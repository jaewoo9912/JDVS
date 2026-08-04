`ifndef __VQDMAIF_H2C_SLAVE_DRIVER_SVH__
`define __VQDMAIF_H2C_SLAVE_DRIVER_SVH__



class vqdmaif_h2c_slave_driver extends vbfm_driver#(.REQ(vqdmaif_h2c_slave_sequence_item));

  typedef virtual vqdmaif_h2c_if T_VIF;
  typedef vqdmaif_h2c_slave_cfg T_CFG;
  typedef vqdmaif_h2c_slave_sequence_item T_SEQ_ITEM;
  typedef vqdmaif_h2c_transaction T_TRANS;
  typedef vqdmaif_h2c_sub_transaction T_SUB_TRANS;
  typedef QdmaH2CCmd_t T_CMD_PL;
  typedef QdmaH2CData_t T_DATA_PL;
  typedef QdmaH2CDataSideBand_t T_DATA_SB_PL;
  typedef QdmaH2CStatusSideBand_t T_STATUS_SB_PL;
  typedef QdmaH2CInterruptSideBand_t T_INTERRUPT_SB_PL;

  typedef enum int{
    NEW_SUB_TRANS,
    COMPLETED_SUB_TRANS,
    COMPLETED_TRANS,
    UNDEFINED_MAIN_EVENT
  }MainEventIdType_t;

  // -----------------------------------------------------------
  T_CFG cfg;
  T_VIF vif;
  vmem_if_svcr_behavior mem_svcr;
  real bandwidth;
  int DATA_SIZE;

  bit data_interleaving_on=0;

  `uvm_analysis_imp_decl(_trans_cmd);
  `uvm_analysis_imp_decl(_bandwidth);
  uvm_analysis_imp_trans_cmd#(vqdmaif_h2c_transaction, vqdmaif_h2c_slave_driver) impl_trans_cmd;
  uvm_analysis_imp_bandwidth#(real, vqdmaif_h2c_slave_driver) bandwidth_port;
  
  protected T_SEQ_ITEM q_active[$];
  protected T_SEQ_ITEM sa_pending_cmd2data[QdmaQId_t][$], q_pending_cmd2data[$];
  protected T_SEQ_ITEM q_pending_data[$];
  protected QdmaQId_t q_pending_data_qid[$];
  protected int unsigned q_cmd_pending_cycle[$];
  
  protected vqdmaif_h2c_slave_bfm_timing_policy q_bfm_timing_policy[$];
  protected T_SEQ_ITEM        q_pending_ctrl_sideband[$];
  protected T_SEQ_ITEM        q_pending_status_sideband[$];
  protected T_SEQ_ITEM        q_pending_interrupt_sideband[$];
  protected T_STATUS_SB_PL    q_pending_status_sideband_pl[$];
  protected T_INTERRUPT_SB_PL q_pending_interrupt_sideband_pl[$];

  protected int unsigned q_pending_status_sideband_latency[$];
  protected int unsigned q_pending_interrupt_sideband_latency[$];

  protected vqdmaif_h2c_transaction q_pending_cmd_trans[$];

  protected QdmaQId_t prev_arbitrated_qid;

  protected bit reset_pending;

  `uvm_component_utils(vqdmaif_h2c_slave_driver)
  function new(string name, uvm_component parent);
    super.new(name, parent);
    this.bandwidth_port = new("bandwidth_port", this);
  endfunction
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task reset_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

  extern task doOnCollectBfmTimingPolicy();

  extern virtual task doOnReset();
  extern virtual task doOnCmdService();
  extern virtual task doOnCmdRdy();
  extern virtual task doOnCmd2Data();
  extern virtual task doOnDataIssue();
  extern virtual task doOnCtrlSideband();
  extern virtual task doOnStatusSidebandIssue();
  extern virtual task doOnInterruptSidebandIssue();

  extern virtual function T_SEQ_ITEM arbitrateToIssueData();

  extern virtual function void write_trans_cmd(vqdmaif_h2c_transaction me);
  extern virtual function void write_bandwidth(real me);

	extern virtual function string decideReportFamilyId();

  extern local function T_STATUS_SB_PL makeStatusSidebandPl(T_TRANS trans);
  extern local function T_INTERRUPT_SB_PL makeInterruptSidebandPl(T_TRANS trans);

  extern virtual task waitIdle(string call_info="unspecified");
  extern task driveData(T_SEQ_ITEM me);

  extern virtual task readHmem(T_SEQ_ITEM item);
  extern virtual function void makeTransCompleted(T_TRANS trans, ref ByteQ_t bytestream);
  extern virtual function void decideBfmParam(T_SEQ_ITEM item);
  extern virtual function void initInternalState(string call_info="unspecified");

  extern protected function void addItem_PendingCmd2Data(T_SEQ_ITEM me);
  extern protected function void deleteItem_PendingCmd2Data(T_SEQ_ITEM me);
  extern protected function void addItem_PendingData(T_SEQ_ITEM me);
  extern protected function void deleteItem_PendingData(T_SEQ_ITEM me);
  extern protected function void addItem_Trans(T_SEQ_ITEM me);
  extern protected function void deleteItem_Trans(T_SEQ_ITEM me);

  extern protected function bit isCompletedTrans_AfterIssueLastData(T_SEQ_ITEM me);

endclass:vqdmaif_h2c_slave_driver


task vqdmaif_h2c_slave_driver::doOnCollectBfmTimingPolicy();
  forever begin
    T_SEQ_ITEM item;
    wait(this.q_bfm_timing_policy.size() <= this.cfg.max_ot);
    this.seq_item_port.get(item);
    this.q_bfm_timing_policy.push_back(item.bfm_timing_policy);
    this.seq_item_port.put(item);
  end
endtask

/**
 */
task vqdmaif_h2c_slave_driver::doOnReset();
  @(negedge this.clk_vif.RESETn);
endtask : doOnReset


task vqdmaif_h2c_slave_driver::reset_phase(uvm_phase phase);
  super.reset_phase(phase);
  this.reset_pending = 1;
endtask : reset_phase


function void vqdmaif_h2c_slave_driver::initInternalState(string call_info = "unspecified");
  `vmg_info("H2C_SLV_DRIVER-INIT_INTERNAL_STATE", $sformatf("Initializing... call_info=[%s]", call_info), UVM_LOW)
  this.vif.cmd_rdy <= 0;
  this.vif.data_pl <= '0;
  this.vif.data_vld <= 0;
  this.q_active.delete();
  foreach(this.sa_pending_cmd2data[qid]) this.sa_pending_cmd2data[qid].delete();
  this.sa_pending_cmd2data.delete();
  this.q_pending_cmd2data.delete();
  this.q_pending_data.delete();
  this.q_pending_data_qid.delete();
  this.q_cmd_pending_cycle.delete();
  this.q_bfm_timing_policy.delete();
  this.q_pending_ctrl_sideband.delete();
  this.q_pending_status_sideband.delete();
  this.q_pending_interrupt_sideband.delete();
  this.q_pending_status_sideband_pl.delete();
  this.q_pending_interrupt_sideband_pl.delete();
  this.q_pending_status_sideband_latency.delete();
  this.q_pending_interrupt_sideband_latency.delete();
  this.q_pending_cmd_trans.delete();
