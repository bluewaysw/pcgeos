/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  GEOS
 * MODULE:	  Irlmp
 * FILE:	  irlmp.h
 *
 * AUTHOR:  	  Andy Chiu: Mar  5, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	AC	3/ 5/96   	Initial version
 *
 * DESCRIPTION:
 *	
 *
 *
 * 	$Id: irlmp.h,v 1.1 97/04/04 15:59:43 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _IRLMP_H_
#define _IRLMP_H_

/* ----------------------------------------------------------------------------
 * 			COMPILER DIRECTIVES
 * ----------------------------------------------------------------------------*/

#define GENOA_TEST	(0)
#if GENOA_TEST
PrintMessage	<Turn this flag of before shipping...>
#endif


#include	<Internal/irlapDr.h>

/* ---------------------------------------------------------------------------
 * 
 * 				LSAP
 * 
 * ---------------------------------------------------------------------------*/

typedef	byte IrlmpLsapSel;

#define IRLMP_ANY_LSAP_SEL	(0xFF)
/*
 *  Not a true LSAP-Sel.  Pass this to IrlmpRegister when no specific 
 *  LSAP-Sel is requested.
 */

#define IRLMP_MONITOR_LSAP_SEL	(0x82)
/*
 *  Register to this LSAP in order to receive IIC_STATUS_INDICATION only.
 */

#define IRLMP_PENDING_CONNECT	(0x81)
/*
 *  Not a true LSAP-Sel.  This indicates that we are still waiting for 
 *  a PDU to establish the IrLMP level connection, and the peer LSAP-Sel 
 *  is still unknown.
 */

#define IRLMP_XID_DISCOVERY_SAP	(0x80)
/*
 *  Not a true LSAP-Sel.  Pass this to IrlmpRegister to indicate that 
 *  client wishes to bind to the XID_Discovery Service Access Point,
 *  in order to receive LM_DiscoverDevices.indication only.
 */

#define IRLMP_IAS_LSAP_SEL	(0x00)
/*
 *  Reserved for IAS. Only a client prepared to respond to IAS queries
 *  should bind to this LSAP-Sel.
 */

#define IRLMP_CONNECTIONLESS_LSAP_SEL	(0x70)
/*
 *  Reserved for Connectionless Data service, which is not currently
 *  supported in this implementation.
 */
	
#define IRLMP_BROADCAST_LSAP_SEL	(0x7F)
/*  Reserved for broadcast data, which is not currently supported. */

#define IRLMP_MAX_LEGAL_LSAP_SEL	(0x80)
/*  LSAPs with values above 0x6F are reserved. */

typedef struct {
/* 32-bit IrLAP device address */
    dword		ILI_irlapAddr;
    IrlmpLsapSel	ILI_lsapSel;
    byte		ILI_unused;	/* align word */
} IrlmpLsapID;

/* ------------------------------------------------------------------------
 * 
 * 			Structs for requests
 * 
 * ------------------------------------------------------------------------*/

#if GENOA_TEST

/*
 *  I added these options to make irlap handle data requests deterministically.
 *  For instance, Genoa test suite expects us to send multiple frames in
 *  response to a certain trigger data, but if we don't do anything special like
 *  this, data requests will be enqueued and there is no saying when they will
 *  be sent out.  Suspending irlap then enqueueing requests and then unsuspending
 *  irlap guarantees that the data requests enqueued in between suspending and
 *  unsuspending irlap will be sent out in one window( or as much of it as
 *  possible will be sent out in one window ).
 * 							- SJ
 */

typedef WordFlags IrlmpDataArgFlag;
/*  suspend IrLAP thread before enqueueing data request */
#define IDAF_SUSPEND_IRLAP	(0x8000)
/*  unsuspend IrLAP thread after enqueueing request */
#define IDAF_UNSUSPEND_IRLAP	(0x4000)
/* 14 bits unused */

#endif

/*
 *  Data is passed to the Irlmp Library in a HugeLMem buffer allocated
 *  with the NetUtils Library.  The Irlmp Library will free the HugeLMem
 *  buffer when done transmitting the data.
 * 
 *  The data buffer HugeLMem block must have IRLMP_HEADER_SIZE bytes of 
 *  free space before the actual data (or TTP_HEADER_SIZE bytes, if using 
 *  TinyTP.)  In other words, IDA_dataOffset must be equal or greater than 
 *  IRLMP_HEADER_SIZE (or TTP_HEADER_SIZE).  This space is used by the Irlmp 
 *  Library to place its (and TinyTP's) PDU header, before passing the data to 
 *  the IrLAP Driver.
 */

typedef struct {
    word	IDA_dataSize;
/*
 *  IDA_dataOffset and IDA_data are only valid if IDA_dataSize > 0
 *  The maximum IDA_dataSize is ICA_QoS.QOS_param.ICP_dataSize minus
 *  either IRLMP_HEADER_SIZE or TTP_HEADER_SIZE.
 */

    word	IDA_dataOffset;
/*
 *  Offset into IDA_data where the real data starts.  IDA_dataOffset
 *  must be at least IRLMP_HEADER_SIZE (or TTP_HEADER_SIZE for TinyTP
 *  requests), providing room in IDA_data for the IrLMP and IrLAP 
 *  (and TinyTP) packet headers.
 */

    optr	IDA_data;
/*
 *  HugeLMem data allocated with the NetUtils Library.  When passed
 *  to the Irlmp Library, the library frees the data when done using
 *  it.  When passed to a client callback, the callback routine is
 *  responsible for freeing this data by calling HugeLMemFree.
 */

#if GENOA_TEST
    IrlmpDataArgFlag	IDA_flags;
/*
 *  I am adding this flag to pass special information into IRDA stack
 *  see record definition
 */
#endif

} IrlmpDataArgs;

