`ifndef  __VDMATB_FAULT_HOST_B_WRONG_RESP_VSEQ_SVH__
`define  __VDMATB_FAULT_HOST_B_WRONG_RESP_VSEQ_SVH__


class vdmatb_fault_host_b_wrong_resp_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_fault_host_b_wrong_resp_vseq)

  function new(string name="vdmatb_fault_host_b_wrong_resp_vseq");
    super.new(name);

    this.num_seq_range.start_value = 1;
    this.num_seq_range.end_value   = 1;
  endfunction

  virtual function void setDefaultCfg();
    if(this.tcfg.getDmaIpType == ST)       this.addC2HDmaMstSeqToExecute("vdma_st_fault_host_b_wrong_resp_seq", $sformatf("C2H_SEQ0"));
    else if(this.tcfg.getDmaIpType == MM)  this.addC2HDmaMstSeqToExecute("vdma_mm_fault_host_b_wrong_resp_seq", $sformatf("C2H_SEQ0"));
    else                                   this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endfunction

  virtual protected function string decideHostSeqToExecute(); return("vdmatb_host_fault_host_b_wrong_resp_seq"); endfunction

endclass:vdmatb_fault_host_b_wrong_resp_vseq




`endif // __VDMATB_FAULT_HOST_B_WRONG_RESP_VSEQ_SVH__
