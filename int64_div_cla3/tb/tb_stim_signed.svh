// ========================================================================================================
// File Name			: tb_stim_signed.svh
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-07-23 10:08:49
// Last Modified Time   : 2021-10-30 16:18:31
// ========================================================================================================
// Description	:
// Stim for signed op.
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


opcode = OPCODE_SIGNED;

dividend_64 = 64'hb338_d6e1_4a76_0a6d;
divisor_64 = 64'hffd8_09e6_11a0_22a9;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = 32'h8d201e54;
divisor_64 = 32'hfff10513;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = 579274702;
divisor_64 = 621799622;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = 995101285;
divisor_64 = 822573882;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = -100;
divisor_64 = 0;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = -2090966090;
divisor_64 = 0;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = INT64_NEG_MIN;
divisor_64 = 1;
dividend_32 = INT32_NEG_MIN;
divisor_32 = 1;
dividend_16 = INT16_NEG_MIN;
divisor_16 = 1;
`SINGLE_STIM

dividend_64 = INT64_NEG_MIN;
divisor_64 = -1;
dividend_32 = INT32_NEG_MIN;
divisor_32 = -1;
dividend_16 = INT16_NEG_MIN;
divisor_16 = -1;
`SINGLE_STIM

for(i = 0; i < SIGNED_RANDOM_TEST_NUM; i++) begin
	// Make sure divisor_lzc >= dividend_lzc, so "ITER" is always needed.
	dividend_64_lzc = $urandom() % 64;
	dividend_32_lzc = $urandom() % 32;
	dividend_16_lzc = $urandom() % 16;
	divisor_64_lzc = ($urandom() % (64 - dividend_64_lzc)) + dividend_64_lzc;
	divisor_32_lzc = ($urandom() % (32 - dividend_32_lzc)) + dividend_32_lzc;
	divisor_16_lzc = ($urandom() % (16 - dividend_16_lzc)) + dividend_16_lzc;

	std::randomize(dividend_64);
	dividend_64[63] = 1'b1;
	dividend_64 = dividend_64 >> dividend_64_lzc;
	// sign of dividend is random
	dividend_64[63] = dividend_64[0];
	std::randomize(divisor_64);
	divisor_64[63] = 1'b1;
	divisor_64 = divisor_64 >> divisor_64_lzc;
	// sign of divisor is random
	divisor_64[63] = divisor_64[0];

	std::randomize(dividend_32);
	dividend_32[31] = 1'b1;
	dividend_32 = dividend_32 >> dividend_32_lzc;
	dividend_32[31] = dividend_32[0];
	std::randomize(divisor_32);
	divisor_32[31] = 1'b1;
	divisor_32 = divisor_32 >> divisor_32_lzc;
	divisor_32[31] = divisor_32[0];

	std::randomize(dividend_16);
	dividend_16[15] = 1'b1;
	dividend_16 = dividend_16 >> dividend_16_lzc;
	dividend_16[15] = dividend_16[0];
	std::randomize(divisor_16);
	divisor_16[15] = 1'b1;
	divisor_16 = divisor_16 >> divisor_16_lzc;
	divisor_16[15] = divisor_16[0];
	`SINGLE_STIM
end
