`ifndef __VDMA_ST_C2H_SPLIT_MAX_HBURST_SEQ_SVH__
`define __VDMA_ST_C2H_SPLIT_MAX_HBURST_SEQ_SVH__




class vdma_st_c2h_split_max_hburst_seq extends vdma_st_c2h_mst_seq;

   
  `uvm_object_utils(vdma_st_c2h_split_max_hburst_seq)

  function new (string name="vdma_st_c2h_split_max_hburst_seq");
	  super.new(name);
	  this.watchdog_cycle = 400000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  extern virtual function Len_t decideCstrLen();
  extern virtual function FncId_t decideCstrMaxBL();
  
endclass:vdma_st_c2h_split_max_hburst_seq

function vdma_st_c2h_split_max_hburst_seq::FncId_t vdma_st_c2h_split_max_hburst_seq::decideCstrMaxBL();
	this.max_axi_len = 1;
	
	return(this.max_axi_len);
endfunction:decideCstrMaxBL

function vdma_st_c2h_split_max_hburst_seq::Len_t vdma_st_c2h_split_max_hburst_seq::decideCstrLen();
	
	this.being_static_len = this.being_static_len + (this.tcfg.ST_DUT_PARAM.AXI_DATA_WIDTH / 8);
	return(this.being_static_len);
endfunction:decideCstrLen

function void vdma_st_c2h_split_max_hburst_seq::genCfg();
	  this.num_item_start = MAX_DMA_LEN / CARD_DATA_BYTE_WIDTH;
	  this.num_item_end   = MAX_DMA_LEN / CARD_DATA_BYTE_WIDTH;
	  
	  super.genCfg();
	
endfunction:genCfg


task vdma_st_c2h_split_max_hburst_seq::pre_genCfg();

	this.max_dma_size = 1;
	this.min_dma_size = 1;//this.max_dma_size;
	this.preset_dma_size = this.min_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;
	
	super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_ST_C2H_SPLIT_MAX_HBURST_SEQ_SVH__
