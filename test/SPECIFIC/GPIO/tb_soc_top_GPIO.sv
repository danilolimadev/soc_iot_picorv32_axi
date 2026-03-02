// ============================================================================
// tb_soc_top.sv — TB “auditável” (Transcript + Wave Markers) e resiliente
// - Compatível com ModelSim Intel FPGA Edition 2020.1
// - NÃO depende de hierarquia interna do soc_top (sem uut.interconnect.*)
// - Usa BIND para:
//     * axi_gpio  -> expor gpio_out
//     * axi_timer -> expor irq_out
//     * axi_interconnect -> expor handshake AXI do caminho do GPIO (AW/W/B)
// - Transcript mostra claramente cada etapa (OK/FAIL) + handshakes AXI
// - Wave markers (pulsos) para STEP1/STEP2/PASS/FAIL
//
// Compile:
//   vlog -sv -work work C:/Projetos/SoC_TESTES/tb_soc_top.sv
// Run:
//   vsim -voptargs=+acc work.soc_tb
//   onbreak {resume}
//   run -all
// ============================================================================

`timescale 1ns/1ps

// Habilite conforme firmware.hex carregado
`define TEST_GPIO_SEQ  1

// ============================================================================
// MONITORES (DEVEM existir como design units ANTES do BIND)
// ============================================================================

// 1) Captura gpio_out dentro do axi_gpio
module tb_gpio_mon(
  input  logic        clk,
  input  logic        resetn,
  input  logic [31:0] gpio_out
);
  always_ff @(posedge clk) begin
    if (!resetn) soc_tb.mon_gpio_out <= 32'h0;
    else         soc_tb.mon_gpio_out <= gpio_out;
  end
endmodule

// 2) Captura irq_out dentro do axi_timer
module tb_timer_mon(
  input  logic clk,
  input  logic resetn,
  input  logic irq_out
);
  always_ff @(posedge clk) begin
    if (!resetn) soc_tb.mon_timer_irq <= 1'b0;
    else         soc_tb.mon_timer_irq <= irq_out;
  end
endmodule

// 3) Captura o “caminho AXI do GPIO” dentro do axi_interconnect
//    Observação: tipos/widths devem bater com o axi_interconnect.v do seu projeto.
//    Se gpio_awaddr / gpio_araddr forem [11:0], deixamos [11:0] aqui.
module tb_axi_gpio_bus_mon (
  input  logic        clk,
  input  logic        resetn,

  input  logic        gpio_awvalid,
  input  logic        gpio_awready,
  input  logic [11:0] gpio_awaddr,

  input  logic        gpio_wvalid,
  input  logic        gpio_wready,
  input  logic [31:0] gpio_wdata,
  input  logic [3:0]  gpio_wstrb,

  input  logic        gpio_bvalid,
  input  logic        gpio_bready,
  input  logic [1:0]  gpio_bresp
);
  always_ff @(posedge clk) begin
    if (!resetn) begin
      soc_tb.mon_gpio_awvalid <= 1'b0;
      soc_tb.mon_gpio_awready <= 1'b0;
      soc_tb.mon_gpio_awaddr  <= 12'h0;

      soc_tb.mon_gpio_wvalid  <= 1'b0;
      soc_tb.mon_gpio_wready  <= 1'b0;
      soc_tb.mon_gpio_wdata   <= 32'h0;
      soc_tb.mon_gpio_wstrb   <= 4'h0;

      soc_tb.mon_gpio_bvalid  <= 1'b0;
      soc_tb.mon_gpio_bready  <= 1'b0;
      soc_tb.mon_gpio_bresp   <= 2'b00;
    end else begin
      soc_tb.mon_gpio_awvalid <= gpio_awvalid;
      soc_tb.mon_gpio_awready <= gpio_awready;
      soc_tb.mon_gpio_awaddr  <= gpio_awaddr;

      soc_tb.mon_gpio_wvalid  <= gpio_wvalid;
      soc_tb.mon_gpio_wready  <= gpio_wready;
      soc_tb.mon_gpio_wdata   <= gpio_wdata;
      soc_tb.mon_gpio_wstrb   <= gpio_wstrb;

      soc_tb.mon_gpio_bvalid  <= gpio_bvalid;
      soc_tb.mon_gpio_bready  <= gpio_bready;
      soc_tb.mon_gpio_bresp   <= gpio_bresp;
    end
  end
endmodule


