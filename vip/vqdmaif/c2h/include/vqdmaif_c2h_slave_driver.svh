`ifndef __VQDMAIF_C2H_SLAVE_DRIVER_SVH__
`define __VQDMAIF_C2H_SLAVE_DRIVER_SVH__


class vqdmaif_c2h_slave_driver extends vbfm_driver#(.REQ(vqdmaif_c2h_slave_sequence_item));
  typedef virtual vqdmaif_c2h_if T_VIF;
  typedef vqdmaif_c2h_slave_cfg T_CFG;
  typedef vqdmaif_c2h_slave_sequence_item T_SEQ_ITEM;
  typedef vqdmaif_c2h_transaction T_TRANS;
  typedef QdmaC2HCmd_t T_CMD_PL;
  typedef QdmaC2HData_t T_DATA_PL;
  typedef QdmaC2HStatus_t T_STATUS_PL;
  typedef QdmaC2HStatusSideBand_t T_STATUS_SB_PL;
  typedef QdmaC2HInterruptSideBand_t T_INTERRUPT_SB_PL;
  
  typedef enum int{
    NEW_SEQ_ITEM,
    COMPLETED_TRANS,
    UNDEFINED_MAIN_EVENT
  }MainEventIdType_t;

  // -----------------------------------------------------------
  T_CFG cfg;
  T_VIF vif;
  real bandwidth;
  vmem_if_svcr_behavior mem_svcr;


  `uvm_analysis_imp_decl(_fwd_transfer);
  `uvm_analysis_imp_decl(_bandwidth);
  uvm_analysis_imp_fwd_transfer#(T_TRANS, vqdmaif_c2h_slave_driver) impl_fwd_transfer;
  uvm_analysis_imp_bandwidth#(real, vqdmaif_c2h_slave_driver) bandwidth_port;

  protected T_TRANS q_pending_fwd_transfer[$];
  protected T_SEQ_ITEM q_active[$];
  protected T_SEQ_ITEM sa_pending_fwd2status[QdmaQId_t][$], q_pending_fwd2status[$];
  protected T_SEQ_ITEM q_pending_status[$];
  protected QdmaQId_t q_pending_status_qid[$];
  protected T_INTERRUPT_SB_PL q_pending_interrupt_sideband[$];

  protected vqdmaif_c2h_slave_bfm_timing_policy q_bfm_timing_policy[$];
  protected int unsigned q_cmd_pending_cycle[$];
  protected int unsigned q_data_pending_cycle[$];

  //TODO:NeedUpdate -- w/ the latest implementation style (in QDMA)
  protected int unsigned q_pending_status_latency[$];
  protected int unsigned q_pending_interrupt_sideband_latency[$];

  protected QdmaQId_t prev_arbitrated_qid;

  protected bit reset_pending;

  `uvm_component_utils(vqdmaif_c2h_slave_driver)
  function new(string name, uvm_component parent);
    super.new(name, parent);
    this.impl_fwd_transfer = new("impl_fwd_transfer", this);
    this.bandwidth_port = new("bandwidth_port", this);
  endfunction

  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task reset_phase(uvm_phase phase);

	extern virtual function string decideReportFamilyId();


  extern virtual function void decideBfmParam(T_SEQ_ITEM item);
  extern virtual function void decideStatusTransfer(T_SEQ_ITEM item);

  extern virtual task doOnReset();
  extern virtual task doOnCollectBfmTimingPolicy();
  extern virtual task doOnFwdTransfer();
  extern virtual task doOnFwd2Status();
  extern virtual task doOnStatusIssue();
  extern virtual task doOnCmdRdy();
  extern virtual task doOnDataRdy();

  extern task driveStatus(T_SEQ_ITEM me);

  extern virtual function T_SEQ_ITEM arbitrateToIssueStatus();

  extern virtual task doOnFwdTransfer_OnMbdma();
  extern virtual task doOnInterruptSideband();

  extern virtual function void write_fwd_transfer(T_TRANS me);
  extern virtual function void write_bandwidth(real me);
  protected virtual function void preStoreStatus(T_SEQ_ITEM item, ref T_STATUS_PL status);endfunction

  extern virtual task waitIdle(string call_info="unspecified");

  extern function void showInternalState(string call_info="unspecified");
  extern function void initInternalState(string call_info="unspecified");

  extern protected function void addItem_PendingFwd2Status(T_SEQ_ITEM me);
  extern protected function void deleteItem_PendingFwd2Status(T_SEQ_ITEM me);
  extern protected function void addItem_PendingStatus(T_SEQ_ITEM me);
  extern protected function void deleteItem_PendingStatus(T_SEQ_ITEM me);
  extern protected function void addItem_Trans(T_SEQ_ITEM me);
  extern protected function void deleteItem_Trans(T_SEQ_ITEM me);

  extern protected function bit isCompletedTrans_AfterIssueStatus(T_SEQ_ITEM me);

endclass:vqdmaif_c2h_slave_driver


function string vqdmaif_c2h_slave_driver::decideReportFamilyId(); return("C2H_SLV_DRV"); endfunction


function void vqdmaif_c2h_slave_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
  `vmg_get_cfgdb_at_me(T_CFG, "cfg", this.cfg)
  `vmg_get_cfgdb_at_me(T_VIF, "vif", this.vif);
endfunction:build_phase


task vqdmaif_c2h_slave_driver::run_phase(uvm_phase phase);
  super.run_phase(phase);
  this.vif.data_rdy <= FlipCoin(50);
  this.vif.cmd_rdy  <= FlipCoin(50);
  this.vif.status_pl <= '0;
  this.vif.status_vld <= 0;
  @(negedge this.clk_vif.RESETn);
  this.reset_pending = 0;
  forever begin
    fork
      begin
        fork
          begin : C2H
            if(this.cfg.dma_type == QDMA) begin
              fork
                this.doOnCollectBfmTimingPolicy();
                this.doOnCmdRdy();
                this.doOnDataRdy();
                this.doOnFwdTransfer();
                this.doOnFwd2Status();
                this.doOnStatusIssue();
              join
            end
            else begin
              fork
                this.doOnCollectBfmTimingPolicy();
                this.doOnCmdRdy();
                this.doOnDataRdy();
                this.doOnFwdTransfer_OnMbdma();
                this.doOnFwd2Status();
                this.doOnStatusIssue();
                this.doOnInterruptSideband();
              join
            end
          end
          begin : RESET
            fork
              this.doOnReset();
              wait(this.reset_pending);
            join_any
            disable fork;
          end
        join_any
        disable fork;
        this.initInternalState("reset triggered");
        this.reset_pending = 0;
        @(posedge this.clk_vif.RESETn);
      end
    join
  end
endtask:run_phase


task vqdmaif_c2h_slave_driver::doOnReset();
  @(negedge this.clk_vif.RESETn);
endtask : doOnReset


task vqdmaif_c2h_slave_driver::doOnCmdRdy();
  int unsigned cmd_pending_cycle;
  bit pop_done = 0;

  forever begin
    this.vif.cmd_rdy <= 0;
    wait(this.cfg.max_ot > this.q_active.size);
    if(this.q_cmd_pending_cycle.size > 0) begin
      cmd_pending_cycle = this.q_cmd_pending_cycle[0];
      pop_done = 1;
    end
    else begin
      cmd_pending_cycle = $urandom_range(this.cfg.default_bfm_timing_policy.start_cmd_pending_cycle, this.cfg.default_bfm_timing_policy.end_cmd_pending_cycle);
    end
    this.waitCycle(cmd_pending_cycle);
    this.vif.cmd_rdy <= 1;
    this.waitCycle();
    if(this.vif.cmd_vld && this.vif.cmd_rdy && pop_done) begin
      void'(this.q_cmd_pending_cycle.pop_front);
      pop_done = 0;
    end
  end
endtask:doOnCmdRdy


task vqdmaif_c2h_slave_driver::doOnDataRdy();
  int unsigned data_pending_cycle;
  bit pop_done = 0;

  forever begin
    this.vif.data_rdy <= 0;
    wait(this.cfg.max_ot > this.q_active.size);

    if(this.q_data_pending_cycle.size > 0) begin
      data_pending_cycle = this.q_data_pending_cycle[0];
      pop_done = 1;
    end
    else begin
      data_pending_cycle = $urandom_range(this.cfg.default_bfm_timing_policy.start_data_pending_cycle, this.cfg.default_bfm_timing_policy.end_data_pending_cycle);
    end

    this.waitCycle(data_pending_cycle);
    this.vif.data_rdy <= 1;
    this.waitCycle();
    if(this.vif.data_vld && this.vif.data_rdy && pop_done) begin
      void'(this.q_data_pending_cycle.pop_front);
      pop_done = 0;
    end
  end
endtask:doOnDataRdy


function void vqdmaif_c2h_slave_driver::write_fwd_transfer(T_TRANS me);
  T_TRANS cloned;
  $cast(cloned, me.clone);
  cloned.cfg = me.cfg;
  cloned.qid = me.qid;
  this.q_pending_fwd_transfer.push_back(cloned);
endfunction:write_fwd_transfer


function void vqdmaif_c2h_slave_driver::write_bandwidth(real me);
  this.bandwidth = me; 
endfunction : write_bandwidth


task vqdmaif_c2h_slave_driver::doOnFwdTransfer_OnMbdma();
//TODO:NeedUpdateProperly -- forever begin
//TODO:NeedUpdateProperly --   T_SEQ_ITEM item;
//TODO:NeedUpdateProperly --   T_STATUS_PL status_pl = 0;
//TODO:NeedUpdateProperly --   T_STATUS_SB_PL status_sideband_pl = 0;
//TODO:NeedUpdateProperly --   T_INTERRUPT_SB_PL interrupt_sideband_pl = 0;
//TODO:NeedUpdateProperly -- 
//TODO:NeedUpdateProperly --   wait(this.q_pending_fwd_transfer.size > 0);
//TODO:NeedUpdateProperly --   item = this.q_pending_fwd_transfer.pop_front();
//TODO:NeedUpdateProperly --   waitCycle((item.fetch_latency==-1)? pickFetchLatency() : item.fetch_latency);
//TODO:NeedUpdateProperly --   this.mem_svcr.writeByteQ(item.trans.ctrl_info.addr, item.trans.dcntnr.m_data);
//TODO:NeedUpdateProperly -- 
//TODO:NeedUpdateProperly --   if(item.trans.isNeedStatus) begin
//TODO:NeedUpdateProperly --     status_pl = item.trans.status_pl;
//TODO:NeedUpdateProperly --     status_pl.qid = item.trans.getQid;
//TODO:NeedUpdateProperly --     status_sideband_pl.dma_id = item.trans.cmd_sideband_pl.dma_id;
//TODO:NeedUpdateProperly --     this.q_pending_status.push_back(status_pl);
//TODO:NeedUpdateProperly --     this.q_pending_status_sideband.push_back(status_sideband_pl);
//TODO:NeedUpdateProperly --     this.q_pending_status_latency.push_back((item.status_latency==-1) ? pickStatusLatency() : item.status_latency);
//TODO:NeedUpdateProperly --   end
//TODO:NeedUpdateProperly -- 
//TODO:NeedUpdateProperly --   if(item.trans.isNeedInterruptSideband) begin
//TODO:NeedUpdateProperly --     interrupt_sideband_pl.qid = item.trans.getQid;
//TODO:NeedUpdateProperly --     interrupt_sideband_pl.dma_id = item.trans.cmd_sideband_pl.dma_id;
//TODO:NeedUpdateProperly --     interrupt_sideband_pl.fnc_id = item.trans.getFunc();
//TODO:NeedUpdateProperly --     interrupt_sideband_pl.vec_id = item.trans.cmd_sideband_pl.vec_id;
//TODO:NeedUpdateProperly --     this.q_pending_interrupt_sideband.push_back(interrupt_sideband_pl);
//TODO:NeedUpdateProperly --     this.q_pending_interrupt_sideband_latency.push_back((item.interrupt_sideband_latency==-1) ? pickInterruptSidebandLatency() : item.interrupt_sideband_latency);
//TODO:NeedUpdateProperly --   end
//TODO:NeedUpdateProperly -- end
endtask : doOnFwdTransfer_OnMbdma


task vqdmaif_c2h_slave_driver::doOnInterruptSideband();
  forever begin
    T_INTERRUPT_SB_PL interrupt_sideband_pl;

    wait(this.q_pending_interrupt_sideband.size > 0);
    interrupt_sideband_pl = this.q_pending_interrupt_sideband.pop_front();

    this.vif.interrupt_sideband_vld <= 0;
    this.waitCycle(this.q_pending_interrupt_sideband_latency.pop_front());
    this.vif.interrupt_sideband_vld <= 1;
    this.vif.interrupt_sideband_pl <= interrupt_sideband_pl;
    this.waitCycle();
    while(this.vif.interrupt_sideband_rdy === 0) this.waitCycle();
    if(this.q_pending_interrupt_sideband.size == 0) begin
      this.vif.interrupt_sideband_vld <= 0;
      this.waitCycle();
    end
  end  
endtask : doOnInterruptSideband


task vqdmaif_c2h_slave_driver::doOnFwdTransfer();
  int num_item;
  forever begin
    T_SEQ_ITEM item;

    wait(this.q_pending_fwd_transfer.size>0);
    item = T_SEQ_ITEM::type_id::create($sformatf("%s.item#%1d", this.get_name, num_item++));
    item.trans = this.q_pending_fwd_transfer.pop_front();
    this.mem_svcr.writeByteQ(item.trans.ctrl_info.addr, item.trans.dcntnr.m_data);
    this.decideStatusTransfer(item);
    this.decideBfmParam(item);
    // -------------------------------------------
    this.addItem_PendingFwd2Status(item);
    this.addItem_Trans(item);
    this.q_cmd_pending_cycle.push_back(item.cmd_pending_cycle);
    if(this.cfg.driver_operation_mode == PERF_MODE && this.cfg.performance_measure == YES && this.cfg.target_bandwidth > this.bandwidth)begin
      foreach(item.data_pending_cycle[i]) this.q_data_pending_cycle.push_back(0);
    end
    else begin
      foreach(item.data_pending_cycle[i]) this.q_data_pending_cycle.push_back(item.data_pending_cycle[i]);
    end
  end
endtask


function void vqdmaif_c2h_slave_driver::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  if(this.mem_svcr==null) `vmg_fatal_wrong_usage(this.get_full_name, "You should set \"mem_svcr\" handle at connect_phase for me!!")
endfunction


