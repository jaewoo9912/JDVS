`ifndef __VDMATB_SB_SVH__
`define __VDMATB_SB_SVH__

`uvm_analysis_imp_decl(_mst_desc)
`uvm_analysis_imp_decl(_mst_data)
`uvm_analysis_imp_decl(_mst_intr)
`uvm_analysis_imp_decl(_mst_status)
`uvm_analysis_imp_decl(_mst_fault)
`uvm_analysis_imp_decl(_host_data)
`uvm_analysis_imp_decl(_card_h2c_data)
`uvm_analysis_imp_decl(_card_c2h_data)
`uvm_analysis_imp_decl(_mst_completed)

virtual class vdmatb_sb#(
    parameter  type  T_SEQ_ITEM  = vdma_seq_item,
    parameter  type  T_SEQ_ITEM2 = vdmatb_host_seq_item,
    parameter  type  T_SEQ_ITEM3 = vdma_pkt_seq_item,
    parameter  type  T_SEQ_ITEM4 = vdma_card_axi_seq_item,
    localparam type  T_TRANS     = T_SEQ_ITEM,
    localparam type  T_TRANS2    = T_SEQ_ITEM2,
    localparam type  T_TRANS3    = T_SEQ_ITEM3,
    localparam type  T_TRANS4    = T_SEQ_ITEM4
  )extends vmg_scoreboard;

  

  uvm_analysis_imp_mst_desc        #(T_TRANS, vdmatb_sb) ap_mst_desc;
  uvm_analysis_imp_mst_data        #(T_TRANS, vdmatb_sb) ap_mst_data;
  uvm_analysis_imp_mst_intr        #(T_TRANS, vdmatb_sb) ap_mst_intr;
  uvm_analysis_imp_mst_status      #(T_TRANS, vdmatb_sb) ap_mst_status;
  uvm_analysis_imp_mst_fault       #(T_TRANS, vdmatb_sb) ap_mst_fault;
  uvm_analysis_imp_host_data       #(T_TRANS2, vdmatb_sb) ap_host_data;
  uvm_analysis_imp_card_h2c_data   #(T_TRANS4, vdmatb_sb) ap_card_h2c_data;
  uvm_analysis_imp_card_c2h_data   #(T_TRANS4, vdmatb_sb) ap_card_c2h_data;
  uvm_analysis_imp_mst_completed   #(T_TRANS, vdmatb_sb) ap_mst_completed;
  
  local vdma_mst_tcfg tcfg;
  
  vdmatb_st_sb_cov_colctr st_sb_cov_colctr;
  vdmatb_mm_sb_cov_colctr mm_sb_cov_colctr;
  
  protected  StDmaDesignParam_t  ST_DUT_PARAM;
  protected  MmDmaDesignParam_t  MM_DUT_PARAM;
  protected  HStrb_t             max_host_wstrb;
  protected  CStrb_t             max_card_wstrb;
  protected  ScoreboardFlag_t    sb_flag;
  
  int act_flt_count = 0;
  int card_data_size;
 
 
  event ev_need_inter_reset;

  protected DmaTransType_t trans_type;
  protected string sb_name;
  
  T_TRANS3 q_active_pkt[$];
  T_TRANS3 q_completed_pkt[$];
  
  T_TRANS2    q_expected_host_data[$] , q_actual_host_data[$];
  T_TRANS2    q_expected_mst_data[$]  , q_actual_mst_data[$];
  T_TRANS4    q_expected_card_data[$] , q_actual_card_data[$];
  Interrupt_t q_expected_intr[$]      , q_actual_intr[$];

  Interrupt_t q_expected_desc_fault_intr[$], q_actual_desc_fault_intr[$];
  Interrupt_t q_expected_card_fault_intr[$], q_actual_card_fault_intr[$];
  Interrupt_t q_expected_host_fault_intr[$], q_actual_host_fault_intr[$];

  Status_t    q_expected_status[$]    , q_actual_status[$];

  Fault_t     q_expected_desc_fault[$]     , q_actual_desc_fault[$];
  Fault_t     q_expected_card_fault[$]     , q_actual_card_fault[$];
  Fault_t     q_expected_host_fault[$]     , q_actual_host_fault[$];
  Fault_t     last_actual_fault;
  
  Interrupt_t   q_intr_split[$];
  Fault_t       q_fault_split[$];
            
  YesOrNo_t result_wdma_id = NO;
  
  T_TRANS2    q_expected_host_req[$];
  T_TRANS4    q_expected_card_req[$];

  typedef struct {
    DmaId_t                        dma_id;
    logic[`SVT_AXI_RESP_WIDTH-1:0] resp;
  }CovWrongResp_t;
  
  typedef struct {
    DmaId_t dma_id;
    int     fault_code;
  }CovFault_t;
  
  typedef CovFault_t CovFaultQ_t[$];
  
  CovWrongResp_t q_actual_fault_host_b_wrong_resp[$];
  CovWrongResp_t q_expected_fault_host_b_wrong_resp[$];
  CovWrongResp_t q_actual_fault_host_r_wrong_resp[$];
  CovWrongResp_t q_expected_fault_host_r_wrong_resp[$];
  
  CovWrongResp_t q_actual_fault_card_b_wrong_resp[$];
  CovWrongResp_t q_expected_fault_card_b_wrong_resp[$];
  CovWrongResp_t q_actual_fault_card_r_wrong_resp[$];
  CovWrongResp_t q_expected_fault_card_r_wrong_resp[$];
  
  CovFault_t q_cov_card_fault[$];
  CovFault_t q_cov_desc_fault[$];
  CovFault_t q_cov_desc_data_length_is_zero[$];
  // ----- protocol fault
  CovFault_t q_cov_expected_fault_host_r_no_last[$];
  CovFault_t q_cov_actual_fault_host_r_no_last[$];
  CovFault_t q_cov_expected_fault_host_r_premature_last[$];
  CovFault_t q_cov_actual_fault_host_r_premature_last[$];


  `vdmatb_rptr_utils
  function new (string name = "vdmatb_sb", uvm_component parent);
    super.new(name, parent);
    `vdmatb_rptr_impl_in_new
//    this.enableDebugMode();
  endfunction



  // ---------------------------- uvm built-in
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);


  // ---------------------------- vdmatb_sb built-in
  extern virtual protected function void extractDb();
  extern function int getDataSize();
  extern virtual function YesOrNo_t isBusy();
  extern protected function void resetSB();
  extern virtual function void callbackReset();

  extern virtual protected function string getReportHeader();
  extern virtual function void showHistory(string prompt);


  // ---------------------------- vdmatb_sb built-in (subscriber)
  extern virtual function void write_mst_desc(T_TRANS trans);
  extern virtual function void write_mst_data(T_TRANS trans);
  extern virtual function void write_mst_intr(T_TRANS trans);
  extern virtual function void write_mst_status(T_TRANS trans);
  extern virtual function void write_mst_fault(T_TRANS trans);
  extern virtual function void write_host_data(T_TRANS2 trans);
  extern virtual function void write_card_h2c_data(T_TRANS4 trans); // kitec3
  extern virtual function void write_card_c2h_data(T_TRANS4 trans); // kitec3
  extern virtual function void write_mst_completed(T_TRANS trans);


  // ---------------------------- vdmatb_sb built-in (behavior)
  extern virtual protected task updateActiveQ();
  extern virtual function void  updateState();
  extern virtual function void  registerNewPkt(T_TRANS trans);
  extern virtual function void  post_registerNewPkt(T_TRANS3 trans, T_TRANS trans2);
  extern virtual function void  updateMstData(T_TRANS trans); // kitec3
  extern virtual function void  post_updateMstData(T_TRANS3 trans, T_TRANS trans2); // kitec3
  extern virtual function void  updateHostData(T_TRANS2 trans);
  extern virtual function void  post_updateHostData(T_TRANS3 trans, T_TRANS2 trans2);
  extern virtual function void  updateCardData(T_TRANS4 trans); // kitec3
  extern virtual function void  post_updateCardData(T_TRANS3 trans, T_TRANS4 trans2); // kitec3
  extern virtual function void  updateInterrupt(T_TRANS trans);
  extern virtual function void  updateStatus(T_TRANS trans);
  extern virtual function void  updateFault(T_TRANS trans);
  
  extern virtual task          doDataPathChecker();
  extern virtual task          cardIntrChecker();
  extern virtual task          cardStatusChecker();

  extern virtual task          descFaultStatChecker();
  extern virtual task          cardFaultStatChecker();
  extern virtual task          hostFaultStatChecker();
  extern virtual task          descFaultIntrChecker();
  extern virtual task          cardFaultIntrChecker();
  extern virtual task          hostFaultIntrChecker();
  
  extern virtual task          splitForFaultIntr();
  
  extern protected function T_TRANS3 findPkt(DmaPktStatus_t pkt_status, DmaId_t dma_id, string call_info);
  extern protected function T_TRANS3 findDesc(DmaPktStatus_t pkt_status, DmaId_t dma_id, StrId_t str_id, string call_info);

  extern protected function T_TRANS3 findPkt_MustSuccess(DmaPktStatus_t pkt_status, DmaId_t dma_id, string call_info);
  extern protected function T_TRANS3 findDesc_MustSuccess(DmaPktStatus_t pkt_status, DmaId_t dma_id, StrId_t str_id, string call_info);

  extern protected function T_TRANS3 findPkt_ExpectedHost(DmaPktStatus_t pkt_status, T_TRANS2 trans);
  extern protected function T_TRANS3 findPkt_ExpectedCard(DmaPktStatus_t pkt_status, T_TRANS4 trans);

  extern protected function YesOrNo_t compareIntr(Interrupt_t actual, Interrupt_t expected);
  extern protected function YesOrNo_t compareStatus(Status_t actual, Status_t expected);
  
  extern virtual function YesOrNo_t checkFaultOnDesc(T_TRANS3 trans, T_TRANS trans2);
  extern virtual function YesOrNo_t checkFaultOnMstData(T_TRANS3 trans, T_TRANS trans2);

 extern virtual function YesOrNo_t descFaultCodeCheck(Fault_t found);
 extern virtual function YesOrNo_t cardFaultCodeCheck(Fault_t found);
 extern virtual function YesOrNo_t hostFaultCodeCheck(Fault_t found);

  // ---------------------------- vdmatb_sb built-in (utility)
  extern virtual function Len_t               getTotalHostBurst(Desc_t desc);
  extern virtual function Len_t               getTotalCardBurst(Desc_t desc);
  extern virtual function DutParamAxiMaxLen_t updateCurrHostBurstLen(Addr_t cAddr, Addr_t nAddr);
  extern virtual function DutParamAxiMaxLen_t updateCurrCardBurstLen(Addr_t cAddr, Addr_t nAddr);

  extern virtual function Addr_t         calculateNextHostAddr     (Addr_t addr, DutParamAxiMaxLen_t maxBurstLen, Addr_t endAddr);
  extern virtual function Addr_t         calculateNextCardAddr     (Addr_t addr, DutParamAxiMaxLen_t maxBurstLen, Addr_t endAddr);
  extern virtual function CData_t        andWithStrb           (CData_t inData, CStrb_t strb);

  pure virtual function void sampleDesc(T_TRANS trans);
  pure virtual function DmaTransType_t getTransType();
  pure virtual task cardDataChecker();
  pure virtual task hostDataChecker();
  
  extern protected function int calculate_data_width_gap();
  
  extern local function void doOnDescFaultForCov(T_TRANS trans, Fault_t found_fault);
  extern local function void doOnCardFaultForCov(T_TRANS trans, Fault_t found_fault);
  extern local function void doOnHostFaultForCov(T_TRANS trans, Fault_t found_fault);
  
  extern local function FaultCode_t ChkWhatTypeOfHostFault();
 
  extern local function void doForFaultCovCollect(T_TRANS3 completed);
  extern local function void doOnDataLenZeroFault_wo_following_trans(T_TRANS trans, Fault_t fault);
  extern local function void doOnDataLenZeroFault_with_following_trans(T_TRANS3 completed);
  extern local function void doOnCompletedHostFault(T_TRANS3 completed);
  extern local function void doOnCompletedDescFault(T_TRANS3 completed);
  extern local function void doOnCompletedCardFault(T_TRANS3 completed);
  extern local function void doOnCompletedCardWrongRespFault(T_TRANS3 completed);
  
  extern local function void doOnCompletedHostRWrongRespFault(T_TRANS3 completed);
  extern local function void doOnCompletedHostBWrongRespFault(T_TRANS3 completed);
  extern local function void doOnCompletedHostRNoLastFault(T_TRANS3 completed);
  extern local function void doOnCompletedHostRPrematureFault(T_TRANS3 completed);
  
endclass:vdmatb_sb




