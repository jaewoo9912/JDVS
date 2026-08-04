`ifndef __VQDMAIF_H2C_MASTER_SEQUENCE_SVH__
`define __VQDMAIF_H2C_MASTER_SEQUENCE_SVH__

class vqdmaif_h2c_master_sequence extends vbfm_sequence#(.REQ(vqdmaif_h2c_master_sequence_item));

  vqdmaif_h2c_master_cfg cfg;
  vqdmaif_h2c_master_sequencer sqr;

  local int num_created_item;

  `uvm_object_utils(vqdmaif_h2c_master_sequence)
  function new(string name="vqdmaif_h2c_master_sequence");
    super.new(name);
  endfunction

  extern virtual function void set_sequencer(uvm_sequencer_base sequencer);

  extern virtual function vqdmaif_h2c_master_sequence_item createItem(vqdmaif_h2c_master_transaction_scenario_control_knob sck, bit randomize_sck=1);

endclass


function void vqdmaif_h2c_master_sequence::set_sequencer(uvm_sequencer_base sequencer);
  super.set_sequencer(sequencer);
  $cast(this.sqr, sequencer);
  this.cfg = this.sqr.cfg;
  // [HISTORY] sungmin.hong
  //  - [2025/05/28] I wasn't able to solve the problem, because get_response does not work in a blocked manner
  this.set_response_queue_error_report_disabled(1);
endfunction


function vqdmaif_h2c_master_sequence_item vqdmaif_h2c_master_sequence::createItem(vqdmaif_h2c_master_transaction_scenario_control_knob sck, bit randomize_sck=1);
  vqdmaif_h2c_master_sequence_item created;
  string inst_name = $sformatf("%s.item#%1d", this.get_name, this.num_created_item++);
  vqdmaif_h2c_sub_transaction q_sub_trans[$];

  if(randomize_sck)begin
    if(!sck.randomize()) begin
      sck.show("[randomize-failed]");
      `vmg_fatal_randomize(this.get_name, "createItem");
    end
  end
  `uvm_create(created)
  foreach(sck.cmd_pl_list[i])begin
    string sub_trans_name = $sformatf("%s.sub_trans#%1d", inst_name, i);
    vqdmaif_h2c_sub_transaction sub_trans;
    QdmaH2CCmd_t cmd = sck.cmd_pl_list[i];
    QdmaH2CCmdSideBand_t cmd_sideband = sck.cmd_sideband_pl_list[i];
    sub_trans = VQDMAIF_H2C_FACTORY.createSubTrans(sub_trans_name, this.cfg, cmd);
    sub_trans.storeCmdSideband(cmd_sideband);
    q_sub_trans.push_back(sub_trans);
  end
  created.trans = VQDMAIF_H2C_FACTORY.createTrans($sformatf("%s.trans", inst_name), q_sub_trans.pop_front);
  while(q_sub_trans.size > 0)begin
    created.trans.addSubTrans(q_sub_trans.pop_front);
  end
  created.cmd2cmd_delay_list = sck.cmd2cmd_delay_list;
  return(created);
endfunction:createItem


`endif // __VQDMAIF_H2C_MASTER_SEQUENCE_SVH__
