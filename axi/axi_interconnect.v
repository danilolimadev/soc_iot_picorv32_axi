module axi_interconnect (
    input  wire clk,
    input  wire resetn,

    input  wire [31:0] m_awaddr,
    input  wire        m_awvalid,
    output wire        m_awready,
    input  wire [31:0] m_wdata,
    input  wire [3:0]  m_wstrb,
    input  wire        m_wvalid,
    output wire        m_wready,
    output wire [1:0]  m_bresp,
    output wire        m_bvalid,
    input  wire        m_bready,
    input  wire [31:0] m_araddr,
    input  wire        m_arvalid,
    output wire        m_arready,
    output wire [31:0] m_rdata,
    output wire [1:0]  m_rresp,
    output wire        m_rvalid,
    input  wire        m_rready,

    output wire [31:0] ram_awaddr,
    output wire        ram_awvalid,
    input  wire        ram_awready,
    output wire [31:0] ram_wdata,
    output wire [3:0]  ram_wstrb,
    output wire        ram_wvalid,
    input  wire        ram_wready,
    input  wire [1:0]  ram_bresp,
    input  wire        ram_bvalid,
    output wire        ram_bready,
    output wire [31:0] ram_araddr,
    output wire        ram_arvalid,
    input  wire        ram_arready,
    input  wire [31:0] ram_rdata,
    input  wire [1:0]  ram_rresp,
    input  wire        ram_rvalid,
    output wire        ram_rready,

    output wire [11:0] gpio_awaddr,
    output wire        gpio_awvalid,
    input  wire        gpio_awready,
    output wire [31:0] gpio_wdata,
    output wire [3:0]  gpio_wstrb,
    output wire        gpio_wvalid,
    input  wire        gpio_wready,
    input  wire [1:0]  gpio_bresp,
    input  wire        gpio_bvalid,
    output wire        gpio_bready,
    output wire [11:0] gpio_araddr,
    output wire        gpio_arvalid,
    input  wire        gpio_arready,
    input  wire [31:0] gpio_rdata,
    input  wire [1:0]  gpio_rresp,
    input  wire        gpio_rvalid,
    output wire        gpio_rready,

    output wire [11:0] uart_awaddr,
    output wire        uart_awvalid,
    input  wire        uart_awready,
    output wire [31:0] uart_wdata,
    output wire [3:0]  uart_wstrb,
    output wire        uart_wvalid,
    input  wire        uart_wready,
    input  wire [1:0]  uart_bresp,
    input  wire        uart_bvalid,
    output wire        uart_bready,
    output wire [11:0] uart_araddr,
    output wire        uart_arvalid,
    input  wire        uart_arready,
    input  wire [31:0] uart_rdata,
    input  wire [1:0]  uart_rresp,
    input  wire        uart_rvalid,
    output wire        uart_rready,

    output wire [11:0] spi_awaddr,
    output wire        spi_awvalid,
    input  wire        spi_awready,
    output wire [31:0] spi_wdata,
    output wire [3:0]  spi_wstrb,
    output wire        spi_wvalid,
    input  wire        spi_wready,
    input  wire [1:0]  spi_bresp,
    input  wire        spi_bvalid,
    output wire        spi_bready,
    output wire [11:0] spi_araddr,
    output wire        spi_arvalid,
    input  wire        spi_arready,
    input  wire [31:0] spi_rdata,
    input  wire [1:0]  spi_rresp,
    input  wire        spi_rvalid,
    output wire        spi_rready,

    output wire [11:0] i2c_awaddr,
    output wire        i2c_awvalid,
    input  wire        i2c_awready,
    output wire [31:0] i2c_wdata,
    output wire [3:0]  i2c_wstrb,
    output wire        i2c_wvalid,
    input  wire        i2c_wready,
    input  wire [1:0]  i2c_bresp,
    input  wire        i2c_bvalid,
    output wire        i2c_bready,
    output wire [11:0] i2c_araddr,
    output wire        i2c_arvalid,
    input  wire        i2c_arready,
    input  wire [31:0] i2c_rdata,
    input  wire [1:0]  i2c_rresp,
    input  wire        i2c_rvalid,
    output wire        i2c_rready,

    output wire [11:0] timer_awaddr,
    output wire        timer_awvalid,
    input  wire        timer_awready,
    output wire [31:0] timer_wdata,
    output wire [3:0]  timer_wstrb,
    output wire        timer_wvalid,
    input  wire        timer_wready,
    input  wire [1:0]  timer_bresp,
    input  wire        timer_bvalid,
    output wire        timer_bready,
    output wire [11:0] timer_araddr,
    output wire        timer_arvalid,
    input  wire        timer_arready,
    input  wire [31:0] timer_rdata,
    input  wire [1:0]  timer_rresp,
    input  wire        timer_rvalid,
    output wire        timer_rready
);

    localparam RAM_BASE   = 32'h0000_0000;
    localparam GPIO_BASE  = 32'h1000_0000;
    localparam UART_BASE  = 32'h2000_0000;
    localparam SPI_BASE   = 32'h3000_0000;
    localparam I2C_BASE   = 32'h4000_0000;
    localparam TIMER_BASE = 32'h5000_0000;

    wire sel_ram   = (m_awaddr[31:12] == RAM_BASE[31:12])   || (m_araddr[31:12] == RAM_BASE[31:12]);
    wire sel_gpio  = (m_awaddr[31:12] == GPIO_BASE[31:12])  || (m_araddr[31:12] == GPIO_BASE[31:12]);
    wire sel_uart  = (m_awaddr[31:12] == UART_BASE[31:12])  || (m_araddr[31:12] == UART_BASE[31:12]);
    wire sel_spi   = (m_awaddr[31:12] == SPI_BASE[31:12])   || (m_araddr[31:12] == SPI_BASE[31:12]);
    wire sel_i2c   = (m_awaddr[31:12] == I2C_BASE[31:12])   || (m_araddr[31:12] == I2C_BASE[31:12]);
    wire sel_timer = (m_awaddr[31:12] == TIMER_BASE[31:12]) || (m_araddr[31:12] == TIMER_BASE[31:12]);

    assign ram_awvalid   = m_awvalid && sel_ram;
    assign gpio_awvalid  = m_awvalid && sel_gpio;
    assign uart_awvalid  = m_awvalid && sel_uart;
    assign spi_awvalid   = m_awvalid && sel_spi;
    assign i2c_awvalid   = m_awvalid && sel_i2c;
    assign timer_awvalid = m_awvalid && sel_timer;

    assign ram_awaddr   = m_awaddr;
    assign gpio_awaddr  = m_awaddr[11:0];
    assign uart_awaddr  = m_awaddr[11:0];
    assign spi_awaddr   = m_awaddr[11:0];
    assign i2c_awaddr   = m_awaddr[11:0];
    assign timer_awaddr = m_awaddr[11:0];

    assign ram_wdata   = ram_bvalid ? m_wdata : 0;
    assign gpio_wdata  = gpio_bvalid ? m_wdata : 0;
    assign uart_wdata  = uart_bvalid ? m_wdata : 0;
    assign spi_wdata   = spi_bvalid ? m_wdata : 0;
    assign i2c_wdata   = i2c_bvalid ? m_wdata : 0;
    assign timer_wdata = timer_bvalid ? m_wdata : 0;

    assign ram_wstrb   = m_wstrb;
    assign gpio_wstrb  = m_wstrb;
    assign uart_wstrb  = m_wstrb;
    assign spi_wstrb   = m_wstrb;
    assign i2c_wstrb   = m_wstrb;
    assign timer_wstrb = m_wstrb;

    assign ram_wvalid   = m_wvalid && sel_ram;
    assign gpio_wvalid  = m_wvalid && sel_gpio;
    assign uart_wvalid  = m_wvalid && sel_uart;
    assign spi_wvalid   = m_wvalid && sel_spi;
    assign i2c_wvalid   = m_wvalid && sel_i2c;
    assign timer_wvalid = m_wvalid && sel_timer;

    assign ram_bready   = m_bready;
    assign gpio_bready  = m_bready;
    assign uart_bready  = m_bready;
    assign spi_bready   = m_bready;
    assign i2c_bready   = m_bready;
    assign timer_bready = m_bready;

    assign m_awready = (sel_ram   && ram_awready)  ||
                       (sel_gpio  && gpio_awready) ||
                       (sel_uart  && uart_awready) ||
                       (sel_spi   && spi_awready)  ||
                       (sel_i2c   && i2c_awready)  ||
                       (sel_timer && timer_awready);

    assign m_wready  = (sel_ram   && ram_wready)  ||
                       (sel_gpio  && gpio_wready) ||
                       (sel_uart  && uart_wready) ||
                       (sel_spi   && spi_wready)  ||
                       (sel_i2c   && i2c_wready)  ||
                       (sel_timer && timer_wready);

    assign m_bvalid  = (sel_ram   && ram_bvalid)  ||
                       (sel_gpio  && gpio_bvalid) ||
                       (sel_uart  && uart_bvalid) ||
                       (sel_spi   && spi_bvalid)  ||
                       (sel_i2c   && i2c_bvalid)  ||
                       (sel_timer && timer_bvalid);

    assign m_bresp = (sel_ram   ? ram_bresp   :
                      sel_gpio  ? gpio_bresp  :
                      sel_uart  ? uart_bresp  :
                      sel_spi   ? spi_bresp   :
                      sel_i2c   ? i2c_bresp   :
                      sel_timer ? timer_bresp : 2'b00);

    assign ram_arvalid   = m_arvalid && sel_ram;
    assign gpio_arvalid  = m_arvalid && sel_gpio;
    assign uart_arvalid  = m_arvalid && sel_uart;
    assign spi_arvalid   = m_arvalid && sel_spi;
    assign i2c_arvalid   = m_arvalid && sel_i2c;
    assign timer_arvalid = m_arvalid && sel_timer;

    assign ram_araddr   = m_araddr;
    assign gpio_araddr  = m_araddr[11:0];
    assign uart_araddr  = m_araddr[11:0];
    assign spi_araddr   = m_araddr[11:0];
    assign i2c_araddr   = m_araddr[11:0];
    assign timer_araddr = m_araddr[11:0];

    assign ram_rready   = m_rready;
    assign gpio_rready  = m_rready;
    assign uart_rready  = m_rready;
    assign spi_rready   = m_rready;
    assign i2c_rready   = m_rready;
    assign timer_rready = m_rready;

    assign m_arready = (sel_ram   && ram_arready)  ||
                       (sel_gpio  && gpio_arready) ||
                       (sel_uart  && uart_arready) ||
                       (sel_spi   && spi_arready)  ||
                       (sel_i2c   && i2c_arready)  ||
                       (sel_timer && timer_arready);

    assign m_rvalid = (sel_ram   && ram_rvalid)  ||
                      (sel_gpio  && gpio_rvalid) ||
                      (sel_uart  && uart_rvalid) ||
                      (sel_spi   && spi_rvalid)  ||
                      (sel_i2c   && i2c_rvalid)  ||
                      (sel_timer && timer_rvalid);

    assign m_rdata = (sel_ram   ? ram_rdata   :
                      sel_gpio  ? gpio_rdata  :
                      sel_uart  ? uart_rdata  :
                      sel_spi   ? spi_rdata   :
                      sel_i2c   ? i2c_rdata   :
                      sel_timer ? timer_rdata : 32'hDEAD_BEEF);

    assign m_rresp = (sel_ram   ? ram_rresp   :
                      sel_gpio  ? gpio_rresp  :
                      sel_uart  ? uart_rresp  :
                      sel_spi   ? spi_rresp   :
                      sel_i2c   ? i2c_rresp   :
                      sel_timer ? timer_rresp : 2'b00);

endmodule
