`ifndef __VDMA_MM_H2C_INTER_RESET_SEQ_SVH__
`define __VDMA_MM_H2C_INTER_RESET_SEQ_SVH__




class vdma_mm_h2c_inter_reset_seq extends vdma_mm_h2c_mst_seq;

  
  `uvm_object_utils(vdma_mm_h2c_inter_reset_seq)

  function new (string name="vdma_mm_h2c_inter_reset_seq");
	  super.new(name);
	  this.watchdog_cycle = 400000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();

endclass:vdma_mm_h2c_inter_reset_seq

function void vdma_mm_h2c_inter_reset_seq::genCfg();
	
	  this.num_item_start = 10;
	  this.num_item_end = 10;
	
	  super.genCfg();
	
endfunction:genCfg

task vdma_mm_h2c_inter_reset_seq::pre_genCfg();

	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = 1;
	this.preset_dma_size = this.min_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;
	
	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_MM_H2C_INTER_RESET_SEQ_SVH__
