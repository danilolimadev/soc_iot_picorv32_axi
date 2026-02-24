# Testbench de Interrupções do PicoRV32

Este diretório contém um testbench para testar o suporte a interrupções (IRQs) no core PicoRV32 integrado com uma RAM via interface AXI.

## Arquivos Principais

- `int_cpu_top.v`: Módulo top-level que instancia o PicoRV32 (com IRQs habilitadas), RAM AXI e interconnect.
- `tb_int_cpu.v`: Testbench que simula o sistema, gera clock/reset e ativa uma IRQ externa.
- `int_cpu.c`: Firmware C que executa no PicoRV32, lê/escreve na RAM e trata IRQs.
- `irq.c`: Handler de interrupções em C, conta ocorrências de IRQs externas e de timer.
- `start.S`: Startup code em assembly, configura o stack e chama main.
- `Makefile`: Compila o firmware RISC-V e gera hex para inicializar a RAM.

## Descrição do Testbench

O testbench `tb_int_cpu.v` realiza os seguintes passos:

1. **Inicialização**: Define clock (100 MHz), reset ativo-baixo, e IRQ = 0.
2. **Reset**: Mantém reset por 5 ciclos, depois libera.
3. **Execução do Firmware**: Aguarda 20.000 ciclos para o CPU inicializar e executar o loop principal em `int_cpu.c` (lê 10 palavras da RAM, espera valores não-zero, escreve em outro local).
4. **Ativação da IRQ**: Define `irq[4] = 1` para simular uma interrupção externa (IRQ 4).
5. **Tratamento**: O PicoRV32 salta para o handler em `irq.c` (endereço 0x0000_0010), que incrementa `ext_irq_4_count`.
6. **Finalização**: Após 100.000 ciclos, finaliza a simulação.

### Configurações do PicoRV32
- `ENABLE_IRQ = 1`: Suporte a IRQs habilitado.
- `MASKED_IRQ = 32'hFFFF_FF00`: Permite IRQs 0-7 (mascara 8-31).
- `PROGADDR_IRQ = 32'h0000_0010`: Vetor de interrupção.

### Firmware
- `int_cpu.c`: Loop infinito após processar RAM.
- `irq.c`: Trata IRQs, conta `ext_irq_4_count` para IRQ 4.

## Resultados Esperados
- Contador `ext_irq_4_count` em `irq.c` deve ser > 0 após a IRQ.
- Waveforms mostram PC saltando para 0x10 e `irq_active` setado.

![Waveforms da Simulação de IRQ 4](/waveforms/INT_IRQ4.png)
