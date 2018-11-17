/*-
 * LstAppend.c --
 *	Add a new node with a new datum after an existing node
 *
 * Copyright (c) 1988 by University of California Regents
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright    
 * fee is hereby granted, provided that the above copyright
 * notice appears in all copies.  Neither the University of California nor
 * Adam de Boor makes any representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 */
#ifndef lint
static char *rcsid =
"$Id: lstAppnd.c,v 1.2 96/06/24 14:57:50 tbradley Exp $ SPRITE (Berkeley)";
#endif lint

#include	"lstInt.h"


/*-
 *-----------------------------------------------------------------------
 * Lst_Append --
 *	Create a new node and add it to the given list after the given node.
 *
 * Results:
 *	SUCCESS if all went well.
 *
 * Side Effects:
 *	A new ListNode is created and linked in to the List. The lastPtr
 *	field of the List will be altered if ln is the last node in the
 *	list. lastPtr and firstPtr will alter if the list was empty and
 *	ln was NILLNODE.
 *
 *-----------------------------------------------------------------------
 */
ReturnStatus
Lst_Append (Lst	  	l,	/* affected list */
	    LstNode	ln,	/* node after which to append the datum */
	    ClientData	d)	/* said datum */
{
    register List 	list;
    register ListNode	lNode;
    register ListNode	nLNode;
    
    if (LstValid (l) && (ln == NILLNODE && LstIsEmpty (l))) {
	goto ok;
    }
    
    if (!LstValid (l) || LstIsEmpty (l)  || ! LstNodeValid (ln, l)) {
	return (FAILURE);
    }
    ok:
    
    list = (List)l;
    lNode = (ListNode)ln;

    PAlloc (nLNode, ListNode);
    nLNode->datum = d;
    nLNode->useCount = nLNode->flags = 0;
    
    if (lNode == NilListNode) {
	if (list->isCirc) {
	    nLNode->nextPtr = nLNode->prevPtr = nLNode;
	} else {
	    nLNode->nextPtr = nLNode->prevPtr = NilListNode;
	}
	list->firstPtr = list->lastPtr = nLNode;
    } else {
	nLNode->prevPtr = lNode;
	nLNode->nextPtr = lNode->nextPtr;
	
	lNode->nextPtr = nLNode;
	if (nLNode->nextPtr != NilListNode) {
	    nLNode->nextPtr->prevPtr = nLNode;
	}
	
	if (lNode == list->lastPtr) {
	    list->lastPtr = nLNode;
	}
    }
    
    return (SUCCESS);
}

