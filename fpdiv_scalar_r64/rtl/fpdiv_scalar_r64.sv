// ========================================================================================================
// File Name			: fpdiv_scalar_r64.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-04 09:09:21
// Last Modified Time   : 2022-01-11 22:03:13
// ========================================================================================================
// Description	:
// A Scalar Floating Point Divider based on Minimally Redundant Radix-4 SRT Algorithm.
// The design is based on the paper:
// "Radix-64 Floating-Point Divider", Javier D. Bruguera, ARM Austin Design Center
// It supports fp16/32/64.
// ========================================================================================================
// ========================================================================================================
// Copyright (C) 2022, HYF. All Rights Reserved.
// ========================================================================================================
// This file is licensed under BSD 3-Clause License.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice, this list of 
// conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of 
// conditions and the following disclaimer in the documentation and/or other materials provided 
// with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors may be used 
// to endorse or promote products derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND 
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ========================================================================================================

// include some definitions here

module fpdiv_scalar_r64 #(
	// Put some parameters here, which can be changed by other modules
	parameter QDS_ARCH = 2,
	parameter S1_SPECULATIVE_QDS = 1
)(
	input  logic start_valid_i,
	output logic start_ready_o,
	input  logic flush_i,
	// 2'd0: fp16
	// 2'd1: fp16
	// 2'd2: fp64
	input  logic [2-1:0] fp_format_i,
	input  logic [64-1:0] opa_i,
	input  logic [64-1:0] opb_i,
	input  logic [3-1:0] rm_i,

	output logic finish_valid_o,
	input  logic finish_ready_i,
	output logic [64-1:0] fpdiv_res_o,
	output logic [5-1:0] fflags_o,

	input  logic clk,
	input  logic rst_n
);

// ================================================================================================================================================
// (local) parameters begin

// If we regard "fp64_frac" is a number that < 1, then we have:
// fp64_frac[52] <=> 2 ^ -1
// fp64_frac[52] <=> 2 ^ -2
// ...
// fp64_frac[ 1] <=> 2 ^ -52
// fp64_frac[ 0] <=> 2 ^ -53
// The field of the "REM" used in iter is:
// [59]: sign
// [58]: 2 ^ 1
// [57]: 2 ^ 0
// [56:4]: (2 ^ -1) ~ (2 ^ -53)
// [3:1]: (2 ^ -54) ~ (2 ^ -56) -> for operand scaling, need to do "* (2 ^ -3)"
// [0]: add 1-bit as LSB for initialization -> the 1st quo could only be +1 or +2, so we make "rem_init[0] = 1". Thus the 1st CSA is simplified
localparam REM_W = 3 + 53 + 3 + 1;

localparam QUO_DIG_W = 5;

localparam QUO_DIG_NEG_2_BIT = 4;
localparam QUO_DIG_NEG_1_BIT = 3;
localparam QUO_DIG_NEG_0_BIT = 2;
localparam QUO_DIG_POS_1_BIT = 1;
localparam QUO_DIG_POS_2_BIT = 0;

localparam QUO_DIG_NEG_2 = (1 << 4);
localparam QUO_DIG_NEG_1 = (1 << 3);
localparam QUO_DIG_NEG_0 = (1 << 2);
localparam QUO_DIG_POS_1 = (1 << 1);
localparam QUO_DIG_POS_2 = (1 << 0);

localparam FP64_FRAC_W = 52 + 1;
localparam FP32_FRAC_W = 23 + 1;
localparam FP16_FRAC_W = 10 + 1;

localparam FP64_EXP_W = 11;
localparam FP32_EXP_W = 8;
localparam FP16_EXP_W = 5;

localparam FSM_W = 6;
localparam FSM_PRE_0 	= (1 << 0);
localparam FSM_PRE_1 	= (1 << 1);
localparam FSM_PRE_2 	= (1 << 2);
localparam FSM_ITER  	= (1 << 3);
localparam FSM_POST_0 	= (1 << 4);
localparam FSM_POST_1 	= (1 << 5);

localparam FSM_PRE_0_BIT 	= 0;
localparam FSM_PRE_1_BIT	= 1;
localparam FSM_PRE_2_BIT	= 2;
localparam FSM_ITER_BIT 	= 3;
localparam FSM_POST_0_BIT 	= 4;
localparam FSM_POST_1_BIT 	= 5;

// If r_shift_num of quo is greater than or equal to this value, then the whole quo would be sticky_bit
localparam R_SHIFT_NUM_LIMIT = 6'd54;

localparam RM_RNE = 3'b000;
localparam RM_RTZ = 3'b001;
localparam RM_RDN = 3'b010;
localparam RM_RUP = 3'b011;
localparam RM_RMM = 3'b100;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

genvar i;

logic start_handshaked;
logic [FSM_W-1:0] fsm_d;
logic [FSM_W-1:0] fsm_q;
logic [3-1:0] init_cycles;

logic [13-1:0] op_exp_diff;
logic out_exp_diff_en;
logic [13-1:0] out_exp_diff_d;
logic [13-1:0] out_exp_diff_q;

logic opa_sign;
logic opb_sign;
logic [11-1:0] opa_exp;
logic [11-1:0] opb_exp;
logic [11-1:0] opa_exp_biased;
logic [11-1:0] opb_exp_biased;
logic [12-1:0] opa_exp_plus_biased;
logic opa_exp_is_zero;
logic opb_exp_is_zero;
logic opa_exp_is_max;
logic opb_exp_is_max;
logic opa_is_zero;
logic opb_is_zero;

logic opa_frac_is_zero;
logic opb_frac_is_zero;
logic opa_frac_is_zero_f32_f16;
logic opb_frac_is_zero_f32_f16;

logic opa_is_inf;
logic opb_is_inf;
logic opa_is_qnan;
logic opb_is_qnan;
logic opa_is_snan;
logic opb_is_snan;
logic opa_is_nan;
logic opb_is_nan;

// ================================================================================================================================================
// In these special cases, srt_iter is not needed so we can get the correct result with only several cycles.
logic res_is_nan;
logic res_is_inf;
logic res_is_exact_zero;
logic opb_is_power_of_2;
logic op_invalid_div;
logic divided_by_zero;

logic res_is_nan_d;
logic res_is_nan_q;
logic res_is_inf_d;
logic res_is_inf_q;
logic res_is_exact_zero_d;
logic res_is_exact_zero_q;
logic opb_is_power_of_2_d;
logic opb_is_power_of_2_q;
logic op_invalid_div_d;
logic op_invalid_div_q;
logic divided_by_zero_d;
logic divided_by_zero_q;

logic early_finish;
logic res_is_denormal;
// ================================================================================================================================================

logic out_sign_d;
logic out_sign_q;
logic [2-1:0] fp_format_d;
logic [2-1:0] fp_format_q;
logic [3-1:0] rm_d;
logic [3-1:0] rm_q;

logic [FP32_FRAC_W-1:0] opa_frac_pre_shifted_f32_f16;
logic [FP32_FRAC_W-1:0] opb_frac_pre_shifted_f32_f16;
logic [$clog2(FP32_FRAC_W)-1:0] opa_l_shift_num_pre_f32_f16;
logic [$clog2(FP32_FRAC_W)-1:0] opb_l_shift_num_pre_f32_f16;
logic [$clog2(FP32_FRAC_W)-1:0] opa_l_shift_num_f32_f16;
logic [$clog2(FP32_FRAC_W)-1:0] opb_l_shift_num_f32_f16;
logic [FP32_FRAC_W-1:0] opa_frac_l_shifted_f32_f16;
logic [FP32_FRAC_W-1:0] opb_frac_l_shifted_f32_f16;

logic [FP64_FRAC_W-1:0] opa_frac_pre_shifted;
logic [FP64_FRAC_W-1:0] opb_frac_pre_shifted;
logic [$clog2(FP64_FRAC_W)-1:0] opa_l_shift_num;
logic [$clog2(FP64_FRAC_W)-1:0] opb_l_shift_num;
logic [$clog2(FP64_FRAC_W)-1:0] opa_l_shift_num_pre;
logic [$clog2(FP64_FRAC_W)-1:0] opb_l_shift_num_pre;
logic [(FP64_FRAC_W-1)-1:0] opa_frac_l_shifted_s2_to_s0;
logic [(FP64_FRAC_W-1)-1:0] opb_frac_l_shifted_s2_to_s0;
logic [FP64_FRAC_W-1:0] opa_frac_l_shifted;
logic [FP64_FRAC_W-1:0] opb_frac_l_shifted;

logic [3-1:0] scale_factor_idx;
logic [3-1:0] scale_factor_idx_f32_f16;
logic [FP64_FRAC_W-1:0] prescaled_a_frac;
logic [FP64_FRAC_W-1:0] prescaled_b_frac;
logic [FP32_FRAC_W-1:0] prescaled_a_frac_f32_f16;
logic [FP32_FRAC_W-1:0] prescaled_b_frac_f32_f16;
logic [(FP64_FRAC_W+4)-1:0] scaled_a_frac;
logic [(FP64_FRAC_W+4)-1:0] scaled_b_frac;

logic a_frac_lt_b_frac;
logic a_frac_lt_b_frac_l_shifted;
logic a_frac_lt_b_frac_f32_f16;
logic a_frac_lt_b_frac_f32_f16_l_shifted;

logic [29-1:0] scale_adder_29b_opa_0_in [3-1:0];
logic [29-1:0] scale_adder_29b_opa_0;
logic [29-1:0] scale_adder_29b_opb_0_in [3-1:0];
logic [29-1:0] scale_adder_29b_opb_0;
logic [29-1:0] scale_adder_29b_opa_1_in [3-1:0];
logic [29-1:0] scale_adder_29b_opa_1;
logic [29-1:0] scale_adder_29b_opb_1_in [3-1:0];
logic [29-1:0] scale_adder_29b_opb_1;
logic [30-1:0] scale_adder_30b_opa_in [3-1:0];
logic [30-1:0] scale_adder_30b_opa;
logic [30-1:0] scale_adder_30b_opb_in [3-1:0];
logic [30-1:0] scale_adder_30b_opb;

// f_r = frac_rem
// f_r_s = frac_rem_sum
// f_r_c = frac_rem_carry
logic [REM_W-1:0] f_r_s_iter_init;
logic [REM_W-1:0] f_r_c_iter_init;
logic [(REM_W+1)-1:0] f_r_s_iter_init_pre;
logic [5-1:0] f_r_s_for_integer_quo;
logic integer_quo_is_pos_2;

logic [REM_W-1:0] scaled_b_frac_ext;
logic [REM_W-1:0] scaled_b_frac_ext_mul_neg_1;
logic [REM_W-1:0] scaled_b_frac_ext_mul_neg_2;

logic [6-1:0] adder_6b_iter_init;
logic [7-1:0] adder_7b_iter_init;

logic [6-1:0] adder_6b_res_for_nxt_cycle_s0_qds;
logic [7-1:0] adder_7b_res_for_nxt_cycle_s1_qds;

// nr = non_redundant
logic nr_f_r_6b_for_nxt_cycle_s0_qds_en;
logic [6-1:0] nr_f_r_6b_for_nxt_cycle_s0_qds_d;
logic [6-1:0] nr_f_r_6b_for_nxt_cycle_s0_qds_q;
logic nr_f_r_7b_for_nxt_cycle_s1_qds_en;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s1_qds_d;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s1_qds_q;

