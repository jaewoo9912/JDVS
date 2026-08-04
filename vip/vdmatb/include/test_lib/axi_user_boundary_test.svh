`ifndef  __AXI_USER_BOUNDARY_TEST_SVH__
`define  __AXI_USER_BOUNDARY_TEST_SVH__



class axi_user_boundary_test extends vdmatb_test;
  
  `uvm_component_utils(axi_user_boundary_test)
  
  function new(string name="axi_user_boundary_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_axi_user_boundary_vseq");
  endfunction

endclass:axi_user_boundary_test



`endif // __AXI_USER_BOUNDARY_TEST_SVH__
