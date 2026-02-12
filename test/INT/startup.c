#include <stdint.h>

#include "custom_ops.h"

/* Símbolos fornecidos pelo linker script */
// extern uint32_t _sidata;     /* início dos dados inicializados na ROM */
// extern uint32_t _sdata;      /* início da seção .data na RAM */
// extern uint32_t _edata;      /* fim da seção .data */
// extern uint32_t _sbss;       /* início da seção .bss */
// extern uint32_t _ebss;       /* fim da seção .bss */
extern uint32_t _stack_top;  /* topo da pilha */

int main(void);
__attribute__((noreturn)) void reset_c(void);

/* Função de reset em C */
__attribute__((noreturn))
void reset_c(void)
{
    // uint32_t *src;
    // uint32_t *dst;

    /* Copiar .data da ROM para RAM */
    // src = &_sidata;
    // dst = &_sdata;
    // while (dst < &_edata) {
    //     *dst++ = *src++;
    // }

    /* Zerar .bss */
    // dst = &_sbss;
    // while (dst < &_ebss) {
    //     *dst++ = 0;
    // }

    /* Chamar main */
    main();

    /* Se main retornar, entra em loop */
    while (1) {
        asm volatile ("wfi");
    }
}

/* Ponto de entrada do sistema */
__attribute__((naked, used, section(".text.start")))
void start_func (void)
{
    asm volatile (
        "la sp, _stack_top\n"
        "j  reset_c\n"
    );
}
