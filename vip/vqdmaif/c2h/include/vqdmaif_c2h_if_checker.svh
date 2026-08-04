`ifndef __VQDMAIF_C2H_IF_CHECKER_SVH__
`define __VQDMAIF_C2H_IF_CHECKER_SVH__


interface class vqdmaif_c2h_if_checker extends vmg_if_checker;

  pure virtual function void chkCmd(QdmaC2HCmd_t cmd, QdmaC2HCmdSideBand_t cmd_sideband);
  pure virtual function void chkData(QdmaC2HData_t data, QdmaC2HDataSideBand_t data_sideband);
  pure virtual function void chkStatus(QdmaC2HStatus_t status, QdmaC2HStatusSideBand_t status_sideband);

endclass

`endif //__VQDMAIF_C2H_IF_CHECKER_SVH__
