`ifndef __VDMA_SA_ST_MON_SVH__
`define __VDMA_SA_ST_MON_SVH__




virtual class vdma_sa_st_mon extends vdma_sa_mon;
  
  function new(string name="vdma_sa_st_mon", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // ------------------------------------ vdma_sa_st_mon-api
  extern virtual function void collectData();
  extern virtual function void collectFault();
  // ---------------------------- vdma_sa_st_mon-impl
endclass:vdma_sa_st_mon

function void vdma_sa_st_mon::collectData();  endfunction:collectData


function void vdma_sa_st_mon::collectFault(); 
  T_TRANS found_trans;
  Fault_t being_collected;
  
  if(this.observedNewFault) begin
    being_collected = this.extractNewFault();
    
    if(being_collected.code < FaultCode_t'(4) || being_collected.code == 13) found_trans = this.configureFaultTransOnDropCase(being_collected);
    else                                                                     found_trans = this.configureFaultTransOnNormalCase(being_collected);
    
    this.ap_fault.write(found_trans);
    
  end // observedNewFault
endfunction:collectFault


`endif // __VDMA_SA_ST_MON_SVH__
