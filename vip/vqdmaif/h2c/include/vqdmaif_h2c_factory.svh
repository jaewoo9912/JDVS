`ifndef __VQDMAIF_H2C_FACTORY_SVH__
`define __VQDMAIF_H2C_FACTORY_SVH__

class vqdmaif_h2c_factory extends vmg_factory;
  function new(string name="vqdmaif_h2c_factory");
    super.new(name);
  endfunction
  extern function vqdmaif_h2c_master_cfg createMstCfg(string agt_name, string key, QdmaifH2cAgtParam_t PARAM);
  extern function vqdmaif_h2c_master_agent createMstAgt(string inst_name, uvm_component parent, vqdmaif_h2c_master_cfg cfg);
  extern function vqdmaif_h2c_slave_cfg createSlvCfg(string agt_name, string key, QdmaifH2cAgtParam_t PARAM);
  extern function vqdmaif_h2c_slave_agent createSlvAgt(string inst_name, uvm_component parent, vqdmaif_h2c_slave_cfg cfg);

  extern function vqdmaif_h2c_master_transaction_scenario_control_knob createMstTransSck(string inst_name, vbfm_agent_param param);
  extern function vqdmaif_h2c_master_random_sequence createMstRandomSeq(string inst_name, vqdmaif_h2c_master_cfg cfg, vqdmaif_h2c_master_transaction_scenario_control_knob sck=null);
  extern function vqdmaif_h2c_transaction_dispatch_sequence createTransDispatchSeq(string inst_name, vqdmaif_h2c_master_cfg cfg, vqdmaif_h2c_master_transaction_scenario_control_knob sck=null);
  extern function vqdmaif_h2c_sub_transaction createSubTrans(string inst_name, vqdmaif_h2c_cfg cfg, ref QdmaH2CCmd_t cmd_pl);
  extern function vqdmaif_h2c_transaction createTrans(string inst_name, vqdmaif_h2c_sub_transaction sub_trans);

endclass:vqdmaif_h2c_factory

vqdmaif_h2c_factory VQDMAIF_H2C_FACTORY = new("VQDMAIF_H2C_FACTORY");



function vqdmaif_h2c_master_cfg vqdmaif_h2c_factory::createMstCfg(string agt_name, string key, QdmaifH2cAgtParam_t PARAM);
  vqdmaif_h2c_master_cfg created;
  vqdmaif_h2c_param param;
  vqdmaif_h2c_cfgdb_key cfgdb_key;
  param = vqdmaif_h2c_param::type_id::create($sformatf("%s.param", agt_name));
  param.PARAM = PARAM;
  param.finalize();
  cfgdb_key = vqdmaif_h2c_cfgdb_key::type_id::create(key);
  cfgdb_key.finalize();
  created = vqdmaif_h2c_master_cfg::type_id::create($sformatf("%s.cfg", agt_name));
  created.param = param;
  created.cfgdb_key = cfgdb_key;
  created.finalize();
  return(created);
endfunction:createMstCfg


function vqdmaif_h2c_slave_cfg vqdmaif_h2c_factory::createSlvCfg(string agt_name, string key, QdmaifH2cAgtParam_t PARAM);
  vqdmaif_h2c_slave_cfg created;
  vqdmaif_h2c_param param;
  vqdmaif_h2c_cfgdb_key cfgdb_key;
  param = vqdmaif_h2c_param::type_id::create($sformatf("%s.param", agt_name));
  param.PARAM = PARAM;
  param.finalize();
  cfgdb_key = vqdmaif_h2c_cfgdb_key::type_id::create(key);
  cfgdb_key.finalize();
  created = vqdmaif_h2c_slave_cfg::type_id::create($sformatf("%s.cfg", agt_name));
  created.param = param;
  created.cfgdb_key = cfgdb_key;
  created.default_bfm_timing_policy = vqdmaif_h2c_slave_bfm_timing_policy::type_id::create($sformatf("%s.default_bfm_timing_policy", agt_name));
  created.finalize();
  return(created);
endfunction:createSlvCfg

