`ifndef __VDMA_ST_H2C_MST_SEQ_SVH__
`define __VDMA_ST_H2C_MST_SEQ_SVH__



virtual class vdma_st_h2c_mst_seq extends vdma_st_mst_seq;
  
  typedef vdma_seq_item SeqItem_t;

  `uvm_declare_p_sequencer(vdma_st_h2c_mst_seqr)
  function new (string name="vdma_st_h2c_mst_seq");
	  super.new(name);
  endfunction

  extern virtual function DmaTransType_t getTransType();
  extern virtual protected function string getItemFamilyName();
  extern virtual function StringQ_t getInfoList_Cfg();

  extern virtual function SeqItem_t post_createSeqItem(SeqItem_t me);
  extern virtual protected function T_SEQ_ITEM_Q createSeqItemQ(string name_postfix="");

endclass:vdma_st_h2c_mst_seq



function string vdma_st_h2c_mst_seq::getItemFamilyName();
  return("ST_H2C_ITEM");
endfunction:getItemFamilyName



function DmaTransType_t vdma_st_h2c_mst_seq::getTransType();
  return(ST_H2C);
endfunction:getTransType



function StringQ_t vdma_st_h2c_mst_seq::getInfoList_Cfg();
  StringQ_t result;

  result = super.getInfoList_Cfg();
  result.push_back($sformatf(" --------------------------------------------------- "));
  result.push_back($sformatf(" * H2C gathering "));
  result.push_back($sformatf("    - Probability                     : %1d %%",  this.prob_pkt_gathering));
  result.push_back($sformatf("    - Number of packets per gathering : %1d~%1d", this.pkt_gathering_num_packet_start, pkt_gathering_num_packet_end));

  return(result);
endfunction:getInfoList_Cfg



function vdma_st_h2c_mst_seq::SeqItem_t vdma_st_h2c_mst_seq::post_createSeqItem(SeqItem_t me);
	return(me);
endfunction:post_createSeqItem



function vdma_mst_seq::T_SEQ_ITEM_Q vdma_st_h2c_mst_seq::createSeqItemQ(string name_postfix="");
  localparam bit NON_PKT_GATHERING  = 0;
  localparam bit PKT_GATHERING    = 1;

  T_SEQ_ITEM    created;
  T_SEQ_ITEM_Q  q_created;
  int       num_be_created;
  DmaId_t     startPkt_dma_id;
  
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
  
  return(q_created);
endfunction:createSeqItemQ

`endif // __VDMA_ST_H2C_MST_SEQ_SVH__