#define IRLMP_HEADER_SIZE	(4)
#define TTP_HEADER_SIZE	(IRLMP_HEADER_SIZE + 1)

typedef struct {
word		ICA_dataSize;
/*
 *  Maximum size is 60 bytes for IrLMP, and 53 bytes for TinyTP.  
 *  ICA_dataOffset and ICA_data are only valid if ICA_dataSize > 0.
 */

word		ICA_dataOffset;
/*
 *  Offset into ICA_data where the real data starts.  IDA_dataOffset
 *  must be at least IRLMP_HEADER_SIZE (or TTP_HEADER_SIZE), providing 
 *  room in ICA_data for the IrLMP and IrLAP (and TinyTP) packet 
 *  headers.
 */

optr		ICA_data;
/*
 * HugeLMem data
 *  HugeLMem data allocated with the NetUtils Library.  When passed
 *  to the Irlmp Library, the library frees the data when done using
 *  it.  When passed to a client callback, the callback routine is
 *  responsible for freeing this data by calling HugeLMemFree.
 */

IrlmpLsapID	ICA_lsapID;
/*  LSAP-ID of remote device */

QualityOfService	ICA_QoS;
/*
 *  QOS_devAddr field is always ignored; the IrLAP address should
 *  be passed in ICA_lsapID.  If QOSF_DEFAULT_PARAMS is set, then
 *  the QOS_param field is ignored, and default params are read in
 *  from the initfile.
 */

} IrlmpConnectArgs;

/* ----------------------------------------------------------------------
 * 
 *  			Error Codes
 * 
 * ----------------------------------------------------------------------*/

/* enum IrlmpError */
typedef enum {

    IE_SUCCESS = 0x0,

    IE_LSAP_SEL_IN_USE = 0x2,
/*  The requested LSAP-Sel is already being used by another client */

    IE_NO_FREE_LSAP_SEL = 0x4,
/*  All legal LSAP-Sel values are in use. */

    IE_LSAP_DISCONNECTED = 0x6,
    IE_UNABLE_TO_LOAD_IRLAP_DRIVER = 0x8,
    IE_ALREADY_CONNECTED = 0xa,
    IE_INCOMING_CONNECTION = 0xc,
    IE_RESPONSE_WITHOUT_INDICATION = 0xe,
    IE_LSAP_NOT_DISCONNECTED = 0x10,

    IE_IAS_CONNECTED_TO_ANOTHER_ADDRESS = 0x12,
/*  The IAS Client FSM is already connected to a different IrLAP address. */

    IE_LSAP_NOT_CONNECTED_TO_IAS = 0x14,
/*
 *  IrlmpDisconnectIas was called, but the endpoint did not make any IAS
 *  queries.
 */

    IE_DISCONNECT_INDICATION = 0x16,
/*  Lost connection to peer IAS LSAP in the middle of IAS query. */

    IE_TTP_TX_QUEUE_FULL = 0x18,
} IrlmpError;
/*
 *  The TinyTP TxQueue is full; therefore, no data requests can be accepted.
 *  Caller should try again later.
 */


/* ---------------------------------------------------------------------------
 * 
 * 				IAS 
 * 
 * ---------------------------------------------------------------------------*/

/*
 *  Class and Attribute names are preceded by an 8-bit size byte.
 */
typedef struct {	
    byte	IINH_size;
/*    label 	char	IINH_name; */
} IrlmpIasNameHeader;

/*
 *  Maximum size for a Class or Attribute name is 60 bytes.
 */
#define IRLMP_IAS_MAX_NAME_SIZE	(60)

typedef struct {	
    byte	IIMN_size;
    char	IIMN_name[IRLMP_IAS_MAX_NAME_SIZE];
} IrlmpIasMaxName;

/*
 *  Each object in the IAS database has an object ID.  
 */
typedef word IrlmpIasObjectIdentifier;

/*
 *  Values for attributes are encoded so that the first byte indicates the
 *  object type.
 */
typedef ByteEnum IrlmpIasValueType;
#define IIVT_MISSING		0x0
#define IIVT_INTEGER		0x1
#define IIVT_OCTET_SEQUENCE	0x2
#define IIVT_USER_STRING	0x3

/*
 *  IIVT_INTEGER type object.
 */
typedef dword IrlmpIasIntegerValue;

/*
 *  IIVT_OCTET_SEQUENCE type object.
 */
typedef struct {	
    word	IIOSH_size;
/*    label	byte	IIOSH_value; */
} IrlmpIasOctetSequenceHeader;

/*
 *  Objects of type IIVT_USER_STRING have the character set encoded as part
 *  of the value.
 */
