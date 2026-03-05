`ifndef SOC_DRIVER_SV
`define SOC_DRIVER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "soc_macros.svh"
`include "transaction.sv"

// =============================================================================
// BOOTLOADER Driver
// =============================================================================
class bootloader_driver extends uvm_driver #(bootloader_transaction);
    `uvm_component_utils(bootloader_driver)

    virtual soc_bfm bfm;

    function new(string name = "bootloader_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_fatal("NO_BFM", "BFM not set via uvm_config_db");
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        bootloader_transaction item;

        seq_item_port.get_next_item(item);

        send_mode(item);

        seq_item_port.item_done();

    endtask : run_phase

    task send_mode(bootloader_transaction item);
        bit timed_out = 0;
        uvm_event ev_boot_done = uvm_event_pool::get_global("ev_boot_done");

        bfm.boot_mode = item.boot_mode;

        fork
            begin
                ev_boot_done.wait_trigger();
                bfm.boot_mode = 1'b0;
            end

            begin
                #(100ms);
                timed_out = 1;
            end
        join_any
        disable fork;
    endtask
endclass : bootloader_driver


// =============================================================================
// UART Driver
// =============================================================================
class uart_driver extends uvm_driver #(uart_transaction);
    `uvm_component_utils(uart_driver)

    virtual soc_bfm bfm;

    function new(string name = "uart_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_fatal("NO_BFM", "BFM not set via uvm_config_db");
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        uart_transaction item;

        forever
        begin
            seq_item_port.get_next_item(item);

            send_command(item);

            seq_item_port.item_done();
        end
    endtask : run_phase

    task send_command(uart_transaction item);
        bfm.boot_mode = 0; // garantir que o soc não está no modo de bootload

        send_bit(1'b0); // bit de START (sempre 0)

        for(int i = 0; i < UART_DATA_BITS; i = i + 1)
        begin
            send_bit(item.data_sent[i]);
        end
        
        send_bit(1'b1); // bit de STOP (sempre 1)
    endtask

    task send_bit(bit val);
        bfm.uart_tx = val;
        #(UART_BIT_CLKS * CLK_PERIOD);
    endtask
endclass : uart_driver


// =============================================================================
// GPIO Driver
// =============================================================================
class gpio_driver extends uvm_driver #(gpio_transaction);
    `uvm_component_utils(gpio_driver)

    virtual soc_bfm bfm;

    function new(string name = "gpio_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_fatal("NO_BFM", "BFM not set via uvm_config_db");
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        gpio_transaction item;

        forever
        begin
            seq_item_port.get_next_item(item);

            // No momento, não temos entrada via GPIO - driver já preparado para mudanças futuras
            bfm.gpio_out = item.data_sent;

            seq_item_port.item_done();
        end
    endtask : run_phase
endclass : gpio_driver


// =============================================================================
// SPI Driver
// =============================================================================
class spi_driver extends uvm_driver #(spi_transaction);
    `uvm_component_utils(spi_driver)

    virtual soc_bfm bfm;

    function new(string name = "spi_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_fatal("NO_BFM", "BFM not set via uvm_config_db");
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        spi_transaction item;
        
        spi_off();
        start_stop(1'b0);
        wait_for_start();

        seq_item_port.get_next_item(item);

        send_command(item);
        start_stop(1'b1);
        seq_item_port.item_done();

    endtask : run_phase

    function void spi_off();
        bfm.spi_miso <= 1'b0;
        bfm.spi_mosi <= 1'b0;
        bfm.spi_sck  <= 1'b0;
        bfm.spi_cs   <= 1'b1;
    endfunction

    task wait_for_start();
        bit start_detected = 0;
        fork
            begin
                @(negedge bfm.spi_cs);
                start_detected = 1;
            end

        // Aguarda START_TIMEOUT unidades de tempo; se a DUT não gerar START nesse intervalo, a simulação é encerrada com uvm_fatal.
        begin
            #(START_TIMEOUT);
            if (!start_detected)
            begin
                `uvm_fatal("SPI DRIVER", $sformatf("TIMEOUT: DUT não gerou condição de START após %0t ps. ", START_TIMEOUT))
            end
        end
        join_any
        
        disable fork;

    endtask

    task wait_for_stop();
        forever
        begin
            @(posedge bfm.spi_cs);
            begin
                return;
            end
        end
    endtask

    task send_command(spi_transaction item);
        for(int i = 0; i < SPI_DATA_BITS; i = i + 1)
        begin
            send_bit(item.data_sent[i]);
        end
    endtask

    task send_bit(bit val);
        bfm.spi_miso = val;
        #SPI_BIT_PERIOD_NS;
    endtask

    task start_stop(bit val);
        bfm.spi_cs = val;
        #SPI_BIT_PERIOD_NS;
    endtask

endclass : spi_driver


// =============================================================================
// I2C Driver - Revisar quando possível
// =============================================================================
class i2c_driver extends uvm_driver #(i2c_transaction);
    `uvm_component_utils(i2c_driver)

    virtual soc_bfm bfm;

    function new(string name = "i2c_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_fatal("NO_BFM", "BFM not set via uvm_config_db");
    endfunction : build_phase

    task run_phase(uvm_phase phase);

        release_sda(); // garantir que sda não esteja sendo dirigida inicialmente (idle)

        forever
        begin
            logic [I2C_DATA_BITS-1:0] rcvd_addr, rcvd_data;
            logic rcvd_rw;

            wait_for_start();
            decode_byte(rcvd_addr); // recebe o byte de endereço + bit R/W
            rcvd_rw = rcvd_addr[0];

            if (rcvd_addr !== I2C_ADDRESS) // verifica se a transação é para este slave
            begin
                `uvm_info("I2C DRIVER", $sformatf("Endereço 0x%02X não é meu (0x%02X) - ignorando", rcvd_addr, I2C_ADDRESS), UVM_HIGH)
                release_sda(); // só pra garantir que não estamos dirigindo o barramento
                
                wait_for_stop(); // Aguarda STOP sem responder
                continue;
            end

            send_ack();

            if (rcvd_rw == 1'b0)
            begin
                decode_byte(rcvd_data);

                send_ack();
                wait_for_stop();
            end
            else
            begin
                `uvm_info("I2C DRIVER", "READ - not implemented yet", UVM_LOW)
            end
        end
    endtask : run_phase
    
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
    endtask

    // Slave puxa SDA para 0 para ACK, após o pulso de SCL, libera SDA (volta para alta impedância)
    task send_ack();
        @(negedge bfm.i2c_scl);

        bfm.i2c_sda_oe  <= 1'b1;
        bfm.i2c_sda_out <= 1'b0;

        @(posedge bfm.i2c_scl);
        @(negedge bfm.i2c_scl);

        release_sda();
    endtask

    function void release_sda();
        bfm.i2c_sda_oe <= 1'b0;
        bfm.i2c_sda_out <= 1'bz;
    endfunction

    // Aguarda a condição de START: SDA desce enquanto SCL está alto - slave não faz nada enquanto espera
    task wait_for_start();
        bit start_detected = 0;   // flag compartilhada entre as threads

        fork
            forever
            begin
                @(negedge bfm.i2c_sda);
                if (bfm.resolve(bfm.i2c_scl) === 1'b1)
                begin
                    start_detected = 1;
                    break;
                end
            end
        
            // Aguarda START_TIMEOUT unidades de tempo; se a DUT não gerar START nesse intervalo, a simulação é encerrada com uvm_fatal.
            begin
                #(START_TIMEOUT);
                if (!start_detected)
                begin
                    `uvm_fatal("I2C DRIVER", $sformatf("TIMEOUT: DUT não gerou condição de START após %0t ps. ", START_TIMEOUT))
                end
            end
        join_any
        
        disable fork;

    endtask

    task wait_for_stop();
        forever
        begin
            @(bfm.i2c_sda);
            if (bfm.resolve(bfm.i2c_sda) === 1'b1)
            begin
                if (bfm.i2c_scl !== 1'b0)
                begin
                    release_sda();
                    break;
                end
            end
        end
    endtask

endclass : i2c_driver


// =============================================================================
// TIMER Driver - Como não envia dados, não é necessário
// =============================================================================

`endif // SOC_DRIVER_SV