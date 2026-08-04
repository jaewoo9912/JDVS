`ifndef __VQDMAIF_H2C_MONITOR_SVH__
`define __VQDMAIF_H2C_MONITOR_SVH__

class vqdmaif_h2c_monitor extends vbfm_monitor;
  typedef virtual vqdmaif_h2c_if T_VIF;
  typedef vqdmaif_h2c_transaction T_TRANS;
  typedef vqdmaif_h2c_sub_transaction T_SUB_TRANS;
  typedef QdmaH2CCmd_t T_CMD_PL;
  typedef QdmaH2CData_t T_DATA_PL;
  typedef QdmaH2CCmdSideBand_t T_CMD_SB_PL;
  typedef QdmaH2CDataSideBand_t T_DATA_SB_PL;
  typedef QdmaH2CStatusSideBand_t T_STATUS_SB_PL;
  typedef QdmaH2CInterruptSideBand_t T_INTERRUPT_SB_PL;
  typedef vqdmaif_h2c_cfg T_CFG;
  typedef vqdmaif_h2c_coverage_collector T_COV_COLCTR;
  
  typedef enum int{
    NEW_TRANS,
    COMPLETED_TRANS,
    WAIT_IDLE,
    UNDEFINED_MAIN_EVENT
  }MainEventIdType_t;

  // --------------------------------------------
  T_CFG cfg;
  T_COV_COLCTR cov;
  T_VIF vif;
  T_TRANS sa_active[QdmaQId_t][$];
  T_TRANS q_active[$];

  // -------------------------------------------- Performance
  real cur_bandwidth;
  longint total_bytes = 0;
  real total_time = 0;
  int freq_in_mhz;
  real clk_period;
  int ot_cnt;
  vtrans_specific_performance_analyzer#(T_TRANS) perf_analyzer;

  uvm_severity sa_severity_protcl_err[QdmaifH2cProtclErrIdType_t];
  uvm_severity sa_severity_unsup_feature[QdmaifH2cUnsupFeatureIdType_t];

  uvm_analysis_port #(T_TRANS) ap_trans_cmd;
  uvm_analysis_port #(T_TRANS) ap_trans;
  uvm_analysis_port #(T_TRANS) ap_exception_trans;
  uvm_analysis_port #(vdata_container) ap_dcntnr;
  uvm_analysis_port #(real) ap_bandwidth;
  uvm_analysis_port #(vdata_container) ap_sub_dcntnr;
  vqdmaif_h2c_converter converter;
  vqdmaif_h2c_if_checker default_chkr;
  
  `uvm_component_utils(vqdmaif_h2c_monitor)
  function new(string name, uvm_component parent);
    super.new(name, parent);
    this.ap_trans_cmd = new("ap_trans_cmd", this);
    this.ap_trans = new("ap_trans", this);
    this.ap_exception_trans = new("ap_exception_trans", this);
    this.ap_dcntnr = new("ap_dcntnr", this);
    this.ap_bandwidth = new("ap_bandwidth", this);
    this.ap_sub_dcntnr = new("ap_sub_dcntnr", this);
  endfunction

  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void start_of_simulation_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task reset_phase(uvm_phase phase);
  extern virtual function void report_phase(uvm_phase phase);
  extern virtual task waitIdle(string call_info="unspecified");

  extern virtual function string decideReportFamilyId();
  extern virtual function void reportProtclErr(QdmaifH2cProtclErrIdType_t err_id, string msg);
  extern virtual function void reportMainEvent(MainEventIdType_t event_id, string msg, uvm_verbosity verbosity);
  extern virtual function void reportUnsupFeature(QdmaifH2cUnsupFeatureIdType_t feature_id, string msg);
  extern virtual function void reportDebugInfo(string debug_id, string msg);

  extern virtual task doOnReset();
  extern virtual task doOnCmd();
  extern virtual task doOnData();
  extern virtual task doOnStatusSideband();
  extern virtual task doOnInterruptSideband();
  extern virtual task measureBandwidth();
  extern virtual function void startTraceNewTrans(T_TRANS me);
  extern virtual function void deleteCompletedTrans(T_TRANS me);
  extern virtual function bit isOutstandQid(QdmaQId_t qid);
  extern virtual function T_TRANS findTrans_NotPktLvCmdRdy(QdmaQId_t qid);
  extern virtual function T_TRANS findTrans_DataCorrespond(QdmaQId_t qid);

  extern virtual protected function bit chkProtclAtCmd(T_TRANS trans, ref T_CMD_PL cmd_pl, string str_cmd_pl);
  extern virtual protected function bit chkProtclAtCmd_len(T_TRANS trans, ref T_CMD_PL cmd_pl, string str_cmd_pl);
  extern virtual protected function bit chkProtclAtCmd_sop(T_TRANS trans, ref T_CMD_PL cmd_pl, string str_cmd_pl);
  extern virtual protected function bit chkProtclAtCmd_no_dma(T_TRANS trans, ref T_CMD_PL cmd_pl, string str_cmd_pl);
  extern virtual protected function bit chkSupportnessAtCmd(ref T_CMD_PL cmd_pl, string str_cmd_pl);

  extern virtual protected function bit chkProtclAtData(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  extern virtual protected function bit chkProtclAtData_qid(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  extern virtual protected function bit chkProtclAtData_mty(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  extern virtual protected function bit chkProtclAtData_last(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  extern virtual protected function bit chkSupportnessAtData(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);

  extern virtual protected function bit chkProtclAtCmdSideband(T_TRANS trans, ref T_CMD_SB_PL cmd_pl, string str_cmd_pl);
  extern virtual protected function bit chkProtclAtDataSideband(T_TRANS trans, ref T_DATA_SB_PL data_pl, string str_data_pl);
  extern virtual protected function bit chkProtclAtStatusSideband(ref T_STATUS_SB_PL status_sideband_pl);
  extern virtual protected function bit chkProtclAtInterruptSideband(ref T_INTERRUPT_SB_PL interrupt_sideband_pl);

  extern virtual protected function void discoverSeverityPolicy_ProtclErr();
  extern virtual protected function void discoverSeverityPolicy_UnsupFeature();

  extern protected function vqdmaif_h2c_if_checker discoverDefaultChkr();
endclass:vqdmaif_h2c_monitor


function string vqdmaif_h2c_monitor::decideReportFamilyId(); return("H2C_MON"); endfunction

function void vqdmaif_h2c_monitor::reportProtclErr(QdmaifH2cProtclErrIdType_t err_id, string msg);
  this.reportProtclErr_body(err_id.name, msg, this.sa_severity_protcl_err[err_id]);
endfunction


function void vqdmaif_h2c_monitor::reportMainEvent(MainEventIdType_t event_id, string msg, uvm_verbosity verbosity);
  this.reportMainEvent_body(event_id.name, msg, verbosity);
endfunction


function void vqdmaif_h2c_monitor::reportUnsupFeature(QdmaifH2cUnsupFeatureIdType_t feature_id, string msg);
  this.reportUnsupFeature_body(feature_id.name, msg, this.sa_severity_unsup_feature[feature_id]);
endfunction


function void vqdmaif_h2c_monitor::reportDebugInfo(string debug_id, string msg);
  this.reportDebugInfo_body(debug_id, msg);
endfunction


function bit vqdmaif_h2c_monitor::isOutstandQid(QdmaQId_t qid); return(this.sa_active.exists(qid) == 1); endfunction


function vqdmaif_h2c_monitor::T_TRANS vqdmaif_h2c_monitor::findTrans_NotPktLvCmdRdy(QdmaQId_t qid);
  int idx[$];
  if(!this.isOutstandQid(qid)) return(null);
  idx = this.sa_active[qid].find_first_index(x) with(x.isPktLvCmdRdy==0);
  if(idx.size == 0) return(null);
  return(this.sa_active[qid][idx[0]]);
endfunction:findTrans_NotPktLvCmdRdy


function vqdmaif_h2c_monitor::T_TRANS vqdmaif_h2c_monitor::findTrans_DataCorrespond(QdmaQId_t qid);
  int idx[$];
  if(!this.isOutstandQid(qid)) return(null);

  if(this.cfg.dma_type == QDMA) idx = this.sa_active[qid].find_first_index(x) with(x.wasDone==0);
  else if(this.cfg.dma_type == MBDMA) idx = this.sa_active[qid].find_first_index(x) with(x.wasDone == 0 && x.isDataPlStored == 0);

  if(idx.size == 0) return(null);
  return(this.sa_active[qid][idx[0]]);
endfunction:findTrans_DataCorrespond


function void vqdmaif_h2c_monitor::startTraceNewTrans(T_TRANS me);
  this.sa_active[me.qid].push_back(me);
  this.q_active.push_back(me);
  this.perf_analyzer.doOnStarted(me);
  `vmg_info("H2C_MON-NEW_TRANS", $sformatf("trans=[%s] (#active=%1d) -- @%s", me.getInfo, this.q_active.size, this.get_full_name), cfg.verbosity)
