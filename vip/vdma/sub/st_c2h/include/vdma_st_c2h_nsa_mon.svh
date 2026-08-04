`ifndef __VDMA_ST_C2H_NSA_MON_SVH__
`define __VDMA_ST_C2H_NSA_MON_SVH__



class vdma_st_c2h_nsa_mon extends vdma_nsa_mon;

  local virtual ddma_st_c2h_if vif;
  local DataQ_t q_data;

  `uvm_component_utils(vdma_st_c2h_nsa_mon)
  function new(string name="vdma_st_c2h_nsa_mon", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  extern virtual function void connectVif();
  extern virtual function YesOrNo_t hasBwdChannel();  // <------ protocol spec
  extern virtual function void init_core(string call_info="unknown");
  extern virtual function YesOrNo_t isBusy();
  extern virtual protected task updateActiveQ();

  // ------------------------------------------
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
  
  extern virtual function void showHistory(string prompt);

  extern virtual protected function void post_registerNewActiveTrans(T_TRANS new_trans, string call_info="unspeicifed");

  extern virtual function YesOrNo_t resetMon();


  // ---------------------------------------------- internal-impl
  extern local task doOnDataQueue();

endclass:vdma_st_c2h_nsa_mon



function DmaTransType_t vdma_st_c2h_nsa_mon::getTransType();
  return(ST_C2H);
endfunction:getTransType


function void vdma_st_c2h_nsa_mon::connectVif();
  `vmg_get_cfgdb_at_me(virtual ddma_st_c2h_if, "vif", this.vif)
endfunction:connectVif



function YesOrNo_t vdma_st_c2h_nsa_mon::hasBwdChannel();  // <------ protocol spec
  return(YES);
endfunction:hasBwdChannel



function void vdma_st_c2h_nsa_mon::init_core(string call_info="unknown");
  this.warning($sformatf("[INIT] Data queue is being deleted !! (cur:%1d), call_info=[%s]", this.q_data.size, call_info));
  this.q_data.delete();
endfunction:init_core



function YesOrNo_t vdma_st_c2h_nsa_mon::resetMon();
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



function YesOrNo_t vdma_st_c2h_nsa_mon::isBusy();
  if(this.q_data.size != 0) return(YES);
  return(this.hasActiveTrans);
endfunction:isBusy




task vdma_st_c2h_nsa_mon::updateActiveQ();
  fork
    super.updateActiveQ();
    this.doOnDataQueue();
  join
endtask:updateActiveQ




task vdma_st_c2h_nsa_mon::doOnDataQueue();

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


function DmaTransType_t vdma_st_c2h_nsa_mon::getMonitorTransType();
  return(ST_C2H);
endfunction:getMonitorTransType


function bit vdma_st_c2h_nsa_mon::observedNewDesc();
  return(this.vif.IsDescHS());
endfunction:observedNewDesc


function Desc_t vdma_st_c2h_nsa_mon::extractNewDesc();
  return(this.vif.GetDesc());
endfunction:extractNewDesc



function bit vdma_st_c2h_nsa_mon::observedNewData();
  return(this.vif.IsDataHS());
endfunction:observedNewData


function Data_t vdma_st_c2h_nsa_mon::extractNewData();
  return(this.vif.GetData());
endfunction:extractNewData


function bit vdma_st_c2h_nsa_mon::chkLastData();
endfunction:chkLastData


function bit vdma_st_c2h_nsa_mon::observedNewStatus();
  return(this.vif.IsStatusHS());
endfunction:observedNewStatus


function Status_t vdma_st_c2h_nsa_mon::extractNewStatus();
  return(this.vif.GetStatus());
endfunction:extractNewStatus



function bit vdma_st_c2h_nsa_mon::observedNewInterrupt();
  return(this.vif.IsInterruptHS());
endfunction:observedNewInterrupt


function Interrupt_t vdma_st_c2h_nsa_mon::extractNewInterrupt();
  return(this.vif.GetInterrupt());
endfunction:extractNewInterrupt




function void vdma_st_c2h_nsa_mon::post_registerNewActiveTrans(T_TRANS new_trans, string call_info="unspeicifed");
	if(new_trans.desc.len == 0) begin
		new_trans.setTransStatusType(DMA_DESC_HAS_DROP_FAULT);
	end
endfunction:post_registerNewActiveTrans



function void vdma_st_c2h_nsa_mon::showHistory(string prompt);
  this.showReportHeader(this.mon_name, prompt);
  this.info($sformatf("   - Number of transactions : %1d", this.num_trans));
  this.info($sformatf("   - Number of status       : %1d", this.num_status));
  this.info($sformatf("   - Number of interrupt    : %1d", this.num_interrupt));
  this.info($sformatf("   - Number of data         : %1d", this.num_data));
  this.info($sformatf("   - c2h_count_resp = %1d, c2h_count_func = %1d", this.c2h_count_resp, this.c2h_count_func));
  this.showReportBar(prompt);
endfunction:showHistory


`endif // __VDMA_ST_C2H_NSA_MON_SVH__
