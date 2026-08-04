`ifndef __VDMATB_VWRAP_PKG_SV__
`define __VDMATB_VWRAP_PKG_SV__


package vdmatb_vwrap_pkg;

  `vdmatb_import_core_pkg
 

  `ifdef DMA_ST_SYMMETRIC_BASIC_DUT_PKG 
    `define DUT_NAME dma_st_symmetric_basic
    `define DUT_PKG `DUT_NAME``_dut_pkg
  `elsif DMA_ST_SYMMETRIC_HDW128_DUT_PKG 
    `define DUT_NAME dma_st_symmetric_hdw128
    `define DUT_PKG `DUT_NAME``_dut_pkg
  `elsif DMA_ST_ASYMMETRIC_CDW32_DUT_PKG 
    `define DUT_NAME dma_st_asymmetric_cdw32
    `define DUT_PKG `DUT_NAME``_dut_pkg
  `elsif DMA_ST_ASYMMETRIC_HDW128_CDW16_DUT_PKG 
    `define DUT_NAME dma_st_asymmetric_hdw128_cdw16
    `define DUT_PKG `DUT_NAME``_dut_pkg
  `elsif DMA_MM_SYMMETRIC_BASIC_DUT_PKG
    `define DUT_NAME dma_mm_symmetric_basic
    `define DUT_PKG `DUT_NAME``_dut_pkg
  `elsif DMA_MM_ASYMMETRIC_CDW32_DUT_PKG
    `define DUT_NAME dma_mm_asymmetric_cdw32
    `define DUT_PKG `DUT_NAME``_dut_pkg
  `else  //-------------------------------------  Default Set
    `define DUT_NAME dma_st_symmetric_basic
    `define DUT_PKG `DUT_NAME``_dut_pkg
  `endif 
  

  localparam StDmaDesignParam_t ST_DUT_PARAM = '{
    C2H_BUF_DEPTH          : `DUT_PKG::C2H_BUF_DEPTH,
    H2C_BUF_DEPTH          : `DUT_PKG::H2C_BUF_DEPTH,
    HAXI_WMO               : `DUT_PKG::HAXI_WMO,
    HAXI_RMO               : `DUT_PKG::HAXI_RMO,
    C2H_DESCR_TABLE_SIZE   : `DUT_PKG::C2H_DESCR_TABLE_SIZE,
    H2C_DESCR_TABLE_SIZE   : `DUT_PKG::H2C_DESCR_TABLE_SIZE,
    C2H_POST_FIFO_DEPTH    : `DUT_PKG::C2H_POST_FIFO_DEPTH,
    H2C_POST_FIFO_DEPTH    : `DUT_PKG::H2C_POST_FIFO_DEPTH,
    C2H_START_W_FIFO_DEPTH : `DUT_PKG::C2H_START_W_FIFO_DEPTH,
    H2C_START_W_FIFO_DEPTH : `DUT_PKG::H2C_START_W_FIFO_DEPTH,
    AXI_ID_WIDTH           : `DUT_PKG::AXI_ID_WIDTH,
    HAXI_ADDR_WIDTH        : `DUT_PKG::HAXI_ADDR_WIDTH,
    AXI_DATA_WIDTH         : `DUT_PKG::AXI_DATA_WIDTH,
    AXIS_ID_WIDTH          : `DUT_PKG::AXIS_ID_WIDTH,
    AXIS_DATA_WIDTH        : `DUT_PKG::AXIS_DATA_WIDTH,
    DMA_ID_WIDTH           : `DUT_PKG::DMA_ID_WIDTH,
    // ----------------- Not used in DmaST, just default
    CAXI_ADDR_WIDTH        : `DUT_PKG::CAXI_ADDR_WIDTH,
    CAXI_WMO               : `DUT_PKG::CAXI_WMO,
    CAXI_RMO               : `DUT_PKG::CAXI_RMO
  };

  localparam MmDmaDesignParam_t MM_DUT_PARAM = '{
    C2H_BUF_DEPTH          : `DUT_PKG::C2H_BUF_DEPTH,
    H2C_BUF_DEPTH          : `DUT_PKG::H2C_BUF_DEPTH,
    HAXI_WMO               : `DUT_PKG::HAXI_WMO,
    HAXI_RMO               : `DUT_PKG::HAXI_RMO,
    C2H_DESCR_TABLE_SIZE   : `DUT_PKG::C2H_DESCR_TABLE_SIZE,
    H2C_DESCR_TABLE_SIZE   : `DUT_PKG::H2C_DESCR_TABLE_SIZE,
    C2H_POST_FIFO_DEPTH    : `DUT_PKG::C2H_POST_FIFO_DEPTH,
    H2C_POST_FIFO_DEPTH    : `DUT_PKG::H2C_POST_FIFO_DEPTH,
    C2H_START_W_FIFO_DEPTH : `DUT_PKG::C2H_START_W_FIFO_DEPTH,
    H2C_START_W_FIFO_DEPTH : `DUT_PKG::H2C_START_W_FIFO_DEPTH,
    AXI_ID_WIDTH           : `DUT_PKG::AXI_ID_WIDTH,
    HAXI_ADDR_WIDTH        : `DUT_PKG::HAXI_ADDR_WIDTH,
    AXI_DATA_WIDTH         : `DUT_PKG::AXI_DATA_WIDTH,
    AXIS_ID_WIDTH          : `DUT_PKG::AXIS_ID_WIDTH,
    AXIS_DATA_WIDTH        : `DUT_PKG::AXIS_DATA_WIDTH,
    DMA_ID_WIDTH           : `DUT_PKG::DMA_ID_WIDTH,
    CAXI_ADDR_WIDTH        : `DUT_PKG::CAXI_ADDR_WIDTH,
    CAXI_WMO               : `DUT_PKG::CAXI_WMO,
    CAXI_RMO               : `DUT_PKG::CAXI_RMO
  };

  localparam AxiPortParam_t HOST_AXI_PORT_PARAM ='{
    PROTCL_TYPE  : PROTCL_AXI4,
    ID_WIDTH     : ST_DUT_PARAM.AXI_ID_WIDTH,
    ADDR_WIDTH   : ST_DUT_PARAM.HAXI_ADDR_WIDTH,
    DATA_WIDTH   : ST_DUT_PARAM.AXI_DATA_WIDTH,
    LEN_WIDTH    : 8,
    USER_WIDTH   : 16,
    MAX_OT_RD    : ST_DUT_PARAM.HAXI_RMO,
    MAX_OT_WR    : ST_DUT_PARAM.HAXI_WMO,
    MAX_ID_VALUE : 0,
    MAX_NUM_BEAT : 256
  };


  localparam AxiPortParam_t CARD_AXI_PORT_PARAM ='{
    PROTCL_TYPE  : PROTCL_AXI4,
    ID_WIDTH     : MM_DUT_PARAM.AXI_ID_WIDTH,
    ADDR_WIDTH   : MM_DUT_PARAM.CAXI_ADDR_WIDTH,
    DATA_WIDTH   : MM_DUT_PARAM.AXI_DATA_WIDTH,
    LEN_WIDTH    : 8,
    USER_WIDTH   : 16,
    MAX_OT_RD    : MM_DUT_PARAM.CAXI_RMO,
    MAX_OT_WR    : MM_DUT_PARAM.CAXI_WMO,
    MAX_ID_VALUE : 0,
    MAX_NUM_BEAT : 256
  };
  
endpackage:vdmatb_vwrap_pkg




`endif // __VDMATB_VWRAP_PKG_SV__
