`ifndef __VDMA_ST_FAULT_HOST_R_NO_LAST_SEQ_SVH__
`define __VDMA_ST_FAULT_HOST_R_NO_LAST_SEQ_SVH__




class vdma_st_fault_host_r_no_last_seq extends vdma_st_h2c_mst_seq;

  
  `uvm_object_utils(vdma_st_fault_host_r_no_last_seq)

  function new (string name="vdma_st_fault_host_r_no_last_seq");
	  super.new(name);
	  this.watchdog_cycle = 400000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  
  extern virtual function Addr_t  decideCstrAddr();
  extern virtual function FncId_t decideCstrMaxBL();

endclass:vdma_st_fault_host_r_no_last_seq

function Addr_t vdma_st_fault_host_r_no_last_seq::decideCstrAddr(); return(0); endfunction
function FncId_t vdma_st_fault_host_r_no_last_seq::decideCstrMaxBL(); return(0); endfunction

function void vdma_st_fault_host_r_no_last_seq::genCfg();
	  this.prob_pkt_gathering = 0;
  
	  this.num_item_start = 1;
	  this.num_item_end   = 1;
	
	  super.genCfg();
	
endfunction:genCfg

task vdma_st_fault_host_r_no_last_seq::pre_genCfg();

	this.max_dma_size = HOST_DATA_BYTE_WIDTH * 2;
	this.min_dma_size = HOST_DATA_BYTE_WIDTH * 2;
	this.preset_dma_size = this.min_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;
	
	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_ST_FAULT_HOST_R_NO_LAST_SEQ_SVH__
