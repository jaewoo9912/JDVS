`ifndef __VDMA_UTILS_SVH__
`define __VDMA_UTILS_SVH__





  function automatic StringQ_t MakeStringList_StDmaDesignParam_t(StDmaDesignParam_t me);
    StringQ_t result;
  
    result.push_back($sformatf("----------------------------------------------------------------"));
    result.push_back($sformatf(" ** DESIGN_PARAMETER"));
    result.push_back($sformatf("----------------------------------------------------------------"));
    result.push_back($sformatf("     - c2h_buf_depth/descr_table_size/post_fifo/start_w_fifo: %1d/%1d/%1d/%1d",
      me.C2H_BUF_DEPTH, me.C2H_DESCR_TABLE_SIZE, me.C2H_POST_FIFO_DEPTH, me.C2H_START_W_FIFO_DEPTH
    ));
    result.push_back($sformatf("     - h2c_buf_depth/descr_table_size/post_fifo/start_w_fifo: %1d/%1d/%1d/%1d",
      me.H2C_BUF_DEPTH, me.H2C_DESCR_TABLE_SIZE, me.H2C_POST_FIFO_DEPTH, me.H2C_START_W_FIFO_DEPTH
    ));
    result.push_back($sformatf("     - AXI master port max. read/write outstanding: %1d/%1d",
      me.HAXI_RMO, me.HAXI_WMO
    ));
    result.push_back($sformatf("     - AXI I/F ID/ADDR/DATA width: %1d/%1d/%1d",
      me.AXI_ID_WIDTH,
      me.HAXI_ADDR_WIDTH,
      me.AXI_DATA_WIDTH
    ));
    result.push_back($sformatf("    - AXIS I/F ID/DATA width: %1d/%1d",
      me.AXIS_ID_WIDTH,
      me.AXIS_DATA_WIDTH
    ));
  
    return(result);
  endfunction:MakeStringList_StDmaDesignParam_t
  
  
  
  
  
  function automatic StringQ_t MakeStringList_MmDmaDesignParam_t(MmDmaDesignParam_t me);
    StringQ_t result;
  
    result.push_back($sformatf("----------------------------------------------------------------"));
    result.push_back($sformatf(" ** DESIGN_PARAMETER"));
    result.push_back($sformatf("----------------------------------------------------------------"));
    result.push_back($sformatf("     - c2h_buf_depth/descr_table_size/post_fifo/start_w_fifo: %1d/%1d/%1d/%1d",
      me.C2H_BUF_DEPTH, me.C2H_DESCR_TABLE_SIZE, me.C2H_POST_FIFO_DEPTH, me.C2H_START_W_FIFO_DEPTH
    ));
    result.push_back($sformatf("     - h2c_buf_depth/descr_table_size/post_fifo/start_w_fifo: %1d/%1d/%1d/%1d",
      me.H2C_BUF_DEPTH, me.H2C_DESCR_TABLE_SIZE, me.H2C_POST_FIFO_DEPTH, me.H2C_START_W_FIFO_DEPTH
    ));
    result.push_back($sformatf("     - AXI master port max. read/write outstanding: %1d/%1d",
      me.HAXI_RMO, me.HAXI_WMO
    ));
    result.push_back($sformatf("     - AXI I/F ID/ADDR/DATA width: %1d/%1d/%1d",
      me.AXI_ID_WIDTH,
      me.HAXI_ADDR_WIDTH,
      me.AXI_DATA_WIDTH
    ));
    result.push_back($sformatf("    - AXIS I/F ID/DATA width: %1d/%1d",
      me.AXIS_ID_WIDTH,
      me.AXIS_DATA_WIDTH
    ));
  
    return(result);
  endfunction:MakeStringList_MmDmaDesignParam_t
  
  
  
  
  
  function automatic StringQ_t MakeStringList_StH2CDmaBfmTimingParam_t(StH2CDmaBfmTimingParam_t me);
    StringQ_t result;
    
    result.push_back($sformatf("----------------------------------------------------------------"));
    result.push_back($sformatf(" ** H2C_BFM_TIMING_PARAM"));
    result.push_back($sformatf("----------------------------------------------------------------"));
    result.push_back($sformatf("     -  DESC to DESC issuing interval  : %s", MakeString_UIntRange_t(me.desc2desc,            " cycles(s)")));
    result.push_back($sformatf("     -  DATA ready assertion           : %s", MakeString_UIntRange_t(me.data_assert_rdy,      " cycles(s)")));
    result.push_back($sformatf("     -  STATUS ready assertion         : %s", MakeString_UIntRange_t(me.status_assert_rdy   , " cycles(s)")));
    result.push_back($sformatf("     -  INTERRUPT ready assertion      : %s", MakeString_UIntRange_t(me.interrupt_assert_rdy, " cycles(s)")));
    result.push_back($sformatf("     -  FAULT ready assertion          : %s", MakeString_UIntRange_t(me.fault_assert_rdy    , " cycles(s)")));
    result.push_back($sformatf("----------------------------------------------------------------"));
  
    return(result);
  endfunction:MakeStringList_StH2CDmaBfmTimingParam_t
  
  
  
  
  
  function automatic StringQ_t MakeStringList_StC2HDmaBfmTimingParam_t(StC2HDmaBfmTimingParam_t me);
    StringQ_t result;
    
    result.push_back($sformatf("----------------------------------------------------------------"));
    result.push_back($sformatf(" ** C2H_BFM_TIMING_PARAM"));
    result.push_back($sformatf("----------------------------------------------------------------"));
    result.push_back($sformatf("     -  DESC to DESC issuing interval : %s", MakeString_UIntRange_t(me.desc2desc,            " cycles(s)")));
    //result.push_back($sformatf("     -  DESC to DATA latency          : %s", MakeString_UIntRange_t(me.desc2data,            " cycles(s)")));
    result.push_back($sformatf("     -  DATA to DATA issuing interval : %s", MakeString_UIntRange_t(me.data2data,            " cycles(s)")));
    result.push_back($sformatf("     -  status ready assertion        : %s", MakeString_UIntRange_t(me.status_assert_rdy   , " cycles(s)")));
    result.push_back($sformatf("     -  interrupt ready assertion     : %s", MakeString_UIntRange_t(me.interrupt_assert_rdy, " cycles(s)")));
    result.push_back($sformatf("     -  fault ready assertion         : %s", MakeString_UIntRange_t(me.fault_assert_rdy    , " cycles(s)")));
    result.push_back($sformatf("----------------------------------------------------------------"));
  
    return(result);
  endfunction:MakeStringList_StC2HDmaBfmTimingParam_t
  
  
  
  
  
  function automatic StringQ_t MakeStringList_MmH2CDmaBfmTimingParam_t(MmH2CDmaBfmTimingParam_t me);
    StringQ_t result;
    
    result.push_back($sformatf("----------------------------------------------------------------"));
    result.push_back($sformatf(" ** H2C_BFM_TIMING_PARAM"));
    result.push_back($sformatf("----------------------------------------------------------------"));
    result.push_back($sformatf("     -  DESC to DESC issuing interval  : %s", MakeString_UIntRange_t(me.desc2desc,            " cycles(s)")));
    result.push_back($sformatf("     -  STATUS ready assertion         : %s", MakeString_UIntRange_t(me.status_assert_rdy   , " cycles(s)")));
    result.push_back($sformatf("     -  INTERRUPT ready assertion      : %s", MakeString_UIntRange_t(me.interrupt_assert_rdy, " cycles(s)")));
    result.push_back($sformatf("     -  FAULT ready assertion          : %s", MakeString_UIntRange_t(me.fault_assert_rdy    , " cycles(s)")));
    result.push_back($sformatf("----------------------------------------------------------------"));
  
    return(result);
  endfunction:MakeStringList_MmH2CDmaBfmTimingParam_t
  
  
  
  
  
  function automatic StringQ_t MakeStringList_MmC2HDmaBfmTimingParam_t(MmC2HDmaBfmTimingParam_t me);
    StringQ_t result;
    
    result.push_back($sformatf("----------------------------------------------------------------"));
    result.push_back($sformatf(" ** C2H_BFM_TIMING_PARAM"));
    result.push_back($sformatf("----------------------------------------------------------------"));
    result.push_back($sformatf("     -  DESC to DESC issuing interval : %s", MakeString_UIntRange_t(me.desc2desc,            " cycles(s)")));
    result.push_back($sformatf("     -  status ready assertion        : %s", MakeString_UIntRange_t(me.status_assert_rdy   , " cycles(s)")));
    result.push_back($sformatf("     -  interrupt ready assertion     : %s", MakeString_UIntRange_t(me.interrupt_assert_rdy, " cycles(s)")));
    result.push_back($sformatf("     -  fault ready assertion         : %s", MakeString_UIntRange_t(me.fault_assert_rdy    , " cycles(s)")));
    result.push_back($sformatf("----------------------------------------------------------------"));
  
    return(result);
  endfunction:MakeStringList_MmC2HDmaBfmTimingParam_t
  
  
  
  
  
  function automatic string MakeString_StCardSideInfo_t(StCardSideInfo_t me);
    return($sformatf("dma_id=%1d mty=%1d", DutParamDmaId_t'(me.dma_id), DutParamEmpty_t'(me.mty)));
  endfunction:MakeString_StCardSideInfo_t
  



  // TODO:NeedImplement
  function automatic string MakeReport_Trans_t(DmaTransType_t trans_type, Desc_t desc, DataQ_t q_data, Status_t status, Interrupt_t interrupt, Fault_t fault);
    return(MakeString_Desc_t(trans_type, desc));
  endfunction:MakeReport_Trans_t
  
  
  function automatic string MakeString_Data_t(Data_t me);
  
    return($sformatf("last=%1d side_info=[%s] value=0x%1h",
      me.last,
      MakeString_StCardSideInfo_t(me.side_info),
      me.value
    ));
  endfunction:MakeString_Data_t
  
  
  
  function automatic string MakeString_Status_t(Status_t me);
  
    return($sformatf("dma_id=%1d msg=%1d",
      DutParamDmaId_t'(me.dma_id),
      me.msg
    ));
  endfunction:MakeString_Status_t
  
  
  
  
  function automatic string MakeString_Interrupt_t(Interrupt_t me);
  
    return($sformatf("dma/fnc/vec_id=%1d/%1d/%1d",
      DutParamDmaId_t'(me.dma_id),
      me.fnc_id,
      me.vec_id
    ));
  endfunction:MakeString_Interrupt_t
  
  
  
  
  function automatic string MakeString_Fault_t(Fault_t me);
    return($sformatf("dma_id=%1d code=%s axi_resp=%1d",
      DutParamDmaId_t'(me.dma_id),
      me.code,
      me.axi_resp
    ));
  endfunction:MakeString_Fault_t
  
  
  
  
  function automatic string MakeString_Desc_t(DmaTransType_t trans_type, Desc_t me, YesOrNo_t formatted=YES);
    string str_id, str_addr, str_len, str_req, str_packet_gathering;
  
  
    if(formatted == YES)begin
      str_id = $sformatf("dma_id=%-3d str/fnc/vec_id=%-3d/%-3d/%-3d", 
        DutParamDmaId_t'(me.dma_id),
        me.str_id,
        me.fnc_id,
        me.vec_id
      );
    end
    else begin
      str_id = $sformatf("dma_id=%1d str/fnc/vec_id=%1d/%1d/%1d", 
        DutParamDmaId_t'(me.dma_id),
        me.str_id,
        me.fnc_id,
        me.vec_id
      );
    end
  
    case(trans_type)
      ST_H2C  : str_addr = $sformatf("src_addr=0x%1h", DutParamHostAddr_t'(me.src_addr));
      ST_C2H  : str_addr = $sformatf("dst_addr=0x%1h", DutParamHostAddr_t'(me.dst_addr));
      default : str_addr = $sformatf("src/dst_addr=0x%1h/0x%1h", DutParamHostAddr_t'(me.src_addr), DutParamHostAddr_t'(me.dst_addr));
    endcase
  
    if(formatted == YES)begin
      str_len = $sformatf("len=%-3d", me.len);
    end
    else begin
      str_len = $sformatf("len=%1d", me.len);
    end
  
    str_req = $sformatf("req_intr/stat=%1d/%1d", me.req_intr, me.req_stat); 
  
  /*
    case(trans_type)
      ST_H2C  : str_packet_gathering = $sformatf(" sop/eop=%1d/%1d", me.sop, me.eop);
      default : str_packet_gathering = "";
    endcase
  */
    str_packet_gathering = $sformatf(" sop/eop=%1d/%1d", me.sop, me.eop);
  
    return($sformatf("%s %s %s %s %s %s",
      trans_type.name,
      str_id,
      str_len,
      str_req,
      str_packet_gathering,
      str_addr
    ));
  endfunction:MakeString_Desc_t





`endif // __VDMA_UTILS_SVH__
