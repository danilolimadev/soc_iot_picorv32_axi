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

  // Registradores internos
  reg [7:0] tx_data_reg;
  reg       tx_start_reg;
  reg       busy;
  reg       bvalid_reg;
  wire      tx_done;
  wire      rx_done;
  wire [7:0] rx_data_wire;

  // UART instâncias
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

  // AXI handshake simples
  assign s_axi_awready = !busy;
  assign s_axi_wready  = !busy;
  assign s_axi_bvalid  = bvalid_reg;
  assign s_axi_bresp   = 2'b00;

  assign s_axi_arready = 1'b1;
  assign s_axi_rresp   = 2'b00;
  assign s_axi_rvalid  = s_axi_arvalid;

  // Escrita: endereço 0x000 = TX_DATA
  always @(posedge clk or negedge resetn)
  begin
    if (!resetn)
    begin
      tx_data_reg  <= 8'b0;
      tx_start_reg <= 1'b0;
      busy         <= 1'b0;
      bvalid_reg   <= 1'b0;
    end
    else
    begin
      tx_start_reg <= 1'b0;

      // Aceita escrita só se UART estiver livre
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

      // Mestre aceitou resposta AXI
      if (bvalid_reg && s_axi_bready)
      begin
        bvalid_reg <= 1'b0;
      end

      // UART terminou transmissão
      if (busy && tx_done)
      begin
        busy <= 1'b0;
      end
    end
  end


  // Leitura: endereço 0x004 = RX_DATA, 0x008 = STATUS
  assign s_axi_rdata = (s_axi_araddr[3:0] == 4'h4) ? {24'b0, rx_data_wire} :
         (s_axi_araddr[3:0] == 4'h8) ? {30'b0, rx_done, !busy} :
         32'h00000000;

endmodule