endfunction : initInternalState


task vqdmaif_h2c_slave_driver::doOnCmdService();
  int num_item;
  forever begin
    T_SEQ_ITEM item;

    wait(this.q_pending_cmd_trans.size>0);
    item = T_SEQ_ITEM::type_id::create($sformatf("%s.item#%1d", this.get_name, num_item++));
    item.trans = this.q_pending_cmd_trans.pop_front();
    this.readHmem(item);
    this.decideBfmParam(item);
    // ---------------------------
    this.addItem_PendingCmd2Data(item);
    this.addItem_Trans(item);
    this.q_cmd_pending_cycle.push_back(item.cmd_pending_cycle);
  end
endtask


function string vqdmaif_h2c_slave_driver::decideReportFamilyId(); return("H2C_SLV_DRV"); endfunction


task vqdmaif_h2c_slave_driver::doOnCmd2Data();
  forever begin
    T_SEQ_ITEM q_proceed_item[$];
    wait(this.q_pending_cmd2data.size > 0);
    this.waitCycle(1);
    foreach(this.q_pending_cmd2data[i])begin
      if(this.q_pending_cmd2data[i].ts_to_fetch != 0) this.q_pending_cmd2data[i].ts_to_fetch--;
    end

    case(this.cfg.arb_type)
      FIFS:begin
        if(this.q_pending_cmd2data[0].ts_to_fetch==0)begin
          q_proceed_item.push_back(this.q_pending_cmd2data[0]);
        end          
      end
      default:begin
        foreach(this.sa_pending_cmd2data[qid])begin
          if(this.sa_pending_cmd2data[qid][0].ts_to_fetch==0)begin
            q_proceed_item.push_back(this.sa_pending_cmd2data[qid][0]);
          end
        end
      end
    endcase

    foreach(q_proceed_item[i])begin
      this.addItem_PendingData(q_proceed_item[i]);
      this.deleteItem_PendingCmd2Data(q_proceed_item[i]);
    end
  end
