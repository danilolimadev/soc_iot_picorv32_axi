interface soc_bfm;
    bit        clk;
    bit        resetn;

    // Debug
    bit        trap;
    bit [31:0] gpio_out;
    bit        timer_irq;

    // UART
    bit        uart_tx;
    bit        uart_rx;

    // SPI
    bit        spi_mosi;
    bit        spi_miso;
    bit        spi_sck;
    bit        spi_cs;

    // I2C
    bit        i2c_sda;
    bit        i2c_scl;

    // TODO: adicionar métodos
endinterface