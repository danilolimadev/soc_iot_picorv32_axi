`ifndef SOC_MONITOR_SV
`define SOC_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "soc_macros.svh"
`include "transaction.sv"

// =============================================================================
// I2C Monitor
// =============================================================================
class i2c_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_monitor)
    
    virtual soc_bfm bfm;
    uvm_analysis_port #(i2c_transaction) ap;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);

        `uvm_info("I2C MONITOR", "NEW", UVM_LOW)

    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_warning("I2C_MON", "Virtual interface `bfm` not found via uvm_config_db. Check config_db::set path.")

        `uvm_info("I2C MONITOR", "BUILD", UVM_LOW)

    endfunction
    
    task run_phase(uvm_phase phase);
        `uvm_info("I2C MONITOR", "RUN: started", UVM_LOW);
        forever
        begin            
            i2c_transaction transaction;
            transaction = i2c_transaction::type_id::create("transaction");

            monitor_i2c_transaction(transaction); // pega os mdados da BFM

            ap.write(transaction);
        end

        `uvm_info("I2C MONITOR", "RUN: finished", UVM_LOW)
    endtask
    
    task decode_byte(bit [7:0] data_byte);
        // decode 8 bits
        for(int i = 7; i >= 0; i--)
        begin
            @(posedge bfm.i2c_scl);
            data_byte[i] = bfm.i2c_sda;
        end

        // ack
        @(posedge bfm.i2c_scl);
        // reponder o ack
    endtask

    task detect_stop(output bit stop_flag);
        forever
        begin
            @(posedge bfm.i2c_sda);
            if (bfm.i2c_scl == 1'b1)
                stop_flag = 1'b1;
            else
                stop_flag = 1'b0;
        end
    endtask

    task monitor_i2c_transaction(i2c_transaction transaction);
        bit [7:0] addr_byte;
        bit [7:0] data_byte;
        bit       stop_flag = 1'b0;

        wait_for_start();

        // Capture address byte
        decode_byte(addr_byte);
        
        transaction.slave_addr = addr_byte[7:1];
        transaction.rw = addr_byte[0];
        
        // Capture data bytes until STOP
        while(!stop_flag)
        begin
            
            fork
                decode_byte(data_byte);
                // colocar na transaco
                detect_stop(stop_flag);
            join_any
            disable fork;

            transaction.data_bytes = data_byte;
        end
        
        `uvm_info(get_type_name(), $sformatf("Monitored I2C: Addr=0x%0h", 
                  transaction.slave_addr), UVM_MEDIUM)
    endtask

    task wait_for_start();
        bit start_detected = 0;   // flag compartilhada entre as threads
        fork
        begin
            @(posedge bfm.i2c_scl);

            // Aguarda SDA descer com SCL alto = START
            forever
            begin
                @(negedge bfm.i2c_sda);
                if (bfm.i2c_scl === 1'b1)
                begin
                    start_detected = 1;
                    `uvm_info("I2C DRIVER", "START detectado da DUT", UVM_HIGH)
                    break;
                end
            end
        end

        // Aguarda START_TIMEOUT unidades de tempo; se a DUT não gerar START nesse intervalo, a simulação é encerrada com uvm_fatal.
        // begin
        //     #(START_TIMEOUT);
        //     if (!start_detected)
        //     begin
        //         `uvm_fatal("I2C DRIVER", $sformatf("TIMEOUT: DUT não gerou condição de START após %0t ps. ", START_TIMEOUT))
        //     end
        // end
        join_any
        
        disable fork;

    endtask

endclass : i2c_monitor

// =============================================================================
// UART Monitor
// =============================================================================
class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)
    
    virtual soc_bfm bfm;
    uvm_analysis_port #(uart_transaction) ap_rx;
    uvm_analysis_port #(uart_transaction) ap_tx;

    function new(string name, uvm_component parent);
        super.new(name, parent);

        ap_rx = new("ap_rx", this);
        ap_tx = new("ap_tx", this);

        `uvm_info("UART MONITOR", "NEW", UVM_LOW)
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_warning("UART_MON", "Virtual interface `bfm` not found via uvm_config_db. Check config_db::set path.")

        `uvm_info("UART MONITOR", "BUILD", UVM_LOW)
    endfunction
    
    task run_phase(uvm_phase phase);
        `uvm_info("UART MONITOR", "RUN: started", UVM_LOW);
        
        fork
            uart_transaction transaction_rx, transaction_tx;
            bit [UART_DATA_BITS-1:0] data_byte_rx, data_byte_tx;
            bit erro_rx, erro_tx;

            monitor_uart(1'b0, data_byte_rx, erro_rx); // DUT enviando para UART

            transaction_rx = uart_transaction::type_id::create("transaction_rx");
            transaction_rx.data = data_byte_rx;
            transaction_rx.framing_error = erro_rx;

            ap_rx.write(transaction_rx);
            `uvm_info("UART MONITOR", $sformatf("Data received from DUT=0x%02X", transaction_rx.data), UVM_MEDIUM)


            monitor_uart(1'b1, data_byte_tx, erro_tx); // UART enviando para DUT

            transaction_tx = uart_transaction::type_id::create("transaction_tx");
            transaction_tx.data = data_byte_tx;
            transaction_tx.framing_error = erro_tx;

            ap_tx.write(transaction_tx);
            `uvm_info("UART MONITOR", $sformatf("Data sent to DUT=0x%02X", transaction_tx.data), UVM_MEDIUM)
        join_none

        `uvm_info("UART MONITOR", "RUN: finished", UVM_LOW)
    endtask

    task monitor_uart(bit rx_tx, output bit [UART_DATA_BITS-1:0] data_byte, output bit erro);
        detect_start(rx_tx);

        // Recebe byte de dado
        receive_data(rx_tx, data_byte);
        
        detect_stop(rx_tx, erro);
    endtask

    task detect_start(bit rx_tx); // se 0, olhar rx, se 1, olhar tx
        bit monitored_line = rx_tx ? bfm.uart_tx : bfm.uart_rx;

         // assim que receber um start
        if (!rx_tx)
            @(negedge bfm.uart_rx);
        else
            @(negedge bfm.uart_tx);
        
    endtask

    task detect_stop(bit rx_tx, output bit erro);
        bit monitored_line = rx_tx ? bfm.uart_tx : bfm.uart_rx;

        // verifica bit de STOP: deve ser 1
        #(UART_BIT_PERIOD_NS);
        if (monitored_line !== 1'b1)
        begin
            erro = 1'b1;
        end
    endtask

    task receive_data(bit rx_tx, output bit [UART_DATA_BITS-1:0] data);
        bit monitored_line = rx_tx ? bfm.uart_tx : bfm.uart_rx;

        for (int i = 0; i < UART_DATA_BITS; i++)
        begin
            #(UART_BIT_PERIOD_NS);
            data[i] = monitored_line;
        end
    endtask
endclass : uart_monitor

`endif // SOC_MONITOR_SV