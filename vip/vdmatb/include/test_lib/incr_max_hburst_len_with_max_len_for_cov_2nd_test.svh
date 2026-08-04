`ifndef  __INCR_MAX_HBURST_LEN_WITH_MAX_LEN_FOR_COV_2ND_TEST_SVH__
`define  __INCR_MAX_HBURST_LEN_WITH_MAX_LEN_FOR_COV_2ND_TEST_SVH__



class incr_max_hburst_len_with_max_len_for_cov_2nd_test extends vdmatb_test;
  
  `uvm_component_utils(incr_max_hburst_len_with_max_len_for_cov_2nd_test)
  
  function new(string name="incr_max_hburst_len_with_max_len_for_cov_2nd_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();

    return("vdmatb_incr_max_hburst_len_with_max_len_for_cov_2nd_vseq");

  endfunction

endclass:incr_max_hburst_len_with_max_len_for_cov_2nd_test



`endif // __INCR_MAX_HBURST_LEN_WITH_MAX_LEN_FOR_COV_2ND_TEST_SVH__
