`ifndef __VDMA_ST_FAULT_C2H_COVER_ALL_DMA_ID_BITS_FROM_DESC_FAULT_SEQ_SVH__
`define __VDMA_ST_FAULT_C2H_COVER_ALL_DMA_ID_BITS_FROM_DESC_FAULT_SEQ_SVH__



class vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq extends vdma_st_c2h_mst_seq;
  local int seq_item_cnt = -1;	
  
  `uvm_object_utils(vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq)

  function new (string name="vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq");
    super.new(name);
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();

  extern virtual function T_SEQ_ITEM createC2HFaultSeqItem(vdma_seq_item me);
  extern virtual function SeqItem_t createSeqItem_DataLenZero(string name_postfix="");
  extern virtual protected function T_SEQ_ITEM_Q createSeqItemQ(string name_postfix="");

  extern local function DmaId_t decideDirectedDmaId();
endclass:vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq


function DmaId_t vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq::decideDirectedDmaId();
  this.seq_item_cnt++;
  if(this.seq_item_cnt == 0)      return(DutParamDmaId_t'(0));
  else if(this.seq_item_cnt == 1) return(DutParamDmaId_t'(16'hFFFF));
  else                            return(DutParamDmaId_t'(0));
endfunction


function vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq::T_SEQ_ITEM vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq::createC2HFaultSeqItem(vdma_seq_item me);
  vdma_seq_item created;


  created = me;
  created.desc.len = 0;
  
  created.intended_faultType = 0;

  
  return(created);
endfunction:createC2HFaultSeqItem


function vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq::SeqItem_t vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq::createSeqItem_DataLenZero(string name_postfix="");
	vdma_seq_item created;

	created = vdma_seq_item::type_id::create(this.makeItemName(name_postfix));

	created.setDataSize(this.mst.getDataSize);

        created.cstr_dma_id     = this.decideDirectedDmaId();	
        created.cstr_trans_type = this.getTransType();
	created.cstr_dma_len    = 0;
	created.cstr_axi_max_len = this.decideCstrMaxBL();
	created.cstr_src_addr   = DutParamHostAddr_t'(this.decideCstrAddr());
	created.cstr_dst_addr   = DutParamHostAddr_t'(this.decideCstrAddr());
	created.cstr_fnc_id     = this.decideCstrFnc_Id();
	created.cstr_str_id     = this.decideCstrStr_Id();

	created.randomize();

	return(this.post_createSeqItem(created));
endfunction:createSeqItem_DataLenZero

function vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq::T_SEQ_ITEM_Q vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq::createSeqItemQ(string name_postfix="");
  T_SEQ_ITEM    created;
  T_SEQ_ITEM_Q  q_created;

  created = this.createSeqItem_DataLenZero();
  q_created.push_back(this.createC2HFaultSeqItem(created));

  return(q_created);
endfunction:createSeqItemQ

function void vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq::genCfg();
	// #PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start = 3;
	this.num_item_end   = 3;

	super.genCfg();

endfunction:genCfg

task vdma_st_fault_c2h_cover_all_dma_id_bits_from_desc_fault_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs


	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;


	super.pre_genCfg();
endtask:pre_genCfg

`endif // __VDMA_ST_FAULT_C2H_COVER_ALL_DMA_ID_BITS_FROM_DESC_FAULT_SEQ_SVH__
