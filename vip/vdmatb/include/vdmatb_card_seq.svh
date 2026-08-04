`ifndef __VDMATB_CARD_SEQ_SVH__
`define __VDMATB_CARD_SEQ_SVH__



virtual class vdmatb_card_seq extends vaxi_slv_seq;

  vdmatb_tcfg tcfg;
  vdmatb_scfg scfg;
  
	bit enable_aw_to_b_delay;
	bit enable_ar_to_r_delay;
	int prob_slv_min_max;

	function new(string name="vdmatb_card_seq");
		super.new(name);
	endfunction

  // -------------------------------- vaxi_slv_seq-impl; 
	extern virtual protected task doSend();
  extern virtual function void setDefaultCfg();


  // ----------------------------------- vdmatb_card_seq-impl
  extern protected function void setupDelayType_AsymmetricLatency();


  // ----------------------------------- internal-impl
  extern local function void setupDelayType_IDEAL();
  extern local function void setupDelayType_ON_DELAY_WO_RESP();
  extern local function void setupDelayType_FOR_REGRESSION();
  
 
endclass:vdmatb_card_seq




// TODO:Refactoring w/ small pcieces of methods
task vdmatb_card_seq::doSend();
  AxiSlvTrans_t found;

  bit rdata_prob[2**`SVT_AXI_MAX_BURST_LENGTH_WIDTH];
  bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rdata_max = (1 << `SVT_AXI_MAX_DATA_WIDTH) -1;
  int rvalid_max,rvalid_min,first_rvalid_max,first_rvalid_min;
  int addr_read_ready_delay_max,addr_read_ready_delay_min,addr_write_ready_delay_max,addr_write_ready_delay_min;
  int wready_min,wready_max;
  int bvalid_min,bvalid_max;
  
  this.sink_responses();
  forever begin
    foreach (rdata_prob[i]) rdata_prob[i] = FlipCoin(this.prob_slv_min_max);

    this.p_sequencer.response_request_port.peek(found);
    found.random_interleave_array = new[found.burst_length];
    $cast(this.req, found);

    if(req.xact_type == AxiTrans_t::READ)begin
      case(this.rgen_addr_read_ready_delay_type.gen)
	RGS_AXI_ADDR_READ_READY_RANDOM_DELAY : begin 
          this.debug("[CARD_AXI_LATENCY] AR_READY_DELAY_TYPE : RANDOM_DELAY");
          addr_read_ready_delay_min = 0;
          addr_read_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY;
        end
        RGS_AXI_ADDR_READ_READY_NORMAL_DELAY : begin
          this.debug("[CARD_AXI_LATENCY] AR_READY_DELAY_TYPE : NORMAL_DELAY");
          if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY;
          end
          else if(this.tcfg.test_type != ASYMMETRIC_LATENCY_TEST) begin
            if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
              addr_read_ready_delay_min = 0;
              addr_read_ready_delay_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 4;;
            end// ON_DELAY_WO_RESP
            else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
              addr_read_ready_delay_min = 0;
              addr_read_ready_delay_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 16;
            end//FOR_REGRESSION
          end//NOT ASYMMETRIC_LATENCY_TEST
        end//RGS_NORMAL
	RGS_AXI_ADDR_READ_READY_ZERO_DELAY   : begin
          this.debug("[CARD_AXI_LATENCY] AR_READY_DELAY_TYPE : ZERO_DELAY");
          addr_read_ready_delay_min = 0;
          addr_read_ready_delay_max = 0;  
        end
	RGS_AXI_ADDR_READ_READY_LONG_DELAY   : begin
          this.debug("[CARD_AXI_LATENCY] AR_READY_DELAY_TYPE : LONG_DELAY");
          addr_read_ready_delay_min = `SVT_AXI_MAX_ADDR_DELAY/2;
          addr_read_ready_delay_max =  `SVT_AXI_MAX_ADDR_DELAY; 
        end
	default : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
      endcase

      case(this.rgen_read_valid_delay_type.gen)
        RGS_AXI_READ_VALID_RANDOM_DELAY  : begin
          this.debug("[CARD_AXI_LATENCY] R_VALID_DELAY_TYPE : RANDOM_DELAY");
          rvalid_min = 0; 
          rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 2; 
        end
	RGS_AXI_READ_VALID_NORMAL_DELAY  : begin
          this.debug("[CARD_AXI_LATENCY] R_VALID_DELAY_TYPE : NORMAL_DELAY");
          if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
            rvalid_min = 0;
            rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 4;
          end//ASYMMETRIC_LATENCY_TEST
          else if(this.tcfg.test_type != ASYMMETRIC_LATENCY_TEST) begin
            if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
              rvalid_min = 0; 
              rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 4; 
            end// ON_DELAY_WO_RESP
            else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
              rvalid_min = 0;
              rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 16; 
            end// FOR_REGRESSION
          end//NOT ASYMMETRIC_LATENCY_TEST
        end
	RGS_AXI_READ_VALID_ZERO_DELAY    : begin 
          this.debug("[CARD_AXI_LATENCY] R_VALID_DELAY_TYPE : ZERO_DELAY");
          rvalid_min = 0; 
          rvalid_max = 0; 
        end
	RGS_AXI_READ_VALID_LONG_DELAY    : begin
          this.debug("[CARD_AXI_LATENCY] R_VALID_DELAY_TYPE : LONG_DELAY");
          rvalid_min =`SVT_AXI_MAX_AXI3_GENERIC_DELAY / 4 + 1;
          rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 2; 
        end
	default : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
      endcase

      case(this.rgen_first_read_valid_delay_type.gen)
        RGS_AXI_FIRST_READ_VALID_RANDOM_DELAY  : begin 
          this.debug("[CARD_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : RANDOM_DELAY");
          first_rvalid_min = 0; 
          first_rvalid_max = `SVT_AXI_MAX_RVALID_DELAY; 
        end
	RGS_AXI_FIRST_READ_VALID_NORMAL_DELAY  : begin 
          this.debug("[CARD_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : NORMAL_DELAY");
          if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
            first_rvalid_min = `SVT_AXI_MAX_AXI3_GENERIC_DELAY * 2;
            first_rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY * 4;
          end//ASYMMETRIC_LATENCY_TEST
          else if(this.tcfg.test_type != ASYMMETRIC_LATENCY_TEST) begin
            if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
              first_rvalid_min = 0; 
              first_rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 16; 
            end // ON_DELAY_WO_RESP
            else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
              first_rvalid_min = 0;
              first_rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 16; 
            end// FOR_REGRESSION
          end//NOT ASYMMETRIC_LATENCY_TEST
        end
	RGS_AXI_FIRST_READ_VALID_ZERO_DELAY    : begin 
          this.debug("[CARD_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : ZERO_DELAY");
          first_rvalid_min = 0;
          first_rvalid_max = 0;
        end
	RGS_AXI_FIRST_READ_VALID_LONG_DELAY    : begin
          this.debug("[CARD_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : LONG_DELAY");
          first_rvalid_min = 5000;
          first_rvalid_max = `SVT_AXI_MAX_RVALID_DELAY; 
        end
	default : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
      endcase
      
      `uvm_rand_send_with(this.req,
       {enable_interleave == 1;
	  foreach(random_interleave_array[i]){
	    random_interleave_array[i] == 1;
	}
	foreach(data[i]) {
	  if (rdata_prob[i])  data[i] inside {0, rdata_max};
	  else                data[i] inside {[0:rdata_max]};
	}
	foreach(rresp[i]) {
	  rresp[i] inside {AxiSlvTrans_t::OKAY };
	}
        foreach(rvalid_delay[i]) {
	  if (i == 0) rvalid_delay[i] inside {[first_rvalid_min:first_rvalid_max]};
	  else        rvalid_delay[i] inside {[rvalid_min:(rvalid_max)]};
	}
	addr_ready_delay inside {[addr_read_ready_delay_min:addr_read_ready_delay_max]};
        })
  end


  if(req.xact_type == AxiTrans_t::WRITE)begin
    case(this.rgen_addr_write_ready_delay_type.gen)
      RGS_AXI_ADDR_WRITE_READY_RANDOM_DELAY : begin
        this.debug("[CARD_AXI_LATENCY] AW_READY_DELAY_TYPE : RANDOM_DELAY");
        addr_write_ready_delay_min = 0;
        addr_write_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY;
      end
      RGS_AXI_ADDR_WRITE_READY_NORMAL_DELAY : begin
        this.debug("[CARD_AXI_LATENCY] AW_READY_DELAY_TYPE : NORMAL_DELAY");
        if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
          addr_write_ready_delay_min = 0;
          addr_write_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY / 4;
        end//ASYMMETRIC_LATENCY_TEST
        else if(this.tcfg.test_type != ASYMMETRIC_LATENCY_TEST) begin
          if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
            addr_write_ready_delay_min = 0; 
            addr_write_ready_delay_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 4; 
          end // ON_DELAY_WO_RESP
          else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 16; 
          end// FOR_REGRESSION
        end//NOT ASYMMETRIC_LATENCY_TEST
      end
      RGS_AXI_ADDR_WRITE_READY_ZERO_DELAY   : begin
        this.debug("[CARD_AXI_LATENCY] AW_READY_DELAY_TYPE : ZERO_DELAY");
        addr_write_ready_delay_min = 0;
        addr_write_ready_delay_max = 0;
      end
      RGS_AXI_ADDR_WRITE_READY_LONG_DELAY   : begin
        this.debug("[CARD_AXI_LATENCY] AW_READY_DELAY_TYPE : LONG_DELAY");
        addr_write_ready_delay_min = `SVT_AXI_MAX_ADDR_DELAY/2;
        addr_write_ready_delay_max =  `SVT_AXI_MAX_ADDR_DELAY;
      end
      default : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
    endcase

    case (this.rgen_write_ready_delay_type.gen)
      RGS_AXI_WRITE_READY_RANDOM_DELAY    : begin 
        this.debug("[CARD_AXI_LATENCY] W_READY_DELAY_TYPE : RANDOM_DELAY");
        wready_min = 0;
        wready_max = `SVT_AXI_MAX_WREADY_DELAY;
      end
      RGS_AXI_WRITE_READY_NORMAL_DELAY    : begin
        this.debug("[CARD_AXI_LATENCY] W_READY_DELAY_TYPE : NORMAL_DELAY");
        if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
          wready_min = 0;
          wready_max = `SVT_AXI_MAX_WREADY_DELAY / 2;
        end//ASYMMETRIC_LATENCY_TEST
        else if(this.tcfg.test_type != ASYMMETRIC_LATENCY_TEST) begin
          if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
            wready_min = 0; 
            wready_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 4; 
          end// ON_DELAY_WO_RESP
          else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
            wready_min = 0;
            wready_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 16; 
          end// FOR_REGRESSION
        end//NOT_ASYMMETRIC_LATENCY_TEST
      end
      RGS_AXI_WRITE_READY_FAST_DELAY      : begin
        this.debug("[CARD_AXI_LATENCY] W_READY_DELAY_TYPE : ZERO_DELAY");
        wready_min = 0;
        wready_max = 0;
      end
      RGS_AXI_WRITE_READY_SLOW_DELAY      : begin 
        this.debug("[CARD_AXI_LATENCY] W_READY_DELAY_TYPE : LONG_DELAY");
        wready_min = `SVT_AXI_MAX_WREADY_DELAY/2 + 1;
        wready_max = `SVT_AXI_MAX_WREADY_DELAY; 
      end
      default : this.fatal("VMG_ERROR", $sformatf("rgen_slv_ready_delay_type result is illegal!!"));
    endcase

    case (this.rgen_write_resp_valid_delay_type.gen)
      RGS_AXI_WRITE_RESP_VALID_RANDOM_DELAY : begin 
        this.debug("[CARD_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : RANDOM_DELAY");
        bvalid_min = 0;
        bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY; 
      end
      RGS_AXI_WRITE_RESP_VALID_NORMAL_DELAY : begin 
        this.debug("[CARD_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : NORMAL_DELAY");
        if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
          bvalid_min = `SVT_AXI_MAX_WRITE_RESP_DELAY / 200 + 3;
          bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 100 + 6;
        end//ASYMMETRIC_LATENCY_TEST
        else if(this.tcfg.test_type != ASYMMETRIC_LATENCY_TEST) begin
          if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
            bvalid_min = 0; 
            bvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY * 16 / 64;
          end// ON_DELAY_WO_RESP
          else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
            bvalid_min = 0; 
            bvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY * 16 / 256; 
          end// FOR_REGRESSION
        end//NOT ASYMMTERIC_LATENCY_TEST
      end
      RGS_AXI_WRITE_RESP_VALID_FAST_DELAY   : begin
        this.debug("[CARD_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : ZERO_DELAY");
        bvalid_min = 0;
        bvalid_max = 0; 
      end
      RGS_AXI_WRITE_RESP_VALID_SLOW_DELAY   : begin 
        this.debug("[CARD_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : LONG_DELAY");
        bvalid_min = `SVT_AXI_MAX_WRITE_RESP_DELAY;
        bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY; 
      end
      default : this.fatal("VMG_ERROR", $sformatf("rgen_slv_resp_delay result is illegal!!"));
    endcase
    
    `uvm_rand_send_with(this.req,
    {
      enable_interleave == 1;
      reference_event_for_bvalid_delay == ADDR_HANDSHAKE;
      foreach(random_interleave_array[i]){
        random_interleave_array[i] == 1;
      }
      foreach(wready_delay[i]) {
 	wready_delay[i] inside {[wready_min:wready_max]};
      }
      if (enable_aw_to_b_delay) bvalid_delay inside {bvalid_max};
      else                      bvalid_delay inside {[bvalid_min:bvalid_max]};
      bresp inside {AxiSlvTrans_t::OKAY };
      addr_ready_delay inside {[addr_write_ready_delay_min:addr_write_ready_delay_max]};
    })
    end
   
  end
  
