`ifndef soc_sequences_SV
`define soc_sequences_SV

`include "soc_macros.svh"
`include "transaction.sv"

// =============================================================================
// BOOTLOADER Sequence
// =============================================================================
class bootloader_seq extends uvm_sequence #(bootloader_transaction);
    `uvm_object_utils(bootloader_seq)

    int unsigned max_transactions = 1;

    function new(string name = "bootloader_seq");
        super.new(name);
        `uvm_info("BOOTLOADER SEQUENCE", "NEW", UVM_LOW)
    endfunction

    task body();
        bootloader_transaction item;
        
        if (starting_phase != null)
        begin
            starting_phase.raise_objection(this);
        end

        `uvm_info("BOOTLOADER SEQUENCE", $sformatf("Starting %0d random BOOTLOADER commands", max_transactions), UVM_LOW)

        repeat (max_transactions)
        begin
            item = bootloader_transaction::type_id::create("req");

            start_item(item);

            //assert(this.randomize());
            item.boot_mode = 1;
            `uvm_info("BOOTLOADER SEQUENCE", $sformatf("Sending bootloader mode: 0x%h", item.boot_mode), UVM_MEDIUM)

            finish_item(item);
        end

        if (starting_phase != null)
        begin
            starting_phase.drop_objection(this);
        end
    endtask

endclass : bootloader_seq

// =============================================================================
// I2C Sequence
// =============================================================================
class i2c_slave_seq extends uvm_sequence #(i2c_transaction);
    `uvm_object_utils(i2c_slave_seq)

    int unsigned max_transactions = 5;  // 0 = infinito

    function new(string name = "i2c_slave_seq");
        super.new(name);
        `uvm_info("I2C SEQUENCE", "NEW", UVM_LOW)
    endfunction

    task body();
        i2c_transaction item;
        int cnt = 0;

        if (starting_phase != null)
        begin
            starting_phase.raise_objection(this);
        end

        `uvm_info("I2C SEQUENCE", "Receiving data via i2c", UVM_LOW)

        repeat (max_transactions == 0 ? 1 : max_transactions)
        begin
            item = i2c_transaction::type_id::create("item");

            `uvm_info("I2C SEQUENCE", $sformatf("Before starting item #%0d", cnt), UVM_MEDIUM)
            // O sequencer entrega o item ao driver 
            // nada precisa ser enviado pois somos passivos
            start_item(item);
            `uvm_info("I2C SEQUENCE", $sformatf("Receiving data from SOC"), UVM_MEDIUM)
            item.slave_addr = I2C_ADDRESS; // só pra registro, o driver já sabe que é esse endereço
            finish_item(item);

            `uvm_info("I2C SEQUENCE", $sformatf("Transação slave concluída: %s", item.convert2string()), UVM_MEDIUM)

            cnt++;
            // if (max_transactions > 0 && cnt >= max_transactions)
            //     break;
        end

        if (starting_phase != null)
        begin
            starting_phase.drop_objection(this);
        end
    endtask

endclass : i2c_slave_seq

// =============================================================================
// UART Sequence
// =============================================================================
class uart_seq extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_seq)

    int unsigned max_transactions = 5;

    function new(string name = "uart_seq");
        super.new(name);
        `uvm_info("UART SEQUENCE", "NEW", UVM_LOW)
    endfunction

    task body();
        uart_transaction item;
        commands cmd;

        `uvm_info("UART SEQUENCE", $sformatf("Starting %0d random UART commands", max_transactions), UVM_LOW)
        //forever
        //begin
            // repeat (max_transactions)
            // begin
            //     `uvm_info("UART SEQUENCE", "Sending new UART command", UVM_MEDIUM)
            //     item = uart_transaction::type_id::create("item");

            //     start_item(item);
            //     `uvm_info("UART SEQUENCE", "Starting new UART command", UVM_MEDIUM)
            //     assert(item.randomize());
            //     `uvm_info("UART SEQUENCE", $sformatf("Sending command: 0x%h", item.data_sent), UVM_MEDIUM)

            //     finish_item(item);
            // end
        //end
        cmd = cmd.first();
        do
        begin
            `uvm_info("UART SEQUENCE", "Sending new UART command", UVM_MEDIUM)
            item = uart_transaction::type_id::create("item");

            start_item(item);
            //assert(item.randomize());
            item.data_sent = cmd;
            `uvm_info("UART SEQUENCE", $sformatf("Sending command: 0x%h", item.data_sent), UVM_MEDIUM)

            finish_item(item);
            cmd = cmd.next();
        end while (cmd != cmd.first());

    endtask

endclass : uart_seq

// =============================================================================
// Virtual Sequences - Coordinate multiple protocol agents
// =============================================================================
class soc_virtual_seq extends uvm_sequence;
    `uvm_object_utils(soc_virtual_seq)
    `uvm_declare_p_sequencer(soc_virtual_sequencer)
    
    function new(string name = "soc_virtual_base_seq");
        super.new(name);
        `uvm_info("VIRTUAL SEQUENCE", "NEW", UVM_LOW)
    endfunction
    
    task body();
        bootloader_seq bootloader_sequence;
        uart_seq uart_sequence;
        uvm_event ev_boot_done = uvm_event_pool::get_global("ev_boot_done");
        uvm_event ev_initial_msg_done = uvm_event_pool::get_global("ev_initial_msg_done");
        bit             timed_out;

        `uvm_info("VIRTUAL SEQUENCE", "Iniciando testes", UVM_LOW)
        // Bootloader
        bootloader_sequence = bootloader_seq::type_id::create("bootloader_sequence");
        bootloader_sequence.start(p_sequencer.bootloader_seqr);  // bloqueia até terminar

        timed_out = 0;
        fork
        begin
            `uvm_info("VIRTUAL SEQUENCE", "esperando boot_done", UVM_NONE)
            ev_boot_done.wait_ptrigger();
            `uvm_info("VIRTUAL SEQUENCE", "boot_done recebido! Iniciando UART...", UVM_NONE)
            // esperar receber mensagem "SOC IOT PICORV32"
            ev_initial_msg_done.wait_ptrigger();
            `uvm_info("VIRTUAL SEQUENCE", "terminou de ler a msg", UVM_MEDIUM)
        end
        begin
            #(200ms);
            timed_out = 1;
            `uvm_error("VIRTUAL SEQUENCE", "Timeout! boot_done não chegou em 100ms")
        end
        join_any
        disable fork;

        if (timed_out) return;

        `uvm_info("VIRTUAL SEQUENCE", "Bootloader terminou - iniciando UART", UVM_LOW)

        // Só após de Bootloader terminar, UART começa ────────────────
        uart_sequence = uart_seq::type_id::create("uart_sequence");
        uart_sequence.start(p_sequencer.uart_seqr);  // bloqueia até terminar

        `uvm_info("VIRTUAL SEQUENCE", "UART terminou - funcionamento completo", UVM_LOW)
    endtask
endclass : soc_virtual_seq

`endif // soc_sequences_SV