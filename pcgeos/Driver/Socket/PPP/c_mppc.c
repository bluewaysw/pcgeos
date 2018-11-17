/***********************************************************************
 *
 *	Copyright (c) Geoworks 1997 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  c_mppc.c
 *
 * AUTHOR:  	  Jennifer Wu: Sep 23, 1997
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	mppc_down
 *
 *	mppc_resetcomp
 *	mppc_resetdecomp
 *
 *	mppc_initcomp
 *	mppc_initdecomp
 *
 *	mppc_comp
 *	mppc_decomp
 *
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/23/97	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Microsoft Point-to-Point Compression (MPPC) Protocol.
 *	This is based on Stac LZS.  
 *
 * 	A license from Stac Electronics is required before this 
 *	code may be used.
 *
 * 	$Id: c_mppc.c,v 1.2 98/06/15 13:56:43 jwu Exp $
 *
 ***********************************************************************/

#ifdef USE_CCP
#ifdef MPPC

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

# include <ppp.h>
/* # include <mppc.h> */	    /* file does not exist yet! */
# include <sysstats.h>

#ifdef __HIGHC__
#pragma Code("MPPCCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg MPPCCODE
#endif

/*
 * MPPC overhead per PPP packet: 
 *	2 bytes for coherency count & flags 
 */
#define MPPC_OVHD   2	    
#define MPPC_DATA_OFFSET    MPPC_OVHD

struct mppc_db
{
    unsigned short mru;
    unsigned short flags;	/* bits A, B, C for compression */
    unsigned short count;	/* coherency count */
    Handle history;		/* handle of compression history */
};

/*
 * Handle of memory blocks holding compression/decompression tables.
 * Blocks must be locked before use.
 */
Handle mppc_tx_db = 0;	    /* mppc compression table */
Handle mppc_rx_db = 0;	    /* mppc decompression table */

/*
 * ReservationHandles returned by GeodeRequestSpace.
 */
ReservationHandle   mppc_compSpaceToken = 0;	/* compression */
ReservationHandle   mppc_decompSpaceToken = 0;	/* decompression */


/***********************************************************************
 *			mppc_down
 ***********************************************************************
 * SYNOPSIS:	Compression is going down.  Free memory used by MPPC
 *		algorithm.
 * CALLED BY:	ccp_down
 * RETURN:	nothing
 *
 * STRATEGY:	Free the blocks holding the compression tables, if 
 *		they exist.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	9/23/97		Initial Revision
 *
 ***********************************************************************/
void mppc_down (int unit)
{
    struct mppc_db *db;

    LOG3(LOG_BASE, (LOG_MPPC_DOWN));

    if (mppc_tx_db) {
	MemLock(mppc_tx_db);
	db = (struct mppc_db *)MemDeref(mppc_tx_db);
	MemFree(db -> history);
	MemFree(mppc_tx_db);

	if (mppc_compSpaceToken) {
	    GeodeReturnSpace(mppc_compSpaceToken);
	}
    }

    if (mppc_rx_db) {
	MemLock(mppc_rx_db);
	db = (struct mppc_db *)MemDeref(mppc_rx_db);
	MemFree(db -> history);
	MemFree(mppc_rx_db);

	if (mppc_decompSpaceToken) {
	    GeodeReturnSpace(mppc_decompSpaceToken);
	}

    }

    mppc_tx_db = mppc_rx_db = 0;
    mppc_compSpaceToken = mppc_decompSpaceToken = 0;

}	/* mppc_down */


/***********************************************************************
 *			mppc_resetcomp
 ***********************************************************************
 * SYNOPSIS:	Reset compression history.
 * CALLED BY:	ccp_resetrequest
 * RETURN:	0  -  no ack is needed for MPPC
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	9/23/97		Initial Revision
 *
 ***********************************************************************/
int mppc_resetcomp (int unit)
{
    struct mppc_db *db;
    
    LOG3(LOG_BASE, (LOG_MPPC_RESETCOMP));

    MemLock(mppc_tx_db);
    db = (struct mppc_db *)MemDeref(mppc_tx_db);

    MemLock(db -> history);

    MPPC_InitCompressionHistory(MemDeref(db -> history));

    db -> flags = MPPC_PACKET_FLUSHED;

    MemUnlock(db -> history);
    MemUnlock(mppc_tx_db);
    
    return (0);			/* no acks needed for MPPC */
}	/* mppc_resetcomp */



