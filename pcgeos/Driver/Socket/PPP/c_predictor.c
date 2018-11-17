/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  c_predictor.c
 *
 * AUTHOR:  	  Jennifer Wu: Aug 22, 1996
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * 	predictor1_free_table
 *	predictor1_lock_table
 *	predictor1_unlock_table
 *	predictor1_lookup_table	
 *	predictor1_store_table
 *
 *	predictor1_down
 *
 *	predictor1_reset    Code common to resetcomp and resetdecomp.
 *	predictor1_resetcomp
 *	predictor1_resetdecomp
 *
 *	predictor1_init	    Code common to initcomp and initdecomp.
 *	predictor1_initcomp
 *	predictor1_initdecomp
 *
 *	predictor1_comp
 *	predictor1_decomp
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/22/96	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Predictor 1 Compression Protocol for PPP.
 *
 * 	$Id: c_predictor.c,v 1.6 98/01/07 15:27:09 brianc Exp $
 *
 ***********************************************************************/

#ifdef USE_CCP
#ifdef PRED_1

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

# include <ppp.h>
# include <sysstats.h>

#ifdef __HIGHC__
#pragma Code("PRED1CODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg PRED1CODE
#endif


# define MY_MIN(a, b) (((a) < (b)) ? (a) : (b))
# define MY_MAX(a, b) (((a) > (b)) ? (a) : (b))

/* PPP "Predictor" compression */
#define PRED_OVHD 4			/* Predictor 1 overhead per packet */

#define PRED_HASH(h,x) ((unsigned short)(((h)<<4) ^ (x)))

#define PRED_LEN_MASK	0x7fff
#define PRED_COMP_BIT	0x8000

#define PRED_TABLE_SIZE	65536
#define PRED_TABLE_SIZE_K    64		    /* 65536 divided by 1024 */
#define HALF_PRED_TABLE_SIZE 32768  	    /* 65536 divided by 2 */
#define EIGTH_PRED_TABLE_SIZE	8192	    /* 65536 divided by 8 */

struct pred_db
{
    unsigned short	hash;
    unsigned short	mru;
    unsigned char	unit;
    Handle  	    	tbl1;	    	/* first half of dictionary */
    Handle  	    	tbl2;	    	/* 2nd half of dictionary */
    unsigned char *    	tbl1_ptr;
    unsigned char * 	tbl2_ptr;
};


/*
 * Handle of memory blocks holding compression/decompression tables.
 * Block must be locked before use. 
 */
Handle pred_tx_db = 0;     /* predictor 1 compression info */
Handle pred_rx_db = 0;	    /* predictor 1 decompression info */

/*
 * ReservationHandles returned by GeodeRequestSpace.
 */
ReservationHandle   pred_compSpaceToken = 0;	/* compression */
ReservationHandle   pred_decompSpaceToken = 0;	/* decompression */


/***********************************************************************
 *			predictor1_free_table
 ***********************************************************************
 * SYNOPSIS:	Free the database and compression dictionary.
 * CALLED BY:	predictor1_down
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/24/96		Initial Revision
 *
 ***********************************************************************/
void predictor1_free_table (Handle db_block)
{
    struct pred_db *db;

    if (db_block) {
	MemLock(db_block);
	db = (struct pred_db *)MemDeref(db_block);
	MemFree(db -> tbl1);
	MemFree(db -> tbl2);
	MemFree(db_block);
    }
}


/***********************************************************************
 *			predictor1_lock_table
 ***********************************************************************
 * SYNOPSIS:	Lock predictor1 database.
 * CALLED BY:	predictor1_comp
 *	    	predictor1_decomp
 *	    	predictor1_reset
 * RETURN:	pointer to the locked db
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/26/96		Initial Revision
 *
 ***********************************************************************/
struct pred_db *predictor1_lock_table (Handle db_block)
{
    struct pred_db *db;

    MemLock(db_block);
    db = (struct pred_db *)MemDeref(db_block);
    MemLock(db->tbl1);
    MemLock(db->tbl2);
    db -> tbl1_ptr= (unsigned char *)MemDeref(db -> tbl1);
    db -> tbl2_ptr = (unsigned char *)MemDeref(db -> tbl2);
    return (db);
}



