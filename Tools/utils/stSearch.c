/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stSearch.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  4, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 4/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Utility used to search a hash chain for a string.
 *
 ***********************************************************************/

#include <config.h>
#include <compat/string.h>
#include "stInt.h"


/***********************************************************************
 *				STSearch
 ***********************************************************************
 * SYNOPSIS:	    Search a hash chain for a string.
 * CALLED BY:	    ST_Enter and ST_Lookup (INTERNAL)
 * RETURN:	    The ID of the found thing, or NullID if not there.
 * SIDE EFFECTS:    If the ID is found, its STChainRec is shifted to
 *	    	    the front of its chain.
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
STSearch(VMHandle   	vmHandle,   	/* Handle of VM file */
	 STHeader    	*hdr,	    	/* Locked header */
	 int	    	bucket,	    	/* Bucket in which to search */
	 word	    	hashval,    	/* Hash value for the string */
	 const char 	*name,	    	/* String for which to search */
	 int	    	len)	    	/* Length of name */
{
    STChainPtr 	    stcp;   	/* Address of current entry */
    ID	    	    result; 	/* Result to return */
    STChainHdr	    *chdr;  	/* Base of chain block */
    STChainPtr	    end;    	/* End of search... */

    result = NullID;

    if (hdr->chains[bucket] != (VMBlockHandle)0) {
	chdr = (STChainHdr *)VMLock(vmHandle, hdr->chains[bucket],
				    (MemHandle *)NULL);
	
	/*
	 * Run through all the STChainRecs in the chain, looking for a match.
	 * The first entry in the chain follows immediately after chdr, with
	 * the last being chdr->offset bytes into the block.
	 */
	end = ST_LAST_CP(chdr);
	
	for (stcp = (STChainPtr)(chdr+1);
	     stcp < end;
	     stcp = ST_NEXT_CP(stcp,stcp->length))
	{
	    if ((stcp->hashval == hashval) && (stcp->length == len) &&
		memcmp(stcp->string, name, len) == 0)
	    {
		result = (ID)((hdr->chains[bucket] << 16) |
			      (stcp->string - (char *)chdr));
		break;
	    }
	}
	
	VMUnlock(vmHandle, hdr->chains[bucket]);
    }
    
    return(result);
}
