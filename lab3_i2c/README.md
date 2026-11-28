# Лаб. 3 — I2C (Verilog), варіант 2
rtl/ — i2c_tx.v (Master Tx), i2c_rx.v (Slave Rx), i2c_top.v
tb/  — tb_i2c.v (самоперевірний тестбенч)
Симуляція: iverilog -g2005 -o sim/tb.vvp rtl/*.v tb/tb_i2c.v && vvp sim/tb.vvp
Синтез:    bash syn/run.sh   (Yosys synth_ice40 + nextpnr-ice40 --hx8k)
