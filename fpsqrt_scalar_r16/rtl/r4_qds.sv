// ========================================================================================================
// File Name			: r4_qds.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-15 11:10:46
// Last Modified Time   : 2022-01-16 11:07:10
// ========================================================================================================
// Description	:
// A standatd Radix-4 SRT Square-Root Quotient Digit Selection module.
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

module r4_qds #(
	// Put some parameters here, which can be changed by other modules.
)(
	input  logic [7-1:0] rem_i,
	input  logic [7-1:0] m_neg_1_i,
	input  logic [7-1:0] m_neg_0_i,
	input  logic [7-1:0] m_pos_1_i,
	input  logic [7-1:0] m_pos_2_i,
	output logic [5-1:0] rt_dig_o
);

// ================================================================================================================================================
// (local) parameters begin


// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic [4-1:0] qds_sign;
logic [6-1:0] unused_bit [4-1:0];

// signals end
// ================================================================================================================================================

assign {qds_sign[3], unused_bit[3]} = rem_i + m_pos_2_i;
assign {qds_sign[2], unused_bit[2]} = rem_i + m_pos_1_i;
assign {qds_sign[1], unused_bit[1]} = rem_i + m_neg_0_i;
assign {qds_sign[0], unused_bit[0]} = rem_i + m_neg_1_i;

assign rt_dig_o[4] = (qds_sign[1:0] == 2'b11);
assign rt_dig_o[3] = (qds_sign[1:0] == 2'b10);
assign rt_dig_o[2] = (qds_sign[2:1] == 2'b10);
assign rt_dig_o[1] = (qds_sign[3:2] == 2'b10);
assign rt_dig_o[0] = (qds_sign[3:2] == 2'b00);

endmodule
