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
    uart_agent       uart_agt;
    gpio_agent       gpio_agt;
    spi_agent        spi_agt;
    i2c_agent        i2c_agt;
    timer_agent      timer_agt;

    soc_scoreboard scoreboard;

    bootloader_coverage bootloader_cvg;
    uart_coverage       uart_cvg;
    gpio_coverage       gpio_cvg;
    spi_coverage        spi_cvg;
    i2c_coverage        i2c_cvg;

    soc_virtual_sequencer virtual_seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        bootloader_agt = bootloader_agent::type_id::create("bootloader_agt", this);
        uart_agt       = uart_agent::type_id::create("uart_agt", this);
        gpio_agt       = gpio_agent::type_id::create("gpio_agt", this);
        spi_agt        = spi_agent::type_id::create("spi_agt", this);
        i2c_agt        = i2c_agent::type_id::create("i2c_agt", this);
        timer_agt      = timer_agent::type_id::create("timer_agt", this);

        uvm_config_db#(uvm_active_passive_enum)::set(this, "bootloader_agt", "is_active", UVM_ACTIVE);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "uart_agt",       "is_active", UVM_ACTIVE);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "gpio_agt",       "is_active", UVM_PASSIVE);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "spi_agt",        "is_active", UVM_PASSIVE);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "i2c_agt",        "is_active", UVM_ACTIVE);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "timer_agt",      "is_active", UVM_ACTIVE);

        scoreboard = soc_scoreboard::type_id::create("scoreboard", this);
        
        bootloader_cvg = bootloader_coverage::type_id::create("bootloader_cvg", this);
        uart_cvg = uart_coverage::type_id::create("uart_cvg", this);
        gpio_cvg = gpio_coverage::type_id::create("gpio_cvg", this);
        spi_cvg  = spi_coverage::type_id::create("spi_cvg", this);
        i2c_cvg   = i2c_coverage::type_id::create("i2c_cvg", this);

        virtual_seqr  = soc_virtual_sequencer::type_id::create("virtual_seqr", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        bootloader_agt.monitor.ap.connect(scoreboard.bootloader_ap_imp);
        bootloader_agt.monitor.ap.connect(bootloader_cvg.analysis_export);

        uart_agt.monitor.ap_rx.connect(scoreboard.uart_ap_rx_imp.analysis_export);
        uart_agt.monitor.ap_tx.connect(scoreboard.uart_ap_tx_imp);
        uart_agt.monitor.ap_tx.connect(uart_cvg.analysis_export);

        gpio_agt.monitor.ap.connect(scoreboard.gpio_ap_imp);
        gpio_agt.monitor.ap.connect(gpio_cvg.analysis_export);

        spi_agt.monitor.ap_mosi.connect(scoreboard.spi_ap_mosi_imp.analysis_export);
        spi_agt.monitor.ap_miso.connect(scoreboard.spi_ap_miso_imp);
        spi_agt.monitor.ap_miso.connect(spi_cvg.analysis_export);

        i2c_agt.monitor.ap.connect(scoreboard.i2c_ap_imp);
        i2c_agt.monitor.ap.connect(i2c_cvg.analysis_export);

        timer_agt.monitor.ap.connect(scoreboard.timer_ap_imp);


        // Conecta os sequencers reais ao virtual sequencer
        virtual_seqr.bootloader_seqr = bootloader_agt.sequencer;
        virtual_seqr.uart_seqr       = uart_agt.sequencer;

    endfunction
endclass : soc_env

`endif // soc_env_SV
