// ========================================================================================================
// File Name			: int64_div_cla3.sv
// Author				: Yifei He
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-10-29 10:21:29
// Last Modified Time   : 2021-11-01 15:50:36
// ========================================================================================================
// Description	:
// Radix-8 restoring interger division algorithm.
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

module int64_div_cla3 #(
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
logic [(64 + 3)-1:0] D_times_5;
logic [(64 + 3)-1:0] D_times_7;

logic [64-1:0] rem [64-1:0];
logic [64-1:0] rem_prev_q_0 [64-1:0];
logic [64-1:0] rem_prev_q_1 [64-1:0];
logic [64-1:0] rem_prev_q_00 [64-1:0];
logic [64-1:0] rem_prev_q_01 [64-1:0];
logic [64-1:0] rem_prev_q_10 [64-1:0];
logic [64-1:0] rem_prev_q_11 [64-1:0];

logic rem_cout [64-1:0];
logic rem_cout_prev_q_0 [64-1:0];
logic rem_cout_prev_q_1 [64-1:0];
logic rem_cout_prev_q_00 [64-1:0];
logic rem_cout_prev_q_01 [64-1:0];
logic rem_cout_prev_q_10 [64-1:0];
logic rem_cout_prev_q_11 [64-1:0];

logic [64-1:0] rem_sum [64-1:0];
logic [64-1:0] rem_sum_prev_q_0 [64-1:0];
logic [64-1:0] rem_sum_prev_q_1 [64-1:0];
logic [64-1:0] rem_sum_prev_q_00 [64-1:0];
logic [64-1:0] rem_sum_prev_q_01 [64-1:0];
logic [64-1:0] rem_sum_prev_q_10 [64-1:0];
logic [64-1:0] rem_sum_prev_q_11 [64-1:0];

logic [64-1:0] quo_iter;
logic q_prev_q_0 [64-1:0];
logic q_prev_q_1 [64-1:0];
logic q_prev_q_00 [64-1:0];
logic q_prev_q_01 [64-1:0];
logic q_prev_q_10 [64-1:0];
logic q_prev_q_11 [64-1:0];

logic force_q_to_zero [64-1:0];
logic force_q_to_zero_prev_q_0 [64-1:0];
logic force_q_to_zero_prev_q_1 [64-1:0];
logic force_q_to_zero_prev_q_00 [64-1:0];
logic force_q_to_zero_prev_q_01 [64-1:0];
logic force_q_to_zero_prev_q_10 [64-1:0];
logic force_q_to_zero_prev_q_11 [64-1:0];

logic D_msb_to_lsb_flag [64-1:0];
logic D_lsb_to_msb_flag [64-1:0];

