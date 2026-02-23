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
    reg [7:0] captured_addr;
    reg [7:0] captured_data;
    integer i;

    initial begin
        tb_drive_sda_low = 0; // Slave quieto
        wait(resetn);
        
        // 1. Detectar START (SDA desce com SCL alto)
        @(negedge i2c_sda); 
        $display("[TB SLAVE] Start Condition Detectado!");

        // 2. Ler 8 bits de Endereço
        for (i=7; i>=0; i=i-1) begin
            @(posedge i2c_scl); // Na subida do clock, lemos o dado
            captured_addr[i] = i2c_sda;
        end
        $display("[TB SLAVE] Endereco recebido: 0x%h", captured_addr);

        // 3. Enviar ACK do Endereço
        // Esperamos o clock descer (Master libera linha)
        @(negedge i2c_scl);
        tb_drive_sda_low = 1; // PUXAMOS O SDA PRA BAIXO (ACK!)
        $display("[TB SLAVE] Enviando ACK...");
        
        // Esperamos o pulso de clock do ACK passar
        @(negedge i2c_scl); 
        tb_drive_sda_low = 0; // Soltamos a linha

        // 4. Ler 8 bits de Dados
        for (i=7; i>=0; i=i-1) begin
            @(posedge i2c_scl);
            captured_data[i] = i2c_sda;
        end
        $display("[TB SLAVE] Dado recebido: 0x%h", captured_data);

        // 5. Enviar ACK do Dado
        @(negedge i2c_scl);
        tb_drive_sda_low = 1; // ACK!
        $display("[TB SLAVE] Enviando ACK...");
        @(negedge i2c_scl);
        tb_drive_sda_low = 0; // Solta

        // 6. Detectar STOP (SDA sobe com SCL alto)
        @(posedge i2c_sda);
        if (i2c_scl) $display("[TB SLAVE] Stop Condition Detectado. Sucesso Total!");
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