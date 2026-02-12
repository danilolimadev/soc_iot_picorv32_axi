#include "../../common/soc.h"


int main() {

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
        mmio_write32(RAM_BASE + 0x80 + i*4, value);
    }
   

    while(1);
    return 0;
}

