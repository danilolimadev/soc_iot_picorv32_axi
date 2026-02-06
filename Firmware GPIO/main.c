#include "../common/soc.h"

#define GPIO_OUT (GPIO_BASE + 0x0)

int main() {

    mmio_write32(GPIO_OUT, 0xA5A5A5A5);

    if(mmio_read32(GPIO_OUT) != 0xA5A5A5A5)
        while(1);

    mmio_write32(GPIO_OUT, 0xFFFFFFFF);

    if(mmio_read32(GPIO_OUT) != 0xFFFFFFFF)
        while(1);

    while(1);
    return 0;
}

