/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Socket Project
 * MODULE:	  IrLAP driver
 * FILE:	  irlapDr.h
 *
 * AUTHOR:  	  Andy Chiu: Mar  7, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	AC	3/ 7/96   	Initial version
 *
 * DESCRIPTION:
 *	C definitions for the irlap driver
 *
 *
 * 	$Id: irlapDr.h,v 1.1 97/04/04 15:54:07 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _IRLAPDR_H_
#define _IRLAPDR_H_


/*  -------------------------------------------------------------------------
 *  DISCOVERY
 *  ------------------------------------------------------------------------*/

typedef ByteEnum IrlapUserTimeSlot;   
#define IUTS_1_SLOT	0x0
#define IUTS_6_SLOT	0x1
#define IUTS_8_SLOT	0x2
#define IUTS_16_SLOT	0x3

typedef ByteEnum IrlapDiscoveryType;		
#define IDT_DISCOVERY	        0x0   /*  normal discovery   */
#define IDT_ADDRESS_RESOLUTION	0x1   /*  address resolution */

/*
 *  From IrLMP spec: "It should be noted that the total number of bytes in
 *  the deviceInfo field must not exceed 23 bytes even though the IrLAP 
 *  specification allows up to 32 bytes.  This is to prevent the XID process
 *  from spilling over into the next slot.
 * 
 * DiscoveryInfo	TYPE	32 dup (byte)
 */
typedef byte DiscoveryInfo[23];

typedef WordFlags DiscoveryLogFlags;		/* CHECKME */
/*  1 if discovery success / 0 if failure */
#define DLF_VALID	(0x8000)
/*  Solicited discovery? */
#define DLF_SOLICITED	(0x4000)
/*  Sniffing device? */
#define DLF_SNIFF	(0x2000)
/*  Discovery failed because media is busy */
#define DLF_MEDIA_BUSY	(0x1000)
/*  Discovery aborted */
#define DLF_ABORTED	(0x0800)
/*  See NII_DISCOVERY_INDICATION */
#define DLF_REMOTE	(0x0400)
/* 1 bit unused */
/*  number of valid bytes in DL_info */
#define DLF_INFO_SIZE	(0x0100 | 0x0080 | 0x0040 | 0x0020 | 0x0010)
#define DLF_INFO_SIZE_OFFSET	4
/*  INTERNAL USE */
#define DLF_INDEX	(0x0008 | 0x0004 | 0x0002 | 0x0001)
#define DLF_INDEX_OFFSET	0

/*
 * 	DL_flags and DL_deviceAddr can only be filled in by the driver
 * 	(so the client should not worry about them)
 */
typedef struct {	 
    DiscoveryLogFlags	DL_flags;   /*  32 bit device address */
    dword         	DL_devAddr; /*  32 byte discovery information */
    DiscoveryInfo	DL_info;
} DiscoveryLog;

typedef ByteFlags DiscoveryBlockFlags;	
#define DBF_LOG_RCVD	(0x80)  /*  is set if any log has been received */
/* 7 bits unused */

typedef struct {     
    Handle               DLB_blockHandle;  /*  block handle */
    DiscoveryBlockFlags	 DLB_flags;
    byte	         DLB_lastIndex;    /*  last log index = numLogs */
} DiscoveryLogBlock;

/*  -----------------------------------------------------------------------
 *  QUALITY OF SERVICE
 *  ------------------------------------------------------------------------*/

/*  Baud rate negotiation param in bps */
typedef ByteFlags IrlapParamBaudRate;  
#define IPBR_RESERVED	(0x80 | 0x40) /*  reserved and cleared */
#define IPBR_RESERVED_OFFSET	6
#define IPBR_115200BPS	(0x20)
#define IPBR_57600BPS	(0x10)
#define IPBR_38400BPS	(0x08)
#define IPBR_19200BPS	(0x04)
#define IPBR_9600BPS	(0x02)
#define IPBR_2400BPS	(0x01)

/*  Maximum Turnaround time */
typedef ByteFlags IrlapParamMaxTurnAround;
#define IPMTA_RESERVED	(0x80)
#define IPMTA_5MS	(0x40)   /*  Only valid at 115200 bps */
#define IPMTA_10MS	(0x20)   /*  Only valid at 115200 bps */
#define IPMTA_25MS	(0x10)   /*  Only valid at 115200 bps */
#define IPMTA_50MS	(0x08)   /*  Only valid at 115200 bps */
#define IPMTA_100MS	(0x04)
#define IPMTA_250MS	(0x02)
#define IPMTA_500MS	(0x01)

