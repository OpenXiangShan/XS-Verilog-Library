quit -sim

file mkdir ./lib
file mkdir ./lib/work
file mkdir ./log
file mkdir ./wave

vlib ./lib
vlib ./lib/work

vmap work ./lib/work

vlog -work work -incr -f ../tb/tb.lst

vsim -c -l ./log/tb_top.log -wlf ./wave/tb_top.wlf -voptargs=+acc -sv_seed 38 work.tb_top


# 0: full names
# 1: leaf names
configure wave -signalnamewidth 1
configure wave -timelineunits ns

# wave files for WIDTH = 64
#do wave_64.do

# wave files for WIDTH = 32
#do wave_32.do

# wave files for WIDTH = 16
#do wave_16.do

run -all
