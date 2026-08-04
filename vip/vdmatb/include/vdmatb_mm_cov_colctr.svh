`ifndef __VDMATB_MM_COV_COLCTR_SVH__
`define __VDMATB_MM_COV_COLCTR_SVH__

class vdmatb_mm_cov_colctr extends vmg_obj;

  PerfTestCtrlKnob_t  perf_ctrl_knob;
  PerfExpected_t      perf_expected;
  
  PdmaC2HPerfResult_t c2h_specific_result;
  PdmaH2CPerfResult_t h2c_specific_result;
  
  covergroup cg_perf_result;
    single_actual_c2h_throughput : coverpoint this.c2h_specific_result.c2h_throughput {
      bins range1 = {[1:15]};
      bins range2 = {[20:30]};
      bins range3 = {[25:30]};
      bins range4 = {[60:90]};
      bins range5 = {[110:128]};
    }

    single_actual_h2c_throughput : coverpoint this.h2c_specific_result.h2c_throughput {
      bins range1 = {[1:15]};
      bins range2 = {[20:30]};
      bins range3 = {[25:30]};
      bins range4 = {[60:90]};
      bins range5 = {[110:128]};
    }

    single_expected_c2h_throughput : coverpoint this.perf_expected.c2h_throughput {
      bins range1 = {[1:15]};
      bins range2 = {[20:30]};
      bins range3 = {[25:30]};
      bins range4 = {[60:90]};
      bins range5 = {[110:128]};
    }
  
    single_expected_h2c_throughput : coverpoint this.perf_expected.h2c_throughput {
      bins range1 = {[1:15]};
      bins range2 = {[20:30]};
      bins range3 = {[25:30]};
      bins range4 = {[60:90]};
      bins range5 = {[110:128]};
    }
   
  endgroup
  
  

  covergroup cg_perf_scenario;
    c2h_len_in_byte : coverpoint (this.perf_ctrl_knob.perf_c2h_len_in_byte) {
      bins perf_c2h_len_in_byte[] = {[1:64]};
      bins perf_c2h_len_in_byte_128 = {128};
      bins perf_c2h_len_in_byte_1500 = {1500};
      bins perf_c2h_len_in_byte_32768 = {32768};
    }
    
    h2c_len_in_byte : coverpoint (this.perf_ctrl_knob.perf_h2c_len_in_byte) {
      bins perf_h2c_len_in_byte[] = {[1:64]};
      bins perf_h2c_len_in_byte_128 = {128};
      bins perf_h2c_len_in_byte_1500 = {1500};
      bins perf_h2c_len_in_byte_32768 = {32768};
    }
    
    h2c_src_addr : coverpoint (DutParamHostAddr_t'(this.perf_ctrl_knob.perf_src_addr[5:0])) {
      bins perf_h2c_src_addr[] = {[0:pdma_dut_pkg::HOST_ADDR_WIDTH-1]};
    }
    
    c2h_dst_addr : coverpoint (DutParamHostAddr_t'(this.perf_ctrl_knob.perf_dst_addr[5:0])) {
      bins perf_c2h_dst_addr[] = {[0:pdma_dut_pkg::HOST_ADDR_WIDTH-1]};
    }
    
    req_intr : coverpoint (this.perf_ctrl_knob.perf_req_intr) {
      bins perf_req_intr[] = {1};
    }

    req_stat : coverpoint (this.perf_ctrl_knob.perf_req_stat) {
      bins perf_req_stat[] = {1};
    }

    host_side_latency : coverpoint (this.perf_ctrl_knob.perf_host_side_latency) {
      bins min_perf_host_side_latency[] = {0};
      bins max_perf_host_side_latency[] = {550};
    }

    card_side_data_latency : coverpoint (this.perf_ctrl_knob.perf_card_side_data_latency) {
      bins perf_card_side_data_latency[] = {0};
    }

    desc_fire_latency : coverpoint (this.perf_ctrl_knob.perf_desc_fire_latency) {
      bins perf_desc_fire_latency[] = {0};
    }

    intr_latency : coverpoint (this.perf_ctrl_knob.perf_intr_latency) {
      bins min_perf_intr_latency[] = {0};
      bins max_perf_intr_latency[] = {625};
    }

    stat_latency : coverpoint (this.perf_ctrl_knob.perf_stat_latency) {
      bins min_perf_stat_latency[] = {0};
      bins max_perf_stat_latency[] = {300};
    }

  endgroup
  
  `uvm_object_utils(vdmatb_mm_cov_colctr) 
  function new (string name = "vdmatb_mm_cov_colctr");
    super.new(name);
    cg_perf_scenario = new();
    cg_perf_result = new();
  endfunction
  
  extern function void set_C2HActualResult(PdmaC2HPerfResult_t me);
  extern function void set_H2CActualResult(PdmaH2CPerfResult_t me);
  extern function void set_PerfExpected_CP(vdmatb_scfg scfg);
  extern function void set_PerfScenario_CP(vdmatb_scfg scfg);
  
  extern function void sampleActualPerfResult();
  extern function void samplePerfScenario(vdmatb_scfg scfg);
  
endclass


function void vdmatb_mm_cov_colctr::set_C2HActualResult(PdmaC2HPerfResult_t me);
  this.c2h_specific_result = me;
endfunction


function void vdmatb_mm_cov_colctr::set_H2CActualResult(PdmaH2CPerfResult_t me);
  this.h2c_specific_result = me;
endfunction



function void vdmatb_mm_cov_colctr::sampleActualPerfResult();
  cg_perf_result.sample();
endfunction


function void vdmatb_mm_cov_colctr::set_PerfExpected_CP(vdmatb_scfg scfg);
  this.perf_expected.c2h_throughput  = scfg.perf_expected.c2h_throughput;
  this.perf_expected.h2c_throughput  = scfg.perf_expected.h2c_throughput;
endfunction : set_PerfExpected_CP


function void vdmatb_mm_cov_colctr::set_PerfScenario_CP(vdmatb_scfg scfg);
  this.perf_ctrl_knob.perf_c2h_len_in_byte        = scfg.perf_ctrl_knob.perf_c2h_len_in_byte;
  this.perf_ctrl_knob.perf_h2c_len_in_byte        = scfg.perf_ctrl_knob.perf_h2c_len_in_byte;
  this.perf_ctrl_knob.perf_dst_addr               = scfg.perf_ctrl_knob.perf_dst_addr;
  this.perf_ctrl_knob.perf_src_addr               = scfg.perf_ctrl_knob.perf_src_addr;
  this.perf_ctrl_knob.perf_req_intr               = scfg.perf_ctrl_knob.perf_req_intr;
  this.perf_ctrl_knob.perf_req_stat               = scfg.perf_ctrl_knob.perf_req_stat;
  this.perf_ctrl_knob.perf_host_side_latency      = scfg.perf_ctrl_knob.perf_host_side_latency;
  this.perf_ctrl_knob.perf_card_side_data_latency = scfg.perf_ctrl_knob.perf_card_side_data_latency;
  this.perf_ctrl_knob.perf_desc_fire_latency      = scfg.perf_ctrl_knob.perf_desc_fire_latency;
  this.perf_ctrl_knob.perf_intr_latency           = scfg.perf_ctrl_knob.perf_intr_latency;
  this.perf_ctrl_knob.perf_stat_latency           = scfg.perf_ctrl_knob.perf_stat_latency;
endfunction : set_PerfScenario_CP


function void vdmatb_mm_cov_colctr::samplePerfScenario(vdmatb_scfg scfg);
  this.set_PerfScenario_CP(scfg);
  cg_perf_scenario.sample();
endfunction : samplePerfScenario



`endif //__VDMATB_MM_COV_COLCTR_SVH__

