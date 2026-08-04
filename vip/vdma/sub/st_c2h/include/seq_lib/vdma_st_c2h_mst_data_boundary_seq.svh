`ifndef __VDMA_ST_C2H_MST_DATA_BOUNDARY_SEQ_SVH__
`define __VDMA_ST_C2H_MST_DATA_BOUNDARY_SEQ_SVH__



class vdma_st_c2h_mst_data_boundary_seq extends vdma_st_c2h_mst_seq;

  typedef vdma_seq_item SeqItem_t;
  
  `uvm_object_utils(vdma_st_c2h_mst_data_boundary_seq)

  function new (string name="vdma_st_c2h_mst_data_boundary_seq");
	  super.new(name);
  endfunction

  extern function void genCfg();
  extern function SeqItem_t post_createSeqItem(SeqItem_t me);

endclass:vdma_st_c2h_mst_data_boundary_seq


function void vdma_st_c2h_mst_data_boundary_seq::genCfg();
	  // #PKT is randomized within the below values
	  // At least num_item is over 1
	  this.num_item_start = 10;
	  this.num_item_end   = 10;
	
	  super.genCfg();
	
endfunction:genCfg


function vdma_st_c2h_mst_data_boundary_seq::SeqItem_t vdma_st_c2h_mst_data_boundary_seq::post_createSeqItem(SeqItem_t me);
	localparam bit MIN = 0;
	localparam bit MAX = 1;
	
	case(FlipCoin(50))
		MIN : begin
			me.makeDataValue(0);
		end
		MAX : begin
			me.makeDataValue(-1);
		end
	endcase
	
	return(me);
		
endfunction:post_createSeqItem




`endif // __VDMA_ST_C2H_MST_DATA_BOUNDARY_SEQ_SVH__
