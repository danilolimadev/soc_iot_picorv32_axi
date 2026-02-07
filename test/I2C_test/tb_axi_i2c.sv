`timescale 1ns/1ps

module tb_axi_i2c;

    // =========================
    // Clock / Reset
    // =========================
    logic clk;
    logic resetn;

    initial clk = 0;
    always #10 clk = ~clk;   // 50 MHz

    initial begin
        resetn = 0;
        #100;
        resetn = 1;
    end

    // =========================
    // AXI Signals
    // =========================
    logic [11:0] awaddr;
    logic        awvalid;
    wire         awready;

    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wvalid;
    wire         wready;

    wire [1:0]   bresp;
    wire         bvalid;
    logic        bready;

    logic [11:0] araddr;
    logic        arvalid;
    wire         arready;

    wire [31:0]  rdata;
    wire [1:0]   rresp;
    wire         rvalid;
    logic        rready;

    // =========================
    // DUT
    // =========================
    axi_i2c dut (
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

        .s_axi_araddr(araddr),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),

        .s_axi_rdata(rdata),
        .s_axi_rresp(rresp),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready)
    );

    // =========================
    // AXI WRITE TASK
    // =========================
    task axi_write(input [11:0] addr, input [31:0] data);
    begin
        @(posedge clk);
        awaddr  <= addr;
        awvalid <= 1;
        wdata   <= data;
        wstrb   <= 4'hF;
        wvalid  <= 1;

        wait (awready && wready);
        @(posedge clk);
        awvalid <= 0;
        wvalid  <= 0;

        bready <= 1;
        wait (bvalid);
        @(posedge clk);
        bready <= 0;

        $display("[AXI][I2C] WRITE addr=0x%03h data=0x%08h", addr, data);
    end
    endtask

    // =========================
    // AXI READ TASK
    // =========================
    task axi_read(input [11:0] addr, output [31:0] data);
    begin
        @(posedge clk);
        araddr  <= addr;
        arvalid <= 1;

        wait (arready);
        @(posedge clk);
        arvalid <= 0;

        rready <= 1;
        wait (rvalid);
        data = rdata;
        @(posedge clk);
        rready <= 0;

        $display("[AXI][I2C] READ  addr=0x%03h data=0x%08h", addr, data);
    end
    endtask

    // =========================
    // TEST SEQUENCE
    // =========================
    logic [31:0] rx;

    initial begin
        awvalid = 0; wvalid = 0; bready = 0;
        arvalid = 0; rready = 0;

        wait(resetn);

        $display("\n================ TEST_I2C START ================\n");

        axi_write(12'h000, 32'h00000001); // CTRL
        axi_write(12'h004, 32'h00000050); // ADDR
        axi_write(12'h008, 32'h000000A5); // TX

        #50;

        axi_read(12'h00C, rx); // RX

        if (rx == 32'h000000A6)
            $display("\n[TEST_I2C][RESULT] PASS ✅\n");
        else
            $display("\n[TEST_I2C][RESULT] FAIL ❌ (rx=0x%08h)\n", rx);

        $stop;
    end

    // =========================
    // Waveform
    // =========================
    initial begin
        $dumpfile("tb_axi_i2c.vcd");
        $dumpvars(0, tb_axi_i2c);
    end

endmodule
