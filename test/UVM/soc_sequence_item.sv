`ifndef SOC_SEQUENCE_ITEM_SV
`define SOC_SEQUENCE_ITEM_SV

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class soc_sequence_item extends uvm_sequence_item;
        // TODO: quais valores serão enviados
        // Debug
        bit       trap;
        shortint  gpio_out; //?
        bit       timer_irq;

        // UART
        bit       uart_tx;
        rand bit  uart_rx;

        // SPI
        bit       spi_mosi;
        rand bit  spi_miso;
        bit       spi_sck;
        bit       spi_cs;

        // I2C
        rand bit  i2c_sda;
        rand bit  i2c_scl;
        
        function new(string name);
            super.new(name);
        endfunction : new
        
        function bit get_random_i2c_value();
            assert(this.randomize());
            return this.i2c_sda;
        endfunction

        function bit get_random_spi_value();
            assert(this.randomize());
            return this.spi_miso;
        endfunction

        function bit get_random_uart_value();
            assert(this.randomize());
            return this.uart_rx;
        endfunction

    endclass : soc_sequence_item

`endif