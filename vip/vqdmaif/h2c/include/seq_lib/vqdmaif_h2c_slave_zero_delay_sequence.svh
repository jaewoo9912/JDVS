`ifndef __VQDMAIF_H2C_SLAVE_ZERO_DELAY_SEQUENCE_SVH__
`define __VQDMAIF_H2C_SLAVE_ZERO_DELAY_SEQUENCE_SVH__

class vqdmaif_h2c_slave_zero_delay_sequence extends vqdmaif_h2c_slave_sequence;

  `uvm_object_utils(vqdmaif_h2c_slave_zero_delay_sequence)
  function new(string name="vqdmaif_h2c_slave_zero_delay_sequence");
    super.new(name);
  endfunction

  virtual function void set_sequencer(uvm_sequencer_base sequencer);
    super.set_sequencer(sequencer);
    this.cfg.default_bfm_timing_policy.start_fetch_latency = 0;  this.cfg.default_bfm_timing_policy.end_fetch_latency = 0;
    this.cfg.default_bfm_timing_policy.start_data_latency  = 0;  this.cfg.default_bfm_timing_policy.end_data_latency  = 0;
  endfunction

endclass

`endif // __VQDMAIF_H2C_SLAVE_ZERO_DELAY_SEQUENCE_SVH__
