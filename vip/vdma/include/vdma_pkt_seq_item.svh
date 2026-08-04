`ifndef __VDMA_PKT_SEQ_ITEM_SVH__
`define __VDMA_PKT_SEQ_ITEM_SVH__



/*

*/


class vdma_pkt_seq_item#(parameter type T_SEQ_ITEM = vdma_seq_item) extends vmg_seq_item;

  localparam type T_TRANS = T_SEQ_ITEM;

  local static int num_created = 0;
  T_TRANS q_mst[$];
  
  // ---------------------------- Packet Information
  DmaId_t         pkt_dma_id;
  Addr_t          pkt_addr;
  Desc_t          desc;

  DmaTransType_t  trans_type = UNDEFINED_DmaTransType_t;
  DmaPktStatus_t  pkt_status = INVALID_PHASE;
  DmaTransPktGatheringStatusType_t pkt_gathering_info = UNDEFINED_PKT_GATHERING_STATUS;
  
  int             cdata_width;

  longint unsigned        num_planned_card_data = -1;
  longint unsigned        num_planned_host_data = -1;
  longint unsigned        cur_in_card_data = 0;
  longint unsigned        cur_in_host_data = 0;
  
  YesOrNo_t       need_intr           = NO;
  YesOrNo_t       need_status         = NO;
  YesOrNo_t       is_gathering        = NO;

  YesOrNo_t       has_last_mst       = NO;
  YesOrNo_t       has_last_cdata      = NO;
  YesOrNo_t       has_last_hdata      = NO;
  YesOrNo_t       has_complete_intr   = NO;
  YesOrNo_t       has_complete_status = NO;
  
  
  // ---------------------------- Scoreboard Data
  longint         expected_pkt_len = -1;
  longint         actual_pkt_len = 0;

  // ---------------------------- Fault cov
  OccuIntendedFault_t intended_faultType = -1;
  
  `uvm_object_utils(vdma_pkt_seq_item)
  function new (string name="vdma_pkt_seq_item");
    super.new(name);
    this.setID(this.num_created++);
  endfunction

  // ---------------------------- vmg_seq_item built-in
  extern virtual function YesOrNo_t isCompleted();



  // ---------------------------- vdma_pkt_seq_item built-in
  extern virtual function void updateByMst(T_TRANS trans, Len_t total_hburst_len, Len_t total_cburst_len);
  extern virtual function void updateByCardData(T_TRANS trans);
  
  extern virtual function void updateByIntr(T_TRANS trans);
  extern virtual function void updateByStatus(T_TRANS trans);
  
  extern virtual function void setCompletedByFault();
  
endclass:vdma_pkt_seq_item



function YesOrNo_t vdma_pkt_seq_item::isCompleted();
  if(this.has_last_mst && this.has_last_cdata && this.has_last_hdata) begin
    if((this.need_intr==this.has_complete_intr) && (this.need_status==this.has_complete_status))begin
      return(YES);
    end
  end
  else begin
    return(NO);
  end
endfunction:isCompleted



function void vdma_pkt_seq_item::updateByMst(T_TRANS trans, Len_t total_hburst_len, Len_t total_cburst_len);
  if( this.q_mst.size == 0 ) begin
    this.expected_pkt_len = trans.desc.len;
    this.num_planned_host_data = total_hburst_len;
    this.num_planned_card_data = total_cburst_len;
    this.pkt_status = ON_DESC_PHASE;
  end
  else begin
    this.expected_pkt_len += trans.desc.len;
    this.num_planned_host_data += total_hburst_len;
    this.num_planned_card_data += total_cburst_len;
  end
  
  this.q_mst.push_back(trans);
  
  if( (trans.getPktGatheringInfo() == NOT_ON_PKT_GATHERING) || (trans.getPktGatheringInfo() == END_OF_PKT_GATHERING) ) begin
    this.has_last_mst = YES;
    if (trans.getTransType() == ST_C2H || trans.getTransType() == ST_H2C) begin
      this.num_planned_card_data = this.expected_pkt_len/this.cdata_width;
      if(this.expected_pkt_len%this.cdata_width !=0) this.num_planned_card_data++;
      this.debug($sformatf("[UPDATE_BY_MST] num_planned_card_data=%0d, expected_pkt_len=%0d, cdata_width=%0d", this.num_planned_card_data, this.expected_pkt_len, this.cdata_width));
    end

    if(trans.desc.req_intr == 1) this.need_intr = YES;
    if(trans.desc.req_stat == 1) this.need_status = YES;
    
    this.is_gathering = NO;
  end
  else if( (trans.getPktGatheringInfo() == START_OF_PKT_GATHERING) ) begin
    this.is_gathering = YES;
  end
endfunction:updateByMst


function void vdma_pkt_seq_item::updateByCardData(T_TRANS trans);
  DataQ_t tmp_data_q;
  Data_t  tmp_data;
  
  foreach( trans.q_data[i] ) begin
    tmp_data = trans.q_data[i];
    tmp_data_q.push_back(tmp_data);
  end

  this.has_last_cdata = YES;
endfunction:updateByCardData




function void vdma_pkt_seq_item::updateByIntr(T_TRANS trans);
  Interrupt_t found_intr;
  YesOrNo_t   error;
  
  found_intr = trans.getInterrupt();
  
  case(this.trans_type)
    ST_H2C : error = this.has_last_cdata;
    ST_C2H : error = this.has_last_hdata;
    MM_H2C : error = this.has_last_cdata;
    MM_C2H : error = this.has_last_hdata;
    default : this.fatal("PKT_ITEM", "Unknown trans_type");
  endcase
  
  if( found_intr.vec_id == 'h1f ) begin
    this.fatalShallImpl("Need to implement FAULT interrupt on PKT_SEQ_ITEM");
  end
  else begin
    this.has_complete_intr = YES;
  end
endfunction:updateByIntr


function void vdma_pkt_seq_item::updateByStatus(T_TRANS trans);
  Status_t  found_status;
  YesOrNo_t error;
  
  found_status = trans.getStatus();
  
  case(this.trans_type)
    ST_H2C : error = this.has_last_cdata;
    ST_C2H : error = this.has_last_hdata;
    MM_H2C : error = this.has_last_cdata;
    MM_C2H : error = this.has_last_hdata;
    default : this.fatal("PKT_ITEM", "Unknown trans_type");
  endcase
  
  this.has_complete_status = YES;
endfunction : updateByStatus


function void vdma_pkt_seq_item::setCompletedByFault();
  this.need_intr = NO;
  this.need_status = NO;
  this.has_last_cdata = YES;
  this.has_last_hdata = YES;
  this.has_last_mst = YES;
endfunction:setCompletedByFault




`endif // __VDMA_PKT_SEQ_ITEM_SVH__
