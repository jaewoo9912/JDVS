`ifndef __VDMA_ST_H2C_MST_RANDOM_SEQ_SVH__
`define __VDMA_ST_H2C_MST_RANDOM_SEQ_SVH__

typedef struct {
  Len_t start_len;
  Len_t end_len;
}H2CLenRange_t;

class vdma_st_h2c_mst_random_seq extends vdma_st_h2c_mst_seq;


  `uvm_object_utils(vdma_st_h2c_mst_random_seq)

  function new (string name="vdma_st_h2c_mst_random_seq");
    super.new(name);
    this.watchdog_cycle = 400000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();

  extern virtual function Len_t decideCstrLen();
  extern function H2CLenRange_t selectLenRange();
endclass:vdma_st_h2c_mst_random_seq

function void vdma_st_h2c_mst_random_seq::genCfg();
  
  this.num_item_start = this.tcfg.ST_DUT_PARAM.H2C_DESCR_TABLE_SIZE * 2;
  this.num_item_end   = this.tcfg.ST_DUT_PARAM.H2C_DESCR_TABLE_SIZE * 2;

  super.genCfg();

endfunction:genCfg



function H2CLenRange_t vdma_st_h2c_mst_random_seq::selectLenRange();
  int        select_num;
  H2CLenRange_t range;
 
  select_num = $urandom_range(1, 1700);
 
  if(select_num > 0 && select_num < 101) begin
    range.start_len = 1;
    range.end_len   = 4096;
  end
  else if(select_num > 100 && select_num < 201) begin
    range.start_len = 4097;
    range.end_len   = 8193;
  end
  else if(select_num > 200 && select_num < 301) begin
    range.start_len = 8194;
    range.end_len   = 12290;
  end
  else if(select_num > 300 && select_num < 401) begin
    range.start_len = 12291;
    range.end_len   = 16387;
  end
  else if(select_num > 400 && select_num < 501) begin
    range.start_len = 16388;
    range.end_len   = 20484;
  end
  else if(select_num > 500 && select_num < 601) begin
    range.start_len = 20485;
    range.end_len   = 24581;
  end
  else if(select_num > 600 && select_num < 701) begin
    range.start_len = 24582;
    range.end_len   = 28678;
  end
  else if(select_num > 700 && select_num < 801) begin
    range.start_len = 28679;
    range.end_len   = 32775;
  end
  else if(select_num > 800 && select_num < 901) begin
    range.start_len = 32776;
    range.end_len   = 36872;
  end
  else if(select_num > 900 && select_num < 1001) begin
    range.start_len = 36873;
    range.end_len   = 40969;
  end
  else if(select_num > 1000 && select_num < 1101) begin
    range.start_len = 40970;
    range.end_len   = 45066;
  end
  else if(select_num > 1100 && select_num < 1201) begin
    range.start_len = 45067;
    range.end_len   = 49160;
  end
  else if(select_num > 1200 && select_num < 1301) begin
    range.start_len = 49161;
    range.end_len   = 53257;
  end
  else if(select_num > 1300 && select_num < 1401) begin
    range.start_len = 53258;
    range.end_len   = 57354;
  end
  else if(select_num > 1400 && select_num < 1501) begin
    range.start_len = 57355;
    range.end_len   = 61451;
  end
  else if(select_num > 1500 && select_num < 1601) begin
    range.start_len = 61452;
    range.end_len   = 65534;
  end
  else if(select_num > 1600 && select_num < 1701) begin
    range.start_len = 65535;
    range.end_len   = 65535;
  end
  
  return(range);
endfunction : selectLenRange


function Len_t vdma_st_h2c_mst_random_seq::decideCstrLen();
  Len_t      rnd_len;
  H2CLenRange_t range;
  
  range   = this.selectLenRange();
  rnd_len = $urandom_range(range.start_len, range.end_len);
  
  return(rnd_len);
endfunction



task vdma_st_h2c_mst_random_seq::pre_genCfg();

  this.max_dma_size = MAX_DMA_LEN;
  this.min_dma_size = 1;
  this.preset_dma_size = this.min_dma_size;
  this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;

  super.pre_genCfg();
endtask:pre_genCfg



`endif // __VDMA_ST_H2C_MST_RANDOM_SEQ_SVH__
