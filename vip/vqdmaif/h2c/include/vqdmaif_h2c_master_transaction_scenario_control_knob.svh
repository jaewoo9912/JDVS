`ifndef __VQDMAIF_H2C_MASTER_TRANSACTION_SCENARIO_CONTROL_KNOB_SVH__
`define __VQDMAIF_H2C_MASTER_TRANSACTION_SCENARIO_CONTROL_KNOB_SVH__


class vqdmaif_h2c_master_transaction_scenario_control_knob extends vbfm_transaction_scenario_control_knob;
  vqdmaif_h2c_param param;
  int DATA_SIZE;

  QdmaH2CCmd_t cmd_pl_list[];
  QdmaH2CCmdSideBand_t cmd_sideband_pl_list[];

  // pkt type, number of pkt
  rand QdmaH2CTransPktType_t pkt_type; int prob_gather_pkt=50;
  constraint c_pkt_type { pkt_type dist {QDMA_GATHER_PKT := prob_gather_pkt, QDMA_SOLO_PKT := 100-prob_gather_pkt}; };
  rand int num_cmd_per_pkt; int start_num_cmd_per_pkt, end_num_cmd_per_pkt, max_num_cmd_per_pkt;
  constraint c_num_cmd_per_pkt{
    pkt_type == QDMA_SOLO_PKT   -> num_cmd_per_pkt == 1;
    pkt_type == QDMA_GATHER_PKT -> num_cmd_per_pkt inside {[start_num_cmd_per_pkt:end_num_cmd_per_pkt]};
  }
  constraint c_available_num_cmd_per_pkt { num_cmd_per_pkt inside {[1:max_num_cmd_per_pkt]}; };
  // qid
  rand QdmaQId_t qid; QdmaQId_t start_qid, end_qid, max_qid;
  constraint c_qid           { qid inside {[start_qid:end_qid]}; };
  constraint c_available_qid { qid inside {[0        :max_qid]}; };
  // addr
  rand QdmaAddr_t addr_list[]; QdmaAddr_t start_addr, end_addr, max_addr;
  constraint c_addr_list_size{ addr_list.size == num_cmd_per_pkt; }
  constraint c_addr{
    foreach(addr_list[i]) addr_list[i] inside {[start_addr:end_addr]}; 
  };
  constraint c_available_addr{
    foreach(addr_list[i]) addr_list[i] inside {[0:max_addr]}; 
  };
  // len
  rand QdmaLen_t len_list[]; QdmaLen_t start_len, end_len, max_len;
  constraint c_len_list_size{ len_list.size == num_cmd_per_pkt; }
  constraint c_len{
    foreach(len_list[i]) len_list[i] inside {[start_len:end_len]}; 
  };
  constraint c_available_len{
    foreach(len_list[i]) len_list[i] inside {[0:max_len]}; 
  };
  // sop/eop
  rand logic sop_list[], eop_list[];
  constraint c_sop_eop{
    sop_list.size() == num_cmd_per_pkt; 
    eop_list.size() == num_cmd_per_pkt; 
    foreach(sop_list[i]){
      if(pkt_type == QDMA_SOLO_PKT){
        sop_list[i] == 1; eop_list[i] == 1;
      }else if(pkt_type == QDMA_GATHER_PKT){
        if     (num_cmd_per_pkt == 1)    { sop_list[i] == 1; eop_list[i] == 1; }
        else   {
          if     (i == 0)                { sop_list[i] == 1; eop_list[i] == 0; }
          else if(i == num_cmd_per_pkt-1){ sop_list[i] == 0; eop_list[i] == 1; }
          else                           { sop_list[i] == 0; eop_list[i] == 0; }
        }
      }
    }
  }
  // func
  rand QdmaFunc_t func; QdmaFunc_t start_func, end_func, max_func;
  constraint c_func           { func inside {[start_func:end_func]}; };
  constraint c_available_func { func inside {[0         :max_func]}; };
  // port_id
  rand QdmaPortId_t port_id; QdmaPortId_t start_port_id, end_port_id, max_port_id;
  constraint c_port_id           { port_id inside {[start_port_id:end_port_id]}; };
  constraint c_available_port_id { port_id inside {[0            :max_port_id]}; };
  // sideband
  rand QdmaDmaId_t dma_id; QdmaDmaId_t start_dma_id, end_dma_id, max_dma_id;
  constraint c_dma_id              { dma_id inside {[start_dma_id:end_dma_id]}; };
  constraint c_available_dma_id    { dma_id inside {[0           :max_dma_id]}; };
  rand QdmaStrId_t str_id; QdmaStrId_t start_str_id, end_str_id, max_str_id;
  constraint c_str_id              { str_id inside {[start_str_id:end_str_id]}; };
  constraint c_available_str_id    { str_id inside {[0           :max_str_id]}; };
  rand QdmaVecId_t vec_id; QdmaVecId_t start_vec_id, end_vec_id, max_vec_id;
  constraint c_vec_id              { vec_id inside {[start_vec_id:end_vec_id]}; };
  constraint c_available_vec_id    { vec_id inside {[0           :max_vec_id]}; };
  rand logic last_rd; logic start_last_rd, end_last_rd, max_last_rd;
  constraint c_last_rd              { last_rd inside {[start_last_rd:end_last_rd]}; };
  constraint c_available_last_rd    { last_rd inside {[0            :max_last_rd]}; };
  int prob_req_intr = 0;
  int prob_req_stat = 0;
  rand logic req_intr = 0;
  constraint c_req_intr { req_intr dist {1 := prob_req_intr, 0 := 100 - prob_req_intr}; };
  rand logic req_stat = 0;
  constraint c_req_stat { req_stat dist {1 := prob_req_stat, 0 := 100 - prob_req_stat}; };
  // no_dma: command-only transaction (no data path). Always solo packet.
  int prob_no_dma = 0;
  rand logic no_dma;
  constraint c_no_dma      { no_dma dist {1 := prob_no_dma, 0 := 100 - prob_no_dma}; };
  constraint c_no_dma_solo { no_dma == 1 -> pkt_type == QDMA_SOLO_PKT; };

  rand QdmaFId_t fid;  QdmaFId_t start_fid, end_fid, max_fid;
  vqdmaif_fid_generator fid_gen;
  constraint c_fid         { fid inside {[start_fid:end_fid]}; };
  constraint available_fid { fid inside {[0        :max_fid]}; };
  // alignment
  int alignment=0;  // 0: alignment disabled
  constraint c_alignment{
    foreach(addr_list[i]){
      if(alignment != 0){
        addr_list[i]%alignment == 0;
        len_list [i]%alignment == 0;
        len_list [i]  inside {[alignment:end_len]};
      }
    }
  };
  // out-of-bound
  constraint c_acs_range{
    foreach(addr_list[i]){
      addr_list[i]+len_list[i]-1 <= end_addr;
    }
  };

  // BFM timing parameters: cmd2cmd
  rand int unsigned cmd2cmd_delay_list[];
  int unsigned start_cmd2cmd_delay=0, end_cmd2cmd_delay=5;
  constraint c_cmd2cmd_delay_list_size{ cmd2cmd_delay_list.size == num_cmd_per_pkt; }
  constraint c_cmd2cmd_delay{
    foreach(cmd2cmd_delay_list[i]) cmd2cmd_delay_list[i] inside {[start_cmd2cmd_delay:end_cmd2cmd_delay]}; 
  };


  `uvm_object_utils(vqdmaif_h2c_master_transaction_scenario_control_knob)
  function new(string name="vqdmaif_h2c_master_transaction_scenario_control_knob");
    super.new(name);
  endfunction
  extern virtual function void finalize();
  extern virtual function StringQ_t getInfoList();
  extern function void post_randomize();
  extern local function void makeCmdPl();
  virtual function string decideReportFamilyId(); return("H2C_MASTER_TRANSACTION_SCENARIO_CONTROL_KNOB"); endfunction

  extern function void forceRandomKnob_CtrlInfo(QdmaifDmaTransCtrlInfo_t me);
  extern function void forceRandomKnob_UsingAddrRange(vrand_address_range range);
  extern virtual function void makeDirectTestable();
  extern virtual function void enterForcingMode();
  extern virtual function void exitForcingMode();
endclass:vqdmaif_h2c_master_transaction_scenario_control_knob


function void vqdmaif_h2c_master_transaction_scenario_control_knob::makeDirectTestable();
  this.start_cmd2cmd_delay=0;
  this.end_cmd2cmd_delay = this.start_cmd2cmd_delay;
  this.reportMainEvent_body("MAKE-DIRECT-TESTABLE", "Adjusted sck to issue CMD immediately", UVM_LOW);
endfunction:makeDirectTestable


function void vqdmaif_h2c_master_transaction_scenario_control_knob::makeCmdPl();
  QdmaH2CCmd_t seed_pl=0;
  seed_pl.qid = this.qid;
  seed_pl.func = this.func;
  seed_pl.port_id = this.port_id;
  this.cmd_pl_list = new[this.num_cmd_per_pkt];
  foreach(this.cmd_pl_list[i])begin
    this.cmd_pl_list[i]=seed_pl;
    this.cmd_pl_list[i].addr = this.addr_list[i];
    this.cmd_pl_list[i].len = this.len_list[i];
    this.cmd_pl_list[i].sop = this.sop_list[i];
    this.cmd_pl_list[i].eop = this.eop_list[i];
    this.cmd_pl_list[i].no_dma = this.no_dma;
  end

  this.cmd_sideband_pl_list = new[this.num_cmd_per_pkt];
  foreach(this.cmd_sideband_pl_list[i]) begin
    this.cmd_sideband_pl_list[i].dma_id   = this.dma_id;
    this.cmd_sideband_pl_list[i].str_id   = this.str_id;
    this.cmd_sideband_pl_list[i].vec_id   = this.vec_id;
    this.cmd_sideband_pl_list[i].last_rd  = this.last_rd;
    this.cmd_sideband_pl_list[i].req_intr = 0;
    this.cmd_sideband_pl_list[i].req_stat = 0;
    this.cmd_sideband_pl_list[i].fid      = this.fid;
  end
  this.cmd_sideband_pl_list[this.num_cmd_per_pkt - 1].req_intr = this.req_intr;
  this.cmd_sideband_pl_list[this.num_cmd_per_pkt - 1].req_stat = this.req_stat;
endfunction:makeCmdPl


function void vqdmaif_h2c_master_transaction_scenario_control_knob::post_randomize();
  if(this.fid_gen != null) this.fid = this.fid_gen.gen();
  this.makeCmdPl();
endfunction:post_randomize


function void vqdmaif_h2c_master_transaction_scenario_control_knob::finalize();
  if(this.param == null) `vmg_fatal_wrong_usage(this.get_name, $sformatf("finalize -- param==null"));
  this.DATA_SIZE = this.param.PARAM.PORT.DATA_WIDTH/8;
  this.max_qid     = (1<<$bits(QdmaQId_t))-1;
  this.max_addr    = (1<<param.PARAM.PORT.ADDR_WIDTH)-1;
  this.max_func    = (1<<$bits(QdmaFunc_t))-1;
  this.max_port_id = (1<<$bits(QdmaPortId_t))-1;
  this.max_dma_id  = (1<<$bits(QdmaDmaId_t))-1;
  this.max_str_id  = (1<<$bits(QdmaStrId_t))-1;
  this.max_vec_id  = (1<<$bits(QdmaVecId_t))-2;
  this.max_last_rd = (1<<$bits(logic))-1;
  this.max_fid     = (1<<$bits(QdmaFId_t)) - 1;
  // [HISTORY] Decided based on the use case as the following: (2025/5/E)
  //   - NRT project: number of max command per pkt: 66
  //   - Jumbo packet: 9000+header length < 10000
  this.max_num_cmd_per_pkt = 80;
  this.max_len             = 10000;
  // ------------------------------------
  this.start_num_cmd_per_pkt = 1; this.end_num_cmd_per_pkt = this.max_num_cmd_per_pkt;
  this.start_qid             = 0; this.end_qid             =  this.max_qid;
  this.start_addr            = 0; this.end_addr            =  this.max_addr;
  this.start_len             = 1; this.end_len             =  this.max_len;
  this.start_func            = 0; this.end_func            =  this.max_func;
  this.start_port_id         = 0; this.end_port_id         =  this.max_port_id;
  this.start_dma_id          = 0; this.end_dma_id          =  this.max_dma_id;
  this.start_str_id          = 0; this.end_str_id          =  this.max_str_id;
  this.start_vec_id          = 0; this.end_vec_id          =  this.max_vec_id;
  this.start_last_rd         = 0; this.end_last_rd         =  this.max_last_rd;
  this.start_fid             = 0; this.end_fid             =  this.max_fid;