function void vqdmaif_c2h_slave_driver::decideBfmParam(T_SEQ_ITEM item);
  vqdmaif_c2h_slave_bfm_timing_policy policy;

  foreach(this.q_bfm_timing_policy[i])begin
    if(this.q_bfm_timing_policy[i].isMatched_WithTrans(item.trans))begin
      policy = this.q_bfm_timing_policy[i];
      this.q_bfm_timing_policy.delete(i);
      break;
    end
  end
  if(policy == null) policy = this.cfg.default_bfm_timing_policy;
  policy.setup(item);
  item.ts_to_fetch = item.fetch_latency;
endfunction:decideBfmParam


function void vqdmaif_c2h_slave_driver::decideStatusTransfer(T_SEQ_ITEM item);
  T_STATUS_PL status_pl=0;
  T_STATUS_SB_PL status_sideband_pl = 0;

  status_pl.qid = item.trans.getQid;
  status_pl.last = 1;
  status_pl.cmp = FlipCoin(this.cfg.prob_status_cmp);
  status_pl.drop = FlipCoin(this.cfg.prob_status_drop);
  status_pl.error = FlipCoin(this.cfg.prob_status_error);
  status_sideband_pl.fid = item.trans.cmd_sideband_pl.fid;
  this.preStoreStatus(item, status_pl);
  item.trans.storeStatus(status_pl);
  item.trans.storeStatusSideband(status_sideband_pl);
