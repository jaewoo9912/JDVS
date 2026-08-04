`ifndef __VDMATB_HOST_MON_SVH__
`define __VDMATB_HOST_MON_SVH__

class vdmatb_host_mon #(
  parameter  type T_SEQ_ITEM = vdmatb_host_seq_item,
  localparam type T_TRANS    = T_SEQ_ITEM
)extends vmg_mon;

  typedef T_TRANS Q_TRANS[$];


  protected vdmatb_tcfg tcfg;
  
  uvm_analysis_port#(T_TRANS) ap_aw;
  uvm_analysis_port#(T_TRANS) ap_ar;

  protected T_TRANS q_activeAW[$];
  protected T_TRANS q_activeW[$];
  protected T_TRANS q_activeAR[$];
  protected T_TRANS q_activeR[$];
  
//  T_TRANS q_4fault_bresp[$];
//  local int     q_host_fault_bresp[$];
//  local int     q_host_fault_rresp[$];
//  
//  YesOrNo_t gen_host_fault_no_last;
//  YesOrNo_t gen_premature_last_fault;
//  YesOrNo_t q_host_fault_premature_last[$];
//  YesOrNo_t host_fault_premature_last;
  
  int count_gen_prematureLast;
  int count_prematureLast = 0;
  
  protected int num_trans;
  protected logic [HOST_DATA_WIDTH-1:0]            qwdata [$];
  protected logic [HOST_DATA_WIDTH/8-1:0]          qwstrb [$];
  protected logic [HOST_DATA_WIDTH-1:0]            qrdata [$];

  protected logic qrlast[$];
  protected logic [`SVT_AXI_RESP_WIDTH-1:0]                 qrresp[$];

  event ev_need_inter_reset;
  logic                    w_start;
  logic                    r_start;

  virtual svt_axi_master_if vif;
  virtual vdmatb_vwrap_if vwrap_if;
  
  protected DmaTransType_t trans_type;
  protected string mon_name;

  local int num_interrupt, num_status, num_data, num_fault_intr;

  `uvm_component_utils (vdmatb_host_mon)
  function new(string name="vdmatb_host_mon", uvm_component parent=null);
    super.new(name, parent);
    this.setTitleHeader("vdmatb_host_mon");
  endfunction

  // ---------------------------- uvm built-in
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern         function void end_of_elaboration_phase(uvm_phase phase);
  extern protected function void init(string call_info="unknown");

  // ---------------------------- vmg_vip_monitor built-in
  extern virtual function void showHistory(string prompt);
  extern virtual function YesOrNo_t hasBwdChannel();  
  extern virtual function void init_core(string call_info="unknown");

  // ---------------------------- extended-specific
  extern local task collectAW();
  extern local task collectWData();
  extern local task collectB();
  extern local task collectAR();
  extern local task collectRData();


  extern virtual function YesOrNo_t resetHostMon();
  
  extern virtual function YesOrNo_t isBusy();

  extern virtual function void connectVif();
  
endclass:vdmatb_host_mon


function void vdmatb_host_mon::connectVif(); endfunction


function void vdmatb_host_mon::build_phase(uvm_phase phase);
  super.build_phase(phase);

  `vmg_get_cfgdb_at_me(virtual vdmatb_vwrap_if, "vwrap_if", this.vwrap_if)
  `vmg_get_cfgdb_at_me(vdmatb_tcfg, "tcfg", this.tcfg)
  this.vif = this.vwrap_if.axi_if.master_if[0];

  this.ap_aw = new("ap_aw", this);
  this.ap_ar = new("ap_ar", this);
  this.mon_name = $sformatf("HOST_MON");
endfunction:build_phase



function YesOrNo_t vdmatb_host_mon::hasBwdChannel(); return(YES); endfunction


function void vdmatb_host_mon::init_core(string call_info="unknown");
  this.q_activeAW.delete();
  this.q_activeAR.delete();
  this.q_activeW.delete();
  this.q_activeR.delete();
  
  this.qwdata.delete();
  this.qwstrb.delete();
  this.qrdata.delete();

  this.qrlast.delete();
  this.qrresp.delete();
endfunction:init_core


task vdmatb_host_mon::run_phase(uvm_phase phase);
  fork
    this.collectAW();
    this.collectWData();
    this.collectB();
    this.collectAR();
    this.collectRData();
  join
endtask:run_phase

function void vdmatb_host_mon::end_of_elaboration_phase(uvm_phase phase);
endfunction:end_of_elaboration_phase


function void vdmatb_host_mon::init(string call_info="unknown");
  this.info($sformatf("INITIALIZED !!  call_info=[%s]", call_info));
endfunction:init


function YesOrNo_t vdmatb_host_mon::resetHostMon();
  this.q_activeAW.delete();
  this.q_activeAR.delete();
  this.q_activeW.delete();
  this.q_activeR.delete();
  
  this.qwdata.delete();
  this.qwstrb.delete();
  this.qrdata.delete();

  this.qrlast.delete();
  this.qrresp.delete();

  return(YES);
endfunction:resetHostMon


function YesOrNo_t vdmatb_host_mon::isBusy();
  if( (this.q_activeAW.size() == 0) && (this.q_activeW.size() == 0) )
    return(NO);
  
  return(YES);
endfunction : isBusy


task vdmatb_host_mon::collectAW();
  T_TRANS created;

  forever begin
    if (vif.awvalid && vif.awready) begin
      created = T_TRANS::type_id::create();
      created.awid    = vif.awid;
      created.awaddr  = vif.awaddr;
      created.awcache = vif.awcache;
      created.awlen   = vif.awlen;
      created.awuser  = vif.awuser;
      created.awburst = vif.awburst;
      this.q_activeAW.push_back(created);
    end
    @(posedge vif.common_aclk);
  end
endtask:collectAW



task vdmatb_host_mon::collectWData();
  T_TRANS found_trans;

  forever begin
    if (vif.wvalid && vif.wready) begin
      this.qwdata.push_back(vif.wdata);
      this.qwstrb.push_back(vif.wstrb);

      if (w_start == 1) begin w_start = 0; end

      if (vif.wlast) begin
        found_trans = T_TRANS::type_id::create();

        found_trans.wdata = qwdata;
        found_trans.wstrb = qwstrb;
        q_activeW.push_back(found_trans);
        qwdata.delete();
        qwstrb.delete();
        w_start = 1;
      end
    end
    @(posedge vif.common_aclk);
  end

endtask:collectWData

task vdmatb_host_mon::collectB();
  T_TRANS found_trans;
  T_TRANS write_trans;

  found_trans = T_TRANS::type_id::create();
  write_trans  = T_TRANS::type_id::create();
  forever begin
    if (vif.bvalid && vif.bready) begin

      write_trans = q_activeAW.pop_front();
      found_trans = write_trans;
      write_trans = q_activeW.pop_front();
      found_trans.wdata = write_trans.wdata;
      found_trans.wstrb = write_trans.wstrb;
      found_trans.bresp = vif.bresp;
      
      this.ap_aw.write(found_trans);
    end
    @(posedge vif.common_aclk);
  end
endtask:collectB

task vdmatb_host_mon::collectAR();
  T_TRANS found_trans;

  forever begin
    if (vif.arvalid && vif.arready) begin
//      `uvm_info("COLLECTAR",$sformatf("araddr : %0h", vif.araddr),     UVM_MEDIUM);
      found_trans = T_TRANS::type_id::create();
      found_trans.araddr  = vif.araddr;
      found_trans.arlen   = vif.arlen;
      found_trans.aruser  = vif.aruser;
      found_trans.arid    = vif.arid;
      found_trans.arcache = vif.arcache;
      found_trans.arburst = vif.arburst;
      this.q_activeAR.push_back(found_trans);
    end
    @(posedge vif.common_aclk);
  end
endtask:collectAR

task vdmatb_host_mon::collectRData();
  localparam real RLAST_PROBABILITY = 50;

  T_TRANS found_trans;
  T_TRANS read_trans;
  int rand_num = 0;
  int pre_rand_num = 0;
  //int oneloop = 0;

  YesOrNo_t trans_ongo = NO;
  //int data_trans_count = 0;
  YesOrNo_t pre_rlast_done = NO;

  Len_t			 expected_len;

  found_trans = T_TRANS::type_id::create();
  read_trans  = T_TRANS::type_id::create();

  forever begin
    if (vif.rvalid && vif.rready) begin
      if(vif.rlast) begin
        this.count_prematureLast = 0;
      end
      
      if(this.tcfg.select_fault == HOST_R_PREMATURE_LAST_FAULT && this.count_prematureLast == 0) begin : PREMATURE_LAST
        this.vwrap_if.forceHostRLast_Enable();
        this.count_prematureLast++;
      end : PREMATURE_LAST
      
      if(trans_ongo == NO) begin
        if( q_activeAR.size()> 0) read_trans = q_activeAR.pop_front();
        else this.fatal("collectR",$sformatf("araddr: %0h, rdata : %0h ", read_trans.araddr, vif.rdata));
        //expected_len = read_trans.arlen;
        expected_len = read_trans.arlen + 1;
        //`uvm_info("ARLEN_CHK",$sformatf("ONGO: %0d, aruser: %0h, rdata_size: %0d, qrdata_size: %0d, arlen: %0d, expected_len: %0d, araddr: %0h, rdata : %0h, rlast : %0d", trans_ongo, read_trans.aruser, found_trans.rdata.size(), qrdata.size(), read_trans.arlen, expected_len, read_trans.araddr, vif.rdata, vif.rlast),     UVM_LOW);
        trans_ongo = YES;
      end

      expected_len--;

      if(this.tcfg.select_fault == HOST_R_NO_LAST_FAULT) begin
        this.vwrap_if.forceHostRLast_disable();
      end
      

      this.qrdata.push_back(vif.rdata);
      this.qrlast.push_back(vif.rlast);
      this.qrresp.push_back(vif.rresp);

      if(expected_len == 0) begin
          found_trans = T_TRANS::type_id::create();

          found_trans = read_trans;
          found_trans.rdata = qrdata;

          found_trans.q_rresp = qrresp;
          found_trans.q_rlast = qrlast;

          this.debug($sformatf("[COLLECTOR] aruser: %0h, rdata_size: %0d, qrdata_size: %0d, araddr: %0h, arlen: %0d, rlast_size : %0d", read_trans.aruser, found_trans.rdata.size(), qrdata.size(), found_trans.araddr, found_trans.arlen, found_trans.q_rlast.size()));
          
          // This fault is generated by forcing VIP signal(rlast)
          if(this.tcfg.test_type == FAULT_TEST && this.tcfg.select_fault == HOST_R_PREMATURE_LAST_FAULT && this.tcfg.getDmaIpType == MM) found_trans.q_rlast[0] = 0; 
          
          this.ap_ar.write(found_trans);
        
          qrdata.delete();
          qrlast.delete();
          qrresp.delete();
          //data_trans_count = 0;

  				pre_rlast_done = NO;
          trans_ongo = NO;
      end

      //oneloop = 1;

    end //valid


      @(posedge vif.common_aclk);
      
      if(this.vwrap_if.forced_rlast_state == 1) begin
        this.vwrap_if.releaseHostRLast();
      end
      this.count_gen_prematureLast++;
  end

endtask:collectRData

function void vdmatb_host_mon::showHistory(string prompt);
  //this.showReportHeader(this.mon_name, prompt);
  `uvm_info("showHistory",$sformatf("   - Number of transactions : %1d", this.num_trans),     UVM_MEDIUM);
  `uvm_info("showHistory",$sformatf("   - Number of status       : %1d", this.num_status),    UVM_MEDIUM);
  `uvm_info("showHistory",$sformatf("   - Number of interrupt    : %1d", this.num_interrupt), UVM_MEDIUM);
  `uvm_info("showHistory",$sformatf("   - Number of data         : %1d", this.num_data),      UVM_MEDIUM);
//this.showBar(prompt);
endfunction:showHistory



`endif // __VDMATB_HOST_MON_SVH__

