`ifndef __VQDMAIF_H2C_MASTER_DRIVER_SVH__
`define __VQDMAIF_H2C_MASTER_DRIVER_SVH__

class vqdmaif_h2c_master_driver extends vbfm_driver#(.REQ(vqdmaif_h2c_master_sequence_item));

  typedef vqdmaif_h2c_master_sequence_item T_SEQ_ITEM;
  typedef virtual vqdmaif_h2c_if T_VIF;
  typedef QdmaH2CData_t T_DATA_PL;
  typedef QdmaH2CDataSideBand_t T_DATA_SB_PL;
  typedef QdmaH2CStatusSideBand_t T_STATUS_SB_PL;
  typedef QdmaH2CInterruptSideBand_t T_INTERRUPT_SB_PL;
  typedef enum int{
    NOT_CORRESPONDING_DATA,
    NOT_CORRESPONDING_STATUS_SIDEBAND,
    NOT_CORRESPONDING_INTERRUPT_SIDEBAND,
    COMPLETED_SEQ_ITEM,
    WAIT_IDLE
  }MainEventIdType_t;

  vqdmaif_h2c_master_cfg cfg;
  T_VIF vif;
  T_SEQ_ITEM q_active[$];
  T_SEQ_ITEM q_pending_cmd_item[$];

  `uvm_component_utils(vqdmaif_h2c_master_driver)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task waitIdle(string call_info);
  // -------------------
  extern virtual task doOnReset();
  extern virtual task doOnQdma();
  extern virtual task doOnMbdma();
  extern virtual task doOnCmd();
  extern virtual task doOnData();
  extern virtual task driveTransfer_CMD(T_SEQ_ITEM item, int sub_idx);
  extern local function int unsigned pickDataPendingCycle();
  extern virtual function void initInternalState(string call_info="unspecified");
  // -------------------
  extern local task doOnStatusSideband();
  extern local task doOnInterruptSideband();
  extern local task doOnStatusSidebandRdy();
  extern local task doOnInterruptSidebandRdy();

  extern local function int unsigned pickStatusSidebandPendingCycle();
  extern local function int unsigned pickInterruptSidebandPendingCycle();

	extern virtual function string decideReportFamilyId();
  extern virtual function void reportMainEvent(MainEventIdType_t event_id, string msg, uvm_verbosity verbosity);
  extern virtual function void reportDebugInfo(string debug_id, string msg);
endclass:vqdmaif_h2c_master_driver

function string vqdmaif_h2c_master_driver::decideReportFamilyId(); return("H2C_MST_DRV"); endfunction

function void vqdmaif_h2c_master_driver::reportMainEvent(MainEventIdType_t event_id, string msg, uvm_verbosity verbosity);
  this.reportMainEvent_body(event_id.name, msg, verbosity);
endfunction

function void vqdmaif_h2c_master_driver::reportDebugInfo(string debug_id, string msg);
	this.reportDebugInfo_body(debug_id, msg);
endfunction

function int unsigned vqdmaif_h2c_master_driver::pickDataPendingCycle();
  return($urandom_range(this.cfg.start_data_pending_cycle, this.cfg.end_data_pending_cycle));
endfunction:pickDataPendingCycle

function void vqdmaif_h2c_master_driver::initInternalState(string call_info = "unspecified");
  `vmg_info("H2C_MST_DRIVER-INIT_INTERNAL_STATE", $sformatf("Initializing... call_info=[%s]", call_info), UVM_LOW)
  this.vif.cmd_vld  <= 0;
  this.vif.cmd_pl   <= $urandom;
  this.vif.data_rdy <= 0;
  this.vif.status_sideband_rdy <= 0;
  this.vif.interrupt_sideband_rdy <= 0;
  q_active.delete();
  q_pending_cmd_item.delete();
endfunction : initInternalState

function void vqdmaif_h2c_master_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
  `vmg_get_cfgdb_at_me(vqdmaif_h2c_master_cfg, "cfg", this.cfg)
  `vmg_get_cfgdb_at_me(T_VIF, "vif", this.vif)
endfunction


task vqdmaif_h2c_master_driver::run_phase(uvm_phase phase);
  fork
    super.run_phase(phase);
    begin
      this.vif.cmd_vld  <= 0;
      this.vif.cmd_pl   <= $urandom;
      this.vif.data_rdy <= FlipCoin(50);
      this.vif.status_sideband_rdy <= FlipCoin(50);
      this.vif.interrupt_sideband_rdy <= FlipCoin(50);
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
endtask:run_phase

task vqdmaif_h2c_master_driver::doOnReset();
  @(negedge this.vif.IF_clk.RESETn);
