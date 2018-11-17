/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- String Table Handling
 * FILE:	  stReloc.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  7, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 7/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Byte-swapping for string-table blocks.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: stReloc.c,v 1.7 92/06/22 15:19:10 jimmy Exp $";
#endif lint

#include <config.h>
#include "stInt.h"


/***********************************************************************
 *				ST_Reloc
 ***********************************************************************
 * SYNOPSIS:	    "Relocate" a string-table block, byteswapping
 *	    	    all necessary fields.
 * CALLED BY:	    User of library
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *	A header block is made exclusively of shortwords, so we can
 *	just treat it as an array of same and swap them all.
 *
 *	A chain block, however, consists of chain records interspersed with
 *	string data. We need to actually travel down the block and
 *	swap only the binary parts.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 7/89		Initial Revision
 *
 ***********************************************************************/
void
ST_Reloc(VMHandle 	vmHandle,   	/* File from which block came */
	 VMBlockHandle	vmBlock,    	/* Handle of block */
	 VMID    	vmID,	    	/* ID of block (block type [ignored])*/
	 MemHandle	handle,	    	/* Memory handle of resident block */
	 genptr	    	block)	    	/* Base of block */
{
    byte    	*bp;
    word    	size;

    if (vmID == ST_HEADER_ID) {
	/*
	 * Fetch the size of the block so we know how many words to swap
	 */
	MemInfo(handle, (genptr *)NULL, &size);
	
	/*
	 * Should be a multiple of 2 bytes long...
	 */
	assert((size & 1) == 0);
	
	/*
	 * The bp[-1] here is due to the indeterminacy of something like
	 *	*++bp = *bp;
	 * We want to advance bp by 2 during each iteration, preferably using
	 * postincrement (that's a mode that might be supported by the
	 * machine), so we advance bp after fetching the first byte, then use
	 * bp[-1].
	 *
	 * An alternative might be:
	 *
	 * t = *bp; *bp = bp[1]; *++bp = t; bp++;
	 *
	 * but I think it's worse than the current one, no?
	 */
	for (bp = (byte *)block; size > 0; size -= 2) {
	    byte	t = *bp++;
	    bp[-1] = *bp;
	    *bp++ = t;
	}
    } else {
	/*
	 * First swap the STChainHdr.
	 */
	STChainPtr  stcp, end;
	
	size = sizeof(STChainHdr);
	for (bp = (byte *)block; size > 0; size -= 2) {
	    byte	t = *bp++;
	    bp[-1] = *bp;
	    *bp++ = t;
	}

	/*
	 * Now do the individual pieces. bp points to the first chain record
	 * and we can use the chain header to figure when to stop...
	 */
	end = ST_LAST_CP((STChainHdr *)block);
	stcp = (STChainPtr)bp;

	while (stcp < end) {
	    /*
	     * Swap the binary portions at the front -- all shortwords.
	     */
	    for (bp = (byte *)stcp, size = sizeof(STChainRec);
		 size > 0;
		 size -= 2)
	    {
		byte	t = *bp++;
		bp[-1] = *bp;
		*bp++ = t;
	    }

	    stcp = ST_NEXT_CP(stcp, stcp->length);
	}
    }
}
