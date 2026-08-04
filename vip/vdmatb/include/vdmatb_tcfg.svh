`ifndef __VDMATB_TCFG_SVH__
`define __VDMATB_TCFG_SVH__


class vdmatb_tcfg extends vt4_tcfg;

  local DmaIpType_t dma_ip_type;

  local StDmaDesignParam_t ST_DUT_PARAM; 
  local StDmaDesignParam_t MM_DUT_PARAM; 
  local AxiPortParam_t     HOST_AXI_PORT_PARAM = UNDEFINED_AXI_PORT_PARAM;
  local AxiPortParam_t     CARD_AXI_PORT_PARAM = UNDEFINED_AXI_PORT_PARAM;

  TestScheme_t          tb_scheme;
  TestType_t            test_type;
  SelectFault_t         select_fault;
  YesOrNo_t             enable_pmon;
  FaultProb_t           fault_prob;
  RatioFaultInjection_t fault_ratio;
  DataDirectionType_t   data_direction_type;

  vdma_mst_tcfg mst_tcfg;

  `uvm_object_utils(vdmatb_tcfg)

  function new(string name="vdmatb_tcfg");
    super.new(name);
    this.enable_sb = YES;
  endfunction


  // -------------------------------------- vdmatb_tcfg-api
  extern function void setDmaIpType(DmaIpType_t dma_ip_type);
  extern function DmaIpType_t getDmaIpType();
  
  extern function void setStDmaDutParam(StDmaDesignParam_t ST_DUT_PARAM);
  extern function void setMmDmaDutParam(MmDmaDesignParam_t MM_DUT_PARAM);
  extern function StDmaDesignParam_t getStDmaDutParam();
  extern function MmDmaDesignParam_t getMmDmaDutParam();
  extern function void setHostAxiPortParam(AxiPortParam_t HOST_AXI_PORT_PARAM);
  extern function AxiPortParam_t getHostAxiPortParam();
  extern function void setCardAxiPortParam(AxiPortParam_t CARD_AXI_PORT_PARAM);
  extern function AxiPortParam_t getCardAxiPortParam();

  // TODO:Primitive obsession
  extern function void setTbCfg(TestScheme_t tb_scheme, TestType_t test_type, SelectFault_t select_fault, YesOrNo_t enable_pmon, FaultProb_t fault_prob, RatioFaultInjection_t fault_ratio, DataDirectionType_t data_direction_type);
  extern function void showTbCfg();
  


  //------------------------------------ vmg_tcfg-impl
  extern virtual function void finalizeCfg();
  extern virtual function void chkFinalCfg();
  

  
endclass:vdmatb_tcfg

function void vdmatb_tcfg::finalizeCfg(); endfunction : finalizeCfg
function void vdmatb_tcfg::chkFinalCfg(); endfunction : chkFinalCfg


function void vdmatb_tcfg::setDmaIpType(DmaIpType_t dma_ip_type);
  this.dma_ip_type = dma_ip_type;  
endfunction : setDmaIpType

function ddma_pkg::DmaIpType_t vdmatb_tcfg::getDmaIpType();
  return(this.dma_ip_type);  
endfunction : getDmaIpType


function void vdmatb_tcfg::setStDmaDutParam(StDmaDesignParam_t ST_DUT_PARAM);
  this.ST_DUT_PARAM = ST_DUT_PARAM;
endfunction : setStDmaDutParam

function ddma_pkg::StDmaDesignParam_t vdmatb_tcfg::getStDmaDutParam();
  return(this.ST_DUT_PARAM);  
endfunction : getStDmaDutParam


function void vdmatb_tcfg::setMmDmaDutParam(MmDmaDesignParam_t MM_DUT_PARAM);
  this.MM_DUT_PARAM = MM_DUT_PARAM;
endfunction : setMmDmaDutParam

function ddma_pkg::MmDmaDesignParam_t vdmatb_tcfg::getMmDmaDutParam();
  return(this.MM_DUT_PARAM);  
endfunction : getMmDmaDutParam


function void vdmatb_tcfg::setHostAxiPortParam(AxiPortParam_t HOST_AXI_PORT_PARAM);
  this.HOST_AXI_PORT_PARAM = HOST_AXI_PORT_PARAM; 
endfunction:setHostAxiPortParam

function AxiPortParam_t vdmatb_tcfg::getHostAxiPortParam();
  return(this.HOST_AXI_PORT_PARAM); 
endfunction:getHostAxiPortParam


function void vdmatb_tcfg::setCardAxiPortParam(AxiPortParam_t CARD_AXI_PORT_PARAM);
  this.CARD_AXI_PORT_PARAM = CARD_AXI_PORT_PARAM; 
endfunction:setCardAxiPortParam

function AxiPortParam_t vdmatb_tcfg::getCardAxiPortParam();
  return(this.CARD_AXI_PORT_PARAM); 
endfunction:getCardAxiPortParam


function void vdmatb_tcfg::setTbCfg(TestScheme_t tb_scheme, TestType_t test_type, SelectFault_t select_fault, YesOrNo_t enable_pmon, FaultProb_t fault_prob, RatioFaultInjection_t fault_ratio, DataDirectionType_t data_direction_type);
  this.tb_scheme                         = tb_scheme;
  this.test_type                         = test_type;
  this.select_fault                      = select_fault;
  this.enable_pmon                       = enable_pmon;
  this.fault_prob                        = fault_prob;
  this.fault_ratio                       = fault_ratio;
  this.data_direction_type.only_c2h_test = data_direction_type.only_c2h_test;
  this.data_direction_type.only_h2c_test = data_direction_type.only_h2c_test;
  this.showTbCfg();

  this.mst_tcfg.setTbCfg(tb_scheme, test_type, select_fault, enable_pmon, fault_prob, fault_ratio, data_direction_type);
endfunction:setTbCfg


function void vdmatb_tcfg::showTbCfg();
  this.info($sformatf("_______________________________________________________________________"));
  this.info($sformatf("                                                                       "));
  this.info($sformatf("                   MB_DMA_STANDALONE_TB_CONFIGURATION                  "));
  this.info($sformatf("_______________________________________________________________________"));
  this.info($sformatf("                                                                       "));
  this.info($sformatf(" * tb_scheme    : %s", this.tb_scheme.name));
  this.info($sformatf(" * test_type    : %s", this.test_type.name));
  this.info($sformatf(" * enable_pmon  : %s", this.enable_pmon.name));
  this.info($sformatf("-----------------------------------------------------------------------"));
  this.info($sformatf(" * Fault related"));
  this.info($sformatf("    - fault_prob   : %1.2f%%", this.fault_prob));
  this.info($sformatf("    - select_fault : %s", this.select_fault.name));
  this.info($sformatf("    - fault_ratio"));
  this.info($sformatf("        > WEIGHT_DESC_DATA_LENGTH_IS_ZERO            : %1d%%", this.fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO           ));
  this.info($sformatf("        > WEIGHT_DESC_MID_OF_PKT_BEFORE_START_OF_PKT : %1d%%", this.fault_ratio.WEIGHT_DESC_MID_OF_PKT_BEFORE_START_OF_PKT));
  this.info($sformatf("        > WEIGHT_DESC_SOLO_OF_PKT_DURING_GATHERING   : %1d%%", this.fault_ratio.WEIGHT_DESC_SOLO_OF_PKT_DURING_GATHERING  ));
  this.info($sformatf("        > WEIGHT_DESC_START_OF_PKT_DURING_GATHERING  : %1d%%", this.fault_ratio.WEIGHT_DESC_START_OF_PKT_DURING_GATHERING ));
  this.info($sformatf("        > WEIGHT_DESC_END_OF_PKT_BEFORE_START_PKT    : %1d%%", this.fault_ratio.WEIGHT_DESC_END_OF_PKT_BEFORE_START_PKT   ));
  this.info($sformatf("        > WEIGHT_CARD_R_PREMATURE_LAST               : %1d%%", this.fault_ratio.WEIGHT_CARD_R_PREMATURE_LAST              ));
  this.info($sformatf("        > WEIGHT_CARD_R_NO_LAST                      : %1d%%", this.fault_ratio.WEIGHT_CARD_R_NO_LAST                     ));
  this.info($sformatf("        > WEIGHT_CARD_R_WRONG_MTY                    : %1d%%", this.fault_ratio.WEIGHT_CARD_R_WRONG_MTY                   ));
  this.info($sformatf("        > WEIGHT_CARD_R_WRONG_DMA_ID                 : %1d%%", this.fault_ratio.WEIGHT_CARD_R_WRONG_DMA_ID                ));
  this.info($sformatf("        > WEIGHT_HOST_R_WRONG_RESP                   : %1d%%", this.fault_ratio.WEIGHT_HOST_R_WRONG_RESP                  ));
  this.info($sformatf("        > WEIGHT_HOST_B_WRONG_RESP                   : %1d%%", this.fault_ratio.WEIGHT_HOST_B_WRONG_RESP                  ));
  this.info($sformatf("        > WEIGHT_HOST_CORRECT_RESP                   : %1d%%", this.fault_ratio.WEIGHT_HOST_CORRECT_RESP                  ));
  this.info($sformatf("_______________________________________________________________________"));
  this.info($sformatf("                                                                       "));
endfunction:showTbCfg


`endif // __VDMATB_TCFG_SVH__