logic f_r_s_en;
logic [REM_W-1:0] f_r_s_d;
logic [REM_W-1:0] f_r_s_q;
logic f_r_c_en;
logic [REM_W-1:0] f_r_c_d;
logic [REM_W-1:0] f_r_c_q;

logic [REM_W-1:0] nxt_f_r_s [3-1:0];
logic [REM_W-1:0] nxt_f_r_c [3-1:0];

// 57 = FP64_FRAC_W + 4
logic frac_divisor_en;
logic [57-1:0] frac_divisor_d;
logic [57-1:0] frac_divisor_q;

logic [57-1:0] nxt_frac_divisor_pre_0;
logic [57-1:0] nxt_frac_divisor_pre_1;
logic [57-1:0] nxt_frac_divisor_pre_2;

// The OFC Logic of the last stage in the current cycle could be placed in the next cycle
// So the timing of "quo_iter_d/quo_m1_iter_d" is much better.
logic prev_quo_dig_en;
logic [QUO_DIG_W-1:0] prev_quo_dig_d;
logic [QUO_DIG_W-1:0] prev_quo_dig_q;
logic [QUO_DIG_W-1:0] nxt_quo_dig [3-1:0];

logic quo_iter_en;
// For FP64, it will generate 6 * 9 + 2 = 56-bit Q. But we also use "prev_quo_dig" to store the quo_dig of the last iter.
// So we only need (56 - 2)-bit regs to store Q/Q_M1
logic [(56-2)-1:0] quo_iter_d;
logic [(56-2)-1:0] quo_iter_q;
logic quo_m1_iter_en;
logic [(56-2)-1:0] quo_m1_iter_d;
logic [(56-2)-1:0] quo_m1_iter_q;
logic [56-1:0] nxt_quo_iter [3-1:0];
logic [56-1:0] nxt_quo_m1_iter [3-1:0];

logic [(56-2)-1:0] nxt_quo_iter_pre_0;
logic [(56-2)-1:0] nxt_quo_iter_pre_1;
logic [(56-2)-1:0] nxt_quo_iter_pre_2;

logic [(56-2)-1:0] nxt_quo_m1_iter_pre_0;
logic [(56-2)-1:0] nxt_quo_m1_iter_pre_1;
logic [(56-2)-1:0] nxt_quo_m1_iter_post_0;

logic iter_num_en;
// f64: iter_num_needed = 9, 9 - 1 = 8
// f32: iter_num_needed = 4, 4 - 1 = 3
// f16: iter_num_needed = 2, 2 - 1 = 1
// So a 4-bit counter is enough.
logic [4-1:0] iter_num_d;
logic [4-1:0] iter_num_q;
logic [4-1:0] iter_num_needed;
logic final_iter;

logic [REM_W-1:0] nr_f_r;
logic [(REM_W-2)-1:0] f_r_xor;
logic [(REM_W-2)-1:0] f_r_or;
logic rem_is_not_zero;

logic [(FP64_FRAC_W + 1)-1:0] quo_pre_shift;
logic [(FP64_FRAC_W + 1)-1:0] quo_m1_pre_shift;
logic [((FP64_FRAC_W + 1) * 2)-1:0] quo_r_shifted;
logic [((FP64_FRAC_W + 1) * 2)-1:0] quo_m1_r_shifted;

logic [13-1:0] r_shift_num_pre;
logic [13-1:0] r_shift_num_pre_minus_limit;
logic [13-1:0] r_shift_num;

logic select_quo_m1;
logic [(FP64_FRAC_W + 1)-1:0] correct_quo_r_shifted;
logic [(FP64_FRAC_W + 1)-1:0] sticky_without_rem;

logic [(FP64_FRAC_W - 1)-1:0] quo_pre_inc;
logic [(FP64_FRAC_W - 1)-1:0] quo_m1_pre_inc;
logic [FP64_FRAC_W-1:0] quo_inc_res;
logic [(FP64_FRAC_W - 1)-1:0] quo_m1_inc_res;

logic guard_bit_quo;
logic round_bit_quo;
logic sticky_bit_quo;
logic inexact_quo;
logic quo_need_rup;
logic [FP64_FRAC_W-1:0] quo_rounded;

logic guard_bit_quo_m1;
logic round_bit_quo_m1;
logic sticky_bit_quo_m1;
logic inexact_quo_m1;
logic quo_need_rup_m1;
logic [(FP64_FRAC_W - 1)-1:0] quo_m1_rounded;

logic [(FP64_FRAC_W - 1)-1:0] frac_rounded_post_0;
logic carry_after_round;
logic overflow;
logic overflow_to_inf;

logic [FP16_EXP_W-1:0] f16_out_exp_post_0;
logic [FP32_EXP_W-1:0] f32_out_exp_post_0;
logic [FP64_EXP_W-1:0] f64_out_exp_post_0;

logic [(FP16_FRAC_W-1)-1:0] f16_out_frac_post_0;
logic [(FP32_FRAC_W-1)-1:0] f32_out_frac_post_0;
logic [(FP64_FRAC_W-1)-1:0] f64_out_frac_post_0;

logic [FP16_EXP_W-1:0] f16_out_exp_post_1;
logic [FP32_EXP_W-1:0] f32_out_exp_post_1;
logic [FP64_EXP_W-1:0] f64_out_exp_post_1;

logic [(FP16_FRAC_W-1)-1:0] f16_out_frac_post_1;
logic [(FP32_FRAC_W-1)-1:0] f32_out_frac_post_1;
logic [(FP64_FRAC_W-1)-1:0] f64_out_frac_post_1;

logic [(FP16_EXP_W + FP16_FRAC_W)-1:0] f16_res_post_0;
logic [(FP32_EXP_W + FP32_FRAC_W)-1:0] f32_res_post_0;
logic [(FP64_EXP_W + FP64_FRAC_W)-1:0] f64_res_post_0;
logic [(FP16_EXP_W + FP16_FRAC_W)-1:0] f16_res_post_1;
logic [(FP32_EXP_W + FP32_FRAC_W)-1:0] f32_res_post_1;
logic [(FP64_EXP_W + FP64_FRAC_W)-1:0] f64_res_post_1;

logic [(FP64_EXP_W + FP64_FRAC_W)-1:0] fpdiv_res_post_0;
logic [(FP64_EXP_W + FP64_FRAC_W)-1:0] fpdiv_res_post_1;

logic fflags_invalid_operation;
logic fflags_div_by_zero;
logic fflags_overflow;
logic fflags_underflow;
logic fflags_inexact;

// signals end
// ================================================================================================================================================

// ================================================================================================================================================
// FSM ctrl
// ================================================================================================================================================
always_comb begin
	unique case(fsm_q)
		FSM_PRE_0:
			fsm_d = 
			start_valid_i ? (
				early_finish ? FSM_POST_1 : 
				init_cycles[0] ? (opb_is_power_of_2 ? FSM_POST_0 : FSM_ITER) : 
				init_cycles[1] ? (opb_is_power_of_2 ? FSM_POST_0 : FSM_PRE_2) : 
				FSM_PRE_1
			) : 
			FSM_PRE_0;
		FSM_PRE_1:
			fsm_d = opb_is_power_of_2_q ? FSM_POST_0 : FSM_PRE_2;
		FSM_PRE_2:
			fsm_d = FSM_ITER;
		FSM_ITER:
			fsm_d = final_iter ? FSM_POST_0 : FSM_ITER;
		FSM_POST_0:
			fsm_d = res_is_denormal ? FSM_POST_1 : finish_ready_i ? FSM_PRE_0 : FSM_POST_0;
		FSM_POST_1:
			fsm_d = finish_ready_i ? FSM_PRE_0 : FSM_POST_1;
		default:
			fsm_d = FSM_PRE_0;
	endcase

	if(flush_i)
		// flush has the highest priority.
		fsm_d = FSM_PRE_0;
end

// The only reg that need to be reset.
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		fsm_q <= FSM_PRE_0;
	else
		fsm_q <= fsm_d;
end

assign start_ready_o = fsm_q[FSM_PRE_0_BIT];
assign start_handshaked = start_valid_i & start_ready_o;
assign finish_valid_o = fsm_q[FSM_POST_1_BIT] | (fsm_q[FSM_POST_0_BIT] & ~res_is_denormal);

