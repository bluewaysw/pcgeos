/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stLookupNoLen.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  7, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 7/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Lookup a null-terminated string into the table
 *
 ***********************************************************************/

#include <config.h>
#include "stInt.h"

#include <compat/string.h>


/***********************************************************************
 *				ST_LookupNoLen
 ***********************************************************************
 * SYNOPSIS:	    Lookup a null-terminated string
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The ID for the string
 * SIDE EFFECTS:    None here.
 *
 * STRATEGY:	    Just calls ST_Lookup and strlen
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 7/89		Initial Revision
 *
 ***********************************************************************/
ID
ST_LookupNoLen(VMHandle	    	vmHandle,
	       VMBlockHandle	table,
	       const char    	*name)
{
    return ST_Lookup(vmHandle, table, name, strlen(name));
}
