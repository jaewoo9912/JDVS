`ifndef __VDMA_MST_DRIVER_SVH__
`define __VDMA_MST_DRIVER_SVH__


/*


  ** Design note
      - Common things implemented (ex] DESC)



  TODO: 
    * NeedReview -- back2back transfer
*/


virtual class vdma_mst_driver extends vmg_mst_driver#(.T_SEQ_ITEM(vdma_seq_item));

  protected vdma_mst_tcfg tcfg;
  protected DmaTransType_t trans_type;
  protected string driver_name; 

  local Desc_t q_need_serve_desc[$];

  local UIntRange_t timing_param_desc2desc;
  local UIntRange_t timing_param_interrupt_rdy;
  local UIntRange_t timing_param_fault_rdy;
  local UIntRange_t timing_param_status_rdy;

  local vdma_mon mon;
  
  // TODO:DefineSchemes
  // Keep completed transactions for sometimes since some of them could be reported as faults
  local vdma_seq_item q_completed[$];


  function new(string name="vdma_mst_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

  extern virtual function YesOrNo_t isBusy();

  extern virtual protected function void extractDb();

  extern virtual task driveItem(T_SEQ_ITEM item);

  extern function YesOrNo_t hasBwdChannel();

  extern protected virtual function void showBfmTimingParam(string prompt="");

  extern virtual function YesOrNo_t needSubscribe();

  // ---------------
  extern local task doOnDesc();
  pure virtual task doOnData();
  extern local task doOnInterrupt();
  extern local task doOnStatus();
  extern local task doOnFault();
  extern local task doOnCompletedTrans();

  extern virtual function void init_core(string call_info="unknown");

  extern function void prepare(vdma_mon mon);

  extern virtual task driveDesc(Desc_t me);

  extern virtual protected function void setupTimingParamProperty();


  pure virtual function void connectVif();
  pure virtual function DmaTransType_t getTransType();

  pure virtual function void setDescVld(bit valid);
  pure virtual function bit getDescRdy();
  pure virtual function void setDescPayload(Desc_t payload);
  pure virtual function void setInterruptRdy(bit ready);
  pure virtual function void setStatusRdy(bit ready);
  pure virtual function void setFaultRdy(bit ready);

  extern virtual function YesOrNo_t resetDriver();

endclass:vdma_mst_driver



function YesOrNo_t vdma_mst_driver::needSubscribe(); return(YES); endfunction


function void vdma_mst_driver::init_core(string call_info="unknown");
  super.init_core(call_info);
  this.q_need_serve_desc.delete();
  this.setInterruptRdy(FlipCoin());
  this.setStatusRdy(FlipCoin());
  this.setFaultRdy(FlipCoin());
endfunction:init_core




function YesOrNo_t vdma_mst_driver::resetDriver();
  YesOrNo_t reset_completed = NO;
  
  super.init_core();
  
  this.info($sformatf("[Initialized !!] q_need_serve_desc & size=%1d", this.q_need_serve_desc.size()));
  this.q_need_serve_desc.delete();
  
  this.setInterruptRdy(FlipCoin());
  this.setStatusRdy(FlipCoin());
  this.setFaultRdy(FlipCoin());
  
  if(this.q_need_serve_desc.size() == 0) return(YES);
  
  return(NO);
endfunction : resetDriver



function YesOrNo_t vdma_mst_driver::hasBwdChannel(); return(YES); endfunction


function YesOrNo_t vdma_mst_driver::isBusy();
  if(this.q_need_serve_desc.size != 0) return(YES);
  return(this.mon.isBusy);
endfunction:isBusy



function void vdma_mst_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);

  this.trans_type = this.getTransType();
  this.driver_name = $sformatf("VMG_%s_DRIVER", this.trans_type.name);
endfunction:build_phase


function void vdma_mst_driver::setupTimingParamProperty();
  this.timing_param_desc2desc     = this.tcfg.getTimingParamDesc2Desc(this.trans_type);
  this.timing_param_interrupt_rdy = this.tcfg.getTimingParamInterruptAssertRdy(this.trans_type);
  this.timing_param_status_rdy    = this.tcfg.getTimingParamStatusAssertRdy(this.trans_type);
  this.timing_param_fault_rdy     = this.tcfg.getTimingParamFaultAssertRdy(this.trans_type);
endfunction:setupTimingParamProperty



task vdma_mst_driver::doOnDesc();
  forever begin
    Desc_t being_drived;

    wait(this.q_need_serve_desc.size > 0);
    being_drived = this.q_need_serve_desc.pop_front();
    this.driveDesc(being_drived);
  end
endtask:doOnDesc




