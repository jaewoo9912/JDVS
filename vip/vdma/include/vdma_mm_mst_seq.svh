`ifndef __VDMA_MM_MST_SEQ_SVH__
`define __VDMA_MM_MST_SEQ_SVH__



virtual class vdma_mm_mst_seq extends vdma_mst_seq;
  
  typedef vdma_seq_item SeqItem_t;

  `uvm_declare_p_sequencer(vdma_mm_mst_seqr)
  function new (string name="vdma_mm_mst_seq");
	  super.new(name);
  endfunction

  extern virtual protected function T_SEQ_ITEM_Q createSeqItemQ(string name_postfix="");
  extern virtual function SeqItem_t post_createSeqItem(SeqItem_t me);
  extern virtual function void genCfg();
endclass:vdma_mm_mst_seq


function vdma_mm_mst_seq::SeqItem_t vdma_mm_mst_seq::post_createSeqItem(SeqItem_t me);
  return(me);
endfunction


function vdma_mm_mst_seq::T_SEQ_ITEM_Q vdma_mm_mst_seq::createSeqItemQ(string name_postfix="");
  T_SEQ_ITEM    created;
  T_SEQ_ITEM_Q  q_created;
  
  created = this.createSeqItem();
  created.desc.sop = 0;
  created.desc.eop = 0;
  created.setPktGatheringInfo(NOT_ON_PKT_GATHERING);
  
  q_created.push_back(created);
  
  return(q_created);
endfunction:createSeqItemQ


function void vdma_mm_mst_seq::genCfg();
	
	this.prob_pkt_gathering = 0;
	
	super.genCfg();
	
endfunction:genCfg
`endif // __VDMA_MM_MST_SEQ_SVH__