endtask:doSend



function void vdmatb_card_seq::setupDelayType_IDEAL();
  this.rgs_addr_read_ready_delay_type    = RGS_PRESET;
  this.preset_addr_read_ready_delay_type = RGS_AXI_ADDR_READ_READY_ZERO_DELAY;
  this.min_addr_read_ready_delay_type    = RGS_AXI_ADDR_READ_READY_RANDOM_DELAY;
  this.max_addr_read_ready_delay_type    = RGS_AXI_ADDR_READ_READY_LONG_DELAY;

  this.rgs_addr_write_ready_delay_type    = RGS_PRESET;
  this.preset_addr_write_ready_delay_type = RGS_AXI_ADDR_WRITE_READY_ZERO_DELAY;
  this.min_addr_write_ready_delay_type    = RGS_AXI_ADDR_WRITE_READY_RANDOM_DELAY;
  this.max_addr_write_ready_delay_type    = RGS_AXI_ADDR_WRITE_READY_LONG_DELAY;

  this.rgs_read_valid_delay_type    = RGS_PRESET;
  this.preset_read_valid_delay_type = RGS_AXI_READ_VALID_ZERO_DELAY;
  this.min_read_valid_delay_type    = RGS_AXI_READ_VALID_RANDOM_DELAY;
  this.max_read_valid_delay_type    = RGS_AXI_READ_VALID_LONG_DELAY;

  this.rgs_first_read_valid_delay_type    = RGS_PRESET;
  this.preset_first_read_valid_delay_type = RGS_AXI_FIRST_READ_VALID_ZERO_DELAY;
  this.min_first_read_valid_delay_type    = RGS_AXI_FIRST_READ_VALID_RANDOM_DELAY;
  this.max_first_read_valid_delay_type    = RGS_AXI_FIRST_READ_VALID_LONG_DELAY;

  this.rgs_write_ready_delay_type     = RGS_PRESET;
  this.preset_write_ready_delay_type  = RGS_AXI_WRITE_READY_FAST_DELAY;
  this.min_write_ready_delay_type     = RGS_AXI_WRITE_READY_RANDOM_DELAY;
  this.max_write_ready_delay_type     = RGS_AXI_WRITE_READY_SLOW_DELAY;

  this.rgs_write_resp_valid_delay_type      = RGS_PRESET;
  this.preset_write_resp_valid_delay_type   = RGS_AXI_WRITE_RESP_VALID_FAST_DELAY;
  this.min_write_resp_valid_delay_type      = RGS_AXI_WRITE_RESP_VALID_RANDOM_DELAY;
  this.max_write_resp_valid_delay_type      = RGS_AXI_WRITE_RESP_VALID_SLOW_DELAY;
