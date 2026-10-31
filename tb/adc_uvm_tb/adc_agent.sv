class adc_agent 
	extends uvm_agent;
	
	adc_driver drv;
       	adc_monitor mon;
       	adc_sequencer seqr;
	
	`uvm_component_utils(adc_agent)
	function new(string n,uvm_component p);
		super.new(n,p);
	endfunction
		
	function void build_phase(uvm_phase phase);
	       	drv=adc_driver::type_id::create("drv",this);
	       	mon=adc_monitor::type_id::create("mon",this); 
		seqr=adc_sequencer::type_id::create("seqr",this);
       	endfunction
	
	function void connect_phase(uvm_phase phase);
	       	drv.seq_item_port.connect(seqr.seq_item_export); 
	endfunction
	
endclass
