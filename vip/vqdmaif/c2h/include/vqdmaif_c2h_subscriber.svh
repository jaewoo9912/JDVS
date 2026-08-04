`ifndef __VQDMAIF_C2H_SUBSCRIBER_SVH__
`define __VQDMAIF_C2H_SUBSCRIBER_SVH__


class vqdmaif_c2h_subscriber extends vbfm_subscriber#(vqdmaif_c2h_transaction);

  `uvm_component_utils(vqdmaif_c2h_subscriber)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function bit isMatched(vqdmaif_c2h_transaction item0, vqdmaif_c2h_transaction item1);
    return(item0.getQid == item1.getQid);
  endfunction:isMatched
  
endclass:vqdmaif_c2h_subscriber

`endif // __VQDMAIF_C2H_SUBSCRIBER_SVH__
