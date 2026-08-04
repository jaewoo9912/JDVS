`ifndef __VDMATB_VSEQR_SVH__
`define __VDMATB_VSEQR_SVH__



class vdmatb_vseqr extends vt4_vseqr;

  vdmatb_tcfg tcfg;
  vdmatb_scfg scfg;

  vdma_st_h2c_mst   st_h2c_mst;
  vdma_st_c2h_mst   st_c2h_mst;
  vdma_mm_h2c_mst   mm_h2c_mst;
  vdma_mm_c2h_mst   mm_c2h_mst;
  AxiSlvSeqr_t      host_seqr;
  AxiSlvSeqr_t      card_seqr;

  vdmatb_menv menv;
  pdma_st_ip_c2h_mon_mngr st_c2h_pmon_mngr;
  pdma_st_ip_h2c_mon_mngr st_h2c_pmon_mngr;
  pdma_mm_ip_c2h_mon_mngr mm_c2h_pmon_mngr;
  pdma_mm_ip_h2c_mon_mngr mm_h2c_pmon_mngr;

  vdmatb_st_cov_colctr       st_cov_colctr;
  vdmatb_mm_cov_colctr       mm_cov_colctr;
  
  `uvm_component_utils(vdmatb_vseqr)
  function new (string name="vdmatb_vseqr", uvm_component parent=null);
    super.new(name, parent);
  endfunction:new         

  extern virtual protected function void declareExtendedCfg();

  extern virtual function void show(string prompt="");

  extern virtual function void integrateMenv(vt4_menv me);

endclass:vdmatb_vseqr



function void vdmatb_vseqr::declareExtendedCfg();
  $cast(this.tcfg, this.m_tcfg);
  $cast(this.scfg, this.m_scfg);
endfunction:declareExtendedCfg


function void vdmatb_vseqr::show(string prompt="");
  super.show(prompt);
  
  if(this.tcfg.getDmaIpType == ST) begin
    this.st_h2c_mst.show();
    this.st_c2h_mst.show();
  end
  else if(this.tcfg.getDmaIpType == MM) begin
    this.mm_h2c_mst.show();  
    this.mm_c2h_mst.show();  
  end
  else
    this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  
endfunction:show


function void vdmatb_vseqr::integrateMenv(vt4_menv me);
  super.integrateMenv(me);
  $cast(this.menv, this.m_menv);
  
  if(this.tcfg.getDmaIpType == ST) begin
    this.st_c2h_pmon_mngr = this.menv.st_c2h_pmon_mngr;
    this.st_h2c_pmon_mngr = this.menv.st_h2c_pmon_mngr;
    this.st_cov_colctr    = this.menv.st_cov_colctr;
  end
  else if(this.tcfg.getDmaIpType == MM) begin 
    this.mm_c2h_pmon_mngr = this.menv.mm_c2h_pmon_mngr;
    this.mm_h2c_pmon_mngr = this.menv.mm_h2c_pmon_mngr;
    this.mm_cov_colctr    = this.menv.mm_cov_colctr;
  end
  else
    this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
endfunction:integrateMenv


`endif // __VDMATB_VSEQR_SVH__
