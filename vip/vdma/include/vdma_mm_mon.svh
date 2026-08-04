`ifndef __VDMA_MM_MONITOR_SVH__
`define __VDMA_MM_MONITOR_SVH__


/*

    [IMPORTANT_NOTICE]
       * Unique dma_id assumed (spec can be updated)

    TODO
       * NeedConsiderFault <------- search it (you may need to do something at pre_notifyCompletedTrans)

*/
//7.7 No card axis data

virtual class vdma_mm_monitor extends vmg_mon#(.T_SEQ_ITEM(vdma_seq_item));
  
  protected string cfgdb_key;
  
  uvm_analysis_port#(T_TRANS) ap_desc;
  //uvm_analysis_port#(T_TRANS) ap_data;
  uvm_analysis_port#(T_TRANS) ap_intr;
  uvm_analysis_port#(T_TRANS) ap_status;
  uvm_analysis_port#(T_TRANS) ap_fault;

  typedef T_TRANS Q_TRANS[$];

  local vdma_cmdr_tcfg tcfg;

  protected int q_HostFaultBresp[$];
  protected int q_HostFaultRresp[$];

  protected DmaTransType_t trans_type;
  protected string monitor_name;

  protected T_TRANS q_completed[$];
  protected T_TRANS q_ready2completed[$];
            T_TRANS collectedData;

  // history
  protected int num_trans; 
  protected int num_interrupt, num_status, num_data, num_fault_intr;
  
  typedef struct {
    int num_fault_c2h_code0 = 0;
    int num_fault_h2c_code0 = 0;
    int num_fault_code1 = 0;
    int num_fault_code2 = 0;
    int num_fault_code3 = 0;
    int num_fault_code13 = 0;
    int num_fault_code5 = 0;
    int num_fault_code6 = 0;
    int num_fault_code7 = 0;
    int num_fault_code14 = 0;
    int num_fault_code8 = 0;
    int num_fault_code12 = 0;
    int num_c2h_card_side_fault = 0;
    int num_h2c_card_side_fault = 0;
  }DmaMonFaultCount_t;
  protected DmaMonFaultCount_t fault_count;
  
  YesOrNo_t intended_faultBresp;
  YesOrNo_t intended_faultRresp;
  YesOrNo_t genFaultBresp;
  YesOrNo_t genFaultRresp;
  YesOrNo_t faultBresp_followingTrans;
  YesOrNo_t faultRresp_followingTrans;
  Fault_t q_Complete_HostFaultBresp[$];
  Fault_t q_Complete_HostFaultRresp[$];
  int rresp_idx = -1;
  int bresp_idx = -1;
  int h2c_count_resp = 0;
  int c2h_count_resp = 0;
  int c2h_count_func = 0;
  int h2c_count_func = 0;
  
  YesOrNo_t HostFaultRNoLast;
  YesOrNo_t q_HostFaultRPrematureLast[$];
  YesOrNo_t intended_fault_host_r_no_last;
  YesOrNo_t intended_fault_host_r_premature_last;
  
  FaultCode_t genFault_host_r_no_last;
  FaultCode_t genFault_host_r_premature_last;
  
  int count_premature_last = 0;
  
  YesOrNo_t faultHostRNoLast_followingTrans;
  YesOrNo_t faultHostRPrematureLast_followingTrans;
  
  Fault_t q_Complete_HostFaultRNoLast[$];
  Fault_t q_Complete_HostFaultRPrematureLast[$];
  
  T_TRANS q_fromSeqItem[$];
  T_TRANS q_faultTrans[$];
  Fault_t q_faultStored[$];
  
  C2HFault4Cov_t c2h_fault_cov; 
  H2CFault4Cov_t h2c_fault_cov; 
 
  int count = 0;
  int found_idx = 0;
  
  TestType_t test_type;
  SelectFault_t select_fault;
  string family_name;
  
  int c2h_need_wait_fault = 0;
  
//=====================================================================
// host-side fault cov  
//=====================================================================
  covergroup cg_host_b_wrong_resp;
    intended_fault_bresp : coverpoint (this.intended_faultBresp) {
      bins yes = {1};
      illegal_bins no = {0};
    }
    
    gen_fault_bresp : coverpoint (this.genFaultBresp) {
      bins gen_host_b_wrong_resp_fault = {1};
      illegal_bins not_gen_host_b_wrong_resp_fault = {0};
    }
    
    
    cross_fault_host_b_wrong_resp : cross intended_fault_bresp, gen_fault_bresp;
  endgroup
  
  covergroup cg_host_r_wrong_resp;
    intended_fault_rresp : coverpoint (this.intended_faultRresp) {
      bins yes = {1};
      illegal_bins no = {0};
    }
    
    gen_fault_rresp : coverpoint (this.genFaultRresp) {
      bins gen_host_r_wrong_resp_fault = {1};
      illegal_bins not_gen_host_r_wrong_resp_fault = {0};
    }
    
    cross_fault_host_r_wrong_resp : cross intended_fault_rresp, gen_fault_rresp;
  endgroup
  
  covergroup cg_bresp_following_trans_complete;
    following_trans_complete : coverpoint (this.faultBresp_followingTrans) {
      bins yes = {1};
      illegal_bins no = {0};
    }
  endgroup
  
  covergroup cg_rresp_following_trans_complete;
    following_trans_complete : coverpoint (this.faultRresp_followingTrans) {
      bins yes = {1};
      illegal_bins no = {0};
    }
  endgroup
  
  covergroup cg_host_r_no_last;
    
    gen_fault_host_r_no_last : coverpoint (this.genFault_host_r_no_last) {
      bins HOST_R_NO_LAST = {10};
    }
    
    intended_fault_host_r_no_last : coverpoint (this.intended_fault_host_r_no_last) {
      bins yes = {1};
      illegal_bins no = {0};
    }
  endgroup
  
  covergroup cg_host_r_no_last_following_trans_complete;
    following_trans_complete : coverpoint (this.faultHostRNoLast_followingTrans) {
      bins yes = {1};
      illegal_bins no = {0};
    }
  endgroup
  
  covergroup cg_host_r_premature_last;
    gen_fault_host_r_premature_last : coverpoint (this.genFault_host_r_premature_last) {
      bins HOST_R_PREMATURE_LAST = {9};
    }
    
    intended_fault_host_r_premature_last : coverpoint (this.intended_fault_host_r_premature_last) {
      bins yes = {1};
      illegal_bins no = {0};
    }
  endgroup
  
  covergroup cg_host_r_premature_last_following_trans_complete;
    following_trans_complete : coverpoint (this.faultHostRPrematureLast_followingTrans) {
      bins yes = {1};
      illegal_bins no = {0};
    }
  endgroup
