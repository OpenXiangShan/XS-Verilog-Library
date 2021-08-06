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
// File Name	: 	tb_stim_signed.svh
// Author		: 	Yifei He
// Created On	: 	2021/07/21
// --------------------------------------------------------------------------------------------------------
// Description	:
// Stim for signed op.
// --------------------------------------------------------------------------------------------------------

opcode = OPCODE_SIGNED;

dividend_64 = 64'hb338_d6e1_4a76_0a6d;
divisor_64 = 64'hffd8_09e6_11a0_22a9;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = 99;
divisor_64 = -10;
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
	dividend_64 = {$urandom(), $urandom()};
	divisor_64 = {$urandom(), $urandom()};
	dividend_32 = dividend_64[32-1:0];
	divisor_32 = divisor_64[32-1:0];
	dividend_16 = dividend_64[16-1:0];
	divisor_16 = divisor_64[16-1:0];
	`SINGLE_STIM
end
