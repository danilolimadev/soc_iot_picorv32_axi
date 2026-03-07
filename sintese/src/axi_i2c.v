/* verilator lint_off UNUSEDSIGNAL */
`timescale 1 ns / 1 ps

module axi_i2c (
    input  wire        clk,
    input  wire        resetn,

    // AXI4-Lite Slave Interface
    input  wire [11:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [11:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,

    // I2C Physical Interface
    inout wire i2c_sda,
    inout wire i2c_scl
);

    // Registradores ajustados para 8 bits (corrige WIDTHEXPAND)
    reg [7:0] addr_reg;
    reg [7:0] data_reg;

    reg sda_drive_low;
    reg scl_drive_low;

    // I2C é Open-Drain: Drive 0 para nível baixo, High-Z para nível alto
    assign i2c_sda = (sda_drive_low) ? 1'b0 : 1'bz;
    assign i2c_scl = (scl_drive_low) ? 1'b0 : 1'bz;

    reg busy;

    localparam IDLE      = 4'd0;
    localparam START     = 4'd1;
    localparam SEND_ADDR = 4'd2;
    localparam ACK_ADDR  = 4'd3;
    localparam SEND_DATA = 4'd4;
    localparam ACK_DATA  = 4'd5;
    localparam STOP      = 4'd6;

    reg [3:0] main_state;
    reg [2:0] bit_cnt;    // 3 bits indexam perfeitamente 8 bits (0-7)
    reg [1:0] sub_state;
    reg [7:0] clk_div;

    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'd0;
            s_axi_rresp   <= 2'b00;

            main_state    <= IDLE;
            sub_state     <= 2'd0;
            clk_div       <= 8'd0;
            bit_cnt       <= 3'd0;
            busy          <= 1'b0;
            addr_reg      <= 8'd0;
            data_reg      <= 8'd0;

            sda_drive_low <= 1'b0;
            scl_drive_low <= 1'b0;
        end else begin

            // =====================================================
            // AXI WRITE CHANNEL
            // =====================================================
            s_axi_awready <= (!busy) && s_axi_awvalid && !s_axi_bvalid;
            s_axi_wready  <= (!busy) && s_axi_wvalid  && !s_axi_bvalid;

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end 
            else if (s_axi_awvalid && s_axi_wvalid && s_axi_awready && s_axi_wready) begin
                // Endereço 0x8 (s_axi_awaddr[5:2] == 2) para disparar I2C
                if (s_axi_awaddr[5:2] == 4'h2 && main_state == IDLE) begin
                    addr_reg   <= s_axi_wdata[15:8];
                    data_reg   <= s_axi_wdata[7:0];
                    main_state <= START;
                    sub_state  <= 2'd0;
                    clk_div    <= 8'd0;
                    busy       <= 1'b1;
                end else begin
                    s_axi_bvalid <= 1'b1; // Responde imediatamente se não for o comando I2C
                end
            end

            // =====================================================
            // AXI READ CHANNEL
            // =====================================================
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rdata  <= {31'd0, busy}; // Exemplo: lê status busy
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end

            // =====================================================
            // FSM I2C
            // =====================================================
            if (main_state != IDLE) begin
                clk_div <= clk_div + 8'd1;

                if (clk_div == 8'd20) begin
                    clk_div <= 8'd0;

                    case (main_state)
                        START: begin
                            if (sub_state == 0) begin
                                sda_drive_low <= 1'b1;
                                scl_drive_low <= 1'b0;
                                sub_state     <= 2'd1;
                            end else begin
                                scl_drive_low <= 1'b1;
                                bit_cnt       <= 3'd7;
                                main_state    <= SEND_ADDR;
                                sub_state     <= 2'd0;
                            end
                        end

                        SEND_ADDR, SEND_DATA: begin
                            case (sub_state)
                                2'd0: begin 
                                    scl_drive_low <= 1'b1; 
                                    sub_state     <= 2'd1; 
                                end
                                2'd1: begin
                                    if (main_state == SEND_ADDR)
                                        sda_drive_low <= ~addr_reg[bit_cnt];
                                    else
                                        sda_drive_low <= ~data_reg[bit_cnt];
                                    sub_state <= 2'd2;
                                end
                                2'd2: begin 
                                    scl_drive_low <= 1'b0; 
                                    sub_state     <= 2'd3; 
                                end
                                2'd3: begin
                                    scl_drive_low <= 1'b1;
                                    sub_state     <= 2'd0;
                                    if (bit_cnt == 3'd0)
                                        main_state <= (main_state == SEND_ADDR) ? ACK_ADDR : ACK_DATA;
                                    else
                                        bit_cnt <= bit_cnt - 3'd1;
                                end
                            endcase
                        end

                        ACK_ADDR, ACK_DATA: begin
                            case (sub_state)
                                2'd0: begin scl_drive_low <= 1'b1; sda_drive_low <= 1'b0; sub_state <= 2'd1; end
                                2'd1: sub_state <= 2'd2;
                                2'd2: begin scl_drive_low <= 1'b0; sub_state <= 2'd3; end
                                2'd3: begin
                                    scl_drive_low <= 1'b1;
                                    bit_cnt       <= 3'd7;
                                    sub_state     <= 2'd0;
                                    main_state    <= (main_state == ACK_ADDR) ? SEND_DATA : STOP;
                                end
                            endcase
                        end

                        STOP: begin
                            case (sub_state)
                                2'd0: begin scl_drive_low <= 1'b1; sda_drive_low <= 1'b1; sub_state <= 2'd1; end
                                2'd1: begin scl_drive_low <= 1'b0; sub_state <= 2'd2; end
                                2'd2: begin sda_drive_low <= 1'b0; sub_state <= 2'd3; end
                                2'd3: begin
                                    main_state    <= IDLE;
                                    busy          <= 1'b0;
                                    s_axi_bvalid  <= 1'b1; // Resposta de escrita completa
                                end
                            endcase
                        end
                        default: main_state <= IDLE;
                    endcase
                end
            end
        end
    end
endmodule
