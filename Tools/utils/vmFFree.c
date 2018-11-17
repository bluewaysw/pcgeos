/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmFileFree.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Release a region of a VM file
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vmFFree.c,v 1.1 91/04/26 11:52:24 adam Exp $";
#endif lint

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMFileFree
 ***********************************************************************
 * SYNOPSIS:	    Release a region of the file, placing it on the
 *	    	    assigned list in the proper location.
 * CALLED BY:	    VMFree, VMWriteBlock (INTERNAL)
 * RETURN:	    Nothing
 * SIDE EFFECTS:    An unassigned handle may be taken and placed on
 *	    	    the assigned list.
 *
 * STRATEGY:
 *	- Locate the proper place in the assigned list for the block,
 *	keeping track of the preceding block.
 *	- If freed block follows directly after preceding block, up
 *	the size of the preceding block and shift the freed block handle
 *	to the unassigned list, making the preceding block the one
 *	at which we look for the next test.
 *	- If block is immediately before next block in the assigned list:
 *	    - If block was coalesced above, give the next block's space to
 *	    the combined block and place the next block on the unassigned list
 *	    - Else, give the freed block's space to the next block and place
 *	    the freed block on the unassigned list.
 *	- If can't coalesce either way, link freed block into assigned list.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 2/89		Initial Revision
 *
 ***********************************************************************/
void
VMFileFree(VMFilePtr	file,	    /* File to alter */
	   dword    	pos,	    /* Start of region to free */
	   word	    	size)	    /* Size of region being freed */
{
    VMHeader	    *hdr;   	    /* Header for file */
    VMBlock 	    *cur;   	    /* Block being examined (after region) */
    VMBlock 	    *prev;  	    /* Block before region */
    int	    	    prevMerged = 0; /* Non-zero if merged into prev */
    int	    	    aftMerged = 0;  /* Non-zero if merged into cur */
    VMBlockHandle   prevH, curH;
    
    /*
     * Locate the header.
     */
    hdr = file->blkHdr;
    
    /*
     * Reduce size of in-use blocks.
     */
    hdr->VMH_usedSize -= size;

    /*
     * Look for insertion point in 'assigned' list
     */
    for (prev = (VMBlock *)0, cur = VM_HANDLE_TO_BLOCK(hdr->VMH_assigned, hdr);
	 cur != VM_NULL(file);
	 cur = VM_HANDLE_TO_BLOCK(cur->VMB_nextPtr, hdr))
    {
	if (cur->VMB_pos > pos) {
	    break;
	}
	prev = cur;
    }
    
    /*
     * 'prev' is now either 0 (freed block goes at start of list) or
     * the block after which region is to be inserted, if not coalesced.
     *
     * 'cur' is either VM_NULL(file) (freed block goes at the end of the
     * list) or is the block before which region is to be inserted, if
     * not coalesced.
     */
    
    if (prev != 0 && (prev->VMB_pos + prev->VMB_free.VMBF_size) == pos) {
	/*
	 * Previous block abuts current one -- coalesce the two,
	 * recording this in the prevMerged variable.
	 */
	prev->VMB_free.VMBF_size += size;
	prevMerged = 1;
    }
    
    if (cur != VM_NULL(file) && (pos + size) == cur->VMB_pos) {
	/*
	 * Next block follows immediately after region. If region not
	 * coalesced with prev, we want to stretch cur back to cover the
	 * region. Otherwise, we want to stretch 'prev' to cover cur and
	 * remove cur from the assigned list.
	 */
	if (!prevMerged) {
	    /*
	     * Stretch cur back to cover block.
	     */
	    cur->VMB_free.VMBF_size += size;
	    cur->VMB_pos = pos;
	} else {
	    /*
	     * Extend 'prev' to cover 'cur' and shift 'cur' to the
	     * unassigned list.
	     */
	    prev->VMB_free.VMBF_size += cur->VMB_free.VMBF_size;
	    prev->VMB_nextPtr = cur->VMB_nextPtr;
	    
	    cur->VMB_pos = 0;
	    cur->VMB_nextPtr = hdr->VMH_unassigned;
	    hdr->VMH_unassigned = VM_BLOCK_TO_HANDLE(cur,hdr);
	    hdr->VMH_numUnassigned += 1;
	    hdr->VMH_numAssigned -= 1;
	}
	aftMerged = 1;
    }
    
    if (!prevMerged && !aftMerged) {
	VMBlock *block;

	/* The next operation may move these pointers. */

	curH = VM_BLOCK_TO_HANDLE(cur, hdr);
	if (prev != 0) {
	    prevH = VM_BLOCK_TO_HANDLE(prev, hdr);
	}

        /*
         * Region wasn't merged into either the before or after, so
         * get an unassigned handle and link it into the assigned list with
         * the region's position and size.
         */

	block = VMAllocUnassigned(file);
	
	/*
	 * Get header pointer again (if header was extended by
	 * VMAllocUnassigned, header block might have moved).
	 */
	hdr = file->blkHdr;

	/* dereference other (possibly moved) pointers */

	cur = VM_HANDLE_TO_BLOCK(curH, hdr);
	if (prev != 0) {
	    prev = VM_HANDLE_TO_BLOCK(prevH, hdr);
	}

	
	if (prev != 0) {
	    /*
	     * Not at front -- just link after prev
	     */
	    prev->VMB_nextPtr = VM_BLOCK_TO_HANDLE(block,hdr);
	} else {
	    /*
	     * At front -- link there
	     */
	    hdr->VMH_assigned = VM_BLOCK_TO_HANDLE(block,hdr);
	}
	
	/*
	 * Link cur after block.
	 */
	if (cur != VM_NULL(file)) {
	    block->VMB_nextPtr = VM_BLOCK_TO_HANDLE(cur,hdr);
	} else {
	    block->VMB_nextPtr = 0;
	}
	
	hdr->VMH_numAssigned += 1;
    }
}
