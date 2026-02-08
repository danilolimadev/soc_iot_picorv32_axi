`ifndef SOC_SEQUENCE_ITEM_SV
`define SOC_SEQUENCE_ITEM_SV

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class soc_sequence_item extends uvm_sequence_item;
        // TODO: quais valores serão enviados
        rand [WIDTH-1:0] init_value;
        
        function new(string name);
            super.new(name);
        endfunction : new
        
        function bit [WIDTH-1:0] get_random_init_value();
            assert(this.randomize());
            return this.init_value;
        endfunction

    endclass : soc_sequence_item

`endif