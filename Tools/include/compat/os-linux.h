/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  os-unix.h
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
 * 	$Id: os-unix.h,v 1.2 96/05/24 20:46:44 jacob Exp $
 *
 ***********************************************************************/
#ifndef _OS_LINUX_H_
#define _OS_LINUX_H_

#ifndef _LINUX
#error Why are you including this file?
#endif

/***********************************************************************
 *
 * Remap routine names with macros
 *
 ***********************************************************************/

 /***********************************************************************
  *
  * Remap routine names with macros
  *
  ***********************************************************************/

 #ifndef HAVE_BZERO
 #define HAVE_BZERO
 #define bzero(b, length) ((void) memset((void *) (b), 0, (length)))
 #endif

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

#define QUOTED_SLASH   "/"
#define PATHNAME_SLASH	'/'
#define IS_PATHSEP(s) (((s) == PATHNAME_SLASH) ? 1 : 0)

/* Unix isn't all hosed like DOS and Windows. */
#define CARRIAGE_RETURN ""

#endif /* _OS_LINUX_H_ */
