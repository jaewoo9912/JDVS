`ifndef  __VDMATB_PERF_TEST_LIB_SVH__
`define  __VDMATB_PERF_TEST_LIB_SVH__

/*



  TODO:JW -- Short name
    You don't need to write down the full detail of the test, just show the test description in each test log
    or simply give them test index (ex] vdmatb_perf_test0)


*/


class vdmatb_perf_128byte_aligned_hostside_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_128byte_aligned_hostside_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_128byte_aligned_hostside_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = YES;
    made.perf_c2h_len_in_byte        = 128;
    made.perf_h2c_len_in_byte        = 128;
    made.BL                          = 2;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 0;
    made.perf_intr_latency           = 0;
    made.perf_stat_latency           = 0;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_128byte_aligned_hostside_ideal_intr_stat_ideal_test



class vdmatb_perf_128byte_aligned_hostside_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_128byte_aligned_hostside_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_128byte_aligned_hostside_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = YES;
    made.perf_c2h_len_in_byte        = 128;
    made.perf_h2c_len_in_byte        = 128;
    made.BL                          = 2;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 0;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_128byte_aligned_hostside_ideal_intr_stat_non_ideal_test



class vdmatb_perf_128byte_aligned_hostside_non_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_128byte_aligned_hostside_non_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_128byte_aligned_hostside_non_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = YES;
    made.perf_c2h_len_in_byte        = 128;
    made.perf_h2c_len_in_byte        = 128;
    made.BL                          = 2;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 0;
    made.perf_stat_latency           = 0;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_128byte_aligned_hostside_non_ideal_intr_stat_ideal_test




class vdmatb_perf_128byte_aligned_hostside_non_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_128byte_aligned_hostside_non_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_128byte_aligned_hostside_non_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = YES;
    made.perf_c2h_len_in_byte        = 128;
    made.perf_h2c_len_in_byte        = 128;
    made.BL                          = 2;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_128byte_aligned_hostside_non_ideal_intr_stat_non_ideal_test






class vdmatb_perf_128byte_unaligned_rand_addr_hostside_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_128byte_unaligned_rand_addr_hostside_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_128byte_unaligned_rand_addr_hostside_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing                = YES;
    made.perf_host_addr_aligned       = NO;
    made.perf_c2h_len_in_byte         = 128;
    made.perf_h2c_len_in_byte         = 128;
    made.BL                           = 2;
    made.perf_desc_fire_latency       = 0;
    made.perf_card_side_data_latency  = 0;
    made.perf_host_side_latency       = 0;
    made.perf_intr_latency            = 0;
    made.perf_stat_latency            = 0;
    made.perf_req_intr                = 1;
    made.perf_req_stat                = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_128byte_unaligned_rand_addr_hostside_ideal_intr_stat_ideal_test





class vdmatb_perf_128byte_unaligned_rand_addr_hostside_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_128byte_unaligned_rand_addr_hostside_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_128byte_unaligned_rand_addr_hostside_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 128;
    made.perf_h2c_len_in_byte        = 128;
    made.BL                          = 2;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 0;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_128byte_unaligned_rand_addr_hostside_ideal_intr_stat_non_ideal_test




class vdmatb_perf_128byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_128byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_128byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 128;
    made.perf_h2c_len_in_byte        = 128;
    made.BL                          = 2;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 0;
    made.perf_stat_latency           = 0;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_128byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_ideal_test





class vdmatb_perf_128byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_128byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_128byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 128;
    made.perf_h2c_len_in_byte        = 128;
    made.BL                          = 2;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_128byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test




class vdmatb_perf_64byte_aligned_hostside_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_64byte_aligned_hostside_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_64byte_aligned_hostside_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing                = YES;
    made.perf_host_addr_aligned       = YES;
    made.perf_c2h_len_in_byte         = 64;
    made.perf_h2c_len_in_byte         = 64;
    made.BL                           = 1;
    made.perf_desc_fire_latency       = 0;
    made.perf_card_side_data_latency  = 0;
    made.perf_host_side_latency       = 0;
    made.perf_intr_latency            = 0;
    made.perf_stat_latency            = 0;
    made.perf_req_intr                = 1;
    made.perf_req_stat                = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_64byte_aligned_hostside_ideal_intr_stat_ideal_test




