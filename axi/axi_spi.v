module axi_spi (
    input  wire        clk,
    input  wire        resetn,

    // AXI-Lite
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

    // SPI
    output reg         spi_sck,
    output reg         spi_mosi,
    input  wire        spi_miso,
    output reg         spi_cs
);

    // ============================================================
    // REGISTRADORES INTERNOS
    // ============================================================
    reg [7:0] tx_data_reg;
    reg       tx_start_reg;
    reg       busy;
    reg       bvalid_reg;
    reg [7:0] rx_data_reg;

    // SPI shift
    reg [7:0] shift_tx, shift_rx;
    reg [2:0] bit_cnt;
    reg [7:0] clk_div;

    wire tick = (clk_div == 8'd10);

    // ============================================================
    // AXI HANDSHAKE
    // ============================================================
    assign s_axi_awready = !busy;
    assign s_axi_wready  = !busy;
    assign s_axi_bvalid  = bvalid_reg;
    assign s_axi_bresp   = 2'b00;

    assign s_axi_arready = 1'b1;
    assign s_axi_rresp   = 2'b00;
    assign s_axi_rvalid  = s_axi_arvalid;
    assign s_axi_rdata   = (s_axi_araddr[3:0] == 4'h4) ? {24'b0, rx_data_reg} :
                            (s_axi_araddr[3:0] == 4'h8) ? {30'b0, !busy} :
                            32'h00000000;

    // ============================================================
    // ESCRITA AXI
    // ============================================================
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            tx_data_reg  <= 8'b0;
            tx_start_reg <= 1'b0;
            busy         <= 1'b0;
            bvalid_reg   <= 1'b0;
        end else begin
            tx_start_reg <= 1'b0;

            // aceita escrita só se SPI estiver livre
            if (!busy &&
                s_axi_awvalid && s_axi_wvalid &&
                s_axi_awaddr[3:0] == 4'h0)  // endereço TXDATA
            begin
                tx_data_reg  <= s_axi_wdata[7:0];
                tx_start_reg <= 1'b1;
                //busy         <= 1'b1;
                bvalid_reg   <= 1'b1;
            end

            // Mestre aceitou resposta AXI
            if (bvalid_reg && s_axi_bready)
                bvalid_reg <= 1'b0;
        end
    end

    // ============================================================
    // SPI MASTER MODE 0
    // ============================================================
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            spi_cs   <= 1;
            spi_sck  <= 0;
            spi_mosi <= 0;
            busy     <= 0;
            clk_div  <= 0;
            shift_tx <= 0;
            shift_rx <= 0;
            bit_cnt  <= 0;
            rx_data_reg <= 0;
        end else begin
            // clock divider
            if (busy)
                clk_div <= clk_div + 1;
            else
                clk_div <= 0;

            // iniciar SPI
            if (tx_start_reg && !busy) begin
                busy      <= 1;
                spi_cs    <= 0;
                spi_sck   <= 0;
                shift_tx  <= tx_data_reg;
                shift_rx  <= 0;
                bit_cnt   <= 3'd7;
                spi_mosi  <= tx_data_reg[7]; // MSB primeiro
            end

            // envio de bits
            if (busy && tick) begin
                spi_sck <= ~spi_sck;

                if (!spi_sck) begin
                    // captura MISO na falling edge
                    shift_rx <= {shift_rx[6:0], spi_miso};

                    if (bit_cnt == 0) begin
                        busy       <= 0;
                        spi_cs     <= 1;
                        spi_sck    <= 0;
                        rx_data_reg <= {shift_rx[6:0], spi_miso};
                        clk_div    <= 0;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end else begin
                    // envia MOSI no rising edge
                    spi_mosi <= shift_tx[6];
                    shift_tx <= {shift_tx[6:0], 1'b0};
                end
            end
        end
    end
endmodule