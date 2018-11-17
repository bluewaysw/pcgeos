/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- Memory Allocation: locking
 * FILE:	  memLock.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	MemLock	    	    Lock a block and return its address.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Lock a block and return its address.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: memLock.c,v 1.5 91/04/26 11:48:18 adam Exp $";
#endif lint

#include <config.h>
#include "memInt.h"


/***********************************************************************
 *				MemLock
 ***********************************************************************
 * SYNOPSIS:	    Lock a block and return its address
 * CALLED BY:	    External
 * RETURN:	    Base of locked block
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
void *
MemLock(MemHandle   	handle)
{
    assert(handle > 0 && handle < memNumHandles &&
	   memHandleTable[handle].addr != 0);
    
    return (memHandleTable[handle].addr);
}
