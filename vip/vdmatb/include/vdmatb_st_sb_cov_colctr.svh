`ifndef __VDMATB_ST_SB_COV_COLCTR_SVH__
`define __VDMATB_ST_SB_COV_COLCTR_SVH__

class vdmatb_st_sb_cov_colctr #(
  parameter type T_TRANS  = vdma_seq_item,
  parameter type T_TRANS2 = vdmatb_host_seq_item
) extends vmg_obj;

  T_TRANS c2h_trans, h2c_trans;

  FuncCovC2H_t c2h_cp;
  FuncCovH2C_t h2c_cp;

  Empty_t c2h_mty, h2c_mty;
  logic [AXI_BURST_LENGTH_WIDTH-1:0] awlen, arlen;
  int num_0, num_1;
  
  SampleLstForFault_t sample_lst_host_b_wrong_resp;
  SampleLstForFault_t sample_lst_host_r_wrong_resp;
  SampleLstForFault_t sample_lst_c2h_desc_data_length_is_zero_fault_wo_following_trans;
  SampleLstForFault_t sample_lst_h2c_desc_data_length_is_zero_fault_wo_following_trans;
  SampleLstForFault_t sample_lst_c2h_desc_data_length_is_zero_fault_with_following_trans;
  SampleLstForFault_t sample_lst_h2c_desc_data_length_is_zero_fault_with_following_trans;
  SampleLstForFault_t sample_lst_h2c_desc_fault;
  SampleLstForFault_t sample_lst_c2h_card_fault;
  SampleLstForFault_t sample_lst_host_r_no_last;
  SampleLstForFault_t sample_lst_host_r_premature_last;
  
  logic[pdma_dut_pkg::HOST_ADDR_WIDTH - 1:0] max_host_addr;

  localparam bit[pdma_dut_pkg::HOST_ADDR_WIDTH - 1:0] MAX_HOST_ADDR = '1;
  localparam bit[pdma_dut_pkg::HOST_ADDR_WIDTH - 1:0] MAX_HOST_ADDR_DIV8 = MAX_HOST_ADDR >> 3;
  localparam bit[pdma_dut_pkg::HOST_ADDR_WIDTH - 1:0] MAX_HOST_ADDR_DIV4 = MAX_HOST_ADDR >> 2;
  localparam bit[pdma_dut_pkg::HOST_ADDR_WIDTH - 1:0] MAX_HOST_ADDR_DIV2 = MAX_HOST_ADDR >> 1;
  // ------------------------------ C2H
  covergroup C2H_cov_grp(input logic[pdma_dut_pkg::HOST_ADDR_WIDTH - 1:0] max_host_addr);
    single_dst_addr : coverpoint DutParamHostAddr_t'(this.c2h_trans.desc.dst_addr){
      bins min  = {0};
      bins bin1 = {[1                 :MAX_HOST_ADDR_DIV8 - 1]};
      bins bin2 = {[MAX_HOST_ADDR_DIV8:MAX_HOST_ADDR_DIV4 - 1]};
      bins bin3 = {[MAX_HOST_ADDR_DIV4:MAX_HOST_ADDR_DIV2 - 1]};
      bins bin4 = {[MAX_HOST_ADDR_DIV2:MAX_HOST_ADDR      - 2]};
      bins max  = {MAX_HOST_ADDR - 1};
