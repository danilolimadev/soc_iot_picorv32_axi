`ifndef SOC_SEQUENCE_SV
`define SOC_SEQUENCE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "soc_sequence_item.sv"

class soc_sequence extends uvm_sequence #(soc_sequence_item);
    `uvm_object_utils(soc_sequence);

    function new(string name);
        super.new(name);
    endfunction : new

    task body;
        soc_sequence_item req;

        if (starting_phase != null) 
        begin
            starting_phase.raise_objection(this);
        end

        `uvm_info(get_full_name(), "Starting 10 random soc commands", UVM_LOW)
        
        repeat (10) 
        begin
            req = soc_sequence_item::type_id::create("req");
            start_item(req);
            req.init_value = req.get_random_init_value(); 
            `uvm_info(get_full_name(), $sformatf("Sending init_value: 0x%h", req.init_value), UVM_MEDIUM)
            finish_item(req);
        end
        
        if (starting_phase != null) 
        begin
            starting_phase.drop_objection(this);
        end
    endtask : body

endclass

`endif