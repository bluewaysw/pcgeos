/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- Memory Allocation
 * FILE:	  memReAlloc.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	MemReAlloc  	    Alter the size of an existing block.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Change the size of an existing block.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: memRAl.c,v 1.2 92/06/02 21:17:54 adam Exp $";
#endif lint

#include <config.h>
#include <compat/string.h>
#include "malloc.h"
#include "memInt.h"


/***********************************************************************
 *				MemReAlloc
 ***********************************************************************
 * SYNOPSIS:	    Alter the size of an existing block.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    non-zero if successful
 * SIDE EFFECTS:    The size field in the handle table is changed to
 *	    	    reflect the new size.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 2/89		Initial Revision
 *
 ***********************************************************************/
int
MemReAlloc(MemHandle	    handle,
	   word    	    numBytes,
	   short    	    allocFlags)
{
    void    	*newBlock;
    int	    	oldSize;
    
    assert(handle > 0 && handle < memNumHandles &&
	   memHandleTable[handle].addr != 0);
    
    newBlock = (void *)realloc(memHandleTable[handle].addr,
			       numBytes);

    /*
     * Deal with allocation failure.
     */
    if (newBlock == (void *)0) {
	if (allocFlags & HAF_NO_ERR) {
	    MemAllocErr();
	} else {
	    /*
	     * XXX: has old block been freed now? I don't think so.
	     */
	    return(0);
	}
    }

    /*
     * Deal with request for zero-init of new memory
     */
    oldSize = memHandleTable[handle].size;
    /*
     * if ((allocFlags & HAF_ZERO_INIT) && (numBytes > oldSize)) {
     *	bzero((char *)newBlock + oldSize, numBytes - oldSize);
     * }
     */
    if (numBytes > oldSize) {
        bzero((char *)newBlock + oldSize, numBytes - oldSize);
    }


    /*
     * Store new parameters
     */
    memHandleTable[handle].addr = newBlock;
    memHandleTable[handle].size = numBytes;

    /*
     * Indicate success
     */
    return(1);
}
    
