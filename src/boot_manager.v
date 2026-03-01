/*
`timescale 1ns/1ps

module boot_manager #(
    parameter MEM_WORDS = 256
)(
    input  wire        clk,
    input  wire        resetn,
    input  wire        boot_mode,
    input  wire        uart_rx,
    input  wire [31:0] firmware_size,

    output reg         boot_we,
    output reg [31:0]  boot_addr,
    output reg [31:0]  boot_wdata,
    output wire        cpu_resetn
);

  wire rom_done;

  uart_rom_receiver #(
      .CLK_FREQ(50_000_000),
      .BAUD_RATE(115200),
      .MEM_WORDS(MEM_WORDS)
  ) rom_receiver_inst (
      .clk(clk),
      .resetn(resetn),
      .uart_rx(uart_rx),
      .firmware_size(firmware_size),
      .done(rom_done)
  );

  // Acesso hierárquico (porque seu receiver não expõe porta de leitura)
  wire [31:0] rom_rdata;
  reg  [31:0] copy_index;

  assign rom_rdata = rom_receiver_inst.rom_mem[copy_index];

  // FSM
  localparam COPY_IDLE = 0;
  localparam COPY_RUN  = 1;
  localparam COPY_DONE = 2;

  reg [1:0] copy_state;

  always @(posedge clk) begin
    if (!resetn) begin
      copy_state <= COPY_IDLE;
      copy_index <= 0;
      boot_we    <= 0;
    end else begin

      boot_we <= 0;

      case (copy_state)

        COPY_IDLE: begin
          copy_index <= 0;

          if (!boot_mode && rom_done)
            copy_state <= COPY_RUN;
        end

        COPY_RUN: begin
          boot_we    <= 1;
          boot_addr  <= copy_index << 2;
          boot_wdata <= rom_rdata;

          if (copy_index == MEM_WORDS-1)
            copy_state <= COPY_DONE;
          else
            copy_index <= copy_index + 1;
        end

        COPY_DONE: begin
          boot_we <= 0;
        end

      endcase
    end
  end

  assign cpu_resetn = resetn & (copy_state == COPY_DONE);

endmodule
*/
`timescale 1ns/1ps

module boot_manager #(
    parameter MEM_WORDS = 256
)(
    input  wire        clk,
    input  wire        resetn,
    input  wire        boot_mode,
    input  wire        uart_rx,
    input  wire [31:0] firmware_size,

    output reg         boot_we,
    output reg [31:0]  boot_addr,
    output reg [31:0]  boot_wdata,
    output wire        cpu_resetn
);

  wire rom_done;
  wire [31:0] rom_rdata;
  reg  [31:0] copy_index;

  // Instanciação corrigida: conectando as novas portas de leitura
  uart_rom_receiver #(
      .CLK_FREQ(50_000_000),
      .BAUD_RATE(115200),
      .MEM_WORDS(MEM_WORDS)
  ) rom_receiver_inst (
      .clk(clk),
      .resetn(resetn),
      .uart_rx(uart_rx),
      .firmware_size(firmware_size),
      .done(rom_done),
      .rd_addr(copy_index), // Saída do boot_manager entra no receiver
      .rd_data(rom_rdata)   // Dado da memória do receiver volta para cá
  );

  // FSM States
  localparam COPY_IDLE = 2'd0;
  localparam COPY_RUN  = 2'd1;
  localparam COPY_DONE = 2'd2;

  reg [1:0] copy_state;

  always @(posedge clk) begin
    if (!resetn) begin
      copy_state <= COPY_IDLE;
      copy_index <= 0;
      boot_we    <= 0;
      boot_addr  <= 0;
      boot_wdata <= 0;
    end else begin
      // Padrão: escrita desativada
      boot_we <= 0;

      case (copy_state)
        COPY_IDLE: begin
          copy_index <= 0;
          // Inicia a cópia apenas se o modo boot estiver off e a UART terminou de receber
          if (!boot_mode && rom_done)
            copy_state <= COPY_RUN;
        end

        COPY_RUN: begin
          boot_we    <= 1'b1;
          boot_addr  <= copy_index << 2; // Endereçamento por byte para a RAM AXI
          boot_wdata <= rom_rdata;

          if (copy_index >= (MEM_WORDS - 1)) begin
            copy_state <= COPY_DONE;
          end else begin
            copy_index <= copy_index + 1;
          end
        end

        COPY_DONE: begin
          boot_we    <= 1'b0;
          copy_state <= COPY_DONE; // Aguarda reset do sistema
        end

        default: copy_state <= COPY_IDLE;
      endcase
    end
  end

  // A CPU só sai do reset após a conclusão da cópia do Firmware da ROM para a RAM
  assign cpu_resetn = resetn & (copy_state == COPY_DONE);

endmodule
