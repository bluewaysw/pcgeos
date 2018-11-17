/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmSetReloc.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Change the relocation routine for a VM File
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vmSetRel.c,v 1.1 91/04/26 11:53:44 adam Exp $";
#endif lint

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMSetReloc
 ***********************************************************************
 * SYNOPSIS:	    Change the relocation routine for the file
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    file->reloc altered
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 2/89		Initial Revision
 *
 ***********************************************************************/
void
VMSetReloc(VMHandle 	    vmHandle,
	   VMRelocRoutine   *reloc)
{
    VMFilePtr	    file = (VMFilePtr)vmHandle;

    file->reloc = reloc;
}
