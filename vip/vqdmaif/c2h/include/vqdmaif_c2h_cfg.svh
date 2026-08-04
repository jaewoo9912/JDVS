`ifndef __VQDMAIF_C2H_CFG_SVH__
`define __VQDMAIF_C2H_CFG_SVH__


class vqdmaif_c2h_cfg extends vbfm_agent_cfg;
  int unsigned max_ot=-1;
  DmaType_t dma_type = QDMA;
  vqdmaif_c2h_param param;
  vqdmaif_c2h_cfgdb_key cfgdb_key;
  YesOrNo_t report_unsup_status_err = YES;
  YesOrNo_t report_unsup_cmd_err = YES;
  YesOrNo_t report_unsup_cmd_pfch_tag = NO;
  YesOrNo_t performance_measure = YES;
  YesOrNo_t enable_coverage = YES;
  int DATA_SIZE;

  // * Assembling the fwd transfers for monitor
  //    After the reception of packed DATA beats, the slave keep waiting the matching CMD transaction 
  //    that triggered the data payload.
  int fwd_transfer_assemble_try_intvl=100; 
  int max_num_fwd_transfer_assemble_retry=5000;

  `uvm_object_utils(vqdmaif_c2h_cfg)
  function new(string name="vqdmaif_c2h_cfg");
    super.new(name);
  endfunction
  extern virtual function string getInfo();
  extern virtual function StringQ_t getInfoList();
  extern virtual function void finalize();
  extern virtual function YesOrNo_t isActiveAgt();
  extern function QdmaifC2hPortParam_t getPortParamStruct();
endclass

function void vqdmaif_c2h_cfg::finalize();
  if(this.param == null) `vmg_fatal_wrong_usage(this.get_name, $sformatf("finalize -- param == null"));
  this.DATA_SIZE = this.param.PARAM.PORT.DATA_WIDTH/8;
  this.max_ot = this.param.PARAM.PORT.MAX_NUM_OT;
endfunction:finalize

function string vqdmaif_c2h_cfg::getInfo();
  return($sformatf("%s param=[%s]", super.getInfo, param.getInfo));
endfunction
function StringQ_t vqdmaif_c2h_cfg::getInfoList(); return(this.param.getInfoList); endfunction
function YesOrNo_t vqdmaif_c2h_cfg::isActiveAgt(); return(this.param.isActiveAgt); endfunction

function QdmaifC2hPortParam_t vqdmaif_c2h_cfg::getPortParamStruct(); return(this.param.PARAM.PORT); endfunction

`endif // __VQDMAIF_C2H_CFG_SVH__
