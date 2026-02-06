module soc_top (
    input  wire clk,
    input  wire resetn,

    // UART
    output wire uart_tx,
    input  wire uart_rx,

    // SPI
    output wire spi_mosi,
    input  wire spi_miso,
    output wire spi_sck,
    output wire spi_cs,

    // I2C
    input  wire i2c_sda, //não usado
    input  wire i2c_scl  //não usado
);

    wire trap;

    // timer IRQ is produced by the timer inside the SoC
    wire timer_irq;

    wire        mem_axi_awvalid;
    wire         mem_axi_awready;
    wire [31:0] mem_axi_awaddr;
    wire [ 2:0] mem_axi_awprot;

    wire        mem_axi_wvalid;
    wire         mem_axi_wready;
    wire [31:0] mem_axi_wdata;
    wire [ 3:0] mem_axi_wstrb;

    wire         mem_axi_bvalid;
    wire        mem_axi_bready;

    wire        mem_axi_arvalid;
    wire         mem_axi_arready;
    wire [31:0] mem_axi_araddr;
    wire [ 2:0] mem_axi_arprot;

    wire         mem_axi_rvalid;
    wire        mem_axi_rready;
    wire  [31:0] mem_axi_rdata;

    wire        pcpi_valid;
    wire [31:0] pcpi_insn;
    wire [31:0] pcpi_rs1;
    wire [31:0] pcpi_rs2;
    reg         pcpi_wr;
    reg  [31:0] pcpi_rd;
    reg         pcpi_wait;
    reg         pcpi_ready;

    wire  [31:0] irq;
    wire [31:0] eoi;

    wire        trace_valid;
    wire [35:0] trace_data;

    assign irq = {31'd0, timer_irq};

    // =========================================================================
    //  CPU
    // =========================================================================
    picorv32_axi #(
        .PROGADDR_RESET(32'h00000000),
        .STACKADDR     (32'h00001000)
        ) cpu (
                 .clk(clk),
                 .resetn(resetn),
                 .trap(trap),

                 .mem_axi_awvalid(mem_axi_awvalid),
                 .mem_axi_awready(mem_axi_awready),
                 .mem_axi_awaddr(mem_axi_awaddr),
                 .mem_axi_awprot(mem_axi_awprot),

                 .mem_axi_wvalid(mem_axi_wvalid),
                 .mem_axi_wready(mem_axi_wready),
                 .mem_axi_wdata(mem_axi_wdata),
                 .mem_axi_wstrb(mem_axi_wstrb),

                 .mem_axi_bvalid(mem_axi_bvalid),
                 .mem_axi_bready(mem_axi_bready),

                 .mem_axi_arvalid(mem_axi_arvalid),
                 .mem_axi_arready(mem_axi_arready),
                 .mem_axi_araddr(mem_axi_araddr),
                 .mem_axi_arprot(mem_axi_arprot),

                 .mem_axi_rvalid(mem_axi_rvalid),
                 .mem_axi_rready(mem_axi_rready),
                 .mem_axi_rdata(mem_axi_rdata),

                 .pcpi_valid(pcpi_valid),
                 .pcpi_insn(pcpi_insn),
                 .pcpi_rs1(pcpi_rs1),
                 .pcpi_rs2(pcpi_rs2),
                 .pcpi_wr(pcpi_wr),
                 .pcpi_rd(pcpi_rd),
                 .pcpi_wait(pcpi_wait),
                 .pcpi_ready(pcpi_ready),

                 .irq(irq),
                 .eoi(eoi),

                 .trace_valid(trace_valid),
                 .trace_data(trace_data)
               );

    // Sinais entre interconector e RAM
    wire [31:0] ram_awaddr;
    wire        ram_awvalid;
    wire        ram_awready;
    wire [31:0] ram_wdata;
    wire [3:0]  ram_wstrb;
    wire        ram_wvalid;
    wire        ram_wready;
    wire [1:0]  ram_bresp;
    wire        ram_bvalid;
    wire        ram_bready;
    wire [31:0] ram_araddr;
    wire        ram_arvalid;
    wire        ram_arready;
    wire [31:0] ram_rdata;
    wire [1:0]  ram_rresp;
    wire        ram_rvalid;
    wire        ram_rready;

    // Sinais entre interconector e GPIO
    wire [11:0] gpio_awaddr;
    wire        gpio_awvalid;
    wire        gpio_awready;
    wire [31:0] gpio_wdata;
    wire [3:0]  gpio_wstrb;
    wire        gpio_wvalid;
    wire        gpio_wready;
    wire [1:0]  gpio_bresp;
    wire        gpio_bvalid;
    wire        gpio_bready;
    wire [11:0] gpio_araddr;
    wire        gpio_arvalid;
    wire        gpio_arready;
    wire [31:0] gpio_rdata;
    wire [1:0]  gpio_rresp;
    wire        gpio_rvalid;
    wire        gpio_rready;
    wire [31:0] gpio_out;

    // Sinais entre interconector e UART
    wire [11:0] uart_awaddr;
    wire        uart_awvalid;
    wire        uart_awready;
    wire [31:0] uart_wdata;
    wire [3:0]  uart_wstrb;
    wire        uart_wvalid;
    wire        uart_wready;
    wire [1:0]  uart_bresp;
    wire        uart_bvalid;
    wire        uart_bready;
    wire [11:0] uart_araddr;
    wire        uart_arvalid;
    wire        uart_arready;
    wire [31:0] uart_rdata;
    wire [1:0]  uart_rresp;
    wire        uart_rvalid;
    wire        uart_rready;

    // Sinais entre interconector e o SPI

    wire [11:0] spi_awaddr;
    wire        spi_awvalid;
    wire        spi_awready;
    wire [31:0] spi_wdata;
    wire [3:0]  spi_wstrb;
    wire        spi_wvalid;
    wire        spi_wready;
    wire [1:0]  spi_bresp;
    wire        spi_bvalid;
    wire        spi_bready;
    wire [11:0] spi_araddr;
    wire        spi_arvalid;
    wire        spi_arready;
    wire [31:0] spi_rdata;
    wire [1:0]  spi_rresp;
    wire        spi_rvalid;
    wire        spi_rready;

    // Sinais entre interconector e o I2C
    wire [11:0] i2c_awaddr;
    wire        i2c_awvalid;
    wire        i2c_awready;
    wire [31:0] i2c_wdata;
    wire [3:0]  i2c_wstrb;
    wire        i2c_wvalid;
    wire        i2c_wready;
    wire [1:0]  i2c_bresp;
    wire        i2c_bvalid;
    wire        i2c_bready;
    wire [11:0] i2c_araddr;
    wire        i2c_arvalid;
    wire        i2c_arready;
    wire [31:0] i2c_rdata;
    wire [1:0]  i2c_rresp;
    wire        i2c_rvalid;
    wire        i2c_rready;

    // Sinais entre interconector e o Timer
    wire [11:0] timer_awaddr;
    wire        timer_awvalid;
    wire        timer_awready;
    wire [31:0] timer_wdata;
    wire [3:0]  timer_wstrb;
    wire        timer_wvalid;
    wire        timer_wready;
    wire [1:0]  timer_bresp;
    wire        timer_bvalid;
    wire        timer_bready;
    wire [11:0] timer_araddr;
    wire        timer_arvalid;
    wire        timer_arready;
    wire [31:0] timer_rdata;
    wire [1:0]  timer_rresp;
    wire        timer_rvalid;
    wire        timer_rready;

  axi_interconnect interconnect (
                     .clk(clk),
                     .resetn(resetn),

                     // Mestre
                     .m_awaddr(mem_axi_awaddr),
                     .m_awvalid(mem_axi_awvalid),
                     .m_awready(mem_axi_awready),
                     .m_wdata(mem_axi_wdata),
                     .m_wstrb(mem_axi_wstrb),
                     .m_wvalid(mem_axi_wvalid),
                     .m_wready(mem_axi_wready),
                     .m_bresp(mem_axi_bresp),
                     .m_bvalid(mem_axi_bvalid),
                     .m_bready(mem_axi_bready),
                     .m_araddr(mem_axi_araddr),
                     .m_arvalid(mem_axi_arvalid),
                     .m_arready(mem_axi_arready),
                     .m_rdata(mem_axi_rdata),
                     .m_rresp(mem_axi_rresp),
                     .m_rvalid(mem_axi_rvalid),
                     .m_rready(mem_axi_rready),

                     // RAM
                     .ram_awaddr(ram_awaddr),
                     .ram_awvalid(ram_awvalid),
                     .ram_awready(ram_awready),
                     .ram_wdata(ram_wdata),
                     .ram_wstrb(ram_wstrb),
                     .ram_wvalid(ram_wvalid),
                     .ram_wready(ram_wready),
                     .ram_bresp(ram_bresp),
                     .ram_bvalid(ram_bvalid),
                     .ram_bready(ram_bready),
                     .ram_araddr(ram_araddr),
                     .ram_arvalid(ram_arvalid),
                     .ram_arready(ram_arready),
                     .ram_rdata(ram_rdata),
                     .ram_rresp(ram_rresp),
                     .ram_rvalid(ram_rvalid),
                     .ram_rready(ram_rready),

                     // GPIO
                     .gpio_awaddr(gpio_awaddr),
                     .gpio_awvalid(gpio_awvalid),
                     .gpio_awready(gpio_awready),
                     .gpio_wdata(gpio_wdata),
                     .gpio_wstrb(gpio_wstrb),
                     .gpio_wvalid(gpio_wvalid),
                     .gpio_wready(gpio_wready),
                     .gpio_bresp(gpio_bresp),
                     .gpio_bvalid(gpio_bvalid),
                     .gpio_bready(gpio_bready),
                     .gpio_araddr(gpio_araddr),
                     .gpio_arvalid(gpio_arvalid),
                     .gpio_arready(gpio_arready),
                     .gpio_rdata(gpio_rdata),
                     .gpio_rresp(gpio_rresp),
                     .gpio_rvalid(gpio_rvalid),
                     .gpio_rready(gpio_rready),

                     //UART
                     .uart_awaddr(uart_awaddr),
                     .uart_awvalid(uart_awvalid),
                     .uart_awready(uart_awready),
                     .uart_wdata(uart_wdata),
                     .uart_wstrb(uart_wstrb),
                     .uart_wvalid(uart_wvalid),
                     .uart_wready(uart_wready),
                     .uart_bresp(uart_bresp),
                     .uart_bvalid(uart_bvalid),
                     .uart_bready(uart_bready),
                     .uart_araddr(uart_araddr),
                     .uart_arvalid(uart_arvalid),
                     .uart_arready(uart_arready),
                     .uart_rdata(uart_rdata),
                     .uart_rresp(uart_rresp),
                     .uart_rvalid(uart_rvalid),
                     .uart_rready(uart_rready),

                    // SPI
                    .spi_awaddr(spi_awaddr),
                    .spi_awvalid(spi_awvalid),
                    .spi_awready(spi_awready),
                    .spi_wdata(spi_wdata),
                    .spi_wstrb(spi_wstrb),
                    .spi_wvalid(spi_wvalid),
                    .spi_wready(spi_wready),
                    .spi_bresp(spi_bresp),
                    .spi_bvalid(spi_bvalid),
                    .spi_bready(spi_bready),
                    .spi_araddr(spi_araddr),
                    .spi_arvalid(spi_arvalid),
                    .spi_arready(spi_arready),
                    .spi_rdata(spi_rdata),
                    .spi_rresp(spi_rresp),
                    .spi_rvalid(spi_rvalid),
                    .spi_rready(spi_rready),

                    // I2C
                    .i2c_awaddr(i2c_awaddr),
                    .i2c_awvalid(i2c_awvalid),
                    .i2c_awready(i2c_awready),
                    .i2c_wdata(i2c_wdata),
                    .i2c_wstrb(i2c_wstrb),
                    .i2c_wvalid(i2c_wvalid),
                    .i2c_wready(i2c_wready),
                    .i2c_bresp(i2c_bresp),
                    .i2c_bvalid(i2c_bvalid),
                    .i2c_bready(i2c_bready),
                    .i2c_araddr(i2c_araddr),
                    .i2c_arvalid(i2c_arvalid),
                    .i2c_arready(i2c_arready),
                    .i2c_rdata(i2c_rdata),
                    .i2c_rresp(i2c_rresp),
                    .i2c_rvalid(i2c_rvalid),
                    .i2c_rready(i2c_rready),

                    // TIMER
                    .timer_awaddr(timer_awaddr),
                    .timer_awvalid(timer_awvalid),
                    .timer_awready(timer_awready),
                    .timer_wdata(timer_wdata),
                    .timer_wstrb(timer_wstrb),
                    .timer_wvalid(timer_wvalid),
                    .timer_wready(timer_wready),
                    .timer_bresp(timer_bresp),
                    .timer_bvalid(timer_bvalid),
                    .timer_bready(timer_bready),
                    .timer_araddr(timer_araddr),
                    .timer_arvalid(timer_arvalid),
                    .timer_arready(timer_arready),
                    .timer_rdata(timer_rdata),
                    .timer_rresp(timer_rresp),
                    .timer_rvalid(timer_rvalid),
                    .timer_rready(timer_rready)
                   );

    axi_ram ram_inst (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awaddr(ram_awaddr),
        .s_axi_awvalid(ram_awvalid),
        .s_axi_awready(ram_awready),

        .s_axi_wdata(ram_wdata),
        .s_axi_wstrb(ram_wstrb),
        .s_axi_wvalid(ram_wvalid),
        .s_axi_wready(ram_wready),

        .s_axi_bresp(),// opcional
        .s_axi_bvalid(ram_bvalid),
        .s_axi_bready(ram_bready),

        .s_axi_araddr(ram_araddr),
        .s_axi_arvalid(ram_arvalid),
        .s_axi_arready(ram_arready),

        .s_axi_rdata(ram_rdata),
        .s_axi_rresp(), // opcional
        .s_axi_rvalid(ram_rvalid),
        .s_axi_rready(ram_rready)
    );

  axi_gpio gpio_inst (
        .clk(clk),
        .resetn(resetn),
        .s_axi_awaddr(gpio_awaddr),
        .s_axi_awvalid(gpio_awvalid),
        .s_axi_awready(gpio_awready),
        .s_axi_wdata(gpio_wdata),
        .s_axi_wstrb(gpio_wstrb),
        .s_axi_wvalid(gpio_wvalid),
        .s_axi_wready(gpio_wready),
        .s_axi_bresp(gpio_bresp),
        .s_axi_bvalid(gpio_bvalid),
        .s_axi_bready(gpio_bready),
        .s_axi_araddr(gpio_araddr),
        .s_axi_arvalid(gpio_arvalid),
        .s_axi_arready(gpio_arready),
        .s_axi_rdata(gpio_rdata),
        .s_axi_rresp(gpio_rresp),
        .s_axi_rvalid(gpio_rvalid),
        .s_axi_rready(gpio_rready),
        .gpio_out(gpio_out)
    );

  axi_uart uart_inst (
        .clk(clk),
        .resetn(resetn),
        .s_axi_awaddr(uart_awaddr),
        .s_axi_awvalid(uart_awvalid),
        .s_axi_awready(uart_awready),
        .s_axi_wdata(uart_wdata),
        .s_axi_wstrb(uart_wstrb),
        .s_axi_wvalid(uart_wvalid),
        .s_axi_wready(uart_wready),
        .s_axi_bresp(uart_bresp),
        .s_axi_bvalid(uart_bvalid),
        .s_axi_bready(uart_bready),
        .s_axi_araddr(uart_araddr),
        .s_axi_arvalid(uart_arvalid),
        .s_axi_arready(uart_arready),
        .s_axi_rdata(uart_rdata),
        .s_axi_rresp(uart_rresp),
        .s_axi_rvalid(uart_rvalid),
        .s_axi_rready(uart_rready),
        .tx(uart_tx),
        .rx(uart_rx)
    );

    axi_spi spi_inst (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awaddr(spi_awaddr),
        .s_axi_awvalid(spi_awvalid),
        .s_axi_awready(spi_awready),
        .s_axi_wdata(spi_wdata),
        .s_axi_wstrb(spi_wstrb),
        .s_axi_wvalid(spi_wvalid),
        .s_axi_wready(spi_wready),
        .s_axi_bresp(spi_bresp),
        .s_axi_bvalid(spi_bvalid),
        .s_axi_bready(spi_bready),
        .s_axi_araddr(spi_araddr),
        .s_axi_arvalid(spi_arvalid),
        .s_axi_arready(spi_arready),
        .s_axi_rdata(spi_rdata),
        .s_axi_rresp(spi_rresp),
        .s_axi_rvalid(spi_rvalid),
        .s_axi_rready(spi_rready)
    );

    axi_i2c i2c_inst (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awaddr(i2c_awaddr),
        .s_axi_awvalid(i2c_awvalid),
        .s_axi_awready(i2c_awready),
        .s_axi_wdata(i2c_wdata),
        .s_axi_wstrb(i2c_wstrb),
        .s_axi_wvalid(i2c_wvalid),
        .s_axi_wready(i2c_wready),
        .s_axi_bresp(i2c_bresp),
        .s_axi_bvalid(i2c_bvalid),
        .s_axi_bready(i2c_bready),
        .s_axi_araddr(i2c_araddr),
        .s_axi_arvalid(i2c_arvalid),
        .s_axi_arready(i2c_arready),
        .s_axi_rdata(i2c_rdata),
        .s_axi_rresp(i2c_rresp),
        .s_axi_rvalid(i2c_rvalid),
        .s_axi_rready(i2c_rready)
    );


    axi_timer timer_inst (
        .clk(clk),
        .resetn(resetn),
        .s_axi_awaddr(timer_awaddr),
        .s_axi_awvalid(timer_awvalid),
        .s_axi_awready(timer_awready),
        .s_axi_wdata(timer_wdata),
        .s_axi_wstrb(timer_wstrb),
        .s_axi_wvalid(timer_wvalid),
        .s_axi_wready(timer_wready),
        .s_axi_bresp(timer_bresp),
        .s_axi_bvalid(timer_bvalid),
        .s_axi_bready(timer_bready),
        .s_axi_araddr(timer_araddr),
        .s_axi_arvalid(timer_arvalid),
        .s_axi_arready(timer_arready),
        .s_axi_rdata(timer_rdata),
        .s_axi_rresp(timer_rresp),
        .s_axi_rvalid(timer_rvalid),
        .s_axi_rready(timer_rready),
        .irq_out(timer_irq)
    );

endmodule
