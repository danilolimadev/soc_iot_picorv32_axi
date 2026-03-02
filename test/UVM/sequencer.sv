`ifndef SOC_SEQUENCER_SV
`define SOC_SEQUENCER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "transaction.sv"

class i2c_sequencer extends uvm_sequencer #(i2c_transaction);
    `uvm_component_utils(i2c_sequencer)

    function new (string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("I2C SEQUENCER", "NEW", UVM_LOW)
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("I2C SEQUENCER", "BUILD", UVM_LOW)
    endfunction : build_phase

endclass

class uart_sequencer extends uvm_sequencer #(uart_transaction);
    `uvm_component_utils(uart_sequencer)

    function new (string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("UART SEQUENCER", "NEW", UVM_LOW)
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("UART SEQUENCER", "BUILD", UVM_LOW)
    endfunction : build_phase

endclass

`endif // SOC_SEQUENCER_SV