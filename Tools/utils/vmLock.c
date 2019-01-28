/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmLock.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Lock a VM block, returning its handle and address
 *
 ***********************************************************************/

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMLock
 ***********************************************************************
 * SYNOPSIS:	    Lock down a VM block
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The base of the block in memory
 * SIDE EFFECTS:    A handle will be allocated for the block if
 *	    	    none already exists.
 *	    	    If a relocation routine was given for the file, and
 *	    	    the block was brought in from disk, the routine
 *	    	    will be called.
 *
 * STRATEGY:
 *	If no handle allocated for the block, do so now.
 *	If block in file, read it in and relocate it.
 *	Return the base of the memory block
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/31/89		Initial Revision
 *
 ***********************************************************************/
genptr
VMLock(VMHandle	    	vmHandle,   /* File to which block belongs */
       VMBlockHandle	vmBlock,    /* Block to be locked */
       MemHandle    	*handlePtr) /* Place to store memory handle */
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
     * If no memory assigned to the block yet, do so now.
     */
    if (block->VMB_memHandle == 0) {
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
	     * No copy of the block in the file, but should have been
	     * allocated before -- choke now.
	     */
	    assert(0);
	    return((genptr)NULL);
	}
    }

    if (handlePtr) {
	*handlePtr = block->VMB_memHandle;
    }

    /*
     * Finally, return the base of the block in memory
     */
		{
			return MemLock(block->VMB_memHandle);
		}
}
