/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS Tools
MODULE:		Win32 support library
FILE:		winutil.c

AUTHOR:		Jacob A. Gabrielson, Oct 28, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jacob	10/28/96   	Initial version

DESCRIPTION:
	A collection of useful Win32 utility routines.
	

	$Id: winutil.c,v 1.1 97/04/17 17:58:02 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>

#include <compat/windows.h>
#include <stdarg.h>
#include <stdio.h>
#include <compat/string.h>

typedef int	Boolean;
#include "winutil.h"


/***********************************************************************
 *				WinUtil_PrintError
 ***********************************************************************
 *
 * SYNOPSIS:	    Print out error message (like perror())
 * CALLED BY:	    (GLOBAL)
 * RETURN:	    void
 * SIDE EFFECTS:    Prints error message on stderr
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jacob	9/07/96   	Initial Revision
 *
 ***********************************************************************/
void
WinUtil_PrintError (char *fmt, ...)
{
    LPVOID lpMessageBuffer;
    va_list argList;

    va_start(argList, fmt);
    
    /*
     * This turns GetLastError() into a human-readable string.
     */
    (void) FormatMessage(
	FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
	NULL,
	GetLastError(),
	MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), /* user default language */
	(LPTSTR) &lpMessageBuffer,
	0,
	NULL);			/* #1 */

    vfprintf(stderr, fmt, argList);
    fprintf(stderr, ": %s", (char *) lpMessageBuffer);

    LocalFree(lpMessageBuffer);	/* #1 */

    va_end(argList);
}	/* End of WinUtil_PrintError.	*/


/***********************************************************************
 *				WinUtil_SprintError
 ***********************************************************************
 *
 * SYNOPSIS:	    Print the error message (like perror()) to a buffer
 * CALLED BY:	    (GLOBAL)
 * RETURN:	    void
 * SIDE EFFECTS:    Prints error message to buffer
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jacob	9/07/96   	Initial Revision
 *
 ***********************************************************************/
void
WinUtil_SprintError (char *buf, char *fmt, ...)
{
    LPVOID lpMessageBuffer;
    va_list argList;

    va_start(argList, fmt);
    
    /*
     * This turns GetLastError() into a human-readable string.
     */
    (void) FormatMessage(
	FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
	NULL,
	GetLastError(),
	MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), /* user default language */
	(LPTSTR) &lpMessageBuffer,
	0,
	NULL);			/* #1 */

    vsprintf(buf, fmt, argList);
    while (*buf != '\0') {
	buf++;
    }
    sprintf(buf, ": %s: Error #%d\r\n", lpMessageBuffer, GetLastError());

    LocalFree(lpMessageBuffer);	/* #1 */

    va_end(argList);
}	/* End of WinUtil_PrintError.	*/


/***********************************************************************
 *				WinUtil_LastPathSep
 ***********************************************************************
 *
 * SYNOPSIS:	        Finds the last path separator in a string.
 * CALLED BY:	        SuffFindNormalDeps and VarHead
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
WinUtil_LastPathSep (char *path)
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
}	/* End of WinUtil_LastPathSep.	*/


/***********************************************************************
 *				WinUtil_FirstPathSep
 ***********************************************************************
 *
 * SYNOPSIS:	        Finds the first path separator in a string.
 * CALLED BY:	        SuffFindNormalDeps and VarHead
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
WinUtil_FirstPathSep (char *path)
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
}	/* End of WinUtil_FirstPathSep.	*/
