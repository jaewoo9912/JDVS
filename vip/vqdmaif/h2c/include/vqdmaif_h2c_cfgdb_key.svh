`ifndef __VQDMAIF_H2C_CFGDB_KEY_SVH__
`define __VQDMAIF_H2C_CFGDB_KEY_SVH__

class vqdmaif_h2c_cfgdb_key extends vbfm_cfgdb_key;
  `uvm_object_utils(vqdmaif_h2c_cfgdb_key)
  function new(string name="vqdmaif_h2c_cfgdb_key");
    super.new(name);
  endfunction
  extern function string getCfgDbField_Vif();
endclass:vqdmaif_h2c_cfgdb_key

function string vqdmaif_h2c_cfgdb_key::getCfgDbField_Vif(); return(GetCfgDbField_H2cVif(this.getKey)); endfunction

`endif // __VQDMAIF_H2C_CFGDB_KEY_SVH__
