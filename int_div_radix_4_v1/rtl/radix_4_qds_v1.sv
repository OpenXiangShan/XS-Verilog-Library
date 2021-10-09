// ========================================================================================================
// File Name			: radix_4_qds_v1.sv
// Author				: Yifei He
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-07-20 09:44:49
// Last Modified Time 	: 2021-10-06 18:11:49
// ========================================================================================================
// Description	:
// Please Look at the reference for more details.
// ========================================================================================================

// ========================================================================================================
// Copyright (C) 2021, Yifei He. All Rights Reserved.
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

module radix_4_qds_v1 #(
	// Put some parameters here, which can be changed by other modules.
	parameter WIDTH = 32,
	// ATTENTION: Don't change the below paras !!!
	// ITN = InTerNal
	parameter ITN_WIDTH = 1 + WIDTH + 2 + 1,
	parameter QUOT_ONEHOT_WIDTH = 5
)(
	input  logic [ITN_WIDTH-1:0] rem_sum_i,
	input  logic [ITN_WIDTH-1:0] rem_carry_i,
	input  logic [WIDTH-1:0] divisor_i,
	input  logic [5-1:0] qds_para_neg_1_i,
	input  logic [3-1:0] qds_para_neg_0_i,
	input  logic [2-1:0] qds_para_pos_1_i,
	input  logic [5-1:0] qds_para_pos_2_i,
	input  logic special_divisor_i,
	input  logic [QUOT_ONEHOT_WIDTH-1:0] prev_quot_digit_i,
	output logic [QUOT_ONEHOT_WIDTH-1:0] quot_digit_o
);
// ================================================================================================================================================
// (local) parameters begin

localparam QUOT_NEG_2 = 0;
localparam QUOT_NEG_1 = 1;
localparam QUOT_ZERO  = 2;
localparam QUOT_POS_1 = 3;
localparam QUOT_POS_2 = 4;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// functions begin



// functions end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

// sd = sign detector
logic [(ITN_WIDTH + 4)-1:0] rem_sum_mul_16;
logic [(ITN_WIDTH + 4)-1:0] rem_carry_mul_16;
logic [7-1:0] rem_sum_mul_16_trunc_2_5;
logic [7-1:0] rem_carry_mul_16_trunc_2_5;
logic [7-1:0] rem_sum_mul_16_trunc_3_4;
logic [7-1:0] rem_carry_mul_16_trunc_3_4;

// Since we need to do "16 * rem_sum + 16 * rem_carry - m[i] - 4 * q * D" (i = -1, 0, +1, +2) to select the next quot, so we choose to remember the 
// inversed value of parameters described in the paper.
logic [7-1:0] para_m_neg_1_trunc_2_5;
logic [7-1:0] para_m_neg_0_trunc_3_4;
logic [7-1:0] para_m_pos_1_trunc_3_4;
logic [7-1:0] para_m_pos_2_trunc_2_5;

logic [ITN_WIDTH-1:0] divisor;
logic [(ITN_WIDTH + 2)-1:0] divisor_mul_4;
logic [(ITN_WIDTH + 2)-1:0] divisor_mul_8;
logic [(ITN_WIDTH + 2)-1:0] divisor_mul_neg_4;
logic [(ITN_WIDTH + 2)-1:0] divisor_mul_neg_8;
logic [7-1:0] divisor_mul_4_trunc_2_5;
logic [7-1:0] divisor_mul_4_trunc_3_4;
logic [7-1:0] divisor_mul_8_trunc_2_5;
logic [7-1:0] divisor_mul_8_trunc_3_4;
logic [7-1:0] divisor_mul_neg_4_trunc_2_5;
logic [7-1:0] divisor_mul_neg_4_trunc_3_4;
logic [7-1:0] divisor_mul_neg_8_trunc_2_5;
logic [7-1:0] divisor_mul_neg_8_trunc_3_4;
logic [7-1:0] divisor_for_sd_trunc_3_4;
logic [7-1:0] divisor_for_sd_trunc_2_5;

logic sd_m_neg_1_sign;
logic sd_m_neg_0_sign;
logic sd_m_pos_1_sign;
logic sd_m_pos_2_sign;

// signals end
// ================================================================================================================================================

