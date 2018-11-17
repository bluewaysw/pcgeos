/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmDetach.c
 *
 * AUTHOR:  	  Adam de Boor: Sep 26, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/26/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Detach a memory handle from a VM block handle
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vmDetach.c,v 1.5 91/04/26 11:51:50 adam Exp $";
#endif lint

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMDetach
 ***********************************************************************
 * SYNOPSIS:	    Unbind a memory block from a VM data block. This
 *	    	    allows the memory block to be bound to another
 *	    	    data block in a different file (or the same one)
 *	    	    thus copying the data without having to copy it.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The memory handle for the block. If the block isn't
 *	    	    in memory and has no data in the file, returns NULL
 * SIDE EFFECTS:    If the block was dirty, it is written to disk before
 *	    	    being detached.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/26/89		Initial Revision
 *
 ***********************************************************************/
MemHandle
VMDetach(VMHandle   	vmHandle,
	 VMBlockHandle	vmBlock)
{
    VMFilePtr	    file;   	    /* Internal representation of vmHandle */
    VMHeader	    *hdr;   	    /* Header data for file */
    VMBlock 	    *block; 	    /* Block being locked */
    MemHandle	    retval; 	    /* Value to return */

    file = (VMFilePtr)vmHandle;
    hdr = file->blkHdr;
    block = VM_HANDLE_TO_BLOCK(vmBlock, hdr);

    /*
     * Make sure block is in-use.
     */
    assert(VM_IN_USE(block));

    if (block->VMB_memHandle == 0) {
	/*
	 * Block has no memory associated with it -- read the thing in
	 * from disk first.
	 */
	if (block->VMB_pos != 0) {
	    block->VMB_memHandle = VMAllocAndRead(file, block->VMB_pos,
						  block->VMB_size);
	    /*
	     * If relocation routine given, call it now, passing the relevant
	     * parameters to it to identify the block.
	     */
	    if (file->reloc != (VMRelocRoutine *)0) {
		(*file->reloc)(vmHandle, vmBlock, block->VMB_uid,
			       block->VMB_memHandle,
			       MemLock(block->VMB_memHandle));
	    }
	} else {
	    /*
	     * No copy of the block in the file -- choke now.
	     */
	    return((MemHandle)NULL);
	}
    }
    
    retval = block->VMB_memHandle;

#if 0
    /*
     * If the block is dirty, flush it to disk.
     *
     * 3/22/90 -- there's probably a reason for detaching the dirty
     * block that would likely be thwarted by flushing the thing to disk
     * first. Besides, PC/GEOS doesn't do it and doing so introduces a
     * Bug in Glue.
     */
    if (block->VMB_sig == VM_DIRTY_BLK_SIG) {
	VMWriteBlock(file, block);
	VMFlushWrites(file);
    }
#endif

    block->VMB_memHandle = (MemHandle)0;

    return(retval);
}
