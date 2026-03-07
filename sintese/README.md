# SoC RISC-V com OpenLane

Este projeto descreve o desenvolvimento e a síntese física de um **System on Chip (SoC)** baseado no núcleo PicoRV32, utilizando o fluxo automatizado do OpenLane executado dentro de um container Docker.

O objetivo é demonstrar o fluxo completo, desde a organização do HDL até a geração do layout físico do chip. O projeto foi implementado utilizando o PDK SkyWater Sky130, tecnologia CMOS de 130 nm que é de codigo aberto e possui grande documentação disponivel.

A frequencia alvo de operação foi fixada em 50Mhz.

---

# Ambiente de Desenvolvimento

Para garantir reprodutibilidade e consistência do fluxo de síntese, utilizamos o OpenLane executado dentro de um container Docker.

## 🔹 Docker

O Docker foi utilizado para:

- Criar um ambiente isolado e controlado
- Garantir compatibilidade entre versões das ferramentas
- Evitar conflitos de dependências
- Permitir portabilidade entre diferentes máquinas

Com isso, todo o fluxo de síntese pode ser reproduzido de forma confiável.

---

# Fluxo de Síntese com OpenLane

O OpenLane é um fluxo automatizado de design digital RTL-to-GDSII que integra diversas ferramentas de EDA.

Abaixo estão as principais ferramentas utilizadas no processo:

---

## 🔹 Yosys – Síntese Lógica

Responsável por:

- Converter o código RTL (Verilog) em uma netlist lógica
- Realizar otimizações iniciais
- Remover lógica redundante
- Preparar o design para as próximas etapas

Entrada: Código RTL  
Saída: Netlist otimizada

---

## 🔹 ABC – Otimização Lógica

Ferramenta utilizada internamente pelo Yosys para:

- Minimização lógica
- Redução de área
- Melhoria de timing
- Balanceamento de portas lógicas

---

## 🔹 OpenROAD – Place and Route

Responsável pelas etapas físicas do design:

- Floorplanning
- Placement (posicionamento das células)
- Clock Tree Synthesis (CTS)
- Routing (roteamento das interconexões)
- Análise de timing (STA)

---

## 🔹 Magic – Verificação de Layout

Utilizado para:

- Visualização do layout físico
- Verificação de regras de fabricação (DRC)
- Geração do arquivo final GDSII

---

## 🔹 Netgen – LVS (Layout Versus Schematic)

Ferramenta responsável por:

- Comparar o layout físico com a netlist lógica
- Garantir que o circuito implementado corresponde ao projeto original

---

# Estrutura do Projeto

A organização do projeto foi planejada para permitir modularidade, reutilização e síntese independente das macros.

```
openlane/designs/
            ├── picorv32_macro/        # Macro 1: Núcleo RISC-V (PicoRV32 CPU)
            │
            ├── axi_rom/               # Macro 2: ROM AXI (boot / firmware storage)
            │   ├── src/
            │   │   └── axi_rom.v
            │   └── config.json
            │
            ├── axi_ram/               # Macro 3: Memória RAM AXI
            │   ├── src/
            │   │   └── axi_ram.v
            │   └── config.json
            │
            ├── axi_peripherals/       # Macro 4: Interconnect + Periféricos
            │   ├── src/
            │   │   ├── axi_interconnect.v
            │   │   ├── axi_uart.v
            │   │   ├── boot_manager.v
            │   │   └── ...
            │   └── config.json
            │
            └── soc_top/               # Top Level do SoC (macro integration)
                ├── macros/            # LEF, GDS, LIB e configs das macros
                ├── src/
                │   └── soc_top.v
                └── config.json
```

---

## 🔹 picorv32_macro

Contém o núcleo RISC-V responsável pela execução das instruções e controle do sistema.

---

## 🔹 axi_ram

Implementa a memória principal do SoC utilizando o protocolo AXI.

- `axi_ram.v`: Implementação RTL
- `config.json`: Parâmetros de síntese da macro

---

## 🔹 axi_peripherals

Inclui:

- Interconexão AXI
- UART
- Boot manager
- Demais periféricos do sistema

Cada módulo é descrito em Verilog dentro da pasta `src/`.

---

## 🔹 soc_top

Módulo responsável por instanciar as três macros e interligá-las.

