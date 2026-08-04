`ifndef __VQDMAIF_C2H_MONITOR_SVH__
`define __VQDMAIF_C2H_MONITOR_SVH__

/*

   TODO
    * Per port notification


*/

class vqdmaif_c2h_monitor extends vbfm_monitor;

  typedef virtual vqdmaif_c2h_if T_VIF;
  typedef vqdmaif_c2h_transaction T_TRANS;
  typedef QdmaC2HCmd_t T_CMD_PL;
  typedef QdmaC2HData_t T_DATA_PL;
  typedef QdmaC2HStatus_t T_STATUS_PL;
  typedef QdmaC2HCmdSideBand_t T_CMD_SB_PL;
  typedef QdmaC2HDataSideBand_t T_DATA_SB_PL;
  typedef QdmaC2HStatusSideBand_t T_STATUS_SB_PL;
  typedef QdmaC2HInterruptSideBand_t T_INTERRUPT_SB_PL;
  typedef vqdmaif_c2h_cfg T_CFG;
  typedef vqdmaif_c2h_coverage_collector T_COV_COLCTR;


  typedef enum int{
    NEW_TRANS,
    COMPLETED_TRANS,
    WAIT_IDLE,
    UNDEFINED_MAIN_EVENT
  }MainEventIdType_t;

  
  // -----------------------------------------------------------
  T_COV_COLCTR cov;
  T_CFG cfg;
  T_VIF vif;
  T_CMD_PL q_cmd[$];
  T_CMD_SB_PL q_cmd_sideband[$];
  T_TRANS  q_fwd_to_assemble_cmd[$];
  T_TRANS  sa_active[QdmaQId_t][$];
  T_TRANS  q_active[$];

  // -------------------------------------------- Performance
  real cur_bandwidth;
  longint total_bytes = 0;
  real total_time = 0;
  int freq_in_mhz;
  real clk_period;
  int ot_cnt;
  vtrans_specific_performance_analyzer#(T_TRANS) perf_analyzer;

  uvm_severity sa_severity_protcl_err[QdmaifC2hProtclErrIdType_t];
  uvm_severity sa_severity_unsup_feature[QdmaifC2hUnsupFeatureIdType_t];

  vqdmaif_c2h_converter converter;
  vqdmaif_c2h_if_checker default_chkr;
  uvm_analysis_port #(T_TRANS) ap_assembled_fwd_transfer;
  uvm_analysis_port #(T_TRANS) ap_trans;
  uvm_analysis_port #(vdata_container) ap_dcntnr;
  uvm_analysis_port #(real) ap_bandwidth;

  `uvm_component_utils(vqdmaif_c2h_monitor)
  function new(string name, uvm_component parent);
    super.new(name, parent);
    this.ap_assembled_fwd_transfer = new("ap_assembled_fwd_transfer", this);
    this.ap_trans = new("ap_trans", this);
    this.ap_dcntnr = new("ap_dcntnr", this);
	  this.ap_bandwidth = new("ap_bandwidth", this);
  endfunction

  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void start_of_simulation_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task reset_phase(uvm_phase phase);
  extern virtual function void report_phase(uvm_phase phase);

  extern virtual function string getInfo();
  extern virtual function StringQ_t getInfoList();
  extern virtual task waitIdle(string call_info="unspecified");

  extern virtual function string decideReportFamilyId();
  extern virtual function void reportProtclErr(QdmaifC2hProtclErrIdType_t err_id, string msg);
  extern virtual function void reportMainEvent(MainEventIdType_t event_id, string msg, uvm_verbosity verbosity);
  extern virtual function void reportUnsupFeature(QdmaifC2hUnsupFeatureIdType_t feature_id, string msg);
  extern virtual function void reportDebugInfo(string debug_id, string msg);

  extern virtual task doOnReset();
  extern virtual task doOnCmd();
  extern virtual task doOnData();
  extern virtual task doOnAssembleCmdDataTransfer();
  extern virtual task doOnStatus();
  extern virtual task doOnInterruptSideband();
  extern virtual task measureBandwidth();
  extern virtual function void startTraceNewTrans(T_TRANS me);
  extern virtual function void deleteCompletedTrans(T_TRANS me);

  extern virtual protected function bit chkProtclAtData(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  extern virtual protected function bit chkProtclAtData_qid(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  extern virtual protected function bit chkProtclAtData_last(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  extern virtual protected function bit chkProtclAtData_mty(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  extern virtual protected function bit chkSupportnessAtData(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);

  extern virtual protected function bit chkProtclAtAssembleCmdData(T_TRANS trans, ref T_CMD_PL cmd_pl, string str_cmd_pl);
  extern virtual protected function bit chkSupportnessAtAssembleCmdData(T_TRANS trans, ref T_CMD_PL cmd_pl, string str_cmd_pl);

  extern virtual protected function bit chkProtclAtStatus(ref T_STATUS_PL status_pl, string str_status_pl);
  extern virtual protected function bit chkSupportnessAtStatus(ref T_STATUS_PL status_pl, string str_status_pl);

  extern virtual protected function bit chkProtclAtDataSideband(T_TRANS trans, ref T_DATA_SB_PL data_pl, string str_data_pl);
  extern virtual protected function bit chkProtclAtInterruptSideband(ref T_INTERRUPT_SB_PL interrupt_sideband_pl);

  extern virtual protected function void discoverSeverityPolicy_ProtclErr();
  extern virtual protected function void discoverSeverityPolicy_UnsupFeature();

  extern virtual protected function vqdmaif_c2h_if_checker discoverDefaultChkr();
endclass:vqdmaif_c2h_monitor


function string vqdmaif_c2h_monitor::decideReportFamilyId(); return("C2H_MON"); endfunction

function void vqdmaif_c2h_monitor::reportProtclErr(QdmaifC2hProtclErrIdType_t err_id, string msg);
  this.reportProtclErr_body(err_id.name, msg, this.sa_severity_protcl_err[err_id]);
endfunction


function void vqdmaif_c2h_monitor::reportMainEvent(MainEventIdType_t event_id, string msg, uvm_verbosity verbosity);
  this.reportMainEvent_body(event_id.name, msg, verbosity);
endfunction


function void vqdmaif_c2h_monitor::reportUnsupFeature(QdmaifC2hUnsupFeatureIdType_t feature_id, string msg);
  this.reportUnsupFeature_body(feature_id.name, msg, this.sa_severity_unsup_feature[feature_id]);
endfunction


function void vqdmaif_c2h_monitor::reportDebugInfo(string debug_id, string msg);
  this.reportDebugInfo_body(debug_id, msg);
endfunction


function string vqdmaif_c2h_monitor::getInfo();
  return($sformatf("cfg=[%s] #active=%1d", this.cfg.getInfo, this.q_active.size));
endfunction:getInfo


function void vqdmaif_c2h_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);
  `vmg_get_cfgdb_at_me(T_CFG, "cfg", this.cfg)
  `vmg_get_cfgdb_at_me(T_VIF, "vif", this.vif);
  if(this.cfg.enable_coverage) begin
    this.cov = T_COV_COLCTR::type_id::create("cov_colctr", this);
    `vmg_set_cfgdb_at_me(T_CFG, this.cov.getName, "cfg", this.cfg)
  end
  this.converter = vqdmaif_c2h_converter::type_id::create("converter", this);
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


