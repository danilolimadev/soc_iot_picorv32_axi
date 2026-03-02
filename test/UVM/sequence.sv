`ifndef soc_sequences_SV
`define soc_sequences_SV

`include "soc_macros.svh"
`include "transaction.sv"

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

    int unsigned max_transactions = 1;

    function new(string name = "uart_seq");
        super.new(name);
        `uvm_info("UART SEQUENCE", "NEW", UVM_LOW)
    endfunction

    task body();
        uart_transaction item;

        if (starting_phase != null)
        begin
            starting_phase.raise_objection(this);
        end

        `uvm_info("UART SEQUENCE", $sformatf("Starting %0d random UART commands", max_transactions), UVM_LOW)

        repeat (max_transactions)
        begin
            item = uart_transaction::type_id::create("req");

            start_item(item);

            assert(this.randomize());
            `uvm_info("UART SEQUENCE", $sformatf("Sending command: 0x%h", item.data_sent), UVM_MEDIUM)

            finish_item(item);
        end

        if (starting_phase != null)
        begin
            starting_phase.drop_objection(this);
        end
    endtask

endclass : uart_seq

`endif // soc_sequences_SV