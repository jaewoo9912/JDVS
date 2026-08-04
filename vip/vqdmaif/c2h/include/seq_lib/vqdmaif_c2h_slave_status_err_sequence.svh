`ifndef __VQDMAIF_C2H_SLAVE_STATUS_ERR_SEQUENCE_SVH__
`define __VQDMAIF_C2H_SLAVE_STATUS_ERR_SEQUENCE_SVH__


class vqdmaif_c2h_slave_status_err_sequence extends vqdmaif_c2h_slave_sequence;
  `uvm_object_utils(vqdmaif_c2h_slave_status_err_sequence)
  function new(string name="vqdmaif_c2h_slave_zero_dly_data_sequence");
    super.new(name);
  endfunction
  virtual function void set_sequencer(uvm_sequencer_base sequencer);
    super.set_sequencer(sequencer);
    this.cfg.prob_status_error = 90;
  endfunction
endclass


`endif // __VQDMAIF_C2H_SLAVE_STATUS_ERR_SEQUENCE_SVH__