// After "16 * " operation, the decimal point is still between "[ITN_WIDTH-1]" and "[ITN_WIDTH-2]".
assign rem_sum_mul_16 = {rem_sum_i, 4'b0};
assign rem_carry_mul_16 = {rem_carry_i, 4'b0};

assign rem_sum_mul_16_trunc_2_5 = rem_sum_mul_16[(ITN_WIDTH    ) -: 7];
assign rem_sum_mul_16_trunc_3_4 = rem_sum_mul_16[(ITN_WIDTH + 1) -: 7];
assign rem_carry_mul_16_trunc_2_5 = rem_carry_mul_16[(ITN_WIDTH    ) -: 7];
assign rem_carry_mul_16_trunc_3_4 = rem_carry_mul_16[(ITN_WIDTH + 1) -: 7];
// ================================================================================================================================================
// Calculate the parameters for CMP.
// ================================================================================================================================================
assign para_m_neg_1_trunc_2_5 = {1'b0, qds_para_neg_1_i, 1'b0};

assign para_m_neg_0_trunc_3_4 = {3'b0, qds_para_neg_0_i, special_divisor_i};

assign para_m_pos_1_trunc_3_4 = {4'b1111, qds_para_pos_1_i, special_divisor_i};

assign para_m_pos_2_trunc_2_5 = {1'b1, qds_para_pos_2_i, 1'b0};

// ================================================================================================================================================
// Calculate "-4 * q * D" for CMP.
// ================================================================================================================================================
assign divisor = {1'b0, divisor_i, 3'b0};
assign divisor_mul_4 = {divisor, 2'b0};
assign divisor_mul_8 = {divisor[ITN_WIDTH-2:0], 3'b0};
// Using "~" is enough here.
assign divisor_mul_neg_4 = ~{divisor, 2'b0};
assign divisor_mul_neg_8 = ~{divisor[ITN_WIDTH-2:0], 1'b0, 2'b0};

// The decimal point is between "[ITN_WIDTH-1]" and "[ITN_WIDTH-2]".
assign divisor_mul_4_trunc_2_5 = divisor_mul_4[(ITN_WIDTH    ) -: 7];
assign divisor_mul_4_trunc_3_4 = divisor_mul_4[(ITN_WIDTH + 1) -: 7];
assign divisor_mul_8_trunc_2_5 = divisor_mul_8[(ITN_WIDTH    ) -: 7];
assign divisor_mul_8_trunc_3_4 = divisor_mul_8[(ITN_WIDTH + 1) -: 7];
assign divisor_mul_neg_4_trunc_2_5 = divisor_mul_neg_4[(ITN_WIDTH    ) -: 7];
assign divisor_mul_neg_4_trunc_3_4 = divisor_mul_neg_4[(ITN_WIDTH + 1) -: 7];
assign divisor_mul_neg_8_trunc_2_5 = divisor_mul_neg_8[(ITN_WIDTH    ) -: 7];
assign divisor_mul_neg_8_trunc_3_4 = divisor_mul_neg_8[(ITN_WIDTH + 1) -: 7];

// sd = Sign Detector
assign divisor_for_sd_trunc_2_5 = 
  ({(7){prev_quot_digit_i[QUOT_NEG_2]}} & divisor_mul_8_trunc_2_5)
| ({(7){prev_quot_digit_i[QUOT_NEG_1]}} & divisor_mul_4_trunc_2_5)
| ({(7){prev_quot_digit_i[QUOT_POS_1]}} & divisor_mul_neg_4_trunc_2_5)
| ({(7){prev_quot_digit_i[QUOT_POS_2]}} & divisor_mul_neg_8_trunc_2_5);
assign divisor_for_sd_trunc_3_4 = 
  ({(7){prev_quot_digit_i[QUOT_NEG_2]}} & divisor_mul_8_trunc_3_4)
| ({(7){prev_quot_digit_i[QUOT_NEG_1]}} & divisor_mul_4_trunc_3_4)
| ({(7){prev_quot_digit_i[QUOT_POS_1]}} & divisor_mul_neg_4_trunc_3_4)
| ({(7){prev_quot_digit_i[QUOT_POS_2]}} & divisor_mul_neg_8_trunc_3_4);

// ================================================================================================================================================
// Calculate sign and code the res.
// ================================================================================================================================================
radix_4_sign_detector
u_sd_m_neg_1 (
	.rem_sum_msb_i(rem_sum_mul_16_trunc_2_5),
	.rem_carry_msb_i(rem_carry_mul_16_trunc_2_5),
	.parameter_i(para_m_neg_1_trunc_2_5),
	.divisor_i(divisor_for_sd_trunc_2_5),
	.sign_o(sd_m_neg_1_sign)
);
radix_4_sign_detector
u_sd_m_neg_0 (
	.rem_sum_msb_i(rem_sum_mul_16_trunc_3_4),
	.rem_carry_msb_i(rem_carry_mul_16_trunc_3_4),
	.parameter_i(para_m_neg_0_trunc_3_4),
	.divisor_i(divisor_for_sd_trunc_3_4),
	.sign_o(sd_m_neg_0_sign)
);
radix_4_sign_detector
u_sd_m_pos_1 (
	.rem_sum_msb_i(rem_sum_mul_16_trunc_3_4),
	.rem_carry_msb_i(rem_carry_mul_16_trunc_3_4),
	.parameter_i(para_m_pos_1_trunc_3_4),
	.divisor_i(divisor_for_sd_trunc_3_4),
	.sign_o(sd_m_pos_1_sign)
);
radix_4_sign_detector
u_sd_m_pos_2 (
	.rem_sum_msb_i(rem_sum_mul_16_trunc_2_5),
	.rem_carry_msb_i(rem_carry_mul_16_trunc_2_5),
	.parameter_i(para_m_pos_2_trunc_2_5),
	.divisor_i(divisor_for_sd_trunc_2_5),
	.sign_o(sd_m_pos_2_sign)
);

radix_4_sign_coder
u_sign_coder (
	.sd_m_neg_1_sign_i(sd_m_neg_1_sign),
	.sd_m_neg_0_sign_i(sd_m_neg_0_sign),
	.sd_m_pos_1_sign_i(sd_m_pos_1_sign),
	.sd_m_pos_2_sign_i(sd_m_pos_2_sign),
	.quot_o(quot_digit_o)
);


endmodule
