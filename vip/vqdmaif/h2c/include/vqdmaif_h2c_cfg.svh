`ifndef __VQDMAIF_H2C_CFG_SVH__
`define __VQDMAIF_H2C_CFG_SVH__

class vqdmaif_h2c_cfg extends vbfm_agent_cfg;
  int max_ot = -1;
  DmaType_t dma_type = QDMA;
  vqdmaif_h2c_param param;
  vqdmaif_h2c_cfgdb_key cfgdb_key;
  YesOrNo_t performance_measure = YES;
  YesOrNo_t enable_coverage = YES;
  int DATA_SIZE;
  `uvm_object_utils(vqdmaif_h2c_cfg)
  function new(string name="vqdmaif_h2c_cfg");
    super.new(name);
  endfunction
  extern virtual function string getInfo();
  extern virtual function StringQ_t getInfoList();
  extern virtual function void finalize();
  extern function QdmaifH2cPortParam_t getPortParamStruct();
  extern virtual function YesOrNo_t isActiveAgt();
endclass


function YesOrNo_t vqdmaif_h2c_cfg::isActiveAgt(); return(this.param.isActiveAgt); endfunction

function void vqdmaif_h2c_cfg::finalize();
  super.finalize();
  if(this.param == null) `vmg_fatal_wrong_usage(this.get_name, $sformatf("finalize -- param == null"));
  this.DATA_SIZE = this.param.PARAM.PORT.DATA_WIDTH/8;
  this.max_ot = this.param.PARAM.PORT.MAX_NUM_OT;
endfunction:finalize

function string vqdmaif_h2c_cfg::getInfo();
  return($sformatf("%s param=[%s]", super.getInfo, this.param.getInfo));
endfunction:getInfo

function StringQ_t vqdmaif_h2c_cfg::getInfoList(); return(this.param.getInfoList); endfunction

function QdmaifH2cPortParam_t vqdmaif_h2c_cfg::getPortParamStruct(); return(this.param.PARAM.PORT); endfunction


`endif // __VQDMAIF_H2C_CFG_SVH__
