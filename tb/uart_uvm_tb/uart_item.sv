class uart_item extends uvm_sequence_item;

  bit uart_rx_i;
  rand bit uart_tx_o;

  `uvm_object_utils(uart_item)

  function new(string name="uart_item"); super.new(name); endfunction
endclass
