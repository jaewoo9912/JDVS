`ifndef __VDMA_SEQ_ITEM_SVH__
`define __VDMA_SEQ_ITEM_SVH__



/*

  [IMPORTANT_NOTICE]
    ** 2 modes
      - As a master sequence item
         Randomization 
      - As a transaction being monitored 
         Set method used, status updated accordingly

   ** sop/eop
       > It's in randomized "desc" structure, but not randomized and external entities control it (see post_randomize)

  TODO
    - Implement detail-getInfo
    - Upgrade w/ "rand"

    - Enhancement w/ considering fault 
       ==> Search w/ "COMPLETED_WO_CONSIDERING_FAULT"


*/


class vdma_seq_item extends vmg_seq_item;

  local static DmaId_t  num_created    = 0;
  local static int      count_created  = 0;

  local DmaTransType_t trans_type = UNDEFINED_DmaTransType_t;
  local DmaTransStatus_t trans_status = DMA_INVALID;
  
  // Randomization knobs
  DmaId_t			    cstr_dma_id;
  DmaTransType_t	cstr_trans_type;
  Len_t				    cstr_dma_len;
  AxiMaxLen_t		  cstr_axi_max_len;
  AxiMaxLen_t 		cstr_axi_min_len;
  Addr_t			    cstr_src_addr;
  Addr_t			    cstr_dst_addr;
  StrId_t 			  cstr_str_id;
  FncId_t			    cstr_fnc_id;

  // Sequence item related
        rand Desc_t       desc;
             Data_t       q_data[$]; // <--------------- This is randomized at "post_randomize"
             CaxiDataQ_t  q_caxi_data[$];
             CStrbQ_t     q_caxi_strb[$];
  local rand Status_t     status;
  local rand Interrupt_t  interrupt;
  local rand Fault_t      fault;

  local YesOrNo_t has_status = NO;
  local YesOrNo_t has_interrupt = NO;
  local YesOrNo_t has_fault = NO;
  
  local YesOrNo_t has_host_b_wrong_resp_fault = NO;

  TestType_t test_type;

        rand DmaId_t dma_id;

  local int data_size = INVALID_INT_VALUE;
  local int num_planned_data;
  
  int caxi_strb_cnt   = 0;
  int total_strb_size = 0;

  local DmaTransPktGatheringStatusType_t pkt_gathering_info = UNDEFINED_PKT_GATHERING_STATUS;
  
  
  //==============================================================
  // Fault
  //==============================================================
  typedef struct {
    int num_fault_code0 = 0;
    int num_fault_code1 = 0;
    int num_fault_code2 = 0;
    int num_fault_code3 = 0;
    int num_fault_code4 = 0;
    int num_fault_code13 = 0;
    int num_fault_code5 = 0;
    int num_fault_code6 = 0;
    int num_fault_code7 = 0;
    int num_fault_code14 = 0;
    int num_fault_code8 = 0;
    int num_fault_code12 = 0;
  }DmaSeqItemFaultCount_t;
  DmaSeqItemFaultCount_t fault_count;

  
  OccuIntendedFault_t intended_faultType = -1;
  
  int completed_flag = 0;
  int completed_count = 0;

  `uvm_object_utils_begin(vdma_seq_item)
    `uvm_field_enum     (DmaTransStatus_t,                trans_status,       UVM_ALL_ON)
    `uvm_field_enum     (DmaTransType_t,                  trans_type,         UVM_ALL_ON)
    `uvm_field_int      (                                 desc,               UVM_ALL_ON)
    `uvm_field_queue_int(                                 q_data,             UVM_ALL_ON)
    `uvm_field_int      (                                 status,             UVM_ALL_ON)
    `uvm_field_int      (                                 interrupt,          UVM_ALL_ON)
    `uvm_field_int      (                                 fault,              UVM_ALL_ON)
    `uvm_field_enum     (YesOrNo_t,                       has_status,         UVM_ALL_ON)
    `uvm_field_enum     (YesOrNo_t,                       has_interrupt,      UVM_ALL_ON)
    `uvm_field_enum     (YesOrNo_t,                       has_fault,          UVM_ALL_ON)
    `uvm_field_int      (                                 dma_id,             UVM_ALL_ON)
    `uvm_field_int      (                                 data_size,          UVM_ALL_ON | UVM_DEC)
    `uvm_field_int      (                                 num_planned_data,   UVM_ALL_ON | UVM_DEC)
    `uvm_field_enum     (DmaTransPktGatheringStatusType_t,pkt_gathering_info, UVM_ALL_ON)
  `uvm_object_utils_end



  constraint CSTR_LEN{
    desc.len == cstr_dma_len;
  }

  constraint CSTR_DMA_ID{
    dma_id           == cstr_dma_id;
    desc     .dma_id == cstr_dma_id;
    status   .dma_id == cstr_dma_id;
    fault    .dma_id == cstr_dma_id;
    interrupt.dma_id == cstr_dma_id;
  }
  
  constraint CSTR_VEC_ID{
    desc.vec_id < 'h1f;
  }
  constraint CSTR_MAX_BURST_LEN{
    desc.axi_max_len == cstr_axi_max_len;
  }
  constraint CSTR_SRC_ADDR{
    desc.src_addr == cstr_src_addr;
  }
  constraint CSTR_DST_ADDR{
    desc.dst_addr == cstr_dst_addr;
  }
  constraint CSTR_AXUSER{
    desc.fnc_id == cstr_fnc_id;
    desc.str_id == cstr_str_id;
  }
 

  function new (string name="vdma_seq_item");
    super.new(name);
    
    if(this.count_created == 0) begin
      this.num_created = DutParamDmaId_t'($urandom());
      this.count_created = 1;
    end
    
    this.setID(this.num_created++);
  endfunction


  // ------------------------- vmg_if_default_behavior
  extern virtual function string getInfo();


  // -------------------------- vdma_seq_item-api
  extern virtual function YesOrNo_t isCompleted();
  extern virtual function YesOrNo_t isCardDataCompleted();

  extern function DmaTransType_t getTransType(); 
  extern function DmaTransStatus_t getTransStatusType(); 
  extern function void setTransStatusType(DmaTransStatus_t trans_status_info);

  extern function int getNumPlannedData();
  extern function int getDataSize();

  extern function void setDesc(DmaTransType_t trans_type, Desc_t me, int data_size);
  extern function void setDataSize(int data_size);
  extern function void pushData(Data_t me);
  extern function void pushCaxiData(CaxiDataQ_t me, CStrbQ_t strb);
  extern function Data_t popData(string call_info="unspecified");
  extern function CaxiDataQ_t popCaxiData(string call_info="unspecified");
  extern function void setStatus(Status_t me);
  extern function void setInterrupt(Interrupt_t me);
  extern function void setFault(Fault_t me);
  extern function void setFaultInterrupt(Interrupt_t me);

  extern function void makeSoloPkt();
  extern function void makeStartOfPacketGathering();
  extern function void makeIntermediateOfPacketGathering();
  extern function void makeEndOfPacketGathering();
  
  extern function void makeIntrReq();
  extern function void makeIntrNoReq();
  extern function void makeStatReq();
  extern function void makeStatNoReq();
  extern function void makeDataValue(DataValue_t data_value);
  extern function void makeRandDataValue();
  
  // TODO:Move to h2c specific objects
  // H2C PKT gathering
  extern function void setPktGatheringInfo(DmaTransPktGatheringStatusType_t pkt_gathering_info);
  extern function DmaTransPktGatheringStatusType_t getPktGatheringInfo();
  extern function void completeEndPkt();
  extern local function void computePktType();

  extern function YesOrNo_t hasStatus();
  extern function YesOrNo_t hasInterrupt();
  extern function YesOrNo_t hasData();
  extern function YesOrNo_t hasFault();

  extern function int getNumData();

  extern function YesOrNo_t needStatus();
  extern function YesOrNo_t needInterrupt();

  extern function Desc_t getDesc();
  extern function Status_t getStatus();
  extern function Interrupt_t getInterrupt();
  extern function Fault_t getFault();

  extern function void    setDmaId(DmaId_t new_id);
  extern function DmaId_t getDmaId();

  extern function void post_randomize();

  extern local function void computeNumPlannedData();



  // -------------------------- internal-impl
  
  