endtask:doOnCmd2Data


function vqdmaif_h2c_slave_driver::T_SEQ_ITEM vqdmaif_h2c_slave_driver::arbitrateToIssueData();
  T_SEQ_ITEM item;
  int arbitrated_idx, idx[$];
  QdmaQId_t arbitrated_qid;

  case(this.cfg.arb_type)
    FIFS:begin
      arbitrated_qid = this.q_pending_data[0].trans.getQid;
    end
    RANDOM:begin
      int rand_idx = $urandom_range(0, this.q_pending_data.size-1);
      arbitrated_qid = this.q_pending_data[rand_idx].trans.getQid;
    end
    ROUND_ROBIN:begin
      int qid_queue_idx=0;
      if(this.q_pending_data_qid.size > 1)begin
        idx = this.q_pending_data_qid.find_first_index(x) with(x===this.prev_arbitrated_qid);
        if(idx.size != 0)begin
          if(idx[0]+1 <= this.q_pending_data_qid.size-1)begin
            qid_queue_idx = idx[0]+1;
          end
        end
      end
      arbitrated_qid = this.q_pending_data_qid[qid_queue_idx];
    end
    default:begin
      `vmg_fatal_shall_impl(this.get_full_name, $sformatf("arbitrateToIssueData -- cfg.arb_type=%s", cfg.arb_type.name))
    end
  endcase
  
  `vmg_info(this.get_full_name, $sformatf("ARB_RESULT: prev_qid/cur_qid=%1d/%1d %s num_active_trans/qid=%1d/%1d",
      this.prev_arbitrated_qid, arbitrated_qid,
      this.cfg.arb_type.name,
      this.q_active.size, this.q_pending_data_qid.size
    ), this.cfg.arb_result_verbosity)
  this.prev_arbitrated_qid = arbitrated_qid;

  idx = this.q_pending_data.find_first_index(x) with(x.trans.getQid===arbitrated_qid);
  return(this.q_pending_data[idx[0]]);
endfunction:arbitrateToIssueData


function void vqdmaif_h2c_slave_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
  `vmg_get_cfgdb_at_me(T_CFG, "cfg", this.cfg)
  `vmg_get_cfgdb_at_me(T_VIF, "vif", this.vif);
  this.DATA_SIZE = this.cfg.DATA_SIZE;
  this.impl_trans_cmd = new("impl_trans_cmd", this);
endfunction:build_phase


