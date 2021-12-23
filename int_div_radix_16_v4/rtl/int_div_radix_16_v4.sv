// ========================================================================================================
// File Name			: int_div_radix_16_v4.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-09-21 21:04:30
// Last Modified Time   : 2021-12-03 20:54:20
// ========================================================================================================
// Description	:
// A Radix-16 SRT Integer Divider, by using 2 overlapped Radix-4.
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

module int_div_radix_16_v4 #(
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
// 1-bit in front of the MSB of rem -> Sign.
// 2-bit after the LSB of rem -> Used in Retiming Design.
// 3-bit after the LSB of rem -> Used for Align operation.
localparam ITN_W = 1 + WIDTH + 2 + 3;

localparam QUO_ONEHOT_WIDTH = 5;
localparam QUO_NEG_2 = 0;
localparam QUO_NEG_1 = 1;
localparam QUO_ZERO  = 2;
localparam QUO_POS_1 = 3;
localparam QUO_POS_2 = 4;
localparam QUO_ONEHOT_NEG_2 = 5'b0_0001;
localparam QUO_ONEHOT_NEG_1 = 5'b0_0010;
localparam QUO_ONEHOT_ZERO  = 5'b0_0100;
localparam QUO_ONEHOT_POS_1 = 5'b0_1000;
localparam QUO_ONEHOT_POS_2 = 5'b1_0000;

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
// The delay of this signal is "delay(u_lzc) + delay(LZC_WIDTH-bit full adder)" -> slow
logic [(LZC_WIDTH + 1)-1:0] lzc_diff_slow;
// The delay of this signal is "delay(LZC_WIDTH-bit full adder)" -> fast
logic [(LZC_WIDTH + 1)-1:0] lzc_diff_fast;
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

logic no_iter_needed_en;
logic no_iter_needed_d;
logic no_iter_needed_q;
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
logic [ITN_W-1:0] nr_rem_nxt;
logic [ITN_W-1:0] nr_rem_plus_d_nxt;
logic [(WIDTH+1)-1:0] nr_rem;
logic [(WIDTH+1)-1:0] nr_rem_plus_d;
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

logic [5-1:0] pre_m_pos_1;
logic [5-1:0] pre_m_pos_2;
logic [2-1:0] pre_cmp_res;
logic [5-1:0] pre_rem_trunc_1_4;
logic qds_para_neg_1_en;
logic [5-1:0] qds_para_neg_1_d;
logic [5-1:0] qds_para_neg_1_q;
logic qds_para_neg_0_en;
logic [3-1:0] qds_para_neg_0_d;
logic [3-1:0] qds_para_neg_0_q;
logic qds_para_pos_1_en;
logic [2-1:0] qds_para_pos_1_d;
logic [2-1:0] qds_para_pos_1_q;
logic qds_para_pos_2_en;
logic [5-1:0] qds_para_pos_2_d;
logic [5-1:0] qds_para_pos_2_q;
logic special_divisor_en;
logic special_divisor_d;
logic special_divisor_q;

logic [ITN_W-1:0] rem_sum_normal_init_value;
logic [ITN_W-1:0] rem_sum_init_value;
logic [ITN_W-1:0] rem_carry_init_value;
logic rem_sum_en;
logic [ITN_W-1:0] rem_sum_d;
logic [ITN_W-1:0] rem_sum_q;
logic rem_carry_en;
logic [ITN_W-1:0] rem_carry_d;
logic [ITN_W-1:0] rem_carry_q;
logic [ITN_W-1:0] rem_sum_nxt;
logic [ITN_W-1:0] rem_carry_nxt;

