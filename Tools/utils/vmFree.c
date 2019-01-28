/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmFree.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Free a VM block
 *
 ***********************************************************************/

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMFree
 ***********************************************************************
 * SYNOPSIS:	    Free a block, both in memory and in the file.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The handle goes on the assigned list, unless its
 *	    	    file space is coalesced with a previous block.
 *
 * STRATEGY:
 *	- If block has memory with it, free it.
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/31/89		Initial Revision
 *
 ***********************************************************************/
void
VMFree(VMHandle	    	vmHandle,
       VMBlockHandle	vmBlock)
{
    VMFilePtr	    file;   	/* Internal representation of vmHandle */
    VMHeader	    *hdr;   	/* Header describing same */
    VMBlock 	    *block; 	/* Block being freed...sort of */

    file = (VMFilePtr)vmHandle;
    hdr = file->blkHdr;
    block = VM_HANDLE_TO_BLOCK(vmBlock, hdr);

    /*
     * If file is read-only, can't free anything.
     */
    if (file->flags & VM_READ_ONLY) {
	assert(0);
	return;
    }

    /*
     * Free any memory associated with the block and adjust the in-use and
     * dirty counters for the file to reflect this block's absence,
     * altering the block's signature so it no longer appears in-use.
     */
    if ((block->VMB_memHandle != 0) || (block == hdr->VMH_blockTable)) {
	MemFree(block->VMB_memHandle);
	hdr->VMH_numResident -= 1;
    }

    /*
     * If the block has file space allocated to it, free that now too.
     */
    if (block->VMB_pos != 0) {
	VMFileFree(file, block->VMB_pos, block->VMB_size);
    }

    /*
     * Reduce the count of used blocks.
     */
    hdr->VMH_numUsed -= 1;

    block->VMB_sig = 0;	/* So we don't think it's in-use... */

    /*
     * Place the block on the unassigned list
     */
    block->VMB_nextPtr = hdr->VMH_unassigned;
    hdr->VMH_unassigned = vmBlock;
    hdr->VMH_numUnassigned += 1;
}
