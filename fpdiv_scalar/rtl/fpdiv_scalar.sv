// ========================================================================================================
// File Name			: fpdiv_scalar.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-12-01 21:23:29
// Last Modified Time   : 2021-12-23 17:13:24
// ========================================================================================================
// Description	:
// A Scala Floating Point Divider based on radix-2 srt algorithm.
// It supports fp16/32/64. (Maybe add support for bfloat16/tfloat32 in the future ??)
// ========================================================================================================
// ========================================================================================================
// Copyright (C) 2021, HYF. All Rights Reserved.
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

module fpdiv_scalar #(
	// Put some parameters here, which can be changed by other modules
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

// SPECULATIVE_MSB_W = "number of srt iteration per cycles" * 2 = 3 * 2 = 6
localparam SPECULATIVE_MSB_W = 6;

// ITN = InTerNal
// 1-bit in the front of frac[52:0] as sign
// 1-bit after frac[52:0] for initial operation
localparam ITN_W = 1 + 53 + 1;

localparam FP64_FRAC_W = 52 + 1;
localparam FP32_FRAC_W = 23 + 1;
localparam FP16_FRAC_W = 10 + 1;

localparam FP64_EXP_W = 11;
localparam FP32_EXP_W = 8;
localparam FP16_EXP_W = 5;

localparam FSM_W = 5;
localparam FSM_PRE_0 	= (1 << 0);
localparam FSM_PRE_1 	= (1 << 1);
localparam FSM_ITER  	= (1 << 2);
localparam FSM_POST_0 	= (1 << 3);
localparam FSM_POST_1 	= (1 << 4);

localparam FSM_PRE_0_BIT 	= 0;
localparam FSM_PRE_1_BIT	= 1;
localparam FSM_ITER_BIT 	= 2;
localparam FSM_POST_0_BIT 	= 3;
localparam FSM_POST_1_BIT 	= 4;

// If r_shift_num of quo is larger than this value, then the whole quo would be sticky_bit
localparam R_SHIFT_NUM_LIMIT = 6'd55;

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

logic [13-1:0] exp_diff_m1;
logic [13-1:0] exp_diff_adjusted;
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
logic opa_is_inf;
logic opb_is_inf;
logic opa_is_qnan;
logic opb_is_qnan;
logic opa_is_snan;
logic opb_is_snan;
logic opa_is_nan;
logic opb_is_nan;
logic op_invalid_div;
logic res_is_nan;
logic res_is_inf;
logic res_is_exact_zero;
logic opb_is_power_of_2;
logic divided_by_zero;
logic early_finish;
logic skip_iter;

logic out_sign_d;
logic out_sign_q;
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
logic res_is_from_opa_d;
logic res_is_from_opa_q;
logic [2-1:0] fp_format_d;
logic [2-1:0] fp_format_q;
logic [3-1:0] rm_d;
logic [3-1:0] rm_q;

logic [6-1:0] opa_l_shift_num_d;
logic [6-1:0] opa_l_shift_num_q;
logic [6-1:0] opb_l_shift_num_d;
logic [6-1:0] opb_l_shift_num_q;
logic [6-1:0] opa_l_shift_num_pre;
logic [6-1:0] opb_l_shift_num_pre;
logic [FP64_FRAC_W-1:0] opa_frac_pre_shifted;
logic [FP64_FRAC_W-1:0] opb_frac_pre_shifted;
logic [FP64_FRAC_W-1:0] opa_frac_l_shifted;
logic [FP64_FRAC_W-1:0] opb_frac_l_shifted;

logic [ITN_W-1:0] frac_rem_sum_iter_init;
logic [ITN_W-1:0] frac_rem_carry_iter_init;

logic frac_rem_sum_en;
logic [ITN_W-1:0] frac_rem_sum_d;
logic [ITN_W-1:0] frac_rem_sum_q;
logic frac_rem_carry_en;
logic [ITN_W-1:0] frac_rem_carry_d;
logic [ITN_W-1:0] frac_rem_carry_q;

logic [ITN_W-1:0] frac_rem_sum_in [3-1:0];
logic [ITN_W-1:0] frac_rem_carry_in [3-1:0];
logic [ITN_W-1:0] frac_rem_sum_out [3-1:0];
logic [ITN_W-1:0] frac_rem_carry_out [3-1:0];
logic [(ITN_W - SPECULATIVE_MSB_W)-1:0] frac_rem_sum_out_lsbs [3-1:0];
logic [(ITN_W - SPECULATIVE_MSB_W)-1:0] frac_rem_carry_out_lsbs [3-1:0];
logic [SPECULATIVE_MSB_W-1:0] frac_rem_sum_out_msbs [3-1:0];
logic [SPECULATIVE_MSB_W-1:0] frac_rem_carry_out_msbs [3-1:0];
logic [SPECULATIVE_MSB_W-1:0] frac_rem_sum_out_msbs_zero [3-1:0];
logic [SPECULATIVE_MSB_W-1:0] frac_rem_carry_out_msbs_zero [3-1:0];
logic [SPECULATIVE_MSB_W-1:0] frac_rem_sum_out_msbs_minus [3-1:0];
logic [SPECULATIVE_MSB_W-1:0] frac_rem_carry_out_msbs_minus [3-1:0];
logic [SPECULATIVE_MSB_W-1:0] frac_rem_sum_out_msbs_plus [3-1:0];
logic [SPECULATIVE_MSB_W-1:0] frac_rem_carry_out_msbs_plus [3-1:0];

