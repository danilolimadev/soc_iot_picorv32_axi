#include <stdint.h>

/* ============================================================
 * MAPA DE MEMÓRIA DOS PERIFÉRICOS
 * ============================================================ */

 /* ---------------- GPIO ---------------- */
#define GPIO_BASE       0x10000000
#define GPIO_OUT        (*(volatile uint32_t*)(GPIO_BASE + 0x00))

/* ---------------- UART ---------------- */
#define UART_BASE       0x20000000

#define UART_TXDATA     (*(volatile uint32_t*)(UART_BASE + 0x00))
#define UART_RXDATA     (*(volatile uint32_t*)(UART_BASE + 0x04))
#define UART_STATUS     (*(volatile uint32_t*)(UART_BASE + 0x08))

#define UART_STATUS_TX_READY   0x01
#define UART_STATUS_RX_VALID   0x02

/* ---------------- SPI ---------------- */
#define SPI_BASE        0x30000000

#define SPI_DATA        (*(volatile uint32_t*)(SPI_BASE + 0x00))
#define SPI_STATUS      (*(volatile uint32_t*)(SPI_BASE + 0x04))

#define SPI_STATUS_BUSY 0x01


/* ---------------- I2C (AXI) ---------------- */
#define AXI_I2C_BASE    0x40000000
#define I2C_REG         (*(volatile uint32_t*)(AXI_I2C_BASE + 0x08))


/* ---------------- TIMER ---------------- */
#define TIMER_BASE      0x50000000

#define TIMER_CONTROL   (*(volatile uint32_t*)(TIMER_BASE + 0x00))
#define TIMER_RELOAD    (*(volatile uint32_t*)(TIMER_BASE + 0x04))
#define TIMER_STATUS    (*(volatile uint32_t*)(TIMER_BASE + 0x08))

#define TIMER_ENABLE    0x01
#define TIMER_STOP      0x02
#define TIMER_DONE      0x01


/* ============================================================
 * DRIVERS - UART
 * ============================================================ */

/**
 * Envia 1 caractere via UART (bloqueante).
 */
void uart_putc(char c)
{
    while (!(UART_STATUS & UART_STATUS_TX_READY));
    UART_TXDATA = (uint32_t)c;
}

/**
 * Envia string terminada em '\0'.
 */
void uart_print(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

/**
 * Recebe 1 caractere via UART (bloqueante).
 */
char uart_getc(void)
{
    while (!(UART_STATUS & UART_STATUS_RX_VALID));
    return (char)(UART_RXDATA & 0xFF);
}


/* ============================================================
 * DRIVERS - SPI
 * ============================================================ */

/**
 * Envia 1 byte via SPI (bloqueante).
 */
void spi_send(uint8_t byte)
{
    while (SPI_STATUS & SPI_STATUS_BUSY);
    SPI_DATA = byte;
}

/**
 * Envia múltiplos bytes via SPI.
 */
void spi_send_bytes(const uint8_t *buffer, int length)
{
    for (int i = 0; i < length; i++)
        spi_send(buffer[i]);
}


/* ============================================================
 * APLICAÇÃO PRINCIPAL
 * ============================================================ */

int main(void)
{
    uart_print("SOC IOT PICORV32");

    while (1)
    {
        char c = uart_getc();

        switch (c)
        {
            /* ------------------------------------------------ */
            case 'A':
                GPIO_OUT = 0xA;
                break;

            /* ------------------------------------------------ */
            case 'B':
            {
                GPIO_OUT = 0x5;

                uint8_t data[] = {
                    0x67, 0x6F, 0x6F, 0x64, 0x20,
                    0x6D, 0x6F, 0x72, 0x6E, 0x69,
                    0x6E, 0x67, 0x20, 0x77, 0x6F,
                    0x72, 0x6C, 0x64
                };

                spi_send_bytes(data, 18);
                break;
            }

            /* ------------------------------------------------ */
            case 'C':
            {
                GPIO_OUT = 0x8;

                uint8_t addr = (0x50 << 1);  // I2C write

                I2C_REG = (addr << 8) | 0x11;
                I2C_REG = (addr << 8) | 0x22;
                I2C_REG = (addr << 8) | 0x33;

                break;
            }

            /* ------------------------------------------------ */
            case 'D':
                GPIO_OUT = 0xF;
                uart_print("DD\n");
                break;

            /* ------------------------------------------------ */
            case 'E':
                GPIO_OUT = 0x1;

                TIMER_RELOAD  = 5000;
                TIMER_CONTROL = TIMER_ENABLE;

                while (!(TIMER_STATUS & TIMER_DONE));

                GPIO_OUT = 0xE;
                TIMER_CONTROL = TIMER_STOP;
                break;

            /* ------------------------------------------------ */
            default:
                GPIO_OUT = 0x0;
                break;
        }
    }
}