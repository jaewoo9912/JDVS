`ifndef __VQDMAIF_C2H_SLAVE_CFG_SVH__
`define __VQDMAIF_C2H_SLAVE_CFG_SVH__

class vqdmaif_c2h_slave_cfg extends vqdmaif_c2h_cfg;

  ArbType_t arb_type=FIFS; // FIFS/ROUND_ROBIN/RANDOM available
  QdmaifSlvDriverMode_t driver_operation_mode = NORMAL_MODE;
  real target_bandwidth = 100;

  vqdmaif_c2h_slave_bfm_timing_policy default_bfm_timing_policy;

  int prob_status_drop=0;
  int prob_status_error=0;
  int prob_status_cmp=100;

  uvm_verbosity arb_result_verbosity=UVM_HIGH;

  // TODO:NeedRemove -- after migration
  int unsigned start_cmd_pending_cycle             = 0, end_cmd_pending_cycle             = 10; 
  int unsigned start_data_pending_cycle            = 0, end_data_pending_cycle            = 5;
  int unsigned start_fetch_latency                 = 5, end_fetch_latency                 = 20;
  int unsigned start_status_latency                = 5, end_status_latency                = 20;
  int unsigned start_interruptsideband_latency     = 5, end_interruptsideband_latency     = 20;

  `uvm_object_utils_begin(vqdmaif_c2h_slave_cfg)
    `uvm_field_int(max_ot, UVM_DEFAULT)
    `uvm_field_int(prob_status_drop, UVM_DEFAULT)
    `uvm_field_int(prob_status_error, UVM_DEFAULT)
    `uvm_field_int(prob_status_cmp, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name="vqdmaif_c2h_slave_cfg");
    super.new(name);
  endfunction

  virtual function void finalize();
    super.finalize();
    //TODO:NeedRemove -- after migration
    if(this.default_bfm_timing_policy==null)begin
      this.default_bfm_timing_policy = vqdmaif_c2h_slave_bfm_timing_policy::type_id::create($sformatf("%s.default_bfm_timing_policy", this.get_name));
      this.default_bfm_timing_policy.start_cmd_pending_cycle          = this.start_cmd_pending_cycle;
      this.default_bfm_timing_policy.start_data_pending_cycle         = this.start_data_pending_cycle;
      this.default_bfm_timing_policy.start_fetch_latency              = this.start_fetch_latency;
      this.default_bfm_timing_policy.start_status_latency             = this.start_status_latency;
      this.default_bfm_timing_policy.start_interrupt_sideband_latency = this.start_interruptsideband_latency ;
      this.default_bfm_timing_policy.end_cmd_pending_cycle            = this.end_cmd_pending_cycle;
      this.default_bfm_timing_policy.end_data_pending_cycle           = this.end_data_pending_cycle;
      this.default_bfm_timing_policy.end_fetch_latency                = this.end_fetch_latency;
      this.default_bfm_timing_policy.end_status_latency               = this.end_status_latency;
      this.default_bfm_timing_policy.end_interrupt_sideband_latency   = this.end_interruptsideband_latency ;
    end
  endfunction



endclass

`endif // __VQDMAIF_C2H_SLAVE_CFG_SVH__