endfunction:startTraceNewTrans


function void vqdmaif_h2c_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);
  `vmg_get_cfgdb_at_me(T_CFG, "cfg", this.cfg);
  `vmg_get_cfgdb_at_me(T_VIF, "vif", this.vif);
  this.converter = vqdmaif_h2c_converter::type_id::create("converter", this);
  if(this.cfg.enable_coverage) begin
    this.cov = T_COV_COLCTR::type_id::create("cov_colctr", this);
    `vmg_set_cfgdb_at_me(T_CFG, this.cov.getName, "cfg", this.cfg)
  end
  this.default_chkr = this.discoverDefaultChkr();
  this.perf_analyzer = new("perf_analyzer", this);
  this.perf_analyzer.prepare(
    .freq_in_mhz(this.vif.IF_clk.FREQ_MHZ),
    .max_data_width_in_bytes(this.cfg.DATA_SIZE),
    .data_unit(10**9/8), // Gb
    .time_unit(1s),
    .data_unit_str("Bytes"),
    .throuput_unit_str("Gbps")
  );
endfunction:build_phase


task vqdmaif_h2c_monitor::run_phase(uvm_phase phase);
  super.run_phase(phase);
  @(negedge this.vif.IF_clk.RESETn);
  forever begin
    fork
      begin
        fork
          begin : H2C
            fork
              this.doOnCmd();
              this.doOnData();
              this.doOnStatusSideband();
              this.doOnInterruptSideband();
              if(this.cfg.performance_measure) this.measureBandwidth();
            join
          end
          begin : RESET
            this.doOnReset();
          end
        join_any
        disable fork;
      end
    join
  end
endtask:run_phase

task vqdmaif_h2c_monitor::doOnReset();
  @(negedge this.vif.IF_clk.RESETn);
  foreach(sa_active[qid]) this.sa_active[qid].delete();
  q_active.delete();
  this.default_chkr.initialize();
endtask : doOnReset

task vqdmaif_h2c_monitor::doOnCmd();
  localparam string DEBUG_TAG = "H2C-NEW_CMD";
  int num_created_trans;

  forever begin:CAPTURE
    T_CMD_PL cmd_pl;
    T_CMD_SB_PL cmd_sideband_pl;
    T_SUB_TRANS sub_trans;
    T_TRANS trans;
    string str_cmd_pl;

    // CAPTURE			
    this.vif.WaitTransferHs_CMD(cmd_pl);
    cmd_sideband_pl = this.vif.cmd_sideband_pl;
    str_cmd_pl = $sformatf("cmd_pl=[%s]", MakeString_QdmaH2CCmd_t(cmd_pl));
    trans = this.findTrans_NotPktLvCmdRdy(cmd_pl.qid);

    // CHK
    void'(this.chkProtclAtCmd(trans, cmd_pl, str_cmd_pl));
    void'(this.chkSupportnessAtCmd(cmd_pl, str_cmd_pl));
    this.default_chkr.chkCmd(cmd_pl, cmd_sideband_pl);

    // UPDATE
    sub_trans = VQDMAIF_H2C_FACTORY.createSubTrans("sub_trans", this.cfg, cmd_pl);
    sub_trans.storeCmdSideband(cmd_sideband_pl);

    if(cmd_pl.no_dma === 1) begin : NO_DMA_PATH
      string trans_name = $sformatf("%s.trans#%1d", this.get_name, num_created_trans++);
      trans = VQDMAIF_H2C_FACTORY.createTrans(trans_name, sub_trans);
      this.reportDebugInfo(DEBUG_TAG, $sformatf("NO_DMA_TRANS -- trans=[%s] %s", trans.getInfo, str_cmd_pl));
      this.ap_exception_trans.write(trans);
      if(this.cfg.enable_coverage) this.cov.sampleH2CTrans(trans);
    end
    else begin
      if(trans == null)begin
          string trans_name = $sformatf("%s.trans#%1d", this.get_name, num_created_trans++);
          trans = VQDMAIF_H2C_FACTORY.createTrans(trans_name, sub_trans);
          this.startTraceNewTrans(trans);
          this.reportDebugInfo(DEBUG_TAG, $sformatf("NEW_TRANS -- trans=[%s] %s", trans.getInfo, str_cmd_pl));
      end
      else begin
          void'(this.chkProtclAtCmdSideband(trans, cmd_sideband_pl, str_cmd_pl));
          trans.addSubTrans(sub_trans);
          this.reportDebugInfo(DEBUG_TAG, $sformatf("ONGOING_TRANS -- trans=[%s] %s", trans.getInfo, str_cmd_pl));
      end
      if(trans.isPktLvCmdRdy)begin
          this.ap_trans_cmd.write(trans);
          ot_cnt += 1;
          if(this.cfg.enable_coverage) this.cov.sampleOt(ot_cnt);
          this.reportDebugInfo(DEBUG_TAG, $sformatf("PKT_LVL_CMD_RDY -- trans=[%s] %s", trans.getInfo, str_cmd_pl));
      end
    end
  end
endtask:doOnCmd


task vqdmaif_h2c_monitor::waitIdle(string call_info="unspecified");
  `vmg_info("H2C_MON-WAIT_IDLE", $sformatf("call_info=%s wait(q_active.size == 0) cur=%1d", call_info, this.q_active.size), UVM_LOW)
  wait(this.q_active.size == 0);
