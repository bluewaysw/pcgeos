/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmClose.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Close down a VM file
 *
 ***********************************************************************/

#include <config.h>
#include <compat/file.h>
#include "vmInt.h"
#include "malloc.h"


/***********************************************************************
 *				VMClose
 ***********************************************************************
 * SYNOPSIS:	    Close down a VM file, writing all dirty blocks to
 *	    	    disk and freeing up all in-core blocks.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    All resources associated with the file are
 *	    	    released.
 *	    	    Any temp file created is removed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/19/89		Initial Revision
 *
 ***********************************************************************/
void
VMClose(VMHandle    vmHandle)
{
    VMFilePtr	    file = (VMFilePtr)vmHandle;
    VMBlock 	    *block; 	/* Block being tested for dirt */
    int	    	    i;	    	/* Number of in-use blocks left to check */
    VMHeader	    *hdr;   	/* Header block for file */

    /*
     * Write it to disk if it's not temporary (no point in writing out
     * stuff we're just going to delete, after all...)
     */
    if (!(file->flags & VM_TEMP_FILE)) {
	/*
	 * First sync the copy on disk.
	 */
	VMUpdate(vmHandle);
    }

    hdr = file->blkHdr;
    
    /*
     * Locate and free all the memory for in-use blocks. We start 'i' at
     * numUsed - 1 b/c we don't free the header block until the end (avoids
     * referencing into free memory), and the header is included in the
     * numUsed count.
     */
    for (i = hdr->VMH_numUsed-1, block = &hdr->VMH_blockTable[1];
	 i > 0;
	 block++)
    {
	if (VM_IN_USE(block)) {
	    if (block->VMB_memHandle) {
		/*
		 * Release the in-core version
		 */
		MemFree(block->VMB_memHandle);
	    }
	    /*
	     * One fewer in-use block to find
	     */
	    i--;
	}
    }

    /*
     * Free the header block now
     */
    MemFree(hdr->VMH_blockTable[0].VMB_memHandle);

    /*
     * Close the stream
     */
    (void)FileUtil_Close(file->fd);

    /*
     * If temporary, unlink it.
     */
    if (file->flags & VM_TEMP_FILE) {
	(void)unlink(file->name);
    }

    free(file->name);

    /*
     * And the VMHandle itself
     */
    free((char *)file);
}

