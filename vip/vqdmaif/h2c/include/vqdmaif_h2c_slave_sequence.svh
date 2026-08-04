`ifndef __VQDMAIF_H2C_SLAVE_SEQUENCE_SVH__
`define __VQDMAIF_H2C_SLAVE_SEQUENCE_SVH__

class vqdmaif_h2c_slave_sequence extends vbfm_sequence#(.REQ(vqdmaif_h2c_slave_sequence_item));

  typedef vqdmaif_h2c_slave_sequence_item T_SEQ_ITEM;

  vqdmaif_h2c_slave_sequencer sqr;
  vqdmaif_h2c_slave_cfg cfg;
  vqdmaif_h2c_slave_sequence_item item;

  `uvm_object_utils(vqdmaif_h2c_slave_sequence)
  function new(string name="vqdmaif_h2c_slave_sequence");
    super.new(name);
    this.item = vqdmaif_h2c_slave_sequence_item::type_id::create($sformatf("%s.item", this.get_name));
  endfunction

  virtual function void set_sequencer(uvm_sequencer_base sequencer);
    super.set_sequencer(sequencer);
    $cast(this.sqr, sequencer);
    this.cfg = this.sqr.cfg;
    this.set_response_queue_error_report_disabled(1);
  endfunction

endclass


`endif //__VQDMAIF_H2C_SLAVE_SEQUENCE_SVH__
