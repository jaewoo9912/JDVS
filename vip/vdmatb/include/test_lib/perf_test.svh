`ifndef  __PERF_TEST_SVH__
`define  __PERF_TEST_SVH__



class perf_test extends vdmatb_test;
  
  `uvm_component_utils(perf_test)
  
  function new(string name="perf_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();
    return("vdmatb_perf_vseq");
  endfunction
  
  extern virtual function void build_phase(uvm_phase phase);
  
  extern protected virtual function void post_createTcfg(vt4_tcfg m_tcfg);
  
  extern protected function PerfTestCrtlKnob_t cal_perfLenNAddr(PerfTestCrtlKnob_t me);
  extern protected function PerfExpected_t cal_perfExpectedTp(PerfTestCrtlKnob_t me);
  extern protected function int cal_expectedTpWithMO(AxiMaxLen_t BL, int host_side_latency);
  extern protected function int cal_expectedTpWithoutMO(Len_t len, YesOrNo_t host_addr_aligned, YesOrNo_t perf_crossing);
  extern protected function int compareMin(int TP_withMO, int TP_withoutMO); 
endclass:perf_test


function void perf_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  $cast(this.scfg, this.m_scfg);
endfunction


function void perf_test::post_createTcfg(vt4_tcfg m_tcfg);
  string cfgdb_key;
  super.post_createTcfg(m_tcfg);
  
  this.test_type = PERF_TEST;
  `vmg_get_cfgdb_anyone(string, "cfgdb_key", cfgdb_key)
  `vmg_set_cfgdb_anyone(TestType_t, $sformatf("%s_test_type", cfgdb_key), this.test_type)
  
//	uvm_config_db#(TestType_t)::set(uvm_root::get(), "*", $sformatf("%s_test_type", family_name), this.test_type);
endfunction : post_createTcfg


function PerfTestCrtlKnob_t perf_test::cal_perfLenNAddr(PerfTestCrtlKnob_t me);
  parameter PERF_DATA_WIDTH = 64;
  PerfTestCrtlKnob_t perf_ctrl_knob;
  
  perf_ctrl_knob = me;
  
  perf_ctrl_knob.perf_dst_addr = {$urandom(), $urandom()};
  perf_ctrl_knob.perf_src_addr = {$urandom(), $urandom()};
  
  if(perf_ctrl_knob.perf_crossing == YES) begin
    perf_ctrl_knob.perf_c2h_len_in_byte = perf_ctrl_knob.perf_c2h_len_in_byte;
    perf_ctrl_knob.perf_h2c_len_in_byte = perf_ctrl_knob.perf_h2c_len_in_byte;
    
    if(perf_ctrl_knob.perf_host_addr_aligned == NO) begin
      perf_ctrl_knob.perf_dst_addr[5:0] = $urandom();
      perf_ctrl_knob.perf_src_addr[5:0] = $urandom();
      
      return(perf_ctrl_knob);
    end//NOT aligned
    else begin
      perf_ctrl_knob.perf_dst_addr[5:0] = 0;
      perf_ctrl_knob.perf_src_addr[5:0] = 0;
      
      return(perf_ctrl_knob);
    end// aligned
  end//crossing
  else begin
    perf_ctrl_knob.perf_c2h_len_in_byte = $urandom_range(1, PERF_DATA_WIDTH);
    perf_ctrl_knob.perf_h2c_len_in_byte = $urandom_range(1, PERF_DATA_WIDTH);
    perf_ctrl_knob.perf_dst_addr[5:0]   = $urandom_range(0, PERF_DATA_WIDTH - perf_ctrl_knob.perf_c2h_len_in_byte);
    perf_ctrl_knob.perf_src_addr[5:0]   = $urandom_range(0, PERF_DATA_WIDTH - perf_ctrl_knob.perf_h2c_len_in_byte);
    
    return(perf_ctrl_knob);
  end//else
  
endfunction : cal_perfLenNAddr


function PerfExpected_t perf_test::cal_perfExpectedTp(PerfTestCrtlKnob_t me);
  PerfExpected_t perf_expected;
  
  perf_expected.c2h_throughput_with_MO = this.cal_expectedTpWithMO(me.BL, me.perf_host_side_latency);
  perf_expected.h2c_throughput_with_MO = this.cal_expectedTpWithMO(me.BL, me.perf_host_side_latency);

  perf_expected.c2h_throughput_without_MO = this.cal_expectedTpWithoutMO(me.perf_c2h_len_in_byte, me.perf_host_addr_aligned, me.perf_crossing); 
  perf_expected.h2c_throughput_without_MO = this.cal_expectedTpWithoutMO(me.perf_h2c_len_in_byte, me.perf_host_addr_aligned, me.perf_crossing);

  perf_expected.c2h_throughput = this.compareMin(perf_expected.c2h_throughput_with_MO, perf_expected.c2h_throughput_without_MO);
  perf_expected.h2c_throughput = this.compareMin(perf_expected.h2c_throughput_with_MO, perf_expected.h2c_throughput_without_MO);
  
  return(perf_expected);
endfunction



function int perf_test::cal_expectedTpWithoutMO(Len_t len, YesOrNo_t host_addr_aligned, YesOrNo_t perf_crossing);
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
      len_divided = len / 64 + 1;
      result = len * 8 * DMA_FREQUENCY_MHZ / len_divided / 1000;
      return(result);
    end
  end
  
endfunction : cal_expectedTpWithoutMO


function int perf_test::cal_expectedTpWithMO(AxiMaxLen_t BL, int host_side_latency);
  int result;
  
  if(host_side_latency == 0)
    host_side_latency = 1;
  
  result = (((DMA_WR_MO * HOST_DATA_WIDTH * BL) / host_side_latency) * 250) / 1000;
  return(result);
endfunction:cal_expectedTpWithMO


function int perf_test::compareMin(int TP_withMO, int TP_withoutMO);
  if(TP_withMO < TP_withoutMO) begin
    return(TP_withMO);
  end
  else if(TP_withMO > TP_withoutMO) begin
    return(TP_withoutMO);
  end
  else
    this.fatal("PERF_TEST", "TP_withMO value is same as TP_witoutMO value");
endfunction

`endif // __PERF_TEST_SVH__
