`ifndef __VDMA_ST_FAULT_H2C_ALL_RANDOM_SEQ_SVH__
`define __VDMA_ST_FAULT_H2C_ALL_RANDOM_SEQ_SVH__



class vdma_st_fault_h2c_all_random_seq extends vdma_st_h2c_mst_seq;


  `uvm_object_utils(vdma_st_fault_h2c_all_random_seq)

  function new (string name="vdma_st_fault_h2c_all_random_seq");
	  super.new(name);
    this.watchdog_cycle = 400000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  
  extern function T_SEQ_ITEM selectFault_2_Case(RatioFaultInjection_t fault_ratio);
  extern function T_SEQ_ITEM_Q selectFault_5_Case(RatioFaultInjection_t fault_ratio, T_SEQ_ITEM me, int num_be_created, DmaId_t startPkt_dma_id);

  extern virtual function T_SEQ_ITEM_Q createMidPkt_SeqItemQ(T_SEQ_ITEM created, int num_be_created, DmaId_t startPkt_dma_id);
  extern virtual function T_SEQ_ITEM_Q createSoloPkt_SeqItemQ(T_SEQ_ITEM created, int num_be_created, DmaId_t startPkt_dma_id);
  extern virtual function T_SEQ_ITEM_Q createStartPkt_SeqItemQ(T_SEQ_ITEM created, int num_be_created, DmaId_t startPkt_dma_id);
  extern virtual function T_SEQ_ITEM_Q createEndPkt_SeqItemQ(T_SEQ_ITEM created, int num_be_created, DmaId_t startPkt_dma_id);
  
  extern virtual function T_SEQ_ITEM createDataLenZero_SeqItemQ(T_SEQ_ITEM me);
	extern virtual function T_SEQ_ITEM_Q createDataLenZeroPkt_SeqItemQ(T_SEQ_ITEM created, int num_be_created, DmaId_t startPkt_dma_id);
  extern virtual function SeqItem_t createDataLenZero_SeqItem(string name_postfix="");
  
	extern virtual protected function T_SEQ_ITEM_Q createSeqItemQ(string name_postfix="");

endclass:vdma_st_fault_h2c_all_random_seq


function vdma_st_fault_h2c_all_random_seq::T_SEQ_ITEM vdma_st_fault_h2c_all_random_seq::createDataLenZero_SeqItemQ(T_SEQ_ITEM me);
  vdma_seq_item created;
  
  created = me;
  created.desc.len = 0;
  
  created.intended_faultType = 0;
  
  return(created);
endfunction:createDataLenZero_SeqItemQ


function vdma_st_fault_h2c_all_random_seq::T_SEQ_ITEM_Q vdma_st_fault_h2c_all_random_seq::createDataLenZeroPkt_SeqItemQ(T_SEQ_ITEM created, int num_be_created, DmaId_t startPkt_dma_id);

  T_SEQ_ITEM_Q q_created;
  
  for(int i=0; i<num_be_created; i++)begin
//    created = super.createSeqItem($sformatf("pkt_gathering_seq%1d",i));
    if    (i == 0) begin 
      created = super.createSeqItem($sformatf("pkt_gathering_seq%1d", i));
      created.makeStartOfPacketGathering();
      startPkt_dma_id=DutParamDmaId_t'(created.getDmaId()); end
    else if (i == num_be_created-1) begin
      created = super.createSeqItem($sformatf("pkt_gathering_seq%1d", i));
      created.makeEndOfPacketGathering();
    end
    else if (i == 1) begin
      created = this.createDataLenZero_SeqItemQ(this.createDataLenZero_SeqItem($sformatf("pkt_gathering_seq%1d", i)));
      created.makeIntermediateOfPacketGathering();
    end
    else begin
      created = super.createSeqItem($sformatf("pkt_gathering_seq%1d", i));
      created.makeIntermediateOfPacketGathering();
    end
    
    created.setDmaId(DutParamDmaId_t'(startPkt_dma_id));
    q_created.push_back(created);
  end

  return(q_created);
endfunction:createDataLenZeroPkt_SeqItemQ


function vdma_st_fault_h2c_all_random_seq::SeqItem_t vdma_st_fault_h2c_all_random_seq::createDataLenZero_SeqItem(string name_postfix="");
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


function vdma_st_fault_h2c_all_random_seq::T_SEQ_ITEM_Q vdma_st_fault_h2c_all_random_seq::createMidPkt_SeqItemQ(T_SEQ_ITEM created, int num_be_created, DmaId_t startPkt_dma_id);

	T_SEQ_ITEM_Q q_created;
  int rand_num = 0;
  
	for(int i=0; i<num_be_created; i++)begin
		created = super.createSeqItem($sformatf("pkt_gathering_seq%1d",i));
    if    (i == 0) begin 
      created.makeIntermediateOfPacketGathering() ; 
      startPkt_dma_id=DutParamDmaId_t'(created.getDmaId());
      created.intended_faultType = 1;
    end
		else if (i == 1) created.makeStartOfPacketGathering();
    else if (i == num_be_created-1) created.makeEndOfPacketGathering();
    else
      created.makeIntermediateOfPacketGathering();
    
		created.setDmaId(DutParamDmaId_t'(startPkt_dma_id));
		q_created.push_back(created);
	end

	return(q_created);
endfunction:createMidPkt_SeqItemQ


function vdma_st_fault_h2c_all_random_seq::T_SEQ_ITEM_Q vdma_st_fault_h2c_all_random_seq::createSoloPkt_SeqItemQ(T_SEQ_ITEM created, int num_be_created, DmaId_t startPkt_dma_id);

  T_SEQ_ITEM_Q q_created;
  int rand_num = 0;
  
  
  for(int i=0; i<num_be_created; i++)begin
    created = super.createSeqItem($sformatf("pkt_gathering_seq%1d",i));
    if    (i == 0) begin 
      created.makeStartOfPacketGathering(); 
      startPkt_dma_id=DutParamDmaId_t'(created.getDmaId());
    end
    else if (i == 1) begin
      created.makeSoloPkt();
      created.intended_faultType = 2;
    end
    else if (i == num_be_created-1) created.makeEndOfPacketGathering();
    else begin
      created.makeIntermediateOfPacketGathering();
    end
    created.setDmaId(DutParamDmaId_t'(startPkt_dma_id));
    q_created.push_back(created);
  end

  return(q_created);
endfunction:createSoloPkt_SeqItemQ


function vdma_st_fault_h2c_all_random_seq::T_SEQ_ITEM_Q vdma_st_fault_h2c_all_random_seq::createStartPkt_SeqItemQ(T_SEQ_ITEM created, int num_be_created, DmaId_t startPkt_dma_id);

  T_SEQ_ITEM_Q q_created;
  int rand_num = 0;
  
  for(int i=0; i<num_be_created; i++)begin
    created = super.createSeqItem($sformatf("pkt_gathering_seq%1d",i));
    if    (i == 0) begin created.makeStartOfPacketGathering(); startPkt_dma_id=DutParamDmaId_t'(created.getDmaId()); end
    else if (i == 1) begin
      created.makeStartOfPacketGathering();
      created.intended_faultType = 3;
    end
    else if (i == num_be_created-1) created.makeEndOfPacketGathering();
    else begin
      created.makeIntermediateOfPacketGathering();
    end
    created.setDmaId(DutParamDmaId_t'(startPkt_dma_id));
    q_created.push_back(created);
  end

  return(q_created);
endfunction:createStartPkt_SeqItemQ


function vdma_st_fault_h2c_all_random_seq::T_SEQ_ITEM_Q vdma_st_fault_h2c_all_random_seq::createEndPkt_SeqItemQ(T_SEQ_ITEM created, int num_be_created, DmaId_t startPkt_dma_id);

  T_SEQ_ITEM_Q q_created;
  
  
  for(int i=0; i<num_be_created; i++)begin
    created = super.createSeqItem($sformatf("pkt_gathering_seq%1d",i));
    if    (i == 0) begin 
      created.makeEndOfPacketGathering(); 
      startPkt_dma_id=DutParamDmaId_t'(created.getDmaId());
      created.intended_faultType = 13;
    end
    else if (i == 1) created.makeStartOfPacketGathering();
    else if (i == num_be_created-1) created.makeEndOfPacketGathering();
    else
      created.makeIntermediateOfPacketGathering();
    
    created.setDmaId(DutParamDmaId_t'(startPkt_dma_id));
    q_created.push_back(created);
  end

  return(q_created);
endfunction:createEndPkt_SeqItemQ


function vdma_st_fault_h2c_all_random_seq::T_SEQ_ITEM vdma_st_fault_h2c_all_random_seq::selectFault_2_Case(RatioFaultInjection_t fault_ratio);
  T_SEQ_ITEM created;
  
  int select = fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO;
 
  if($urandom_range(1, select) <= fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO) begin
    created = this.createDataLenZero_SeqItemQ(this.createDataLenZero_SeqItem());
    return(created);   
  end
  
  return(null);
endfunction : selectFault_2_Case


function vdma_st_fault_h2c_all_random_seq::T_SEQ_ITEM_Q vdma_st_fault_h2c_all_random_seq::selectFault_5_Case(RatioFaultInjection_t fault_ratio, T_SEQ_ITEM me, int num_be_created, DmaId_t startPkt_dma_id);
  T_SEQ_ITEM_Q created;
  
  int select = fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO + fault_ratio.WEIGHT_DESC_MID_OF_PKT_BEFORE_START_OF_PKT + fault_ratio.WEIGHT_DESC_SOLO_OF_PKT_DURING_GATHERING + fault_ratio.WEIGHT_DESC_START_OF_PKT_DURING_GATHERING + fault_ratio.WEIGHT_DESC_END_OF_PKT_BEFORE_START_PKT;
  
  if($urandom_range(1, select) <= fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO) begin
   return(this.createDataLenZeroPkt_SeqItemQ(me, num_be_created, DutParamDmaId_t'(startPkt_dma_id)));
  end
  else if($urandom_range(1, select) <= fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO + fault_ratio.WEIGHT_DESC_MID_OF_PKT_BEFORE_START_OF_PKT) begin
    return(this.createMidPkt_SeqItemQ(me, num_be_created, DutParamDmaId_t'(startPkt_dma_id)));
  end
  else if($urandom_range(1, select) <= fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO + fault_ratio.WEIGHT_DESC_MID_OF_PKT_BEFORE_START_OF_PKT + fault_ratio.WEIGHT_DESC_SOLO_OF_PKT_DURING_GATHERING) begin
    return(this.createSoloPkt_SeqItemQ(me, num_be_created, DutParamDmaId_t'(startPkt_dma_id)));
  end
  else if($urandom_range(1, select) <= fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO + fault_ratio.WEIGHT_DESC_MID_OF_PKT_BEFORE_START_OF_PKT + fault_ratio.WEIGHT_DESC_SOLO_OF_PKT_DURING_GATHERING + fault_ratio.WEIGHT_DESC_START_OF_PKT_DURING_GATHERING) begin
    return(this.createStartPkt_SeqItemQ(me, num_be_created, DutParamDmaId_t'(startPkt_dma_id)));
  end
  else if($urandom_range(1, select) <= fault_ratio.WEIGHT_DESC_DATA_LENGTH_IS_ZERO + fault_ratio.WEIGHT_DESC_MID_OF_PKT_BEFORE_START_OF_PKT + fault_ratio.WEIGHT_DESC_SOLO_OF_PKT_DURING_GATHERING + fault_ratio.WEIGHT_DESC_START_OF_PKT_DURING_GATHERING + fault_ratio.WEIGHT_DESC_END_OF_PKT_BEFORE_START_PKT) begin
    return(this.createEndPkt_SeqItemQ(me, num_be_created, DutParamDmaId_t'(startPkt_dma_id)));
  end

 
  return(created);
endfunction : selectFault_5_Case


function vdma_st_fault_h2c_all_random_seq::T_SEQ_ITEM_Q vdma_st_fault_h2c_all_random_seq::createSeqItemQ(string name_postfix="");
	localparam bit NON_PKT_GATHERING  = 0;
	localparam bit PKT_GATHERING    = 1;

	T_SEQ_ITEM    created;
	T_SEQ_ITEM_Q  q_created;
  T_SEQ_ITEM_Q  q_for_check;

	int       num_be_created;
	DmaId_t     startPkt_dma_id;
  
  real prob_fault_pkt_gathering = 0;
  
  if( (this.tcfg.fault_ratio.WEIGHT_DESC_MID_OF_PKT_BEFORE_START_OF_PKT > 0) || (this.tcfg.fault_ratio.WEIGHT_DESC_SOLO_OF_PKT_DURING_GATHERING > 0) || (this.tcfg.fault_ratio.WEIGHT_DESC_START_OF_PKT_DURING_GATHERING > 0) || (this.tcfg.fault_ratio.WEIGHT_DESC_END_OF_PKT_BEFORE_START_PKT > 0))
     prob_fault_pkt_gathering = 100;
  else
     prob_fault_pkt_gathering = this.prob_pkt_gathering;
  

  
  if( this.getTransType() == ST_C2H ) begin
    created = this.createSeqItem();
    q_created.push_back(created);
  end
  else if ( this.getTransType() == ST_H2C ) begin
    if(FlipCoin(this.tcfg.fault_prob)) begin
      case(FlipCoin(prob_fault_pkt_gathering))
        NON_PKT_GATHERING : begin
          created = this.selectFault_2_Case(this.tcfg.fault_ratio);
          if(created == null)
            this.fatal("NULL", "selectFault_2_Case returns null !!");
          created.makeSoloPkt();
          q_created.push_back(created);
        end
        PKT_GATHERING : begin
          num_be_created = this.pickRandUIntInTheRange2(this.pkt_gathering_num_packet_start, this.pkt_gathering_num_packet_end);
          if(num_be_created < 2) this.reportFatal(
                            $sformatf("%s_GEN_GATHERING_PKT_FAILED", this.getName()),
                            $sformatf("Cannot generate GATHERING_PKT with one DESC"));
          q_for_check = this.selectFault_5_Case(this.tcfg.fault_ratio, created, num_be_created, DutParamDmaId_t'(startPkt_dma_id));
          if(q_for_check.size() == 0)
            this.fatal("NULL","selectFault_4_Case returns NULL !!");
          return(this.selectFault_5_Case(this.tcfg.fault_ratio, created, num_be_created, DutParamDmaId_t'(startPkt_dma_id)));
        end
      endcase
    end//if(fault_prob)
    else begin
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
    
  end

	return(q_created);
endfunction:createSeqItemQ

function void vdma_st_fault_h2c_all_random_seq::genCfg();
	// Probability of Packet gathering
	this.prob_pkt_gathering = 30;

	// #MID_PKT is randomized within the below values
	// At least num_packet is over 2 (START/END_PKT is necessary)
	this.pkt_gathering_num_packet_start = 3;
	this.pkt_gathering_num_packet_end = 12;

	// #GATHERING_PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start = 20;
	this.num_item_end = 20;


	super.genCfg();
endfunction:genCfg


task vdma_st_fault_h2c_all_random_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs
	this.max_dma_size = 1500;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;

	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_ST_FAULT_H2C_ALL_RANDOM_SEQ_SVH__
