class spi_item 
	extends uvm_sequence_item;

  rand bit spi_clk_o;
  rand bit spi_cs_n_o;
  rand bit spi_mosi_o;
  bit spi_miso_i;

  `uvm_object_utils(spi_item)

  function new(string name="spi_item"); 
	  super.new(name);
  endfunction
endclass
