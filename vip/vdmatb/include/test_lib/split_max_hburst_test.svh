`ifndef  __SPLIT_MAX_HBURST_TEST_SVH__
`define  __SPLIT_MAX_HBURST_TEST_SVH__



class split_max_hburst_test extends vdmatb_test;
  
  `uvm_component_utils(split_max_hburst_test)
  
  function new(string name="split_max_hburst_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();

    return("vdmatb_split_max_hburst_vseq");

  endfunction

endclass:split_max_hburst_test



`endif // __SPLIT_MAX_HBURST_TEST_SVH__