task vqdmaif_c2h_monitor::run_phase(uvm_phase phase);
  super.run_phase(phase);
  @(negedge this.clk_vif.RESETn);
  forever begin
    fork
      begin
        fork
          begin
            fork
              this.doOnCmd();
              this.doOnData();
              this.doOnAssembleCmdDataTransfer();
              this.doOnStatus();
              this.doOnInterruptSideband();
            if(this.cfg.performance_measure) this.measureBandwidth();
            join
          end
          begin
            this.doOnReset();
          end
          join_any
        disable fork;
      end
    join
  end
endtask:run_phase

task vqdmaif_c2h_monitor::doOnReset();
  @(negedge this.clk_vif.RESETn);
  q_cmd.delete();
  q_cmd_sideband.delete();
  q_fwd_to_assemble_cmd.delete();
  q_active.delete();
  foreach(sa_active[qid]) sa_active[qid].delete();
  this.default_chkr.initialize();
endtask : doOnReset

task vqdmaif_c2h_monitor::doOnCmd();
  forever begin:CAPTURE
    T_CMD_PL cmd_pl;
    T_CMD_SB_PL cmd_sideband_pl;

    // CAPTURE			
    this.vif.WaitTransferHs_CMD(cmd_pl);
    cmd_sideband_pl = this.vif.cmd_sideband_pl;
    this.q_cmd.push_back(cmd_pl);
    this.q_cmd_sideband.push_back(cmd_sideband_pl);

    // CHK
    this.default_chkr.chkCmd(cmd_pl, cmd_sideband_pl);

    // UPDATE
    this.reportDebugInfo("CMD", $sformatf("cmd_pl=[%s] q_cmd.size=%1d", MakeString_QdmaC2HCmd_t(cmd_pl), this.q_cmd.size));
  end
