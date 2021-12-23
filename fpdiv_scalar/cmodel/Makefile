#=============================================================================
#
# This Makefile is part of the SoftFloat IEEE Floating-Point Arithmetic
# Package, Release 3e, by John R. Hauser.
#
# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 The Regents of the
# University of California.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice,
#     this list of conditions, and the following disclaimer.
#
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions, and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  3. Neither the name of the University nor the names of its contributors
#     may be used to endorse or promote products derived from this software
#     without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS "AS IS", AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ARE
# DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#=============================================================================
# This Makefile is modified by HYF to be used in my simulation environment (Windows 10 and Questasim 10.7c Compiler 2018.08 Aug 18 2018).
#=============================================================================

TESTFLOAT_SOURCE_DIR ?= ./src/testfloat/source
SOFTFLOAT_SOURCE_DIR ?= ./src/softfloat
SPECIALIZE_TYPE ?= 8086-SSE
SOFTFLOAT_OPTS ?= \
	-DSOFTFLOAT_ROUND_ODD -DINLINE_LEVEL=5 -DSOFTFLOAT_FAST_DIV32TO16 \
	-DSOFTFLOAT_FAST_DIV64TO32

TESTFLOAT_OPTS ?= \
  -DFLOAT16 -DFLOAT64 -DEXTFLOAT80 -DFLOAT128 -DFLOAT_ROUND_ODD \
  -DLONG_DOUBLE_IS_EXTFLOAT80

SOFTFLOAT_C_INCLUDES = -I$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE) -I$(SOFTFLOAT_SOURCE_DIR)/include
TESTFLOAT_C_INCLUDES = -I$(TESTFLOAT_SOURCE_DIR)


SOFTFLOAT_SRCS = $(SOFTFLOAT_SRCS_PRIMITIVES) $(SOFTFLOAT_SRCS_SPECIALIZE) $(SOFTFLOAT_SRCS_OTHERS)

SOFTFLOAT_SRCS_PRIMITIVES = \
	$(SOFTFLOAT_SOURCE_DIR)/s_eq128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_le128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_lt128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_shortShiftLeft128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_shortShiftRight128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_shortShiftRightJam64.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_shortShiftRightJam64Extra.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_shortShiftRightJam128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_shortShiftRightJam128Extra.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_shiftRightJam32.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_shiftRightJam64.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_shiftRightJam64Extra.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_shiftRightJam128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_shiftRightJam128Extra.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_shiftRightJam256M.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_countLeadingZeros8.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_countLeadingZeros16.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_countLeadingZeros32.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_countLeadingZeros64.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_add128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_add256M.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_sub128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_sub256M.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_mul64ByShifted32To128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_mul64To128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_mul128By32.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_mul128To256M.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_approxRecip_1Ks.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_approxRecip32_1.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_approxRecipSqrt_1Ks.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_approxRecipSqrt32_1.c

SOFTFLOAT_SRCS_SPECIALIZE = \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/softfloat_raiseFlags.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_f16UIToCommonNaN.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_commonNaNToF16UI.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_propagateNaNF16UI.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_f32UIToCommonNaN.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_commonNaNToF32UI.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_propagateNaNF32UI.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_f64UIToCommonNaN.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_commonNaNToF64UI.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_propagateNaNF64UI.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/extF80M_isSignalingNaN.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_extF80UIToCommonNaN.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_commonNaNToExtF80UI.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_propagateNaNExtF80UI.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/f128M_isSignalingNaN.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_f128UIToCommonNaN.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_commonNaNToF128UI.c \
	$(SOFTFLOAT_SOURCE_DIR)/$(SPECIALIZE_TYPE)/s_propagateNaNF128UI.c

