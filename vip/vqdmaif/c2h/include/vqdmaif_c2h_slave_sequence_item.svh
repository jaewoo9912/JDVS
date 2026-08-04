`ifndef __VQDMAIF_C2H_SLAVE_SEQUENCE_ITEM_SVH__
`define __VQDMAIF_C2H_SLAVE_SEQUENCE_ITEM_SVH__

class vqdmaif_c2h_slave_sequence_item extends vmg_sequence_item;

  vqdmaif_c2h_transaction trans;
  int unsigned cmd_pending_cycle;
  int unsigned data_pending_cycle[];
  int unsigned fetch_latency;
  int unsigned status_latency;
  int unsigned interrupt_sideband_latency;

  vqdmaif_c2h_slave_bfm_timing_policy bfm_timing_policy;

  int unsigned ts_to_fetch;

  `uvm_object_utils(vqdmaif_c2h_slave_sequence_item)
  function new (string name="vqdmaif_c2h_slave_sequence_item");
	  super.new(name);
    this.bfm_timing_policy = vqdmaif_c2h_slave_bfm_timing_policy::type_id::create($sformatf("%s.bfm_timing_policy", this.get_name));
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

  function void registerQid(QdmaQId_t qid);
    this.bfm_timing_policy.registerQid(qid);
  endfunction

  function void setStatusLatency(int me);
    this.bfm_timing_policy.start_status_latency = me; 
    this.bfm_timing_policy.end_status_latency   = me; 
  endfunction


endclass:vqdmaif_c2h_slave_sequence_item

`endif // __VQDMAIF_C2H_SLAVE_SEQUENCE_ITEM_SVH__
