`ifndef __VQDMAIF_H2C_IF_CHECKER_SVH__
`define __VQDMAIF_H2C_IF_CHECKER_SVH__


interface class vqdmaif_h2c_if_checker extends vmg_if_checker;

  pure virtual function void chkCmd(QdmaH2CCmd_t cmd, QdmaH2CCmdSideBand_t cmd_sideband);
  pure virtual function void chkData(QdmaH2CData_t data, QdmaH2CDataSideBand_t data_sideband);

endclass

`endif //__VQDMAIF_H2C_IF_CHECKER_SVH__
