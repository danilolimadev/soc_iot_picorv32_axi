# Revisar - Está tudo diferente agora

# Projeto UVM - PicoRV32 SoC

Este diretório contém a **estrutura de verificação UVM** para o SoC baseado no PicoRV32, com periféricos AXI-Lite (RAM, GPIO, UART, SPI, I2C, Timer).


## Estrutura do projeto

```
top_tb.sv
├─ DUT
├─ soc_bfm.sv
└─ soc_test.sv
    └─ soc_env.sv
        ├─ soc_sequencer.sv
        ├─ soc_driver.sv
        ├─ soc_monitor.sv
        ├─ soc_scoreboard.sv
        └─ soc_coverage.sv
```

## Descrição dos módulos

- **top_tb.sv**  
  Instancia o DUT e o testbench. Chama `run_test()` do UVM.

- **DUT**  
  Seu SoC (PicoRV32 + periféricos) que será verificado.

- **soc_bfm.sv**  
  Conecta sinais do testbench ao DUT via `virtual interface`. Implementa a **camada de baixo nível de comunicação**.

- **soc_test.sv**  
  Classe UVM `uvm_test` que configura o ambiente e escolhe quais sequences rodar.

- **soc_env.sv**  
  Classe UVM `uvm_env` que agrega:
  - Sequencer
  - Driver
  - Monitor
  - Scoreboard
  - Coverage

- **soc_sequencer.sv**  
  Sequencer UVM que envia **sequence_items** para o driver.

- **soc_driver.sv**  
  Recebe **sequence_items** do sequencer e converte em estímulos físicos no DUT (via BFM).

- **soc_monitor.sv**  
  Observa sinais do DUT e reconstrói **transações** para análise.

- **soc_scoreboard.sv**  
  Recebe transações do monitor e compara com resultados esperados (**checa funcionalidade**).

- **soc_coverage.sv**  
  Recebe transações do monitor para gerar **cobertura funcional**.

---
