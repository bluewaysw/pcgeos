/* list.c -
 *
 * This file contains procedures for manipulating lists.
 * Structures may be inserted into or deleted from lists, and
 * they may be moved from one place in a list to another.
 *
 * The header file contains macros to help in determining the destination
 * locations for List_Insert and List_Move.  See list.h for details.
 *
 * Copyright (C) 1985 Regents of the University of California
 * All rights reserved.
 */
#include <config.h>

#ifndef lint
static char rcsid[] = "$Id: list.c,v 1.2 96/06/24 15:04:00 tbradley Exp $ SPRITE (Berkeley)";
#endif not lint

#include <compat/string.h>

#include "sprite.h"
#include "list.h"
#include "sys.h"


/*
 * ----------------------------------------------------------------------------
 *
 * List_Insert --
 *
 *	Insert the list element pointed to by itemPtr into a List after 
 *	destPtr.  Perform a primitive test for self-looping by returning
 *	failure if the list element is being inserted next to itself.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The list containing destPtr is modified to contain itemPtr.
 *
 * ----------------------------------------------------------------------------
 */
void
List_Insert(
    register	List_Links *itemPtr,	/* structure to insert */
    register	List_Links *destPtr)	/* structure after which to insert it */
{
    if (itemPtr == (List_Links *) NIL || 
	destPtr == (List_Links *) NIL ||
       ((unsigned long)itemPtr == 0) || 
       ((unsigned long)destPtr == 0) ||
       ((unsigned long)itemPtr == (unsigned long)destPtr)) {
	Sys_Panic(SYS_FATAL,
		  "List_Insert: inserting this item would create a loop.\n");
	return;
    }
    itemPtr->nextPtr = destPtr->nextPtr;
    itemPtr->prevPtr = destPtr;
    destPtr->nextPtr->prevPtr = itemPtr;
    destPtr->nextPtr = itemPtr;
}


/*
 * ----------------------------------------------------------------------------
 *
 * List_Remove --
 *
 *	Remove a list element from the list in which it is contained.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The given structure is removed from its containing list.
 *
 * ----------------------------------------------------------------------------
 */
void
List_Remove(register List_Links *itemPtr)	/* list element to remove */
{
    if (itemPtr == (List_Links *) NIL || itemPtr == itemPtr->nextPtr
	    || !itemPtr) {
	Sys_Panic(SYS_FATAL, "List_Remove: invalid item to remove.\n");
    }
    itemPtr->prevPtr->nextPtr = itemPtr->nextPtr;
    itemPtr->nextPtr->prevPtr = itemPtr->prevPtr;
}


/*
 * ----------------------------------------------------------------------------
 *
 * List_Move --
 *
 *	Move the list element referenced by itemPtr to follow destPtr.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	List ordering is modified.
 *
 * ----------------------------------------------------------------------------
 */
void
List_Move(
    register List_Links *itemPtr, /* list element to be moved */
    register List_Links *destPtr) /* element after which it is to be placed */
{

    if (itemPtr == (List_Links *) NIL || destPtr == (List_Links *) NIL
	    || !itemPtr || !destPtr) {
	Sys_Panic(SYS_FATAL, "List_Move: One of the list items is NIL.\n");
    }
    /*
     * It is conceivable that someone will try to move a list element to
     * be after itself.
     */
    if (itemPtr != destPtr) {
	List_Remove(itemPtr);
	List_Insert(itemPtr, destPtr);
    }    
}


/*
 * ----------------------------------------------------------------------------
 *
 * List_Init --
 *
 *	Initialize a header pointer to point to an empty list.  The List_Links
 *	structure must already be allocated.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The header's pointers are modified to point to itself.
 *
 * ----------------------------------------------------------------------------
 */
void
List_Init(register List_Links *headerPtr) /* Pointer to a List_Links structure 
					     to be header */
{
    if (headerPtr == (List_Links *) NIL || !headerPtr) {
	Sys_Panic(SYS_FATAL, "List_Init: invalid header pointer.\n");
    }
    headerPtr->nextPtr = headerPtr;
    headerPtr->prevPtr = headerPtr;
}
