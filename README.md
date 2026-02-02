# 🧩 PicoRV32 AXI SoC Full

Este projeto implementa um **System-on-Chip (SoC)** completo baseado no processador **PicoRV32**, utilizando uma **interconexão AXI4-Lite** para comunicação entre memória e periféricos.  
Inclui módulos AXI para **GPIO**, **UART**, **SPI**, **I2C**, **TIMER** e **RAM**, além de uma **testbench funcional** e um **firmware de teste** (`firmware.hex`) carregado automaticamente na simulação.

---

## 🏗️ Estrutura do Projeto

```
picorv32_axi_soc_full/
├── firmware.hex
├── README.md
├── test/
│   └── tb_soc_top.v
└── axi/
    ├── axi_gpio.v
    ├── axi_i2c.v
    ├── axi_interconnect.v
    ├── axi_ram.v
    ├── axi_spi.v
    ├── axi_timer.v
    ├── axi_uart.v
    ├── picorv32.v
    ├── soc_top.v
    ├── tb_soc_top.v
    ├── uart_rx.v
    └── uart_tx.v
```

---

## ⚙️ Descrição dos Principais Módulos

### 🔹 `soc_top.v`
Integra o núcleo **PicoRV32**, a **interconexão AXI4-Lite**, a **memória RAM** e todos os **periféricos AXI** (GPIO, UART, SPI, I2C e TIMER).  
Responsável pelo mapeamento de endereços e pela comunicação entre o processador e os periféricos.

### 🔹 `axi_interconnect.v`
Implementa o barramento **AXI4-Lite** que interliga o processador, a memória e os periféricos.  
Realiza o roteamento das transações de leitura e escrita com base nos endereços.

### 🔹 `axi_ram.v`
Memória RAM interna acessada via AXI4-Lite.  
Durante a simulação, carrega automaticamente o conteúdo do arquivo `firmware.hex`.

### 🔹 `axi_gpio.v`
Módulo de entrada/saída genérico controlado via AXI.  
Permite escrita e leitura de registradores mapeados em memória.

### 🔹 `axi_uart.v`
Interface serial UART com registradores de transmissão (`uart_tx.v`) e recepção (`uart_rx.v`).  
Simula a comunicação serial entre o SoC e dispositivos externos.

### 🔹 `axi_spi.v`
Controlador SPI compatível com AXI4-Lite, com registradores de controle, TX e RX.  
Atualmente implementa comportamento de **loopback** para testes.

### 🔹 `axi_i2c.v`
Módulo AXI I2C simplificado (stub) com registradores de controle, TX e RX, também com loopback interno para verificação de acesso via AXI.

### 🔹 `axi_timer.v`
Temporizador simples com contador e registradores AXI.  
Pode ser usado para gerar interrupções ou eventos temporizados em versões futuras.

---

## 🧠 Mapa de Endereços

| Periférico | Endereço Base       |
|-------------|--------------------|
| RAM         | `0x0000_0000`      |
| GPIO        | `0x1000_0000`      |
| UART        | `0x2000_0000`      |
| SPI         | `0x3000_0000`      |
| I2C         | `0x4000_0000`      |
| TIMER       | `0x5000_0000`      |

---

## 🔬 Testbench (`tb_soc_top.v`)

A testbench fornece ambiente completo de simulação:

- Geração de **clock** e **reset**;
- Inicialização da **memória RAM** com `firmware.hex`;
- Observação das transações **AXI4-Lite** de leitura e escrita;
- Validação de acesso aos periféricos GPIO, UART, SPI, I2C e TIMER;
- Registro de sinais em arquivo **.vcd** para análise em simulador de forma de onda (ex: GTKWave).

---

## 🧩 Firmware de Teste (`firmware.hex`)

Arquivo em formato hexadecimal compatível com a inicialização da AXI RAM.  
O programa executa instruções simples de escrita e leitura nos periféricos, validando o funcionamento do barramento AXI e das respostas dos módulos.

---

## ▶️ Simulação

Para simular o SoC, utilize **Icarus Verilog** ou **ModelSim**:

```bash
cd axi
iverilog -o soc_tb tb_soc_top.v soc_top.v axi_*.v picorv32.v uart_*.v
vvp soc_tb
```

Após a simulação, visualize o resultado:

```bash
gtkwave dump.vcd
```

🧾 Licença

Este projeto é distribuído sob a licença MIT.
Sinta-se à vontade para estudar, modificar e expandir o SoC para fins educacionais e de pesquisa.

---
