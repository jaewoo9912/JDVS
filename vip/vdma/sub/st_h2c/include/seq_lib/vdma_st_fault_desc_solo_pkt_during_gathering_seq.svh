`ifndef __VDMA_ST_FAULT_DESC_SOLO_PKT_DURING_GATHERING_SEQ_SVH__
`define __VDMA_ST_FAULT_DESC_SOLO_PKT_DURING_GATHERING_SEQ_SVH__



class vdma_st_fault_desc_solo_pkt_during_gathering_seq extends vdma_st_h2c_mst_seq;


	`uvm_object_utils(vdma_st_fault_desc_solo_pkt_during_gathering_seq)

	function new (string name="vdma_st_fault_desc_solo_pkt_during_gathering_seq");
		super.new(name);
	endfunction

	extern virtual function void genCfg();
	extern virtual task pre_genCfg();

	extern virtual function T_SEQ_ITEM_Q createH2CFaultSeqItemQ(T_SEQ_ITEM created, int num_be_created, DmaId_t startPkt_dma_id);
	extern virtual protected function T_SEQ_ITEM_Q createSeqItemQ(string name_postfix="");

endclass:vdma_st_fault_desc_solo_pkt_during_gathering_seq

function vdma_st_fault_desc_solo_pkt_during_gathering_seq::T_SEQ_ITEM_Q vdma_st_fault_desc_solo_pkt_during_gathering_seq::createH2CFaultSeqItemQ(T_SEQ_ITEM created, int num_be_created, DmaId_t startPkt_dma_id);

	T_SEQ_ITEM_Q q_created;
	int rand_num = 0;
	
	rand_num = this.pickRandUIntInTheRange2(1, num_be_created - 2);
	
	for(int i=0; i<num_be_created; i++)begin
		created = super.createSeqItem($sformatf("pkt_gathering_seq%1d",i));
		if    (i == 0) begin created.makeStartOfPacketGathering(); startPkt_dma_id=DutParamDmaId_t'(created.getDmaId()); end
//    if    (i == 0) begin created.makeIntermediateOfPacketGathering() ; startPkt_dma_id=created.getDmaId(); end
		else if (i == rand_num)begin
			created.makeSoloPkt();
		end
		else if (i == num_be_created-1) created.makeEndOfPacketGathering();
		else begin
			created.makeIntermediateOfPacketGathering();
		end
		created.setDmaId(DutParamDmaId_t'(startPkt_dma_id));
    
    created.intended_faultType = 2;
    
		q_created.push_back(created);
	end

	return(q_created);
endfunction:createH2CFaultSeqItemQ

function vdma_st_fault_desc_solo_pkt_during_gathering_seq::T_SEQ_ITEM_Q vdma_st_fault_desc_solo_pkt_during_gathering_seq::createSeqItemQ(string name_postfix="");
	localparam bit NON_PKT_GATHERING  = 0;
	localparam bit PKT_GATHERING    = 1;

	T_SEQ_ITEM    created;
	T_SEQ_ITEM_Q  q_created;

	int       num_be_created;
	DmaId_t     startPkt_dma_id;


	if( this.getTransType() == ST_C2H ) begin
		created = this.createSeqItem();
		q_created.push_back(created);
	end
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
				if(FlipCoin(50))
//					q_created = this.createH2CFaultSeqItemQ(created, num_be_created, startPkt_dma_id);
				  return(this.createH2CFaultSeqItemQ(created, num_be_created, DutParamDmaId_t'(startPkt_dma_id)));
				else begin
					for(int i=0; i<num_be_created; i++)begin
						created = super.createSeqItem($sformatf("pkt_gathering_seq%1d",i));
						if    (i == 0) begin created.makeStartOfPacketGathering(); startPkt_dma_id=DutParamDmaId_t'(created.getDmaId()); end
						else if (i == num_be_created-1) created.makeEndOfPacketGathering();
						else begin
							created.makeIntermediateOfPacketGathering();
						end
						created.setDmaId(DutParamDmaId_t'(startPkt_dma_id));
						q_created.push_back(created);
					end
					return(q_created);
				end
			end
		endcase
	end

	return(q_created);
endfunction:createSeqItemQ

function void vdma_st_fault_desc_solo_pkt_during_gathering_seq::genCfg();
	// Probability of Packet gathering
	this.prob_pkt_gathering = 100;

	// #MID_PKT is randomized within the below values
	// At least num_packet is over 2 (START/END_PKT is necessary)
	this.pkt_gathering_num_packet_start = 3;
	this.pkt_gathering_num_packet_end = 3;

	// #GATHERING_PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start = 3;
	this.num_item_end = 3;


	super.genCfg();
endfunction:genCfg


task vdma_st_fault_desc_solo_pkt_during_gathering_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs
	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;

	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_ST_FAULT_DESC_SOLO_PKT_DURING_GATHERING_SEQ_SVH__
