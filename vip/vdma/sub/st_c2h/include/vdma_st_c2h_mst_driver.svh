`ifndef __VDMA_ST_C2H_MST_DRIVER_SVH__
`define __VDMA_ST_C2H_MST_DRIVER_SVH__



class vdma_st_c2h_mst_driver extends vdma_mst_driver;

  local virtual ddma_st_c2h_if vif;

  local Data_t      q_need_serve_data[$];

  local UIntRange_t timing_param_desc2data;
  local UIntRange_t timing_param_data2data;

  `uvm_component_utils(vdma_st_c2h_mst_driver)
  
  function new(string name="vdma_st_c2h_mst_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // ----------- vmg-vip built-in
  extern virtual function void connectVif();
  extern virtual task driveItem(T_SEQ_ITEM item);
  extern virtual function YesOrNo_t isBusy();
  extern virtual function void init_core(string call_info="unknown");
  extern virtual protected function void setupTimingParamProperty();


  // ----------- vmg-vdma specific
  extern virtual function DmaTransType_t getTransType();
  extern virtual task doOnData();
  extern virtual function void setDescVld(bit valid);
  extern virtual function bit getDescRdy();
  extern virtual function void setDescPayload(Desc_t payload);
  extern virtual function void setInterruptRdy(bit ready);
  extern virtual function void setStatusRdy(bit ready);
  extern virtual function void setFaultRdy(bit ready);

  // ------------- st_c2h specific
  extern local task driveData(Data_t me);
  
  extern virtual function YesOrNo_t resetDriver();
endclass:vdma_st_c2h_mst_driver



function DmaTransType_t vdma_st_c2h_mst_driver::getTransType(); return(ST_C2H); endfunction



task vdma_st_c2h_mst_driver::driveItem(T_SEQ_ITEM item);
  super.driveItem(item);

  while(item.hasData() == YES)begin
    Data_t need_served;
    
    need_served = item.popData();
    this.q_need_serve_data.push_back(need_served);
  end

endtask:driveItem




function void vdma_st_c2h_mst_driver::connectVif();
  `vmg_get_cfgdb_at_me(virtual ddma_st_c2h_if, "vif", this.vif)
endfunction:connectVif





function void vdma_st_c2h_mst_driver::init_core(string call_info="unknown");

  super.init_core(call_info);

  this.q_need_serve_data.delete();

  this.vif.InitDescMstPerspective();
  this.vif.InitDataMstPerspective();

endfunction:init_core




function YesOrNo_t vdma_st_c2h_mst_driver::resetDriver();
  YesOrNo_t super_reset_completed = NO;
  YesOrNo_t reset_completed = NO;
  
  super_reset_completed = super.resetDriver();
  
  this.q_need_serve_data.delete();
 
  this.vif.InitDescMstPerspective();
  this.vif.InitDataMstPerspective();
  
  if( (super_reset_completed == YES) && (this.q_need_serve_data.size == 0) )
    return(YES);
  
  return(NO);
endfunction : resetDriver



function void vdma_st_c2h_mst_driver::setupTimingParamProperty();
  super.setupTimingParamProperty();

  this.timing_param_data2data = this.tcfg.getTimingParamData2Data(ST_C2H);
endfunction:setupTimingParamProperty




task vdma_st_c2h_mst_driver::doOnData();

  forever begin
    Data_t being_drived;

    wait(this.q_need_serve_data.size > 0);
    being_drived = this.q_need_serve_data.pop_front();
    this.driveData(being_drived);
  end
endtask:doOnData




task vdma_st_c2h_mst_driver::driveData(Data_t me);
  int issuing_interval;
  
  issuing_interval = this.pickRandUIntInTheRange(this.timing_param_data2data);

  this.debug($sformatf("driveData w/ issuing_interval=%1d cycles -- [%s]", 
      issuing_interval, 
      MakeString_Data_t(me)
  ));

  if( issuing_interval != 0 ) begin
  	this.vif.data_valid <= 0;
  	this.waitCycle(issuing_interval);
  end

  this.vif.data_valid <= 1;
  this.vif.SetDataPayload(me);

  while(1)begin
    this.waitCycle();
    if(this.vif.data_ready)begin
      if(this.q_need_serve_data.size == 0)begin
        this.vif.data_valid <= 0;
        this.waitCycle();
      end
      break;
    end
  end

endtask:driveData




function void vdma_st_c2h_mst_driver::setDescVld(bit valid); this.vif.desc_valid <= valid; endfunction
function bit vdma_st_c2h_mst_driver::getDescRdy(); return(this.vif.desc_ready); endfunction
function void vdma_st_c2h_mst_driver::setDescPayload(Desc_t payload); this.vif.SetDescPayload(payload); endfunction

function void vdma_st_c2h_mst_driver::setInterruptRdy(bit ready); this.vif.interrupt_ready <= ready; endfunction

function void vdma_st_c2h_mst_driver::setStatusRdy(bit ready); this.vif.status_ready <= ready; endfunction

function void vdma_st_c2h_mst_driver::setFaultRdy(bit ready); this.vif.fault_ready <= ready; endfunction



function YesOrNo_t vdma_st_c2h_mst_driver::isBusy();
  if(this.q_need_serve_data     .size != 0) return(YES);

  return(super.isBusy);
endfunction:isBusy









`endif // __VDMA_ST_C2H_MST_DRIVER_SVH__