// ============================================================================
// TESTBENCH TOP
// ============================================================================
module soc_tb;

  // ===============================
  // Clock / Reset
  // ===============================
  logic clk;
  logic resetn;

  localparam time CLK_HALF = 10ns; // 50 MHz

  initial begin
    clk = 1'b0;
    forever #CLK_HALF clk = ~clk;
  end

  initial begin
    resetn = 1'b0;
    #200ns;
    resetn = 1'b1;
  end

  // ===============================
  // SoC IOs
  // ===============================
  wire  uart_tx;
  logic uart_rx;

  wire  spi_sck, spi_mosi, spi_cs;
  wire  spi_miso;

  wire  i2c_sda, i2c_scl;

  initial uart_rx = 1'b1;   // UART idle
  assign  spi_miso = 1'b0;  // stub slave

  pullup(i2c_sda);
  pullup(i2c_scl);

  // ===============================
  // DUT
  // ===============================
  soc_top uut (
    .clk     (clk),
    .resetn  (resetn),

    .uart_tx (uart_tx),
    .uart_rx (uart_rx),

    .spi_mosi(spi_mosi),
    .spi_miso(spi_miso),
    .spi_sck (spi_sck),
    .spi_cs  (spi_cs),

    .i2c_sda (i2c_sda),
    .i2c_scl (i2c_scl)
  );

  // ===========================================================================
  // Published monitor signals (capturados via bind)
  // ===========================================================================
  logic [31:0] mon_gpio_out;
  logic        mon_timer_irq;

  // AXI GPIO path (capturado via bind no axi_interconnect)
  logic        mon_gpio_awvalid, mon_gpio_awready;
  logic [11:0] mon_gpio_awaddr;

  logic        mon_gpio_wvalid,  mon_gpio_wready;
  logic [31:0] mon_gpio_wdata;
  logic [3:0]  mon_gpio_wstrb;

  logic        mon_gpio_bvalid,  mon_gpio_bready;
  logic [1:0]  mon_gpio_bresp;

  // ===========================================================================
  // Result flags
  // ===========================================================================
  bit pass_gpio, fail_gpio;

  initial begin
    pass_gpio = 0;
    fail_gpio = 0;
  end

  // ===========================================================================
  // BINDs — sem depender de hierarquia do soc_top
  // ===========================================================================
  bind axi_gpio  tb_gpio_mon  u_tb_gpio_mon  (.clk(clk), .resetn(resetn), .gpio_out(gpio_out));
  bind axi_timer tb_timer_mon u_tb_timer_mon (.clk(clk), .resetn(resetn), .irq_out(irq_out));

  bind axi_interconnect tb_axi_gpio_bus_mon u_tb_axi_gpio_bus_mon (
    .clk        (soc_tb.clk),
    .resetn     (soc_tb.resetn),

    .gpio_awvalid(gpio_awvalid),
    .gpio_awready(gpio_awready),
    .gpio_awaddr (gpio_awaddr),

    .gpio_wvalid (gpio_wvalid),
    .gpio_wready (gpio_wready),
    .gpio_wdata  (gpio_wdata),
    .gpio_wstrb  (gpio_wstrb),

    .gpio_bvalid (gpio_bvalid),
    .gpio_bready (gpio_bready),
    .gpio_bresp  (gpio_bresp)
  );

  // ===========================================================================
  // Wave Markers (pulsos de evento)
  // ===========================================================================
  logic ev_gpio_step_a5_ok;
  logic ev_gpio_step_ff_ok;
  logic ev_test_pass;
  logic ev_test_fail;

  initial begin
    ev_gpio_step_a5_ok = 1'b0;
    ev_gpio_step_ff_ok = 1'b0;
    ev_test_pass       = 1'b0;
    ev_test_fail       = 1'b0;
  end

  // IMPORTANT: usar ref + blocking "=" (ModelSim 2020.1 não aceita "<=" em output automatic)
  task automatic pulse_event(ref logic ev);
    ev = 1'b1;
    @(posedge clk);
    ev = 1'b0;
  endtask

  // ===========================================================================
  // Logging padronizado
  // ===========================================================================
  task automatic log_info(input string testid, input string msg);
    $display("[%0t] [%s] [INFO] %s", $time, testid, msg);
  endtask

  task automatic log_ok(input string testid, input string step, input string msg);
    $display("[%0t] [%s] [%s] [OK] %s", $time, testid, step, msg);
  endtask

  task automatic log_fail(input string testid, input string step, input string msg);
    $display("[%0t] [%s] [%s] [FAIL] %s", $time, testid, step, msg);
  endtask

  // ===========================================================================
  // UART monitor (opcional) — mantém capturas, mas não imprime por default
  // ===========================================================================
  byte uart_bytes[$];
  localparam time UART_BIT = 400ns; // CLK_PER_BIT=20 @50MHz

  task automatic uart_rx_byte(output byte b, output bit ok_frame);
    int i;
    bit [9:0] sh;
    ok_frame = 1'b0;
    sh = '1;

    @(negedge uart_tx);
    #(UART_BIT/2);

    for (i = 0; i < 10; i++) begin
      sh[i] = uart_tx;
      #(UART_BIT);
    end

    if (sh[0] == 1'b0 && sh[9] == 1'b1) begin
      b = sh[8:1];
      ok_frame = 1'b1;
    end
  endtask

  initial begin : UART_MON
    byte b;
    bit ok;
    wait(resetn);
    $display("\n=== Simulacao Iniciada ===\n");
    forever begin
      uart_rx_byte(b, ok);
      if (ok) uart_bytes.push_back(b);
    end
  end

  // ===========================================================================
  // Transcript: monitoramento “útil” (AXI + GPIO + eventos)
  // ===========================================================================
  logic [31:0] last_gpio;

  initial begin
    last_gpio = 32'h0;
    wait(resetn);
    $display("\n==================== MONITOR START ====================\n");
  end

  // Log de mudança do GPIO observado
  always @(posedge clk) begin
    if (!resetn) begin
      last_gpio <= 32'h0;
    end else if (mon_gpio_out !== last_gpio) begin
      $display("[%0t] [GPIO_MON] gpio_out = 0x%08h", $time, mon_gpio_out);
      last_gpio <= mon_gpio_out;
    end
  end

  // Log do handshake AXI (caminho do GPIO)
  always @(posedge clk) begin
    if (resetn) begin
      if (mon_gpio_awvalid && mon_gpio_awready)
        $display("[%0t] [AXI][GPIO] AW  addr=0x%03h", $time, mon_gpio_awaddr);

      if (mon_gpio_wvalid && mon_gpio_wready)
        $display("[%0t] [AXI][GPIO] W   data=0x%08h wstrb=0x%1h", $time, mon_gpio_wdata, mon_gpio_wstrb);

      if (mon_gpio_bvalid && mon_gpio_bready)
        $display("[%0t] [AXI][GPIO] B   resp=0x%0h (OK=00)", $time, mon_gpio_bresp);
    end
  end

  // Log dos event markers
  always @(posedge clk) begin
    if (ev_gpio_step_a5_ok) $display("[%0t] [EVENT] STEP1_OK (A5A5A5A5)", $time);
    if (ev_gpio_step_ff_ok) $display("[%0t] [EVENT] STEP2_OK (FFFFFFFF)", $time);
    if (ev_test_pass)       $display("[%0t] [EVENT] >>> TEST PASS <<<", $time);
    if (ev_test_fail)       $display("[%0t] [EVENT] >>> TEST FAIL <<<", $time);
  end

  // ===========================================================================
  // Watchdog global
  // ===========================================================================
  localparam time GLOBAL_TIMEOUT = 5ms;

  initial begin : GLOBAL_WD
    wait(resetn);
    #GLOBAL_TIMEOUT;

    log_fail("GLOBAL", "TIMEOUT",
             $sformatf("Timeout global %0t. GPIO=0x%08h", GLOBAL_TIMEOUT, mon_gpio_out));
    fail_gpio = 1;
    pulse_event(ev_test_fail);
    report_and_finish();
  end

  // ===========================================================================
  // TESTE: GPIO sequence (fw_gpio)
  // Esperado: A5A5A5A5 -> FFFFFFFF
  // ===========================================================================
