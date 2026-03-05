`ifndef soc_transactions_SV
`define soc_transactions_SV

import uvm_pkg::*;    
    `include "uvm_macros.svh"

`include "soc_macros.svh"


// =============================================================================
// BOOTLOADER Transaction
// =============================================================================
class bootloader_transaction extends uvm_sequence_item;
    rand bit boot_mode;
    integer clock_cycles;
    
    `uvm_object_utils_begin(bootloader_transaction)
        `uvm_field_int(boot_mode,    UVM_ALL_ON)
        `uvm_field_int(clock_cycles, UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "bootloader_transaction");
        super.new(name);
    endfunction

endclass : bootloader_transaction


// =============================================================================
// UART Transaction
// =============================================================================
class uart_transaction extends uvm_sequence_item;
    bit [UART_DATA_BITS-1:0]      data;
    randc commands  data_sent;
    bit framing_error; // 1 se o bit de stop não for 1
    
    `uvm_object_utils_begin(uart_transaction)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(data_sent, UVM_ALL_ON)
        `uvm_field_int(framing_error, UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "uart_transaction");
        super.new(name);
    endfunction

endclass : uart_transaction


// =============================================================================
// GPIO Transaction
// =============================================================================
class gpio_transaction extends uvm_sequence_item;
    bit  [GPIO_DATA_BITS-1:0]     data;
    rand bit [GPIO_DATA_BITS-1:0] data_sent;
    
    `uvm_object_utils_begin(gpio_transaction)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(data_sent, UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "gpio_transaction");
        super.new(name);
    endfunction

endclass : gpio_transaction



// =============================================================================
// SPI Transactions
// =============================================================================
class spi_transaction extends uvm_sequence_item;
    bit [SPI_DATA_BITS-1:0]      data;
    string msg_received;
    rand commands  data_sent;
    
    `uvm_object_utils_begin(spi_transaction)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(data_sent, UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "spi_transaction");
        super.new(name);
    endfunction

endclass : spi_transaction


// =============================================================================
// I2C Transaction
// =============================================================================
class i2c_transaction extends uvm_sequence_item;
    logic [6:0] slave_addr;
    logic [I2C_DATA_BITS-1:0] data;
    logic rw; // 0 = DUT escreveu, 1 = DUT leu
    logic send_nack = 1'b0; // Se 1, o slave responde com NACK em vez de ACK (para teste de erro)
    
    `uvm_object_utils_begin(i2c_transaction)
        `uvm_field_int(slave_addr,  UVM_ALL_ON)
        `uvm_field_int(data,  UVM_ALL_ON)
        `uvm_field_int(rw,          UVM_ALL_ON)
        `uvm_field_int(send_nack,   UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "i2c_transaction");
        super.new(name);
    endfunction

endclass : i2c_transaction


// =============================================================================
// TIMER Transaction
// =============================================================================
class timer_transaction extends uvm_sequence_item;
    logic irq;
    
    `uvm_object_utils_begin(timer_transaction)
        `uvm_field_int(irq,  UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "timer_transaction");
        super.new(name);
    endfunction

endclass : timer_transaction


`endif // soc_transactions_SV