# Teste da RAM AXI4-Lite

Este diretório contém testes para o módulo `axi_ram.v`, que implementa uma memória RAM simples compatível com o protocolo AXI4-Lite. Abaixo, uma análise do modelo e dos testes criados.

## Modelo `axi_ram.v`

O módulo `axi_ram` é uma implementação de memória RAM de 32 bits acessível via barramento AXI4-Lite. Principais características:

- **Parâmetros**:
  - `ADDR_WIDTH`: Largura do endereço (padrão: 16 bits, permitindo 64 KB de memória).
  - `DATA_WIDTH`: Largura dos dados (padrão: 32 bits).

- **Funcionalidades**:
  - Inicialização: Carrega automaticamente o conteúdo do arquivo `firmware.hex` na memória durante a simulação.
  - **Escrita AXI**: Suporta transações de escrita com strobe (`s_axi_wstrb`) para controle byte-a-byte.
  - **Leitura AXI**: Responde a transações de leitura retornando dados da memória.
  - **Respostas**: Sempre retorna `bresp` e `rresp` como `2'b00` (OKAY), indicando sucesso.
  - **Reset**: Em reset ativo baixo (`resetn`), limpa sinais de controle e prepara para operação.

- **Estrutura Interna**:
  - Array de memória: `reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1]`, onde `MEM_WORDS = (1 << ADDR_WIDTH) / (DATA_WIDTH/8)`.
  - Lógica de handshake AXI: Gerencia `awready`, `wready`, `bvalid`, `arready`, `rvalid` para sincronização.

Este módulo é usado como escravo no SoC, mapeado no endereço base `0x0000_0000`, armazenando código e dados do firmware.

## Testes Criados

Dois testbenches foram desenvolvidos para validar o `axi_ram`:

### 1. `tb_axi_ram.v` (Teste Básico sem CPU)
- **Descrição**: Testbench simples que simula um mestre AXI genérico interagindo diretamente com a RAM. Não inclui o processador PicoRV32.
- **Cenários Testados**:
  - Escrita em endereços específicos (ex.: `0x0000_0000` com dados `0xDEADBEEF`).
  - Leitura dos mesmos endereços para verificar integridade.
  - Teste de strobe para escritas parciais (byte-wise).
  - Reset e inicialização.
- **Saída**: 

![RAM_1.png](/waveforms/RAM_1.png)


### 2. `tb_axi_ram_cpu.v` (Teste com CPU PicoRV32)
- **Descrição**: Testbench integrado que conecta o processador PicoRV32 à RAM via interconexão AXI. O CPU executa firmware C carregado na RAM.
- **Cenários Testados**:
  - Inicialização da RAM com `firmware.hex` (gerado a partir de `tb_axi_ram.c`).
  - Execução de instruções RISC-V: O firmware C escreve e lê valores na RAM (ex.: escreve `0x12345678` em endereço `0x1000` e lê de volta).
  - Validação de transações AXI geradas pelo CPU.
  - Verificação de comportamento em loop (escrita/leitura contínua).
- **Firmware C (`tb_axi_ram.c`)**: Código simples em C que acessa a RAM via ponteiros mapeados em memória. Compilado com toolchain RISC-V para gerar `firmware.hex`.
- **Saída**: 

![RAM_2.png](/waveforms/RAM_2.png)




## Dependências e Execução Geral

- **Ferramentas**: Icarus Verilog (`iverilog`, `vvp`), GTKWave para visualização.
- **Arquivos Comuns**: Usa `../common/crt0.S` e `../common/linker.ld` para firmware (não incluídos aqui, mas referenciados no Makefile).
- **Makefile**: Automatiza compilação do firmware C para RISC-V.

Para mais detalhes, consulte o código-fonte dos testbenches e o módulo `axi_ram.v`.</content>
<parameter name="filePath">/home/menezes/soc_iot_picorv32_axi/test/RAM/README.md
