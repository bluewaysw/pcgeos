/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmAllocUnassigned.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Allocate an unassigned handle to someone
 *
 ***********************************************************************/

#include <config.h>
#include <compat/string.h>
#include <stdio.h>
#include "vmInt.h"


/***********************************************************************
 *				VMLinkNewBlocks
 ***********************************************************************
 * SYNOPSIS:	    Initialize a set of new blocks, placing them all
 *	    	    on the unassigned list.
 * CALLED BY:	    VMInitFile, VMAlloc
 * RETURN:	    Nothing
 * SIDE EFFECTS:    hdr->VMH_unassigned and VMH_numUnassigned are adjusted
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/31/89		Initial Revision
 *
 ***********************************************************************/
void
VMLinkNewBlocks(VMHeader    	*hdr,	    /* Header for file */
		VMBlock	    	*first,     /* First new block */
		int 	    	num)	    /* Number of new blocks */
{
    VMBlock 	*block = first;
    word    	hid;
    int	    	i;

    /*
     * Initialize all fields of new handles to 0
     */
    bzero((char *)first, num * sizeof(VMBlock));

    /*
     * Need a handle ID for the pointers, not a VMBlock *...
     */
    hid = VM_BLOCK_TO_HANDLE(first, hdr);
    
    /*
     * Link all the blocks into a chain of their own, ending up with
     * block pointing to the final block in the chain.
     */
    for (i = num-1; i > 0; i--) {
	hid += sizeof(VMBlock);
	block->VMB_nextPtr = hid;
	block++;
    }
    /*
     * Link the end of the chain to the start of the unassigned chain
     */
    block->VMB_nextPtr = hdr->VMH_unassigned;

    /*
     * Make the unassigned chain begin with the first block we were given.
     */
    hdr->VMH_unassigned = VM_BLOCK_TO_HANDLE(first, hdr);

    /*
     * Up the number of unassigned handles to include the new ones
     */
    hdr->VMH_numUnassigned += num;
}

/***********************************************************************
 *				VMAllocUnassigned
 ***********************************************************************
 * SYNOPSIS:	    Allocate an unassigned handle to the caller
 * CALLED BY:	    VMAlloc, VMFileFree (INTERNAL)
 * RETURN:	    VMBlock * for allocated handle
 * SIDE EFFECTS:    The table may be extended and the header dirtied.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 2/89		Initial Revision
 *
 ***********************************************************************/
VMBlock *
VMAllocUnassigned(VMFilePtr file)
{
    VMHeader	    *hdr = file->blkHdr;
    VMBlock 	    *block;

    if (hdr->VMH_numUnassigned == 0) {
	/*
	 * Need to extend the block table...
	 */
	VMBlockHandle	firstHandle;
	MemHandle   	headerHandle;
	
	firstHandle = hdr->VMH_lastHandle;

	hdr->VMH_lastHandle += (VM_EXTEND_NUM_BLKS * sizeof(VMBlock));

	/*
	 * Enlarge the header to hold the required number of handles, plus
	 * the normal header information.
	 */
	headerHandle = hdr->VMH_blockTable[0].VMB_memHandle;
	MemReAlloc(headerHandle, hdr->VMH_lastHandle, HAF_ZERO_INIT);
	MemInfo(headerHandle, (genptr *)&file->blkHdr, (word *)NULL);

	hdr = file->blkHdr;

	/*
	 * Place the blocks on the unassigned list
	 */
	if (firstHandle && (firstHandle > hdr->VMH_lastHandle))
	{
	    printf("Have exceeded glue's handle table limit!  Try reducing the number of resources.");
     	}
	VMLinkNewBlocks(hdr,
			VM_HANDLE_TO_BLOCK(firstHandle,hdr),
			VM_EXTEND_NUM_BLKS);
    }

    /*
     * Convert the head block to a pointer
     */
    block = VM_HANDLE_TO_BLOCK(hdr->VMH_unassigned, hdr);

    /*
     * Remove the head from the list
     */
    hdr->VMH_unassigned = block->VMB_nextPtr;
    hdr->VMH_numUnassigned -= 1;

    return(block);
}

