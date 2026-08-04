`ifndef  __VDMATB_FAULT_CONSTRAINED_RANDOM_VSEQ_SVH__
`define  __VDMATB_FAULT_CONSTRAINED_RANDOM_VSEQ_SVH__



class vdmatb_fault_constrained_random_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_fault_constrained_random_vseq)

  function new(string name="vdmatb_fault_constrained_random_vseq");
    super.new(name);

  endfunction

  virtual function void setDefaultCfg();
    if(this.tcfg.getDmaIpType == ST)begin 
      this.addC2HDmaMstSeqToExecute("vdma_st_fault_c2h_constrained_random_seq", $sformatf("C2H_SEQ0"));
      this.addH2CDmaMstSeqToExecute("vdma_st_fault_h2c_constrained_random_seq", $sformatf("H2C_SEQ0"));
    end
    else if(this.tcfg.getDmaIpType == MM)begin
      this.addC2HDmaMstSeqToExecute("vdma_st_fault_c2h_constrained_random_seq", $sformatf("C2H_SEQ0"));
      this.addH2CDmaMstSeqToExecute("vdma_st_fault_h2c_constrained_random_seq", $sformatf("H2C_SEQ0"));
    end
    else
      this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endfunction

  virtual protected function string decideHostSeqToExecute(); return("vdmatb_host_constrained_random_seq"); endfunction

endclass:vdmatb_fault_constrained_random_vseq




`endif // __VDMATB_FAULT_CONSTRAINED_RANDOM_VSEQ_SVH__
