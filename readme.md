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

### What I have done

1. Modify the `Basys-3-Master.xdc` file to enable switches, buttons, LEDs and 7-segment display on the board.
2. Create a *manual clock* with `btnU`, which generates one signal pulse when it is pressed.
3. Modify the `risc_top` module to set the rdy input of `cpu` and `ram` to *manual clock* when `sw0` is turned on.
4. Modify the `ram` and `single_port_ram_sync` module so that it outputs the value at the ram address requested last time when it is ready, instead of the address of the previous clock.
5. Read the official manual for the way to control of the 7-segment display and implemented `display_ctrl` module.
6. Connect the `dbgreg_dout` to the `display_ctrl` module. The lowest 16 bit of `dbgreg_dout` is displayed on the 7-segment display in hex.

### Truth table

![](./img/7-segment-display.png)

| # | A | B | C | D | E | F | G | DP |
|--|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:--:|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |
| 1 | 1 | 0 | 0 | 1 | 1 | 1 | 1 | 1 |
| 2 | 0 | 0 | 1 | 0 | 0 | 1 | 0 | 1 |
| 3 | 0 | 0 | 0 | 0 | 1 | 1 | 0 | 1 |
| 4 | 1 | 0 | 0 | 1 | 1 | 0 | 0 | 1 |
| 5 | 0 | 1 | 0 | 0 | 1 | 0 | 0 | 1 |
| 6 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| 7 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 |
| 8 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| 9 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 1 |
| A | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| b | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| c | 1 | 1 | 1 | 0 | 0 | 1 | 0 | 1 |
| d | 1 | 0 | 0 | 0 | 0 | 1 | 0 | 1 |
| E | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 1 |
| F | 0 | 1 | 1 | 1 | 0 | 0 | 0 | 1 |
