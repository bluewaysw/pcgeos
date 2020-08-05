/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  c_stac.c
 *
 * AUTHOR:  	  Jennifer Wu: Aug 28, 1996
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	stac_lcb
 *
 *	stac_down
 *
 *	stac_resetcomp
 *	stac_resetdecomp
 *
 *	stac_initcomp
 *	stac_initdecomp
 *
 *	stac_comp
 *	stac_decomp
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/28/96	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Stac LZS Compression Protocol for PPP.
 *
 * 	A license from Stac Electronics is required before this
 *	code may be used.
 *
 * 	$Id: c_stac.c,v 1.6 97/11/20 18:49:17 jwu Exp $
 *
 ***********************************************************************/

#ifdef USE_CCP
#ifdef STAC_LZS

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

# include <ppp.h>
# include <lzs.h>
# include <sysstats.h>

#ifdef __HIGHC__
#pragma Code("STACCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg STACCODE
#endif
#ifdef __WATCOMC__
#pragma code_seg("STACCODE")
#endif

/*
 * Stac LZS overhead per PPP packet:
 * 	2 bytes max for check field
 *	0 bytes for history (only supporting single history)
 *	1 byte for lzs end marker
 *	1 byte to make it even.
 */
#define STAC_OVHD   	    4

#define STAC_DATA_OFFSET    2	    	/* max space check field needs */

#define	INIT_LCB    0xFF	    	/* Initial LCB value */

struct stac_db
{
    unsigned short mru;
    unsigned char checkMode;	    	    /* check mode */
    union {
	unsigned char seq;	    	    /* sequence number */
	struct {
	    unsigned short flags;
	    unsigned short count;  	    /* coherency count */
	} extended;
    } check;
    Handle  history;
};


/*
 * Handle of memory blocks holding compression/decompression tables.
 * Blocks must be locked before use.
 */
Handle stac_tx_db = 0;	 /* stac lzs compression table */
Handle stac_rx_db = 0; 	 /* stac lzs decompression table */

/*
 * ReservationHandles returned by GeodeRequestSpace.
 */
ReservationHandle   stac_compSpaceToken = 0;	/* compression */
ReservationHandle   stac_decompSpaceToken = 0;	/* decompression */


/***********************************************************************
 *		stac_lcb
 ***********************************************************************
 * SYNOPSIS:	Calculate a new LCB given the current LCB and the new
 *	    	data.
 * CALLED BY:	stac_comp
 *	    	stac_decomp
 * RETURN:	new LCB
 *
 * STRATEGY:	LCB is the exclusive-OR of FF (hex) and each byte
 *	    	of the data.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/29/96   	Initial Revision
 *
 ***********************************************************************/
unsigned char stac_lcb (unsigned char lcb,
			unsigned char *cp,
			int len)
{
    while (len--)
	lcb ^= *cp++;

    return (lcb);

}	/* End of ppplcb.	*/



/***********************************************************************
 *			stac_down
 ***********************************************************************
 * SYNOPSIS:	Compression is going down.  Free memory used by
 *	    	Stac LZS algorithm.
 * CALLED BY:	ccp_down
 * RETURN:	nothing
 *
 * STRATEGY:	Free the blocks holding the comperssion tables, if
 *	    	they exists.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/28/96		Initial Revision
 *
 ***********************************************************************/
void stac_down (int unit)
{
    struct stac_db *db;

    if (stac_tx_db) {
	MemLock(stac_tx_db);
    	db = (struct stac_db *)MemDeref(stac_tx_db);
	MemFree(db -> history);
	MemFree(stac_tx_db);

	if (stac_compSpaceToken) {
	    GeodeReturnSpace(stac_compSpaceToken);
	}
    }
    if (stac_rx_db) {
	MemLock(stac_rx_db);
	db = (struct stac_db *)MemDeref(stac_rx_db);
	MemFree(db -> history);
	MemFree(stac_rx_db);

	if (stac_decompSpaceToken) {
	    GeodeReturnSpace(stac_decompSpaceToken);
	}
    }

    stac_tx_db = stac_rx_db = 0;
    stac_compSpaceToken = stac_decompSpaceToken = 0;
}


