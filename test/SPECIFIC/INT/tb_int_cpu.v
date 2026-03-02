
`timescale 1ns / 1ps

module int_cpu_tb;

    // --- Parâmetros de Configuração ---
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10; // Período de 10ns (frequência de 100MHz)

    // ===============================
    // Clock e Reset
    // ===============================
    reg clk;
    reg resetn;
    reg [31:0] irq = 0; // Linha de interrupção para o CPU

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk; // Clock de 50 MHz
    end

    initial begin
        resetn = 0;
        #200;
        resetn = 1;
    end

    // ===============================
    // UART Signals
    // ===============================
    wire uart_tx;
    reg  uart_rx;

    initial uart_rx = 1'b1; // linha idle

    // ===============================
    // SPI Signals
    // ===============================
    wire spi_sck;
    wire spi_mosi;
    wire spi_miso;
    wire spi_cs;

    assign spi_miso = 1'b0; // sem resposta de slave externo (loopback pode ser adicionado)

    // ===============================
    // I2C Signals
    // ===============================
    wire i2c_sda;
    wire i2c_scl;
    pullup(i2c_sda);
    pullup(i2c_scl);

    // ===============================
    // Instância do SoC
    // ===============================
    soc_top uut (
        .clk(clk),
        .resetn(resetn),

        // UART
        .uart_tx(uart_tx),
        .uart_rx(uart_rx),

        // SPI
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_sck(spi_sck),
        .spi_cs(spi_cs),

        // I2C
        .i2c_sda(i2c_sda),
        .i2c_scl(i2c_scl),

        .irq_4(irq[4])  // Conecta a IRQ 4 ao sinal de interrupção externo
    );

    // =========================================================================
    // Monitoramento da UART TX (decodifica caracteres ASCII)
    // =========================================================================
    reg [9:0] uart_shift;
    integer bit_count = 0;
    realtime baud_period = 400;//8680; // ~115200 baud @50MHz

    initial begin
        wait(resetn);
        $display("\n=== Simulação Iniciada ===\n");
        forever begin
            @(negedge uart_tx); // start bit
            #(baud_period/2);
            uart_shift = 0;
            for (bit_count = 0; bit_count < 10; bit_count = bit_count + 1) begin
                uart_shift[bit_count] = uart_tx;
                #(baud_period);
            end
            if (uart_shift[0] == 0 && uart_shift[9] == 1) begin
                $write("%c", uart_shift[8:1]);
                $display(uart_shift[8:1]);
                $fflush();
            end
        end
    end

    // =========================================================================
    // Simulação da interrupção (IRQ)
    // =========================================================================

    always #(CLK_PERIOD * 20000) begin
        irq[4] = 1;             // Ativa a IRQ 4
        #(CLK_PERIOD * 1);      // interrupção latched
        irq[4] = 0;             // Desativa a IRQ externa
    end

    initial begin
        irq = 32'd0;
        wait(resetn);
        #2000;
        forever #(CLK_PERIOD * 20000) begin
            irq[4] = 1;             // Ativa a IRQ 4
            #(CLK_PERIOD * 1);      // interrupção latched
            irq[4] = 0;             // Desativa a IRQ externa
        end
    end

    // =========================================================================
    // Simulação de periféricos SPI e I2C
    // =========================================================================
    initial begin
        wait(resetn);
        #5000;
        $display("\n[TB] Teste SPI/I2C em andamento...");
        #1000;
        $display("[TB] Teste finalizado.\n");
        $stop;
    end

    // =========================================================================
    // Dump de sinais para GTKWave
    // =========================================================================
    initial begin
        $dumpfile("dump3.vcd");
        $dumpvars(0, int_cpu_tb);
    end

endmodule