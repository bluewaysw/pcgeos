/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  os-win32.h
 *
 * AUTHOR:  	  Jacob A. Gabrielson: May  3, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/ 3/96   	Initial version
 *
 * DESCRIPTION:
 *	Do not include this file directly.  It is meant to be included
 *	via config.h.  See config.h for details.
 *
 *
 * 	$Id: os-win32.h,v 1.2 97/04/17 17:37:37 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _OS_WIN32_H_
#define _OS_WIN32_H_

#ifndef _WIN32
#error Why are you including this file?
#endif

/***********************************************************************
 *
 * Remap routine names with macros
 *
 ***********************************************************************/

#define HAVE_BZERO
#define bzero(b, length) ((void) memset((void *) (b), 0, (length)))

#define HAVE_TIMELOCAL
#define timelocal mktime

/***********************************************************************
 *
 * Define any routines available in this OS
 *
 ***********************************************************************/

#define HAVE_STRERROR

/***********************************************************************
 *
 * Define directory separator shme and other misc. stuff
 *
 ***********************************************************************/

#define QUOTED_SLASH   "\\"
#define PATHNAME_SLASH	'\\'
#define IS_PATHSEP(s) ((((s) == '\\') || ((s) == '/')) ? 1 : 0)

#define CARRIAGE_RETURN "\r"

#endif /* _OS_WIN32_H_ */
