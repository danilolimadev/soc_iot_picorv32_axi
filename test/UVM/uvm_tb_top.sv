`timescale 1ns/10ps
import soc_pkg::*;
`include "soc_pkg.sv"
`include "soc_test.sv"

module uvm_tb_top;
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   import soc_pkg::*;
   
   soc_bfm  bfm();

    soc_bootloader_complete DUT(
        .clk       (bfm.clk),
        .resetn    (bfm.resetn),
        .boot_mode (bfm.boot_mode),
        .boot_done (bfm.boot_done),
        .trap      (bfm.trap),
        .gpio_out  (bfm.gpio_out),
        .timer_irq (bfm.timer_irq),
        .uart_tx   (bfm.uart_rx),
        .uart_rx   (bfm.uart_tx),
        .spi_mosi  (bfm.spi_mosi),
        .spi_miso  (bfm.spi_miso),
        .spi_sck   (bfm.spi_sck),
        .spi_cs    (bfm.spi_cs),
        .i2c_sda   (bfm.i2c_sda),
        .i2c_scl   (bfm.i2c_scl)
    );

    initial
    begin
        `uvm_info("TOP", "TOP UVM", UVM_MEDIUM)
        uvm_config_db #(virtual soc_bfm)::set(null, "*", "bfm", bfm);

        $dumpfile("uvm_tb_top.vcd");
        $dumpvars(0, uvm_tb_top);

        run_test();
    end

    initial
    begin
        fork
        bfm.uart_tx = 1; // garantir que inicialmente está em 1
        bfm.generate_clock(CLK_PERIOD);
        bfm.reset_pulse(0, 5, "Sync", 1);
        join_none
    end
    
endmodule : uvm_tb_top
