/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  socketDr.h
 * FILE:	  socketDr.h
 *
 * AUTHOR:  	  Jennifer Wu: Jul 25, 1994
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/25/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	C definitions for SocketDr.def.
 *
 *
 * 	$Id: socketDr.h,v 1.1 97/04/04 15:53:49 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _SOCKETDR_H_
#define _SOCKETDR_H_

#include "sockmisc.h"

/*---------------------------------------------------------------------------*
 * 
 * MbufHeader is identical to the PacketHeader structure defined in 
 * Internal/socketInt.def.
 *
 *---------------------------------------------------------------------------*/

#define IF_BCAST    0x01
#define	IF_MCAST    0x02

typedef struct {
    word    	MH_dataSize;    	    	
    word    	MH_dataOffset;   	/* offset in bytes */
    byte    	MH_flags;
    word    	MH_domain;
    byte    	MH_reserved;
} MbufHeader;	    	    /* different name from ASM to satisfy glue */


typedef struct {
    MbufHeader 	DH_common;
    byte    	DH_addrSize;
    byte    	DH_addrOffset;	    	/* offset in bytes */
    word    	DH_lport;   	    	/* local port */
    word    	DH_rport;   	    	/* remote port */
} DatagramHeader;

/* 
 * Get the ptr to the data in a data buffer.  Works for datagram buffers
 * also if cast to MbufHeader.
 */
#if ERROR_CHECK
#define mtod(x)   (ECCheckBounds(x), \
		   ECCheckBounds((byte *)(x) + ((x)->MH_dataOffset)), \
		   ((byte *)(x) + ((x)->MH_dataOffset)))
#else
#define mtod(x)   ((byte *)(x) + ((x)->MH_dataOffset))
#endif

/*
 * Get the ptr to the address in a datagram buffer.  
 * Analogous to mtod definition above.
 */
#if ERROR_CHECK
#define mtoa(x)	(ECCheckBounds(x), \
		 ECCheckBounds((byte *)(x) + ((x)->DH_addrOffset)), \
		 ((byte *)(x) + ((x)->DH_addrOffset)))
#else
#define mtoa(x)     ((byte *)(x) + ((x)->DH_addrOffset))
#endif


/*------------------------------------------------------------------------ *
 *
 *	SocketCloseType
 *
 *------------------------------------------------------------------------ */

typedef word SocketCloseType;	    	
#define SCT_FULL	0x0
#define SCT_HALF	0x1

/*------------------------------------------------------------------------ *
 *
 *	SocketSendMode	    
 *
 *------------------------------------------------------------------------ */
typedef word SocketSendMode;
#define SSM_NORMAL  	0x0
#define SSM_URGENT  	0x1

/*------------------------------------------------------------------------
 *
 *	SocketOptionType
 *
 *------------------------------------------------------------------------ */
typedef word SocketOptionType;
#define SOT_RECV_BUF	0x0
#define SOT_SEND_BUF	0x1
#define SOT_INLINE  	0x2
#define SOT_NODELAY 	0x3

/*------------------------------------------------------------------------
 *
 *	MediumOptionType
 *
 *------------------------------------------------------------------------ */
typedef word MediumOptionType;
#define MOT_ALWAYS_BUSY 0x0

/*------------------------------------------------------------------------ *
 *
 *	SocketDrError
 *
 *------------------------------------------------------------------------ */

typedef enum /*word*/ {
    SDE_NO_ERROR,   	    	   /* must be first */
    SDE_CONNECTION_REFUSED,        /* remote refuse to connect */
    SDE_CONNECTION_TIMEOUT, 	    /* remote does not respond  */
    SDE_MEDIUM_BUSY,                 /* active connection outside */
    SDE_INSUFFICIENT_MEMORY,        
    SDE_NOT_REGISTERED,               /* client has not reg with drvr */
    SDE_ALREADY_REGISTERED,           /* same client registering twice */
    SDE_CONNECTION_EXISTS,  	      /* opening duplicate connection */
    SDE_LINK_OPEN_FAILED,   	      /* couldn't open any links */
    SDE_DRIVER_NOT_FOUND,
    SDE_DESTINATION_UNREACHABLE,    	
    SDE_CONNECTION_RESET_BY_PEER,   
    SDE_CONNECTION_RESET,
    SDE_UNSUPPORTED_FUNCTION,
    SDE_INVALID_CONNECTION_HANDLE,
    SDE_INVALID_ADDR_FOR_LINK,
    SDE_INVALID_ADDR,
    SDE_TEMPORARY_ERROR,
    SDE_INTERRUPTED 	    	      
} SocketDrError;


#endif /* _SOCKETDR_H_ */



