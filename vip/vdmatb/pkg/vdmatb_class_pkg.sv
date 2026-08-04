`ifndef __VDMATB_CLASS_PKG_SV__
`define __VDMATB_CLASS_PKG_SV__


package vdmatb_class_pkg;
  
  `vdmatb_import_core_pkg
  import vdmatb_pkg::*;


  // ---------------------------------------------------
  `include "vdmatb_macro.svh"
  `include "vdmatb_rptr.svh"



  // ---------------------------------------------------
  typedef class vdmatb_tcfg_factory;
  typedef class vdmatb_factory;


  `include "vdmatb_tcfg.svh"
  `include "vdmatb_scfg.svh"

  `include "vdmatb_host_seq_item.svh"
  `include "vdmatb_host_mon.svh"

  `include "vdmatb_host_seq.svh"
  `include "vdmatb_host_seq_lib.svh"

  `include "vdmatb_card_seq.svh"  
  `include "vdmatb_card_seq_lib.svh"

  `include "vdmatb_st_sb_cov_colctr.svh"
  `include "vdmatb_mm_sb_cov_colctr.svh"
  `include "vdmatb_sb.svh"
  `include "vdmatb_st_c2h_sb.svh"
  `include "vdmatb_st_h2c_sb.svh"
  `include "vdmatb_st_cov_colctr.svh"
  `include "vdmatb_mm_c2h_sb.svh"
  `include "vdmatb_mm_h2c_sb.svh"
  `include "vdmatb_mm_cov_colctr.svh"
  `include "vdmatb_menv.svh"

  `include "vdmatb_vseqr.svh"
  `include "vdmatb_senv.svh"
  `include "vdmatb_env_top.svh"

  `include "vdmatb_vseq.svh"
  `include "vdmatb_vseq_lib.svh"

  `include "vdmatb_test.svh"

  `include "vdmatb_fault_test.svh"
  `include "vdmatb_fault_test_lib.svh"

  `include "vdmatb_perf_test.svh"
  `include "vdmatb_perf_test_lib.svh"



  // ---------------------------------------------------
  `include "vdmatb_factory.svh"
  `include "vdmatb_tcfg_factory.svh"



endpackage:vdmatb_class_pkg


`endif // __VDMATB_CLASS_PKG_SV__
