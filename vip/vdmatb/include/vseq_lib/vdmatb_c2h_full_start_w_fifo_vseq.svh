`ifndef  __VDMATB_C2H_FULL_START_W_FIFO_VSEQ_SVH__
`define  __VDMATB_C2H_FULL_START_W_FIFO_VSEQ_SVH__


class vdmatb_c2h_full_start_w_fifo_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_c2h_full_start_w_fifo_vseq)

  function new(string name="vdmatb_c2h_full_start_w_fifo_vseq");
    super.new(name);

    this.num_seq_range.start_value = 1;
    this.num_seq_range.end_value   = 1;
  endfunction

  virtual function void setDefaultCfg();
    if(this.tcfg.getDmaIpType == ST)      this.addC2HDmaMstSeqToExecute("vdma_st_c2h_full_start_w_fifo_seq", $sformatf("C2H_SEQ0"));
    else if(this.tcfg.getDmaIpType == MM) this.addC2HDmaMstSeqToExecute("vdma_mm_c2h_full_start_w_fifo_seq", $sformatf("C2H_SEQ0"));
    else                                  this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endfunction

  virtual local function string decideHostSeqToExecute(); return("vdmatb_host_full_start_w_fifo_seq"); endfunction
  virtual local function string decideCardSeqToExecute(); return("vdmatb_card_full_start_w_fifo_seq"); endfunction
endclass:vdmatb_c2h_full_start_w_fifo_vseq




`endif // __VDMATB_C2H_FULL_START_W_FIFO_VSEQ_SVH__