endfunction:setupDelayType_IDEAL




function void vdmatb_card_seq::setupDelayType_ON_DELAY_WO_RESP();
  this.rgs_addr_read_ready_delay_type    = RGS_PRESET;
  this.preset_addr_read_ready_delay_type = RGS_AXI_ADDR_READ_READY_NORMAL_DELAY;
  this.min_addr_read_ready_delay_type    = RGS_AXI_ADDR_READ_READY_RANDOM_DELAY;
  this.max_addr_read_ready_delay_type    = RGS_AXI_ADDR_READ_READY_LONG_DELAY;
  
  this.rgs_addr_write_ready_delay_type    = RGS_PRESET;
  this.preset_addr_write_ready_delay_type = RGS_AXI_ADDR_WRITE_READY_NORMAL_DELAY;
  this.min_addr_write_ready_delay_type    = RGS_AXI_ADDR_WRITE_READY_RANDOM_DELAY;
  this.max_addr_write_ready_delay_type    = RGS_AXI_ADDR_WRITE_READY_LONG_DELAY;
  
  this.rgs_read_valid_delay_type    = RGS_PRESET;
  this.preset_read_valid_delay_type = RGS_AXI_READ_VALID_NORMAL_DELAY;
  this.min_read_valid_delay_type    = RGS_AXI_READ_VALID_RANDOM_DELAY;
  this.max_read_valid_delay_type    = RGS_AXI_READ_VALID_LONG_DELAY;
  
  this.rgs_first_read_valid_delay_type    = RGS_PRESET;
  this.preset_first_read_valid_delay_type = RGS_AXI_FIRST_READ_VALID_NORMAL_DELAY;
  this.min_first_read_valid_delay_type    = RGS_AXI_FIRST_READ_VALID_RANDOM_DELAY;
  this.max_first_read_valid_delay_type    = RGS_AXI_FIRST_READ_VALID_LONG_DELAY;
  
  this.rgs_write_ready_delay_type     = RGS_PRESET;
  this.preset_write_ready_delay_type  = RGS_AXI_WRITE_READY_NORMAL_DELAY;
  this.min_write_ready_delay_type     = RGS_AXI_WRITE_READY_RANDOM_DELAY;
  this.max_write_ready_delay_type     = RGS_AXI_WRITE_READY_SLOW_DELAY;
  
  this.rgs_write_resp_valid_delay_type      = RGS_PRESET;
  this.preset_write_resp_valid_delay_type   = RGS_AXI_WRITE_RESP_VALID_NORMAL_DELAY;
  this.min_write_resp_valid_delay_type      = RGS_AXI_WRITE_RESP_VALID_RANDOM_DELAY;
  this.max_write_resp_valid_delay_type      = RGS_AXI_WRITE_RESP_VALID_SLOW_DELAY;
