`timescale 1ns / 1ps

module axi_gpio_tb;

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

    wire [31:0]             gpio_out;

    axi_gpio #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
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
        .s_axi_rready(s_axi_rready),
        .gpio_out(gpio_out)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

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

    // Leitura AXI-Lite
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

        // Escrita no GPIO
        axi_write(12'h000, 32'hAAAA5555);
        #20;
        if (gpio_out === 32'hAAAA5555)
            $display("SUCESSO: gpio_out atualizado corretamente.");
        else
            $display("ERRO: gpio_out incorreto! Valor: 0x%h", gpio_out);

        // Leitura do GPIO
        axi_read(12'h000);

        
        #100;
        $display("Simulação Finalizada.");
        $finish;
    end

endmodule