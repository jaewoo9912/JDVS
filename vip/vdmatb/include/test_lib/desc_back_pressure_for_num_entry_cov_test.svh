`ifndef  __DESC_BACK_PRESSURE_FOR_NUM_ENTRY_COV_TEST_SVH__
`define  __DESC_BACK_PRESSURE_FOR_NUM_ENTRY_COV_TEST_SVH__


class desc_back_pressure_for_num_entry_cov_test extends vdmatb_test;
	
  `uvm_component_utils(desc_back_pressure_for_num_entry_cov_test)
  
  function new(string name="desc_back_pressure_for_num_entry_cov_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual function string decideVseqToExecute();

    return("vdmatb_desc_back_pressure_for_num_entry_cov_vseq");

  endfunction
  
  extern virtual local function StC2HDmaBfmTimingParam_t decideStC2HDmaBfmTimingParam();
  extern virtual local function StH2CDmaBfmTimingParam_t decideStH2CDmaBfmTimingParam();
  extern virtual local function MmC2HDmaBfmTimingParam_t decideMmC2HDmaBfmTimingParam();
  extern virtual local function MmH2CDmaBfmTimingParam_t decideMmH2CDmaBfmTimingParam();

endclass:desc_back_pressure_for_num_entry_cov_test


localparam UIntRange_t NUM_ENTRY_COV_IDEAL_LATENCY = '{
	start_value : 0,
	end_value   : 0
};

localparam UIntRange_t NUM_ENTRY_COV_LONG_INTR_LATENCY = '{
	
	start_value : 5000,
	end_value   : 5000
};

localparam StC2HDmaBfmTimingParam_t ST_C2H_NUM_ENTRY_COV_LATENCY = '{
    desc2desc            : NUM_ENTRY_COV_IDEAL_LATENCY,
    data2data  		       : NUM_ENTRY_COV_IDEAL_LATENCY,
    status_assert_rdy    : NUM_ENTRY_COV_IDEAL_LATENCY,
    interrupt_assert_rdy : NUM_ENTRY_COV_LONG_INTR_LATENCY,
    fault_assert_rdy     : NUM_ENTRY_COV_IDEAL_LATENCY
};

localparam StH2CDmaBfmTimingParam_t ST_H2C_NUM_ENTRY_COV_LATENCY = '{
    desc2desc            : NUM_ENTRY_COV_IDEAL_LATENCY,
    data_assert_rdy      : NUM_ENTRY_COV_IDEAL_LATENCY,
    status_assert_rdy    : NUM_ENTRY_COV_IDEAL_LATENCY,
    interrupt_assert_rdy : NUM_ENTRY_COV_LONG_INTR_LATENCY,
    fault_assert_rdy     : NUM_ENTRY_COV_IDEAL_LATENCY
};

localparam MmC2HDmaBfmTimingParam_t MM_C2H_NUM_ENTRY_COV_LATENCY = '{
    desc2desc            : NUM_ENTRY_COV_IDEAL_LATENCY,
    status_assert_rdy    : NUM_ENTRY_COV_IDEAL_LATENCY,
    interrupt_assert_rdy : NUM_ENTRY_COV_LONG_INTR_LATENCY,
    fault_assert_rdy     : NUM_ENTRY_COV_IDEAL_LATENCY
};

localparam MmH2CDmaBfmTimingParam_t MM_H2C_NUM_ENTRY_COV_LATENCY = '{
    desc2desc            : NUM_ENTRY_COV_IDEAL_LATENCY,
    status_assert_rdy    : NUM_ENTRY_COV_IDEAL_LATENCY,
    interrupt_assert_rdy : NUM_ENTRY_COV_LONG_INTR_LATENCY,
    fault_assert_rdy     : NUM_ENTRY_COV_IDEAL_LATENCY
};


function StC2HDmaBfmTimingParam_t desc_back_pressure_for_num_entry_cov_test::decideStC2HDmaBfmTimingParam();
	return(ST_C2H_NUM_ENTRY_COV_LATENCY);
endfunction:decideStC2HDmaBfmTimingParam


function StH2CDmaBfmTimingParam_t desc_back_pressure_for_num_entry_cov_test::decideStH2CDmaBfmTimingParam();
	return(ST_H2C_NUM_ENTRY_COV_LATENCY);
endfunction:decideStH2CDmaBfmTimingParam


function MmC2HDmaBfmTimingParam_t desc_back_pressure_for_num_entry_cov_test::decideMmC2HDmaBfmTimingParam();
	return(MM_C2H_NUM_ENTRY_COV_LATENCY);
endfunction:decideMmC2HDmaBfmTimingParam


function MmH2CDmaBfmTimingParam_t desc_back_pressure_for_num_entry_cov_test::decideMmH2CDmaBfmTimingParam();
	return(MM_H2C_NUM_ENTRY_COV_LATENCY);
endfunction:decideMmH2CDmaBfmTimingParam

`endif // __DESC_BACK_PRESSURE_FOR_NUM_ENTRY_COV_TEST_SVH__
