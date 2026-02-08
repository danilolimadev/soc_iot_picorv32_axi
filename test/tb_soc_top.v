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
        forever #10 clk = ~clk; // 50 MHz
    end

    initial begin
        resetn = 0;
        #200;
        resetn = 1;
    end

    // ===============================
    // UART
    // ===============================
    wire uart_tx;
    reg  uart_rx;

    initial uart_rx = 1'b1; // idle

    // ===============================
    // SPI
    // ===============================
    wire spi_sck;
    wire spi_mosi;
    wire spi_miso;
    wire spi_cs;

    assign spi_miso = 1'b0; // slave dummy

    // ===============================
    // I2C (open-drain)
    // ===============================
    wire i2c_sda;
    wire i2c_scl;

    pullup(i2c_sda);
    pullup(i2c_scl);

    // ===============================
    // Debug / GPIO / IRQ
    // ===============================
    wire [31:0] gpio_out;
    wire        trap;
    wire        timer_irq;

    // ===============================
    // Instância do SoC
    // ===============================
    soc_top uut (
        .clk(clk),
        .resetn(resetn),

        // Debug
        .trap(trap),
        .gpio_out(gpio_out),
        .timer_irq(timer_irq),

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
    );

    // =========================================================================
    // Monitoramento da UART TX (ASCII)
    // =========================================================================
    reg [9:0] uart_shift;
    integer bit_count;
    realtime baud_period = 8680; // ~115200 baud @50MHz

    initial begin
        wait(resetn);
        $display("\n=== Simulação Iniciada ===\n");

        forever begin
            @(negedge uart_tx); // start bit
            #(baud_period/2);

            for (bit_count = 0; bit_count < 10; bit_count = bit_count + 1) begin
                uart_shift[bit_count] = uart_tx;
                #(baud_period);
            end

            if (uart_shift[0] == 1'b0 && uart_shift[9] == 1'b1) begin
                $write("%c", uart_shift[8:1]);
                $fflush();
            end
        end
    end

    // =========================================================================
    // Monitoramento de GPIO
    // =========================================================================
    always @(gpio_out) begin
        $display("[TB] GPIO_OUT = 0x%08X @ %0t", gpio_out, $time);
    end

    // =========================================================================
    // Monitoramento de IRQ do Timer
    // =========================================================================
    always @(posedge timer_irq) begin
        $display("[TB] >>> TIMER IRQ ASSERTED @ %0t", $time);
    end

    // =========================================================================
    // Monitoramento de TRAP (erro fatal do CPU)
    // =========================================================================
    always @(posedge trap) begin
        $display("\n[TB] !!! TRAP DETECTADO — CPU PAROU @ %0t !!!\n", $time);
        $stop;
    end

    // =========================================================================
    // Observação de I2C (nível dos pinos)
    // =========================================================================
    always @(i2c_sda or i2c_scl) begin
        $display("[TB][I2C] SDA=%b SCL=%b @ %0t", i2c_sda, i2c_scl, $time);
    end

    // =========================================================================
    // Tempo total de simulação
    // =========================================================================
    initial begin
        wait(resetn);
        #200000;
        $display("\n[TB] Fim da simulação.\n");
        $stop;
    end

    // =========================================================================
    // Dump GTKWave
    // =========================================================================
    initial begin
        $dumpfile("soc_tb.vcd");
        $dumpvars(0, soc_tb);
    end

endmodule
