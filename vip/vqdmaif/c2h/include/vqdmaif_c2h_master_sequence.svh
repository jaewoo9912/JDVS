`ifndef __VQDMAIF_C2H_MASTER_SEQUENCE_SVH__
`define __VQDMAIF_C2H_MASTER_SEQUENCE_SVH__

class vqdmaif_c2h_master_sequence extends vbfm_sequence#(.REQ(vqdmaif_c2h_master_sequence_item));

  vqdmaif_c2h_master_cfg cfg;
  vqdmaif_c2h_master_sequencer sqr;

  local int num_created_item;

  `uvm_object_utils(vqdmaif_c2h_master_sequence)
  function new(string name="vqdmaif_c2h_master_sequence");
    super.new(name);
  endfunction

  extern virtual function void set_sequencer(uvm_sequencer_base sequencer);

  extern virtual function vqdmaif_c2h_master_sequence_item createItem(vqdmaif_c2h_master_transaction_scenario_control_knob sck, bit randomize_sck=1);
endclass


function void vqdmaif_c2h_master_sequence::set_sequencer(uvm_sequencer_base sequencer);
  super.set_sequencer(sequencer);
  $cast(this.sqr, sequencer);
  this.cfg = this.sqr.cfg;
  // [HISTORY] sungmin.hong
  //  - [2025/05/28] I wasn't able to solve the problem, because get_response does not work in a blocked manner
  this.set_response_queue_error_report_disabled(1);
endfunction


function vqdmaif_c2h_master_sequence_item vqdmaif_c2h_master_sequence::createItem(vqdmaif_c2h_master_transaction_scenario_control_knob sck, bit randomize_sck=1);
  vqdmaif_c2h_master_sequence_item created;
  string inst_name = $sformatf("%s.item#%1d", this.get_name, this.num_created_item++);

  if(randomize_sck)begin
    if(!sck.randomize()) begin
      sck.show("[randomize-failed]");
      `vmg_fatal_randomize(this.get_name, "createItem");
    end
  end
  `uvm_create(created)
  `vmg_info(this.get_name, $sformatf("createItem -- sck.data_pl_list.size=%1d", sck.data_pl_list.size), UVM_DEBUG)
  foreach(sck.data_pl_list[i])begin
    QdmaC2HData_t data_pl = sck.data_pl_list[i];
    `vmg_info(this.get_name, $sformatf("createItem -- data_pl_list[%1d]", i), UVM_DEBUG)
    if(i == 0)begin
      created.trans = VQDMAIF_C2H_FACTORY.createTrans_ByDataPl($sformatf("%s.trans", inst_name), this.cfg, data_pl);
    end
    else begin
      created.trans.storeData(data_pl);
    end
  end
  if(created.trans == null) `vmg_fatal_wrong_impl("C2H_MST_CREATE_ITEM_FAILED", $sformatf("created.trans==null")) 

  created.trans.storeCmdSideband(sck.cmd_sideband_pl);
  foreach(sck.data_sideband_pl_list[i]) created.trans.storeDataSideband(sck.data_sideband_pl_list[i]);

  created.trans.storeCmd(sck.cmd_pl);
  created.cmd2cmd_delay = sck.cmd2cmd_delay;
  created.data2data_delay_list = sck.data2data_delay_list;
  created.cmd2data_delay = sck.cmd2data_delay;
  created.status_pending_cycle = sck.status_pending_cycle;
  return(created);
endfunction



`endif // __VQDMAIF_C2H_MASTER_SEQUENCE_SVH__