typedef ByteEnum IrlmpIasCharSetCode;	
#define IICSC_ASCII		0x0
#define IICSC_ISO_8859_1	0x1
#define IICSC_ISO_8859_2	0x2
#define IICSC_ISO_8859_3	0x3
#define IICSC_ISO_8859_4	0x4
#define IICSC_ISO_8859_5	0x5
#define IICSC_ISO_8859_6	0x6
#define IICSC_ISO_8859_7	0x7
#define IICSC_ISO_8859_8	0x8
#define IICSC_ISO_8859_9	0x9
#define IICSC_UNICODE		0xff

/*
 *  Object of type IIVT_USER_STRING
 */
typedef struct {
    IrlmpIasCharSetCode	IIUSH_charSet;
    byte		IIUSH_size;
/*    label	char	IIUSH_value; */
} IrlmpIasUserStringHeader;

/*
 *  Union of the possible types for the IIAV_value field.
 */
typedef union {
    IrlmpIasIntegerValue	IIVU_integer;
    IrlmpIasOctetSequenceHeader	IIVU_octetSequence;
    IrlmpIasUserStringHeader	IIVU_userString;
} IrlmpIasValueUnion;

/*
 *  IAS attribute value, with value type.
 */
typedef struct {
    IrlmpIasValueType	IIAV_type;
    IrlmpIasValueUnion	IIAV_value;
} IrlmpIasAttributeValue;




/* -------------------------------------------------------------------------
 * 
 * 	       Stuctures and types for Irlmp
 *  
 * -------------------------------------------------------------------------*/
typedef Handle ClientHandle;

/* -----------------------------------------------------------------------
 * 
 *  	Indications and Confirmations For Client Callback Routine.
 * 
 * -----------------------------------------------------------------------*/

/*
 *  The routine passed to IrlmpRegister will be called for Irlmp indications
 *  and confirmations.  The callback runs on the irlmp thread, so it should
 *  be as short as possible.  The arguments passed to the callback are not
 *  valid after the callback exits, so it should copy the needed information 
 *  rather than storing pointers.
 */

/* enum IrlmpIndicationOrConfirmation */
typedef enum {

    IIC_DISCOVER_DEVICES_INDICATION = 0x0,
/*
 *  Indication to clients bound to IRLMP_XID_DISOVERY_SAP that a remote 
 *  machine discovered the local machine.
 * 
 * 	Pass:		client	= client handle of requester
 * 			extra	= extra word passed to IrlmpRegister
 * 			data 	= optr of chunk array of DiscoveryLog. 
 *                                Not valid
 * 				  after callback returns, so callback should
 * 			    	  copy whatever information it wants to keep.
 * 				  DL_info begins with IrlmpDiscoveryServiceA,
 * 				  possibly followed by IrlmpDiscoveryServiceB,
 * 				  possibly followed by other service hints.
 * 				  Following that is the device's name, as
 * 				  an IAS User String (without the type)
 * 	Return: 	nothing
 * 	Destroy:	nothing
 */

    IIC_DISCOVER_DEVICES_CONFIRMATION = 0x2,
/*
 *  Results of discovery.
 * 
 * 	Pass:		client	= client handle of requester
 * 			extra	= extra word passed to IrlmpRegister
 * 			status	= IrlmpDiscoveryStatus
 * 		        data 	= optr of chunk array of DiscoveryLog. 
 *                                Not valid
 * 				  after callback returns, so callback should
 * 			    	  copy whatever information it wants to keep.
 * 				  DL_info begins with IrlmpDiscoveryServiceA,
 * 				  possibly followed by IrlmpDiscoveryServiceB,
 * 				  possibly followed by other service hints.
 * 				  Following that is the device's name, as
 * 				  an IAS User String (without the type)
 */

    IIC_CONNECT_INDICATION = 0x4,
/*
 *  A remote LSAP wants to establish a connection to the LSAP that received
 *  this indication.  The callback should respond with either
 *  IrlmpConnectResponse or IrlmpDisconnectRequest.
 * 
 * 	Pass:		client	= client handle
 * 			extra	= extra word passed to IrlmpRegister
 * 			data	= IrlmpConnectArgs.  If ICA_dataSize > 0, then
 * 				  callback must free the ICA_data.
 * 	Return:		nothing
 * 	Destroy:	nothing
 */

    IIC_CONNECT_CONFIRMATION = 0x6,
/*
 *  Connect request was accepted.
 * 
 * 	Pass:		client	= client handle
 * 			extra	= extra word passed to IrlmpRegister
 * 			data	= IrlmpConnectArgs.  If ICA_dataSize > 0, then
 * 				  callback must free the ICA_data.
 * 				  Note that ICA_QoS.QOS_param.ICP_dataSize
 * 				  provides the maximum data size for the 
 * 				  IrLAP layer.  The client's maximum data
 * 				  size is this value minus IRLMP_HEADER_SIZE.
 */

    IIC_DISCONNECT_INDICATION = 0x8,
/*
 *  Connection was terminated.
 * 
 * 	Pass:		client	= client handle
 * 			extra	= extra word passed to IrlmpRegister
 * 			status	= IrlmpDisconnectReason
 * 			data 	= IrlmpDataArgs.  If IDA_dataSize > 0, then
 * 				  callback must free the data.
 * 	Return:		nothing
 * 	Destroy:	nothing
 */

    IIC_STATUS_INDICATION = 0xa,
/*
 *  Remote device requested status, or current connection is in jeopardy.
 * 
 * 	Pass:		client	= client handle
 * 			extra	= extra word passed to IrlmpRegister
 * 			status	= ConnectionStatus (from IrLAP)
 */

    IIC_STATUS_CONFIRMATION = 0xc,
/*
 *  Received connection status from remote side.
 *  
 * 	Pass:		client	= client handle
 * 			extra	= extra word passed to IrlmpRegister
 * 			status	= ConnectionStatus
 */

    IIC_DATA_INDICATION = 0xe,
/*
 *  Incoming data indication.
 * 
 * 	Pass:		client	= client handle
 * 			extra	= extra word passed to IrlmpRegister
 * 			data	= IrlmpDataArgs.  If IDA_dataSize > 0, then
 * 				  callback must free the data.
 */
    IIC_UDATA_INDICATION = 0x10,
/*
 *  Incoming UData indication.
 * 
 * 	Pass:           client  = ClientHandle
 * 			extra	= extra word passed to IrlmpRegister
 * 			data	= IrlmpDataArgs.  If IDA_dataSize > 0, then
 * 				  callback must free the data.
 * 				
 */

/* ----------------------------------------------------------------------
 * 
 * 			IAS Confirmations
 * 
 * ----------------------------------------------------------------------*/

    IIC_GET_VALUE_BY_CLASS_CONFIRMATION = 0x12,

    IIC_LAST_VALUE = 0x12,
} IrlmpIndicationOrConfirmation;
/*
 *  Results of IAS query.
 * 
 * 	Pass:           client  = ClientHandle
 * 			extra	= extra word passed to IrlmpRegister
 *                      data    = optr to chunk array of IrlmpIasIdAndValue
 *                      status  = IrlmpGetValueByClassReturnCode
 *                      if error IrlmpError is returned by ThreadGetError
 *
 */


