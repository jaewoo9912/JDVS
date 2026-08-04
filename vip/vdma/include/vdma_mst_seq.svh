`ifndef __VDMA_MST_SEQ_SVH__
`define __VDMA_MST_SEQ_SVH__



/*


  [IMPORTANT_NOTICE]
    - dma_id  : Unique ID schemers forced on dma_id generation by setting item ID as the ID
       --> this is to make clean for fault scenario, termporarilly (this will be clean-up after spec discussion)

*/
virtual class vdma_mst_seq extends vmg_seq#(.T_SEQ_ITEM(vdma_seq_item));


	typedef ddma_pkg::Addr_t	Addr_t;
	typedef ddma_pkg::Len_t		Len_t;
	typedef ddma_pkg::FncId_t   FncId_t;
	typedef ddma_pkg::StrId_t   StrId_t;
  typedef vdma_seq_item SeqItem_t;
  typedef T_SEQ_ITEM SeqItemQ_t[$];
  typedef T_SEQ_ITEM T_SEQ_ITEM_Q[$];

  vdma_mst_tcfg tcfg;

  // ===================================================
  // USER_CONFIGURABLE
  // ===================================================
  int num_item_start = 1, num_item_end = 1;
  // ---------------------------------------------------
  RgsType_t		rgs_dma_size    = RGS_RANDOM_PER_SEQ_ITEM;
  int       	preset_dma_size	= 4096; // <----- These two set during the "prepare", since it's defined based on the DUT's data size
  int       	min_dma_size	= 1;    // <----- These two set during the "prepare", since it's defined based on the DUT's data size
  int       	max_dma_size    = MAX_DMA_LEN;
  AxiMaxLen_t	min_axi_len		= 0;
  AxiMaxLen_t	max_axi_len		= 255;
  Len_t 		being_static_len = 0;  // for unique dma data size test