endtask:doOnCmd


task vqdmaif_c2h_monitor::doOnData();
  localparam DEBUG_ID = "DATA";
  T_TRANS trans_storing_data;
  int num_created_trans;

  forever begin
    T_DATA_PL data_pl;
    T_DATA_SB_PL data_sideband_pl;
  string str_data_pl;

  // CAPTURE
  this.vif.WaitTransferHs_DATA(data_pl);
  str_data_pl = $sformatf("data_pl=[%s]", MakeString_QdmaC2HData_t(data_pl));
  data_sideband_pl = this.vif.data_sideband_pl;
    
  // UPDATE
  if(trans_storing_data == null)begin
      string inst_name = $sformatf("%s.trans#%1d", this.get_name, num_created_trans++);
      trans_storing_data = VQDMAIF_C2H_FACTORY.createTrans_ByDataPl(inst_name, this.cfg, data_pl);
      this.startTraceNewTrans(trans_storing_data);
      this.reportDebugInfo(DEBUG_ID, $sformatf("NEW_TRANS -- trans=[%s] %s", trans_storing_data.getInfo, str_data_pl));
  end
  else begin
      trans_storing_data.storeData(data_pl);
      this.reportDebugInfo(DEBUG_ID, $sformatf("ONGOING_TRANS -- trans=[%s] %s", trans_storing_data.getInfo, str_data_pl));
  end

  void'(this.chkProtclAtDataSideband(trans_storing_data, data_sideband_pl, str_data_pl));
  trans_storing_data.storeDataSideband(data_sideband_pl);

  // CHK
  void'(this.chkProtclAtData(trans_storing_data, data_pl, str_data_pl));
  void'(this.chkSupportnessAtData(trans_storing_data, data_pl, str_data_pl));
  this.default_chkr.chkData(data_pl, data_sideband_pl);

  if(data_pl.last)begin
    this.q_fwd_to_assemble_cmd.push_back(trans_storing_data); 
      this.reportDebugInfo(DEBUG_ID, $sformatf("LAST_DATA -- trans=[%s] %s", trans_storing_data.getInfo, str_data_pl));
    trans_storing_data = null;
  end
  end
endtask:doOnData	


task vqdmaif_c2h_monitor::doOnAssembleCmdDataTransfer();
  localparam DEBUG_ID = "ASSEMBLE-CMD-DATA";
  forever begin
    T_TRANS trans;
    T_CMD_PL cmd_pl;
  T_CMD_SB_PL cmd_sideband_pl;
  string str_cmd_pl;

    // CAPTURE
    wait(this.q_fwd_to_assemble_cmd.size > 0);
    trans = this.q_fwd_to_assemble_cmd.pop_front();
    this.reportDebugInfo(DEBUG_ID, $sformatf("FOUND_TRANS trans=[%s] waiting the DATA transfers to assemble..", trans.getInfo));
    fork begin
      fork
        wait(this.q_cmd.size > 0);
        this.watchDog_MustNotExpired(
          "doOnAssembleCmdDataTransfer", 
          this.cfg.fwd_transfer_assemble_try_intvl,
          this.cfg.max_num_fwd_transfer_assemble_retry
        );
      join_any
    disable fork;
    end join
    cmd_pl = this.q_cmd.pop_front();
    str_cmd_pl = $sformatf("cmd_pl=[%s]", MakeString_QdmaC2HCmd_t(cmd_pl));

    // CHK
    void'(this.chkProtclAtAssembleCmdData(trans, cmd_pl, str_cmd_pl));
    void'(this.chkSupportnessAtAssembleCmdData(trans, cmd_pl, str_cmd_pl));

    // UPDATE
    this.reportDebugInfo(DEBUG_ID, $sformatf("trans=[%s] %s", trans.getInfo, str_cmd_pl));

    cmd_sideband_pl = this.q_cmd_sideband.pop_front();
    trans.storeCmdSideband(cmd_sideband_pl);
    trans.storeCmd(cmd_pl);

    this.ap_assembled_fwd_transfer.write(trans);
    ot_cnt += 1;
    if(this.cfg.enable_coverage) this.cov.sampleOt(ot_cnt);
    if(this.cfg.dma_type == MBDMA && (!trans.isNeedStatus && !trans.isNeedInterruptSideband)) this.deleteCompletedTrans(trans);
  end