endfunction:setupDelayType_ON_DELAY_WO_RESP



//TODO : Update & Add tb_scheme
function void vdmatb_card_seq::setupDelayType_FOR_REGRESSION();
  this.rgs_addr_read_ready_delay_type    = RGS_PRESET;
  this.preset_addr_read_ready_delay_type = RGS_AXI_ADDR_READ_READY_NORMAL_DELAY;
  this.min_addr_read_ready_delay_type    = RGS_AXI_ADDR_READ_READY_RANDOM_DELAY;
  this.max_addr_read_ready_delay_type    = RGS_AXI_ADDR_READ_READY_LONG_DELAY;
  
  this.rgs_addr_write_ready_delay_type    = RGS_PRESET;
  this.preset_addr_write_ready_delay_type = RGS_AXI_ADDR_WRITE_READY_NORMAL_DELAY;
  this.min_addr_write_ready_delay_type    = RGS_AXI_ADDR_WRITE_READY_RANDOM_DELAY;
  this.max_addr_write_ready_delay_type    = RGS_AXI_ADDR_WRITE_READY_LONG_DELAY;
  
  this.rgs_read_valid_delay_type    = RGS_PRESET;
  this.preset_read_valid_delay_type = RGS_AXI_READ_VALID_NORMAL_DELAY;
  this.min_read_valid_delay_type    = RGS_AXI_READ_VALID_RANDOM_DELAY;
  this.max_read_valid_delay_type    = RGS_AXI_READ_VALID_LONG_DELAY;
  
  this.rgs_first_read_valid_delay_type    = RGS_PRESET;
  this.preset_first_read_valid_delay_type = RGS_AXI_FIRST_READ_VALID_NORMAL_DELAY;
  this.min_first_read_valid_delay_type    = RGS_AXI_FIRST_READ_VALID_RANDOM_DELAY;
  this.max_first_read_valid_delay_type    = RGS_AXI_FIRST_READ_VALID_LONG_DELAY;
  
  this.rgs_write_ready_delay_type     = RGS_PRESET;
  this.preset_write_ready_delay_type  = RGS_AXI_WRITE_READY_NORMAL_DELAY;
  this.min_write_ready_delay_type     = RGS_AXI_WRITE_READY_RANDOM_DELAY;
  this.max_write_ready_delay_type     = RGS_AXI_WRITE_READY_SLOW_DELAY;
  
  this.rgs_write_resp_valid_delay_type      = RGS_PRESET;
  this.preset_write_resp_valid_delay_type   = RGS_AXI_WRITE_RESP_VALID_NORMAL_DELAY;
  this.min_write_resp_valid_delay_type      = RGS_AXI_WRITE_RESP_VALID_RANDOM_DELAY;
  this.max_write_resp_valid_delay_type      = RGS_AXI_WRITE_RESP_VALID_SLOW_DELAY;
