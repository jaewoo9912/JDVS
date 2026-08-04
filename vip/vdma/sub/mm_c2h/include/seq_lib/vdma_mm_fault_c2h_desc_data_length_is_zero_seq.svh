`ifndef __VDMA_MM_FAULT_C2H_DESC_DATA_LENGTH_IS_ZERO_SEQ_SVH__
`define __VDMA_MM_FAULT_C2H_DESC_DATA_LENGTH_IS_ZERO_SEQ_SVH__



class vdma_mm_fault_c2h_desc_data_length_is_zero_seq extends vdma_mm_c2h_mst_seq;
	

	`uvm_object_utils(vdma_mm_fault_c2h_desc_data_length_is_zero_seq)

	function new (string name="vdma_mm_fault_c2h_desc_data_length_is_zero_seq");
		super.new(name);
	endfunction

	extern virtual function void genCfg();
	extern virtual task pre_genCfg();

  extern virtual function T_SEQ_ITEM createC2HFaultSeqItem(vdma_seq_item me);
	extern virtual function SeqItem_t createSeqItem_DataLenZero(string name_postfix="");
  extern virtual protected function T_SEQ_ITEM_Q createSeqItemQ(string name_postfix="");

endclass:vdma_mm_fault_c2h_desc_data_length_is_zero_seq

function vdma_mm_fault_c2h_desc_data_length_is_zero_seq::T_SEQ_ITEM vdma_mm_fault_c2h_desc_data_length_is_zero_seq::createC2HFaultSeqItem(vdma_seq_item me);
  vdma_seq_item created;


  created = me;
  created.desc.len = 0;
  
  created.intended_faultType = 0;

  
  return(created);
endfunction:createC2HFaultSeqItem

function vdma_mm_fault_c2h_desc_data_length_is_zero_seq::SeqItem_t vdma_mm_fault_c2h_desc_data_length_is_zero_seq::createSeqItem_DataLenZero(string name_postfix="");
	vdma_seq_item created;

	created = vdma_seq_item::type_id::create(this.makeItemName(name_postfix));

	created.setDataSize(this.mst.getDataSize);

        created.cstr_dma_id     = DutParamDmaId_t'(created.getID);
        created.cstr_trans_type = this.getTransType();
	created.cstr_dma_len    = 0;
	created.cstr_axi_max_len = this.decideCstrMaxBL();
	created.cstr_src_addr   = DutParamHostAddr_t'(this.decideCstrAddr());
	created.cstr_dst_addr   = DutParamHostAddr_t'(this.decideCstrAddr());
	created.cstr_fnc_id     = this.decideCstrFnc_Id();
	created.cstr_str_id     = this.decideCstrStr_Id();

//  created.cstr_axi_min_len = min_axi_len;
//  created.cstr_axi_max_len = max_axi_len;

	created.randomize();

	return(this.post_createSeqItem(created));
endfunction:createSeqItem_DataLenZero

function vdma_mm_fault_c2h_desc_data_length_is_zero_seq::T_SEQ_ITEM_Q vdma_mm_fault_c2h_desc_data_length_is_zero_seq::createSeqItemQ(string name_postfix="");
  T_SEQ_ITEM    created;
  T_SEQ_ITEM_Q  q_created;

  created = this.createSeqItem_DataLenZero();
  q_created.push_back(this.createC2HFaultSeqItem(created));

  return(q_created);
endfunction:createSeqItemQ

function void vdma_mm_fault_c2h_desc_data_length_is_zero_seq::genCfg();
	// #PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start = 10;
	this.num_item_end   = 10;

	super.genCfg();

endfunction:genCfg

task vdma_mm_fault_c2h_desc_data_length_is_zero_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs


	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;


	super.pre_genCfg();
endtask:pre_genCfg

`endif // __VDMA_MM_FAULT_C2H_DESC_DATA_LENGTH_IS_ZERO_SEQ_SVH__
