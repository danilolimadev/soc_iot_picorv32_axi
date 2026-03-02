`timescale 1ns/1ps

module soc_tb;
    reg clk;
    reg resetn;

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        resetn = 0;
        #200;
        resetn = 1;
    end

    // --- Sinais ---
    wire uart_tx, spi_mosi, spi_miso, spi_sck, spi_cs, uart_rx;
    assign uart_rx = 1'b1;
    assign spi_miso = 0;

    // --- I2C Bidirecional ---
    wire i2c_sda;
    wire i2c_scl;
    
    // PULL-UPS (Obrigatórios para Open-Drain)
    // Se ninguém puxar pra 0, eles garantem que seja 1.
    pullup(i2c_sda);
    pullup(i2c_scl);

    // Variável para o Testbench controlar o ACK
    reg tb_drive_sda_low = 0;
    assign i2c_sda = (tb_drive_sda_low) ? 1'b0 : 1'bz;

    // --- Instância SoC ---
    soc_top uut (
        .clk(clk), .resetn(resetn),
        .uart_tx(uart_tx), .uart_rx(uart_rx),
        .spi_mosi(spi_mosi), .spi_miso(spi_miso),
        .spi_sck(spi_sck), .spi_cs(spi_cs),
        .i2c_sda(i2c_sda), // inout
        .i2c_scl(i2c_scl)  // inout
    );

    // =========================================================
    //  SLAVE I2C MODEL (O "Responder")
    // =========================================================
    // =========================================================
    //  SLAVE I2C MODEL (Receptor de N Bytes)
    // =========================================================
// =========================================================
    //  SLAVE I2C MODEL (Receptor de N Bytes - Verilog Puro)
    // =========================================================
    reg [7:0] captured_addr;
    reg [7:0] captured_data;
    integer i;
    integer byte_count;
    reg stop_detected;

    initial begin
        tb_drive_sda_low = 0; // Slave quieto
        wait(resetn);
        
        forever begin : loop_start
            // 1. Detectar START (SDA desce com SCL alto)
            stop_detected = 0;
            begin : wait_start
                forever begin
                    @(negedge i2c_sda);
                    if (i2c_scl === 1'b1) disable wait_start; // Sai deste loop ao detectar START
                end
            end
            
            $display("[TB SLAVE] Start Condition Detectado!");
            byte_count = 0;

            // 2. Ler Endereço
            for (i=7; i>=0; i=i-1) begin
                @(posedge i2c_scl); 
                captured_addr[i] = i2c_sda;
            end
            $display("[TB SLAVE] Endereco recebido: 0x%h", captured_addr);

            // 3. Enviar ACK do Endereço
            @(negedge i2c_scl); tb_drive_sda_low = 1; 
            @(negedge i2c_scl); tb_drive_sda_low = 0;

            // 4. Loop para ler N Bytes de Dados
            forever begin : receive_bytes
                
                // Em Verilog clássico, usamos fork/join com disable 
                // para sair assim que uma das duas condições acontecer
                fork : wait_bit_or_stop
                    begin
                        @(posedge i2c_scl); // Condição A: Chegou o clock do bit 7
                        disable wait_bit_or_stop;
                    end
                    begin
                        forever begin
                            @(posedge i2c_sda); // Condição B: SDA subiu
                            if (i2c_scl === 1'b1) begin // Se o SCL está alto, é STOP!
                                stop_detected = 1;
                                disable wait_bit_or_stop;
                            end
                        end
                    end
                join

                if (stop_detected) begin
                    $display("[TB SLAVE] Stop Condition. Total de bytes recebidos: %d", byte_count);
                    disable receive_bytes; // Sai do loop de dados e volta a esperar outro START
                end else begin
                    // Se não foi STOP, lemos o bit 7 que ativou a condição A
                    captured_data[7] = i2c_sda;
                    
                    // Lemos os 6 bits restantes (do 6 ao 0)
                    for (i=6; i>=0; i=i-1) begin
                        @(posedge i2c_scl); 
                        captured_data[i] = i2c_sda;
                    end
                    
                    byte_count = byte_count + 1;
                    $display("[TB SLAVE] Dado %d recebido: 0x%h", byte_count, captured_data);

                    // Enviar ACK do Dado
                    @(negedge i2c_scl); tb_drive_sda_low = 1;
                    @(negedge i2c_scl); tb_drive_sda_low = 0;
                end
            end
        end
    end

    // =========================================================
    //  Controle Geral da Simulação
    // =========================================================
    initial begin
        $dumpfile("soc_tb.vcd");
        $dumpvars(0, soc_tb);
        
        // Carrega firmware
        //$readmemh("firmware.hex", uut.cpu.mem_inst.mem);
        $readmemh("firmware.hex", uut.ram_inst.mem);

        #300000; // 300us timeout
        $display("[TB] Timeout.");
        $stop;
    end

endmodule