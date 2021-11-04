// ========================================================================================================
// File Name			: int64_div_cla2.sv
// Author				: Yifei He
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-10-29 10:21:29
// Last Modified Time   : 2021-10-31 15:03:58
// ========================================================================================================
// Description	:
// Radix-4 restoring interger division algorithm.
// This algorithm is suitable for multicycle implementation.
// This module could do 16/32/64-bit signed/unsigned integer division.
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

// include your definitions here

module int64_div_cla2 #(
	// Put your parameters here, which can be changed by other modules.
	
)(
	// 00: int16
	// 01: int32
	// 10: int64
	input  logic [1:0] op_format_i,
	input  logic op_sign_i,
	input  logic [64-1:0] dividend_i,
	input  logic [64-1:0] divisor_i,
	output logic [64-1:0] quotient_o,
	output logic [64-1:0] remainder_o,
	output logic divisor_is_zero_o
);

// ==================================================================================================================================================
// (local) params
// ==================================================================================================================================================



// ==================================================================================================================================================
// functions
// ==================================================================================================================================================



// ==================================================================================================================================================
// signals
// ==================================================================================================================================================

genvar i;

logic int16_en;
logic int32_en;
logic int64_en;

logic dividend_sign;
logic divisor_sign;
logic quo_sign;
logic rem_sign;

logic [64-1:0] dividend_abs;
logic [64-1:0] negated_dividend;
logic [64-1:0] dividend_adjusted;
logic [64-1:0] divisor_adjusted;

logic [64-1:0] D;
logic [(64 + 2)-1:0] D_times_3;

logic [64-1:0] rem [64-1:0];
logic [64-1:0] rem_prev_q_0 [64-1:0];
logic [64-1:0] rem_prev_q_1 [64-1:0];

logic rem_cout [64-1:0];
logic rem_cout_prev_q_0 [64-1:0];
logic rem_cout_prev_q_1 [64-1:0];

logic [64-1:0] rem_sum [64-1:0];
logic [64-1:0] rem_sum_prev_q_0 [64-1:0];
logic [64-1:0] rem_sum_prev_q_1 [64-1:0];

logic [64-1:0] quo_iter;
logic q_prev_q_0 [64-1:0];
logic q_prev_q_1 [64-1:0];

logic force_q_to_zero [64-1:0];
logic force_q_to_zero_prev_q_0 [64-1:0];
logic force_q_to_zero_prev_q_1 [64-1:0];

logic D_msb_to_lsb_flag [64-1:0];
logic D_lsb_to_msb_flag [64-1:0];

logic D_times_3_msb_to_lsb_flag [64-1:0];
logic D_times_3_lsb_to_msb_flag [64-1:0];

logic [64-1:0] final_rem;
logic [64-1:0] final_quo;
logic [64-1:0] final_quo_pre;

// ==================================================================================================================================================
// main codes
// ==================================================================================================================================================

