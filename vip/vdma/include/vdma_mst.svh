`ifndef __VDMA_MST_SVH__
`define __VDMA_MST_SVH__


virtual class vdma_mst extends vmg_agent;
  local vdma_mst_tcfg   tcfg;

  vdma_mon        mon;
  vdma_mst_driver driver;
  vdma_mst_seqr   seqr;


  function new(string name="vdma_mst", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  // API
  extern function int getDataSize();


  // Internal -- shall be implemented
  pure virtual function DmaTransType_t getTransType();


  // Internal -- implemented 
  extern virtual function void connect_phase(uvm_phase phase);

  extern virtual function YesOrNo_t isBusy();
  extern virtual function void createMon();
  extern virtual function void createSeqr();
  extern virtual function void createDriver();
  extern virtual protected function void extractDbBeforeCreation();
  extern virtual function void show(string prompt="");

  extern local function void extractStH2CVif();
  extern local function void extractStC2HVif();
  extern local function void extractMmH2CVif();
  extern local function void extractMmC2HVif();
  extern local function void extractTcfg();


endclass:vdma_mst





function void vdma_mst::createMon();
  this.mon = VDMA_FACTORY.createMbDmaMonitor("mon", this.getTransType, this, this.tcfg.is_sa);
endfunction:createMon


function void vdma_mst::createSeqr();
  this.seqr = VDMA_FACTORY.createMbDmaMstSeqr("seqr", this.getTransType, this); 
endfunction:createSeqr


function void vdma_mst::createDriver();
  this.driver = VDMA_FACTORY.createMbDmaMstDriver("driver", this.getTransType, this); 
endfunction:createDriver



function void vdma_mst::extractDbBeforeCreation();
  this.extractTcfg();
  case(this.getTransType)
    ST_H2C: this.extractStH2CVif();
    ST_C2H: this.extractStC2HVif();
    MM_H2C: this.extractMmH2CVif();
    MM_C2H: this.extractMmC2HVif();
  endcase
endfunction:extractDbBeforeCreation



function void vdma_mst::extractStH2CVif();
  virtual ddma_st_h2c_if vif;

  `vmg_get_cfgdb_at_me(virtual ddma_st_h2c_if, "vif", vif)
  `vmg_set_cfgdb_under_me(virtual ddma_st_h2c_if, "vif", vif)
endfunction:extractStH2CVif



function void vdma_mst::extractStC2HVif();
  virtual ddma_st_c2h_if vif;

  `vmg_get_cfgdb_at_me(virtual ddma_st_c2h_if, "vif", vif)
  `vmg_set_cfgdb_under_me(virtual ddma_st_c2h_if, "vif", vif)
endfunction:extractStC2HVif




function void vdma_mst::extractMmH2CVif();
  virtual ddma_mm_h2c_if vif;

  `vmg_get_cfgdb_at_me(virtual ddma_mm_h2c_if, "vif", vif)
  `vmg_set_cfgdb_under_me(virtual ddma_mm_h2c_if, "vif", vif)
endfunction:extractMmH2CVif



function void vdma_mst::extractMmC2HVif();
  virtual ddma_mm_c2h_if vif;

  `vmg_get_cfgdb_at_me(virtual ddma_mm_c2h_if, "vif", vif)
  `vmg_set_cfgdb_under_me(virtual ddma_mm_c2h_if, "vif", vif)
endfunction:extractMmC2HVif



function void vdma_mst::extractTcfg();
  `vmg_get_cfgdb_at_me(vdma_mst_tcfg, "tcfg", this.tcfg)
  `vmg_set_cfgdb_under_me(vdma_mst_tcfg, "tcfg", this.tcfg)
endfunction:extractTcfg




function void vdma_mst::show(string prompt="");
  if(this.driver != null) this.driver.show(prompt);
  if(this.mon    != null) this.mon   .show(prompt);
  if(this.seqr   != null) this.seqr  .show(prompt);
endfunction:show



function int vdma_mst::getDataSize();
  return(this.mon.getDataSize);
endfunction:getDataSize



function void vdma_mst::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if(this.get_is_active)begin
    this.driver.seq_item_port.connect(this.seqr.seq_item_export);
    this.mon.ap.connect(this.driver.sub.analysis_export);
    this.driver.prepare(this.mon);
  end
endfunction:connect_phase




function YesOrNo_t vdma_mst::isBusy();
  if(this.driver != null) begin if(this.driver.isBusy() == YES) return(YES); end
  if(this.mon    != null) begin if(this.mon   .isBusy() == YES) return(YES); end

  return(NO);
endfunction:isBusy


`endif // __VDMA_MST_SVH__
