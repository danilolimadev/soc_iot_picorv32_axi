`ifndef soc_env_SV
`define soc_env_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "agent.sv"
`include "scoreboard.sv" 
`include "coverage.sv"

class soc_env extends uvm_env;
    `uvm_component_utils(soc_env)
    
    // i2c_agent  i2c_agt;
    uart_agent uart_agt;
    // spi_agent  spi_agt;
    
    soc_scoreboard scoreboard;

    //i2c_coverage   i2c_coverage;
    uart_coverage   uart_cvg;
    //spi_coverage   spi_coverage;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("ENV", "NEW", UVM_LOW)
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create agents
        // i2c_agt  = i2c_agent::type_id::create("i2c_agt", this);
        uart_agt = uart_agent::type_id::create("uart_agt", this);
        // spi_agt  = spi_agent::type_id::create("spi_agt", this);        
        
        // Set agents to active
        uvm_config_db#(uvm_active_passive_enum)::set(this, "uart_agt", "is_active", UVM_ACTIVE);
        // uvm_config_db#(uvm_active_passive_enum)::set(this, "spi_agt", "is_active", UVM_ACTIVE);
        // uvm_config_db#(uvm_active_passive_enum)::set(this, "i2c_agt", "is_active", UVM_ACTIVE);
        
        // Create scoreboard and coverage
        scoreboard = soc_scoreboard::type_id::create("scoreboard", this);
        
        //i2c_coverage   = i2c_coverage::type_id::create("i2c_coverage", this);
        uart_cvg  = uart_coverage::type_id::create("uart_cvg", this);
        //spi_coverage   = spi_coverage::type_id::create("spi_coverage", this);

        `uvm_info("ENV", "BUILD", UVM_LOW)

    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // i2c_agt.monitor.ap.connect(scoreboard.analysis_export);
        // i2c_agt.monitor.ap.connect(i2c_coverage.analysis_export);

        uart_agt.monitor.ap_rx.connect(scoreboard.uart_ap_rx_imp.analysis_export);
        uart_agt.monitor.ap_tx.connect(scoreboard.uart_ap_tx_imp);

        uart_agt.monitor.ap_tx.connect(uart_cvg.analysis_export);

    endfunction
endclass : soc_env

`endif // soc_env_SV
