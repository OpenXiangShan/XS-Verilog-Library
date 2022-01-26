// ========================================================================================================
// File Name			: fpsqrt_scalar_r16.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-17 17:06:55
// Last Modified Time   : 2022-01-26 11:37:47
// ========================================================================================================
// Description	:
// A high performance Floating Point Square-Root module, based on Radix-16 SRT algorithm.
// It supports f16/f32/f64.
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

module fpsqrt_scalar_r16 #(
	// Put some parameters here, which can be changed by other modules
)(
	input  logic start_valid_i,
	output logic start_ready_o,
	input  logic flush_i,
	// 2'd0: f16
	// 2'd1: f16
	// 2'd2: f64
	input  logic [2-1:0] fp_format_i,
	input  logic [64-1:0] op_i,
	input  logic [3-1:0] rm_i,

	output logic finish_valid_o,
	input  logic finish_ready_i,
	output logic [64-1:0] fpsqrt_res_o,
	output logic [5-1:0] fflags_o,

	input  logic clk,
	input  logic rst_n
);

// ================================================================================================================================================
// (local) parameters begin

localparam REM_W = 2 + 54;

localparam FP64_FRAC_W = 52 + 1;
localparam FP32_FRAC_W = 23 + 1;
localparam FP16_FRAC_W = 10 + 1;

localparam FP64_EXP_W = 11;
localparam FP32_EXP_W = 8;
localparam FP16_EXP_W = 5;

localparam FSM_W = 4;
localparam FSM_PRE_0 	= (1 << 0);
localparam FSM_PRE_1 	= (1 << 1);
localparam FSM_ITER  	= (1 << 2);
localparam FSM_POST_0 	= (1 << 3);

localparam FSM_PRE_0_BIT 	= 0;
localparam FSM_PRE_1_BIT 	= 1;
localparam FSM_ITER_BIT 	= 2;
localparam FSM_POST_0_BIT 	= 3;

localparam RT_DIG_W = 5;

localparam RT_DIG_NEG_2_BIT = 4;
localparam RT_DIG_NEG_1_BIT = 3;
localparam RT_DIG_NEG_0_BIT = 2;
localparam RT_DIG_POS_1_BIT = 1;
localparam RT_DIG_POS_2_BIT = 0;

localparam RT_DIG_NEG_2 = (1 << 4);
localparam RT_DIG_NEG_1 = (1 << 3);
localparam RT_DIG_NEG_0 = (1 << 2);
localparam RT_DIG_POS_1 = (1 << 1);
localparam RT_DIG_POS_2 = (1 << 0);

// Used when we find that the op is the power of 2 and it has an odd_exp.
localparam SQRT_2_WITH_ROUND_BIT = 54'b1_01101010000010011110011001100111111100111011110011001;

localparam RM_RNE = 3'b000;
localparam RM_RTZ = 3'b001;
localparam RM_RDN = 3'b010;
localparam RM_RUP = 3'b011;
localparam RM_RMM = 3'b100;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

// Some abbreviations:
// rt = root
// f_r = frac_rem
// f_r_s = frac_rem_sum
// f_r_c = frac_rem_carry
// ext = extended
// nr = non_redundant

logic start_handshaked;
logic [FSM_W-1:0] fsm_d;
logic [FSM_W-1:0] fsm_q;

logic iter_num_en;
logic [4-1:0] iter_num_d;
logic [4-1:0] iter_num_q;
logic final_iter;

logic out_sign_d;
logic out_sign_q;
logic [2-1:0] fp_format_d;
logic [2-1:0] fp_format_q;
logic [3-1:0] rm_d;
logic [3-1:0] rm_q;
logic [11-1:0] out_exp_d;
logic [11-1:0] out_exp_q;
logic [12-1:0] res_exp_pre;

logic op_sign;
logic [11-1:0] op_exp;
logic op_exp_is_zero;
logic op_exp_is_max;
logic op_is_zero;
logic op_is_inf;
logic op_is_qnan;
logic op_is_snan;
logic op_is_nan;

// ================================================================================================================================================
// In these special cases, srt_iter is not needed so we can get the correct result with only several cycles.
logic res_is_nan_d;
logic res_is_nan_q;
logic res_is_inf_d;
logic res_is_inf_q;
logic res_is_exact_zero_d;
logic res_is_exact_zero_q;
logic op_invalid_d;
logic op_invalid_q;

logic res_is_sqrt_2_d;
logic res_is_sqrt_2_q;

logic early_finish;
// ================================================================================================================================================

logic [$clog2(FP64_FRAC_W)-1:0] op_l_shift_num_pre;
logic [$clog2(FP64_FRAC_W)-1:0] op_l_shift_num;
logic [FP64_FRAC_W-1:0] op_frac_pre_shifted;
logic [(FP64_FRAC_W-1)-1:0] op_frac_l_shifted_s5_to_s3;
logic [FP64_FRAC_W-1:0] op_frac_l_shifted;
logic op_frac_is_zero;

