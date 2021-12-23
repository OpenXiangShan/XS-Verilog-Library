#include "stdio.h"
#include "stdlib.h"
#include "stdint.h"

#include "svdpi.h"
#include "softfloat.h"
#include "genCases.h"

#define MAX_ERR_COUNT 10

uint64_t recorded_opa[MAX_ERR_COUNT];
uint64_t recorded_opb[MAX_ERR_COUNT];
uint32_t recorded_fp_format[MAX_ERR_COUNT];
uint32_t recorded_rm[MAX_ERR_COUNT];
uint64_t recorded_dut_res[MAX_ERR_COUNT];
uint32_t recorded_dut_fflags[MAX_ERR_COUNT];
uint64_t recorded_ref_res[MAX_ERR_COUNT];
uint32_t recorded_ref_fflags[MAX_ERR_COUNT];

extern float16_t genCases_f16_a, genCases_f16_b, genCases_f16_c;
extern float32_t genCases_f32_a, genCases_f32_b, genCases_f32_c;
extern float64_t genCases_f64_a, genCases_f64_b, genCases_f64_c;

const uint16_t fp16_defaultNaN = 0x7E00;
const uint32_t fp32_defaultNaN = 0x7FC00000;
const uint64_t fp64_defaultNaN = 0x7FF8000000000000;

const uint16_t fp16_min_pos_normal = 0x0400;
const uint16_t fp16_min_neg_normal = 0x8400;
const uint32_t fp32_min_pos_normal = 0x00800000;
const uint32_t fp32_min_neg_normal = 0x80800000;
const uint64_t fp64_min_pos_normal = 0x0010000000000000;
const uint64_t fp64_min_neg_normal = 0x8010000000000000;

// ================================================================================================================================================
// Function Declarations
// ================================================================================================================================================
void cmodel_check_result(
	const svBitVecVal *error_count,
	const svBitVecVal *opa_hi,
	const svBitVecVal *opa_lo,
	const svBitVecVal *opb_hi,
	const svBitVecVal *opb_lo,
	const svBitVecVal *fp_format,
	const svBitVecVal *rm,
	const svBitVecVal *dut_res_hi,
	const svBitVecVal *dut_res_lo,
	const svBitVecVal *dut_fflags,
	svBitVecVal *compare_ok
);
void gencases_init(const svBitVecVal *seed, const svBitVecVal *level);
void gencases_for_f16(svBitVecVal *opa, svBitVecVal *opb);
void gencases_for_f32(svBitVecVal *opa, svBitVecVal *opb);
void gencases_for_f64(svBitVecVal *opa_hi, svBitVecVal *opa_lo, svBitVecVal *opb_hi, svBitVecVal *opb_lo);
void print_error(const svBitVecVal *error_count);
uint32_t fp16_is_nan(const uint16_t x);
uint32_t fp32_is_nan(const uint32_t x);
uint32_t fp64_is_nan(const uint64_t x);


