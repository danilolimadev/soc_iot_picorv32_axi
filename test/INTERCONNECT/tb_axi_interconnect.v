`timescale 1ns/1ps

module tb_axi_interconnect;

    reg clk;
    reg resetn;

    
    // MASTER
    reg  [31:0] m_awaddr;
    reg         m_awvalid;
    wire        m_awready;

    reg  [31:0] m_wdata;
    reg  [3:0]  m_wstrb;
    reg         m_wvalid;
    wire        m_wready;

    wire [1:0]  m_bresp;
    wire        m_bvalid;
    reg         m_bready;

    reg  [31:0] m_araddr;
    reg         m_arvalid;
    wire        m_arready;

    wire [31:0] m_rdata;
    wire [1:0]  m_rresp;
    wire        m_rvalid;
    reg         m_rready;


    // RAM SLAVE MODEL
    reg  ram_awready;
    reg  ram_wready;
    reg  ram_bvalid;
    reg  [1:0] ram_bresp;

    reg  ram_arready;
    reg  ram_rvalid;
    reg  [31:0] ram_rdata;
    reg  [1:0]  ram_rresp;

    
    // GPIO SLAVE MODEL
    reg gpio_awready;
    reg gpio_wready;
    reg gpio_bvalid;
    reg [1:0] gpio_bresp;

    reg gpio_arready;
    reg gpio_rvalid;
    reg [31:0] gpio_rdata;
    reg [1:0] gpio_rresp;


    // Outros slaves (fixos)
    wire uart_awready = 1'b1;
    wire uart_wready  = 1'b1;
    wire uart_arready = 1'b1;
    wire uart_bvalid  = 1'b0;
    wire [1:0] uart_bresp = 2'b00;
    wire uart_rvalid  = 1'b0;
    wire [31:0] uart_rdata = 32'hAABBCCDD;
    wire [1:0] uart_rresp = 2'b00;

    wire spi_awready = 1'b1;
    wire spi_wready  = 1'b1;
    wire spi_arready = 1'b1;
    wire spi_bvalid  = 1'b0;
    wire [1:0] spi_bresp = 2'b00;
    wire spi_rvalid  = 1'b0;
    wire [31:0] spi_rdata = 32'h0;
    wire [1:0] spi_rresp = 2'b00;

    wire i2c_awready = 1'b1;
    wire i2c_wready  = 1'b1;
    wire i2c_arready = 1'b1;
    wire i2c_bvalid  = 1'b0;
    wire [1:0] i2c_bresp = 2'b00;
    wire i2c_rvalid  = 1'b0;
    wire [31:0] i2c_rdata = 32'h0;
    wire [1:0] i2c_rresp = 2'b00;

    wire timer_awready = 1'b1;
    wire timer_wready  = 1'b1;
    wire timer_arready = 1'b1;
    wire timer_bvalid  = 1'b0;
    wire [1:0] timer_bresp = 2'b00;
    wire timer_rvalid  = 1'b0;
    wire [31:0] timer_rdata = 32'h0;
    wire [1:0] timer_rresp = 2'b00;

    
    axi_interconnect dut (
        .clk(clk),
        .resetn(resetn),

        .m_awaddr(m_awaddr),
        .m_awvalid(m_awvalid),
        .m_awready(m_awready),
        .m_wdata(m_wdata),
        .m_wstrb(m_wstrb),
        .m_wvalid(m_wvalid),
        .m_wready(m_wready),
        .m_bresp(m_bresp),
        .m_bvalid(m_bvalid),
        .m_bready(m_bready),

        .m_araddr(m_araddr),
        .m_arvalid(m_arvalid),
        .m_arready(m_arready),
        .m_rdata(m_rdata),
        .m_rresp(m_rresp),
        .m_rvalid(m_rvalid),
        .m_rready(m_rready),

        .ram_awready(ram_awready),
        .ram_wready(ram_wready),
        .ram_bvalid(ram_bvalid),
        .ram_bresp(ram_bresp),
        .ram_arready(ram_arready),
        .ram_rvalid(ram_rvalid),
        .ram_rdata(ram_rdata),
        .ram_rresp(ram_rresp),

        .gpio_awready(gpio_awready),
        .gpio_wready(gpio_wready),
        .gpio_bvalid(gpio_bvalid),
        .gpio_bresp(gpio_bresp),
        .gpio_arready(gpio_arready),
        .gpio_rvalid(gpio_rvalid),
        .gpio_rdata(gpio_rdata),
        .gpio_rresp(gpio_rresp),

        .uart_awready(uart_awready),
        .uart_wready(uart_wready),
        .uart_bvalid(uart_bvalid),
        .uart_bresp(uart_bresp),
        .uart_arready(uart_arready),
        .uart_rvalid(uart_rvalid),
        .uart_rdata(uart_rdata),
        .uart_rresp(uart_rresp),

        .spi_awready(spi_awready),
        .spi_wready(spi_wready),
        .spi_bvalid(spi_bvalid),
        .spi_bresp(spi_bresp),
        .spi_arready(spi_arready),
        .spi_rvalid(spi_rvalid),
        .spi_rdata(spi_rdata),
        .spi_rresp(spi_rresp),

        .i2c_awready(i2c_awready),
        .i2c_wready(i2c_wready),
        .i2c_bvalid(i2c_bvalid),
        .i2c_bresp(i2c_bresp),
        .i2c_arready(i2c_arready),
        .i2c_rvalid(i2c_rvalid),
        .i2c_rdata(i2c_rdata),
        .i2c_rresp(i2c_rresp),

        .timer_awready(timer_awready),
        .timer_wready(timer_wready),
        .timer_bvalid(timer_bvalid),
        .timer_bresp(timer_bresp),
        .timer_arready(timer_arready),
        .timer_rvalid(timer_rvalid),
        .timer_rdata(timer_rdata),
        .timer_rresp(timer_rresp)
    );

    
    always #5 clk = ~clk;


    initial begin
        clk = 0;
        resetn = 0;

        m_awvalid = 0;
        m_wvalid  = 0;
        m_arvalid = 0;
        m_bready  = 1;
        m_rready  = 1;

        ram_awready = 1;
        ram_wready  = 1;
        ram_bvalid  = 0;
        ram_bresp   = 2'b00;
        ram_arready = 1;
        ram_rvalid  = 0;
        ram_rdata   = 32'hCAFEBABE;
        ram_rresp   = 2'b00;

        gpio_awready = 1;
        gpio_wready  = 1;
        gpio_bvalid  = 0;
        gpio_bresp   = 2'b00;
        gpio_arready = 1;
        gpio_rvalid  = 0;
        gpio_rdata   = 32'h12345678;
        gpio_rresp   = 2'b00;

        #20 resetn = 1;

        
        // TESTE 1 - WRITE RAM
        @(posedge clk);
        m_awaddr  = 32'h0000_0010;
        m_wdata   = 32'hDEADBEEF;
        m_wstrb   = 4'hF;
        m_awvalid = 1;
        m_wvalid  = 1;

        @(posedge clk);
        m_awvalid = 0;
        m_wvalid  = 0;

        ram_bvalid = 1;
        @(posedge clk);
        ram_bvalid = 0;

        if (!m_bvalid) begin
            $display("TEST 1 FAIL: Write RAM");
            $stop;
        end
        else begin
            $display("TEST 1 PASS: Write RAM");
        end


        
        // TESTE 2 - READ GPIO
        @(posedge clk);
        m_araddr  = 32'h1000_0004;
        m_arvalid = 1;

        @(posedge clk);
        m_arvalid = 0;

        gpio_rvalid = 1;
        @(posedge clk);
        gpio_rvalid = 0;

        if (!m_rvalid) begin
            $display("TEST 2 FAIL: Read GPIO - RVALID");
            $stop;
        end

        if (m_rdata != 32'h12345678) begin
            $display("TEST 2 FAIL: Read GPIO - DATA");
            $stop;
        end
        else begin
            $display("TEST 2 PASS: Read GPIO");
        end


        $display("======================================");
        $display("ALL TESTS PASSED ");
        $display("======================================");

        #20 
        $stop;
    end

endmodule
