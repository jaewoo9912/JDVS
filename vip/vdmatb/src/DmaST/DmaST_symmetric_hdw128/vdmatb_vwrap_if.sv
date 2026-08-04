`ifndef __VDMATB_VWRAP_IF_SV__
`define __VDMATB_VWRAP_IF_SV__


`include "svt_axi_if.svi"
//`include "svt_axi_stream_if.svi"
`include "svt_axi_master_param_if.svi"
`include "svt_axi_slave_param_if.svi"




interface vdmatb_vwrap_if;

  `vdmatb_import_core_pkg
  import vdmatb_vwrap_pkg::*;


  // -----------------------------------------------------------------------------
  // HOST
  // -----------------------------------------------------------------------------

  svt_axi_if axi_if(); 
  `vaxi_snps_active_mst_if(axi_if, m_host_axi, PORT0, HOST_AXI_PORT_PARAM)
  // -----------------------------------------------------------------------------
  // DUT-specific
  // -----------------------------------------------------------------------------
  ddma_st_h2c_if s_h2c_dma();
  ddma_st_c2h_if s_c2h_dma();
  ddma_mm_h2c_if m_h2c_dma();
  ddma_mm_c2h_if m_c2h_dma();
  
  daxi_if  paxi_if();
  
	typedef enum bit{
		NO,
		YES
	}DmaForceState_t;
	DmaForceState_t forced_rlast_state;

  function automatic void forceHostRLast_disable();
	  force m_host_axi.rlast = 1'b0;
	  forced_rlast_state = YES;
  endfunction:forceHostRLast_disable
  
  function automatic void forceHostRLast_Enable();
	  force m_host_axi.rlast = 1'b1;
	  forced_rlast_state = YES;
  endfunction:forceHostRLast_Enable
  
  function automatic void releaseHostRLast();
	  release m_host_axi.rlast;
	  forced_rlast_state = NO;
  endfunction:releaseHostRLast

  function automatic void forceCardRLast_disable(); endfunction:forceCardRLast_disable
  
  function automatic void forceCardRLast_Enable();  endfunction:forceCardRLast_Enable
  
  function automatic void releaseCardRLast();       endfunction:releaseCardRLast

endinterface:vdmatb_vwrap_if


`endif // __VDMATB_VWRAP_IF_SV__
