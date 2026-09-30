# ADC IP VCS filelist
+incdir+./rtl
+incdir+./tb
+incdir+./tb/agents
+incdir+./tb/models
+incdir+./tb/tests

./rtl/adc_pkg.sv
./rtl/adc_fifo.sv
./rtl/adc_sample_acquisition.sv
./rtl/adc_sampling_scheduler.sv
./rtl/adc_registers.sv
./rtl/adc_axi_lite_slave.sv
./rtl/adc_controller.sv

./tb/agents/axi_lite_master_bfm.sv
./tb/models/adc_sample_source.sv

./tb/tests/adc_basic_test.sv
./tb/tests/adc_fifo_test.sv
./tb/tests/adc_interrupt_test.sv
./tb/tests/adc_reset_test.sv
./tb/tests/adc_axi_protocol_test.sv
./tb/tests/adc_periodic_test.sv

./tb/adc_tb.sv
