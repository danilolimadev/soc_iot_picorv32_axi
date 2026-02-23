// ============================================================
// axi_i2c.v (Versão Final: Bidirecional Open-Drain)
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
    inout wire i2c_sda, // VOLTOU para inout
    inout wire i2c_scl  // VOLTOU para inout
);

    // Registradores Internos
    reg [31:0] addr_reg; // Armazena endereço do escravo
    reg [31:0] data_reg; // Armazena dado a enviar

    // Controle Open-Drain
    // Se drive_low = 1, a saída é 0 (GND). 
    // Se drive_low = 0, a saída é Z (Alta Impedância -> Pull-up puxa pra 1).
    reg sda_drive_low;
    reg scl_drive_low;

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

    always @(posedge clk) begin
        if (!resetn) begin
            // Reset AXI
            s_axi_awready <= 0; s_axi_wready <= 0; s_axi_bvalid <= 0;
            s_axi_arready <= 0; s_axi_rvalid <= 0;
            s_axi_rdata   <= 0;
            
            // Reset I2C
            main_state <= IDLE;
            sub_state <= 0;
            clk_div <= 0;
            
            // Solta o barramento (High-Z)
            sda_drive_low <= 0; 
            scl_drive_low <= 0;
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
                
                // Endereço (Offset 4)
                if (s_axi_awaddr[5:2] == 4'h1) begin
                    addr_reg <= s_axi_wdata;
                    $display("[AXI_I2C] Endereco de Destino Configurado: 0x%h", s_axi_wdata);
                end
                
                // Dado (Offset 8) -> Dispara Transmissão
                if (s_axi_awaddr[5:2] == 4'h2 && main_state == IDLE) begin
                    data_reg <= s_axi_wdata;
                    main_state <= START;
                    sub_state <= 0;
                    clk_div <= 0;
                    $display("[AXI_I2C] Dado escrito: 0x%h. Iniciando Transmissao...", s_axi_wdata);
                end
            end
            
            // ------------------------------------------------
            // Interface AXI (Leitura Dummy)
            // ------------------------------------------------
            s_axi_arready <= (!s_axi_arready && s_axi_arvalid);
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1; 
                s_axi_rdata <= 0; // Retorna 0
            end else if (s_axi_rvalid && s_axi_rready) 
                s_axi_rvalid <= 0;

            // ------------------------------------------------
            // Máquina de Estados I2C (Hardware)
            // ------------------------------------------------
            if (main_state != IDLE) begin
                clk_div <= clk_div + 1;
                
                // Velocidade do clock I2C (ajuste este valor para simulação mais rápida ou lenta)
                if (clk_div == 20) begin 
                    clk_div <= 0;
                    
                    case (main_state)
                        START: begin
                            // Sequência de Start: SDA desce enquanto SCL está alto
                            if (sub_state == 0) begin 
                                sda_drive_low <= 1; // SDA Low
                                scl_drive_low <= 0; // SCL High (Z)
                                sub_state <= 1; 
                                $display("[I2C_BUS] START Condition");
                            end
                            else begin 
                                scl_drive_low <= 1; // SCL Low
                                bit_cnt <= 7; 
                                main_state <= SEND_ADDR; 
                                sub_state <= 0; 
                            end
                        end

                        SEND_ADDR, SEND_DATA: begin
                            case (sub_state)
                                0: begin // Clock Low -> Preparar Dado
                                    scl_drive_low <= 1; 
                                    sub_state <= 1; 
                                end
                                1: begin // Mudar SDA
                                    if (main_state == SEND_ADDR) sda_drive_low <= ~addr_reg[bit_cnt];
                                    else                         sda_drive_low <= ~data_reg[bit_cnt];
                                    sub_state <= 2;
                                end
                                2: begin // Clock High -> Validar Dado
                                    scl_drive_low <= 0; // SCL High (Z)
                                    sub_state <= 3; 
                                end
                                3: begin // Clock Low -> Próximo Bit
                                    scl_drive_low <= 1; // SCL Low
                                    sub_state <= 0;
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
                                    scl_drive_low <= 1; // Clock Low
                                    sda_drive_low <= 0; // Solta SDA (High-Z) para o Slave responder!
                                    sub_state <= 1; 
                                end
                                1: begin // Wait (Slave puxa SDA aqui)
                                    sub_state <= 2; 
                                end
                                2: begin // Clock High (Pulso de ACK)
                                    scl_drive_low <= 0; 
                                    $display("[I2C_BUS] Aguardando ACK...");
                                    sub_state <= 3; 
                                end
                                3: begin // Clock Low -> Fim do ACK
                                    scl_drive_low <= 1; 
                                    sub_state <= 0;
                                    bit_cnt <= 7;
                                    if (main_state == ACK_ADDR) main_state <= SEND_DATA;
                                    else                        main_state <= STOP;
                                end
                            endcase
                        end

                        STOP: begin
                            case (sub_state)
                                0: begin // Garante ambos Low
                                    scl_drive_low <= 1; 
                                    sda_drive_low <= 1; 
                                    sub_state <= 1; 
                                end
                                1: begin // SCL Sobe primeiro
                                    scl_drive_low <= 0; // SCL High (Z)
                                    sub_state <= 2; 
                                end
                                2: begin // SDA Sobe depois (Stop Condition)
                                    sda_drive_low <= 0; // SDA High (Z)
                                    sub_state <= 3; 
                                    $display("[I2C_BUS] STOP Condition. Fim.\n");
                                end
                                3: begin 
                                    main_state <= IDLE; 
                                end
                            endcase
                        end
                    endcase
                end
            end
        end
    end
endmodule