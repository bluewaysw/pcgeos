/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stLookup.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  4, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 4/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Look up a string in a string table.
 *
 ***********************************************************************/
#include <config.h>
#include "stInt.h"


/***********************************************************************
 *				ST_Lookup
 ***********************************************************************
 * SYNOPSIS:	    Search for a string in a string table as for
 *	    	    ST_Enter, but if it's not there, just return
 *	    	    NullID; don't enter the string into the table.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    ID of string or NullID if not there
 * SIDE EFFECTS:    See STSearch
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 4/89		Initial Revision
 *
 ***********************************************************************/
ID
ST_Lookup(VMHandle   	vmHandle,   	/* File in which table resides */
	  VMBlockHandle	table,	    	/* Header block for table */
	  const char   	*name,	    	/* String to enter */
	  int	    	len)	    	/* Length of same */
{
    int	    	    bucket; 	/* Bucket in which to search */
    STHeader 	    *hdr;   	/* Address of header block */
    ID	    	    result; 	/* ID to return as result */
    word    	    hashval;	/* Actual hash value for the string */

    /*
     * Figure in which bucket the thing should reside.
     */
    bucket = STHash(name, len, &hashval);

    /*
     * Lock down the header. We don't need the handle of the header, as we're
     * not going to be doing any resizing.
     */
    hdr = (STHeader *)VMLock(vmHandle, table, (MemHandle *)NULL);

    /*
     * Take a stab at finding the thing.
     */
    result = STSearch(vmHandle, hdr, bucket, hashval, name, len);

    /*
     * Unlock the table and return whatever result we got.
     */
    VMUnlock(vmHandle, table);
    return(result);
}