/***********************************************************************
 *			predictor1_unlock_table
 ***********************************************************************
 * SYNOPSIS:	Unlock predictor1 database.
 * CALLED BY:	predictor1_comp
 *	    	predictor1_decomp
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/26/96		Initial Revision
 *
 ***********************************************************************/
void predictor1_unlock_table (Handle db_block)
{
    struct pred_db *db = (struct pred_db *)MemDeref(db_block);
    MemUnlock(db -> tbl1);
    MemUnlock(db -> tbl2);
    MemUnlock(db_block);
}



/***********************************************************************
 *			predictor1_lookup_table
 ***********************************************************************
 * SYNOPSIS:	Lookup value in hash table.
 * CALLED BY:	predictor1_comp
 *	    	predictor1_decomp
 * PASS:    	hash value
 * RETURN:  	value in table	
 *
 * STRATEGY:	Get the value from the correct half of the table.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/26/96		Initial Revision
 *
 ***********************************************************************/
unsigned char predictor1_lookup_table (struct pred_db *db,
				       unsigned short hash)
{
    if (hash < HALF_PRED_TABLE_SIZE) 
	return (db -> tbl1_ptr[hash]);
    else
	return (db -> tbl2_ptr[hash - HALF_PRED_TABLE_SIZE]);
}



/***********************************************************************
 *			predictor1_store_table
 ***********************************************************************
 * SYNOPSIS:	Store the value in the hash table
 * CALLED BY:	predictor1_comp
 *	    	predictor1_decomp
 * RETURN:  	nothing	
 *
 * STRATEGY:	Store the value in the correct half of the table.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/26/96		Initial Revision
 *
 ***********************************************************************/
void predictor1_store_table (struct pred_db *db,
			     unsigned short hash,    
			     unsigned char value)
{
    if (hash < HALF_PRED_TABLE_SIZE)
	db -> tbl1_ptr[hash] = value;
    else
	db -> tbl2_ptr[hash - HALF_PRED_TABLE_SIZE] = value;
}





/***********************************************************************
 *			predictor1_down
 ***********************************************************************
 * SYNOPSIS:	Compression is going down.  Free memory used by
 *	    	Predictor1 algorithm.
 * CALLED BY:	ccp_down
 * RETURN:	nothing
 *
 * STRATEGY:	Free the block holding the compression table, if exists.
 *	    	Reset variable.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/22/96		Initial Revision
 *
 ***********************************************************************/
void predictor1_down (int unit)
{
    if (pred_tx_db) {
	predictor1_free_table(pred_tx_db);
	if (pred_compSpaceToken) {
	    GeodeReturnSpace(pred_compSpaceToken);
	}
    }

    if (pred_rx_db) {
	predictor1_free_table(pred_rx_db);
	if (pred_decompSpaceToken) {
	    GeodeReturnSpace(pred_decompSpaceToken);
	}
    }

    pred_tx_db = pred_rx_db = 0;
    pred_compSpaceToken = pred_decompSpaceToken = 0;
}


/***********************************************************************
 *			predictor1_reset
 ***********************************************************************
 * SYNOPSIS:	Reset predictor1 dictionary.
 * CALLED BY:	predictor1_resetcomp
 *	    	predictor1_resetdecomp
 * RETURN:  	nothing	
 *
 * STRATEGY:	zero out hash and dictionary
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/26/96		Initial Revision
 *
 ***********************************************************************/
void predictor1_reset (int unit, Handle db_block)
{
    struct pred_db *db;
    int i;

    db = predictor1_lock_table(db_block);

    db -> hash = 0;

    /*
     * Zero out the table.  Set tbl_ptr to point to dwords so we 
     * loop less.
     */
    for (i = 0; i < EIGTH_PRED_TABLE_SIZE; i++) {
	((unsigned long *)(db -> tbl1_ptr))[i] = 0L;
    	((unsigned long *)(db -> tbl2_ptr))[i] = 0L;
    }

    predictor1_unlock_table(db_block);
}



