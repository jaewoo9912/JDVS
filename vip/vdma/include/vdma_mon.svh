`ifndef __VDMA_MON_SVH__
`define __VDMA_MON_SVH__


/*



  TODO
    Define API


*/


virtual class vdma_mon extends vmg_mon#(.T_SEQ_ITEM(vdma_seq_item));

  protected vdma_mst_tcfg tcfg;
  protected DmaTransType_t trans_type;
  protected string mon_name;

  protected int num_trans; 
  protected int num_interrupt, num_status, num_data;
  
  protected DataDirectionType_t data_direction_type;
  
  
  uvm_analysis_port#(T_TRANS) ap_desc;
  uvm_analysis_port#(T_TRANS) ap_data;
  uvm_analysis_port#(T_TRANS) ap_intr;
  uvm_analysis_port#(T_TRANS) ap_status;
  uvm_analysis_port#(T_TRANS) ap_fault;
  function new(string name="vdma_mon", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // --------------------------------------- uvm
  extern virtual function void build_phase(uvm_phase phase);


  // ---------------------------- vmg-common
  extern virtual local function string getReportHeader();


  // ---------------------------- vmg_mon-impl
  extern virtual function void pre_notifyCompletedTrans(T_TRANS completed);


  // ------------------------------- vdma_mon-api
  extern function int getDataSize();
  extern virtual function YesOrNo_t resetMon();

  // ------------------------------ vdma_mon-impl
  pure virtual function DmaTransType_t getTransType();
  pure virtual function bit observedNewDesc();
  pure virtual function Desc_t extractNewDesc();
  pure virtual function bit observedNewData();
  pure virtual function Data_t extractNewData();
  pure virtual function bit observedNewStatus();
  pure virtual function Status_t extractNewStatus();
  pure virtual function bit observedNewInterrupt();
  pure virtual function Interrupt_t extractNewInterrupt();
  pure virtual function bit observedNewFault();
  pure virtual function Fault_t extractNewFault();

  extern virtual protected function void collectTransfer();
  pure virtual function void collectDesc();
  pure virtual function void collectData();
  pure virtual function void collectStatus();
  pure virtual function void collectInterrupt();
  pure virtual function void collectFault();

  extern virtual protected function void updateDataState();

  extern protected function T_TRANS findTrans(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  extern protected function T_TRANS findTrans_MustSuccess(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);


endclass:vdma_mon


function int vdma_mon::getDataSize(); return(this.tcfg.getDataSize(this.trans_type)); endfunction


function void vdma_mon::build_phase(uvm_phase phase);
  super.build_phase(phase);

  `vmg_get_cfgdb_at_me(vdma_mst_tcfg, "tcfg", this.tcfg)
  this.trans_type = this.getTransType();
  this.data_direction_type = this.tcfg.data_direction_type;
  this.mon_name = $sformatf("%s_MON", this.trans_type.name);
  this.ap_desc   = new("ap_desc", this);
  this.ap_data   = new("ap_data", this);
  this.ap_intr   = new("ap_intr", this);
  this.ap_status = new("ap_status", this);
  this.ap_fault  = new("ap_fault", this);
endfunction:build_phase
  

function string vdma_mon::getReportHeader(); return(this.mon_name); endfunction



function vdma_mon::T_TRANS vdma_mon::findTrans(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  string assembled_call_info;
  
  assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, dma_id);
  
  foreach(this.q_active[i])begin
    this.debug($sformatf("findTrans(call_info=[%s]) this.q_active[%1d]=[%s]", assembled_call_info, i, this.q_active[i].getInfo));
    // Data interevaling not allowed
    if(trans_status == DMA_ON_DATA_PHASE)begin
      if(this.q_active[i].getTransStatusType == trans_status && DutParamDmaId_t'(this.q_active[i].getDmaId) != DutParamDmaId_t'(dma_id) )begin
        this.reportFatal(
          $sformatf("%s_DATA_INTERLEAVING_NOT_ALLOWED", this.mon_name), 
          $sformatf("Tried to find the corresponding trans w/ call_info=[%s], but but the \"%s(dma_id=%1d)\" transaction still waits its data.",
              assembled_call_info,
              this.q_active[i].getNameWithID,
              DutParamDmaId_t'(this.q_active[i].getDmaId)
        ));
      end
    end
    if(this.q_active[i].getTransStatusType() == trans_status && DutParamDmaId_t'(this.q_active[i].getDmaId()) == DutParamDmaId_t'(dma_id))begin
      return(this.q_active[i]);
    end
  end
  return(null);
endfunction:findTrans




function vdma_mon::T_TRANS vdma_mon::findTrans_MustSuccess(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  T_TRANS found;

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
endfunction:findTrans_MustSuccess



function void vdma_mon::collectTransfer();
  this.collectDesc();
  this.collectData();
  this.updateDataState();
  this.collectStatus();
  this.collectInterrupt();
  this.collectFault();
endfunction:collectTransfer



function void vdma_mon::pre_notifyCompletedTrans(T_TRANS completed);
  this.num_trans++;
  this.num_data += completed.getNumData();
  if(completed.hasInterrupt == YES) this.num_interrupt++;
  if(completed.hasStatus == YES) this.num_status++;
endfunction:pre_notifyCompletedTrans


function void vdma_mon::updateDataState(); endfunction


// TODO:NeedReview -- what is the YesOrNo_t for?
function YesOrNo_t vdma_mon::resetMon();
  this.q_active.delete();
  return(YES);
endfunction:resetMon



`endif // __VDMA_MON_SVH__
