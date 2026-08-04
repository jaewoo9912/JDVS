`ifndef __VQDMAIF_H2C_SUB_TRANSACTION_SVH__
`define __VQDMAIF_H2C_SUB_TRANSACTION_SVH__

/*

   Indicates a CMD/DATA transaction
   (ex] gather pkt transactions consist of multiple sub transactions)


*/


class vqdmaif_h2c_sub_transaction extends vqdmaif_dma_transaction;
  vqdmaif_h2c_cfg cfg;
  QdmaH2CCmd_t cmd_pl;
  QdmaH2CCmdSideBand_t cmd_sideband_pl;
  QdmaQId_t qid;
  ByteQ_t bytestream;

  local bit cmd_pl_stored;

  `uvm_object_utils_begin(vqdmaif_h2c_sub_transaction)
    `uvm_field_int    (cmd_pl,          UVM_ALL_ON)
    `uvm_field_int    (cmd_sideband_pl, UVM_ALL_ON)
    `uvm_field_object (cfg,             UVM_DEFAULT | UVM_NOCOMPARE)
  `uvm_object_utils_end
  function new (string name="vqdmaif_h2c_sub_transaction");
    super.new(name);
  endfunction

  extern virtual function string getInfo();
  extern virtual function StringQ_t getInfoList();
  extern virtual function QdmaQId_t getQid();
  extern virtual function QdmaAddr_t getAddr();
  extern virtual function QdmaLen_t getLen();
  extern virtual function QdmaFunc_t getFunc();
  extern virtual function QdmaPortId_t getPortId();
  extern virtual function logic getSop();
  extern virtual function logic getEop();
  extern virtual function logic getNoDma();
  extern virtual function void makeupCtrlInfo();
  extern function void storeCmd(ref QdmaH2CCmd_t me);
  extern function void getCmd(ref QdmaH2CCmd_t me);
  extern function void storeCmdSideband(ref QdmaH2CCmdSideBand_t me);
  extern virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
endclass:vqdmaif_h2c_sub_transaction



function void vqdmaif_h2c_sub_transaction::getCmd(ref QdmaH2CCmd_t me);
  if(!this.cmd_pl_stored) `vmg_fatal_wrong_usage(this.get_name, $sformatf("getCmd -- !cmd_pl_stored"));
  me = this.cmd_pl;
endfunction:getCmd

function string vqdmaif_h2c_sub_transaction::getInfo();
  return($sformatf("%s bytestream=%1d bytes", super.getInfo, this.bytestream.size));
endfunction

function StringQ_t vqdmaif_h2c_sub_transaction::getInfoList();
  StringQ_t result = super.getInfoList();
  result.push_back($sformatf("[CMD] %s", MakeString_QdmaH2CCmd_t(this.cmd_pl)));
  return(result);
endfunction:getInfoList

function QdmaQId_t    vqdmaif_h2c_sub_transaction::getQid();     return(this.cmd_pl.qid);     endfunction
function QdmaAddr_t   vqdmaif_h2c_sub_transaction::getAddr();    return(this.cmd_pl.addr);    endfunction
function QdmaLen_t    vqdmaif_h2c_sub_transaction::getLen();     return(this.cmd_pl.len);     endfunction
function QdmaFunc_t   vqdmaif_h2c_sub_transaction::getFunc();    return(this.cmd_pl.func);    endfunction
function QdmaPortId_t vqdmaif_h2c_sub_transaction::getPortId();  return(this.cmd_pl.port_id); endfunction
function logic        vqdmaif_h2c_sub_transaction::getSop();     return(this.cmd_pl.sop);     endfunction
function logic        vqdmaif_h2c_sub_transaction::getEop();     return(this.cmd_pl.eop);     endfunction
function logic        vqdmaif_h2c_sub_transaction::getNoDma();   return(this.cmd_pl.no_dma);  endfunction

function void vqdmaif_h2c_sub_transaction::makeupCtrlInfo();
  if(this.cfg == null) `vmg_fatal_wrong_usage(this.get_name, $sformatf("makeupCtrlInfo -- cfg == null"));
  if(this.cfg.dma_type == UNDEFINED_DMA) `vmg_fatal_wrong_usage(this.get_name, $sformatf("makeupCtrlInfo -- DMA_TYPE == UNDEFINED_DMA"));
  this.ctrl_info.protcl_type = QDMA_H2C_ST;
  this.ctrl_info.DATA_SIZE = this.cfg.DATA_SIZE;
  this.ctrl_info.qid = this.cmd_pl.qid;
  this.ctrl_info.fid = this.cmd_sideband_pl.fid;
  this.ctrl_info.addr = this.cmd_pl.addr;
  this.ctrl_info.len = this.cmd_pl.len;
  this.ctrl_info.func = this.cmd_pl.func;
  this.ctrl_info.port_id = this.cmd_pl.port_id;
endfunction:makeupCtrlInfo

function void vqdmaif_h2c_sub_transaction::storeCmd(ref QdmaH2CCmd_t me);
  this.cmd_pl = me;
  this.qid = this.cmd_pl.qid;
  this.cmd_pl_stored = 1;
  this.makeupCtrlInfo();
endfunction:storeCmd


function void vqdmaif_h2c_sub_transaction::storeCmdSideband(ref QdmaH2CCmdSideBand_t me);
  this.cmd_sideband_pl = me;  
endfunction : storeCmdSideband

function bit vqdmaif_h2c_sub_transaction::do_compare(uvm_object rhs, uvm_comparer comparer);
  vqdmaif_h2c_sub_transaction tmp;

  $cast(tmp, rhs);

  if (this.cmd_pl !== tmp.cmd_pl) begin
    `uvm_info("MISCMP", $sformatf("Mismatch in cmd_pl: lhs = %0h, rhs = %0h", this.cmd_pl, tmp.cmd_pl), UVM_LOW)
    return 0;
  end

  if (this.cmd_sideband_pl !== tmp.cmd_sideband_pl) begin
    `uvm_info("MISCMP", $sformatf("Mismatch in cmd_sideband_pl: lhs = %0h, rhs = %0h", this.cmd_sideband_pl, tmp.cmd_sideband_pl), UVM_LOW)
    return 0;
  end

  return 1;
endfunction : do_compare







`endif // __VQDMAIF_H2C_SUB_TRANSACTION_SVH__
