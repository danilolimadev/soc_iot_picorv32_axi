
`timescale 1ns / 1ps

module int_cpu_tb;

    // --- Parâmetros de Configuração ---
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10; // Período de 10ns (frequência de 100MHz)

    // --- Sinais de Estímulo (Regs para controlar, Wires para observar) ---
    reg clk;
    reg resetn;
    reg [31:0] irq; // Linha de interrupção para o CPU

    // --- Instanciação do Módulo RAM (Unit Under Test - UUT) ---
    int_cpu_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .resetn(resetn),
        .irq(irq) // Conecta a linha de IRQ do CPU ao testbench
    );


    // --- Geração do Clock ---
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk; // Inverte o nível lógico a cada meio período
 
    //  Simula uma interrupção externa após alguns ciclos
    always #(CLK_PERIOD * 20000) begin
        irq[4] = 1;             // Ativa a IRQ 4
        #(CLK_PERIOD * 1);      // interrupção latched
        irq[4] = 0;             // Desativa a IRQ externa
    end

    // --- Bloco Principal de Estímulos ---
    initial begin
        // 1. Inicialização segura de todos os sinais de entrada
        resetn = 0;
        irq = 0;


        // 2. Aguarda alguns ciclos e libera o Reset
        #(CLK_PERIOD * 5);
        resetn = 1;
        #(CLK_PERIOD * 2);

       
                 

        #(CLK_PERIOD * 100000);
        $display("--- Simulação Finalizada ---");
        $finish;
    end

    // =========================================================================
    // Dump de sinais para GTKWave
    // =========================================================================
    initial begin
        $dumpfile("dump2.vcd");
        $dumpvars(0, int_cpu_tb);
    end

endmodule