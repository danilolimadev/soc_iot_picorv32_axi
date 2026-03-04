`ifndef SOC_MACROS_SVH
`define SOC_MACROS_SVH

    localparam I2C_ADDRESS = 7'h21; 
    // Tempo máximo de espera por um START da DUT antes de falhar a simulação.
    localparam START_TIMEOUT = 1_000_000;   // 1 µs (padrão)

    localparam CLK_PERIOD = 20ns; // 50 MHz
    localparam CLK_FREQ   = 50_000_000;
    localparam UART_BAUD_RATE  = 9600;
    localparam UART_BIT_CLKS = CLK_FREQ / UART_BAUD_RATE;
    localparam UART_BIT_PERIOD_NS = 1_000_000_000 / UART_BAUD_RATE;
    localparam UART_DATA_BITS = 8;

    localparam string INITIAL_MSG = "SOC IOT PICORV32";

    localparam string MSG_TO_I2C  = "";
    localparam string MSG_TO_SPI  = "good morning world";
    localparam string MSG_TO_UART = "DD\n";
    localparam string MSG_TO_GPIO = "";

    typedef enum bit [UART_DATA_BITS-1:0] {
        //SEND_DATA_TO_I2C    = 8'h43,
        //SEND_DATA_TO_SPI    = 8'h42,
        SEND_DATA_TO_UART   = 8'h44//,
        //SEND_DATA_TO_GPIO   = 8'h41
    } commands;

`endif // SOC_MACROS_SVH