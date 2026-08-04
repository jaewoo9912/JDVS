`ifndef __VDMA_ST_C2H_MST_SEQ_SVH__
`define __VDMA_ST_C2H_MST_SEQ_SVH__



virtual class vdma_st_c2h_mst_seq extends vdma_st_mst_seq;
  
  typedef vdma_seq_item SeqItem_t;

  `uvm_declare_p_sequencer(vdma_st_c2h_mst_seqr)
  function new (string name="vdma_st_c2h_mst_seq");
	  super.new(name);
  endfunction

  extern virtual function DmaTransType_t getTransType();
  extern virtual protected function string getItemFamilyName();
  
  extern virtual function SeqItem_t post_createSeqItem(SeqItem_t me);
  extern virtual protected function T_SEQ_ITEM_Q createSeqItemQ(string name_postfix="");


endclass:vdma_st_c2h_mst_seq



function string vdma_st_c2h_mst_seq::getItemFamilyName();
  return("ST_C2H_ITEM");
endfunction:getItemFamilyName



function DmaTransType_t vdma_st_c2h_mst_seq::getTransType();
  return(ST_C2H);
endfunction:getTransType


function vdma_st_c2h_mst_seq::SeqItem_t vdma_st_c2h_mst_seq::post_createSeqItem(SeqItem_t me);
	me.makeRandDataValue();
  return(me);
endfunction:post_createSeqItem



function vdma_mst_seq::T_SEQ_ITEM_Q vdma_st_c2h_mst_seq::createSeqItemQ(string name_postfix="");
  T_SEQ_ITEM    created;
  T_SEQ_ITEM_Q  q_created;
  
  created = this.createSeqItem();
  q_created.push_back(created);
  
  return(q_created);
endfunction:createSeqItemQ


`endif // __VDMA_ST_C2H_MST_SEQ_SVH__
