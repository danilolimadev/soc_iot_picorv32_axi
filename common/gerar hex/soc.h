#pragma once
#include <stdint.h>

#define SOC_GPIO_BASE   0x10000000u
#define SOC_UART_BASE   0x20000000u

static inline void mmio_write(uint32_t addr, uint32_t value) {
    *(volatile uint32_t*)addr = value;
}
static inline uint32_t mmio_read(uint32_t addr) {
    return *(volatile uint32_t*)addr;
}

#define GPIO_OUT        (SOC_GPIO_BASE + 0x00u)

#define UART_TXDATA     (SOC_UART_BASE + 0x00u)
#define UART_STATUS     (SOC_UART_BASE + 0x08u)
#define UART_ST_TXRDY   (1u<<0)