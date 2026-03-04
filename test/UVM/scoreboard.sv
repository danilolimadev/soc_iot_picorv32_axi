`ifndef SOC_SCOREBOARD_SV
`define SOC_SCOREBOARD_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "transaction.sv" 
`include "soc_macros.svh" 

// declaração dos sufixos para as analysis port de cada monitor
`uvm_analysis_imp_decl(_bootloader)
`uvm_analysis_imp_decl(_uart)
// `uvm_analysis_imp_decl(_spi)
// `uvm_analysis_imp_decl(_i2c)

class soc_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(soc_scoreboard)
    
    uvm_analysis_imp_bootloader #(bootloader_transaction, soc_scoreboard) bootloader_ap_imp;

    uvm_analysis_imp_uart #(uart_transaction, soc_scoreboard) uart_ap_tx_imp;
    uvm_tlm_analysis_fifo #(uart_transaction) uart_ap_rx_imp;

    // Statistics
    int uart_transaction_rx_count;
    int uart_transaction_tx_count;
    int spi_transaction_count;
    int i2c_transaction_count;
    int errors;
    int bootload_time;
    string msg_received = "";
    bit [UART_DATA_BITS-1:0] uart_cmd_sent;

    function new(string name = "soc_scoreboard", uvm_component parent = null);
        super.new(name, parent);

        bootloader_ap_imp    = new("bootloader_ap_imp", this);

        uart_ap_rx_imp   = new("uart_ap_rx_imp", this);
        uart_ap_tx_imp   = new("uart_ap_tx_imp", this);

        errors = 0;
        uart_transaction_rx_count = 0;
        uart_transaction_tx_count = 0;
        spi_transaction_count = 0;
        i2c_transaction_count = 0;
        bootload_time = 0;

        `uvm_info("SCOREBOARD", "NEW", UVM_LOW)
    endfunction : new

    // Bootloader check
    function void write_bootloader(bootloader_transaction item);
        //`uvm_info("SCOREBOARD", "Entrou no write bootloader", UVM_MEDIUM)
        bootload_time = item.clock_cycles;
        `uvm_info("SCOREBOARD", $sformatf( "Boot DONE em %0d ciclos", bootload_time), UVM_MEDIUM);
    endfunction

    // UART transaction check - algum dado foi enviado pela uart
    function void write_uart(uart_transaction item_tx);
        uart_transaction uart_rcv_item;
        
        int count = 0;
        //`uvm_info("SCOREBOARD", "Entrou no write uart", UVM_MEDIUM)
        uart_transaction_tx_count++;

        `uvm_info("SCOREBOARD", $sformatf("UART Transaction sent to DUT #%0d: Data=0x%0h", uart_transaction_tx_count, item_tx.data), UVM_MEDIUM)
        
        if (item_tx.framing_error)
        begin
            errors++;
        end
        else
        begin
            uart_cmd_sent = item_tx.data;
        end
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
    
    task run_phase(uvm_phase phase);
        uart_transaction uart_item;
        
        int count = 0;

        `uvm_info("SCOREBOARD", "Entrou no run phase", UVM_MEDIUM)
        forever
        begin
            // get() bloqueia automaticamente até ter dado na fila
            uart_ap_rx_imp.get(uart_item);
            check_msg_received(uart_item);
            uart_transaction_rx_count++;

            if (uart_cmd_sent == 0)
            begin
                // Receiving initial message
                count++;

                if (count >= INITIAL_MSG.len())
                begin
                    if (INITIAL_MSG !=  msg_received)
                    begin
                        errors++;
                        `uvm_info("SCOREBOARD", $sformatf("Esperado :%s.", INITIAL_MSG), UVM_MEDIUM);
                        `uvm_info("SCOREBOARD", $sformatf("Recebido :%s.", msg_received), UVM_MEDIUM);
                    end
                    `uvm_info("SCOREBOARD", $sformatf("Mensagem recebida sem erros: %s", msg_received), UVM_MEDIUM);
                    msg_received = "";
                    count = 0;
                end
            end
            else if (uart_cmd_sent == SEND_DATA_TO_UART)
            begin
                count++;

                `uvm_info("SCOREBOARD", $sformatf("Recebendo dados após comando: %h", uart_cmd_sent), UVM_MEDIUM);

                if (count >= MSG_TO_UART.len())
                begin
                    `uvm_info("SCOREBOARD", "Recebeu todos os caracteres", UVM_MEDIUM);
                    if (MSG_TO_UART !=  msg_received)
                    begin
                        errors++;
                        `uvm_info("SCOREBOARD", $sformatf("Esperado :%s.", MSG_TO_UART), UVM_MEDIUM);
                        `uvm_info("SCOREBOARD", $sformatf("Recebido :%s.", msg_received), UVM_MEDIUM);
                    end
                    `uvm_info("SCOREBOARD", $sformatf("Mensagem recebida sem erros: %s", msg_received), UVM_MEDIUM);
                    count = 0;
                    msg_received = "";
                end
                // buscar cada um dos protocolos e verificar se recebeu o esperado
            end
        end

        `uvm_info("SCOREBOARD", "Saiu do run phase", UVM_MEDIUM)
    endtask

    task check_msg_received(uart_transaction uart_item);
        if (!uart_item.framing_error)
        begin
            msg_received = {msg_received, bytes_to_string(uart_item.data)};
        end
        else
        begin
            errors++;
            `uvm_info("SCOREBOARD", "Erro no recebimento da msg", UVM_MEDIUM);
        end
    endtask

    function string bytes_to_string(logic [7:0] payload);
        string s = "";
        s = {s, string'(payload)};
        return s;
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("SCOREBOARD", "================= Scoreboard Report =================", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Bootloader:               %0d cycles", bootload_time), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Initial message received: %s", msg_received), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("UART write on DUT:        %0d transactions", uart_transaction_tx_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("UART read from DUT:       %0d transactions", uart_transaction_rx_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("SPI:                      %0d transactions", spi_transaction_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("I2C:                      %0d transactions", i2c_transaction_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Errors:                   %0d", errors), UVM_LOW)
        `uvm_info("SCOREBOARD", "===================================================", UVM_LOW)
        
        if(errors > 0)
            `uvm_error("SCOREBOARD", "TEST FAILED: Scoreboard reported mismatches.")
        else
            `uvm_info("SCOREBOARD", "Test completed with NO errors!", UVM_LOW)
    endfunction
endclass

`endif


