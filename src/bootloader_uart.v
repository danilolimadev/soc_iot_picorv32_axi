// ============================================================
// Bootloader UART
// Lê firmware.hex e envia palavra por palavra via UART
// Quando boot_enable = 1, inicia transmissão automática
// ============================================================

`timescale 1ns/1ps

module bootloader_uart #(
    parameter CLK_FREQ      = 50_000_000,
    parameter BAUD_RATE     = 115200,
    parameter MEM_WORDS     = 256,          // quantidade de palavras 32-bit
    parameter FIRMWARE_FILE = "firmware.hex"
  )(
    input  wire clk,
    input  wire resetn,
    input  wire boot_enable,

    output wire uart_tx,
    output reg  done,
    output reg [31:0] firmware_size
  );

  // ========================================================
  // UART Baudrate Generator
  // ========================================================

  localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;

  reg [31:0] baud_cnt;
  reg baud_tick;

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      baud_cnt  <= 0;
      baud_tick <= 0;
    end
    else
    begin
      if (baud_cnt == BAUD_DIV-1)
      begin
        baud_cnt  <= 0;
        baud_tick <= 1;
      end
      else
      begin
        baud_cnt  <= baud_cnt + 1;
        baud_tick <= 0;
      end
    end
  end

  // ========================================================
  // Firmware Memory
  // ========================================================

  reg [31:0] firmware_mem [0:MEM_WORDS-1];

  integer i;

  initial
  begin
    // Inicializa tudo com X
    for (i = 0; i < MEM_WORDS; i = i + 1)
      firmware_mem[i] = 32'hxxxxxxxx;

    // Carrega arquivo
    $readmemh(FIRMWARE_FILE, firmware_mem);

    // Conta quantas palavras válidas existem
    firmware_size = 0;
    for (i = 0; i < MEM_WORDS; i = i + 1)
    begin
      if (^firmware_mem[i] !== 1'bx)
        firmware_size = firmware_size + 1;
      else
        i = MEM_WORDS;  // força saída do loop
    end
  end


  // ========================================================
  // UART TX Engine (8N1)
  // ========================================================

  reg [3:0]  tx_state;
  reg [9:0]  tx_shift;
  reg [3:0]  tx_bitcount;
  reg        tx_busy;
  reg        tx_reg;

  assign uart_tx = tx_reg;

  localparam TX_IDLE  = 0;
  localparam TX_START = 1;
  localparam TX_DATA  = 2;
  localparam TX_STOP  = 3;

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      tx_state    <= TX_IDLE;
      tx_shift    <= 10'h3FF;
      tx_bitcount <= 0;
      tx_busy     <= 0;
      tx_reg      <= 1'b1;
    end
    else
    begin
      if (baud_tick)
      begin
        case (tx_state)
          TX_IDLE:
          begin
            if (tx_busy)
            begin
              tx_state <= TX_START;
              tx_reg   <= 0; // start bit
            end
          end

          TX_START:
          begin
            tx_state    <= TX_DATA;
            tx_bitcount <= 0;
            tx_reg      <= tx_shift[0];
            tx_shift    <= {1'b1, tx_shift[9:1]};
          end

          TX_DATA:
          begin
            tx_bitcount <= tx_bitcount + 1;
            tx_reg      <= tx_shift[0];
            tx_shift    <= {1'b1, tx_shift[9:1]};
            if (tx_bitcount == 7)
              tx_state <= TX_STOP;
          end

          TX_STOP:
          begin
            tx_reg   <= 1'b1;
            tx_state <= TX_IDLE;
            tx_busy  <= 0;
          end
        endcase
      end
    end
  end

  // ========================================================
  // Bootloader Control FSM
  // Envia cada palavra 32-bit como 4 bytes (LSB first)
  // ========================================================

  reg [31:0] word_index;
  reg [1:0]  byte_index;
  reg [31:0] current_word;

  localparam BL_IDLE   = 0;
  localparam BL_LOAD   = 1;
  localparam BL_SEND   = 2;
  localparam BL_WAIT   = 3;
  localparam BL_DONE   = 4;

  reg [2:0] bl_state;

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      bl_state    <= BL_IDLE;
      word_index  <= 0;
      byte_index  <= 0;
      done        <= 0;
    end
    else
    begin
      case (bl_state)

        BL_IDLE:
        begin
          done <= 0;
          if (boot_enable)
          begin
            word_index <= 0;
            bl_state   <= BL_LOAD;
          end
        end

        BL_LOAD:
        begin
          current_word <= firmware_mem[word_index];
          byte_index   <= 0;
          bl_state     <= BL_SEND;
        end

        BL_SEND:
        begin
          if (!tx_busy)
          begin
            tx_busy  <= 1;
            tx_shift <= {1'b1, current_word[7:0], 1'b0}; // stop + data + start
            bl_state <= BL_WAIT;
          end
        end

        BL_WAIT:
        begin
          if (!tx_busy)
          begin
            current_word <= current_word >> 8;
            if (byte_index == 3)
            begin
              if (word_index == firmware_size-1)
              begin
                bl_state <= BL_DONE;
              end
              else
              begin
                word_index <= word_index + 1;
                bl_state   <= BL_LOAD;
              end
            end
            else
            begin
              byte_index <= byte_index + 1;
              bl_state   <= BL_SEND;
            end
          end
        end

        BL_DONE:
        begin
          done <= 1;
        end

      endcase
    end
  end

endmodule
