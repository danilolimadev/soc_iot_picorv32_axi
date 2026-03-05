`ifndef SOC_COVERAGE_SV
`define SOC_COVERAGE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "soc_macros.svh"
`include "transaction.sv"


// =============================================================================
// BOOTLOADER Coverage
// =============================================================================
class bootloader_coverage extends uvm_subscriber #(bootloader_transaction);
    `uvm_component_utils(bootloader_coverage)

    protected bit boot_mode;

    covergroup bootloader_cg;
        cp_mode: coverpoint boot_mode {
            bins valid_data[] = {1'b1};
        }        
    endgroup
    
    function new(string name = "bootloader_coverage", uvm_component parent);
        super.new(name, parent);
        bootloader_cg = new();
    endfunction
    
    function void write(bootloader_transaction t);
        boot_mode = t.boot_mode;
        bootloader_cg.sample();
        `uvm_info("BOOTLOADER COVERAGE", $sformatf("Sampled Data: 0x%h", t.boot_mode), UVM_HIGH)
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("BOOTLOADER COVERAGE", $sformatf("--- COVERAGE REPORT ---\n Data Coverage: %f%%\n", bootloader_cg.get_coverage()), UVM_LOW)
    endfunction

endclass : bootloader_coverage


// =============================================================================
// UART Coverage
// =============================================================================
class uart_coverage extends uvm_subscriber #(uart_transaction);
    `uvm_component_utils(uart_coverage)

    protected commands current_command;

    covergroup uart_cg;
        option.per_instance = 1;
        command_cp : coverpoint current_command {
            bins all_cmds[] = { SEND_DATA_TO_GPIO,
                                SEND_DATA_TO_SPI,
                                SEND_DATA_TO_I2C,
                                SEND_DATA_TO_UART
                            };
        }
    endgroup

    function new(string name = "uart_coverage", uvm_component parent);
        super.new(name, parent);
        uart_cg = new();
    endfunction
    
    function void write(uart_transaction t);
        current_command = t.data_sent;
        uart_cg.sample();
        `uvm_info("UART COVERAGE", $sformatf("Sampled Data: 0x%h", t.data_sent), UVM_HIGH)
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("UART COVERAGE", $sformatf("--- COVERAGE REPORT ---\n Data Coverage: %f%%\n", uart_cg.get_coverage()), UVM_LOW)
    endfunction

endclass : uart_coverage


// =============================================================================
// GPIO Coverage
// =============================================================================
class gpio_coverage extends uvm_subscriber #(gpio_transaction);
    `uvm_component_utils(gpio_coverage)

    protected bit [31:0]  data_bytes;

    covergroup gpio_cg;
        cp_data: coverpoint data_bytes {
            bins valid_data[] = {[8'h00:8'hFF]};
        }
    endgroup
    
    function new(string name = "gpio_coverage", uvm_component parent);
        super.new(name, parent);
        gpio_cg = new();
    endfunction
    
    function void write(gpio_transaction t);
        data_bytes = t.data;
        gpio_cg.sample();
        //`uvm_info("GPIO COVERAGE", $sformatf("Sampled Data: 0x%h", t.data_sent), UVM_HIGH)
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        //`uvm_info("GPIO COVERAGE", $sformatf("--- COVERAGE REPORT ---\n Data Coverage: %f%%\n", gpio_cg.get_coverage()), UVM_LOW)
    endfunction

endclass : gpio_coverage


// =============================================================================
// SPI Coverage
// =============================================================================
class spi_coverage extends uvm_subscriber #(spi_transaction);
    `uvm_component_utils(spi_coverage)

    protected bit [7:0]  data_bytes;

    covergroup spi_cg;
        cp_data: coverpoint data_bytes {
            bins valid_data[] = {[8'h00:8'hFF]};
        }        
    endgroup
    
    function new(string name = "spi_coverage", uvm_component parent);
        super.new(name, parent);
        spi_cg = new();
    endfunction
    
    function void write(spi_transaction t);
        data_bytes = t.data_sent;
        spi_cg.sample();
        //`uvm_info("SPI COVERAGE", $sformatf("Sampled Data: 0x%h", t.data_sent), UVM_HIGH)
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        //`uvm_info("SPI COVERAGE", $sformatf("--- COVERAGE REPORT ---\n Data Coverage: %f%%\n", spi_cg.get_coverage()), UVM_LOW)
    endfunction

endclass : spi_coverage


// =============================================================================
// I2C Coverage
// =============================================================================
class i2c_coverage extends uvm_subscriber #(i2c_transaction);
    `uvm_component_utils(i2c_coverage)

    protected bit [7:0]  data_bytes;

    covergroup i2c_cg;
        cp_data: coverpoint data_bytes {
            bins valid_data[] = {[8'h00:8'hFF]};
        }        
    endgroup
    
    function new(string name = "i2c_coverage", uvm_component parent);
        super.new(name, parent);
        i2c_cg = new();
    endfunction
    
    function void write(i2c_transaction t);
        data_bytes = t.data;
        i2c_cg.sample();
        //`uvm_info("I2C COVERAGE", $sformatf("Sampled Data: 0x%h", t.data), UVM_HIGH)
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        //`uvm_info("I2C COVERAGE", $sformatf("--- COVERAGE REPORT ---\n Data Coverage: %f%%\n", i2c_cg.get_coverage()), UVM_LOW)
    endfunction

endclass : i2c_coverage


// =============================================================================
// TIMER Coverage - Como não envia dados, não é necessário
// =============================================================================

`endif // SOC_COVERAGE_SV