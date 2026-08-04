`ifndef  __C2H_FULL_START_W_FIFO_TEST_SVH__
`define  __C2H_FULL_START_W_FIFO_TEST_SVH__



class c2h_full_start_w_fifo_test extends vdmatb_test;
  
  `uvm_component_utils(c2h_full_start_w_fifo_test)
  
  function new(string name="c2h_full_start_w_fifo_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_c2h_full_start_w_fifo_vseq");
  endfunction

  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = YES;
    this.data_direction_type.only_h2c_test = NO;
  endfunction
endclass:c2h_full_start_w_fifo_test



`endif // __C2H_FULL_START_W_FIFO_TEST_SVH__
