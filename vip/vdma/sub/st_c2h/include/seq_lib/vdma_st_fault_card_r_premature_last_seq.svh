`ifndef __VDMA_ST_FAULT_CARD_R_PREMATURE_LAST_SEQ_SVH__
`define __VDMA_ST_FAULT_CARD_R_PREMATURE_LAST_SEQ_SVH__



class vdma_st_fault_card_r_premature_last_seq extends vdma_st_c2h_mst_seq;


	`uvm_object_utils(vdma_st_fault_card_r_premature_last_seq)

	function new (string name="vdma_st_fault_card_r_premature_last_seq");
		super.new(name);
	endfunction

	extern virtual function void genCfg();
	extern virtual task pre_genCfg();

	extern virtual function T_SEQ_ITEM createC2HFaultSeqItemQ(vdma_seq_item me);
	extern virtual protected function T_SEQ_ITEM_Q createSeqItemQ(string name_postfix="");

endclass:vdma_st_fault_card_r_premature_last_seq

function vdma_st_fault_card_r_premature_last_seq::T_SEQ_ITEM vdma_st_fault_card_r_premature_last_seq::createC2HFaultSeqItemQ(vdma_seq_item me);
	vdma_seq_item created;
	int selected;
	
	created = me;
	if( created.q_data.size() > 3) begin
		selected = this.pickRandUIntInTheRange2(0, created.q_data.size() -2);
	end
	else begin
		selected = 0;
	end
	
	created.q_data[selected].last = 1;
	
  created.intended_faultType = 5;

	return(created);
endfunction:createC2HFaultSeqItemQ

function vdma_st_fault_card_r_premature_last_seq::T_SEQ_ITEM_Q vdma_st_fault_card_r_premature_last_seq::createSeqItemQ(string name_postfix="");
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

function void vdma_st_fault_card_r_premature_last_seq::genCfg();
	// #PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start = 10;
	this.num_item_end = 10;

	super.genCfg();

endfunction:genCfg

task vdma_st_fault_card_r_premature_last_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs


	this.max_dma_size = 1024;
	this.min_dma_size = 255;
	this.preset_dma_size = this.max_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;


	super.pre_genCfg();
endtask:pre_genCfg

`endif // __VDMA_ST_FAULT_CARD_R_PREMATURE_LAST_SEQ_SVH__
