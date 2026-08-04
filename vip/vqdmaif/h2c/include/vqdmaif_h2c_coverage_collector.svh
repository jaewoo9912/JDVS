`ifndef __VQDMAIF_H2C_COVERAGE_COLLECTOR_SVH__
`define __VQDMAIF_H2C_COVERAGE_COLLECTOR_SVH__

class vqdmaif_h2c_coverage_collector extends vmg_component;
  typedef vqdmaif_h2c_sub_transaction T_SUB_TRANS;
  typedef vqdmaif_h2c_transaction T_TRANS;
  typedef vqdmaif_h2c_cfg T_CFG;

  // CG_H2C_CMD is a package-scope type (vqdmaif_h2c_transaction_covergroup.svh),
  // constructed in end_of_elaboration with config-driven max_addr.
  CG_H2C_CMD CG_H2C_CMD;

  // ----------------------------
  covergroup CG_H2C_DATA with function sample(ref T_CFG cfg);
    option.per_instance = 1;
    `include "vqdmaif_h2c_data_coverpoints.svh"
  endgroup


  covergroup CG_H2C_GATHERING with function sample(ref T_TRANS h2c_trans, ref T_CFG cfg);
    option.per_instance = 1;
    `include "vqdmaif_h2c_gathering_coverpoints.svh"
  endgroup

  covergroup CG_H2C_OT with function sample(ref vqdmaif_h2c_cfg cfg, ref int ot_cnt);
    option.per_instance = 1;
    `include "vqdmaif_h2c_ot_coverpoints.svh"
  endgroup
  // ----------------------------
  T_CFG cfg;
  QdmaH2CData_t h2c_trans_data;


  `uvm_component_utils(vqdmaif_h2c_coverage_collector)
  function new(string name = "vqdmaif_h2c_coverage_collector", uvm_component parent = null);
    super.new(name, parent);
    CG_H2C_DATA      = new();
    CG_H2C_GATHERING = new();
    CG_H2C_OT        = new();
  endfunction

  extern virtual function void end_of_elaboration_phase(uvm_phase phase);

  extern function void sampleH2CTrans(T_TRANS trans);
  extern function void sampleCgData(T_TRANS trans);
  extern function void sampleOt(int ot_cnt);
endclass


function void vqdmaif_h2c_coverage_collector::end_of_elaboration_phase(uvm_phase phase);
  QdmaAddr_t max_addr;
  super.end_of_elaboration_phase(phase);
  `vmg_get_cfgdb_at_me(T_CFG, "cfg", this.cfg)

  max_addr = (QdmaAddr_t'(1) << this.cfg.param.PARAM.PORT.ADDR_WIDTH) - 1;
  CG_H2C_CMD = new(max_addr);
  CG_H2C_CMD      .set_inst_name($sformatf("%s.CG_H2C_CMD", this.get_full_name));
  CG_H2C_DATA     .set_inst_name($sformatf("%s.CG_H2C_DATA", this.get_full_name));
  CG_H2C_GATHERING.set_inst_name($sformatf("%s.CG_H2C_GATHERING", this.get_full_name));
  CG_H2C_OT       .set_inst_name($sformatf("%s.CG_H2C_OT", this.get_full_name));
endfunction : end_of_elaboration_phase


function void vqdmaif_h2c_coverage_collector::sampleH2CTrans(T_TRANS trans);
  foreach(trans.q_sub[i]) CG_H2C_CMD.sample(trans.q_sub[i], this.cfg);
  CG_H2C_GATHERING.sample(trans, this.cfg);
  this.sampleCgData(trans);
endfunction : sampleH2CTrans


function void vqdmaif_h2c_coverage_collector::sampleCgData(T_TRANS trans);
  for(int i = 0; i < trans.getNumData; i++) begin
    trans.getData(i, this.h2c_trans_data);
    CG_H2C_DATA.sample(this.cfg);
  end
endfunction : sampleCgData

function void vqdmaif_h2c_coverage_collector::sampleOt(int ot_cnt);
  CG_H2C_OT.sample(this.cfg, ot_cnt);
endfunction

`endif //  __VQDMAIF_H2C_COVERAGE_COLLECTOR_SVH__
