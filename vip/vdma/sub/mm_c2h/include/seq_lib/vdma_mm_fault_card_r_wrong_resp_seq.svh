`ifndef __VDMA_MM_FAULT_CARD_R_WRONG_RESP_SEQ_SVH__
`define __VDMA_MM_FAULT_CARD_R_WRONG_RESP_SEQ_SVH__




class vdma_mm_fault_card_r_wrong_resp_seq extends vdma_mm_c2h_mst_seq;

	typedef vdma_seq_item SeqItem_t;
	`uvm_object_utils(vdma_mm_fault_card_r_wrong_resp_seq)

	function new (string name="vdma_mm_fault_card_r_wrong_resp_seq");
		super.new(name);
	endfunction

	extern function void genCfg();

endclass:vdma_mm_fault_card_r_wrong_resp_seq

function void vdma_mm_fault_card_r_wrong_resp_seq::genCfg();
	// #PKT is randomized within the below values
	// At least num_item is over 1

	this.num_item_start = 10;
	this.num_item_end   = 10;

	super.genCfg();

endfunction:genCfg


`endif // __VDMA_MM_FAULT_CARD_R_WRONG_RESP_SEQ_SVH__
