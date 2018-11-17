/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  queue.c
 * FILE:	  queue.c
 *
 * AUTHOR:  	  Adam de Boor: Apr 19, 1991
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/19/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	queue manipulation routines missing from non-Unix
 *
 ***********************************************************************/

#include <config.h>

#ifndef HAVE_QUEUE

#ifndef lint
static char *rcsid =
"$Id: queue.c,v 1.1 91/04/26 11:54:55 adam Exp $";
#endif lint

#include <compat/queue.h>

void
insque(struct qelem *elem, struct qelem *pred)
{
    elem->q_forw = pred->q_forw;
    pred->q_forw = elem;
    elem->q_forw->q_back = elem;
    elem->q_back = pred;
}

void
remque(struct qelem *elem)
{
    elem->q_forw->q_back = elem->q_back;
    elem->q_back->q_forw = elem->q_forw;
}

#endif /* !HAVE_QUEUE */
