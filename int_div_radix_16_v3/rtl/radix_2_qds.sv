// ========================================================================================================
// File Name			: radix_2_qds.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-07-23 10:08:49
// Last Modified Time   : 2021-09-20 20:47:28
// ========================================================================================================
// Description	:
// quoient Digit Selection (QDS) for Radix-2 SRT.
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

module radix_2_qds #(
	// put some parameters here, which can be changed by other modules
	
)(
	input  logic [2:0] rem_sum_msb_i,
	input  logic [2:0] rem_carry_msb_i,
	output logic [1:0] quo_dig_o
);
// ================================================================================================================================================
// (local) parameters begin


// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// functions begin



// functions end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin


// signals end
// ================================================================================================================================================

always_comb
begin
	case({rem_sum_msb_i[2:0], rem_carry_msb_i[2:0]})
		// sum + carry = 0000
		// sum - carry = 0, 0, 0
		6'b000_000:		quo_dig_o = 2'b01;
		// sum + carry = 0001
		// sum - carry = 0, 0, -1
		6'b000_001:		quo_dig_o = 2'b01;
		// sum + carry = 0010
		// sum - carry = 0, -1, 0
		6'b000_010:		quo_dig_o = 2'b01;
		// sum + carry = 0011
		// sum - carry = 0, -1, -1
		6'b000_011:		quo_dig_o = 2'b01;
		// sum + carry = 0100
		// sum - carry = -1, 0, 0
		6'b000_100:		quo_dig_o = 2'b10;
		// sum + carry = 0101
		// sum - carry = -1, 0, -1
		6'b000_101:		quo_dig_o = 2'b10;
		// sum + carry = 0110
		// sum - carry = -1, -1, 0
		6'b000_110:		quo_dig_o = 2'b10;
		// sum + carry = 0111
		// sum - carry = -1, -1, -1
		6'b000_111:		quo_dig_o = 2'b00;
		// sum + carry = 0001
		// sum - carry = 0, 0, 1
		6'b001_000:		quo_dig_o = 2'b01;
		// sum + carry = 0010
		// sum - carry = 0, 0, 0
		6'b001_001:		quo_dig_o = 2'b01;
		// sum + carry = 0011
		// sum - carry = 0, -1, 1
		6'b001_010:		quo_dig_o = 2'b01;
		// sum + carry = 0100
		// sum - carry = 0, -1, 0
		6'b001_011:		quo_dig_o = 2'b01;
		// sum + carry = 0101
		// sum - carry = -1, 0, 1
		6'b001_100:		quo_dig_o = 2'b10;
		// sum + carry = 0110
		// sum - carry = -1, 0, 0
		6'b001_101:		quo_dig_o = 2'b10;
		// sum + carry = 0111
		// sum - carry = -1, -1, 1
		6'b001_110:		quo_dig_o = 2'b00;
		// sum + carry = 1000
		// sum - carry = -1, -1, 0
		6'b001_111:		quo_dig_o = 2'b01;
		// sum + carry = 0010
		// sum - carry = 0, 1, 0
		6'b010_000:		quo_dig_o = 2'b01;
		// sum + carry = 0011
		// sum - carry = 0, 1, -1
		6'b010_001:		quo_dig_o = 2'b01;
		// sum + carry = 0100
		// sum - carry = 0, 0, 0
		6'b010_010:		quo_dig_o = 2'b01;
		// sum + carry = 0101
		// sum - carry = 0, 0, -1
		6'b010_011:		quo_dig_o = 2'b01;
		// sum + carry = 0110
		// sum - carry = -1, 1, 0
		6'b010_100:		quo_dig_o = 2'b10;
		// sum + carry = 0111
		// sum - carry = -1, 1, -1
		6'b010_101:		quo_dig_o = 2'b00;
		// sum + carry = 1000
		// sum - carry = -1, 0, 0
		6'b010_110:		quo_dig_o = 2'b01;
		// sum + carry = 1001
		// sum - carry = -1, 0, -1
		6'b010_111:		quo_dig_o = 2'b01;
		// sum + carry = 0011
		// sum - carry = 0, 1, 1
		6'b011_000:		quo_dig_o = 2'b01;
		// sum + carry = 0100
		// sum - carry = 0, 1, 0
		6'b011_001:		quo_dig_o = 2'b01;
		// sum + carry = 0101
		// sum - carry = 0, 0, 1
		6'b011_010:		quo_dig_o = 2'b01;
		// sum + carry = 0110
		// sum - carry = 0, 0, 0
		6'b011_011:		quo_dig_o = 2'b01;
		// sum + carry = 0111
		// sum - carry = -1, 1, 1
		6'b011_100:		quo_dig_o = 2'b00;
		// sum + carry = 1000
		// sum - carry = -1, 1, 0
		6'b011_101:		quo_dig_o = 2'b01;
		// sum + carry = 1001
		// sum - carry = -1, 0, 1
		6'b011_110:		quo_dig_o = 2'b01;
		// sum + carry = 1010
		// sum - carry = -1, 0, 0
		6'b011_111:		quo_dig_o = 2'b01;
		// sum + carry = 0100
		// sum - carry = 1, 0, 0
		6'b100_000:		quo_dig_o = 2'b10;
		// sum + carry = 0101
		// sum - carry = 1, 0, -1
		6'b100_001:		quo_dig_o = 2'b10;
		// sum + carry = 0110
		// sum - carry = 1, -1, 0
		6'b100_010:		quo_dig_o = 2'b10;
		// sum + carry = 0111
		// sum - carry = 1, -1, -1
		6'b100_011:		quo_dig_o = 2'b00;
		// sum + carry = 1000
		// sum - carry = 0, 0, 0
		6'b100_100:		quo_dig_o = 2'b10;
		// sum + carry = 1001
		// sum - carry = 0, 0, -1
		6'b100_101:		quo_dig_o = 2'b10;
		// sum + carry = 1010
		// sum - carry = 0, -1, 0
		6'b100_110:		quo_dig_o = 2'b10;
		// sum + carry = 1011
		// sum - carry = 0, -1, -1
		6'b100_111:		quo_dig_o = 2'b10;
		// sum + carry = 0101
		// sum - carry = 1, 0, 1
		6'b101_000:		quo_dig_o = 2'b10;
		// sum + carry = 0110
		// sum - carry = 1, 0, 0
		6'b101_001:		quo_dig_o = 2'b10;
		// sum + carry = 0111
		// sum - carry = 1, -1, 1
		6'b101_010:		quo_dig_o = 2'b00;
		// sum + carry = 1000
		// sum - carry = 1, -1, 0
		6'b101_011:		quo_dig_o = 2'b01;
		// sum + carry = 1001
		// sum - carry = 0, 0, 1
		6'b101_100:		quo_dig_o = 2'b10;
		// sum + carry = 1010
		// sum - carry = 0, 0, 0
		6'b101_101:		quo_dig_o = 2'b10;
		// sum + carry = 1011
		// sum - carry = 0, -1, 1
		6'b101_110:		quo_dig_o = 2'b10;
		// sum + carry = 1100
		// sum - carry = 0, -1, 0
		6'b101_111:		quo_dig_o = 2'b10;
		// sum + carry = 0110
		// sum - carry = 1, 1, 0
		6'b110_000:		quo_dig_o = 2'b10;
		// sum + carry = 0111
		// sum - carry = 1, 1, -1
		6'b110_001:		quo_dig_o = 2'b00;
		// sum + carry = 1000
		// sum - carry = 1, 0, 0
		6'b110_010:		quo_dig_o = 2'b01;
		// sum + carry = 1001
		// sum - carry = 1, 0, -1
		6'b110_011:		quo_dig_o = 2'b01;
		// sum + carry = 1010
		// sum - carry = 0, 1, 0
		6'b110_100:		quo_dig_o = 2'b10;
		// sum + carry = 1011
		// sum - carry = 0, 1, -1
		6'b110_101:		quo_dig_o = 2'b10;
		// sum + carry = 1100
		// sum - carry = 0, 0, 0
		6'b110_110:		quo_dig_o = 2'b10;
		// sum + carry = 1101
		// sum - carry = 0, 0, -1
		6'b110_111:		quo_dig_o = 2'b10;
		// sum + carry = 0111
		// sum - carry = 1, 1, 1
		6'b111_000:		quo_dig_o = 2'b00;
		// sum + carry = 1000
		// sum - carry = 1, 1, 0
		6'b111_001:		quo_dig_o = 2'b01;
		// sum + carry = 1001
		// sum - carry = 1, 0, 1
		6'b111_010:		quo_dig_o = 2'b01;
		// sum + carry = 1010
		// sum - carry = 1, 0, 0
		6'b111_011:		quo_dig_o = 2'b01;
		// sum + carry = 1011
		// sum - carry = 0, 1, 1
		6'b111_100:		quo_dig_o = 2'b10;
		// sum + carry = 1100
		// sum - carry = 0, 1, 0
		6'b111_101:		quo_dig_o = 2'b10;
		// sum + carry = 1101
		// sum - carry = 0, 0, 1
		6'b111_110:		quo_dig_o = 2'b10;
		// sum + carry = 1110
		// sum - carry = 0, 0, 0
		6'b111_111:		quo_dig_o = 2'b10;
	endcase
end

endmodule

