`ifndef __VQDMAIF_C2H_MASTER_DRIVER_SVH__
`define __VQDMAIF_C2H_MASTER_DRIVER_SVH__

class vqdmaif_c2h_master_driver extends vbfm_driver#(.REQ(vqdmaif_c2h_master_sequence_item));

  typedef vqdmaif_c2h_master_sequence_item T_SEQ_ITEM;
  typedef QdmaC2HStatus_t T_STATUS_PL;
  typedef QdmaC2HStatusSideBand_t T_STATUS_SB_PL;
  typedef QdmaC2HInterruptSideBand_t T_INTERRUPT_SB_PL;
  typedef virtual vqdmaif_c2h_if T_VIF;
  typedef enum int{
    NOT_CORRESPONDING_STATUS,
    NOT_CORRESPONDING_INTERRUPT_SIDEBAND,
    COMPLETED_SEQ_ITEM,
    WAIT_IDLE
  }MainEventIdType_t;

  vqdmaif_c2h_master_cfg cfg;
  T_VIF vif;
  vqdmaif_c2h_master_sequence_item q_pending[$], q_active[$];
  T_SEQ_ITEM q_pending_cmd_item[$];
  protected T_SEQ_ITEM q_pending_cmd2data_item[$];
  T_SEQ_ITEM q_pending_data_item[$];
  protected int unsigned q_pending_status_cycle[$];

  `uvm_component_utils(vqdmaif_c2h_master_driver)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task waitIdle(string call_info);

	extern virtual function string decideReportFamilyId();
  extern virtual function void reportMainEvent(MainEventIdType_t event_id, string msg, uvm_verbosity verbosity);
  extern virtual function void reportDebugInfo(string debug_id, string msg);

  extern virtual task doOnReset();
  extern virtual task doOnQdma();
  extern virtual task doOnMbdma();

  extern local task doOnMstSeqItem();
  extern local task doOnMstSeqItem_CollectItem();
  extern local task doOnMstSeqItem_SeperateCmdAndData();
  extern local task doOnCmd();
  extern local task doOnCmd_DriveItem();
  extern local task doOnCmd2Data();
  extern local task doOnData();
  extern local task doOnData_DriveItem();
  extern local task doOnStatus(); //To generate rdy
  extern local task driveTransfer_CMD(T_SEQ_ITEM item);
  extern local task driveTransfer_DATA(T_SEQ_ITEM item, int data_idx);
  extern local function void showActiveTrans(string prompt="");

  extern local task doOnInterruptSideband();
  extern local task doOnStatusRdy();
  extern local task doOnInterruptSidebandRdy();

  extern local function int unsigned pickStatusPendingCycle();
  extern local function int unsigned pickInterruptPendingCycle();
  extern virtual function void initInternalState(string call_info = "unspecified");
endclass:vqdmaif_c2h_master_driver

function string vqdmaif_c2h_master_driver::decideReportFamilyId(); return("C2H_MST_DRV"); endfunction

function void vqdmaif_c2h_master_driver::reportMainEvent(MainEventIdType_t event_id, string msg, uvm_verbosity verbosity);
  this.reportMainEvent_body(event_id.name, msg, verbosity);
endfunction:reportMainEvent

function void vqdmaif_c2h_master_driver::reportDebugInfo(string debug_id, string msg);
	this.reportDebugInfo_body(debug_id, msg);
endfunction

function void vqdmaif_c2h_master_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
  `vmg_get_cfgdb_at_me(vqdmaif_c2h_master_cfg, "cfg", this.cfg)
  `vmg_get_cfgdb_at_me(T_VIF, "vif", this.vif)
endfunction


task vqdmaif_c2h_master_driver::run_phase(uvm_phase phase);
  fork
    super.run_phase(phase);
    begin
      this.vif.cmd_vld  <= 0;
      this.vif.cmd_pl   <= $urandom;
      this.vif.data_vld <= 0;
      this.vif.data_pl  <= $urandom;
      this.vif.status_rdy <= FlipCoin(50);
      @(posedge this.vif.IF_clk.RESETn);
      forever begin
        fork
          begin
            fork
              begin
                if(this.cfg.dma_type == QDMA) this.doOnQdma();
                else                          this.doOnMbdma();
              end
              begin
                this.doOnReset();
              end
            join_any
            disable fork;
            this.initInternalState("reset triggered");
            @(posedge this.vif.IF_clk.RESETn);
          end
        join
      end
    end
  join
endtask : run_phase

task vqdmaif_c2h_master_driver::doOnReset();
  @(negedge this.vif.IF_clk.RESETn);
endtask : doOnReset

function void vqdmaif_c2h_master_driver::initInternalState(string call_info = "unspecified");
  `vmg_info("C2H_MST_DRIVER-INIT_INTERNAL_STATE", $sformatf("Initializing... call_info=[%s]", call_info), UVM_LOW)
  this.vif.cmd_vld  <= 0;
  this.vif.cmd_pl   <= $urandom;
  this.vif.data_vld <= 0;
  this.vif.data_pl  <= $urandom;
  this.vif.status_rdy <= 0;
  q_pending.delete();
  q_active.delete();
  q_pending_cmd_item.delete();
  q_pending_data_item.delete();