endclass:vdma_seq_item


typedef vdma_seq_item vdma_seq_item_queue[$];


function void vdma_seq_item::makeStartOfPacketGathering();
  this.desc.sop = 1;
  this.desc.eop = 0;
  this.pkt_gathering_info = START_OF_PKT_GATHERING;
  
  this.desc.req_intr = 0;
  this.desc.req_stat = 0;
endfunction:makeStartOfPacketGathering


function void vdma_seq_item::makeIntermediateOfPacketGathering();
  this.desc.sop = 0;
  this.desc.eop = 0;
  this.pkt_gathering_info = INTERMEDIATE_PKT_GATHERING;
  
  this.desc.req_stat = 0;
  this.desc.req_intr = 0;
endfunction:makeIntermediateOfPacketGathering


function void vdma_seq_item::makeEndOfPacketGathering();
  this.desc.sop = 0;
  this.desc.eop = 1;
  this.pkt_gathering_info = END_OF_PKT_GATHERING;
endfunction:makeEndOfPacketGathering





function void vdma_seq_item::makeSoloPkt();
  this.desc.sop = 1;
  this.desc.eop = 1;
  this.pkt_gathering_info = NOT_ON_PKT_GATHERING;
endfunction:makeSoloPkt

function void vdma_seq_item::makeIntrReq();
  this.desc.req_intr = 1;
