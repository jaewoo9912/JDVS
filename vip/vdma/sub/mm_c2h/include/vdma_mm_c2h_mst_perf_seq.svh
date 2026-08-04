`ifndef __VDMA_MM_C2H_MST_PERF_SEQ_SVH__
`define __VDMA_MM_C2H_MST_PERF_SEQ_SVH__



class vdma_mm_c2h_mst_perf_seq extends vdma_mm_c2h_mst_seq;

  int   cnt_addr = 0;
  Len_t len;
  
  `uvm_object_utils(vdma_mm_c2h_mst_perf_seq)

  function new (string name="vdma_mm_c2h_mst_perf_seq");
     super.new(name);
     this.watchdog_cycle = 400000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  extern virtual protected function SeqItem_t createSeqItem(string name_postfix="");
  extern virtual function SeqItem_t post_createSeqItem(SeqItem_t me);
  
  extern virtual function Addr_t decideCstrAddr();
  extern virtual function Len_t decideCstrLen();
  extern virtual function FncId_t decideCstrMaxBL();
  
  extern local function Addr_t make64BAlignedAddr();
endclass:vdma_mm_c2h_mst_perf_seq


function void vdma_mm_c2h_mst_perf_seq::genCfg();
  // #PKT is randomized within the below values
  // At least num_item is over 1
  if(this.tcfg.perf_ctrl_knob.perf_crossing == NO) begin
    this.num_item_start = PERF_REASONABLE_LEN / 64;
    this.num_item_end   = PERF_REASONABLE_LEN / 64;
  end
  else begin
    this.num_item_start = PERF_REASONABLE_LEN / this.tcfg.perf_ctrl_knob.perf_c2h_len_in_byte;
    this.num_item_end   = PERF_REASONABLE_LEN / this.tcfg.perf_ctrl_knob.perf_c2h_len_in_byte;
  end
  
  super.genCfg();
endfunction:genCfg



task vdma_mm_c2h_mst_perf_seq::pre_genCfg();
  // data size per desc (len_in_byte) is randomized within the below values
  // Based on vmg_rgs
  this.max_dma_size = MAX_DMA_LEN;
  this.min_dma_size = 1;
  this.preset_dma_size = this.max_dma_size;
  this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;
  
  super.pre_genCfg();
endtask:pre_genCfg



function vdma_mm_c2h_mst_perf_seq::FncId_t vdma_mm_c2h_mst_perf_seq::decideCstrMaxBL();
	AxiMaxLen_t rnd_maxBL;
	rnd_maxBL = 0;
	return(rnd_maxBL);
endfunction:decideCstrMaxBL



function vdma_mm_c2h_mst_perf_seq::SeqItem_t vdma_mm_c2h_mst_perf_seq::post_createSeqItem(SeqItem_t me);
  if( (this.tcfg.perf_ctrl_knob.perf_req_intr == 1) && (this.tcfg.perf_ctrl_knob.perf_req_stat == 1) ) begin
    me.makeIntrReq();
    me.makeStatReq();
  end
  
  return(me);
endfunction:post_createSeqItem


function Addr_t vdma_mm_c2h_mst_perf_seq::make64BAlignedAddr();
  Addr_t served_addr;
  
  served_addr      = {$urandom(), $urandom()};
  served_addr[5:0] = 0;
  
  return(served_addr);
endfunction : make64BAlignedAddr


function vdma_mm_c2h_mst_perf_seq::Addr_t vdma_mm_c2h_mst_perf_seq::decideCstrAddr();
  Addr_t rnd_addr;
 
  rnd_addr = {$urandom(), $urandom()};
 
  if(this.tcfg.perf_ctrl_knob.perf_crossing == NO) begin
    rnd_addr[5:0] = this.pickRandUIntInTheRange2(0, 64 - this.len);
    return(rnd_addr);
  end
  else begin
    if(!this.cnt_addr) begin
      this.cnt_addr++;
      return(DutParamHostAddr_t'(this.tcfg.perf_ctrl_knob.perf_dst_addr));
    end
    else begin
      if(this.tcfg.perf_ctrl_knob.perf_host_addr_aligned) begin
        rnd_addr[5:0] = 6'b0;
        return(DutParamHostAddr_t'(rnd_addr));
      end
      else 
        return(DutParamHostAddr_t'(rnd_addr));
    end
  end
  
  return(null);
endfunction : decideCstrAddr


function vdma_mm_c2h_mst_perf_seq::Len_t vdma_mm_c2h_mst_perf_seq::decideCstrLen();
  if(this.tcfg.perf_ctrl_knob.perf_crossing == NO) begin
    this.len = Len_t'(this.pickRandUIntInTheRange2(1, 64));
    return(this.len);
  end
  else
    return(this.tcfg.perf_ctrl_knob.perf_c2h_len_in_byte);
  
  return(null);
endfunction:decideCstrLen



function vdma_mst_seq::SeqItem_t vdma_mm_c2h_mst_perf_seq::createSeqItem(string name_postfix="");
  vdma_seq_item created;

  created = vdma_seq_item::type_id::create(this.makeItemName(name_postfix));
  created.test_type = this.tcfg.test_type;
  created.setDataSize(this.mst.getDataSize);
   
  created.cstr_dma_id      = DutParamDmaId_t'(created.getID);
  created.cstr_trans_type  = MM_C2H;
  created.cstr_dma_len     = this.decideCstrLen();
  created.cstr_axi_max_len = this.decideCstrMaxBL();
  created.cstr_src_addr    = DutParamCardAddr_t'(this.make64BAlignedAddr);
  created.cstr_dst_addr    = DutParamHostAddr_t'(this.decideCstrAddr);
  created.cstr_fnc_id      = this.decideCstrFnc_Id();
  created.cstr_str_id      = this.decideCstrStr_Id();
  
  created.randomize();
  
  return(this.post_createSeqItem(created));
endfunction:createSeqItem

`endif // __VDMA_MM_C2H_MST_PERF_SEQ_SVH__
