`ifndef __VDMATB_VWRAP_SV__
`define __VDMATB_VWRAP_SV__


module vdmatb_vwrap
  `vdmatb_import_core_pkg
  import vdmatb_vwrap_pkg::*;
(
  dmg_clk_if      IF_clk,
  vdmatb_vwrap_if IF_vwrap
);

  vmg_rptr rptr;


//------------------------------------- PMON
//`ifdef IP_PMON_ENABLE
  pdma_mm_ip_c2h_mon_mngr mm_c2h_mon_mngr;
  pdma_mm_ip_h2c_mon_mngr mm_h2c_mon_mngr;
  
//`elsif ITF_PMON_ENABLE
//    pdma_st_c2h_mon_mngr c2h_mon_mngr;
//    paxi_wr_mon_mngr     wr_mon_mngr;
//    pdma_st_h2c_mon_mngr h2c_mon_mngr;
//    paxi_rd_mon_mngr     rd_mon_mngr;
//`endif



  DmaMM_symmetric_basic A_DUT(
  
    .i_clk (IF_clk.CLK),
    .i_rsn (IF_clk.RESETn),
  
    .s_h2c_desc_VALID           (IF_vwrap.m_h2c_dma.desc_valid),
    .s_h2c_desc_READY           (IF_vwrap.m_h2c_dma.desc_ready),
    .s_h2c_desc_dma_id          (IF_vwrap.m_h2c_dma.desc_dma_id),
    .s_h2c_desc_str_id          (IF_vwrap.m_h2c_dma.desc_str_id),
    .s_h2c_desc_fnc_id          (IF_vwrap.m_h2c_dma.desc_fnc_id),
    .s_h2c_desc_vec_id          (IF_vwrap.m_h2c_dma.desc_vec_id),
    .s_h2c_desc_src_byte_addr   (IF_vwrap.m_h2c_dma.desc_src_addr),
    .s_h2c_desc_dst_byte_addr   (IF_vwrap.m_h2c_dma.desc_dst_addr[vdmatb_vwrap_pkg::MM_DUT_PARAM.CAXI_ADDR_WIDTH - 1:0]),
    .s_h2c_desc_len_in_byte     (IF_vwrap.m_h2c_dma.desc_len),
    .s_h2c_desc_req_intr        (IF_vwrap.m_h2c_dma.desc_req_intr),
    .s_h2c_desc_req_stat        (IF_vwrap.m_h2c_dma.desc_req_stat),
    .s_h2c_desc_max_hburst_len  (IF_vwrap.m_h2c_dma.desc_axi_max_len),
    .m_h2c_status_VALID         (IF_vwrap.m_h2c_dma.status_valid),
    .m_h2c_status_READY         (IF_vwrap.m_h2c_dma.status_ready),
    .m_h2c_status_dma_id        (IF_vwrap.m_h2c_dma.status_dma_id),
    .m_h2c_status_status_msg    (IF_vwrap.m_h2c_dma.status_msg),
    .m_h2c_interrupt_VALID      (IF_vwrap.m_h2c_dma.interrupt_valid),
    .m_h2c_interrupt_READY      (IF_vwrap.m_h2c_dma.interrupt_ready),
    .m_h2c_interrupt_dma_id     (IF_vwrap.m_h2c_dma.interrupt_dma_id),
    .m_h2c_interrupt_fnc_id     (IF_vwrap.m_h2c_dma.interrupt_fnc_id),
    .m_h2c_interrupt_vec_id     (IF_vwrap.m_h2c_dma.interrupt_vec_id),
    .m_h2c_fault_VALID          (IF_vwrap.m_h2c_dma.fault_valid),
    .m_h2c_fault_READY          (IF_vwrap.m_h2c_dma.fault_ready),
    .m_h2c_fault_dma_id         (IF_vwrap.m_h2c_dma.fault_dma_id),
    .m_h2c_fault_str_id         (IF_vwrap.m_h2c_dma.fault_str_id),
    .m_h2c_fault_fault_code     (IF_vwrap.m_h2c_dma.fault_code),
    .m_h2c_fault_axi_resp       (IF_vwrap.m_h2c_dma.fault_axi_resp),
    .o_h2c_num_entry            (IF_vwrap.m_h2c_dma.num_entry),
    .o_h2c_num_pending          (IF_vwrap.m_h2c_dma.num_pending),
    .s_c2h_desc_VALID           (IF_vwrap.m_c2h_dma.desc_valid),
    .s_c2h_desc_READY           (IF_vwrap.m_c2h_dma.desc_ready),
    .s_c2h_desc_dma_id          (IF_vwrap.m_c2h_dma.desc_dma_id),
    .s_c2h_desc_str_id          (IF_vwrap.m_c2h_dma.desc_str_id),
    .s_c2h_desc_fnc_id          (IF_vwrap.m_c2h_dma.desc_fnc_id),
    .s_c2h_desc_vec_id          (IF_vwrap.m_c2h_dma.desc_vec_id),
    .s_c2h_desc_src_byte_addr   (IF_vwrap.m_c2h_dma.desc_src_addr[vdmatb_vwrap_pkg::MM_DUT_PARAM.CAXI_ADDR_WIDTH - 1:0]),
    .s_c2h_desc_dst_byte_addr   (IF_vwrap.m_c2h_dma.desc_dst_addr),
    .s_c2h_desc_len_in_byte     (IF_vwrap.m_c2h_dma.desc_len),
    .s_c2h_desc_req_intr        (IF_vwrap.m_c2h_dma.desc_req_intr),
    .s_c2h_desc_req_stat        (IF_vwrap.m_c2h_dma.desc_req_stat),
    .s_c2h_desc_max_hburst_len  (IF_vwrap.m_c2h_dma.desc_axi_max_len),
    .m_c2h_status_VALID         (IF_vwrap.m_c2h_dma.status_valid),
    .m_c2h_status_READY         (IF_vwrap.m_c2h_dma.status_ready),
    .m_c2h_status_dma_id        (IF_vwrap.m_c2h_dma.status_dma_id),
    .m_c2h_status_status_msg    (IF_vwrap.m_c2h_dma.status_msg),
    .m_c2h_interrupt_VALID      (IF_vwrap.m_c2h_dma.interrupt_valid),
    .m_c2h_interrupt_READY      (IF_vwrap.m_c2h_dma.interrupt_ready),
    .m_c2h_interrupt_dma_id     (IF_vwrap.m_c2h_dma.interrupt_dma_id),
    .m_c2h_interrupt_fnc_id     (IF_vwrap.m_c2h_dma.interrupt_fnc_id),
    .m_c2h_interrupt_vec_id     (IF_vwrap.m_c2h_dma.interrupt_vec_id),
    .m_c2h_fault_VALID          (IF_vwrap.m_c2h_dma.fault_valid),
    .m_c2h_fault_READY          (IF_vwrap.m_c2h_dma.fault_ready),
    .m_c2h_fault_dma_id         (IF_vwrap.m_c2h_dma.fault_dma_id),
    .m_c2h_fault_str_id         (IF_vwrap.m_c2h_dma.fault_str_id),
    .m_c2h_fault_fault_code     (IF_vwrap.m_c2h_dma.fault_code),
    .m_c2h_fault_axi_resp       (IF_vwrap.m_c2h_dma.fault_axi_resp),
    .o_c2h_num_entry            (IF_vwrap.m_c2h_dma.num_entry),
    .o_c2h_num_pending          (IF_vwrap.m_c2h_dma.num_pending),
    
    ////////////////////////MM only////////////////////////
    .m_card_axi_AWVALID         (IF_vwrap.m_card_axi.awvalid),
    .m_card_axi_AWREADY         (IF_vwrap.m_card_axi.awready),
    .m_card_axi_AWID            (IF_vwrap.m_card_axi.awid   ),
    .m_card_axi_AWADDR          (IF_vwrap.m_card_axi.awaddr ),
    .m_card_axi_AWBURST         (IF_vwrap.m_card_axi.awburst),
    .m_card_axi_AWLEN           (IF_vwrap.m_card_axi.awlen  ),
    .m_card_axi_AWCACHE         (IF_vwrap.m_card_axi.awcache),
    .m_card_axi_AWUSER          (IF_vwrap.m_card_axi.awuser ),
    .m_card_axi_WVALID          (IF_vwrap.m_card_axi.wvalid ),
    .m_card_axi_WREADY          (IF_vwrap.m_card_axi.wready ),
    .m_card_axi_WDATA           (IF_vwrap.m_card_axi.wdata  ),
    .m_card_axi_WLAST           (IF_vwrap.m_card_axi.wlast  ),
    .m_card_axi_WSTRB           (IF_vwrap.m_card_axi.wstrb  ),
    .m_card_axi_BVALID          (IF_vwrap.m_card_axi.bvalid ),
    .m_card_axi_BREADY          (IF_vwrap.m_card_axi.bready ),
    .m_card_axi_BID             (IF_vwrap.m_card_axi.bid    ),
    .m_card_axi_BRESP           (IF_vwrap.m_card_axi.bresp  ),
    
    .m_card_axi_ARVALID         (IF_vwrap.m_card_axi.arvalid),
    .m_card_axi_ARREADY         (IF_vwrap.m_card_axi.arready),
    .m_card_axi_ARID            (IF_vwrap.m_card_axi.arid),
    .m_card_axi_ARADDR          (IF_vwrap.m_card_axi.araddr),
    .m_card_axi_ARBURST         (IF_vwrap.m_card_axi.arburst),
    .m_card_axi_ARLEN           (IF_vwrap.m_card_axi.arlen),
    .m_card_axi_ARCACHE         (IF_vwrap.m_card_axi.arcache),
    .m_card_axi_ARUSER          (IF_vwrap.m_card_axi.aruser),
    .m_card_axi_RVALID          (IF_vwrap.m_card_axi.rvalid),
    .m_card_axi_RREADY          (IF_vwrap.m_card_axi.rready),
    .m_card_axi_RID             (IF_vwrap.m_card_axi.rid),
    .m_card_axi_RDATA           (IF_vwrap.m_card_axi.rdata),
    .m_card_axi_RRESP           (IF_vwrap.m_card_axi.rresp),
    .m_card_axi_RLAST           (IF_vwrap.m_card_axi.rlast),
    ////////////////////////MM only////////////////////////

    .m_host_axi_ARVALID (IF_vwrap.m_host_axi.arvalid),
    .m_host_axi_ARREADY (IF_vwrap.m_host_axi.arready),
    .m_host_axi_ARID    (IF_vwrap.m_host_axi.arid),
    .m_host_axi_ARADDR  (IF_vwrap.m_host_axi.araddr),
    .m_host_axi_ARBURST (IF_vwrap.m_host_axi.arburst),
    .m_host_axi_ARLEN   (IF_vwrap.m_host_axi.arlen),
    .m_host_axi_ARCACHE (IF_vwrap.m_host_axi.arcache),
    .m_host_axi_ARUSER  (IF_vwrap.m_host_axi.aruser),
    .m_host_axi_RVALID  (IF_vwrap.m_host_axi.rvalid),
    .m_host_axi_RREADY  (IF_vwrap.m_host_axi.rready),
    .m_host_axi_RID     (IF_vwrap.m_host_axi.rid),
    .m_host_axi_RDATA   (IF_vwrap.m_host_axi.rdata),
    .m_host_axi_RRESP   (IF_vwrap.m_host_axi.rresp[1:0]),
    .m_host_axi_RLAST   (IF_vwrap.m_host_axi.rlast),
    .m_host_axi_AWVALID (IF_vwrap.m_host_axi.awvalid),
    .m_host_axi_AWREADY (IF_vwrap.m_host_axi.awready),
    .m_host_axi_AWID    (IF_vwrap.m_host_axi.awid),
    .m_host_axi_AWADDR  (IF_vwrap.m_host_axi.awaddr),
    .m_host_axi_AWBURST (IF_vwrap.m_host_axi.awburst),
    .m_host_axi_AWLEN   (IF_vwrap.m_host_axi.awlen),
    .m_host_axi_AWCACHE (IF_vwrap.m_host_axi.awcache),
    .m_host_axi_AWUSER  (IF_vwrap.m_host_axi.awuser),
    .m_host_axi_WVALID  (IF_vwrap.m_host_axi.wvalid),
    .m_host_axi_WREADY  (IF_vwrap.m_host_axi.wready),
    .m_host_axi_WDATA   (IF_vwrap.m_host_axi.wdata),
    .m_host_axi_WLAST   (IF_vwrap.m_host_axi.wlast),
    .m_host_axi_WSTRB   (IF_vwrap.m_host_axi.wstrb),
    .m_host_axi_BVALID  (IF_vwrap.m_host_axi.bvalid),
    .m_host_axi_BREADY  (IF_vwrap.m_host_axi.bready),
    .m_host_axi_BID     (IF_vwrap.m_host_axi.bid),
    .m_host_axi_BRESP   (IF_vwrap.m_host_axi.bresp[1:0]),
  
  
    // TODO:NeedVerify
    .m_h2c_testcmd_t_VALID       (1'b0),
    .m_h2c_testcmd_t_READY       (),
    .m_h2c_testcmd_t_test_msg0   (8'd0),
    .m_h2c_testcmd_t_test_msg1   (8'd0),

    .m_c2h_testcmd_t_VALID       (1'b0),
    .m_c2h_testcmd_t_READY       (),
    .m_c2h_testcmd_t_test_msg0   (8'd0),
    .m_c2h_testcmd_t_test_msg1   (8'd0)
  );
  
  
  assign IF_vwrap.axi_if.common_aclk = IF_clk.CLK;
  assign IF_vwrap.m_host_axi.aclk    = IF_clk.CLK;
  assign IF_vwrap.m_host_axi.aresetn = IF_clk.RESETn;
  
  
  assign IF_vwrap.m_host_axi.arsize = AXI_SIZE_64B;
  assign IF_vwrap.m_host_axi.arlock = 0;
  assign IF_vwrap.m_host_axi.arqos  = 0;
  assign IF_vwrap.m_host_axi.arprot = 0;

  assign IF_vwrap.m_host_axi.awsize = AXI_SIZE_64B;
  assign IF_vwrap.m_host_axi.awlock = 0;
  assign IF_vwrap.m_host_axi.awqos  = 0;
  assign IF_vwrap.m_host_axi.awprot = 0;
 
  assign IF_vwrap.m_host_axi.wuser = 0;

  //assign IF_vwrap.m_c2h_dma.rdata[MAX_DATA_WIDTH - 1:DUT_TDATA_WIDTH] = 0;
  //assign IF_vwrap.m_h2c_dma.wdata[MAX_DATA_WIDTH - 1:DUT_TDATA_WIDTH] = 0;
  
  assign IF_vwrap.m_card_axi.aclk    = IF_clk.CLK;
  assign IF_vwrap.m_card_axi.aresetn = IF_clk.RESETn;
  
  
  assign IF_vwrap.m_card_axi.arsize = AXI_SIZE_64B;
  assign IF_vwrap.m_card_axi.arlock = 0;
  assign IF_vwrap.m_card_axi.arqos  = 0;
  assign IF_vwrap.m_card_axi.arprot = 0;

  assign IF_vwrap.m_card_axi.awsize = AXI_SIZE_64B;
  assign IF_vwrap.m_card_axi.awlock = 0;
  assign IF_vwrap.m_card_axi.awqos  = 0;
  assign IF_vwrap.m_card_axi.awprot = 0;
 
  assign IF_vwrap.m_card_axi.wuser = 0;
	
//User Define 

  assign h2c_lenInByte_low_6bits = IF_vwrap.m_h2c_dma.desc_len[5:0];
	
  assign src_addr_low_6bits = IF_vwrap.m_h2c_dma.desc_src_addr[5:0];
	
  assign h2c_len_in_byte_buf = IF_vwrap.m_h2c_dma.desc_len;
  assign h2c_max_hburst_len_buf = IF_vwrap.m_h2c_dma.desc_axi_max_len;
  assign h2c_max_hburst_len = (h2c_max_hburst_len_buf==0) ? 256 : h2c_max_hburst_len_buf;
  assign h2c_BL2 = (h2c_len_in_byte_buf/64)/h2c_max_hburst_len;
  assign h2c_Split_on_BL_modulo = (h2c_len_in_byte_buf/64)%h2c_max_hburst_len;
/////	
  assign c2h_lenInByte_low_6bits = IF_vwrap.m_c2h_dma.desc_len[5:0];
  assign c2h_lenInByte_low_12bits = IF_vwrap.m_c2h_dma.desc_len[11:0];
	
  assign dst_addr_low_6bits = IF_vwrap.m_c2h_dma.desc_dst_addr[5:0];
  assign dst_addr_low_12bits = IF_vwrap.m_c2h_dma.desc_dst_addr[11:0];
  assign dst_addr_aligned = dst_addr_low_12bits & 12'b111111000000;
	
  assign c2h_len_in_byte_buf = IF_vwrap.m_c2h_dma.desc_len;
  assign c2h_max_hburst_len_buf = IF_vwrap.m_c2h_dma.desc_axi_max_len;
  assign c2h_max_hburst_len = (c2h_max_hburst_len_buf==0) ? 256 : c2h_max_hburst_len_buf;
  assign BL2 = (c2h_len_in_byte_buf/64)/c2h_max_hburst_len;
  assign Split_on_BL_modulo = (c2h_len_in_byte_buf/64) % c2h_max_hburst_len;
	
	
  assign dst_addr_buf = IF_vwrap.m_c2h_dma.desc_dst_addr;
  assign c2h_lenInByte_buf_32bits = IF_vwrap.m_c2h_dma.desc_len;
  assign after_shift_dst_addr = dst_addr_buf >> 12;

//---------------------------------WSTRB
  assign host_input_wstrb = IF_vwrap.m_host_axi.wstrb;
  assign host_wlast = IF_vwrap.m_host_axi.wlast;
  assign card_input_wstrb = IF_vwrap.m_card_axi.wstrb;
  assign card_wlast = IF_vwrap.m_card_axi.wlast;
	
  assign HOST_WVALID = IF_vwrap.m_host_axi.wvalid;
  assign HOST_WREADY = IF_vwrap.m_host_axi.wready;
    
  assign CARD_WVALID = IF_vwrap.m_card_axi.wvalid;
  assign CARD_WREADY = IF_vwrap.m_card_axi.wready;
  
  assign IF_vwrap.axi_if.master_if[0].arvalid =    IF_vwrap.m_host_axi.arvalid;
  assign IF_vwrap.axi_if.master_if[0].arready =    IF_vwrap.m_host_axi.arready;
  assign IF_vwrap.axi_if.master_if[0].arid =       IF_vwrap.m_host_axi.arid;
  assign IF_vwrap.axi_if.master_if[0].araddr =     IF_vwrap.m_host_axi.araddr;
  assign IF_vwrap.axi_if.master_if[0].arburst =    IF_vwrap.m_host_axi.arburst;
  assign IF_vwrap.axi_if.master_if[0].arlen =      IF_vwrap.m_host_axi.arlen;
  assign IF_vwrap.axi_if.master_if[0].arcache =    IF_vwrap.m_host_axi.arcache;
  assign IF_vwrap.axi_if.master_if[0].aruser =     IF_vwrap.m_host_axi.aruser;
  assign IF_vwrap.axi_if.master_if[0].rvalid =     IF_vwrap.m_host_axi.rvalid;
  assign IF_vwrap.axi_if.master_if[0].rready =     IF_vwrap.m_host_axi.rready;
  assign IF_vwrap.axi_if.master_if[0].rid =        IF_vwrap.m_host_axi.rid;
  assign IF_vwrap.axi_if.master_if[0].rdata =      IF_vwrap.m_host_axi.rdata;
  assign IF_vwrap.axi_if.master_if[0].rresp[1:0] = IF_vwrap.m_host_axi.rresp[1:0];
  assign IF_vwrap.axi_if.master_if[0].rlast =      IF_vwrap.m_host_axi.rlast;
  assign IF_vwrap.axi_if.master_if[0].awvalid =    IF_vwrap.m_host_axi.awvalid;
  assign IF_vwrap.axi_if.master_if[0].awready =    IF_vwrap.m_host_axi.awready;
  assign IF_vwrap.axi_if.master_if[0].awid =       IF_vwrap.m_host_axi.awid;
  assign IF_vwrap.axi_if.master_if[0].awaddr =     IF_vwrap.m_host_axi.awaddr;
  assign IF_vwrap.axi_if.master_if[0].awburst =    IF_vwrap.m_host_axi.awburst;
  assign IF_vwrap.axi_if.master_if[0].awlen =      IF_vwrap.m_host_axi.awlen;
  assign IF_vwrap.axi_if.master_if[0].awcache =    IF_vwrap.m_host_axi.awcache;
  assign IF_vwrap.axi_if.master_if[0].awuser =     IF_vwrap.m_host_axi.awuser;
  assign IF_vwrap.axi_if.master_if[0].wvalid =     IF_vwrap.m_host_axi.wvalid;
  assign IF_vwrap.axi_if.master_if[0].wready =     IF_vwrap.m_host_axi.wready;
  assign IF_vwrap.axi_if.master_if[0].wdata =      IF_vwrap.m_host_axi.wdata;
  assign IF_vwrap.axi_if.master_if[0].wlast =      IF_vwrap.m_host_axi.wlast;
  assign IF_vwrap.axi_if.master_if[0].wstrb =      IF_vwrap.m_host_axi.wstrb;
  assign IF_vwrap.axi_if.master_if[0].bvalid =     IF_vwrap.m_host_axi.bvalid;
  assign IF_vwrap.axi_if.master_if[0].bready =     IF_vwrap.m_host_axi.bready;
  assign IF_vwrap.axi_if.master_if[0].bid =        IF_vwrap.m_host_axi.bid;
  assign IF_vwrap.axi_if.master_if[0].bresp =      IF_vwrap.m_host_axi.bresp;

  assign IF_vwrap.axi_if.master_if[1].arvalid =    IF_vwrap.m_card_axi.arvalid;
  assign IF_vwrap.axi_if.master_if[1].arready =    IF_vwrap.m_card_axi.arready;
  assign IF_vwrap.axi_if.master_if[1].arid =       IF_vwrap.m_card_axi.arid;
  assign IF_vwrap.axi_if.master_if[1].araddr =     IF_vwrap.m_card_axi.araddr;
  assign IF_vwrap.axi_if.master_if[1].arburst =    IF_vwrap.m_card_axi.arburst;
  assign IF_vwrap.axi_if.master_if[1].arlen =      IF_vwrap.m_card_axi.arlen;
  assign IF_vwrap.axi_if.master_if[1].arcache =    IF_vwrap.m_card_axi.arcache;
  assign IF_vwrap.axi_if.master_if[1].aruser =     IF_vwrap.m_card_axi.aruser;
  assign IF_vwrap.axi_if.master_if[1].rvalid =     IF_vwrap.m_card_axi.rvalid;
  assign IF_vwrap.axi_if.master_if[1].rready =     IF_vwrap.m_card_axi.rready;
  assign IF_vwrap.axi_if.master_if[1].rid =        IF_vwrap.m_card_axi.rid;
  assign IF_vwrap.axi_if.master_if[1].rdata =      IF_vwrap.m_card_axi.rdata;
  assign IF_vwrap.axi_if.master_if[1].rresp[1:0] = IF_vwrap.m_card_axi.rresp[1:0];
  assign IF_vwrap.axi_if.master_if[1].rlast =      IF_vwrap.m_card_axi.rlast;
  assign IF_vwrap.axi_if.master_if[1].awvalid =    IF_vwrap.m_card_axi.awvalid;
  assign IF_vwrap.axi_if.master_if[1].awready =    IF_vwrap.m_card_axi.awready;
  assign IF_vwrap.axi_if.master_if[1].awid =       IF_vwrap.m_card_axi.awid;
  assign IF_vwrap.axi_if.master_if[1].awaddr =     IF_vwrap.m_card_axi.awaddr;
  assign IF_vwrap.axi_if.master_if[1].awburst =    IF_vwrap.m_card_axi.awburst;
  assign IF_vwrap.axi_if.master_if[1].awlen =      IF_vwrap.m_card_axi.awlen;
  assign IF_vwrap.axi_if.master_if[1].awcache =    IF_vwrap.m_card_axi.awcache;
  assign IF_vwrap.axi_if.master_if[1].awuser =     IF_vwrap.m_card_axi.awuser;
  assign IF_vwrap.axi_if.master_if[1].wvalid =     IF_vwrap.m_card_axi.wvalid;
  assign IF_vwrap.axi_if.master_if[1].wready =     IF_vwrap.m_card_axi.wready;
  assign IF_vwrap.axi_if.master_if[1].wdata =      IF_vwrap.m_card_axi.wdata;
  assign IF_vwrap.axi_if.master_if[1].wlast =      IF_vwrap.m_card_axi.wlast;
  assign IF_vwrap.axi_if.master_if[1].wstrb =      IF_vwrap.m_card_axi.wstrb;
  assign IF_vwrap.axi_if.master_if[1].bvalid =     IF_vwrap.m_card_axi.bvalid;
  assign IF_vwrap.axi_if.master_if[1].bready =     IF_vwrap.m_card_axi.bready;
  assign IF_vwrap.axi_if.master_if[1].bid =        IF_vwrap.m_card_axi.bid;
  assign IF_vwrap.axi_if.master_if[1].bresp =      IF_vwrap.m_card_axi.bresp;

//--------------------------------------PMON
  pdma_mm_ip_c2h_mon#(.MYNAME ("A_pdma_mm_ip_c2h_mon")) A_pdma_mm_ip_c2h_mon(.*, .IF_paxi(IF_vwrap.c2h_paxi_if), .IF_mm_c2h(IF_vwrap.m_c2h_dma));
  pdma_mm_ip_h2c_mon#(.MYNAME ("A_pdma_mm_ip_h2c_mon")) A_pdma_mm_ip_h2c_mon(.*, .IF_paxi(IF_vwrap.h2c_paxi_if), .IF_mm_h2c(IF_vwrap.m_h2c_dma));

//---------------------------------------------------------------------------------------------
//PMON interconnection
//---------------------------------------------------------------------------------------------
//C2H
//pdma_mm_c2h_mon#(.MYNAME ("A_pdma_mm_c2h_mon")) A_pdma_mm_c2h_mon(.*, .IF_mon(IF_vwrap.m_c2h_dma));
  assign IF_vwrap.m_c2h_dma.desc_pl.dma_id = IF_vwrap.m_c2h_dma.desc_dma_id;
  assign IF_vwrap.m_c2h_dma.desc_pl.str_id = IF_vwrap.m_c2h_dma.desc_str_id;
  assign IF_vwrap.m_c2h_dma.desc_pl.fnc_id = IF_vwrap.m_c2h_dma.desc_fnc_id;
  assign IF_vwrap.m_c2h_dma.desc_pl.vec_id = IF_vwrap.m_c2h_dma.desc_vec_id;
  assign IF_vwrap.m_c2h_dma.desc_pl.src_addr = IF_vwrap.m_c2h_dma.desc_src_addr[vdmatb_vwrap_pkg::MM_DUT_PARAM.CAXI_ADDR_WIDTH - 1:0];
  assign IF_vwrap.m_c2h_dma.desc_pl.dst_addr = IF_vwrap.m_c2h_dma.desc_dst_addr;
  assign IF_vwrap.m_c2h_dma.desc_pl.len = IF_vwrap.m_c2h_dma.desc_len;
  assign IF_vwrap.m_c2h_dma.desc_pl.req_intr = IF_vwrap.m_c2h_dma.desc_req_intr;
  assign IF_vwrap.m_c2h_dma.desc_pl.req_stat = IF_vwrap.m_c2h_dma.desc_req_stat;
  assign IF_vwrap.m_c2h_dma.desc_pl.axi_max_len = IF_vwrap.m_c2h_dma.desc_axi_max_len;

  assign IF_vwrap.m_c2h_dma.status_pl.dma_id = IF_vwrap.m_c2h_dma.status_dma_id;
  assign IF_vwrap.m_c2h_dma.status_pl.msg = IF_vwrap.m_c2h_dma.status_msg;

  assign IF_vwrap.m_c2h_dma.interrupt_pl.dma_id = IF_vwrap.m_c2h_dma.interrupt_dma_id;
  assign IF_vwrap.m_c2h_dma.interrupt_pl.fnc_id = IF_vwrap.m_c2h_dma.interrupt_fnc_id;
  assign IF_vwrap.m_c2h_dma.interrupt_pl.vec_id = IF_vwrap.m_c2h_dma.interrupt_vec_id;

  assign IF_vwrap.m_c2h_dma.fault_pl.dma_id = IF_vwrap.m_c2h_dma.fault_dma_id;
  assign IF_vwrap.m_c2h_dma.fault_pl.str_id = IF_vwrap.m_c2h_dma.fault_str_id;
  assign IF_vwrap.m_c2h_dma.fault_pl.code = IF_vwrap.m_c2h_dma.fault_code;
  assign IF_vwrap.m_c2h_dma.fault_pl.axi_resp = IF_vwrap.m_c2h_dma.fault_axi_resp;
  //---------------------------------------------------------------------------------------------
//PAXI_WR
//paxi_wr_mon#(.MYNAME ("A_paxi_wr_mon")) A_paxi_wr_mon(.*, .IF_mon(IF_vwrap.paxi_if.wrmon));
  assign IF_vwrap.c2h_paxi_if.ar_vld = IF_vwrap.m_card_axi.arvalid;
  assign IF_vwrap.c2h_paxi_if.ar_rdy = IF_vwrap.m_card_axi.arready;
  assign IF_vwrap.c2h_paxi_if.ar_pl.id = IF_vwrap.m_card_axi.arid;
  assign IF_vwrap.c2h_paxi_if.ar_pl.addr = IF_vwrap.m_card_axi.araddr;
  assign IF_vwrap.c2h_paxi_if.ar_pl.len = IF_vwrap.m_card_axi.arlen;
  assign IF_vwrap.c2h_paxi_if.ar_pl.size = IF_vwrap.m_card_axi.arsize;
  assign IF_vwrap.c2h_paxi_if.ar_pl.burst = IF_vwrap.m_card_axi.arburst;
  assign IF_vwrap.c2h_paxi_if.ar_pl.cache = IF_vwrap.m_card_axi.arcache;
  assign IF_vwrap.c2h_paxi_if.ar_pl.lock = IF_vwrap.m_card_axi.arlock;
  assign IF_vwrap.c2h_paxi_if.ar_pl.prot = IF_vwrap.m_card_axi.arprot;
  assign IF_vwrap.c2h_paxi_if.ar_pl.qos = IF_vwrap.m_card_axi.arqos;
  assign IF_vwrap.c2h_paxi_if.ar_pl.user = IF_vwrap.m_card_axi.aruser;

  assign IF_vwrap.c2h_paxi_if.r_vld = IF_vwrap.m_card_axi.rvalid;
  assign IF_vwrap.c2h_paxi_if.r_rdy = IF_vwrap.m_card_axi.rready;
  assign IF_vwrap.c2h_paxi_if.r_pl.id = IF_vwrap.m_card_axi.rid;
  assign IF_vwrap.c2h_paxi_if.r_pl.resp = IF_vwrap.m_card_axi.rresp;
  assign IF_vwrap.c2h_paxi_if.r_pl.data = IF_vwrap.m_card_axi.rdata;
  assign IF_vwrap.c2h_paxi_if.r_pl.last = IF_vwrap.m_card_axi.rlast;
  assign IF_vwrap.c2h_paxi_if.r_pl.user = IF_vwrap.m_card_axi.ruser;

  assign IF_vwrap.c2h_paxi_if.aw_vld = IF_vwrap.m_host_axi.awvalid;
  assign IF_vwrap.c2h_paxi_if.aw_rdy = IF_vwrap.m_host_axi.awready;
  assign IF_vwrap.c2h_paxi_if.aw_pl.id = IF_vwrap.m_host_axi.awid;
  assign IF_vwrap.c2h_paxi_if.aw_pl.addr = IF_vwrap.m_host_axi.awaddr;
  assign IF_vwrap.c2h_paxi_if.aw_pl.len = IF_vwrap.m_host_axi.awlen;
  assign IF_vwrap.c2h_paxi_if.aw_pl.size = IF_vwrap.m_host_axi.awsize;
  assign IF_vwrap.c2h_paxi_if.aw_pl.burst = IF_vwrap.m_host_axi.awburst;
  assign IF_vwrap.c2h_paxi_if.aw_pl.cache = IF_vwrap.m_host_axi.awcache;
  assign IF_vwrap.c2h_paxi_if.aw_pl.lock = IF_vwrap.m_host_axi.awlock;
  assign IF_vwrap.c2h_paxi_if.aw_pl.prot = IF_vwrap.m_host_axi.awprot;
  assign IF_vwrap.c2h_paxi_if.aw_pl.qos = IF_vwrap.m_host_axi.awqos;
  assign IF_vwrap.c2h_paxi_if.aw_pl.user = IF_vwrap.m_host_axi.awuser;

  assign IF_vwrap.c2h_paxi_if.w_vld = IF_vwrap.m_host_axi.wvalid;
  assign IF_vwrap.c2h_paxi_if.w_rdy = IF_vwrap.m_host_axi.wready;
  assign IF_vwrap.c2h_paxi_if.w_pl.data = IF_vwrap.m_host_axi.wdata;
  assign IF_vwrap.c2h_paxi_if.w_pl.strb = IF_vwrap.m_host_axi.wstrb;
  assign IF_vwrap.c2h_paxi_if.w_pl.last = IF_vwrap.m_host_axi.wlast;
  assign IF_vwrap.c2h_paxi_if.w_pl.user = IF_vwrap.m_host_axi.wuser;

  assign IF_vwrap.c2h_paxi_if.b_vld = IF_vwrap.m_host_axi.bvalid;
  assign IF_vwrap.c2h_paxi_if.b_rdy = IF_vwrap.m_host_axi.bready;
  assign IF_vwrap.c2h_paxi_if.b_pl.id = IF_vwrap.m_host_axi.bid;
  assign IF_vwrap.c2h_paxi_if.b_pl.resp = IF_vwrap.m_host_axi.bresp;
  assign IF_vwrap.c2h_paxi_if.b_pl.user = IF_vwrap.m_host_axi.buser;
//---------------------------------------------------------------------------------------------
//H2C
//pdma_st_h2c_mon#(.MYNAME ("A_pdma_st_h2c_mon")) A_pdma_st_h2c_mon(.*, .IF_mon(IF_vwrap.s_h2c_dma));
  assign IF_vwrap.m_h2c_dma.desc_pl.dma_id = IF_vwrap.m_h2c_dma.desc_dma_id;
  assign IF_vwrap.m_h2c_dma.desc_pl.str_id = IF_vwrap.m_h2c_dma.desc_str_id;
  assign IF_vwrap.m_h2c_dma.desc_pl.fnc_id = IF_vwrap.m_h2c_dma.desc_fnc_id;
  assign IF_vwrap.m_h2c_dma.desc_pl.vec_id = IF_vwrap.m_h2c_dma.desc_vec_id;
  assign IF_vwrap.m_h2c_dma.desc_pl.src_addr = IF_vwrap.m_h2c_dma.desc_src_addr;
  assign IF_vwrap.m_h2c_dma.desc_pl.dst_addr = IF_vwrap.m_h2c_dma.desc_dst_addr[vdmatb_vwrap_pkg::MM_DUT_PARAM.CAXI_ADDR_WIDTH - 1:0];
  assign IF_vwrap.m_h2c_dma.desc_pl.len = IF_vwrap.m_h2c_dma.desc_len;
  assign IF_vwrap.m_h2c_dma.desc_pl.req_intr = IF_vwrap.m_h2c_dma.desc_req_intr;
  assign IF_vwrap.m_h2c_dma.desc_pl.req_stat = IF_vwrap.m_h2c_dma.desc_req_stat;
  assign IF_vwrap.m_h2c_dma.desc_pl.axi_max_len = IF_vwrap.m_h2c_dma.desc_axi_max_len;
  assign IF_vwrap.m_h2c_dma.desc_pl.sop = IF_vwrap.m_h2c_dma.desc_sop;
  assign IF_vwrap.m_h2c_dma.desc_pl.eop = IF_vwrap.m_h2c_dma.desc_eop;

  assign IF_vwrap.m_h2c_dma.status_pl.dma_id = IF_vwrap.m_h2c_dma.status_dma_id;
  assign IF_vwrap.m_h2c_dma.status_pl.msg = IF_vwrap.m_h2c_dma.status_msg;

  assign IF_vwrap.m_h2c_dma.interrupt_pl.dma_id = IF_vwrap.m_h2c_dma.interrupt_dma_id;
  assign IF_vwrap.m_h2c_dma.interrupt_pl.fnc_id = IF_vwrap.m_h2c_dma.interrupt_fnc_id;
  assign IF_vwrap.m_h2c_dma.interrupt_pl.vec_id = IF_vwrap.m_h2c_dma.interrupt_vec_id;

  assign IF_vwrap.m_h2c_dma.fault_pl.dma_id = IF_vwrap.m_h2c_dma.fault_dma_id;
  assign IF_vwrap.m_h2c_dma.fault_pl.str_id = IF_vwrap.m_h2c_dma.fault_str_id;
  assign IF_vwrap.m_h2c_dma.fault_pl.code = IF_vwrap.m_h2c_dma.fault_code;
  assign IF_vwrap.m_h2c_dma.fault_pl.axi_resp = IF_vwrap.m_h2c_dma.fault_axi_resp;
//---------------------------------------------------------------------------------------------

//PAXI_RD
//paxi_rd_mon#(.MYNAME ("A_paxi_rd_mon")) A_paxi_rd_mon(.*, .IF_mon(IF_vwrap.paxi_if.rdmon));
  assign IF_vwrap.h2c_paxi_if.aw_vld = IF_vwrap.m_card_axi.awvalid;
  assign IF_vwrap.h2c_paxi_if.aw_rdy = IF_vwrap.m_card_axi.awready;
  assign IF_vwrap.h2c_paxi_if.aw_pl.id = IF_vwrap.m_card_axi.awid;
  assign IF_vwrap.h2c_paxi_if.aw_pl.addr = IF_vwrap.m_card_axi.awaddr;
  assign IF_vwrap.h2c_paxi_if.aw_pl.len = IF_vwrap.m_card_axi.awlen;
  assign IF_vwrap.h2c_paxi_if.aw_pl.size = IF_vwrap.m_card_axi.awsize;
  assign IF_vwrap.h2c_paxi_if.aw_pl.burst = IF_vwrap.m_card_axi.awburst;
  assign IF_vwrap.h2c_paxi_if.aw_pl.cache = IF_vwrap.m_card_axi.awcache;
  assign IF_vwrap.h2c_paxi_if.aw_pl.lock = IF_vwrap.m_card_axi.awlock;
  assign IF_vwrap.h2c_paxi_if.aw_pl.prot = IF_vwrap.m_card_axi.awprot;
  assign IF_vwrap.h2c_paxi_if.aw_pl.qos = IF_vwrap.m_card_axi.awqos;
  assign IF_vwrap.h2c_paxi_if.aw_pl.user = IF_vwrap.m_card_axi.awuser;

  assign IF_vwrap.h2c_paxi_if.w_vld = IF_vwrap.m_card_axi.wvalid;
  assign IF_vwrap.h2c_paxi_if.w_rdy = IF_vwrap.m_card_axi.wready;
  assign IF_vwrap.h2c_paxi_if.w_pl.data = IF_vwrap.m_card_axi.wdata;
  assign IF_vwrap.h2c_paxi_if.w_pl.strb = IF_vwrap.m_card_axi.wstrb;
  assign IF_vwrap.h2c_paxi_if.w_pl.last = IF_vwrap.m_card_axi.wlast;
  assign IF_vwrap.h2c_paxi_if.w_pl.user = IF_vwrap.m_card_axi.wuser;

  assign IF_vwrap.h2c_paxi_if.b_vld = IF_vwrap.m_card_axi.bvalid;
  assign IF_vwrap.h2c_paxi_if.b_rdy = IF_vwrap.m_card_axi.bready;
  assign IF_vwrap.h2c_paxi_if.b_pl.id = IF_vwrap.m_card_axi.bid;
  assign IF_vwrap.h2c_paxi_if.b_pl.resp = IF_vwrap.m_card_axi.bresp;
  assign IF_vwrap.h2c_paxi_if.b_pl.user = IF_vwrap.m_card_axi.buser;

  assign IF_vwrap.h2c_paxi_if.ar_vld = IF_vwrap.m_host_axi.arvalid;
  assign IF_vwrap.h2c_paxi_if.ar_rdy = IF_vwrap.m_host_axi.arready;
  assign IF_vwrap.h2c_paxi_if.ar_pl.id = IF_vwrap.m_host_axi.arid;
  assign IF_vwrap.h2c_paxi_if.ar_pl.addr = IF_vwrap.m_host_axi.araddr;
  assign IF_vwrap.h2c_paxi_if.ar_pl.len = IF_vwrap.m_host_axi.arlen;
  assign IF_vwrap.h2c_paxi_if.ar_pl.size = IF_vwrap.m_host_axi.arsize;
  assign IF_vwrap.h2c_paxi_if.ar_pl.burst = IF_vwrap.m_host_axi.arburst;
  assign IF_vwrap.h2c_paxi_if.ar_pl.cache = IF_vwrap.m_host_axi.arcache;
  assign IF_vwrap.h2c_paxi_if.ar_pl.lock = IF_vwrap.m_host_axi.arlock;
  assign IF_vwrap.h2c_paxi_if.ar_pl.prot = IF_vwrap.m_host_axi.arprot;
  assign IF_vwrap.h2c_paxi_if.ar_pl.qos = IF_vwrap.m_host_axi.arqos;
  assign IF_vwrap.h2c_paxi_if.ar_pl.user = IF_vwrap.m_host_axi.aruser;

  assign IF_vwrap.h2c_paxi_if.r_vld = IF_vwrap.m_host_axi.rvalid;
  assign IF_vwrap.h2c_paxi_if.r_rdy = IF_vwrap.m_host_axi.rready;
  assign IF_vwrap.h2c_paxi_if.r_pl.id = IF_vwrap.m_host_axi.rid;
  assign IF_vwrap.h2c_paxi_if.r_pl.resp = IF_vwrap.m_host_axi.rresp;
  assign IF_vwrap.h2c_paxi_if.r_pl.data = IF_vwrap.m_host_axi.rdata;
  assign IF_vwrap.h2c_paxi_if.r_pl.last = IF_vwrap.m_host_axi.rlast;
  assign IF_vwrap.h2c_paxi_if.r_pl.user = IF_vwrap.m_host_axi.ruser;
//---------------------------------------------------------------------------------------------


  initial begin
    string cfgdb_key; 

    rptr = new("vdmatb_vwrap");
    
    cfgdb_key = "vdmatb_mm";
    `vmg_set_cfgdb_anyone_w_rptr_inform(AxiPortParam_t, $sformatf("HOST_AXI_PORT_PARAM"), HOST_AXI_PORT_PARAM)
    `vmg_set_cfgdb_anyone_w_rptr_inform(AxiPortParam_t, $sformatf("CARD_AXI_PORT_PARAM"), CARD_AXI_PORT_PARAM)
    `vmg_set_cfgdb_anyone_w_rptr_inform(virtual svt_axi_if, $sformatf("%s", cfgdb_key), IF_vwrap.axi_if)
    `vmg_set_cfgdb_anyone_w_rptr_inform(MmDmaDesignParam_t, $sformatf("%s_MM_DUT_PARAM", cfgdb_key), vdmatb_vwrap_pkg::MM_DUT_PARAM)

    A_pdma_mm_ip_c2h_mon.WaitMngrHandle(mm_c2h_mon_mngr);
    A_pdma_mm_ip_h2c_mon.WaitMngrHandle(mm_h2c_mon_mngr);
  
    `vmg_set_cfgdb_anyone_w_rptr_inform(pdma_mm_ip_c2h_mon_mngr, $sformatf("%s_c2h_pmon_mngr", cfgdb_key), mm_c2h_mon_mngr)
    `vmg_set_cfgdb_anyone_w_rptr_inform(pdma_mm_ip_h2c_mon_mngr, $sformatf("%s_h2c_pmon_mngr", cfgdb_key), mm_h2c_mon_mngr)
  end


endmodule:vdmatb_vwrap


`endif // __VDMATB_VWRAP_SV__