logic prev_quo_digit_en;
logic [QUO_ONEHOT_WIDTH-1:0] prev_quo_digit_d;
logic [QUO_ONEHOT_WIDTH-1:0] prev_quo_digit_q;
logic [QUO_ONEHOT_WIDTH-1:0] prev_quo_digit_init_value;
logic [QUO_ONEHOT_WIDTH-1:0] quo_digit_nxt;
logic quo_iter_en;
logic [WIDTH-1:0] quo_iter_d;
logic [WIDTH-1:0] quo_iter_q;
logic [WIDTH-1:0] quo_iter_nxt;
// m1 = minus_1
logic quo_m1_iter_en;
logic [WIDTH-1:0] quo_m1_iter_d;
logic [WIDTH-1:0] quo_m1_iter_q;
logic [WIDTH-1:0] quo_m1_iter_nxt;

logic [WIDTH-1:0] final_rem;
logic [WIDTH-1:0] final_quo;

// signals end
// ================================================================================================================================================

assign div_start_handshaked = div_start_valid_i & div_start_ready_o;
// ================================================================================================================================================
// FSM Ctrl Logic
// ================================================================================================================================================
always_comb begin
	unique case(fsm_q)
		FSM_IDLE_ABS:
			fsm_d = div_start_valid_i ? FSM_PRE_PROCESS_0 : FSM_IDLE_ABS;
		FSM_PRE_PROCESS_0:
			fsm_d = FSM_PRE_PROCESS_1;
		FSM_PRE_PROCESS_1:
			fsm_d = (dividend_too_small_q | divisor_is_zero | no_iter_needed_q) ? FSM_POST_PROCESS_0 : FSM_SRT_ITERATION;
		FSM_SRT_ITERATION:
			fsm_d = final_iter ? FSM_POST_PROCESS_0 : FSM_SRT_ITERATION;
		FSM_POST_PROCESS_0:
			fsm_d = FSM_POST_PROCESS_1;
		FSM_POST_PROCESS_1:
			fsm_d = div_finish_ready_i ? FSM_IDLE_ABS : FSM_POST_PROCESS_1;
		default:
			fsm_d = FSM_IDLE_ABS;
	endcase

	if(flush_i)
		// flush has the highest priority.
		fsm_d = FSM_IDLE_ABS;
end

always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		fsm_q <= FSM_IDLE_ABS;
	else
		fsm_q <= fsm_d;
