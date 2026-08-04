`ifndef __VDMA_ST_C2H_MST_AXI_USER_BOUNDARY_SEQ_SVH__
`define __VDMA_ST_C2H_MST_AXI_USER_BOUNDARY_SEQ_SVH__



class vdma_st_c2h_mst_axi_user_boundary_seq extends vdma_st_c2h_mst_seq;

  
  `uvm_object_utils(vdma_st_c2h_mst_axi_user_boundary_seq)

  function new (string name="vdma_st_c2h_mst_axi_user_boundary_seq");
	  super.new(name);
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  extern virtual function FncId_t decideCstrFnc_Id();
  extern virtual function StrId_t decideCstrStr_Id();

endclass:vdma_st_c2h_mst_axi_user_boundary_seq

function vdma_st_c2h_mst_axi_user_boundary_seq::FncId_t vdma_st_c2h_mst_axi_user_boundary_seq::decideCstrFnc_Id();
	FncId_t rnd_fnc_id;
	logic select_fncId_size;
	
	select_fncId_size = FlipCoin(50);
	
	if(select_fncId_size == 0)begin
		rnd_fnc_id = 8'd2**8-1;
		return(rnd_fnc_id);
	end
	else if(select_fncId_size == 1)begin
		rnd_fnc_id = 8'd0;
		return(rnd_fnc_id);
	end
	else begin
	end
endfunction:decideCstrFnc_Id
function vdma_st_c2h_mst_axi_user_boundary_seq::StrId_t vdma_st_c2h_mst_axi_user_boundary_seq::decideCstrStr_Id();
	StrId_t rnd_str_id;
	logic select_strId_size;
	
	select_strId_size = FlipCoin(50);
	
	if(select_strId_size == 0)begin
		rnd_str_id = 8'd2**8-1;
		return(rnd_str_id);
	end
	else if(select_strId_size == 1)begin
		rnd_str_id = 8'd0;
		return(rnd_str_id);
	end
	else begin
	end
endfunction:decideCstrStr_Id

function void vdma_st_c2h_mst_axi_user_boundary_seq::genCfg();
	  // #PKT is randomized within the below values
	  // At least num_item is over 1
	  this.num_item_start = this.tcfg.ST_DUT_PARAM.C2H_DESCR_TABLE_SIZE / 2;
	  this.num_item_end   = this.tcfg.ST_DUT_PARAM.C2H_DESCR_TABLE_SIZE / 2;
	
	  super.genCfg();
	
endfunction:genCfg

task vdma_st_c2h_mst_axi_user_boundary_seq::pre_genCfg();
	// data size per desc (len_in_byte) is randomized within the below values
	// Based on vmg_rgs
	

  this.max_dma_size = MAX_DMA_LEN;
	this.min_dma_size = 1;
	this.preset_dma_size = this.max_dma_size;
	this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;

	
	super.pre_genCfg();
endtask:pre_genCfg

`endif // __VDMA_ST_C2H_MST_AXI_USER_BOUNDARY_SEQ_SVH__
