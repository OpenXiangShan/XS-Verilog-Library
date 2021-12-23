// ========================================================================================================
// File Name			: int_div_radix_16_v3.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-07-23 10:08:49
// Last Modified Time   : 2021-12-05 11:41:23
// ========================================================================================================
// Description	:
// A Radix-16 SRT Integer Divider, by using 4 overlapped Radix-2.
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

module int_div_radix_16_v3 #(
	// Put some parameters here, which can be changed by other modules
	// Only support WIDTH = 64/32/16
	parameter WIDTH = 64
)(
	input  logic div_start_valid_i,
	output logic div_start_ready_o,
	input  logic flush_i,
	input  logic signed_op_i,
	input  logic [WIDTH-1:0] dividend_i,
	input  logic [WIDTH-1:0] divisor_i,

	output logic div_finish_valid_o,
	input  logic div_finish_ready_i,
	output logic [WIDTH-1:0] quotient_o,
	output logic [WIDTH-1:0] remainder_o,
	output logic divisor_is_zero_o,

	input  logic clk,
	input  logic rst_n
);

// ================================================================================================================================================
// (local) parameters begin

localparam FSM_W	 			= 6;
localparam FSM_IDLE_ABS_BIT	 	= 0;
localparam FSM_PRE_0_BIT	 	= 1;
localparam FSM_PRE_1_BIT	 	= 2;
localparam FSM_ITER_BIT		 	= 3;
localparam FSM_POST_0_BIT	 	= 4;
localparam FSM_POST_1_BIT	 	= 5;
localparam FSM_IDLE_ABS			= 6'b00_0001;
localparam FSM_PRE_PROCESS_0 	= 6'b00_0010;
localparam FSM_PRE_PROCESS_1 	= 6'b00_0100;
localparam FSM_SRT_ITERATION 	= 6'b00_1000;
localparam FSM_POST_PROCESS_0 	= 6'b01_0000;
localparam FSM_POST_PROCESS_1 	= 6'b10_0000;

// How many bits do we need to express the Leading Zero Count of the data ?
localparam LZC_WIDTH = $clog2(WIDTH);

// ITN = InTerNal
// 3-bit after the LSB of REM -> For Align operation.
localparam ITN_W = WIDTH + 3;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// functions begin



// functions end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

genvar i;

logic div_start_handshaked;
logic [FSM_W-1:0] fsm_d;
logic [FSM_W-1:0] fsm_q;

// 1-extra bit for LZC
logic [(LZC_WIDTH + 1)-1:0] dividend_lzc;
logic [(LZC_WIDTH + 1)-1:0] divisor_lzc;
logic dividend_lzc_en;
logic [(LZC_WIDTH + 1)-1:0] dividend_lzc_d;
logic [(LZC_WIDTH + 1)-1:0] dividend_lzc_q;
logic divisor_lzc_en;
logic [(LZC_WIDTH + 1)-1:0] divisor_lzc_d;
logic [(LZC_WIDTH + 1)-1:0] divisor_lzc_q;
logic [(LZC_WIDTH + 1)-1:0] lzc_diff;
logic [2-1:0] r_shift_num;
logic iter_num_en;
logic [(LZC_WIDTH - 2)-1:0] iter_num_d;
logic [(LZC_WIDTH - 2)-1:0] iter_num_q;
logic final_iter;

logic dividend_sign;
logic divisor_sign;
logic [WIDTH-1:0] dividend_abs;
logic [WIDTH-1:0] divisor_abs;
logic dividend_abs_en;
logic [(WIDTH+1)-1:0] dividend_abs_d;
logic [(WIDTH+1)-1:0] dividend_abs_q;
logic [WIDTH-1:0] normalized_dividend;
logic divisor_abs_en;
logic [(WIDTH+1)-1:0] divisor_abs_d;
logic [(WIDTH+1)-1:0] divisor_abs_q;
logic [WIDTH-1:0] normalized_divisor;
logic [(ITN_W + 2)-1:0] divisor_ext;
logic [WIDTH-1:0] inverter_in [1:0];
logic [WIDTH-1:0] inverter_res [1:0];

logic dividend_too_small;
logic dividend_too_small_en;
logic dividend_too_small_d;
logic dividend_too_small_q;
logic divisor_is_zero;
logic quo_sign_en;
logic quo_sign_d;
logic quo_sign_q;
logic rem_sign_en;
logic rem_sign_d;
logic rem_sign_q;

// nr = non_redundant
// logic [(ITN_W + 2)-1:0] nr_rem_nxt;
logic [(ITN_W + 1)-1:0] nr_rem_nxt;
logic [(ITN_W + 2)-1:0] nr_rem_plus_d_nxt;
logic [(WIDTH + 1)-1:0] nr_rem;
logic [(WIDTH + 1)-1:0] nr_rem_plus_d;
logic nr_rem_is_zero;
logic need_corr;