/***********************************************************************
 *			stac_resetcomp
 ***********************************************************************
 * SYNOPSIS:	Reset compression history.
 * CALLED BY:	ccp_resetrequest
 * RETURN:	0 if no ack is needed
 *	    	1 if ack is needed
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/28/96		Initial Revision
 *
 ***********************************************************************/
int stac_resetcomp (int unit)
{
    struct stac_db *db;
    void *history;
    int ack = 1;    	    /* default is to reply with reset-ack */
    unsigned long nada = 0L, dnada = LZS_DEST_MIN;
    unsigned short result;

    MemLock(stac_tx_db);
    db = (struct stac_db *)MemDeref(stac_tx_db);

    MemLock(db -> history);
    history = MemDeref(db -> history);

    result = LZS_Compress((unsigned char **)NULL, (unsigned char **)NULL,
			  &nada, &dnada, history,
			  LZS_SOURCE_FLUSH | LZS_DEST_FLUSH, 0);
    EC_ERROR_IF((result & LZS_FLUSHED) == 0, -1);

    /*
     * If extended mode, set the flushed bit instead of sending
     * a reset-ack.
     */
    if (db -> checkMode == STAC_CHECK_EXTENDED) {
	db -> check.extended.flags = STAC_PACKET_FLUSHED;
	ack = 0;
    }

    MemUnlock(db -> history);
    MemUnlock(stac_tx_db);
    return (ack);
}


/***********************************************************************
 *			stac_resetdecomp
 ***********************************************************************
 * SYNOPSIS:	Reset decompression history.
 * CALLED BY:	ccp_resetack
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/28/96		Initial Revision
 *
 ***********************************************************************/
void stac_resetdecomp (int unit)
{
    struct stac_db *db;
    void *history;

    MemLock(stac_rx_db);

    db = (struct stac_db *)MemDeref(stac_rx_db);

    MemLock(db -> history);
    history = MemDeref(db -> history);
    LZS_InitDecompressionHistory(history);
    MemUnlock(db -> history);

    MemUnlock(stac_rx_db);

}


/***********************************************************************
 *			stac_initcomp
 ***********************************************************************
 * SYNOPSIS:	Initialize the compressor.
 * CALLED BY:	ccp_up
 * RETURN:	0 if successful
 *	    	-1 if unable to allocate memory for compression history
 *
 * STRATEGY:	If db not allocated, do so now, returning error
 *	    	    if insufficient memory.
 *	    	store mru and check mode
 *	    	If check mode is seq, init sequence number.
 *	    	If check mode is extended, init count & set bit A
 *	    	Reset compression history.
 *	    	Decrease interface MTU by stac overhead bytes.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/28/96		Initial Revision
 *
 ***********************************************************************/
int stac_initcomp (int unit, int mru, unsigned char check)
     /*int unit;*/   	    	/* old-style function declaration needed here */
     /*int mru;*/
     /*unsigned char check;*/	    	/* check mode to use */
{
    unsigned short histSize;
    Handle hBlock = 0;
    struct stac_db *db;

    /*
     * If stac compression table hasn't been allocated yet, do
     * so now.  Return error if insufficient memory.  Initialize
     * history only when allocated.
     */
    if (stac_tx_db == 0) {

	stac_tx_db = MemAlloc(sizeof (struct stac_db), HF_DYNAMIC,
			      HAF_ZERO_INIT | HAF_LOCK);
	if (stac_tx_db == 0) {
	    LOG3(LOG_BASE, (LOG_STAC_NO_MEM, "stac"));
	    return (-1);
	}

	histSize = LZS_SizeOfCompressionHistory();
	stac_compSpaceToken = GeodeRequestSpace((histSize + 1023)/1024,
						SysGetInfo(SGIT_UI_PROCESS));
	if (stac_compSpaceToken)
	    hBlock = MemAlloc(histSize, HF_DYNAMIC, HAF_LOCK);

	if (hBlock == 0) {
	    MemFree(stac_tx_db);
	    if (stac_compSpaceToken) {
		GeodeReturnSpace(stac_compSpaceToken);
		stac_compSpaceToken = NullHandle;
	    }
	    stac_tx_db = 0;
	    LOG3(LOG_BASE, (LOG_STAC_NO_MEM, "compression"));
	    return (-1);
	}

	/*
	 * Must initialize before use!
	 */
	LZS_InitCompressionHistory(MemDeref(hBlock));

    }

    db = (struct stac_db *)MemDeref(stac_tx_db);
    if ( ! db -> history)
	db -> history = hBlock;

    db -> mru = mru;
    db -> checkMode = check;

    /*
     * If doing sequence numbers, initialize seq to 1.  If extended,
     * init count to 1 and disable protocol field compression for
     * outgoing packets.
     */
    if (check == STAC_CHECK_SEQ) {
	db -> check.seq = 1;
    }
    else if (check == STAC_CHECK_EXTENDED) {
	db -> check.extended.count = 1;
	ppp_mode_flags &= ~SC_TX_COMPPROT;
    }

    MemUnlock(stac_tx_db);

    stac_resetcomp(0);

    SetInterfaceMTU(mru - STAC_OVHD);
    return (0);

}


