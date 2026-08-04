`ifndef __VQDMAIF_H2C_DEFAULT_CHECKER_SVH__
`define __VQDMAIF_H2C_DEFAULT_CHECKER_SVH__

class vqdmaif_h2c_default_checker extends vmg_checker implements vqdmaif_h2c_if_checker;

  `uvm_object_utils(vqdmaif_h2c_default_checker)
  function new(string name="vqdmaif_h2c_default_checker");
    super.new(name);
  endfunction

  virtual function void chkCmd(QdmaH2CCmd_t cmd, QdmaH2CCmdSideBand_t cmd_sideband); endfunction
  virtual function void chkData(QdmaH2CData_t data, QdmaH2CDataSideBand_t data_sideband); endfunction


  virtual task initialize(string call_info=""); endtask
  virtual function string makeShortReport(); endfunction
  virtual function StringQ_t makeReport(); endfunction

endclass

`endif //__VQDMAIF_H2C_DEFAULT_CHECKER_SVH__
