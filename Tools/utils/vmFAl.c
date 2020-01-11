/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmFileAlloc.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Allocation of space in a VM file
 *
 ***********************************************************************/

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMFileAlloc
 ***********************************************************************
 * SYNOPSIS:	    Locate room in the file for a block
 * CALLED BY:	    VMWriteBlock (INTERNAL)
 * RETURN:	    block->VMB_pos set
 * SIDE EFFECTS:    Assigned handles may become unassigned.
 *	    	    file->blkHdr->VMH_usedSize will be extended
 *	    	    The header is marked dirty.
 *
 * STRATEGY:
 *	The assigned list is sorted by file-order.
 *	We use the same strategy as the OS90 kernel: first-fit.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/29/89		Initial Revision
 *
 ***********************************************************************/
dword
VMFileAlloc(VMFilePtr	file,	    /* File in which to allocate room */
	    word    	size)	    /* Size of area required */
{
    VMBlock 	*cur;	    /* Block being examined */
    word 	*curP;	    /* Address of pointer to cur */
    long    	pos;	    /* Position to return */

    /*
     * First look for a block that's big enough. At the end of the loop,
     * cur will be VM_NULL or the block to use. curP will be
     * the address of the pointer to cur (as a handle ID...)
     */
    curP = &file->blkHdr->VMH_assigned;
    for(cur = VM_HANDLE_TO_BLOCK(*curP, file->blkHdr);
	cur != VM_NULL(file);
	cur = VM_HANDLE_TO_BLOCK(*curP, file->blkHdr))
    {
	if (cur->VMB_size >= size) {
	    break;
	} else {
	    curP = &cur->VMB_nextPtr;
	}
    }

    if (cur == VM_NULL(file)) {
	/*
	 * Nothing big enough -- allocate room at the end of the file
	 * and have done.
	 */
	pos = ((file->flags & VM_2_0) ?
	       file->fsize - sizeof(GeosFileHeader2) :
	       file->fsize);

	/*
	 * Update the file size.
	 */
	file->fsize += size;
    } else {
	/*
	 * No matter what, the block begins at the start of the chosen,
	 * assigned block.
	 */
	pos = cur->VMB_pos;

	if (cur->VMB_size != size) {
	    /*
	     * Not an exact match -- split the block in two, giving
	     * the starting piece to the new block and leaving the
	     * rest to the old, assigned block.
	     */
	    cur->VMB_size -= size;
	    cur->VMB_pos += size;
	} else {
	    /*
	     * Shift the handle to be unassigned.
	     */
	    word    curID = *curP; /* Need ID for unassigned list */
	    
	    /*
	     * Unlink from the assigned list. This list is only singly-linked
	     * when in-core.
	     */
	    *curP = cur->VMB_nextPtr;
	    file->blkHdr->VMH_numAssigned -= 1;
	    cur->VMB_nextPtr = file->blkHdr->VMH_unassigned;

	    /*
	     * Link it into the unassigned list at the front.
	     */
	    cur->VMB_nextPtr = file->blkHdr->VMH_unassigned;
	    file->blkHdr->VMH_unassigned = curID;
	    file->blkHdr->VMH_numUnassigned += 1;
	}
    }

    /*
     * Mark the header as dirty...
     */
    VMDirty((VMHandle)file, VM_HEADER_ID);

    /*
     * Add the size of this block into the total number of bytes actually
     * in-use in the file.
     */
    file->blkHdr->VMH_usedSize += size;

    return(pos);
}
