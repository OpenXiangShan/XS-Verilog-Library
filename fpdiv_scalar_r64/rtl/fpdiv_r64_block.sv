// ========================================================================================================
// File Name			: fpdiv_r64_block.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-11 09:01:28
// Last Modified Time   : 2022-01-11 22:03:09
// ========================================================================================================
// Description	:
// Please look at the reference paper for its original architecture.
// Here I add more speculation to reduce latency.
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

module fpdiv_r64_block #(
	// Put some parameters here, which can be changed by other modules.

	// You should try which config could lead to best PPA.
	// 0: Native expression
	// 1: Comparator based
	// 2: Adder based
	parameter QDS_ARCH = 2,
	// 0: Larger delay, smaller area
	// 1: Smaller delay, larger area
	parameter S1_SPECULATIVE_QDS = 1,
	
	// Don't change the following value
	parameter REM_W = 3 + 53 + 3 + 1,
	parameter QUO_DIG_W = 5
)(
	input  logic [REM_W-1:0] f_r_s_i,
	input  logic [REM_W-1:0] f_r_c_i,
	// 57 = FP64_FRAC_W + 4
	input  logic [57-1:0] divisor_i,
	input  logic [6-1:0] nr_f_r_6b_for_nxt_cycle_s0_qds_i,
	input  logic [7-1:0] nr_f_r_7b_for_nxt_cycle_s1_qds_i,
	
	output logic [QUO_DIG_W-1:0] nxt_quo_dig_o [3-1:0],
	output logic [REM_W-1:0] nxt_f_r_s_o [3-1:0],
	output logic [REM_W-1:0] nxt_f_r_c_o [3-1:0],
	output logic [6-1:0] adder_6b_res_for_nxt_cycle_s0_qds_o,
	output logic [7-1:0] adder_7b_res_for_nxt_cycle_s1_qds_o
);

// ================================================================================================================================================
// (local) parameters begin

localparam QUO_DIG_NEG_2_BIT = 4;
localparam QUO_DIG_NEG_1_BIT = 3;
localparam QUO_DIG_NEG_0_BIT = 2;
localparam QUO_DIG_POS_1_BIT = 1;
localparam QUO_DIG_POS_2_BIT = 0;

localparam QUO_DIG_NEG_2 = (1 << 4);
localparam QUO_DIG_NEG_1 = (1 << 3);
localparam QUO_DIG_NEG_0 = (1 << 2);
localparam QUO_DIG_POS_1 = (1 << 1);
localparam QUO_DIG_POS_2 = (1 << 0);

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic [REM_W-1:0] divisor_ext;
logic [REM_W-1:0] divisor_mul_neg_2;
logic [REM_W-1:0] divisor_mul_neg_1;
logic [REM_W-1:0] divisor_mul_pos_1;
logic [REM_W-1:0] divisor_mul_pos_2;

logic [QUO_DIG_W-1:0] nxt_quo_dig [3-1:0];

// f_r = frac_rem
// f_r_s = frac_rem_sum
// f_r_c = frac_rem_carry
logic [REM_W-1:0] nxt_f_r_s [3-1:0];
logic [REM_W-1:0] nxt_f_r_c [3-1:0];
// Speculativly do csa for next stage
logic [REM_W-1:0] nxt_f_r_s_spec_s0 [QUO_DIG_W-1:0];
logic [REM_W-1:0] nxt_f_r_s_spec_s1 [QUO_DIG_W-1:0];
logic [REM_W-1:0] nxt_f_r_s_spec_s2 [QUO_DIG_W-1:0];
logic [REM_W-1:0] nxt_f_r_c_spec_s0 [QUO_DIG_W-1:0];
logic [REM_W-1:0] nxt_f_r_c_spec_s1 [QUO_DIG_W-1:0];
logic [REM_W-1:0] nxt_f_r_c_spec_s2 [QUO_DIG_W-1:0];

