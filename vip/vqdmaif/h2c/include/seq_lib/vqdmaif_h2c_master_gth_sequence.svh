`ifndef __VQDMAIF_H2C_MASTER_GTH_SEQUENCE_SVH__
`define __VQDMAIF_H2C_MASTER_GTH_SEQUENCE_SVH__


class vqdmaif_h2c_master_gth_sequence extends vqdmaif_h2c_master_random_sequence;

  `uvm_object_utils(vqdmaif_h2c_master_gth_sequence)
  function new(string name = "vqdmaif_h2c_master_gth_sequence");
    super.new(name);
  endfunction

  extern virtual task body();
  extern local function void setupMstSck(vqdmaif_h2c_master_transaction_scenario_control_knob sck);
endclass 


task vqdmaif_h2c_master_gth_sequence::body();
  repeat(num_trans) begin
    automatic vqdmaif_h2c_master_sequence_item req, rsp;
    this.setupMstSck(this.sck);
    req = this.createItem(this.sck);
    rsp = new();
    fork begin
      `uvm_send(req);
      rsp.set_id_info(req);
      this.get_response(rsp);
    end join_none
  end
  wait fork;
endtask:body

function void vqdmaif_h2c_master_gth_sequence::setupMstSck(vqdmaif_h2c_master_transaction_scenario_control_knob sck);
  sck.alignment = SIZE_4B;
  sck.start_len = 1;
  sck.end_len   = 4096;
  sck.prob_gather_pkt = 100;
endfunction : setupMstSck

`endif //  __VQDMAIF_H2C_MASTER_GTH_SEQUENCE_SVH__
