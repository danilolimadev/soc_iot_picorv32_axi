`ifndef SOC_ENV_SV
`define SOC_ENV_SV

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "soc_agent.sv"
    `include "soc_scoreboard.sv" 
    `include "soc_coverage.sv"

    class soc_env extends uvm_env;
        `uvm_component_utils(soc_env);

        soc_agent        agent_h;
        soc_scoreboard   scoreboard_h;
        soc_coverage     coverage_h;

        function new (string name, uvm_component parent);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            agent_h = soc_agent::type_id::create("agent_h", this);
            scoreboard_h = soc_scoreboard::type_id::create("scoreboard_h", this);
            coverage_h = soc_coverage::type_id::create("coverage_h", this);

        endfunction : build_phase

        // TODO: revisar
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);

            // Command Monitor's analysis port (ap) broadcasts to both Scoreboard and Coverage
            agent_h.monitor_h.ap.connect(scoreboard_h.analysis_export);
            agent_h.monitor_h.ap.connect(coverage_h.analysis_export);

            //  Monitor's analysis port (ap_response_cmd) broadcasts to the Scoreboard
            agent_h.monitor_h.ap_response_cmd.connect(scoreboard_h.response_export);

        endfunction : connect_phase
    endclass

`endif