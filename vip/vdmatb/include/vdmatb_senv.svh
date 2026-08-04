`ifndef __VDMATB_SENV_SVH__
`define __VDMATB_SENV_SVH__



class vdmatb_senv extends vt4_senv;

  vdmatb_tcfg tcfg;
  vdma_mst_tcfg mst_tcfg;
  virtual vdmatb_vwrap_if vwrap_if; 

  vdma_st_h2c_mst st_h2c_mst;
  vdma_st_c2h_mst st_c2h_mst;
  vdma_mm_h2c_mst mm_h2c_mst;
  vdma_mm_c2h_mst mm_c2h_mst;
  local AxiSysEnv_t axi_env;

  vdmatb_vseqr vseqr;
  vdmatb_menv menv;

  vdma_st_h2c_sa_mon st_h2c_mon;
  vdma_st_c2h_sa_mon st_c2h_mon;
  vdma_mm_h2c_sa_mon mm_h2c_mon;
  vdma_mm_c2h_sa_mon mm_c2h_mon;
  
  `uvm_component_utils(vdmatb_senv)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // --------------------------------------- uvm
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  

  // --------------------------------------- vt4_senv-impl
  extern virtual protected function void declareExtendedCfg();
  extern virtual function void integrateMenv(vt4_menv me);


  // ------------------------- internal-impl
endclass:vdmatb_senv


function void vdmatb_senv::declareExtendedCfg();
  $cast(this.tcfg, this.m_tcfg); 
  this.mst_tcfg = this.tcfg.mst_tcfg;
endfunction:declareExtendedCfg


function void vdmatb_senv::build_phase(uvm_phase phase);
  string cfgdb_key;
  AxiPortParamList_t SP_PARAM_LIST;
  
  super.build_phase(phase);
  `vmg_get_cfgdb_at_me(string, "cfgdb_key", cfgdb_key)
  `vmg_get_cfgdb_at_me(virtual vdmatb_vwrap_if, $sformatf("%s_vwrap_if", cfgdb_key), this.vwrap_if)
 
  if(this.tcfg.getDmaIpType == ST) begin
    this.st_h2c_mst = VDMA_FACTORY.createStH2CMst(this, this.makeInstName("st_h2c_mst"), this.vwrap_if.s_h2c_dma, this.mst_tcfg, UVM_ACTIVE);
    this.st_c2h_mst = VDMA_FACTORY.createStC2HMst(this, this.makeInstName("st_c2h_mst"), this.vwrap_if.s_c2h_dma, this.mst_tcfg, UVM_ACTIVE);
    
    this.axi_env = VAXI_FACTORY.createAxiEnv_1slv(
   		this.makeInstName("axi_env"),
   		$sformatf("%s", this.m_tcfg.getCfgDbKey),
                        this.tcfg.getHostAxiPortParam(),
                        this
    );
    end
  else if(this.tcfg.getDmaIpType == MM) begin
    this.mm_h2c_mst = VDMA_FACTORY.createMmH2CMst(this, this.makeInstName("mm_h2c_mst"), this.vwrap_if.m_h2c_dma, this.mst_tcfg, UVM_ACTIVE);
    this.mm_c2h_mst = VDMA_FACTORY.createMmC2HMst(this, this.makeInstName("mm_c2h_mst"), this.vwrap_if.m_c2h_dma, this.mst_tcfg, UVM_ACTIVE);
    
    SP_PARAM_LIST = new[2];
  
    SP_PARAM_LIST[0] =  this.tcfg.getHostAxiPortParam();
    SP_PARAM_LIST[1] =  this.tcfg.getCardAxiPortParam();
   
    this.axi_env = VAXI_FACTORY.createAxiEnv_2slv(
      this.makeInstName("axi_env"),
      $sformatf("%s", this.m_tcfg.getCfgDbKey)
      , SP_PARAM_LIST,
      this);
    
    `vmg_set_cfgdb_anyone(virtual svt_axi_master_if, "card_axi", this.vwrap_if.axi_if.master_if[1])
    
  end 
  else
    this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but It is not supported", this.tcfg.getDmaIpType));
  
endfunction:build_phase
  


function void vdmatb_senv::connect_phase(uvm_phase phase);
  vdmatb_vseqr vseqr;
  
  super.connect_phase(phase);

  $cast(vseqr, this.m_vseqr);
  
  if(this.tcfg.getDmaIpType == ST) begin
    vseqr.st_h2c_mst   = this.st_h2c_mst;
    vseqr.st_c2h_mst   = this.st_c2h_mst;
    vseqr.host_seqr    = this.axi_env.slave[0].sequencer;
    
    $cast(this.st_h2c_mon, this.st_h2c_mst.mon);
    $cast(this.st_c2h_mon, this.st_c2h_mst.mon);
  end
  else if(this.tcfg.getDmaIpType == MM) begin
   vseqr.mm_h2c_mst    = this.mm_h2c_mst; 
   vseqr.mm_c2h_mst    = this.mm_c2h_mst; 
   vseqr.host_seqr     = this.axi_env.slave[0].sequencer;
   vseqr.card_seqr     = this.axi_env.slave[1].sequencer;
   
   $cast(this.mm_h2c_mon, this.mm_h2c_mst.mon);
   $cast(this.mm_c2h_mon, this.mm_c2h_mst.mon);
  end 
  else
    this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));

endfunction:connect_phase



task vdmatb_senv::run_phase(uvm_phase phase);
  fork
    super.run_phase(phase);
  join
endtask:run_phase



function void vdmatb_senv::integrateMenv(vt4_menv me);
  super.integrateMenv(me);
  $cast(this.menv, this.m_menv);
endfunction:integrateMenv





`endif // __VDMATB_SENV_SVH__
