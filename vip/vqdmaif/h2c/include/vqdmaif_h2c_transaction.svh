`ifndef __VQDMAIF_H2C_TRANSACTION_SVH__
`define __VQDMAIF_H2C_TRANSACTION_SVH__


class vqdmaif_h2c_transaction extends vqdmaif_dma_transaction;
  typedef QdmaH2CCmd_t T_CMD_PL;
  QdmaQId_t qid;
  protected QdmaH2CData_t q_data_pl[$];

  QdmaH2CDataSideBand_t q_data_sideband_pl[$];
  QdmaH2CStatusSideBand_t status_sideband_pl;
  QdmaH2CInterruptSideBand_t interrupt_sideband_pl;

  vqdmaif_h2c_cfg cfg;
  vqdmaif_h2c_sub_transaction q_sub[$];
  bit pkt_lv_cmd_rdy=0;
	logic[63:0] remained_len = 0;

  local bit data_pl_stored;
  local bit status_sideband_pl_stored, interrupt_sideband_pl_stored;

  bit has_status_sideband = NO;
  bit has_interrupt_sideband = NO;

  bit ref_last_data_pl_stored = 0;
  int num_planned_data = -1, num_stored_data = 0;

  `uvm_object_utils_begin(vqdmaif_h2c_transaction)
    `uvm_field_int         (pkt_lv_cmd_rdy,         UVM_ALL_ON)
    `uvm_field_queue_object(q_sub,                  UVM_ALL_ON)
    `uvm_field_queue_int   (q_data_pl,              UVM_ALL_ON)
    `uvm_field_int         (status_sideband_pl,     UVM_ALL_ON)
    `uvm_field_int         (interrupt_sideband_pl,  UVM_ALL_ON)
    `uvm_field_object      (cfg,                    UVM_ALL_ON | UVM_NOCOMPARE)
  `uvm_object_utils_end
  function new (string name="vqdmaif_h2c_transaction");
    super.new(name);
  endfunction

  extern virtual function string getInfo();
  extern virtual function StringQ_t getInfoList();
  extern virtual function QdmaQId_t getQid();
  extern virtual function QdmaAddr_t getAddr();
  extern virtual function QdmaLen_t getLen();
  extern function logic[63:0] getTotalLen();
  extern virtual function QdmaFunc_t getFunc();
  extern virtual function QdmaPortId_t getPortId();
  extern virtual function logic getNoDma();
  extern function void addSubTrans(vqdmaif_h2c_sub_transaction me);
  extern virtual protected function void makeupCtrlInfo();
  extern virtual function void getData(int beat_idx, ref QdmaH2CData_t me);
  extern virtual function int getNumData();
  extern virtual function void getDataValue(int beat_idx, ref QdmaData_t data_value); 
  extern virtual function QdmaMty_t getMty(int beat_idx);
  extern function bit isPktLvCmdRdy();
  extern function void storeData(ref QdmaH2CData_t me);
  extern function void storeDataSideband(ref QdmaH2CDataSideBand_t me);
  extern function void storeStatusSideband(ref QdmaH2CStatusSideBand_t me);
  extern function void storeInterruptSideband(ref QdmaH2CInterruptSideBand_t me);
  extern virtual function void getDataSideband(int beat_idx, ref QdmaH2CDataSideBand_t me);
  extern virtual function void getStatusSideband(ref QdmaH2CStatusSideBand_t me);
  extern virtual function void getInterruptSideband(ref QdmaH2CInterruptSideBand_t me);
  extern function bit isNeedStatusSideband();
  extern function bit isNeedInterruptSideband();
  extern function bit isDataPlStored();
  extern function bit hasStatusSideband();
  extern function bit hasInterruptSideband();
  extern virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
  extern virtual function byte getByteData(int beat_idx, int byte_offset);
  extern virtual function QdmaAddr_t getByteAddr(int beat_idx, int byte_offset);
  extern virtual function void makeDone();
  extern local function void setNumPlannedData(logic[63:0] len);
  extern function bit isLastDataPlStored();