endfunction : initInternalState

task vqdmaif_c2h_master_driver::doOnQdma();
  forever begin
    fork
      begin
        this.vif.status_rdy <= 1; // no c2h status rdy in QDMA spec, so fix it to 1
        fork
          this.doOnMstSeqItem();
          this.doOnCmd();
          this.doOnCmd2Data();
          this.doOnData();
          this.doOnStatus();
          this.doOnReset();
        join_any
        disable fork;
        this.initInternalState("reset triggered");
        @(posedge this.vif.IF_clk.RESETn);
      end
    join
  end
endtask : doOnQdma


task vqdmaif_c2h_master_driver::doOnMbdma();
  fork
    this.doOnMstSeqItem();
    this.doOnCmd();
    this.doOnCmd2Data();
    this.doOnData();
    this.doOnStatus();
    this.doOnStatusRdy();
    this.doOnInterruptSidebandRdy();
    this.doOnInterruptSideband();
  join
endtask : doOnMbdma


task vqdmaif_c2h_master_driver::doOnMstSeqItem();
  fork
    this.doOnMstSeqItem_CollectItem();
    this.doOnMstSeqItem_SeperateCmdAndData();
  join
endtask : doOnMstSeqItem


task vqdmaif_c2h_master_driver::doOnMstSeqItem_CollectItem();
  forever begin
    vqdmaif_c2h_master_sequence_item item;
    this.seq_item_port.get_next_item(item);
    this.q_pending.push_back(item);
    this.seq_item_port.item_done(item);
  end
endtask : doOnMstSeqItem_CollectItem


task vqdmaif_c2h_master_driver::doOnMstSeqItem_SeperateCmdAndData();
  forever begin
    vqdmaif_c2h_master_sequence_item item;

    wait(this.q_pending.size > 0);
    item = this.q_pending.pop_front();
    this.q_pending_cmd_item.push_back(item);
    this.q_pending_cmd2data_item.push_back(item);
    if(this.cfg.dma_type == QDMA || (this.cfg.dma_type == MBDMA && (item.trans.isNeedStatus || item.trans.isNeedInterruptSideband)))begin
      this.q_active.push_back(item);
    end
  end
endtask : doOnMstSeqItem_SeperateCmdAndData


task vqdmaif_c2h_master_driver::doOnCmd();
  this.doOnCmd_DriveItem();
endtask : doOnCmd


task vqdmaif_c2h_master_driver::doOnCmd_DriveItem();
  forever begin
    T_SEQ_ITEM item;
    wait(this.q_pending_cmd_item.size > 0);
    item = this.q_pending_cmd_item.pop_front();
    this.driveTransfer_CMD(item);
  end
endtask:doOnCmd_DriveItem


task vqdmaif_c2h_master_driver::doOnCmd2Data();
  forever begin
    T_SEQ_ITEM item;
    wait(this.q_pending_cmd2data_item.size > 0);
    item = this.q_pending_cmd2data_item.pop_front();
    this.waitCycle(item.cmd2data_delay);
    this.q_pending_data_item.push_back(item);
  end
endtask:doOnCmd2Data

task vqdmaif_c2h_master_driver::driveTransfer_CMD(T_SEQ_ITEM item);
  this.vif.cmd_vld <= 0;
  this.waitCycle(item.cmd2cmd_delay);
  this.vif.cmd_vld          <= 1;
  this.vif.cmd_pl           <= item.trans.cmd_pl;
  this.vif.cmd_sideband_pl  <= item.trans.cmd_sideband_pl;
  this.waitCycle();
  while(this.vif.cmd_rdy === 0) this.waitCycle();
  if(this.q_pending_cmd_item.size == 0)begin
    this.vif.cmd_vld <= 0;
    if(this.cfg.drv_hold_pl_at_non_vld == NO) this.vif.cmd_pl <= $urandom;
    this.waitCycle();
  end
