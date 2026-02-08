`timescale 1ns/1ps

module tb_axi_spi;

    reg clk;
    reg resetn;

    always #5 clk = ~clk; // 100 MHz

    reg  [11:0] s_axi_awaddr;
    reg         s_axi_awvalid;
    wire        s_axi_awready;

    reg  [31:0] s_axi_wdata;
    reg  [3:0]  s_axi_wstrb;
    reg         s_axi_wvalid;
    wire        s_axi_wready;

    wire [1:0]  s_axi_bresp;
    wire        s_axi_bvalid;
    reg         s_axi_bready;

    reg  [11:0] s_axi_araddr;
    reg         s_axi_arvalid;
    wire        s_axi_arready;

    wire [31:0] s_axi_rdata;
    wire [1:0]  s_axi_rresp;
    wire        s_axi_rvalid;
    reg         s_axi_rready;



    wire spi_sck;
    wire spi_mosi;
    wire spi_cs;
    wire spi_miso;

    // Loopback SPI
    assign spi_miso = spi_mosi;


    axi_spi dut (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),

        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs(spi_cs)
    );

    // tasks
    task axi_write;
        input [11:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            s_axi_awaddr  <= addr;
            s_axi_awvalid <= 1;
            s_axi_wdata   <= data;
            s_axi_wstrb   <= 4'hF;
            s_axi_wvalid  <= 1;
            s_axi_bready  <= 1;

            wait (s_axi_awready && s_axi_wready);
            @(posedge clk);
            s_axi_awvalid <= 0;
            s_axi_wvalid  <= 0;

            wait (s_axi_bvalid);
            @(posedge clk);
            s_axi_bready <= 0;
        end
    endtask

    task axi_read;
        input  [11:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            s_axi_araddr  <= addr;
            s_axi_arvalid <= 1;
            s_axi_rready  <= 1;

            wait (s_axi_arready);
            @(posedge clk);
            s_axi_arvalid <= 0;

            wait (s_axi_rvalid);
            data = s_axi_rdata;
            @(posedge clk);
            s_axi_rready <= 0;
        end
    endtask

    // test
    reg [31:0] rx;

    initial begin
        // init
        clk = 0;
        resetn = 0;

        s_axi_awaddr  = 0;
        s_axi_awvalid = 0;
        s_axi_wdata   = 0;
        s_axi_wstrb   = 0;
        s_axi_wvalid  = 0;
        s_axi_bready  = 0;
        s_axi_araddr  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 0;

        // reset
        repeat (5) @(posedge clk);
        resetn = 1;

        $display("=== AXI-SPI TEST START ===");

        // TXDATA = 0xA5
        axi_write(12'h004, 32'h000000A5);

        // START = 1
        axi_write(12'h000, 32'h00000001);

        // wait SPI end
        wait (dut.spi_busy == 1);
        wait (dut.spi_busy == 0);

        // Read RXDATA
        axi_read(12'h008, rx);

        $display("RXDATA = 0x%02X", rx[7:0]);

        if (rx[7:0] == 8'hA5)
            $display(" TEST PASSED");
        else
            $display(" TEST FAILED");

        #50;
        $finish;
    end

endmodule
