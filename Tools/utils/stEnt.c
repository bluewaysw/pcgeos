/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stEnter.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  4, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 4/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Look for and enter, if not found, a string in a string table
 *
 ***********************************************************************/
#include <config.h>
#include <compat/string.h>
#include "stInt.h"


/***********************************************************************
 *				STAlloc
 ***********************************************************************
 * SYNOPSIS:	    Allocate a new chain entry for a string, placing
 *	    	    the string in an appropriate data block.
 * CALLED BY:	    ST_Enter
 * RETURN:	    The ID for the string.
 * SIDE EFFECTS:    The header is marked dirty.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 7/89		Initial Revision
 *
 ***********************************************************************/
ID
STAlloc(VMHandle    	vmHandle,   /* Handle of file containing table */
	VMBlockHandle	table,	    /* Handle of header block */
	STHeader    	*hdr,	    /* Locked header block */
	int 	    	bucket,	    /* Bucket to which string is to be added */
	word	    	hashval,    /* Actual hash value for string */
	const char    	*name,	    /* String to add */
	int 	    	len)	    /* Length of same */
{
    MemHandle   mem;    	/* Memory handle (for MemReAlloc) */
    STChainPtr	stcp;   	/* New chain element */
    word	size;   	/* Size of block */
    ID	    	result;	    	/* Value to return */
    STChainHdr  *chdr;	    	/* Header for chain block for bucket */
    dword   	sizeNeeded; 	/* Block size required once this string is
				 * stored in the chain block */
    
    result = NullID;

    /*
     * If no block allocated for the chain, do so now, initializing the
     * chain header's offset to point to immediately after the header --
     * the first possible chain record in the block.
     */
    if (hdr->chains[bucket] == (VMBlockHandle)0) {
	hdr->chains[bucket] = VMAlloc(vmHandle,ST_INIT_CHAIN_BYTES,ST_CHAIN_ID);
	/*
	 * Mark the table header dirty.
	 */
	VMDirty(vmHandle, table);
	
	/*
	 * Lock down and initialize the block.
	 */
	chdr = (STChainHdr *)VMLock(vmHandle, hdr->chains[bucket], &mem);
	chdr->offset = sizeof(STChainHdr);
    } else {
	chdr = (STChainHdr *)VMLock(vmHandle, hdr->chains[bucket], &mem);
    }

    stcp = ST_LAST_CP(chdr);
    
    /*
     * Figure out how big the block is.
     */
    MemInfo(mem, (genptr *)0, &size);

    sizeNeeded = ((char *)ST_NEXT_CP(stcp,len) - (char *)chdr);

    assert(sizeNeeded < 65536);

    if ((word)sizeNeeded > size) {
	/*
	 * Hit the end of the block -- make the block bigger
	 */
	do {
	    size += ST_INCR_CHAIN_BYTES;
	} while (size < (word)sizeNeeded);
	
	if (!MemReAlloc(mem, size, 0)) {
	    goto error;
	}
	/*
	 * Fetch new base of memory block w/o locking it.
	 */
	MemInfo(mem, (genptr *)&chdr, (word *)0);
    }

    /*
     * Point stcp at the chain record to use, advancing the offset in the
     * chain block header.
     */
    stcp = ST_LAST_CP(chdr);
    chdr->offset = sizeNeeded;

    /*
     * Record the integral parameters for the entry now.
     */
    stcp->length = len;
    stcp->hashval = hashval;

    /*
     * stcp->string is the base of a block of memory large enough to hold
     * the string w/ a null byte at the end, while still ensuring that the
     * next STChainRec is word-aligned.
     *
     * Copy the string in and null-terminate it.
     */
    memcpy(stcp->string, name, len);
    stcp->string[len] = '\0';
    
    /*
     * Form the ID to be returned from the chain handle and the actual
     * offset of the string.
     */
    result = (ID)((hdr->chains[bucket] << 16) | (stcp->string - (char *)chdr));

    /*
     * Release the block in which the chain resides, after marking
     * it dirty.
     */
    VMDirty(vmHandle, hdr->chains[bucket]);

error:

    VMUnlock(vmHandle, hdr->chains[bucket]);

    return(result);
}

/***********************************************************************
 *				ST_Enter
 ***********************************************************************
 * SYNOPSIS:	    Enter a string into a string table.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The ID for the string -- a unique, long integer
 *	    	    that identifies the string.
 * SIDE EFFECTS:    
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 4/89		Initial Revision
 *
 ***********************************************************************/
ID
ST_Enter(VMHandle   	vmHandle,   	/* File in which table resides */
	 VMBlockHandle	table,	    	/* Header block for table */
	 char	    	*name,	    	/* String to enter */
	 int	    	len)	    	/* Length of same */
{
    int	    	    bucket; 	/* Bucket in which to search */
    word    	    hashval;	/* Full hash value for the string */
    STHeader 	    *hdr;   	/* Address of header block */
    ID	    	    result; 	/* ID to return as result */

    /*
     * Figure in which bucket the thing should reside.
     */
    bucket = STHash(name, len, &hashval);

    /*
     * Lock down the header. We don't need the handle of the header, as we're
     * not going to be doing any resizing.
     */
    hdr = (STHeader *)VMLock(vmHandle, table, (MemHandle *)0);

    /*
     * First take a stab at finding the thing.
     */
    result = STSearch(vmHandle, hdr, bucket, hashval, name, len);

    if (result == NullID) {
	/*
	 * Not there -- need to make a new entry.
	 */
	result = STAlloc(vmHandle, table, hdr, bucket, hashval, name, len);
    }
	
    /*
     * Unlock the header block now the search is complete.
     */
    VMUnlock(vmHandle, table);

    return(result);
}
	 
    
