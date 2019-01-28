/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tool Utilities
 * FILE:	  mallocerr.c
 *
 * AUTHOR:  	  Adam de Boor: November 12, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	malloc_err	    Print an error from the malloc system w/o
 *			    using the malloc system.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/12	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Routine provided for tools that don't have any special screen
 *	requirements that preclude the writing of a malloc error message
 *	to stderr.
 *
 ***********************************************************************/

#include <config.h>
#include <compat/stdlib.h>
#include <compat/file.h>
#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif


/***********************************************************************
 *				malloc_err
 ***********************************************************************
 * SYNOPSIS:		Write an error message w/o using malloc
 * CALLED BY:		malloc and friends
 * RETURN:		if 'fatal' is non-zero, exits 1.
 * SIDE EFFECTS:	None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/12/89	Initial Revision
 *
 ***********************************************************************/
void
malloc_err(int fatal, char	*str, int len)
{
    write(2, str, len);
    if (fatal) {
	exit(1);
    }
}