function void vdmatb_sb::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  this.ap_mst_desc       = new("ap_mst_desc", this);
  this.ap_mst_data       = new("ap_mst_data", this);
  this.ap_mst_intr       = new("ap_mst_intr", this);
  this.ap_mst_status     = new("ap_mst_status", this);
  this.ap_mst_fault      = new("ap_mst_fault", this);
  this.ap_host_data      = new("ap_host_data", this);
  this.ap_card_h2c_data  = new("ap_card_h2c_data", this);
  this.ap_card_c2h_data  = new("ap_card_c2h_data", this);
  this.ap_mst_completed  = new("ap_mst_completed", this);
  
  this.sb_flag.flag_cardData      = YES;
  this.sb_flag.flag_c2h_hostData  = YES;
  this.sb_flag.flag_h2c_hostData  = YES;
  this.sb_flag.flag_cardIntr      = YES;
  this.sb_flag.flag_cardStat      = YES;

  this.sb_flag.flag_descFaultStat     = YES;
  this.sb_flag.flag_cardFaultStat     = YES;
  this.sb_flag.flag_hostFaultStat     = YES;
  this.sb_flag.flag_descFaultIntr     = YES;
  this.sb_flag.flag_cardFaultIntr     = YES;
  this.sb_flag.flag_hostFaultIntr     = YES;
  
  this.trans_type = this.getTransType();
  this.sb_name = $sformatf("VDMATB_%s_SB", this.trans_type.name);

  this.max_host_wstrb = 1;
  for(int i = 0; i < HOST_DATA_BYTE_WIDTH; i++)
    this.max_host_wstrb = (this.max_host_wstrb << 1) | 1;

  this.max_card_wstrb = 1;
  for(int i = 0; i < CARD_DATA_BYTE_WIDTH; i++)
    this.max_card_wstrb = (this.max_card_wstrb << 1) | 1;

  this.st_sb_cov_colctr = vdmatb_st_sb_cov_colctr#()::type_id::create();
  this.mm_sb_cov_colctr = vdmatb_mm_sb_cov_colctr#()::type_id::create();
endfunction:build_phase


function void vdmatb_sb::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  this.extractDb();
  
  this.card_data_size = this.getDataSize();
  
endfunction:connect_phase



task vdmatb_sb::run_phase(uvm_phase phase);
  
  this.setPrompt($sformatf("[%s]", this.getReportHeader));
  
  
  fork
    begin:MAIN
      fork
        begin:CONTROL_PATH
          this.updateActiveQ();
        end
        begin:DATA_PATH
          this.doDataPathChecker();
        end
      join
    end // MAIN
    
    begin:INTER_RESET
      forever begin
        @this.ev_need_inter_reset;
        // There is no requirement on INTER_RESET by event-driven
        this.fatalShallImpl("Need to implement INTER_RESET");
      end
    end // INTER_RESET
  join
  
  
endtask:run_phase



function void vdmatb_sb::write_mst_desc(T_TRANS trans);
  this.debug($sformatf("DESC received, desc=[%s]", trans.getInfo()));
  this.sampleDesc(trans);
  this.registerNewPkt(trans);
endfunction:write_mst_desc

function void vdmatb_sb::write_mst_data(T_TRANS trans);
  this.debug($sformatf("CARD_DATA received, desc=[%s]", trans.getInfo()));
  this.updateMstData(trans); // kitec3
endfunction:write_mst_data

function void vdmatb_sb::write_mst_intr(T_TRANS trans);
  this.debug($sformatf("INTR received, desc=[%s]", trans.getInfo()));
  this.updateInterrupt(trans);
endfunction:write_mst_intr

function void vdmatb_sb::write_mst_status(T_TRANS trans);
  this.debug($sformatf("STATUS received, desc=[%s]", trans.getInfo()));
  this.updateStatus(trans);
endfunction:write_mst_status

function void vdmatb_sb::write_mst_fault(T_TRANS trans);
  this.debug($sformatf("FAULT received, desc=[%s]", trans.getInfo()));
  this.updateFault(trans);
endfunction:write_mst_fault

function void vdmatb_sb::write_host_data(T_TRANS2 trans);
  this.debug($sformatf("HOST_DATA received, rresp=%0d, araddr=0x%0h", trans.rresp, trans.araddr));
  this.updateHostData(trans);
endfunction:write_host_data

function void vdmatb_sb::write_card_h2c_data(T_TRANS4 trans); // kitec3
  this.debug($sformatf("CARD_H2C_DATA received, rresp=%0d", trans.rresp));
  this.updateCardData(trans);
endfunction:write_card_h2c_data

function void vdmatb_sb::write_card_c2h_data(T_TRANS4 trans); // kitec3
  this.debug($sformatf("CARD_C2H_DATA received, rresp=%0d", trans.rresp));
  this.updateCardData(trans);
endfunction:write_card_c2h_data

function void vdmatb_sb::write_mst_completed(T_TRANS trans);
  this.debug($sformatf("DESC_COMPLETED received, dma_id=%0d", trans.getDmaId()));
endfunction:write_mst_completed