endtask : doOnReset

task vqdmaif_h2c_master_driver::doOnQdma();
  fork
    this.doOnCmd();
    this.doOnData();
  join
endtask : doOnQdma


task vqdmaif_h2c_master_driver::doOnMbdma();
  fork
    this.doOnCmd();
    this.doOnData();
    this.doOnStatusSideband();
    this.doOnStatusSidebandRdy();
    this.doOnInterruptSideband();
    this.doOnInterruptSidebandRdy();
  join  
endtask : doOnMbdma


task vqdmaif_h2c_master_driver::doOnCmd();
  fork
    forever begin
      T_SEQ_ITEM item;
      this.seq_item_port.get_next_item(item);
      this.q_pending_cmd_item.push_back(item);
      // no_dma: cmd-only, no data correlation needed -> skip q_active
      if(item.trans.getNoDma !== 1) this.q_active.push_back(item);
      this.seq_item_port.item_done(item);
    end
    forever begin
      T_SEQ_ITEM item;
      wait(this.q_pending_cmd_item.size > 0);
      item = this.q_pending_cmd_item.pop_front();
      for(int i=0; i<item.trans.q_sub.size; i++)begin
        this.driveTransfer_CMD(item, i);
      end
    end
  join
endtask:doOnCmd


task vqdmaif_h2c_master_driver::driveTransfer_CMD(T_SEQ_ITEM item, int sub_idx);
  this.vif.cmd_vld <= 0;
  this.waitCycle(item.cmd2cmd_delay_list[sub_idx]);
  this.vif.cmd_vld <= 1;
  this.vif.cmd_pl  <= item.trans.q_sub[sub_idx].cmd_pl;
  this.vif.cmd_sideband_pl <= item.trans.q_sub[sub_idx].cmd_sideband_pl;
  this.waitCycle(1);
  while(this.vif.cmd_rdy === 0) this.waitCycle(1);
  if(this.q_pending_cmd_item.size == 0 && item.trans.q_sub.size-1 == sub_idx)begin
    this.vif.cmd_vld <= 0;
    if(this.cfg.drv_hold_pl_at_non_vld == NO) this.vif.cmd_pl <= $urandom; //TODO:Consider big width
    this.waitCycle(1);
  end
endtask : driveTransfer_CMD



task vqdmaif_h2c_master_driver::doOnData();
  fork
    forever begin : UPDATE_ACTIVE
      T_SEQ_ITEM item;
      T_DATA_PL data_pl;
      T_DATA_SB_PL data_sideband_pl;
      int idx[$];
      this.vif.WaitTransferHs_DATA(data_pl);
      data_sideband_pl = this.vif.data_sideband_pl;
      if(this.cfg.dma_type == QDMA)       idx = this.q_active.find_first_index(x) with(x.trans.getQid === data_pl.qid);
      else if(this.cfg.dma_type == MBDMA) idx = this.q_active.find_first_index(x) with(x.trans.getQid === data_pl.qid && x.trans.isDataPlStored == 0);

      if(idx.size == 0) begin
        this.reportMainEvent(NOT_CORRESPONDING_DATA, $sformatf("Failed to get the corresponding active transaction for the incoming \"DATA\"(qid=0x%1h)", data_pl.qid), UVM_NONE);
      end
      else begin
        item = this.q_active[idx[0]];
        item.trans.storeData(data_pl);
        item.trans.storeDataSideband(data_sideband_pl); 
        if(!item.trans.wasDone) continue;
        this.seq_item_port.put_response(item);
        this.q_active.delete(idx[0]);
        this.reportMainEvent(
            COMPLETED_SEQ_ITEM, 
            $sformatf("%s=[%s] q_active/q_pending_cmd_item=%1d/%1d", 
              item.get_name, item.getInfo, this.q_active.size, this.q_pending_cmd_item.size
            ),
            cfg.verbosity
        );
      end
    end
    forever begin : DATA_RDY_CTRL
      wait(this.q_active.size > 0);
      this.vif.data_rdy <= 0;
      this.waitCycle(this.pickDataPendingCycle);
      this.vif.data_rdy <= 1;
      this.waitCycle(1);
    end
  join
endtask : doOnData


