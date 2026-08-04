`ifndef __VQDMAIF_C2H_COVERAGE_COLLECTOR_SVH__
`define __VQDMAIF_C2H_COVERAGE_COLLECTOR_SVH__

class vqdmaif_c2h_coverage_collector extends vmg_component;
  typedef vqdmaif_c2h_transaction T_TRANS;
  typedef vqdmaif_c2h_cfg T_CFG;

  // CG_C2H_TRANS is a package-scope type (vqdmaif_c2h_transaction_covergroup.svh),
  // constructed in end_of_elaboration with config-driven max_addr.
  CG_C2H_TRANS CG_C2H_TRANS;

  // ----------------------------
  covergroup CG_C2H_DATA with function sample(ref vqdmaif_c2h_cfg cfg);
    option.per_instance = 1;
    `include "vqdmaif_c2h_data_coverpoints.svh"
  endgroup

  covergroup CG_C2H_OT with function sample(ref vqdmaif_c2h_cfg cfg, ref int ot_cnt);
    option.per_instance = 1;
    `include "vqdmaif_c2h_ot_coverpoints.svh"
  endgroup
  // ----------------------------
  T_CFG cfg;
  QdmaC2HData_t c2h_trans_data;


  `uvm_component_utils(vqdmaif_c2h_coverage_collector)
  function new(string name = "vqdmaif_c2h_coverage_collector", uvm_component parent = null);
    super.new(name, parent);
    CG_C2H_DATA = new();
    CG_C2H_OT   = new();
  endfunction

  extern virtual function void end_of_elaboration_phase(uvm_phase phase);

  extern function void sampleC2HTrans(T_TRANS trans);
  extern function void sampleCgDataValue(T_TRANS trans);
  extern function void sampleOt(int ot_cnt);
endclass


function void vqdmaif_c2h_coverage_collector::end_of_elaboration_phase(uvm_phase phase);
  QdmaAddr_t max_addr;
  super.end_of_elaboration_phase(phase);
  `vmg_get_cfgdb_at_me(T_CFG, "cfg", this.cfg)

  max_addr = (QdmaAddr_t'(1) << this.cfg.param.PARAM.PORT.ADDR_WIDTH) - 1;
  CG_C2H_TRANS = new(max_addr);
  CG_C2H_TRANS.set_inst_name($sformatf("%s.CG_C2H_TRANS", this.get_full_name));
  CG_C2H_DATA .set_inst_name($sformatf("%s.CG_C2H_DATA", this.get_full_name));
  CG_C2H_OT   .set_inst_name($sformatf("%s.CG_C2H_OT", this.get_full_name));
endfunction : end_of_elaboration_phase


function void vqdmaif_c2h_coverage_collector::sampleC2HTrans(T_TRANS trans);
  CG_C2H_TRANS.sample(trans, this.cfg);
  this.sampleCgDataValue(trans);
endfunction : sampleC2HTrans


function void vqdmaif_c2h_coverage_collector::sampleCgDataValue(T_TRANS trans);
  foreach(trans.q_data_pl[i]) begin
    this.c2h_trans_data = trans.q_data_pl[i];
    CG_C2H_DATA.sample(this.cfg);
  end
endfunction : sampleCgDataValue

function void vqdmaif_c2h_coverage_collector::sampleOt(int ot_cnt);
  CG_C2H_OT.sample(this.cfg, ot_cnt);
endfunction : sampleOt




`endif //  __VQDMAIF_C2H_COVERAGE_COLLECTOR_SVH__
