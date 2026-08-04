`ifndef __VDMATB_MM_H2C_SB_SVH__

`define __VDMATB_MM_H2C_SB_SVH__

class vdmatb_mm_h2c_sb extends vdmatb_sb;
  
  typedef struct{
    DmaId_t    dma_id;
    int        cnt_bresp;
  }CntBrespWithDmaId_t;
  
  typedef struct{
    DmaId_t    dma_id;
    logic[`SVT_AXI_RESP_WIDTH-1:0] bresp;
  }BrespWithDmaId_t;

  int flt_count   = 0;

  T_TRANS4 q_expected_card_temp[$];
  
  CntBrespWithDmaId_t q_cnt_bresp_with_dma_id[$];
  BrespWithDmaId_t    q_bresp_with_dma_id[$];

  `uvm_component_utils (vdmatb_mm_h2c_sb)

  YesOrNo_t cardDataCheck_expected_flag = NO;


  function new (string name = "vdmatb_mm_h2c_sb", uvm_component parent);
    super.new(name, parent);
  endfunction


  // ---------------------------- uvm built-in
  extern virtual function void build_phase(uvm_phase phase);


  // ---------------------------- vdma_sb built-in
  extern virtual function DmaTransType_t getTransType();
  extern virtual function void post_registerNewPkt(T_TRANS3 trans, T_TRANS trans2);

  extern virtual function void genExpectedHostArReq(T_TRANS3 trans, T_TRANS trans2);
  extern virtual function void genExpectedCardAwReq(T_TRANS3 trans, T_TRANS trans2);

  extern virtual function void post_updateMstData(T_TRANS3 trans, T_TRANS trans2);
  extern virtual function void post_updateHostData(T_TRANS3 trans, T_TRANS2 trans2);
  extern virtual function void post_updateCardData(T_TRANS3 trans, T_TRANS4 trans2);

  extern virtual function void callbackReset();


  // ---------------------------- vdmatb_mm_h2c_sb built-in
  extern virtual task cardDataChecker();
  extern virtual task hostDataChecker();

  extern virtual function YesOrNo_t checkFaultOnHostData(T_TRANS3 trans, T_TRANS2 trans2);
  extern virtual function YesOrNo_t checkFaultOnCardData(T_TRANS3 trans, T_TRANS4 trans2);

  extern virtual function void calculateHostExpected(T_TRANS data);
  extern virtual function void calculateCardExpected(T_TRANS data);

  extern virtual function void sampleDesc(T_TRANS trans);
  
  // ---------------------------- 
  extern local function void      countBTransFromDesc(T_TRANS trans);
  extern local function void      pushBrespWithDmaId(int cnt_bresp_trans, DmaId_t dma_id);
  extern local function YesOrNo_t isCntBTransSame(DmaId_t dma_id);
  extern local function logic[`SVT_AXI_RESP_WIDTH-1:0] calculate_FaultBrespBitwiseOr();
  
  extern local function int       calculateCardExpectedBurstLen(T_TRANS trans);
  extern local function Len_t     getLenGapFromCurAddrNNextAddr(logic[11:0] addr, int burst_len);
  extern local function YesOrNo_t isLenBiggerThanAddrTo4K(logic[11:0] start_addr, Len_t len);
  extern local function int       getDistanceStartAddrTo4K(logic[11:0] start_addr);
  extern local function int       countNumAwTransOnNotSplit4K(DmaId_t dma_id, logic[11:0] start_addr, Len_t len, int unsigned num_planned_data);
  extern local function int       countNumAwTransOnSplit4K(DmaId_t dma_id, logic[11:0] start_addr, Len_t len, int unsigned num_planned_data);
endclass:vdmatb_mm_h2c_sb


function void vdmatb_mm_h2c_sb::sampleDesc(T_TRANS trans);
  this.mm_sb_cov_colctr.sampleDesc(trans);
endfunction : sampleDesc


function void vdmatb_mm_h2c_sb::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction:build_phase



function DmaTransType_t vdmatb_mm_h2c_sb::getTransType();
  return(MM_H2C);
endfunction:getTransType

function void vdmatb_mm_h2c_sb::callbackReset();
  this.q_expected_card_temp.delete();
endfunction:callbackReset


function void vdmatb_mm_h2c_sb::post_registerNewPkt(T_TRANS3 trans, T_TRANS trans2);

  this.genExpectedHostArReq(trans, trans2);
  this.genExpectedCardAwReq(trans, trans2);

endfunction: post_registerNewPkt

// KTSB-9 : Generate expected Host AR request in H2C operation
function void vdmatb_mm_h2c_sb::genExpectedHostArReq(T_TRANS3 trans, T_TRANS trans2);
  static int num_created = 0;
  Desc_t                    desc;
  DmaId_t                   dma_id;
  StrId_t                   str_id;

  int                       max_hburst_len;
  int                       cur_burst_len;
  int                       next_burst_len;
  Len_t                     total_burst_len;
  Len_t                     data_len;
  Len_t                     remain_data_len;
  Addr_t                    araddr;
  Addr_t                    pkt_addr;
  Addr_t                    next_araddr;
  Addr_t                    end_araddr;
  Addr_t                    raddr;
  Addr_t                    next_raddr;
  HStrb_t                   strb;


  // START ----------- Initialize variables with DESC information
  desc = trans2.desc;

  dma_id          = DutParamDmaId_t'(desc.dma_id);
  str_id          = desc.str_id;
  data_len        = desc.len;
  max_hburst_len  = desc.axi_max_len;
  araddr          = DutParamHostAddr_t'(desc.src_addr);
  pkt_addr        = DutParamHostAddr_t'(desc.src_addr);

  end_araddr      = DutParamHostAddr_t'(araddr) + data_len;
  remain_data_len = data_len;
  total_burst_len = getTotalHostBurst(desc);
  if( (desc.axi_max_len> (AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH)) || (desc.axi_max_len==0) )
    max_hburst_len = AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH;

  this.debug($sformatf("[EXPECT_HOST_AR_1] PKT#%0d: src_addr=%0h, max_hburst_len=%0d, len_in_byte=%0d, len/%0d=%0d",
      DutParamDmaId_t'(desc.dma_id), DutParamHostAddr_t'(desc.src_addr), desc.axi_max_len, desc.len, HOST_DATA_BYTE_WIDTH, desc.len/HOST_DATA_BYTE_WIDTH));
  num_created++;
  cur_burst_len = max_hburst_len;
  next_araddr   = calculateNextHostAddr(DutParamHostAddr_t'(araddr), max_hburst_len, DutParamHostAddr_t'(end_araddr));
  cur_burst_len = updateCurrHostBurstLen(DutParamHostAddr_t'(araddr), DutParamHostAddr_t'(next_araddr));
  raddr         = DutParamHostAddr_t'(araddr);
  // END ----------- Initialize variables with DESC information

  // START ----------- Generate Expected HOST_AR
  while(remain_data_len) begin:while_begin_end
    T_TRANS2 expected;
    expected = T_TRANS2::type_id::create();

    this.debug($sformatf("[EXPECT_HOST_AR_2] PKT#%0d: remain_data_len=%0d, araddr=0x%0h, cur_burst_len=%0d, next_araddr=0x%0h",
        DutParamDmaId_t'(desc.dma_id), remain_data_len, DutParamHostAddr_t'(araddr), cur_burst_len, DutParamHostAddr_t'(next_araddr)));

    expected.dma_id   =  DutParamDmaId_t'(desc.dma_id);
    expected.desc.dma_id   =  DutParamDmaId_t'(desc.dma_id);
    expected.desc.str_id   =  desc.str_id;
    expected.arvalid  =  1'b1;
    expected.arready  =  1'b1;
    expected.arid     =  0;
    expected.araddr   =  DutParamHostAddr_t'(araddr);
    expected.pkt_addr =  DutParamHostAddr_t'(desc.src_addr);
    expected.arcache  =  2;
    expected.aruser   =  {desc.fnc_id, desc.str_id};
    expected.arburst  =  1;
    expected.arlen    =  cur_burst_len -1;
    expected.byteLen  =  desc.len;


    for(int i=0; i<cur_burst_len; i++) begin:host_data_loop

      // START ----------- Expected WSTRB
      // First Burst
      if( remain_data_len == data_len ) begin
        if(data_len < HOST_DATA_BYTE_WIDTH) begin
          strb = (this.max_host_wstrb >> (HOST_DATA_BYTE_WIDTH-data_len));
          strb = (strb << DutParamHostAddr_t'(desc.src_addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0]));
        end
        else begin
          strb = (this.max_host_wstrb << DutParamHostAddr_t'(desc.src_addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0]));
        end
      end
      // Middle of Bursts
      else if(remain_data_len >= HOST_DATA_BYTE_WIDTH) begin
        strb = this.max_host_wstrb;
      end
      // Last Burst
      else if( (remain_data_len>0) && (remain_data_len<HOST_DATA_BYTE_WIDTH) ) begin
        strb = ~(this.max_host_wstrb << remain_data_len);
      end
      // END ----------- Expected WSTRB

      remain_data_len = remain_data_len - checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(strb);
      next_raddr = DutParamHostAddr_t'(raddr) + checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(strb);

      expected.wstrb.push_back(strb);
      expected.raddr.push_back(DutParamHostAddr_t'(raddr));

      this.debug($sformatf("[EXPECT_HOST_AR_3] PKT#%0d: araddr=0x%0h, raddr=0x%0h, strb=%0h, num_of_data=%0d, wstrb.size=%0d, remain_data_len=%0d",
          DutParamDmaId_t'(expected.dma_id), DutParamHostAddr_t'(araddr), DutParamHostAddr_t'(raddr), strb, checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(strb), expected.wstrb.size(), remain_data_len));

      if( remain_data_len == 0 ) break;

      raddr = DutParamHostAddr_t'(next_raddr);

    end:host_data_loop


    this.debug($sformatf("[NEW_EXPECTED_HOST_AR] PKT#%0d: pkt_addr=0x%0h, araddr=0x%0h, aruser=%0d, arlen=%0d, size(num_data)=%0d",
        DutParamDmaId_t'(expected.dma_id), DutParamHostAddr_t'(expected.pkt_addr), DutParamHostAddr_t'(expected.araddr), expected.aruser, expected.arlen, expected.wstrb.size()));
    this.q_expected_host_req.push_back(expected);

    this.debug($sformatf("[EXPECT_HOST_AR_4] araddr=0x%0h, next_araddr=0x%0h, raddr=0x%0h / cur_burst_len=%0d",
        DutParamHostAddr_t'(araddr), DutParamHostAddr_t'(next_araddr), DutParamHostAddr_t'(raddr), cur_burst_len));

    // Update with NEXT
    araddr = DutParamHostAddr_t'(raddr); //next_araddr;
    next_araddr = calculateNextHostAddr(DutParamHostAddr_t'(araddr), max_hburst_len, DutParamHostAddr_t'(end_araddr));
    next_burst_len = updateCurrHostBurstLen(DutParamHostAddr_t'(araddr), DutParamHostAddr_t'(next_araddr));
    cur_burst_len = next_burst_len;

  end:while_begin_end

  this.calculateHostExpected(trans2);
endfunction:genExpectedHostArReq



// KTSB-9 : Generate expected Card AW request in H2C operation
function void vdmatb_mm_h2c_sb::genExpectedCardAwReq(T_TRANS3 trans, T_TRANS trans2);

  static int num_created = 0;
  Desc_t                    desc;
  DmaId_t                   dma_id;
  StrId_t                   str_id;

  int                       max_cburst_len;
  int                       cur_burst_len;
  int                       next_burst_len;
  Len_t                     total_burst_len;
  Len_t                     data_len;
  Len_t                     remain_data_len;
  Addr_t                    awaddr;
  Addr_t                    pkt_addr;
  Addr_t                    next_awaddr;
  Addr_t                    end_awaddr;
  Addr_t                    waddr;
  Addr_t                    next_waddr;
  CStrb_t                   strb;
  CntBrespWithDmaId_t       cnt_bresp_with_dma_id;


  // START ----------- Initialize variables with DESC information
  this.countBTransFromDesc(trans2);
  
  desc = trans2.desc;

  dma_id          = DutParamDmaId_t'(desc.dma_id);
  str_id          = desc.str_id;
  data_len        = desc.len;
  awaddr          = DutParamCardAddr_t'(desc.dst_addr);
  pkt_addr        = DutParamCardAddr_t'(desc.dst_addr);

  end_awaddr      = DutParamCardAddr_t'(awaddr + data_len);
  remain_data_len = data_len;
  total_burst_len = getTotalCardBurst(desc);
  max_cburst_len = AXI_4K_BOUNDARY / CARD_DATA_BYTE_WIDTH;
  
  if(max_cburst_len >= 256) max_cburst_len = 256;

  this.debug($sformatf("[EXPECT_CARD_AW_1] PKT#%0d: dst_addr=%0h, max_cburst_len=%0d, len_in_byte=%0d, len/%0d=%0d",
      DutParamDmaId_t'(desc.dma_id), DutParamCardAddr_t'(desc.dst_addr), max_cburst_len, desc.len, CARD_DATA_BYTE_WIDTH, desc.len/CARD_DATA_BYTE_WIDTH));

  num_created++;
  cur_burst_len = max_cburst_len;
  next_awaddr   = calculateNextCardAddr(DutParamCardAddr_t'(awaddr), max_cburst_len, DutParamCardAddr_t'(end_awaddr));
  this.debug($sformatf("[EXPECT_CARD_AW_1_1] PKT#%0d: awaddr=%0h, end_awaddr=%0h, nex_awaddr=%0h", desc.dma_id, awaddr, end_awaddr, next_awaddr));
  cur_burst_len = updateCurrCardBurstLen(DutParamCardAddr_t'(awaddr), DutParamCardAddr_t'(next_awaddr));
  waddr         = DutParamCardAddr_t'(awaddr);
  // END ----------- Initialize variables with DESC information


  // START ----------- Generate Expected CARD_AW
  while(remain_data_len) begin:while_begin_end
    T_TRANS4 expected;
    expected = T_TRANS4::type_id::create();

    this.debug($sformatf("[EXPECT_CARD_AW_2] PKT#%0d: remain_data_len=%0d, awaddr=%0h, cur_burst_len=%0d, next_awaddr=%0h",
        DutParamDmaId_t'(desc.dma_id), remain_data_len, DutParamCardAddr_t'(awaddr), cur_burst_len, DutParamCardAddr_t'(next_awaddr)));

    expected.dma_id   =  DutParamDmaId_t'(desc.dma_id);
    expected.awvalid  =  1'b1;
    expected.awready  =  1'b1;
    expected.awid     =  0;
    expected.awaddr   =  DutParamCardAddr_t'(awaddr);
    expected.awcache  =  2;
    expected.awuser   =  {desc.dma_id};
    expected.awburst  =  1;
    expected.awlen    =  cur_burst_len -1;
    expected.byteLen  =  desc.len;


    for(int i=0; i<cur_burst_len; i++) begin:card_data_loop

      // START ----------- Expected WSTRB
      // First Burst
      if( remain_data_len == data_len ) begin
        if(data_len < CARD_DATA_BYTE_WIDTH) begin
          strb = (this.max_card_wstrb >> (CARD_DATA_BYTE_WIDTH-data_len));
          strb = (strb << DutParamCardAddr_t'(desc.dst_addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0]));
        end
        else begin
          strb = (this.max_card_wstrb << DutParamCardAddr_t'(desc.dst_addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0]));
        end
      end
      // Middle of Bursts
      else if(remain_data_len >= CARD_DATA_BYTE_WIDTH) begin
        strb = this.max_card_wstrb;
      end
      // Last Burst
      else if( (remain_data_len>0) && (remain_data_len<CARD_DATA_BYTE_WIDTH) ) begin
        strb = ~(this.max_card_wstrb << remain_data_len);
      end
      // END ----------- Expected WSTRB

      remain_data_len = remain_data_len - checkItems#(CARD_DATA_BYTE_WIDTH)::countOnes(strb);
      next_waddr = DutParamCardAddr_t'(waddr) + checkItems#(CARD_DATA_BYTE_WIDTH)::countOnes(strb);

      expected.wstrb.push_back(strb);
      expected.waddr.push_back(DutParamCardAddr_t'(waddr));

      this.debug($sformatf("[EXPECT_CARD_AW_3] PKT#%0d: awaddr=0x%0h, waddr=0x%0h, strb=%0h, num_of_data=%0d, wstrb.size=%0d, remain_data_len=%0d",
          DutParamDmaId_t'(expected.dma_id), DutParamCardAddr_t'(awaddr), DutParamCardAddr_t'(waddr), strb, checkItems#(CARD_DATA_BYTE_WIDTH)::countOnes(strb), expected.wstrb.size(), remain_data_len));

      if( remain_data_len == 0 ) break;

      waddr = DutParamCardAddr_t'(next_waddr);

    end:card_data_loop


    this.debug($sformatf("[NEW_EXPECTED_CARD_AW] PKT#%0d: pkt_addr=0x%0h, awaddr=0x%0h, awuser=%0d, awlen=%0d, size(num_data)=%0d",
        DutParamDmaId_t'(expected.dma_id), DutParamCardAddr_t'(pkt_addr), DutParamCardAddr_t'(expected.awaddr), expected.awuser, expected.awlen, expected.wstrb.size()));
    this.q_expected_card_req.push_back(expected);

    this.debug($sformatf("[EXPECT_CARD_AW_4] awaddr=0x%0h, next_awaddr=0x%0h, waddr=0x%0h / cur_burst_len=%0d",
        DutParamCardAddr_t'(awaddr), DutParamCardAddr_t'(next_awaddr), DutParamCardAddr_t'(waddr), cur_burst_len));

    // Update with NEXT
    awaddr = DutParamCardAddr_t'(waddr); //next_awaddr;
    next_awaddr = calculateNextCardAddr(DutParamCardAddr_t'(awaddr), max_cburst_len, DutParamCardAddr_t'(end_awaddr));
    next_burst_len = updateCurrCardBurstLen(DutParamCardAddr_t'(awaddr), DutParamCardAddr_t'(next_awaddr));
    cur_burst_len = next_burst_len;

  end:while_begin_end

  this.calculateCardExpected(trans2);

endfunction:genExpectedCardAwReq


function int vdmatb_mm_h2c_sb::calculateCardExpectedBurstLen(T_TRANS trans);
  DmaId_t      dma_id;
  Len_t        len, remained_len;
  logic[11:0]  start_addr;
  int unsigned num_planned_data;
  YesOrNo_t    isLenBigger;
  int          num_total_awlen = 0;
  
  dma_id       = trans.getDmaId();
  len          = trans.desc.len;
  remained_len = len;
  start_addr   = trans.desc.dst_addr[11:0];
  
  num_planned_data = len / CARD_DATA_BYTE_WIDTH;
  if((len % CARD_DATA_BYTE_WIDTH) != 0) num_planned_data++;

  isLenBigger  = this.isLenBiggerThanAddrTo4K(start_addr, len);
  
  if(isLenBigger == NO) num_total_awlen    = this.countNumAwTransOnNotSplit4K(dma_id, start_addr, remained_len, num_planned_data);
  else                  num_total_awlen    = this.countNumAwTransOnSplit4K(dma_id, start_addr, remained_len, num_planned_data);
 
  return(num_total_awlen);
endfunction : calculateCardExpectedBurstLen 


function int vdmatb_mm_h2c_sb::countNumAwTransOnNotSplit4K(DmaId_t dma_id, logic[11:0] start_addr, Len_t len, int unsigned num_planned_data);
  logic[31:0]  expected_awlen_to_1st_4K, tmp_awlen_to_1st_4K, expected_awlen_after_1st_4K;
  Len_t        remained_len, to_add_len;
  int          num_awlen_to_1st_4K = 0;
 
  remained_len             = len;
  expected_awlen_to_1st_4K = num_planned_data;
  to_add_len               = this.getLenGapFromCurAddrNNextAddr(start_addr, expected_awlen_to_1st_4K);
  remained_len             = remained_len + to_add_len;
  
  while(remained_len > 0) begin
    if(expected_awlen_to_1st_4K >= 256) begin
      expected_awlen_to_1st_4K -= 256;
      remained_len             -= 256 * CARD_DATA_BYTE_WIDTH;
      
      num_awlen_to_1st_4K++;
    end
    else begin
      if(expected_awlen_to_1st_4K == 0) begin
        num_awlen_to_1st_4K++;
        
        break;
      end
      else begin
        remained_len = expected_awlen_to_1st_4K * CARD_DATA_BYTE_WIDTH;
        num_awlen_to_1st_4K++;
        
        break;
      end
    end
  end
  
  return(num_awlen_to_1st_4K);
endfunction : countNumAwTransOnNotSplit4K


function int vdmatb_mm_h2c_sb::countNumAwTransOnSplit4K(DmaId_t dma_id, logic[11:0] start_addr, Len_t len, int unsigned num_planned_data);
  Len_t        remained_len, to_add_len;
  logic[31:0]  expected_awlen_to_1st_4K, tmp_awlen_to_1st_4K, expected_awlen_after_1st_4K;
  logic[31:0]  remained_addr_to_1st_4K;
  int          num_awlen_to_1st_4K = 0, num_awlen_after_1st_4K = 0;
 
  remained_len            = len;
  remained_addr_to_1st_4K = this.getDistanceStartAddrTo4K(start_addr);
    
  expected_awlen_to_1st_4K = remained_addr_to_1st_4K / CARD_DATA_BYTE_WIDTH;
  if(remained_addr_to_1st_4K % CARD_DATA_BYTE_WIDTH != 0) expected_awlen_to_1st_4K++;
  tmp_awlen_to_1st_4K = expected_awlen_to_1st_4K;
  
  to_add_len   = this.getLenGapFromCurAddrNNextAddr(start_addr, expected_awlen_to_1st_4K);
  remained_len = remained_len + to_add_len;
  
  while(expected_awlen_to_1st_4K > 0) begin : Before_4K
    if(expected_awlen_to_1st_4K >= 256) begin
      expected_awlen_to_1st_4K -= 256;
      remained_len             -= 256 * CARD_DATA_BYTE_WIDTH;
      
      num_awlen_to_1st_4K++;
    end
    else begin
      remained_len            -= expected_awlen_to_1st_4K * CARD_DATA_BYTE_WIDTH;
      expected_awlen_to_1st_4K = 0;
      
      num_awlen_to_1st_4K++;
    end
  end : Before_4K
  
  expected_awlen_after_1st_4K = num_planned_data - tmp_awlen_to_1st_4K;
  
  while(remained_len > 0) begin : After_4K
    if(expected_awlen_after_1st_4K >= 256) begin
      expected_awlen_after_1st_4K -= 256;
      
      if(remained_len < 256 * CARD_DATA_BYTE_WIDTH) remained_len  = 0;
      else                                          remained_len -= 256 * CARD_DATA_BYTE_WIDTH;
     
      num_awlen_after_1st_4K++;
    end
    else begin
      if(expected_awlen_after_1st_4K == 0) begin
        num_awlen_after_1st_4K++;
        break;
      end
      else begin
        remained_len -= expected_awlen_after_1st_4K * CARD_DATA_BYTE_WIDTH;
        num_awlen_after_1st_4K++;
        break;
      end
    end
  end : After_4K
  
  return(num_awlen_to_1st_4K + num_awlen_after_1st_4K);
endfunction : countNumAwTransOnSplit4K


function Len_t vdmatb_mm_h2c_sb::getLenGapFromCurAddrNNextAddr(logic[11:0] addr, int burst_len);
  int   next_addr, changed_addr;
  Len_t result_len;
  
  if(burst_len >= 256) burst_len = 256;
  
  next_addr    = addr + (burst_len * CARD_DATA_BYTE_WIDTH);
  changed_addr = next_addr - (next_addr % CARD_DATA_BYTE_WIDTH);
  
  result_len   = next_addr - changed_addr;
  
  return(result_len);
endfunction


function pmg_pkg::YesOrNo_t vdmatb_mm_h2c_sb::isLenBiggerThanAddrTo4K(logic[11:0] start_addr, Len_t len);
  if(AXI_4K_BOUNDARY - start_addr > len) return(NO);
  else                                   return(YES);
endfunction : isLenBiggerThanAddrTo4K


function int vdmatb_mm_h2c_sb::getDistanceStartAddrTo4K(logic[11:0] start_addr);
  return(AXI_4K_BOUNDARY - start_addr);
endfunction : getDistanceStartAddrTo4K


function void vdmatb_mm_h2c_sb::countBTransFromDesc(T_TRANS trans);
  DmaId_t             dma_id;
  Len_t               len;
  logic[11:0]         addr;
  int                 cnt_b_trans;
  
  dma_id = DutParamDmaId_t'(trans.desc.dma_id);
  len    = trans.desc.len;
  
  case(CARD_DATA_WIDTH)
    512 : begin
      addr = trans.desc.dst_addr[11:0];
      
      cnt_b_trans = (len + addr) / AXI_4K_BOUNDARY;
      if((len + addr) % AXI_4K_BOUNDARY != 0) cnt_b_trans++;
    end
    32 : begin
      cnt_b_trans = this.calculateCardExpectedBurstLen(trans);
    end
  endcase
  
  this.pushBrespWithDmaId(cnt_b_trans, dma_id);
endfunction : countBTransFromDesc



function void vdmatb_mm_h2c_sb::pushBrespWithDmaId(int cnt_bresp_trans, DmaId_t dma_id);
  CntBrespWithDmaId_t cnt_bresp_with_dma_id;
  
  cnt_bresp_with_dma_id.cnt_bresp = cnt_bresp_trans;
  cnt_bresp_with_dma_id.dma_id    = DutParamDmaId_t'(dma_id);
  this.q_cnt_bresp_with_dma_id.push_back(cnt_bresp_with_dma_id);
endfunction : pushBrespWithDmaId



function YesOrNo_t vdmatb_mm_h2c_sb::isCntBTransSame(DmaId_t dma_id);
  foreach(this.q_cnt_bresp_with_dma_id[i]) begin
    if(this.q_cnt_bresp_with_dma_id[i].dma_id == dma_id) begin
      if(this.q_bresp_with_dma_id.size == this.q_cnt_bresp_with_dma_id[i].cnt_bresp) begin
        this.q_cnt_bresp_with_dma_id.delete(i);
        return(YES);
      end
    end
  end
  
  return(NO);
endfunction : isCntBTransSame



function logic[`SVT_AXI_RESP_WIDTH-1:0] vdmatb_mm_h2c_sb::calculate_FaultBrespBitwiseOr();
  int                            q_size;
  logic[`SVT_AXI_RESP_WIDTH-1:0] output_bresp = 0;
  
  q_size = this.q_bresp_with_dma_id.size();
  
  for(int i = 0; i < q_size; i++) begin
    BrespWithDmaId_t               bresp_with_dma_id;
    logic[`SVT_AXI_RESP_WIDTH-1:0] pop_bresp;
    
    bresp_with_dma_id = this.q_bresp_with_dma_id.pop_front();
    pop_bresp         = bresp_with_dma_id.bresp;
    output_bresp     |= pop_bresp;
  end
  
  return(output_bresp);
endfunction : calculate_FaultBrespBitwiseOr



// KTSB-22 : H2C post_updateMstData
function void vdmatb_mm_h2c_sb::post_updateMstData(T_TRANS3 trans, T_TRANS trans2);
endfunction:post_updateMstData



function void vdmatb_mm_h2c_sb::post_updateHostData(T_TRANS3 trans, T_TRANS2 trans2);
  YesOrNo_t fault;

  fault = this.checkFaultOnHostData(trans, trans2);

endfunction:post_updateHostData



function void vdmatb_mm_h2c_sb::post_updateCardData(T_TRANS3 trans, T_TRANS4 trans2);
  YesOrNo_t fault;

  fault = this.checkFaultOnCardData(trans, trans2);

endfunction:post_updateCardData



function YesOrNo_t vdmatb_mm_h2c_sb::checkFaultOnHostData(T_TRANS3 trans, T_TRANS2 trans2);
  YesOrNo_t result = NO;
  YesOrNo_t result_all = NO;
  YesOrNo_t result_plast = NO;
  YesOrNo_t result_rresp = NO;
  YesOrNo_t result_sgl = NO;
  Desc_t desc;
  logic q_rlast[$];
  logic [`SVT_AXI_RESP_WIDTH-1:0]                 q_rresp[$];

  Fault_t created_fault;
  Interrupt_t created_fault_intr;
  
  int  cnt_rlast = 0;
  int  cnt_rresp = 0;


  q_rlast = trans2.q_rlast;
  q_rresp = trans2.q_rresp;


  desc = trans.desc;


  created_fault.dma_id = DutParamDmaId_t'(desc.dma_id);
  created_fault.str_id = desc.str_id;
  created_fault.axi_resp = 0;
  created_fault_intr.dma_id = DutParamDmaId_t'(desc.dma_id);
  created_fault_intr.fnc_id = desc.fnc_id;

  this.debug($sformatf("result: %0h, aruser : %0h, rdata_size : %0d, rlast_size : %0d, dma_id : %0h, str_id : %0h, fault_code : %0h", result, trans2.aruser, trans2.rdata.size(), q_rlast.size(), DutParamDmaId_t'(desc.dma_id), created_fault.str_id, created_fault.code));

  // All Data transaction(beats) check : HOST_R_PREMATURE_LAST, HOST_R_WRONG_RESP
  foreach( q_rlast[i] ) begin:Q_ALL_CHK
    // KTSB- : Fault Code : HOST_R_PREMATURE_LAST
    this.debug($sformatf("[PREMATURE_LAST_CHECK] result: %0h, rlast : %0h, q_rlast_size : %0d, cnt_rlast : 0%d", result, q_rlast[i], q_rlast.size(), cnt_rlast));
    if( q_rlast[i] == 1 ) begin
      if( i != (q_rlast.size()-1) ) begin
        CovFault_t cov_host_r_premature_last;
        
        created_fault.code = HOST_R_PREMATURE_LAST;
        result_plast = YES;
        this.debug($sformatf("[FAIL_HOST_R_PREMATURE_LAST] result: %0h, rlast : %0d, fault_code : %0h, failed_rlast_in_q : %0d", result, q_rlast[i], created_fault.code, i));
        
        cov_host_r_premature_last.dma_id     = DutParamDmaId_t'(created_fault.dma_id);
        cov_host_r_premature_last.fault_code = int'(created_fault.code); 
        this.q_cov_expected_fault_host_r_premature_last.push_back(cov_host_r_premature_last);
      end
    end
    //end

    // KTSB- : HOST_R_WRONG_RESP - Check Fault code within RRESP
    if( q_rresp[i] != 0 ) begin
      CovWrongResp_t cov_host_r_wrong_resp;
      
      created_fault.axi_resp = q_rresp[i];
      created_fault.code = HOST_R_WRONG_RESP;
      result_rresp = YES;
      this.debug($sformatf("[FAIL_HOST_R_WRONG_RESP] result: %0h, rresp : %0h, fault_code : %0h, rresp : %0h", result, created_fault.axi_resp, created_fault.code, q_rresp[i]));
      
      cov_host_r_wrong_resp.dma_id = DutParamDmaId_t'(desc.dma_id);
      cov_host_r_wrong_resp.resp   = created_fault.axi_resp;
      this.q_actual_fault_host_r_wrong_resp.push_back(cov_host_r_wrong_resp);
    end

    if((result_plast == YES) || (result_rresp == YES)) result_all = YES;
    else result_all = NO;

    if( result_all == YES ) begin

      this.flt_count++;


      created_fault_intr.vec_id = 'h1f;
      created_fault_intr.fnc_id = 'hff;

      this.q_expected_host_fault.push_back(created_fault);
      this.q_expected_host_fault_intr.push_back(created_fault_intr);

      this.debug($sformatf("[EXPECT_FAULT_ON_HOST_DATA] Host Data has fault case w/ dma_id=%0d, fault_code=%0d, str_id=%0h, fnc_id=%0h, q_flt_size=%0d, q_flt_intr_size=%0d",
          DutParamDmaId_t'(created_fault.dma_id), created_fault.code, created_fault.str_id, created_fault_intr.fnc_id,q_expected_host_fault.size(),q_expected_host_fault_intr.size()));
    end

    result_plast = NO;
    result_rresp = NO;

  end:Q_ALL_CHK



  // Single transaction check : HOST_R_NO_LAST
  if( result_all == NO ) begin:Q_SINGLE_CHK
    // KTSB- : Fault Code : HOST_R_NO_LAST
    if( q_rlast[$] == 0 ) begin
      CovFault_t cov_host_r_no_last;
      
      created_fault.code = HOST_R_NO_LAST;
      result_sgl = YES;
      this.debug($sformatf("[FAIL_HOST_R_NO_LAST] result: %0h,  q_rlast_size : %0d, cnt_rlast : %0d, fault_code : %0h", result, q_rlast.size(), cnt_rlast, created_fault.code));
      
      cov_host_r_no_last.dma_id     = DutParamDmaId_t'(created_fault.dma_id);
      cov_host_r_no_last.fault_code = int'(created_fault.code);
      this.q_cov_expected_fault_host_r_no_last.push_back(cov_host_r_no_last);
    end

    if( result_sgl == YES ) begin

      this.flt_count++;

      created_fault_intr.vec_id = 'h1f;
      created_fault_intr.fnc_id = 'hff;

      this.q_expected_host_fault.push_back(created_fault);
      this.q_expected_host_fault_intr.push_back(created_fault_intr);

      this.debug($sformatf("[EXPECT_FAULT_ON_HOST_DATA] Host Data has fault case w/ dma_id=%0d, fault_code=%0d, str_id=%0h, fnc_id=%0h, q_flt_size=%0d, q_flt_intr_size=%0d",
          DutParamDmaId_t'(created_fault.dma_id), created_fault.code, created_fault.str_id, created_fault_intr.fnc_id,q_expected_host_fault.size(),q_expected_host_fault_intr.size()));
    end

  end:Q_SINGLE_CHK


  if((result_all == YES) | (result_sgl == YES)) result = YES;

  this.debug($sformatf("[EXPECT_FAULT_STAT] flt_count=%0d", this.flt_count));

  return(result);

endfunction:checkFaultOnHostData



function YesOrNo_t vdmatb_mm_h2c_sb::checkFaultOnCardData(T_TRANS3 trans, T_TRANS4 trans2);
  YesOrNo_t result = NO;

  Desc_t desc;
  logic [`SVT_AXI_RESP_WIDTH-1:0] bresp;

  Fault_t created_fault;
  Interrupt_t created_fault_intr;
 
  BrespWithDmaId_t bresp_with_dma_id;
  logic[`SVT_AXI_RESP_WIDTH-1:0] calculated_bresp;
  YesOrNo_t                      isCntBTransSame = NO;

  bresp = trans2.bresp;

  desc = trans.desc;

  created_fault.dma_id = DutParamDmaId_t'(desc.dma_id);
  created_fault.str_id = desc.str_id;
  created_fault.axi_resp = 0;
  created_fault_intr.dma_id = DutParamDmaId_t'(desc.dma_id);
  created_fault_intr.fnc_id = desc.fnc_id;

  this.debug($sformatf("result: %0h, awuser : %0h, wdata_size : %0d, dma_id : %0h, str_id : %0h, fault_code : %0h", result, trans2.awuser, trans2.wdata.size(), DutParamDmaId_t'(desc.dma_id), created_fault.str_id, created_fault.code));

  bresp_with_dma_id.dma_id = DutParamDmaId_t'(desc.dma_id);
  bresp_with_dma_id.bresp  = bresp;
  this.q_bresp_with_dma_id.push_back(bresp_with_dma_id);
  
  isCntBTransSame = this.isCntBTransSame(desc.dma_id);
  
  if(isCntBTransSame == YES) begin
    calculated_bresp = this.calculate_FaultBrespBitwiseOr();
    
    if(calculated_bresp != 0) begin
      CovWrongResp_t cov_card_b_wrong_resp;
      
      created_fault.axi_resp = calculated_bresp;
      created_fault.code     = CARD_B_WRONG_RESP;
      result                 = YES;
      
      cov_card_b_wrong_resp.dma_id = DutParamDmaId_t'(desc.dma_id);
      cov_card_b_wrong_resp.resp   = calculated_bresp;
      this.q_actual_fault_card_b_wrong_resp.push_back(cov_card_b_wrong_resp);
      this.debug($sformatf("[FAIL_CARD_B_WRONG_RESP] result: %0h, bresp : %0h, fault_code : %0h, bresp : %0h", result, created_fault.axi_resp, created_fault.code, bresp));
    end
  end


  if( result == YES ) begin

    this.flt_count++;


    created_fault_intr.vec_id = 'h1f;
    created_fault_intr.fnc_id = 'hff;

    this.q_expected_card_fault.push_back(created_fault);
    this.q_expected_card_fault_intr.push_back(created_fault_intr);

    this.debug($sformatf("[EXPECT_FAULT_ON_CARD_DATA] Card Data has fault case w/ dma_id=%0d, fault_code=%0d, str_id=%0h, fnc_id=%0h, q_flt_size=%0d, q_flt_intr_size=%0d",
        DutParamDmaId_t'(created_fault.dma_id), created_fault.code, created_fault.str_id, created_fault_intr.fnc_id,q_expected_card_fault.size(),q_expected_card_fault_intr.size()));
  end

  this.debug($sformatf("[EXPECT_FAULT_STAT] flt_count=%0d", this.flt_count));

  return(result);

endfunction:checkFaultOnCardData



task vdmatb_mm_h2c_sb::hostDataChecker();

  T_TRANS2      actual, host_expected;

  Addr_t        host_expected_addr;
  HStrb_t       host_expected_wstrb;
  bit           gathering = 1'b0;
  int           cnt_ar = 0, cnt_bl = 0;
  int           expected_byte;
  int           expected_ar_len = 0;
  int           byte_cnt = 0;
  DmaId_t       cur_dma_id = 0;

  T_TRANS4      card_expected;

  CData_t       card_expected_data;
  HData_t       host_expected_data;
  HData_t       actual_data, actual_data_shift;

  Byte_t        tmp_data[$];

  host_expected = T_TRANS2::type_id::create();
  card_expected = T_TRANS4::type_id::create();

  forever begin:forever_end
    wait(this.q_expected_host_data.size() > 0);
    this.sb_flag.flag_h2c_hostData = NO;

    if(this.q_expected_host_data.size() > 0) begin:expected_host_qsize
      cnt_ar++;
      cnt_bl=0;

      wait(this.q_actual_host_data.size() > 0 );
      actual = this.q_actual_host_data.pop_front();
      this.mm_sb_cov_colctr.sampleHostArLen(actual.arlen);

      if(host_expected.wstrb.size() == 0) begin:update_expected_item
        host_expected        = this.q_expected_host_data.pop_front();
        host_expected_addr   = DutParamHostAddr_t'(host_expected.araddr);
        expected_ar_len = host_expected.wstrb.size();
        expected_byte   = host_expected.byteLen;
        cur_dma_id      = DutParamDmaId_t'(host_expected.dma_id);
      end:update_expected_item
      this.debug($sformatf("[COMPARE_HOST_DATA_EXPECTED] dma_id=%0d, host_expected_addr=0x%0h, len=%0d/%0d",
          DutParamDmaId_t'(host_expected.dma_id), host_expected_addr, expected_ar_len, host_expected.arlen));
      this.debug($sformatf("[COMPARE_HOST_DATA_ACTUAL ] dma_id=%0d, actual.addr=%0h, acutal.arBL=%0d, expected_ar_len=%0d, wstrb.size=%0d",
          DutParamDmaId_t'(actual.dma_id), DutParamHostAddr_t'(actual.araddr), actual.arlen, expected_ar_len, host_expected.wstrb.size()));

      if(host_expected.raddr.size() > 0) begin:update_expected_addr
        host_expected_addr = DutParamHostAddr_t'(host_expected.raddr.pop_front());
      end:update_expected_addr

      begin:AXIChecker
        if( checkItems#(MAX_ADDR_WIDTH)::compareItem("H2C_SB_ARADDR", "araddr", DutParamDmaId_t'(cur_dma_id), DutParamHostAddr_t'(actual.araddr), DutParamHostAddr_t'(host_expected_addr), 0) )
          this.error("COMPARE_ARADDR_ERROR", $sformatf("(actual/expected) araddr=0x%0h/0x%0h", DutParamHostAddr_t'(actual.araddr), DutParamHostAddr_t'(host_expected_addr)));

        if( checkItems#(16)::compareItem("H2C_SB_ARUSER", "aruser", DutParamDmaId_t'(cur_dma_id), actual.aruser, host_expected.aruser, 0) )
          this.error("COMPARE_ARUSER_ERROR", $sformatf("(actual/expected) aruser=0x%0h/0x%0h", actual.aruser, host_expected.aruser));

        if( checkItems#(1)::compareItem("H2C_SB_ARID", "arid", DutParamDmaId_t'(cur_dma_id), actual.arid, host_expected.arid, 0) )
          this.error("COMPARE_ARID_ERROR", $sformatf("(actual/expected) arid=0x%0h/0x%0h", actual.arid, host_expected.arid));

        if( checkItems#( 4)::compareItem("H2C_SB_ARCACHE", "arache", DutParamDmaId_t'(cur_dma_id), actual.arcache, host_expected.arcache) )
          this.error("COMPARE_ARCACHE_ERROR", $sformatf("(actual/expected) arcache=0x%0h/0x%0h", actual.arcache, host_expected.arcache));

        if( checkItems#( 2)::compareItem("H2C_SB_ARBURST", "arburst", DutParamDmaId_t'(cur_dma_id), actual.arburst, host_expected.arburst, 0) )
          this.error("COMPARE_ARBURST_ERROR", $sformatf("(actual/expected) arburst=%0d/%0d", actual.arburst, host_expected.arburst));
      end:AXIChecker

      for(int i=0; i<actual.arlen+1; i++) begin:for_actual_arlen
        cnt_bl++;
        expected_ar_len--;

        this.debug($sformatf("[COMPARE_HOST_DATA_ACTUAL] dma_id=%0d, expect_ar_len=%0d, strb.size=%0d, actual.araddr=0x%0h, actual.arlen=%0d", DutParamDmaId_t'(cur_dma_id), expected_ar_len, host_expected.wstrb.size(), DutParamHostAddr_t'(actual.araddr), actual.arlen+1));

        if( (i<actual.arlen) && (host_expected.raddr.size()>0) ) host_expected_addr = DutParamHostAddr_t'(host_expected.raddr.pop_front());
        if( host_expected.wstrb.size() > 0 ) begin
          host_expected_wstrb = host_expected.wstrb.pop_front();
        end
//        foreach(actual.rdata[i])
        actual_data = actual.rdata.pop_front();
        actual_data_shift = actual_data;

        this.debug($sformatf("[COMPARE_HOST_DATA_ACTUAL_RDATA_2] dma_id=%0d, gathering=%0d, sop/eop=%0d/%0d, actual_araddr=0x%0h, expected_wstrb=0x%0h, actual.rdata.size=%0d, actual_data=0x%0h, byte_cnt=%0d",
            DutParamDmaId_t'(cur_dma_id), gathering, host_expected.sop, host_expected.eop, DutParamHostAddr_t'(actual.araddr), host_expected_wstrb, actual.rdata.size(), actual_data, byte_cnt));

        for(int j=0; j<HOST_DATA_BYTE_WIDTH; j++) begin:for_byte
          if(host_expected_wstrb[j]) begin:if_wstrb
            tmp_data.push_back(actual_data_shift[7:0]);
          end:if_wstrb

          actual_data_shift = actual_data_shift >> 8;
          expected_byte = expected_byte - host_expected_wstrb[j];

        end

        this.debug($sformatf("[KITEC] expected_byte = %0d", expected_byte));

        if(expected_byte==0) begin
          int q_expected_card_temp_size = 0;
          
          if(this.q_expected_card_temp.size() == 0) wait(this.q_expected_card_temp.size() > 0);
          
          q_expected_card_temp_size = this.q_expected_card_temp.size();
          
          for(int j = 0; j < q_expected_card_temp_size; j++) begin
            if (this.q_expected_card_temp[0].dma_id == cur_dma_id) begin
              card_expected = this.q_expected_card_temp.pop_front();
              foreach(card_expected.wstrb[k]) begin
                card_expected_data = 0;
                
                for(int l=0; l<CARD_DATA_BYTE_WIDTH; l++) begin
                  if(card_expected.wstrb[k][l] == 0) begin
                    card_expected_data[CARD_DATA_WIDTH-1:CARD_DATA_WIDTH-8] = 0;
                  end else begin
                    card_expected_data[CARD_DATA_WIDTH-1:CARD_DATA_WIDTH-8] = tmp_data.pop_front();
                  end
                  
                  if(l<CARD_DATA_BYTE_WIDTH-1) begin
                    card_expected_data = card_expected_data >> 8;
                  end
                end
                
                this.debug($sformatf("[CARD_DATA_CHECK] PKT#%0d q_expected_card_temp[%0d].wdata[%0d] = %0h", cur_dma_id, j, k, card_expected_data));
                card_expected.wdata.push_back(card_expected_data);
              end
              this.q_expected_card_data.push_back(card_expected);
            end
          end
        end

      end:for_actual_arlen

      this.debug($sformatf("[COMPARE_HOST_DATA] dma_id=%0d, cnt_ar=%0d, cnt_bl=%0d, strb.size=%0d, expected_ar_len=%0d",
          DutParamDmaId_t'(cur_dma_id), cnt_ar, cnt_bl, host_expected.wstrb.size(), expected_ar_len));
    end:expected_host_qsize
    this.sb_flag.flag_h2c_hostData = YES;
  end

endtask:hostDataChecker



task vdmatb_mm_h2c_sb::cardDataChecker();

  T_TRANS4 actual, expected;

  Addr_t expected_addr;
  int cnt_aw = 0;
  int cnt_bl = 0;

  T_TRANS3 found;
  expected = T_TRANS4::type_id::create();


  forever begin
    if( this.q_expected_card_data.size() == 0 ) wait(this.q_expected_card_data.size()>0);
    if( this.q_actual_card_data.size() == 0 ) wait(this.q_actual_card_data.size()>0);

    this.debug($sformatf("[COMPARE_CARD_DATA]"));

    if(this.q_actual_card_data.size() > 0) begin:compare_card_data
      this.sb_flag.flag_cardData = NO;

      cnt_aw ++;
      cnt_bl = 0;

      actual = this.q_actual_card_data.pop_front();
      this.mm_sb_cov_colctr.sampleCardAwLen(actual.awlen);

      if(expected.wstrb.size() == 0) begin
        this.debug($sformatf("[COMPARE_CARD_PREPARE] expected.wstrb.size() == 0"));
        expected = this.q_expected_card_data.pop_front();
        expected_addr = DutParamCardAddr_t'(expected.waddr.pop_front());
      end

      if(this.cardDataCheck_expected_flag != NO) begin
        this.debug($sformatf("[COMPARE_CARD_PREPARE] cardDataCheck_expected_flag != NO"));
        expected = this.q_expected_card_data.pop_front();
      end

      this.debug($sformatf("[COMPARE_CARD_DATA_EXPECTED] dma_id=%0d, data.szie=%0d, wstrb.size=%0d, waddr.size=%0d",
          DutParamDmaId_t'(expected.dma_id), expected.wdata.size(), expected.wstrb.size(), expected.waddr.size()));


      begin:AXIChecker
        if( checkItemsByType#(DutParamCardAddr_t)::compareItem("H2C_SB_AWADDR", "awaddr", DutParamDmaId_t'(expected.dma_id), DutParamCardAddr_t'(actual.awaddr), DutParamCardAddr_t'(expected_addr)))
          this.error("COMPARE_AWADDR_ERROR", $sformatf("(actual/expected) awaddr=0x%0h/0x%0h, expected.waddr.size=%0d", DutParamCardAddr_t'(actual.awaddr), DutParamCardAddr_t'(expected_addr), expected.waddr.size()));

        if( checkItems#(16)::compareItem("H2C_SB_AWUSER", "awuser", DutParamDmaId_t'(expected.dma_id), actual.awuser, expected.awuser, 0) )
          this.error("COMPARE_AWUSER_ERROR", $sformatf("(actual/expected) awuser=%0d/%0d", actual.awuser, expected.awuser));

        if( checkItems#(1)::compareItem("H2C_SB_AWID", "awid", DutParamDmaId_t'(expected.dma_id), actual.awid, expected.awid, 0) )
          this.error("COMPARE_AWID_ERROR", $sformatf("(actual/expected) awid=0x%0h/0x%0h", actual.awid, expected.awid));

        if( checkItems#(4)::compareItem("H2C_SB_AWCACHE", "awcache", DutParamDmaId_t'(expected.dma_id), actual.awcache, expected.awcache) )
          this.error("COMPARE_AWCACHE_ERROR", $sformatf("(actual/expected) awcache=0x%0h/0x%0h", actual.awcache, expected.awcache));

        if( checkItems#(2)::compareItem("H2C_SB_AWBURST", "awburst", DutParamDmaId_t'(expected.dma_id), actual.awburst, expected.awburst, 0) )
          this.error("COMPARE_AWBURST_ERROR", $sformatf("(actual/expected) awburst=%0d/%0d", actual.awburst, expected.awburst));
      end:AXIChecker

      for(int i=0; i<actual.awlen+1; i++) begin
        CData_t actual_data, expected_data;
        CStrb_t actual_wstrb, expected_wstrb;

        cnt_bl ++;

        actual_data    = actual.wdata.pop_front();
        actual_wstrb   = actual.wstrb.pop_front();
        expected_data  = expected.wdata.pop_front();
        expected_wstrb = expected.wstrb.pop_front();
        expected_addr  = DutParamCardAddr_t'(expected.waddr.pop_front());


        this.mm_sb_cov_colctr.sampleCardWstrb(actual_wstrb);

        if( checkItems#(CARD_DATA_BYTE_WIDTH)::compareItem("H2C_SB_WSTRB", "WSTRB", DutParamDmaId_t'(expected.dma_id), actual_wstrb, expected_wstrb, 0) )
          this.error("COMPARE_WSTRB_ERROR", $sformatf("PKT#%0d: (actual/expected) wstrb=%0h/%0h", DutParamDmaId_t'(expected.dma_id), actual_wstrb, expected_wstrb));

        if( checkItems#(CARD_DATA_WIDTH)::compareItemWithStrb("H2C_SB_CARD_DATA", "CARD_DATA", DutParamDmaId_t'(expected.dma_id), actual_data, expected_data, expected_wstrb, 0) )
          this.error("COMPARE_CARD_DATA_ERROR", $sformatf("PKT#%0d: actual_data=%0h, expected_data=%0h", DutParamDmaId_t'(expected.dma_id), actual_data, expected_data));
//        this.debug($sformatf("[COMPARE_CARD_DATA_CHECK] PKT#%0d: actual_data=%0h, expected_data=%0h", DutParamDmaId_t'(expected.dma_id), actual_data, expected_data));

        this.debug($sformatf("%0d, %0d:: wstrb : actual %0h, expected %0h", cnt_aw, cnt_bl, actual_wstrb, expected_wstrb));
      end

      this.debug($sformatf("[COMPARE_CARD_DATA_COMPLETED] PKT#%0d: (actual/expected) awaddr=0x%0h/0x%0h, awlen=%0d/%0d",
          DutParamDmaId_t'(expected.dma_id), DutParamCardAddr_t'(actual.awaddr), DutParamCardAddr_t'(expected.awaddr), actual.awlen, expected.awlen));

      if(expected.wstrb.size == 0 && expected.waddr.size == 0 && expected.wdata.size == 0) begin
        this.cardDataCheck_expected_flag = NO;
      end
      if(expected.wstrb.size != 0 || expected.waddr.size != 0 || expected.wdata.size != 0) begin
        this.cardDataCheck_expected_flag = YES;
        this.q_expected_card_data.push_front(expected);
      end

    end:compare_card_data
    this.sb_flag.flag_cardData = YES;
  end // END forever
endtask:cardDataChecker




// ----------- Back-up origin-code
// TODO : remove codes in comment out

// KTSB-10 : Generate expected Host AR request in H2C operation
function void vdmatb_mm_h2c_sb::calculateHostExpected(T_TRANS data);
  static int num_created = 0;
  T_TRANS                    axiData;
  T_TRANS2                   currAxiItem;
  Len_t                      DataLen;
  Len_t                      pureTotalBurst;
  int                        maxBurstLen;
  int                        currBurstLen;
  int                        remainBurstLen;
  Len_t                      remainDataLen;
  HStrb_t                    strb;
  Addr_t                     raddr;
  Addr_t                     raddrNext;
  Addr_t                     currArAddr;
  Addr_t                     nextArAddr;
  Addr_t                     endArAddr;

  currAxiItem = T_TRANS2::type_id::create();

  DataLen            = data.desc.len;
  maxBurstLen        = data.desc.axi_max_len;
  currArAddr         = DutParamHostAddr_t'(data.desc.src_addr);
  endArAddr          = DutParamHostAddr_t'(data.desc.src_addr) + data.desc.len;

  remainDataLen      = DataLen;
  pureTotalBurst     = getTotalHostBurst(data.desc);

  this.debug($sformatf("[H2C_SB_CALCULATE_HOST_EXPECTED_1] num=%0d: src_addr = %0h max_len = %0d, len = %0d, len/64= %0d ", data.desc.dma_id, data.desc.src_addr, data.desc.axi_max_len, data.desc.len, data.desc.len/64));
  this.debug($sformatf("[H2C_SB_CALCULATE_HOST_EXPECTED_2] src_addr = %0h max_len = %0h, len = %0h", data.desc.src_addr, data.desc.axi_max_len, data.desc.len));
  if (data.desc.axi_max_len >= (AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH))
    maxBurstLen = AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH;

  num_created++;
  currBurstLen   = maxBurstLen;
  nextArAddr     = calculateNextHostAddr(DutParamHostAddr_t'(currArAddr), maxBurstLen, DutParamHostAddr_t'(endArAddr));
  currBurstLen   = updateCurrHostBurstLen(DutParamHostAddr_t'(currArAddr), DutParamHostAddr_t'(nextArAddr));

  currAxiItem.byteLen  =  data.desc.len;
  currAxiItem.arvalid  =  1'b1;
  currAxiItem.arready  =  1'b1;
  currAxiItem.arid     =  0;
  currAxiItem.araddr   =  DutParamHostAddr_t'(currArAddr);
  currAxiItem.arcache  =  2;
  currAxiItem.aruser   =  {data.desc.fnc_id, data.desc.str_id};
  currAxiItem.arburst  =  1;
  currAxiItem.arlen    =  pureTotalBurst;
  currAxiItem.dma_id   =  DutParamDmaId_t'(data.desc.dma_id);

  this.debug($sformatf("[H2C_SB_CALCULATE_HOST_EXPECTED_3] remainData = %0d, currArAddr = %0h pureBL %0d, currBurstLen = %0d, nextArAddr = %0h", remainDataLen, DutParamHostAddr_t'(currArAddr), pureTotalBurst, currBurstLen, DutParamHostAddr_t'(nextArAddr)));

  raddr =  DutParamHostAddr_t'(currArAddr);

  while (remainDataLen) begin:while_begin_end
    for (int i = 0; i < pureTotalBurst; i ++) begin:pureTotalBurst
      if (DataLen == remainDataLen) begin
        if (DataLen < HOST_DATA_BYTE_WIDTH) begin
          strb = (this.max_host_wstrb >> (HOST_DATA_BYTE_WIDTH-DataLen));
          strb = (strb << DutParamHostAddr_t'(data.desc.src_addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0]));
        end else begin
          strb = (this.max_host_wstrb << DutParamHostAddr_t'(data.desc.src_addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0]));
        end
      end // first burst
      else if (remainDataLen >= HOST_DATA_BYTE_WIDTH) begin
        strb = this.max_host_wstrb;
      end // middle of bursts
      else if ((remainDataLen > 0) && (remainDataLen < HOST_DATA_BYTE_WIDTH)) begin
        strb = ~(this.max_host_wstrb << remainDataLen);
      end // last burst
      remainDataLen = remainDataLen - checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(strb);
      raddrNext = DutParamHostAddr_t'(raddr) + checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(strb);

      currAxiItem.wstrb.push_back(strb);
      currAxiItem.raddr.push_back(DutParamHostAddr_t'(raddr));
      this.debug($sformatf("[H2C_SB_CALCULATE_HOST_EXPECTED_4] raddr = %0h, strb = %0h, strb.size = %0d, remainDataLen = %0h", DutParamHostAddr_t'(raddr), strb, currAxiItem.wstrb.size(), remainDataLen));
      if (remainDataLen == 0)  break;
      raddr = DutParamHostAddr_t'(raddrNext);
    end:pureTotalBurst

    this.debug($sformatf("[H2C_SB_CALCULATE_HOST_EXPECTED_GEN] id = %d, araddr = %0h, arlen = %0d, strb.size = %0d, remainDataLen = %0h", DutParamDmaId_t'(currAxiItem.dma_id), DutParamHostAddr_t'(currAxiItem.araddr), currAxiItem.arlen, currAxiItem.wstrb.size(), remainDataLen));
    this.q_expected_host_data.push_back(currAxiItem);
  end:while_begin_end
endfunction:calculateHostExpected



// KTSB-10 : Generate expected Card AW request in H2C operation
function void vdmatb_mm_h2c_sb::calculateCardExpected(T_TRANS data);
  static int num_created = 0;
  T_TRANS                    axiData;
  T_TRANS4                   currAxiItem;
  Len_t                      DataLen;
  Len_t                      pureTotalBurst;
  int                        maxBurstLen;
  int                        currBurstLen;
  int                        remainBurstLen;
  Len_t                      remainDataLen;
  CStrb_t                    strb;
  Addr_t                     waddr;
  Addr_t                     waddrNext;
  Addr_t                     currAwAddr;
  Addr_t                     nextAwAddr;
  Addr_t                     endAwAddr;

  currAxiItem = T_TRANS4::type_id::create();

  DataLen            = data.desc.len;
  currAwAddr         = DutParamCardAddr_t'(data.desc.dst_addr);
  endAwAddr          = DutParamCardAddr_t'(data.desc.dst_addr) + data.desc.len;

  remainDataLen      = DataLen;
  pureTotalBurst     = getTotalCardBurst(data.desc);

  this.debug($sformatf("[H2C_SB_CALCULATE_CARD_EXPECTED] num=%0d: dst_addr = %0h max_len = %0d, len = %0d, len/64= %0d ", data.desc.dma_id, data.desc.dst_addr, data.desc.axi_max_len, data.desc.len, data.desc.len/64));
  this.debug($sformatf("[H2C_SB_CALCULATE_CARD_EXPECTED] dst_addr = %0h max_len = %0h, len = %0h", data.desc.dst_addr, data.desc.axi_max_len, data.desc.len));
  
  maxBurstLen = AXI_4K_BOUNDARY / CARD_DATA_BYTE_WIDTH;
  
  if(maxBurstLen >= 256) maxBurstLen = 256;

  num_created++;
  currBurstLen   = maxBurstLen;
  nextAwAddr     = calculateNextCardAddr(DutParamCardAddr_t'(currAwAddr), maxBurstLen, DutParamCardAddr_t'(endAwAddr));
  currBurstLen   = updateCurrCardBurstLen(DutParamCardAddr_t'(currAwAddr), DutParamCardAddr_t'(nextAwAddr));

  currAxiItem.byteLen  =  data.desc.len;
  currAxiItem.awvalid  =  1'b1;
  currAxiItem.awready  =  1'b1;
  currAxiItem.awid     =  0;
  currAxiItem.awaddr   =  DutParamCardAddr_t'(currAwAddr);
  currAxiItem.awcache  =  2;
  currAxiItem.awuser   =  DutParamDmaId_t'(data.desc.dma_id);
  currAxiItem.awburst  =  1;
  currAxiItem.awlen    =  pureTotalBurst;
  currAxiItem.dma_id   =  DutParamDmaId_t'(data.desc.dma_id);

  this.debug($sformatf("[H2C_SB_CALCULATE_CARD_EXPECTED] remainDataLen = %0d, currAwAddr = %0h pureBL %0d, currBurstLen = %0d, nextAwAddr = %0h", remainDataLen, DutParamCardAddr_t'(currAwAddr), pureTotalBurst, currBurstLen, DutParamCardAddr_t'(nextAwAddr)));

  waddr =  DutParamCardAddr_t'(currAwAddr);

  while (remainDataLen) begin:while_begin_end
    for (int i = 0; i < pureTotalBurst; i ++) begin:pureTotalBurst
      if (DataLen == remainDataLen) begin
        if (DataLen < CARD_DATA_BYTE_WIDTH) begin

          strb = (this.max_card_wstrb >> (CARD_DATA_BYTE_WIDTH-DataLen));
          strb = (strb << DutParamCardAddr_t'(data.desc.dst_addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0]));
        end else begin
          strb = (this.max_card_wstrb << DutParamCardAddr_t'(data.desc.dst_addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0]));
        end
      end // first burst
      else if (remainDataLen >= CARD_DATA_BYTE_WIDTH) begin
        strb = this.max_card_wstrb;
      end // middle of bursts
      else if ((remainDataLen > 0) && (remainDataLen < CARD_DATA_BYTE_WIDTH)) begin
        strb = ~(this.max_card_wstrb << remainDataLen);
      end // last burst
      remainDataLen = remainDataLen - checkItems#(CARD_DATA_BYTE_WIDTH)::countOnes(strb);
      waddrNext = DutParamCardAddr_t'(waddr) + checkItems#(CARD_DATA_BYTE_WIDTH)::countOnes(strb);

      currAxiItem.wstrb.push_back(strb);
      currAxiItem.waddr.push_back(DutParamCardAddr_t'(waddr));
      this.debug($sformatf("[H2C_SB_CALCULATE_CARD_EXPECTED] waddr = %0h, strb = %0h, strb.size = %0d, remainDataLen = %0h", DutParamCardAddr_t'(waddr), strb, currAxiItem.wstrb.size(), remainDataLen));
      if (remainDataLen == 0)  begin
       
        break;
      end
      
      waddr = DutParamCardAddr_t'(waddrNext);
    end:pureTotalBurst

    this.debug($sformatf("[H2C_SB_CALCULATE_CARD_EXPECTED_GEN] id = %d, awaddr = %0h, awlen = %0d, strb.size = %0d, remainDataLen = %0h", DutParamDmaId_t'(currAxiItem.dma_id), DutParamCardAddr_t'(currAxiItem.awaddr), currAxiItem.awlen, currAxiItem.wstrb.size(), remainDataLen));
    this.q_expected_card_temp.push_back(currAxiItem);
  end:while_begin_end
endfunction:calculateCardExpected



`endif //__VDMATB_MM_H2C_SB_SVH__