/***********************************************************************
 *			stac_initdecomp
 ***********************************************************************
 * SYNOPSIS:	Initialize decompressor.
 * CALLED BY:	ccp_up
 * RETURN:	0 if successful
 *	    	-1 if unable to allocate memory for decompression history
 *
 * STRATEGY:	If compression history is not allocated, allocate it now.
 *		    	Find out how much memory to alloc.
 *	    	    	Alloc the block and save handle
 *	    	    	Return error if insufficient memory.
 *	    	store mru and check mode
 *	    	if check mode is seq, init sequence number to 1
 *	    	if check mode is extended, init count
 *	    	Reset decompression history.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/28/96		Initial Revision
 *
 ***********************************************************************/
int stac_initdecomp (int unit, int mru, unsigned char check)
     /*int unit;*/   	    	/* old-style declaration needed here */
     /*int mru;*/
       /*unsigned char check;*/    	/* check mode to use */
{
    unsigned short histSize;
    Handle hBlock = 0;
    struct stac_db *db;

    /*
     * If stac decompression table hasn't been allocated yet, do so
     * now.  Return error if insufficient memory.
     */
    if (stac_rx_db == 0) {

	stac_rx_db = MemAlloc(sizeof (struct stac_db), HF_DYNAMIC,
			      HAF_ZERO_INIT | HAF_LOCK);
	if (stac_rx_db == 0) {
	    LOG3(LOG_BASE, (LOG_STAC_NO_MEM, "stac"));
	    return(-1);
	}

	histSize = LZS_SizeOfDecompressionHistory();
	stac_decompSpaceToken = GeodeRequestSpace((histSize + 1023)/1024,
						  SysGetInfo(SGIT_UI_PROCESS));

	if (stac_decompSpaceToken)
	    hBlock = MemAlloc(histSize, HF_DYNAMIC, HAF_STANDARD);

	if (hBlock == 0) {
	    MemFree(stac_rx_db);
	    if (stac_decompSpaceToken) {
		GeodeReturnSpace(stac_decompSpaceToken);
		stac_decompSpaceToken = NullHandle;
	    }
	    stac_rx_db = 0;
	    LOG3(LOG_BASE, (LOG_STAC_NO_MEM, "decompression"));
	    return (-1);
	}
    }

    db = (struct stac_db *)MemDeref(stac_rx_db);
    if ( ! db -> history)
	db -> history = hBlock;

    db -> mru = mru;
    db -> checkMode = check;

    if (check == STAC_CHECK_SEQ)
	db -> check.seq = 1;
    else if (check == STAC_CHECK_EXTENDED)
	db -> check.extended.count = 1;

    MemUnlock(stac_rx_db);

    stac_resetdecomp(0);

    return (0);

}



