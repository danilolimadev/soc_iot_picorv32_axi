`ifndef SOC_SCOREBOARD_SV
`define SOC_SCOREBOARD_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "transaction.sv" 
`include "soc_macros.svh" 

// declaração dos sufixos para as analysis port de cada monitor
`uvm_analysis_imp_decl(_uart)
// `uvm_analysis_imp_decl(_spi)
// `uvm_analysis_imp_decl(_i2c)

class soc_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(soc_scoreboard)
    
    uvm_analysis_imp_uart #(uart_transaction, soc_scoreboard) uart_ap_tx_imp;
    uvm_tlm_analysis_fifo #(uart_transaction) uart_ap_rx_imp;

    // Statistics
    int uart_transaction_rx_count;
    int uart_transaction_tx_count;
    int spi_transaction_count;
    int i2c_transaction_count;
    int errors;
    
    function new(string name = "soc_scoreboard", uvm_component parent = null);
        super.new(name, parent);

        uart_ap_rx_imp   = new("uart_ap_rx_imp", this);
        uart_ap_tx_imp   = new("uart_ap_tx_imp", this);

        errors = 0;
        uart_transaction_rx_count = 0;
        uart_transaction_tx_count = 0;
        spi_transaction_count = 0;
        i2c_transaction_count = 0;

        `uvm_info("SCOREBOARD", "NEW", UVM_LOW)
    endfunction : new

    
    // UART transaction check - algum dado foi enviado pela uart
    function void write_uart(uart_transaction item_tx);
        uart_transaction_tx_count++;

        `uvm_info("SCOREBOARD", $sformatf("UART Transaction sent to DUT #%0d: Data=0x%0h", uart_transaction_tx_count, item_tx.data), UVM_MEDIUM)
        
        // buscar cada um dos protocolos e verificar se recebeu o esperado

    endfunction
    
    // // SPI transaction check
    // function void write_spi(spi_seq_item seq_item);
    //     spi_transaction_count++;
    //     `uvm_info(get_type_name(), $sformatf("SPI Transaction #%0d: MOSI=0x%0h MISO=0x%0h", 
    //               spi_transaction_count, seq_item.data_mosi, seq_item.data_miso), UVM_MEDIUM)
        
    //     // Add specific SPI checks here
    // endfunction
    
    // // checagem da i2c
    // function void write(i2c_transaction t);
    //     i2c_transaction_count++;

    //     `uvm_info(get_type_name(), $sformatf("I2C: #%0d: Addr=0x%0h Data=0x%0h", 
    //               i2c_transaction_count, t.slave_addr, t.data_bytes), UVM_MEDIUM)
        
    //     // // Check for ACK errors
    //     // if(t.ack_error)
    //     // begin
    //     //     errors++;
    //     //     `uvm_error(get_type_name(), "Erro de I2C ACK.")
    //     // end
        
    //     // // Verify data if needed
    //     // if(seq_item.num_bytes > 0)
    //     // begin
    //     //     `uvm_info(get_type_name(), $sformatf("Dados I2C: %p", seq_item.data_bytes), UVM_HIGH)
    //     // end
    // endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info(get_type_name(), "====== Scoreboard Report ======", UVM_LOW)
        //`uvm_info(get_type_name(), $sformatf("UART: %0d transações", uart_transaction_count), UVM_LOW)
        //`uvm_info(get_type_name(), $sformatf("SPI:  %0d transações", spi_transaction_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("I2C:  %0d transacoes", i2c_transaction_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total de erros:      %0d", errors), UVM_LOW)
        `uvm_info(get_type_name(), "===============================", UVM_LOW)
        
        if(errors > 0)
            `uvm_error(get_full_name(), "TEST FAILED: Scoreboard reported mismatches.")
        else
            `uvm_info(get_type_name(), "Test completed with NO errors!", UVM_LOW)
    endfunction
endclass

`endif


