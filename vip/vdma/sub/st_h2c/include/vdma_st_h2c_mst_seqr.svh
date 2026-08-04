`ifndef __VDMA_ST_H2C_MST_SEQR_SVH__
`define __VDMA_ST_H2C_MST_SEQR_SVH__



class vdma_st_h2c_mst_seqr extends vdma_st_mst_seqr;

  `uvm_component_utils(vdma_st_h2c_mst_seqr)
  
  function new(string name="vdma_st_h2c_mst_seqr", uvm_component parent=null);
    super.new(name, parent);
  endfunction

endclass:vdma_st_h2c_mst_seqr




`endif // __VDMA_ST_H2C_MST_SEQR_SVH__
