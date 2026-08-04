`ifndef __VDMA_ST_C2H_SA_MON_SVH__
`define __VDMA_ST_C2H_SA_MON_SVH__



class vdma_st_c2h_sa_mon extends vdma_sa_st_mon;

  local virtual ddma_st_c2h_if vif;
  local DataQ_t q_data;
  
  local YesOrNo_t trans_ongo      = NO;
  local int       exp_trans_store = 0;

  `uvm_component_utils(vdma_st_c2h_sa_mon)
  function new(string name="vdma_st_c2h_sa_mon", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  extern virtual function void connectVif();
  extern virtual function YesOrNo_t hasBwdChannel();  // <------ protocol spec
  extern virtual function void init_core(string call_info="unknown");
  extern virtual function YesOrNo_t isBusy();
  extern virtual protected task updateActiveQ();

  // ------------------------------------------
  extern virtual function void collectData();
  
  extern virtual function DmaTransType_t getTransType();
  extern virtual function DmaTransType_t getMonitorTransType();
  extern virtual function bit observedNewDesc();
  extern virtual function Desc_t extractNewDesc();
  extern virtual function bit observedNewData();
  extern virtual function Data_t extractNewData();
  extern virtual function bit chkLastData();
  extern virtual function bit observedNewStatus();
  extern virtual function Status_t extractNewStatus();
  extern virtual function bit observedNewInterrupt();
  extern virtual function Interrupt_t extractNewInterrupt();
  extern virtual function bit observedNewFault();
  extern virtual function Fault_t extractNewFault();
  

  extern virtual protected function void post_registerNewActiveTrans(T_TRANS new_trans, string call_info="unspeicifed");

  extern virtual function YesOrNo_t resetMon();


  // ---------------------------------------------- internal-impl
  extern local function T_TRANS findTrans_hasWrongDmaId(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  extern local function YesOrNo_t chkFaultWrongDmaId(DmaId_t dma_id);
  
  extern local task doOnDataQueue();

  extern virtual function void assignSimStartFlag();
endclass:vdma_st_c2h_sa_mon



function DmaTransType_t vdma_st_c2h_sa_mon::getTransType();
  return(ST_C2H);
endfunction:getTransType


function void vdma_st_c2h_sa_mon::connectVif();
  `vmg_get_cfgdb_at_me(virtual ddma_st_c2h_if, "vif", this.vif)
endfunction:connectVif



function YesOrNo_t vdma_st_c2h_sa_mon::hasBwdChannel();  // <------ protocol spec
  return(YES);
endfunction:hasBwdChannel



function void vdma_st_c2h_sa_mon::init_core(string call_info="unknown");
  this.warning($sformatf("[INIT] Data queue is being deleted !! (cur:%1d), call_info=[%s]", this.q_data.size, call_info));
  this.q_data.delete();
endfunction:init_core



function YesOrNo_t vdma_st_c2h_sa_mon::resetMon();
  YesOrNo_t super_reset_completed = NO;
  super_reset_completed = super.resetMon();
  
  if(this.q_data.size() != 0)
    this.warning($sformatf("[Initialized !!] But q_data is not empty (q_data.size=%1d) !!", this.q_data.size()));
  else
    this.info($sformatf("[Initialized !!] q_data in c2h_mon (q_data.size=%1d) !!", this.q_data.size()));
  
  this.q_data.delete();
  
  if( (this.q_data.size() == 0) && (super_reset_completed == YES))
    return(YES);
  
  return(NO);
endfunction:resetMon



function YesOrNo_t vdma_st_c2h_sa_mon::isBusy();
  if(this.q_data.size != 0) return(YES);
  if(this.flag_c2h_start_simulation == NO) return(YES);
  return(this.hasActiveTrans);
endfunction:isBusy




