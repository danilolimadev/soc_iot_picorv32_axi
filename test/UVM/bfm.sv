`ifndef SOC_BFM_SV
`define SOC_BFM_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

interface soc_bfm;
    
    bit resetn;
    bit clk;

    // Bootloader Signals
    bit boot_done;
    bit boot_mode;

    // Debug signals
    bit        trap;
    bit [31:0] gpio_out;
    bit        timer_irq;
    
    // UART signals
    bit        uart_rx; // Soc escreve para UVM
    bit        uart_tx; // UVM escreve para Soc
    
    // SPI signals
    bit        spi_mosi;
    bit        spi_miso;
    bit        spi_sck;
    bit        spi_cs;
    
    // I2C signals
    wire       i2c_scl; // só o soc (master) controla o clock

    wire       i2c_sda;
    bit        i2c_sda_oe;
    bit        i2c_sda_out;
    assign i2c_sda = i2c_sda_oe ? i2c_sda_out : 1'bz;

    function automatic logic resolve(logic sig);
        return (sig === 1'bz) ? 1'b1 : sig;
    endfunction

    // task to generate clock signal
    task generate_clock(input real period = 20, bit clk_pol = 0, real delay = 0);
        clk = ~clk_pol;
        #(delay);

        forever
		begin
            clk = ~clk;
            #(period/2);
        end

    endtask : generate_clock

    // task to generate reset pulse
    task reset_pulse(input bit rst_pol = '0, int rst_width = 2, string rst_type = "Sync", bit rst_edge = 1);
      	if (rst_type == "Sync")
		begin
        	if (rst_edge)
            	@(posedge clk);
         	else
            	@(negedge clk);
      	end
      	resetn = rst_pol;

        if (rst_type == "Async")
        begin 
            #(rst_width);
        end
        else
        begin
            repeat (rst_width)
            begin
                if (rst_edge)
                    @(posedge clk);
                else
                    @(negedge clk);
            end
        end
        resetn = ~rst_pol;
        
    endtask : reset_pulse

endinterface

`endif // SOC_BFM_SV