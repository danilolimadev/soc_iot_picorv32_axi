`ifndef SOC_MONITOR_SV
`define SOC_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "soc_macros.svh"
`include "transaction.sv"

// =============================================================================
// BOOTLOADER Monitor
// =============================================================================
class bootloader_monitor extends uvm_monitor;
    `uvm_component_utils(bootloader_monitor)
    
    virtual soc_bfm bfm;
    uvm_analysis_port #(bootloader_transaction) ap;

    uvm_event ev_boot_done;

    function new(string name, uvm_component parent);
        super.new(name, parent);

        ap = new("ap", this);

        // Pega o evento do pool global (mesmo objeto em todo o ambiente)
        ev_boot_done = uvm_event_pool::get_global("ev_boot_done");

        `uvm_info("BOOTLOADER MONITOR", "NEW", UVM_LOW)
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_warning("BOOTLOADER_MON", "Virtual interface `bfm` not found via uvm_config_db. Check config_db::set path.")

        `uvm_info("BOOTLOADER MONITOR", "BUILD", UVM_LOW)
    endfunction
    
    task run_phase(uvm_phase phase);
        bootloader_transaction transaction;
        int cycle_count;

        `uvm_info("BOOTLOADER MONITOR", "RUN: started", UVM_LOW);
        
        monitor_bootloader(cycle_count);

        transaction = bootloader_transaction::type_id::create("transaction");
        transaction.clock_cycles = cycle_count;

        ap.write(transaction);

        `uvm_info("BOOTLOADER MONITOR", $sformatf( "Boot DONE em %0d ciclos (%0t)", cycle_count, $time), UVM_MEDIUM)
    endtask

    task monitor_bootloader(output int cycle_count);
        int counting = 0;
        
        @(posedge bfm.boot_mode); // Detecta início do boot
        counting = 0;
        `uvm_info("BOOTLOADER MONITOR", "Boot iniciado - contando ciclos...", UVM_LOW)

        forever
        begin
            @(posedge bfm.clk);
            if (!bfm.boot_done)
                counting++;
            else
            begin
                cycle_count = counting;
                ev_boot_done.trigger();
                `uvm_info("BOOTLOADER MONITOR", $sformatf( "Boot DONE em %0d ciclos - trigou", cycle_count), UVM_LOW)
                break;
            end
        end
    endtask

