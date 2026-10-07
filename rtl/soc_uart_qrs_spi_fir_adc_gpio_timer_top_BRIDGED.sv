// ============================================================================
// File: soc_uart_qrs_spi_fir_adc_gpio_timer_top_BRIDGED.sv
// Project: HONOURS_CBP_CARDIOEDGE
//
// Top-Level Module: soc_uart_qrs_spi_fir_adc_gpio_timer_top
// Interconnect    : axi_interconnect_wrap_3x18 (Shared Group 3x18 AXI4 Fabric)
//
// ============================================================================
// AUTHORITATIVE CARDIOEDGE ADDRESS MAP & PORT ALLOCATION
// ============================================================================
//   Interconnect Port | Peripheral          | Address Range           | Notes
//  -------------------+---------------------+-------------------------+-------------------
//   M00               | UART                | 0x4000_0000–0x4000_0FFF | Native AXI4/AXI-Lite
//   M01               | GPIO                | 0x4000_2000–0x4000_2FFF | AXI4-Lite via Bridge
//   M02               | TIMER               | 0x4000_4000–0x4000_4FFF | AXI4-Lite via Bridge
//   M03               | FIR                 | 0x4000_C000–0x4000_CFFF | AXI4-Lite subset
//   M04               | ADC                 | 0x4000_E000–0x4000_EFFF | Native AXI4-Lite subset
//   M05               | SPI                 | 0x4001_0000–0x4001_0FFF | Native AXI4/AXI-Lite
//   M06               | QRS                 | 0x4001_2000–0x4001_2FFF | Native AXI4 Wrapper
//  -------------------+---------------------+-------------------------+-------------------
//   M07               | DUMMY (WATCHDOG)    | 0x4000_6000–0x4000_6FFF | Placeholder Dummy Slave
//   M08               | DUMMY (FFT CTRL)    | 0x4000_8000–0x4000_8FFF | Placeholder Dummy Slave
//   M09               | DUMMY (FFT MEM)     | 0x4000_A000–0x4000_AFFF | Placeholder Dummy Slave
//   M10               | DUMMY (AES)         | 0x4001_4000–0x4001_4FFF | Placeholder Dummy Slave
//   M11               | DUMMY (INT AGGR)    | 0x4001_6000–0x4001_6FFF | Placeholder Dummy Slave
//   M12               | DUMMY (PWM)         | 0x4001_8000–0x4001_8FFF | Placeholder Dummy Slave
//   M13               | DUMMY (I2C)         | 0x4001_A000–0x4001_AFFF | Placeholder Dummy Slave
//   M14               | DUMMY (DMA REG)     | 0x4001_C000–0x4001_CFFF | Placeholder Dummy Slave
//   M15               | DUMMY (FUTURE 1)    | 0x4001_E000–0x4001_EFFF | Placeholder Dummy Slave
//   M16               | DUMMY (FUTURE 2)    | 0x4002_0000–0x4002_0FFF | Placeholder Dummy Slave
//   M17               | DUMMY (FUTURE 3)    | 0x4002_2000–0x4002_2FFF | Placeholder Dummy Slave
// ============================================================================
// Interconnect Masters (Slaves to Interconnect):
//   S00 : Active Verification / CPU Master Bus (driven by testbench)
//   S01 : Inactive placeholder (tied off safely)
//   S02 : Inactive placeholder (tied off safely)
// ============================================================================

`timescale 1ns/1ps
`default_nettype none

