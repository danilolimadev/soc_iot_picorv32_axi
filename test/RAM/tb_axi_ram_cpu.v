
`timescale 1ns / 1ps

module axi_ram_cpu_tb;

    // --- Parâmetros de Configuração ---
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10; // Período de 10ns (frequência de 100MHz)

    // --- Sinais de Estímulo (Regs para controlar, Wires para observar) ---
    reg clk;
    reg resetn;

    // Sinais do Canal de Escrita (Mestre -> Escravo)
    wire [31:0] s_axi_awaddr;
    wire        s_axi_awvalid;
    wire       s_axi_awready; // Output da RAM
    wire [31:0] s_axi_wdata;
    wire [3:0]  s_axi_wstrb;
    wire        s_axi_wvalid;
    wire       s_axi_wready;  // Output da RAM
    wire [1:0] s_axi_bresp;   // Output da RAM
    wire       s_axi_bvalid;  // Output da RAM
    wire        s_axi_bready;

    // Sinais do Canal de Leitura (Mestre -> Escravo)
    wire [31:0] s_axi_araddr;
    wire        s_axi_arvalid;
    wire       s_axi_arready; // Output da RAM
    wire [31:0] s_axi_rdata;  // Output da RAM
    wire [1:0]  s_axi_rresp;  // Output da RAM
    wire        s_axi_rvalid; // Output da RAM
    wire         s_axi_rready;

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

    // --- Instanciação do PicoRV32 CPU com AXI Master ---
    picorv32_axi #(
        .PROGADDR_RESET(32'h0000_0000) // Endereço de reset do programa
    ) cpu (
        .clk(clk),
        .resetn(resetn),
        // Conexões AXI-Lite para a RAM
        .mem_axi_awaddr(s_axi_awaddr),
        .mem_axi_awvalid(s_axi_awvalid),
        .mem_axi_awready(s_axi_awready),
        .mem_axi_wdata(s_axi_wdata),
        .mem_axi_wstrb(s_axi_wstrb),
        .mem_axi_wvalid(s_axi_wvalid),
        .mem_axi_wready(s_axi_wready),
        .mem_axi_bvalid(s_axi_bvalid),
        .mem_axi_bready(s_axi_bready),
        .mem_axi_araddr(s_axi_araddr),
        .mem_axi_arvalid(s_axi_arvalid),
        .mem_axi_arready(s_axi_arready),
        .mem_axi_rdata(s_axi_rdata),
        .mem_axi_rvalid(s_axi_rvalid),
        .mem_axi_rready(s_axi_rready)
    );

    // --- Geração do Clock ---
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk; // Inverte o nível lógico a cada meio período

    // --- Bloco Principal de Estímulos ---
    initial begin
        // 1. Inicialização segura de todos os sinais de entrada
        resetn = 0;


        // 2. Aguarda alguns ciclos e libera o Reset
        #(CLK_PERIOD * 5);
        resetn = 1;
        #(CLK_PERIOD * 2);


        #(CLK_PERIOD * 10);
        $display("--- Simulação Finalizada ---");
        //$finish;
    end

endmodule