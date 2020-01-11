/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stDup.c
 *
 * AUTHOR:  	  Adam de Boor: Sep 26, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/26/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Duplicate a string-table entry from one table to another
 *
 ***********************************************************************/
#include <config.h>
#include "stInt.h"

#include <stddef.h>


/***********************************************************************
 *				ST_Dup
 ***********************************************************************
 * SYNOPSIS:	    Duplicate a string from one table to another.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The ID of the string in the new table
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/26/89		Initial Revision
 *
 ***********************************************************************/
ID
ST_Dup(VMHandle	    	vmSrcHandle,
       ID   	    	srcID,
       VMHandle	    	vmDstHandle,
       VMBlockHandle	dstTable)
{
    STChainPtr	    stcp;
    STHeader	    *hdr;
    ID	    	    result;
    int	    	    bucket;

    /*
     * Convenience: Null IDs map to Null IDs (avoids conditionals in the
     * linker).
     */
    if (srcID == NullID) {
	return(NullID);
    }
    
    /*
     * Find the record in the source table
     */
    stcp = (STChainPtr)((char *)VMLock(vmSrcHandle,
				       srcID >> 16,
				       (MemHandle *)NULL) +
			((srcID & 0xffff) - offsetof(STChainRec, string)));

    /*
     * Lock down the header for the dest table
     */
    hdr = (STHeader *)VMLock(vmDstHandle, dstTable, (MemHandle *)NULL);

    /*
     * Make sure the string isn't already in the dest table.
     */
    bucket = ST_HASH_TO_BUCKET(stcp->hashval);
    result = STSearch(vmDstHandle, hdr,
		      bucket, stcp->hashval,
		      stcp->string, stcp->length);

    if (result == NullID) {
	/*
	 * Not there -- allocate a new entry
	 */
	result = STAlloc(vmDstHandle, dstTable, hdr,
			 bucket, stcp->hashval,
			 stcp->string, stcp->length);
    }

    VMUnlock(vmDstHandle, dstTable);

    return(result);
}


/***********************************************************************
 *				ST_DupNoEnter
 ***********************************************************************
 * SYNOPSIS:	    Look up a string from one table in another.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The ID of the string in the new table
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/26/89		Initial Revision
 *
 ***********************************************************************/
ID
ST_DupNoEnter(VMHandle	    	vmSrcHandle,
	      ID   	    	srcID,
	      VMHandle	    	vmDstHandle,
	      VMBlockHandle	dstTable)
{
    STChainPtr	    stcp;
    STHeader	    *hdr;
    ID	    	    result;
    int	    	    bucket;

    /*
     * Convenience: Null IDs map to Null IDs (avoids conditionals in the
     * linker).
     */
    if (srcID == NullID) {
	return(NullID);
    }
    
    /*
     * Find the record in the source table
     */
    stcp = (STChainPtr)((char *)VMLock(vmSrcHandle,
				       srcID >> 16,
				       (MemHandle *)NULL) +
			((srcID & 0xffff) - offsetof(STChainRec, string)));

    /*
     * Lock down the header for the dest table
     */
    hdr = (STHeader *)VMLock(vmDstHandle, dstTable, (MemHandle *)NULL);

    /*
     * Make sure the string isn't already in the dest table.
     */
    bucket = ST_HASH_TO_BUCKET(stcp->hashval);
    result = STSearch(vmDstHandle, hdr,
		      bucket, stcp->hashval,
		      stcp->string, stcp->length);

    VMUnlock(vmDstHandle, dstTable);

    return(result);
}
