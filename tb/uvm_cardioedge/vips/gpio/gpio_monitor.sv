// ============================================================================
// File: gpio_monitor.sv
// Directory: tb/uvm_cardioedge/vips/gpio/
// Description: UVM Monitor for GPIO VIP
// ============================================================================

`ifndef GPIO_MONITOR_SV
`define GPIO_MONITOR_SV

class gpio_monitor extends uvm_monitor;

    virtual gpio_if vif;
    uvm_analysis_port #(gpio_item) ap;
    int unsigned num_monitored = 0;

    `uvm_component_utils(gpio_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual gpio_if)::get(
                this, "", "vif", vif)) begin
            `uvm_fatal("GPIO_MON",
                       "Failed to retrieve GPIO virtual interface")
        end
        `uvm_info("GPIO_MON", "[GPIO VIF] Virtual interface connected: vif != null", UVM_LOW)
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpio_item item;
        logic [31:0] prev_out = 32'hDEAD_BEEF;
        logic [31:0] prev_oe  = 32'hDEAD_BEEF;
        logic [31:0] prev_in  = 32'hDEAD_BEEF;

        // Wait for reset release
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            @(posedge vif.clk);
            if (vif.rst_n) begin
                // Check if any GPIO line transitioned
                if ((vif.gpio_out !== prev_out) || (vif.gpio_oe !== prev_oe) || 
                    ((vif.gpio_drv_en != 8'h0) && (vif.gpio_in !== prev_in))) begin
                    
                    item = gpio_item::type_id::create("gpio_mon_item");
                    item.gpio_out     = vif.gpio_out;
                    item.gpio_oe      = vif.gpio_oe;
                    item.gpio_in      = vif.gpio_in;
                    item.gpio_drv_en  = vif.gpio_drv_en;
                    item.gpio_irq     = vif.gpio_irq;
                    item.timestamp    = $time;
                    num_monitored++;
                    item.trans_id     = num_monitored;

                    prev_out = vif.gpio_out;
                    prev_oe  = vif.gpio_oe;
                    prev_in  = vif.gpio_in;

                    `uvm_info("GPIO_MON", $sformatf("[GPIO DUT] GPIO output observed: OUT=0x%02h, OE=0x%02h, IRQ=%0b",
                              item.gpio_out[7:0], item.gpio_oe[7:0], item.gpio_irq), UVM_LOW)
                    `uvm_info("GPIO_MON", $sformatf("[GPIO MONITOR] Transaction captured: ID=%0d, OUT=0x%02h, OE=0x%02h, IN=0x%02h at %0t",
                              num_monitored, item.gpio_out[7:0], item.gpio_oe[7:0], item.gpio_in[7:0], item.timestamp), UVM_LOW)
                    `uvm_info("GPIO_MON", $sformatf("Observed GPIO pattern = OUT: 0x%02h, OE: 0x%02h",
                              item.gpio_out[7:0], item.gpio_oe[7:0]), UVM_MEDIUM)

                    $display("[LIVE MONITOR] GPIO | TIME: %0t | TXN ID: %0d | GPIO IN: 0x%02h | GPIO OUT: 0x%02h | GPIO DIR: 0x%02h | STATUS: DRV_EN=0x%02h, IRQ=%0b",
                             item.timestamp, num_monitored, item.gpio_in[7:0], item.gpio_out[7:0], item.gpio_oe[7:0], item.gpio_drv_en, item.gpio_irq);

                    ap.write(item);
                end
            end
        end
    endtask

endclass : gpio_monitor

`endif // GPIO_MONITOR_SV
