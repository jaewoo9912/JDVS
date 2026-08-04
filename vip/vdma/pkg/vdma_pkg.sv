`ifndef __VDMA_PKG_SV__
`define __VDMA_PKG_SV__


package vdma_pkg;



  // ---------------------------------------------------------------------
  // [CATEGORY] IMPOPT
  // ---------------------------------------------------------------------
  `vdma_import_core_pkg



  // ---------------------------------------------------------------------
  // [CATEGORY] MACRO/DEFS/UTILS
  // ---------------------------------------------------------------------
  `include "vip_common_macro.svh"
  `include "vdma_macro.svh"
  `include "vdma_defs.svh"
  `include "vdma_utils.svh"




  // ---------------------------------------------------------------------
  // [CATEGORY] CLASSES
  // ---------------------------------------------------------------------
  typedef class vdma_factory;

  `include "vdma_obj.svh"

  `include "vdma_seq_item.svh"
  `include "vdma_fault_seq_item.svh"
  `include "vdma_pkt_seq_item.svh"
  `include "vdma_card_axi_seq_item.svh" 

  `include "vdma_mst_tcfg.svh"

  `include "vdma_caxi_rd_mon.svh"
  `include "vdma_caxi_wr_mon.svh"
  `include "vdma_mon.svh"
  //`include "vdma_mm_mon.svh"
  `include "vdma_h2c_pkt_gathering_trkr.svh"
  `include "vdma_sa_mon.svh"
  `include "vdma_sa_st_mon.svh"
  `include "vdma_sa_mm_mon.svh"
  `include "vdma_st_h2c_sa_mon.svh"
  `include "vdma_st_c2h_sa_mon.svh"
  `include "vdma_nsa_mon.svh"
  `include "vdma_st_h2c_nsa_mon.svh"
  `include "vdma_st_c2h_nsa_mon.svh"

  `include "vdma_mm_h2c_sa_mon.svh"
  `include "vdma_mm_c2h_sa_mon.svh"

  `include "vdma_mst_driver.svh"
  `include "vdma_mst_seqr.svh"
  `include "vdma_mst.svh"
  `include "vdma_mst_seq.svh"

  `include "vdma_st_mst_seqr.svh"
  `include "vdma_mm_mst_seqr.svh"
  `include "vdma_st_mst_seq.svh"
  `include "vdma_mm_mst_seq.svh"

  `include "vdma_st_h2c_mst_driver.svh"
  `include "vdma_st_h2c_mst_seqr.svh"
  `include "vdma_st_h2c_mst.svh"
  `include "vdma_st_h2c_mst_seq.svh"
  `include "vdma_st_h2c_mst_perf_seq.svh"
  `include "vdma_st_h2c_seq_lib.svh"

  `include "vdma_st_c2h_mst_driver.svh"
  `include "vdma_st_c2h_mst_seqr.svh"
  `include "vdma_st_c2h_mst.svh"
  `include "vdma_st_c2h_mst_seq.svh"
  `include "vdma_st_c2h_mst_perf_seq.svh"
  `include "vdma_st_c2h_seq_lib.svh"

  `include "vdma_mm_h2c_mst_driver.svh"
  `include "vdma_mm_h2c_mst_seqr.svh"
  `include "vdma_mm_h2c_mst.svh"
  `include "vdma_mm_h2c_mst_seq.svh"
  `include "vdma_mm_h2c_mst_perf_seq.svh"
  `include "vdma_mm_h2c_seq_lib.svh"

  `include "vdma_mm_c2h_mst_driver.svh"
  `include "vdma_mm_c2h_mst_seqr.svh"
  `include "vdma_mm_c2h_mst.svh"
  `include "vdma_mm_c2h_mst_seq.svh"
  `include "vdma_mm_c2h_mst_perf_seq.svh"
  `include "vdma_mm_c2h_seq_lib.svh"

  `include "vdma_factory.svh"


endpackage:vdma_pkg


`endif // __VDMA_PKG_SV__