endclass:vqdmaif_h2c_transaction

function byte vqdmaif_h2c_transaction::getByteData(int beat_idx, int byte_offset);
  byte byte_data;
  QdmaData_t data_value;
  HostAddr_t addr_offset;
  HostAddr_t curr_total_sub_len=0;
  HostAddr_t prev_total_sub_len=0;

  this.getDataValue(beat_idx, data_value);
  byte_data = data_value[byte_offset*8+:8];
  return(byte_data);
endfunction : getByteData

function QdmaAddr_t vqdmaif_h2c_transaction::getByteAddr(int beat_idx, int byte_offset);
  HostAddr_t addr_offset;
  HostAddr_t curr_addr;
  HostAddr_t curr_total_sub_len=0;
  HostAddr_t prev_total_sub_len=0;

  int sub_idx=0;
  addr_offset = beat_idx * this.cfg.DATA_SIZE + byte_offset;

  foreach(this.q_sub[i]) begin
    curr_total_sub_len += this.q_sub[i].getLen();
    if(addr_offset < curr_total_sub_len) begin
      sub_idx = i;
      break;
    end
  end
  prev_total_sub_len = curr_total_sub_len - this.q_sub[sub_idx].getLen();
  
  curr_addr = this.q_sub[sub_idx].getAddr() + addr_offset - prev_total_sub_len;
  return(curr_addr);
endfunction : getByteAddr

function void vqdmaif_h2c_transaction::makeDone();
  super.makeDone();
  foreach(this.q_sub[i]) begin
    this.q_sub[i].makeDone();
  end   
endfunction : makeDone

function bit vqdmaif_h2c_transaction::isPktLvCmdRdy(); return(this.pkt_lv_cmd_rdy); endfunction

function void vqdmaif_h2c_transaction::storeData(ref QdmaH2CData_t me);
  this.q_data_pl.push_back(me); 
	this.remained_len -= (this.cfg.DATA_SIZE-me.mty);
  this.num_stored_data++;
  if(this.num_planned_data == this.num_stored_data) this.ref_last_data_pl_stored = 1;
  if(me.last) begin
    this.data_pl_stored = 1;
    this.makeupDataInfo();
    this.dcntnr.set_command(UVM_TLM_READ_COMMAND);
    if(this.cfg.dma_type == MBDMA) begin
      if(!this.isNeedStatusSideband && !this.isNeedInterruptSideband) this.makeDone();
    end
    else begin
      this.makeDone();
    end
  end
endfunction:storeData

function string vqdmaif_h2c_transaction::getInfo();
  return($sformatf("%s pkt_lv_cmd_rdy=%1d #core_trans=%1d, no_dma=%1d", super.getInfo, this.pkt_lv_cmd_rdy, this.q_sub.size, this.getNoDma));
endfunction

function StringQ_t vqdmaif_h2c_transaction::getInfoList();
  StringQ_t result = super.getInfoList();
  foreach(this.q_sub[i]) result = AppendStringList(result, this.q_sub[i].getInfoList, $sformatf("sub_trans#%-3d", i));
  return(result);
endfunction:getInfoList

function QdmaQId_t    vqdmaif_h2c_transaction::getQid();       return(this.q_sub[0].getQid);    endfunction
function QdmaAddr_t   vqdmaif_h2c_transaction::getAddr();      return(this.q_sub[0].getAddr);   endfunction
function QdmaLen_t    vqdmaif_h2c_transaction::getLen();       return(this.ctrl_info.len);      endfunction // In gathering mode, do not use !! data_len > 16 bits -- overflow occur | Use getTotalLen instead
function logic[63:0]  vqdmaif_h2c_transaction::getTotalLen();  return(this.ctrl_info.len);      endfunction
function QdmaFunc_t   vqdmaif_h2c_transaction::getFunc();      return(this.q_sub[0].getFunc);   endfunction
function QdmaPortId_t vqdmaif_h2c_transaction::getPortId();    return(this.q_sub[0].getPortId); endfunction