end
// ================================================================================================================================================
// R_SHIFT
// ================================================================================================================================================
// PRE_PROCESS_1: r_shift the dividend for "dividend_too_small/divisor_is_zero".
// POST_PROCESS_1: If "dividend_too_small/divisor_is_zero", we should not do any r_shift. Because we have already put dividend into the correct position
// in PRE_PROCESS_1.
assign post_r_shift_num = fsm_q[FSM_PRE_1_BIT] ? dividend_lzc_q : ((dividend_too_small_q | divisor_is_zero) ? {(LZC_WIDTH){1'b0}} : divisor_lzc_q);
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
assign dividend_sign 	= signed_op_i & dividend_i[WIDTH-1];
assign divisor_sign 	= signed_op_i & divisor_i[WIDTH-1];
assign dividend_abs 	= dividend_sign ? inverter_res[0] : dividend_i;
assign divisor_abs 		= divisor_sign ? inverter_res[1] : divisor_i;

assign dividend_abs_en 	= div_start_handshaked | fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_POST_0_BIT];
assign divisor_abs_en  	= div_start_handshaked | fsm_q[FSM_PRE_0_BIT] | fsm_q[FSM_POST_0_BIT];
// In PRE_PROCESS_1, if we find "divisor_is_zero", we should force quo_sign = 0 -> We can get final_quo = {(WIDTH){1'b1}};
assign quo_sign_en = div_start_handshaked | (fsm_q[FSM_PRE_1_BIT] & divisor_is_zero);
assign rem_sign_en = div_start_handshaked;
assign quo_sign_d = fsm_q[FSM_IDLE_ABS_BIT] ? (dividend_sign ^ divisor_sign) : 1'b0;
assign rem_sign_d = dividend_sign;

assign dividend_abs_d = 
  ({(WIDTH + 1){fsm_q[FSM_IDLE_ABS_BIT]}} 	& {1'b0, dividend_abs})
| ({(WIDTH + 1){fsm_q[FSM_PRE_0_BIT]}} 		& {1'b0, normalized_dividend})
| ({(WIDTH + 1){fsm_q[FSM_POST_0_BIT]}} 	& nr_rem_nxt[5 +: (WIDTH + 1)]);
assign divisor_abs_d = 
  ({(WIDTH + 1){fsm_q[FSM_IDLE_ABS_BIT]}} 	& {1'b0, divisor_abs})
| ({(WIDTH + 1){fsm_q[FSM_PRE_0_BIT]}} 		& {1'b0, normalized_divisor})
| ({(WIDTH + 1){fsm_q[FSM_POST_0_BIT]}} 	& nr_rem_plus_d_nxt[5 +: (WIDTH + 1)]);

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
// Choose the parameters for CMP, according to the value of the normalized_d[(WIDTH - 2) -: 3]
// ================================================================================================================================================
assign qds_para_neg_1_en = fsm_q[FSM_PRE_1_BIT];
// For "normalized_d[(WIDTH - 2) -: 3]",
// 000: m[-1] = -13, -m[-1] = +13 = 00_1101 -> ext(-m[-1]) = 00_11010
// 001: m[-1] = -15, -m[-1] = +15 = 00_1111 -> ext(-m[-1]) = 00_11110
// 010: m[-1] = -16, -m[-1] = +16 = 01_0000 -> ext(-m[-1]) = 01_00000
// 011: m[-1] = -17, -m[-1] = +17 = 01_0001 -> ext(-m[-1]) = 01_00010
// 100: m[-1] = -19, -m[-1] = +19 = 01_0011 -> ext(-m[-1]) = 01_00110
// 101: m[-1] = -20, -m[-1] = +20 = 01_0100 -> ext(-m[-1]) = 01_01000
// 110: m[-1] = -22, -m[-1] = +22 = 01_0110 -> ext(-m[-1]) = 01_01100
// 111: m[-1] = -24, -m[-1] = +24 = 01_1000 -> ext(-m[-1]) = 01_10000
// We need to use 5-bit reg.
assign qds_para_neg_1_d = 
  ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b000}} & 5'b0_1101)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b001}} & 5'b0_1111)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b010}} & 5'b1_0000)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b011}} & 5'b1_0010)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b100}} & 5'b1_0011)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b101}} & 5'b1_0100)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b110}} & 5'b1_0110)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b111}} & 5'b1_1000);

