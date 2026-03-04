`ifndef soc_env_SV
`define soc_env_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "agent.sv"
`include "scoreboard.sv" 
`include "coverage.sv"

class soc_env extends uvm_env;
    `uvm_component_utils(soc_env)
    
    bootloader_agent bootloader_agt;
    // i2c_agent  i2c_agt;
    uart_agent uart_agt;
    // spi_agent  spi_agt;
    
    soc_scoreboard scoreboard;

    bootloader_coverage bootloader_cvg;
    //i2c_coverage   i2c_coverage;
    uart_coverage   uart_cvg;
    //spi_coverage   spi_coverage;

    soc_virtual_sequencer virtual_seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("ENV", "NEW", UVM_LOW)
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create agents
        bootloader_agt = bootloader_agent::type_id::create("bootloader_agt", this);
        // i2c_agt  = i2c_agent::type_id::create("i2c_agt", this);
        uart_agt = uart_agent::type_id::create("uart_agt", this);
        // spi_agt  = spi_agent::type_id::create("spi_agt", this);
        
        // Set agents to active
        uvm_config_db#(uvm_active_passive_enum)::set(this, "bootloader_agt", "is_active", UVM_ACTIVE);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "uart_agt", "is_active", UVM_ACTIVE);
        // uvm_config_db#(uvm_active_passive_enum)::set(this, "spi_agt", "is_active", UVM_ACTIVE);
        // uvm_config_db#(uvm_active_passive_enum)::set(this, "i2c_agt", "is_active", UVM_ACTIVE);
        
        // Create scoreboard and coverage
        scoreboard = soc_scoreboard::type_id::create("scoreboard", this);
        
        bootloader_cvg  = bootloader_coverage::type_id::create("bootloader_cvg", this);
        //i2c_coverage   = i2c_coverage::type_id::create("i2c_coverage", this);
        uart_cvg  = uart_coverage::type_id::create("uart_cvg", this);
        //spi_coverage   = spi_coverage::type_id::create("spi_coverage", this);

        virtual_seqr  = soc_virtual_sequencer::type_id::create("virtual_seqr", this);

        `uvm_info("ENV", "BUILD", UVM_LOW)

    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        bootloader_agt.monitor.ap.connect(scoreboard.bootloader_ap_imp);
        bootloader_agt.monitor.ap.connect(bootloader_cvg.analysis_export);

        // i2c_agt.monitor.ap.connect(scoreboard.analysis_export);
        // i2c_agt.monitor.ap.connect(i2c_coverage.analysis_export);

        uart_agt.monitor.ap_rx.connect(scoreboard.uart_ap_rx_imp.analysis_export);
        uart_agt.monitor.ap_tx.connect(scoreboard.uart_ap_tx_imp);

        uart_agt.monitor.ap_tx.connect(uart_cvg.analysis_export);

        // Conecta os sequencers reais ao virtual sequencer
        virtual_seqr.bootloader_seqr = bootloader_agt.sequencer;
        virtual_seqr.uart_seqr       = uart_agt.sequencer;

    endfunction
endclass : soc_env

`endif // soc_env_SV
