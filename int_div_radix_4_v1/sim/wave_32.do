add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/clk
add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/rst_n

add wave -position insertpoint -expand -group FSM_CTRL -radix unsigned sim:/tb_top/acq_count
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/stim_end
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_start_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_valid
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/dut_finish_ready
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/g_dut_32/dut/quotient_o
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/g_dut_32/dut/remainder_o
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/compare_ok
add wave -position insertpoint -expand -group FSM_CTRL sim:/tb_top/g_dut_32/dut/fsm_q


add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/signed_op_i
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/dividend_i
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/divisor_i
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/dividend_sign
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/divisor_sign
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/quot_sign_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/rem_sign_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/dividend_abs
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/dividend_abs_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/divisor_abs
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/divisor_abs_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/normalized_dividend
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/normalized_divisor
add wave -position insertpoint -expand -group main_signals -radix unsigned sim:/tb_top/g_dut_32/dut/dividend_lzc
add wave -position insertpoint -expand -group main_signals -radix unsigned sim:/tb_top/g_dut_32/dut/dividend_lzc_q
add wave -position insertpoint -expand -group main_signals -radix unsigned sim:/tb_top/g_dut_32/dut/divisor_lzc
add wave -position insertpoint -expand -group main_signals -radix unsigned sim:/tb_top/g_dut_32/dut/divisor_lzc_q
add wave -position insertpoint -expand -group main_signals -radix unsigned sim:/tb_top/g_dut_32/dut/lzc_diff_slow
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/no_iter_needed_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/dividend_too_small_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/divisor_is_one
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/divisor_is_zero

add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/final_iter
add wave -position insertpoint -expand -group main_signals -radix unsigned sim:/tb_top/g_dut_32/dut/iter_num_q

add wave -position insertpoint -expand -group main_signals -radix binary sim:/tb_top/g_dut_32/dut/pre_m_pos_1
add wave -position insertpoint -expand -group main_signals -radix binary sim:/tb_top/g_dut_32/dut/pre_m_pos_2
add wave -position insertpoint -expand -group main_signals -radix binary sim:/tb_top/g_dut_32/dut/pre_rem_trunc_1_4
add wave -position insertpoint -expand -group main_signals -radix binary sim:/tb_top/g_dut_32/dut/pre_cmp_res
add wave -position insertpoint -expand -group main_signals -radix binary sim:/tb_top/g_dut_32/dut/qds_para_neg_1_q
add wave -position insertpoint -expand -group main_signals -radix binary sim:/tb_top/g_dut_32/dut/qds_para_neg_0_q
add wave -position insertpoint -expand -group main_signals -radix binary sim:/tb_top/g_dut_32/dut/qds_para_pos_1_q
add wave -position insertpoint -expand -group main_signals -radix binary sim:/tb_top/g_dut_32/dut/qds_para_pos_2_q

add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/rem_sum_init_value
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/rem_sum_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/rem_carry_q
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/rem_sum_iter_end
add wave -position insertpoint -expand -group main_signals sim:/tb_top/g_dut_32/dut/rem_carry_iter_end

add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/prev_quot_digit_init_value
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/prev_quot_digit_q
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/quot_digit_iter_end
add wave -position insertpoint -expand -group srt_iter sim:/tb_top/g_dut_32/dut/csa_3_2_x1
add wave -position insertpoint -expand -group srt_iter sim:/tb_top/g_dut_32/dut/csa_3_2_x2
add wave -position insertpoint -expand -group srt_iter sim:/tb_top/g_dut_32/dut/csa_3_2_x3

add wave -position insertpoint -expand -group srt_iter sim:/tb_top/g_dut_32/dut/iter_quot_nxt
add wave -position insertpoint -expand -group srt_iter sim:/tb_top/g_dut_32/dut/iter_quot_q
add wave -position insertpoint -expand -group srt_iter sim:/tb_top/g_dut_32/dut/iter_quot_minus_1_nxt
add wave -position insertpoint -expand -group srt_iter sim:/tb_top/g_dut_32/dut/iter_quot_minus_1_q

add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/para_m_neg_1_trunc_2_5
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/para_m_neg_0_trunc_3_4
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/para_m_pos_1_trunc_3_4
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/para_m_pos_2_trunc_2_5

add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/divisor_mul_4_trunc_2_5
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/divisor_mul_4_trunc_3_4
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/divisor_mul_8_trunc_2_5
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/divisor_mul_8_trunc_3_4
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/divisor_mul_neg_4_trunc_2_5
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/divisor_mul_neg_4_trunc_3_4
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/divisor_mul_neg_8_trunc_2_5
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/divisor_mul_neg_8_trunc_3_4
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/divisor_for_sd_trunc_3_4
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/divisor_for_sd_trunc_2_5

add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/rem_sum_mul_16_trunc_2_5
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/rem_sum_mul_16_trunc_3_4
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/rem_carry_mul_16_trunc_2_5
add wave -position insertpoint -expand -group srt_iter -radix binary sim:/tb_top/g_dut_32/dut/u_qds/rem_carry_mul_16_trunc_3_4

add wave -position insertpoint -expand -group srt_iter sim:/tb_top/g_dut_32/dut/u_qds/sd_m_neg_1_sign
add wave -position insertpoint -expand -group srt_iter sim:/tb_top/g_dut_32/dut/u_qds/sd_m_neg_0_sign
add wave -position insertpoint -expand -group srt_iter sim:/tb_top/g_dut_32/dut/u_qds/sd_m_pos_1_sign
add wave -position insertpoint -expand -group srt_iter sim:/tb_top/g_dut_32/dut/u_qds/sd_m_pos_2_sign

add wave -position insertpoint -expand -group POST_PROCESS sim:/tb_top/g_dut_32/dut/nrdnt_rem_nxt
add wave -position insertpoint -expand -group POST_PROCESS sim:/tb_top/g_dut_32/dut/nrdnt_rem
add wave -position insertpoint -expand -group POST_PROCESS sim:/tb_top/g_dut_32/dut/nrdnt_rem_is_zero
add wave -position insertpoint -expand -group POST_PROCESS sim:/tb_top/g_dut_32/dut/nrdnt_rem_plus_d_nxt
add wave -position insertpoint -expand -group POST_PROCESS sim:/tb_top/g_dut_32/dut/nrdnt_rem_plus_d
add wave -position insertpoint -expand -group POST_PROCESS sim:/tb_top/g_dut_32/dut/need_corr

add wave -position insertpoint -expand -group R_SHIFT sim:/tb_top/g_dut_32/dut/post_r_shift_extend_msb
add wave -position insertpoint -expand -group R_SHIFT sim:/tb_top/g_dut_32/dut/post_r_shift_num
add wave -position insertpoint -expand -group R_SHIFT sim:/tb_top/g_dut_32/dut/post_r_shift_data_in
add wave -position insertpoint -expand -group R_SHIFT sim:/tb_top/g_dut_32/dut/post_r_shift_res_s5


add wave -position insertpoint -expand -group OUT sim:/tb_top/g_dut_32/dut/div_finish_valid_o
add wave -position insertpoint -expand -group OUT sim:/tb_top/g_dut_32/dut/final_quot
add wave -position insertpoint -expand -group OUT sim:/tb_top/g_dut_32/dut/final_rem


