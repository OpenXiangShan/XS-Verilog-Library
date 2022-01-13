

This is a high performance floating point divider, which is in compliance with riscv-spec.



# Latency Details (Measured in cycles)

## F64

|Operands Combination|Normalization|Scaling|SRT_ITER|Denormalization|Rounding|Total|
|------|------|------|------|------|------|------|
|normal inputs, normal result|0|1.5|9|0|1|12|
|denormal inputs, normal result|1.5|1.5|9|0|1|13|
|normal inputs, denormal result|0|1.5|9|1|1|13|
|denormal inputs, denormal result|1.5|1.5|9|1|1|14|

## F32

|Operands Combination|Normalization|Scaling|SRT_ITER|Denormalization|Rounding|Total|
|------|------|------|------|------|------|------|
|normal inputs, normal result|0|1|4|0|1|6|
|denormal inputs, normal result|1|1|4|0|1|7|
|normal inputs, denormal result|0|1|4|1|1|7|
|denormal inputs, denormal result|1|1|4|1|1|8|

## F16

|Operands Combination|Normalization|Scaling|SRT_ITER|Denormalization|Rounding|Total|
|------|------|------|------|------|------|------|
|normal inputs, normal result|0|1|2|0|1|4|
|denormal inputs, normal result|1|1|2|0|1|5|
|normal inputs, denormal result|0|1|2|1|1|5|
|denormal inputs, denormal result|1|1|2|1|1|6|

_When the divisor is a normal number and is a power of 2, the "SRT_ITER" step could be skipped._

_So the latency could be reduced by 9/4/2 for F64/F32/F16._

# Performance Comparison With Mainstream CPUs (Assuming normal inputs and normal result)

||F16|F32|F64|
|------|------|------|------|
|This design|4|6|12|
|Intel Coeffee Lake|x|11|13~14|
|AMD Zen3/Zen3|x|10|13|
|AMD Jaguar|x|14|19|
|ARM Cortex A55, and other "small cores"|8|13|22|
|ARM Cortex A76, and its successors|7|7 ~ 10|7 ~ 15|
|ARM Cortex A75|6 ~ 8|6 ~ 10|6 ~ 15|
|ARM Cortex A72|x|6 ~ 11|6 ~ 18|
|ARM Cortex A57|x|7 ~ 17|7 ~ 32|
