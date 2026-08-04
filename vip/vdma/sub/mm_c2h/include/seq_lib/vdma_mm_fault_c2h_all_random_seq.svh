`ifndef __VDMA_MM_FAULT_C2H_ALL_RANDOM_SEQ_SVH__
`define __VDMA_MM_FAULT_C2H_ALL_RANDOM_SEQ_SVH__



class vdma_mm_fault_c2h_all_random_seq extends vdma_mm_c2h_mst_seq;


	`uvm_object_utils(vdma_mm_fault_c2h_all_random_seq)

	function new (string name="vdma_mm_fault_c2h_all_random_seq");
		super.new(name);
    this.watchdog_cycle = 400000000;
	endfunction

	extern virtual function void genCfg();
	extern virtual task pre_genCfg();
  
  extern function T_SEQ_ITEM selectFaultCase(RatioFaultInjection_t fault_ratio);

  extern virtual function T_SEQ_ITEM             makeSeqItem_DataLenZero(T_SEQ_ITEM me);
  extern virtual function SeqItem_t              createDataLenZero_SeqItem(string name_postfix="");
  extern virtual protected function T_SEQ_ITEM_Q createSeqItemQ(string name_postfix="");
endclass:vdma_mm_fault_c2h_all_random_seq

function vdma_mm_fault_c2h_all_random_seq::T_SEQ_ITEM vdma_mm_fault_c2h_all_random_seq::makeSeqItem_DataLenZero(T_SEQ_ITEM me);
  vdma_seq_item created;
  
  created = me;
  created.desc.len = 0;
  
  created.intended_faultType = 0;
  
  return(created);
endfunction:makeSeqItem_DataLenZero

function vdma_mm_fault_c2h_all_random_seq::SeqItem_t vdma_mm_fault_c2h_all_random_seq::createDataLenZero_SeqItem(string name_postfix="");
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


  created.randomize();

  return(this.post_createSeqItem(created));
endfunction:createDataLenZero_SeqItem


function vdma_mm_fault_c2h_all_random_seq::T_SEQ_ITEM vdma_mm_fault_c2h_all_random_seq::selectFaultCase(RatioFaultInjection_t fault_ratio);
  T_SEQ_ITEM created;
  
  created = this.makeSeqItem_DataLenZero(this.createDataLenZero_SeqItem(""));

  return(created);   
endfunction : selectFaultCase


function vdma_mm_fault_c2h_all_random_seq::T_SEQ_ITEM_Q vdma_mm_fault_c2h_all_random_seq::createSeqItemQ(string name_postfix="");
  T_SEQ_ITEM    created;
  T_SEQ_ITEM_Q  q_created;
  
  if(FlipCoin(this.tcfg.fault_prob)) begin
    created = this.selectFaultCase(this.tcfg.fault_ratio);
    if(created == null) this.fatal("NULL","selectFaultCase return NULL !!"); 
    q_created.push_back(created);
  end//flipCoin
  else begin
    created = this.createSeqItem();
    q_created.push_back(created);
  end

  return(q_created);
endfunction:createSeqItemQ

function void vdma_mm_fault_c2h_all_random_seq::genCfg();
	// #GATHERING_PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start = 10;
	this.num_item_end   = 10;


	super.genCfg();
endfunction:genCfg


task vdma_mm_fault_c2h_all_random_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs
	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;

	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_MM_FAULT_C2H_ALL_RANDOM_SEQ_SVH__
