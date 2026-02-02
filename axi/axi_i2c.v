// ============================================================
// axi_i2c.v
// Controlador I2C com interface AXI4-Lite (versão simplificada)
// Corrigido e otimizado para SoC com PicoRV32_AXI
// ============================================================

module axi_i2c (
    input  wire        clk,
    input  wire        resetn,

    // AXI4-Lite Write Address Channel
    input  wire [11:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [11:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    // --------------------------------------------------------
    // Registradores simulados
    // --------------------------------------------------------
    reg [31:0] ctrl_reg;   // Controle I2C (enable, start, etc)
    reg [31:0] addr_reg;   // Endereço do dispositivo
    reg [31:0] tx_reg;     // Dado a transmitir
    reg [31:0] rx_reg;     // Dado recebido (simulado)
    reg [31:0] status_reg; // Status (busy, ack, etc)

    // --------------------------------------------------------
    // Escrita AXI4-Lite
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 0;
            s_axi_wready  <= 0;
            s_axi_bvalid  <= 0;
            s_axi_bresp   <= 2'b00;
            ctrl_reg      <= 0;
            addr_reg      <= 0;
            tx_reg        <= 0;
            rx_reg        <= 0;
            status_reg    <= 0;
        end else begin
            // Handshake de escrita
            if (!s_axi_awready && s_axi_awvalid)
                s_axi_awready <= 1;
            else
                s_axi_awready <= 0;

            if (!s_axi_wready && s_axi_wvalid)
                s_axi_wready <= 1;
            else
                s_axi_wready <= 0;

            // Quando ambos válidos
            if (s_axi_awvalid && s_axi_wvalid && s_axi_awready && s_axi_wready) begin
                s_axi_bvalid <= 1;
                s_axi_bresp  <= 2'b00; // OKAY

                case (s_axi_awaddr[5:2])  // alinhado a 4 bytes
                    4'h0: ctrl_reg   <= s_axi_wdata;
                    4'h1: addr_reg   <= s_axi_wdata;
                    4'h2: tx_reg     <= s_axi_wdata;
                    4'h3: status_reg <= s_axi_wdata;
                    default: ;
                endcase

                // Simula que dado foi recebido (loopback)
                rx_reg <= tx_reg + 1; // apenas pra ver mudança
            end

            // Encerramento da resposta de escrita
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 0;
        end
    end

    // --------------------------------------------------------
    // Leitura AXI4-Lite
    // --------------------------------------------------------
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
                s_axi_rresp  <= 2'b00;

                case (s_axi_araddr[5:2])
                    4'h0: s_axi_rdata <= ctrl_reg;
                    4'h1: s_axi_rdata <= addr_reg;
                    4'h2: s_axi_rdata <= tx_reg;
                    4'h3: s_axi_rdata <= rx_reg;
                    4'h4: s_axi_rdata <= status_reg;
                    default: s_axi_rdata <= 32'hDEAD_BEEF;
                endcase
            end else if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 0;
        end
    end

endmodule
