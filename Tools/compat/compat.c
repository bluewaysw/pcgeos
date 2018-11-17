/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS Tools
MODULE:		Unix Compatiblity Library
FILE:		compat.c

AUTHOR:		Jacob A. Gabrielson, Feb 06, 1997

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jacob   	2/06/97   	Initial version

DESCRIPTION:
	Various useful routines for doing stuff (mostly file-related)
	under all platforms.
	

	$Id: compat.c,v 1.2 1997/02/20 07:20:37 jacob Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>
#include <compat/file.h>
#include <compat/string.h>
#include <ctype.h>
#include <stdio.h>

#if defined(_WIN32)
/*
 * Case-insensitive paths under NT (sigh!)
 */
#define FIND_PATH_SUBSTRING strstri
#else
#define FIND_PATH_SUBSTRING strstr
#endif


/***********************************************************************
 *				strstri
 ***********************************************************************
 *
 * SYNOPSIS:	     See if a string contains a particular substring
 *                   using case-insensitive matching
 * CALLED BY:	     (GLOBAL)
 * RETURN:	     If string contains a case-insensitive version of
 *                   substring, the return value is the location of the
 *                   first matching instance of substring in string.
 *                   Otherwise the return value is NULL.  Matching is
 *                   done without wildcards or special characters.
 * SIDE EFFECTS:     None.
 *
 * STRATEGY:	     Search the string for a single character match and
 *                   if one is found, see if it's the beginning of the
 *                   substring.  If it's not the beginning of the
 *                   substring, reset the pointer to the beginning of the
 *                   substring and start over.
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	9/17/96   	Initial Revision
 *
 ***********************************************************************/
char *
strstri (char *string, char *substring)
{
    char *sptr = string;

    /* either string isn't valid */
    if (string == NULL || substring == NULL) {
	return NULL;
    }

    do {
	if (toupper(*sptr) == toupper(*substring)) {
	    return ((strnicmp(sptr, substring, strlen(substring)) == 0) 
		    ? sptr 
		    : strstri(sptr + 1, substring));
	}
	sptr++;
    } while (*sptr != '\0');

    return NULL;
}	/* End of strstri.	*/


/***********************************************************************
 *		Compat_CanonicalizeFilename
 ***********************************************************************
 *
 * SYNOPSIS:	Destructively change all backslashes to forward slashes.
 * CALLED BY:	(GLOBAL)
 * RETURN:	void
 *	
 * STRATEGY:	
 *	
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	jacob   	2/06/97   	Initial Revision
 *	
 ***********************************************************************/
void
Compat_CanonicalizeFilename (char *path)
{
#ifndef unix
    if (path != NULL) {
	while (*path != '\0') {
	    if (*path == '\\') {
		*path = '/';
	    }
	    path++;
	} 
    }
#endif
}	/* End of Compat_CanonicalizeFilename.	*/



/***********************************************************************
 *				Compat_LastPathSep
 ***********************************************************************
 *
 * SYNOPSIS:	        Finds the last path separator in a string.
 *			Use instead of rindex() or strrchr().
 * CALLED BY:	        (GLOBAL)
 * RETURN:	        Pointer into path where last path separator is.
 * SIDE EFFECTS:        none
 *
 * STRATEGY:	        (Win32) First find the last slash, then find the last
 *                      backslash and see which one comes after the
 *                      other.  
 * 
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	9/18/96   	Initial Revision
 *
 ***********************************************************************/
char *
Compat_LastPathSep (char *path)
{
    char *lastSlash;
    char *lastBackSlash;
    
    lastSlash     = strrchr(path, '/');
    lastBackSlash = strrchr(path, '\\');
    
    if (lastSlash == NULL) {
	return lastBackSlash;
    } else if (lastBackSlash == NULL) {
	return lastSlash;
    } else {
	return (lastSlash > lastBackSlash) ? lastSlash : lastBackSlash;
    }
}	/* End of Compat_LastPathSep.	*/


/***********************************************************************
 *				Compat_FirstPathSep
 ***********************************************************************
 *
 * SYNOPSIS:	        Finds the first path separator in a string.
 *			Use instead of index() or strchr().
 * CALLED BY:	        (GLOBAL)
 * RETURN:	        Pointer into path where first path separator is.
 * SIDE EFFECTS:        none
 *
 * STRATEGY:	        (Win32) First find the first slash, then find the first
 *                      backslash and see which one comes after the
 *                      other.  
 * 
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	9/18/96   	Initial Revision
 *
 ***********************************************************************/
