`ifndef __VDMA_MM_FAULT_C2H_CONSTRAINED_RANDOM_SEQ_SVH__
`define __VDMA_MM_FAULT_C2H_CONSTRAINED_RANDOM_SEQ_SVH__



class vdma_mm_fault_c2h_constrained_random_seq extends vdma_mm_c2h_mst_seq;


	`uvm_object_utils(vdma_mm_fault_c2h_constrained_random_seq)

	function new (string name="vdma_mm_fault_c2h_constrained_random_seq");
		super.new(name);
    this.watchdog_cycle = 400000000;
	endfunction

	extern virtual function void genCfg();
	extern virtual task pre_genCfg();
  
  extern function T_SEQ_ITEM selectFaultCase(RatioFaultInjection_t fault_ratio);

	extern virtual function T_SEQ_ITEM createDataLenZero_SeqItemQ(T_SEQ_ITEM me);
  extern virtual function SeqItem_t createDataLenZero_SeqItem(string name_postfix="");
  
  extern virtual function T_SEQ_ITEM createPrematureLast_SeqItemQ(T_SEQ_ITEM me);
  extern virtual function T_SEQ_ITEM createNoLast_SeqItemQ(T_SEQ_ITEM me);
  extern virtual function T_SEQ_ITEM createWrongMty_SeqItemQ(T_SEQ_ITEM me);
  extern virtual function T_SEQ_ITEM createWrongDmaId_SeqItemQ(T_SEQ_ITEM me);
  
  
	extern virtual protected function T_SEQ_ITEM_Q createSeqItemQ(string name_postfix="");
endclass:vdma_mm_fault_c2h_constrained_random_seq

function vdma_mm_fault_c2h_constrained_random_seq::T_SEQ_ITEM vdma_mm_fault_c2h_constrained_random_seq::createDataLenZero_SeqItemQ(T_SEQ_ITEM me);
  vdma_seq_item created;
  
  created = me;
  created.desc.len = 0;
  
  return(created);
endfunction:createDataLenZero_SeqItemQ

function vdma_mm_fault_c2h_constrained_random_seq::SeqItem_t vdma_mm_fault_c2h_constrained_random_seq::createDataLenZero_SeqItem(string name_postfix="");
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

function vdma_mm_fault_c2h_constrained_random_seq::T_SEQ_ITEM vdma_mm_fault_c2h_constrained_random_seq::createPrematureLast_SeqItemQ(T_SEQ_ITEM me);
  vdma_seq_item created;
  int selected;
  
  created = me;
 
  if(created.q_data.size() > 3) begin
    selected = this.pickRandUIntInTheRange2(0, created.q_data.size()-1);
  end
  else begin
    selected = 0;
  end
  
  created.q_data[selected].last = 1;
  
  return(created);
endfunction:createPrematureLast_SeqItemQ


function vdma_mm_fault_c2h_constrained_random_seq::T_SEQ_ITEM vdma_mm_fault_c2h_constrained_random_seq::createNoLast_SeqItemQ(T_SEQ_ITEM me);
  vdma_seq_item created;
  
  created = me;
  created.q_data[$].last = 0;
  
  return(created);
endfunction:createNoLast_SeqItemQ



function vdma_mm_fault_c2h_constrained_random_seq::T_SEQ_ITEM vdma_mm_fault_c2h_constrained_random_seq::createWrongMty_SeqItemQ(T_SEQ_ITEM me);
  vdma_seq_item created;
 
  int add_wrong_mty = 0;
  
  add_wrong_mty = this.pickRandUIntInTheRange2(1, 63);
  
  created = me;
  created.q_data[$].side_info.mty = DutParamEmpty_t'(created.q_data[$].side_info.mty + add_wrong_mty);
 
  return(created);
endfunction:createWrongMty_SeqItemQ



function vdma_mm_fault_c2h_constrained_random_seq::T_SEQ_ITEM vdma_mm_fault_c2h_constrained_random_seq::createWrongDmaId_SeqItemQ(T_SEQ_ITEM me);
  vdma_seq_item created;
  
  created = me;
  for( int i = 0; i < created.q_data.size(); i++ ) begin
    created.q_data[i].side_info.dma_id = DutParamDmaId_t'(created.q_data[i].side_info.dma_id + WRONG_DMA_ID);
  end
   
  return(created);
endfunction:createWrongDmaId_SeqItemQ



function vdma_mm_fault_c2h_constrained_random_seq::T_SEQ_ITEM vdma_mm_fault_c2h_constrained_random_seq::selectFaultCase(RatioFaultInjection_t fault_ratio);
  T_SEQ_ITEM created;
  
  int select = fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO + fault_ratio.WEIGHT_CARD_R_PREMATURE_LAST + fault_ratio.WEIGHT_CARD_R_NO_LAST + fault_ratio.WEIGHT_CARD_R_WRONG_MTY + fault_ratio.WEIGHT_CARD_R_WRONG_DMA_ID;
  
  SelectFault_t select_fault;
  
  
  
  if($urandom_range(1, select) <= fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO) begin
    created = this.createDataLenZero_SeqItemQ(this.createDataLenZero_SeqItem(""));
    return(created);   
  end
  else if($urandom_range(1, select) <= fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO + fault_ratio.WEIGHT_CARD_R_PREMATURE_LAST) begin
    created = this.createPrematureLast_SeqItemQ(this.createSeqItem());
    return(created);
  end
  else if($urandom_range(1, select) <= fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO + fault_ratio.WEIGHT_CARD_R_PREMATURE_LAST + fault_ratio.WEIGHT_CARD_R_NO_LAST) begin
    created = this.createNoLast_SeqItemQ(this.createSeqItem());
    return(created);
  end
  else if($urandom_range(1, select) <= fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO + fault_ratio.WEIGHT_CARD_R_PREMATURE_LAST + fault_ratio.WEIGHT_CARD_R_NO_LAST + fault_ratio.WEIGHT_CARD_R_WRONG_MTY) begin
    created = this.createWrongMty_SeqItemQ(this.createSeqItem());
    return(created);
  end
  else if($urandom_range(1, select) <= fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO + fault_ratio.WEIGHT_CARD_R_PREMATURE_LAST + fault_ratio.WEIGHT_CARD_R_NO_LAST + fault_ratio.WEIGHT_CARD_R_WRONG_MTY + fault_ratio.WEIGHT_CARD_R_WRONG_DMA_ID) begin
    created = this.createWrongDmaId_SeqItemQ(this.createSeqItem());
    return(created); 
  end
  
  
  return(null);
endfunction : selectFaultCase


function vdma_mm_fault_c2h_constrained_random_seq::T_SEQ_ITEM_Q vdma_mm_fault_c2h_constrained_random_seq::createSeqItemQ(string name_postfix="");
  localparam bit NON_PKT_GATHERING  = 0;
  localparam bit PKT_GATHERING    = 1;

  T_SEQ_ITEM    created;
  T_SEQ_ITEM_Q  q_created;

  int       num_be_created;
  DmaId_t     startPkt_dma_id;
  
  if( this.getTransType() == ST_C2H ) begin
    if(FlipCoin(this.tcfg.fault_prob)) begin
      created = this.selectFaultCase(this.tcfg.fault_ratio);
      if(created == null) 
        this.fatal("NULL","selectFaultCase return NULL !!"); 
      q_created.push_back(created);
    end
    else begin
      created = this.createSeqItem();
      q_created.push_back(created);
    end
  end//C2H
  else if ( this.getTransType() == ST_H2C ) begin
    case(FlipCoin(this.prob_pkt_gathering))
      NON_PKT_GATHERING : begin
        created = this.createSeqItem();
        created.makeSoloPkt();
        q_created.push_back(created);
      end
      PKT_GATHERING : begin
        num_be_created = this.pickRandUIntInTheRange2(this.pkt_gathering_num_packet_start, this.pkt_gathering_num_packet_end);
        if(num_be_created < 2) this.reportFatal(
                          $sformatf("%s_GEN_GATHERING_PKT_FAILED", this.getName()),
                          $sformatf("Cannot generate GATHERING_PKT with one DESC"));
        for(int i=0; i<num_be_created; i++) begin
          created = this.createSeqItem($sformatf("pkt_gathering_seq%1d", i));
            if      (i == 0) begin       created.makeStartOfPacketGathering(); startPkt_dma_id=DutParamDmaId_t'(created.getDmaId()); end
            else if (i == num_be_created-1) created.makeEndOfPacketGathering();
            else begin
              created.makeIntermediateOfPacketGathering();
          end
            created.setDmaId(DutParamDmaId_t'(startPkt_dma_id));
            q_created.push_back(created);
        end
      end
    endcase
  end

  return(q_created);
endfunction:createSeqItemQ

function void vdma_mm_fault_c2h_constrained_random_seq::genCfg();
	// #GATHERING_PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start = this.tcfg.ST_DUT_PARAM.C2H_DESCR_TABLE_SIZE * 2;
	this.num_item_end   = this.tcfg.ST_DUT_PARAM.C2H_DESCR_TABLE_SIZE * 2;


	super.genCfg();
endfunction:genCfg


task vdma_mm_fault_c2h_constrained_random_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs
	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;

	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_MM_FAULT_C2H_CONSTRAINED_RANDOM_SEQ_SVH__