endfunction:setupDelayType_FOR_REGRESSION



function void vdmatb_card_seq::setDefaultCfg();
	this.enable_aw_to_b_delay = 0;
	this.enable_ar_to_r_delay = 0;
  this.prob_slv_min_max = 5;

  case(this.tcfg.tb_scheme)
    IDEAL            : this.setupDelayType_IDEAL();
    ON_DELAY_WO_RESP : this.setupDelayType_ON_DELAY_WO_RESP();
    FOR_REGRESSION   : this.setupDelayType_FOR_REGRESSION();
    // --------------------------------------
    default: this.fatalShallImpl($sformatf("setDefaultCfg -- tb_scheme=%s", this.tcfg.tb_scheme.name));
  endcase
endfunction:setDefaultCfg



function void vdmatb_card_seq::setupDelayType_AsymmetricLatency();
  this.rgs_addr_read_ready_delay_type    = RGS_RANDOM_PER_SEQ;
  this.preset_addr_read_ready_delay_type = RGS_AXI_ADDR_READ_READY_RANDOM_DELAY;
  this.min_addr_read_ready_delay_type    = RGS_AXI_ADDR_READ_READY_RANDOM_DELAY;
  this.max_addr_read_ready_delay_type    = RGS_AXI_ADDR_READ_READY_LONG_DELAY;
  
  this.rgs_addr_write_ready_delay_type    = RGS_RANDOM_PER_SEQ;
  this.preset_addr_write_ready_delay_type = RGS_AXI_ADDR_WRITE_READY_RANDOM_DELAY;
  this.min_addr_write_ready_delay_type    = RGS_AXI_ADDR_WRITE_READY_RANDOM_DELAY;
  this.max_addr_write_ready_delay_type    = RGS_AXI_ADDR_WRITE_READY_LONG_DELAY;
  
  this.rgs_read_valid_delay_type    = RGS_RANDOM_PER_SEQ;
  this.preset_read_valid_delay_type = RGS_AXI_READ_VALID_RANDOM_DELAY;
  this.min_read_valid_delay_type    = RGS_AXI_READ_VALID_RANDOM_DELAY;
  this.max_read_valid_delay_type    = RGS_AXI_READ_VALID_LONG_DELAY;
  
  this.rgs_first_read_valid_delay_type    = RGS_RANDOM_PER_SEQ;
  this.preset_first_read_valid_delay_type = RGS_AXI_FIRST_READ_VALID_RANDOM_DELAY;
  this.min_first_read_valid_delay_type    = RGS_AXI_FIRST_READ_VALID_RANDOM_DELAY;
  this.max_first_read_valid_delay_type    = RGS_AXI_FIRST_READ_VALID_LONG_DELAY;
  
  this.rgs_write_ready_delay_type     = RGS_RANDOM_PER_SEQ;
  this.preset_write_ready_delay_type  = RGS_AXI_WRITE_READY_RANDOM_DELAY;
  this.min_write_ready_delay_type     = RGS_AXI_WRITE_READY_RANDOM_DELAY;
  this.max_write_ready_delay_type     = RGS_AXI_WRITE_READY_SLOW_DELAY;
  
  this.rgs_write_resp_valid_delay_type      = RGS_RANDOM_PER_SEQ;
  this.preset_write_resp_valid_delay_type   = RGS_AXI_WRITE_RESP_VALID_RANDOM_DELAY;
  this.min_write_resp_valid_delay_type      = RGS_AXI_WRITE_RESP_VALID_RANDOM_DELAY;
  this.max_write_resp_valid_delay_type      = RGS_AXI_WRITE_RESP_VALID_SLOW_DELAY;
endfunction:setupDelayType_AsymmetricLatency


`endif // __VDMATB_CARD_SEQ_SVH__
