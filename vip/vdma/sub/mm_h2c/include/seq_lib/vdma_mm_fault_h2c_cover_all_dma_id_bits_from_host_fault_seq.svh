`ifndef __VDMA_MM_FAULT_H2C_COVER_ALL_DMA_ID_BITS_FROM_HOST_FAULT_SEQ_SVH__
`define __VDMA_MM_FAULT_H2C_COVER_ALL_DMA_ID_BITS_FROM_HOST_FAULT_SEQ_SVH__

class vdma_mm_fault_h2c_cover_all_dma_id_bits_from_host_fault_seq extends vdma_mm_h2c_mst_seq;
  local int seq_item_cnt = -1;
	
  typedef vdma_seq_item SeqItem_t;
  `uvm_object_utils(vdma_mm_fault_h2c_cover_all_dma_id_bits_from_host_fault_seq)

  function new (string name="vdma_mm_fault_h2c_cover_all_dma_id_bits_from_host_fault_seq");
    super.new(name);
    this.watchdog_cycle = 400000000;
  endfunction

  extern function void genCfg();

  extern virtual protected function SeqItem_t createSeqItem(string name_postfix="");
  extern local function DmaId_t               decideDirectedDmaId();
endclass:vdma_mm_fault_h2c_cover_all_dma_id_bits_from_host_fault_seq


function DmaId_t vdma_mm_fault_h2c_cover_all_dma_id_bits_from_host_fault_seq::decideDirectedDmaId();
  this.seq_item_cnt++;
  if(this.seq_item_cnt == 0)      return(DutParamDmaId_t'(0));
  else if(this.seq_item_cnt == 1) return(DutParamDmaId_t'(16'hFFFF));
  else                            return(DutParamDmaId_t'(1));
endfunction


function vdma_mm_fault_h2c_cover_all_dma_id_bits_from_host_fault_seq::SeqItem_t vdma_mm_fault_h2c_cover_all_dma_id_bits_from_host_fault_seq::createSeqItem(string name_postfix="");
  vdma_seq_item created;

  created = vdma_seq_item::type_id::create(this.makeItemName(name_postfix));
  created.test_type = this.tcfg.test_type;
  created.setDataSize(this.mst.getDataSize);
  
  created.cstr_dma_id      = this.decideDirectedDmaId(); 
  created.cstr_trans_type  = this.getTransType();
  created.cstr_dma_len     = this.decideCstrLen();
  created.cstr_axi_max_len = this.decideCstrMaxBL();
  created.cstr_src_addr    = DutParamHostAddr_t'(this.decideCstrAddr);
  created.cstr_dst_addr    = DutParamCardAddr_t'(this.decideCstrAddr);
  created.cstr_fnc_id      = this.decideCstrFnc_Id();
  created.cstr_str_id      = this.decideCstrStr_Id();
  
  created.randomize();
  
  return(this.post_createSeqItem(created));
endfunction:createSeqItem



function void vdma_mm_fault_h2c_cover_all_dma_id_bits_from_host_fault_seq::genCfg();
	// #PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start = 3;
	this.num_item_end   = 3;

	super.genCfg();

endfunction:genCfg


`endif // __VDMA_MM_FAULT_H2C_COVER_ALL_DMA_ID_BITS_FROM_HOST_FAULT_SEQ_SVH__