endfunction


task vqdmaif_c2h_slave_driver::doOnCollectBfmTimingPolicy();
  forever begin
    T_SEQ_ITEM item;
    wait(this.q_bfm_timing_policy.size() <= this.cfg.max_ot);
    this.seq_item_port.get(item);
    this.q_bfm_timing_policy.push_back(item.bfm_timing_policy);
    this.seq_item_port.put(item);
  end
endtask


function void vqdmaif_c2h_slave_driver::deleteItem_PendingFwd2Status(T_SEQ_ITEM me);
  int idx[$] = this.q_pending_fwd2status.find_first_index(x) with(x===me);
  if(idx.size==0)begin
    `vmg_fatal_wrong_impl(this.get_full_name, $sformatf("Failed to deleteItem_PendingFwd2Status(q_pending_fwd2status) for item=[%s]", me.getInfo));
  end
  this.q_pending_fwd2status.delete(idx[0]);

  if(!this.sa_pending_fwd2status.exists(me.trans.getQid))begin
    `vmg_fatal_wrong_impl(this.get_full_name, $sformatf("Failed to deleteItem_PendingFwd2Status(sa_pending_fwd2status) for item=[%s]", me.getInfo));
  end
  void'(this.sa_pending_fwd2status[me.trans.getQid].pop_front);
  if(this.sa_pending_fwd2status[me.trans.getQid].size==0)  this.sa_pending_fwd2status.delete(me.trans.getQid);
