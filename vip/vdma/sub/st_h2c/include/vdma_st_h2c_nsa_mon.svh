`ifndef __VDMA_ST_H2C_NSA_MON_SVH__
`define __VDMA_ST_H2C_NSA_MON_SVH__



class vdma_st_h2c_nsa_mon extends vdma_nsa_mon;

  local virtual ddma_st_h2c_if vif;
  local vdma_h2c_pkt_gathering_trkr gathering_trkr;

  `uvm_component_utils(vdma_st_h2c_nsa_mon)

  function new(string name="vdma_st_h2c_nsa_mon", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  extern virtual function void build_phase(uvm_phase phase);
  extern virtual protected function void updateDataState();
  extern virtual function void connectVif();
  extern virtual function YesOrNo_t hasBwdChannel();
  extern virtual function void init_core(string call_info="unknown");

  // ---------------------------------------
  extern virtual function DmaTransType_t getTransType();
  extern virtual function bit observedNewDesc();
  extern virtual function Desc_t extractNewDesc();
  extern virtual function bit observedNewData();
  extern virtual function Data_t extractNewData();
  extern virtual function bit observedNewStatus();
  extern virtual function Status_t extractNewStatus();
  extern virtual function bit observedNewInterrupt();
  extern virtual function Interrupt_t extractNewInterrupt();

  extern virtual function void showHistory(string prompt);

  extern virtual protected function void post_registerNewActiveTrans (T_TRANS new_trans, string call_info="unspeicifed");

  extern virtual function YesOrNo_t resetMon();
  // ---------------------------------------
  extern protected function Q_TRANS findTrans_gathering(DmaId_t dma_id, string call_info);

  extern virtual local function void updateH2CNumData(T_TRANS found_trans);

  extern virtual protected function StringQ_t getInfoList_Extended();
  

endclass:vdma_st_h2c_nsa_mon



function void vdma_st_h2c_nsa_mon::init_core(string call_info="unknown");
  this.gathering_trkr.init();
endfunction:init_core



function YesOrNo_t vdma_st_h2c_nsa_mon::resetMon();
  YesOrNo_t reset_completed;
  YesOrNo_t super_reset_completed;
  
  super_reset_completed = super.resetMon();
  reset_completed = this.gathering_trkr.reset();
  if( (reset_completed == YES) && (super_reset_completed == YES) )
    return(YES);
  
  return(NO);
endfunction:resetMon


function void vdma_st_h2c_nsa_mon::build_phase(uvm_phase phase);
  super.build_phase(phase);
  this.gathering_trkr = vdma_h2c_pkt_gathering_trkr::type_id::create(this.get_name, this);
  this.gathering_trkr.integrateTcfg(this.tcfg);
endfunction:build_phase



function StringQ_t vdma_st_h2c_nsa_mon::getInfoList_Extended();
  return(this.gathering_trkr.getInfoList);
endfunction:getInfoList_Extended



function YesOrNo_t vdma_st_h2c_nsa_mon::hasBwdChannel();
  return(YES);
endfunction:hasBwdChannel


function void vdma_st_h2c_nsa_mon::connectVif();
  `vmg_get_cfgdb_at_me(virtual ddma_st_h2c_if, "vif", this.vif)
endfunction:connectVif



