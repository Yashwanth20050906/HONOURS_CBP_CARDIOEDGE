class adc_env 
	extends uvm_env;

	adc_agent agent; 
	adc_scoreboard sb;

	`uvm_component_utils(adc_env)

	function new(string n,uvm_component p);
		super.new(n,p);
	endfunction

	function void build_phase(uvm_phase phase);
	       	agent=adc_agent::type_id::create("agent",this); 
		sb=adc_scoreboard::type_id::create("sb",this); 
	endfunction
endclass
