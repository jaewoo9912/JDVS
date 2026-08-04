`ifndef __VQDMAIF_C2H_MASTER_HMEM_SEQUENCE_SVH__
`define __VQDMAIF_C2H_MASTER_HMEM_SEQUENCE_SVH__


class vqdmaif_c2h_master_hmem_sequence extends vqdmaif_c2h_master_random_sequence;

  `uvm_object_utils(vqdmaif_c2h_master_hmem_sequence)
  function new(string name = "vqdmaif_c2h_master_hmem_sequence");
    super.new(name);
  endfunction

  
  extern virtual task body();
  extern local function void setupMstSck(vqdmaif_c2h_master_transaction_scenario_control_knob sck);
endclass


task vqdmaif_c2h_master_hmem_sequence::body();
  for(int i = 0; i < this.num_trans; i++) begin
    vqdmaif_c2h_master_sequence_item created;

    this.setupMstSck(this.sck);
    created = this.createItem(this.sck);
    `uvm_send(created);
  end
endtask : body


function void vqdmaif_c2h_master_hmem_sequence::setupMstSck(vqdmaif_c2h_master_transaction_scenario_control_knob sck);
  sck.alignment = SIZE_4B;
  sck.start_len = 1;
  sck.end_len   = 4096;
endfunction : setupMstSck

`endif // __VQDMAIF_C2H_MASTER_HMEM_SEQUENCE_SVH__