- `soc_top.v`: Integração completa do SoC
- `macros/`: Arquivos físicos gerados das macros
- `config.json`: Configurações globais do design

---

# Estratégia de Síntese Modular

O desenvolvimento seguiu uma abordagem modular e incremental focada no reaproveitamento e otimização.

---

## 1️⃣ Síntese do PicoRV32

Por ser modular e reutilizável, o PicoRV32 foi a primeira macro sintetizada.

Isso permitiu:

- Validar o núcleo do processador isoladamente
- Garantir funcionamento correto antes da integração

---

## 2️⃣ Validação do HDL

A estratégia adotada para validação foi:

- Realizar uma primeira síntese utilizando parâmetros padrão (default)
- Verificar ausência de erros
- Confirmar consistência do código RTL

Essa etapa garantiu que o HDL estivesse correto antes das otimizações.

---

## 3️⃣ Síntese das Demais Macros

Após validar o núcleo, foram sintetizadas:

- axi_ram
- axi_peripherals

Durante essa etapa foram coletadas métricas importantes:

- Área ocupada
- Análise estática de timing (STA)
- Estimativas de desempenho

Esses dados foram fundamentais para o planejamento físico do SoC. Cada macro gera um csv com o resumo das metricas [picorv32](metrics_pico.csv), [axi_ram](metrics_ram.csv) e [axi_peripherals](metrics_axi.csv). 

Tabela de resultados
| design_name     | total_runtime | DIEAREA_mm² | CellPer_mm² | wns | AND | DFF | NAND | NOR | OR  | XOR | XNOR | MUX  | Fmax (MHz) |
|-----------------|--------------|-------------|-------------|-----|-----|-----|------|-----|-----|-----|------|------|------------|
| picorv32        | 0h20m11s     | 0.25        | 44,716      | 1.57| 405 | 91  | 226  | 171 |1045 |388  |113   |2709 | 66.67      |
| axi_peripherals | 0h6m35s      | 0.0795      | 27,788      | 0.00| 78  | 15  | 96   | 44  |426  |97   |19    |170  | 286.5      |
| axi_ram         | 1h18m40s     | 0.827       | 53,804      | 5.60| 6   | 0   | 4    | 3   |307  |0    |0     |8212 | 100.00     |
| axi_rom         | 1h4m8s       | 0.8596      | 51,962      | 0.00| 41  | 4   | 40   | 11  |395  |121  |7     |8160 | 206.6      |
| soc_top         | 0h36m37s     | 4.84        | 63.63       | 0.00| 2   | 0   | 15   | 1   |20   |17   |14    |64   | 185.9      |

*O consumo global de todo sistema foi aproximadamente 120mW.

---
# Planejamento do Layout do SoC

Com os valores de área de cada macro, foi possível definir um floorplan inicial para dar forma física ao SoC.

A disposição adotada foi:

```
 -----------
|   2  |    |
|------|  1 |
|   3  |    |
|      |    |
 -----------
```

Legenda:

- **1** → PicoRV32  
- **2** → axi_ram  
- **3** → axi_peripherals  

Essa organização foi definida com base:

- Na área de cada macro
- Na proximidade lógica entre os blocos
- Na otimização das interconexões

Vista renderizada com a ferramenta Klayout
<img width="794" height="736" alt="foorplain" src="https://github.com/user-attachments/assets/628d31c8-7f2d-4dd0-a467-3e3575c92261" />

---

# ✅ Conclusão

A abordagem modular permitiu:

- Desenvolvimento incremental
- Validação isolada de cada bloco
- Melhor controle de área e timing e consumo de energia
- Integração organizada no top-level

---

 # Trabalhos Futuros

 A partir dos resultados obtidos, abre-se espaço para a realização de otimizações mais refinadas no projeto, com foco no aprimoramento individual de cada macrobloco do sistema. Estudos futuros podem explorar ajustes mais detalhados nos parâmetros de síntese e place-and-route, visando melhorar métricas como área, densidade, consumo de potência e desempenho temporal (timing).

Além disso, realizar a avaliação de diferentes estratégias de distribuição da rede de alimentação (PDN), analisando o impacto na integridade de sinal, queda de tensão (IR drop) e robustez do layout. Também podem ser investigadas variações na organização física dos blocos (floorplanning), buscando topologias que reduzam congestionamento e melhorem o roteamento global.
