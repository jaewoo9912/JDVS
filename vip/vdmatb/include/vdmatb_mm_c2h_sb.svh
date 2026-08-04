`ifndef __VDMATB_MM_C2H_SB_SVH__
`define __VDMATB_MM_C2H_SB_SVH__

class vdmatb_mm_c2h_sb extends vdmatb_sb;

  int flt_count = 0;
  
  T_TRANS2 q_expected_host_temp[$];

  `uvm_component_utils(vdmatb_mm_c2h_sb)

  YesOrNo_t hostDataCheck_expected_flag = NO;


  function new (string name = "vdmatb_mm_c2h_sb", uvm_component parent);
    super.new(name, parent);
  endfunction


  // ---------------------------- uvm built-in
  extern virtual function void build_phase(uvm_phase phase);


  // ---------------------------- vdma_sb built-in
  extern virtual function DmaTransType_t getTransType();

  extern virtual function void post_registerNewPkt(T_TRANS3 trans, T_TRANS trans2);

  extern virtual function void genExpectedHostAwReq(T_TRANS3 trans, T_TRANS trans2);
  extern virtual function void genExpectedCardArReq(T_TRANS3 trans, T_TRANS trans2);

  extern virtual function void post_updateMstData(T_TRANS3 trans, T_TRANS trans2);
  extern virtual function void post_updateHostData(T_TRANS3 trans, T_TRANS2 trans2);
  extern virtual function void post_updateCardData(T_TRANS3 trans, T_TRANS4 trans2);

  extern virtual function void callbackReset();

  // ---------------------------- vdmatb_mm_c2h_sb built-in
  extern virtual task cardDataChecker();
  extern virtual task hostDataChecker();

  extern virtual function void   calculateHostExpected (T_TRANS data);
  extern virtual function void   calculateCardExpected (T_TRANS data);

  extern virtual function YesOrNo_t checkFaultOnHostData(T_TRANS3 trans, T_TRANS2 trans2);
  extern virtual function YesOrNo_t checkFaultOnCardData(T_TRANS3 trans, T_TRANS4 trans2);

  extern virtual function void sampleDesc(T_TRANS trans);

endclass:vdmatb_mm_c2h_sb


function void vdmatb_mm_c2h_sb::sampleDesc(T_TRANS trans);
  this.mm_sb_cov_colctr.sampleDesc(trans);
endfunction : sampleDesc


function void vdmatb_mm_c2h_sb::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction:build_phase


function DmaTransType_t vdmatb_mm_c2h_sb::getTransType();
  return(MM_C2H);
endfunction:getTransType


function void vdmatb_mm_c2h_sb::callbackReset();
  this.q_expected_host_temp.delete();
endfunction:callbackReset


// KTSB-8 : Generate expected Host AW request in C2H operation
function void vdmatb_mm_c2h_sb::post_registerNewPkt(T_TRANS3 trans, T_TRANS trans2);

  this.genExpectedCardArReq(trans, trans2);
  this.genExpectedHostAwReq(trans, trans2);

endfunction:post_registerNewPkt




// KTSB-9 : Generate expected Card AR request in C2H operation
function void vdmatb_mm_c2h_sb::genExpectedCardArReq(T_TRANS3 trans, T_TRANS trans2);
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
  Addr_t                    araddr;
  Addr_t                    pkt_addr;
  Addr_t                    next_araddr;
  Addr_t                    end_araddr;
  Addr_t                    raddr;
  Addr_t                    next_raddr;
  CStrb_t                   strb;


  // START ----------- Initialize variables with DESC information
  desc = trans2.desc;

  dma_id          = DutParamDmaId_t'(desc.dma_id);
  str_id          = desc.str_id;
  data_len        = desc.len;
  araddr          = DutParamCardAddr_t'(desc.src_addr);
  pkt_addr        = DutParamCardAddr_t'(desc.src_addr);

  end_araddr      = DutParamCardAddr_t'(araddr + data_len);
  remain_data_len = data_len;
  total_burst_len = getTotalCardBurst(desc);
  max_cburst_len = AXI_4K_BOUNDARY / CARD_DATA_BYTE_WIDTH;
  
  if(max_cburst_len >= 256) max_cburst_len = 256;

  this.debug($sformatf("[EXPECT_CARD_AR_1] PKT#%0d: src_addr=%0h, max_cburst_len=%0d, len_in_byte=%0d, len/64=%0d",
      DutParamDmaId_t'(desc.dma_id), DutParamCardAddr_t'(desc.src_addr), max_cburst_len, desc.len, desc.len/64));

  num_created++;
  cur_burst_len = max_cburst_len;
  next_araddr   = calculateNextCardAddr(DutParamCardAddr_t'(araddr), max_cburst_len, DutParamCardAddr_t'(end_araddr));
  this.debug($sformatf("[EXPECT_CARD_AR_1_1] PKT#%0d: araddr=%0h, end_araddr=%0h, nex_araddr=%0h", desc.dma_id, araddr, end_araddr, next_araddr));
  cur_burst_len = updateCurrCardBurstLen(DutParamCardAddr_t'(araddr), DutParamCardAddr_t'(next_araddr));
  raddr         = DutParamCardAddr_t'(araddr);
  // END ----------- Initialize variables with DESC information

  // START ----------- Generate Expected CARD_AR
  while(remain_data_len) begin:while_begin_end
    T_TRANS4 expected;
    expected = T_TRANS4::type_id::create();

    this.debug($sformatf("[EXPECT_CARD_AR_2] PKT#%0d: remain_data_len=%0d, araddr=%0h, cur_burst_len=%0d, next_araddr=%0h",
        DutParamDmaId_t'(desc.dma_id), remain_data_len, DutParamCardAddr_t'(araddr), cur_burst_len, DutParamCardAddr_t'(next_araddr)));

    expected.dma_id   =  DutParamDmaId_t'(desc.dma_id);
    expected.arvalid  =  1'b1;
    expected.arready  =  1'b1;
    expected.arid     =  0;
    expected.araddr   =  DutParamCardAddr_t'(araddr);
    expected.arcache  =  2;
    expected.aruser   =  DutParamDmaId_t'(desc.dma_id);
    expected.arburst  =  1;
    expected.arlen    =  cur_burst_len -1;
    expected.byteLen  =  desc.len;


    for(int i=0; i<cur_burst_len; i++) begin:card_data_loop

      // START ----------- Expected WSTRB
      // First Burst
      if( remain_data_len == data_len ) begin
        if(data_len < CARD_DATA_BYTE_WIDTH) begin
          strb = (this.max_card_wstrb >> (CARD_DATA_BYTE_WIDTH-data_len));
          strb = (strb << DutParamCardAddr_t'(desc.src_addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0]));
        end
        else begin
          strb = (this.max_card_wstrb << DutParamCardAddr_t'(desc.src_addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0]));
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
      next_raddr = DutParamCardAddr_t'(raddr) + checkItems#(CARD_DATA_BYTE_WIDTH)::countOnes(strb);

      expected.wstrb.push_back(strb);
      expected.raddr.push_back(DutParamCardAddr_t'(raddr));

      this.debug($sformatf("[EXPECT_CARD_AR_3] PKT#%0d: araddr=0x%0h, raddr=0x%0h, strb=%0h, num_of_data=%0d, wstrb.size=%0d, remain_data_len=%0d",
          DutParamDmaId_t'(expected.dma_id), DutParamCardAddr_t'(araddr), DutParamCardAddr_t'(raddr), strb, checkItems#(CARD_DATA_BYTE_WIDTH)::countOnes(strb), expected.wstrb.size(), remain_data_len));

      if( remain_data_len == 0 ) break;

      raddr = DutParamCardAddr_t'(next_raddr);

    end:card_data_loop


    this.debug($sformatf("[NEW_EXPECTED_CARD_AR] PKT#%0d: pkt_addr=0x%0h, araddr=0x%0h, aruser=%0d, arlen=%0d, size(num_data)=%0d",
        DutParamDmaId_t'(expected.dma_id), DutParamCardAddr_t'(pkt_addr), DutParamCardAddr_t'(expected.araddr), expected.aruser, expected.arlen, expected.wstrb.size()));
    this.q_expected_card_req.push_back(expected);

    this.debug($sformatf("[EXPECT_CARD_AR_4] araddr=0x%0h, next_araddr=0x%0h, raddr=0x%0h / cur_burst_len=%0d",
        DutParamCardAddr_t'(araddr), DutParamCardAddr_t'(next_araddr), DutParamCardAddr_t'(raddr), cur_burst_len));

    // Update with NEXT
    araddr = DutParamCardAddr_t'(raddr); //next_araddr;
    next_araddr = calculateNextCardAddr(DutParamCardAddr_t'(araddr), max_cburst_len, DutParamCardAddr_t'(end_araddr));
    next_burst_len = updateCurrCardBurstLen(DutParamCardAddr_t'(araddr), DutParamCardAddr_t'(next_araddr));
    cur_burst_len = next_burst_len;

  end:while_begin_end

  this.calculateCardExpected(trans2);
endfunction:genExpectedCardArReq

// KTSB-9 : Generate expected Host AW request in C2h operation
function void vdmatb_mm_c2h_sb::genExpectedHostAwReq(T_TRANS3 trans, T_TRANS trans2);

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
  Addr_t                    awaddr;
  Addr_t                    pkt_addr;
  Addr_t                    next_awaddr;
  Addr_t                    end_awaddr;
  Addr_t                    waddr;
  Addr_t                    next_waddr;
  HStrb_t                   strb;


  // START ----------- Initialize variables with DESC information
  desc = trans2.desc;

  dma_id          = DutParamDmaId_t'(desc.dma_id);
  str_id          = desc.str_id;
  data_len        = desc.len;
  max_hburst_len  = int'(desc.axi_max_len);
  awaddr          = DutParamHostAddr_t'(desc.dst_addr);
  pkt_addr        = DutParamHostAddr_t'(desc.dst_addr);

  end_awaddr      = DutParamHostAddr_t'(awaddr) + data_len;
  remain_data_len = data_len;
  total_burst_len = getTotalHostBurst(desc);
  
  if( (desc.axi_max_len > (AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH)) || (desc.axi_max_len==0) )
    max_hburst_len = AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH;

  this.debug($sformatf("[EXPECT_HOST_AW_1] PKT#%0d: dst_addr=%0h, max_hburst_len=%0d, len_in_byte=%0d, len/%0d=%0d",
      DutParamDmaId_t'(desc.dma_id), DutParamHostAddr_t'(desc.dst_addr), desc.axi_max_len, desc.len, HOST_DATA_BYTE_WIDTH, (desc.len/HOST_DATA_BYTE_WIDTH)));

  num_created++;
  cur_burst_len = max_hburst_len;
  next_awaddr   = calculateNextHostAddr(DutParamHostAddr_t'(awaddr), max_hburst_len, DutParamHostAddr_t'(end_awaddr));
  cur_burst_len = updateCurrHostBurstLen(DutParamHostAddr_t'(awaddr), DutParamHostAddr_t'(next_awaddr));
  waddr         = DutParamHostAddr_t'(awaddr);
  // END ----------- Initialize variables with DESC information

  // START ----------- Generate Expected HOST_AR
  while(remain_data_len) begin:while_begin_end
    T_TRANS2 expected;
    expected = T_TRANS2::type_id::create();

    this.debug($sformatf("[EXPECT_HOST_AW_2] PKT#%0d: remain_data_len=%0d, awaddr=%0h, cur_burst_len=%0d, next_awaddr=%0h",
        DutParamDmaId_t'(desc.dma_id), remain_data_len, DutParamHostAddr_t'(awaddr), cur_burst_len, DutParamHostAddr_t'(next_awaddr)));

    expected.dma_id   =  DutParamDmaId_t'(desc.dma_id);
    expected.desc.dma_id   =  DutParamDmaId_t'(desc.dma_id);
    expected.desc.str_id   =  desc.str_id;
    expected.awvalid  =  1'b1;
    expected.awready  =  1'b1;
    expected.awid     =  0;
    expected.awaddr   =  DutParamHostAddr_t'(awaddr);
    expected.pkt_addr =  DutParamHostAddr_t'(desc.dst_addr);
    expected.awcache  =  2;
    expected.awuser   =  {desc.fnc_id, desc.str_id};
    expected.awburst  =  1;
    expected.awlen    =  cur_burst_len -1;
    expected.byteLen  =  desc.len;


    for(int i=0; i<cur_burst_len; i++) begin:host_data_loop

      // START ----------- Expected WSTRB
      // First Burst
      if( remain_data_len == data_len ) begin
        if(data_len < HOST_DATA_BYTE_WIDTH) begin
          strb = (this.max_host_wstrb >> (HOST_DATA_BYTE_WIDTH-data_len));
          strb = (strb << DutParamHostAddr_t'(desc.dst_addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0]));
        end
        else begin
          strb = (this.max_host_wstrb << DutParamHostAddr_t'(desc.dst_addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0]));
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
      next_waddr = DutParamHostAddr_t'(waddr) + checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(strb);

      expected.wstrb.push_back(strb);
      expected.waddr.push_back(DutParamHostAddr_t'(waddr));

      this.debug($sformatf("[EXPECT_HOST_AW_3] PKT#%0d: awaddr=0x%0h, waddr=0x%0h, strb=%0h, num_of_data=%0d, wstrb.size=%0d, remain_data_len=%0d",
          DutParamDmaId_t'(expected.dma_id), DutParamHostAddr_t'(awaddr), DutParamHostAddr_t'(waddr), strb, checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(strb), expected.wstrb.size(), remain_data_len));

      if( remain_data_len == 0 ) break;

      waddr = DutParamHostAddr_t'(next_waddr);

    end:host_data_loop


    this.debug($sformatf("[NEW_EXPECTED_HOST_AW] PKT#%0d: pkt_addr=0x%0h, awaddr=0x%0h, awuser=%0d, awlen=%0d, size(num_data)=%0d",
        DutParamDmaId_t'(expected.dma_id), DutParamHostAddr_t'(expected.pkt_addr), DutParamHostAddr_t'(expected.awaddr), expected.awuser, expected.awlen, expected.wstrb.size()));
    
    this.q_expected_host_req.push_back(expected);

    this.debug($sformatf("[EXPECT_HOST_AW_4] awaddr=0x%0h, next_awaddr=0x%0h, waddr=0x%0h / cur_burst_len=%0d",
        DutParamHostAddr_t'(awaddr), DutParamHostAddr_t'(next_awaddr), DutParamHostAddr_t'(waddr), cur_burst_len));

    // Update with NEXT
    awaddr = DutParamHostAddr_t'(waddr); //next_awaddr;
    next_awaddr = calculateNextHostAddr(DutParamHostAddr_t'(awaddr), max_hburst_len, DutParamHostAddr_t'(end_awaddr));
    next_burst_len = updateCurrHostBurstLen(DutParamHostAddr_t'(awaddr), DutParamHostAddr_t'(next_awaddr));
    cur_burst_len = next_burst_len;


  end:while_begin_end

  this.calculateHostExpected(trans2);

endfunction:genExpectedHostAwReq





// KTSB-26 : C2H post_updateHostData
function void vdmatb_mm_c2h_sb::post_updateHostData(T_TRANS3 trans, T_TRANS2 trans2);
  YesOrNo_t fault;

  fault = this.checkFaultOnHostData(trans, trans2);

endfunction:post_updateHostData



// KTSB-26 : C2H post_updateCardData
function void vdmatb_mm_c2h_sb::post_updateCardData(T_TRANS3 trans, T_TRANS4 trans2);
  YesOrNo_t fault;

  fault = this.checkFaultOnCardData(trans, trans2);

endfunction:post_updateCardData


/*
 * KTSB-21 : C2H post_updateCardData
 * calculate expected HOST_DATA from PKT_INFO and CARD_DATA
 */
function void vdmatb_mm_c2h_sb::post_updateMstData(T_TRANS3 trans, T_TRANS trans2);
endfunction:post_updateMstData



function YesOrNo_t vdmatb_mm_c2h_sb::checkFaultOnHostData(T_TRANS3 trans, T_TRANS2 trans2);
  YesOrNo_t      result = NO;
  Desc_t         desc;
  Fault_t        created_fault;
  Interrupt_t    created_fault_intr;
  CovWrongResp_t cov_host_b_wrong_resp;

  desc = trans.q_mst[0].desc;

  created_fault.dma_id = DutParamDmaId_t'(desc.dma_id);
  created_fault.str_id = desc.str_id;
  created_fault.axi_resp = 0;
  created_fault_intr.dma_id = DutParamDmaId_t'(desc.dma_id);
  created_fault_intr.fnc_id = desc.fnc_id;

  // KTSB-27 : Check Fault code within BRESP
  if( trans2.bresp != 0 ) begin
    created_fault.code = HOST_B_WRONG_RESP;
    created_fault.axi_resp = trans2.bresp;
    result = YES;
    
    cov_host_b_wrong_resp.dma_id = DutParamDmaId_t'(desc.dma_id);
    cov_host_b_wrong_resp.resp   = trans2.bresp;
    this.q_actual_fault_host_b_wrong_resp.push_back(cov_host_b_wrong_resp);
  end


  if( result == YES ) begin
    created_fault_intr.vec_id = 'h1f;
    created_fault_intr.fnc_id = 'hff;
    this.debug($sformatf("[EXPECT_FAULT_ON_BRESP] BRESP has fault case w/ dma_id=%0d, fault_code=%0d, str_id=%0d, fnc_id=%0d",
        DutParamDmaId_t'(created_fault.dma_id), created_fault.code, created_fault.str_id, created_fault_intr.fnc_id));

    this.q_expected_host_fault.push_back(created_fault);
    this.q_expected_host_fault_intr.push_back(created_fault_intr);
  end

  return(result);
endfunction:checkFaultOnHostData




function YesOrNo_t vdmatb_mm_c2h_sb::checkFaultOnCardData(T_TRANS3 trans, T_TRANS4 trans2);

  YesOrNo_t result        = NO;
  YesOrNo_t result_all    = NO;
  YesOrNo_t result_plast  = NO;
  YesOrNo_t result_rresp  = NO;
  YesOrNo_t result_sgl    = NO;

  Desc_t desc;

  logic q_rlast[$];
  logic [`SVT_AXI_RESP_WIDTH-1:0] q_rresp[$];

  Fault_t created_fault;
  Interrupt_t created_fault_intr;

  int  cnt_rlast = 0;
  int  cnt_rresp = 0;

  q_rlast = trans2.q_rlast;
  q_rresp = trans2.q_rresp;

  desc = trans.q_mst[0].desc;

  created_fault.dma_id = DutParamDmaId_t'(desc.dma_id);
  created_fault.str_id = desc.str_id;
  created_fault.axi_resp = 0;
  created_fault_intr.dma_id = DutParamDmaId_t'(desc.dma_id);
  created_fault_intr.fnc_id = desc.fnc_id;

  this.debug($sformatf("result: %0h, aruser : %0h, rdata_size : %0d, rlast_size : %0d, dma_id : %0h, str_id : %0h, fault_code : %0h", result, trans2.aruser, trans2.rdata.size(), q_rlast.size(), DutParamDmaId_t'(desc.dma_id), created_fault.str_id, created_fault.code));

  // All Data transaction(beats) check : CARD_R_PREMATURE_LAST, CARD_R_WRONG_RESP
  foreach( q_rlast[i] ) begin:Q_ALL_CHK
    // KTSB- : Fault Code : CARD_R_PREMATURE_LAST
    this.debug($sformatf("[PREMATURE_LAST_CHECK] result: %0h, rlast : %0h, q_rlast_size : %0d, cnt_rlast : 0%d", result, q_rlast[i], q_rlast.size(), cnt_rlast));
    if( q_rlast[i] == 1 ) begin
      if( i != (q_rlast.size()-1) ) begin
        created_fault.code = CARD_R_PREMATURE_LAST;
        result_plast = YES;
        this.debug($sformatf("[FAIL_CARD_R_PREMATURE_LAST] result: %0h, rlast : %0d, fault_code : %0h, failed_rlast_in_q : %0d", result, q_rlast[i], created_fault.code, i));
      end
    end
    //end

    // KTSB- : CARD_R_WRONG_RESP - Check Fault code within RRESP
    if( q_rresp[i] != 0 ) begin
      CovWrongResp_t cov_card_r_wrong_resp;
      
      created_fault.axi_resp = q_rresp[i];
      created_fault.code = CARD_R_WRONG_RESP;
      result_rresp = YES;
      this.debug($sformatf("[FAIL_HOST_R_WRONG_RESP] result: %0h, rresp : %0h, fault_code : %0h, rresp : %0h", result, created_fault.axi_resp, created_fault.code, q_rresp[i]));
      
      cov_card_r_wrong_resp.dma_id = DutParamDmaId_t'(desc.dma_id);
      cov_card_r_wrong_resp.resp   = created_fault.axi_resp;
      this.q_actual_fault_card_r_wrong_resp.push_back(cov_card_r_wrong_resp);
    end

    if((result_plast == YES) | (result_rresp == YES)) result_all = YES;
    else result_all = NO;

    if( result_all == YES ) begin

      this.flt_count++;

      created_fault_intr.vec_id = 'h1f;
      created_fault_intr.fnc_id = 'hff;

      this.q_expected_card_fault.push_back(created_fault);
      this.q_expected_card_fault_intr.push_back(created_fault_intr);

      this.debug($sformatf("[EXPECT_FAULT_ON_CARD_DATA] Card Data has fault case w/ dma_id=%0d, fault_code=%0d, str_id=%0h, fnc_id=%0h, q_flt_size=%0d, q_flt_intr_size=%0d",
          DutParamDmaId_t'(created_fault.dma_id), created_fault.code, created_fault.str_id, created_fault_intr.fnc_id,q_expected_card_fault.size(),q_expected_card_fault_intr.size()));
    end

    result_plast = NO;
    result_rresp = NO;

  end:Q_ALL_CHK


  // Single transaction check : CARD_R_NO_LAST
  if( result_all == NO ) begin:Q_SINGLE_CHK
    // KTSB- : Fault Code : CARD_R_NO_LAST
    if( q_rlast[$] == 0 ) begin
      created_fault.code = CARD_R_NO_LAST;
      result_sgl = YES;
      this.debug($sformatf("[FAIL_CARD_R_NO_LAST] result: %0h,  q_rlast_size : %0d, cnt_rlast : %0d, fault_code : %0h", result, q_rlast.size(), cnt_rlast, created_fault.code));
    end

    if( result_sgl == YES ) begin

      this.flt_count++;

      created_fault_intr.vec_id = 'h1f;
      created_fault_intr.fnc_id = 'hff;

      this.q_expected_card_fault.push_back(created_fault);
      this.q_expected_card_fault_intr.push_back(created_fault_intr);

      this.debug($sformatf("[EXPECT_FAULT_ON_CARD_DATA] Card Data has fault case w/ dma_id=%0d, fault_code=%0d, str_id=%0h, fnc_id=%0h, q_flt_size=%0d, q_flt_intr_size=%0d",
          DutParamDmaId_t'(created_fault.dma_id), created_fault.code, created_fault.str_id, created_fault_intr.fnc_id,q_expected_card_fault.size(),q_expected_card_fault_intr.size()));
    end

  end:Q_SINGLE_CHK


  if((result_all == YES) | (result_sgl == YES)) result = YES;

  this.debug($sformatf("[EXPECT_FAULT_STAT] flt_count=%0d", this.flt_count));

  return(result);

endfunction:checkFaultOnCardData




task vdmatb_mm_c2h_sb::cardDataChecker();
  T_TRANS4      actual, card_expected;

  Addr_t        card_expected_addr;
  CStrb_t       card_expected_wstrb;
  bit           gathering = 1'b0;
  int           cnt_ar = 0, cnt_bl = 0;
  int           expected_byte;
  int           expected_ar_len = 0;
  int           byte_cnt = 0;
  DmaId_t       cur_dma_id = 0;

  T_TRANS2      host_expected;

  HData_t       host_expected_data;
  CData_t       card_expected_data;
  CData_t       actual_data, actual_data_shift;

  Byte_t        tmp_data[$];
  
  YesOrNo_t     isExisted = NO;
  int           idx_deleted;

  card_expected = T_TRANS4::type_id::create();
  host_expected = T_TRANS2::type_id::create();

  forever begin:forever_end
    this.debug("C2H_CARD_CHECKER_START");
    wait(this.q_expected_card_data.size() > 0);
    this.sb_flag.flag_cardData = NO;

    if(this.q_expected_card_data.size() > 0) begin:expected_card_qsize
      cnt_ar++;
      cnt_bl=0;

      wait(this.q_actual_card_data.size() > 0 );
      actual = this.q_actual_card_data.pop_front();
      this.mm_sb_cov_colctr.sampleCardArLen(actual.arlen);

      if(card_expected.wstrb.size() == 0) begin:update_expected_item
        card_expected        = this.q_expected_card_data.pop_front();
        this.debug($sformatf("[C2H_SB_CALCULATE_CARD_EXPECTED_POP] id = %d, araddr = %0h, arlen = %0d, strb.size = %0d", DutParamDmaId_t'(card_expected.dma_id), DutParamCardAddr_t'(card_expected.araddr), card_expected.arlen, card_expected.wstrb.size()));
        card_expected_addr   = DutParamCardAddr_t'(card_expected.araddr);
        expected_ar_len = card_expected.wstrb.size();
        expected_byte   = card_expected.byteLen;
        cur_dma_id      = DutParamDmaId_t'(card_expected.dma_id);
      end:update_expected_item
      this.debug($sformatf("[COMPARE_CARD_DATA_EXPECTED] dma_id=%0d, len=%0d/%0d",
          DutParamDmaId_t'(card_expected.dma_id), expected_ar_len, card_expected.arlen));
      this.debug($sformatf("[COMPARE_CARD_DATA_ACTUAL ] dma_id=%0d, actual.addr=%0h, acutal.arBL=%0d, expected_ar_len=%0d, wstrb.size=%0d",
          DutParamDmaId_t'(actual.dma_id), DutParamCardAddr_t'(actual.araddr), actual.arlen, expected_ar_len, card_expected.wstrb.size()));

      if(card_expected.raddr.size() > 0) begin:update_expected_addr
        card_expected_addr = DutParamCardAddr_t'(card_expected.raddr.pop_front());
      end:update_expected_addr

      begin:AXIChecker
        if( checkItems#(MAX_ADDR_WIDTH)::compareItem("C2H_SB_ARADDR", "araddr", DutParamDmaId_t'(cur_dma_id), DutParamCardAddr_t'(actual.araddr), DutParamCardAddr_t'(card_expected_addr), 0) )
          this.error("COMPARE_ARADDR_ERROR", $sformatf("(actual/expected) araddr=0x%0h/0x%0h", DutParamCardAddr_t'(actual.araddr), DutParamCardAddr_t'(card_expected_addr)));

        if( checkItems#(16)::compareItem("C2H_SB_ARUSER", "aruser", DutParamDmaId_t'(cur_dma_id), actual.aruser, card_expected.aruser, 0) )
          this.error("COMPARE_ARUSER_ERROR", $sformatf("(actual/expected) aruser=%0d/%0d", actual.aruser, card_expected.aruser));

        if( checkItems#(1)::compareItem("C2H_SB_ARID", "arid", DutParamDmaId_t'(cur_dma_id), actual.arid, card_expected.arid, 0) )
          this.error("COMPARE_ARID_ERROR", $sformatf("(actual/expected) arid=0x%0h/0x%0h", actual.arid, card_expected.arid));

        if( checkItems#( 4)::compareItem("C2H_SB_ARCACHE", "arache", DutParamDmaId_t'(cur_dma_id), actual.arcache, card_expected.arcache) )
          this.error("COMPARE_ARCACHE_ERROR", $sformatf("(actual/expected) arcache=0x%0h/0x%0h", actual.arcache, card_expected.arcache));

        if( checkItems#( 2)::compareItem("C2H_SB_ARBURST", "arburst", DutParamDmaId_t'(cur_dma_id), actual.arburst, card_expected.arburst, 0) )
          this.error("COMPARE_ARBURST_ERROR", $sformatf("(actual/expected) arburst=%0d/%0d", actual.arburst, card_expected.arburst));
      end:AXIChecker

      for(int i=0; i<actual.arlen+1; i++) begin:for_actual_arlen
        cnt_bl++;
        expected_ar_len--;

        this.debug($sformatf("[COMPARE_CARD_DATA_ACTUAL] dma_id=%0d, expect_ar_len=%0d, strb.size=%0d, actual.araddr=0x%0h, actual.arlen=%0d", DutParamDmaId_t'(cur_dma_id), expected_ar_len, card_expected.wstrb.size(), DutParamCardAddr_t'(actual.araddr), actual.arlen+1));

        if( (i<actual.arlen) && (card_expected.raddr.size()>0) ) card_expected_addr = DutParamCardAddr_t'(card_expected.raddr.pop_front());
        if( card_expected.wstrb.size() > 0 ) begin
          card_expected_wstrb = card_expected.wstrb.pop_front();
        end
        
        actual_data = actual.rdata.pop_front();
        actual_data_shift = actual_data;

        this.debug($sformatf("[COMPARE_CARD_DATA_ACTUAL_RDATA_2] dma_id=%0d, gathering=%0d, sop/eop=%0d/%0d, actual_araddr=0x%h, expected_wstrb=0x%0h, actual.rdata.size=%0d, actual_data=0x%0h, byte_cnt=%0d",
            DutParamDmaId_t'(cur_dma_id), gathering, card_expected.sop, card_expected.eop, DutParamHostAddr_t'(actual.araddr), card_expected_wstrb, actual.rdata.size(), actual_data, byte_cnt));

        for(int t=0; t<CARD_DATA_BYTE_WIDTH; t++) begin:for_byte
          if(card_expected_wstrb[t]) begin:if_wstrb
            tmp_data.push_back(actual_data_shift[7:0]);
          end:if_wstrb

          actual_data_shift = actual_data_shift >> 8;
          expected_byte = expected_byte - card_expected_wstrb[t];
        end

        this.debug($sformatf("[KITEC] expected_byte = %0d", expected_byte));

        if(expected_byte==0) begin
          int q_size;
          
          if(this.q_expected_host_temp.size() == 0) 
            wait(this.q_expected_host_temp.size() > 0);
          
          q_size = this.q_expected_host_temp.size();
          
          for(int j = 0; j < q_size; j++) begin
            if (this.q_expected_host_temp[0].dma_id == cur_dma_id) begin
              host_expected = this.q_expected_host_temp.pop_front();
              foreach(host_expected.wstrb[k]) begin
                host_expected_data = 0;
                
                for(int l=0; l<HOST_DATA_BYTE_WIDTH; l++) begin
                  if(host_expected.wstrb[k][l] == 0) begin
                    host_expected_data[HOST_DATA_WIDTH-1:HOST_DATA_WIDTH-8] = 0;
                  end 
                  else begin
                    host_expected_data[HOST_DATA_WIDTH-1:HOST_DATA_WIDTH-8] = tmp_data.pop_front();
                  end
                 
                  if(l < HOST_DATA_BYTE_WIDTH-1) begin
                    host_expected_data = host_expected_data >> 8;
                  end
                end
                
                host_expected.wdata.push_back(host_expected_data);
                
              end
              this.q_expected_host_data.push_back(host_expected);
            end
          end
         
        end
      end:for_actual_arlen

      this.debug($sformatf("[COMPARE_CARD_DATA] dma_id=%0d, cnt_ar=%0d, cnt_bl=%0d, strb.size=%0d, expected_ar_len=%0d",
          DutParamDmaId_t'(cur_dma_id), cnt_ar, cnt_bl, card_expected.wstrb.size(), expected_ar_len));
    end:expected_card_qsize
    
    this.sb_flag.flag_cardData = YES;
  end:forever_end

endtask:cardDataChecker


/*
 * Compare Host Data
 * TODO : move T_TRANS2 expected into function local
 */
task vdmatb_mm_c2h_sb::hostDataChecker();
  T_TRANS2 actual, expected;

  Addr_t expected_addr;
  int cnt_aw = 0;
  int cnt_bl = 0;

  T_TRANS3 found;
  expected = T_TRANS2::type_id::create();

  forever begin
    if( this.q_expected_host_data.size() == 0 ) wait(this.q_expected_host_data.size()>0);
    if( this.q_actual_host_data.size() == 0 ) wait(this.q_actual_host_data.size()>0);

    this.debug($sformatf("[COMPARE_HOST_DATA]"));

    if(this.q_actual_host_data.size() > 0) begin:compare_host_data
      this.sb_flag.flag_c2h_hostData = NO;

      cnt_aw ++;
      cnt_bl = 0;

      actual = this.q_actual_host_data.pop_front();
      this.mm_sb_cov_colctr.sampleHostAwLen(actual.awlen);

      if(expected.wstrb.size() == 0) begin
        expected = this.q_expected_host_data.pop_front();
        expected_addr = DutParamHostAddr_t'(expected.waddr.pop_front());
      end

      if(this.hostDataCheck_expected_flag != NO) begin
        expected = this.q_expected_host_data.pop_front();
      end

      this.debug($sformatf("[COMPARE_HOST_DATA_EXPECTED] dma_id=%0d, data.szie=%0d, wstrb.size=%0d, waddr.size=%0d",
          DutParamDmaId_t'(expected.dma_id), expected.wdata.size(), expected.wstrb.size(), expected.waddr.size()));

      begin:AXIChecker
        if( checkItemsByType#(DutParamCardAddr_t)::compareItem("C2H_SB_AWADDR", "awaddr", DutParamDmaId_t'(expected.dma_id), DutParamCardAddr_t'(actual.awaddr), DutParamCardAddr_t'(expected_addr)))
          this.error("COMPARE_AWADDR_ERROR", $sformatf("(actual/expected) awaddr=0x%0h/0x%0h, expected.waddr.size=%0d", DutParamCardAddr_t'(actual.awaddr), DutParamCardAddr_t'(expected_addr), expected.waddr.size()));

        if( checkItems#(16)::compareItem("C2H_SB_AWUSER", "awuser", DutParamDmaId_t'(expected.dma_id), actual.awuser, expected.awuser, 0) )
          this.error("COMPARE_AWUSER_ERROR", $sformatf("(actual/expected) awuser=%0d/%0d", actual.awuser, expected.awuser));

        if( checkItems#(1)::compareItem("C2H_SB_AWID", "awid", DutParamDmaId_t'(expected.dma_id), actual.awid, expected.awid, 0) )
          this.error("COMPARE_AWID_ERROR", $sformatf("(actual/expected) awid=0x%0h/0x%0h", actual.awid, expected.awid));

        if( checkItems#(4)::compareItem("C2H_SB_AWCACHE", "awcache", DutParamDmaId_t'(expected.dma_id), actual.awcache, expected.awcache) )
          this.error("COMPARE_AWCACHE_ERROR", $sformatf("(actual/expected) awcache=0x%0h/0x%0h", actual.awcache, expected.awcache));

        if( checkItems#(2)::compareItem("C2H_SB_AWBURST", "awburst", DutParamDmaId_t'(expected.dma_id), actual.awburst, expected.awburst, 0) )
          this.error("COMPARE_AWBURST_ERROR", $sformatf("(actual/expected) awburst=%0d/%0d", actual.awburst, expected.awburst));
      end:AXIChecker
      
      for(int i=0; i<actual.awlen+1; i++) begin
        HData_t actual_data, expected_data;
        HStrb_t actual_wstrb, expected_wstrb;

        cnt_bl ++;

        actual_data    = actual.wdata.pop_front();
        actual_wstrb   = actual.wstrb.pop_front();
        expected_data  = expected.wdata.pop_front();
        expected_wstrb = expected.wstrb.pop_front();
        expected_addr  = DutParamHostAddr_t'(expected.waddr.pop_front());
       
        this.mm_sb_cov_colctr.sampleHostWstrb(actual_wstrb);

        if( checkItems#(HOST_DATA_BYTE_WIDTH)::compareItem("C2H_SB_WSTRB", "WSTRB", DutParamDmaId_t'(expected.dma_id), actual_wstrb, expected_wstrb, 0) )
          this.error("COMPARE_WSTRB_ERROR", $sformatf("PKT#%0d: (actual/expected) wstrb=%0h/%0h", DutParamDmaId_t'(expected.dma_id), actual_wstrb, expected_wstrb));

        if( checkItems#(HOST_DATA_WIDTH)::compareItemWithStrb("C2H_SB_HOST_DATA", "HOST_DATA", DutParamDmaId_t'(expected.dma_id), actual_data, expected_data, expected_wstrb, 0) )
          this.error("COMPARE_HOST_DATA_ERROR", $sformatf("PKT#%0d: actual_data=%0h, expected_data=%0h", DutParamDmaId_t'(expected.dma_id), actual_data, expected_data));
//        this.debug($sformatf("[COMPARE_HOST_DATA_CHECK] PKT#%0d: actual_data=%0h, expected_data=%0h", DutParamDmaId_t'(expected.dma_id), actual_data, expected_data));

        this.debug($sformatf("%0d, %0d:: wstrb : actual %0h, expected %0h", cnt_aw, cnt_bl, actual_wstrb, expected_wstrb));
      end

      this.debug($sformatf("[COMPARE_HOST_DATA_COMPLETED] PKT#%0d: (actual/expected) awaddr=0x%0h/0x%0h, awlen=%0d/%0d",
          DutParamDmaId_t'(expected.dma_id), DutParamHostAddr_t'(actual.awaddr), DutParamHostAddr_t'(expected.awaddr), actual.awlen, expected.awlen));

      if(expected.wstrb.size == 0 && expected.waddr.size == 0 && expected.wdata.size == 0) begin
        this.hostDataCheck_expected_flag = NO;
      end
      if(expected.wstrb.size != 0 || expected.waddr.size != 0 || expected.wdata.size != 0) begin
        this.hostDataCheck_expected_flag = YES;
        this.q_expected_host_data.push_front(expected);
      end

    end:compare_host_data
    this.sb_flag.flag_c2h_hostData = YES;
  end // END forever

endtask:hostDataChecker



// KTSB-10 : Generate expected Card AR request in C2H operation
function void vdmatb_mm_c2h_sb::calculateCardExpected(T_TRANS data);
  static int num_created = 0;
  T_TRANS                    axiData;
  T_TRANS4                   currAxiItem;
  Len_t                      DataLen;
  Len_t                      pureTotalBurst;
  int                        currBurstLen;
  int                        maxBurstLen;
  int                        remainBurstLen;
  Len_t                      remainDataLen;
  CStrb_t                    strb;
  Addr_t                     raddr;
  Addr_t                     raddrNext;
  Addr_t                     currArAddr;
  Addr_t                     nextArAddr;
  Addr_t                     endArAddr;

  currAxiItem = T_TRANS4::type_id::create();

  DataLen            = data.desc.len;
  maxBurstLen        = 256;
  currArAddr         = DutParamCardAddr_t'(data.desc.src_addr);
  endArAddr          = DutParamCardAddr_t'(data.desc.src_addr) + data.desc.len;

  remainDataLen      = DataLen;
  pureTotalBurst     = getTotalCardBurst(data.desc);


  num_created++;
  currBurstLen   = maxBurstLen;
  nextArAddr     = calculateNextCardAddr(DutParamCardAddr_t'(currArAddr), maxBurstLen, DutParamCardAddr_t'(endArAddr));
  currBurstLen   = updateCurrCardBurstLen(DutParamCardAddr_t'(currArAddr), DutParamCardAddr_t'(nextArAddr));

  currAxiItem.byteLen  =  data.desc.len;
  currAxiItem.arvalid  =  1'b1;
  currAxiItem.arready  =  1'b1;
  currAxiItem.arid     =  0;
  currAxiItem.araddr   =  DutParamCardAddr_t'(currArAddr);
  currAxiItem.arcache  =  2;
  currAxiItem.aruser   =  {data.desc.dma_id};
  currAxiItem.arburst  =  1;
  currAxiItem.arlen    =  pureTotalBurst;
  currAxiItem.dma_id   =  DutParamDmaId_t'(data.desc.dma_id);

  this.debug($sformatf("[C2H_SB_CALCULATE_CARD_EXPECTED] remainData = %0d, currArAddr = %0h pureBL %0d, currBurstLen = %0d, nextArAddr = %0h", remainDataLen, DutParamCardAddr_t'(currArAddr), pureTotalBurst, currBurstLen, DutParamCardAddr_t'(nextArAddr)));

  raddr =  DutParamCardAddr_t'(currArAddr);
  
  while (remainDataLen) begin:while_begin_end
    for (int i = 0; i < pureTotalBurst; i ++) begin:pureTotalBurst
      if (DataLen == remainDataLen) begin
        if (DataLen < CARD_DATA_BYTE_WIDTH) begin
          strb = (this.max_card_wstrb >> (CARD_DATA_BYTE_WIDTH-DataLen));
          strb = (strb << DutParamCardAddr_t'(data.desc.src_addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0]));
        end else begin
          strb = (this.max_card_wstrb << DutParamCardAddr_t'(data.desc.src_addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0]));
        end
      end // first burst
      else if (remainDataLen >= CARD_DATA_BYTE_WIDTH) begin
        strb = this.max_card_wstrb;
      end // middle of bursts
      else if ((remainDataLen > 0) && (remainDataLen < CARD_DATA_BYTE_WIDTH)) begin
        strb = ~(this.max_card_wstrb << remainDataLen);
      end // last burst

      remainDataLen = remainDataLen - checkItems#(CARD_DATA_BYTE_WIDTH)::countOnes(strb);
      raddrNext = DutParamCardAddr_t'(raddr) + checkItems#(CARD_DATA_BYTE_WIDTH)::countOnes(strb);

      currAxiItem.wstrb.push_back(strb);
      currAxiItem.raddr.push_back(DutParamCardAddr_t'(raddr));
      this.debug($sformatf("[C2H_SB_CALCULATE_CARD_EXPECTED] raddr = %0h, strb = %0h, strb.size = %0d, remainDataLen = %0h", DutParamCardAddr_t'(raddr), strb, currAxiItem.wstrb.size(), remainDataLen));
      if (remainDataLen == 0)  break;
      raddr = DutParamCardAddr_t'(raddrNext);
    end:pureTotalBurst

    this.debug($sformatf("[C2H_SB_CALCULATE_CARD_EXPECTED_GEN] id = %d, araddr = %0h, arlen = %0d, strb.size = %0d, remainDataLen = %0h", DutParamDmaId_t'(currAxiItem.dma_id), DutParamCardAddr_t'(currAxiItem.araddr), currAxiItem.arlen, currAxiItem.wstrb.size(), remainDataLen));
    this.q_expected_card_data.push_back(currAxiItem);
  end:while_begin_end
endfunction:calculateCardExpected


// KTSB-10 : Generate expected Host AW request in C2H operation
function void vdmatb_mm_c2h_sb::calculateHostExpected(T_TRANS data);
  static int num_created = 0;
  T_TRANS                    axiData;
  T_TRANS2                   expected;
  DutParamAxiMaxLen_t        maxBurstLen;
  Len_t                      DataLen;
  Len_t                      pureTotalBurst;
  DutParamAxiMaxLen_t        currBurstLen;
  Len_t                      remainDataLen;
  DutParamAxiMaxLen_t        remainBurstLen;
  HStrb_t                    strb;
  Addr_t                     waddr;
  Addr_t                     waddrNext;
  Addr_t                     currAwAddr;
  Addr_t                     nextAwAddr;
  Addr_t                     endAwAddr;

  expected = T_TRANS2::type_id::create();

  DataLen            = data.desc.len;
  maxBurstLen        = data.desc.axi_max_len;
  currAwAddr         = DutParamHostAddr_t'(data.desc.dst_addr);
  endAwAddr          = DutParamHostAddr_t'(data.desc.dst_addr) + data.desc.len;

  remainDataLen      = DataLen;
  pureTotalBurst     = getTotalHostBurst(data.desc);

  this.debug($sformatf("[C2H_SB_CALCULATE_EXPECTED] num=%0d: dst_addr = %0h max_len = %0d, len = %0d, len/64= %0d ", data.desc.dma_id, data.desc.dst_addr, data.desc.axi_max_len, data.desc.len, data.desc.len/64));
  this.debug($sformatf("[C2H_SB_CALCULATE_EXPECTED] dst_addr = %0h max_len = %0h, len = %0h", data.desc.dst_addr, data.desc.axi_max_len, data.desc.len));
  if (data.desc.axi_max_len > (AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH) || (data.desc.axi_max_len == 0))
    maxBurstLen = AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH;

  num_created++;
  currBurstLen   = maxBurstLen;
  nextAwAddr     = calculateNextHostAddr(DutParamHostAddr_t'(currAwAddr), maxBurstLen, DutParamHostAddr_t'(endAwAddr));
  currBurstLen   = updateCurrHostBurstLen(DutParamHostAddr_t'(currAwAddr), DutParamHostAddr_t'(nextAwAddr));

  expected.byteLen  =  data.desc.len;
  expected.awvalid  =  1'b1;
  expected.awready  =  1'b1;
  expected.awid     =  0;
  expected.awaddr   =  DutParamHostAddr_t'(currAwAddr);
  expected.awcache  =  2;
  expected.awuser   =  {data.desc.fnc_id, data.desc.str_id};
  expected.awburst  =  1;
  expected.awlen    =  pureTotalBurst;
  expected.dma_id   =  DutParamDmaId_t'(data.desc.dma_id);

  this.debug($sformatf("[C2H_SB_CALCULATE_HOST_EXPECTED] remainData = %0d, currAwAddr = %0h pureBL %0d, currBurstLen = %0d, nextAwAddr = %0h", remainDataLen, DutParamHostAddr_t'(currAwAddr), pureTotalBurst, currBurstLen, DutParamHostAddr_t'(nextAwAddr)));

  waddr =  DutParamHostAddr_t'(currAwAddr);
  
  
  while (remainDataLen) begin:while_begin_end
    for (int i = 0; i < pureTotalBurst; i ++) begin:pureTotalBurst
      if (DataLen == remainDataLen) begin
        if (DataLen < HOST_DATA_BYTE_WIDTH) begin
          strb = (this.max_host_wstrb >> (HOST_DATA_BYTE_WIDTH-DataLen));
          strb = (strb << DutParamHostAddr_t'(data.desc.dst_addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0]));
        end else begin
          strb = this.max_host_wstrb << DutParamHostAddr_t'(data.desc.dst_addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0]);
        end
      end // first burst
      else if (remainDataLen >= HOST_DATA_BYTE_WIDTH) begin
        strb = this.max_host_wstrb;
      end // middle of bursts
      else if ((remainDataLen > 0) && (remainDataLen < HOST_DATA_BYTE_WIDTH)) begin
        strb = ~(this.max_host_wstrb << remainDataLen);
      end // last burst
      
      remainDataLen = remainDataLen - checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(strb);
      waddrNext = DutParamHostAddr_t'(waddr) + checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(strb);

      this.debug($sformatf("[CAL_EXPECTED_HOST_DATA_REMAIN] PKT#%0d: wstrb=%0h, remain_data_len=%0d, num_of_data=%0d",
          DutParamDmaId_t'(expected.dma_id), strb, remainDataLen, checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(strb)));

      expected.wstrb.push_back(strb);
      expected.waddr.push_back(DutParamHostAddr_t'(waddr));
      
      this.debug($sformatf("[C2H_SB_CALCULATE_HOST_EXPECTED] waddr = %0h, strb = %0h, strb.size = %0d, remainDataLen = %0h", DutParamHostAddr_t'(waddr), strb, expected.wstrb.size(), remainDataLen));
      if (remainDataLen == 0)  break;
      
      waddr = DutParamHostAddr_t'(waddrNext);
    end:pureTotalBurst

    this.debug($sformatf("[C2H_SB_CALCULATE_HOST_EXPECTED_GEN] id = %d, awaddr = %0h, awlen = %0d, strb.size = %0d, remainDataLen = %0h", DutParamDmaId_t'(expected.dma_id), DutParamHostAddr_t'(expected.awaddr), expected.awlen, expected.wstrb.size(), remainDataLen));
    
    this.q_expected_host_temp.push_back(expected);
  end:while_begin_end
endfunction:calculateHostExpected



`endif //__VDMATB_MM_C2H_SB_SVH__