/***********************************************************************
 *			stac_comp
 ***********************************************************************
 * SYNOPSIS:	Compress a packet using Stac LZS.
 * CALLED BY:	PPPSendPacket
 * RETURN:	0 (always able to send packet)
 *
 * STRATEGY:	Allocate buffer for compressed data.  If failed,
 *	    	    send original without modifications.
 *	    	Compress protocol field if possible.
 *	    	compute lcb or fcs
 *	    	compress protocol field into new buffer
 *	    	compress data into new buffer
 *	    	if data expanded (and not extended mode)
 *	    	    free new buffer and send original
 *	    	else
 *	    	    if expanded in extended mode, reset history, set bit A
 *	    	    	store uncompressed proto & original data in new buffer
 *	    	    else if extended mode, set compressed bit in flag
 *	    	    store check field or coherency count, incrementing
 *	    	    	seq and count and adjusting flags as needed
 *	    	    adjust packet header dataOffset and dataSize fields
 *	    	    free original packet and set return values
 *	    	return success
 *
 * NOTES:
 *	Data is not considered to have expanded if compression only
 *	added 1 byte to the size.  We can spare 1 byte for the lzs
 *	end marker, and future compression ratios will benefit from
 *	not resetting history as often.
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/28/96		Initial Revision
 *
 ***********************************************************************/
