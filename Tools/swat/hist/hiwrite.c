/*
 *    			RCS Control Information:
 *    $Author: adam $				
 *    $Date: 91/03/22 01:19:19 $
 *
 *    $Revision: 1.1 $		
 *    $Source: /staff/pcgeos/Tools/swat/hist/RCS/hiwrite.c,v $
 *    $State: Exp $
 */
#include "hidefs.h"
#include "hist.h"
#include "hiextern.h"

/*
 *    The purpose of this function is to write argv[start - (stop-1)]
 *    out to the space being sure that the space is not overrun.
 *    The number of chars actually written out are returned.
 */
hiWrite(space, size, start, stop, hi, esc)
char *space;
int size;		/* not more than size chars available	*/
int start;		/* start at argv[start]	(prev errorcked)*/
int stop;		/* stop at argv[stop] (prev errorcked)	*/
HIST *hi;		/* current history line			*/
char esc;		/* current escape character		*/
{
	register char *word;		/* ptr to an argv[i]		*/
	register int i,
		     len = 0;		/* have written len chars	*/

	for ( i=start; i<stop && len<size; i++) {
	    word = hi->argv[i];
	    if (hi->argq[i] && len < size)	/* get the quotes	*/
		*space++ = hi->argq[i], len++;
	    while (*word && len < size) {
		/*
		 *    Handle specials which need to be re-escaped.
		 *    If there is enough room that is, handle normally.
		 */
		if (esc && (*word == esc || isspace(*word)) && len+1 < size) 
		    *space++ = esc, *space++ = *word++, len += 2;
		else
		    *space++ = *word++, len++;
	    }
	    if (hi->argq[i] && len < size)	/* get the quotes	*/
		*space++ = hi->argq[i], len++;	
	    if (i+1 < stop)			/* add that space	*/
		*space++ = ' ', len++;
	}
	return (len);
}