endfunction:finalize


function StringQ_t vqdmaif_h2c_master_transaction_scenario_control_knob::getInfoList();
  StringQ_t result;
  result.push_back($sformatf(" * PORT_PARAM"));
  result.push_back($sformatf("    %s", this.param.getInfo));
  result.push_back($sformatf(" * Randomization inputs"));
  result.push_back($sformatf("    - qid     : 0x%1h~0x%1h", this.start_qid, this.end_qid));
  result.push_back($sformatf("    - addr    : 0x%1h~0x%1h", this.start_addr, this.end_addr));
  result.push_back($sformatf("    - len     : 0x%1h~0x%1h", this.start_len, this.end_len));
  result.push_back($sformatf("    - func    : 0x%1h~0x%1h", this.start_func, this.end_func));
  result.push_back($sformatf("    - port_id : 0x%1h~0x%1h", this.start_port_id, this.end_port_id));
  return(result);
endfunction:getInfoList


function void vqdmaif_h2c_master_transaction_scenario_control_knob::forceRandomKnob_CtrlInfo(QdmaifDmaTransCtrlInfo_t me);
  this.start_qid     = me.qid; 
  this.start_fid     = me.fid; 
  this.start_addr    = me.addr;
  this.start_len     = me.len;
  this.start_func    = me.func;
  this.start_port_id = me.port_id;
  // -----------------------------
  this.end_qid     = this.start_qid; 
  this.end_fid     = this.start_fid; 
  this.end_addr    = this.start_addr; 
  this.end_len     = this.start_len; 
  this.end_func    = this.start_func; 
  this.end_port_id = this.start_port_id; 

  this.c_acs_range.constraint_mode(0);
endfunction:forceRandomKnob_CtrlInfo


function void vqdmaif_h2c_master_transaction_scenario_control_knob::enterForcingMode();
  super.enterForcingMode();
  this.c_acs_range.constraint_mode(0);
endfunction


function void vqdmaif_h2c_master_transaction_scenario_control_knob::exitForcingMode();
  super.exitForcingMode();
  this.c_acs_range.constraint_mode(1);
endfunction


function void vqdmaif_h2c_master_transaction_scenario_control_knob::forceRandomKnob_UsingAddrRange(vrand_address_range range);
  this.start_addr = range.start_addr;
  this.start_len  = range.size;
  // --------------
  this.end_addr = this.start_addr;
  this.end_len  = this.start_len;
  // --------------
  this.c_acs_range.constraint_mode(0);
endfunction : forceRandomKnob_UsingAddrRange















`endif // __VQDMAIF_H2C_MASTER_TRANSACTION_SCENARIO_CONTROL_KNOB_SVH__
