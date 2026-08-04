`ifndef __VDMA_H2C_PKT_GATHERING_TRKR_SVH__
`define __VDMA_H2C_PKT_GATHERING_TRKR_SVH__



class vdma_h2c_pkt_gathering_trkr extends vmg_cmpnt;

  local vdma_seq_item q_active[$];

  typedef struct {
	  vdma_seq_item 	q_trans_per_pkt[$];
	  DmaId_t		      pkt_dma_id;
	  longint		      total_pkt_data_size = -1;
	  int				      pkt_idx;
	  int				      num_planned_data = INVALID_INT_VALUE;
	  int				      cur_in_data = 0;
  }DmaTransPktGatheringInfo_t;
  DmaTransPktGatheringInfo_t	q_active_pkt[$];

  local vdma_mst_tcfg tcfg;

  local YesOrNo_t on_gathering =  NO;
  local int num_gathering 		= 0;
  local int num_gathered_pkt 	= 0;
  local int last_pkt_idx 		= 0;

  // Coverpoint -----------------
  local Desc_t for_cp_mid_desc;
	
  covergroup cg_h2c_gth_total;
    h2c_gth_num_mid : coverpoint (this.q_active_pkt[last_pkt_idx].q_trans_per_pkt.size() - 2) {
      bins range[] = {[0:10]};
    }
    h2c_gth_total_size : coverpoint (this.q_active_pkt[last_pkt_idx].total_pkt_data_size) {
      bins range[] = {[2:64]};

    }
  endgroup
  covergroup cg_h2c_gth_mid;
    h2c_gth_mid_size : coverpoint (this.for_cp_mid_desc.len) {
      
        bins small1 = {[1:4096]};
		bins small2 = {[4097:8193]};
		bins small3 = {[8194:12290]};
		bins small4 = {[12291:16387]};
		bins small5 = {[16388:20484]};
		bins mid1 = {[20485:24581]};
		bins mid2 = {[24582:28678]};
		bins mid3 = {[28679:32775]};
		bins mid4 = {[32776:36872]};
		bins mid5 = {[36873:40969]};
		bins big1 = {[40970:45066]};
		bins big2 = {[45067:49160]};
		bins big3 = {[49161:53257]};
		bins big4 = {[53258:57354]};
		bins big5 = {[57355:61451]};
		bins big6 = {[61452:65536]};
    }
  endgroup
  
  // ----------------------------
  `uvm_component_utils(vdma_h2c_pkt_gathering_trkr)
  function new(string name="vdma_h2c_pkt_gathering_trkr", uvm_component parent=null);
    super.new(name, parent);
	  cg_h2c_gth_total = new();
	  cg_h2c_gth_mid   = new();
  endfunction
  

  extern virtual function void updateState();
  extern virtual function StringQ_t getInfoList();
  extern virtual function string getInfo();
  
  extern virtual function string getPktInfo(DmaTransPktGatheringInfo_t call_pkt);

  extern virtual function void init();

  extern function vdma_seq_item chkAndUpdate(vdma_seq_item new_trans);

  extern function void integrateTcfg(vdma_mst_tcfg me);
  
  extern virtual function YesOrNo_t reset();
endclass:vdma_h2c_pkt_gathering_trkr


function void vdma_h2c_pkt_gathering_trkr::init();
  if(this.q_active.size != 0) this.warning($sformatf("Initialized !! (Number of active queue:%1d)", this.q_active.size));
  else                        this.info   ($sformatf("Initialized !!"));
  this.q_active.delete();
  
  if(this.q_active_pkt.size != 0)	this.warning($sformatf("Initialized !! (Number of active gathering pkt:%1d)", this.q_active.size));
  else								this.info   ($sformatf("Initialized !!"));
  this.q_active_pkt.delete();
endfunction:init


function YesOrNo_t vdma_h2c_pkt_gathering_trkr::reset();
  this.on_gathering     = NO;
  this.num_gathering    = 0;
  this.num_gathered_pkt = 0;
  this.last_pkt_idx     = 0;
  
  if(this.q_active_pkt.size != 0) 
    this.warning($sformatf("[Initialized !!] But q_active_pkt is not empty (Number of active gathering pkt:%1d)", this.q_active.size));
  else                
    this.info   ($sformatf("[Initialized !!] q_active_pkt in pkt_gathering_mon (q_active_pkt.size=%1d)", this.q_active_pkt.size()));
  
  this.q_active_pkt.delete();
  if( (this.on_gathering == NO) && (this.num_gathering == 0) && (this.num_gathered_pkt == 0) && (this.last_pkt_idx == 0) && (this.q_active_pkt.size() == 0))
    return(YES);
  
  return(NO);
endfunction:reset


function void vdma_h2c_pkt_gathering_trkr::updateState();
  vdma_seq_item latest;
  
  if( !(this.q_active_pkt.size()>0) ) return;
  
endfunction:updateState



function string vdma_h2c_pkt_gathering_trkr::getInfo();
  YesOrNo_t on_gathering;

  return($sformatf("Number of packet gathering=%1d on_gathering=%s",
    this.num_gathering,
    this.on_gathering.name
  ));
endfunction:getInfo



function StringQ_t vdma_h2c_pkt_gathering_trkr::getInfoList();
  StringQ_t result;

  if(this.on_gathering == YES)begin
    result.push_back($sformatf("----------------------------------------"));
    result.push_back($sformatf("Packet gathering queue (%1d packet(s))", this.q_active.size));
    foreach(this.q_active[i])begin
      result.push_back($sformatf(" - pkt[%3d] %s", i, this.q_active[i].getInfo));
    end
    result.push_back($sformatf("----------------------------------------"));
  end

  return(result);
endfunction:getInfoList



function string vdma_h2c_pkt_gathering_trkr::getPktInfo(DmaTransPktGatheringInfo_t call_pkt);
	string result;
	result = $sformatf("----------------------------------------\n\
		Packet gathering Info (pkt_id=%1d)\n - pkt_dma_id : %1d\n - num_pkt : %1d\n - total_pkt_size : %1dB\n - num_cur/planned_data : %1d B / %1d B\n\
		----------------------------------------",
		call_pkt.pkt_idx, call_pkt.pkt_dma_id, call_pkt.q_trans_per_pkt.size(), call_pkt.total_pkt_data_size, call_pkt.cur_in_data, call_pkt.num_planned_data
		);
	return(result);
endfunction : getPktInfo




function vdma_seq_item vdma_h2c_pkt_gathering_trkr::chkAndUpdate(vdma_seq_item new_trans);
  Desc_t desc;
  DmaTransPktGatheringInfo_t new_pkts;

  desc = new_trans.getDesc();
	
	if(this.tcfg.test_type != FAULT_TEST)begin
		case(this.on_gathering)
		YES:begin
	    	// CPChker : Can't allow interleaving new GATHERING during GATHERING
	    	if( new_trans.getPktGatheringInfo() == START_OF_PKT_GATHERING ) begin
		    	this.reportFatal("VDMA_MON_ILLEGA_H2C_GATHERING",
	        		$sformatf("An packet gathering is already underway, but got \"sop\" from new_trans\n\n     %s\n\n", new_trans.getInfo)
	        		);
	    	end
	    
	    	if( new_trans.getPktGatheringInfo() == END_OF_PKT_GATHERING ) begin
        		this.info($sformatf("A end of packet gathering observed.. from trans \n\n     %s\n\n", new_trans.getInfo));
	    		this.q_active_pkt[last_pkt_idx].total_pkt_data_size += desc.len;
		    	this.q_active_pkt[last_pkt_idx].q_trans_per_pkt.push_back(new_trans);
		    	this.q_active_pkt[last_pkt_idx].num_planned_data = this.q_active_pkt[last_pkt_idx].total_pkt_data_size/CARD_DATA_BYTE_WIDTH;
		    	this.info($sformatf("num_planned_data/total_pkt_data_size = %1d / %1d", this.q_active_pkt[last_pkt_idx].num_planned_data, this.q_active_pkt[last_pkt_idx].total_pkt_data_size));
		    	if( this.q_active_pkt[last_pkt_idx].total_pkt_data_size%CARD_DATA_BYTE_WIDTH != 0 ) this.q_active_pkt[last_pkt_idx].num_planned_data++;

		    	
		    	cg_h2c_gth_total.sample();
		    	
		    	this.last_pkt_idx++;
		    	this.on_gathering = NO;
	    	end
	    
	    	else if( new_trans.getPktGatheringInfo() == INTERMEDIATE_PKT_GATHERING ) begin
	    		// CPChker : Can't request stat/intr on MID_PKT
	    		if( (desc.req_intr == 1) || (desc.req_stat == 1) ) begin
		    		this.reportFatal("VDMA_MON_ILLEGA_H2C_GATHERING",
			    		$sformatf("Can't request stat/intr on MID_PKT\n\n     %s\n\n", new_trans.getInfo)
			    		);
	    		end
        		this.info($sformatf("A mid of packet gathering observed.. from trans \n\n     %s\n\n", new_trans.getInfo));
	    		this.q_active_pkt[last_pkt_idx].total_pkt_data_size += desc.len;
		    	this.q_active_pkt[last_pkt_idx].q_trans_per_pkt.push_back(new_trans);
	    		
	    		 this.for_cp_mid_desc = desc;
	    		 cg_h2c_gth_mid.sample();
	    	end
	    	
	    	// CPChker : SOLO PKT during pkt gathering
	    	else if( new_trans.getPktGatheringInfo() == NOT_ON_PKT_GATHERING ) begin
		    	this.reportFatal("VDMA_MON_ILLEGA_H2C_GATHERING",
	        		$sformatf("SOLO_PKT can't be asserted on Gathering PKTs\n\n     %s\n\n", new_trans.getInfo)
			    	);
	    	end
	    
	    	// CPChker : UNDEFINED PKT GATHERING STATUS is used
	    	else begin
		    	this.reportFatal("VDMA_MON_ILLEGA_H2C_GATHERING",
	        		$sformatf("UNDEFINED PKT GATHERING STATUS from new_trans\n\n     %s\n\n", new_trans.getInfo)
	        		);
	    	end
    	end
    
    	NO:begin
	    	if( new_trans.getPktGatheringInfo() != NOT_ON_PKT_GATHERING ) begin
	    	
	    	// CPChker : Can't allow MID or END PKT before GATHERING by START PKT
	    	if( (new_trans.getPktGatheringInfo() == INTERMEDIATE_PKT_GATHERING) || (new_trans.getPktGatheringInfo() == END_OF_PKT_GATHERING) ) begin
		    	this.reportFatal("VDMA_MON_ILLEGA_H2C_GATHERING",
			    	$sformatf("Can't allow MID or END PKT before START PKT\n\n     %s\n\n", new_trans.getInfo)
	        		);
	    	end
	    
	    	if( (new_trans.getPktGatheringInfo() == START_OF_PKT_GATHERING) ) begin
	    		// CPChker : Can't request stat/intr on START_PKT
		    	if( (desc.req_intr == 1) || (desc.req_stat == 1) ) begin
			    	this.reportFatal("VDMA_MON_ILLEGA_H2C_GATHERING",
			    		$sformatf("Can't request stat/intr on MID_PKT\n\n     %s\n\n", new_trans.getInfo)
			    		);
		    	end
		    	
        		this.info($sformatf("A start of packet gathering observed.. from trans \n\n     %s\n\n", new_trans.getInfo));
		    	new_pkts.pkt_dma_id          = DutParamDmaId_t'(desc.dma_id);
		    	new_pkts.total_pkt_data_size = desc.len;
		    	new_pkts.pkt_idx             = this.last_pkt_idx;
		    	new_pkts.q_trans_per_pkt.push_back(new_trans);
		    	this.q_active_pkt.push_back(new_pkts);
		    	this.on_gathering = YES;
	    	end
	    
	    	// CPChker : UNDEFINED PKT GATHERING STATUS is used
	    	else begin
        		this.reportFatal("VDMA_MON_ILLEGA_H2C_GATHERING",
	        		$sformatf("UNDEFINED PKT GATHERING STATUS from new_trans\n\n     %s\n\n", new_trans.getInfo)
	        		);
	    	end
	    	
	    	end
    	end
	endcase
	end
	else begin
		case(this.on_gathering)
			YES:begin
				// CPChker : Can't allow interleaving new GATHERING during GATHERING
				if( new_trans.getPktGatheringInfo() == START_OF_PKT_GATHERING ) begin
					this.info($sformatf("[VDMA_MON_ILLEGA_H2C_GATHERING] An packet gathering is already underway, but got \"sop\" from new_trans\n\n     %s\n\n", new_trans.getInfo));
		    	return(new_trans);
				end
	    
				if( new_trans.getPktGatheringInfo() == END_OF_PKT_GATHERING ) begin
					this.info($sformatf("A end of packet gathering observed.. from trans \n\n     %s\n\n", new_trans.getInfo));
					this.q_active_pkt[last_pkt_idx].total_pkt_data_size += desc.len;
					this.q_active_pkt[last_pkt_idx].q_trans_per_pkt.push_back(new_trans);
					this.q_active_pkt[last_pkt_idx].num_planned_data = this.q_active_pkt[last_pkt_idx].total_pkt_data_size/CARD_DATA_BYTE_WIDTH;
					this.info($sformatf("num_planned_data/total_pkt_data_size = %1d / %1d", this.q_active_pkt[last_pkt_idx].num_planned_data, this.q_active_pkt[last_pkt_idx].total_pkt_data_size));
					if( this.q_active_pkt[last_pkt_idx].total_pkt_data_size%CARD_DATA_BYTE_WIDTH != 0 ) this.q_active_pkt[last_pkt_idx].num_planned_data++;

		    	
					cg_h2c_gth_total.sample();
		    	
					this.last_pkt_idx++;
					this.on_gathering = NO;
	    		end
	    
	    		else if( new_trans.getPktGatheringInfo() == INTERMEDIATE_PKT_GATHERING ) begin
		    		// CPChker : Can't request stat/intr on MID_PKT
		    		if( (desc.req_intr == 1) || (desc.req_stat == 1) ) begin
			    		this.info($sformatf("[VDMA_MON_ILLEGA_H2C_GATHERING] Can't request stat/intr on MID_PKT\n\n     %s\n\n", new_trans.getInfo));
		    		end
		    		this.info($sformatf("A mid of packet gathering observed.. from trans \n\n     %s\n\n", new_trans.getInfo));
		    		this.q_active_pkt[last_pkt_idx].total_pkt_data_size += desc.len;
		    		this.q_active_pkt[last_pkt_idx].q_trans_per_pkt.push_back(new_trans);
	    		
		    		this.for_cp_mid_desc = desc;
		    		cg_h2c_gth_mid.sample();
	    		end
	    	
	    		// CPChker : SOLO PKT during pkt gathering
	    		else if( new_trans.getPktGatheringInfo() == NOT_ON_PKT_GATHERING ) begin
		    		this.info($sformatf("[VDMA_MON_ILLEGA_H2C_GATHERING] SOLO_PKT can't be asserted on Gathering PKTs\n\n     %s\n\n", new_trans.getInfo)
			    		);
		    		return(new_trans);
	    		end
	    
	    	// CPChker : UNDEFINED PKT GATHERING STATUS is used
	    		else begin
		    		this.info($sformatf("[VDMA_MON_ILLEGA_H2C_GATHERING] UNDEFINED PKT GATHERING STATUS from new_trans\n\n     %s\n\n", new_trans.getInfo)
			    		);
	    		end
    		end
    
    		NO:begin
	    		if( new_trans.getPktGatheringInfo() != NOT_ON_PKT_GATHERING ) begin
	    	
	    		// CPChker : Can't allow MID or END PKT before GATHERING by START PKT
	    		if( (new_trans.getPktGatheringInfo() == INTERMEDIATE_PKT_GATHERING) || (new_trans.getPktGatheringInfo() == END_OF_PKT_GATHERING) ) begin
		    		this.info($sformatf("[VDMA_MON_ILLEGA_H2C_GATHERING] Can't allow MID or END PKT before START PKT\n\n     %s\n\n", new_trans.getInfo)
			    		);
		    		return(new_trans);
	    		end
	    
	    		if( (new_trans.getPktGatheringInfo() == START_OF_PKT_GATHERING) ) begin
	    			// CPChker : Can't request stat/intr on START_PKT
		    		if( (desc.req_intr == 1) || (desc.req_stat == 1) ) begin
			    		this.info($sformatf("[VDMA_MON_ILLEGA_H2C_GATHERING] Can't request stat/intr on MID_PKT\n\n     %s\n\n", new_trans.getInfo)
				    		);
		    		end
		    	
        			this.info($sformatf("A start of packet gathering observed.. from trans \n\n     %s\n\n", new_trans.getInfo));
		    		new_pkts.pkt_dma_id          = DutParamDmaId_t'(desc.dma_id);
		    		new_pkts.total_pkt_data_size = desc.len;
		    		new_pkts.pkt_idx             = this.last_pkt_idx;
		    		new_pkts.q_trans_per_pkt.push_back(new_trans);
		    		this.q_active_pkt.push_back(new_pkts);
		    		this.on_gathering = YES;
	    		end
	    
	    		// CPChker : UNDEFINED PKT GATHERING STATUS is used
	    		else begin
        			this.info($sformatf("[VDMA_MON_ILLEGA_H2C_GATHERING] UNDEFINED PKT GATHERING STATUS from new_trans\n\n     %s\n\n", new_trans.getInfo)
	        			);
	    		end
	    	
	    		end
    		end
		endcase
		
		
	end
	
	return(null);
endfunction:chkAndUpdate



function void vdma_h2c_pkt_gathering_trkr::integrateTcfg(vdma_mst_tcfg me); this.tcfg = me; endfunction




`endif // __VDMA_H2C_PKT_GATHERING_TRKR_SVH__