endfunction


task vqdmaif_c2h_slave_driver::doOnFwd2Status();
  forever begin
    T_SEQ_ITEM q_proceed_item[$];

    wait(this.q_pending_fwd2status.size > 0);
    this.waitCycle(1);
    foreach(this.q_pending_fwd2status[i])begin
      if(this.q_pending_fwd2status[i].ts_to_fetch != 0) this.q_pending_fwd2status[i].ts_to_fetch--;
    end

    case(this.cfg.arb_type)
      FIFS:begin
        if(this.q_pending_fwd2status[0].ts_to_fetch==0)begin
          q_proceed_item.push_back(this.q_pending_fwd2status[0]);
        end          
      end
      default:begin
        foreach(this.sa_pending_fwd2status[qid])begin
          if(this.sa_pending_fwd2status[qid][0].ts_to_fetch==0)begin
            q_proceed_item.push_back(this.sa_pending_fwd2status[qid][0]);
          end
        end
      end
    endcase

    foreach(q_proceed_item[i])begin
      this.addItem_PendingStatus(q_proceed_item[i]);
      this.deleteItem_PendingFwd2Status(q_proceed_item[i]);
    end
  end
endtask:doOnFwd2Status


task vqdmaif_c2h_slave_driver::doOnStatusIssue();
  forever begin
    T_SEQ_ITEM item;

    wait(this.q_pending_status.size > 0);
    item = this.arbitrateToIssueStatus();
    this.driveStatus(item);

    if(this.isCompletedTrans_AfterIssueStatus(item))begin
      this.deleteItem_Trans(item);
    end
  end
