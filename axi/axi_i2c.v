module axi_i2c (
    input  wire        clk,
    input  wire        resetn,

    input  wire [11:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [11:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,

    inout wire i2c_sda,
    inout wire i2c_scl
);

    reg [31:0] addr_reg;
    reg [31:0] data_reg;

    reg sda_drive_low;
    reg scl_drive_low;

    assign i2c_sda = (sda_drive_low) ? 1'b0 : 1'bz;
    assign i2c_scl = (scl_drive_low) ? 1'b0 : 1'bz;

    reg busy;

    localparam IDLE      = 0;
    localparam START     = 1;
    localparam SEND_ADDR = 2;
    localparam ACK_ADDR  = 3;
    localparam SEND_DATA = 4;
    localparam ACK_DATA  = 5;
    localparam STOP      = 6;

    reg [3:0] main_state;
    reg [2:0] bit_cnt;
    reg [1:0] sub_state;
    reg [7:0] clk_div;

    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 0;
            s_axi_wready  <= 0;
            s_axi_bvalid  <= 0;
            s_axi_bresp   <= 0;
            s_axi_arready <= 0;
            s_axi_rvalid  <= 0;
            s_axi_rdata   <= 0;
            s_axi_rresp   <= 0;

            main_state <= IDLE;
            sub_state <= 0;
            clk_div <= 0;
            busy <= 0;

            sda_drive_low <= 0;
            scl_drive_low <= 0;
        end else begin

            // =====================================================
            // AXI WRITE — AGORA ESPERA busy = 0
            // =====================================================
            s_axi_awready <= (!busy) && s_axi_awvalid;
            s_axi_wready  <= (!busy) && s_axi_wvalid;

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 0;

            else if (s_axi_awvalid && s_axi_wvalid && s_axi_awready && s_axi_wready) begin
                // Dado → Inicia FSM
                if (s_axi_awaddr[5:2] == 4'h2 && main_state == IDLE) begin
                    addr_reg <= s_axi_wdata[15:8];
                    data_reg <= s_axi_wdata[7:0];

                    main_state <= START;
                    sub_state <= 0;
                    clk_div <= 0;
                    busy <= 1;
                end
            end

            // =====================================================
            // AXI READ (igual ao seu)
            // =====================================================
            s_axi_arready <= (!s_axi_arready && s_axi_arvalid);

            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1;
                s_axi_rdata  <= 0;
            end else if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 0;

            // =====================================================
            // FSM I2C
            // =====================================================
            if (main_state != IDLE) begin
                clk_div <= clk_div + 1;

                if (clk_div == 20) begin
                    clk_div <= 0;

                    case (main_state)

                        START: begin
                            if (sub_state == 0) begin
                                sda_drive_low <= 1;
                                scl_drive_low <= 0;
                                sub_state <= 1;
                            end else begin
                                scl_drive_low <= 1;
                                bit_cnt <= 7;
                                main_state <= SEND_ADDR;
                                sub_state <= 0;
                            end
                        end

                        SEND_ADDR, SEND_DATA: begin
                            case (sub_state)
                                0: begin scl_drive_low <= 1; sub_state <= 1; end
                                1: begin
                                    if (main_state == SEND_ADDR)
                                        sda_drive_low <= ~addr_reg[bit_cnt];
                                    else
                                        sda_drive_low <= ~data_reg[bit_cnt];
                                    sub_state <= 2;
                                end
                                2: begin scl_drive_low <= 0; sub_state <= 3; end
                                3: begin
                                    scl_drive_low <= 1;
                                    sub_state <= 0;
                                    if (bit_cnt == 0)
                                        main_state <= (main_state == SEND_ADDR) ? ACK_ADDR : ACK_DATA;
                                    else
                                        bit_cnt <= bit_cnt - 1;
                                end
                            endcase
                        end

                        ACK_ADDR, ACK_DATA: begin
                            case (sub_state)
                                0: begin scl_drive_low <= 1; sda_drive_low <= 0; sub_state <= 1; end
                                1: sub_state <= 2;
                                2: begin scl_drive_low <= 0; sub_state <= 3; end
                                3: begin
                                    scl_drive_low <= 1;
                                    bit_cnt <= 7;
                                    sub_state <= 0;
                                    main_state <= (main_state == ACK_ADDR) ? SEND_DATA : STOP;
                                end
                            endcase
                        end

                        STOP: begin
                            case (sub_state)
                                0: begin scl_drive_low <= 1; sda_drive_low <= 1; sub_state <= 1; end
                                1: begin scl_drive_low <= 0; sub_state <= 2; end
                                2: begin
                                    sda_drive_low <= 0;
                                    sub_state <= 3;
                                end
                                3: begin
                                    main_state <= IDLE;
                                    busy <= 0;            // libera AXI
                                    s_axi_bvalid <= 1;    // RESPONDE SÓ AGORA
                                end
                            endcase
                        end
                    endcase
                end
            end
        end
    end
endmodule
