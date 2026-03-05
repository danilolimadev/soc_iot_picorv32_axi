// ============================================================
// UART ROM Receiver
// Recebe dados via UART (8N1) e grava em memória interna
// Cada 4 bytes recebidos formam uma palavra 32-bit (LSB first)
// ============================================================

/* verilator lint_off UNUSEDSIGNAL */
`timescale 1 ns / 1 ps

module uart_rom_receiver #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200,
    parameter MEM_WORDS = 256
)(
    input  wire clk,
    input  wire resetn,
    input  wire uart_rx,
    input  wire [31:0] firmware_size,
    output reg  done,         // Adicione uma vírgula aqui se não tiver
    input  wire [31:0] rd_addr, // Nova porta
    output wire [31:0] rd_data  // Nova porta (sem vírgula na última)
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
    localparam RX_IDLE  = 2'd0;
    localparam RX_START = 2'd1;
    localparam RX_DATA  = 2'd2;
    localparam RX_STOP  = 2'd3;

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
                        if (uart_rx == 0) rx_state <= RX_START;
                    end
                    RX_START: begin
                        rx_state    <= RX_DATA;
                        rx_bitcount <= 0;
                    end
                    RX_DATA: begin
                        rx_shift <= {uart_rx, rx_shift[7:1]};
                        rx_bitcount <= rx_bitcount + 4'd1;
                        if (rx_bitcount == 4'd7) rx_state <= RX_STOP;
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
    // ROM Memory (RAM interna) e Montagem da Palavra
    // ========================================================
    reg [31:0] rom_mem [0:MEM_WORDS-1];
    reg [31:0] word_index;
    reg [1:0]  byte_index;
    reg [31:0] current_word;

    // Criamos um sinal de 32 bits para o rx_shift para evitar avisos de largura
    wire [31:0] rx_data_expanded = {24'b0, rx_shift};
	
// ATRIBUIÇÃO DE LEITURA (Isso permite que o boot_manager leia a ROM)
    assign rd_data = rom_mem[rd_addr];		

	always @(posedge clk) begin
			if (!resetn) begin
				word_index   <= 0;
				byte_index   <= 0;
				current_word <= 0;
				done         <= 0;
			end else begin
				if (rx_ready && !done) begin
					if (byte_index == 2'd3) begin
						rom_mem[word_index] <= current_word | (rx_data_expanded << 24);
						current_word <= 0;
						byte_index   <= 0;
						if (word_index == firmware_size - 1) done <= 1;
						else word_index <= word_index + 1;
					end else begin
						current_word <= current_word | (rx_data_expanded << (8 * byte_index));
						byte_index   <= byte_index + 2'd1;
					end
				end
			end
		end
endmodule
