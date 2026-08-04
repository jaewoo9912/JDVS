`ifndef __VQDMAIF_H2C_SLAVE_BFM_TIMING_POLICY_SVH__
`define __VQDMAIF_H2C_SLAVE_BFM_TIMING_POLICY_SVH__

typedef class vqdmaif_h2c_slave_sequence_item;

class vqdmaif_h2c_slave_bfm_timing_policy extends vmg_object;

  int unsigned start_cmd_pending_cycle          = 0,  end_cmd_pending_cycle          =  0;
  int unsigned start_fetch_latency              = 5,  end_fetch_latency              =  15;
  int unsigned start_data_latency               = 0,  end_data_latency               =  0;
  int unsigned start_status_sideband_latency    = 0,  end_status_sideband_latency    =  5;
  int unsigned start_interrupt_sideband_latency = 0,  end_interrupt_sideband_latency =  5;

  QdmaQId_t q_qid[$];
  QdmaAddr_t q_addr_start[$], q_addr_end[$];

  // =============================================================================
  // X CMD X <--cmd_pending_cycle--> X CMD X CMD X CMD X ...
  // =============================================================================
  // <--fetch_latency+data_latency--> X DATA X <-- data_latency--> X DATA X DATA X DATA X ...
  // <--fetch_latency+data_latency+status_sideband_latency--> X Status X <--status_latency--> X Status X ...
  // <--fetch_latency+data_latency+interrupt_sideband_latency--> X Interrupt X <--interrupt_latency--> X Interrupt X ...
  // =============================================================================

  `uvm_object_utils_begin(vqdmaif_h2c_slave_bfm_timing_policy)
    `uvm_field_int(start_cmd_pending_cycle, UVM_DEFAULT)
    `uvm_field_int(end_cmd_pending_cycle, UVM_DEFAULT)
    `uvm_field_int(start_fetch_latency, UVM_DEFAULT)
    `uvm_field_int(end_fetch_latency, UVM_DEFAULT)
    `uvm_field_int(start_data_latency, UVM_DEFAULT)
    `uvm_field_int(end_data_latency, UVM_DEFAULT)
    `uvm_field_int(start_status_sideband_latency, UVM_DEFAULT)
    `uvm_field_int(end_status_sideband_latency, UVM_DEFAULT)
    `uvm_field_int(start_interrupt_sideband_latency, UVM_DEFAULT)
    `uvm_field_int(end_interrupt_sideband_latency, UVM_DEFAULT)
  `uvm_object_utils_end


  function new (string name="vqdmaif_h2c_slave_bfm_timing_policy");
    super.new(name);
  endfunction


  extern function void registerQid(QdmaQId_t qid);
  extern function void registerAddrRange(QdmaAddr_t start_addr, end_addr);

  extern function YesOrNo_t isMatched_WithTrans(vqdmaif_h2c_transaction me);
  extern function YesOrNo_t isMatched_WithCmdPl(ref QdmaH2CCmd_t me);

  extern virtual function void setup(vqdmaif_h2c_slave_sequence_item item);

  extern virtual function int unsigned pickCmdPendingCycle();
  extern virtual function int unsigned pickFetchLatency();
  extern virtual function int unsigned pickDataLatency();
  extern virtual function int unsigned pickStatusSidebandLatency();
  extern virtual function int unsigned pickInterruptSidebandLatency();

endclass

function void vqdmaif_h2c_slave_bfm_timing_policy::registerQid(QdmaQId_t qid);
  this.q_qid.push_back(qid);
endfunction

function void vqdmaif_h2c_slave_bfm_timing_policy::registerAddrRange(QdmaAddr_t start_addr, end_addr);
  this.q_addr_start.push_back(start_addr);
  this.q_addr_end.push_back(end_addr);
endfunction


function YesOrNo_t vqdmaif_h2c_slave_bfm_timing_policy::isMatched_WithTrans(vqdmaif_h2c_transaction me);
  bit was_matched_addr, was_matched_qid;
  YesOrNo_t was_matched;

  if(this.q_addr_start.size==0 && this.q_qid.size==0) return(NO);

  foreach(this.q_addr_start[i]) begin
    foreach(me.q_sub[j]) begin
      if(me.q_sub[j].cmd_pl.addr inside {[this.q_addr_start[i]:this.q_addr_end[i]]}) begin
        was_matched_addr=1;
        break;
      end
    end
    if(was_matched_addr==1) break;
  end

  foreach(this.q_qid[i]) begin
    if(me.getQid inside {this.q_qid}) begin
      was_matched_qid=1;
      break;
    end
  end

  was_matched = YES;
  if(this.q_addr_start.size>0 && !was_matched_addr) was_matched=NO;
  if(this.q_qid.size>0  && !was_matched_qid)  was_matched=NO;

  return(was_matched);
endfunction


function YesOrNo_t vqdmaif_h2c_slave_bfm_timing_policy::isMatched_WithCmdPl(ref QdmaH2CCmd_t me);
  bit was_matched_addr, was_matched_qid;
  YesOrNo_t was_matched;

  if(this.q_addr_start.size==0 && this.q_qid.size==0) return(NO);

  foreach(this.q_addr_start[i]) begin
    if(me.addr inside {[this.q_addr_start[i]:this.q_addr_end[i]]}) begin
      was_matched_addr=1;
      break;
    end
    if(was_matched_addr==1) break;
  end

  foreach(this.q_qid[i]) begin
    if(me.qid inside {this.q_qid}) begin
      was_matched_qid=1;
      break;
    end
  end

  was_matched = YES;
  if(this.q_addr_start.size>0 && !was_matched_addr) was_matched=NO;
  if(this.q_qid.size>0  && !was_matched_qid)  was_matched=NO;

  return(was_matched);
endfunction


function void vqdmaif_h2c_slave_bfm_timing_policy::setup(vqdmaif_h2c_slave_sequence_item item);
  item.cmd_pending_cycle          = this.pickCmdPendingCycle();
  item.fetch_latency              = this.pickFetchLatency();
  item.status_sideband_latency    = this.pickStatusSidebandLatency();
  item.interrupt_sideband_latency = this.pickInterruptSidebandLatency();
  item.data_latency = new[item.trans.getNumData];
  foreach(item.data_latency[i]) item.data_latency[i] = this.pickDataLatency();
endfunction


function int unsigned vqdmaif_h2c_slave_bfm_timing_policy::pickCmdPendingCycle();
  return($urandom_range(this.start_cmd_pending_cycle, this.end_cmd_pending_cycle));
endfunction

function int unsigned vqdmaif_h2c_slave_bfm_timing_policy::pickFetchLatency();
  return($urandom_range(this.start_fetch_latency, this.end_fetch_latency));
endfunction

function int unsigned vqdmaif_h2c_slave_bfm_timing_policy::pickDataLatency();
  return($urandom_range(this.start_data_latency, this.end_data_latency));
endfunction

function int unsigned vqdmaif_h2c_slave_bfm_timing_policy::pickStatusSidebandLatency();
  return($urandom_range(this.start_status_sideband_latency, this.end_status_sideband_latency));
endfunction

function int unsigned vqdmaif_h2c_slave_bfm_timing_policy::pickInterruptSidebandLatency();
  return($urandom_range(this.start_interrupt_sideband_latency, this.end_interrupt_sideband_latency));
endfunction



`endif // __VQDMAIF_H2C_SLAVE_BFM_TIMING_POLICY_SVH__
