`ifndef __VDMA_FAULT_SEQ_ITEM_SVH__
`define __VDMA_FAULT_SEQ_ITEM_SVH__



class vdma_fault_seq_item extends vdma_seq_item;

  `uvm_object_utils(vdma_fault_seq_item)
  function new (string name="vdma_seq_item");
    super.new(name);
    this.test_type = FAULT_TEST; 
  endfunction

endclass:vdma_fault_seq_item

`endif // __VDMA_FAULT_SEQ_ITEM_SVH__
