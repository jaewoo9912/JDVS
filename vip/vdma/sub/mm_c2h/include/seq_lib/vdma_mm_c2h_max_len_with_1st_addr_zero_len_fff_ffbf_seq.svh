`ifndef __VDMA_MM_C2H_MAX_LEN_WITH_1ST_ADDR_ZERO_LEN_FFF_FFBF_SEQ_SVH__
`define __VDMA_MM_C2H_MAX_LEN_WITH_1ST_ADDR_ZERO_LEN_FFF_FFBF_SEQ_SVH__




class vdma_mm_c2h_max_len_with_1st_addr_zero_len_fff_ffbf_seq extends vdma_mm_c2h_mst_seq;

  local int len_count  = 0;
  local int addr_count = 0;
   
  `uvm_object_utils(vdma_mm_c2h_max_len_with_1st_addr_zero_len_fff_ffbf_seq)

  function new (string name="vdma_mm_c2h_max_len_with_1st_addr_zero_len_fff_ffbf_seq");
	  super.new(name);
	  this.watchdog_cycle = 2000000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  extern virtual function Len_t decideCstrLen();
  extern virtual function Addr_t decideCstrAddr();
  
endclass:vdma_mm_c2h_max_len_with_1st_addr_zero_len_fff_ffbf_seq


function void vdma_mm_c2h_max_len_with_1st_addr_zero_len_fff_ffbf_seq::genCfg();
	  this.num_item_start = 3;
	  this.num_item_end   = 3;
	  
	  super.genCfg();
	
endfunction:genCfg


function vdma_mm_c2h_max_len_with_1st_addr_zero_len_fff_ffbf_seq::Addr_t vdma_mm_c2h_max_len_with_1st_addr_zero_len_fff_ffbf_seq::decideCstrAddr();
  Addr_t return_addr;

  if(this.addr_count == 1)
    return_addr = 0;
  else
    return_addr = {$urandom(), $urandom()};

  this.addr_count++;

  return(DutParamHostAddr_t'(return_addr));
endfunction : decideCstrAddr


function vdma_mm_c2h_max_len_with_1st_addr_zero_len_fff_ffbf_seq::Len_t vdma_mm_c2h_max_len_with_1st_addr_zero_len_fff_ffbf_seq::decideCstrLen();
	
	Len_t return_len;
	
  if(this.len_count == 0)
		return_len = 1;
	else if(this.len_count == 1)
		return_len = MAX_DMA_LEN;
	else	
		return_len = 1;

	this.len_count++;

	return(return_len);
endfunction:decideCstrLen


task vdma_mm_c2h_max_len_with_1st_addr_zero_len_fff_ffbf_seq::pre_genCfg();

	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = MAX_DMA_LEN;//this.max_dma_size;
	this.preset_dma_size = this.min_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;
	
	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_MM_C2H_MAX_LEN_WITH_1ST_ADDR_ZERO_LEN_FFF_FFBF_SEQ_SVH__
