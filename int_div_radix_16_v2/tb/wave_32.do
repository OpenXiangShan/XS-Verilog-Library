add wave -position insertpoint -expand -group CLK_RST sim:/tb_int_div_radix_16_v2/clk
add wave -position insertpoint -expand -group CLK_RST sim:/tb_int_div_radix_16_v2/rst_n

add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned sim:/tb_int_div_radix_16_v2/acq_count
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_int_div_radix_16_v2/stim_end
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_int_div_radix_16_v2/dut_start_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_int_div_radix_16_v2/dut_start_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_int_div_radix_16_v2/dut_finish_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_int_div_radix_16_v2/dut_finish_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_int_div_radix_16_v2/compare_ok
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_int_div_radix_16_v2/quotient_32
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_int_div_radix_16_v2/remainder_32
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_int_div_radix_16_v2/g_dut_32/dut/fsm_reg
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_int_div_radix_16_v2/g_dut_32/dut/nxt_fsm_reg
add wave -position insertpoint -expand -group main_data_path -radix unsigned sim:/tb_int_div_radix_16_v2/g_dut_32/dut/nxt_iters_required
add wave -position insertpoint -expand -group main_data_path -radix unsigned sim:/tb_int_div_radix_16_v2/g_dut_32/dut/iters_required
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/final_iter

add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/signed_op_i
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/dividend_i
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/divisor_i
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_cpa
add wave -position insertpoint -expand -group main_data_path -radix unsigned sim:/tb_int_div_radix_16_v2/g_dut_32/dut/lzc_remainder
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/divisor
add wave -position insertpoint -expand -group main_data_path -radix unsigned sim:/tb_int_div_radix_16_v2/g_dut_32/dut/lzc_divisor
add wave -position insertpoint -expand -group main_data_path -radix unsigned sim:/tb_int_div_radix_16_v2/g_dut_32/dut/lzc_diff
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/divisor_gt_remainder
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/divisor_eq_zero
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig[0]
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig[1]
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig[2]
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig[3]
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig[4]
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quotient
add wave -position insertpoint -expand -group main_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quotient_m1

add wave -position insertpoint -expand -group quo_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/n_quotient[0]
add wave -position insertpoint -expand -group quo_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/n_quotient_m1[0]
add wave -position insertpoint -expand -group quo_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/n_quotient[1]
add wave -position insertpoint -expand -group quo_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/n_quotient_m1[1]
add wave -position insertpoint -expand -group quo_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/n_quotient[2]
add wave -position insertpoint -expand -group quo_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/n_quotient_m1[2]
add wave -position insertpoint -expand -group quo_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/n_quotient[3]
add wave -position insertpoint -expand -group quo_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/n_quotient_m1[3]


add wave -position insertpoint -group srt_control_path_0 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_cp[0]
add wave -position insertpoint -group srt_control_path_0 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_cp[0]
add wave -position insertpoint -group srt_control_path_0 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_zero[0]
add wave -position insertpoint -group srt_control_path_0 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_zero[0]
add wave -position insertpoint -group srt_control_path_0 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_minus_d[0]
add wave -position insertpoint -group srt_control_path_0 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_minus_d[0]
add wave -position insertpoint -group srt_control_path_0 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig_zero[0]
add wave -position insertpoint -group srt_control_path_0 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig_plus_d[0]
add wave -position insertpoint -group srt_control_path_0 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig_minus_d[0]

add wave -position insertpoint -group srt_control_path_1 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_cp[1]
add wave -position insertpoint -group srt_control_path_1 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_cp[1]
add wave -position insertpoint -group srt_control_path_1 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_zero[1]
add wave -position insertpoint -group srt_control_path_1 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_zero[1]
add wave -position insertpoint -group srt_control_path_1 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_minus_d[1]
add wave -position insertpoint -group srt_control_path_1 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_minus_d[1]
add wave -position insertpoint -group srt_control_path_1 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig_zero[1]
add wave -position insertpoint -group srt_control_path_1 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig_plus_d[1]
add wave -position insertpoint -group srt_control_path_1 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig_minus_d[1]

add wave -position insertpoint -group srt_control_path_2 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_cp[2]
add wave -position insertpoint -group srt_control_path_2 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_cp[2]
add wave -position insertpoint -group srt_control_path_2 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_zero[2]
add wave -position insertpoint -group srt_control_path_2 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_zero[2]
add wave -position insertpoint -group srt_control_path_2 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_minus_d[2]
add wave -position insertpoint -group srt_control_path_2 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_minus_d[2]
add wave -position insertpoint -group srt_control_path_2 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig_zero[2]
add wave -position insertpoint -group srt_control_path_2 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig_plus_d[2]
add wave -position insertpoint -group srt_control_path_2 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig_minus_d[2]

add wave -position insertpoint -group srt_control_path_3 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_cp[3]
add wave -position insertpoint -group srt_control_path_3 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_cp[3]
add wave -position insertpoint -group srt_control_path_3 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_zero[3]
add wave -position insertpoint -group srt_control_path_3 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_zero[3]
add wave -position insertpoint -group srt_control_path_3 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_minus_d[3]
add wave -position insertpoint -group srt_control_path_3 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_minus_d[3]
add wave -position insertpoint -group srt_control_path_3 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig_zero[3]
add wave -position insertpoint -group srt_control_path_3 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig_plus_d[3]
add wave -position insertpoint -group srt_control_path_3 sim:/tb_int_div_radix_16_v2/g_dut_32/dut/quot_dig_minus_d[3]

add wave -position insertpoint -expand -group srt_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_dp[0]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_dp[0]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_dp[1]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_dp[1]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_dp[2]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_dp[2]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_dp[3]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_dp[3]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_sum_dp[4]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_int_div_radix_16_v2/g_dut_32/dut/rem_carry_dp[4]



