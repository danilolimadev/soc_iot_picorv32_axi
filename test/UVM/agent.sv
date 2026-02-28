`ifndef soc_agent_SV
`define soc_agent_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "sequencer.sv"
`include "driver.sv"
`include "monitor.sv"

// =============================================================================
// I2C Agent
// =============================================================================
class i2c_agent extends uvm_agent;
    `uvm_component_utils(i2c_agent)
    
    i2c_sequencer sequencer;
    i2c_driver    driver;
    i2c_monitor   monitor;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("I2C AGENT", "NEW", UVM_LOW)
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active);

        if (is_active == UVM_ACTIVE)
        begin
            sequencer = i2c_sequencer::type_id::create("sequencer", this);
            driver = i2c_driver::type_id::create("driver", this);
        end
        else
        begin
            `uvm_info("I2C AGENT", "Building PASSIVE I2C AGENT: Only Monitor included.", UVM_HIGH)
        end

        monitor = i2c_monitor::type_id::create("monitor", this);

        if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", monitor.bfm))
        begin
            `uvm_fatal("I2C AGENT", "Virtual interface 'bfm' not set for Monitor. Check environment build.")
        end

        if (is_active == UVM_ACTIVE)
        begin
            if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", driver.bfm))
            begin
                `uvm_fatal("I2C AGENT", "Virtual interface 'bfm' not set for Driver. Check environment build.")
            end
        end

        `uvm_info("I2C AGENT", "BUILD", UVM_LOW)
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (is_active == UVM_ACTIVE)
        begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
            `uvm_info("I2C AGENT", "Connected driver to sequencer.", UVM_MEDIUM)
        end
    endfunction : connect_phase

endclass : i2c_agent


// =============================================================================
// UART Agent
// =============================================================================
class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)
    
    uart_sequencer sequencer;
    uart_driver    driver;
    uart_monitor   monitor;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("UART AGENT", "NEW", UVM_LOW)
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active);

        if (is_active == UVM_ACTIVE)
        begin
            sequencer = uart_sequencer::type_id::create("sequencer", this);
            driver = uart_driver::type_id::create("driver", this);
        end
        else
        begin
            `uvm_info("UART AGENT", "Building PASSIVE UART AGENT: Only Monitor included.", UVM_HIGH)
        end

        monitor = uart_monitor::type_id::create("monitor", this);

        if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", monitor.bfm))
        begin
            `uvm_fatal("UART AGENT", "Virtual interface 'bfm' not set for Monitor. Check environment build.")
        end

        if (is_active == UVM_ACTIVE)
        begin
            if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", driver.bfm))
            begin
                `uvm_fatal("UART AGENT", "Virtual interface 'bfm' not set for Driver. Check environment build.")
            end
        end

        `uvm_info("UART AGENT", "BUILD", UVM_LOW)
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (is_active == UVM_ACTIVE)
        begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
            `uvm_info("UART AGENT", "Connected driver to sequencer.", UVM_MEDIUM)
        end
    endfunction : connect_phase

endclass : uart_agent

`endif // soc_agent_SV