endtask:driveTransfer_CMD


task vqdmaif_c2h_master_driver::doOnData();
  this.doOnData_DriveItem();
endtask : doOnData


task vqdmaif_c2h_master_driver::doOnData_DriveItem();
  forever begin
    T_SEQ_ITEM item;
    wait(this.q_pending_data_item.size > 0);
    item = this.q_pending_data_item.pop_front();
    for(int i=0; i<item.trans.getNumData; i++)begin
      this.driveTransfer_DATA(item, i);
    end
    this.q_pending_status_cycle.push_back(item.status_pending_cycle);
  end
endtask:doOnData_DriveItem


task vqdmaif_c2h_master_driver::driveTransfer_DATA(T_SEQ_ITEM item, int data_idx);
  this.vif.data_vld <= 0;
  this.waitCycle(item.data2data_delay_list[data_idx]);
  this.vif.data_vld <= 1;
  this.vif.data_pl  <= item.trans.q_data_pl[data_idx];
  this.vif.data_sideband_pl <= item.trans.q_data_sideband_pl[data_idx];
  this.waitCycle();
  while(this.vif.data_rdy === 0) this.waitCycle();
  if(this.q_pending_data_item.size == 0 && item.trans.getNumData-1 == data_idx)begin
    this.vif.data_vld <= 0;
    if(this.cfg.drv_hold_pl_at_non_vld == NO) this.vif.data_pl <= $urandom;
    this.waitCycle();
  end
endtask:driveTransfer_DATA


