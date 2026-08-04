`ifndef  __VDMATB_H2C_RANDOM_VSEQ_SVH__
`define  __VDMATB_H2C_RANDOM_VSEQ_SVH__


class vdmatb_h2c_random_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_h2c_random_vseq)

  function new(string name="vdmatb_h2c_random_vseq");
    super.new(name);

    this.num_seq_range.start_value = 1;
    this.num_seq_range.end_value   = 1;
  endfunction

  virtual function void setDefaultCfg();
    if(this.tcfg.getDmaIpType == ST)
      this.addH2CDmaMstSeqToExecute("vdma_st_h2c_mst_random_seq", $sformatf("H2C_SEQ0"));
    else if(this.tcfg.getDmaIpType == MM)
      this.addH2CDmaMstSeqToExecute("vdma_mm_h2c_mst_random_seq", $sformatf("H2C_SEQ0"));
    else
      this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));

  endfunction
endclass:vdmatb_h2c_random_vseq




`endif // __VDMATB_H2C_RANDOM_VSEQ_SVH__
