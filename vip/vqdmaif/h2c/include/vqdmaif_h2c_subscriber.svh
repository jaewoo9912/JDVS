`ifndef __VQDMAIF_H2C_SUBSCRIBER_SVH__
`define __VQDMAIF_H2C_SUBSCRIBER_SVH__


class vqdmaif_h2c_subscriber extends vbfm_subscriber#(vqdmaif_h2c_transaction);

  `uvm_component_utils(vqdmaif_h2c_subscriber)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function bit isMatched(vqdmaif_h2c_transaction item0, vqdmaif_h2c_transaction item1);
    return(item0.getQid == item1.getQid);
  endfunction:isMatched
  
endclass:vqdmaif_h2c_subscriber

`endif // __VQDMAIF_H2C_SUBSCRIBER_SVH__
