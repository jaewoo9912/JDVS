`ifndef __VDMA_NSA_MON_SVH__
`define __VDMA_NSA_MON_SVH__


/*

    [IMPORTANT_NOTICE]
       * Unique dma_id assumed (spec can be updated)

  TODO
    * Refactoring
       - deeply nested if/else statement
       - big class

*/


virtual class vdma_nsa_mon extends vdma_mon;
  

  // ------------------------------------------------------------------------
  // DEFINITIONS
  // ------------------------------------------------------------------------
  typedef T_TRANS Q_TRANS[$];


  // ------------------------------------------------------------------------
  // VARIABLES
  // ------------------------------------------------------------------------

  local YesOrNo_t trans_ongo = NO;
  local int exp_trans_store = 0;

  protected int h2c_count_resp = 0;
  protected int c2h_count_resp = 0;
  protected int c2h_count_func = 0;
  protected int h2c_count_func = 0;
  
  local Data_t q_h2c_pkt_data[$];
  
  function new(string name="vdma_nsa_mon", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  // ------------------------------------ vdma_nsa_mon-impl
  extern virtual local function void updateH2CNumData(T_TRANS found_trans);



  // ---------------------------- vmg_mon-impl
  extern virtual protected function void updateState();


  // ---------------------------- vdma_nsa_mon-impl
  extern virtual function void collectDesc();
  extern virtual function void collectData();
  extern virtual function void collectStatus();
  extern virtual function void collectInterrupt();

  extern virtual function void collectFault();
  extern virtual function bit observedNewFault();
  extern virtual function Fault_t extractNewFault();

  


endclass:vdma_nsa_mon




function void vdma_nsa_mon::collectDesc();
  T_TRANS created;

  if(this.observedNewDesc)begin
    created = T_TRANS::type_id::create(this.makeTransName($sformatf("%s_TRANS", this.trans_type.name)));
    created.setDesc(this.trans_type, this.extractNewDesc, this.tcfg.getDataSize(this.trans_type));
    
    this.registerNewActiveTrans(created, "COLLECT_DESC");
    this.ap_desc.write(created);
  end
endfunction:collectDesc




function void vdma_nsa_mon::collectData();
  T_TRANS found_trans;
  Data_t being_collected;
  Len_t  expected_len;

  int cnt_trans = 0;
  int exp_last = 0;
  int exp_trans = 0;
  
  int q_h2c_pkt_data_size = 0;
  
  if(this.observedNewData)begin
    being_collected = this.extractNewData();
    being_collected.side_info.dma_id =  DutParamDmaId_t'(being_collected.side_info.dma_id);

    // TODO:Make warning for fault scenarios
    found_trans = this.findTrans_MustSuccess(
      DMA_ON_DATA_PHASE, 
      DutParamDmaId_t'(being_collected.side_info.dma_id), 
      "COLLECT_DATA"
    );

    if(this.getTransType == ST_H2C && found_trans.getPktGatheringInfo != NOT_ON_PKT_GATHERING) begin
      this.updateH2CNumData(found_trans);
      this.q_h2c_pkt_data.push_back(being_collected);
      
      if(being_collected.last == 1) begin
        found_trans.q_data.delete();
        q_h2c_pkt_data_size = this.q_h2c_pkt_data.size();
        
        for(int i = 0; i < q_h2c_pkt_data_size; i++) begin
          Data_t being_served;
          
          being_served = this.q_h2c_pkt_data.pop_front();
          found_trans.q_data.push_back(being_served);
        end
      end
    end
    else 
      found_trans.pushData(being_collected);
    
    if(being_collected.last == 1)begin
      this.debug($sformatf("being_collected.. id : %0d, dst_addr %0h last = %0d", DutParamDmaId_t'(found_trans.desc.dma_id), DutParamHostAddr_t'(found_trans.desc.dst_addr), being_collected.last));
      this.ap_data.write(found_trans);
    end
  end
endfunction:collectData




function void vdma_nsa_mon::collectStatus();
  T_TRANS found_trans;
  Status_t being_collected;

  if(this.observedNewStatus)begin
    being_collected = this.extractNewStatus();
    being_collected.dma_id = DutParamDmaId_t'(being_collected.dma_id);
    found_trans = this.findTrans_MustSuccess(
        DMA_ON_RESP_PHASE, 
        DutParamDmaId_t'(being_collected.dma_id), 
        "COLLECT_STATUS"
      );

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




function void vdma_nsa_mon::collectInterrupt();
  T_TRANS found_trans;
  Interrupt_t being_collected;
  Interrupt_t being_found;
  
  if(this.observedNewInterrupt)begin
    being_collected = this.extractNewInterrupt();
    being_collected.dma_id = DutParamDmaId_t'(being_collected.dma_id);
  
    if(being_collected.vec_id == VEC_ID_FAULT) return;
  
    found_trans = this.findTrans_MustSuccess(
      DMA_ON_RESP_PHASE, 
      DutParamDmaId_t'(being_collected.dma_id), 
      "COLLECT_INTERRUPT"
    );
  
    if(found_trans.needInterrupt() == NO)begin 
      this.reportFatal(
      $sformatf("%s_COLLECT_INTERRUPT_FAILED", this.mon_name),
      $sformatf("Got INTERRUPT w/ dma_id=%1d but the corresponding transaction was non-interrupt !! correspond transaction\n\n    %s\n\n", 
         DutParamDmaId_t'(being_collected.dma_id), found_trans.getInfo
      ));
    end
    found_trans.setInterrupt(being_collected);
    this.ap_intr.write(found_trans);
  end
endfunction:collectInterrupt




function void vdma_nsa_mon::updateState();
  foreach(this.q_active[i])begin
    if(this.q_active[i].completed_flag == 1) begin // TODO:NeedClean (after fault_mon redesign, seq item should update its state by itself.
      this.q_active[i].setTransStatusType(DMA_COMPLETED_WO_CONSIDERING_FAULT);
    end
  end
endfunction:updateState


function bit vdma_nsa_mon::observedNewFault(); endfunction 
function Fault_t vdma_nsa_mon::extractNewFault(); endfunction
function void vdma_nsa_mon::collectFault(); endfunction

function void vdma_nsa_mon::updateH2CNumData(T_TRANS found_trans); endfunction



`endif // __VDMA_NSA_MON_SVH__
