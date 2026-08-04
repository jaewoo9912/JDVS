`ifndef __VQDMAIF_C2H_MASTER_TRANSACTION_SCENARIO_CONTROL_KNOB_SVH__
`define __VQDMAIF_C2H_MASTER_TRANSACTION_SCENARIO_CONTROL_KNOB_SVH__



class vqdmaif_c2h_master_transaction_scenario_control_knob extends vbfm_transaction_scenario_control_knob;
  vqdmaif_c2h_param param;
  int DATA_SIZE;

  QdmaC2HCmd_t  cmd_pl;
  QdmaC2HData_t data_pl_list[];
  QdmaC2HCmdSideBand_t cmd_sideband_pl;
  QdmaC2HDataSideBand_t data_sideband_pl_list[];

  // qid
  rand QdmaQId_t qid; QdmaQId_t start_qid, end_qid, max_qid;
  constraint c_qid           { qid inside {[start_qid:end_qid]}; };
  constraint c_available_qid { qid inside {[0        :max_qid]}; };
  // addr
  rand QdmaAddr_t addr; QdmaAddr_t start_addr, end_addr, max_addr;
  constraint c_addr           { addr inside {[start_addr:end_addr]}; };
  constraint c_available_addr { addr inside {[0         :max_addr]}; };
  // len
  rand QdmaLen_t len; QdmaLen_t start_len, end_len, max_len;
  constraint c_len           { len inside {[start_len:end_len]}; };
  constraint c_available_len { len inside {[0        :max_len]}; };
  // func
  rand QdmaFunc_t func; QdmaFunc_t start_func, end_func, max_func;
  constraint c_func           { func inside {[start_func:end_func]}; };
  constraint c_available_func { func inside {[0         :max_func]}; };
  // port_id
  rand QdmaPortId_t port_id; QdmaPortId_t start_port_id, end_port_id, max_port_id;
  constraint c_port_id           { port_id inside {[start_port_id:end_port_id]}; };
  constraint c_available_port_id { port_id inside {[0            :max_port_id]}; };
  // sideband
  rand QdmaDmaId_t dma_id = 0; QdmaDmaId_t start_dma_id, end_dma_id, max_dma_id; 
  constraint c_dma_id            { dma_id inside {[start_dma_id:end_dma_id]}; };
  constraint c_available_dma_id  { dma_id inside {[0           :end_dma_id]}; };
  rand QdmaStrId_t str_id = 0; QdmaStrId_t start_str_id, end_str_id, max_str_id; 
  constraint c_str_id            { str_id inside {[start_str_id:end_str_id]}; };
  constraint c_available_str_id  { str_id inside {[0           :end_str_id]}; };
  rand QdmaVecId_t vec_id = 0; QdmaVecId_t start_vec_id, end_vec_id, max_vec_id; 
  constraint c_vec_id            { vec_id inside {[start_vec_id:end_vec_id]}; };
  constraint c_available_vec_id  { vec_id inside {[0           :end_vec_id]}; };
  int prob_req_intr = 0;
  int prob_req_stat = 0;
  rand logic req_intr = 0;
  constraint c_req_intr { req_intr dist {1 := prob_req_intr, 0 := 100-prob_req_intr}; };
  rand logic req_stat = 0;
  constraint c_req_stat { req_stat dist {1 := prob_req_stat, 0 := 100-prob_req_stat}; };
  // ----------------------- fid
  rand QdmaFId_t fid; QdmaFId_t start_fid, end_fid, max_fid;
  vqdmaif_fid_generator fid_gen;
  constraint c_fid           { fid inside {[start_fid:end_fid]}; };
  constraint c_available_fid { fid inside {[0        :max_fid]}; };
  // alignment
  int alignment=0;  // 0: alignment disabled
  constraint c_alignment{
    if(alignment != 0){
      addr%alignment == 0;
      len%alignment == 0;
      len inside {[alignment:end_len]};
    }
  };
  // out-of-bound
  constraint c_acs_range{
    addr+len-1 <= end_addr;
  };
  // data/keep
  rand int num_beat;
  rand QdmaData_t data_list[];
  QdmaData_t start_data, end_data, max_data;
  rand QdmaKeep_t keep_list[];
  QdmaKeep_t max_keep;
  constraint c_num_data {
    solve addr before num_beat;
    solve len before num_beat;
    if(len % DATA_SIZE == 0) num_beat == len/DATA_SIZE;
    else                     num_beat == len/DATA_SIZE + 1;
  }
  constraint c_data_size{ solve num_beat before data_list; data_list.size == num_beat; }
  constraint c_data { foreach(data_list[i]) data_list[i] inside {[start_data:end_data]}; };
  constraint c_keep_size{ solve num_beat before keep_list; keep_list.size == num_beat; }

  // BFM timing parameters: cmd2cmd
  rand int unsigned cmd2cmd_delay;
  int unsigned start_cmd2cmd_delay=0, end_cmd2cmd_delay=5;
  constraint c_cmd2cmd_delay{ cmd2cmd_delay inside {[start_cmd2cmd_delay:end_cmd2cmd_delay]}; };
  // BFM timing parameters: data2data
  rand int unsigned data2data_delay_list[];
  int unsigned start_data2data_delay=0, end_data2data_delay=3;
  constraint c_data2data_delay_size{ solve num_beat before data2data_delay_list; data2data_delay_list.size == num_beat; }
  constraint c_data2data_delay { foreach(data2data_delay_list[i]) data2data_delay_list[i] inside {[start_data2data_delay:end_data2data_delay]}; };
  // BFM timing parameters : cmd2data
  rand int unsigned cmd2data_delay;
  int unsigned start_cmd2data_delay=0, end_cmd2data_delay=5;
  constraint c_cmd2data_delay{ cmd2data_delay inside {[start_cmd2data_delay:end_cmd2data_delay]}; };
  // BFM timing parameters : status_pending
  rand int unsigned status_pending_cycle;
  int unsigned start_status_pending_cycle=0, end_status_pending_cycle=5;
  constraint c_status_pending_cycle{ status_pending_cycle inside {[start_status_pending_cycle:end_status_pending_cycle]}; };
  `uvm_object_utils(vqdmaif_c2h_master_transaction_scenario_control_knob)
  function new(string name="vqdmaif_c2h_master_transaction_scenario_control_knob");
    super.new(name);
  endfunction
  extern virtual function void finalize();
  extern virtual function StringQ_t getInfoList();
  extern function void post_randomize();
  extern local function void makeFwdPl();
  extern local function void makeKeep();
  virtual function string decideReportFamilyId(); return("C2H_MASTER_TRANSACTION_SCENARIO_CONTROL_KNOB"); endfunction

  extern function void forceRandomKnob_CtrlInfo(QdmaifDmaTransCtrlInfo_t me);
  extern function void forceRandomKnob_UsingAddrRange(vrand_address_range range);
  extern virtual function void makeDirectTestable();
  extern virtual function void enterForcingMode();
  extern virtual function void exitForcingMode();

endclass:vqdmaif_c2h_master_transaction_scenario_control_knob


function void vqdmaif_c2h_master_transaction_scenario_control_knob::makeDirectTestable();
  this.start_cmd2cmd_delay=0;
  this.start_data2data_delay=0;
  this.end_cmd2cmd_delay = this.start_cmd2cmd_delay;
  this.end_data2data_delay = this.start_data2data_delay;
  this.reportMainEvent_body("MAKE-DIRECT-TESTABLE", "Adjusted sck to issue CMD and DATA transfers immediately", UVM_LOW);
endfunction:makeDirectTestable


function void vqdmaif_c2h_master_transaction_scenario_control_knob::forceRandomKnob_CtrlInfo(QdmaifDmaTransCtrlInfo_t me);
  this.start_qid     = me.qid; 
  this.start_addr    = me.addr;
  this.start_len     = me.len;
  this.start_func    = me.func;
  this.start_port_id = me.port_id;
  // -----------------------------
  this.end_qid     = this.start_qid; 
  this.end_addr    = this.start_addr; 
  this.end_len     = this.start_len; 
  this.end_func    = this.start_func; 
  this.end_port_id = this.start_port_id; 

  this.c_acs_range.constraint_mode(0);
endfunction:forceRandomKnob_CtrlInfo


function void vqdmaif_c2h_master_transaction_scenario_control_knob::makeFwdPl();
  QdmaC2HData_t seed_data_pl;
  this.cmd_pl = 0;
  this.cmd_pl.qid     = this.qid;
  this.cmd_pl.addr    = this.addr;
  this.cmd_pl.func    = this.func;
  this.cmd_pl.port_id = this.port_id;

  seed_data_pl         = 0;
  seed_data_pl.qid     = this.qid;
  seed_data_pl.port_id = this.port_id;
  this.data_pl_list = new[this.data_list.size];
  foreach(this.data_pl_list[i])begin
    this.data_pl_list[i] = seed_data_pl;
    this.data_pl_list[i].data = this.data_list[i];
    this.data_pl_list[i].len = this.len;
    if(i == this.data_pl_list.size-1)begin
      this.data_pl_list[i].last = 1;
      this.data_pl_list[i].mty = (this.DATA_SIZE - (this.len % this.DATA_SIZE)) % this.DATA_SIZE;
    end
  end

  this.cmd_sideband_pl.dma_id   = this.dma_id;
  this.cmd_sideband_pl.str_id   = this.str_id;
  this.cmd_sideband_pl.vec_id   = this.vec_id;
  this.cmd_sideband_pl.len      = this.len;
  this.cmd_sideband_pl.req_intr = this.req_intr;
  this.cmd_sideband_pl.req_stat = this.req_stat;
  this.cmd_sideband_pl.fid      = this.fid;
  this.data_sideband_pl_list = new[this.data_list.size];
  foreach(this.data_sideband_pl_list[i]) begin
    this.data_sideband_pl_list[i].dma_id = this.dma_id;
    this.data_sideband_pl_list[i].fid    = this.fid;
  end
endfunction:makeFwdPl


function void vqdmaif_c2h_master_transaction_scenario_control_knob::post_randomize();
  if(this.fid_gen != null) this.fid = this.fid_gen.gen();
  this.makeKeep();
  this.makeFwdPl();
endfunction:post_randomize


function void vqdmaif_c2h_master_transaction_scenario_control_knob::makeKeep();
  int remained_len = this.len;
  foreach(this.keep_list[i])begin
    int effective_len = i < this.keep_list.size-1 ? max_keep : remained_len;
    this.keep_list[i] = 1<<effective_len;
    remained_len -= effective_len;
  end
endfunction:makeKeep


function void vqdmaif_c2h_master_transaction_scenario_control_knob::finalize();
  if(this.param == null) `vmg_fatal_wrong_usage(this.get_name, $sformatf("finalize -- param==null"));
  this.DATA_SIZE = this.param.PARAM.PORT.DATA_WIDTH/8;
  this.max_qid     = (1<<$bits(QdmaQId_t))-1;
  this.max_addr    = (1<<this.param.PARAM.PORT.ADDR_WIDTH)-1;
  this.max_len     = 10000;//(1<<$bits(QdmaLen_t))-1;//jumbo packet size = 9000+header length < 10000
  this.max_func    = (1<<$bits(QdmaFunc_t))-1;
  this.max_port_id = (1<<$bits(QdmaPortId_t))-1;
  this.max_data    = (1<<this.param.PARAM.PORT.DATA_WIDTH)-1;
  this.max_keep    = (1<<this.DATA_SIZE)-1;
  this.max_dma_id  = (1<<$bits(QdmaDmaId_t))-1;
  this.max_str_id  = (1<<$bits(QdmaStrId_t))-1;
  this.max_vec_id  = (1<<$bits(QdmaVecId_t))-2; //vec_id='h1f is used in fault (mbdma spec)
  this.max_fid     = (1<<$bits(QdmaFId_t)) - 1;
  // ------------------------------------
  this.start_qid     = 0; this.end_qid     =  this.max_qid;
  this.start_addr    = 0; this.end_addr    =  this.max_addr;
  this.start_len     = 1; this.end_len     =  this.max_len;
  this.start_func    = 0; this.end_func    =  this.max_func;
  this.start_port_id = 0; this.end_port_id =  this.max_port_id;
  this.start_data    = 0; this.end_data    =  this.max_data;
  this.start_dma_id  = 0; this.end_dma_id  =  this.max_dma_id;
  this.start_str_id  = 0; this.end_str_id  =  this.max_str_id;
  this.start_vec_id  = 0; this.end_vec_id  =  this.max_vec_id;
  this.start_fid     = 0; this.end_fid     =  this.max_fid;