/***********************************************************************
 *			mppc_resetdecomp
 ***********************************************************************
 * SYNOPSIS:	Reset decompression history
 * CALLED BY:	ccp_resetack
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	9/23/97		Initial Revision
 *
 ***********************************************************************/
void mppc_resetdecomp (int unit) 
{
    struct mppc_db *db;
    
    LOG3(LOG_BASE, (LOG_MPPC_RESETDECOMP));

    MemLock(mppc_rx_db);
    db = (struct mppc_db *)MemDeref(mppc_rx_db);

    MemLock(db -> history);

    MPPC_InitDecompressionHistory(MemDeref(db -> history));

    MemUnlock(db -> history);
    MemUnlock(mppc_rx_db);
    
}	/* mppc_resetdecomp */


/***********************************************************************
 *			mppc_initcomp
 ***********************************************************************
 * SYNOPSIS:	Initialize the compressor.
 * CALLED BY:	ccp_up
 * RETURN:	0 if successful
 *		-1 if unable to allocate memory for compression history
 *
 * STRATEGY:	If db not allocated, do so now, returning error if 
 *		insufficient memory.
 *		Reset compression history.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	9/23/97		Initial Revision
 *
 ***********************************************************************/
int mppc_initcomp (int unit, 
		   int mru) 
{
    unsigned short histSize;
    Handle hBlock = 0;
    struct mppc_db *db;

    /* 
     * If MPPC compression history hasn't been allocated yet, 
     * do so now.  Return error if insufficient memory.  
     */
    if (mppc_tx_db == 0) {
	mppc_tx_db = MemAlloc(sizeof (struct mppc_db), HF_DYNAMIC,
			      HAF_ZERO_INIT | HAF_LOCK);
	if (mppc_tx_db == 0) {
	    LOG3(LOG_BASE, (LOG_MPPC_NO_MEM, "mppc"));
	    return (-1);
	}
	
	histSize = MPPC_SizeOfCompressionHistory();
	mppc_compSpaceToken = GeodeRequestSpace((histSize + 1023)/1024,
						SysGetInfo(SGIT_UI_PROCESS));
	if (mppc_compSpaceToken)
	    hBlock = MemAlloc(histSize, HF_DYNAMIC, HAF_STANDARD);

	if (hBlock == 0) {
	    MemFree (mppc_tx_db);
	    if (mppc_compSpaceToken) {
		GeodeReturnSpace(mppc_compSpaceToken);
		mppc_compSpaceToken = NullHandle;
	    }
	    mppc_tx_db = 0;
	    LOG3(LOG_BASE, (LOG_MPPC_NO_MEM, "compression"));
	    return (-1);
	}
    }

    db = (struct mppc_db *)MemDeref(mppc_tx_db);
    if (! db -> history)
	db -> history = hBlock;

    db -> mru = mru;

    MemUnlock(mppc_tx_db);

    mppc_resetcomp(0);

    SetInterfaceMTU(mru - MPPC_OVHD);

    return (0);
    
}	/* mppc_initcomp */


/***********************************************************************
 *			mppc_initdecomp
 ***********************************************************************
 * SYNOPSIS:	Initialize decompressor.
 * CALLED BY:	ccp_up
 * RETURN:	0 if successful
 *		-1 if unable to allocate memory for decompression history
 *
 * STRATEGY:	If decompression history is not allocated, do so now.
 *		    Find out how much memory to allow.
 *		    Alloc the block and save handle.
 *		    Return error if insufficient memory.
 *		Store mru.
 *		Reset decompression history.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	9/23/97		Initial Revision
 *
 ***********************************************************************/
