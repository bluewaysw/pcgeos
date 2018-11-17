/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  dir.c
 * FILE:	  dir.c
 *
 * AUTHOR:  	  Adam de Boor: Jul  8, 1992
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	opendir	    	    Begin reading a directory.
 *	readdir	    	    Read the next entry in a directory
 *	rewinddir   	    Start over
 *	closedir    	    Finish reading a directory.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/ 8/92	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Implementation of the UNIX directory-access set of functions.
 *
 ***********************************************************************/

#include <config.h>

#ifndef HAVE_DIRENT

#  ifndef lint
static char *rcsid =
"$Id: dir.c,v 1.1 92/07/09 21:56:10 adam Exp $";
#  endif lint

#  if defined(_MSC_VER) && defined(_WIN32)

/*************************************************************************
 *                                                                       *
 *                         MSC implementation                            *
 *                                                                       *
 *************************************************************************/

#    define WIN32_LEAN_AND_MEAN
#    include <windows.h>
#    include "winutil.h"
#    include <compat/string.h>
#    include <compat/dirent.h>
#    include <stdlib.h>
#    include <stdio.h>

typedef struct _Dir {
    HANDLE           hFile;
    WIN32_FIND_DATA  win32FindData;
    int              index;
    char             pattern[MAX_PATH + 3];
    struct direct    d;
} Dir;

/***********************************************************************
 *		opendir
 ***********************************************************************
 *
 * SYNOPSIS:	       "open" a directory for reading
 * CALLED BY:	       external
 * RETURN:	       a Dir * if success, NULL if failure
 *	
 * STRATEGY:	       call FindFirstFile with a pattern of path\\*
 *                     and set index to 0 so that when
 *                     readdir is called it will still return the first
 *                     file (readdir calls FindNextFile).
 *	
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	tbradley	3/17/97   	Initial Revision
 *	
 ***********************************************************************/
DIR *
opendir (const char *path)
{
    /* we allocate strlen(path) + 3 because we need room for the \\*\0 */
    Dir  *dir     = (Dir *) malloc(sizeof(Dir));

    sprintf(dir->pattern, "%s\\*", path);

    dir->index    = 0;

    return (DIR *) dir;
}	/* End of opendir.	*/

/***********************************************************************
 *		readdir
 ***********************************************************************
 *
 * SYNOPSIS:	        returns the next file in a directory
 * CALLED BY:	        external
 * RETURN:	        a struct direct * on success, NULL on failure
 *	
 * STRATEGY:	        if the user wants the first file, then just use
 *                      the data gleaned from opendir, otherwise call
 *                      FindNextFile
 *	
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	tbradley	3/17/97   	Initial Revision
 *	
 ***********************************************************************/
const struct direct *
readdir (DIR *dirP)
{
    Dir *dp = (Dir *) dirP;

    /*
     * not the first file
     */
    if (dp->index == 0) {
	if ((dp->hFile = FindFirstFile(dp->pattern, &(dp->win32FindData))) ==
	    INVALID_HANDLE_VALUE) {
	    return NULL;
	}
    } else if (!FindNextFile(dp->hFile, &(dp->win32FindData))) {
	/*
	 * FindNextFile failed
	 */
	return(NULL);
    }

    dp->index++;
    dp->d.d_fileno = dp->index;
    dp->d.d_namlen = strlen(dp->win32FindData.cFileName);
    dp->d.d_reclen = sizeof(dp->d) - sizeof(dp->d.d_name) + dp->d.d_namlen + 1;
    strcpy(dp->d.d_name, dp->win32FindData.cFileName);

    return &(dp->d);
}	/* End of readdir.	*/

/***********************************************************************
 *		rewinddir
 ***********************************************************************
 *
 * SYNOPSIS:	        "rewinds" the Dir structure
 * CALLED BY:	        external
 * RETURN:	        nothing
 *	
 * STRATEGY:	        call FindFirstFile again and set the index back
 *                      to 0
 *	
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	tbradley	3/17/97   	Initial Revision
 *	
 ***********************************************************************/
void
rewinddir (DIR *dirP)
{
    Dir *dp = (Dir *) dirP;

    (void) FindClose(dp->hFile);
    dp->index = 0;
}	/* End of rewinddir.	*/


/***********************************************************************
 *		closedir
 ***********************************************************************
 *
 * SYNOPSIS:	        return resources which were allocated for dir stuff
 * CALLED BY:	        external
 * RETURN:	        0 on success, nonzero on failure
 *	
 * STRATEGY:	        call FindClose and free the dir structure
 *	
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	tbradley	3/17/97   	Initial Revision
 *	
 ***********************************************************************/