typedef ByteEnum IrlmpDisconnectReason;
#define IDR_USER_REQUEST				0x1
#define IDR_UNEXPECTED_IRLAP_DISCONNECT			0x2
#define	IDR_FAILED_TO_ESTABLISH_IRLAP_CONNECTION 	0x3
#define IDR_IRLAP_RESET					0x4
#define IDR_LINK_MANAGEMENT_DISCONNECT			0x5
#define IDR_DATA_ON_DISCONNECTED_LSAP			0x6
#define	IDR_NON_RESPONSIVE_LM_MUX_CLIENT 		0x7
#define IDR_NO_AVAILABLE_LM_MUX_CLIENT			0x8
#define IDR_UNSPECIFIED					0xff

/* This is slightly different from the assembly version */
typedef struct { 
    dword	         IGVBCRA_irlapAddr;
    char                *IGVBCRA_className;
    char                *IGVBCRA_attributeName;
} IrlmpGetValueByClassRequestArgs;

typedef ByteEnum IrlmpDiscoveryStatus; 
#define IDS_DISCOVERY	0x0  /*  Returning results of actual discovery. */
#define IDS_CACHED	0x1  /*  Already connected.  Returning cached discovery log info. */
#define IDS_PASSIVE	0x2  /*  Remote device discovered us.   */


typedef ByteFlags IrlmpDiscoveryServiceA;  
#define IDSA_EXTENDED	(0x80)  /* set means IrlmpDiscoveryServiceB byte is */
				/*  present                                 */
#define IDSA_LAN_ACCESS	(0x40)  /* set means device provides access to a LAN*/
#define IDSA_FAX	(0x20)  /* set means device provides fax service */
#define IDSA_MODEM	(0x10)  /* set means device provides data modem  */
                                /*  service                              */
#define IDSA_PRINTER	(0x08)  /* set means device provides hardcopy (and */
                                /*   usually supports IrLPT protocol) */
#define IDSA_COMPUTER	(0x04)  /* set means device is a personal computer */
                                /*   (desktop/laptop)                      */
#define IDSA_PDA	(0x02)  /* set means device is a PDA or            */
                                /* palmtop computer                        */ 
#define IDSA_PNP_COMPATIBLE	(0x01) /* set means device is Plug-N-Play */
                                       /*  compatible (contains all       */
                                       /*  required PnP attributes        */
                                       /*  in the IAS)                    */
    


typedef ByteFlags IrlmpDiscoveryServiceB;		/* CHECKME */
#define IDSB_EXTENDED	 (0x80)  /*  set means further service bytes whose */
                                 /*   meaning is unknown follow            */
/* 4 bits unused */
#define IDSB_IRCOMM	 (0x04)  /*  set means device provides IrCOMM service */
#define IDSB_FILE_SERVER (0x02)  /*  set means device is a file server */
#define IDSB_TELEPHONY	(0x01)   /*  set means device is a telephone  */
                                 /* switch/PBX of some sort?          */

typedef struct {	    
    IrlmpIasObjectIdentifier	IIIAV_id;
    IrlmpIasAttributeValue	IIIAV_value;
} IrlmpIasIdAndValue;

typedef ByteEnum IrlmpGetValueByClassReturnCode;
#define IGVBCRC_SUCCESS	                0x0
#define IGVBCRC_NO_SUCH_CLASS	        0x1
#define IGVBCRC_NO_SUCH_ATTRIBUTE	0x2
#define IGVBCRC_IRLMP_ERROR	        0xff
/*
 *  Not an IAS-defined return code.  This means that the request failed
 *  because of some IrLMP error, such as a lost connection.
 */

