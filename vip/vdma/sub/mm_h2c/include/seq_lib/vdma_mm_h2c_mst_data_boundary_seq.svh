`ifndef __VDMA_MM_H2C_MST_DATA_BOUNDARY_SEQ_SVH__
`define __VDMA_MM_H2C_MST_DATA_BOUNDARY_SEQ_SVH__




class vdma_mm_h2c_mst_data_boundary_seq extends vdma_mm_h2c_mst_seq;

  typedef vdma_seq_item SeqItem_t;
  `uvm_object_utils(vdma_mm_h2c_mst_data_boundary_seq)

  function new (string name="vdma_mm_h2c_mst_data_boundary_seq");
	  super.new(name);
  endfunction

  extern function void genCfg();
 
endclass:vdma_mm_h2c_mst_data_boundary_seq

function void vdma_mm_h2c_mst_data_boundary_seq::genCfg();
	  // #PKT is randomized within the below values
	  // At least num_item is over 1
    this.prob_pkt_gathering = 0;
	  
	  this.num_item_start = 10;
	  this.num_item_end   = 10;
	
	  super.genCfg();
	
endfunction:genCfg


`endif // __VDMA_MM_H2C_MST_DATA_BOUNDARY_SEQ_SVH__
