`ifndef __VDMA_MM_C2H_FULL_START_W_FIFO_SEQ_SVH__
`define __VDMA_MM_C2H_FULL_START_W_FIFO_SEQ_SVH__



class vdma_mm_c2h_full_start_w_fifo_seq extends vdma_mm_c2h_mst_seq;

  `uvm_object_utils(vdma_mm_c2h_full_start_w_fifo_seq)

  function new (string name="vdma_mm_c2h_full_start_w_fifo_seq");
	  super.new(name);
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();

  extern virtual function Len_t decideCstrLen();
endclass:vdma_mm_c2h_full_start_w_fifo_seq

function Len_t vdma_mm_c2h_full_start_w_fifo_seq::decideCstrLen();
  Len_t served_len;

  served_len = $urandom_range(1, 32);

  return(served_len);
endfunction

function void vdma_mm_c2h_full_start_w_fifo_seq::genCfg();
	  // #PKT is randomized within the below values
	  // At least num_item is over 1
	  this.num_item_start = 80;
	  this.num_item_end   = 80;
	
	  super.genCfg();
	
endfunction:genCfg

task vdma_mm_c2h_full_start_w_fifo_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs

        this.max_dma_size = 2;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;
  
	
	super.pre_genCfg();
endtask:pre_genCfg

 
`endif // __VDMA_MM_C2H_FULL_START_W_FIFO_SEQ_SVH__