// For F64, it needs 13 cycles for iter, so we would get 13 * 4 + 2 = 54-bit root after iter is finished.
// At the beginning, rt could be {1}.{54'b0}, but finally it must become something like {0}.{1, 53'bx}
// So we only need to store the digits after the decimal point, and we must have rt[54] = ~rt[53]. So we would have:
// rt_full[54:0] = {~rt[53]}.{rt[53:0]}
// rt_m1_full[54:0] = {0}.{1, rt_m1[52:0]}

// This design would add "delay(INV_GATE)" to the critical path, it should be negligible.
// By doing this, we replace the 1-bit reg with a 1-bit INV_GATE, which should reduce some area (I have to admit that the area reduction is very small.)

logic [3-1:0] rt_1st;
// At the beginning, rt_m1 must be {0}.{1x, 52'b0}, so we only need to store [52:0] for rt_m1, and rt_m1[53] must be 1
logic rt_en;
logic [54-1:0] rt_d;
logic [54-1:0] rt_q;
logic rt_m1_en;
logic [53-1:0] rt_m1_d;
logic [53-1:0] rt_m1_q;
logic [55-1:0] rt_iter_init;
logic [55-1:0] rt_m1_iter_init;
logic [54-1:0] rt_after_iter;
logic [53-1:0] rt_m1_after_iter;

logic current_exp_is_odd;
logic [52-1:0] current_frac;

logic mask_en;
logic [13-1:0] mask_d;
logic [13-1:0] mask_q;

logic [REM_W-1:0] f_r_s_iter_init_pre;
logic [REM_W-1:0] f_r_s_iter_init;
logic [REM_W-1:0] f_r_c_iter_init;
logic f_r_s_en;
logic [REM_W-1:0] f_r_s_d;
logic [REM_W-1:0] f_r_s_q;
logic f_r_c_en;
logic [REM_W-1:0] f_r_c_d;
logic [REM_W-1:0] f_r_c_q;
logic [REM_W-1:0] nxt_f_r_s [2-1:0];
logic [REM_W-1:0] nxt_f_r_c [2-1:0];

logic nr_f_r_7b_for_nxt_cycle_s0_qds_en;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_d;
logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s0_qds_q;
logic nr_f_r_9b_for_nxt_cycle_s1_qds_en;
logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_d;
logic [9-1:0] nr_f_r_9b_for_nxt_cycle_s1_qds_q;
logic [8-1:0] adder_8b_iter_init;
logic [9-1:0] adder_9b_iter_init;
logic a0_iter_init;
logic a2_iter_init;
logic a3_iter_init;
logic a4_iter_init;
logic [7-1:0] m_neg_1_iter_init;
logic [7-1:0] m_neg_0_iter_init;
logic [7-1:0] m_pos_1_iter_init;
logic [7-1:0] m_pos_2_iter_init;
logic [7-1:0] adder_7b_res_for_nxt_cycle_s0_qds;
logic [9-1:0] adder_9b_res_for_nxt_cycle_s1_qds;

logic m_neg_1_for_nxt_cycle_s0_qds_en;
// [6:5] = 00, don't need to store it
logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_d;
logic [5-1:0] m_neg_1_for_nxt_cycle_s0_qds_q;

logic m_neg_0_for_nxt_cycle_s0_qds_en;
// [6:4] = 000, don't need to store it
logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_d;
logic [4-1:0] m_neg_0_for_nxt_cycle_s0_qds_q;

logic m_pos_1_for_nxt_cycle_s0_qds_en;
// [6:3] = 1111, don't need to store it
logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_d;
logic [3-1:0] m_pos_1_for_nxt_cycle_s0_qds_q;

logic m_pos_2_for_nxt_cycle_s0_qds_en;
// [6:5] = 11, [0] = 0, don't need to store it
logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_d;
logic [4-1:0] m_pos_2_for_nxt_cycle_s0_qds_q;

logic [7-1:0] m_neg_1_to_nxt_cycle;
logic [7-1:0] m_neg_0_to_nxt_cycle;
logic [7-1:0] m_pos_1_to_nxt_cycle;
logic [7-1:0] m_pos_2_to_nxt_cycle;

logic [REM_W-1:0] nr_f_r;
logic [(REM_W-2)-1:0] f_r_xor;
logic [(REM_W-2)-1:0] f_r_or;
logic rem_is_not_zero;
logic select_rt_m1;

logic [54-1:0] rt_before_round_f64;
logic [54-1:0] rt_before_round_f32;
logic [54-1:0] rt_before_round_f16;
logic [54-1:0] rt_before_round;
logic [54-1:0] rt_m1_before_round_f64;
logic [54-1:0] rt_m1_before_round_f32;
logic [54-1:0] rt_m1_before_round_f16;
logic [54-1:0] rt_m1_before_round;
logic [52-1:0] rt_pre_inc;
logic [52-1:0] rt_m1_pre_inc;
logic [53-1:0] rt_inc_res;
logic [52-1:0] rt_m1_inc_res;

