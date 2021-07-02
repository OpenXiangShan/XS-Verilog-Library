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
// File Name	: 	tb_defines.svh
// Author		: 	Yifei He
// Created On	: 	2021/06/20
// --------------------------------------------------------------------------------------------------------
// Description	:
// Some common definitions for Testbench.
// --------------------------------------------------------------------------------------------------------

`timescale 1ns/100ps

`define CLK_HI 5
`define CLK_LO 5
`define CLK_PERIOD (`CLK_HI + `CLK_LO)
// set stimuli application delay
`define APPL_DELAY 3
// set response aquisition delay
`define RESP_DELAY 7

`define SHORT_DELAY 5
`define MIDDLE_DELAY 10
`define LONG_DELAY 20

`ifdef USE_LONG_DELAY
`define VALID_READY_DELAY `LONG_DELAY
`elsif USE_MIDDLE_DELAY
`define VALID_READY_DELAY `MIDDLE_DELAY
`elsif USE_SHORT_DELAY
`define VALID_READY_DELAY `SHORT_DELAY
`else
`define VALID_READY_DELAY 0
`endif


`define WAIT_CYC(CLK, N)	\
repeat(N) @(posedge CLK);

`define APPL_WAIT_CYC(CLK, N) \
repeat(N) @(posedge CLK); \
#(`APPL_DELAY);

`define RESP_WAIT_CYC(CLK, N) \
repeat(N) @(posedge CLK); \
#(`RESP_DELAY);

`define WAIT_SIG(CLK, SIG)	\
do begin					\
	@(posedge CLK);			\
end while(SIG == 1'b0);

`define WAIT_COMB_SIG(CLK, SIG)		\
while(SIG == 1'b0) begin			\
	@(posedge CLK);					\
end

`define APPL_WAIT_COMB_SIG(CLK, SIG) \
#(`APPL_DELAY); \
while(SIG == 1'b0) begin \
	@(posedge CLK); \
	#(`APPL_DELAY); \
end

`define APPL_WAIT_SIG(CLK, SIG) \
do begin \
	@(posedge CLK); \
	#(`APPL_DELAY); \
end while(SIG == 1'b0);

`define RESP_WAIT_COMB_SIG(CLK, SIG) \
#(`RESP_DELAY); \
while(SIG == 1'b0) begin \
	@(posedge CLK); \
	#(`RESP_DELAY); \
end

`define RESP_WAIT_SIG(CLK, SIG) \
do begin \
	@(posedge CLK); \
	#(`RESP_DELAY); \
end while(SIG == 1'b0);


