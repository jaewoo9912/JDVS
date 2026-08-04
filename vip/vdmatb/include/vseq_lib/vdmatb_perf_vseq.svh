`ifndef  __VDMATB_PERF_VSEQ_SVH__
`define  __VDMATB_PERF_VSEQ_SVH__


class vdmatb_perf_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_perf_vseq)

  function new(string name="vdmatb_perf_vseq");
    super.new(name);

    this.num_seq_range.start_value = 1;
    this.num_seq_range.end_value   = 1;
  endfunction

  virtual function void setDefaultCfg();
    if(this.tcfg.getDmaIpType == ST) begin
      this.addH2CDmaMstSeqToExecute("vdma_st_h2c_mst_perf_seq", $sformatf("H2C_SEQ0"));
      this.addC2HDmaMstSeqToExecute("vdma_st_c2h_mst_perf_seq", $sformatf("C2H_SEQ0"));
    end
    else if(this.tcfg.getDmaIpType == MM) begin
      this.addH2CDmaMstSeqToExecute("vdma_mm_h2c_mst_perf_seq", $sformatf("H2C_SEQ0"));
      this.addC2HDmaMstSeqToExecute("vdma_mm_c2h_mst_perf_seq", $sformatf("C2H_SEQ0"));
    end
    else
      this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endfunction


  virtual protected function string decideHostSeqToExecute();                                  return("vdmatb_host_perf_seq"); endfunction
  virtual protected function string decideCardSeqToExecute(); if(this.tcfg.getDmaIpType == MM) return("vdmatb_card_perf_seq"); endfunction

endclass:vdmatb_perf_vseq




`endif // __VDMATB_PERF_VSEQ_SVH__
