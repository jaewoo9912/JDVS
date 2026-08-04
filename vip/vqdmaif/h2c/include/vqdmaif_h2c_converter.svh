`ifndef __VQDMAIF_H2C_CONVERTER_SVH__
`define __VQDMAIF_H2C_CONVERTER_SVH__

class vqdmaif_h2c_converter extends vmg_object;
  `uvm_object_utils(vqdmaif_h2c_converter)
  function new(string name="vqdmaif_h2c_converter");
    super.new(name);
  endfunction

  extern virtual function bit convertToGatheredDcntr(input vqdmaif_h2c_transaction trans, ref vdata_container container);
  extern virtual function bit convertH2cNotGatherToDcntr(vqdmaif_h2c_transaction trans, UInt_t idx = 0, vdata_container gathered_dcntr, ref vdata_container container);
endclass


function bit vqdmaif_h2c_converter::convertToGatheredDcntr(input vqdmaif_h2c_transaction trans, ref vdata_container container);
  int byte_idx, len;
  if(container == null) container = vdata_container::type_id::create($sformatf("%s.container", trans.get_name()));
  container.set_command(UVM_TLM_READ_COMMAND);
  container.set_address(trans.getAddr());
  len = trans.getTotalLen();
  container.setDataSize(len, YES);
  for(int i=0; i< trans.getNumData(); i++)begin
    QdmaData_t data;
    trans.getDataValue(i, data);
    for(int j = 0 ; j < trans.cfg.DATA_SIZE ; j++)begin
      container.m_data[byte_idx++] = data[8*j+:8];
      if(byte_idx == len) return(1);
    end
  end
  return(0);
endfunction:convertToGatheredDcntr

function bit vqdmaif_h2c_converter::convertH2cNotGatherToDcntr(vqdmaif_h2c_transaction trans, UInt_t idx=0, vdata_container gathered_dcntr, ref vdata_container container);
  int byte_idx, len;
  int num_last=0;
  int total_num_cmd=trans.q_sub.size();
  bit result;
  int j=0;

  if(idx >= total_num_cmd) return NO;

  if(gathered_dcntr != null) result = 1;
  else return 0;
  if(trans.q_sub.size() < 2) begin
    container = gathered_dcntr;
    return result;
  end

  container = vdata_container::type_id::create($sformatf("%s.container_%0d/%0d", trans.get_name(), idx, total_num_cmd));
  container.set_command(UVM_TLM_READ_COMMAND);
  container.set_address(trans.q_sub[idx].getAddr());
  len = trans.q_sub[idx].getLen();
  container.setDataSize(len, YES);

  for(int i=0; i<idx;i++) begin
    byte_idx += trans.q_sub[i].getLen();
  end

  for(int i=byte_idx; i<byte_idx+len; i++) begin
    container.m_data[j] = gathered_dcntr.m_data[i];
    j++;
  end

  return(1);
endfunction : convertH2cNotGatherToDcntr

`endif //__VQDMAIF_H2C_CONVERTER_SVH__