assign qds_para_neg_0_en = fsm_q[FSM_PRE_1_BIT];
// For "normalized_d[(WIDTH - 2) -: 3]",
// 000: m[-0] = -4, -m[-0] = +4 = 000_0100
// 001: m[-0] = -6, -m[-0] = +6 = 000_0110
// 010: m[-0] = -6, -m[-0] = +6 = 000_0110
// 011: m[-0] = -6, -m[-0] = +6 = 000_0110
// 100: m[-0] = -6, -m[-0] = +6 = 000_0110
// 101: m[-0] = -8, -m[-0] = +8 = 000_1000
// 110: m[-0] = -8, -m[-0] = +8 = 000_1000
// 111: m[-0] = -8, -m[-0] = +8 = 000_1000
// We need to use 3-bit reg.
assign qds_para_neg_0_d = 
  ({(3){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b000}} & 3'b010)
| ({(3){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b001}} & 3'b011)
| ({(3){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b010}} & 3'b011)
| ({(3){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b011}} & 3'b011)
| ({(3){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b100}} & 3'b011)
| ({(3){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b101}} & 3'b100)
| ({(3){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b110}} & 3'b100)
| ({(3){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b111}} & 3'b100);

assign qds_para_pos_1_en = fsm_q[FSM_PRE_1_BIT];
// For "normalized_d[(WIDTH - 2) -: 3]",
// 000: m[+1] = +4, -m[+1] = -4 = 111_1100
// 001: m[+1] = +4, -m[+1] = -4 = 111_1100
// 010: m[+1] = +4, -m[+1] = -4 = 111_1100
// 011: m[+1] = +4, -m[+1] = -4 = 111_1100
// 100: m[+1] = +6, -m[+1] = -6 = 111_1010
// 101: m[+1] = +6, -m[+1] = -6 = 111_1010
// 110: m[+1] = +6, -m[+1] = -6 = 111_1010
// 111: m[+1] = +8, -m[+1] = -8 = 111_1000
assign qds_para_pos_1_d = 
  ({(2){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b000}} & 2'b10)
| ({(2){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b001}} & 2'b10)
| ({(2){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b010}} & 2'b10)
| ({(2){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b011}} & 2'b10)
| ({(2){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b100}} & 2'b01)
| ({(2){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b101}} & 2'b01)
| ({(2){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b110}} & 2'b01)
| ({(2){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b111}} & 2'b00);

assign qds_para_pos_2_en = fsm_q[FSM_PRE_1_BIT];
// For "normalized_d[(WIDTH - 2) -: 3]",
// 000: m[+2] = +12, -m[+2] = -12 = 11_0100 -> ext(-m[+2]) = 11_01000
// 001: m[+2] = +14, -m[+2] = -14 = 11_0010 -> ext(-m[+2]) = 11_00100
// 010: m[+2] = +15, -m[+2] = -15 = 11_0001 -> ext(-m[+2]) = 11_00010
// 011: m[+2] = +16, -m[+2] = -16 = 11_0000 -> ext(-m[+2]) = 11_00000
// 100: m[+2] = +18, -m[+2] = -18 = 10_1110 -> ext(-m[+2]) = 10_11100
// 101: m[+2] = +20, -m[+2] = -20 = 10_1100 -> ext(-m[+2]) = 10_11000
// 110: m[+2] = +22, -m[+2] = -22 = 10_1010 -> ext(-m[+2]) = 10_10100
// 111: m[+2] = +22, -m[+2] = -22 = 10_1010 -> ext(-m[+2]) = 10_10100
assign qds_para_pos_2_d = 
  ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b000}} & 5'b1_0100)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b001}} & 5'b1_0010)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b010}} & 5'b1_0001)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b011}} & 5'b1_0000)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b100}} & 5'b0_1110)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b101}} & 5'b0_1100)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b110}} & 5'b0_1010)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b111}} & 5'b0_1010);

assign special_divisor_en = fsm_q[FSM_PRE_1_BIT];
assign special_divisor_d = (divisor_abs_q[(WIDTH - 2) -: 3] == 3'b000) | (divisor_abs_q[(WIDTH - 2) -: 3] == 3'b100);
always_ff @(posedge clk) begin
	if(qds_para_neg_1_en)
		qds_para_neg_1_q <= qds_para_neg_1_d;
	if(qds_para_neg_0_en)
		qds_para_neg_0_q <= qds_para_neg_0_d;
	if(qds_para_pos_1_en)
		qds_para_pos_1_q <= qds_para_pos_1_d;
	if(qds_para_pos_2_en)
		qds_para_pos_2_q <= qds_para_pos_2_d;
	if(special_divisor_en)
		special_divisor_q <= special_divisor_d;
end

// ================================================================================================================================================
// Get iter_num, and some initial value for different regs.
// ================================================================================================================================================
assign lzc_diff_slow = {1'b0, divisor_lzc[0 +: LZC_WIDTH]} - {1'b0, dividend_lzc[0 +: LZC_WIDTH]};
assign lzc_diff_fast = {1'b0, divisor_lzc_q[0 +: LZC_WIDTH]} - {1'b0, dividend_lzc_q[0 +: LZC_WIDTH]};

// Make sure "dividend_too_small" is the "Q" of a Reg -> The timing could be improved.
assign dividend_too_small_en = fsm_q[FSM_PRE_0_BIT];
assign dividend_too_small_d = lzc_diff_slow[LZC_WIDTH] | dividend_lzc[LZC_WIDTH];
always_ff @(posedge clk)
	if(dividend_too_small_en)
		dividend_too_small_q <= dividend_too_small_d;

assign divisor_is_zero = divisor_lzc_q[LZC_WIDTH];
assign divisor_is_one = (divisor_lzc[LZC_WIDTH-1:0] == {(LZC_WIDTH){1'b1}});
// iter_num = ceil((lzc_diff + 2) / 4);
// Take "WIDTH = 32" as an example, lzc_diff = 
//  0 -> iter_num = 1, actual_r_shift_num = 2;
//  1 -> iter_num = 1, actual_r_shift_num = 1;
//  2 -> iter_num = 1, actual_r_shift_num = 0;
//  3 -> iter_num = 2, actual_r_shift_num = 3;
//  4 -> iter_num = 2, actual_r_shift_num = 2;
//  5 -> iter_num = 2, actual_r_shift_num = 1;
//  6 -> iter_num = 2, actual_r_shift_num = 0;
// ...
// 28 -> iter_num = 8, actual_r_shift_num = 2;
// 29 -> iter_num = 8, actual_r_shift_num = 1;
// 30 -> iter_num = 8, actual_r_shift_num = 0;
// 31 -> iter_num = 9, actual_r_shift_num = 3, avoid this !!!!
// Therefore, max(iter_num) = 8 -> We only need "3-bit Reg" to remember the "iter_num".
// If (lzc_diff == 31) -> Q = dividend_i, R = 0.
assign no_iter_needed_en = fsm_q[FSM_PRE_0_BIT];
assign no_iter_needed_d = divisor_is_one & dividend_abs_q[WIDTH-1];
always_ff @(posedge clk)
	if(no_iter_needed_en)
		no_iter_needed_q <= no_iter_needed_d;

// TO save a FA, use "lzc_diff[1:0]" to express "r_shift_num";
assign r_shift_num = lzc_diff_fast[1:0];
assign rem_sum_normal_init_value = {
	3'b0, 
	  {(WIDTH + 3){r_shift_num == 2'd0}} & {2'b0, 	dividend_abs_q[WIDTH-1:0], 1'b0	}
	| {(WIDTH + 3){r_shift_num == 2'd1}} & {1'b0, 	dividend_abs_q[WIDTH-1:0], 2'b0	}
	| {(WIDTH + 3){r_shift_num == 2'd2}} & {		dividend_abs_q[WIDTH-1:0], 3'b0	}
	| {(WIDTH + 3){r_shift_num == 2'd3}} & {3'b0,	dividend_abs_q[WIDTH-1:0]		}
};
assign rem_carry_init_value = {(ITN_W){1'b0}};
// divisor_is_zero/dividend_too_small: Put the dividend at the suitable position. So we can get the correct R in POST_PROCESS_1.
assign rem_sum_init_value = (dividend_too_small_q | divisor_is_zero) ? {1'b0, post_r_shift_res_s5, 5'b0} : no_iter_needed_q ? {(ITN_W){1'b0}} : 
rem_sum_normal_init_value;

// For "rem_sum_normal_init_value = (normalized_dividend >> 2 >> r_shift_num)", the decimal point is between "[ITN_W-1]" and "[ITN_W-2]".
// According to the paper, we should use "(4 * rem_sum_normal_init_value)_trunc_1_4" to choose the 1st quo.
assign pre_rem_trunc_1_4 = {1'b0, rem_sum_normal_init_value[(ITN_W - 4) -: 4]};
// For "normalized_d[(WIDTH - 2) -: 3]",
// 000: m[+1] =  +4 = 0_0100;
// 001: m[+1] =  +4 = 0_0100;
// 010: m[+1] =  +4 = 0_0100;
// 011: m[+1] =  +4 = 0_0100;
// 100: m[+1] =  +6 = 0_0110;
// 101: m[+1] =  +6 = 0_0110;
// 110: m[+1] =  +6 = 0_0110;
// 111: m[+1] =  +8 = 0_1000;
// =============================
// 000: m[+2] = +12 = 0_1100;
// 001: m[+2] = +14 = 0_1110;
// 010: m[+2] = +15 = 0_1111;
// 011: m[+2] = +16 = 1_0000;
// 100: m[+2] = +18 = 1_0010;
// 101: m[+2] = +20 = 1_0100;
// 110: m[+2] = +22 = 1_0110;
// 111: m[+2] = +22 = 1_0110;
// So we need to do 5-bit cmp to get the 1st quo.
assign pre_m_pos_1 = 
  ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b000}} & 5'b0_0100)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b001}} & 5'b0_0100)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b010}} & 5'b0_0100)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b011}} & 5'b0_0110)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b100}} & 5'b0_0110)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b101}} & 5'b0_0110)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b110}} & 5'b0_0110)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b111}} & 5'b0_1000);
assign pre_m_pos_2 = 
  ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b000}} & 5'b0_1100)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b001}} & 5'b0_1110)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b010}} & 5'b0_1111)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b011}} & 5'b1_0000)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b100}} & 5'b1_0010)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b101}} & 5'b1_0100)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b110}} & 5'b1_0110)
