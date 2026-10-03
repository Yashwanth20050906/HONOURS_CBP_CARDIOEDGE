# ============================================================
# CARDIOEDGE - UART + QRS + SPI + FIR + ADC + GPIO + TIMER
# Integrated AXI 3x14 SoC Verification
#
# Run from:
#   /home/student/Documents/HONOURS_CBP_CARDIOEDGE/run
# ============================================================

# GPIO simulation-only pull-up/pull-down model
+define+SIMULATION

# Include directories
+incdir+../rtl/uart/include
+incdir+../rtl/spi/include

# ============================================================
# AXI INTERCONNECT
# ============================================================
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_3x14.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/priority_encoder.v

# ============================================================
# COMMON AXI SUPPORT
#   axi4lite_slave_adapter   : AXI4-Lite -> register-bus (used by gpio_axi, timer_axi)
#   axi4_to_axi4lite_bridge  : AXI4 -> AXI4-Lite bridge (used by BRIDGED SoC top)
# ============================================================
../rtl/common/axi4lite_slave_adapter.sv
../rtl/common/axi4_to_axi4lite_bridge.sv

# ============================================================
# UART
# ============================================================
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/uart_receiver.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v

# ============================================================
# SPI
# ============================================================
../rtl/spi/ratio_clk.v
../rtl/spi/spi_clk_gen.v
../rtl/spi/spi_ctrl.v
../rtl/spi/spi_exch_byte.v
../rtl/spi/spi_fifo.v
../rtl/spi/spi_valid_logic.v
../rtl/spi/axi_spi_ctrl.v
../rtl/spi/axi_spi_top.v

# ============================================================
# QRS
# ============================================================
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

# ============================================================
# FIR
# ============================================================
../rtl/FIR/axis_fifo.v
../rtl/FIR/fir_axi_lite.v
../rtl/FIR/fir_dsp.v
../rtl/FIR/fir_top.v

# ============================================================
# ADC
# ============================================================
../rtl/ADC/adc_pkg.sv
../rtl/ADC/adc_fifo.sv
../rtl/ADC/adc_sample_acquisition.sv
../rtl/ADC/adc_sampling_scheduler.sv
../rtl/ADC/adc_registers.sv
../rtl/ADC/adc_axi_lite_slave.sv
../rtl/ADC/adc_controller.sv

# ============================================================
# GPIO - Gemini IP
# ============================================================
../rtl/gpio/gpio_bit.sv
../rtl/gpio/gpio_wrapper.sv
../rtl/gpio/gpio_regs.sv
../rtl/gpio/gpio_axi.sv

# ============================================================
# TIMER - Gemini IP
# ============================================================
../rtl/timer/timer_core.sv
../rtl/timer/timer_regs.sv
../rtl/timer/timer_axi.sv

# ============================================================
# INTEGRATED TOP
# ============================================================
../rtl/soc_uart_qrs_spi_fir_adc_gpio_timer_top_BRIDGED.sv

# ============================================================
# INTEGRATED TESTBENCH
# ============================================================
../tb/tb_soc_uart_qrs_spi_fir_adc_gpio_timer_top.sv
