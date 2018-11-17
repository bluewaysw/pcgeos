/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- Memory Allocation
 * FILE:	  memAlloc.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  1, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	MemAlloc    	    Allocate a block and return its handle
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 1/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Allocate a block.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: memAl.c,v 1.1 91/04/26 11:47:36 adam Exp $";
#endif lint

#include <config.h>
#include <compat/string.h>

#include "malloc.h"
#include "memInt.h"


/***********************************************************************
 *				MemAlloc
 ***********************************************************************
 * SYNOPSIS:	    Allocate a block of memory, returning its handle.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The handle allocated
 * SIDE EFFECTS:    A block of memory of the given size is allocated and
 *	    	    its address stored in the handle table.
 *
 * STRATEGY:
 *	- Allocate a handle
 *	- Allocate a block of memory
 *	- Store the address in the handle
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 1/89		Initial Revision
 *
 ***********************************************************************/
MemHandle
MemAlloc(word	    numBytes,	    /* Number of bytes to allocate */
	 short	    typeFlags,	    /* Type of block (ignored) */
	 short	    allocFlags)	    /* Flags for allocation */
{
    MemHandle	    handle;
    void    	    *block;

    handle = MemAllocHandle();
    block = (void *)malloc(numBytes);

    if (block == 0) {
    	if (allocFlags & HAF_NO_ERR) {
	    MemAllocErr();
	} else {
	    /*
	     * No need to free the handle -- it's not really allocated until
	     * we store an address in it...
	     */
	    return((MemHandle)0);
	}
    }

    /*
     * Deal with request for zero-initialization...
     */
    if (allocFlags & HAF_ZERO_INIT) {
	bzero(block, numBytes);
    }

    /*
     * Use the handle to store the parameters
     */
    memHandleTable[handle].addr = block;
    memHandleTable[handle].size = numBytes;

    /*
     * Return the allocated handle
     */
    return (handle);
}
