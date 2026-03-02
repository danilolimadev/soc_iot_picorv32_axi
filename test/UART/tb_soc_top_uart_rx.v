`timescale 1ns/1ps

module tb_soc_top_uart_rx;

  // --------------------------------------------------------------------------
  // Clock/Reset
  // --------------------------------------------------------------------------
  reg clk;
  reg resetn;

  initial clk = 1'b0;
  always #10 clk = ~clk; // 50 MHz

  // --------------------------------------------------------------------------
  // Portas externas do SoC
  // --------------------------------------------------------------------------
  wire        uart_tx;
  reg         uart_rx;

  // --------------------------------------------------------------------------
  // Parâmetros UART (coerente com seu uart_rx.v / uart_tx.v atuais)
  // CLK_PER_BIT=20 @ 50MHz => 2.5 Mbps => 400ns/bit
  // --------------------------------------------------------------------------
  localparam integer CLK_HZ      = 50_000_000;
  localparam integer CLK_PER_BIT = 20;
  localparam real    BIT_NS      = (1.0e9 * CLK_PER_BIT) / CLK_HZ; // 400ns

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
  // Acesso interno ao RX do axi_uart (observação)
  // axi_uart.v:
  //   wire rx_done;
  //   wire [7:0] rx_data_wire;
  // --------------------------------------------------------------------------
  wire       soc_rx_done = dut.uart_inst.rx_done;
  wire [7:0] soc_rx_data = dut.uart_inst.rx_data_wire;

  // --------------------------------------------------------------------------
  // Task: injeta 1 byte na linha uart_rx (8N1, LSB first)
  // --------------------------------------------------------------------------
  task automatic uart_inject_byte(input [7:0] b);
    integer i;
    begin
      // garante idle antes
      uart_rx = 1'b1;
      #(BIT_NS);

      // start bit
      uart_rx = 1'b0;
      #(BIT_NS);

      // 8 bits LSB first
      for (i = 0; i < 8; i = i + 1) begin
        uart_rx = b[i];
        #(BIT_NS);
      end

      // stop bit
      uart_rx = 1'b1;
      #(BIT_NS);

      // gap entre bytes (1 bit-time)
      #(BIT_NS);
    end
  endtask

  // --------------------------------------------------------------------------
  // Scoreboard (fila de bytes esperados)
  // --------------------------------------------------------------------------
  reg [7:0] exp_q [0:255];
  integer exp_w, exp_r;
  integer pass, fail;

  task automatic expect_byte(input [7:0] b);
    begin
      exp_q[exp_w] = b;
      exp_w = exp_w + 1;
    end
  endtask

  // Captura do RX dentro do SoC (rx_done pulsa 1 clk)
  always @(posedge clk) begin
    if (!resetn) begin
      exp_r <= 0;
      pass  <= 0;
      fail  <= 0;
    end else begin
      if (soc_rx_done) begin
        if (exp_r < exp_w) begin
          if (soc_rx_data === exp_q[exp_r]) begin
            pass <= pass + 1;
            if (soc_rx_data >= 8'h20 && soc_rx_data <= 8'h7E)
              $display("[SOC][RX] OK  0x%02h '%c' t=%0t", soc_rx_data, soc_rx_data, $time);
            else
              $display("[SOC][RX] OK  0x%02h t=%0t", soc_rx_data, $time);
          end else begin
            fail <= fail + 1;
            $display("[SOC][RX] FAIL exp=0x%02h got=0x%02h t=%0t",
                     exp_q[exp_r], soc_rx_data, $time);
          end
          exp_r <= exp_r + 1;
        end else begin
          fail <= fail + 1;
          $display("[SOC][RX] FAIL byte inesperado got=0x%02h t=%0t", soc_rx_data, $time);
        end
      end
    end
  end

  // --------------------------------------------------------------------------
  // Sequência de teste
  // --------------------------------------------------------------------------
  initial begin
    // Se isso te gera o "GetModuleFileName..." no ModelSim/Windows, comente.
    // $dumpfile("tb_soc_uart_rx.vcd");
    // $dumpvars(0, tb_soc_uart_rx);

    // init
    resetn   = 1'b0;
    uart_rx  = 1'b1; // idle

    exp_w = 0; exp_r = 0;
    pass  = 0; fail = 0;

    // reset
    #100;
    resetn = 1'b1;
    $display("[TB] Reset liberado t=%0t | BIT_NS=%0f ns | CLK_PER_BIT=%0d", $time, BIT_NS, CLK_PER_BIT);

    // espera SoC estabilizar (CPU pode estar rodando firmware, mas aqui não depende disso)
    #5000;

    // --------- Monte a mensagem esperada e injete ----------
    // Exemplo: "CI DIGITAL"
    expect_byte("C"); uart_inject_byte("C");
    expect_byte("I"); uart_inject_byte("I");
    expect_byte(" "); uart_inject_byte(" ");
    expect_byte("D"); uart_inject_byte("D");
    expect_byte("I"); uart_inject_byte("I");
    expect_byte("G"); uart_inject_byte("G");
    expect_byte("I"); uart_inject_byte("I");
    expect_byte("T"); uart_inject_byte("T");
    expect_byte("A"); uart_inject_byte("A");
    expect_byte("L"); uart_inject_byte("L");

    // espera chegar tudo
    wait (exp_r >= exp_w);

    // resultado
    if (fail == 0) begin
      $display("[TB] PASS: UART RX SoC OK. bytes=%0d", pass);
    end else begin
      $display("[TB] FAIL: pass=%0d fail=%0d", pass, fail);
    end

    #1000;
    $finish;
  end

endmodule