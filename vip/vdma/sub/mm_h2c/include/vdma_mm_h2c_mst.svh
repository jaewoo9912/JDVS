`ifndef __VDMA_MM_H2C_MST_SVH__
`define __VDMA_MM_H2C_MST_SVH__


class vdma_mm_h2c_mst extends vdma_mst;


  `uvm_component_utils(vdma_mm_h2c_mst)
  function new(string name="vdma_mm_h2c_mst", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  extern virtual function DmaTransType_t getTransType();

endclass:vdma_mm_h2c_mst


function DmaTransType_t vdma_mm_h2c_mst::getTransType();
  return(MM_H2C);
endfunction:getTransType


`endif // __VDMA_MM_H2C_MST_SVH__
