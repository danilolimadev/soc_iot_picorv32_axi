#define GPIO_BASE   0x10000000
#define GPIO_OUT    (*(volatile unsigned int*)(GPIO_BASE + 0x00))

#define UART_BASE   0x20000000
#define UART_TXDATA (*(volatile unsigned int*)(UART_BASE + 0x00))
#define UART_STATUS (*(volatile unsigned int*)(UART_BASE + 0x04))

#define SPI_BASE    0x30000000
#define SPI_TXDATA  (*(volatile unsigned int*)(SPI_BASE + 0x00))

#define I2C_BASE    0x40000000
#define I2C_TXDATA  (*(volatile unsigned int*)(I2C_BASE + 0x08))

#define TIMER_BASE  0x50000000
#define TIMER_CTRL  (*(volatile unsigned int*)(TIMER_BASE + 0x00))

// --------------------- UART ---------------------
void uart_putc(char c)
{
    while (UART_STATUS & 0x1); // espera TX pronto
    UART_TXDATA = c;
}

void uart_print(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

// --------------------- GPIO ---------------------
void gpio_set(unsigned int val)
{
    GPIO_OUT = val;
}

// --------------------- SPI ---------------------
void spi_write_byte(unsigned char data)
{
    SPI_TXDATA = data; // escreve direto, sem esperar
}

// --------------------- I2C ---------------------
void i2c_write_byte(unsigned char data)
{
    I2C_TXDATA = data; // escreve direto, sem esperar
}

// --------------------- Timer ---------------------
void timer_start(unsigned int val)
{
    TIMER_CTRL = val; // exemplo: seta o timer
}

int main()
{
    uart_print("Hello from PicoRV32!\r\n");

    // GPIO: pisca
    gpio_set(0x1);
    for (volatile int i=0; i<10; i++);
    gpio_set(0x0);
    for (volatile int i=0; i<10; i++);
    gpio_set(0x1);
    for (volatile int i=0; i<10; i++);
    gpio_set(0x0);
    for (volatile int i=0; i<10; i++);

    // SPI: envia alguns bytes
    spi_write_byte(0xAA);
    for (volatile int i=0; i<10; i++);
    spi_write_byte(0x55);
    for (volatile int i=0; i<10; i++);

    // I2C: envia alguns bytes
    i2c_write_byte(0x12);
    for (volatile int i=0; i<10; i++);
    i2c_write_byte(0x34);
    for (volatile int i=0; i<10; i++);

    // Timer: seta valor inicial
    timer_start(0x12345678);

    while (1); // loop infinito
}