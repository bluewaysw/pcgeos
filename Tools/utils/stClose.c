/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stClose.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  7, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 7/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Release extra working space allocated for the table 
 *
 ***********************************************************************/
#include <config.h>
#include "stInt.h"


/***********************************************************************
 *				ST_Close
 ***********************************************************************
 * SYNOPSIS:	    Shrink the current string data block and chain
 *	    	    block down to the number of bytes actually in-use.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Non-zero if table is non-empty. If table is empty,
 *	    	    caller is free to call VMFree on the table block.
 * SIDE EFFECTS:    See above...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 7/89		Initial Revision
 *
 ***********************************************************************/
int
ST_Close(VMHandle   	vmHandle,   	/* File in which table resides */
	 VMBlockHandle	table)	    	/* Table to shrink */
{
    STHeader	    *hdr;   	/* Locked header block */
    MemHandle	    mem;    	/* General memory handle for MemReAlloc */
    int	    	    i;	    	/* Current bucket number */
    int	    	    result = 0;	/* Value to return. Set to 1 if non-empty
				 * chain encountered */

    hdr = (STHeader *)VMLock(vmHandle, table, (MemHandle *)0);

    for (i = 0; i < ST_NUM_BUCKETS; i++) {
	if (hdr->chains[i] != 0) {
	    /*
	     * Non-empty chain -- lock down the block and resize the
	     * handle to match the current offset.
	     */
	    STChainHdr	*chdr = (STChainHdr *)
	      VMLock(vmHandle, hdr->chains[i], &mem);

	    if (chdr->offset == sizeof(STChainHdr)) {
		/*
		 * Must have had a failed allocation. This chain is actually
		 * empty. Nuke the block and zero out the chains field...
		 */
		VMUnlock(vmHandle, hdr->chains[i]);
		VMFree(vmHandle, hdr->chains[i]);
		hdr->chains[i] = (VMBlockHandle)0;
		VMDirty(vmHandle, table);
	    } else {
		/*
		 * Adjust and unlock the block, setting the result to 1 since
		 * we've got at least one non-empty chain. Mark the block
		 * as dirty to ensure the size change making it to disk.
		 */
		(void)MemReAlloc(mem, chdr->offset, 0);
		VMUnlock(vmHandle, hdr->chains[i]);
		VMDirty(vmHandle, hdr->chains[i]);
		result = 1;
	    }
	}
    }

    /*
     * Release the header...
     */
    VMUnlock(vmHandle, table);

    return(result);
}
	
