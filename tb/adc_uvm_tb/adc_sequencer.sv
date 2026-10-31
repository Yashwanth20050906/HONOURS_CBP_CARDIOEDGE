class adc_sequencer 
	extends uvm_sequencer #(adc_item);

	`uvm_component_utils(adc_sequencer)

	function new(string n,uvm_component p);
		super.new(n,p);
	endfunction
endclass
