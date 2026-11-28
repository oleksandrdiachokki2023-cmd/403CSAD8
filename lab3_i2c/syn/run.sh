cd "$(dirname "$0")/.."
yosys -q -l syn/yosys.log -p "read_verilog rtl/i2c_tx.v rtl/i2c_rx.v rtl/i2c_top.v; synth_ice40 -top i2c_top -json syn/i2c.json; stat" >/dev/null
nextpnr-ice40 --hx8k --package ct256 --json syn/i2c.json --freq 50 --seed 1 --log syn/nextpnr.log -q
