`ifndef  __H2C_SMALL_LEN_IN_BYTE_TEST_SVH__
`define  __H2C_SMALL_LEN_IN_BYTE_TEST_SVH__



class h2c_small_len_in_byte_test extends vdmatb_test;
  
  `uvm_component_utils(h2c_small_len_in_byte_test)
  
  function new(string name="h2c_small_len_in_byte_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_h2c_small_len_in_byte_vseq");
  endfunction
  

  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = NO;
    this.data_direction_type.only_h2c_test = YES;
  endfunction
endclass:h2c_small_len_in_byte_test



`endif // __H2C_SMALL_LEN_IN_BYTE_TEST_SVH__
