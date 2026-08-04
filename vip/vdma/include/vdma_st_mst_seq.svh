`ifndef __VDMA_ST_MST_SEQ_SVH__
`define __VDMA_ST_MST_SEQ_SVH__



virtual class vdma_st_mst_seq extends vdma_mst_seq;
  
  typedef vdma_seq_item SeqItem_t;

  `uvm_declare_p_sequencer(vdma_st_mst_seqr)
  function new (string name="vdma_st_mst_seq");
	  super.new(name);
  endfunction

  extern virtual protected function SeqItem_t createSeqItem(string name_postfix="");
endclass:vdma_st_mst_seq



function vdma_st_mst_seq::SeqItem_t vdma_st_mst_seq::createSeqItem(string name_postfix="");
  vdma_seq_item created;

  created = vdma_seq_item::type_id::create(this.makeItemName(name_postfix));
  created.test_type = this.tcfg.test_type;
  created.setDataSize(this.mst.getDataSize);
  
  created.cstr_dma_id      = DutParamDmaId_t'(created.getID);
  created.cstr_trans_type  = this.getTransType();
  created.cstr_dma_len     = this.decideCstrLen();
  created.cstr_axi_max_len = this.decideCstrMaxBL();
  created.cstr_src_addr    = DutParamHostAddr_t'(this.decideCstrAddr);
  created.cstr_dst_addr    = DutParamHostAddr_t'(this.decideCstrAddr);
  created.cstr_fnc_id      = this.decideCstrFnc_Id();
  created.cstr_str_id      = this.decideCstrStr_Id();
  
  created.randomize();
  
  return(this.post_createSeqItem(created));
endfunction:createSeqItem

`endif // __VDMA_ST_MST_SEQ_SVH__
