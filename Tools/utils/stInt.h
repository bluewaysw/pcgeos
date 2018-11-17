/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stInt.h
 *
 * AUTHOR:  	  Adam de Boor: Aug  3, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 3/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Internal definitions for the ST module. A string table spans
 *	multiple VM blocks, being made of two types of blocks:
 *
 *	    - The header block, containing an array of VMBlockHandles
 *	      that point to the individual chain blocks (in which the
 *	      records describing the element of a chain reside).
 *
 *	    - A set of chain blocks, containing an STChainHdr and
 *	      STChainRecs that are part of the same chain. Each chain
 *	      record is followed immediately by the string for the record,
 *	      allowing us to avoid an extra four bytes of overhead per
 *	      string. The string itself is padded and null-terminated
 *	      to ensure each chain record is word-aligned.
 *
 * 	$Id: stInt.h,v 1.7 92/06/03 16:35:11 adam Exp $
 *
 ***********************************************************************/
#ifndef _STINT_H_
#define _STINT_H_

#include    <os90.h>
#include    <st.h>

#include    <assert.h>

/*
 * Structure used to point to objects in a VM file. A variation on the
 * segment:offset model favored by 8086's...
 */
typedef struct {
    word    	    offset;
    VMBlockHandle   vmBlock;
} STVMPtr;

/*
 * Chain element.
 */
typedef struct {
    word    	hashval;    /* Full hash value for the string */
    word    	length;	    /* Length of the string */
    char    	string[LABEL_IN_STRUCT];  /* Start of string */
} STChainRec, *STChainPtr;

/*
 * Macro to advance to the next chain record from the given one. The string
 * in a chain record is one longer than len (has a null byte, you know) and
 * the whole thing is rounded so the next record is word-aligned. Hence the
 * +2 & ~1 business.
 *
 * We pass the length to the macro independently so we can figure the proper
 * size for a block w/o having filled in the record.
 *
 * (TODO: Use length == -1 to => hashval is VMBlockHandle of place to
 * find next thing...requires extra care with lock/unlock, but...)
 */
#define ST_NEXT_CP(stcp,len) ((STChainPtr)((stcp)->string+(((len)+2)&~1)))

/*
 * Structure placed at start of a chain block. This is here, rather than
 * in the STHeader to avoid (a) extra overhead for empty chains and (b)
 * because the offset is needed only when allocating a new chain, at which
 * point the chain block will be locked down anyway...
 */
typedef struct {
    word    	offset;	    /* Offset of next free STChainRec in the block */
} STChainHdr;

#define ST_LAST_CP(chdr) ((STChainPtr)((char *)(chdr) + (chdr)->offset))

/*
 * Number of buckets in the header block for the table.
 */
#define ST_NUM_BUCKETS	    257     /* Number of buckets in the header block
				     * for the table */
#define ST_HASH_TO_BUCKET(val) ((val) % ST_NUM_BUCKETS)

#define ST_INIT_CHAIN_BYTES 1024    /* Initial size of a chain block */
#define ST_INCR_CHAIN_BYTES 512	    /* Number of bytes by which to increase
				     * a chain block */

typedef struct {
    VMBlockHandle   chains[ST_NUM_BUCKETS];
} STHeader;


extern int  STHash(const char *name, int length, word *hashval);
extern ID   STSearch(VMHandle 	vmHandle,
		     STHeader	*hdr,
		     int    	bucket,
		     word   	hashval,
		     const char	*name,
		     int    	len);
extern ID   STAlloc(VMHandle        vmHandle,
		    VMBlockHandle   table,
		    STHeader   	    *hdr,
		    int	    	    bucket,
		    word	    hashval,
		    const char	    *name,
		    int 	    len);


#define STVM_LOCK(v,p,m) (VMLock((v), (p)->vmBlock, (m)) + (p)->offset)
#define STVM_UNLOCK(v,p)    VMUnlock((v), (p)->vmBlock)

#endif /* _STINT_H_ */
