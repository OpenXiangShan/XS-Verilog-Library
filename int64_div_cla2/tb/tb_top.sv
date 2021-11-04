// ========================================================================================================
// File Name			: tb_top.sv
// Author				: HYF
// How to Contact		: hyf_sysu@qq.com
// Created Time    		: 2021-07-23 10:08:49
// Last Modified Time   : 2021-10-31 14:45:15
// ========================================================================================================
// Description	:
// TB for R16_SRT formed by 2 overlapped R4_SRT.
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
`define MAX_ERR_COUNT 5
// `define USE_SHORT_DELAY
`include "tb_defines.svh"
// If DUT doesn't have valid-ready control logic itself, don't use this definition.
// `define DUT_HAS_VALID_READY

`define SINGLE_STIM \
dut_start_valid = 1; \
`WAIT_COMB_SIG(clk, (dut_start_valid & dut_start_ready)) \
`APPL_WAIT_CYC(clk, 1) \
dut_start_valid = 0; \
 \
`WAIT_SIG(clk, (dut_finish_valid & dut_finish_ready)) \
dut_start_valid_after_finish_handshake_delay = $urandom() % `VALID_READY_DELAY; \
`APPL_WAIT_CYC(clk, dut_start_valid_after_finish_handshake_delay)


module tb_top #(
	// Put some parameters here, which can be changed by other modules
	
)(
);

// ==================================================================================================================================================
// (local) params
// ==================================================================================================================================================

localparam DUT_WIDTH = 32;

localparam OPCODE_SIGNED = 1'b1;
localparam OPCODE_UNSIGNED = 1'b0;

localparam SIGNED_SINGLE_TEST_NUM = 8;
localparam SIGNED_RANDOM_TEST_NUM = 2 ** 10;
localparam SIGNED_TEST_NUM = SIGNED_SINGLE_TEST_NUM + SIGNED_RANDOM_TEST_NUM;
localparam UNSIGNED_SINGLE_TEST_NUM = 9;
localparam UNSIGNED_RANDOM_TEST_NUM = 2 ** 10;
localparam UNSIGNED_TEST_NUM = UNSIGNED_SINGLE_TEST_NUM + UNSIGNED_RANDOM_TEST_NUM;

localparam TEST_NUM = SIGNED_TEST_NUM + UNSIGNED_TEST_NUM;

