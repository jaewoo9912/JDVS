`ifndef  __VDMATB_FAULT_HOST_R_PREMATURE_LAST_SPECIFIC_DMA_ID_VSEQ_SVH__
`define  __VDMATB_FAULT_HOST_R_PREMATURE_LAST_SPECIFIC_DMA_ID_VSEQ_SVH__



class vdmatb_fault_host_r_premature_last_specific_dma_id_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_fault_host_r_premature_last_specific_dma_id_vseq)

  function new(string name="vdmatb_fault_host_r_premature_last_specific_dma_id_vseq");
    super.new(name);

  endfunction

  virtual function void setDefaultCfg();
    if(this.tcfg.getDmaIpType == ST)begin 
      this.addH2CDmaMstSeqToExecute("vdma_st_fault_host_r_premature_last_specific_dma_id_seq", $sformatf("H2C_SEQ0"));
    end
    else if(this.tcfg.getDmaIpType == MM)begin
      this.addH2CDmaMstSeqToExecute("vdma_mm_fault_host_r_premature_last_specific_dma_id_seq", $sformatf("H2C_SEQ0"));
    end
    else
      this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endfunction

endclass:vdmatb_fault_host_r_premature_last_specific_dma_id_vseq




`endif // __VDMATB_FAULT_HOST_R_PREMATURE_LAST_SPECIFIC_DMA_ID_VSEQ_SVH__
