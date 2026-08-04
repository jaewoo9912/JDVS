`ifndef __VQDMAIF_H2C_TRANSACTION_DISPATCH_SEQUENCE_SVH__
`define __VQDMAIF_H2C_TRANSACTION_DISPATCH_SEQUENCE_SVH__



class vqdmaif_h2c_transaction_dispatch_request extends vbfm_transaction_dispatch_request;
  QdmaifDmaTransCtrlInfo_t ctrl_info=UNDEFINED_QDMAIF_DMA_CTRL_INFO;
  int prob_gather_pkt=50;
  // --------------------------
  vqdmaif_h2c_master_sequence_item item;
  function new(string name="vqdmaif_h2c_transaction_dispatch_request");
    super.new(name);
  endfunction
  virtual function string getInfo();
    return($sformatf("%s ctrl_info=[%s] prob_gather_pkt=%s",
      super.getInfo,
      MakeString_QdmaifDmaTransCtrlInfo_t(this.ctrl_info),
      MakeString_Percent(this.prob_gather_pkt)
    ));
  endfunction
  virtual function void finalize();
    if(this.ctrl_info == UNDEFINED_QDMAIF_DMA_CTRL_INFO)begin
      `vmg_fatal_wrong_usage(this.get_name, "finalize -- ctrl_info == UNDEFINED_QDMAIF_DMA_CTRL_INFO");
    end
  endfunction
endclass:vqdmaif_h2c_transaction_dispatch_request



class vqdmaif_h2c_transaction_dispatch_sequence extends vqdmaif_h2c_master_random_sequence;
  typedef vqdmaif_h2c_transaction_dispatch_request T_DISPATCH_REQ;
  T_DISPATCH_REQ q_pending[$];
  `uvm_object_utils(vqdmaif_h2c_transaction_dispatch_sequence)
  function new(string name="vqdmaif_h2c_transaction_dispatch_sequence");
    super.new(name);
  endfunction
  extern virtual function void set_sequencer(uvm_sequencer_base sequencer);
  extern virtual task body();
  extern task executeTrans(string trans_name, QdmaQId_t qid, QdmaAddr_t addr, QdmaLen_t len, QdmaPortId_t port_id, QdmaFunc_t func, output T_DISPATCH_REQ dispatch_req);
  extern task executeTrans_WithTransCtrlInfo(string trans_name, QdmaifDmaTransCtrlInfo_t ctrl_info, output T_DISPATCH_REQ dispatch_req);
  extern function void pushReq(T_DISPATCH_REQ me);
  extern local function void makeupReq(T_DISPATCH_REQ me);
  extern local task doOnService();
endclass:vqdmaif_h2c_transaction_dispatch_sequence

task vqdmaif_h2c_transaction_dispatch_sequence::executeTrans(string trans_name, QdmaQId_t qid, QdmaAddr_t addr, QdmaLen_t len, QdmaPortId_t port_id, QdmaFunc_t func, output T_DISPATCH_REQ dispatch_req);
  dispatch_req = new(trans_name);
  dispatch_req.ctrl_info.protcl_type = QDMA_H2C_ST;
  dispatch_req.ctrl_info.DATA_SIZE = this.sck.DATA_SIZE;
  dispatch_req.ctrl_info.qid = qid;
  dispatch_req.ctrl_info.addr = addr;
  dispatch_req.ctrl_info.len = len;
  dispatch_req.ctrl_info.func = func;
  dispatch_req.ctrl_info.port_id = port_id;
  dispatch_req.finalize();
  dispatch_req.prob_gather_pkt = 0;
  this.pushReq(dispatch_req);
  dispatch_req.waitDone($sformatf("%s::executeTrans", this.get_name));
endtask:executeTrans

task vqdmaif_h2c_transaction_dispatch_sequence::executeTrans_WithTransCtrlInfo(string trans_name, QdmaifDmaTransCtrlInfo_t ctrl_info, output T_DISPATCH_REQ dispatch_req);
  dispatch_req = new(trans_name);
  dispatch_req.ctrl_info = ctrl_info;
  dispatch_req.finalize();
  dispatch_req.prob_gather_pkt=0;
  this.pushReq(dispatch_req);
endtask:executeTrans_WithTransCtrlInfo

task vqdmaif_h2c_transaction_dispatch_sequence::body();
  fork
    this.doOnService();
  join
endtask:body

function void vqdmaif_h2c_transaction_dispatch_sequence::set_sequencer(uvm_sequencer_base sequencer);
  super.set_sequencer(sequencer);
  if(this.sck == null)begin
    this.sck = this.sqr.createSck($sformatf("%s.sck", this.get_name));
    this.sck.makeDirectTestable();
  end
  this.sck.enterForcingMode();
endfunction:set_sequencer

function void vqdmaif_h2c_transaction_dispatch_sequence::pushReq(T_DISPATCH_REQ me);
  this.makeupReq(me);
  this.q_pending.push_back(me);
endfunction:pushReq
  
function void vqdmaif_h2c_transaction_dispatch_sequence::makeupReq(T_DISPATCH_REQ me);
  this.sck.forceRandomKnob_CtrlInfo(me.ctrl_info);
  this.sck.prob_gather_pkt = me.prob_gather_pkt;
  me.item = this.createItem(this.sck);
endfunction:makeupReq


task vqdmaif_h2c_transaction_dispatch_sequence::doOnService();
  this.reportMainEvent_body("START_DISPATCH_SEQ", $sformatf("Starting..... (sqr=%s)", this.m_sequencer.get_name), UVM_LOW);
  forever begin
    T_DISPATCH_REQ dispatch_req;
    wait(this.q_pending.size > 0);
    dispatch_req = this.q_pending.pop_front();
    begin
      automatic T_DISPATCH_REQ _dispatch_req = dispatch_req;
      automatic vqdmaif_h2c_master_sequence_item done_item;
      fork begin
        this.executeItem(_dispatch_req.item, done_item);
        _dispatch_req.item = done_item;
        _dispatch_req.makeDone();
      end join_none
    end
  end
endtask:doOnService



`endif // __VQDMAIF_H2C_TRANSACTION_DISPATCH_SEQUENCE_SVH__
