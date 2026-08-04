`ifndef __VQDMAIF_C2H_MASTER_RANDOM_SEQUENCE_SVH__
`define __VQDMAIF_C2H_MASTER_RANDOM_SEQUENCE_SVH__


class vqdmaif_c2h_master_random_sequence extends vqdmaif_c2h_master_sequence;
  rand int num_trans = 10;
  int min_num_trans = 10, max_num_trans = 10;
  constraint c_num_trans { num_trans inside {[min_num_trans:max_num_trans]}; };
  vqdmaif_c2h_master_transaction_scenario_control_knob sck;
  vrand_address_range_generator addr_gen;

  `uvm_object_utils(vqdmaif_c2h_master_random_sequence)
  function new(string name = "vqdmaif_c2h_master_random_sequence");
    super.new(name);
  endfunction
  extern virtual task pre_body();
  extern virtual task body();
endclass : vqdmaif_c2h_master_random_sequence


task vqdmaif_c2h_master_random_sequence::pre_body();
  super.pre_body();
  if(this.sck == null) `vmg_fatal_wrong_usage(this.get_full_name, $sformatf("pre_body -- sck == null"));
  if(this.addr_gen != null) this.sck.enterForcingMode();
endtask


task vqdmaif_c2h_master_random_sequence::body();
  repeat(num_trans) begin
    automatic vqdmaif_c2h_master_sequence_item req, rsp;
    if(this.addr_gen != null)begin
      vrand_address_range addr_range = this.addr_gen.genRange();
      this.sck.forceRandomKnob_UsingAddrRange(addr_range);
    end
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



`endif // __VQDMAIF_C2H_MASTER_RANDOM_SEQUENCE_SVH__
