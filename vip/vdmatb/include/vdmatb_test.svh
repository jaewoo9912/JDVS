`ifndef __VDMATB_TEST_SVH__
`define __VDMATB_TEST_SVH__


virtual class vdmatb_test extends vt4_test;
  
  protected vdmatb_scfg scfg;
  protected vdmatb_tcfg tcfg;
 
  protected StDmaDesignParam_t ST_DUT_PARAM;
  protected MmDmaDesignParam_t MM_DUT_PARAM;
  protected AxiPortParam_t     HOST_AXI_PORT_PARAM;
  protected AxiPortParam_t     CARD_AXI_PORT_PARAM;
  
  local DmaIpType_t       dma_ip_type = UNDEFINED_DMA_IP_TYPE;
  // tb configuration
  TestScheme_t          tb_scheme;
  TestType_t            test_type;
  SelectFault_t         select_fault;
  YesOrNo_t             enable_pmon;
  FaultProb_t           fault_prob;
  RatioFaultInjection_t fault_ratio;
  DataDirectionType_t   data_direction_type;


  function new(string name="vdmatb_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  
  extern virtual protected function void setupUvmFactory();

  extern virtual function vt4_tcfg createTcfg();
  extern virtual function vt4_scfg createScfg();

  pure virtual function string decideVseqToExecute();

  extern protected virtual function void setTestPlan();

  extern local function void discoverTestParam();
  // --------------------------------------------------------------------- vdma specific
  extern virtual local function StH2CDmaBfmTimingParam_t decideStH2CDmaBfmTimingParam(); 
  extern virtual local function StC2HDmaBfmTimingParam_t decideStC2HDmaBfmTimingParam(); 
  extern virtual local function MmH2CDmaBfmTimingParam_t decideMmH2CDmaBfmTimingParam(); 
  extern virtual local function MmC2HDmaBfmTimingParam_t decideMmC2HDmaBfmTimingParam(); 

  extern function StC2HDmaBfmTimingParam_t decideStC2HAsymmetricLatencyCfg();
  extern function StH2CDmaBfmTimingParam_t decideStH2CAsymmetricLatencyCfg();
  extern function MmC2HDmaBfmTimingParam_t decideMmC2HAsymmetricLatencyCfg();
  extern function MmH2CDmaBfmTimingParam_t decideMmH2CAsymmetricLatencyCfg();


  // ------------ ANDA_WORKING
  extern virtual protected function void decideTbCfg();
  extern virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
  extern virtual protected function PerfTestCtrlKnob_t randomizePerfCtrlKnob(PerfTestCtrlKnob_t ctrl_knob);
  extern virtual protected function PerfExpected_t calculateExpectedPerfResult(PerfTestCtrlKnob_t ctrl_knob);

  extern local function vdma_mst_tcfg createMstTcfg();

  extern virtual protected function void decideDataDirectionType();
  
endclass:vdmatb_test


function void vdmatb_test::build_phase(uvm_phase phase);
  this.discoverTestParam();
  super.build_phase(phase);

  $cast(this.tcfg, m_tcfg);
  $cast(this.scfg, m_scfg);
  this.tcfg.mst_tcfg = this.createMstTcfg();

  this.decideTbCfg();
  this.tcfg.setTbCfg(this.tb_scheme, this.test_type, this.select_fault, this.enable_pmon, this.fault_prob, this.fault_ratio, this.data_direction_type);
  this.tcfg.mst_tcfg.setStH2CDmaBfmTimingParam(this.decideStH2CDmaBfmTimingParam);
  this.tcfg.mst_tcfg.setStC2HDmaBfmTimingParam(this.decideStC2HDmaBfmTimingParam);
  this.tcfg.mst_tcfg.setMmH2CDmaBfmTimingParam(this.decideMmH2CDmaBfmTimingParam);
  this.tcfg.mst_tcfg.setMmC2HDmaBfmTimingParam(this.decideMmC2HDmaBfmTimingParam);

  this.scfg.mst_tcfg = this.tcfg.mst_tcfg;
  this.scfg.perf_ctrl_knob = this.randomizePerfCtrlKnob(this.makeInitialPerfCtrlKnob);
  this.scfg.perf_expected = this.calculateExpectedPerfResult(this.scfg.perf_ctrl_knob);

  this.tcfg.mst_tcfg.perf_ctrl_knob      = this.scfg.perf_ctrl_knob;
endfunction:build_phase



function void vdmatb_test::discoverTestParam();
  string cfgdb_key;
  
  `vmg_get_cfgdb_at_me(string, "cfgdb_key", cfgdb_key)
  
  if(cfgdb_key == "vdmatb_st") begin 
    `vmg_get_cfgdb_at_me(StDmaDesignParam_t, $sformatf("%s_ST_DUT_PARAM", cfgdb_key), this.ST_DUT_PARAM)
    `vmg_get_cfgdb_at_me(AxiPortParam_t, $sformatf("HOST_AXI_PORT_PARAM"), this.HOST_AXI_PORT_PARAM)
    this.dma_ip_type = ST;
    this.debug($sformatf("ID_WIDTH: %d, HOST_ADDR_WIDTH: %d", HOST_AXI_PORT_PARAM.ID_WIDTH, HOST_AXI_PORT_PARAM.ADDR_WIDTH));
  end
  else if(cfgdb_key == "vdmatb_mm") begin
    `vmg_get_cfgdb_at_me(MmDmaDesignParam_t, $sformatf("%s_MM_DUT_PARAM", cfgdb_key), this.MM_DUT_PARAM)
    `vmg_get_cfgdb_at_me(AxiPortParam_t, $sformatf("HOST_AXI_PORT_PARAM"), this.HOST_AXI_PORT_PARAM)
    `vmg_get_cfgdb_at_me(AxiPortParam_t, $sformatf("CARD_AXI_PORT_PARAM"), this.CARD_AXI_PORT_PARAM)
    this.dma_ip_type = MM;
    this.debug($sformatf("ID_WIDTH: %d, HOST_ADDR_WIDTH: %d, CARD_ADDR_WIDTH: %d", HOST_AXI_PORT_PARAM.ID_WIDTH, HOST_AXI_PORT_PARAM.ADDR_WIDTH, CARD_AXI_PORT_PARAM.ADDR_WIDTH));
  end
  else
    this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.dma_ip_type));
  
