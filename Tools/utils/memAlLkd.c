/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- Memory Allocation
 * FILE:	  memAllocLocked.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	MemAllocAndLock	    Allocate a block, lock it and return its address
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Allocate a block and lock it immediately.
 *
 ***********************************************************************/
#include <config.h>
#include "memInt.h"


/***********************************************************************
 *				MemAllocAndLock
 ***********************************************************************
 * SYNOPSIS:	    Just like MemAlloc, except returns the address of
 *	    	    the allocated memory, too.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    MemHandle and address of block
 * SIDE EFFECTS:    A handle be allocated
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 2/89		Initial Revision
 *
 ***********************************************************************/
MemHandle
MemAllocAndLock(short	    numBytes,	    /* Number of bytes to allocate */
		short	    typeFlags,	    /* Type of block (ignored) */
		short	    allocFlags,	    /* Flags for allocation */
		void	    **addrPtr)	    /* Place to store block addr */
{
    MemHandle	    handle;

    handle = MemAlloc(numBytes, typeFlags, allocFlags);

    if (handle != (MemHandle)0) {
	*addrPtr = memHandleTable[handle].addr;
    }
    return(handle);
}