//      bins bin1 = {[1:(max_host_addr >> 3) - 1]};
//      bins bin2 = {[max_host_addr >> 3:(max_host_addr >> 2) - 1]};
//      bins bin3 = {[max_host_addr >> 2:(max_host_addr >> 1) - 1]};
//      bins bin4 = {[max_host_addr >> 1: max_host_addr - 2]};
//      bins max =   {max_host_addr - 1};
    }
       
    single_len_in_byte : coverpoint this.c2h_trans.desc.len{
      bins auto1  = {[1    : 4096]};
      bins auto2  = {[4097 : 8193]};
      bins auto3  = {[8194 :12290]};
      bins auto4  = {[12291:16387]};
      bins auto5  = {[16388:20484]};
      bins auto6  = {[20485:24581]};
      bins auto7  = {[24582:28678]};
      bins auto8  = {[28679:32775]};
      bins auto9  = {[32776:36872]};
      bins auto10 = {[36873:40969]};
      bins auto11 = {[40970:45066]};
      bins auto12 = {[45067:49160]};
      bins auto13 = {[49161:53257]};
      bins auto14 = {[53258:57354]};
      bins auto15 = {[57355:61451]};
      bins auto16 = {[61452:65534]};
      bins auto17 = {65535};
    }
    
    trans_len_in_byte : coverpoint this.c2h_trans.desc.len{
      bins auto1_to_auto9  = ([    1: 4096]=>[32776:36872]); //0~4 32~36
      bins auto2_to_auto10 = ([ 4097: 8193]=>[36873:40969]); // 4~8 36~40
      bins auto3_to_auto11 = ([ 8194:12290]=>[40970:45066]);// 8~12 40~44
      bins auto5_to_auto12 = ([16388:20484]=>[45067:49160]);// 16~20 44~48
      bins auto7_to_auto14 = ([24582:28678]=>[53258:57354]);// 24~28 52~56
      bins auto9_to_auto16 = ([32776:36872]=>[61452:65534]);// 32~36 60~64
      
      bins auto9_to_auto1  = ([32776:36872]=>[    1: 4096]);
      bins auto10_to_auto2 = ([36873:40969]=>[ 4097: 8193]);
      bins auto11_to_auto3 = ([40970:45066]=>[ 8194:12290]);
      bins auto12_to_auto5 = ([45067:49160]=>[16388:20484]);
      bins auto14_to_auto7 = ([53258:57354]=>[24582:28678]);
      bins auto16_to_auto9 = ([61452:65534]=>[32776:36872]);
    }
    
    single_max_hburst_len : coverpoint this.c2h_trans.desc.axi_max_len {
      bins range[] = {[0:255]};
    }
    
    trans_max_hburst_len : coverpoint this.c2h_trans.desc.axi_max_len {
      
      bins small1_to_small5 = ([  0: 15]=>[ 64: 79]); 
      bins small5_to_mid4   = ([ 64: 79]=>[128:143]); 
      bins mid4_to_big3     = ([128:143]=>[192:207]); 
      bins big3_to_big6     = ([192:207]=>[240:255]); 
      
      bins small5_to_small1 = ([ 64: 79]=>[  0: 15]); 
      bins mid4_to_small5   = ([128:143]=>[ 64: 79]); 
      bins big3_to_mid4     = ([192:207]=>[128:143]); 
      bins big6_to_big3     = ([240:255]=>[192:207]); 
      
      bins small1_to_mid4   = ([  0: 15]=>[128:143]); 
      bins mid4_to_big6     = ([128:143]=>[240:255]); 
      
      bins mid4_to_small1   = ([128:143]=>[  0: 15]); 
      bins big6_to_mid4     = ([240:255]=>[128:143]); 
    }
    
    single_req_intr : coverpoint this.c2h_trans.desc.req_intr {
      bins range[] = {[0:1]};
    }
    
    single_req_stat : coverpoint this.c2h_trans.desc.req_stat {
      bins range[] = {[0:1]};
    }
    
    single_str_id : coverpoint this.c2h_trans.desc.str_id{
      option.auto_bin_max = 16;
    }
  
    single_vec_id : coverpoint this.c2h_trans.desc.vec_id{
      option.auto_bin_max = 8;
    } 
  
    single_fnc_id : coverpoint this.c2h_trans.desc.fnc_id{
      option.auto_bin_max = 16;
    }


    for_cross_dstAddr_4k_Boundary : coverpoint this.c2h_cp.dst_addr_aligned{
      option.auto_bin_max = 32;
    }
    
    for_cross_lenInByte_4k_Boundary : coverpoint this.c2h_cp.c2h_lenInByte_low_12bits{
      option.auto_bin_max = 32;
    }
    
    for_cross_dstAddr_Addr_logic : coverpoint this.c2h_cp.dst_addr_low_6bits{
      bins range[] = {[64'd0:(64'd2**6)-1]};
    }
    
    for_cross_lenInByte_Addr_logic : coverpoint this.c2h_cp.c2h_lenInByte_low_6bits {
      bins range[] = {[64'd0:(64'd2**6)-1]};
    }

    // Split on Burst Length
    cross_maxBL_LenInByte : cross single_max_hburst_len, single_len_in_byte;
    
    specific_num_split_on_maxBL : coverpoint this.c2h_cp.c2h_BL2 {
      bins range[] = {[0:MAX_DMA_LEN / HOST_DATA_BYTE_WIDTH]};
//      bins range[] = {[0:1024]};
    }
    
    specific_modulo_split_on_maxBL : coverpoint this.c2h_cp.c2h_split_on_BL_modulo {
//      bins range[] = {[0:63]};
      bins range[] = {[0:AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH - 1]};
    }
    
    // Split on 4K Boundary
    cross_dstAddr_LenInByte_low_12bits : cross for_cross_dstAddr_4k_Boundary, for_cross_lenInByte_4k_Boundary{
      bins range = cross_dstAddr_LenInByte_low_12bits with (for_cross_dstAddr_4k_Boundary + for_cross_lenInByte_4k_Boundary > 'hfff);
    }
    
    specific_num_split_on_4k_boundary : coverpoint this.c2h_cp.num_split_on_4K_Boundary{
//      bins range[] = {[0:16]};
      bins range[] = {[0:MAX_DMA_LEN / AXI_4K_BOUNDARY]};
    }

    for_cross_Split_Type : coverpoint this.c2h_cp.num_split_on_4K_Boundary{
      bins zero = {0};
      bins over_zero = {[1:MAX_DMA_LEN / AXI_4K_BOUNDARY]};
    }
    
    for_cross_dstAddr_Split_Type : coverpoint this.c2h_cp.dst_addr_low_12bits{
      bins range[] = {[0:$]};
    }
    
  	cross_dstAddr_low_12bits_on_split : cross for_cross_Split_Type, for_cross_dstAddr_Split_Type;
    
    cross_addr_logic : cross single_dst_addr, single_len_in_byte, for_cross_dstAddr_Addr_logic, for_cross_lenInByte_Addr_logic;
    cross_dstAddr_lenInByte_Addr_logic : cross single_dst_addr, single_len_in_byte;
    cross_Low_lenInByte_Addr_logic : cross single_len_in_byte, for_cross_lenInByte_Addr_logic;
    cross_Low_dstAddr_Addr_logic : cross for_cross_dstAddr_Addr_logic, single_dst_addr;
    cross_dstAddr_LenInByte_low_6bits : cross for_cross_dstAddr_Addr_logic, for_cross_lenInByte_Addr_logic;
    
  endgroup
  
  // ------------------------------ H2C
  covergroup H2C_cov_grp(input logic[pdma_dut_pkg::HOST_ADDR_WIDTH - 1:0] max_host_addr);
    
    single_src_addr : coverpoint DutParamHostAddr_t'(this.h2c_trans.desc.src_addr){
      bins min  = {0};
      bins bin1 = {[1                 :MAX_HOST_ADDR_DIV8 - 1]};
      bins bin2 = {[MAX_HOST_ADDR_DIV8:MAX_HOST_ADDR_DIV4 - 1]};
      bins bin3 = {[MAX_HOST_ADDR_DIV4:MAX_HOST_ADDR_DIV2 - 1]};
      bins bin4 = {[MAX_HOST_ADDR_DIV2:MAX_HOST_ADDR      - 2]};
      bins max  = {MAX_HOST_ADDR - 1};
//      
//      bins min = {0};
//      bins bin1 = {[1:(max_host_addr >> 3) - 1]};
//      bins bin2 = {[max_host_addr >> 3:(max_host_addr >> 2) - 1]};
//      bins bin3 = {[max_host_addr >> 2:(max_host_addr >> 1) - 1]};
//      bins bin4 = {[max_host_addr >> 1: max_host_addr - 2]};
//      bins max =   {max_host_addr - 1};
    }
    
    single_len_in_byte : coverpoint this.h2c_trans.desc.len{
      bins auto1  = {[    1: 4096]};
      bins auto2  = {[ 4097: 8193]};
      bins auto3  = {[ 8194:12290]};
      bins auto4  = {[12291:16387]};
      bins auto5  = {[16388:20484]};
      bins auto6  = {[20485:24581]};
      bins auto7  = {[24582:28678]};
      bins auto8  = {[28679:32775]};
      bins auto9  = {[32776:36872]};
      bins auto10 = {[36873:40969]};
      bins auto11 = {[40970:45066]};
      bins auto12 = {[45067:49160]};
      bins auto13 = {[49161:53257]};
      bins auto14 = {[53258:57354]};
      bins auto15 = {[57355:61451]};
      bins auto16 = {[61452:65534]};
      bins auto17 = {65535};
    }
    
    trans_len_in_byte : coverpoint this.h2c_trans.desc.len{
      bins auto1_to_auto9  = ([    1: 4096]=>[32776:36872]); //0~4 32~36
      bins auto2_to_auto10 = ([ 4097: 8193]=>[36873:40969]); // 4~8 36~40
      bins auto3_to_auto11 = ([ 8194:12290]=>[40970:45066]);// 8~12 40~44
      bins auto5_to_auto12 = ([16388:20484]=>[45067:49160]);// 16~20 44~48
      bins auto7_to_auto14 = ([24582:28678]=>[53258:57354]);// 24~28 52~56
      bins auto9_to_auto16 = ([32776:36872]=>[61452:65534]);// 32~36 60~64
      
      bins auto9_to_auto1  = ([32776:36872]=>[    1: 4096]);
      bins auto10_to_auto2 = ([36873:40969]=>[ 4097: 8193]);
      bins auto11_to_auto3 = ([40970:45066]=>[ 8194:12290]);
      bins auto12_to_auto5 = ([45067:49160]=>[16388:20484]);
      bins auto14_to_auto7 = ([53258:57354]=>[24582:28678]);
      bins auto16_to_auto9 = ([61452:65534]=>[32776:36872]);
    }
   
   
    single_max_hburst_len : coverpoint this.h2c_trans.desc.axi_max_len{
      bins range[] = {[0:255]};
    }
    
    trans_max_hburst_len : coverpoint this.h2c_trans.desc.axi_max_len {
      bins small1_to_small5 = ([  0: 15]=>[ 64: 79]); 
      bins small5_to_mid4   = ([ 64: 79]=>[128:143]); 
      bins mid4_to_big3     = ([128:143]=>[192:207]); 
      bins big3_to_big6     = ([192:207]=>[240:255]); 
      
      bins small5_to_small1 = ([ 64: 79]=>[  0: 15]); 
      bins mid4_to_small5   = ([128:143]=>[ 64: 79]); 
      bins big3_to_mid4     = ([192:207]=>[128:143]); 
      bins big6_to_big3     = ([240:255]=>[192:207]); 
      
      bins small1_to_mid4   = ([  0: 15]=>[128:143]); 
      bins mid4_to_big6     = ([128:143]=>[240:255]); 
      
      bins mid4_to_small1   = ([128:143]=>[  0: 15]); 
      bins big6_to_mid4     = ([240:255]=>[128:143]); 
    }
    
    single_req_intr : coverpoint this.h2c_trans.desc.req_intr{
      bins range[] = {[0:1]};
    }

    single_req_stat : coverpoint this.h2c_trans.desc.req_stat{
      bins range[] = {[0:1]};
    }

    single_str_id : coverpoint this.h2c_trans.desc.str_id{
      option.auto_bin_max = 16;
    }

    single_vec_id : coverpoint this.h2c_trans.desc.vec_id{
      option.auto_bin_max = 8;
    }
    
    single_fnc_id : coverpoint this.h2c_trans.desc.fnc_id{
      option.auto_bin_max = 16;
    }

    single_sop : coverpoint this.h2c_trans.desc.sop{
      bins range[] = {[0:1]};
    }

    single_eop : coverpoint this.h2c_trans.desc.eop{
      bins range[] = {[0:1]};
    }
    
    for_cross_srcAddr_Addr_logic : coverpoint this.h2c_cp.src_addr_low_6bits{
      bins range[] = {[64'd0:(64'd2**6)-1]};
    }
    
    for_cross_lenInByte_Addr_logic : coverpoint this.h2c_cp.h2c_lenInByte_low_6bits{
      bins range[] = {[64'd0:(64'd2**6)-1]};
    }
    
    cross_maxBL_LenInByte : cross single_max_hburst_len, single_len_in_byte;
    
    specific_num_split_on_maxBL : coverpoint this.h2c_cp.h2c_BL2 {
      bins range[] = {[0:MAX_DMA_LEN / HOST_DATA_BYTE_WIDTH]};
    }
    
    specific_modulo_split_on_maxBL : coverpoint this.h2c_cp.h2c_split_on_BL_modulo {
      bins range[] = {[0:AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH -1]};
    }
    
    cross_addr_logic : cross single_src_addr, single_len_in_byte, for_cross_srcAddr_Addr_logic, for_cross_lenInByte_Addr_logic;
    cross_srcAddr_lenInByte_Addr_logic : cross single_src_addr, single_len_in_byte;
    cross_Low_lenInByte_Addr_logic : cross single_len_in_byte, for_cross_lenInByte_Addr_logic;
    cross_Low_srcAddr_Addr_logic : cross for_cross_srcAddr_Addr_logic, single_src_addr;
    cross_srcAddr_LenInByte_low_6bits : cross for_cross_srcAddr_Addr_logic, for_cross_lenInByte_Addr_logic;
    
  endgroup
  
  // ------------------------------ Axlen
  covergroup ar_burst_len;
    arlen : coverpoint this.arlen{
      bins min = {0};
      bins mid = {[1:(AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH) - 2]};
      bins max = {(AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH) - 1};
    }
  endgroup
  
  covergroup aw_burst_len;
    awlen : coverpoint this.awlen{
      bins min = {0};
      bins mid = {[0:(AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH) - 2]};
      bins max = {(AXI_4K_BOUNDARY / HOST_DATA_BYTE_WIDTH) - 1};
    }
  endgroup
  
  // ------------------------------ wstrb
  covergroup wstrb;
    single_wstrb_num_zero : coverpoint this.num_0 {
      bins range[] = {[0:HOST_DATA_BYTE_WIDTH]};
    }
    
    single_wstrb_num_one : coverpoint this.num_1 {
      bins range[] = {[0:HOST_DATA_BYTE_WIDTH]};
    }
    
    cross_wstrb_pattern : cross single_wstrb_num_zero, single_wstrb_num_one;
  endgroup
  
  // ------------------------------ Fault Host
  covergroup cg_fault_host_b_wrong_resp;
    intended_fault_host_b_wrong_resp : coverpoint (this.sample_lst_host_b_wrong_resp.intended_fault) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    generated_fault_host_b_wrong_resp : coverpoint (this.sample_lst_host_b_wrong_resp.gen_faultType) {
      bins         gen_fault_host_b_wrong_resp     = {int'(HOST_B_WRONG_RESP)};
      illegal_bins not_gen_fault_host_b_wrong_resp = {0};
    }
    
    following_trans_complete : coverpoint (this.sample_lst_host_b_wrong_resp.following_trans) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    cross_fault_host_b_wrong_resp : cross intended_fault_host_b_wrong_resp, generated_fault_host_b_wrong_resp, following_trans_complete;
  endgroup
 
  covergroup cg_fault_host_r_wrong_resp;
    intended_fault_host_r_wrong_resp : coverpoint (this.sample_lst_host_r_wrong_resp.intended_fault) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    generated_fault_host_r_wrong_resp : coverpoint (this.sample_lst_host_r_wrong_resp.gen_faultType) {
      bins         gen_fault_host_r_wrong_resp     = {int'(HOST_R_WRONG_RESP)};
      illegal_bins not_gen_fault_host_r_wrong_resp = {0};
    }
    
    following_trans_complete : coverpoint (this.sample_lst_host_r_wrong_resp.following_trans) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    cross_fault_host_r_wrong_resp : cross intended_fault_host_r_wrong_resp, generated_fault_host_r_wrong_resp, following_trans_complete;
  endgroup
  
  covergroup cg_fault_host_r_no_last;
    intended_fault_host_r_no_last : coverpoint (this.sample_lst_host_r_no_last.intended_fault) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    generated_fault_host_r_no_last : coverpoint (this.sample_lst_host_r_no_last.gen_faultType) {
      bins         gen_fault_host_r_no_last     = {int'(HOST_R_NO_LAST)};
      illegal_bins not_gen_fault_host_r_no_last = {0};
    }
    
    following_trans_complete : coverpoint (this.sample_lst_host_r_no_last.following_trans) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    cross_fault_host_r_no_last : cross intended_fault_host_r_no_last, generated_fault_host_r_no_last, following_trans_complete;
  endgroup
  
  covergroup cg_fault_host_r_premature_last;
    intended_fault_host_r_premature_last : coverpoint (this.sample_lst_host_r_premature_last.intended_fault) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    generated_fault_host_r_premature_last : coverpoint (this.sample_lst_host_r_premature_last.gen_faultType) {
      bins         gen_fault_host_r_premature_last     = {int'(HOST_R_PREMATURE_LAST)};
      illegal_bins not_gen_fault_host_r_premature_last = {0};
    }
    
    following_trans_complete : coverpoint (this.sample_lst_host_r_premature_last.following_trans) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    cross_fault_host_r_premature_last : cross intended_fault_host_r_premature_last, generated_fault_host_r_premature_last, following_trans_complete;
  endgroup
  // ------------------------------ Fault Card
  
  covergroup cg_c2h_desc_data_length_is_zero_fault_wo_following_trans;
    generated_fault_type : coverpoint (this.sample_lst_c2h_desc_data_length_is_zero_fault_wo_following_trans.gen_faultType) {
      bins DESC_DATA_LENGTH_IS_ZERO            = {0};
    }
    
    intended_fault : coverpoint (this.sample_lst_c2h_desc_data_length_is_zero_fault_wo_following_trans.intended_fault) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    cross_h2c_card_fault : cross generated_fault_type, intended_fault;
  endgroup


  covergroup cg_h2c_desc_data_length_is_zero_fault_wo_following_trans;
    generated_fault_type : coverpoint (this.sample_lst_h2c_desc_data_length_is_zero_fault_wo_following_trans.gen_faultType) {
      bins DESC_DATA_LENGTH_IS_ZERO            = {0};
    }
    
    intended_fault : coverpoint (this.sample_lst_h2c_desc_data_length_is_zero_fault_wo_following_trans.intended_fault) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    cross_h2c_card_fault : cross generated_fault_type, intended_fault;
  endgroup
  
  
  covergroup cg_c2h_desc_data_length_is_zero_fault_with_following_trans;
    following_trans_complete : coverpoint (this.sample_lst_c2h_desc_data_length_is_zero_fault_with_following_trans.following_trans) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
  endgroup


  covergroup cg_h2c_desc_data_length_is_zero_fault_with_following_trans;
    following_trans_complete : coverpoint (this.sample_lst_h2c_desc_data_length_is_zero_fault_with_following_trans.following_trans) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
  endgroup
  
  
  
  
  covergroup cg_c2h_card_fault;
    generated_fault_type : coverpoint (this.sample_lst_c2h_card_fault.gen_faultType) {
      bins CARD_R_PREMATURE_LAST    = {5};
      bins CARD_R_NO_LAST           = {6};
      bins CARD_R_WRONG_MTY         = {7};
      bins CARD_R_WRONG_DMA_ID      = {14};
    }
    
    intended_fault : coverpoint (this.sample_lst_c2h_card_fault.intended_fault) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    following_trans_complete : coverpoint (this.sample_lst_c2h_card_fault.following_trans) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    cross_c2h_card_fault : cross generated_fault_type, intended_fault, following_trans_complete;
  endgroup
 
  covergroup cg_h2c_desc_fault;
    generated_fault_type : coverpoint (this.sample_lst_h2c_desc_fault.gen_faultType) {
      bins DESC_MID_OF_PKT_BEFORE_START_OF_PKT = {1};
      bins DESC_SOLO_PKT_DURING_GATHERING      = {2};
      bins DESC_START_OF_PKT_DURING_GATHERING  = {3};
      bins DESC_END_OF_PKT_BEFORE_START_OF_PKT = {13};
    }
    
    intended_fault : coverpoint (this.sample_lst_h2c_desc_fault.intended_fault) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    following_trans_complete : coverpoint (this.sample_lst_h2c_desc_fault.following_trans) {
      bins         YES = {1};
      illegal_bins NO  = {0};
    }
    
    cross_h2c_card_fault : cross generated_fault_type, intended_fault, following_trans_complete;
  endgroup
  
  `uvm_object_utils(vdmatb_st_sb_cov_colctr) 
  function new (string name = "vdmatb_st_sb_cov_colctr");
    super.new(name);
    this.setMaxHostAddr();
    
    C2H_cov_grp                                                = new(this.max_host_addr);
    H2C_cov_grp                                                = new(this.max_host_addr);
    ar_burst_len                                               = new();
    aw_burst_len                                               = new();
    wstrb                                                      = new();
    cg_fault_host_b_wrong_resp                                 = new();
    cg_fault_host_r_wrong_resp                                 = new();
    cg_c2h_desc_data_length_is_zero_fault_wo_following_trans   = new();
    cg_h2c_desc_data_length_is_zero_fault_wo_following_trans   = new();
    cg_c2h_desc_data_length_is_zero_fault_with_following_trans = new();
    cg_h2c_desc_data_length_is_zero_fault_with_following_trans = new();
    cg_h2c_desc_fault                                          = new();
    cg_c2h_card_fault                                          = new();
    cg_fault_host_r_no_last                                    = new();
    cg_fault_host_r_premature_last                             = new();
  endfunction
  
  extern function void sampleDesc(T_TRANS trans);
  extern function void sampleArLen(logic[AXI_BURST_LENGTH_WIDTH-1:0] arlen);
  extern function void sampleAwLen(logic[AXI_BURST_LENGTH_WIDTH-1:0] awlen);
  extern function void sampleWstrb(logic[HOST_DATA_BYTE_WIDTH-1:0] input_wstrb);

  extern function void       cal_CrossCP_core(T_TRANS trans);
  extern function int        cal_BLSplit(Len_t len, AxiMaxLen_t axi_max_len);
  extern function int        cal_BLSplitModulo(Len_t len, AxiMaxLen_t axi_max_len);
  extern function logic[4:0] cal_split4KBoundary(Addr_t addr, Len_t len);
  extern function void       setAddrAndLen(T_TRANS trans);
  
  extern function int countWstrb_1(logic[HOST_DATA_BYTE_WIDTH-1:0] input_wstrb);
  extern function int countWstrb_0(logic[HOST_DATA_BYTE_WIDTH-1:0] input_wstrb);
 
  extern function void setMaxHostAddr();
  
  // ----- ANDA working
  extern function void setFaultHostBWrongRespSampleLst(SampleLstForFault_t sample_list);
  extern function void sampleFaultHostBWrongResp();
  extern function void setFaultHostRWrongRespSampleLst(SampleLstForFault_t sample_list);
  extern function void sampleFaultHostRWrongResp();
 
  extern function void setC2HDescDataLenZeroFaultSampleLst_wo_followingTrans(SampleLstForFault_t sample_list);
  extern function void sampleC2HDescDataLenZeroFault_wo_followingTrans();
  extern function void setH2CDescDataLenZeroFaultSampleLst_wo_followingTrans(SampleLstForFault_t sample_list);
  extern function void sampleH2CDescDataLenZeroFault_wo_followingTrans();
  
  extern function void setC2HDescDataLenZeroFaultSampleLst_with_followingTrans(SampleLstForFault_t sample_list);
  extern function void sampleC2HDescDataLenZeroFault_with_followingTrans();
  extern function void setH2CDescDataLenZeroFaultSampleLst_with_followingTrans(SampleLstForFault_t sample_list);
  extern function void sampleH2CDescDataLenZeroFault_with_followingTrans();
  
  extern function void setH2CDescFaultSampleLst(SampleLstForFault_t sample_list);
  extern function void sampleH2CDescFault();
 
  extern function void setC2HCardFaultSampleLst(SampleLstForFault_t sample_list);
  extern function void sampleC2HCardFault();
  
  extern function void setFaultHostRNoLastSampleLst(SampleLstForFault_t sample_list);
  extern function void sampleFaultHostRNoLast();

  extern function void setFaultHostRPrematureLastSampleLst(SampleLstForFault_t sample_list);
  extern function void sampleFaultHostRPrematureLast();
endclass



function void vdmatb_st_sb_cov_colctr::setAddrAndLen(T_TRANS trans);

  if(trans.getTransType == ST_C2H) begin
    this.c2h_cp.dst_addr_low_6bits       = trans.desc.dst_addr[5:0];
    this.c2h_cp.dst_addr_low_12bits      = trans.desc.dst_addr[11:0];
    this.c2h_cp.dst_addr_aligned         = this.c2h_cp.dst_addr_low_12bits & 12'b111111000000;
    this.c2h_cp.c2h_lenInByte_low_6bits  = trans.desc.len[5:0];
    this.c2h_cp.c2h_lenInByte_low_12bits = trans.desc.len[11:0];
  end
  else if(trans.getTransType == ST_H2C) begin
    this.h2c_cp.src_addr_low_6bits       = trans.desc.src_addr[5:0];
    this.h2c_cp.h2c_lenInByte_low_6bits  = trans.desc.len[5:0];
  end

endfunction:setAddrAndLen



function int vdmatb_st_sb_cov_colctr::cal_BLSplit(Len_t len, AxiMaxLen_t axi_max_len);
  return((len / HOST_DATA_BYTE_WIDTH) / axi_max_len);
endfunction : cal_BLSplit


function int vdmatb_st_sb_cov_colctr::cal_BLSplitModulo(Len_t len, AxiMaxLen_t axi_max_len);
  return((len / HOST_DATA_BYTE_WIDTH) % axi_max_len);  
endfunction : cal_BLSplitModulo



function logic[4:0] vdmatb_st_sb_cov_colctr::cal_split4KBoundary(Addr_t addr, Len_t len);
  logic[pdma_dut_pkg::HOST_ADDR_WIDTH:0] sum_addr_len;
  logic[pdma_dut_pkg::HOST_ADDR_WIDTH - 12:0] shift_sum;
  logic[pdma_dut_pkg::HOST_ADDR_WIDTH -1 - 12:0] shift_addr;
  logic[4:0] result;
  
  sum_addr_len = DutParamHostAddr_t'(addr) + len;
  shift_sum = sum_addr_len >> 12;
  shift_addr = DutParamHostAddr_t'(addr) >> 12;
  
  if(sum_addr_len[11:0] == 12'h000) begin
    result = shift_sum - shift_addr - 1;
  end
  else begin
    result = shift_sum - shift_addr;
  end
  
  return(result);
endfunction:cal_split4KBoundary



function void vdmatb_st_sb_cov_colctr::cal_CrossCP_core(T_TRANS trans);
  this.setAddrAndLen(trans);

  if(trans.getTransType == ST_C2H) begin
    this.c2h_cp.c2h_max_hburst_len       = (trans.desc.axi_max_len == 0) ? 256 : trans.desc.axi_max_len;
    this.c2h_cp.c2h_BL2                  = this.cal_BLSplit(trans.desc.len, this.c2h_cp.c2h_max_hburst_len);
    this.c2h_cp.c2h_split_on_BL_modulo   = this.cal_BLSplitModulo(trans.desc.len, this.c2h_cp.c2h_max_hburst_len);
    this.c2h_cp.num_split_on_4K_Boundary = this.cal_split4KBoundary(trans.desc.dst_addr, trans.desc.len);
  end
  else if(trans.getTransType == ST_H2C) begin
    this.h2c_cp.h2c_max_hburst_len       = (trans.desc.axi_max_len == 0) ? 256 : trans.desc.axi_max_len;
    this.h2c_cp.h2c_BL2                  = this.cal_BLSplit(trans.desc.len, this.h2c_cp.h2c_max_hburst_len);
    this.h2c_cp.h2c_split_on_BL_modulo   = this.cal_BLSplitModulo(trans.desc.len, this.h2c_cp.h2c_max_hburst_len);
    
  end

endfunction:cal_CrossCP_core



function int vdmatb_st_sb_cov_colctr::countWstrb_1(logic[HOST_DATA_BYTE_WIDTH-1:0] input_wstrb);
  logic value_0_or_1 = 0; 
  logic[CLOG_HOST_DATA_BYTE_WIDTH:0] num_0 = 0;
  logic[CLOG_HOST_DATA_BYTE_WIDTH:0] num_1 = 64;
  int count_one = 0;
  int check_start_bit = 0;
  int start_bit_is_one = 0;
  int end_bit_is_one = 0;
  int check_bit_zero = 0;
  int error_bit = 0;
  
  for(int i = 0; i <= 63; i++) begin
    value_0_or_1 = (input_wstrb & (1 << i)) >> i;
    
    if(value_0_or_1 == 1) begin
      if(check_bit_zero) begin
        error_bit = 1;
      end
      
      count_one++;
      
      if(check_start_bit == 0) begin
        start_bit_is_one = i;
        num_0 = start_bit_is_one;
        
        check_start_bit = 1;
      end
      
      if((check_start_bit == 1) && (i == 63)) begin
        end_bit_is_one = count_one;
        num_1 = end_bit_is_one;
      end
    end // main if
    else if(value_0_or_1 == 0) begin
      if(check_start_bit == 1) begin
        end_bit_is_one = count_one;
        num_1 = end_bit_is_one;
        
        check_bit_zero = 1;
      end
    end // else
  end // for
      
  return(num_1);
endfunction : countWstrb_1



function int vdmatb_st_sb_cov_colctr::countWstrb_0(logic[HOST_DATA_BYTE_WIDTH-1:0] input_wstrb);
  logic value_0_or_1 = 0;
  logic[CLOG_HOST_DATA_BYTE_WIDTH:0] num_0 = 64;
  logic[CLOG_HOST_DATA_BYTE_WIDTH:0] num_1 = 0;
  int count_one = 0;
  int check_start_bit = 0;
  int start_bit_is_one = 0;
  int end_bit_is_one = 0;
  int check_bit_zero = 0;
  int error_bit = 0;
  
  for(int i = 0; i<=63; i++) begin
    value_0_or_1 = (input_wstrb & (1 << i)) >> i;
    
    if(value_0_or_1 == 1)begin
      
      if(check_bit_zero) begin
        error_bit = 1; // TODO : Error checker implementation
      end
      
      count_one++;
      
      if(check_start_bit == 0)begin 
        start_bit_is_one = i;
        num_0 = start_bit_is_one;
        
        check_start_bit = 1;
      end    
      
      if((check_start_bit == 1) && (i == 63)) begin
        end_bit_is_one = count_one;
        num_1 = end_bit_is_one;
        
      end
    end  // -------------- if
    else if(value_0_or_1 == 0)begin
      if(check_start_bit == 1)begin
        end_bit_is_one = count_one;
        num_1 = end_bit_is_one;
        
        check_bit_zero = 1;
      end
    end
  end // for
  
  return(num_0);
endfunction : countWstrb_0




function void vdmatb_st_sb_cov_colctr::setMaxHostAddr();
  case(pdma_dut_pkg::HOST_ADDR_WIDTH)
    64 : this.max_host_addr = 64'hFFFF_FFFF_FFFF_FFFF;
    48 : this.max_host_addr = 64'hFFFF_FFFF_FFFF;
    40 : this.max_host_addr = 64'hFF_FFFF_FFFF;
  endcase
endfunction : setMaxHostAddr



function void vdmatb_st_sb_cov_colctr::sampleDesc(T_TRANS trans);
  if(trans.getTransType == ST_C2H) begin
    this.c2h_trans = trans;
    this.cal_CrossCP_core(this.c2h_trans);
    C2H_cov_grp.sample();
  end
  else if(trans.getTransType == ST_H2C) begin
    this.h2c_trans = trans;
    this.cal_CrossCP_core(this.h2c_trans);
    H2C_cov_grp.sample(); 
  end
endfunction



function void vdmatb_st_sb_cov_colctr::sampleArLen(logic[AXI_BURST_LENGTH_WIDTH-1:0] arlen);
  this.arlen = arlen;
  ar_burst_len.sample();
endfunction : sampleArLen



function void vdmatb_st_sb_cov_colctr::sampleAwLen(logic[AXI_BURST_LENGTH_WIDTH-1:0] awlen);
  this.awlen = awlen;
  aw_burst_len.sample();
endfunction : sampleAwLen




function void vdmatb_st_sb_cov_colctr::sampleWstrb(logic[HOST_DATA_BYTE_WIDTH-1:0] input_wstrb);
  this.num_0 = this.countWstrb_0(input_wstrb);
  this.num_1 = this.countWstrb_1(input_wstrb);
  wstrb.sample();
endfunction : sampleWstrb



function void vdmatb_st_sb_cov_colctr::setFaultHostBWrongRespSampleLst(SampleLstForFault_t sample_list);
  this.sample_lst_host_b_wrong_resp.following_trans = sample_list.following_trans;
  this.sample_lst_host_b_wrong_resp.gen_faultType   = sample_list.gen_faultType;
  this.sample_lst_host_b_wrong_resp.intended_fault  = sample_list.intended_fault;
endfunction : setFaultHostBWrongRespSampleLst



function void vdmatb_st_sb_cov_colctr::sampleFaultHostBWrongResp();
  cg_fault_host_b_wrong_resp.sample();
endfunction : sampleFaultHostBWrongResp



function void vdmatb_st_sb_cov_colctr::setFaultHostRWrongRespSampleLst(SampleLstForFault_t sample_list);
  this.sample_lst_host_r_wrong_resp.following_trans = sample_list.following_trans;
  this.sample_lst_host_r_wrong_resp.gen_faultType   = sample_list.gen_faultType;
  this.sample_lst_host_r_wrong_resp.intended_fault  = sample_list.intended_fault;
endfunction : setFaultHostRWrongRespSampleLst



function void vdmatb_st_sb_cov_colctr::sampleFaultHostRWrongResp();
  cg_fault_host_r_wrong_resp.sample();
endfunction : sampleFaultHostRWrongResp


// ----- len is zero
function void vdmatb_st_sb_cov_colctr::setC2HDescDataLenZeroFaultSampleLst_wo_followingTrans(SampleLstForFault_t sample_list);
  this.sample_lst_c2h_desc_data_length_is_zero_fault_wo_following_trans.gen_faultType   = sample_list.gen_faultType;
  this.sample_lst_c2h_desc_data_length_is_zero_fault_wo_following_trans.intended_fault  = sample_list.intended_fault;
endfunction 



function void vdmatb_st_sb_cov_colctr::sampleC2HDescDataLenZeroFault_wo_followingTrans();
  cg_c2h_desc_data_length_is_zero_fault_wo_following_trans.sample();
endfunction


function void vdmatb_st_sb_cov_colctr::setH2CDescDataLenZeroFaultSampleLst_wo_followingTrans(SampleLstForFault_t sample_list);
  this.sample_lst_h2c_desc_data_length_is_zero_fault_wo_following_trans.gen_faultType   = sample_list.gen_faultType;
  this.sample_lst_h2c_desc_data_length_is_zero_fault_wo_following_trans.intended_fault  = sample_list.intended_fault;
endfunction 



function void vdmatb_st_sb_cov_colctr::sampleH2CDescDataLenZeroFault_wo_followingTrans();
  cg_h2c_desc_data_length_is_zero_fault_wo_following_trans.sample();
endfunction 



function void vdmatb_st_sb_cov_colctr::setC2HDescDataLenZeroFaultSampleLst_with_followingTrans(SampleLstForFault_t sample_list);
  this.sample_lst_c2h_desc_data_length_is_zero_fault_with_following_trans.following_trans = sample_list.following_trans;
endfunction 



function void vdmatb_st_sb_cov_colctr::sampleC2HDescDataLenZeroFault_with_followingTrans();
  cg_c2h_desc_data_length_is_zero_fault_with_following_trans.sample();
endfunction


function void vdmatb_st_sb_cov_colctr::setH2CDescDataLenZeroFaultSampleLst_with_followingTrans(SampleLstForFault_t sample_list);
  this.sample_lst_h2c_desc_data_length_is_zero_fault_with_following_trans.following_trans = sample_list.following_trans;
endfunction 



function void vdmatb_st_sb_cov_colctr::sampleH2CDescDataLenZeroFault_with_followingTrans();
  cg_h2c_desc_data_length_is_zero_fault_with_following_trans.sample();
endfunction 
// ----- len is zero


function void vdmatb_st_sb_cov_colctr::setH2CDescFaultSampleLst(SampleLstForFault_t sample_list);
  this.sample_lst_h2c_desc_fault.following_trans = sample_list.following_trans;
  this.sample_lst_h2c_desc_fault.gen_faultType   = sample_list.gen_faultType;
  this.sample_lst_h2c_desc_fault.intended_fault  = sample_list.intended_fault;
endfunction : setH2CDescFaultSampleLst



function void vdmatb_st_sb_cov_colctr::sampleH2CDescFault();
  cg_h2c_desc_fault.sample();
endfunction : sampleH2CDescFault



function void vdmatb_st_sb_cov_colctr::setC2HCardFaultSampleLst(SampleLstForFault_t sample_list);
  this.sample_lst_c2h_card_fault.following_trans = sample_list.following_trans;
  this.sample_lst_c2h_card_fault.gen_faultType   = sample_list.gen_faultType;
  this.sample_lst_c2h_card_fault.intended_fault  = sample_list.intended_fault;
endfunction : setC2HCardFaultSampleLst



function void vdmatb_st_sb_cov_colctr::sampleC2HCardFault();
  cg_c2h_card_fault.sample();
endfunction : sampleC2HCardFault




function void vdmatb_st_sb_cov_colctr::setFaultHostRNoLastSampleLst(SampleLstForFault_t sample_list);
  this.sample_lst_host_r_no_last.following_trans = sample_list.following_trans;  
  this.sample_lst_host_r_no_last.gen_faultType   = sample_list.gen_faultType;  
  this.sample_lst_host_r_no_last.intended_fault  = sample_list.intended_fault;  
endfunction : setFaultHostRNoLastSampleLst


function void vdmatb_st_sb_cov_colctr::sampleFaultHostRNoLast();
  cg_fault_host_r_no_last.sample();  
endfunction : sampleFaultHostRNoLast



function void vdmatb_st_sb_cov_colctr::setFaultHostRPrematureLastSampleLst(SampleLstForFault_t sample_list);
  this.sample_lst_host_r_premature_last.following_trans = sample_list.following_trans;  
  this.sample_lst_host_r_premature_last.gen_faultType   = sample_list.gen_faultType;  
  this.sample_lst_host_r_premature_last.intended_fault  = sample_list.intended_fault;  
endfunction : setFaultHostRPrematureLastSampleLst


function void vdmatb_st_sb_cov_colctr::sampleFaultHostRPrematureLast();
  cg_fault_host_r_premature_last.sample();  
endfunction : sampleFaultHostRPrematureLast


`endif //__VDMATB_ST_SB_COV_COLCTR_SVH__
