/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmMapBlk.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	VMSetMapBlock	    Set the handle ID for the map block
 *	VMGetMapBlock	    Get the block handle for the map block
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for playing with the map block
 *
 ***********************************************************************/

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMSetMapBlock
 ***********************************************************************
 * SYNOPSIS:	    Record a block ID as the map block for a file.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    the VMH_mapBlock field is overwritten
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
VMSetMapBlock(VMHandle	    vmHandle,	    /* VM File */
	      VMBlockHandle vmBlock)	    /* Block to be map block */
{
    VMFilePtr	    file;   	    /* Internal representation of vmHandle */
    VMHeader	    *hdr;   	    /* Header block for vmHandle */
    VMBlock 	    *block; 	    /* Block being set as map block */

    file = (VMFilePtr)vmHandle;
    hdr = file->blkHdr;
    block = VM_HANDLE_TO_BLOCK(vmBlock, hdr);

    assert(VM_IN_USE(block));

    hdr->VMH_mapBlock = vmBlock;
}

/***********************************************************************
 *				VMGetMapBlock
 ***********************************************************************
 * SYNOPSIS:	    Retrieve the handle of the map block for the file
 * CALLED BY:	    EXTERNAL
 * RETURN:	    VMBlockHandle for map block
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/31/89		Initial Revision
 *
 ***********************************************************************/
VMBlockHandle
VMGetMapBlock(VMHandle	vmHandle)
{
    VMFilePtr	    file = (VMFilePtr)vmHandle;

    return(file->blkHdr->VMH_mapBlock);
}


/***********************************************************************
 *				VMSetDBMap
 ***********************************************************************
 * SYNOPSIS:	    Record a block ID as the map block for a file.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    the VMH_mapBlock field is overwritten
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
VMSetDBMap(VMHandle	    vmHandle,	    /* VM File */
	      VMBlockHandle vmBlock)	    /* Block to be map block */
{
    VMFilePtr	    file;   	    /* Internal representation of vmHandle */
    VMHeader	    *hdr;   	    /* Header block for vmHandle */
    VMBlock 	    *block; 	    /* Block being set as map block */

    file = (VMFilePtr)vmHandle;
    hdr = file->blkHdr;
    block = VM_HANDLE_TO_BLOCK(vmBlock, hdr);

    assert(VM_IN_USE(block));

    hdr->VMH_dbMapBlock = vmBlock;
}

/***********************************************************************
 *				VMGetDBMap
 ***********************************************************************
 * SYNOPSIS:	    Retrieve the handle of the map block for the file
 * CALLED BY:	    EXTERNAL
 * RETURN:	    VMBlockHandle for map block
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/31/89		Initial Revision
 *
 ***********************************************************************/
VMBlockHandle
VMGetDBMap(VMHandle	vmHandle)
{
    VMFilePtr	    file = (VMFilePtr)vmHandle;

    return(file->blkHdr->VMH_dbMapBlock);
}