//  Addr_t 		rnd_addr		= 0;
  // ===================================================
  // Category : H2C
  // ---------------------------------------------------
  // * Packet gathering
  real	prob_pkt_gathering             = 30;
  int	pkt_gathering_num_packet_start   = 3;
  int	pkt_gathering_num_packet_end     = 5;
  // ===================================================
  // Category : C2H
  // ---------------------------------------------------
  // ===================================================

  // ----------------------------------------------------
  // ----------------------------------------------------
  protected vdma_mst mst;

  local DmaTransType_t trans_type;
  int c2h_num_sam = 0;
  int h2c_num_sam = 0;
  int count_sample = 0;
  

  // ----------------------------------------------------
  protected int num_being_executed_item;
  
  protected static DmaId_t specific_dma_id = 0;
  
  typedef enum logic[1:0]{
    FOR_SPECIFIC_DMA_ID,
    FOR_BIT15_TARGET,
    NORMAL
  }DmaIdRange_t;
  
  protected int          seq_item_cnt            = 0;

  protected vmg_int_rgs_rgen rgen_dma_size;


  `uvm_declare_p_sequencer(vdma_mst_seqr)

  function new (string name="vdma_mst_seq");
	  super.new(name);

    this.need_wait_idle     = YES;
    this.watchdog_cycle = 40000000;
  endfunction


  extern virtual protected function SeqItem_t createSeqItem(string name_postfix="");
  pure virtual function SeqItem_t post_createSeqItem(SeqItem_t me);
  extern virtual protected function T_SEQ_ITEM_Q createSeqItemQ(string name_postfix="");
  
  extern virtual function Addr_t  decideCstrAddr();
  extern virtual function Len_t   decideCstrLen();
  extern virtual function FncId_t decideCstrMaxBL();  
  extern virtual function FncId_t decideCstrFnc_Id();
  extern virtual function StrId_t decideCstrStr_Id();
  
  pure virtual function DmaTransType_t getTransType();

  extern function vdma_mst_seqr getMstSeqr();

  extern virtual function void chkCfg();

  extern virtual task prepare();

  extern local function void createRgen();

  extern function void setCfg(vdma_mst mst);

  extern virtual task body();

  extern virtual task pre_genCfg();

  extern virtual function void genCfg();

  extern virtual function YesOrNo_t isIdle();
  extern virtual function YesOrNo_t isBusy();

  extern virtual function void show(string prompt="");

  extern virtual function StringQ_t getInfoList_Cfg();


endclass:vdma_mst_seq


task vdma_mst_seq::body();  
  repeat(this.num_being_executed_item) begin
    T_SEQ_ITEM_Q q_new_item;
    q_new_item = this.createSeqItemQ();
    while(q_new_item.size() > 0) begin
      T_SEQ_ITEM new_item;
      new_item = q_new_item.pop_front();
      this.issueSeqItem(new_item);
    end
  end
endtask:body




function void vdma_mst_seq::show(string prompt="");
  super.show(prompt);
  this.mst.show(prompt);
endfunction:show


function YesOrNo_t vdma_mst_seq::isBusy();
  return(this.mst.isBusy);
endfunction:isBusy


function YesOrNo_t vdma_mst_seq::isIdle();
  return(this.mst.isIdle);
endfunction:isIdle



function StringQ_t vdma_mst_seq::getInfoList_Cfg();
  StringQ_t result;

  result = super.getInfoList_Cfg();
  result.push_back($sformatf("--------------------------------------------------- "));
  result.push_back($sformatf(" - Number of transactions being executed: %1d", this.num_being_executed_item));

  result = MergeStringList(result, this.rgen_dma_size.getInfoList_Cfg);
  return(result);
endfunction:getInfoList_Cfg




function void vdma_mst_seq::genCfg();
  this.num_being_executed_item = this.pickRandUIntInTheRange2(this.num_item_start, this.num_item_end);
  this.rgen_dma_size.genCfg();
endfunction:genCfg


function void vdma_mst_seq::chkCfg(); this.rgen_dma_size.chkCfg(); endfunction



function void vdma_mst_seq::createRgen();
  this.rgen_dma_size = new($sformatf("%s_rgen_dma_size", this.get_name));
  this.rgen_dma_size.setCfg(this.rgs_dma_size, this.preset_dma_size, this.min_dma_size, this.max_dma_size);
endfunction:createRgen


task vdma_mst_seq::pre_genCfg(); this.createRgen(); endtask


function void vdma_mst_seq::setCfg(vdma_mst mst); this.mst = mst; endfunction


function vdma_mst_seqr vdma_mst_seq::getMstSeqr(); return(this.mst.seqr); endfunction


task vdma_mst_seq::prepare();
  this.trans_type = this.getTransType();
  this.min_dma_size    = this.mst.getDataSize();
  this.preset_dma_size = this.mst.getDataSize();
  this.tcfg = this.p_sequencer.tcfg;
endtask:prepare


function vdma_mst_seq::Addr_t vdma_mst_seq::decideCstrAddr();
	Addr_t	rnd_addr;
	rnd_addr = {$urandom(), $urandom()};
	return(DutParamHostAddr_t'(rnd_addr));
endfunction : decideCstrAddr


function vdma_mst_seq::Len_t vdma_mst_seq::decideCstrLen();
	Len_t rnd_len;
	rnd_len = this.rgen_dma_size.gen();
	return(rnd_len);
endfunction:decideCstrLen


function vdma_mst_seq::FncId_t vdma_mst_seq::decideCstrMaxBL();
	AxiMaxLen_t rnd_maxBL;
	rnd_maxBL = AxiMaxLen_t'($urandom());
	return(rnd_maxBL);
endfunction:decideCstrMaxBL


function vdma_mst_seq::FncId_t vdma_mst_seq::decideCstrFnc_Id();
	FncId_t rnd_fnc_id;
	rnd_fnc_id = FncId_t'($urandom());
	return(rnd_fnc_id);
endfunction:decideCstrFnc_Id


function vdma_mst_seq::StrId_t vdma_mst_seq::decideCstrStr_Id();
	StrId_t rnd_str_id;
	rnd_str_id = StrId_t'($urandom());
	return(rnd_str_id);
endfunction:decideCstrStr_Id



function vdma_mst_seq::SeqItem_t vdma_mst_seq::createSeqItem(string name_postfix=""); endfunction:createSeqItem


function vdma_mst_seq::T_SEQ_ITEM_Q vdma_mst_seq::createSeqItemQ(string name_postfix=""); endfunction:createSeqItemQ


`endif // __VDMA_MST_SEQ_SVH__
