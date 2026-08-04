`ifndef __VDMATB_FACTORY_SVH__
`define __VDMATB_FACTORY_SVH__




class vdmatb_factory extends vmg_factory;

  `uvm_object_utils(vdmatb_factory);

  function new(string name="vdmatb_factory");
    super.new(name);
  endfunction

  extern function vdmatb_host_mon createHostMon(vmg_env parent, string inst_name, virtual vdmatb_vwrap_if vwrap_if, vdmatb_tcfg tcfg);
  extern function vdma_mm_h2c_sa_mon createCardH2CMon(vmg_env parent, string inst_name, YesOrNo_t is_sa, virtual vdmatb_vwrap_if vwrap_if, vdma_mst_tcfg tcfg);
  extern function vdma_mm_c2h_sa_mon createCardC2HMon(vmg_env parent, string inst_name, YesOrNo_t is_sa, virtual vdmatb_vwrap_if vwrap_if, vdma_mst_tcfg tcfg);

  extern function vdmatb_st_h2c_sb createStH2CSb(vmg_env parent, string inst_name, vdmatb_tcfg tcfg);
  extern function vdmatb_st_c2h_sb createStC2HSb(vmg_env parent, string inst_name, vdmatb_tcfg tcfg);
  extern function vdmatb_mm_h2c_sb createMmH2CSb(vmg_env parent, string inst_name, vdmatb_tcfg tcfg);
  extern function vdmatb_mm_c2h_sb createMmC2HSb(vmg_env parent, string inst_name, vdmatb_tcfg tcfg);

endclass:vdmatb_factory


vdmatb_factory VDMATB_FACTORY = new("VDMATB_FACTORY");


function vdmatb_host_mon vdmatb_factory::createHostMon(vmg_env parent, string inst_name, virtual vdmatb_vwrap_if vwrap_if, vdmatb_tcfg tcfg);
  vdmatb_host_mon created;

  `vmg_set_cfgdb_at_this_parent(parent, virtual vdmatb_vwrap_if, inst_name, "vwrap_if", vwrap_if);
  `vmg_set_cfgdb_at_this_parent(parent, vdmatb_tcfg,             inst_name, "tcfg",     tcfg);
  created = vdmatb_host_mon::type_id::create(inst_name, parent);
  return(created);
endfunction:createHostMon


function vdma_mm_h2c_sa_mon vdmatb_factory::createCardH2CMon(vmg_env parent, string inst_name, YesOrNo_t is_sa, virtual vdmatb_vwrap_if vwrap_if, vdma_mst_tcfg tcfg);
  vdma_mm_h2c_sa_mon created;
  `vmg_set_cfgdb_at_this_parent(parent, virtual vdmatb_vwrap_if,   inst_name, "vwrap_if", vwrap_if);
  `vmg_set_cfgdb_at_this_parent(parent, virtual ddma_mm_h2c_if,    inst_name, "vif",      vwrap_if.m_h2c_dma);
  `vmg_set_cfgdb_at_this_parent(parent, virtual svt_axi_master_if, inst_name, "c_vif",    vwrap_if.axi_if.master_if[1]);
  `vmg_set_cfgdb_at_this_parent(parent, vdma_mst_tcfg,             inst_name, "tcfg",     tcfg);
  case(is_sa)
    YES    : created = vdma_mm_h2c_sa_mon ::type_id::create(inst_name, parent);
    default: this.fatalShallImpl($sformatf("createCardMon -- trans_type=%s", MM_H2C));
  endcase
  return(created);
endfunction:createCardH2CMon


function vdma_mm_c2h_sa_mon vdmatb_factory::createCardC2HMon(vmg_env parent, string inst_name, YesOrNo_t is_sa, virtual vdmatb_vwrap_if vwrap_if, vdma_mst_tcfg tcfg);
  vdma_mm_c2h_sa_mon created;
  `vmg_set_cfgdb_at_this_parent(parent, virtual vdmatb_vwrap_if,   inst_name, "vwrap_if", vwrap_if);
  `vmg_set_cfgdb_at_this_parent(parent, virtual ddma_mm_c2h_if,    inst_name, "vif",      vwrap_if.m_c2h_dma);
  `vmg_set_cfgdb_at_this_parent(parent, virtual svt_axi_master_if, inst_name, "c_vif",    vwrap_if.axi_if.master_if[1]);
  `vmg_set_cfgdb_at_this_parent(parent, vdma_mst_tcfg,             inst_name, "tcfg",     tcfg);
  case(is_sa)
    YES    : created = vdma_mm_c2h_sa_mon ::type_id::create(inst_name, parent);
    default: this.fatalShallImpl($sformatf("createCardMon -- trans_type=%s", MM_C2H));
  endcase
  return(created);
endfunction:createCardC2HMon


function vdmatb_st_h2c_sb vdmatb_factory::createStH2CSb(vmg_env parent, string inst_name, vdmatb_tcfg tcfg);
  vdmatb_st_h2c_sb created;

  `vmg_set_cfgdb_at_this_parent(parent, vdma_mst_tcfg, inst_name, "tcfg", tcfg.mst_tcfg);
  created = vdmatb_st_h2c_sb::type_id::create(inst_name, parent);
  return(created);
endfunction:createStH2CSb


function vdmatb_st_c2h_sb vdmatb_factory::createStC2HSb(vmg_env parent, string inst_name, vdmatb_tcfg tcfg);
  vdmatb_st_c2h_sb created;

  `vmg_set_cfgdb_at_this_parent(parent, vdma_mst_tcfg, inst_name, "tcfg", tcfg.mst_tcfg);
  created = vdmatb_st_c2h_sb::type_id::create(inst_name, parent);
  return(created);
endfunction:createStC2HSb


function vdmatb_mm_h2c_sb vdmatb_factory::createMmH2CSb(vmg_env parent, string inst_name, vdmatb_tcfg tcfg);
  vdmatb_mm_h2c_sb created;

  `vmg_set_cfgdb_at_this_parent(parent, vdma_mst_tcfg, inst_name, "tcfg", tcfg.mst_tcfg);
  created = vdmatb_mm_h2c_sb::type_id::create(inst_name, parent);
  return(created);
endfunction:createMmH2CSb


function vdmatb_mm_c2h_sb vdmatb_factory::createMmC2HSb(vmg_env parent, string inst_name, vdmatb_tcfg tcfg);
  vdmatb_mm_c2h_sb created;

  `vmg_set_cfgdb_at_this_parent(parent, vdma_mst_tcfg, inst_name, "tcfg", tcfg.mst_tcfg);
  created = vdmatb_mm_c2h_sb::type_id::create(inst_name, parent);
  return(created);
endfunction:createMmC2HSb


`endif // __VDMATB_FACTORY_SVH__
