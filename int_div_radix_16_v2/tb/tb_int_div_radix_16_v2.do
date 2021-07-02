quit -sim

set toplevel {tb_int_div_radix_16_v2}

file mkdir ./lib
file mkdir ./lib/work

vlib ./lib
vlib ./lib/work

vmap work ./lib/work

vlog -work work -incr -f $toplevel.lst

vsim -c -l $toplevel.log -voptargs=+acc -sv_seed 5 work.$toplevel


# 0: full names
# 1: leaf names
configure wave -signalnamewidth 1
configure wave -timelineunits ns

# wave files for WIDTH = 64
#do wave.do

# wave files for WIDTH = 32
#do wave_32.do

# wave files for WIDTH = 16
do wave_16.do


run -all
