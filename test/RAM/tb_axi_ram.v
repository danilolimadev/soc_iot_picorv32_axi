
`timescale 1ns / 1ps

module axi_ram_tb;

    // --- Parâmetros de Configuração ---
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10; // Período de 10ns (frequência de 100MHz)

    // --- Sinais de Estímulo (Regs para controlar, Wires para observar) ---
    reg clk;
    reg resetn;

    // Sinais do Canal de Escrita (Mestre -> Escravo)
    reg [31:0] s_axi_awaddr;
    reg        s_axi_awvalid;
    wire       s_axi_awready; // Output da RAM
    reg [31:0] s_axi_wdata;
    reg [3:0]  s_axi_wstrb;
    reg        s_axi_wvalid;
    wire       s_axi_wready;  // Output da RAM
    wire [1:0] s_axi_bresp;   // Output da RAM
    wire       s_axi_bvalid;  // Output da RAM
    reg        s_axi_bready;

    // Sinais do Canal de Leitura (Mestre -> Escravo)
    reg [31:0] s_axi_araddr;
    reg        s_axi_arvalid;
    wire       s_axi_arready; // Output da RAM
    wire [31:0] s_axi_rdata;  // Output da RAM
    wire [1:0]  s_axi_rresp;  // Output da RAM
    wire        s_axi_rvalid; // Output da RAM
    reg         s_axi_rready;

    // --- Instanciação do Módulo RAM (Unit Under Test - UUT) ---
    axi_ram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .resetn(resetn),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready)
    );

    // --- Geração do Clock ---
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk; // Inverte o nível lógico a cada meio período

    // --- Bloco Principal de Estímulos ---
    initial begin
        // 1. Inicialização segura de todos os sinais de entrada
        resetn = 0;
        s_axi_awaddr = 0; s_axi_awvalid = 0; s_axi_bready = 0;
        s_axi_wdata = 0;  s_axi_wstrb = 0;   s_axi_wvalid = 0;
        s_axi_araddr = 0; s_axi_arvalid = 0; s_axi_rready = 0;

        // 2. Aguarda alguns ciclos e libera o Reset
        #(CLK_PERIOD * 5);
        resetn = 1;
        #(CLK_PERIOD * 2);

        $display("--- Iniciando Testes ---");

        // TESTE 1: Leitura do arquivo firmware.hex
        // Supõe-se que o arquivo firmware.hex contenha dados pré-carregados
        $display("[%0t] Teste 1: Lendo posição 0 (carregada do .hex)", $time);
        axi_read(32'h0000_0000); 
        $display("[%0t] Valor lido no endereço 0x0: %h", $time, s_axi_rdata);

        // TESTE 2: Escrita AXI-Lite
        // Escrevendo 0xDEADBEEF no endereço 0x10 (16 em decimal)
        $display("[%0t] Teste 2: Escrevendo 0xDEADBEEF no endereço 0x10", $time);
        axi_write(32'h0000_0010, 32'hDEADBEEF, 4'b1111); // Strobe 4'b1111 = escreve os 4 bytes

        // TESTE 3: Verificação (Leitura do que foi escrito)
        $display("[%0t] Teste 3: Lendo endereço 0x10 para validar escrita", $time);
        axi_read(32'h0000_0010);
        if (s_axi_rdata == 32'hDEADBEEF)
            $display("SUCESSO: O dado lido corresponde ao escrito.");
        else
            $display("ERRO: O dado lido (%h) esta incorreto!", s_axi_rdata);

        // Finalização
        #(CLK_PERIOD * 10);
        $display("--- Simulação Finalizada ---");
        $finish;
    end

    // --- Tarefa (Task): Escrita AXI-Lite ---
    // Esta task abstrai o protocolo de handshake VALID/READY
    task axi_write(input [31:0] addr, input [31:0] data, input [3:0] strb);
        begin
            @(posedge clk);
            s_axi_awaddr  <= addr;
            s_axi_awvalid <= 1;        // Sinaliza endereço válido
            s_axi_wdata   <= data;
            s_axi_wstrb   <= strb;
            s_axi_wvalid  <= 1;        // Sinaliza dado válido
            s_axi_bready  <= 1;        // Indica que aceita resposta de confirmação

            // Espera até que o escravo (RAM) levante os sinais READY
            wait(s_axi_awready && s_axi_wready);
            
            @(posedge clk);
            s_axi_awvalid <= 0;        // Desativa sinais após o handshake
            s_axi_wvalid  <= 0;

            // Aguarda o canal de resposta (B) confirmar a transação
            wait(s_axi_bvalid);
            @(posedge clk);
            s_axi_bready  <= 0;
            $display("[%0t] Escrita concluída com resposta BRESP: %b", $time, s_axi_bresp);
        end
    endtask

    // --- Tarefa (Task): Leitura AXI-Lite ---
    task axi_read(input [31:0] addr);
        begin
            @(posedge clk);
            s_axi_araddr  <= addr;
            s_axi_arvalid <= 1;        // Mestre solicita endereço de leitura
            s_axi_rready  <= 1;        // Mestre diz que está pronto para receber o dado

            // Aguarda o escravo aceitar o endereço
            wait(s_axi_arready);
            
            @(posedge clk);
            s_axi_arvalid <= 0;

            // Aguarda o escravo disponibilizar o dado (RVALID)
            wait(s_axi_rvalid);
            @(posedge clk);
            s_axi_rready  <= 0; // Finaliza o handshake de leitura
        end
    endtask

endmodule