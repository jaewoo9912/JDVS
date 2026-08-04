`ifndef  __MAX_LEN_TEST_SVH__
`define  __MAX_LEN_TEST_SVH__



class max_len_test extends vdmatb_test;
  
  `uvm_component_utils(max_len_test)
  
  function new(string name="max_len_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_max_len_vseq");
  endfunction

endclass:max_len_test



`endif // __MAX_LEN_TEST_SVH__
