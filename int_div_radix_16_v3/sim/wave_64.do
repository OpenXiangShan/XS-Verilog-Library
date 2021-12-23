add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/clk
add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/rst_n

add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned sim:/tb_top/acq_count
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/stim_end
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/compare_ok
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/quotient_64
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/remainder_64
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/g_dut_64/dut/fsm_d
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/g_dut_64/dut/fsm_q

add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/signed_op_i
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/dividend_i
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/divisor_i
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/dividend_sign
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/divisor_sign
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/dividend_abs
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/dividend_abs_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/divisor_abs
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/divisor_abs_q

add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/normalized_dividend
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/normalized_divisor

add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/quo_sign_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/rem_sign_q

add wave -position insertpoint -expand -group main_signals -radix unsigned sim:/tb_top/g_dut_64/dut/dividend_lzc
add wave -position insertpoint -expand -group main_signals -radix unsigned sim:/tb_top/g_dut_64/dut/dividend_lzc_q
add wave -position insertpoint -expand -group main_signals -radix unsigned sim:/tb_top/g_dut_64/dut/divisor_lzc
add wave -position insertpoint -expand -group main_signals -radix unsigned sim:/tb_top/g_dut_64/dut/divisor_lzc_q
add wave -position insertpoint -expand -group main_signals -radix unsigned sim:/tb_top/g_dut_64/dut/lzc_diff
add wave -position insertpoint -expand -group main_signals -radix unsigned sim:/tb_top/g_dut_64/dut/iter_num_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/final_iter
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/dividend_too_small_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/divisor_is_zero
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/rem_sum_init_value
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/rem_sum_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/rem_carry_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/nr_rem
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/nr_rem_plus_d
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_64/dut/need_corr


add wave -position insertpoint -expand -group quo_path -radix binary sim:/tb_top/g_dut_64/dut/prev_prev_quo_q
add wave -position insertpoint -expand -group quo_path -radix binary sim:/tb_top/g_dut_64/dut/prev_quo_zero_q
add wave -position insertpoint -expand -group quo_path -radix binary sim:/tb_top/g_dut_64/dut/prev_quo_plus_d_q
add wave -position insertpoint -expand -group quo_path -radix binary sim:/tb_top/g_dut_64/dut/prev_quo_minus_d_q
add wave -position insertpoint -expand -group quo_path -radix binary sim:/tb_top/g_dut_64/dut/quo_iter_nxt[0]
add wave -position insertpoint -expand -group quo_path -radix binary sim:/tb_top/g_dut_64/dut/quo_m1_iter_nxt[0]
add wave -position insertpoint -expand -group quo_path -radix binary sim:/tb_top/g_dut_64/dut/quo_iter_nxt[1]
add wave -position insertpoint -expand -group quo_path -radix binary sim:/tb_top/g_dut_64/dut/quo_m1_iter_nxt[1]
add wave -position insertpoint -expand -group quo_path -radix binary sim:/tb_top/g_dut_64/dut/quo_iter_nxt[2]
add wave -position insertpoint -expand -group quo_path -radix binary sim:/tb_top/g_dut_64/dut/quo_m1_iter_nxt[2]
add wave -position insertpoint -expand -group quo_path -radix binary sim:/tb_top/g_dut_64/dut/quo_iter_nxt[3]
add wave -position insertpoint -expand -group quo_path -radix binary sim:/tb_top/g_dut_64/dut/quo_m1_iter_nxt[3]
add wave -position insertpoint -expand -group quo_path sim:/tb_top/g_dut_64/dut/quo_iter_q
add wave -position insertpoint -expand -group quo_path sim:/tb_top/g_dut_64/dut/quo_m1_iter_q


add wave -position insertpoint -expand -group srt_ctrl_path_0 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig[0]
add wave -position insertpoint -expand -group srt_ctrl_path_0 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig_zero[0]
add wave -position insertpoint -expand -group srt_ctrl_path_0 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig_plus_d[0]
add wave -position insertpoint -expand -group srt_ctrl_path_0 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig_minus_d[0]
add wave -position insertpoint -expand -group srt_ctrl_path_0 sim:/tb_top/g_dut_64/dut/rem_sum_cp[0]
add wave -position insertpoint -expand -group srt_ctrl_path_0 sim:/tb_top/g_dut_64/dut/rem_carry_cp[0]
add wave -position insertpoint -expand -group srt_ctrl_path_0 sim:/tb_top/g_dut_64/dut/rem_sum_zero[0]
add wave -position insertpoint -expand -group srt_ctrl_path_0 sim:/tb_top/g_dut_64/dut/rem_carry_zero[0]
add wave -position insertpoint -expand -group srt_ctrl_path_0 sim:/tb_top/g_dut_64/dut/rem_sum_minus_d[0]
add wave -position insertpoint -expand -group srt_ctrl_path_0 sim:/tb_top/g_dut_64/dut/rem_carry_minus_d[0]
add wave -position insertpoint -expand -group srt_ctrl_path_0 sim:/tb_top/g_dut_64/dut/rem_sum_plus_d[0]
add wave -position insertpoint -expand -group srt_ctrl_path_0 sim:/tb_top/g_dut_64/dut/rem_carry_plus_d[0]

