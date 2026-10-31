class adc_item extends uvm_sequence_item;

  bit [11:0] sample_in;
  bit sample_valid;

  `uvm_object_utils(adc_item)

  function new(string name="adc_item"); 
	  super.new(name);
  endfunction
endclass
