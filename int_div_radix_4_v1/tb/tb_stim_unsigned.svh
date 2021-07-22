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
// File Name	: 	tb_stim_unsigned.svh
// Author		: 	Yifei He
// Created On	: 	2021/07/21
// --------------------------------------------------------------------------------------------------------
// Description	:
// Stim for unsigned op.
// --------------------------------------------------------------------------------------------------------

opcode = OPCODE_UNSIGNED;

dividend_64 = 4245582384;
divisor_64 = 3759407232;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = 4245582384;
divisor_64 = 1879703616;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = 100;
divisor_64 = 10;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = UINT64_POS_MAX;
divisor_64 = 10;
dividend_32 = UINT32_POS_MAX;
divisor_32 = 9090;
dividend_16 = UINT16_POS_MAX;
divisor_16 = 60012;
`SINGLE_STIM

dividend_64 = 100;
divisor_64 = 0;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = 90909090;
divisor_64 = 5050;
dividend_32 = dividend_64[32-1:0];
divisor_32 = divisor_64[32-1:0];
dividend_16 = dividend_64[16-1:0];
divisor_16 = divisor_64[16-1:0];
`SINGLE_STIM

dividend_64 = 1;
divisor_64 = UINT64_POS_MAX;
dividend_32 = 1;
divisor_32 = UINT32_POS_MAX;
dividend_16 = 1;
divisor_16 = UINT16_POS_MAX;
`SINGLE_STIM

dividend_64 = 0;
divisor_64 = 0;
dividend_32 = 0;
divisor_32 = 0;
dividend_16 = 0;
divisor_16 = 0;
`SINGLE_STIM

for(i = 0; i < UNSIGNED_RANDOM_TEST_NUM; i++) begin
	dividend_64 = {$urandom(), $urandom()};
	divisor_64 = {$urandom(), $urandom()};
	dividend_32 = dividend_64[32-1:0];
	divisor_32 = divisor_64[32-1:0];
	dividend_16 = dividend_64[16-1:0];
	divisor_16 = divisor_64[16-1:0];
	`SINGLE_STIM
end
