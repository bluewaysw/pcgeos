/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- Memory Allocation: freeing
 * FILE:	  memFree.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	MemFree	    	    Free a block and handle
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Free a block and handle
 *
 ***********************************************************************/
#include <config.h>
#include "malloc.h"
#include "memInt.h"


/***********************************************************************
 *				MemFree
 ***********************************************************************
 * SYNOPSIS:	    Free a block handle and its memory
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The handle is freed
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
MemFree(MemHandle   handle)
{
    
    assert(handle > 0 && handle < memNumHandles &&
	   memHandleTable[handle].addr != 0);
    
    free((char *)memHandleTable[handle].addr);

    MemFreeHandle(handle);
}
