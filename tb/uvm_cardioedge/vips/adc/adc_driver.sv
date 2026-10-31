// ============================================================================
// File: adc_driver.sv
// Directory: tb/uvm_cardioedge/vips/adc/
// Description: UVM Driver for ADC VIP driving samples to CardioEdge SoC
// ============================================================================

`ifndef ADC_DRIVER_SV
`define ADC_DRIVER_SV

class adc_driver extends uvm_driver #(adc_item);

    virtual adc_if vif;
    int unsigned num_driven = 0;

    `uvm_component_utils(adc_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual adc_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("ADC_DRV_NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Initialize interface to inactive state
        vif.sample_in    <= 12'h000;
        vif.sample_valid <= 1'b0;

        // Wait for system reset release
        `uvm_info("ADC_DRV", "Waiting for reset release (rst_n == 1)...", UVM_MEDIUM)
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);
        `uvm_info("ADC_DRV", "Reset released. Starting ADC sample driving loop.", UVM_MEDIUM)

        forever begin
            seq_item_port.get_next_item(req);

            // Wait inter-sample delay
            if (req.delay_cycles > 0) begin
                repeat (req.delay_cycles) @(posedge vif.clk);
            end else begin
                @(posedge vif.clk);
            end

            // Drive sample onto interface
            vif.sample_in    <= req.sample_in;
            vif.sample_valid <= req.sample_valid;
            req.timestamp    = $time;
            num_driven++;

            `uvm_info("ADC_DRV", $sformatf("Driving ADC sample #%0d: 0x%03h (%0d), valid=%0b",
                      num_driven, req.sample_in, req.sample_in, req.sample_valid), UVM_HIGH)

            @(posedge vif.clk);
            // Deassert valid after one clock cycle
            vif.sample_valid <= 1'b0;

            seq_item_port.item_done();
        end
    endtask

endclass : adc_driver

`endif // ADC_DRIVER_SV
