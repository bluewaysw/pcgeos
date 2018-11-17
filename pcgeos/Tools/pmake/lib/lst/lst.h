/*-
 * lst.h --
 *	Header for using the list library
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
 *
 * $Id: lst.h,v 1.2 92/07/27 12:21:55 jimmy Exp $ SPRITE (Berkeley)
 */
#ifndef _LST_H_
#define _LST_H_

#include	<sprite.h>

/*
 * basic typedef. This is what the Lst_ functions handle
 */

typedef	void	*Lst;
typedef	void	*LstNode;

#define	NILLST		((Lst) NIL)
#define	NILLNODE	((LstNode) NIL)

/*
 * NOFREE can be used as the freeProc to Lst_Destroy when the elements are
 *	not to be freed.
 * NOCOPY performs similarly when given as the copyProc to Lst_Duplicate.
 */
#define NOFREE		((void (*)()) 0)
#define NOCOPY		((ClientData (*)()) 0)

#define LST_CONCNEW	0   /* create new LstNode's when using Lst_Concat */
#define LST_CONCLINK	1   /* relink LstNode's when using Lst_Concat */

/*
 * Creation/destruction functions
 */
Lst		  Lst_Init(Boolean circ);   	/* Create a new list */
Lst	    	  Lst_Duplicate(Lst l, ClientData (*copyProc)());
	/* Duplicate an existing list */

void		  Lst_Destroy(Lst l, void (*freeProc)());
	/* Destroy an old one */

int	    	  Lst_Length(Lst l);   	/* Find the length of a list */
Boolean		  Lst_IsEmpty(Lst l);	/* True if list is empty */

/*
 * Functions to modify a list
 */
ReturnStatus	  Lst_Insert(Lst l, LstNode ln, ClientData d);
		/* Insert an element before another */

ReturnStatus	  Lst_Append(Lst l, LstNode ln, ClientData d);
		/* Insert an element after another */

ReturnStatus	  Lst_AtFront(Lst l, ClientData d);
	/* Place an element at the front of
					 * a lst. */
ReturnStatus	  Lst_AtEnd(Lst l, ClientData d);
		/* Place an element at the end of a lst. */

ReturnStatus	  Lst_Remove(Lst l, LstNode ln);/* Remove an element */

ReturnStatus	  Lst_Replace(register LstNode ln, ClientData d);
		/* Replace a node with a new value */

ReturnStatus	  Lst_Move(Lst ls, register LstNode lns, Lst ld,
			   register LstNode lnd, Boolean before);
		/* Move an element to another place */

ReturnStatus	  Lst_Concat(Lst l1, Lst l2, int flags);
		/* Concatenate two lists */

/*
 * Node-specific functions
 */
LstNode		  Lst_First(Lst l);	    	/* Return first element in list */
LstNode		  Lst_Last(Lst l);	    	/* Return last element in list */
LstNode		  Lst_Succ(Lst l);	    	/* Return successor to given element */
LstNode		  Lst_Pred(Lst l);	    	/* Return predecessor to given
					 * element */
ClientData	  Lst_Datum(Lst l);	    	/* Get datum from LstNode */

/*
 * Functions for entire lists
 */
LstNode		  Lst_Find(Lst l, ClientData d, int (*cProc)());
		/* Find an element in a list */

LstNode		  Lst_FindFrom(Lst l, register LstNode ln,
			       register ClientData d, register int (*cProc)());
		/* Find an element starting from somewhere */

LstNode	    	  Lst_Member(Lst l, ClientData d);
		/* See if the given datum is on the
		 * list. Returns the LstNode containing
		 * the datum */

int	    	  Lst_Index(Lst l, ClientData d);
		/* Returns the index of a datum in the
		 * list, starting from 0 */

void		  Lst_ForEach(Lst l, register int (*proc)(), register ClientData d);
	/* Apply a function to all elements of
					 * a lst */
void	    	  Lst_ForEachFrom(Lst l, LstNode ln,
			register int (*proc)(), register ClientData d);
			/* Apply a function to all elements of
			 * a lst starting from a certain point.
			 * If the list is circular, the
			 * application will wrap around to the
			 * beginning of the list again. */
/*
 * these functions are for dealing with a list as a table, of sorts.
 * An idea of the "current element" is kept and used by all the functions
 * between Lst_Open() and Lst_Close().
 */
ReturnStatus	  Lst_Open(register Lst l);    	/* Open the list */
LstNode		  Lst_Prev(Lst l);	    	/* Previous element */
LstNode		  Lst_Cur(Lst l);	    	/* The current element, please */
LstNode		  Lst_Next(Lst l);	    	/* Next element please */
Boolean		  Lst_IsAtEnd(Lst l);	/* Done yet? */
void		  Lst_Close(Lst l);	    	/* Finish table access */

/*
 * for using the list as a queue
 */
ReturnStatus	  Lst_EnQueue(Lst l, ClientData d);
	/* Place an element at tail of queue */
ClientData	  Lst_DeQueue(Lst l);
	/* Remove an element from head of
					 * queue */

#endif _LST_H_
