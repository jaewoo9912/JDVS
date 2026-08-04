`ifndef  __ASYMMETRIC_LATENCY_TEST_SVH__
`define  __ASYMMETRIC_LATENCY_TEST_SVH__



class asymmetric_latency_test extends vdmatb_test;
  
  
  `uvm_component_utils(asymmetric_latency_test)
  
  function new(string name="asymmetric_latency_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_asymmetric_latency_vseq");
  endfunction
  
  extern virtual protected function void decideTbCfg();
  
endclass:asymmetric_latency_test


function void asymmetric_latency_test::decideTbCfg();
  super.decideTbCfg();
  this.test_type = ASYMMETRIC_LATENCY_TEST;
endfunction:decideTbCfg



`endif // __ASYMMETRIC_LATENCY_TEST_SVH__
