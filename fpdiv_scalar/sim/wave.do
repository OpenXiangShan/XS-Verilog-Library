add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/clk
add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/rst_n

add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned sim:/tb_top/acq_count
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/stim_end
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/u_dut/fsm_q
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/u_dut/final_iter
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/compare_ok
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fp_format
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fpdiv_rm
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fpdiv_opa
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/fpdiv_opb
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_fpdiv_res
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_fpdiv_fflags

add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_rem_sum_iter_init
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_rem_carry_iter_init
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_rem_sum_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_rem_carry_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/fp_format_q

add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_divisor_iter_init
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/frac_divisor_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/div_csa_val[0]
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/div_csa_val[1]
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/u_dut/div_csa_val[2]

add wave -position insertpoint -expand -group QUO_REG sim:/tb_top/u_dut/quo_iter_init
add wave -position insertpoint -expand -group QUO_REG sim:/tb_top/u_dut/quo_iter_q
add wave -position insertpoint -expand -group QUO_REG sim:/tb_top/u_dut/quo_m1_iter_q

add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/early_finish
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/out_sign_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/res_is_nan_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/res_is_inf_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/res_is_exact_zero_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_is_power_of_2_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/op_invalid_div_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/divided_by_zero_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_l_shift_num_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_l_shift_num_q
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_exp_plus_biased
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_exp_biased
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_exp_biased
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/out_exp_diff_q


add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_frac_pre_shifted
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_frac_pre_shifted
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_l_shift_num_pre
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_l_shift_num_pre
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_frac_is_zero
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_frac_is_zero
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opa_frac_l_shifted
add wave -position insertpoint -expand -group PRE sim:/tb_top/u_dut/opb_frac_l_shifted



add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_frac_rem
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/nr_frac_rem_plus_d
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_msb
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_pre_shift
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_m1_pre_shift
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/r_shift_num_pre
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/r_shift_num_pre_minus_limit
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/r_shift_num
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_r_shifted
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/quo_m1_r_shifted
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/sticky_without_rem
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/correct_quo_r_shifted
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/rem_is_not_zero
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/sticky_bit
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/frac_before_round
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/guard_bit
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/round_bit
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/exp_before_round
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/inexact
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/round_up
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/frac_after_round
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/carry_after_round
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/exp_after_round
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/overflow
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/overflow_to_inf


add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/fp16_out_exp
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/fp32_out_exp
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/fp64_out_exp
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/fp16_out_frac
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/fp32_out_frac
add wave -position insertpoint -expand -group POST sim:/tb_top/u_dut/fp64_out_frac


add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/frac_rem_sum_out_msbs_zero[0]
add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/frac_rem_carry_out_msbs_zero[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/quo_dig_zero[0]
add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/frac_rem_sum_out_msbs_plus[0]
add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/frac_rem_carry_out_msbs_plus[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/quo_dig_plus[0]
add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/frac_rem_sum_out_msbs_minus[0]
add wave -position insertpoint -expand -group stage_0 -radix binary sim:/tb_top/u_dut/frac_rem_carry_out_msbs_minus[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/quo_dig_minus[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/quo_dig[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/nxt_quo_iter[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/nxt_quo_m1_iter[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/frac_rem_sum_in[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/frac_rem_carry_in[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/frac_rem_sum_out[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/frac_rem_carry_out[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/frac_rem_sum_out_lsbs[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/frac_rem_carry_out_lsbs[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/frac_rem_sum_out_msbs[0]
add wave -position insertpoint -expand -group stage_0 sim:/tb_top/u_dut/frac_rem_carry_out_msbs[0]

add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/frac_rem_sum_out_msbs_zero[1]
add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/frac_rem_carry_out_msbs_zero[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/quo_dig_zero[1]
add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/frac_rem_sum_out_msbs_plus[1]
add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/frac_rem_carry_out_msbs_plus[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/quo_dig_plus[1]
add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/frac_rem_sum_out_msbs_minus[1]
add wave -position insertpoint -expand -group stage_1 -radix binary sim:/tb_top/u_dut/frac_rem_carry_out_msbs_minus[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/quo_dig_minus[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/quo_dig[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/nxt_quo_iter[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/nxt_quo_m1_iter[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/frac_rem_sum_in[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/frac_rem_carry_in[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/frac_rem_sum_out[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/frac_rem_carry_out[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/frac_rem_sum_out_lsbs[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/frac_rem_carry_out_lsbs[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/frac_rem_sum_out_msbs[1]
add wave -position insertpoint -expand -group stage_1 sim:/tb_top/u_dut/frac_rem_carry_out_msbs[1]

add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/frac_rem_sum_out_msbs_zero[2]
add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/frac_rem_carry_out_msbs_zero[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/quo_dig_zero[2]
add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/frac_rem_sum_out_msbs_plus[2]
add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/frac_rem_carry_out_msbs_plus[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/quo_dig_plus[2]
add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/frac_rem_sum_out_msbs_minus[2]
add wave -position insertpoint -expand -group stage_2 -radix binary sim:/tb_top/u_dut/frac_rem_carry_out_msbs_minus[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/quo_dig_minus[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/quo_dig[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/nxt_quo_iter[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/nxt_quo_m1_iter[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/frac_rem_sum_in[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/frac_rem_carry_in[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/frac_rem_sum_out[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/frac_rem_carry_out[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/frac_rem_sum_out_lsbs[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/frac_rem_carry_out_lsbs[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/frac_rem_sum_out_msbs[2]
add wave -position insertpoint -expand -group stage_2 sim:/tb_top/u_dut/frac_rem_carry_out_msbs[2]









