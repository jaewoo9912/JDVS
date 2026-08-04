`ifndef  __VDMATB_VSEQ_SVH__
`define  __VDMATB_VSEQ_SVH__


class vdmatb_vseq extends vt4_vseq;

  vdmatb_tcfg tcfg;
  vdmatb_scfg scfg;

  SeqInfoQ_t q_being_executed_h2c_seq_info, q_being_executed_c2h_seq_info;
  
  PdmaC2HPerfResult_t c2h_perf_actual_result;
  PdmaH2CPerfResult_t h2c_perf_actual_result;

//-------------------------------------- PMON
  pdma_st_ip_c2h_mon_mngr    st_c2h_pmon_mngr;
  pdma_st_ip_h2c_mon_mngr    st_h2c_pmon_mngr;
  pdma_mm_ip_c2h_mon_mngr    mm_c2h_pmon_mngr;
  pdma_mm_ip_h2c_mon_mngr    mm_h2c_pmon_mngr;
  
  pdma_st_c2h_mon_perf_anlzr st_c2h_m_perf_anlzr;   
  pdma_st_h2c_mon_perf_anlzr st_h2c_m_perf_anlzr;
  pdma_mm_c2h_mon_perf_anlzr mm_c2h_m_perf_anlzr;   
  pdma_mm_h2c_mon_perf_anlzr mm_h2c_m_perf_anlzr;
//
  pvip_pmon_perf_report pmon_report;

  `uvm_declare_p_sequencer(vdmatb_vseqr)

  `uvm_object_utils(vdmatb_vseq)

  function new(string name="vdmatb_vseq");
    super.new(name);
    this.need_wait_idle = YES;
  endfunction

  extern virtual task body();
  extern virtual task pre_body();
  extern virtual function YesOrNo_t isBusy();

  extern virtual function void integrateCfg(vt4_tcfg m_tcfg, vt4_scfg m_scfg);

  extern virtual function void show(string prompt="");
  extern virtual function void chkCfg();
  extern virtual function void showCfg(string prompt="");
  extern protected virtual function void makeScenarioDescription();

  extern function void addH2CDmaMstSeqToExecute(string type_name, string inst_name=type_name);
  extern function void addC2HDmaMstSeqToExecute(string type_name, string inst_name=type_name);

  extern protected task executeDmaMstSeqList(SeqInfoQ_t seq_info_list);
  extern protected task executeDmaMstSeq(SeqInfo_t seq_info);

  extern virtual task doPreBody_body();
  extern virtual task doBody_body();
  extern virtual task doPostBody_body();


  extern protected function vdmatb_host_seq createHostSeq(string type_name, string inst_name=type_name);
  extern virtual local function string decideHostSeqToExecute();
  extern protected task executeHostSeq(string type_name, string inst_name=type_name, string msg="");

  extern protected function vdmatb_card_seq createCardSeq(string type_name, string inst_name=type_name);
  extern virtual local function string decideCardSeqToExecute();
  extern protected task executeCardSeq(string type_name, string inst_name=type_name, string msg="");
  
  extern local task executeInterReset();
  
  // ---------------- perf checker
  extern local function void getPerfAnlzr(); 
  extern local function void executeStPerfChecker();
  extern local function void chk_StPerfResult(vdmatb_scfg scfg);
  extern local function void executeMmPerfChecker();
  extern local function void chk_MmPerfResult(vdmatb_scfg scfg);
  extern local function PerfExpectedThroughputRange_t calculate_ExpectedTpByErrorRatio(int throughput, int error_ratio);
  
  extern local task startPmonMeas();
  extern local task stopPmonMeas();
  extern local function void disablePmon(DmaIpType_t dma_ip_type);
  extern local function void showPmonReport(DmaIpType_t dma_ip_type);

endclass:vdmatb_vseq


function void vdmatb_vseq::integrateCfg(vt4_tcfg m_tcfg, vt4_scfg m_scfg);
  super.integrateCfg(m_tcfg, m_scfg);
  $cast(this.tcfg, m_tcfg);
  $cast(this.scfg, m_scfg);
endfunction:integrateCfg


function YesOrNo_t vdmatb_vseq::isBusy(); return(this.p_sequencer.isBusy); endfunction

function void vdmatb_vseq::chkCfg(); endfunction



