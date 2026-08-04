`ifndef __VDMA_ST_H2C_MST_ADDR_BOUNDARY_SEQ_SVH__
`define __VDMA_ST_H2C_MST_ADDR_BOUNDARY_SEQ_SVH__




class vdma_st_h2c_mst_addr_boundary_seq extends vdma_st_h2c_mst_seq;

  
  `uvm_object_utils(vdma_st_h2c_mst_addr_boundary_seq)

  function new (string name="vdma_st_h2c_mst_addr_boundary_seq");
	  super.new(name);
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  extern virtual function Addr_t decideCstrAddr();
endclass:vdma_st_h2c_mst_addr_boundary_seq

function vdma_st_h2c_mst_addr_boundary_seq::Addr_t vdma_st_h2c_mst_addr_boundary_seq::decideCstrAddr();
	Addr_t rnd_value;
	logic select_addr_size;
	
	select_addr_size = FlipCoin(50);
	
	if(select_addr_size == 0)begin
		rnd_value = 64'd2**64 - 1;
		return(DutParamHostAddr_t'(rnd_value));
	end
	else if(select_addr_size == 1)begin
		rnd_value = 64'd0;
		return(DutParamHostAddr_t'(rnd_value));
	end
	else begin
	end
endfunction:decideCstrAddr

function void vdma_st_h2c_mst_addr_boundary_seq::genCfg();
  this.prob_pkt_gathering = 0; 

	this.num_item_start = 10;
	this.num_item_end   = 10;

	super.genCfg();
	
endfunction:genCfg

// I think this task will be deleted
task vdma_st_h2c_mst_addr_boundary_seq::pre_genCfg();

  
	this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = 1;//this.max_dma_size;
	this.preset_dma_size = this.min_dma_size;
	
	super.pre_genCfg();
endtask:pre_genCfg




`endif // __VDMA_ST_H2C_MST_ADDR_BOUNDARY_SEQ_SVH__
