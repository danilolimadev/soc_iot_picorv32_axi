module axi_gpio #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  resetn,

    // AXI-lite interface
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output wire                  s_axi_awready,

    input  wire [DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [3:0]            s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output wire                  s_axi_wready,

    output wire [1:0]            s_axi_bresp,
    output wire                  s_axi_bvalid,
    input  wire                  s_axi_bready,

    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output wire                  s_axi_arready,

    output reg  [DATA_WIDTH-1:0] s_axi_rdata,
    output wire [1:0]            s_axi_rresp,
    output wire                  s_axi_rvalid,
    input  wire                  s_axi_rready,

    // GPIO signals
    output reg [31:0] gpio_out
);

    reg awready, wready, bvalid, arready, rvalid;
    reg [31:0] reg_gpio;

    assign s_axi_awready = awready;
    assign s_axi_wready  = wready;
    assign s_axi_bresp   = 2'b00;
    assign s_axi_bvalid  = bvalid;

    assign s_axi_arready = arready;
    assign s_axi_rresp   = 2'b00;
    assign s_axi_rvalid  = rvalid;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            awready <= 0; wready <= 0; bvalid <= 0;
            arready <= 0; rvalid <= 0;
            reg_gpio <= 0; gpio_out <= 0;
        end else begin
            // Write transaction
            if (s_axi_awvalid && !awready) awready <= 1;
            else awready <= 0;

            if (s_axi_wvalid && !wready) begin
                wready <= 1;
                if (s_axi_awaddr[3:0] == 4'h0) begin
                    reg_gpio <= s_axi_wdata;
                    gpio_out <= s_axi_wdata;
                end
            end else wready <= 0;

            if (wready) bvalid <= 1;
            else if (s_axi_bready) bvalid <= 0;

            // Read transaction
            if (s_axi_arvalid && !arready) begin
                arready <= 1;
                if (s_axi_araddr[3:0] == 4'h0)
                    s_axi_rdata <= reg_gpio;
                else
                    s_axi_rdata <= 32'hDEADBEEF;
                rvalid <= 1;
            end else arready <= 0;

            if (rvalid && s_axi_rready) rvalid <= 0;
        end
    end

endmodule
