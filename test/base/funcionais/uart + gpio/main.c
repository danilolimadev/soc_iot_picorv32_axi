#define UART_BASE   0x20000000
#define UART_TXDATA (*(volatile unsigned int*)(UART_BASE + 0x00))
#define UART_STATUS (*(volatile unsigned int*)(UART_BASE + 0x04))

#define GPIO_BASE   0x10000000
#define GPIO_OUT    (*(volatile unsigned int*)(GPIO_BASE + 0x00))

void uart_putc(char c)
{
    // espera TX ficar livre (bit0 == 0)
    while (UART_STATUS & 0x1);
    UART_TXDATA = c;
}

void uart_print(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

int main()
{
    uart_print("Hello from PicoRV32!\r\n");

    // exemplo mínimo de GPIO: pisca 1 vez
    GPIO_OUT = 0x1;  // liga o primeiro bit
    for (volatile int i=0; i<10; i++); // delay simples
    GPIO_OUT = 0x0;  // desliga
    for (volatile int i=0; i<10; i++);
    GPIO_OUT = 0x1;
    for (volatile int i=0; i<10; i++);
    GPIO_OUT = 0x0;

    while (1);
}