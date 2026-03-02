`ifndef soc_transactions_SV
`define soc_transactions_SV

import uvm_pkg::*;    
    `include "uvm_macros.svh"

`include "soc_macros.svh"

class i2c_transaction extends uvm_sequence_item;
    logic [6:0] slave_addr = I2C_ADDRESS;
    logic [7:0] data_bytes;
    logic rw; // 0 = DUT escreveu, 1 = DUT leu
    logic send_nack = 1'b0; // Se 1, o slave responde com NACK em vez de ACK (para teste de erro)
    
    `uvm_object_utils_begin(i2c_transaction)
        `uvm_field_int(slave_addr,  UVM_ALL_ON)
        `uvm_field_int(data_bytes,        UVM_ALL_ON)
        `uvm_field_int(rw,          UVM_ALL_ON)
        `uvm_field_int(send_nack,   UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "i2c_transaction");
        super.new(name);
        `uvm_info("I2C TRANSACTION", "NEW", UVM_LOW)
    endfunction

    function string convert2string();
        return $sformatf("SLAVE_ADDR=0x%02X DATA=0x%02X DIR=%s NACK=%b",
                        slave_addr, data_bytes,
                        rw ? "DUT_READ" : "DUT_WRITE",
                        send_nack);
    endfunction

endclass : i2c_transaction


class uart_transaction extends uvm_sequence_item;
    bit [UART_DATA_BITS-1:0]      data;
    rand commands  data_sent;
    bit framing_error; // 1 se o bit de stop não for 1
    
    `uvm_object_utils_begin(uart_transaction)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(data_sent,     UVM_ALL_ON)
        `uvm_field_int(framing_error,  UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "uart_transaction");
        super.new(name);
        `uvm_info("UART TRANSACTION", "NEW", UVM_LOW)
    endfunction

endclass : uart_transaction

`endif // soc_transactions_SV