`ifndef __VQDMAIF_C2H_CFGDB_KEY_SVH__
`define __VQDMAIF_C2H_CFGDB_KEY_SVH__

class vqdmaif_c2h_cfgdb_key extends vbfm_cfgdb_key;
  `uvm_object_utils(vqdmaif_c2h_cfgdb_key)
  function new(string name="vqdmaif_c2h_cfgdb_key");
    super.new(name);
  endfunction
  extern function string getCfgDbField_Vif();
endclass:vqdmaif_c2h_cfgdb_key

function string vqdmaif_c2h_cfgdb_key::getCfgDbField_Vif(); return(GetCfgDbField_C2hVif(this.getKey)); endfunction

`endif // __VQDMAIF_C2H_CFGDB_KEY_SVH__
