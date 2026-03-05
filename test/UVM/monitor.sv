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
        ev_boot_done = uvm_event_pool::get_global("ev_boot_done");
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_warning("BOOTLOADER_MON", "Virtual interface `bfm` not found via uvm_config_db. Check config_db::set path.")
    endfunction
    
    task run_phase(uvm_phase phase);
        bootloader_transaction transaction;
        int cycle_count;
        
        monitor_bootloader(cycle_count);

        transaction = bootloader_transaction::type_id::create("transaction");
        transaction.clock_cycles = cycle_count;

        ap.write(transaction);
    endtask

    task monitor_bootloader(output int cycle_count);
        int counting = 0;
        
        @(posedge bfm.boot_mode); // Detecta início do boot
        counting = 0;

        forever
        begin
            @(posedge bfm.clk);
            if (!bfm.boot_done)
                counting++;
            else
            begin
                cycle_count = counting;
                ev_boot_done.trigger();
                break;
            end
        end
    endtask

endclass : bootloader_monitor


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
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_warning("UART_MON", "Virtual interface `bfm` not found via uvm_config_db. Check config_db::set path.")
    endfunction
    
    task run_phase(uvm_phase phase);
        uart_transaction transaction_rx, transaction_tx;
        bit [UART_DATA_BITS-1:0] data_byte_rx, data_byte_tx;
        bit erro_rx, erro_tx, timed_out;

        // TODO: REFACTOR TO GET INITIAL MESSAGE OR OTHER MESSAGES AT SAME TIME

        // Monitorar mensagem inicial
        repeat(INITIAL_MSG.len())
        begin
            monitor_uart(1'b1, data_byte_rx, erro_rx);  // DUT enviando para UART

            transaction_rx = uart_transaction::type_id::create("transaction_rx");
            transaction_rx.data = data_byte_rx;
            transaction_rx.framing_error = erro_tx;

            ap_rx.write(transaction_rx);
        end

        ev_initial_msg_done.trigger();
        
        fork
            forever
            begin
                monitor_uart(1'b0, data_byte_tx, erro_tx); // UART enviando para DUT

                transaction_tx = uart_transaction::type_id::create("transaction_tx");
                transaction_tx.data = data_byte_tx;
                transaction_tx.framing_error = erro_tx;

                ap_tx.write(transaction_tx);
            end
        
            forever
            begin
                monitor_uart(1'b1, data_byte_rx, erro_rx); // DUT enviando para UART

                transaction_rx = uart_transaction::type_id::create("transaction_rx");
                transaction_rx.data = data_byte_rx;
                transaction_rx.framing_error = erro_rx;

                ap_rx.write(transaction_rx);
                
            end

            begin
                #(100ms);
                timed_out = 1;
                `uvm_error("UART MONITOR", "Timeout! UART não enviou nenhum comando em 100ms")
            end
        join_any
        disable fork;

        if (timed_out) return;
    endtask

    task monitor_uart(bit tx_rx, output bit [UART_DATA_BITS-1:0] data_byte, output bit erro);
        detect_start(tx_rx);
        receive_data(tx_rx, data_byte);        
        detect_stop(tx_rx, erro);
    endtask

    task detect_start(bit tx_rx); // se 0, olhar tx, se 1, olhar rx
        if (!tx_rx)
        begin
            @(negedge bfm.uart_tx);
        end
        else
        begin
            @(negedge bfm.uart_rx);
        end
        #((UART_BIT_CLKS * CLK_PERIOD) / 2);
    endtask

    task detect_stop(bit tx_rx, output bit erro);
        #(UART_BIT_CLKS * CLK_PERIOD);
        if (!tx_rx)
            begin
                if (bfm.uart_tx !== 1'b1)
                begin
                    erro = 1'b1;
                end
            end
            else
            begin
                if (bfm.uart_rx !== 1'b1)
                begin
                    erro = 1'b1;
                end
            end
    endtask

    task receive_data(bit tx_rx, output bit [UART_DATA_BITS-1:0] data);
        for (int i = 0; i < UART_DATA_BITS; i++)
        begin
            #(UART_BIT_CLKS * CLK_PERIOD);

            if (!tx_rx)
            begin
                data[i] = bfm.uart_tx;
            end
            else
            begin
                data[i] = bfm.uart_rx;
            end
        end
    endtask

endclass : uart_monitor


// =============================================================================
// GPIO Monitor
// =============================================================================
class gpio_monitor extends uvm_monitor;
    `uvm_component_utils(gpio_monitor)
    
    virtual soc_bfm bfm;
    uvm_analysis_port #(gpio_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);

        ap = new("ap", this);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_warning("GPIO MONITOR", "Virtual interface `bfm` not found via uvm_config_db. Check config_db::set path.")
    endfunction

    task run_phase(uvm_phase phase);
        gpio_transaction transaction;

        monitor_gpio();
    endtask

    task monitor_gpio();
        gpio_transaction transaction;

        forever
        begin
            @(bfm.gpio_out)

            transaction = gpio_transaction::type_id::create("transaction");
            transaction.data = bfm.gpio_out;

            ap.write(transaction);
        end
    endtask
endclass : gpio_monitor


// =============================================================================
// SPI Monitor
// =============================================================================
class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)
    
    virtual soc_bfm bfm;

    uvm_analysis_port #(spi_transaction) ap_mosi;
    uvm_analysis_port #(spi_transaction) ap_miso;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);

        ap_mosi = new("ap_mosi", this);
        ap_miso = new("ap_miso", this);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_warning("SPI MONITOR", "Virtual interface `bfm` not found via uvm_config_db. Check config_db::set path.")
    endfunction
    
    task run_phase(uvm_phase phase);
        spi_transaction transaction_mosi, transaction_miso;
        bit [SPI_DATA_BITS-1:0] data_byte_mosi, data_byte_miso;
        string msg_received_spi = "";

        forever
        begin
            monitor_spi(data_byte_mosi, data_byte_miso);

            if (data_byte_mosi != 8'h0)
            begin
                msg_received_spi = {msg_received_spi, string'(data_byte_mosi)};
            end

            if (msg_received_spi.len() >= MSG_TO_SPI.len())
            begin
                transaction_mosi = spi_transaction::type_id::create("transaction_mosi");
                transaction_mosi.msg_received = msg_received_spi;
                ap_mosi.write(transaction_mosi);

                msg_received_spi = "";
            end

            if (data_byte_miso != 8'h0)
            begin
                transaction_miso = spi_transaction::type_id::create("transaction_miso");
                transaction_miso.data = data_byte_miso;
                ap_miso.write(transaction_miso);
            end
        end
    endtask


    task monitor_spi(output bit [SPI_DATA_BITS-1:0] data_byte_mosi, data_byte_miso);

        wait_for_start();
        decode_byte(data_byte_mosi, data_byte_miso);
        wait_for_stop();

    endtask

    task decode_byte(output bit [SPI_DATA_BITS-1:0] data_byte_mosi, data_byte_miso);
        data_byte_mosi[SPI_DATA_BITS-1] = bfm.spi_mosi;
        data_byte_miso[SPI_DATA_BITS-1] = bfm.spi_miso;

        for(int i = SPI_DATA_BITS-2; i >= 0; i--)
        begin
            @(negedge bfm.spi_sck); // pega cada bit restante na subida de sck
            begin
                data_byte_mosi[i] = bfm.spi_mosi;
            end
            @(posedge bfm.spi_sck); 
            begin
                data_byte_miso[i] = bfm.spi_miso;
            end
        end
    endtask

    task wait_for_start();
        @(negedge bfm.spi_cs);
    endtask

    task wait_for_stop();
         @(posedge bfm.spi_cs);
    endtask

endclass : spi_monitor


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
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_warning("I2C_MON", "Virtual interface `bfm` not found via uvm_config_db. Check config_db::set path.")
    endfunction
    
    task run_phase(uvm_phase phase);
        bit [I2C_DATA_BITS-1:0] addr_byte;
        bit [I2C_DATA_BITS-1:0] data_byte;
        i2c_transaction transaction;

        forever
        begin
            monitor_read_i2c(addr_byte, data_byte);

            transaction = i2c_transaction::type_id::create("transaction");
            transaction.data = data_byte;
            transaction.slave_addr = addr_byte;
            ap.write(transaction);

            // TODO: IMPLEMENT WRITE I2C
        end
    endtask
    
    task monitor_read_i2c(output bit [I2C_DATA_BITS-1:0] addr_byte, data_byte);
        bit       stop_flag = 1'b0;

        wait_for_start();
        decode_byte(addr_byte);
        decode_byte(data_byte);
        detect_stop();
    endtask

    task decode_byte(output bit [I2C_DATA_BITS-1:0] data_byte);
        int count = I2C_DATA_BITS-1;

        while (count >=0)
        begin
            @(bfm.i2c_scl);
            if (bfm.resolve(bfm.i2c_scl) === 1'b1)
            begin
                data_byte[count] = bfm.resolve(bfm.i2c_sda);
                count--;
            end
        end

        wait_ack();
    endtask

    task wait_ack();
        @(negedge bfm.i2c_scl);

        @(bfm.i2c_scl);
        if (bfm.resolve(bfm.i2c_scl) === 1'b1)
        begin
            @(negedge bfm.i2c_scl);
        end
    endtask

    task detect_stop();
        forever
        begin
            @(bfm.i2c_sda);
            if (bfm.resolve(bfm.i2c_sda) === 1'b1)
            begin
                if (bfm.i2c_scl !== 1'b0)
                begin
                    break;
                end
            end
        end
    endtask

    task wait_for_start();
        forever
        begin
            @(negedge bfm.i2c_sda);
            if (bfm.resolve(bfm.i2c_scl) === 1'b1)
            begin
                break;
            end
        end
    endtask

endclass : i2c_monitor


// =============================================================================
// TIMER Monitor
// =============================================================================
class timer_monitor extends uvm_monitor;
    `uvm_component_utils(timer_monitor)
    
    virtual soc_bfm bfm;
    uvm_analysis_port #(timer_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);

        ap = new("ap", this);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_warning("TIMER MONITOR", "Virtual interface `bfm` not found via uvm_config_db. Check config_db::set path.")
    endfunction

    task run_phase(uvm_phase phase);
        monitor_timer();
    endtask

    task monitor_timer();
        timer_transaction transaction;

        forever
        begin
            @(posedge bfm.timer_irq)

            transaction = timer_transaction::type_id::create("transaction");
            transaction.irq = bfm.timer_irq;

            ap.write(transaction);
        end
    endtask
endclass : timer_monitor

`endif // SOC_MONITOR_SV