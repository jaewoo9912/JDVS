`ifndef __VDMA_CAXI_WR_MON_SVH__
`define __VDMA_CAXI_WR_MON_SVH__

class vdma_caxi_wr_mon #(
    parameter  type                    T_SEQ_ITEM = vdma_card_axi_seq_item,
    localparam type                    T_TRANS    = T_SEQ_ITEM
  )extends vmg_mon;

  typedef T_TRANS Q_TRANS[$];
  uvm_analysis_port#(T_TRANS) ap_aw;
  
  vdma_mst_tcfg tcfg;

  T_TRANS       q_CollectedWrTrans[$];
  local T_TRANS q_activeAW[$];
  local T_TRANS q_activeW[$];
  
  local int q_card_fault_bresp[$];
  
  local logic [CARD_DATA_WIDTH-1:0]            qwdata [$];
  local logic [CARD_DATA_WIDTH/8-1:0]          qwstrb [$];
  event ev_need_inter_reset;
  logic                    w_start;

  virtual svt_axi_master_if vif;
  virtual vdmatb_vwrap_if   vwrap_if;
  
  SelectFault_t select_fault;

  protected DmaTransType_t trans_type;
  protected string monitor_name;

  local T_TRANS q_completed[$];

  local int num_trans;
  local int num_interrupt, num_status, num_data, num_fault_intr;
  
  `uvm_component_utils (vdma_caxi_wr_mon)
  function new(string name="vdma_caxi_wr_mon", uvm_component parent=null);
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
  extern local task collectAW();
  extern local task collectWData();
  extern local task collectB();

  extern virtual function YesOrNo_t resetCardMon();
  
  extern virtual function YesOrNo_t isBusy();
  
  extern task waitFaultBresp(output int new_resp);
  
endclass:vdma_caxi_wr_mon

function void vdma_caxi_wr_mon::connectVif(); endfunction


task vdma_caxi_wr_mon::waitFaultBresp(output int new_resp);
  wait(this.q_card_fault_bresp.size > 0);
  new_resp = this.q_card_fault_bresp.pop_front();
endtask:waitFaultBresp


function void vdma_caxi_wr_mon::build_phase(uvm_phase phase);
  string cfgdb_key;
  
  super.build_phase(phase);
  
  `vmg_get_cfgdb_at_me(string, "cfgdb_key", cfgdb_key)
  `vmg_get_cfgdb_anyone(virtual vdmatb_vwrap_if, $sformatf("%s_vwrap_if", cfgdb_key), this.vwrap_if)
  `vmg_get_cfgdb_at_me(vdma_mst_tcfg, "tcfg", this.tcfg)
  this.vif = this.vwrap_if.axi_if.master_if[1];
  
  this.ap_aw = new("ap_aw", this);
  this.monitor_name = $sformatf("VDMATB_CARD");

endfunction:build_phase


function YesOrNo_t vdma_caxi_wr_mon::hasBwdChannel(); return(YES); endfunction


function void vdma_caxi_wr_mon::init_core(string call_info="unknown");
  this.q_activeAW.delete();
  this.q_activeW.delete();
  this.qwdata.delete();
  this.qwstrb.delete();
endfunction:init_core



task vdma_caxi_wr_mon::run_phase(uvm_phase phase);
  fork
    this.collectAW();
    this.collectWData();
    this.collectB();
  join
endtask:run_phase

function void vdma_caxi_wr_mon::end_of_elaboration_phase(uvm_phase phase);
endfunction:end_of_elaboration_phase


function void vdma_caxi_wr_mon::init(string call_info="unknown"); endfunction:init


function YesOrNo_t vdma_caxi_wr_mon::resetCardMon();
  this.q_activeAW.delete();
  this.q_activeW.delete();
  
  this.qwdata.delete();
  this.qwstrb.delete();
  
  if( (this.q_activeAW.size() == 0) && (this.q_activeW.size() == 0) && (this.qwdata.size() == 0) && (this.qwstrb.size() == 0) )
    return(YES);
  
  return(NO);
endfunction : resetCardMon


function YesOrNo_t vdma_caxi_wr_mon::isBusy();
  if( (this.q_activeAW.size() == 0) && (this.q_activeW.size() == 0) )
    return(NO);
  
  return(YES);
endfunction : isBusy


task vdma_caxi_wr_mon::collectAW();
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



task vdma_caxi_wr_mon::collectWData();
  T_TRANS found_trans;
  Data_t being_collected;

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

task vdma_caxi_wr_mon::collectB();
  T_TRANS found_trans;
  T_TRANS write_trans; //TODO : Remove write_trans, only using found_trans does not matter

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
      
      if(found_trans.bresp != 0) this.q_card_fault_bresp.push_back(vif.bresp);
      
      this.q_CollectedWrTrans.push_back(found_trans);
//      this.ap_aw.write(found_trans);
    end
    @(posedge vif.common_aclk);
  end
endtask:collectB


function void vdma_caxi_wr_mon::showHistory(string prompt);
  `uvm_info("showHistory",$sformatf("   - Number of transactions : %1d", this.num_trans),     UVM_MEDIUM);
  `uvm_info("showHistory",$sformatf("   - Number of status       : %1d", this.num_status),    UVM_MEDIUM);
  `uvm_info("showHistory",$sformatf("   - Number of interrupt    : %1d", this.num_interrupt), UVM_MEDIUM);
  `uvm_info("showHistory",$sformatf("   - Number of data         : %1d", this.num_data),      UVM_MEDIUM);
endfunction:showHistory



`endif // __VDMA_CAXI_WR_MON_SVH__