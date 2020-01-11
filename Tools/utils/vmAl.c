/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmAlloc.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Allocate a new VM block
 *
 ***********************************************************************/

#include <config.h>
#include "vmInt.h"
#include "malloc.h"


/***********************************************************************
 *				VMAlloc
 ***********************************************************************
 * SYNOPSIS:	    Allocate a handle and initial memory for a VM block
 * CALLED BY:	    EXTERNAL
 * RETURN:	    VMBlockHandle for the new block
 * SIDE EFFECTS:    Header may be extended and is surely marked dirty.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/31/89		Initial Revision
 *
 ***********************************************************************/
VMBlockHandle
VMAlloc(VMHandle    	vmHandle,   /* File in which to allocate the block */
	int 	    	numBytes,   /* Initial number of bytes (may be 0) */
	VMID	    	id) 	    /* Initial ID to assign block (0 if
				     * don't care) */
{
    VMFilePtr	    file = (VMFilePtr)vmHandle;
    VMHeader	    *hdr;
    VMBlock 	    *block;

    /*
     * If file is read-only, can't allocate anything.
     */
    if (file->flags & VM_READ_ONLY) {
	assert(0);
	return((VMBlockHandle)0);
    }
    
    /*
     * Make sure we're allocating some memory...
     */
    if (numBytes == 0) {
	numBytes = 16;
    }

    assert(numBytes < 65536);
    
    block = VMAllocUnassigned(file);

    /*
     * Mark block as dirty (needs to make it to the file on update) and up
     * numUsed count for file. Also need to allocate memory for the thing.
     * We zero-init the block b/c that's what os90 does...
     */
    block->VMB_sig = VM_DIRTY_BLK_SIG;
    block->VMB_size = 0;
    block->VMB_pos = 0;
    block->VMB_uid = id;
    block->VMB_memHandle = MemAlloc(numBytes,
				    HF_SWAPABLE|HF_SHARABLE,
				    HAF_ZERO_INIT|HAF_NO_ERR);

#ifdef MEM_TRACE
    malloc_settag(MemLock(block->VMB_memHandle), id);
    MemUnlock(block->VMB_memHandle);
#endif

    hdr = file->blkHdr;
    hdr->VMH_numUsed += 1;
    hdr->VMH_numResident += 1;

    /*
     * Mark the header as dirty.
     */
    VMDirty(vmHandle, VM_HEADER_ID);

    /*
     * Return the handle ID to the user.
     */
    return(VM_BLOCK_TO_HANDLE(block,hdr));
}
