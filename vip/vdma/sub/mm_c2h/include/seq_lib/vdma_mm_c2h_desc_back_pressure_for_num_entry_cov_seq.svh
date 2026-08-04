`ifndef __VDMA_MM_C2H_DESC_BACK_PRESSURE_FOR_NUM_ENTRY_COV_SEQ_SVH__
`define __VDMA_MM_C2H_DESC_BACK_PRESSURE_FOR_NUM_ENTRY_COV_SEQ_SVH__



class vdma_mm_c2h_desc_back_pressure_for_num_entry_cov_seq extends vdma_mm_c2h_mst_seq;

  `uvm_object_utils(vdma_mm_c2h_desc_back_pressure_for_num_entry_cov_seq)

  function new (string name="vdma_mm_c2h_desc_back_pressure_for_num_entry_cov_seq");
     super.new(name);
     this.watchdog_cycle = 400000000;
  endfunction

  extern virtual function void genCfg();
  extern virtual task pre_genCfg();

  extern virtual function SeqItem_t post_createSeqItem(SeqItem_t me);

endclass:vdma_mm_c2h_desc_back_pressure_for_num_entry_cov_seq

function void vdma_mm_c2h_desc_back_pressure_for_num_entry_cov_seq::genCfg();
     // #PKT is randomized within the below values
     // At least num_item is over 1
     this.num_item_start = 300;
     this.num_item_end   = 300;
   
     super.genCfg();
   
endfunction:genCfg

task vdma_mm_c2h_desc_back_pressure_for_num_entry_cov_seq::pre_genCfg();
   // data size per desc (len_in_byte) is randomized within the below values
   // Based on vmg_rgs
   

   this.max_dma_size = 64;
   this.min_dma_size = 64;
   this.preset_dma_size = this.max_dma_size;
   this.rgs_dma_size = RGS_RANDOM_PER_SEQ_ITEM;

   
   super.pre_genCfg();
endtask:pre_genCfg

function vdma_mm_c2h_mst_seq::SeqItem_t vdma_mm_c2h_desc_back_pressure_for_num_entry_cov_seq::post_createSeqItem(SeqItem_t me);
  me.makeIntrReq();
  me.makeStatNoReq();
  me.makeRandDataValue(); 
  return(me);
endfunction:post_createSeqItem


`endif // __VDMA_MM_C2H_DESC_BACK_PRESSURE_FOR_NUM_ENTRY_COV_SEQ_SVH__
