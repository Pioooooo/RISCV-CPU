# RISCV CPU

- Repo: github.com/Pioooooo/RISCV-CPU
- Hash: f4bfffc826b98634c4652fb6d5280bf6e3422924

- Implemented on FPGA.
- Frequency: 100MHz, WNS: -0.950ns
- Supported features:
  - ICache: 256 lines
  - Branch Predictor: BTB + two-level adaptive predictor

Failed tests: pi, hanoi, heart, magic, statement_test.

## DBG mode

1. Use the `risc_top.v`, `Basys-3-Master.xdc`, `testbench.v`, `display_ctrl.v` in the repo.
2. Bind the wanted output to the `dbgreg_dout` of the `cpu` module.
3. Turn on `SW1` to turn on the display.
4. Turn on `SW0` to turn on manual control of `rdy`.
5. With `SW0` on, press `btnU` to step forward to the next `clk` period.
6. Set `DBG` in `testbench.v` to use in simulation.# RISCV-CPU
