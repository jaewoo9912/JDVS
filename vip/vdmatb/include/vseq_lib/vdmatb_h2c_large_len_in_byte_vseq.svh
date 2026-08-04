`ifndef  __VDMATB_H2C_LARGE_LEN_IN_BYTE_VSEQ_SVH__
`define  __VDMATB_H2C_LARGE_LEN_IN_BYTE_VSEQ_SVH__


class vdmatb_h2c_large_len_in_byte_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_h2c_large_len_in_byte_vseq)

  function new(string name="vdmatb_h2c_large_len_in_byte_vseq");
    super.new(name);

    this.num_seq_range.start_value = 1;
    this.num_seq_range.end_value   = 1;
  endfunction

  virtual function void setDefaultCfg();
    for(int i = 0 ; i < this.pickRandUIntInTheRange(this.num_seq_range) ; i++)begin
      this.addC2HDmaMstSeqToExecute("vdma_st_h2c_large_len_in_byte_seq", $sformatf("C2H_SEQ%1d", i));
    end
  endfunction

endclass:vdmatb_h2c_large_len_in_byte_vseq




`endif // __VDMATB_H2C_LARGE_LEN_IN_BYTE_VSEQ_SVH__
