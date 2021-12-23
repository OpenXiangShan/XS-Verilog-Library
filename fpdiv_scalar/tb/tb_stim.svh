// ========================================================================================================
// File Name			: tb_stim.svh
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-07-23 10:08:49
// Last Modified Time   : 2021-12-21 21:40:11
// ========================================================================================================
// Description	:
// 
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
`ifndef RAND_SEED
	`define RAND_SEED 999
`endif
`ifndef TEST_LEVEL
	`define TEST_LEVEL 1
`endif

gencases_init(`RAND_SEED, `TEST_LEVEL);


`ifdef TEST_SPECIAL_POINT
// ==================================================================================================================================================
// Some wrong points..
// ==================================================================================================================================================
fp_format = 0;
fpdiv_opa = 32'h800;
fpdiv_opb = 32'hC001;
fpdiv_rm = 2;
`SINGLE_STIM
fpdiv_opa = 32'hB045;
fpdiv_opb = 32'hCFBF;
fpdiv_rm = 0;
`SINGLE_STIM

`else

// ==================================================================================================================================================
// Just random test...
// ==================================================================================================================================================
fp_format = 0;
for(i = 0; i < FP16_RANDOM_NUM; i++) begin
	gencases_for_f16(fpdiv_opa[15:0], fpdiv_opb[15:0]);
	
	fpdiv_rm = RM_RNE;
	`SINGLE_STIM
	fpdiv_rm = RM_RTZ;
	`SINGLE_STIM
	fpdiv_rm = RM_RDN;
	`SINGLE_STIM
	fpdiv_rm = RM_RUP;
	`SINGLE_STIM
	fpdiv_rm = RM_RMM;
	`SINGLE_STIM
end

fp_format = 1;
for(i = 0; i < FP32_RANDOM_NUM; i++) begin
	gencases_for_f32(fpdiv_opa[31:0], fpdiv_opb[31:0]);

	fpdiv_rm = RM_RNE;
	`SINGLE_STIM
	fpdiv_rm = RM_RTZ;
	`SINGLE_STIM
	fpdiv_rm = RM_RDN;
	`SINGLE_STIM
	fpdiv_rm = RM_RUP;
	`SINGLE_STIM
	fpdiv_rm = RM_RMM;
	`SINGLE_STIM
end

fp_format = 2;
for(i = 0; i < FP64_RANDOM_NUM; i++) begin
	gencases_for_f64(fpdiv_opa[63:32], fpdiv_opa[31:0], fpdiv_opb[63:32], fpdiv_opb[31:0]);

	fpdiv_rm = RM_RNE;	
	`SINGLE_STIM
	fpdiv_rm = RM_RTZ;
	`SINGLE_STIM
	fpdiv_rm = RM_RDN;
	`SINGLE_STIM
	fpdiv_rm = RM_RUP;
	`SINGLE_STIM
	fpdiv_rm = RM_RMM;
	`SINGLE_STIM
end

`endif