module soc_uart_qrs_spi_fir_adc_gpio_timer_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = 4,
    parameter ID_WIDTH   = 8
)(
    input  wire                     clk,
    input  wire                     rst,

    /* ============================================================
     * S00 AXI4 Slave Interface (Active SoC Master Interface)
     * ============================================================ */
    input  wire [ID_WIDTH-1:0]      s00_axi_awid,
    input  wire [ADDR_WIDTH-1:0]    s00_axi_awaddr,
    input  wire [7:0]               s00_axi_awlen,
    input  wire [2:0]               s00_axi_awsize,
    input  wire [1:0]               s00_axi_awburst,
    input  wire                     s00_axi_awlock,
    input  wire [3:0]               s00_axi_awcache,
    input  wire [2:0]               s00_axi_awprot,
    input  wire [3:0]               s00_axi_awqos,
    input  wire [0:0]               s00_axi_awuser,
    input  wire                     s00_axi_awvalid,
    output wire                     s00_axi_awready,

    input  wire [DATA_WIDTH-1:0]    s00_axi_wdata,
    input  wire [STRB_WIDTH-1:0]    s00_axi_wstrb,
    input  wire                     s00_axi_wlast,
    input  wire [0:0]               s00_axi_wuser,
    input  wire                     s00_axi_wvalid,
    output wire                     s00_axi_wready,

    output wire [ID_WIDTH-1:0]      s00_axi_bid,
    output wire [1:0]               s00_axi_bresp,
    output wire [0:0]               s00_axi_buser,
    output wire                     s00_axi_bvalid,
    input  wire                     s00_axi_bready,

    input  wire [ID_WIDTH-1:0]      s00_axi_arid,
    input  wire [ADDR_WIDTH-1:0]    s00_axi_araddr,
    input  wire [7:0]               s00_axi_arlen,
    input  wire [2:0]               s00_axi_arsize,
    input  wire [1:0]               s00_axi_arburst,
    input  wire                     s00_axi_arlock,
    input  wire [3:0]               s00_axi_arcache,
    input  wire [2:0]               s00_axi_arprot,
    input  wire [3:0]               s00_axi_arqos,
    input  wire [0:0]               s00_axi_aruser,
    input  wire                     s00_axi_arvalid,
    output wire                     s00_axi_arready,

    output wire [ID_WIDTH-1:0]      s00_axi_rid,
    output wire [DATA_WIDTH-1:0]    s00_axi_rdata,
    output wire [1:0]               s00_axi_rresp,
    output wire                     s00_axi_rlast,
    output wire [0:0]               s00_axi_ruser,
    output wire                     s00_axi_rvalid,
    input  wire                     s00_axi_rready,

    /* ============================================================
     * External Peripheral I/O Pins
     * ============================================================ */

    /* UART external pins */
    input  wire                     uart_rx_i,
    output wire                     uart_tx_o,

    /* SPI external pins */
    input  wire                     spi_miso_i,
    output wire                     spi_clk_o,
    output wire                     spi_cs_n_o,
    output wire                     spi_mosi_o,

    /* FIR AXI4-Stream input */
    input  wire                     fir_s_axis_tvalid,
    output wire                     fir_s_axis_tready,
    input  wire [15:0]              fir_s_axis_tdata,

    /* FIR AXI4-Stream output */
    output wire                     fir_m_axis_tvalid,
    input  wire                     fir_m_axis_tready,
    output wire [39:0]              fir_m_axis_tdata,

    /* ADC external sample interface & interrupts */
    input  wire [11:0]              adc_sample_in,
    input  wire                     adc_sample_valid,
    output wire                     adc_irq_sample,
    output wire                     adc_irq_overrun,

    /* GPIO external pins & interrupt */
    inout  wire [7:0]               gpio_io,
    output wire                     gpio_irq,

    /* Timer external pins & interrupt */
    input  wire                     timer_ext_meas_i,
    input  wire                     timer_capture_i,
    output wire                     timer_pwm_o,
    output wire                     timer_trigger_o,
    output wire                     timer_irq
);

    /* ------------------------------------------------------------
     * Interconnect Master Port M00
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m00_axi_awid;
    wire [ADDR_WIDTH-1:0] m00_axi_awaddr;
    wire [7:0]            m00_axi_awlen;
    wire [2:0]            m00_axi_awsize;
    wire [1:0]            m00_axi_awburst;
    wire                  m00_axi_awlock;
    wire [3:0]            m00_axi_awcache;
    wire [2:0]            m00_axi_awprot;
    wire [3:0]            m00_axi_awqos;
    wire [3:0]            m00_axi_awregion;
    wire [0:0]            m00_axi_awuser;
    wire                  m00_axi_awvalid;
    wire                  m00_axi_awready;

    wire [DATA_WIDTH-1:0] m00_axi_wdata;
    wire [STRB_WIDTH-1:0] m00_axi_wstrb;
    wire                  m00_axi_wlast;
    wire [0:0]            m00_axi_wuser;
    wire                  m00_axi_wvalid;
    wire                  m00_axi_wready;

    wire [ID_WIDTH-1:0]   m00_axi_bid;
    wire [1:0]            m00_axi_bresp;
    wire [0:0]            m00_axi_buser;
    wire                  m00_axi_bvalid;
    wire                  m00_axi_bready;

    wire [ID_WIDTH-1:0]   m00_axi_arid;
    wire [ADDR_WIDTH-1:0] m00_axi_araddr;
    wire [7:0]            m00_axi_arlen;
    wire [2:0]            m00_axi_arsize;
    wire [1:0]            m00_axi_arburst;
    wire                  m00_axi_arlock;
    wire [3:0]            m00_axi_arcache;
    wire [2:0]            m00_axi_arprot;
    wire [3:0]            m00_axi_arqos;
    wire [3:0]            m00_axi_arregion;
    wire [0:0]            m00_axi_aruser;
    wire                  m00_axi_arvalid;
    wire                  m00_axi_arready;

    wire [ID_WIDTH-1:0]   m00_axi_rid;
    wire [DATA_WIDTH-1:0] m00_axi_rdata;
    wire [1:0]            m00_axi_rresp;
    wire                  m00_axi_rlast;
    wire [0:0]            m00_axi_ruser;
    wire                  m00_axi_rvalid;
    wire                  m00_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M01
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m01_axi_awid;
    wire [ADDR_WIDTH-1:0] m01_axi_awaddr;
    wire [7:0]            m01_axi_awlen;
    wire [2:0]            m01_axi_awsize;
    wire [1:0]            m01_axi_awburst;
    wire                  m01_axi_awlock;
    wire [3:0]            m01_axi_awcache;
    wire [2:0]            m01_axi_awprot;
    wire [3:0]            m01_axi_awqos;
    wire [3:0]            m01_axi_awregion;
    wire [0:0]            m01_axi_awuser;
    wire                  m01_axi_awvalid;
    wire                  m01_axi_awready;

    wire [DATA_WIDTH-1:0] m01_axi_wdata;
    wire [STRB_WIDTH-1:0] m01_axi_wstrb;
    wire                  m01_axi_wlast;
    wire [0:0]            m01_axi_wuser;
    wire                  m01_axi_wvalid;
    wire                  m01_axi_wready;

    wire [ID_WIDTH-1:0]   m01_axi_bid;
    wire [1:0]            m01_axi_bresp;
    wire [0:0]            m01_axi_buser;
    wire                  m01_axi_bvalid;
    wire                  m01_axi_bready;

    wire [ID_WIDTH-1:0]   m01_axi_arid;
    wire [ADDR_WIDTH-1:0] m01_axi_araddr;
    wire [7:0]            m01_axi_arlen;
    wire [2:0]            m01_axi_arsize;
    wire [1:0]            m01_axi_arburst;
    wire                  m01_axi_arlock;
    wire [3:0]            m01_axi_arcache;
    wire [2:0]            m01_axi_arprot;
    wire [3:0]            m01_axi_arqos;
    wire [3:0]            m01_axi_arregion;
    wire [0:0]            m01_axi_aruser;
    wire                  m01_axi_arvalid;
    wire                  m01_axi_arready;

    wire [ID_WIDTH-1:0]   m01_axi_rid;
    wire [DATA_WIDTH-1:0] m01_axi_rdata;
    wire [1:0]            m01_axi_rresp;
    wire                  m01_axi_rlast;
    wire [0:0]            m01_axi_ruser;
    wire                  m01_axi_rvalid;
    wire                  m01_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M02
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m02_axi_awid;
    wire [ADDR_WIDTH-1:0] m02_axi_awaddr;
    wire [7:0]            m02_axi_awlen;
    wire [2:0]            m02_axi_awsize;
    wire [1:0]            m02_axi_awburst;
    wire                  m02_axi_awlock;
    wire [3:0]            m02_axi_awcache;
    wire [2:0]            m02_axi_awprot;
    wire [3:0]            m02_axi_awqos;
    wire [3:0]            m02_axi_awregion;
    wire [0:0]            m02_axi_awuser;
    wire                  m02_axi_awvalid;
    wire                  m02_axi_awready;

    wire [DATA_WIDTH-1:0] m02_axi_wdata;
    wire [STRB_WIDTH-1:0] m02_axi_wstrb;
    wire                  m02_axi_wlast;
    wire [0:0]            m02_axi_wuser;
    wire                  m02_axi_wvalid;
    wire                  m02_axi_wready;

    wire [ID_WIDTH-1:0]   m02_axi_bid;
    wire [1:0]            m02_axi_bresp;
    wire [0:0]            m02_axi_buser;
    wire                  m02_axi_bvalid;
    wire                  m02_axi_bready;

    wire [ID_WIDTH-1:0]   m02_axi_arid;
    wire [ADDR_WIDTH-1:0] m02_axi_araddr;
    wire [7:0]            m02_axi_arlen;
    wire [2:0]            m02_axi_arsize;
    wire [1:0]            m02_axi_arburst;
    wire                  m02_axi_arlock;
    wire [3:0]            m02_axi_arcache;
    wire [2:0]            m02_axi_arprot;
    wire [3:0]            m02_axi_arqos;
    wire [3:0]            m02_axi_arregion;
    wire [0:0]            m02_axi_aruser;
    wire                  m02_axi_arvalid;
    wire                  m02_axi_arready;

    wire [ID_WIDTH-1:0]   m02_axi_rid;
    wire [DATA_WIDTH-1:0] m02_axi_rdata;
    wire [1:0]            m02_axi_rresp;
    wire                  m02_axi_rlast;
    wire [0:0]            m02_axi_ruser;
    wire                  m02_axi_rvalid;
    wire                  m02_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M03
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m03_axi_awid;
    wire [ADDR_WIDTH-1:0] m03_axi_awaddr;
    wire [7:0]            m03_axi_awlen;
    wire [2:0]            m03_axi_awsize;
    wire [1:0]            m03_axi_awburst;
    wire                  m03_axi_awlock;
    wire [3:0]            m03_axi_awcache;
    wire [2:0]            m03_axi_awprot;
    wire [3:0]            m03_axi_awqos;
    wire [3:0]            m03_axi_awregion;
    wire [0:0]            m03_axi_awuser;
    wire                  m03_axi_awvalid;
    wire                  m03_axi_awready;

    wire [DATA_WIDTH-1:0] m03_axi_wdata;
    wire [STRB_WIDTH-1:0] m03_axi_wstrb;
    wire                  m03_axi_wlast;
    wire [0:0]            m03_axi_wuser;
    wire                  m03_axi_wvalid;
    wire                  m03_axi_wready;

    wire [ID_WIDTH-1:0]   m03_axi_bid;
    wire [1:0]            m03_axi_bresp;
    wire [0:0]            m03_axi_buser;
    wire                  m03_axi_bvalid;
    wire                  m03_axi_bready;

    wire [ID_WIDTH-1:0]   m03_axi_arid;
    wire [ADDR_WIDTH-1:0] m03_axi_araddr;
    wire [7:0]            m03_axi_arlen;
    wire [2:0]            m03_axi_arsize;
    wire [1:0]            m03_axi_arburst;
    wire                  m03_axi_arlock;
    wire [3:0]            m03_axi_arcache;
    wire [2:0]            m03_axi_arprot;
    wire [3:0]            m03_axi_arqos;
    wire [3:0]            m03_axi_arregion;
    wire [0:0]            m03_axi_aruser;
    wire                  m03_axi_arvalid;
    wire                  m03_axi_arready;

    wire [ID_WIDTH-1:0]   m03_axi_rid;
    wire [DATA_WIDTH-1:0] m03_axi_rdata;
    wire [1:0]            m03_axi_rresp;
    wire                  m03_axi_rlast;
    wire [0:0]            m03_axi_ruser;
    wire                  m03_axi_rvalid;
    wire                  m03_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M04
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m04_axi_awid;
    wire [ADDR_WIDTH-1:0] m04_axi_awaddr;
    wire [7:0]            m04_axi_awlen;
    wire [2:0]            m04_axi_awsize;
    wire [1:0]            m04_axi_awburst;
    wire                  m04_axi_awlock;
    wire [3:0]            m04_axi_awcache;
    wire [2:0]            m04_axi_awprot;
    wire [3:0]            m04_axi_awqos;
    wire [3:0]            m04_axi_awregion;
    wire [0:0]            m04_axi_awuser;
    wire                  m04_axi_awvalid;
    wire                  m04_axi_awready;

    wire [DATA_WIDTH-1:0] m04_axi_wdata;
    wire [STRB_WIDTH-1:0] m04_axi_wstrb;
    wire                  m04_axi_wlast;
    wire [0:0]            m04_axi_wuser;
    wire                  m04_axi_wvalid;
    wire                  m04_axi_wready;

    wire [ID_WIDTH-1:0]   m04_axi_bid;
    wire [1:0]            m04_axi_bresp;
    wire [0:0]            m04_axi_buser;
    wire                  m04_axi_bvalid;
    wire                  m04_axi_bready;

    wire [ID_WIDTH-1:0]   m04_axi_arid;
    wire [ADDR_WIDTH-1:0] m04_axi_araddr;
    wire [7:0]            m04_axi_arlen;
    wire [2:0]            m04_axi_arsize;
    wire [1:0]            m04_axi_arburst;
    wire                  m04_axi_arlock;
    wire [3:0]            m04_axi_arcache;
    wire [2:0]            m04_axi_arprot;
    wire [3:0]            m04_axi_arqos;
    wire [3:0]            m04_axi_arregion;
    wire [0:0]            m04_axi_aruser;
    wire                  m04_axi_arvalid;
    wire                  m04_axi_arready;

    wire [ID_WIDTH-1:0]   m04_axi_rid;
    wire [DATA_WIDTH-1:0] m04_axi_rdata;
    wire [1:0]            m04_axi_rresp;
    wire                  m04_axi_rlast;
    wire [0:0]            m04_axi_ruser;
    wire                  m04_axi_rvalid;
    wire                  m04_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M05
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m05_axi_awid;
    wire [ADDR_WIDTH-1:0] m05_axi_awaddr;
    wire [7:0]            m05_axi_awlen;
    wire [2:0]            m05_axi_awsize;
    wire [1:0]            m05_axi_awburst;
    wire                  m05_axi_awlock;
    wire [3:0]            m05_axi_awcache;
    wire [2:0]            m05_axi_awprot;
    wire [3:0]            m05_axi_awqos;
    wire [3:0]            m05_axi_awregion;
    wire [0:0]            m05_axi_awuser;
    wire                  m05_axi_awvalid;
    wire                  m05_axi_awready;

    wire [DATA_WIDTH-1:0] m05_axi_wdata;
    wire [STRB_WIDTH-1:0] m05_axi_wstrb;
    wire                  m05_axi_wlast;
    wire [0:0]            m05_axi_wuser;
    wire                  m05_axi_wvalid;
    wire                  m05_axi_wready;

    wire [ID_WIDTH-1:0]   m05_axi_bid;
    wire [1:0]            m05_axi_bresp;
    wire [0:0]            m05_axi_buser;
    wire                  m05_axi_bvalid;
    wire                  m05_axi_bready;

    wire [ID_WIDTH-1:0]   m05_axi_arid;
    wire [ADDR_WIDTH-1:0] m05_axi_araddr;
    wire [7:0]            m05_axi_arlen;
    wire [2:0]            m05_axi_arsize;
    wire [1:0]            m05_axi_arburst;
    wire                  m05_axi_arlock;
    wire [3:0]            m05_axi_arcache;
    wire [2:0]            m05_axi_arprot;
    wire [3:0]            m05_axi_arqos;
    wire [3:0]            m05_axi_arregion;
    wire [0:0]            m05_axi_aruser;
    wire                  m05_axi_arvalid;
    wire                  m05_axi_arready;

    wire [ID_WIDTH-1:0]   m05_axi_rid;
    wire [DATA_WIDTH-1:0] m05_axi_rdata;
    wire [1:0]            m05_axi_rresp;
    wire                  m05_axi_rlast;
    wire [0:0]            m05_axi_ruser;
    wire                  m05_axi_rvalid;
    wire                  m05_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M06
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m06_axi_awid;
    wire [ADDR_WIDTH-1:0] m06_axi_awaddr;
    wire [7:0]            m06_axi_awlen;
    wire [2:0]            m06_axi_awsize;
    wire [1:0]            m06_axi_awburst;
    wire                  m06_axi_awlock;
    wire [3:0]            m06_axi_awcache;
    wire [2:0]            m06_axi_awprot;
    wire [3:0]            m06_axi_awqos;
    wire [3:0]            m06_axi_awregion;
    wire [0:0]            m06_axi_awuser;
    wire                  m06_axi_awvalid;
    wire                  m06_axi_awready;

    wire [DATA_WIDTH-1:0] m06_axi_wdata;
    wire [STRB_WIDTH-1:0] m06_axi_wstrb;
    wire                  m06_axi_wlast;
    wire [0:0]            m06_axi_wuser;
    wire                  m06_axi_wvalid;
    wire                  m06_axi_wready;

    wire [ID_WIDTH-1:0]   m06_axi_bid;
    wire [1:0]            m06_axi_bresp;
    wire [0:0]            m06_axi_buser;
    wire                  m06_axi_bvalid;
    wire                  m06_axi_bready;

    wire [ID_WIDTH-1:0]   m06_axi_arid;
    wire [ADDR_WIDTH-1:0] m06_axi_araddr;
    wire [7:0]            m06_axi_arlen;
    wire [2:0]            m06_axi_arsize;
    wire [1:0]            m06_axi_arburst;
    wire                  m06_axi_arlock;
    wire [3:0]            m06_axi_arcache;
    wire [2:0]            m06_axi_arprot;
    wire [3:0]            m06_axi_arqos;
    wire [3:0]            m06_axi_arregion;
    wire [0:0]            m06_axi_aruser;
    wire                  m06_axi_arvalid;
    wire                  m06_axi_arready;

    wire [ID_WIDTH-1:0]   m06_axi_rid;
    wire [DATA_WIDTH-1:0] m06_axi_rdata;
    wire [1:0]            m06_axi_rresp;
    wire                  m06_axi_rlast;
    wire [0:0]            m06_axi_ruser;
    wire                  m06_axi_rvalid;
    wire                  m06_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M07
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m07_axi_awid;
    wire [ADDR_WIDTH-1:0] m07_axi_awaddr;
    wire [7:0]            m07_axi_awlen;
    wire [2:0]            m07_axi_awsize;
    wire [1:0]            m07_axi_awburst;
    wire                  m07_axi_awlock;
    wire [3:0]            m07_axi_awcache;
    wire [2:0]            m07_axi_awprot;
    wire [3:0]            m07_axi_awqos;
    wire [3:0]            m07_axi_awregion;
    wire [0:0]            m07_axi_awuser;
    wire                  m07_axi_awvalid;
    wire                  m07_axi_awready;

    wire [DATA_WIDTH-1:0] m07_axi_wdata;
    wire [STRB_WIDTH-1:0] m07_axi_wstrb;
    wire                  m07_axi_wlast;
    wire [0:0]            m07_axi_wuser;
    wire                  m07_axi_wvalid;
    wire                  m07_axi_wready;

    wire [ID_WIDTH-1:0]   m07_axi_bid;
    wire [1:0]            m07_axi_bresp;
    wire [0:0]            m07_axi_buser;
    wire                  m07_axi_bvalid;
    wire                  m07_axi_bready;

    wire [ID_WIDTH-1:0]   m07_axi_arid;
    wire [ADDR_WIDTH-1:0] m07_axi_araddr;
    wire [7:0]            m07_axi_arlen;
    wire [2:0]            m07_axi_arsize;
    wire [1:0]            m07_axi_arburst;
    wire                  m07_axi_arlock;
    wire [3:0]            m07_axi_arcache;
    wire [2:0]            m07_axi_arprot;
    wire [3:0]            m07_axi_arqos;
    wire [3:0]            m07_axi_arregion;
    wire [0:0]            m07_axi_aruser;
    wire                  m07_axi_arvalid;
    wire                  m07_axi_arready;

    wire [ID_WIDTH-1:0]   m07_axi_rid;
    wire [DATA_WIDTH-1:0] m07_axi_rdata;
    wire [1:0]            m07_axi_rresp;
    wire                  m07_axi_rlast;
    wire [0:0]            m07_axi_ruser;
    wire                  m07_axi_rvalid;
    wire                  m07_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M08
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m08_axi_awid;
    wire [ADDR_WIDTH-1:0] m08_axi_awaddr;
    wire [7:0]            m08_axi_awlen;
    wire [2:0]            m08_axi_awsize;
    wire [1:0]            m08_axi_awburst;
    wire                  m08_axi_awlock;
    wire [3:0]            m08_axi_awcache;
    wire [2:0]            m08_axi_awprot;
    wire [3:0]            m08_axi_awqos;
    wire [3:0]            m08_axi_awregion;
    wire [0:0]            m08_axi_awuser;
    wire                  m08_axi_awvalid;
    wire                  m08_axi_awready;

    wire [DATA_WIDTH-1:0] m08_axi_wdata;
    wire [STRB_WIDTH-1:0] m08_axi_wstrb;
    wire                  m08_axi_wlast;
    wire [0:0]            m08_axi_wuser;
    wire                  m08_axi_wvalid;
    wire                  m08_axi_wready;

    wire [ID_WIDTH-1:0]   m08_axi_bid;
    wire [1:0]            m08_axi_bresp;
    wire [0:0]            m08_axi_buser;
    wire                  m08_axi_bvalid;
    wire                  m08_axi_bready;

    wire [ID_WIDTH-1:0]   m08_axi_arid;
    wire [ADDR_WIDTH-1:0] m08_axi_araddr;
    wire [7:0]            m08_axi_arlen;
    wire [2:0]            m08_axi_arsize;
    wire [1:0]            m08_axi_arburst;
    wire                  m08_axi_arlock;
    wire [3:0]            m08_axi_arcache;
    wire [2:0]            m08_axi_arprot;
    wire [3:0]            m08_axi_arqos;
    wire [3:0]            m08_axi_arregion;
    wire [0:0]            m08_axi_aruser;
    wire                  m08_axi_arvalid;
    wire                  m08_axi_arready;

    wire [ID_WIDTH-1:0]   m08_axi_rid;
    wire [DATA_WIDTH-1:0] m08_axi_rdata;
    wire [1:0]            m08_axi_rresp;
    wire                  m08_axi_rlast;
    wire [0:0]            m08_axi_ruser;
    wire                  m08_axi_rvalid;
    wire                  m08_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M09
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m09_axi_awid;
    wire [ADDR_WIDTH-1:0] m09_axi_awaddr;
    wire [7:0]            m09_axi_awlen;
    wire [2:0]            m09_axi_awsize;
    wire [1:0]            m09_axi_awburst;
    wire                  m09_axi_awlock;
    wire [3:0]            m09_axi_awcache;
    wire [2:0]            m09_axi_awprot;
    wire [3:0]            m09_axi_awqos;
    wire [3:0]            m09_axi_awregion;
    wire [0:0]            m09_axi_awuser;
    wire                  m09_axi_awvalid;
    wire                  m09_axi_awready;

    wire [DATA_WIDTH-1:0] m09_axi_wdata;
    wire [STRB_WIDTH-1:0] m09_axi_wstrb;
    wire                  m09_axi_wlast;
    wire [0:0]            m09_axi_wuser;
    wire                  m09_axi_wvalid;
    wire                  m09_axi_wready;

    wire [ID_WIDTH-1:0]   m09_axi_bid;
    wire [1:0]            m09_axi_bresp;
    wire [0:0]            m09_axi_buser;
    wire                  m09_axi_bvalid;
    wire                  m09_axi_bready;

    wire [ID_WIDTH-1:0]   m09_axi_arid;
    wire [ADDR_WIDTH-1:0] m09_axi_araddr;
    wire [7:0]            m09_axi_arlen;
    wire [2:0]            m09_axi_arsize;
    wire [1:0]            m09_axi_arburst;
    wire                  m09_axi_arlock;
    wire [3:0]            m09_axi_arcache;
    wire [2:0]            m09_axi_arprot;
    wire [3:0]            m09_axi_arqos;
    wire [3:0]            m09_axi_arregion;
    wire [0:0]            m09_axi_aruser;
    wire                  m09_axi_arvalid;
    wire                  m09_axi_arready;

    wire [ID_WIDTH-1:0]   m09_axi_rid;
    wire [DATA_WIDTH-1:0] m09_axi_rdata;
    wire [1:0]            m09_axi_rresp;
    wire                  m09_axi_rlast;
    wire [0:0]            m09_axi_ruser;
    wire                  m09_axi_rvalid;
    wire                  m09_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M10
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m10_axi_awid;
    wire [ADDR_WIDTH-1:0] m10_axi_awaddr;
    wire [7:0]            m10_axi_awlen;
    wire [2:0]            m10_axi_awsize;
    wire [1:0]            m10_axi_awburst;
    wire                  m10_axi_awlock;
    wire [3:0]            m10_axi_awcache;
    wire [2:0]            m10_axi_awprot;
    wire [3:0]            m10_axi_awqos;
    wire [3:0]            m10_axi_awregion;
    wire [0:0]            m10_axi_awuser;
    wire                  m10_axi_awvalid;
    wire                  m10_axi_awready;

    wire [DATA_WIDTH-1:0] m10_axi_wdata;
    wire [STRB_WIDTH-1:0] m10_axi_wstrb;
    wire                  m10_axi_wlast;
    wire [0:0]            m10_axi_wuser;
    wire                  m10_axi_wvalid;
    wire                  m10_axi_wready;

    wire [ID_WIDTH-1:0]   m10_axi_bid;
    wire [1:0]            m10_axi_bresp;
    wire [0:0]            m10_axi_buser;
    wire                  m10_axi_bvalid;
    wire                  m10_axi_bready;

    wire [ID_WIDTH-1:0]   m10_axi_arid;
    wire [ADDR_WIDTH-1:0] m10_axi_araddr;
    wire [7:0]            m10_axi_arlen;
    wire [2:0]            m10_axi_arsize;
    wire [1:0]            m10_axi_arburst;
    wire                  m10_axi_arlock;
    wire [3:0]            m10_axi_arcache;
    wire [2:0]            m10_axi_arprot;
    wire [3:0]            m10_axi_arqos;
    wire [3:0]            m10_axi_arregion;
    wire [0:0]            m10_axi_aruser;
    wire                  m10_axi_arvalid;
    wire                  m10_axi_arready;

    wire [ID_WIDTH-1:0]   m10_axi_rid;
    wire [DATA_WIDTH-1:0] m10_axi_rdata;
    wire [1:0]            m10_axi_rresp;
    wire                  m10_axi_rlast;
    wire [0:0]            m10_axi_ruser;
    wire                  m10_axi_rvalid;
    wire                  m10_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M11
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m11_axi_awid;
    wire [ADDR_WIDTH-1:0] m11_axi_awaddr;
    wire [7:0]            m11_axi_awlen;
    wire [2:0]            m11_axi_awsize;
    wire [1:0]            m11_axi_awburst;
    wire                  m11_axi_awlock;
    wire [3:0]            m11_axi_awcache;
    wire [2:0]            m11_axi_awprot;
    wire [3:0]            m11_axi_awqos;
    wire [3:0]            m11_axi_awregion;
    wire [0:0]            m11_axi_awuser;
    wire                  m11_axi_awvalid;
    wire                  m11_axi_awready;

    wire [DATA_WIDTH-1:0] m11_axi_wdata;
    wire [STRB_WIDTH-1:0] m11_axi_wstrb;
    wire                  m11_axi_wlast;
    wire [0:0]            m11_axi_wuser;
    wire                  m11_axi_wvalid;
    wire                  m11_axi_wready;

    wire [ID_WIDTH-1:0]   m11_axi_bid;
    wire [1:0]            m11_axi_bresp;
    wire [0:0]            m11_axi_buser;
    wire                  m11_axi_bvalid;
    wire                  m11_axi_bready;

    wire [ID_WIDTH-1:0]   m11_axi_arid;
    wire [ADDR_WIDTH-1:0] m11_axi_araddr;
    wire [7:0]            m11_axi_arlen;
    wire [2:0]            m11_axi_arsize;
    wire [1:0]            m11_axi_arburst;
    wire                  m11_axi_arlock;
    wire [3:0]            m11_axi_arcache;
    wire [2:0]            m11_axi_arprot;
    wire [3:0]            m11_axi_arqos;
    wire [3:0]            m11_axi_arregion;
    wire [0:0]            m11_axi_aruser;
    wire                  m11_axi_arvalid;
    wire                  m11_axi_arready;

    wire [ID_WIDTH-1:0]   m11_axi_rid;
    wire [DATA_WIDTH-1:0] m11_axi_rdata;
    wire [1:0]            m11_axi_rresp;
    wire                  m11_axi_rlast;
    wire [0:0]            m11_axi_ruser;
    wire                  m11_axi_rvalid;
    wire                  m11_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M12
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m12_axi_awid;
    wire [ADDR_WIDTH-1:0] m12_axi_awaddr;
    wire [7:0]            m12_axi_awlen;
    wire [2:0]            m12_axi_awsize;
    wire [1:0]            m12_axi_awburst;
    wire                  m12_axi_awlock;
    wire [3:0]            m12_axi_awcache;
    wire [2:0]            m12_axi_awprot;
    wire [3:0]            m12_axi_awqos;
    wire [3:0]            m12_axi_awregion;
    wire [0:0]            m12_axi_awuser;
    wire                  m12_axi_awvalid;
    wire                  m12_axi_awready;

    wire [DATA_WIDTH-1:0] m12_axi_wdata;
    wire [STRB_WIDTH-1:0] m12_axi_wstrb;
    wire                  m12_axi_wlast;
    wire [0:0]            m12_axi_wuser;
    wire                  m12_axi_wvalid;
    wire                  m12_axi_wready;

    wire [ID_WIDTH-1:0]   m12_axi_bid;
    wire [1:0]            m12_axi_bresp;
    wire [0:0]            m12_axi_buser;
    wire                  m12_axi_bvalid;
    wire                  m12_axi_bready;

    wire [ID_WIDTH-1:0]   m12_axi_arid;
    wire [ADDR_WIDTH-1:0] m12_axi_araddr;
    wire [7:0]            m12_axi_arlen;
    wire [2:0]            m12_axi_arsize;
    wire [1:0]            m12_axi_arburst;
    wire                  m12_axi_arlock;
    wire [3:0]            m12_axi_arcache;
    wire [2:0]            m12_axi_arprot;
    wire [3:0]            m12_axi_arqos;
    wire [3:0]            m12_axi_arregion;
    wire [0:0]            m12_axi_aruser;
    wire                  m12_axi_arvalid;
    wire                  m12_axi_arready;

    wire [ID_WIDTH-1:0]   m12_axi_rid;
    wire [DATA_WIDTH-1:0] m12_axi_rdata;
    wire [1:0]            m12_axi_rresp;
    wire                  m12_axi_rlast;
    wire [0:0]            m12_axi_ruser;
    wire                  m12_axi_rvalid;
    wire                  m12_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M13
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m13_axi_awid;
    wire [ADDR_WIDTH-1:0] m13_axi_awaddr;
    wire [7:0]            m13_axi_awlen;
    wire [2:0]            m13_axi_awsize;
    wire [1:0]            m13_axi_awburst;
    wire                  m13_axi_awlock;
    wire [3:0]            m13_axi_awcache;
    wire [2:0]            m13_axi_awprot;
    wire [3:0]            m13_axi_awqos;
    wire [3:0]            m13_axi_awregion;
    wire [0:0]            m13_axi_awuser;
    wire                  m13_axi_awvalid;
    wire                  m13_axi_awready;

    wire [DATA_WIDTH-1:0] m13_axi_wdata;
    wire [STRB_WIDTH-1:0] m13_axi_wstrb;
    wire                  m13_axi_wlast;
    wire [0:0]            m13_axi_wuser;
    wire                  m13_axi_wvalid;
    wire                  m13_axi_wready;

    wire [ID_WIDTH-1:0]   m13_axi_bid;
    wire [1:0]            m13_axi_bresp;
    wire [0:0]            m13_axi_buser;
    wire                  m13_axi_bvalid;
    wire                  m13_axi_bready;

    wire [ID_WIDTH-1:0]   m13_axi_arid;
    wire [ADDR_WIDTH-1:0] m13_axi_araddr;
    wire [7:0]            m13_axi_arlen;
    wire [2:0]            m13_axi_arsize;
    wire [1:0]            m13_axi_arburst;
    wire                  m13_axi_arlock;
    wire [3:0]            m13_axi_arcache;
    wire [2:0]            m13_axi_arprot;
    wire [3:0]            m13_axi_arqos;
    wire [3:0]            m13_axi_arregion;
    wire [0:0]            m13_axi_aruser;
    wire                  m13_axi_arvalid;
    wire                  m13_axi_arready;

    wire [ID_WIDTH-1:0]   m13_axi_rid;
    wire [DATA_WIDTH-1:0] m13_axi_rdata;
    wire [1:0]            m13_axi_rresp;
    wire                  m13_axi_rlast;
    wire [0:0]            m13_axi_ruser;
    wire                  m13_axi_rvalid;
    wire                  m13_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M14
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m14_axi_awid;
    wire [ADDR_WIDTH-1:0] m14_axi_awaddr;
    wire [7:0]            m14_axi_awlen;
    wire [2:0]            m14_axi_awsize;
    wire [1:0]            m14_axi_awburst;
    wire                  m14_axi_awlock;
    wire [3:0]            m14_axi_awcache;
    wire [2:0]            m14_axi_awprot;
    wire [3:0]            m14_axi_awqos;
    wire [3:0]            m14_axi_awregion;
    wire [0:0]            m14_axi_awuser;
    wire                  m14_axi_awvalid;
    wire                  m14_axi_awready;

    wire [DATA_WIDTH-1:0] m14_axi_wdata;
    wire [STRB_WIDTH-1:0] m14_axi_wstrb;
    wire                  m14_axi_wlast;
    wire [0:0]            m14_axi_wuser;
    wire                  m14_axi_wvalid;
    wire                  m14_axi_wready;

    wire [ID_WIDTH-1:0]   m14_axi_bid;
    wire [1:0]            m14_axi_bresp;
    wire [0:0]            m14_axi_buser;
    wire                  m14_axi_bvalid;
    wire                  m14_axi_bready;

    wire [ID_WIDTH-1:0]   m14_axi_arid;
    wire [ADDR_WIDTH-1:0] m14_axi_araddr;
    wire [7:0]            m14_axi_arlen;
    wire [2:0]            m14_axi_arsize;
    wire [1:0]            m14_axi_arburst;
    wire                  m14_axi_arlock;
    wire [3:0]            m14_axi_arcache;
    wire [2:0]            m14_axi_arprot;
    wire [3:0]            m14_axi_arqos;
    wire [3:0]            m14_axi_arregion;
    wire [0:0]            m14_axi_aruser;
    wire                  m14_axi_arvalid;
    wire                  m14_axi_arready;

    wire [ID_WIDTH-1:0]   m14_axi_rid;
    wire [DATA_WIDTH-1:0] m14_axi_rdata;
    wire [1:0]            m14_axi_rresp;
    wire                  m14_axi_rlast;
    wire [0:0]            m14_axi_ruser;
    wire                  m14_axi_rvalid;
    wire                  m14_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M15
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m15_axi_awid;
    wire [ADDR_WIDTH-1:0] m15_axi_awaddr;
    wire [7:0]            m15_axi_awlen;
    wire [2:0]            m15_axi_awsize;
    wire [1:0]            m15_axi_awburst;
    wire                  m15_axi_awlock;
    wire [3:0]            m15_axi_awcache;
    wire [2:0]            m15_axi_awprot;
    wire [3:0]            m15_axi_awqos;
    wire [3:0]            m15_axi_awregion;
    wire [0:0]            m15_axi_awuser;
    wire                  m15_axi_awvalid;
    wire                  m15_axi_awready;

    wire [DATA_WIDTH-1:0] m15_axi_wdata;
    wire [STRB_WIDTH-1:0] m15_axi_wstrb;
    wire                  m15_axi_wlast;
    wire [0:0]            m15_axi_wuser;
    wire                  m15_axi_wvalid;
    wire                  m15_axi_wready;

    wire [ID_WIDTH-1:0]   m15_axi_bid;
    wire [1:0]            m15_axi_bresp;
    wire [0:0]            m15_axi_buser;
    wire                  m15_axi_bvalid;
    wire                  m15_axi_bready;

    wire [ID_WIDTH-1:0]   m15_axi_arid;
    wire [ADDR_WIDTH-1:0] m15_axi_araddr;
    wire [7:0]            m15_axi_arlen;
    wire [2:0]            m15_axi_arsize;
    wire [1:0]            m15_axi_arburst;
    wire                  m15_axi_arlock;
    wire [3:0]            m15_axi_arcache;
    wire [2:0]            m15_axi_arprot;
    wire [3:0]            m15_axi_arqos;
    wire [3:0]            m15_axi_arregion;
    wire [0:0]            m15_axi_aruser;
    wire                  m15_axi_arvalid;
    wire                  m15_axi_arready;

    wire [ID_WIDTH-1:0]   m15_axi_rid;
    wire [DATA_WIDTH-1:0] m15_axi_rdata;
    wire [1:0]            m15_axi_rresp;
    wire                  m15_axi_rlast;
    wire [0:0]            m15_axi_ruser;
    wire                  m15_axi_rvalid;
    wire                  m15_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M16
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m16_axi_awid;
    wire [ADDR_WIDTH-1:0] m16_axi_awaddr;
    wire [7:0]            m16_axi_awlen;
    wire [2:0]            m16_axi_awsize;
    wire [1:0]            m16_axi_awburst;
    wire                  m16_axi_awlock;
    wire [3:0]            m16_axi_awcache;
    wire [2:0]            m16_axi_awprot;
    wire [3:0]            m16_axi_awqos;
    wire [3:0]            m16_axi_awregion;
    wire [0:0]            m16_axi_awuser;
    wire                  m16_axi_awvalid;
    wire                  m16_axi_awready;

    wire [DATA_WIDTH-1:0] m16_axi_wdata;
    wire [STRB_WIDTH-1:0] m16_axi_wstrb;
    wire                  m16_axi_wlast;
    wire [0:0]            m16_axi_wuser;
    wire                  m16_axi_wvalid;
    wire                  m16_axi_wready;

    wire [ID_WIDTH-1:0]   m16_axi_bid;
    wire [1:0]            m16_axi_bresp;
    wire [0:0]            m16_axi_buser;
    wire                  m16_axi_bvalid;
    wire                  m16_axi_bready;

    wire [ID_WIDTH-1:0]   m16_axi_arid;
    wire [ADDR_WIDTH-1:0] m16_axi_araddr;
    wire [7:0]            m16_axi_arlen;
    wire [2:0]            m16_axi_arsize;
    wire [1:0]            m16_axi_arburst;
    wire                  m16_axi_arlock;
    wire [3:0]            m16_axi_arcache;
    wire [2:0]            m16_axi_arprot;
    wire [3:0]            m16_axi_arqos;
    wire [3:0]            m16_axi_arregion;
    wire [0:0]            m16_axi_aruser;
    wire                  m16_axi_arvalid;
    wire                  m16_axi_arready;

    wire [ID_WIDTH-1:0]   m16_axi_rid;
    wire [DATA_WIDTH-1:0] m16_axi_rdata;
    wire [1:0]            m16_axi_rresp;
    wire                  m16_axi_rlast;
    wire [0:0]            m16_axi_ruser;
    wire                  m16_axi_rvalid;
    wire                  m16_axi_rready;

    /* ------------------------------------------------------------
     * Interconnect Master Port M17
     * ------------------------------------------------------------ */
    wire [ID_WIDTH-1:0]   m17_axi_awid;
    wire [ADDR_WIDTH-1:0] m17_axi_awaddr;
    wire [7:0]            m17_axi_awlen;
    wire [2:0]            m17_axi_awsize;
    wire [1:0]            m17_axi_awburst;
    wire                  m17_axi_awlock;
    wire [3:0]            m17_axi_awcache;
    wire [2:0]            m17_axi_awprot;
    wire [3:0]            m17_axi_awqos;
    wire [3:0]            m17_axi_awregion;
    wire [0:0]            m17_axi_awuser;
    wire                  m17_axi_awvalid;
    wire                  m17_axi_awready;

    wire [DATA_WIDTH-1:0] m17_axi_wdata;
    wire [STRB_WIDTH-1:0] m17_axi_wstrb;
    wire                  m17_axi_wlast;
    wire [0:0]            m17_axi_wuser;
    wire                  m17_axi_wvalid;
    wire                  m17_axi_wready;

    wire [ID_WIDTH-1:0]   m17_axi_bid;
    wire [1:0]            m17_axi_bresp;
    wire [0:0]            m17_axi_buser;
    wire                  m17_axi_bvalid;
    wire                  m17_axi_bready;

    wire [ID_WIDTH-1:0]   m17_axi_arid;
    wire [ADDR_WIDTH-1:0] m17_axi_araddr;
    wire [7:0]            m17_axi_arlen;
    wire [2:0]            m17_axi_arsize;
    wire [1:0]            m17_axi_arburst;
    wire                  m17_axi_arlock;
    wire [3:0]            m17_axi_arcache;
    wire [2:0]            m17_axi_arprot;
    wire [3:0]            m17_axi_arqos;
    wire [3:0]            m17_axi_arregion;
    wire [0:0]            m17_axi_aruser;
    wire                  m17_axi_arvalid;
    wire                  m17_axi_arready;

    wire [ID_WIDTH-1:0]   m17_axi_rid;
    wire [DATA_WIDTH-1:0] m17_axi_rdata;
    wire [1:0]            m17_axi_rresp;
    wire                  m17_axi_rlast;
    wire [0:0]            m17_axi_ruser;
    wire                  m17_axi_rvalid;
    wire                  m17_axi_rready;

    /* ============================================================
     * Inactive Interconnect Slave Response Wires (S01, S02)
     * Prevents unconnected port lint warnings.
     * ============================================================ */
    wire                  s01_axi_awready_unconn;
    wire                  s01_axi_wready_unconn;
    wire [ID_WIDTH-1:0]   s01_axi_bid_unconn;
    wire [1:0]            s01_axi_bresp_unconn;
    wire [0:0]            s01_axi_buser_unconn;
    wire                  s01_axi_bvalid_unconn;
    wire                  s01_axi_arready_unconn;
    wire [ID_WIDTH-1:0]   s01_axi_rid_unconn;
    wire [DATA_WIDTH-1:0] s01_axi_rdata_unconn;
    wire [1:0]            s01_axi_rresp_unconn;
    wire                  s01_axi_rlast_unconn;
    wire [0:0]            s01_axi_ruser_unconn;
    wire                  s01_axi_rvalid_unconn;

    wire                  s02_axi_awready_unconn;
    wire                  s02_axi_wready_unconn;
    wire [ID_WIDTH-1:0]   s02_axi_bid_unconn;
    wire [1:0]            s02_axi_bresp_unconn;
    wire [0:0]            s02_axi_buser_unconn;
    wire                  s02_axi_bvalid_unconn;
    wire                  s02_axi_arready_unconn;
    wire [ID_WIDTH-1:0]   s02_axi_rid_unconn;
    wire [DATA_WIDTH-1:0] s02_axi_rdata_unconn;
    wire [1:0]            s02_axi_rresp_unconn;
    wire                  s02_axi_rlast_unconn;
    wire [0:0]            s02_axi_ruser_unconn;
    wire                  s02_axi_rvalid_unconn;

    /* ============================================================
     * SHARED GROUP 3x18 AXI INTERCONNECT WRAPPER INSTANCE
     * ============================================================ */
    axi_interconnect_wrap_3x18 #(
        .DATA_WIDTH        (DATA_WIDTH),
        .ADDR_WIDTH        (ADDR_WIDTH),
        .STRB_WIDTH        (STRB_WIDTH),
        .ID_WIDTH          (ID_WIDTH),

        .AWUSER_WIDTH      (1),
        .WUSER_WIDTH       (1),
        .BUSER_WIDTH       (1),
        .ARUSER_WIDTH      (1),
        .RUSER_WIDTH       (1),

        .M_REGIONS         (1),

        /* M00: UART */
        .M00_BASE_ADDR     (32'h4000_0000),
        .M00_ADDR_WIDTH    (32'd12),
        .M00_CONNECT_READ  (3'b001),
        .M00_CONNECT_WRITE (3'b001),

        /* M01: GPIO */
        .M01_BASE_ADDR     (32'h4000_2000),
        .M01_ADDR_WIDTH    (32'd12),
        .M01_CONNECT_READ  (3'b001),
        .M01_CONNECT_WRITE (3'b001),

        /* M02: TIMER */
        .M02_BASE_ADDR     (32'h4000_4000),
        .M02_ADDR_WIDTH    (32'd12),
        .M02_CONNECT_READ  (3'b001),
        .M02_CONNECT_WRITE (3'b001),

        /* M03: FIR */
        .M03_BASE_ADDR     (32'h4000_C000),
        .M03_ADDR_WIDTH    (32'd12),
        .M03_CONNECT_READ  (3'b001),
        .M03_CONNECT_WRITE (3'b001),

        /* M04: ADC */
        .M04_BASE_ADDR     (32'h4000_E000),
        .M04_ADDR_WIDTH    (32'd12),
        .M04_CONNECT_READ  (3'b001),
        .M04_CONNECT_WRITE (3'b001),

        /* M05: SPI */
        .M05_BASE_ADDR     (32'h4001_0000),
        .M05_ADDR_WIDTH    (32'd12),
        .M05_CONNECT_READ  (3'b001),
        .M05_CONNECT_WRITE (3'b001),

        /* M06: QRS */
        .M06_BASE_ADDR     (32'h4001_2000),
        .M06_ADDR_WIDTH    (32'd12),
        .M06_CONNECT_READ  (3'b001),
        .M06_CONNECT_WRITE (3'b001),

        /* M07: WATCHDOG (Dummy) */
        .M07_BASE_ADDR     (32'h4000_6000),
        .M07_ADDR_WIDTH    (32'd12),
        .M07_CONNECT_READ  (3'b001),
        .M07_CONNECT_WRITE (3'b001),

        /* M08: FFT CONTROL (Dummy) */
        .M08_BASE_ADDR     (32'h4000_8000),
        .M08_ADDR_WIDTH    (32'd12),
        .M08_CONNECT_READ  (3'b001),
        .M08_CONNECT_WRITE (3'b001),

        /* M09: FFT MEMORY (Dummy) */
        .M09_BASE_ADDR     (32'h4000_A000),
        .M09_ADDR_WIDTH    (32'd12),
        .M09_CONNECT_READ  (3'b001),
        .M09_CONNECT_WRITE (3'b001),

        /* M10: AES (Dummy) */
        .M10_BASE_ADDR     (32'h4001_4000),
        .M10_ADDR_WIDTH    (32'd12),
        .M10_CONNECT_READ  (3'b001),
        .M10_CONNECT_WRITE (3'b001),

        /* M11: INTERRUPT AGGREGATOR (Dummy) */
        .M11_BASE_ADDR     (32'h4001_6000),
        .M11_ADDR_WIDTH    (32'd12),
        .M11_CONNECT_READ  (3'b001),
        .M11_CONNECT_WRITE (3'b001),

        /* M12: PWM (Dummy) */
        .M12_BASE_ADDR     (32'h4001_8000),
        .M12_ADDR_WIDTH    (32'd12),
        .M12_CONNECT_READ  (3'b001),
        .M12_CONNECT_WRITE (3'b001),

        /* M13: I2C (Dummy) */
        .M13_BASE_ADDR     (32'h4001_A000),
        .M13_ADDR_WIDTH    (32'd12),
        .M13_CONNECT_READ  (3'b001),
        .M13_CONNECT_WRITE (3'b001),

        /* M14: DMA REG (Dummy) */
        .M14_BASE_ADDR     (32'h4001_C000),
        .M14_ADDR_WIDTH    (32'd12),
        .M14_CONNECT_READ  (3'b001),
        .M14_CONNECT_WRITE (3'b001),

        /* M15: RESERVED (Dummy) */
        .M15_BASE_ADDR     (32'h4001_E000),
        .M15_ADDR_WIDTH    (32'd12),
        .M15_CONNECT_READ  (3'b001),
        .M15_CONNECT_WRITE (3'b001),

        /* M16: RESERVED (Dummy) */
        .M16_BASE_ADDR     (32'h4002_0000),
        .M16_ADDR_WIDTH    (32'd12),
        .M16_CONNECT_READ  (3'b001),
        .M16_CONNECT_WRITE (3'b001),

        /* M17: RESERVED (Dummy) */
        .M17_BASE_ADDR     (32'h4002_2000),
        .M17_ADDR_WIDTH    (32'd12),
        .M17_CONNECT_READ  (3'b001),
        .M17_CONNECT_WRITE (3'b001)
    ) u_interconnect (
        .clk              (clk),
        .rst              (rst),

        /* ========================================================
         * S00 ACTIVE (SoC Master Interface)
         * ======================================================== */
        .s00_axi_awid     (s00_axi_awid),
        .s00_axi_awaddr   (s00_axi_awaddr),
        .s00_axi_awlen    (s00_axi_awlen),
        .s00_axi_awsize   (s00_axi_awsize),
        .s00_axi_awburst  (s00_axi_awburst),
        .s00_axi_awlock   (s00_axi_awlock),
        .s00_axi_awcache  (s00_axi_awcache),
        .s00_axi_awprot   (s00_axi_awprot),
        .s00_axi_awqos    (s00_axi_awqos),
        .s00_axi_awuser   (s00_axi_awuser),
        .s00_axi_awvalid  (s00_axi_awvalid),
        .s00_axi_awready  (s00_axi_awready),

        .s00_axi_wdata    (s00_axi_wdata),
        .s00_axi_wstrb    (s00_axi_wstrb),
        .s00_axi_wlast    (s00_axi_wlast),
        .s00_axi_wuser    (s00_axi_wuser),
        .s00_axi_wvalid   (s00_axi_wvalid),
        .s00_axi_wready   (s00_axi_wready),

        .s00_axi_bid      (s00_axi_bid),
        .s00_axi_bresp    (s00_axi_bresp),
        .s00_axi_buser    (s00_axi_buser),
        .s00_axi_bvalid   (s00_axi_bvalid),
        .s00_axi_bready   (s00_axi_bready),

        .s00_axi_arid     (s00_axi_arid),
        .s00_axi_araddr   (s00_axi_araddr),
        .s00_axi_arlen    (s00_axi_arlen),
        .s00_axi_arsize   (s00_axi_arsize),
        .s00_axi_arburst  (s00_axi_arburst),
        .s00_axi_arlock   (s00_axi_arlock),
        .s00_axi_arcache  (s00_axi_arcache),
        .s00_axi_arprot   (s00_axi_arprot),
        .s00_axi_arqos    (s00_axi_arqos),
        .s00_axi_aruser   (s00_axi_aruser),
        .s00_axi_arvalid  (s00_axi_arvalid),
        .s00_axi_arready  (s00_axi_arready),

        .s00_axi_rid      (s00_axi_rid),
        .s00_axi_rdata    (s00_axi_rdata),
        .s00_axi_rresp    (s00_axi_rresp),
        .s00_axi_rlast    (s00_axi_rlast),
        .s00_axi_ruser    (s00_axi_ruser),
        .s00_axi_rvalid   (s00_axi_rvalid),
        .s00_axi_rready   (s00_axi_rready),

        /* ========================================================
         * S01 INACTIVE (Tied Off Safely)
         * ======================================================== */
        .s01_axi_awid     (8'd0),
        .s01_axi_awaddr   (32'd0),
        .s01_axi_awlen    (8'd0),
        .s01_axi_awsize   (3'd0),
        .s01_axi_awburst  (2'd0),
        .s01_axi_awlock   (1'b0),
        .s01_axi_awcache  (4'd0),
        .s01_axi_awprot   (3'd0),
        .s01_axi_awqos    (4'd0),
        .s01_axi_awuser   (1'b0),
        .s01_axi_awvalid  (1'b0),
        .s01_axi_awready  (s01_axi_awready_unconn),

        .s01_axi_wdata    (32'd0),
        .s01_axi_wstrb    (4'd0),
        .s01_axi_wlast    (1'b0),
        .s01_axi_wuser    (1'b0),
        .s01_axi_wvalid   (1'b0),
        .s01_axi_wready   (s01_axi_wready_unconn),

        .s01_axi_bid      (s01_axi_bid_unconn),
        .s01_axi_bresp    (s01_axi_bresp_unconn),
        .s01_axi_buser    (s01_axi_buser_unconn),
        .s01_axi_bvalid   (s01_axi_bvalid_unconn),
        .s01_axi_bready   (1'b0),

        .s01_axi_arid     (8'd0),
        .s01_axi_araddr   (32'd0),
        .s01_axi_arlen    (8'd0),
        .s01_axi_arsize   (3'd0),
        .s01_axi_arburst  (2'd0),
        .s01_axi_arlock   (1'b0),
        .s01_axi_arcache  (4'd0),
        .s01_axi_arprot   (3'd0),
        .s01_axi_arqos    (4'd0),
        .s01_axi_aruser   (1'b0),
        .s01_axi_arvalid  (1'b0),
        .s01_axi_arready  (s01_axi_arready_unconn),

        .s01_axi_rid      (s01_axi_rid_unconn),
        .s01_axi_rdata    (s01_axi_rdata_unconn),
        .s01_axi_rresp    (s01_axi_rresp_unconn),
        .s01_axi_rlast    (s01_axi_rlast_unconn),
        .s01_axi_ruser    (s01_axi_ruser_unconn),
        .s01_axi_rvalid   (s01_axi_rvalid_unconn),
        .s01_axi_rready   (1'b0),

        /* ========================================================
         * S02 INACTIVE (Tied Off Safely)
         * ======================================================== */
        .s02_axi_awid     (8'd0),
        .s02_axi_awaddr   (32'd0),
        .s02_axi_awlen    (8'd0),
        .s02_axi_awsize   (3'd0),
        .s02_axi_awburst  (2'd0),
        .s02_axi_awlock   (1'b0),
        .s02_axi_awcache  (4'd0),
        .s02_axi_awprot   (3'd0),
        .s02_axi_awqos    (4'd0),
        .s02_axi_awuser   (1'b0),
        .s02_axi_awvalid  (1'b0),
        .s02_axi_awready  (s02_axi_awready_unconn),

        .s02_axi_wdata    (32'd0),
        .s02_axi_wstrb    (4'd0),
        .s02_axi_wlast    (1'b0),
        .s02_axi_wuser    (1'b0),
        .s02_axi_wvalid   (1'b0),
        .s02_axi_wready   (s02_axi_wready_unconn),

        .s02_axi_bid      (s02_axi_bid_unconn),
        .s02_axi_bresp    (s02_axi_bresp_unconn),
        .s02_axi_buser    (s02_axi_buser_unconn),
        .s02_axi_bvalid   (s02_axi_bvalid_unconn),
        .s02_axi_bready   (1'b0),

        .s02_axi_arid     (8'd0),
        .s02_axi_araddr   (32'd0),
        .s02_axi_arlen    (8'd0),
        .s02_axi_arsize   (3'd0),
        .s02_axi_arburst  (2'd0),
        .s02_axi_arlock   (1'b0),
        .s02_axi_arcache  (4'd0),
        .s02_axi_arprot   (3'd0),
        .s02_axi_arqos    (4'd0),
        .s02_axi_aruser   (1'b0),
        .s02_axi_arvalid  (1'b0),
        .s02_axi_arready  (s02_axi_arready_unconn),

        .s02_axi_rid      (s02_axi_rid_unconn),
        .s02_axi_rdata    (s02_axi_rdata_unconn),
        .s02_axi_rresp    (s02_axi_rresp_unconn),
        .s02_axi_rlast    (s02_axi_rlast_unconn),
        .s02_axi_ruser    (s02_axi_ruser_unconn),
        .s02_axi_rvalid   (s02_axi_rvalid_unconn),
        .s02_axi_rready   (1'b0),

        /* Master Port M00 */
        .m00_axi_awid     (m00_axi_awid),
        .m00_axi_awaddr   (m00_axi_awaddr),
        .m00_axi_awlen    (m00_axi_awlen),
        .m00_axi_awsize   (m00_axi_awsize),
        .m00_axi_awburst  (m00_axi_awburst),
        .m00_axi_awlock   (m00_axi_awlock),
        .m00_axi_awcache  (m00_axi_awcache),
        .m00_axi_awprot   (m00_axi_awprot),
        .m00_axi_awqos    (m00_axi_awqos),
        .m00_axi_awregion (m00_axi_awregion),
        .m00_axi_awuser   (m00_axi_awuser),
        .m00_axi_awvalid  (m00_axi_awvalid),
        .m00_axi_awready  (m00_axi_awready),

        .m00_axi_wdata    (m00_axi_wdata),
        .m00_axi_wstrb    (m00_axi_wstrb),
        .m00_axi_wlast    (m00_axi_wlast),
        .m00_axi_wuser    (m00_axi_wuser),
        .m00_axi_wvalid   (m00_axi_wvalid),
        .m00_axi_wready   (m00_axi_wready),

        .m00_axi_bid      (m00_axi_bid),
        .m00_axi_bresp    (m00_axi_bresp),
        .m00_axi_buser    (m00_axi_buser),
        .m00_axi_bvalid   (m00_axi_bvalid),
        .m00_axi_bready   (m00_axi_bready),

        .m00_axi_arid     (m00_axi_arid),
        .m00_axi_araddr   (m00_axi_araddr),
        .m00_axi_arlen    (m00_axi_arlen),
        .m00_axi_arsize   (m00_axi_arsize),
        .m00_axi_arburst  (m00_axi_arburst),
        .m00_axi_arlock   (m00_axi_arlock),
        .m00_axi_arcache  (m00_axi_arcache),
        .m00_axi_arprot   (m00_axi_arprot),
        .m00_axi_arqos    (m00_axi_arqos),
        .m00_axi_arregion (m00_axi_arregion),
        .m00_axi_aruser   (m00_axi_aruser),
        .m00_axi_arvalid  (m00_axi_arvalid),
        .m00_axi_arready  (m00_axi_arready),

        .m00_axi_rid      (m00_axi_rid),
        .m00_axi_rdata    (m00_axi_rdata),
        .m00_axi_rresp    (m00_axi_rresp),
        .m00_axi_rlast    (m00_axi_rlast),
        .m00_axi_ruser    (m00_axi_ruser),
        .m00_axi_rvalid   (m00_axi_rvalid),
        .m00_axi_rready   (m00_axi_rready),
        /* Master Port M01 */
        .m01_axi_awid     (m01_axi_awid),
        .m01_axi_awaddr   (m01_axi_awaddr),
        .m01_axi_awlen    (m01_axi_awlen),
        .m01_axi_awsize   (m01_axi_awsize),
        .m01_axi_awburst  (m01_axi_awburst),
        .m01_axi_awlock   (m01_axi_awlock),
        .m01_axi_awcache  (m01_axi_awcache),
        .m01_axi_awprot   (m01_axi_awprot),
        .m01_axi_awqos    (m01_axi_awqos),
        .m01_axi_awregion (m01_axi_awregion),
        .m01_axi_awuser   (m01_axi_awuser),
        .m01_axi_awvalid  (m01_axi_awvalid),
        .m01_axi_awready  (m01_axi_awready),

        .m01_axi_wdata    (m01_axi_wdata),
        .m01_axi_wstrb    (m01_axi_wstrb),
        .m01_axi_wlast    (m01_axi_wlast),
        .m01_axi_wuser    (m01_axi_wuser),
        .m01_axi_wvalid   (m01_axi_wvalid),
        .m01_axi_wready   (m01_axi_wready),

        .m01_axi_bid      (m01_axi_bid),
        .m01_axi_bresp    (m01_axi_bresp),
        .m01_axi_buser    (m01_axi_buser),
        .m01_axi_bvalid   (m01_axi_bvalid),
        .m01_axi_bready   (m01_axi_bready),

        .m01_axi_arid     (m01_axi_arid),
        .m01_axi_araddr   (m01_axi_araddr),
        .m01_axi_arlen    (m01_axi_arlen),
        .m01_axi_arsize   (m01_axi_arsize),
        .m01_axi_arburst  (m01_axi_arburst),
        .m01_axi_arlock   (m01_axi_arlock),
        .m01_axi_arcache  (m01_axi_arcache),
        .m01_axi_arprot   (m01_axi_arprot),
        .m01_axi_arqos    (m01_axi_arqos),
        .m01_axi_arregion (m01_axi_arregion),
        .m01_axi_aruser   (m01_axi_aruser),
        .m01_axi_arvalid  (m01_axi_arvalid),
        .m01_axi_arready  (m01_axi_arready),

        .m01_axi_rid      (m01_axi_rid),
        .m01_axi_rdata    (m01_axi_rdata),
        .m01_axi_rresp    (m01_axi_rresp),
        .m01_axi_rlast    (m01_axi_rlast),
        .m01_axi_ruser    (m01_axi_ruser),
        .m01_axi_rvalid   (m01_axi_rvalid),
        .m01_axi_rready   (m01_axi_rready),
        /* Master Port M02 */
        .m02_axi_awid     (m02_axi_awid),
        .m02_axi_awaddr   (m02_axi_awaddr),
        .m02_axi_awlen    (m02_axi_awlen),
        .m02_axi_awsize   (m02_axi_awsize),
        .m02_axi_awburst  (m02_axi_awburst),
        .m02_axi_awlock   (m02_axi_awlock),
        .m02_axi_awcache  (m02_axi_awcache),
        .m02_axi_awprot   (m02_axi_awprot),
        .m02_axi_awqos    (m02_axi_awqos),
        .m02_axi_awregion (m02_axi_awregion),
        .m02_axi_awuser   (m02_axi_awuser),
        .m02_axi_awvalid  (m02_axi_awvalid),
        .m02_axi_awready  (m02_axi_awready),

        .m02_axi_wdata    (m02_axi_wdata),
        .m02_axi_wstrb    (m02_axi_wstrb),
        .m02_axi_wlast    (m02_axi_wlast),
        .m02_axi_wuser    (m02_axi_wuser),
        .m02_axi_wvalid   (m02_axi_wvalid),
        .m02_axi_wready   (m02_axi_wready),

        .m02_axi_bid      (m02_axi_bid),
        .m02_axi_bresp    (m02_axi_bresp),
        .m02_axi_buser    (m02_axi_buser),
        .m02_axi_bvalid   (m02_axi_bvalid),
        .m02_axi_bready   (m02_axi_bready),

        .m02_axi_arid     (m02_axi_arid),
        .m02_axi_araddr   (m02_axi_araddr),
        .m02_axi_arlen    (m02_axi_arlen),
        .m02_axi_arsize   (m02_axi_arsize),
        .m02_axi_arburst  (m02_axi_arburst),
        .m02_axi_arlock   (m02_axi_arlock),
        .m02_axi_arcache  (m02_axi_arcache),
        .m02_axi_arprot   (m02_axi_arprot),
        .m02_axi_arqos    (m02_axi_arqos),
        .m02_axi_arregion (m02_axi_arregion),
        .m02_axi_aruser   (m02_axi_aruser),
        .m02_axi_arvalid  (m02_axi_arvalid),
        .m02_axi_arready  (m02_axi_arready),

        .m02_axi_rid      (m02_axi_rid),
        .m02_axi_rdata    (m02_axi_rdata),
        .m02_axi_rresp    (m02_axi_rresp),
        .m02_axi_rlast    (m02_axi_rlast),
        .m02_axi_ruser    (m02_axi_ruser),
        .m02_axi_rvalid   (m02_axi_rvalid),
        .m02_axi_rready   (m02_axi_rready),
        /* Master Port M03 */
        .m03_axi_awid     (m03_axi_awid),
        .m03_axi_awaddr   (m03_axi_awaddr),
        .m03_axi_awlen    (m03_axi_awlen),
        .m03_axi_awsize   (m03_axi_awsize),
        .m03_axi_awburst  (m03_axi_awburst),
        .m03_axi_awlock   (m03_axi_awlock),
        .m03_axi_awcache  (m03_axi_awcache),
        .m03_axi_awprot   (m03_axi_awprot),
        .m03_axi_awqos    (m03_axi_awqos),
        .m03_axi_awregion (m03_axi_awregion),
        .m03_axi_awuser   (m03_axi_awuser),
        .m03_axi_awvalid  (m03_axi_awvalid),
        .m03_axi_awready  (m03_axi_awready),

        .m03_axi_wdata    (m03_axi_wdata),
        .m03_axi_wstrb    (m03_axi_wstrb),
        .m03_axi_wlast    (m03_axi_wlast),
        .m03_axi_wuser    (m03_axi_wuser),
        .m03_axi_wvalid   (m03_axi_wvalid),
        .m03_axi_wready   (m03_axi_wready),

        .m03_axi_bid      (m03_axi_bid),
        .m03_axi_bresp    (m03_axi_bresp),
        .m03_axi_buser    (m03_axi_buser),
        .m03_axi_bvalid   (m03_axi_bvalid),
        .m03_axi_bready   (m03_axi_bready),

        .m03_axi_arid     (m03_axi_arid),
        .m03_axi_araddr   (m03_axi_araddr),
        .m03_axi_arlen    (m03_axi_arlen),
        .m03_axi_arsize   (m03_axi_arsize),
        .m03_axi_arburst  (m03_axi_arburst),
        .m03_axi_arlock   (m03_axi_arlock),
        .m03_axi_arcache  (m03_axi_arcache),
        .m03_axi_arprot   (m03_axi_arprot),
        .m03_axi_arqos    (m03_axi_arqos),
        .m03_axi_arregion (m03_axi_arregion),
        .m03_axi_aruser   (m03_axi_aruser),
        .m03_axi_arvalid  (m03_axi_arvalid),
        .m03_axi_arready  (m03_axi_arready),

        .m03_axi_rid      (m03_axi_rid),
        .m03_axi_rdata    (m03_axi_rdata),
        .m03_axi_rresp    (m03_axi_rresp),
        .m03_axi_rlast    (m03_axi_rlast),
        .m03_axi_ruser    (m03_axi_ruser),
        .m03_axi_rvalid   (m03_axi_rvalid),
        .m03_axi_rready   (m03_axi_rready),
        /* Master Port M04 */
        .m04_axi_awid     (m04_axi_awid),
        .m04_axi_awaddr   (m04_axi_awaddr),
        .m04_axi_awlen    (m04_axi_awlen),
        .m04_axi_awsize   (m04_axi_awsize),
        .m04_axi_awburst  (m04_axi_awburst),
        .m04_axi_awlock   (m04_axi_awlock),
        .m04_axi_awcache  (m04_axi_awcache),
        .m04_axi_awprot   (m04_axi_awprot),
        .m04_axi_awqos    (m04_axi_awqos),
        .m04_axi_awregion (m04_axi_awregion),
        .m04_axi_awuser   (m04_axi_awuser),
        .m04_axi_awvalid  (m04_axi_awvalid),
        .m04_axi_awready  (m04_axi_awready),

        .m04_axi_wdata    (m04_axi_wdata),
        .m04_axi_wstrb    (m04_axi_wstrb),
        .m04_axi_wlast    (m04_axi_wlast),
        .m04_axi_wuser    (m04_axi_wuser),
        .m04_axi_wvalid   (m04_axi_wvalid),
        .m04_axi_wready   (m04_axi_wready),

        .m04_axi_bid      (m04_axi_bid),
        .m04_axi_bresp    (m04_axi_bresp),
        .m04_axi_buser    (m04_axi_buser),
        .m04_axi_bvalid   (m04_axi_bvalid),
        .m04_axi_bready   (m04_axi_bready),

        .m04_axi_arid     (m04_axi_arid),
        .m04_axi_araddr   (m04_axi_araddr),
        .m04_axi_arlen    (m04_axi_arlen),
        .m04_axi_arsize   (m04_axi_arsize),
        .m04_axi_arburst  (m04_axi_arburst),
        .m04_axi_arlock   (m04_axi_arlock),
        .m04_axi_arcache  (m04_axi_arcache),
        .m04_axi_arprot   (m04_axi_arprot),
        .m04_axi_arqos    (m04_axi_arqos),
        .m04_axi_arregion (m04_axi_arregion),
        .m04_axi_aruser   (m04_axi_aruser),
        .m04_axi_arvalid  (m04_axi_arvalid),
        .m04_axi_arready  (m04_axi_arready),

        .m04_axi_rid      (m04_axi_rid),
        .m04_axi_rdata    (m04_axi_rdata),
        .m04_axi_rresp    (m04_axi_rresp),
        .m04_axi_rlast    (m04_axi_rlast),
        .m04_axi_ruser    (m04_axi_ruser),
        .m04_axi_rvalid   (m04_axi_rvalid),
        .m04_axi_rready   (m04_axi_rready),
        /* Master Port M05 */
        .m05_axi_awid     (m05_axi_awid),
        .m05_axi_awaddr   (m05_axi_awaddr),
        .m05_axi_awlen    (m05_axi_awlen),
        .m05_axi_awsize   (m05_axi_awsize),
        .m05_axi_awburst  (m05_axi_awburst),
        .m05_axi_awlock   (m05_axi_awlock),
        .m05_axi_awcache  (m05_axi_awcache),
        .m05_axi_awprot   (m05_axi_awprot),
        .m05_axi_awqos    (m05_axi_awqos),
        .m05_axi_awregion (m05_axi_awregion),
        .m05_axi_awuser   (m05_axi_awuser),
        .m05_axi_awvalid  (m05_axi_awvalid),
        .m05_axi_awready  (m05_axi_awready),

        .m05_axi_wdata    (m05_axi_wdata),
        .m05_axi_wstrb    (m05_axi_wstrb),
        .m05_axi_wlast    (m05_axi_wlast),
        .m05_axi_wuser    (m05_axi_wuser),
        .m05_axi_wvalid   (m05_axi_wvalid),
        .m05_axi_wready   (m05_axi_wready),

        .m05_axi_bid      (m05_axi_bid),
        .m05_axi_bresp    (m05_axi_bresp),
        .m05_axi_buser    (m05_axi_buser),
        .m05_axi_bvalid   (m05_axi_bvalid),
        .m05_axi_bready   (m05_axi_bready),

        .m05_axi_arid     (m05_axi_arid),
        .m05_axi_araddr   (m05_axi_araddr),
        .m05_axi_arlen    (m05_axi_arlen),
        .m05_axi_arsize   (m05_axi_arsize),
        .m05_axi_arburst  (m05_axi_arburst),
        .m05_axi_arlock   (m05_axi_arlock),
        .m05_axi_arcache  (m05_axi_arcache),
        .m05_axi_arprot   (m05_axi_arprot),
        .m05_axi_arqos    (m05_axi_arqos),
        .m05_axi_arregion (m05_axi_arregion),
        .m05_axi_aruser   (m05_axi_aruser),
        .m05_axi_arvalid  (m05_axi_arvalid),
        .m05_axi_arready  (m05_axi_arready),

        .m05_axi_rid      (m05_axi_rid),
        .m05_axi_rdata    (m05_axi_rdata),
        .m05_axi_rresp    (m05_axi_rresp),
        .m05_axi_rlast    (m05_axi_rlast),
        .m05_axi_ruser    (m05_axi_ruser),
        .m05_axi_rvalid   (m05_axi_rvalid),
        .m05_axi_rready   (m05_axi_rready),
        /* Master Port M06 */
        .m06_axi_awid     (m06_axi_awid),
        .m06_axi_awaddr   (m06_axi_awaddr),
        .m06_axi_awlen    (m06_axi_awlen),
        .m06_axi_awsize   (m06_axi_awsize),
        .m06_axi_awburst  (m06_axi_awburst),
        .m06_axi_awlock   (m06_axi_awlock),
        .m06_axi_awcache  (m06_axi_awcache),
        .m06_axi_awprot   (m06_axi_awprot),
        .m06_axi_awqos    (m06_axi_awqos),
        .m06_axi_awregion (m06_axi_awregion),
        .m06_axi_awuser   (m06_axi_awuser),
        .m06_axi_awvalid  (m06_axi_awvalid),
        .m06_axi_awready  (m06_axi_awready),

        .m06_axi_wdata    (m06_axi_wdata),
        .m06_axi_wstrb    (m06_axi_wstrb),
        .m06_axi_wlast    (m06_axi_wlast),
        .m06_axi_wuser    (m06_axi_wuser),
        .m06_axi_wvalid   (m06_axi_wvalid),
        .m06_axi_wready   (m06_axi_wready),

        .m06_axi_bid      (m06_axi_bid),
        .m06_axi_bresp    (m06_axi_bresp),
        .m06_axi_buser    (m06_axi_buser),
        .m06_axi_bvalid   (m06_axi_bvalid),
        .m06_axi_bready   (m06_axi_bready),

        .m06_axi_arid     (m06_axi_arid),
        .m06_axi_araddr   (m06_axi_araddr),
        .m06_axi_arlen    (m06_axi_arlen),
        .m06_axi_arsize   (m06_axi_arsize),
        .m06_axi_arburst  (m06_axi_arburst),
        .m06_axi_arlock   (m06_axi_arlock),
        .m06_axi_arcache  (m06_axi_arcache),
        .m06_axi_arprot   (m06_axi_arprot),
        .m06_axi_arqos    (m06_axi_arqos),
        .m06_axi_arregion (m06_axi_arregion),
        .m06_axi_aruser   (m06_axi_aruser),
        .m06_axi_arvalid  (m06_axi_arvalid),
        .m06_axi_arready  (m06_axi_arready),

        .m06_axi_rid      (m06_axi_rid),
        .m06_axi_rdata    (m06_axi_rdata),
        .m06_axi_rresp    (m06_axi_rresp),
        .m06_axi_rlast    (m06_axi_rlast),
        .m06_axi_ruser    (m06_axi_ruser),
        .m06_axi_rvalid   (m06_axi_rvalid),
        .m06_axi_rready   (m06_axi_rready),
        /* Master Port M07 */
        .m07_axi_awid     (m07_axi_awid),
        .m07_axi_awaddr   (m07_axi_awaddr),
        .m07_axi_awlen    (m07_axi_awlen),
        .m07_axi_awsize   (m07_axi_awsize),
        .m07_axi_awburst  (m07_axi_awburst),
        .m07_axi_awlock   (m07_axi_awlock),
        .m07_axi_awcache  (m07_axi_awcache),
        .m07_axi_awprot   (m07_axi_awprot),
        .m07_axi_awqos    (m07_axi_awqos),
        .m07_axi_awregion (m07_axi_awregion),
        .m07_axi_awuser   (m07_axi_awuser),
        .m07_axi_awvalid  (m07_axi_awvalid),
        .m07_axi_awready  (m07_axi_awready),

        .m07_axi_wdata    (m07_axi_wdata),
        .m07_axi_wstrb    (m07_axi_wstrb),
        .m07_axi_wlast    (m07_axi_wlast),
        .m07_axi_wuser    (m07_axi_wuser),
        .m07_axi_wvalid   (m07_axi_wvalid),
        .m07_axi_wready   (m07_axi_wready),

        .m07_axi_bid      (m07_axi_bid),
        .m07_axi_bresp    (m07_axi_bresp),
        .m07_axi_buser    (m07_axi_buser),
        .m07_axi_bvalid   (m07_axi_bvalid),
        .m07_axi_bready   (m07_axi_bready),

        .m07_axi_arid     (m07_axi_arid),
        .m07_axi_araddr   (m07_axi_araddr),
        .m07_axi_arlen    (m07_axi_arlen),
        .m07_axi_arsize   (m07_axi_arsize),
        .m07_axi_arburst  (m07_axi_arburst),
        .m07_axi_arlock   (m07_axi_arlock),
        .m07_axi_arcache  (m07_axi_arcache),
        .m07_axi_arprot   (m07_axi_arprot),
        .m07_axi_arqos    (m07_axi_arqos),
        .m07_axi_arregion (m07_axi_arregion),
        .m07_axi_aruser   (m07_axi_aruser),
        .m07_axi_arvalid  (m07_axi_arvalid),
        .m07_axi_arready  (m07_axi_arready),

        .m07_axi_rid      (m07_axi_rid),
        .m07_axi_rdata    (m07_axi_rdata),
        .m07_axi_rresp    (m07_axi_rresp),
        .m07_axi_rlast    (m07_axi_rlast),
        .m07_axi_ruser    (m07_axi_ruser),
        .m07_axi_rvalid   (m07_axi_rvalid),
        .m07_axi_rready   (m07_axi_rready),
        /* Master Port M08 */
        .m08_axi_awid     (m08_axi_awid),
        .m08_axi_awaddr   (m08_axi_awaddr),
        .m08_axi_awlen    (m08_axi_awlen),
        .m08_axi_awsize   (m08_axi_awsize),
        .m08_axi_awburst  (m08_axi_awburst),
        .m08_axi_awlock   (m08_axi_awlock),
        .m08_axi_awcache  (m08_axi_awcache),
        .m08_axi_awprot   (m08_axi_awprot),
        .m08_axi_awqos    (m08_axi_awqos),
        .m08_axi_awregion (m08_axi_awregion),
        .m08_axi_awuser   (m08_axi_awuser),
        .m08_axi_awvalid  (m08_axi_awvalid),
        .m08_axi_awready  (m08_axi_awready),

        .m08_axi_wdata    (m08_axi_wdata),
        .m08_axi_wstrb    (m08_axi_wstrb),
        .m08_axi_wlast    (m08_axi_wlast),
        .m08_axi_wuser    (m08_axi_wuser),
        .m08_axi_wvalid   (m08_axi_wvalid),
        .m08_axi_wready   (m08_axi_wready),

        .m08_axi_bid      (m08_axi_bid),
        .m08_axi_bresp    (m08_axi_bresp),
        .m08_axi_buser    (m08_axi_buser),
        .m08_axi_bvalid   (m08_axi_bvalid),
        .m08_axi_bready   (m08_axi_bready),

        .m08_axi_arid     (m08_axi_arid),
        .m08_axi_araddr   (m08_axi_araddr),
        .m08_axi_arlen    (m08_axi_arlen),
        .m08_axi_arsize   (m08_axi_arsize),
        .m08_axi_arburst  (m08_axi_arburst),
        .m08_axi_arlock   (m08_axi_arlock),
        .m08_axi_arcache  (m08_axi_arcache),
        .m08_axi_arprot   (m08_axi_arprot),
        .m08_axi_arqos    (m08_axi_arqos),
        .m08_axi_arregion (m08_axi_arregion),
        .m08_axi_aruser   (m08_axi_aruser),
        .m08_axi_arvalid  (m08_axi_arvalid),
        .m08_axi_arready  (m08_axi_arready),

        .m08_axi_rid      (m08_axi_rid),
        .m08_axi_rdata    (m08_axi_rdata),
        .m08_axi_rresp    (m08_axi_rresp),
        .m08_axi_rlast    (m08_axi_rlast),
        .m08_axi_ruser    (m08_axi_ruser),
        .m08_axi_rvalid   (m08_axi_rvalid),
        .m08_axi_rready   (m08_axi_rready),
        /* Master Port M09 */
        .m09_axi_awid     (m09_axi_awid),
        .m09_axi_awaddr   (m09_axi_awaddr),
        .m09_axi_awlen    (m09_axi_awlen),
        .m09_axi_awsize   (m09_axi_awsize),
        .m09_axi_awburst  (m09_axi_awburst),
        .m09_axi_awlock   (m09_axi_awlock),
        .m09_axi_awcache  (m09_axi_awcache),
        .m09_axi_awprot   (m09_axi_awprot),
        .m09_axi_awqos    (m09_axi_awqos),
        .m09_axi_awregion (m09_axi_awregion),
        .m09_axi_awuser   (m09_axi_awuser),
        .m09_axi_awvalid  (m09_axi_awvalid),
        .m09_axi_awready  (m09_axi_awready),

        .m09_axi_wdata    (m09_axi_wdata),
        .m09_axi_wstrb    (m09_axi_wstrb),
        .m09_axi_wlast    (m09_axi_wlast),
        .m09_axi_wuser    (m09_axi_wuser),
        .m09_axi_wvalid   (m09_axi_wvalid),
        .m09_axi_wready   (m09_axi_wready),

        .m09_axi_bid      (m09_axi_bid),
        .m09_axi_bresp    (m09_axi_bresp),
        .m09_axi_buser    (m09_axi_buser),
        .m09_axi_bvalid   (m09_axi_bvalid),
        .m09_axi_bready   (m09_axi_bready),

        .m09_axi_arid     (m09_axi_arid),
        .m09_axi_araddr   (m09_axi_araddr),
        .m09_axi_arlen    (m09_axi_arlen),
        .m09_axi_arsize   (m09_axi_arsize),
        .m09_axi_arburst  (m09_axi_arburst),
        .m09_axi_arlock   (m09_axi_arlock),
        .m09_axi_arcache  (m09_axi_arcache),
        .m09_axi_arprot   (m09_axi_arprot),
        .m09_axi_arqos    (m09_axi_arqos),
        .m09_axi_arregion (m09_axi_arregion),
        .m09_axi_aruser   (m09_axi_aruser),
        .m09_axi_arvalid  (m09_axi_arvalid),
        .m09_axi_arready  (m09_axi_arready),

        .m09_axi_rid      (m09_axi_rid),
        .m09_axi_rdata    (m09_axi_rdata),
        .m09_axi_rresp    (m09_axi_rresp),
        .m09_axi_rlast    (m09_axi_rlast),
        .m09_axi_ruser    (m09_axi_ruser),
        .m09_axi_rvalid   (m09_axi_rvalid),
        .m09_axi_rready   (m09_axi_rready),
        /* Master Port M10 */
        .m10_axi_awid     (m10_axi_awid),
        .m10_axi_awaddr   (m10_axi_awaddr),
        .m10_axi_awlen    (m10_axi_awlen),
        .m10_axi_awsize   (m10_axi_awsize),
        .m10_axi_awburst  (m10_axi_awburst),
        .m10_axi_awlock   (m10_axi_awlock),
        .m10_axi_awcache  (m10_axi_awcache),
        .m10_axi_awprot   (m10_axi_awprot),
        .m10_axi_awqos    (m10_axi_awqos),
        .m10_axi_awregion (m10_axi_awregion),
        .m10_axi_awuser   (m10_axi_awuser),
        .m10_axi_awvalid  (m10_axi_awvalid),
        .m10_axi_awready  (m10_axi_awready),

        .m10_axi_wdata    (m10_axi_wdata),
        .m10_axi_wstrb    (m10_axi_wstrb),
        .m10_axi_wlast    (m10_axi_wlast),
        .m10_axi_wuser    (m10_axi_wuser),
        .m10_axi_wvalid   (m10_axi_wvalid),
        .m10_axi_wready   (m10_axi_wready),

        .m10_axi_bid      (m10_axi_bid),
        .m10_axi_bresp    (m10_axi_bresp),
        .m10_axi_buser    (m10_axi_buser),
        .m10_axi_bvalid   (m10_axi_bvalid),
        .m10_axi_bready   (m10_axi_bready),

        .m10_axi_arid     (m10_axi_arid),
        .m10_axi_araddr   (m10_axi_araddr),
        .m10_axi_arlen    (m10_axi_arlen),
        .m10_axi_arsize   (m10_axi_arsize),
        .m10_axi_arburst  (m10_axi_arburst),
        .m10_axi_arlock   (m10_axi_arlock),
        .m10_axi_arcache  (m10_axi_arcache),
        .m10_axi_arprot   (m10_axi_arprot),
        .m10_axi_arqos    (m10_axi_arqos),
        .m10_axi_arregion (m10_axi_arregion),
        .m10_axi_aruser   (m10_axi_aruser),
        .m10_axi_arvalid  (m10_axi_arvalid),
        .m10_axi_arready  (m10_axi_arready),

        .m10_axi_rid      (m10_axi_rid),
        .m10_axi_rdata    (m10_axi_rdata),
        .m10_axi_rresp    (m10_axi_rresp),
        .m10_axi_rlast    (m10_axi_rlast),
        .m10_axi_ruser    (m10_axi_ruser),
        .m10_axi_rvalid   (m10_axi_rvalid),
        .m10_axi_rready   (m10_axi_rready),
        /* Master Port M11 */
        .m11_axi_awid     (m11_axi_awid),
        .m11_axi_awaddr   (m11_axi_awaddr),
        .m11_axi_awlen    (m11_axi_awlen),
        .m11_axi_awsize   (m11_axi_awsize),
        .m11_axi_awburst  (m11_axi_awburst),
        .m11_axi_awlock   (m11_axi_awlock),
        .m11_axi_awcache  (m11_axi_awcache),
        .m11_axi_awprot   (m11_axi_awprot),
        .m11_axi_awqos    (m11_axi_awqos),
        .m11_axi_awregion (m11_axi_awregion),
        .m11_axi_awuser   (m11_axi_awuser),
        .m11_axi_awvalid  (m11_axi_awvalid),
        .m11_axi_awready  (m11_axi_awready),

        .m11_axi_wdata    (m11_axi_wdata),
        .m11_axi_wstrb    (m11_axi_wstrb),
        .m11_axi_wlast    (m11_axi_wlast),
        .m11_axi_wuser    (m11_axi_wuser),
        .m11_axi_wvalid   (m11_axi_wvalid),
        .m11_axi_wready   (m11_axi_wready),

        .m11_axi_bid      (m11_axi_bid),
        .m11_axi_bresp    (m11_axi_bresp),
        .m11_axi_buser    (m11_axi_buser),
        .m11_axi_bvalid   (m11_axi_bvalid),
        .m11_axi_bready   (m11_axi_bready),

        .m11_axi_arid     (m11_axi_arid),
        .m11_axi_araddr   (m11_axi_araddr),
        .m11_axi_arlen    (m11_axi_arlen),
        .m11_axi_arsize   (m11_axi_arsize),
        .m11_axi_arburst  (m11_axi_arburst),
        .m11_axi_arlock   (m11_axi_arlock),
        .m11_axi_arcache  (m11_axi_arcache),
        .m11_axi_arprot   (m11_axi_arprot),
        .m11_axi_arqos    (m11_axi_arqos),
        .m11_axi_arregion (m11_axi_arregion),
        .m11_axi_aruser   (m11_axi_aruser),
        .m11_axi_arvalid  (m11_axi_arvalid),
        .m11_axi_arready  (m11_axi_arready),

        .m11_axi_rid      (m11_axi_rid),
        .m11_axi_rdata    (m11_axi_rdata),
        .m11_axi_rresp    (m11_axi_rresp),
        .m11_axi_rlast    (m11_axi_rlast),
        .m11_axi_ruser    (m11_axi_ruser),
        .m11_axi_rvalid   (m11_axi_rvalid),
        .m11_axi_rready   (m11_axi_rready),
        /* Master Port M12 */
        .m12_axi_awid     (m12_axi_awid),
        .m12_axi_awaddr   (m12_axi_awaddr),
        .m12_axi_awlen    (m12_axi_awlen),
        .m12_axi_awsize   (m12_axi_awsize),
        .m12_axi_awburst  (m12_axi_awburst),
        .m12_axi_awlock   (m12_axi_awlock),
        .m12_axi_awcache  (m12_axi_awcache),
        .m12_axi_awprot   (m12_axi_awprot),
        .m12_axi_awqos    (m12_axi_awqos),
        .m12_axi_awregion (m12_axi_awregion),
        .m12_axi_awuser   (m12_axi_awuser),
        .m12_axi_awvalid  (m12_axi_awvalid),
        .m12_axi_awready  (m12_axi_awready),

        .m12_axi_wdata    (m12_axi_wdata),
        .m12_axi_wstrb    (m12_axi_wstrb),
        .m12_axi_wlast    (m12_axi_wlast),
        .m12_axi_wuser    (m12_axi_wuser),
        .m12_axi_wvalid   (m12_axi_wvalid),
        .m12_axi_wready   (m12_axi_wready),

        .m12_axi_bid      (m12_axi_bid),
        .m12_axi_bresp    (m12_axi_bresp),
        .m12_axi_buser    (m12_axi_buser),
        .m12_axi_bvalid   (m12_axi_bvalid),
        .m12_axi_bready   (m12_axi_bready),

        .m12_axi_arid     (m12_axi_arid),
        .m12_axi_araddr   (m12_axi_araddr),
        .m12_axi_arlen    (m12_axi_arlen),
        .m12_axi_arsize   (m12_axi_arsize),
        .m12_axi_arburst  (m12_axi_arburst),
        .m12_axi_arlock   (m12_axi_arlock),
        .m12_axi_arcache  (m12_axi_arcache),
        .m12_axi_arprot   (m12_axi_arprot),
        .m12_axi_arqos    (m12_axi_arqos),
        .m12_axi_arregion (m12_axi_arregion),
        .m12_axi_aruser   (m12_axi_aruser),
        .m12_axi_arvalid  (m12_axi_arvalid),
        .m12_axi_arready  (m12_axi_arready),

        .m12_axi_rid      (m12_axi_rid),
        .m12_axi_rdata    (m12_axi_rdata),
        .m12_axi_rresp    (m12_axi_rresp),
        .m12_axi_rlast    (m12_axi_rlast),
        .m12_axi_ruser    (m12_axi_ruser),
        .m12_axi_rvalid   (m12_axi_rvalid),
        .m12_axi_rready   (m12_axi_rready),
        /* Master Port M13 */
        .m13_axi_awid     (m13_axi_awid),
        .m13_axi_awaddr   (m13_axi_awaddr),
        .m13_axi_awlen    (m13_axi_awlen),
        .m13_axi_awsize   (m13_axi_awsize),
        .m13_axi_awburst  (m13_axi_awburst),
        .m13_axi_awlock   (m13_axi_awlock),
        .m13_axi_awcache  (m13_axi_awcache),
        .m13_axi_awprot   (m13_axi_awprot),
        .m13_axi_awqos    (m13_axi_awqos),
        .m13_axi_awregion (m13_axi_awregion),
        .m13_axi_awuser   (m13_axi_awuser),
        .m13_axi_awvalid  (m13_axi_awvalid),
        .m13_axi_awready  (m13_axi_awready),

        .m13_axi_wdata    (m13_axi_wdata),
        .m13_axi_wstrb    (m13_axi_wstrb),
        .m13_axi_wlast    (m13_axi_wlast),
        .m13_axi_wuser    (m13_axi_wuser),
        .m13_axi_wvalid   (m13_axi_wvalid),
        .m13_axi_wready   (m13_axi_wready),

        .m13_axi_bid      (m13_axi_bid),
        .m13_axi_bresp    (m13_axi_bresp),
        .m13_axi_buser    (m13_axi_buser),
        .m13_axi_bvalid   (m13_axi_bvalid),
        .m13_axi_bready   (m13_axi_bready),

        .m13_axi_arid     (m13_axi_arid),
        .m13_axi_araddr   (m13_axi_araddr),
        .m13_axi_arlen    (m13_axi_arlen),
        .m13_axi_arsize   (m13_axi_arsize),
        .m13_axi_arburst  (m13_axi_arburst),
        .m13_axi_arlock   (m13_axi_arlock),
        .m13_axi_arcache  (m13_axi_arcache),
        .m13_axi_arprot   (m13_axi_arprot),
        .m13_axi_arqos    (m13_axi_arqos),
        .m13_axi_arregion (m13_axi_arregion),
        .m13_axi_aruser   (m13_axi_aruser),
        .m13_axi_arvalid  (m13_axi_arvalid),
        .m13_axi_arready  (m13_axi_arready),

        .m13_axi_rid      (m13_axi_rid),
        .m13_axi_rdata    (m13_axi_rdata),
        .m13_axi_rresp    (m13_axi_rresp),
        .m13_axi_rlast    (m13_axi_rlast),
        .m13_axi_ruser    (m13_axi_ruser),
        .m13_axi_rvalid   (m13_axi_rvalid),
        .m13_axi_rready   (m13_axi_rready),
        /* Master Port M14 */
        .m14_axi_awid     (m14_axi_awid),
        .m14_axi_awaddr   (m14_axi_awaddr),
        .m14_axi_awlen    (m14_axi_awlen),
        .m14_axi_awsize   (m14_axi_awsize),
        .m14_axi_awburst  (m14_axi_awburst),
        .m14_axi_awlock   (m14_axi_awlock),
        .m14_axi_awcache  (m14_axi_awcache),
        .m14_axi_awprot   (m14_axi_awprot),
        .m14_axi_awqos    (m14_axi_awqos),
        .m14_axi_awregion (m14_axi_awregion),
        .m14_axi_awuser   (m14_axi_awuser),
        .m14_axi_awvalid  (m14_axi_awvalid),
        .m14_axi_awready  (m14_axi_awready),

        .m14_axi_wdata    (m14_axi_wdata),
        .m14_axi_wstrb    (m14_axi_wstrb),
        .m14_axi_wlast    (m14_axi_wlast),
        .m14_axi_wuser    (m14_axi_wuser),
        .m14_axi_wvalid   (m14_axi_wvalid),
        .m14_axi_wready   (m14_axi_wready),

        .m14_axi_bid      (m14_axi_bid),
        .m14_axi_bresp    (m14_axi_bresp),
        .m14_axi_buser    (m14_axi_buser),
        .m14_axi_bvalid   (m14_axi_bvalid),
        .m14_axi_bready   (m14_axi_bready),

        .m14_axi_arid     (m14_axi_arid),
        .m14_axi_araddr   (m14_axi_araddr),
        .m14_axi_arlen    (m14_axi_arlen),
        .m14_axi_arsize   (m14_axi_arsize),
        .m14_axi_arburst  (m14_axi_arburst),
        .m14_axi_arlock   (m14_axi_arlock),
        .m14_axi_arcache  (m14_axi_arcache),
        .m14_axi_arprot   (m14_axi_arprot),
        .m14_axi_arqos    (m14_axi_arqos),
        .m14_axi_arregion (m14_axi_arregion),
        .m14_axi_aruser   (m14_axi_aruser),
        .m14_axi_arvalid  (m14_axi_arvalid),
        .m14_axi_arready  (m14_axi_arready),

        .m14_axi_rid      (m14_axi_rid),
        .m14_axi_rdata    (m14_axi_rdata),
        .m14_axi_rresp    (m14_axi_rresp),
        .m14_axi_rlast    (m14_axi_rlast),
        .m14_axi_ruser    (m14_axi_ruser),
        .m14_axi_rvalid   (m14_axi_rvalid),
        .m14_axi_rready   (m14_axi_rready),
        /* Master Port M15 */
        .m15_axi_awid     (m15_axi_awid),
        .m15_axi_awaddr   (m15_axi_awaddr),
        .m15_axi_awlen    (m15_axi_awlen),
        .m15_axi_awsize   (m15_axi_awsize),
        .m15_axi_awburst  (m15_axi_awburst),
        .m15_axi_awlock   (m15_axi_awlock),
        .m15_axi_awcache  (m15_axi_awcache),
        .m15_axi_awprot   (m15_axi_awprot),
        .m15_axi_awqos    (m15_axi_awqos),
        .m15_axi_awregion (m15_axi_awregion),
        .m15_axi_awuser   (m15_axi_awuser),
        .m15_axi_awvalid  (m15_axi_awvalid),
        .m15_axi_awready  (m15_axi_awready),

        .m15_axi_wdata    (m15_axi_wdata),
        .m15_axi_wstrb    (m15_axi_wstrb),
        .m15_axi_wlast    (m15_axi_wlast),
        .m15_axi_wuser    (m15_axi_wuser),
        .m15_axi_wvalid   (m15_axi_wvalid),
        .m15_axi_wready   (m15_axi_wready),

        .m15_axi_bid      (m15_axi_bid),
        .m15_axi_bresp    (m15_axi_bresp),
        .m15_axi_buser    (m15_axi_buser),
        .m15_axi_bvalid   (m15_axi_bvalid),
        .m15_axi_bready   (m15_axi_bready),

        .m15_axi_arid     (m15_axi_arid),
        .m15_axi_araddr   (m15_axi_araddr),
        .m15_axi_arlen    (m15_axi_arlen),
        .m15_axi_arsize   (m15_axi_arsize),
        .m15_axi_arburst  (m15_axi_arburst),
        .m15_axi_arlock   (m15_axi_arlock),
        .m15_axi_arcache  (m15_axi_arcache),
        .m15_axi_arprot   (m15_axi_arprot),
        .m15_axi_arqos    (m15_axi_arqos),
        .m15_axi_arregion (m15_axi_arregion),
        .m15_axi_aruser   (m15_axi_aruser),
        .m15_axi_arvalid  (m15_axi_arvalid),
        .m15_axi_arready  (m15_axi_arready),

        .m15_axi_rid      (m15_axi_rid),
        .m15_axi_rdata    (m15_axi_rdata),
        .m15_axi_rresp    (m15_axi_rresp),
        .m15_axi_rlast    (m15_axi_rlast),
        .m15_axi_ruser    (m15_axi_ruser),
        .m15_axi_rvalid   (m15_axi_rvalid),
        .m15_axi_rready   (m15_axi_rready),
        /* Master Port M16 */
        .m16_axi_awid     (m16_axi_awid),
        .m16_axi_awaddr   (m16_axi_awaddr),
        .m16_axi_awlen    (m16_axi_awlen),
        .m16_axi_awsize   (m16_axi_awsize),
        .m16_axi_awburst  (m16_axi_awburst),
        .m16_axi_awlock   (m16_axi_awlock),
        .m16_axi_awcache  (m16_axi_awcache),
        .m16_axi_awprot   (m16_axi_awprot),
        .m16_axi_awqos    (m16_axi_awqos),
        .m16_axi_awregion (m16_axi_awregion),
        .m16_axi_awuser   (m16_axi_awuser),
        .m16_axi_awvalid  (m16_axi_awvalid),
        .m16_axi_awready  (m16_axi_awready),

        .m16_axi_wdata    (m16_axi_wdata),
        .m16_axi_wstrb    (m16_axi_wstrb),
        .m16_axi_wlast    (m16_axi_wlast),
        .m16_axi_wuser    (m16_axi_wuser),
        .m16_axi_wvalid   (m16_axi_wvalid),
        .m16_axi_wready   (m16_axi_wready),

        .m16_axi_bid      (m16_axi_bid),
        .m16_axi_bresp    (m16_axi_bresp),
        .m16_axi_buser    (m16_axi_buser),
        .m16_axi_bvalid   (m16_axi_bvalid),
        .m16_axi_bready   (m16_axi_bready),

        .m16_axi_arid     (m16_axi_arid),
        .m16_axi_araddr   (m16_axi_araddr),
        .m16_axi_arlen    (m16_axi_arlen),
        .m16_axi_arsize   (m16_axi_arsize),
        .m16_axi_arburst  (m16_axi_arburst),
        .m16_axi_arlock   (m16_axi_arlock),
        .m16_axi_arcache  (m16_axi_arcache),
        .m16_axi_arprot   (m16_axi_arprot),
        .m16_axi_arqos    (m16_axi_arqos),
        .m16_axi_arregion (m16_axi_arregion),
        .m16_axi_aruser   (m16_axi_aruser),
        .m16_axi_arvalid  (m16_axi_arvalid),
        .m16_axi_arready  (m16_axi_arready),

        .m16_axi_rid      (m16_axi_rid),
        .m16_axi_rdata    (m16_axi_rdata),
        .m16_axi_rresp    (m16_axi_rresp),
        .m16_axi_rlast    (m16_axi_rlast),
        .m16_axi_ruser    (m16_axi_ruser),
        .m16_axi_rvalid   (m16_axi_rvalid),
        .m16_axi_rready   (m16_axi_rready),
        /* Master Port M17 */
        .m17_axi_awid     (m17_axi_awid),
        .m17_axi_awaddr   (m17_axi_awaddr),
        .m17_axi_awlen    (m17_axi_awlen),
        .m17_axi_awsize   (m17_axi_awsize),
        .m17_axi_awburst  (m17_axi_awburst),
        .m17_axi_awlock   (m17_axi_awlock),
        .m17_axi_awcache  (m17_axi_awcache),
        .m17_axi_awprot   (m17_axi_awprot),
        .m17_axi_awqos    (m17_axi_awqos),
        .m17_axi_awregion (m17_axi_awregion),
        .m17_axi_awuser   (m17_axi_awuser),
        .m17_axi_awvalid  (m17_axi_awvalid),
        .m17_axi_awready  (m17_axi_awready),

        .m17_axi_wdata    (m17_axi_wdata),
        .m17_axi_wstrb    (m17_axi_wstrb),
        .m17_axi_wlast    (m17_axi_wlast),
        .m17_axi_wuser    (m17_axi_wuser),
        .m17_axi_wvalid   (m17_axi_wvalid),
        .m17_axi_wready   (m17_axi_wready),

        .m17_axi_bid      (m17_axi_bid),
        .m17_axi_bresp    (m17_axi_bresp),
        .m17_axi_buser    (m17_axi_buser),
        .m17_axi_bvalid   (m17_axi_bvalid),
        .m17_axi_bready   (m17_axi_bready),

        .m17_axi_arid     (m17_axi_arid),
        .m17_axi_araddr   (m17_axi_araddr),
        .m17_axi_arlen    (m17_axi_arlen),
        .m17_axi_arsize   (m17_axi_arsize),
        .m17_axi_arburst  (m17_axi_arburst),
        .m17_axi_arlock   (m17_axi_arlock),
        .m17_axi_arcache  (m17_axi_arcache),
        .m17_axi_arprot   (m17_axi_arprot),
        .m17_axi_arqos    (m17_axi_arqos),
        .m17_axi_arregion (m17_axi_arregion),
        .m17_axi_aruser   (m17_axi_aruser),
        .m17_axi_arvalid  (m17_axi_arvalid),
        .m17_axi_arready  (m17_axi_arready),

        .m17_axi_rid      (m17_axi_rid),
        .m17_axi_rdata    (m17_axi_rdata),
        .m17_axi_rresp    (m17_axi_rresp),
        .m17_axi_rlast    (m17_axi_rlast),
        .m17_axi_ruser    (m17_axi_ruser),
        .m17_axi_rvalid   (m17_axi_rvalid),
        .m17_axi_rready   (m17_axi_rready)
    );

    /* ============================================================
     * M00: UART IP
     *
     * Interconnect ID = 8 bits
     * UART ID         = 12 bits
     * IDs zero-extended toward UART; lower 8 bits returned.
     * ============================================================ */
    wire [11:0] uart_axi_arid;
    wire [4:0]  uart_axi_araddr;
    wire        uart_axi_arvalid;
    wire        uart_axi_arready;

    wire [11:0] uart_axi_rid;
    wire [31:0] uart_axi_rdata;
    wire [1:0]  uart_axi_rresp;
    wire        uart_axi_rvalid;
    wire        uart_axi_rready;

    wire [11:0] uart_axi_awid;
    wire [4:0]  uart_axi_awaddr;
    wire        uart_axi_awvalid;
    wire        uart_axi_awready;

    wire [31:0] uart_axi_wdata;
    wire [3:0]  uart_axi_wstrb;
    wire        uart_axi_wvalid;
    wire        uart_axi_wready;

    wire [11:0] uart_axi_bid;
    wire [1:0]  uart_axi_bresp;
    wire        uart_axi_bvalid;
    wire        uart_axi_bready;

    wire        uart_read_interrupt;

    assign uart_axi_arid    = {4'b0000, m00_axi_arid};
    assign uart_axi_araddr  = m00_axi_araddr[4:0];
    assign uart_axi_arvalid = m00_axi_arvalid;
    assign m00_axi_arready  = uart_axi_arready;

    assign m00_axi_rid      = uart_axi_rid[7:0];
    assign m00_axi_rdata    = uart_axi_rdata;
    assign m00_axi_rresp    = uart_axi_rresp;
    assign m00_axi_rlast    = 1'b1;
    assign m00_axi_ruser    = 1'b0;
    assign m00_axi_rvalid   = uart_axi_rvalid;
    assign uart_axi_rready  = m00_axi_rready;

    assign uart_axi_awid    = {4'b0000, m00_axi_awid};
    assign uart_axi_awaddr  = m00_axi_awaddr[4:0];
    assign uart_axi_awvalid = m00_axi_awvalid;
    assign m00_axi_awready  = uart_axi_awready;

    assign uart_axi_wdata   = m00_axi_wdata;
    assign uart_axi_wstrb   = m00_axi_wstrb;
    assign uart_axi_wvalid  = m00_axi_wvalid;
    assign m00_axi_wready   = uart_axi_wready;

    assign m00_axi_bid      = uart_axi_bid[7:0];
    assign m00_axi_bresp    = uart_axi_bresp;
    assign m00_axi_buser    = 1'b0;
    assign m00_axi_bvalid   = uart_axi_bvalid;
    assign uart_axi_bready  = m00_axi_bready;

    axi_uart_top u_uart (
        .fixed_clk_i       (clk),
        .axi_aclk_i        (clk),
        .axi_aresetn_i     (~rst),

        .axi_arid_i        (uart_axi_arid),
        .axi_araddr_i      (uart_axi_araddr),
        .axi_arvalid_i     (uart_axi_arvalid),
        .axi_arready_o     (uart_axi_arready),

        .axi_rid_o         (uart_axi_rid),
        .axi_rdata_o       (uart_axi_rdata),
        .axi_rresp_o       (uart_axi_rresp),
        .axi_rvalid_o      (uart_axi_rvalid),
        .axi_rready_i      (uart_axi_rready),

        .axi_awid_i        (uart_axi_awid),
        .axi_awaddr_i      (uart_axi_awaddr),
        .axi_awvalid_i     (uart_axi_awvalid),
        .axi_awready_o     (uart_axi_awready),

        .axi_wdata_i       (uart_axi_wdata),
        .axi_wstrb_i       (uart_axi_wstrb),
        .axi_wvalid_i      (uart_axi_wvalid),
        .axi_wready_o      (uart_axi_wready),

        .axi_bid_o         (uart_axi_bid),
        .axi_bresp_o       (uart_axi_bresp),
        .axi_bvalid_o      (uart_axi_bvalid),
        .axi_bready_i      (uart_axi_bready),

        .read_interrupt_o  (uart_read_interrupt),

        .uart_rx_i         (uart_rx_i),
        .uart_tx_o         (uart_tx_o)
    );

    /* ============================================================
     * M01: AXI4 -> AXI4-Lite Bridge -> GPIO
     * ============================================================ */
    wire [ADDR_WIDTH-1:0] gpio_lite_awaddr;
    wire [2:0]            gpio_lite_awprot;
    wire                  gpio_lite_awvalid;
    wire                  gpio_lite_awready;
    wire [DATA_WIDTH-1:0] gpio_lite_wdata;
    wire [STRB_WIDTH-1:0] gpio_lite_wstrb;
    wire                  gpio_lite_wvalid;
    wire                  gpio_lite_wready;
    wire [1:0]            gpio_lite_bresp;
    wire                  gpio_lite_bvalid;
    wire                  gpio_lite_bready;
    wire [ADDR_WIDTH-1:0] gpio_lite_araddr;
    wire [2:0]            gpio_lite_arprot;
    wire                  gpio_lite_arvalid;
    wire                  gpio_lite_arready;
    wire [DATA_WIDTH-1:0] gpio_lite_rdata;
    wire [1:0]            gpio_lite_rresp;
    wire                  gpio_lite_rvalid;
    wire                  gpio_lite_rready;

    axi4_to_axi4lite_bridge #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .STRB_WIDTH (STRB_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .USER_WIDTH (1)
    ) u_gpio_axi_bridge (
        .aclk        (clk),
        .aresetn     (~rst),

        .s_awid      (m01_axi_awid),
        .s_awaddr    (m01_axi_awaddr),
        .s_awlen     (m01_axi_awlen),
        .s_awsize    (m01_axi_awsize),
        .s_awburst   (m01_axi_awburst),
        .s_awlock    (m01_axi_awlock),
        .s_awcache   (m01_axi_awcache),
        .s_awprot    (m01_axi_awprot),
        .s_awqos     (m01_axi_awqos),
        .s_awregion  (m01_axi_awregion),
        .s_awuser    (m01_axi_awuser),
        .s_awvalid   (m01_axi_awvalid),
        .s_awready   (m01_axi_awready),

        .s_wdata     (m01_axi_wdata),
        .s_wstrb     (m01_axi_wstrb),
        .s_wlast     (m01_axi_wlast),
        .s_wuser     (m01_axi_wuser),
        .s_wvalid    (m01_axi_wvalid),
        .s_wready    (m01_axi_wready),

        .s_bid       (m01_axi_bid),
        .s_bresp     (m01_axi_bresp),
        .s_buser     (m01_axi_buser),
        .s_bvalid    (m01_axi_bvalid),
        .s_bready    (m01_axi_bready),

        .s_arid      (m01_axi_arid),
        .s_araddr    (m01_axi_araddr),
        .s_arlen     (m01_axi_arlen),
        .s_arsize    (m01_axi_arsize),
        .s_arburst   (m01_axi_arburst),
        .s_arlock    (m01_axi_arlock),
        .s_arcache   (m01_axi_arcache),
        .s_arprot    (m01_axi_arprot),
        .s_arqos     (m01_axi_arqos),
        .s_arregion  (m01_axi_arregion),
        .s_aruser    (m01_axi_aruser),
        .s_arvalid   (m01_axi_arvalid),
        .s_arready   (m01_axi_arready),

        .s_rid       (m01_axi_rid),
        .s_rdata     (m01_axi_rdata),
        .s_rresp     (m01_axi_rresp),
        .s_rlast     (m01_axi_rlast),
        .s_ruser     (m01_axi_ruser),
        .s_rvalid    (m01_axi_rvalid),
        .s_rready    (m01_axi_rready),

        .m_awaddr    (gpio_lite_awaddr),
        .m_awprot    (gpio_lite_awprot),
        .m_awvalid   (gpio_lite_awvalid),
        .m_awready   (gpio_lite_awready),
        .m_wdata     (gpio_lite_wdata),
        .m_wstrb     (gpio_lite_wstrb),
        .m_wvalid    (gpio_lite_wvalid),
        .m_wready    (gpio_lite_wready),
        .m_bresp     (gpio_lite_bresp),
        .m_bvalid    (gpio_lite_bvalid),
        .m_bready    (gpio_lite_bready),
        .m_araddr    (gpio_lite_araddr),
        .m_arprot    (gpio_lite_arprot),
        .m_arvalid   (gpio_lite_arvalid),
        .m_arready   (gpio_lite_arready),
        .m_rdata     (gpio_lite_rdata),
        .m_rresp     (gpio_lite_rresp),
        .m_rvalid    (gpio_lite_rvalid),
        .m_rready    (gpio_lite_rready)
    );

    gpio_axi #(
        .NUM_BITS(8)
    ) u_gpio (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (~rst),

        .s_axi_awaddr  (gpio_lite_awaddr),
        .s_axi_awprot  (gpio_lite_awprot),
        .s_axi_awvalid (gpio_lite_awvalid),
        .s_axi_awready (gpio_lite_awready),
        .s_axi_wdata   (gpio_lite_wdata),
        .s_axi_wstrb   (gpio_lite_wstrb),
        .s_axi_wvalid  (gpio_lite_wvalid),
        .s_axi_wready  (gpio_lite_wready),
        .s_axi_bresp   (gpio_lite_bresp),
        .s_axi_bvalid  (gpio_lite_bvalid),
        .s_axi_bready  (gpio_lite_bready),
        .s_axi_araddr  (gpio_lite_araddr),
        .s_axi_arprot  (gpio_lite_arprot),
        .s_axi_arvalid (gpio_lite_arvalid),
        .s_axi_arready (gpio_lite_arready),
        .s_axi_rdata   (gpio_lite_rdata),
        .s_axi_rresp   (gpio_lite_rresp),
        .s_axi_rvalid  (gpio_lite_rvalid),
        .s_axi_rready  (gpio_lite_rready),
        .io            (gpio_io),
        .intr          (gpio_irq)
    );

    /* ============================================================
     * M02: AXI4 -> AXI4-Lite Bridge -> TIMER
     * ============================================================ */
    wire [ADDR_WIDTH-1:0] timer_lite_awaddr;
    wire [2:0]            timer_lite_awprot;
    wire                  timer_lite_awvalid;
    wire                  timer_lite_awready;
    wire [DATA_WIDTH-1:0] timer_lite_wdata;
    wire [STRB_WIDTH-1:0] timer_lite_wstrb;
    wire                  timer_lite_wvalid;
    wire                  timer_lite_wready;
    wire [1:0]            timer_lite_bresp;
    wire                  timer_lite_bvalid;
    wire                  timer_lite_bready;
    wire [ADDR_WIDTH-1:0] timer_lite_araddr;
    wire [2:0]            timer_lite_arprot;
    wire                  timer_lite_arvalid;
    wire                  timer_lite_arready;
    wire [DATA_WIDTH-1:0] timer_lite_rdata;
    wire [1:0]            timer_lite_rresp;
    wire                  timer_lite_rvalid;
    wire                  timer_lite_rready;

    axi4_to_axi4lite_bridge #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .STRB_WIDTH (STRB_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .USER_WIDTH (1)
    ) u_timer_axi_bridge (
        .aclk        (clk),
        .aresetn     (~rst),

        .s_awid      (m02_axi_awid),
        .s_awaddr    (m02_axi_awaddr),
        .s_awlen     (m02_axi_awlen),
        .s_awsize    (m02_axi_awsize),
        .s_awburst   (m02_axi_awburst),
        .s_awlock    (m02_axi_awlock),
        .s_awcache   (m02_axi_awcache),
        .s_awprot    (m02_axi_awprot),
        .s_awqos     (m02_axi_awqos),
        .s_awregion  (m02_axi_awregion),
        .s_awuser    (m02_axi_awuser),
        .s_awvalid   (m02_axi_awvalid),
        .s_awready   (m02_axi_awready),

        .s_wdata     (m02_axi_wdata),
        .s_wstrb     (m02_axi_wstrb),
        .s_wlast     (m02_axi_wlast),
        .s_wuser     (m02_axi_wuser),
        .s_wvalid    (m02_axi_wvalid),
        .s_wready    (m02_axi_wready),

        .s_bid       (m02_axi_bid),
        .s_bresp     (m02_axi_bresp),
        .s_buser     (m02_axi_buser),
        .s_bvalid    (m02_axi_bvalid),
        .s_bready    (m02_axi_bready),

        .s_arid      (m02_axi_arid),
        .s_araddr    (m02_axi_araddr),
        .s_arlen     (m02_axi_arlen),
        .s_arsize    (m02_axi_arsize),
        .s_arburst   (m02_axi_arburst),
        .s_arlock    (m02_axi_arlock),
        .s_arcache   (m02_axi_arcache),
        .s_arprot    (m02_axi_arprot),
        .s_arqos     (m02_axi_arqos),
        .s_arregion  (m02_axi_arregion),
        .s_aruser    (m02_axi_aruser),
        .s_arvalid   (m02_axi_arvalid),
        .s_arready   (m02_axi_arready),

        .s_rid       (m02_axi_rid),
        .s_rdata     (m02_axi_rdata),
        .s_rresp     (m02_axi_rresp),
        .s_rlast     (m02_axi_rlast),
        .s_ruser     (m02_axi_ruser),
        .s_rvalid    (m02_axi_rvalid),
        .s_rready    (m02_axi_rready),

        .m_awaddr    (timer_lite_awaddr),
        .m_awprot    (timer_lite_awprot),
        .m_awvalid   (timer_lite_awvalid),
        .m_awready   (timer_lite_awready),
        .m_wdata     (timer_lite_wdata),
        .m_wstrb     (timer_lite_wstrb),
        .m_wvalid    (timer_lite_wvalid),
        .m_wready    (timer_lite_wready),
        .m_bresp     (timer_lite_bresp),
        .m_bvalid    (timer_lite_bvalid),
        .m_bready    (timer_lite_bready),
        .m_araddr    (timer_lite_araddr),
        .m_arprot    (timer_lite_arprot),
        .m_arvalid   (timer_lite_arvalid),
        .m_arready   (timer_lite_arready),
        .m_rdata     (timer_lite_rdata),
        .m_rresp     (timer_lite_rresp),
        .m_rvalid    (timer_lite_rvalid),
        .m_rready    (timer_lite_rready)
    );

    timer_axi u_timer (
        .aclk        (clk),
        .aresetn     (~rst),

        .awaddr      (timer_lite_awaddr),
        .awprot      (timer_lite_awprot),
        .awvalid     (timer_lite_awvalid),
        .awready     (timer_lite_awready),
        .wdata       (timer_lite_wdata),
        .wstrb       (timer_lite_wstrb),
        .wvalid      (timer_lite_wvalid),
        .wready      (timer_lite_wready),
        .bresp       (timer_lite_bresp),
        .bvalid      (timer_lite_bvalid),
        .bready      (timer_lite_bready),
        .araddr      (timer_lite_araddr),
        .arprot      (timer_lite_arprot),
        .arvalid     (timer_lite_arvalid),
        .arready     (timer_lite_arready),
        .rdata       (timer_lite_rdata),
        .rresp       (timer_lite_rresp),
        .rvalid      (timer_lite_rvalid),
        .rready      (timer_lite_rready),

        .ext_meas_i  (timer_ext_meas_i),
        .capture_i   (timer_capture_i),
        .pwm_o       (timer_pwm_o),
        .trigger_o   (timer_trigger_o),
        .irq         (timer_irq)
    );

    /* ============================================================
     * M03: FIR AXI4-Lite ADAPTATION
     *
     * Interconnect performs 0x4000_C000 window decode.
     * Only single-beat AXI4-Lite subset is passed to FIR.
     * ============================================================ */
    wire [31:0] fir_axi_awaddr;
    wire        fir_axi_awvalid;
    wire        fir_axi_awready;

    wire [31:0] fir_axi_wdata;
    wire [3:0]  fir_axi_wstrb;
    wire        fir_axi_wvalid;
    wire        fir_axi_wready;

    wire        fir_axi_bvalid;
    wire [1:0]  fir_axi_bresp;
    wire        fir_axi_bready;

    wire [31:0] fir_axi_araddr;
    wire        fir_axi_arvalid;
    wire        fir_axi_arready;

    wire [31:0] fir_axi_rdata;
    wire        fir_axi_rvalid;
    wire [1:0]  fir_axi_rresp;
    wire        fir_axi_rready;

    localparam [31:0] FIR_BASE_ADDR = 32'h4000_C000;

    assign fir_axi_awaddr  = m03_axi_awaddr - FIR_BASE_ADDR;
    assign fir_axi_awvalid = m03_axi_awvalid;
    assign m03_axi_awready = fir_axi_awready;

    assign fir_axi_wdata   = m03_axi_wdata;
    assign fir_axi_wstrb   = m03_axi_wstrb;
    assign fir_axi_wvalid  = m03_axi_wvalid;
    assign m03_axi_wready  = fir_axi_wready;

    assign m03_axi_bresp   = fir_axi_bresp;
    assign m03_axi_bvalid  = fir_axi_bvalid;
    assign m03_axi_buser   = 1'b0;
    assign m03_axi_bid     = m03_axi_awid;
    assign fir_axi_bready  = m03_axi_bready;

    assign fir_axi_araddr  = m03_axi_araddr - FIR_BASE_ADDR;
    assign fir_axi_arvalid = m03_axi_arvalid;
    assign m03_axi_arready = fir_axi_arready;

    assign m03_axi_rdata   = fir_axi_rdata;
    assign m03_axi_rresp   = fir_axi_rresp;
    assign m03_axi_rvalid  = fir_axi_rvalid;
    assign m03_axi_ruser   = 1'b0;
    assign m03_axi_rid     = m03_axi_arid;
    assign m03_axi_rlast   = 1'b1;
    assign fir_axi_rready  = m03_axi_rready;

    fir_top #(
        .DATA_WIDTH (16),
        .COEFF_WIDTH(16),
        .ACC_WIDTH  (40),
        .NUM_TAPS   (32),
        .FIFO_DEPTH (8)
    ) u_fir (
        .clk                (clk),
        .rst_n              (~rst),

        .s_axis_tvalid     (fir_s_axis_tvalid),
        .s_axis_tready     (fir_s_axis_tready),
        .s_axis_tdata      (fir_s_axis_tdata),

        .m_axis_tvalid     (fir_m_axis_tvalid),
        .m_axis_tready     (fir_m_axis_tready),
        .m_axis_tdata      (fir_m_axis_tdata),

        .s_axi_awaddr      (fir_axi_awaddr),
        .s_axi_awvalid     (fir_axi_awvalid),
        .s_axi_awready     (fir_axi_awready),

        .s_axi_wdata       (fir_axi_wdata),
        .s_axi_wstrb       (fir_axi_wstrb),
        .s_axi_wvalid      (fir_axi_wvalid),
        .s_axi_wready      (fir_axi_wready),

        .s_axi_bvalid      (fir_axi_bvalid),
        .s_axi_bresp       (fir_axi_bresp),
        .s_axi_bready      (fir_axi_bready),

        .s_axi_araddr      (fir_axi_araddr),
        .s_axi_arvalid     (fir_axi_arvalid),
        .s_axi_arready     (fir_axi_arready),

        .s_axi_rdata       (fir_axi_rdata),
        .s_axi_rvalid      (fir_axi_rvalid),
        .s_axi_rresp       (fir_axi_rresp),
        .s_axi_rready      (fir_axi_rready),

        .input_fifo_full   (),
        .input_fifo_empty  (),
        .output_fifo_empty ()
    );

    /* ============================================================
     * M04: ADC (Native AXI4-Lite Subset)
     * ============================================================ */
    reg [ID_WIDTH-1:0] adc_bid_reg;
    reg [ID_WIDTH-1:0] adc_rid_reg;

    always @(posedge clk) begin
        if (rst) begin
            adc_bid_reg <= {ID_WIDTH{1'b0}};
            adc_rid_reg <= {ID_WIDTH{1'b0}};
        end else begin
            if (m04_axi_awvalid && m04_axi_awready)
                adc_bid_reg <= m04_axi_awid;
            if (m04_axi_arvalid && m04_axi_arready)
                adc_rid_reg <= m04_axi_arid;
        end
    end

    assign m04_axi_bid   = adc_bid_reg;
    assign m04_axi_buser = 1'b0;
    assign m04_axi_rid   = adc_rid_reg;
    assign m04_axi_ruser = 1'b0;
    assign m04_axi_rlast = 1'b1;

    adc_controller #(
        .ADC_RESOLUTION    (12),
        .NUM_CHANNELS      (1),
        .FIFO_DEPTH        (32),
        .CLK_FREQ_HZ       (50_000_000),
        .SAMPLE_RATE_HZ    (250),
        .BASE_ADDR         (32'h4000_E000),
        .ENABLE_FIFO       (1),
        .ENABLE_INTERRUPTS (1)
    ) u_adc (
        .aclk            (clk),
        .aresetn         (~rst),

        .sample_in       (adc_sample_in),
        .sample_valid    (adc_sample_valid),

        .irq_sample      (adc_irq_sample),
        .irq_overrun     (adc_irq_overrun),

        .s_axi_awaddr    (m04_axi_awaddr),
        .s_axi_awvalid   (m04_axi_awvalid),
        .s_axi_awready   (m04_axi_awready),

        .s_axi_wdata     (m04_axi_wdata),
        .s_axi_wstrb     (m04_axi_wstrb),
        .s_axi_wvalid    (m04_axi_wvalid),
        .s_axi_wready    (m04_axi_wready),

        .s_axi_bresp     (m04_axi_bresp),
        .s_axi_bvalid    (m04_axi_bvalid),
        .s_axi_bready    (m04_axi_bready),

        .s_axi_araddr    (m04_axi_araddr),
        .s_axi_arvalid   (m04_axi_arvalid),
        .s_axi_arready   (m04_axi_arready),

        .s_axi_rdata     (m04_axi_rdata),
        .s_axi_rresp     (m04_axi_rresp),
        .s_axi_rvalid    (m04_axi_rvalid),
        .s_axi_rready    (m04_axi_rready)
    );

    /* ============================================================
     * M05: SPI AXI4-Lite Adaptation
     *
     * Interconnect already decodes the 0x4001_0000 window.
     * Lower 7 address bits passed to SPI.
     * ============================================================ */
    wire [11:0] spi_axi_arid;
    wire [6:0]  spi_axi_araddr;
    wire        spi_axi_arvalid;
    wire        spi_axi_arready;

    wire [11:0] spi_axi_rid;
    wire [31:0] spi_axi_rdata;
    wire [1:0]  spi_axi_rresp;
    wire        spi_axi_rvalid;
    wire        spi_axi_rready;

    wire [11:0] spi_axi_awid;
    wire [6:0]  spi_axi_awaddr;
    wire        spi_axi_awvalid;
    wire        spi_axi_awready;

    wire [31:0] spi_axi_wdata;
    wire [3:0]  spi_axi_wstrb;
    wire        spi_axi_wvalid;
    wire        spi_axi_wready;

    wire [11:0] spi_axi_bid;
    wire [1:0]  spi_axi_bresp;
    wire        spi_axi_bvalid;
    wire        spi_axi_bready;

    assign spi_axi_arid    = {4'b0000, m05_axi_arid};
    assign spi_axi_araddr  = m05_axi_araddr[6:0];
    assign spi_axi_arvalid = m05_axi_arvalid;
    assign m05_axi_arready = spi_axi_arready;

    assign m05_axi_rid     = spi_axi_rid[7:0];
    assign m05_axi_rdata   = spi_axi_rdata;
    assign m05_axi_rresp   = spi_axi_rresp;
    assign m05_axi_rlast   = 1'b1;
    assign m05_axi_ruser   = 1'b0;
    assign m05_axi_rvalid  = spi_axi_rvalid;
    assign spi_axi_rready  = m05_axi_rready;

    assign spi_axi_awid    = {4'b0000, m05_axi_awid};
    assign spi_axi_awaddr  = m05_axi_awaddr[6:0];
    assign spi_axi_awvalid = m05_axi_awvalid;
    assign m05_axi_awready = spi_axi_awready;

    assign spi_axi_wdata   = m05_axi_wdata;
    assign spi_axi_wstrb   = m05_axi_wstrb;
    assign spi_axi_wvalid  = m05_axi_wvalid;
    assign m05_axi_wready  = spi_axi_wready;

    assign m05_axi_bid     = spi_axi_bid[7:0];
    assign m05_axi_bresp   = spi_axi_bresp;
    assign m05_axi_buser   = 1'b0;
    assign m05_axi_bvalid  = spi_axi_bvalid;
    assign spi_axi_bready  = m05_axi_bready;

    axi_spi_top u_spi (
        .fixed_clk_i       (clk),
        .axi_aclk_i        (clk),
        .axi_aresetn_i     (~rst),

        .axi_arid_i        (spi_axi_arid),
        .axi_araddr_i      (spi_axi_araddr),
        .axi_arvalid_i     (spi_axi_arvalid),
        .axi_arready_o     (spi_axi_arready),

        .axi_rid_o         (spi_axi_rid),
        .axi_rdata_o       (spi_axi_rdata),
        .axi_rresp_o       (spi_axi_rresp),
        .axi_rvalid_o      (spi_axi_rvalid),
        .axi_rready_i      (spi_axi_rready),

        .axi_awid_i        (spi_axi_awid),
        .axi_awaddr_i      (spi_axi_awaddr),
        .axi_awvalid_i     (spi_axi_awvalid),
        .axi_awready_o     (spi_axi_awready),

        .axi_wdata_i       (spi_axi_wdata),
        .axi_wstrb_i       (spi_axi_wstrb),
        .axi_wvalid_i      (spi_axi_wvalid),
        .axi_wready_o      (spi_axi_wready),

        .axi_bid_o         (spi_axi_bid),
        .axi_bresp_o       (spi_axi_bresp),
        .axi_bvalid_o      (spi_axi_bvalid),
        .axi_bready_i      (spi_axi_bready),

        .spi_clk_o         (spi_clk_o),
        .spi_cs_n_o        (spi_cs_n_o),
        .spi_mosi_o        (spi_mosi_o),
        .spi_miso_i        (spi_miso_i)
    );

    /* ============================================================
     * M06: QRS AXI4 Wrapper (0x4001_2000 - 0x4001_2FFF)
     * ============================================================ */
    qrs_axi4_wrapper #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .FS         (360),
        .BASE_ADDR  (32'h4001_2000)
    ) u_qrs (
        .clk          (clk),
        .rst          (rst),

        .s_axi_awid   (m06_axi_awid),
        .s_axi_awaddr (m06_axi_awaddr),
        .s_axi_awlen  (m06_axi_awlen),
        .s_axi_awsize (m06_axi_awsize),
        .s_axi_awburst(m06_axi_awburst),
        .s_axi_awlock (m06_axi_awlock),
        .s_axi_awcache(m06_axi_awcache),
        .s_axi_awprot (m06_axi_awprot),
        .s_axi_awqos  (m06_axi_awqos),
        .s_axi_awvalid(m06_axi_awvalid),
        .s_axi_awready(m06_axi_awready),

        .s_axi_wdata  (m06_axi_wdata),
        .s_axi_wstrb  (m06_axi_wstrb),
        .s_axi_wlast  (m06_axi_wlast),
        .s_axi_wvalid (m06_axi_wvalid),
        .s_axi_wready (m06_axi_wready),

        .s_axi_bid    (m06_axi_bid),
        .s_axi_bresp  (m06_axi_bresp),
        .s_axi_bvalid (m06_axi_bvalid),
        .s_axi_bready (m06_axi_bready),

        .s_axi_arid   (m06_axi_arid),
        .s_axi_araddr (m06_axi_araddr),
        .s_axi_arlen  (m06_axi_arlen),
        .s_axi_arsize (m06_axi_arsize),
        .s_axi_arburst(m06_axi_arburst),
        .s_axi_arlock (m06_axi_arlock),
        .s_axi_arcache(m06_axi_arcache),
        .s_axi_arprot (m06_axi_arprot),
        .s_axi_arqos  (m06_axi_arqos),
        .s_axi_arvalid(m06_axi_arvalid),
        .s_axi_arready(m06_axi_arready),

        .s_axi_rid    (m06_axi_rid),
        .s_axi_rdata  (m06_axi_rdata),
        .s_axi_rresp  (m06_axi_rresp),
        .s_axi_rlast  (m06_axi_rlast),
        .s_axi_rvalid (m06_axi_rvalid),
        .s_axi_rready (m06_axi_rready)
    );

    /* ============================================================
     * M07: Generic Dummy Slave (WATCHDOG (Dummy))
     * ============================================================ */
    axi_dummy_slave #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .STRB_WIDTH   (STRB_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (1),
        .WUSER_WIDTH  (1),
        .BUSER_WIDTH  (1),
        .ARUSER_WIDTH (1),
        .RUSER_WIDTH  (1),
        .RESP         (2'b11)   // DECERR
    ) u_dummy_slave_m07 (
        .clk             (clk),
        .rst             (rst),

        .s_axi_awid      (m07_axi_awid),
        .s_axi_awaddr    (m07_axi_awaddr),
        .s_axi_awlen     (m07_axi_awlen),
        .s_axi_awsize    (m07_axi_awsize),
        .s_axi_awburst   (m07_axi_awburst),
        .s_axi_awlock    (m07_axi_awlock),
        .s_axi_awcache   (m07_axi_awcache),
        .s_axi_awprot    (m07_axi_awprot),
        .s_axi_awqos     (m07_axi_awqos),
        .s_axi_awregion  (m07_axi_awregion),
        .s_axi_awuser    (m07_axi_awuser),
        .s_axi_awvalid   (m07_axi_awvalid),
        .s_axi_awready   (m07_axi_awready),

        .s_axi_wdata     (m07_axi_wdata),
        .s_axi_wstrb     (m07_axi_wstrb),
        .s_axi_wlast     (m07_axi_wlast),
        .s_axi_wuser     (m07_axi_wuser),
        .s_axi_wvalid    (m07_axi_wvalid),
        .s_axi_wready    (m07_axi_wready),

        .s_axi_bid       (m07_axi_bid),
        .s_axi_bresp     (m07_axi_bresp),
        .s_axi_buser     (m07_axi_buser),
        .s_axi_bvalid    (m07_axi_bvalid),
        .s_axi_bready    (m07_axi_bready),

        .s_axi_arid      (m07_axi_arid),
        .s_axi_araddr    (m07_axi_araddr),
        .s_axi_arlen     (m07_axi_arlen),
        .s_axi_arsize    (m07_axi_arsize),
        .s_axi_arburst   (m07_axi_arburst),
        .s_axi_arlock    (m07_axi_arlock),
        .s_axi_arcache   (m07_axi_arcache),
        .s_axi_arprot    (m07_axi_arprot),
        .s_axi_arqos     (m07_axi_arqos),
        .s_axi_arregion  (m07_axi_arregion),
        .s_axi_aruser    (m07_axi_aruser),
        .s_axi_arvalid   (m07_axi_arvalid),
        .s_axi_arready   (m07_axi_arready),

        .s_axi_rid       (m07_axi_rid),
        .s_axi_rdata     (m07_axi_rdata),
        .s_axi_rresp     (m07_axi_rresp),
        .s_axi_rlast     (m07_axi_rlast),
        .s_axi_ruser     (m07_axi_ruser),
        .s_axi_rvalid    (m07_axi_rvalid),
        .s_axi_rready    (m07_axi_rready)
    );
    /* ============================================================
     * M08: Generic Dummy Slave (FFT CONTROL (Dummy))
     * ============================================================ */
    axi_dummy_slave #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .STRB_WIDTH   (STRB_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (1),
        .WUSER_WIDTH  (1),
        .BUSER_WIDTH  (1),
        .ARUSER_WIDTH (1),
        .RUSER_WIDTH  (1),
        .RESP         (2'b11)   // DECERR
    ) u_dummy_slave_m08 (
        .clk             (clk),
        .rst             (rst),

        .s_axi_awid      (m08_axi_awid),
        .s_axi_awaddr    (m08_axi_awaddr),
        .s_axi_awlen     (m08_axi_awlen),
        .s_axi_awsize    (m08_axi_awsize),
        .s_axi_awburst   (m08_axi_awburst),
        .s_axi_awlock    (m08_axi_awlock),
        .s_axi_awcache   (m08_axi_awcache),
        .s_axi_awprot    (m08_axi_awprot),
        .s_axi_awqos     (m08_axi_awqos),
        .s_axi_awregion  (m08_axi_awregion),
        .s_axi_awuser    (m08_axi_awuser),
        .s_axi_awvalid   (m08_axi_awvalid),
        .s_axi_awready   (m08_axi_awready),

        .s_axi_wdata     (m08_axi_wdata),
        .s_axi_wstrb     (m08_axi_wstrb),
        .s_axi_wlast     (m08_axi_wlast),
        .s_axi_wuser     (m08_axi_wuser),
        .s_axi_wvalid    (m08_axi_wvalid),
        .s_axi_wready    (m08_axi_wready),

        .s_axi_bid       (m08_axi_bid),
        .s_axi_bresp     (m08_axi_bresp),
        .s_axi_buser     (m08_axi_buser),
        .s_axi_bvalid    (m08_axi_bvalid),
        .s_axi_bready    (m08_axi_bready),

        .s_axi_arid      (m08_axi_arid),
        .s_axi_araddr    (m08_axi_araddr),
        .s_axi_arlen     (m08_axi_arlen),
        .s_axi_arsize    (m08_axi_arsize),
        .s_axi_arburst   (m08_axi_arburst),
        .s_axi_arlock    (m08_axi_arlock),
        .s_axi_arcache   (m08_axi_arcache),
        .s_axi_arprot    (m08_axi_arprot),
        .s_axi_arqos     (m08_axi_arqos),
        .s_axi_arregion  (m08_axi_arregion),
        .s_axi_aruser    (m08_axi_aruser),
        .s_axi_arvalid   (m08_axi_arvalid),
        .s_axi_arready   (m08_axi_arready),

        .s_axi_rid       (m08_axi_rid),
        .s_axi_rdata     (m08_axi_rdata),
        .s_axi_rresp     (m08_axi_rresp),
        .s_axi_rlast     (m08_axi_rlast),
        .s_axi_ruser     (m08_axi_ruser),
        .s_axi_rvalid    (m08_axi_rvalid),
        .s_axi_rready    (m08_axi_rready)
    );
    /* ============================================================
     * M09: Generic Dummy Slave (FFT MEMORY (Dummy))
     * ============================================================ */
    axi_dummy_slave #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .STRB_WIDTH   (STRB_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (1),
        .WUSER_WIDTH  (1),
        .BUSER_WIDTH  (1),
        .ARUSER_WIDTH (1),
        .RUSER_WIDTH  (1),
        .RESP         (2'b11)   // DECERR
    ) u_dummy_slave_m09 (
        .clk             (clk),
        .rst             (rst),

        .s_axi_awid      (m09_axi_awid),
        .s_axi_awaddr    (m09_axi_awaddr),
        .s_axi_awlen     (m09_axi_awlen),
        .s_axi_awsize    (m09_axi_awsize),
        .s_axi_awburst   (m09_axi_awburst),
        .s_axi_awlock    (m09_axi_awlock),
        .s_axi_awcache   (m09_axi_awcache),
        .s_axi_awprot    (m09_axi_awprot),
        .s_axi_awqos     (m09_axi_awqos),
        .s_axi_awregion  (m09_axi_awregion),
        .s_axi_awuser    (m09_axi_awuser),
        .s_axi_awvalid   (m09_axi_awvalid),
        .s_axi_awready   (m09_axi_awready),

        .s_axi_wdata     (m09_axi_wdata),
        .s_axi_wstrb     (m09_axi_wstrb),
        .s_axi_wlast     (m09_axi_wlast),
        .s_axi_wuser     (m09_axi_wuser),
        .s_axi_wvalid    (m09_axi_wvalid),
        .s_axi_wready    (m09_axi_wready),

        .s_axi_bid       (m09_axi_bid),
        .s_axi_bresp     (m09_axi_bresp),
        .s_axi_buser     (m09_axi_buser),
        .s_axi_bvalid    (m09_axi_bvalid),
        .s_axi_bready    (m09_axi_bready),

        .s_axi_arid      (m09_axi_arid),
        .s_axi_araddr    (m09_axi_araddr),
        .s_axi_arlen     (m09_axi_arlen),
        .s_axi_arsize    (m09_axi_arsize),
        .s_axi_arburst   (m09_axi_arburst),
        .s_axi_arlock    (m09_axi_arlock),
        .s_axi_arcache   (m09_axi_arcache),
        .s_axi_arprot    (m09_axi_arprot),
        .s_axi_arqos     (m09_axi_arqos),
        .s_axi_arregion  (m09_axi_arregion),
        .s_axi_aruser    (m09_axi_aruser),
        .s_axi_arvalid   (m09_axi_arvalid),
        .s_axi_arready   (m09_axi_arready),

        .s_axi_rid       (m09_axi_rid),
        .s_axi_rdata     (m09_axi_rdata),
        .s_axi_rresp     (m09_axi_rresp),
        .s_axi_rlast     (m09_axi_rlast),
        .s_axi_ruser     (m09_axi_ruser),
        .s_axi_rvalid    (m09_axi_rvalid),
        .s_axi_rready    (m09_axi_rready)
    );
    /* ============================================================
     * M10: Generic Dummy Slave (AES (Dummy))
     * ============================================================ */
    axi_dummy_slave #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .STRB_WIDTH   (STRB_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (1),
        .WUSER_WIDTH  (1),
        .BUSER_WIDTH  (1),
        .ARUSER_WIDTH (1),
        .RUSER_WIDTH  (1),
        .RESP         (2'b11)   // DECERR
    ) u_dummy_slave_m10 (
        .clk             (clk),
        .rst             (rst),

        .s_axi_awid      (m10_axi_awid),
        .s_axi_awaddr    (m10_axi_awaddr),
        .s_axi_awlen     (m10_axi_awlen),
        .s_axi_awsize    (m10_axi_awsize),
        .s_axi_awburst   (m10_axi_awburst),
        .s_axi_awlock    (m10_axi_awlock),
        .s_axi_awcache   (m10_axi_awcache),
        .s_axi_awprot    (m10_axi_awprot),
        .s_axi_awqos     (m10_axi_awqos),
        .s_axi_awregion  (m10_axi_awregion),
        .s_axi_awuser    (m10_axi_awuser),
        .s_axi_awvalid   (m10_axi_awvalid),
        .s_axi_awready   (m10_axi_awready),

        .s_axi_wdata     (m10_axi_wdata),
        .s_axi_wstrb     (m10_axi_wstrb),
        .s_axi_wlast     (m10_axi_wlast),
        .s_axi_wuser     (m10_axi_wuser),
        .s_axi_wvalid    (m10_axi_wvalid),
        .s_axi_wready    (m10_axi_wready),

        .s_axi_bid       (m10_axi_bid),
        .s_axi_bresp     (m10_axi_bresp),
        .s_axi_buser     (m10_axi_buser),
        .s_axi_bvalid    (m10_axi_bvalid),
        .s_axi_bready    (m10_axi_bready),

        .s_axi_arid      (m10_axi_arid),
        .s_axi_araddr    (m10_axi_araddr),
        .s_axi_arlen     (m10_axi_arlen),
        .s_axi_arsize    (m10_axi_arsize),
        .s_axi_arburst   (m10_axi_arburst),
        .s_axi_arlock    (m10_axi_arlock),
        .s_axi_arcache   (m10_axi_arcache),
        .s_axi_arprot    (m10_axi_arprot),
        .s_axi_arqos     (m10_axi_arqos),
        .s_axi_arregion  (m10_axi_arregion),
        .s_axi_aruser    (m10_axi_aruser),
        .s_axi_arvalid   (m10_axi_arvalid),
        .s_axi_arready   (m10_axi_arready),

        .s_axi_rid       (m10_axi_rid),
        .s_axi_rdata     (m10_axi_rdata),
        .s_axi_rresp     (m10_axi_rresp),
        .s_axi_rlast     (m10_axi_rlast),
        .s_axi_ruser     (m10_axi_ruser),
        .s_axi_rvalid    (m10_axi_rvalid),
        .s_axi_rready    (m10_axi_rready)
    );
    /* ============================================================
     * M11: Generic Dummy Slave (INTERRUPT AGGREGATOR (Dummy))
     * ============================================================ */
    axi_dummy_slave #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .STRB_WIDTH   (STRB_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (1),
        .WUSER_WIDTH  (1),
        .BUSER_WIDTH  (1),
        .ARUSER_WIDTH (1),
        .RUSER_WIDTH  (1),
        .RESP         (2'b11)   // DECERR
    ) u_dummy_slave_m11 (
        .clk             (clk),
        .rst             (rst),

        .s_axi_awid      (m11_axi_awid),
        .s_axi_awaddr    (m11_axi_awaddr),
        .s_axi_awlen     (m11_axi_awlen),
        .s_axi_awsize    (m11_axi_awsize),
        .s_axi_awburst   (m11_axi_awburst),
        .s_axi_awlock    (m11_axi_awlock),
        .s_axi_awcache   (m11_axi_awcache),
        .s_axi_awprot    (m11_axi_awprot),
        .s_axi_awqos     (m11_axi_awqos),
        .s_axi_awregion  (m11_axi_awregion),
        .s_axi_awuser    (m11_axi_awuser),
        .s_axi_awvalid   (m11_axi_awvalid),
        .s_axi_awready   (m11_axi_awready),

        .s_axi_wdata     (m11_axi_wdata),
        .s_axi_wstrb     (m11_axi_wstrb),
        .s_axi_wlast     (m11_axi_wlast),
        .s_axi_wuser     (m11_axi_wuser),
        .s_axi_wvalid    (m11_axi_wvalid),
        .s_axi_wready    (m11_axi_wready),

        .s_axi_bid       (m11_axi_bid),
        .s_axi_bresp     (m11_axi_bresp),
        .s_axi_buser     (m11_axi_buser),
        .s_axi_bvalid    (m11_axi_bvalid),
        .s_axi_bready    (m11_axi_bready),

        .s_axi_arid      (m11_axi_arid),
        .s_axi_araddr    (m11_axi_araddr),
        .s_axi_arlen     (m11_axi_arlen),
        .s_axi_arsize    (m11_axi_arsize),
        .s_axi_arburst   (m11_axi_arburst),
        .s_axi_arlock    (m11_axi_arlock),
        .s_axi_arcache   (m11_axi_arcache),
        .s_axi_arprot    (m11_axi_arprot),
        .s_axi_arqos     (m11_axi_arqos),
        .s_axi_arregion  (m11_axi_arregion),
        .s_axi_aruser    (m11_axi_aruser),
        .s_axi_arvalid   (m11_axi_arvalid),
        .s_axi_arready   (m11_axi_arready),

        .s_axi_rid       (m11_axi_rid),
        .s_axi_rdata     (m11_axi_rdata),
        .s_axi_rresp     (m11_axi_rresp),
        .s_axi_rlast     (m11_axi_rlast),
        .s_axi_ruser     (m11_axi_ruser),
        .s_axi_rvalid    (m11_axi_rvalid),
        .s_axi_rready    (m11_axi_rready)
    );
    /* ============================================================
     * M12: Generic Dummy Slave (PWM (Dummy))
     * ============================================================ */
    axi_dummy_slave #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .STRB_WIDTH   (STRB_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (1),
        .WUSER_WIDTH  (1),
        .BUSER_WIDTH  (1),
        .ARUSER_WIDTH (1),
        .RUSER_WIDTH  (1),
        .RESP         (2'b11)   // DECERR
    ) u_dummy_slave_m12 (
        .clk             (clk),
        .rst             (rst),

        .s_axi_awid      (m12_axi_awid),
        .s_axi_awaddr    (m12_axi_awaddr),
        .s_axi_awlen     (m12_axi_awlen),
        .s_axi_awsize    (m12_axi_awsize),
        .s_axi_awburst   (m12_axi_awburst),
        .s_axi_awlock    (m12_axi_awlock),
        .s_axi_awcache   (m12_axi_awcache),
        .s_axi_awprot    (m12_axi_awprot),
        .s_axi_awqos     (m12_axi_awqos),
        .s_axi_awregion  (m12_axi_awregion),
        .s_axi_awuser    (m12_axi_awuser),
        .s_axi_awvalid   (m12_axi_awvalid),
        .s_axi_awready   (m12_axi_awready),

        .s_axi_wdata     (m12_axi_wdata),
        .s_axi_wstrb     (m12_axi_wstrb),
        .s_axi_wlast     (m12_axi_wlast),
        .s_axi_wuser     (m12_axi_wuser),
        .s_axi_wvalid    (m12_axi_wvalid),
        .s_axi_wready    (m12_axi_wready),

        .s_axi_bid       (m12_axi_bid),
        .s_axi_bresp     (m12_axi_bresp),
        .s_axi_buser     (m12_axi_buser),
        .s_axi_bvalid    (m12_axi_bvalid),
        .s_axi_bready    (m12_axi_bready),

        .s_axi_arid      (m12_axi_arid),
        .s_axi_araddr    (m12_axi_araddr),
        .s_axi_arlen     (m12_axi_arlen),
        .s_axi_arsize    (m12_axi_arsize),
        .s_axi_arburst   (m12_axi_arburst),
        .s_axi_arlock    (m12_axi_arlock),
        .s_axi_arcache   (m12_axi_arcache),
        .s_axi_arprot    (m12_axi_arprot),
        .s_axi_arqos     (m12_axi_arqos),
        .s_axi_arregion  (m12_axi_arregion),
        .s_axi_aruser    (m12_axi_aruser),
        .s_axi_arvalid   (m12_axi_arvalid),
        .s_axi_arready   (m12_axi_arready),

        .s_axi_rid       (m12_axi_rid),
        .s_axi_rdata     (m12_axi_rdata),
        .s_axi_rresp     (m12_axi_rresp),
        .s_axi_rlast     (m12_axi_rlast),
        .s_axi_ruser     (m12_axi_ruser),
        .s_axi_rvalid    (m12_axi_rvalid),
        .s_axi_rready    (m12_axi_rready)
    );
    /* ============================================================
     * M13: Generic Dummy Slave (I2C (Dummy))
     * ============================================================ */
    axi_dummy_slave #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .STRB_WIDTH   (STRB_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (1),
        .WUSER_WIDTH  (1),
        .BUSER_WIDTH  (1),
        .ARUSER_WIDTH (1),
        .RUSER_WIDTH  (1),
        .RESP         (2'b11)   // DECERR
    ) u_dummy_slave_m13 (
        .clk             (clk),
        .rst             (rst),

        .s_axi_awid      (m13_axi_awid),
        .s_axi_awaddr    (m13_axi_awaddr),
        .s_axi_awlen     (m13_axi_awlen),
        .s_axi_awsize    (m13_axi_awsize),
        .s_axi_awburst   (m13_axi_awburst),
        .s_axi_awlock    (m13_axi_awlock),
        .s_axi_awcache   (m13_axi_awcache),
        .s_axi_awprot    (m13_axi_awprot),
        .s_axi_awqos     (m13_axi_awqos),
        .s_axi_awregion  (m13_axi_awregion),
        .s_axi_awuser    (m13_axi_awuser),
        .s_axi_awvalid   (m13_axi_awvalid),
        .s_axi_awready   (m13_axi_awready),

        .s_axi_wdata     (m13_axi_wdata),
        .s_axi_wstrb     (m13_axi_wstrb),
        .s_axi_wlast     (m13_axi_wlast),
        .s_axi_wuser     (m13_axi_wuser),
        .s_axi_wvalid    (m13_axi_wvalid),
        .s_axi_wready    (m13_axi_wready),

        .s_axi_bid       (m13_axi_bid),
        .s_axi_bresp     (m13_axi_bresp),
        .s_axi_buser     (m13_axi_buser),
        .s_axi_bvalid    (m13_axi_bvalid),
        .s_axi_bready    (m13_axi_bready),

        .s_axi_arid      (m13_axi_arid),
        .s_axi_araddr    (m13_axi_araddr),
        .s_axi_arlen     (m13_axi_arlen),
        .s_axi_arsize    (m13_axi_arsize),
        .s_axi_arburst   (m13_axi_arburst),
        .s_axi_arlock    (m13_axi_arlock),
        .s_axi_arcache   (m13_axi_arcache),
        .s_axi_arprot    (m13_axi_arprot),
        .s_axi_arqos     (m13_axi_arqos),
        .s_axi_arregion  (m13_axi_arregion),
        .s_axi_aruser    (m13_axi_aruser),
        .s_axi_arvalid   (m13_axi_arvalid),
        .s_axi_arready   (m13_axi_arready),

        .s_axi_rid       (m13_axi_rid),
        .s_axi_rdata     (m13_axi_rdata),
        .s_axi_rresp     (m13_axi_rresp),
        .s_axi_rlast     (m13_axi_rlast),
        .s_axi_ruser     (m13_axi_ruser),
        .s_axi_rvalid    (m13_axi_rvalid),
        .s_axi_rready    (m13_axi_rready)
    );
    /* ============================================================
     * M14: Generic Dummy Slave (DMA REG (Dummy))
     * ============================================================ */
    axi_dummy_slave #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .STRB_WIDTH   (STRB_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (1),
        .WUSER_WIDTH  (1),
        .BUSER_WIDTH  (1),
        .ARUSER_WIDTH (1),
        .RUSER_WIDTH  (1),
        .RESP         (2'b11)   // DECERR
    ) u_dummy_slave_m14 (
        .clk             (clk),
        .rst             (rst),

        .s_axi_awid      (m14_axi_awid),
        .s_axi_awaddr    (m14_axi_awaddr),
        .s_axi_awlen     (m14_axi_awlen),
        .s_axi_awsize    (m14_axi_awsize),
        .s_axi_awburst   (m14_axi_awburst),
        .s_axi_awlock    (m14_axi_awlock),
        .s_axi_awcache   (m14_axi_awcache),
        .s_axi_awprot    (m14_axi_awprot),
        .s_axi_awqos     (m14_axi_awqos),
        .s_axi_awregion  (m14_axi_awregion),
        .s_axi_awuser    (m14_axi_awuser),
        .s_axi_awvalid   (m14_axi_awvalid),
        .s_axi_awready   (m14_axi_awready),

        .s_axi_wdata     (m14_axi_wdata),
        .s_axi_wstrb     (m14_axi_wstrb),
        .s_axi_wlast     (m14_axi_wlast),
        .s_axi_wuser     (m14_axi_wuser),
        .s_axi_wvalid    (m14_axi_wvalid),
        .s_axi_wready    (m14_axi_wready),

        .s_axi_bid       (m14_axi_bid),
        .s_axi_bresp     (m14_axi_bresp),
        .s_axi_buser     (m14_axi_buser),
        .s_axi_bvalid    (m14_axi_bvalid),
        .s_axi_bready    (m14_axi_bready),

        .s_axi_arid      (m14_axi_arid),
        .s_axi_araddr    (m14_axi_araddr),
        .s_axi_arlen     (m14_axi_arlen),
        .s_axi_arsize    (m14_axi_arsize),
        .s_axi_arburst   (m14_axi_arburst),
        .s_axi_arlock    (m14_axi_arlock),
        .s_axi_arcache   (m14_axi_arcache),
        .s_axi_arprot    (m14_axi_arprot),
        .s_axi_arqos     (m14_axi_arqos),
        .s_axi_arregion  (m14_axi_arregion),
        .s_axi_aruser    (m14_axi_aruser),
        .s_axi_arvalid   (m14_axi_arvalid),
        .s_axi_arready   (m14_axi_arready),

        .s_axi_rid       (m14_axi_rid),
        .s_axi_rdata     (m14_axi_rdata),
        .s_axi_rresp     (m14_axi_rresp),
        .s_axi_rlast     (m14_axi_rlast),
        .s_axi_ruser     (m14_axi_ruser),
        .s_axi_rvalid    (m14_axi_rvalid),
        .s_axi_rready    (m14_axi_rready)
    );
    /* ============================================================
     * M15: Generic Dummy Slave (RESERVED (Dummy))
     * ============================================================ */
    axi_dummy_slave #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .STRB_WIDTH   (STRB_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (1),
        .WUSER_WIDTH  (1),
        .BUSER_WIDTH  (1),
        .ARUSER_WIDTH (1),
        .RUSER_WIDTH  (1),
        .RESP         (2'b11)   // DECERR
    ) u_dummy_slave_m15 (
        .clk             (clk),
        .rst             (rst),

        .s_axi_awid      (m15_axi_awid),
        .s_axi_awaddr    (m15_axi_awaddr),
        .s_axi_awlen     (m15_axi_awlen),
        .s_axi_awsize    (m15_axi_awsize),
        .s_axi_awburst   (m15_axi_awburst),
        .s_axi_awlock    (m15_axi_awlock),
        .s_axi_awcache   (m15_axi_awcache),
        .s_axi_awprot    (m15_axi_awprot),
        .s_axi_awqos     (m15_axi_awqos),
        .s_axi_awregion  (m15_axi_awregion),
        .s_axi_awuser    (m15_axi_awuser),
        .s_axi_awvalid   (m15_axi_awvalid),
        .s_axi_awready   (m15_axi_awready),

        .s_axi_wdata     (m15_axi_wdata),
        .s_axi_wstrb     (m15_axi_wstrb),
        .s_axi_wlast     (m15_axi_wlast),
        .s_axi_wuser     (m15_axi_wuser),
        .s_axi_wvalid    (m15_axi_wvalid),
        .s_axi_wready    (m15_axi_wready),

        .s_axi_bid       (m15_axi_bid),
        .s_axi_bresp     (m15_axi_bresp),
        .s_axi_buser     (m15_axi_buser),
        .s_axi_bvalid    (m15_axi_bvalid),
        .s_axi_bready    (m15_axi_bready),

        .s_axi_arid      (m15_axi_arid),
        .s_axi_araddr    (m15_axi_araddr),
        .s_axi_arlen     (m15_axi_arlen),
        .s_axi_arsize    (m15_axi_arsize),
        .s_axi_arburst   (m15_axi_arburst),
        .s_axi_arlock    (m15_axi_arlock),
        .s_axi_arcache   (m15_axi_arcache),
        .s_axi_arprot    (m15_axi_arprot),
        .s_axi_arqos     (m15_axi_arqos),
        .s_axi_arregion  (m15_axi_arregion),
        .s_axi_aruser    (m15_axi_aruser),
        .s_axi_arvalid   (m15_axi_arvalid),
        .s_axi_arready   (m15_axi_arready),

        .s_axi_rid       (m15_axi_rid),
        .s_axi_rdata     (m15_axi_rdata),
        .s_axi_rresp     (m15_axi_rresp),
        .s_axi_rlast     (m15_axi_rlast),
        .s_axi_ruser     (m15_axi_ruser),
        .s_axi_rvalid    (m15_axi_rvalid),
        .s_axi_rready    (m15_axi_rready)
    );
    /* ============================================================
     * M16: Generic Dummy Slave (RESERVED (Dummy))
     * ============================================================ */
    axi_dummy_slave #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .STRB_WIDTH   (STRB_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (1),
        .WUSER_WIDTH  (1),
        .BUSER_WIDTH  (1),
        .ARUSER_WIDTH (1),
        .RUSER_WIDTH  (1),
        .RESP         (2'b11)   // DECERR
    ) u_dummy_slave_m16 (
        .clk             (clk),
        .rst             (rst),

        .s_axi_awid      (m16_axi_awid),
        .s_axi_awaddr    (m16_axi_awaddr),
        .s_axi_awlen     (m16_axi_awlen),
        .s_axi_awsize    (m16_axi_awsize),
        .s_axi_awburst   (m16_axi_awburst),
        .s_axi_awlock    (m16_axi_awlock),
        .s_axi_awcache   (m16_axi_awcache),
        .s_axi_awprot    (m16_axi_awprot),
        .s_axi_awqos     (m16_axi_awqos),
        .s_axi_awregion  (m16_axi_awregion),
        .s_axi_awuser    (m16_axi_awuser),
        .s_axi_awvalid   (m16_axi_awvalid),
        .s_axi_awready   (m16_axi_awready),

        .s_axi_wdata     (m16_axi_wdata),
        .s_axi_wstrb     (m16_axi_wstrb),
        .s_axi_wlast     (m16_axi_wlast),
        .s_axi_wuser     (m16_axi_wuser),
        .s_axi_wvalid    (m16_axi_wvalid),
        .s_axi_wready    (m16_axi_wready),

        .s_axi_bid       (m16_axi_bid),
        .s_axi_bresp     (m16_axi_bresp),
        .s_axi_buser     (m16_axi_buser),
        .s_axi_bvalid    (m16_axi_bvalid),
        .s_axi_bready    (m16_axi_bready),

        .s_axi_arid      (m16_axi_arid),
        .s_axi_araddr    (m16_axi_araddr),
        .s_axi_arlen     (m16_axi_arlen),
        .s_axi_arsize    (m16_axi_arsize),
        .s_axi_arburst   (m16_axi_arburst),
        .s_axi_arlock    (m16_axi_arlock),
        .s_axi_arcache   (m16_axi_arcache),
        .s_axi_arprot    (m16_axi_arprot),
        .s_axi_arqos     (m16_axi_arqos),
        .s_axi_arregion  (m16_axi_arregion),
        .s_axi_aruser    (m16_axi_aruser),
        .s_axi_arvalid   (m16_axi_arvalid),
        .s_axi_arready   (m16_axi_arready),

        .s_axi_rid       (m16_axi_rid),
        .s_axi_rdata     (m16_axi_rdata),
        .s_axi_rresp     (m16_axi_rresp),
        .s_axi_rlast     (m16_axi_rlast),
        .s_axi_ruser     (m16_axi_ruser),
        .s_axi_rvalid    (m16_axi_rvalid),
        .s_axi_rready    (m16_axi_rready)
    );
    /* ============================================================
     * M17: Generic Dummy Slave (RESERVED (Dummy))
     * ============================================================ */
    axi_dummy_slave #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .STRB_WIDTH   (STRB_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (1),
        .WUSER_WIDTH  (1),
        .BUSER_WIDTH  (1),
        .ARUSER_WIDTH (1),
        .RUSER_WIDTH  (1),
        .RESP         (2'b11)   // DECERR
    ) u_dummy_slave_m17 (
        .clk             (clk),
        .rst             (rst),

        .s_axi_awid      (m17_axi_awid),
        .s_axi_awaddr    (m17_axi_awaddr),
        .s_axi_awlen     (m17_axi_awlen),
        .s_axi_awsize    (m17_axi_awsize),
        .s_axi_awburst   (m17_axi_awburst),
        .s_axi_awlock    (m17_axi_awlock),
        .s_axi_awcache   (m17_axi_awcache),
        .s_axi_awprot    (m17_axi_awprot),
        .s_axi_awqos     (m17_axi_awqos),
        .s_axi_awregion  (m17_axi_awregion),
        .s_axi_awuser    (m17_axi_awuser),
        .s_axi_awvalid   (m17_axi_awvalid),
        .s_axi_awready   (m17_axi_awready),

        .s_axi_wdata     (m17_axi_wdata),
        .s_axi_wstrb     (m17_axi_wstrb),
        .s_axi_wlast     (m17_axi_wlast),
        .s_axi_wuser     (m17_axi_wuser),
        .s_axi_wvalid    (m17_axi_wvalid),
        .s_axi_wready    (m17_axi_wready),

        .s_axi_bid       (m17_axi_bid),
        .s_axi_bresp     (m17_axi_bresp),
        .s_axi_buser     (m17_axi_buser),
        .s_axi_bvalid    (m17_axi_bvalid),
        .s_axi_bready    (m17_axi_bready),

        .s_axi_arid      (m17_axi_arid),
        .s_axi_araddr    (m17_axi_araddr),
        .s_axi_arlen     (m17_axi_arlen),
        .s_axi_arsize    (m17_axi_arsize),
        .s_axi_arburst   (m17_axi_arburst),
        .s_axi_arlock    (m17_axi_arlock),
        .s_axi_arcache   (m17_axi_arcache),
        .s_axi_arprot    (m17_axi_arprot),
        .s_axi_arqos     (m17_axi_arqos),
        .s_axi_arregion  (m17_axi_arregion),
        .s_axi_aruser    (m17_axi_aruser),
        .s_axi_arvalid   (m17_axi_arvalid),
        .s_axi_arready   (m17_axi_arready),

        .s_axi_rid       (m17_axi_rid),
        .s_axi_rdata     (m17_axi_rdata),
        .s_axi_rresp     (m17_axi_rresp),
        .s_axi_rlast     (m17_axi_rlast),
        .s_axi_ruser     (m17_axi_ruser),
        .s_axi_rvalid    (m17_axi_rvalid),
        .s_axi_rready    (m17_axi_rready)
    );
endmodule

`resetall
