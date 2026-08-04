`ifndef __VDMATB_MACRO_SVH__
`define __VDMATB_MACRO_SVH__


  `define vdmatb_rptr_utils \
    local vdmatb_rptr vdmatb_rptr_inst;
    

  `define vdmatb_rptr_impl_in_new \
    this.vdmatb_rptr_inst = new(this.getName);



`endif // __VDMATB_MACRO_SVH__