function void vdmatb_vseq::showCfg(string prompt="");
  this.showReportHeader(prompt);
  this.debug($sformatf("%s ** Being executed H2C DMA sequences (total:%1d)", prompt, this.q_being_executed_h2c_seq_info.size));
  foreach(this.q_being_executed_h2c_seq_info[i])begin
    this.debug($sformatf("%s    - %s (type=%s)", prompt, this.q_being_executed_h2c_seq_info[i].inst_name, this.q_being_executed_h2c_seq_info[i].type_name));
  end
  this.debug($sformatf("%s ** Being executed C2H DMA sequences (total:%1d)", prompt, this.q_being_executed_c2h_seq_info.size));
  foreach(this.q_being_executed_c2h_seq_info[i])begin
    this.debug($sformatf("%s    - %s (type=%s)", prompt, this.q_being_executed_c2h_seq_info[i].inst_name, this.q_being_executed_c2h_seq_info[i].type_name));
  end
endfunction:showCfg





function void vdmatb_vseq::addC2HDmaMstSeqToExecute(string type_name, string inst_name=type_name);
  SeqInfo_t new_info;

  new_info.type_name = type_name;
  new_info.inst_name = inst_name;

  this.q_being_executed_c2h_seq_info.push_back(new_info);
endfunction:addC2HDmaMstSeqToExecute




function void vdmatb_vseq::addH2CDmaMstSeqToExecute(string type_name, string inst_name=type_name);
  SeqInfo_t new_info;

  new_info.type_name = type_name;
  new_info.inst_name = inst_name;

  this.q_being_executed_h2c_seq_info.push_back(new_info);
endfunction:addH2CDmaMstSeqToExecute




task vdmatb_vseq::executeDmaMstSeq(SeqInfo_t seq_info);
  vdma_mst_seq seq;

  if(this.tcfg.getDmaIpType == ST)
    seq = VDMA_FACTORY.createMbDmaStMstSeq(seq_info, this.get_full_name, this.p_sequencer.st_h2c_mst, this.p_sequencer.st_c2h_mst);
  else if(this.tcfg.getDmaIpType == MM)
    seq = VDMA_FACTORY.createMbDmaMmMstSeq(seq_info, this.get_full_name, this.p_sequencer.mm_h2c_mst, this.p_sequencer.mm_c2h_mst);
  else
    this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  
  seq.start(seq.getMstSeqr);
endtask:executeDmaMstSeq


function void vdmatb_vseq::show(string prompt="");
  super.show(prompt);
  this.p_sequencer.show(prompt);
endfunction:show


task vdmatb_vseq::executeDmaMstSeqList(SeqInfoQ_t seq_info_list);
  while(seq_info_list.size != 0)begin
    SeqInfo_t new_seq_info;

    new_seq_info = seq_info_list.pop_front();
    this.executeDmaMstSeq(new_seq_info);
  end
endtask:executeDmaMstSeqList


task vdmatb_vseq::pre_body();
  if(this.tcfg.getDmaIpType == ST) begin
    this.st_c2h_pmon_mngr = this.p_sequencer.st_c2h_pmon_mngr;
    this.st_h2c_pmon_mngr = this.p_sequencer.st_h2c_pmon_mngr;
  end
  else if(this.tcfg.getDmaIpType == MM) begin 
    this.mm_c2h_pmon_mngr = this.p_sequencer.mm_c2h_pmon_mngr;
    this.mm_h2c_pmon_mngr = this.p_sequencer.mm_h2c_pmon_mngr;
  end 
  else
    this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  
  super.pre_body();
endtask : pre_body




// TODO: Redesign w/ small pcies of tasks
task vdmatb_vseq::body();
  
  this.waitCycle(575);

  fork
    this.executeHostSeq(this.decideHostSeqToExecute());
    if(this.tcfg.getDmaIpType == MM) this.executeCardSeq(this.decideCardSeqToExecute());
  join_none
