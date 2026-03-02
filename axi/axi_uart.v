module axi_uart (
    input  wire        clk,
    input  wire        resetn,

    // AXI-Lite interface
    input  wire [11:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire [11:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,

    // UART interface
    output wire        tx,
    input  wire        rx
);

  // =========================================================
  // REGISTRADORES INTERNOS
  // =========================================================

  reg [7:0] tx_data_reg;
  reg       tx_start_reg;
  reg       busy;

  reg       bvalid_reg;
  reg       rvalid_reg;

  reg [7:0] rx_data_reg;
  reg       rx_valid_reg;

  wire      tx_done;
  wire      rx_done;
  wire [7:0] rx_data_wire;

  // =========================================================
  // INSTÂNCIAS UART
  // =========================================================

  uart_tx uart_tx_inst (
      .clk(clk),
      .reset(~resetn),
      .data_in(tx_data_reg),
      .tx_start(tx_start_reg),
      .tx(tx),
      .tx_done(tx_done)
  );

  uart_rx uart_rx_inst (
      .clk(clk),
      .reset(~resetn),
      .rx(rx),
      .data_out(rx_data_wire),
      .rx_done(rx_done)
  );

  // =========================================================
  // AXI WRITE CHANNEL (TX)
  // Endereço 0x000 = TX_DATA
  // =========================================================

  assign s_axi_awready = !busy;
  assign s_axi_wready  = !busy;
  assign s_axi_bvalid  = bvalid_reg;
  assign s_axi_bresp   = 2'b00; // OKAY

  always @(posedge clk or negedge resetn)
  begin
    if (!resetn)
    begin
      tx_data_reg  <= 8'd0;
      tx_start_reg <= 1'b0;
      busy         <= 1'b0;
      bvalid_reg   <= 1'b0;
    end
    else
    begin
      tx_start_reg <= 1'b0;

      // Escrita TXDATA
      if (!busy &&
          s_axi_awvalid &&
          s_axi_wvalid &&
          s_axi_awaddr[3:0] == 4'h0)
      begin
          tx_data_reg  <= s_axi_wdata[7:0];
          tx_start_reg <= 1'b1;
          busy         <= 1'b1;
          bvalid_reg   <= 1'b1;
      end

      // Mestre aceitou resposta
      if (bvalid_reg && s_axi_bready)
          bvalid_reg <= 1'b0;

      // Transmissão terminou
      if (busy && tx_done)
          busy <= 1'b0;
    end
  end

  // =========================================================
  // RX LÓGICA (FLAG LATCHED)
  // =========================================================

  always @(posedge clk or negedge resetn)
  begin
    if (!resetn)
    begin
        rx_valid_reg <= 1'b0;
        rx_data_reg  <= 8'd0;
    end
    else
    begin
        // Quando um byte chega
        if (rx_done)
        begin
            rx_data_reg  <= rx_data_wire;
            rx_valid_reg <= 1'b1;
        end

        // Limpa quando CPU lê RXDATA (0x4)
        if (s_axi_arvalid &&
            s_axi_araddr[3:0] == 4'h4 &&
            s_axi_rready)
        begin
            rx_valid_reg <= 1'b0;
        end
    end
  end

  // =========================================================
  // AXI READ CHANNEL
  // 0x004 = RX_DATA
  // 0x008 = STATUS
  // =========================================================

  assign s_axi_arready = 1'b1;
  assign s_axi_rresp   = 2'b00; // OKAY
  assign s_axi_rvalid  = rvalid_reg;

  always @(posedge clk or negedge resetn)
  begin
    if (!resetn)
        rvalid_reg <= 1'b0;
    else
    begin
        if (s_axi_arvalid)
            rvalid_reg <= 1'b1;
        else if (rvalid_reg && s_axi_rready)
            rvalid_reg <= 1'b0;
    end
  end

  assign s_axi_rdata =
        (s_axi_araddr[3:0] == 4'h4) ? {24'd0, rx_data_reg} :
        (s_axi_araddr[3:0] == 4'h8) ? {30'd0, rx_valid_reg, !busy} :
        32'h00000000;

endmodule