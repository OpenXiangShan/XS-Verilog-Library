// ========================================================================================================
// File Name			: compressor_3_2.sv
// Author				: Yifei He
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-07-17 21:50:22
// Last Modified Time 	: 2021-09-10 14:34:23
// ========================================================================================================
// Description	:
// This is a very standard 3-2 CSA.
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

// include your definitions here

module compressor_3_2 #(
	// Put your parameters here, which can be changed by other modules
	parameter WIDTH = 16
)(
	input  logic [WIDTH-1:0] x1,
	input  logic [WIDTH-1:0] x2,
	input  logic [WIDTH-1:0] x3,
	
	output logic [WIDTH-1:0] sum_o,
	output logic [WIDTH-1:0] carry_o
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



// ==================================================================================================================================================
// main codes
// ==================================================================================================================================================

// add_res_0[WIDTH-1:0] = sum_o + carry_o;
// add_res_1[WIDTH-1:0] = x1 + x2 + x3;
// add_res_0 == add_res_1
assign sum_o[WIDTH-1:0] = x1 ^ x2 ^ x3;
assign carry_o[WIDTH-1:0] = {(x1[WIDTH-2:0] & x2[WIDTH-2:0]) | (x1[WIDTH-2:0] & x3[WIDTH-2:0]) | (x2[WIDTH-2:0] & x3[WIDTH-2:0]), 1'b0};

endmodule
