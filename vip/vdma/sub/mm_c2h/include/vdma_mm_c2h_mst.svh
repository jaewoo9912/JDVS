`ifndef __VDMA_MM_C2H_MST_SVH__
`define __VDMA_MM_C2H_MST_SVH__


class vdma_mm_c2h_mst extends vdma_mst;


  `uvm_component_utils(vdma_mm_c2h_mst)
  function new(string name="vdma_mm_c2h_mst", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  extern virtual function DmaTransType_t getTransType();

endclass:vdma_mm_c2h_mst


function DmaTransType_t vdma_mm_c2h_mst::getTransType();
  return(MM_C2H);
endfunction:getTransType


`endif // __VDMA_MM_C2H_MST_SVH__
