

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

|CPU|Algorithm|F16|F32|F64|
|------|------|------|------|------|
|**This design**|**Radix-64 SRT**|**4**|**6**|**12**|
|Intel Coeffee Lake[^coeffee]|Radix-1024 SRT|x|11|13 ~ 14|
|AMD Zen3/Zen2[^amd]|Unknown, guess it also use some kinds of SRT|x|10|13|
|AMD Jaguar[^Jaguar]|Multiplicative|x|14|19|
|ARM Cortex A55, and other "small cores"[^arm]|Radix-8 SRT|8|13|22|
|ARM Cortex A76, and its successors[^arm]|Radix-64 SRT|7|7 ~ 10|7 ~ 15|
|ARM Cortex A75[^arm]|Radix-64 SRT|6 ~ 8|6 ~ 10|6 ~ 15|
|ARM Cortex A72[^arm]|Radix-16 SRT|x|6 ~ 11|6 ~ 18|
|ARM Cortex A57[^arm]|Radix-4 SRT|x|7 ~ 17|7 ~ 32|
|IBM Z13[^ibm]|Radix-8 SRT|x|18|28|
|HAL Sparc[^HAL]|Multiplicative|x|16|19|
|OpenC910[^c910]|Radix-16 SRT|4 ~ 7|4 ~ 10|4 ~ 17|


[^coeffee]: https://www.agner.org/optimize/instruction_tables.pdf
[^amd]: https://www.amd.com/en/support/tech-docs
[^Jaguar]: http://ieeexplore.ieee.org/document/6545886?arnumber=6545886
[^arm]: https://developer.arm.com/documentation
[^ibm]: https://ieeexplore.ieee.org/abstract/document/7563276/
[^HAL]: http://ieeexplore.ieee.org/abstract/document/930117/similar
[^c910]: https://github.com/T-head-Semi/openc910