endtask:doOnAssembleCmdDataTransfer


task vqdmaif_c2h_monitor::doOnStatus();
  localparam int DEBUG_ID = "STATUS";				
  forever begin
    T_TRANS trans;
    T_STATUS_PL status_pl;
    T_STATUS_SB_PL status_sideband_pl;
    string str_status_pl;
    int idx[$];

    // CAPTURE
    this.vif.WaitTransferHs_STATUS(status_pl);
    status_sideband_pl = this.vif.status_sideband_pl;
    str_status_pl = $sformatf("status_pl=[%s]", MakeString_QdmaC2HStatus_t(status_pl));

    // CHK
    void'(this.chkProtclAtStatus(status_pl, str_status_pl));
    void'(this.chkSupportnessAtStatus(status_pl, str_status_pl));
    this.default_chkr.chkStatus(status_pl, status_sideband_pl);

    // UPDATE
    this.reportDebugInfo(DEBUG_ID, $sformatf("%s", str_status_pl));
    if(this.sa_active.exists(status_pl.qid))begin
      if(this.cfg.dma_type == QDMA) begin
        trans = this.sa_active[status_pl.qid][0];
      end
      else if(this.cfg.dma_type == MBDMA) begin
        idx = this.sa_active[status_pl.qid].find_first_index(x) with (x.hasStatus === 0);
        trans = this.sa_active[status_pl.qid][idx[0]];
      end
      trans.storeStatusSideband(status_sideband_pl);
      trans.storeStatus(status_pl);
      if(trans.wasDone) begin
        this.deleteCompletedTrans(trans);
      end
    end
  end
endtask:doOnStatus


task vqdmaif_c2h_monitor::doOnInterruptSideband();
  localparam int DEBUG_ID = "INTERRUPT_SIDEBAND";
  forever begin
  T_TRANS trans;
  T_INTERRUPT_SB_PL interrupt_sideband_pl;
  int idx[$];

  //CAPTURE
  this.vif.WaitTransferHs_INTERRUPT_SIDEBAND(interrupt_sideband_pl);

  //CHK
  void'(this.chkProtclAtInterruptSideband(interrupt_sideband_pl));
  
  //UPDATE
  if(this.sa_active.exists(interrupt_sideband_pl.qid)) begin
    idx = this.sa_active[interrupt_sideband_pl.qid].find_first_index(x) with (x.hasInterruptSideband === 0);
    trans = this.sa_active[interrupt_sideband_pl.qid][idx[0]];
    trans.storeInterruptSideband(interrupt_sideband_pl);
    if(trans.wasDone) this.deleteCompletedTrans(trans);
  end
  end
endtask : doOnInterruptSideband


task vqdmaif_c2h_monitor::measureBandwidth();
  Timestamp_t prev_ts = 0;  
  QdmaC2HData_t data_pl;
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


function StringQ_t vqdmaif_c2h_monitor::getInfoList();
  StringQ_t result;
  result.push_back($sformatf("** Total %1d active trans(s)", this.q_active.size));
  foreach(this.q_active[i])begin
    T_TRANS trans=this.q_active[i];
    result.push_back($sformatf("\t\t- active_trans#%-3d=[%s]", i, trans.getInfo));
  end
  return(result);
