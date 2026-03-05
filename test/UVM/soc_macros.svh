`ifndef SOC_MACROS_SVH
`define SOC_MACROS_SVH

    localparam I2C_ADDRESS = 8'hA0; 
    // Tempo máximo de espera por um START da DUT antes de falhar a simulação.
    localparam START_TIMEOUT = 150ms;

    localparam CLK_PERIOD = 20ns; // 50 MHz
    localparam CLK_FREQ   = 50_000_000;

    localparam UART_BAUD_RATE  = 9600;
    localparam UART_BIT_CLKS = CLK_FREQ / UART_BAUD_RATE;
    localparam UART_BIT_PERIOD_NS = 1_000_000_000 / UART_BAUD_RATE;
    localparam UART_DATA_BITS = 8;
    localparam string INITIAL_MSG = "SOC IOT PICORV32";
    localparam string MSG_TO_UART = "DD\n";

    localparam GPIO_DATA_BITS = 32;
    localparam [GPIO_DATA_BITS-1:0] MSG_TO_GPIO_AFTER_SEND_DATA_TO_I2C           = 32'h8;
    localparam [GPIO_DATA_BITS-1:0] MSG_TO_GPIO_AFTER_SEND_DATA_TO_SPI           = 32'h5;
    localparam [GPIO_DATA_BITS-1:0] MSG_TO_GPIO_AFTER_SEND_DATA_TO_UART          = 32'hF;
    localparam [GPIO_DATA_BITS-1:0] MSG_TO_GPIO_AFTER_SEND_DATA_TO_GPIO          = 32'hA;
    localparam [GPIO_DATA_BITS-1:0] MSG_TO_GPIO_AFTER_SEND_DATA_TO_TIMER_INITIAL = 32'h1;
    localparam [GPIO_DATA_BITS-1:0] MSG_TO_GPIO_AFTER_SEND_DATA_TO_TIMER_END     = 32'hE;
    localparam [GPIO_DATA_BITS-1:0] MSG_TO_GPIO_DEFAULT = 32'h0;

    localparam SPI_SCK = 1_000_000;
    localparam SPI_BIT_PERIOD_NS = 1_000_000_000 / SPI_SCK;
    localparam SPI_DATA_BITS = 8;
    
    localparam string MSG_TO_SPI  = "good morning world";

    localparam I2C_DATA_BITS = 8;

    localparam TIMER_EXPECTED_DELAY = 5000;
    localparam DELAY_ERROR = 50;

    typedef enum bit [UART_DATA_BITS-1:0] {
        SEND_DATA_TO_GPIO    = 8'h41,
        SEND_DATA_TO_SPI     = 8'h42,
        SEND_DATA_TO_I2C     = 8'h43,
        SEND_DATA_TO_UART    = 8'h44,
        SEND_DATA_TO_TIMER   = 8'h45
    } commands;

    typedef enum bit [I2C_DATA_BITS-1:0] {
        MSG_TO_I2C_0 = 8'h11,
        MSG_TO_I2C_1 = 8'h22,
        MSG_TO_I2C_2 = 8'h33
    } expected_i2c;

    function automatic expected_i2c get_expected_i2c_enum_by_index(int idx);
        expected_i2c state;
        int count = 0;

        state = state.first();
        forever
        begin
            if (count == idx)
                return state;
            if (state == state.last())
                break;
            state = state.next();
            count++;
        end

        `uvm_fatal("ENUM", $sformatf("Índice %0d fora do range", idx))
    endfunction

`endif // SOC_MACROS_SVH