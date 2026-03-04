`timescale 1ns/1ps

module aa_soc_tb;

    parameter CLK_PERIOD = 20; // 50 MHz
    parameter CLK_FREQ   = 50_000_000;
    parameter BAUD_RATE  = 9600;
    localparam integer BIT_CLKS = CLK_FREQ / BAUD_RATE;

    wire clk;
    reg resetn;
    wire boot_done;

    reg boot_mode;

    wire uart_tx;
    reg uart_rx;

    wire spi_mosi, spi_miso, spi_sck, spi_cs;
    assign spi_miso = 0;

    wire i2c_sda;
    wire i2c_scl;
    pullup(i2c_sda);
    pullup(i2c_scl);
    reg tb_drive_sda_low = 0;
    assign i2c_sda = (tb_drive_sda_low) ? 1'b0 : 1'bz;

    wire [31:0] gpio_out;
    wire        trap;
    wire        timer_irq;

    integer j;
    reg [7:0] data;

    clockGeneratorByPeriod #(CLK_PERIOD) clock(clk);

    soc_bootloader_complete DUT(
                                clk,
                                resetn,
                                boot_mode,
                                boot_done,
                                trap,
                                gpio_out,
                                timer_irq,
                                uart_tx,
                                uart_rx,
                                spi_mosi,
                                spi_miso,
                                spi_sck,
                                spi_cs,
                                i2c_sda,
                                i2c_scl
    );

    initial
    begin
        resetn   = 0;
        boot_mode = 0;
        #200;
        resetn   = 1;

        // Ativa modo boot após reset
        #100;
        boot_mode = 1;

        wait(DUT.soc.boot_mgr.rom_done);

        boot_mode = 0;

        #1000
        
        // escrevendo via uart
        data = 8'hA5; // Dado a ser transmitido

        uart_rx = 1; // idle state
        
        uart_rx = 0; #(BIT_CLKS * CLK_PERIOD); // Start
        for(j=0; j<8; j=j+1)
        begin
            uart_rx = data[j]; #(BIT_CLKS * CLK_PERIOD); 
        end
        uart_rx = 1; #(BIT_CLKS * CLK_PERIOD); // Stop

        #11000;
        $stop;
    end

endmodule

module clockGeneratorByPeriod #(parameter period = 5)(
    output clk
);
    reg outClk;

    initial outClk = 1'b0;                   // clk is initially 0

    always
    begin
        #(period/2) outClk = ~outClk;        // after a delay of period, the clk receives its inverse
    end

    assign clk = outClk;

endmodule