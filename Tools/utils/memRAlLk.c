/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- Memory Allocation
 * FILE:	  memReAllocLocked.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	MemReAllocAndLock   Change the size of a block and lock it down.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Change the size of a block and lock it down.
 *
 ***********************************************************************/
#include <config.h>
#include "memInt.h"


/***********************************************************************
 *				MemReAllocAndLock
 ***********************************************************************
 * SYNOPSIS:	    Change the size of a block and return its new address
 * CALLED BY:	    EXTERNAL
 * RETURN:	    non-zero and new address if successful
 * SIDE EFFECTS:    Same as MemReAlloc
 *
 * STRATEGY:	    Call MemReAlloc and return block's address if ok
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 2/89		Initial Revision
 *
 ***********************************************************************/
int
MemReAllocAndLock(MemHandle 	handle,	    	/* Handle to alter */
		  short	    	numBytes,   	/* New size */
		  short	    	allocFlags, 	/* Flags for new memory */
		  void	    	**addrPtr)  	/* Place to store new address*/
{
    int	    result;

    result = MemReAlloc(handle, numBytes, allocFlags);

    if (result) {
	*addrPtr = memHandleTable[handle].addr;
    }

    return(result);
}
