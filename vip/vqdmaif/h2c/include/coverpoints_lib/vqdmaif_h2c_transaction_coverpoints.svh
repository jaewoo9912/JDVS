  CP_CMD_FUNC : coverpoint h2c_sub_trans.cmd_pl.func {
    `vtrans_coverbin_divide_by_16(QdmaFunc_t'(-1))
  }

  CP_CMD_ADDR : coverpoint h2c_sub_trans.cmd_pl.addr {
    `vtrans_coverbin_divide_by_64(max_addr)
  }

  CP_CMD_CIDX     : coverpoint h2c_sub_trans.cmd_pl.cidx {
    `vtrans_coverbin_divide_by_16(QdmaCIdx_t'(-1))
  }

  CP_CMD_LEN      : coverpoint h2c_sub_trans.cmd_pl.len {
    `vtrans_coverbin_divide_by_16(QdmaLen_t'(-1))
  }

  CP_CMD_QID      : coverpoint h2c_sub_trans.qid;
  CP_CMD_PORT_ID  : coverpoint h2c_sub_trans.cmd_pl.port_id;
  CP_CMD_SOP      : coverpoint h2c_sub_trans.cmd_pl.sop;
  CP_CMD_EOP      : coverpoint h2c_sub_trans.cmd_pl.eop;
  CP_CMD_ERROR    : coverpoint h2c_sub_trans.cmd_pl.error;
  CP_CMD_MRKR_REQ : coverpoint h2c_sub_trans.cmd_pl.mrkr_req;
  CP_CMD_NO_DMA   : coverpoint h2c_sub_trans.cmd_pl.no_dma;
  CP_CMD_SDI      : coverpoint h2c_sub_trans.cmd_pl.sdi;

  CP_CMD_ADDR_OFFSET : coverpoint (h2c_sub_trans.cmd_pl.addr % cfg.DATA_SIZE) {
    bins aligned   = {0};
    bins unaligned = {[1:$]};
  }

  // ---------------------------- CROSS
  CCP_SOP_X_EOP          : cross CP_CMD_SOP, CP_CMD_EOP;
  CCP_QID_X_DATA_LEN     : cross CP_CMD_QID, CP_CMD_LEN;
  CCP_ADDR_ALIGN_X_LEN   : cross CP_CMD_ADDR_OFFSET, CP_CMD_LEN;