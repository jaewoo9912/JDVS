`ifndef  __VDMA_ST_VSEQ_LIB_SVH__
`define  __VDMA_ST_VSEQ_LIB_SVH__


	`include "vdmatb_random_vseq.svh"
	`include "vdmatb_h2c_random_vseq.svh"
	`include "vdmatb_c2h_random_vseq.svh"

	`include "vdmatb_h2c_gathering_vseq.svh"

	`include "vdmatb_h2c_small_gathering_vseq.svh"

	`include "vdmatb_split_max_hburst_vseq.svh"
	`include "vdmatb_incr_max_hburst_len_with_max_len_vseq.svh"
	`include "vdmatb_incr_max_hburst_len_with_max_len_for_cov_1st_vseq.svh"
	`include "vdmatb_incr_max_hburst_len_with_max_len_for_cov_2nd_vseq.svh"

	`include "vdmatb_addr_boundary_vseq.svh"
	`include "vdmatb_axi_user_boundary_vseq.svh"
	`include "vdmatb_data_boundary_vseq.svh"

	`include "vdmatb_small_len_in_byte_vseq.svh"
	`include "vdmatb_c2h_small_len_in_byte_vseq.svh"
	`include "vdmatb_c2h_small_len_for_zero_split_vseq.svh"
	`include "vdmatb_h2c_small_len_in_byte_vseq.svh"

	`include "vdmatb_c2h_bvalid_to_bready_delay_vseq.svh"

	`include "vdmatb_max_len_vseq.svh"
	`include "vdmatb_max_len_with_1st_addr_zero_vseq.svh"
	`include "vdmatb_max_len_with_1st_addr_zero_len_fff_ffbf_vseq.svh"
	`include "vdmatb_max_len_for_cov_vseq.svh"

	`include "vdmatb_asymmetric_latency_vseq.svh"

	`include "vdmatb_desc_back_pressure_for_num_entry_cov_vseq.svh"
        `include "vdmatb_rdy_signal_state_for_func_cov_vseq.svh"
	`include "vdmatb_c2h_full_start_w_fifo_vseq.svh"

  `include "vdmatb_c2h_512mib_addr_aligned_vseq.svh"

	// TODO:Alpha
	`include "vdmatb_h2c_c2h_vseq.svh"

// Fault Vseq
	`include "vdmatb_fault_desc_mid_pkt_before_start_pkt_vseq.svh"
	`include "vdmatb_fault_desc_solo_pkt_during_gathering_vseq.svh"
	`include "vdmatb_fault_desc_start_pkt_during_gathering_vseq.svh"
	`include "vdmatb_fault_desc_end_pkt_before_start_pkt_vseq.svh"

	`include "vdmatb_fault_card_r_wrong_mty_vseq.svh"
	`include "vdmatb_fault_card_r_no_last_vseq.svh"
	`include "vdmatb_fault_card_r_premature_last_vseq.svh"
	`include "vdmatb_fault_host_r_no_last_vseq.svh"
	`include "vdmatb_fault_host_r_premature_last_vseq.svh"
	`include "vdmatb_fault_desc_data_length_is_zero_vseq.svh"
	
        `include "vdmatb_fault_card_r_wrong_resp_vseq.svh"
        `include "vdmatb_fault_card_b_wrong_resp_vseq.svh"

	`include "vdmatb_fault_host_r_wrong_resp_vseq.svh"
	`include "vdmatb_fault_host_b_wrong_resp_vseq.svh"
	
	`include "vdmatb_fault_card_r_wrong_dma_id_vseq.svh"

	`include "vdmatb_fault_constrained_random_vseq.svh"
	`include "vdmatb_fault_all_random_vseq.svh"

        `include "vdmatb_fault_cover_all_dma_id_bits_from_desc_fault_vseq.svh"
        `include "vdmatb_fault_cover_all_dma_id_bits_from_card_fault_vseq.svh"
        `include "vdmatb_fault_cover_all_dma_id_bits_from_host_fault_vseq.svh"
// Inter-Reset Vseq
	`include "vdmatb_inter_reset_vseq.svh"

// Perf Vseq
	`include "vdmatb_perf_vseq.svh"
`endif // __VDMA_ST_VSEQ_LIB_SVH__
