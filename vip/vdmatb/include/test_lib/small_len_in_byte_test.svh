`ifndef  __SMALL_LEN_IN_BYTE_TEST_SVH__
`define  __SMALL_LEN_IN_BYTE_TEST_SVH__



class small_len_in_byte_test extends vdmatb_test;
  
  `uvm_component_utils(small_len_in_byte_test)
  
  function new(string name="small_len_in_byte_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_small_len_in_byte_vseq");
  endfunction

endclass:small_len_in_byte_test



`endif // __SMALL_LEN_IN_BYTE_TEST_SVH__
