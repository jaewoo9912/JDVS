`ifndef __VDMA_MM_C2H_SA_MON_SVH__
`define __VDMA_MM_C2H_SA_MON_SVH__



class vdma_mm_c2h_sa_mon extends vdma_sa_mm_mon;
  
  typedef struct packed{
    DutParamCardAddr_t                              araddr;
    logic[pdma_dut_pkg::AXI_USER_WIDTH-1:0]         aruser;
    logic[pdma_dut_pkg::AXI_BURST_LENGTH_WIDTH-1:0] arlen;
  }CaxiAr_t;
  
  typedef struct packed{
    DmaId_t   dma_id;
    CStrb_t   rstrb;
  }CaxiExpectedRstrbWithDesc_t;
  
  local vdma_caxi_rd_mon caxi_rd_mon;
  uvm_analysis_port#(vdma_card_axi_seq_item) ap_rd;

  local virtual ddma_mm_c2h_if vif;
  local virtual svt_axi_master_if  c_vif;

  local CaxiExpectedRstrbWithDesc_t     q_expected_rstrb[$];
  local CaxiAr_t                        q_ar[$];
  local CaxiData_t                      q_rdata[$];
  local DmaId_t                         q_existed_ar[$];
  
  `uvm_component_utils(vdma_mm_c2h_sa_mon)

  function new(string name="vdma_mm_c2h_sa_mon", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connectVif();
  extern virtual function YesOrNo_t hasBwdChannel();
  extern virtual function void init_core(string call_info="unknown");
  extern virtual function YesOrNo_t isBusy();

  extern virtual protected function void post_registerNewActiveTrans (T_TRANS new_trans, string call_info="unspeicifed");
  extern virtual function YesOrNo_t resetMon();
  // ---------------------------------------
  extern virtual function void collectData();
  
  extern virtual function DmaTransType_t getTransType();
  extern virtual function bit observedNewDesc();
  extern virtual function bit observedNewData();
  extern virtual function bit observedNewAR();
  extern virtual function bit observedNewStatus();
  extern virtual function bit observedNewInterrupt();
  extern virtual function bit observedNewFault();
  
  extern virtual function Desc_t                                  extractNewDesc();
  extern virtual function Data_t                                  extractNewData();
  extern virtual function CaxiData_t                              extractNewCaxiData();
  extern virtual function Status_t                                extractNewStatus();
  extern virtual function Interrupt_t                             extractNewInterrupt();
  extern virtual function Fault_t                                 extractNewFault();
  extern virtual function logic[CARD_ADDR_WIDTH-1:0]              extractNewAR();
  extern virtual function logic[AXI_BURST_LENGTH_WIDTH-1:0]       extractNewArlen();
  extern virtual function logic[pdma_dut_pkg::AXI_USER_WIDTH-1:0] extractNewAruser();
  extern virtual function AxiRespType_t                           extractNewR();
  extern virtual function logic                                   extractNewRlast();

  
  extern local function YesOrNo_t chk_ExistedAR(CaxiAr_t ar);
  extern function vdma_caxi_rd_mon getCaxiRdMon();

  extern virtual function void assignSimStartFlag();
endclass:vdma_mm_c2h_sa_mon


function vdma_caxi_rd_mon vdma_mm_c2h_sa_mon::getCaxiRdMon(); return(this.caxi_rd_mon); endfunction

function void vdma_mm_c2h_sa_mon::init_core(string call_info="unknown"); endfunction:init_core


function void vdma_mm_c2h_sa_mon::build_phase(uvm_phase phase);
  super.build_phase(phase);

  this.caxi_rd_mon = VDMA_FACTORY.createCaxiRdMon(this, "caxi_rd_mon", this.tcfg);
  this.ap_rd = new("ap_rd", this);
endfunction : build_phase



function YesOrNo_t vdma_mm_c2h_sa_mon::resetMon();
  YesOrNo_t super_reset_completed;
  
  super_reset_completed = super.resetMon();
  if(super_reset_completed == YES) return(YES);
  
  return(NO);
endfunction:resetMon



function YesOrNo_t vdma_mm_c2h_sa_mon::hasBwdChannel();
  return(YES);
endfunction:hasBwdChannel


function void vdma_mm_c2h_sa_mon::connectVif();
  `vmg_get_cfgdb_at_me(virtual ddma_mm_c2h_if, "vif", this.vif)
  `vmg_get_cfgdb_at_me(virtual svt_axi_master_if, "card_axi", this.c_vif)
endfunction:connectVif


function YesOrNo_t vdma_mm_c2h_sa_mon::isBusy();
  if(this.flag_c2h_start_simulation == NO) return(YES);
  return(this.hasActiveTrans);
endfunction:isBusy



function void vdma_mm_c2h_sa_mon::collectData();
  CaxiExpectedRstrbWithDesc_t expected_rstrb_with_desc;
  T_TRANS                     found_trans, found_trans_for_getDesc;
  CaxiAr_t                    collected_ar, serving_ar;
  CaxiData_t                  collected_rdata;
  CStrbQ_t                    q_total_rstrb;
  int                         q_total_rstrb_size = 0;

  if(this.caxi_rd_mon.q_CollectedRdTrans.size > 0) begin
    foreach(this.caxi_rd_mon.q_CollectedRdTrans[i]) begin
      vdma_card_axi_seq_item served;
      
      served = this.caxi_rd_mon.q_CollectedRdTrans.pop_front();
      
      ap_rd.write(served);
    end
  end

  if(this.observedNewAR) begin : AR
    collected_ar.araddr = this.extractNewAR();
    collected_ar.arlen  = this.extractNewArlen();
    collected_ar.aruser = this.extractNewAruser();
    
    if(this.chk_ExistedAR(collected_ar) == NO) begin
      Desc_t found_desc;

      found_trans_for_getDesc = this.findTrans_ForGetDesc(DMA_ON_DATA_PHASE, DutParamDmaId_t'(collected_ar.aruser), "COLLECT_DATA_FOR_GET_DESC");
      
      found_desc = found_trans_for_getDesc.getDesc();
      
      q_total_rstrb      = this.cal_ExpectedCardStrb(found_desc);
      q_total_rstrb_size = q_total_rstrb.size();
      
      found_trans_for_getDesc.total_strb_size = q_total_rstrb_size;
      
      for(int i = 0; i < q_total_rstrb_size; i++) begin
        expected_rstrb_with_desc.dma_id = found_desc.dma_id;
        expected_rstrb_with_desc.rstrb  = q_total_rstrb.pop_front();
        this.q_expected_rstrb.push_back(expected_rstrb_with_desc);
      end
    end//chk_ExistedAR
    
    for(int i = 0; i < q_total_rstrb_size; i++) begin
      this.q_ar.push_back(collected_ar);
    end
    
  end// AR
  
  if(this.observedNewData) begin : R
    vdma_card_axi_seq_item created, caxi_read_trans;
    int                      rdata_size = 0;
    
    collected_rdata = this.extractNewCaxiData();
    this.q_rdata.push_back(collected_rdata);
   
    created = vdma_card_axi_seq_item::type_id::create();
    
    serving_ar = this.q_ar.pop_front();
    created.aruser = serving_ar.aruser;
    
    found_trans = this.findTrans_ForGetDesc(DMA_ON_DATA_PHASE, DutParamDmaId_t'(created.aruser), "COLLECT_DATA");
    
    found_trans.total_strb_size--;
    if(found_trans.total_strb_size == 0) begin
      caxi_read_trans = vdma_card_axi_seq_item::type_id::create();
      
      caxi_read_trans.araddr = serving_ar.araddr;
      caxi_read_trans.arlen  = serving_ar.arlen;
      caxi_read_trans.aruser = serving_ar.aruser;
      
      rdata_size = this.q_rdata.size();
      
      caxi_read_trans.rdata = this.q_rdata;
      this.q_rdata.delete();
      
      for(int i = 0; i < rdata_size; i++) begin
        caxi_read_trans.wstrb.push_back(this.q_expected_rstrb.pop_front);
      end
      
      found_trans = this.findTrans_MustSuccess(DMA_ON_DATA_PHASE, DutParamDmaId_t'(caxi_read_trans.aruser), "COLLECT_DATA");
      
      found_trans.pushCaxiData(caxi_read_trans.rdata, caxi_read_trans.wstrb);
      
    end
  end // R
endfunction : collectData




function DmaTransType_t vdma_mm_c2h_sa_mon::getTransType();
  return(MM_C2H);
endfunction:getTransType


function bit vdma_mm_c2h_sa_mon::observedNewDesc();
  return(this.vif.IsDescHS());
endfunction:observedNewDesc


function Desc_t vdma_mm_c2h_sa_mon::extractNewDesc();
  return(this.vif.GetDesc());
endfunction:extractNewDesc



function bit vdma_mm_c2h_sa_mon::observedNewData();
  return(c_vif.rvalid & c_vif.rready);
endfunction:observedNewData


function Data_t vdma_mm_c2h_sa_mon::extractNewData(); endfunction:extractNewData



function CaxiData_t vdma_mm_c2h_sa_mon::extractNewCaxiData();
  return(c_vif.rdata);
endfunction:extractNewCaxiData


function bit vdma_mm_c2h_sa_mon::observedNewAR();
  return(c_vif.arvalid & c_vif.arready);  
endfunction : observedNewAR


function logic[CARD_ADDR_WIDTH-1:0] vdma_mm_c2h_sa_mon::extractNewAR();
  return(c_vif.araddr);  
endfunction : extractNewAR


function logic[pdma_dut_pkg::AXI_USER_WIDTH-1:0] vdma_mm_c2h_sa_mon::extractNewAruser();
  return(c_vif.aruser);  
endfunction : extractNewAruser


function logic[AXI_BURST_LENGTH_WIDTH-1:0] vdma_mm_c2h_sa_mon::extractNewArlen();
  return(c_vif.arlen);  
endfunction : extractNewArlen


function logic vdma_mm_c2h_sa_mon::extractNewRlast();
  return(c_vif.rlast);  
endfunction : extractNewRlast


function AxiRespType_t vdma_mm_c2h_sa_mon::extractNewR();
  return(c_vif.rresp);
endfunction


function bit vdma_mm_c2h_sa_mon::observedNewStatus();
  return(this.vif.IsStatusHS());
endfunction:observedNewStatus


function Status_t vdma_mm_c2h_sa_mon::extractNewStatus();
  return(this.vif.GetStatus());
endfunction:extractNewStatus



function bit vdma_mm_c2h_sa_mon::observedNewInterrupt();
  return(this.vif.IsInterruptHS());
endfunction:observedNewInterrupt


function Interrupt_t vdma_mm_c2h_sa_mon::extractNewInterrupt();
  return(this.vif.GetInterrupt());
endfunction:extractNewInterrupt


function bit vdma_mm_c2h_sa_mon::observedNewFault();
  return(this.vif.IsFaultHS());
endfunction:observedNewFault


function Fault_t vdma_mm_c2h_sa_mon::extractNewFault();
  return(this.vif.GetFault());
endfunction:extractNewFault



function pmg_pkg::YesOrNo_t vdma_mm_c2h_sa_mon::chk_ExistedAR(CaxiAr_t ar);
  int       delete_idx = 0;
  YesOrNo_t existedAr  = YES;
  YesOrNo_t firstAr    = NO;
  
  delete_idx = this.q_existed_ar.size - 1;
  
  if(this.q_ar.size == 0 && this.q_existed_ar.size == 0) begin
    this.debug($sformatf("[Check AR] 1.This is the first extracted AR, dma_id=%1d", ar.aruser));
    existedAr = NO;
    firstAr   = YES;
  end
  else existedAr = YES;
  
  foreach(this.q_existed_ar[i]) begin
    if(this.q_existed_ar[i] != ar.aruser) begin
      this.debug($sformatf("[Check AR] 2.This is the first extracted AR, dma_id=%1d", ar.aruser));
      existedAr = NO;
    end
    else existedAr = YES;
  end
  
  if(firstAr == NO && existedAr == NO) begin
    for(int i = delete_idx; i > (-1); i--) begin
      this.debug($sformatf("[Check AR] Remove idx=%1d of q_existed_ar, dma_id=%1d", i, this.q_existed_ar[i]));
      this.q_existed_ar.delete(i);
    end
  end
  
  this.q_existed_ar.push_back(ar.aruser);
  
  return(existedAr);
endfunction : chk_ExistedAR




function void vdma_mm_c2h_sa_mon::post_registerNewActiveTrans (T_TRANS new_trans, string call_info="unspeicifed");
	if(new_trans.desc.len == 0) new_trans.setTransStatusType(DMA_DESC_HAS_DROP_FAULT);
endfunction:post_registerNewActiveTrans



function void vdma_mm_c2h_sa_mon::assignSimStartFlag(); 
  this.flag_c2h_start_simulation = YES;
endfunction : assignSimStartFlag




`endif // __VDMA_MM_C2H_SA_MON_SVH__