typedef void _pascal IrlmpCallbackType (ClientHandle client,
			   IrlmpIndicationOrConfirmation type,
			   word extra,
			   dword data, 
			   word status);


/* -------------------------------------------------------------------------
 * 
 * 				TinyTP
 * 
 *  Applications wishing to use the TinyTP flow control mechanism must
 *  use the routines below, instead of their IrLMP counterparts.
 * 
 * -----------------------------------------------------------------------*/


IrlmpError
_pascal TTPRegister(IrlmpLsapSel *lsapSel, word extraData, 
		      PCB(void, callback, (ClientHandle client,
					   IrlmpIndicationOrConfirmation type,
					   word extra,
					   dword data, 
					   word status)),
		      ClientHandle *clientHandle);
/*
 * 	Desc:	Register to use TinyTP.  Client using TTPRegister must
 * 		use:
 * 			TTPConnectRequest
 * 			TTPConnectResponse
 * 			TTPDataRequest
 * 			TTPDisconnectRequest
 * 		instead of:
 * 			IrlmpConnectRequest
 * 			IrlmpConnectResponse
 * 			IrlmpDataRequest
 * 			IrlmpDisconnectRequest
 * 
 * 		The client callback will receive:
 * 			TTPIC_CONNECT_INDICATION
 * 			TTPIC_CONNECT_CONFIRMATION
 * 			TTPIC_DATA_INDICATION
 * 			TTPIC_DISCONNECT_INDICATION
 * 		instead of:
 * 			IIC_CONNECT_INDICATION
 * 			IIC_CONNECT_CONFIRMATION
 * 			IIC_DATA_INDICATION
 * 			IIC_DISCONNECT_INDICATION
 * 
 * 		Other functions and callbacks are the same as when using
 * 		IrlmpRegister.
 * 
 * 	Pass:	same as IrlmpRegister
 * 	Return:	same as IrlmpRegister
 */


IrlmpError
_pascal TTPUnregister(ClientHandle client);
/*
 * 	Desc:	Same as IrlmpUnregister
 * 	Pass:	Same as IrlmpUnregister
 * 	Return:	Same as IrlmpUnregister
 */

IrlmpError
_pascal TTPConnectRequest(ClientHandle client, IrlmpConnectArgs *connectArgs);
/*
 * 	Desc:	Request that a TinyTP connection be established to a remote
 * 		IrlmpLsapID.
 * 	Pass:	Same as IrlmpConnectRequest
 * 	Return:	Same as IrlmpConnectRequest
 */
	
IrlmpError
_pascal TTPConnectResponse(ClientHandle client, IrlmpDataArgs *dataArgs);
/*
 * 	Desc:	Accept a TinyTP connection initiated by a remote device.
 * 		To reject a connection, use TTPDisconnectRequest.
 * 	Pass:	same as IrlmpConnectResponse
 * 	Return:	same as IrlmpConnectResponse
 */

IrlmpError
_pascal TTPDataRequest(ClientHandle client, IrlmpDataArgs *dataArgs);
/*
 * 	Desc:	Send data through the TinyTP connection.
 * 	Pass:	si	= client handle
 * 		cx:dx	= IrlmpDataArgs.  IDA_dataSize must not be larger than
 * 			(ICA_QoS.QOS_param.ICP_dataSize - TTP_HEADER_SIZE).
 * 	Return: carry clear if okay:
 * 			ax	= IE_SUCCESS
 * 		carry set if error:
 * 			ax	= IrlmpError
 * 					IE_LSAP_DISCONNECTED
 * 					IE_TTP_TX_QUEUE_FULL
 */

word
_pascal TTPTxQueueGetFreeCount(ClientHandle client);
/*
 * 	Desc:	Returns the number of calls to TTPDataRequest that can be
 *  		handled before TxQueue is full. 
 * 	Pass:	si	= client handle
 *  	Return:	cx	= free count (send credits + free TxQueue entries)
 */

IrlmpError
_pascal TTPDisconnectRequest(ClientHandle client, IrlmpDataArgs *dataArgs);
/*
 * 	Desc:	Terminate TinyTP connection.
 * 	Pass:	si	= client handle
 * 		cx:dx	= IrlmpDataArgs
 * 	Return: carry clear if okay:
 *			ax	= IE_SUCCESS
 *		carry set if error:
 *			ax	= IrlmpError
 */

IrlmpError
_pascal TTPStatusRequest(ClientHandle client);
/*
 * 	Desc:	Check for unacked data
 * 	Pass:	si	= client handle
 *	Return:	carry clear if okay:
 *			ax	= IE_SUCCESS
 *		carry set if error:
 *			ax	= IrlmpError
 *
 * 	Return:	
 */

void
_pascal TTPAdvanceCredit(ClientHandle client, word credits);
/*
 * 	Desc:	Increase available credit to advance to peer
 * 	Pass:	si	= client handle
 * 		cx	= # credits
 * 	Return:	nothing
 */


/* -------------------------------------------------------------------------
 * 
 * 	 			Routines
 *  
 * -------------------------------------------------------------------------*/


