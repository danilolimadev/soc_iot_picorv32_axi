module axi_spi (
    input  wire        clk,
    input  wire        resetn,

    // AXI-Lite
    input  wire [11:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,

    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,

    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire [11:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,

    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,

    // SPI
    output reg         spi_sck,
    output reg         spi_mosi,
    input  wire        spi_miso,
    output reg         spi_cs
);

    // ---------------- AXI REGISTERS ----------------
    reg        start_req;
    reg [7:0]  txdata;
    reg [7:0]  rxdata;
    reg        spi_busy;

    // ---------------- AXI WRITE ----------------
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 0;
            s_axi_wready  <= 0;
            s_axi_bvalid  <= 0;
            start_req     <= 0;
            txdata        <= 0;
        end else begin
            s_axi_awready <= s_axi_awvalid && !s_axi_bvalid;
            s_axi_wready  <= s_axi_wvalid  && !s_axi_bvalid;

            if (s_axi_awready && s_axi_wready) begin
                case (s_axi_awaddr[5:2])
                    4'h0: start_req <= s_axi_wdata[0];
                    4'h1: txdata    <= s_axi_wdata[7:0];
                endcase
                s_axi_bvalid <= 1;
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 0;
            end

            if (spi_busy)
                start_req <= 0;
        end
    end

    // ---------------- AXI READ ----------------
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_arready <= 0;
            s_axi_rvalid  <= 0;
            s_axi_rdata   <= 0;
        end else begin
            s_axi_arready <= s_axi_arvalid && !s_axi_rvalid;

            if (s_axi_arready) begin
                case (s_axi_araddr[5:2])
                    4'h0: s_axi_rdata <= {30'd0, spi_busy, start_req};
                    4'h1: s_axi_rdata <= {24'd0, txdata};
                    4'h2: s_axi_rdata <= {24'd0, rxdata};
                    default: s_axi_rdata <= 32'hDEADBEEF;
                endcase
                s_axi_rvalid <= 1;
            end

            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 0;
        end
    end

    // ---------------- SPI MASTER MODE 0 ----------------
    reg [7:0] shift_tx, shift_rx;
    reg [2:0] bit_cnt;
    reg [7:0] clk_div;

    wire tick = (clk_div == 8'd10);
    wire start_pulse = start_req && !spi_busy;

    always @(posedge clk) begin
        if (!resetn) begin
            spi_cs   <= 1;
            spi_sck  <= 0;
            spi_mosi <= 0;
            spi_busy <= 0;
            clk_div  <= 0;
            rxdata   <= 0;
        end else begin
            clk_div <= spi_busy ? clk_div + 1 : 0;

            // START
            if (start_pulse) begin
                spi_busy <= 1;
                spi_cs   <= 0;
                spi_sck  <= 0;
                bit_cnt <= 3'd7;
                shift_tx <= txdata;
                shift_rx <= 0;
                spi_mosi <= txdata[7];
            end

            if (spi_busy && tick) begin
                spi_sck <= ~spi_sck;

                if (!spi_sck) begin
                    // rising edge → sample
                    shift_rx <= {shift_rx[6:0], spi_miso};

                    if (bit_cnt == 0) begin
                        spi_busy <= 0;
                        spi_cs   <= 1;
                        spi_sck  <= 0;
                        rxdata   <= {shift_rx[6:0], spi_miso};
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end else begin
                    // falling edge → shift + drive
                    shift_tx <= {shift_tx[6:0], 1'b0};
                    spi_mosi <= shift_tx[6];
                end
            end
        end
    end

endmodule
