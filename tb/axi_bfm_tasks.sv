//------------------------------------------------------------------------------
// File: axi_bfm_tasks.sv
// Description: Common AXI4-Lite Bus Functional Model (BFM) tasks for verification.
//
// Tasks:
//   - axi_write(addr, data): Standard write transaction.
//   - axi_write_strb(addr, data, strb): Write transaction with byte strobes.
//   - axi_read(addr, data): Standard read transaction.
//
// Assumptions:
//   - Signals are expected to be available in the parent scope:
//     s_axi_awaddr, s_axi_wdata, s_axi_awvalid, s_axi_wvalid, s_axi_wstrb,
//     s_axi_bready, s_axi_awready, s_axi_wready, s_axi_bvalid,
//     s_axi_araddr, s_axi_arvalid, s_axi_rready, s_axi_arready, 
//     s_axi_rvalid, s_axi_rdata
//   - Clock is 'aclk'
//------------------------------------------------------------------------------

    // AXI Write Task
    task axi_write(input [31:0] addr, input [31:0] data);
        s_axi_awaddr  = addr;
        s_axi_wdata   = data;
        s_axi_awvalid = 1;
        s_axi_wvalid  = 1;
        s_axi_wstrb   = 4'hF;
        s_axi_bready  = 1;
        
        wait(s_axi_awready && s_axi_wready);
        @(posedge aclk);
        #1;
        s_axi_awvalid = 0;
        s_axi_wvalid  = 0;
        
        wait(s_axi_bvalid);
        @(posedge aclk);
        #1;
        s_axi_bready  = 0;
    endtask

    // AXI Write Task with Strobe
    task axi_write_strb(input [31:0] addr, input [31:0] data, input [3:0] strb);
        s_axi_awaddr  = addr;
        s_axi_wdata   = data;
        s_axi_awvalid = 1;
        s_axi_wvalid  = 1;
        s_axi_wstrb   = strb;
        s_axi_bready  = 1;
        
        wait(s_axi_awready && s_axi_wready);
        @(posedge aclk);
        #1;
        s_axi_awvalid = 0;
        s_axi_wvalid  = 0;
        
        wait(s_axi_bvalid);
        @(posedge aclk);
        #1;
        s_axi_bready  = 0;
    endtask

    // AXI Read Task
    task axi_read(input [31:0] addr, output [31:0] data);
        s_axi_araddr  = addr;
        s_axi_arvalid = 1;
        s_axi_rready  = 1;
        
        wait(s_axi_arready);
        @(posedge aclk);
        #1;
        s_axi_arvalid = 0;
        
        wait(s_axi_rvalid);
        data = s_axi_rdata;
        @(posedge aclk);
        #1;
        s_axi_rready  = 0;
    endtask