function void vqdmaif_h2c_transaction::makeupCtrlInfo();
  if(this.q_sub.size == 0) `vmg_fatal_wrong_usage(this.get_name, $sformatf("makeupCtrlInfo -- q_sub.size == 0"));
  this.ctrl_info = this.q_sub[0].ctrl_info;
  this.ctrl_info.len = 0;
  foreach(this.q_sub[i])begin
    this.ctrl_info.len += this.q_sub[i].ctrl_info.len;
  end
endfunction:makeupCtrlInfo


function void vqdmaif_h2c_transaction::getData(int beat_idx, ref QdmaH2CData_t me); 
  if(beat_idx > this.getNumData-1)begin
    `vmg_fatal_wrong_usage(this.get_name, $sformatf("getData -- out-of-bound beat_idx=%1d q_data_pl.size=%1d", beat_idx, this.q_data_pl.size));
  end
  me = this.q_data_pl[beat_idx];
endfunction:getData

function int vqdmaif_h2c_transaction::getNumData(); return(this.q_data_pl.size); endfunction

function void vqdmaif_h2c_transaction::getDataValue(int beat_idx, ref QdmaData_t data_value); 
  if(beat_idx > this.q_data_pl.size-1)begin
    `vmg_fatal_wrong_usage(this.get_name, $sformatf("getDataValue -- out-of-bound beat_idx=%1d q_data_pl.size=%1d", beat_idx, this.q_data_pl.size));
  end
  data_value = this.q_data_pl[beat_idx].data;
endfunction:getDataValue

function QdmaMty_t vqdmaif_h2c_transaction::getMty(int beat_idx);
  if(beat_idx > this.q_data_pl.size-1)begin
    `vmg_fatal_wrong_usage(this.get_name, $sformatf("getMty -- out-of-bound beat_idx=%1d q_data_pl.size=%1d", beat_idx, this.q_data_pl.size));
  end
  return(this.q_data_pl[beat_idx].mty);
endfunction:getMty

function void vqdmaif_h2c_transaction::addSubTrans(vqdmaif_h2c_sub_transaction me);
  T_CMD_PL cmd_pl;
  me.setName($sformatf("%s(sub#%1d(obj#%1d))", this.get_name, this.q_sub.size, me.getObjId));
  me.getCmd(cmd_pl);
  this.qid = cmd_pl.qid;
  this.q_sub.push_back(me);
  this.remained_len += me.getLen;
  if(cmd_pl.eop == 1)begin
    this.makeupCtrlInfo();
    this.pkt_lv_cmd_rdy = 1;
    this.setNumPlannedData(this.ctrl_info.len);
    if(cmd_pl.no_dma == 1) this.makeDone;
  end
endfunction:addSubTrans


function void vqdmaif_h2c_transaction::storeDataSideband(ref QdmaH2CDataSideBand_t me);
  this.q_data_sideband_pl.push_back(me);    
endfunction : storeDataSideband


function void vqdmaif_h2c_transaction::storeStatusSideband(ref QdmaH2CStatusSideBand_t me);
  if(this.cfg.dma_type == QDMA) `vmg_fatal("PROTOCOL_VIOLATION", $sformatf("QDMA does not support status-related sideband signal -- storeStatusSideband"))
  if(!this.data_pl_stored)      `vmg_fatal("PROTOCOL_VIOLATION", $sformatf("Status Sideband detected before data completion -- data_pl_stored=%1d", this.data_pl_stored));

  this.status_sideband_pl = me;
  this.status_sideband_pl_stored = 1;  

  if(!this.q_sub[$].cmd_sideband_pl.req_intr || this.interrupt_sideband_pl_stored) this.makeDone();
endfunction : storeStatusSideband


