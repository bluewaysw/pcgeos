/*-
 * LstEnQueue.c--
 *	Treat the list as a queue and place a datum at its end
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
"$Id: lstEnQ.c,v 1.2 96/06/24 14:59:29 tbradley Exp $ SPRITE (Berkeley)";
#endif lint

#include	"lstInt.h"

/*-
 *-----------------------------------------------------------------------
 * Lst_EnQueue --
 *	Add the datum to the tail of the given list.
 *
 * Results:
 *	SUCCESS or FAILURE as returned by Lst_Append.
 *
 * Side Effects:
 *	the lastPtr field is altered all the time and the firstPtr field
 *	will be altered if the list used to be empty.
 *
 *-----------------------------------------------------------------------
 */
ReturnStatus
Lst_EnQueue (Lst    	  l,
	     ClientData	  d)
{
    if (LstValid (l) == FALSE) {
	return (FAILURE);
    }
    
    return (Lst_Append (l, Lst_Last(l), d));
}

