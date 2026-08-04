`ifndef __VDMA_ST_H2C_SMALL_GATHERING_SEQ_SVH__
`define __VDMA_ST_H2C_SMALL_GATHERING_SEQ_SVH__



class vdma_st_h2c_small_gathering_seq extends vdma_st_h2c_mst_seq;

  
  `uvm_object_utils(vdma_st_h2c_small_gathering_seq)

  function new (string name="vdma_st_h2c_small_gathering_seq");
	  super.new(name);
  endfunction
 
  extern virtual function void genCfg();
  extern virtual task pre_genCfg();

endclass:vdma_st_h2c_small_gathering_seq



function void vdma_st_h2c_small_gathering_seq::genCfg();
	// Probability of Packet gathering
	this.prob_pkt_gathering = 100;
	
	// #MID_PKT is randomized within the below values
	// At least num_packet is over 2 (START/END_PKT is necessary)
	this.pkt_gathering_num_packet_start = 2;
	this.pkt_gathering_num_packet_end	= 5;	
	
	// #GATHERING_PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start	= this.tcfg.ST_DUT_PARAM.H2C_DESCR_TABLE_SIZE;
	this.num_item_end	  = this.tcfg.ST_DUT_PARAM.H2C_DESCR_TABLE_SIZE;

	
	super.genCfg();
endfunction:genCfg


task vdma_st_h2c_small_gathering_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs
	this.max_dma_size = HOST_DATA_BYTE_WIDTH + this.tcfg.ST_DUT_PARAM.HAXI_ADDR_WIDTH - 1;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;
	
	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_ST_H2C_SMALL_GATHERING_SEQ_SVH__