endtask:waitIdle


task vqdmaif_h2c_monitor::doOnData();
  localparam DEBUG_TAG = "H2C-NEW_DATA";
  forever begin
    T_TRANS trans;
    T_DATA_PL data_pl;
    T_DATA_SB_PL data_sideband_pl;
    string str_data_pl;

    // CAPTURE
    this.vif.WaitTransferHs_DATA(data_pl);

    str_data_pl = $sformatf("data_pl=[%s]", MakeString_QdmaH2CData_t(data_pl));
    trans = this.findTrans_DataCorrespond(data_pl.qid);
    this.reportDebugInfo(DEBUG_TAG, $sformatf("NEW_DATA -- %s", str_data_pl));

    // CHK
    void'(this.chkSupportnessAtData(trans, data_pl, str_data_pl));
    this.default_chkr.chkData(data_pl, data_sideband_pl);

    // UPDATE
    if(trans != null)begin
        trans.storeData(data_pl);
        data_sideband_pl = this.vif.data_sideband_pl;
        void'(this.chkProtclAtData(trans, data_pl, str_data_pl));
        void'(this.chkProtclAtDataSideband(trans, data_sideband_pl, str_data_pl));
        trans.storeDataSideband(data_sideband_pl);
         if(trans.wasDone) begin
        this.reportDebugInfo(DEBUG_TAG, $sformatf("LAST_DATA -- %s", str_data_pl));
           this.deleteCompletedTrans(trans);
         end
    end
  end
