`ifndef __VQDMAIF_H2C_SLAVE_SINGLE_TRANSACTION_SEQUENCE_SVH__
`define __VQDMAIF_H2C_SLAVE_SINGLE_TRANSACTION_SEQUENCE_SVH__

class vqdmaif_h2c_slave_single_transaction_sequence extends vqdmaif_h2c_slave_sequence;
  `uvm_object_utils(vqdmaif_h2c_slave_single_transaction_sequence)
  function new(string name="vqdmaif_h2c_slave_single_transaction_sequence");
    super.new(name);
  endfunction

  virtual task body();
    super.body;

    this.start_item(this.item);
    this.finish_item(this.item);
  endtask
endclass







`endif // __VQDMAIF_H2C_SLAVE_SINGLE_TRANSACTION_SEQUENCE_SVH__
