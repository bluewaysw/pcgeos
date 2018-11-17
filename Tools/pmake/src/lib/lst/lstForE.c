/*-
 * LstForeach.c --
 *	Perform a given function on all elements of a list.
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
"$Id: lstForE.c,v 1.2 96/06/24 15:00:22 tbradley Exp $ SPRITE (Berkeley)";
#endif lint

#include	"lstInt.h"

/*-
 *-----------------------------------------------------------------------
 * Lst_ForEach --
 *	Apply the given function to each element of the given list. The
 *	function should return 0 if Lst_ForEach should continue and non-
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
Lst_ForEach (Lst	         l,
	     register int      (*proc)(),
	     register ClientData d)
{
    Lst_ForEachFrom(l, Lst_First(l), proc, d);
}

