// =============================================================================
// i2c_tx.v - I2C Master Transmitter (Tx)
// Варіант 2: I2C, Verilog
// Виконує запис одного байта: START -> ADDR(7)+W -> ACK -> DATA(8) -> ACK -> STOP
// Шина open-drain: вихід 1 = лінію відпущено (підтяжка до "1"), 0 = лінію притиснуто.
// =============================================================================
module i2c_tx #(
    parameter integer CLK_DIV = 125   // тактів clk на 1/4 періоду SCL (50 МГц / (4*125) = 100 кГц)
)(
    input  wire       clk,       // системний такт
    input  wire       rst,       // синхронний скид (активний 1)
    input  wire       start,     // імпульс запуску транзакції
    input  wire [6:0] addr,      // 7-бітна адреса Slave
    input  wire [7:0] data,      // байт даних для запису
    output reg        scl_o,     // лінія SCL (open-drain, 1 = відпущено)
    output reg        sda_o,     // лінія SDA (open-drain, 1 = відпущено)
    input  wire       sda_i,     // стан шини SDA (для читання ACK)
    output wire       busy,      // транзакція виконується
    output reg        done,      // імпульс завершення транзакції
    output reg        ack_err    // 1, якщо Slave не підтвердив (NACK)
);
    // ---- Стани скінченного автомата ----
    localparam [2:0] S_IDLE     = 3'd0,
                     S_START    = 3'd1,
                     S_ADDR     = 3'd2,   // 7 біт адреси + біт R/W (=0)
                     S_ADDR_ACK = 3'd3,
                     S_DATA     = 3'd4,
                     S_DATA_ACK = 3'd5,
                     S_STOP     = 3'd6;

    reg [2:0]  state;
    reg [1:0]  ph;          // фаза біта: 0..3 (1 біт = 4 тіки)
    reg [15:0] div_cnt;     // лічильник дільника частоти
    reg [2:0]  bit_cnt;     // номер біта, що передається (7..0)
    reg [7:0]  shreg;       // зсувний регістр поточного байта
    reg [7:0]  data_r;      // збережений байт даних
    wire       tick = (div_cnt == CLK_DIV - 1);

    assign busy = (state != S_IDLE);

    // Дільник частоти: формує тік кожні CLK_DIV тактів
    always @(posedge clk) begin
        if (rst || state == S_IDLE)       div_cnt <= 16'd0;
        else if (tick)                    div_cnt <= 16'd0;
        else                              div_cnt <= div_cnt + 16'd1;
    end

    always @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            state <= S_IDLE; ph <= 2'd0; scl_o <= 1'b1; sda_o <= 1'b1;
            bit_cnt <= 3'd7; shreg <= 8'd0; data_r <= 8'd0; ack_err <= 1'b0;
        end else if (state == S_IDLE) begin
            scl_o <= 1'b1; sda_o <= 1'b1; ph <= 2'd0;
            if (start) begin
                shreg   <= {addr, 1'b0};   // адреса + R/W = 0 (запис)
                data_r  <= data;
                ack_err <= 1'b0;
                state   <= S_START;
            end
        end else if (tick) begin
            ph <= ph + 2'd1;
            case (state)
                // START: SDA падає при SCL = 1
                S_START: case (ph)
                    2'd0: begin sda_o <= 1'b1; scl_o <= 1'b1; end
                    2'd1: sda_o <= 1'b0;                       // умова START
                    2'd3: begin scl_o <= 1'b0; state <= S_ADDR; bit_cnt <= 3'd7; end
                    default: ;
                endcase
                // Передача біта: SDA виставляється при SCL=0, SCL=1 у фазах 1..2
                S_ADDR, S_DATA: case (ph)
                    2'd0: sda_o <= shreg[7];
                    2'd1: scl_o <= 1'b1;
                    2'd3: begin
                        scl_o <= 1'b0;
                        shreg <= {shreg[6:0], 1'b0};
                        if (bit_cnt == 3'd0) state <= (state == S_ADDR) ? S_ADDR_ACK : S_DATA_ACK;
                        else bit_cnt <= bit_cnt - 3'd1;
                    end
                    default: ;
                endcase
                // Біт ACK: Master відпускає SDA, Slave тягне її в 0
                S_ADDR_ACK, S_DATA_ACK: case (ph)
                    2'd0: sda_o <= 1'b1;
                    2'd1: scl_o <= 1'b1;
                    2'd2: if (sda_i) ack_err <= 1'b1;          // NACK
                    2'd3: begin
                        scl_o <= 1'b0;
                        if (sda_i || state == S_DATA_ACK) state <= S_STOP;
                        else begin
                            state <= S_DATA; shreg <= data_r; bit_cnt <= 3'd7;
                        end
                    end
                    default: ;
                endcase
                // STOP: SDA зростає при SCL = 1
                S_STOP: case (ph)
                    2'd0: sda_o <= 1'b0;
                    2'd1: scl_o <= 1'b1;
                    2'd2: sda_o <= 1'b1;                       // умова STOP
                    2'd3: begin state <= S_IDLE; done <= 1'b1; end
                    default: ;
                endcase
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
