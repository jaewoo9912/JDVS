`ifndef __VDMA_CARD_AXI_SEQ_ITEM_SVH__
`define __VDMA_CARD_AXI_SEQ_ITEM_SVH__


class vdma_card_axi_seq_item extends vmg_seq_item;

  static int num_created = 0;
  DmaId_t    dma_id;
  Desc_t     desc;
  Addr_t     pkt_addr;

  logic [64:0]                                   byteLen;
  logic                                          sop;
  logic                                          eop;

  Len_t   ax_byte_len;
  CStrb_t strb[$];
  
  bit [7:0] q_byte_data[$];
  logic                                          q_rlast[$];
  logic [`SVT_AXI_RESP_WIDTH-1:0]                q_rresp[$];

   //-----------------------------------------------------------------------
   // AXI3 Interface Write Address Channel Signals
   //-----------------------------------------------------------------------
   rand logic                                             awready;
   rand logic                                             awvalid;
   rand logic [pdma_dut_pkg::CARD_ADDR_WIDTH-1:0]         awaddr;
   rand logic [pdma_dut_pkg::CARD_ADDR_WIDTH-1:0]         waddr[$];
   rand logic [`SVT_AXI_BURST_WIDTH-1:0]                  awburst;
   rand logic [`SVT_AXI_CACHE_WIDTH-1:0]                  awcache;
   rand logic [pdma_dut_pkg::AXI_ID_WIDTH-1:0]            awid; 
   rand logic [AXI_BURST_LENGTH_WIDTH-1:0]                awlen; 
   rand logic [pdma_dut_pkg::AXI_USER_WIDTH-1:0]          awuser;
   //rand logic [`SVT_CARD_AXI_SIZE_WIDTH-1:0]                 awsize;
   //rand logic [`SVT_CARD_AXI_LOCK_WIDTH-1:0]                 awlock;
   //rand logic [`SVT_CARD_AXI_PROT_WIDTH-1:0]                 awprot;
   //-----------------------------------------------------------------------
   // AXI Interface Write Channel Signals
   //-----------------------------------------------------------------------
   rand logic                                           wready;
   rand logic                                           wvalid;
   rand logic                                           wlast;
   rand logic [CARD_DATA_WIDTH-1:0]                     wdata [$]; 
   rand logic [CARD_DATA_BYTE_WIDTH-1:0]                wstrb [$]; 
   //rand logic [SVT_CARD_AXI_ID_WIDTH_PARAM-1:0]              wid; 
   
   //-----------------------------------------------------------------------
   // AXI Interface Write Response Channel Signals
   //-----------------------------------------------------------------------
   rand logic                                           bready;
   rand logic                                           bvalid;
   rand logic [`SVT_AXI_RESP_WIDTH-1:0]                 bresp;
   rand logic [pdma_dut_pkg::AXI_ID_WIDTH-1:0]          bid; 

   //-----------------------------------------------------------------------
   // AXI Interface Read Address Channel Signals
   //-----------------------------------------------------------------------
   rand logic                                           arready;
   rand logic                                           arvalid;
   rand logic [pdma_dut_pkg::CARD_ADDR_WIDTH-1:0]       araddr; 
   rand logic [pdma_dut_pkg::CARD_ADDR_WIDTH-1:0]       raddr[$];
   rand logic [`SVT_AXI_BURST_WIDTH-1:0]                arburst;
   rand logic [`SVT_AXI_CACHE_WIDTH-1:0]                arcache;
   rand logic [pdma_dut_pkg::AXI_ID_WIDTH-1:0]          arid; 
   rand logic [AXI_BURST_LENGTH_WIDTH-1:0]              arlen; 
   rand logic [pdma_dut_pkg::AXI_USER_WIDTH-1:0]        aruser;
   //rand logic [`SVT_CARD_AXI_SIZE_WIDTH-1:0]                 arsize;
   //rand logic [`SVT_CARD_AXI_LOCK_WIDTH-1:0]                 arlock;
   //rand logic [`SVT_CARD_AXI_PROT_WIDTH-1:0]                 arprot;
  YesOrNo_t	need_fault_ar = NO;

   //-----------------------------------------------------------------------
   // AXI Interface Read Channel Signals
   //-----------------------------------------------------------------------
   rand logic                                           rready;
   rand logic                                           rvalid;
   rand logic                                           rlast;
   rand logic [pdma_dut_pkg::AXI_ID_WIDTH-1:0]          rid; 
   rand logic [CARD_DATA_WIDTH-1:0]                     rdata[$]; 
   rand logic [`SVT_AXI_RESP_WIDTH-1:0]                 rresp;
   
   CaxiData_t                                           q_caxi_data;
   DataQ_t                                              q_data; // <--------------- This is randomized at "post_randomize"


  `uvm_object_utils(vdma_card_axi_seq_item)

  function new (string name="vdma_card_axi_seq_item");
    super.new(name);
    this.setID(this.num_created++);
  endfunction

  extern virtual function YesOrNo_t isCompleted();

endclass:vdma_card_axi_seq_item

function YesOrNo_t vdma_card_axi_seq_item::isCompleted();
  return(NO);
endfunction:isCompleted



`endif // __VDMA_CARD_AXI_SEQ_ITEM_SVH__