int mppc_initdecomp (int unit, 
		     int mru) 
{
    unsigned short histSize;
    Handle hBlock = 0;
    struct mppc_db *db;

    /*
     * If MPPC decompression history hasn't been allocated yet, do
     * so now.  Return error if insufficient memory.
     */
    if (mppc_rx_db == 0) {
	
	mppc_rx_db = MemAlloc(sizeof (struct mppc_db), HF_DYNAMIC,
			      HAF_ZERO_INIT | HAF_LOCK);
	if (mppc_rx_db == 0) {
	    LOG3(LOG_BASE, (LOG_MPPC_NO_MEM, "mppc"));
	    return (-1);
	}

	histSize = MPPC_SizeOfDecompressionHistory();
	mppc_decompSpaceToken = GeodeRequestSpace((histSize + 1023)/1024,
						  SysGetInfo(SGIT_UI_PROCESS));

	if (mppc_decompSpaceToken)
	    hBlock = MemAlloc(histSize, HF_DYNAMIC, HAF_STANDARD);

	if (hBlock == 0) {
	    MemFree(mppc_rx_db);
	    if (mppc_decompSpaceToken) {
		GeodeReturnSpace(mppc_decompSpaceToken);
		mppc_decompSpaceToken = NullHandle;
	    }
	    mppc_rx_db = 0;
	    LOG3(LOG_BASE, (LOG_MPPC_NO_MEM, "decompression"));
	    return (-1);
	}
    }

    db = (struct mppc_db *)MemDeref(mppc_rx_db);
    if (! db -> history)
	db -> history = hBlock;

    db -> mru = mru;
    
    MemUnlock(mppc_rx_db);

    mppc_resetdecomp(0);

    return(0);

}	/* mppc_initdecomp */


/***********************************************************************
 *			mppc_comp
 ***********************************************************************
 * SYNOPSIS:	Compress a packet using MPPC.
 * CALLED BY:	PPPSendPacket
 * RETURN:	0 (always able to send packet)
 *
 * STRATEGY:	Allocate buffer for compressed data.  If failed,
 *		    send original without modifications.
 *		Compress protocol field if possible.
 *		Compress protocol field into new buffer.
 *		Compress data into new buffer
 *		If data expanded
 *		    reset history
 *		    set bit A
 *		    store uncompressed proto & original data in new buffer
 *		else 
 *		    set compressed bit in flag
 *		    store coherency count, incrementing count and
 *		    adjusting flags as needed
 *		    adjust packet header dataOffset and dataSize fields
 *		    free original packet and set return values
 *		return success
 * 
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	9/23/97		Initial Revision
 *
 ***********************************************************************/
