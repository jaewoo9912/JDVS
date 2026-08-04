`ifndef __VDMATB_MENV_SVH__
`define __VDMATB_MENV_SVH__



class vdmatb_menv extends vt4_menv;

  protected string cfgdb_key;
  protected vdmatb_tcfg tcfg;
  protected virtual vdmatb_vwrap_if vwrap_if;

  vdma_st_h2c_mst  st_h2c_mst;
  vdma_st_c2h_mst  st_c2h_mst;
  vdma_mm_h2c_mst  mm_h2c_mst;
  vdma_mm_c2h_mst  mm_c2h_mst;

  vdmatb_st_h2c_sb   st_h2c_sb;
  vdmatb_st_c2h_sb   st_c2h_sb;
  vdmatb_mm_h2c_sb   mm_h2c_sb;
  vdmatb_mm_c2h_sb   mm_c2h_sb;

  vdmatb_host_mon    host_mon;
  vdma_mm_h2c_sa_mon mm_h2c_mon;
  vdma_mm_c2h_sa_mon mm_c2h_mon;
  
  pdma_st_ip_c2h_mon_mngr st_c2h_pmon_mngr;
  pdma_st_ip_h2c_mon_mngr st_h2c_pmon_mngr;
  pdma_mm_ip_c2h_mon_mngr mm_c2h_pmon_mngr;
  pdma_mm_ip_h2c_mon_mngr mm_h2c_pmon_mngr;
  
  vdmatb_st_cov_colctr st_cov_colctr;
  vdmatb_mm_cov_colctr mm_cov_colctr;
  
  
  `uvm_component_utils(vdmatb_menv)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // ------------------------------------------ uvm
  extern virtual function void build_phase(uvm_phase phase);


  // ------------------------------------------ vt4_menv-impl
  extern virtual protected function void declareExtendedCfg();
  extern virtual function YesOrNo_t isBusy();


  // ------------------------------------------ vdmatb_menv-api
  extern function void integrateDmaStMst(vdma_st_h2c_mst h2c_mst, vdma_st_c2h_mst c2h_mst);
  extern function void integrateDmaMmMst(vdma_mm_h2c_mst h2c_mst, vdma_mm_c2h_mst c2h_mst);

endclass:vdmatb_menv


function void vdmatb_menv::declareExtendedCfg();
  $cast(this.tcfg, this.m_tcfg);
endfunction:declareExtendedCfg


function YesOrNo_t vdmatb_menv::isBusy();
  if(this.tcfg.getDmaIpType == ST) begin
    if(this.st_h2c_sb.isBusy == YES) return(YES);
    if(this.st_c2h_sb.isBusy == YES) return(YES);
    if(this.host_mon.isBusy == YES)  return(YES);
  end
  else if(this.tcfg.getDmaIpType == MM) begin
    if(this.mm_h2c_sb.isBusy == YES)   return(YES); 
    if(this.mm_c2h_sb.isBusy == YES)   return(YES); 
    if(this.host_mon.isBusy == YES)    return(YES); 
    if(this.mm_h2c_mon.isBusy == YES)  return(YES); 
    if(this.mm_c2h_mon.isBusy == YES)  return(YES); 
  end
  else
    this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported", this.tcfg.getDmaIpType));
  
  return(NO);
endfunction:isBusy


function void vdmatb_menv::integrateDmaStMst(vdma_st_h2c_mst h2c_mst, vdma_st_c2h_mst c2h_mst);
  this.st_h2c_mst = h2c_mst;
  this.st_c2h_mst = c2h_mst;

  if(this.st_h2c_sb != null)begin
    this.st_h2c_mst.mon.ap_desc.connect(this.st_h2c_sb.ap_mst_desc);
    this.st_h2c_mst.mon.ap_data.connect(this.st_h2c_sb.ap_mst_data);
    this.st_h2c_mst.mon.ap_intr.connect(this.st_h2c_sb.ap_mst_intr);
    this.st_h2c_mst.mon.ap_status.connect(this.st_h2c_sb.ap_mst_status);
    this.st_h2c_mst.mon.ap_fault.connect(this.st_h2c_sb.ap_mst_fault);
    this.st_h2c_mst.mon.ap.connect(this.st_h2c_sb.ap_mst_completed);
    this.host_mon.ap_ar.connect(this.st_h2c_sb.ap_host_data);
  end

  if(this.st_c2h_sb != null)begin
    this.st_c2h_mst.mon.ap_desc.connect(this.st_c2h_sb.ap_mst_desc);
    this.st_c2h_mst.mon.ap_data.connect(this.st_c2h_sb.ap_mst_data);
    this.st_c2h_mst.mon.ap_intr.connect(this.st_c2h_sb.ap_mst_intr);
    this.st_c2h_mst.mon.ap_status.connect(this.st_c2h_sb.ap_mst_status);
    this.st_c2h_mst.mon.ap_fault.connect(this.st_c2h_sb.ap_mst_fault);
    this.st_c2h_mst.mon.ap.connect(this.st_c2h_sb.ap_mst_completed);
    this.host_mon.ap_aw.connect(this.st_c2h_sb.ap_host_data);
  end
endfunction:integrateDmaStMst



function void vdmatb_menv::integrateDmaMmMst(vdma_mm_h2c_mst h2c_mst, vdma_mm_c2h_mst c2h_mst);
  this.mm_h2c_mst = h2c_mst;
  this.mm_c2h_mst = c2h_mst;

  if(this.mm_h2c_sb != null)begin
    this.mm_h2c_mst.mon.ap_desc.connect(this.mm_h2c_sb.ap_mst_desc);
    this.mm_h2c_mst.mon.ap_data.connect(this.mm_h2c_sb.ap_mst_data);
    this.mm_h2c_mst.mon.ap_intr.connect(this.mm_h2c_sb.ap_mst_intr);
    this.mm_h2c_mst.mon.ap_status.connect(this.mm_h2c_sb.ap_mst_status);
    this.mm_h2c_mst.mon.ap_fault.connect(this.mm_h2c_sb.ap_mst_fault);
    this.mm_h2c_mst.mon.ap.connect(this.mm_h2c_sb.ap_mst_completed);
    $cast(this.mm_h2c_mon, this.mm_h2c_mst.mon);
    this.mm_h2c_mon.ap_wr.connect(this.mm_h2c_sb.ap_card_h2c_data);
    this.host_mon.ap_ar.connect(this.mm_h2c_sb.ap_host_data);
  end

  if(this.mm_c2h_sb != null)begin
    this.mm_c2h_mst.mon.ap_desc.connect(this.mm_c2h_sb.ap_mst_desc);
    this.mm_c2h_mst.mon.ap_data.connect(this.mm_c2h_sb.ap_mst_data);
    this.mm_c2h_mst.mon.ap_intr.connect(this.mm_c2h_sb.ap_mst_intr);
    this.mm_c2h_mst.mon.ap_status.connect(this.mm_c2h_sb.ap_mst_status);
    this.mm_c2h_mst.mon.ap_fault.connect(this.mm_c2h_sb.ap_mst_fault);
    this.mm_c2h_mst.mon.ap.connect(this.mm_c2h_sb.ap_mst_completed);
    $cast(this.mm_c2h_mon, this.mm_c2h_mst.mon);
    this.mm_c2h_mon.ap_rd.connect(this.mm_c2h_sb.ap_card_c2h_data);
    this.host_mon.ap_aw.connect(this.mm_c2h_sb.ap_host_data);
  end
endfunction:integrateDmaMmMst



function void vdmatb_menv::build_phase(uvm_phase phase);
  super.build_phase(phase);

  `vmg_get_cfgdb_at_me(string, "cfgdb_key", this.cfgdb_key)
  `vmg_get_cfgdb_at_me(virtual vdmatb_vwrap_if, $sformatf("%s_vwrap_if", this.cfgdb_key), this.vwrap_if)
  `vmg_set_cfgdb_anyone(virtual vdmatb_vwrap_if, $sformatf("%s_vwrap_if", this.cfgdb_key), this.vwrap_if)
  
  if(this.tcfg.getDmaIpType == ST) begin
    `vmg_get_cfgdb_at_me(pdma_st_ip_c2h_mon_mngr, $sformatf("%s_c2h_pmon_mngr", this.cfgdb_key), this.st_c2h_pmon_mngr)
    `vmg_get_cfgdb_at_me(pdma_st_ip_h2c_mon_mngr, $sformatf("%s_h2c_pmon_mngr", this.cfgdb_key), this.st_h2c_pmon_mngr)

    this.st_cov_colctr = vdmatb_st_cov_colctr::type_id::create();
  end
  else if(this.tcfg.getDmaIpType == MM) begin //TODO : Add handle about PMON and cov_colctr after PMON/cov_colctr implementation is complete.
    `vmg_get_cfgdb_at_me(pdma_mm_ip_c2h_mon_mngr, $sformatf("%s_c2h_pmon_mngr", this.cfgdb_key), this.mm_c2h_pmon_mngr)
    `vmg_get_cfgdb_at_me(pdma_mm_ip_h2c_mon_mngr, $sformatf("%s_h2c_pmon_mngr", this.cfgdb_key), this.mm_h2c_pmon_mngr)
