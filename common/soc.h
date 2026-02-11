#pragma once
#include <stdint.h>

#define RAM_BASE   0x00000000u
#define GPIO_BASE  0x10000000u
#define UART_BASE  0x20000000u
#define SPI_BASE   0x30000000u
#define I2C_BASE   0x40000000u
#define TIMER_BASE 0x50000000u

static inline void mmio_write32(uint32_t addr, uint32_t value){
    *(volatile uint32_t*)addr = value;
}
static inline uint32_t mmio_read32(uint32_t addr){
    return *(volatile uint32_t*)addr;
}