task vqdmaif_h2c_slave_driver::run_phase(uvm_phase phase);
  super.run_phase(phase);
  this.vif.cmd_rdy  <= FlipCoin(50);
  this.vif.data_pl <= '0;
  this.vif.data_vld <= 0;
  @(negedge this.clk_vif.RESETn);
  this.reset_pending = 0;
  forever begin
    fork
      begin
        fork
          begin : H2C
            fork
              this.doOnCollectBfmTimingPolicy();
              this.doOnCmdService();
              this.doOnCmdRdy();
              this.doOnCmd2Data();
              this.doOnDataIssue();
              this.doOnCtrlSideband();
              this.doOnStatusSidebandIssue();
              this.doOnInterruptSidebandIssue();
            join
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


task vqdmaif_h2c_slave_driver::doOnCmdRdy();
  int unsigned cmd_pending_cycle;
  bit pop_done = 0;
  forever begin
    this.vif.cmd_rdy <= 0;
    wait(this.cfg.max_ot > this.q_active.size);

    if(q_cmd_pending_cycle.size > 0) begin
      cmd_pending_cycle = q_cmd_pending_cycle[0];
      pop_done = 1;
    end
    else begin
      cmd_pending_cycle = $urandom_range(this.cfg.default_bfm_timing_policy.start_cmd_pending_cycle, this.cfg.default_bfm_timing_policy.end_cmd_pending_cycle);
    end

    this.waitCycle(cmd_pending_cycle);
    this.vif.cmd_rdy <= 1;
    this.waitCycle();
    if(this.vif.cmd_vld && this.vif.cmd_rdy && pop_done) begin
      void'(q_cmd_pending_cycle.pop_front);
      pop_done = 0;
    end
  end
endtask:doOnCmdRdy


function void vqdmaif_h2c_slave_driver::write_bandwidth(real me);
  this.bandwidth = me; 
endfunction : write_bandwidth


task vqdmaif_h2c_slave_driver::doOnDataIssue();
  forever begin
    T_SEQ_ITEM item;

    wait(this.q_pending_data.size > 0);
    item = this.arbitrateToIssueData();
    this.driveData(item);
    if(item.data_issue_idx<item.trans.getNumData) continue;

    if(this.isCompletedTrans_AfterIssueLastData(item))begin
      this.deleteItem_Trans(item);
    end
    if(this.cfg.dma_type==MBDMA)begin
      if(item.trans.isNeedStatusSideband || item.trans.isNeedInterruptSideband)begin
        this.q_pending_ctrl_sideband.push_back(item);
      end
    end
  end
endtask:doOnDataIssue


task vqdmaif_h2c_slave_driver::driveData(T_SEQ_ITEM me);
  int num_data_to_issue = !this.data_interleaving_on ? me.trans.getNumData : 1;

  repeat(num_data_to_issue)begin
    T_DATA_PL data_pl;
    T_DATA_SB_PL data_sideband_pl;
    int unsigned data_latency;

    me.trans.getData(me.data_issue_idx, data_pl);
    me.trans.getDataSideband(me.data_issue_idx, data_sideband_pl);
    data_latency = me.data_latency[me.data_issue_idx];
    me.data_issue_idx++;
    this.vif.data_vld <= 0;
    if(this.cfg.driver_operation_mode == PERF_MODE && this.cfg.performance_measure == YES && this.cfg.target_bandwidth > this.bandwidth) data_latency=0;
    //TODO:NeedReview
    if(!data_latency) data_latency = 0;
    else              data_latency--;

    this.waitCycle(data_latency);
    this.vif.data_vld         <= 1;
    this.vif.data_pl          <= data_pl;
    this.vif.data_sideband_pl <= data_sideband_pl;
    this.waitCycle();
    while(this.vif.data_rdy===0) this.waitCycle();
  end

  if(me.data_issue_idx==me.trans.getNumData)begin
    this.deleteItem_PendingData(me);
  end
  if(this.q_pending_data.size == 0)begin
    this.vif.data_vld <= 0;
    this.waitCycle();
  end
endtask:driveData