SOFTFLOAT_SRCS_OTHERS = \
	$(SOFTFLOAT_SOURCE_DIR)/s_roundToUI32.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_roundToUI64.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_roundToI32.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_roundToI64.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_normSubnormalF16Sig.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_roundPackToF16.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_normRoundPackToF16.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_addMagsF16.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_subMagsF16.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_mulAddF16.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_normSubnormalF32Sig.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_roundPackToF32.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_normRoundPackToF32.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_addMagsF32.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_subMagsF32.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_mulAddF32.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_normSubnormalF64Sig.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_roundPackToF64.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_normRoundPackToF64.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_addMagsF64.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_subMagsF64.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_mulAddF64.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_normSubnormalExtF80Sig.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_roundPackToExtF80.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_normRoundPackToExtF80.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_addMagsExtF80.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_subMagsExtF80.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_normSubnormalF128Sig.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_roundPackToF128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_normRoundPackToF128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_addMagsF128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_subMagsF128.c \
	$(SOFTFLOAT_SOURCE_DIR)/s_mulAddF128.c \
	$(SOFTFLOAT_SOURCE_DIR)/softfloat_state.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui32_to_f16.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui32_to_f32.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui32_to_f64.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui32_to_extF80.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui32_to_extF80M.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui32_to_f128.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui32_to_f128M.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui64_to_f16.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui64_to_f32.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui64_to_f64.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui64_to_extF80.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui64_to_extF80M.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui64_to_f128.c \
	$(SOFTFLOAT_SOURCE_DIR)/ui64_to_f128M.c \
	$(SOFTFLOAT_SOURCE_DIR)/i32_to_f16.c \
	$(SOFTFLOAT_SOURCE_DIR)/i32_to_f32.c \
	$(SOFTFLOAT_SOURCE_DIR)/i32_to_f64.c \
	$(SOFTFLOAT_SOURCE_DIR)/i32_to_extF80.c \
	$(SOFTFLOAT_SOURCE_DIR)/i32_to_extF80M.c \
	$(SOFTFLOAT_SOURCE_DIR)/i32_to_f128.c \
	$(SOFTFLOAT_SOURCE_DIR)/i32_to_f128M.c \
	$(SOFTFLOAT_SOURCE_DIR)/i64_to_f16.c \
	$(SOFTFLOAT_SOURCE_DIR)/i64_to_f32.c \
	$(SOFTFLOAT_SOURCE_DIR)/i64_to_f64.c \
	$(SOFTFLOAT_SOURCE_DIR)/i64_to_extF80.c \
	$(SOFTFLOAT_SOURCE_DIR)/i64_to_extF80M.c \
	$(SOFTFLOAT_SOURCE_DIR)/i64_to_f128.c \
	$(SOFTFLOAT_SOURCE_DIR)/i64_to_f128M.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_ui32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_ui64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_i32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_i64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_ui32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_ui64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_i32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_i64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_f32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_f64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_extF80.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_extF80M.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_f128.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_to_f128M.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_roundToInt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_add.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_sub.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_mul.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_mulAdd.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_div.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_rem.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_sqrt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_eq.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_le.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_lt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_eq_signaling.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_le_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_lt_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/f16_isSignalingNaN.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_ui32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_ui64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_i32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_i64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_ui32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_ui64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_i32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_i64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_f16.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_f64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_extF80.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_extF80M.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_f128.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_to_f128M.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_roundToInt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_add.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_sub.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_mul.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_mulAdd.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_div.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_rem.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_sqrt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_eq.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_le.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_lt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_eq_signaling.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_le_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_lt_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/f32_isSignalingNaN.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_ui32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_ui64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_i32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_i64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_ui32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_ui64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_i32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_i64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_f16.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_f32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_extF80.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_extF80M.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_f128.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_to_f128M.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_roundToInt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_add.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_sub.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_mul.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_mulAdd.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_div.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_rem.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_sqrt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_eq.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_le.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_lt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_eq_signaling.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_le_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_lt_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/f64_isSignalingNaN.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_to_ui32.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_to_ui64.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_to_i32.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_to_i64.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_to_ui32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_to_ui64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_to_i32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_to_i64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_to_f16.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_to_f32.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_to_f64.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_to_f128.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_roundToInt.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_add.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_sub.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_mul.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_div.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_rem.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_sqrt.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_eq.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_le.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_lt.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_eq_signaling.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_le_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_lt_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80_isSignalingNaN.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_to_ui32.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_to_ui64.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_to_i32.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_to_i64.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_to_ui32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_to_ui64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_to_i32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_to_i64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_to_f16.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_to_f32.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_to_f64.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_to_f128M.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_roundToInt.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_add.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_sub.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_mul.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_div.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_rem.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_sqrt.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_eq.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_le.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_lt.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_eq_signaling.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_le_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/extF80M_lt_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_to_ui32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_to_ui64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_to_i32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_to_i64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_to_ui32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_to_ui64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_to_i32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_to_i64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_to_f16.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_to_f32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_to_extF80.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_to_f64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_roundToInt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_add.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_sub.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_mul.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_mulAdd.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_div.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_rem.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_sqrt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_eq.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_le.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_lt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_eq_signaling.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_le_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_lt_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128_isSignalingNaN.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_to_ui32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_to_ui64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_to_i32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_to_i64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_to_ui32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_to_ui64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_to_i32_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_to_i64_r_minMag.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_to_f16.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_to_f32.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_to_extF80M.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_to_f64.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_roundToInt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_add.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_sub.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_mul.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_mulAdd.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_div.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_rem.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_sqrt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_eq.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_le.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_lt.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_eq_signaling.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_le_quiet.c \
	$(SOFTFLOAT_SOURCE_DIR)/f128M_lt_quiet.c

