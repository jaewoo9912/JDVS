`ifndef __VDMA_MM_H2C_MST_ADDR_BOUNDARY_SEQ_SVH__
`define __VDMA_MM_H2C_MST_ADDR_BOUNDARY_SEQ_SVH__




class vdma_mm_h2c_mst_addr_boundary_seq extends vdma_mm_h2c_mst_seq;


  `uvm_object_utils(vdma_mm_h2c_mst_addr_boundary_seq)

  function new (string name="vdma_mm_h2c_mst_addr_boundary_seq");
    super.new(name);
    this.watchdog_cycle = 400000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();
  extern virtual function Addr_t decideCstrAddr();
endclass:vdma_mm_h2c_mst_addr_boundary_seq

function Addr_t vdma_mm_h2c_mst_addr_boundary_seq::decideCstrAddr();
  Addr_t rnd_value;
  logic select_addr_size;

  select_addr_size = FlipCoin(50);

  if(select_addr_size == 0)begin
    rnd_value = 64'd2**64 - 1;
    return(DutParamHostAddr_t'(rnd_value));
  end
  else if(select_addr_size == 1)begin
    rnd_value = 64'd0;
    return(DutParamHostAddr_t'(rnd_value));
  end
  else begin
  end
endfunction:decideCstrAddr

function void vdma_mm_h2c_mst_addr_boundary_seq::genCfg();

  this.num_item_start = this.tcfg.MM_DUT_PARAM.H2C_DESCR_TABLE_SIZE * 2;
  this.num_item_end   = this.tcfg.MM_DUT_PARAM.H2C_DESCR_TABLE_SIZE * 2;

  super.genCfg();

endfunction:genCfg

// I think this task will be deleted
task vdma_mm_h2c_mst_addr_boundary_seq::pre_genCfg();


  this.max_dma_size = MAX_DMA_LEN;
  this.min_dma_size = 1;//this.max_dma_size;
  this.preset_dma_size = this.min_dma_size;

  super.pre_genCfg();
endtask:pre_genCfg




`endif // __VDMA_MM_H2C_MST_ADDR_BOUNDARY_SEQ_SVH__
