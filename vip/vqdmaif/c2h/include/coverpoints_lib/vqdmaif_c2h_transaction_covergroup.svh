`ifndef __VQDMAIF_C2H_TRANSACTION_COVERGROUP_SVH__
`define __VQDMAIF_C2H_TRANSACTION_COVERGROUP_SVH__

// Package-scope covergroup type for C2H transaction coverage.
// Constructed in vqdmaif_c2h_coverage_collector::end_of_elaboration_phase
// with config-driven max_addr (bins sized to actual ADDR_WIDTH).
covergroup CG_C2H_TRANS (QdmaAddr_t max_addr) with function sample(ref vqdmaif_c2h_transaction c2h_trans, ref vqdmaif_c2h_cfg cfg);
  option.per_instance = 1;
  `include "vqdmaif_c2h_transaction_coverpoints.svh"
endgroup

`endif // __VQDMAIF_C2H_TRANSACTION_COVERGROUP_SVH__
