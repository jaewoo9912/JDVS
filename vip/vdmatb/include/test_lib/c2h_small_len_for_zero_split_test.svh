`ifndef  __C2H_SMALL_LEN_FOR_ZERO_SPLIT_TEST_SVH__
`define  __C2H_SMALL_LEN_FOR_ZERO_SPLIT_TEST_SVH__



class c2h_small_len_for_zero_split_test extends vdmatb_test;
  
  `uvm_component_utils(c2h_small_len_for_zero_split_test)
  
  function new(string name="c2h_small_len_for_zero_split_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_c2h_small_len_for_zero_split_vseq");
  endfunction

  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = YES;
    this.data_direction_type.only_h2c_test = NO;
  endfunction
endclass:c2h_small_len_for_zero_split_test



`endif // __C2H_SMALL_LEN_FOR_ZERO_SPLIT_TEST_SVH__
