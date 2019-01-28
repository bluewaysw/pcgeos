/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmInfo.c
 *
 * AUTHOR:  	  Adam de Boor: January  23, 1990
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	1/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Return info about a VM block
 *
 ***********************************************************************/

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMInfo
 ***********************************************************************
 * SYNOPSIS:	    Fetch info about a block
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The size, memory handle and user ID for a block
 * SIDE EFFECTS:    
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
VMInfo(VMHandle	    	vmHandle,   /* File to which block belongs */
       VMBlockHandle	vmBlock,    /* Block for which info is desired */
       word 	    	*sizePtr,   /* Place to store current block size */
       MemHandle    	*memPtr,    /* Place to store memory handle (0 if not
				     * resident) */
       VMID 	    	*idPtr)	    /* Place to store ID for the block */
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

    /*
     * Use the recorded block size if not resident, else use the size of the
     * current memory block.
     */
    if (sizePtr) {
	*sizePtr = block->VMB_size;
	if (block->VMB_memHandle != 0) {
	    MemInfo(block->VMB_memHandle, (genptr *)NULL, sizePtr);
	}
    }

    if (memPtr) {
	*memPtr = block->VMB_memHandle;
    }

    if (idPtr) {
	*idPtr = block->VMB_uid;
    }
}
