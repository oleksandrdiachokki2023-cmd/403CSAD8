// =============================================================================
// i2c_top.v - верхній рівень: Master (Tx) + Slave (Rx), з'єднані шиною
// з монтажним "І" (open-drain). Використовується для синтезу та симуляції.
// =============================================================================
module i2c_top #(
    parameter integer CLK_DIV    = 125,
    parameter [6:0]   SLAVE_ADDR = 7'h50
)(
    input  wire       clk, rst, start,
    input  wire [6:0] addr,
    input  wire [7:0] data,
    output wire       busy, done, ack_err,
    output wire [7:0] rx_data,
    output wire       rx_valid, rx_match,
    output wire       scl, sda
);
    wire scl_m, sda_m, sda_s;
    assign scl = scl_m;
    assign sda = sda_m & sda_s;                    // wired-AND

    i2c_tx #(.CLK_DIV(CLK_DIV)) u_tx (
        .clk(clk), .rst(rst), .start(start), .addr(addr), .data(data),
        .scl_o(scl_m), .sda_o(sda_m), .sda_i(sda),
        .busy(busy), .done(done), .ack_err(ack_err));

    i2c_rx #(.SLAVE_ADDR(SLAVE_ADDR)) u_rx (
        .clk(clk), .rst(rst), .scl_i(scl), .sda_i(sda), .sda_o(sda_s),
        .data_out(rx_data), .data_valid(rx_valid), .addr_match(rx_match));
endmodule
