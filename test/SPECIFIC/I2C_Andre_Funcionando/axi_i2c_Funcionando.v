// ============================================================
// axi_i2c.v (Versão: N-Bytes com Buffer, Open-Drain)
// ============================================================
module axi_i2c (
    input  wire        clk,
    input  wire        resetn,

    // Interface AXI4-Lite Slave
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

    // Pinos Físicos I2C (Bidirecionais)
    inout wire i2c_sda,
    inout wire i2c_scl 
);

    // =========================================================
    // Mapa de Registradores AXI
    // Offset 0x04: ADDR_REG (Endereço I2C do Escravo)
    // Offset 0x08: LEN_REG  (Quantidade de Bytes a enviar: 0 a 16)
    // Offset 0x0C: START    (Escrever qualquer valor aqui inicia a transação)
    // Offset 0x10 a 0x4C: DATA_BUF[0] a DATA_BUF[15]
    // =========================================================
    reg [31:0] addr_reg;
    reg [31:0] len_reg;
    reg [31:0] data_buf [0:15];
    
    // Contadores Internos
    reg [4:0] byte_idx; // Conta qual byte está sendo enviado (0 a 15)

    // Fio para facilitar leitura do buffer no Verilog
    wire [31:0] current_tx_data = data_buf[byte_idx[3:0]];

    // Controle Open-Drain
    reg sda_drive_low; reg scl_drive_low;
    assign i2c_sda = (sda_drive_low) ? 1'b0 : 1'bz;
    assign i2c_scl = (scl_drive_low) ? 1'b0 : 1'bz;

    // Estados da Máquina
    localparam IDLE      = 0;
    localparam START     = 1;
    localparam SEND_ADDR = 2;
    localparam ACK_ADDR  = 3;
    localparam SEND_DATA = 4;
    localparam ACK_DATA  = 5;
    localparam STOP      = 6;

    reg [3:0] main_state;
    reg [2:0] bit_cnt;
    reg [1:0] sub_state; 
    reg [7:0] clk_div;

    wire [5:0] reg_idx = s_axi_awaddr[7:2]; // Decodificador de Offset AXI

    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 0; s_axi_wready <= 0; s_axi_bvalid <= 0;
            s_axi_arready <= 0; s_axi_rvalid <= 0; s_axi_rdata   <= 0;
            
            main_state <= IDLE; sub_state <= 0; clk_div <= 0; byte_idx <= 0;
            sda_drive_low <= 0; scl_drive_low <= 0;
            len_reg <= 0;
        end else begin
            // ------------------------------------------------
            // Interface AXI (Escrita)
            // ------------------------------------------------
            s_axi_awready <= (!s_axi_awready && s_axi_awvalid);
            s_axi_wready  <= (!s_axi_wready && s_axi_wvalid);

            if (s_axi_bvalid && s_axi_bready) 
                s_axi_bvalid <= 0;
            else if (s_axi_awvalid && s_axi_wvalid && s_axi_awready && s_axi_wready) begin
                s_axi_bvalid <= 1;
                
                case (reg_idx)
                    6'd1: addr_reg <= s_axi_wdata; // Offset 0x04
                    6'd2: len_reg  <= s_axi_wdata; // Offset 0x08
                    6'd3: begin                    // Offset 0x0C (START)
                        if (main_state == IDLE) begin
                            main_state <= START;
                            sub_state <= 0;
                            clk_div <= 0;
                            byte_idx <= 0;
                            $display("[AXI_I2C] Iniciando Transmissao de %d Bytes...", len_reg);
                        end
                    end
                    default: begin // Offsets 0x10 a 0x4C (Buffer)
                        if (reg_idx >= 4 && reg_idx <= 19) begin
                            data_buf[reg_idx - 4] <= s_axi_wdata;
                            $display("[AXI_I2C] Buffer[%d] = 0x%h", reg_idx - 4, s_axi_wdata);
                        end
                    end
                endcase
            end
            
            // ------------------------------------------------
            // Interface AXI (Leitura Dummy)
            // ------------------------------------------------
            s_axi_arready <= (!s_axi_arready && s_axi_arvalid);
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1; s_axi_rdata <= 0;
            end else if (s_axi_rvalid && s_axi_rready) 
                s_axi_rvalid <= 0;

            // ------------------------------------------------
            // Máquina de Estados I2C (N-Bytes)
            // ------------------------------------------------
            if (main_state != IDLE) begin
                clk_div <= clk_div + 1;
                
                if (clk_div == 20) begin 
                    clk_div <= 0;
                    case (main_state)
                        START: begin
                            if (sub_state == 0) begin 
                                sda_drive_low <= 1; scl_drive_low <= 0; sub_state <= 1; 
                            end
                            else begin 
                                scl_drive_low <= 1; bit_cnt <= 7; main_state <= SEND_ADDR; sub_state <= 0; 
                            end
                        end

                        SEND_ADDR, SEND_DATA: begin
                            case (sub_state)
                                0: begin scl_drive_low <= 1; sub_state <= 1; end
                                1: begin // Mudar SDA
                                    if (main_state == SEND_ADDR) sda_drive_low <= ~addr_reg[bit_cnt];
                                    else                         sda_drive_low <= ~current_tx_data[bit_cnt];
                                    sub_state <= 2;
                                end
                                2: begin scl_drive_low <= 0; sub_state <= 3; end
                                3: begin // Clock Low -> Próximo Bit
                                    scl_drive_low <= 1; sub_state <= 0;
                                    if (bit_cnt == 0) begin
                                        if (main_state == SEND_ADDR) main_state <= ACK_ADDR;
                                        else                         main_state <= ACK_DATA;
                                    end else begin
                                        bit_cnt <= bit_cnt - 1;
                                    end
                                end
                            endcase
                        end

                        ACK_ADDR, ACK_DATA: begin
                            case (sub_state)
                                0: begin 
                                    scl_drive_low <= 1; sda_drive_low <= 0; // Solta SDA
                                    sub_state <= 1; 
                                end
                                1: begin sub_state <= 2; end
                                2: begin scl_drive_low <= 0; sub_state <= 3; end // Pulso ACK
                                3: begin 
                                    scl_drive_low <= 1; sub_state <= 0; bit_cnt <= 7;
                                    if (main_state == ACK_ADDR) begin
                                        if (len_reg > 0) main_state <= SEND_DATA; // Vai para dados se LEN > 0
                                        else             main_state <= STOP;      // Senão apenas STOP
                                    end else begin // ACK_DATA
                                        if (byte_idx + 1 < len_reg) begin
                                            byte_idx <= byte_idx + 1; // Puxa próximo byte do Buffer
                                            main_state <= SEND_DATA;
                                        end else begin
                                            main_state <= STOP; // Terminou todos os N bytes
                                        end
                                    end
                                end
                            endcase
                        end

                        STOP: begin
                            case (sub_state)
                                0: begin scl_drive_low <= 1; sda_drive_low <= 1; sub_state <= 1; end
                                1: begin scl_drive_low <= 0; sub_state <= 2; end
                                2: begin 
                                    sda_drive_low <= 0; sub_state <= 3; 
                                    $display("[I2C_BUS] Transmissao Concluida.\\n");
                                end
                                3: begin main_state <= IDLE; end
                            endcase
                        end
                    endcase
                end
            end
        end
    end
endmodule