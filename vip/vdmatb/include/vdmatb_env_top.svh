`ifndef __VDMATB_ENV_TOP_SVH__
`define __VDMATB_ENV_TOP_SVH__



class vdmatb_env_top extends vt4_env_top;

  local vdmatb_senv  senv;
  local vdmatb_menv  menv;
  
  local vdmatb_tcfg tcfg;

  `uvm_component_utils(vdmatb_env_top);

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  
  extern virtual protected function void declareExtendedCfg();
endclass


function void vdmatb_env_top::declareExtendedCfg();
  $cast(this.tcfg, this.m_tcfg);
endfunction : declareExtendedCfg


function void vdmatb_env_top::build_phase(uvm_phase phase);
  super.build_phase(phase);
  $cast(this.senv, this.m_senv);
  $cast(this.menv, this.m_menv);
endfunction:build_phase


function void vdmatb_env_top::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  if(this.tcfg.getDmaIpType == ST)       this.menv.integrateDmaStMst(this.senv.st_h2c_mst, this.senv.st_c2h_mst);
  else if(this.tcfg.getDmaIpType == MM)  this.menv.integrateDmaMmMst(this.senv.mm_h2c_mst, this.senv.mm_c2h_mst);
  else                                   this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
endfunction:connect_phase



`endif // __VDMATB_ENV_TOP_SVH__
