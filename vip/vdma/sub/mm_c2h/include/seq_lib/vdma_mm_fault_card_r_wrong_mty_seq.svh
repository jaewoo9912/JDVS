`ifndef __VDMA_MM_FAULT_CARD_R_WRONG_MTY_SEQ_SVH__
`define __VDMA_MM_FAULT_CARD_R_WRONG_MTY_SEQ_SVH__



class vdma_mm_fault_card_r_wrong_mty_seq extends vdma_mm_c2h_mst_seq;


	`uvm_object_utils(vdma_mm_fault_card_r_wrong_mty_seq)

	function new (string name="vdma_mm_fault_card_r_wrong_mty_seq");
		super.new(name);
	endfunction

	extern virtual function void genCfg();
	extern virtual task pre_genCfg();

	extern virtual function T_SEQ_ITEM createC2HFaultSeqItemQ(vdma_seq_item me);
	extern virtual protected function T_SEQ_ITEM_Q createSeqItemQ(string name_postfix="");

endclass:vdma_mm_fault_card_r_wrong_mty_seq

function vdma_mm_fault_card_r_wrong_mty_seq::T_SEQ_ITEM vdma_mm_fault_card_r_wrong_mty_seq::createC2HFaultSeqItemQ(vdma_seq_item me);
	vdma_seq_item created;
	int add_mty_num = 0;
	
	add_mty_num = this.pickRandUIntInTheRange2(1, 63);

	created = me;
	created.q_data[$].side_info.mty = DutParamEmpty_t'(created.q_data[$].side_info.mty + add_mty_num);
  
  created.intended_faultType = 7;

	return(created);
endfunction:createC2HFaultSeqItemQ

function vdma_mm_fault_card_r_wrong_mty_seq::T_SEQ_ITEM_Q vdma_mm_fault_card_r_wrong_mty_seq::createSeqItemQ(string name_postfix="");
	localparam bit NON_PKT_GATHERING  = 0;
	localparam bit PKT_GATHERING    = 1;

	T_SEQ_ITEM    created;
	T_SEQ_ITEM_Q  q_created;

	int       num_be_created;
	DmaId_t     startPkt_dma_id;


	if( this.getTransType() == ST_C2H ) begin
		created = this.createSeqItem();
		if(FlipCoin(50))
			q_created.push_back(created);
		else
			q_created.push_back(this.createC2HFaultSeqItemQ(created));
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

function void vdma_mm_fault_card_r_wrong_mty_seq::genCfg();
	// #PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start = 10;
	this.num_item_end = 10;

	super.genCfg();

endfunction:genCfg

task vdma_mm_fault_card_r_wrong_mty_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs


	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;


	super.pre_genCfg();
endtask:pre_genCfg

`endif // __VDMA_MM_FAULT_CARD_R_WRONG_MTY_SEQ_SVH__
