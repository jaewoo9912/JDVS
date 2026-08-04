`ifndef  __VDMATB_FAULT_DESC_SOLO_PKT_DURING_GATHERING_VSEQ_SVH__
`define  __VDMATB_FAULT_DESC_SOLO_PKT_DURING_GATHERING_VSEQ_SVH__



class vdmatb_fault_desc_solo_pkt_during_gathering_vseq extends vdmatb_vseq;

  UIntRange_t num_seq_range;

  `uvm_object_utils(vdmatb_fault_desc_solo_pkt_during_gathering_vseq)

  function new(string name="vdmatb_fault_desc_solo_pkt_during_gathering_vseq");
    super.new(name);

  endfunction

  virtual function void setDefaultCfg();
	this.addH2CDmaMstSeqToExecute("vdma_st_fault_desc_solo_pkt_during_gathering_seq", $sformatf("H2C_SEQ0"));

  endfunction

endclass:vdmatb_fault_desc_solo_pkt_during_gathering_vseq




`endif // __VDMATB_FAULT_DESC_SOLO_PKT_DURING_GATHERING_VSEQ_SVH__
