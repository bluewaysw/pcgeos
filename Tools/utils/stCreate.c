/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stCreate.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  4, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 4/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Create a string table in a VM file
 *
 ***********************************************************************/
#include <config.h>
#include "stInt.h"


/***********************************************************************
 *				ST_Create
 ***********************************************************************
 * SYNOPSIS:	    Create and initialize a string table in a VM file
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The VMBlockHandle of the header.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 4/89		Initial Revision
 *
 ***********************************************************************/
VMBlockHandle
ST_Create(VMHandle  vmHandle)	    /* File in which to create the table */
{
    VMBlockHandle   vmBlock;

    /*
     * Allocate a block with enough room to hold the header.
     * VMAlloc will cause the memory to be zero-initialized, so everything's
     * all set.
     */
    vmBlock = VMAlloc(vmHandle, sizeof(STHeader), ST_HEADER_ID);

    return(vmBlock);
}
