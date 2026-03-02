#include <stdint.h>


uint32_t *irq(uint32_t *regs, uint32_t irqs);
extern uint32_t ext_irq_4_count;


uint32_t *irq(uint32_t *regs, uint32_t irqs)
{

	if ((irqs & (1<<4)) != 0) {
		ext_irq_4_count++;
	}

	return regs;
}