endfunction : discoverTestParam


function PerfTestCtrlKnob_t vdmatb_test::makeInitialPerfCtrlKnob(); endfunction
function PerfExpected_t vdmatb_test::calculateExpectedPerfResult(PerfTestCtrlKnob_t ctrl_knob); endfunction
function PerfTestCtrlKnob_t vdmatb_test::randomizePerfCtrlKnob(PerfTestCtrlKnob_t ctrl_knob); endfunction



function void vdmatb_test::decideTbCfg();
  `ifdef TB_IDEAL
    this.tb_scheme = IDEAL;
  `elsif TB_DELAY_ONLY
    this.tb_scheme = ON_DELAY_WO_RESP;
  `elsif FOR_REGRESSION
    this.tb_scheme = FOR_REGRESSION;
  `else
    this.tb_scheme = DEFAULT;
  `endif
 
  this.test_type                         = NORMAL_TEST;
  this.enable_pmon                       = YES;
  this.select_fault                      = SAME_NORMAL_OPERATION;
  this.fault_prob                        = 0;
  this.fault_ratio                       = 0;
  this.decideDataDirectionType();
endfunction:decideTbCfg




function vdma_mst_tcfg vdmatb_test::createMstTcfg();
  vdma_mst_tcfg created;

  created = vdma_mst_tcfg::type_id::create($sformatf("mst_tcfg"));
  
  if(this.dma_ip_type == ST)      created.setStDmaDesignParam(this.ST_DUT_PARAM);
  else if(this.dma_ip_type == MM) created.setMmDmaDesignParam(this.MM_DUT_PARAM);
  else                            this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.dma_ip_type));
  
  created.setDmaIpType(this.dma_ip_type);
  
  return(created);
endfunction:createMstTcfg




function StH2CDmaBfmTimingParam_t vdmatb_test::decideStH2CDmaBfmTimingParam();
  if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
    this.debug("[Check Card] H2C Test Scheme : ASYMMETRIC_LATENCY_TEST");
    return(this.decideStH2CAsymmetricLatencyCfg());
  end// ASYMMETRIC_LATENCY_TEST
  else if(this.tcfg.test_type == PERF_TEST) begin
    if( (this.scfg.perf_ctrl_knob.perf_intr_latency && this.scfg.perf_ctrl_knob.perf_stat_latency) ) begin
      this.debug("[Check Card] H2C Test Scheme : PERF_LONG_TEST");
      return(ST_PERF_H2C_LONG_LATENCY);
    end
    else begin
      this.debug("[Check Card] H2C Test Scheme : PERF_IDEAL_TEST");
      return(ST_PERF_H2C_IDEAL_LATENCY);
    end
  end
  else begin
    if(this.tcfg.tb_scheme == IDEAL) begin
      this.debug("[Check Card] H2C Test Scheme : IDEAL");
      return(IDEAL_ST_H2C_DMA_BFM_TIMING_PARAM);
    end// Asymmetric_scheme
    else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
      this.debug("[Check Card] H2C Test Scheme : FOR_REGRESSION");
      return(DEFAULT_ST_H2C_DMA_BFM_TIMING_PARAM);
    end
    else if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
      this.debug("[Check Card] H2C Test Scheme : ON_DELAY_WO_RESP");
      return(DEFAULT_ST_H2C_DMA_BFM_TIMING_PARAM);
    end
    else
      this.fatal("H2C_TEST_SCHEME_NOT_SUPPORTED", "vdmatb_test has unsupported test scheme type !!");
  end//NOT ASYMMETRIC_LATENCY_TEST
    
endfunction:decideStH2CDmaBfmTimingParam



function StC2HDmaBfmTimingParam_t vdmatb_test::decideStC2HDmaBfmTimingParam();
  if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
    this.debug("[Check Card] C2H Test Scheme : ASYMMETRIC_LATENCY_TEST");
    return(this.decideStC2HAsymmetricLatencyCfg());
  end// ASYMMETRIC_LATENCY_TEST
  else if(this.tcfg.test_type == PERF_TEST) begin
    if( (this.scfg.perf_ctrl_knob.perf_intr_latency && this.scfg.perf_ctrl_knob.perf_stat_latency) ) begin
      this.debug("[Check Card] C2H Test Scheme : PERF_LONG_TEST");
      return(ST_PERF_C2H_LONG_LATENCY);
    end
    else begin
      this.debug("[Check Card] C2H Test Scheme : PERF_IDEAL_TEST");
      return(ST_PERF_C2H_IDEAL_LATENCY);
    end
  end
  else begin
    if(this.tcfg.tb_scheme == IDEAL) begin
      this.debug("[Check Card] C2H Test Scheme : IDEAL");
      return(IDEAL_ST_C2H_DMA_BFM_TIMING_PARAM);
    end// Asymmetric_scheme
    else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
      this.debug("[Check Card] C2H Test Scheme : FOR_REGRESSION");
      return(DEFAULT_ST_C2H_DMA_BFM_TIMING_PARAM);
    end
    else if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
      this.debug("[Check Card] C2H Test Scheme : ON_DELAY_WO_RESP");
      return(DEFAULT_ST_C2H_DMA_BFM_TIMING_PARAM);
    end
    else
      this.fatal("C2H_TEST_SCHEME_NOT_SUPPORTED", "vdmatb_test has unsupported test scheme type !!");
  end//NOT ASYMMETRIC_LATENCY_TEST
endfunction:decideStC2HDmaBfmTimingParam



function MmH2CDmaBfmTimingParam_t vdmatb_test::decideMmH2CDmaBfmTimingParam();
  if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
    this.debug("[Check Card] H2C Test Scheme : ASYMMETRIC_LATENCY_TEST");
    return(this.decideMmH2CAsymmetricLatencyCfg());
  end// ASYMMETRIC_LATENCY_TEST
  else if(this.tcfg.test_type == PERF_TEST) begin
    if( (this.scfg.perf_ctrl_knob.perf_intr_latency && this.scfg.perf_ctrl_knob.perf_stat_latency) ) begin
      this.debug("[Check Card] H2C Test Scheme : PERF_LONG_TEST");
      return(MM_PERF_H2C_LONG_LATENCY);
    end
    else begin
      this.debug("[Check Card] H2C Test Scheme : PERF_IDEAL_TEST");
      return(MM_PERF_H2C_IDEAL_LATENCY);
    end
  end
  else begin
    if(this.tcfg.tb_scheme == IDEAL) begin
      this.debug("[Check Card] H2C Test Scheme : IDEAL");
      return(IDEAL_MM_H2C_DMA_BFM_TIMING_PARAM);
    end// Asymmetric_scheme
    else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
      this.debug("[Check Card] H2C Test Scheme : FOR_REGRESSION");
      return(DEFAULT_MM_H2C_DMA_BFM_TIMING_PARAM);
    end
    else if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
      this.debug("[Check Card] H2C Test Scheme : ON_DELAY_WO_RESP");
      return(DEFAULT_MM_H2C_DMA_BFM_TIMING_PARAM);
    end
    else
      this.fatal("H2C_TEST_SCHEME_NOT_SUPPORTED", "vdmatb_test has unsupported test scheme type !!");
  end//NOT ASYMMETRIC_LATENCY_TEST
endfunction:decideMmH2CDmaBfmTimingParam



function MmC2HDmaBfmTimingParam_t vdmatb_test::decideMmC2HDmaBfmTimingParam();
  if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
    this.debug("[Check Card] C2H Test Scheme : ASYMMETRIC_LATENCY_TEST");
    return(this.decideMmC2HAsymmetricLatencyCfg());
  end// ASYMMETRIC_LATENCY_TEST
  else if(this.tcfg.test_type == PERF_TEST) begin
    if( (this.scfg.perf_ctrl_knob.perf_intr_latency && this.scfg.perf_ctrl_knob.perf_stat_latency) ) begin
      this.debug("[Check Card] C2H Test Scheme : PERF_LONG_TEST");
      return(MM_PERF_C2H_LONG_LATENCY);
    end
    else begin
      this.debug("[Check Card] C2H Test Scheme : PERF_IDEAL_TEST");
      return(MM_PERF_C2H_IDEAL_LATENCY);
    end
  end
  else begin
    if(this.tcfg.tb_scheme == IDEAL) begin
      this.debug("[Check Card] C2H Test Scheme : IDEAL");
      return(IDEAL_MM_C2H_DMA_BFM_TIMING_PARAM);
    end// Asymmetric_scheme
    else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
      this.debug("[Check Card] C2H Test Scheme : FOR_REGRESSION");
      return(DEFAULT_MM_C2H_DMA_BFM_TIMING_PARAM);
    end
    else if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
      this.debug("[Check Card] C2H Test Scheme : ON_DELAY_WO_RESP");
      return(DEFAULT_MM_C2H_DMA_BFM_TIMING_PARAM);
    end
    else
      this.fatal("C2H_TEST_SCHEME_NOT_SUPPORTED", "vdmatb_test has unsupported test scheme type !!");
  end//NOT ASYMMETRIC_LATENCY_TEST
endfunction:decideMmC2HDmaBfmTimingParam



function void vdmatb_test::setupUvmFactory();
  set_type_override_by_type(vt4_env_top::get_type(), vdmatb_env_top::get_type());
  set_type_override_by_type(vt4_senv   ::get_type(), vdmatb_senv   ::get_type());
  set_type_override_by_type(vt4_menv   ::get_type(), vdmatb_menv   ::get_type());
  set_type_override_by_type(vt4_vseqr  ::get_type(), vdmatb_vseqr  ::get_type());
endfunction:setupUvmFactory



function vt4_tcfg vdmatb_test::createTcfg();
  vdmatb_tcfg created;
  
  created = vdmatb_tcfg::type_id::create("tcfg");
  
  created.setDmaIpType(this.dma_ip_type);
  
  if(this.dma_ip_type == ST) begin
    created.setStDmaDutParam(this.ST_DUT_PARAM);
  end
  else if(this.dma_ip_type == MM) begin
    created.setMmDmaDutParam(this.MM_DUT_PARAM);
    created.setCardAxiPortParam(this.CARD_AXI_PORT_PARAM);
  end
  else
    this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.dma_ip_type));
  
  created.setHostAxiPortParam(this.HOST_AXI_PORT_PARAM);
  
  return(created);
endfunction : createTcfg


function vt4_scfg vdmatb_test::createScfg();
  vdmatb_scfg created;

  created = vdmatb_scfg::type_id::create("scfg");
  return(created);
endfunction:createScfg



function void vdmatb_test::setTestPlan(); endfunction


function vdma_pkg::StC2HDmaBfmTimingParam_t vdmatb_test::decideStC2HAsymmetricLatencyCfg();
  localparam START_NUM = 1;
  localparam END_NUM   = 4;

  StC2HDmaBfmTimingParam_t c2h_asymmetric_latency;
  
  int select_desc2desc_latency_cfg = 0;
  int select_data2data_latency_cfg = 0;
  int select_intr2intr_latency_cfg = 0;
  int select_stat2stat_latency_cfg = 0;
  
  select_desc2desc_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
  select_data2data_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
  select_intr2intr_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
  select_stat2stat_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
 
 
  case(DmaLatencyType_t'(select_desc2desc_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] desc2desc is ZERO");
      c2h_asymmetric_latency.desc2desc = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] desc2desc is NORMAL");
      c2h_asymmetric_latency.desc2desc = ASYMMETRIC_DESC_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] desc2desc is LONG");
      c2h_asymmetric_latency.desc2desc = ASYMMETRIC_DESC_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] desc2desc is RANDOM");
      c2h_asymmetric_latency.desc2desc = ASYMMETRIC_DESC_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "desc2desc_latency_cfg is out of range");
  endcase
  
  case(DmaLatencyType_t'(select_data2data_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] data2data is ZERO");
      c2h_asymmetric_latency.data2data = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] data2data is NORMAL");
      c2h_asymmetric_latency.data2data = ASYMMETRIC_DATA_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] data2data is LONG");
      c2h_asymmetric_latency.data2data = ASYMMETRIC_DATA_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] data2data is RANDOM");
      c2h_asymmetric_latency.data2data = ASYMMETRIC_DATA_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "data2data_latency_cfg is out of range");
  endcase
  
  case(DmaLatencyType_t'(select_intr2intr_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] intr2intr is ZERO");
      c2h_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] intr2intr is NORMAL");
      c2h_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_INTR_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] intr2intr is LONG");
      c2h_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_INTR_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] intr2intr is RANDOM");
      c2h_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_INTR_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "intr2intr_latency_cfg is out of range");
  endcase
  
  case(DmaLatencyType_t'(select_stat2stat_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] stat2stat is ZERO");
      c2h_asymmetric_latency.status_assert_rdy = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] stat2stat is NORMAL");
      c2h_asymmetric_latency.status_assert_rdy = ASYMMETRIC_STAT_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] stat2stat is LONG");
      c2h_asymmetric_latency.status_assert_rdy = ASYMMETRIC_STAT_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] stat2stat is RANDOM");
      c2h_asymmetric_latency.status_assert_rdy = ASYMMETRIC_STAT_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "stat2stat_latency_cfg is out of range");
  endcase
  
  
  return(c2h_asymmetric_latency);
endfunction : decideStC2HAsymmetricLatencyCfg


function vdma_pkg::StH2CDmaBfmTimingParam_t vdmatb_test::decideStH2CAsymmetricLatencyCfg();
  localparam START_NUM = 1;
  localparam END_NUM   = 4;

  StH2CDmaBfmTimingParam_t h2c_asymmetric_latency;
  
  int select_desc2desc_latency_cfg = 0;
  int select_data2data_latency_cfg = 0;
  int select_intr2intr_latency_cfg = 0;
  int select_stat2stat_latency_cfg = 0;
  
  select_desc2desc_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
  select_data2data_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
  select_intr2intr_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
  select_stat2stat_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
 
 
  case(DmaLatencyType_t'(select_desc2desc_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] desc2desc is ZERO");
      h2c_asymmetric_latency.desc2desc = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] desc2desc is NORMAL");
      h2c_asymmetric_latency.desc2desc = ASYMMETRIC_DESC_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] desc2desc is LONG");
      h2c_asymmetric_latency.desc2desc = ASYMMETRIC_DESC_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] desc2desc is RANDOM");
      h2c_asymmetric_latency.desc2desc = ASYMMETRIC_DESC_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "desc2desc_latency_cfg is out of range");
  endcase
  
  case(DmaLatencyType_t'(select_data2data_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] data2data is ZERO");
      h2c_asymmetric_latency.data_assert_rdy = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] data2data is NORMAL");
      h2c_asymmetric_latency.data_assert_rdy = ASYMMETRIC_DATA_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] data2data is LONG");
      h2c_asymmetric_latency.data_assert_rdy = ASYMMETRIC_DATA_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] data2data is RANDOM");
      h2c_asymmetric_latency.data_assert_rdy = ASYMMETRIC_DATA_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "data2data_latency_cfg is out of range");
  endcase
  
  case(DmaLatencyType_t'(select_intr2intr_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] intr2intr is ZERO");
      h2c_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] intr2intr is NORMAL");
      h2c_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_INTR_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] intr2intr is LONG");
      h2c_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_INTR_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] intr2intr is RANDOM");
      h2c_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_INTR_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "intr2intr_latency_cfg is out of range");
  endcase
  
  case(DmaLatencyType_t'(select_stat2stat_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] stat2stat is ZERO");
      h2c_asymmetric_latency.status_assert_rdy = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] stat2stat is NORMAL");
      h2c_asymmetric_latency.status_assert_rdy = ASYMMETRIC_STAT_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] stat2stat is LONG");
      h2c_asymmetric_latency.status_assert_rdy = ASYMMETRIC_STAT_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] stat2stat is RANDOM");
      h2c_asymmetric_latency.status_assert_rdy = ASYMMETRIC_STAT_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "stat2stat_latency_cfg is out of range");
  endcase
  
  return(h2c_asymmetric_latency);
endfunction : decideStH2CAsymmetricLatencyCfg



function vdma_pkg::MmC2HDmaBfmTimingParam_t vdmatb_test::decideMmC2HAsymmetricLatencyCfg();
  localparam START_NUM = 1;
  localparam END_NUM   = 4;

  MmC2HDmaBfmTimingParam_t c2h_asymmetric_latency;
  
  int select_desc2desc_latency_cfg = 0;
  int select_intr2intr_latency_cfg = 0;
  int select_stat2stat_latency_cfg = 0;
  
  select_desc2desc_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
  select_intr2intr_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
  select_stat2stat_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
 
 
  case(DmaLatencyType_t'(select_desc2desc_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] desc2desc is ZERO");
      c2h_asymmetric_latency.desc2desc = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] desc2desc is NORMAL");
      c2h_asymmetric_latency.desc2desc = ASYMMETRIC_DESC_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] desc2desc is LONG");
      c2h_asymmetric_latency.desc2desc = ASYMMETRIC_DESC_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] desc2desc is RANDOM");
      c2h_asymmetric_latency.desc2desc = ASYMMETRIC_DESC_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "desc2desc_latency_cfg is out of range");
  endcase
  
  case(DmaLatencyType_t'(select_intr2intr_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] intr2intr is ZERO");
      c2h_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] intr2intr is NORMAL");
      c2h_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_INTR_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] intr2intr is LONG");
      c2h_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_INTR_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] intr2intr is RANDOM");
      c2h_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_INTR_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "intr2intr_latency_cfg is out of range");
  endcase
  
  case(DmaLatencyType_t'(select_stat2stat_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] stat2stat is ZERO");
      c2h_asymmetric_latency.status_assert_rdy = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] stat2stat is NORMAL");
      c2h_asymmetric_latency.status_assert_rdy = ASYMMETRIC_STAT_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] stat2stat is LONG");
      c2h_asymmetric_latency.status_assert_rdy = ASYMMETRIC_STAT_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[C2H_ASYMMETRIC_LATENCY_TEST] stat2stat is RANDOM");
      c2h_asymmetric_latency.status_assert_rdy = ASYMMETRIC_STAT_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "stat2stat_latency_cfg is out of range");
  endcase
  
  
  return(c2h_asymmetric_latency);
endfunction : decideMmC2HAsymmetricLatencyCfg


function vdma_pkg::MmH2CDmaBfmTimingParam_t vdmatb_test::decideMmH2CAsymmetricLatencyCfg();
  localparam START_NUM = 1;
  localparam END_NUM   = 4;

  MmH2CDmaBfmTimingParam_t h2c_asymmetric_latency;
  
  int select_desc2desc_latency_cfg = 0;
  int select_intr2intr_latency_cfg = 0;
  int select_stat2stat_latency_cfg = 0;
  
  select_desc2desc_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
  select_intr2intr_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
  select_stat2stat_latency_cfg = this.pickRandUIntInTheRange2(START_NUM, END_NUM);
 
 
  case(DmaLatencyType_t'(select_desc2desc_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] desc2desc is ZERO");
      h2c_asymmetric_latency.desc2desc = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] desc2desc is NORMAL");
      h2c_asymmetric_latency.desc2desc = ASYMMETRIC_DESC_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] desc2desc is LONG");
      h2c_asymmetric_latency.desc2desc = ASYMMETRIC_DESC_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] desc2desc is RANDOM");
      h2c_asymmetric_latency.desc2desc = ASYMMETRIC_DESC_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "desc2desc_latency_cfg is out of range");
  endcase
  
  case(DmaLatencyType_t'(select_intr2intr_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] intr2intr is ZERO");
      h2c_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] intr2intr is NORMAL");
      h2c_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_INTR_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] intr2intr is LONG");
      h2c_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_INTR_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] intr2intr is RANDOM");
      h2c_asymmetric_latency.interrupt_assert_rdy = ASYMMETRIC_INTR_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "intr2intr_latency_cfg is out of range");
  endcase
  
  case(DmaLatencyType_t'(select_stat2stat_latency_cfg)) 
    DMA_ZERO_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] stat2stat is ZERO");
      h2c_asymmetric_latency.status_assert_rdy = ASYMMETRIC_ZERO_TYPE;
    end//ZERO
    DMA_NORMAL_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] stat2stat is NORMAL");
      h2c_asymmetric_latency.status_assert_rdy = ASYMMETRIC_STAT_NORMAL_TYPE;
    end//NORMAL
    DMA_LONG_LATENCY   : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] stat2stat is LONG");
      h2c_asymmetric_latency.status_assert_rdy = ASYMMETRIC_STAT_LONG_TYPE;
    end//LONG
    DMA_RANDOM_LATENCY : begin
      this.debug("[H2C_ASYMMETRIC_LATENCY_TEST] stat2stat is RANDOM");
      h2c_asymmetric_latency.status_assert_rdy = ASYMMETRIC_STAT_RANDOM_TYPE;
    end//RANDOM
    default : this.fatal("ASYMMETRIC_LATENCY_TEST", "stat2stat_latency_cfg is out of range");
  endcase
  
  return(h2c_asymmetric_latency);
endfunction : decideMmH2CAsymmetricLatencyCfg


function void vdmatb_test::decideDataDirectionType();
  this.data_direction_type.only_c2h_test = YES;
  this.data_direction_type.only_h2c_test = YES;
endfunction : decideDataDirectionType


function void vdmatb_test::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  uvm_top.print_topology();
endfunction : end_of_elaboration_phase


`endif // __VDMATB_TEST_SVH__