endfunction:getInfoList


function void vqdmaif_c2h_monitor::deleteCompletedTrans(T_TRANS me);
  QdmaQId_t qid = me.getQid;
  MainEventIdType_t event_type;
  int idx[$] = this.q_active.find_first_index(x) with (x === me);
  this.q_active.delete(idx[0]);
  void'(this.sa_active[qid].pop_front);
  if(this.sa_active[qid].size == 0) this.sa_active.delete(qid);
  `vmg_info("C2H_MON-COMPLETED_TRANS", $sformatf("trans=[%s] (#active=%1d) -- @%s", me.getInfo, this.q_active.size, this.get_full_name), cfg.verbosity)
  if(this.cfg.enable_coverage) this.cov.sampleC2HTrans(me);
  this.ap_trans.write(me);
  this.ap_dcntnr.write(me.dcntnr);
  this.perf_analyzer.doOnCompleted(me);
  ot_cnt -= 1;
endfunction:deleteCompletedTrans


function void vqdmaif_c2h_monitor::startTraceNewTrans(T_TRANS me);
  this.q_active.push_back(me);
  this.sa_active[me.qid].push_back(me);
  this.perf_analyzer.doOnStarted(me);
  `vmg_info("C2H_MON-NEW_TRANS", $sformatf("trans=[%s] (#active=%1d) -- @%s", me.getInfo, this.q_active.size, this.get_full_name), cfg.verbosity)
endfunction:startTraceNewTrans


task vqdmaif_c2h_monitor::waitIdle(string call_info="unspecified");
  `vmg_info("C2H_MON-WAIT_IDLE", $sformatf("call_info=%s wait(q_active.size == 0)", call_info), UVM_LOW)
  wait(this.q_active.size == 0);
endtask:waitIdle


function bit  vqdmaif_c2h_monitor::chkProtclAtData(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  bit result=1;

  if(!this.chkProtclAtData_qid(trans, data_pl, str_data_pl))begin
    `vmg_warning(this.get_name, $sformatf("chkProtclAtData -- Skipping further checks due to the cmd/data pair mapping failure, result may be invalid."));
    return(0);
  end
  // if(!this.chkProtclAtData_len(trans, data_pl, str_data_pl)) result = 0;
  if(!this.chkProtclAtData_last(trans, data_pl, str_data_pl)) result = 0;
  if(!this.chkProtclAtData_mty(trans, data_pl, str_data_pl)) result = 0;
  return(result);
endfunction:chkProtclAtData


