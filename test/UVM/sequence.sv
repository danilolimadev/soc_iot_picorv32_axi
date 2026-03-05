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
// UART Sequence
// =============================================================================
class uart_seq extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_seq)


    function new(string name = "uart_seq");
        super.new(name);
    endfunction

    task body();
        uart_transaction item;
        commands cmd;

        `uvm_info("UART SEQUENCE", $sformatf("Starting %0d random UART commands", $size(cmd)), UVM_LOW)
        cmd = cmd.first();
        do
        begin
            item = uart_transaction::type_id::create("item");

            start_item(item);
            item.data_sent = cmd;

            finish_item(item);

            #(10 * UART_BIT_CLKS * CLK_PERIOD);
            
            cmd = cmd.next();
        end while (cmd != cmd.first());

        #(10 * UART_BIT_CLKS * CLK_PERIOD);
    endtask

endclass : uart_seq


// =============================================================================
// GPIO Sequence
// =============================================================================
class gpio_seq extends uvm_sequence #(gpio_transaction);
    `uvm_object_utils(gpio_seq)

    function new(string name = "gpio_seq");
        super.new(name);
    endfunction

    task body();
        gpio_transaction item;

        `uvm_info("GPIO SEQUENCE", "Starting random GPIO commands", UVM_LOW)
        
        item = gpio_transaction::type_id::create("item");

        start_item(item);
        assert(item.randomize());
        finish_item(item);
    endtask

endclass : gpio_seq


// =============================================================================
// SPI Sequence
// =============================================================================
class spi_seq extends uvm_sequence #(spi_transaction);
    `uvm_object_utils(spi_seq)

    int unsigned max_transactions = 1;

    function new(string name = "spi_seq");
        super.new(name);
    endfunction

    task body();
        spi_transaction item;

        if (starting_phase != null)
        begin
            starting_phase.raise_objection(this);
        end

        `uvm_info("SPI SEQUENCE", $sformatf("Starting %0d random SPI commands", max_transactions), UVM_LOW)

        repeat (max_transactions)
        begin
            item = spi_transaction::type_id::create("req");

            start_item(item);

            assert(this.randomize());

            finish_item(item);
        end

        if (starting_phase != null)
        begin
            starting_phase.drop_objection(this);
        end
    endtask

endclass : spi_seq


// =============================================================================
// I2C Sequence
// =============================================================================
class i2c_seq extends uvm_sequence #(i2c_transaction);
    `uvm_object_utils(i2c_seq)

    function new(string name = "i2c_seq");
        super.new(name);
    endfunction

    task body();
        i2c_transaction item;

        `uvm_info("I2C SEQUENCE", "Starting random I2C commands", UVM_LOW)
        
        item = i2c_transaction::type_id::create("item");

        start_item(item);
        assert(item.randomize());
        finish_item(item);
    endtask

endclass : i2c_seq


// =============================================================================
// TIMER Sequence - Como não envia dados, não é necessária
// =============================================================================


// =============================================================================
// Virtual Sequences - Coordinate multiple protocol agents
// =============================================================================
class soc_virtual_seq extends uvm_sequence;
    `uvm_object_utils(soc_virtual_seq)
    `uvm_declare_p_sequencer(soc_virtual_sequencer)
    
    function new(string name = "soc_virtual_base_seq");
        super.new(name);
    endfunction
    
    task body();
        bootloader_seq bootloader_sequence;
        uart_seq uart_sequence;
        uvm_event ev_boot_done = uvm_event_pool::get_global("ev_boot_done");
        uvm_event ev_initial_msg_done = uvm_event_pool::get_global("ev_initial_msg_done");
        bit             timed_out;

        `uvm_info("VIRTUAL SEQUENCE", "Starting tests", UVM_LOW)
        // Bootloader
        bootloader_sequence = bootloader_seq::type_id::create("bootloader_sequence");
        bootloader_sequence.start(p_sequencer.bootloader_seqr);  // bloqueia até terminar

        timed_out = 0;
        fork
        begin
            `uvm_info("VIRTUAL SEQUENCE", "Waiting boot_done", UVM_NONE)
            ev_boot_done.wait_ptrigger();
            `uvm_info("VIRTUAL SEQUENCE", "boot_done received! Receiving initial message via UART...", UVM_NONE)
            // esperar receber mensagem "SOC IOT PICORV32"
            ev_initial_msg_done.wait_ptrigger();
        end
        begin
            #(200ms);
            timed_out = 1;
            `uvm_error("VIRTUAL SEQUENCE", "Timeout! boot_done não chegou em 100ms")
        end
        join_any
        disable fork;

        if (timed_out) return;

        `uvm_info("VIRTUAL SEQUENCE", "Starting UART tests", UVM_LOW)

        uart_sequence = uart_seq::type_id::create("uart_sequence");
        uart_sequence.start(p_sequencer.uart_seqr);

        `uvm_info("VIRTUAL SEQUENCE", "Tests finished", UVM_LOW)
    endtask
endclass : soc_virtual_seq

`endif // soc_sequences_SV