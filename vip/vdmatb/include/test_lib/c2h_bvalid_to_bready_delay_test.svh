`ifndef  __C2H_BVALID_TO_BREADY_DELAY_TEST_SVH__
`define  __C2H_BVALID_TO_BREADY_DELAY_TEST_SVH__


class c2h_bvalid_to_bready_delay_test extends vdmatb_test;
	
  `uvm_component_utils(c2h_bvalid_to_bready_delay_test)
  
  function new(string name="c2h_bvalid_to_bready_delay_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();

    return("vdmatb_c2h_bvalid_to_bready_delay_vseq");

  endfunction
  
  protected virtual function void decideDataDirectionType();
    this.data_direction_type.only_c2h_test = YES;
    this.data_direction_type.only_h2c_test = NO;
  endfunction
  
  extern virtual local function StC2HDmaBfmTimingParam_t decideStC2HDmaBfmTimingParam();
  extern virtual local function MmC2HDmaBfmTimingParam_t decideMmC2HDmaBfmTimingParam();
endclass:c2h_bvalid_to_bready_delay_test

localparam UIntRange_t BRESP_IDEAL_LATENCY = '{
	start_value : 0,
	end_value   : 0
};

localparam UIntRange_t BRESP_LONG_LATENCY = '{
	start_value : 1024,
	end_value : 1024
};

localparam StC2HDmaBfmTimingParam_t BRESP_LONG_LATENCY_256 = '{
    desc2desc            : BRESP_IDEAL_LATENCY,
    data2data  		       : BRESP_IDEAL_LATENCY,
    status_assert_rdy    : BRESP_LONG_LATENCY,
    interrupt_assert_rdy : BRESP_IDEAL_LATENCY,
    fault_assert_rdy     : BRESP_IDEAL_LATENCY
};

function StC2HDmaBfmTimingParam_t c2h_bvalid_to_bready_delay_test::decideStC2HDmaBfmTimingParam();
	return(BRESP_LONG_LATENCY_256);
endfunction:decideStC2HDmaBfmTimingParam
	
localparam MmC2HDmaBfmTimingParam_t MM_BRESP_LONG_LATENCY_256 = '{
    desc2desc            : BRESP_IDEAL_LATENCY,
    status_assert_rdy    : BRESP_LONG_LATENCY,
    interrupt_assert_rdy : BRESP_IDEAL_LATENCY,
    fault_assert_rdy     : BRESP_IDEAL_LATENCY
};

function MmC2HDmaBfmTimingParam_t c2h_bvalid_to_bready_delay_test::decideMmC2HDmaBfmTimingParam();
	return(MM_BRESP_LONG_LATENCY_256);
endfunction:decideMmC2HDmaBfmTimingParam
	
	




`endif // __C2H_BVALID_TO_BREADY_DELAY_TEST_SVH__
