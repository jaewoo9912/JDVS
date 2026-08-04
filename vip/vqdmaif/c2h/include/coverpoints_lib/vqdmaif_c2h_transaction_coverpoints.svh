  // ---------------------------- CMD
  CP_CMD_QID      : coverpoint c2h_trans.qid;
  CP_CMD_PORT_ID  : coverpoint c2h_trans.cmd_pl.port_id;
  CP_CMD_PFCH_TAG : coverpoint c2h_trans.cmd_pl.pfch_tag;
  CP_CMD_ERROR    : coverpoint c2h_trans.cmd_pl.error;

  CP_CMD_FUNC : coverpoint c2h_trans.cmd_pl.func {
    `vtrans_coverbin_divide_by_16(QdmaFunc_t'(-1))
  }

  CP_CMD_ADDR : coverpoint c2h_trans.cmd_pl.addr {
    `vtrans_coverbin_divide_by_64(max_addr)
  }

  // ---------------------------- DATA
  CP_DATA_LEN : coverpoint c2h_trans.q_data_pl[0].len {
    `vtrans_coverbin_divide_by_16(QdmaLen_t'(-1))
  }

  // ---------------------------- STATUS
  CP_STATUS_QID   : coverpoint c2h_trans.status_pl.qid;
  CP_STATUS_LAST  : coverpoint c2h_trans.status_pl.last;
  CP_STATUS_CMP   : coverpoint c2h_trans.status_pl.cmp;
  CP_STATUS_DROP  : coverpoint c2h_trans.status_pl.drop;
  CP_STATUS_ERROR : coverpoint c2h_trans.status_pl.error;

  CP_CMD_ADDR_OFFSET : coverpoint (c2h_trans.cmd_pl.addr % cfg.DATA_SIZE) {
    bins aligned   = {0};
    bins unaligned = {[1:$]};
  }

  // ---------------------------- CROSS
  CCP_QID_X_DATA_LEN     : cross CP_CMD_QID, CP_DATA_LEN;
  CCP_ADDR_ALIGN_X_LEN   : cross CP_CMD_ADDR_OFFSET, CP_DATA_LEN;