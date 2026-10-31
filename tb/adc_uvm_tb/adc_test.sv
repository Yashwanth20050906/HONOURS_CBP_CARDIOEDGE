class adc_test 
	extends uvm_test;

	adc_env env;

	`uvm_component_utils(adc_test)

	function new(string n,uvm_component p);
		super.new(n,p);
	endfunction

	function void build_phase(uvm_phase phase); 
		env=adc_env::type_id::create("env",this); 
	endfunction
endclass
