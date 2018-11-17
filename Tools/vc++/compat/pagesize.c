/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Tools
MODULE:		Unix compatibility library
FILE:		getpagesize.c

AUTHOR:		Jacob A. Gabrielson, May 24, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	5/24/96   	Initial version.

DESCRIPTION:
	This one's pretty obvious.

	$Id: pagesize.c,v 1.1 1996/08/07 04:53:55 ron Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>		/* always include at top */

#ifndef HAVE_GETPAGESIZE

#if !defined(lint)
static char rcsid[] = 
"$Id";
#endif 

#include <assert.h>

#ifdef _WIN32

#include <compat/windows.h>


/***********************************************************************
 *				getpagesize
 ***********************************************************************
 * SYNOPSIS:	    Gets the size of system virtual pages.
 * CALLED BY:	    GLOBAL
 * RETURN:	    int
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/24/96   	Initial Revision
 *
 ***********************************************************************/
int 
getpagesize(void)
{
    static int pagesize = 0;	/* if this is zero, we haven't been 
				   called yet */
    SYSTEM_INFO systemInfo;

    if (pagesize == 0) {
	GetSystemInfo(&systemInfo);
	pagesize = (int) systemInfo.dwPageSize;
    }

    return pagesize;
}	/* End of getpagesize.	*/

#endif /* _WIN32 */

#endif /* !HAVE_GETPAGESIZE */
