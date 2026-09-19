// =============================================================================
// aes_axi_slave.sv
// AXI4-Lite Slave Wrapper for AES-256
//
// Wraps aes_cipher_top (encryption) and aes_inv_cipher_top (decryption)
// behind a standard AXI4-Lite slave interface.
//
// AXI4-Lite interface:
//   - 32-bit data width
//   - 32-bit address width
//   - Synchronous active-low reset (S_AXI_ARESETN)
//
// Register Map (byte offsets from peripheral base address):
//
//   0x00 : CONTROL/STATUS
//            bit 0 = START  (write 1 to start; self-clearing after acceptance)
//            bit 1 = DECRYPT (0=encrypt, 1=decrypt)
//            bit 2 = DONE   (read-only; clears on new START)
//            bit 3 = BUSY   (read-only)
//            bits[31:4] = reserved
//
//   0x04 : KEY0   = key[31:0]
//   0x08 : KEY1   = key[63:32]
//   0x0C : KEY2   = key[95:64]
//   0x10 : KEY3   = key[127:96]
//   0x14 : KEY4   = key[159:128]
//   0x18 : KEY5   = key[191:160]
//   0x1C : KEY6   = key[223:192]
//   0x20 : KEY7   = key[255:224]
//
//   0x24 : DATA_IN0  = data_in[31:0]
//   0x28 : DATA_IN1  = data_in[63:32]
//   0x2C : DATA_IN2  = data_in[95:64]
//   0x30 : DATA_IN3  = data_in[127:96]
//
//   0x34 : DATA_OUT0 = data_out[31:0]   (read-only)
//   0x38 : DATA_OUT1 = data_out[63:32]  (read-only)
//   0x3C : DATA_OUT2 = data_out[95:64]  (read-only)
//   0x40 : DATA_OUT3 = data_out[127:96] (read-only)
//
// Operation:
//   1. Write 256-bit KEY to KEY0..KEY7
//   2. Write 128-bit plaintext/ciphertext to DATA_IN0..DATA_IN3
//   3. Set DECRYPT bit if decrypting
//   4. Write START=1 to CONTROL register
//   5. Poll CONTROL until DONE=1 (BUSY=0)
//   6. Read DATA_OUT0..DATA_OUT3
//
// =============================================================================