endfunction:makeIntrReq


function void vdma_seq_item::makeIntrNoReq();
  this.desc.req_intr = 0;
endfunction:makeIntrNoReq


function void vdma_seq_item::makeStatReq();
  this.desc.req_stat = 1;
endfunction:makeStatReq


function void vdma_seq_item::makeStatNoReq();
  this.desc.req_stat = 0;
endfunction:makeStatNoReq


function void vdma_seq_item::makeDataValue(DataValue_t data_value);
  foreach(this.q_data[i]) begin
    this.q_data[i].value = data_value;
  end
endfunction:makeDataValue


function void vdma_seq_item::makeRandDataValue();
  foreach(this.q_data[i]) begin
    this.q_data[i].value = {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom()};
  end
endfunction




function void vdma_seq_item::computeNumPlannedData();
  if(this.test_type != FAULT_TEST)begin
    if(this.data_size == INVALID_INT_VALUE || this.desc.len == 0)begin
      this.info(this.getInfo);
      this.info($sformatf("computeNumPlannedData -- data_size=%1d desc.len=%1d", this.data_size, this.desc.len));
      this.fatal("VDMA_SEQ_ITEM_FAILED in Normal_Test", "vdma_seq_item::computeNumPlannedData -- failed");
    end
  end
  else begin
    if(this.data_size == INVALID_INT_VALUE)begin
      this.info(this.getInfo);
      this.info($sformatf("computeNumPlannedData -- data_size=%1d desc.len=%1d", this.data_size, this.desc.len));
      this.fatal("VDMA_SEQ_ITEM_FAILED in Fault_Test", "vdma_seq_item::computeNumPlannedData -- failed");
    end
  end

  this.num_planned_data = this.desc.len/this.data_size;
  if(this.desc.len%this.data_size != 0) this.num_planned_data++;
endfunction:computeNumPlannedData



function void vdma_seq_item::post_randomize();

  this.computeNumPlannedData();
  
  if(this.num_planned_data == 0) begin
    this.info("Data Length is zero in this desc !!");
  end
  else begin
    for(int i = 0 ; i < this.num_planned_data ; i++)begin
      Data_t new_data;

      new_data       = 0;
      new_data.side_info.dma_id = DutParamDmaId_t'(this.dma_id);
      if(i == num_planned_data-1)begin
        new_data.last = 1;
        new_data.side_info.mty = DutParamEmpty_t'(this.data_size - (this.desc.len%this.data_size)); //updated by jaewoo// TODO:NeedReview
      end
      
      this.q_data.push_back(new_data);
    end
  end
  
  // H2C gathering not randomized, since it's out-of-scope of the single sequence item
  // It's controlled by external objects                                              
  this.desc.sop = 1;
  this.desc.eop = 1;
  