endtask:doOnData


task vqdmaif_h2c_monitor::doOnStatusSideband();
  localparam DEBUG_TAG = "H2C-STATUS-SIDEBAND";
  forever begin
    T_TRANS trans;
  T_STATUS_SB_PL status_sideband_pl;
  int idx[$];

  this.vif.WaitTransferHs_STATUS_SIDEBAND(status_sideband_pl);

  // CHK
  void'(this.chkProtclAtStatusSideband(status_sideband_pl));

  // UPDATE
  if(this.sa_active.exists(status_sideband_pl.qid)) begin
    idx = this.sa_active[status_sideband_pl.qid].find_first_index(x) with (x.hasStatusSideband === 0);
    trans = this.sa_active[status_sideband_pl.qid][idx[0]];
    trans.storeStatusSideband(status_sideband_pl);
    if(trans.wasDone) begin
    this.deleteCompletedTrans(trans);
    end
  end
  end	
endtask : doOnStatusSideband


task vqdmaif_h2c_monitor::doOnInterruptSideband();
  localparam DEBUG_TAG = "H2C-INTERRUPT-SIDEBAND";
  forever begin
    T_TRANS trans;
  T_INTERRUPT_SB_PL interrupt_sideband_pl;
  int idx[$];

  this.vif.WaitTransferHs_INTERRUPT_SIDEBAND(interrupt_sideband_pl);

  // CHK
  void'(this.chkProtclAtInterruptSideband(interrupt_sideband_pl));

  // UPDATE
  if(this.sa_active.exists(interrupt_sideband_pl.qid)) begin
    idx = this.sa_active[interrupt_sideband_pl.qid].find_first_index(x) with (x.hasInterruptSideband === 0);
    trans = this.sa_active[interrupt_sideband_pl.qid][idx[0]];
    trans.storeInterruptSideband(interrupt_sideband_pl);
    if(trans.wasDone) begin
    this.deleteCompletedTrans(trans);
    end
  end
  end	
endtask : doOnInterruptSideband


task vqdmaif_h2c_monitor::measureBandwidth();
  Timestamp_t prev_ts = 0;  
  T_DATA_PL data_pl;
  int valid_bytes;

  this.freq_in_mhz = this.vif.IF_clk.FREQ_MHZ;
  this.clk_period = 1000.0 / this.freq_in_mhz;

  this.vif.WaitTransferHs_DATA(data_pl);
  prev_ts = this.vif.IF_clk.TIMESTAMP;
  valid_bytes = this.cfg.DATA_SIZE - data_pl.mty;
  this.total_bytes += valid_bytes;
  `vmg_info("MEASURE_BANDWIDTH", $sformatf("First data observed, starting measurement (prev_ts=%1d)", prev_ts), cfg.verbosity)

  forever begin
    Timestamp_t cur_ts;
    real elapsed_time;

    this.vif.WaitTransferHs_DATA(data_pl);
    cur_ts = this.vif.IF_clk.TIMESTAMP;
    valid_bytes = this.cfg.DATA_SIZE - data_pl.mty;
    elapsed_time = (cur_ts - prev_ts) * clk_period;
    this.total_bytes += valid_bytes;
    this.total_time += elapsed_time;
    this.cur_bandwidth = real'(this.total_bytes * 8) / this.total_time;
    `vmg_info("MEASURE_BANDWIDTH", $sformatf("prev/cur_ts=%1d/%1d valid/total_bytes=%1d/%1d elapsed/total_time=%.1f/%.1f(ns) cur_bandwidth=%.1f Gbps", prev_ts, cur_ts, valid_bytes, this.total_bytes, elapsed_time, this.total_time, this.cur_bandwidth), cfg.verbosity)
    this.ap_bandwidth.write(this.cur_bandwidth);
     
    prev_ts = cur_ts;
  end
