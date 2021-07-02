// ========================================================================================================
// Copyright (C) 2021, Yifei He. All Rights Reserved.
// This file is licensed under BSD 3-Clause License.
// 
// Author's E-mail: hyf_sysu@qq.com
// 
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
// File Name	: 	int_div_radix_16_v2.sv
// Author		: 	Yifei He
// Created On	: 	2021/06/28
// --------------------------------------------------------------------------------------------------------
// Description	:
// A Radix-16 algorithm, composed of 4 overlapped "MAGIC" Radix-2 SRT Iteration.
// But this "MAGIC" algorithm can't get the precise remainder. So you might need another MAC operation (REM = DIVIDEND - Q * DIVISOR)
// to get the correct remainder.
// --------------------------------------------------------------------------------------------------------

// include some definitions here

module int_div_radix_16_v2 #(
	// put some parameters here, which can be changed by other modules
	// ATTENTION: WIDTH >= 9
	parameter WIDTH = 64
)(
	input logic div_start_valid_i,
	output logic div_start_ready_o,
	input logic flush_i,
	input logic signed_op_i,
	input logic [WIDTH-1:0] dividend_i,
	input logic [WIDTH-1:0] divisor_i,

	output logic div_finish_valid_o,
	input logic div_finish_ready_i,
	output logic [WIDTH-1:0] quotient_o,
	// Can we get precise remainder ?
	output logic divisor_is_zero_o,

	input logic clk,
	input logic rst_n
);

// --------------------------------------------------------------------------------------------------------
// definitions begin



// definitions end
// --------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------
// (local) parameters begin

// TODO:
// If the timing of the input signals is good enough, you can do "Abs Calculation/(clz + left_shift)" in FSM_IDLE, and then 
// do (lzc + left_shift) in FSM_CLZ (if dividend_i or divisor_i is negative), so you can save 1 cycle.
localparam FSM_ABS_CLZ 	= 0;
localparam FSM_CLZ		= 1;
localparam FSM_STEP 	= 2;
localparam FSM_CORR 	= 3;
localparam FSM_OUT		= 4;

localparam DIV_FSM_WIDTH = 5;

localparam [DIV_FSM_WIDTH-1:0] DIV_ST_IDLE 		= 5'b0_0000;
localparam [DIV_FSM_WIDTH-1:0] DIV_ST_ABS_CLZ 	= 5'b0_0001;
localparam [DIV_FSM_WIDTH-1:0] DIV_ST_CLZ 		= 5'b0_0010;
localparam [DIV_FSM_WIDTH-1:0] DIV_ST_STEP 		= 5'b0_0100;
localparam [DIV_FSM_WIDTH-1:0] DIV_ST_CORR 		= 5'b0_1000;
localparam [DIV_FSM_WIDTH-1:0] DIV_ST_OUT 		= 5'b1_0000;

// How many bits do we need to express the Leading Zero Count of the data ?
localparam LZC_WIDTH = $clog2(WIDTH);


// (local) parameters end
// --------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------
// functions begin



// functions end
// --------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------
// signals begin

genvar i;

logic div_start_handshake;
logic div_finish_handshake;
logic [DIV_FSM_WIDTH-1:0] fsm_reg;
logic [DIV_FSM_WIDTH-1:0] nxt_fsm_reg;
logic [WIDTH-1:0] divisor;
logic quotient_sign_q;
logic quotient_sign_d;
logic sign_reg;

logic iters_required_en;
logic [LZC_WIDTH-1:0] iters_required;
logic [LZC_WIDTH-1:0] nxt_iters_required;
logic [LZC_WIDTH-1:0] iters_required_m1;

logic [(WIDTH + 2)-1:0] rem_sum;
logic [(WIDTH + 2)-1:0] rem_carry;
logic final_rem_negative;
logic [WIDTH-1:0] quotient;
logic [WIDTH-1:0] quotient_m1;
logic [2-1:0] n_prev_quot_dig;
logic [2-1:0] prev_quot_dig;

logic special_case;
logic divisor_is_zero_en;
logic divisor_is_zero_reg;
logic dividend_too_small_en;
logic dividend_too_small_reg;

