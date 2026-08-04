`ifndef __VDMA_ST_H2C_MAX_LEN_FOR_COV_SEQ_SVH__
`define __VDMA_ST_H2C_MAX_LEN_FOR_COV_SEQ_SVH__




class vdma_st_h2c_max_len_for_cov_seq extends vdma_st_h2c_mst_seq;

  local int count = 0;
   
  `uvm_object_utils(vdma_st_h2c_max_len_for_cov_seq)

  function new (string name="vdma_st_h2c_max_len_for_cov_seq");
	  super.new(name);
    this.watchdog_cycle = 2000000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  extern virtual function Len_t decideCstrLen();
  
endclass:vdma_st_h2c_max_len_for_cov_seq


function void vdma_st_h2c_max_len_for_cov_seq::genCfg();
	  this.prob_pkt_gathering = 0;
	
	  this.num_item_start = 3;
	  this.num_item_end   = 3;

	  
	  super.genCfg();
	
endfunction:genCfg


function Len_t vdma_st_h2c_max_len_for_cov_seq::decideCstrLen();
  Len_t return_len;
  
  if(this.count == 0)      return_len = 1;
  else if(this.count == 1) return_len = MAX_DMA_LEN;
  else                     return_len = 1;
  
  this.count++;
  return(return_len);
endfunction


task vdma_st_h2c_max_len_for_cov_seq::pre_genCfg();

	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = MAX_DMA_LEN;//this.max_dma_size;
	this.preset_dma_size = this.min_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;
	
	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_ST_H2C_MAX_LEN_SEQ_SVH__
