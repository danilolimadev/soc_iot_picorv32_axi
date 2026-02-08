`ifndef SOC_TOP_SV
`define SOC_TOP_SV

module top_tb;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    localparam int WIDTH = 8;

    soc_bfm bfm_local();  // sinais que irei usar para conectar com o DUT
    soc_top DUT (
                .clk         (bfm_local.clk),
                .resetn      (bfm_local.resetn),
                .trap        (bfm_local.trap),
                .gpio_out    (bfm_local.gpio_out),
                .timer_irq   (bfm_local.timer_irq),
                .uart_tx     (bfm_local.uart_tx),
                .uart_rx     (bfm_local.uart_rx),
                .spi_mosi    (bfm_local.spi_mosi),
                .spi_miso    (bfm_local.spi_miso),
                .spi_sck     (bfm_local.spi_sck),
                .spi_cs      (bfm_local.spi_cs),
                .i2c_sda     (bfm_local.i2c_sda),
                .i2c_scl     (bfm_local.i2c_scl)
            );

    initial
    begin

        uvm_config_db #(virtual soc_bfm)::set(null, "*", "bfm", bfm_local);

        run_test();
    end

endmodule : top

`endif