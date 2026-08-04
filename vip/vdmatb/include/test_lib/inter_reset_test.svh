`ifndef  __INTER_RESET_TEST_SVH__
`define  __INTER_RESET_TEST_SVH__



class inter_reset_test extends vdmatb_test;
  
  `uvm_component_utils(inter_reset_test)
  
  function new(string name="inter_reset_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_inter_reset_vseq");
  endfunction
  
  extern virtual protected function void decideTbCfg();

endclass:inter_reset_test


function void inter_reset_test::decideTbCfg();
  super.decideTbCfg();
  this.test_type = INTER_RESET_TEST;
endfunction:decideTbCfg


`endif // __INTER_RESET_TEST_SVH__
