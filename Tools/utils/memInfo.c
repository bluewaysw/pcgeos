/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- Memory Allocation: information fetching
 * FILE:	  memInfo.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	MemInfo	    	    Retrieve information about a handle
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Retrieve information about a handle
 *
 ***********************************************************************/
#include <config.h>
#include "memInt.h"


/***********************************************************************
 *				MemInfo
 ***********************************************************************
 * SYNOPSIS:	    Retrieve the address and size of a memory block
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The address and size
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 2/89		Initial Revision
 *
 ***********************************************************************/
void
MemInfo(MemHandle   handle,
	genptr	    *addrPtr,
	word 	    *sizePtr)
{
    assert(handle > 0 && handle < memNumHandles &&
	   memHandleTable[handle].addr != 0);
    
    if (addrPtr) {
	*addrPtr = memHandleTable[handle].addr;
    }
    if (sizePtr) {
	*sizePtr = memHandleTable[handle].size;
    }
}