/***********************************************************************
 *			predictor1_resetcomp
 ***********************************************************************
 * SYNOPSIS:	Reset compression history.
 * CALLED BY:	ccp_resetrequest
 * RETURN:	1 because ack is always needed
 *
 * STRATEGY:	Zero out hash value and compression table entries.
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/22/96		Initial Revision
 *
 ***********************************************************************/
int predictor1_resetcomp (int unit)
{
    predictor1_reset (unit, pred_tx_db);
    return (1);
}


/***********************************************************************
 *			predictor1_resetdecomp
 ***********************************************************************
 * SYNOPSIS:	Reset decompression history.
 * CALLED BY:	ccp_resetack
 * RETURN:	nothing
 
 *
 * STRATEGY:	Zero out hash value & decompression table entries.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/22/96		Initial Revision
 *
 ***********************************************************************/
void predictor1_resetdecomp (int unit)
{
    predictor1_reset(unit, pred_rx_db);
}


/***********************************************************************
 *			predictor1_init
 ***********************************************************************
 * SYNOPSIS:	Allocate memory for the predictor info and compression
 *	    	dictionary.
 * CALLED BY:	predictor1_initcomp
 *	        predictor1_initdecomp
 * PASS:    	place to store pred info block handle
 *	    	mru
 * RETURN:	non-zero if successful
 *	    	zero if insufficient memory
 *
 * STRATEGY:	Dictionary is allocated in 2 separate pieces due to
 *	    	MemAlloc limitations.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/26/96		Initial Revision
 *
 ***********************************************************************/
word predictor1_init (Handle *db_block, 	    
		     int mru)
{
    struct pred_db *db;
    Handle dict1 = 0, dict2 = 0;

    /*
     * Allocate memory if not already done.
     */
    if (*db_block == 0) {
	*db_block = MemAlloc(sizeof (struct pred_db), HF_DYNAMIC, 
			     HAF_ZERO_INIT | HAF_LOCK);

	if (*db_block == 0) 
	    return (0);

	dict1 = MemAlloc(HALF_PRED_TABLE_SIZE, HF_DYNAMIC, HAF_STANDARD);

	if (dict1)
	    dict2 = MemAlloc(HALF_PRED_TABLE_SIZE, HF_DYNAMIC, HAF_STANDARD);
	
	if (dict1 == 0 || dict2 == 0) {
	    if (dict1) 
		MemFree(dict1);	    

	    MemFree(*db_block);
	    *db_block = 0;
	    return (0);
	}
    }

    db = (struct pred_db *)MemDeref(*db_block);
    db -> mru = mru;

    if (db -> tbl1 == 0) {
	db -> tbl1 = dict1;
	db -> tbl2 = dict2;
    }

    MemUnlock(*db_block);
    return (~0);
}




/***********************************************************************
 *			predictor1_initcomp
 ***********************************************************************
 * SYNOPSIS:	Initialize the compressor database.
 * CALLED BY:	ccp_up
 * RETURN:	0 if successful,
 *	    	-1 if unable to allocate database.
 *
 * STRATEGY:	If compression table not allocated, allocate it now.
 *	    	Return error if insufficient memory.
 *	    	Initialize mru.
 *	    	Reset compression table.
 *	    	Decrease interface MTU by predictor overhead bytes
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/22/96		Initial Revision
 *
 ***********************************************************************/
int predictor1_initcomp (int unit, int mru)
{
    pred_compSpaceToken = GeodeRequestSpace(PRED_TABLE_SIZE_K, 
					    SysGetInfo(SGIT_UI_PROCESS));

    if (pred_compSpaceToken && predictor1_init(&pred_tx_db, mru)) {
	/* 
	 * Space reservation and init successful.  Reset
	 * compression history and return success. 
	 */
	predictor1_resetcomp(unit);
	SetInterfaceMTU(mru - PRED_OVHD);
	return (0);
    }
    else {
	/* 
	 * Either space reservation failed or init failed.
	 * If reserved space, return it now. Signal failure.
	 */
	if ( pred_compSpaceToken ) {
	    GeodeReturnSpace(pred_compSpaceToken );
	    pred_compSpaceToken = NullHandle;
	}

	return (-1);
    }
}