// How many adders are needed in this design?
// (7-bit FA) * 5
logic [7-1:0] adder_7b_for_s1_qds_spec [QUO_DIG_W-1:0];
logic [6-1:0] adder_6b_res_for_s1_qds;
// (7-bit FA) * 5
logic [7-1:0] adder_7b_for_s2_qds_in_s0_spec [QUO_DIG_W-1:0];
logic [7-1:0] adder_7b_res_for_s2_qds_in_s0;
// (7-bit FA) * 5
logic [7-1:0] adder_7b_for_s2_qds_in_s1_spec [QUO_DIG_W-1:0];
logic [6-1:0] adder_6b_res_for_s2_qds_in_s1;
// (7-bit FA) * 5
logic [7-1:0] adder_7b_for_nxt_cycle_s0_qds_spec [QUO_DIG_W-1:0];
// (8-bit FA) * 5
logic [8-1:0] adder_8b_for_nxt_cycle_s1_qds_spec [QUO_DIG_W-1:0];


// signals end
// ================================================================================================================================================

assign divisor_ext = {2'b0, divisor_i, 1'b0};
assign divisor_mul_neg_2 = ~{divisor_ext[(REM_W-1)-1:0], 1'b0};
assign divisor_mul_neg_1 = ~divisor_ext;
assign divisor_mul_pos_1 = divisor_ext;
assign divisor_mul_pos_2 = {divisor_ext[(REM_W-1)-1:0], 1'b0};

// ================================================================================================================================================
// stage[0].csa + "adders for stage[1].qds and stage[1].qds"
// ================================================================================================================================================
// Here we assume nxt_quo_dig[0] = -2
assign nxt_f_r_s_spec_s0[4] = 
  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_2;
assign nxt_f_r_c_spec_s0[4] = {
	  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0])
	| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0]),
	1'b0
};

// Here we assume nxt_quo_dig[0] = -1
assign nxt_f_r_s_spec_s0[3] = 
  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_1;
assign nxt_f_r_c_spec_s0[3] = {
	  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0])
	| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0]),
	1'b0
};

// Here we assume nxt_quo_dig[0] = 0
assign nxt_f_r_s_spec_s0[2] = {f_r_s_i[(REM_W-1)-2:0], 2'b0};
assign nxt_f_r_c_spec_s0[2] = {f_r_c_i[(REM_W-1)-2:0], 2'b0};

// Here we assume nxt_quo_dig[0] = +1
assign nxt_f_r_s_spec_s0[1] = 
  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_1;
assign nxt_f_r_c_spec_s0[1] = {
	  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0])
	| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0]),
	1'b1
};

