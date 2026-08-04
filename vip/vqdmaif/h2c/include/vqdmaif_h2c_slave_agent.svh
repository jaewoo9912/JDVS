`ifndef __VQDMAIF_H2C_SLAVE_AGENT_SVH__
`define __VQDMAIF_H2C_SLAVE_AGENT_SVH__

class vqdmaif_h2c_slave_agent extends vbfm_agent;
  vqdmaif_h2c_slave_cfg cfg;
  vqdmaif_h2c_slave_driver drv;
  vqdmaif_h2c_slave_sequencer sqr;
  vqdmaif_h2c_monitor mon;
  `uvm_component_utils(vqdmaif_h2c_slave_agent)
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void setMemSvcr(vmem_if_svcr_behavior me);
  extern virtual task waitIdle(string call_info);
	virtual function string decideReportFamilyId(); return("H2C_SLV_AGT"); endfunction
endclass:vqdmaif_h2c_slave_agent

function void vqdmaif_h2c_slave_agent::build_phase(uvm_phase phase);
  virtual vqdmaif_h2c_if _vif;
  super.build_phase(phase);
  `vmg_get_cfgdb_at_me(vqdmaif_h2c_slave_cfg, "cfg", this.cfg)
  `vmg_get_cfgdb_at_me(virtual vqdmaif_h2c_if, "vif", _vif);
  this.mon = vqdmaif_h2c_monitor::type_id::create("mon", this);
  `vmg_set_cfgdb_at_me(virtual vmg_clk_if, this.mon.get_name, "clk_vif", _vif.IF_clk);
  `vmg_set_cfgdb_at_me(virtual vqdmaif_h2c_if, this.mon.get_name, "vif", _vif);
  `vmg_set_cfgdb_at_me(vqdmaif_h2c_cfg, this.mon.get_name, "cfg", cfg);
  if(this.cfg.isActiveAgt() == YES)begin
    this.drv = vqdmaif_h2c_slave_driver::type_id::create("drv", this);
    `vmg_set_cfgdb_at_me(virtual vmg_clk_if, this.drv.get_name, "clk_vif", _vif.IF_clk);
    `vmg_set_cfgdb_at_me(virtual vqdmaif_h2c_if, this.drv.get_name, "vif", _vif);
    `vmg_set_cfgdb_at_me(vqdmaif_h2c_slave_cfg, this.drv.get_name, "cfg", cfg);
    this.sqr = vqdmaif_h2c_slave_sequencer::type_id::create("sqr", this);
    uvm_config_db#(uvm_object_wrapper)::set(this, {sqr.get_name(), ".run_phase"}, "default_sequence", vqdmaif_h2c_slave_sequence::type_id::get());
    `vmg_set_cfgdb_at_me(vqdmaif_h2c_slave_cfg, this.sqr.get_name, "cfg", cfg);
  end
endfunction:build_phase

function void vqdmaif_h2c_slave_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if(this.cfg.isActiveAgt == YES)begin
    this.drv.seq_item_port.connect(this.sqr.seq_item_export);
    this.mon.ap_trans_cmd.connect(this.drv.impl_trans_cmd);
    this.mon.ap_bandwidth.connect(this.drv.bandwidth_port);
  end
endfunction:connect_phase

function void vqdmaif_h2c_slave_agent::setMemSvcr(vmem_if_svcr_behavior me);
  `vmg_info("MEM_SVCR_SETUP", $sformatf("setMemSvcr at @%s", this.get_full_name), UVM_LOW)
  if(this.sqr != null) this.drv.mem_svcr = me;
endfunction

task vqdmaif_h2c_slave_agent::waitIdle(string call_info);
  this.mon.waitIdle(call_info);
  if(this.cfg.isActiveAgt == YES) begin
    this.drv.waitIdle(call_info);
  end
endtask : waitIdle

`endif // __VQDMAIF_H2C_SLAVE_AGENT_SVH__
