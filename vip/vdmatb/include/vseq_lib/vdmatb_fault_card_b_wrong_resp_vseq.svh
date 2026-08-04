`ifndef  __VDMATB_FAULT_CARD_B_WRONG_RESP_VSEQ_SVH__
`define  __VDMATB_FAULT_CARD_B_WRONG_RESP_VSEQ_SVH__


class vdmatb_fault_card_b_wrong_resp_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_fault_card_b_wrong_resp_vseq)

  function new(string name="vdmatb_fault_card_b_wrong_resp_vseq");
    super.new(name);

    this.num_seq_range.start_value = 1;
    this.num_seq_range.end_value   = 1;
  endfunction

  virtual function void setDefaultCfg();
    if(this.tcfg.getDmaIpType == MM)  this.addH2CDmaMstSeqToExecute("vdma_mm_fault_card_b_wrong_resp_seq", $sformatf("H2C_SEQ0"));
    else                              this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endfunction

  virtual local function string decideCardSeqToExecute(); return("vdmatb_card_fault_card_b_wrong_resp_seq"); endfunction

endclass:vdmatb_fault_card_b_wrong_resp_vseq




`endif // __VDMATB_FAULT_CARD_B_WRONG_RESP_VSEQ_SVH__
