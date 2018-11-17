/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  vmAttr.c
 * FILE:	  vmAttr.c
 *
 * AUTHOR:  	  Adam de Boor: March 29, 1990
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/29/90	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to set/get the VM file's attribute bits.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vmAttr.c,v 1.3 92/12/10 22:08:46 adam Exp $";
#endif lint

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMGetAttributes
 ***********************************************************************
 * SYNOPSIS:	    Fetch the attributes for the VM file.
 * CALLED BY:	    GLOBAL
 * RETURN:	    The attributes for the file
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	Just copy the shadow version from the VMHandle out.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/90		Initial Revision
 *
 ***********************************************************************/
byte
VMGetAttributes(VMHandle    vmHandle)
{
    VMFilePtr	    file = (VMFilePtr)vmHandle;

    return (file->blkHdr->VMH_attributes);
}


/***********************************************************************
 *				VMSetAttributes
 ***********************************************************************
 * SYNOPSIS:	    Set the attributes for the VM file
 * CALLED BY:	    GLOBAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/90		Initial Revision
 *
 ***********************************************************************/
void
VMSetAttributes(VMHandle    vmHandle,
		byte	    set,    	/* Bits to set */
		byte	    reset)  	/* Bits to reset (to 0) */
{
    VMFilePtr	    file = (VMFilePtr)vmHandle;

    file->blkHdr->VMH_attributes &= ~reset;
    file->blkHdr->VMH_attributes |= set;
}


/***********************************************************************
 *				VMSetLMemFlag
 ***********************************************************************
 * SYNOPSIS:	    This is a hack for Glue.
 * CALLED BY:	    Glue
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The VMBF_LMEM bit is set for the block
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/29/90		Initial Revision
 *
 ***********************************************************************/
void
VMSetLMemFlag(VMHandle	    	vmHandle,
	      VMBlockHandle 	vmBlock)
{
    VMBlock 	*block;

    block = VM_HANDLE_TO_BLOCK(vmBlock,((VMFilePtr)vmHandle)->blkHdr);
    assert(VM_IN_USE(block));
    block->VMB_flags |= VMBF_LMEM;
}


/***********************************************************************
 *				VMSetPreserveFlag
 ***********************************************************************
 * SYNOPSIS:	    This is another hack for Glue.
 * CALLED BY:	    Glue
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The VMBF_PRESERVE bit is set for the block
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/29/90		Initial Revision
 *
 ***********************************************************************/
void
VMSetPreserveFlag(VMHandle	    	vmHandle,
		  VMBlockHandle 	vmBlock)
{
    VMBlock 	*block;

    block = VM_HANDLE_TO_BLOCK(vmBlock,((VMFilePtr)vmHandle)->blkHdr);
    assert(VM_IN_USE(block));
    block->VMB_flags |= VMBF_PRESERVE;
}
