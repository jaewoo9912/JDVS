`ifndef __VDMA_SA_MON_SVH__
`define __VDMA_SA_MON_SVH__




virtual class vdma_sa_mon extends vdma_mon;
  

  // ------------------------------------------------------------------------
  // DEFINITIONS
  // ------------------------------------------------------------------------
  typedef T_TRANS Q_TRANS[$];

  // ------------------------------------------------------------------------
  // VARIABLES
  // ------------------------------------------------------------------------


  // ------------------------------- tracking
  protected T_TRANS q_completed[$];
  protected T_TRANS q_ready2completed[$];
            T_TRANS collected_data;

  local YesOrNo_t trans_ongo = NO;
  local int exp_trans_store = 0;
  
  protected T_TRANS q_from_seq_item[$];
  
  protected T_TRANS q_fault_trans[$];
  
  protected YesOrNo_t flag_c2h_start_simulation = NO; 
  protected YesOrNo_t flag_h2c_start_simulation = NO; 


  function new(string name="vdma_sa_mon", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  // ---------------------------- uvm
  extern virtual function void build_phase(uvm_phase phase);


  // ---------------------------- vmg_mon-impl
  extern virtual protected function void updateState();
  extern virtual function void pre_notifyCompletedTrans(T_TRANS completed);


  // ------------------------------------ vdma_sa_mon-api
  extern function void pushItemFromDriver(T_TRANS me);
  extern virtual local function void updateH2CNumData(T_TRANS found_trans);


  // ---------------------------- vdma_sa_mon-impl
  extern protected function T_TRANS findTrans_forFaultIrq(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  extern protected function T_TRANS findTrans_Fault_DropCase(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  extern protected function T_TRANS findTrans_Fault_NormalCase(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  extern virtual function YesOrNo_t resetMon();


  // ---------------------------------------------- internal-impl
  extern protected function T_TRANS configureFaultTransOnDropCase(Fault_t collected_fault);
  extern protected function T_TRANS configureFaultTransOnNormalCase(Fault_t collected_fault);
 
  // ---------------------------- collection
  extern virtual function void collectDesc();
  extern virtual function void collectData();
  extern virtual function void collectStatus();
  extern virtual function void collectInterrupt();
  extern virtual function void collectFault();
  
  extern protected virtual function void decideStartSimFlag();
  pure virtual function void assignSimStartFlag();
  
endclass:vdma_sa_mon




function void vdma_sa_mon::build_phase(uvm_phase phase);
  super.build_phase(phase);

  this.collected_data = T_TRANS::type_id::create();
  
  this.decideStartSimFlag();
endfunction:build_phase



function YesOrNo_t vdma_sa_mon::resetMon();
  super.resetMon();
  this.q_completed.delete();
  return(YES);
endfunction:resetMon


function void vdma_sa_mon::collectDesc();
  T_TRANS created;

  if(this.observedNewDesc)begin
    created = T_TRANS::type_id::create(this.makeTransName($sformatf("%s_TRANS", this.trans_type.name)));
    created.setDesc(this.trans_type, this.extractNewDesc, this.tcfg.getDataSize(this.trans_type));
    
    foreach(this.q_from_seq_item[i]) begin
      if(DutParamDmaId_t'(created.desc.dma_id) == DutParamDmaId_t'(this.q_from_seq_item[i].desc.dma_id)) begin
        created.intended_faultType = this.q_from_seq_item[i].intended_faultType;
      end
    end
    this.registerNewActiveTrans(created, "COLLECT_DESC");
    
    this.ap_desc.write(created);
    
    this.assignSimStartFlag();
  end
endfunction:collectDesc



function void vdma_sa_mon::collectData(); endfunction:collectData



function void vdma_sa_mon::collectStatus();
  T_TRANS found_trans;
  Status_t being_collected;

  if(this.observedNewStatus)begin
    being_collected = this.extractNewStatus();
    being_collected.dma_id = DutParamDmaId_t'(being_collected.dma_id);
    found_trans = this.findTrans_MustSuccess( DMA_ON_RESP_PHASE, DutParamDmaId_t'(being_collected.dma_id), "COLLECT_STATUS");
    
    if(found_trans.needStatus() == NO)begin 
      this.reportFatal(
        $sformatf("%s_COLLECT_STATUS_FAILED", this.mon_name),
        $sformatf("Got STATUS w/ dma_id=%1d but the corresponding transaction is not supposed to have it !! correspond transction\n\n    %s\n\n", 
          DutParamDmaId_t'(being_collected.dma_id), found_trans.getInfo
      ));
    end
    found_trans.setStatus(being_collected);
    
    this.ap_status.write(found_trans);
  end
endfunction:collectStatus




function void vdma_sa_mon::collectInterrupt();
  T_TRANS found_trans;
  Interrupt_t being_collected;
  Interrupt_t being_found;
  
  if(this.observedNewInterrupt)begin
    being_collected = this.extractNewInterrupt();
    being_collected.dma_id = DutParamDmaId_t'(being_collected.dma_id);
   
   // CPCker : Fault Intr generated
   if( being_collected.vec_id == 'h1f ) begin
    found_trans = this.findTrans_forFaultIrq( DMA_ON_RESP_PHASE, DutParamDmaId_t'(being_collected.dma_id), "COLLECT_FAULT_INTERRUPT");
     
    if(this.tcfg.test_type != FAULT_TEST)begin
      this.reportFatal(
       $sformatf("%s_COLLECT_INTERRUPT_FAILED", this.mon_name),
       $sformatf("Got FAULT INTERRUPT w/ dma_id=%1d, FAULT_IS_ERROR on this test\n\n    %s\n\n", 
          DutParamDmaId_t'(being_collected.dma_id), found_trans.getInfo)
      );
    end
    else begin
      found_trans.setFaultInterrupt(being_collected);
      this.warning(
        $sformatf("%s_COLLECT_INTERRUPT_FAILED, Got FAULT INTERRUPT w/ dma_id=%1d, FAULT_IS_ERROR on this test\n\n    %s\n\n",this.mon_name,
           DutParamDmaId_t'(being_collected.dma_id), found_trans.getInfo)
        );
      end
   end
   else begin
    found_trans = this.findTrans_MustSuccess( DMA_ON_RESP_PHASE, DutParamDmaId_t'(being_collected.dma_id), "COLLECT_INTERRUPT");
    
    // CPChker : No intr req, but has the interrupt
    if(found_trans.needInterrupt() == NO)begin 
          this.reportFatal(
          $sformatf("%s_COLLECT_INTERRUPT_FAILED", this.mon_name),
          $sformatf("Got INTERRUPT w/ dma_id=%1d but the corresponding transaction is not supposed to have it !! correspond transaction\n\n    %s\n\n", 
             DutParamDmaId_t'(being_collected.dma_id), found_trans.getInfo
          ));
    end
    found_trans.setInterrupt(being_collected);
   end
   
   this.ap_intr.write(found_trans);
  end
endfunction:collectInterrupt





function void vdma_sa_mon::collectFault(); endfunction:collectFault



function vdma_sa_mon::T_TRANS vdma_sa_mon::findTrans_forFaultIrq(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  string assembled_call_info;

  assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, DutParamDmaId_t'(dma_id));
  foreach(this.q_active[i])begin
    this.debug($sformatf("findTrans_forFaultIrq(call_info=[%s]) this.q_active[%1d]=[%s]", assembled_call_info, i, this.q_active[i].getInfo));
    if(this.q_active[i].getTransStatusType() != DMA_INVALID && DutParamDmaId_t'(this.q_active[i].getDmaId()) == DutParamDmaId_t'(dma_id))begin
      return(this.q_active[i]);
    end
  end
  foreach(this.q_fault_trans[i])begin
    this.debug($sformatf("findTrans(call_info=[%s]) this.q_fault_trans[%1d]=[%s]", assembled_call_info, i, this.q_fault_trans[i].getInfo));
    if(this.q_fault_trans[i].getTransStatusType() != DMA_INVALID && DutParamDmaId_t'(this.q_fault_trans[i].getDmaId()) == DutParamDmaId_t'(dma_id))begin
      return(this.q_fault_trans[i]);
    end
  end
  return(null);
endfunction:findTrans_forFaultIrq


function vdma_sa_mon::T_TRANS vdma_sa_mon::findTrans_Fault_NormalCase(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  string assembled_call_info;

  assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, DutParamDmaId_t'(dma_id));
  foreach(this.q_active[i])begin
    this.debug($sformatf("findTrans_Fault_NormalCase(call_info=[%s]) this.q_active[%1d]=[%s]", assembled_call_info, i, this.q_active[i].getInfo));
    if(this.q_active[i].getTransStatusType() != DMA_INVALID  && DutParamDmaId_t'(this.q_active[i].getDmaId()) == DutParamDmaId_t'(dma_id))begin
      return(this.q_active[i]);
    end
  end
  foreach(this.q_fault_trans[i])begin
    this.debug($sformatf("findTrans(call_info=[%s]) this.q_fault_trans[%1d]=[%s]", assembled_call_info, i, this.q_fault_trans[i].getInfo));
    if(this.q_fault_trans[i].getTransStatusType() != DMA_INVALID && DutParamDmaId_t'(this.q_fault_trans[i].getDmaId()) == DutParamDmaId_t'(dma_id))begin
      return(this.q_fault_trans[i]);
    end
  end
  return(null);
endfunction:findTrans_Fault_NormalCase


function vdma_sa_mon::T_TRANS vdma_sa_mon::findTrans_Fault_DropCase(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  string assembled_call_info;

  assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, DutParamDmaId_t'(dma_id));
  
  foreach(this.q_active[i])begin
    this.debug($sformatf("findTrans_Fault_DropCase(call_info=[%s]) this.q_active[%1d]=[%s]", assembled_call_info, i, this.q_active[i].getInfo));
    if(this.q_active[i].getTransStatusType() == DMA_DESC_HAS_DROP_FAULT && DutParamDmaId_t'(this.q_active[i].getDmaId()) == DutParamDmaId_t'(dma_id))begin
      return(this.q_active[i]);
    end
  end
  foreach(this.q_fault_trans[i])begin
    this.debug($sformatf("findTrans(call_info=[%s]) this.q_completed[%1d]=[%s]", assembled_call_info, i, this.q_fault_trans[i].getInfo));
    if(this.q_fault_trans[i].getTransStatusType() == DMA_DESC_HAS_DROP_FAULT && DutParamDmaId_t'(this.q_fault_trans[i].getDmaId) == DutParamDmaId_t'(dma_id))begin
      return(this.q_fault_trans[i]);
    end
  end
  
  return(null);
endfunction:findTrans_Fault_DropCase




function vdma_sa_mon::T_TRANS vdma_sa_mon::configureFaultTransOnDropCase(Fault_t collected_fault);
  T_TRANS found_trans;
  
  found_trans = this.findTrans_Fault_DropCase(DMA_ON_DATA_PHASE, DutParamDmaId_t'(collected_fault.dma_id), "COLLECT_FAULT");
  
  if(found_trans == null) begin
    found_trans = this.findTrans_Fault_DropCase(DMA_ON_RESP_PHASE, DutParamDmaId_t'(collected_fault.dma_id), "COLLECT_FAULT");
    if(found_trans == null) begin	
      this.reportFatal(
        $sformatf("%s_COLLECT_FAULT_FAILED_IN_FAULT_DROP_CASE", this.mon_name),
        $sformatf("Got FAULT w/ dma_id=%1d, FAULT_CODE=%1d but the corresponding transaction is not supposed to have it !! correspond transaction\n\n    ", 
        DutParamDmaId_t'(collected_fault.dma_id), collected_fault.code
        ));
    end
  end
  else if(found_trans != null) begin
    this.warning($sformatf("%s_COLLECT_FAULT, Got FAULT w/ dma_id=%1d, FAULT_CODE=%1d on this test\n\n    %s\n\n",this.mon_name,
      DutParamDmaId_t'(collected_fault.dma_id), collected_fault.code, found_trans.getInfo)
      );
    
    found_trans.setFault(collected_fault);
    this.q_fault_trans.push_back(found_trans);
    
    if(found_trans.hasFault == YES) begin
      found_trans.setTransStatusType(DMA_COMPLETED_WO_CONSIDERING_FAULT);
    end
  end
 
 return(found_trans);
endfunction




function vdma_sa_mon::T_TRANS vdma_sa_mon::configureFaultTransOnNormalCase(Fault_t collected_fault);
  T_TRANS found_trans;

  found_trans = this.findTrans_Fault_NormalCase(DMA_ON_DATA_PHASE, DutParamDmaId_t'(collected_fault.dma_id), "COLLECT_FAULT");
  
  if(found_trans == null) begin
    found_trans = this.findTrans_Fault_NormalCase(DMA_ON_RESP_PHASE, DutParamDmaId_t'(collected_fault.dma_id), "COLLECT_FAULT");
    if(found_trans == null) begin	
      this.reportFatal(
        $sformatf("%s_COLLECT_FAULT_FAILED_IN_FAULT_NORMAL_CASE", this.mon_name),
        $sformatf("Got FAULT w/ dma_id=%1d, FAULT_CODE=%1d but the corresponding transaction is not supposed to have it !! correspond transaction\n\n", 
        DutParamDmaId_t'(collected_fault.dma_id), collected_fault.code
        ));
    end
  end
  else if(found_trans != null) begin
    this.warning($sformatf("%s_COLLECT_FAULT, Got FAULT w/ dma_id=%1d, FAULT_CODE=%1d on this test\n\n    %s\n\n",this.mon_name,
      DutParamDmaId_t'(collected_fault.dma_id), collected_fault.code, found_trans.getInfo)
      );
  end
  
  found_trans.setFault(collected_fault);
  
  return(found_trans);
endfunction



function void vdma_sa_mon::updateState();
  for(int i = 0; i < this.q_active.size(); i++)begin
    if(this.q_active[i].completed_flag == 1) begin
      this.q_active[i].completed_count++;
      
      if(this.q_active[i].completed_count == 10000)
        this.q_active[i].setTransStatusType(DMA_COMPLETED_WO_CONSIDERING_FAULT);
    end
    else
      this.q_active[i].completed_count = 0;
  end
endfunction:updateState



function void vdma_sa_mon::pre_notifyCompletedTrans(T_TRANS completed);
  this.q_completed.push_back(completed); 
  this.q_completed.delete();
  
  this.num_trans++;
  
  if(completed.hasInterrupt == YES) this.num_interrupt++;
  if(completed.hasStatus == YES)    this.num_status++;
endfunction:pre_notifyCompletedTrans



function void vdma_sa_mon::pushItemFromDriver(T_TRANS me); this.q_from_seq_item.push_back(me); endfunction

function void vdma_sa_mon::updateH2CNumData(T_TRANS found_trans); endfunction


function void vdma_sa_mon::decideStartSimFlag();
  if(this.data_direction_type.only_c2h_test == YES      && this.data_direction_type.only_h2c_test == NO)  this.flag_h2c_start_simulation = YES; 
  else if(this.data_direction_type.only_c2h_test == NO  && this.data_direction_type.only_h2c_test == YES) this.flag_c2h_start_simulation = YES;
  else if(this.data_direction_type.only_c2h_test == NO && this.data_direction_type.only_h2c_test == NO)   this.fatal("NOT SUPPORTED", "There is no data_direction_type in this test !!");
endfunction : decideStartSimFlag

`endif // __VDMA_SA_MON_SVH__