endclass : bootloader_monitor

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

    uvm_event ev_initial_msg_done;

    function new(string name, uvm_component parent);
        super.new(name, parent);

        ap_rx = new("ap_rx", this);
        ap_tx = new("ap_tx", this);

        ev_initial_msg_done = uvm_event_pool::get_global("ev_initial_msg_done");

        `uvm_info("UART MONITOR", "NEW", UVM_LOW)
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_warning("UART_MON", "Virtual interface `bfm` not found via uvm_config_db. Check config_db::set path.")

        `uvm_info("UART MONITOR", "BUILD", UVM_LOW)
    endfunction
    
    task run_phase(uvm_phase phase);
        uart_transaction transaction_rx, transaction_tx;
        bit [UART_DATA_BITS-1:0] data_byte_rx, data_byte_tx;
        bit erro_rx, erro_tx, timed_out;

        // Monitorar mensagem inicial
        repeat(INITIAL_MSG.len())
        begin
            monitor_uart(1'b1, data_byte_rx, erro_rx);  // DUT enviando para UART

            transaction_rx = uart_transaction::type_id::create("transaction_rx");
            transaction_rx.data = data_byte_rx;
            transaction_rx.framing_error = erro_tx;

            ap_rx.write(transaction_rx);
        end

        `uvm_info("UART MONITOR", "Recebeu msg", UVM_MEDIUM)
        ev_initial_msg_done.trigger();
        
        fork
            forever
            begin
                `uvm_info("UART MONITOR", "Monitorando envio de msg", UVM_MEDIUM)
                monitor_uart(1'b0, data_byte_tx, erro_tx); // UART enviando para DUT

                transaction_tx = uart_transaction::type_id::create("transaction_tx");
                transaction_tx.data = data_byte_tx;
                transaction_tx.framing_error = erro_tx;

                ap_tx.write(transaction_tx);
                `uvm_info("UART MONITOR", $sformatf("Data sent to DUT=0x%02X", transaction_tx.data), UVM_MEDIUM)

            end
        
            forever
            begin
                `uvm_info("UART MONITOR", "Monitorando recebimento de msg", UVM_MEDIUM)
                monitor_uart(1'b1, data_byte_rx, erro_rx); // DUT enviando para UART

                transaction_rx = uart_transaction::type_id::create("transaction_rx");
                transaction_rx.data = data_byte_rx;
                transaction_rx.framing_error = erro_rx;

                ap_rx.write(transaction_rx);
                `uvm_info("UART MONITOR", $sformatf("Data sent from DUT after command=0x%02X", transaction_rx.data), UVM_MEDIUM)
            end

            begin
                #(100ms);
                timed_out = 1;
                `uvm_error("UART MONITOR", "Timeout! UART não enviou nenhum comando em 100ms")
            end
        join_any
        disable fork;

        `uvm_info("UART MONITOR", "Saiu do fork", UVM_MEDIUM)

        if (timed_out) return;

        `uvm_info("UART MONITOR", "RUN: finished", UVM_LOW)
    endtask

    task monitor_uart(bit tx_rx, output bit [UART_DATA_BITS-1:0] data_byte, output bit erro);
        detect_start(tx_rx);

        // Recebe byte de dado
        receive_data(tx_rx, data_byte);
        
        detect_stop(tx_rx, erro);
        `uvm_info("UART MONITOR", $sformatf("Data: 0x%h", data_byte), UVM_MEDIUM)
        `uvm_info("UART MONITOR", $sformatf("Erro: %b", erro), UVM_MEDIUM)
    endtask

    task detect_start(bit tx_rx); // se 0, olhar tx, se 1, olhar rx
        if (!tx_rx)
        begin
            @(negedge bfm.uart_tx);
            `uvm_info("UART MONITOR", "Detectou start no tx", UVM_LOW)
        end
        else
        begin
            @(negedge bfm.uart_rx);
            `uvm_info("UART MONITOR", "Detectou start no rx", UVM_LOW)
        end
        #((UART_BIT_CLKS * CLK_PERIOD) / 2);
    endtask

    task detect_stop(bit tx_rx, output bit erro);
        // verifica bit de STOP: deve ser 1
        #(UART_BIT_CLKS * CLK_PERIOD);
        if (!tx_rx)
            begin
                if (bfm.uart_tx !== 1'b1)
                begin
                    erro = 1'b1;
                end
                `uvm_info("UART MONITOR", $sformatf("Detected tx stop: %b", bfm.uart_tx), UVM_MEDIUM)
            end
            else
            begin
                if (bfm.uart_rx !== 1'b1)
                begin
                    erro = 1'b1;
                end
                `uvm_info("UART MONITOR", $sformatf("Detected rx stop: %b", bfm.uart_rx), UVM_MEDIUM)
            end
    endtask

    task receive_data(bit tx_rx, output bit [UART_DATA_BITS-1:0] data);
        for (int i = 0; i < UART_DATA_BITS; i++)
        begin
            #(UART_BIT_CLKS * CLK_PERIOD);

            if (!tx_rx)
            begin
                data[i] = bfm.uart_tx;
                //`uvm_info("UART MONITOR", $sformatf("Bit sent to DUT #%d = 0x%b", i, bfm.uart_tx), UVM_MEDIUM)
            end
            else
            begin
                data[i] = bfm.uart_rx;
                //`uvm_info("UART MONITOR", $sformatf("Bit received from DUT = 0x%b", bfm.uart_rx), UVM_MEDIUM)
            end
        end
    endtask
endclass : uart_monitor

`endif // SOC_MONITOR_SV