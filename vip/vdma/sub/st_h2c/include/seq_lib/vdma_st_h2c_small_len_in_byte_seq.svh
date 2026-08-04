`ifndef __VDMA_ST_H2C_SMALL_LEN_IN_BYTE_SEQ_SVH__
`define __VDMA_ST_H2C_SMALL_LEN_IN_BYTE_SEQ_SVH__



class vdma_st_h2c_small_len_in_byte_seq extends vdma_st_h2c_mst_seq;

  
  `uvm_object_utils(vdma_st_h2c_small_len_in_byte_seq)

  function new (string name="vdma_st_h2c_small_len_in_byte_seq");
	  super.new(name);
  endfunction
 
  extern virtual function void genCfg();
  extern virtual task pre_genCfg();

endclass:vdma_st_h2c_small_len_in_byte_seq



function void vdma_st_h2c_small_len_in_byte_seq::genCfg();
	// Probability of Packet gathering

	this.prob_pkt_gathering = 30;
	
	// #MID_PKT is randomized within the below values
	// At least num_packet is over 2 (START/END_PKT is necessary)
	// #GATHERING_PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start	= this.tcfg.ST_DUT_PARAM.H2C_DESCR_TABLE_SIZE * 2;
	this.num_item_end	  = this.tcfg.ST_DUT_PARAM.H2C_DESCR_TABLE_SIZE * 2;

	
	super.genCfg();
endfunction:genCfg


task vdma_st_h2c_small_len_in_byte_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs
	this.max_dma_size = HOST_DATA_BYTE_WIDTH + this.tcfg.ST_DUT_PARAM.HAXI_ADDR_WIDTH - 1;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;
  this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;
	
	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_ST_H2C_SMALL_LEN_IN_BYTE_SEQ_SVH__