| ({(5){divisor_abs_q[(WIDTH - 2) -: 3] == 3'b111}} & 5'b1_0110);
// REM must be positive in PRE_PROCESS_1, so we only need to compare it with m[+1]/m[+2]. The 5-bit CMP should be fast enough.
assign pre_cmp_res = {(pre_rem_trunc_1_4 >= pre_m_pos_1), (pre_rem_trunc_1_4 >= pre_m_pos_2)};
assign prev_quo_digit_init_value = pre_cmp_res[0] ? QUO_ONEHOT_POS_2 : pre_cmp_res[1] ? QUO_ONEHOT_POS_1 : QUO_ONEHOT_ZERO;
assign prev_quo_digit_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign prev_quo_digit_d = fsm_q[FSM_PRE_1_BIT] ? prev_quo_digit_init_value : quo_digit_nxt;
always_ff @(posedge clk)
	if(prev_quo_digit_en)
		prev_quo_digit_q <= prev_quo_digit_d;

// ================================================================================================================================================
// Let's do SRT ITER !!!!!
// ================================================================================================================================================

r16_block #(
	.WIDTH(WIDTH),
	.ITN_W(ITN_W),
	.QUO_ONEHOT_WIDTH(QUO_ONEHOT_WIDTH)
) u_r16_block (
	.rem_sum_i(rem_sum_q),
	.rem_carry_i(rem_carry_q),
	.rem_sum_o(rem_sum_nxt),
	.rem_carry_o(rem_carry_nxt),
	.divisor_i(divisor_abs_q[WIDTH-1:0]),
	.qds_para_neg_1_i(qds_para_neg_1_q),
	.qds_para_neg_0_i(qds_para_neg_0_q),
	.qds_para_pos_1_i(qds_para_pos_1_q),
	.qds_para_pos_2_i(qds_para_pos_2_q),
	.special_divisor_i(special_divisor_q),
	.quo_iter_i(quo_iter_q),
	.quo_m1_iter_i(quo_m1_iter_q),
	.quo_iter_o(quo_iter_nxt),
	.quo_m1_iter_o(quo_m1_iter_nxt),
	.prev_quo_digit_i(prev_quo_digit_q),
	.quo_digit_o(quo_digit_nxt)
);

assign quo_iter_en 		= fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT] | fsm_q[FSM_POST_0_BIT];
assign quo_m1_iter_en 	= fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT] | fsm_q[FSM_POST_0_BIT];
// When "divisor_is_zero", the final Q should be ALL'1s
assign quo_iter_d = fsm_q[FSM_PRE_1_BIT] ? (divisor_is_zero ? {(WIDTH){1'b1}} : no_iter_needed_q ? dividend_abs_q[WIDTH-1:0] : {(WIDTH){1'b0}}) : 
(fsm_q[FSM_POST_0_BIT] ? (quo_sign_q ? inverter_res[0] : quo_iter_q) : quo_iter_nxt);
assign quo_m1_iter_d = fsm_q[FSM_PRE_1_BIT] ? {(WIDTH){1'b0}} : (fsm_q[FSM_POST_0_BIT] ? (quo_sign_q ? inverter_res[1] : quo_m1_iter_q) : quo_m1_iter_nxt);
always_ff @(posedge clk) begin
	if(quo_iter_en)
		quo_iter_q <= quo_iter_d;
	if(quo_m1_iter_en)
		quo_m1_iter_q <= quo_m1_iter_d;
end

assign final_iter = (iter_num_q == {(LZC_WIDTH - 2){1'b0}});
assign iter_num_en = fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign iter_num_d = fsm_q[FSM_PRE_1_BIT] ? (lzc_diff_fast[LZC_WIDTH - 1:2] + {{(LZC_WIDTH - 3){1'b0}}, &lzc_diff_fast[1:0]}) : 
(iter_num_q - {{(LZC_WIDTH - 3){1'b0}}, 1'b1});
always_ff @(posedge clk)
	if(iter_num_en)
		iter_num_q <= iter_num_d;

assign rem_sum_en 		= fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign rem_sum_d	 	= fsm_q[FSM_PRE_1_BIT] ? rem_sum_init_value : rem_sum_nxt;
assign rem_carry_en 	= fsm_q[FSM_PRE_1_BIT] | fsm_q[FSM_ITER_BIT];
assign rem_carry_d 		= fsm_q[FSM_PRE_1_BIT] ? rem_carry_init_value : rem_carry_nxt;
always_ff @(posedge clk) begin
	if(rem_sum_en)
		rem_sum_q <= rem_sum_d;
	if(rem_carry_en)
		rem_carry_q <= rem_carry_d;
end

// ================================================================================================================================================
// Post Process
// ================================================================================================================================================
// If(rem <= 0), 
// rem = (-rem_sum) + (-rem_carry) = ~rem_sum + ~rem_carry + 2'b10;
// If(rem <= 0), 
// rem_plus_d = ~rem_sum + ~rem_carry + ~normalized_d + 2'b11;
assign nr_rem_nxt = 
  ({(ITN_W){rem_sign_q}} ^ rem_sum_q)
+ ({(ITN_W){rem_sign_q}} ^ rem_carry_q)
+ {{(ITN_W - 2){1'b0}}, rem_sign_q, 1'b0};

assign nr_rem_plus_d_nxt = 
  ({(ITN_W){rem_sign_q}} ^ rem_sum_q)
+ ({(ITN_W){rem_sign_q}} ^ rem_carry_q)
+ ({(ITN_W){rem_sign_q}} ^ {1'b0, divisor_abs_q[WIDTH-1:0], 5'b0})
+ {{(ITN_W - 2){1'b0}}, rem_sign_q, rem_sign_q};

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
assign need_corr = (~divisor_is_zero & ~no_iter_needed_q) & (rem_sign_q ? (~nr_rem[WIDTH] & ~nr_rem_is_zero) : nr_rem[WIDTH]);
assign pre_shifted_rem = need_corr ? nr_rem_plus_d : nr_rem;
assign final_rem = post_r_shift_res_s5;
assign final_quo = need_corr ? quo_m1_iter_q : quo_iter_q;
// ================================================================================================================================================
// output signals
// ================================================================================================================================================
assign div_start_ready_o = fsm_q[FSM_IDLE_ABS_BIT];
assign div_finish_valid_o = fsm_q[FSM_POST_1_BIT];
assign divisor_is_zero_o = divisor_is_zero;
assign quotient_o = final_quo;
assign remainder_o = final_rem;


endmodule
