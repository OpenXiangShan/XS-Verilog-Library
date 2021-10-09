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

add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/signed_op_i
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/dividend_i
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/divisor_i
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/dividend_sign
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/divisor_sign
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/dividend_abs
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/dividend_abs_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/divisor_abs
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/divisor_abs_q

add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/normalized_dividend
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/normalized_divisor

add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/quo_sign_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/rem_sign_q

add wave -position insertpoint -expand -group MAIN_SIGNALS -radix unsigned sim:/tb_top/g_dut_64/dut/dividend_lzc
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix unsigned sim:/tb_top/g_dut_64/dut/dividend_lzc_q
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix unsigned sim:/tb_top/g_dut_64/dut/divisor_lzc
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix unsigned sim:/tb_top/g_dut_64/dut/divisor_lzc_q
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix unsigned sim:/tb_top/g_dut_64/dut/lzc_diff_slow
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix unsigned sim:/tb_top/g_dut_64/dut/iter_num_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/no_iter_needed_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/final_iter
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/dividend_too_small_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/divisor_is_zero
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/rem_sum_init_value
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/rem_sum_q
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_64/dut/rem_carry_q

add wave -position insertpoint -expand -group MAIN_SIGNALS -radix binary sim:/tb_top/g_dut_64/dut/pre_m_pos_1
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix binary sim:/tb_top/g_dut_64/dut/pre_m_pos_2
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix binary sim:/tb_top/g_dut_64/dut/pre_rem_trunc_1_4
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix binary sim:/tb_top/g_dut_64/dut/pre_cmp_res
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix binary sim:/tb_top/g_dut_64/dut/qds_para_neg_1_q
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix binary sim:/tb_top/g_dut_64/dut/qds_para_neg_0_q
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix binary sim:/tb_top/g_dut_64/dut/qds_para_pos_1_q
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix binary sim:/tb_top/g_dut_64/dut/qds_para_pos_2_q
add wave -position insertpoint -expand -group MAIN_SIGNALS -radix binary sim:/tb_top/g_dut_64/dut/special_divisor_q

add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/prev_quo_digit_init_value
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/quo_digit_nxt
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/prev_quo_digit_q

add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/quo_iter_q
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/quo_m1_iter_q
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/quo_digit_s0
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/quo_digit_s1
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/quo_iter_s0
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/quo_m1_iter_s0
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/quo_iter_s1
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/quo_m1_iter_s1

add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/para_m_neg_1
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/para_m_neg_0
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/para_m_pos_1
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/para_m_pos_2
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/divisor_mul_4_trunc_2_5
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/divisor_mul_4_trunc_3_4
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/divisor_mul_8_trunc_2_5
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/divisor_mul_8_trunc_3_4
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/divisor_mul_neg_4_trunc_2_5
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/divisor_mul_neg_4_trunc_3_4
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/divisor_mul_neg_8_trunc_2_5
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/divisor_mul_neg_8_trunc_3_4
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/divisor_mul_neg_8_trunc_3_4
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/divisorfor_sd_trunc_2_5
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/divisorfor_sd_trunc_3_4
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/rem_sum_mul_16_trunc_2_5
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/rem_sum_mul_16_trunc_3_4
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/rem_carry_mul_16_trunc_2_5
add wave -position insertpoint -expand -group SRT_BLOCK -radix binary sim:/tb_top/g_dut_64/dut/u_r16_block/rem_carry_mul_16_trunc_3_4

add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/sd_m_neg_1_sign_s0
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/sd_m_neg_0_sign_s0
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/sd_m_pos_1_sign_s0
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/sd_m_pos_2_sign_s0
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/sd_m_neg_1_sign_s1
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/sd_m_neg_0_sign_s1
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/sd_m_pos_1_sign_s1
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/sd_m_pos_2_sign_s1


add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/csa_x1[0]
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/csa_x2[0]
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/csa_x3[0]
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/csa_x1[1]
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/csa_x2[1]
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/csa_x3[1]
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/rem_sum[0]
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/rem_carry[0]
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/rem_sum[1]
add wave -position insertpoint -expand -group SRT_BLOCK sim:/tb_top/g_dut_64/dut/u_r16_block/rem_carry[1]


add wave -position insertpoint -expand -group POST_PROCESS sim:/tb_top/g_dut_64/dut/nr_rem_nxt
add wave -position insertpoint -expand -group POST_PROCESS sim:/tb_top/g_dut_64/dut/nr_rem
add wave -position insertpoint -expand -group POST_PROCESS sim:/tb_top/g_dut_64/dut/nr_rem_is_zero
add wave -position insertpoint -expand -group POST_PROCESS sim:/tb_top/g_dut_64/dut/nr_rem_plus_d_nxt
add wave -position insertpoint -expand -group POST_PROCESS sim:/tb_top/g_dut_64/dut/nr_rem_plus_d
add wave -position insertpoint -expand -group POST_PROCESS sim:/tb_top/g_dut_64/dut/need_corr

add wave -position insertpoint -expand -group R_SHIFT sim:/tb_top/g_dut_64/dut/post_r_shift_extend_msb
add wave -position insertpoint -expand -group R_SHIFT sim:/tb_top/g_dut_64/dut/post_r_shift_num
add wave -position insertpoint -expand -group R_SHIFT sim:/tb_top/g_dut_64/dut/post_r_shift_data_in
add wave -position insertpoint -expand -group R_SHIFT sim:/tb_top/g_dut_64/dut/post_r_shift_res_s5

add wave -position insertpoint -expand -group OUT sim:/tb_top/g_dut_64/dut/div_finish_valid_o
add wave -position insertpoint -expand -group OUT sim:/tb_top/g_dut_64/dut/final_quo
add wave -position insertpoint -expand -group OUT sim:/tb_top/g_dut_64/dut/final_rem