logic [(WIDTH + 2)-1:0] nxt_remainder;
logic [WIDTH-1:0] nxt_divisor;
logic [(LZC_WIDTH + 1)-1:0] lzc_remainder;
logic [LZC_WIDTH-1:0] lzc_diff;
logic [(LZC_WIDTH + 1)-1:0] lzc_divisor;
logic [(LZC_WIDTH + 1)-1:0] lzc_remainder_divisor_delta;
logic remainder_wr_en;
logic rem_carry_wr_en;
logic divisor_wr_en;
logic [(WIDTH + 2)-1:0] new_remainder;
logic [WIDTH-1:0] new_divisor;
logic divisor_eq_zero;
logic divisor_gt_remainder;
logic neg_remainder;

logic [WIDTH-1:0] negated_remainder;
logic neg_divisor;
logic [WIDTH-1:0] negated_divisor;
logic quot_enable;
logic [WIDTH-1:0] remainder_norm;
logic [WIDTH-1:0] divisor_norm;

logic final_iter;
logic [(WIDTH + 2)-1:0] new_rem_sum;
logic [(WIDTH + 2)-1:0] nxt_rem_carry;
logic [(WIDTH + 2)-1:0] new_rem_carry;
logic [(WIDTH + 2)-1:0] rem_cpa;
logic [WIDTH-1:0] n_quotient_step;
logic [WIDTH-1:0] n_quotient_m1_step;
logic skip_corr;
logic [WIDTH-1:0] final_quotient;
logic nxt_final_rem_negative;
logic final_rem_negative_en;
logic [WIDTH-1:0] nxt_quotient;
logic [WIDTH-1:0] nxt_quotient_m1;
logic [WIDTH-1:0] n_quotient [4-1:0];
logic [WIDTH-1:0] n_quotient_m1 [4-1:0];

logic [11-1:0] rem_sum_zero [4-1:0];
logic [11-1:0] rem_carry_zero [4-1:0];
logic [11-1:0] rem_sum_minus_d [4-1:0];
logic [11-1:0] rem_carry_minus_d [4-1:0];
logic [11-1:0] rem_sum_plus_d [4-1:0];
logic [11-1:0] rem_carry_plus_d [4-1:0];

logic [2-1:0] quot_dig_zero [4-1:0];
logic [2-1:0] quot_dig_minus_d [4-1:0];
logic [2-1:0] quot_dig_plus_d [4-1:0];
logic [2-1:0] quot_dig [5-1:0];

logic [11-1:0] rem_sum_cp [5-1:0];
logic [11-1:0] rem_carry_cp [5-1:0];

logic [(WIDTH - 1)-1:0] mux_divisor [3-1:0];
logic [(WIDTH + 2)-1:0] rem_sum_dp [5-1:0];
logic [(WIDTH + 2)-1:0] rem_carry_dp [5-1:0];
logic [(WIDTH + 1)-1:0] rem_sum_zero_dp;
logic [(WIDTH + 1)-1:0] rem_carry_zero_dp;
logic [(WIDTH + 1)-1:0] rem_sum_minus_d_dp;
logic [(WIDTH + 1)-1:0] rem_carry_minus_d_dp;
logic [(WIDTH + 1)-1:0] rem_sum_plus_d_dp;
logic [(WIDTH + 1)-1:0] rem_carry_plus_d_dp;



// signals end
// --------------------------------------------------------------------------------------------------------

assign div_start_handshake = div_start_valid_i & div_start_ready_o;
assign div_finish_handshake = div_finish_valid_o & div_finish_ready_i;

always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		fsm_reg <= DIV_ST_IDLE;
	else
		fsm_reg <= nxt_fsm_reg;
end

always_comb begin
	case(fsm_reg)
		DIV_ST_IDLE:
			nxt_fsm_reg = div_start_valid_i ? DIV_ST_ABS_CLZ : DIV_ST_IDLE;
		DIV_ST_ABS_CLZ:
			nxt_fsm_reg = (neg_divisor | neg_remainder) ? DIV_ST_CLZ : special_case ? DIV_ST_OUT : DIV_ST_STEP;
		DIV_ST_CLZ:
			nxt_fsm_reg = special_case ? DIV_ST_OUT : DIV_ST_STEP;
		DIV_ST_STEP:
			nxt_fsm_reg = final_iter ? (skip_corr ? DIV_ST_OUT : DIV_ST_CORR) : DIV_ST_STEP;
		DIV_ST_CORR:
			nxt_fsm_reg = DIV_ST_OUT;
		DIV_ST_OUT:
			nxt_fsm_reg = div_finish_ready_i ? DIV_ST_IDLE : DIV_ST_OUT;
		default:
			nxt_fsm_reg = DIV_ST_IDLE;
	endcase

	if(flush_i)
		// flush has the highest priority
		nxt_fsm_reg = DIV_ST_IDLE;
