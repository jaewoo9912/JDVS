`ifndef __VDMA_ST_H2C_MST_SEQ_SVH__
`define __VDMA_ST_H2C_MST_SEQ_SVH__




class vdma_st_h2c_mst_seq extends vdma_st_h2c_mst_seq;

  typedef vdma_seq_item SeqItem_t;
  `uvm_object_utils(vdma_st_h2c_mst_seq)

  function new (string name="vdma_st_h2c_mst_seq");
	  super.new(name);
  endfunction

 
endclass:vdma_st_h2c_mst_seq




`endif // __VDMA_ST_H2C_MST_SEQ_SVH__
