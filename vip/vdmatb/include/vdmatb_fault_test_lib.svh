`ifndef  __VDMATB_FAULT_TEST_LIB_SVH__
`define  __VDMATB_FAULT_TEST_LIB_SVH__


/*


    ** Direct tests
      vdmatb_fault_desc_mid_pkt_before_start_pkt_test
      vdmatb_fault_desc_solo_pkt_during_gathering_test
      vdmatb_fault_desc_start_pkt_during_gathering_test
      vdmatb_fault_desc_end_pkt_before_start_pkt_test
    
      vdmatb_fault_card_r_wrong_mty_test
      vdmatb_fault_card_r_wrong_dma_id_test
      vdmatb_fault_card_r_no_last_test
      vdmatb_fault_card_r_premature_last_test
      vdmatb_fault_host_r_no_last_test
      vdmatb_fault_host_r_premature_last_test
      vdmatb_fault_desc_data_length_is_zero_test
    
      vdmatb_fault_host_r_wrong_resp_test
      vdmatb_fault_host_b_wrong_resp_test
    
    ** Random tests
      vdmatb_fault_constrained_random_test
      vdmatb_fault_all_random_test
    
    ** Specific tests? 
      vdmatb_fault_cover_all_dma_id_bits_from_desc_fault_test     
      vdmatb_fault_cover_all_dma_id_bits_from_card_fault_test
      vdmatb_fault_cover_all_dma_id_bits_from_host_fault_test

*/


class vdmatb_fault_all_random_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_all_random_test)
  function new(string name="vdmatb_fault_all_random_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_all_random_vseq");
  endfunction
  
endclass:vdmatb_fault_all_random_test



class vdmatb_fault_card_r_no_last_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_card_r_no_last_test)
  function new(string name="vdmatb_fault_card_r_no_last_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_card_r_no_last_vseq");
  endfunction

  virtual protected function void decideTbCfg();
    super.decideTbCfg();
    this.select_fault = CARD_R_NO_LAST_FAULT;
  endfunction
  
  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = YES;
    this.data_direction_type.only_h2c_test = NO;
  endfunction
endclass:vdmatb_fault_card_r_no_last_test




class vdmatb_fault_card_r_premature_last_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_card_r_premature_last_test)
  function new(string name="vdmatb_fault_card_r_premature_last_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_card_r_premature_last_vseq");
  endfunction

  virtual protected function void decideTbCfg();
    super.decideTbCfg();
    this.select_fault = CARD_R_PREMATURE_LAST_FAULT;
  endfunction
  
  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = YES;
    this.data_direction_type.only_h2c_test = NO;
  endfunction
endclass:vdmatb_fault_card_r_premature_last_test




class vdmatb_fault_card_r_wrong_dma_id_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_card_r_wrong_dma_id_test)
  function new(string name="vdmatb_fault_card_r_wrong_dma_id_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_card_r_wrong_dma_id_vseq");
  endfunction

  virtual protected function void decideTbCfg();
    super.decideTbCfg();
    this.select_fault = HAS_WRONG_DMA_ID_FAULT;
  endfunction
  
  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = YES;
    this.data_direction_type.only_h2c_test = NO;
  endfunction
endclass:vdmatb_fault_card_r_wrong_dma_id_test




class vdmatb_fault_card_r_wrong_mty_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_card_r_wrong_mty_test)
  function new(string name="vdmatb_fault_card_r_wrong_mty_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_card_r_wrong_mty_vseq");
  endfunction

  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = YES;
    this.data_direction_type.only_h2c_test = NO;
  endfunction
endclass:vdmatb_fault_card_r_wrong_mty_test




class vdmatb_fault_constrained_random_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_constrained_random_test)
  function new(string name="vdmatb_fault_constrained_random_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_constrained_random_vseq");
  endfunction


  virtual protected function void decideTbCfg();
    super.decideTbCfg();
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
    // Fault of Card-side
    this.fault_ratio.WEIGHT_CARD_R_WRONG_RESP                     = 0;  //CARD_R_WRONG_RESP
    this.fault_ratio.WEIGHT_CARD_B_WRONG_RESP                     = 0;  //CARD_B_WRONG_RESP
    this.fault_ratio.WEIGHT_CARD_CORRECT_RESP                     = 1;  //CARD_CORRECT_RESP
    // Fault of Host-side
    this.fault_ratio.WEIGHT_HOST_R_WRONG_RESP                     = 0;  //HOST_R_WRONG_RESP
    this.fault_ratio.WEIGHT_HOST_B_WRONG_RESP                     = 0;  //HOST_B_WRONG_RESP
    this.fault_ratio.WEIGHT_HOST_CORRECT_RESP                     = 1;  //HOST_CORRECT_RESP
  endfunction
  
endclass:vdmatb_fault_constrained_random_test




class vdmatb_fault_desc_data_length_is_zero_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_desc_data_length_is_zero_test)
  function new(string name="vdmatb_fault_desc_data_length_is_zero_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_desc_data_length_is_zero_vseq");
  endfunction

endclass:vdmatb_fault_desc_data_length_is_zero_test





class vdmatb_fault_desc_end_pkt_before_start_pkt_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_desc_end_pkt_before_start_pkt_test)
  function new(string name="vdmatb_fault_desc_end_pkt_before_start_pkt_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_desc_end_pkt_before_start_pkt_vseq");
  endfunction

  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = NO;
    this.data_direction_type.only_h2c_test = YES;
  endfunction