endfunction:post_randomize




// TODO:NeedConsider --- fault condition (can get interrupt when the DMA gots fault during the operation
function YesOrNo_t vdma_seq_item::needInterrupt();
  if((this.desc.req_intr && this.has_interrupt) == NO) return(YES); //updated by jaewoo
  return(NO);
endfunction:needInterrupt


function YesOrNo_t vdma_seq_item::needStatus();
  if((this.desc.req_stat && this.has_status) == NO) return(YES);
  return(NO);
endfunction:needStatus



function YesOrNo_t vdma_seq_item::hasData();
  if(this.getNumData() != 0) return(YES);
  return(NO);
endfunction:hasData


function YesOrNo_t vdma_seq_item::hasStatus();
  return(this.has_status);
endfunction:hasStatus


function YesOrNo_t vdma_seq_item::hasInterrupt();
  return(this.has_interrupt);
endfunction:hasInterrupt


function YesOrNo_t vdma_seq_item::hasFault();
  return(this.has_fault);
endfunction:hasFault


function int vdma_seq_item::getNumData();
  return(this.q_data.size);
endfunction:getNumData



function int vdma_seq_item::getNumPlannedData();
  return(this.num_planned_data);
endfunction:getNumPlannedData

function int vdma_seq_item::getDataSize();
  return(this.data_size);
endfunction:getDataSize

