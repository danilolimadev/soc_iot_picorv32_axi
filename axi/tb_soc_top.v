// ============================================================================
//  Testbench — SoC AXI (CPU + RAM + GPIO + UART + SPI + I2C + TIMER)
// ============================================================================

`timescale 1ns/1ps

module soc_tb;

    // ===============================
    // Clock e Reset
    // ===============================
    reg clk;
    reg resetn;

    initial begin
        clk = 0;
        forever #10 clk = ~clk; // Clock de 50 MHz
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
    // IRQ (Timer)
    // ===============================
    //wire timer_irq;

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
        .i2c_scl(i2c_scl)

        // IRQ do timer
        //.timer_irq(timer_irq)
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
    initial begin
        wait(resetn);
        #2000;
        $display("\n[TB] Forçando interrupção por Timer...");
        force uut.timer_irq = 1'b1;
        #1000;
        release uut.timer_irq;
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
        $dumpfile("soc_tb.vcd");
        $dumpvars(0, soc_tb);
    end

endmodule
