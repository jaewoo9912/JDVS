`ifndef __VDMA_ST_H2C_DESC_BACK_PRESSURE_FOR_NUM_ENTRY_COV_SEQ_SVH__
`define __VDMA_ST_H2C_DESC_BACK_PRESSURE_FOR_NUM_ENTRY_COV_SEQ_SVH__



class vdma_st_h2c_desc_back_pressure_for_num_entry_cov_seq extends vdma_st_h2c_mst_seq;

  `uvm_object_utils(vdma_st_h2c_desc_back_pressure_for_num_entry_cov_seq)

  function new (string name="vdma_st_h2c_desc_back_pressure_for_num_entry_cov_seq");
	  super.new(name);
  endfunction
 
  extern virtual function void genCfg();
  extern virtual task pre_genCfg();

  extern virtual function SeqItem_t post_createSeqItem(SeqItem_t me);

endclass:vdma_st_h2c_desc_back_pressure_for_num_entry_cov_seq



function void vdma_st_h2c_desc_back_pressure_for_num_entry_cov_seq::genCfg();
	// Probability of Packet gathering
	this.prob_pkt_gathering = 0;
	
	// #DESC_BACK_PRESSURE_FOR_NUM_ENTRY_COV_PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start	= 340;
	this.num_item_end	  = 340;
	
	super.genCfg();
endfunction:genCfg


task vdma_st_h2c_desc_back_pressure_for_num_entry_cov_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs
	this.max_dma_size = 64; // 4096;
	this.min_dma_size = 64; 
	this.preset_dma_size = this.max_dma_size;
	
	super.pre_genCfg();
endtask:pre_genCfg


function vdma_st_h2c_mst_seq::SeqItem_t vdma_st_h2c_desc_back_pressure_for_num_entry_cov_seq::post_createSeqItem(SeqItem_t me);
  me.makeIntrReq();
  me.makeStatNoReq();
  return(me);
endfunction:post_createSeqItem

`endif // __VDMA_ST_H2C_DESC_BACK_PRESSURE_FOR_NUM_ENTRY_COV_SEQ_SVH__
