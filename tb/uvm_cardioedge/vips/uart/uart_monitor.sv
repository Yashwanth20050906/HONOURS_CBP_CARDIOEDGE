// ============================================================================
// File: uart_monitor.sv
// Directory: tb/uvm_cardioedge/vips/uart/
// Description: UVM Monitor for UART VIP monitoring serial characters from CardioEdge SoC
// ============================================================================

`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

class uart_monitor extends uvm_monitor;

    virtual uart_if vif;
    uvm_analysis_port #(uart_item) ap;
    time baud_period = 1280ns;
    int unsigned num_monitored = 0;

    `uvm_component_utils(uart_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("UART_MON_NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
        end
        void'(uvm_config_db#(time)::get(this, "", "baud_period", baud_period));
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_item item;
        logic [7:0] rx_byte;

        // Wait for reset release
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            // 1. Wait for Start bit falling edge
            @(negedge vif.uart_tx_o);

            // 2. Sample at mid-point of start bit to filter glitches
            #(baud_period / 2);
            if (vif.uart_tx_o !== 1'b0) begin
                `uvm_warning("UART_MON_GLITCH", "Glitched start bit detected on uart_tx_o, ignoring")
                continue;
            end

            // 3. Sample 8 data bits at mid-bit points
            rx_byte = 8'h00;
            for (int b = 0; b < 8; b++) begin
                #(baud_period);
                rx_byte[b] = vif.uart_tx_o;
            end

            // 4. Sample Stop bit (must be 1)
            #(baud_period);
            if (vif.uart_tx_o !== 1'b1) begin
                `uvm_error("UART_MON_FRAME_ERR", $sformatf("Framing error detected! Expected Stop bit=1, got %0b", vif.uart_tx_o))
            end

            // Wait remainder of stop bit
            #(baud_period / 2);

            num_monitored++;
            item = uart_item::type_id::create("uart_mon_item");
            item.data      = rx_byte;
            item.is_dut_tx = 1'b1;
            item.timestamp = $time;
            item.trans_id  = num_monitored;

            `uvm_info("UART_MON", $sformatf("Monitored SoC Character #%0d: 0x%02h ('%c') at %0t",
                      num_monitored, item.data, (item.data >= 32 && item.data <= 126) ? item.data : 8'h2E, item.timestamp), UVM_MEDIUM)

            ap.write(item);
        end
    endtask

endclass : uart_monitor

`endif // UART_MONITOR_SV