class vdmatb_perf_64byte_aligned_hostside_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_64byte_aligned_hostside_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_64byte_aligned_hostside_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = YES;
    made.perf_c2h_len_in_byte        = 64;
    made.perf_h2c_len_in_byte        = 64;
    made.BL                          = 1;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 0;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_64byte_aligned_hostside_ideal_intr_stat_non_ideal_test





class vdmatb_perf_64byte_aligned_hostside_non_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_64byte_aligned_hostside_non_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_64byte_aligned_hostside_non_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = YES;
    made.perf_c2h_len_in_byte        = 64;
    made.perf_h2c_len_in_byte        = 64;
    made.BL                          = 1;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 0;
    made.perf_stat_latency           = 0;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_64byte_aligned_hostside_non_ideal_intr_stat_ideal_test





class vdmatb_perf_64byte_aligned_hostside_non_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_64byte_aligned_hostside_non_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_64byte_aligned_hostside_non_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES; 
    made.perf_host_addr_aligned      = YES;
    made.perf_c2h_len_in_byte        = 64;
    made.perf_h2c_len_in_byte        = 64;
    made.BL                          = 1;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_64byte_aligned_hostside_non_ideal_intr_stat_non_ideal_test




class vdmatb_perf_64byte_unaligned_non_crossing_hostside_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_64byte_unaligned_non_crossing_hostside_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_64byte_unaligned_non_crossing_hostside_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = NO;
    made.perf_host_addr_aligned      = NO;  
    made.perf_c2h_len_in_byte        = 32;  
    made.perf_h2c_len_in_byte        = 32;  
    made.BL                          = 1;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 0;
    made.perf_intr_latency           = 0;
    made.perf_stat_latency           = 0;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_64byte_unaligned_non_crossing_hostside_ideal_intr_stat_ideal_test



class vdmatb_perf_64byte_unaligned_non_crossing_hostside_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_64byte_unaligned_non_crossing_hostside_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_64byte_unaligned_non_crossing_hostside_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = NO;
    made.perf_host_addr_aligned      = NO;  
    made.perf_c2h_len_in_byte        = 32;  
    made.perf_h2c_len_in_byte        = 32;  
    made.BL                          = 1;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 0;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_64byte_unaligned_non_crossing_hostside_ideal_intr_stat_non_ideal_test



class vdmatb_perf_64byte_unaligned_non_crossing_hostside_non_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_64byte_unaligned_non_crossing_hostside_non_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_64byte_unaligned_non_crossing_hostside_non_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = NO;
    made.perf_host_addr_aligned      = NO;  
    made.perf_c2h_len_in_byte        = 32;  
    made.perf_h2c_len_in_byte        = 32;  
    made.BL                          = 1;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 0;
    made.perf_stat_latency           = 0;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_64byte_unaligned_non_crossing_hostside_non_ideal_intr_stat_ideal_test



class vdmatb_perf_64byte_unaligned_non_crossing_hostside_non_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_64byte_unaligned_non_crossing_hostside_non_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_64byte_unaligned_non_crossing_hostside_non_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = NO;
    made.perf_host_addr_aligned      = NO;  
    made.perf_c2h_len_in_byte        = 32;  
    made.perf_h2c_len_in_byte        = 32;  
    made.BL                          = 1;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_64byte_unaligned_non_crossing_hostside_non_ideal_intr_stat_non_ideal_test



class vdmatb_perf_64byte_unaligned_rand_addr_hostside_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_64byte_unaligned_rand_addr_hostside_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_64byte_unaligned_rand_addr_hostside_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 64;
    made.perf_h2c_len_in_byte        = 64;
    made.BL                          = 1;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 0;
    made.perf_intr_latency           = 0;
    made.perf_stat_latency           = 0;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_64byte_unaligned_rand_addr_hostside_ideal_intr_stat_ideal_test




class vdmatb_perf_64byte_unaligned_rand_addr_hostside_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_64byte_unaligned_rand_addr_hostside_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_64byte_unaligned_rand_addr_hostside_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 64;
    made.perf_h2c_len_in_byte        = 64;
    made.BL                          = 1;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 0;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_64byte_unaligned_rand_addr_hostside_ideal_intr_stat_non_ideal_test




