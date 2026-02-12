// =====================================
// AXI4-Lite RAM simples (32-bit)
// =====================================
module axi_ram #(
    parameter ADDR_WIDTH = 16,   // 64KB (2^16 bytes)
    parameter DATA_WIDTH = 32
)(
    input  wire                     clk,
    input  wire                     resetn,

    // AXI Write Address Channel
    input  wire [31:0]              s_axi_awaddr,
    input  wire                     s_axi_awvalid,
    output reg                      s_axi_awready,

    // AXI Write Data Channel
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                     s_axi_wvalid,
    output reg                      s_axi_wready,

    // AXI Write Response Channel
    output reg [1:0]                s_axi_bresp,
    output reg                      s_axi_bvalid,
    input  wire                     s_axi_bready,

    // AXI Read Address Channel
    input  wire [31:0]              s_axi_araddr,
    input  wire                     s_axi_arvalid,
    output reg                      s_axi_arready,

    // AXI Read Data Channel
    output reg [DATA_WIDTH-1:0]     s_axi_rdata,
    output reg [1:0]                s_axi_rresp,
    output reg                      s_axi_rvalid,
    input  wire                     s_axi_rready
);

    localparam MEM_WORDS = (1 << ADDR_WIDTH) / (DATA_WIDTH/8);

    reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

    integer i;
    initial begin
        for (i=0; i<MEM_WORDS; i=i+1)
            mem[i] = 0;
        // Carrega firmware
        $readmemh("firmware.hex", mem);
    end

    // --------------------
    // Write logic
    // --------------------
    reg aw_en;
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 0;
            s_axi_wready  <= 0;
            s_axi_bvalid  <= 0;
            s_axi_bresp   <= 2'b00;
            aw_en         <= 1;
        end else begin
            // Address ready
            if (~s_axi_awready && s_axi_awvalid && aw_en) begin
                s_axi_awready <= 1;
                aw_en <= 0;
            end else if (s_axi_wready && s_axi_wvalid && ~s_axi_bvalid) begin
                s_axi_awready <= 0;
                aw_en <= 1;
            end

            // Data ready
            if (~s_axi_wready && s_axi_wvalid && s_axi_awvalid) begin
                s_axi_wready <= 1;
            end else begin
                s_axi_wready <= 0;
            end

            // Write memory
            if (s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid) begin
                for (i=0; i<DATA_WIDTH/8; i=i+1) begin
                    if (s_axi_wstrb[i]) begin
                        mem[s_axi_awaddr[ADDR_WIDTH-1:2]][8*i +: 8] <= s_axi_wdata[8*i +: 8];
                    end
                end
            end

            // Response
            if (s_axi_awready && s_axi_awvalid && ~s_axi_bvalid && s_axi_wready && s_axi_wvalid) begin
                s_axi_bvalid <= 1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 0;
            end
        end
    end

    // --------------------
    // Read logic
    // --------------------
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_arready <= 0;
            s_axi_rvalid  <= 0;
            s_axi_rresp   <= 2'b00;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1;
            end else begin
                s_axi_arready <= 0;
            end

            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rdata <= mem[s_axi_araddr[ADDR_WIDTH-1:2]];
                s_axi_rvalid <= 1;
                s_axi_rresp <= 2'b00; // OKAY
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 0;
            end
        end
    end

endmodule