int
closedir (DIR *dirP)
{
    Dir   *dp    = (Dir *) dirP;
    DWORD  error = 0;
    
    if (!FindClose(dp->hFile)) {
	error = GetLastError();
    }

    (void) free(dp);

    return error;
}	/* End of closedir.	*/


#  elif defined(_MSDOS)

/*************************************************************************
 *                                                                       *
 *                     Non MSC implementation                            *
 *                                                                       *
 *************************************************************************/

#    include    <compat/dirent.h>
#    include    <dos.h>
#    include    <malloc.h>
#    include    <string.h>

typedef struct _Dir {
    char    	    *path;  	    /* Directory being scanned */
    struct find_t   dta;    	    /* Buffer for the next file found */
    int	    	    index;  	    /* Index of last thing found. 0 =>
				     * nothing found yet */
    struct direct   d;	    	    /* Structure returned by previous
				     * readdir() */
} Dir;


/***********************************************************************
 *				opendir
 ***********************************************************************
 * SYNOPSIS:	    "open" a directory for reading
 * CALLED BY:	    GLOBAL
 * RETURN:	    DIR *, or NULL if couldn't open it
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 9/92		Initial Revision
 *
 ***********************************************************************/
DIR *
opendir(const char *path)
{
    Dir	    *dp;
    char    *cp;

    /*
     * Allocate room for our state variables, including the path.
     */
    dp = (Dir *)malloc(sizeof(Dir) + strlen(path) + 4 + 1);
    if (dp == 0) {
	return((DIR *)0);
    }

    /*
     * Copy the path in, transforming forward slashes into backward ones for
     * DOS.
     */
    dp->path = (char *)(dp+1);
    for (cp = dp->path; *path != '\0'; path++) {
	if (*path == '/') {
	    *cp++ = '\\';
	} else {
	    *cp++ = *path;
	}
    }
    /*
     * Append the pattern we'll need for the _dos_findfirst: we want to find
     * everything.
     */
    strcpy(cp, "\\*.*");
	

    dp->index = 0;

    /* XXX: SEE IF THE PATH ACTUALLY EXISTS? */
    return ((DIR *)dp);
}


/***********************************************************************
 *				readdir
 ***********************************************************************
 * SYNOPSIS:	    Fetch the next entry from the directory.
 * CALLED BY:	    GLOBAL
 * RETURN:	    address of the next entry (static buffer), or 0 if
 *	    	    no more entries to return
 * SIDE EFFECTS:    previous entry returned is overwritten
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 9/92		Initial Revision
 *
 ***********************************************************************/
const struct direct *
readdir(DIR *dirp)
{
    Dir	    *dp = (Dir *)dirp;

    if (dp->index++ == 0) {
	if (_dos_findfirst(dp->path, _A_HIDDEN|_A_SYSTEM|_A_SUBDIR, &dp->dta)){
	    /*
	     * Error on findfirst, so return 0. Reset dp->index to 0 in case
	     * caller tries again...
	     */
	    dp->index = 0;
	    return ((struct direct *)0);
	}
    } else if (_dos_findnext(&dp->dta)) {
	/*
	 * Error on findnext, so return 0. Back up dp->index in case the guy
	 * tries again and a file's been added to the directory...
	 */
	dp->index -= 1;
	return((struct direct *)0);
    }

    dp->d.d_fileno = dp->index;
    dp->d.d_namlen = strlen(dp->dta.name);
    dp->d.d_reclen = sizeof(dp->d) - sizeof(dp->d.d_name) + dp->d.d_namlen + 1;
    strcpy(dp->d.d_name, dp->dta.name);

    return (&dp->d);
}


/***********************************************************************
 *				rewinddir
 ***********************************************************************
 * SYNOPSIS:	    Start searching the directory from the beginning.
 * CALLED BY:	    GLOBAL
 * RETURN:	    nothing
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 9/92		Initial Revision
 *
 ***********************************************************************/
void
rewinddir(DIR *dirp)
{
    Dir	*dp = (Dir *)dirp;

    /*
     * Tell readdir to do a _dos_findfirst again next time.
     */
    dp->index = 0;
}


/***********************************************************************
 *				closedir
 ***********************************************************************
 * SYNOPSIS:	    Shut down the reading of a directory.
 * CALLED BY:	    GLOBAL
 * RETURN:	    0 on success (always successful here...)
 * SIDE EFFECTS:    the descriptor allocated by opendir is freed and must
 *	    	    never be used again.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 9/92		Initial Revision
 *
 ***********************************************************************/
int
closedir(DIR *dirp)
{
    /*
     * Everything's in that one block o' memory, so we can just free the beast.
     */
    free(dirp);

    /*
     * Always successful.
     */
    return(0);
}

#  endif /* _MSC_VER && _WIN32 */

#endif /* !HAVE_DIRENT */
