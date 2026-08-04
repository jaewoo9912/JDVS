`ifndef __VQDMAIF_C2H_CONVERTER_SVH__
`define __VQDMAIF_C2H_CONVERTER_SVH__

class vqdmaif_c2h_converter extends vmg_object;
  `uvm_object_utils(vqdmaif_c2h_converter)
  function new(string name="vqdmaif_c2h_converter");
    super.new(name);
  endfunction
  
  extern virtual function bit convertC2hToDcntr(input vqdmaif_c2h_transaction c2h, output vdata_container container);
endclass

function bit vqdmaif_c2h_converter::convertC2hToDcntr(input vqdmaif_c2h_transaction c2h, output vdata_container container);
  int byte_idx, len;
  container = vdata_container::type_id::create($sformatf("%s.container", c2h.get_name()));
  container.set_command(UVM_TLM_WRITE_COMMAND);
  container.set_address(c2h.getAddr());
  len = c2h.getLen();
  container.setDataSize(len, YES);
  foreach(c2h.q_data_pl[i])begin
    for(int j = 0 ; j < c2h.cfg.DATA_SIZE ; j++)begin
      container.m_data[byte_idx++] = c2h.q_data_pl[i].data[8*j+:8];
      if(byte_idx == len) return(1);
    end
  end
  return(0);
endfunction:convertC2hToDcntr
`endif //__VQDMAIF_C2H_CONVERTER_SVH__