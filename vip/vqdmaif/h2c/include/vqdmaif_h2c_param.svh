`ifndef __VQDMAIF_H2C_PARAM_SVH__
`define __VQDMAIF_H2C_PARAM_SVH__

class vqdmaif_h2c_param extends vbfm_agent_param;
  QdmaifH2cAgtParam_t PARAM=UNDEFINED_QDMAIF_H2C_AGT_PARAM;
  `uvm_object_utils(vqdmaif_h2c_param)
  function new(string name="vqdmaif_h2c_param");
    super.new(name);
  endfunction
  extern virtual function StringQ_t getInfoList();
  extern virtual function void finalize();
  extern virtual function YesOrNo_t isActiveAgt();
endclass:vqdmaif_h2c_param

function StringQ_t vqdmaif_h2c_param::getInfoList(); return(MakeReport_QdmaifH2cAgtParam_t(this.PARAM)); endfunction

function void vqdmaif_h2c_param::finalize();
  if(this.PARAM == UNDEFINED_QDMAIF_H2C_AGT_PARAM) `vmg_fatal_wrong_usage("H2C_PARAM", $sformatf("finalize -- PARAM == UNDEFINED_QDMAIF_H2C_AGT_PARAM"));
endfunction:finalize

function YesOrNo_t vqdmaif_h2c_param::isActiveAgt();
  if(this.PARAM.IS_ACTIVE == UVM_ACTIVE) return(YES);
  return(NO);
endfunction:isActiveAgt

`endif // __VQDMAIF_H2C_PARAM_SVH__