IrlmpError
_pascal IrlmpRegister(IrlmpLsapSel *lsapSel, word extraData, 
		      PCB(void, callback, (ClientHandle client,
					   IrlmpIndicationOrConfirmation type,
					   word extra,
					   dword data, 
					   word status)),
		      ClientHandle *clientHandle);
/* 
 * 	Desc:	Client must call this function before any IrLMP requests,
 * 		so that indications and confirmations can be delivered.
 * 		A geode that uses the IrLMP Library can call this function
 * 		multiple times, if it is interested in registering for
 * 		more than one LSAP-Sel.
 * 
 * 	Pass:	cl	= IrlmpLsapSel (could be IRLMP_ANY_LSAP_SEL)
 * 		dx:ax	= vfptr of callback for indications and confirmations
 * 		bx	= extra word to be passed to callback (could be
 * 			  caller's dgroup, process handle, or whatever is
 * 			  useful.)
 * 
 * 	Return: carry clear if okay:
 * 			ax	= IE_SUCCESS
 * 			cl	= IrlmpLsapSel (actual LSAP-Sel, if 
 * 				  IRLMP_ANY_LSAP_SEL was passed in.)
 * 			si	= client handle
 * 		carry set if error:
 * 			ax	= IrlmpError
 * 					IE_NO_FREE_LSAP_SEL
 * 					IE_UNABLE_TO_LOAD_IRLAP_DRIVER
 * 			cx, si destroyed
 * 	Callback:
 * 		Pass:	 di	= IrlmpIndicationOrConfirmation
 * 			 si	= client handle
 * 			 bx	= extra word passed to IrlmpRegister
 * 			 Other registers depend on di
 * 		Return:	 nothing
 * 		Destroy: nothing
 */

void
_pascal IrlmpUnregister(ClientHandle client);
/* 
 * 	Desc:	Stop receiving callbacks for the LSAP-Sel.  This routine
 * 		may be called from the client's callback routine; however,
 * 		afterwards arguments passed to the callback become invalid.
 * 
 * 	Pass:	si	= client handle
 * 	Return: carry clear if okay:
 *			ax	= IE_SUCCESS
 *		carry set if error:
 *			ax 	= IE_LSAP_NOT_DISCONNECTED
 *
 */

IrlmpError
_pascal IrlmpDiscoverDevicesRequest(ClientHandle client, word timeSlot);
/*
 * 	Desc:	Look for remote machines.  If link is currently in use, the
 * 		cached result of the last discovery operation is returned.
 * 		Otherwise, initiate IrLAP discovery. The callback is to 
 * 		receive the confirmation for the discovery request.
 * 
 * 	Pass:	si	= client handle, bound to IRLMP_XID_DISCOVERY_SAP
 * 		bl	= IrlapUserTimeSlot
 * 	Return: carry clear:
 * 		ax	= IE_SUCCESS
 */

IrlmpError
_pascal IrlmpConnectRequest(ClientHandle client, IrlmpConnectArgs *connectArgs);
/*
 * 	Desc:	Request that a connection be established to a remote 
 * 		LSAP-ID.
 * 	Pass:	si	= client handle
 * 		cx:dx	= IrlmpConnectArgs.  Up to 60 bytes of data
 * 			may be transmitted along with the request.
 * 
 * 	Return: carry clear if okay:
 * 			ax	= IE_SUCCESS
 * 		carry set if error:
 * 			ax	= IrlmpError
 * 					IE_ALREADY_CONNECTED
 */

IrlmpError
_pascal IrlmpConnectResponse(ClientHandle client, IrlmpDataArgs *dataArgs);
/*
 * 	Desc:	Accept a connection initiated by a remote device. 
 * 		To reject a connection, use IrlmpDisconnectRequest.
 * 	Pass:	si	= client handle
 * 		cx:dx	= IrlmpDataArgs. 
 * 
 * 	Return: carry clear if okay:
 * 			ax	= IE_SUCCESS
 * 		carry set if error:
 * 			ax	= IrlmpError
 * 					IE_LSAP_DISCONNECTED
 */

IrlmpError
_pascal IrlmpDisconnectRequest(ClientHandle client, IrlmpDataArgs *dataArgs,
			       word reason);
/*
 * 	Desc:	Terminate a connection.
 * 	Pass:	si	= client handle
 * 		cx:dx	= IrlmpDataArgs.  There is no guarantee
 * 			  that the data will be delivered.
 * 		bl	= IrlmpDisconnectReason
 * 	Return: carry clear if okay:
 * 			ax	= IE_SUCCESS
 * 		carry set if error:
 * 			ax	= IrlmpError
 * 					IE_LSAP_DISCONNECTED
 */

IrlmpError
_pascal IrlmpStatusRequest(ClientHandle client);
/*
 * 	Desc:	Check if there is unacknowledged data in the IrLAP queue.
 * 	Pass:	si	= client handle
 * 	Return: carry clear if okay:
 * 			ax	= IE_SUCCESS
 * 		carry set if error:
 * 			ax	= IrlmpError
 * 					IE_LSAP_DISCONNECTED
 */

