`ifndef __VDMA_MST_TCFG_SVH__
`define __VDMA_MST_TCFG_SVH__


/*


   * DESIGN_NOTE
       A TCFG THAT COVERS WHOLE USE CASES, users set related parameters by using set* methods and gets the related parameters using get* methods
       and it's used across the whole MB-DMA verification components.

*/


class vdma_mst_tcfg extends vmg_tcfg;
  local DmaIpType_t dma_ip_type;
  
  StDmaDesignParam_t ST_DUT_PARAM;
  MmDmaDesignParam_t MM_DUT_PARAM;

  local StH2CDmaBfmTimingParam_t st_h2c_bfm_timing_param = DEFAULT_ST_H2C_DMA_BFM_TIMING_PARAM;
  local StC2HDmaBfmTimingParam_t st_c2h_bfm_timing_param = DEFAULT_ST_C2H_DMA_BFM_TIMING_PARAM;
  local MmH2CDmaBfmTimingParam_t mm_h2c_bfm_timing_param = DEFAULT_MM_H2C_DMA_BFM_TIMING_PARAM;
  local MmC2HDmaBfmTimingParam_t mm_c2h_bfm_timing_param = DEFAULT_MM_C2H_DMA_BFM_TIMING_PARAM;

  local YesOrNo_t was_set_st_dut_param            = NO;
  local YesOrNo_t was_set_st_h2c_bfm_timing_param = NO;
  local YesOrNo_t was_set_st_c2h_bfm_timing_param = NO;
  
  local YesOrNo_t was_set_mm_dut_param            = NO;
  local YesOrNo_t was_set_mm_h2c_bfm_timing_param = NO;
  local YesOrNo_t was_set_mm_c2h_bfm_timing_param = NO;
  
  TestScheme_t          tb_scheme;
  TestType_t            test_type;
  SelectFault_t         select_fault;
  YesOrNo_t             enable_pmon;
  FaultProb_t           fault_prob;
  RatioFaultInjection_t fault_ratio;
  DataDirectionType_t   data_direction_type;

  PerfTestCtrlKnob_t perf_ctrl_knob;

  YesOrNo_t is_sa = YES;

  
  `uvm_object_utils(vdma_mst_tcfg)
  function new(string name="vdma_mst_tcfg");
    super.new(name);
  endfunction

  extern virtual local function void chk();
  extern virtual local function StringQ_t getInfoList();
 
  extern function void setDmaIpType(DmaIpType_t dma_ip_type);
  extern function DmaIpType_t getDmaIpType();
 
  extern function void setStDmaDesignParam(StDmaDesignParam_t param);
  extern function void setStH2CDmaBfmTimingParam(StH2CDmaBfmTimingParam_t param);
  extern function void setStC2HDmaBfmTimingParam(StC2HDmaBfmTimingParam_t param);

  extern function StDmaDesignParam_t getStDmaDesignParam();
  extern function StH2CDmaBfmTimingParam_t getStH2CDmaBfmTimingParam();
  extern function StC2HDmaBfmTimingParam_t getStC2HDmaBfmTimingParam();

  extern function void setMmDmaDesignParam(MmDmaDesignParam_t param);
  extern function void setMmH2CDmaBfmTimingParam(MmH2CDmaBfmTimingParam_t param);
  extern function void setMmC2HDmaBfmTimingParam(MmC2HDmaBfmTimingParam_t param);

  extern function MmDmaDesignParam_t getMmDmaDesignParam();
  extern function MmH2CDmaBfmTimingParam_t getMmH2CDmaBfmTimingParam();
  extern function MmC2HDmaBfmTimingParam_t getMmC2HDmaBfmTimingParam();
  
  extern function StringQ_t makeStringList_DmaBfmTimingParam(DmaTransType_t trans_type);

  extern function int getDataSize(DmaTransType_t trans_type);

  extern function UIntRange_t getTimingParamDesc2Desc(DmaTransType_t trans_type);
  extern function UIntRange_t getTimingParamData2Data(DmaTransType_t trans_type);
  extern function UIntRange_t getTimingParamInterruptAssertRdy(DmaTransType_t trans_type);
  extern function UIntRange_t getTimingParamStatusAssertRdy(DmaTransType_t trans_type);
  extern function UIntRange_t getTimingParamFaultAssertRdy(DmaTransType_t trans_type);
  extern function UIntRange_t getTimingParamDataAssertRdy(DmaTransType_t trans_type);

  extern virtual function void finalizeCfg();
  extern virtual function void chkFinalCfg();

  extern function void setTbCfg(TestScheme_t tb_scheme, TestType_t test_type, SelectFault_t select_fault, YesOrNo_t enable_pmon, FaultProb_t fault_prob, RatioFaultInjection_t fault_ratio, DataDirectionType_t data_direction_type);

endclass:vdma_mst_tcfg



// TODO:Refactoring -- need delete vdmatb concept 
function void vdma_mst_tcfg::setTbCfg(TestScheme_t tb_scheme, TestType_t test_type, SelectFault_t select_fault, YesOrNo_t enable_pmon, FaultProb_t fault_prob, RatioFaultInjection_t fault_ratio, DataDirectionType_t data_direction_type);
  this.tb_scheme           = tb_scheme;
  this.test_type           = test_type;
  this.select_fault        = select_fault;
  this.enable_pmon         = enable_pmon;
  this.fault_prob          = fault_prob;
  this.fault_ratio         = fault_ratio;
  this.data_direction_type = data_direction_type;
endfunction:setTbCfg




function void vdma_mst_tcfg::finalizeCfg(); this.warningShouldChk("vdma_mst_tcfg::finalizeCfg"); endfunction
function void vdma_mst_tcfg::chkFinalCfg(); this.warningShouldChk("vdma_mst_tcfg::chkFinalCfg"); endfunction


function StH2CDmaBfmTimingParam_t vdma_mst_tcfg::getStH2CDmaBfmTimingParam(); return(this.st_h2c_bfm_timing_param); endfunction
function StC2HDmaBfmTimingParam_t vdma_mst_tcfg::getStC2HDmaBfmTimingParam(); return(this.st_c2h_bfm_timing_param); endfunction


function MmH2CDmaBfmTimingParam_t vdma_mst_tcfg::getMmH2CDmaBfmTimingParam(); return(this.mm_h2c_bfm_timing_param); endfunction
function MmC2HDmaBfmTimingParam_t vdma_mst_tcfg::getMmC2HDmaBfmTimingParam(); return(this.mm_c2h_bfm_timing_param); endfunction


function void vdma_mst_tcfg::chk();
  if(this.was_set_st_dut_param == NO && this.was_set_st_dut_param == NO)begin
    this.reportFatal("ILLEGAL_VDMA_MST_TCFG", "ST or MM type DUT parameters shall be set!!");
  end
endfunction:chk



function void vdma_mst_tcfg::setDmaIpType(DmaIpType_t dma_ip_type);
  this.dma_ip_type = dma_ip_type; 
endfunction : setDmaIpType


function ddma_pkg::DmaIpType_t vdma_mst_tcfg::getDmaIpType();
  return(this.dma_ip_type); 
endfunction : getDmaIpType


function void vdma_mst_tcfg::setStDmaDesignParam(StDmaDesignParam_t param);
  this.ST_DUT_PARAM = param;
  this.was_set_st_dut_param = YES;
endfunction:setStDmaDesignParam


function void vdma_mst_tcfg::setStH2CDmaBfmTimingParam(StH2CDmaBfmTimingParam_t param);
  this.st_h2c_bfm_timing_param = param;
  this.was_set_st_h2c_bfm_timing_param = YES;
endfunction:setStH2CDmaBfmTimingParam


function void vdma_mst_tcfg::setStC2HDmaBfmTimingParam(StC2HDmaBfmTimingParam_t param);
  this.st_c2h_bfm_timing_param = param;
  this.was_set_st_c2h_bfm_timing_param = YES;
endfunction:setStC2HDmaBfmTimingParam


function void vdma_mst_tcfg::setMmDmaDesignParam(MmDmaDesignParam_t param);
  this.MM_DUT_PARAM = param;
  this.was_set_mm_dut_param = YES;
endfunction:setMmDmaDesignParam


function void vdma_mst_tcfg::setMmH2CDmaBfmTimingParam(MmH2CDmaBfmTimingParam_t param);
  this.mm_h2c_bfm_timing_param = param;
  this.was_set_mm_h2c_bfm_timing_param = YES;
endfunction:setMmH2CDmaBfmTimingParam


function void vdma_mst_tcfg::setMmC2HDmaBfmTimingParam(MmC2HDmaBfmTimingParam_t param);
  this.mm_c2h_bfm_timing_param = param;
  this.was_set_mm_c2h_bfm_timing_param = YES;
endfunction:setMmC2HDmaBfmTimingParam


function ddma_pkg::StDmaDesignParam_t vdma_mst_tcfg::getStDmaDesignParam();
  return(this.ST_DUT_PARAM);  
endfunction : getStDmaDesignParam


function ddma_pkg::MmDmaDesignParam_t vdma_mst_tcfg::getMmDmaDesignParam();
  return(this.MM_DUT_PARAM);  
endfunction : getMmDmaDesignParam



function StringQ_t vdma_mst_tcfg::getInfoList();
  StringQ_t result, temp;

  if(this.was_set_st_dut_param == YES)begin
    temp.delete(); temp = MakeStringList_StDmaDesignParam_t(this.ST_DUT_PARAM);
    foreach(temp[i]) result.push_back(temp[i]);
  end
  if(this.was_set_st_h2c_bfm_timing_param == YES)begin
    temp.delete(); temp = MakeStringList_StH2CDmaBfmTimingParam_t(this.st_h2c_bfm_timing_param);
    foreach(temp[i]) result.push_back(temp[i]);
  end
  if(this.was_set_st_c2h_bfm_timing_param == YES)begin
    temp.delete(); temp = MakeStringList_StC2HDmaBfmTimingParam_t(this.st_c2h_bfm_timing_param);
    foreach(temp[i]) result.push_back(temp[i]);
  end
  if(this.was_set_mm_dut_param == YES)begin
    temp.delete(); temp = MakeStringList_MmDmaDesignParam_t(this.MM_DUT_PARAM);
    foreach(temp[i]) result.push_back(temp[i]);
  end
  if(this.was_set_mm_h2c_bfm_timing_param == YES)begin
    temp.delete(); temp = MakeStringList_MmH2CDmaBfmTimingParam_t(this.mm_h2c_bfm_timing_param);
    foreach(temp[i]) result.push_back(temp[i]);
  end
  if(this.was_set_mm_c2h_bfm_timing_param == YES)begin
    temp.delete(); temp = MakeStringList_MmC2HDmaBfmTimingParam_t(this.mm_c2h_bfm_timing_param);
    foreach(temp[i]) result.push_back(temp[i]);
  end
  return(result);
endfunction:getInfoList



function StringQ_t vdma_mst_tcfg::makeStringList_DmaBfmTimingParam(DmaTransType_t trans_type);
  case(trans_type)
    ST_H2C: return(MakeStringList_StH2CDmaBfmTimingParam_t(this.st_h2c_bfm_timing_param));
    ST_C2H: return(MakeStringList_StC2HDmaBfmTimingParam_t(this.st_c2h_bfm_timing_param));
    MM_H2C: return(MakeStringList_MmH2CDmaBfmTimingParam_t(this.mm_h2c_bfm_timing_param));
    MM_C2H: return(MakeStringList_MmC2HDmaBfmTimingParam_t(this.mm_c2h_bfm_timing_param));
  endcase
endfunction:makeStringList_DmaBfmTimingParam





function int vdma_mst_tcfg::getDataSize(DmaTransType_t trans_type);
  case(trans_type)
    ST_H2C: return(this.ST_DUT_PARAM.AXIS_DATA_WIDTH/8);
    ST_C2H: return(this.ST_DUT_PARAM.AXIS_DATA_WIDTH/8);
    MM_H2C: return(this.MM_DUT_PARAM.AXI_DATA_WIDTH/8);
    MM_C2H: return(this.MM_DUT_PARAM.AXI_DATA_WIDTH/8);
  endcase
endfunction:getDataSize




function UIntRange_t vdma_mst_tcfg::getTimingParamInterruptAssertRdy(DmaTransType_t trans_type);
  case(trans_type)
    ST_H2C: return(this.st_h2c_bfm_timing_param.interrupt_assert_rdy);
    ST_C2H: return(this.st_c2h_bfm_timing_param.interrupt_assert_rdy);
    MM_H2C: return(this.mm_h2c_bfm_timing_param.interrupt_assert_rdy);
    MM_C2H: return(this.mm_c2h_bfm_timing_param.interrupt_assert_rdy);
  endcase
endfunction:getTimingParamInterruptAssertRdy




function UIntRange_t vdma_mst_tcfg::getTimingParamDesc2Desc(DmaTransType_t trans_type);
  case(trans_type)
    ST_H2C: return(this.st_h2c_bfm_timing_param.desc2desc);
    ST_C2H: return(this.st_c2h_bfm_timing_param.desc2desc);
    MM_H2C: return(this.mm_h2c_bfm_timing_param.desc2desc);
    MM_C2H: return(this.mm_c2h_bfm_timing_param.desc2desc);
  endcase
endfunction:getTimingParamDesc2Desc



function UIntRange_t vdma_mst_tcfg::getTimingParamData2Data(DmaTransType_t trans_type);
  case(trans_type)
    ST_C2H  : return(this.st_c2h_bfm_timing_param.data2data);
    default : this.fatal("VMG_USAGE_ERROR", $sformatf("vdma_mst_tcfg::getTimingParamData2Data for \"%s\" not allowed !!", trans_type.name));
  endcase
endfunction:getTimingParamData2Data



function UIntRange_t vdma_mst_tcfg::getTimingParamStatusAssertRdy(DmaTransType_t trans_type);
  case(trans_type)
    ST_H2C: return(this.st_h2c_bfm_timing_param.status_assert_rdy);
    ST_C2H: return(this.st_c2h_bfm_timing_param.status_assert_rdy);
    MM_H2C: return(this.mm_h2c_bfm_timing_param.status_assert_rdy);
    MM_C2H: return(this.mm_c2h_bfm_timing_param.status_assert_rdy);
  endcase
endfunction:getTimingParamStatusAssertRdy




function UIntRange_t vdma_mst_tcfg::getTimingParamDataAssertRdy(DmaTransType_t trans_type);
  case(trans_type)
    ST_H2C  : return(this.st_h2c_bfm_timing_param.data_assert_rdy);
    default : this.fatal("VMG_USAGE_ERROR", $sformatf("vdma_mst_tcfg::getTimingParamDataAssertRdy for \"%s\" not allowed !!", trans_type.name));
  endcase
endfunction:getTimingParamDataAssertRdy




function UIntRange_t vdma_mst_tcfg::getTimingParamFaultAssertRdy(DmaTransType_t trans_type);
  case(trans_type)
    ST_H2C: return(this.st_h2c_bfm_timing_param.fault_assert_rdy);
    ST_C2H: return(this.st_c2h_bfm_timing_param.fault_assert_rdy);
    MM_H2C: return(this.mm_h2c_bfm_timing_param.fault_assert_rdy);
    MM_C2H: return(this.mm_c2h_bfm_timing_param.fault_assert_rdy);
  endcase
endfunction:getTimingParamFaultAssertRdy





`endif // __VDMA_MST_TCFG_SVH__