logic guard_bit_rt;
logic round_bit_rt;
logic sticky_bit_rt;
logic rt_need_rup;
logic inexact_rt;

logic guard_bit_rt_m1;
logic round_bit_rt_m1;
logic rt_m1_need_rup;

logic [53-1:0] rt_rounded;
logic [52-1:0] rt_m1_rounded;
logic inexact;
logic carry_after_round;
logic [53-1:0] frac_rounded;
logic [11-1:0] exp_rounded;

logic [FP16_EXP_W-1:0] f16_out_exp;
logic [FP32_EXP_W-1:0] f32_out_exp;
logic [FP64_EXP_W-1:0] f64_out_exp;

logic [(FP16_FRAC_W-1)-1:0] f16_out_frac;
logic [(FP32_FRAC_W-1)-1:0] f32_out_frac;
logic [(FP64_FRAC_W-1)-1:0] f64_out_frac;

logic fflags_invalid_operation;
logic fflags_div_by_zero;
logic fflags_overflow;
logic fflags_underflow;
logic fflags_inexact;

logic [(FP16_EXP_W + FP16_FRAC_W)-1:0] f16_res;
logic [(FP32_EXP_W + FP32_FRAC_W)-1:0] f32_res;
logic [(FP64_EXP_W + FP64_FRAC_W)-1:0] f64_res;


// signals end
// ================================================================================================================================================

// ================================================================================================================================================
// FSM ctrl
// ================================================================================================================================================
always_comb begin
	unique case(fsm_q)
		FSM_PRE_0:
			fsm_d = start_valid_i ? (early_finish ? FSM_POST_0 : (op_exp_is_zero ? FSM_PRE_1 : FSM_ITER)) : FSM_PRE_0;
		FSM_PRE_1:
			fsm_d = FSM_ITER;
		FSM_ITER:
			fsm_d = final_iter ? FSM_POST_0 : FSM_ITER;
		FSM_POST_0:
			fsm_d = finish_ready_i ? FSM_PRE_0 : FSM_POST_0;
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
assign finish_valid_o = fsm_q[FSM_POST_0_BIT];

// ================================================================================================================================================
// Pre
// ================================================================================================================================================

