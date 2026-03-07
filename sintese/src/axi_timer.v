/* verilator lint_off UNUSEDSIGNAL */
`timescale 1 ns / 1 ps

module axi_timer (
    input wire clk,
    input wire resetn,
    
    // AXI-lite slave
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

    reg [31:0] reload;
    reg [31:0] counter;
    reg        enable;
    reg        irq_pending;

    // Fio auxiliar para detectar o comando de clear via AXI
    wire axi_clear_irq = (s_axi_awvalid && s_axi_wvalid && s_axi_awready && s_axi_wready && 
                          s_axi_awaddr[3:0] == 4'h0 && s_axi_wdata[1]);

    // ============================================================
    // AXI WRITE & TIMER LOGIC (UNIFICADOS PARA EVITAR CONFLITOS)
    // ============================================================
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            reload        <= 32'd1000000;
            enable        <= 1'b0;
            counter       <= 32'd0;
            irq_pending   <= 1'b0;
        end else begin
            // Handshakes AXI
            s_axi_awready <= s_axi_awvalid && !s_axi_awready;
            s_axi_wready  <= s_axi_wvalid && !s_axi_wready;

            // Escrita nos Registradores
            if (s_axi_awvalid && s_axi_wvalid && s_axi_awready && s_axi_wready) begin
                s_axi_bvalid <= 1'b1;
                case (s_axi_awaddr[3:0])
                    4'h0: enable <= s_axi_wdata[0];
                    4'h4: reload <= s_axi_wdata;
					default: ;
                endcase
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            // Lógica do Contador e IRQ (Unificada para irq_pending ter apenas 1 driver)
            if (enable) begin
                if (counter >= reload) begin
                    irq_pending <= 1'b1; // Timer estourou: Set IRQ
                    counter     <= 32'd0;
                end else begin
                    counter <= counter + 32'd1;
                    // Se o CPU mandar limpar, o clear tem prioridade ou acontece aqui
                    if (axi_clear_irq) irq_pending <= 1'b0; 
                end
            end else begin
                counter <= 32'd0;
                // Permite limpar o IRQ mesmo com timer parado
                if (axi_clear_irq) irq_pending <= 1'b0;
            end
        end
    end

    // ============================================================
    // AXI READ LOGIC
    // ============================================================
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'd0;
            s_axi_rresp   <= 2'b00;
        end else begin
            s_axi_arready <= s_axi_arvalid && !s_axi_arready;
            
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                case (s_axi_araddr[3:0])
                    4'h0: s_axi_rdata <= {31'd0, enable};
                    4'h4: s_axi_rdata <= reload;
                    4'h8: s_axi_rdata <= {31'd0, irq_pending};
                    default: s_axi_rdata <= 32'hDEADBEEF;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    assign irq_out = irq_pending;

endmodule
