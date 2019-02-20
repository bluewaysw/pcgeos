/*
 *    			RCS Control Information:
 *    $Author: adam $				
 *    $Date: 91/03/22 01:18:37 $
 *
 *    $Revision: 1.1 $		
 *    $Source: /staff/pcgeos/Tools/swat/hist/RCS/higetline.c,v $
 *    $State: Exp $
 */
#include "hidefs.h"
#include "hist.h"
#include "hiextern.h"

/*
 *    The purpose of thiS function is to get a line, and keep getting
 *    stuff if there is a '\\' before a '\n'.  Size bounds are respected.
 */
hiGetLine(space, size, fptr)
char *space;
int size;
FILE *fptr;
{
	register int c,
		     len = 0,		/* length of the current line	*/
		     skip = FALSE;	/* skip char '\\'		*/

	/*
	 *    While not EOF, and not (skipping, and newline)
	 */
	while (++len<size && (c = getc(fptr)) != EOF && (skip || c != '\n')) {
	    *space++ = c;
	    skip = !skip && (c == '\\');
	}
	if ( c == '\n' ){
		*space++ = c;
	}
	*space = '\0';
	if (c == EOF)
	    return (hiErrno = HI_EOF);
	else if (len == size)
	    return (hiErrno = HI_TOOLONG);
	return (hiErrno = HI_NOERROR);
}