function DmaId_t vdma_seq_item::getDmaId();
  return(DutParamDmaId_t'(this.dma_id));
endfunction:getDmaId


function Desc_t vdma_seq_item::getDesc();
  return(this.desc);
endfunction:getDesc

function Status_t vdma_seq_item::getStatus();
  return(this.status);
endfunction:getStatus

function Interrupt_t vdma_seq_item::getInterrupt();
  return(this.interrupt);
endfunction:getInterrupt

function Fault_t vdma_seq_item::getFault();
  return(this.fault);
endfunction:getFault


function void vdma_seq_item::setDmaId(DmaId_t new_id);
  this.cstr_dma_id      = DutParamDmaId_t'(new_id);
  this.dma_id           = DutParamDmaId_t'(new_id);
  this.desc.dma_id      = DutParamDmaId_t'(new_id);
  this.status.dma_id    = DutParamDmaId_t'(new_id);
  this.fault.dma_id     = DutParamDmaId_t'(new_id);
  this.interrupt.dma_id = DutParamDmaId_t'(new_id);
endfunction:setDmaId

function void vdma_seq_item::setDataSize(int data_size);
  this.data_size = data_size;
endfunction:setDataSize



function void vdma_seq_item::setDesc(DmaTransType_t trans_type, Desc_t me, int data_size);
  this.trans_type = trans_type;
  this.desc = me;
  this.dma_id = DutParamDmaId_t'(me.dma_id);
  this.data_size = data_size;
  this.trans_status = DMA_ON_DATA_PHASE;

  this.computePktType();
  this.computeNumPlannedData();
endfunction:setDesc


function Data_t vdma_seq_item::popData(string call_info="unspecified");
  if(this.q_data.size == 0)begin
    this.fatal("VDMA_SEQ_ITEM_POP_DATA_FAILED", $sformatf("There's nothing to pop !! call_info=[%s]", call_info));
  end

  return(this.q_data.pop_front());
endfunction:popData



function void vdma_seq_item::pushData(Data_t me);

  this.q_data.push_back(me);

  if(this.q_data.size == this.num_planned_data)begin
    if(this.desc.req_intr || this.desc.req_stat)begin
      this.trans_status = DMA_ON_RESP_PHASE;
    end
    else begin
      this.completed_flag = 1;
      this.trans_status = DMA_READY_TO_COMPLETED;
    end
    
    if(this.getTransType() == ST_C2H) begin
      this.info($sformatf("[ST_C2H] C2DMA all Data Transaction Done / %s", this.getInfo()));
    end
  end
endfunction:pushData



function CaxiDataQ_t vdma_seq_item::popCaxiData(string call_info="unspecified");
  if(this.q_caxi_data.size == 0)begin
    this.fatal("VDMA_SEQ_ITEM_POP_DATA_FAILED", $sformatf("There's nothing to pop !! call_info=[%s]", call_info));
  end

  return(this.q_caxi_data.pop_front());
endfunction:popCaxiData



function void vdma_seq_item::pushCaxiData(CaxiDataQ_t me, CStrbQ_t strb);
  CStrb_t  chk_strb;
  int      cnt_ones, strb_size, num_caxi_data;

  this.q_caxi_data.push_back(me);
 
  strb_size = strb.size();
  
  for(int i = 0; i < strb_size; i++) begin
    chk_strb = strb.pop_front();
    for(int j = 0; j < CARD_DATA_BYTE_WIDTH; j++) begin
      this.caxi_strb_cnt += chk_strb[j];
    end
  end
  
  
  if(this.caxi_strb_cnt == this.desc.len)begin
    if(this.desc.req_intr || this.desc.req_stat)begin
      this.trans_status = DMA_ON_RESP_PHASE;
    end
    else begin
      this.completed_flag = 1;
      this.trans_status = DMA_READY_TO_COMPLETED;
    end
    
  end
endfunction:pushCaxiData



function void vdma_seq_item::setStatus(Status_t me);
  this.status = me;
  this.has_status = YES;
  
  this.debug($sformatf("SET seq_item has_status / dma_id=%1d", DutParamDmaId_t'(this.desc.dma_id)));
  
  if(!this.desc.req_intr || this.has_interrupt == YES)begin
    this.completed_flag = 1;
  end
endfunction:setStatus


function void vdma_seq_item::setInterrupt(Interrupt_t me);
  this.interrupt = me;
  this.has_interrupt = YES;
  
  this.debug($sformatf("SET seq_item has_interrupt / dma_id=%1d", DutParamDmaId_t'(this.desc.dma_id)));
  if(!this.desc.req_stat || this.has_status == YES)begin
    this.completed_flag = 1;
  end
endfunction:setInterrupt


function void vdma_seq_item::setFault(Fault_t me);
  this.fault = me;
  this.has_fault = YES;
  
  me.dma_id = DutParamDmaId_t'(this.dma_id);

  this.info($sformatf("SET seq_item has_fault / dma_id=%1d / fault_code=%1d", DutParamDmaId_t'(this.desc.dma_id), me.code));
  case(me.code)
    DESC_DATA_LENGTH_IS_ZERO            : this.fault_count.num_fault_code0++;
    CARD_R_PREMATURE_LAST               : this.fault_count.num_fault_code5++;
    CARD_R_NO_LAST                      : this.fault_count.num_fault_code6++;
    CARD_R_WRONG_MTY                    : this.fault_count.num_fault_code7++;
    CARD_R_WRONG_DMA_ID                 : this.fault_count.num_fault_code14++;
    DESC_DATA_LENGTH_IS_ZERO            : this.fault_count.num_fault_code0++;
    DESC_MID_OF_PKT_BEFORE_START_OF_PKT : this.fault_count.num_fault_code1++;
    DESC_SOLO_OF_PKT_DURING_GATHERING   : this.fault_count.num_fault_code2++;
    DESC_START_OF_PKT_DURING_GATHERING  : this.fault_count.num_fault_code3++;
    DESC_END_OF_PKT_BEFORE_START_OF_PKT : this.fault_count.num_fault_code13++;
    HOST_R_WRONG_RESP                   : this.fault_count.num_fault_code8++;
    HOST_B_WRONG_RESP                   : this.fault_count.num_fault_code12++;
  endcase
endfunction:setFault


function void vdma_seq_item::setFaultInterrupt(Interrupt_t me); this.interrupt = me; endfunction

function DmaTransType_t vdma_seq_item::getTransType(); return(this.trans_type); endfunction

function DmaTransStatus_t vdma_seq_item::getTransStatusType(); return(this.trans_status); endfunction

function void vdma_seq_item::setTransStatusType(DmaTransStatus_t trans_status_info);  this.trans_status = trans_status_info; endfunction


function string vdma_seq_item::getInfo();
  string str_status, str_interrupt, str_fault, str_pkt_gathering_info;

  str_status = MakeString_Status_t(this.status);
  if(this.has_status == NO) str_status = "no_status";

  str_interrupt = MakeString_Interrupt_t(this.interrupt);
  if(this.has_interrupt == NO) str_interrupt = "no_interrupt";

  str_fault = MakeString_Fault_t(this.fault);
  if(this.has_fault == NO) str_fault = "no_fault";

  str_pkt_gathering_info = "";
  if(this.trans_type == ST_H2C) str_pkt_gathering_info = $sformatf(" %s", this.pkt_gathering_info.name);

  return(
    $sformatf("%s %s %s%s desc=[%s] num_has/planned_data=%1d/%1d status=[%s] interrupt=[%s] fault=[%s]",
      this.getNameWithID,
      this.trans_type.name,
      this.trans_status.name,
      str_pkt_gathering_info,
      MakeString_Desc_t(this.trans_type, this.desc),
      this.q_data.size,
      this.num_planned_data,
      str_status,
      str_interrupt,
      str_fault
    )
  );
endfunction:getInfo




function YesOrNo_t vdma_seq_item::isCompleted();
  YesOrNo_t result;

  if(this.trans_status == DMA_COMPLETED_WO_CONSIDERING_FAULT) return(YES);
  return(NO);
endfunction:isCompleted


function YesOrNo_t vdma_seq_item::isCardDataCompleted();
  if( this.q_data.size==this.num_planned_data ) return(YES);
  return(NO);
endfunction:isCardDataCompleted



function void vdma_seq_item::setPktGatheringInfo(DmaTransPktGatheringStatusType_t pkt_gathering_info); this.pkt_gathering_info = pkt_gathering_info; endfunction

function DmaTransPktGatheringStatusType_t vdma_seq_item::getPktGatheringInfo(); return(this.pkt_gathering_info); endfunction


function void vdma_seq_item::completeEndPkt();
  this.debug( $sformatf("Being completed=[%s]", this.getInfo) );
  if( this.desc.req_intr || this.desc.req_stat ) begin
      this.debug($sformatf("SET seq_item RESP_PHASE by Gathering / dma_id=%1d", DutParamDmaId_t'(this.desc.dma_id)));
    this.trans_status = DMA_ON_RESP_PHASE;
  end
  else begin
    this.debug($sformatf("SET seq_item completed by Gathering / dma_id=%1d", DutParamDmaId_t'(this.desc.dma_id)));
    this.trans_status = DMA_COMPLETED_WO_CONSIDERING_FAULT;
  end
endfunction:completeEndPkt



function void vdma_seq_item::computePktType();
  if( this.trans_type == ST_H2C) begin
    if(this.desc.sop == 1) begin
      if(this.desc.eop == 1) 	this.pkt_gathering_info = NOT_ON_PKT_GATHERING;
      else				            this.pkt_gathering_info = START_OF_PKT_GATHERING;
    end
    else begin
      if(this.desc.eop == 1) 	this.pkt_gathering_info = END_OF_PKT_GATHERING;
      else					          this.pkt_gathering_info = INTERMEDIATE_PKT_GATHERING;
    end
  end
  if( this.trans_type == ST_C2H || this.trans_type == MM_C2H || this.trans_type == MM_H2C ) begin
    this.pkt_gathering_info = NOT_ON_PKT_GATHERING;
  end
endfunction:computePktType





`endif // __VDMA_SEQ_ITEM_SVH__
