`timescale 1ns/1ps

module soc_tb;
    reg clk;
    reg resetn;
    wire uart_tx;
    reg  uart_rx = 1'b1;
    
    // Periféricos Dummy
    wire spi_sck, spi_mosi, spi_miso, spi_cs;
    assign spi_miso = 1'b0;
    wire i2c_sda, i2c_scl;
    pullup(i2c_sda);
    pullup(i2c_scl);

    // Clock 50MHz
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // Reset
    initial begin
        resetn = 0;
        #200;
        resetn = 1;
    end

    // Instância SoC
    soc_top uut (
        .clk(clk), .resetn(resetn),
        .uart_tx(uart_tx), .uart_rx(uart_rx),
        .spi_mosi(spi_mosi), .spi_miso(spi_miso), .spi_sck(spi_sck), .spi_cs(spi_cs),
        .i2c_sda(i2c_sda), .i2c_scl(i2c_scl)
    );

    // Monitoramento UART
    reg [9:0] uart_shift;
    reg [7:0] char_rx;
    integer bit_count;
    realtime baud_period = 400; // Baud rate simulado
    integer estagio = 0; 

    initial begin
        wait(resetn);
        $display("\n=== Simulação Iniciada: Teste Sequencial A -> B -> C ===\n");

        forever begin
            @(negedge uart_tx);
            #(baud_period/2); 
            
            uart_shift = 0;
            for (bit_count = 0; bit_count < 10; bit_count = bit_count + 1) begin
                uart_shift[bit_count] = uart_tx;
                #(baud_period);
            end

            if (uart_shift[0] == 0 && uart_shift[9] == 1) begin
                char_rx = uart_shift[8:1];
                $display("[UART RX] Recebido: %c", char_rx);

                if (estagio == 0) begin
                    if (char_rx == "A") begin
                        $display("  -> Passo 1 (Timer Lento) [OK]");
                        estagio = 1;
                    end else begin $display("  [ERRO] Esperava A"); $stop; end
                end
                else if (estagio == 1) begin
                    if (char_rx == "B") begin
                        $display("  -> Passo 2 (Timer Loop) [OK]");
                        estagio = 2;
                    end else begin $display("  [ERRO] Esperava B"); $stop; end
                end
                else if (estagio == 2) begin
                    if (char_rx == "C") begin
                        $display("  -> Passo 3 (Timer Reconfigurado Rápido) [OK]");
                        $display("\n=== SUCESSO TOTAL: 3 TESTES PASSARAM! ===");
                        $finish;
                    end else begin $display("  [ERRO] Esperava C"); $stop; end
                end
            end
        end
    end

    // Timeout
    initial begin
        wait(resetn);
        #200000; 
        $display("\n[TIMEOUT] Falha: O teste demorou demais.");
        $stop;
    end

endmodule