/* verilator lint_off UNUSEDSIGNAL */
`timescale 1 ns / 1 ps

module axi_spi (
    input  wire        clk,
    input  wire        resetn,

    // AXI4-Lite Interface
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

    // SPI Interface
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

    reg [7:0] shift_tx, shift_rx;
    reg [2:0] bit_cnt;
    reg [7:0] clk_div;

    // Tick para controle de tempo da SPI
    wire tick = (clk_div == 8'd10);

    // ============================================================
    // AXI HANDSHAKE (Combinacional)
    // ============================================================
    assign s_axi_awready = !busy && !bvalid_reg;
    assign s_axi_wready  = !busy && !bvalid_reg;
    assign s_axi_bvalid  = bvalid_reg;
    assign s_axi_bresp   = 2'b00;

    assign s_axi_arready = 1'b1;
    assign s_axi_rresp   = 2'b00;
    assign s_axi_rvalid  = s_axi_arvalid; 

    // CORREÇÃO DO ERRO WIDTHEXPAND: Agora somando 31 bits de zero + 1 bit de dado = 32 bits
    assign s_axi_rdata = (s_axi_araddr[3:0] == 4'h4) ? {24'b0, rx_data_reg} :
                         (s_axi_araddr[3:0] == 4'h8) ? {31'b0, busy}        : // Corrigido aqui
                         32'h00000000;

    // ============================================================
    // LÓGICA DE CONTROLE (Single Always Block para evitar conflitos)
    // ============================================================
    always @(posedge clk) begin
        if (!resetn) begin
            tx_data_reg  <= 8'b0;
            tx_start_reg <= 1'b0;
            bvalid_reg   <= 1'b0;
            busy         <= 1'b0;
            spi_cs       <= 1'b1;
            spi_sck      <= 1'b0;
            spi_mosi     <= 1'b0;
            clk_div      <= 8'd0;
            shift_tx     <= 8'd0;
            shift_rx     <= 8'd0;
            bit_cnt      <= 3'd0;
            rx_data_reg  <= 8'd0;
        end else begin
            
            // --- Gestão de Escrita AXI ---
            if (!busy && s_axi_awvalid && s_axi_wvalid && !bvalid_reg) begin
                if (s_axi_awaddr[3:0] == 4'h0) begin
                    tx_data_reg  <= s_axi_wdata[7:0];
                    tx_start_reg <= 1'b1;
                end
                bvalid_reg <= 1'b1;
            end

            if (bvalid_reg && s_axi_bready) begin
                bvalid_reg <= 1'b0;
            end

            // --- Máquina de Estados SPI ---
            if (!busy) begin
                if (tx_start_reg) begin
                    busy         <= 1'b1;
                    tx_start_reg <= 1'b0;
                    spi_cs       <= 1'b0;
                    spi_sck      <= 1'b0;
                    shift_tx     <= tx_data_reg;
                    bit_cnt      <= 3'd7;
                    spi_mosi     <= tx_data_reg[7];
                    clk_div      <= 8'd0;
                end
            end else begin
                clk_div <= clk_div + 8'd1;
                
                if (tick) begin
                    clk_div <= 8'd0;
                    spi_sck <= ~spi_sck;

                    if (spi_sck) begin // Falling Edge (SPI Mode 0: captura no falling edge se SCK iniciou em 0)
                        shift_rx <= {shift_rx[6:0], spi_miso};
                        
                        if (bit_cnt == 3'd0) begin
                            busy        <= 1'b0;
                            spi_cs      <= 1'b1;
                            spi_sck     <= 1'b0;
                            rx_data_reg <= {shift_rx[6:0], spi_miso};
                        end else begin
                            bit_cnt <= bit_cnt - 3'd1;
                        end
                    end else begin // Rising Edge
                        // Shift e prepara próximo bit MOSI
                        // Como já enviamos o bit 7 no START, fazemos o shift aqui para o bit 6
                        spi_mosi <= shift_tx[6];
                        shift_tx <= {shift_tx[6:0], 1'b0};
                    end
                end
            end
        end
    end

endmodule
