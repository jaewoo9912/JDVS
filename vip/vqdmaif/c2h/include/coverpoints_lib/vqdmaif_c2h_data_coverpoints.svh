  CP_DATA_VALUE : coverpoint c2h_trans_data.data {
    `vtrans_coverbin_divide_by_16(QdmaData_t'(-1))
  }

  CP_DATA_CRC : coverpoint c2h_trans_data.crc {
    `vtrans_coverbin_divide_by_16(QdmaCrc_t'(-1))
  }

  CP_DATA_QID      : coverpoint c2h_trans_data.qid;
  CP_DATA_PORT_ID  : coverpoint c2h_trans_data.port_id;
  CP_DATA_MTY      : coverpoint c2h_trans_data.mty;
  CP_DATA_LAST     : coverpoint c2h_trans_data.last;
  CP_DATA_MARKER   : coverpoint c2h_trans_data.marker;
  CP_DATA_HAS_CMPT : coverpoint c2h_trans_data.has_cmpt;
  CP_DATA_ECC      : coverpoint c2h_trans_data.ecc;