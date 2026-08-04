`ifndef __VDMATB_VWRAP_SV__
`define __VDMATB_VWRAP_SV__


//`define IP_PMON_ENABLE
//`define ITF_PMON_ENABLE

module vdmatb_vwrap
  `vdmatb_import_core_pkg
  import vdmatb_vwrap_pkg::*;
  
(
  dmg_clk_if      IF_clk,
  vdmatb_vwrap_if IF_vwrap
);

  vmg_rptr rptr;

//  localparam int DUT_TDATA_WIDTH = 512;






//------------------------------------- PMON
  pdma_st_ip_c2h_mon_mngr ip_c2h_mon_mngr;
  pdma_st_ip_h2c_mon_mngr ip_h2c_mon_mngr;
  

//--------------------------------------

  //DmaST_symmetric_basic A_DUT(
  DmaST_pdma A_DUT(
  
    .i_clk (IF_clk.CLK),
    .i_rsn (IF_clk.RESETn),
  
    .s_h2c_desc_VALID           (IF_vwrap.s_h2c_dma.desc_valid),
    .s_h2c_desc_READY           (IF_vwrap.s_h2c_dma.desc_ready),
    .s_h2c_desc_dma_id          (IF_vwrap.s_h2c_dma.desc_dma_id[vdmatb_vwrap_pkg::ST_DUT_PARAM.DMA_ID_WIDTH - 1:0]),
    .s_h2c_desc_str_id          (IF_vwrap.s_h2c_dma.desc_str_id),
    .s_h2c_desc_fnc_id          (IF_vwrap.s_h2c_dma.desc_fnc_id),
    .s_h2c_desc_vec_id          (IF_vwrap.s_h2c_dma.desc_vec_id),
    .s_h2c_desc_src_byte_addr   (IF_vwrap.s_h2c_dma.desc_addr[vdmatb_vwrap_pkg::ST_DUT_PARAM.HAXI_ADDR_WIDTH - 1:0]),
    .s_h2c_desc_len_in_byte     (IF_vwrap.s_h2c_dma.desc_len),
    .s_h2c_desc_req_intr        (IF_vwrap.s_h2c_dma.desc_req_intr),
    .s_h2c_desc_req_stat        (IF_vwrap.s_h2c_dma.desc_req_stat),
    .s_h2c_desc_sop             (IF_vwrap.s_h2c_dma.desc_sop),
    .s_h2c_desc_eop             (IF_vwrap.s_h2c_dma.desc_eop),
    .s_h2c_desc_max_hburst_len  (IF_vwrap.s_h2c_dma.desc_axi_max_len),
    .m_card_axis_TVALID         (IF_vwrap.s_h2c_dma.data_valid),
    .m_card_axis_TREADY         (IF_vwrap.s_h2c_dma.data_ready),
    .m_card_axis_TDATA          (IF_vwrap.s_h2c_dma.data_value[vdmatb_vwrap_pkg::ST_DUT_PARAM.AXIS_DATA_WIDTH - 1:0]),
    .m_card_axis_TLAST          (IF_vwrap.s_h2c_dma.data_last),
    .m_card_axis_TUSER          ({IF_vwrap.s_h2c_dma.data_side_info[(MAX_MTY_WIDTH + MAX_DMA_ID_WIDTH - 1):MAX_DMA_ID_WIDTH], IF_vwrap.s_h2c_dma.data_side_info[vdmatb_vwrap_pkg::ST_DUT_PARAM.DMA_ID_WIDTH - 1:0]}),
    .m_h2c_status_VALID         (IF_vwrap.s_h2c_dma.status_valid),
    .m_h2c_status_READY         (IF_vwrap.s_h2c_dma.status_ready),
    .m_h2c_status_dma_id        (IF_vwrap.s_h2c_dma.status_dma_id[vdmatb_vwrap_pkg::ST_DUT_PARAM.DMA_ID_WIDTH - 1:0]),
    .m_h2c_status_status_msg    (IF_vwrap.s_h2c_dma.status_msg),
    .m_h2c_interrupt_VALID      (IF_vwrap.s_h2c_dma.interrupt_valid),
    .m_h2c_interrupt_READY      (IF_vwrap.s_h2c_dma.interrupt_ready),
    .m_h2c_interrupt_dma_id     (IF_vwrap.s_h2c_dma.interrupt_dma_id[vdmatb_vwrap_pkg::ST_DUT_PARAM.DMA_ID_WIDTH - 1:0]),
    .m_h2c_interrupt_fnc_id     (IF_vwrap.s_h2c_dma.interrupt_fnc_id),
    .m_h2c_interrupt_vec_id     (IF_vwrap.s_h2c_dma.interrupt_vec_id),
    .m_h2c_fault_VALID          (IF_vwrap.s_h2c_dma.fault_valid),
    .m_h2c_fault_READY          (IF_vwrap.s_h2c_dma.fault_ready),
    .m_h2c_fault_dma_id         (IF_vwrap.s_h2c_dma.fault_dma_id[vdmatb_vwrap_pkg::ST_DUT_PARAM.DMA_ID_WIDTH - 1:0]),
    .m_h2c_fault_str_id         (IF_vwrap.s_h2c_dma.fault_str_id),
    .m_h2c_fault_fault_code     (IF_vwrap.s_h2c_dma.fault_code),
    .m_h2c_fault_axi_resp       (IF_vwrap.s_h2c_dma.fault_axi_resp),
    .o_h2c_num_entry            (IF_vwrap.s_h2c_dma.num_entry),
    .o_h2c_num_pending          (IF_vwrap.s_h2c_dma.num_pending),
  
    .s_c2h_desc_VALID           (IF_vwrap.s_c2h_dma.desc_valid),
    .s_c2h_desc_READY           (IF_vwrap.s_c2h_dma.desc_ready),
    .s_c2h_desc_dma_id          (IF_vwrap.s_c2h_dma.desc_dma_id[vdmatb_vwrap_pkg::ST_DUT_PARAM.DMA_ID_WIDTH - 1:0]),
    .s_c2h_desc_str_id          (IF_vwrap.s_c2h_dma.desc_str_id),
    .s_c2h_desc_fnc_id          (IF_vwrap.s_c2h_dma.desc_fnc_id),
    .s_c2h_desc_vec_id          (IF_vwrap.s_c2h_dma.desc_vec_id),
    .s_c2h_desc_dst_byte_addr   (IF_vwrap.s_c2h_dma.desc_addr[vdmatb_vwrap_pkg::ST_DUT_PARAM.HAXI_ADDR_WIDTH - 1:0]),
    .s_c2h_desc_len_in_byte     (IF_vwrap.s_c2h_dma.desc_len),
    .s_c2h_desc_req_intr        (IF_vwrap.s_c2h_dma.desc_req_intr),
    .s_c2h_desc_req_stat        (IF_vwrap.s_c2h_dma.desc_req_stat),
    .s_c2h_desc_max_hburst_len  (IF_vwrap.s_c2h_dma.desc_axi_max_len),
    .s_card_axis_TVALID         (IF_vwrap.s_c2h_dma.data_valid),
    .s_card_axis_TREADY         (IF_vwrap.s_c2h_dma.data_ready),
    .s_card_axis_TDATA          (IF_vwrap.s_c2h_dma.data_value[vdmatb_vwrap_pkg::ST_DUT_PARAM.AXIS_DATA_WIDTH - 1:0]),   //check this!!! //updated by jaewoo
    .s_card_axis_TLAST          (IF_vwrap.s_c2h_dma.data_last),
    .s_card_axis_TUSER          ({IF_vwrap.s_c2h_dma.data_side_info[(MAX_MTY_WIDTH + MAX_DMA_ID_WIDTH - 1):MAX_DMA_ID_WIDTH], IF_vwrap.s_c2h_dma.data_side_info[vdmatb_vwrap_pkg::ST_DUT_PARAM.DMA_ID_WIDTH - 1:0]}),
    .m_c2h_status_VALID         (IF_vwrap.s_c2h_dma.status_valid),
    .m_c2h_status_READY         (IF_vwrap.s_c2h_dma.status_ready),
    .m_c2h_status_dma_id        (IF_vwrap.s_c2h_dma.status_dma_id[vdmatb_vwrap_pkg::ST_DUT_PARAM.DMA_ID_WIDTH - 1:0]),
    .m_c2h_status_status_msg    (IF_vwrap.s_c2h_dma.status_msg),
    .m_c2h_interrupt_VALID      (IF_vwrap.s_c2h_dma.interrupt_valid),
    .m_c2h_interrupt_READY      (IF_vwrap.s_c2h_dma.interrupt_ready),
    .m_c2h_interrupt_dma_id     (IF_vwrap.s_c2h_dma.interrupt_dma_id[vdmatb_vwrap_pkg::ST_DUT_PARAM.DMA_ID_WIDTH - 1:0]),
    .m_c2h_interrupt_fnc_id     (IF_vwrap.s_c2h_dma.interrupt_fnc_id),
    .m_c2h_interrupt_vec_id     (IF_vwrap.s_c2h_dma.interrupt_vec_id),
    .m_c2h_fault_VALID          (IF_vwrap.s_c2h_dma.fault_valid),
    .m_c2h_fault_READY          (IF_vwrap.s_c2h_dma.fault_ready),
    .m_c2h_fault_dma_id         (IF_vwrap.s_c2h_dma.fault_dma_id[vdmatb_vwrap_pkg::ST_DUT_PARAM.DMA_ID_WIDTH - 1:0]),
    .m_c2h_fault_str_id         (IF_vwrap.s_c2h_dma.fault_str_id),
    .m_c2h_fault_fault_code     (IF_vwrap.s_c2h_dma.fault_code),
    .m_c2h_fault_axi_resp       (IF_vwrap.s_c2h_dma.fault_axi_resp),
    .o_c2h_num_entry            (IF_vwrap.s_c2h_dma.num_entry),
    .o_c2h_num_pending          (IF_vwrap.s_c2h_dma.num_pending),


    .m_host_axi_ARVALID (IF_vwrap.m_host_axi.arvalid),
    .m_host_axi_ARREADY (IF_vwrap.m_host_axi.arready),
    .m_host_axi_ARID    (IF_vwrap.m_host_axi.arid),
    .m_host_axi_ARADDR  (IF_vwrap.m_host_axi.araddr),
    .m_host_axi_ARBURST (IF_vwrap.m_host_axi.arburst),
    .m_host_axi_ARLEN   (IF_vwrap.m_host_axi.arlen),
//  .m_host_axi_ARSIZE  (IF_vwrap.m_host_axi.arsize),
    .m_host_axi_ARCACHE (IF_vwrap.m_host_axi.arcache),
//  .m_host_axi_ARLOCK  (IF_vwrap.m_host_axi.arlock),
    .m_host_axi_ARUSER  (IF_vwrap.m_host_axi.aruser),
//  .m_host_axi_ARQOS   (IF_vwrap.m_host_axi.arqos),
//  .m_host_axi_ARPROT  (IF_vwrap.m_host_axi.arprot),
    .m_host_axi_RVALID  (IF_vwrap.m_host_axi.rvalid),
    .m_host_axi_RREADY  (IF_vwrap.m_host_axi.rready),
    .m_host_axi_RID     (IF_vwrap.m_host_axi.rid),
    .m_host_axi_RDATA   (IF_vwrap.m_host_axi.rdata),
    .m_host_axi_RRESP   (IF_vwrap.m_host_axi.rresp[1:0]),
    .m_host_axi_RLAST   (IF_vwrap.m_host_axi.rlast),
//  .m_host_axi_RUSER   (IF_vwrap.m_host_axi.ruser),
    .m_host_axi_AWVALID (IF_vwrap.m_host_axi.awvalid),
    .m_host_axi_AWREADY (IF_vwrap.m_host_axi.awready),
    .m_host_axi_AWID    (IF_vwrap.m_host_axi.awid),
    .m_host_axi_AWADDR  (IF_vwrap.m_host_axi.awaddr),
    .m_host_axi_AWBURST (IF_vwrap.m_host_axi.awburst),
    .m_host_axi_AWLEN   (IF_vwrap.m_host_axi.awlen),
//  .m_host_axi_AWSIZE  (IF_vwrap.m_host_axi.awsize),
    .m_host_axi_AWCACHE (IF_vwrap.m_host_axi.awcache),
//  .m_host_axi_AWLOCK  (IF_vwrap.m_host_axi.awlock),
    .m_host_axi_AWUSER  (IF_vwrap.m_host_axi.awuser),
//  .m_host_axi_AWQOS   (IF_vwrap.m_host_axi.awqos),
//  .m_host_axi_AWPROT  (IF_vwrap.m_host_axi.awprot),
    .m_host_axi_WVALID  (IF_vwrap.m_host_axi.wvalid),
    .m_host_axi_WREADY  (IF_vwrap.m_host_axi.wready),
    .m_host_axi_WDATA   (IF_vwrap.m_host_axi.wdata),
    .m_host_axi_WLAST   (IF_vwrap.m_host_axi.wlast),
    .m_host_axi_WSTRB   (IF_vwrap.m_host_axi.wstrb),
//  .m_host_axi_WUSER   (IF_vwrap.m_host_axi.wuser),
    .m_host_axi_BVALID  (IF_vwrap.m_host_axi.bvalid),
    .m_host_axi_BREADY  (IF_vwrap.m_host_axi.bready),
    .m_host_axi_BID     (IF_vwrap.m_host_axi.bid),
    .m_host_axi_BRESP   (IF_vwrap.m_host_axi.bresp[1:0]),
//  .m_host_axi_BUSER   (IF_vwrap.m_host_axi.buser),
  
  
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
  
  
  assign IF_vwrap.m_host_axi.arsize = DMAST_HAXI_AXSIZE;
  assign IF_vwrap.m_host_axi.arlock = 0;
  assign IF_vwrap.m_host_axi.arqos  = 0;
  assign IF_vwrap.m_host_axi.arprot = 0;

  assign IF_vwrap.m_host_axi.awsize = DMAST_HAXI_AXSIZE;
  assign IF_vwrap.m_host_axi.awlock = 0;
  assign IF_vwrap.m_host_axi.awqos  = 0;
  assign IF_vwrap.m_host_axi.awprot = 0;
 
  assign IF_vwrap.m_host_axi.wuser = 0;
//  assign IF_vwrap.m_host_axi.buser = 0;
//  assign IF_vwrap.m_host_axi.ruser = 0;

  assign IF_vwrap.s_c2h_dma.data_value[MAX_DATA_WIDTH - 1:vdmatb_vwrap_pkg::ST_DUT_PARAM.AXIS_DATA_WIDTH] = 0;
  assign IF_vwrap.s_h2c_dma.data_value[MAX_DATA_WIDTH - 1:vdmatb_vwrap_pkg::ST_DUT_PARAM.AXIS_DATA_WIDTH] = 0;
	
//assign IF_vwrap.axi_if.master_if[0].common_aclk = IF_clk.CLK;
  assign IF_vwrap.axi_if.master_if[0].arvalid =    IF_vwrap.m_host_axi.arvalid;
  assign IF_vwrap.axi_if.master_if[0].arready =    IF_vwrap.m_host_axi.arready;
  assign IF_vwrap.axi_if.master_if[0].arid =       IF_vwrap.m_host_axi.arid;
  assign IF_vwrap.axi_if.master_if[0].araddr =     IF_vwrap.m_host_axi.araddr;
  assign IF_vwrap.axi_if.master_if[0].arburst =    IF_vwrap.m_host_axi.arburst;
  assign IF_vwrap.axi_if.master_if[0].arlen =      IF_vwrap.m_host_axi.arlen;
//assign IF_vwrap.axi_if.master_if[0].arsize =     IF_vwrap.m_host_axi.arsize;
  assign IF_vwrap.axi_if.master_if[0].arcache =    IF_vwrap.m_host_axi.arcache;
//assign IF_vwrap.axi_if.master_if[0].arlock =     IF_vwrap.m_host_axi.arlock;
  assign IF_vwrap.axi_if.master_if[0].aruser =     IF_vwrap.m_host_axi.aruser;
//assign IF_vwrap.axi_if.master_if[0].arqos =      IF_vwrap.m_host_axi.arqos;
//assign IF_vwrap.axi_if.master_if[0].arprot =     IF_vwrap.m_host_axi.arprot;
  assign IF_vwrap.axi_if.master_if[0].rvalid =     IF_vwrap.m_host_axi.rvalid;
  assign IF_vwrap.axi_if.master_if[0].rready =     IF_vwrap.m_host_axi.rready;
  assign IF_vwrap.axi_if.master_if[0].rid =        IF_vwrap.m_host_axi.rid;
  assign IF_vwrap.axi_if.master_if[0].rdata =      IF_vwrap.m_host_axi.rdata;
  assign IF_vwrap.axi_if.master_if[0].rresp[1:0] = IF_vwrap.m_host_axi.rresp[1:0];
  assign IF_vwrap.axi_if.master_if[0].rlast =      IF_vwrap.m_host_axi.rlast;
//assign IF_vwrap.axi_if.master_if[0].ruser =      IF_vwrap.m_host_axi.ruser;
  assign IF_vwrap.axi_if.master_if[0].awvalid =    IF_vwrap.m_host_axi.awvalid;
  assign IF_vwrap.axi_if.master_if[0].awready =    IF_vwrap.m_host_axi.awready;
  assign IF_vwrap.axi_if.master_if[0].awid =       IF_vwrap.m_host_axi.awid;
  assign IF_vwrap.axi_if.master_if[0].awaddr =     IF_vwrap.m_host_axi.awaddr;
  assign IF_vwrap.axi_if.master_if[0].awburst =    IF_vwrap.m_host_axi.awburst;
  assign IF_vwrap.axi_if.master_if[0].awlen =      IF_vwrap.m_host_axi.awlen;
//assign IF_vwrap.axi_if.master_if[0].awsize =     IF_vwrap.m_host_axi.awsize;
  assign IF_vwrap.axi_if.master_if[0].awcache =    IF_vwrap.m_host_axi.awcache;
//assign IF_vwrap.axi_if.master_if[0].awlock =     IF_vwrap.m_host_axi.awlock;
  assign IF_vwrap.axi_if.master_if[0].awuser =     IF_vwrap.m_host_axi.awuser;
//assign IF_vwrap.axi_if.master_if[0].awqos =      IF_vwrap.m_host_axi.awqos;
//assign IF_vwrap.axi_if.master_if[0].awprot =     IF_vwrap.m_host_axi.awprot;
  assign IF_vwrap.axi_if.master_if[0].wvalid =     IF_vwrap.m_host_axi.wvalid;
  assign IF_vwrap.axi_if.master_if[0].wready =     IF_vwrap.m_host_axi.wready;
  assign IF_vwrap.axi_if.master_if[0].wdata =      IF_vwrap.m_host_axi.wdata;
  assign IF_vwrap.axi_if.master_if[0].wlast =      IF_vwrap.m_host_axi.wlast;
  assign IF_vwrap.axi_if.master_if[0].wstrb =      IF_vwrap.m_host_axi.wstrb;
//assign IF_vwrap.axi_if.master_if[0].wuser =      IF_vwrap.m_host_axi.wuser;
  assign IF_vwrap.axi_if.master_if[0].bvalid =     IF_vwrap.m_host_axi.bvalid;
  assign IF_vwrap.axi_if.master_if[0].bready =     IF_vwrap.m_host_axi.bready;
  assign IF_vwrap.axi_if.master_if[0].bid =        IF_vwrap.m_host_axi.bid;
  assign IF_vwrap.axi_if.master_if[0].bresp =      IF_vwrap.m_host_axi.bresp;
//assign IF_vwrap.axi_if.master_if[0].buser =      IF_vwrap.m_host_axi.buser;



//-------------------------------------- PMON
pdma_st_ip_c2h_mon#(.MYNAME ("A_pdma_st_ip_c2h_mon")) A_pdma_st_ip_c2h_mon(.*, .IF_paxi(IF_vwrap.paxi_if), .IF_st_c2h(IF_vwrap.s_c2h_dma));
pdma_st_ip_h2c_mon#(.MYNAME ("A_pdma_st_ip_h2c_mon")) A_pdma_st_ip_h2c_mon(.*, .IF_paxi(IF_vwrap.paxi_if), .IF_st_h2c(IF_vwrap.s_h2c_dma));

//---------------------------------------------------------------------------------------------
//PMON interconnection
//---------------------------------------------------------------------------------------------
//C2H

  //-------------------------------------------------------- for type_casting
  assign IF_vwrap.s_c2h_dma.desc_pl.dma_id = IF_vwrap.s_c2h_dma.desc_dma_id;
  assign IF_vwrap.s_c2h_dma.desc_pl.str_id = IF_vwrap.s_c2h_dma.desc_str_id;
  assign IF_vwrap.s_c2h_dma.desc_pl.fnc_id = IF_vwrap.s_c2h_dma.desc_fnc_id;
  assign IF_vwrap.s_c2h_dma.desc_pl.vec_id = IF_vwrap.s_c2h_dma.desc_vec_id;
  assign IF_vwrap.s_c2h_dma.desc_pl.dst_addr = IF_vwrap.s_c2h_dma.desc_addr;
  assign IF_vwrap.s_c2h_dma.desc_pl.len = IF_vwrap.s_c2h_dma.desc_len;
  assign IF_vwrap.s_c2h_dma.desc_pl.req_intr = IF_vwrap.s_c2h_dma.desc_req_intr;
  assign IF_vwrap.s_c2h_dma.desc_pl.req_stat = IF_vwrap.s_c2h_dma.desc_req_stat;
  assign IF_vwrap.s_c2h_dma.desc_pl.axi_max_len = IF_vwrap.s_c2h_dma.desc_axi_max_len;

  assign IF_vwrap.s_c2h_dma.data_pl.value = IF_vwrap.s_c2h_dma.data_value;
  assign IF_vwrap.s_c2h_dma.data_pl.last = IF_vwrap.s_c2h_dma.data_last;
  assign IF_vwrap.s_c2h_dma.data_pl.side_info = IF_vwrap.s_c2h_dma.data_side_info;

  assign IF_vwrap.s_c2h_dma.status_pl.dma_id = IF_vwrap.s_c2h_dma.status_dma_id;
  assign IF_vwrap.s_c2h_dma.status_pl.msg = IF_vwrap.s_c2h_dma.status_msg;

  assign IF_vwrap.s_c2h_dma.interrupt_pl.dma_id = IF_vwrap.s_c2h_dma.interrupt_dma_id;
  assign IF_vwrap.s_c2h_dma.interrupt_pl.fnc_id = IF_vwrap.s_c2h_dma.interrupt_fnc_id;
  assign IF_vwrap.s_c2h_dma.interrupt_pl.vec_id = IF_vwrap.s_c2h_dma.interrupt_vec_id;

  assign IF_vwrap.s_c2h_dma.fault_pl.dma_id = IF_vwrap.s_c2h_dma.fault_dma_id;
  assign IF_vwrap.s_c2h_dma.fault_pl.str_id = IF_vwrap.s_c2h_dma.fault_str_id;
  assign IF_vwrap.s_c2h_dma.fault_pl.code = IF_vwrap.s_c2h_dma.fault_code;
  assign IF_vwrap.s_c2h_dma.fault_pl.axi_resp = IF_vwrap.s_c2h_dma.fault_axi_resp;
//---------------------------------------------------------------------------------------------
//PAXI_WR
//paxi_wr_mon#(.MYNAME ("A_paxi_wr_mon")) A_paxi_wr_mon(.*, .IF_mon(IF_vwrap.paxi_if.wrmon));
  assign IF_vwrap.paxi_if.aw_vld = IF_vwrap.m_host_axi.awvalid;
  assign IF_vwrap.paxi_if.aw_rdy = IF_vwrap.m_host_axi.awready;
  assign IF_vwrap.paxi_if.aw_pl.id = IF_vwrap.m_host_axi.awid;
  assign IF_vwrap.paxi_if.aw_pl.addr = IF_vwrap.m_host_axi.awaddr;
  assign IF_vwrap.paxi_if.aw_pl.len = IF_vwrap.m_host_axi.awlen;
  assign IF_vwrap.paxi_if.aw_pl.size = AxiSize_t'(IF_vwrap.m_host_axi.awsize);
  assign IF_vwrap.paxi_if.aw_pl.burst = AxiBurstType_t'(IF_vwrap.m_host_axi.awburst);
  assign IF_vwrap.paxi_if.aw_pl.cache = IF_vwrap.m_host_axi.awcache;
  assign IF_vwrap.paxi_if.aw_pl.lock = IF_vwrap.m_host_axi.awlock;
  assign IF_vwrap.paxi_if.aw_pl.prot = IF_vwrap.m_host_axi.awprot;
  assign IF_vwrap.paxi_if.aw_pl.qos = IF_vwrap.m_host_axi.awqos;
  assign IF_vwrap.paxi_if.aw_pl.user = IF_vwrap.m_host_axi.awuser;

  assign IF_vwrap.paxi_if.w_vld = IF_vwrap.m_host_axi.wvalid;
  assign IF_vwrap.paxi_if.w_rdy = IF_vwrap.m_host_axi.wready;
  assign IF_vwrap.paxi_if.w_pl.data = IF_vwrap.m_host_axi.wdata;
  assign IF_vwrap.paxi_if.w_pl.strb = IF_vwrap.m_host_axi.wstrb;
  assign IF_vwrap.paxi_if.w_pl.last = IF_vwrap.m_host_axi.wlast;
  assign IF_vwrap.paxi_if.w_pl.user = IF_vwrap.m_host_axi.wuser;

  assign IF_vwrap.paxi_if.b_vld = IF_vwrap.m_host_axi.bvalid;
  assign IF_vwrap.paxi_if.b_rdy = IF_vwrap.m_host_axi.bready;
  assign IF_vwrap.paxi_if.b_pl.id = IF_vwrap.m_host_axi.bid;
  assign IF_vwrap.paxi_if.b_pl.resp = AxiRespType_t'(IF_vwrap.m_host_axi.bresp);
  assign IF_vwrap.paxi_if.b_pl.user = IF_vwrap.m_host_axi.buser;
//---------------------------------------------------------------------------------------------
//H2C
//pdma_st_h2c_mon#(.MYNAME ("A_pdma_st_h2c_mon")) A_pdma_st_h2c_mon(.*, .IF_mon(IF_vwrap.s_h2c_dma));

//----------------------------------------------------------- for type_casting
 
  assign IF_vwrap.s_h2c_dma.desc_pl.dma_id = IF_vwrap.s_h2c_dma.desc_dma_id;
  assign IF_vwrap.s_h2c_dma.desc_pl.str_id = IF_vwrap.s_h2c_dma.desc_str_id;
  assign IF_vwrap.s_h2c_dma.desc_pl.fnc_id = IF_vwrap.s_h2c_dma.desc_fnc_id;
  assign IF_vwrap.s_h2c_dma.desc_pl.vec_id = IF_vwrap.s_h2c_dma.desc_vec_id;
  assign IF_vwrap.s_h2c_dma.desc_pl.src_addr = IF_vwrap.s_h2c_dma.desc_addr;
//assign IF_vwrap.s_h2c_dma.desc_pl.dst_addr = IF_vwrap.s_h2c_dma.desc_addr;
  assign IF_vwrap.s_h2c_dma.desc_pl.len = IF_vwrap.s_h2c_dma.desc_len;
  assign IF_vwrap.s_h2c_dma.desc_pl.req_intr = IF_vwrap.s_h2c_dma.desc_req_intr;
  assign IF_vwrap.s_h2c_dma.desc_pl.req_stat = IF_vwrap.s_h2c_dma.desc_req_stat;
  assign IF_vwrap.s_h2c_dma.desc_pl.axi_max_len = IF_vwrap.s_h2c_dma.desc_axi_max_len;
  assign IF_vwrap.s_h2c_dma.desc_pl.sop = IF_vwrap.s_h2c_dma.desc_sop;
  assign IF_vwrap.s_h2c_dma.desc_pl.eop = IF_vwrap.s_h2c_dma.desc_eop;

  assign IF_vwrap.s_h2c_dma.data_pl.value = IF_vwrap.s_h2c_dma.data_value;
  assign IF_vwrap.s_h2c_dma.data_pl.last = IF_vwrap.s_h2c_dma.data_last;
//  assign IF_vwrap.s_h2c_dma.data_pl.side_info.dma_id = DutParamDmaId_t'(IF_vwrap.s_h2c_dma.data_pl.side_info.dma_id);
//  assign IF_vwrap.s_h2c_dma.data_pl.side_info.mty    = DutParamEmpty_t'(IF_vwrap.s_h2c_dma.data_pl.side_info.dma_id);
  assign IF_vwrap.s_h2c_dma.data_pl.side_info = IF_vwrap.s_h2c_dma.data_side_info;

  assign IF_vwrap.s_h2c_dma.status_pl.dma_id = IF_vwrap.s_h2c_dma.status_dma_id;
  assign IF_vwrap.s_h2c_dma.status_pl.msg = IF_vwrap.s_h2c_dma.status_msg;

  assign IF_vwrap.s_h2c_dma.interrupt_pl.dma_id = IF_vwrap.s_h2c_dma.interrupt_dma_id;
  assign IF_vwrap.s_h2c_dma.interrupt_pl.fnc_id = IF_vwrap.s_h2c_dma.interrupt_fnc_id;
  assign IF_vwrap.s_h2c_dma.interrupt_pl.vec_id = IF_vwrap.s_h2c_dma.interrupt_vec_id;

  assign IF_vwrap.s_h2c_dma.fault_pl.dma_id = IF_vwrap.s_h2c_dma.fault_dma_id;
  assign IF_vwrap.s_h2c_dma.fault_pl.str_id = IF_vwrap.s_h2c_dma.fault_str_id;
  assign IF_vwrap.s_h2c_dma.fault_pl.code = IF_vwrap.s_h2c_dma.fault_code;
  assign IF_vwrap.s_h2c_dma.fault_pl.axi_resp = IF_vwrap.s_h2c_dma.fault_axi_resp;
//---------------------------------------------------------------------------------------------
//PAXI_RD
//paxi_rd_mon#(.MYNAME ("A_paxi_rd_mon")) A_paxi_rd_mon(.*, .IF_mon(IF_vwrap.paxi_if.rdmon));
  assign IF_vwrap.paxi_if.ar_vld = IF_vwrap.m_host_axi.arvalid;
  assign IF_vwrap.paxi_if.ar_rdy = IF_vwrap.m_host_axi.arready;
  assign IF_vwrap.paxi_if.ar_pl.id = IF_vwrap.m_host_axi.arid;
  assign IF_vwrap.paxi_if.ar_pl.addr = IF_vwrap.m_host_axi.araddr;
  assign IF_vwrap.paxi_if.ar_pl.len = IF_vwrap.m_host_axi.arlen;
  assign IF_vwrap.paxi_if.ar_pl.size = AxiSize_t'(IF_vwrap.m_host_axi.arsize);
  assign IF_vwrap.paxi_if.ar_pl.burst = AxiBurstType_t'(IF_vwrap.m_host_axi.arburst);
  assign IF_vwrap.paxi_if.ar_pl.cache = IF_vwrap.m_host_axi.arcache;
  assign IF_vwrap.paxi_if.ar_pl.lock = IF_vwrap.m_host_axi.arlock;
  assign IF_vwrap.paxi_if.ar_pl.prot = IF_vwrap.m_host_axi.arprot;
  assign IF_vwrap.paxi_if.ar_pl.qos = IF_vwrap.m_host_axi.arqos;
  assign IF_vwrap.paxi_if.ar_pl.user = IF_vwrap.m_host_axi.aruser;
  
  assign IF_vwrap.paxi_if.r_vld = IF_vwrap.m_host_axi.rvalid;
  assign IF_vwrap.paxi_if.r_rdy = IF_vwrap.m_host_axi.rready;
  assign IF_vwrap.paxi_if.r_pl.id = IF_vwrap.m_host_axi.rid;
  assign IF_vwrap.paxi_if.r_pl.resp = AxiRespType_t'(IF_vwrap.m_host_axi.rresp);
  assign IF_vwrap.paxi_if.r_pl.data = IF_vwrap.m_host_axi.rdata;
  assign IF_vwrap.paxi_if.r_pl.last = IF_vwrap.m_host_axi.rlast;
  assign IF_vwrap.paxi_if.r_pl.user = IF_vwrap.m_host_axi.ruser;
//---------------------------------------------------------------------------------------------



  initial begin
    string cfgdb_key; 
  
    PMG_CFGDB.setClkVif(IF_clk);
    rptr = new("vdmatb_vwrap");
    
    cfgdb_key = "vdmatb_st";
    `vmg_set_cfgdb_anyone_w_rptr_inform(AxiPortParam_t, $sformatf("HOST_AXI_PORT_PARAM"), HOST_AXI_PORT_PARAM)
    `vmg_set_cfgdb_anyone_w_rptr_inform(virtual svt_axi_if, $sformatf("%s", cfgdb_key), IF_vwrap.axi_if)
    `vmg_set_cfgdb_anyone_w_rptr_inform(StDmaDesignParam_t, $sformatf("%s_ST_DUT_PARAM", cfgdb_key), vdmatb_vwrap_pkg::ST_DUT_PARAM)
  
    A_pdma_st_ip_c2h_mon.WaitMngrHandle(ip_c2h_mon_mngr);
    A_pdma_st_ip_h2c_mon.WaitMngrHandle(ip_h2c_mon_mngr);
  
    `vmg_set_cfgdb_anyone_w_rptr_inform(pdma_st_ip_c2h_mon_mngr, $sformatf("%s_c2h_pmon_mngr", cfgdb_key), ip_c2h_mon_mngr)
    `vmg_set_cfgdb_anyone_w_rptr_inform(pdma_st_ip_h2c_mon_mngr, $sformatf("%s_h2c_pmon_mngr", cfgdb_key), ip_h2c_mon_mngr)
  
  end
  
 

endmodule:vdmatb_vwrap

`endif // __VDMATB_VWRAP_SV__
