/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmModUID.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Change the user-assigned ID number for a VM block
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vmModUID.c,v 1.5 91/04/26 11:53:29 adam Exp $";
#endif lint

#include <config.h>
#include "vmInt.h"

    

/***********************************************************************
 *				VMModifyUserID
 ***********************************************************************
 * SYNOPSIS:	    Alter the recorded uid of a block
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    the VMB_uid field is overwritten
 *
 * STRATEGY:	    None to speak of
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/31/89		Initial Revision
 *
 ***********************************************************************/
void
VMModifyUserID(VMHandle	    	vmHandle,    	/* VM File */
	       VMBlockHandle	vmBlock,    	/* Block to alter */
	       VMID 	    	uid)	    	/* New ID */
{
    VMFilePtr	    file;   	    /* Internal representation of vmHandle */
    VMHeader	    *hdr;   	    /* Header block for vmHandle */
    VMBlock 	    *block; 	    /* Block being modified */

    file = (VMFilePtr)vmHandle;
    hdr = file->blkHdr;
    block = VM_HANDLE_TO_BLOCK(vmBlock, hdr);

    assert(VM_IN_USE(block));

    block->VMB_uid = uid;
}
