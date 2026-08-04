`ifndef __VQDMAIF_C2H_MASTER_AGENT_SVH__
`define __VQDMAIF_C2H_MASTER_AGENT_SVH__

class vqdmaif_c2h_master_agent extends vbfm_agent;
  vqdmaif_c2h_master_cfg cfg;
  vqdmaif_c2h_master_driver drv;
  vqdmaif_c2h_monitor mon;
  vqdmaif_c2h_master_sequencer sqr;
  `uvm_component_utils(vqdmaif_c2h_master_agent)
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task waitIdle(string call_info);
	virtual function string decideReportFamilyId(); return("C2H_MST_AGT"); endfunction
endclass:vqdmaif_c2h_master_agent


function void vqdmaif_c2h_master_agent::build_phase(uvm_phase phase);
  virtual vqdmaif_c2h_if _vif;
  super.build_phase(phase);
  `vmg_get_cfgdb_at_me(vqdmaif_c2h_master_cfg, "cfg", this.cfg)
  `vmg_get_cfgdb_at_me(virtual vqdmaif_c2h_if, "vif", _vif);
  this.mon = vqdmaif_c2h_monitor::type_id::create("mon", this);
  `vmg_set_cfgdb_at_me(vqdmaif_c2h_cfg, this.mon.get_name, "cfg", this.cfg)
  `vmg_set_cfgdb_at_me(virtual vmg_clk_if, this.mon.get_name, "clk_vif", _vif.IF_clk);
  `vmg_set_cfgdb_at_me(virtual vqdmaif_c2h_if, this.mon.get_name, "vif", _vif)
  if(this.cfg.isActiveAgt == YES)begin
    this.drv = vqdmaif_c2h_master_driver::type_id::create("drv", this);
    `vmg_set_cfgdb_at_me(virtual vmg_clk_if, this.drv.get_name, "clk_vif", _vif.IF_clk);
    `vmg_set_cfgdb_at_me(virtual vqdmaif_c2h_if, this.drv.get_name, "vif", _vif)
    `vmg_set_cfgdb_at_me(vqdmaif_c2h_master_cfg, this.drv.get_name, "cfg", this.cfg)
    this.sqr = vqdmaif_c2h_master_sequencer::type_id::create("sqr", this);
    `vmg_set_cfgdb_at_me(virtual vqdmaif_c2h_if, this.sqr.get_name, "vif", _vif)
    `vmg_set_cfgdb_at_me(vqdmaif_c2h_master_cfg, this.sqr.get_name, "cfg", this.cfg)
  end
endfunction


function void vqdmaif_c2h_master_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if(this.cfg.isActiveAgt == YES) begin
    this.drv.seq_item_port.connect(this.sqr.seq_item_export);
  end
endfunction


task vqdmaif_c2h_master_agent::waitIdle(string call_info);
  if(this.cfg.isActiveAgt == YES) begin
    this.sqr.waitIdle(call_info);
    this.drv.waitIdle(call_info);
  end
  this.mon.waitIdle(call_info);
endtask : waitIdle

`endif // __VQDMAIF_C2H_MASTER_AGENT_SVH__