TESTFLOAT_SRCS_GENCASES = \
  $(TESTFLOAT_SOURCE_DIR)/genCases_ui32.c \
  $(TESTFLOAT_SOURCE_DIR)/genCases_ui64.c \
  $(TESTFLOAT_SOURCE_DIR)/genCases_i32.c \
  $(TESTFLOAT_SOURCE_DIR)/genCases_i64.c \
  $(TESTFLOAT_SOURCE_DIR)/genCases_f16.c \
  $(TESTFLOAT_SOURCE_DIR)/genCases_f32.c \
  $(TESTFLOAT_SOURCE_DIR)/genCases_f64.c \
  $(TESTFLOAT_SOURCE_DIR)/genCases_extF80.c \
  $(TESTFLOAT_SOURCE_DIR)/genCases_f128.c \
  $(TESTFLOAT_SOURCE_DIR)/genCases_common.c

TESTFLOAT_SRCS_COMMON = \
  $(TESTFLOAT_SOURCE_DIR)/uint128_inline.c \
  $(TESTFLOAT_SOURCE_DIR)/uint128.c \
  $(TESTFLOAT_SOURCE_DIR)/fail.c \
  $(TESTFLOAT_SOURCE_DIR)/random.c
  

TESTFLOAT_SRCS = $(TESTFLOAT_SRCS_GENCASES) $(TESTFLOAT_SRCS_COMMON)

# compile softfloat as DLL and copy it to the "sim" dir, so vsim could load it correctly
softfloat_lib: 
	gcc $(SOFTFLOAT_SRCS) -o ./lib/softfloat.dll \
	-DSOFTFLOAT_FAST_INT64 $(SOFTFLOAT_OPTS) $(SOFTFLOAT_C_INCLUDES) -fPIC -shared -O2 -mfma -m64
	cp ./lib/softfloat.dll ../sim/softfloat.dll

# -Werror-implicit-function-declaration

testfloat_gencases_lib:
	gcc $(TESTFLOAT_SRCS) -o ./lib/testfloat_gencases.dll \
	-shared -fPIC -O2 -mfma -m64 -std=c99 \
	$(TESTFLOAT_OPTS) $(TESTFLOAT_C_INCLUDES)
	cp ./lib/testfloat_gencases.dll ../sim/testfloat_gencases.dll

cmodel: 
	gcc ./src/cmodel.c -o ./lib/cmodel.dll \
	-shared -fPIC -O2 -mfma -m64 \
	-I./include \
	-L./lib -lsoftfloat -ltestfloat_gencases

all: softfloat_lib testfloat_gencases_lib cmodel

clean_cmodel:
	rm -f ./lib/cmodel.dll
clean_softfloat:
	rm -f ./lib/softfloat.dll
	rm -f ../sim/softfloat.dll
clean_testfloat:
	rm -f ./lib/testfloat_gencases.dll
	rm -f ../sim/testfloat_gencases.dll
clean: clean_softfloat clean_testfloat clean_cmodel


