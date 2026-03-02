`timescale 1ns/1ps

module axi_uart_tb;

    // =========================================================
    // Clock / Reset
    // =========================================================
    reg clk;
    reg resetn;

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        resetn = 0;
        #100;
        resetn = 1;
    end

    // =========================================================
    // AXI
    // =========================================================
    reg  [11:0] awaddr;
    reg         awvalid;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    wire        awready;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;

    // =========================================================
    // UART
    // =========================================================
    wire tx;
    reg  rx;

    // =========================================================
    // Verificação
    // =========================================================
    reg [7:0] expected [0:4];
    integer   rx_index;
    integer   error_count;

    // =========================================================
    // DUT
    // =========================================================
    axi_uart dut (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awaddr(awaddr),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),

        .s_axi_wdata(wdata),
        .s_axi_wstrb(wstrb),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),

        .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready),

        .s_axi_araddr(12'b0),
        .s_axi_arvalid(1'b0),
        .s_axi_arready(),
        .s_axi_rdata(),
        .s_axi_rresp(),
        .s_axi_rvalid(),
        .s_axi_rready(1'b0),

        .tx(tx),
        .rx(rx)
    );

    // =========================================================
    // Init
    // =========================================================
    initial begin
        rx = 1'b1;
        awvalid = 0;
        wvalid  = 0;
        bready  = 0;

        expected[0] = "U";
        expected[1] = "A";
        expected[2] = "R";
        expected[3] = "T";
        expected[4] = "\n";

        rx_index    = 0;
        error_count = 0;
    end

    // =========================================================
    // AXI write
    // =========================================================
    task axi_write;
        input [11:0] addr;
        input [7:0]  data;
        begin
            @(posedge clk);
            awaddr  <= addr;
            awvalid <= 1'b1;
            wdata   <= {24'b0, data};
            wstrb   <= 4'b0001;
            wvalid  <= 1'b1;
            bready  <= 1'b1;

            @(posedge clk);
            awvalid <= 0;
            wvalid  <= 0;

            wait (bvalid);
            @(posedge clk);
        end
    endtask

    // =========================================================
    // Aguarda pulso de tx_done
    // =========================================================
    task wait_tx_done_pulse;
        begin
            @(posedge dut.tx_done);
        end
    endtask

    // =========================================================
    // Teste principal
    // =========================================================
    initial begin
        wait(resetn);

        $display("\n[TB] Teste UART AXI iniciado\n");

        // Primeiro byte NÃO espera
        axi_write(12'h000, "U");

        wait_tx_done_pulse();
        axi_write(12'h000, "A");

        wait_tx_done_pulse();
        axi_write(12'h000, "R");

        wait_tx_done_pulse();
        axi_write(12'h000, "T");

        wait_tx_done_pulse();
        axi_write(12'h000, "\n");

        // Aguarda último byte terminar
        wait_tx_done_pulse();
        #50000;

        if (error_count == 0) begin
            $display("\n==============================");
            $display("✅ UART TEST PASSOU");
            $display("==============================\n");
        end else begin
            $display("\n==============================");
            $display("❌ UART TEST FALHOU (%0d erros)", error_count);
            $display("==============================\n");
            $fatal;
        end

        $stop;
    end

    // =========================================================
    // UART Monitor + Checker
    // =========================================================
    reg [9:0] shift = 0;
    integer i;
    realtime baud = 400;//8680

    initial begin
        forever begin
            @(negedge tx);
            #(baud/2);

            for (i = 0; i < 10; i = i + 1) begin
                shift[i] = tx;
                if(i != 9)#(baud);
            end

            if (shift[0] == 0 && shift[9] == 1) begin
                if (shift[8:1] !== expected[rx_index]) begin
                    $error("[UART] Byte %0d incorreto: esperado '%c', recebido '%c'",
                           rx_index, expected[rx_index], shift[8:1]);
                    error_count = error_count + 1;
                end else begin
                    $display("[UART] Byte %0d OK: '%c'", rx_index, shift[8:1]);
                end
                rx_index = rx_index + 1;
            end else begin
                $error("[UART] Erro de framing");
                error_count = error_count + 1;
            end
        end
    end

    // =========================================================
    // Timeout
    // =========================================================
    initial begin
        #2_000_000;
        $fatal("[TB] Timeout — UART não finalizou transmissão");
    end

endmodule
