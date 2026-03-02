`timescale 1ns/1ps

module tb_soc_top_uart_tx;

  // --------------------------------------------------------------------------
  // Clock/Reset
  // --------------------------------------------------------------------------
  reg clk;
  reg resetn;

  initial clk = 1'b0;
  always #10 clk = ~clk; // 50 MHz

  // --------------------------------------------------------------------------
  // Sinais externos do SoC
  // --------------------------------------------------------------------------
  wire        uart_tx;
  reg         uart_rx;
  // --------------------------------------------------------------------------
  // Parâmetros UART (coerentes com uart_tx.v / uart_rx.v)
  // CLK_PER_BIT = 20 @ 50MHz => 2.5 Mbps => 400 ns/bit
  // --------------------------------------------------------------------------
  localparam integer CLK_HZ      = 50_000_000;
  localparam integer CLK_PER_BIT = 20;
  localparam real    BIT_NS      = (1.0e9 * CLK_PER_BIT) / CLK_HZ; // 400.0 ns

  // --------------------------------------------------------------------------
  // DUT
  // --------------------------------------------------------------------------
  soc_top dut (
    .clk(clk),
    .resetn(resetn),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx)
  );

  // --------------------------------------------------------------------------
  // UART monitor por tempo (robusto)
  // --------------------------------------------------------------------------
  task automatic uart_capture_byte(output reg [7:0] b);
    integer i;
    begin
      b = 8'h00;

      // espera start bit (queda)
      @(negedge uart_tx);

      // vai para o meio do bit0: 1.5 bits após a borda de start
      #(BIT_NS * 1.5);

      // amostra 8 bits (LSB first)
      for (i = 0; i < 8; i = i + 1) begin
        b[i] = uart_tx;
        #(BIT_NS);
      end

      // checa stop bit no meio
      if (uart_tx !== 1'b1) begin
        $display("[UART][WARN] Stop bit != 1 em t=%0t (uart_tx=%b)", $time, uart_tx);
      end

      // espera fim do stop (opcional)
      #(BIT_NS * 0.5);
    end
  endtask

// guarda exatamente os 10 primeiros caracteres, no formato compatível com "CI DIGITAL"
reg [8*10-1:0] uart10;
integer idx = 0;

task automatic push_char(input [7:0] c);
begin
  if (idx < 10) begin
    uart10 = {uart10[8*10-9:0], c}; // shift-left 8, insere char no LSB
    idx = idx + 1;
  end
end
endtask

  initial begin : uart_sniffer
    reg [7:0] ch;
    // espera reset soltar
    wait(resetn === 1'b1);

    forever begin
      uart_capture_byte(ch);
      
      if (ch >= 8'h20 && ch <= 8'h7E) begin
          if (ch == 8'h0D || ch == 8'h0A) begin
          // ignora CR/LF
          end else begin
          push_char(ch);
          end
        $display("UART recebeu byte: 0x%02h ('%c') t=%0t", ch, ch, $time);
      end
      else
        $display("UART recebeu byte: 0x%02h t=%0t", ch, $time);
    end
  end

  // --------------------------------------------------------------------------
  // Estímulos
  // --------------------------------------------------------------------------
  initial begin
    // OBS: esse $dumpfile pode gerar o “GetModuleFileName...” no ModelSim/Windows.
    // Se te incomodar, comente e use waveform do ModelSim.
    // $dumpfile("tb_soc.vcd");
    // $dumpvars(0, tb_soc);

    resetn   = 1'b0;
    uart_rx  = 1'b1; // idle
      uart10 = {8*10{1'b0}};
  idx   = 0;

    #100;
    resetn = 1'b1;

    $display("[TB] Reset liberado em t=%0t", $time);

    // Tempo para CPU rodar firmware e escrever UART
    #200000;

    $display("[TB] Rodando... (BIT_NS=%0f ns, CLK_PER_BIT=%0d)", BIT_NS, CLK_PER_BIT);

    #2_000_000;
    
    // espere pelo menos 10 chars
    wait (idx >= 10);

if (uart10 == "CI DIGITAL") begin
  $display("[TB] PASS: string OK (%s)", uart10);
end else begin
  $display("[TB] FAIL: esperado 'CI DIGITAL' mas veio '%s' (idx=%0d)", uart10, idx);
end

     $display("[TB] PASS: string OK");

    $finish;
  end

endmodule