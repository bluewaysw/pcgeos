/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stDestroy.c
 *
 * AUTHOR:  	  Adam de Boor: Feb  28, 1990
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	2/28/90	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Free all space occupied by a string table.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: stDest.c,v 1.1 91/04/26 11:49:37 adam Exp $";
#endif lint

#include <config.h>
#include "stInt.h"


/***********************************************************************
 *				ST_Destroy
 ***********************************************************************
 * SYNOPSIS:	    Release all space occupied by a string table.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    See above...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/28/90		Initial Revision
 *
 ***********************************************************************/
void
ST_Destroy(VMHandle   	    vmHandle, 	/* File in which table resides */
	   VMBlockHandle    table)	/* Table to free */
{
    STHeader	    *hdr;   	/* Locked header block */
    int	    	    i;	    	/* Current bucket number */

    hdr = (STHeader *)VMLock(vmHandle, table, (MemHandle *)0);

    for (i = 0; i < ST_NUM_BUCKETS; i++) {
#if 0
	/* If we decide to chain things... */
	VMBlockHandle   next, cur;

	for (cur = hdr->chains[i]; cur != 0; cur = next) {
	    STChainHdr	*chdr = VMLock(vmHandle, cur, (MemHandle *)NULL);
	    next = chdr->next;
	    VMFree(vmHandle, cur);
	}
#else
	if (hdr->chains[i] != 0) {
	    VMFree(vmHandle, hdr->chains[i]);
	}
#endif
    }

    /*
     * Biff the header...
     */
    VMFree(vmHandle, table);
}
	
