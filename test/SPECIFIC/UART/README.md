# AXI Lite UART IP - Testbench & Verification Suite

O **axi_uart_tb.sv** é um mbiente de verificação (**Testbench**) desenvolvido em **SystemVerilog** para validação de um núcleo de IP UART com interface **AXI4-Lite** simplificados para compor um SoC focado em soluções IoT.

O foco deste projeto foi garantir:

- ✅ Conformidade com o protocolo AXI  
- ✅ Robustez física da UART frente a variações de clock  
- ✅ Tratamento correto de erros de enquadramento  

---

## Metodologia de Verificação

O ambiente utiliza uma abordagem de **Verificação Baseada em Simulação (SBV)**, empregando as seguintes técnicas:

### 🔹 Modularização por Tasks
Separação clara entre:
- Drivers físicos (UART)
- Bus masters (AXI)
- Sequências de teste

### 🔹 Protocol Assertions (SVA)
Uso de **SystemVerilog Assertions** para garantir que o handshake do protocolo AXI (**VALID/READY**) ocorra sem:
- Violações de timing
- Deadlocks

### 🔹 Stress Testing (Corner Cases)
Injeção de desvios de temporização propositais para encontrar o ponto de falha do hardware.

### 🔹 Self-Checking
O testbench compara automaticamente os valores recebidos com os esperados, reportando um log detalhado de erros.

---

## Cobertura de Testes

### 1️⃣ Teste de Transmissão (CPU → AXI → TX)

Valida o fluxo de saída de dados.

- **Método:** Escrita via AXI Lite no endereço de transmissão.
- **Verificação:** Monitoramento físico do pino TX para detectar:
  - Bit de Start
  - Enquadramento correto do byte enviado

---

### 2️⃣ Teste de Recepção (RX → AXI → CPU)

Valida o fluxo de entrada e o armazenamento interno.

- **Método:** Injeção de bytes via driver UART no pino RX.
- **Verificação:** Leitura via AXI Lite nos endereços de status e dados para confirmar a integridade da informação recebida.

---

### 3️⃣ Teste de Erro de Framing (Framing Error)

Valida o comportamento do IP diante de sinais corrompidos.

- **Método:** Injeção de um byte com o Stop Bit incorreto (nível lógico `'0'`).
- **Verificação:** Checagem se o IP sinaliza corretamente o erro através do registrador de Status (bit de erro).

---

### 4️⃣ Limite de Clock Skew (Stress Test)

Teste de robustez para medir a tolerância do receptor a variações na taxa de Baud Rate.

- **Técnica:** O Testbench incrementa gradualmente o tempo de bit (Skew) de **1% até 10%**.
- **Resultado:** O IP demonstrou alta qualidade, suportando até **6% de desvio**, superando o limite teórico padrão de **5% para transmissões de 8 bits**.

---

## Detalhes Técnicos do Ambiente

| Parâmetro            | Valor de Configuração |
|----------------------|----------------------|
| Clock do Sistema     | 50 MHz (CLK_PERIOD = 20ns) |
| Baud Rate            | 9600 bps |
| Frame format         | 8N1 (fixado) |
| Protocolo Bus        | AXI4-Lite (32-bit data) |
| Linguagem            | SystemVerilog |
| Tolerância Medida    | 6% de Clock Skew |

---

## Exemplo de Saída do Monitor

```plaintext
[START] Iniciando Testbench AXI-UART...
[TEST 1] SUCESSO: Start bit detectado!
[TEST 2] SUCESSO: Dado encontrado no endereco 0x4!
[STRESS TEST] Iniciando busca de limite de Skew...
[PASS] Hardware operou corretamente com 6% de skew.
[LIMIT] Falha detectada em 7%. Lido: 0xda
STATUS: PASS - Simulacao finalizada com sucesso!
```

---
<img width="1436" height="805" alt="image" src="https://github.com/user-attachments/assets/f00589bb-a4d8-487f-8fe7-eb23fd6299ee" />

Desenvolvido para validação robusta de IPs digitais com foco em conformidade de protocolo e análise de tolerância temporal.
