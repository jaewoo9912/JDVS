`ifndef __VQDMAIF_C2H_TRANSACTION_SVH__
`define __VQDMAIF_C2H_TRANSACTION_SVH__

/*


  DESIGN_REPORT
    [2025/05/08] sungmin.hong
      Assumed that storeData is called first before storeCmd just for simple implementation


*/

class vqdmaif_c2h_transaction extends vqdmaif_dma_transaction;
  vqdmaif_c2h_cfg cfg;
  QdmaQId_t qid;
  QdmaC2HCmd_t cmd_pl;
  QdmaC2HData_t q_data_pl[$];
  QdmaC2HStatus_t status_pl = QdmaC2HDefaultStatus;
  //Sideband
  QdmaC2HCmdSideBand_t       cmd_sideband_pl;  
  QdmaC2HDataSideBand_t      q_data_sideband_pl[$];  
  QdmaC2HStatusSideBand_t    status_sideband_pl;  
  QdmaC2HInterruptSideBand_t interrupt_sideband_pl;
  QdmaLen_t remained_len;
  local int num_planned_data;

  local bit cmd_pl_stored, status_pl_stored, interrupt_sideband_pl_stored;
  bit first_data_pl_stored = 0;
   

  `uvm_object_utils_begin(vqdmaif_c2h_transaction)
    `uvm_field_int      (cmd_pl,                UVM_DEFAULT)
    `uvm_field_queue_int(q_data_pl,             UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_int      (status_pl,             UVM_DEFAULT)
    `uvm_field_int      (cmd_sideband_pl,       UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_queue_int(q_data_sideband_pl,    UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_int      (status_sideband_pl,    UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_int      (interrupt_sideband_pl, UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_object   (cfg,                   UVM_DEFAULT | UVM_NOCOMPARE)
  `uvm_object_utils_end
  function new (string name="vqdmaif_c2h_transaction");
    super.new(name);
  endfunction

  extern virtual function string getInfo();
  extern virtual function StringQ_t getInfoList();
  extern virtual function QdmaQId_t getQid();
  extern virtual function QdmaAddr_t getAddr();
  extern virtual function QdmaLen_t getLen();
  extern virtual function QdmaFunc_t getFunc();
  extern virtual function QdmaPortId_t getPortId();
  extern virtual protected function void makeupCtrlInfo();
  extern virtual function int getNumData();
  extern virtual function void getDataValue(int beat_idx, ref QdmaData_t data_value); 
  extern virtual function QdmaMty_t getMty(int beat_idx);
  extern function void storeCmd(ref QdmaC2HCmd_t me);
  extern function void storeData(ref QdmaC2HData_t me);
  extern function void storeStatus(ref QdmaC2HStatus_t me);
  extern function void getCmd(ref QdmaC2HCmd_t me);
  extern function void getData(int beat_idx, ref QdmaC2HData_t me); 
  extern function void getStatus(ref QdmaC2HStatus_t me);
  extern function void getInterruptSideband(ref QdmaC2HInterruptSideBand_t me);
  extern local function void setNumPlannedData(QdmaLen_t len);
  extern function int getNumPlannedData();
  extern function void storeCmdSideband(ref QdmaC2HCmdSideBand_t me);
  extern function void storeDataSideband(ref QdmaC2HDataSideBand_t me);
  extern function void storeStatusSideband(ref QdmaC2HStatusSideBand_t me);
  extern function void storeInterruptSideband(ref QdmaC2HInterruptSideBand_t me);
  extern function bit isNeedStatus();
  extern function bit isNeedInterruptSideband();
  extern function bit hasStatus();
  extern function bit hasInterruptSideband();
  extern virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
endclass:vqdmaif_c2h_transaction


function void vqdmaif_c2h_transaction::getCmd(ref QdmaC2HCmd_t me);
  if(!this.cmd_pl_stored) `vmg_fatal_wrong_usage(this.get_name, $sformatf("getCmd -- !cmd_pl_stored"));
  me = this.cmd_pl;
endfunction:getCmd

function void vqdmaif_c2h_transaction::getData(int beat_idx, ref QdmaC2HData_t me); 
  if(beat_idx > this.getNumData-1)begin
    `vmg_fatal_wrong_usage(this.get_name, $sformatf("getData -- out-of-bound beat_idx=%1d q_data_pl.size=%1d", beat_idx, this.q_data_pl.size));
  end
  me = this.q_data_pl[beat_idx];
endfunction:getData

function void vqdmaif_c2h_transaction::getStatus(ref QdmaC2HStatus_t me);
  if(!this.status_pl_stored) `vmg_fatal_wrong_usage(this.get_name, $sformatf("getStatus -- !status_pl_stored"));
  me = this.status_pl;
endfunction:getStatus

function void vqdmaif_c2h_transaction::getInterruptSideband(ref QdmaC2HInterruptSideBand_t me);
  if(!this.interrupt_sideband_pl_stored) `vmg_fatal_wrong_usage(this.get_name, $sformatf("getInterruptSideband -- !interrupt_sideband_pl_stored"));
  me = this.interrupt_sideband_pl;
endfunction : getInterruptSideband


function int vqdmaif_c2h_transaction::getNumData(); return(this.q_data_pl.size); endfunction

function string vqdmaif_c2h_transaction::getInfo();
  return($sformatf("%s DMA_TYPE=%s #data=%1d", super.getInfo, this.cfg.dma_type, this.q_data_pl.size));
endfunction

function StringQ_t vqdmaif_c2h_transaction::getInfoList();
  StringQ_t result = super.getInfoList();
  result.push_back($sformatf("[CMD] %s", MakeString_QdmaC2HCmd_t(this.cmd_pl)));
  result.push_back($sformatf("--------------------------------------------"));
  result.push_back($sformatf("[DATA] Has %1d transfer(s)", this.q_data_pl.size));
  foreach(this.q_data_pl[i]) result.push_back($sformatf("   - DATA#%1d %s", i, MakeString_QdmaC2HData_t(this.q_data_pl[i])));
  result.push_back($sformatf("--------------------------------------------"));
  result.push_back($sformatf("[STATUS] %s", MakeString_QdmaC2HStatus_t(this.status_pl)));
  return(result);
endfunction:getInfoList

function QdmaQId_t vqdmaif_c2h_transaction::getQid();
  if(this.q_data_pl.size == 0) `vmg_fatal_wrong_usage(this.get_name, $sformatf("getQid -- q_data_pl.size == 0"));
  return(this.q_data_pl[0].qid);
endfunction:getQid

function QdmaAddr_t   vqdmaif_c2h_transaction::getAddr();     return(this.cmd_pl.addr);    endfunction
function QdmaLen_t    vqdmaif_c2h_transaction::getLen();      return(this.q_data_pl[0].len); endfunction
function QdmaFunc_t   vqdmaif_c2h_transaction::getFunc();     return(this.cmd_pl.func);    endfunction 
function QdmaPortId_t vqdmaif_c2h_transaction:: getPortId();  return(this.cmd_pl.port_id); endfunction

function void vqdmaif_c2h_transaction::makeupCtrlInfo();
  if(this.cfg == null) `vmg_fatal_wrong_usage(this.get_name, $sformatf("makeupCtrlInfo -- this.cfg == null"));
  if(this.cfg.dma_type == UNDEFINED_DMA) `vmg_fatal_wrong_usage(this.get_name, $sformatf("makeupCtrlInfo -- DMA_TYPE == UNDEFINED_TYPE"));
  if(this.q_data_pl.size == 0) `vmg_fatal_wrong_usage(this.get_name, $sformatf("makeupCtrlInfo -- q_data_pl.size == 0"));
  this.ctrl_info.protcl_type = QDMA_C2H_ST;
  this.ctrl_info.DATA_SIZE = this.cfg.DATA_SIZE;
  this.ctrl_info.qid = this.q_data_pl[0].qid;
  this.ctrl_info.fid = this.q_data_sideband_pl[0].fid;
  this.ctrl_info.addr = this.cmd_pl.addr;
  this.ctrl_info.len = this.q_data_pl[0].len;
  this.ctrl_info.func = this.cmd_pl.func;
  this.ctrl_info.port_id = this.cmd_pl.port_id;
endfunction:makeupCtrlInfo

function void vqdmaif_c2h_transaction::getDataValue(int beat_idx, ref QdmaData_t data_value); 
  if(beat_idx > this.q_data_pl.size-1)begin
    `vmg_fatal_wrong_usage(this.get_name, $sformatf("getDataValue -- out-of-bound beat_idx=%1d q_data_pl.size=%1d", beat_idx, this.q_data_pl.size));
  end
  data_value = this.q_data_pl[beat_idx].data;
endfunction:getDataValue


function QdmaMty_t vqdmaif_c2h_transaction::getMty(int beat_idx);
  if(beat_idx > this.q_data_pl.size-1)begin
    `vmg_fatal_wrong_usage(this.get_name, $sformatf("getMty -- out-of-bound beat_idx=%1d q_data_pl.size=%1d", beat_idx, this.q_data_pl.size));
  end
  return(this.q_data_pl[beat_idx].mty);
endfunction:getMty

function void vqdmaif_c2h_transaction::storeData(ref QdmaC2HData_t me);
  if(!this.first_data_pl_stored) begin
    this.setNumPlannedData(me.len);
    this.first_data_pl_stored = 1;
  end
  this.num_planned_data--;
  if(this.num_planned_data == 0) this.remained_len = this.cfg.DATA_SIZE - me.mty;

  this.qid = me.qid;
  this.q_data_pl.push_back(me);
  if(me.last && this.cmd_pl_stored)begin
    this.makeupDataInfo();
    this.dcntnr.set_command(UVM_TLM_WRITE_COMMAND);
    if(this.cfg.dma_type == MBDMA)begin
      if(!this.cmd_sideband_pl.req_intr && !this.cmd_sideband_pl.req_stat) this.makeDone();
    end
  end
endfunction:storeData

function void vqdmaif_c2h_transaction::storeCmd(ref QdmaC2HCmd_t me);
  if(this.q_data_pl.size == 0) `vmg_fatal_wrong_usage(this.get_name, $sformatf("storeCmd -- You should \"storeData\" first!!"));
  this.cmd_pl = me;
  this.cmd_pl_stored = 1;
  this.qid = this.cmd_pl.qid;
  this.makeupCtrlInfo();
  if(this.q_data_pl[$].last)begin
    this.makeupDataInfo();
    this.dcntnr.set_command(UVM_TLM_WRITE_COMMAND);
    if(this.cfg.dma_type == MBDMA)begin
      if(!this.cmd_sideband_pl.req_intr && !this.cmd_sideband_pl.req_stat) this.makeDone();
    end
  end
endfunction:storeCmd

function void vqdmaif_c2h_transaction::storeStatus(ref QdmaC2HStatus_t me);
  this.status_pl = me;
  this.status_pl_stored = 1;

  if(this.cfg.dma_type == MBDMA)begin
    if(!this.cmd_sideband_pl.req_intr || this.interrupt_sideband_pl_stored) this.makeDone();
  end
  else begin
    this.makeDone();
  end
endfunction:storeStatus


function void vqdmaif_c2h_transaction::storeCmdSideband(ref QdmaC2HCmdSideBand_t me);
  this.cmd_sideband_pl = me;
endfunction : storeCmdSideband

function void vqdmaif_c2h_transaction::storeDataSideband(ref QdmaC2HDataSideBand_t me);
  this.q_data_sideband_pl.push_back(me);
endfunction : storeDataSideband

function void vqdmaif_c2h_transaction::storeStatusSideband(ref QdmaC2HStatusSideBand_t me);
  this.status_sideband_pl = me;
endfunction : storeStatusSideband

function void vqdmaif_c2h_transaction::storeInterruptSideband(ref QdmaC2HInterruptSideBand_t me);
  if(this.cfg.dma_type == QDMA) `vmg_fatal_wrong_usage("[PROTOCOL_VIOLATION]", $sformatf("QDMA does not support Interrupt-Sideband signal"))
  this.interrupt_sideband_pl = me;
  this.interrupt_sideband_pl_stored = 1;
  
  if(!this.cmd_sideband_pl.req_stat || this.status_pl_stored) this.makeDone();
endfunction : storeInterruptSideband

function bit vqdmaif_c2h_transaction::isNeedStatus();            return(this.cmd_sideband_pl.req_stat); endfunction : isNeedStatus
function bit vqdmaif_c2h_transaction::isNeedInterruptSideband(); return(this.cmd_sideband_pl.req_intr); endfunction : isNeedInterruptSideband

function bit vqdmaif_c2h_transaction::hasStatus();            return(this.status_pl_stored); endfunction : hasStatus
function bit vqdmaif_c2h_transaction::hasInterruptSideband(); return(this.interrupt_sideband_pl_stored); endfunction : hasInterruptSideband


function void vqdmaif_c2h_transaction::setNumPlannedData(QdmaLen_t len);
  this.num_planned_data = len / this.cfg.DATA_SIZE;
  if(len % this.cfg.DATA_SIZE != 0) this.num_planned_data++;
endfunction : setNumPlannedData


function int vqdmaif_c2h_transaction::getNumPlannedData(); return(this.num_planned_data); endfunction : getNumPlannedData

function bit vqdmaif_c2h_transaction::do_compare(uvm_object rhs, uvm_comparer comparer);
  vqdmaif_c2h_transaction tmp;
  if(!super.do_compare(rhs, comparer)) return 0;

  $cast(tmp, rhs);
  
  if (this.qid != tmp.qid) begin
    `uvm_info("MISCMP", $sformatf("Mismatch in qid: lhs = %0x, rhs = %0x", this.qid, tmp.qid), UVM_LOW)
    return 0;
  end

  if (this.dcntnr.m_data.size() != tmp.dcntnr.m_data.size()) begin
    `uvm_info("MISCMP", $sformatf("Mismatch in q_data_pl size: lhs = %0d, rhs = %0d", this.q_data_pl.size(), tmp.q_data_pl.size()), UVM_LOW)
    return 0;
  end 
  else begin
    foreach(this.dcntnr.m_data[i]) begin
      if(this.dcntnr.m_data[i] != tmp.dcntnr.m_data[i]) begin
        `uvm_info("MISCMP", $sformatf("Mismatch in q_data_pl[%0d]: lhs = %0d, rhs = %0d", i, this.dcntnr.m_data[i], tmp.dcntnr.m_data[i]), UVM_LOW)
        return 0;
      end
    end
  end

  if(this.cfg.dma_type == QDMA) begin
    if (this.cmd_sideband_pl.fid !== tmp.cmd_sideband_pl.fid) begin
      `uvm_info("MISCMP", $sformatf("Mismatch in cmd_sideband_pl: lhs = %0h, rhs = %0h", this.cmd_sideband_pl, tmp.cmd_sideband_pl), UVM_LOW)
      return 0;
    end
    //fid connection in C2H data ch can be omitted
    //if (this.q_data_sideband_pl[0].fid !== tmp.q_data_sideband_pl[0].fid) begin
    //  `uvm_info("MISCMP", $sformatf("Mismatch in q_data_sideband_pl[%0d]: lhs = %0h, rhs = %0h", 0, this.q_data_sideband_pl[0], tmp.q_data_sideband_pl[0]), UVM_LOW)
    //  return 0;
    //end
    if (this.status_sideband_pl.fid !== tmp.status_sideband_pl.fid) begin
      `uvm_info("MISCMP", $sformatf("Mismatch in status_sideband_pl: lhs = %0h, rhs = %0h", this.status_sideband_pl, tmp.status_sideband_pl), UVM_LOW)
      return 0;
    end
  end

  return 1;
endfunction : do_compare


`endif // __VQDMAIF_C2H_TRANSACTION_SVH__
