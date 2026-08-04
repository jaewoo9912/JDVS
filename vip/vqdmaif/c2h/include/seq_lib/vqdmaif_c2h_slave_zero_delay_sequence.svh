`ifndef __VQDMAIF_C2H_SLAVE_ZERO_DELAY_SEQUENCE_SVH__
`define __VQDMAIF_C2H_SLAVE_ZERO_DELAY_SEQUENCE_SVH__


class vqdmaif_c2h_slave_zero_delay_sequence extends vqdmaif_c2h_slave_sequence;
  `uvm_object_utils(vqdmaif_c2h_slave_zero_delay_sequence)
  function new(string name="vqdmaif_c2h_slave_zero_delay_sequence");
    super.new(name);
  endfunction

  virtual function void set_sequencer(uvm_sequencer_base sequencer);
    super.set_sequencer(sequencer);
    this.cfg.default_bfm_timing_policy.start_fetch_latency = 0;    this.cfg.default_bfm_timing_policy.end_fetch_latency = 0;
  endfunction
endclass

`endif // __VQDMAIF_C2H_SLAVE_ZERO_DELAY_SEQUENCE_SVH__
