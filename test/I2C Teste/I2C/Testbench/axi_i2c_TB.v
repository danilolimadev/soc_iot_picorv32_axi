`timescale 1ns / 1ps

module axi_i2c_tb;

    parameter ADDR_WIDTH = 12;
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10;

    reg                     clk;
    reg                     resetn;

    reg  [ADDR_WIDTH-1:0]   s_axi_awaddr;
    reg                     s_axi_awvalid;
    wire                    s_axi_awready;
    reg  [DATA_WIDTH-1:0]   s_axi_wdata;
    reg  [3:0]              s_axi_wstrb;
    reg                     s_axi_wvalid;
    wire                    s_axi_wready;
    wire [1:0]              s_axi_bresp;
    wire                    s_axi_bvalid;
    reg                     s_axi_bready;

    reg  [ADDR_WIDTH-1:0]   s_axi_araddr;
    reg                     s_axi_arvalid;
    wire                    s_axi_arready;
    wire [DATA_WIDTH-1:0]   s_axi_rdata;
    wire [1:0]              s_axi_rresp;
    wire                    s_axi_rvalid;
    reg                     s_axi_rready;

    // Instância do DUT (apenas sinais AXI)
    axi_i2c uut (
        .clk(clk),
        .resetn(resetn),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready)
    );

    // Clock
    always #(CLK_PERIOD/2) clk = ~clk;

    // Task de Escrita AXI
    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            @(posedge clk);
            s_axi_awaddr  <= addr;
            s_axi_awvalid <= 1'b1;
            s_axi_wdata   <= data;
            s_axi_wstrb   <= 4'hF;
            s_axi_wvalid  <= 1'b1;
            s_axi_bready  <= 1'b1;

            wait(s_axi_awready && s_axi_awvalid);
            @(posedge clk);
            s_axi_awvalid <= 1'b0;
           
            wait(s_axi_wready && s_axi_wvalid);
            @(posedge clk);
            s_axi_wvalid  <= 1'b0;

            wait(s_axi_bvalid);
            @(posedge clk);
            s_axi_bready  <= 1'b0;
            $display("[WRITE] Addr: 0x%h, Data: 0x%h", addr, data);
        end
    endtask

    // Task de Leitura AXI
    task axi_read(input [ADDR_WIDTH-1:0] addr);
        begin
            @(posedge clk);
            s_axi_araddr  <= addr;
            s_axi_arvalid <= 1'b1;
            s_axi_rready  <= 1'b1;

            wait(s_axi_arready && s_axi_arvalid);
            @(posedge clk);
            s_axi_arvalid <= 1'b0;

            wait(s_axi_rvalid);
            $display("[READ]  Addr: 0x%h, Data: 0x%h", addr, s_axi_rdata);
            @(posedge clk);
            s_axi_rready  <= 1'b0;
        end
    endtask

    initial begin
        // Inicialização
        clk = 0;
        resetn = 0;
        s_axi_awaddr = 0;
        s_axi_awvalid = 0;
        s_axi_wdata = 0;
        s_axi_wstrb = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 0;
        s_axi_araddr = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 0;

        // Reset
        repeat(5) @(posedge clk);
        resetn = 1;
        repeat(2) @(posedge clk);

        $display("\n========================================");
        $display("    TESTE AXI I2C - INICIADO");
        $display("========================================\n");

        // --- Teste 1: Configurar Prescaler (CTRL) ---
        $display("--- Teste 1: Configurar Prescaler ---");
        axi_write(12'h000, 32'h0000_0064); // Prescaler = 100
        #20;

        // --- Teste 2: Escrever Endereço Slave ---
        $display("\n--- Teste 2: Endereço Slave I2C ---");
        axi_write(12'h004, 32'h0000_0050); // Endereço slave 0x50
        #20;

        // --- Teste 3: Escrever Dados TX ---
        $display("\n--- Teste 3: Enviar Dados TX ---");
        axi_write(12'h008, 32'h0000_00AA); // Dado 0xAA
        #20;

        // --- Teste 4: Ler Status ---
        $display("\n--- Teste 4: Ler Status ---");
        axi_read(12'h00C);
        #20;

        // --- Teste 5: Sequência Completa I2C ---
        $display("\n--- Teste 5: Transação I2C Completa ---");
        
        // Habilitar I2C
        axi_write(12'h000, 32'h0000_0001);
        #20;
        
        // START condition
        axi_write(12'h000, 32'h0000_0003); // START bit
        #100;
        
        // Enviar endereço
        axi_write(12'h004, 32'h0000_00A0); // 0x50 << 1 | W
        #100;
        
        // Enviar dado
        axi_write(12'h008, 32'h0000_0055);
        #100;
        
        // STOP condition
        axi_write(12'h000, 32'h0000_0004);
        #100;

        // --- Teste 6: Verificar Flags de Status ---
        $display("\n--- Teste 6: Verificar Status Final ---");
        axi_read(12'h00C);

        #100;
        $display("\n========================================");
        $display("    TESTE AXI I2C - FINALIZADO");
        $display("========================================\n");
        $finish;
    end

    // Dump de sinais
    initial begin
        $dumpfile("axi_i2c_tb.vcd");
        $dumpvars(0, axi_i2c_tb);
    end

    // Timeout
    initial begin
        #100000;
        $display("TIMEOUT!");
        $finish;
    end

endmodule