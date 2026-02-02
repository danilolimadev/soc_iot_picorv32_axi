// axi_timer.v - AXI-lite timer stub (gera irq_out)
module axi_timer (
    input wire clk,
    input wire resetn,
    // AXI-lite slave (endereço 12 bits usado no interconnect)
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
    output wire        irq_out
);

    reg [31:0] reload; // valor limite
    reg [31:0] counter;
    reg enable;

    // simple AXI-lite register map:
    // addr 0x0: CONTROL (bit0 = enable, bit1 = IRQ clear)
    // addr 0x4: RELOAD (valor)
    // addr 0x8: STATUS (bit0 = irq_pending)
    reg irq_pending;

    // AXI write (very small implementation)
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 0;
            s_axi_wready <= 0;
            s_axi_bvalid <= 0;
            reload <= 32'd1000000; // default
            enable <= 0;
            irq_pending <= 0;
        end else begin
            // AW handshake
            s_axi_awready <= s_axi_awvalid && !s_axi_awready;
            // W handshake
            s_axi_wready <= s_axi_wvalid && !s_axi_wready;
            if (s_axi_awvalid && s_axi_wvalid && s_axi_awready && s_axi_wready) begin
                s_axi_bvalid <= 1;
                s_axi_bresp  <= 2'b00;
                case (s_axi_awaddr[3:0])
                    4'h0: begin
                        enable <= s_axi_wdata[0];
                        if (s_axi_wdata[1]) irq_pending <= 0; // write 1 to clear irq
                    end
                    4'h4: reload <= s_axi_wdata;
                    default: ;
                endcase
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 0;
            end
        end
    end

    // AXI read
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_arready <= 0;
            s_axi_rvalid <= 0;
            s_axi_rdata <= 0;
        end else begin
            s_axi_arready <= s_axi_arvalid && !s_axi_arready;
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1;
                s_axi_rresp  <= 2'b00;
                case (s_axi_araddr[3:0])
                    4'h0: s_axi_rdata <= {31'd0, enable};
                    4'h4: s_axi_rdata <= reload;
                    4'h8: s_axi_rdata <= {31'd0, irq_pending};
                    default: s_axi_rdata <= 32'hDEADBEEF;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 0;
            end
        end
    end

    // timer counting
    always @(posedge clk) begin
        if (!resetn) begin
            counter <= 0;
            irq_pending <= 0;
        end else begin
            if (enable) begin
                if (counter >= reload) begin
                    irq_pending <= 1;
                    counter <= 0;
                end else begin
                    counter <= counter + 1;
                end
            end else begin
                counter <= 0;
            end
        end
    end

    assign irq_out = irq_pending;

endmodule