function void vdma_mst_driver::extractDb();
  `vmg_get_cfgdb_at_me(vdma_mst_tcfg, "tcfg", this.tcfg)
  this.setupTimingParamProperty();
endfunction:extractDb



task vdma_mst_driver::run_phase(uvm_phase phase);
  fork
    super.run_phase(phase);

    this.doOnDesc();
    this.doOnData();
    this.doOnInterrupt();
    this.doOnStatus();
    this.doOnFault();
    this.doOnCompletedTrans();
  join
endtask:run_phase




function void vdma_mst_driver::prepare(vdma_mon mon); this.mon = mon; endfunction



task vdma_mst_driver::driveItem(T_SEQ_ITEM item);
  vdma_sa_mon sa_mon;
  
  $cast(sa_mon, this.mon);
  
  this.q_need_serve_desc.push_back(item.getDesc);
  if(item.intended_faultType != -1) sa_mon.pushItemFromDriver(item);
  //TODO:fault_mon -- if(item.intended_faultType != -1) this.mon.pushItemFromDriver(item);
endtask:driveItem



function void vdma_mst_driver::showBfmTimingParam(string prompt="");
  StringQ_t result;

  result = this.tcfg.makeStringList_DmaBfmTimingParam(this.trans_type);
  foreach(result[i]) this.info($sformatf("%s%s", prompt, result[i]));
endfunction:showBfmTimingParam





task vdma_mst_driver::doOnInterrupt();
  int assert_rdy_interval;

  forever begin
    @this.ev_need_serve_bwd_channel;
    assert_rdy_interval = this.pickRandUIntInTheRange(this.timing_param_interrupt_rdy);

    if( assert_rdy_interval != 0 ) begin
      this.setInterruptRdy(0);
      this.waitCycle(assert_rdy_interval);
    end
    this.setInterruptRdy(1);
    this.waitCycle(1);

    if( assert_rdy_interval != 0 ) begin
      this.setInterruptRdy(FlipCoin());
      this.waitCycle(1);
    end
  end
endtask:doOnInterrupt




task vdma_mst_driver::doOnStatus();
  int assert_rdy_interval;

  forever begin
    @this.ev_need_serve_bwd_channel;

    assert_rdy_interval = this.pickRandUIntInTheRange(this.timing_param_status_rdy);
    if( assert_rdy_interval != 0 ) begin
      this.setStatusRdy(0);
      this.waitCycle(assert_rdy_interval);
    end
    this.setStatusRdy(1);
    this.waitCycle(1);

    if( assert_rdy_interval != 0 ) begin
      this.setStatusRdy(FlipCoin());
      this.waitCycle(1);
    end
  end
endtask:doOnStatus






task vdma_mst_driver::doOnFault();
  int assert_rdy_interval;

  forever begin
    @this.ev_need_serve_bwd_channel;

    assert_rdy_interval = 0;//this.pickRandUIntInTheRange(this.timing_param_fault_rdy);
    if( assert_rdy_interval != 0 ) begin
      this.setFaultRdy(0);
      this.waitCycle(assert_rdy_interval);
    end

    this.setFaultRdy(1);
    this.waitCycle(1);

    if( assert_rdy_interval != 0 ) begin
      this.setFaultRdy(FlipCoin());
      this.waitCycle(1);
    end
  end
endtask:doOnFault




task vdma_mst_driver::doOnCompletedTrans();
  forever begin
    T_SEQ_ITEM completed;

    this.sub.waitTrans(completed);
    this.q_completed.push_back(completed);
    this.q_completed.delete();

    this.info($sformatf("------------------------------------------------------------------------------------------------------------------"));
    this.info($sformatf("FOUND_COMPLETED -- Found a completed transaction \"%s\", keep it for sometimes, because it can be fault.", completed.getNameWithID));
    this.info($sformatf("completed=[%s]", completed.getInfo));
    this.info($sformatf("------------------------------------------------------------------------------------------------------------------"));
  end
endtask:doOnCompletedTrans



task vdma_mst_driver::driveDesc(Desc_t me);
  int issuing_interval;

  issuing_interval = this.pickRandUIntInTheRange(this.timing_param_desc2desc);

  if( issuing_interval != 0 ) begin
    this.setDescVld(0);
    this.waitCycle(issuing_interval);
  end

  this.setDescVld(1);
  this.setDescPayload(me);

  while(1)begin
    this.waitCycle();
    if(this.getDescRdy)begin
      if(this.q_need_serve_desc.size == 0)begin
        this.setDescVld(0);
        this.waitCycle();
      end
      break;
    end
  end
endtask:driveDesc







`endif // __VDMA_MST_DRIVER_SVH__
