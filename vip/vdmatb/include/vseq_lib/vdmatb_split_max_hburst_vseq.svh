`ifndef  __VDMATB_SPLIT_MAX_HBURST_VSEQ_SVH__
`define  __VDMATB_SPLIT_MAX_HBURST_VSEQ_SVH__


class vdmatb_split_max_hburst_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_split_max_hburst_vseq)

  function new(string name="vdmatb_split_max_hburst_vseq");
    super.new(name);

    this.num_seq_range.start_value = 1;
    this.num_seq_range.end_value   = 1;
  endfunction

  virtual function void setDefaultCfg();
    if(this.tcfg.getDmaIpType == ST) begin
      for(int i = 0 ; i < this.pickRandUIntInTheRange(this.num_seq_range) ; i++)begin
        this.addH2CDmaMstSeqToExecute("vdma_st_h2c_split_max_hburst_seq", $sformatf("H2C_SEQ%1d", i));
      end
      for(int i = 0 ; i < this.pickRandUIntInTheRange(this.num_seq_range) ; i++)begin
        this.addC2HDmaMstSeqToExecute("vdma_st_c2h_split_max_hburst_seq", $sformatf("C2H_SEQ%1d", i));
      end
    end
    else if(this.tcfg.getDmaIpType == MM) begin
      for(int i = 0 ; i < this.pickRandUIntInTheRange(this.num_seq_range) ; i++)begin
        this.addH2CDmaMstSeqToExecute("vdma_mm_h2c_split_max_hburst_seq", $sformatf("H2C_SEQ%1d", i));
      end
      for(int i = 0 ; i < this.pickRandUIntInTheRange(this.num_seq_range) ; i++)begin
        this.addC2HDmaMstSeqToExecute("vdma_mm_c2h_split_max_hburst_seq", $sformatf("C2H_SEQ%1d", i));
      end
    end
    else
      this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endfunction

endclass:vdmatb_split_max_hburst_vseq




`endif // __VDMATB_SPLIT_MAX_HBURST_VSEQ_SVH__
