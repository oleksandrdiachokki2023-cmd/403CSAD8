// =============================================================================
// i2c_rx.v - I2C Slave Receiver (Rx)
// Варіант 2: I2C, Verilog
// Детектує START/STOP, приймає адресу, порівнює її з SLAVE_ADDR, приймає байти
// даних і підтверджує їх (ACK).
// =============================================================================
module i2c_rx #(
    parameter [6:0] SLAVE_ADDR = 7'h50      // власна адреса пристрою
)(
    input  wire       clk,         // системний такт
    input  wire       rst,         // синхронний скид (активний 1)
    input  wire       scl_i,       // вхід SCL з шини
    input  wire       sda_i,       // вхід SDA з шини
    output reg        sda_o,       // вихід SDA (open-drain, 1 = відпущено)
    output reg  [7:0] data_out,    // останній прийнятий байт
    output reg        data_valid,  // імпульс: прийнято новий байт
    output reg        addr_match   // адресу розпізнано
);
    localparam [2:0] R_IDLE     = 3'd0,
                     R_ADDR     = 3'd1,
                     R_ADDR_ACK = 3'd2,
                     R_DATA     = 3'd3,
                     R_DATA_ACK = 3'd4;

    // ---- Синхронізатори вхідних сигналів (2 тригери) + історія для детекції фронтів
    reg [2:0] scl_s, sda_s;
    always @(posedge clk) begin
        scl_s <= {scl_s[1:0], scl_i};
        sda_s <= {sda_s[1:0], sda_i};
    end
    wire scl_now  = scl_s[1], scl_prev = scl_s[2];
    wire sda_now  = sda_s[1], sda_prev = sda_s[2];
    wire scl_rise = ~scl_prev &  scl_now;
    wire scl_fall =  scl_prev & ~scl_now;
    wire start_c  =  scl_now & sda_prev & ~sda_now;   // SDA падає при SCL=1
    wire stop_c   =  scl_now & ~sda_prev & sda_now;   // SDA зростає при SCL=1

    reg [2:0] state;
    reg [3:0] bit_cnt;       // кількість прийнятих біт
    reg [7:0] shreg;         // зсувний регістр прийому
    reg       match_r;       // результат порівняння адреси

    always @(posedge clk) begin
        data_valid <= 1'b0;
        if (rst) begin
            state <= R_IDLE; bit_cnt <= 4'd0; shreg <= 8'd0; sda_o <= 1'b1;
            data_out <= 8'd0; addr_match <= 1'b0; match_r <= 1'b0;
        end else if (start_c) begin                 // (повторний) START: чекаємо адресу
            state <= R_ADDR; bit_cnt <= 4'd0; sda_o <= 1'b1; addr_match <= 1'b0;
        end else if (stop_c) begin                  // STOP: повертаємось у IDLE
            state <= R_IDLE; sda_o <= 1'b1;
        end else begin
            case (state)
                R_ADDR, R_DATA: if (scl_rise) begin // біти фіксуються по фронту SCL
                    shreg   <= {shreg[6:0], sda_now};
                    bit_cnt <= bit_cnt + 4'd1;
                end else if (scl_fall && bit_cnt == 4'd8) begin
                    bit_cnt <= 4'd0;
                    if (state == R_ADDR) begin
                        if (shreg[7:1] == SLAVE_ADDR && shreg[0] == 1'b0) begin
                            sda_o <= 1'b0; addr_match <= 1'b1; state <= R_ADDR_ACK; // ACK
                        end else state <= R_IDLE;     // чужа адреса - ігноруємо (NACK)
                    end else begin
                        sda_o <= 1'b0; data_out <= shreg; data_valid <= 1'b1;
                        state <= R_DATA_ACK;
                    end
                end
                R_ADDR_ACK: if (scl_fall) begin sda_o <= 1'b1; state <= R_DATA; end
                R_DATA_ACK: if (scl_fall) begin sda_o <= 1'b1; state <= R_DATA; end
                default: ;
            endcase
        end
    end
endmodule