`ifdef TEST_GPIO_SEQ
  initial begin : TEST_GPIO
    string T;
    T = "TEST_GPIO";

    wait(resetn);
    log_info(T, "Inicio: aguardando GPIO_OUT A5A5A5A5 -> FFFFFFFF");

    fork
      begin : GPIO_TIMEOUT
        #2ms;
        log_fail(T, "TIMEOUT", $sformatf("Nao observou sequencia. GPIO atual=0x%08h", mon_gpio_out));
        fail_gpio = 1;
        pulse_event(ev_test_fail);
        report_and_finish();
      end

      begin : GPIO_SEQ
        wait(mon_gpio_out == 32'hA5A5A5A5);
        log_ok(T, "STEP1", "GPIO_OUT atingiu 0xA5A5A5A5");
        pulse_event(ev_gpio_step_a5_ok);

        wait(mon_gpio_out == 32'hFFFFFFFF);
        log_ok(T, "STEP2", "GPIO_OUT atingiu 0xFFFFFFFF");
        pulse_event(ev_gpio_step_ff_ok);

        pass_gpio = 1;
        pulse_event(ev_test_pass);
        log_ok(T, "RESULT", "PASS");
        report_and_finish();
      end
    join_any

    disable fork;
  end
`endif

  // ===========================================================================
  // Report e encerramento
  // ===========================================================================
  task automatic report_and_finish();
    int total, passed, failed;

    total  = 1;
    passed = (pass_gpio && !fail_gpio) ? 1 : 0;
    failed = (pass_gpio && !fail_gpio) ? 0 : 1;

    $display("\n==================== TEST SUMMARY ====================");
    if (pass_gpio && !fail_gpio) $display("TEST_GPIO : PASS");
    else                         $display("TEST_GPIO : FAIL");
    $display("------------------------------------------------------");
    $display("TOTAL=%0d  PASS=%0d  FAIL=%0d", total, passed, failed);
    $display("======================================================\n");

    if (failed == 0) begin
      $display("[TB] RESULT: ALL TESTS PASSED.");
      $finish;
    end else begin
      $display("[TB] RESULT: TESTS FAILED.");
      $fatal(1);
    end
  endtask

  // ===========================================================================
  // VCD (opcional)
  // ===========================================================================
  initial begin
    $dumpfile("soc_tb.vcd");
    $dumpvars(0, soc_tb);
  end

endmodule
