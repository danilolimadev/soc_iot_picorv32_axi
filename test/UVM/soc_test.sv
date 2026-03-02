`ifndef soc_test_SV
`define soc_test_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "environment.sv"
`include "sequence.sv"

// =============================================================================
// Base Test
// =============================================================================
class soc_base_test extends uvm_test;
    `uvm_component_utils(soc_base_test)
    
    soc_env env;
    
    function new(string name = "soc_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create environment
        env = soc_env::type_id::create("env", this);

    endfunction
    
    task run_phase(uvm_phase phase);
        `uvm_info("soc_base_test", "Starting base_test...", UVM_LOW)
    endtask
endclass : soc_base_test

// =============================================================================
// UART Focused Test
// =============================================================================
class soc_uart_test extends soc_base_test;
    `uvm_component_utils(soc_uart_test)
    
    function new(string name = "soc_uart_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        uart_seq seq;
        
        phase.raise_objection(this);
        
        seq = uart_seq::type_id::create("seq");
        `uvm_info("UART TEST", "Starting uart_sequence on sequencer...", UVM_LOW)
        seq.start(env.uart_agt.sequencer);
        
        #10us;
        phase.drop_objection(this);
    endtask
endclass : soc_uart_test

// // =============================================================================
// // I2C Focused Test
// // =============================================================================
// class soc_i2c_test extends soc_base_test;
//     `uvm_component_utils(soc_i2c_test)
    
//     function new(string name = "soc_i2c_test", uvm_component parent = null);
//         super.new(name, parent);
//         `uvm_info("I2C TEST", "NEW", UVM_LOW)
//     endfunction
    
//     task run_phase(uvm_phase phase);
//         i2c_slave_seq seq;
        
//         `uvm_info("I2C TEST", "RUN: started", UVM_LOW);

//         phase.raise_objection(this);
        
//         seq = i2c_slave_seq::type_id::create("seq");
//         `uvm_info("I2C TEST", "criou seqeunce", UVM_LOW);

//         seq.start(env.i2c_agt.sequencer);
//         `uvm_info("I2C TEST", "started", UVM_LOW);
//         #5us;
//         phase.drop_objection(this);

//         `uvm_info("I2C TEST", "RUN: finished", UVM_LOW)
//     endtask
// endclass : soc_i2c_test

`endif // soc_test_SV