endclass:vdmatb_fault_desc_end_pkt_before_start_pkt_test




class vdmatb_fault_desc_mid_pkt_before_start_pkt_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_desc_mid_pkt_before_start_pkt_test)
  function new(string name="vdmatb_fault_desc_mid_pkt_before_start_pkt_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_desc_mid_pkt_before_start_pkt_vseq");
  endfunction

  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = NO;
    this.data_direction_type.only_h2c_test = YES;
  endfunction
endclass:vdmatb_fault_desc_mid_pkt_before_start_pkt_test






class vdmatb_fault_desc_solo_pkt_during_gathering_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_desc_solo_pkt_during_gathering_test)
  function new(string name="vdmatb_fault_desc_solo_pkt_during_gathering_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_desc_solo_pkt_during_gathering_vseq");
  endfunction

  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = NO;
    this.data_direction_type.only_h2c_test = YES;
  endfunction
endclass:vdmatb_fault_desc_solo_pkt_during_gathering_test






class vdmatb_fault_desc_start_pkt_during_gathering_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_desc_start_pkt_during_gathering_test)
  function new(string name="vdmatb_fault_desc_start_pkt_during_gathering_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_desc_start_pkt_during_gathering_vseq");
  endfunction

  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = NO;
    this.data_direction_type.only_h2c_test = YES;
  endfunction
endclass:vdmatb_fault_desc_start_pkt_during_gathering_test





class vdmatb_fault_host_b_wrong_resp_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_host_b_wrong_resp_test)
  function new(string name="vdmatb_fault_host_b_wrong_resp_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_host_b_wrong_resp_vseq");
  endfunction
  
  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = YES;
    this.data_direction_type.only_h2c_test = NO;
  endfunction

endclass:vdmatb_fault_host_b_wrong_resp_test





class vdmatb_fault_host_r_no_last_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_host_r_no_last_test)
  function new(string name="vdmatb_fault_host_r_no_last_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_host_r_no_last_vseq");
  endfunction


  virtual protected function void decideTbCfg();
    super.decideTbCfg();
    this.select_fault = HOST_R_NO_LAST_FAULT;
  endfunction
  
  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = NO;
    this.data_direction_type.only_h2c_test = YES;
  endfunction

endclass:vdmatb_fault_host_r_no_last_test




class vdmatb_fault_host_r_premature_last_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_host_r_premature_last_test)
  function new(string name="vdmatb_fault_host_r_premature_last_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_host_r_premature_last_vseq");
  endfunction

  virtual protected function void decideTbCfg();
    super.decideTbCfg();
    this.select_fault = HOST_R_PREMATURE_LAST_FAULT;
  endfunction

  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = NO;
    this.data_direction_type.only_h2c_test = YES;
  endfunction
  
endclass:vdmatb_fault_host_r_premature_last_test





class vdmatb_fault_host_r_wrong_resp_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_host_r_wrong_resp_test)
  function new(string name="vdmatb_fault_host_r_wrong_resp_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_host_r_wrong_resp_vseq");
  endfunction
  
  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = NO;
    this.data_direction_type.only_h2c_test = YES;
  endfunction

endclass:vdmatb_fault_host_r_wrong_resp_test




class vdmatb_fault_cover_all_dma_id_bits_from_desc_fault_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_cover_all_dma_id_bits_from_desc_fault_test)
  function new(string name="vdmatb_fault_cover_all_dma_id_bits_from_desc_fault_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_cover_all_dma_id_bits_from_desc_fault_vseq");
  endfunction

endclass:vdmatb_fault_cover_all_dma_id_bits_from_desc_fault_test



class vdmatb_fault_cover_all_dma_id_bits_from_card_fault_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_cover_all_dma_id_bits_from_card_fault_test)
  function new(string name="vdmatb_fault_cover_all_dma_id_bits_from_card_fault_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_cover_all_dma_id_bits_from_card_fault_vseq");
  endfunction

endclass:vdmatb_fault_cover_all_dma_id_bits_from_card_fault_test



class vdmatb_fault_cover_all_dma_id_bits_from_host_fault_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_cover_all_dma_id_bits_from_host_fault_test)
  function new(string name="vdmatb_fault_cover_all_dma_id_bits_from_host_fault_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_cover_all_dma_id_bits_from_host_fault_vseq");
  endfunction

endclass:vdmatb_fault_cover_all_dma_id_bits_from_host_fault_test





class vdmatb_fault_card_b_wrong_resp_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_card_b_wrong_resp_test)
  function new(string name="vdmatb_fault_card_b_wrong_resp_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_card_b_wrong_resp_vseq");
  endfunction
  
  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = NO;
    this.data_direction_type.only_h2c_test = YES;
  endfunction

endclass:vdmatb_fault_card_b_wrong_resp_test




class vdmatb_fault_card_r_wrong_resp_test extends vdmatb_fault_test;
  
  `uvm_component_utils(vdmatb_fault_card_r_wrong_resp_test)
  function new(string name="vdmatb_fault_card_r_wrong_resp_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_fault_card_r_wrong_resp_vseq");
  endfunction
  
  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = YES;
    this.data_direction_type.only_h2c_test = NO;
  endfunction

endclass:vdmatb_fault_card_r_wrong_resp_test




`endif // __VDMATB_FAULT_TEST_LIB_SVH__