// Here we assume nxt_quo_dig[0] = +2
assign nxt_f_r_s_spec_s0[0] = 
  {f_r_s_i[(REM_W-1)-2:0], 2'b0}
^ {f_r_c_i[(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_2;
assign nxt_f_r_c_spec_s0[0] = {
	  ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & {f_r_c_i[(REM_W-1)-3:0], 2'b0})
	| ({f_r_s_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0])
	| ({f_r_c_i[(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0]),
	1'b1
};

generate if(S1_SPECULATIVE_QDS) begin: g_n_adder_7b_for_s1_qds

	assign adder_7b_for_s1_qds_spec[4] = '0;
	assign adder_7b_for_s1_qds_spec[3] = '0;
	assign adder_7b_for_s1_qds_spec[2] = '0;
	assign adder_7b_for_s1_qds_spec[1] = '0;
	assign adder_7b_for_s1_qds_spec[0] = '0;
	
end else begin: g_adder_7b_for_s1_qds

	assign adder_7b_for_s1_qds_spec[4] = nr_f_r_7b_for_nxt_cycle_s1_qds_i + divisor_mul_pos_2[(REM_W-1)-2 -: 7];
	assign adder_7b_for_s1_qds_spec[3] = nr_f_r_7b_for_nxt_cycle_s1_qds_i + divisor_mul_pos_1[(REM_W-1)-2 -: 7];
	assign adder_7b_for_s1_qds_spec[2] = nr_f_r_7b_for_nxt_cycle_s1_qds_i;
	assign adder_7b_for_s1_qds_spec[1] = nr_f_r_7b_for_nxt_cycle_s1_qds_i + divisor_mul_neg_1[(REM_W-1)-2 -: 7];
	assign adder_7b_for_s1_qds_spec[0] = nr_f_r_7b_for_nxt_cycle_s1_qds_i + divisor_mul_neg_2[(REM_W-1)-2 -: 7];
	
end
endgenerate

assign adder_7b_for_s2_qds_in_s0_spec[4] = nxt_f_r_s_spec_s0[4][(REM_W-1)-4 -: 7] + nxt_f_r_c_spec_s0[4][(REM_W-1)-4 -: 7];
assign adder_7b_for_s2_qds_in_s0_spec[3] = nxt_f_r_s_spec_s0[3][(REM_W-1)-4 -: 7] + nxt_f_r_c_spec_s0[3][(REM_W-1)-4 -: 7];
assign adder_7b_for_s2_qds_in_s0_spec[2] = nxt_f_r_s_spec_s0[2][(REM_W-1)-4 -: 7] + nxt_f_r_c_spec_s0[2][(REM_W-1)-4 -: 7];
assign adder_7b_for_s2_qds_in_s0_spec[1] = nxt_f_r_s_spec_s0[1][(REM_W-1)-4 -: 7] + nxt_f_r_c_spec_s0[1][(REM_W-1)-4 -: 7];
assign adder_7b_for_s2_qds_in_s0_spec[0] = nxt_f_r_s_spec_s0[0][(REM_W-1)-4 -: 7] + nxt_f_r_c_spec_s0[0][(REM_W-1)-4 -: 7];

// ================================================================================================================================================
// stage[0].qds
// ================================================================================================================================================
r4_qds_v2 #(
	.QDS_ARCH(QDS_ARCH)
) u_r4_qds_s0 (
	.rem_i(nr_f_r_6b_for_nxt_cycle_s0_qds_i),
	.quo_dig_o(nxt_quo_dig[0])
);

assign nxt_f_r_s[0] = 
  ({(REM_W){nxt_quo_dig[0][4]}} & nxt_f_r_s_spec_s0[4])
| ({(REM_W){nxt_quo_dig[0][3]}} & nxt_f_r_s_spec_s0[3])
| ({(REM_W){nxt_quo_dig[0][2]}} & nxt_f_r_s_spec_s0[2])
| ({(REM_W){nxt_quo_dig[0][1]}} & nxt_f_r_s_spec_s0[1])
| ({(REM_W){nxt_quo_dig[0][0]}} & nxt_f_r_s_spec_s0[0]);
assign nxt_f_r_c[0] = 
  ({(REM_W){nxt_quo_dig[0][4]}} & nxt_f_r_c_spec_s0[4])
| ({(REM_W){nxt_quo_dig[0][3]}} & nxt_f_r_c_spec_s0[3])
| ({(REM_W){nxt_quo_dig[0][2]}} & nxt_f_r_c_spec_s0[2])
| ({(REM_W){nxt_quo_dig[0][1]}} & nxt_f_r_c_spec_s0[1])
| ({(REM_W){nxt_quo_dig[0][0]}} & nxt_f_r_c_spec_s0[0]);

assign adder_7b_res_for_s2_qds_in_s0 = 
  ({(7){nxt_quo_dig[0][4]}} & adder_7b_for_s2_qds_in_s0_spec[4])
| ({(7){nxt_quo_dig[0][3]}} & adder_7b_for_s2_qds_in_s0_spec[3])
| ({(7){nxt_quo_dig[0][2]}} & adder_7b_for_s2_qds_in_s0_spec[2])
| ({(7){nxt_quo_dig[0][1]}} & adder_7b_for_s2_qds_in_s0_spec[1])
| ({(7){nxt_quo_dig[0][0]}} & adder_7b_for_s2_qds_in_s0_spec[0]);

generate if(S1_SPECULATIVE_QDS) begin: g_n_adder_6b_res_for_s1_qds

	assign adder_6b_res_for_s1_qds = '0;
	
end else begin: g_adder_6b_res_for_s1_qds

	assign adder_6b_res_for_s1_qds = 
	  ({(6){nxt_quo_dig[0][4]}} & adder_7b_for_s1_qds_spec[4][6:1])
	| ({(6){nxt_quo_dig[0][3]}} & adder_7b_for_s1_qds_spec[3][6:1])
	| ({(6){nxt_quo_dig[0][2]}} & adder_7b_for_s1_qds_spec[2][6:1])
	| ({(6){nxt_quo_dig[0][1]}} & adder_7b_for_s1_qds_spec[1][6:1])
	| ({(6){nxt_quo_dig[0][0]}} & adder_7b_for_s1_qds_spec[0][6:1]);

end
endgenerate


// ================================================================================================================================================
// stage[1].csa + "adders for stage[2].qds"
// ================================================================================================================================================
// Here we assume nxt_quo_dig[1] = -2
assign nxt_f_r_s_spec_s1[4] = 
  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_2;
assign nxt_f_r_c_spec_s1[4] = {
	  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0])
	| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0]),
	1'b0
};

// Here we assume nxt_quo_dig[1] = -1
assign nxt_f_r_s_spec_s1[3] = 
  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_1;
assign nxt_f_r_c_spec_s1[3] = {
	  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0])
	| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0]),
	1'b0
};