char *
Compat_FirstPathSep (char *path)
{
    char *firstSlash;
    char *firstBackSlash;
    
    firstSlash     = strchr(path, '/');
    firstBackSlash = strchr(path, '\\');
    
    if (firstSlash == NULL) {
	return firstBackSlash;
    } else if (firstBackSlash == NULL) {
	return firstSlash;
    } else {
	return (firstSlash < firstBackSlash) ? firstSlash : firstBackSlash;
    }
}	/* End of Compat_FirstPathSep.	*/


/***********************************************************************
 *				Compat_GetCwd
 ***********************************************************************
 *
 * SYNOPSIS:	      Wrapper for getcwd which also converts \'s in the
 *                    path to /'s.  You should always use this
 *		      instead of getcwd()
 * CALLED BY:	      (GLOBAL)
 * RETURN:	      The CWD as returned by getcwd()
 * SIDE EFFECTS:
 *              
 *
 * STRATEGY:	 
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	11/16/96   	Initial Revision
 *
 ***********************************************************************/
char *
Compat_GetCwd (char *cwd, int maxLength)
{
#ifdef unix
    return getcwd(cwd, maxLength);
#else
    if (getcwd(cwd, maxLength) != NULL) {
	Compat_CanonicalizeFilename(cwd);
    }

    return cwd;
#endif
}	/* End of Compat_GetCwd.	*/


/***********************************************************************
 *				Compat_GetTrailingPath
 ***********************************************************************
 *
 * SYNOPSIS:	      Returns everything in path after component
 * CALLED BY:	      (GLOBAL)
 * RETURN:	      a pointer into path after the appearance of component
 * SIDE EFFECTS:      NONE
 *
 * STRATEGY:	      Call strstr to find component, then return everything
 *                    after the 2nd path separator after that.
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	11/16/96   	Initial Revision
 *
 ***********************************************************************/
char *
Compat_GetTrailingPath (char *component, char *path)
{
    char *position = FIND_PATH_SUBSTRING(path, component);

    if (position != NULL) {
	char *afterPosition = 
	    Compat_FirstPathSep(Compat_FirstPathSep(position + 1) + 1);
       
	return (afterPosition == NULL) ? position : afterPosition + 1;
    }

    return NULL;
}	/* End of Compat_GetTrailingPath.	*/


/***********************************************************************
 *				Compat_GetNextComponent
 ***********************************************************************
 *
 * SYNOPSIS:	        Finds the next component in path after 
 *			passed component
 * CALLED BY:	        (GLOBAL)
 * RETURN:	        A new string containing the next component
 * SIDE EFFECTS:        memory is malloc'ed
 *
 * STRATEGY:	        call strstr to find the first occurence of component
 *                      in path.  copy everything up to the next path sep 
 *                      or '\0' to a new string.
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	1/14/97   	Initial Revision
 *
 ***********************************************************************/

#ifndef MAX_PATH
#define MAX_PATH (256)
#endif

char * 
Compat_GetNextComponent (char *component, char *path)
{
   char *cp = FIND_PATH_SUBSTRING(path, component);
   
   if (cp != NULL) {
       char *nextComp = (char *) malloc (MAX_PATH * sizeof(char)); /* #1 */

       if (IS_PATHSEP(*cp)) {
	   cp++;
       }

       /*
	* Skip to the next path sep.
	*/
       if ((cp = Compat_FirstPathSep(cp)) != NULL) {
	   int i = 0;

	   cp++;  /* skip path sep */
	   while ((*cp != '\0') && !IS_PATHSEP(*cp) && (i < MAX_PATH - 1)) {
	       nextComp[i] = *cp++;
	       i++;
	   }
	   nextComp[i] = '\0';
	   return nextComp;
       }
       
       free(nextComp);		/* #1 */
   }

   return NULL;
}	/* End of Compat_GetNextComponent.	*/



/***********************************************************************
 *				Compat_GetPathTail
 ***********************************************************************
 *
 * SYNOPSIS:	      Returns the final component of path
 * CALLED BY:	      (GLOBAL)
 * RETURN:	      Pointer into last element of path
 * SIDE EFFECTS:     
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	tbradley	11/16/96   	Initial Revision
 *
 ***********************************************************************/
char *
Compat_GetPathTail(char *path)
{
    char *lastSlash = Compat_LastPathSep(path);

    /*
     * If we were passed something like "/staff/pcgeos/" instead
     * of "/staff/pcgeos", we want to return "pcgeos", not "".
     */
    if (lastSlash != NULL && lastSlash[1] == '\0') {
	char *mungePath = strdup(path);	/* #1 */
	
	mungePath[strlen(mungePath) - 1] = '\0'; /* nuke final slash */
	lastSlash = Compat_LastPathSep(mungePath);
	free(mungePath);	/* #1 */
    }


    return (lastSlash != NULL) ? lastSlash : path;
}	/* End of Compat_GetPathTail */