function bit vqdmaif_c2h_monitor::chkProtclAtData_qid(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  bit result=1;
  QdmaifC2hProtclErrIdType_t err_id = C2H_000_DATA_QID;
  QdmaQId_t actual_qid = data_pl.qid;
  QdmaQId_t ref_qid = trans == null ? actual_qid : trans.q_data_pl[$].qid;

  if(actual_qid !== ref_qid)begin
    result = 0;
    this.reportProtclErr(
      err_id,
      $sformatf("actual/expected_qid=%1d(0x%1h)/%1d(0x%1h)\n\t\t* %s\n",
        actual_qid, actual_qid,
        ref_qid, ref_qid,
        str_data_pl
    ));				
  end
  else begin
    this.reportDebugInfo(
      $sformatf("CHK_PROTCL.%s", err_id.name),
      $sformatf("PASS -- actual/expected_qid=%1d(0x%1h)/%1d(0x%1h)\n\t\t* %s\n",
        actual_qid, actual_qid,
        ref_qid, ref_qid,
        str_data_pl
    ));
  end
  return(result);
endfunction:chkProtclAtData_qid


function bit vqdmaif_c2h_monitor::chkProtclAtData_mty(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  bit result=1;
  QdmaifC2hProtclErrIdType_t err_id = C2H_003_DATA_MTY;
  QdmaMty_t actual_mty = data_pl.mty;
  QdmaMty_t ref_mty;

  if(trans.getNumPlannedData == 0) ref_mty = (this.cfg.DATA_SIZE - (trans.q_data_pl[0].len % this.cfg.DATA_SIZE)) % this.cfg.DATA_SIZE;
  else                       	     ref_mty = 0;

  if(actual_mty !== ref_mty)begin
    result = 0;
    this.reportProtclErr(
      err_id,
      $sformatf("actual/expected_mty=%1d(0x%1h)/%1d(0x%1h)\n\t\t* %s\n\t\t* Interface data signal width: %1d bytes\n",
        actual_mty, actual_mty,
        ref_mty, ref_mty,
        str_data_pl,
        this.cfg.DATA_SIZE
    ));				
  end
  else begin
    this.reportDebugInfo(
      $sformatf("CHK_PROTCL.%s", err_id.name),
      $sformatf("PASS -- actual/expected_mty=%1d(0x%1h)/%1d(0x%1h)\n\t\t* %s\n\t\t* Interface data signal width: %1d bytes\n",
        actual_mty, actual_mty,
        ref_mty, ref_mty,
        str_data_pl,
        this.cfg.DATA_SIZE
    ));
  end
  return(result);
endfunction:chkProtclAtData_mty


// function bit vqdmaif_c2h_monitor::chkProtclAtData_last(ref T_DATA_PL data_pl, string str_data_pl);
function bit vqdmaif_c2h_monitor::chkProtclAtData_last(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  bit result=1;
  QdmaifC2hProtclErrIdType_t err_id = C2H_002_DATA_LAST;
  logic actual_last = data_pl.last;
  logic ref_last;

  if(trans.getNumPlannedData == 0) ref_last = 1;
  else                             ref_last = 0;

  if(actual_last !== ref_last)begin
    result = 0;
    this.reportProtclErr(
      err_id,
      $sformatf("actual/expected_last=%1d/%1d\n\t\t* %s\n\t\t* Interface data signal width: %1d bytes\n",
        actual_last,
        ref_last,
        str_data_pl,
        this.cfg.DATA_SIZE
    ));				
  end
  else begin
    this.reportDebugInfo(
      $sformatf("CHK_PROTCL.%s", err_id.name),
      $sformatf("PASS -- actual/expected_last=%1d/%1d\n\t\t* %s\n\t\t* Interface data signal width: %1d bytes\n",
        actual_last,
        ref_last,
        str_data_pl,
        this.cfg.DATA_SIZE
    ));
  end
  return(result);
endfunction:chkProtclAtData_last


function bit vqdmaif_c2h_monitor::chkSupportnessAtData(T_TRANS trans, ref T_DATA_PL data_pl, string str_data_pl);
  bit result=1;

  if(trans.q_data_pl.size == 0 && data_pl.len === 0)begin
    result = 0;
    this.reportUnsupFeature(C2H_UNSUP_DATA_LEN_ZERO, str_data_pl);
  end
  if(data_pl.marker !== 0)begin
    result = 0;
    this.reportUnsupFeature(C2H_UNSUP_DATA_MARKER, str_data_pl);
  end
  if(data_pl.has_cmpt !== 0)begin
    result = 0;
    this.reportUnsupFeature(C2H_UNSUP_DATA_HAS_CMPT, str_data_pl);
  end
  if(data_pl.ecc !== 0)begin
    result = 0;
    this.reportUnsupFeature(C2H_UNSUP_DATA_ECC, str_data_pl);
  end
  if(data_pl.crc !== 0)begin
    result = 0;
    this.reportUnsupFeature(C2H_UNSUP_DATA_CRC, str_data_pl);
  end
  return(result);
endfunction:chkSupportnessAtData


function bit vqdmaif_c2h_monitor::chkProtclAtAssembleCmdData(T_TRANS trans, ref T_CMD_PL cmd_pl, string str_cmd_pl);
  bit result=1;
  QdmaifC2hProtclErrIdType_t err_id = C2H_100_CMD_DATA_INORDER;
  QdmaQId_t actual_qid = cmd_pl.qid;
  QdmaQId_t ref_qid = trans.qid;

  if(actual_qid !== ref_qid)begin
    result = 0;
    this.reportProtclErr(
      err_id,
      $sformatf("actual/expected_qid=%1d(0x%1h)/%1d(0x%1h)\n\t\t* %s\n",
        actual_qid, actual_qid,
        ref_qid, ref_qid,
        str_cmd_pl
    ));				
  end
  else begin
    this.reportDebugInfo(
      $sformatf("CHK_PROTCL.%s", err_id.name),
      $sformatf("PASS -- actual/expected_qid=%1d(0x%1h)/%1d(0x%1h)\n\t\t* %s\n",
        actual_qid, actual_qid,
        ref_qid, ref_qid,
        str_cmd_pl
    ));
  end
  return(result);
endfunction:chkProtclAtAssembleCmdData


function bit vqdmaif_c2h_monitor::chkSupportnessAtAssembleCmdData(T_TRANS trans, ref T_CMD_PL cmd_pl, string str_cmd_pl);
  bit result=1;

  if(cmd_pl.pfch_tag !== 0 && (cfg.report_unsup_cmd_pfch_tag == YES)) begin
    result = 0;
    this.reportUnsupFeature(C2H_UNSUP_CMD_PFCH_TAG, str_cmd_pl);
  end
  if(cmd_pl.error !== 0 && (cfg.report_unsup_cmd_err == YES)) begin
    result = 0;
    this.reportUnsupFeature(C2H_UNSUP_CMD_ERROR, str_cmd_pl);
  end
  return(result);
endfunction:chkSupportnessAtAssembleCmdData


function bit vqdmaif_c2h_monitor::chkProtclAtStatus(ref T_STATUS_PL status_pl, string str_status_pl);
  bit result=1;
  QdmaifC2hProtclErrIdType_t err_id = C2H_200_STATUS_CORRESPOND;
  QdmaQId_t actual_qid = status_pl.qid;

  if(!this.sa_active.exists(actual_qid))begin
    result = 0;
    this.reportProtclErr(
      err_id,
      $sformatf("Cannot find the oustanding transaction for qid=%1d(0x%1h)\n\t\t* %s\n",
        actual_qid, actual_qid,
        str_status_pl
    ));				
  end
  else begin
    this.reportDebugInfo(
      $sformatf("CHK_PROTCL.%s", err_id.name),
      $sformatf("PASS -- actual_qid=%1d(0x%1h)\n\t\t* %s\n",
        actual_qid, actual_qid,
        str_status_pl
    ));
  end
  return(result);
endfunction:chkProtclAtStatus


function bit vqdmaif_c2h_monitor::chkSupportnessAtStatus(ref T_STATUS_PL status_pl, string str_status_pl);
  bit result=1;

  if((status_pl.error !== 0) && (cfg.report_unsup_status_err == YES)) begin
    result = 0;
    `uvm_info(this.get_full_name(), "STATUS_ERR", cfg.verbosity);
    this.reportUnsupFeature(C2H_UNSUP_STATUS_ERROR, str_status_pl);
  end
  return(result);
endfunction:chkSupportnessAtStatus

function bit vqdmaif_c2h_monitor::chkProtclAtDataSideband(T_TRANS trans, ref T_DATA_SB_PL data_pl, string str_data_pl);
  bit result = 1;
  if(trans.q_data_sideband_pl.size() && (trans.q_data_sideband_pl[$].fid != data_pl.fid)) begin
    result = 0;
    this.reportProtclErr(
      C2H_400_DATA_SIDEBAND_CORRESPOND,
      $sformatf("fid changed during data trans: prev_fid=%0x, curr_fid=%0x",
      trans.q_data_sideband_pl[$].fid, data_pl.fid
    ));				
  end
endfunction : chkProtclAtDataSideband

function bit vqdmaif_c2h_monitor::chkProtclAtInterruptSideband(ref T_INTERRUPT_SB_PL interrupt_sideband_pl);
  bit result = 1;
  QdmaifC2hProtclErrIdType_t err_id = C2H_300_INTERRUPT_SIDEBAND_CORRESPOND;
  QdmaQId_t actual_qid = interrupt_sideband_pl.qid;

  if(!this.sa_active.exists(actual_qid))begin
    result = 0;
    this.reportProtclErr(
      err_id,
      $sformatf("Cannot find the oustanding transaction for qid=%1d(0x%1h)\n\t\t*",
        actual_qid, actual_qid
    ));				
  end
  else begin
    this.reportDebugInfo(
      $sformatf("CHK_PROTCL.%s", err_id.name),
      $sformatf("PASS -- actual_qid=%1d(0x%1h)\n\t\t*",
        actual_qid, actual_qid
    ));
  end

  return(result);
endfunction : chkProtclAtInterruptSideband


function void vqdmaif_c2h_monitor::discoverSeverityPolicy_ProtclErr();
  uvm_severity default_severity=UVM_ERROR;

  `vmg_get_cfgdb_at_me_can_be_failed(uvm_severity, MakeCfgdbFieldName_Severity("default"), default_severity)
  for(QdmaifC2hProtclErrIdType_t cur_type=cur_type.first(); cur_type < UNDEFINED_QDMAIF_C2H_PROTCL_ERR_ID_TYPE; cur_type = cur_type.next()) begin
    this.sa_severity_protcl_err[cur_type] = default_severity;
    `vmg_get_cfgdb_at_me_can_be_failed(uvm_severity, MakeCfgdbFieldName_Severity(cur_type.name), this.sa_severity_protcl_err[cur_type])
  end
endfunction:discoverSeverityPolicy_ProtclErr


function void vqdmaif_c2h_monitor::discoverSeverityPolicy_UnsupFeature();
  uvm_severity default_severity=UVM_FATAL;

  `vmg_get_cfgdb_at_me_can_be_failed(uvm_severity, MakeCfgdbFieldName_Severity("default"), default_severity)
  for(QdmaifC2hUnsupFeatureIdType_t cur_type=cur_type.first(); cur_type < UNDEFINED_QDMAIF_C2H_UNSUP_FEATURE_ID_TYPE; cur_type = cur_type.next()) begin
    this.sa_severity_unsup_feature[cur_type] = default_severity;
    `vmg_get_cfgdb_at_me_can_be_failed(uvm_severity, MakeCfgdbFieldName_Severity(cur_type.name), this.sa_severity_unsup_feature[cur_type])
  end
endfunction:discoverSeverityPolicy_UnsupFeature


function void vqdmaif_c2h_monitor::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);				
  this.discoverSeverityPolicy_ProtclErr();
  this.discoverSeverityPolicy_UnsupFeature();
endfunction:start_of_simulation_phase


function void vqdmaif_c2h_monitor::report_phase(uvm_phase phase);
  if(this.cfg.performance_measure) begin
    `vmg_info(this.getName, $sformatf("---------------------------------------------------------------------"), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf(" PERFORMANCE_REPORT(C2H)"), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf("---------------------------------------------------------------------"), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf("  - Interface frequency           : %1d Mhz", this.freq_in_mhz), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf("  - Monitored time interval       : %.1f ns", this.total_time), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf("  - Total amount of data transfer : %s", MakeString_MemSize(this.total_bytes)), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf("  - Average B/W                   : %.1f Gbps", this.cur_bandwidth), UVM_MEDIUM)
    `vmg_info(this.getName, $sformatf("---------------------------------------------------------------------"), UVM_MEDIUM)
  end
endfunction : report_phase



task vqdmaif_c2h_monitor::reset_phase(uvm_phase phase);
  super.reset_phase(phase);
  this.q_cmd.delete();
  this.q_cmd_sideband.delete();
  this.q_fwd_to_assemble_cmd.delete();
  foreach(this.sa_active[qid]) this.sa_active[qid].delete();
  this.sa_active.delete();
  this.q_active.delete();
endtask
  

function vqdmaif_c2h_if_checker vqdmaif_c2h_monitor::discoverDefaultChkr();
  vqdmaif_c2h_if_checker discovered;

  `vmg_get_cfgdb_at_me_can_be_failed(vqdmaif_c2h_if_checker, "default_chkr", discovered)
  if(discovered != null)begin
    `vmg_info(this.get_full_name, $sformatf("Found an injected \"default_chkr\" handle, will use the customized one."), UVM_LOW)
  end
  else begin
    discovered = vqdmaif_c2h_default_checker::type_id::create("default_chkr");
  end
  discovered.setVerbosity(this.cfg.verbosity);
  return(discovered);
endfunction


`endif // __VQDMAIF_C2H_MONITOR_SVH__
