`ifndef __VDMA_ST_C2H_512MIB_ADdR_ALIGNED_SEQ_SVH__
`define __VDMA_ST_C2H_512MIB_ADdR_ALIGNED_SEQ_SVH__




class vdma_st_c2h_512mib_addr_aligned_seq extends vdma_st_c2h_mst_seq;

  local int len_count  = 0;
  local int addr_count = 0;
   
  `uvm_object_utils(vdma_st_c2h_512mib_addr_aligned_seq)

  function new (string name="vdma_st_c2h_512mib_addr_aligned_seq");
	  super.new(name);
	  this.watchdog_cycle = 2000000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  extern virtual function Len_t decideCstrLen();
  extern virtual function Addr_t decideCstrAddr();
  
endclass:vdma_st_c2h_512mib_addr_aligned_seq


function void vdma_st_c2h_512mib_addr_aligned_seq::genCfg();
	  this.num_item_start = 100;
	  this.num_item_end   = 100;
	  
	  super.genCfg();
	
endfunction:genCfg


function vdma_st_c2h_512mib_addr_aligned_seq::Addr_t vdma_st_c2h_512mib_addr_aligned_seq::decideCstrAddr();
  Addr_t return_addr;

  return_addr = {$urandom(), $urandom()};
  return_addr[28:0] = 0;

  return(DutParamHostAddr_t'(return_addr));
endfunction : decideCstrAddr


function vdma_st_c2h_512mib_addr_aligned_seq::Len_t vdma_st_c2h_512mib_addr_aligned_seq::decideCstrLen();
	return(4096);
endfunction:decideCstrLen


task vdma_st_c2h_512mib_addr_aligned_seq::pre_genCfg();

	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = MAX_DMA_LEN;//this.max_dma_size;
	this.preset_dma_size = this.min_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;
	
	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_ST_C2H_512MIB_ADdR_ALIGNED_SEQ_SVH__
