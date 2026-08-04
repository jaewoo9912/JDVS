`ifndef __VDMA_ST_C2H_ASYMMETRIC_LATENCY_SEQ_SVH__
`define __VDMA_ST_C2H_ASYMMETRIC_LATENCY_SEQ_SVH__



class vdma_st_c2h_asymmetric_latency_seq extends vdma_st_c2h_mst_seq;

  
  `uvm_object_utils(vdma_st_c2h_asymmetric_latency_seq)

  function new (string name="vdma_st_c2h_asymmetric_latency_seq");
     super.new(name);
     this.watchdog_cycle = 400000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();

endclass:vdma_st_c2h_asymmetric_latency_seq

function void vdma_st_c2h_asymmetric_latency_seq::genCfg();
     // #PKT is randomized within the below values
     // At least num_item is over 1
     this.num_item_start = this.tcfg.ST_DUT_PARAM.C2H_DESCR_TABLE_SIZE;
     this.num_item_end   = this.tcfg.ST_DUT_PARAM.C2H_DESCR_TABLE_SIZE;
   
     super.genCfg();
   
endfunction:genCfg

task vdma_st_c2h_asymmetric_latency_seq::pre_genCfg();
   // data size per desc (len_in_byte) is randomized within the below values
   // Based on vmg_rgs
   

   this.max_dma_size = 32767;
   this.min_dma_size = 1;
   this.preset_dma_size = this.max_dma_size;
   this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;

   
   super.pre_genCfg();
endtask:pre_genCfg

`endif // __VDMA_ST_C2H_ASYMMETRIC_LATENCY_SEQ_SVH__