// ================================================================================================================================================
// Function Implementations
// ================================================================================================================================================
void cmodel_check_result(
	const svBitVecVal *error_count,
	const svBitVecVal *opa_hi,
	const svBitVecVal *opa_lo,
	const svBitVecVal *opb_hi,
	const svBitVecVal *opb_lo,
	const svBitVecVal *fp_format,
	const svBitVecVal *rm,
	const svBitVecVal *dut_res_hi,
	const svBitVecVal *dut_res_lo,
	const svBitVecVal *dut_fflags,
	svBitVecVal *compare_ok
) {
	float16_t f16_opa;
	float16_t f16_opb;
	float16_t f16_div_res;
	float32_t f32_opa;
	float32_t f32_opb;
	float32_t f32_div_res;
	float64_t f64_opa;
	float64_t f64_opb;
	float64_t f64_div_res;

	uint32_t check_underflow = 1;
	uint32_t data_ok;
	uint32_t fflags_ok;

	f16_opa.v = (uint16_t)(*opa_lo);
	f16_opb.v = (uint16_t)(*opb_lo);
	f32_opa.v = *opa_lo;
	f32_opb.v = *opb_lo;
	f64_opa.v = ((uint64_t)(*opa_hi) << 32) | *opa_lo;
	f64_opb.v = ((uint64_t)(*opb_hi) << 32) | *opb_lo;

	// The same as RTL....
	softfloat_detectTininess = softfloat_tininess_afterRounding;
	// clean fflags before computation?
	softfloat_exceptionFlags = 0;
	softfloat_roundingMode = *rm;
	uint32_t dut_fflags_invalid_operation 	= *dut_fflags & 0x10;
	uint32_t dut_fflags_div_by_zero 		= *dut_fflags & 0x8;
	uint32_t dut_fflags_overflow 			= *dut_fflags & 0x4;
	uint32_t dut_fflags_underflow 			= *dut_fflags & 0x2;
	uint32_t dut_fflags_inexact 			= *dut_fflags & 0x1;

	if(*fp_format == 0) {
		f16_div_res = f16_div(f16_opa, f16_opb);
		// In rv-spec, we only produce defaultNaN
		if(fp16_is_nan(f16_div_res.v))
			data_ok = (*dut_res_lo & 0xFFFF) == fp16_defaultNaN;
		else
			data_ok = (*dut_res_lo & 0xFFFF) == f16_div_res.v;

	} else if(*fp_format == 1) {
		f32_div_res = f32_div(f32_opa, f32_opb);

		if(fp32_is_nan(f32_div_res.v))
			data_ok = *dut_res_lo == fp32_defaultNaN;
		else
			data_ok = *dut_res_lo == f32_div_res.v;

	} else {
		f64_div_res = f64_div(f64_opa, f64_opb);

		if(fp64_is_nan(f64_div_res.v))
			data_ok = (((uint64_t)(*dut_res_hi) << 32) | *dut_res_lo) == fp64_defaultNaN;
		else
			data_ok = (((uint64_t)(*dut_res_hi) << 32) | *dut_res_lo) == f64_div_res.v;

	}

	// Underflow flag seems have some problems...
	if(*fp_format == 0) {
		if((f16_div_res.v == fp16_min_pos_normal) | (f16_div_res.v == fp16_min_neg_normal))
			check_underflow = 0;
	} else if(*fp_format == 1) {
		if((f32_div_res.v == fp32_min_pos_normal) | (f32_div_res.v == fp32_min_neg_normal))
			check_underflow = 0;
	} else {
		if((f64_div_res.v == fp64_min_pos_normal) | (f64_div_res.v == fp64_min_neg_normal))
			check_underflow = 0;
	}

	if(check_underflow) {
		fflags_ok = 
		  (dut_fflags_invalid_operation == (softfloat_exceptionFlags & 0x10))
		& (dut_fflags_div_by_zero 		== (softfloat_exceptionFlags & 0x8))
		& (dut_fflags_overflow 			== (softfloat_exceptionFlags & 0x4))
		& (dut_fflags_underflow 		== (softfloat_exceptionFlags & 0x2))
		& (dut_fflags_inexact 			== (softfloat_exceptionFlags & 0x1));
	} else {
		fflags_ok = 
		  (dut_fflags_invalid_operation == (softfloat_exceptionFlags & 0x10))
		& (dut_fflags_div_by_zero 		== (softfloat_exceptionFlags & 0x8))
		& (dut_fflags_overflow 			== (softfloat_exceptionFlags & 0x4))
		& (dut_fflags_inexact 			== (softfloat_exceptionFlags & 0x1));
	}

	*compare_ok = data_ok & fflags_ok;
	if(*compare_ok == 0) {
		recorded_opa[*error_count] = (*fp_format == 0) ? f16_opa.v : (*fp_format == 1) ? f32_opa.v : f64_opa.v;
		recorded_opb[*error_count] = (*fp_format == 0) ? f16_opb.v : (*fp_format == 1) ? f32_opb.v : f64_opb.v;
		recorded_fp_format[*error_count] = *fp_format;
		recorded_rm[*error_count] = *rm;
		recorded_dut_res[*error_count] = (*fp_format == 0) ? (*dut_res_lo & 0xFFFF) : (*fp_format == 1) ? *dut_res_lo : (((uint64_t)(*dut_res_hi) << 32) | *dut_res_lo);
		recorded_dut_fflags[*error_count] = *dut_fflags;
		recorded_ref_res[*error_count] = (*fp_format == 0) ? f16_div_res.v : (*fp_format == 1) ? f32_div_res.v : f64_div_res.v;
		recorded_ref_fflags[*error_count] = softfloat_exceptionFlags;
	}
}

