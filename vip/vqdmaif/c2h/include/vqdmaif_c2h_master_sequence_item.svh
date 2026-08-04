`ifndef __VQDMAIF_C2H_MASTER_SEQUENCE_ITEM_SVH__
`define __VQDMAIF_C2H_MASTER_SEQUENCE_ITEM_SVH__

class vqdmaif_c2h_master_sequence_item extends vmg_sequence_item;
  vqdmaif_c2h_transaction trans;
  int unsigned cmd2cmd_delay;
  int unsigned data2data_delay_list[];
  int unsigned cmd2data_delay;
  int unsigned status_pending_cycle;
  `uvm_object_utils(vqdmaif_c2h_master_sequence_item)
  function new (string name="vqdmaif_c2h_master_sequence_item");
	  super.new(name);
  endfunction

  virtual function string getInfo();
    if(this.trans == null) return("trans=null");
    return($sformatf("trans=[%s]", this.trans.getInfo));
  endfunction

  virtual function StringQ_t getInfoList();
    StringQ_t result;
    if(this.trans == null) return(result);
    return(this.trans.getInfoList);
  endfunction

  virtual task waitDone(string call_info="");
    this.trans.waitDone(call_info);
  endtask

endclass:vqdmaif_c2h_master_sequence_item

`endif // __VQDMAIF_C2H_MASTER_SEQUENCE_ITEM_SVH__