function void vdma_st_h2c_nsa_mon::updateDataState();
  T_TRANS	q_found_trans[$];
  T_TRANS	target_trans;
  DmaId_t	target_dma_id;
  
	foreach( this.gathering_trkr.q_active_pkt[i] ) begin
		if( this.gathering_trkr.q_active_pkt[i].cur_in_data == this.gathering_trkr.q_active_pkt[i].num_planned_data ) begin
			target_dma_id = DutParamDmaId_t'(this.gathering_trkr.q_active_pkt[i].pkt_dma_id);
			this.debug($sformatf("RELEASE H2C GATHERING PKT DESCs, dma_id=%1d", target_dma_id));
			q_found_trans = this.findTrans_gathering(target_dma_id, "RELEASE_DESC");
			this.debug($sformatf("First Find %1d gathering seq!", q_found_trans.size()));
			this.debug("--------------------------");
			foreach(q_found_trans[j]) begin
				this.debug($sformatf("desc=[%s]", q_found_trans[j].getInfo));
			end
			this.debug("--------------------------");
			
			while( q_found_trans.size() != 0 ) begin
				target_trans = q_found_trans.pop_front();
				target_trans.completeEndPkt();
			end
			this.debug($sformatf("DELETE active pkt queue for dma_id = %1d", DutParamDmaId_t'(this.gathering_trkr.q_active_pkt[i].pkt_dma_id)));
//			this.gathering_trkr.q_active_pkt.delete(i); <--------- TODO:NeedCheck
			this.gathering_trkr.q_active_pkt[i].num_planned_data = -1;
		end
	end
endfunction:updateDataState



function DmaTransType_t vdma_st_h2c_nsa_mon::getTransType();
  return(ST_H2C);
endfunction:getTransType


function bit vdma_st_h2c_nsa_mon::observedNewDesc();
  return(this.vif.IsDescHS());
endfunction:observedNewDesc


function Desc_t vdma_st_h2c_nsa_mon::extractNewDesc();
  return(this.vif.GetDesc());
endfunction:extractNewDesc



function bit vdma_st_h2c_nsa_mon::observedNewData();
  return(this.vif.IsDataHS());
endfunction:observedNewData



function Data_t vdma_st_h2c_nsa_mon::extractNewData();
  return(this.vif.GetData());
endfunction:extractNewData



function bit vdma_st_h2c_nsa_mon::observedNewStatus();
  return(this.vif.IsStatusHS());
endfunction:observedNewStatus


function Status_t vdma_st_h2c_nsa_mon::extractNewStatus();
  return(this.vif.GetStatus());
endfunction:extractNewStatus



function bit vdma_st_h2c_nsa_mon::observedNewInterrupt();
  return(this.vif.IsInterruptHS());
endfunction:observedNewInterrupt


function Interrupt_t vdma_st_h2c_nsa_mon::extractNewInterrupt();
  return(this.vif.GetInterrupt());
endfunction:extractNewInterrupt


function void vdma_st_h2c_nsa_mon::post_registerNewActiveTrans (T_TRANS new_trans, string call_info="unspeicifed");
	T_TRANS found_trans;
	
	found_trans = this.gathering_trkr.chkAndUpdate(new_trans);
	if(new_trans.desc.len == 0)
		new_trans.setTransStatusType(DMA_DESC_HAS_DROP_FAULT);
	else if( (found_trans != null) ) begin
		found_trans.setTransStatusType(DMA_DESC_HAS_DROP_FAULT);
	end
endfunction:post_registerNewActiveTrans


function vdma_st_h2c_nsa_mon::Q_TRANS vdma_st_h2c_nsa_mon::findTrans_gathering(DmaId_t dma_id, string call_info);
	Q_TRANS q_found_trans;

	string assembled_call_info;
	assembled_call_info = $sformatf("%s H2C_PKT_GATHERING dma_id=%1d", call_info, dma_id);

	foreach(this.q_active[i])begin
		this.debug($sformatf("findTrans(call_info=[%s]) this.q_active[%1d]=[%s]", assembled_call_info, i, this.q_active[i].getInfo));

    	if(this.q_active[i].getTransStatusType() == DMA_ON_DATA_PHASE && DutParamDmaId_t'(this.q_active[i].getDmaId()) == DutParamDmaId_t'(dma_id))begin
      		q_found_trans.push_back(this.q_active[i]);
    	end
	end
	
	return(q_found_trans);
	
endfunction:findTrans_gathering



function void vdma_st_h2c_nsa_mon::updateH2CNumData(T_TRANS found_trans);
	foreach(this.gathering_trkr.q_active_pkt[i]) begin
		if( DutParamDmaId_t'(this.gathering_trkr.q_active_pkt[i].pkt_dma_id) == DutParamDmaId_t'(found_trans.getDmaId()) ) begin
			this.gathering_trkr.q_active_pkt[i].cur_in_data++;
      this.debug(
        $sformatf("PKT(dma_id=%1d) accumulated data = %1dB / %1dB",
          DutParamDmaId_t'(this.gathering_trkr.q_active_pkt[i].pkt_dma_id), this.gathering_trkr.q_active_pkt[i].cur_in_data, this.gathering_trkr.q_active_pkt[i].num_planned_data)
        );
		end
	end
endfunction:updateH2CNumData


function void vdma_st_h2c_nsa_mon::showHistory(string prompt);
  this.showReportHeader(this.mon_name, prompt);
  this.info($sformatf("   - Number of transactions : %1d", this.num_trans));
  this.info($sformatf("   - Number of status       : %1d", this.num_status));
  this.info($sformatf("   - Number of interrupt    : %1d", this.num_interrupt));
  this.info($sformatf("   - Number of data         : %1d", this.num_data));
  this.info($sformatf("   - h2c_count_resp : %1d, h2c_count_func : %1d", this.h2c_count_resp, this.h2c_count_func));
  this.showReportBar(prompt);
endfunction : showHistory


`endif // __VDMA_ST_H2C_NSA_MON_SVH__
