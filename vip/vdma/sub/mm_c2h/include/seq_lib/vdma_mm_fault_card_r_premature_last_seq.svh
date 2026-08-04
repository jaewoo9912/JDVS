`ifndef __VDMA_MM_FAULT_CARD_R_PREMATURE_LAST_SEQ_SVH__
`define __VDMA_MM_FAULT_CARD_R_PREMATURE_LAST_SEQ_SVH__



class vdma_mm_fault_card_r_premature_last_seq extends vdma_mm_c2h_mst_seq;


	`uvm_object_utils(vdma_mm_fault_card_r_premature_last_seq)

	function new (string name="vdma_mm_fault_card_r_premature_last_seq");
		super.new(name);
	endfunction

	extern virtual function void genCfg();
	extern virtual task pre_genCfg();

endclass:vdma_mm_fault_card_r_premature_last_seq


function void vdma_mm_fault_card_r_premature_last_seq::genCfg();
	// #PKT is randomized within the below values
	// At least num_item is over 1
	this.num_item_start = 1;
	this.num_item_end   = 1;

	super.genCfg();

endfunction:genCfg

task vdma_mm_fault_card_r_premature_last_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs


	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;


	super.pre_genCfg();
endtask:pre_genCfg

`endif // __VDMA_MM_FAULT_CARD_R_PREMATURE_LAST_SEQ_SVH__
