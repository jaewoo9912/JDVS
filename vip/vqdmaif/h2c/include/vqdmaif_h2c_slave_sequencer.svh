`ifndef __VQDMAIF_H2C_SLAVE_SEQUENCER_SVH__
`define __VQDMAIF_H2C_SLAVE_SEQUENCER_SVH__

class vqdmaif_h2c_slave_sequencer extends vbfm_sequencer#(vqdmaif_h2c_slave_sequence_item);

  vqdmaif_h2c_slave_cfg cfg;

  `uvm_component_utils(vqdmaif_h2c_slave_sequencer)
  function new(string name="vqdmaif_h2c_slave_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction

	extern virtual function void build_phase(uvm_phase phase);

	virtual function string decideReportFamilyId(); return("H2C_SLV_SQR"); endfunction

endclass:vqdmaif_h2c_slave_sequencer


function void vqdmaif_h2c_slave_sequencer::build_phase(uvm_phase phase);
  super.build_phase(phase);
  `vmg_get_cfgdb_at_me(vqdmaif_h2c_slave_cfg, "cfg", this.cfg)
endfunction



`endif // __VQDMAIF_H2C_SLAVE_SEQUENCER_SVH__