void gencases_init(const svBitVecVal *seed, const svBitVecVal *level) {
	srand(*seed);
	genCases_setLevel(*level);
	genCases_f16_ab_init();
	genCases_f32_ab_init();
	genCases_f64_ab_init();
}

void gencases_for_f16(svBitVecVal *opa, svBitVecVal *opb) {
	genCases_f16_ab_next();
	*opa = genCases_f16_a.v;
	*opb = genCases_f16_b.v;
	// printf("generated_opa = %04X\n", genCases_f16_a.v);
	// printf("generated_opb = %04X\n", genCases_f16_b.v);
}
void gencases_for_f32(svBitVecVal *opa, svBitVecVal *opb) {
	genCases_f32_ab_next();
	*opa = genCases_f32_a.v;
	*opb = genCases_f32_b.v;
	// printf("generated_opa = %08X\n", genCases_f32_a.v);
	// printf("generated_opb = %08X\n", genCases_f32_b.v);
}
void gencases_for_f64(svBitVecVal *opa_hi, svBitVecVal *opa_lo, svBitVecVal *opb_hi, svBitVecVal *opb_lo) {
	genCases_f64_ab_next();
	*opa_hi = genCases_f64_a.v >> 32;
	*opa_lo = genCases_f64_a.v & 0xFFFFFFFF;
	*opb_hi = genCases_f64_b.v >> 32;
	*opb_lo = genCases_f64_b.v & 0xFFFFFFFF;
	// printf("generated_opa = %16lX\n", genCases_f64_a.v);
	// printf("generated_opb = %16lX\n", genCases_f64_b.v);
}

void print_error(const svBitVecVal *error_count) {
	FILE *fptr;
	fptr = fopen("result.log", "w+");
	for(uint32_t i = 0; i < *error_count; i++) {
		fprintf(fptr, "[%d]:\n", i);
		fprintf(fptr, "recorded_opa 		= %16X\n", recorded_opa[i]);
		fprintf(fptr, "recorded_opb 		= %16X\n", recorded_opb[i]);
		fprintf(fptr, "recorded_fp_format 	= %16X\n", recorded_fp_format[i]);
		fprintf(fptr, "recorded_rm 			= %16X\n", recorded_rm[i]);
		fprintf(fptr, "recorded_dut_res 	= %16X\n", recorded_dut_res[i]);
		fprintf(fptr, "recorded_dut_fflags 	= %16X\n", recorded_dut_fflags[i]);
		fprintf(fptr, "recorded_ref_res 	= %16X\n", recorded_ref_res[i]);
		fprintf(fptr, "recorded_ref_fflags 	= %16X\n", recorded_ref_fflags[i]);
	}
	fclose(fptr);
}

uint32_t fp16_is_nan(const uint16_t x) {
	return ((((x >> 10) == 31) | ((x >> 10) == 63)) & ((x & ((1 << 10) - 1)) != 0));
}
uint32_t fp32_is_nan(const uint32_t x) {
	return ((((x >> 23) == 255) | ((x >> 23) == 511)) & ((x & ((1 << 23) - 1)) != 0));
}
uint32_t fp64_is_nan(const uint64_t x) {
	return ((((x >> 52) == 2047) | ((x >> 52) == 4095)) & ((x & (((uint64_t)1 << 52) - 1)) != 0));
}