endtask : measureBandwidth


function void vqdmaif_h2c_monitor::deleteCompletedTrans(T_TRANS me);
  int idx[$] = this.q_active.find_first_index(x) with (x === me);
  vdata_container dcntnr;
  this.q_active.delete(idx[0]);
  void'(this.sa_active[me.qid].pop_front);
  if(this.sa_active[me.qid].size == 0) this.sa_active.delete(me.qid);
  `vmg_info("H2C_MON-COMPLETED_TRANS", $sformatf("trans=[%s] (#active=%1d) -- @%s", me.getInfo, this.q_active.size, this.get_full_name), cfg.verbosity)
  if(this.cfg.enable_coverage) this.cov.sampleH2CTrans(me);
  if(this.converter.convertToGatheredDcntr(me, me.dcntnr)) begin
    foreach(me.q_sub[i]) begin
      if(this.converter.convertH2cNotGatherToDcntr(me, i, me.dcntnr, dcntnr)) begin 
        me.q_sub[i].dcntnr = dcntnr;
        this.ap_sub_dcntnr.write(dcntnr);
      end
    end 
  end
  this.ap_trans.write(me);
  this.ap_dcntnr.write(me.dcntnr);
  this.perf_analyzer.doOnCompleted(me);
  ot_cnt-=1;
endfunction:deleteCompletedTrans


function bit vqdmaif_h2c_monitor::chkProtclAtCmd(T_TRANS trans, ref T_CMD_PL cmd_pl, string str_cmd_pl);
  bit result=1;

  if(!this.chkProtclAtCmd_sop(trans, cmd_pl, str_cmd_pl))     result = 0;
  if(!this.chkProtclAtCmd_len(trans, cmd_pl, str_cmd_pl))     result = 0;
  if(!this.chkProtclAtCmd_no_dma(trans, cmd_pl, str_cmd_pl))  result = 0;
  return(result);
endfunction:chkProtclAtCmd


function bit vqdmaif_h2c_monitor::chkProtclAtCmd_sop(T_TRANS trans, ref T_CMD_PL cmd_pl, string str_cmd_pl);
  bit result=1;
  QdmaifH2cProtclErrIdType_t vio_type = H2C_000_CMD_SOP;

  if(trans == null)begin
    if(cmd_pl.sop === 0)begin
      result = 0;
      this.reportProtclErr(
        vio_type,
        $sformatf("This is the first sub-trans for QID=%1d(0x%1h), but \"sop\" is ZERO.\n\t\t* %s\n",
          cmd_pl.qid, cmd_pl.qid,
          str_cmd_pl
      ));
    end
  end
  else begin
    if(cmd_pl.sop === 1)begin
      result = 0;
      trans.show($sformatf("[%s] ", vio_type.name));
      this.reportProtclErr(
        vio_type,
        $sformatf("This is not a first sub-trans for QID=%1d(0x%1h), but \"sop\" is ONE.\n\t\t* %s\n",
          cmd_pl.qid, cmd_pl.qid,
          str_cmd_pl
      ));
    end
  end
  if(result == 1)begin
    this.reportDebugInfo(
      $sformatf("CHK_PROTCL.%s", vio_type.name),
      $sformatf("PASS -- sop/eop=%1d/%1d\n\t\t* %s\n",
        cmd_pl.sop,
        cmd_pl.eop,
        str_cmd_pl
    ));
  end
  return(result);
endfunction:chkProtclAtCmd_sop

function bit vqdmaif_h2c_monitor::chkProtclAtCmd_len(T_TRANS trans, ref T_CMD_PL cmd_pl, string str_cmd_pl);
  bit result=1;
  QdmaifH2cProtclErrIdType_t vio_type = H2C_001_CMD_LEN;

  if(cmd_pl.len === 0)begin
    result = 0;
    this.reportProtclErr(
      vio_type,
      $sformatf("\"len\" MUST NOT be ZERO.\n\t\t* %s\n",
        str_cmd_pl
    ));
  end
  else begin
    this.reportDebugInfo(
      $sformatf("CHK_PROTCL.%s", vio_type.name),
      $sformatf("PASS -- len !== 0\n\t\t* %s\n",
        str_cmd_pl
    ));
  end
  return(result);
endfunction:chkProtclAtCmd_len


function bit vqdmaif_h2c_monitor::chkProtclAtCmd_no_dma(T_TRANS trans, ref T_CMD_PL cmd_pl, string str_cmd_pl);
  bit result = 1;
  QdmaifH2cProtclErrIdType_t vio_type = H2C_002_CMD_NO_DMA_EOP;

  if(cmd_pl.no_dma === 1) begin
    if(cmd_pl.eop !== 1) begin
      result = 0;
      this.reportProtclErr(
        vio_type,
        $sformatf("\"no_dma\" cmd MUST have eop = 1 \n\t\t* %s\n", str_cmd_pl)
      );
    end
  end
  return(result);
endfunction : chkProtclAtCmd_no_dma


function bit vqdmaif_h2c_monitor::chkSupportnessAtCmd(ref T_CMD_PL cmd_pl, string str_cmd_pl);
  bit result=1;

  if(cmd_pl.error !== 0)begin
    result = 0;
    this.reportUnsupFeature(H2C_UNSUP_CMD_ERROR, str_cmd_pl);
  end
  if(cmd_pl.mrkr_req !== 0)begin
    result = 0;
    this.reportUnsupFeature(H2C_UNSUP_CMD_MRKR_REQ, str_cmd_pl);
  end
  if(cmd_pl.sdi !== 0)begin
    result = 0;
    this.reportUnsupFeature(H2C_UNSUP_CMD_SDI, str_cmd_pl);
  end
  return(result);
endfunction:chkSupportnessAtCmd



function bit vqdmaif_h2c_monitor::chkProtclAtData(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  bit result=1;

  if(!this.chkProtclAtData_qid(trans, data_pl, str_data_pl))begin
    `vmg_warning(this.get_name, $sformatf("chkProtclAtData -- Skipping further checks due to the cmd/data pair mapping failure, result may be invalid."));
    return(0);
  end
  if(!this.chkProtclAtData_last(trans, data_pl, str_data_pl)) result = 0;
  if(!this.chkProtclAtData_mty(trans, data_pl, str_data_pl)) result = 0; 
  return(result);
