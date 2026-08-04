`ifndef  __RANDOM_TEST_SVH__
`define  __RANDOM_TEST_SVH__



class random_test extends vdmatb_test;
  
  `uvm_component_utils(random_test)
  
  function new(string name="random_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_random_vseq");
  endfunction

endclass:random_test



`endif // __RANDOM_TEST_SVH__