logic [(WIDTH + 1)-1:0] pre_shifted_rem;
logic [WIDTH-1:0] post_r_shift_data_in;
logic [(LZC_WIDTH)-1:0] post_r_shift_num;
logic post_r_shift_extend_msb;
// S0 ~ S5 is enough for "WIDTH <= 64".
logic [WIDTH-1:0] post_r_shift_res_s0;
logic [WIDTH-1:0] post_r_shift_res_s1;
logic [WIDTH-1:0] post_r_shift_res_s2;
logic [WIDTH-1:0] post_r_shift_res_s3;
logic [WIDTH-1:0] post_r_shift_res_s4;
logic [WIDTH-1:0] post_r_shift_res_s5;
// logic [WIDTH-1:0] post_r_shift_res_s6;

logic [(ITN_W + 2)-1:0] rem_sum_init_value;
logic rem_sum_en;
logic [(ITN_W + 2)-1:0] rem_sum_d;
logic [(ITN_W + 2)-1:0] rem_sum_q;
logic rem_carry_en;
logic [(ITN_W + 2)-1:0] rem_carry_d;
logic [(ITN_W + 2)-1:0] rem_carry_q;
logic [(ITN_W - 1)-1:0] mux_divisor [3-1:0];

logic prev_prev_quo_en;
logic [2-1:0] prev_prev_quo_d;
logic [2-1:0] prev_prev_quo_q;
logic prev_quo_zero_en;
logic [2-1:0] prev_quo_zero_d;
logic [2-1:0] prev_quo_zero_q;
logic prev_quo_plus_d_en;
logic [2-1:0] prev_quo_plus_d_d;
logic [2-1:0] prev_quo_plus_d_q;
logic prev_quo_minus_d_en;
logic [2-1:0] prev_quo_minus_d_d;
logic [2-1:0] prev_quo_minus_d_q;

logic quo_iter_en;
logic [WIDTH-1:0] quo_iter_d;
logic [WIDTH-1:0] quo_iter_q;
logic [WIDTH-1:0] quo_iter_nxt [4-1:0];
// m1 = minus_1
logic quo_m1_iter_en;
logic [WIDTH-1:0] quo_m1_iter_d;
logic [WIDTH-1:0] quo_m1_iter_q;
logic [WIDTH-1:0] quo_m1_iter_nxt [4-1:0];

logic [2-1:0] quo_dig [4-1:0];
logic [2-1:0] quo_dig_zero [4-1:0];
logic [2-1:0] quo_dig_plus_d [4-1:0];
logic [2-1:0] quo_dig_minus_d [4-1:0];

logic [11-1:0] rem_sum_cp [5-1:0];
logic [11-1:0] rem_carry_cp [5-1:0];
logic [11-1:0] rem_sum_zero [5-1:0];
logic [11-1:0] rem_carry_zero [5-1:0];
logic [11-1:0] rem_sum_minus_d [5-1:0];
logic [11-1:0] rem_carry_minus_d [5-1:0];
logic [11-1:0] rem_sum_plus_d [5-1:0];
logic [11-1:0] rem_carry_plus_d [5-1:0];

logic [(ITN_W + 2)-1:0] rem_sum_dp [5-1:0];
logic [(ITN_W + 2)-1:0] rem_carry_dp [5-1:0];
logic [(ITN_W + 1)-1:0] rem_sum_zero_dp;
logic [(ITN_W + 1)-1:0] rem_carry_zero_dp;
logic [(ITN_W + 1)-1:0] rem_sum_minus_d_dp;
logic [(ITN_W + 1)-1:0] rem_carry_minus_d_dp;
logic [(ITN_W + 1)-1:0] rem_sum_plus_d_dp;
logic [(ITN_W + 1)-1:0] rem_carry_plus_d_dp;

logic [WIDTH-1:0] final_rem;
logic [WIDTH-1:0] final_quo;

// signals end
// ================================================================================================================================================

assign div_start_handshaked = div_start_valid_i & div_start_ready_o;

// ================================================================================================================================================
// FSM Control
// ================================================================================================================================================
always_comb begin
	unique case(fsm_q)
		FSM_IDLE_ABS:
			fsm_d = div_start_valid_i ? FSM_PRE_PROCESS_0 : FSM_IDLE_ABS;
		FSM_PRE_PROCESS_0:
			fsm_d = FSM_PRE_PROCESS_1;
		FSM_PRE_PROCESS_1:
			fsm_d = (dividend_too_small_q | divisor_is_zero) ? FSM_POST_PROCESS_0 : FSM_SRT_ITERATION;
		FSM_SRT_ITERATION:
			fsm_d = final_iter ? FSM_POST_PROCESS_0 : FSM_SRT_ITERATION;
		FSM_POST_PROCESS_0:
			fsm_d = FSM_POST_PROCESS_1;
		FSM_POST_PROCESS_1:
			fsm_d = div_finish_ready_i ? FSM_IDLE_ABS : FSM_POST_PROCESS_1;
		default:
			fsm_d = FSM_PRE_PROCESS_0;
	endcase

	if(flush_i)
		// flush has the highest priority.
		fsm_d = FSM_IDLE_ABS;
