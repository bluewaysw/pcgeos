/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  mkstemp.c
 *
 * AUTHOR:  	  Adam de Boor: April 18, 1991
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	mkstemp		    open a temporary file with a unique name
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/18/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	
 *
 ***********************************************************************/

#include <config.h>
#include <compat/file.h>

#ifndef HAVE_MKSTEMP

#ifndef lint
static char *rcsid =
"$Id$";
#endif lint

#include    <fcntl.h>
#include    <io.h>

#ifdef _MSDOS
#include    <dos.h>
#endif

#ifdef __BORLANDC__
#include    <sys/stat.h>	/* for S_ constants */
#endif

#ifdef __HIGHC__
#define mktemp _mktemp
#endif


/***********************************************************************
 *				mkstemp
 ***********************************************************************
 * SYNOPSIS:	create a temporary file with a unique name, returning
 *		its open file handle.
 * CALLED BY:	GLOBAL
 * RETURN:	the file handle, and the template modified to hold the
 *		file name.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/18/91		Initial Revision
 *
 ***********************************************************************/
int
mkstemp(char *template)
{
    if (mktemp(template) != 0) {
	return open(template, O_CREAT | O_RDWR, S_IREAD | S_IWRITE);
    } else {
	return -1;
    }
}

#endif /* !HAVE_MKSTEMP */