endtask:doOnStatusIssue


task vqdmaif_c2h_slave_driver::driveStatus(T_SEQ_ITEM me);
  int unsigned status_latency;

  this.vif.status_vld <= 0;
  //TODO:NeedReview
  status_latency = me.status_latency;
  if(!status_latency) status_latency = 0;
  else                status_latency--;

  this.waitCycle(status_latency);
  this.vif.status_vld         <= 1;
  this.vif.status_pl          <= me.trans.status_pl;
  this.vif.status_sideband_pl <= me.trans.status_sideband_pl;
  this.waitCycle();
  while(this.vif.status_rdy===0) this.waitCycle();

  this.deleteItem_PendingStatus(me);
  if(this.q_pending_status.size == 0)begin
    this.vif.status_vld <= 0;
    this.waitCycle();
  end
endtask:driveStatus


function vqdmaif_c2h_slave_driver::T_SEQ_ITEM vqdmaif_c2h_slave_driver::arbitrateToIssueStatus();
  T_SEQ_ITEM item;
  int arbitrated_idx, idx[$];
  QdmaQId_t arbitrated_qid;

  case(this.cfg.arb_type)
    FIFS:begin
      arbitrated_qid = this.q_pending_status[0].trans.getQid;
    end
    RANDOM:begin
      int rand_idx = $urandom_range(0, this.q_pending_status.size-1);
      arbitrated_qid = this.q_pending_status[rand_idx].trans.getQid;
    end
    ROUND_ROBIN:begin
      int qid_queue_idx=0;
      if(this.q_pending_status_qid.size > 1)begin
        idx = this.q_pending_status_qid.find_first_index(x) with(x===this.prev_arbitrated_qid);
        if(idx.size != 0)begin
          if(idx[0]+1 <= this.q_pending_status_qid.size-1)begin
            qid_queue_idx = idx[0]+1;
          end
        end
      end
      arbitrated_qid = this.q_pending_status_qid[qid_queue_idx];
    end
    default:begin
      `vmg_fatal_shall_impl(this.get_full_name, $sformatf("arbitrateToIssueStatus -- cfg.arb_type=%s", cfg.arb_type.name))
    end
  endcase
  
  `vmg_info(this.get_full_name, $sformatf("C2H_ARB_RESULT: prev_qid/cur_qid=%1d/%1d %s num_active_trans/qid=%1d/%1d",
      this.prev_arbitrated_qid, arbitrated_qid,
      this.cfg.arb_type.name,
      this.q_active.size, this.q_pending_status_qid.size
    ), this.cfg.arb_result_verbosity)
  this.prev_arbitrated_qid = arbitrated_qid;

  idx = this.q_pending_status.find_first_index(x) with(x.trans.getQid===arbitrated_qid);
  return(this.q_pending_status[idx[0]]);
endfunction:arbitrateToIssueStatus