IrlmpError
_pascal IrlmpDataRequest(ClientHandle client, IrlmpDataArgs *dataArgs);
/*
 * 	Desc:	Send data through the connection.
 * 	Pass:	si	= client handle
 * 		cx:dx	= IrlmpDataArgs.  IDA_dataSize must not be larger than
 * 			(ICA_QoS.QOS_param.ICP_dataSize - IRLMP_HEADER_SIZE).
 * 	Return: carry clear if okay:
 * 			ax	= IE_SUCCESS
 * 		carry set if error:
 * 			ax	= IrlmpError
 * 					IE_LSAP_DISCONNECTED
 */

IrlmpError
_pascal IrlmpUDataRequest(ClientHandle client, IrlmpDataArgs *dataArgs);
/*
 * 	Desc: 	Send UI frame data.
 * 	Pass:	si	= client handle
 * 		cx:dx	= IrlmpDataArgs
 * 	Return: carry clear if okay:
 * 			ax	= IE_SUCCESS
 * 		carry set if error:
 * 			ax	= IrlmpError
 * 					IE_LSAP_DISCONNECTED
 */

word
_pascal IrlmpGetPacketSize(IrlapParamDataSize dataSize);
/*
 * 	Desc:	Converts IrlapParamDataSize to number of bytes
 * 	Pass:	ax	= IrlapParamDataSize
 * 	Return:	cx	= data size
 */

/* ------------------------------------------------------------------------------
 * 
 * 			IAS Requests
 * 
 * ------------------------------------------------------------------------------*/

IrlmpError
_pascal IrlmpDisconnectIas(ClientHandle client);
/*
 * 	Desc:	Terminate the IrLMP-level IAS connection to the remote peer.  
 * 		The first IAS request to a remote peer implicity establishes
 * 		an IrLMP connection to the IRLMP_IAS_LSAP_SEL of the peer.
 *  		This connection is not automatically broken after the IAS 
 * 		query is completed, because almost always the first IAS query
 *  		is followed by other IAS queries or an IrlmpConnectRequest.
 * 		This way the time-consuming step of terminating and
 * 		re-establishing the same IrLAP connection is avoided.  What
 * 		this all means is that the entity that performs an IAS query
 * 		is required to call IrlmpDisconnectIas in order to sign-off
 * 		from IAS.  This should preferrably be done *after* receiving
 * 		an IIC_CONNECT_CONFIRMATION, ensuring that at all times there
 * 		exists an IrLMP connection, and avoiding disconnecting and 
 * 		reconnecting the IrLAP layer.
 * 
 * 	Pass:	si	= client handle
 * 	Return: carry clear if okay:
 * 			ax	= IE_SUCCESS
 * 		carry set if error:
 * 			ax	= IrlmpError
 */


IrlmpError
_pascal IrlmpGetValueByClassRequest(ClientHandle client, 
				    IrlmpGetValueByClassRequestArgs *dataArgs);
/*
 *  	Desc:	Get all the values of a named attribute in objects of a
 * 		given class name.
 * 	Pass:	si	= client handle
 * 		cx:dx	= IrlmpGetValueByClassRequestArgs
 * 
 * 	Return: carry clear if okay:
 * 			ax	= IE_SUCCESS
 * 		carry set if error:
 * 			ax	= IrlmpError
 */

/* ----------------------------------------------------------------------
 * 
 *  		TinyTP Indications and Confirmations 
 * 
 * ----------------------------------------------------------------------*/

/* enum TinyTPIndicationOrConfirmation */
typedef enum {		/* CHECKME */

    TTPIC_CONNECT_INDICATION = IIC_LAST_VALUE + 2,

    TTPIC_CONNECT_CONFIRMATION = IIC_LAST_VALUE + 4,
/*
 *  TinyTP connection request was accepted.
 * 
 * 	Pass:		si	= client handle
 * 			bx	= extra word passed to IrlmpRegister
 * 			cx:dx	= IrlmpConnectArgs.  If ICA_dataSize > 0, then
 * 				  callback must free the ICA_data.
 * 				  Note that ICA_QoS.QOS_param.ICP_dataSize
 * 				  provides the maximum data size for the 
 * 				  IrLAP layer.  The client's maximum data
 * 				  size is this value minus TTP_HEADER_SIZE.
 * 	Return:		nothing
 * 	Destroy:	nothing
 */

    TTPIC_DISCONNECT_INDICATION = IIC_LAST_VALUE + 6,
    TTPIC_DATA_INDICATION = IIC_LAST_VALUE + 8,
    TTPIC_STATUS_CONFIRMATION = IIC_LAST_VALUE + 10,
} TinyTPIndicationOrConfirmation;


/* ----------------------------------------------------------------------
 * 
 *  			Ias Database
 * 
 * ----------------------------------------------------------------------*/

typedef ByteFlags IrdbCreateEntryFlags;		/* CHECKME */

#define ICEF_PERMANENT	(0x80)
/* 7 bits unused */


/*  ------------------------------------------------- */
sword
_pascal	IrdbOpenDatabase();
/*  -------------------------------------------------
 *  Open the database so we can read/write information to it.
 *  Multiple clients can read/write to the database,
 *  This routine will block the thread if another is doing
 *  an access. 
 * 
 *  PASS:		nothing
 *  RETURN:	carry set if error
 * 		ax = IrdbErrorType
 * 		else ax = 0
 *  DESTROYED:	nothing
 */


