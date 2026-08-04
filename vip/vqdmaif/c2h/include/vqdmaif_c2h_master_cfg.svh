`ifndef __VQDMAIF_C2H_MASTER_CFG_SVH__
`define __VQDMAIF_C2H_MASTER_CFG_SVH__

class vqdmaif_c2h_master_cfg extends vqdmaif_c2h_cfg;
  int unsigned start_status_pending_cycle    = 0, end_status_pending_cycle    = 10;
  int unsigned start_interrupt_pending_cycle = 0, end_interrupt_pending_cycle = 10;
  YesOrNo_t drv_hold_pl_at_non_vld = YES;

  `uvm_object_utils(vqdmaif_c2h_master_cfg)
  function new(string name="vqdmaif_c2h_master_cfg");
    super.new(name);
    max_ot=64;
  endfunction
endclass

`endif // __VQDMAIF_C2H_MASTER_CFG_SVH__
