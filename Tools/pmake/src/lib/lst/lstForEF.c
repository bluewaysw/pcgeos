/*-
 * lstForEachFrom.c --
 *	Perform a given function on all elements of a list starting from
 *	a given point.
 *
 * Copyright (c) 1988 by University of California Regents
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appears in all copies.  Neither the University of California nor
 * Adam de Boor makes any representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 */
#ifndef lint
static char *rcsid =
"$Id: lstForEF.c,v 1.2 96/06/24 15:00:32 tbradley Exp $ SPRITE (Berkeley)";
#endif lint

#include <stdlib.h>

#include	"lstInt.h"

/*-
 *-----------------------------------------------------------------------
 * Lst_ForEachFrom --
 *	Apply the given function to each element of the given list. The
 *	function should return 0 if traversal should continue and non-
 *	zero if it should abort. 
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Only those created by the passed-in function.
 *
 *-----------------------------------------------------------------------
 */
/*VARARGS2*/
void
Lst_ForEachFrom (Lst	    	     l,
		 LstNode    	     ln,
		 register int	   (*proc)(),
		 register ClientData d)
{
    register ListNode	tln = (ListNode)ln;
    register List 	list = (List)l;
    register ListNode	next;
    Boolean 	    	done;
    int     	    	result;
    
    if (!LstValid (list) || LstIsEmpty (list)) {
	return;
    }
    
    do {
	/*
	 * Take care of having the current element deleted out from under
	 * us. Set "done" to indicate if we're currently on the last
	 * element of the list.
	 */
	next = tln->nextPtr;
	done = ((next == list->firstPtr) || (next == NilListNode));
	
	tln->useCount++;
	result = (*proc) (tln->datum, d);
	tln->useCount--;

	/*
	 * We're done with the traversal if
	 *  - nothing's been added after the current node and
	 *  - we were on the last node of the list before the callout.
	 */
	done = (next == tln->nextPtr && done);
	
	next = tln->nextPtr;

	if (tln->flags & LN_DELETED) {
	    free((char *)tln);
	}
	tln = next;
    } while (!result && !LstIsEmpty(list) && !done);
    
}

