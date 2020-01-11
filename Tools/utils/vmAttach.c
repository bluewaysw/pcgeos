/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmAttach.c
 *
 * AUTHOR:  	  Adam de Boor: Sep 26, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/26/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Attach a memory block to a vm block
 *
 ***********************************************************************/

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMAttach
 ***********************************************************************
 * SYNOPSIS:	    Attach a memory block to a VM block. See VMDetach
 *	    	    for rationale.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Any previous memory block is freed. The vm block is
 *	    	    marked dirty.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/26/89		Initial Revision
 *
 ***********************************************************************/
void
VMAttach(VMHandle   	vmHandle,
	 VMBlockHandle	vmBlock,
	 MemHandle  	mem)
{
    VMFilePtr	    file;   	    /* Internal representation of vmHandle */
    VMHeader	    *hdr;   	    /* Header data for file */
    VMBlock 	    *block; 	    /* Block being locked */

    file = (VMFilePtr)vmHandle;
    hdr = file->blkHdr;
    block = VM_HANDLE_TO_BLOCK(vmBlock, hdr);

    /*
     * Make sure block is in-use.
     */
    assert(VM_IN_USE(block));

    if (block->VMB_memHandle != 0) {
	MemFree(block->VMB_memHandle);
    }

    block->VMB_memHandle = mem;

    /*
     * If block not already marked dirty, do so now.
     */
    if (block->VMB_sig != VM_DIRTY_BLK_SIG) {
	block->VMB_sig = VM_DIRTY_BLK_SIG;
    }
}
