`ifndef __VDMATB_CARD_SEQ_LIB_SVH__
`define __VDMATB_CARD_SEQ_LIB_SVH__





class vdmatb_card_default_seq extends vdmatb_card_seq;

  `uvm_object_utils(vdmatb_card_default_seq)
  function new(string name="vdmatb_card_default_seq");
    super.new(name);
  endfunction

endclass:vdmatb_card_default_seq




class vdmatb_card_asymmetric_latency_seq extends vdmatb_card_seq;

  `uvm_object_utils(vdmatb_card_asymmetric_latency_seq)
  function new(string name="vdmatb_card_asymmetric_latency_seq");
    super.new(name);
  endfunction

  virtual function void setDefaultCfg();
    super.setDefaultCfg();
    this.setupDelayType_AsymmetricLatency();
  endfunction

endclass:vdmatb_card_asymmetric_latency_seq




class vdmatb_card_data_boundary_seq extends vdmatb_card_seq;

  `uvm_object_utils(vdmatb_card_data_boundary_seq)
  function new(string name="vdmatb_card_data_boundary_seq");
    super.new(name);
  endfunction

  // TODO:NewFeature -- add data ready delay
  virtual task body();
	  AxiSlvTrans_t found;

	  this.sink_responses();

	  forever begin
	  	this.p_sequencer.response_request_port.peek(found);
	  	$cast(this.req, found);
	  	
	  	if(!this.req.randomize() with {
	  		foreach(rresp[i]) { rresp[i] inside { AxiSlvTrans_t::OKAY }; }
	  		                    bresp    inside { AxiSlvTrans_t::OKAY };
	  	})begin
        this.fatalRandomization("rresp or bresp randomization is failed !!");
      end
	  	
      if(req.xact_type == AxiTrans_t::READ)begin
        logic[`SVT_AXI_MAX_DATA_WIDTH - 1:0] data_value;

        data_value = 0;
        if(FlipCoin() == 1) data_value = '1;
	  	  foreach(this.req.data[i]) this.req.data[i] = data_value;
      end
	  	`uvm_send(this.req);
    end
  endtask:body

endclass:vdmatb_card_data_boundary_seq



class vdmatb_card_fault_card_b_wrong_resp_seq extends vdmatb_card_seq;

	`uvm_object_utils(vdmatb_card_fault_card_b_wrong_resp_seq)
	function new(string name="vdmatb_card_fault_card_b_wrong_resp_seq");
		super.new(name);
	endfunction

  virtual function void setDefaultCfg();
    super.setDefaultCfg();
    this.enable_aw_to_b_delay = FlipCoin();
  endfunction


  // TODO:DRY -- what's the difference with its base class?
	virtual protected task doSend();
    AxiSlvTrans_t found;

    bit rdata_prob[2**`SVT_AXI_MAX_BURST_LENGTH_WIDTH];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rdata_max = (1 << `SVT_AXI_MAX_DATA_WIDTH) -1;
    int rvalid_max,rvalid_min,first_rvalid_max,first_rvalid_min;
    int addr_read_ready_delay_max,addr_read_ready_delay_min,addr_write_ready_delay_max,addr_write_ready_delay_min;
    int wready_min,wready_max;
    int bvalid_min,bvalid_max;
    
    this.sink_responses();
    
    forever begin
      foreach (rdata_prob[i]) rdata_prob[i] = FlipCoin(prob_slv_min_max);

      this.p_sequencer.response_request_port.peek(found);
      found.random_interleave_array = new[found.burst_length];
      $cast(this.req, found);

      if(req.xact_type == AxiTrans_t::READ)begin
        case(this.rgen_addr_read_ready_delay_type.gen)
          RGS_AXI_ADDR_READ_READY_RANDOM_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : RANDOM_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY;
          end
          RGS_AXI_ADDR_READ_READY_NORMAL_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : ZERO_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = 0;  
          end
          RGS_AXI_ADDR_READ_READY_LONG_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : LONG_DELAY");
            addr_read_ready_delay_min = `SVT_AXI_MAX_ADDR_DELAY/2;
            addr_read_ready_delay_max =  `SVT_AXI_MAX_ADDR_DELAY; 
          end
          default                   : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
        endcase

        case(this.rgen_read_valid_delay_type.gen)
          RGS_AXI_READ_VALID_RANDOM_DELAY  : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : RANDOM_DELAY");
            rvalid_min = 0; 
            rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 2; 
          end
          RGS_AXI_READ_VALID_NORMAL_DELAY  : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : ZERO_DELAY");
            rvalid_min = 0; 
            rvalid_max = 0; 
          end
          RGS_AXI_READ_VALID_LONG_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : LONG_DELAY");
            rvalid_min =`SVT_AXI_MAX_AXI3_GENERIC_DELAY / 4 + 1;
            rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 2; 
          end
          default                             : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
        endcase

        case(this.rgen_first_read_valid_delay_type.gen)
          RGS_AXI_FIRST_READ_VALID_RANDOM_DELAY  : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : RANDOM_DELAY");
            first_rvalid_min = 0; 
            first_rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY * 4; 
          end
          RGS_AXI_FIRST_READ_VALID_NORMAL_DELAY  : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : ZERO_DELAY");
            first_rvalid_min = 0;
            first_rvalid_max = 0;
          end
          RGS_AXI_FIRST_READ_VALID_LONG_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : LONG_DELAY");
            first_rvalid_min = `SVT_AXI_MAX_RVALID_DELAY/2;
            first_rvalid_max = `SVT_AXI_MAX_RVALID_DELAY; 
          end
          default                             : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
        endcase
        `uvm_rand_send_with(this.req,
          {
            enable_interleave == 1;
            foreach(random_interleave_array[i]){
              random_interleave_array[i] == 1;
            }
            foreach(data[i]) {
              if (rdata_prob[i])  data[i] inside {0, rdata_max};
              else                data[i] inside {[0:rdata_max]};
            }
            foreach(rresp[i]) {
              rresp[i]  inside {AxiSlvTrans_t::OKAY };
            }

            foreach(rvalid_delay[i]) {
              if (i == 0) rvalid_delay[i] inside {[first_rvalid_min:first_rvalid_max]};
              else rvalid_delay[i] inside {[rvalid_min:(rvalid_max)]};
            }
            addr_ready_delay inside {[addr_read_ready_delay_min:addr_read_ready_delay_max]};
          })

      end
      if(req.xact_type == AxiTrans_t::WRITE)begin

        case(this.rgen_addr_write_ready_delay_type.gen)
          RGS_AXI_ADDR_WRITE_READY_RANDOM_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : RANDOM_DELAY");
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY;
          end
          RGS_AXI_ADDR_WRITE_READY_NORMAL_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : ZERO_DELAY");
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = 0;
          end
          RGS_AXI_ADDR_WRITE_READY_LONG_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : LONG_DELAY");
            addr_write_ready_delay_min = `SVT_AXI_MAX_ADDR_DELAY/2;
            addr_write_ready_delay_max =  `SVT_AXI_MAX_ADDR_DELAY;
          end
          default                   : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
        endcase

        case (this.rgen_write_ready_delay_type.gen)
          RGS_AXI_WRITE_READY_RANDOM_DELAY    : begin 
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : RANDOM_DELAY");
            wready_min = 0;
            wready_max = `SVT_AXI_MAX_WREADY_DELAY;
          end
          RGS_AXI_WRITE_READY_NORMAL_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : ZERO_DELAY");
            wready_min = 0;
            wready_max = 0;
          end
          RGS_AXI_WRITE_READY_SLOW_DELAY      : begin 
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : LONG_DELAY");
            wready_min = `SVT_AXI_MAX_WREADY_DELAY/2 + 1;
            wready_max = `SVT_AXI_MAX_WREADY_DELAY; 
          end
          default                           : this.fatal("VMG_ERROR", $sformatf("rgen_slv_ready_delay_type result is illegal!!"));
        endcase

        case (this.rgen_write_resp_valid_delay_type.gen)
          RGS_AXI_WRITE_RESP_VALID_RANDOM_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : RANDOM_DELAY");
            bvalid_min = 0;
            bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 32; 
          end
          RGS_AXI_WRITE_RESP_VALID_NORMAL_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : NORMAL_DELAY");
            if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
              bvalid_min = `SVT_AXI_MAX_WRITE_RESP_DELAY / 64;
              bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 64;
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
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : ZERO_DELAY");
            bvalid_min = 0;
            bvalid_max =  0; 
          end
          RGS_AXI_WRITE_RESP_VALID_SLOW_DELAY   : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : LONG_DELAY");
            bvalid_min = `SVT_AXI_MAX_WRITE_RESP_DELAY/64 + 1;
            bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 32; 
          end
          default                           : this.fatal("VMG_ERROR", $sformatf("rgen_slv_resp_delay result is illegal!!"));
        endcase
        
        `uvm_rand_send_with(this.req,
          {
            enable_interleave == 1;
            foreach(random_interleave_array[i]){
              random_interleave_array[i] == 1;
            }
            foreach(wready_delay[i]) {
              wready_delay[i] inside {[wready_min:wready_max]};
            }
            if (enable_aw_to_b_delay) 
              bvalid_delay inside {bvalid_max};
            else  bvalid_delay inside {[bvalid_min/32:bvalid_max/16]};
            bresp > 1;
            addr_ready_delay inside {[addr_write_ready_delay_min:addr_write_ready_delay_max]};
          })
      end
    end
  endtask:doSend

