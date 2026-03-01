#include <stdint.h>

#define UART_BASE   0x20000000
#define UART_TXDATA (*(volatile uint32_t*)(UART_BASE + 0x00))
#define UART_STATUS (*(volatile uint32_t*)(UART_BASE + 0x04))

#define GPIO_BASE   0x10000000
#define GPIO_OUT    (*(volatile uint32_t*)(GPIO_BASE + 0x00))

#define SPI_BASE    0x30000000
#define SPI_DATA    (*(volatile uint32_t*)(SPI_BASE + 0x00))
#define SPI_STATUS  (*(volatile uint32_t*)(SPI_BASE + 0x04))

void uart_putc(char c)
{
    while (UART_STATUS & 0x1); // espera TX ficar livre
    UART_TXDATA = c;
}

void uart_print(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

// envia 1 byte pela SPI
void spi_send(uint8_t b)
{
    while (SPI_STATUS & 0x1); // espera SPI pronta
    SPI_DATA = b;
}

// exemplo simples: envia um array de bytes
void spi_send_bytes(const uint8_t *buf, int len)
{
    for (int i=0; i<len; i++)
        spi_send(buf[i]);
}

int main()
{
    uart_print("O wa yo sekai!\r\n");

    // pisca GPIO como antes
    GPIO_OUT = 0x1;
    for (volatile int i=0; i<10; i++);
    GPIO_OUT = 0x0;
    for (volatile int i=0; i<10; i++);
    GPIO_OUT = 0x1;
    for (volatile int i=0; i<10; i++);
    GPIO_OUT = 0x0;

    // exemplo SPI: envia sequência 0xAA, 0x55, 0xFF
    uint8_t data[] = {0x67, 0x6F, 0x6F, 0x64, 0x20, 0x6D, 0x6F, 0x72, 0x6E, 0x69, 0x6E, 0x67, 0x20, 0x77, 0x6F, 0x72, 0x6C, 0x64};
    spi_send_bytes(data, 18);

    while (1);
}