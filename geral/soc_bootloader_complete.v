module soc_bootloader_complete(
    input clk,
    input resetn,
    input boot_mode, // 1 = programar ROM via UART | 0 = rodar sistema

    // Bootloader
    output boot_done,

    // SoC
    // Debug
    output wire        trap,
    output wire [31:0] gpio_out,
    output wire        timer_irq,

    // UART
    output wire        uart_tx,
    input  wire        uart_rx,

    // SPI
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        spi_sck,
    output wire        spi_cs,

    // I2C
    inout  wire        i2c_sda,
    inout  wire        i2c_scl
);

    wire uart_rx_boot;
    wire [31:0] firmware_size;

    bootloader_uart #(
                        .FIRMWARE_FILE("firmware.hex")
                    ) boot (
                        .clk(clk),
                        .resetn(resetn),
                        .boot_enable(boot_mode),
                        .uart_tx(uart_rx_boot),  // <- conecta no RX do SoC
                        .done(boot_done),
                        .firmware_size(firmware_size)
                    );


    soc_top soc (
                .clk(clk),
                .resetn(resetn),
                .boot_mode(boot_mode),   // <<< IMPORTANTE
                .uart_rx_boot(uart_rx_boot),
                .firmware_size(firmware_size),
                .trap(trap),
                .gpio_out(gpio_out),
                .timer_irq(timer_irq),
                .uart_tx(uart_tx),
                .uart_rx(uart_rx),
                .spi_mosi(spi_mosi),
                .spi_miso(spi_miso),
                .spi_sck(spi_sck),
                .spi_cs(spi_cs),
                .i2c_sda(i2c_sda),
                .i2c_scl(i2c_scl)
            );
endmodule