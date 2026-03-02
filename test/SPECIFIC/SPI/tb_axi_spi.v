`timescale 1ns/1ps

module tb_axi_spi;

  // ------------------------------------------------
  // CLOCK / RESET
  // ------------------------------------------------
  reg clk;
  always #5 clk = ~clk;   // 100 MHz

  reg resetn;

  // ------------------------------------------------
  // AXI-Lite
  // ------------------------------------------------
  reg  [11:0] s_axi_awaddr;
  reg         s_axi_awvalid;
  wire        s_axi_awready;

  reg  [31:0] s_axi_wdata;
  reg  [3:0]  s_axi_wstrb;
  reg         s_axi_wvalid;
  wire        s_axi_wready;

  wire [1:0]  s_axi_bresp;
  wire        s_axi_bvalid;
  reg         s_axi_bready;

  reg  [11:0] s_axi_araddr;
  reg         s_axi_arvalid;
  wire        s_axi_arready;

  wire [31:0] s_axi_rdata;
  wire [1:0]  s_axi_rresp;
  wire        s_axi_rvalid;
  reg         s_axi_rready;

  // ------------------------------------------------
  // SPI
  // ------------------------------------------------
  wire spi_sck;
  wire spi_mosi;
  reg  spi_miso;
  wire spi_cs;

  // ------------------------------------------------
  // DUT
  // ------------------------------------------------
  axi_spi dut (
    .clk(clk),
    .resetn(resetn),

    .s_axi_awaddr (s_axi_awaddr),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),

    .s_axi_wdata  (s_axi_wdata),
    .s_axi_wstrb  (s_axi_wstrb),
    .s_axi_wvalid (s_axi_wvalid),
    .s_axi_wready (s_axi_wready),

    .s_axi_bresp  (s_axi_bresp),
    .s_axi_bvalid (s_axi_bvalid),
    .s_axi_bready (s_axi_bready),

    .s_axi_araddr (s_axi_araddr),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),

    .s_axi_rdata  (s_axi_rdata),
    .s_axi_rresp  (s_axi_rresp),
    .s_axi_rvalid (s_axi_rvalid),
    .s_axi_rready (s_axi_rready),

    .spi_sck (spi_sck),
    .spi_mosi(spi_mosi),
    .spi_miso(spi_miso),
    .spi_cs  (spi_cs)
  );

  // ------------------------------------------------
  // AXI TASKS
  // ------------------------------------------------
  task axi_write;
    input [11:0] addr;
    input [31:0] data;
    begin
      @(posedge clk);
      s_axi_awaddr  = addr;
      s_axi_awvalid = 1;
      s_axi_wdata   = data;
      s_axi_wstrb   = 4'hF;
      s_axi_wvalid  = 1;
      s_axi_bready  = 1;

      while (!(s_axi_awready && s_axi_wready))
        @(posedge clk);

      s_axi_awvalid = 0;
      s_axi_wvalid  = 0;

      while (!s_axi_bvalid)
        @(posedge clk);

      s_axi_bready = 0;
    end
  endtask

  task axi_read;
    input  [11:0] addr;
    output [31:0] data;
    begin
      @(posedge clk);
      s_axi_araddr  = addr;
      s_axi_arvalid = 1;
      s_axi_rready  = 1;

      while (!s_axi_arready)
        @(posedge clk);

      s_axi_arvalid = 0;

      while (!s_axi_rvalid)
        @(posedge clk);

      data = s_axi_rdata;
      s_axi_rready = 0;
    end
  endtask

  // ------------------------------------------------
  // SPI TRANSFER TASK
  // ------------------------------------------------
  task spi_transfer;
    input  [7:0] tx;
    output [7:0] rx;
    reg [31:0] r;
    begin
      axi_write(12'h004, {24'd0, tx});   // Write TXDATA
      axi_write(12'h000, 32'h1);         // Start SPI

      // Wait busy clear
      axi_read(12'h000, r);
      while (r[1])
        axi_read(12'h000, r);

      axi_read(12'h008, r);              // Read RXDATA
      rx = r[7:0];
    end
  endtask

  // ------------------------------------------------
  // SPI SLAVE — MODE 0
  // ------------------------------------------------
  reg [7:0] slave_rx;
  reg [7:0] slave_tx;
  integer bit_idx;

  // Preload MISO no início do frame
  always @(negedge spi_cs) begin
    bit_idx  <= 7;
    slave_rx <= 8'h00;
    spi_miso <= slave_tx[7];  // garante primeiro bit válido
  end

  // Captura MOSI no posedge
  always @(posedge spi_sck) begin
    if (!spi_cs && bit_idx >= 0) begin
      slave_rx[bit_idx] <= spi_mosi;
      bit_idx <= bit_idx - 1;
    end
  end

  // Atualiza MISO no negedge
  always @(negedge spi_sck) begin
    if (!spi_cs && bit_idx >= 0)
      spi_miso <= slave_tx[bit_idx];
  end

  // Após cada frame, prepara resposta invertida
  always @(posedge spi_cs) begin
    slave_tx <= ~slave_rx;
  end

  // ------------------------------------------------
  // TEST SEQUENCE — 10 TESTES
  // ------------------------------------------------
  reg [7:0] rx;
  initial begin
    clk = 0;
    resetn = 0;

    spi_miso = 0;
    slave_tx = 8'hAA;

    s_axi_awvalid = 0;
    s_axi_wvalid  = 0;
    s_axi_bready  = 0;
    s_axi_arvalid = 0;
    s_axi_rready  = 0;

    #50;
    resetn = 1;

    // ---- Dummy transfer para descartar primeiro byte lixo ----
    spi_transfer(8'h00, rx); // IGNORADO

    // ----------------------------
    // TESTES ORIGINAIS
    // ----------------------------
    slave_tx = 8'hAA; spi_transfer(8'hA5, rx); $display("TEST 1 RX=%02X (esperado AA)", rx);
    slave_tx = 8'hAA; spi_transfer(8'h55, rx); $display("TEST 2 RX=%02X (esperado AA)", rx);
    slave_tx = 8'h5A; spi_transfer(8'h00, rx); $display("TEST 3 RX=%02X (esperado 5A)", rx);
    slave_tx = 8'h5A; spi_transfer(8'h3C, rx); $display("TEST 4 RX=%02X (esperado 5A)", rx);
    slave_tx = 8'hC3; spi_transfer(8'h00, rx); $display("TEST 5 RX=%02X (esperado C3)", rx);

    // ----------------------------
    // 5 TESTES ADICIONAIS
    // ----------------------------
    slave_tx = 8'hF0; spi_transfer(8'h0F, rx); $display("TEST 6 RX=%02X (esperado F0)", rx);
    slave_tx = 8'h0F; spi_transfer(8'hF0, rx); $display("TEST 7 RX=%02X (esperado 0F)", rx);
    slave_tx = 8'h3C; spi_transfer(8'hC3, rx); $display("TEST 8 RX=%02X (esperado 3C)", rx);
    slave_tx = 8'hA5; spi_transfer(8'h5A, rx); $display("TEST 9 RX=%02X (esperado A5)", rx);
    slave_tx = 8'h5A; spi_transfer(8'hA5, rx); $display("TEST 10 RX=%02X (esperado 5A)", rx);

    #200;
    $stop;
  end

endmodule