class vdmatb_perf_64byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_64byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_64byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing                = YES;
    made.perf_host_addr_aligned       = NO;
    made.perf_c2h_len_in_byte         = 64;
    made.perf_h2c_len_in_byte         = 64;
    made.BL                           = 1;
    made.perf_desc_fire_latency       = 0;
    made.perf_card_side_data_latency  = 0;
    made.perf_host_side_latency       = 400;
    made.perf_intr_latency            = 0;
    made.perf_stat_latency            = 0;
    made.perf_req_intr                = 1;
    made.perf_req_stat                = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_64byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_ideal_test




class vdmatb_perf_64byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_64byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_64byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 64;
    made.perf_h2c_len_in_byte        = 64;
    made.BL                          = 1;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_64byte_unaligned_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test




class vdmatb_perf_large_rand_addr_hostside_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_large_rand_addr_hostside_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_large_rand_addr_hostside_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 32768;
    made.perf_h2c_len_in_byte        = 32768;
    made.BL                          = 64;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 0;
    made.perf_intr_latency           = 0;
    made.perf_stat_latency           = 0;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_large_rand_addr_hostside_ideal_intr_stat_ideal_test




class vdmatb_perf_large_rand_addr_hostside_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_large_rand_addr_hostside_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_large_rand_addr_hostside_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 32768;
    made.perf_h2c_len_in_byte        = 32768;
    made.BL                          = 64;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 0;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_large_rand_addr_hostside_ideal_intr_stat_non_ideal_test




class vdmatb_perf_large_rand_addr_hostside_non_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_large_rand_addr_hostside_non_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_large_rand_addr_hostside_non_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 32768;
    made.perf_h2c_len_in_byte        = 32768;
    made.BL                          = 64;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 0;
    made.perf_stat_latency           = 0;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_large_rand_addr_hostside_non_ideal_intr_stat_ideal_test




class vdmatb_perf_large_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_large_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_large_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 32768;
    made.perf_h2c_len_in_byte        = 32768;
    made.BL                          = 64;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_large_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test




class vdmatb_perf_medium_rand_addr_hostside_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_medium_rand_addr_hostside_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_medium_rand_addr_hostside_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 1500;
    made.perf_h2c_len_in_byte        = 1500;
    made.BL                          = 23;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 0;
    made.perf_intr_latency           = 0;
    made.perf_stat_latency           = 0;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_medium_rand_addr_hostside_ideal_intr_stat_ideal_test




class vdmatb_perf_medium_rand_addr_hostside_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_medium_rand_addr_hostside_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_medium_rand_addr_hostside_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 1500;
    made.perf_h2c_len_in_byte        = 1500;
    made.BL                          = 23;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 0;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_medium_rand_addr_hostside_ideal_intr_stat_non_ideal_test




class vdmatb_perf_medium_rand_addr_hostside_non_ideal_intr_stat_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_medium_rand_addr_hostside_non_ideal_intr_stat_ideal_test)
  function new(string name="vdmatb_perf_medium_rand_addr_hostside_non_ideal_intr_stat_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 1500;
    made.perf_h2c_len_in_byte        = 1500;
    made.BL                          = 23;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 0;
    made.perf_stat_latency           = 0;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_medium_rand_addr_hostside_non_ideal_intr_stat_ideal_test




class vdmatb_perf_medium_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test extends vdmatb_perf_test;
  
  `uvm_component_utils(vdmatb_perf_medium_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test)
  function new(string name="vdmatb_perf_medium_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test", uvm_component parent=null);
      super.new(name, parent);
  endfunction

  virtual protected function PerfTestCtrlKnob_t makeInitialPerfCtrlKnob();
    PerfTestCtrlKnob_t made;

    made.perf_crossing               = YES;
    made.perf_host_addr_aligned      = NO;
    made.perf_c2h_len_in_byte        = 1500;
    made.perf_h2c_len_in_byte        = 1500;
    made.BL                          = 23;
    made.perf_desc_fire_latency      = 0;
    made.perf_card_side_data_latency = 0;
    made.perf_host_side_latency      = 400;
    made.perf_intr_latency           = 625;
    made.perf_stat_latency           = 300;
    made.perf_req_intr               = 1;
    made.perf_req_stat               = 1;
    return(made);
  endfunction:makeInitialPerfCtrlKnob
  
endclass:vdmatb_perf_medium_rand_addr_hostside_non_ideal_intr_stat_non_ideal_test







`endif //__VDMATB_PERF_TEST_LIB_SVH__
