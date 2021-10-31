add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/clk
add wave -position insertpoint -expand -group CLK_RST sim:/tb_top/rst_n

add wave -position insertpoint -expand -group STATE -radix unsigned sim:/tb_top/acq_count
add wave -position insertpoint -expand -group STATE sim:/tb_top/stim_end
add wave -position insertpoint -expand -group STATE sim:/tb_top/dut_start_valid
add wave -position insertpoint -expand -group STATE sim:/tb_top/dut_start_ready
add wave -position insertpoint -expand -group STATE sim:/tb_top/dut_finish_valid
add wave -position insertpoint -expand -group STATE sim:/tb_top/dut_finish_ready
add wave -position insertpoint -expand -group STATE sim:/tb_top/compare_ok
add wave -position insertpoint -expand -group STATE sim:/tb_top/quotient_16
add wave -position insertpoint -expand -group STATE sim:/tb_top/remainder_16
add wave -position insertpoint -expand -group STATE sim:/tb_top/g_dut_16/u_dut/final_quo
add wave -position insertpoint -expand -group STATE sim:/tb_top/g_dut_16/u_dut/final_rem

add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_16/u_dut/op_sign_i
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_16/u_dut/dividend_i
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_16/u_dut/divisor_i
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_16/u_dut/dividend_sign
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_16/u_dut/divisor_sign
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_16/u_dut/quo_sign
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_16/u_dut/rem_sign
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_16/u_dut/dividend_abs
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_16/u_dut/dividend_adjusted
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_16/u_dut/divisor_adjusted
add wave -position insertpoint -expand -group MAIN_SIGNALS sim:/tb_top/g_dut_16/u_dut/D_times_3

add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/D_msb_to_lsb_flag
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/D_lsb_to_msb_flag
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/D_times_3_msb_to_lsb_flag
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/D_times_3_lsb_to_msb_flag

add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/force_q_to_zero
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/force_q_to_zero_prev_q_0
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/force_q_to_zero_prev_q_1

add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/rem
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/rem_sum
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/rem_cout
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/rem_sum_prev_q_0
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/rem_sum_prev_q_1
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/rem_cout_prev_q_0
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/rem_cout_prev_q_1

add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/quo_iter
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/q_prev_q_0
add wave -position insertpoint -expand -group DATA_PATH sim:/tb_top/g_dut_16/u_dut/q_prev_q_1