/***********************************************************************
 *			predictor1_initdecomp
 ***********************************************************************
 * SYNOPSIS:	Initialize the decompressor database.
 * CALLED BY:	ccp_up
 * RETURN:	0 if successful
 *	    	-1 if unable to allocate the database
 *
 * STRATEGY:	If decompression table not allocated, allocate it now
 *	    	Return error if insufficient memory
 *	    	Initialize mru
 *	    	Reset decompression table
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/22/96		Initial Revision
 *
 ***********************************************************************/
int predictor1_initdecomp (int unit, int mru)
{
    pred_decompSpaceToken = GeodeRequestSpace(PRED_TABLE_SIZE_K,
					      SysGetInfo(SGIT_UI_PROCESS));

    if (pred_decompSpaceToken && predictor1_init(&pred_rx_db, mru)) {
	/*
	 * Space reservation and init successful.  Reset 
	 * decompression history and return success.
	 */
	predictor1_resetdecomp(unit);
    	return (0);
    }
    else {
	/*
	 * Either space reservation failed or init failed.
	 * If reserved space, return it now.  Signal failure.
	 */
	if ( pred_decompSpaceToken ) {
	    GeodeReturnSpace(pred_decompSpaceToken);
	    pred_decompSpaceToken = NullHandle;
	}

	return (-1);
    }
}		



/***********************************************************************
 *			predictor1_comp
 ***********************************************************************
 * SYNOPSIS:	Compress a packet using Predictor Type 1.
 * CALLED BY:	PPPSendPacket
 * RETURN:	0 (always able to send the packet)
 *	    	packetp updated to point to new packet if sending
 *	    	    a compressed packet (data may or may not actually
 *	    	    be compressed)
 *
 * STRATGY: 	Allocate buffer for compressed data.  Send original
 *		    	packet if failed.
 *	    	Store protocol in temporary buffer, compressing if possible
 *	    	init FCS and compute over uncompressed len
 *	    	Compress data
 *	    	If expanded, send uncompressed data
 *	    	else send compressed data
 *	    	free original packet
 *	    	set return params
 *
 *
 * NOTES:	Code is optimized to compress protocol field even
 * 	    	though it's not part of the packet data.   This is
 *	    	done by adjusting the pointer to the data.  Neat
 *	    	trick, but makes code a little harder to understand.
 *
 * PREDICTOR ALGORITHM DESCRIPTION:
 *	From the IETF draft by D. Rand:
 *
 *	Predictor works by filling a guess table with values, based on
 *	the hash of the previous characters seen.  Since we are either
 *	emitting the source data, or depending on the guess table, we 
 *	add a flag bit for every byte of input, telling the decompressor 
 *	if it should retrieve the byte from the compressed data stream
 *	or the guess table.  Blocking the input into groups of 8
 *	characters means that we don't have to bit-insert the compressed
 *	output - a flag byte preceeds every 8 bytes of compressed data.
 * 	Each bit of the flag byte corresponds to one byte of reconstructed
 *	data.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/22/96		Initial Revision
 *
 ***********************************************************************/
