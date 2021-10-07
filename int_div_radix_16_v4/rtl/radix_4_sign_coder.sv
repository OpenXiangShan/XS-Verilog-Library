// ========================================================================================================
// File Name			: radix_4_sign_coder.sv
// Author				: Yifei He
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-07-20 16:20:14
// Last Modified Time 	: 2021-10-06 17:18:51
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

module radix_4_sign_coder #(
	// Put some parameters here, which can be changed by other modules.
	
)(
	input  logic sd_m_neg_1_sign_i,
	input  logic sd_m_neg_0_sign_i,
	input  logic sd_m_pos_1_sign_i,
	input  logic sd_m_pos_2_sign_i,
	output logic [5-1:0] quo_o
);

// ==================================================================================================================================================
// (local) params
// ==================================================================================================================================================

localparam QUO_NEG_2 = 0;
localparam QUO_NEG_1 = 1;
localparam QUO_ZERO  = 2;
localparam QUO_POS_1 = 3;
localparam QUO_POS_2 = 4;

// ==================================================================================================================================================
// functions
// ==================================================================================================================================================



// ==================================================================================================================================================
// signals
// ==================================================================================================================================================

logic [4-1:0] sign;

// ==================================================================================================================================================
// main codes
// ==================================================================================================================================================

// Just look at "TABLE 2" in 
// "Digit-Recurrence Dividers with Reduced Logical Depth", Elisardo Antelo.
assign sign = {sd_m_pos_2_sign_i, sd_m_pos_1_sign_i, sd_m_neg_0_sign_i, sd_m_neg_1_sign_i};
assign quo_o[QUO_POS_2] = (sign[3:1] == 3'b000);
assign quo_o[QUO_POS_1] = (sign[3:1] == 3'b100);
assign quo_o[QUO_ZERO ] = (sign[2:1] == 2'b10 );
assign quo_o[QUO_NEG_1] = (sign[2:0] == 3'b110);
assign quo_o[QUO_NEG_2] = (sign[2:0] == 3'b111);

endmodule