// Also use this reg to remember "frac_rem" generated in post_0, so we can get sticky_bit in post_1
// Since frac_rem must be positive, so 54-bit is enough.
// frac_divisor[52] must be 1 so don't need to remember it
logic frac_divisor_en;
logic [(FP64_FRAC_W + 1)-1:0] frac_divisor_iter_init;
logic [(FP64_FRAC_W + 1)-1:0] frac_divisor_d;
logic [(FP64_FRAC_W + 1)-1:0] frac_divisor_q;
logic [ITN_W-1:0] div_csa_val [3-1:0];

logic [ITN_W-1:0] quo_iter_init;
logic quo_iter_en;
logic [ITN_W-1:0] quo_iter_d;
logic [ITN_W-1:0] quo_iter_q;
logic quo_m1_iter_en;
logic [ITN_W-1:0] quo_m1_iter_d;
logic [ITN_W-1:0] quo_m1_iter_q;
logic [ITN_W-1:0] nxt_quo_iter [3-1:0];
logic [ITN_W-1:0] nxt_quo_m1_iter [3-1:0];

logic [2-1:0] quo_dig [3-1:0];
logic [2-1:0] quo_dig_zero [3-1:0];
logic [2-1:0] quo_dig_plus [3-1:0];
logic [2-1:0] quo_dig_minus [3-1:0];

logic iter_num_en;
// fp64: iter_num_needed = ceil((53 + 1) / 3) = 18, 18 - 1 = 17
// fp32: iter_num_needed = ceil((24 + 1) / 3) =  9,  9 - 1 =  8
// fp16: iter_num_needed = ceil((11 + 1) / 3) =  4,  4 - 1 =  3
// So we need a 5-bit signal as the counter.
logic [5-1:0] iter_num_d;
logic [5-1:0] iter_num_q;
logic final_iter;

logic [ITN_W-1:0] nr_frac_rem;
logic [ITN_W-1:0] nr_frac_rem_plus_d;

logic quo_msb;
logic [ITN_W-1:0] quo_pre_shift;
logic [ITN_W-1:0] quo_m1_pre_shift;
logic [(2 * ITN_W)-1:0] quo_r_shifted;
logic [(2 * ITN_W)-1:0] quo_m1_r_shifted;
logic [(ITN_W + 1)-1:0] sticky_without_rem;
logic [(ITN_W - 1)-1:0] correct_quo_r_shifted;

logic [13-1:0] r_shift_num_pre;
logic [13-1:0] r_shift_num_pre_minus_limit;
logic [ 6-1:0] r_shift_num;

logic rem_is_not_zero;
logic sticky_bit;

logic [(FP64_FRAC_W - 1)-1:0] frac_before_round;
logic guard_bi;
logic round_bit;
logic [12-1:0] exp_before_round;
logic inexact;
logic round_up;
logic [FP64_FRAC_W-1:0] frac_after_round;
logic carry_after_round;
logic [12-1:0] exp_after_round;
logic overflow;
logic overflow_to_inf;

logic [ 5-1:0] fp16_out_exp;
logic [10-1:0] fp16_out_frac;
logic [ 8-1:0] fp32_out_exp;
logic [23-1:0] fp32_out_frac;
logic [11-1:0] fp64_out_exp;
logic [52-1:0] fp64_out_frac;

logic fflags_invalid_operation;
logic fflags_div_by_zero;
logic fflags_overflow;
logic fflags_underflow;
logic fflags_inexact;

logic [16-1:0] fp16_res;
logic [32-1:0] fp32_res;
logic [64-1:0] fp64_res;

// signals end
// ================================================================================================================================================

// ================================================================================================================================================
// FSM ctrl
// ================================================================================================================================================
always_comb begin
	unique case(fsm_q)
		FSM_PRE_0:
			fsm_d = start_valid_i ? (early_finish ? FSM_POST_1 : FSM_PRE_1) : FSM_PRE_0;
		FSM_PRE_1:
			fsm_d = skip_iter ? FSM_POST_0 : FSM_ITER;
		FSM_ITER:
			fsm_d = final_iter ? FSM_POST_0 : FSM_ITER;
		FSM_POST_0:
			fsm_d = FSM_POST_1;
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
assign finish_valid_o = fsm_q[FSM_POST_1_BIT];

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
assign opa_is_zero = opa_exp_is_zero & opa_frac_is_zero;
assign opb_is_zero = opb_exp_is_zero & opb_frac_is_zero;
assign opa_is_inf = opa_exp_is_max & opa_frac_is_zero;
assign opb_is_inf = opb_exp_is_max & opb_frac_is_zero;

