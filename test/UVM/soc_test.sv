`ifndef SOC_TEST
`define SOC_TEST

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "soc_env.sv"
    `include "soc_sequence.sv"

    class soc_test extends uvm_test;
        `uvm_component_utils(soc_test)

        soc_env env_h;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            
            uvm_config_db#(uvm_active_passive_enum)::set(this, "env_h.agent_h", "is_active", UVM_ACTIVE);
            env_h = soc_env::type_id::create("env_h", this);

        endfunction : build_phase

        task run_phase(uvm_phase phase);

            soc_sequence seq_h;

            phase.raise_objection(this);
            
            seq_h = soc_sequence::type_id::create("seq_h");
            `uvm_info(get_full_name(), "Starting soc_sequence on sequencer...", UVM_LOW)

            seq_h.start(env_h.agent_h.sequencer_h);
            #100ns;

            phase.drop_objection(this);
        endtask : run_phase
        
    endclass

`endif