`ifndef __VDMA_MM_H2C_SA_MON_SVH__
`define __VDMA_MM_H2C_SA_MON_SVH__



class vdma_mm_h2c_sa_mon extends vdma_sa_mm_mon;

  typedef struct packed{
    DutParamCardAddr_t                              awaddr;
    logic[pdma_dut_pkg::AXI_USER_WIDTH-1:0]         awuser;
    logic[pdma_dut_pkg::AXI_BURST_LENGTH_WIDTH-1:0] awlen;
  }CaxiAw_t;
  
  typedef struct packed{
    DmaId_t    dma_id;
    CStrb_t    wstrb;
  }CaxiExpectedWstrbWithDesc_t;
  
  typedef struct packed{
    Desc_t    desc;
    YesOrNo_t isSplittedOn4k;
  }SplittedDesc_t;
  
  typedef struct packed{
    DmaId_t    dma_id;
    logic[1:0] bresp;
  }DescWithBresp_t;
  
  local vdma_caxi_wr_mon caxi_wr_mon;
  uvm_analysis_port#(vdma_card_axi_seq_item) ap_wr;

  local virtual ddma_mm_h2c_if vif;
  local virtual svt_axi_master_if  c_vif;
  
  local vdma_card_axi_seq_item          q_caxi_seq_item[$];
  local CaxiExpectedWstrbWithDesc_t     q_expected_wstrb[$];
  local CaxiAw_t                        q_aw[$];
  local CaxiData_t                      q_wdata[$];
  local DmaId_t                         q_existed_aw[$];
  
  SplittedDesc_t   q_splitted_desc[$];
  SplittedDesc_t   q_splitted_desc_for_chk[$];
  DutParamDmaId_t  q_splitted_dma_id_for_chk[$];
  logic[1:0]       q_bresp_to_or[$];//, q_bresp_from_fault[$], q_bresp_from_data[$];
  DescWithBresp_t  q_bresp_from_fault[$], q_bresp_from_data[$];
  
  YesOrNo_t start_seq = NO;
  DmaId_t   before_dma_id;

  `uvm_component_utils(vdma_mm_h2c_sa_mon)

  function new(string name="vdma_mm_h2c_sa_mon", uvm_component parent=null);
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
  extern virtual function bit  observedNewDesc();
  extern virtual function bit  observedNewAW();
  extern virtual function bit  observedNewB();
  extern virtual function bit  observedNewData();
  extern virtual function bit  observedNewStatus();
  extern virtual function bit  observedNewInterrupt();
  extern virtual function bit  observedNewFault();
  
  extern virtual function Desc_t                                  extractNewDesc();
  extern virtual function Data_t                                  extractNewData();
  extern virtual function CaxiData_t                              extractNewCaxiData();
  extern virtual function Status_t                                extractNewStatus();
  extern virtual function Interrupt_t                             extractNewInterrupt();
  extern virtual function Fault_t                                 extractNewFault();
  extern virtual function logic[CARD_ADDR_WIDTH-1:0]              extractNewAW();
  extern virtual function logic[AXI_BURST_LENGTH_WIDTH-1:0]       extractNewAwlen();
  extern virtual function logic[pdma_dut_pkg::AXI_USER_WIDTH-1:0] extractNewAwuser();
  extern virtual function AxiRespType_t                           extractNewB();
  extern virtual function logic                                   extractNewWlast();
  extern virtual function logic[CARD_DATA_BYTE_WIDTH-1:0]         extractNewWstrb();

  extern local function YesOrNo_t chk_ExistedAW(CaxiAw_t aw);
  extern virtual function void assignSimStartFlag();
  extern function vdma_caxi_wr_mon getCaxiWrMon();
endclass:vdma_mm_h2c_sa_mon


function vdma_pkg::vdma_caxi_wr_mon vdma_mm_h2c_sa_mon::getCaxiWrMon(); return(this.caxi_wr_mon); endfunction : getCaxiWrMon

function void vdma_mm_h2c_sa_mon::init_core(string call_info="unknown");
endfunction:init_core


function void vdma_mm_h2c_sa_mon::build_phase(uvm_phase phase);
  super.build_phase(phase);

  this.caxi_wr_mon = VDMA_FACTORY.createCaxiWrMon(this, "caxi_wr_mon", this.tcfg);
  this.ap_wr = new("ap_wr", this);
endfunction : build_phase


function YesOrNo_t vdma_mm_h2c_sa_mon::resetMon();
  YesOrNo_t super_reset_completed;
  
  super_reset_completed = super.resetMon();
  if((super_reset_completed == YES) )
    return(YES);
  
  return(NO);
endfunction:resetMon




function YesOrNo_t vdma_mm_h2c_sa_mon::hasBwdChannel();
  return(YES);
endfunction:hasBwdChannel


function void vdma_mm_h2c_sa_mon::connectVif();
  `vmg_get_cfgdb_at_me(virtual ddma_mm_h2c_if, "vif", this.vif)
  `vmg_get_cfgdb_at_me(virtual svt_axi_master_if, "card_axi", this.c_vif)
endfunction:connectVif


function YesOrNo_t vdma_mm_h2c_sa_mon::isBusy();
  if(this.flag_h2c_start_simulation == NO) return(YES);
  return(this.hasActiveTrans);
endfunction:isBusy


function void vdma_mm_h2c_sa_mon::collectData();
  CaxiExpectedWstrbWithDesc_t     expected_wstrb_with_desc;
  T_TRANS                         found_trans, found_trans_for_getDesc;
  CaxiAw_t                        collected_aw, serving_aw;
  CaxiData_t                      collected_wdata;
  CStrbQ_t                        q_total_wstrb;
  
  if(this.caxi_wr_mon.q_CollectedWrTrans.size > 0) begin
    foreach(this.caxi_wr_mon.q_CollectedWrTrans[i]) begin
      vdma_card_axi_seq_item served;
      SplittedDesc_t         splitted_desc;
      
      served = this.caxi_wr_mon.q_CollectedWrTrans.pop_front();
      ap_wr.write(served);
    end
  end
 
  if(this.observedNewAW) begin : AW
    collected_aw.awaddr = this.extractNewAW(); 
    collected_aw.awuser = this.extractNewAwuser(); 
    collected_aw.awlen  = this.extractNewAwlen();
    
    if(this.tcfg.test_type == FAULT_TEST) begin
      T_TRANS        found_fault_desc;
      Desc_t         found_desc;
      SplittedDesc_t splitted_desc;
      
      found_fault_desc = this.findTrans_ForGetDesc(DMA_ON_DATA_PHASE, DutParamDmaId_t'(collected_aw.awuser), "COLLECT_DATA_FOR_GET_DESC_ON_FAULT_TEST");
      
      found_desc = found_fault_desc.getDesc();
    end
    
    if(this.chk_ExistedAW(collected_aw) == NO) begin
      Desc_t found_desc;
      int    q_total_wstrb_size = 0;
      
      found_trans_for_getDesc = this.findTrans_ForGetDesc(DMA_ON_DATA_PHASE, DutParamDmaId_t'(collected_aw.awuser), "COLLECT_DATA_FOR_GET_DESC");
      
      found_desc = found_trans_for_getDesc.getDesc();
      
      q_total_wstrb = this.cal_ExpectedCardStrb(found_desc);
      q_total_wstrb_size = q_total_wstrb.size();
      
      for(int i = 0; i < q_total_wstrb_size; i++) begin
        expected_wstrb_with_desc.dma_id = found_desc.dma_id;
        expected_wstrb_with_desc.wstrb  = q_total_wstrb.pop_front();
        this.q_expected_wstrb.push_back(expected_wstrb_with_desc); 
      end
    end
    
    this.q_aw.push_back(collected_aw);
  end
  
  if(this.observedNewData) begin : W
    collected_wdata = this.extractNewCaxiData();
    this.q_wdata.push_back(collected_wdata);
  
  
    if(this.extractNewWlast == 1) begin
      vdma_card_axi_seq_item created;
      
      created = vdma_card_axi_seq_item::type_id::create();
      
      created.wdata = this.q_wdata;
      this.q_caxi_seq_item.push_back(created);
      this.q_wdata.delete();
    end
  end
  
  if(this.observedNewB) begin : B
    vdma_card_axi_seq_item caxi_write_trans;
    int                      wdata_size = 0;
    
    caxi_write_trans = vdma_card_axi_seq_item::type_id::create();
    
    caxi_write_trans = this.q_caxi_seq_item.pop_front();
    serving_aw = this.q_aw.pop_front();
    
    caxi_write_trans.awaddr = serving_aw.awaddr;
    caxi_write_trans.awlen  = serving_aw.awlen;
    caxi_write_trans.awuser = serving_aw.awuser;
    
    wdata_size = caxi_write_trans.wdata.size();
    
    for(int i = 0; i < wdata_size; i++) begin
      caxi_write_trans.wstrb.push_back(this.q_expected_wstrb.pop_front);
    end
      
    found_trans = this.findTrans_MustSuccess(DMA_ON_DATA_PHASE, DutParamDmaId_t'(caxi_write_trans.awuser), "COLLECT_DATA");
   
    found_trans.pushCaxiData(caxi_write_trans.wdata, caxi_write_trans.wstrb);
  end
endfunction : collectData



function DmaTransType_t vdma_mm_h2c_sa_mon::getTransType();
  return(MM_H2C);
endfunction:getTransType


function bit vdma_mm_h2c_sa_mon::observedNewDesc();
  return(this.vif.IsDescHS());
endfunction:observedNewDesc


function Desc_t vdma_mm_h2c_sa_mon::extractNewDesc();
  return(this.vif.GetDesc());
endfunction:extractNewDesc


function bit vdma_mm_h2c_sa_mon::observedNewAW();
  return(c_vif.awvalid & c_vif.awready);
endfunction:observedNewAW


function logic[CARD_ADDR_WIDTH-1:0] vdma_mm_h2c_sa_mon::extractNewAW();
  return(c_vif.awaddr);
endfunction:extractNewAW


function logic[pdma_dut_pkg::AXI_USER_WIDTH-1:0] vdma_mm_h2c_sa_mon::extractNewAwuser();
  return(c_vif.awuser);
endfunction:extractNewAwuser


function logic[AXI_BURST_LENGTH_WIDTH-1:0] vdma_mm_h2c_sa_mon::extractNewAwlen();
  return(c_vif.awlen);
endfunction:extractNewAwlen



function logic vdma_mm_h2c_sa_mon::extractNewWlast();
  return(c_vif.wlast);
endfunction:extractNewWlast



function logic[CARD_DATA_BYTE_WIDTH-1:0] vdma_mm_h2c_sa_mon::extractNewWstrb();
  return(c_vif.wstrb);
endfunction:extractNewWstrb



function bit vdma_mm_h2c_sa_mon::observedNewB();
  return(c_vif.bvalid & c_vif.bready);
endfunction:observedNewB



function AxiRespType_t vdma_mm_h2c_sa_mon::extractNewB();
  return(c_vif.bresp);
endfunction:extractNewB




function bit vdma_mm_h2c_sa_mon::observedNewData();
  return(c_vif.wvalid & c_vif.wready);
endfunction:observedNewData



function CaxiData_t vdma_mm_h2c_sa_mon::extractNewCaxiData();
  return(c_vif.wdata);
endfunction:extractNewCaxiData


function Data_t vdma_mm_h2c_sa_mon::extractNewData(); endfunction:extractNewData



function bit vdma_mm_h2c_sa_mon::observedNewStatus();
  return(this.vif.IsStatusHS());
endfunction:observedNewStatus


function Status_t vdma_mm_h2c_sa_mon::extractNewStatus();
  return(this.vif.GetStatus());
endfunction:extractNewStatus



function bit vdma_mm_h2c_sa_mon::observedNewInterrupt();
  return(this.vif.IsInterruptHS());
endfunction:observedNewInterrupt


function Interrupt_t vdma_mm_h2c_sa_mon::extractNewInterrupt();
  return(this.vif.GetInterrupt());
endfunction:extractNewInterrupt


function bit vdma_mm_h2c_sa_mon::observedNewFault();
  return(this.vif.IsFaultHS());
endfunction:observedNewFault


function Fault_t vdma_mm_h2c_sa_mon::extractNewFault();
  return(this.vif.GetFault());
endfunction:extractNewFault


function pmg_pkg::YesOrNo_t vdma_mm_h2c_sa_mon::chk_ExistedAW(CaxiAw_t aw);
  int       delete_idx = 0;
  YesOrNo_t existedAw  = YES;
  YesOrNo_t firstAw    = NO;
  
  delete_idx = this.q_existed_aw.size - 1;
  
  if(this.q_aw.size == 0 && this.q_existed_aw.size == 0) begin
    this.debug($sformatf("[Check AW] 1.This is the first extracted AW, dma_id=%1d", aw.awuser));
    existedAw = NO;
    firstAw   = YES;
  end
  else existedAw = YES;
  
  foreach(this.q_existed_aw[i]) begin
    if(this.q_existed_aw[i] != aw.awuser) begin
      this.debug($sformatf("[Check AW] 2.This is the first extracted AW, dma_id=%1d", aw.awuser));
      existedAw = NO;
    end
    else existedAw = YES;
  end
  
  if(firstAw == NO && existedAw == NO) begin
    for(int i = delete_idx; i > (-1); i--) begin
      this.debug($sformatf("[Check AW] Remove idx=%1d of q_existed_aw, dma_id=%1d", i, this.q_existed_aw[i]));
      this.q_existed_aw.delete(i);
    end
  end
  
  this.q_existed_aw.push_back(aw.awuser);
  
  return(existedAw);
endfunction : chk_ExistedAW


function void vdma_mm_h2c_sa_mon::post_registerNewActiveTrans (T_TRANS new_trans, string call_info="unspeicifed");
  if(new_trans.desc.len == 0) new_trans.setTransStatusType(DMA_DESC_HAS_DROP_FAULT);
endfunction:post_registerNewActiveTrans


function void vdma_mm_h2c_sa_mon::assignSimStartFlag();
  this.flag_h2c_start_simulation = YES;
endfunction : assignSimStartFlag




`endif // __VDMA_MM_H2C_SA_MON_SVH__
