module tb_top;
import uvm_pkg::*; import adc_pkguvm::*;
adc_if vif();
initial run_test("adc_test");
endmodule
