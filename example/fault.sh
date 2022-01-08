mkdir -p fault
[ -d fault ] && echo "Clean-up old results." && rm -rf fault/*

mv flow/results/sky130hd/riscv-mini/base/1_synth.v flow/results/sky130hd/riscv-mini/base/1_synth.no_dft.v

fault chain \
    --clock clock --reset reset \
    --liberty /openroad-flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib \
    --dff sky130_fd_sc_hd__dfrtp_1,sky130_fd_sc_hd__dfxtp_1 \
    --output fault/fault.v \
    ./flow/results/sky130hd/riscv-mini/base/1_synth.no_dft.v

ln -s $(readlink -f fault/fault.v) ./flow/results/sky130hd/riscv-mini/base/1_synth.v