//=====================================================================
// card-side fault cov  
//=====================================================================
  covergroup cg_card_c2h_fault;
    gen_fault_type : coverpoint (this.c2h_fault_cov.gen_faultType) {
      bins DESC_DATA_LENGHT_IS_ZERO = {0};
      bins CARD_R_PREMATURE_LAST    = {5};
      bins CARD_R_NO_LAST           = {6};
      bins CARD_R_WRONG_MTY         = {7};
      bins CARD_R_WRONG_DMA_ID      = {14};
    }
    
    intended_fault : coverpoint (this.c2h_fault_cov.intended_fault) {
      bins yes = {1};
      illegal_bins no = {0};
    }
    
    following_trans_complete : coverpoint (this.c2h_fault_cov.following_trans) {
      bins yes = {1};
      illegal_bins no = {0};
    }
    
  endgroup
  
  covergroup cg_card_h2c_fault;
    gen_fault_type : coverpoint (this.h2c_fault_cov.gen_faultType) {
      bins DESC_DATA_LENGHT_IS_ZERO               = {0};
      bins DESC_MID_OF_PKT_BEFORE_START_OF_PKT    = {1};
      bins DESC_SOLO_OF_PKT_DURING_GATHERING      = {2};
      bins DESC_START_OF_PKT_DURING_GATHERING     = {3};
      bins DESC_END_OF_PKT_BEFORE_START_OF_PKT    = {13};
    }
    
    intended_fault : coverpoint (this.h2c_fault_cov.intended_fault) {
      bins yes = {1};
      illegal_bins no = {0};
    }
    
    following_trans_complete : coverpoint (this.h2c_fault_cov.following_trans) {
      bins yes = {1};
      illegal_bins no = {0};
    }
    
  endgroup

  `vdma_rptr_utils

  function new(string name="vdma_mm_monitor", uvm_component parent=null);
    super.new(name, parent);
    `vdma_rptr_impl_in_new
    cg_host_b_wrong_resp = new();
    cg_host_r_wrong_resp = new();
    cg_bresp_following_trans_complete = new();
    cg_rresp_following_trans_complete = new();
    cg_card_c2h_fault = new();
    cg_card_h2c_fault = new();
    cg_host_r_no_last = new();
    cg_host_r_no_last_following_trans_complete = new();
    cg_host_r_premature_last = new();
    cg_host_r_premature_last_following_trans_complete = new();
  endfunction


  // ---------------------------- uvm built-in
  extern virtual function void build_phase(uvm_phase phase);


  // ---------------------------- vmg vip components built-in
  extern virtual local function string getReportHeader();



  // ---------------------------- vmg_monitor built-in
  extern virtual protected function void extractDb();
  extern virtual protected function void collectTransfer();
  extern virtual protected function void updateState();
  extern virtual protected function void updateDataState();

  extern virtual function void pre_notifyCompletedTrans(T_TRANS completed);
  extern virtual function void showHistory(string prompt);

  extern function void pushFaultBresp(int me);
  extern function void pushFaultRresp(int me);
  
  extern function void pushFaultHostRNoLast(YesOrNo_t me);
  extern function void pushFaultHostRPrematureLast(YesOrNo_t me);

  // ---------------------------- extended-specific
  extern local function void collectDesc();
  //extern local function void collectData();
  extern local function void collectStatus();
  extern local function void collectInterrupt();
  extern local function void collectFault();
  extern local function void collectCompleted();
  extern protected function T_TRANS findTrans(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  extern protected function T_TRANS findTrans_onCompleted(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  extern protected function T_TRANS findTrans_forFaultIrq(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  extern protected function T_TRANS findTrans_Fault_DropCase(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  extern protected function T_TRANS findTrans_Fault_NormalCase(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  extern protected function T_TRANS findTrans_MustSuccess(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  
  extern protected function T_TRANS findTrans_hasWrongDmaId(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);

  extern function int getDataSize();
  
  extern virtual function YesOrNo_t resetMon();
  
  // ---------------------------- fault coverpoint
  extern local function void chkIntendedFault_Bresp(Fault_t being_found);
  extern local function void chkIntendedFault_Rresp(Fault_t being_found);
  extern local function void BrespIntendedFault_sample_core();
  extern local function void RrespIntendedFault_sample_core();
  extern local function YesOrNo_t chkFollowingTransCompl_Bresp(Fault_t completed_fault);
  extern local function YesOrNo_t chkFollowingTransCompl_Rresp(Fault_t completed_fault);
  extern local function void BrespFollowingTransCompl_sample_core();
  extern local function void RrespFollowingTransCompl_sample_core();
 
  extern local function void chkIntendedFault_HostRNoLast(Fault_t being_collected);
  extern local function void chkIntendedFault_HostRPrematureLast(Fault_t being_collected);
  extern local function void hostRNoLast_sample_core();
  extern local function void hostRPrematureLast_sample_core();
  extern local function YesOrNo_t chkFollowingTransCompl_HostRNoLast(Fault_t completed_fault);
  extern local function YesOrNo_t chkFollowingTransCompl_HostRPrematureLast(Fault_t completed_fault);
  extern local function void hostRNoLastFollowingTransCompl_sample_core();
  extern local function void hostRPrematureLastFollowingTransCompl_sample_core();
  
  
  extern local function void chkIntendedFault_C2H_CardSide(FaultCode_t me);
  extern local function void chkIntendedFault_H2C_CardSide(FaultCode_t me);
  extern local function void chkGenFault_C2H_CardSide(FaultCode_t code, OccuIntendedFault_t intended_FaultType);
  extern local function void chkGenFault_H2C_CardSide(FaultCode_t code, OccuIntendedFault_t intended_FaultType);
  extern local function vdma_cmdr_seq_item chkFollowingTransCompl_c2hFault(T_TRANS completed, Fault_t completed_fault);
  extern local function vdma_cmdr_seq_item chkFollowingTransCompl_h2cFault(T_TRANS completed, Fault_t completed_fault);
  extern local function void C2H_CardSideFault_sample_core();
  extern local function void H2C_CardSideFault_sample_core();
  
  extern local function YesOrNo_t chkFaultWrongDmaId(DmaId_t dma_id);
  
//  extern function 
  // Methods that shall be implemented
  pure virtual function DmaTransType_t getTransType();

  pure virtual function bit observedNewDesc();
  pure virtual function Desc_t extractNewDesc();

  //pure virtual function bit observedNewData();
  //pure virtual function Data_t extractNewData();

  pure virtual function bit observedNewStatus();
  pure virtual function Status_t extractNewStatus();

  pure virtual function bit observedNewInterrupt();
  pure virtual function Interrupt_t extractNewInterrupt();

  pure virtual function bit observedNewFault();
  pure virtual function Fault_t extractNewFault();


endclass:vdma_mm_monitor



function int vdma_mm_monitor::getDataSize();
  return(this.tcfg.getDataSize(this.trans_type));
endfunction:getDataSize


function void vdma_mm_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);

  `vmg_get_cfgdb_anyone(string, "cfgdb_key", this.cfgdb_key)
  `vmg_get_cfgdb_anyone(TestType_t, $sformatf("%s_test_type", this.cfgdb_key), this.test_type)
  `vmg_get_cfgdb_anyone(SelectFault_t, $sformatf("%s_select_fault", this.cfgdb_key), this.select_fault)
  
  this.ap_desc    = new("ap_desc", this);
  //this.ap_data    = new("ap_data", this);
  this.ap_intr    = new("ap_intr", this);
  this.ap_status  = new("ap_status", this);
  this.ap_fault   = new("ap_fault", this);
  
  
  this.c2h_need_wait_fault = 1;

  this.trans_type = this.getTransType();
  this.monitor_name = $sformatf("VMG_%s_MONITOR", this.trans_type.name);
  collectedData = T_TRANS::type_id::create();
  
  
//  this.vdma_rptr.enableDebugMode();
endfunction:build_phase




function void vdma_mm_monitor::extractDb();
  `vmg_get_cfgdb_anyone(vdma_cmdr_tcfg, "tcfg", this.tcfg)
endfunction:extractDb




function string vdma_mm_monitor::getReportHeader();
  return(this.monitor_name);
endfunction:getReportHeader



function YesOrNo_t vdma_mm_monitor::resetMon();
  this.q_active.delete();
  this.q_completed.delete();
  
  this.info($sformatf("[Initialized !!] q_active and q_completed is being deleted !! (cur q_active_size:%1d), (cur q_completed_size=%1d)", this.q_active.size(), this.q_completed.size()));
  if( (this.q_active.size() == 0) && (this.q_completed.size() == 0) )
    return(YES);
  
  return(NO);
endfunction : resetMon



function void vdma_mm_monitor::collectDesc();
  T_TRANS created;

  if(this.observedNewDesc)begin
    created = T_TRANS::type_id::create(this.makeTransName($sformatf("%s_TRANS", this.trans_type.name)));
    created.setDesc(this.trans_type, this.extractNewDesc, this.tcfg.getDataSize(this.trans_type));
    
    foreach(this.q_fromSeqItem[i]) begin
      if(created.desc.dma_id == this.q_fromSeqItem[i].desc.dma_id) begin
        created.intended_faultType = this.q_fromSeqItem[i].intended_faultType;
      end
    end
    
//7.13
    created.completeEndPkt();

    this.registerNewActiveTrans(created, "COLLECT_DESC");
    this.ap_desc.write(created);
  end
endfunction:collectDesc


//7.7
/*
function void vdma_mm_monitor::collectData();
  T_TRANS found_trans;
  Data_t being_collected;
  
 $display("JH_TEST vdma_mm_monitor::collectData 1 "); 
  if(this.observedNewData)begin
    being_collected = this.extractNewData();
    if(this.select_fault == HAS_WRONG_DMA_ID_FAULT) begin
      found_trans = this.findTrans_hasWrongDmaId(
       DMA_ON_DATA_PHASE, 
         being_collected.side_info.dma_id, 
         "COLLECT_DATA"
        );
    end
    else begin
      $display("JH_TEST vdma_mm_monitor::collectData before findTrans_MustSuccess "); 
      found_trans = this.findTrans_MustSuccess(
       DMA_ON_DATA_PHASE, 
         being_collected.side_info.dma_id, 
         "COLLECT_DATA"
        );
    end
    $display("JH_TEST vdma_mm_monitor::collectData 2 "); 
    
    if (this.getTransType()== ST_H2C || this.getTransType()== MM_H2C) begin
      collectedData.dma_id = found_trans.dma_id;
      collectedData.q_data.push_back(being_collected);
    $display("JH_TEST vdma_mm_monitor::collectData 3 "); 
    end

    //JH FOR MM$display("JH_TEST vdma_mm_monitor::collectData getPktGatheringInfo %s", found_trans.getPktGatheringInfo()); 
    //JH FOR MMif( found_trans.getPktGatheringInfo() != NOT_ON_PKT_GATHERING) begin
    //JH FOR MM  this.updateNumData(found_trans);
    //JH FOR MMend
    //JH FOR MMelse begin 
    //JH FOR MM  found_trans.pushData(being_collected);
    //JH FOR MMend

    //if( (this.select_fault == SAME_NORMAL_OPERATION) || (this.select_fault == HAS_WRONG_DMA_ID_FAULT) ) begin
    // $display("JH_TEST vdma_mm_monitor::collectData 4 "); 
    //  if(being_collected.last == 1) begin
    //     if (this.getTransType()== ST_C2H || this.getTransType()== MM_C2H) begin
    //      this.info($sformatf("vdma_mm_monitor:being_collected.. id : %0d, dst_addr %0h last = %0d",found_trans.desc.dma_id, found_trans.desc.dst_addr, being_collected.last));
    //       this.ap_data.write(found_trans);
    //     end
    //     if (this.getTransType()== ST_H2C || this.getTransType()== MM_H2C) begin
    //       this.info($sformatf("vdma_mm_monitor:being_collected.. id : %0d, src_addr %0h last = %0d",found_trans.desc.dma_id, found_trans.desc.src_addr, being_collected.last));
    //       this.ap_data.write(collectedData);
    //       this.debug($sformatf("%s last vdma_mm_monitor:being_collected.last is ONE.. ",getTransType()));
    //       collectedData.q_data.delete();
    //     end
    // $display("JH_TEST vdma_mm_monitor::collectData 5 "); 
    //  
    //  end
    //end//SAME_NORMAL_OPERATION
      
  end

endfunction:collectData
*/



function void vdma_mm_monitor::collectStatus();
  T_TRANS found_trans;
  Status_t being_collected;

  if(this.observedNewStatus)begin
    being_collected = this.extractNewStatus();
    //$display("JH_TEST vdma_mm_monitor::collectStatus "); 
    found_trans = this.findTrans_MustSuccess(
//7.13
        DMA_ON_RESP_PHASE, 
        //DMA_ON_DATA_PHASE, 
        being_collected.dma_id, 
        "COLLECT_STATUS"
      );
    
    // CPChker : No stat req, but has the status
    if(found_trans.needStatus() == NO)begin 
      this.reportFatal(
        $sformatf("%s_COLLECT_STATUS_FAILED", this.monitor_name),
        $sformatf("Got STATUS w/ dma_id=%1d but the corresponding transaction is not supposed to have it !! correspond transction\n\n    %s\n\n", 
          being_collected.dma_id, found_trans.getInfo
      ));
    end
    
    found_trans.setStatus(being_collected);
    
    this.ap_status.write(found_trans);
  end

endfunction:collectStatus




function void vdma_mm_monitor::collectInterrupt();
  T_TRANS found_trans;
  Interrupt_t being_collected;
  Interrupt_t being_found;
  
  if(this.observedNewInterrupt)begin
    being_collected = this.extractNewInterrupt();
   
   // CPCker : Fault Intr generated
   if( being_collected.vec_id == 'h1f ) begin
     
    found_trans = this.findTrans_forFaultIrq(
//7.13
         DMA_ON_RESP_PHASE, 
         //DMA_ON_DATA_PHASE, 
         being_collected.dma_id, 
         "COLLECT_FAULT_INTERRUPT"
       );
     
      if(this.test_type != FAULT_TEST) this.reportFatal(
         $sformatf("%s_COLLECT_INTERRUPT_FAILED", this.monitor_name),
         $sformatf("Got FAULT INTERRUPT w/ dma_id=%1d, FAULT_IS_ERROR on this test\n\n    %s\n\n", 
            being_collected.dma_id, found_trans.getInfo)
         );
      else begin
        found_trans.setFaultInterrupt(being_collected);
    this.warning(
         $sformatf("%s_COLLECT_INTERRUPT_FAILED, Got FAULT INTERRUPT w/ dma_id=%1d, FAULT_IS_ERROR on this test\n\n    %s\n\n",this.monitor_name,
            being_collected.dma_id, found_trans.getInfo)
         );
      end
   end
   else begin
      //$display("JH_TEST vdma_mm_monitor::collectInterrupt "); 
      found_trans = this.findTrans_MustSuccess(
         DMA_ON_RESP_PHASE, 
         being_collected.dma_id, 
         "COLLECT_INTERRUPT"
         );
   
      // CPChker : No intr req, but has the interrupt
      if(found_trans.needInterrupt() == NO)begin 
            this.reportFatal(
            $sformatf("%s_COLLECT_INTERRUPT_FAILED", this.monitor_name),
            $sformatf("Got INTERRUPT w/ dma_id=%1d but the corresponding transaction is not supposed to have it !! correspond transaction\n\n    %s\n\n", 
               being_collected.dma_id, found_trans.getInfo
            ));
      end
      
      found_trans.setInterrupt(being_collected);
      
   end
   
   this.ap_intr.write(found_trans);
   
  end // observedNewInterrupt
endfunction:collectInterrupt





// TODO:NeedConsiderFault
function void vdma_mm_monitor::collectFault();
  T_TRANS found_trans;
  Fault_t being_collected;
  Fault_t being_found;
  
  if(this.observedNewFault)begin
//    this.warning("Detected --- vdma_mm_monitor::collectFault not implemented yet --- search NeedConsiderFault to know what's going on here.");
    being_collected = this.extractNewFault();
    this.info($sformatf("[collectFault] current_bresp=%1d", this.q_HostFaultBresp[$]));
    
    if( (being_collected.code < 4) || (being_collected.code == 13) ) begin
      this.info("findTrans_DropCase Start !!");
      found_trans = this.findTrans_Fault_DropCase(
        DMA_ON_DATA_PHASE,
        being_collected.dma_id,
        "COLLECT_FAULT"
        );
        if(found_trans == null) begin
          found_trans = this.findTrans_Fault_DropCase(
            DMA_ON_RESP_PHASE,
            being_collected.dma_id,
            "COLLECT_FAULT");
          if(found_trans == null) begin	
            this.reportFatal(
              $sformatf("%s_COLLECT_FAULT_FAILED_IN_FAULT_DROP_CASE", this.monitor_name),
              $sformatf("Got FAULT w/ dma_id=%1d, FAULT_CODE=%1d but the corresponding transaction is not supposed to have it !! correspond transaction\n\n    ", 
              being_collected.dma_id, being_collected.code
              ));
          end
        end
        else if(found_trans != null) begin
          this.warning($sformatf("%s_COLLECT_FAULT, Got FAULT w/ dma_id=%1d, FAULT_CODE=%1d on this test\n\n    %s\n\n",this.monitor_name,
            being_collected.dma_id, being_collected.code, found_trans.getInfo)
            );
          
          
          this.q_faultStored.push_back(being_collected);
          found_trans.setFault(being_collected);
          this.q_faultTrans.push_back(found_trans);
          
          
          if(found_trans.hasFault() == YES) begin
            found_trans.setTransStatusType(DMA_COMPLETED_WO_CONSIDERING_FAULT);
          end
      
        end
    end//fault_code limitation
    else if( ((being_collected.code > 4) && (being_collected.code < 13)) || being_collected.code == 14 ) begin
      this.info("findTrans_NormalCase Start !!");
      this.info($sformatf("Rresp=%1d", being_collected.axi_resp));
      found_trans = this.findTrans_Fault_NormalCase(
        DMA_ON_DATA_PHASE,
        being_collected.dma_id,
        "COLLECT_FAULT"
        );
        if(found_trans == null) begin
          found_trans = this.findTrans_Fault_NormalCase(
            DMA_ON_RESP_PHASE,
            being_collected.dma_id,
            "COLLECT_FAULT");
          if(found_trans == null) begin	
            this.reportFatal(
              $sformatf("%s_COLLECT_FAULT_FAILED_IN_FAULT_NORMAL_CASE", this.monitor_name),
              $sformatf("Got FAULT w/ dma_id=%1d, FAULT_CODE=%1d but the corresponding transaction is not supposed to have it !! correspond transaction\n\n", 
              being_collected.dma_id, being_collected.code
              ));
          end
        end
        else if(found_trans != null) begin
          this.warning($sformatf("%s_COLLECT_FAULT, Got FAULT w/ dma_id=%1d, FAULT_CODE=%1d on this test\n\n    %s\n\n",this.monitor_name,
            being_collected.dma_id, being_collected.code, found_trans.getInfo)
            );
        end
        
        if(this.select_fault == HOST_R_NO_LAST_FAULT) begin
          
          if(being_collected.code == HOST_R_NO_LAST) begin
            this.chkIntendedFault_HostRNoLast(being_collected);
          end
          this.hostRNoLast_sample_core();
          
          found_trans.setFault(being_collected); 
        end//HOST_R_NO_LAST
        else if(this.select_fault == HOST_R_PREMATURE_LAST_FAULT) begin
          if(being_collected.code == HOST_R_PREMATURE_LAST) begin
            this.chkIntendedFault_HostRPrematureLast(being_collected); 
          end//code
          this.hostRPrematureLast_sample_core();
          
          found_trans.setFault(being_collected);
        end//HOST_R_PREMATURE_LAST
        else begin
          this.q_faultStored.push_back(being_collected);
          
          found_trans.setFault(being_collected); 
        
          if(being_collected.code == HOST_B_WRONG_RESP) begin
            this.chkIntendedFault_Bresp(being_collected);
            this.c2h_count_resp++;
          end
        
          if(being_collected.code == HOST_R_WRONG_RESP) begin
            this.chkIntendedFault_Rresp(being_collected);
            this.h2c_count_resp++;
          end
          
          
          this.q_faultTrans.push_back(found_trans);
        end//ELSE
        
        
    end//else if
  
    this.ap_fault.write(found_trans);
  
  end
endfunction:collectFault



function vdma_mm_monitor::T_TRANS vdma_mm_monitor::findTrans(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  string assembled_call_info;
  
  assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, dma_id);
  
  foreach(this.q_active[i])begin
    this.debug($sformatf("findTrans(call_info=[%s]) this.q_active[%1d]=[%s]", assembled_call_info, i, this.q_active[i].getInfo));

    // Data interevaling not allowed
    //JH FORM MMif(trans_status == DMA_ON_DATA_PHASE)begin
    //JH FORM MM  if(this.q_active[i].getTransStatusType == trans_status && this.q_active[i].getDmaId != dma_id )begin
    //JH FORM MM    this.reportFatal(
    //JH FORM MM      $sformatf("%s_DATA_INTERLEAVING_NOT_ALLOWED", this.monitor_name), 
    //JH FORM MM      $sformatf("Tried to find the corresponding trans w/ call_info=[%s], but but the \"%s(dma_id=%1d)\" transaction still waits its data.",
    //JH FORM MM          assembled_call_info,
    //JH FORM MM          this.q_active[i].getNameWithID,
    //JH FORM MM          this.q_active[i].getDmaId
    //JH FORM MM    ));
    //JH FORM MM  end
    //JH FORM MMend
    
    if(this.q_active[i].getTransStatusType() == trans_status && this.q_active[i].getDmaId() == dma_id)begin
      return(this.q_active[i]);
    end
  end

  return(null);
endfunction:findTrans


function vdma_mm_monitor::T_TRANS vdma_mm_monitor::findTrans_onCompleted(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  string assembled_call_info;

  assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, dma_id);


  foreach(this.q_completed[i])begin
    this.debug($sformatf("findTrans_onCompleted(call_info=[%s]) this.q_completed[%1d]=[%s]", assembled_call_info, i, this.q_completed[i].getInfo));

    if(this.q_completed[i].getTransStatusType() == trans_status && this.q_completed[i].getDmaId() == dma_id)begin
      return(this.q_completed[i]);
    end
  end

  return(null);
   
   
endfunction:findTrans_onCompleted



function vdma_mm_monitor::T_TRANS vdma_mm_monitor::findTrans_forFaultIrq(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  string assembled_call_info;

  assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, dma_id);

  // Find Trans on ActiveQ
  foreach(this.q_active[i])begin
    this.debug($sformatf("findTrans_forFaultIrq(call_info=[%s]) this.q_active[%1d]=[%s]", assembled_call_info, i, this.q_active[i].getInfo));

    if(this.q_active[i].getTransStatusType() != DMA_INVALID && this.q_active[i].getDmaId() == dma_id)begin
      return(this.q_active[i]);
    end
  end

  // Find Trans on CompletedQ
  foreach(this.q_completed[i])begin
    this.debug($sformatf("findTrans_onCompleted(call_info=[%s]) this.q_completed[%1d]=[%s]", assembled_call_info, i, this.q_completed[i].getInfo));

    if(this.q_completed[i].getTransStatusType() != DMA_INVALID && this.q_completed[i].getDmaId() == dma_id)begin
      return(this.q_completed[i]);
    end
  end

  return(null);
   
endfunction:findTrans_forFaultIrq


function vdma_mm_monitor::T_TRANS vdma_mm_monitor::findTrans_Fault_NormalCase(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  string assembled_call_info;

  assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, dma_id);

  // Find Trans on ActiveQ
  foreach(this.q_active[i])begin
    this.debug($sformatf("findTrans_Fault_NormalCase(call_info=[%s]) this.q_active[%1d]=[%s]", assembled_call_info, i, this.q_active[i].getInfo));

    if(this.q_active[i].getTransStatusType() != DMA_INVALID  && this.q_active[i].getDmaId() == dma_id)begin
      return(this.q_active[i]);
    end
  end
  
  

  // Find Trans on CompletedQ
  foreach(this.q_completed[i])begin
    this.debug($sformatf("findTrans_onCompleted(call_info=[%s]) this.q_completed[%1d]=[%s]", assembled_call_info, i, this.q_completed[i].getInfo));

    if(this.q_completed[i].getTransStatusType() != DMA_INVALID && this.q_completed[i].getDmaId() == dma_id)begin
      return(this.q_completed[i]);
    end
  end

  return(null);
   
endfunction:findTrans_Fault_NormalCase


function vdma_mm_monitor::T_TRANS vdma_mm_monitor::findTrans_Fault_DropCase(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  string assembled_call_info;

  assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, dma_id);
  

  // Find Trans on ActiveQ
  foreach(this.q_active[i])begin
    this.debug($sformatf("findTrans_Fault_DropCase(call_info=[%s]) this.q_active[%1d]=[%s]", assembled_call_info, i, this.q_active[i].getInfo));

    if(this.q_active[i].getTransStatusType() == DMA_DESC_HAS_DROP_FAULT && this.q_active[i].getDmaId() == dma_id)begin
      return(this.q_active[i]);
    end
  end

  // Find Trans on CompletedQ
  foreach(this.q_completed[i])begin
    this.debug($sformatf("findTrans_onCompleted(call_info=[%s]) this.q_completed[%1d]=[%s]", assembled_call_info, i, this.q_completed[i].getInfo));

    if(this.q_completed[i].getTransStatusType() != DMA_INVALID && this.q_completed[i].getDmaId() == dma_id)begin
      return(this.q_completed[i]);
    end
  end

  return(null);
   
endfunction:findTrans_Fault_DropCase




function vdma_mm_monitor::T_TRANS vdma_mm_monitor::findTrans_MustSuccess(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  T_TRANS found;

 // $display("JH_TEST vdma_mm_monitor::findTrans_MustSuccess");
  found = this.findTrans(trans_status, dma_id, call_info);
  //JH FORM MMif(found == null) begin
  //JH FORM MM   string assembled_call_info;
  //JH FORM MM   assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, dma_id);
  //JH FORM MM    $display("JH_CHECK MustSuccess");
  //JH FORM MM    this.reportFatal(
  //JH FORM MM     $sformatf("%s_NO_CORRESPOND_TRANS", this.monitor_name), 
  //JH FORM MM       $sformatf("Cannot find the corresponding transaction for call_info=[%s]", assembled_call_info)
  //JH FORM MM       );
  //JH FORM MMend

  return(found);
endfunction:findTrans_MustSuccess




function vdma_mm_monitor::T_TRANS vdma_mm_monitor::findTrans_hasWrongDmaId(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  T_TRANS found;
  YesOrNo_t fault_is_WrongDmaId = NO;
 
  fault_is_WrongDmaId = this.chkFaultWrongDmaId(dma_id);
  //$display("JH_TEST vdma_mm_monitor::findTrans_hasWrongDmaId");
  
  if( (fault_is_WrongDmaId == YES) && ( (dma_id > WRONG_DMA_ID) && (dma_id < 65536) ) ) begin
    dma_id = dma_id - WRONG_DMA_ID;
  end
  else if( (fault_is_WrongDmaId == YES) && (dma_id < WRONG_DMA_ID) ) begin
    dma_id = DmaId_t'(dma_id - WRONG_DMA_ID);
  end
  
  found = this.findTrans(trans_status, dma_id, call_info);
  if(found == null) begin
     string assembled_call_info;
     assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, dma_id);
      //$display("JH_CHECK hasWrongDmaId");
      this.reportFatal(
       $sformatf("%s_NO_CORRESPOND_TRANS", this.monitor_name), 
         $sformatf("Cannot find the corresponding transaction for call_info=[%s]", assembled_call_info)
         );
  end

  return(found);
endfunction:findTrans_hasWrongDmaId


function void vdma_mm_monitor::collectCompleted();

  for(int i = 0; i < this.q_active.size(); i++)begin
    
    if(this.q_active[i].completed_flag == 1) begin
      this.q_active[i].completed_count++;
      
      if(this.q_active[i].completed_count == 10000)
        this.q_active[i].setTransStatusType(DMA_COMPLETED_WO_CONSIDERING_FAULT);
    end
    else
      this.q_active[i].completed_count = 0;
    
  end

//$display("[KDS] collectCompleted : q_acitve.size=%d", this.q_active.size());
//$display("[KDS] collectCompleted : hasActiveTrans=%s", this.hasActiveTrans());
  

endfunction : collectCompleted


function void vdma_mm_monitor::collectTransfer();
  this.collectDesc();
  //this.collectData();
  //this.updateDataState();
  this.collectStatus();
  this.collectInterrupt();
  //this.collectFault();
  this.collectCompleted();
endfunction:collectTransfer



function void vdma_mm_monitor::updateState(); endfunction
function void vdma_mm_monitor::updateDataState(); endfunction



function void vdma_mm_monitor::pre_notifyCompletedTrans(T_TRANS completed);
  
//  T_TRANS fromSeqItem;
  Fault_t completed_fault;
  Fault_t over1fault_fault;
  Fault_t completed2_fault;
 
  this.q_completed.push_back(completed); 
  this.num_trans++;
  
  
  if(completed.hasInterrupt == YES) this.num_interrupt++;
  if(completed.hasStatus == YES) this.num_status++;
  
   
//7.7
/*
  if(completed.hasFault() == YES) begin
    completed_fault = completed.getFault();
    
    if(this.select_fault == HOST_R_NO_LAST_FAULT) begin
      foreach(this.q_Complete_HostFaultRNoLast[i])
      
      this.faultHostRNoLast_followingTrans = this.chkFollowingTransCompl_HostRNoLast(completed_fault);
      
      this.hostRNoLastFollowingTransCompl_sample_core();
    end // HOST_R_NO_LAST
    
    else if(this.select_fault == HOST_R_PREMATURE_LAST_FAULT) begin
      foreach(this.q_Complete_HostFaultRPrematureLast[i])
        
      this.faultHostRPrematureLast_followingTrans = this.chkFollowingTransCompl_HostRPrematureLast(completed_fault);
      
      this.hostRPrematureLastFollowingTransCompl_sample_core();
    end//HOST_R_PREMATURE_LAST
    
    else begin 
      foreach(this.q_faultStored[i]) begin
        if(completed.getTransType() == ST_C2H) begin
          if(this.q_faultStored[i].dma_id == completed.dma_id && this.q_faultTrans[i].dma_id == completed.dma_id)begin //TODO
            
            if(this.q_faultStored[i].code == HOST_B_WRONG_RESP) begin
              this.faultBresp_followingTrans = this.chkFollowingTransCompl_Bresp(this.q_faultStored[i]);
              this.BrespFollowingTransCompl_sample_core();
            end
      
         
            if( ((this.q_faultStored[i].code > 4) && (this.q_faultStored[i].code < 8)) || (this.q_faultStored[i].code == 14) || (this.q_faultStored[i].code == 0) ) begin
              this.chkIntendedFault_C2H_CardSide(this.q_faultStored[i].code);
              this.chkGenFault_C2H_CardSide(this.q_faultStored[i].code , this.q_faultTrans[i].intended_faultType); 
        
      
              if(this.chkFollowingTransCompl_c2hFault(this.q_faultTrans[i], this.q_faultStored[i]) == null)
                this.c2h_fault_cov.following_trans = NO;
              else
                this.c2h_fault_cov.following_trans = YES;
      
                this.C2H_CardSideFault_sample_core();
         
            end // fault_code range
        
          end //should_delete
        
        end//C2H  
        
      
        if(completed.getTransType() == ST_H2C) begin
          if( (this.q_faultStored[i].dma_id == completed.dma_id) && (this.q_faultTrans[i].dma_id == completed.dma_id) && (this.q_faultStored[i].code == completed_fault.code) ) begin
          
            if(this.q_faultStored[i].code == HOST_R_WRONG_RESP) begin
              this.faultRresp_followingTrans = this.chkFollowingTransCompl_Rresp(this.q_faultStored[i]);
              this.RrespFollowingTransCompl_sample_core();
            end
            else if( (this.q_faultStored[i].code < 4) || (this.q_faultStored[i].code == 13) ) begin
              this.chkIntendedFault_H2C_CardSide(this.q_faultStored[i].code);
              this.chkGenFault_H2C_CardSide(this.q_faultStored[i].code, this.q_faultTrans[i].intended_faultType);
            
              if(this.chkFollowingTransCompl_h2cFault(this.q_faultTrans[i], this.q_faultStored[i]) == null)
                this.h2c_fault_cov.following_trans = NO;
              else
                this.h2c_fault_cov.following_trans = YES;
              this.H2C_CardSideFault_sample_core();
            end//fault range
            
          end//should_delete
        
          
        end//H2C
      end//q_faultStored
    end //select fault
      
    
    
  //7.7
    if(completed.getTransType() == ST_C2H) begin
      
      if(completed.fault_count.num_fault_code0 > 0)
        this.fault_count.num_fault_c2h_code0++;
      else if(completed.fault_count.num_fault_code5 > 0)
        this.fault_count.num_fault_code5++;
      else if(completed.fault_count.num_fault_code6 > 0)
        this.fault_count.num_fault_code6++;
      else if(completed.fault_count.num_fault_code7 > 0)
        this.fault_count.num_fault_code7++;
      else if(completed.fault_count.num_fault_code14 > 0)
        this.fault_count.num_fault_code14++;
      
      if(completed.fault_count.num_fault_code12 > 0)
        this.fault_count.num_fault_code12++;
      
    end//C2H
    else if(completed.getTransType() == ST_H2C ) begin
      
      if(completed.fault_count.num_fault_code0 > 0)
        this.fault_count.num_fault_h2c_code0++;
      else if(completed.fault_count.num_fault_code1 > 0)
        this.fault_count.num_fault_code1++;
      else if(completed.fault_count.num_fault_code2 > 0)
        this.fault_count.num_fault_code2++;
      else if(completed.fault_count.num_fault_code3 > 0)
        this.fault_count.num_fault_code3++;
      else if(completed.fault_count.num_fault_code13 > 0)
        this.fault_count.num_fault_code13++;
      
      if(completed.fault_count.num_fault_code8 > 0)
        this.fault_count.num_fault_code8++;
      
    end//H2C
    
  end
  
  this.fault_count.num_c2h_card_side_fault = this.fault_count.num_fault_c2h_code0 + this.fault_count.num_fault_code5 + this.fault_count.num_fault_code6 + this.fault_count.num_fault_code7 + this.fault_count.num_fault_code14;
  this.fault_count.num_h2c_card_side_fault = this.fault_count.num_fault_h2c_code0 + this.fault_count.num_fault_code1 + this.fault_count.num_fault_code2 + this.fault_count.num_fault_code3 + this.fault_count.num_fault_code13;
  
  //this.num_data += completed.getNumData();
  */

endfunction:pre_notifyCompletedTrans



function void vdma_mm_monitor::showHistory(string prompt); endfunction:showHistory



function void vdma_mm_monitor::chkIntendedFault_Bresp(Fault_t being_found);
  this.c2h_count_func++;
  this.bresp_idx++;
  
  if(this.q_HostFaultBresp[this.bresp_idx] == being_found.axi_resp)begin
    this.intended_faultBresp = YES;
  end
  else begin
    this.intended_faultBresp = NO;
  end
       
  this.genFaultBresp = YES;
  this.q_Complete_HostFaultBresp.push_back(being_found);
  
  this.BrespIntendedFault_sample_core();
endfunction : chkIntendedFault_Bresp


function void vdma_mm_monitor::chkIntendedFault_Rresp(Fault_t being_found);
  this.h2c_count_func++;
  this.rresp_idx++;
  
  if(this.q_HostFaultRresp[this.rresp_idx] == being_found.axi_resp)
    this.intended_faultRresp = YES;
  else begin
    this.intended_faultRresp = NO;
    
  end
  
  this.genFaultRresp = YES;
  this.q_Complete_HostFaultRresp.push_back(being_found);

  this.RrespIntendedFault_sample_core();
endfunction : chkIntendedFault_Rresp


function void vdma_mm_monitor::BrespIntendedFault_sample_core();
  cg_host_b_wrong_resp.sample();
endfunction : BrespIntendedFault_sample_core


function void vdma_mm_monitor::RrespIntendedFault_sample_core();
  cg_host_r_wrong_resp.sample();
endfunction : RrespIntendedFault_sample_core



function YesOrNo_t vdma_mm_monitor::chkFollowingTransCompl_Bresp(Fault_t completed_fault);
  
  foreach(this.q_Complete_HostFaultBresp[i]) begin
      if(completed_fault.dma_id == this.q_Complete_HostFaultBresp[i].dma_id) begin
        return(YES);
      end
  end
  
  return(NO); 
endfunction : chkFollowingTransCompl_Bresp


function YesOrNo_t vdma_mm_monitor::chkFollowingTransCompl_Rresp(Fault_t completed_fault);
  
  foreach(this.q_Complete_HostFaultRresp[i]) begin
      if(completed_fault.dma_id == this.q_Complete_HostFaultRresp[i].dma_id) begin
        return(YES);
      end
  end
  
  return(NO); 
endfunction : chkFollowingTransCompl_Rresp


function void vdma_mm_monitor::chkIntendedFault_HostRNoLast(Fault_t being_collected);
  this.intended_fault_host_r_no_last = NO;

  this.genFault_host_r_no_last = being_collected.code;
  
  this.q_Complete_HostFaultRNoLast.push_back(being_collected);
  
  if(this.HostFaultRNoLast == YES)
    this.intended_fault_host_r_no_last = YES;
  else
    this.intended_fault_host_r_no_last = NO;
  
endfunction : chkIntendedFault_HostRNoLast

function void vdma_mm_monitor::chkIntendedFault_HostRPrematureLast(Fault_t being_collected);
  this.intended_fault_host_r_premature_last = NO;

  this.genFault_host_r_premature_last = being_collected.code; 
  
  this.q_Complete_HostFaultRPrematureLast.push_back(being_collected);
  
  if(this.q_HostFaultRPrematureLast[this.count_premature_last] == YES)
    this.intended_fault_host_r_premature_last = YES;
  else
    this.intended_fault_host_r_premature_last = NO;
  
  this.count_premature_last++;
endfunction : chkIntendedFault_HostRPrematureLast


function YesOrNo_t vdma_mm_monitor::chkFollowingTransCompl_HostRNoLast(Fault_t completed_fault);
  
  foreach(this.q_Complete_HostFaultRNoLast[i]) begin
    if(completed_fault.dma_id == this.q_Complete_HostFaultRNoLast[i].dma_id) begin
      return(YES);
    end
    
  end
  
  return(NO);
endfunction : chkFollowingTransCompl_HostRNoLast


function YesOrNo_t vdma_mm_monitor::chkFollowingTransCompl_HostRPrematureLast(Fault_t completed_fault);
  foreach(this.q_Complete_HostFaultRPrematureLast[i]) begin
    if(completed_fault.dma_id == this.q_Complete_HostFaultRPrematureLast[i].dma_id) begin
      return(YES);
    end
    
  end
  
  return(NO);
endfunction : chkFollowingTransCompl_HostRPrematureLast


function void vdma_mm_monitor::hostRNoLast_sample_core();
  cg_host_r_no_last.sample(); 
endfunction : hostRNoLast_sample_core


function void vdma_mm_monitor::hostRPrematureLast_sample_core();
  cg_host_r_premature_last.sample();
endfunction : hostRPrematureLast_sample_core

function void vdma_mm_monitor::hostRNoLastFollowingTransCompl_sample_core();
  cg_host_r_no_last_following_trans_complete.sample(); 
endfunction : hostRNoLastFollowingTransCompl_sample_core


function void vdma_mm_monitor::hostRPrematureLastFollowingTransCompl_sample_core();
  cg_host_r_premature_last_following_trans_complete.sample();
endfunction : hostRPrematureLastFollowingTransCompl_sample_core


function void vdma_mm_monitor::BrespFollowingTransCompl_sample_core();
  cg_bresp_following_trans_complete.sample();
endfunction : BrespFollowingTransCompl_sample_core


function void vdma_mm_monitor::RrespFollowingTransCompl_sample_core();
  cg_rresp_following_trans_complete.sample();
endfunction : RrespFollowingTransCompl_sample_core



function void vdma_mm_monitor::chkIntendedFault_C2H_CardSide(FaultCode_t me);
 
  this.info($sformatf("Check intended fault of C2H Card-Side !!"));
  
  case(me)
    DESC_DATA_LENGTH_IS_ZERO : this.c2h_fault_cov.gen_faultType = int '(DESC_DATA_LENGTH_IS_ZERO);
    CARD_R_PREMATURE_LAST    : this.c2h_fault_cov.gen_faultType = int '(CARD_R_PREMATURE_LAST); 
    CARD_R_NO_LAST           : this.c2h_fault_cov.gen_faultType = int '(CARD_R_NO_LAST); 
    CARD_R_WRONG_MTY         : this.c2h_fault_cov.gen_faultType = int '(CARD_R_WRONG_MTY); 
    CARD_R_WRONG_DMA_ID      : this.c2h_fault_cov.gen_faultType = int '(CARD_R_WRONG_DMA_ID);
  endcase
endfunction : chkIntendedFault_C2H_CardSide



function void vdma_mm_monitor::chkIntendedFault_H2C_CardSide(FaultCode_t me);
  
  this.info($sformatf("Check intended fault of C2H Card-Side !!"));
  
  case(me)
    DESC_DATA_LENGTH_IS_ZERO            : this.h2c_fault_cov.gen_faultType = int '(DESC_DATA_LENGTH_IS_ZERO);
    DESC_MID_OF_PKT_BEFORE_START_OF_PKT : this.h2c_fault_cov.gen_faultType = int '(DESC_MID_OF_PKT_BEFORE_START_OF_PKT);
    DESC_SOLO_OF_PKT_DURING_GATHERING   : this.h2c_fault_cov.gen_faultType = int '(DESC_SOLO_OF_PKT_DURING_GATHERING);
    DESC_START_OF_PKT_DURING_GATHERING  : this.h2c_fault_cov.gen_faultType = int '(DESC_START_OF_PKT_DURING_GATHERING);
    DESC_END_OF_PKT_BEFORE_START_OF_PKT : this.h2c_fault_cov.gen_faultType = int '(DESC_END_OF_PKT_BEFORE_START_OF_PKT);
  endcase
   
endfunction : chkIntendedFault_H2C_CardSide


function void vdma_mm_monitor::chkGenFault_C2H_CardSide(FaultCode_t code, OccuIntendedFault_t intended_FaultType);
  
  this.info($sformatf("Check which Fault Type Generated !!"));
  
  if(code == intended_FaultType)begin
    this.c2h_fault_cov.intended_fault = YES;
  end
  else begin
    this.c2h_fault_cov.intended_fault = NO;
  end
   
endfunction : chkGenFault_C2H_CardSide



function void vdma_mm_monitor::chkGenFault_H2C_CardSide(FaultCode_t code, OccuIntendedFault_t intended_FaultType);
 
  this.info($sformatf("Check which Fault Type Generated !!"));
  
  if(code == intended_FaultType) begin
    this.h2c_fault_cov.intended_fault = YES;
  end
  else begin
    this.h2c_fault_cov.intended_fault = NO;
  end
endfunction : chkGenFault_H2C_CardSide



function vdma_class_pkg::vdma_cmdr_seq_item vdma_mm_monitor::chkFollowingTransCompl_c2hFault(T_TRANS completed, Fault_t completed_fault);
  T_TRANS fromSeqItem;
  
  foreach(this.q_fromSeqItem[i]) begin
      this.debug($sformatf("1 [C2H] q_fromSeqItem[%1d].desc.dma_id=%1d, intended_faultType=%1d", i, this.q_fromSeqItem[i].desc.dma_id, this.q_fromSeqItem[i].intended_faultType));
    if( (completed.desc.dma_id == this.q_fromSeqItem[i].desc.dma_id) && (completed_fault.code == this.q_fromSeqItem[i].intended_faultType) ) begin
      fromSeqItem = this.q_fromSeqItem[i];
      this.debug($sformatf("2 [C2H] q_fromSeqItem[%1d].desc.dma_id=%1d, intended_faultType=%1d", i, fromSeqItem.desc.dma_id, fromSeqItem.intended_faultType));
      return(fromSeqItem);
    end
  end//foreach
  
  return(null);
endfunction : chkFollowingTransCompl_c2hFault



function vdma_class_pkg::vdma_cmdr_seq_item vdma_mm_monitor::chkFollowingTransCompl_h2cFault(T_TRANS completed, Fault_t completed_fault);
  T_TRANS fromSeqItem;
  
  foreach(this.q_fromSeqItem[i]) begin
      this.debug($sformatf("1 [H2C] q_fromSeqItem[%1d].desc.dma_id=%1d, intended_faultType=%1d", i, this.q_fromSeqItem[i].desc.dma_id, this.q_fromSeqItem[i].intended_faultType));
    if( (completed.desc.dma_id == this.q_fromSeqItem[i].desc.dma_id) && (completed_fault.code == this.q_fromSeqItem[i].intended_faultType) ) begin
      fromSeqItem = this.q_fromSeqItem[i];
      this.debug($sformatf("2 [H2C] q_fromSeqItem[%1d].desc.dma_id=%1d, intended_faultType=%1d", i, fromSeqItem.desc.dma_id, fromSeqItem.intended_faultType));
      return(fromSeqItem);
    end
  end//foreach
  
  return(null);
endfunction : chkFollowingTransCompl_h2cFault


function void vdma_mm_monitor::C2H_CardSideFault_sample_core();
  cg_card_c2h_fault.sample();
endfunction : C2H_CardSideFault_sample_core


function void vdma_mm_monitor::H2C_CardSideFault_sample_core();
  cg_card_h2c_fault.sample();  
endfunction : H2C_CardSideFault_sample_core



function pmg_pkg::YesOrNo_t vdma_mm_monitor::chkFaultWrongDmaId(DmaId_t dma_id);
  foreach(this.q_fromSeqItem[i]) begin
    if( this.q_fromSeqItem[i].dma_id == DmaId_t'(dma_id - WRONG_DMA_ID) && (this.q_fromSeqItem[i].intended_faultType == 14) ) begin
      return(YES);
    end
  end//foreach
  
  return(NO);
endfunction : chkFaultWrongDmaId


function void vdma_mm_monitor::pushFaultBresp(int me); this.q_HostFaultBresp.push_back(me); endfunction
function void vdma_mm_monitor::pushFaultRresp(int me); this.q_HostFaultRresp.push_back(me); endfunction

function void vdma_mm_monitor::pushFaultHostRNoLast(YesOrNo_t me); this.HostFaultRNoLast = me; endfunction : pushFaultHostRNoLast
function void vdma_mm_monitor::pushFaultHostRPrematureLast(YesOrNo_t me); this.q_HostFaultRPrematureLast.push_back(me); endfunction : pushFaultHostRPrematureLast
`endif // __VDMA_MM_MONITOR_SVH__
