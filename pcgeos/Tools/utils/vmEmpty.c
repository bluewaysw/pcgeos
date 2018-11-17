/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmEmpty.c
 *
 * AUTHOR:  	  Adam de Boor: January  23, 1990
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	1/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Nuke any memory associated witha block
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vmEmpty.c,v 3.1 91/04/26 11:52:08 adam Exp $";
#endif lint

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMEmpty
 ***********************************************************************
 * SYNOPSIS:	    Free the memory associated with a block
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The memory handle for the block will be freed and the
 *	    	    VMBH_memHandle field zeroed. If the block is locked
 *	    	    again, the data will come in from disk.
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
VMEmpty(VMHandle	vmHandle,   /* File to which block belongs */
	VMBlockHandle	vmBlock)    /* Block to empty */
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
	block->VMB_memHandle = 0;
    }
}
