`ifndef __VQDMAIF_C2H_DEF_SVH__
`define __VQDMAIF_C2H_DEF_SVH__


  typedef class vqdmaif_c2h_factory;

  typedef QdmaC2HData_t QdmaC2HDataQ_t[$];

  typedef enum int{
		//------------------------- DATA
		C2H_000_DATA_QID,
		C2H_001_DATA_LEN,
		C2H_002_DATA_LAST,
		C2H_003_DATA_MTY,
		//-------------------------- CMD/DATA
		C2H_100_CMD_DATA_INORDER,
		//-------------------------- STATUS
		C2H_200_STATUS_CORRESPOND,
		//-------------------------- INTERRUPT_SIDEBAND
		C2H_300_INTERRUPT_SIDEBAND_CORRESPOND,
		//-------------------------- DATA_SIDEBAND
		C2H_400_DATA_SIDEBAND_CORRESPOND,
		//--------------------------
		UNDEFINED_QDMAIF_C2H_PROTCL_ERR_ID_TYPE
	}QdmaifC2hProtclErrIdType_t;

	typedef enum int{
		//------------------------- CMD
		C2H_UNSUP_CMD_PFCH_TAG,
		C2H_UNSUP_CMD_ERROR,
		//------------------------- DATA
		C2H_UNSUP_DATA_MARKER,
		C2H_UNSUP_DATA_HAS_CMPT,
		C2H_UNSUP_DATA_ECC,
		C2H_UNSUP_DATA_CRC,
		//------------------------- STATUS
		C2H_UNSUP_STATUS_DROP,
		C2H_UNSUP_STATUS_ERROR,
		C2H_UNSUP_DATA_LEN_ZERO,
		//------------------------- 
		UNDEFINED_QDMAIF_C2H_UNSUP_FEATURE_ID_TYPE
	}QdmaifC2hUnsupFeatureIdType_t;

`endif // __VQDMAIF_C2H_DEF_SVH__