function void vdma_st_c2h_sa_mon::collectData();
  T_TRANS found_trans;
  Data_t being_collected;
  Len_t  expected_len;

  int cnt_trans = 0;
  int exp_last = 0;
  int exp_trans = 0;
  
  if(this.observedNewData)begin
    being_collected = this.extractNewData();
    being_collected.side_info.dma_id =  DutParamDmaId_t'(being_collected.side_info.dma_id);
    
    case(this.tcfg.select_fault)
      HAS_WRONG_DMA_ID_FAULT : found_trans = this.findTrans_hasWrongDmaId(DMA_ON_DATA_PHASE, DutParamDmaId_t'(being_collected.side_info.dma_id), "COLLECT_DATA");
      ALL_RANDOM_FAULT       : found_trans = this.findTrans_hasWrongDmaId(DMA_ON_DATA_PHASE, DutParamDmaId_t'(being_collected.side_info.dma_id), "COLLECT_DATA");
      default                : found_trans = this.findTrans_MustSuccess(DMA_ON_DATA_PHASE, DutParamDmaId_t'(being_collected.side_info.dma_id), "COLLECT_DATA");
    endcase
    
    found_trans.pushData(being_collected);

    if( (this.tcfg.select_fault == SAME_NORMAL_OPERATION) || (this.tcfg.select_fault == HAS_WRONG_DMA_ID_FAULT) || (this.tcfg.select_fault == ALL_RANDOM_FAULT) ) begin
      expected_len = found_trans.desc.len;
      if(this.trans_ongo == NO) begin
        cnt_trans = expected_len / CARD_DATA_BYTE_WIDTH;
        exp_last = expected_len%CARD_DATA_BYTE_WIDTH;
        if(cnt_trans == 0) exp_trans = 0;
        else if((cnt_trans != 0) && (exp_last == 0)) exp_trans = cnt_trans - 1;
        else exp_trans = cnt_trans ;
        this.trans_ongo = YES;
      end
      else begin
        exp_trans = this.exp_trans_store;
      end
      
      if(exp_trans == 0) begin
        this.ap_data.write(found_trans);
        this.trans_ongo = NO;
      end
      else begin
        exp_trans--;
        this.exp_trans_store = exp_trans;
        this.debug($sformatf("[3]vdma_sa_mon:being_collected.. id : %0d, len = %0h dst_addr %0h last = %0h, cnt_trans = %0h exp_last = %0h exp_trans = %0h",DutParamDmaId_t'(found_trans.desc.dma_id), expected_len, found_trans.desc.dst_addr, being_collected.last, cnt_trans, exp_last, exp_trans));
      end
    end//SAME_NORMAL_OPERATION
  end
endfunction:collectData




task vdma_st_c2h_sa_mon::updateActiveQ();
  fork
    super.updateActiveQ();
    this.doOnDataQueue();
  join
endtask:updateActiveQ




task vdma_st_c2h_sa_mon::doOnDataQueue();

  localparam int TIMEOUT_CYCLE = 500;

  forever begin
    Data_t being_collected;

    wait(this.q_data.size > 0);
    being_collected = this.q_data.pop_front();

    `pmg_disable_fork_begin
        begin
          while(1)begin:COLLECT_C2H_DATA
            T_TRANS found;
        
            found = this.findTrans(DMA_ON_DATA_PHASE, being_collected.side_info.dma_id, "COLLECT_C2H_DATA");
            if(found != null)begin
              this.debug($sformatf("COLLECT_C2H_DATA -- found target [%s]", found.getInfo));
              found.pushData(being_collected);
              break;
            end
            else begin
              this.warning($sformatf("COLLECT_C2H_DATA -- Cannot find target -- maybe its \"DATA\" before \"DESC\""));
            end
            this.waitCycle();
          end
        end
        begin
          this.watchTimer(TIMEOUT_CYCLE, "COLLECT_C2H_DATA");
        end
    `pmg_disable_fork_end
  end
endtask:doOnDataQueue



function vdma_sa_mon::T_TRANS vdma_st_c2h_sa_mon::findTrans_hasWrongDmaId(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  T_TRANS found;
  YesOrNo_t fault_is_WrongDmaId = NO;

  fault_is_WrongDmaId = this.chkFaultWrongDmaId(DutParamDmaId_t'(dma_id));

  if( (fault_is_WrongDmaId == YES) && ( (DutParamDmaId_t'(dma_id) > WRONG_DMA_ID) && (DutParamDmaId_t'(dma_id) <= DMA_ID_MAX_VALUE) ) ) begin
    dma_id = DutParamDmaId_t'(dma_id) - WRONG_DMA_ID;
  end
  else if( (fault_is_WrongDmaId == YES) && (DutParamDmaId_t'(dma_id) < WRONG_DMA_ID) ) begin
    dma_id = DutParamDmaId_t'(dma_id - WRONG_DMA_ID);
  end
 
  found = this.findTrans(trans_status, DutParamDmaId_t'(dma_id), call_info);
  if(found == null) begin
     string assembled_call_info;
     assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, DutParamDmaId_t'(dma_id));
      this.reportFatal(
       $sformatf("%s_NO_CORRESPOND_TRANS", this.mon_name), 
         $sformatf("Cannot find the corresponding transaction for call_info=[%s]", assembled_call_info)
         );
  end
  return(found);
endfunction:findTrans_hasWrongDmaId



function YesOrNo_t vdma_st_c2h_sa_mon::chkFaultWrongDmaId(DmaId_t dma_id);
  foreach(this.q_from_seq_item[i]) begin
    if( DutParamDmaId_t'(this.q_from_seq_item[i].dma_id) == DutParamDmaId_t'(dma_id - WRONG_DMA_ID) && (this.q_from_seq_item[i].intended_faultType == 14) ) begin
      return(YES);
    end
  end
  return(NO);
endfunction: chkFaultWrongDmaId



function DmaTransType_t vdma_st_c2h_sa_mon::getMonitorTransType();
  return(ST_C2H);
endfunction:getMonitorTransType


function bit vdma_st_c2h_sa_mon::observedNewDesc();
  return(this.vif.IsDescHS());
endfunction:observedNewDesc


function Desc_t vdma_st_c2h_sa_mon::extractNewDesc();
  return(this.vif.GetDesc());
endfunction:extractNewDesc



function bit vdma_st_c2h_sa_mon::observedNewData();
  return(this.vif.IsDataHS());
endfunction:observedNewData


function Data_t vdma_st_c2h_sa_mon::extractNewData();
  return(this.vif.GetData());
endfunction:extractNewData


function bit vdma_st_c2h_sa_mon::chkLastData();
endfunction:chkLastData


function bit vdma_st_c2h_sa_mon::observedNewStatus();
  return(this.vif.IsStatusHS());
endfunction:observedNewStatus


function Status_t vdma_st_c2h_sa_mon::extractNewStatus();
  return(this.vif.GetStatus());
endfunction:extractNewStatus



function bit vdma_st_c2h_sa_mon::observedNewInterrupt();
  return(this.vif.IsInterruptHS());
endfunction:observedNewInterrupt


function Interrupt_t vdma_st_c2h_sa_mon::extractNewInterrupt();
  return(this.vif.GetInterrupt());
endfunction:extractNewInterrupt





function bit vdma_st_c2h_sa_mon::observedNewFault();
  return(this.vif.IsFaultHS());
endfunction:observedNewFault


function void vdma_st_c2h_sa_mon::post_registerNewActiveTrans(T_TRANS new_trans, string call_info="unspeicifed");
	if(new_trans.desc.len == 0) begin
		new_trans.setTransStatusType(DMA_DESC_HAS_DROP_FAULT);
	end
endfunction:post_registerNewActiveTrans


function Fault_t vdma_st_c2h_sa_mon::extractNewFault();
  return(this.vif.GetFault());
endfunction:extractNewFault



function void vdma_st_c2h_sa_mon::assignSimStartFlag();
  this.flag_c2h_start_simulation = YES;  
endfunction : assignSimStartFlag




`endif // __VDMA_ST_C2H_SA_MON_SVH__