task vqdmaif_c2h_master_driver::doOnStatus();
  fork
    forever begin : UPDATE_ACTIVE
      vqdmaif_c2h_master_sequence_item item;
      T_STATUS_PL status_pl;
      T_STATUS_SB_PL status_sideband_pl;
      int idx[$];
      this.vif.WaitTransferHs_STATUS(status_pl);
      status_sideband_pl = this.vif.status_sideband_pl;
      if     (this.cfg.dma_type == QDMA )  idx = this.q_active.find_first_index(x) with(x.trans.qid === status_pl.qid);
      else if(this.cfg.dma_type == MBDMA)  idx = this.q_active.find_first_index(x) with(x.trans.getQid == status_pl.qid && x.trans.hasStatus === 0);
      if(idx.size == 0) begin
        `vmg_error(
          "C2H_MASTER_DRIVER.NOT_CORRESPONDING_STATUS", 
          $sformatf("Failed to get the corresponding active transaction for the incoming \"STATUS\"(qid=0x%1h)", status_pl.qid)
        )
        break;
      end
      item = this.q_active[idx[0]];
      item.trans.storeStatus(status_pl);
      item.trans.storeStatusSideband(status_sideband_pl);
      if(item.trans.wasDone) begin
        this.seq_item_port.put_response(item);
        this.q_active.delete(idx[0]);
        this.reportMainEvent(
            COMPLETED_SEQ_ITEM, 
            $sformatf("%s=[%s] q_active/q_pending/q_pending_cmd_item/q_pending_data_item=%1d/%1d/%1d/%1d", 
              item.get_name, item.getInfo, this.q_active.size, this.q_pending.size, this.q_pending_cmd_item.size, this.q_pending_data_item.size
            ),
            cfg.verbosity
        );
      end
    end
  join
endtask : doOnStatus


task vqdmaif_c2h_master_driver::doOnInterruptSideband();
  fork
    forever begin
      vqdmaif_c2h_master_sequence_item item;
      T_INTERRUPT_SB_PL interrupt_sideband_pl;
      int idx[$];
      this.vif.WaitTransferHs_INTERRUPT_SIDEBAND(interrupt_sideband_pl);
      idx = this.q_active.find_first_index(x) with(x.trans.getQid == interrupt_sideband_pl.qid && x.trans.hasInterruptSideband === 0);
      if(idx.size == 0) begin
        this.reportMainEvent(NOT_CORRESPONDING_INTERRUPT_SIDEBAND, $sformatf("Failed to get the corresponding active transaction for the incoming \"INTERRUPT_SIDEBAND\"(qid=0x%1h)", interrupt_sideband_pl.qid), UVM_NONE);
        break;
      end
      item = this.q_active[idx[0]];
      item.trans.storeInterruptSideband(interrupt_sideband_pl);
      if(item.trans.wasDone) begin
        this.seq_item_port.put_response(item);
        this.q_active.delete(idx[0]);
        this.reportMainEvent(
            COMPLETED_SEQ_ITEM, 
            $sformatf("%s=[%s] q_active/q_pending/q_pending_cmd_item/q_pending_data_item=%1d/%1d/%1d/%1d", 
              item.get_name, item.getInfo, this.q_active.size, this.q_pending.size, this.q_pending_cmd_item.size, this.q_pending_data_item.size
            ),
            cfg.verbosity
        );
      end
    end
  join  
endtask : doOnInterruptSideband


task vqdmaif_c2h_master_driver::doOnStatusRdy();
  forever begin
    this.vif.status_rdy <= 0;
    if(this.q_pending_status_cycle.size > 0) begin
      int unsigned status_pending_cycle = this.q_pending_status_cycle.pop_front();
      this.waitCycle(status_pending_cycle);
    end
    else begin
      this.waitCycle(this.pickStatusPendingCycle);
    end
    this.vif.status_rdy <= 1;
    this.waitCycle();
  end
endtask : doOnStatusRdy


task vqdmaif_c2h_master_driver::doOnInterruptSidebandRdy();
  forever begin
    this.vif.interrupt_sideband_rdy <= 0;
    this.waitCycle(this.pickInterruptPendingCycle);
    this.vif.interrupt_sideband_rdy <= 1;
    this.waitCycle();
  end
endtask : doOnInterruptSidebandRdy


function void vqdmaif_c2h_master_driver::showActiveTrans(string prompt="");
  `vmg_info(this.get_name, $sformatf("%s--------------------------------------------------------------------------", prompt), UVM_LOW)
  `vmg_info(this.get_name, $sformatf("%s [%s] Has %1d active transactions", prompt, this.q_active.size, this.makeReportId("ACTIVE_TRANS")), UVM_LOW)
  `vmg_info(this.get_name, $sformatf("%s--------------------------------------------------------------------------", prompt), UVM_LOW)
  foreach(this.q_active[i])begin
    `vmg_info(this.get_name, $sformatf("%s\t\t trans[%-3d] %s", prompt, i, this.q_active[i].getInfo), UVM_LOW)
  end
endfunction:showActiveTrans


task vqdmaif_c2h_master_driver::waitIdle(string call_info);
  this.reportMainEvent(WAIT_IDLE, $sformatf("waitIdle(call_info=%s) this.q_pending.size=%1d", call_info, this.q_pending.size), UVM_LOW);
  wait(this.q_pending.size == 0);
  this.reportMainEvent(WAIT_IDLE, $sformatf("waitIdle(call_info=%s) this.vif.cmd_vld=%1d", call_info, this.vif.cmd_vld), UVM_LOW);
  wait(this.vif.cmd_vld == 0);
  this.reportMainEvent(WAIT_IDLE, $sformatf("waitIdle(call_info=%s) this.q_pending_cmd_item.size=%1d", call_info, this.q_pending_cmd_item.size), UVM_LOW);
  wait(this.q_pending_cmd_item.size == 0);
  this.reportMainEvent(WAIT_IDLE, $sformatf("waitIdle(call_info=%s) this.q_pending_data_item.size=%1d", call_info, this.q_pending_data_item.size), UVM_LOW);
  wait(this.q_pending_data_item.size == 0);
  this.reportMainEvent(WAIT_IDLE, $sformatf("waitIdle(call_info=%s) this.q_active.size=%1d", call_info, this.q_active.size), UVM_LOW);
  wait(this.q_active.size == 0);
endtask : waitIdle


function int unsigned vqdmaif_c2h_master_driver::pickStatusPendingCycle();
  return($urandom_range(this.cfg.start_status_pending_cycle, this.cfg.end_status_pending_cycle));
endfunction : pickStatusPendingCycle

function int unsigned vqdmaif_c2h_master_driver::pickInterruptPendingCycle();
  return($urandom_range(this.cfg.start_interrupt_pending_cycle, this.cfg.end_interrupt_pending_cycle));
endfunction : pickInterruptPendingCycle


`endif //__VQDMAIF_C2H_MASTER_DRIVER_SVH__
