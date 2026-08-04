`ifndef __VDMA_ST_FAULT_HOST_R_WRONG_RESP_SEQ_SVH__
`define __VDMA_ST_FAULT_HOST_R_WRONG_RESP_SEQ_SVH__




class vdma_st_fault_host_r_wrong_resp_seq extends vdma_st_h2c_mst_seq;

	typedef vdma_seq_item SeqItem_t;
	`uvm_object_utils(vdma_st_fault_host_r_wrong_resp_seq)

	function new (string name="vdma_st_fault_host_r_wrong_resp_seq");
		super.new(name);
    this.watchdog_cycle = 400000000;
	endfunction

	extern function void genCfg();

endclass:vdma_st_fault_host_r_wrong_resp_seq

function void vdma_st_fault_host_r_wrong_resp_seq::genCfg();
	// #PKT is randomized within the below values
	// At least num_item is over 1
  this.prob_pkt_gathering = 0;

	this.num_item_start = 50;
	this.num_item_end   = 50;

	super.genCfg();

endfunction:genCfg


`endif // __VDMA_ST_FAULT_HOST_R_WRONG_RESP_SEQ_SVH__