int stac_comp (int unit,
	       PACKET **packetp,
	       int *lenp,
	       unsigned short *protop)
{

    struct stac_db *db;
    void *history;

    int len = *lenp;	    	    	/* original length of packet */
    unsigned short proto = *protop; 	/* original protocol */

    unsigned char lcb;
    unsigned short fcs;

    PACKET *compr_m;	    	    	/* packet for compressed data */
    unsigned char *srcPtr, *destPtr, *cp_buf;
    unsigned char c_proto[2];	    	/* temp buffer for protocol */
    unsigned short proto_len;

    unsigned short result;
    unsigned long srcLen, destLen;

    /*
     * Allocate a buffer for the compressed data.  If insufficient
     * memory, send the original packet unaltered.
     */
    if ((compr_m = PACKET_ALLOC(MAX_MTU + MAX_FCS_LEN)) == 0) {
	LOG3(LOG_BASE, (LOG_STAC_ALLOC_FAILED, "comp"));
	return (0);
    }

    /*
     * Save room for check field or coherency count at start of
     * compressed packet.
     */
    cp_buf = PACKET_DATA(compr_m);
    destPtr = &cp_buf[STAC_DATA_OFFSET];
    destLen = MAX_MTU - STAC_OVHD;

    MemLock(stac_tx_db);
    db = (struct stac_db *)MemDeref(stac_tx_db);
    MemLock(db -> history);
    history = MemDeref(db -> history);

    srcPtr = PACKET_DATA(*packetp);

    /*
     * Store protocol in temp buffer for compression.  If possible,
     * compress it.  May be compressed whether protocol field
     * compression has been negotiated or not, unless doing extended
     * mode.
     */
    if (proto < 256 && db -> checkMode != STAC_CHECK_EXTENDED) {
	c_proto[0] = proto;
	proto_len = 1;
    }
    else {
	c_proto[0] = proto >> 8;
	c_proto[1] = proto;
	proto_len = 2;
    }

    /*
     * Compute FCS or LCB over the protocol ID field and all the
     * uncompressed data at once.
     */
    if (db -> checkMode == STAC_CHECK_LCB) {
	lcb = stac_lcb(INIT_LCB, c_proto, proto_len);
	lcb = stac_lcb(lcb, srcPtr, len);
    }
    else if (db -> checkMode == STAC_CHECK_CRC) {
	fcs = pppfcs(PPP_INITFCS, c_proto, proto_len);
	fcs = pppfcs(fcs, srcPtr, len);
    }

    /*
     * Compress the protocol field, then the regular data.
     *
     */
    srcPtr = c_proto;
    srcLen = (unsigned long)proto_len;
    result = LZS_Compress(&srcPtr, &destPtr, &srcLen, &destLen, history,
			  (LZS_SAVE_HISTORY | perf_mode),
			  perf);

    EC_ERROR_IF(result & LZS_INVALID, -1);
    EC_ERROR_IF((result & LZS_SOURCE_EXHAUSTED) == 0, -1);

    srcPtr = PACKET_DATA(*packetp);
    srcLen = len;
    result = LZS_Compress(&srcPtr, &destPtr, &srcLen, &destLen, history,
			  (LZS_SOURCE_FLUSH | LZS_SAVE_HISTORY | perf_mode),
			  perf);

    EC_ERROR_IF(result & LZS_INVALID, -1);
    EC_ERROR_IF((result & (LZS_SOURCE_EXHAUSTED | LZS_DEST_EXHAUSTED)) == 0, -1);

    if (result & LZS_SOURCE_EXHAUSTED) {
	/*
	 * Compute size of the compressed data by seeing how much
	 * space was used by LZS_Decompress.
	 */
	destLen = (unsigned long)(MAX_MTU - STAC_OVHD) - destLen;
    }
    else {
	/*
	 * Finish processing source data to keep history intact.
	 * We'll be sending the uncompressed data so overwrite what
	 * we've already compressed.
	 */
	while (! (result &  LZS_SOURCE_EXHAUSTED)) {
	    destPtr = &cp_buf[STAC_DATA_OFFSET];
	    destLen = MAX_MTU - STAC_OVHD;
	    result = LZS_Compress(&srcPtr, &destPtr, &srcLen, &destLen,
			     history,
			     LZS_SOURCE_FLUSH | LZS_SAVE_HISTORY | perf_mode,
			     perf);
	}
	destLen = MAX_MTU;  	    /* guaranteed bigger than original len */
    }

    len += proto_len;	    	    /* include protocol in original length */

    EC_ERROR_IF(! (result & LZS_FLUSHED), -1);
    EC_ERROR_IF(srcLen, -1);

    /*
     * Send original packet if compressed data expanded and not
     * doing extended check mode.  Data needs to have expanded to
     * exceed MRU so only need to check for expansion.
     * Reset the compression history.
     */
    if ((db -> checkMode != STAC_CHECK_EXTENDED) &&
	(destLen > len + 1)) {	    	/* allow for lzs end marker */

	/*
	 * Use LZS_Compress with 0 srcCnt and LZS_SOURCE_FLUSH without
	 * saving history to reset.  Faster than LZS_InitCompressionHistory.
	 */
	destLen = LZS_DEST_MIN;	    	/* to make LZS_Compress happy */
	(void)LZS_Compress(&srcPtr, &destPtr, &srcLen, &destLen, history,
			   LZS_SOURCE_FLUSH, 0);
	EC_ERROR_IF(! (result & LZS_FLUSHED), -1);

	PACKET_FREE(compr_m);
	LOG3(LOG_BASE, (LOG_STAC_SEND_NATIVE));
    }
    else {
	if (destLen > len + 1) {    	   /* allow for lzs end marker */
	    /*
	     * Expansion occurred in extended mode.  Clear history buffer
	     * and set flushed bit.
	     */
	    destLen = LZS_DEST_MIN; 	/* to make LZS_Compress happy */
	    (void)LZS_Compress(&srcPtr, &destPtr, &srcLen, &destLen, history,
			       LZS_SOURCE_FLUSH, 0);
	    EC_ERROR_IF(! (result & LZS_FLUSHED), -1);

	    db -> check.extended.flags = STAC_PACKET_FLUSHED;

	    /*
	     * Store protocol field and copy original data to the new
	     * buffer.
	     */
	    srcPtr = PACKET_DATA(*packetp);
	    cp_buf[2] = proto >> 8;
	    cp_buf[3] = proto;
	    memcpy(&cp_buf[4], srcPtr, len);
	    destLen = len;
	    LOG3(LOG_BASE, (LOG_STAC_EXPANDED));
	}
	else if (db -> checkMode == STAC_CHECK_EXTENDED) {
	    db -> check.extended.flags |= STAC_COMPRESSED;
	}

	/*
	 * Store check field or coherency count in packet.
	 * Adjust packet's dataSize and dataOffset.
	 */
	EC_ERROR_IF((STAC_CHECK_SEQ & 1) == 0, -1);
	EC_ERROR_IF((STAC_CHECK_LCB & 1) == 0, -1);

	if (db -> checkMode & 1) {
	    /* quick check relying on lcb & seq check modes being odd */
	    if (db -> checkMode == STAC_CHECK_SEQ)
		cp_buf[1] = db -> check.seq++;
	    else
		cp_buf[1] = lcb;

	    /* adjust data offset and data size to include check field */
	    compr_m -> MH_dataOffset += 1;
	    compr_m -> MH_dataSize = destLen + 1;
	}
	else {
	    if (db -> checkMode == STAC_CHECK_CRC) {
		cp_buf[0] = fcs;    	    /* least significant byte first */
	    	cp_buf[1] = fcs >> 8;
	    }
	    else {
		result = db -> check.extended.flags |
		    	 db -> check.extended.count;
		cp_buf[0] = result >> 8;
		cp_buf[1] = (unsigned char)result;

		/*
		 * If sending compressed, then safe to clear reset bit.
		 * Else, leave the flag alone.
		 */
		if (db -> check.extended.flags & STAC_COMPRESSED)
		    db -> check.extended.flags = 0;

		if (++db -> check.extended.count & COHERENCY_FLAGS_MASK)
		    db -> check.extended.count = 0;
	    }

	    /* adjust data size, include size of check field */
	    compr_m -> MH_dataSize = destLen + 2;
	}

	/*
	 * Free original packet and set return values.
	 */
	PACKET_FREE(*packetp);

	*packetp = compr_m;
	*lenp = compr_m -> MH_dataSize;
	*protop = COMPRESS;
    }

    MemUnlock(db -> history);
    MemUnlock(stac_tx_db);

    return (0);
}


