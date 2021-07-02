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
// File Name	: 	radix_2_srt_csa.sv
// Author		: 	Yifei He
// Created On	: 	2021/06/28
// --------------------------------------------------------------------------------------------------------
// Description	:
// CSA Module to calculate MSB of sum/carry in srt iteration.
// --------------------------------------------------------------------------------------------------------

// include some definitions here

module radix_2_srt_csa #(
	// put some parameters here, which can be changed by other modules
	parameter WIDTH = 66
)(
	input logic [WIDTH-4:0] csa_plus_i,
	input logic [WIDTH-4:0] csa_minus_i,
	input logic [WIDTH-2:0] rem_sum_i,
	input logic [WIDTH-2:0] rem_carry_i,
	output logic [WIDTH-2:0] rem_sum_zero_o,
	output logic [WIDTH-2:0] rem_carry_zero_o,
	output logic [WIDTH-2:0] rem_sum_minus_d_o,
	output logic [WIDTH-2:0] rem_carry_minus_d_o,
	output logic [WIDTH-2:0] rem_sum_plus_d_o,
	output logic [WIDTH-2:0] rem_carry_plus_d_o
);

// --------------------------------------------------------------------------------------------------------
// definitions begin



// definitions end
// --------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------
// (local) parameters begin



// (local) parameters end
// --------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------
// functions begin



// functions end
// --------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------
// signals begin



// signals end
// --------------------------------------------------------------------------------------------------------

generate
if(WIDTH > 3) begin: g_csa_full_width
	assign rem_sum_zero_o[(WIDTH - 2):0] = {2'b01, rem_sum_i[(WIDTH - 4):0] ^ rem_carry_i[(WIDTH - 4):0]};
	assign rem_carry_zero_o[(WIDTH - 2):0] = {1'b1, rem_sum_i[(WIDTH - 4):0] & rem_carry_i[(WIDTH - 4):0], 1'b0};

	assign rem_sum_plus_d_o[(WIDTH - 4):0] = rem_sum_i[(WIDTH - 4):0] ^ rem_carry_i[(WIDTH - 4):0] ^ csa_plus_i[(WIDTH - 4):0];
	assign rem_carry_plus_d_o[(WIDTH - 3):0] = {
		  (rem_sum_i[(WIDTH - 4):0] & rem_carry_i[(WIDTH - 4):0])
		| (rem_sum_i[(WIDTH - 4):0] & csa_plus_i[(WIDTH - 4):0])
		| (rem_carry_i[(WIDTH - 4):0] & csa_plus_i[(WIDTH - 4):0]), 
		1'b0
	};

	assign rem_sum_minus_d_o[(WIDTH - 4):0] = rem_sum_i[(WIDTH - 4):0] ^ rem_carry_i[(WIDTH - 4):0] ^ ~csa_minus_i[(WIDTH - 4):0];
	assign rem_carry_minus_d_o[(WIDTH - 3):0] = {
		  (rem_sum_i[(WIDTH - 4):0] & rem_carry_i[(WIDTH - 4):0])
		| (rem_sum_i[(WIDTH - 4):0] & ~csa_minus_i[(WIDTH - 4):0])
		| (rem_carry_i[(WIDTH - 4):0] & ~csa_minus_i[(WIDTH - 4):0]), 
		1'b1
	};
end
else begin: g_csa_narrow_width
	assign rem_sum_zero_o[1:0] = 2'b01;
	assign rem_carry_zero_o[1:0] = 2'b10;
	assign rem_carry_plus_d_o[0] = 1'b0;
	assign rem_carry_minus_d_o[0] = 1'b1; 
end
endgenerate

assign rem_carry_minus_d_o[WIDTH - 2] = 
  (~rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| (~rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| (~rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| (~rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3]);

assign rem_sum_minus_d_o[WIDTH - 2] = 1'b0;
assign rem_sum_minus_d_o[WIDTH - 3] = 
  (~rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| (~rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| (~rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| (~rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3]);

assign rem_carry_plus_d_o[WIDTH - 2] = 
  (~rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| (~rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| (~rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| (~rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| (                        ~rem_sum_i[WIDTH - 3] &                           ~rem_carry_i[WIDTH - 3])
| (                         rem_sum_i[WIDTH - 3] &                            rem_carry_i[WIDTH - 3]);

assign rem_sum_plus_d_o[WIDTH - 2] = 
  (~rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| (~rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| (~rem_sum_i[WIDTH - 2] &  rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] & ~rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3])
| (~rem_sum_i[WIDTH - 2] & ~rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 2] &  rem_carry_i[WIDTH - 3]);

assign rem_sum_plus_d_o[WIDTH - 3] = 
  (~rem_sum_i[WIDTH - 3] & ~rem_carry_i[WIDTH - 3])
| ( rem_sum_i[WIDTH - 3] &  rem_carry_i[WIDTH - 3]);

endmodule