int predictor1_comp (int unit, 
		    PACKET **packetp, 
		    int *lenp, 
		    unsigned short *protop)
{

    struct pred_db *db;
    PACKET *m = *packetp;   	    	/* input packet */
    int len = *lenp;	    	    	/* original length of packet */
    unsigned short proto = *protop; 	/* original protocol */
    int index, mlim, slim;
    unsigned short hash, fcs;
    unsigned char flags, *flagsp;
    unsigned char *rptr, *wptr, *wptr0;
    unsigned char c_proto[2], *cp_buf, *cp;
    PACKET *compr_m;
    byte have_buf = 1, proto_len;	   

    /*
     * Allocate a buffer for the compressed data.  If insufficient
     * memory, send the original packet unaltered.
     */
    if ((compr_m = PACKET_ALLOC(MAX_MTU + MAX_FCS_LEN)) == 0) {
	LOG3(LOG_BASE, (LOG_PRED1_COMP_ALLOC));
	return (0);
    }

    cp_buf = PACKET_DATA(compr_m);


    /*
     * Store protocol in temp buffer for compression.  If possible,
     * use a compressed protocol field.  CCP protocol field is allowed
     * to be compressed regardless of whether protocol field compression
     * has been negotiated or not.
     */
    if (proto < 256) {
	c_proto[0] = proto;
	mlim = proto_len = 1;
    }
    else {
	c_proto[0] = proto >> 8;
	c_proto[1] = proto;
	mlim = proto_len = 2;
    }

    /*
     * Set the initial input data pointer to the protocol because
     * we have to compress that first.  Add protocol ID to total
     * uncompressed length.
     */
    rptr = c_proto;	
    len += mlim;    	

    /*
     * Initialize FCS computations.  FCS is calculated over the 
     * uncompressed length, uncompressed protocol ID and each byte 
     * of the uncompressed data.
     */
    fcs = PPP_INITFCS;
    fcs = PPP_FCS(fcs, len >> 8);   	/* high byte of len */
    fcs = PPP_FCS(fcs, len);	    	/* low byte of len */

    wptr = &cp_buf[2];	    /* write pointer for compressed
			       data, leaving room for length field */
				       
    /*
     * Keep track of start of compressed data, not counting protocol ID.
     * Used after compression to compute length of compressed data.
     */
    wptr0 = wptr + mlim; 

    flags = 0;
    flagsp = wptr++;	    /* place for first flag byte */
    index = 8;

    /*
     * Loop through data, starting with protocol field (separate from 
     * rest of data).  Compress the byte if predicted by the hash table.
     * We will exit the loop when we run out of data to compress.
     */

    db = predictor1_lock_table(pred_tx_db);
    hash = db -> hash;	    	    /* Initial hash value */
    
    for (;;) {
	/*
	 * If no more input, and no input buffer remaining to work on, 
	 * then compression is done.  Else, start compressing data
	 * from the input buffer.
	 */
	if ( ! mlim) {

	    /*
	     * If done processing input buffer, write final flags 
	     * byte, store current hash value and quit compressing.
	     */
	    if ( ! have_buf) {
		*flagsp = flags >> index;   
		db -> hash = hash;  	    
		break;	    	    	    
	    }

	    /*
	     * Done compressing protocol ID.  Start compressing input
	     * buffer.
	     */
	    mlim = *lenp;   	    	/* length of input data */
	    rptr = PACKET_DATA(m);  	/* pointer to input data */
	    have_buf = 0;

	    /*
	     * If empty input buffer, let next iteration take care
	     * of writing out the final flags byte and exiting from
	     * this compression loop.
	     */
	    if ( ! mlim)
		continue;	    	
	}

	/*
	 * If processed 8 bytes, write the flag to the output and
	 * reset index (8-byte block counter).
	 */
	if ( ! index) {
	    *flagsp = flags;
	    flagsp = wptr++;
	    index = 8;
	}

	/*
	 * Work with the smaller of 8-bytes or the total length.
	 */
	slim = MY_MIN(mlim, index);
	index -= slim;
	mlim -= slim;	 	

	/*
	 * For each byte, compute FCS, if in hash table, set bit in 
	 * flag for the byte, else write the byte to the output buffer.
	 * Update hash value for next time through.
	 */
	do {
	    unsigned char b = *rptr++;

	    fcs = PPP_FCS(fcs, b);
	    flags >>= 1;

	    if (predictor1_lookup_table(db, hash) == b)
		flags |= 0x80;
	    else {
		predictor1_store_table(db, hash, b);
		*wptr++ = b;
	    }

	    hash = PRED_HASH(hash, b);
	} while (--slim != 0);
    }

    predictor1_unlock_table(pred_tx_db);

    /*
     * Store uncompressed length at start of buffer if compression
     * succeeded.  If compressing made it larger, send the original.
     */
    if (wptr - wptr0 < len) {
	cp = cp_buf;
	PUTSHORT(len | PRED_COMP_BIT, cp);
    }
    else {
	/*
	 * Store uncompressed length, followed by protocol ID (may be 
	 * compressed), then copy the original data to the new buffer.
	 */

	cp = cp_buf;
	PUTSHORT(len, cp);  	

	if (proto_len == 1) {
	    cp_buf[2] = proto;	    	    
	}
	else {
	    cp_buf[2] = proto >> 8;
	    cp_buf[3] = proto;
	}

	(void)memcpy(&cp_buf[proto_len + 2], PACKET_DATA(m), len - proto_len);

	wptr = &cp_buf[len + 2];    	    /* set pointer for FCS */

	LOG3(LOG_BASE, (LOG_PRED1_COMP_BUF_EXPANDED));
    }

    /*
     * Free original input buffer, store FCS and update parameters
     * with the compressed buffer, length and protocol.
     */

    PACKET_FREE(m); 	  

    fcs ^= PPP_INITFCS;
    *wptr++ = fcs;
    *wptr++ = fcs >> 8;

    *packetp = compr_m;	 
    *lenp = compr_m -> MH_dataSize = wptr - cp_buf;  
    *protop = COMPRESS;	

    return (0);
}



