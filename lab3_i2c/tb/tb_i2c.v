// =============================================================================
// tb_i2c.v - самоперевірний тестбенч для I2C Master(Tx) <-> Slave(Rx)
// Тест 1: запис 0xA5 за адресою 0x50  -> очікуємо ACK, rx_data = 0xA5
// Тест 2: запис 0x3C за адресою 0x50  -> очікуємо ACK, rx_data = 0x3C
// Тест 3: запис 0x77 за адресою 0x51  -> очікуємо NACK (чужа адреса), даних немає
// =============================================================================
`timescale 1ns/1ps
module tb_i2c;
    reg        clk = 1'b0, rst = 1'b1, start = 1'b0;
    reg  [6:0] addr = 7'd0;
    reg  [7:0] data = 8'd0;
    wire       busy, done, ack_err, rx_valid, rx_match, scl, sda;
    wire [7:0] rx_data;
    integer    errors = 0, rx_count = 0;

    // CLK_DIV = 4 для швидкої симуляції (на реальній платі 125 -> SCL = 100 кГц)
    i2c_top #(.CLK_DIV(4), .SLAVE_ADDR(7'h50)) dut (
        .clk(clk), .rst(rst), .start(start), .addr(addr), .data(data),
        .busy(busy), .done(done), .ack_err(ack_err),
        .rx_data(rx_data), .rx_valid(rx_valid), .rx_match(rx_match),
        .scl(scl), .sda(sda));

    always #10 clk = ~clk;                 // 50 МГц

    always @(posedge clk) if (rx_valid) rx_count <= rx_count + 1;

    // Запис одного байта та перевірка результату
    task i2c_write(input [6:0] a, input [7:0] d, input expect_ack);
        integer before;
        begin
            before = rx_count;
            @(negedge clk); addr = a; data = d; start = 1'b1;
            @(negedge clk); start = 1'b0;
            @(posedge done);
            repeat (4) @(posedge clk);
            if (expect_ack) begin
                if (ack_err)               begin errors = errors + 1; $display("FAIL: очікувався ACK, addr=%h", a); end
                else if (rx_count != before + 1 || rx_data !== d)
                                           begin errors = errors + 1; $display("FAIL: Rx data=%h, очікувалось %h", rx_data, d); end
                else $display("PASS: addr=0x%h data=0x%h -> Rx отримав 0x%h, ACK", a, d, rx_data);
            end else begin
                if (!ack_err || rx_count != before)
                                           begin errors = errors + 1; $display("FAIL: очікувався NACK, addr=%h", a); end
                else $display("PASS: addr=0x%h -> NACK, дані не прийнято", a);
            end
            repeat (20) @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("sim/i2c.vcd");
        $dumpvars(0, tb_i2c);
        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (5) @(posedge clk);
        i2c_write(7'h50, 8'hA5, 1);
        i2c_write(7'h50, 8'h3C, 1);
        i2c_write(7'h51, 8'h77, 0);
        if (errors == 0) $display("=== УСІ ТЕСТИ ПРОЙДЕНО ===");
        else             $display("=== ПОМИЛОК: %0d ===", errors);
        $finish;
    end

    initial begin #200000; $display("TIMEOUT"); $finish; end
endmodule