int mppc_comp (int unit,
	       PACKET **packetp,
	       int *lenp,
	       unsigned short *protop)
{
    struct mppc_db *db;
    void *history;

    int len = *lenp;			/* original length of packet */
    unsigned short proto = *protop;	/* original protocol */

    PACKET *compr_m;			/* packet for compressed data */
    unsigned char *srcPtr, *destPtr, *cp_buf;
    unsigned char c_proto[2];		/* temp buffer for protocol */
    unsigned short proto_len;

    unsigned short result, flags = 0;
    unsigned long srcLen, destLen;

    /*
     * Allocate a buffer for the compressed data.  If insufficient
     * memory, send the original packet unaltered.
     */
    if ((compr_m = PACKET_ALLOC(MAX_MTU + MAX_FCS_LEN)) == 0) {
	LOG3(LOG_BASE, (LOG_MPPC_ALLOC_FAILED, "comp"));
	return (0);
    }

    /*
     * Save room for coherency count at start of compressed packet.
     */
    cp_buf = PACKET_DATA(compr_m);
    destPtr = &cp_buf[MPPC_DATA_OFFSET];
    destLen = MAX_MTU - MPPC_OVHD;

    MemLock(mppc_tx_db);
    db = (struct mppc_db *)MemDeref(mppc_tx_db);
    MemLock(db -> history);
    history = MemDeref(db -> history);

    srcPtr = PACKET_DATA(*packetp);

    /*
     * Store protocol in temp buffer for compression.  If possible,
     * compress it.  Only compress if protocol field compression
     * negotiated.
     */
    if (proto < 256) {
	c_proto[0] = proto;
	proto_len = 1;
    }
    else {
	c_proto[0] = proto >> 8;
	c_proto[1] = proto;
	proto_len = 2;
    }

    /*
     * Compress the protocol field, then the regular data.
     */
    srcPtr = c_proto;
    srcLen = (unsigned long)proto_len;
    result = MPPC_Compress(&srcPtr, &destPtr, &srcLen, &destLen, history, 
			   (MPPC_SAVE_HISTORY | MPPC_MANDATORY_COMPRESS_FLAGS),
			   MPPC_PERFORMANCE_MODE_0);
    
    EC_ERROR_IF (result & MPPC_INVALID, -1);
    EC_ERROR_IF ((result & MPPC_SOURCE_EXHAUSTED) == 0, -1);
    
    srcPtr = PACKET_DATA(*packetp);
    srcLen = len;
    result = MPPC_Compress(&srcPtr, &destPtr, &srcLen, &destLen, history,
			   (MPPC_SAVE_HISTORY | MPPC_MANDATORY_COMPRESS_FLAGS),
			   MPPC_PERFORMANCE_MODE_0);

    EC_ERROR_IF (result & MPPC_INVALID, -1);

    if (result & MPPC_EXPANDED) {
	/*
	 * Data expanded. Original data is sent as an uncompressed MPPC
	 * packet.  Store protocol field and copy original data to the	
	 * new buffer.  History has already been flushed by MPPC library.   
	 */
	srcPtr = PACKET_DATA(*packetp);
	cp_buf[2] = proto >> 8;
	cp_buf[3] = proto;
	memcpy(&cp_buf[4], srcPtr, len);
	destLen = len + 2;		/* original length + protocol field */
	LOG3(LOG_BASE, (LOG_MPPC_EXPANDED));
	
	/*
	 * Next packet must set the flushed bit.
	 */
	db -> flags |= MPPC_PACKET_FLUSHED;	
    } 
    else if (result & (MPPC_SOURCE_EXHAUSTED | MPPC_FLUSHED)) {
	/*
	 * Packet was compressed.  Compute compressed length and
	 * set bits.  
	 */
	destLen = (unsigned long)(MAX_MTU - MPPC_OVHD) - destLen;

	flags = db -> flags | MPPC_PACKET_COMPRESSED;	/* bit C and maybe A */

	if (result & MPPC_RESTART_HISTORY) {
	    LOG3(LOG_BASE, (LOG_MPPC_RESTART_HISTORY));

	    /* 
	     * MPPC library flushed history before restarting it
	     * to work around a NT Server bug.  We don't need 
	     * to set flushed bit because packet is always
	     * decompressible as long as history ptrs are reset
	     * after history is flushed.
	     */
	    flags |= MPPC_PACKET_AT_FRONT;		/*  bit B */
	}

	/* 
	 * Clear flushed bit for next time. 
	 */
	db -> flags = 0;	    

    }
    /*
     * Store coherency count and flags in packet.
     * Adjust packet's dataSize and dataOffset.
     */
    result = flags | db -> count;
    cp_buf[0] = result >> 8;
    cp_buf[1] = (unsigned char)result;

    /*
     * Increment count, handling wraparound.
     */
    if (++db -> count & COHERENCY_FLAGS_MASK)
	db -> count = 0;

    compr_m -> MH_dataSize = destLen + MPPC_OVHD;
     
    /*
     * Free original packet and set return values.
     */
    PACKET_FREE(*packetp);

    *packetp = compr_m;
    *lenp = compr_m -> MH_dataSize;
    *protop = COMPRESS;

    MemUnlock(db -> history);
    MemUnlock(mppc_tx_db);

    return (0);

}	/* mppc_comp */


/***********************************************************************
 *			mppc_decomp
 ***********************************************************************
 * SYNOPSIS:	Decompress a MPPC packet.
 * CALLED BY:	compress_input
 * RETURN:	-1 if packet could not be decompressed
 *		0 if packet does not affect idle time
 *		1 if packet affects idle time
 *
 * SIDE EFFECTS: If packet cannot be decompressed, a reset-request
 *		will be sent to have the peer reset their compression
 *		table.
 *
 * STRATEGY:	Do sequence number check on coherency count.
 *		If data not compressed, extract protocol and adjust 
 *		    header, then deliver.
 *		Alloc buffer for decompressed data
 *		Decompress packet
 *		Discard compressed packet
 *		Check for decompression error
 *		Get protocol of decompressed data
 *		Adjust new buffer's dataSzie and dataOffset
 *		deliver packet to PPPInput
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	9/23/97		Initial Revision
 *
 ***********************************************************************/
