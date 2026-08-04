`ifndef __VDMA_FACTORY_SVH__
`define __VDMA_FACTORY_SVH__




class vdma_factory extends vmg_factory;

  `uvm_object_utils(vdma_factory);

  function new(string name="vdma_factory");
    super.new(name);
  endfunction


  // ANDA_WORKING
  extern function vdma_st_h2c_mst createStH2CMst(vmg_env parent, string inst_name, virtual ddma_st_h2c_if vif, vdma_mst_tcfg tcfg, uvm_active_passive_enum is_active);
  extern function vdma_st_c2h_mst createStC2HMst(vmg_env parent, string inst_name, virtual ddma_st_c2h_if vif, vdma_mst_tcfg tcfg, uvm_active_passive_enum is_active);
  extern function vdma_mm_h2c_mst createMmH2CMst(vmg_env parent, string inst_name, virtual ddma_mm_h2c_if vif, vdma_mst_tcfg tcfg, uvm_active_passive_enum is_active);
  extern function vdma_mm_c2h_mst createMmC2HMst(vmg_env parent, string inst_name, virtual ddma_mm_c2h_if vif, vdma_mst_tcfg tcfg, uvm_active_passive_enum is_active);

  extern function vdma_mon createMbDmaMonitor(string name, DmaTransType_t trans_type, vmg_agent parent, YesOrNo_t is_sa);
  extern function vdma_mst_driver createMbDmaMstDriver(string name, DmaTransType_t trans_type, vmg_agent parent);
  extern function vdma_mst_seqr createMbDmaMstSeqr(string name, DmaTransType_t trans_type, vmg_agent parent);
  extern function vdma_mst_seq createMbDmaStMstSeq(SeqInfo_t seq_info, string full_name, vdma_mst h2c_mst, vdma_mst c2h_mst);
  extern function vdma_mst_seq createMbDmaMmMstSeq(SeqInfo_t seq_info, string full_name, vdma_mst h2c_mst, vdma_mst c2h_mst);

  extern function vdma_caxi_rd_mon createCaxiRdMon(vdma_mm_c2h_sa_mon parent, string inst_name, vdma_mst_tcfg tcfg);
  extern function vdma_caxi_wr_mon createCaxiWrMon(vdma_mm_h2c_sa_mon parent, string inst_name, vdma_mst_tcfg tcfg);
endclass:vdma_factory


vdma_factory VDMA_FACTORY = new("VDMA_FACTORY");



function vdma_st_h2c_mst vdma_factory::createStH2CMst(vmg_env parent, string inst_name, virtual ddma_st_h2c_if vif, vdma_mst_tcfg tcfg, uvm_active_passive_enum is_active);
  vdma_st_h2c_mst created;

  `vmg_set_cfgdb_at_this_parent(parent, virtual ddma_st_h2c_if,  inst_name, "vif",       vif)
  `vmg_set_cfgdb_at_this_parent(parent, vdma_mst_tcfg,           inst_name, "tcfg",      tcfg)
  `vmg_set_cfgdb_at_this_parent(parent, uvm_active_passive_enum, inst_name, "is_active", is_active)
  created = vdma_st_h2c_mst::type_id::create(inst_name, parent);
  return(created);
endfunction:createStH2CMst




function vdma_st_c2h_mst vdma_factory::createStC2HMst(vmg_env parent, string inst_name, virtual ddma_st_c2h_if vif, vdma_mst_tcfg tcfg, uvm_active_passive_enum is_active);
  vdma_st_c2h_mst created;

  `vmg_set_cfgdb_at_this_parent(parent, virtual ddma_st_c2h_if,  inst_name, "vif",       vif)
  `vmg_set_cfgdb_at_this_parent(parent, vdma_mst_tcfg,           inst_name, "tcfg",      tcfg)
  `vmg_set_cfgdb_at_this_parent(parent, uvm_active_passive_enum, inst_name, "is_active", is_active)
  created = vdma_st_c2h_mst::type_id::create(inst_name, parent);
  return(created);
endfunction:createStC2HMst





function vdma_mm_h2c_mst vdma_factory::createMmH2CMst(vmg_env parent, string inst_name, virtual ddma_mm_h2c_if vif, vdma_mst_tcfg tcfg, uvm_active_passive_enum is_active);
  vdma_mm_h2c_mst created;

  `vmg_set_cfgdb_at_this_parent(parent, virtual ddma_mm_h2c_if,  inst_name, "vif",       vif)
  `vmg_set_cfgdb_at_this_parent(parent, vdma_mst_tcfg,           inst_name, "tcfg",      tcfg)
  `vmg_set_cfgdb_at_this_parent(parent, uvm_active_passive_enum, inst_name, "is_active", is_active)
  created = vdma_mm_h2c_mst::type_id::create(inst_name, parent);
  return(created);
endfunction:createMmH2CMst




