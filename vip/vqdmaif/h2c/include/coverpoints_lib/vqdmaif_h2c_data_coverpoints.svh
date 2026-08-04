  CP_DATA_VALUE : coverpoint h2c_trans_data.data {
    `vtrans_coverbin_divide_by_16(QdmaData_t'(-1))
  }

  CP_DATA_CRC : coverpoint h2c_trans_data.crc {
    `vtrans_coverbin_divide_by_16(QdmaCrc_t'(-1))
  }

  CP_DATA_MDATA : coverpoint h2c_trans_data.mdata {
    `vtrans_coverbin_divide_by_16(QdmaMData_t'(-1))
  }

  CP_DATA_QID       : coverpoint h2c_trans_data.qid;
  CP_DATA_PORT_ID   : coverpoint h2c_trans_data.port_id;
  CP_DATA_MTY       : coverpoint h2c_trans_data.mty;
  CP_DATA_LAST      : coverpoint h2c_trans_data.last;
  CP_DATA_ERR       : coverpoint h2c_trans_data.err;
  CP_DATA_ZERO_BYTE : coverpoint h2c_trans_data.zero_byte;