`ifndef SOC_SEQUENCER_SV
`define SOC_SEQUENCER_SV

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "soc_sequence_item.sv"

    class soc_sequencer extends uvm_sequencer #(soc_sequence_item);
        `uvm_component_utils(soc_sequencer)

        function new (string name, uvm_component parent);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
        endfunction : build_phase

    endclass

`endif