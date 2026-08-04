`ifndef __VQDMAIF_H2C_SLAVE_LONG_DELAY_SEQUENCE_SVH__
`define __VQDMAIF_H2C_SLAVE_LONG_DELAY_SEQUENCE_SVH__

class vqdmaif_h2c_slave_long_delay_sequence extends vqdmaif_h2c_slave_sequence;

  `uvm_object_utils(vqdmaif_h2c_slave_long_delay_sequence)
  function new(string name="vqdmaif_h2c_slave_long_delay_sequence");
    super.new(name);
  endfunction

  virtual function void set_sequencer(uvm_sequencer_base sequencer);
    super.set_sequencer(sequencer);
    this.cfg.default_bfm_timing_policy.start_fetch_latency = 300;  this.cfg.default_bfm_timing_policy.end_fetch_latency = 3000;
  endfunction

endclass


`endif // __VQDMAIF_H2C_SLAVE_LONG_DELAY_SEQUENCE_SVH__
