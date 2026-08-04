`ifndef  __RDY_SIGNAL_STATE_FOR_FUNC_COV_TEST_SVH__
`define  __RDY_SIGNAL_STATE_FOR_FUNC_COV_TEST_SVH__



class rdy_signal_state_for_func_cov_test extends vdmatb_test;
  
  `uvm_component_utils(rdy_signal_state_for_func_cov_test)
  
  function new(string name="rdy_signal_state_for_func_cov_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_rdy_signal_state_for_func_cov_vseq");
  endfunction

endclass:rdy_signal_state_for_func_cov_test



`endif // __RDY_SIGNAL_STATE_FOR_FUNC_COV_TEST_SVH__
