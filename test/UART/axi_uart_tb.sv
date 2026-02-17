`timescale 1ns / 1ps

module tb_axi_uart();

    // --- Parametros e Sinais ---
    parameter CLK_PERIOD = 20; // 50 MHz
    parameter CLK_FREQ   = 50_000_000;
    parameter BAUD_RATE  = 9600;
    localparam integer BIT_CLKS = CLK_FREQ / BAUD_RATE; 

    logic clk = 0;
    logic resetn;
    integer error_count = 0;
	logic [7:0] test_data = 8'h5A;
	real skew;
	logic [7:0] dummy_data = 8'h5A;
	bit failed = 0;

    // Interface AXI
    logic [11:0] s_axi_awaddr, s_axi_araddr;
    logic s_axi_awvalid, s_axi_awready, s_axi_wvalid, s_axi_wready, s_axi_bvalid, s_axi_bready;
    logic s_axi_arvalid, s_axi_arready, s_axi_rvalid, s_axi_rready;
    logic [31:0] s_axi_wdata, s_axi_rdata;
    logic [3:0] s_axi_wstrb;
    logic [1:0] s_axi_bresp, s_axi_rresp;
    
    // Interface UART
    logic tx, rx;

    // Instancia do DUT
    axi_uart dut (.*);

    // Geracao de Clock
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---------------------------------------------------------
    // BLOCO DE ASSERTIONS (Monitoramento de Protocolo)
    // ---------------------------------------------------------
    // Garante que o AXI Handshake ocorra corretamente
    property p_axi_write_handshake;
        @(posedge clk) disable iff (!resetn)
        s_axi_awvalid |-> s_axi_awready [->1] ##1 !s_axi_awvalid;
    endproperty
    assert_axi_write: assert property (p_axi_write_handshake) else $error("AXI Write Handshake Timeout/Error");

    // ---------------------------------------------------------
    // SEQUENCIA DE TESTES
    // ---------------------------------------------------------
    initial begin
        // Reset Inicial
        resetn = 0; rx = 1;
        s_axi_awaddr = 0; s_axi_awvalid = 0; s_axi_wdata = 0; 
        s_axi_wstrb = 0;  s_axi_wvalid = 0;  s_axi_bready = 0;
        s_axi_araddr = 0; s_axi_arvalid = 0; s_axi_rready = 0;

        $display("\n[START] Iniciando Testbench AXI-UART...");
        #100 resetn = 1;
        repeat(5) @(posedge clk);

        // --- TESTE 1: CPU -> AXI -> TX (Transmissao) ---
        test_tx_transmission(8'h55);
        test_tx_transmission(8'hAA);

        // --- TESTE 2: RX -> AXI -> CPU (Recepcao) ---
        test_rx_reception(8'hA5);
        test_rx_reception(8'h3C);

        // --- TESTE 3: Timing / Framing Error ---
        test_timing_error(8'hFF);
		
        // --- TESTE 4: Erro de Clock (Clock Skew) ---
        test_clock_skew_limits();

        // Relatorio Final
        $display("\n========================================================");
        if (error_count == 0) $display("   STATUS: PASS - Simulacao finalizada com sucesso!");
        else $display("   STATUS: FAIL - Total de Erros: %0d", error_count);
        $display("========================================================\n");
        
        #1000 $finish;
    end

    // ---------------------------------------------------------
    // TASKS DE TESTE (Modularizadas)
    // ---------------------------------------------------------

    // Teste 1 com Debug de Handshake
    task test_tx_transmission(input [7:0] data);
        $display("[%0t] [TEST 1] Tentando escrever 0x%h no AXI...", $time, data);
        
        // Dispara a escrita
        axi_write(12'h0, {24'h0, data});
        $display("[%0t] [TEST 1] Escrita AXI concluida. Aguardando saida fisica (TX)...", $time);

        fork : tx_watchdog
            begin
                wait(tx == 0); 
                $display("[%0t] [TEST 1] SUCESSO: Start bit detectado!", $time);
            end
            begin
                // Aumentado para 3 periodos de bit para dar margem ao DUT
                #(BIT_CLKS * CLK_PERIOD * 3);
                $error("[%0t] [TEST 1] FALHA: Timeout! O pino TX permaneceu em 1.", $time);
                error_count++;
            end
        join_any
        disable fork; // Limpa o timer se o start bit chegar
        
        #(BIT_CLKS * 12 * CLK_PERIOD); 
    endtask

    // Teste 2 com verificacao de tempo
    task test_rx_reception(input [7:0] data_to_send);
        $display("[%0t] [TEST 2] Injetando no pino RX: 0x%h", $time, data_to_send);
        drive_rx_byte(data_to_send);
        
        // Aguarda tempo suficiente para a UART processar o bit de STOP
        // e transferir o byte para o registrador AXI.
        #(BIT_CLKS * CLK_PERIOD * 3); 
        repeat(50) @(posedge clk); 
        
        // --- PASSO DE DEBUG ---
        $display("[%0t] [TEST 2] Verificando Status (Endereco 12'h4)...", $time);
        axi_read(12'h4); 
        $display("[%0t] [TEST 2] Valor do Status: 0x%h", $time, s_axi_rdata);

        $display("[%0t] [TEST 2] Lendo Dado (Endereco 12'h0)...", $time);
        axi_read(12'h0); 
        
        if (s_axi_rdata[7:0] === data_to_send) begin
            $display("[%0t] [TEST 2] SUCESSO: Lido 0x%h no endereco 0x0", $time, s_axi_rdata[7:0]);
        end else begin
            $display("[%0t] [TEST 2] Tentativa no endereco 12'h4...", $time);
            axi_read(12'h4); // Tenta ler o dado no offset 4
            if (s_axi_rdata[7:0] === data_to_send) begin
                 $display("[%0t] [TEST 2] SUCESSO: Dado encontrado no endereco 0x4!", $time);
            end else begin
                 $error("[%0t] [TEST 2] FALHA: Dado nao encontrado em 0x0 ou 0x4. Lido: 0x%h", $time, s_axi_rdata[7:0]);
                 error_count++;
            end
        end
    endtask

    // Teste 3: Erro de Timing (Stop bit incorreto)
    task test_timing_error(input [7:0] data);
        $display("[%0t] [TEST 3] Injetando Erro de Framing...", $time);
        inject_rx_frame_error(data);
        
        repeat(10) @(posedge clk);
        
        axi_read(12'h4); // Le Status Register
        
        // Assercao: Alguma flag de erro (bit 1 ou superior) deve estar alta
        assert_error_flag: assert (s_axi_rdata != 0)
            else begin
                $error("[%0t] [TEST 3] FALHA: Flag de erro nao subiu no Status Register.", $time);
                error_count++;
            end
    endtask

	// Teste 4: Erro de Clock (Clock Skew)
	// Envia um byte com os bits 1-10% mais lentos para testar a robustez do receptor
	task test_clock_skew_limits();
			
			$display("\n[%0t] [STRESS TEST] Iniciando busca de limite de Skew(dummy_data = 8'h5A)", $time);

			// Testa de 1.01 (1%) até 1.10 (10%) em passos de 1%
			for (skew = 1.01; skew <= 1.10; skew = skew + 0.01) begin
				$display("[%0t] Tentando Skew de %0.0f%%...", $time, (skew-1.0)*100);
				
				inject_clock_skew(dummy_data, skew);
				
				// Espera proporcional ao skew para não ler antes da hora
				#(BIT_CLKS * CLK_PERIOD * 12 * skew); 
				repeat(100) @(posedge clk);
				
				axi_read(12'h4);
				
				if (s_axi_rdata[7:0] === dummy_data) begin
					$display("[%0t] [PASS] Hardware operou corretamente com %0.0f%% de skew.", $time, (skew-1.0)*100);
				end else begin
					$warning("[%0t] [LIMIT] Falha detectada em %0.0f%%. Lido: 0x%h", $time, (skew-1.0)*100, s_axi_rdata[7:0]);
					failed = 1;
					break; // Para o teste ao achar o limite
				end
			end
			
			if (!failed) $display("[%0t] [WOW] O IP suportou 10%% de skew sem falhar!", $time);
		endtask

	// Task que gera o sinal RX com timing alterado
	task inject_clock_skew(input [7:0] data, input real skew_factor);
		integer i;
		real bit_time;
		begin
			bit_time = BIT_CLKS * CLK_PERIOD * skew_factor;
			
			@(posedge clk);
			rx = 0; #bit_time; // Start bit com skew
			
			for(i=0; i<8; i=i+1) begin
				rx = data[i]; #bit_time; 
			end
			
			rx = 1; #bit_time; // Stop bit com skew
			rx = 1;
		end
	endtask	

    // ---------------------------------------------------------
    // DRIVERS FISICOS (UART)
    // ---------------------------------------------------------
    task drive_rx_byte(input [7:0] data);
        integer i;
        rx = 0; #(BIT_CLKS * CLK_PERIOD); // Start
        for(i=0; i<8; i=i+1) begin
            rx = data[i]; #(BIT_CLKS * CLK_PERIOD); 
        end
        rx = 1; #(BIT_CLKS * CLK_PERIOD); // Stop
    endtask

    task inject_rx_frame_error(input [7:0] d);
        integer j;
        rx = 0; #(BIT_CLKS * CLK_PERIOD); // Start
        for(j=0; j<8; j=j+1) begin
            rx = d[j]; #(BIT_CLKS * CLK_PERIOD);
        end
        rx = 0; #(BIT_CLKS * CLK_PERIOD); 
        rx = 1; 
    endtask

    // ---------------------------------------------------------
    // BUS MASTERS (AXI Lite)
    // ---------------------------------------------------------
    task axi_write(input [11:0] addr, input [31:0] data);
        @(posedge clk);
        s_axi_awaddr <= addr; s_axi_awvalid <= 1;
        s_axi_wdata <= data; s_axi_wstrb <= 4'hF; s_axi_wvalid <= 1;
        s_axi_bready <= 1;
        wait(s_axi_awready && s_axi_wready);
        @(posedge clk);
        s_axi_awvalid <= 0; s_axi_wvalid <= 0;
        wait(s_axi_bvalid);
        @(posedge clk);
        s_axi_bready <= 0;
    endtask

    task axi_read(input [11:0] addr);
        @(posedge clk);
        s_axi_araddr <= addr; 
        s_axi_arvalid <= 1; 
        s_axi_rready <= 1;
        wait(s_axi_arready);
        @(posedge clk);
        s_axi_arvalid <= 0;
        wait(s_axi_rvalid);
        @(posedge clk);
        s_axi_rready <= 0;
    endtask

endmodule