task vqdmaif_h2c_slave_driver::doOnCtrlSideband();
  forever begin
    T_SEQ_ITEM item;
    T_STATUS_SB_PL status_sideband_pl;
    T_INTERRUPT_SB_PL interrupt_sideband_pl;

    wait(this.q_pending_ctrl_sideband.size > 0);
    
    item = this.q_pending_ctrl_sideband.pop_front();

    if(item.trans.isNeedStatusSideband) begin
      status_sideband_pl = this.makeStatusSidebandPl(item.trans);
      this.q_pending_status_sideband_pl.push_back(status_sideband_pl);
      this.q_pending_status_sideband.push_back(item);
      this.q_pending_status_sideband_latency.push_back(item.status_sideband_latency);
    end

    if(item.trans.isNeedInterruptSideband) begin
      interrupt_sideband_pl = this.makeInterruptSidebandPl(item.trans);
      this.q_pending_interrupt_sideband_pl.push_back(interrupt_sideband_pl);
      this.q_pending_interrupt_sideband.push_back(item);
      this.q_pending_interrupt_sideband_latency.push_back(item.interrupt_sideband_latency);
    end
  end  
endtask : doOnCtrlSideband


task vqdmaif_h2c_slave_driver::doOnStatusSidebandIssue();
  forever begin
    T_SEQ_ITEM served;
    T_STATUS_SB_PL status_sideband_pl;

    wait(this.q_pending_status_sideband.size > 0);
    served = this.q_pending_status_sideband.pop_front();
    status_sideband_pl = this.q_pending_status_sideband_pl.pop_front();

    this.vif.status_sideband_vld <= 0;
    this.waitCycle(q_pending_status_sideband_latency.pop_front());
    this.vif.status_sideband_vld <= 1;
    this.vif.status_sideband_pl <= status_sideband_pl;
    served.trans.storeStatusSideband(status_sideband_pl);
    if(served.trans.wasDone) this.deleteItem_Trans(served);
    this.waitCycle();
    while(this.vif.status_sideband_rdy === 0) this.waitCycle();
    if(this.q_pending_status_sideband.size == 0) begin
      this.vif.status_sideband_vld <= 0;
      this.waitCycle();
    end
  end  
endtask : doOnStatusSidebandIssue


task vqdmaif_h2c_slave_driver::doOnInterruptSidebandIssue();
  forever begin
    T_SEQ_ITEM served;
    T_INTERRUPT_SB_PL interrupt_sideband_pl;

    wait(this.q_pending_interrupt_sideband.size > 0);
    served = this.q_pending_interrupt_sideband.pop_front();
    interrupt_sideband_pl = this.q_pending_interrupt_sideband_pl.pop_front();

    this.vif.interrupt_sideband_vld <= 0;
    this.waitCycle(q_pending_interrupt_sideband_latency.pop_front());
    this.vif.interrupt_sideband_vld <= 1;
    this.vif.interrupt_sideband_pl <= interrupt_sideband_pl;
    served.trans.storeInterruptSideband(interrupt_sideband_pl);
    if(served.trans.wasDone) this.deleteItem_Trans(served);
    this.waitCycle();
    while(this.vif.interrupt_sideband_rdy === 0) this.waitCycle();
    if(this.q_pending_interrupt_sideband.size == 0) begin
      this.vif.interrupt_sideband_vld <= 0;
      this.waitCycle();
    end
  end
endtask : doOnInterruptSidebandIssue


function vqdmaif_h2c_slave_driver::T_STATUS_SB_PL vqdmaif_h2c_slave_driver::makeStatusSidebandPl(T_TRANS trans);
  T_STATUS_SB_PL status_sideband_pl;
  
  status_sideband_pl.qid = trans.qid;
  status_sideband_pl.dma_id = trans.q_sub[0].cmd_sideband_pl.dma_id;

  return(status_sideband_pl);
endfunction : makeStatusSidebandPl