assign int16_en = (op_format_i == 2'b00);
assign int32_en = (op_format_i == 2'b01);
assign int64_en = (op_format_i == 2'b10);

assign dividend_sign = op_sign_i & (int16_en ? dividend_i[15] : int32_en ? dividend_i[31] : dividend_i[63]);
assign divisor_sign = op_sign_i & (int16_en ? divisor_i[15] : int32_en ? divisor_i[31] : divisor_i[63]);
assign quo_sign = dividend_sign ^ divisor_sign;
assign rem_sign = dividend_sign;

assign dividend_adjusted = int32_en ? {{(32){dividend_sign}}, dividend_i[31:0]} : int16_en ? {{(48){dividend_sign}}, dividend_i[15:0]} : dividend_i[63:0];
assign divisor_adjusted = int32_en ? {{(32){divisor_sign}}, divisor_i[31:0]} : int16_en ? {{(48){divisor_sign}}, divisor_i[15:0]} : divisor_i[63:0];

assign negated_dividend = -dividend_adjusted;
assign dividend_abs = dividend_sign ? negated_dividend : dividend_adjusted;

assign D = divisor_adjusted;
// Sign-ext and add
assign D_times_3[66-1:0] = {D[63], D[63], D} + {D[63], D, 1'b0};

// When "D < 0, and D is the power of 2", we need to make sure that we detect the index of the leading "1" in its abs value (leading one index, loi) correctly.
// For simplicity, let's assume D is a 8-bit signed integer:
// Ex0.
// D = 1101_0000, abs(D) = 0011_0000
// &(D[7:6]) = 1, loi = 5 -> This is correct.
// Ex1.
// D = 1001_1101, abs(D) = 0110_0011
// &(D[7:7]) = 1, loi = 6 -> This is correct.
// Ex2.
// D = 1111_0100, abs(D) = 0000_1100
// &(D[7:4]) = 1, loi = 3 -> This is correct.
// Ex3.
// D = 1111_0000, abs(D) = 0001_0000
// &(D[7:4]) = 1, loi = 3 -> This is wrong !!!
// So, we need to use "D_lsb_to_msb_flag" to get the correct "loi".
// D = 1111_0000, abs(D) = 0001_0000
// &(D[7:4]) = 1, |(D[3:0]) = 0 -> loi is not 3.
// &(D[7:5]) = 1, |(D[4:0]) = 1 -> loi is 4, correct !!!
// The same logic will be used in "D_times_3".

// When D is negative, D[64] must be 1, so we don't need to include it.
assign D_msb_to_lsb_flag[ 0] = ~divisor_sign ? |(D[63: 1]) : ~(&(D[62: 1]));
assign D_msb_to_lsb_flag[ 1] = ~divisor_sign ? |(D[63: 2]) : ~(&(D[62: 2]));
assign D_msb_to_lsb_flag[ 2] = ~divisor_sign ? |(D[63: 3]) : ~(&(D[62: 3]));
assign D_msb_to_lsb_flag[ 3] = ~divisor_sign ? |(D[63: 4]) : ~(&(D[62: 4]));
assign D_msb_to_lsb_flag[ 4] = ~divisor_sign ? |(D[63: 5]) : ~(&(D[62: 5]));
assign D_msb_to_lsb_flag[ 5] = ~divisor_sign ? |(D[63: 6]) : ~(&(D[62: 6]));
assign D_msb_to_lsb_flag[ 6] = ~divisor_sign ? |(D[63: 7]) : ~(&(D[62: 7]));
assign D_msb_to_lsb_flag[ 7] = ~divisor_sign ? |(D[63: 8]) : ~(&(D[62: 8]));
assign D_msb_to_lsb_flag[ 8] = ~divisor_sign ? |(D[63: 9]) : ~(&(D[62: 9]));
assign D_msb_to_lsb_flag[ 9] = ~divisor_sign ? |(D[63:10]) : ~(&(D[62:10]));
assign D_msb_to_lsb_flag[10] = ~divisor_sign ? |(D[63:11]) : ~(&(D[62:11]));
assign D_msb_to_lsb_flag[11] = ~divisor_sign ? |(D[63:12]) : ~(&(D[62:12]));
assign D_msb_to_lsb_flag[12] = ~divisor_sign ? |(D[63:13]) : ~(&(D[62:13]));
assign D_msb_to_lsb_flag[13] = ~divisor_sign ? |(D[63:14]) : ~(&(D[62:14]));
assign D_msb_to_lsb_flag[14] = ~divisor_sign ? |(D[63:15]) : ~(&(D[62:15]));
assign D_msb_to_lsb_flag[15] = ~divisor_sign ? |(D[63:16]) : ~(&(D[62:16]));
assign D_msb_to_lsb_flag[16] = ~divisor_sign ? |(D[63:17]) : ~(&(D[62:17]));
assign D_msb_to_lsb_flag[17] = ~divisor_sign ? |(D[63:18]) : ~(&(D[62:18]));
assign D_msb_to_lsb_flag[18] = ~divisor_sign ? |(D[63:19]) : ~(&(D[62:19]));
assign D_msb_to_lsb_flag[19] = ~divisor_sign ? |(D[63:20]) : ~(&(D[62:20]));
assign D_msb_to_lsb_flag[20] = ~divisor_sign ? |(D[63:21]) : ~(&(D[62:21]));
assign D_msb_to_lsb_flag[21] = ~divisor_sign ? |(D[63:22]) : ~(&(D[62:22]));
assign D_msb_to_lsb_flag[22] = ~divisor_sign ? |(D[63:23]) : ~(&(D[62:23]));
assign D_msb_to_lsb_flag[23] = ~divisor_sign ? |(D[63:24]) : ~(&(D[62:24]));
assign D_msb_to_lsb_flag[24] = ~divisor_sign ? |(D[63:25]) : ~(&(D[62:25]));
assign D_msb_to_lsb_flag[25] = ~divisor_sign ? |(D[63:26]) : ~(&(D[62:26]));
assign D_msb_to_lsb_flag[26] = ~divisor_sign ? |(D[63:27]) : ~(&(D[62:27]));
assign D_msb_to_lsb_flag[27] = ~divisor_sign ? |(D[63:28]) : ~(&(D[62:28]));
assign D_msb_to_lsb_flag[28] = ~divisor_sign ? |(D[63:29]) : ~(&(D[62:29]));
assign D_msb_to_lsb_flag[29] = ~divisor_sign ? |(D[63:30]) : ~(&(D[62:30]));
assign D_msb_to_lsb_flag[30] = ~divisor_sign ? |(D[63:31]) : ~(&(D[62:31]));
assign D_msb_to_lsb_flag[31] = ~divisor_sign ? |(D[63:32]) : ~(&(D[62:32]));
assign D_msb_to_lsb_flag[32] = ~divisor_sign ? |(D[63:33]) : ~(&(D[62:33]));
assign D_msb_to_lsb_flag[33] = ~divisor_sign ? |(D[63:34]) : ~(&(D[62:34]));
assign D_msb_to_lsb_flag[34] = ~divisor_sign ? |(D[63:35]) : ~(&(D[62:35]));
assign D_msb_to_lsb_flag[35] = ~divisor_sign ? |(D[63:36]) : ~(&(D[62:36]));
assign D_msb_to_lsb_flag[36] = ~divisor_sign ? |(D[63:37]) : ~(&(D[62:37]));
assign D_msb_to_lsb_flag[37] = ~divisor_sign ? |(D[63:38]) : ~(&(D[62:38]));
assign D_msb_to_lsb_flag[38] = ~divisor_sign ? |(D[63:39]) : ~(&(D[62:39]));
assign D_msb_to_lsb_flag[39] = ~divisor_sign ? |(D[63:40]) : ~(&(D[62:40]));
assign D_msb_to_lsb_flag[40] = ~divisor_sign ? |(D[63:41]) : ~(&(D[62:41]));
assign D_msb_to_lsb_flag[41] = ~divisor_sign ? |(D[63:42]) : ~(&(D[62:42]));
assign D_msb_to_lsb_flag[42] = ~divisor_sign ? |(D[63:43]) : ~(&(D[62:43]));
assign D_msb_to_lsb_flag[43] = ~divisor_sign ? |(D[63:44]) : ~(&(D[62:44]));
assign D_msb_to_lsb_flag[44] = ~divisor_sign ? |(D[63:45]) : ~(&(D[62:45]));
assign D_msb_to_lsb_flag[45] = ~divisor_sign ? |(D[63:46]) : ~(&(D[62:46]));
assign D_msb_to_lsb_flag[46] = ~divisor_sign ? |(D[63:47]) : ~(&(D[62:47]));
assign D_msb_to_lsb_flag[47] = ~divisor_sign ? |(D[63:48]) : ~(&(D[62:48]));
assign D_msb_to_lsb_flag[48] = ~divisor_sign ? |(D[63:49]) : ~(&(D[62:49]));
assign D_msb_to_lsb_flag[49] = ~divisor_sign ? |(D[63:50]) : ~(&(D[62:50]));
assign D_msb_to_lsb_flag[50] = ~divisor_sign ? |(D[63:51]) : ~(&(D[62:51]));
assign D_msb_to_lsb_flag[51] = ~divisor_sign ? |(D[63:52]) : ~(&(D[62:52]));
assign D_msb_to_lsb_flag[52] = ~divisor_sign ? |(D[63:53]) : ~(&(D[62:53]));
assign D_msb_to_lsb_flag[53] = ~divisor_sign ? |(D[63:54]) : ~(&(D[62:54]));
assign D_msb_to_lsb_flag[54] = ~divisor_sign ? |(D[63:55]) : ~(&(D[62:55]));
assign D_msb_to_lsb_flag[55] = ~divisor_sign ? |(D[63:56]) : ~(&(D[62:56]));
assign D_msb_to_lsb_flag[56] = ~divisor_sign ? |(D[63:57]) : ~(&(D[62:57]));
assign D_msb_to_lsb_flag[57] = ~divisor_sign ? |(D[63:58]) : ~(&(D[62:58]));
assign D_msb_to_lsb_flag[58] = ~divisor_sign ? |(D[63:59]) : ~(&(D[62:59]));
assign D_msb_to_lsb_flag[59] = ~divisor_sign ? |(D[63:60]) : ~(&(D[62:60]));
assign D_msb_to_lsb_flag[60] = ~divisor_sign ? |(D[63:61]) : ~(&(D[62:61]));
assign D_msb_to_lsb_flag[61] = ~divisor_sign ? |(D[63:62]) : ~(&(D[62:62]));
assign D_msb_to_lsb_flag[62] = ~divisor_sign ? |(D[63:63]) : 1'b0;
assign D_msb_to_lsb_flag[63] = 1'b0;

// This flag is only useful when D < 0
assign D_lsb_to_msb_flag[ 0] = divisor_sign ? ~(|(D[ 0:0])) : 1'b0;
assign D_lsb_to_msb_flag[ 1] = divisor_sign ? ~(|(D[ 1:0])) : 1'b0;
assign D_lsb_to_msb_flag[ 2] = divisor_sign ? ~(|(D[ 2:0])) : 1'b0;
assign D_lsb_to_msb_flag[ 3] = divisor_sign ? ~(|(D[ 3:0])) : 1'b0;
assign D_lsb_to_msb_flag[ 4] = divisor_sign ? ~(|(D[ 4:0])) : 1'b0;
assign D_lsb_to_msb_flag[ 5] = divisor_sign ? ~(|(D[ 5:0])) : 1'b0;
assign D_lsb_to_msb_flag[ 6] = divisor_sign ? ~(|(D[ 6:0])) : 1'b0;
assign D_lsb_to_msb_flag[ 7] = divisor_sign ? ~(|(D[ 7:0])) : 1'b0;
assign D_lsb_to_msb_flag[ 8] = divisor_sign ? ~(|(D[ 8:0])) : 1'b0;
assign D_lsb_to_msb_flag[ 9] = divisor_sign ? ~(|(D[ 9:0])) : 1'b0;
assign D_lsb_to_msb_flag[10] = divisor_sign ? ~(|(D[10:0])) : 1'b0;
assign D_lsb_to_msb_flag[11] = divisor_sign ? ~(|(D[11:0])) : 1'b0;
assign D_lsb_to_msb_flag[12] = divisor_sign ? ~(|(D[12:0])) : 1'b0;
assign D_lsb_to_msb_flag[13] = divisor_sign ? ~(|(D[13:0])) : 1'b0;
assign D_lsb_to_msb_flag[14] = divisor_sign ? ~(|(D[14:0])) : 1'b0;
assign D_lsb_to_msb_flag[15] = divisor_sign ? ~(|(D[15:0])) : 1'b0;
assign D_lsb_to_msb_flag[16] = divisor_sign ? ~(|(D[16:0])) : 1'b0;
assign D_lsb_to_msb_flag[17] = divisor_sign ? ~(|(D[17:0])) : 1'b0;
assign D_lsb_to_msb_flag[18] = divisor_sign ? ~(|(D[18:0])) : 1'b0;
assign D_lsb_to_msb_flag[19] = divisor_sign ? ~(|(D[19:0])) : 1'b0;
assign D_lsb_to_msb_flag[20] = divisor_sign ? ~(|(D[20:0])) : 1'b0;
assign D_lsb_to_msb_flag[21] = divisor_sign ? ~(|(D[21:0])) : 1'b0;
assign D_lsb_to_msb_flag[22] = divisor_sign ? ~(|(D[22:0])) : 1'b0;
assign D_lsb_to_msb_flag[23] = divisor_sign ? ~(|(D[23:0])) : 1'b0;
assign D_lsb_to_msb_flag[24] = divisor_sign ? ~(|(D[24:0])) : 1'b0;
assign D_lsb_to_msb_flag[25] = divisor_sign ? ~(|(D[25:0])) : 1'b0;
assign D_lsb_to_msb_flag[26] = divisor_sign ? ~(|(D[26:0])) : 1'b0;
assign D_lsb_to_msb_flag[27] = divisor_sign ? ~(|(D[27:0])) : 1'b0;
assign D_lsb_to_msb_flag[28] = divisor_sign ? ~(|(D[28:0])) : 1'b0;
assign D_lsb_to_msb_flag[29] = divisor_sign ? ~(|(D[29:0])) : 1'b0;
assign D_lsb_to_msb_flag[30] = divisor_sign ? ~(|(D[30:0])) : 1'b0;
assign D_lsb_to_msb_flag[31] = divisor_sign ? ~(|(D[31:0])) : 1'b0;
assign D_lsb_to_msb_flag[32] = divisor_sign ? ~(|(D[32:0])) : 1'b0;
assign D_lsb_to_msb_flag[33] = divisor_sign ? ~(|(D[33:0])) : 1'b0;
assign D_lsb_to_msb_flag[34] = divisor_sign ? ~(|(D[34:0])) : 1'b0;
assign D_lsb_to_msb_flag[35] = divisor_sign ? ~(|(D[35:0])) : 1'b0;
assign D_lsb_to_msb_flag[36] = divisor_sign ? ~(|(D[36:0])) : 1'b0;
assign D_lsb_to_msb_flag[37] = divisor_sign ? ~(|(D[37:0])) : 1'b0;
assign D_lsb_to_msb_flag[38] = divisor_sign ? ~(|(D[38:0])) : 1'b0;
assign D_lsb_to_msb_flag[39] = divisor_sign ? ~(|(D[39:0])) : 1'b0;
assign D_lsb_to_msb_flag[40] = divisor_sign ? ~(|(D[40:0])) : 1'b0;
assign D_lsb_to_msb_flag[41] = divisor_sign ? ~(|(D[41:0])) : 1'b0;
assign D_lsb_to_msb_flag[42] = divisor_sign ? ~(|(D[42:0])) : 1'b0;
assign D_lsb_to_msb_flag[43] = divisor_sign ? ~(|(D[43:0])) : 1'b0;
assign D_lsb_to_msb_flag[44] = divisor_sign ? ~(|(D[44:0])) : 1'b0;
assign D_lsb_to_msb_flag[45] = divisor_sign ? ~(|(D[45:0])) : 1'b0;
assign D_lsb_to_msb_flag[46] = divisor_sign ? ~(|(D[46:0])) : 1'b0;
assign D_lsb_to_msb_flag[47] = divisor_sign ? ~(|(D[47:0])) : 1'b0;
assign D_lsb_to_msb_flag[48] = divisor_sign ? ~(|(D[48:0])) : 1'b0;
assign D_lsb_to_msb_flag[49] = divisor_sign ? ~(|(D[49:0])) : 1'b0;
assign D_lsb_to_msb_flag[50] = divisor_sign ? ~(|(D[50:0])) : 1'b0;
assign D_lsb_to_msb_flag[51] = divisor_sign ? ~(|(D[51:0])) : 1'b0;
assign D_lsb_to_msb_flag[52] = divisor_sign ? ~(|(D[52:0])) : 1'b0;
assign D_lsb_to_msb_flag[53] = divisor_sign ? ~(|(D[53:0])) : 1'b0;
assign D_lsb_to_msb_flag[54] = divisor_sign ? ~(|(D[54:0])) : 1'b0;
assign D_lsb_to_msb_flag[55] = divisor_sign ? ~(|(D[55:0])) : 1'b0;
assign D_lsb_to_msb_flag[56] = divisor_sign ? ~(|(D[56:0])) : 1'b0;
assign D_lsb_to_msb_flag[57] = divisor_sign ? ~(|(D[57:0])) : 1'b0;
assign D_lsb_to_msb_flag[58] = divisor_sign ? ~(|(D[58:0])) : 1'b0;
assign D_lsb_to_msb_flag[59] = divisor_sign ? ~(|(D[59:0])) : 1'b0;
assign D_lsb_to_msb_flag[60] = divisor_sign ? ~(|(D[60:0])) : 1'b0;
assign D_lsb_to_msb_flag[61] = divisor_sign ? ~(|(D[61:0])) : 1'b0;
assign D_lsb_to_msb_flag[62] = divisor_sign ? ~(|(D[62:0])) : 1'b0;
assign D_lsb_to_msb_flag[63] = 1'b0;

// Only useful in stage[1, 3, ..., 63]
assign D_times_3_msb_to_lsb_flag[ 0] = 1'b0;
assign D_times_3_msb_to_lsb_flag[ 1] = ~divisor_sign ? |(D_times_3[65: 2]) : ~(&(D_times_3[64: 2]));
assign D_times_3_msb_to_lsb_flag[ 2] = 1'b0;
assign D_times_3_msb_to_lsb_flag[ 3] = ~divisor_sign ? |(D_times_3[65: 4]) : ~(&(D_times_3[64: 4]));
assign D_times_3_msb_to_lsb_flag[ 4] = 1'b0;
assign D_times_3_msb_to_lsb_flag[ 5] = ~divisor_sign ? |(D_times_3[65: 6]) : ~(&(D_times_3[64: 6]));
assign D_times_3_msb_to_lsb_flag[ 6] = 1'b0;
assign D_times_3_msb_to_lsb_flag[ 7] = ~divisor_sign ? |(D_times_3[65: 8]) : ~(&(D_times_3[64: 8]));
assign D_times_3_msb_to_lsb_flag[ 8] = 1'b0;
assign D_times_3_msb_to_lsb_flag[ 9] = ~divisor_sign ? |(D_times_3[65:10]) : ~(&(D_times_3[64:10]));
assign D_times_3_msb_to_lsb_flag[10] = 1'b0;
assign D_times_3_msb_to_lsb_flag[11] = ~divisor_sign ? |(D_times_3[65:12]) : ~(&(D_times_3[64:12]));
assign D_times_3_msb_to_lsb_flag[12] = 1'b0;
assign D_times_3_msb_to_lsb_flag[13] = ~divisor_sign ? |(D_times_3[65:14]) : ~(&(D_times_3[64:14]));
assign D_times_3_msb_to_lsb_flag[14] = 1'b0;
assign D_times_3_msb_to_lsb_flag[15] = ~divisor_sign ? |(D_times_3[65:16]) : ~(&(D_times_3[64:16]));
assign D_times_3_msb_to_lsb_flag[16] = 1'b0;
assign D_times_3_msb_to_lsb_flag[17] = ~divisor_sign ? |(D_times_3[65:18]) : ~(&(D_times_3[64:18]));
assign D_times_3_msb_to_lsb_flag[18] = 1'b0;
assign D_times_3_msb_to_lsb_flag[19] = ~divisor_sign ? |(D_times_3[65:20]) : ~(&(D_times_3[64:20]));
assign D_times_3_msb_to_lsb_flag[20] = 1'b0;
assign D_times_3_msb_to_lsb_flag[21] = ~divisor_sign ? |(D_times_3[65:22]) : ~(&(D_times_3[64:22]));
assign D_times_3_msb_to_lsb_flag[22] = 1'b0;
assign D_times_3_msb_to_lsb_flag[23] = ~divisor_sign ? |(D_times_3[65:24]) : ~(&(D_times_3[64:24]));
assign D_times_3_msb_to_lsb_flag[24] = 1'b0;
assign D_times_3_msb_to_lsb_flag[25] = ~divisor_sign ? |(D_times_3[65:26]) : ~(&(D_times_3[64:26]));
assign D_times_3_msb_to_lsb_flag[26] = 1'b0;
assign D_times_3_msb_to_lsb_flag[27] = ~divisor_sign ? |(D_times_3[65:28]) : ~(&(D_times_3[64:28]));
assign D_times_3_msb_to_lsb_flag[28] = 1'b0;
assign D_times_3_msb_to_lsb_flag[29] = ~divisor_sign ? |(D_times_3[65:30]) : ~(&(D_times_3[64:30]));
assign D_times_3_msb_to_lsb_flag[30] = 1'b0;
assign D_times_3_msb_to_lsb_flag[31] = ~divisor_sign ? |(D_times_3[65:32]) : ~(&(D_times_3[64:32]));
assign D_times_3_msb_to_lsb_flag[32] = 1'b0;
assign D_times_3_msb_to_lsb_flag[33] = ~divisor_sign ? |(D_times_3[65:34]) : ~(&(D_times_3[64:34]));
assign D_times_3_msb_to_lsb_flag[34] = 1'b0;
assign D_times_3_msb_to_lsb_flag[35] = ~divisor_sign ? |(D_times_3[65:36]) : ~(&(D_times_3[64:36]));
assign D_times_3_msb_to_lsb_flag[36] = 1'b0;
assign D_times_3_msb_to_lsb_flag[37] = ~divisor_sign ? |(D_times_3[65:38]) : ~(&(D_times_3[64:38]));
assign D_times_3_msb_to_lsb_flag[38] = 1'b0;
assign D_times_3_msb_to_lsb_flag[39] = ~divisor_sign ? |(D_times_3[65:40]) : ~(&(D_times_3[64:40]));
assign D_times_3_msb_to_lsb_flag[40] = 1'b0;
assign D_times_3_msb_to_lsb_flag[41] = ~divisor_sign ? |(D_times_3[65:42]) : ~(&(D_times_3[64:42]));
assign D_times_3_msb_to_lsb_flag[42] = 1'b0;
assign D_times_3_msb_to_lsb_flag[43] = ~divisor_sign ? |(D_times_3[65:44]) : ~(&(D_times_3[64:44]));
assign D_times_3_msb_to_lsb_flag[44] = 1'b0;
assign D_times_3_msb_to_lsb_flag[45] = ~divisor_sign ? |(D_times_3[65:46]) : ~(&(D_times_3[64:46]));
assign D_times_3_msb_to_lsb_flag[46] = 1'b0;
assign D_times_3_msb_to_lsb_flag[47] = ~divisor_sign ? |(D_times_3[65:48]) : ~(&(D_times_3[64:48]));
assign D_times_3_msb_to_lsb_flag[48] = 1'b0;
assign D_times_3_msb_to_lsb_flag[49] = ~divisor_sign ? |(D_times_3[65:50]) : ~(&(D_times_3[64:50]));
assign D_times_3_msb_to_lsb_flag[50] = 1'b0;
assign D_times_3_msb_to_lsb_flag[51] = ~divisor_sign ? |(D_times_3[65:52]) : ~(&(D_times_3[64:52]));
assign D_times_3_msb_to_lsb_flag[52] = 1'b0;
assign D_times_3_msb_to_lsb_flag[53] = ~divisor_sign ? |(D_times_3[65:54]) : ~(&(D_times_3[64:54]));
assign D_times_3_msb_to_lsb_flag[54] = 1'b0;
assign D_times_3_msb_to_lsb_flag[55] = ~divisor_sign ? |(D_times_3[65:56]) : ~(&(D_times_3[64:56]));
assign D_times_3_msb_to_lsb_flag[56] = 1'b0;
assign D_times_3_msb_to_lsb_flag[57] = ~divisor_sign ? |(D_times_3[65:58]) : ~(&(D_times_3[64:58]));
assign D_times_3_msb_to_lsb_flag[58] = 1'b0;
assign D_times_3_msb_to_lsb_flag[59] = ~divisor_sign ? |(D_times_3[65:60]) : ~(&(D_times_3[64:60]));
assign D_times_3_msb_to_lsb_flag[60] = 1'b0;
assign D_times_3_msb_to_lsb_flag[61] = ~divisor_sign ? |(D_times_3[65:62]) : ~(&(D_times_3[64:62]));
assign D_times_3_msb_to_lsb_flag[62] = 1'b0;
assign D_times_3_msb_to_lsb_flag[63] = ~divisor_sign ? |(D_times_3[65:64]) : ~(&(D_times_3[64:64]));

// Only useful in stage[1, 3, 5, ..., 31], when D < 0.
assign D_times_3_lsb_to_msb_flag[ 0] = 1'b0;
assign D_times_3_lsb_to_msb_flag[ 1] = divisor_sign ? ~(|(D_times_3[ 1:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[ 2] = 1'b0;
assign D_times_3_lsb_to_msb_flag[ 3] = divisor_sign ? ~(|(D_times_3[ 3:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[ 4] = 1'b0;
assign D_times_3_lsb_to_msb_flag[ 5] = divisor_sign ? ~(|(D_times_3[ 5:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[ 6] = 1'b0;
assign D_times_3_lsb_to_msb_flag[ 7] = divisor_sign ? ~(|(D_times_3[ 7:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[ 8] = 1'b0;
assign D_times_3_lsb_to_msb_flag[ 9] = divisor_sign ? ~(|(D_times_3[ 9:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[10] = 1'b0;
assign D_times_3_lsb_to_msb_flag[11] = divisor_sign ? ~(|(D_times_3[11:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[12] = 1'b0;
assign D_times_3_lsb_to_msb_flag[13] = divisor_sign ? ~(|(D_times_3[13:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[14] = 1'b0;
assign D_times_3_lsb_to_msb_flag[15] = divisor_sign ? ~(|(D_times_3[15:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[16] = 1'b0;
assign D_times_3_lsb_to_msb_flag[17] = divisor_sign ? ~(|(D_times_3[17:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[18] = 1'b0;
assign D_times_3_lsb_to_msb_flag[19] = divisor_sign ? ~(|(D_times_3[19:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[20] = 1'b0;
assign D_times_3_lsb_to_msb_flag[21] = divisor_sign ? ~(|(D_times_3[21:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[22] = 1'b0;
assign D_times_3_lsb_to_msb_flag[23] = divisor_sign ? ~(|(D_times_3[23:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[24] = 1'b0;
assign D_times_3_lsb_to_msb_flag[25] = divisor_sign ? ~(|(D_times_3[25:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[26] = 1'b0;
assign D_times_3_lsb_to_msb_flag[27] = divisor_sign ? ~(|(D_times_3[27:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[28] = 1'b0;
assign D_times_3_lsb_to_msb_flag[29] = divisor_sign ? ~(|(D_times_3[29:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[30] = 1'b0;
assign D_times_3_lsb_to_msb_flag[31] = divisor_sign ? ~(|(D_times_3[31:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[32] = 1'b0;
assign D_times_3_lsb_to_msb_flag[33] = divisor_sign ? ~(|(D_times_3[33:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[34] = 1'b0;
assign D_times_3_lsb_to_msb_flag[35] = divisor_sign ? ~(|(D_times_3[35:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[36] = 1'b0;
assign D_times_3_lsb_to_msb_flag[37] = divisor_sign ? ~(|(D_times_3[37:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[38] = 1'b0;
assign D_times_3_lsb_to_msb_flag[39] = divisor_sign ? ~(|(D_times_3[39:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[40] = 1'b0;
assign D_times_3_lsb_to_msb_flag[41] = divisor_sign ? ~(|(D_times_3[41:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[42] = 1'b0;
assign D_times_3_lsb_to_msb_flag[43] = divisor_sign ? ~(|(D_times_3[43:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[44] = 1'b0;
assign D_times_3_lsb_to_msb_flag[45] = divisor_sign ? ~(|(D_times_3[45:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[46] = 1'b0;
assign D_times_3_lsb_to_msb_flag[47] = divisor_sign ? ~(|(D_times_3[47:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[48] = 1'b0;
assign D_times_3_lsb_to_msb_flag[49] = divisor_sign ? ~(|(D_times_3[49:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[50] = 1'b0;
assign D_times_3_lsb_to_msb_flag[51] = divisor_sign ? ~(|(D_times_3[51:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[52] = 1'b0;
assign D_times_3_lsb_to_msb_flag[53] = divisor_sign ? ~(|(D_times_3[53:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[54] = 1'b0;
assign D_times_3_lsb_to_msb_flag[55] = divisor_sign ? ~(|(D_times_3[55:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[56] = 1'b0;
assign D_times_3_lsb_to_msb_flag[57] = divisor_sign ? ~(|(D_times_3[57:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[58] = 1'b0;
assign D_times_3_lsb_to_msb_flag[59] = divisor_sign ? ~(|(D_times_3[59:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[60] = 1'b0;
assign D_times_3_lsb_to_msb_flag[61] = divisor_sign ? ~(|(D_times_3[61:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[62] = 1'b0;
// D_times_3[63] MUST be 1 if "D < 0".
assign D_times_3_lsb_to_msb_flag[63] = 1'b0;


// ==================================================================================================================================================
// stage[0, 1]
// ==================================================================================================================================================
// Set unused bits to zero
// assign rem_cout[1] = '0;
// assign rem_cout_prev_q_0[0] = '0;
// assign rem_cout_prev_q_1[0] = '0;
// assign rem[0][63:1] = '0;
// assign rem[1][63:2] = '0;
// assign rem_sum[0][63:1] = '0;
// assign rem_sum[1] = '0;
// assign rem_prev_q_0[0] = '0;
// assign rem_prev_q_1[0] = '0;
// assign rem_sum_prev_q_0[0] = '0;
// assign rem_sum_prev_q_1[0] = '0;
// assign q_prev_q_0[0] = '0;
// assign q_prev_q_1[0] = '0;
// assign force_q_to_zero[1] = '0;
// assign force_q_to_zero_prev_q_0[0] = '0;
// assign force_q_to_zero_prev_q_1[0] = '0;

// stage[0]
assign {rem_cout[0], rem_sum[0][0:0]} = 
  {1'b0, dividend_abs[63]}
+ {1'b0, {(1){~divisor_sign}} ^ D[0:0]}
+ {1'b0, ~divisor_sign};
assign force_q_to_zero[0] = D_msb_to_lsb_flag[0] | D_lsb_to_msb_flag[0];
assign quo_iter[0] = force_q_to_zero[0] ? 1'b0 : rem_cout[0];
assign rem[0][0:0] = quo_iter[0] ? rem_sum[0][0:0] : dividend_abs[63];

// stage[1]
assign {rem_cout_prev_q_0[1], rem_sum_prev_q_0[1][1:0]} = 
  {1'b0, dividend_abs[63:62]}
+ {1'b0, {(2){~divisor_sign}} ^ D[1:0]}
+ {2'b0, ~divisor_sign};
assign force_q_to_zero_prev_q_0[1] = D_msb_to_lsb_flag[1] | D_lsb_to_msb_flag[1];
assign q_prev_q_0[1] = force_q_to_zero_prev_q_0[1] ? 1'b0 : rem_cout_prev_q_0[1];
assign rem_prev_q_0[1][1:0] = q_prev_q_0[1] ? rem_sum_prev_q_0[1][1:0] : dividend_abs[63:62];

assign {rem_cout_prev_q_1[1], rem_sum_prev_q_1[1][1:0]} = 
  {1'b0, dividend_abs[63:62]}
+ {1'b0, {(2){~divisor_sign}} ^ D_times_3[1:0]}
+ {2'b0, ~divisor_sign};
assign force_q_to_zero_prev_q_1[1] = D_times_3_msb_to_lsb_flag[1] | D_times_3_lsb_to_msb_flag[1];
assign q_prev_q_1[1] = force_q_to_zero_prev_q_1[1] ? 1'b0 : rem_cout_prev_q_1[1];
assign rem_prev_q_1[1][1:0] = q_prev_q_1[1] ? rem_sum_prev_q_1[1][1:0] : {rem[0][0:0], dividend_abs[62]};

assign quo_iter[1] = quo_iter[0] ? q_prev_q_1[1] : q_prev_q_0[1];
assign rem[1][1:0] = quo_iter[0] ? rem_prev_q_1[1][1:0] : rem_prev_q_0[1][1:0];


for(i = 2; i <= 62; i = i + 2) begin: g_restoring_stage_2_to_63

	always_comb begin
		// Set unused bits to zero
		// rem_cout[i] = '0;
		// rem_cout[i+1] = '0;
		// rem_cout_prev_q_0[i] = '0;
		// rem_cout_prev_q_0[i+1] = '0;
		// rem_cout_prev_q_1[i] = '0;
		// rem_cout_prev_q_1[i+1] = '0;
		// rem[i] = '0;
		// rem[i+1] = '0;
		// rem_sum[i] = '0;
		// rem_sum[i+1] = '0;
		// rem_prev_q_0[i] = '0;
		// rem_prev_q_0[i+1] = '0;
		// rem_prev_q_1[i] = '0;
		// rem_prev_q_1[i+1] = '0;
		// rem_sum_prev_q_0[i] = '0;
		// rem_sum_prev_q_0[i+1] = '0;
		// rem_sum_prev_q_1[i] = '0;
		// rem_sum_prev_q_1[i+1] = '0;
		// quo_iter[i] = '0;
		// quo_iter[i+1] = '0;
		// q_prev_q_0[i] = '0;
		// q_prev_q_0[i+1] = '0;
		// q_prev_q_1[i] = '0;
		// q_prev_q_1[i+1] = '0;
		// force_q_to_zero[i] = '0;
		// force_q_to_zero[i+1] = '0;
		// force_q_to_zero_prev_q_0[i] = '0;
		// force_q_to_zero_prev_q_0[1+1] = '0;
		// force_q_to_zero_prev_q_1[i] = '0;
		// force_q_to_zero_prev_q_1[1+1] = '0;

		// stage[2n]
		{rem_cout[i], rem_sum[i][i:0]} = 
		  {1'b0, rem[i-1][i-1:0], dividend_abs[63-i]}
		+ {1'b0, {(i + 1){~divisor_sign}} ^ D[i:0]}
		+ {{(i + 1){1'b0}}, ~divisor_sign};		
		force_q_to_zero[i] = D_msb_to_lsb_flag[i] | D_lsb_to_msb_flag[i];
		quo_iter[i] = force_q_to_zero[i] ? 1'b0 : rem_cout[i];
		rem[i][i:0] = quo_iter[i] ? rem_sum[i][i:0] : {rem[i-1][i-1:0], dividend_abs[63-i]};

		// stage[2n + 1], assume previous quo is 0
		{rem_cout_prev_q_0[i+1], rem_sum_prev_q_0[i+1][i+1:0]} = 
		  {1'b0, rem[i-1][i-1:0], dividend_abs[63-i -: 2]}
		+ {1'b0, {(i + 2){~divisor_sign}} ^ D[i+1:0]}
		+ {{(i + 2){1'b0}}, ~divisor_sign};
		force_q_to_zero_prev_q_0[i+1] = D_msb_to_lsb_flag[i+1] | D_lsb_to_msb_flag[i+1];
		q_prev_q_0[i+1] = force_q_to_zero_prev_q_0[i+1] ? 1'b0 : rem_cout_prev_q_0[i+1];
		rem_prev_q_0[i+1][i+1:0] = q_prev_q_0[i+1] ? rem_sum_prev_q_0[i+1][i+1:0] : {rem[i-1][i-1:0], dividend_abs[63-i -: 2]};

		// stage[2n + 1], assume previous quo is 1
		{rem_cout_prev_q_1[i+1], rem_sum_prev_q_1[i+1][i+1:0]} = 
		  {1'b0, rem[i-1][i-1:0], dividend_abs[63-i -: 2]}
		+ {1'b0, {(i + 2){~divisor_sign}} ^ D_times_3[i+1:0]}
		+ {{(i + 2){1'b0}}, ~divisor_sign};
		force_q_to_zero_prev_q_1[i+1] = D_times_3_msb_to_lsb_flag[i+1] | D_times_3_lsb_to_msb_flag[i+1];
		q_prev_q_1[i+1] = force_q_to_zero_prev_q_1[i+1] ? 1'b0 : rem_cout_prev_q_1[i+1];
		// Since we assume quo of stage[2n] is 1, so the rem of stage[2n] must be rem_sum[i]
		rem_prev_q_1[i+1][i+1:0] = q_prev_q_1[i+1] ? rem_sum_prev_q_1[i+1][i+1:0] : {rem_sum[i][i:0], dividend_abs[63-1-i]};

		quo_iter[i+1] = quo_iter[i] ? q_prev_q_1[i+1] : q_prev_q_0[i+1];
		rem[i+1][i+1:0] = quo_iter[i] ? rem_prev_q_1[i+1][i+1:0] : rem_prev_q_0[i+1][i+1:0];
	end
end

for(i = 0; i < 64; i = i + 1) begin: g_quo_reverse
	assign final_quo_pre[i] = quo_iter[63 - i];
end

assign final_quo = quo_sign ? -final_quo_pre : final_quo_pre;
assign final_rem = rem_sign ? -rem[63] : rem[63];

assign divisor_is_zero_o = (divisor_i == '0);
assign quotient_o = divisor_is_zero_o ? {(64){1'b1}} : final_quo;
assign remainder_o = divisor_is_zero_o ? dividend_i : final_rem;


endmodule