end

// The only reg that need to be reset.
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		fsm_q <= FSM_IDLE_ABS;
	else
		fsm_q <= fsm_d;
end

// ================================================================================================================================================
// Global Inverters to save area.
// ================================================================================================================================================
// FSM_IDLE_ABS: Get the inversed value of dividend_i.
// FSM_POST_PROCESS_0: Get the inversed value of quo_iter.
assign inverter_in[0] = fsm_q[FSM_IDLE_ABS_BIT] ? dividend_i : quo_iter_q;
assign inverter_res[0] = -inverter_in[0];
// FSM_IDLE_ABS: Get the inversed value of divisor_i.
// FSM_POST_PROCESS_0: Get the inversed value of quo_m1_iter.
assign inverter_in[1] = fsm_q[FSM_IDLE_ABS_BIT] ? divisor_i : quo_m1_iter_q;
assign inverter_res[1] = -inverter_in[1];

// ================================================================================================================================================
// Calculate ABS
// ================================================================================================================================================
assign dividend_sign = signed_op_i & dividend_i[WIDTH-1];
assign divisor_sign = signed_op_i & divisor_i[WIDTH-1];
assign dividend_abs = dividend_sign ? inverter_res[0] : dividend_i;
assign divisor_abs = divisor_sign ? inverter_res[1] : divisor_i;

assign dividend_abs_en = div_start_handshaked | fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_POST_0_BIT];
assign divisor_abs_en = div_start_handshaked | fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_POST_0_BIT];
// In PRE_PROCESS_1, if we find "divisor_is_zero", we should force quo_sign = 0 -> So we can get "final_quo = {(WIDTH){1'b1}}";
assign quo_sign_en = div_start_handshaked | (fsm_q[FSM_PRE_1_BIT] & divisor_is_zero);
assign rem_sign_en = div_start_handshaked;
assign quo_sign_d = fsm_q[FSM_IDLE_ABS_BIT] ? (dividend_sign ^ divisor_sign) : 1'b0;
assign rem_sign_d = dividend_sign;