function void vqdmaif_h2c_transaction::storeInterruptSideband(ref QdmaH2CInterruptSideBand_t me);
  if(this.cfg.dma_type == QDMA) `vmg_fatal("PROTOCOL_VIOLATION", $sformatf("QDMA does not support interrupt-related sideband signal -- storeInterruptSideband"))
  if(!this.data_pl_stored)      `vmg_fatal("PROTOCOL_VIOLATION", $sformatf("Interrupt Sideband detected before data completion -- data_pl_stored=%1d", this.data_pl_stored));

  this.interrupt_sideband_pl = me;
  this.interrupt_sideband_pl_stored = 1;

  if(!this.q_sub[$].cmd_sideband_pl.req_stat || this.status_sideband_pl_stored) this.makeDone();
endfunction : storeInterruptSideband


function void vqdmaif_h2c_transaction::getDataSideband(int beat_idx, ref QdmaH2CDataSideBand_t me);
  if(beat_idx > this.getNumData-1)begin
    `vmg_fatal_wrong_usage(this.get_name, $sformatf("getDataSideband -- out-of-bound beat_idx=%1d q_data_pl.size=%1d", beat_idx, this.q_data_pl.size));
  end
  me = this.q_data_sideband_pl[beat_idx];
endfunction : getDataSideband

function void vqdmaif_h2c_transaction::getStatusSideband(ref QdmaH2CStatusSideBand_t me);
  if(!this.status_sideband_pl_stored) `vmg_fatal_wrong_usage(this.get_name, $sformatf("getStatusSideband -- !status_sideband_pl_stored"));
  me = this.status_sideband_pl;
endfunction : getStatusSideband

function void vqdmaif_h2c_transaction::getInterruptSideband(ref QdmaH2CInterruptSideBand_t me);
  if(!this.interrupt_sideband_pl_stored) `vmg_fatal_wrong_usage(this.get_name, $sformatf("getInterruptSideband -- !interrupt_sideband_pl_stored"));
endfunction : getInterruptSideband


function bit vqdmaif_h2c_transaction::isNeedStatusSideband();
  return(this.q_sub[$].cmd_sideband_pl.req_stat);
endfunction : isNeedStatusSideband

function bit vqdmaif_h2c_transaction::isNeedInterruptSideband();
  return(this.q_sub[$].cmd_sideband_pl.req_intr);
endfunction : isNeedInterruptSideband


function bit vqdmaif_h2c_transaction::isDataPlStored();
  return(this.data_pl_stored);
endfunction : isDataPlStored

function bit vqdmaif_h2c_transaction::do_compare(uvm_object rhs, uvm_comparer comparer);
  vqdmaif_h2c_transaction tmp;
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
  
  if (this.q_data_sideband_pl[0] !== tmp.q_data_sideband_pl[0]) begin
    `uvm_info("MISCMP", $sformatf("Mismatch in q_data_sideband_pl[%0d]: lhs = %0h, rhs = %0h", 0, this.q_data_sideband_pl[0], tmp.q_data_sideband_pl[0]), UVM_LOW)
    return 0;
  end

  return 1;
endfunction : do_compare


function void vqdmaif_h2c_transaction::setNumPlannedData(logic[63:0] len);
  this.num_planned_data = len / this.cfg.DATA_SIZE;
  if(len % this.cfg.DATA_SIZE != 0) this.num_planned_data++;
endfunction : setNumPlannedData


function bit vqdmaif_h2c_transaction::isLastDataPlStored(); return(this.ref_last_data_pl_stored); endfunction : isLastDataPlStored


function logic vqdmaif_h2c_transaction::getNoDma(); return(this.q_sub[0].getNoDma); endfunction : getNoDma



function bit vqdmaif_h2c_transaction::hasStatusSideband();    return(this.status_sideband_pl_stored);    endfunction : hasStatusSideband
function bit vqdmaif_h2c_transaction::hasInterruptSideband(); return(this.interrupt_sideband_pl_stored); endfunction : hasInterruptSideband




`endif // __VQDMAIF_H2C_TRANSACTION_SVH__
