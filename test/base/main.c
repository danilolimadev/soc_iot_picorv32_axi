#include <stdint.h>

#define UART_BASE   0x20000000
#define UART_TXDATA (*(volatile uint32_t*)(UART_BASE + 0x00))
#define UART_STATUS (*(volatile uint32_t*)(UART_BASE + 0x04))

#define GPIO_BASE   0x10000000
#define GPIO_OUT    (*(volatile uint32_t*)(GPIO_BASE + 0x00))

#define SPI_BASE    0x30000000
#define SPI_DATA    (*(volatile uint32_t*)(SPI_BASE + 0x00))
#define SPI_STATUS  (*(volatile uint32_t*)(SPI_BASE + 0x04))

#define I2C_BASE    0x40000000
#define I2C_ADDR    (*(volatile uint32_t*)(I2C_BASE + 0x00)) // endereço do dispositivo
#define I2C_DATA    (*(volatile uint32_t*)(I2C_BASE + 0x04)) // dado
#define I2C_STATUS  (*(volatile uint32_t*)(I2C_BASE + 0x08)) // busy

// ===================== UART =====================
void uart_putc(char c)
{
    while (UART_STATUS & 0x1); // espera TX livre
    UART_TXDATA = c;
}

void uart_print(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

// ===================== SPI =====================
void spi_send(uint8_t b)
{
    while (SPI_STATUS & 0x1); // espera SPI pronta
    SPI_DATA = b;
}

void spi_send_bytes(const uint8_t *buf, int len)
{
    for (int i=0; i<len; i++)
        spi_send(buf[i]);
}

// ===================== I2C =====================
void i2c_write(uint8_t addr, uint8_t data)
{
    // escreve endereço primeiro
    while (I2C_STATUS & 0x1); // espera I2C livre
    I2C_ADDR = addr;

    // escreve dado → inicia transmissão
    while (I2C_STATUS & 0x1); // espera I2C livre
    I2C_DATA = data;
}

// ===================== MAIN =====================
int main()
{
    uart_print("O wa yo sekai!\r\n");

    // pisca GPIO
    GPIO_OUT = 0x1;
    for (volatile int i=0; i<10; i++);
    GPIO_OUT = 0x0;
    for (volatile int i=0; i<10; i++);
    GPIO_OUT = 0x1;
    for (volatile int i=0; i<10; i++);
    GPIO_OUT = 0x0;

    // envia 3 bytes de teste para SPI
    uint8_t spi_data[] = {0xAA, 0x55, 0xFF};
    spi_send_bytes(spi_data, 3);

    // envia dados para I2C (endereços e bytes)
    i2c_write(0x42, 0x11);
    i2c_write(0x42, 0x22);
    i2c_write(0x42, 0x33);

    while (1);
}