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
        
        env = soc_env::type_id::create("env", this);

    endfunction
    
    task run_phase(uvm_phase phase);
        `uvm_info("soc_base_test", "Starting base_test...", UVM_LOW)
    endtask
endclass : soc_base_test

// =============================================================================
// BOOTLOADER Focused Test
// =============================================================================
class soc_bootloader_test extends soc_base_test;
    `uvm_component_utils(soc_bootloader_test)
    
    function new(string name = "soc_bootloader_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        bootloader_seq seq;
        
        phase.raise_objection(this);
        
        seq = bootloader_seq::type_id::create("seq");
        seq.start(env.bootloader_agt.sequencer);
        
        #60ms;
        phase.drop_objection(this);
    endtask
endclass : soc_bootloader_test

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
        seq.start(env.uart_agt.sequencer);
        
        #10us;
        phase.drop_objection(this);
    endtask
endclass : soc_uart_test

// =============================================================================
// GPIO Focused Test
// =============================================================================
class soc_gpio_test extends soc_base_test;
    `uvm_component_utils(soc_gpio_test)
    
    function new(string name = "soc_gpio_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        gpio_seq seq;
        
        phase.raise_objection(this);
        
        seq = gpio_seq::type_id::create("seq");
        seq.start(env.gpio_agt.sequencer);
        
        #50us;
        phase.drop_objection(this);
    endtask
endclass : soc_gpio_test


// =============================================================================
// SPI Focused Test
// =============================================================================
class soc_spi_test extends soc_base_test;
    `uvm_component_utils(soc_spi_test)
    
    function new(string name = "soc_spi_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        spi_seq seq;
        
        phase.raise_objection(this);
        
        seq = spi_seq::type_id::create("seq");
        seq.start(env.spi_agt.sequencer);
        
        #10us;
        phase.drop_objection(this);
    endtask
endclass : soc_spi_test


// =============================================================================
// I2C Focused Test
// =============================================================================
class soc_i2c_test extends soc_base_test;
    `uvm_component_utils(soc_i2c_test)
    
    function new(string name = "soc_i2c_test", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("I2C TEST", "NEW", UVM_LOW)
    endfunction
    
    task run_phase(uvm_phase phase);
        i2c_seq seq;
        
        phase.raise_objection(this);
        
        seq = i2c_seq::type_id::create("seq");
        seq.start(env.i2c_agt.sequencer);
        
        #50us;
        phase.drop_objection(this);
    endtask
endclass : soc_i2c_test


// =============================================================================
// TIMER Test - Como não envia dados, não é necessário: consigo fazer uma seq sem enviar nada só para ver o funcionamento do Timer isolado?
// =============================================================================


// =============================================================================
// COMPLETE Focused Test
// =============================================================================
class soc_complete_test extends soc_base_test;
    `uvm_component_utils(soc_complete_test)
    
    function new(string name = "soc_complete_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        soc_virtual_seq seq;
        
        phase.raise_objection(this);
        
        seq = soc_virtual_seq::type_id::create("seq");
        seq.start(env.virtual_seqr);
        
        #10ms;
        phase.drop_objection(this);
    endtask
endclass : soc_complete_test

`endif // soc_test_SV