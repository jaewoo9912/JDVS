`ifndef __VDMA_ST_C2H_MAX_LEN_SEQ_SVH__
`define __VDMA_ST_C2H_MAX_LEN_SEQ_SVH__




class vdma_st_c2h_max_len_seq extends vdma_st_c2h_mst_seq;

  `uvm_object_utils(vdma_st_c2h_max_len_seq)

  function new (string name="vdma_st_c2h_max_len_seq");
	  super.new(name);
	  this.watchdog_cycle = 2000000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  extern virtual function Len_t decideCstrLen();
  
endclass:vdma_st_c2h_max_len_seq


function void vdma_st_c2h_max_len_seq::genCfg();
	  this.num_item_start = this.tcfg.ST_DUT_PARAM.C2H_DESCR_TABLE_SIZE * 2;
	  this.num_item_end   = this.tcfg.ST_DUT_PARAM.C2H_DESCR_TABLE_SIZE * 2;
	  
	  super.genCfg();
	
endfunction:genCfg


function vdma_st_c2h_max_len_seq::Len_t vdma_st_c2h_max_len_seq::decideCstrLen();
  return(MAX_DMA_LEN);
endfunction:decideCstrLen


task vdma_st_c2h_max_len_seq::pre_genCfg();

	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = MAX_DMA_LEN;//this.max_dma_size;
	this.preset_dma_size = this.min_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;
	
	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_ST_C2H_MAX_LEN_SEQ_SVH__