module aes_axi_slave #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 32
)(
    input  logic                              S_AXI_ACLK,
    input  logic                              S_AXI_ARESETN,

    // Write address channel
    input  logic [C_S_AXI_ADDR_WIDTH-1:0]    S_AXI_AWADDR,
    input  logic                              S_AXI_AWVALID,
    output logic                              S_AXI_AWREADY,

    // Write data channel
    input  logic [C_S_AXI_DATA_WIDTH-1:0]    S_AXI_WDATA,
    input  logic [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  logic                              S_AXI_WVALID,
    output logic                              S_AXI_WREADY,

    // Write response channel
    output logic [1:0]                        S_AXI_BRESP,
    output logic                              S_AXI_BVALID,
    input  logic                              S_AXI_BREADY,

    // Read address channel
    input  logic [C_S_AXI_ADDR_WIDTH-1:0]    S_AXI_ARADDR,
    input  logic                              S_AXI_ARVALID,
    output logic                              S_AXI_ARREADY,

    // Read data channel
    output logic [C_S_AXI_DATA_WIDTH-1:0]    S_AXI_RDATA,
    output logic [1:0]                        S_AXI_RRESP,
    output logic                              S_AXI_RVALID,
    input  logic                              S_AXI_RREADY
);

    // =========================================================================
    // Register address offsets
    // =========================================================================
    localparam [7:0]
        OFS_CSR      = 8'h00,
        OFS_KEY0     = 8'h04,
        OFS_KEY1     = 8'h08,
        OFS_KEY2     = 8'h0C,
        OFS_KEY3     = 8'h10,
        OFS_KEY4     = 8'h14,
        OFS_KEY5     = 8'h18,
        OFS_KEY6     = 8'h1C,
        OFS_KEY7     = 8'h20,
        OFS_DIN0     = 8'h24,
        OFS_DIN1     = 8'h28,
        OFS_DIN2     = 8'h2C,
        OFS_DIN3     = 8'h30,
        OFS_DOUT0    = 8'h34,
        OFS_DOUT1    = 8'h38,
        OFS_DOUT2    = 8'h3C,
        OFS_DOUT3    = 8'h40;

    // =========================================================================
    // Internal registers
    // =========================================================================
    logic [31:0] reg_key0, reg_key1, reg_key2, reg_key3;
    logic [31:0] reg_key4, reg_key5, reg_key6, reg_key7;
    logic [31:0] reg_din0, reg_din1, reg_din2, reg_din3;
    logic [31:0] reg_dout0, reg_dout1, reg_dout2, reg_dout3;

    // Control/Status bits
    logic        reg_decrypt;  // 0=encrypt, 1=decrypt
    logic        reg_done;     // sticky done flag
    logic        reg_busy;     // reflects core busy

    // AES core connections
    logic [255:0] aes_key;
    logic [127:0] aes_data_in;
    logic [127:0] enc_data_out, dec_data_out;
    logic         enc_done, dec_done;
    logic         enc_busy, dec_busy;
    logic         enc_start, dec_start;

    // Assemble key and data_in from registers
    // KEY0 = key[31:0], KEY7 = key[255:224]
    assign aes_key     = {reg_key7, reg_key6, reg_key5, reg_key4,
                          reg_key3, reg_key2, reg_key1, reg_key0};

    // DIN0 = data_in[31:0], DIN3 = data_in[127:96]
    assign aes_data_in = {reg_din3, reg_din2, reg_din1, reg_din0};

    // Instantiate encryption core
    aes_cipher_top u_enc (
        .clk     (S_AXI_ACLK),
        .rst_n   (S_AXI_ARESETN),
        .start   (enc_start),
        .key     (aes_key),
        .text_in (aes_data_in),
        .text_out(enc_data_out),
        .busy    (enc_busy),
        .done    (enc_done)
    );

    // Instantiate decryption core
    aes_inv_cipher_top u_dec (
        .clk     (S_AXI_ACLK),
        .rst_n   (S_AXI_ARESETN),
        .start   (dec_start),
        .key     (aes_key),
        .text_in (aes_data_in),
        .text_out(dec_data_out),
        .busy    (dec_busy),
        .done    (dec_done)
    );

    // Composite busy/done
    assign reg_busy = reg_decrypt ? dec_busy : enc_busy;

    // =========================================================================
    // AXI Write Address / Data Handshake
    // =========================================================================
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    logic aw_en;  // enables address capture

    // Simultaneous AWVALID+WVALID handshake (single-beat AXI4-Lite)
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
            axi_awaddr    <= '0;
        end
        else begin
            if (!S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID) begin
                S_AXI_AWREADY <= 1'b1;
                S_AXI_WREADY  <= 1'b1;
                axi_awaddr    <= S_AXI_AWADDR;
            end
            else begin
                S_AXI_AWREADY <= 1'b0;
                S_AXI_WREADY  <= 1'b0;
            end
        end
    end

    // Write enable pulse
    wire wr_en = S_AXI_AWREADY & S_AXI_AWVALID & S_AXI_WREADY & S_AXI_WVALID;

    // =========================================================================
    // Write Response Channel
    // =========================================================================
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_BVALID <= 1'b0;
            S_AXI_BRESP  <= 2'b00;
        end
        else if (wr_en) begin
            S_AXI_BVALID <= 1'b1;
            S_AXI_BRESP  <= 2'b00;   // OKAY
        end
        else if (S_AXI_BVALID && S_AXI_BREADY) begin
            S_AXI_BVALID <= 1'b0;
        end
    end

    // =========================================================================
    // Register Write Logic
    // =========================================================================
    // AES core start signals (one-cycle pulses)
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            reg_key0    <= 32'h0;  reg_key1    <= 32'h0;
            reg_key2    <= 32'h0;  reg_key3    <= 32'h0;
            reg_key4    <= 32'h0;  reg_key5    <= 32'h0;
            reg_key6    <= 32'h0;  reg_key7    <= 32'h0;
            reg_din0    <= 32'h0;  reg_din1    <= 32'h0;
            reg_din2    <= 32'h0;  reg_din3    <= 32'h0;
            reg_dout0   <= 32'h0;  reg_dout1   <= 32'h0;
            reg_dout2   <= 32'h0;  reg_dout3   <= 32'h0;
            reg_decrypt <= 1'b0;
            reg_done    <= 1'b0;
            enc_start   <= 1'b0;
            dec_start   <= 1'b0;
        end
        else begin
            // Default: start pulses are one-cycle wide
            enc_start <= 1'b0;
            dec_start <= 1'b0;

            // Capture done from cores (sticky until next START)
            if (!reg_decrypt && enc_done) begin
                reg_done  <= 1'b1;
                reg_dout0 <= enc_data_out[31:0];
                reg_dout1 <= enc_data_out[63:32];
                reg_dout2 <= enc_data_out[95:64];
                reg_dout3 <= enc_data_out[127:96];
            end
            if (reg_decrypt && dec_done) begin
                reg_done  <= 1'b1;
                reg_dout0 <= dec_data_out[31:0];
                reg_dout1 <= dec_data_out[63:32];
                reg_dout2 <= dec_data_out[95:64];
                reg_dout3 <= dec_data_out[127:96];
            end

            if (wr_en) begin
                case (axi_awaddr[7:0])
                    OFS_CSR: begin
                        // bit 1: DECRYPT mode select
                        if (S_AXI_WSTRB[0]) begin
                            reg_decrypt <= S_AXI_WDATA[1];
                        end
                        // bit 0: START - trigger the selected operation
                        if (S_AXI_WSTRB[0] && S_AXI_WDATA[0] && !reg_busy) begin
                            reg_done  <= 1'b0;   // clear previous done
                            if (S_AXI_WDATA[1])   // DECRYPT
                                dec_start <= 1'b1;
                            else                   // ENCRYPT
                                enc_start <= 1'b1;
                        end
                    end
                    OFS_KEY0: if (S_AXI_WSTRB[0]) reg_key0 <= S_AXI_WDATA;
                    OFS_KEY1: if (S_AXI_WSTRB[0]) reg_key1 <= S_AXI_WDATA;
                    OFS_KEY2: if (S_AXI_WSTRB[0]) reg_key2 <= S_AXI_WDATA;
                    OFS_KEY3: if (S_AXI_WSTRB[0]) reg_key3 <= S_AXI_WDATA;
                    OFS_KEY4: if (S_AXI_WSTRB[0]) reg_key4 <= S_AXI_WDATA;
                    OFS_KEY5: if (S_AXI_WSTRB[0]) reg_key5 <= S_AXI_WDATA;
                    OFS_KEY6: if (S_AXI_WSTRB[0]) reg_key6 <= S_AXI_WDATA;
                    OFS_KEY7: if (S_AXI_WSTRB[0]) reg_key7 <= S_AXI_WDATA;
                    OFS_DIN0: if (S_AXI_WSTRB[0]) reg_din0 <= S_AXI_WDATA;
                    OFS_DIN1: if (S_AXI_WSTRB[0]) reg_din1 <= S_AXI_WDATA;
                    OFS_DIN2: if (S_AXI_WSTRB[0]) reg_din2 <= S_AXI_WDATA;
                    OFS_DIN3: if (S_AXI_WSTRB[0]) reg_din3 <= S_AXI_WDATA;
                    // DATA_OUT registers are read-only; writes are ignored
                    default: ; // unmapped addresses: OKAY response, data ignored
                endcase
            end
        end
    end

    // =========================================================================
    // AXI Read Address Handshake
    // =========================================================================
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
            axi_araddr    <= '0;
        end
        else begin
            if (!S_AXI_ARREADY && S_AXI_ARVALID) begin
                S_AXI_ARREADY <= 1'b1;
                axi_araddr    <= S_AXI_ARADDR;
            end
            else begin
                S_AXI_ARREADY <= 1'b0;
            end
        end
    end

    // =========================================================================
    // Read Data Mux
    // =========================================================================
    logic [31:0] rd_data_comb;

    always_comb begin
        rd_data_comb = 32'h0;
        case (axi_araddr[7:0])
            OFS_CSR:   rd_data_comb = {28'h0, reg_busy, reg_done, reg_decrypt, 1'b0};
            OFS_KEY0:  rd_data_comb = reg_key0;
            OFS_KEY1:  rd_data_comb = reg_key1;
            OFS_KEY2:  rd_data_comb = reg_key2;
            OFS_KEY3:  rd_data_comb = reg_key3;
            OFS_KEY4:  rd_data_comb = reg_key4;
            OFS_KEY5:  rd_data_comb = reg_key5;
            OFS_KEY6:  rd_data_comb = reg_key6;
            OFS_KEY7:  rd_data_comb = reg_key7;
            OFS_DIN0:  rd_data_comb = reg_din0;
            OFS_DIN1:  rd_data_comb = reg_din1;
            OFS_DIN2:  rd_data_comb = reg_din2;
            OFS_DIN3:  rd_data_comb = reg_din3;
            OFS_DOUT0: rd_data_comb = reg_dout0;
            OFS_DOUT1: rd_data_comb = reg_dout1;
            OFS_DOUT2: rd_data_comb = reg_dout2;
            OFS_DOUT3: rd_data_comb = reg_dout3;
            default:   rd_data_comb = 32'hDEAD_BEEF;  // unmapped
        endcase
    end

    // =========================================================================
    // AXI Read Data Channel
    // =========================================================================
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_RVALID <= 1'b0;
            S_AXI_RRESP  <= 2'b00;
            S_AXI_RDATA  <= 32'h0;
        end
        else if (S_AXI_ARREADY && S_AXI_ARVALID && !S_AXI_RVALID) begin
            S_AXI_RVALID <= 1'b1;
            S_AXI_RRESP  <= 2'b00;   // OKAY
            S_AXI_RDATA  <= rd_data_comb;
        end
        else if (S_AXI_RVALID && S_AXI_RREADY) begin
            S_AXI_RVALID <= 1'b0;
        end
    end

endmodule
