class adc_monitor 
	extends uvm_monitor;

	virtual adc_if vif;

	uvm_analysis_port #(adc_item) ap;

	`uvm_component_utils(adc_monitor)

	function new(string n,uvm_component p); 
		super.new(n,p); 
		ap=new("ap",this);
       	endfunction
endclass
