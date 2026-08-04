`ifndef __VQDMAIF_C2H_PARAM_SVH__
`define __VQDMAIF_C2H_PARAM_SVH__

class vqdmaif_c2h_param extends vbfm_agent_param;
  QdmaifC2hAgtParam_t PARAM=UNDEFINED_QDMAIF_C2H_AGT_PARAM;
  `uvm_object_utils(vqdmaif_c2h_param)
  function new(string name="vqdmaif_c2h_param");
    super.new(name);
  endfunction
  extern virtual function StringQ_t getInfoList();
  extern virtual function void finalize();
  extern virtual function YesOrNo_t isActiveAgt();
endclass:vqdmaif_c2h_param

function StringQ_t vqdmaif_c2h_param::getInfoList(); return(MakeReport_QdmaifC2hAgtParam_t(this.PARAM)); endfunction

function void vqdmaif_c2h_param::finalize();
  if(this.PARAM == UNDEFINED_QDMAIF_C2H_AGT_PARAM) `vmg_fatal_wrong_usage("C2H_PARAM", $sformatf("finalize -- PARAM == UNDEFINED_QDMAIF_C2H_AGT_PARAM"));
endfunction:finalize

function YesOrNo_t vqdmaif_c2h_param::isActiveAgt();
  if(this.PARAM.IS_ACTIVE == UVM_ACTIVE) return(YES);
  return(NO);
endfunction:isActiveAgt

`endif // __VQDMAIF_C2H_PARAM_SVH__
