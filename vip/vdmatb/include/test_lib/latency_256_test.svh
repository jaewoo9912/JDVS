`ifndef  __LATENCY_256_TEST_SVH__
`define  __LATENCY_256_TEST_SVH__


class latency_256_test extends vdmatb_test;
	
  `uvm_component_utils(latency_256_test)
  
  function new(string name="latency_256_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();

    return("vdmatb_random_vseq");

  endfunction
  
  extern virtual local function StH2CDmaBfmTimingParam_t decideStH2CDmaBfmTimingParam();
  extern virtual local function MmH2CDmaBfmTimingParam_t decideMmH2CDmaBfmTimingParam();
  	
endclass:latency_256_test

localparam UIntRange_t LONG_LATENCY = '{
	start_value : 256,
	end_value : 256 
};

localparam StH2CDmaBfmTimingParam_t LONG_LATENCY_256 = '{
	  desc2desc            : LONG_LATENCY,
    data_assert_rdy      : LONG_LATENCY,
    status_assert_rdy    : LONG_LATENCY,
    interrupt_assert_rdy : LONG_LATENCY,
    fault_assert_rdy     : LONG_LATENCY
};

function StH2CDmaBfmTimingParam_t latency_256_test::decideStH2CDmaBfmTimingParam();
	return(LONG_LATENCY_256);
endfunction:decideStH2CDmaBfmTimingParam
	

localparam MmH2CDmaBfmTimingParam_t MM_LONG_LATENCY_256 = '{
	  desc2desc            : LONG_LATENCY,
    status_assert_rdy    : LONG_LATENCY,
    interrupt_assert_rdy : LONG_LATENCY,
    fault_assert_rdy     : LONG_LATENCY
};

function MmH2CDmaBfmTimingParam_t latency_256_test::decideMmH2CDmaBfmTimingParam();
	return(MM_LONG_LATENCY_256);
endfunction:decideMmH2CDmaBfmTimingParam
	





`endif // __LATENCY_256_TEST_SVH__
