`ifndef __VDMATB_PERF_TEST_SVH__
`define __VDMATB_PERF_TEST_SVH__


virtual class vdmatb_perf_test extends vdmatb_test;
  
  function new(string name="vdmatb_perf_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  extern virtual function string decideVseqToExecute();

  extern virtual protected function void decideTbCfg();
  extern virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
  extern virtual protected function PerfTestCtrlKnob_t randomizePerfCtrlKnob(PerfTestCtrlKnob_t ctrl_knob);
  extern virtual protected function PerfExpected_t calculateExpectedPerfResult(PerfTestCtrlKnob_t ctrl_knob);
  
  extern local function int getC2HBufSize();
  extern local function int getH2CBufSize();

  extern protected function int cal_expectedTpWithMO(YesOrNo_t crossing, AxiMaxLen_t BL, int host_side_latency);
  extern protected function int cal_expectedTpWithoutMO(Len_t len, YesOrNo_t host_addr_aligned, YesOrNo_t perf_crossing);
  extern protected function int cal_expectedC2HTpByBufferLimit(AxiMaxLen_t BL, int host_side_latency, int buf_size);
  extern protected function int cal_expectedH2CTpByBufferLimit(AxiMaxLen_t BL, int host_side_latency, int buf_size);
  extern protected function int compareMinArg3(int TP_withMO, int TP_withoutMO, int TP_byBufLimit); 
  extern protected function YesOrNo_t isBiggerThanOne(int arg);  
  
endclass:vdmatb_perf_test


function string vdmatb_perf_test::decideVseqToExecute(); return("vdmatb_perf_vseq"); endfunction
  

function void vdmatb_perf_test::decideTbCfg();
  super.decideTbCfg();
  this.test_type = PERF_TEST;
endfunction:decideTbCfg



// TODO:JW -- set the typical behaviour of the performance tests
function PerfTestCtrlKnob_t vdmatb_perf_test::makeInitialPerfCtrlKnob();
  PerfTestCtrlKnob_t made;

  made.perf_crossing               = YES;
  made.perf_host_addr_aligned      = YES;
  made.perf_c2h_len_in_byte        = 128;
  made.perf_h2c_len_in_byte        = 128;
  made.BL                          = 2;
  made.perf_desc_fire_latency      = 0;
  made.perf_card_side_data_latency = 0;
  made.perf_host_side_latency      = 0;
  made.perf_intr_latency           = 0;
  made.perf_stat_latency           = 0;
  made.perf_req_intr               = 1;
  made.perf_req_stat               = 1;
  return(made);
endfunction:makeInitialPerfCtrlKnob


function PerfTestCtrlKnob_t vdmatb_perf_test::randomizePerfCtrlKnob(PerfTestCtrlKnob_t ctrl_knob);
  parameter PERF_DATA_WIDTH = 64;
  
  ctrl_knob.perf_dst_addr = {$urandom(), $urandom()};
  ctrl_knob.perf_src_addr = {$urandom(), $urandom()};
  
  if(ctrl_knob.perf_crossing == YES) begin
    ctrl_knob.perf_c2h_len_in_byte = ctrl_knob.perf_c2h_len_in_byte;
    ctrl_knob.perf_h2c_len_in_byte = ctrl_knob.perf_h2c_len_in_byte;
    
    if(ctrl_knob.perf_host_addr_aligned == NO) begin
      ctrl_knob.perf_dst_addr[5:0] = $urandom();
      ctrl_knob.perf_src_addr[5:0] = $urandom();
      
      return(ctrl_knob);
    end//NOT aligned
    else begin
      ctrl_knob.perf_dst_addr[5:0] = 0;
      ctrl_knob.perf_src_addr[5:0] = 0;
      
      return(ctrl_knob);
    end// aligned
  end//crossing
  else begin
    ctrl_knob.perf_c2h_len_in_byte = $urandom_range(1, PERF_DATA_WIDTH);
    ctrl_knob.perf_h2c_len_in_byte = $urandom_range(1, PERF_DATA_WIDTH);
    ctrl_knob.perf_dst_addr[5:0]   = $urandom_range(0, PERF_DATA_WIDTH - ctrl_knob.perf_c2h_len_in_byte);
    ctrl_knob.perf_src_addr[5:0]   = $urandom_range(0, PERF_DATA_WIDTH - ctrl_knob.perf_h2c_len_in_byte);
    
    return(ctrl_knob);
  end//else
endfunction:randomizePerfCtrlKnob


function PerfExpected_t vdmatb_perf_test::calculateExpectedPerfResult(PerfTestCtrlKnob_t ctrl_knob);
  PerfExpected_t result;
  int c2h_buf_size, h2c_buf_size;
  string data_direction;
  
  c2h_buf_size = this.getC2HBufSize();
  h2c_buf_size = this.getH2CBufSize();
  
  result.c2h_throughput_with_MO = this.cal_expectedTpWithMO(ctrl_knob.perf_crossing, ctrl_knob.BL, ctrl_knob.perf_host_side_latency);
  result.h2c_throughput_with_MO = this.cal_expectedTpWithMO(ctrl_knob.perf_crossing, ctrl_knob.BL, ctrl_knob.perf_host_side_latency);

  result.c2h_throughput_without_MO = this.cal_expectedTpWithoutMO(ctrl_knob.perf_c2h_len_in_byte, ctrl_knob.perf_host_addr_aligned, ctrl_knob.perf_crossing); 
  result.h2c_throughput_without_MO = this.cal_expectedTpWithoutMO(ctrl_knob.perf_h2c_len_in_byte, ctrl_knob.perf_host_addr_aligned, ctrl_knob.perf_crossing);

  result.c2h_throughput_by_buf_limit = this.cal_expectedC2HTpByBufferLimit(ctrl_knob.BL, ctrl_knob.perf_host_side_latency, c2h_buf_size);
  result.h2c_throughput_by_buf_limit = this.cal_expectedH2CTpByBufferLimit(ctrl_knob.BL, ctrl_knob.perf_host_side_latency, h2c_buf_size);

  result.c2h_throughput = this.compareMinArg3(result.c2h_throughput_with_MO, result.c2h_throughput_without_MO, result.c2h_throughput_by_buf_limit);
  result.h2c_throughput = this.compareMinArg3(result.h2c_throughput_with_MO, result.h2c_throughput_without_MO, result.h2c_throughput_by_buf_limit);

  result.error_ratio = 10;
  return(result);
endfunction



function int vdmatb_perf_test::cal_expectedTpWithoutMO(Len_t len, YesOrNo_t host_addr_aligned, YesOrNo_t perf_crossing);
  int len_divided; // len_in_byte / 64
  int result;
 
  if(perf_crossing == NO) begin
    result = 32 * 8 * DMA_FREQUENCY_MHZ / 1000;
    return(result);
  end
  else begin
    if(host_addr_aligned) begin
      len_divided = len / 64; 
      result = len * 8 * DMA_FREQUENCY_MHZ / len_divided / 1000;
      return(result);
    end
    else begin
      len_divided = len / 64;
      if(len % 64 != 0) len_divided++;
      len_divided = len_divided + 1;
      
      result = len * 8 * DMA_FREQUENCY_MHZ / len_divided / 1000;
      return(result);
    end
  end
  
endfunction : cal_expectedTpWithoutMO


function int vdmatb_perf_test::cal_expectedTpWithMO(YesOrNo_t crossing, AxiMaxLen_t BL, int host_side_latency);
  int result;
  
  if(host_side_latency == 0) host_side_latency = 1;
 
  if(crossing == YES) result = (((DMA_WR_MO * HOST_DATA_WIDTH * BL) / host_side_latency) * 250) / 1000;
  else                result = (((DMA_WR_MO * HOST_DATA_WIDTH * BL / 2) / host_side_latency) * 250) / 1000; // Total_len of non_crossing perf_test is half of PERF_REASONABLE_LEN
  
  return(result);
endfunction:cal_expectedTpWithMO


function int vdmatb_perf_test::cal_expectedC2HTpByBufferLimit(AxiMaxLen_t BL, int host_side_latency, int buf_size);
  real      result;
  YesOrNo_t isBiggerThanOne = NO;
  
  if(host_side_latency == 0) host_side_latency = 1;

  isBiggerThanOne = this.isBiggerThanOne(buf_size / (host_side_latency + 2 * BL));

  if(isBiggerThanOne == NO) result = HOST_DATA_WIDTH * buf_size / (host_side_latency + 2 * BL) * 250 / 1000;
  else                      result = HOST_DATA_WIDTH * 1 * 250 / 1000;
 
  return($rtoi(int'(result)));
endfunction : cal_expectedC2HTpByBufferLimit



function int vdmatb_perf_test::cal_expectedH2CTpByBufferLimit(AxiMaxLen_t BL, int host_side_latency, int buf_size);
  real      result;
  YesOrNo_t isBiggerThanOne = NO;
  
  if(host_side_latency == 0) host_side_latency = 1;
  
  isBiggerThanOne = this.isBiggerThanOne(buf_size / (host_side_latency + 3 * BL));
  
  if(isBiggerThanOne == NO) result = HOST_DATA_WIDTH * buf_size / (host_side_latency + 3 * BL) * 250 / 1000;
  else                      result = HOST_DATA_WIDTH * 1 * 250 / 1000;
  
  return($rtoi(int'(result)));
endfunction : cal_expectedH2CTpByBufferLimit



function int vdmatb_perf_test::getC2HBufSize();
  int c2h_buf_size = 0;
  
  case(this.tcfg.getDmaIpType)
    ST : begin
      StDmaDesignParam_t ST_DUT_PARAM;
      
      ST_DUT_PARAM = this.tcfg.getStDmaDutParam();
      c2h_buf_size = ST_DUT_PARAM.C2H_BUF_DEPTH;
    end
    MM : begin
      MmDmaDesignParam_t MM_DUT_PARAM;
      
      MM_DUT_PARAM = this.tcfg.getMmDmaDutParam();
      c2h_buf_size = MM_DUT_PARAM.C2H_BUF_DEPTH;
    end
    default : this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endcase
  
  if(c2h_buf_size == 0) this.fatal("DUT BUF_SIZE FATAL", $sformatf("C2H_BUF_DEPTH=%1d cannot be 0", c2h_buf_size));
  
  return(c2h_buf_size);
endfunction : getC2HBufSize


function int vdmatb_perf_test::getH2CBufSize();
  int h2c_buf_size = 0;
  
  case(this.tcfg.getDmaIpType)
    ST : begin
      StDmaDesignParam_t ST_DUT_PARAM;
      
      ST_DUT_PARAM = this.tcfg.getStDmaDutParam();
      h2c_buf_size = ST_DUT_PARAM.H2C_BUF_DEPTH;
    end
    MM : begin
      MmDmaDesignParam_t MM_DUT_PARAM;
      
      MM_DUT_PARAM = this.tcfg.getMmDmaDutParam();
      h2c_buf_size = MM_DUT_PARAM.H2C_BUF_DEPTH;
    end
    default : this.fatal("NOT_SUPPORTED", $sformatf("DMA IP Type is %s, but it is not supported !!", this.tcfg.getDmaIpType));
  endcase
  
  if(h2c_buf_size == 0) this.fatal("DUT BUF_SIZE FATAL", $sformatf("H2C_BUF_DEPTH=%1d cannot be 0", h2c_buf_size));
  
  return(h2c_buf_size);
endfunction : getH2CBufSize


function int vdmatb_perf_test::compareMinArg3(int TP_withMO, int TP_withoutMO, int TP_byBufLimit);
  if(TP_withMO <= TP_withoutMO && TP_withMO <= TP_byBufLimit)         return(TP_withMO);
  else if(TP_withoutMO <= TP_withMO && TP_withoutMO <= TP_byBufLimit) return(TP_withoutMO);
  else                                                                return(TP_byBufLimit);
endfunction


function YesOrNo_t vdmatb_perf_test::isBiggerThanOne(int arg);
  if(arg < 1) return(NO);
  else        return(YES);
endfunction : isBiggerThanOne

`endif // __VDMATB_PERF_TEST_SVH__