function void vqdmaif_c2h_slave_driver::deleteItem_Trans(T_SEQ_ITEM me);
  int idx[$] = this.q_active.find_first_index(x) with (x===me);
  if(idx.size == 0) begin
    `vmg_error("H2C_SLAVE_DRIVER.NOT_CORRESPONDING_TRANS", $sformatf("Failed to get the corresponding active transcation for the incoming (qid=0x%1h)", me.trans.getQid));
  end
  this.q_active.delete(idx[0]);
  `vmg_info("H2C_SLV_DRIVER-COMPLETED_TRANS", $sformatf("trans=[%s] (#active=%1d) -- @%s", me.trans.getInfo, this.q_active.size, this.get_full_name), cfg.verbosity)
endfunction:deleteItem_Trans


task vqdmaif_c2h_slave_driver::waitIdle(string call_info="unspecified");
  `vmg_info("H2C_SLV_DRIVER-WAIT_IDLE", $sformatf("call_info=%s wait(q_active.size == 0) cur=%1d", call_info, this.q_active.size), UVM_LOW)
  wait(this.q_active.size == 0);
endtask:waitIdle


task vqdmaif_c2h_slave_driver::reset_phase(uvm_phase phase);
  super.reset_phase(phase);
  this.reset_pending = 1;
endtask
  

function void vqdmaif_c2h_slave_driver::initInternalState(string call_info="unspecified");
  `vmg_info("C2H_SLV_DRIVER-INIT_INTERNAL_STATE", $sformatf("Initializing... call_info=[%s]", call_info), UVM_LOW)
  this.vif.data_rdy <= 0;
  this.vif.cmd_rdy  <= 0;
  this.vif.status_pl <= '0;
  this.vif.status_vld <= 0;
  this.showInternalState(call_info);
  this.q_pending_fwd_transfer.delete();
  this.q_active.delete();
  foreach(this.sa_pending_fwd2status[qid]) this.sa_pending_fwd2status[qid].delete();
  this.sa_pending_fwd2status.delete();
  this.q_pending_fwd2status.delete();
  this.q_pending_status.delete();
  this.q_pending_status_qid.delete();
  this.q_bfm_timing_policy.delete();
  this.q_cmd_pending_cycle.delete();
  this.q_data_pending_cycle.delete();
  this.q_pending_status_latency.delete();
  this.q_pending_interrupt_sideband.delete();
  this.q_pending_interrupt_sideband_latency.delete();
endfunction


function void vqdmaif_c2h_slave_driver::showInternalState(string call_info="unspecified");
  //TODO
endfunction:showInternalState


function void vqdmaif_c2h_slave_driver::addItem_PendingStatus(T_SEQ_ITEM me);
  int idx[$] = this.q_pending_status.find_first_index(x) with(x.trans.getQid==me.trans.getQid);
  if(idx.size==0) this.q_pending_status_qid.push_back(me.trans.getQid);
  this.q_pending_status.push_back(me);
endfunction


function void vqdmaif_c2h_slave_driver::deleteItem_PendingStatus(T_SEQ_ITEM me);
  int idx[$] = this.q_pending_status.find_index(x) with(x.trans.getQid===me.trans.getQid);
  if(idx.size==0)begin
    `vmg_fatal_wrong_impl(this.get_full_name, $sformatf("Failed to deleteItem_PendingStatus(q_pending_status) for item=[%s]", me.getInfo));
  end
  this.q_pending_status.delete(idx[0]);
  if(idx.size==1)begin
    int idx2[$] = this.q_pending_status_qid.find_index(x) with(x==me.trans.getQid);
    if(idx2.size != 1)begin
      `vmg_fatal_wrong_impl(this.get_full_name, $sformatf("Failed to deleteItem_PendingStatus(q_pending_status_qid) idx2.size=%1d for item=[%s]", idx2.size, me.getInfo));
    end
    this.q_pending_status_qid.delete(idx2[0]);
  end
endfunction


function void vqdmaif_c2h_slave_driver::addItem_PendingFwd2Status(T_SEQ_ITEM me);
  this.sa_pending_fwd2status[me.trans.getQid].push_back(me);
  this.q_pending_fwd2status.push_back(me);
endfunction


function void vqdmaif_c2h_slave_driver::addItem_Trans(T_SEQ_ITEM me);
  this.q_active.push_back(me);
endfunction:addItem_Trans


function bit vqdmaif_c2h_slave_driver::isCompletedTrans_AfterIssueStatus(T_SEQ_ITEM me);
  if(this.cfg.dma_type==QDMA) return(1);
  if(!me.trans.isNeedInterruptSideband) return(1);
  return(0);
endfunction












`endif //__VQDMAIF_C2H_SLAVE_DRIVER_SVH__
