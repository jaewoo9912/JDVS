`ifndef __VQDMAIF_C2H_TRANSACTION_DISPATCH_SEQUENCE_SVH__
`define __VQDMAIF_C2H_TRANSACTION_DISPATCH_SEQUENCE_SVH__



class vqdmaif_c2h_transaction_dispatch_request extends vbfm_transaction_dispatch_request;
  QdmaifDmaTransCtrlInfo_t ctrl_info=UNDEFINED_QDMAIF_DMA_CTRL_INFO;
  QdmaData_t data_value_list[];
  vqdmaif_c2h_master_sequence_item item;
  function new(string name="vqdmaif_c2h_transaction_dispatch_request");
    super.new(name);
  endfunction
  virtual function string getInfo();
    return($sformatf("%s ctrl_info=[%s]",
      super.getInfo,
      MakeString_QdmaifDmaTransCtrlInfo_t(this.ctrl_info)
    ));
  endfunction
  virtual function void finalize();
    int ref_num_data;
    if(this.ctrl_info == UNDEFINED_QDMAIF_DMA_CTRL_INFO)begin
      `vmg_fatal_wrong_usage(this.get_name, "finalize -- ctrl_info == UNDEFINED_QDMAIF_DMA_CTRL_INFO");
    end
    if(this.ctrl_info.len==0)begin
      ref_num_data=1;
    end
    else begin
      ref_num_data = this.ctrl_info.len/this.ctrl_info.DATA_SIZE;
      if(this.ctrl_info.len%this.ctrl_info.DATA_SIZE != 0) ref_num_data++;
    end
    if(ref_num_data != this.data_value_list.size)begin
      `vmg_fatal_wrong_usage(this.get_name, $sformatf("finalize -- ref_num_data(%1d) != data_value_list.size(%1d) len=%1d DATA_SIZE=%1d",
        ref_num_data, this.data_value_list.size, this.ctrl_info.len, this.ctrl_info.DATA_SIZE
      ));
    end
  endfunction:finalize
endclass:vqdmaif_c2h_transaction_dispatch_request



class vqdmaif_c2h_transaction_dispatch_sequence extends vqdmaif_c2h_master_random_sequence;
  typedef vqdmaif_c2h_transaction_dispatch_request T_DISPATCH_REQ;

  T_DISPATCH_REQ q_pending[$];
  `uvm_object_utils(vqdmaif_c2h_transaction_dispatch_sequence)
  function new(string name="vqdmaif_c2h_transaction_dispatch_sequence");
    super.new(name);
  endfunction
  extern virtual function void set_sequencer(uvm_sequencer_base sequencer);
  extern virtual task body();
  extern task executeTrans_SingleData(string trans_name, QdmaQId_t qid, QdmaAddr_t addr, QdmaLen_t len, QdmaPortId_t port_id, QdmaFunc_t func, QdmaData_t data_value, output T_DISPATCH_REQ dispatch_req);
  extern task executeTrans(string trans_name, QdmaQId_t qid, QdmaAddr_t addr, QdmaLen_t len, QdmaPortId_t port_id, QdmaFunc_t func, QdmaData_t data_value_list[], output T_DISPATCH_REQ dispatch_req);
  extern task executeTrans_RandomData(string trans_name, QdmaQId_t qid, QdmaAddr_t addr, QdmaLen_t len, QdmaPortId_t port_id, QdmaFunc_t func, output T_DISPATCH_REQ dispatch_req);
  extern function void pushReq(T_DISPATCH_REQ me);
  extern local function void makeupReq(T_DISPATCH_REQ me);
  extern local task doOnService();
endclass:vqdmaif_c2h_transaction_dispatch_sequence


task vqdmaif_c2h_transaction_dispatch_sequence::executeTrans_SingleData(string trans_name, QdmaQId_t qid, QdmaAddr_t addr, QdmaLen_t len, QdmaPortId_t port_id, QdmaFunc_t func, QdmaData_t data_value, output T_DISPATCH_REQ dispatch_req);
  QdmaData_t data_value_list[] = new[1];
  if(len > this.sck.DATA_SIZE) `vmg_fatal_wrong_usage("executeTrans_SingleData", $sformatf("len(%1d) > this.sck.DATA_SIZE(%1d)", len, this.sck.DATA_SIZE));
  data_value_list[0] = data_value;
  this.executeTrans(trans_name, qid, addr, len, port_id, func, data_value_list, dispatch_req);
