`ifndef __VQDMAIF_H2C_SLAVE_SEQUENCE_ITEM_SVH__
`define __VQDMAIF_H2C_SLAVE_SEQUENCE_ITEM_SVH__

class vqdmaif_h2c_slave_sequence_item extends vmg_sequence_item;

  vqdmaif_h2c_transaction trans;
  int unsigned cmd_pending_cycle;
  int unsigned fetch_latency;
  int unsigned data_latency[];
  int unsigned status_sideband_latency;
  int unsigned interrupt_sideband_latency;

  vqdmaif_h2c_slave_bfm_timing_policy bfm_timing_policy;


  // ------------------------------------------------------------------ Internal
  int unsigned ts_to_fetch;
  int unsigned data_issue_idx=0;

  `uvm_object_utils_begin(vqdmaif_h2c_slave_sequence_item)
    `uvm_field_int(cmd_pending_cycle, UVM_DEFAULT)
    `uvm_field_int(fetch_latency, UVM_DEFAULT)
    `uvm_field_int(status_sideband_latency, UVM_DEFAULT)
    `uvm_field_int(interrupt_sideband_latency, UVM_DEFAULT)
  `uvm_object_utils_end

  function new (string name="vqdmaif_h2c_slave_sequence_item");
    super.new(name);
    this.bfm_timing_policy = vqdmaif_h2c_slave_bfm_timing_policy::type_id::create($sformatf("%s.bfm_timing_policy", this.get_name));
  endfunction

  extern function void registerQid(QdmaQId_t qid);
  extern function void setDataLatency(int me);
  extern virtual function string getInfo();
  extern virtual function StringQ_t getInfoList();

endclass

function string vqdmaif_h2c_slave_sequence_item:: getInfo();
  if(this.trans == null) return("trans=null");
  return($sformatf("trans=[%s ts_to_fetch=%1d]", this.trans.getInfo, this.ts_to_fetch));
endfunction

function StringQ_t vqdmaif_h2c_slave_sequence_item::getInfoList();
  StringQ_t result;
  if(this.trans == null) return(result);
  return(this.trans.getInfoList);
endfunction


function void vqdmaif_h2c_slave_sequence_item::registerQid(QdmaQId_t qid);
  this.bfm_timing_policy.registerQid(qid);
endfunction

function void vqdmaif_h2c_slave_sequence_item::setDataLatency(int me);
  this.bfm_timing_policy.start_data_latency = me; 
  this.bfm_timing_policy.end_data_latency   = me; 
endfunction


`endif // __VQDMAIF_H2C_SLAVE_SEQUENCE_ITEM_SVH__