function void vdmatb_sb::extractDb();
  `vmg_get_cfgdb_at_me(vdma_mst_tcfg, "tcfg", this.tcfg)
  if(this.getTransType == ST_C2H || this.getTransType == ST_H2C)
    this.ST_DUT_PARAM = this.tcfg.getStDmaDesignParam();
  else if(this.getTransType == MM_C2H || this.getTransType == MM_H2C)
    this.MM_DUT_PARAM = this.tcfg.getMmDmaDesignParam();
  else
    this.fatal("EXTRACT_DB", "Cannot find Trans Type");

endfunction:extractDb

function int vdmatb_sb::getDataSize();
  return(this.tcfg.getDataSize(this.trans_type));
endfunction:getDataSize

function YesOrNo_t vdmatb_sb::isBusy();
  YesOrNo_t result = NO;
  
  if( this.q_active_pkt.size > 0 ) result = YES;
  if( this.q_expected_intr.size > 0 ) result = YES;
  if( this.q_expected_status.size > 0 ) result = YES;
  if( this.q_expected_host_data.size > 0 ) result = YES;
  if( this.q_expected_card_data.size > 0 ) result = YES;
  if( this.q_expected_mst_data.size > 0  ) result = YES;

  if( this.q_expected_desc_fault.size > 0 ) result = YES;
  if( this.q_expected_card_fault.size > 0 ) result = YES;
  if( this.q_expected_host_fault.size > 0 ) result = YES;
  if( this.q_expected_desc_fault_intr.size > 0 ) result = YES;
  if( this.q_expected_card_fault_intr.size > 0 ) result = YES;
  if( this.q_expected_host_fault_intr.size > 0 ) result = YES;
  
  if( this.sb_flag.flag_c2h_hostData  == NO )  result = YES;
  if( this.sb_flag.flag_h2c_hostData  == NO )  result = YES;
  if( this.sb_flag.flag_cardData      == NO )  result = YES;
  if( this.sb_flag.flag_cardIntr      == NO )  result = YES;
  if( this.sb_flag.flag_cardStat      == NO )  result = YES;

  if( this.sb_flag.flag_descFaultStat     == NO )  result = YES;
  if( this.sb_flag.flag_cardFaultStat     == NO )  result = YES;
  if( this.sb_flag.flag_hostFaultStat     == NO )  result = YES;
  if( this.sb_flag.flag_descFaultIntr     == NO )  result = YES;
  if( this.sb_flag.flag_cardFaultIntr     == NO )  result = YES;
  if( this.sb_flag.flag_hostFaultIntr     == NO )  result = YES;
  
  if( this.q_fault_split.size > 0 ) result = YES;
  if( this.q_intr_split.size > 0 )  result = YES;
  
  if(result == YES) begin

    this.debug($sformatf("[IsBusy] active_pkt=%0d, intr=%0d, stat=%0d, hdata=%0d, cdata=%0d, fault_desc_stat=%0d, fault_card_stat=%0d, fault_host_stat=%0d, fault_desc_intr=%0d, fault_card_intr=%0d, fault_host_intr=%0d",
        this.q_active_pkt.size(), this.q_expected_intr.size(), this.q_expected_status.size(), this.q_expected_host_data.size(), this.q_expected_card_data.size(), this.q_expected_desc_fault.size(), this.q_expected_card_fault.size(), this.q_expected_host_fault.size(), this.q_expected_desc_fault_intr.size(), this.q_expected_card_fault_intr.size(), this.q_expected_host_fault_intr.size()));

    this.debug($sformatf("[IsBusy] q_fault_split=%0d, q_intr_split=0%d", this.q_fault_split.size, this.q_intr_split.size));

    this.debug($sformatf("[IsBusy] c2h_hostData=%s / h2c_hostData=%s / cardData=%s / cardIntr=%s / cardStat=%s / descFaultStat=%s / cardFaultStat=%s / hostFaultStat=%s / descFaultIntr=%s / cardFaultIntr=%s / hostFaultIntr=%s",
        this.sb_flag.flag_c2h_hostData, this.sb_flag.flag_h2c_hostData, this.sb_flag.flag_cardData,this.sb_flag.flag_cardIntr, this.sb_flag.flag_cardStat,
        this.sb_flag.flag_descFaultStat, this.sb_flag.flag_cardFaultStat, this.sb_flag.flag_hostFaultStat, this.sb_flag.flag_descFaultIntr, this.sb_flag.flag_cardFaultIntr, this.sb_flag.flag_hostFaultIntr));
  end
  return(result);
endfunction:isBusy

function void vdmatb_sb::resetSB();
  this.warning("[RESET_SB] Start reset on Scoreboard!!");
  
  this.q_active_pkt.delete();
  this.q_completed_pkt.delete();
  
  this.q_expected_host_data.delete();
  this.q_actual_host_data.delete();
  this.q_expected_card_data.delete();
  this.q_actual_card_data.delete();
  this.q_expected_intr.delete();
  this.q_actual_intr.delete();

  this.q_expected_desc_fault_intr.delete();
  this.q_expected_card_fault_intr.delete();
  this.q_expected_host_fault_intr.delete();

  this.q_actual_desc_fault_intr.delete();
  this.q_actual_card_fault_intr.delete();
  this.q_actual_host_fault_intr.delete();

  this.q_expected_status.delete();
  this.q_actual_status.delete();

  this.q_expected_desc_fault.delete();
  this.q_expected_card_fault.delete();
  this.q_expected_host_fault.delete();
 
  this.q_actual_desc_fault.delete();
  this.q_actual_card_fault.delete();
  this.q_actual_host_fault.delete();
  
  this.q_expected_host_req.delete();
  this.q_expected_card_req.delete();

  this.callbackReset();
  
  this.warning("[RESET_SB] Finish reset on Scoreboard!!");
  
endfunction:resetSB

function void vdmatb_sb::callbackReset();
endfunction:callbackReset


function string vdmatb_sb::getReportHeader();
  return(this.sb_name);
endfunction:getReportHeader


function void vdmatb_sb::showHistory(string prompt);
  this.showReportHeader(this.sb_name, prompt);
endfunction:showHistory



task vdmatb_sb::updateActiveQ();
  forever begin
    this.waitCycle();
    this.updateState();
  end
endtask:updateActiveQ


function void vdmatb_sb::updateState();
  T_TRANS3 completed;
  int found_idx = 0;
  int delete = 0;
  int cur_size = 0;

  if(this.q_active_pkt.size > 0) begin
    foreach(this.q_active_pkt[i]) begin
      if( this.q_active_pkt[i].isCompleted() == YES ) begin
        completed = this.q_active_pkt[i];
       
        this.doForFaultCovCollect(completed);

        if((completed.trans_type == ST_H2C || completed.trans_type == MM_H2C) && this.q_expected_host_req.size > 0) begin
          cur_size = this.q_expected_host_req.size();
          for(int j=0; j<cur_size; j++) begin // TODO : If SB Error is generated, Check this
            if(DutParamDmaId_t'(completed.pkt_dma_id) == DutParamDmaId_t'(this.q_expected_host_req[found_idx].dma_id)) begin
              this.debug($sformatf("[UPDATE_STATE] PKT#%0d q_expected_host_req.delete(%0d) / %0d, cur_size:%0d", completed.pkt_dma_id, found_idx, this.q_expected_host_req.size(), cur_size));
              this.q_expected_host_req.delete(found_idx);
            end
            else
              found_idx++;
          end
        end

        if(completed.trans_type == MM_C2H && this.q_expected_card_req.size > 0) begin
          cur_size = this.q_expected_card_req.size();
          for(int j=0; j<cur_size; j++) begin // TODO : If SB Error is generated, Check this
            if(DutParamDmaId_t'(completed.pkt_dma_id) == DutParamDmaId_t'(this.q_expected_card_req[found_idx].dma_id)) begin
              this.debug($sformatf("[UPDATE_STATE] PKT#%0d q_expected_card_req.delete(%0d) / %0d, cur_size:%0d", completed.pkt_dma_id, found_idx, this.q_expected_card_req.size(), cur_size));
              this.q_expected_card_req.delete(found_idx);
            end
            else
              found_idx++;
          end
        end
        
        found_idx = 0; 
        this.q_active_pkt.delete(i);
        this.q_completed_pkt.push_back(completed);
        this.q_completed_pkt.delete();
        
        this.debug($sformatf("[COMPLETED_PKT] PKT#%0d: has_last_mst=%0d, has_last_cdata=%0d, has_last_hdata=%0d, intr=%0d/%0d, stat=%0d/%0d",
          DutParamDmaId_t'(completed.pkt_dma_id), completed.has_last_mst, completed.has_last_cdata, completed.has_last_hdata, completed.has_complete_intr, completed.need_intr, completed.has_complete_status, completed.need_status));
        this.debug($sformatf("[COMPLETED_PKT] Now has %0d active_pkts, %0d completed_pkts", this.q_active_pkt.size, this.q_completed_pkt.size));
        
        this.debug("[COMPLETED_PKT] Active PKT list");
        foreach(this.q_active_pkt[i]) begin
          this.debug($sformatf("[ACTIVE_PKT_LIST] PKT#%0d: mst=%0d, cdata=%0d, hdata=%0d, intr=%0d/%0d, status=%0d/%0d",
              DutParamDmaId_t'(this.q_active_pkt[i].pkt_dma_id), this.q_active_pkt[i].has_last_mst, this.q_active_pkt[i].has_last_cdata, this.q_active_pkt[i].has_last_hdata, this.q_active_pkt[i].has_complete_intr, this.q_active_pkt[i].need_intr, this.q_active_pkt[i].has_complete_status, this.q_active_pkt[i].need_status));
        end
      end
      
    end
    
  end
  
endfunction:updateState



function void vdmatb_sb::registerNewPkt(T_TRANS trans);
  T_TRANS3    found;
  Interrupt_t created_intr;
  Status_t    created_status;
  Len_t       total_hburst_len;
  Len_t       total_cburst_len;
  
  found = this.findPkt(ON_DESC_PHASE, DutParamDmaId_t'(trans.getDmaId()), "NEW_PKT");
  
  // KTSB-1 : If the desc is first of pkt, create pkt
  if( found == null ) begin
    found = T_TRANS3::type_id::create();
    found.pkt_dma_id         = DutParamDmaId_t'(trans.desc.dma_id);
    found.trans_type         = trans.getTransType();
    found.cdata_width        = trans.getDataSize();
    found.intended_faultType = trans.intended_faultType;
    this.q_active_pkt.push_back(found);
  end
  
  // KTSB-2 : Check Fault case on Desc
  if( this.checkFaultOnDesc(found, trans) == YES ) return;
  
  
  total_hburst_len = this.getTotalHostBurst(trans.desc);
  total_cburst_len = this.getTotalCardBurst(trans.desc);
  // KTSB-18 : update PKT information with desc
  found.updateByMst(trans, total_hburst_len, total_cburst_len);
  
  this.debug($sformatf("[NEW/UPDATE_PKT] PKT#%0d: num_desc=%0d, pkt_len=%0d, req_intr/stat=%0d/%0d, has_last_mst=%s, num_planned_card_data=%0d, num_planned_host_data=%0d",
    DutParamDmaId_t'(found.pkt_dma_id), found.q_mst.size(), found.expected_pkt_len, found.need_intr, found.need_status, found.has_last_mst, found.num_planned_card_data, found.num_planned_host_data));
  this.debug($sformatf("[NEW/UPDATE_PKT] Now has %0d active pkts", this.q_active_pkt.size()));
  
  
  // KTSB-6 : Generate "Expected Interrupt/Status"
  if(found.need_intr == YES) begin
    created_intr.dma_id = DutParamDmaId_t'(trans.desc.dma_id);
    created_intr.fnc_id = trans.desc.fnc_id;
    created_intr.vec_id = trans.desc.vec_id;
    this.q_expected_intr.push_back(created_intr);
  end
  
  if(found.need_status == YES) begin
    created_status.dma_id = DutParamDmaId_t'(trans.desc.dma_id);
    this.q_expected_status.push_back(created_status);
  end
  
  // KTSB-7 : post_registerNewPkt for each h2c/c2h operation
  this.post_registerNewPkt(found, trans);
  
  
endfunction:registerNewPkt



function void vdmatb_sb::post_registerNewPkt(T_TRANS3 trans, T_TRANS trans2);
endfunction:post_registerNewPkt



function void vdmatb_sb::updateMstData(T_TRANS trans);
  T_TRANS3 found;
  Data_t   found_q_data[$];
  YesOrNo_t fault;
  
  // [KTSB] Find PKT corresponding to the CARD_DATA
  found = this.findPkt_MustSuccess(ON_CARD_DATA_PHASE, DutParamDmaId_t'(trans.getDmaId()), "UPDATE_CARD_DATA");
  
  found_q_data = trans.q_data;
  
  // [KTSB] Check CARD_DATA size with expected card data size
  this.debug($sformatf("[UPDATE_MST_DATA] PKT#%0d: num_has/planned_card_data=%0d/%0d found_q_data.size:%0d", 
    DutParamDmaId_t'(found.pkt_dma_id), found.cur_in_card_data, found.num_planned_card_data, found_q_data.size()));
  if( found.num_planned_card_data != found_q_data.size() ) begin
    this.fatal("[CARD_DATA_CHK]", $sformatf("Mismatch CARD_DATA_LEN, (actual/expected) dma_id=%0d/%0d, len=%0d/%0d",
        DutParamDmaId_t'(trans.dma_id), DutParamDmaId_t'(found.pkt_dma_id), trans.q_data.size(), found.num_planned_card_data));
  end
  
  // [KTSB] Check Fault case on Card Data
  fault = this.checkFaultOnMstData(found, trans);
  
  // [KTSB] update PKT information with card data
  found.updateByCardData(trans);
  
  // [KTSB] post_updateCardData for each h2c/c2h operation
  this.post_updateMstData(found, trans);

endfunction:updateMstData


function void vdmatb_sb::post_updateMstData(T_TRANS3 trans, T_TRANS trans2);
endfunction:post_updateMstData


function void vdmatb_sb::updateHostData(T_TRANS2 trans);
  T_TRANS3 found;
  Addr_t      axaddr;
  AxiMaxLen_t axlen;
  
  case(this.getTransType())
    ST_H2C : begin
      axaddr = DutParamHostAddr_t'(trans.araddr);
      axlen  = trans.arlen;
    end
    ST_C2H : begin
      axaddr = DutParamHostAddr_t'(trans.awaddr);
      axlen  = trans.awlen;
    end
    MM_H2C : begin
      axaddr = DutParamHostAddr_t'(trans.araddr);
      axlen  = trans.arlen;
    end
    MM_C2H : begin
      axaddr = DutParamHostAddr_t'(trans.awaddr);
      axlen  = trans.awlen;
    end
    default : this.fatal("PKT_FIND", "Unknown trans_type");
  endcase
 
  // [KTSB] Find PKT corresponding to host data
  found = this.findPkt_ExpectedHost(ON_HOST_DATA_PHASE, trans);
  
  // [KSTB] update PKT information with host data
  found.cur_in_host_data += (axlen+1);
  this.debug($sformatf("[UPDATE_HOST_DATA] PKT#%0d: num_has/planned_host_data=%0d/%0d", DutParamDmaId_t'(found.pkt_dma_id), found.cur_in_host_data, found.num_planned_host_data));
  if(found.cur_in_host_data == found.num_planned_host_data) begin
    found.has_last_hdata=YES;
  end

  this.q_actual_host_data.push_back(trans);
  
  // [KTSB] post_updateHostData for each h2c/c2h operation
  this.post_updateHostData(found, trans);
  
endfunction:updateHostData

function void vdmatb_sb::post_updateHostData(T_TRANS3 trans, T_TRANS2 trans2);
endfunction:post_updateHostData




function void vdmatb_sb::updateCardData(T_TRANS4 trans);
  T_TRANS3 found;
  Addr_t      axaddr;
  AxiMaxLen_t axlen;

  case(this.getTransType())
    MM_H2C : begin
      axaddr = DutParamCardAddr_t'(trans.awaddr);
      axlen  = trans.awlen;
    end
    MM_C2H : begin
      axaddr = DutParamCardAddr_t'(trans.araddr);
      axlen  = trans.arlen;
    end
    default : this.fatal("PKT_FIND", "Unknown trans_type");
  endcase

  // [KTSB] Find PKT corresponding to host data
  found = this.findPkt_ExpectedCard(ON_CARD_DATA_PHASE, trans);
  
  // [KSTB] update PKT information with card data
  found.cur_in_card_data += (axlen+1);
  this.debug($sformatf("[UPDATE_CARD_DATA] PKT#%0d: axlen=%0d num_has/planned_card_data=%0d/%0d", DutParamDmaId_t'(found.pkt_dma_id), axlen, found.cur_in_card_data, found.num_planned_card_data));
  if(found.cur_in_card_data == found.num_planned_card_data) begin
    found.has_last_cdata=YES;
  end
  trans.dma_id = found.pkt_dma_id;

  this.q_actual_card_data.push_back(trans);
  
  // [KTSB] post_updateCardData for each h2c/c2h operation
  this.post_updateCardData(found, trans);

endfunction:updateCardData

function void vdmatb_sb::post_updateCardData(T_TRANS3 trans, T_TRANS4 trans2);
endfunction:post_updateCardData




function void vdmatb_sb::updateInterrupt(T_TRANS trans);
  T_TRANS3 found;
  Interrupt_t found_intr;

  Fault_t found_desc_fault;
  Fault_t found_card_fault;
  Fault_t found_host_fault;
  
  found_intr = trans.getInterrupt();
  
  if( found_intr.vec_id == 'h1f ) begin
    this.debug($sformatf("[ACTUAL_FAULT_ON_INTR] Intr has fault case w/ dma_id=%0d, fnc_id=%0d, vec_id=%0d",
      DutParamDmaId_t'(found_intr.dma_id), found_intr.fnc_id, found_intr.vec_id));
    
    this.q_intr_split.push_back(found_intr);
  end
  else begin
    found = this.findPkt_MustSuccess(ON_CARD_RESP_PHASE, DutParamDmaId_t'(trans.getDmaId()), "UPDATE_INTTERUPT");
    found.updateByIntr(trans);
    this.q_actual_intr.push_back(found_intr);
  end

endfunction:updateInterrupt


function void vdmatb_sb::updateStatus(T_TRANS trans);
  T_TRANS3 found;
  Status_t found_status;
  
  found = this.findPkt_MustSuccess(ON_CARD_RESP_PHASE, DutParamDmaId_t'(trans.getDmaId()), "UPDATA_STATUS");
  
  found_status = trans.getStatus();
  
  found.updateByStatus(trans);
  this.q_actual_status.push_back(found_status);
  
endfunction:updateStatus


function void vdmatb_sb::updateFault(T_TRANS trans);
  Fault_t        found_fault;
  
  this.act_flt_count++;

  found_fault = trans.getFault();
  this.debug($sformatf("[ACTUAL_FAULT_STAT] Fault Status w/ dma_id=%0d, str_id=%0d, fault_code=%0d, axi_resp=%0d",
    DutParamDmaId_t'(found_fault.dma_id), found_fault.str_id, found_fault.code, found_fault.axi_resp));
  
  this.q_fault_split.push_back(found_fault);

  if(this.descFaultCodeCheck(found_fault)) begin
    this.doOnDescFaultForCov(trans, found_fault); 
    this.q_actual_desc_fault.push_back(found_fault);
  end
  else if(this.cardFaultCodeCheck(found_fault)) begin
    this.doOnCardFaultForCov(trans, found_fault); 
    this.q_actual_card_fault.push_back(found_fault);
  end
  else if(this.hostFaultCodeCheck(found_fault)) begin
    this.doOnHostFaultForCov(trans, found_fault); 
    this.q_actual_host_fault.push_back(found_fault);
  end
  else begin
  end
  
endfunction:updateFault


task vdmatb_sb::splitForFaultIntr();
  Interrupt_t  new_intr;
  Fault_t      new_fault;
  int          loop_cnt = 0;
  
  forever begin
    wait(this.q_fault_split.size > 0 && this.q_intr_split.size > 0);
    
    if(this.q_fault_split.size > this.q_intr_split.size) 
      loop_cnt = this.q_intr_split.size;
    else if(this.q_fault_split.size < this.q_intr_split.size)
      loop_cnt = this.q_fault_split.size;
    else
      loop_cnt = this.q_fault_split.size;
    
    
    for(int i = 0; i < loop_cnt; i++) begin
      new_intr  = this.q_intr_split.pop_front();
      new_fault = this.q_fault_split.pop_front();
      
      if(this.descFaultCodeCheck(new_fault)) begin
        this.q_actual_desc_fault_intr.push_back(new_intr);
      end
      else if(this.cardFaultCodeCheck(new_fault)) begin
        this.q_actual_card_fault_intr.push_back(new_intr);
      end
      else if(this.hostFaultCodeCheck(new_fault)) begin
        this.q_actual_host_fault_intr.push_back(new_intr);
      end
      
    end//for
    
  end//forever
endtask : splitForFaultIntr


function YesOrNo_t vdmatb_sb::descFaultCodeCheck(Fault_t found);
  if((found.code == DESC_DATA_LENGTH_IS_ZERO)            ||
     (found.code == DESC_MID_OF_PKT_BEFORE_START_OF_PKT) ||
     (found.code == DESC_SOLO_OF_PKT_DURING_GATHERING)   ||
     (found.code == DESC_START_OF_PKT_DURING_GATHERING)  ||
     (found.code == DESC_END_OF_PKT_BEFORE_START_OF_PKT)) begin
    return(YES);
  end
  else return(NO);
endfunction:descFaultCodeCheck

function YesOrNo_t vdmatb_sb::cardFaultCodeCheck(Fault_t found);
  if((found.code == CARD_R_WRONG_RESP)                   ||
     (found.code == CARD_R_PREMATURE_LAST)               ||
     (found.code == CARD_R_NO_LAST)                      ||
     (found.code == CARD_R_WRONG_MTY)                    ||
     (found.code == CARD_R_WRONG_DMA_ID)                 ||
     (found.code == CARD_B_WRONG_RESP)) begin
    return(YES);
  end
  else return(NO);
endfunction:cardFaultCodeCheck

function YesOrNo_t vdmatb_sb::hostFaultCodeCheck(Fault_t found);
  if((found.code == HOST_R_WRONG_RESP)                   ||
     (found.code == HOST_R_PREMATURE_LAST)               ||
     (found.code == HOST_R_NO_LAST)                      ||
     (found.code == HOST_B_WRONG_RESP)) begin
    return(YES);
  end
  else return(NO);
endfunction:hostFaultCodeCheck

task vdmatb_sb::doDataPathChecker();
  fork
    this.cardDataChecker();
    this.hostDataChecker();
    this.cardIntrChecker();
    this.cardStatusChecker();

    this.descFaultStatChecker();
    this.cardFaultStatChecker();
    this.hostFaultStatChecker();
    this.descFaultIntrChecker();
    this.cardFaultIntrChecker();
    this.hostFaultIntrChecker();
    
    this.splitForFaultIntr();
  join_none
endtask:doDataPathChecker


task vdmatb_sb::cardIntrChecker();
  Interrupt_t expected_intr, actual_intr;
  
  forever begin
    
    wait(this.q_expected_intr.size() > 0);
    wait(this.q_actual_intr.size() > 0);
    this.sb_flag.flag_cardIntr = NO;

    expected_intr = this.q_expected_intr.pop_front();
    actual_intr = this.q_actual_intr.pop_front();
    
    this.debug($sformatf("[COMPARE_INTR] (actual/expected) dma_id=%0d/%0d, fnc_id=%0d/%0d, vec_id=%0d/%0d",
        DutParamDmaId_t'(actual_intr.dma_id), DutParamDmaId_t'(expected_intr.dma_id), actual_intr.fnc_id, expected_intr.fnc_id, actual_intr.vec_id, expected_intr.vec_id));
    
    if( DutParamDmaId_t'(actual_intr.dma_id) != DutParamDmaId_t'(expected_intr.dma_id) )
      this.fatal("[INTR_COMPARE_FATAL]", "Doesn't match interrupt ids");
    
    if( !this.compareIntr(actual_intr, expected_intr) )
      this.fatal("[INTR_COMPARE_FATAL]", $sformatf("Mismatch Interrupts (actual/expected) dma_id=%0d/%0d, fnc_id=%0d/%0d, vec_id=%0d/%0d",
        DutParamDmaId_t'(actual_intr.dma_id), DutParamDmaId_t'(expected_intr.dma_id), actual_intr.fnc_id, expected_intr.fnc_id, actual_intr.vec_id, expected_intr.vec_id));
    
    this.sb_flag.flag_cardIntr = YES;
    
  end
  
endtask:cardIntrChecker


task vdmatb_sb::cardStatusChecker();
  Status_t expected_status, actual_status;
  
  forever begin
    
    wait(this.q_expected_status.size() > 0);
    wait(this.q_actual_status.size() > 0);
    this.sb_flag.flag_cardStat = NO;
    
    expected_status = this.q_expected_status.pop_front();
    actual_status   = this.q_actual_status.pop_front();
    
    this.debug($sformatf("[COMPARE_STATUS] (actual/expected) dma_id=%0d/%0d",
        DutParamDmaId_t'(actual_status.dma_id), DutParamDmaId_t'(expected_status.dma_id)));
    
    if( !this.compareStatus(actual_status, expected_status))
      this.fatal("[STATUS_COMPARE_FATAL]", $sformatf("Mismatch Status (actual/expected) dma_id=%0d/%0d",
        DutParamDmaId_t'(actual_status.dma_id), DutParamDmaId_t'(expected_status.dma_id)));
    
    this.sb_flag.flag_cardStat = YES;
    
  end
  
endtask:cardStatusChecker


task vdmatb_sb::descFaultStatChecker();
  Fault_t expected_desc_fault, actual_desc_fault;
  YesOrNo_t pass_desc;
  int       q_expected_size = 0;
  
  forever begin:CARD_DESC_STAT
    
    wait(this.q_expected_desc_fault.size() > 0);
    wait(this.q_actual_desc_fault.size() > 0);
    
    wait(this.q_actual_desc_fault.size() == this.q_expected_desc_fault.size());
    q_expected_size = this.q_expected_desc_fault.size();
    
    this.sb_flag.flag_descFaultStat = NO;
    
    this.debug($sformatf("[COMPARE_DESC_FAULT] (actual) dma_id=%0d, str_id=%0d, fault_code=%0d, axi_resp=%0d",
      DutParamDmaId_t'(actual_desc_fault.dma_id), actual_desc_fault.str_id, actual_desc_fault.code, actual_desc_fault.axi_resp));
    
//    foreach(this.q_expected_desc_fault[i]) begin:DESC_FLT_Q_CHK
    for(int i = 0; i < q_expected_size; i++) begin:DESC_FLT_Q_CHK
      expected_desc_fault = this.q_expected_desc_fault.pop_front();
      actual_desc_fault = this.q_actual_desc_fault.pop_front();
      pass_desc = NO;

      this.debug($sformatf("[COMPARE_DESC_FAULT_STAT] FIND) dma_id=%0d, str_id=%0h, fault_code=%0d, axi_resp=%0d",
        DutParamDmaId_t'(expected_desc_fault.dma_id), expected_desc_fault.str_id, expected_desc_fault.code, expected_desc_fault.axi_resp));
      if( expected_desc_fault.code == actual_desc_fault.code && DutParamDmaId_t'(expected_desc_fault.dma_id) == DutParamDmaId_t'(actual_desc_fault.dma_id) && expected_desc_fault.axi_resp == actual_desc_fault.axi_resp ) begin
        pass_desc = YES;

        this.debug($sformatf("[COMPARE_DESC_FAULT_COMPLETED] (actual/expected) dma_id=%0d/%0d, str_id=%0h/%0h, axi_resp=%0h/%0h",
          DutParamDmaId_t'(actual_desc_fault.dma_id), DutParamDmaId_t'(expected_desc_fault.dma_id), actual_desc_fault.str_id, expected_desc_fault.str_id, actual_desc_fault.axi_resp, expected_desc_fault.axi_resp));
      end
    
      if(pass_desc == NO) begin
        this.fatal("COMPARE_DESC_FAULT_STAT_FATAL", $sformatf("No corresponding Expected Fault Status w/ actual.dma_id=%0d, str_id=%0d, expected.dma_id=%0d",
          DutParamDmaId_t'(actual_desc_fault.dma_id), actual_desc_fault.str_id, DutParamDmaId_t'(expected_desc_fault.dma_id)));
      end
  
    end:DESC_FLT_Q_CHK

    this.sb_flag.flag_descFaultStat = YES;

  end:CARD_DESC_STAT

endtask:descFaultStatChecker

task vdmatb_sb::cardFaultStatChecker();
  Fault_t   expected_card_fault, actual_card_fault;
  YesOrNo_t pass_card;
  int       q_size = 0;
  
  forever begin:CARD_DATA_STAT
    
    wait(this.q_expected_card_fault.size() > 0);
    wait(this.q_actual_card_fault.size() > 0);
    
    wait(this.q_actual_card_fault.size() == this.q_expected_card_fault.size());
    if(this.q_actual_card_fault.size < this.q_expected_card_fault.size) q_size = this.q_actual_card_fault.size();
    else                                                                q_size = this.q_expected_card_fault.size();
    
    this.sb_flag.flag_cardFaultStat = NO;
    
    this.debug($sformatf("[COMPARE_CARD_FAULT] (actual) dma_id=%0d, str_id=%0d, fault_code=%0d, axi_resp=%0d",
      DutParamDmaId_t'(actual_card_fault.dma_id), actual_card_fault.str_id, actual_card_fault.code, actual_card_fault.axi_resp));
    
    for(int i = 0; i < q_size; i++) begin:CARD_FLT_Q_CHK
      expected_card_fault = this.q_expected_card_fault.pop_front();
      actual_card_fault = this.q_actual_card_fault.pop_front();
      pass_card = NO;

      this.debug($sformatf("[COMPARE_CARD_FAULT_STAT] FIND) dma_id=%0d, str_id=%0h, fault_code=%0d, axi_resp=%0d",
        DutParamDmaId_t'(expected_card_fault.dma_id), expected_card_fault.str_id, expected_card_fault.code, expected_card_fault.axi_resp));
      if( expected_card_fault.code == actual_card_fault.code && DutParamDmaId_t'(expected_card_fault.dma_id) == DutParamDmaId_t'(actual_card_fault.dma_id) && expected_card_fault.axi_resp == actual_card_fault.axi_resp ) begin
        pass_card = YES;

        this.debug($sformatf("[COMPARE_CARD_FAULT_COMPLETED] (actual/expected) dma_id=%0d/%0d, str_id=%0h/%0h, axi_resp=%0h/%0h",
          DutParamDmaId_t'(actual_card_fault.dma_id), DutParamDmaId_t'(expected_card_fault.dma_id), actual_card_fault.str_id, expected_card_fault.str_id, actual_card_fault.axi_resp, expected_card_fault.axi_resp));
      end
    
      if(pass_card == NO) begin
        this.fatal("COMPARE_CARD_FAULT_STAT_FATAL", $sformatf("No corresponding Expected Fault Status w/ actual.dma_id=%0d, str_id=%0d, expected.dma_id=%0d",
          DutParamDmaId_t'(actual_card_fault.dma_id), actual_card_fault.str_id, DutParamDmaId_t'(expected_card_fault.dma_id)));
      end
  
    end:CARD_FLT_Q_CHK

    this.sb_flag.flag_cardFaultStat = YES;

  end:CARD_DATA_STAT

endtask:cardFaultStatChecker

task vdmatb_sb::hostFaultStatChecker();
  Fault_t expected_host_fault, actual_host_fault;
  YesOrNo_t pass_host;
  int       q_size = 0;
  
  forever begin:HOST_SIDE_STAT
    
    wait(this.q_expected_host_fault.size() > 0);
    wait(this.q_actual_host_fault.size() > 0);
    
    wait(this.q_actual_host_fault.size() == this.q_expected_host_fault.size());
    
    if(this.q_actual_host_fault.size < this.q_expected_host_fault.size) q_size = this.q_actual_host_fault.size();
    else                                                                q_size = this.q_expected_host_fault.size();
   
    this.sb_flag.flag_hostFaultStat = NO;

 
    for(int i = 0; i < q_size; i++) begin:HOST_FLT_Q_CHK 
      expected_host_fault = this.q_expected_host_fault.pop_front();
      actual_host_fault   = this.q_actual_host_fault.pop_front();
      pass_host = NO;
      
      
      this.debug($sformatf("[COMPARE_HOST_FAULT_STAT] FIND) dma_id=%0d, str_id=%0h, fault_code=%0d, axi_resp=%0d",
        DutParamDmaId_t'(expected_host_fault.dma_id), expected_host_fault.str_id, expected_host_fault.code, expected_host_fault.axi_resp));
      if( expected_host_fault.code == actual_host_fault.code && DutParamDmaId_t'(expected_host_fault.dma_id) == DutParamDmaId_t'(actual_host_fault.dma_id) && expected_host_fault.axi_resp == actual_host_fault.axi_resp) begin
        pass_host = YES;

        this.debug($sformatf("[COMPARE_HOST_FAULT_COMPLETED] (actual/expected) dma_id=%0d/%0d, str_id=%0h/%0h, axi_resp=%0h/%0h",
          DutParamDmaId_t'(actual_host_fault.dma_id), DutParamDmaId_t'(expected_host_fault.dma_id), actual_host_fault.str_id, expected_host_fault.str_id, actual_host_fault.axi_resp, expected_host_fault.axi_resp));
      end
    
      if(pass_host == NO) begin
        this.fatal("COMPARE_HOST_FAULT_STAT_FATAL", $sformatf("No corresponding Expected Fault Status w/ actual.dma_id=%0d, str_id=%0d, expected.dma_id=%0d",
          DutParamDmaId_t'(actual_host_fault.dma_id), actual_host_fault.str_id, DutParamDmaId_t'(expected_host_fault.dma_id)));
      end
  
    end:HOST_FLT_Q_CHK

    this.sb_flag.flag_hostFaultStat = YES;

  end:HOST_SIDE_STAT

endtask:hostFaultStatChecker


task vdmatb_sb::descFaultIntrChecker();
  Interrupt_t expected_desc_fault_intr, actual_desc_fault_intr;
  YesOrNo_t   pass_desc;
  int         q_expected_size = 0;
  
  forever begin:CARD_DESC_FLT_INTR
   
    wait(this.q_expected_desc_fault_intr.size() > 0);
    wait(this.q_actual_desc_fault_intr.size() > 0);
    
    wait(this.q_actual_desc_fault_intr.size() == this.q_expected_desc_fault_intr.size());
    this.sb_flag.flag_descFaultIntr = NO;
    q_expected_size                 = this.q_expected_desc_fault_intr.size();
    
    for(int i = 0; i < q_expected_size; i++) begin:DESC_FLT_INTR_Q_CHK
      expected_desc_fault_intr = this.q_expected_desc_fault_intr.pop_front();
      actual_desc_fault_intr   = this.q_actual_desc_fault_intr.pop_front();
      pass_desc = NO;
      
      if( expected_desc_fault_intr == actual_desc_fault_intr ) begin
        pass_desc = YES;
        this.debug($sformatf("[COMPARE_DESC_FAULT_INTR_COMPLETED] (actual/expected) dma_id=%0d/%0d, fnc_id=%0h/%0h, vec_id=%0h/%0h",
          DutParamDmaId_t'(actual_desc_fault_intr.dma_id), DutParamDmaId_t'(expected_desc_fault_intr.dma_id), actual_desc_fault_intr.fnc_id, expected_desc_fault_intr.fnc_id, actual_desc_fault_intr.vec_id, expected_desc_fault_intr.vec_id));
      end
    
      if( pass_desc == NO ) begin
        this.debug($sformatf("[COMPARE_DESC_FAULT_INTR_FAIL] (actual/expected) dma_id=%0d/%0d, fnc_id=%0h/%0h, vec_id=%0h/%0h",
          DutParamDmaId_t'(actual_desc_fault_intr.dma_id), DutParamDmaId_t'(expected_desc_fault_intr.dma_id), actual_desc_fault_intr.fnc_id, expected_desc_fault_intr.fnc_id, actual_desc_fault_intr.vec_id, expected_desc_fault_intr.vec_id));
        this.fatal("COMPARE_DESC_FAULT_INTR_FATAL", $sformatf("No corresponding Expected Fault Intr w/ dma_id=%0d, fnc_id=%0d, vec_id=%0d",
        DutParamDmaId_t'(actual_desc_fault_intr.dma_id), actual_desc_fault_intr.fnc_id, actual_desc_fault_intr.vec_id));
      end
    
    end:DESC_FLT_INTR_Q_CHK

    q_actual_desc_fault_intr.delete();
    q_expected_desc_fault_intr.delete();
    this.sb_flag.flag_descFaultIntr = YES;

  end:CARD_DESC_FLT_INTR
  
endtask:descFaultIntrChecker
  
task vdmatb_sb::cardFaultIntrChecker();
  Interrupt_t expected_card_fault_intr, actual_card_fault_intr;
  YesOrNo_t   pass_card;
  int         q_expected_size = 0;
  
  forever begin:CARD_DATA_FLT_INTR
    
    wait(this.q_expected_card_fault_intr.size() > 0);
    wait(this.q_actual_card_fault_intr.size() > 0);
    
    wait(this.q_actual_card_fault_intr.size() == this.q_expected_card_fault_intr.size());
    q_expected_size = this.q_expected_card_fault_intr.size();

    this.sb_flag.flag_cardFaultIntr = NO;

    for(int i = 0; i < q_expected_size; i++) begin:CARD_FLT_INTR_Q_CHK
      expected_card_fault_intr = this.q_expected_card_fault_intr.pop_front();
      actual_card_fault_intr = this.q_actual_card_fault_intr.pop_front();
      pass_card = NO;

      if( expected_card_fault_intr == actual_card_fault_intr ) begin
        pass_card = YES;
        this.debug($sformatf("[COMPARE_CARD_FAULT_INTR_COMPLETED] (actual/expected) dma_id=%0d/%0d, fnc_id=%0h/%0h, vec_id=%0h/%0h",
          DutParamDmaId_t'(actual_card_fault_intr.dma_id), DutParamDmaId_t'(expected_card_fault_intr.dma_id), actual_card_fault_intr.fnc_id, expected_card_fault_intr.fnc_id, actual_card_fault_intr.vec_id, expected_card_fault_intr.vec_id));
      end
    
      if( pass_card == NO ) begin
        this.debug($sformatf("[COMPARE_CARD_FAULT_INTR_FAIL] (actual/expected) dma_id=%0d/%0d, fnc_id=%0h/%0h, vec_id=%0h/%0h",
          DutParamDmaId_t'(actual_card_fault_intr.dma_id),DutParamDmaId_t'(expected_card_fault_intr.dma_id), actual_card_fault_intr.fnc_id, expected_card_fault_intr.fnc_id, actual_card_fault_intr.vec_id, expected_card_fault_intr.vec_id));
        this.fatal("COMPARE_CARD_FAULT_INTR_FATAL", $sformatf("No corresponding Expected Fault Intr w/ dma_id=%0d, fnc_id=%0d, vec_id=%0d",
        DutParamDmaId_t'(actual_card_fault_intr.dma_id), actual_card_fault_intr.fnc_id, actual_card_fault_intr.vec_id));
      end
    
    end:CARD_FLT_INTR_Q_CHK

    q_actual_card_fault_intr.delete();
    q_expected_card_fault_intr.delete();
    this.sb_flag.flag_cardFaultIntr = YES;

  end:CARD_DATA_FLT_INTR
  
endtask:cardFaultIntrChecker
  
task vdmatb_sb::hostFaultIntrChecker();
  Interrupt_t expected_host_fault_intr, actual_host_fault_intr;
  YesOrNo_t pass_host;
  int        q_expected_size = 0;
  
  forever begin:HOST_SIDE_FLT_INTR
    
    wait(this.q_expected_host_fault_intr.size() > 0);
    wait(this.q_actual_host_fault_intr.size() > 0);
    
    wait(this.q_actual_host_fault_intr.size() == this.q_expected_host_fault_intr.size());
    
    q_expected_size = this.q_expected_host_fault_intr.size();

    this.sb_flag.flag_hostFaultIntr = NO;

    for(int i = 0; i < q_expected_size; i++) begin:HOST_FLT_INTR_Q_CHK
      expected_host_fault_intr = this.q_expected_host_fault_intr.pop_front();
      actual_host_fault_intr   = this.q_actual_host_fault_intr.pop_front();
      pass_host = NO;

      if( expected_host_fault_intr == actual_host_fault_intr ) begin
        pass_host = YES;
        this.debug($sformatf("[COMPARE_HOST_FAULT_INTR_COMPLETED] (actual/expected) dma_id=%0d/%0d, fnc_id=%0h/%0h, vec_id=%0h/%0h",
          DutParamDmaId_t'(actual_host_fault_intr.dma_id), DutParamDmaId_t'(expected_host_fault_intr.dma_id), actual_host_fault_intr.fnc_id, expected_host_fault_intr.fnc_id, actual_host_fault_intr.vec_id, expected_host_fault_intr.vec_id));
      end
    
      if( pass_host == NO ) begin
        this.debug($sformatf("[COMPARE_HOST_FAULT_INTR_FAIL] (actual/expected) dma_id=%0d/%0d, fnc_id=%0h/%0h, vec_id=%0h/%0h",
          DutParamDmaId_t'(actual_host_fault_intr.dma_id), DutParamDmaId_t'(expected_host_fault_intr.dma_id), actual_host_fault_intr.fnc_id, expected_host_fault_intr.fnc_id, actual_host_fault_intr.vec_id, expected_host_fault_intr.vec_id));
        this.fatal("COMPARE_HOST_FAULT_INTR_FATAL", $sformatf("No corresponding Expected Fault Intr w/ dma_id=%0d, fnc_id=%0d, vec_id=%0d",
        DutParamDmaId_t'(actual_host_fault_intr.dma_id), actual_host_fault_intr.fnc_id, actual_host_fault_intr.vec_id));
      end
    
    end:HOST_FLT_INTR_Q_CHK

    q_actual_host_fault_intr.delete();
    q_expected_host_fault_intr.delete();
    this.sb_flag.flag_hostFaultIntr = YES;

  end:HOST_SIDE_FLT_INTR

endtask:hostFaultIntrChecker


function YesOrNo_t vdmatb_sb::compareIntr(Interrupt_t actual, Interrupt_t expected);
  
  if( DutParamDmaId_t'(actual.dma_id) != DutParamDmaId_t'(expected.dma_id)) begin
    this.debug($sformatf("[INTR_COMPARE_FATAL] Doesn't match interrupt dma_id / actual_dma_id=%0d, expected_dma_id=%0d", DutParamDmaId_t'(actual.dma_id), DutParamDmaId_t'(expected.dma_id)));
    return(NO);
  end
  if( actual.fnc_id != expected.fnc_id ) begin
    this.debug($sformatf("[INTR_COMPARE_FATAL] Doesn't match interrupt fnc_id / actual_fnc_id=%0d, expected_fnc_id=%0d", actual.fnc_id, expected.fnc_id));
    return(NO);
  end
  if( actual.vec_id != expected.vec_id ) begin
    this.debug($sformatf("[INTR_COMPARE_FATAL] Doesn't match interrupt vec_id / actual_vec_id=%0d, expected_vec_id=%0d", actual.vec_id, expected.vec_id));
    return(NO);
  end

  return(YES);

endfunction:compareIntr


function YesOrNo_t vdmatb_sb::compareStatus(Status_t actual, Status_t expected);
  
  if( DutParamDmaId_t'(actual.dma_id) != DutParamDmaId_t'(expected.dma_id) ) begin
    this.debug($sformatf("[STATUS_COMPARE_FATAL] Doesn't match status dma_id / actual_dma_id=%0d, expected_dma_id=%0d", DutParamDmaId_t'(actual.dma_id), DutParamDmaId_t'(expected.dma_id)));
    return(NO);
  end
  
  return(YES);
  
endfunction:compareStatus



function YesOrNo_t vdmatb_sb::checkFaultOnDesc(T_TRANS3 trans, T_TRANS trans2);
  YesOrNo_t result = NO;
  Desc_t  desc;
  Fault_t created_fault;
  Interrupt_t created_fault_intr;
  
  desc = trans2.desc;
  
  created_fault.dma_id = DutParamDmaId_t'(desc.dma_id);
  created_fault.str_id = desc.str_id;
  created_fault.axi_resp = 0;
  created_fault_intr.dma_id = DutParamDmaId_t'(desc.dma_id);
  created_fault_intr.fnc_id = desc.fnc_id;
  
  // [KTSB] Fault Code : DESC_DATA_LENGTH_IS_ZERO
  if( desc.len == 0 ) begin
    CovFault_t cov_desc_data_len_is_zero;
    
    created_fault.code = DESC_DATA_LENGTH_IS_ZERO;
    result             = YES;
    
    cov_desc_data_len_is_zero.dma_id     = desc.dma_id;
    cov_desc_data_len_is_zero.fault_code = int'(DESC_DATA_LENGTH_IS_ZERO);
    this.q_cov_desc_data_length_is_zero.push_back(cov_desc_data_len_is_zero);
  end
  
  // [KTSB] Only H2C : there are sop/eop only on H2C I/F
  if( this.getTransType() == ST_H2C ) begin
    // Fault Code : DESC_SOLO_OF_PKT_DURING_GATHERING, DESC_START_OF_PKT_DURING_GATHERING
    if( (trans.is_gathering == YES) && (desc.sop) ) begin
      if( desc.eop ) created_fault.code = DESC_SOLO_OF_PKT_DURING_GATHERING;
      else           created_fault.code = DESC_START_OF_PKT_DURING_GATHERING;
      result = YES;
    end
    // [KTSB] Fault Code : DESC_MID_OF_PKT_BEFORE_START_OF_PKT
    else if( (trans.is_gathering == NO) && (!desc.sop) ) begin
      if(desc.eop) created_fault.code = DESC_END_OF_PKT_BEFORE_START_OF_PKT;
      else created_fault.code = DESC_MID_OF_PKT_BEFORE_START_OF_PKT;
      result = YES;
    end
  end
  
  if( (result==YES) && (trans.is_gathering==NO) ) trans.setCompletedByFault();
  

  // [KTSB] Generate expected fault status/interrupt
  if( result == YES ) begin
    created_fault_intr.vec_id = 'h1f;
    created_fault_intr.fnc_id = 'hff;
    this.debug($sformatf("[EXPECT_FAULT_ON_DESC] Desc has fault case w/ dma_id=%0d, fault_code=%0d, str_id=%0d, fnc_id=%0d",
      DutParamDmaId_t'(created_fault.dma_id), created_fault.code, created_fault.str_id, created_fault_intr.fnc_id));

    this.q_expected_desc_fault.push_back(created_fault);
    this.q_expected_desc_fault_intr.push_back(created_fault_intr);
  end
  
  return(result);
endfunction:checkFaultOnDesc



function YesOrNo_t vdmatb_sb::checkFaultOnMstData(T_TRANS3 trans, T_TRANS trans2);
  T_TRANS  expected;
  YesOrNo_t result = NO;
  YesOrNo_t result_all = NO;
  YesOrNo_t result_plast = NO;
  YesOrNo_t result_wdma = NO;
  YesOrNo_t result_sgl = NO;
  Desc_t  desc;
  DataQ_t q_data;
  Empty_t expected_mty;
  Fault_t   created_fault;
  Interrupt_t created_fault_intr;
  DmaId_t   dma_id;
  Len_t     len;

  int cnt_tlast = 0;
  
  desc = trans2.desc;
  q_data = trans2.q_data;
  
  created_fault.dma_id = DutParamDmaId_t'(desc.dma_id);
  created_fault.str_id = desc.str_id;
  created_fault.axi_resp = 0;
  created_fault_intr.dma_id = DutParamDmaId_t'(desc.dma_id);
  created_fault_intr.fnc_id = desc.fnc_id;
  
  this.debug($sformatf("[CHECK_FAULT_ON_CARD_DATA] w/ dma_id=%0d, q_data_size=%0d", DutParamDmaId_t'(desc.dma_id), q_data.size()));

  // [KTSB] All Data transaction check : CARD_R_PREMATURE_LAST, CARD_R_WRONG_DMA_ID
  foreach( q_data[i] ) begin:Q_ALL_CHK
    // [KTSB] Fault Code : CARD_R_PREMATURE_LAST
    if( DutParamDmaId_t'(q_data[i].side_info.dma_id) != DutParamDmaId_t'(desc.dma_id) ) begin
      this.debug($sformatf("[FAULT_ON_CARD_DATA] PKT#%0d: card_data_dma_id=%0d, card_data_size=%0d, len=%0d",
        DutParamDmaId_t'(desc.dma_id), DutParamDmaId_t'(q_data[i].side_info.dma_id), this.card_data_size, desc.len));
      
      created_fault.code = CARD_R_WRONG_DMA_ID;
      result_wdma = YES;
  
      this.result_wdma_id = YES;
  
    end
    
    if( q_data[i].last == 1 ) begin
      if( i != (q_data.size()-1) ) begin
        created_fault.code = CARD_R_PREMATURE_LAST;
        result_plast = YES;
      end
    end
  
    if((result_plast == YES) | (result_wdma == YES)) result_all = YES;
    else  result_all = NO;
  
  
    // [KTSB] Generate expected fault status/interrupt
    if( result_all == YES ) begin
      created_fault_intr.vec_id = 'h1f;
      created_fault_intr.fnc_id = 'hff;
      this.debug($sformatf("[EXPECT_FAULT_ON_CARD_DATA] Card_Data has fault case w/ dma_id=%0d, fault_code=%0d, str_id=%0d, fnc_id=%0d",
        DutParamDmaId_t'(created_fault.dma_id), created_fault.code, created_fault.str_id, created_fault_intr.fnc_id));

      this.q_expected_card_fault.push_back(created_fault);
      this.q_expected_card_fault_intr.push_back(created_fault_intr);
    end
    
    result_plast = NO;
    result_wdma = NO;
  
  end:Q_ALL_CHK


  // [KTSB] Single transaction check : CARD_R_NO_LAST, CARD_R_WRONG_MTY
  if( result_all == NO ) begin:Q_SINGLE_CHK
  // [KTSB] Fault Code : CARD_R_NO_LAST
    if( q_data[$].last == 0 ) begin
      created_fault.code = CARD_R_NO_LAST;
      result_sgl = YES;
    end
  
  // [KTSB] Fault Code : CARD_R_WRONG_MTY
    expected_mty = (this.card_data_size - (desc.len%this.card_data_size));
    if( DutParamEmpty_t'(q_data[$].side_info.mty) != DutParamEmpty_t'(expected_mty) ) begin
      this.debug($sformatf("[FAULT_ON_CARD_DATA] PKT#%0d: mty=%0d/%0d, card_data_size=%0d, len=%0d",
        DutParamDmaId_t'(desc.dma_id), DutParamEmpty_t'(q_data[$].side_info.mty), DutParamEmpty_t'(expected_mty), this.card_data_size, desc.len));
      created_fault.code = CARD_R_WRONG_MTY;
      result_sgl = YES;
    end
  
    // [KTSB] Generate expected fault status/interrupt
    if( result_sgl == YES ) begin
      created_fault_intr.vec_id = 'h1f;
      created_fault_intr.fnc_id = 'hff;
      this.debug($sformatf("[EXPECT_FAULT_ON_CARD_DATA] Card_Data has fault case w/ dma_id=%0d, fault_code=%0d, str_id=%0d, fnc_id=%0d",
        DutParamDmaId_t'(created_fault.dma_id), created_fault.code, created_fault.str_id, created_fault_intr.fnc_id));

      this.q_expected_card_fault.push_back(created_fault);
      this.q_expected_card_fault_intr.push_back(created_fault_intr);
    end
  
  end:Q_SINGLE_CHK


  if((result_all == YES) | (result_sgl == YES)) result = YES;
  
  return(result);

endfunction:checkFaultOnMstData



function vdmatb_sb::T_TRANS3 vdmatb_sb::findPkt(DmaPktStatus_t pkt_status, DmaId_t dma_id, string call_info);
  
  this.debug($sformatf("(findPkt) found_dma_id/dma_id : %0d", DutParamDmaId_t'(dma_id)));

  this.debug($sformatf("[%s] (findPkt) start found_dma_id/dma_id : %0d", call_info, DutParamDmaId_t'(dma_id)));

  foreach(this.q_active_pkt[i]) begin

    this.debug($sformatf("[%s] (findPkt) find found_dma_id : %0d, q_found_dma_id : %0d, q_found_pkt_addr : 0x%0h", call_info, DutParamDmaId_t'(dma_id), DutParamDmaId_t'(this.q_active_pkt[i].pkt_dma_id), DutParamHostAddr_t'(this.q_active_pkt[i].pkt_addr)));

    if(DutParamDmaId_t'(this.q_active_pkt[i].pkt_dma_id) == DutParamDmaId_t'(dma_id)) begin

      this.debug($sformatf("[%s] (findPkt) found found_dma_id : %0d, q_found_dma_id : %0d, q_found_pkt_addr : 0x%0h", call_info, DutParamDmaId_t'(dma_id), DutParamDmaId_t'(this.q_active_pkt[i].pkt_dma_id), DutParamHostAddr_t'(this.q_active_pkt[i].pkt_addr)));
      return(this.q_active_pkt[i]);
    end
  end
  
  return(null);
endfunction:findPkt



function vdmatb_sb::T_TRANS3 vdmatb_sb::findDesc(DmaPktStatus_t pkt_status, DmaId_t dma_id, StrId_t str_id, string call_info);

  this.debug($sformatf("[%s] (InfindDesc) found_dma_id/dma_id : %0d, found_str_id/str_id : 0x%0h", call_info, DutParamDmaId_t'(dma_id), str_id));

  foreach(this.q_active_pkt[i]) begin:Q_ACTIVE

    this.debug($sformatf("[%s] (findDesc) found_dma_id : %0d, found_str_id : 0x%0h, q_found_dma_id : %0d, q_found_str_id : 0x%0h", call_info, DutParamDmaId_t'(dma_id), str_id, DutParamDmaId_t'(this.q_active_pkt[i].desc.dma_id), this.q_active_pkt[i].desc.str_id));

    foreach(this.q_active_pkt[i].q_mst[j]) begin
      if((DutParamDmaId_t'(this.q_active_pkt[i].q_mst[j].desc.dma_id) == DutParamDmaId_t'(dma_id)) && (this.q_active_pkt[i].q_mst[j].desc.str_id == str_id)) begin

        this.q_active_pkt[i].desc.dma_id = DutParamDmaId_t'(dma_id);
        this.q_active_pkt[i].desc.str_id = str_id;

        this.debug($sformatf("[%s] (findDesc:FOUND) found_dma_id : %0d, found_str_id : 0x%0h, q_found_dma_id : %0d, q_found_str_id : 0x%0h", call_info, DutParamDmaId_t'(dma_id), str_id, DutParamDmaId_t'(this.q_active_pkt[i].desc.dma_id), this.q_active_pkt[i].desc.str_id));

        return(this.q_active_pkt[i]);

      end

    end
  end:Q_ACTIVE
  
  return(null);
endfunction:findDesc


function vdmatb_sb::T_TRANS3 vdmatb_sb::findPkt_MustSuccess(DmaPktStatus_t pkt_status, DmaId_t dma_id, string call_info);
  T_TRANS3 found;
  
  found = this.findPkt(pkt_status, DutParamDmaId_t'(dma_id), call_info);
  this.debug($sformatf("(findPkt_MustSuccess) found_dma_id/dma_id : %0d/%0d", found.pkt_dma_id, DutParamDmaId_t'(dma_id)));

  if(found == null) begin
    this.fatal("[REPORT_FATAL]", $sformatf("Cannot find the corresponding PKT w/ dma_id=%0d, call_info=[%s]", DutParamDmaId_t'(dma_id), call_info));

  end
  
  return(found);
endfunction:findPkt_MustSuccess



function vdmatb_sb::T_TRANS3 vdmatb_sb::findDesc_MustSuccess(DmaPktStatus_t pkt_status, DmaId_t dma_id, StrId_t str_id, string call_info);
  T_TRANS3 found;
  
  found = this.findDesc(pkt_status, DutParamDmaId_t'(dma_id), str_id, call_info);
  this.debug($sformatf("(findDesc_MustSuccess) found_dma_id/dma_id : %0d/%0d, found_str_id/str_id : 0x%0h/0x%0h", found.pkt_dma_id, DutParamDmaId_t'(dma_id), found.desc.str_id, str_id));

  if(found == null) begin
    this.fatal("[REPORT_FATAL]", $sformatf("Cannot find the corresponding PKT w/ dma_id=%0d, str_id : 0x%0h, call_info=[%s]", DutParamDmaId_t'(dma_id), str_id, call_info));

  end

  return(found);

endfunction:findDesc_MustSuccess



function vdmatb_sb::T_TRANS3 vdmatb_sb::findPkt_ExpectedHost(DmaPktStatus_t pkt_status, T_TRANS2 trans);
  T_TRANS3 found;
  DmaId_t   found_dma_id;
  StrId_t   found_str_id;

  Addr_t    addr;
  logic[pdma_dut_pkg::AXI_USER_WIDTH-1:0] user;
  YesOrNo_t completed = NO;

  if( this.getTransType() == ST_H2C || this.getTransType() == MM_H2C) begin
    addr = DutParamHostAddr_t'(trans.araddr);
    user = trans.aruser;
    foreach(this.q_expected_host_req[i]) begin
      this.debug($sformatf("(FIND) araddr 0x%0h/0x%0h str_id %0d/%0d", DutParamHostAddr_t'(q_expected_host_req[i].araddr), DutParamHostAddr_t'(addr), q_expected_host_req[i].aruser, user));
      if((DutParamHostAddr_t'(this.q_expected_host_req[i].araddr) == DutParamHostAddr_t'(addr))&&(this.q_expected_host_req[i].aruser == user)) begin
        found_dma_id = DutParamDmaId_t'(this.q_expected_host_req[i].desc.dma_id);
        found_str_id = this.q_expected_host_req[i].desc.str_id;
        completed=YES;
        break;
      end
    end
  end
  else if( this.getTransType() == ST_C2H || this.getTransType() == MM_C2H) begin
    addr = DutParamHostAddr_t'(trans.awaddr);
    user = trans.awuser;
    foreach(this.q_expected_host_req[i]) begin
      this.debug($sformatf("(FIND) awaddr 0x%0h/0x%0h str_id %0d/%0d", DutParamHostAddr_t'(q_expected_host_req[i].awaddr), DutParamHostAddr_t'(addr), q_expected_host_req[i].awuser, user));
      if((DutParamHostAddr_t'(this.q_expected_host_req[i].awaddr) == DutParamHostAddr_t'(addr))&&(this.q_expected_host_req[i].awuser == user)) begin
        found_dma_id = DutParamDmaId_t'(this.q_expected_host_req[i].dma_id);
        this.q_expected_host_req.delete(i);
        completed=YES;
        break;
      end
    end
  end
  
  if(completed == NO) this.fatal("FIND_PKT", $sformatf("Cannot find PKT on host, w/ addr=0x%0h", DutParamHostAddr_t'(addr)));

  if( this.getTransType() == ST_H2C || this.getTransType() == MM_H2C) begin
    found = this.findDesc_MustSuccess(pkt_status, DutParamDmaId_t'(found_dma_id), found_str_id, "FIND_PKT_HOST");
  end
  else if( this.getTransType() == ST_C2H || this.getTransType() == MM_C2H) begin
    found = this.findPkt_MustSuccess(pkt_status, DutParamDmaId_t'(found_dma_id), "FIND_PKT_HOST");
  end

  return(found);
endfunction:findPkt_ExpectedHost


function vdmatb_sb::T_TRANS3 vdmatb_sb::findPkt_ExpectedCard(DmaPktStatus_t pkt_status, T_TRANS4 trans);
  T_TRANS3 found;
  DmaId_t   found_dma_id;
  StrId_t   found_str_id;

  Addr_t    addr;
  logic[pdma_dut_pkg::AXI_USER_WIDTH-1:0] user;
  YesOrNo_t completed = NO;


  if( this.getTransType() == MM_H2C) begin
    addr = DutParamCardAddr_t'(trans.awaddr);
    user = trans.awuser;
    foreach(this.q_expected_card_req[i]) begin
      this.debug($sformatf("(FIND) awaddr 0x%0h/0x%0h user %0d/%0d", DutParamCardAddr_t'(q_expected_card_req[i].awaddr), DutParamCardAddr_t'(addr), q_expected_card_req[i].awuser, user));
      if((DutParamCardAddr_t'(this.q_expected_card_req[i].awaddr) == DutParamCardAddr_t'(addr))&&(this.q_expected_card_req[i].awuser == user)) begin
        found_dma_id = DutParamDmaId_t'(this.q_expected_card_req[i].dma_id);
        this.q_expected_card_req.delete(i);
        completed=YES;
        break;
      end
    end
  end 
  else if( this.getTransType() == MM_C2H) begin
    addr = DutParamCardAddr_t'(trans.araddr);
    user = trans.aruser;
    foreach(this.q_expected_card_req[i]) begin
      this.debug($sformatf("(FIND) araddr 0x%0h/0x%0h user %0d/%0d", DutParamCardAddr_t'(q_expected_card_req[i].araddr), DutParamCardAddr_t'(addr), q_expected_card_req[i].aruser, user));
      if((DutParamCardAddr_t'(this.q_expected_card_req[i].araddr) == DutParamCardAddr_t'(addr)) && (this.q_expected_card_req[i].aruser == user)) begin
        found_dma_id = DutParamDmaId_t'(this.q_expected_card_req[i].dma_id);
        completed=YES;
        break;
      end
    end
  end

  if(completed == NO) this.fatal("FIND_PKT", $sformatf("Cannot find PKT on card, w/ addr=0x%0h", DutParamCardAddr_t'(addr)));

  found = this.findPkt_MustSuccess(pkt_status, DutParamDmaId_t'(found_dma_id), "FIND_PKT_CARD");

  return(found);
endfunction:findPkt_ExpectedCard




function Addr_t vdmatb_sb::calculateNextHostAddr(Addr_t addr, DutParamAxiMaxLen_t maxBurstLen, Addr_t endAddr);
  Addr_t nextAddr;

  nextAddr = DutParamHostAddr_t'(addr) + (maxBurstLen * HOST_DATA_BYTE_WIDTH);
  if (DutParamHostAddr_t'(nextAddr) > DutParamHostAddr_t'(endAddr)) nextAddr = DutParamHostAddr_t'(endAddr);

  if ((DutParamHostAddr_t'(addr[11:0]) != 12'h0) && (DutParamHostAddr_t'(addr[12]) != DutParamHostAddr_t'(nextAddr[12]))) //To Check 4K Boundary
    nextAddr = {nextAddr[pdma_dut_pkg::HOST_ADDR_WIDTH -1 :12],12'h000};

  return (DutParamHostAddr_t'(nextAddr));
endfunction:calculateNextHostAddr


function Addr_t vdmatb_sb::calculateNextCardAddr(Addr_t addr, DutParamAxiMaxLen_t maxBurstLen, Addr_t endAddr);
  Addr_t nextAddr;

  nextAddr = DutParamCardAddr_t'(addr + (maxBurstLen * CARD_DATA_BYTE_WIDTH));
  if (DutParamCardAddr_t'(endAddr) < DutParamCardAddr_t'(addr)) begin
    if (DutParamCardAddr_t'(nextAddr) < 16'h1000) begin
      if (DutParamCardAddr_t'(nextAddr) > DutParamCardAddr_t'(endAddr)) nextAddr = DutParamCardAddr_t'(endAddr);
    end
  end
  else begin
    if (DutParamCardAddr_t'(nextAddr) > DutParamCardAddr_t'(endAddr)) nextAddr = DutParamCardAddr_t'(endAddr);
  end

  if ((DutParamCardAddr_t'(addr[11:0]) != 12'h0) && (DutParamCardAddr_t'(addr[12]) != DutParamCardAddr_t'(nextAddr[12]))) //To Check 4K Boundary
    nextAddr = DutParamCardAddr_t'({nextAddr[pdma_dut_pkg::CARD_ADDR_WIDTH -1 :12],12'h000});

  return (DutParamCardAddr_t'(nextAddr));
endfunction:calculateNextCardAddr


function Len_t vdmatb_sb::getTotalHostBurst(Desc_t desc);
  Len_t         result;
  Addr_t        addr;

  case(this.getTransType())
    ST_H2C:begin
      addr = DutParamHostAddr_t'(desc.src_addr);
    end
    ST_C2H:begin
      addr = DutParamHostAddr_t'(desc.dst_addr);
    end
    MM_H2C:begin
      addr = DutParamHostAddr_t'(desc.src_addr);
    end
    MM_C2H:begin
      addr = DutParamHostAddr_t'(desc.dst_addr);
    end
    default:begin
      this.fatal("getTotalBurst_ERROR", "Unknown TransType");
    end
  endcase

  if( (desc.len + DutParamHostAddr_t'(addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0])) <= HOST_DATA_BYTE_WIDTH)
    result = 1;
  else begin
    result = ((desc.len + DutParamHostAddr_t'(addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0])) / HOST_DATA_BYTE_WIDTH);
    if( (desc.len + DutParamHostAddr_t'(addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0])) % HOST_DATA_BYTE_WIDTH != 0 ) result ++;
  end
  
  return(result);
endfunction:getTotalHostBurst


function Len_t vdmatb_sb::getTotalCardBurst(Desc_t desc);
  Len_t         result;
  Addr_t        addr;

  case(this.getTransType())
    ST_H2C:begin
      addr = DutParamCardAddr_t'(desc.dst_addr);
    end
    ST_C2H:begin
      addr = DutParamCardAddr_t'(desc.src_addr);
    end
    MM_H2C:begin
      addr = DutParamCardAddr_t'(desc.dst_addr);
    end
    MM_C2H:begin
      addr = DutParamCardAddr_t'(desc.src_addr);
    end
    default:begin
      this.fatal("getTotalBurst_ERROR", "Unknown TransType");
    end
  endcase

  if( (desc.len + DutParamCardAddr_t'(addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0])) <= CARD_DATA_BYTE_WIDTH)
    result = 1;
  else begin
    result = ((desc.len + DutParamCardAddr_t'(addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0])) / CARD_DATA_BYTE_WIDTH);
    if( (desc.len + DutParamCardAddr_t'(addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0])) % CARD_DATA_BYTE_WIDTH != 0 ) result ++;
  end

  return(result);
endfunction:getTotalCardBurst


function DutParamAxiMaxLen_t vdmatb_sb::updateCurrHostBurstLen(Addr_t cAddr, Addr_t nAddr);
  DutParamAxiMaxLen_t burstLen;

  burstLen = (DutParamHostAddr_t'(nAddr) + (HOST_DATA_BYTE_WIDTH - 1) - DutParamHostAddr_t'(cAddr)) / HOST_DATA_BYTE_WIDTH;

  if(burstLen > 256)
    burstLen = 256;

  return (burstLen);
endfunction:updateCurrHostBurstLen


function DutParamAxiMaxLen_t vdmatb_sb::updateCurrCardBurstLen(Addr_t cAddr, Addr_t nAddr);
  DutParamAxiMaxLen_t burstLen;

  burstLen = (DutParamCardAddr_t'(nAddr) + (CARD_DATA_BYTE_WIDTH - 1) - DutParamCardAddr_t'(cAddr)) / CARD_DATA_BYTE_WIDTH;

  if(burstLen > 256)
    burstLen = 256;

  return (burstLen);
endfunction:updateCurrCardBurstLen


function CData_t vdmatb_sb::andWithStrb(CData_t inData, CStrb_t strb);
  CData_t outData;
  for (int i =0; i <CARD_DATA_WIDTH; i++) begin
    outData[i] = inData[i] & strb[i/8];
  end
  return (outData);
endfunction:andWithStrb


function int vdmatb_sb::calculate_data_width_gap();
  if     (HOST_DATA_WIDTH > CARD_DATA_WIDTH) return(HOST_DATA_WIDTH / CARD_DATA_WIDTH);
  else if(HOST_DATA_WIDTH < CARD_DATA_WIDTH) return(CARD_DATA_WIDTH / HOST_DATA_WIDTH);
  else                                       return(1);
endfunction : calculate_data_width_gap



function void vdmatb_sb::doOnDescFaultForCov(T_TRANS trans, Fault_t found_fault);
  CovFault_t cov_desc_fault;
  
  cov_desc_fault.dma_id     = trans.getDmaId();
  cov_desc_fault.fault_code = int'(found_fault.code);
  
  if(found_fault.code == DESC_DATA_LENGTH_IS_ZERO) this.doOnDataLenZeroFault_wo_following_trans(trans, found_fault);
  else                                             this.q_cov_desc_fault.push_back(cov_desc_fault);
endfunction : doOnDescFaultForCov



function void vdmatb_sb::doOnCardFaultForCov(T_TRANS trans, Fault_t found_fault);
  DmaId_t dma_id;
  
  dma_id = DutParamDmaId_t'(trans.getDmaId);
  
  case(found_fault.code)
    CARD_R_WRONG_RESP : begin
      CovWrongResp_t cov_card_r_wrong_resp;
      
      cov_card_r_wrong_resp.dma_id = dma_id;
      cov_card_r_wrong_resp.resp   = found_fault.axi_resp;
      this.q_expected_fault_card_r_wrong_resp.push_back(cov_card_r_wrong_resp);
    end
    CARD_B_WRONG_RESP : begin
      CovWrongResp_t cov_card_b_wrong_resp;
      
      cov_card_b_wrong_resp.dma_id = dma_id;
      cov_card_b_wrong_resp.resp   = found_fault.axi_resp;
      this.q_expected_fault_card_b_wrong_resp.push_back(cov_card_b_wrong_resp);
    end
    default : begin
      CovFault_t cov_card_fault;
      
      cov_card_fault.dma_id     = dma_id;
      cov_card_fault.fault_code = int'(found_fault.code);
      this.q_cov_card_fault.push_back(cov_card_fault);
    end
  endcase
  
endfunction : doOnCardFaultForCov



function void vdmatb_sb::doOnHostFaultForCov(T_TRANS trans, Fault_t found_fault);
  DmaId_t dma_id;
  
  dma_id = DutParamDmaId_t'(trans.getDmaId);
  
  case(found_fault.code)
    HOST_R_WRONG_RESP : begin
      CovWrongResp_t cov_host_r_wrong_resp;
      
      cov_host_r_wrong_resp.dma_id = dma_id;
      cov_host_r_wrong_resp.resp   = found_fault.axi_resp;
      this.q_expected_fault_host_r_wrong_resp.push_back(cov_host_r_wrong_resp);
    end
    HOST_B_WRONG_RESP : begin
      CovWrongResp_t cov_host_b_wrong_resp;
      
      cov_host_b_wrong_resp.dma_id = dma_id;
      cov_host_b_wrong_resp.resp   = found_fault.axi_resp;
      this.q_expected_fault_host_b_wrong_resp.push_back(cov_host_b_wrong_resp);
    end
    HOST_R_NO_LAST : begin
      CovFault_t cov_host_r_no_last;
      
      cov_host_r_no_last.dma_id     = dma_id;
      cov_host_r_no_last.fault_code = int'(found_fault.code);
      this.q_cov_actual_fault_host_r_no_last.push_back(cov_host_r_no_last);
    end
    HOST_R_PREMATURE_LAST : begin
      CovFault_t cov_host_r_premature_last;
      
      cov_host_r_premature_last.dma_id     = dma_id;
      cov_host_r_premature_last.fault_code = int'(found_fault.code);
      this.q_cov_actual_fault_host_r_premature_last.push_back(cov_host_r_premature_last);
    end
  endcase
endfunction : doOnHostFaultForCov


function void vdmatb_sb::doOnDataLenZeroFault_with_following_trans(T_TRANS3 completed);
  foreach(this.q_cov_desc_data_length_is_zero[i]) begin
    SampleLstForFault_t sample_list_desc_len_zero_fault;
    
    if(this.q_cov_desc_data_length_is_zero[i].dma_id == completed.pkt_dma_id) begin
    
      sample_list_desc_len_zero_fault.following_trans = YES;
      
      case(completed.trans_type)
        ST_C2H : begin
          this.st_sb_cov_colctr.setC2HDescDataLenZeroFaultSampleLst_with_followingTrans(sample_list_desc_len_zero_fault);
          this.st_sb_cov_colctr.sampleC2HDescDataLenZeroFault_with_followingTrans();
        end
        ST_H2C : begin
          this.st_sb_cov_colctr.setH2CDescDataLenZeroFaultSampleLst_with_followingTrans(sample_list_desc_len_zero_fault);
          this.st_sb_cov_colctr.sampleH2CDescDataLenZeroFault_with_followingTrans();
        end
        MM_C2H : begin
          this.mm_sb_cov_colctr.setC2HDescDataLenZeroFaultSampleLst_with_followingTrans(sample_list_desc_len_zero_fault);
          this.mm_sb_cov_colctr.sampleC2HDescDataLenZeroFault_with_followingTrans();
        end
        MM_H2C : begin
          this.mm_sb_cov_colctr.setH2CDescDataLenZeroFaultSampleLst_with_followingTrans(sample_list_desc_len_zero_fault);
          this.mm_sb_cov_colctr.sampleH2CDescDataLenZeroFault_with_followingTrans();
        end
      endcase
    end
  end
  
  for(int i = 0; i < this.q_cov_desc_data_length_is_zero.size;) begin
    if(this.q_cov_desc_data_length_is_zero[i].dma_id == completed.pkt_dma_id) this.q_cov_desc_data_length_is_zero.delete(i);
    else                                                                         i++;
  end
endfunction : doOnDataLenZeroFault_with_following_trans



function void vdmatb_sb::doOnDataLenZeroFault_wo_following_trans(T_TRANS trans, Fault_t fault);
  SampleLstForFault_t sample_list_desc_len_zero_fault;
  
  if(trans.intended_faultType == fault.code) begin
    sample_list_desc_len_zero_fault.gen_faultType  = int'(fault.code);
    sample_list_desc_len_zero_fault.intended_fault = YES; 
  end
  else begin
    sample_list_desc_len_zero_fault.intended_fault = NO; 
  end
  
  case(trans.getTransType)
    ST_C2H : begin
      this.st_sb_cov_colctr.setC2HDescDataLenZeroFaultSampleLst_wo_followingTrans(sample_list_desc_len_zero_fault);
      this.st_sb_cov_colctr.sampleC2HDescDataLenZeroFault_wo_followingTrans();
    end
    ST_H2C : begin
      this.st_sb_cov_colctr.setH2CDescDataLenZeroFaultSampleLst_wo_followingTrans(sample_list_desc_len_zero_fault);
      this.st_sb_cov_colctr.sampleH2CDescDataLenZeroFault_wo_followingTrans();
    end
    MM_C2H : begin
      this.mm_sb_cov_colctr.setC2HDescDataLenZeroFaultSampleLst_wo_followingTrans(sample_list_desc_len_zero_fault);
      this.mm_sb_cov_colctr.sampleC2HDescDataLenZeroFault_wo_followingTrans();
    end
    MM_H2C : begin
      this.mm_sb_cov_colctr.setH2CDescDataLenZeroFaultSampleLst_wo_followingTrans(sample_list_desc_len_zero_fault);
      this.mm_sb_cov_colctr.sampleH2CDescDataLenZeroFault_wo_followingTrans();
    end
  endcase
endfunction 



function void vdmatb_sb::doOnCompletedDescFault(T_TRANS3 completed);
  SampleLstForFault_t sample_list_desc_fault;
  
  foreach(this.q_cov_desc_fault[i]) begin
    if(this.q_cov_desc_fault[i].dma_id == completed.pkt_dma_id) begin
      sample_list_desc_fault.following_trans = YES;
      
      if(this.q_cov_desc_fault[i].fault_code == completed.intended_faultType) begin
        sample_list_desc_fault.gen_faultType  = completed.intended_faultType;
        sample_list_desc_fault.intended_fault = YES; 
      end
      else begin
        sample_list_desc_fault.intended_fault = NO;
      end
      
      this.st_sb_cov_colctr.setH2CDescFaultSampleLst(sample_list_desc_fault);
      this.st_sb_cov_colctr.sampleH2CDescFault();
    end
  end
  
  for(int i = 0; i < this.q_cov_desc_fault.size;) begin
    if(this.q_cov_desc_fault[i].dma_id == completed.pkt_dma_id) this.q_cov_desc_fault.delete(i);
    else                                                               i++;
  end
endfunction : doOnCompletedDescFault



function void vdmatb_sb::doOnCompletedCardFault(T_TRANS3 completed);
  SampleLstForFault_t sample_list_card_fault;
  
  if(completed.trans_type == ST_C2H) begin
    foreach(this.q_cov_card_fault[i]) begin
      if(this.q_cov_card_fault[i].dma_id == completed.pkt_dma_id) begin
        sample_list_card_fault.following_trans = YES;
        
        if(this.q_cov_card_fault[i].fault_code == completed.intended_faultType) begin
          sample_list_card_fault.gen_faultType  = completed.intended_faultType;
          sample_list_card_fault.intended_fault = YES; 
        end
        else begin
          sample_list_card_fault.intended_fault = NO;
        end
        
        this.st_sb_cov_colctr.setC2HCardFaultSampleLst(sample_list_card_fault);
        this.st_sb_cov_colctr.sampleC2HCardFault();
      end
    end
    
    for(int i = 0; i < this.q_cov_card_fault.size;) begin
      if(this.q_cov_card_fault[i].dma_id == completed.pkt_dma_id) this.q_cov_card_fault.delete(i);
      else                                                           i++;
    end
  end
 
endfunction : doOnCompletedCardFault
  
 

function void vdmatb_sb::doOnCompletedCardWrongRespFault(T_TRANS3 completed);
  SampleLstForFault_t sample_list_card_wrong_resp;
  
  sample_list_card_wrong_resp.following_trans = YES;
  
  case(completed.trans_type)
    MM_C2H : begin
      foreach(this.q_expected_fault_card_r_wrong_resp[i]) begin
        if(this.q_actual_fault_card_r_wrong_resp[i].resp == this.q_expected_fault_card_r_wrong_resp[i].resp) begin
          sample_list_card_wrong_resp.gen_faultType  = int'(CARD_R_WRONG_RESP);
          sample_list_card_wrong_resp.intended_fault = YES;
        end
        else begin
          sample_list_card_wrong_resp.gen_faultType  = -1;
          sample_list_card_wrong_resp.intended_fault = NO;
        end
        
        this.mm_sb_cov_colctr.setFaultCardRWrongRespSampleLst(sample_list_card_wrong_resp);
        this.mm_sb_cov_colctr.sampleFaultCardRWrongResp();
      end//foreach
      
      this.q_actual_fault_card_r_wrong_resp.delete();
      this.q_expected_fault_card_r_wrong_resp.delete();
    end
    MM_H2C : begin
      foreach(this.q_expected_fault_card_b_wrong_resp[i]) begin
        if(this.q_actual_fault_card_b_wrong_resp[i].resp == this.q_expected_fault_card_b_wrong_resp[i].resp) begin
          sample_list_card_wrong_resp.gen_faultType  = int'(CARD_B_WRONG_RESP);
          sample_list_card_wrong_resp.intended_fault = YES;
        end
        else begin
          sample_list_card_wrong_resp.gen_faultType  = -1;
          sample_list_card_wrong_resp.intended_fault = NO;
        end
        
        this.mm_sb_cov_colctr.setFaultCardBWrongRespSampleLst(sample_list_card_wrong_resp);
        this.mm_sb_cov_colctr.sampleFaultCardBWrongResp();
      end//foreach
      
      this.q_actual_fault_card_b_wrong_resp.delete();
      this.q_expected_fault_card_b_wrong_resp.delete();
    end
  endcase

endfunction : doOnCompletedCardWrongRespFault
 
 

function void vdmatb_sb::doOnCompletedHostFault(T_TRANS3 completed);
  FaultCode_t found_fault_code;
  SampleLstForFault_t sample_list_host_wrong_resp;
  
  found_fault_code = this.ChkWhatTypeOfHostFault(); //TODO : Must Use !!
  
  if(found_fault_code == 0) return;
   
  case(found_fault_code)
    HOST_R_WRONG_RESP     : this.doOnCompletedHostRWrongRespFault(completed);
    HOST_B_WRONG_RESP     : this.doOnCompletedHostBWrongRespFault(completed);
    HOST_R_NO_LAST        : this.doOnCompletedHostRNoLastFault(completed);
    HOST_R_PREMATURE_LAST : this.doOnCompletedHostRPrematureFault(completed);
    default               : this.fatal("NOT SUPPORTED", $sformatf("This fault cannot exist in host-side fault !!"));
  endcase
endfunction : doOnCompletedHostFault



function void vdmatb_sb::doOnCompletedHostRWrongRespFault(T_TRANS3 completed);
  SampleLstForFault_t sample_list_host_wrong_resp;
  
  sample_list_host_wrong_resp.following_trans = YES;
 
  foreach(this.q_expected_fault_host_r_wrong_resp[i]) begin
    if(this.q_actual_fault_host_r_wrong_resp[i].resp == this.q_expected_fault_host_r_wrong_resp[i].resp) begin
      sample_list_host_wrong_resp.gen_faultType  = int'(HOST_R_WRONG_RESP);
      sample_list_host_wrong_resp.intended_fault = YES;
    end
    else begin
      sample_list_host_wrong_resp.gen_faultType  = -1;
      sample_list_host_wrong_resp.intended_fault = NO;
    end
    
    case(completed.trans_type)
      ST_H2C : begin
        this.st_sb_cov_colctr.setFaultHostRWrongRespSampleLst(sample_list_host_wrong_resp);
        this.st_sb_cov_colctr.sampleFaultHostRWrongResp();
      end
      MM_H2C : begin
        this.mm_sb_cov_colctr.setFaultHostRWrongRespSampleLst(sample_list_host_wrong_resp);
        this.mm_sb_cov_colctr.sampleFaultHostRWrongResp();
      end
    endcase
  end
 
  this.q_actual_fault_host_r_wrong_resp.delete();
  this.q_expected_fault_host_r_wrong_resp.delete();
endfunction : doOnCompletedHostRWrongRespFault



function void vdmatb_sb::doOnCompletedHostBWrongRespFault(T_TRANS3 completed);
  SampleLstForFault_t sample_list_host_wrong_resp;
 
  sample_list_host_wrong_resp.following_trans = YES;
 
  foreach(this.q_expected_fault_host_b_wrong_resp[i]) begin
    if(this.q_actual_fault_host_b_wrong_resp[i].resp == this.q_expected_fault_host_b_wrong_resp[i].resp) begin
      sample_list_host_wrong_resp.gen_faultType  = int'(HOST_B_WRONG_RESP);
      sample_list_host_wrong_resp.intended_fault = YES;
    end
    else begin
      sample_list_host_wrong_resp.gen_faultType  = -1;
      sample_list_host_wrong_resp.intended_fault = NO;
    end
    
    case(completed.trans_type)
      ST_C2H : begin
        this.st_sb_cov_colctr.setFaultHostBWrongRespSampleLst(sample_list_host_wrong_resp);
        this.st_sb_cov_colctr.sampleFaultHostBWrongResp();
      end
      MM_C2H : begin
        this.mm_sb_cov_colctr.setFaultHostBWrongRespSampleLst(sample_list_host_wrong_resp);
        this.mm_sb_cov_colctr.sampleFaultHostBWrongResp();
      end
    endcase
  end
 
  this.q_actual_fault_host_b_wrong_resp.delete();
  this.q_expected_fault_host_b_wrong_resp.delete();
endfunction : doOnCompletedHostBWrongRespFault



function void vdmatb_sb::doOnCompletedHostRNoLastFault(T_TRANS3 completed);
  SampleLstForFault_t sample_list_host_r_no_last;
  
  
  foreach(this.q_cov_expected_fault_host_r_no_last[i]) begin
    if(this.q_cov_expected_fault_host_r_no_last[i].dma_id == completed.pkt_dma_id)
      sample_list_host_r_no_last.following_trans = YES;
   
    if(this.q_cov_actual_fault_host_r_no_last[i].dma_id == this.q_cov_expected_fault_host_r_no_last[i].dma_id && this.q_cov_actual_fault_host_r_no_last[i].fault_code == this.q_cov_expected_fault_host_r_no_last[i].fault_code) begin
      sample_list_host_r_no_last.gen_faultType  = int'(HOST_R_NO_LAST);
      sample_list_host_r_no_last.intended_fault = YES; 
    end
    else begin
      sample_list_host_r_no_last.gen_faultType  = -1;
      sample_list_host_r_no_last.intended_fault = NO; 
    end
    
    case(completed.trans_type)
      ST_H2C : begin
        this.st_sb_cov_colctr.setFaultHostRNoLastSampleLst(sample_list_host_r_no_last);
        this.st_sb_cov_colctr.sampleFaultHostRNoLast();
      end
      MM_H2C : begin
        this.mm_sb_cov_colctr.setFaultHostRNoLastSampleLst(sample_list_host_r_no_last);
        this.mm_sb_cov_colctr.sampleFaultHostRNoLast();
      end
    endcase
  end
  
  
  for(int i = 0; i < this.q_cov_expected_fault_host_r_no_last.size;) begin
    if(this.q_cov_expected_fault_host_r_no_last[i].dma_id == completed.pkt_dma_id) this.q_cov_expected_fault_host_r_no_last.delete(i);
    else                                                                           i++;
  end
  
  for(int i = 0; i < this.q_cov_actual_fault_host_r_no_last.size;) begin
    if(this.q_cov_actual_fault_host_r_no_last[i].dma_id == completed.pkt_dma_id) this.q_cov_actual_fault_host_r_no_last.delete(i);
    else                                                                         i++;
  end
endfunction : doOnCompletedHostRNoLastFault


function void vdmatb_sb::doOnCompletedHostRPrematureFault(T_TRANS3 completed);
  SampleLstForFault_t sample_list_host_r_premature_last;
  
  foreach(this.q_cov_expected_fault_host_r_premature_last[i]) begin
    if(this.q_cov_expected_fault_host_r_premature_last[i].dma_id == completed.pkt_dma_id)
      sample_list_host_r_premature_last.following_trans = YES;
    
    if(this.q_cov_actual_fault_host_r_premature_last[i].dma_id == this.q_cov_expected_fault_host_r_premature_last[i].dma_id && this.q_cov_actual_fault_host_r_premature_last[i].fault_code == this.q_cov_expected_fault_host_r_premature_last[i].fault_code) begin
      sample_list_host_r_premature_last.gen_faultType  = int'(HOST_R_PREMATURE_LAST);
      sample_list_host_r_premature_last.intended_fault = YES;
    end
    else begin
      sample_list_host_r_premature_last.gen_faultType  = -1;
      sample_list_host_r_premature_last.intended_fault = NO;
    end
    
    case(completed.trans_type)
      ST_H2C : begin
        this.st_sb_cov_colctr.setFaultHostRPrematureLastSampleLst(sample_list_host_r_premature_last);
        this.st_sb_cov_colctr.sampleFaultHostRPrematureLast();
      end
      MM_H2C : begin
        this.mm_sb_cov_colctr.setFaultHostRPrematureLastSampleLst(sample_list_host_r_premature_last);
        this.mm_sb_cov_colctr.sampleFaultHostRPrematureLast();
      end
    endcase
  end
  
  for(int i = 0; i < this.q_cov_expected_fault_host_r_premature_last.size;) begin
    if(this.q_cov_expected_fault_host_r_premature_last[i].dma_id == completed.pkt_dma_id) this.q_cov_expected_fault_host_r_premature_last.delete(i);
    else                                                                                  i++;
  end
  
  for(int i = 0; i < this.q_cov_actual_fault_host_r_premature_last.size;) begin
    if(this.q_cov_actual_fault_host_r_premature_last[i].dma_id == completed.pkt_dma_id) this.q_cov_actual_fault_host_r_premature_last.delete(i);
    else                                                                                i++;
  end

endfunction : doOnCompletedHostRPrematureFault

function FaultCode_t vdmatb_sb::ChkWhatTypeOfHostFault();
  if(this.q_expected_fault_host_b_wrong_resp.size > 0)               return(HOST_B_WRONG_RESP);
  else if(this.q_expected_fault_host_r_wrong_resp.size > 0)          return(HOST_R_WRONG_RESP);
  else if(this.q_cov_expected_fault_host_r_no_last.size > 0)         return(HOST_R_NO_LAST);
  else if(this.q_cov_expected_fault_host_r_premature_last.size > 0)  return(HOST_R_PREMATURE_LAST);
  
  return(FaultCode_t'(0));
endfunction : ChkWhatTypeOfHostFault


function void vdmatb_sb::doForFaultCovCollect(T_TRANS3 completed);
  this.doOnDataLenZeroFault_with_following_trans(completed);
  this.doOnCompletedDescFault(completed);
  this.doOnCompletedCardFault(completed);
  
  if(this.q_active_pkt.size == 1) begin
    this.doOnCompletedCardWrongRespFault(completed);
    this.doOnCompletedHostFault(completed);
  end
endfunction : doForFaultCovCollect



`endif //__VDMATB_SB_SVH__