endtask:executeTrans_SingleData

task vqdmaif_c2h_transaction_dispatch_sequence::executeTrans_RandomData(string trans_name, QdmaQId_t qid, QdmaAddr_t addr, QdmaLen_t len, QdmaPortId_t port_id, QdmaFunc_t func, output T_DISPATCH_REQ dispatch_req);
  QdmaData_t data_value_list[];
  int num_data;
  if(len == 0) num_data = 1;
  else         num_data = len/this.sck.DATA_SIZE; if(len%this.sck.DATA_SIZE != 0) num_data++;
  data_value_list = new[num_data];
  foreach(data_value_list[i])begin
    data_value_list[i] = std::randomize(data_value_list[i]) with { data_value_list[i] >= 0 && data_value_list[i] <= this.sck.max_data; };
  end
  this.executeTrans(trans_name, qid, addr, len, port_id, func, data_value_list, dispatch_req);
endtask:executeTrans_RandomData


task vqdmaif_c2h_transaction_dispatch_sequence::executeTrans(string trans_name, QdmaQId_t qid, QdmaAddr_t addr, QdmaLen_t len, QdmaPortId_t port_id, QdmaFunc_t func, QdmaData_t data_value_list[], output T_DISPATCH_REQ dispatch_req);
  dispatch_req = new(trans_name);
  dispatch_req.ctrl_info.protcl_type = QDMA_C2H_ST;
  dispatch_req.ctrl_info.DATA_SIZE = this.sck.DATA_SIZE;
  dispatch_req.ctrl_info.qid = qid;
  dispatch_req.ctrl_info.addr = addr;
  dispatch_req.ctrl_info.len = len;
  dispatch_req.ctrl_info.func = func;
  dispatch_req.ctrl_info.port_id = port_id;
  dispatch_req.data_value_list = data_value_list;
  this.pushReq(dispatch_req);
  dispatch_req.waitDone($sformatf("%s::executeTrans", this.get_name));
endtask:executeTrans

task vqdmaif_c2h_transaction_dispatch_sequence::body();
  fork
    this.doOnService();
  join
endtask:body

function void vqdmaif_c2h_transaction_dispatch_sequence::set_sequencer(uvm_sequencer_base sequencer);
  super.set_sequencer(sequencer);
  if(this.sck == null)begin
    this.sck = this.sqr.createSck($sformatf("%s.sck", this.get_name));
    this.sck.enterForcingMode();
  end
  this.sck.makeDirectTestable();
endfunction:set_sequencer

function void vqdmaif_c2h_transaction_dispatch_sequence::pushReq(T_DISPATCH_REQ me);
  this.makeupReq(me);
  this.q_pending.push_back(me);
endfunction:pushReq
  
function void vqdmaif_c2h_transaction_dispatch_sequence::makeupReq(T_DISPATCH_REQ me);
  me.finalize();
  this.sck.forceRandomKnob_CtrlInfo(me.ctrl_info);
  me.item = this.createItem(this.sck);
  foreach(me.item.trans.q_data_pl[i]) me.item.trans.q_data_pl[i].data = me.data_value_list[i];
endfunction:makeupReq


task vqdmaif_c2h_transaction_dispatch_sequence::doOnService();
  this.reportMainEvent_body("START_DISPATCH_SEQ", $sformatf("Starting..... (sqr=%s)", this.m_sequencer.get_name), UVM_LOW);
  forever begin
    T_DISPATCH_REQ dispatch_req;
    wait(this.q_pending.size > 0);
    dispatch_req = this.q_pending.pop_front();
    begin
      automatic T_DISPATCH_REQ _dispatch_req = dispatch_req;
      automatic vqdmaif_c2h_master_sequence_item done_item;
      fork begin
        this.executeItem(_dispatch_req.item, done_item);
        _dispatch_req.item = done_item;
        _dispatch_req.makeDone();
      end join_none
    end
  end
endtask:doOnService



`endif // __VQDMAIF_C2H_TRANSACTION_DISPATCH_SEQUENCE_SVH__