add wave -position insertpoint -expand -group srt_ctrl_path_1 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig[1]
add wave -position insertpoint -expand -group srt_ctrl_path_1 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig_zero[1]
add wave -position insertpoint -expand -group srt_ctrl_path_1 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig_plus_d[1]
add wave -position insertpoint -expand -group srt_ctrl_path_1 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig_minus_d[1]
add wave -position insertpoint -expand -group srt_ctrl_path_1 sim:/tb_top/g_dut_64/dut/rem_sum_cp[1]
add wave -position insertpoint -expand -group srt_ctrl_path_1 sim:/tb_top/g_dut_64/dut/rem_carry_cp[1]
add wave -position insertpoint -expand -group srt_ctrl_path_1 sim:/tb_top/g_dut_64/dut/rem_sum_zero[1]
add wave -position insertpoint -expand -group srt_ctrl_path_1 sim:/tb_top/g_dut_64/dut/rem_carry_zero[1]
add wave -position insertpoint -expand -group srt_ctrl_path_1 sim:/tb_top/g_dut_64/dut/rem_sum_minus_d[1]
add wave -position insertpoint -expand -group srt_ctrl_path_1 sim:/tb_top/g_dut_64/dut/rem_carry_minus_d[1]
add wave -position insertpoint -expand -group srt_ctrl_path_1 sim:/tb_top/g_dut_64/dut/rem_sum_plus_d[1]
add wave -position insertpoint -expand -group srt_ctrl_path_1 sim:/tb_top/g_dut_64/dut/rem_carry_plus_d[1]

add wave -position insertpoint -expand -group srt_ctrl_path_2 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig[2]
add wave -position insertpoint -expand -group srt_ctrl_path_2 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig_zero[2]
add wave -position insertpoint -expand -group srt_ctrl_path_2 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig_plus_d[2]
add wave -position insertpoint -expand -group srt_ctrl_path_2 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig_minus_d[2]
add wave -position insertpoint -expand -group srt_ctrl_path_2 sim:/tb_top/g_dut_64/dut/rem_sum_cp[2]
add wave -position insertpoint -expand -group srt_ctrl_path_2 sim:/tb_top/g_dut_64/dut/rem_carry_cp[2]
add wave -position insertpoint -expand -group srt_ctrl_path_2 sim:/tb_top/g_dut_64/dut/rem_sum_zero[2]
add wave -position insertpoint -expand -group srt_ctrl_path_2 sim:/tb_top/g_dut_64/dut/rem_carry_zero[2]
add wave -position insertpoint -expand -group srt_ctrl_path_2 sim:/tb_top/g_dut_64/dut/rem_sum_minus_d[2]
add wave -position insertpoint -expand -group srt_ctrl_path_2 sim:/tb_top/g_dut_64/dut/rem_carry_minus_d[2]
add wave -position insertpoint -expand -group srt_ctrl_path_2 sim:/tb_top/g_dut_64/dut/rem_sum_plus_d[2]
add wave -position insertpoint -expand -group srt_ctrl_path_2 sim:/tb_top/g_dut_64/dut/rem_carry_plus_d[2]

add wave -position insertpoint -expand -group srt_ctrl_path_3 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig[3]
add wave -position insertpoint -expand -group srt_ctrl_path_3 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig_zero[3]
add wave -position insertpoint -expand -group srt_ctrl_path_3 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig_plus_d[3]
add wave -position insertpoint -expand -group srt_ctrl_path_3 -radix binary sim:/tb_top/g_dut_64/dut/quo_dig_minus_d[3]
add wave -position insertpoint -expand -group srt_ctrl_path_3 sim:/tb_top/g_dut_64/dut/rem_sum_cp[3]
add wave -position insertpoint -expand -group srt_ctrl_path_3 sim:/tb_top/g_dut_64/dut/rem_carry_cp[3]
add wave -position insertpoint -expand -group srt_ctrl_path_3 sim:/tb_top/g_dut_64/dut/rem_sum_zero[3]
add wave -position insertpoint -expand -group srt_ctrl_path_3 sim:/tb_top/g_dut_64/dut/rem_carry_zero[3]
add wave -position insertpoint -expand -group srt_ctrl_path_3 sim:/tb_top/g_dut_64/dut/rem_sum_minus_d[3]
add wave -position insertpoint -expand -group srt_ctrl_path_3 sim:/tb_top/g_dut_64/dut/rem_carry_minus_d[3]
add wave -position insertpoint -expand -group srt_ctrl_path_3 sim:/tb_top/g_dut_64/dut/rem_sum_plus_d[3]
add wave -position insertpoint -expand -group srt_ctrl_path_3 sim:/tb_top/g_dut_64/dut/rem_carry_plus_d[3]


add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_sum_dp[0]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_carry_dp[0]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_sum_dp[1]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_carry_dp[1]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_sum_dp[2]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_carry_dp[2]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_sum_dp[3]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_carry_dp[3]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_sum_dp[4]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_carry_dp[4]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_sum_zero_dp
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_carry_zero_dp
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_sum_plus_d_dp
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_carry_plus_d_dp
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_sum_minus_d_dp
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/rem_carry_minus_d_dp
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/mux_divisor[0]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/mux_divisor[1]
add wave -position insertpoint -expand -group srt_data_path sim:/tb_top/g_dut_64/dut/mux_divisor[2]