function vqdmaif_h2c_slave_driver::T_INTERRUPT_SB_PL vqdmaif_h2c_slave_driver::makeInterruptSidebandPl(T_TRANS trans);
  T_INTERRUPT_SB_PL interrupt_sideband_pl;
  
  interrupt_sideband_pl.qid    = trans.qid;
  interrupt_sideband_pl.dma_id = trans.q_sub[0].cmd_sideband_pl.dma_id;
  interrupt_sideband_pl.vec_id = trans.q_sub[$].cmd_sideband_pl.vec_id;
  interrupt_sideband_pl.fnc_id = trans.q_sub[$].getFunc();

  return(interrupt_sideband_pl);
endfunction : makeInterruptSidebandPl


function void vqdmaif_h2c_slave_driver::deleteItem_Trans(T_SEQ_ITEM me);
  int idx[$] = this.q_active.find_first_index(x) with (x===me);
  if(idx.size == 0) begin
    `vmg_error("H2C_SLAVE_DRIVER.NOT_CORRESPONDING_TRANS", $sformatf("Failed to get the corresponding active transcation for the incoming (qid=0x%1h)", me.trans.getQid));
  end
  this.q_active.delete(idx[0]);
  `vmg_info("H2C_SLV_DRIVER-COMPLETED_TRANS", $sformatf("trans=[%s] (#active=%1d) -- @%s", me.trans.getInfo, this.q_active.size, this.get_full_name), cfg.verbosity)
endfunction:deleteItem_Trans


task vqdmaif_h2c_slave_driver::waitIdle(string call_info="unspecified");
  `vmg_info("H2C_SLV_DRIVER-WAIT_IDLE", $sformatf("call_info=%s wait(q_active.size == 0) cur=%1d", call_info, this.q_active.size), UVM_LOW)
  wait(this.q_active.size == 0);
endtask:waitIdle


function void vqdmaif_h2c_slave_driver::deleteItem_PendingCmd2Data(T_SEQ_ITEM me);
  int idx[$] = this.q_pending_cmd2data.find_first_index(x) with(x===me);
  if(idx.size==0)begin
    `vmg_fatal_wrong_impl(this.get_full_name, $sformatf("Failed to deleteItem_PendingCmd2Data(q_pending_cmd2data) for item=[%s]", me.getInfo));
  end
  this.q_pending_cmd2data.delete(idx[0]);

  if(!this.sa_pending_cmd2data.exists(me.trans.getQid))begin
    `vmg_fatal_wrong_impl(this.get_full_name, $sformatf("Failed to deleteItem_PendingCmd2Data(sa_pending_cmd2data) for item=[%s]", me.getInfo));
  end
  void'(this.sa_pending_cmd2data[me.trans.getQid].pop_front);
  if(this.sa_pending_cmd2data[me.trans.getQid].size==0)  this.sa_pending_cmd2data.delete(me.trans.getQid);
endfunction


function void vqdmaif_h2c_slave_driver::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  if(this.mem_svcr==null) `vmg_fatal_wrong_usage(this.get_full_name, "You should set \"mem_svcr\" handle at connect_phase for me!!")
endfunction


function void vqdmaif_h2c_slave_driver::write_trans_cmd(T_TRANS me);
  vqdmaif_h2c_transaction cloned;
  $cast(cloned, me.clone);
  cloned.cfg = me.cfg;
  cloned.qid = me.qid;
  this.q_pending_cmd_trans.push_back(cloned);
endfunction:write_trans_cmd


task vqdmaif_h2c_slave_driver::readHmem(T_SEQ_ITEM item);
  ByteQ_t bytestream;
  foreach(item.trans.q_sub[i])begin
    T_SUB_TRANS subtrans = item.trans.q_sub[i];
    this.mem_svcr.readByteQ(subtrans.ctrl_info.addr, subtrans.ctrl_info.len, subtrans.bytestream);
    foreach(subtrans.bytestream[j]) bytestream.push_back(subtrans.bytestream[j]);
  end
  this.makeTransCompleted(item.trans, bytestream);
