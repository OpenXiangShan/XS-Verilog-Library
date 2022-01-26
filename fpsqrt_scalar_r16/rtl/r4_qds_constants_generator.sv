// ========================================================================================================
// File Name			: r4_qds_constants_generator.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-15 20:37:05
// Last Modified Time   : 2022-01-15 21:16:33
// ========================================================================================================
// Description	:
// For more details, please look at "TABLE 6.5" and "equation 6.29" in:
// Digital Arithmetic By M.D. Ercegovac, 2004
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

module r4_qds_constants_generator #(
	// Put some parameters here, which can be changed by other modules.
)(
	input  logic a0_i,
	input  logic a2_i,
	input  logic a3_i,
	input  logic a4_i,
	output logic [7-1:0] m_neg_1_o,
	output logic [7-1:0] m_neg_0_o,
	output logic [7-1:0] m_pos_1_o,
	output logic [7-1:0] m_pos_2_o
);

// ================================================================================================================================================
// (local) parameters begin


// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin


// signals end
// ================================================================================================================================================

// According to the paper, the decimal point is between m[3] and m[2]
// Here we generate negative value of 4 constants
// I[0]:
// m[-1] = -13, -m[-1] = +13 = 0001_101
// m[-0] = - 4, -m[-0] = + 4 = 0000_100
// m[+1] = + 4, -m[+1] = - 4 = 1111_100
// m[+2] = +12, -m[+2] = -12 = 1110_100
// I[1]:
// m[-1] = -14, -m[-1] = +14 = 0001_110
// m[-0] = - 5, -m[-0] = + 5 = 0000_101
// m[+1] = + 4, -m[+1] = - 4 = 1111_100
// m[+2] = +14, -m[+2] = -14 = 1110_010
// I[2]:
// m[-1] = -16, -m[-1] = +16 = 0010_000
// m[-0] = - 6, -m[-0] = + 6 = 0000_110
// m[+1] = + 4, -m[+1] = - 4 = 1111_100
// m[+2] = +16, -m[+2] = -16 = 1110_000
// I[3]:
// m[-1] = -17, -m[-1] = +17 = 0010_001
// m[-0] = - 6, -m[-0] = + 6 = 0000_110
// m[+1] = + 4, -m[+1] = - 4 = 1111_100
// m[+2] = +16, -m[+2] = -16 = 1110_000
// I[4]:
// m[-1] = -18, -m[-1] = +18 = 0010_010
// m[-0] = - 6, -m[-0] = + 6 = 0000_110
// m[+1] = + 6, -m[+1] = - 6 = 1111_010
// m[+2] = +18, -m[+2] = -18 = 1101_110
// I[5]:
// m[-1] = -20, -m[-1] = +20 = 0010_100
// m[-0] = - 8, -m[-0] = + 8 = 0001_000
// m[+1] = + 6, -m[+1] = - 6 = 1111_010
// m[+2] = +20, -m[+2] = -20 = 1101_100
// I[6]:
// m[-1] = -22, -m[-1] = +22 = 0010_110
// m[-0] = - 8, -m[-0] = + 8 = 0001_000
// m[+1] = + 8, -m[+1] = - 8 = 1111_000
// m[+2] = +20, -m[+2] = -20 = 1101_100
// I[7]:
// m[-1] = -23, -m[-1] = +23 = 0010_111
// m[-0] = - 8, -m[-0] = + 8 = 0001_000
// m[+1] = + 8, -m[+1] = - 8 = 1111_000
// m[+2] = +22, -m[+2] = -22 = 1101_010

assign m_neg_1_o = 
  ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd0)}} & 7'b0001_101)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd1)}} & 7'b0001_110)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd2)}} & 7'b0010_000)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd3)}} & 7'b0010_001)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd4)}} & 7'b0010_010)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd5)}} & 7'b0010_100)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd6)}} & 7'b0010_110)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd7)}} & 7'b0010_111)
| ({(7){ a0_i                               }} & 7'b0010_111);

assign m_neg_0_o = 
  ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd0)}} & 7'b0000_100)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd1)}} & 7'b0000_101)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd2)}} & 7'b0000_110)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd3)}} & 7'b0000_110)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd4)}} & 7'b0000_110)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd5)}} & 7'b0001_000)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd6)}} & 7'b0001_000)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd7)}} & 7'b0001_000)
| ({(7){ a0_i                               }} & 7'b0001_000);

assign m_pos_1_o = 
  ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd0)}} & 7'b1111_100)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd1)}} & 7'b1111_100)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd2)}} & 7'b1111_100)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd3)}} & 7'b1111_100)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd4)}} & 7'b1111_010)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd5)}} & 7'b1111_010)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd6)}} & 7'b1111_000)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd7)}} & 7'b1111_000)
| ({(7){ a0_i                               }} & 7'b1111_000);

assign m_pos_2_o = 
  ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd0)}} & 7'b1110_100)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd1)}} & 7'b1110_010)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd2)}} & 7'b1110_000)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd3)}} & 7'b1110_000)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd4)}} & 7'b1101_110)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd5)}} & 7'b1101_100)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd6)}} & 7'b1101_100)
| ({(7){~a0_i & ({a2_i, a3_i, a4_i} == 3'd7)}} & 7'b1101_010)
| ({(7){ a0_i                               }} & 7'b1101_010);

endmodule