function vqdmaif_h2c_slave_agent vqdmaif_h2c_factory::createSlvAgt(string inst_name, uvm_component parent, vqdmaif_h2c_slave_cfg cfg);
  vqdmaif_h2c_slave_agent created; 
  virtual vqdmaif_h2c_if vif;
  `vmg_get_cfgdb_at_this_parent(parent, virtual vqdmaif_h2c_if, cfg.cfgdb_key.getCfgDbField_Vif(), vif)
  `vmg_set_cfgdb_at_this_parent(parent, vqdmaif_h2c_slave_cfg, inst_name, "cfg", cfg)
  `vmg_set_cfgdb_at_this_parent(parent, virtual vqdmaif_h2c_if, inst_name, "vif", vif)
  created = vqdmaif_h2c_slave_agent::type_id::create(inst_name, parent);
  return(created);
endfunction:createSlvAgt



function vqdmaif_h2c_master_agent vqdmaif_h2c_factory::createMstAgt(string inst_name, uvm_component parent, vqdmaif_h2c_master_cfg cfg);
  vqdmaif_h2c_master_agent created; 
  virtual vqdmaif_h2c_if vif;
  `vmg_get_cfgdb_at_this_parent(parent, virtual vqdmaif_h2c_if, cfg.cfgdb_key.getCfgDbField_Vif(), vif)
  `vmg_set_cfgdb_at_this_parent(parent, vqdmaif_h2c_master_cfg, inst_name, "cfg", cfg)
  `vmg_set_cfgdb_at_this_parent(parent, virtual vqdmaif_h2c_if, inst_name, "vif", vif)
  created = vqdmaif_h2c_master_agent::type_id::create(inst_name, parent);
  return(created);
endfunction:createMstAgt


function vqdmaif_h2c_sub_transaction vqdmaif_h2c_factory::createSubTrans(string inst_name, vqdmaif_h2c_cfg cfg, ref QdmaH2CCmd_t cmd_pl);
  vqdmaif_h2c_sub_transaction created = vqdmaif_h2c_sub_transaction::type_id::create(inst_name);
  created.cfg = cfg;
  created.storeCmd(cmd_pl);
  return(created);
endfunction:createSubTrans


function vqdmaif_h2c_transaction vqdmaif_h2c_factory::createTrans(string inst_name, vqdmaif_h2c_sub_transaction sub_trans);
  vqdmaif_h2c_transaction created = vqdmaif_h2c_transaction::type_id::create(inst_name);
  created.cfg = sub_trans.cfg;
  created.addSubTrans(sub_trans);
  return(created);
endfunction:createTrans


function vqdmaif_h2c_master_transaction_scenario_control_knob vqdmaif_h2c_factory::createMstTransSck(string inst_name, vbfm_agent_param param);
  vqdmaif_h2c_master_transaction_scenario_control_knob created = vqdmaif_h2c_master_transaction_scenario_control_knob::type_id::create(inst_name);
  $cast(created.param, param);
  created.finalize();
  return(created);
endfunction:createMstTransSck


function vqdmaif_h2c_master_random_sequence vqdmaif_h2c_factory::createMstRandomSeq(string inst_name, vqdmaif_h2c_master_cfg cfg, vqdmaif_h2c_master_transaction_scenario_control_knob sck=null);
  vqdmaif_h2c_master_random_sequence created = vqdmaif_h2c_master_random_sequence::type_id::create(inst_name);
  if(sck != null) created.sck = sck;
  else            created.sck = this.createMstTransSck($sformatf("%s.sck", inst_name), cfg.param);
  return(created);
endfunction:createMstRandomSeq


function vqdmaif_h2c_transaction_dispatch_sequence vqdmaif_h2c_factory::createTransDispatchSeq(string inst_name, vqdmaif_h2c_master_cfg cfg, vqdmaif_h2c_master_transaction_scenario_control_knob sck=null);
  vqdmaif_h2c_transaction_dispatch_sequence created = vqdmaif_h2c_transaction_dispatch_sequence::type_id::create(inst_name);
  if(sck != null) created.sck = sck;
  else            created.sck = this.createMstTransSck($sformatf("%s.sck", inst_name), cfg.param);
  created.sck.makeDirectTestable();
  return(created);
endfunction:createTransDispatchSeq

`endif // __VQDMAIF_H2C_FACTORY_SVH__
