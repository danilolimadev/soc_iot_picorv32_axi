/* verilator lint_off UNUSEDSIGNAL */
`timescale 1 ns / 1 ps

module axi_ram #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
)(
    input  wire                      clk,
    input  wire                      resetn,

    // Boot write port
    input  wire                      boot_we,
    input  wire [31:0]               boot_addr,
    input  wire [DATA_WIDTH-1:0]     boot_wdata,

    // AXI Write Address Channel
    input  wire [31:0]               s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,

    // AXI Write Data Channel
    input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,

    // AXI Write Response Channel
    output reg [1:0]                 s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,

    // AXI Read Address Channel
    input  wire [31:0]               s_axi_araddr,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,

    // AXI Read Data Channel
    output reg [DATA_WIDTH-1:0]      s_axi_rdata,
    output reg [1:0]                 s_axi_rresp,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready
);

    localparam MEM_WORDS = (1 << ADDR_WIDTH) / 4;
    reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];
    
    // Máscara para endereçamento seguro
    wire [ADDR_WIDTH-3:0] boot_idx = boot_addr[ADDR_WIDTH-1:2];
    wire [ADDR_WIDTH-3:0] aw_idx   = s_axi_awaddr[ADDR_WIDTH-1:2];
    wire [ADDR_WIDTH-3:0] ar_idx   = s_axi_araddr[ADDR_WIDTH-1:2];

    integer i;

    // =====================================
    // LÓGICA DE ESCRITA
    // =====================================
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
        end else begin
            // Escrita Física
            if (boot_we) begin
                mem[boot_idx] <= boot_wdata;
            end else if (s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid) begin
                for (i=0; i < (DATA_WIDTH/8); i=i+1) begin
                    if (s_axi_wstrb[i]) begin
                        mem[aw_idx][8*i +: 8] <= s_axi_wdata[8*i +: 8];
                    end
                end
            end

            // Handshake AXI Write
            if (!s_axi_awready && s_axi_awvalid && s_axi_wvalid && !boot_we) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            // Resposta B
            if (s_axi_awready && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // =====================================
    // LÓGICA DE LEITURA
    // =====================================
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= 32'b0;
        end else begin
            // Handshake AR
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            // Canal R
            if (s_axi_arready && s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rdata  <= mem[ar_idx];
                s_axi_rresp  <= 2'b00;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
