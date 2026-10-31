// ============================================================================
// File: uart_driver.sv
// Directory: tb/uvm_cardioedge/vips/uart/
// Description: UVM Driver for UART VIP transmitting serial frames into CardioEdge SoC
// ============================================================================

`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

class uart_driver extends uvm_driver #(uart_item);

    virtual uart_if vif;
    time baud_period = 1280ns; // 50 MHz clock (20ns), BAUD_DIV = 4, 16x oversampling
    int unsigned num_driven = 0;

    `uvm_component_utils(uart_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("UART_DRV_NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
        end
        void'(uvm_config_db#(time)::get(this, "", "baud_period", baud_period));
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Idle line state is high
        vif.uart_rx_i <= 1'b1;

        `uvm_info("UART_DRV", "Waiting for reset release (rst_n == 1)...", UVM_MEDIUM)
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);
        `uvm_info("UART_DRV", $sformatf("Reset released. UART Transmitter active (baud_period = %0t)", baud_period), UVM_MEDIUM)

        forever begin
            seq_item_port.get_next_item(req);

            // Wait idle delay before start bit
            if (req.delay_bauds > 0) begin
                repeat (req.delay_bauds) #(baud_period);
            end

            num_driven++;
            req.timestamp = $time;
            `uvm_info("UART_DRV", $sformatf("Transmitting byte #%0d to DUT: 0x%02h ('%c')",
                      num_driven, req.data, (req.data >= 32 && req.data <= 126) ? req.data : 8'h2E), UVM_MEDIUM)

            // 1. Start bit (logic 0)
            vif.uart_rx_i <= 1'b0;
            #(baud_period);

            // 2. 8 Data bits (LSB first)
            for (int b = 0; b < 8; b++) begin
                vif.uart_rx_i <= req.data[b];
                #(baud_period);
            end

            // 3. Stop bit (logic 1)
            vif.uart_rx_i <= 1'b1;
            #(baud_period);

            seq_item_port.item_done();
        end
    endtask

endclass : uart_driver

`endif // UART_DRIVER_SV