/***********************************************************************
 *			predictor1_decomp
 ***********************************************************************
 * SYNOPSIS:	Decompress a Predictor Type 1 packet.
 * CALLED BY:	compress_input
 * RETURN:	-1 if packet could not be decompressed
 *	    	0 if packet does not affect idle time
 *	    	1 if packet affects idle time
 *
 * SIDE EFFECT:  If packet cannot be decompressed, a reset-request
 *	    	will be sent to have the peer reset their compression
 *	    	table.
 *
 * STRATEGY:	Verify length of packet
 *	    	Allocate a buffer for decompressed data.
 *	    	Init FCS and compute FCS of uncompresesd length field
 *	    	If data in packet is not compressed, update dictionary
 *	    	    with the uncompressible data
 *	    	Else decompress the data 
 *	    	Verify CCP FCS.  
 *	    	Free original packet
 *	    	Ensure IP header to at longword boundary in new packet
 *	    	Deliver packet to PPPInput 
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/22/96		Initial Revision
 *
 ***********************************************************************/
int predictor1_decomp (int unit, PACKET *p, int len)
{

    struct pred_db *db;
    unsigned char flags = 0, b;
    int comp, index, dlen;
    unsigned char *rptr, *wptr;
    unsigned short fcs, protocol, hash, explen;
    PACKET *dmsg = (PACKET *)NULL;    	/* packet for decompressed data */
    
    rptr = PACKET_DATA(p);
    GETSHORT(comp, rptr);
    explen = comp & PRED_LEN_MASK;     /* mask out compressed bit from length*/

    db = predictor1_lock_table(pred_rx_db);

    hash = db->hash;

    /*
     * Verify length in packet.
     */
    if (explen > db -> mru || explen == 0) {
	LOG3(LOG_DIAL, (LOG_PRED1_DECOMP_BAD_LEN, comp));
	goto bad;
    }

    /*
     * Allocate a buffer for decompressed data.   Must leave room
     * for VJ uncompression code to prepend 128 (MAX_HDR) bytes of
     * header.  sl_uncompress_tcp code expects this.
     */
    if ((dmsg = PACKET_ALLOC(MAX_HDR + MAX_MTU)) == 0) {
	LOG3(LOG_BASE, (LOG_PRED1_DECOMP_ALLOC));
	goto bad;
    }

    dmsg -> MH_dataSize -= MAX_HDR;
    dmsg -> MH_dataOffset += MAX_HDR;

    wptr = PACKET_DATA(dmsg);	    	/* start of decompressed data */

    fcs = PPP_INITFCS;
    fcs = PPP_FCS(fcs, explen >> 8);
    fcs = PPP_FCS(fcs, explen);
    index = 0;

    /*
     * Go through data in input and decompress packet.
     */
    do {
	/*
	 * There should be 2 bytes remaining for FCS.  Give up
	 * if length is bad.
	 */
	if (len <= 0) {
	    LOG3(LOG_BASE,
		(LOG_PRED1_DECOMP_TOO_SHORT, comp));
	    goto bad;
	}

	/*
	 * If data is not compressed, update dictionary with the 
	 * uncompressible data.
	 */

	if ( ! (comp & PRED_COMP_BIT)) {

	    do {
		b = *rptr++;
		fcs = PPP_FCS(fcs, b);
		*wptr++ = b;
		predictor1_store_table(db, hash, b);
		hash = PRED_HASH(hash, b);

		if (--explen == 0)
		    goto fin;

	    } while (--len != 0);

	    continue;	   	/* let next iteration catch zero length */
	}   

	/*
	 * Decompress the data in 8 byte blocks.  Get flag byte.  For
	 * each bit, if bit is set, get byte from hash table and put 
	 * in decompressed buffer, else copy byte from input buffer 
	 * to decompressed buffer.
	 */
	if (index == 0) {
	    /* be quick about most of the packet */
	    while (len >= 9 && explen >= 8) {
		flags = *rptr++;
		--len;

		for (index = 8; index != 0; index--) {
		    if (flags & 1)
			b = predictor1_lookup_table(db, hash);
		    else {
			--len;
			b = *rptr++;
			predictor1_store_table(db, hash, b);
		    }

		    fcs = PPP_FCS(fcs, b);
		    hash = PRED_HASH(hash, b);
		    *wptr++ = b;
		    flags >>= 1;
		}

		if ((explen -= 8) == 0)
		    goto fin;
	    }
	}

	/* 
	 * Handle last dribble at the end of an input buffer
	 * or the partial block at the start of an input buffer.
	 */
	if (index != 0 || len < 9 || explen < 8) {
	    dlen = MY_MAX(index, 8);

	    while (dlen != 0) {
		/*
		 * If start of another 8 bytes, get the flag byte.
		 */
		if (index == 0) {
		    if ( ! len)
			break;

		    --len;
		    flags = *rptr++;
		    index = 8;
		}

		/*
		 * If bit is set, get byte from hash table, else copy
		 * from input buffer.
		 */
		if (flags & 1)
		    b = predictor1_lookup_table(db, hash);
		else {
		    if ( ! len)
			break;

		    --len;
		    b = *rptr++;
		    predictor1_store_table(db, hash, b);
		}

		--index;
		flags >>= 1;
		hash = PRED_HASH(hash, b);
		fcs = PPP_FCS(fcs, b);
		*wptr++ = b;

		if (--explen == 0)
		    goto fin;

		--dlen;
	    }
	}
    } while (explen != 0);

fin:
    db -> hash = hash;

    /*
     * Verify CCP FCS.  Give up if CCP FCS is missing.
     */
    if (len < 2) {
	LOG3(LOG_BASE,
	    (LOG_PRED1_DECOMP_FCS,
	     len, comp));
	goto bad;
    }

    fcs = PPP_FCS(fcs, *rptr);
    rptr++;
    fcs = PPP_FCS(fcs, *rptr);

    if (fcs != PPP_GOODFCS) {
	LOG3(LOG_BASE, (LOG_PRED1_DECOMP_BAD_FCS, comp));
	goto bad;
    }

    PACKET_FREE(p);
    predictor1_unlock_table(pred_rx_db);

    /* 
     * Handle uncompressed PPP protocol field.  Get 1st byte from
     * decompressed data. If protocol ID is 2 bytes, get 2nd byte.
     * Advance data offset in buffer to after protocol ID.
     */
    rptr = PACKET_DATA(dmsg);	    	

    protocol = *rptr++;	    	    	

    if ((protocol & 1) == 0)	    	
	protocol = (protocol << 8) | *rptr++;

    dmsg -> MH_dataOffset += (word)(rptr - PACKET_DATA(dmsg));

    /*
     *	Ensure that the IP header is at a longword boundary by
     *  shifting packet contents forward, if necessary.
     */
    if ((dword)rptr & 3) {
	int offset = (dword)rptr & 3;

	memmove(rptr - offset, rptr, (word)(wptr - rptr));
	dmsg -> MH_dataOffset -= offset;
    }

    dmsg -> MH_dataSize = (word)(wptr - rptr);
    return ((int)PPPInput(protocol, dmsg, dmsg -> MH_dataSize));

bad:
    predictor1_unlock_table(pred_rx_db);
    PACKET_FREE(p);
    if (dmsg)
	PACKET_FREE(dmsg);
    return (-1);
}

#endif /* PRED1 */
#endif /* USE_CCP */
