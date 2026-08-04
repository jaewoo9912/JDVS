`ifndef __VDMA_MST_SEQR_SVH__
`define __VDMA_MST_SEQR_SVH__




virtual class vdma_mst_seqr extends vmg_seqr#(.T_SEQ_ITEM(vdma_seq_item));

  vdma_mst_tcfg tcfg;
  
  function new(string name="vdma_mst_seqr", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  extern virtual function void build_phase(uvm_phase phase);
  extern function StDmaDesignParam_t getStDmaDesignParam();
  extern function MmDmaDesignParam_t getMmDmaDesignParam();
  
endclass:vdma_mst_seqr


function void vdma_mst_seqr::build_phase(uvm_phase phase);
  super.build_phase(phase);
  `vmg_get_cfgdb_at_me(vdma_mst_tcfg, "tcfg", this.tcfg)
endfunction:build_phase



function ddma_pkg::StDmaDesignParam_t vdma_mst_seqr::getStDmaDesignParam(); return(this.tcfg.getStDmaDesignParam); endfunction
function ddma_pkg::MmDmaDesignParam_t vdma_mst_seqr::getMmDmaDesignParam(); return(this.tcfg.getMmDmaDesignParam); endfunction


`endif // __VDMA_MST_SEQR_SVH__