endfunction:finalize


function StringQ_t vqdmaif_c2h_master_transaction_scenario_control_knob::getInfoList();
  StringQ_t result;
  result.push_back($sformatf(" * PARAM"));
  result.push_back($sformatf("    %s", this.param.getInfo));
  result.push_back($sformatf(" * Randomization inputs"));
  result.push_back($sformatf("    - qid     : 0x%1h~0x%1h", this.start_qid, this.end_qid));
  result.push_back($sformatf("    - addr    : 0x%1h~0x%1h", this.start_addr, this.end_addr));
  result.push_back($sformatf("    - len     : 0x%1h~0x%1h", this.start_len, this.end_len));
  result.push_back($sformatf("    - func    : 0x%1h~0x%1h", this.start_func, this.end_func));
  result.push_back($sformatf("    - port_id : 0x%1h~0x%1h", this.start_port_id, this.end_port_id));
  return(result);
endfunction:getInfoList


function void vqdmaif_c2h_master_transaction_scenario_control_knob::forceRandomKnob_UsingAddrRange(vrand_address_range range);
  this.start_addr = range.start_addr;
  this.start_len  = range.size;
  // --------------
  this.end_addr = this.start_addr;
  this.end_len  = this.start_len;
  // --------------
  this.c_acs_range.constraint_mode(0);
endfunction : forceRandomKnob_UsingAddrRange


function void vqdmaif_c2h_master_transaction_scenario_control_knob::enterForcingMode();
  super.enterForcingMode();
  this.c_acs_range.constraint_mode(0);
endfunction


function void vqdmaif_c2h_master_transaction_scenario_control_knob::exitForcingMode();
  super.exitForcingMode();
  this.c_acs_range.constraint_mode(1);
endfunction








`endif // __VQDMAIF_C2H_MASTER_TRANSACTION_SCENARIO_CONTROL_KNOB_SVH__
