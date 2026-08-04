`ifndef __VDMA_CAXI_RD_MON_SVH__
`define __VDMA_CAXI_RD_MON_SVH__

class vdma_caxi_rd_mon #(
    parameter  type                    T_SEQ_ITEM = vdma_card_axi_seq_item,
    localparam type                    T_TRANS    = T_SEQ_ITEM
  )extends vmg_mon;

  typedef T_TRANS Q_TRANS[$];
  uvm_analysis_port#(T_TRANS) ap_ar;
  
  vdma_mst_tcfg tcfg;
  int rlast_cnt = 0;
  T_TRANS           q_CollectedRdTrans[$];
  protected T_TRANS q_activeAR[$];
  protected T_TRANS q_activeR[$];
  
  int count_gen_prematureLast;
  int count_prematureLast = 0;
  
  protected logic [HOST_DATA_WIDTH-1:0]            qwdata [$];
  protected logic [HOST_DATA_WIDTH/8-1:0]          qwstrb [$];
//  protected logic [HOST_DATA_WIDTH-1:0]            qrdata [$];

  protected logic                                  qrlast[$];
  protected logic [CARD_DATA_WIDTH-1:0]            qrdata[$];
  protected logic [`SVT_AXI_RESP_WIDTH-1:0]        qrresp[$];
  
  event ev_need_inter_reset;
  logic                    r_start;

  virtual svt_axi_master_if vif;
  virtual vdmatb_vwrap_if   vwrap_if;
  
  SelectFault_t select_fault;

  protected DmaTransType_t trans_type;
  protected string monitor_name;

  protected T_TRANS q_completed[$];

  local int num_trans;
  local int num_interrupt, num_status, num_data, num_fault_intr;

  `uvm_component_utils (vdma_caxi_rd_mon)
  function new(string name="vdma_caxi_rd_mon", uvm_component parent=null);
    super.new(name, parent);
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
  extern virtual function void connectVif();

  // ---------------------------- extended-specific
  extern local task collectAR();
  extern local task collectRData();


  extern virtual function YesOrNo_t resetCardMon();
  
  extern virtual function YesOrNo_t isBusy();
  
endclass:vdma_caxi_rd_mon



function void vdma_caxi_rd_mon::connectVif(); endfunction


function void vdma_caxi_rd_mon::build_phase(uvm_phase phase);
  string cfgdb_key;
  
  super.build_phase(phase);

  `vmg_get_cfgdb_at_me(string, "cfgdb_key", cfgdb_key)
  `vmg_get_cfgdb_anyone(virtual vdmatb_vwrap_if, $sformatf("%s_vwrap_if", cfgdb_key), this.vwrap_if)
  `vmg_get_cfgdb_at_me(vdma_mst_tcfg, "tcfg", this.tcfg)
  this.vif = this.vwrap_if.axi_if.master_if[1];
  
  this.ap_ar = new("ap_ar", this);
  this.monitor_name = $sformatf("VDMATB_CARD");

endfunction:build_phase


function void vdma_caxi_rd_mon::init_core(string call_info="unknown");
  this.q_activeAR.delete();
  this.q_activeR.delete();
  this.qrdata.delete();
endfunction:init_core


function YesOrNo_t vdma_caxi_rd_mon::hasBwdChannel(); return(YES); endfunction



task vdma_caxi_rd_mon::run_phase(uvm_phase phase);

  `uvm_info("VDMATB_CARD_MONITOR",$sformatf("run_phase"),     UVM_MEDIUM);
  fork
    this.collectAR();
    this.collectRData();
  join

endtask:run_phase

function void vdma_caxi_rd_mon::end_of_elaboration_phase(uvm_phase phase);
endfunction:end_of_elaboration_phase


function void vdma_caxi_rd_mon::init(string call_info="unknown"); endfunction:init


function YesOrNo_t vdma_caxi_rd_mon::resetCardMon();
  this.q_activeAR.delete();
  this.q_activeR.delete();
  
  this.qrdata.delete();
  
  if( ((this.q_activeAR.size == 0) && (this.q_activeR.size == 0) && (this.qrdata.size == 0)) )
    return(YES);
  
  return(NO);
endfunction : resetCardMon


function YesOrNo_t vdma_caxi_rd_mon::isBusy();
  if( (this.q_activeAR.size == 0) && (this.q_activeR.size == 0) )
    return(NO);
  
  return(YES);
endfunction : isBusy



task vdma_caxi_rd_mon::collectAR();
  T_TRANS found_trans;

  forever begin
    if (vif.arvalid && vif.arready) begin
      `uvm_info("COLLECTAR",$sformatf("araddr : %0h", vif.araddr),     UVM_MEDIUM);
      found_trans = T_TRANS::type_id::create();
      found_trans.araddr  = vif.araddr;
      found_trans.arlen   = vif.arlen;
      found_trans.aruser  = vif.aruser;
      found_trans.arid    = vif.arid;
      found_trans.arcache = vif.arcache;
      found_trans.arburst = vif.arburst;
      this.q_activeAR.push_back(found_trans);
//      this.q_4faultRresp.push_back(found_trans);
    end
    @(posedge vif.common_aclk);
  end
endtask:collectAR



task vdma_caxi_rd_mon::collectRData();
  localparam real RLAST_PROBABILITY = 50;

  T_TRANS found_trans;
  T_TRANS read_trans;
  T_TRANS fault_trans;
  int rand_num = 0;
  int pre_rand_num = 0;
  //int oneloop = 0;

  YesOrNo_t trans_ongo = NO;
  //int data_trans_count = 0;
  YesOrNo_t pre_rlast_done = NO;

  Len_t			 expected_len;

  found_trans = T_TRANS::type_id::create();
  read_trans  = T_TRANS::type_id::create();
  fault_trans = T_TRANS::type_id::create();

  forever begin
    if (vif.rvalid && vif.rready) begin
      if(vif.rlast) begin
        this.count_prematureLast = 0;
      end
      
      
      if(trans_ongo == NO) begin
        if( q_activeAR.size()> 0) read_trans = q_activeAR.pop_front();
        else this.fatal("collectR",$sformatf("araddr: %0h, rdata : %0h ", read_trans.araddr, vif.rdata));
        //expected_len = read_trans.arlen;
        expected_len = read_trans.arlen + 1;
        trans_ongo = YES;
      end

      expected_len--;

      
      this.qrdata.push_back(vif.rdata[CARD_DATA_WIDTH-1:0]);
      this.qrlast.push_back(vif.rlast);
      this.qrresp.push_back(vif.rresp);

      if(expected_len == 0) begin
        found_trans = T_TRANS::type_id::create();

        found_trans = read_trans;
        found_trans.rdata = qrdata;

        found_trans.q_rresp = qrresp;
        found_trans.q_rlast = qrlast;
        
        this.q_CollectedRdTrans.push_back(found_trans);
        
        this.rlast_cnt++;
        this.debug($sformatf("[COLLECTOR] aruser: %0h, rdata_size: %0d, qrdata_size: %0d, araddr: %0h, arlen: %0d, rlast_size : %0d", read_trans.aruser, found_trans.rdata.size(), qrdata.size(), found_trans.araddr, found_trans.arlen, found_trans.q_rlast.size()));

//        this.ap_ar.write(found_trans);
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
        this.vwrap_if.releaseCardRLast();
      end
      this.count_gen_prematureLast++;
  end

endtask:collectRData


function void vdma_caxi_rd_mon::showHistory(string prompt);
  `uvm_info("showHistory",$sformatf("   - Number of transactions : %1d", this.num_trans),     UVM_MEDIUM);
  `uvm_info("showHistory",$sformatf("   - Number of status       : %1d", this.num_status),    UVM_MEDIUM);
  `uvm_info("showHistory",$sformatf("   - Number of interrupt    : %1d", this.num_interrupt), UVM_MEDIUM);
  `uvm_info("showHistory",$sformatf("   - Number of data         : %1d", this.num_data),      UVM_MEDIUM);
endfunction:showHistory



`endif // __VDMA_CAXI_RD_MON_SVH__

