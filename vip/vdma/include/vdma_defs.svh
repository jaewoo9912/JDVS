`ifndef __VDMA_DEFS_SV__
`define __VDMA_DEFS_SV__


  typedef Data_t      DataList_t[];
  typedef CData_t    cDataList_t[];
  typedef HData_t    hDataList_t[];

  typedef Data_t      DataQ_t[$];
  typedef CData_t    cDataQ_t[$];
  typedef HData_t    hDataQ_t[$];

  localparam logic[21:0] MAX_DMA_SIZE_FOR_COV = 22'h3f_ffff;
  localparam int WRONG_DMA_ID                 = 10000;
  
  typedef enum {
    INTER_RESET_TEST 		    = 0,
    NORMAL_TEST		          = 1,
    PERF_TEST               = 2,
    ASYMMETRIC_LATENCY_TEST = 3,
    FAULT_TEST              = 4
  }TestType_t;
  
  typedef enum {
    DEFAULT_SCHEME	    = 0,
    IDEAL   				    = 1,
    ON_DELAY_WO_RESP 		= 2,
    FOR_REGRESSION      = 3
  }TestScheme_t;
  
  typedef enum {
    SAME_NORMAL_OPERATION	      = 1,
    CARD_R_NO_LAST_FAULT        = 2,
    CARD_R_PREMATURE_LAST_FAULT = 3,
    HOST_R_NO_LAST_FAULT        = 4,
    HOST_R_PREMATURE_LAST_FAULT = 5,
    HAS_WRONG_DMA_ID_FAULT	    = 6,
    ALL_RANDOM_FAULT            = 7
  }SelectFault_t;
  
 
  typedef struct packed{
    int WEIGHT_DESC_DATA_LENGTH_IS_ZERO;
    int WEIGHT_DESC_MID_OF_PKT_BEFORE_START_OF_PKT;
    int WEIGHT_DESC_SOLO_OF_PKT_DURING_GATHERING;
    int WEIGHT_DESC_START_OF_PKT_DURING_GATHERING;
    int WEIGHT_DESC_END_OF_PKT_BEFORE_START_PKT;
    int WEIGHT_CARD_R_PREMATURE_LAST;
    int WEIGHT_CARD_R_NO_LAST;
    int WEIGHT_CARD_R_WRONG_MTY;
    int WEIGHT_CARD_R_WRONG_DMA_ID;
    int WEIGHT_CARD_R_WRONG_RESP;
    int WEIGHT_CARD_B_WRONG_RESP;
    int WEIGHT_CARD_CORRECT_RESP;
    int WEIGHT_HOST_R_WRONG_RESP;
    int WEIGHT_HOST_B_WRONG_RESP;
    int WEIGHT_HOST_CORRECT_RESP;
  }RatioFaultInjection_t;
  
  typedef real FaultProb_t;
  typedef int  OccuIntendedFault_t;
  
  
  typedef struct{
    YesOrNo_t intended_fault  = NO;
    YesOrNo_t following_trans = NO;
    int       gen_faultType   = -1;
  }SampleLstForFault_t;
  
  typedef struct{
    YesOrNo_t       perf_crossing;
    YesOrNo_t       perf_host_addr_aligned;
    
    Len_t           perf_c2h_len_in_byte;
    Len_t           perf_h2c_len_in_byte;
    Addr_t          perf_dst_addr;
    Addr_t          perf_src_addr;
    Addr_t          perf_card_dst_addr;
    Addr_t          perf_card_src_addr;
    logic           perf_req_intr, perf_req_stat;
    
    int             perf_host_side_latency;
    int             perf_card_side_data_latency;
    int             perf_desc_fire_latency;
    int             perf_intr_latency, perf_stat_latency;
    
    AxiMaxLen_t     BL;
  }PerfTestCtrlKnob_t;

  typedef struct{
	  int c2h_throughput_with_MO;
	  int h2c_throughput_with_MO;	  
	  int c2h_throughput_without_MO;
	  int h2c_throughput_without_MO;	
    int c2h_throughput_by_buf_limit;
    int h2c_throughput_by_buf_limit;
	  int c2h_throughput;
	  int h2c_throughput;
	  int error_ratio;
  }PerfExpected_t;
  
  typedef struct packed{
    int max_throughput;
    int min_throughput;
  }PerfExpectedThroughputRange_t;

  typedef struct{
    YesOrNo_t flag_cardData;
    YesOrNo_t flag_c2h_hostData;
    YesOrNo_t flag_h2c_hostData;
    YesOrNo_t flag_cardIntr;
    YesOrNo_t flag_cardStat;

    YesOrNo_t flag_descFaultStat;
    YesOrNo_t flag_cardFaultStat;
    YesOrNo_t flag_hostFaultStat;
    YesOrNo_t flag_descFaultIntr;
    YesOrNo_t flag_cardFaultIntr;
    YesOrNo_t flag_hostFaultIntr;
  }ScoreboardFlag_t;
 
 
  typedef struct{
    logic[5:0]    src_addr_low_6bits;
    logic[11:0]   src_addr_low_12bits;
    logic[11:0]   src_addr_aligned;
    logic[5:0]    dst_addr_low_6bits;
    logic[11:0]   dst_addr_low_12bits;
    logic[11:0]   dst_addr_aligned;
    logic[5:0]    c2h_lenInByte_low_6bits;
    logic[11:0]   c2h_lenInByte_low_12bits;
    logic[8:0]    c2h_max_hburst_len;
    logic[8:0]    c2h_max_cburst_len;
    logic[11:0]   c2h_BL2;
    logic[11:0]   c2h_card_BL2;
    logic[5:0]    c2h_split_on_BL_modulo;
    logic[4:0]    num_split_on_4K_Boundary;
    logic[5:0]    c2h_split_on_card_BL_modulo;
    logic[4:0]    num_split_on_card_4K_Boundary;
  }FuncCovC2H_t;



  typedef struct{
    logic[5:0]    src_addr_low_6bits;
    logic[11:0]   src_addr_low_12bits;
    logic[11:0]   src_addr_aligned;
    logic[5:0]    dst_addr_low_6bits;
    logic[11:0]   dst_addr_low_12bits;
    logic[11:0]   dst_addr_aligned;
    logic[5:0]    h2c_lenInByte_low_6bits;
    logic[11:0]   h2c_lenInByte_low_12bits;
    logic[8:0]    h2c_max_hburst_len;
    logic[8:0]    h2c_max_cburst_len;
    logic[11:0]   h2c_BL2;
    logic[11:0]   h2c_card_BL2;
    logic[5:0]    h2c_split_on_BL_modulo;
    logic[4:0]    num_split_on_4K_Boundary;
    logic[5:0]    h2c_split_on_card_BL_modulo;
    logic[4:0]    num_split_on_card_4K_Boundary;
  }FuncCovH2C_t;
    

  
  typedef struct{
    UIntRange_t desc2desc;
    UIntRange_t data_assert_rdy;
    UIntRange_t status_assert_rdy;
    UIntRange_t interrupt_assert_rdy;
    UIntRange_t fault_assert_rdy;
  }StH2CDmaBfmTimingParam_t;


  typedef struct{
    UIntRange_t desc2desc;
    UIntRange_t data2data;
    UIntRange_t status_assert_rdy;
    UIntRange_t interrupt_assert_rdy;
    UIntRange_t fault_assert_rdy;
  }StC2HDmaBfmTimingParam_t;


  typedef struct{
    UIntRange_t desc2desc;
    UIntRange_t status_assert_rdy;
    UIntRange_t interrupt_assert_rdy;
    UIntRange_t fault_assert_rdy;
  }MmH2CDmaBfmTimingParam_t;
  
  typedef MmH2CDmaBfmTimingParam_t MmC2HDmaBfmTimingParam_t; 

  localparam UIntRange_t DEFAULT_BFM_TIMING_RANGE = '{
    start_value : 0,
    end_value   : 15 
  };

  localparam StH2CDmaBfmTimingParam_t DEFAULT_ST_H2C_DMA_BFM_TIMING_PARAM = '{
    desc2desc            : DEFAULT_BFM_TIMING_RANGE,
    data_assert_rdy      : DEFAULT_BFM_TIMING_RANGE,
    status_assert_rdy    : DEFAULT_BFM_TIMING_RANGE,
    interrupt_assert_rdy : DEFAULT_BFM_TIMING_RANGE,
    fault_assert_rdy     : DEFAULT_BFM_TIMING_RANGE
  };

  localparam StC2HDmaBfmTimingParam_t DEFAULT_ST_C2H_DMA_BFM_TIMING_PARAM = '{
    desc2desc            : DEFAULT_BFM_TIMING_RANGE,
    data2data            : DEFAULT_BFM_TIMING_RANGE,
    status_assert_rdy    : DEFAULT_BFM_TIMING_RANGE,
    interrupt_assert_rdy : DEFAULT_BFM_TIMING_RANGE,
    fault_assert_rdy     : DEFAULT_BFM_TIMING_RANGE
  };
  
  localparam MmH2CDmaBfmTimingParam_t DEFAULT_MM_H2C_DMA_BFM_TIMING_PARAM = '{
    desc2desc            : DEFAULT_BFM_TIMING_RANGE,
    status_assert_rdy    : DEFAULT_BFM_TIMING_RANGE,
    interrupt_assert_rdy : DEFAULT_BFM_TIMING_RANGE,
    fault_assert_rdy     : DEFAULT_BFM_TIMING_RANGE
  };

  localparam MmC2HDmaBfmTimingParam_t DEFAULT_MM_C2H_DMA_BFM_TIMING_PARAM = '{
    desc2desc            : DEFAULT_BFM_TIMING_RANGE,
    status_assert_rdy    : DEFAULT_BFM_TIMING_RANGE,
    interrupt_assert_rdy : DEFAULT_BFM_TIMING_RANGE,
    fault_assert_rdy     : DEFAULT_BFM_TIMING_RANGE
  };
  
  
  localparam UIntRange_t IDEAL_BFM_TIMING_RANGE = '{
    start_value : 0,
    end_value   : 0 
  };

  localparam StH2CDmaBfmTimingParam_t IDEAL_ST_H2C_DMA_BFM_TIMING_PARAM = '{
    desc2desc            : IDEAL_BFM_TIMING_RANGE,
    data_assert_rdy      : IDEAL_BFM_TIMING_RANGE,
    status_assert_rdy    : IDEAL_BFM_TIMING_RANGE,
    interrupt_assert_rdy : IDEAL_BFM_TIMING_RANGE,
    fault_assert_rdy     : IDEAL_BFM_TIMING_RANGE
  };

  localparam StC2HDmaBfmTimingParam_t IDEAL_ST_C2H_DMA_BFM_TIMING_PARAM = '{
    desc2desc            : IDEAL_BFM_TIMING_RANGE,
    data2data            : IDEAL_BFM_TIMING_RANGE,
    status_assert_rdy    : IDEAL_BFM_TIMING_RANGE,
    interrupt_assert_rdy : IDEAL_BFM_TIMING_RANGE,
    fault_assert_rdy     : IDEAL_BFM_TIMING_RANGE
  };
  
  localparam MmH2CDmaBfmTimingParam_t IDEAL_MM_H2C_DMA_BFM_TIMING_PARAM = '{
    desc2desc            : IDEAL_BFM_TIMING_RANGE,
    status_assert_rdy    : IDEAL_BFM_TIMING_RANGE,
    interrupt_assert_rdy : IDEAL_BFM_TIMING_RANGE,
    fault_assert_rdy     : IDEAL_BFM_TIMING_RANGE
  };

  localparam MmC2HDmaBfmTimingParam_t IDEAL_MM_C2H_DMA_BFM_TIMING_PARAM = '{
    desc2desc            : IDEAL_BFM_TIMING_RANGE,
    status_assert_rdy    : IDEAL_BFM_TIMING_RANGE,
    interrupt_assert_rdy : IDEAL_BFM_TIMING_RANGE,
    fault_assert_rdy     : IDEAL_BFM_TIMING_RANGE
  };
  
  localparam UIntRange_t PERF_INTR_TIMING_RANGE = '{
    start_value : 625,
    end_value   : 625 
  };
  
  
  localparam UIntRange_t PERF_STAT_TIMING_RANGE = '{
    start_value : 300,
    end_value   : 300 
  };
  
  localparam StC2HDmaBfmTimingParam_t ST_PERF_C2H_IDEAL_LATENCY = '{
    desc2desc            : IDEAL_BFM_TIMING_RANGE,
    data2data            : IDEAL_BFM_TIMING_RANGE,
    status_assert_rdy    : IDEAL_BFM_TIMING_RANGE,
    interrupt_assert_rdy : IDEAL_BFM_TIMING_RANGE,
    fault_assert_rdy     : IDEAL_BFM_TIMING_RANGE
  };
  
  localparam StC2HDmaBfmTimingParam_t ST_PERF_C2H_LONG_LATENCY = '{
    desc2desc            : IDEAL_BFM_TIMING_RANGE,
    data2data            : IDEAL_BFM_TIMING_RANGE,
    status_assert_rdy    : PERF_STAT_TIMING_RANGE,
    interrupt_assert_rdy : PERF_INTR_TIMING_RANGE,
    fault_assert_rdy     : IDEAL_BFM_TIMING_RANGE
  };


  localparam StH2CDmaBfmTimingParam_t ST_PERF_H2C_IDEAL_LATENCY = '{
    desc2desc            : IDEAL_BFM_TIMING_RANGE,
    data_assert_rdy      : IDEAL_BFM_TIMING_RANGE,
    status_assert_rdy    : IDEAL_BFM_TIMING_RANGE,
    interrupt_assert_rdy : IDEAL_BFM_TIMING_RANGE,
    fault_assert_rdy     : IDEAL_BFM_TIMING_RANGE
  };
  
  
  localparam StH2CDmaBfmTimingParam_t ST_PERF_H2C_LONG_LATENCY = '{
    desc2desc            : IDEAL_BFM_TIMING_RANGE,
    data_assert_rdy      : IDEAL_BFM_TIMING_RANGE,
    status_assert_rdy    : PERF_STAT_TIMING_RANGE,
    interrupt_assert_rdy : PERF_INTR_TIMING_RANGE,
    fault_assert_rdy     : IDEAL_BFM_TIMING_RANGE
  };
  
  
  localparam MmC2HDmaBfmTimingParam_t MM_PERF_C2H_IDEAL_LATENCY = '{
    desc2desc            : IDEAL_BFM_TIMING_RANGE,
    status_assert_rdy    : IDEAL_BFM_TIMING_RANGE,
    interrupt_assert_rdy : IDEAL_BFM_TIMING_RANGE,
    fault_assert_rdy     : IDEAL_BFM_TIMING_RANGE
  };
  
  localparam MmC2HDmaBfmTimingParam_t MM_PERF_C2H_LONG_LATENCY = '{
    desc2desc            : IDEAL_BFM_TIMING_RANGE,
    status_assert_rdy    : PERF_STAT_TIMING_RANGE,
    interrupt_assert_rdy : PERF_INTR_TIMING_RANGE,
    fault_assert_rdy     : IDEAL_BFM_TIMING_RANGE
  };


  localparam MmH2CDmaBfmTimingParam_t MM_PERF_H2C_IDEAL_LATENCY = '{
    desc2desc            : IDEAL_BFM_TIMING_RANGE,
    status_assert_rdy    : IDEAL_BFM_TIMING_RANGE,
    interrupt_assert_rdy : IDEAL_BFM_TIMING_RANGE,
    fault_assert_rdy     : IDEAL_BFM_TIMING_RANGE
  };
  
  
  localparam MmH2CDmaBfmTimingParam_t MM_PERF_H2C_LONG_LATENCY = '{
    desc2desc            : IDEAL_BFM_TIMING_RANGE,
    status_assert_rdy    : PERF_STAT_TIMING_RANGE,
    interrupt_assert_rdy : PERF_INTR_TIMING_RANGE,
    fault_assert_rdy     : IDEAL_BFM_TIMING_RANGE
  };



  localparam UIntRange_t ASYMMETRIC_ZERO_TYPE = '{
    start_value : 0,
    end_value   : 0
  };
  
  localparam UIntRange_t ASYMMETRIC_DESC_NORMAL_TYPE = '{
    start_value : 0,
    end_value   : 16
  };
  
  localparam UIntRange_t ASYMMETRIC_DESC_LONG_TYPE = '{
    start_value : 64,
    end_value   : 128
  };
  
  localparam UIntRange_t ASYMMETRIC_DESC_RANDOM_TYPE = '{
    start_value : 0,
    end_value   : 128
  };
  
  localparam UIntRange_t ASYMMETRIC_DATA_NORMAL_TYPE = '{
    start_value : 0,
    end_value   : 16
  };
  
  localparam UIntRange_t ASYMMETRIC_DATA_LONG_TYPE = '{
    start_value : 17,
    end_value   : 32
  };
  
  localparam UIntRange_t ASYMMETRIC_DATA_RANDOM_TYPE = '{
    start_value : 0,
    end_value   : 32
  };
  
  localparam UIntRange_t ASYMMETRIC_INTR_NORMAL_TYPE = '{
    start_value : 0,
    end_value   : 128
  };
  
  localparam UIntRange_t ASYMMETRIC_INTR_LONG_TYPE = '{
    start_value : 129,
    end_value   : 256
  };
  
  localparam UIntRange_t ASYMMETRIC_INTR_RANDOM_TYPE = '{
    start_value : 0,
    end_value   : 256
  };
  
  localparam UIntRange_t ASYMMETRIC_STAT_NORMAL_TYPE = '{
    start_value : 0,
    end_value   : 100
  };
  
  localparam UIntRange_t ASYMMETRIC_STAT_LONG_TYPE = '{
    start_value : 101,
    end_value   : 300
  };
  
  localparam UIntRange_t ASYMMETRIC_STAT_RANDOM_TYPE = '{
    start_value : 0,
    end_value   : 300
  };
  


  typedef enum int{
   DMA_INVALID,
   DMA_ON_DATA_PHASE,  
   DMA_ON_RESP_PHASE, // there could be state/interrupt if the corresponding descriptor is so
   DMA_COMPLETED_WO_CONSIDERING_FAULT,
   DMA_DESC_HAS_DROP_FAULT,
   DMA_READY_TO_COMPLETED,
   DMA_COMPLETED
  }DmaTransStatus_t;


  typedef enum int{
    NOT_ON_PKT_GATHERING,
    START_OF_PKT_GATHERING,
    INTERMEDIATE_PKT_GATHERING,
    END_OF_PKT_GATHERING,
    UNDEFINED_PKT_GATHERING_STATUS
  }DmaTransPktGatheringStatusType_t;
  
  typedef enum int{
   INVALID_PHASE,
   ON_DESC_PHASE,
   ON_CARD_DATA_PHASE,
   ON_HOST_DATA_PHASE,
   ON_CARD_RESP_PHASE
  }DmaPktStatus_t;
  
  typedef enum int{
    DMA_ZERO_LATENCY   = 1,
    DMA_NORMAL_LATENCY = 2,
    DMA_LONG_LATENCY   = 3,
    DMA_RANDOM_LATENCY = 4
  }DmaLatencyType_t;

  typedef struct{
    YesOrNo_t only_c2h_test = YES;
    YesOrNo_t only_h2c_test = YES;
  }DataDirectionType_t;

`endif // __VDMA_DEFS_SV__
