/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stIndex.c
 *
 * AUTHOR:  	  Adam de Boor: Aug 21, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/21/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Return the hash value for an identifier
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: stIndex.c,v 1.4 91/04/26 11:50:08 adam Exp $";
#endif lint

#include <config.h>
#include "stInt.h"
#include <stddef.h>


/***********************************************************************
 *				ST_Index
 ***********************************************************************
 * SYNOPSIS:	    Find the index (hash value) for a string
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The hash value for the ID
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	Lock the ID
 *	Arrange a pointer to an STChainRec so the string field matches
 *	    the address of the locked ID
 *	Fetch the hash value
 *	Unlock the ID
 *	return the hash value
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/21/89		Initial Revision
 *
 ***********************************************************************/
word
ST_Index(VMHandle   vmHandle,
	 ID 	    id)
{
    VMBlockHandle   block;
    void    	    *base;
    STChainPtr	    stcp;
    word    	    value;

    /*
     * Extract block handle from ID
     */
    block = id >> 16; 

    /*
     * Lock down the block in question
     */
    base = VMLock(vmHandle, block, (MemHandle *)NULL);

    /*
     * Point stcp at the proper place in the block (the ID contains the
     * offset of the string field of the record in its low 16 bits)
     */
    stcp = (STChainPtr)((char *)base +
			(id & 0xffff) -
			offsetof(STChainRec,string));

    /*
     * Fetch the value so we can unlock the block
     */
    value = stcp->hashval;

    VMUnlock(vmHandle, block);

    /*
     * Return the value fetched
     */
    return(value);
}