int mppc_decomp (int unit,
		 PACKET *p,
		 int len)
{
    struct mppc_db *db;
    void *history;

    unsigned short ccount, protocol;	/* ccount is coherency count */

    PACKET *dmsg = (PACKET *)NULL;	/* packet for decompressed data */
    unsigned char *srcPtr, *destPtr;
    unsigned long srcLen, destLen;
    unsigned short result;		

    /*
     * Set up pointers, etc.
     */
    MemLock(mppc_rx_db);
    db = (struct mppc_db *)MemDeref(mppc_rx_db);
    MemLock(db -> history);
    history = MemDeref(db -> history);

    srcPtr = PACKET_DATA(p);

    /*
     * Get the coherency count.  
     */
    GETSHORT(ccount, srcPtr);
    len -= 2;

    /*
     * If flushed bit set, resynchronize coherency count to the
     * received value in the packet, stop resetting & flush history.  
     * If not set, count must match or packet is bad.
     */
    if (ccount & MPPC_PACKET_FLUSHED) {
	db -> count = (ccount & COHERENCY_COUNT_MASK) + 1;
	ccp_resetack(&ccp_fsm[0], (unsigned char *)NULL, 0, 0);
	LOG3(LOG_BASE, (LOG_MPPC_DECOMP_FLUSHED));
    }
    else if ((ccount & COHERENCY_COUNT_MASK) == db -> count)
	db -> count++;
    else {
	LOG3(LOG_BASE, (LOG_MPPC_DECOMP_BAD_COUNT));
	goto bad;
    }

    /*
     * Handle coherency count wrapping around.
     */
    if (db -> count & COHERENCY_FLAGS_MASK)	
	db -> count = 0;

    /* 
     * If packet data is not compressed, extract protocol,
     * adjust packet header to exclude check field and protocol,
     * then deliver.
     */
    if (! (ccount & MPPC_PACKET_COMPRESSED)) {
	LOG3(LOG_BASE, (LOG_MPPC_UNCOMPRESSED));
	GETSHORT(protocol, srcPtr);
	p -> MH_dataSize -= 4;	    /* coherency count & proto is 4 bytes  */
	p -> MH_dataOffset += 4;
	MemUnlock(db -> history);
	MemUnlock(mppc_rx_db);
	return ((int)PPPInput(protocol, p, p -> MH_dataSize));
    }

#ifdef LOGGING_ENABLED
    if (ccount & MPPC_PACKET_AT_FRONT) 
	LOG3(LOG_BASE, (LOG_MPPC_DECOMP_HISTORY_RESTARTED));
#endif /* LOGGING_ENABLED */

    /*
     * Allocate a new buffer for decompresssed data.  Must leave room
     * for VJ uncompression code to prepend 128 (MAX_HDR) bytes of 
     * header.  sl_uncompress_tcp code expects this.
     */
    if ((dmsg = PACKET_ALLOC(MAX_HDR + MAX_MTU)) == 0) {
	LOG3(LOG_BASE, (LOG_MPPC_ALLOC_FAILED, "decomp"));
	goto bad;
    }

    dmsg -> MH_dataSize -= MAX_HDR;
    dmsg -> MH_dataOffset += MAX_HDR;

    /*
     * Decompress into the new buffer.  If decompression fails,
     * discard packet.  A reset-requeset will be generated.
     * Handle packet being at front of history.
     */
    destPtr = PACKET_DATA(dmsg);
    destLen = MAX_MTU;
    srcLen = (unsigned long)len;
    result = MPPC_Decompress(&srcPtr, &destPtr, &srcLen, &destLen, history,
		    (ccount & MPPC_PACKET_AT_FRONT) ?
	            (MPPC_RESTART_HISTORY | MPPC_MANDATORY_DECOMPRESS_FLAGS) : 
		     MPPC_MANDATORY_DECOMPRESS_FLAGS);
    
    PACKET_FREE(p);	    /* free compressed packet */

    if ((result & (MPPC_SOURCE_EXHAUSTED | MPPC_FLUSHED)) == 0)	{	
	LOG3(LOG_BASE, (LOG_MPPC_DECOMP_FAILED));
	goto bad2;
    }

    /*
     * Compute size of decompressed data.  destLen contains remaining 
     * space in destination buffer.
     */
    len = (int)((unsigned long)MAX_MTU - destLen);

    /*
     * Get protocol from decompressed data and deliver.  Protocol field
     * may be compressed.
     */
    destPtr = PACKET_DATA(dmsg);
    protocol = *destPtr++;
    len--;
    dmsg -> MH_dataOffset++;

    if ((protocol & 1) == 0) {
	protocol = (protocol << 8) | *destPtr;
	len--;
	dmsg -> MH_dataOffset++;
    }

    dmsg -> MH_dataSize = len;
    MemUnlock(db -> history);
    MemUnlock(mppc_rx_db);
    return ((int)PPPInput(protocol, dmsg, len));

bad:
    PACKET_FREE(p);
bad2:
    if (dmsg)
	PACKET_FREE(dmsg);
    MemUnlock(db -> history);
    MemUnlock(mppc_rx_db);
    return (-1);

}	/* mppc_decomp */

#endif /* MPPC */
#endif /* USE_CCP */
