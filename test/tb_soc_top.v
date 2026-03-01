`timescale 1ns/1ps

module soc_tb;

  reg clk;
  reg resetn;
  reg boot_mode;   // <<< NOVO

  // Clock 50MHz
  initial
  begin
    clk = 0;
    forever
      #10 clk = ~clk;
  end

  initial
  begin
    resetn   = 0;
    boot_mode = 0;
    #200;
    resetn   = 1;

    // Ativa modo boot após reset
    #100;
    boot_mode = 1;
  end

  // =========================================================
  // SINAIS
  // =========================================================

  wire uart_tx;
  reg uart_rx;

  wire spi_mosi, spi_miso, spi_sck, spi_cs;

  assign spi_miso = 0;

  // UART loop: bootloader TX -> ROM RX
  //assign uart_rx = uart_tx;

  // =========================================================
  // I2C (mantido como estava)
  // =========================================================

  wire i2c_sda;
  wire i2c_scl;

  pullup(i2c_sda);
  pullup(i2c_scl);

  reg tb_drive_sda_low = 0;
  assign i2c_sda = (tb_drive_sda_low) ? 1'b0 : 1'bz;

  wire [31:0] gpio_out;
  wire        trap;
  wire        timer_irq;

  // =========================================================
  // INSTÂNCIA DO SOC
  // =========================================================

  wire uart_rx_boot;
  wire [31:0] firmware_size;

  bootloader_uart #(
                    .FIRMWARE_FILE("firmware.hex")
                  ) tb_boot (
                    .clk(clk),
                    .resetn(resetn),
                    .boot_enable(boot_mode),
                    .uart_tx(uart_rx_boot),  // <- conecta no RX do SoC
                    .done(),
                    .firmware_size(firmware_size)
                  );


  soc_top uut (
            .clk(clk),
            .resetn(resetn),
            .boot_mode(boot_mode),   // <<< IMPORTANTE
            .uart_rx_boot(uart_rx_boot),
            .firmware_size(firmware_size),
            .trap(trap),
            .gpio_out(gpio_out),
            .timer_irq(timer_irq),
            .uart_tx(uart_tx),
            .uart_rx(uart_rx),
            .spi_mosi(spi_mosi),
            .spi_miso(spi_miso),
            .spi_sck(spi_sck),
            .spi_cs(spi_cs),
            .i2c_sda(i2c_sda),
            .i2c_scl(i2c_scl)
          );

  // =========================================================
  // MONITOR DE BOOT
  // =========================================================

  initial
  begin
    uart_rx = 1; // linha idle
    wait(boot_mode);
    $display("\n[TB] Bootloader ativado...");
    wait(uut.boot_mgr.rom_done);
    boot_mode = 0;
    $display("[TB] ROM terminou de receber firmware!");

    #3000000;

    $display("[TB] Enviando byte 'A'");
    uart_send_byte(8'h41);

    #100000;

    $display("[TB] Enviando byte 'B'");
    uart_send_byte(8'h42);
    #100000;
    $stop;

  end

  // =========================================================
  // SLAVE I2C (igual ao seu)
  // =========================================================

  reg [7:0] captured_addr;
  reg [7:0] captured_data;
  integer i;

  initial
  begin
      tb_drive_sda_low = 0;
      wait(resetn);
      
      forever begin
          // Espera start condition (SDA cai com SCL alto)
          @(negedge i2c_sda);
          wait(i2c_scl == 1);
          $display("[TB SLAVE] Start Condition Detectado!");

          // Captura endereço
          for (i=7; i>=0; i=i-1) begin
              @(posedge i2c_scl);
              captured_addr[i] = i2c_sda;
          end
          $display("[TB SLAVE] Endereco recebido: 0x%h", captured_addr);

          // ACK do endereço
          @(negedge i2c_scl);
          tb_drive_sda_low = 1;   // ACK
          @(negedge i2c_scl);
          tb_drive_sda_low = 0;

          // Captura dados
          for (i=7; i>=0; i=i-1) begin
              @(posedge i2c_scl);
              captured_data[i] = i2c_sda;
          end
          $display("[TB SLAVE] Dado recebido: 0x%h", captured_data);

          // ACK do dado
          @(negedge i2c_scl);
          tb_drive_sda_low = 1;
          @(negedge i2c_scl);
          tb_drive_sda_low = 0;

          // Espera stop
          @(posedge i2c_sda);
          if (i2c_scl)
              $display("[TB SLAVE] Stop Condition Detectado. Sucesso Total!");
      end
  end

  task uart_send_byte;
    input [7:0] data;
    integer i;
    begin
        // Start bit
        uart_rx = 0;
        #(400);

        // Data bits
        for (i=0; i<8; i=i+1)
        begin
            uart_rx = data[i];
            #(400);
        end

        // Stop bit
        uart_rx = 1;
        #(400);
    end
  endtask

  // =========================================================
  // TIMEOUT GERAL
  // =========================================================

  initial
  begin
    #100000000; // 1ms
    $display("\n[TB] Timeout.");
    $stop;
  end

endmodule