//    
    this.mm_cov_colctr = vdmatb_mm_cov_colctr::type_id::create();
  end
  else
    this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));


  if(this.m_tcfg.enable_senv == NO)begin
    if(this.tcfg.getDmaIpType == ST) begin
      this.st_h2c_mst = VDMA_FACTORY.createStH2CMst(this, "st_h2c_mst", this.vwrap_if.s_h2c_dma, this.tcfg.mst_tcfg, UVM_PASSIVE);
      this.st_c2h_mst = VDMA_FACTORY.createStC2HMst(this, "st_c2h_mst", this.vwrap_if.s_c2h_dma, this.tcfg.mst_tcfg, UVM_PASSIVE);
    end
    else begin
      this.mm_h2c_mst = VDMA_FACTORY.createMmH2CMst(this, "mm_h2c_mst", this.vwrap_if.m_h2c_dma, this.tcfg.mst_tcfg, UVM_PASSIVE);
      this.mm_c2h_mst = VDMA_FACTORY.createMmC2HMst(this, "mm_c2h_mst", this.vwrap_if.m_c2h_dma, this.tcfg.mst_tcfg, UVM_PASSIVE);
    end
  end

  if(this.m_tcfg.enable_sb == YES)begin
    if(this.tcfg.getDmaIpType == ST) begin
      this.st_h2c_sb = VDMATB_FACTORY.createStH2CSb(this, this.makeInstName("h2c_sb"), this.tcfg);
      this.st_c2h_sb = VDMATB_FACTORY.createStC2HSb(this, this.makeInstName("c2h_sb"), this.tcfg);
      this.host_mon = VDMATB_FACTORY.createHostMon(this, this.makeInstName("host_mon"), this.vwrap_if, this.tcfg);
    end
    else begin
      this.mm_h2c_sb = VDMATB_FACTORY.createMmH2CSb(this, this.makeInstName("h2c_sb"), this.tcfg);
      this.mm_c2h_sb = VDMATB_FACTORY.createMmC2HSb(this, this.makeInstName("c2h_sb"), this.tcfg);
      this.host_mon = VDMATB_FACTORY.createHostMon(this, this.makeInstName("host_mon"), this.vwrap_if, this.tcfg);
    end
  end
endfunction:build_phase





`endif // __VDMATB_MENV_SVH__