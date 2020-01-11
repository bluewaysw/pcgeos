/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stEnterNoLen.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  7, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 7/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Enter a null-terminated string into the table
 *
 ***********************************************************************/

#include <config.h>
#include <compat/string.h>
#include "stInt.h"


/***********************************************************************
 *				ST_EnterNoLen
 ***********************************************************************
 * SYNOPSIS:	    Enter a null-terminated string
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The ID for the string
 * SIDE EFFECTS:    None here.
 *
 * STRATEGY:	    Just calls ST_Enter and strlen
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 7/89		Initial Revision
 *
 ***********************************************************************/
ID
ST_EnterNoLen(VMHandle	    vmHandle,
	      VMBlockHandle table,
	      char  	    *name)
{
    return ST_Enter(vmHandle, table, name, strlen(name));
}
