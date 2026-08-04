`ifndef __VQDMAIF_C2H_FACTORY_SVH__
`define __VQDMAIF_C2H_FACTORY_SVH__

class vqdmaif_c2h_factory extends vmg_factory;

  function new(string name="vqdmaif_c2h_factory");
    super.new(name);
  endfunction

  extern function vqdmaif_c2h_master_cfg createMstCfg(string agt_name, string key, QdmaifC2hAgtParam_t PARAM);
  extern function vqdmaif_c2h_master_agent createMstAgt(string inst_name, uvm_component parent, vqdmaif_c2h_master_cfg cfg);
  extern function vqdmaif_c2h_slave_cfg createSlvCfg(string agt_name, string key, QdmaifC2hAgtParam_t PARAM);
  extern function vqdmaif_c2h_slave_agent createSlvAgt(string inst_name, uvm_component parent, vqdmaif_c2h_slave_cfg cfg);

  extern function vqdmaif_c2h_master_transaction_scenario_control_knob createMstTransSck(string inst_name, vbfm_agent_param param);
  extern function vqdmaif_c2h_master_random_sequence createMstRandomSeq(string inst_name, vqdmaif_c2h_master_cfg cfg, vqdmaif_c2h_master_transaction_scenario_control_knob sck=null);
  extern function vqdmaif_c2h_transaction_dispatch_sequence createTransDispatchSeq(string inst_name, vqdmaif_c2h_master_cfg cfg, vqdmaif_c2h_master_transaction_scenario_control_knob sck=null);
  extern function vqdmaif_c2h_transaction createTrans_ByDataPl(string inst_name, vqdmaif_c2h_cfg cfg, ref QdmaC2HData_t data_pl);
endclass:vqdmaif_c2h_factory

vqdmaif_c2h_factory VQDMAIF_C2H_FACTORY = new("VQDMAIF_C2H_FACTORY");


function vqdmaif_c2h_master_cfg vqdmaif_c2h_factory::createMstCfg(string agt_name, string key, QdmaifC2hAgtParam_t PARAM);
  vqdmaif_c2h_master_cfg created;
  vqdmaif_c2h_param param;
  vqdmaif_c2h_cfgdb_key cfgdb_key;
  param = vqdmaif_c2h_param::type_id::create($sformatf("%s.param", agt_name));
  param.PARAM = PARAM;
  param.finalize();
  cfgdb_key = vqdmaif_c2h_cfgdb_key::type_id::create(key);
  cfgdb_key.finalize();
  created = vqdmaif_c2h_master_cfg::type_id::create($sformatf("%s.cfg", agt_name));
  created.param = param;
  created.cfgdb_key = cfgdb_key;
  created.finalize();
  return(created);
endfunction:createMstCfg


function vqdmaif_c2h_slave_cfg vqdmaif_c2h_factory::createSlvCfg(string agt_name, string key, QdmaifC2hAgtParam_t PARAM);
  vqdmaif_c2h_slave_cfg created;
  vqdmaif_c2h_param param;
  vqdmaif_c2h_cfgdb_key cfgdb_key;
  param = vqdmaif_c2h_param::type_id::create($sformatf("%s.param", agt_name));
  param.PARAM = PARAM;
  param.finalize();
  cfgdb_key = vqdmaif_c2h_cfgdb_key::type_id::create(key);
  cfgdb_key.finalize();
  created = vqdmaif_c2h_slave_cfg::type_id::create($sformatf("%s.cfg", agt_name));
  created.param = param;
  created.cfgdb_key = cfgdb_key;
  created.default_bfm_timing_policy = vqdmaif_c2h_slave_bfm_timing_policy::type_id::create($sformatf("%s.default_bfm_timing_policy", agt_name));
  created.finalize();
  return(created);
endfunction:createSlvCfg


function vqdmaif_c2h_slave_agent vqdmaif_c2h_factory::createSlvAgt(string inst_name, uvm_component parent, vqdmaif_c2h_slave_cfg cfg);
  vqdmaif_c2h_slave_agent created; 
  virtual vqdmaif_c2h_if vif;
  `vmg_get_cfgdb_at_this_parent(parent, virtual vqdmaif_c2h_if, cfg.cfgdb_key.getCfgDbField_Vif(), vif)
  `vmg_set_cfgdb_at_this_parent(parent, vqdmaif_c2h_slave_cfg, inst_name, "cfg", cfg)
  `vmg_set_cfgdb_at_this_parent(parent, virtual vqdmaif_c2h_if, inst_name, "vif", vif)
  created = vqdmaif_c2h_slave_agent::type_id::create(inst_name, parent);
  return(created);
endfunction:createSlvAgt


function vqdmaif_c2h_master_agent vqdmaif_c2h_factory::createMstAgt(string inst_name, uvm_component parent, vqdmaif_c2h_master_cfg cfg);
  vqdmaif_c2h_master_agent created; 
  virtual vqdmaif_c2h_if vif;
  `vmg_get_cfgdb_at_this_parent(parent, virtual vqdmaif_c2h_if, cfg.cfgdb_key.getCfgDbField_Vif(), vif)
  `vmg_set_cfgdb_at_this_parent(parent, vqdmaif_c2h_master_cfg, inst_name, "cfg", cfg)
  `vmg_set_cfgdb_at_this_parent(parent, virtual vqdmaif_c2h_if, inst_name, "vif", vif)
  created = vqdmaif_c2h_master_agent::type_id::create(inst_name, parent);
  return(created);
endfunction:createMstAgt


function vqdmaif_c2h_master_random_sequence vqdmaif_c2h_factory::createMstRandomSeq(string inst_name, vqdmaif_c2h_master_cfg cfg, vqdmaif_c2h_master_transaction_scenario_control_knob sck=null);
  vqdmaif_c2h_master_random_sequence created = vqdmaif_c2h_master_random_sequence::type_id::create(inst_name);
  if(sck != null) created.sck = sck;
  else            created.sck = this.createMstTransSck($sformatf("%s.sck", inst_name), cfg.param);
  return(created);
endfunction:createMstRandomSeq


function vqdmaif_c2h_transaction_dispatch_sequence vqdmaif_c2h_factory::createTransDispatchSeq(string inst_name, vqdmaif_c2h_master_cfg cfg, vqdmaif_c2h_master_transaction_scenario_control_knob sck=null);
  vqdmaif_c2h_transaction_dispatch_sequence created = vqdmaif_c2h_transaction_dispatch_sequence::type_id::create(inst_name);
  if(sck != null) created.sck = sck;
  else            created.sck = this.createMstTransSck($sformatf("%s.sck", inst_name), cfg.param);
  created.sck.makeDirectTestable();
  return(created);
endfunction:createTransDispatchSeq


function vqdmaif_c2h_transaction vqdmaif_c2h_factory::createTrans_ByDataPl(string inst_name, vqdmaif_c2h_cfg cfg, ref QdmaC2HData_t data_pl);
  vqdmaif_c2h_transaction created = vqdmaif_c2h_transaction::type_id::create(inst_name);
  created.cfg = cfg;
  created.storeData(data_pl);
  return(created);
endfunction:createTrans_ByDataPl


function vqdmaif_c2h_master_transaction_scenario_control_knob vqdmaif_c2h_factory::createMstTransSck(string inst_name, vbfm_agent_param param);
  vqdmaif_c2h_master_transaction_scenario_control_knob created = vqdmaif_c2h_master_transaction_scenario_control_knob::type_id::create(inst_name);
  $cast(created.param, param);
  created.finalize();
  return(created);
endfunction:createMstTransSck



`endif // __VQDMAIF_C2H_FACTORY_SVH__
