/*
 *    			RCS Control Information:
 *    $Author: adam $				
 *    $Date: 91/03/22 01:18:52 $
 *
 *    $Revision: 1.1 $		
 *    $Source: /staff/pcgeos/Tools/swat/hist/RCS/hiputh.c,v $
 *    $State: Exp $
 */
#include "hidefs.h"
#include "hist.h"
#include "hiextern.h"

/*
 *    The purpose of thiS function is to put a buffer onto the tail of
 *    the history, and update the proper counts.
 */
hiPuth(buf, hq)
char *buf;
HIQUEUE *hq;
{
	register HIST *oldhq,		/* delete this guy	*/
		      *hrun,		/* run down the list	*/
		      *hi;
	register int i;

	if ((hi = (HIST *) malloc(sizeof (*hi))) == NULL) 
	    return (-1);
	hi->next = NULL;		/* be safe			*/
	if (hiSplit(hq, hi, buf) < 0)
	    return (-1);
	hq->count++;
	hq->line++;
	if (hq->head != NULL) {
	    hi->next = hq->head;
	    hq->head = hi;
	} else {
	    hq->head = hi;
	    hq->tail = hi;
	}
	if (hq->count > hq->max) {
	    hq->count--;
	    oldhq = hq->tail;		/* delete this guy	*/
	    if (hq->tail == hq->head)	/* handle last node	*/
		hq->head = NULL;
	    hiFree(oldhq);
	    for ( hrun = hq->head, i=0; i<hq->count-1; hrun = hrun->next, i++)
		;
	    hq->tail = hrun;
	    hq->tail->next = NULL;
	}
	return (0);
}
