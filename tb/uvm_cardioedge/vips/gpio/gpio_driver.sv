// ============================================================================
// File: gpio_driver.sv
// Directory: tb/uvm_cardioedge/vips/gpio/
// Description: UVM Driver for GPIO VIP
// ============================================================================

`ifndef GPIO_DRIVER_SV
`define GPIO_DRIVER_SV

class gpio_driver extends uvm_driver #(gpio_item);

    virtual gpio_if vif;
    int unsigned num_driven = 0;

    `uvm_component_utils(gpio_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual gpio_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("GPIO_DRV_NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Initialize GPIO VIP outputs
        vif.gpio_in     <= 32'h0;
        vif.gpio_drv_en <= 8'h0;

        `uvm_info("GPIO_DRV", "Waiting for reset release (rst_n == 1)...", UVM_MEDIUM)
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);
        `uvm_info("GPIO_DRV", "Reset released. Starting GPIO stimulus driving loop.", UVM_MEDIUM)

        forever begin
            seq_item_port.get_next_item(req);

            // Wait inter-transaction delay
            if (req.delay_cycles > 0) begin
                repeat (req.delay_cycles) @(posedge vif.clk);
            end else begin
                @(posedge vif.clk);
            end

            // Apply GPIO drive stimulus
            vif.gpio_in     <= req.gpio_in;
            vif.gpio_drv_en <= req.gpio_drv_en;
            req.timestamp    = $time;
            num_driven++;

            `uvm_info("GPIO_DRV", $sformatf("Driving GPIO stimulus #%0d: IN=0x%02h, DRV_EN=0x%02h",
                      num_driven, req.gpio_in[7:0], req.gpio_drv_en), UVM_HIGH)

            // Hold stimulus for requested cycles
            if (req.hold_cycles > 0) begin
                repeat (req.hold_cycles) @(posedge vif.clk);
            end else begin
                @(posedge vif.clk);
            end

            // Release drive enable if drv_en was pulsed
            if (req.gpio_drv_en != 8'h00) begin
                vif.gpio_drv_en <= 8'h00;
                @(posedge vif.clk);
            end

            seq_item_port.item_done();
        end
    endtask

endclass : gpio_driver

`endif // GPIO_DRIVER_SV
