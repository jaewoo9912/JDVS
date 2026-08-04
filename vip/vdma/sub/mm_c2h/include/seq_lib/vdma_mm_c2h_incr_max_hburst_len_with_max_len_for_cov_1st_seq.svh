`ifndef __VDMA_MM_C2H_INCR_MAX_HBURST_LEN_WITH_MAX_LEN_FOR_COV_1ST_SEQ_SVH__
`define __VDMA_MM_C2H_INCR_MAX_HBURST_LEN_WITH_MAX_LEN_FOR_COV_1ST_SEQ_SVH__




class vdma_mm_c2h_incr_max_hburst_len_with_max_len_for_cov_1st_seq extends vdma_mm_c2h_mst_seq;

   
  `uvm_object_utils(vdma_mm_c2h_incr_max_hburst_len_with_max_len_for_cov_1st_seq)
  
  function new (string name="vdma_mm_c2h_incr_max_hburst_len_with_max_len_for_cov_1st_seq");
	  super.new(name);
	  this.watchdog_cycle = 200000000;

  endfunction
  
  int count = 0;
  
  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  extern virtual function FncId_t decideCstrMaxBL();
endclass:vdma_mm_c2h_incr_max_hburst_len_with_max_len_for_cov_1st_seq

function vdma_mm_c2h_incr_max_hburst_len_with_max_len_for_cov_1st_seq::FncId_t vdma_mm_c2h_incr_max_hburst_len_with_max_len_for_cov_1st_seq::decideCstrMaxBL();
	AxiMaxLen_t being_static_max_hburst_len;
	
  being_static_max_hburst_len = this.count;
	this.count++;
	
	return(being_static_max_hburst_len);
endfunction:decideCstrMaxBL


function void vdma_mm_c2h_incr_max_hburst_len_with_max_len_for_cov_1st_seq::genCfg();
	  this.num_item_start = 128;
	  this.num_item_end   = 128;
	  
	  super.genCfg();
	
endfunction:genCfg


task vdma_mm_c2h_incr_max_hburst_len_with_max_len_for_cov_1st_seq::pre_genCfg();

	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = MAX_DMA_LEN;//this.max_dma_size;
	this.preset_dma_size = this.min_dma_size;
	
	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_MM_C2H_INCR_MAX_HBURST_LEN_WITH_MAX_LEN_FOR_COV_1ST_SEQ_SVH__