// Here we assume nxt_quo_dig[1] = 0
assign nxt_f_r_s_spec_s1[2] = {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0};
assign nxt_f_r_c_spec_s1[2] = {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0};

// Here we assume nxt_quo_dig[1] = +1
assign nxt_f_r_s_spec_s1[1] = 
  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_1;
assign nxt_f_r_c_spec_s1[1] = {
	  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0])
	| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0]),
	1'b1
};

// Here we assume nxt_quo_dig[1] = +2
assign nxt_f_r_s_spec_s1[0] = 
  {nxt_f_r_s[0][(REM_W-1)-2:0], 2'b0}
^ {nxt_f_r_c[0][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_2;
assign nxt_f_r_c_spec_s1[0] = {
	  ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0})
	| ({nxt_f_r_s[0][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0])
	| ({nxt_f_r_c[0][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0]),
	1'b1
};

assign adder_7b_for_s2_qds_in_s1_spec[4] = adder_7b_res_for_s2_qds_in_s0 + divisor_mul_pos_2[(REM_W-1)-2 -: 7];
assign adder_7b_for_s2_qds_in_s1_spec[3] = adder_7b_res_for_s2_qds_in_s0 + divisor_mul_pos_1[(REM_W-1)-2 -: 7];
assign adder_7b_for_s2_qds_in_s1_spec[2] = adder_7b_res_for_s2_qds_in_s0;
assign adder_7b_for_s2_qds_in_s1_spec[1] = adder_7b_res_for_s2_qds_in_s0 + divisor_mul_neg_1[(REM_W-1)-2 -: 7];
assign adder_7b_for_s2_qds_in_s1_spec[0] = adder_7b_res_for_s2_qds_in_s0 + divisor_mul_neg_2[(REM_W-1)-2 -: 7];

// ================================================================================================================================================
// stage[1].qds
// ================================================================================================================================================
generate if(S1_SPECULATIVE_QDS) begin: g_speculative_s1_qds

	r4_qds_v2_with_speculation #(
		.QDS_ARCH(QDS_ARCH)
	) u_r4_qds_s1 (
		.rem_i(nr_f_r_7b_for_nxt_cycle_s1_qds_i),
		.divisor_mul_pos_2_i(divisor_mul_pos_2[(REM_W-1)-2 -: 7]),
		.divisor_mul_pos_1_i(divisor_mul_pos_1[(REM_W-1)-2 -: 7]),
		.divisor_mul_neg_1_i(divisor_mul_neg_1[(REM_W-1)-2 -: 7]),
		.divisor_mul_neg_2_i(divisor_mul_neg_2[(REM_W-1)-2 -: 7]),
		.prev_quo_dig_i(nxt_quo_dig[0]),
		.quo_dig_o(nxt_quo_dig[1])
	);

end else begin: g_normal_s1_qds

	r4_qds_v2 #(
		.QDS_ARCH(QDS_ARCH)
	) u_r4_qds_s1 (
		.rem_i(adder_6b_res_for_s1_qds),
		.quo_dig_o(nxt_quo_dig[1])
	);

end
endgenerate

assign nxt_f_r_s[1] = 
  ({(REM_W){nxt_quo_dig[1][4]}} & nxt_f_r_s_spec_s1[4])
| ({(REM_W){nxt_quo_dig[1][3]}} & nxt_f_r_s_spec_s1[3])
| ({(REM_W){nxt_quo_dig[1][2]}} & nxt_f_r_s_spec_s1[2])
| ({(REM_W){nxt_quo_dig[1][1]}} & nxt_f_r_s_spec_s1[1])
| ({(REM_W){nxt_quo_dig[1][0]}} & nxt_f_r_s_spec_s1[0]);
assign nxt_f_r_c[1] = 
  ({(REM_W){nxt_quo_dig[1][4]}} & nxt_f_r_c_spec_s1[4])
| ({(REM_W){nxt_quo_dig[1][3]}} & nxt_f_r_c_spec_s1[3])
| ({(REM_W){nxt_quo_dig[1][2]}} & nxt_f_r_c_spec_s1[2])
| ({(REM_W){nxt_quo_dig[1][1]}} & nxt_f_r_c_spec_s1[1])
| ({(REM_W){nxt_quo_dig[1][0]}} & nxt_f_r_c_spec_s1[0]);

assign adder_6b_res_for_s2_qds_in_s1 = 
  ({(6){nxt_quo_dig[1][4]}} & adder_7b_for_s2_qds_in_s1_spec[4][6:1])
| ({(6){nxt_quo_dig[1][3]}} & adder_7b_for_s2_qds_in_s1_spec[3][6:1])
| ({(6){nxt_quo_dig[1][2]}} & adder_7b_for_s2_qds_in_s1_spec[2][6:1])
| ({(6){nxt_quo_dig[1][1]}} & adder_7b_for_s2_qds_in_s1_spec[1][6:1])
| ({(6){nxt_quo_dig[1][0]}} & adder_7b_for_s2_qds_in_s1_spec[0][6:1]);

// ================================================================================================================================================
// stage[2].csa + "adders for nxt cycle"
// ================================================================================================================================================
// Here we assume nxt_quo_dig[2] = -2
assign nxt_f_r_s_spec_s2[4] = 
  {nxt_f_r_s[1][(REM_W-1)-2:0], 2'b0}
^ {nxt_f_r_c[1][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_2;
assign nxt_f_r_c_spec_s2[4] = {
	  ({nxt_f_r_s[1][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[1][(REM_W-1)-3:0], 2'b0})
	| ({nxt_f_r_s[1][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0])
	| ({nxt_f_r_c[1][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_2[(REM_W-1)-1:0]),
	1'b0
};

// Here we assume nxt_quo_dig21] = -1
assign nxt_f_r_s_spec_s2[3] = 
  {nxt_f_r_s[1][(REM_W-1)-2:0], 2'b0}
^ {nxt_f_r_c[1][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_pos_1;
assign nxt_f_r_c_spec_s2[3] = {
	  ({nxt_f_r_s[1][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[1][(REM_W-1)-3:0], 2'b0})
	| ({nxt_f_r_s[1][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0])
	| ({nxt_f_r_c[1][(REM_W-1)-3:0], 2'b0} & divisor_mul_pos_1[(REM_W-1)-1:0]),
	1'b0
};

// Here we assume nxt_quo_dig[2] = 0
assign nxt_f_r_s_spec_s2[2] = {nxt_f_r_s[1][(REM_W-1)-2:0], 2'b0};
assign nxt_f_r_c_spec_s2[2] = {nxt_f_r_c[1][(REM_W-1)-2:0], 2'b0};

// Here we assume nxt_quo_dig[2] = +1
assign nxt_f_r_s_spec_s2[1] = 
  {nxt_f_r_s[1][(REM_W-1)-2:0], 2'b0}
^ {nxt_f_r_c[1][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_1;
assign nxt_f_r_c_spec_s2[1] = {
	  ({nxt_f_r_s[1][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[1][(REM_W-1)-3:0], 2'b0})
	| ({nxt_f_r_s[1][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0])
	| ({nxt_f_r_c[1][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_1[(REM_W-1)-1:0]),
	1'b1
};

// Here we assume nxt_quo_dig[2] = +2
assign nxt_f_r_s_spec_s2[0] = 
  {nxt_f_r_s[1][(REM_W-1)-2:0], 2'b0}
^ {nxt_f_r_c[1][(REM_W-1)-2:0], 2'b0}
^ divisor_mul_neg_2;
assign nxt_f_r_c_spec_s2[0] = {
	  ({nxt_f_r_s[1][(REM_W-1)-3:0], 2'b0} & {nxt_f_r_c[1][(REM_W-1)-3:0], 2'b0})
	| ({nxt_f_r_s[1][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0])
	| ({nxt_f_r_c[1][(REM_W-1)-3:0], 2'b0} & divisor_mul_neg_2[(REM_W-1)-1:0]),
	1'b1
};

// Get the non_redundant form of REM to make the nxt cycle faster
// Here we assume nxt_quo_dig[2] = -2
assign adder_7b_for_nxt_cycle_s0_qds_spec[4] = 
  nxt_f_r_s[1][(REM_W-1)-2-2 -: 7]
+ nxt_f_r_c[1][(REM_W-1)-2-2 -: 7]
+ divisor_mul_pos_2[(REM_W-1)-2 -: 7];

assign adder_8b_for_nxt_cycle_s1_qds_spec[4] = 
  nxt_f_r_s[1][(REM_W-1)-2-2-2 -: 8]
+ nxt_f_r_c[1][(REM_W-1)-2-2-2 -: 8]
+ divisor_mul_pos_2[(REM_W-1)-2-2 -: 8];

// Here we assume nxt_quo_dig[2] = -1
assign adder_7b_for_nxt_cycle_s0_qds_spec[3] = 
  nxt_f_r_s[1][(REM_W-1)-2-2 -: 7]
+ nxt_f_r_c[1][(REM_W-1)-2-2 -: 7]
+ divisor_mul_pos_1[(REM_W-1)-2 -: 7];

assign adder_8b_for_nxt_cycle_s1_qds_spec[3] = 
  nxt_f_r_s[1][(REM_W-1)-2-2-2 -: 8]
+ nxt_f_r_c[1][(REM_W-1)-2-2-2 -: 8]
+ divisor_mul_pos_1[(REM_W-1)-2-2 -: 8];

// Here we assume nxt_quo_dig[2] = 0
assign adder_7b_for_nxt_cycle_s0_qds_spec[2] = 
  nxt_f_r_s[1][(REM_W-1)-2-2 -: 7]
+ nxt_f_r_c[1][(REM_W-1)-2-2 -: 7];

assign adder_8b_for_nxt_cycle_s1_qds_spec[2] = 
  nxt_f_r_s[1][(REM_W-1)-2-2-2 -: 8]
+ nxt_f_r_c[1][(REM_W-1)-2-2-2 -: 8];

// Here we assume nxt_quo_dig[2] = +1
assign adder_7b_for_nxt_cycle_s0_qds_spec[1] = 
  nxt_f_r_s[1][(REM_W-1)-2-2 -: 7]
+ nxt_f_r_c[1][(REM_W-1)-2-2 -: 7]
+ divisor_mul_neg_1[(REM_W-1)-2 -: 7];

assign adder_8b_for_nxt_cycle_s1_qds_spec[1] = 
  nxt_f_r_s[1][(REM_W-1)-2-2-2 -: 8]
+ nxt_f_r_c[1][(REM_W-1)-2-2-2 -: 8]
+ divisor_mul_neg_1[(REM_W-1)-2-2 -: 8];

// Here we assume nxt_quo_dig[2] = +2
assign adder_7b_for_nxt_cycle_s0_qds_spec[0] = 
  nxt_f_r_s[1][(REM_W-1)-2-2 -: 7]
+ nxt_f_r_c[1][(REM_W-1)-2-2 -: 7]
+ divisor_mul_neg_2[(REM_W-1)-2 -: 7];

assign adder_8b_for_nxt_cycle_s1_qds_spec[0] = 
  nxt_f_r_s[1][(REM_W-1)-2-2-2 -: 8]
+ nxt_f_r_c[1][(REM_W-1)-2-2-2 -: 8]
+ divisor_mul_neg_2[(REM_W-1)-2-2 -: 8];

// ================================================================================================================================================
// stage[2].qds
// ================================================================================================================================================
r4_qds_v2 #(
	.QDS_ARCH(QDS_ARCH)
) u_r4_qds_s2 (
	.rem_i(adder_6b_res_for_s2_qds_in_s1),
	.quo_dig_o(nxt_quo_dig[2])
);

assign nxt_f_r_s[2] = 
  ({(REM_W){nxt_quo_dig[2][4]}} & nxt_f_r_s_spec_s2[4])
| ({(REM_W){nxt_quo_dig[2][3]}} & nxt_f_r_s_spec_s2[3])
| ({(REM_W){nxt_quo_dig[2][2]}} & nxt_f_r_s_spec_s2[2])
| ({(REM_W){nxt_quo_dig[2][1]}} & nxt_f_r_s_spec_s2[1])
| ({(REM_W){nxt_quo_dig[2][0]}} & nxt_f_r_s_spec_s2[0]);
assign nxt_f_r_c[2] = 
  ({(REM_W){nxt_quo_dig[2][4]}} & nxt_f_r_c_spec_s2[4])
| ({(REM_W){nxt_quo_dig[2][3]}} & nxt_f_r_c_spec_s2[3])
| ({(REM_W){nxt_quo_dig[2][2]}} & nxt_f_r_c_spec_s2[2])
| ({(REM_W){nxt_quo_dig[2][1]}} & nxt_f_r_c_spec_s2[1])
| ({(REM_W){nxt_quo_dig[2][0]}} & nxt_f_r_c_spec_s2[0]);

assign adder_6b_res_for_nxt_cycle_s0_qds_o = 
  ({(6){nxt_quo_dig[2][4]}} & adder_7b_for_nxt_cycle_s0_qds_spec[4][6:1])
| ({(6){nxt_quo_dig[2][3]}} & adder_7b_for_nxt_cycle_s0_qds_spec[3][6:1])
| ({(6){nxt_quo_dig[2][2]}} & adder_7b_for_nxt_cycle_s0_qds_spec[2][6:1])
| ({(6){nxt_quo_dig[2][1]}} & adder_7b_for_nxt_cycle_s0_qds_spec[1][6:1])
| ({(6){nxt_quo_dig[2][0]}} & adder_7b_for_nxt_cycle_s0_qds_spec[0][6:1]);
assign adder_7b_res_for_nxt_cycle_s1_qds_o = 
  ({(7){nxt_quo_dig[2][4]}} & adder_8b_for_nxt_cycle_s1_qds_spec[4][7:1])
| ({(7){nxt_quo_dig[2][3]}} & adder_8b_for_nxt_cycle_s1_qds_spec[3][7:1])
| ({(7){nxt_quo_dig[2][2]}} & adder_8b_for_nxt_cycle_s1_qds_spec[2][7:1])
| ({(7){nxt_quo_dig[2][1]}} & adder_8b_for_nxt_cycle_s1_qds_spec[1][7:1])
| ({(7){nxt_quo_dig[2][0]}} & adder_8b_for_nxt_cycle_s1_qds_spec[0][7:1]);

assign nxt_quo_dig_o[0] = nxt_quo_dig[0];
assign nxt_quo_dig_o[1] = nxt_quo_dig[1];
assign nxt_quo_dig_o[2] = nxt_quo_dig[2];

assign nxt_f_r_s_o[0] = nxt_f_r_s[0];
assign nxt_f_r_s_o[1] = nxt_f_r_s[1];
assign nxt_f_r_s_o[2] = nxt_f_r_s[2];

assign nxt_f_r_c_o[0] = nxt_f_r_c[0];
assign nxt_f_r_c_o[1] = nxt_f_r_c[1];
assign nxt_f_r_c_o[2] = nxt_f_r_c[2];


// ================================================================================================================================================
// TEST SIGNALS
// ================================================================================================================================================
logic [REM_W-1:0] nxt_nr_f_r [3-1:0];

assign nxt_nr_f_r[0] = nxt_f_r_s[0] + nxt_f_r_c[0];
assign nxt_nr_f_r[1] = nxt_f_r_s[1] + nxt_f_r_c[1];
assign nxt_nr_f_r[2] = nxt_f_r_s[2] + nxt_f_r_c[2];

endmodule
