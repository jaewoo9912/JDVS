`ifndef __VQDMAIF_H2C_DEFS_SVH__
`define __VQDMAIF_H2C_DEFS_SVH__


  typedef class vqdmaif_h2c_factory;

  typedef enum int{
		//--------------------- CMD
		H2C_000_CMD_SOP,
		H2C_001_CMD_LEN,
		H2C_002_CMD_NO_DMA_EOP,
		//--------------------- DATA
		H2C_100_DATA_QID,
		H2C_101_DATA_LAST,
		H2C_102_DATA_MTY,
		//--------------------- STATUS_SIDEBAND
		H2C_200_STATUS_SIDEBAND_CORRESPOND,
		//--------------------- INTERRUPT_SIDEBAND
		H2C_300_INTERRUPT_SIDEBAND_CORRESPOND,
		// ----------------------CMD_SIDEBAND
		H2C_400_CMD_SIDEBAND_CORRESPOND,
		// ----------------------DATA_SIDEBAND
		H2C_500_DATA_SIDEBAND_CORRESPOND,
		//-----------------------
		UNDEFINED_QDMAIF_H2C_PROTCL_ERR_ID_TYPE
  }QdmaifH2cProtclErrIdType_t;



	typedef enum int{
		//------------------------- CMD
		H2C_UNSUP_CMD_ERROR,
		H2C_UNSUP_CMD_MRKR_REQ,
		H2C_UNSUP_CMD_NO_DMA,
		H2C_UNSUP_CMD_SDI,
		//------------------------- DATA
		H2C_UNSUP_DATA_ERR,
		H2C_UNSUP_DATA_CRC,
		H2C_UNSUP_DATA_MDATA,
		H2C_UNSUP_DATA_ZERO_BYTE,
		//------------------------- 
		UNDEFINED_QDMAIF_H2C_UNSUP_FEATURE_ID_TYPE
	}QdmaifH2cUnsupFeatureIdType_t;



`endif // __VQDMAIF_H2C_DEFS_SVH__