endtask


function void vqdmaif_h2c_slave_driver::makeTransCompleted(T_TRANS trans, ref ByteQ_t bytestream);
  localparam int MAX_ITER = 32'h7FFF_FFFF;
  int remained_len = trans.ctrl_info.len;
  bit loop_done = 0;
  int idx;

  for(int i = 0; i < MAX_ITER; i++) begin
    QdmaH2CData_t data_pl=0;
    QdmaH2CDataSideBand_t data_sideband_pl=0;

    data_pl.qid = trans.getQid;
    data_pl.port_id = trans.ctrl_info.port_id;
    
    data_sideband_pl.dma_id = trans.q_sub[0].cmd_sideband_pl.dma_id;
    data_sideband_pl.fid    = trans.q_sub[0].cmd_sideband_pl.fid;

    if(remained_len < this.DATA_SIZE) data_pl.mty = this.DATA_SIZE - remained_len;

    data_pl.last = remained_len <= this.DATA_SIZE;

    for(int j = 0; j < this.DATA_SIZE; j++) begin
      data_pl.data[j*8+:8] = bytestream[idx++];
      remained_len--;
      if(remained_len == 0) begin
        loop_done = 1;
        break;
      end 
    end

    trans.storeData(data_pl);
    trans.storeDataSideband(data_sideband_pl);
    if(loop_done) break;
  end

  if(!loop_done) begin
    `vmg_fatal_wrong_impl(this.get_name, $sformatf("Loop exited without consuming all %1d bytes", remained_len));
  end
endfunction:makeTransCompleted


function void vqdmaif_h2c_slave_driver::decideBfmParam(T_SEQ_ITEM item);
  vqdmaif_h2c_slave_bfm_timing_policy policy;

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


function void vqdmaif_h2c_slave_driver::addItem_Trans(T_SEQ_ITEM me);
  this.q_active.push_back(me);
endfunction:addItem_Trans


function void vqdmaif_h2c_slave_driver::addItem_PendingCmd2Data(T_SEQ_ITEM me);
  this.sa_pending_cmd2data[me.trans.getQid].push_back(me);
  this.q_pending_cmd2data.push_back(me);
endfunction


function void vqdmaif_h2c_slave_driver::addItem_PendingData(T_SEQ_ITEM me);
  int idx[$] = this.q_pending_data.find_first_index(x) with(x.trans.getQid==me.trans.getQid);
  if(idx.size==0) this.q_pending_data_qid.push_back(me.trans.getQid);
  this.q_pending_data.push_back(me);
endfunction


function void vqdmaif_h2c_slave_driver::deleteItem_PendingData(T_SEQ_ITEM me);
  int idx[$] = this.q_pending_data.find_index(x) with(x.trans.getQid===me.trans.getQid);
  if(idx.size==0)begin
    `vmg_fatal_wrong_impl(this.get_full_name, $sformatf("Failed to deleteItem_PendingData(q_pending_data) for item=[%s]", me.getInfo));
  end
  this.q_pending_data.delete(idx[0]);
  if(idx.size==1)begin
    int idx2[$] = this.q_pending_data_qid.find_index(x) with(x==me.trans.getQid);
    if(idx2.size != 1)begin
      `vmg_fatal_wrong_impl(this.get_full_name, $sformatf("Failed to deleteItem_PendingData(q_pending_data_qid) idx2.size=%1d for item=[%s]", idx2.size, me.getInfo));
    end
    this.q_pending_data_qid.delete(idx2[0]);
  end
endfunction


function bit vqdmaif_h2c_slave_driver::isCompletedTrans_AfterIssueLastData(T_SEQ_ITEM me);
  if(this.cfg.dma_type==QDMA) return(1);
  if(me.trans.isNeedStatusSideband) return(0);
  if(me.trans.isNeedInterruptSideband) return(0);
  return(1);
endfunction






`endif // __VQDMAIF_H2C_SLAVE_DRIVER_SVH__
