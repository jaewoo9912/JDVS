`ifndef __VDMATB_ST_H2C_SB_SVH__
`define __VDMATB_ST_H2C_SB_SVH__

class vdmatb_st_h2c_sb extends vdmatb_sb;

  typedef struct{
    DmaId_t      dma_id;
    int unsigned total_len;
    bit          sop, eop;
    YesOrNo_t    flag_chk_to_delete = NO;
  }LenOfGathering_t;

  int flt_count = 0;

  `uvm_component_utils (vdmatb_st_h2c_sb)
  // TODO : need to remove global items into function scope
  T_TRANS2 checkData;
  
  LenOfGathering_t q_h2c_desc_with_gathering[$];


  function new (string name = "vdmatb_st_h2c_sb", uvm_component parent);
    super.new(name, parent);
  endfunction


  // ---------------------------- uvm built-in
  extern virtual function void build_phase(uvm_phase phase);


  // ---------------------------- vdma_sb built-in
  extern virtual function DmaTransType_t getTransType();
  extern virtual function void post_registerNewPkt(T_TRANS3 trans, T_TRANS trans2);
  extern virtual function void post_updateMstData(T_TRANS3 trans, T_TRANS trans2);
  extern virtual function void post_updateHostData(T_TRANS3 trans, T_TRANS2 trans2);
  
  extern virtual function void callbackReset();


  // ---------------------------- vdmatb_st_h2c_sb built-in
  extern virtual task cardDataChecker();
  extern virtual task hostDataChecker();

  extern virtual function void compareCardData(T_TRANS2 actual, T_TRANS2 expected);
  extern virtual function YesOrNo_t checkFaultOnHostData(T_TRANS3 trans, T_TRANS2 trans2);
  
  extern virtual function void          calculateExpected     (T_TRANS data);
  extern virtual function bit           isGathering           (bit gathering, sop, eop);
  extern virtual function void          updateExpectAxisData  (int byte_cnt, HData_t expectData, T_TRANS2 inData, Len_t total_len);

  extern virtual function void sampleDesc(T_TRANS trans);
  
  extern local function vdmatb_host_seq_item calculateExpectedTdata(T_TRANS2 trans, int q_data_size, int trans_total_len); 

endclass:vdmatb_st_h2c_sb


function void vdmatb_st_h2c_sb::sampleDesc(T_TRANS trans);
  this.st_sb_cov_colctr.sampleDesc(trans);
endfunction : sampleDesc

function void vdmatb_st_h2c_sb::build_phase(uvm_phase phase);
  super.build_phase(phase);

  checkData = T_TRANS2::type_id::create();

endfunction:build_phase



function DmaTransType_t vdmatb_st_h2c_sb::getTransType();
  return(ST_H2C);
endfunction:getTransType

function void vdmatb_st_h2c_sb::callbackReset();
  this.checkData = new();
endfunction:callbackReset



// KTSB-9 : Generate expected Host AR request in H2C operation
function void vdmatb_st_h2c_sb::post_registerNewPkt(T_TRANS3 trans, T_TRANS trans2);
  static int num_created = 0;
  Desc_t                    desc;
  DmaId_t                   dma_id;
  StrId_t                   str_id;

  DutParamAxiMaxLen_t       max_hburst_len;
  DutParamAxiMaxLen_t       cur_burst_len;
  DutParamAxiMaxLen_t       next_burst_len;
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
  
  this.debug($sformatf("[EXPECT_HOST_AR_1] PKT#%0d: src_addr=%0h, max_hburst_len=%0d, len_in_byte=%0d, len/64=%0d",
    DutParamDmaId_t'(desc.dma_id), DutParamHostAddr_t'(desc.src_addr), desc.axi_max_len, desc.len, desc.len/64));
  
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
    
    this.debug($sformatf("[EXPECT_HOST_AR_2] PKT#%0d: remain_data_len=%0d, araddr=%0h, cur_burst_len=%0d, next_araddr=%0h",
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
    expected.sop      =  desc.sop;
    expected.eop      =  desc.eop;
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
  
  this.calculateExpected(trans2);
endfunction:post_registerNewPkt




// KTSB-22 : H2C post_updateCardData
function void vdmatb_st_h2c_sb::post_updateMstData(T_TRANS3 trans, T_TRANS trans2);
  T_TRANS2    rcvd;

  rcvd = T_TRANS2::type_id::create();
  
  rcvd.q_data = trans2.q_data;
  rcvd.dma_id = DutParamDmaId_t'(trans2.dma_id);
  
  this.q_actual_mst_data.push_back(rcvd);
endfunction : post_updateMstData


function void vdmatb_st_h2c_sb::post_updateHostData(T_TRANS3 trans, T_TRANS2 trans2);
  YesOrNo_t fault;
  
  fault = this.checkFaultOnHostData(trans, trans2);
  
  
endfunction:post_updateHostData




function void vdmatb_st_h2c_sb::compareCardData(T_TRANS2 actual, T_TRANS2 expected);
  Data_t  actual_data;
  CStrb_t expected_strb;
  CData_t expected_data;
  DataValue_t   actual_data_value;
  
  if( checkItemsByType#(int)::compareItem("H2C_SB_ST_SIZE", "size", actual.dma_id, actual.q_data.size(), expected.q_data.size(), 0) )
    this.error("COMPARE_DATA_SIZE_ERROR", $sformatf("(actual/expected) size=%0d/%0d, dma_id=%1d", actual.q_data.size(), expected.q_data.size(), expected.dma_id));
  
  while( actual.q_data.size() > 0) begin:do_while
    actual_data = actual.q_data.pop_front();
    expected_data = expected.q_data.pop_front();
    expected_strb = expected.wstrb.pop_front();
    
    this.debug($sformatf("[COMPARE_RUN_PHASE] PKT#%0d: actual_data=0x%0h, expected_data=0x%0h, expected_strb=0x%016h",
      DutParamDmaId_t'(actual.dma_id), actual_data.value, expected_data, expected_strb));
    
    if( checkItems#(MAX_DATA_WIDTH)::compareItem("H2C_SB_DATA", "C_DATA", DutParamDmaId_t'(actual.dma_id), actual_data.value, expected_data, 0) )
      this.error("COMPARE_C_DATA_ERROR", $sformatf("PKT#%0d: (actual/expected) data=0x%0h/0x%0h",
        DutParamDmaId_t'(actual.dma_id), actual_data_value, expected_data));
    
  end:do_while

endfunction


function YesOrNo_t vdmatb_st_h2c_sb::checkFaultOnHostData(T_TRANS3 trans, T_TRANS2 trans2);
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
  
  CovWrongResp_t cov_host_r_wrong_resp;
  
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
        
        cov_host_r_premature_last.dma_id     = created_fault.dma_id;
        cov_host_r_premature_last.fault_code = int'(created_fault.code);
        this.q_cov_expected_fault_host_r_premature_last.push_back(cov_host_r_premature_last);
        this.debug($sformatf("[FAIL_HOST_R_PREMATURE_LAST] result: %0h, rlast : %0d, fault_code : %0h, failed_rlast_in_q : %0d", result, q_rlast[i], created_fault.code, i));
      end
    end
  //end

  // KTSB- : HOST_R_WRONG_RESP - Check Fault code within RRESP
    if( q_rresp[i] != 0 ) begin
      created_fault.axi_resp = q_rresp[i];
      created_fault.code     = HOST_R_WRONG_RESP;
      result_rresp           = YES;
      this.debug($sformatf("[FAIL_HOST_R_WRONG_RESP] result: %0h, rresp : %0h, fault_code : %0h, rresp : %0h", result, created_fault.axi_resp, created_fault.code, q_rresp[i]));
      
      cov_host_r_wrong_resp.resp   = created_fault.axi_resp;
      cov_host_r_wrong_resp.dma_id = DutParamDmaId_t'(desc.dma_id);
      this.q_actual_fault_host_r_wrong_resp.push_back(cov_host_r_wrong_resp);
    end

    if((result_plast == YES) | (result_rresp == YES)) result_all = YES;
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
      
      cov_host_r_no_last.dma_id     = DutParamDmaId_t'(created_fault.dma_id);
      cov_host_r_no_last.fault_code = int'(created_fault.code);
      this.q_cov_expected_fault_host_r_no_last.push_back(cov_host_r_no_last);
      this.debug($sformatf("[FAIL_HOST_R_NO_LAST] result: %0h,  q_rlast_size : %0d, cnt_rlast : %0d, fault_code : %0h", result, q_rlast.size(), cnt_rlast, created_fault.code));
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



function bit vdmatb_st_h2c_sb::isGathering(bit gathering, sop, eop);
   bit value;

  case ({gathering, sop, eop})
    3'b000  : value = gathering;
    3'b010  : value = 1'b1;
    3'b001  : value = 1'b0;
    3'b011  : value = 1'b0;
    3'b101  : value = 1'b0;
    3'b111  : value = 1'b0;
    default : value = gathering;
  endcase

   return (value);
endfunction

function void vdmatb_st_h2c_sb::updateExpectAxisData(int byte_cnt, HData_t expectData, T_TRANS2 inData, Len_t total_len);
  T_TRANS2    copyData;
  HStrb_t     strb = this.max_host_wstrb;
  DmaId_t     deleted_dma_id;
  int         q_data_size, q_h2c_desc_with_gth_size, trans_total_len;

  copyData     = T_TRANS2::type_id::create();
  
  foreach(this.q_h2c_desc_with_gathering[i]) begin
    if(inData.dma_id == this.q_h2c_desc_with_gathering[i].dma_id) begin
      deleted_dma_id   = inData.dma_id;
      trans_total_len += this.q_h2c_desc_with_gathering[i].total_len;
      this.q_h2c_desc_with_gathering[i].flag_chk_to_delete = YES;
    end
  end

  for(int i = 0; i < q_h2c_desc_with_gth_size; i++) begin
    LenOfGathering_t deleted_desc; 
    
    if(this.q_h2c_desc_with_gathering[i].flag_chk_to_delete == YES)
      deleted_desc = this.q_h2c_desc_with_gathering.pop_front();
  end
  
  
  if (byte_cnt !=0) begin:byte_cnt_not_zero
    while (byte_cnt<HOST_DATA_BYTE_WIDTH-1) begin:byte_cnt_less_64
      expectData[HOST_DATA_WIDTH-1:HOST_DATA_WIDTH-8]=8'h00;
      expectData = expectData >> 8;
      strb[byte_cnt+1] = 1'b0;
      byte_cnt++;
    end:byte_cnt_less_64
    
    byte_cnt = 0;
    inData.q_data.push_back(expectData);
    inData.wstrb.push_back(strb);
  end:byte_cnt_not_zero
  
  copyData.copy(inData);
  copyData.q_data = inData.q_data;
  copyData.dma_id = DutParamDmaId_t'(inData.dma_id);
  copyData.wstrb  = inData.wstrb;
  
  q_data_size = copyData.q_data.size();
  
  this.q_expected_mst_data.push_back(this.calculateExpectedTdata(copyData, q_data_size, trans_total_len));
endfunction




task vdmatb_st_h2c_sb::cardDataChecker();

  bit   expected_bit = 0;
  bit   actual_bit   = 0;
  
  T_TRANS2 actual, expected;
  expected = T_TRANS2::type_id::create();
  actual   = T_TRANS2::type_id::create();
  
  forever begin:card_data_check_routine
    this.debug($sformatf("[H2C_SB_RUN_PHASE0] actual.q_data.size=%1d, expected.q_data.size=%1d", this.q_actual_mst_data.size, this.q_expected_mst_data.size));
    
    if( this.q_expected_mst_data.size() == 0 ) wait(this.q_expected_mst_data.size()>0);
    if( this.q_actual_mst_data.size() == 0 ) wait(this.q_actual_mst_data.size()>0);
    this.sb_flag.flag_cardData = NO;
    
    fork
      begin
        expected = this.q_expected_mst_data.pop_front();
        this.debug($sformatf("[H2C_SB_RUN_PHASE2] expected: dma_id=%0d, size=%0d, strb.size=%0d",
          DutParamDmaId_t'(expected.dma_id), expected.q_data.size(), expected.wstrb.size()));
        expected_bit = 1'b1;
      end
      
      begin
        actual = this.q_actual_mst_data.pop_front();
        this.debug($sformatf("[H2C_SB_RUN_PHASE1] actual: dma_id=%0d, size=%0d",
          DutParamDmaId_t'(actual.dma_id), actual.q_data.size()));
        actual_bit = 1'b1;
      end
    join
    
    wait( (actual_bit==1) && (expected_bit==1) );
    
    foreach(actual.q_data[i])
      this.compareCardData(actual, expected);
    
    this.sb_flag.flag_cardData = YES;
    actual_bit = 0; expected_bit = 0;
  end:card_data_check_routine

endtask:cardDataChecker



task vdmatb_st_h2c_sb::hostDataChecker();

  T_TRANS2      actual, expected;

  Addr_t        expected_addr;
  bit           gathering = 1'b0;
  int           cnt_ar = 0, cnt_bl = 0;
  HStrb_t       expected_byte;
  Len_t         total_len;
  int           expected_ar_len = 0;
  int           byte_cnt = 0;
  DmaId_t       cur_dma_id = 0;

//  CData_t       expected_data;
  HData_t       expected_data;
  HData_t       actual_data, actual_data_shift;
  HStrb_t       expected_wstrb;
  
  expected = T_TRANS2::type_id::create();
  
  forever begin:forever_end
    wait(this.q_expected_host_data.size() > 0);
    this.sb_flag.flag_h2c_hostData = NO;
    
    if(this.q_expected_host_data.size() > 0) begin:expected_host_qsize
      cnt_ar++;
      cnt_bl=0;
      
      wait(this.q_actual_host_data.size() > 0 );
      actual = this.q_actual_host_data.pop_front();
      this.st_sb_cov_colctr.sampleArLen(actual.arlen);
      
      if(expected.wstrb.size() == 0) begin:update_expected_item
        LenOfGathering_t gth_desc;
        
        expected           = this.q_expected_host_data.pop_front();
        expected_addr      = DutParamHostAddr_t'(expected.araddr);
        expected_ar_len    = expected.wstrb.size();
        expected_byte      = expected.byteLen;
        cur_dma_id         = DutParamDmaId_t'(expected.dma_id);
        gathering          = isGathering(gathering, expected.sop, expected.eop);
        total_len          = Len_t'(expected.byteLen);
        gth_desc.dma_id    = DutParamDmaId_t'(expected.dma_id);
        gth_desc.total_len = int'(total_len);
        gth_desc.sop       = expected.sop;
        gth_desc.eop       = expected.eop;
        
        this.q_h2c_desc_with_gathering.push_back(gth_desc);
      end:update_expected_item
      this.debug($sformatf("[COMPARE_HOST_DATA_EXPECTED] dma_id=%0d, gathering=%0d, sop/eop=%0d/%0d, len=%0d/%0d",
        DutParamDmaId_t'(expected.dma_id), gathering, expected.sop, expected.eop, expected_ar_len, expected.arlen));
      this.debug($sformatf("[COMPARE_HOST_DATA_ACTUAL ] dma_id=%0d, actual.addr=%0h, acutal.arBL=%0d, expected_ar_len=%0d, wstrb.size=%0d",
        DutParamDmaId_t'(actual.dma_id), DutParamHostAddr_t'(actual.araddr), actual.arlen, expected_ar_len, expected.wstrb.size()));
      
      if(expected.raddr.size() > 0) begin:update_expected_addr
        expected_addr = DutParamHostAddr_t'(expected.raddr.pop_front());
      end:update_expected_addr
      
      begin:AXIChecker
        if( checkItems#(MAX_ADDR_WIDTH)::compareItem("H2C_SB_ARADDR", "araddr", DutParamDmaId_t'(cur_dma_id), DutParamHostAddr_t'(actual.araddr), DutParamHostAddr_t'(expected_addr), 0) )
          this.error("COMPARE_ARADDR_ERROR", $sformatf("(actual/expected) araddr=0x%0h/0x%0h", DutParamHostAddr_t'(actual.araddr), DutParamHostAddr_t'(expected_addr)));
        
        if( checkItems#(16)::compareItem("H2C_SB_ARUSER", "aruser", DutParamDmaId_t'(cur_dma_id), actual.aruser, expected.aruser, 0) )
          this.error("COMPARE_ARUSER_ERROR", $sformatf("(actual/expected) aruser=0x%0h/0x%0h", actual.aruser, expected.aruser));
          
        if( checkItems#(1)::compareItem("H2C_SB_ARID", "arid", DutParamDmaId_t'(cur_dma_id), actual.arid, expected.arid, 0) )
          this.error("COMPARE_ARID_ERROR", $sformatf("(actual/expected) arid=0x%0h/0x%0h", actual.arid, expected.arid));
        
        if( checkItems#( 4)::compareItem("H2C_SB_ARCACHE", "arache", DutParamDmaId_t'(cur_dma_id), actual.arcache, expected.arcache) )
          this.error("COMPARE_ARCACHE_ERROR", $sformatf("(actual/expected) arcache=0x%0h/0x%0h", actual.arcache, expected.arcache));
        
        if( checkItems#( 2)::compareItem("H2C_SB_ARBURST", "arburst", DutParamDmaId_t'(cur_dma_id), actual.arburst, expected.arburst, 0) )
          this.error("COMPARE_ARBURST_ERROR", $sformatf("(actual/expected) arburst=%0d/%0d", actual.arburst, expected.arburst));
      end:AXIChecker
      
      for(int i=0; i<actual.arlen+1; i++) begin:for_actual_arlen
        cnt_bl++;
        expected_ar_len--;
        
        this.debug($sformatf("[COMPARE_HOST_DATA_ACTUAL] dma_id=%0d, expect_ar_len=%0d, strb.size=%0d, actual.araddr=0x%0h, actual.arlen=%0d", DutParamDmaId_t'(cur_dma_id), expected_ar_len, expected.wstrb.size(), DutParamHostAddr_t'(actual.araddr), actual.arlen+1));
        
        if( (i<actual.arlen) && (expected.raddr.size()>0) ) expected_addr = DutParamHostAddr_t'(expected.raddr.pop_front());
        if( expected.wstrb.size() > 0 ) begin
          expected_wstrb = expected.wstrb.pop_front();
        end
        
        actual_data = actual.rdata.pop_front();
        actual_data_shift = actual_data;
        
        this.debug($sformatf("[COMPARE_HOST_DATA_ACTUAL_RDATA_2] dma_id=%0d, gathering=%0d, sop/eop=%0d/%0d, actual_araddr=0x%0h, expected_wstrb=0x%0h, actual.rdata.size=%0d, actual_data=0x%0h, byte_cnt=%0d",
          DutParamDmaId_t'(cur_dma_id), gathering, expected.sop, expected.eop, DutParamHostAddr_t'(actual.araddr), expected_wstrb, actual.rdata.size(), actual_data, byte_cnt));
       
        for(int t=0; t<HOST_DATA_BYTE_WIDTH; t++) begin:for_byte
          checkData.dma_id = DutParamDmaId_t'(cur_dma_id);
          
          if(expected_wstrb[t]) begin:if_wstrb
            expected_data[HOST_DATA_WIDTH-1:HOST_DATA_WIDTH-8] = actual_data_shift[7:0];
            if(byte_cnt==HOST_DATA_BYTE_WIDTH-1) begin:byte_cnt_63
              byte_cnt=0;
              checkData.q_data.push_back(expected_data);
              checkData.wstrb.push_back(this.max_host_wstrb);
              this.debug($sformatf("[COMPARE_HOST_DATA_tt] dma_id=%0d, gathering=%0d, checkData.q_data.size=%0d, expected_data=0x%0h",
                DutParamDmaId_t'(checkData.dma_id), gathering, checkData.q_data.size(), expected_data));
            end:byte_cnt_63
            else    begin 
              byte_cnt++;
            end
            expected_data = expected_data >> 8;
          end:if_wstrb
          
          
          actual_data_shift = actual_data_shift >> 8;
          expected_byte = expected_byte - expected_wstrb[t];
          
          
          this.debug($sformatf("[COMPARE_HOST_DATA_tt_byte] %0d .. %0d dma_id=%0d, gathering=%0d, checkData.q_data.size=%0d, strb=0x%0h, expected_data=0x%0h, actual_data_shift=0x%0h",
            t, byte_cnt, DutParamDmaId_t'(checkData.dma_id), gathering, checkData.q_data.size(), expected_wstrb, expected_data, actual_data_shift));
          this.debug($sformatf("[COMPARE_HOST_DATA_ACTUAL_RDATA1_] dma_id=%0d, gathering=%0d, byte=%0d, expected_byte=0x%0h, countOnes=0x%0h, wstrb=0x%0h, byte_cnt=%0d",
            DutParamDmaId_t'(cur_dma_id), gathering, expected_byte, expected_ar_len, checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(expected_wstrb), expected_wstrb, byte_cnt));
        end:for_byte
        
        this.debug($sformatf("[COMPARE_HOST_DATA_ACTUAL_RDATA1_] dma_id=%0d, gathering=%0d, byte=%0d, arlen=%0d, araddr=0x%0h, wstrb=0x%0h, size=%0d, actual_data=0x%0h, byte_cnt=%0d",
          DutParamDmaId_t'(cur_dma_id), gathering, expected_byte, expected_ar_len, DutParamHostAddr_t'(actual.araddr), expected_wstrb, actual.rdata.size(), actual_data, byte_cnt));
       
       
        if( (expected_byte==0) && (gathering==0) ) begin
          this.debug($sformatf("[COMPARE_HOST_DATA_ACTUAL_RDATA1_]IN!! dma_id=%0d, gathering=%0d, byte=%0d, arlen=%0d, araddr=0x%0h, wstrb=0x%0h, size=%0d, actual_data=0x%0h, byte_cnt=%0d",
            DutParamDmaId_t'(cur_dma_id), gathering, expected_byte, expected_ar_len, DutParamHostAddr_t'(actual.araddr), expected_wstrb, actual.rdata.size(), actual_data, byte_cnt));
          
          updateExpectAxisData(byte_cnt, expected_data, checkData, total_len);
          
          this.debug($sformatf("[COMPARE_HOST_DATA_expected_card_data] dma_id=%0d, q_data.size=%0d, q_expected_mst_data.size=%0d, expected_data=0x%0h",
            DutParamDmaId_t'(checkData.dma_id), checkData.q_data.size(), this.q_expected_mst_data.size(), expected_data));
          byte_cnt=0;
          checkData.q_data.delete();
          checkData.wstrb.delete();
        end
        
      end:for_actual_arlen
      
      this.debug($sformatf("[COMPARE_HOST_DATA] dma_id=%0d, cnt_ar=%0d, cnt_bl=%0d, strb.size=%0d, expected_ar_len=%0d",
        DutParamDmaId_t'(cur_dma_id), cnt_ar, cnt_bl, expected.wstrb.size(), expected_ar_len));
    end:expected_host_qsize
    this.sb_flag.flag_h2c_hostData = YES;
  end:forever_end

endtask:hostDataChecker



// ----------- Back-up origin-code
// TODO : remove codes in comment out

// KTSB-10 : Generate expected Host AR request in H2C operation
function void vdmatb_st_h2c_sb::calculateExpected(T_TRANS data );
   static int num_created = 0;
   T_TRANS                    axiData;
   T_TRANS2                   currAxiItem;
   DutParamAxiMaxLen_t        maxBurstLen;
   Len_t                      DataLen;
   Len_t                      pureTotalBurst;
   DutParamAxiMaxLen_t        currBurstLen;
   Len_t                      remainDataLen;
   DutParamAxiMaxLen_t        remainBurstLen;
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

   this.debug($sformatf("[H2C_SB_CALCULATE_EXPECTED] num=%0d: src_addr = %0h max_len = %0d, len = %0d, len/64= %0d sop %0d eop %0d", data.desc.dma_id, data.desc.src_addr, data.desc.axi_max_len, data.desc.len, data.desc.len/64, data.desc.sop, data.desc.eop));
   this.debug($sformatf("[H2C_SB_CALCULATE_EXPECTED] src_addr = %0h max_len = %0h, len = %0h", data.desc.src_addr, data.desc.axi_max_len, data.desc.len));
   if (data.desc.axi_max_len > (AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH)) 
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
   currAxiItem.sop      =  data.desc.sop;
   currAxiItem.eop      =  data.desc.eop;

  this.debug($sformatf("[H2C_SB_CALCULATE_EXPECTED] remainData = %0d, currArAddr = %0h pureBL %0d, currBurstLen = %0d, nextArAddr = %0h", remainDataLen, DutParamHostAddr_t'(currArAddr), pureTotalBurst, currBurstLen, DutParamHostAddr_t'(nextArAddr)));

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
     this.debug($sformatf("[H2C_SB_CALCULATE_EXPECTED] raddr = %0h, strb = %0h, strb.size = %0d, remainDataLen = %0h", DutParamHostAddr_t'(raddr), strb, currAxiItem.wstrb.size(), remainDataLen));
     if (remainDataLen == 0)  break;
      raddr = DutParamHostAddr_t'(raddrNext);
   end:pureTotalBurst

     this.debug($sformatf("[H2C_SB_CALCULATE_EXPECTED_GEN] id = %d, araddr = %0h, arlen = %0d, strb.size = %0d, remainDataLen = %0h", DutParamDmaId_t'(currAxiItem.dma_id), DutParamHostAddr_t'(currAxiItem.araddr), currAxiItem.arlen, currAxiItem.wstrb.size(), remainDataLen));
     this.q_expected_host_data.push_back(currAxiItem);
  end:while_begin_end
endfunction:calculateExpected



function vdmatb_host_seq_item vdmatb_st_h2c_sb::calculateExpectedTdata(T_TRANS2 trans, int q_data_size, int trans_total_len);
  T_TRANS2 host_trans;
  int num_planned_data = 0, chk_num_planned_data = 0;
  int data_width_gap;
  
  host_trans = T_TRANS2::type_id::create();
  
  host_trans.dma_id = DutParamDmaId_t'(trans.dma_id);
  host_trans.wstrb  = trans.wstrb;
  data_width_gap    = this.calculate_data_width_gap();
  
  num_planned_data = trans_total_len / CARD_DATA_BYTE_WIDTH;
  if(trans_total_len % CARD_DATA_BYTE_WIDTH != 0) num_planned_data++;
  chk_num_planned_data = num_planned_data;
  
  for(int i = 0; i < q_data_size; i++) begin
    HData_t host_data;
    
    host_data = trans.q_data.pop_front();
    if(i == (q_data_size - 1)) 
      num_planned_data = chk_num_planned_data - (i * (data_width_gap));
    else 
      num_planned_data = data_width_gap;
    
    for(int j = 0; j < num_planned_data; j++) begin
      CData_t tdata;
      
      tdata = host_data[CARD_DATA_WIDTH - 1:0];
      host_trans.q_data.push_back(tdata);
      host_data = host_data >> CARD_DATA_WIDTH;
    end
  end
  
  return(host_trans);
endfunction : calculateExpectedTdata


`endif //__VDMATB_ST_H2C_SB_SVH__
