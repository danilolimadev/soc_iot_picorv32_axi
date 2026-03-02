`timescale 1ns/1ps
// =============================================================
// Testbench do SoC
// =============================================================

module soc_tb;

  // =========================================================
  // CLOCK E RESET
  // =========================================================

  reg clk;
  reg resetn;
  reg boot_mode;     // Controle do modo boot

  // Clock 50 MHz (período = 20ns)
  initial begin
    clk = 0;
    forever #10 clk = ~clk;
  end

  // Sequência de reset + ativação do boot
  initial begin
    resetn   = 0;
    boot_mode = 0;

    #200;
    resetn   = 1;        // Libera reset

    #100;
    boot_mode = 1;       // Ativa boot após reset
  end

  // UART
  wire uart_tx;
  reg  uart_rx;

  // SPI
  wire spi_mosi;
  wire spi_miso;
  wire spi_sck;
  wire spi_cs;

  assign spi_miso = 1'b0;   // SPI não utilizado (MISO fixo)

  // I2C
  wire i2c_sda;
  wire i2c_scl;

  pullup(i2c_sda);
  pullup(i2c_scl);

  reg tb_drive_sda_low = 0;
  assign i2c_sda = (tb_drive_sda_low) ? 1'b0 : 1'bz;

  // Outros sinais
  wire [31:0] gpio_out;
  wire        trap;
  wire        timer_irq;

  wire        uart_rx_boot;
  wire [31:0] firmware_size;


  // =========================================================
  // INSTÂNCIA DO BOOTLOADER UART
  // =========================================================

  bootloader_uart #(
    .FIRMWARE_FILE("firmware.hex")
  ) tb_boot (
    .clk(clk),
    .resetn(resetn),
    .boot_enable(boot_mode),
    .uart_tx(uart_rx_boot),   // Conectado ao RX de boot do SoC
    .done(),
    .firmware_size(firmware_size)
  );


  // =========================================================
  // INSTÂNCIA DO SoC
  // =========================================================

  soc_top uut (
    .clk(clk),
    .resetn(resetn),
    .boot_mode(boot_mode),
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
  // MONITOR DE BOOT + TESTE DE UART
  // =========================================================

  initial begin
    uart_rx = 1'b1;   // Linha UART idle (nível alto)

    wait(boot_mode);
    $display("\n[TB] Bootloader ativado...");

    // Aguarda ROM terminar de receber firmware
    wait(uut.boot_mgr.rom_done);

    boot_mode = 0;
    $display("[TB] ROM terminou de receber firmware!");

    // Aguarda execução normal
    #3000000;

    // Envio de bytes para teste
    send_and_log("A", 8'h41, 100000);
    send_and_log("B", 8'h42, 1300000);
    send_and_log("C", 8'h43, 200000);
    send_and_log("D", 8'h44, 200000);
    send_and_log("E", 8'h45, 200000);

    $stop;
  end


  // =========================================================
  // TASK AUXILIAR: ENVIO + LOG
  // =========================================================

  task send_and_log;
    input [8*1:1] char_name;
    input [7:0]   value;
    input integer delay_after;
    begin
      $display("[TB] Enviando byte '%s'", char_name);
      uart_send_byte(value);
      #(delay_after);
    end
  endtask


  // =========================================================
  // TASK UART - ENVIO DE 1 BYTE (8N1)
  // Baud simulado via delay fixo (#400)
  // =========================================================

  task uart_send_byte;
    input [7:0] data;
    integer i;
    begin
      // Start bit
      uart_rx = 1'b0;
      #400;

      // Data bits (LSB first)
      for (i = 0; i < 8; i = i + 1) begin
        uart_rx = data[i];
        #400;
      end

      // Stop bit
      uart_rx = 1'b1;
      #400;
    end
  endtask
endmodule