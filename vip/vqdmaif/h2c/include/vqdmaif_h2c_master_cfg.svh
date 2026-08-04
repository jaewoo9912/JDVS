`ifndef __VQDMAIF_H2C_MASTER_CFG_SVH__
`define __VQDMAIF_H2C_MASTER_CFG_SVH__

class vqdmaif_h2c_master_cfg extends vqdmaif_h2c_cfg;
  YesOrNo_t drv_hold_pl_at_non_vld = YES;
  int unsigned start_data_pending_cycle      = 0, end_data_pending_cycle      = 5;
  int unsigned start_status_pending_cycle    = 0, end_status_pending_cycle    = 5;
  int unsigned start_interrupt_pending_cycle = 0, end_interrupt_pending_cycle = 5;
  `uvm_object_utils(vqdmaif_h2c_master_cfg)
  function new(string name="vqdmaif_h2c_master_cfg");
    super.new(name);
    max_ot = 64;
  endfunction
endclass

`endif // __VQDMAIF_H2C_MASTER_CFG_SVH__