assign dividend_abs_d =
  ({(WIDTH + 1){fsm_q[FSM_IDLE_ABS_BIT]}} 	& {1'b0, dividend_abs})
| ({(WIDTH + 1){fsm_q[FSM_PRE_0_BIT]}} 		& {1'b0, normalized_dividend})
// | ({(WIDTH + 1){fsm_q[FSM_POST_0_BIT]}} 	& nr_rem_nxt[4 +: (WIDTH + 1)]);
| ({(WIDTH + 1){fsm_q[FSM_POST_0_BIT]}} 	& nr_rem_nxt[3 +: (WIDTH + 1)]);
assign divisor_abs_d =
  ({(WIDTH + 1){fsm_q[FSM_IDLE_ABS_BIT]}}	& {1'b0, divisor_abs})
| ({(WIDTH + 1){fsm_q[FSM_PRE_0_BIT]}}		& {1'b0, normalized_divisor})
| ({(WIDTH + 1){fsm_q[FSM_POST_0_BIT]}} 	& nr_rem_plus_d_nxt[3 +: (WIDTH + 1)]);

always_ff @(posedge clk) begin
	if(dividend_abs_en)
		dividend_abs_q <= dividend_abs_d;
	if(divisor_abs_en)
		divisor_abs_q <= divisor_abs_d;
	if(quo_sign_en)
		quo_sign_q <= quo_sign_d;
	if(rem_sign_en)
		rem_sign_q <= rem_sign_d;
end

// ================================================================================================================================================
// LZC and Normalize
// ================================================================================================================================================
// Use the open-source LZC from ETH Zurich, University of Bologna.
// You should use DW_lzd (If it as available) to replace it for better synthesis results.
lzc #(
	.WIDTH(WIDTH),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_dividend (
	.in_i(dividend_abs_q[WIDTH-1:0]),
	.cnt_o(dividend_lzc[LZC_WIDTH-1:0]),
	.empty_o(dividend_lzc[LZC_WIDTH])
);
lzc #(
	.WIDTH(WIDTH),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_divisor (
	.in_i(divisor_abs_q[WIDTH-1:0]),
	.cnt_o(divisor_lzc[LZC_WIDTH-1:0]),
	.empty_o(divisor_lzc[LZC_WIDTH])
);

assign normalized_dividend = dividend_abs_q[WIDTH-1:0] << dividend_lzc[LZC_WIDTH-1:0];
assign normalized_divisor  = divisor_abs_q [WIDTH-1:0] << divisor_lzc [LZC_WIDTH-1:0];
assign dividend_lzc_en = fsm_q[FSM_PRE_0_BIT];
assign divisor_lzc_en = fsm_q[FSM_PRE_0_BIT];
assign dividend_lzc_d = dividend_lzc;
assign divisor_lzc_d = divisor_lzc;

always_ff @(posedge clk) begin
	if(dividend_lzc_en)
		dividend_lzc_q <= dividend_lzc_d;
	if(divisor_lzc_en)
		divisor_lzc_q <= divisor_lzc_d;
end

// ================================================================================================================================================
// Calculate iter_num
// ================================================================================================================================================
assign lzc_diff = fsm_q[FSM_PRE_0_BIT] ? {1'b0, divisor_lzc[0 +: LZC_WIDTH]} - {1'b0, dividend_lzc[0 +: LZC_WIDTH]} : 
{1'b0, divisor_lzc_q[0 +: LZC_WIDTH]} - {1'b0, dividend_lzc_q[0 +: LZC_WIDTH]};

assign dividend_too_small = lzc_diff[LZC_WIDTH] | dividend_lzc[LZC_WIDTH];
assign divisor_is_zero = divisor_lzc_q[LZC_WIDTH];
// Make "dividend_too_small" faster in POST_PROCESS_1.
assign dividend_too_small_en = fsm_q[FSM_PRE_0_BIT];
assign dividend_too_small_d = dividend_too_small;
always_ff @(posedge clk)
	if(dividend_too_small_en)
		dividend_too_small_q <= dividend_too_small_d;

// TO save a 2-bit FA, use "lzc_diff[1:0]" to express "r_shift_num";
assign r_shift_num = lzc_diff[1:0];
// For Radix-16 overlapped by 4 Radix-2, iter_num_pre = ceil((lzc_diff + 1) / 4);
// In the Retiming Architecture, in PRE_PROCESS_1, we can get q[0] -> So the equation becomes:
// iter_num_pre = ceil(lzc_diff / 4)
// Take "WIDTH = 32" as an example, lzc_diff,
//  0 -> iter_num_pre = 1, exp_r_shift_num = 3
//  1 -> iter_num_pre = 1, exp_r_shift_num = 2
//  2 -> iter_num_pre = 1, exp_r_shift_num = 1
//  3 -> iter_num_pre = 1, exp_r_shift_num = 0
//  4 -> iter_num_pre = 2, exp_r_shift_num = 3
//  5 -> iter_num_pre = 2, exp_r_shift_num = 2
//  6 -> iter_num_pre = 2, exp_r_shift_num = 1
//  7 -> iter_num_pre = 2, exp_r_shift_num = 0
//  8 -> iter_num_pre = 3, exp_r_shift_num = 3
//  9 -> iter_num_pre = 3, exp_r_shift_num = 2
// ...
// 28 -> iter_num_pre = 8, exp_r_shift_num = 3
// 29 -> iter_num_pre = 8, exp_r_shift_num = 2
// 30 -> iter_num_pre = 8, exp_r_shift_num = 1
// 31 -> iter_num_pre = 8, exp_r_shift_num = 0
// As a result, we need "(LZC_WIDTH - 2)-bit" reg to record iter_num.
// divisor_is_zero/dividend_too_small: Put the dividend at the suitable position. So we can get the correct REM in POST_PROCESS_1.

assign rem_sum_init_value = (divisor_is_zero | dividend_too_small_q) ? {1'b0, post_r_shift_res_s5, 4'b0} : {
	2'b0,
	  ({(ITN_W){r_shift_num == 2'd3}} & {		dividend_abs_q[WIDTH-1:0], 3'b0	})
	| ({(ITN_W){r_shift_num == 2'd2}} & {1'b0, 	dividend_abs_q[WIDTH-1:0], 2'b0	})
	| ({(ITN_W){r_shift_num == 2'd1}} & {2'b0, 	dividend_abs_q[WIDTH-1:0], 1'b0	})
	| ({(ITN_W){r_shift_num == 2'd0}} & {3'b0, 	dividend_abs_q[WIDTH-1:0] 		})
};

// "prev_prev_quo": When we could get 4-bit quo per iteration and we call them q[3, 2, 1, 0], then we regard "prev_prev_quo" as "q[2]".
// In PRE_PROCESS_1, just make "prev_prev_quo_d = 0", and we could get the correct quo_dig[0] in the 1st iteration.
assign prev_prev_quo_d = fsm_q[FSM_PRE_1_BIT] ? 2'b00 : quo_dig[3];
assign prev_prev_quo_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
always_ff @(posedge clk)
	if(prev_prev_quo_en)
		prev_prev_quo_q <= prev_prev_quo_d;

// According to the QDS, the 1st quo must be +1 -> Make the input of the 3-1 MUX +1.
assign prev_quo_zero_d = fsm_q[FSM_PRE_1_BIT] ? 2'b01 : quo_dig_zero[3];
assign prev_quo_plus_d_d = fsm_q[FSM_PRE_1_BIT] ? 2'b01 : quo_dig_plus_d[3];
assign prev_quo_minus_d_d = fsm_q[FSM_PRE_1_BIT] ? 2'b01 : quo_dig_minus_d[3];
assign prev_quo_zero_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign prev_quo_plus_d_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign prev_quo_minus_d_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
always_ff @(posedge clk) begin
	if(prev_quo_zero_en)
		prev_quo_zero_q <= prev_quo_zero_d;
	if(prev_quo_plus_d_en)
		prev_quo_plus_d_q <= prev_quo_plus_d_d;
	if(prev_quo_minus_d_en)
		prev_quo_minus_d_q <= prev_quo_minus_d_d;
end

assign final_iter = (iter_num_q == {(LZC_WIDTH - 2){1'b0}});
assign iter_num_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign iter_num_d = fsm_q[FSM_PRE_1_BIT] ? lzc_diff[LZC_WIDTH - 1:2] : (iter_num_q - {{(LZC_WIDTH - 3){1'b0}}, 1'b1});
always_ff @(posedge clk)
	if(iter_num_en)
		iter_num_q <= iter_num_d;

// ================================================================================================================================================
// SRT Block
// ================================================================================================================================================

assign rem_sum_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign rem_sum_d = fsm_q[FSM_PRE_1_BIT] ? rem_sum_init_value : rem_sum_dp[4];
assign rem_carry_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign rem_carry_d = fsm_q[FSM_PRE_1_BIT] ? {(ITN_W + 2){1'b0}} : rem_carry_dp[4];
always_ff @(posedge clk) begin
	if(rem_sum_en)
		rem_sum_q <= rem_sum_d;
	if(rem_carry_en)
		rem_carry_q <= rem_carry_d;
end

assign rem_sum_cp[0] = rem_sum_q[(ITN_W + 1) -: 11];
assign rem_carry_cp[0] = rem_carry_q[(ITN_W + 1) -: 11];
assign quo_dig[0] = prev_prev_quo_q[0] ? prev_quo_minus_d_q : prev_prev_quo_q[1] ? prev_quo_plus_d_q : prev_quo_zero_q;

generate
for(i = 0; i < 4; i = i + 1) begin: g_srt_control_path
	// The complete "divisor" used for srt_iter is {2'b00, divisor_abs_q[WIDTH-1:0]}
	// Since divisor_abs_q is normalized, so divisor_abs_q[WIDTH-1] = 1'b1.
	// That means the value of divisor_complete[MSB -: 3] is already-known -> In "radix_2_csa" we just use this already-known information to do CSA calculation
	// Several MSBs of rem_sum_zero[i] is used to form rem_sum_dp[1]
	// Here, actually we are doing "2 * (2 * rem - q * d)"
	// So rem_sum_cp[i][10] doesn't need to be the input signal of "radix_2_csa"
	radix_2_csa #(
		// 11, 9, 7, 5
		.WIDTH(11 - (2 * i))
	) u_radix_2_csa (
		.csa_plus_i				(divisor_abs_q			[WIDTH-2:(WIDTH - 9 + (2 * i))]),
		.csa_minus_i			(divisor_abs_q			[WIDTH-2:(WIDTH - 9 + (2 * i))]),
		.rem_sum_i				(rem_sum_cp				[i][9:(2 * i)]),
		.rem_carry_i			(rem_carry_cp			[i][9:(2 * i)]),

		.rem_sum_zero_o			(rem_sum_zero			[i][10:((2 * i) + 1)]),
		.rem_carry_zero_o		(rem_carry_zero			[i][10:((2 * i) + 1)]),
		.rem_sum_minus_d_o		(rem_sum_minus_d		[i][10:((2 * i) + 1)]),
		.rem_carry_minus_d_o	(rem_carry_minus_d		[i][10:((2 * i) + 1)]),
		.rem_sum_plus_d_o		(rem_sum_plus_d			[i][10:((2 * i) + 1)]),
		.rem_carry_plus_d_o		(rem_carry_plus_d		[i][10:((2 * i) + 1)])
	);

	assign rem_sum_zero			[i][(2 * i):0] = {((2 * i) + 1){1'b0}};
	assign rem_carry_zero		[i][(2 * i):0] = {((2 * i) + 1){1'b0}};
	assign rem_sum_minus_d		[i][(2 * i):0] = {((2 * i) + 1){1'b0}};
	assign rem_carry_minus_d	[i][(2 * i):0] = {((2 * i) + 1){1'b0}};
	assign rem_sum_plus_d		[i][(2 * i):0] = {((2 * i) + 1){1'b0}};
	assign rem_carry_plus_d		[i][(2 * i):0] = {((2 * i) + 1){1'b0}};
	// Hewe we are using "2 * rem_sum" and "2 * rem_carry" to select the next quo
	radix_2_qds u_qds_quo_zero (
		.rem_sum_msb_i(rem_sum_zero[i][10:8]),
		.rem_carry_msb_i(rem_carry_zero[i][10:8]),
		.quo_dig_o(quo_dig_zero[i])
	);
	radix_2_qds u_qds_quo_plus_d (
		.rem_sum_msb_i(rem_sum_plus_d[i][10:8]),
		.rem_carry_msb_i(rem_carry_plus_d[i][10:8]),
		.quo_dig_o(quo_dig_plus_d[i])
	);
	radix_2_qds u_qds_quo_minus_d (
		.rem_sum_msb_i(rem_sum_minus_d[i][10:8]),
		.rem_carry_msb_i(rem_carry_minus_d[i][10:8]),
		.quo_dig_o(quo_dig_minus_d[i])
	);

	assign rem_sum_cp[i+1] = quo_dig[i][0] ? rem_sum_minus_d[i] : quo_dig[i][1] ? rem_sum_plus_d[i] : rem_sum_zero[i];
	assign rem_carry_cp[i+1] = quo_dig[i][0] ? rem_carry_minus_d[i] : quo_dig[i][1] ? rem_carry_plus_d[i] : rem_carry_zero[i];
end
endgenerate
assign quo_dig[1] = quo_dig[0][0] ? quo_dig_minus_d[0] : quo_dig[0][1] ? quo_dig_plus_d[0] : quo_dig_zero[0];
assign quo_dig[2] = quo_dig[1][0] ? quo_dig_minus_d[1] : quo_dig[1][1] ? quo_dig_plus_d[1] : quo_dig_zero[1];
assign quo_dig[3] = quo_dig[2][0] ? quo_dig_minus_d[2] : quo_dig[2][1] ? quo_dig_plus_d[2] : quo_dig_zero[2];

// rem_sum_dp[0, 1, 2, 3, 4] has already multiplied by 2
assign rem_sum_dp[0] = rem_sum_q;
assign rem_carry_dp[0] = rem_carry_q;
assign divisor_ext = {2'b0, divisor_abs_q[WIDTH-1:0], 3'b0};
generate
for(i = 0; i < 3; i = i + 1) begin: g_srt_data_path
	assign mux_divisor[i][(ITN_W-5) + i:0] = quo_dig[i][0] ? ~divisor_ext[(ITN_W-5) + i:0] : quo_dig[i][1] ? divisor_ext[(ITN_W-5) + i:0] : {((ITN_W-4) + i){1'b0}};

	// These unused bits are calculated by srt_ctrl_path.
	assign mux_divisor[i][(ITN_W-2) : (ITN_W-4)+i] = {(3 - i){1'b0}};

	assign rem_sum_dp[i+1][(ITN_W-4)+i:0] = {rem_sum_dp[i][(ITN_W-5)+i:0] ^ rem_carry_dp[i][(ITN_W-5)+i:0] ^ mux_divisor[i][(ITN_W-5)+i:0], 1'b0};

	assign rem_carry_dp[i+1][(ITN_W-3)+i:0] = {
		  (rem_sum_dp	[i][(ITN_W-5)+i:0] 	& rem_carry_dp[i][(ITN_W-5)+i:0])
		| (rem_sum_dp	[i][(ITN_W-5)+i:0] 	& mux_divisor [i][(ITN_W-5)+i:0])
		| (rem_carry_dp	[i][(ITN_W-5)+i:0] 	& mux_divisor [i][(ITN_W-5)+i:0]),
		quo_dig[i][0],
		1'b0
	};

	assign rem_sum_dp	[i+1][(ITN_W+1):(ITN_W-3)+i] = rem_sum_cp	[i+1][10:6+i];
	assign rem_carry_dp [i+1][(ITN_W+1):(ITN_W-2)+i] = rem_carry_cp [i+1][10:7+i];
end
endgenerate

radix_2_csa #(
	.WIDTH(ITN_W + 2)
) u_radix_2_csa_full_width (
	.csa_plus_i				(divisor_ext			[ITN_W-2:0]),
	.csa_minus_i			(divisor_ext			[ITN_W-2:0]),
	.rem_sum_i				(rem_sum_dp				[3][ITN_W:0]),
	.rem_carry_i			(rem_carry_dp			[3][ITN_W:0]),

	.rem_sum_zero_o			(rem_sum_zero_dp		[ITN_W:0]),
	.rem_carry_zero_o		(rem_carry_zero_dp		[ITN_W:0]),
	.rem_sum_minus_d_o		(rem_sum_minus_d_dp		[ITN_W:0]),
	.rem_carry_minus_d_o	(rem_carry_minus_d_dp	[ITN_W:0]),
	.rem_sum_plus_d_o		(rem_sum_plus_d_dp		[ITN_W:0]),
	.rem_carry_plus_d_o		(rem_carry_plus_d_dp	[ITN_W:0])
);

assign rem_sum_dp[4][(ITN_W + 2)-1:0] = {quo_dig[3][0] ? rem_sum_minus_d_dp : quo_dig[3][1] ? rem_sum_plus_d_dp : rem_sum_zero_dp, 1'b0};
assign rem_carry_dp[4][(ITN_W + 2)-1:0] = {quo_dig[3][0] ? rem_carry_minus_d_dp : quo_dig[3][1] ? rem_carry_plus_d_dp : rem_carry_zero_dp, 1'b0};

// ================================================================================================================================================
// On the Fly Conversion (OFC/OTFC).
// ================================================================================================================================================

assign quo_iter_nxt[0] = quo_dig[0][0] ? {quo_iter_q[WIDTH-2:0], 1'b1} : quo_dig[0][1] ? {quo_m1_iter_q[WIDTH-2:0], 1'b1} : 
{quo_iter_q[WIDTH-2:0], 1'b0};
assign quo_m1_iter_nxt[0] = quo_dig[0][0] ? {quo_iter_q[WIDTH-2:0], 1'b0} : quo_dig[0][1] ? {quo_m1_iter_q[WIDTH-2:0], 1'b0} : 
{quo_m1_iter_q[WIDTH-2:0], 1'b1};

generate
for(i = 1; i < 4; i++) begin: g_quo_ofc
	assign quo_iter_nxt[i] = quo_dig[i][0] ? {quo_iter_nxt[i-1][WIDTH-2:0], 1'b1} : quo_dig[i][1] ? {quo_m1_iter_nxt[i-1][WIDTH-2:0], 1'b1} : 
	{quo_iter_nxt[i-1][WIDTH-2:0], 1'b0};

	assign quo_m1_iter_nxt[i] = quo_dig[i][0] ? {quo_iter_nxt[i-1][WIDTH-2:0], 1'b0} : quo_dig[i][1] ? {quo_m1_iter_nxt[i-1][WIDTH-2:0], 1'b0} : 
	{quo_m1_iter_nxt[i-1][WIDTH-2:0], 1'b1};
end
endgenerate


assign quo_iter_en 		= fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT] | fsm_q[FSM_POST_0_BIT];
assign quo_m1_iter_en 	= fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT] | fsm_q[FSM_POST_0_BIT];
// When "divisor_is_zero", the final Q should be ALL'1s
assign quo_iter_d = fsm_q[FSM_PRE_1_BIT] ? {(WIDTH){divisor_is_zero}} : fsm_q[FSM_POST_0_BIT] ? (quo_sign_q ? inverter_res[0] : quo_iter_q) : quo_iter_nxt[3];
assign quo_m1_iter_d = fsm_q[FSM_PRE_1_BIT] ? {(WIDTH){1'b0}} : fsm_q[FSM_POST_0_BIT] ? (quo_sign_q ? inverter_res[1] : quo_m1_iter_q) : quo_m1_iter_nxt[3];
always_ff @(posedge clk) begin
	if(quo_iter_en)
		quo_iter_q <= quo_iter_d;
	if(quo_m1_iter_en)
		quo_m1_iter_q <= quo_m1_iter_d;
end

// ================================================================================================================================================
// Post Process 0, get the non_redundant form of REMAINDER
// ================================================================================================================================================
// rem_sum_q/rem_carry_q has already been multiplied by 2, so their [0] must be 0.
// If(rem <= 0), 
// rem = (-rem_sum) + (-rem_carry) = ~rem_sum + ~rem_carry + 2'b10;
// If(rem <= 0), 
// rem_plus_d = ~rem_sum + ~rem_carry + ~normalized_d + 2'b11;
// assign nr_rem_nxt = 
//   ({(ITN_W + 2){rem_sign_q}} ^ rem_sum_q)
// + ({(ITN_W + 2){rem_sign_q}} ^ rem_carry_q)
// + {{(ITN_W){1'b0}}, rem_sign_q, 1'b0};

assign nr_rem_nxt = 
  ({(ITN_W + 1){rem_sign_q}} ^ rem_sum_q	[1 +: (ITN_W + 1)])
+ ({(ITN_W + 1){rem_sign_q}} ^ rem_carry_q	[1 +: (ITN_W + 1)])
+ {{(ITN_W - 2){1'b0}}, rem_sign_q, 1'b0};
// TODO: Maybe "(ITN_W+1)-bit" FA is enough here ?
assign nr_rem_plus_d_nxt = 
  ({(ITN_W + 2){rem_sign_q}} ^ {1'b0, rem_sum_q		[1 +: (ITN_W + 1)]})
+ ({(ITN_W + 2){rem_sign_q}} ^ {1'b0, rem_carry_q	[1 +: (ITN_W + 1)]})
+ ({(ITN_W + 2){rem_sign_q}} ^ {2'b0, divisor_abs_q	[WIDTH-1:0], 3'b0})
+ {{(ITN_W){1'b0}}, rem_sign_q, rem_sign_q};

// ================================================================================================================================================
// Post Process 1, do r_shift to get "final_rem"
// ================================================================================================================================================
assign nr_rem 			= dividend_abs_q;
assign nr_rem_plus_d 	= divisor_abs_q;
assign nr_rem_is_zero 	= ~(|nr_rem);
// Let's assume:
// quo/quo_pre is the ABS value.
// If (rem >= 0), 
// need_corr = 0 <-> "rem_pre" belongs to [ 0, +D), quo = quo_pre - 0, rem = (rem_pre + 0) >> divisor_lzc;
// need_corr = 1 <-> "rem_pre" belongs to (-D,  0), quo = quo_pre - 1, rem = (rem_pre + D) >> divisor_lzc;
// If (rem <= 0), 
// need_corr = 0 <-> "rem_pre" belongs to (-D,  0], quo = quo_pre - 0, rem = (rem_pre - 0) >> divisor_lzc;
// need_corr = 1 <-> "rem_pre" belongs to ( 0, +D), quo = quo_pre - 1, rem = (rem_pre - D) >> divisor_lzc;
assign need_corr = ~divisor_is_zero & (rem_sign_q ? (~nr_rem[WIDTH] & ~nr_rem_is_zero) : nr_rem[WIDTH]);
assign pre_shifted_rem = need_corr ? nr_rem_plus_d : nr_rem;
assign final_rem = post_r_shift_res_s5;
assign final_quo = need_corr ? quo_m1_iter_q : quo_iter_q;

// ================================================================================================================================================
// Global R_SHIFT. (If the timing is bad maybe you should use seperate r_shifter)
// ================================================================================================================================================
// PRE_PROCESS_1: r_shift the dividend for "dividend_too_small/divisor_is_zero".
// POST_PROCESS_1: If "dividend_too_small_q/divisor_is_zero", we should not do any r_shift. Because we have already put dividend into the correct position
// in PRE_PROCESS_1.
assign post_r_shift_num = fsm_q[FSM_PRE_1_BIT] ? dividend_lzc_q : (dividend_too_small_q | divisor_is_zero) ? {(LZC_WIDTH){1'b0}} : divisor_lzc_q;
assign post_r_shift_data_in = fsm_q[FSM_PRE_1_BIT] ? dividend_abs_q[WIDTH-1:0] : pre_shifted_rem[WIDTH-1:0];
assign post_r_shift_extend_msb = fsm_q[FSM_POST_1_BIT] & rem_sign_q & pre_shifted_rem[WIDTH];

assign post_r_shift_res_s0 = post_r_shift_num[0] ? {{(1){post_r_shift_extend_msb}}, post_r_shift_data_in[WIDTH-1:1]} : post_r_shift_data_in;
assign post_r_shift_res_s1 = post_r_shift_num[1] ? {{(2){post_r_shift_extend_msb}}, post_r_shift_res_s0	[WIDTH-1:2]} : post_r_shift_res_s0;
assign post_r_shift_res_s2 = post_r_shift_num[2] ? {{(4){post_r_shift_extend_msb}}, post_r_shift_res_s1 [WIDTH-1:4]} : post_r_shift_res_s1;
assign post_r_shift_res_s3 = post_r_shift_num[3] ? {{(8){post_r_shift_extend_msb}}, post_r_shift_res_s2 [WIDTH-1:8]} : post_r_shift_res_s2;

generate
if(WIDTH == 32) begin
	assign post_r_shift_res_s4 = post_r_shift_num[4] ? {{(16){post_r_shift_extend_msb}}, post_r_shift_res_s3[WIDTH-1:16]} : post_r_shift_res_s3;
	assign post_r_shift_res_s5 = post_r_shift_res_s4;
end
else if(WIDTH == 64) begin
	assign post_r_shift_res_s4 = post_r_shift_num[4] ? {{(16){post_r_shift_extend_msb}}, post_r_shift_res_s3[WIDTH-1:16]} : post_r_shift_res_s3;
	assign post_r_shift_res_s5 = post_r_shift_num[5] ? {{(32){post_r_shift_extend_msb}}, post_r_shift_res_s4[WIDTH-1:32]} : post_r_shift_res_s4;
end
else begin
	// WIDTH = 16
	assign post_r_shift_res_s4 = post_r_shift_res_s3;
	assign post_r_shift_res_s5 = post_r_shift_res_s4;
end
endgenerate

// ================================================================================================================================================
// Output
// ================================================================================================================================================
assign div_start_ready_o 	= fsm_q[FSM_IDLE_ABS_BIT];
assign div_finish_valid_o 	= fsm_q[FSM_POST_1_BIT];
assign divisor_is_zero_o 	= divisor_is_zero;
assign quotient_o 			= final_quo;
assign remainder_o 			= final_rem;

endmodule