/*  ------------------------------------------------- */
sword
_pascal IrdbCloseDatabase();
/*  -------------------------------------------------
 *  Finished with the database.  Close it up.
 * 
 *  PASS:		nothing
 *  RETURN:	carry set if error
 * 		ax = IrdbErrorType
 * 		else ax = 0
 *  DESTROYED:	nothing
 */

/*  ------------------------------------------------- */
sword
_pascal IrdbCreateEntry(char *classname, word length,
			word clientHandle, word flags);
/*  -------------------------------------------------
 *  Add an entry to the database.  The information needed
 *  to establish an entry is a class name.
 *  You can also pass in an lptr to an endpoint.  This will
 *  enable irlmp to delete your entry.  If you do not want this
 *  feature, then pass zero.
 *  
 *  PASS:	ds:si	= class name
 * 		cx	= string length (0 for null terminated)
 * 		dx	= client handle
 * 		al	= IrdbCreateEntryFlags
 *  RETURN:	carry clear if successful
 * 			ax = Object ID
 * 		carry set if error
 * 			ax = IrdbErrorType
 * 
 *  DESTORYED:	nothing
 */

/*  ------------------------------------------------- */
sword
_pascal IrdbDeleteEntry(word objectID);
/*  -------------------------------------------------
 *  Delete an entry in the database.  Give only
 *  the object id that was returned in the
 *  IrdbCreateEntry function.
 *  
 *  PASS:		bx	= Object ID
 * 
 *  RETURN:	carry clear if successful
 * 		carry set if error
 * 			ax = IrdbErrorType
 * 
 *  DESTORYED:	nothing
 */

/*  ------------------------------------------------- */
sword
_pascal IrdbAddAttribute(word objectID, char *attrName, word attrNameSize,
			word dataType, void *data, word dataLegth);

/*  -------------------------------------------------
 *  Add an attribute for an object.
 *  Note this keeps attributes like an array.  You
 *  are appending an attribute to the end of the list.
 * 
 *  PASS:		bx 	= Object ID
 *  		ds:si	= fptr to attribute name
 * 		bp	= attribute name size (0 for null terminated)
 * 		di	= IrlmpIasValueType
 * 		cx,
 * 		dxax	= Data
 * 			if IIVT_MISSING
 * 				invalid
 * 			if IIVT_INTEGER
 * 				dxax 	= dword integer
 * 			if IIVT_OCTET_SEQUENCE
 * 				cx   	= length of sequence
 * 				dx:ax	= fptr to octet sequence
 * 			if IIVT_USER_STRING
 * 				cl	= length of sequence
 * 				ch	= charset (0 is ascii)
 * 				dx:ax	= fptr to user string
 * 
 *  RETURN:	carry clear if sucessful
 * 			ax = Current number of attributes in the object
 *  		carry set if error
 * 			ax = IrdbErrorType
 */

#if __HIGHC__ 


pragma Alias(IrlmpRegister, "IRLMPREGISTER");
pragma Alias(IrlmpUnregister, "IRLMPUNREGISTER");
pragma Alias(IrlmpDiscoverDevicesRequest, "IRLMPDISCOVERDEVICESREQUEST");
pragma Alias(IrlmpConnectRequest, "IRLMPCONNECTREQUEST");
pragma Alias(IrlmpConnectResponse, "IRLMPCONNECTRESPONSE");
pragma Alias(IrlmpDisconnectRequest, "IRLMPDISCONNECTREQUEST");
pragma Alias(IrlmpStatusRequest, "IRLMPSTATUSREQUEST");
pragma Alias(IrlmpDataRequest, "IRLMPDATAREQUEST");
pragma Alias(IrlmpUDataRequest, "IRLMPUDATAREQUEST");
pragma Alias(IrlmpGetPacketSize, "IRLMPGETPACKETSIZE");
pragma Alias(IrlmpDisconnectIas, "IRLMPDISCONNECTIAS");
pragma Alias(IrlmpGetValueByClassRequest, "IRLMPGETVALUEBYCLASSREQUEST");


pragma	Alias(IrdbOpenDatabase, "IRDBOPENDATABASE");
pragma	Alias(IrdbCloseDatabase, "IRDBCLOSEDATABASE");
pragma	Alias(IrdbCreateEntry, "IRDBCREATEENTRY");
pragma	Alias(IrdbDeleteEntry, "IRDBDELETEENTRY");
pragma	Alias(IrdbAddAttribute, "IRDBADDATTRIBUTE");


pragma	Alias(TTPRegister, "TTPREGISTER");
pragma	Alias(TTPUnregister, "TTPUNREGISTER");
pragma	Alias(TTPConnectRequest, "TTPCONNECTREQUEST");
pragma	Alias(TTPConnectResponse, "TTPCONNECTRESPONSE");
pragma	Alias(TTPDataRequest, "TTPDATAREQUEST");
pragma	Alias(TTPTxQueueGetFreeCount, "TTPTXQUEUEGETFREECOUNT");
pragma	Alias(TTPDisconnectRequest, "TTPDISCONNECTREQUEST");
pragma	Alias(TTPStatusRequest, "TTPSTATUSREQUEST");
pragma	Alias(TTPAdvanceCredit, "TTPADVANCECREDIT");

#endif 

#endif /* _IRLMP_H */


