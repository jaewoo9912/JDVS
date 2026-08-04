`ifndef __VQDMAIF_C2H_DEFAULT_CHECKER_SVH__
`define __VQDMAIF_C2H_DEFAULT_CHECKER_SVH__

class vqdmaif_c2h_default_checker extends vmg_checker implements vqdmaif_c2h_if_checker;

  `uvm_object_utils(vqdmaif_c2h_default_checker)
  function new(string name="vqdmaif_c2h_default_checker");
    super.new(name);
  endfunction

  virtual function void chkCmd(QdmaC2HCmd_t cmd, QdmaC2HCmdSideBand_t cmd_sideband); endfunction
  virtual function void chkData(QdmaC2HData_t data, QdmaC2HDataSideBand_t data_sideband); endfunction
  virtual function void chkStatus(QdmaC2HStatus_t status, QdmaC2HStatusSideBand_t status_sideband); endfunction

  virtual task initialize(string call_info=""); endtask
  virtual function string makeShortReport(); endfunction
  virtual function StringQ_t makeReport(); endfunction

endclass

`endif //__VQDMAIF_C2H_DEFAULT_CHECKER_SVH__
