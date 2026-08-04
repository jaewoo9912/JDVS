`ifndef  __VDMATB_H2C_SMALL_LEN_IN_BYTE_VSEQ_SVH__
`define  __VDMATB_H2C_SMALL_LEN_IN_BYTE_VSEQ_SVH__



class vdmatb_h2c_small_len_in_byte_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_h2c_small_len_in_byte_vseq)

  function new(string name="vdmatb_h2c_small_len_in_byte_vseq");
    super.new(name);

  endfunction

  virtual function void setDefaultCfg();
    if(this.tcfg.getDmaIpType == ST)
	    this.addH2CDmaMstSeqToExecute("vdma_st_h2c_small_len_in_byte_seq", $sformatf("H2C_SEQ0"));
    else if(this.tcfg.getDmaIpType == MM)
	    this.addH2CDmaMstSeqToExecute("vdma_mm_h2c_small_len_in_byte_seq", $sformatf("H2C_SEQ0"));
    else
      this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));

  endfunction

endclass:vdmatb_h2c_small_len_in_byte_vseq




`endif // __VDMATB_H2C_SMALL_LEN_IN_BYTE_VSEQ_SVH__