task vqdmaif_h2c_master_driver::doOnStatusSideband();
  forever begin 
    T_SEQ_ITEM item;
    T_STATUS_SB_PL status_sideband_pl;
    int idx[$];
    this.vif.WaitTransferHs_STATUS_SIDEBAND(status_sideband_pl);
    idx = this.q_active.find_first_index(x) with(x.trans.getQid == status_sideband_pl.qid && x.trans.hasStatusSideband === 0);
    if(idx.size == 0) begin
      this.reportMainEvent(NOT_CORRESPONDING_STATUS_SIDEBAND, $sformatf("Failed to get the corresponding active transaction for the incoming \"DATA\"(qid=0x%1h)", status_sideband_pl.qid), UVM_NONE);
    end
    else begin
      item = this.q_active[idx[0]];
      item.trans.storeStatusSideband(status_sideband_pl);
      if(item.trans.wasDone) begin
        this.seq_item_port.put_response(item);
        this.q_active.delete(idx[0]);
        this.reportMainEvent(
            COMPLETED_SEQ_ITEM, 
            $sformatf("%s=[%s] q_active/q_pending/q_pending_cmd_item/q_pending_data_item=%1d/%1d", 
              item.get_name, item.getInfo, this.q_active.size, this.q_pending_cmd_item.size
            ),
            cfg.verbosity
        );
      end
    end
  end
endtask : doOnStatusSideband


task vqdmaif_h2c_master_driver::doOnInterruptSideband();
  forever begin 
    T_SEQ_ITEM item;
    T_INTERRUPT_SB_PL interrupt_sideband_pl;
    int idx[$];
    this.vif.WaitTransferHs_INTERRUPT_SIDEBAND(interrupt_sideband_pl);
    idx = this.q_active.find_first_index(x) with(x.trans.getQid == interrupt_sideband_pl.qid && x.trans.hasInterruptSideband === 0);
    if(idx.size == 0) begin
      this.reportMainEvent(NOT_CORRESPONDING_INTERRUPT_SIDEBAND, $sformatf("Failed to get the corresponding active transaction for the incoming \"DATA\"(qid=0x%1h)", interrupt_sideband_pl.qid), UVM_NONE);
    end
    else begin
      item = this.q_active[idx[0]];
      item.trans.storeInterruptSideband(interrupt_sideband_pl);
      if(item.trans.wasDone) begin
        this.seq_item_port.put_response(item);
        this.q_active.delete(idx[0]);
        this.reportMainEvent(
            COMPLETED_SEQ_ITEM, 
            $sformatf("%s=[%s] q_active/q_pending/q_pending_cmd_item/q_pending_data_item=%1d/%1d", 
              item.get_name, item.getInfo, this.q_active.size, this.q_pending_cmd_item.size
            ),
            cfg.verbosity
        );
      end
    end
  end
endtask : doOnInterruptSideband


task vqdmaif_h2c_master_driver::doOnStatusSidebandRdy();
  forever begin
    this.vif.status_sideband_rdy <= 0;
    this.waitCycle(this.pickStatusSidebandPendingCycle);
    this.vif.status_sideband_rdy <= 1;
    this.waitCycle();
  end  
endtask : doOnStatusSidebandRdy


task vqdmaif_h2c_master_driver::doOnInterruptSidebandRdy();
  forever begin
    this.vif.interrupt_sideband_rdy <= 0;
    this.waitCycle(this.pickInterruptSidebandPendingCycle);
    this.vif.interrupt_sideband_rdy <= 1;
    this.waitCycle();
  end  
endtask : doOnInterruptSidebandRdy


function int unsigned vqdmaif_h2c_master_driver::pickStatusSidebandPendingCycle();
  return($urandom_range(this.cfg.start_status_pending_cycle, this.cfg.end_status_pending_cycle));
endfunction : pickStatusSidebandPendingCycle

function int unsigned vqdmaif_h2c_master_driver::pickInterruptSidebandPendingCycle();
  return($urandom_range(this.cfg.start_interrupt_pending_cycle, this.cfg.end_interrupt_pending_cycle));
endfunction : pickInterruptSidebandPendingCycle


task vqdmaif_h2c_master_driver::waitIdle(string call_info);
  this.reportMainEvent(WAIT_IDLE, $sformatf("waitIdle(call_info=%s) this.vif.cmd_vld=%1d", call_info, this.vif.cmd_vld), UVM_LOW);
  wait(this.vif.cmd_vld == 0);
  this.reportMainEvent(WAIT_IDLE, $sformatf("waitIdle(call_info=%s) this.q_pending_cmd_item.size=%1d", call_info, this.q_pending_cmd_item.size), UVM_LOW);
  wait(this.q_pending_cmd_item.size == 0);
  this.reportMainEvent(WAIT_IDLE, $sformatf("waitIdle(call_info=%s) this.q_active.size=%1d", call_info, this.q_active.size), UVM_LOW);
  wait(this.q_active.size == 0);
endtask : waitIdle



`endif //__VQDMAIF_H2C_MASTER_DRIVER_SVH__
