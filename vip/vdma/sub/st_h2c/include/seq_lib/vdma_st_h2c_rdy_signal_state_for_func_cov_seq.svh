`ifndef __VDMA_ST_H2C_RDY_SIGNAL_STATE_FOR_FUNC_COV_SEQ_SVH__
`define __VDMA_ST_H2C_RDY_SIGNAL_STATE_FOR_FUNC_COV_SEQ_SVH__



class vdma_st_h2c_rdy_signal_state_for_func_cov_seq extends vdma_st_h2c_mst_seq;

  
  `uvm_object_utils(vdma_st_h2c_rdy_signal_state_for_func_cov_seq)

  function new (string name="vdma_st_h2c_rdy_signal_state_for_func_cov_seq");
	  super.new(name);
  endfunction
 
  extern virtual function void genCfg();
  extern virtual task pre_genCfg();

endclass:vdma_st_h2c_rdy_signal_state_for_func_cov_seq



function void vdma_st_h2c_rdy_signal_state_for_func_cov_seq::genCfg();
	// Probability of Packet gathering

	this.prob_pkt_gathering = 0;
	
	// #MID_PKT is randomized within the below values
	// At least num_packet is over 2 (START/END_PKT is necessary)
	// #GATHERING_PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start	= this.tcfg.ST_DUT_PARAM.H2C_DESCR_TABLE_SIZE * 2;
	this.num_item_end	  = this.tcfg.ST_DUT_PARAM.H2C_DESCR_TABLE_SIZE * 2;

	
	super.genCfg();
endfunction:genCfg


task vdma_st_h2c_rdy_signal_state_for_func_cov_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs
	this.max_dma_size = 32768;
	this.min_dma_size = 32768;
	this.preset_dma_size = this.max_dma_size;
  this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;
	
	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_ST_H2C_RDY_SIGNAL_STATE_FOR_FUNC_COV_SEQ_SVH__
