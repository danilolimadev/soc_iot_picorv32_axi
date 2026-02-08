`ifndef SOC_DRIVER_SV
`define SOC_DRIVER_SV

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "soc_sequence_item.sv"

    class soc_driver extends uvm_driver #(soc_sequence_item);
        `uvm_component_utils(soc_driver)

        virtual soc_bfm bfm;
        
        // constructor
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            
            if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
                `uvm_fatal("DRIVER", "Failed to get BFM")
        endfunction : build_phase

        // run phase
        task run_phase(uvm_phase phase);
            soc_sequence_item req;

            fork 
                bfm.generate_clock(100_000_000); // 100 MHz clock
            join_any

            forever 
            begin
                seq_item_port.get_next_item(req);

                // TODO: quais valores serão enviados
                `uvm_info(get_full_name(), $sformatf("Driving soc values: 0x%h", req.init_value), UVM_LOW)

                // aqui: seguir o protocolo de comunicação com o DUT usando o BFM
                bfm.send_init_value(req.init_value);

                seq_item_port.item_done();
            end
        endtask : run_phase
        
    endclass

`endif