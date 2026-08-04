`ifndef  __ADDR_BOUNDARY_TEST_SVH__
`define  __ADDR_BOUNDARY_TEST_SVH__


class addr_boundary_test extends vdmatb_test;
  
  `uvm_component_utils(addr_boundary_test)
  
  function new(string name="addr_boundary_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();

    return("vdmatb_addr_boundary_vseq");

  endfunction

endclass:addr_boundary_test



`endif // __ADDR_BOUNDARY_TEST_SVH__
