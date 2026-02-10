`ifndef SOC_AGENT_SV
`define SOC_AGENT_SV

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "soc_sequencer.sv"
    `include "soc_driver.sv"
    `include "soc_monitor.sv"

    class soc_agent extends uvm_agent;
        `uvm_component_utils(soc_agent)

        soc_sequencer sequencer_h;
        soc_driver    driver_h;
        soc_monitor   monitor_h;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active);

            if (is_active == UVM_ACTIVE)
            begin
                `uvm_info(get_full_name(), "Building ACTIVE agent: Driver and Sequencer included.", UVM_HIGH)
                sequencer_h = soc_sequencer::type_id::create("sequencer_h", this);
                driver_h    = soc_driver::type_id::create("driver_h", this);
            end 
            else
            begin
                `uvm_info(get_full_name(), "Building PASSIVE agent: Only Monitor included.", UVM_HIGH)
            end

            monitor_h = soc_monitor::type_id::create("monitor_h", this);

            if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", monitor_h.bfm))
            begin
                `uvm_fatal(get_full_name(), "Virtual interface 'bfm' not set for Monitor. Check environment build.")
            end

            if (is_active == UVM_ACTIVE)
            begin
                if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", driver_h.bfm))
                begin
                    `uvm_fatal(get_full_name(), "Virtual interface 'bfm' not set for Driver. Check environment build.")
                end
            end
        endfunction : build_phase

        // TODO: revisar
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            
            if (is_active == UVM_ACTIVE)
            begin
                driver_h.seq_item_port.connect(sequencer_h.seq_item_export);
                `uvm_info(get_full_name(), "Connected driver to sequencer.", UVM_MEDIUM)
            end
        endfunction : connect_phase

    endclass

`endif