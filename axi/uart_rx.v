`timescale 1ns/1ps

module uart_rx (
  input wire clk,
  input wire reset,
  input wire rx,
  output reg [7:0] data_out,
  output reg rx_done
);

  // Estados da máquina
  localparam IDLE = 0, START = 1, DATA = 2, STOP = 3, DONE = 4, ERROR = 5;
  localparam CLK_PER_BIT = 16'd0020;//16'd5208; // Assumindo 9600 baud rate e 50 MHz clock

  reg [2:0] state, next_state;
  reg [7:0] shift_reg;
  reg [2:0] bit_counter;
  reg [15:0] clk_counter;
  reg rx_stop;
  reg enable_counter;
  reg enable_shift;
  reg load_data;

  // Contagem dos ciclos de clock
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      clk_counter <= 16'b0;
    end else if (enable_counter) begin
      if (clk_counter < CLK_PER_BIT - 1)
        clk_counter <= clk_counter + 1'b1;
      else
        clk_counter <= 16'b0;
    end else
      clk_counter <= 16'b0;
  end

  // Registrador de deslocamento
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      shift_reg <= 8'b0;
      data_out <= 8'b0;
    end else if (enable_shift) begin
      shift_reg[bit_counter] <= rx;
    end else if (load_data) begin
      data_out <= shift_reg;
    end
  end

  // Lógica sequencial: Transição de estado
  always @(posedge clk or posedge reset) begin
    if (reset)
      state <= IDLE;
    else
      state <= next_state;
  end

  // Lógica combinacional: próximo estado
  always @(*) begin
    next_state <= state;
    case (state)
      IDLE: if (rx == 0) next_state <= START;
      START: if (clk_counter == CLK_PER_BIT - 1) next_state <= DATA;
      DATA: if ((bit_counter == 7) && (clk_counter == CLK_PER_BIT - 1)) next_state <= STOP;
      STOP: if (clk_counter == CLK_PER_BIT - 1)
              next_state <= rx_stop ? DONE : ERROR;
      DONE: next_state <= IDLE;
      ERROR: next_state <= IDLE;
      default: next_state <= IDLE;
    endcase
  end

  // Lógica sequencial: Controle de sinais
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      rx_done <= 0;
      rx_stop <= 0;
      enable_counter <= 0;
      enable_shift <= 0;
      bit_counter <= 3'b0;
      load_data <= 0;
    end else begin
      case (state)
        IDLE: begin
          rx_done <= 0;
          rx_stop <= 0;
          enable_counter <= 0;
          enable_shift <= 0;
          bit_counter <= 3'b0;
          load_data <= 0;
        end
        START: begin
          rx_done <= 0;
          rx_stop <= 0;
          enable_counter <= 1;
          enable_shift <= 0;
          bit_counter <= 3'b0;
          load_data <= 0;
        end
        DATA: begin
          rx_done <= 0;
          rx_stop <= 0;
          enable_counter <= 1;
          load_data <= 0;
          enable_shift <= (clk_counter == CLK_PER_BIT / 2);
          if (clk_counter == CLK_PER_BIT - 1)
            bit_counter <= bit_counter + 1'b1;
          if ((bit_counter == 7) && (clk_counter == CLK_PER_BIT - 1))
            load_data <= 1;
        end
        STOP: begin
          enable_counter <= 1;
          enable_shift <= 0;
          bit_counter <= 3'b0;
          load_data <= 0;
          if (clk_counter == CLK_PER_BIT - 1)
            rx_done <= 1;
          if ((clk_counter == CLK_PER_BIT / 2) && rx)
            rx_stop <= 1;
        end
        DONE, ERROR: begin
          rx_done <= 0;
          rx_stop <= 0;
          enable_counter <= 0;
          enable_shift <= 0;
          bit_counter <= 3'b0;
          load_data <= 0;
        end
        default: begin
          rx_done <= 0;
          rx_stop <= 0;
          enable_counter <= 0;
          enable_shift <= 0;
          bit_counter <= 3'b0;
          load_data <= 0;
        end
      endcase
    end
  end

endmodule