function vdma_mm_c2h_mst vdma_factory::createMmC2HMst(vmg_env parent, string inst_name, virtual ddma_mm_c2h_if vif, vdma_mst_tcfg tcfg, uvm_active_passive_enum is_active);
  vdma_mm_c2h_mst created;

  `vmg_set_cfgdb_at_this_parent(parent, virtual ddma_mm_c2h_if,  inst_name, "vif",       vif)
  `vmg_set_cfgdb_at_this_parent(parent, vdma_mst_tcfg,           inst_name, "tcfg",      tcfg)
  `vmg_set_cfgdb_at_this_parent(parent, uvm_active_passive_enum, inst_name, "is_active", is_active)
  created = vdma_mm_c2h_mst::type_id::create(inst_name, parent);
  return(created);
endfunction:createMmC2HMst





function vdma_mst_seq vdma_factory::createMbDmaStMstSeq(SeqInfo_t seq_info, string full_name, vdma_mst h2c_mst, vdma_mst c2h_mst);
  vdma_mst_seq created;
  DmaTransType_t trans_type;

  if(!$cast(created, this.createObjByTypeName(seq_info.type_name, seq_info.inst_name, full_name)))begin
    this.fatal("CREATE_VDMA_MST_ST_SEQ_FAILED", $sformatf("Failed to created dma commander sequence for \"%s\" !!", seq_info.type_name));
  end

  trans_type = created.getTransType();
  case(trans_type)
    ST_H2C  : created.setCfg(h2c_mst);
    ST_C2H  : created.setCfg(c2h_mst);
    default : begin
      created.show();
      this.fatal("CREATE_VDMA_MST_ST_SEQ_FAILED", $sformatf("trans_type=\"%s\" is not allowable for creation !!", trans_type.name));
    end
  endcase
  return(created);
endfunction:createMbDmaStMstSeq



function vdma_mst_seq vdma_factory::createMbDmaMmMstSeq(SeqInfo_t seq_info, string full_name, vdma_mst h2c_mst, vdma_mst c2h_mst);
  vdma_mst_seq created;
  DmaTransType_t trans_type;

  if(!$cast(created, this.createObjByTypeName(seq_info.type_name, seq_info.inst_name, full_name)))begin
    this.fatal("CREATE_VDMA_MST_MM_SEQ_FAILED", $sformatf("Failed to created dma commander sequence for \"%s\" !!", seq_info.type_name));
  end

  trans_type = created.getTransType();
  case(trans_type)
    MM_H2C  : created.setCfg(h2c_mst);
    MM_C2H  : created.setCfg(c2h_mst);
    default : begin
      created.show();
      this.fatal("CREATE_VDMA_MST_MM_SEQ_FAILED", $sformatf("trans_type=\"%s\" is not allowable for creation !!", trans_type.name));
    end
  endcase
  return(created);
endfunction:createMbDmaMmMstSeq





function vdma_mon vdma_factory::createMbDmaMonitor(string name, DmaTransType_t trans_type, vmg_agent parent, YesOrNo_t is_sa);
  case({is_sa, trans_type})
    {YES, ST_H2C} : return(vdma_st_h2c_sa_mon ::type_id::create(name, parent));
    {YES, ST_C2H} : return(vdma_st_c2h_sa_mon ::type_id::create(name, parent));
    { NO, ST_H2C} : return(vdma_st_h2c_nsa_mon::type_id::create(name, parent));
    { NO, ST_C2H} : return(vdma_st_c2h_nsa_mon::type_id::create(name, parent));
    {YES, MM_H2C} : return(vdma_mm_h2c_sa_mon ::type_id::create(name, parent));
    {YES, MM_C2H} : return(vdma_mm_c2h_sa_mon ::type_id::create(name, parent));
    // --------------------------------------------
    default: this.fatalShallImpl($sformatf("createMbDmaMonitor -- trans_type=%s", trans_type.name));
  endcase
endfunction:createMbDmaMonitor




function vdma_mst_driver vdma_factory::createMbDmaMstDriver(string name, DmaTransType_t trans_type, vmg_agent parent);
  case(trans_type)
    ST_H2C: return(vdma_st_h2c_mst_driver::type_id::create(name, parent));
    ST_C2H: return(vdma_st_c2h_mst_driver::type_id::create(name, parent));
    MM_H2C: return(vdma_mm_h2c_mst_driver::type_id::create(name, parent));
    MM_C2H: return(vdma_mm_c2h_mst_driver::type_id::create(name, parent));
    // --------------------------------------------
    default: this.fatalShallImpl($sformatf("createMbDmaMstDriver -- trans_type=%s", trans_type.name));
  endcase
endfunction:createMbDmaMstDriver





function vdma_mst_seqr vdma_factory::createMbDmaMstSeqr(string name, DmaTransType_t trans_type, vmg_agent parent);
  case(trans_type)
    ST_H2C: return(vdma_st_h2c_mst_seqr::type_id::create(name, parent));
    ST_C2H: return(vdma_st_c2h_mst_seqr::type_id::create(name, parent));
    MM_H2C: return(vdma_mm_h2c_mst_seqr::type_id::create(name, parent));
    MM_C2H: return(vdma_mm_c2h_mst_seqr::type_id::create(name, parent));
    // --------------------------------------------
    default: this.fatalShallImpl($sformatf("createMbDmaMstSeqr -- trans_type=%s", trans_type.name));
  endcase
endfunction:createMbDmaMstSeqr





function vdma_caxi_rd_mon vdma_factory::createCaxiRdMon(vdma_mm_c2h_sa_mon parent, string inst_name, vdma_mst_tcfg tcfg);
  vdma_caxi_rd_mon created;

  `vmg_set_cfgdb_at_this_parent(parent, vdma_mst_tcfg,             inst_name, "tcfg",     tcfg);
  created = vdma_caxi_rd_mon#()::type_id::create(inst_name, parent);
  return(created);
endfunction:createCaxiRdMon





function vdma_caxi_wr_mon vdma_factory::createCaxiWrMon(vdma_mm_h2c_sa_mon parent, string inst_name, vdma_mst_tcfg tcfg);
  vdma_caxi_wr_mon created;

  `vmg_set_cfgdb_at_this_parent(parent, vdma_mst_tcfg,             inst_name, "tcfg",     tcfg);
  created = vdma_caxi_wr_mon#()::type_id::create(inst_name, parent);
  return(created);
endfunction:createCaxiWrMon

`endif // __VDMA_FACTORY_SVH__