assign opa_is_qnan = opa_exp_is_max & ((fp_format_i == 2'd0) ? opa_i[9] : (fp_format_i == 2'd1) ? opa_i[22] : opa_i[51]);
assign opb_is_qnan = opb_exp_is_max & ((fp_format_i == 2'd0) ? opb_i[9] : (fp_format_i == 2'd1) ? opb_i[22] : opb_i[51]);
assign opa_is_snan = opa_exp_is_max & ~opa_frac_is_zero & ((fp_format_i == 2'd0) ? ~opa_i[9] : (fp_format_i == 2'd1) ? ~opa_i[22] : ~opa_i[51]);
assign opb_is_snan = opb_exp_is_max & ~opb_frac_is_zero & ((fp_format_i == 2'd0) ? ~opb_i[9] : (fp_format_i == 2'd1) ? ~opb_i[22] : ~opb_i[51]);
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
assign opb_is_power_of_2 = opb_frac_is_zero & ~res_is_nan;
// When result is not nan, and dividend is not inf, "dividend / 0" should lead to "DIV_BY_ZERO" exception.
assign divided_by_zero = ~res_is_nan & ~opa_is_inf & opb_is_zero;
// assign res_is_from_opa = opa_is_snan | (opa_is_qnan & ~opb_is_snan & ~op_invalid_div) | opb_is_power_of_2;

