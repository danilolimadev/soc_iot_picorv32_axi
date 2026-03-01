#define UART_BASE   0x20000000
#define UART_TXDATA (*(volatile unsigned int*)(UART_BASE + 0x00))
#define UART_RXDATA (*(volatile unsigned int*)(UART_BASE + 0x04))
#define UART_STATUS (*(volatile unsigned int*)(UART_BASE + 0x08))

#define GPIO_BASE   0x10000000
#define GPIO_OUT    (*(volatile unsigned int*)(GPIO_BASE + 0x00))

void uart_putc(char c)
{
    while (!(UART_STATUS & 0x1));  // espera TX ready
    UART_TXDATA = c;
}

void uart_print(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

char uart_getc()
{
    while (!(UART_STATUS & 0x2));  // espera RX valid
    return (char)(UART_RXDATA & 0xFF);
}

int main()
{
    uart_print("UART RX -> GPIO demo\r\n");

    while (1)
    {
        char c = uart_getc();

        if (c == 'A')
            GPIO_OUT = 0x2;
        else if (c == 'B')
            GPIO_OUT = 0x4;
        else if (c == 'C')
            GPIO_OUT = 0x8;
        else
            GPIO_OUT = 0x0;
    }
}