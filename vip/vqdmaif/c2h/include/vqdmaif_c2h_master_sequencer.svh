`ifndef __VQDMAIF_C2H_MASTER_SEQUENCER_SVH__
`define __VQDMAIF_C2H_MASTER_SEQUENCER_SVH__

class vqdmaif_c2h_master_sequencer extends vbfm_sequencer#(.REQ(vqdmaif_c2h_master_sequence_item));
  vqdmaif_c2h_master_cfg cfg;
  `uvm_component_utils(vqdmaif_c2h_master_sequencer)
  function new(string name="vqdmaif_c2h_master_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task waitIdle(string call_info);
  extern function vqdmaif_c2h_master_transaction_scenario_control_knob createSck(string inst_name);
	virtual function string decideReportFamilyId(); return("C2H_MST_SQR"); endfunction
endclass


function void vqdmaif_c2h_master_sequencer::build_phase(uvm_phase phase);
  super.build_phase(phase);
  `vmg_get_cfgdb_at_me(vqdmaif_c2h_master_cfg, "cfg", this.cfg)
endfunction : build_phase


task vqdmaif_c2h_master_sequencer::waitIdle(string call_info); endtask : waitIdle

function vqdmaif_c2h_master_transaction_scenario_control_knob vqdmaif_c2h_master_sequencer::createSck(string inst_name);
  return(VQDMAIF_C2H_FACTORY.createMstTransSck(inst_name, this.cfg.param));
endfunction:createSck


`endif // __VQDMAIF_C2H_MASTER_SEQUENCER_SVH__
