class spi_monitor 
	extends uvm_monitor;

	virtual spi_if vif;

	uvm_analysis_port #(spi_item) ap;

	`uvm_component_utils(spi_monitor)

	function new(string n,uvm_component p);
	       	super.new(n,p); 
		ap=new("ap",this);
       	endfunction
endclass
