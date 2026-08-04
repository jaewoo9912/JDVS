`ifndef  __VDMATB_FAULT_CARD_R_PREMATURE_LAST_VSEQ_SVH__
`define  __VDMATB_FAULT_CARD_R_PREMATURE_LAST_VSEQ_SVH__



class vdmatb_fault_card_r_premature_last_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_fault_card_r_premature_last_vseq)

  function new(string name="vdmatb_fault_card_r_premature_last_vseq");
    super.new(name);

  endfunction

  virtual function void setDefaultCfg();
    if(this.tcfg.getDmaIpType == ST)      this.addC2HDmaMstSeqToExecute("vdma_st_fault_card_r_premature_last_seq", $sformatf("C2H_SEQ0"));
    else if(this.tcfg.getDmaIpType == MM) this.addC2HDmaMstSeqToExecute("vdma_mm_fault_card_r_premature_last_seq", $sformatf("C2H_SEQ0"));
    else                                  this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endfunction

endclass:vdmatb_fault_card_r_premature_last_vseq




`endif // __VDMATB_FAULT_CARD_R_PREMATURE_LAST_VSEQ_SVH__
