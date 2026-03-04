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

    // constructor
    function new(string name = "bootloader_driver", uvm_component parent = null);
        super.new(name, parent);
        //`uvm_info("BOOTLOADER DRIVER", "NEW", UVM_LOW)
    endfunction : new

    // build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_fatal("NO_BFM", "BFM not set via uvm_config_db");

        //`uvm_info("BOOTLOADER DRIVER", "BUILD", UVM_LOW)
    endfunction : build_phase

    // run phase
    task run_phase(uvm_phase phase);
        bootloader_transaction item;

        //`uvm_info("BOOTLOADER DRIVER", "RUN: started", UVM_LOW);

        seq_item_port.get_next_item(item);

        `uvm_info("BOOTLOADER DRIVER", $sformatf("Driving BOOTLOADER mode: 0x%h", item.boot_mode), UVM_LOW)

        send_mode(item);

        seq_item_port.item_done();

        `uvm_info("BOOTLOADER DRIVER", "RUN: finished", UVM_LOW)

    endtask : run_phase

    task send_mode(bootloader_transaction item);
        //`uvm_info("BOOTLOADER DRIVER", "Send mode", UVM_HIGH)
        bit timed_out = 0;
        uvm_event ev_boot_done = uvm_event_pool::get_global("ev_boot_done");

        bfm.boot_mode = item.boot_mode;

        `uvm_info("BOOTLOADER DRIVER", $sformatf("Mode enviado: 0x%h", item.boot_mode), UVM_HIGH)

        fork
        begin
            ev_boot_done.wait_trigger();
            bfm.boot_mode = 1'b0;
            `uvm_info("BOOTLOADER DRIVER", "boot_done recebido!", UVM_NONE)
        end
        begin
            #(100ms);
            timed_out = 1;
            `uvm_error("BOOTLOADER DRIVER", "Timeout! boot_done não chegou em 100ms")
        end
        join_any
        disable fork;
    endtask
endclass : bootloader_driver

// =============================================================================
// I2C Driver
// =============================================================================
class i2c_driver extends uvm_driver #(i2c_transaction);
    `uvm_component_utils(i2c_driver)

    virtual soc_bfm bfm;

    // ---- Estatísticas ----
    int unsigned addr_mismatches = 0;  // Transações endereçadas a outro slave
    int unsigned write_count     = 0;
    int unsigned read_count      = 0;

    // constructor
    function new(string name = "i2c_driver", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("I2C DRIVER", "NEW", UVM_LOW)
    endfunction : new

    // build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_fatal("NO_BFM", "BFM not set via uvm_config_db");

        `uvm_info("I2C DRIVER", "BUILD", UVM_LOW)
    endfunction : build_phase

    // run phase
    task run_phase(uvm_phase phase);        
        `uvm_info("I2C DRIVER", "RUN: started", UVM_LOW);

        release_sda(); // garantir que sda não esteja sendo dirigida inicialmente (idle)

        forever
        begin
            //2c_transaction item;
            logic [6:0] rcvd_addr;
            logic       rcvd_rw;

            // aguarda condição de START da DUT
            wait_for_start();

            // recebe o byte de endereço + bit R/W
            receive_addr_byte(rcvd_addr, rcvd_rw);

            // verifica se a transação é para este slave
            if (rcvd_addr !== I2C_ADDRESS)
            begin
                `uvm_info("I2C DRIVER", $sformatf("Endereço 0x%02X não é meu (0x%02X) – ignorando", rcvd_addr, I2C_ADDRESS), UVM_HIGH)
                addr_mismatches++;
                release_sda(); // só pra garantir que não estamos dirigindo o barramento
                // Aguarda STOP sem responder
                wait_for_stop();
                continue;
            end

            `uvm_info("I2C DRIVER", $sformatf("Endereço correspondente! R/W=%b", rcvd_rw), UVM_MEDIUM)

            // envia ACK do endereço
            send_ack();

            // acredito que não preciso criar um item de transação para o sequencer, pois o slave é passivo e não tem controle sobre os dados que recebe ou envia
            // // Cria item de resposta para o sequencer
            // item = i2c_transaction::type_id::create("item");
            // item.slave_addr = I2C_ADDRESS;
            // item.rw         = rcvd_rw;

            if (rcvd_rw == 1'b0)
            begin
                handle_write(); // DUT envia dado, slave armazena
                write_count++;
            end
            else
            begin
                `uvm_info("I2C DRIVER", "READ", UVM_LOW)
                // handle_read(); // slave envia dado, DUT lê
                read_count++;
            end

            seq_item_port.item_done();
      

            // aguarda STOP e volta ao IDLE
            wait_for_stop();
        end

        `uvm_info("I2C DRIVER", "RUN: finished", UVM_LOW)

    endtask : run_phase
    
    function void report_phase(uvm_phase phase);
        `uvm_info("I2C DRIVER", 
            $sformatf("\n===== Report =====\n  Escritas recebidas   : %0d\n  Leituras servidas    : %0d\n  Endereços ignorados  : %0d\n",
            write_count, read_count, addr_mismatches), UVM_LOW)
    endfunction
    
    function void release_sda();
        bfm.i2c_sda_oe <= 1'b0;
        bfm.i2c_sda_out    <= 1'bz;
    endfunction

    // Aguarda a condição de START: SDA desce enquanto SCL está alto - slave não faz nada enquanto espera
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
            @(posedge bfm.i2c_sda);
            if (bfm.i2c_scl === 1'b1)
            begin
                `uvm_info("I2C DRIVER", "STOP detectado – barramento livre", UVM_HIGH)
                release_sda();
                return;
            end
        end
    endtask

    task receive_addr_byte(output logic [6:0] addr, output logic rw);
        logic [7:0] full_byte;

        receive_byte(full_byte);

        addr = full_byte[7:1];   // Bits [7:1] = endereço do escravo
        rw   = full_byte[0];     // Bit  [0]   = direção (0=Write, 1=Read)
        `uvm_info("I2C DRIVER", $sformatf("Byte de endereço recebido: ADDR=0x%02X R/W=%b", addr, rw), UVM_HIGH)
    endtask

    task receive_byte(output logic [7:0] data_byte);
        for (int i = 7; i >= 0; i--)
        begin
            @(posedge bfm.i2c_scl);          // Aguarda SCL subir (gerado pela DUT)
            data_byte[i] = bfm.i2c_sda;       // Amostra SDA no nível alto do SCL
        end
    endtask

    // Slave puxa SDA para 0 para ACK, após o pulso de SCL, libera SDA (volta para alta impedância)
    task send_ack();
        // Aguarda SCL descer para que o slave possa assumir SDA
        @(negedge bfm.i2c_scl);

        // Puxa SDA para LOW = ACK
        bfm.i2c_sda_oe  <= 1'b1;
        bfm.i2c_sda_out <= 1'b0;

        // Aguarda o pulso de SCL do ACK (DUT lê durante SCL alto)
        @(posedge bfm.i2c_scl);
        @(negedge bfm.i2c_scl);

        // Libera SDA após o ACK
        release_sda();

        `uvm_info("I2C DRIVER", "ACK enviado", UVM_HIGH)
    endtask

    // recebe byte de dado, ACK por byte
    task handle_write();
        logic [7:0] reg_a;
        logic [7:0] data_b;

        // recebe o byte de dado
        // aqui implementamos 1 byte - pode ser estendido para múltiplos bytes com um loop e um flag de STOP
        receive_byte(data_b);
        `uvm_info("I2C DRIVER", $sformatf("WRITE da DUT: dado 0x%02X -> reg[0x%02X]", data_b, reg_a), UVM_MEDIUM)

        // armazena na memória
        //slv_mem.write_reg(reg_a, data_b);

        // ACK do dado
        send_ack();
    endtask

endclass : i2c_driver


// =============================================================================
// UART Driver
// =============================================================================
class uart_driver extends uvm_driver #(uart_transaction);
    `uvm_component_utils(uart_driver)

    virtual soc_bfm bfm;

    // ---- Estatísticas ----
    int unsigned addr_mismatches = 0;  // Transações endereçadas a outro slave
    int unsigned write_count     = 0;
    int unsigned read_count      = 0;

    // constructor
    function new(string name = "uart_driver", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("UART DRIVER", "NEW", UVM_LOW)
    endfunction : new

    // build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_bfm)::get(this, "", "bfm", bfm))
            `uvm_fatal("NO_BFM", "BFM not set via uvm_config_db");

        `uvm_info("UART DRIVER", "BUILD", UVM_LOW)
    endfunction : build_phase

    // run phase
    task run_phase(uvm_phase phase);
        uart_transaction item;

        forever
        begin
            //`uvm_info("UART DRIVER", "RUN: started", UVM_LOW);

            seq_item_port.get_next_item(item);

            //`uvm_info("UART DRIVER", $sformatf("Driving UART command: 0x%h", item.data_sent), UVM_LOW)

            send_command(item);

            seq_item_port.item_done();

            //`uvm_info("UART DRIVER", "RUN: finished", UVM_LOW)
        end
    endtask : run_phase
    
    function void report_phase(uvm_phase phase);
        `uvm_info("UART DRIVER", 
            $sformatf("\n===== Report =====\n  Escritas recebidas   : %0d\n  Leituras servidas    : %0d\n  Endereços ignorados  : %0d\n",
            write_count, read_count, addr_mismatches), UVM_LOW)
    endfunction

    task send_command(uart_transaction item);
        //`uvm_info("UART DRIVER", "Send comand", UVM_HIGH)

        bfm.boot_mode = 0; // garantir que o soc não está no modo de bootload

        send_bit(1'b0); // bit de START (sempre 0)

        // enviar dados
        for(int i = 0; i < UART_DATA_BITS; i = i + 1)
        begin
            send_bit(item.data_sent[i]);
            //`uvm_info("UART DRIVER", $sformatf("Bit enviado: 0x%b", item.data_sent[i]), UVM_HIGH)
        end
        
        send_bit(1'b1); // bit de STOP (sempre 1)

        `uvm_info("UART DRIVER", $sformatf("Frame enviado: 0x%h", item.data_sent), UVM_HIGH)
    endtask

    task send_bit(bit val);
        bfm.uart_tx = val;
        #(UART_BIT_CLKS * CLK_PERIOD);
    endtask
endclass : uart_driver

`endif // SOC_DRIVER_SV