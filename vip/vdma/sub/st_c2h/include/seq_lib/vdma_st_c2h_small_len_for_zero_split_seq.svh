`ifndef __VDMA_ST_C2H_SMALL_LEN_FOR_ZERO_SPLIT_SEQ_SVH__
`define __VDMA_ST_C2H_SMALL_LEN_FOR_ZERO_SPLIT_SEQ_SVH__



class vdma_st_c2h_small_len_for_zero_split_seq extends vdma_st_c2h_mst_seq;

  
  `uvm_object_utils(vdma_st_c2h_small_len_for_zero_split_seq)

  function new (string name="vdma_st_c2h_small_len_for_zero_split_seq");
	  super.new(name);
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  extern virtual function Addr_t decideCstrAddr();
  
  Addr_t rnd_addr = 64'hf00;
  
endclass:vdma_st_c2h_small_len_for_zero_split_seq

function vdma_st_c2h_small_len_for_zero_split_seq::Addr_t vdma_st_c2h_small_len_for_zero_split_seq::decideCstrAddr();
	this.rnd_addr = this.rnd_addr + 1;
	
	return(DutParamHostAddr_t'(this.rnd_addr));
endfunction:decideCstrAddr

function void vdma_st_c2h_small_len_for_zero_split_seq::genCfg();
	  // #PKT is randomized within the below values
	  // At least num_item is over 1
	  this.num_item_start = 255;
	  this.num_item_end   = 255;
	
	  super.genCfg();
	
endfunction:genCfg

task vdma_st_c2h_small_len_for_zero_split_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs
	

   	this.max_dma_size = 1;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;

	
	super.pre_genCfg();
endtask:pre_genCfg

`endif // __VDMA_ST_C2H_SMALL_LEN_FOR_ZERO_SPLIT_SEQ_SVH__