// Here we don't consider "opb_is_power_of_2"
// f32_f16_without_denormal	: 1 cycle for init, pre_0 -> iter
// f32_f16_with_denormal	: 2 cycle for init, pre_0 -> pre_2 -> iter
// f64_without_denormal		: 2 cycle for init, pre_0 -> pre_2 -> iter
// f64_with_denormal		: 3 cycle for init, pre_0 -> pre_1 -> pre_2 -> iter
assign init_cycles[0] = (fp_format_i != 2'd2) & ~(opa_exp_is_zero | opb_exp_is_zero);
assign init_cycles[1] = ((fp_format_i != 2'd2) & (opa_exp_is_zero | opb_exp_is_zero)) | ((fp_format_i == 2'd2) & ~(opa_exp_is_zero | opb_exp_is_zero));
assign init_cycles[2] = (fp_format_i == 2'd2) & (opa_exp_is_zero | opb_exp_is_zero);

// ================================================================================================================================================
// Pre process
// ================================================================================================================================================

assign opa_sign = (fp_format_i == 2'd0) ? opa_i[15] : (fp_format_i == 2'd1) ? opa_i[31] : opa_i[63];
assign opb_sign = (fp_format_i == 2'd0) ? opb_i[15] : (fp_format_i == 2'd1) ? opb_i[31] : opb_i[63];
assign opa_exp = (fp_format_i == 2'd0) ? {6'b0, opa_i[14:10]} : (fp_format_i == 2'd1) ? {3'b0, opa_i[30:23]} : opa_i[62:52];
assign opb_exp = (fp_format_i == 2'd0) ? {6'b0, opb_i[14:10]} : (fp_format_i == 2'd1) ? {3'b0, opb_i[30:23]} : opb_i[62:52];

assign opa_exp_biased = 
(fp_format_i == 2'd0) ? {6'b0, opa_i[14:11], opa_i[10] | opa_exp_is_zero} : 
(fp_format_i == 2'd1) ? {3'b0, opa_i[30:24], opa_i[23] | opa_exp_is_zero} : 
{opa_i[62:53], opa_i[52] | opa_exp_is_zero};
assign opb_exp_biased = 
(fp_format_i == 2'd0) ? {6'b0, opb_i[14:11], opb_i[10] | opb_exp_is_zero} : 
(fp_format_i == 2'd1) ? {3'b0, opb_i[30:24], opb_i[23] | opb_exp_is_zero} : 
{opb_i[62:53], opb_i[52] | opb_exp_is_zero};

assign opa_exp_is_zero = (opa_exp == 11'b0);
assign opb_exp_is_zero = (opb_exp == 11'b0);
assign opa_exp_is_max = (opa_exp == ((fp_format_i == 2'd0) ? 11'd31 : (fp_format_i == 2'd1) ? 11'd255 : 11'd2047));
assign opb_exp_is_max = (opb_exp == ((fp_format_i == 2'd0) ? 11'd31 : (fp_format_i == 2'd1) ? 11'd255 : 11'd2047));
assign opa_is_zero = opa_exp_is_zero & ((fp_format_i == 2'd2) ? opa_frac_is_zero : opa_frac_is_zero_f32_f16);
assign opb_is_zero = opb_exp_is_zero & ((fp_format_i == 2'd2) ? opb_frac_is_zero : opb_frac_is_zero_f32_f16);
assign opa_is_inf = opa_exp_is_max & ((fp_format_i == 2'd2) ? opa_frac_is_zero : opa_frac_is_zero_f32_f16);
assign opb_is_inf = opb_exp_is_max & ((fp_format_i == 2'd2) ? opb_frac_is_zero : opb_frac_is_zero_f32_f16);

assign opa_is_qnan = opa_exp_is_max & ((fp_format_i == 2'd0) ? opa_i[9] : (fp_format_i == 2'd1) ? opa_i[22] : opa_i[51]);
assign opb_is_qnan = opb_exp_is_max & ((fp_format_i == 2'd0) ? opb_i[9] : (fp_format_i == 2'd1) ? opb_i[22] : opb_i[51]);

assign opa_is_snan = 
  opa_exp_is_max
& ~((fp_format_i == 2'd2) ? opa_frac_is_zero : opa_frac_is_zero_f32_f16) 
& ((fp_format_i == 2'd0) ? ~opa_i[9] : (fp_format_i == 2'd1) ? ~opa_i[22] : ~opa_i[51]);
assign opb_is_snan = 
  opb_exp_is_max
& ~((fp_format_i == 2'd2) ? opb_frac_is_zero : opb_frac_is_zero_f32_f16) 
& ((fp_format_i == 2'd0) ? ~opb_i[9] : (fp_format_i == 2'd1) ? ~opb_i[22] : ~opb_i[51]);

assign opa_is_nan = (opa_is_qnan | opa_is_snan);
assign opb_is_nan = (opb_is_qnan | opb_is_snan);
assign op_invalid_div = (opa_is_inf & opb_is_inf) | (opa_is_zero & opb_is_zero) | opa_is_snan | opb_is_snan;
// {res_is_inf}, {res_is_exact_zero} will not happen at the same time
// But {res_is_inf, res_is_exact_zero}, {res_is_nan} could happen at the same time
// In final stage, use these signals to select the correct result
assign res_is_nan = opa_is_nan | opb_is_nan | op_invalid_div;
assign res_is_inf = opa_is_inf | opb_is_zero;
assign res_is_exact_zero = opa_is_zero | opb_is_inf;
// For this signal, don't consider the value of exp, and don't consider denormal number.
assign opb_is_power_of_2 = ((fp_format_i == 2'd2) ? opb_frac_is_zero : opb_frac_is_zero_f32_f16);
// When result is not nan, and dividend is not inf, "dividend / 0" should lead to "DIV_BY_ZERO" exception.
assign divided_by_zero = ~res_is_nan & ~opa_is_inf & opb_is_zero;

assign opa_exp_plus_biased = {1'b0, opa_exp_biased[10:0]} + ((fp_format_i == 2'd0) ? 12'd15 : (fp_format_i == 2'd1) ? 12'd127 : 12'd1023);
assign op_exp_diff[12:0] = 
  {1'b0, opa_exp_plus_biased}
- {7'b0, (fp_format_i == 2'd2) ? opa_l_shift_num : {1'b0, opa_l_shift_num_f32_f16}}
- {1'b0, opb_exp_biased}
+ {7'b0, (fp_format_i == 2'd2) ? opb_l_shift_num : {1'b0, opb_l_shift_num_f32_f16}};

// Follow the rule in riscv-spec, just produce default NaN.
assign out_sign_d = res_is_nan ? 1'b0 : (opa_sign ^ opb_sign);
assign fp_format_d = fp_format_i;
assign rm_d = rm_i;

assign res_is_nan_d = res_is_nan;
assign res_is_inf_d = res_is_inf;
assign res_is_exact_zero_d = res_is_exact_zero;
assign opb_is_power_of_2_d = opb_is_power_of_2;
assign op_invalid_div_d = op_invalid_div;
assign divided_by_zero_d = divided_by_zero;
always_ff @(posedge clk) begin
	if(start_handshaked) begin		
		out_sign_q <= out_sign_d;
		fp_format_q <= fp_format_d;
		rm_q <= rm_d;

		res_is_nan_q <= res_is_nan_d;
		res_is_inf_q <= res_is_inf_d;
		res_is_exact_zero_q <= res_is_exact_zero_d;
		opb_is_power_of_2_q <= opb_is_power_of_2_d;
		op_invalid_div_q <= op_invalid_div_d;
		divided_by_zero_q <= divided_by_zero_d;
	end
end

assign early_finish = res_is_nan | res_is_inf | res_is_exact_zero;
// Min(out_exp_diff_q) cannot reach -4096 = 13'b1_0000_0000_0000 -> 12-bit "==" is enough
assign res_is_denormal = (out_exp_diff_q[11:0] == 0) | out_exp_diff_q[12];

assign out_exp_diff_en = start_handshaked | fsm_q[FSM_PRE_2_BIT];
assign out_exp_diff_d = (fsm_q[FSM_PRE_0_BIT] ? op_exp_diff : out_exp_diff_q) - {
	12'b0,
	fsm_q[FSM_PRE_0_BIT] ? (init_cycles[0] & a_frac_lt_b_frac_f32_f16) : 
	((fp_format_q != 2'd2) ? a_frac_lt_b_frac_f32_f16_l_shifted : iter_num_q[0])
};
always_ff @(posedge clk)
	if(out_exp_diff_en)
		out_exp_diff_q <= out_exp_diff_d;


// The large LZC is only for f64
assign opa_frac_pre_shifted = {1'b0, opa_i[51:0]};
assign opb_frac_pre_shifted = {1'b0, opb_i[51:0]};
lzc #(
	.WIDTH(FP64_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_opa (
	.in_i(opa_frac_pre_shifted),
	.cnt_o(opa_l_shift_num_pre),
	// The hiddend bit of frac is not considered here
	.empty_o(opa_frac_is_zero)
);
lzc #(
	.WIDTH(FP64_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_opb (
	.in_i(opb_frac_pre_shifted),
	.cnt_o(opb_l_shift_num_pre),
	// The hiddend bit of frac is not considered here
	.empty_o(opb_frac_is_zero)
);

assign opa_l_shift_num = {(6){opa_exp_is_zero}} & opa_l_shift_num_pre;
assign opb_l_shift_num = {(6){opb_exp_is_zero}} & opb_l_shift_num_pre;

// This is for f32/f16
assign opa_frac_pre_shifted_f32_f16 = 
  ({(FP32_FRAC_W){fp_format_i == 2'd0}} & {1'b0, opa_i[0 +: (FP16_FRAC_W - 1)], {(FP32_FRAC_W - FP16_FRAC_W){1'b0}}})
| ({(FP32_FRAC_W){fp_format_i == 2'd1}} & {1'b0, opa_i[0 +: (FP32_FRAC_W - 1)], {(FP32_FRAC_W - FP32_FRAC_W){1'b0}}});
assign opb_frac_pre_shifted_f32_f16 = 
  ({(FP32_FRAC_W){fp_format_i == 2'd0}} & {1'b0, opb_i[0 +: (FP16_FRAC_W - 1)], {(FP32_FRAC_W - FP16_FRAC_W){1'b0}}})
| ({(FP32_FRAC_W){fp_format_i == 2'd1}} & {1'b0, opb_i[0 +: (FP32_FRAC_W - 1)], {(FP32_FRAC_W - FP32_FRAC_W){1'b0}}});
lzc #(
	.WIDTH(FP32_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_opa_f32_f16 (
	.in_i(opa_frac_pre_shifted_f32_f16),
	.cnt_o(opa_l_shift_num_pre_f32_f16),
	// The hiddend bit of frac is not considered here
	.empty_o(opa_frac_is_zero_f32_f16)
);
lzc #(
	.WIDTH(FP32_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_opb_f32_f16 (
	.in_i(opb_frac_pre_shifted_f32_f16),
	.cnt_o(opb_l_shift_num_pre_f32_f16),
	// The hiddend bit of frac is not considered here
	.empty_o(opb_frac_is_zero_f32_f16)
);

assign opa_l_shift_num_f32_f16 = {(5){opa_exp_is_zero}} & opa_l_shift_num_pre_f32_f16;
assign opb_l_shift_num_f32_f16 = {(5){opb_exp_is_zero}} & opb_l_shift_num_pre_f32_f16;

// Do "clz + l_shift" in pre_0 for f32/f16. The timing requirement should be met...
// The MSB of frac_l_shifted must be 1 -> A "(FP32_FRAC_W - 1)-bit" l_shifter is enough.
assign opa_frac_l_shifted_f32_f16 = {1'b1, opa_frac_pre_shifted_f32_f16[0 +: (FP32_FRAC_W - 1)] << opa_l_shift_num_f32_f16};
assign opb_frac_l_shifted_f32_f16 = {1'b1, opb_frac_pre_shifted_f32_f16[0 +: (FP32_FRAC_W - 1)] << opb_l_shift_num_f32_f16};

// Do stage[2:0] l_shift in pre_0 for f64
assign opa_frac_l_shifted_s2_to_s0 = opa_i[51:0] << opa_l_shift_num[2:0];
assign opb_frac_l_shifted_s2_to_s0 = opb_i[51:0] << opb_l_shift_num[2:0];
// Do stage[5:3] l_shift in pre_1 for f64
assign opa_frac_l_shifted = {1'b1, quo_iter_q   [51:0] << {frac_divisor_q[5:3], 3'b0}};
assign opb_frac_l_shifted = {1'b1, quo_m1_iter_q[51:0] << {frac_divisor_q[2:0], 3'b0}};

// Now we get the normalized frac. Let's do scaling operation.
// I guess the complexity of a N-bit comparator logic is comparable to that of a N-bit mux, so here I just use several comparators for easy coding...
// The below comparisons are calculated in parallel with scaling operation.

// Done in pre_0, will be used in pre_2
assign a_frac_lt_b_frac = opa_i[51:0] < opb_i[51:0];
// Done in pre_1, will be used in pre_2
assign a_frac_lt_b_frac_l_shifted = opa_frac_l_shifted[51:0] < opb_frac_l_shifted[51:0];
// Done in pre_0, will be used in pre_0
assign a_frac_lt_b_frac_f32_f16 = {{(13){fp_format_i == 2'd1}} & opa_i[22:10], opa_i[9:0]} < {{(13){fp_format_i == 2'd1}} & opb_i[22:10], opb_i[9:0]};
// Done in pre_2, will be used in pre_2
assign a_frac_lt_b_frac_f32_f16_l_shifted = quo_iter_q[22:0] < quo_m1_iter_q[22:0];

// ================================================================================================================================================
// Scaling operation
// ================================================================================================================================================
// For f64, we need a 57-bit 3-input FA for scaling.
// To improve the timing, the implementation is:
// a 30-bit FA in scaling_stage[0]: generate 28-bit "scaled_op[27:0]" and 2-bit carry, which will be used in scaling_stage[1]
// a 29-bit FA in scaling_stage[0]: generate 29-bit "scaled_op_pre[56:28]", which doesn't take the 2-bit carry from the low part into consideration
// a 29-bit FA in scaling_stage[1]: Use "2-bit carry and scaled_op_pre[56:28] (They are generated in scaling_stage[0]) to calculate "scaled_op[56:28]"
// The regs used to store the result of scaling_stage[0]:
// For opa: quo_iter_q[29:0] = {2-bit carry, scaled_opa[27:0]}, {frac_divisor_q[9:5], quo_iter_q[53:30]} = scaled_opa_pre[56:28]
// For opb: quo_m1_iter_q[29:0] = {2-bit carry, scaled_opb[27:0]}, {frac_divisor_q[4:0], quo_m1_iter_q[53:30]} = scaled_opb_pre[56:28]

// For f32/f16, we need a 28-bit FA for scaling.
// When f32/f16 has 1 or 2 denormal input, 2 cycles is needed for init.
// The regs used to store the "frac_l_shifted" when we need 2 cycles for init:
// quo_iter_q[22:0] = opa_frac_l_shifted_f32_f16[22:0]
// quo_m1_iter_q[22:0] = opb_frac_l_shifted_f32_f16[22:0]

// For f32/f16, scaling should be able to finish in 1 cycle, so it is done in pre_0/pre_2
assign prescaled_a_frac_f32_f16 = {
	1'b1, 
	fsm_q[FSM_PRE_0_BIT] ? ((fp_format_i == 2'd1) ? opa_i[22:0] : {opa_i[9:0], 13'b0}) : quo_iter_q[22:0]
};
assign prescaled_b_frac_f32_f16 = {
	1'b1, 
	fsm_q[FSM_PRE_0_BIT] ? ((fp_format_i == 2'd1) ? opb_i[22:0] : {opb_i[9:0], 13'b0}) : quo_m1_iter_q[22:0]
};

assign scale_factor_idx_f32_f16 = prescaled_b_frac_f32_f16[22 -: 3];

// ================================================================================================================================================
// This adder is used for f32_f16.opa or the scaling_stage[1] of f64.opa
// ================================================================================================================================================
assign scale_adder_29b_opa_0_in[0] = 
(fsm_q[FSM_PRE_0_BIT] | (fsm_q[FSM_PRE_2_BIT] & (fp_format_q != 2'd2))) ? {2'b0, prescaled_a_frac_f32_f16, 3'b0} : 
{frac_divisor_q[9:5], quo_iter_q[53:30]};

// Look at "TABLE I" in the paper for details.
// 0: 1/2
// 1: 1/4
// 2: 1/2
// 3: 1/2
// 4: 1/4
// 5: 1/4
// 6: 0
// 7: 0
assign scale_adder_29b_opa_0_in[1] = 
(fsm_q[FSM_PRE_0_BIT] | (fsm_q[FSM_PRE_2_BIT] & (fp_format_q != 2'd2))) ? {
	3'b0, 
	  ({(25){scale_factor_idx_f32_f16 == 3'd0}} & {prescaled_a_frac_f32_f16, 1'b0})
	| ({(25){scale_factor_idx_f32_f16 == 3'd1}} & {1'b0, prescaled_a_frac_f32_f16})
	| ({(25){scale_factor_idx_f32_f16 == 3'd2}} & {prescaled_a_frac_f32_f16, 1'b0})
	| ({(25){scale_factor_idx_f32_f16 == 3'd3}} & {prescaled_a_frac_f32_f16, 1'b0})
	| ({(25){scale_factor_idx_f32_f16 == 3'd4}} & {1'b0, prescaled_a_frac_f32_f16})
	| ({(25){scale_factor_idx_f32_f16 == 3'd5}} & {1'b0, prescaled_a_frac_f32_f16})
	| ({(25){scale_factor_idx_f32_f16 == 3'd6}} & 25'b0)
	| ({(25){scale_factor_idx_f32_f16 == 3'd7}} & 25'b0),
	1'b0
} : 29'b0;

// 0: 1/2
// 1: 1/2
// 2: 1/8
// 3: 0
// 4: 1/8
// 5: 0
// 6: 1/8
// 7: 1/8
assign scale_adder_29b_opa_0_in[2] = 
(fsm_q[FSM_PRE_0_BIT] | (fsm_q[FSM_PRE_2_BIT] & (fp_format_q != 2'd2))) ? {
	3'b0,
	  ({(26){scale_factor_idx_f32_f16 == 3'd0}} & {prescaled_a_frac_f32_f16, 2'b0})
	| ({(26){scale_factor_idx_f32_f16 == 3'd1}} & {prescaled_a_frac_f32_f16, 2'b0})
	| ({(26){scale_factor_idx_f32_f16 == 3'd2}} & {2'b0, prescaled_a_frac_f32_f16})
	| ({(26){scale_factor_idx_f32_f16 == 3'd3}} & 26'b0)
	| ({(26){scale_factor_idx_f32_f16 == 3'd4}} & {2'b0, prescaled_a_frac_f32_f16})
	| ({(26){scale_factor_idx_f32_f16 == 3'd5}} & 26'b0)
	| ({(26){scale_factor_idx_f32_f16 == 3'd6}} & {2'b0, prescaled_a_frac_f32_f16})
	| ({(26){scale_factor_idx_f32_f16 == 3'd7}} & {2'b0, prescaled_a_frac_f32_f16})
} : {27'b0, quo_iter_q[29:28]};

assign scale_adder_29b_opa_0 = 
  scale_adder_29b_opa_0_in[0]
+ scale_adder_29b_opa_0_in[1]
+ scale_adder_29b_opa_0_in[2];
// ================================================================================================================================================
// This adder is used for f32_f16.opb or the scaling_stage[1] of f64.opb
// ================================================================================================================================================
assign scale_adder_29b_opb_0_in[0] = 
(fsm_q[FSM_PRE_0_BIT] | (fsm_q[FSM_PRE_2_BIT] & (fp_format_q != 2'd2))) ? {2'b0, prescaled_b_frac_f32_f16, 3'b0} : 
{frac_divisor_q[4:0], quo_m1_iter_q[53:30]};

assign scale_adder_29b_opb_0_in[1] = 
(fsm_q[FSM_PRE_0_BIT] | (fsm_q[FSM_PRE_2_BIT] & (fp_format_q != 2'd2))) ? {
	3'b0, 
	  ({(25){scale_factor_idx_f32_f16 == 3'd0}} & {prescaled_b_frac_f32_f16, 1'b0})
	| ({(25){scale_factor_idx_f32_f16 == 3'd1}} & {1'b0, prescaled_b_frac_f32_f16})
	| ({(25){scale_factor_idx_f32_f16 == 3'd2}} & {prescaled_b_frac_f32_f16, 1'b0})
	| ({(25){scale_factor_idx_f32_f16 == 3'd3}} & {prescaled_b_frac_f32_f16, 1'b0})
	| ({(25){scale_factor_idx_f32_f16 == 3'd4}} & {1'b0, prescaled_b_frac_f32_f16})
	| ({(25){scale_factor_idx_f32_f16 == 3'd5}} & {1'b0, prescaled_b_frac_f32_f16})
	| ({(25){scale_factor_idx_f32_f16 == 3'd6}} & 25'b0)
	| ({(25){scale_factor_idx_f32_f16 == 3'd7}} & 25'b0),
	1'b0
} : 29'b0;

assign scale_adder_29b_opb_0_in[2] = 
(fsm_q[FSM_PRE_0_BIT] | (fsm_q[FSM_PRE_2_BIT] & (fp_format_q != 2'd2))) ? {
	3'b0,
	  ({(26){scale_factor_idx_f32_f16 == 3'd0}} & {prescaled_b_frac_f32_f16, 2'b0})
	| ({(26){scale_factor_idx_f32_f16 == 3'd1}} & {prescaled_b_frac_f32_f16, 2'b0})
	| ({(26){scale_factor_idx_f32_f16 == 3'd2}} & {2'b0, prescaled_b_frac_f32_f16})
	| ({(26){scale_factor_idx_f32_f16 == 3'd3}} & 26'b0)
	| ({(26){scale_factor_idx_f32_f16 == 3'd4}} & {2'b0, prescaled_b_frac_f32_f16})
	| ({(26){scale_factor_idx_f32_f16 == 3'd5}} & 26'b0)
	| ({(26){scale_factor_idx_f32_f16 == 3'd6}} & {2'b0, prescaled_b_frac_f32_f16})
	| ({(26){scale_factor_idx_f32_f16 == 3'd7}} & {2'b0, prescaled_b_frac_f32_f16})
} : {27'b0, quo_m1_iter_q[29:28]};

assign scale_adder_29b_opb_0 = 
  scale_adder_29b_opb_0_in[0]
+ scale_adder_29b_opb_0_in[1]
+ scale_adder_29b_opb_0_in[2];

// ================================================================================================================================================
assign prescaled_a_frac = {1'b1, fsm_q[FSM_PRE_0_BIT] ? opa_i[51:0] : opa_frac_l_shifted[51:0]};
assign prescaled_b_frac = {1'b1, fsm_q[FSM_PRE_0_BIT] ? opb_i[51:0] : opb_frac_l_shifted[51:0]};

assign scale_factor_idx = prescaled_b_frac[51 -: 3];
// ================================================================================================================================================
// This adder is used for the high part of f64.opa in pre_0 or pre_1
// ================================================================================================================================================
assign scale_adder_29b_opa_1_in[0] = {1'b0, prescaled_a_frac[52:25]};
assign scale_adder_29b_opa_1_in[1] = {
	2'b0,
	  ({(27){scale_factor_idx == 3'd0}} & prescaled_a_frac[52:26])
	| ({(27){scale_factor_idx == 3'd1}} & {1'b0, prescaled_a_frac[52:27]})
	| ({(27){scale_factor_idx == 3'd2}} & prescaled_a_frac[52:26])
	| ({(27){scale_factor_idx == 3'd3}} & prescaled_a_frac[52:26])
	| ({(27){scale_factor_idx == 3'd4}} & {1'b0, prescaled_a_frac[52:27]})
	| ({(27){scale_factor_idx == 3'd5}} & {1'b0, prescaled_a_frac[52:27]})
	| ({(27){scale_factor_idx == 3'd6}} & 27'b0)
	| ({(27){scale_factor_idx == 3'd7}} & 27'b0)
};
assign scale_adder_29b_opa_1_in[2] = {
	2'b0,
	  ({(27){scale_factor_idx == 3'd0}} & prescaled_a_frac[52:26])
	| ({(27){scale_factor_idx == 3'd1}} & prescaled_a_frac[52:26])
	| ({(27){scale_factor_idx == 3'd2}} & {2'b0, prescaled_a_frac[52:28]})
	| ({(27){scale_factor_idx == 3'd3}} & 27'b0)
	| ({(27){scale_factor_idx == 3'd4}} & {2'b0, prescaled_a_frac[52:28]})
	| ({(27){scale_factor_idx == 3'd5}} & 27'b0)
	| ({(27){scale_factor_idx == 3'd6}} & {2'b0, prescaled_a_frac[52:28]})
	| ({(27){scale_factor_idx == 3'd7}} & {2'b0, prescaled_a_frac[52:28]})
};

assign scale_adder_29b_opa_1 = 
  scale_adder_29b_opa_1_in[0]
+ scale_adder_29b_opa_1_in[1]
+ scale_adder_29b_opa_1_in[2];

// ================================================================================================================================================
// This adder is used for the high part of f64.opb in pre_0 or pre_1
// ================================================================================================================================================
assign scale_adder_29b_opb_1_in[0] = {1'b0, prescaled_b_frac[52:25]};
assign scale_adder_29b_opb_1_in[1] = {
	2'b0,
	  ({(27){scale_factor_idx == 3'd0}} & prescaled_b_frac[52:26])
	| ({(27){scale_factor_idx == 3'd1}} & {1'b0, prescaled_b_frac[52:27]})
	| ({(27){scale_factor_idx == 3'd2}} & prescaled_b_frac[52:26])
	| ({(27){scale_factor_idx == 3'd3}} & prescaled_b_frac[52:26])
	| ({(27){scale_factor_idx == 3'd4}} & {1'b0, prescaled_b_frac[52:27]})
	| ({(27){scale_factor_idx == 3'd5}} & {1'b0, prescaled_b_frac[52:27]})
	| ({(27){scale_factor_idx == 3'd6}} & 27'b0)
	| ({(27){scale_factor_idx == 3'd7}} & 27'b0)
};
assign scale_adder_29b_opb_1_in[2] = {
	2'b0,
	  ({(27){scale_factor_idx == 3'd0}} & prescaled_b_frac[52:26])
	| ({(27){scale_factor_idx == 3'd1}} & prescaled_b_frac[52:26])
	| ({(27){scale_factor_idx == 3'd2}} & {2'b0, prescaled_b_frac[52:28]})
	| ({(27){scale_factor_idx == 3'd3}} & 27'b0)
	| ({(27){scale_factor_idx == 3'd4}} & {2'b0, prescaled_b_frac[52:28]})
	| ({(27){scale_factor_idx == 3'd5}} & 27'b0)
	| ({(27){scale_factor_idx == 3'd6}} & {2'b0, prescaled_b_frac[52:28]})
	| ({(27){scale_factor_idx == 3'd7}} & {2'b0, prescaled_b_frac[52:28]})
};

assign scale_adder_29b_opb_1 = 
  scale_adder_29b_opb_1_in[0]
+ scale_adder_29b_opb_1_in[1]
+ scale_adder_29b_opb_1_in[2];

// ================================================================================================================================================
// This adder is used for the low part of f64.opa in pre_0 or pre_1
// ================================================================================================================================================
assign scale_adder_30b_opa_in[0] = {2'b0, prescaled_a_frac[24:0], 3'b0};
assign scale_adder_30b_opa_in[1] = {
	2'b0, 
	  ({(27){scale_factor_idx == 3'd0}} & {prescaled_a_frac[25:0], 1'b0})
	| ({(27){scale_factor_idx == 3'd1}} & prescaled_a_frac[26:0])
	| ({(27){scale_factor_idx == 3'd2}} & {prescaled_a_frac[25:0], 1'b0})
	| ({(27){scale_factor_idx == 3'd3}} & {prescaled_a_frac[25:0], 1'b0})
	| ({(27){scale_factor_idx == 3'd4}} & prescaled_a_frac[26:0])
	| ({(27){scale_factor_idx == 3'd5}} & prescaled_a_frac[26:0])
	| ({(27){scale_factor_idx == 3'd6}} & 27'b0)
	| ({(27){scale_factor_idx == 3'd7}} & 27'b0),
	1'b0
};
assign scale_adder_30b_opa_in[2] = {
	2'b0, 
	  ({(28){scale_factor_idx == 3'd0}} & {prescaled_a_frac[25:0], 2'b0})
	| ({(28){scale_factor_idx == 3'd1}} & {prescaled_a_frac[25:0], 2'b0})
	| ({(28){scale_factor_idx == 3'd2}} & prescaled_a_frac[27:0])
	| ({(28){scale_factor_idx == 3'd3}} & 28'b0)
	| ({(28){scale_factor_idx == 3'd4}} & prescaled_a_frac[27:0])
	| ({(28){scale_factor_idx == 3'd5}} & 28'b0)
	| ({(28){scale_factor_idx == 3'd6}} & prescaled_a_frac[27:0])
	| ({(28){scale_factor_idx == 3'd7}} & prescaled_a_frac[27:0])
};

assign scale_adder_30b_opa = 
  scale_adder_30b_opa_in[0]
+ scale_adder_30b_opa_in[1]
+ scale_adder_30b_opa_in[2];

// ================================================================================================================================================
// This adder is used for the low part of f64.opb in pre_0 or pre_1
// ================================================================================================================================================
assign scale_adder_30b_opb_in[0] = {2'b0, prescaled_b_frac[24:0], 3'b0};
assign scale_adder_30b_opb_in[1] = {
	2'b0, 
	  ({(27){scale_factor_idx == 3'd0}} & {prescaled_b_frac[25:0], 1'b0})
	| ({(27){scale_factor_idx == 3'd1}} & prescaled_b_frac[26:0])
	| ({(27){scale_factor_idx == 3'd2}} & {prescaled_b_frac[25:0], 1'b0})
	| ({(27){scale_factor_idx == 3'd3}} & {prescaled_b_frac[25:0], 1'b0})
	| ({(27){scale_factor_idx == 3'd4}} & prescaled_b_frac[26:0])
	| ({(27){scale_factor_idx == 3'd5}} & prescaled_b_frac[26:0])
	| ({(27){scale_factor_idx == 3'd6}} & 27'b0)
	| ({(27){scale_factor_idx == 3'd7}} & 27'b0),
	1'b0
};
assign scale_adder_30b_opb_in[2] = {
	2'b0, 
	  ({(28){scale_factor_idx == 3'd0}} & {prescaled_b_frac[25:0], 2'b0})
	| ({(28){scale_factor_idx == 3'd1}} & {prescaled_b_frac[25:0], 2'b0})
	| ({(28){scale_factor_idx == 3'd2}} & prescaled_b_frac[27:0])
	| ({(28){scale_factor_idx == 3'd3}} & 28'b0)
	| ({(28){scale_factor_idx == 3'd4}} & prescaled_b_frac[27:0])
	| ({(28){scale_factor_idx == 3'd5}} & 28'b0)
	| ({(28){scale_factor_idx == 3'd6}} & prescaled_b_frac[27:0])
	| ({(28){scale_factor_idx == 3'd7}} & prescaled_b_frac[27:0])
};

assign scale_adder_30b_opb = 
  scale_adder_30b_opb_in[0]
+ scale_adder_30b_opb_in[1]
+ scale_adder_30b_opb_in[2];

// ================================================================================================================================================

// Now, the scaling is finished
// Which frac is larger ?
// f32/f16_with_denormal		: Use cmp_result got in pre_2
// f32/f16_without_denormal		: Use cmp_result got in pre_0
// f64_with_denormal			: Use cmp_result got in pre_1, it is stored in iter_num_q[0]
// f64_without_denormal			: Use cmp_result got in pre_0, it is stored in iter_num_q[0]
assign a_frac_lt_b_frac_real = 
fsm_q[FSM_PRE_0_BIT] ? a_frac_lt_b_frac_f32_f16 : 
((fp_format_q != 2'd2) ? a_frac_lt_b_frac_f32_f16_l_shifted : iter_num_q[0]);

// 57 - 28 = (FP64_FRAC_W+4) - (FP32_FRAC_W+4)
assign scaled_a_frac = 
(fsm_q[FSM_PRE_0_BIT] | (fsm_q[FSM_PRE_2_BIT] & (fp_format_q != 2'd2))) ? {scale_adder_29b_opa_0[27:0], {(57 - 28){1'b0}}} : 
{scale_adder_29b_opa_0[28:0], quo_iter_q[27:0]};
assign scaled_b_frac = 
(fsm_q[FSM_PRE_0_BIT] | (fsm_q[FSM_PRE_2_BIT] & (fp_format_q != 2'd2))) ? {scale_adder_29b_opb_0[27:0], {(57 - 28){1'b0}}} : 
{scale_adder_29b_opb_0[28:0], quo_m1_iter_q[27:0]};

assign f_r_s_iter_init_pre = {3'b0, a_frac_lt_b_frac_real ? {scaled_a_frac, 1'b0} : {1'b0, scaled_a_frac}};
// According to QDS, the 1st quo must be "+1" or "+2", and the sign of the current "f_r" is 0 -> we only need to use (6 - 1 = 5)-bit to cmp.
assign f_r_s_for_integer_quo = f_r_s_iter_init_pre[(REM_W+1)-1-2-1 -: 5];
// The 1st quo can be calculated very fast in Initialization step.
// assign integer_quo_is_pos_2 = (f_r_s_for_integer_quo >= 5'd12);
// Optimize the logic by hand...
assign integer_quo_is_pos_2 = f_r_s_for_integer_quo[4] | (f_r_s_for_integer_quo[3:2] == 2'b11);

assign scaled_b_frac_ext = {2'b0, scaled_b_frac, 1'b0};
assign scaled_b_frac_ext_mul_neg_1 = ~scaled_b_frac_ext;
assign scaled_b_frac_ext_mul_neg_2 = ~{scaled_b_frac_ext[(REM_W-1)-1:0], 1'b0};

// Do "rem[i+1] = 4 * rem[i] - q[i+1] * d"
// For c[N-1:0] = a[N-1:0] - b[N-1:0], if a/b is in the true form, then let sum[N:0] = {a[N-1:0], 1'b1} + {~b[N-1:0], 1'b1}, c[N-1:0] = sum[N:1]
// Some examples:
// a = +15 = 0_1111, b = +6 = 0_0110 ->
// {a, 1} = 0_11111, {~b, 1} = 1_10011
// 0_11111 + 1_10011 = 0_10010: (0_10010)[5:1] = 0_1001 = +9
// a = +13 = 0_1101, b = +9 = 0_1001 ->
// {a, 1} = 0_11011, {~b, 1} = 1_01101
// 0_11011 + 1_01101 = 0_01000: (0_01000)[5:1] = 0_0100 = +4
// According to the QDS, the 1st quo_dig must be "+1", so we need to do "a_frac_i - b_frac_i".
// As a result, we should initialize "sum/carry" using the following value.

assign f_r_s_iter_init = {f_r_s_iter_init_pre[(REM_W+1)-1-2:0], 1'b1};
assign f_r_c_iter_init = integer_quo_is_pos_2 ? scaled_b_frac_ext_mul_neg_2 : scaled_b_frac_ext_mul_neg_1;

assign f_r_s_d = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_2_BIT]) ? f_r_s_iter_init : nxt_f_r_s[2];
assign f_r_s_en = start_handshaked | fsm_q[FSM_PRE_2_BIT] | fsm_q[FSM_ITER_BIT];

assign f_r_c_d = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_2_BIT]) ? f_r_c_iter_init : nxt_f_r_c[2];
assign f_r_c_en = start_handshaked | fsm_q[FSM_PRE_2_BIT] | fsm_q[FSM_ITER_BIT];

// In the ref design, we need to use "(f_r * 4)[MSB -: 6]" for QDS
assign adder_6b_iter_init = f_r_s_iter_init[(REM_W-1)-2 -: 6] + f_r_c_iter_init[(REM_W-1)-2 -: 6];
// When you have f_r[i], and want to do addition for QDS which is used to generate q[i + 2], you need to 
// include 1-extra bit in the adder, to catch the carry from the LSBs
assign adder_7b_iter_init = f_r_s_iter_init[(REM_W-1)-2-2 -: 7] + f_r_c_iter_init[(REM_W-1)-2-2 -: 7];

assign nr_f_r_6b_for_nxt_cycle_s0_qds_en = 
  start_handshaked
| fsm_q[FSM_PRE_2_BIT]
| fsm_q[FSM_ITER_BIT];
// This signal should be in the critical path
assign nr_f_r_6b_for_nxt_cycle_s0_qds_d = 
(fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_2_BIT]) ? adder_6b_iter_init : 
adder_6b_res_for_nxt_cycle_s0_qds;

assign nr_f_r_7b_for_nxt_cycle_s1_qds_en = 
  start_handshaked
| fsm_q[FSM_PRE_2_BIT]
| fsm_q[FSM_ITER_BIT];
// This signal should be in the critical path
assign nr_f_r_7b_for_nxt_cycle_s1_qds_d = 
(fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_2_BIT]) ? adder_7b_iter_init : 
adder_7b_res_for_nxt_cycle_s1_qds;

always_ff @(posedge clk) begin
	if(nr_f_r_6b_for_nxt_cycle_s0_qds_en)
		nr_f_r_6b_for_nxt_cycle_s0_qds_q <= nr_f_r_6b_for_nxt_cycle_s0_qds_d;
	if(nr_f_r_7b_for_nxt_cycle_s1_qds_en)
		nr_f_r_7b_for_nxt_cycle_s1_qds_q <= nr_f_r_7b_for_nxt_cycle_s1_qds_d;

	if(f_r_s_en)
		f_r_s_q <= f_r_s_d;
	if(f_r_c_en)
		f_r_c_q <= f_r_c_d;
end


// ================================================================================================================================================
// How to use "frac_divisor"
// pre_0
// init_cycles[0] = 1: scaled_b_frac
// init_cycles[1] = 1: When (f32/f16), DON'T CARE; else, {scale_adder_29b_opa_1[28:24], scale_adder_29b_opb_1[28:24]}
// init_cycles[2] = 1: {opa_l_shift_num[5:3], opb_l_shift_num[5:3]}
// pre_1
// {scale_adder_29b_opa_1[28:24], scale_adder_29b_opb_1[28:24]}
// pre_2
// scaled_b_frac
// post_0
// 54-bit sticky_without_rem
assign nxt_frac_divisor_pre_0 = 
  ({(57){init_cycles[0]}} & scaled_b_frac)
| ({(57){init_cycles[1]}} & {frac_divisor_q[56:10], scale_adder_29b_opa_1[28:24], scale_adder_29b_opb_1[28:24]})
| ({(57){init_cycles[2]}} & {frac_divisor_q[56:6], opa_l_shift_num[5:3], opb_l_shift_num[5:3]});

assign nxt_frac_divisor_pre_1 = {frac_divisor_q[56:10], scale_adder_29b_opa_1[28:24], scale_adder_29b_opb_1[28:24]};

assign nxt_frac_divisor_pre_2 = scaled_b_frac;

assign frac_divisor_d = 
  ({(57){fsm_q[FSM_PRE_0_BIT ]}} & nxt_frac_divisor_pre_0)
| ({(57){fsm_q[FSM_PRE_1_BIT ]}} & nxt_frac_divisor_pre_1)
| ({(57){fsm_q[FSM_PRE_2_BIT ]}} & nxt_frac_divisor_pre_2)
| ({(57){fsm_q[FSM_POST_0_BIT]}} & {frac_divisor_q[56:54], sticky_without_rem});

assign frac_divisor_en = 
  start_handshaked
| fsm_q[FSM_PRE_1_BIT]
| fsm_q[FSM_PRE_2_BIT]
| (fsm_q[FSM_POST_0_BIT] & res_is_denormal);
always_ff @(posedge clk)
	if(frac_divisor_en)
		frac_divisor_q <= frac_divisor_d;

// ================================================================================================================================================
assign prev_quo_dig_en = 
  start_handshaked
| fsm_q[FSM_PRE_2_BIT]
| fsm_q[FSM_ITER_BIT];

assign prev_quo_dig_d = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_2_BIT]) ? {3'b0, ~integer_quo_is_pos_2, integer_quo_is_pos_2} : nxt_quo_dig[2];

always_ff @(posedge clk)
	if(prev_quo_dig_en)
		prev_quo_dig_q <= prev_quo_dig_d;


// ================================================================================================================================================
// On the Fly Conversion (OFC/OTFC)
// ================================================================================================================================================
assign nxt_quo_iter[0] = 
  ({(56){prev_quo_dig_q[QUO_DIG_POS_2_BIT]}} & {quo_iter_q   [(56-1)-2:0], 2'b10})
| ({(56){prev_quo_dig_q[QUO_DIG_POS_1_BIT]}} & {quo_iter_q   [(56-1)-2:0], 2'b01})
| ({(56){prev_quo_dig_q[QUO_DIG_NEG_0_BIT]}} & {quo_iter_q   [(56-1)-2:0], 2'b00})
| ({(56){prev_quo_dig_q[QUO_DIG_NEG_1_BIT]}} & {quo_m1_iter_q[(56-1)-2:0], 2'b11})
| ({(56){prev_quo_dig_q[QUO_DIG_NEG_2_BIT]}} & {quo_m1_iter_q[(56-1)-2:0], 2'b10});
assign nxt_quo_m1_iter[0] = 
  ({(56){prev_quo_dig_q[QUO_DIG_POS_2_BIT]}} & {quo_iter_q   [(56-1)-2:0], 2'b01})
| ({(56){prev_quo_dig_q[QUO_DIG_POS_1_BIT]}} & {quo_iter_q   [(56-1)-2:0], 2'b00})
| ({(56){prev_quo_dig_q[QUO_DIG_NEG_0_BIT]}} & {quo_m1_iter_q[(56-1)-2:0], 2'b11})
| ({(56){prev_quo_dig_q[QUO_DIG_NEG_1_BIT]}} & {quo_m1_iter_q[(56-1)-2:0], 2'b10})
| ({(56){prev_quo_dig_q[QUO_DIG_NEG_2_BIT]}} & {quo_m1_iter_q[(56-1)-2:0], 2'b01});
assign nxt_quo_iter[1] = 
  ({(56){nxt_quo_dig[0][QUO_DIG_POS_2_BIT]}} & {nxt_quo_iter   [0][(56-1)-2:0], 2'b10})
| ({(56){nxt_quo_dig[0][QUO_DIG_POS_1_BIT]}} & {nxt_quo_iter   [0][(56-1)-2:0], 2'b01})
| ({(56){nxt_quo_dig[0][QUO_DIG_NEG_0_BIT]}} & {nxt_quo_iter   [0][(56-1)-2:0], 2'b00})
| ({(56){nxt_quo_dig[0][QUO_DIG_NEG_1_BIT]}} & {nxt_quo_m1_iter[0][(56-1)-2:0], 2'b11})
| ({(56){nxt_quo_dig[0][QUO_DIG_NEG_2_BIT]}} & {nxt_quo_m1_iter[0][(56-1)-2:0], 2'b10});
assign nxt_quo_m1_iter[1] = 
  ({(56){nxt_quo_dig[0][QUO_DIG_POS_2_BIT]}} & {nxt_quo_iter   [0][(56-1)-2:0], 2'b01})
| ({(56){nxt_quo_dig[0][QUO_DIG_POS_1_BIT]}} & {nxt_quo_iter   [0][(56-1)-2:0], 2'b00})
| ({(56){nxt_quo_dig[0][QUO_DIG_NEG_0_BIT]}} & {nxt_quo_m1_iter[0][(56-1)-2:0], 2'b11})
| ({(56){nxt_quo_dig[0][QUO_DIG_NEG_1_BIT]}} & {nxt_quo_m1_iter[0][(56-1)-2:0], 2'b10})
| ({(56){nxt_quo_dig[0][QUO_DIG_NEG_2_BIT]}} & {nxt_quo_m1_iter[0][(56-1)-2:0], 2'b01});
assign nxt_quo_iter[2] = 
  ({(56){nxt_quo_dig[1][QUO_DIG_POS_2_BIT]}} & {nxt_quo_iter   [1][(56-1)-2:0], 2'b10})
| ({(56){nxt_quo_dig[1][QUO_DIG_POS_1_BIT]}} & {nxt_quo_iter   [1][(56-1)-2:0], 2'b01})
| ({(56){nxt_quo_dig[1][QUO_DIG_NEG_0_BIT]}} & {nxt_quo_iter   [1][(56-1)-2:0], 2'b00})
| ({(56){nxt_quo_dig[1][QUO_DIG_NEG_1_BIT]}} & {nxt_quo_m1_iter[1][(56-1)-2:0], 2'b11})
| ({(56){nxt_quo_dig[1][QUO_DIG_NEG_2_BIT]}} & {nxt_quo_m1_iter[1][(56-1)-2:0], 2'b10});
assign nxt_quo_m1_iter[2] = 
  ({(56){nxt_quo_dig[1][QUO_DIG_POS_2_BIT]}} & {nxt_quo_iter   [1][(56-1)-2:0], 2'b01})
| ({(56){nxt_quo_dig[1][QUO_DIG_POS_1_BIT]}} & {nxt_quo_iter   [1][(56-1)-2:0], 2'b00})
| ({(56){nxt_quo_dig[1][QUO_DIG_NEG_0_BIT]}} & {nxt_quo_m1_iter[1][(56-1)-2:0], 2'b11})
| ({(56){nxt_quo_dig[1][QUO_DIG_NEG_1_BIT]}} & {nxt_quo_m1_iter[1][(56-1)-2:0], 2'b10})
| ({(56){nxt_quo_dig[1][QUO_DIG_NEG_2_BIT]}} & {nxt_quo_m1_iter[1][(56-1)-2:0], 2'b01});

// How to use "quo_iter_q":
// pre_0
// 1. f32_f16_without_denormal &  opb_is_power_of_2: opa_frac_l_shifted_f32_f16
// 2. f32_f16_without_denormal & ~opb_is_power_of_2: 0
// 3. f32_f16_with_denormal, regardless of the value of "opb_is_power_of_2": opa_frac_l_shifted_f32_f16
// 4. f64_without_denormal &  opb_is_power_of_2: opa_frac
// 5. f64_without_denormal & ~opb_is_power_of_2: {scaled_op_pre, scaled_op}
// 6. f64_with_denormal: opa_frac_l_shifted_s2_to_s0
// pre_1
// 1. f64_with_denormal & ~opb_is_power_of_2: {scaled_op_pre, scaled_op}
// 2. f64_with_denormal &  opb_is_power_of_2: opa_frac_l_shifted
// pre_2
// now we must enter FSM_ITER to get final result: 0
assign nxt_quo_iter_pre_0 = 
init_cycles[0] ? (
	opb_is_power_of_2 ? (
		(fp_format_i == 2'd0) ? {{(54 - 11){1'b0}}, 1'b1, opa_i[9:0]} : 
		{{(54 - 24){1'b0}}, 1'b1, opa_i[22:0]}
	) : 
	'0
) : 
init_cycles[1] ? (
	opb_is_power_of_2 ? (
		(fp_format_i == 2'd0) ? {{(54 - 11){1'b0}}, 1'b1, opa_frac_l_shifted_f32_f16[22 -: 10]} : 
		(fp_format_i == 2'd1) ? {{(54 - 24){1'b0}}, 1'b1, opa_frac_l_shifted_f32_f16[22:0]} : 
		{{(54 - 53){1'b0}}, 1'b1, opa_i[51:0]}
	) : 
	((fp_format_i != 2'd2) ? {{(54 - 23){1'b0}}, opa_frac_l_shifted_f32_f16[22:0]} : {scale_adder_29b_opa_1[23:0], scale_adder_30b_opa[29:0]})
) : 
{{(54 - 52){1'b0}}, opa_frac_l_shifted_s2_to_s0};

assign nxt_quo_iter_pre_1 = 
opb_is_power_of_2_q ? {{(54 - 53){1'b0}}, 1'b1, opa_frac_l_shifted[51:0]} : 
{scale_adder_29b_opa_1[23:0], scale_adder_30b_opa[29:0]};

assign nxt_quo_iter_pre_2 = '0;

// How to use "quo_m1_iter_q":
// pre_0
// 1. f32_f16_without_denormal &  opb_is_power_of_2: DON'T CARE
// 2. f32_f16_without_denormal & ~opb_is_power_of_2: DON'T CARE
// 3. f32_f16_with_denormal &  opb_is_power_of_2: DON'T CARE
// 4. f32_f16_with_denormal & ~opb_is_power_of_2: opb_frac_l_shifted_f32_f16
// 5. f64_without_denormal &  opb_is_power_of_2: DON'T CARE
// 6. f64_without_denormal & ~opb_is_power_of_2: {scaled_op_pre, scaled_op}
// 7. f64_with_denormal: opb_frac_l_shifted_s2_to_s0
// pre_1
// 1. f64_with_denormal & ~opb_is_power_of_2: {scaled_op_pre, scaled_op}
// 2. f64_with_denormal &  opb_is_power_of_2: DON'T CARE
// pre_2
// now we must enter FSM_ITER to get final result: DON'T CARE
// post_0, when (res_is_denormal), use this reg to store "correct_quo_r_shifted[52:0]" and "rem_is_not_zero"
// Since the integer part of correct_quo_r_shifted (It is correct_quo_r_shifted[53]) is not needed for rounding, we don't have to remember it.
// Since the complexity of "quo_iter_d" is already great, we should move some logics to "quo_m1_iter_d" for balance.
assign nxt_quo_m1_iter_pre_0 = 
init_cycles[1] ? ((fp_format_i != 2'd2) ? {{(54 - 23){1'b0}}, opb_frac_l_shifted_f32_f16[22:0]} : {scale_adder_29b_opb_1[23:0], scale_adder_30b_opb[29:0]}) : 
{{(54 - 52){1'b0}}, opb_frac_l_shifted_s2_to_s0};

assign nxt_quo_m1_iter_pre_1 = {scale_adder_29b_opb_1[23:0], scale_adder_30b_opb[29:0]};

assign nxt_quo_m1_iter_post_0 = {rem_is_not_zero, correct_quo_r_shifted[52:0]};

assign quo_iter_d = 
  ({(54){fsm_q[FSM_PRE_0_BIT]}} & nxt_quo_iter_pre_0)
| ({(54){fsm_q[FSM_PRE_1_BIT]}} & nxt_quo_iter_pre_1)
| ({(54){fsm_q[FSM_PRE_2_BIT]}} & nxt_quo_iter_pre_2)
| ({(54){fsm_q[FSM_ITER_BIT ]}} & nxt_quo_iter[2][53:0]);

assign quo_m1_iter_d = 
  ({(54){fsm_q[FSM_PRE_0_BIT ]}} & nxt_quo_m1_iter_pre_0)
| ({(54){fsm_q[FSM_PRE_1_BIT ]}} & nxt_quo_m1_iter_pre_1)
| ({(54){fsm_q[FSM_ITER_BIT  ]}} & nxt_quo_m1_iter[2][53:0])
| ({(54){fsm_q[FSM_POST_0_BIT]}} & nxt_quo_m1_iter_post_0);

assign quo_iter_en = 
  start_handshaked
| fsm_q[FSM_PRE_1_BIT] 
| fsm_q[FSM_PRE_2_BIT] 
| fsm_q[FSM_ITER_BIT];

assign quo_m1_iter_en = 
  start_handshaked
| fsm_q[FSM_PRE_1_BIT]
| fsm_q[FSM_ITER_BIT] 
| (fsm_q[FSM_POST_0_BIT] & res_is_denormal);

always_ff @(posedge clk) begin
	if(quo_iter_en)
		quo_iter_q <= quo_iter_d;
	if(quo_m1_iter_en)
		quo_m1_iter_q <= quo_m1_iter_d;
end

// ================================================================================================================================================

assign final_iter = (iter_num_q == 4'd0);
// f64: 9 - 1 = 8
// f32: 4 - 1 = 3
// f16: 2 - 1 = 1
assign iter_num_needed = 
fsm_q[FSM_PRE_0_BIT] ? ((fp_format_i == 2'd0) ? 4'd1 : (fp_format_i == 2'd1) ? 4'd3 : 4'd8) : 
((fp_format_q == 2'd0) ? 4'd1 : (fp_format_q == 2'd1) ? 4'd3 : 4'd8);

assign iter_num_en = 
  start_handshaked 
| fsm_q[FSM_PRE_1_BIT] 
| fsm_q[FSM_PRE_2_BIT] 
| fsm_q[FSM_ITER_BIT];
// pre_0:
// f32/f16_without_denormal: We can start iter in the next cycle -> load "iter_num_needed"
// f64_without_denormal: store the cmp_result
// pre_1: It must be "f64_with_denormal" -> store the cmp_result
// pre_2: It is supposed to start iter in the next cycle -> load "iter_num_needed"
assign iter_num_d  = 
fsm_q[FSM_PRE_0_BIT] ? (init_cycles[0] ? iter_num_needed : {3'b0, a_frac_lt_b_frac}) : 
fsm_q[FSM_PRE_1_BIT] ? {3'b0, a_frac_lt_b_frac_l_shifted} : 
fsm_q[FSM_PRE_2_BIT] ? iter_num_needed : 
(iter_num_q - 4'd1);
always_ff @(posedge clk)
	if(iter_num_en)
		iter_num_q <= iter_num_d;

// ================================================================================================================================================
// Radix-64 Block, formed by 3 overlapped Radix-4 Blocks
// ================================================================================================================================================
fpdiv_r64_block #(
	.QDS_ARCH(QDS_ARCH),
	.S1_SPECULATIVE_QDS(S1_SPECULATIVE_QDS),
	.REM_W(REM_W),
	.QUO_DIG_W(QUO_DIG_W)
) u_r64_block (
	.f_r_s_i(f_r_s_q),
	.f_r_c_i(f_r_c_q),
	.divisor_i(frac_divisor_q),
	.nr_f_r_6b_for_nxt_cycle_s0_qds_i(nr_f_r_6b_for_nxt_cycle_s0_qds_q),
	.nr_f_r_7b_for_nxt_cycle_s1_qds_i(nr_f_r_7b_for_nxt_cycle_s1_qds_q),

	.nxt_quo_dig_o(nxt_quo_dig),
	.nxt_f_r_s_o(nxt_f_r_s),
	.nxt_f_r_c_o(nxt_f_r_c),
	.adder_6b_res_for_nxt_cycle_s0_qds_o(adder_6b_res_for_nxt_cycle_s0_qds),
	.adder_7b_res_for_nxt_cycle_s1_qds_o(adder_7b_res_for_nxt_cycle_s1_qds)
);

// ================================================================================================================================================
// post_0
// ================================================================================================================================================

// nr = non_redundant
assign nr_f_r = f_r_s_q + f_r_c_q;

// For c[N-1:0] = a[N-1:0] + b[N-1:0], if we want to know the value of "c == 0", the common method is:
// 1. Use a N-bit FA to get c
// 2. Calculate (c == 0)
// The total delay = delay(N-bit FA) + delay(N-bit NOT OR)
// A faster method is:
// a_b_xor[N-2:0] = a[N-1:1] ^ b[N-1:1]
// a_b_or[N-2:0] = a[N-2:0] | b[N-2:0]
// Then, (c == 0) <=> (a_b_xor == a_b_or)
// Some examples
// a[15:0] = 1111001111000000
// b[15:0] = (2 ^ 16) - a = 0000110001000000
// a_b_xor[14:0] = 111111111000000
// a_b_or[14:0] = 111111111000000
// ->
// We get (a_b_xor == a_b_or), and we also get ((a + b) == 0)

// a[11:0] = 000000001111
// b[11:0] = (2 ^ 12) - a = 111111110001
// a_b_xor[10:0] = 11111111111
// a_b_or[10:0] = 11111111111
// -> 
// We get (a_b_xor == a_b_or), and we also get ((a + b) == 0)

// a[15:0] = 0101111100001111
// b[15:0] = (2 ^ 16) - a + 0000000011111111 = 1010000111110000
// a_b_xor[14:0] = 111111101111111
// a_b_or[14:0] = 111111111111111
// -> 
// We get (a_b_xor != a_b_or), and we also get ((a + b) != 0)

// By using the above method, the total delay = delay(XOR) + delay(XOR) + delay(N-bit NOT OR)

// For f_r, the MSB is sign, so we only need to know the value of ((f_r_s_q[(REM_W-1)-1:0] + f_r_c_q[(REM_W-1)-1:0]) == 0)
// Apparently, the calculation of "{f_r_xor, f_r_or, f_r_xor != f_r_or}" and "nr_f_r[REM_W-1]" is in parallel
assign f_r_xor = f_r_s_q[(REM_W-1)-1:1] ^ f_r_c_q[(REM_W-1)-1:1];
assign f_r_or = f_r_s_q[(REM_W-1)-2:0] | f_r_c_q[(REM_W-1)-2:0];
// The algorithm we use is "Minimally Redundant Radix 4", and its redundnat factor = 2/3.
// So we must have "|rem| <= D * (2/3)" -> when (nr_f_r < 0), the "positive rem" must be NON_ZERO
// Which also means we don't have to calculate "nr_f_r_plus_d"
assign rem_is_not_zero = ~opb_is_power_of_2_q & (nr_f_r[REM_W-1] | (f_r_xor != f_r_or));

// Now, we have already got 55/25/13-bit Q for f64/f32/f16
// ATTENTION: The MSB must be 1 because we have already do a 1-bit l_shift in the initialization step when (a_frac < b_frac)
// Take f64 as an example.
// In fact, we don't need Q[0] to calculate sticky_bit, reason:
// Q[0] = 0: REM could be ZERO/NON_ZERO
// Q[0] = 1: REM must also be NON_ZERO
// The proof is very easy: Q[0] is the digit in "2 ^ -54" of "a_frac[52:0] / b_frac[52:0]". When Q[0] = 1, "exact division" is impossible.
// In conlusion, we only need "REM" to calculate sticky_bit
// The similiar optimization could also be applied to f16
// For f32, that optimization is not needed because we perfectly get 25-bit Q[24:0]
// With this optimization we could save some "OR" gates, and the width of the r_shifter is also decreased.
assign quo_pre_shift = 
opb_is_power_of_2_q ? {quo_iter_q[52:0], 1'b0} : 
{nxt_quo_iter[0][54:26], (fp_format_q == 2'd1) ? nxt_quo_iter[0][24:0] : nxt_quo_iter[0][25:1]};

assign quo_m1_pre_shift = {nxt_quo_m1_iter[0][54:26], (fp_format_q == 2'd1) ? nxt_quo_m1_iter[0][24:0] : nxt_quo_m1_iter[0][25:1]};

assign r_shift_num_pre = 13'd1 - out_exp_diff_q;
assign r_shift_num_pre_minus_limit = 13'd1 - out_exp_diff_q - R_SHIFT_NUM_LIMIT;
assign r_shift_num = r_shift_num_pre[12] ? 6'd0 : ~r_shift_num_pre_minus_limit[12] ? R_SHIFT_NUM_LIMIT : r_shift_num_pre[5:0];

assign quo_r_shifted    = {quo_pre_shift,    54'b0} >> r_shift_num;
assign quo_m1_r_shifted = {quo_m1_pre_shift, 54'b0} >> r_shift_num;

assign select_quo_m1 = nr_f_r[REM_W-1] & ~opb_is_power_of_2_q;
assign correct_quo_r_shifted = select_quo_m1 ? quo_m1_r_shifted[54 +: 54] : quo_r_shifted[54 +: 54];
assign sticky_without_rem = select_quo_m1 ? quo_m1_r_shifted[0 +: 54] : quo_r_shifted[0 +: 54];

// We only need to increase the fractional part of the Q: A 53-bit and a 52-bit incrementers are enough...
assign quo_pre_inc = fsm_q[FSM_POST_0_BIT] ? {
	quo_pre_shift[52:25], 
	~(fp_format_q == 2'd1) & quo_pre_shift[24], 
	quo_pre_shift[23:12],
	~(fp_format_q == 2'd0) & quo_pre_shift[11], 
	quo_pre_shift[10:1]
} : {
	quo_m1_iter_q[52:25], 
	~(fp_format_q == 2'd1) & quo_m1_iter_q[24], 
	quo_m1_iter_q[23:12],
	~(fp_format_q == 2'd0) & quo_m1_iter_q[11], 
	quo_m1_iter_q[10:1]
};
assign quo_m1_pre_inc = {
	quo_m1_pre_shift[52:25], 
	~(fp_format_q == 2'd1) & quo_m1_pre_shift[24], 
	quo_m1_pre_shift[23:12],
	~(fp_format_q == 2'd0) & quo_m1_pre_shift[11], 
	quo_m1_pre_shift[10:1]
};
// Used in post_0/post_1
assign quo_inc_res[52:0] = {1'b0, quo_pre_inc[51:0]} + {52'b0, 1'b1};
// For Q_M1, "carry_after_round" is impossible
assign quo_m1_inc_res[51:0] = (quo_pre_inc[0] == quo_m1_pre_inc[0]) ? quo_inc_res[51:0] : quo_pre_inc[51:0];


assign guard_bit_quo = fsm_q[FSM_POST_0_BIT] ? quo_pre_shift[1] : quo_m1_iter_q[1];
assign round_bit_quo = fsm_q[FSM_POST_0_BIT] ? quo_pre_shift[0] : quo_m1_iter_q[0];
assign sticky_bit_quo = fsm_q[FSM_POST_0_BIT] ? rem_is_not_zero : (quo_m1_iter_q[53] | (frac_divisor_q[53:0] != 54'b0));
assign quo_need_rup = 
  ({rm_q == RM_RNE} & ((round_bit_quo & sticky_bit_quo) | (guard_bit_quo & round_bit_quo)))
| ({rm_q == RM_RDN} & ((round_bit_quo | sticky_bit_quo) &  out_sign_q))
| ({rm_q == RM_RUP} & ((round_bit_quo | sticky_bit_quo) & ~out_sign_q))
| ({rm_q == RM_RMM} &   round_bit_quo);
assign inexact_quo = round_bit_quo | sticky_bit_quo;

assign guard_bit_quo_m1 = quo_m1_pre_shift[1];
assign round_bit_quo_m1 = quo_m1_pre_shift[0];
// When we need to use "Q_M1", the sticky_bit must be 1
assign sticky_bit_quo_m1 = 1'b1;
assign quo_m1_need_rup = 
  ({rm_q == RM_RNE} & ((round_bit_quo_m1 & sticky_bit_quo_m1) | (guard_bit_quo_m1 & round_bit_quo_m1)))
| ({rm_q == RM_RDN} & ((round_bit_quo_m1 | sticky_bit_quo_m1) &  out_sign_q))
| ({rm_q == RM_RUP} & ((round_bit_quo_m1 | sticky_bit_quo_m1) & ~out_sign_q))
| ({rm_q == RM_RMM} &   round_bit_quo_m1);
// assign inexact_quo_m1 = round_bit_quo_m1 | sticky_bit_quo_m1;
assign inexact_quo_m1 = 1'b1;

assign quo_rounded = quo_need_rup ? quo_inc_res[52:0] : {1'b0, quo_pre_inc};
assign quo_m1_rounded = quo_m1_need_rup ? quo_m1_inc_res : quo_m1_pre_inc;
assign inexact = fsm_q[FSM_POST_0_BIT] ? (select_quo_m1 | inexact_quo) : inexact_quo;

assign frac_rounded_post_0 = select_quo_m1 ? quo_m1_rounded[51:0] : quo_rounded[51:0];
// This signal could only be 1 in post_1
assign carry_after_round = (fp_format_q == 2'd0) ? quo_rounded[10] : (fp_format_q == 2'd1) ? quo_rounded[23] : quo_rounded[52];


// In post_0, the result must be a normal/overflow number
// overflow could only happen in post_0
assign overflow = (out_exp_diff_q[11:0] >= ((fp_format_q == 2'd0) ? 12'd31 : (fp_format_q == 2'd1) ? 12'd255 : 12'd2047));
assign overflow_to_inf = 
  (rm_q == RM_RNE) 
| (rm_q == RM_RMM) 
| ((rm_q == RM_RUP) & ~out_sign_q) 
| ((rm_q == RM_RDN) & out_sign_q);

assign f16_out_exp_post_0 = 
(overflow &  overflow_to_inf) ? {(5){1'b1}} : 
(overflow & ~overflow_to_inf) ? {{(4){1'b1}}, 1'b0} : 
out_exp_diff_q[4:0];

assign f32_out_exp_post_0 = 
(overflow &  overflow_to_inf) ? {(8){1'b1}} : 
(overflow & ~overflow_to_inf) ? {{(7){1'b1}}, 1'b0} : 
out_exp_diff_q[7:0];

assign f64_out_exp_post_0 = 
(overflow &  overflow_to_inf) ? {(11){1'b1}} : 
(overflow & ~overflow_to_inf) ? {{(10){1'b1}}, 1'b0} : 
out_exp_diff_q[10:0];

assign f16_out_frac_post_0 = 
(overflow &  overflow_to_inf) ? 10'b0 : 
(overflow & ~overflow_to_inf) ? {(10){1'b1}} : 
frac_rounded_post_0[9:0];

assign f32_out_frac_post_0 = 
(overflow &  overflow_to_inf) ? 23'b0 : 
(overflow & ~overflow_to_inf) ? {(23){1'b1}} : 
frac_rounded_post_0[22:0];

assign f64_out_frac_post_0 = 
(overflow &  overflow_to_inf) ? 52'b0 : 
(overflow & ~overflow_to_inf) ? {(52){1'b1}} : 
frac_rounded_post_0[51:0];

assign f16_res_post_0 = {out_sign_q, f16_out_exp_post_0, f16_out_frac_post_0};
assign f32_res_post_0 = {out_sign_q, f32_out_exp_post_0, f32_out_frac_post_0};
assign f64_res_post_0 = {out_sign_q, f64_out_exp_post_0, f64_out_frac_post_0};

assign fpdiv_res_post_0 = {
	f64_res_post_0[63:32], 
	(fp_format_q == 2'd1) ? f32_res_post_0[31:16] : f64_res_post_0[31:16],
	(fp_format_q == 2'd0) ? f16_res_post_0[15:0] : (fp_format_q == 2'd1) ? f32_res_post_0[15:0] : f64_res_post_0[15:0]
};

// In post_1, the result before rounding must be a denormal number or a special number
assign f16_out_exp_post_1 = 
(res_is_nan_q | res_is_inf_q) ? {(5){1'b1}} : 
res_is_exact_zero_q ? 5'b0 : 
{4'b0, carry_after_round};

assign f32_out_exp_post_1 = 
(res_is_nan_q | res_is_inf_q) ? {(8){1'b1}} : 
res_is_exact_zero_q ? 8'b0 : 
{7'b0, carry_after_round};

assign f64_out_exp_post_1 = 
(res_is_nan_q | res_is_inf_q) ? {(11){1'b1}} : 
res_is_exact_zero_q ? 11'b0 : 
{10'b0, carry_after_round};

assign f16_out_frac_post_1 = 
res_is_nan_q ? {1'b1, 9'b0} : 
(res_is_inf_q | res_is_exact_zero_q) ? 10'b0 : 
quo_rounded[9:0];

assign f32_out_frac_post_1 = 
res_is_nan_q ? {1'b1, 22'b0} : 
(res_is_inf_q | res_is_exact_zero_q) ? 23'b0 : 
quo_rounded[22:0];

assign f64_out_frac_post_1 = 
res_is_nan_q ? {1'b1, 51'b0} : 
(res_is_inf_q | res_is_exact_zero_q) ? 52'b0 : 
quo_rounded[51:0];

assign f16_res_post_1 = {out_sign_q, f16_out_exp_post_1, f16_out_frac_post_1};
assign f32_res_post_1 = {out_sign_q, f32_out_exp_post_1, f32_out_frac_post_1};
assign f64_res_post_1 = {out_sign_q, f64_out_exp_post_1, f64_out_frac_post_1};

assign fpdiv_res_post_1 = {
	f64_res_post_1[63:32], 
	(fp_format_q == 2'd1) ? f32_res_post_1[31:16] : f64_res_post_1[31:16],
	(fp_format_q == 2'd0) ? f16_res_post_1[15: 0] : (fp_format_q == 2'd1) ? f32_res_post_1[15: 0] : f64_res_post_1[15: 0]
};

assign fpdiv_res_o = fsm_q[FSM_POST_0_BIT] ? fpdiv_res_post_0 : fpdiv_res_post_1;

assign fflags_invalid_operation = op_invalid_div_q;
assign fflags_div_by_zero = divided_by_zero_q;
// As said before, overflow could only happen in post_0
assign fflags_overflow = fsm_q[FSM_POST_0_BIT] & overflow;
// As said before, underflow could only happen in post_1
assign fflags_underflow = fsm_q[FSM_POST_1_BIT] & ~carry_after_round & inexact & ~res_is_exact_zero_q & ~res_is_inf_q & ~res_is_nan_q;
assign fflags_inexact = ((fsm_q[FSM_POST_0_BIT] & overflow) | inexact) & ~res_is_inf_q & ~res_is_nan_q & ~res_is_exact_zero_q;

assign fflags_o = {
	fflags_invalid_operation,
	fflags_div_by_zero,
	fflags_overflow,
	fflags_underflow,
	fflags_inexact
};

endmodule

