`ifndef __VDMA_SA_MM_MON_SVH__
`define __VDMA_SA_MM_MON_SVH__




virtual class vdma_sa_mm_mon extends vdma_sa_mon;
  
  
  function new(string name="vdma_sa_mm_mon", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // ------------------------------------ vdma_sa_mm_mon-api
  extern virtual protected function vdma_seq_item findTrans_WithAxiTrans(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  extern virtual protected function vdma_seq_item findTrans_ForGetDesc(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  extern virtual local function void updateH2CNumData(T_TRANS found_trans);
  // ---------------------------- vdma_sa_mm_mon-impl
  extern virtual function void collectData();
  extern virtual function void collectFault();
  
  pure virtual function CaxiData_t extractNewCaxiData();
  
  extern virtual function CStrbQ_t cal_ExpectedCardStrb(Desc_t desc);
  
  extern protected function Len_t               getTotalBurst(Len_t len, Addr_t addr);
  extern protected function DutParamAxiMaxLen_t updateCurBurstLen(Addr_t cAddr, Addr_t nAddr);
  extern protected function Addr_t              calculateNextAddr(Addr_t addr, DutParamAxiMaxLen_t maxBurstLen, Addr_t end_addr);
  extern protected function int                 countOnesInQueue(logic[CARD_DATA_BYTE_WIDTH-1:0] inData);
endclass:vdma_sa_mm_mon



function void vdma_sa_mm_mon::collectData(); endfunction:collectData


function void vdma_sa_mm_mon::collectFault();
  T_TRANS found_trans;
  Fault_t being_collected;
  
  if(this.observedNewFault)begin
    being_collected = this.extractNewFault();

    case(being_collected.code)
      DESC_DATA_LENGTH_IS_ZERO :found_trans = this.configureFaultTransOnDropCase(being_collected);
      default                  :found_trans = this.configureFaultTransOnNormalCase(being_collected);
    endcase
    
    this.ap_fault.write(found_trans);
  end
endfunction : collectFault




function vdma_seq_item vdma_sa_mm_mon::findTrans_WithAxiTrans(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  string assembled_call_info;
  
  assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, dma_id);
  
  foreach(this.q_active[i]) begin
    this.debug($sformatf("findTrans_WithAxTrans(call_info=[%s]) this.q_active[%1d]=[%s]", assembled_call_info, i, this.q_active[i].getInfo));
    
    if(trans_status == DMA_ON_DATA_PHASE && DutParamDmaId_t'(dma_id) == this.q_active[i].getDmaId)
      return(this.q_active[i]);
  end
endfunction : findTrans_WithAxiTrans



function vdma_seq_item vdma_sa_mm_mon::findTrans_ForGetDesc(DmaTransStatus_t trans_status, DmaId_t dma_id, string call_info);
  vdma_seq_item found;
 
  found = this.findTrans_WithAxiTrans(trans_status, DutParamDmaId_t'(dma_id), call_info);
  if(found == null) begin
    string assembled_call_info;
    assembled_call_info = $sformatf("%s %s dma_id=%1d", call_info, trans_status.name, DutParamDmaId_t'(dma_id));
    this.reportFatal(
     $sformatf("%s_NO_CORRESPOND_TRANS", this.mon_name), 
       $sformatf("Cannot find the corresponding transaction for call_info=[%s]", assembled_call_info)
       );
    
  end
  
  return(found);
endfunction




function void vdma_sa_mm_mon::updateH2CNumData(T_TRANS found_trans); endfunction



function ddma_pkg::Len_t vdma_sa_mm_mon::getTotalBurst(Len_t len, Addr_t addr);
  Len_t result;
  
  if( (len + DutParamCardAddr_t'(addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0])) <= CARD_DATA_BYTE_WIDTH )
    result = 1;
  else begin
    result = ((len + DutParamCardAddr_t'(addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0])) / CARD_DATA_BYTE_WIDTH);
    if(len + DutParamCardAddr_t'(addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0]) % CARD_DATA_BYTE_WIDTH != 0) result++;
  end
  
  return(result);
endfunction : getTotalBurst


function ddma_pkg::Addr_t vdma_sa_mm_mon::calculateNextAddr(Addr_t addr, DutParamAxiMaxLen_t maxBurstLen, Addr_t end_addr);
  Addr_t next_addr;
  
  next_addr = addr + (maxBurstLen * CARD_DATA_BYTE_WIDTH);
  if (DutParamCardAddr_t'(end_addr) < DutParamCardAddr_t'(addr)) begin
    if (DutParamCardAddr_t'(next_addr) < 16'h1000) begin
      if (DutParamCardAddr_t'(next_addr) > DutParamCardAddr_t'(end_addr)) next_addr = DutParamCardAddr_t'(end_addr);
    end
  end
  else begin
    if (DutParamCardAddr_t'(next_addr) > DutParamCardAddr_t'(end_addr)) next_addr = DutParamCardAddr_t'(end_addr);
  end

  if ((DutParamCardAddr_t'(addr[11:0]) != 12'h0) && (DutParamCardAddr_t'(addr[12]) != DutParamCardAddr_t'(next_addr[12]))) //To Check 4K Boundary
     next_addr = {next_addr[pdma_dut_pkg::CARD_ADDR_WIDTH -1 :12],12'h000};

  return (DutParamCardAddr_t'(next_addr));
endfunction : calculateNextAddr


function DutParamAxiMaxLen_t vdma_sa_mm_mon::updateCurBurstLen(Addr_t cAddr, Addr_t nAddr);
  DutParamAxiMaxLen_t burstLen;
  
  burstLen = (DutParamCardAddr_t'(nAddr) + (CARD_DATA_BYTE_WIDTH - 1) - DutParamCardAddr_t'(cAddr)) / CARD_DATA_BYTE_WIDTH;

  if(burstLen > 256)
    burstLen = 256;
   
  return (burstLen);
endfunction



function CStrbQ_t vdma_sa_mm_mon::cal_ExpectedCardStrb(Desc_t desc);
  int                 max_cburst_len;
  int                 cur_burst_len;
  int                 next_burst_len;
  Len_t               total_burst_len;
  Len_t               data_len;
  Len_t               remain_data_len;
  Addr_t              addr;
  Addr_t              next_addr;
  Addr_t              next_axaddr;
  Addr_t              end_addr;
  Addr_t              cur_addr;
  CStrb_t             wstrb, max_wstrb, q_wstrb[$];
  
  data_len        = desc.len;
  
  if(this.getTransType == MM_H2C)      addr = DutParamCardAddr_t'(desc.dst_addr);
  else if(this.getTransType == MM_C2H) addr = DutParamCardAddr_t'(desc.src_addr);
  max_wstrb       = 1;
  
  for(int i = 0; i < CARD_DATA_BYTE_WIDTH; i++)
    max_wstrb = (max_wstrb << 1) | 1;
  
  end_addr        = DutParamCardAddr_t'(addr) + data_len;
  remain_data_len = data_len;
  total_burst_len = this.getTotalBurst(data_len, addr);
  
  max_cburst_len = 256;
  
  cur_burst_len = max_cburst_len;
  next_addr     = this.calculateNextAddr(DutParamCardAddr_t'(addr), max_cburst_len, DutParamCardAddr_t'(end_addr));
  cur_burst_len = updateCurBurstLen(addr, next_addr);
 
  cur_addr = DutParamCardAddr_t'(addr);
  
  while(remain_data_len) begin
    for(int i = 0; i < cur_burst_len; i++) begin
      if(remain_data_len == data_len) begin
        if(data_len < CARD_DATA_BYTE_WIDTH) begin
          wstrb = (max_wstrb >> (CARD_DATA_BYTE_WIDTH - data_len));
          wstrb = (wstrb << DutParamCardAddr_t'(addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0]));
        end
        else begin
          wstrb = (max_wstrb << DutParamCardAddr_t'(addr[CLOG_CARD_DATA_BYTE_WIDTH-1:0]));
        end
      end // First Burst
      else if(remain_data_len >= CARD_DATA_BYTE_WIDTH) begin
        wstrb = max_wstrb;
      end // Middle
      else if( (remain_data_len > 0) && (remain_data_len < CARD_DATA_BYTE_WIDTH) ) begin
        wstrb = ~(max_wstrb << remain_data_len);
      end // End
     
      remain_data_len = remain_data_len - this.countOnesInQueue(wstrb);
      next_addr       = DutParamCardAddr_t'(cur_addr) + this.countOnesInQueue(wstrb);
      
      q_wstrb.push_back(wstrb);
      
      if(remain_data_len == 0)
        return(q_wstrb);
      
    end//for_cur_burst_len
    
    addr = DutParamCardAddr_t'(next_addr);
    next_axaddr = this.calculateNextAddr(DutParamCardAddr_t'(addr), max_cburst_len, DutParamCardAddr_t'(end_addr));
    next_burst_len = this.updateCurBurstLen(DutParamCardAddr_t'(addr), DutParamCardAddr_t'(next_axaddr));

    if(next_axaddr == addr) this.fatal("NEXT_ADDR cannot be same as CURRENT_ADDR", $sformatf("next_addr=0x%h, current_addr=0x%h", next_axaddr, addr));

    cur_burst_len = next_burst_len;
  end//while
  
endfunction




function int vdma_sa_mm_mon::countOnesInQueue(logic[CARD_DATA_BYTE_WIDTH-1:0] inData);
  int count;
  
  for(int i = 0; i < CARD_DATA_BYTE_WIDTH; i++)
    count = count + inData[i];
  
  return(count);
endfunction : countOnesInQueue


`endif // __VDMA_SA_MM_MON_SVH__
