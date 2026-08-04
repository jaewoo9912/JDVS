`ifndef  __DATA_BOUNDARY_TEST_SVH__
`define  __DATA_BOUNDARY_TEST_SVH__


class data_boundary_test extends vdmatb_test;
  
  `uvm_component_utils(data_boundary_test)
  
  function new(string name="data_boundary_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();

    return("vdmatb_data_boundary_vseq");

  endfunction

endclass:data_boundary_test





`endif // __DATA_BOUNDARY_TEST_SVH__