endclass:vdmatb_card_fault_card_b_wrong_resp_seq




class vdmatb_card_fault_card_r_wrong_resp_seq extends vdmatb_card_seq;

	`uvm_object_utils(vdmatb_card_fault_card_r_wrong_resp_seq)
	function new(string name="vdmatb_card_fault_card_r_wrong_resp_seq");
		super.new(name);
	endfunction

  virtual function void setDefaultCfg();
    super.setDefaultCfg();
    this.enable_aw_to_b_delay = FlipCoin();
    this.enable_aw_to_b_delay = $urandom_range(0, 1);
    this.prob_slv_min_max = 5;
  endfunction


  // TODO:DRY
  virtual protected task doSend();
    AxiSlvTrans_t found;
  
    bit rdata_prob[2**`SVT_AXI_MAX_BURST_LENGTH_WIDTH];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rdata_max = (1 << `SVT_AXI_MAX_DATA_WIDTH) -1;
    int rvalid_max,rvalid_min,first_rvalid_max,first_rvalid_min;
    int addr_read_ready_delay_max,addr_read_ready_delay_min,addr_write_ready_delay_max,addr_write_ready_delay_min;
    int wready_min,wready_max;
    int bvalid_min,bvalid_max;
    
    this.sink_responses();
    forever begin
      foreach (rdata_prob[i]) rdata_prob[i] = FlipCoin(prob_slv_min_max);
  
      this.p_sequencer.response_request_port.peek(found);
      found.random_interleave_array = new[found.burst_length];
      $cast(this.req, found);
  
  
      if(req.xact_type == AxiTrans_t::READ)begin
        case(this.rgen_addr_read_ready_delay_type.gen)
          RGS_AXI_ADDR_READ_READY_RANDOM_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : RANDOM_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY;
          end
          RGS_AXI_ADDR_READ_READY_NORMAL_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : ZERO_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = 0;  
          end
          RGS_AXI_ADDR_READ_READY_LONG_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : LONG_DELAY");
            addr_read_ready_delay_min = `SVT_AXI_MAX_ADDR_DELAY/2;
            addr_read_ready_delay_max =  `SVT_AXI_MAX_ADDR_DELAY; 
          end
          default                   : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
        endcase
  
        case(this.rgen_read_valid_delay_type.gen)
          RGS_AXI_READ_VALID_RANDOM_DELAY  : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : RANDOM_DELAY");
            rvalid_min = 0; 
            rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 2; 
          end
          RGS_AXI_READ_VALID_NORMAL_DELAY  : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : ZERO_DELAY");
            rvalid_min = 0; 
            rvalid_max = 0; 
          end
          RGS_AXI_READ_VALID_LONG_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : LONG_DELAY");
            rvalid_min =`SVT_AXI_MAX_AXI3_GENERIC_DELAY / 4 + 1;
            rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 2; 
          end
          default                             : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
        endcase
  
        case(this.rgen_first_read_valid_delay_type.gen)
          RGS_AXI_FIRST_READ_VALID_RANDOM_DELAY  : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : RANDOM_DELAY");
            first_rvalid_min = 0; 
            first_rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY * 4; 
          end
          RGS_AXI_FIRST_READ_VALID_NORMAL_DELAY  : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : ZERO_DELAY");
            first_rvalid_min = 0;
            first_rvalid_max = 0;
          end
          RGS_AXI_FIRST_READ_VALID_LONG_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : LONG_DELAY");
            first_rvalid_min = `SVT_AXI_MAX_RVALID_DELAY/2;
            first_rvalid_max = `SVT_AXI_MAX_RVALID_DELAY; 
          end
          default                             : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
        endcase
        `uvm_rand_send_with(this.req,
          {
            enable_interleave == 1;
            foreach(random_interleave_array[i]){
              random_interleave_array[i] == 1;
            }
            foreach(data[i]) {
              if (rdata_prob[i])  data[i] inside {0, rdata_max};
              else                data[i] inside {[0:rdata_max]};
            }
            foreach(rresp[i]) {
              rresp[i] > 1;
            }
  
            foreach(rvalid_delay[i]) {
              if (i == 0) rvalid_delay[i] inside {[first_rvalid_min:first_rvalid_max]};
              else rvalid_delay[i] inside {[rvalid_min:(rvalid_max)]};
            }
            addr_ready_delay inside {[addr_read_ready_delay_min:addr_read_ready_delay_max]};
          })
  
      end
      if(req.xact_type == AxiTrans_t::WRITE)begin
  
        case(this.rgen_addr_write_ready_delay_type.gen)
          RGS_AXI_ADDR_WRITE_READY_RANDOM_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : RANDOM_DELAY");
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY;
          end
          RGS_AXI_ADDR_WRITE_READY_NORMAL_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : ZERO_DELAY");
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = 0;
          end
          RGS_AXI_ADDR_WRITE_READY_LONG_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : LONG_DELAY");
            addr_write_ready_delay_min = `SVT_AXI_MAX_ADDR_DELAY/2;
            addr_write_ready_delay_max =  `SVT_AXI_MAX_ADDR_DELAY;
          end
          default                   : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
        endcase
  
        case (this.rgen_write_ready_delay_type.gen)
          RGS_AXI_WRITE_READY_RANDOM_DELAY    : begin 
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : RANDOM_DELAY");
            wready_min = 0;
            wready_max = `SVT_AXI_MAX_WREADY_DELAY;
          end
          RGS_AXI_WRITE_READY_NORMAL_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : ZERO_DELAY");
            wready_min = 0;
            wready_max = 0;
          end
          RGS_AXI_WRITE_READY_SLOW_DELAY      : begin 
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : LONG_DELAY");
            wready_min = `SVT_AXI_MAX_WREADY_DELAY/2 + 1;
            wready_max = `SVT_AXI_MAX_WREADY_DELAY; 
          end
          default                           : this.fatal("VMG_ERROR", $sformatf("rgen_slv_ready_delay_type result is illegal!!"));
        endcase
  
        case (this.rgen_write_resp_valid_delay_type.gen)
          RGS_AXI_WRITE_RESP_VALID_RANDOM_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : RANDOM_DELAY");
            bvalid_min = 0;
            bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 32; 
          end
          RGS_AXI_WRITE_RESP_VALID_NORMAL_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : NORMAL_DELAY");
            if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
              bvalid_min = `SVT_AXI_MAX_WRITE_RESP_DELAY / 64;
              bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 64;
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
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : ZERO_DELAY");
            bvalid_min = 0;
            bvalid_max =  0; 
          end
          RGS_AXI_WRITE_RESP_VALID_SLOW_DELAY   : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : LONG_DELAY");
            bvalid_min = `SVT_AXI_MAX_WRITE_RESP_DELAY/64 + 1;
            bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 32; 
          end
          default                           : this.fatal("VMG_ERROR", $sformatf("rgen_slv_resp_delay result is illegal!!"));
        endcase
        
        `uvm_rand_send_with(this.req,
          {
            enable_interleave == 1;
            foreach(random_interleave_array[i]){
              random_interleave_array[i] == 1;
            }
            foreach(wready_delay[i]) {
              wready_delay[i] inside {[wready_min:wready_max]};
            }
            if (enable_aw_to_b_delay) 
              bvalid_delay inside {bvalid_max};
            else  bvalid_delay inside {[bvalid_min/32:bvalid_max/16]};
            bresp inside {AxiSlvTrans_t::OKAY };
            addr_ready_delay inside {[addr_write_ready_delay_min:addr_write_ready_delay_max]};
          })
      end
     
    end
  endtask:doSend

endclass:vdmatb_card_fault_card_r_wrong_resp_seq






class vdmatb_card_perf_seq extends vdmatb_card_seq;
  
  `uvm_object_utils(vdmatb_card_perf_seq)
  function new(string name="vdmatb_card_perf_seq");
    super.new(name);
  endfunction

  virtual function void setDefaultCfg();
    super.setDefaultCfg();
    this.prob_slv_min_max = 5;
  endfunction:setDefaultCfg


  virtual protected task doSend();
    AxiSlvTrans_t found;
  
    bit rdata_prob[2**`SVT_AXI_MAX_BURST_LENGTH_WIDTH];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rdata_max = (1 << `SVT_AXI_MAX_DATA_WIDTH) -1;
    int rvalid_max,rvalid_min,first_rvalid_max,first_rvalid_min;
    int addr_read_ready_delay_max,addr_read_ready_delay_min,addr_write_ready_delay_max,addr_write_ready_delay_min;
    int wready_min,wready_max;
    int bvalid_min,bvalid_max;
    
    this.sink_responses();
    forever begin
      foreach (rdata_prob[i]) rdata_prob[i] = FlipCoin(prob_slv_min_max);
  
      this.p_sequencer.response_request_port.peek(found);
      found.random_interleave_array = new[found.burst_length];
      $cast(this.req, found);
  
  
      if(req.xact_type == AxiTrans_t::READ)begin
        case(this.rgen_addr_read_ready_delay_type.gen)
          RGS_AXI_ADDR_READ_READY_RANDOM_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : RANDOM_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = 0;
          end
          RGS_AXI_ADDR_READ_READY_NORMAL_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : NORMAL_DELAY");
            if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
              addr_read_ready_delay_min = 0;
              addr_read_ready_delay_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY;
            end
            else if(this.tcfg.test_type != ASYMMETRIC_LATENCY_TEST) begin
              if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
                addr_read_ready_delay_min = 0;
                addr_read_ready_delay_max = 0;
              end// ON_DELAY_WO_RESP
              else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
                addr_read_ready_delay_min = 0;
                addr_read_ready_delay_max = 0;
              end//FOR_REGRESSION
            end//NOT ASYMMETRIC_LATENCY_TEST
            
          end//RGS_NORMAL
          RGS_AXI_ADDR_READ_READY_ZERO_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : ZERO_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = 0;  
          end
          RGS_AXI_ADDR_READ_READY_LONG_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : LONG_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max =  0; 
          end
          default                   : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
        endcase
  
        case(this.rgen_read_valid_delay_type.gen)
          RGS_AXI_READ_VALID_RANDOM_DELAY  : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : RANDOM_DELAY");
            rvalid_min = 0; 
            rvalid_max = 0; 
          end
          RGS_AXI_READ_VALID_NORMAL_DELAY  : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : NORMAL_DELAY");
            if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
              rvalid_min = 0;
              rvalid_max = 0;
            end//ASYMMETRIC_LATENCY_TEST
            else if(this.tcfg.test_type != ASYMMETRIC_LATENCY_TEST) begin
              if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
                rvalid_min = 0; 
                rvalid_max = 0; 
              end// ON_DELAY_WO_RESP
              else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
                rvalid_min = 0;
                rvalid_max = 0; 
              end// FOR_REGRESSION
            end//NOT ASYMMETRIC_LATENCY_TEST
          end
          RGS_AXI_READ_VALID_ZERO_DELAY    : begin 
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : ZERO_DELAY");
            rvalid_min = 0; 
            rvalid_max = 0; 
          end
          RGS_AXI_READ_VALID_LONG_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : LONG_DELAY");
            rvalid_min = 0;
            rvalid_max = 0;
          end
          default                             : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
        endcase
  
        case(this.rgen_first_read_valid_delay_type.gen)
          RGS_AXI_FIRST_READ_VALID_RANDOM_DELAY  : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : RANDOM_DELAY");
            first_rvalid_min = 0; 
            first_rvalid_max = 0; 
          end
          RGS_AXI_FIRST_READ_VALID_NORMAL_DELAY  : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : NORMAL_DELAY");
            if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
              first_rvalid_min = `SVT_AXI_MAX_AXI3_GENERIC_DELAY * 2;
              first_rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY * 4;
            end//ASYMMETRIC_LATENCY_TEST
            else if(this.tcfg.test_type != ASYMMETRIC_LATENCY_TEST) begin
              if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
                first_rvalid_min = 0; 
                first_rvalid_max = 0; 
              end // ON_DELAY_WO_RESP
              else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
               first_rvalid_min = 0;
                 first_rvalid_max = 0; 
              end// FOR_REGRESSION
            end//NOT ASYMMETRIC_LATENCY_TEST
          end
          RGS_AXI_FIRST_READ_VALID_ZERO_DELAY    : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : ZERO_DELAY");
            first_rvalid_min = 0;
            first_rvalid_max = 0;
          end
          RGS_AXI_FIRST_READ_VALID_LONG_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : LONG_DELAY");
            first_rvalid_min = 0;
            first_rvalid_max = 0; 
          end
          default                             : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
        endcase
        `uvm_rand_send_with(this.req,
          {
            enable_interleave == 1;
            foreach(random_interleave_array[i]){
              random_interleave_array[i] == 1;
            }
            foreach(data[i]) {
              if (rdata_prob[i])  data[i] inside {0, rdata_max};
              else                data[i] inside {[0:rdata_max]};
            }
            foreach(rresp[i]) {
              rresp[i]  inside {AxiSlvTrans_t::OKAY };
            }
  
            foreach(rvalid_delay[i]) {
              if (i == 0) rvalid_delay[i] == scfg.perf_ctrl_knob.perf_card_side_data_latency;
              else rvalid_delay[i] inside {[0:0]};
            }
            addr_ready_delay inside {[0:0]};
          })
  
      end
      if(req.xact_type == AxiTrans_t::WRITE)begin
  
        case(this.rgen_addr_write_ready_delay_type.gen)
          RGS_AXI_ADDR_WRITE_READY_RANDOM_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : RANDOM_DELAY");
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = 0;
          end
          RGS_AXI_ADDR_WRITE_READY_NORMAL_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : NORMAL_DELAY");
            if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
              addr_write_ready_delay_min = 0;
              addr_write_ready_delay_max = 0;
            end//ASYMMETRIC_LATENCY_TEST
            else if(this.tcfg.test_type != ASYMMETRIC_LATENCY_TEST) begin
              if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
                addr_write_ready_delay_min = 0; 
                addr_write_ready_delay_max = 0; 
              end // ON_DELAY_WO_RESP
             else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
                 addr_write_ready_delay_min = 0;
                addr_write_ready_delay_max = 0; 
              end// FOR_REGRESSION
            end//NOT ASYMMETRIC_LATENCY_TEST
          end
          RGS_AXI_ADDR_WRITE_READY_ZERO_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : ZERO_DELAY");
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = 0;
          end
          RGS_AXI_ADDR_WRITE_READY_LONG_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : LONG_DELAY");
            addr_write_ready_delay_min =  0;
            addr_write_ready_delay_max =  0;
          end
          default                   : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
        endcase
  
        case (this.rgen_write_ready_delay_type.gen)
          RGS_AXI_WRITE_READY_RANDOM_DELAY    : begin 
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : RANDOM_DELAY");
            wready_min = 0;
            wready_max = `SVT_AXI_MAX_WREADY_DELAY;
          end
          RGS_AXI_WRITE_READY_NORMAL_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : ZERO_DELAY");
            wready_min = 0;
            wready_max = 0;
          end
          RGS_AXI_WRITE_READY_SLOW_DELAY      : begin 
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : LONG_DELAY");
            wready_min = 0;
            wready_max = 0; 
          end
          default                           : this.fatal("VMG_ERROR", $sformatf("rgen_slv_ready_delay_type result is illegal!!"));
        endcase
  
        case (this.rgen_write_resp_valid_delay_type.gen)
          RGS_AXI_WRITE_RESP_VALID_RANDOM_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : RANDOM_DELAY");
            bvalid_min = 0;
            bvalid_max = 0; 
          end
          RGS_AXI_WRITE_RESP_VALID_NORMAL_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : NORMAL_DELAY");
            if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
              bvalid_min = 0;
              bvalid_max = 0;
            end//ASYMMETRIC_LATENCY_TEST
            else if(this.tcfg.test_type != ASYMMETRIC_LATENCY_TEST) begin
              if(this.tcfg.tb_scheme == ON_DELAY_WO_RESP) begin
                bvalid_min = 0; 
                bvalid_max = 0; 
              end// ON_DELAY_WO_RESP
              else if(this.tcfg.tb_scheme == FOR_REGRESSION) begin
                bvalid_min = 0; 
                bvalid_max = 0; 
              end// FOR_REGRESSION
            end//NOT ASYMMTERIC_LATENCY_TEST
          end
          RGS_AXI_WRITE_RESP_VALID_FAST_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : ZERO_DELAY");
            bvalid_min = 0;
            bvalid_max =  0; 
          end
          RGS_AXI_WRITE_RESP_VALID_SLOW_DELAY   : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : LONG_DELAY");
            bvalid_min = 0;
            bvalid_max = 0; 
          end
          default                           : this.fatal("VMG_ERROR", $sformatf("rgen_slv_resp_delay result is illegal!!"));
        endcase
        
        `uvm_rand_send_with(this.req,
          {
            enable_interleave == 1;
            reference_event_for_bvalid_delay == LAST_DATA_HANDSHAKE;
            
            foreach(random_interleave_array[i]){
              random_interleave_array[i] == 1;
            }
            foreach(wready_delay[i]) {
              wready_delay[i] inside {[0:0]};
            }
            if (enable_aw_to_b_delay) 
              bvalid_delay inside {bvalid_max};
            else  bvalid_delay == scfg.perf_ctrl_knob.perf_card_side_data_latency;
            bresp inside{ AxiSlvTrans_t::OKAY };
            addr_ready_delay inside {[0:0]};
          })
      end
    end
  endtask:doSend

endclass:vdmatb_card_perf_seq






class vdmatb_card_all_random_seq extends vdmatb_card_seq;

  `uvm_object_utils(vdmatb_card_all_random_seq)
  function new(string name="vdmatb_card_all_random_seq");
    super.new(name);
  endfunction

  virtual task body();
	  AxiSlvTrans_t found;
    YesOrNo_t bresp_fault_on;
    YesOrNo_t rresp_fault_on;
    int rresp_select;
    int bresp_select;
 
    rresp_select = this.tcfg.fault_ratio.WEIGHT_HOST_R_WRONG_RESP + this.tcfg.fault_ratio.WEIGHT_HOST_CORRECT_RESP;
    bresp_select = this.tcfg.fault_ratio.WEIGHT_HOST_B_WRONG_RESP + this.tcfg.fault_ratio.WEIGHT_HOST_CORRECT_RESP;
    
	  this.sink_responses();
	  forever begin
	  	this.p_sequencer.response_request_port.peek(found);
	  	$cast(this.req, found);
      
    if($urandom_range(1, rresp_select) <= this.tcfg.fault_ratio.WEIGHT_HOST_R_WRONG_RESP)
      rresp_fault_on = YES;
    else if($urandom_range(1, rresp_select) <= this.tcfg.fault_ratio.WEIGHT_HOST_R_WRONG_RESP + this.tcfg.fault_ratio.WEIGHT_HOST_CORRECT_RESP)
      rresp_fault_on = NO;
    if($urandom_range(1, bresp_select) <= this.tcfg.fault_ratio.WEIGHT_HOST_B_WRONG_RESP)
      bresp_fault_on = YES;
    else if($urandom_range(1, bresp_select) <= this.tcfg.fault_ratio.WEIGHT_HOST_B_WRONG_RESP + this.tcfg.fault_ratio.WEIGHT_HOST_CORRECT_RESP)
      bresp_fault_on = NO;
    
	  	`uvm_rand_send_with(this.req,
	  	{
	  		// R
        if(rresp_fault_on == YES)
	  		  foreach(rresp[i]) {
	  			  rresp[i] > 1; 
          }
        else if(rresp_fault_on == NO)
          foreach(rresp[i]) {
            rresp[i] inside { AxiSlvTrans_t::OKAY };
          }
	  		
	  		// W
        if(bresp_fault_on == YES)
	  		  bresp > 1;
        else if(bresp_fault_on == NO)
          bresp inside { AxiSlvTrans_t::OKAY };  
	  	})
    end
  endtask:body

endclass:vdmatb_card_all_random_seq



class vdmatb_card_constrained_random_seq extends vdmatb_card_seq;
  
  `uvm_object_utils(vdmatb_card_constrained_random_seq)
  function new(string name="vdmatb_card_constrained_random_seq");
    super.new(name);
  endfunction

  virtual function void setDefaultCfg();
    super.setDefaultCfg();
    this.enable_aw_to_b_delay = $urandom_range(0, 1);
    this.prob_slv_min_max = 5;
  endfunction:setDefaultCfg

  virtual protected task doSend();
    AxiSlvTrans_t found;
    
    bit rdata_prob[2**`SVT_AXI_MAX_BURST_LENGTH_WIDTH];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rdata_max = (1 << `SVT_AXI_MAX_DATA_WIDTH) -1;
    int rvalid_max,rvalid_min,first_rvalid_max,first_rvalid_min;
    int addr_read_ready_delay_max,addr_read_ready_delay_min,addr_write_ready_delay_max,addr_write_ready_delay_min;
    int wready_min,wready_max;
    int bvalid_min,bvalid_max;
    
    YesOrNo_t bresp_fault_on;
    YesOrNo_t rresp_fault_on;
    int rresp_select;
    int bresp_select;
   
    rresp_select = this.tcfg.fault_ratio.WEIGHT_CARD_R_WRONG_RESP + this.tcfg.fault_ratio.WEIGHT_CARD_CORRECT_RESP;
    bresp_select = this.tcfg.fault_ratio.WEIGHT_CARD_B_WRONG_RESP + this.tcfg.fault_ratio.WEIGHT_CARD_CORRECT_RESP;

    this.sink_responses();
    forever begin
      if($urandom_range(1, rresp_select) <= this.tcfg.fault_ratio.WEIGHT_CARD_R_WRONG_RESP)
        rresp_fault_on = YES;
      else if($urandom_range(1, rresp_select) <= this.tcfg.fault_ratio.WEIGHT_CARD_R_WRONG_RESP + this.tcfg.fault_ratio.WEIGHT_CARD_CORRECT_RESP)
        rresp_fault_on = NO;
    
      if($urandom_range(1, bresp_select) <= this.tcfg.fault_ratio.WEIGHT_CARD_B_WRONG_RESP)
        bresp_fault_on = YES;
      else if($urandom_range(1, bresp_select) <= this.tcfg.fault_ratio.WEIGHT_CARD_B_WRONG_RESP + this.tcfg.fault_ratio.WEIGHT_CARD_CORRECT_RESP)
        bresp_fault_on = NO;
      
      
      foreach (rdata_prob[i]) rdata_prob[i] = FlipCoin(prob_slv_min_max);
  
      this.p_sequencer.response_request_port.peek(found);
      found.random_interleave_array = new[found.burst_length];
      $cast(this.req, found);
  
  
      if(req.xact_type == AxiTrans_t::READ)begin
        case(this.rgen_addr_read_ready_delay_type.gen)
          RGS_AXI_ADDR_READ_READY_RANDOM_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : RANDOM_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY;
          end
          RGS_AXI_ADDR_READ_READY_NORMAL_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : ZERO_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = 0;  
          end
          RGS_AXI_ADDR_READ_READY_LONG_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : LONG_DELAY");
            addr_read_ready_delay_min = `SVT_AXI_MAX_ADDR_DELAY/2;
            addr_read_ready_delay_max =  `SVT_AXI_MAX_ADDR_DELAY; 
          end
          default                   : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
        endcase
  
        case(this.rgen_read_valid_delay_type.gen)
          RGS_AXI_READ_VALID_RANDOM_DELAY  : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : RANDOM_DELAY");
            rvalid_min = 0; 
            rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 2; 
          end
          RGS_AXI_READ_VALID_NORMAL_DELAY  : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : ZERO_DELAY");
            rvalid_min = 0; 
            rvalid_max = 0; 
          end
          RGS_AXI_READ_VALID_LONG_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : LONG_DELAY");
            rvalid_min =`SVT_AXI_MAX_AXI3_GENERIC_DELAY / 4 + 1;
            rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 2; 
          end
          default                             : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
        endcase
  
        case(this.rgen_first_read_valid_delay_type.gen)
          RGS_AXI_FIRST_READ_VALID_RANDOM_DELAY  : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : RANDOM_DELAY");
            first_rvalid_min = 0; 
            first_rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY * 4; 
          end
          RGS_AXI_FIRST_READ_VALID_NORMAL_DELAY  : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : ZERO_DELAY");
            first_rvalid_min = 0;
            first_rvalid_max = 0;
          end
          RGS_AXI_FIRST_READ_VALID_LONG_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : LONG_DELAY");
            first_rvalid_min = `SVT_AXI_MAX_RVALID_DELAY/2;
            first_rvalid_max = `SVT_AXI_MAX_RVALID_DELAY; 
          end
          default                             : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
        endcase
        `uvm_rand_send_with(this.req,
          {
            enable_interleave == 1;
            foreach(random_interleave_array[i]){
              random_interleave_array[i] == 1;
            }
            foreach(data[i]) {
              if (rdata_prob[i])  data[i] inside {0, rdata_max};
              else                data[i] inside {[0:rdata_max]};
            }
            if(rresp_fault_on == YES)
              foreach(rresp[i]) {
                rresp[i] > 1;
              }
            else if(rresp_fault_on == NO)
              foreach(rresp[i]) {
                rresp[i]  inside {AxiSlvTrans_t::OKAY};
              }
  
            foreach(rvalid_delay[i]) {
              if (i == 0) rvalid_delay[i] inside {[first_rvalid_min:first_rvalid_max]};
              else rvalid_delay[i] inside {[rvalid_min:(rvalid_max)]};
            }
            addr_ready_delay inside {[addr_read_ready_delay_min:addr_read_ready_delay_max]};
          })
  
      end
      if(req.xact_type == AxiTrans_t::WRITE)begin
  
        case(this.rgen_addr_write_ready_delay_type.gen)
          RGS_AXI_ADDR_WRITE_READY_RANDOM_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : RANDOM_DELAY");
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY;
          end
          RGS_AXI_ADDR_WRITE_READY_NORMAL_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : ZERO_DELAY");
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = 0;
          end
          RGS_AXI_ADDR_WRITE_READY_LONG_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : LONG_DELAY");
            addr_write_ready_delay_min = `SVT_AXI_MAX_ADDR_DELAY/2;
            addr_write_ready_delay_max =  `SVT_AXI_MAX_ADDR_DELAY;
          end
          default                   : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
        endcase
  
        case (this.rgen_write_ready_delay_type.gen)
          RGS_AXI_WRITE_READY_RANDOM_DELAY    : begin 
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : RANDOM_DELAY");
            wready_min = 0;
            wready_max = `SVT_AXI_MAX_WREADY_DELAY;
          end
          RGS_AXI_WRITE_READY_NORMAL_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : ZERO_DELAY");
            wready_min = 0;
            wready_max = 0;
          end
          RGS_AXI_WRITE_READY_SLOW_DELAY      : begin 
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : LONG_DELAY");
            wready_min = `SVT_AXI_MAX_WREADY_DELAY/2 + 1;
            wready_max = `SVT_AXI_MAX_WREADY_DELAY; 
          end
          default                           : this.fatal("VMG_ERROR", $sformatf("rgen_slv_ready_delay_type result is illegal!!"));
        endcase
  
        case (this.rgen_write_resp_valid_delay_type.gen)
          RGS_AXI_WRITE_RESP_VALID_RANDOM_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : RANDOM_DELAY");
            bvalid_min = 0;
            bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 32; 
          end
          RGS_AXI_WRITE_RESP_VALID_NORMAL_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : NORMAL_DELAY");
            if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
              bvalid_min = `SVT_AXI_MAX_WRITE_RESP_DELAY / 64;
              bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 64;
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
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : ZERO_DELAY");
            bvalid_min = 0;
            bvalid_max =  0; 
          end
          RGS_AXI_WRITE_RESP_VALID_SLOW_DELAY   : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : LONG_DELAY");
            bvalid_min = `SVT_AXI_MAX_WRITE_RESP_DELAY/64 + 1;
            bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 32; 
          end
          default                           : this.fatal("VMG_ERROR", $sformatf("rgen_slv_resp_delay result is illegal!!"));
        endcase
        
        `uvm_rand_send_with(this.req,
          {
            enable_interleave == 1;
            foreach(random_interleave_array[i]){
              random_interleave_array[i] == 1;
            }
            foreach(wready_delay[i]) {
              wready_delay[i] inside {[wready_min:wready_max]};
            }
            if (enable_aw_to_b_delay) 
              bvalid_delay inside {bvalid_max};
            else  bvalid_delay inside {[bvalid_min/32:bvalid_max/16]};
            if(bresp_fault_on == YES)
              bresp > 1;
            else if(bresp_fault_on == NO)
              bresp inside { AxiSlvTrans_t::OKAY };
            addr_ready_delay inside {[addr_write_ready_delay_min:addr_write_ready_delay_max]};
          })
      end
     
    end
  endtask:doSend

endclass:vdmatb_card_constrained_random_seq




class vdmatb_card_full_start_w_fifo_seq extends vdmatb_card_seq;

	`uvm_object_utils(vdmatb_card_full_start_w_fifo_seq)
	function new(string name="vdmatb_card_full_start_w_fifo_seq");
		super.new(name);
	endfunction

  virtual function void setDefaultCfg();
    super.setDefaultCfg();
    this.enable_aw_to_b_delay = FlipCoin();
  endfunction


  // TODO:DRY -- what's the difference with its base class?
	virtual protected task doSend();
    AxiSlvTrans_t found;

    bit rdata_prob[2**`SVT_AXI_MAX_BURST_LENGTH_WIDTH];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rdata_max = (1 << `SVT_AXI_MAX_DATA_WIDTH) -1;
    int rvalid_max,rvalid_min,first_rvalid_max,first_rvalid_min;
    int addr_read_ready_delay_max,addr_read_ready_delay_min,addr_write_ready_delay_max,addr_write_ready_delay_min;
    int wready_min,wready_max;
    int bvalid_min,bvalid_max;
    
    this.sink_responses();
    
    forever begin
      foreach (rdata_prob[i]) rdata_prob[i] = FlipCoin(prob_slv_min_max);

      this.p_sequencer.response_request_port.peek(found);
      found.random_interleave_array = new[found.burst_length];
      $cast(this.req, found);

      if(req.xact_type == AxiTrans_t::READ)begin
        case(this.rgen_addr_read_ready_delay_type.gen)
          RGS_AXI_ADDR_READ_READY_RANDOM_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : RANDOM_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY;
          end
          RGS_AXI_ADDR_READ_READY_NORMAL_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : ZERO_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = 0;  
          end
          RGS_AXI_ADDR_READ_READY_LONG_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : LONG_DELAY");
            addr_read_ready_delay_min = `SVT_AXI_MAX_ADDR_DELAY/2;
            addr_read_ready_delay_max =  `SVT_AXI_MAX_ADDR_DELAY; 
          end
          default                   : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
        endcase

        case(this.rgen_read_valid_delay_type.gen)
          RGS_AXI_READ_VALID_RANDOM_DELAY  : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : RANDOM_DELAY");
            rvalid_min = 0; 
            rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 2; 
          end
          RGS_AXI_READ_VALID_NORMAL_DELAY  : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : ZERO_DELAY");
            rvalid_min = 0; 
            rvalid_max = 0; 
          end
          RGS_AXI_READ_VALID_LONG_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : LONG_DELAY");
            rvalid_min =`SVT_AXI_MAX_AXI3_GENERIC_DELAY / 4 + 1;
            rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 2; 
          end
          default                             : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
        endcase

        case(this.rgen_first_read_valid_delay_type.gen)
          RGS_AXI_FIRST_READ_VALID_RANDOM_DELAY  : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : RANDOM_DELAY");
            first_rvalid_min = 0; 
            first_rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY * 4; 
          end
          RGS_AXI_FIRST_READ_VALID_NORMAL_DELAY  : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : ZERO_DELAY");
            first_rvalid_min = 0;
            first_rvalid_max = 0;
          end
          RGS_AXI_FIRST_READ_VALID_LONG_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : LONG_DELAY");
            first_rvalid_min = `SVT_AXI_MAX_RVALID_DELAY/2;
            first_rvalid_max = `SVT_AXI_MAX_RVALID_DELAY; 
          end
          default                             : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
        endcase
        `uvm_rand_send_with(this.req,
          {
            enable_interleave == 1;
            foreach(random_interleave_array[i]){
              random_interleave_array[i] == 1;
            }
            foreach(data[i]) {
              if (rdata_prob[i])  data[i] inside {0, rdata_max};
              else                data[i] inside {[0:rdata_max]};
            }
            foreach(rresp[i]) {
              rresp[i]  inside {AxiSlvTrans_t::OKAY };
            }

            foreach(rvalid_delay[i]) {
              if (i == 0) rvalid_delay[i] inside {[0:0]};
              else rvalid_delay[i] inside {[0:0]};
            }
            addr_ready_delay inside {[0:0]};
          })

      end
      if(req.xact_type == AxiTrans_t::WRITE)begin

        case(this.rgen_addr_write_ready_delay_type.gen)
          RGS_AXI_ADDR_WRITE_READY_RANDOM_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : RANDOM_DELAY");
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY;
          end
          RGS_AXI_ADDR_WRITE_READY_NORMAL_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : ZERO_DELAY");
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = 0;
          end
          RGS_AXI_ADDR_WRITE_READY_LONG_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : LONG_DELAY");
            addr_write_ready_delay_min = `SVT_AXI_MAX_ADDR_DELAY/2;
            addr_write_ready_delay_max =  `SVT_AXI_MAX_ADDR_DELAY;
          end
          default                   : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
        endcase

        case (this.rgen_write_ready_delay_type.gen)
          RGS_AXI_WRITE_READY_RANDOM_DELAY    : begin 
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : RANDOM_DELAY");
            wready_min = 0;
            wready_max = `SVT_AXI_MAX_WREADY_DELAY;
          end
          RGS_AXI_WRITE_READY_NORMAL_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : ZERO_DELAY");
            wready_min = 0;
            wready_max = 0;
          end
          RGS_AXI_WRITE_READY_SLOW_DELAY      : begin 
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : LONG_DELAY");
            wready_min = `SVT_AXI_MAX_WREADY_DELAY/2 + 1;
            wready_max = `SVT_AXI_MAX_WREADY_DELAY; 
          end
          default                           : this.fatal("VMG_ERROR", $sformatf("rgen_slv_ready_delay_type result is illegal!!"));
        endcase

        case (this.rgen_write_resp_valid_delay_type.gen)
          RGS_AXI_WRITE_RESP_VALID_RANDOM_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : RANDOM_DELAY");
            bvalid_min = 0;
            bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 32; 
          end
          RGS_AXI_WRITE_RESP_VALID_NORMAL_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : NORMAL_DELAY");
            if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
              bvalid_min = `SVT_AXI_MAX_WRITE_RESP_DELAY / 64;
              bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 64;
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
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : ZERO_DELAY");
            bvalid_min = 0;
            bvalid_max =  0; 
          end
          RGS_AXI_WRITE_RESP_VALID_SLOW_DELAY   : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : LONG_DELAY");
            bvalid_min = `SVT_AXI_MAX_WRITE_RESP_DELAY/64 + 1;
            bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 32; 
          end
          default                           : this.fatal("VMG_ERROR", $sformatf("rgen_slv_resp_delay result is illegal!!"));
        endcase
        
        `uvm_rand_send_with(this.req,
          {
            enable_interleave == 1;
            foreach(random_interleave_array[i]){
              random_interleave_array[i] == 1;
            }
            foreach(wready_delay[i]) {
              wready_delay[i] inside {[1:1]};
            }
            if (enable_aw_to_b_delay) 
              bvalid_delay inside {0};
            else  bvalid_delay inside {[0:0]};
            bresp < 1;
            addr_ready_delay inside {[1:1]};
          })
      end
    end
  endtask:doSend

endclass:vdmatb_card_full_start_w_fifo_seq



class vdmatb_card_fault_cover_all_dma_id_bits_from_card_fault_seq extends vdmatb_card_seq;

	`uvm_object_utils(vdmatb_card_fault_cover_all_dma_id_bits_from_card_fault_seq)
	function new(string name="vdmatb_card_fault_cover_all_dma_id_bits_from_card_fault_seq");
		super.new(name);
	endfunction

  virtual function void setDefaultCfg();
    super.setDefaultCfg();
    this.enable_aw_to_b_delay = FlipCoin();
  endfunction


	virtual protected task doSend();
    AxiSlvTrans_t found;

    bit rdata_prob[2**`SVT_AXI_MAX_BURST_LENGTH_WIDTH];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rdata_max = (1 << `SVT_AXI_MAX_DATA_WIDTH) -1;
    int rvalid_max,rvalid_min,first_rvalid_max,first_rvalid_min;
    int addr_read_ready_delay_max,addr_read_ready_delay_min,addr_write_ready_delay_max,addr_write_ready_delay_min;
    int wready_min,wready_max;
    int bvalid_min,bvalid_max;
    
    this.sink_responses();
    
    forever begin
      foreach (rdata_prob[i]) rdata_prob[i] = FlipCoin(prob_slv_min_max);

      this.p_sequencer.response_request_port.peek(found);
      found.random_interleave_array = new[found.burst_length];
      $cast(this.req, found);

      if(req.xact_type == AxiTrans_t::READ)begin
        case(this.rgen_addr_read_ready_delay_type.gen)
          RGS_AXI_ADDR_READ_READY_RANDOM_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : RANDOM_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY;
          end
          RGS_AXI_ADDR_READ_READY_NORMAL_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : ZERO_DELAY");
            addr_read_ready_delay_min = 0;
            addr_read_ready_delay_max = 0;  
          end
          RGS_AXI_ADDR_READ_READY_LONG_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AR_READY_DELAY_TYPE : LONG_DELAY");
            addr_read_ready_delay_min = `SVT_AXI_MAX_ADDR_DELAY/2;
            addr_read_ready_delay_max =  `SVT_AXI_MAX_ADDR_DELAY; 
          end
          default                   : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
        endcase

        case(this.rgen_read_valid_delay_type.gen)
          RGS_AXI_READ_VALID_RANDOM_DELAY  : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : RANDOM_DELAY");
            rvalid_min = 0; 
            rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 2; 
          end
          RGS_AXI_READ_VALID_NORMAL_DELAY  : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : ZERO_DELAY");
            rvalid_min = 0; 
            rvalid_max = 0; 
          end
          RGS_AXI_READ_VALID_LONG_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] R_VALID_DELAY_TYPE : LONG_DELAY");
            rvalid_min =`SVT_AXI_MAX_AXI3_GENERIC_DELAY / 4 + 1;
            rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY / 2; 
          end
          default                             : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
        endcase

        case(this.rgen_first_read_valid_delay_type.gen)
          RGS_AXI_FIRST_READ_VALID_RANDOM_DELAY  : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : RANDOM_DELAY");
            first_rvalid_min = 0; 
            first_rvalid_max = `SVT_AXI_MAX_AXI3_GENERIC_DELAY * 4; 
          end
          RGS_AXI_FIRST_READ_VALID_NORMAL_DELAY  : begin 
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : ZERO_DELAY");
            first_rvalid_min = 0;
            first_rvalid_max = 0;
          end
          RGS_AXI_FIRST_READ_VALID_LONG_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] R_FIRST_VALID_DELAY_TYPE : LONG_DELAY");
            first_rvalid_min = `SVT_AXI_MAX_RVALID_DELAY/2;
            first_rvalid_max = `SVT_AXI_MAX_RVALID_DELAY; 
          end
          default                             : this.fatal("VMG_ERROR", $sformatf("rgen_slv_delay_behaviour result is illegal!!"));
        endcase
        `uvm_rand_send_with(this.req,
          {
            enable_interleave == 1;
            foreach(random_interleave_array[i]){
              random_interleave_array[i] == 1;
            }
            foreach(data[i]) {
              if (rdata_prob[i])  data[i] inside {0, rdata_max};
              else                data[i] inside {[0:rdata_max]};
            }
            foreach(rresp[i]) {
              rresp[i] > 0;
            }

            foreach(rvalid_delay[i]) {
              if (i == 0) rvalid_delay[i] inside {[0:0]};
              else rvalid_delay[i] inside {[0:0]};
            }
            addr_ready_delay inside {[0:0]};
          })

      end
      if(req.xact_type == AxiTrans_t::WRITE)begin

        case(this.rgen_addr_write_ready_delay_type.gen)
          RGS_AXI_ADDR_WRITE_READY_RANDOM_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : RANDOM_DELAY");
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = `SVT_AXI_MAX_ADDR_DELAY;
          end
          RGS_AXI_ADDR_WRITE_READY_NORMAL_DELAY : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : ZERO_DELAY");
            addr_write_ready_delay_min = 0;
            addr_write_ready_delay_max = 0;
          end
          RGS_AXI_ADDR_WRITE_READY_LONG_DELAY   : begin
            this.debug("[HOST_AXI_LATENCY] AW_READY_DELAY_TYPE : LONG_DELAY");
            addr_write_ready_delay_min = `SVT_AXI_MAX_ADDR_DELAY/2;
            addr_write_ready_delay_max =  `SVT_AXI_MAX_ADDR_DELAY;
          end
          default                   : this.fatal("VMG_ERROR", $sformatf("rgen_addr_delay_type result is illegal!!"));
        endcase

        case (this.rgen_write_ready_delay_type.gen)
          RGS_AXI_WRITE_READY_RANDOM_DELAY    : begin 
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : RANDOM_DELAY");
            wready_min = 0;
            wready_max = `SVT_AXI_MAX_WREADY_DELAY;
          end
          RGS_AXI_WRITE_READY_NORMAL_DELAY    : begin
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : NORMAL_DELAY");
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
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : ZERO_DELAY");
            wready_min = 0;
            wready_max = 0;
          end
          RGS_AXI_WRITE_READY_SLOW_DELAY      : begin 
            this.debug("[HOST_AXI_LATENCY] W_READY_DELAY_TYPE : LONG_DELAY");
            wready_min = `SVT_AXI_MAX_WREADY_DELAY/2 + 1;
            wready_max = `SVT_AXI_MAX_WREADY_DELAY; 
          end
          default                           : this.fatal("VMG_ERROR", $sformatf("rgen_slv_ready_delay_type result is illegal!!"));
        endcase

        case (this.rgen_write_resp_valid_delay_type.gen)
          RGS_AXI_WRITE_RESP_VALID_RANDOM_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : RANDOM_DELAY");
            bvalid_min = 0;
            bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 32; 
          end
          RGS_AXI_WRITE_RESP_VALID_NORMAL_DELAY : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : NORMAL_DELAY");
            if(this.tcfg.test_type == ASYMMETRIC_LATENCY_TEST) begin
              bvalid_min = `SVT_AXI_MAX_WRITE_RESP_DELAY / 64;
              bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 64;
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
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : ZERO_DELAY");
            bvalid_min = 0;
            bvalid_max =  0; 
          end
          RGS_AXI_WRITE_RESP_VALID_SLOW_DELAY   : begin 
            this.debug("[HOST_AXI_LATENCY] W_RESP_VALID_DELAY_TYPE : LONG_DELAY");
            bvalid_min = `SVT_AXI_MAX_WRITE_RESP_DELAY/64 + 1;
            bvalid_max = `SVT_AXI_MAX_WRITE_RESP_DELAY / 32; 
          end
          default                           : this.fatal("VMG_ERROR", $sformatf("rgen_slv_resp_delay result is illegal!!"));
        endcase
        
        `uvm_rand_send_with(this.req,
          {
            enable_interleave == 1;
            foreach(random_interleave_array[i]){
              random_interleave_array[i] == 1;
            }
            foreach(wready_delay[i]) {
              wready_delay[i] inside {[0:0]};
            }
            if (enable_aw_to_b_delay) 
              bvalid_delay inside {bvalid_max};
            else  bvalid_delay inside {[0:0]};
            bresp > 1;
            addr_ready_delay inside {[0:0]};
          })
      end
    end
  endtask:doSend

endclass:vdmatb_card_fault_cover_all_dma_id_bits_from_card_fault_seq

`endif // __VDMATB_CARD_SEQ_LIB_SVH__
