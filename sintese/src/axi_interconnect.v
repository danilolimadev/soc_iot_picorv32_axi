/* verilator lint_off UNUSEDSIGNAL */
`timescale 1 ns / 1 ps

/*
Mapa de Memória Atualizado:

    RAM: 0x0000_0000

    GPIO: 0x1000_0000

    UART: 0x2000_0000

    SPI: 0x3000_0000

    I2C: 0x4000_0000

    TIMER: 0x5000_0000
*/	

module axi_interconnect (
    input  wire clk,
    input  wire resetn,

    // Interface Master (CPU)
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

    // RAM
    output wire [31:0] ram_awaddr,  output wire ram_awvalid, input wire ram_awready,
    output wire [31:0] ram_wdata,   output wire [3:0] ram_wstrb, output wire ram_wvalid,  input wire ram_wready,
    input  wire [1:0]  ram_bresp,   input  wire ram_bvalid,  output wire ram_bready,
    output wire [31:0] ram_araddr,  output wire ram_arvalid, input wire ram_arready,
    input  wire [31:0] ram_rdata,   input  wire [1:0] ram_rresp, input wire ram_rvalid,  output wire ram_rready,

    // GPIO
    output wire [11:0] gpio_awaddr, output wire gpio_awvalid, input wire gpio_awready,
    output wire [31:0] gpio_wdata,  output wire [3:0] gpio_wstrb, output wire gpio_wvalid,  input wire gpio_wready,
    input  wire [1:0]  gpio_bresp,  input  wire gpio_bvalid,  output wire gpio_bready,
    output wire [11:0] gpio_araddr, output wire gpio_arvalid, input wire gpio_arready,
    input  wire [31:0] gpio_rdata,  input  wire [1:0] gpio_rresp, input wire gpio_rvalid,  output wire gpio_rready,

    // UART
    output wire [11:0] uart_awaddr, output wire uart_awvalid, input wire uart_awready,
    output wire [31:0] uart_wdata,  output wire [3:0] uart_wstrb, output wire uart_wvalid,  input wire uart_wready,
    input  wire [1:0]  uart_bresp,  input  wire uart_bvalid,  output wire uart_bready,
    output wire [11:0] uart_araddr, output wire uart_arvalid, input wire uart_arready,
    input  wire [31:0] uart_rdata,  input  wire [1:0] uart_rresp, input wire uart_rvalid,  output wire uart_rready,

    // SPI
    output wire [11:0] spi_awaddr,  output wire spi_awvalid, input wire spi_awready,
    output wire [31:0] spi_wdata,   output wire [3:0] spi_wstrb, output wire spi_wvalid,  input wire spi_wready,
    input  wire [1:0]  spi_bresp,   input  wire spi_bvalid,  output wire spi_bready,
    output wire [11:0] spi_araddr,  output wire spi_arvalid, input wire spi_arready,
    input  wire [31:0] spi_rdata,   input  wire [1:0] spi_rresp, input wire spi_rvalid,  output wire spi_rready,

    // I2C
    output wire [11:0] i2c_awaddr,  output wire i2c_awvalid, input wire i2c_awready,
    output wire [31:0] i2c_wdata,   output wire [3:0] i2c_wstrb, output wire i2c_wvalid,  input wire i2c_wready,
    input  wire [1:0]  i2c_bresp,   input  wire i2c_bvalid,  output wire i2c_bready,
    output wire [11:0] i2c_araddr,  output wire i2c_arvalid, input wire i2c_arready,
    input  wire [31:0] i2c_rdata,   input  wire [1:0] i2c_rresp, input wire i2c_rvalid,  output wire i2c_rready,

    // TIMER
    output wire [11:0] timer_awaddr, output wire timer_awvalid, input wire timer_awready,
    output wire [31:0] timer_wdata,  output wire [3:0] timer_wstrb, output wire timer_wvalid,  input wire timer_wready,
    input  wire [1:0]  timer_bresp,  input  wire timer_bvalid,  output wire timer_bready,
    output wire [11:0] timer_araddr, output wire timer_arvalid, input wire timer_arready,
    input  wire [31:0] timer_rdata,  input  wire [1:0] timer_rresp, input wire timer_rvalid,  output wire timer_rready
);

    // ============================================================
    // DECODIFICAÇÃO DE ENDEREÇO
    // ============================================================
    wire w_sel_ram   = (m_awaddr[31:12] == 20'h00000); 
    wire w_sel_gpio  = (m_awaddr[31:12] == 20'h10000); 
    wire w_sel_uart  = (m_awaddr[31:12] == 20'h20000); 
    wire w_sel_spi   = (m_awaddr[31:12] == 20'h30000); 
    wire w_sel_i2c   = (m_awaddr[31:12] == 20'h40000); 
    wire w_sel_timer = (m_awaddr[31:12] == 20'h50000); 

    wire r_sel_ram   = (m_araddr[31:12] == 20'h00000);
    wire r_sel_gpio  = (m_araddr[31:12] == 20'h10000);
    wire r_sel_uart  = (m_araddr[31:12] == 20'h20000);
    wire r_sel_spi   = (m_araddr[31:12] == 20'h30000);
    wire r_sel_i2c   = (m_araddr[31:12] == 20'h40000);
    wire r_sel_timer = (m_araddr[31:12] == 20'h50000);

    wire w_invalid = m_awvalid && !(w_sel_ram | w_sel_gpio | w_sel_uart | w_sel_spi | w_sel_i2c | w_sel_timer);
    wire r_invalid = m_arvalid && !(r_sel_ram | r_sel_gpio | r_sel_uart | r_sel_spi | r_sel_i2c | r_sel_timer);

    // ============================================================
    // CANAL DE ESCRITA
    // ============================================================
    assign ram_awaddr   = m_awaddr;
    assign {gpio_awaddr, uart_awaddr, spi_awaddr, i2c_awaddr, timer_awaddr} = {5{m_awaddr[11:0]}};

    assign ram_awvalid   = m_awvalid && w_sel_ram;
    assign gpio_awvalid  = m_awvalid && w_sel_gpio;
    assign uart_awvalid  = m_awvalid && w_sel_uart;
    assign spi_awvalid   = m_awvalid && w_sel_spi;
    assign i2c_awvalid   = m_awvalid && w_sel_i2c;
    assign timer_awvalid = m_awvalid && w_sel_timer;

    assign m_awready = w_invalid     ? 1'b1 :
                       w_sel_ram      ? ram_awready   :
                       w_sel_gpio     ? gpio_awready  :
                       w_sel_uart     ? uart_awready  :
                       w_sel_spi      ? spi_awready   :
                       w_sel_i2c      ? i2c_awready   :
                       w_sel_timer    ? timer_awready : 1'b0;

    assign {ram_wdata, gpio_wdata, uart_wdata, spi_wdata, i2c_wdata, timer_wdata} = {6{m_wdata}};
    assign {ram_wstrb, gpio_wstrb, uart_wstrb, spi_wstrb, i2c_wstrb, timer_wstrb} = {6{m_wstrb}};

    assign ram_wvalid   = m_wvalid && w_sel_ram;
    assign gpio_wvalid  = m_wvalid && w_sel_gpio;
    assign uart_wvalid  = m_wvalid && w_sel_uart;
    assign spi_wvalid   = m_wvalid && w_sel_spi;
    assign i2c_wvalid   = m_wvalid && w_sel_i2c;
    assign timer_wvalid = m_wvalid && w_sel_timer;

    assign m_wready = w_invalid     ? 1'b1 :
                      w_sel_ram      ? ram_wready   :
                      w_sel_gpio     ? gpio_wready  :
                      w_sel_uart     ? uart_wready  :
                      w_sel_spi      ? spi_wready   :
                      w_sel_i2c      ? i2c_wready   :
                      w_sel_timer    ? timer_wready : 1'b0;

    assign {ram_bready, gpio_bready, uart_bready, spi_bready, i2c_bready, timer_bready} = {6{m_bready}};

    assign m_bvalid = w_invalid ? 1'b1 : (ram_bvalid | gpio_bvalid | uart_bvalid | spi_bvalid | i2c_bvalid | timer_bvalid);
	
    assign m_bresp  = w_invalid    ? 2'b11 : 
                      ram_bvalid   ? ram_bresp   :
                      gpio_bvalid  ? gpio_bresp  :
                      uart_bvalid  ? uart_bresp  :
                      spi_bvalid   ? spi_bresp   :
                      i2c_bvalid   ? i2c_bresp   :
                      timer_bvalid ? timer_bresp : 2'b00;

    // ============================================================
    // CANAL DE LEITURA
    // ============================================================
    assign ram_araddr   = m_araddr;
    assign {gpio_araddr, uart_araddr, spi_araddr, i2c_araddr, timer_araddr} = {5{m_araddr[11:0]}};

    assign ram_arvalid   = m_arvalid && r_sel_ram;
    assign gpio_arvalid  = m_arvalid && r_sel_gpio;
    assign uart_arvalid  = m_arvalid && r_sel_uart;
    assign spi_arvalid   = m_arvalid && r_sel_spi;
    assign i2c_arvalid   = m_arvalid && r_sel_i2c;
    assign timer_arvalid = m_arvalid && r_sel_timer;

    assign m_arready = r_invalid     ? 1'b1 :
                       r_sel_ram      ? ram_arready   :
                       r_sel_gpio     ? gpio_arready  :
                       r_sel_uart     ? uart_arready  :
                       r_sel_spi      ? spi_arready   :
                       r_sel_i2c      ? i2c_arready   :
                       r_sel_timer    ? timer_arready : 1'b0;

    assign {ram_rready, gpio_rready, uart_rready, spi_rready, i2c_rready, timer_rready} = {6{m_rready}};

    assign m_rvalid = r_invalid ? 1'b1 : (ram_rvalid | gpio_rvalid | uart_rvalid | spi_rvalid | i2c_rvalid | timer_rvalid);
    
    assign m_rdata  = ram_rvalid   ? ram_rdata   :
                      gpio_rvalid  ? gpio_rdata  :
                      uart_rvalid  ? uart_rdata  :
                      spi_rvalid   ? spi_rdata   :
                      i2c_rvalid   ? i2c_rdata   :
                      timer_rvalid ? timer_rdata : 32'hDEADBEEF;

    assign m_rresp  = r_invalid    ? 2'b11 : 
                      ram_rvalid   ? ram_rresp   :
                      gpio_rvalid  ? gpio_rresp  :
                      uart_rvalid  ? uart_rresp  :
                      spi_rvalid   ? spi_rresp   :
                      i2c_rvalid   ? i2c_rresp   :
                      timer_rvalid ? timer_rresp : 2'b00;

endmodule
