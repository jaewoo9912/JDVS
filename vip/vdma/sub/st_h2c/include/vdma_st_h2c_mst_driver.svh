`ifndef __VDMA_ST_H2C_MST_DRIVER_SVH__
`define __VDMA_ST_H2C_MST_DRIVER_SVH__



class vdma_st_h2c_mst_driver extends vdma_mst_driver;


  local virtual ddma_st_h2c_if vif;

  local UIntRange_t timing_param_data_assert_rdy;

  `uvm_component_utils(vdma_st_h2c_mst_driver)
  
  function new(string name="vdma_st_h2c_mst_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  // ----------- vmg-vip built-in
  extern virtual function void connectVif();
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

  extern virtual function YesOrNo_t resetDriver();
endclass:vdma_st_h2c_mst_driver




function DmaTransType_t vdma_st_h2c_mst_driver::getTransType(); return(ST_H2C); endfunction


function void vdma_st_h2c_mst_driver::setDescVld(bit valid); this.vif.desc_valid <= valid; endfunction
function bit vdma_st_h2c_mst_driver::getDescRdy(); return(this.vif.desc_ready); endfunction
function void vdma_st_h2c_mst_driver::setDescPayload(Desc_t payload); this.vif.SetDescPayload(payload); endfunction

function void vdma_st_h2c_mst_driver::setInterruptRdy(bit ready); this.vif.interrupt_ready <= ready; endfunction

function void vdma_st_h2c_mst_driver::setStatusRdy(bit ready); this.vif.status_ready <= ready; endfunction

function void vdma_st_h2c_mst_driver::setFaultRdy(bit ready); this.vif.fault_ready <= ready; endfunction



task vdma_st_h2c_mst_driver::doOnData();
  int assert_rdy_interval;

  forever begin
    @this.ev_need_serve_bwd_channel;

    assert_rdy_interval = this.pickRandUIntInTheRange(this.timing_param_data_assert_rdy);

	if( assert_rdy_interval != 0 ) begin
    	this.vif.data_ready <= 0;
    	this.waitCycle(assert_rdy_interval);
	end

    this.vif.data_ready <= 1;
    this.waitCycle(1);

	if( assert_rdy_interval != 0 ) begin
    	this.vif.data_ready <= FlipCoin();
    	this.waitCycle(1);
	end
  end
endtask:doOnData





function void vdma_st_h2c_mst_driver::init_core(string call_info="unknown");
  super.init_core(call_info);

  this.vif.InitDescMstPerspective();
  this.vif.data_ready <= FlipCoin();
endfunction:init_core




function YesOrNo_t vdma_st_h2c_mst_driver::resetDriver();
  YesOrNo_t super_reset_completed = NO;

  super_reset_completed = super.resetDriver();
  
  this.info($sformatf("[Initialized !!] h2c_mst_driver !!"));
  this.vif.InitDescMstPerspective();
  this.vif.data_ready <= FlipCoin();
  
  if(super_reset_completed == YES)
    return(YES);
  
  return(NO);
endfunction:resetDriver



function void vdma_st_h2c_mst_driver::connectVif();
  `vmg_get_cfgdb_at_me(virtual ddma_st_h2c_if, "vif", this.vif)
endfunction:connectVif



function void vdma_st_h2c_mst_driver::setupTimingParamProperty();
  super.setupTimingParamProperty();

  this.timing_param_data_assert_rdy = this.tcfg.getTimingParamDataAssertRdy(ST_H2C);
endfunction:setupTimingParamProperty



`endif // __VDMA_ST_H2C_MST_DRIVER_SVH__
