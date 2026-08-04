`ifndef __VQDMAIF_C2H_SLAVE_SINGLE_TRANSACTION_SEQUENCE_SVH__
`define __VQDMAIF_C2H_SLAVE_SINGLE_TRANSACTION_SEQUENCE_SVH__


class vqdmaif_c2h_slave_single_transaction_sequence extends vqdmaif_c2h_slave_sequence;
  `uvm_object_utils(vqdmaif_c2h_slave_single_transaction_sequence)
  function new(string name="vqdmaif_c2h_slave_single_transaction_sequence");
    super.new(name);
  endfunction

  virtual task body();
    super.body;
    this.start_item(this.item);
    this.finish_item(this.item);
  endtask 
endclass





`endif // __VQDMAIF_C2H_SLAVE_SINGLE_TRANSACTION_SEQUENCE_SVH__