localparam UINT64_POS_MAX = {(64){1'b1}};
localparam INT64_POS_MAX = {1'b0, {(63){1'b1}}};
localparam INT64_NEG_MIN = {1'b1, {(63){1'b0}}};
localparam INT64_NEG_ONE = {(64){1'b1}};

localparam UINT32_POS_MAX = {(32){1'b1}};
localparam INT32_POS_MAX = {1'b0, {(31){1'b1}}};
localparam INT32_NEG_MIN = {1'b1, {(31){1'b0}}};
localparam INT32_NEG_ONE = {(32){1'b1}};

localparam UINT16_POS_MAX = {(16){1'b1}};
localparam INT16_POS_MAX = {1'b0, {(15){1'b1}}};
localparam INT16_NEG_MIN = {1'b1, {(15){1'b0}}};
localparam INT16_NEG_ONE = {(16){1'b1}};

// ==================================================================================================================================================
// functions
// ==================================================================================================================================================



// ==================================================================================================================================================
// signals
// ==================================================================================================================================================

// common signals
logic clk;
logic rst_n;
int i;
logic simulation_start;
logic stim_end;
logic acq_trig;
logic [31:0] acq_count;
logic [31:0] err_count;
int fptr;

logic compare_ok;
logic dut_start_valid;
logic dut_start_ready;
logic dut_finish_valid;
logic dut_finish_ready;
// tb向dut发送的后一个start_valid和前一个finish_handshake之间的延迟
logic [31:0] dut_start_valid_after_finish_handshake_delay;
// tb向dut发送了start_valid之后，dut向tb发送start_ready之间的延迟
logic [31:0] dut_start_ready_after_start_valid_delay;
// tb发送到dut的finish_ready和dut发送到tb中的finish_valid之间的延迟
logic [31:0] dut_finish_ready_after_finish_valid_delay;
// start_valid = 1之后，dut向tb发送的finish_valid之间的延迟
logic [31:0] dut_finish_valid_after_start_handshake_delay;


// signals related with DUT.
logic [1-1:0] opcode;
logic [64-1:0] dividend_64;
logic [64-1:0] dividend_abs_64;
logic [64-1:0] divisor_64;
logic [64-1:0] divisor_abs_64;

logic [32-1:0] dividend_32;
logic [32-1:0] dividend_abs_32;
logic [32-1:0] divisor_32;
logic [32-1:0] divisor_abs_32;

logic [16-1:0] dividend_16;
logic [16-1:0] dividend_abs_16;
logic [16-1:0] divisor_16;
logic [16-1:0] divisor_abs_16;

logic [5:0] dividend_64_lzc;
logic [4:0] dividend_32_lzc;
logic [3:0] dividend_16_lzc;

logic [5:0] divisor_64_lzc;
logic [4:0] divisor_32_lzc;
logic [3:0] divisor_16_lzc;

logic neg_quotient_64;
logic neg_remainder_64;
logic neg_quotient_32;
logic neg_remainder_32;
logic neg_quotient_16;
logic neg_remainder_16;
logic [64-1:0] quotient_64;
logic [64-1:0] remainder_64;
logic [32-1:0] quotient_32;
logic [32-1:0] remainder_32;
logic [16-1:0] quotient_16;
logic [16-1:0] remainder_16;
logic divisor_is_zero_64;
logic divisor_is_zero_32;
logic divisor_is_zero_16;

logic [64-1:0] dut_quotient_64;
logic [64-1:0] dut_remainder_64;
logic [32-1:0] dut_quotient_32;
logic [32-1:0] dut_remainder_32;
logic [16-1:0] dut_quotient_16;
logic [16-1:0] dut_remainder_16;
logic dut_divisor_is_zero_64;
logic dut_divisor_is_zero_32;
logic dut_divisor_is_zero_16;
logic [96-1:0] unused_bits;

// ==================================================================================================================================================
// main codes
// ==================================================================================================================================================



// ================================================================================================================================================
// application process

initial begin
	dividend_64 = 0;
	divisor_64 = 0;
	dividend_32 = 0;
	divisor_32 = 0;
	dividend_32 = 0;
	divisor_32 = 0;
	opcode = OPCODE_SIGNED;
	dut_start_valid = 0;
	acq_trig = 0;
	stim_end = 0;

	`APPL_WAIT_SIG(clk, simulation_start)
	$display("TB: stimuli application starts!");

	acq_trig = 1;
	`APPL_WAIT_CYC(clk, 2)
	acq_trig = 0;

	`include "tb_stim_unsigned.svh"
	`include "tb_stim_signed.svh"
	

	`WAIT_CYC(clk, 20)
	stim_end = 1;
end

// ================================================================================================================================================

// ================================================================================================================================================
// acquisition process

initial begin
	dut_finish_ready = 0;
	fptr = $fopen("result.txt", "w+");
	$display("TB: response acquisition starts!");

	// wait for acquisition trigger
	do begin
		`RESP_WAIT_CYC(clk, 1)
		if(stim_end == 1)
		begin
			$display("response acquisition finishes!");
			$display("TB finishes!");
			$fclose(fptr);
			$stop();
		end
	end while(acq_trig == 1'b0);

	acq_count = 0;
	err_count = 0;

	do begin
		`WAIT_COMB_SIG(clk, dut_start_valid)
		`WAIT_COMB_SIG(clk, dut_finish_valid)
		dut_finish_ready_after_finish_valid_delay = $urandom() % `VALID_READY_DELAY;
		`RESP_WAIT_CYC(clk, dut_finish_ready_after_finish_valid_delay)
		dut_finish_ready = 1;

		if((compare_ok == 0) | (compare_ok == 1'bX)) begin
			$display("ERROR FOUND:");
			if(DUT_WIDTH == 64) begin
				$fdisplay(fptr, "------------------------------------------------------------------------------------");
				$fdisplay(fptr, "ERROR FOUND:");
				$fdisplay(fptr, "dividend = %h, divisor = %h", dividend_64, divisor_64);
				$fdisplay(fptr, "opcode = %b", opcode);
				$fdisplay(fptr, "exp_quotient = %h, exp_remainder = %h, act_quotient = %h, act_remainder = %h", quotient_64, remainder_64, dut_quotient_64, dut_remainder_64);
				$fdisplay(fptr, "exp_divisor_is_zero = %b, dut_divisor_is_zero = %b", divisor_is_zero_64, dut_divisor_is_zero_64);
			end
			else if(DUT_WIDTH == 32) begin
				$fdisplay(fptr, "------------------------------------------------------------------------------------");
				$fdisplay(fptr, "ERROR FOUND:");
				$fdisplay(fptr, "dividend = %h, divisor = %h", dividend_32, divisor_32);
				$fdisplay(fptr, "opcode = %b", opcode);
				$fdisplay(fptr, "exp_quotient = %h, exp_remainder = %h, act_quotient = %h, act_remainder = %h", quotient_32, remainder_32, dut_quotient_32, dut_remainder_32);
				$fdisplay(fptr, "exp_divisor_is_zero = %b, dut_divisor_is_zero = %b", divisor_is_zero_32, dut_divisor_is_zero_32);
			end
			else begin
				$fdisplay(fptr, "------------------------------------------------------------------------------------");
				$fdisplay(fptr, "ERROR FOUND:");
				$fdisplay(fptr, "dividend = %h, divisor = %h", dividend_16, divisor_16);
				$fdisplay(fptr, "opcode = %b", opcode);
				$fdisplay(fptr, "exp_quotient = %h, exp_remainder = %h, act_quotient = %h, act_remainder = %h", quotient_16, remainder_16, dut_quotient_16, dut_remainder_16);
				$fdisplay(fptr, "exp_divisor_is_zero = %b, dut_divisor_is_zero = %b", divisor_is_zero_16, dut_divisor_is_zero_16);
			end			

			err_count++;
		end

		if(err_count == `MAX_ERR_COUNT) begin
			$fdisplay(fptr, "finished_test_num = %d, error_test_num = %d", acq_count, err_count);
			$display("Too many ERRORs, stop simulation!!!");
			$fclose(fptr);
			$stop();
		end

		acq_count++;
		`RESP_WAIT_SIG(clk, dut_finish_ready)
		dut_finish_ready = 0;

		if((acq_count != 0) & (acq_count % (2 ** 16) == 0))
			$display("Simulation is still running !!!");

	end while(acq_count < TEST_NUM);

	`WAIT_SIG(clk, stim_end)
	`WAIT_CYC(clk, 20)
	$fdisplay(fptr, "\n");
	$fdisplay(fptr, "------------------------------------------------------------------------------------");
	$fdisplay(fptr, "finished_test_num = %d, error_test_num = %d", acq_count, err_count);
	$display("response acquisition finishes!");
	$display("TB finishes!");
	$fclose(fptr);
	$stop();
end

// ================================================================================================================================================

// ================================================================================================================================================
// calculate expected result

always_comb begin
	neg_quotient_64 = (opcode == OPCODE_SIGNED) & (dividend_64[63] ^ divisor_64[63]);
	neg_remainder_64 = (opcode == OPCODE_SIGNED) & (dividend_64[63]);
	neg_quotient_32 = (opcode == OPCODE_SIGNED) & (dividend_32[31] ^ divisor_32[31]);
	neg_remainder_32 = (opcode == OPCODE_SIGNED) & (dividend_32[31]);
	neg_quotient_16 = (opcode == OPCODE_SIGNED) & (dividend_16[15] ^ divisor_16[15]);
	neg_remainder_16 = (opcode == OPCODE_SIGNED) & (dividend_16[15]);

	dividend_abs_64 = (dividend_64[63] & (opcode == OPCODE_SIGNED)) ? -dividend_64 : dividend_64;
	divisor_abs_64 = (divisor_64[63] & (opcode == OPCODE_SIGNED)) ? -divisor_64 : divisor_64;
	dividend_abs_32 = (dividend_32[31] & (opcode == OPCODE_SIGNED)) ? -dividend_32 : dividend_32;
	divisor_abs_32 = (divisor_32[31] & (opcode == OPCODE_SIGNED)) ? -divisor_32 : divisor_32;
	dividend_abs_16 = (dividend_16[15] & (opcode == OPCODE_SIGNED)) ? -dividend_16 : dividend_16;
	divisor_abs_16 = (divisor_16[15] & (opcode == OPCODE_SIGNED)) ? -divisor_16 : divisor_16;

	quotient_64 = neg_quotient_64 ? -(dividend_abs_64 / divisor_abs_64) : (dividend_abs_64 / divisor_abs_64);
	remainder_64 = neg_remainder_64 ? -(dividend_abs_64 % divisor_abs_64) : (dividend_abs_64 % divisor_abs_64);
	quotient_32 = neg_quotient_32 ? -(dividend_abs_32 / divisor_abs_32) : (dividend_abs_32 / divisor_abs_32);
	remainder_32 = neg_remainder_32 ? -(dividend_abs_32 % divisor_abs_32) : (dividend_abs_32 % divisor_abs_32);
	quotient_16 = neg_quotient_16 ? -(dividend_abs_16 / divisor_abs_16) : (dividend_abs_16 / divisor_abs_16);
	remainder_16 = neg_remainder_16 ? -(dividend_abs_16 % divisor_abs_16) : (dividend_abs_16 % divisor_abs_16);

	divisor_is_zero_64 = (divisor_64 == 0);
	divisor_is_zero_32 = (divisor_32 == 0);
	divisor_is_zero_16 = (divisor_16 == 0);

	if(opcode == OPCODE_SIGNED) begin
		if(divisor_64 == 0) begin
			quotient_64 = UINT64_POS_MAX;
			remainder_64 = dividend_64;
		end
		else if((dividend_64 == INT64_NEG_MIN) & (divisor_64 == INT64_NEG_ONE)) begin
			quotient_64 = INT64_NEG_MIN;
			remainder_64 = 0;
		end

		if(divisor_32 == 0) begin
			quotient_32 = UINT32_POS_MAX;
			remainder_32 = dividend_32;
		end
		else if((dividend_32 == INT32_NEG_MIN) & (divisor_32 == INT32_NEG_ONE)) begin
			quotient_32 = INT32_NEG_MIN;
			remainder_32 = 0;
		end

		if(divisor_16 == 0) begin
			quotient_16 = UINT16_POS_MAX;
			remainder_16 = dividend_16;
		end
		else if((dividend_16 == INT16_NEG_MIN) & (divisor_16 == INT16_NEG_ONE)) begin
			quotient_16 = INT16_NEG_MIN;
			remainder_16 = 0;
		end
	end
	else begin
		if(divisor_64 == 0) begin
			quotient_64 = UINT64_POS_MAX;
			remainder_64 = dividend_64;
		end

		if(divisor_32 == 0) begin
			quotient_32 = UINT32_POS_MAX;
			remainder_32 = dividend_32;
		end

		if(divisor_16 == 0) begin
			quotient_16 = UINT16_POS_MAX;
			remainder_16 = dividend_16;
		end
	end

	if(DUT_WIDTH == 64)
		compare_ok = (quotient_64 == dut_quotient_64) & (remainder_64 == dut_remainder_64) & (divisor_is_zero_64 == dut_divisor_is_zero_64);
	else if(DUT_WIDTH == 32)
		compare_ok = (quotient_32 == dut_quotient_32) & (remainder_32 == dut_remainder_32) & (divisor_is_zero_32 == dut_divisor_is_zero_32);
	else
		compare_ok = (quotient_16 == dut_quotient_16) & (remainder_16 == dut_remainder_16) & (divisor_is_zero_16 == dut_divisor_is_zero_16);
end

// ================================================================================================================================================
// Instantiate DUT here.

generate
if(DUT_WIDTH == 64) begin: g_dut_64
	int64_div_cla2 
	u_dut (
		.op_format_i(2'b10),
		.op_sign_i(opcode),
		.dividend_i(dividend_64),
		.divisor_i(divisor_64),
		.quotient_o(dut_quotient_64),
		.remainder_o(dut_remainder_64),
		.divisor_is_zero_o(dut_divisor_is_zero_64)
	);
end
else if(DUT_WIDTH == 32) begin: g_dut_32
	int64_div_cla2 
	u_dut (
		.op_format_i(2'b01),
		.op_sign_i(opcode),
		.dividend_i({32'b0, dividend_32}),
		.divisor_i({32'b0, divisor_32}),
		.quotient_o({unused_bits[31:0], dut_quotient_32}),
		.remainder_o({unused_bits[63:32], dut_remainder_32}),
		.divisor_is_zero_o(dut_divisor_is_zero_32)
	);
end
else begin: g_dut_16
	int64_div_cla2 
	u_dut (
		.op_format_i(2'b00),
		.op_sign_i(opcode),
		.dividend_i({48'b0, dividend_16}),
		.divisor_i({48'b0, divisor_16}),
		.quotient_o({unused_bits[47:0], dut_quotient_16}),
		.remainder_o({unused_bits[95:48], dut_remainder_16}),
		.divisor_is_zero_o(dut_divisor_is_zero_16)
	);
end
endgenerate



// ================================================================================================================================================
// Simulate valid-ready signals of dut

`ifndef DUT_HAS_VALID_READY
initial begin
	do begin
		dut_start_ready = 0;
		`RESP_WAIT_COMB_SIG(clk, dut_start_valid)
		dut_start_ready_after_start_valid_delay = $urandom() % `VALID_READY_DELAY;
		`RESP_WAIT_CYC(clk, dut_start_ready_after_start_valid_delay)
		dut_start_ready = 1;
		`RESP_WAIT_SIG(clk, dut_start_ready)
	end while(1);
	// end while(acq_count < TEST_NUM);
end

initial begin
	do begin
		dut_finish_valid = 0;
		`WAIT_COMB_SIG(clk, (dut_start_valid & dut_start_ready))
		dut_finish_valid_after_start_handshake_delay = $urandom() % `VALID_READY_DELAY;
		`APPL_WAIT_CYC(clk, dut_finish_valid_after_start_handshake_delay)
		dut_finish_valid = 1;
		`APPL_WAIT_SIG(clk, (dut_finish_valid & dut_finish_ready))		
	end while(1);
end
`else

`endif

// ================================================================================================================================================


// ================================================================================================================================================
// clk generator
initial begin
	clk = 0;
	while(1) begin
		clk = 0;
		#(`CLK_LO);
		clk = 1;
		#(`CLK_HI);
	end
end
// reset and start signal generator
initial begin
	rst_n = 0;
	simulation_start = 0;
	`APPL_WAIT_CYC(clk, 5)
	rst_n = 1;
	`APPL_WAIT_CYC(clk, 5)
	$display("TB: simulation starts!");
	simulation_start <= 1;
end
// ================================================================================================================================================


endmodule