assign opa_l_shift_num_d = {(6){opa_exp_is_zero}} & opa_l_shift_num_pre;
assign opb_l_shift_num_d = {(6){opb_exp_is_zero}} & opb_l_shift_num_pre;
assign opa_exp_plus_biased = {1'b0, opa_exp_biased[10:0]} + ((fp_format_i == 2'd0) ? 12'd15 : (fp_format_i == 2'd1) ? 12'd127 : 12'd1023);
assign op_exp_diff[12:0] = 
  {1'b0, opa_exp_plus_biased}
- {7'b0, opa_l_shift_num_d}
- {1'b0, opb_exp_biased}
+ {7'b0, opb_l_shift_num_d};


// when (res_is_nan)
// res_is_from_opa = 1: fpdiv_res_o = opa_i
// res_is_from_opa = 0: if(op_invalid_div = 0) -> fpdiv_res_o = opb_i; else -> fpdiv_res_o = default NaN
// assign out_sign_d = res_is_nan ? (res_is_from_opa ? opa_sign : op_invalid_div ? 1'b0 : opb_sign) : (opa_sign ^ opb_sign);
// Follow the rule in riscv-spec, just produce default NaN.
assign out_sign_d = res_is_nan ? 1'b0 : (opa_sign ^ opb_sign);

assign res_is_nan_d = res_is_nan;
assign res_is_inf_d = res_is_inf;
assign res_is_exact_zero_d = res_is_exact_zero;
assign opb_is_power_of_2_d = opb_is_power_of_2;
assign op_invalid_div_d = op_invalid_div;
assign divided_by_zero_d = divided_by_zero;
// assign res_is_from_opa_d = res_is_from_opa;
assign fp_format_d = fp_format_i;
assign rm_d = rm_i;

always_ff @(posedge clk) begin
	if(start_handshaked) begin		
		out_sign_q <= out_sign_d;
		res_is_nan_q <= res_is_nan_d;
		res_is_inf_q <= res_is_inf_d;
		res_is_exact_zero_q <= res_is_exact_zero_d;
		opb_is_power_of_2_q <= opb_is_power_of_2_d;
		op_invalid_div_q <= op_invalid_div_d;
		divided_by_zero_q <= divided_by_zero_d;
		// res_is_from_opa_q <= res_is_from_opa_d;
		fp_format_q <= fp_format_d;
		opa_l_shift_num_q <= opa_l_shift_num_d;
		opb_l_shift_num_q <= opb_l_shift_num_d;
		rm_q <= rm_d;
	end
end

assign early_finish = res_is_nan | res_is_inf | res_is_exact_zero;
assign skip_iter = opb_is_power_of_2_q;


assign exp_diff_m1 = out_exp_diff_q - 13'd1;
// TODO: If the timing of this signal is not good (because it uses nxt_quo_iter[2] to select), just put the "- 1" operation into post_0.
assign exp_diff_adjusted = 
(fp_format_q == 2'd0) ? (nxt_quo_iter[2][12] ? out_exp_diff_q : exp_diff_m1) : 
(fp_format_q == 2'd1) ? (nxt_quo_iter[2][27] ? out_exp_diff_q : exp_diff_m1) : 
(nxt_quo_iter[2][54] ? out_exp_diff_q : exp_diff_m1);
// In final_iter, we can know whether the MSB of quo is 1. So we can choose to decrease "exp_diff".
assign out_exp_diff_en = start_handshaked | (fsm_q[FSM_ITER_BIT] & final_iter);
assign out_exp_diff_d  = start_handshaked ? op_exp_diff : exp_diff_adjusted;
always_ff @(posedge clk)
	if(out_exp_diff_en)
		out_exp_diff_q <= out_exp_diff_d;

// ================================================================================================================================================
// Do LZC in pre_0
// ================================================================================================================================================
// Make the MSB of frac of different formats aligned.
assign opa_frac_pre_shifted = 
  ({(FP64_FRAC_W){fp_format_i == 2'd0}} & {1'b0, opa_i[0 +: (FP16_FRAC_W - 1)], {(FP64_FRAC_W - FP16_FRAC_W){1'b0}}})
| ({(FP64_FRAC_W){fp_format_i == 2'd1}} & {1'b0, opa_i[0 +: (FP32_FRAC_W - 1)], {(FP64_FRAC_W - FP32_FRAC_W){1'b0}}})
| ({(FP64_FRAC_W){fp_format_i == 2'd2}} & {1'b0, opa_i[0 +: (FP64_FRAC_W - 1)], {(FP64_FRAC_W - FP64_FRAC_W){1'b0}}});
assign opb_frac_pre_shifted = 
  ({(FP64_FRAC_W){fp_format_i == 2'd0}} & {1'b0, opb_i[0 +: (FP16_FRAC_W - 1)], {(FP64_FRAC_W - FP16_FRAC_W){1'b0}}})
| ({(FP64_FRAC_W){fp_format_i == 2'd1}} & {1'b0, opb_i[0 +: (FP32_FRAC_W - 1)], {(FP64_FRAC_W - FP32_FRAC_W){1'b0}}})
| ({(FP64_FRAC_W){fp_format_i == 2'd2}} & {1'b0, opb_i[0 +: (FP64_FRAC_W - 1)], {(FP64_FRAC_W - FP64_FRAC_W){1'b0}}});
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

// ================================================================================================================================================
// Do l_shift in pre_1
// ================================================================================================================================================
assign opa_frac_l_shifted = frac_rem_sum_q  [52:0] << opa_l_shift_num_q;
assign opb_frac_l_shifted = frac_rem_carry_q[52:0] << opb_l_shift_num_q;

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
assign frac_rem_sum_iter_init 	= opb_is_power_of_2_q ? 55'b0 : {1'b0,  opa_frac_l_shifted, 1'b1};
assign frac_rem_carry_iter_init = opb_is_power_of_2_q ? 55'b0 : {1'b1, ~opb_frac_l_shifted, 1'b1};

assign frac_divisor_iter_init = {2'b0, opb_frac_l_shifted[51:0]};
assign frac_divisor_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_POST_0_BIT];
// Choose the right "frac_rem" according to the sign
assign frac_divisor_d  = fsm_q[FSM_PRE_1_BIT] ? frac_divisor_iter_init : (nr_frac_rem[54] ? nr_frac_rem_plus_d[53:0] : nr_frac_rem[53:0]);
always_ff @(posedge clk)
	if(frac_divisor_en)
		frac_divisor_q <= frac_divisor_d;

// ================================================================================================================================================
// Overlapped srt iteration
// ================================================================================================================================================

assign frac_rem_sum_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign frac_rem_sum_d  = 
start_handshaked 		? {2'b0, 1'b1, opa_frac_pre_shifted[51:0]} : 
fsm_q[FSM_PRE_1_BIT] 	? frac_rem_sum_iter_init : 
frac_rem_sum_out[2];
	
assign frac_rem_carry_en = start_handshaked | fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign frac_rem_carry_d  = 
start_handshaked 		? {2'b0, 1'b1, opb_frac_pre_shifted[51:0]} : 
fsm_q[FSM_PRE_1_BIT] 	? frac_rem_carry_iter_init : 
frac_rem_carry_out[2];

assign final_iter = (iter_num_q == 5'd0);
assign iter_num_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
// fp64: iter_num_needed = ceil((53 + 1) / 3) = 18, 18 - 1 = 17
// fp32: iter_num_needed = ceil((24 + 1) / 3) =  9,  9 - 1 =  8
// fp16: iter_num_needed = ceil((11 + 1) / 3) =  4,  4 - 1 =  3
assign iter_num_d  = fsm_q[FSM_PRE_1_BIT] ? ((fp_format_q == 2'd0) ? 5'd3 : (fp_format_q == 2'd1) ? 5'd8 : 5'd17) : (iter_num_q - 5'd1);

always_ff @(posedge clk) begin
	if(frac_rem_sum_en)
		frac_rem_sum_q <= frac_rem_sum_d;
	if(frac_rem_carry_en)
		frac_rem_carry_q <= frac_rem_carry_d;
	if(iter_num_en)
		iter_num_q <= iter_num_d;
end


// For stage[0], no speculation is needed
radix_2_qds
u_qds_s0 (
	.rem_sum_msb_i(frac_rem_sum_q[54:52]),
	.rem_carry_msb_i(frac_rem_carry_q[54:52]),
	.quo_dig_o(quo_dig[0])
);

generate for(i = 0; i < 3; i++) begin: g_csa_val_select
	assign div_csa_val[i][55-1:0] = 
	  ({(ITN_W){quo_dig[i][0]}} & ~{1'b0, 1'b1, frac_divisor_q[51:0], 1'b0})
	| ({(ITN_W){quo_dig[i][1]}} &  {1'b0, 1'b1, frac_divisor_q[51:0], 1'b0});
end
endgenerate

// Set unused signals to ZERO
assign quo_dig_zero[0]  = '0;
assign quo_dig_plus[0]  = '0;
assign quo_dig_minus[0] = '0;
generate for(i = 1; i < 3; i++) begin: g_speculative_qds
	// speculation is only needed for stage[1, 2]

	// Assume previous quo is 0
	radix_2_qds
	u_qds_zero (
		.rem_sum_msb_i(frac_rem_sum_out_msbs_zero[i-1][5:3]),
		.rem_carry_msb_i(frac_rem_carry_out_msbs_zero[i-1][5:3]),
		.quo_dig_o(quo_dig_zero[i])
	);

	// Assume previous quo is -1
	radix_2_qds
	u_qds_plus (
		.rem_sum_msb_i(frac_rem_sum_out_msbs_plus[i-1][5:3]),
		.rem_carry_msb_i(frac_rem_carry_out_msbs_plus[i-1][5:3]),
		.quo_dig_o(quo_dig_plus[i])
	);

	// Assume previous quo is +1
	radix_2_qds
	u_qds_minus (
		.rem_sum_msb_i(frac_rem_sum_out_msbs_minus[i-1][5:3]),
		.rem_carry_msb_i(frac_rem_carry_out_msbs_minus[i-1][5:3]),
		.quo_dig_o(quo_dig_minus[i])
	);

	assign quo_dig[i] = quo_dig[i-1][0] ? quo_dig_minus[i] : quo_dig[i-1][1] ? quo_dig_plus[i] : quo_dig_zero[i];
end
endgenerate

assign frac_rem_sum_in[0] = frac_rem_sum_q;
assign frac_rem_carry_in[0] = frac_rem_carry_q;
assign frac_rem_sum_in[1] = frac_rem_sum_out[0];
assign frac_rem_carry_in[1] = frac_rem_carry_out[0];
assign frac_rem_sum_in[2] = frac_rem_sum_out[1];
assign frac_rem_carry_in[2] = frac_rem_carry_out[1];

generate for(i = 0; i < 3; i++) begin: g_speculative_msb_compress
	// In fact, for LSB: 1'b0 ^ 1'b0 ^ div_csa_val[i][0] = div_csa_val[i][0], so maybe we should not use "XOR" operation for LSB (to save some gates...)
	assign frac_rem_sum_out_lsbs[i] = 
	  {frac_rem_sum_in  [i][0 +: (ITN_W - SPECULATIVE_MSB_W - 1)], 1'b0}
	^ {frac_rem_carry_in[i][0 +: (ITN_W - SPECULATIVE_MSB_W - 1)], 1'b0}
	^ div_csa_val[i][0 +: (ITN_W - SPECULATIVE_MSB_W)];
	
	// {frac_rem_sum_in[i][47:0], 1'b0}[0] and {frac_rem_carry_in[i][47:0], 1'b0}[0] is ZERO, so the csa result must be 0...
	assign frac_rem_carry_out_lsbs[i] = {
		  (frac_rem_sum_in  [i][0 +: (ITN_W - SPECULATIVE_MSB_W - 1)] & frac_rem_carry_in	[i][0 +: (ITN_W - SPECULATIVE_MSB_W - 1)])
		| (frac_rem_sum_in  [i][0 +: (ITN_W - SPECULATIVE_MSB_W - 1)] & div_csa_val			[i][1 +: (ITN_W - SPECULATIVE_MSB_W - 1)])
		| (frac_rem_carry_in[i][0 +: (ITN_W - SPECULATIVE_MSB_W - 1)] & div_csa_val			[i][1 +: (ITN_W - SPECULATIVE_MSB_W - 1)]),
		1'b0
	};

	// stage[0]: frac_rem_carry_in[0][54 -: 6] is already ready, we can start csa immediately. And we use "(2 * rem)[MSB -: 6]" for csa
	// stage[1]: "frac_rem_sum_in[1][54 -: 6], frac_rem_carry_in[1][54 -: 5] (frac_rem_carry_in[1][49] is not calculated speculativly)" 
	// is calculated speculativly, we can start csa as soon as possible
	// stage[1] -> stage[2]: Mulitiply the MSBs of "frac_rem_xxx[1]" by 2 -> now only "5-bit MSBs of frac_rem_sum" and 
	// "4-bit MSBs of frac_rem_carry" is available
	// stage[2]: "frac_rem_sum_in[2][54 -: 4], frac_rem_carry_in[2][54 -: 3]" is calculated speculativly, we can start csa as soon as possible
	// 3-bit is already enough for radix_2_qds
	radix_2_csa #(
		.WIDTH(SPECULATIVE_MSB_W + 1)
	) u_csa_for_msb (
		.csa_plus_i				(frac_divisor_q[51 -: (SPECULATIVE_MSB_W - 2)]),
		.csa_minus_i			(frac_divisor_q[51 -: (SPECULATIVE_MSB_W - 2)]),
		
		.rem_sum_i				(frac_rem_sum_in  [i][(ITN_W-2) -: SPECULATIVE_MSB_W]),
		.rem_carry_i			(frac_rem_carry_in[i][(ITN_W-2) -: SPECULATIVE_MSB_W]),

		.rem_sum_zero_o			(frac_rem_sum_out_msbs_zero  [i][SPECULATIVE_MSB_W-1:0]),
		.rem_carry_zero_o		(frac_rem_carry_out_msbs_zero[i][SPECULATIVE_MSB_W-1:0]),

		.rem_sum_minus_d_o		(frac_rem_sum_out_msbs_minus  [i][SPECULATIVE_MSB_W-1:0]),
		.rem_carry_minus_d_o	(frac_rem_carry_out_msbs_minus[i][SPECULATIVE_MSB_W-1:0]),

		.rem_sum_plus_d_o		(frac_rem_sum_out_msbs_plus  [i][SPECULATIVE_MSB_W-1:0]),
		.rem_carry_plus_d_o		(frac_rem_carry_out_msbs_plus[i][SPECULATIVE_MSB_W-1:0])
	);
	
	assign frac_rem_sum_out_msbs[i] = 
	quo_dig[i][0] ? frac_rem_sum_out_msbs_minus[i] : 
	quo_dig[i][1] ? frac_rem_sum_out_msbs_plus[i] : 
	frac_rem_sum_out_msbs_zero[i];
	
	assign frac_rem_carry_out_msbs[i] = 
	quo_dig[i][0] ? frac_rem_carry_out_msbs_minus[i] : 
	quo_dig[i][1] ? frac_rem_carry_out_msbs_plus[i] : 
	frac_rem_carry_out_msbs_zero[i];
	
	assign frac_rem_sum_out[i] = {frac_rem_sum_out_msbs[i][SPECULATIVE_MSB_W-1:0], frac_rem_sum_out_lsbs[i]};
	assign frac_rem_carry_out[i] = {frac_rem_carry_out_msbs[i][SPECULATIVE_MSB_W-1:1], frac_rem_carry_out_lsbs[i], quo_dig[i][0]};
end
endgenerate


// ================================================================================================================================================
// Update Quotient Registers
// OTFC ??
// ================================================================================================================================================

assign nxt_quo_iter[0] 	  = quo_dig[0][0] ? {quo_iter_q[53:0], 1'b1} : quo_dig[0][1] ? {quo_m1_iter_q[53:0], 1'b1} : {quo_iter_q   [53:0], 1'b0};
assign nxt_quo_m1_iter[0] = quo_dig[0][0] ? {quo_iter_q[53:0], 1'b0} : quo_dig[0][1] ? {quo_m1_iter_q[53:0], 1'b0} : {quo_m1_iter_q[53:0], 1'b1};

assign nxt_quo_iter[1] 	  = quo_dig[1][0] ? {nxt_quo_iter[0][53:0], 1'b1} : quo_dig[1][1] ? {nxt_quo_m1_iter[0][53:0], 1'b1} : {nxt_quo_iter   [0][53:0], 1'b0};
assign nxt_quo_m1_iter[1] = quo_dig[1][0] ? {nxt_quo_iter[0][53:0], 1'b0} : quo_dig[1][1] ? {nxt_quo_m1_iter[0][53:0], 1'b0} : {nxt_quo_m1_iter[0][53:0], 1'b1};

assign nxt_quo_iter[2] 	  = quo_dig[2][0] ? {nxt_quo_iter[1][53:0], 1'b1} : quo_dig[2][1] ? {nxt_quo_m1_iter[1][53:0], 1'b1} : {nxt_quo_iter   [1][53:0], 1'b0};
assign nxt_quo_m1_iter[2] = quo_dig[2][0] ? {nxt_quo_iter[1][53:0], 1'b0} : quo_dig[2][1] ? {nxt_quo_m1_iter[1][53:0], 1'b0} : {nxt_quo_m1_iter[1][53:0], 1'b1};

// Put opa_frac into right position when we can skip the iter
// fp16: 1 +  4 * 3 = 13
// fp32: 1 +  9 * 3 = 28
// fp64: 1 + 18 * 3 = 55
assign quo_iter_init = opb_is_power_of_2_q ? (
	(fp_format_q == 2'd0) ? {{(55 - 2 - FP16_FRAC_W){1'b0}}, opa_frac_l_shifted[52 -: FP16_FRAC_W], 2'b0} : 
	(fp_format_q == 2'd1) ? {{(55 - 4 - FP32_FRAC_W){1'b0}}, opa_frac_l_shifted[52 -: FP32_FRAC_W], 4'b0} : 
	{{(55 - 2 - FP64_FRAC_W){1'b0}}, opa_frac_l_shifted[52 -: FP64_FRAC_W], 2'b0}
) : {54'b0, 1'b1};
assign quo_iter_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT] | fsm_q[FSM_POST_0_BIT];
// quo_iter_q/quo_m1_iter_q is also used to store the "quo/rem" before rounding.
// The 1st quo_dig must be "+1"
assign quo_iter_d  = fsm_q[FSM_PRE_1_BIT] ? quo_iter_init : fsm_q[FSM_ITER_BIT] ? nxt_quo_iter[2] : {correct_quo_r_shifted, sticky_without_rem[55]};
assign quo_m1_iter_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT] | fsm_q[FSM_POST_0_BIT];
assign quo_m1_iter_d  = fsm_q[FSM_PRE_1_BIT] ? '0 : fsm_q[FSM_ITER_BIT] ? nxt_quo_m1_iter[2] : sticky_without_rem[54:0];
always_ff @(posedge clk) begin
	if(quo_iter_en)
		quo_iter_q <= quo_iter_d;
	if(quo_m1_iter_en)
		quo_m1_iter_q <= quo_m1_iter_d;
end

// ================================================================================================================================================
// post_0
// ================================================================================================================================================

// nr = non_redundant
assign nr_frac_rem = frac_rem_sum_q + frac_rem_carry_q;
assign nr_frac_rem_plus_d = frac_rem_sum_q + frac_rem_carry_q + {1'b0, 1'b1, frac_divisor_q[51:0], 1'b0};

// When (exp_diff <= 0), result might be denormal, we need to r_shift the quo before rounding
// To speed up, use 2 r_shifter here (area cost is increased...)
// The MSB of quo and quo_m1 must be the same (See docs for proof).
assign quo_msb = (fp_format_q == 2'd0) ? quo_iter_q[12] : (fp_format_q == 2'd1) ? quo_iter_q[27] : quo_iter_q[54];

// For FP32, we get extra 2-bit quo -> should merge them.
assign quo_pre_shift = quo_msb ? {quo_iter_q[54:28], (fp_format_q == 2'd1) ? {quo_iter_q[27:3], |(quo_iter_q[2:0])} : quo_iter_q[27:0]} : 
{quo_iter_q[53:27], (fp_format_q == 2'd1) ? {quo_iter_q[26:2], |(quo_iter_q[1:0])} : {quo_iter_q[26:0], 1'b0}};

assign quo_m1_pre_shift = quo_msb ? {quo_m1_iter_q[54:28], (fp_format_q == 2'd1) ? {quo_m1_iter_q[27:3], |(quo_m1_iter_q[2:0])} : quo_m1_iter_q[27:0]} : 
{quo_m1_iter_q[53:27], (fp_format_q == 2'd1) ? {quo_m1_iter_q[26:2], |(quo_m1_iter_q[1:0])} : {quo_m1_iter_q[26:0], 1'b0}};

assign r_shift_num_pre = 13'd1 - out_exp_diff_q;
assign r_shift_num_pre_minus_limit = 13'd1 - out_exp_diff_q - R_SHIFT_NUM_LIMIT;
assign r_shift_num = r_shift_num_pre[12] ? 6'd0 : ~r_shift_num_pre_minus_limit[12] ? R_SHIFT_NUM_LIMIT : r_shift_num_pre[5:0];

// TODO: The shifter in post_0 could be combined with the shifter used in pre_1 if the timing is good enough.
assign quo_r_shifted    = {quo_pre_shift,    55'b0} >> r_shift_num;
assign quo_m1_r_shifted = {quo_m1_pre_shift, 55'b0} >> r_shift_num;

assign sticky_without_rem = nr_frac_rem[54] ? quo_m1_r_shifted[0 +: 56] : quo_r_shifted[0 +: 56];
assign correct_quo_r_shifted = nr_frac_rem[54] ? quo_m1_r_shifted[56 +: 54] : quo_r_shifted[56 +: 54];

// ================================================================================================================================================
// post_1
// ================================================================================================================================================

// ================================================================================================================================================
// Rounding logic
// ================================================================================================================================================
assign rem_is_not_zero = (frac_divisor_q != 0);
assign sticky_bit = rem_is_not_zero | (|{quo_iter_q[0], quo_m1_iter_q});

// quo_iter_q[54] is not needed...
// For fp64: now the decimal point is between "quo_iter_q[54], quo_iter_q[53]", for rounding operation, we only need the fractional part.
assign frac_before_round = {
	quo_iter_q[53:26], 
	~(fp_format_q == 2'd1) & quo_iter_q[25], 
	quo_iter_q[24:13], 
	~(fp_format_q == 2'd0) & quo_iter_q[12], 
	quo_iter_q[11:2]
};
assign guard_bit = frac_before_round[0];
assign round_bit = quo_iter_q[1];
assign exp_before_round = out_exp_diff_q[12] ? 12'd0 : out_exp_diff_q[11:0];
assign inexact = round_bit | sticky_bit;
assign round_up = 
  ({rm_q == RM_RNE} & ((round_bit & sticky_bit) | (guard_bit & round_bit)))
| ({rm_q == RM_RDN} & ((round_bit | sticky_bit) &  out_sign_q))
| ({rm_q == RM_RUP} & ((round_bit | sticky_bit) & ~out_sign_q))
| ({rm_q == RM_RMM} &   round_bit);
assign frac_after_round[52:0] = {1'b0, frac_before_round[51:0]} + {52'b0, round_up};
assign carry_after_round = (fp_format_q == 2'd0) ? frac_after_round[10] : (fp_format_q == 2'd1) ? frac_after_round[23] : frac_after_round[52];
// Don't need to calculate "exp_before_round + 1" -> See docs for proof...
assign exp_after_round = {exp_before_round[11:1], exp_before_round[0] | carry_after_round};

assign overflow = (exp_after_round >= ((fp_format_q == 2'd0) ? 11'd31 : (fp_format_q == 2'd1) ? 11'd255 : 11'd2047));
assign overflow_to_inf = (rm_q == RM_RNE) | (rm_q == RM_RMM) | ((rm_q == RM_RUP) & ~out_sign_q) | ((rm_q == RM_RDN) & out_sign_q);

assign fp16_out_exp = 
(res_is_nan_q | res_is_inf_q | (overflow & overflow_to_inf)) ? {(5){1'b1}} : 
(overflow & ~overflow_to_inf) ? {{(4){1'b1}}, 1'b0} : 
res_is_exact_zero_q ? 5'b0 : 
exp_after_round[4:0];

assign fp32_out_exp = 
(res_is_nan_q | res_is_inf_q | (overflow & overflow_to_inf)) ? {(8){1'b1}} : 
(overflow & ~overflow_to_inf) ? {{(7){1'b1}}, 1'b0} : 
res_is_exact_zero_q ? 8'b0 : 
exp_after_round[7:0];

assign fp64_out_exp = 
(res_is_nan_q | res_is_inf_q | (overflow & overflow_to_inf)) ? {(11){1'b1}} : 
(overflow & ~overflow_to_inf) ? {{(10){1'b1}}, 1'b0} : 
res_is_exact_zero_q ? 11'b0 : 
exp_after_round[10:0];

assign fp16_out_frac = 
res_is_nan_q ? {1'b1, 9'b0} : 
(res_is_inf_q | (overflow & overflow_to_inf) | res_is_exact_zero_q) ? 10'b0 : 
(overflow & ~overflow_to_inf) ? {(10){1'b1}} : 
frac_after_round[0 +: 10];

assign fp32_out_frac = 
res_is_nan_q ? {1'b1, 22'b0} : 
(res_is_inf_q | (overflow & overflow_to_inf) | res_is_exact_zero_q) ? 23'b0 :  
(overflow & ~overflow_to_inf) ? {(23){1'b1}} : 
frac_after_round[0 +: 23];

assign fp64_out_frac = 
res_is_nan_q ? {1'b1, 51'b0} : 
(res_is_inf_q | (overflow & overflow_to_inf) | res_is_exact_zero_q) ? 52'b0 : 
(overflow & ~overflow_to_inf) ? {(52){1'b1}} : 
frac_after_round[0 +: 52];

assign fflags_invalid_operation = op_invalid_div_q;
assign fflags_div_by_zero = divided_by_zero_q;
// When (overflow), res_is_exact_zero_q must be ZERO.
assign fflags_overflow = overflow & ~res_is_inf_q & ~res_is_nan_q;
assign fflags_underflow = (exp_after_round == '0) & inexact & ~res_is_exact_zero_q & ~res_is_inf_q & ~res_is_nan_q;
assign fflags_inexact = (overflow | inexact) & ~res_is_inf_q & ~res_is_nan_q & ~res_is_exact_zero_q;

assign fp16_res = {out_sign_q, fp16_out_exp, fp16_out_frac};
assign fp32_res = {out_sign_q, fp32_out_exp, fp32_out_frac};
assign fp64_res = {out_sign_q, fp64_out_exp, fp64_out_frac};

assign fpdiv_res_o = {
	fp64_res[63:32], 
	(fp_format_q == 2'd1) ? fp32_res[31:16] : fp64_res[31:16], 
	(fp_format_q == 2'd0) ? fp16_res[15:0] : (fp_format_q == 2'd1) ? fp32_res[15:0] : fp64_res[15:0]
};
assign fflags_o = {
	fflags_invalid_operation,
	fflags_div_by_zero,
	fflags_overflow,
	fflags_underflow,
	fflags_inexact
};

endmodule