/*  Data size negotiation param in bytes */
typedef ByteFlags IrlapParamDataSize; 
#define IPDS_RESERVED	(0x80 | 0x40) /*  reserved and cleared */
#define IPDS_RESERVED_OFFSET	6
#define IPDS_2048BYTES	(0x20)
#define IPDS_1024BYTES	(0x10)
#define IPDS_512BYTES	(0x08)
#define IPDS_256BYTES	(0x04)
#define IPDS_128BYTES	(0x02)
#define IPDS_64BYTES	(0x01)

/*  Window size negotiation param in frames */
typedef ByteFlags IrlapParamWindowSize;
#define IPWS_RESERVED	(0x80)  /*  reserved and cleared */
#define IPWS_7FRAME	(0x40)
#define IPWS_6FRAME	(0x20)
#define IPWS_5FRAME	(0x10)
#define IPWS_4FRAME	(0x08)
#define IPWS_3FRAME	(0x04)
#define IPWS_2FRAME	(0x02)
#define IPWS_1FRAME	(0x01)  /*  (lsb, transmitted first) */

/*  number of additional BOF at 115200  */
typedef ByteFlags IrlapParamNumBof;	  
#define IPNB_0BOF	(0x80)
#define IPNB_1BOF	(0x40)
#define IPNB_2BOF	(0x20)
#define IPNB_3BOF	(0x10)
#define IPNB_5BOF	(0x08)
#define IPNB_12BOF	(0x04)
#define IPNB_24BOF	(0x02)
#define IPNB_48BOF	(0x01)

typedef ByteFlags IrlapParamMinTurnaround;  
#define IPMT_0MS	(0x80)   /*  0ms    */
#define IPMT_001MS	(0x40)   /*  0.01ms */
#define IPMT_005MS	(0x20)   /*  0.05ms */
#define IPMT_01MS	(0x10)   /*  0.1ms  */
#define IPMT_05MS	(0x08)   /*  0.5ms  */
#define IPMT_1MS	(0x04)
#define IPMT_5MS	(0x02)
#define IPMT_10MS	(0x01)

/*  Link Disconnect/threshold Time: 6.6.11  */
typedef ByteFlags IrlapParamLinkDisconnect;		/* CHECKME */
#define IPLTT_40SEC	(0x80)  /*  (thresholdequ3sec) */
#define IPLTT_30SEC	(0x40)  /*  (thresholdequ3sec) */
#define IPLTT_25SEC	(0x20)  /*  (thresholdequ3sec) */
#define IPLTT_20SEC	(0x10)  /*  (thresholdequ3sec) */
#define IPLTT_16SEC	(0x08)  /*  (thresholdequ3sec) */
#define IPLTT_12SEC	(0x04)  /*  (thresholdequ3sec) */
#define IPLTT_8SEC	(0x02)  /*  (thresholdequ3sec) */
#define IPLTT_3SEC	(0x01)  /*  (thresholdequ0)    */

/*
 *  connection parameter structure within station structure
 *  NOTE: the ordering of fields is critical
 * 
 *  ICP_baudRate and ICP_linkDisconnect are "type 0" parameters that must
 *  be negotiated to the same value for both stations involved in a connection.
 *  Other parameters are of "type 1", and are negotiated independently for 
 *  both stations involved in a connection.
 */
typedef struct {      
    IrlapParamBaudRate	        ICP_baudRate;
    IrlapParamMaxTurnAround	ICP_maxTurnAround;
    IrlapParamDataSize	        ICP_dataSize;
    IrlapParamWindowSize	ICP_windowSize;
    IrlapParamNumBof         	ICP_numBof;
    IrlapParamMinTurnaround	ICP_minTurnAround;
    IrlapParamLinkDisconnect	ICP_linkDisconnect;
    byte                        ICP_unused;  /*	align	word */
} IrlapConnectionParams;


typedef WordFlags QualityOfServiceFlags;		/* CHECKME */
#define QOSF_DEFAULT_PARAMS	(0x8000)
/* 15 bits unused */

typedef struct { 
    IrlapConnectionParams   QOS_param; 
    dword	            QOS_devAddr;  /*  address to connect to */
    QualityOfServiceFlags   QOS_flags;
} QualityOfService;


/*  --------------------------------------------------------------------------
 *  STATUS
 *  -------------------------------------------------------------------------*/

typedef WordFlags ConnectionStatus; 
/*  connection is in jeopardy */
#define CS_IMPENDING_DISCONNECTION	(0x8000)
/*  there are unacked data in send buffer */
#define CS_UNACKED_DATA	(0x4000)
/* 14 bits unused */

typedef enum {
    ISIT_CONNECTED = 0x01,
    ISIT_BLOCKED = 0x02,
    ISIT_OK = 0x03,
    ISIT_DISCONNECTED = 0x04,
} IrlapStatusIndicationType;

#endif /* _IRLAPDR_H_ */