/***********************************************************************
 *			stac_decomp
 ***********************************************************************
 * SYNOPSIS:	Decompress a Stac LZS packet.
 * CALLED BY:	compress_input
 * RETURN:	-1 if packet could not be decompressed
 *	    	0 if packet does not affect idle time
 *	    	1 if packet affects idle time
 *
 * SIDE EFFECTS: If packet cannot be decompressed, a reset-request
 *	    	will be sent to have the peer reset their compression
 *	    	table.
 *
 * STRATEGY:	get check
 *	    	Do sequence number checks or extended mode checks
 *	    	If not extended mode, inzert a zero byte at end of data
 *	    	alloc buffer for decompressed data
 *	    	decompress packet
 *	    	discard compressed packet
 *	    	check for decompression error
 *	    	get protocol of decompressed data
 *	    	adjust new buffer's dataSize and dataOffset
 *	    	deliver packet to PPPInput
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/28/96		Initial Revision
 *
 ***********************************************************************/
int stac_decomp (int unit, PACKET *p, int len)
{
    struct stac_db *db;
    void *history;

    unsigned char checkChar, lcb;
    unsigned short checkShort, protocol;

    PACKET *dmsg = (PACKET *)NULL;    	    /* packet for decompressed data */
    unsigned char *srcPtr, *destPtr;
    unsigned long srcLen, destLen;
    unsigned short result;

    /*
     * Set up pointers, etc.
     */
    MemLock(stac_rx_db);
    db = (struct stac_db *)MemDeref(stac_rx_db);
    MemLock(db -> history);
    history = MemDeref(db -> history);

    srcPtr = PACKET_DATA(p);

    EC_ERROR_IF((STAC_CHECK_SEQ & 1) == 0, -1);
    EC_ERROR_IF((STAC_CHECK_LCB & 1) == 0, -1);

    /*
     * Get the check field.  LCB and SEQ only use a byte, CRC and
     * EXTENDED is word sized.
     */
    if (db -> checkMode & 1) {
	/* quick check relying on lcb & seq check modes being odd */
	GETCHAR(checkChar, srcPtr);
	len--;

	if (db -> checkMode == STAC_CHECK_SEQ) {
	    /*
	     * Update sequence number to next expected sequence.
	     */
	    lcb = db -> check.seq;
	    db -> check.seq = checkChar + 1;

	    /*
	     * Verify seqeunce number.
	     */
	    if (lcb != checkChar)
		goto bad;
	}
    }
    else if (db -> checkMode == STAC_CHECK_EXTENDED) {

	GETSHORT (checkShort, srcPtr);
	len -= 2;

	/*
	 * If flushed bit set, resynchronize coherency count to the
	 * received value in the packet, reset decompressor and stop
	 * resetting.  If not set, count must match or packet is bad.
	 */
	if (checkShort & STAC_PACKET_FLUSHED) {
	    db -> check.extended.count = (checkShort & COHERENCY_COUNT_MASK)+1;
	    ccp_resetack(&ccp_fsm[0], (unsigned char *)NULL, 0, 0);
	}
	else if ((checkShort & COHERENCY_COUNT_MASK) ==
		 db -> check.extended.count)
	    db -> check.extended.count++;
	else
	    goto bad;

	/*
	 * Handle coherency count wrapping around.
	 */
	if (db -> check.extended.count & COHERENCY_FLAGS_MASK)
	    db -> check.extended.count = 0;

	/*
	 * If packet data is not compressed, extract protocol,
	 * adjust packet header to exclude check field and protocol,
	 * then deliver.
	 */
	if (! (checkShort & STAC_COMPRESSED)) {
	    LOG3(LOG_IP, (LOG_STAC_UNCOMPRESSED));
	    GETSHORT(protocol, srcPtr);
	    p -> MH_dataSize -= 4;
	    p -> MH_dataOffset += 4;
	    MemUnlock(db -> history);
	    MemUnlock(stac_rx_db);
	    return ((int)PPPInput(protocol, p, p -> MH_dataSize));
	}
    }
    else {
	/*
	 * CRC is transmitted least significant byte first so we
	 * can't use GETSHORT.
	 */
	checkShort = *(word *)srcPtr;
	srcPtr += 2;
	len -= 2;
    }

    /*
     * If not doing extended mode, insert a zero byte at the end
     * of the data.
     */
    if (db -> checkMode != STAC_CHECK_EXTENDED)
	srcPtr[len] = 0;

    /*
     * Allocate a new buffer for decompressed data.  Must leave room
     * for VJ uncompression code to prepend 128 (MAX_HDR) bytes of
     * header.  sl_uncompress_tcp code expects this.
     */
    if ((dmsg = PACKET_ALLOC(MAX_HDR + MAX_MTU)) == 0) {
	LOG3(LOG_BASE, (LOG_STAC_ALLOC_FAILED, "decomp"));
	goto bad;
    }

    dmsg -> MH_dataSize -= MAX_HDR;
    dmsg -> MH_dataOffset += MAX_HDR;

    /*
     * Decompress into the new buffer. If decompression fails,
     * discard packet.  A reset-request will be generated.
     */
    destPtr = PACKET_DATA(dmsg);
    destLen = MAX_MTU;
    srcLen = (unsigned long)len;
    result = LZS_Decompress(&srcPtr, &destPtr, &srcLen, &destLen, history,
			    LZS_SAVE_HISTORY);

    PACKET_FREE(p); 	    	    	    /* free compressed packet */

    if ( ! (result & LZS_END_MARKER)) {	    /* did compression work? */
        LOG3(LOG_BASE, (LOG_STAC_DECOMP_FAILED));
	goto bad2;
    }

    /*
     * Compute size of decompressed data.  destLen contains remaining
     * space in destination buffer.
     */
    len = (int)((unsigned long)MAX_MTU - destLen);

    /*
     * Compute LCB or FCS over uncompressed data and verify.
     */
    destPtr = PACKET_DATA(dmsg);
    if (db -> checkMode == STAC_CHECK_LCB) {
	lcb = stac_lcb(INIT_LCB, destPtr, len);
	if (lcb != checkChar) {
	    LOG3(LOG_BASE, (LOG_STAC_DECOMP_BAD, "lcb"));
	    goto bad2;
	}
    }
    else if (db -> checkMode == STAC_CHECK_CRC) {
	result = pppfcs(PPP_INITFCS, destPtr, len);
	if (result != checkShort) {
	    LOG3(LOG_BASE, (LOG_STAC_DECOMP_BAD, "crc"));
	    goto bad2;
	}
    }

    /*
     * Get protcol from decompressed data and deliver.  Protocol field
     * may be compressed.
     */
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
    MemUnlock(stac_rx_db);
    return ((int)PPPInput(protocol, dmsg, len));

bad:
    PACKET_FREE(p);
bad2:
    if (dmsg)
	PACKET_FREE(dmsg);
    MemUnlock(db -> history);
    MemUnlock(stac_rx_db);
    return (-1);

}


#endif /* STAC_LZS */
#endif /* USE_CCP */
