# ============================================================
# CardioEdge UART + QRS + AXI 3x14 integration
# Run from: rtl/../run  (i.e. project/run)
# ============================================================

../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_3x14.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/priority_encoder.v

+incdir+../rtl/uart/include
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/uart_receiver.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v

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

../rtl/soc_uart_qrs_top.v
../tb/tb_soc_uart_qrs_top.sv
