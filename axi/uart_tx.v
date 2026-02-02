module uart_tx (
  input wire clk,
  input wire reset,
  input wire [7:0] data_in,
  input wire tx_start,
  output reg tx,
  output reg tx_done
);

  // Estados da máquina
  localparam IDLE = 0, START = 1, DATA = 2, STOP = 3, DONE = 4;
  localparam CLK_PER_BIT = 16'd0020;//16'd5208; // Assumindo 9600 baud rate e 50 MHz clock

  reg [2:0] state, next_state;
  reg [7:0] shift_reg;
  reg [2:0] bit_counter;
  reg [15:0] clk_counter;
  reg load_data;
  reg enable_counter;
  reg enable_shift;
  reg tx_reg;

  // Contagem dos ciclos de clock
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      clk_counter <= 16'b0;
    end else if (enable_counter) begin
      if (clk_counter < CLK_PER_BIT - 1) begin
        clk_counter <= clk_counter + 1'b1;
      end else begin
        clk_counter <= 16'b0;
      end
    end else clk_counter <= 16'b0;
  end

  // Registrador de deslocamento
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      shift_reg <= 8'b0;
      tx_reg <= 0;
    end else if (enable_shift) begin
      tx_reg <= shift_reg[bit_counter];
    end else if (load_data) begin
      shift_reg <= data_in;
      tx_reg <= 0;
    end
  end

  // Transição de estado
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  // Próximo estado
  always @(*) begin
    next_state <= state;
    case (state)
      IDLE: begin
        if (tx_start && !tx_done) next_state <= START;
      end
      START: begin
        if (clk_counter == CLK_PER_BIT - 1) next_state <= DATA;
      end
      DATA: begin
        if ((bit_counter == 7) && (clk_counter == CLK_PER_BIT - 1)) next_state <= STOP;
      end
      STOP: begin
        if (clk_counter == CLK_PER_BIT - 1) next_state <= DONE;
      end
      DONE: next_state <= IDLE;
      default: next_state <= IDLE;
    endcase
  end

  // Lógica de controle dos sinais
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      tx_done <= 0;
      tx <= 1;
      bit_counter <= 3'b0;
      enable_counter <= 0;
      enable_shift <= 0;
      load_data <= 0;
    end else begin
      case (state)
        IDLE: begin
          tx_done <= 0;
          tx <= 1;
          bit_counter <= 3'b0;
          enable_counter <= 0;
          enable_shift <= 0;
          load_data <= 0;
        end
        START: begin
          tx <= 0;
          tx_done <= 0;
          bit_counter <= 3'b0;
          enable_counter <= 1;
          enable_shift <= 0;
          load_data <= 1;
        end
        DATA: begin
          tx <= tx_reg;
          tx_done <= 0;
          enable_counter <= 1;
          enable_shift <= 1;
          load_data <= 0;
          if (clk_counter == CLK_PER_BIT - 1)
            bit_counter <= bit_counter + 1'b1;
        end
        STOP: begin
          tx <= 1;
          tx_done <= 0;
          bit_counter <= 3'b0;
          enable_counter <= 1;
          enable_shift <= 0;
          load_data <= 0;
        end
        DONE: begin
          tx <= 1;
          tx_done <= 1;
          bit_counter <= 3'b0;
          enable_counter <= 0;
          enable_shift <= 0;
          load_data <= 0;
        end
        default: begin
          tx <= 1;
          tx_done <= 0;
          bit_counter <= 3'b0;
          enable_counter <= 0;
          enable_shift <= 0;
          load_data <= 0;
        end
      endcase
    end
  end

endmodule
