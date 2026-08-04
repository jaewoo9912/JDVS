`ifndef __VDMA_OBJ_SVH__
`define __VDMA_OBJ_SVH__


class vdma_obj extends vdomain_rptr;


  `vip_common_base_rptr_utils
  function new(string name="vdma_obj");
    super.new(name);
    `vip_common_base_rptr_impl_in_new
  endfunction

endclass:vdma_obj


`endif // __VDMA_OBJ_SVH__
