module axi_spi (
    input  wire        clk,
    input  wire        resetn,

    // AXI-Lite Write Address Channel
    input  wire [11:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,

    // AXI-Lite Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,

    // AXI-Lite Write Response Channel
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    // AXI-Lite Read Address Channel
    input  wire [11:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,

    // AXI-Lite Read Data Channel
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    //-----------------------------------------
    // Registros internos (SPI stub)
    //-----------------------------------------
    reg [31:0] ctrl;
    reg [31:0] txdata;
    reg [31:0] rxdata;

    //-----------------------------------------
    // Escrita (Write Channel)
    //-----------------------------------------
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 0;
            s_axi_wready  <= 0;
            s_axi_bvalid  <= 0;
            s_axi_bresp   <= 2'b00;
            ctrl          <= 32'd0;
            txdata        <= 32'd0;
            rxdata        <= 32'd0;
        end else begin
            // Pronto para novo endereço
            if (!s_axi_awready && s_axi_awvalid)
                s_axi_awready <= 1;
            else
                s_axi_awready <= 0;

            // Pronto para novo dado
            if (!s_axi_wready && s_axi_wvalid)
                s_axi_wready <= 1;
            else
                s_axi_wready <= 0;

            // Quando endereço e dado chegam juntos
            if (s_axi_awvalid && s_axi_awready && s_axi_wvalid && s_axi_wready) begin
                case (s_axi_awaddr[5:2])   // word-aligned
                    4'h0: ctrl   <= s_axi_wdata;
                    4'h1: txdata <= s_axi_wdata;
                    default: ;
                endcase
                rxdata <= txdata; // loopback simples
                s_axi_bvalid <= 1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 0;
            end
        end
    end

    //-----------------------------------------
    // Leitura (Read Channel)
    //-----------------------------------------
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_arready <= 0;
            s_axi_rvalid  <= 0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= 32'h0;
        end else begin
            if (!s_axi_arready && s_axi_arvalid)
                s_axi_arready <= 1;
            else
                s_axi_arready <= 0;

            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1;
                s_axi_rresp  <= 2'b00; // OKAY
                case (s_axi_araddr[5:2])
                    4'h0: s_axi_rdata <= ctrl;
                    4'h1: s_axi_rdata <= txdata;
                    4'h2: s_axi_rdata <= rxdata;
                    default: s_axi_rdata <= 32'hDEADBEEF;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 0;
            end
        end
    end

endmodule
