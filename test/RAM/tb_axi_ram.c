#include "../../common/soc.h"


int main() {

    // read 10 first words of RAM
    for(int i = 0; i < 10; i++){
        uint32_t value = mmio_read32(RAM_BASE + i*4);
        mmio_write32(RAM_BASE + 0x100 + i*4, value);
    }
   

    while(1);
    return 0;
}

