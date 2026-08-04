`ifndef __VQDMAIF_H2C_TRANSACTION_COVERGROUP_SVH__
`define __VQDMAIF_H2C_TRANSACTION_COVERGROUP_SVH__

// Package-scope covergroup type for H2C CMD coverage.
// Constructed in vqdmaif_h2c_coverage_collector::end_of_elaboration_phase
// with config-driven max_addr (bins sized to actual ADDR_WIDTH).
covergroup CG_H2C_CMD (QdmaAddr_t max_addr) with function sample(ref vqdmaif_h2c_sub_transaction h2c_sub_trans, ref vqdmaif_h2c_cfg cfg);
  option.per_instance = 1;
  `include "vqdmaif_h2c_transaction_coverpoints.svh"
endgroup

`endif // __VQDMAIF_H2C_TRANSACTION_COVERGROUP_SVH__
