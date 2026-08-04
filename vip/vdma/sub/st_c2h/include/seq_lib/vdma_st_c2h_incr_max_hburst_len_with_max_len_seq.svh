`ifndef __VDMA_ST_C2H_INCR_MAX_HBURST_LEN_WITH_MAX_LEN_SEQ_SVH__
`define __VDMA_ST_C2H_INCR_MAX_HBURST_LEN_WITH_MAX_LEN_SEQ_SVH__




class vdma_st_c2h_incr_max_hburst_len_with_max_len_seq extends vdma_st_c2h_mst_seq;

   
  `uvm_object_utils(vdma_st_c2h_incr_max_hburst_len_with_max_len_seq)
  
  function new (string name="vdma_st_c2h_incr_max_hburst_len_with_max_len_seq");
	  super.new(name);
	  this.watchdog_cycle = 200000000;

  endfunction
  
  int count = 0;
  
  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  extern virtual function FncId_t decideCstrMaxBL();
endclass:vdma_st_c2h_incr_max_hburst_len_with_max_len_seq

function vdma_st_c2h_incr_max_hburst_len_with_max_len_seq::FncId_t vdma_st_c2h_incr_max_hburst_len_with_max_len_seq::decideCstrMaxBL();
	AxiMaxLen_t being_static_max_hburst_len;
	
	for(int i = 0; i <= count; i++) begin
		being_static_max_hburst_len = i;
	end
	count++;
	
	return(being_static_max_hburst_len);
endfunction:decideCstrMaxBL


function void vdma_st_c2h_incr_max_hburst_len_with_max_len_seq::genCfg();
	  this.num_item_start = 256;
	  this.num_item_end   = 256;
	  
	  super.genCfg();
	
endfunction:genCfg


task vdma_st_c2h_incr_max_hburst_len_with_max_len_seq::pre_genCfg();

	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = MAX_DMA_LEN;//this.max_dma_size;
	this.preset_dma_size = this.min_dma_size;
	
	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_ST_C2H_INCR_MAX_HBURST_LEN_WITH_MAX_LEN_SEQ_SVH__
