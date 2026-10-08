# ==============================================================================
# CARDIOEDGE — Dedicated Firmware Simulation Filelist
# Target Testbench: tb_cardioedge_firmware
# Execute from: /home/student/Documents/HONOURS_CBP_CARDIOEDGE/run
# ==============================================================================

# Simulation Defines
+define+SIMULATION
+define+RV_BUILD_AXI4
+define+RV_FPGA_OPTIMIZE

# Top-Level Module Specification
-top tb_cardioedge_firmware

# Include Directories
+incdir+../rtl/Cores-VeeR-EL2/configs/snapshots/cardioedge
+incdir+../rtl/Cores-VeeR-EL2/design/include
+incdir+../rtl/uart/include
+incdir+../rtl/spi/include

# ==============================================================================
# 1. VeeR EL2 Core RTL Design Files
# ==============================================================================
../rtl/Cores-VeeR-EL2/configs/snapshots/cardioedge/common_defines.vh
../rtl/Cores-VeeR-EL2/design/include/el2_def.sv
../rtl/Cores-VeeR-EL2/design/lib/el2_assert.sv
../rtl/Cores-VeeR-EL2/design/el2_mubi_pkg.sv
../rtl/Cores-VeeR-EL2/design/el2_lockstep_pkg.sv
../rtl/Cores-VeeR-EL2/design/lib/el2_lib.sv
../rtl/Cores-VeeR-EL2/design/lib/el2_mem_if.sv
../rtl/Cores-VeeR-EL2/design/lib/el2_prim_generic_buf.sv
../rtl/Cores-VeeR-EL2/design/lib/el2_prim_buf.sv
../rtl/Cores-VeeR-EL2/design/lib/beh_lib.sv
../rtl/Cores-VeeR-EL2/design/lib/mem_lib.sv
../rtl/Cores-VeeR-EL2/design/lib/ahb_to_axi4.sv
../rtl/Cores-VeeR-EL2/design/lib/axi4_to_ahb.sv
../rtl/Cores-VeeR-EL2/design/el2_mem.sv
../rtl/Cores-VeeR-EL2/design/el2_pic_ctrl.sv
../rtl/Cores-VeeR-EL2/design/el2_dma_ctrl.sv
../rtl/Cores-VeeR-EL2/design/el2_pmp.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_aln_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_compress_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_ifc_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_bp_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_ic_mem.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_mem_ctl.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_iccm_mem.sv
../rtl/Cores-VeeR-EL2/design/ifu/el2_ifu.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec_decode_ctl.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec_gpr_ctl.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec_ib_ctl.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec_pmp_ctl.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec_tlu_ctl.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec_trigger.sv
../rtl/Cores-VeeR-EL2/design/dec/el2_dec.sv
../rtl/Cores-VeeR-EL2/design/exu/el2_exu_alu_ctl.sv
../rtl/Cores-VeeR-EL2/design/exu/el2_exu_mul_ctl.sv
../rtl/Cores-VeeR-EL2/design/exu/el2_exu_div_ctl.sv
../rtl/Cores-VeeR-EL2/design/exu/el2_exu.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_clkdomain.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_addrcheck.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_lsc_ctl.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_stbuf.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_bus_buffer.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_bus_intf.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_ecc.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_dccm_mem.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_dccm_ctl.sv
../rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_trigger.sv
../rtl/Cores-VeeR-EL2/design/dbg/el2_dbg.sv
../rtl/Cores-VeeR-EL2/design/dmi/dmi_mux.v
../rtl/Cores-VeeR-EL2/design/dmi/dmi_wrapper.v
../rtl/Cores-VeeR-EL2/design/dmi/dmi_jtag_to_core_sync.v
../rtl/Cores-VeeR-EL2/design/dmi/rvjtag_tap.v
../rtl/Cores-VeeR-EL2/design/el2_veer.sv
../rtl/Cores-VeeR-EL2/design/el2_veer_lockstep.sv
../rtl/Cores-VeeR-EL2/design/el2_veer_wrapper.sv

# ==============================================================================
# 2. Shared Group AXI 3x18 Interconnect Fabric
# ==============================================================================
../rtl/interconnect/arbiter.v
../rtl/interconnect/priority_encoder.v
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_3x18.v

# ==============================================================================
# 3. Common AXI Bridges & Adapters
# ==============================================================================
../rtl/common/axi4lite_slave_adapter.sv
../rtl/common/axi4_to_axi4lite_bridge.sv
../rtl/common/axi_dummy_slave.sv

# ==============================================================================
# 4. RISC-V SoC Top & Memory Subsystems
# ==============================================================================
../rtl/riscv/axi_64to32_adapter.sv
../rtl/riscv/axi_imem_slave.sv
../rtl/riscv/axi_dmem_slave.sv
../rtl/riscv/cardioedge_veer_wrapper.sv

# ==============================================================================
# 5. CARDIOEDGE Peripherals (M00 - M06)
# ==============================================================================
# UART (M00)
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/uart_receiver.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v

# GPIO (M01)
../rtl/gpio/gpio_bit.sv
../rtl/gpio/gpio_wrapper.sv
../rtl/gpio/gpio_regs.sv
../rtl/gpio/gpio_axi.sv

# TIMER (M02)
../rtl/timer/timer_core.sv
../rtl/timer/timer_regs.sv
../rtl/timer/timer_axi.sv

# FIR (M03)
../rtl/FIR/axis_fifo.v
../rtl/FIR/fir_axi_lite.v
../rtl/FIR/fir_dsp.v
../rtl/FIR/fir_top.v

# ADC (M04)
../rtl/ADC/adc_pkg.sv
../rtl/ADC/adc_fifo.sv
../rtl/ADC/adc_sample_acquisition.sv
../rtl/ADC/adc_sampling_scheduler.sv
../rtl/ADC/adc_registers.sv
../rtl/ADC/adc_axi_lite_slave.sv
../rtl/ADC/adc_controller.sv

# SPI (M05)
../rtl/spi/ratio_clk.v
../rtl/spi/spi_clk_gen.v
../rtl/spi/spi_ctrl.v
../rtl/spi/spi_exch_byte.v
../rtl/spi/spi_fifo.v
../rtl/spi/spi_valid_logic.v
../rtl/spi/axi_spi_ctrl.v
../rtl/spi/axi_spi_top.v

# QRS (M06)
../rtl/QRS/baseline_filter.v
../rtl/QRS/first_difference.v
../rtl/QRS/icg_generic.v
../rtl/QRS/moving_sum12.v
../rtl/QRS/moving_sum20.v
../rtl/QRS/pow2_normalizer.v
../rtl/QRS/rr_classifier.v
../rtl/QRS/schmitt_peak_detector.v
../rtl/QRS/search_back.v
../rtl/QRS/shannon_lut12.v
../rtl/QRS/square10.v
../rtl/QRS/ecg_wtsee_v6_top.v
../rtl/QRS/qrs_axi4_wrapper.v

# Integrated SoC Top Module
../rtl/riscv/cardioedge_cpu_soc_top.sv

# ==============================================================================
# 6. Standalone Firmware Verification Testbench (Loads .vhx dynamically)
# ==============================================================================
../firmware/tb_cardioedge_firmware.sv
