`ifndef __VDMATB_SCFG_SVH__
`define __VDMATB_SCFG_SVH__


class vdmatb_scfg extends vt4_scfg;

  vdma_mst_tcfg mst_tcfg;

  PerfTestCtrlKnob_t perf_ctrl_knob;
 	PerfExpected_t     perf_expected;

  `uvm_object_utils(vdmatb_scfg)

  function new(string name="vdmatb_scfg");
    super.new(name);
  endfunction

  extern virtual function void setDefaultPlan();
  extern virtual function void genPlan();
  extern virtual function void chk();
  extern virtual function StringQ_t getInfoList();

endclass:vdmatb_scfg


function void vdmatb_scfg::setDefaultPlan();
endfunction

function void      vdmatb_scfg::genPlan();        endfunction
function void      vdmatb_scfg::chk();            endfunction
function StringQ_t vdmatb_scfg::getInfoList();    endfunction




`endif // __VDMATB_SCFG_SVH__
