`ifndef __VDMA_ST_C2H_MST_SVH__
`define __VDMA_ST_C2H_MST_SVH__


class vdma_st_c2h_mst extends vdma_mst;


  `uvm_component_utils(vdma_st_c2h_mst)
  function new(string name="vdma_st_c2h_mst", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  extern virtual function DmaTransType_t getTransType();

endclass:vdma_st_c2h_mst


function DmaTransType_t vdma_st_c2h_mst::getTransType();
  return(ST_C2H);
endfunction:getTransType


`endif // __VDMA_ST_C2H_MST_SVH__