//-------------------------------------- PMON
  
  if(this.tcfg.test_type == FAULT_TEST) begin
    this.info("Disable PMON because test_type is FAULT_TEST !!");
    this.disablePmon(this.tcfg.getDmaIpType);
  end
  else begin
    if(this.tcfg.getDmaIpType == UNDEFINED_DMA_IP_TYPE)
      this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
    
    this.startPmonMeas();
  end

  fork
    this.executeDmaMstSeqList(this.q_being_executed_h2c_seq_info);
    this.executeDmaMstSeqList(this.q_being_executed_c2h_seq_info);
  join
 
  if(this.tcfg.test_type == INTER_RESET_TEST) this.executeInterReset();

  if(this.tcfg.test_type != FAULT_TEST) begin
    this.stopPmonMeas();
    this.showPmonReport(this.tcfg.getDmaIpType);
    
    if(this.tcfg.test_type == PERF_TEST) begin
      this.getPerfAnlzr();
      case(this.tcfg.getDmaIpType)
        ST : this.executeStPerfChecker();
        MM : this.executeMmPerfChecker();
      endcase
    end
  end
endtask:body



task vdmatb_vseq::executeInterReset();
  virtual  dmg_clk_if vif_dmg_clk;
  
  `vmg_get_cfgdb_anyone(virtual dmg_clk_if, "vif_clk", vif_dmg_clk) 

  if(this.p_sequencer.isIdle() == YES) begin
    this.debug("[INTER-RESET] ENABLED !!");
    vif_dmg_clk.RESETn = 0;
    this.waitCycle(PickRandUIntInTheRange2(20, 50));
    vif_dmg_clk.RESETn = 1;
    this.debug("[INTER-RESET] DISABLED !!");
  end
  else
    this.reportFatal($sformatf("[INTER-RESET] All MST Agents are not Reset !!"), $sformatf("All MST Agents need to Reset !!"));
  this.debug("[INTER-RESET] Second H2C/C2H Seq Execute !!");
  fork
    this.executeDmaMstSeqList(this.q_being_executed_h2c_seq_info);
    this.executeDmaMstSeqList(this.q_being_executed_c2h_seq_info);
  join
endtask : executeInterReset



function void vdmatb_vseq::makeScenarioDescription();
  StringQ_t descriptions;

  foreach(this.q_being_executed_h2c_seq_info[i])begin
    descriptions.delete();
    descriptions.push_back($sformatf("Execute a dma sequence in parallel -- \"%s\"(type=%s)", this.q_being_executed_h2c_seq_info[i].inst_name, this.q_being_executed_h2c_seq_info[i].type_name));
  end

  foreach(this.q_being_executed_c2h_seq_info[i])begin
    descriptions.delete();
    descriptions.push_back($sformatf("Execute a dma sequence in parallel -- \"%s\"(type=%s)", this.q_being_executed_c2h_seq_info[i].inst_name, this.q_being_executed_c2h_seq_info[i].type_name));
  end

endfunction:makeScenarioDescription


task vdmatb_vseq::doBody_body(); endtask:doBody_body
task vdmatb_vseq::doPreBody_body(); endtask:doPreBody_body
task vdmatb_vseq::doPostBody_body(); endtask:doPostBody_body

function vdmatb_host_seq vdmatb_vseq::createHostSeq(string type_name, string inst_name=type_name);
  vdmatb_host_seq created;

  if(!$cast(created, VDMATB_FACTORY.createObjByTypeName(type_name, inst_name, this.get_full_name()))) begin
    this.fatal("CREATE_HOST_SEQ", $sformatf("Failed to create host sequence \"%s\" !!", type_name));
  end
  return(created);
endfunction:createHostSeq


function vdmatb_card_seq vdmatb_vseq::createCardSeq(string type_name, string inst_name=type_name);
  vdmatb_card_seq created;

  if(!$cast(created, VDMATB_FACTORY.createObjByTypeName(type_name, inst_name, this.get_full_name()))) begin
    this.fatal("CREATE_CARD_SEQ", $sformatf("Failed to create card sequence \"%s\" !!", type_name));
  end
  return(created);
endfunction:createCardSeq


function string vdmatb_vseq::decideHostSeqToExecute(); return("vdmatb_host_default_seq"); endfunction
function string vdmatb_vseq::decideCardSeqToExecute(); return("vdmatb_card_default_seq"); endfunction


task vdmatb_vseq::executeHostSeq(string type_name, string inst_name=type_name, string msg="");
  vdmatb_host_seq created;
  string prompt;

  prompt = this.makePrompt($sformatf("executeHostSeq(msg=%s)", msg));

  $cast(created, this.createHostSeq(type_name, inst_name));
  created.tcfg = this.tcfg;
  created.scfg = this.scfg;
  this.info($sformatf("%sEXECUTE_SEQ %s(%s) - Starting..", prompt, inst_name, type_name));
  created.start(this.p_sequencer.host_seqr, null);
this.info($sformatf("%s EXECUTE_SEQ %s(%s) - Completed..", prompt, inst_name, type_name));
endtask:executeHostSeq


task vdmatb_vseq::executeCardSeq(string type_name, string inst_name=type_name, string msg="");
  vdmatb_card_seq created;
  string prompt;

  prompt = this.makePrompt($sformatf("executeCardSeq(msg=%s)", msg));

  $cast(created, this.createCardSeq(type_name, inst_name));
  created.tcfg = this.tcfg;
  created.scfg = this.scfg;
  this.info($sformatf("%sEXECUTE_SEQ %s(%s) - Starting..", prompt, inst_name, type_name));
  created.start(this.p_sequencer.card_seqr, null);
  this.info($sformatf("%s EXECUTE_SEQ %s(%s) - Completed..", prompt, inst_name, type_name));
endtask:executeCardSeq



function void vdmatb_vseq::getPerfAnlzr();
  case(this.tcfg.getDmaIpType)
    ST : begin
      this.st_h2c_m_perf_anlzr = this.st_h2c_pmon_mngr.h2c_mngr.h2c_returnPerfAnlzr();  
      this.st_c2h_m_perf_anlzr = this.st_c2h_pmon_mngr.c2h_mngr.c2h_returnPerfAnlzr();  
    end
    MM : begin
      this.mm_h2c_m_perf_anlzr = this.mm_h2c_pmon_mngr.h2c_mngr.h2c_returnPerfAnlzr();  
      this.mm_c2h_m_perf_anlzr = this.mm_c2h_pmon_mngr.c2h_mngr.c2h_returnPerfAnlzr();  
    end
    default : this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endcase
endfunction : getPerfAnlzr



function void vdmatb_vseq::executeStPerfChecker();
  this.st_h2c_m_perf_anlzr.calculate_actual_result();
  this.st_c2h_m_perf_anlzr.calculate_actual_result();
  
  this.chk_StPerfResult(this.scfg);
  this.p_sequencer.st_cov_colctr.samplePerfScenario(this.scfg);
  this.p_sequencer.st_cov_colctr.sampleActualPerfResult();
endfunction : executeStPerfChecker


function void vdmatb_vseq::chk_StPerfResult(vdmatb_scfg scfg);
  PerfExpectedThroughputRange_t c2h_expectedThroughput, h2c_expectedThroughput;

  if(scfg.perf_ctrl_knob.perf_crossing == YES) begin
    this.c2h_perf_actual_result.c2h_throughput = this.st_c2h_m_perf_anlzr.specific_result.c2h_perf_throughput;
    this.h2c_perf_actual_result.h2c_throughput = this.st_h2c_m_perf_anlzr.specific_result.h2c_perf_throughput;
  end
  else begin // Total_len of non_crossing perf_test is half of PERF_REASONABLE_LEN
    this.c2h_perf_actual_result.c2h_throughput = this.st_c2h_m_perf_anlzr.specific_result.c2h_perf_throughput / 2;
    this.h2c_perf_actual_result.h2c_throughput = this.st_h2c_m_perf_anlzr.specific_result.h2c_perf_throughput / 2;
  end

  this.p_sequencer.st_cov_colctr.set_PerfExpected_CP(scfg);
  this.p_sequencer.st_cov_colctr.set_C2HActualResult(this.c2h_perf_actual_result);
  this.p_sequencer.st_cov_colctr.set_H2CActualResult(this.h2c_perf_actual_result);

  c2h_expectedThroughput = this.calculate_ExpectedTpByErrorRatio(scfg.perf_expected.c2h_throughput, scfg.perf_expected.error_ratio);
  h2c_expectedThroughput = this.calculate_ExpectedTpByErrorRatio(scfg.perf_expected.h2c_throughput, scfg.perf_expected.error_ratio);

  if( (c2h_expectedThroughput.min_throughput > this.c2h_perf_actual_result.c2h_throughput) || (this.c2h_perf_actual_result.c2h_throughput > c2h_expectedThroughput.max_throughput) )
    this.error("[Actual Throughput exceed expected value", $sformatf("Actual C2H Throughput=%1d, expected value min/max=%1d/%1d", this.c2h_perf_actual_result.c2h_throughput, c2h_expectedThroughput.min_throughput, c2h_expectedThroughput.max_throughput));  
  if( (h2c_expectedThroughput.min_throughput > this.h2c_perf_actual_result.h2c_throughput) || (this.h2c_perf_actual_result.h2c_throughput > h2c_expectedThroughput.max_throughput) )
    this.error("[Actual Throughput exceed expected value", $sformatf("Actual H2C Throughput=%1d, expected value min/max=%1d/%1d", this.h2c_perf_actual_result.h2c_throughput, h2c_expectedThroughput.min_throughput, h2c_expectedThroughput.max_throughput));  

endfunction:chk_StPerfResult


function void vdmatb_vseq::executeMmPerfChecker();
  this.mm_h2c_m_perf_anlzr.calculate_actual_result();
  this.mm_c2h_m_perf_anlzr.calculate_actual_result();
  
  this.chk_MmPerfResult(this.scfg);
  
  this.p_sequencer.mm_cov_colctr.samplePerfScenario(this.scfg);
  this.p_sequencer.mm_cov_colctr.sampleActualPerfResult();
endfunction : executeMmPerfChecker


function void vdmatb_vseq::chk_MmPerfResult(vdmatb_scfg scfg);
  PerfExpectedThroughputRange_t c2h_expectedThroughput, h2c_expectedThroughput;

  if(scfg.perf_ctrl_knob.perf_crossing == YES) begin
    this.c2h_perf_actual_result.c2h_throughput = this.mm_c2h_m_perf_anlzr.specific_result.c2h_perf_throughput;
    this.h2c_perf_actual_result.h2c_throughput = this.mm_h2c_m_perf_anlzr.specific_result.h2c_perf_throughput;
  end
  else begin // Total_len of non_crossing perf_test is half of PERF_REASONABLE_LEN
    this.c2h_perf_actual_result.c2h_throughput = this.mm_c2h_m_perf_anlzr.specific_result.c2h_perf_throughput / 2;
    this.h2c_perf_actual_result.h2c_throughput = this.mm_h2c_m_perf_anlzr.specific_result.h2c_perf_throughput / 2;
  end

  this.p_sequencer.mm_cov_colctr.set_PerfExpected_CP(scfg);
  this.p_sequencer.mm_cov_colctr.set_C2HActualResult(this.c2h_perf_actual_result);
  this.p_sequencer.mm_cov_colctr.set_H2CActualResult(this.h2c_perf_actual_result);

  c2h_expectedThroughput = this.calculate_ExpectedTpByErrorRatio(scfg.perf_expected.c2h_throughput, scfg.perf_expected.error_ratio);
  h2c_expectedThroughput = this.calculate_ExpectedTpByErrorRatio(scfg.perf_expected.h2c_throughput, scfg.perf_expected.error_ratio);

  if( (c2h_expectedThroughput.min_throughput > this.c2h_perf_actual_result.c2h_throughput) || (this.c2h_perf_actual_result.c2h_throughput > c2h_expectedThroughput.max_throughput) )
    this.error("[Actual Throughput exceed expected value", $sformatf("Actual C2H Throughput=%1d, expected value min/max=%1d/%1d", this.c2h_perf_actual_result.c2h_throughput, c2h_expectedThroughput.min_throughput, c2h_expectedThroughput.max_throughput));  
  if( (h2c_expectedThroughput.min_throughput > this.h2c_perf_actual_result.h2c_throughput) || (this.h2c_perf_actual_result.h2c_throughput > h2c_expectedThroughput.max_throughput) )
    this.error("[Actual Throughput exceed expected value", $sformatf("Actual H2C Throughput=%1d, expected value min/max=%1d/%1d", this.h2c_perf_actual_result.h2c_throughput, h2c_expectedThroughput.min_throughput, h2c_expectedThroughput.max_throughput));  

endfunction:chk_MmPerfResult



function vdma_pkg::PerfExpectedThroughputRange_t vdmatb_vseq::calculate_ExpectedTpByErrorRatio(int throughput, int error_ratio);
  PerfExpectedThroughputRange_t throughput_range;
  
  throughput_range.min_throughput = throughput - (throughput / error_ratio);
  throughput_range.max_throughput = throughput + (throughput / error_ratio);
  
  if(throughput_range.max_throughput > 128) throughput_range.max_throughput = 128;

  return(throughput_range);
endfunction : calculate_ExpectedTpByErrorRatio


task vdmatb_vseq::startPmonMeas();
  case(this.tcfg.getDmaIpType)
    ST : begin
      this.st_c2h_pmon_mngr.startMeas();
      this.st_h2c_pmon_mngr.startMeas();
    end
    MM : begin
      this.mm_c2h_pmon_mngr.startMeas();
      this.mm_h2c_pmon_mngr.startMeas();
    end
    default : this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endcase
endtask : startPmonMeas


task vdmatb_vseq::stopPmonMeas();
  case(this.tcfg.getDmaIpType)
    ST : begin
      this.st_c2h_pmon_mngr.stopMeas();
      this.st_h2c_pmon_mngr.stopMeas();
    end
    MM : begin
      this.mm_c2h_pmon_mngr.stopMeas();
      this.mm_h2c_pmon_mngr.stopMeas();
    end
    default : this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endcase
endtask : stopPmonMeas


function void vdmatb_vseq::disablePmon(DmaIpType_t dma_ip_type);
  case(dma_ip_type)
    ST : begin
      this.st_c2h_pmon_mngr.c2h_mngr.disableCollectOn();
      this.st_c2h_pmon_mngr.c2h_mngr.disableChkPrtclOn();
      this.st_c2h_pmon_mngr.axi_wr_mngr.disableCollectOn();
      this.st_c2h_pmon_mngr.axi_wr_mngr.disableChkPrtclOn();

      this.st_h2c_pmon_mngr.h2c_mngr.disableCollectOn();
      this.st_h2c_pmon_mngr.h2c_mngr.disableChkPrtclOn();
      this.st_h2c_pmon_mngr.axi_rd_mngr.disableCollectOn();
      this.st_h2c_pmon_mngr.axi_rd_mngr.disableChkPrtclOn();
    end
    MM : begin
      this.mm_c2h_pmon_mngr.c2h_mngr.disableCollectOn();
      this.mm_c2h_pmon_mngr.c2h_mngr.disableChkPrtclOn();
      this.mm_c2h_pmon_mngr.c2h_mngr.axi_rd_mngr.disableCollectOn();
      this.mm_c2h_pmon_mngr.c2h_mngr.axi_rd_mngr.disableChkPrtclOn();
      this.mm_c2h_pmon_mngr.axi_wr_mngr.disableCollectOn();
      this.mm_c2h_pmon_mngr.axi_wr_mngr.disableChkPrtclOn();

      this.mm_h2c_pmon_mngr.h2c_mngr.disableCollectOn();
      this.mm_h2c_pmon_mngr.h2c_mngr.disableChkPrtclOn();
      this.mm_h2c_pmon_mngr.h2c_mngr.axi_wr_mngr.disableCollectOn();
      this.mm_h2c_pmon_mngr.h2c_mngr.axi_wr_mngr.disableChkPrtclOn();
      this.mm_h2c_pmon_mngr.axi_rd_mngr.disableCollectOn();
      this.mm_h2c_pmon_mngr.axi_rd_mngr.disableChkPrtclOn();
    end
    default : this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", dma_ip_type));
  endcase
endfunction : disablePmon



function void vdmatb_vseq::showPmonReport(DmaIpType_t dma_ip_type);
  case(dma_ip_type)
    ST : begin
      pmon_report = this.st_c2h_pmon_mngr.c2h_mngr.extractSubReport(0); pmon_report.showReport();
      pmon_report = this.st_c2h_pmon_mngr.c2h_mngr.extractSubReport(1); pmon_report.showReport();
      pmon_report = this.st_c2h_pmon_mngr.c2h_mngr.extractSubReport(2); pmon_report.showReport();
      pmon_report = this.st_c2h_pmon_mngr.c2h_mngr.extractSubReport(3); pmon_report.showReport();
      pmon_report = this.st_c2h_pmon_mngr.c2h_mngr.extractSubReport(4); pmon_report.showReport();
      pmon_report = this.st_c2h_pmon_mngr.extractSubReport(0); pmon_report.showReport();

      pmon_report = this.st_c2h_pmon_mngr.axi_wr_mngr.extractSubReport(0); pmon_report.showReport();
      pmon_report = this.st_c2h_pmon_mngr.axi_wr_mngr.extractSubReport(1); pmon_report.showReport();
      pmon_report = this.st_c2h_pmon_mngr.axi_wr_mngr.extractSubReport(2); pmon_report.showReport();
      pmon_report = this.st_c2h_pmon_mngr.extractSubReport(1); pmon_report.showReport();
      
      pmon_report = this.st_h2c_pmon_mngr.h2c_mngr.extractSubReport(0); pmon_report.showReport();
      pmon_report = this.st_h2c_pmon_mngr.h2c_mngr.extractSubReport(1); pmon_report.showReport();
      pmon_report = this.st_h2c_pmon_mngr.h2c_mngr.extractSubReport(2); pmon_report.showReport();
      pmon_report = this.st_h2c_pmon_mngr.h2c_mngr.extractSubReport(3); pmon_report.showReport();
      pmon_report = this.st_h2c_pmon_mngr.h2c_mngr.extractSubReport(4); pmon_report.showReport();
      pmon_report = this.st_h2c_pmon_mngr.extractSubReport(0); pmon_report.showReport();

      pmon_report = this.st_h2c_pmon_mngr.axi_rd_mngr.extractSubReport(0); pmon_report.showReport();
      pmon_report = this.st_h2c_pmon_mngr.axi_rd_mngr.extractSubReport(1); pmon_report.showReport();
      pmon_report = this.st_h2c_pmon_mngr.extractSubReport(1); pmon_report.showReport();

      this.st_c2h_pmon_mngr.show("[DMA_ST_C2H : AT_THE_END_OF_TEST] ");
      this.st_h2c_pmon_mngr.show("[DMA_ST_H2C : AT_THE_END_OF_TEST] ");
    end
    MM : begin
      pmon_report = this.mm_c2h_pmon_mngr.c2h_mngr.extractSubReport(0); pmon_report.showReport();
      pmon_report = this.mm_c2h_pmon_mngr.c2h_mngr.extractSubReport(1); pmon_report.showReport();
      pmon_report = this.mm_c2h_pmon_mngr.c2h_mngr.extractSubReport(2); pmon_report.showReport();
      pmon_report = this.mm_c2h_pmon_mngr.c2h_mngr.extractSubReport(3); pmon_report.showReport();
      pmon_report = this.mm_c2h_pmon_mngr.c2h_mngr.extractSubReport(4); pmon_report.showReport();
      pmon_report = this.mm_c2h_pmon_mngr.extractSubReport(0); pmon_report.showReport();

      pmon_report = this.mm_c2h_pmon_mngr.axi_wr_mngr.extractSubReport(0); pmon_report.showReport();
      pmon_report = this.mm_c2h_pmon_mngr.axi_wr_mngr.extractSubReport(1); pmon_report.showReport();
      pmon_report = this.mm_c2h_pmon_mngr.axi_wr_mngr.extractSubReport(2); pmon_report.showReport();
      pmon_report = this.mm_c2h_pmon_mngr.extractSubReport(1); pmon_report.showReport();
      
      pmon_report = this.mm_h2c_pmon_mngr.h2c_mngr.extractSubReport(0); pmon_report.showReport();
      pmon_report = this.mm_h2c_pmon_mngr.h2c_mngr.extractSubReport(1); pmon_report.showReport();
      pmon_report = this.mm_h2c_pmon_mngr.h2c_mngr.extractSubReport(2); pmon_report.showReport();
      pmon_report = this.mm_h2c_pmon_mngr.h2c_mngr.extractSubReport(3); pmon_report.showReport();
      pmon_report = this.mm_h2c_pmon_mngr.h2c_mngr.extractSubReport(4); pmon_report.showReport();
      pmon_report = this.mm_h2c_pmon_mngr.extractSubReport(0); pmon_report.showReport();

      pmon_report = this.mm_h2c_pmon_mngr.axi_rd_mngr.extractSubReport(0); pmon_report.showReport();
      pmon_report = this.mm_h2c_pmon_mngr.axi_rd_mngr.extractSubReport(1); pmon_report.showReport();
      pmon_report = this.mm_h2c_pmon_mngr.extractSubReport(1); pmon_report.showReport();

      this.mm_c2h_pmon_mngr.show("[DMA_MM_C2H : AT_THE_END_OF_TEST] ");
      this.mm_h2c_pmon_mngr.show("[DMA_MM_H2C : AT_THE_END_OF_TEST] ");
    end
    default : this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", dma_ip_type));
  endcase
endfunction : showPmonReport


`endif // __VDMATB_VSEQ_SVH__
