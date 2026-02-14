// ============================================================
// UART ROM Receiver
// Recebe dados via UART (8N1) e grava em memória interna
// Cada 4 bytes recebidos formam uma palavra 32-bit (LSB first)
// ============================================================

`timescale 1ns/1ps

module uart_rom_receiver #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200,
    parameter MEM_WORDS = 256
)(
    input  wire clk,
    input  wire resetn,
    input  wire uart_rx,
    input wire [31:0] firmware_size,
    output reg  done
);

    // ========================================================
    // Baud Generator
    // ========================================================

    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;

    reg [31:0] baud_cnt;
    reg baud_tick;

    always @(posedge clk) begin
        if (!resetn) begin
            baud_cnt  <= 0;
            baud_tick <= 0;
        end else begin
            if (baud_cnt == BAUD_DIV-1) begin
                baud_cnt  <= 0;
                baud_tick <= 1;
            end else begin
                baud_cnt  <= baud_cnt + 1;
                baud_tick <= 0;
            end
        end
    end

    // ========================================================
    // UART RX Engine (8N1)
    // ========================================================

    localparam RX_IDLE  = 0;
    localparam RX_START = 1;
    localparam RX_DATA  = 2;
    localparam RX_STOP  = 3;

    reg [1:0]  rx_state;
    reg [3:0]  rx_bitcount;
    reg [7:0]  rx_shift;
    reg        rx_ready;

    always @(posedge clk) begin
        if (!resetn) begin
            rx_state    <= RX_IDLE;
            rx_bitcount <= 0;
            rx_shift    <= 0;
            rx_ready    <= 0;
        end else begin
            rx_ready <= 0;

            if (baud_tick) begin
                case (rx_state)

                    RX_IDLE: begin
                        if (uart_rx == 0) // detect start bit
                            rx_state <= RX_START;
                    end

                    RX_START: begin
                        rx_state    <= RX_DATA;
                        rx_bitcount <= 0;
                    end

                    RX_DATA: begin
                        rx_shift <= {uart_rx, rx_shift[7:1]};
                        rx_bitcount <= rx_bitcount + 1;
                        if (rx_bitcount == 7)
                            rx_state <= RX_STOP;
                    end

                    RX_STOP: begin
                        rx_state <= RX_IDLE;
                        rx_ready <= 1;
                    end

                endcase
            end
        end
    end

    // ========================================================
    // ROM Memory (RAM interna)
    // ========================================================

    reg [31:0] rom_mem [0:MEM_WORDS-1];

    reg [31:0] word_index;
    reg [1:0]  byte_index;
    reg [31:0] current_word;

    always @(posedge clk) begin
        if (!resetn) begin
            word_index   <= 0;
            byte_index   <= 0;
            current_word <= 0;
            done         <= 0;
        end else begin

            if (rx_ready && !done) begin
                current_word <= current_word | (rx_shift << (8 * byte_index));
                byte_index   <= byte_index + 1;

                if (byte_index == 3) begin
                    rom_mem[word_index] <= current_word | (rx_shift << (8 * byte_index));
                    current_word <= 0;
                    byte_index   <= 0;

                    if (word_index == firmware_size-1) begin
                        done <= 1;
                    end else begin
                        word_index <= word_index + 1;
                    end
                end
            end

        end
    end

endmodule
