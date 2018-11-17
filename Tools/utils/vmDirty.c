/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmDirty.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Mark a block as dirty
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vmDirty.c,v 1.7 91/04/26 11:51:58 adam Exp $";
#endif lint

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMDirty
 ***********************************************************************
 * SYNOPSIS:	    Mark a handle as being dirty.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    If the block wasn't dirty before, its signature will
 *	    	    change
 *
 *	    	    If the block isn't the header, the header will be
 *	    	    marked dirty if the block wasn't dirty before
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/29/89		Initial Revision
 *
 ***********************************************************************/
void
VMDirty(VMHandle    	vmHandle,
	VMBlockHandle	vmBlock)
{
    VMFilePtr	    file = (VMFilePtr)vmHandle;
    VMBlock 	    *block = VM_HANDLE_TO_BLOCK(vmBlock, file->blkHdr);
    
    if (file->flags & VM_READ_ONLY) {
	/*
	 * The string table module likes to mess with data in a most
	 * unnerving manner, wanting us to mark things dirty, which
	 * we can't really do in a read-only file. Perhaps these files
	 * should be opened for writing?
	 */
	return;
    }
    
    assert(VM_IN_USE(block));
    assert(block->VMB_memHandle != 0);

    if (block->VMB_sig != VM_DIRTY_BLK_SIG) {

	block->VMB_sig = VM_DIRTY_BLK_SIG;

	/*
	 * Mark the header block as dirty, too, if not already marking
	 * the header block...
	 */
	if (vmBlock != VM_HEADER_ID) {
	    VMDirty(vmHandle, (VMBlockHandle)VM_HEADER_ID);
	}
    }
}
