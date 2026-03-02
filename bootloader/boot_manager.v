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
    output wire        cpu_resetn,
    output reg         done
);

  wire rom_done;

  wire uart_rom_receiver_resetn = resetn & boot_mode; // Reseta o receiver quando não estiver no modo boot
  
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
      done       <= 0;
    end else begin

      boot_we <= 0;

      case (copy_state)

        COPY_IDLE: begin
          copy_index <= 0;

          if (!boot_mode)
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
          done <= 1;
        end

      endcase
    end
  end

  assign cpu_resetn = resetn & (copy_state == COPY_DONE);

endmodule
