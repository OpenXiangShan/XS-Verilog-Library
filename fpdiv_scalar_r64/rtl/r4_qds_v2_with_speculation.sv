// ========================================================================================================
// File Name			: r4_qds_v2_with_speculation.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2022-01-01 21:15:32
// Last Modified Time   : 2022-01-11 22:03:09
// ========================================================================================================
// Description	:
// Modifed from r4_qds_v2. This is used to calculate the q[i+2].
// This module should lead to less delay but larger area, if the timing is OK then just use r4_qds_v2.
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

module r4_qds_v2_with_speculation #(
	// Put some parameters here, which can be changed by other modules.

	// You should try which config could lead to best PPA.
	// 0: Native expression
	// 1: Comparator based
	// 2: Adder based
	parameter QDS_ARCH = 2
)(
	input  logic [7-1:0] rem_i,
	input  logic [7-1:0] divisor_mul_pos_2_i,
	input  logic [7-1:0] divisor_mul_pos_1_i,
	input  logic [7-1:0] divisor_mul_neg_1_i,
	input  logic [7-1:0] divisor_mul_neg_2_i,
	input  logic [5-1:0] prev_quo_dig_i,
	output logic [5-1:0] quo_dig_o
);

// ================================================================================================================================================
// (local) parameters begin

localparam [6-1:0] M_POS_2 = 6'd12;
localparam [6-1:0] M_POS_1 = 6'd3;
// -4 = 11_1100
// -13 = 11_0011
localparam [6-1:0] M_NEG_0 = -(6'd4);
localparam [6-1:0] M_NEG_1 = -(6'd13);

localparam [6-1:0] M_POS_2_NEGATED = -(6'd12);
localparam [6-1:0] M_POS_1_NEGATED = -(6'd3);
localparam [6-1:0] M_NEG_0_NEGATED = 6'd4;
localparam [6-1:0] M_NEG_1_NEGATED = 6'd13;

// (local) parameters end
// ================================================================================================================================================

// ================================================================================================================================================
// signals begin

logic [7-1:0] adder_7b_spec [5-1:0];

logic [4-1:0] qds_sign;
logic [4-1:0] qds_sign_spec [5-1:0];
logic [6-1:0] unused_bit_prev_q_neg_2 [4-1:0];
logic [6-1:0] unused_bit_prev_q_neg_1 [4-1:0];
logic [6-1:0] unused_bit_prev_q_neg_0 [4-1:0];
logic [6-1:0] unused_bit_prev_q_pos_1 [4-1:0];
logic [6-1:0] unused_bit_prev_q_pos_2 [4-1:0];

logic rem_ge_m_pos_2_spec [5-1:0];
logic rem_ge_m_pos_1_spec [5-1:0];
logic rem_ge_m_neg_0_spec [5-1:0];
logic rem_ge_m_neg_1_spec [5-1:0];
logic rem_ge_m_pos_2;
logic rem_ge_m_pos_1;
logic rem_ge_m_neg_0;
logic rem_ge_m_neg_1;

logic [5-1:0] quo_dig_spec [5-1:0];

// signals end
// ================================================================================================================================================

// The SEL logic is:
// rem >= m[+2]			: quo = +2
// m[+1] <= rem < m[+2]	: quo = +1
// m[-0] <= rem < m[+1]	: quo = -0
// m[-1] <= rem < m[-0]	: quo = -1
// rem < m[-1]			: quo = -2

generate
if(QDS_ARCH == 0) begin

	assign adder_7b_spec[4] = rem_i + divisor_mul_pos_2_i;
	assign adder_7b_spec[3] = rem_i + divisor_mul_pos_1_i;
	assign adder_7b_spec[2] = rem_i;
	assign adder_7b_spec[1] = rem_i + divisor_mul_neg_1_i;
	assign adder_7b_spec[0] = rem_i + divisor_mul_neg_2_i;

	assign quo_dig_spec[4][4] = ($signed(adder_7b_spec[4][6:1]) <= -14);
	assign quo_dig_spec[4][3] = ($signed(adder_7b_spec[4][6:1]) >= -13) & ($signed(adder_7b_spec[4][6:1]) <= -5);
	assign quo_dig_spec[4][2] = ($signed(adder_7b_spec[4][6:1]) >=  -4) & ($signed(adder_7b_spec[4][6:1]) <=  2);
	assign quo_dig_spec[4][1] = ($signed(adder_7b_spec[4][6:1]) >=   3) & ($signed(adder_7b_spec[4][6:1]) <= 11);
	assign quo_dig_spec[4][0] = ($signed(adder_7b_spec[4][6:1]) >=  12);

	assign quo_dig_spec[3][4] = ($signed(adder_7b_spec[3][6:1]) <= -14);
	assign quo_dig_spec[3][3] = ($signed(adder_7b_spec[3][6:1]) >= -13) & ($signed(adder_7b_spec[3][6:1]) <= -5);
	assign quo_dig_spec[3][2] = ($signed(adder_7b_spec[3][6:1]) >=  -4) & ($signed(adder_7b_spec[3][6:1]) <=  2);
	assign quo_dig_spec[3][1] = ($signed(adder_7b_spec[3][6:1]) >=   3) & ($signed(adder_7b_spec[3][6:1]) <= 11);
	assign quo_dig_spec[3][0] = ($signed(adder_7b_spec[3][6:1]) >=  12);

	assign quo_dig_spec[2][4] = ($signed(adder_7b_spec[2][6:1]) <= -14);
	assign quo_dig_spec[2][3] = ($signed(adder_7b_spec[2][6:1]) >= -13) & ($signed(adder_7b_spec[2][6:1]) <= -5);
	assign quo_dig_spec[2][2] = ($signed(adder_7b_spec[2][6:1]) >=  -4) & ($signed(adder_7b_spec[2][6:1]) <=  2);
	assign quo_dig_spec[2][1] = ($signed(adder_7b_spec[2][6:1]) >=   3) & ($signed(adder_7b_spec[2][6:1]) <= 11);
	assign quo_dig_spec[2][0] = ($signed(adder_7b_spec[2][6:1]) >=  12);

	assign quo_dig_spec[1][4] = ($signed(adder_7b_spec[1][6:1]) <= -14);
	assign quo_dig_spec[1][3] = ($signed(adder_7b_spec[1][6:1]) >= -13) & ($signed(adder_7b_spec[1][6:1]) <= -5);
	assign quo_dig_spec[1][2] = ($signed(adder_7b_spec[1][6:1]) >=  -4) & ($signed(adder_7b_spec[1][6:1]) <=  2);
	assign quo_dig_spec[1][1] = ($signed(adder_7b_spec[1][6:1]) >=   3) & ($signed(adder_7b_spec[1][6:1]) <= 11);
	assign quo_dig_spec[1][0] = ($signed(adder_7b_spec[1][6:1]) >=  12);

	assign quo_dig_spec[0][4] = ($signed(adder_7b_spec[0][6:1]) <= -14);
	assign quo_dig_spec[0][3] = ($signed(adder_7b_spec[0][6:1]) >= -13) & ($signed(adder_7b_spec[0][6:1]) <= -5);
	assign quo_dig_spec[0][2] = ($signed(adder_7b_spec[0][6:1]) >=  -4) & ($signed(adder_7b_spec[0][6:1]) <=  2);
	assign quo_dig_spec[0][1] = ($signed(adder_7b_spec[0][6:1]) >=   3) & ($signed(adder_7b_spec[0][6:1]) <= 11);
	assign quo_dig_spec[0][0] = ($signed(adder_7b_spec[0][6:1]) >=  12);

	assign quo_dig_o = 
	  ({(5){prev_quo_dig_i[4]}} & quo_dig_spec[4])
	| ({(5){prev_quo_dig_i[3]}} & quo_dig_spec[3])
	| ({(5){prev_quo_dig_i[2]}} & quo_dig_spec[2])
	| ({(5){prev_quo_dig_i[1]}} & quo_dig_spec[1])
	| ({(5){prev_quo_dig_i[0]}} & quo_dig_spec[0]);

end else if(QDS_ARCH == 1) begin

	assign adder_7b_spec[4] = rem_i + divisor_mul_pos_2_i;
	assign adder_7b_spec[3] = rem_i + divisor_mul_pos_1_i;
	assign adder_7b_spec[2] = rem_i;
	assign adder_7b_spec[1] = rem_i + divisor_mul_neg_1_i;
	assign adder_7b_spec[0] = rem_i + divisor_mul_neg_2_i;

	assign rem_ge_m_pos_2_spec[4] = ($signed(adder_7b_spec[4][6:1]) >= $signed(M_POS_2));
	assign rem_ge_m_pos_1_spec[4] = ($signed(adder_7b_spec[4][6:1]) >= $signed(M_POS_1));
	assign rem_ge_m_neg_0_spec[4] = ($signed(adder_7b_spec[4][6:1]) >= $signed(M_NEG_0));
	assign rem_ge_m_neg_1_spec[4] = ($signed(adder_7b_spec[4][6:1]) >= $signed(M_NEG_1));

	assign rem_ge_m_pos_2_spec[3] = ($signed(adder_7b_spec[3][6:1]) >= $signed(M_POS_2));
	assign rem_ge_m_pos_1_spec[3] = ($signed(adder_7b_spec[3][6:1]) >= $signed(M_POS_1));
	assign rem_ge_m_neg_0_spec[3] = ($signed(adder_7b_spec[3][6:1]) >= $signed(M_NEG_0));
	assign rem_ge_m_neg_1_spec[3] = ($signed(adder_7b_spec[3][6:1]) >= $signed(M_NEG_1));

	assign rem_ge_m_pos_2_spec[2] = ($signed(adder_7b_spec[2][6:1]) >= $signed(M_POS_2));
	assign rem_ge_m_pos_1_spec[2] = ($signed(adder_7b_spec[2][6:1]) >= $signed(M_POS_1));
	assign rem_ge_m_neg_0_spec[2] = ($signed(adder_7b_spec[2][6:1]) >= $signed(M_NEG_0));
	assign rem_ge_m_neg_1_spec[2] = ($signed(adder_7b_spec[2][6:1]) >= $signed(M_NEG_1));

	assign rem_ge_m_pos_2_spec[1] = ($signed(adder_7b_spec[1][6:1]) >= $signed(M_POS_2));
	assign rem_ge_m_pos_1_spec[1] = ($signed(adder_7b_spec[1][6:1]) >= $signed(M_POS_1));
	assign rem_ge_m_neg_0_spec[1] = ($signed(adder_7b_spec[1][6:1]) >= $signed(M_NEG_0));
	assign rem_ge_m_neg_1_spec[1] = ($signed(adder_7b_spec[1][6:1]) >= $signed(M_NEG_1));

	assign rem_ge_m_pos_2_spec[0] = ($signed(adder_7b_spec[0][6:1]) >= $signed(M_POS_2));
	assign rem_ge_m_pos_1_spec[0] = ($signed(adder_7b_spec[0][6:1]) >= $signed(M_POS_1));
	assign rem_ge_m_neg_0_spec[0] = ($signed(adder_7b_spec[0][6:1]) >= $signed(M_NEG_0));
	assign rem_ge_m_neg_1_spec[0] = ($signed(adder_7b_spec[0][6:1]) >= $signed(M_NEG_1));

	// When we get the above signals, the "prev_quo_dig_i" must be ready.

	assign rem_ge_m_pos_2 = 
	  ({(1){prev_quo_dig_i[4]}} & rem_ge_m_pos_2_spec[4])
	| ({(1){prev_quo_dig_i[3]}} & rem_ge_m_pos_2_spec[3])
	| ({(1){prev_quo_dig_i[2]}} & rem_ge_m_pos_2_spec[2])
	| ({(1){prev_quo_dig_i[1]}} & rem_ge_m_pos_2_spec[1])
	| ({(1){prev_quo_dig_i[0]}} & rem_ge_m_pos_2_spec[0]);

	assign rem_ge_m_pos_1 = 
	  ({(1){prev_quo_dig_i[4]}} & rem_ge_m_pos_1_spec[4])
	| ({(1){prev_quo_dig_i[3]}} & rem_ge_m_pos_1_spec[3])
	| ({(1){prev_quo_dig_i[2]}} & rem_ge_m_pos_1_spec[2])
	| ({(1){prev_quo_dig_i[1]}} & rem_ge_m_pos_1_spec[1])
	| ({(1){prev_quo_dig_i[0]}} & rem_ge_m_pos_1_spec[0]);

	assign rem_ge_m_neg_0 = 
	  ({(1){prev_quo_dig_i[4]}} & rem_ge_m_neg_0_spec[4])
	| ({(1){prev_quo_dig_i[3]}} & rem_ge_m_neg_0_spec[3])
	| ({(1){prev_quo_dig_i[2]}} & rem_ge_m_neg_0_spec[2])
	| ({(1){prev_quo_dig_i[1]}} & rem_ge_m_neg_0_spec[1])
	| ({(1){prev_quo_dig_i[0]}} & rem_ge_m_neg_0_spec[0]);

	assign rem_ge_m_neg_1 = 
	  ({(1){prev_quo_dig_i[4]}} & rem_ge_m_neg_1_spec[4])
	| ({(1){prev_quo_dig_i[3]}} & rem_ge_m_neg_1_spec[3])
	| ({(1){prev_quo_dig_i[2]}} & rem_ge_m_neg_1_spec[2])
	| ({(1){prev_quo_dig_i[1]}} & rem_ge_m_neg_1_spec[1])
	| ({(1){prev_quo_dig_i[0]}} & rem_ge_m_neg_1_spec[0]);

	assign quo_dig_o[4] = ~rem_ge_m_neg_1;
	assign quo_dig_o[3] =  rem_ge_m_neg_1 & ~rem_ge_m_neg_0;
	assign quo_dig_o[2] =  rem_ge_m_neg_0 & ~rem_ge_m_pos_1;
	assign quo_dig_o[1] =  rem_ge_m_pos_1 & ~rem_ge_m_pos_2;
	assign quo_dig_o[0] =  rem_ge_m_pos_2;

end else begin

	assign {qds_sign_spec[4][3], unused_bit_prev_q_neg_2[3]} = rem_i + divisor_mul_pos_2_i + {M_POS_2_NEGATED, 1'b0};
	assign {qds_sign_spec[4][2], unused_bit_prev_q_neg_2[2]} = rem_i + divisor_mul_pos_2_i + {M_POS_1_NEGATED, 1'b0};
	assign {qds_sign_spec[4][1], unused_bit_prev_q_neg_2[1]} = rem_i + divisor_mul_pos_2_i + {M_NEG_0_NEGATED, 1'b0};
	assign {qds_sign_spec[4][0], unused_bit_prev_q_neg_2[0]} = rem_i + divisor_mul_pos_2_i + {M_NEG_1_NEGATED, 1'b0};

	assign {qds_sign_spec[3][3], unused_bit_prev_q_neg_1[3]} = rem_i + divisor_mul_pos_1_i + {M_POS_2_NEGATED, 1'b0};
	assign {qds_sign_spec[3][2], unused_bit_prev_q_neg_1[2]} = rem_i + divisor_mul_pos_1_i + {M_POS_1_NEGATED, 1'b0};
	assign {qds_sign_spec[3][1], unused_bit_prev_q_neg_1[1]} = rem_i + divisor_mul_pos_1_i + {M_NEG_0_NEGATED, 1'b0};
	assign {qds_sign_spec[3][0], unused_bit_prev_q_neg_1[0]} = rem_i + divisor_mul_pos_1_i + {M_NEG_1_NEGATED, 1'b0};

	assign {qds_sign_spec[2][3], unused_bit_prev_q_neg_0[3]} = rem_i + {M_POS_2_NEGATED, 1'b0};
	assign {qds_sign_spec[2][2], unused_bit_prev_q_neg_0[2]} = rem_i + {M_POS_1_NEGATED, 1'b0};
	assign {qds_sign_spec[2][1], unused_bit_prev_q_neg_0[1]} = rem_i + {M_NEG_0_NEGATED, 1'b0};
	assign {qds_sign_spec[2][0], unused_bit_prev_q_neg_0[0]} = rem_i + {M_NEG_1_NEGATED, 1'b0};

	assign {qds_sign_spec[1][3], unused_bit_prev_q_pos_1[3]} = rem_i + divisor_mul_neg_1_i + {M_POS_2_NEGATED, 1'b0};
	assign {qds_sign_spec[1][2], unused_bit_prev_q_pos_1[2]} = rem_i + divisor_mul_neg_1_i + {M_POS_1_NEGATED, 1'b0};
	assign {qds_sign_spec[1][1], unused_bit_prev_q_pos_1[1]} = rem_i + divisor_mul_neg_1_i + {M_NEG_0_NEGATED, 1'b0};
	assign {qds_sign_spec[1][0], unused_bit_prev_q_pos_1[0]} = rem_i + divisor_mul_neg_1_i + {M_NEG_1_NEGATED, 1'b0};

	assign {qds_sign_spec[0][3], unused_bit_prev_q_pos_2[3]} = rem_i + divisor_mul_neg_2_i + {M_POS_2_NEGATED, 1'b0};
	assign {qds_sign_spec[0][2], unused_bit_prev_q_pos_2[2]} = rem_i + divisor_mul_neg_2_i + {M_POS_1_NEGATED, 1'b0};
	assign {qds_sign_spec[0][1], unused_bit_prev_q_pos_2[1]} = rem_i + divisor_mul_neg_2_i + {M_NEG_0_NEGATED, 1'b0};
	assign {qds_sign_spec[0][0], unused_bit_prev_q_pos_2[0]} = rem_i + divisor_mul_neg_2_i + {M_NEG_1_NEGATED, 1'b0};

	// When we get the above signals, the "prev_quo_dig_i" must be ready.

	assign qds_sign = 
	  ({(4){prev_quo_dig_i[4]}} & qds_sign_spec[4])
	| ({(4){prev_quo_dig_i[3]}} & qds_sign_spec[3])
	| ({(4){prev_quo_dig_i[2]}} & qds_sign_spec[2])
	| ({(4){prev_quo_dig_i[1]}} & qds_sign_spec[1])
	| ({(4){prev_quo_dig_i[0]}} & qds_sign_spec[0]);

	// assign quo_dig_o[4] = (qds_sign[0]   == 1'b1);
	assign quo_dig_o[4] = (qds_sign[1:0] == 2'b11);
	assign quo_dig_o[3] = (qds_sign[1:0] == 2'b10);
	assign quo_dig_o[2] = (qds_sign[2:1] == 2'b10);
	assign quo_dig_o[1] = (qds_sign[3:2] == 2'b10);
	// assign quo_dig_o[0] = (qds_sign[3]   == 1'b0);
	assign quo_dig_o[0] = (qds_sign[3:2] == 2'b00);
	
end
endgenerate



endmodule
