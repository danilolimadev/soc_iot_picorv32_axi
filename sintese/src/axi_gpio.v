/* verilator lint_off UNUSEDSIGNAL */
`timescale 1 ns / 1 ps

module axi_gpio #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  resetn,

    // AXI-lite
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,

    input  wire [DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [3:0]            s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,

    output wire [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,

    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    output reg  [DATA_WIDTH-1:0] s_axi_rdata,
    output wire [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready,

    // GPIO - Saída física como wire
    output wire [31:0]           gpio_out
);

    assign s_axi_bresp = 2'b00;
    assign s_axi_rresp = 2'b00;

    reg [ADDR_WIDTH-1:0] awaddr_lat;
    reg                  awaddr_valid;
    reg [ADDR_WIDTH-1:0] araddr_lat;
    reg [31:0]           reg_gpio;

    // Handshake wires
    wire aw_hs = s_axi_awvalid && s_axi_awready;
    wire w_hs  = s_axi_wvalid  && s_axi_wready;
    wire ar_hs = s_axi_arvalid && s_axi_arready;

    // O sinal físico gpio_out apenas segue o registrador interno
    assign gpio_out = reg_gpio;

    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_arready  <= 1'b0;
            s_axi_rvalid   <= 1'b0;

            awaddr_lat     <= {ADDR_WIDTH{1'b0}}; 
            awaddr_valid   <= 1'b0;
            araddr_lat     <= {ADDR_WIDTH{1'b0}};

            reg_gpio       <= 32'h0; // Resetamos o registrador aqui
            s_axi_rdata    <= 32'h0;
            
            // A LINHA "gpio_out <= 32'h0" FOI REMOVIDA DAQUI
        end else begin
            // -------------------------
            // Write Address Channel
            // -------------------------
            s_axi_awready <= (!awaddr_valid) && (!s_axi_bvalid);

            if (aw_hs) begin
                awaddr_lat   <= s_axi_awaddr;
                awaddr_valid <= 1'b1;
            end

            // -------------------------
            // Write Data Channel
            // -------------------------
            s_axi_wready <= (awaddr_valid) && (!s_axi_bvalid);

            if (w_hs) begin
                if (awaddr_lat[3:0] == 4'h0) begin
                    if (s_axi_wstrb[0]) reg_gpio[7:0]   <= s_axi_wdata[7:0];
                    if (s_axi_wstrb[1]) reg_gpio[15:8]  <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[2]) reg_gpio[23:16] <= s_axi_wdata[23:16];
                    if (s_axi_wstrb[3]) reg_gpio[31:24] <= s_axi_wdata[31:24];
                end
                s_axi_bvalid <= 1'b1;
                awaddr_valid <= 1'b0;
            end

            // Write response handshake
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            // -------------------------
            // Read Address Channel
            // -------------------------
            s_axi_arready <= (!s_axi_rvalid);

            if (ar_hs) begin
                araddr_lat <= s_axi_araddr;

                if (s_axi_araddr[3:0] == 4'h0)
                    s_axi_rdata <= reg_gpio;
                else
                    s_axi_rdata <= 32'hDEADBEEF;

                s_axi_rvalid <= 1'b1;
            end

            // Read data handshake
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
        end
    end

endmodule