endfunction:chkProtclAtData



function bit vqdmaif_h2c_monitor::chkProtclAtData_qid(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  bit result=1;
  QdmaifH2cProtclErrIdType_t vio_type = H2C_100_DATA_QID;
  QdmaQId_t actual_qid = data_pl.qid;

  if(trans == null)begin
    result = 0;
    this.reportProtclErr(
      vio_type,
      $sformatf("There's no outstanding transactions with QID=%1d(0x%1h)\n\t\t* %s\n",
        actual_qid, actual_qid,
        str_data_pl
    ));				
  end
  else begin
    this.reportDebugInfo(
      $sformatf("CHK_PROTCL.%s", vio_type.name),
      $sformatf("PASS -- Outstanding trans found with QID=%1d(0x%1h)\n\t\t* %s\n\t\t* trans=[%s]\n",
        actual_qid, actual_qid,
        str_data_pl,
        trans.getInfo
    ));
  end
  return(result);
endfunction:chkProtclAtData_qid


function bit vqdmaif_h2c_monitor::chkProtclAtData_mty(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  bit result=1;
  QdmaifH2cProtclErrIdType_t vio_type = H2C_102_DATA_MTY;
  QdmaMty_t actual_mty = data_pl.mty;
  QdmaMty_t ref_mty;

  if(trans.isLastDataPlStored)  ref_mty = (this.cfg.DATA_SIZE - (trans.getTotalLen % this.cfg.DATA_SIZE)) % this.cfg.DATA_SIZE;
  else                          ref_mty = 0;

  if(trans.pkt_lv_cmd_rdy == 0) begin
      if(actual_mty != 0)begin
        result = 0;
        this.reportProtclErr(
          vio_type,
          $sformatf("pkt_lv_cmd is not ready. actual/expected_mty=%1d(0x%1h)/0(0)\n\t\t* %s\n\t\t* Interface data signal width: %1d bytes\n",
            actual_mty, actual_mty,
            str_data_pl,
            this.cfg.DATA_SIZE
        ));				
      end
      else begin
        this.reportDebugInfo(
          $sformatf("CHK_PROTCL.%s", vio_type.name),
          $sformatf("PASS -- actual/expected_mty=%1d(0x%1h)/0(0)\n\t\t* %s\n\t\t* Interface data signal width: %1d bytes\n",
            actual_mty, actual_mty,
            str_data_pl,
            this.cfg.DATA_SIZE
        ));
      end
  end
  else begin
      if(actual_mty !== ref_mty)begin
        result = 0;
        this.reportProtclErr(
          vio_type,
          $sformatf("pkt_lv_cmd is ready. actual/expected_mty=%1d(0x%1h)/%1d(0x%1h)\n\t\t* %s\n\t\t* Interface data signal width: %1d bytes\n",
            actual_mty, actual_mty,
            ref_mty, ref_mty,
            str_data_pl,
            this.cfg.DATA_SIZE
        ));				
      end
      else begin
        this.reportDebugInfo(
          $sformatf("CHK_PROTCL.%s", vio_type.name),
          $sformatf("PASS -- actual/expected_mty=%1d(0x%1h)/%1d(0x%1h)\n\t\t* %s\n\t\t* Interface data signal width: %1d bytes\n",
            actual_mty, actual_mty,
            ref_mty, ref_mty,
            str_data_pl,
            this.cfg.DATA_SIZE
        ));
      end
    end
  return(result);
endfunction:chkProtclAtData_mty



function bit vqdmaif_h2c_monitor::chkProtclAtData_last(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  bit result=1;
  QdmaifH2cProtclErrIdType_t vio_type = H2C_101_DATA_LAST;
  logic actual_last = data_pl.last;
  logic ref_last = trans.isLastDataPlStored ? 1 : 0;

  if(trans.pkt_lv_cmd_rdy == 0) begin
      if(actual_last != 0)begin
        result = 0;
        this.reportProtclErr(
          vio_type,
          $sformatf("actual/expected_last=%1d/0\n\t\t* %s\n\t\t* Interface data signal width: %1d bytes\n",
            actual_last,
            str_data_pl,
            this.cfg.DATA_SIZE
        ));				
      end
      else begin
        this.reportDebugInfo(
          $sformatf("CHK_PROTCL.%s", vio_type.name),
          $sformatf("PASS -- actual/expected_last=%1d/0\n\t\t* %s\n\t\t* Interface data signal width: %1d bytes\n",
            actual_last,
            str_data_pl,
            this.cfg.DATA_SIZE
        ));
      end
  end
  else begin
      if(actual_last !== ref_last)begin
        result = 0;
        this.reportProtclErr(
          vio_type,
          $sformatf("actual/expected_last=%1d/%1d\n\t\t* %s\n\t\t* Interface data signal width: %1d bytes\n",
            actual_last,
            ref_last,
            str_data_pl,
            this.cfg.DATA_SIZE
        ));				
      end
      else begin
        this.reportDebugInfo(
          $sformatf("CHK_PROTCL.%s", vio_type.name),
          $sformatf("PASS -- actual/expected_last=%1d/%1d\n\t\t* %s\n\t\t* Interface data signal width: %1d bytes\n",
            actual_last,
            ref_last,
            str_data_pl,
            this.cfg.DATA_SIZE
        ));
      end
  end

  return(result);
endfunction:chkProtclAtData_last


function bit vqdmaif_h2c_monitor::chkSupportnessAtData(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  bit result=1;

  if(data_pl.err !== 0)begin
    result = 0;
    this.reportUnsupFeature(H2C_UNSUP_DATA_ERR, str_data_pl);
  end
  if(data_pl.crc !== 0)begin
    result = 0;
    this.reportUnsupFeature(H2C_UNSUP_DATA_CRC, str_data_pl);
  end
  if(data_pl.mdata !== 0)begin
    result = 0;
    this.reportUnsupFeature(H2C_UNSUP_DATA_MDATA, str_data_pl);
  end
  if(data_pl.zero_byte !== 0)begin
    result = 0;
    this.reportUnsupFeature(H2C_UNSUP_DATA_ZERO_BYTE, str_data_pl);
  end
  return(result);
endfunction:chkSupportnessAtData

/**
 * @param trans - 
 * @param cmd_pl - 
 * @param str_cmd_pl - 
 * @return 
 */
function bit vqdmaif_h2c_monitor::chkProtclAtCmdSideband(T_TRANS trans, ref T_CMD_SB_PL cmd_pl, string str_cmd_pl);
  bit result=1;
  if(trans.q_sub.size() && (trans.q_sub[$].cmd_sideband_pl.fid != cmd_pl.fid)) begin
    this.reportProtclErr(
    H2C_400_CMD_SIDEBAND_CORRESPOND,
    $sformatf("fid changed during cmd trans: prev_fid=%0x, curr_fid=%0x",
    trans.q_sub[$].cmd_sideband_pl.fid, cmd_pl.fid
  ));				
  end
  return result;
endfunction : chkProtclAtCmdSideband

function bit vqdmaif_h2c_monitor::chkProtclAtDataSideband(T_TRANS trans, ref T_DATA_SB_PL data_pl, string str_data_pl);
  bit result=1;
  if(trans.q_data_sideband_pl.size() && (trans.q_data_sideband_pl[$].fid != data_pl.fid)) begin
    this.reportProtclErr(
    H2C_500_DATA_SIDEBAND_CORRESPOND,
    $sformatf("fid changed during data trans: prev_fid=%0x, curr_fid=%0x",
    trans.q_data_sideband_pl[$].fid, data_pl.fid
  ));				
  end
  return result;
endfunction : chkProtclAtDataSideband

function bit vqdmaif_h2c_monitor::chkProtclAtStatusSideband(ref T_STATUS_SB_PL status_sideband_pl);
  bit result=1;
  QdmaifH2cProtclErrIdType_t err_id = H2C_200_STATUS_SIDEBAND_CORRESPOND;
  QdmaQId_t actual_qid = status_sideband_pl.qid;

  if(!this.sa_active.exists(actual_qid))begin
    result = 0;
    this.reportProtclErr(
      err_id,
      $sformatf("Cannot find the oustanding transaction for qid=%1d(0x%1h)\n\t\t* \n",
        actual_qid, actual_qid
    ));				
  end
  else begin
    this.reportDebugInfo(
      $sformatf("CHK_PROTCL.%s", err_id.name),
      $sformatf("PASS -- actual_qid=%1d(0x%1h)\n\t\t* \n",
        actual_qid, actual_qid
    ));
  end
  return(result);
endfunction:chkProtclAtStatusSideband


function bit vqdmaif_h2c_monitor::chkProtclAtInterruptSideband(ref T_INTERRUPT_SB_PL interrupt_sideband_pl);
  bit result=1;
  QdmaifH2cProtclErrIdType_t err_id = H2C_300_INTERRUPT_SIDEBAND_CORRESPOND;
  QdmaQId_t actual_qid = interrupt_sideband_pl.qid;

  if(!this.sa_active.exists(actual_qid))begin
    result = 0;
    this.reportProtclErr(
      err_id,
      $sformatf("Cannot find the oustanding transaction for qid=%1d(0x%1h)\n\t\t* \n",
        actual_qid, actual_qid
    ));				
  end
  else begin
    this.reportDebugInfo(
      $sformatf("CHK_PROTCL.%s", err_id.name),
      $sformatf("PASS -- actual_qid=%1d(0x%1h)\n\t\t* \n",
        actual_qid, actual_qid
    ));
  end
  return(result);
endfunction:chkProtclAtInterruptSideband


function void vqdmaif_h2c_monitor::discoverSeverityPolicy_ProtclErr();
  uvm_severity default_severity=UVM_ERROR;

  `vmg_get_cfgdb_at_me_can_be_failed(uvm_severity, MakeCfgdbFieldName_Severity("default"), default_severity)
  for(QdmaifH2cProtclErrIdType_t cur_type=cur_type.first(); cur_type < UNDEFINED_QDMAIF_H2C_PROTCL_ERR_ID_TYPE; cur_type = cur_type.next()) begin
    this.sa_severity_protcl_err[cur_type] = default_severity;
    `vmg_get_cfgdb_at_me_can_be_failed(uvm_severity, MakeCfgdbFieldName_Severity(cur_type.name), this.sa_severity_protcl_err[cur_type])
  end
endfunction:discoverSeverityPolicy_ProtclErr


function void vqdmaif_h2c_monitor::discoverSeverityPolicy_UnsupFeature();
  uvm_severity default_severity=UVM_FATAL;

  `vmg_get_cfgdb_at_me_can_be_failed(uvm_severity, MakeCfgdbFieldName_Severity("default"), default_severity)
  for(QdmaifH2cUnsupFeatureIdType_t cur_type=cur_type.first(); cur_type < UNDEFINED_QDMAIF_H2C_UNSUP_FEATURE_ID_TYPE; cur_type = cur_type.next()) begin
    this.sa_severity_unsup_feature[cur_type] = default_severity;
    `vmg_get_cfgdb_at_me_can_be_failed(uvm_severity, MakeCfgdbFieldName_Severity(cur_type.name), this.sa_severity_unsup_feature[cur_type])
  end
endfunction:discoverSeverityPolicy_UnsupFeature


function void vqdmaif_h2c_monitor::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);				
  this.discoverSeverityPolicy_ProtclErr();
  this.discoverSeverityPolicy_UnsupFeature();
endfunction:start_of_simulation_phase


function void vqdmaif_h2c_monitor::report_phase(uvm_phase phase);
  if(this.cfg.performance_measure) begin
    `vmg_info(this.getName, $sformatf("---------------------------------------------------------------------"), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf(" PERFORMANCE_REPORT(H2C)"), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf("---------------------------------------------------------------------"), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf("  - Interface frequency           : %1d Mhz", this.freq_in_mhz), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf("  - Monitored time interval       : %.1f ns", this.total_time), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf("  - Total amount of data transfer : %s", MakeString_MemSize(this.total_bytes)), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf("  - Average B/W                   : %.1f Gbps", this.cur_bandwidth), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf("---------------------------------------------------------------------"), UVM_MEDIUM)
  end
endfunction : report_phase


task vqdmaif_h2c_monitor::reset_phase(uvm_phase phase);
  super.reset_phase(phase);
  this.q_active.delete();
  foreach(this.sa_active[qid]) this.sa_active[qid].delete();
  this.sa_active.delete();
endtask


function vqdmaif_h2c_if_checker vqdmaif_h2c_monitor::discoverDefaultChkr();
  vqdmaif_h2c_if_checker discovered;

  `vmg_get_cfgdb_at_me_can_be_failed(vqdmaif_h2c_if_checker, "default_chkr", discovered)
  if(discovered != null)begin
    `vmg_info(this.get_full_name, $sformatf("Found an injected \"default_chkr\" handle, will use the customized one."), UVM_LOW)
  end
  else begin
    discovered = vqdmaif_h2c_default_checker::type_id::create("default_chkr");
  end
  discovered.setVerbosity(this.cfg.verbosity);
  return(discovered);
endfunction


`endif //__VQDMAIF_H2C_MONITOR_SVH__
