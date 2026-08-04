`ifndef __VDMATB_ST_C2H_SB_SVH__
`define __VDMATB_ST_C2H_SB_SVH__

class vdmatb_st_c2h_sb extends vdmatb_sb;
  
  `uvm_component_utils(vdmatb_st_c2h_sb)

  YesOrNo_t hostDataCheck_expected_flag = NO;

//  vdmatb_st_st_sb_cov_colctr   st_sb_cov_colctr;
  
  function new (string name = "vdmatb_st_c2h_sb", uvm_component parent);
    super.new(name, parent);
  endfunction


  // ---------------------------- uvm built-in
  extern virtual function void build_phase(uvm_phase phase);


  // ---------------------------- vdma_sb built-in
  extern virtual function DmaTransType_t getTransType();
  extern virtual function void post_registerNewPkt(T_TRANS3 trans, T_TRANS trans2);
  extern virtual function void post_updateMstData(T_TRANS3 trans, T_TRANS trans2);
  extern virtual function void post_updateHostData(T_TRANS3 trans, T_TRANS2 trans2);


  // ---------------------------- vdmatb_st_c2h_sb built-in
  extern virtual task cardDataChecker();
  extern virtual task hostDataChecker();
  
  extern virtual function YesOrNo_t checkFaultOnHostData(T_TRANS3 trans, T_TRANS2 trans2);

  extern virtual function void sampleDesc(T_TRANS trans);

endclass:vdmatb_st_c2h_sb


function void vdmatb_st_c2h_sb::sampleDesc(T_TRANS trans);
  this.st_sb_cov_colctr.sampleDesc(trans);
endfunction : sampleDesc


function void vdmatb_st_c2h_sb::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction:build_phase

function DmaTransType_t vdmatb_st_c2h_sb::getTransType();
  return(ST_C2H);
endfunction:getTransType



// KTSB-8 : Generate expected Host AW request in C2H operation
function void vdmatb_st_c2h_sb::post_registerNewPkt(T_TRANS3 trans, T_TRANS trans2);
  static int num_created = 0;
  Desc_t                    desc;
  DmaId_t                   dma_id;
  DutParamAxiMaxLen_t       max_hburst_len;
  DutParamAxiMaxLen_t       cur_burst_len;
  DutParamAxiMaxLen_t       next_burst_len;
  Len_t                     total_burst_len;
  Len_t                     data_len;
  Len_t                     remain_data_len;
  Addr_t                    awaddr;
  Addr_t                    next_awaddr;
  Addr_t                    end_awaddr;
  Addr_t                    waddr;
  Addr_t                    next_waddr;
  HStrb_t                   wstrb;
  
  
  // START ----------- Initialize variables with DESC information
  desc = trans2.desc;
  
  dma_id          = DutParamDmaId_t'(desc.dma_id);
  data_len        = desc.len;
  max_hburst_len  = desc.axi_max_len;
  awaddr          = DutParamHostAddr_t'(desc.dst_addr);
  end_awaddr      = DutParamHostAddr_t'(awaddr) + data_len;
  remain_data_len = data_len;
  total_burst_len = getTotalHostBurst(desc);
  if( (desc.axi_max_len > (AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH)) || (desc.axi_max_len==0) ) 
    max_hburst_len = AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH;
  
  this.debug($sformatf("[EXPECT_HOST_AW_1] PKT#%0d: dst_addr=%0h, max_hburst_len=%0d, len_in_byte=%0d, len/64=%0d",
    DutParamDmaId_t'(desc.dma_id), DutParamHostAddr_t'(desc.dst_addr), desc.axi_max_len, desc.len, desc.len/64));  
  
  num_created++;
  cur_burst_len = max_hburst_len;
  next_awaddr = calculateNextHostAddr(DutParamHostAddr_t'(awaddr), max_hburst_len, DutParamHostAddr_t'(end_awaddr));
  cur_burst_len = updateCurrHostBurstLen(DutParamHostAddr_t'(awaddr), DutParamHostAddr_t'(next_awaddr));
  waddr = DutParamHostAddr_t'(awaddr);
  // END ----------- Initialize variables with DESC information
  
  // START ----------- Generate Expected HOST_AW
  while(remain_data_len) begin:while_begin_end
    T_TRANS2 expected;
    expected = T_TRANS2::type_id::create();
    
    this.debug($sformatf("[EXPECT_HOST_AW_2] PKT#%0d: remain_data_len=%0d, awaddr=%0h, cur_burst_len=%0d, next_awaddr=%0h",
      DutParamDmaId_t'(desc.dma_id), remain_data_len, DutParamHostAddr_t'(awaddr), cur_burst_len, DutParamHostAddr_t'(next_awaddr)));
    
    expected.dma_id   =  DutParamDmaId_t'(dma_id);
    expected.awvalid  =  1'b1;
    expected.awready  =  1'b1;
    expected.awid     =  0; 
    expected.awaddr   =  DutParamHostAddr_t'(awaddr);
    expected.awcache  =  2;
    expected.awuser   =  {desc.fnc_id, desc.str_id};
    expected.awburst  =  1;
    expected.awlen    =  cur_burst_len -1;
    
    for(int i=0; i<cur_burst_len; i++) begin:host_data_loop
      
      // START ----------- Expected WSTRB
      // First Burst
      if( remain_data_len == data_len ) begin
        if(data_len < HOST_DATA_BYTE_WIDTH) begin
          wstrb = (this.max_host_wstrb >> (HOST_DATA_BYTE_WIDTH - data_len));
          wstrb = (wstrb << DutParamHostAddr_t'(desc.dst_addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0]));
        end
        else begin
          wstrb = (this.max_host_wstrb << DutParamHostAddr_t'(desc.dst_addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0]));
        end
      end
      // Middle of Bursts
      else if(remain_data_len >= HOST_DATA_BYTE_WIDTH) begin
        wstrb = this.max_host_wstrb;
      end
      // Last Burst
      else if( (remain_data_len>0) && (remain_data_len<HOST_DATA_BYTE_WIDTH) ) begin
        wstrb = ~(this.max_host_wstrb << remain_data_len);
      end
      // END ----------- Expected WSTRB
      
      remain_data_len = remain_data_len - checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(wstrb);
      next_waddr = DutParamHostAddr_t'(waddr) + checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(wstrb);
      
      expected.wstrb.push_back(wstrb);
      expected.waddr.push_back(DutParamHostAddr_t'(waddr));
      
      this.debug($sformatf("[EXPECT_HOST_AW_3] PKT#%0d: awaddr=0x%0h, waddr=0x%0h, wstrb=%0h, num_of_data=%0d, wstrb.size=%0d, remain_data_len=%0d",
        DutParamDmaId_t'(expected.dma_id), DutParamHostAddr_t'(awaddr), DutParamHostAddr_t'(waddr), wstrb, checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(wstrb), expected.wstrb.size(), remain_data_len));
      
      if(remain_data_len == 0) break;
      
      waddr = DutParamHostAddr_t'(next_waddr);
      
    end:host_data_loop
    
 
    this.debug($sformatf("[NEW_EXPECTED_HOST_AW] PKT#%0d: awaddr=0x%0h, awlen=%0d, size(num_data)=%0d",
      DutParamDmaId_t'(expected.dma_id), DutParamHostAddr_t'(expected.awaddr), expected.awlen, expected.wstrb.size()));
    this.q_expected_host_req.push_back(expected);
    
    this.debug($sformatf("[EXPECT_HOST_AW_4] awaddr=0x%0h, next_awaddr=0x%0h, waddr=0x%0h / cur_burst_len=%0d",
      DutParamHostAddr_t'(awaddr), DutParamHostAddr_t'(next_awaddr), DutParamHostAddr_t'(waddr), cur_burst_len));
    
    // Update with NEXT
    awaddr = DutParamHostAddr_t'(next_waddr); //waddr; //next_awaddr;
    next_awaddr = calculateNextHostAddr(DutParamHostAddr_t'(awaddr), max_hburst_len, DutParamHostAddr_t'(end_awaddr));
    next_burst_len = updateCurrHostBurstLen(DutParamHostAddr_t'(awaddr), DutParamHostAddr_t'(next_awaddr));
    cur_burst_len = next_burst_len;
    
  end:while_begin_end
  // END ----------- Generate Expected HOST_AW


endfunction:post_registerNewPkt



// KTSB-26 : C2H post_updateHostData
function void vdmatb_st_c2h_sb::post_updateHostData(T_TRANS3 trans, T_TRANS2 trans2);
  YesOrNo_t fault;
  
  fault = this.checkFaultOnHostData(trans, trans2);
  
endfunction:post_updateHostData



/*
 * KTSB-21 : C2H post_updateCardData
 * calculate expected HOST_DATA from PKT_INFO and CARD_DATA
*/
function void vdmatb_st_c2h_sb::post_updateMstData(T_TRANS3 trans, T_TRANS trans2);
  static int                num_created = 0;
  T_TRANS2                  expected;
  DutParamAxiMaxLen_t       max_burst_len;
  Len_t                     pure_total_burst;
//  int       pure_total_burst;
  DutParamAxiMaxLen_t       cur_burst_len;
  Len_t                     data_len;
  Len_t                     remain_data_len;
  Addr_t                    cur_aw_addr;
  Addr_t                    next_aw_addr;
  Addr_t                    end_aw_addr;
  Addr_t                    cur_w_addr;
  Addr_t                    next_w_addr;
  HStrb_t                   wstrb;
  HData_t                   calculated_data;
  Desc_t                    desc;
  
  DataQ_t                   input_data;
  logic[7:0]                tmp_data[$];
  Data_t                    tmp_card_data;
  DataQ_t                   q_tmp_card_data;

  int                       trans2_q_data_size;
  
  this.debug("[POST_UPDATECARDDATA] calculate expected HOST_DATA from PKT_INFO and CARD_DATA");
  
  desc = trans.q_mst[0].desc;
 
  trans2_q_data_size = trans2.q_data.size(); 
  data_len        = desc.len;
  max_burst_len   = desc.axi_max_len;
  cur_aw_addr     = DutParamHostAddr_t'(desc.dst_addr);
  end_aw_addr     = DutParamHostAddr_t'(cur_aw_addr) + data_len;
  remain_data_len = data_len;
  pure_total_burst  = getTotalHostBurst(desc);
  if(desc.axi_max_len > (AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH)) max_burst_len = AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH;
  
  expected = T_TRANS2::type_id::create();
  
  this.debug($sformatf("[CAL_EXPECTED_HOST_DATA] PKT#%0d: dst_addr=%0h, max_hburst_len=%0d, len_in_byte=%0d",
    DutParamDmaId_t'(desc.dma_id), DutParamHostAddr_t'(desc.dst_addr), desc.axi_max_len, desc.len));
  
  num_created++;
  cur_burst_len = max_burst_len;
  next_aw_addr = calculateNextHostAddr(DutParamHostAddr_t'(cur_aw_addr), max_burst_len, DutParamHostAddr_t'(end_aw_addr));
  cur_burst_len = updateCurrHostBurstLen(DutParamHostAddr_t'(cur_aw_addr), DutParamHostAddr_t'(next_aw_addr));

  expected.awvalid  =  1'b1;
  expected.awready  =  1'b1;
  expected.awid     =  0; 
  expected.awaddr   =  DutParamHostAddr_t'(cur_aw_addr);
  expected.awcache  =  2;
  expected.awuser   =  {desc.fnc_id, desc.str_id};
  expected.awburst  =  1;
  expected.awlen    =  cur_burst_len -1;
  expected.dma_id   =  DutParamDmaId_t'(desc.dma_id);
   
  this.debug($sformatf("[CAL_EXPECTED_HOST_DATA] PKT#%0d: remain_data_len=%0d, cur_aw_addr=%0h, cur_burst_len=%0d, next_aw_addr=%0h",
    DutParamDmaId_t'(desc.dma_id), remain_data_len, DutParamHostAddr_t'(cur_aw_addr), cur_burst_len, DutParamHostAddr_t'(next_aw_addr)));

  cur_w_addr = DutParamHostAddr_t'(cur_aw_addr);
  
  
  while(remain_data_len) begin:while_begin_end
    for(int i=0; i<pure_total_burst; i++) begin:host_data_loop
      // START ----------- Expected WSTRB
      // First Burst
      if( remain_data_len == data_len ) begin
        if(data_len < HOST_DATA_BYTE_WIDTH) begin
          wstrb = (this.max_host_wstrb >> (HOST_DATA_BYTE_WIDTH-data_len));
          wstrb = (wstrb << DutParamHostAddr_t'(desc.dst_addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0]));
        end
        else begin
          wstrb = (this.max_host_wstrb << DutParamHostAddr_t'(desc.dst_addr[CLOG_HOST_DATA_BYTE_WIDTH-1:0]));
        end
      end
      // Middle of Bursts
      else if(remain_data_len >= HOST_DATA_BYTE_WIDTH) begin
        wstrb = this.max_host_wstrb;
      end
      // Last Burst
      else if( (remain_data_len>0) && (remain_data_len<HOST_DATA_BYTE_WIDTH) ) begin
        wstrb = ~(this.max_host_wstrb << remain_data_len);
      end
      // END ----------- Expected WSTRB
      
      remain_data_len = remain_data_len - checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(wstrb);
      next_w_addr = DutParamHostAddr_t'(cur_w_addr) + checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(wstrb);
      
      
      this.debug($sformatf("[CAL_EXPECTED_HOST_DATA_REMAIN] PKT#%0d: wstrb=%0h, remain_data_len=%0d, num_of_data=%0d",
        DutParamDmaId_t'(expected.dma_id), wstrb, remain_data_len, checkItems#(HOST_DATA_BYTE_WIDTH)::countOnes(wstrb)));
      
      // START ----------- Expected WDATA
      
      
      for(int j=0; j<HOST_DATA_BYTE_WIDTH; j++) begin
        if( tmp_data.size == 0 ) begin
          bit[HOST_DATA_WIDTH-1:0] popData;
          
          if(HOST_DATA_WIDTH > CARD_DATA_WIDTH) begin
            for(int k = 0; k < (HOST_DATA_BYTE_WIDTH / CARD_DATA_BYTE_WIDTH); k++) begin
              tmp_card_data = trans2.q_data.pop_front();
              popData[(k*CARD_DATA_WIDTH) +: CARD_DATA_WIDTH] = DutParamDataValue_t'(tmp_card_data.value);
            end
          end
          else begin
            tmp_card_data = trans2.q_data.pop_front();
            popData = tmp_card_data.value;
          end
          for(int k=0; k<HOST_DATA_BYTE_WIDTH; k++) begin
            bit[7:0] pushData;
            pushData = popData[7:0];
            
            tmp_data.push_back(pushData);
            popData = popData >> 8;
          end
        end
        if( wstrb[j]==0 ) begin
          calculated_data[HOST_DATA_WIDTH-1:HOST_DATA_WIDTH-8] = 0;
        end
        else begin
          calculated_data[HOST_DATA_WIDTH-1:HOST_DATA_WIDTH-8] = tmp_data.pop_front();
        end
        
        if( j < HOST_DATA_BYTE_WIDTH-1 ) begin 
          calculated_data = calculated_data >> 8;
        end
        
      end  // for
      
      
      this.debug($sformatf("[CAL_EXPECTED_HOST_DATA_PUSH_BACK] wstrb=%0h, remain_data_len=%0d, data=%0h, size=%0d, addr=%0h",
        wstrb, remain_data_len, calculated_data, tmp_data.size(), DutParamHostAddr_t'(cur_w_addr)));
      // END ----------- Expected WDATA
      
      expected.wdata.push_back(calculated_data[HOST_DATA_WIDTH-1:0]);
      expected.wstrb.push_back(wstrb);
      expected.waddr.push_back(DutParamHostAddr_t'(cur_w_addr));
      cur_w_addr = DutParamHostAddr_t'(next_w_addr);
      
      if( remain_data_len == 0 ) break;
      
    end:host_data_loop
  end:while_begin_end
  
  
  // Check Expected WSTRB, WADDR size
  if( checkItemsByType#(int)::compareItem("C2H_SB_WSTB_SIZE", "size", DutParamDmaId_t'(expected.dma_id), expected.wstrb.size(), expected.waddr.size()) )
    this.fatal("CAL_EXPECTED_HOST_DATA_CHECK", $sformatf("WSTRB size ERROR, (actual/expected) size=%0d/%0d", expected.wstrb.size(), expected.waddr.size()));
  
  this.debug($sformatf("[NEW_EXPECTED_HOST_DATA] PKT#%0d: wdata.size=%0d, wstrb.size=%0d, waddr.size=%0d",
    DutParamDmaId_t'(expected.dma_id), expected.wdata.size(), expected.wstrb.size(), expected.waddr.size()));
  this.q_expected_host_data.push_back(expected);
endfunction:post_updateMstData



function YesOrNo_t vdmatb_st_c2h_sb::checkFaultOnHostData(T_TRANS3 trans, T_TRANS2 trans2);
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
    this.debug($sformatf("[EXPECT_FAULT_ON_BRESP] BRESP has fault case w/ dma_id=%0d, fault_code=%0d, axi_resp=%0d, str_id=%0d, fnc_id=%0d",
      DutParamDmaId_t'(created_fault.dma_id), created_fault.code, created_fault.axi_resp, created_fault.str_id, created_fault_intr.fnc_id));

    this.q_expected_host_fault.push_back(created_fault);
    this.q_expected_host_fault_intr.push_back(created_fault_intr);
  end
  
  return(result);
endfunction:checkFaultOnHostData




task vdmatb_st_c2h_sb::cardDataChecker();
endtask:cardDataChecker


/*
 * Compare Host Data
 * TODO : move T_TRANS2 expected into function local
*/
task vdmatb_st_c2h_sb::hostDataChecker();
  T_TRANS2 actual, expected;
  
  Addr_t expected_addr;
  int cnt_aw = 0;
  int cnt_bl = 0;
  
  T_TRANS3 found;
  expected = T_TRANS2::type_id::create();

  forever begin
    wait(this.q_actual_host_data.size() > 0);
    wait(this.q_expected_host_data.size() > 0);
    

    this.debug($sformatf("[COMPARE_HOST_DATA]"));
    
    if(this.q_actual_host_data.size() > 0) begin:compare_host_data
      this.sb_flag.flag_c2h_hostData = NO;
      
      cnt_aw ++;
      cnt_bl = 0;
      
      actual = this.q_actual_host_data.pop_front();
      this.st_sb_cov_colctr.sampleAwLen(actual.awlen);
      
      if(expected.wdata.size() == 0) begin
        expected = this.q_expected_host_data.pop_front();
        expected_addr = DutParamHostAddr_t'(expected.waddr.pop_front());
      end
      
      if(this.hostDataCheck_expected_flag != NO) begin
        expected = this.q_expected_host_data.pop_front();
      end
      
      this.debug($sformatf("[COMPARE_HOST_DATA_EXPECTED] dma_id=%0d, data.szie=%0d, wstrb.size=%0d, waddr.size=%0d",
        DutParamDmaId_t'(expected.dma_id), expected.wdata.size(), expected.wstrb.size(), expected.waddr.size()));
      
      if( checkItemsByType#(DutParamHostAddr_t)::compareItem("C2H_SB_AWADDR", "awaddr", DutParamDmaId_t'(expected.dma_id), DutParamHostAddr_t'(actual.awaddr), DutParamHostAddr_t'(expected_addr)))
        this.error("COMPARE_AWADDR_ERROR", $sformatf("(actual/expected) awaddr=%0h/%0h, expected_awaddr.size=%0d", DutParamHostAddr_t'(actual.awaddr), DutParamHostAddr_t'(expected_addr), expected.waddr.size()));
      
      for(int i=0; i<actual.awlen+1; i++) begin
        HData_t actual_data, expected_data;
        HStrb_t actual_wstrb, expected_wstrb;
        
        cnt_bl ++;
        
        actual_data    = actual.wdata.pop_front();
        actual_wstrb   = actual.wstrb.pop_front();
        expected_data  = expected.wdata.pop_front();
        expected_wstrb = expected.wstrb.pop_front();
        expected_addr  = DutParamHostAddr_t'(expected.waddr.pop_front());
        
        
        this.st_sb_cov_colctr.sampleWstrb(actual_wstrb);
       
        if( checkItems#(HOST_DATA_BYTE_WIDTH)::compareItem("C2H_SB_WSTRB", "WSTRB", DutParamDmaId_t'(expected.dma_id), actual_wstrb, expected_wstrb, 0) )
          this.error("COMPARE_WSTRB_ERROR", $sformatf("PKT#%0d: (actual/expected) wstrb=%0h/%0h", DutParamDmaId_t'(expected.dma_id), actual_wstrb, expected_wstrb));
        
        if( checkItems#(HOST_DATA_WIDTH)::compareItemWithStrb("C2H_SB_HOST_DATA", "HOST_DATA", DutParamDmaId_t'(expected.dma_id), actual_data, expected_data, expected_wstrb, 0) )
          this.error("COMPARE_HOST_DATA_ERROR", $sformatf("PKT#%0d: actual_data=%0h, expected_data=%0h", DutParamDmaId_t'(expected.dma_id), actual_data, expected_data));
        
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



`endif //__VDMATB_ST_C2H_SB_SVH__
