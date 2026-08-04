`ifndef __VDMATB_FAULT_TEST_SVH__
`define __VDMATB_FAULT_TEST_SVH__


virtual class vdmatb_fault_test extends vdmatb_test;
  
  function new(string name="vdmatb_fault_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  extern virtual protected function void decideTbCfg();
  extern virtual protected function void setupUvmFactory();

endclass:vdmatb_fault_test


function void vdmatb_fault_test::setupUvmFactory();
  super.setupUvmFactory();
  set_type_override_by_type(vdma_seq_item::get_type(), vdma_fault_seq_item::get_type());
endfunction:setupUvmFactory



function void vdmatb_fault_test::decideTbCfg();
  super.decideTbCfg();

  this.test_type = FAULT_TEST;
  this.select_fault = ALL_RANDOM_FAULT;
  this.fault_prob = 50;
  
  // Fault of Card-side
  this.fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO              = 1;  //DATA_LEN_IS_ZERO
  this.fault_ratio.WEIGHT_DESC_MID_OF_PKT_BEFORE_START_OF_PKT   = 1;  //DESC_MID_PKT_BEFORE_START_PKT
  this.fault_ratio.WEIGHT_DESC_SOLO_OF_PKT_DURING_GATHERING     = 1;  //DESC_SOLO_PKT_DURING_GATHERING
  this.fault_ratio.WEIGHT_DESC_START_OF_PKT_DURING_GATHERING    = 1;  //DESC_START_PKT_DURING_GATHERING
  this.fault_ratio.WEIGHT_DESC_END_OF_PKT_BEFORE_START_PKT      = 1;  //DESC_END_PKT_BEFORE_START_PKT
  this.fault_ratio.WEIGHT_CARD_R_PREMATURE_LAST                 = 1;  //CARD_R_PREMATURE_LAST
  this.fault_ratio.WEIGHT_CARD_R_NO_LAST                        = 1;  //CARD_R_NO_LAST
  this.fault_ratio.WEIGHT_CARD_R_WRONG_MTY                      = 1;  //CARD_R_WRONG_MTY
  this.fault_ratio.WEIGHT_CARD_R_WRONG_DMA_ID                   = 1;  //CARD_R_WRONG_DMA_ID
  // Fault of Card-side wrong_resp
  this.fault_ratio.WEIGHT_CARD_R_WRONG_RESP                     = 1;  //CARD_R_WORNG_RESP
  this.fault_ratio.WEIGHT_CARD_B_WRONG_RESP                     = 1;  //CARD_B_WORNG_RESP
  this.fault_ratio.WEIGHT_CARD_CORRECT_RESP                     = 1;  //HOST_CORRECT_RESP
  // Fault of Host-side wrong_resp
  this.fault_ratio.WEIGHT_HOST_R_WRONG_RESP                     = 1;  //HOST_R_WRONG_RESP
  this.fault_ratio.WEIGHT_HOST_B_WRONG_RESP                     = 1;  //HOST_B_WRONG_RESP
  this.fault_ratio.WEIGHT_HOST_CORRECT_RESP                     = 1;  //HOST_CORRECT_RESP

endfunction:decideTbCfg


`endif // __VDMATB_FAULT_TEST_SVH__
