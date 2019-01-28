/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- Memory Allocation: utilities
 * FILE:	  memUtils.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  1, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	MemAllocErr 	    Produce error message if can't allocate memory
 *	MemAllocHandle	    Allocate a handle
 *	MemFreeHandle	    Free a handle
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 1/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to deal with the handle table
 *
 ***********************************************************************/
#include <config.h>
#include <compat/string.h>
#include <compat/stdlib.h>
#include <compat/file.h>

#ifdef _WIN32
#include <io.h>
#endif

#include "malloc.h"
#include "memInt.h"

#define	MEM_INIT_NUM_HANDLES	30
#define MEM_INCR_NUM_HANDLES	30

/*
 * Table of handles
 */
MemHandlePtr	memHandleTable = (MemHandlePtr)0;
int	    	memNumHandles = 0;
static int  	memHandleFreeList = -1;


/***********************************************************************
 *				MemAllocErr
 ***********************************************************************
 * SYNOPSIS:	    Produce an error message when can't allocate memory
 * CALLED BY:	    MemAlloc, MemReAlloc
 * RETURN:	    No
 * SIDE EFFECTS:    Process exits.
 *
 * STRATEGY:
 *	Writes a standard string on stream 2 (stderr) w/o using stdio
 *	(to avoid other memory allocations) and exits.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 2/89		Initial Revision
 *
 ***********************************************************************/
volatile void
MemAllocErr(void)
{
    char	*memAllocErr = "Virtual memory exhausted\n";
#ifdef unix
    /* Only lame SunOS fails to declare this */
    extern volatile void exit();
#endif

    write(2, memAllocErr, strlen(memAllocErr));
    exit(1);
}


/***********************************************************************
 *				MemAllocHandle
 ***********************************************************************
 * SYNOPSIS:	    Allocate a handle and return its index.
 * CALLED BY:	    MemAlloc
 * RETURN:	    The MemHandle allocated
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 1/89		Initial Revision
 *
 ***********************************************************************/
MemHandle
MemAllocHandle()
{
    int	    i;

    if (memHandleFreeList < 0) {

	/*
	 * Not found. Index to return is that of the first new one we're about
	 * to allocate (which i already contains...it's memNumHandles)
	 */
	if (memNumHandles == 0) {
	    /*
	     * No handle table yet -- just initialize the thing.
	     */
	    memHandleTable = (MemHandlePtr)malloc(MEM_INIT_NUM_HANDLES *
						  sizeof(MemHandleRec));
	    memNumHandles = MEM_INIT_NUM_HANDLES;
	    /*
	     * Reserve handle 0 as error code...
	     */
	    memHandleTable[0].addr = (void *)1;
	    i = 1;
	} else {
	    /*
	     * Expand the handle table by the specified number of handles,
	     * zeroing out all new handles (so we know they're free)
	     */
	    i = memNumHandles + 1;
	    memNumHandles += MEM_INCR_NUM_HANDLES;
	    memHandleTable = (MemHandlePtr)realloc((char *)memHandleTable,
						   memNumHandles *
						   sizeof(MemHandleRec));
	}
	/*
	 * Link the free handles through their size field (as it's an integer)
	 */
	memHandleFreeList = i;
	while (i < memNumHandles-1) {
	    memHandleTable[i].size = i+1;
	    i++;
	}
	memHandleTable[i].size = -1;
    }

    i = memHandleFreeList;
    memHandleFreeList = memHandleTable[i].size;

    /*
     * Return index chosen.
     */
    return(i);
}


/***********************************************************************
 *				MemFreeHandle
 ***********************************************************************
 * SYNOPSIS:	    Release an allocated handle.
 * CALLED BY:	    MemFree
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The addr field of the MemHandleRec is zeroed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 1/89		Initial Revision
 *
 ***********************************************************************/
void
MemFreeHandle(MemHandle	handle)
{
    assert((memNumHandles > 0) && (handle < memNumHandles));

    memHandleTable[handle].size = memHandleFreeList;
    memHandleFreeList = handle;
}
