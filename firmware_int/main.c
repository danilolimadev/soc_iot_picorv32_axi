#include "../common/soc.h"

uint32_t ext_irq_4_count = 0;

int main() {

    //asm volatile("picorv32_maskirq_insn(zero, zero)");
    //asm volatile("timer "); // Instrução NO OPERATION para garantir que o compilador não otimize o loop
    // loop para ler as 10 primeiros palavras da RAM
    for(int i = 0; i < 10; i++){
        uint32_t value = 0;
        // read 10 first words of RAM
        value = mmio_read32(RAM_BASE + i*4);
        // enquanto value for 0, espera
        while(value == 0)
            asm volatile("nop"); // instrução NO OPERATION
        // escreve o valor lido 128 bytes depois
        // na simulação a palavra será vista 128/4 = 32 palavras depois
        mmio_write32(RAM_BASE + 0x0900 + i*4, value);
    }
   

    while(1)
    {
        // endereço de memória 1023 da variável mem do axi_ram
        mmio_write32(RAM_BASE + 0x08FC, ext_irq_4_count);
        
        mmio_write32(GPIO_BASE + 0x0, ext_irq_4_count);
    }
    return 0;
}

