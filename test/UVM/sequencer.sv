`ifndef SOC_SEQUENCER_SV
`define SOC_SEQUENCER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "transaction.sv"

// =============================================================================
// Virtual Sequencer
// =============================================================================
class soc_virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(soc_virtual_sequencer)

    // Handles para os sequencers reais
    uvm_sequencer #(bootloader_transaction) bootloader_seqr;
    uvm_sequencer #(uart_transaction)  uart_seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass


// =============================================================================
// BOOTLOADER Sequencer
// =============================================================================
class bootloader_sequencer extends uvm_sequencer #(bootloader_transaction);
    `uvm_component_utils(bootloader_sequencer)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

endclass


// =============================================================================
// UART Sequencer
// =============================================================================
class uart_sequencer extends uvm_sequencer #(uart_transaction);
    `uvm_component_utils(uart_sequencer)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

endclass


// =============================================================================
// GPIO Sequencer
// =============================================================================
class gpio_sequencer extends uvm_sequencer #(gpio_transaction);
    `uvm_component_utils(gpio_sequencer)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

endclass


// =============================================================================
// SPI Sequencer
// =============================================================================
class spi_sequencer extends uvm_sequencer #(spi_transaction);
    `uvm_component_utils(spi_sequencer)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

endclass


// =============================================================================
// I2C Sequencer
// =============================================================================
class i2c_sequencer extends uvm_sequencer #(i2c_transaction);
    `uvm_component_utils(i2c_sequencer)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

endclass


// =============================================================================
// TIMER Sequencer - Como não envia dados, não é necessário
// =============================================================================

`endif // SOC_SEQUENCER_SV