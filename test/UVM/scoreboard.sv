`ifndef SOC_SCOREBOARD_SV
`define SOC_SCOREBOARD_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "transaction.sv" 
`include "soc_macros.svh" 

// declaração dos sufixos para as analysis port de cada monitor
`uvm_analysis_imp_decl(_bootloader)
`uvm_analysis_imp_decl(_uart)
`uvm_analysis_imp_decl(_gpio)
`uvm_analysis_imp_decl(_spi)
`uvm_analysis_imp_decl(_i2c)
`uvm_analysis_imp_decl(_timer)

class soc_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(soc_scoreboard)
    
    uvm_analysis_imp_bootloader #(bootloader_transaction, soc_scoreboard) bootloader_ap_imp;

    uvm_analysis_imp_uart #(uart_transaction, soc_scoreboard) uart_ap_tx_imp;
    uvm_tlm_analysis_fifo #(uart_transaction) uart_ap_rx_imp;

    uvm_analysis_imp_gpio #(gpio_transaction, soc_scoreboard) gpio_ap_imp;

    uvm_analysis_imp_spi #(spi_transaction, soc_scoreboard) spi_ap_miso_imp;
    uvm_tlm_analysis_fifo #(spi_transaction) spi_ap_mosi_imp;

    uvm_analysis_imp_i2c #(i2c_transaction, soc_scoreboard) i2c_ap_imp;

    uvm_analysis_imp_timer #(timer_transaction, soc_scoreboard) timer_ap_imp;

    int bootload_time = 0;

    int uart_transaction_rx_count = 0;
    int uart_transaction_tx_count = 0;
    int uart_transaction_correct = 0;
    int uart_transaction_wrong = 0;
    string msg_received_uart = "";
    string initial_msg = "";
    bit [UART_DATA_BITS-1:0] uart_cmd_sent[$];

    int gpio_transaction_correct = 0;
    int gpio_transaction_wrong = 0;
    int gpio_transaction_count = 0;

    string msg_received_spi = "";    
    int spi_transaction_correct = 0;
    int spi_transaction_wrong = 0;
    int spi_transaction_miso_count = 0;
    int spi_transaction_mosi_count = 0;

    int i2c_transaction_correct = 0;
    int i2c_transaction_wrong = 0;
    int i2c_transaction_count = 0;

    bit timer_count_finished = 0;
    int timer_transaction_count = 0;    
    int timer_transaction_error = 0;
    int delay_error = 0;
    time start_timer = 0;
    time finish_timer = 0;

    int errors;

    bit [UART_DATA_BITS-1:0] actual_cmd;

    function new(string name = "soc_scoreboard", uvm_component parent = null);
        super.new(name, parent);

        bootloader_ap_imp = new("bootloader_ap_imp", this);
        uart_ap_rx_imp    = new("uart_ap_rx_imp", this);
        uart_ap_tx_imp    = new("uart_ap_tx_imp", this);
        gpio_ap_imp       = new("gpio_ap_imp", this);
        spi_ap_mosi_imp   = new("spi_ap_mosi_imp", this);
        spi_ap_miso_imp   = new("spi_ap_miso_imp", this);
        i2c_ap_imp        = new("i2c_ap_imp", this);
        timer_ap_imp      = new("timer_ap_imp", this);
    endfunction : new

    function void write_bootloader(bootloader_transaction item);
        bootload_time = item.clock_cycles;
        `uvm_info("SCOREBOARD", $sformatf("Boot DONE em %0d ciclos", bootload_time), UVM_MEDIUM);
    endfunction

    // UART transaction check - algum dado foi enviado pela uart
    function void write_uart(uart_transaction item_tx);
        int count = 0;
        uart_transaction_tx_count++;

        `uvm_info("SCOREBOARD", $sformatf("UART Transaction sent to DUT #%0d: Data=0x%0h", uart_transaction_tx_count, item_tx.data), UVM_MEDIUM)
        
        if (item_tx.framing_error)
        begin
            errors++;
        end
        else
        begin
            uart_cmd_sent.push_back(item_tx.data);
        end
    endfunction
    
    function void write_gpio(gpio_transaction item);
        bit [GPIO_DATA_BITS-1:0] expected_data;
        actual_cmd = uart_cmd_sent.pop_front();

        `uvm_info("SCOREBOARD", $sformatf("Recebeu da GPIO: 0x%h depois de 0x%h", item.data, actual_cmd), UVM_MEDIUM);

        case (actual_cmd)
            SEND_DATA_TO_UART:  expected_data = MSG_TO_GPIO_AFTER_SEND_DATA_TO_UART;
            SEND_DATA_TO_I2C:   expected_data = MSG_TO_GPIO_AFTER_SEND_DATA_TO_I2C;
            SEND_DATA_TO_SPI:   expected_data = MSG_TO_GPIO_AFTER_SEND_DATA_TO_SPI;
            SEND_DATA_TO_GPIO:  expected_data = MSG_TO_GPIO_AFTER_SEND_DATA_TO_GPIO;
            SEND_DATA_TO_TIMER: 
                begin
                    expected_data = MSG_TO_GPIO_AFTER_SEND_DATA_TO_TIMER_INITIAL;
                    start_timer = $time;
                end
            default:            expected_data = MSG_TO_GPIO_DEFAULT;
        endcase

        if (timer_count_finished)
        begin
            expected_data = MSG_TO_GPIO_AFTER_SEND_DATA_TO_TIMER_END;
        end

        if (expected_data == item.data)
        begin
            gpio_transaction_count++;
            gpio_transaction_correct++;
        end
        else if (actual_cmd != 8'h0)
        begin
            gpio_transaction_count++;
            gpio_transaction_wrong++;
            errors++;
            `uvm_info("SCOREBOARD", $sformatf("Expected GPIO: 0x%h | Received GPIO: 0x%h", expected_data, item.data), UVM_MEDIUM);
        end
    endfunction
    
    // SPI transaction check - algum dado foi enviado pela spi
    function void write_spi(spi_transaction item);
        int count = 0;
        spi_transaction_miso_count++;

        `uvm_info("SCOREBOARD", $sformatf("SPI Transaction sent to DUT #%0d: Data=0x%0h", spi_transaction_miso_count, item.data), UVM_MEDIUM)
        
    endfunction

    function void write_i2c(i2c_transaction item);
        bit [I2C_DATA_BITS-1:0] expected_data;

        `uvm_info("SCOREBOARD", $sformatf("I2C received: #%0d: Addr=0x%0h Data=0x%0h", i2c_transaction_count, item.slave_addr, item.data), UVM_MEDIUM)

        expected_data = get_expected_i2c_enum_by_index(i2c_transaction_correct);

        if (expected_data == item.data)
        begin
            i2c_transaction_correct++;
        end
        else
        begin
            i2c_transaction_wrong++;
            errors++;
            `uvm_info("SCOREBOARD", $sformatf("Expected I2C: 0x%h | Received I2C: 0x%h", expected_data, item.data), UVM_MEDIUM);
        end
        i2c_transaction_count++;
    endfunction
    
    function void write_timer(timer_transaction item);
        finish_timer = $time;

        timer_count_finished = 1;
        delay_error = ((finish_timer > start_timer ? (finish_timer - start_timer) : (start_timer - finish_timer)) / CLK_PERIOD) - TIMER_EXPECTED_DELAY;
        if (delay_error > DELAY_ERROR)
        begin
            timer_transaction_error++;
            errors++;
        end

        timer_transaction_count++;
    endfunction

    task run_phase(uvm_phase phase);
        uart_transaction uart_item;
        spi_transaction spi_item;

        int count = 0;
        bit first_msg = 1;

        // monitorar mensagens recebidas pela uart
        forever
        begin
            uart_ap_rx_imp.get(uart_item);
            get_msg_uart(uart_item);

            // TODO: REFACTOR TO GET INITIAL MESSAGE OR OTHER MESSAGES AT SAME TIME
            
            if (first_msg == 1)
            begin
                // Receiving initial message
                 count++;

                if (count >= INITIAL_MSG.len())
                begin
                    if (INITIAL_MSG !=  msg_received_uart)
                    begin
                        errors++;
                        uart_transaction_wrong++;
                        uart_transaction_rx_count++;
                        `uvm_info("SCOREBOARD", $sformatf("Expected UART: %s | Received UART: %s", INITIAL_MSG, msg_received_uart), UVM_MEDIUM);
                    end
                    else
                    begin
                        uart_transaction_correct++;
                        uart_transaction_rx_count++;
                    end
                    initial_msg = msg_received_uart;
                    msg_received_uart = "";
                    first_msg = 0;
                    count = 0;
                end
            end
            else
            begin
                count++;

                if (count >= MSG_TO_UART.len())
                begin
                    if (MSG_TO_UART !=  msg_received_uart)
                    begin
                        errors++;
                        uart_transaction_wrong++;
                        uart_transaction_rx_count++;
                        `uvm_info("SCOREBOARD", $sformatf("Esperado UART:%s.", MSG_TO_UART), UVM_MEDIUM);
                        `uvm_info("SCOREBOARD", $sformatf("Recebido UART:%s.", msg_received_uart), UVM_MEDIUM);
                    end
                    else
                    begin
                        uart_transaction_correct++;
                        uart_transaction_rx_count++;
                    end

                    count = 0;
                    msg_received_uart = "";
                end

                spi_ap_mosi_imp.get(spi_item);
                spi_transaction_mosi_count++;

                if (MSG_TO_SPI == spi_item.msg_received)
                begin
                    spi_transaction_correct++;
                end
                else
                begin
                    spi_transaction_wrong++;
                    errors++;
                    `uvm_info("SCOREBOARD", $sformatf("Expected SPI: 0x%h | Received SPI: 0x%h", MSG_TO_SPI, spi_item.msg_received), UVM_MEDIUM);
                end
            end
        end
    endtask

    task get_msg_uart(uart_transaction uart_item);
        if (!uart_item.framing_error)
        begin
            msg_received_uart = {msg_received_uart, bytes_to_string(uart_item.data)};
        end
        else
        begin
            errors++;
            `uvm_info("SCOREBOARD", "Erro no recebimento da msg UART", UVM_MEDIUM);
        end
    endtask

    function string bytes_to_string(logic [7:0] payload);
        string s = "";
        s = {s, string'(payload)};
        return s;
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("SCOREBOARD", "===================== Scoreboard Report ====================", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Bootloader:                      %0d cycles       ", bootload_time), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Initial message received:        %s               ", initial_msg), UVM_LOW)
        `uvm_info("SCOREBOARD", "--------------------------- UART ---------------------------", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("UART write on DUT:               %0d transactions ", uart_transaction_tx_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("UART read from DUT:              %0d transactions ", uart_transaction_rx_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("UART message correctly received: %0d              ", uart_transaction_correct), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("UART message wrongly received:   %0d              ", uart_transaction_wrong), UVM_LOW)
        `uvm_info("SCOREBOARD", "--------------------------- GPIO ---------------------------", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("GPIO read from DUT:              %0d transactions ", gpio_transaction_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("GPIO message correctly received: %0d              ", gpio_transaction_correct), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("GPIO message wrongly received:   %0d              ", gpio_transaction_wrong), UVM_LOW)
        `uvm_info("SCOREBOARD", "--------------------------- SPI ----------------------------", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("SPI write on DUT:                %0d transactions ", spi_transaction_miso_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("SPI read from DUT:               %0d transactions ", spi_transaction_mosi_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("SPI message correctly received:  %0d              ", spi_transaction_correct), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("SPI message wrongly received:    %0d              ", spi_transaction_wrong), UVM_LOW)
        `uvm_info("SCOREBOARD", "--------------------------- I2C ----------------------------", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("I2C:                             %0d transactions ", i2c_transaction_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("I2C message correctly received:  %0d              ", i2c_transaction_correct), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("I2C message wrongly received:    %0d              ", i2c_transaction_wrong), UVM_LOW)
        `uvm_info("SCOREBOARD", "-------------------------- TIMER ---------------------------", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Timer:                           %0d transactions ", timer_transaction_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Delay in clock cycles:           %0d              ", (finish_timer - start_timer)/CLK_PERIOD), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Delay difference:                %0d              ", delay_error), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Delay error:                     %0d              ", timer_transaction_error), UVM_LOW)
        `uvm_info("SCOREBOARD", "------------------------------------------------------------", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Errors:                          %0d              ", errors), UVM_LOW)
        `uvm_info("SCOREBOARD", "============================================================", UVM_LOW)
        
        if(errors > 0)
            `uvm_error("SCOREBOARD", "TEST FAILED: Scoreboard reported mismatches.")
        else
            `uvm_info("SCOREBOARD", "Test completed with NO errors!", UVM_LOW)
    endfunction
endclass

`endif