end

// 1. We receive a new div operation.
// 2. In FSM_ABS_CLZ, we find that remainder is neg -> so we need to get its abs value.
// 3. In FSM_CLZ, we need to get the normalized value of remainder.
// 4. In FSM_STEP, get the updated value after srt_iteration.
assign remainder_wr_en = 
  div_start_handshake
| (fsm_reg[FSM_ABS_CLZ] & (~neg_divisor | neg_remainder))
| fsm_reg[FSM_CLZ]
| fsm_reg[FSM_STEP];

assign nxt_remainder = 
  ({(WIDTH + 2){neg_remainder}} & {2'b00, negated_remainder})
| ({(WIDTH + 2){(fsm_reg[FSM_ABS_CLZ] & ~neg_remainder) | fsm_reg[FSM_CLZ]}} & {2'b00, remainder_norm})
| ({(WIDTH + 2){fsm_reg[FSM_STEP]}} & new_rem_sum);
assign new_remainder = (fsm_reg == DIV_ST_IDLE) ? {2'b00, dividend_i} : nxt_remainder;
always_ff @(posedge clk)
	if(remainder_wr_en)
		rem_sum <= new_remainder;

// 1. We receive a new div operation.
// 2. In FSM_ABS_CLZ, we find that divisor is neg -> so we need to get its abs value.
// 3. In FSM_CLZ, we need to get the normalized value of divisor.
assign divisor_wr_en = 
  div_start_handshake
| (fsm_reg[FSM_ABS_CLZ] & (neg_divisor | ~neg_remainder))
| fsm_reg[FSM_CLZ];
assign nxt_divisor = neg_divisor ? negated_divisor : divisor_norm;

assign new_divisor = (fsm_reg == DIV_ST_IDLE) ? divisor_i : nxt_divisor;
always_ff @(posedge clk)
	if(divisor_wr_en)
		divisor <= new_divisor;

always_ff @(posedge clk)
	if(div_start_handshake)
		sign_reg <= signed_op_i;
assign quotient_sign_d = sign_reg & (rem_sum[WIDTH-1] ^ divisor[WIDTH-1]);

always_ff @(posedge clk)
	if(fsm_reg[FSM_ABS_CLZ])
		quotient_sign_q <= quotient_sign_d;

assign negated_remainder = -rem_sum[WIDTH-1:0];
assign neg_remainder = fsm_reg[FSM_ABS_CLZ] & sign_reg & rem_sum[WIDTH-1];

assign negated_divisor = -divisor[WIDTH-1:0];
assign neg_divisor = fsm_reg[FSM_ABS_CLZ] & sign_reg & divisor[WIDTH-1];

// --------------------------------------------------------------------------------------------------------
// Count Leading Zeros for Normalization
// --------------------------------------------------------------------------------------------------------
// If you have better method to find the number of the leading zeros, just use it.
// Use the open-source LZC from ETH Zurich, University of Bologna.
lzc #(
	.WIDTH(WIDTH),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_remainder (
	.in_i(rem_sum[WIDTH-1:0]),
	.cnt_o(lzc_remainder[LZC_WIDTH-1:0]),
	.empty_o(lzc_remainder[LZC_WIDTH])
);

lzc #(
	.WIDTH(WIDTH),
	// 0: trailing zero.
	// 1: leading zero.
	.MODE(1'b1)
) u_lzc_divisor (
	.in_i(divisor[WIDTH-1:0]),
	.cnt_o(lzc_divisor[LZC_WIDTH-1:0]),
	.empty_o(lzc_divisor[LZC_WIDTH])
);

assign lzc_remainder_divisor_delta = lzc_divisor - lzc_remainder;
assign {divisor_gt_remainder, lzc_diff} = lzc_remainder_divisor_delta;
assign divisor_eq_zero = lzc_divisor[LZC_WIDTH];

// The special situations:
// 1. The exponent of divisor is greater than that of the remainder -> quotient = 0.
// 2. divisor = 0 -> quotient = {(WIDTH){1'b1}}
assign special_case = fsm_reg[FSM_OUT] ? (dividend_too_small_reg | divisor_is_zero_reg) : (divisor_gt_remainder | divisor_eq_zero);
assign dividend_too_small_en = (fsm_reg[FSM_ABS_CLZ] & ~neg_remainder & ~neg_divisor) | fsm_reg[FSM_CLZ];
always_ff @(posedge clk)
	if(dividend_too_small_en)
		dividend_too_small_reg <= divisor_gt_remainder;

assign divisor_is_zero_en = (fsm_reg[FSM_ABS_CLZ] & ~neg_remainder & ~neg_divisor) | fsm_reg[FSM_CLZ];
always_ff @(posedge clk)
	if(divisor_is_zero_en)
		divisor_is_zero_reg <= divisor_eq_zero;

assign remainder_norm = rem_sum[WIDTH-1:0] << lzc_remainder[LZC_WIDTH-1:0];
assign divisor_norm = divisor[WIDTH-1:0] << lzc_divisor[LZC_WIDTH-1:0];

assign iters_required_m1 = iters_required[LZC_WIDTH-1:0] - {{(LZC_WIDTH - 3){1'b0}}, 3'd4};
assign nxt_iters_required = (fsm_reg[FSM_ABS_CLZ] | fsm_reg[FSM_CLZ]) ? lzc_diff : iters_required_m1;
assign final_iter = ~|(iters_required[LZC_WIDTH-1:2]);
assign iters_required_en = fsm_reg[FSM_ABS_CLZ] | fsm_reg[FSM_CLZ] | fsm_reg[FSM_STEP];
always_ff @(posedge clk)
	if(iters_required_en)
		iters_required <= nxt_iters_required;


assign rem_carry_wr_en = fsm_reg[FSM_ABS_CLZ] | fsm_reg[FSM_CLZ] | fsm_reg[FSM_STEP];
assign nxt_rem_carry = (fsm_reg[FSM_ABS_CLZ] | fsm_reg[FSM_CLZ]) ? {(WIDTH + 2){1'b0}} : new_rem_carry;
always_ff @(posedge clk)
	if(rem_carry_wr_en)
		rem_carry <= nxt_rem_carry;

assign new_rem_carry = ~|(iters_required[LZC_WIDTH-1:2]) ? (iters_required[0] ? rem_carry_dp[4] : rem_carry_dp[3]) : rem_carry_dp[4];
assign new_rem_sum = ~|(iters_required[LZC_WIDTH-1:2]) ? (iters_required[0] ? rem_sum_dp[4] : rem_sum_dp[3]) : rem_sum_dp[4];

// --------------------------------------------------------------------------------------------------------
// Let's do SRT Iteration !!!
// --------------------------------------------------------------------------------------------------------

assign rem_sum_cp[0] = rem_sum[WIDTH+1 -: 11];
assign rem_carry_cp[0] = rem_carry[WIDTH+1 -: 11];
assign quot_dig[0] = prev_quot_dig;

generate
for(i = 0; i < 4; i = i + 1) begin: g_srt_control_path
	radix_2_srt_csa #(
		// 11, 9, 7, 5
		.WIDTH(11 - (2 * i))
	) u_radix_2_srt_csa (
		.csa_plus_i				(divisor				[WIDTH-2:(WIDTH - 9 + (2 * i))]),
		.csa_minus_i			(divisor				[WIDTH-2:(WIDTH - 9 + (2 * i))]),
		.rem_sum_i				(rem_sum_cp[i]			[9:(2 * i)]),
		.rem_carry_i			(rem_carry_cp[i]		[9:(2 * i)]),

		.rem_sum_zero_o			(rem_sum_zero[i]		[10:((2 * i) + 1)]),
		.rem_carry_zero_o		(rem_carry_zero[i]		[10:((2 * i) + 1)]),
		.rem_sum_minus_d_o		(rem_sum_minus_d[i]		[10:((2 * i) + 1)]),
		.rem_carry_minus_d_o	(rem_carry_minus_d[i]	[10:((2 * i) + 1)]),
		.rem_sum_plus_d_o		(rem_sum_plus_d[i]		[10:((2 * i) + 1)]),
		.rem_carry_plus_d_o		(rem_carry_plus_d[i]	[10:((2 * i) + 1)])
	);

	assign rem_sum_zero			[i][(2 * i):0] = {((2 * i) + 1){1'b0}};
	assign rem_carry_zero		[i][(2 * i):0] = {((2 * i) + 1){1'b0}};
	assign rem_sum_minus_d		[i][(2 * i):0] = {((2 * i) + 1){1'b0}};
	assign rem_carry_minus_d	[i][(2 * i):0] = {((2 * i) + 1){1'b0}};
	assign rem_sum_plus_d		[i][(2 * i):0] = {((2 * i) + 1){1'b0}};
	assign rem_carry_plus_d		[i][(2 * i):0] = {((2 * i) + 1){1'b0}};

	radix_2_srt_qds u_quot_zero (
		.rem_sum_msb_i(rem_sum_zero[i][10:8]),
		.rem_carry_msb_i(rem_carry_zero[i][10:8]),
		.quot_dig_o(quot_dig_zero[i])
	);
	radix_2_srt_qds u_quot_plus_d (
		.rem_sum_msb_i(rem_sum_plus_d[i][10:8]),
		.rem_carry_msb_i(rem_carry_plus_d[i][10:8]),
		.quot_dig_o(quot_dig_plus_d[i])
	);
	radix_2_srt_qds u_quot_minus_d (
		.rem_sum_msb_i(rem_sum_minus_d[i][10:8]),
		.rem_carry_msb_i(rem_carry_minus_d[i][10:8]),
		.quot_dig_o(quot_dig_minus_d[i])
	);

	assign rem_sum_cp[i+1] = quot_dig[i][0] ? rem_sum_minus_d[i] : quot_dig[i][1] ? rem_sum_plus_d[i] : rem_sum_zero[i];
	assign rem_carry_cp[i+1] = quot_dig[i][0] ? rem_carry_minus_d[i] : quot_dig[i][1] ? rem_carry_plus_d[i] : rem_carry_zero[i];
	assign quot_dig[i+1] = quot_dig[i][0] ? quot_dig_minus_d[i] : quot_dig[i][1] ? quot_dig_plus_d[i] : quot_dig_zero[i];
end
endgenerate

assign n_prev_quot_dig = (fsm_reg[FSM_ABS_CLZ] | fsm_reg[FSM_CLZ]) ? 2'b01 : quot_dig[4];
always_ff @(posedge clk)
	prev_quot_dig <= n_prev_quot_dig;


assign rem_sum_dp[0] = rem_sum;
assign rem_carry_dp[0] = rem_carry;
generate
for(i = 0; i < 3; i = i + 1) begin: g_srt_data_path
	assign mux_divisor[i][(WIDTH-5) + i:0] = quot_dig[i][0] ? ~divisor[(WIDTH-5) + i:0] : quot_dig[i][1] ? divisor[(WIDTH-5) + i:0] : {((WIDTH-4) + i){1'b0}};

	if(i < 3) begin: g_srt_data_path_set_unused_to_zero
		assign mux_divisor[i][(WIDTH-2):(WIDTH-4)+i] = {(3 - i){1'b0}};
	end

	assign rem_sum_dp[i+1][(WIDTH-4)+i:0] = {rem_sum_dp[i][(WIDTH-5)+i:0] ^ rem_carry_dp[i][(WIDTH-5)+i:0] ^ mux_divisor[i][(WIDTH-5)+i:0], 1'b1};

	assign rem_carry_dp[i+1][(WIDTH-3)+i:0] = {
		  (rem_sum_dp[i][(WIDTH-5)+i:0] & rem_carry_dp[i][(WIDTH-5)+i:0])
		| (rem_sum_dp[i][(WIDTH-5)+i:0] & mux_divisor[i][(WIDTH-5)+i:0])
		| (rem_carry_dp[i][(WIDTH-5)+i:0] & mux_divisor[i][(WIDTH-5)+i:0]),
		quot_dig[i][0],
		1'b0
	};

	assign rem_sum_dp[i+1][(WIDTH+1):(WIDTH-3)+i] = rem_sum_cp[i+1][10:6+i];
	assign rem_carry_dp[i+1][(WIDTH+1):(WIDTH-2)+i] = rem_carry_cp[i+1][10:7+i];
end
endgenerate

radix_2_srt_csa #(
	.WIDTH(WIDTH + 2)
) u_radix_2_srt_csa_full_width (
	.csa_plus_i				(divisor				[WIDTH-2:0]),
	.csa_minus_i			(divisor				[WIDTH-2:0]),
	.rem_sum_i				(rem_sum_dp[3]			[WIDTH:0]),
	.rem_carry_i			(rem_carry_dp[3]		[WIDTH:0]),

	.rem_sum_zero_o			(rem_sum_zero_dp		[WIDTH:0]),
	.rem_carry_zero_o		(rem_carry_zero_dp		[WIDTH:0]),
	.rem_sum_minus_d_o		(rem_sum_minus_d_dp		[WIDTH:0]),
	.rem_carry_minus_d_o	(rem_carry_minus_d_dp	[WIDTH:0]),
	.rem_sum_plus_d_o		(rem_sum_plus_d_dp		[WIDTH:0]),
	.rem_carry_plus_d_o		(rem_carry_plus_d_dp	[WIDTH:0])
);

assign rem_sum_dp[4][(WIDTH + 2)-1:0] = {quot_dig[3][0] ? rem_sum_minus_d_dp : quot_dig[3][1] ? rem_sum_plus_d_dp : rem_sum_zero_dp, 1'b0};
assign rem_carry_dp[4][(WIDTH + 2)-1:0] = {quot_dig[3][0] ? rem_carry_minus_d_dp : quot_dig[3][1] ? rem_carry_plus_d_dp : rem_carry_zero_dp, 1'b0};

assign rem_cpa = ~|(iters_required[LZC_WIDTH-1:1]) ? (iters_required[0] ? (rem_sum_dp[2] + rem_carry_dp[2]) : (rem_sum_dp[1] + rem_carry_dp[1])) : (rem_sum + rem_carry);

assign skip_corr = ~|(iters_required[LZC_WIDTH-1:1]);

assign nxt_final_rem_negative = rem_cpa[WIDTH+1];
assign final_rem_negative_en = fsm_reg[FSM_STEP] | fsm_reg[FSM_CORR];
always_ff @(posedge clk)
	if(final_rem_negative_en)
		final_rem_negative <= nxt_final_rem_negative;

// If we detect special_case before, then we have already set "quotient" as the correct value, 
assign final_quotient = special_case ? quotient : (final_rem_negative ? quotient_m1 : quotient);

assign n_quotient_step = ~|(iters_required[LZC_WIDTH-1:2]) ? (
	iters_required[1] ? (iters_required[0] ? n_quotient[3] : n_quotient[2]) : (iters_required[0] ? n_quotient[1] : n_quotient[0])
) : n_quotient[3];

assign n_quotient_m1_step = ~|(iters_required[LZC_WIDTH-1:2]) ? (
	iters_required[1] ? (iters_required[0] ? n_quotient_m1[3] : n_quotient_m1[2]) : (iters_required[0] ? n_quotient_m1[1] : n_quotient_m1[0])
) : n_quotient_m1[3];

assign n_quotient[0] = quot_dig[0][0] ? {quotient[WIDTH-2:0], 1'b1} : (quot_dig[0][1] ? {quotient_m1[WIDTH-2:0], 1'b1} : {quotient[WIDTH-2:0], 1'b0});
assign n_quotient_m1[0] = quot_dig[0][0] ? {quotient[WIDTH-2:0], 1'b0} : (quot_dig[0][1] ? {quotient_m1[WIDTH-2:0], 1'b0} : {quotient_m1[WIDTH-2:0], 1'b1});

generate
for(i = 1; i < 4; i = i + 1)
begin: g_n_quotient

	assign n_quotient[i] = quot_dig[i][0] ? {n_quotient[i-1][WIDTH-2:0], 1'b1} : 
	(quot_dig[i][1] ? {n_quotient_m1[i-1][WIDTH-2:0], 1'b1} : {n_quotient[i-1][WIDTH-2:0], 1'b0});
	
	assign n_quotient_m1[i] = quot_dig[i][0] ? {n_quotient[i-1][WIDTH-2:0], 1'b0} : 
	(quot_dig[i][1] ? {n_quotient_m1[i-1][WIDTH-2:0], 1'b0} : {n_quotient_m1[i-1][WIDTH-2:0], 1'b1});
end
endgenerate

// 1. divisor_eq_zero = 1: quotient should be {(WIDTH){1'b1}}.
assign nxt_quotient = fsm_reg[FSM_STEP] ? n_quotient_step : (divisor_eq_zero ? {(WIDTH){1'b1}} : {(WIDTH){1'b0}});
assign nxt_quotient_m1 = fsm_reg[FSM_STEP] ? n_quotient_m1_step : {(WIDTH){1'b0}};
assign quot_enable = fsm_reg[FSM_ABS_CLZ] | fsm_reg[FSM_CLZ] | fsm_reg[FSM_STEP];
always_ff @(posedge clk) begin
	if(quot_enable) begin
		quotient <= nxt_quotient;
		quotient_m1 <= nxt_quotient_m1;
	end
end

assign div_start_ready_o = (fsm_reg == DIV_ST_IDLE);
assign div_finish_valid_o = fsm_reg[FSM_OUT];
assign quotient_o = (quotient_sign_q & ~special_case) ? -final_quotient : final_quotient;
assign divisor_is_zero_o = divisor_is_zero_reg;

endmodule
