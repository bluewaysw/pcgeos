/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmFind.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Locate a VM block by user-assigned ID	
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vmFind.c,v 1.5 91/04/26 11:52:30 adam Exp $";
#endif lint

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMFind
 ***********************************************************************
 * SYNOPSIS:	    Locate a block given its VMID
 * CALLED BY:	    EXTERNAL
 * RETURN:	    A VMBlockHandle or 0
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Straight, linear search, man
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/31/89		Initial Revision
 *
 ***********************************************************************/
VMBlockHandle
VMFind(VMHandle	    vmHandle,	/* File to search */
       VMID 	    id)	    	/* ID for which to search */
{
    VMFilePtr	    file;   	/* Internal representation of vmHandle */
    VMBlock 	    *block; 	/* Block being examined */
    VMBlock 	    *end;   	/* Value beyond which 'block' may not go */

    file = (VMFilePtr)vmHandle;

    for (block = &file->blkHdr->VMH_blockTable[1], end = VM_LAST(file);
	 block < end;
	 block++)
    {
	if (VM_IN_USE(block) && (block->VMB_uid == id)) {
	    return (VM_BLOCK_TO_HANDLE(block, file->blkHdr));
	}
    }
    return((VMBlockHandle)0);
}
