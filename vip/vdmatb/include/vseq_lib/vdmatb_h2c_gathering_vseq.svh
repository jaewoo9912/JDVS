`ifndef  __VDMATB_H2C_GATHERING_VSEQ_SVH__
`define  __VDMATB_H2C_GATHERING_VSEQ_SVH__



class vdmatb_h2c_gathering_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_h2c_gathering_vseq)

  function new(string name="vdmatb_h2c_gathering_vseq");
    super.new(name);

  endfunction

  virtual function void setDefaultCfg();

    this.addH2CDmaMstSeqToExecute("vdma_st_h2c_gathering_seq", $sformatf("H2C_SEQ0"));
	  this.addH2CDmaMstSeqToExecute("vdma_st_h2c_small_gathering_seq", $sformatf("H2C_SEQ1"));

  endfunction

endclass:vdmatb_h2c_gathering_vseq




`endif // __VDMATB_H2C_GATHERING_VSEQ_SVH__