assign op_sign = (fp_format_i == 2'd0) ? op_i[15] : (fp_format_i == 2'd1) ? op_i[31] : op_i[63];
assign op_exp = (fp_format_i == 2'd0) ? {6'b0, op_i[14:10]} : (fp_format_i == 2'd1) ? {3'b0, op_i[30:23]} : op_i[62:52];
assign op_exp_is_zero = (op_exp == 11'b0);
assign op_exp_is_max = (op_exp == ((fp_format_i == 2'd0) ? 11'd31 : (fp_format_i == 2'd1) ? 11'd255 : 11'd2047));
assign op_is_zero = op_exp_is_zero & op_frac_is_zero;
assign op_is_inf = op_exp_is_max & op_frac_is_zero;
assign op_is_qnan = op_exp_is_max & ((fp_format_i == 2'd0) ? op_i[9] : (fp_format_i == 2'd1) ? op_i[22] : op_i[51]);
assign op_is_snan = op_exp_is_max & ~op_frac_is_zero & ((fp_format_i == 2'd0) ? ~op_i[9] : (fp_format_i == 2'd1) ? ~op_i[22] : ~op_i[51]);
assign op_is_nan = (op_is_qnan | op_is_snan);

assign res_is_nan_d = op_is_nan | op_invalid_d;
assign res_is_inf_d = op_is_inf;
assign res_is_exact_zero_d = op_is_zero;
assign op_invalid_d = (op_sign & ~op_is_zero) | op_is_snan;
assign res_is_sqrt_2_d = op_frac_is_zero & ~op_exp[0];

assign out_sign_d = res_is_nan_d ? 1'b0 : op_sign;
assign fp_format_d = fp_format_i;
assign rm_d = rm_i;
assign out_exp_d = res_exp_pre[11:1];
always_ff @(posedge clk) begin
	if(start_handshaked) begin		
		out_sign_q <= out_sign_d;
		fp_format_q <= fp_format_d;
		rm_q <= rm_d;
		out_exp_q <= out_exp_d;

		res_is_sqrt_2_q <= res_is_sqrt_2_d;
	end
end

assign early_finish = 
  res_is_nan_d
| res_is_inf_d
| res_is_exact_zero_d
| op_frac_is_zero;

// ================================================================================================================================================
// Do LZC and part of l_shift in pre_0
// ================================================================================================================================================
// Make the MSB of frac of different formats aligned.
assign op_frac_pre_shifted = 
  ({(FP64_FRAC_W){fp_format_i == 2'd0}} & {1'b0, op_i[0 +: (FP16_FRAC_W - 1)], {(FP64_FRAC_W - FP16_FRAC_W){1'b0}}})
| ({(FP64_FRAC_W){fp_format_i == 2'd1}} & {1'b0, op_i[0 +: (FP32_FRAC_W - 1)], {(FP64_FRAC_W - FP32_FRAC_W){1'b0}}})
| ({(FP64_FRAC_W){fp_format_i == 2'd2}} & {1'b0, op_i[0 +: (FP64_FRAC_W - 1)], {(FP64_FRAC_W - FP64_FRAC_W){1'b0}}});
lzc #(
	.WIDTH(FP64_FRAC_W),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc (
	.in_i(op_frac_pre_shifted),
	.cnt_o(op_l_shift_num_pre),
	// The hiddend bit of frac is not considered here
	.empty_o(op_frac_is_zero)
);
assign op_l_shift_num = {(6){op_exp_is_zero}} & op_l_shift_num_pre;
// Do stage[5:3] l_shift in pre_0, because in the common CLZ logic, delay(MSB) should be smaller than delay(LSB).
assign op_frac_l_shifted_s5_to_s3 = op_frac_pre_shifted[51:0] << {op_l_shift_num[5:3], 3'b0};
// Do stage[2:0] l_shift in pre_1
assign op_frac_l_shifted = {1'b1, rt_m1_q[51:0] << iter_num_q[2:0]};

// It might be a little bit difficult to understand the logic here.
// E: Real exponent of a number
// exp: The encoding value of E in a particular fp_format
// Take F64 as an example:
// x.E = 1023
// x.exp[10:0] = 1023 + 1023 = 11111111110
// sqrt_res.E = (1023 - 1) / 2 = 511
// sqrt_res.exp = 511 + 1023 = 10111111110
// Since x is a normal number -> op_l_shift_num[5:0] = 000000
// res_exp_pre[11:0] = 
// 011111111110 + 
// 001111111111 = 
// 101111111101
// 101111111101 >> 1 = 10111111110, correct !!!
// ================================================================================================================================================
// x.E = -1056
// x.exp[10:0] = 00000000000
// sqrt_res.E = -1056 / 2 = -528
// sqrt_res.exp = -528 + 1023 = 00111101111
// Since x is a denormal number -> op_l_shift_num[5:0] = 100010
// res_exp_pre[11:0] = 
// 000000000001 + 
// 001111011101 = 
// 001111011110
// 001111011110 >> 1 = 00111101111, correct !!!

// You can also try some other value for different fp_formats
// By using this design, now the cost of getting the unrounded "res_exp" is:
// 1) A 12-bit FA
// 2) A 6-bit 3-to-1 MUX
// What if you use a native method to calculate "res_exp" ?
// If we only consider normal number:
// x.E = x.exp - ((fp_format_i == 2'd0) ? 15 : (fp_format_i == 2'd1) ? 127 : 1023);
// sqrt.E = x.E / 2;
// sqrt.exp = sqrt.E + ((fp_format_i == 2'd0) ? 15 : (fp_format_i == 2'd1) ? 127 : 1023);
// I think the design used here should lead to better PPA.
assign res_exp_pre = {1'b0, op_exp[10:1], op_exp[0] | op_exp_is_zero} + {
	2'b0,
	(fp_format_i == 2'd0) ? 6'b0 : (fp_format_i == 2'd1) ? {3'b0, 2'b11, ~op_l_shift_num[4]} : {4'b1111, ~op_l_shift_num[5:4]},
	~op_l_shift_num[3:0]
};


// pre_0: op is from input port
// pre_1: op is from l_shifted result
assign current_exp_is_odd = fsm_q[FSM_PRE_0_BIT] ? ~op_exp[0] : iter_num_q[0];
assign current_frac = fsm_q[FSM_PRE_0_BIT] ? op_frac_pre_shifted[51:0] : op_frac_l_shifted[51:0];
// Look at the paper for more details.
// even_exp, digit in (2 ^ -1) is 0: s[1] = -2, rt = {0}.{1, 53'b0} , rt_m1 = {0}.{01, 52'b0}
// even_exp, digit in (2 ^ -1) is 1: s[1] = -1, rt = {0}.{11, 52'b0}, rt_m1 = {0}.{10, 52'b0}
// odd_exp, digit in (2 ^ -1) is 0 : s[1] = -1, rt = {0}.{11, 52'b0}, rt_m1 = {0}.{10, 52'b0}
// odd_exp, digit in (2 ^ -1) is 1 : s[1] =  0, rt = {1}.{00, 52'b0}, rt_m1 = {0}.{11, 52'b0}
// [0]: s[1] = -2
// [1]: s[1] = -1
// [2]: s[1] =  0
assign rt_1st[0] = ({current_exp_is_odd, current_frac[51]} == 2'b00);
assign rt_1st[1] = ({current_exp_is_odd, current_frac[51]} == 2'b01) | ({current_exp_is_odd, current_frac[51]} == 2'b10);
assign rt_1st[2] = ({current_exp_is_odd, current_frac[51]} == 2'b11);

// When (op_is_power_of_2) and odd_exp: 
// f_r_s_iter_init = {1, 55'b0}
// f_r_c_iter_init = {0111, 52'b0}
// In the nxt cycle, we would have "nr_f_r != 0" and "nr_f_r[REM_W-1] == 1". This is what we need, to get the correct rounded result for sqrt(2)
// When (op_is_power_of_2) and even_exp: 
// f_r_s_iter_init = {01, 54'b0}
// f_r_c_iter_init = {11, 54'b0}
// In the nxt cycle, we would have "nr_f_r == 0". This is what we need, to get the correct rounded result for sqrt(1)
// In conclusion, when (op_is_power_of_2), the ITER step could be skipped, and we only need to use 1-bit reg to store "op_is_power_of_2 & exp_is_odd", 
// instead of using 2-bit reg to store "{op_is_power_of_2, exp_is_odd}"
assign rt_iter_init = 
  ({(55){rt_1st[0]}} & {3'b010, 52'b0})
| ({(55){rt_1st[1]}} & {3'b011, 52'b0})
| ({(55){rt_1st[2]}} & {3'b100, 52'b0});
// When s[1] = -2, the MSB of rt_m1 is not 1, which doesn't follow my assumption of rt_m1. But you should easily find that in the later iter process,
// the QDS "MUST" select "0/+1/+2" before the next "-1/-2" is selected. Therefore, rt_m1 will not be used until the next "-1/-2" is selected.
assign rt_m1_iter_init = 
  ({(55){rt_1st[0]}} & {3'b001, 52'b0})
| ({(55){rt_1st[1]}} & {3'b010, 52'b0})
| ({(55){rt_1st[2]}} & {3'b011, 52'b0});

assign f_r_s_iter_init_pre = {2'b11, current_exp_is_odd ? {1'b1, current_frac, 1'b0} : {1'b0, 1'b1, current_frac}};
assign f_r_s_iter_init = {f_r_s_iter_init_pre[(REM_W-1)-2:0], 2'b0};
assign f_r_c_iter_init = 
  ({(REM_W){rt_1st[0]}} & {2'b11,   {(REM_W - 2){1'b0}}})
| ({(REM_W){rt_1st[1]}} & {4'b0111, {(REM_W - 4){1'b0}}})
| ({(REM_W){rt_1st[2]}} & {(REM_W){1'b0}});

assign rt_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign rt_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? rt_iter_init[53:0] : rt_after_iter;

assign rt_m1_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
// Use rt_m1_q to store the unfinished l_shifted result when op is a denormal number.
assign rt_m1_d  = 
fsm_q[FSM_PRE_0_BIT] ? (op_exp_is_zero ? {rt_m1_q[52], op_frac_l_shifted_s5_to_s3} : rt_m1_iter_init[52:0]) : 
fsm_q[FSM_PRE_1_BIT] ? rt_m1_iter_init[52:0] : 
rt_m1_after_iter;

assign mask_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign mask_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? {1'b1, 12'b0} : (mask_q >> 1);

assign f_r_s_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign f_r_s_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? f_r_s_iter_init : nxt_f_r_s[1];

assign f_r_c_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign f_r_c_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? f_r_c_iter_init : nxt_f_r_c[1];

assign iter_num_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | (fsm_q[FSM_ITER_BIT] & ~final_iter);
// When sqrt(op) will output a normal result, "iter_num_q" must be 4'b0 after iter is finished.
// So we can use this reg to store some info when sqrt(op) will output some special numbers -> This would save some registers.
// f16: ceil((12 - 2) / 4) =  3,  3 - 1 =  2
// f32: ceil((25 - 2) / 4) =  6,  6 - 1 =  5
// f64: ceil((54 - 2) / 4) = 13, 13 - 1 = 12
// Why "- 2"? -> Because we have already got the 1st root in Initialization step, which could save 1 cycle for f64/f32.
assign iter_num_d  = 
fsm_q[FSM_PRE_0_BIT] ? (
	early_finish ? {res_is_nan_d, res_is_inf_d, res_is_exact_zero_d, op_invalid_d} : 
	op_exp_is_zero ? {iter_num_q[3], op_l_shift_num[2:0]} : 
	((fp_format_i == 2'd0) ? 4'd2 : (fp_format_i == 2'd1) ? 4'd5 : 4'd12)
) : 
fsm_q[FSM_PRE_1_BIT] ? ((fp_format_q == 2'd0) ? 4'd2 : (fp_format_q == 2'd1) ? 4'd5 : 4'd12) : 
(iter_num_q - 4'd1);

assign final_iter = (iter_num_q == 4'd0);


// "f_r_c_iter_init" would only have 4-bit non-zero value, so a 4-bit FA is enough here
// assign adder_8b_iter_init = f_r_s_iter_init[(REM_W-1) -: 8] + f_r_c_iter_init[(REM_W-1) -: 8];
assign adder_8b_iter_init = {f_r_s_iter_init[(REM_W-1) -: 4] + f_r_c_iter_init[(REM_W-1) -: 4], f_r_s_iter_init[(REM_W-1)-4 -: 4]};
assign nr_f_r_7b_for_nxt_cycle_s0_qds_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign nr_f_r_7b_for_nxt_cycle_s0_qds_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? adder_8b_iter_init[7:1] : adder_7b_res_for_nxt_cycle_s0_qds;

// "f_r_c_iter_init * 4" would only have 2-bit non-zero value, so a 2-bit FA is enough here
// assign adder_9b_iter_init = f_r_s_iter_init[(REM_W-1)-2 -: 9] + f_r_c_iter_init[(REM_W-1)-2 -: 9];
assign adder_9b_iter_init = {f_r_s_iter_init[(REM_W-1)-2 -: 2] + f_r_c_iter_init[(REM_W-1)-2 -: 2], f_r_s_iter_init[(REM_W-1)-2-2 -: 7]};
assign nr_f_r_9b_for_nxt_cycle_s1_qds_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign nr_f_r_9b_for_nxt_cycle_s1_qds_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? adder_9b_iter_init : adder_9b_res_for_nxt_cycle_s1_qds;

assign a0_iter_init = rt_iter_init[54];
assign a2_iter_init = rt_iter_init[52];
assign a3_iter_init = rt_iter_init[51];
assign a4_iter_init = rt_iter_init[50];
r4_qds_constants_generator 
u_r4_qds_constants_generator_iter_init (
	.a0_i(a0_iter_init),
	.a2_i(a2_iter_init),
	.a3_i(a3_iter_init),
	.a4_i(a4_iter_init),
	.m_neg_1_o(m_neg_1_iter_init),
	.m_neg_0_o(m_neg_0_iter_init),
	.m_pos_1_o(m_pos_1_iter_init),
	.m_pos_2_o(m_pos_2_iter_init)
);

assign m_neg_1_for_nxt_cycle_s0_qds_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
// [6:5] = 00, don't need to store it
assign m_neg_1_for_nxt_cycle_s0_qds_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_neg_1_iter_init[4:0] : m_neg_1_to_nxt_cycle[4:0];

assign m_neg_0_for_nxt_cycle_s0_qds_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
// [6:4] = 000, don't need to store it
assign m_neg_0_for_nxt_cycle_s0_qds_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_neg_0_iter_init[3:0] : m_neg_0_to_nxt_cycle[3:0];

assign m_pos_1_for_nxt_cycle_s0_qds_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
// [6:3] = 1111, don't need to store it
assign m_pos_1_for_nxt_cycle_s0_qds_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_pos_1_iter_init[2:0] : m_pos_1_to_nxt_cycle[2:0];

assign m_pos_2_for_nxt_cycle_s0_qds_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
// [6:5] = 11, [0] = 0, don't need to store it
assign m_pos_2_for_nxt_cycle_s0_qds_d  = (fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_PRE_1_BIT]) ? m_pos_2_iter_init[4:1] : m_pos_2_to_nxt_cycle[4:1];


always_ff @(posedge clk) begin
	if(rt_en)
		rt_q <= rt_d;
	if(rt_m1_en)
		rt_m1_q <= rt_m1_d;
	if(mask_en)
		mask_q <= mask_d;
	if(f_r_s_en)
		f_r_s_q <= f_r_s_d;
	if(f_r_c_en)
		f_r_c_q <= f_r_c_d;
	if(iter_num_en)
		iter_num_q <= iter_num_d;

	if(nr_f_r_7b_for_nxt_cycle_s0_qds_en)
		nr_f_r_7b_for_nxt_cycle_s0_qds_q <= nr_f_r_7b_for_nxt_cycle_s0_qds_d;
	if(nr_f_r_9b_for_nxt_cycle_s1_qds_en)
		nr_f_r_9b_for_nxt_cycle_s1_qds_q <= nr_f_r_9b_for_nxt_cycle_s1_qds_d;

	if(m_neg_1_for_nxt_cycle_s0_qds_en)
		m_neg_1_for_nxt_cycle_s0_qds_q <= m_neg_1_for_nxt_cycle_s0_qds_d;
	if(m_neg_0_for_nxt_cycle_s0_qds_en)
		m_neg_0_for_nxt_cycle_s0_qds_q <= m_neg_0_for_nxt_cycle_s0_qds_d;
	if(m_pos_1_for_nxt_cycle_s0_qds_en)
		m_pos_1_for_nxt_cycle_s0_qds_q <= m_pos_1_for_nxt_cycle_s0_qds_d;
	if(m_pos_2_for_nxt_cycle_s0_qds_en)
		m_pos_2_for_nxt_cycle_s0_qds_q <= m_pos_2_for_nxt_cycle_s0_qds_d;
end

// ================================================================================================================================================
// ITER
// ================================================================================================================================================

fpsqrt_r16_block #(
	.REM_W(REM_W),
	.RT_DIG_W(RT_DIG_W)
) u_fpsqrt_r16_block (
	.f_r_s_i(f_r_s_q),
	.f_r_c_i(f_r_c_q),
	.rt_i(rt_q),
	.rt_m1_i(rt_m1_q),
	.nr_f_r_7b_for_nxt_cycle_s0_qds_i(nr_f_r_7b_for_nxt_cycle_s0_qds_q),
	.nr_f_r_9b_for_nxt_cycle_s1_qds_i(nr_f_r_9b_for_nxt_cycle_s1_qds_q),
	.m_neg_1_for_nxt_cycle_s0_qds_i(m_neg_1_for_nxt_cycle_s0_qds_q),
	.m_neg_0_for_nxt_cycle_s0_qds_i(m_neg_0_for_nxt_cycle_s0_qds_q),
	.m_pos_1_for_nxt_cycle_s0_qds_i(m_pos_1_for_nxt_cycle_s0_qds_q),
	.m_pos_2_for_nxt_cycle_s0_qds_i(m_pos_2_for_nxt_cycle_s0_qds_q),
	.mask_i(mask_q),

	.nxt_rt_o(rt_after_iter),
	.nxt_rt_m1_o(rt_m1_after_iter),
	.nxt_f_r_s_o(nxt_f_r_s),
	.nxt_f_r_c_o(nxt_f_r_c),
	.adder_7b_res_for_nxt_cycle_s0_qds_o(adder_7b_res_for_nxt_cycle_s0_qds),
	.adder_9b_res_for_nxt_cycle_s1_qds_o(adder_9b_res_for_nxt_cycle_s1_qds),
	.m_neg_1_to_nxt_cycle_o(m_neg_1_to_nxt_cycle),
	.m_neg_0_to_nxt_cycle_o(m_neg_0_to_nxt_cycle),
	.m_pos_1_to_nxt_cycle_o(m_pos_1_to_nxt_cycle),
	.m_pos_2_to_nxt_cycle_o(m_pos_2_to_nxt_cycle)
);


// ================================================================================================================================================
// Post
// ================================================================================================================================================

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
// The algorithm we use is "Minimally Redundant Radix 4", and its redundnat factor is 2/3.
// So we must have "|rem| <= D * (2/3)" -> when (nr_f_r < 0), the "positive rem" must be NON_ZERO
// Which means we don't have to calculate "nr_f_r_plus_d"
assign rem_is_not_zero = nr_f_r[REM_W-1] | (f_r_xor != f_r_or);

// Similar to fpdiv, to get the correct rounded result, we don't need the digits after "round_bit".
// Make the integer part ZERO so we can get the carry bit
assign rt_before_round_f64 = {1'b0, res_is_sqrt_2_q ? SQRT_2_WITH_ROUND_BIT[52:0] : rt_q[52:0]};
assign rt_before_round_f32 = {{(54 - 24){1'b0}}, res_is_sqrt_2_q ? SQRT_2_WITH_ROUND_BIT[52 -: 24] : rt_q[52 -: 24]};
assign rt_before_round_f16 = {{(54 - 11){1'b0}}, res_is_sqrt_2_q ? SQRT_2_WITH_ROUND_BIT[52 -: 11] : rt_q[52 -: 11]};
assign rt_before_round = 
  ({(54){fp_format_q == 2'd0}} & rt_before_round_f16)
| ({(54){fp_format_q == 2'd1}} & rt_before_round_f32)
| ({(54){fp_format_q == 2'd2}} & rt_before_round_f64);

// Make the integer part ZERO so we can get the carry bit
assign rt_m1_before_round_f64 = {1'b0, rt_m1_q};
assign rt_m1_before_round_f32 = {{(54 - 24){1'b0}}, rt_m1_q[52 -: 24]};
assign rt_m1_before_round_f16 = {{(54 - 11){1'b0}}, rt_m1_q[52 -: 11]};
assign rt_m1_before_round = 
  ({(54){fp_format_q == 2'd0}} & rt_m1_before_round_f16)
| ({(54){fp_format_q == 2'd1}} & rt_m1_before_round_f32)
| ({(54){fp_format_q == 2'd2}} & rt_m1_before_round_f64);

assign rt_pre_inc[51:0] = rt_before_round[52:1];
assign rt_m1_pre_inc[51:0] = rt_m1_before_round[52:1];

// Carry will only happen when the following conditions are met:
// 1. exp_is_odd
// 2. op is a normal number and its frac is "ALL_ONES"
// 3. Rounding_Mode = RUP
// That means we can also get its value in initialization step, but it seems that 
// "Getting its value in initialization step" has no benefit...
assign rt_inc_res[52:0] = rt_pre_inc + {52'b0, 1'b1};
// When(f64), for rt_m1, "carry_after_round" is impossible
// But it is possible for f16, because we get 14-bit root.
assign rt_m1_inc_res[51:0] = (rt_m1_pre_inc[0] == rt_pre_inc[0]) ? rt_inc_res[51:0] : rt_pre_inc[51:0];

assign select_rt_m1 = nr_f_r[REM_W-1] & ~res_is_sqrt_2_q;

assign guard_bit_rt = rt_before_round[1];
assign round_bit_rt = rt_before_round[0];
assign sticky_bit_rt = rem_is_not_zero;

// For SQRT, there is no "Midpoint" result, which means, if round_bit is 1, then sticky_bit must be 1 as well. By using this property,
// We could known that the effect of RNE is totally equal to RMM. So we can save several gates here.
// However, in most real-world CPU design, people prefer using a signle module to calculate fpdiv/sqrt, which means div and sqrt will share the same rounding
// logic, so the optimization here would be useless.
assign rt_need_rup = 
  ({rm_q == RM_RNE} &  round_bit_rt)
| ({rm_q == RM_RUP} & (round_bit_rt | sticky_bit_rt))
| ({rm_q == RM_RMM} &  round_bit_rt);
assign inexact_rt = round_bit_rt | sticky_bit_rt;

assign guard_bit_rt_m1 = rt_m1_before_round[1];
assign round_bit_rt_m1 = rt_m1_before_round[0];
// As said before, for rt_m1 the sticky_bit must be 1.
assign rt_m1_need_rup = (rm_q == RM_RUP) | (((rm_q == RM_RNE) | (rm_q == RM_RMM)) & round_bit_rt_m1);

assign rt_rounded = rt_need_rup ? rt_inc_res : {1'b0, rt_pre_inc};
assign rt_m1_rounded = rt_m1_need_rup ? rt_m1_inc_res : rt_m1_pre_inc;
assign inexact = select_rt_m1 | inexact_rt;

assign frac_rounded = select_rt_m1 ? {1'b0, rt_m1_rounded} : rt_rounded;
assign carry_after_round = (fp_format_q == 2'd0) ? frac_rounded[10] : (fp_format_q == 2'd1) ? frac_rounded[23] : frac_rounded[52];
assign exp_rounded = carry_after_round ? (out_exp_q + 11'd1) : out_exp_q;

assign {
	res_is_nan_q,
	res_is_inf_q,
	res_is_exact_zero_q,
	op_invalid_q
} = iter_num_q;

assign f16_out_exp = 
(res_is_nan_q | res_is_inf_q) ? {(5){1'b1}} : 
res_is_exact_zero_q ? 5'b0 : 
exp_rounded[4:0];

assign f32_out_exp = 
(res_is_nan_q | res_is_inf_q) ? {(8){1'b1}} : 
res_is_exact_zero_q ? 8'b0 : 
exp_rounded[7:0];

assign f64_out_exp = 
(res_is_nan_q | res_is_inf_q) ? {(11){1'b1}} : 
res_is_exact_zero_q ? 11'b0 : 
exp_rounded[10:0];

assign f16_out_frac = 
res_is_nan_q ? {1'b1, 9'b0} : 
(res_is_inf_q | res_is_exact_zero_q) ? 10'b0 : 
frac_rounded[9:0];

assign f32_out_frac = 
res_is_nan_q ? {1'b1, 22'b0} : 
(res_is_inf_q | res_is_exact_zero_q) ? 23'b0 : 
frac_rounded[22:0];

assign f64_out_frac = 
res_is_nan_q ? {1'b1, 51'b0} : 
(res_is_inf_q | res_is_exact_zero_q) ? 52'b0 : 
frac_rounded[51:0];

assign f16_res = {out_sign_q, f16_out_exp, f16_out_frac};
assign f32_res = {out_sign_q, f32_out_exp, f32_out_frac};
assign f64_res = {out_sign_q, f64_out_exp, f64_out_frac};

assign fpsqrt_res_o = {
	f64_res[63:32], 
	(fp_format_q == 2'd1) ? f32_res[31:16] : f64_res[31:16], 
	(fp_format_q == 2'd0) ? f16_res[15:0] : (fp_format_q == 2'd1) ? f32_res[15:0] : f64_res[15:0]
};

assign fflags_invalid_operation = op_invalid_q;
assign fflags_div_by_zero = '0;
assign fflags_overflow = '0;
assign fflags_underflow = '0;
// For normal data_path, when (res_is_inf_q), it is equivalent to calculate "sqrt(2 ^ 128)" -> Without using res_is_inf_q, we will also get "inexact = 0"
assign fflags_inexact = inexact & ~res_is_nan_q & ~res_is_exact_zero_q;

assign fflags_o = {
	fflags_invalid_operation,
	fflags_div_by_zero,
	fflags_overflow,
	fflags_underflow,
	fflags_inexact
};

endmodule