logic D_times_3_msb_to_lsb_flag [64-1:0];
logic D_times_3_lsb_to_msb_flag [64-1:0];
logic D_times_5_msb_to_lsb_flag [64-1:0];
logic D_times_5_lsb_to_msb_flag [64-1:0];
logic D_times_7_msb_to_lsb_flag [64-1:0];
logic D_times_7_lsb_to_msb_flag [64-1:0];

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
assign D_times_3[(64 + 2)-1:0] = {D[63], D[63], D} + {D[63], D, 1'b0};
assign D_times_5[(64 + 3)-1:0] = {D[63], D[63], D[63], D} + {D[63], D, 2'b0};
assign D_times_7[(64 + 3)-1:0] = {D[63], D[63], D[63], D} + {D[63], D, 2'b0} + {D[63], D[63], D, 1'b0};

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

// Only useful in stage[1, 2, 4, 5, 7, 8, ..., 61, 62]
assign D_times_3_msb_to_lsb_flag[ 0] = 1'b0;
assign D_times_3_msb_to_lsb_flag[ 1] = ~divisor_sign ? |(D_times_3[65: 2]) : ~(&(D_times_3[64: 2]));
assign D_times_3_msb_to_lsb_flag[ 2] = ~divisor_sign ? |(D_times_3[65: 3]) : ~(&(D_times_3[64: 3]));
assign D_times_3_msb_to_lsb_flag[ 3] = 1'b0;
assign D_times_3_msb_to_lsb_flag[ 4] = ~divisor_sign ? |(D_times_3[65: 5]) : ~(&(D_times_3[64: 5]));
assign D_times_3_msb_to_lsb_flag[ 5] = ~divisor_sign ? |(D_times_3[65: 6]) : ~(&(D_times_3[64: 6]));
assign D_times_3_msb_to_lsb_flag[ 6] = 1'b0;
assign D_times_3_msb_to_lsb_flag[ 7] = ~divisor_sign ? |(D_times_3[65: 8]) : ~(&(D_times_3[64: 8]));
assign D_times_3_msb_to_lsb_flag[ 8] = ~divisor_sign ? |(D_times_3[65: 9]) : ~(&(D_times_3[64: 9]));
assign D_times_3_msb_to_lsb_flag[ 9] = 1'b0;
assign D_times_3_msb_to_lsb_flag[10] = ~divisor_sign ? |(D_times_3[65:11]) : ~(&(D_times_3[64:11]));
assign D_times_3_msb_to_lsb_flag[11] = ~divisor_sign ? |(D_times_3[65:12]) : ~(&(D_times_3[64:12]));
assign D_times_3_msb_to_lsb_flag[12] = 1'b0;
assign D_times_3_msb_to_lsb_flag[13] = ~divisor_sign ? |(D_times_3[65:14]) : ~(&(D_times_3[64:14]));
assign D_times_3_msb_to_lsb_flag[14] = ~divisor_sign ? |(D_times_3[65:15]) : ~(&(D_times_3[64:15]));
assign D_times_3_msb_to_lsb_flag[15] = 1'b0;
assign D_times_3_msb_to_lsb_flag[16] = ~divisor_sign ? |(D_times_3[65:17]) : ~(&(D_times_3[64:17]));
assign D_times_3_msb_to_lsb_flag[17] = ~divisor_sign ? |(D_times_3[65:18]) : ~(&(D_times_3[64:18]));
assign D_times_3_msb_to_lsb_flag[18] = 1'b0;
assign D_times_3_msb_to_lsb_flag[19] = ~divisor_sign ? |(D_times_3[65:20]) : ~(&(D_times_3[64:20]));
assign D_times_3_msb_to_lsb_flag[20] = ~divisor_sign ? |(D_times_3[65:21]) : ~(&(D_times_3[64:21]));
assign D_times_3_msb_to_lsb_flag[21] = 1'b0;
assign D_times_3_msb_to_lsb_flag[22] = ~divisor_sign ? |(D_times_3[65:23]) : ~(&(D_times_3[64:23]));
assign D_times_3_msb_to_lsb_flag[23] = ~divisor_sign ? |(D_times_3[65:24]) : ~(&(D_times_3[64:24]));
assign D_times_3_msb_to_lsb_flag[24] = 1'b0;
assign D_times_3_msb_to_lsb_flag[25] = ~divisor_sign ? |(D_times_3[65:26]) : ~(&(D_times_3[64:26]));
assign D_times_3_msb_to_lsb_flag[26] = ~divisor_sign ? |(D_times_3[65:27]) : ~(&(D_times_3[64:27]));
assign D_times_3_msb_to_lsb_flag[27] = 1'b0;
assign D_times_3_msb_to_lsb_flag[28] = ~divisor_sign ? |(D_times_3[65:29]) : ~(&(D_times_3[64:29]));
assign D_times_3_msb_to_lsb_flag[29] = ~divisor_sign ? |(D_times_3[65:30]) : ~(&(D_times_3[64:30]));
assign D_times_3_msb_to_lsb_flag[30] = 1'b0;
assign D_times_3_msb_to_lsb_flag[31] = ~divisor_sign ? |(D_times_3[65:32]) : ~(&(D_times_3[64:32]));
assign D_times_3_msb_to_lsb_flag[32] = ~divisor_sign ? |(D_times_3[65:33]) : ~(&(D_times_3[64:33]));
assign D_times_3_msb_to_lsb_flag[33] = 1'b0;
assign D_times_3_msb_to_lsb_flag[34] = ~divisor_sign ? |(D_times_3[65:35]) : ~(&(D_times_3[64:35]));
assign D_times_3_msb_to_lsb_flag[35] = ~divisor_sign ? |(D_times_3[65:36]) : ~(&(D_times_3[64:36]));
assign D_times_3_msb_to_lsb_flag[36] = 1'b0;
assign D_times_3_msb_to_lsb_flag[37] = ~divisor_sign ? |(D_times_3[65:38]) : ~(&(D_times_3[64:38]));
assign D_times_3_msb_to_lsb_flag[38] = ~divisor_sign ? |(D_times_3[65:39]) : ~(&(D_times_3[64:39]));
assign D_times_3_msb_to_lsb_flag[39] = 1'b0;
assign D_times_3_msb_to_lsb_flag[40] = ~divisor_sign ? |(D_times_3[65:41]) : ~(&(D_times_3[64:41]));
assign D_times_3_msb_to_lsb_flag[41] = ~divisor_sign ? |(D_times_3[65:42]) : ~(&(D_times_3[64:42]));
assign D_times_3_msb_to_lsb_flag[42] = 1'b0;
assign D_times_3_msb_to_lsb_flag[43] = ~divisor_sign ? |(D_times_3[65:44]) : ~(&(D_times_3[64:44]));
assign D_times_3_msb_to_lsb_flag[44] = ~divisor_sign ? |(D_times_3[65:45]) : ~(&(D_times_3[64:45]));
assign D_times_3_msb_to_lsb_flag[45] = 1'b0;
assign D_times_3_msb_to_lsb_flag[46] = ~divisor_sign ? |(D_times_3[65:47]) : ~(&(D_times_3[64:47]));
assign D_times_3_msb_to_lsb_flag[47] = ~divisor_sign ? |(D_times_3[65:48]) : ~(&(D_times_3[64:48]));
assign D_times_3_msb_to_lsb_flag[48] = 1'b0;
assign D_times_3_msb_to_lsb_flag[49] = ~divisor_sign ? |(D_times_3[65:50]) : ~(&(D_times_3[64:50]));
assign D_times_3_msb_to_lsb_flag[50] = ~divisor_sign ? |(D_times_3[65:51]) : ~(&(D_times_3[64:51]));
assign D_times_3_msb_to_lsb_flag[51] = 1'b0;
assign D_times_3_msb_to_lsb_flag[52] = ~divisor_sign ? |(D_times_3[65:53]) : ~(&(D_times_3[64:53]));
assign D_times_3_msb_to_lsb_flag[53] = ~divisor_sign ? |(D_times_3[65:54]) : ~(&(D_times_3[64:54]));
assign D_times_3_msb_to_lsb_flag[54] = 1'b0;
assign D_times_3_msb_to_lsb_flag[55] = ~divisor_sign ? |(D_times_3[65:56]) : ~(&(D_times_3[64:56]));
assign D_times_3_msb_to_lsb_flag[56] = ~divisor_sign ? |(D_times_3[65:57]) : ~(&(D_times_3[64:57]));
assign D_times_3_msb_to_lsb_flag[57] = 1'b0;
assign D_times_3_msb_to_lsb_flag[58] = ~divisor_sign ? |(D_times_3[65:59]) : ~(&(D_times_3[64:59]));
assign D_times_3_msb_to_lsb_flag[59] = ~divisor_sign ? |(D_times_3[65:60]) : ~(&(D_times_3[64:60]));
assign D_times_3_msb_to_lsb_flag[60] = 1'b0;
assign D_times_3_msb_to_lsb_flag[61] = ~divisor_sign ? |(D_times_3[65:62]) : ~(&(D_times_3[64:62]));
assign D_times_3_msb_to_lsb_flag[62] = ~divisor_sign ? |(D_times_3[65:63]) : ~(&(D_times_3[64:63]));
assign D_times_3_msb_to_lsb_flag[63] = 1'b0;

// Only useful in stage[1, 2, 4, 5, 7, 8, ..., 61, 62], when D < 0.
assign D_times_3_lsb_to_msb_flag[ 0] = 1'b0;
assign D_times_3_lsb_to_msb_flag[ 1] = divisor_sign ? ~(|(D_times_3[ 1:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[ 2] = divisor_sign ? ~(|(D_times_3[ 2:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[ 3] = 1'b0;
assign D_times_3_lsb_to_msb_flag[ 4] = divisor_sign ? ~(|(D_times_3[ 4:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[ 5] = divisor_sign ? ~(|(D_times_3[ 5:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[ 6] = 1'b0;
assign D_times_3_lsb_to_msb_flag[ 7] = divisor_sign ? ~(|(D_times_3[ 7:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[ 8] = divisor_sign ? ~(|(D_times_3[ 8:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[ 9] = 1'b0;
assign D_times_3_lsb_to_msb_flag[10] = divisor_sign ? ~(|(D_times_3[10:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[11] = divisor_sign ? ~(|(D_times_3[11:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[12] = 1'b0;
assign D_times_3_lsb_to_msb_flag[13] = divisor_sign ? ~(|(D_times_3[13:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[14] = divisor_sign ? ~(|(D_times_3[14:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[15] = 1'b0;
assign D_times_3_lsb_to_msb_flag[16] = divisor_sign ? ~(|(D_times_3[16:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[17] = divisor_sign ? ~(|(D_times_3[17:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[18] = 1'b0;
assign D_times_3_lsb_to_msb_flag[19] = divisor_sign ? ~(|(D_times_3[19:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[20] = divisor_sign ? ~(|(D_times_3[20:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[21] = 1'b0;
assign D_times_3_lsb_to_msb_flag[22] = divisor_sign ? ~(|(D_times_3[22:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[23] = divisor_sign ? ~(|(D_times_3[23:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[24] = 1'b0;
assign D_times_3_lsb_to_msb_flag[25] = divisor_sign ? ~(|(D_times_3[25:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[26] = divisor_sign ? ~(|(D_times_3[26:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[27] = 1'b0;
assign D_times_3_lsb_to_msb_flag[28] = divisor_sign ? ~(|(D_times_3[28:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[29] = divisor_sign ? ~(|(D_times_3[29:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[30] = 1'b0;
assign D_times_3_lsb_to_msb_flag[31] = divisor_sign ? ~(|(D_times_3[31:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[32] = divisor_sign ? ~(|(D_times_3[32:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[33] = 1'b0;
assign D_times_3_lsb_to_msb_flag[34] = divisor_sign ? ~(|(D_times_3[34:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[35] = divisor_sign ? ~(|(D_times_3[35:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[36] = 1'b0;
assign D_times_3_lsb_to_msb_flag[37] = divisor_sign ? ~(|(D_times_3[37:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[38] = divisor_sign ? ~(|(D_times_3[38:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[39] = 1'b0;
assign D_times_3_lsb_to_msb_flag[40] = divisor_sign ? ~(|(D_times_3[40:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[41] = divisor_sign ? ~(|(D_times_3[41:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[42] = 1'b0;
assign D_times_3_lsb_to_msb_flag[43] = divisor_sign ? ~(|(D_times_3[43:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[44] = divisor_sign ? ~(|(D_times_3[44:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[45] = 1'b0;
assign D_times_3_lsb_to_msb_flag[46] = divisor_sign ? ~(|(D_times_3[46:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[47] = divisor_sign ? ~(|(D_times_3[47:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[48] = 1'b0;
assign D_times_3_lsb_to_msb_flag[49] = divisor_sign ? ~(|(D_times_3[49:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[50] = divisor_sign ? ~(|(D_times_3[50:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[51] = 1'b0;
assign D_times_3_lsb_to_msb_flag[52] = divisor_sign ? ~(|(D_times_3[52:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[53] = divisor_sign ? ~(|(D_times_3[53:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[54] = 1'b0;
assign D_times_3_lsb_to_msb_flag[55] = divisor_sign ? ~(|(D_times_3[55:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[56] = divisor_sign ? ~(|(D_times_3[56:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[57] = 1'b0;
assign D_times_3_lsb_to_msb_flag[58] = divisor_sign ? ~(|(D_times_3[58:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[59] = divisor_sign ? ~(|(D_times_3[59:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[60] = 1'b0;
assign D_times_3_lsb_to_msb_flag[61] = divisor_sign ? ~(|(D_times_3[61:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[62] = divisor_sign ? ~(|(D_times_3[62:0])) : 1'b0;
assign D_times_3_lsb_to_msb_flag[63] = 1'b0;

// Only useful in stage[1, 2, 4, 5, 7, 8, ..., 61, 62]
assign D_times_5_msb_to_lsb_flag[ 0] = 1'b0;
assign D_times_5_msb_to_lsb_flag[ 1] = ~divisor_sign ? |(D_times_5[66: 2]) : ~(&(D_times_5[65: 2]));
assign D_times_5_msb_to_lsb_flag[ 2] = ~divisor_sign ? |(D_times_5[66: 3]) : ~(&(D_times_5[65: 3]));
assign D_times_5_msb_to_lsb_flag[ 3] = 1'b0;
assign D_times_5_msb_to_lsb_flag[ 4] = ~divisor_sign ? |(D_times_5[66: 5]) : ~(&(D_times_5[65: 5]));
assign D_times_5_msb_to_lsb_flag[ 5] = ~divisor_sign ? |(D_times_5[66: 6]) : ~(&(D_times_5[65: 6]));
assign D_times_5_msb_to_lsb_flag[ 6] = 1'b0;
assign D_times_5_msb_to_lsb_flag[ 7] = ~divisor_sign ? |(D_times_5[66: 8]) : ~(&(D_times_5[65: 8]));
assign D_times_5_msb_to_lsb_flag[ 8] = ~divisor_sign ? |(D_times_5[66: 9]) : ~(&(D_times_5[65: 9]));
assign D_times_5_msb_to_lsb_flag[ 9] = 1'b0;
assign D_times_5_msb_to_lsb_flag[10] = ~divisor_sign ? |(D_times_5[66:11]) : ~(&(D_times_5[65:11]));
assign D_times_5_msb_to_lsb_flag[11] = ~divisor_sign ? |(D_times_5[66:12]) : ~(&(D_times_5[65:12]));
assign D_times_5_msb_to_lsb_flag[12] = 1'b0;
assign D_times_5_msb_to_lsb_flag[13] = ~divisor_sign ? |(D_times_5[66:14]) : ~(&(D_times_5[65:14]));
assign D_times_5_msb_to_lsb_flag[14] = ~divisor_sign ? |(D_times_5[66:15]) : ~(&(D_times_5[65:15]));
assign D_times_5_msb_to_lsb_flag[15] = 1'b0;
assign D_times_5_msb_to_lsb_flag[16] = ~divisor_sign ? |(D_times_5[66:17]) : ~(&(D_times_5[65:17]));
assign D_times_5_msb_to_lsb_flag[17] = ~divisor_sign ? |(D_times_5[66:18]) : ~(&(D_times_5[65:18]));
assign D_times_5_msb_to_lsb_flag[18] = 1'b0;
assign D_times_5_msb_to_lsb_flag[19] = ~divisor_sign ? |(D_times_5[66:20]) : ~(&(D_times_5[65:20]));
assign D_times_5_msb_to_lsb_flag[20] = ~divisor_sign ? |(D_times_5[66:21]) : ~(&(D_times_5[65:21]));
assign D_times_5_msb_to_lsb_flag[21] = 1'b0;
assign D_times_5_msb_to_lsb_flag[22] = ~divisor_sign ? |(D_times_5[66:23]) : ~(&(D_times_5[65:23]));
assign D_times_5_msb_to_lsb_flag[23] = ~divisor_sign ? |(D_times_5[66:24]) : ~(&(D_times_5[65:24]));
assign D_times_5_msb_to_lsb_flag[24] = 1'b0;
assign D_times_5_msb_to_lsb_flag[25] = ~divisor_sign ? |(D_times_5[66:26]) : ~(&(D_times_5[65:26]));
assign D_times_5_msb_to_lsb_flag[26] = ~divisor_sign ? |(D_times_5[66:27]) : ~(&(D_times_5[65:27]));
assign D_times_5_msb_to_lsb_flag[27] = 1'b0;
assign D_times_5_msb_to_lsb_flag[28] = ~divisor_sign ? |(D_times_5[66:29]) : ~(&(D_times_5[65:29]));
assign D_times_5_msb_to_lsb_flag[29] = ~divisor_sign ? |(D_times_5[66:30]) : ~(&(D_times_5[65:30]));
assign D_times_5_msb_to_lsb_flag[30] = 1'b0;
assign D_times_5_msb_to_lsb_flag[31] = ~divisor_sign ? |(D_times_5[66:32]) : ~(&(D_times_5[65:32]));
assign D_times_5_msb_to_lsb_flag[32] = ~divisor_sign ? |(D_times_5[66:33]) : ~(&(D_times_5[65:33]));
assign D_times_5_msb_to_lsb_flag[33] = 1'b0;
assign D_times_5_msb_to_lsb_flag[34] = ~divisor_sign ? |(D_times_5[66:35]) : ~(&(D_times_5[65:35]));
assign D_times_5_msb_to_lsb_flag[35] = ~divisor_sign ? |(D_times_5[66:36]) : ~(&(D_times_5[65:36]));
assign D_times_5_msb_to_lsb_flag[36] = 1'b0;
assign D_times_5_msb_to_lsb_flag[37] = ~divisor_sign ? |(D_times_5[66:38]) : ~(&(D_times_5[65:38]));
assign D_times_5_msb_to_lsb_flag[38] = ~divisor_sign ? |(D_times_5[66:39]) : ~(&(D_times_5[65:39]));
assign D_times_5_msb_to_lsb_flag[39] = 1'b0;
assign D_times_5_msb_to_lsb_flag[40] = ~divisor_sign ? |(D_times_5[66:41]) : ~(&(D_times_5[65:41]));
assign D_times_5_msb_to_lsb_flag[41] = ~divisor_sign ? |(D_times_5[66:42]) : ~(&(D_times_5[65:42]));
assign D_times_5_msb_to_lsb_flag[42] = 1'b0;
assign D_times_5_msb_to_lsb_flag[43] = ~divisor_sign ? |(D_times_5[66:44]) : ~(&(D_times_5[65:44]));
assign D_times_5_msb_to_lsb_flag[44] = ~divisor_sign ? |(D_times_5[66:45]) : ~(&(D_times_5[65:45]));
assign D_times_5_msb_to_lsb_flag[45] = 1'b0;
assign D_times_5_msb_to_lsb_flag[46] = ~divisor_sign ? |(D_times_5[66:47]) : ~(&(D_times_5[65:47]));
assign D_times_5_msb_to_lsb_flag[47] = ~divisor_sign ? |(D_times_5[66:48]) : ~(&(D_times_5[65:48]));
assign D_times_5_msb_to_lsb_flag[48] = 1'b0;
assign D_times_5_msb_to_lsb_flag[49] = ~divisor_sign ? |(D_times_5[66:50]) : ~(&(D_times_5[65:50]));
assign D_times_5_msb_to_lsb_flag[50] = ~divisor_sign ? |(D_times_5[66:51]) : ~(&(D_times_5[65:51]));
assign D_times_5_msb_to_lsb_flag[51] = 1'b0;
assign D_times_5_msb_to_lsb_flag[52] = ~divisor_sign ? |(D_times_5[66:53]) : ~(&(D_times_5[65:53]));
assign D_times_5_msb_to_lsb_flag[53] = ~divisor_sign ? |(D_times_5[66:54]) : ~(&(D_times_5[65:54]));
assign D_times_5_msb_to_lsb_flag[54] = 1'b0;
assign D_times_5_msb_to_lsb_flag[55] = ~divisor_sign ? |(D_times_5[66:56]) : ~(&(D_times_5[65:56]));
assign D_times_5_msb_to_lsb_flag[56] = ~divisor_sign ? |(D_times_5[66:57]) : ~(&(D_times_5[65:57]));
assign D_times_5_msb_to_lsb_flag[57] = 1'b0;
assign D_times_5_msb_to_lsb_flag[58] = ~divisor_sign ? |(D_times_5[66:59]) : ~(&(D_times_5[65:59]));
assign D_times_5_msb_to_lsb_flag[59] = ~divisor_sign ? |(D_times_5[66:60]) : ~(&(D_times_5[65:60]));
assign D_times_5_msb_to_lsb_flag[60] = 1'b0;
assign D_times_5_msb_to_lsb_flag[61] = ~divisor_sign ? |(D_times_5[66:62]) : ~(&(D_times_5[65:62]));
assign D_times_5_msb_to_lsb_flag[62] = ~divisor_sign ? |(D_times_5[66:63]) : ~(&(D_times_5[65:63]));
assign D_times_5_msb_to_lsb_flag[63] = 1'b0;

// Only useful in stage[1, 2, 4, 5, 7, 8, ..., 61, 62], when D < 0.
assign D_times_5_lsb_to_msb_flag[ 0] = 1'b0;
assign D_times_5_lsb_to_msb_flag[ 1] = divisor_sign ? ~(|(D_times_5[ 1:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[ 2] = divisor_sign ? ~(|(D_times_5[ 2:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[ 3] = 1'b0;
assign D_times_5_lsb_to_msb_flag[ 4] = divisor_sign ? ~(|(D_times_5[ 4:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[ 5] = divisor_sign ? ~(|(D_times_5[ 5:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[ 6] = 1'b0;
assign D_times_5_lsb_to_msb_flag[ 7] = divisor_sign ? ~(|(D_times_5[ 7:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[ 8] = divisor_sign ? ~(|(D_times_5[ 8:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[ 9] = 1'b0;
assign D_times_5_lsb_to_msb_flag[10] = divisor_sign ? ~(|(D_times_5[10:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[11] = divisor_sign ? ~(|(D_times_5[11:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[12] = 1'b0;
assign D_times_5_lsb_to_msb_flag[13] = divisor_sign ? ~(|(D_times_5[13:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[14] = divisor_sign ? ~(|(D_times_5[14:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[15] = 1'b0;
assign D_times_5_lsb_to_msb_flag[16] = divisor_sign ? ~(|(D_times_5[16:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[17] = divisor_sign ? ~(|(D_times_5[17:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[18] = 1'b0;
assign D_times_5_lsb_to_msb_flag[19] = divisor_sign ? ~(|(D_times_5[19:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[20] = divisor_sign ? ~(|(D_times_5[20:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[21] = 1'b0;
assign D_times_5_lsb_to_msb_flag[22] = divisor_sign ? ~(|(D_times_5[22:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[23] = divisor_sign ? ~(|(D_times_5[23:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[24] = 1'b0;
assign D_times_5_lsb_to_msb_flag[25] = divisor_sign ? ~(|(D_times_5[25:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[26] = divisor_sign ? ~(|(D_times_5[26:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[27] = 1'b0;
assign D_times_5_lsb_to_msb_flag[28] = divisor_sign ? ~(|(D_times_5[28:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[29] = divisor_sign ? ~(|(D_times_5[29:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[30] = 1'b0;
assign D_times_5_lsb_to_msb_flag[31] = divisor_sign ? ~(|(D_times_5[31:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[32] = divisor_sign ? ~(|(D_times_5[32:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[33] = 1'b0;
assign D_times_5_lsb_to_msb_flag[34] = divisor_sign ? ~(|(D_times_5[34:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[35] = divisor_sign ? ~(|(D_times_5[35:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[36] = 1'b0;
assign D_times_5_lsb_to_msb_flag[37] = divisor_sign ? ~(|(D_times_5[37:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[38] = divisor_sign ? ~(|(D_times_5[38:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[39] = 1'b0;
assign D_times_5_lsb_to_msb_flag[40] = divisor_sign ? ~(|(D_times_5[40:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[41] = divisor_sign ? ~(|(D_times_5[41:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[42] = 1'b0;
assign D_times_5_lsb_to_msb_flag[43] = divisor_sign ? ~(|(D_times_5[43:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[44] = divisor_sign ? ~(|(D_times_5[44:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[45] = 1'b0;
assign D_times_5_lsb_to_msb_flag[46] = divisor_sign ? ~(|(D_times_5[46:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[47] = divisor_sign ? ~(|(D_times_5[47:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[48] = 1'b0;
assign D_times_5_lsb_to_msb_flag[49] = divisor_sign ? ~(|(D_times_5[49:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[50] = divisor_sign ? ~(|(D_times_5[50:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[51] = 1'b0;
assign D_times_5_lsb_to_msb_flag[52] = divisor_sign ? ~(|(D_times_5[52:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[53] = divisor_sign ? ~(|(D_times_5[53:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[54] = 1'b0;
assign D_times_5_lsb_to_msb_flag[55] = divisor_sign ? ~(|(D_times_5[55:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[56] = divisor_sign ? ~(|(D_times_5[56:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[57] = 1'b0;
assign D_times_5_lsb_to_msb_flag[58] = divisor_sign ? ~(|(D_times_5[58:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[59] = divisor_sign ? ~(|(D_times_5[59:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[60] = 1'b0;
assign D_times_5_lsb_to_msb_flag[61] = divisor_sign ? ~(|(D_times_5[61:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[62] = divisor_sign ? ~(|(D_times_5[62:0])) : 1'b0;
assign D_times_5_lsb_to_msb_flag[63] = 1'b0;

// Only useful in stage[1, 2, 4, 5, 7, 8, ..., 61, 62]
assign D_times_7_msb_to_lsb_flag[ 0] = 1'b0;
assign D_times_7_msb_to_lsb_flag[ 1] = ~divisor_sign ? |(D_times_7[66: 2]) : ~(&(D_times_7[65: 2]));
assign D_times_7_msb_to_lsb_flag[ 2] = ~divisor_sign ? |(D_times_7[66: 3]) : ~(&(D_times_7[65: 3]));
assign D_times_7_msb_to_lsb_flag[ 3] = 1'b0;
assign D_times_7_msb_to_lsb_flag[ 4] = ~divisor_sign ? |(D_times_7[66: 5]) : ~(&(D_times_7[65: 5]));
assign D_times_7_msb_to_lsb_flag[ 5] = ~divisor_sign ? |(D_times_7[66: 6]) : ~(&(D_times_7[65: 6]));
assign D_times_7_msb_to_lsb_flag[ 6] = 1'b0;
assign D_times_7_msb_to_lsb_flag[ 7] = ~divisor_sign ? |(D_times_7[66: 8]) : ~(&(D_times_7[65: 8]));
assign D_times_7_msb_to_lsb_flag[ 8] = ~divisor_sign ? |(D_times_7[66: 9]) : ~(&(D_times_7[65: 9]));
assign D_times_7_msb_to_lsb_flag[ 9] = 1'b0;
assign D_times_7_msb_to_lsb_flag[10] = ~divisor_sign ? |(D_times_7[66:11]) : ~(&(D_times_7[65:11]));
assign D_times_7_msb_to_lsb_flag[11] = ~divisor_sign ? |(D_times_7[66:12]) : ~(&(D_times_7[65:12]));
assign D_times_7_msb_to_lsb_flag[12] = 1'b0;
assign D_times_7_msb_to_lsb_flag[13] = ~divisor_sign ? |(D_times_7[66:14]) : ~(&(D_times_7[65:14]));
assign D_times_7_msb_to_lsb_flag[14] = ~divisor_sign ? |(D_times_7[66:15]) : ~(&(D_times_7[65:15]));
assign D_times_7_msb_to_lsb_flag[15] = 1'b0;
assign D_times_7_msb_to_lsb_flag[16] = ~divisor_sign ? |(D_times_7[66:17]) : ~(&(D_times_7[65:17]));
assign D_times_7_msb_to_lsb_flag[17] = ~divisor_sign ? |(D_times_7[66:18]) : ~(&(D_times_7[65:18]));
assign D_times_7_msb_to_lsb_flag[18] = 1'b0;
assign D_times_7_msb_to_lsb_flag[19] = ~divisor_sign ? |(D_times_7[66:20]) : ~(&(D_times_7[65:20]));
assign D_times_7_msb_to_lsb_flag[20] = ~divisor_sign ? |(D_times_7[66:21]) : ~(&(D_times_7[65:21]));
assign D_times_7_msb_to_lsb_flag[21] = 1'b0;
assign D_times_7_msb_to_lsb_flag[22] = ~divisor_sign ? |(D_times_7[66:23]) : ~(&(D_times_7[65:23]));
assign D_times_7_msb_to_lsb_flag[23] = ~divisor_sign ? |(D_times_7[66:24]) : ~(&(D_times_7[65:24]));
assign D_times_7_msb_to_lsb_flag[24] = 1'b0;
assign D_times_7_msb_to_lsb_flag[25] = ~divisor_sign ? |(D_times_7[66:26]) : ~(&(D_times_7[65:26]));
assign D_times_7_msb_to_lsb_flag[26] = ~divisor_sign ? |(D_times_7[66:27]) : ~(&(D_times_7[65:27]));
assign D_times_7_msb_to_lsb_flag[27] = 1'b0;
assign D_times_7_msb_to_lsb_flag[28] = ~divisor_sign ? |(D_times_7[66:29]) : ~(&(D_times_7[65:29]));
assign D_times_7_msb_to_lsb_flag[29] = ~divisor_sign ? |(D_times_7[66:30]) : ~(&(D_times_7[65:30]));
assign D_times_7_msb_to_lsb_flag[30] = 1'b0;
assign D_times_7_msb_to_lsb_flag[31] = ~divisor_sign ? |(D_times_7[66:32]) : ~(&(D_times_7[65:32]));
assign D_times_7_msb_to_lsb_flag[32] = ~divisor_sign ? |(D_times_7[66:33]) : ~(&(D_times_7[65:33]));
assign D_times_7_msb_to_lsb_flag[33] = 1'b0;
assign D_times_7_msb_to_lsb_flag[34] = ~divisor_sign ? |(D_times_7[66:35]) : ~(&(D_times_7[65:35]));
assign D_times_7_msb_to_lsb_flag[35] = ~divisor_sign ? |(D_times_7[66:36]) : ~(&(D_times_7[65:36]));
assign D_times_7_msb_to_lsb_flag[36] = 1'b0;
assign D_times_7_msb_to_lsb_flag[37] = ~divisor_sign ? |(D_times_7[66:38]) : ~(&(D_times_7[65:38]));
assign D_times_7_msb_to_lsb_flag[38] = ~divisor_sign ? |(D_times_7[66:39]) : ~(&(D_times_7[65:39]));
assign D_times_7_msb_to_lsb_flag[39] = 1'b0;
assign D_times_7_msb_to_lsb_flag[40] = ~divisor_sign ? |(D_times_7[66:41]) : ~(&(D_times_7[65:41]));
assign D_times_7_msb_to_lsb_flag[41] = ~divisor_sign ? |(D_times_7[66:42]) : ~(&(D_times_7[65:42]));
assign D_times_7_msb_to_lsb_flag[42] = 1'b0;
assign D_times_7_msb_to_lsb_flag[43] = ~divisor_sign ? |(D_times_7[66:44]) : ~(&(D_times_7[65:44]));
assign D_times_7_msb_to_lsb_flag[44] = ~divisor_sign ? |(D_times_7[66:45]) : ~(&(D_times_7[65:45]));
assign D_times_7_msb_to_lsb_flag[45] = 1'b0;
assign D_times_7_msb_to_lsb_flag[46] = ~divisor_sign ? |(D_times_7[66:47]) : ~(&(D_times_7[65:47]));
assign D_times_7_msb_to_lsb_flag[47] = ~divisor_sign ? |(D_times_7[66:48]) : ~(&(D_times_7[65:48]));
assign D_times_7_msb_to_lsb_flag[48] = 1'b0;
assign D_times_7_msb_to_lsb_flag[49] = ~divisor_sign ? |(D_times_7[66:50]) : ~(&(D_times_7[65:50]));
assign D_times_7_msb_to_lsb_flag[50] = ~divisor_sign ? |(D_times_7[66:51]) : ~(&(D_times_7[65:51]));
assign D_times_7_msb_to_lsb_flag[51] = 1'b0;
assign D_times_7_msb_to_lsb_flag[52] = ~divisor_sign ? |(D_times_7[66:53]) : ~(&(D_times_7[65:53]));
assign D_times_7_msb_to_lsb_flag[53] = ~divisor_sign ? |(D_times_7[66:54]) : ~(&(D_times_7[65:54]));
assign D_times_7_msb_to_lsb_flag[54] = 1'b0;
assign D_times_7_msb_to_lsb_flag[55] = ~divisor_sign ? |(D_times_7[66:56]) : ~(&(D_times_7[65:56]));
assign D_times_7_msb_to_lsb_flag[56] = ~divisor_sign ? |(D_times_7[66:57]) : ~(&(D_times_7[65:57]));
assign D_times_7_msb_to_lsb_flag[57] = 1'b0;
assign D_times_7_msb_to_lsb_flag[58] = ~divisor_sign ? |(D_times_7[66:59]) : ~(&(D_times_7[65:59]));
assign D_times_7_msb_to_lsb_flag[59] = ~divisor_sign ? |(D_times_7[66:60]) : ~(&(D_times_7[65:60]));
assign D_times_7_msb_to_lsb_flag[60] = 1'b0;
assign D_times_7_msb_to_lsb_flag[61] = ~divisor_sign ? |(D_times_7[66:62]) : ~(&(D_times_7[65:62]));
assign D_times_7_msb_to_lsb_flag[62] = ~divisor_sign ? |(D_times_7[66:63]) : ~(&(D_times_7[65:63]));
assign D_times_7_msb_to_lsb_flag[63] = 1'b0;

// Only useful in stage[1, 2, 4, 5, 7, 8, ..., 61, 62], when D < 0.
assign D_times_7_lsb_to_msb_flag[ 0] = 1'b0;
assign D_times_7_lsb_to_msb_flag[ 1] = divisor_sign ? ~(|(D_times_7[ 1:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[ 2] = divisor_sign ? ~(|(D_times_7[ 2:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[ 3] = 1'b0;
assign D_times_7_lsb_to_msb_flag[ 4] = divisor_sign ? ~(|(D_times_7[ 4:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[ 5] = divisor_sign ? ~(|(D_times_7[ 5:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[ 6] = 1'b0;
assign D_times_7_lsb_to_msb_flag[ 7] = divisor_sign ? ~(|(D_times_7[ 7:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[ 8] = divisor_sign ? ~(|(D_times_7[ 8:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[ 9] = 1'b0;
assign D_times_7_lsb_to_msb_flag[10] = divisor_sign ? ~(|(D_times_7[10:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[11] = divisor_sign ? ~(|(D_times_7[11:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[12] = 1'b0;
assign D_times_7_lsb_to_msb_flag[13] = divisor_sign ? ~(|(D_times_7[13:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[14] = divisor_sign ? ~(|(D_times_7[14:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[15] = 1'b0;
assign D_times_7_lsb_to_msb_flag[16] = divisor_sign ? ~(|(D_times_7[16:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[17] = divisor_sign ? ~(|(D_times_7[17:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[18] = 1'b0;
assign D_times_7_lsb_to_msb_flag[19] = divisor_sign ? ~(|(D_times_7[19:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[20] = divisor_sign ? ~(|(D_times_7[20:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[21] = 1'b0;
assign D_times_7_lsb_to_msb_flag[22] = divisor_sign ? ~(|(D_times_7[22:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[23] = divisor_sign ? ~(|(D_times_7[23:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[24] = 1'b0;
assign D_times_7_lsb_to_msb_flag[25] = divisor_sign ? ~(|(D_times_7[25:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[26] = divisor_sign ? ~(|(D_times_7[26:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[27] = 1'b0;
assign D_times_7_lsb_to_msb_flag[28] = divisor_sign ? ~(|(D_times_7[28:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[29] = divisor_sign ? ~(|(D_times_7[29:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[30] = 1'b0;
assign D_times_7_lsb_to_msb_flag[31] = divisor_sign ? ~(|(D_times_7[31:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[32] = divisor_sign ? ~(|(D_times_7[32:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[33] = 1'b0;
assign D_times_7_lsb_to_msb_flag[34] = divisor_sign ? ~(|(D_times_7[34:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[35] = divisor_sign ? ~(|(D_times_7[35:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[36] = 1'b0;
assign D_times_7_lsb_to_msb_flag[37] = divisor_sign ? ~(|(D_times_7[37:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[38] = divisor_sign ? ~(|(D_times_7[38:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[39] = 1'b0;
assign D_times_7_lsb_to_msb_flag[40] = divisor_sign ? ~(|(D_times_7[40:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[41] = divisor_sign ? ~(|(D_times_7[41:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[42] = 1'b0;
assign D_times_7_lsb_to_msb_flag[43] = divisor_sign ? ~(|(D_times_7[43:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[44] = divisor_sign ? ~(|(D_times_7[44:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[45] = 1'b0;
assign D_times_7_lsb_to_msb_flag[46] = divisor_sign ? ~(|(D_times_7[46:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[47] = divisor_sign ? ~(|(D_times_7[47:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[48] = 1'b0;
assign D_times_7_lsb_to_msb_flag[49] = divisor_sign ? ~(|(D_times_7[49:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[50] = divisor_sign ? ~(|(D_times_7[50:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[51] = 1'b0;
assign D_times_7_lsb_to_msb_flag[52] = divisor_sign ? ~(|(D_times_7[52:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[53] = divisor_sign ? ~(|(D_times_7[53:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[54] = 1'b0;
assign D_times_7_lsb_to_msb_flag[55] = divisor_sign ? ~(|(D_times_7[55:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[56] = divisor_sign ? ~(|(D_times_7[56:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[57] = 1'b0;
assign D_times_7_lsb_to_msb_flag[58] = divisor_sign ? ~(|(D_times_7[58:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[59] = divisor_sign ? ~(|(D_times_7[59:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[60] = 1'b0;
assign D_times_7_lsb_to_msb_flag[61] = divisor_sign ? ~(|(D_times_7[61:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[62] = divisor_sign ? ~(|(D_times_7[62:0])) : 1'b0;
assign D_times_7_lsb_to_msb_flag[63] = 1'b0;

// ==================================================================================================================================================
// stage[0, 1]
// ==================================================================================================================================================

// stage[0]
assign {rem_cout[0], rem_sum[0][0:0]} = 
  {1'b0, dividend_abs[63]}
+ {1'b0, {(1){~divisor_sign}} ^ D[0:0]}
+ {1'b0, ~divisor_sign};
assign force_q_to_zero[0] = D_msb_to_lsb_flag[0] | D_lsb_to_msb_flag[0];
assign quo_iter[0] = force_q_to_zero[0] ? 1'b0 : rem_cout[0];
// assign rem[0][0:0] = quo_iter[0] ? rem_sum[0][0:0] : dividend_abs[63];

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
assign rem_prev_q_1[1][1:0] = q_prev_q_1[1] ? rem_sum_prev_q_1[1][1:0] : {rem_sum[0][0:0], dividend_abs[62]};

// stage[2]
assign {rem_cout_prev_q_00[2], rem_sum_prev_q_00[2][2:0]} = 
  {1'b0, dividend_abs[63:61]}
+ {1'b0, {(3){~divisor_sign}} ^ D[2:0]}
+ {3'b0, ~divisor_sign};
assign force_q_to_zero_prev_q_00[2] = D_msb_to_lsb_flag[2] | D_lsb_to_msb_flag[2];
assign q_prev_q_00[2] = force_q_to_zero_prev_q_00[2] ? 1'b0 : rem_cout_prev_q_00[2];
assign rem_prev_q_00[2][2:0] = q_prev_q_00[2] ? rem_sum_prev_q_00[2][2:0] : dividend_abs[63:61];

assign {rem_cout_prev_q_01[2], rem_sum_prev_q_01[2][2:0]} = 
  {1'b0, dividend_abs[63:61]}
+ {1'b0, {(3){~divisor_sign}} ^ D_times_3[2:0]}
+ {3'b0, ~divisor_sign};
assign force_q_to_zero_prev_q_01[2] = D_times_3_msb_to_lsb_flag[2] | D_times_3_lsb_to_msb_flag[2];
assign q_prev_q_01[2] = force_q_to_zero_prev_q_01[2] ? 1'b0 : rem_cout_prev_q_01[2];
assign rem_prev_q_01[2][2:0] = q_prev_q_01[2] ? rem_sum_prev_q_01[2][2:0] : {rem_sum_prev_q_0[1][1:0], dividend_abs[61]};

assign {rem_cout_prev_q_10[2], rem_sum_prev_q_10[2][2:0]} = 
  {1'b0, dividend_abs[63:61]}
+ {1'b0, {(3){~divisor_sign}} ^ D_times_5[2:0]}
+ {3'b0, ~divisor_sign};
assign force_q_to_zero_prev_q_10[2] = D_times_5_msb_to_lsb_flag[2] | D_times_5_lsb_to_msb_flag[2];
assign q_prev_q_10[2] = force_q_to_zero_prev_q_10[2] ? 1'b0 : rem_cout_prev_q_10[2];
assign rem_prev_q_10[2][2:0] = q_prev_q_10[2] ? rem_sum_prev_q_10[2][2:0] : {rem_sum[0][0:0], dividend_abs[62:61]};

assign {rem_cout_prev_q_11[2], rem_sum_prev_q_11[2][2:0]} = 
  {1'b0, dividend_abs[63:61]}
+ {1'b0, {(3){~divisor_sign}} ^ D_times_7[2:0]}
+ {3'b0, ~divisor_sign};
assign force_q_to_zero_prev_q_11[2] = D_times_7_msb_to_lsb_flag[2] | D_times_7_lsb_to_msb_flag[2];
assign q_prev_q_11[2] = force_q_to_zero_prev_q_11[2] ? 1'b0 : rem_cout_prev_q_11[2];
assign rem_prev_q_11[2][2:0] = q_prev_q_11[2] ? rem_sum_prev_q_11[2][2:0] : {rem_sum_prev_q_1[1][1:0], dividend_abs[61]};

assign quo_iter[1] = quo_iter[0] ? q_prev_q_1[1] : q_prev_q_0[1];
// assign rem[1][1:0] = quo_iter[0] ? rem_prev_q_1[1][1:0] : rem_prev_q_0[1][1:0];
assign quo_iter[2] = 
  ({(1){{quo_iter[0], quo_iter[1]} == 2'b00}} & q_prev_q_00[2])
| ({(1){{quo_iter[0], quo_iter[1]} == 2'b01}} & q_prev_q_01[2])
| ({(1){{quo_iter[0], quo_iter[1]} == 2'b10}} & q_prev_q_10[2])
| ({(1){{quo_iter[0], quo_iter[1]} == 2'b11}} & q_prev_q_11[2]);
assign rem[2][2:0] = 
  ({(3){{quo_iter[0], quo_iter[1]} == 2'b00}} & rem_prev_q_00[2][2:0])
| ({(3){{quo_iter[0], quo_iter[1]} == 2'b01}} & rem_prev_q_01[2][2:0])
| ({(3){{quo_iter[0], quo_iter[1]} == 2'b10}} & rem_prev_q_10[2][2:0])
| ({(3){{quo_iter[0], quo_iter[1]} == 2'b11}} & rem_prev_q_11[2][2:0]);

for(i = 3; i <= 60; i = i + 3) begin: g_restoring_stage_3_to_62

	always_comb begin		

		// stage[3n]
		{rem_cout[i], rem_sum[i][i:0]} = 
		  {1'b0, rem[i-1][i-1:0], dividend_abs[63-i]}
		+ {1'b0, {(i + 1){~divisor_sign}} ^ D[i:0]}
		+ {{(i + 1){1'b0}}, ~divisor_sign};		
		force_q_to_zero[i] = D_msb_to_lsb_flag[i] | D_lsb_to_msb_flag[i];
		quo_iter[i] = force_q_to_zero[i] ? 1'b0 : rem_cout[i];
		// rem[i][i:0] = quo_iter[i] ? rem_sum[i][i:0] : {rem[i-1][i-1:0], dividend_abs[63-i]};

		// stage[3n + 1], assume previous quo is 0
		{rem_cout_prev_q_0[i+1], rem_sum_prev_q_0[i+1][i+1:0]} = 
		  {1'b0, rem[i-1][i-1:0], dividend_abs[63-i -: 2]}
		+ {1'b0, {(i + 2){~divisor_sign}} ^ D[i+1:0]}
		+ {{(i + 2){1'b0}}, ~divisor_sign};
		force_q_to_zero_prev_q_0[i+1] = D_msb_to_lsb_flag[i+1] | D_lsb_to_msb_flag[i+1];
		q_prev_q_0[i+1] = force_q_to_zero_prev_q_0[i+1] ? 1'b0 : rem_cout_prev_q_0[i+1];
		rem_prev_q_0[i+1][i+1:0] = q_prev_q_0[i+1] ? rem_sum_prev_q_0[i+1][i+1:0] : {rem[i-1][i-1:0], dividend_abs[63-i -: 2]};

		// stage[3n + 1], assume previous quo is 1
		{rem_cout_prev_q_1[i+1], rem_sum_prev_q_1[i+1][i+1:0]} = 
		  {1'b0, rem[i-1][i-1:0], dividend_abs[63-i -: 2]}
		+ {1'b0, {(i + 2){~divisor_sign}} ^ D_times_3[i+1:0]}
		+ {{(i + 2){1'b0}}, ~divisor_sign};
		force_q_to_zero_prev_q_1[i+1] = D_times_3_msb_to_lsb_flag[i+1] | D_times_3_lsb_to_msb_flag[i+1];
		q_prev_q_1[i+1] = force_q_to_zero_prev_q_1[i+1] ? 1'b0 : rem_cout_prev_q_1[i+1];
		// Since we assume quo of stage[2n] is 1, so the rem of stage[2n] must be rem_sum[i]
		rem_prev_q_1[i+1][i+1:0] = q_prev_q_1[i+1] ? rem_sum_prev_q_1[i+1][i+1:0] : {rem_sum[i][i:0], dividend_abs[63-1-i]};

		// stage[3n + 2], assume previous quo is 00
		{rem_cout_prev_q_00[i+2], rem_sum_prev_q_00[i+2][i+2:0]} = 
		  {1'b0, rem[i-1][i-1:0], dividend_abs[63-i -: 3]}
		+ {1'b0, {(i + 3){~divisor_sign}} ^ D[i+2:0]}
		+ {{(i + 3){1'b0}}, ~divisor_sign};
		force_q_to_zero_prev_q_00[i+2] = D_msb_to_lsb_flag[i+2] | D_lsb_to_msb_flag[i+2];
		q_prev_q_00[i+2] = force_q_to_zero_prev_q_00[i+2] ? 1'b0 : rem_cout_prev_q_00[i+2];
		rem_prev_q_00[i+2][i+2:0] = q_prev_q_00[i+2] ? rem_sum_prev_q_00[i+2][i+2:0] : {rem[i-1][i-1:0], dividend_abs[63-i -: 3]};

		// assume previous quo is 01
		{rem_cout_prev_q_01[i+2], rem_sum_prev_q_01[i+2][i+2:0]} = 
		  {1'b0, rem[i-1][i-1:0], dividend_abs[63-i -: 3]}
		+ {1'b0, {(i + 3){~divisor_sign}} ^ D_times_3[i+2:0]}
		+ {{(i + 3){1'b0}}, ~divisor_sign};
		force_q_to_zero_prev_q_01[i+2] = D_times_3_msb_to_lsb_flag[i+2] | D_times_3_lsb_to_msb_flag[i+2];
		q_prev_q_01[i+2] = force_q_to_zero_prev_q_01[i+2] ? 1'b0 : rem_cout_prev_q_01[i+2];
		rem_prev_q_01[i+2][i+2:0] = q_prev_q_01[i+2] ? rem_sum_prev_q_01[i+2][i+2:0] : {rem_sum_prev_q_0[i+1][i+1:0], dividend_abs[63-2-i]};

		// assume previous quo is 10
		{rem_cout_prev_q_10[i+2], rem_sum_prev_q_10[i+2][i+2:0]} = 
		  {1'b0, rem[i-1][i-1:0], dividend_abs[63-i -: 3]}
		+ {1'b0, {(i + 3){~divisor_sign}} ^ D_times_5[i+2:0]}
		+ {{(i + 3){1'b0}}, ~divisor_sign};
		force_q_to_zero_prev_q_10[i+2] = D_times_5_msb_to_lsb_flag[i+2] | D_times_5_lsb_to_msb_flag[i+2];
		q_prev_q_10[i+2] = force_q_to_zero_prev_q_10[i+2] ? 1'b0 : rem_cout_prev_q_10[i+2];
		rem_prev_q_10[i+2][i+2:0] = q_prev_q_10[i+2] ? rem_sum_prev_q_10[i+2][i+2:0] : {rem_sum[i][i:0], dividend_abs[63-1-i : 63-2-i]};

		// assume previous quo is 11
		{rem_cout_prev_q_11[i+2], rem_sum_prev_q_11[i+2][i+2:0]} = 
		  {1'b0, rem[i-1][i-1:0], dividend_abs[63-i -: 3]}
		+ {1'b0, {(i + 3){~divisor_sign}} ^ D_times_7[i+2:0]}
		+ {{(i + 3){1'b0}}, ~divisor_sign};
		force_q_to_zero_prev_q_11[i+2] = D_times_7_msb_to_lsb_flag[i+2] | D_times_7_lsb_to_msb_flag[i+2];
		q_prev_q_11[i+2] = force_q_to_zero_prev_q_11[i+2] ? 1'b0 : rem_cout_prev_q_11[i+2];
		rem_prev_q_11[i+2][i+2:0] = q_prev_q_11[i+2] ? rem_sum_prev_q_11[i+2][i+2:0] : {rem_sum_prev_q_1[i+1][i+1:0], dividend_abs[63-2-i]};

		quo_iter[i+1] = quo_iter[i] ? q_prev_q_1[i+1] : q_prev_q_0[i+1];
		// rem[i+1][i+1:0] = quo_iter[i] ? rem_prev_q_1[i+1][i+1:0] : rem_prev_q_0[i+1][i+1:0];
		quo_iter[i+2] = 
		  ({(1){{quo_iter[i], quo_iter[i+1]} == 2'b00}} & q_prev_q_00[i+2])
		| ({(1){{quo_iter[i], quo_iter[i+1]} == 2'b01}} & q_prev_q_01[i+2])
		| ({(1){{quo_iter[i], quo_iter[i+1]} == 2'b10}} & q_prev_q_10[i+2])
		| ({(1){{quo_iter[i], quo_iter[i+1]} == 2'b11}} & q_prev_q_11[i+2]);
		rem[i+2][i+2:0] = 
		  ({(i + 3){{quo_iter[i], quo_iter[i+1]} == 2'b00}} & rem_prev_q_00[i+2][i+2:0])
		| ({(i + 3){{quo_iter[i], quo_iter[i+1]} == 2'b01}} & rem_prev_q_01[i+2][i+2:0])
		| ({(i + 3){{quo_iter[i], quo_iter[i+1]} == 2'b10}} & rem_prev_q_10[i+2][i+2:0])
		| ({(i + 3){{quo_iter[i], quo_iter[i+1]} == 2'b11}} & rem_prev_q_11[i+2][i+2:0]);
	end
end

// stage[63]
assign {rem_cout[63], rem_sum[63][63:0]} = 
  {1'b0, rem[62][62:0], dividend_abs[0]}
+ {1'b0, {(64){~divisor_sign}} ^ D[63:0]}
+ {64'b0, ~divisor_sign};
assign force_q_to_zero[63] = 1'b0;
assign quo_iter[63] = rem_cout[63];
assign rem[63][63:0] = quo_iter[63] ? rem_sum[63][63:0] : {rem[62], dividend_abs[0]};

for(i = 0; i < 64; i = i + 1) begin: g_quo_reverse
	assign final_quo_pre[i] = quo_iter[63 - i];
end

assign final_quo = quo_sign ? -final_quo_pre : final_quo_pre;
assign final_rem = rem_sign ? -rem[63] : rem[63];

assign divisor_is_zero_o = (divisor_i == '0);
assign quotient_o = divisor_is_zero_o ? {(64){1'b1}} : final_quo;
assign remainder_o = divisor_is_zero_o ? dividend_i : final_rem;


endmodule
