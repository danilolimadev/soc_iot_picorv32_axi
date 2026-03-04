`ifndef SOC_COVERAGE_SV
`define SOC_COVERAGE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "soc_macros.svh"
`include "transaction.sv"

class i2c_coverage extends uvm_subscriber #(i2c_transaction);
    `uvm_component_utils(i2c_coverage)

    protected bit [7:0]  data_bytes;

    // o que mais preciso conferir? 
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
        data_bytes = t.data_bytes;
        i2c_cg.sample();
        `uvm_info(get_full_name(), $sformatf("Sampled Data: 0x%h", t.data_bytes), UVM_HIGH)
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_full_name(), $sformatf("--- COVERAGE REPORT ---\n Data Coverage: %f%%\n", i2c_cg.get_coverage()), UVM_LOW)
    endfunction

endclass : i2c_coverage

class uart_coverage extends uvm_subscriber #(uart_transaction);
    `uvm_component_utils(uart_coverage)

    protected bit [UART_DATA_BITS-1:0]  data_bytes;

    // o que mais preciso conferir? 
    covergroup uart_cg; 
        option.per_instance = 1;
        command_cp : coverpoint data_bytes {
            bins all_cmds[] = {
                                //SEND_DATA_TO_I2C,
                                //SEND_DATA_TO_SPI,
                                SEND_DATA_TO_UART//,
                                //SEND_DATA_TO_GPIO
                            };
        }      
    endgroup

    function new(string name = "uart_coverage", uvm_component parent);
        super.new(name, parent);
        uart_cg = new();
    endfunction
    
    function void write(uart_transaction t);
        data_bytes = t.data_sent;
        uart_cg.sample();
        `uvm_info(get_full_name(), $sformatf("Sampled Data: 0x%h", t.data_sent), UVM_HIGH)
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_full_name(), $sformatf("--- COVERAGE REPORT ---\n Data Coverage: %f%%\n", uart_cg.get_coverage()), UVM_LOW)
    endfunction

endclass : uart_coverage

class bootloader_coverage extends uvm_subscriber #(bootloader_transaction);
    `uvm_component_utils(bootloader_coverage)

    protected bit boot_mode;

    // o que mais preciso conferir? 
    covergroup bootloader_cg;
        cp_mode: coverpoint boot_mode {
            bins valid_data[] = {[1'b0: 1'b1]};
        }        
    endgroup
    
    function new(string name = "bootloader_coverage", uvm_component parent);
        super.new(name, parent);
        bootloader_cg = new();
    endfunction
    
    function void write(bootloader_transaction t);
        boot_mode = t.boot_mode;
        bootloader_cg.sample();
        `uvm_info(get_full_name(), $sformatf("Sampled Data: 0x%h", t.boot_mode), UVM_HIGH)
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_full_name(), $sformatf("--- COVERAGE REPORT ---\n Data Coverage: %f%%\n", bootloader_cg.get_coverage()), UVM_LOW)
    endfunction

endclass : bootloader_coverage

`endif // SOC_COVERAGE_SV