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
#ifndef _OS_UNIX_H_
#define _OS_UNIX_H_

#ifndef unix
#error Why are you including this file?
#endif

/***********************************************************************
 *
 * Remap routine names with macros
 *
 ***********************************************************************/

/***********************************************************************
 *
 * Define any routines available in this OS
 *
 ***********************************************************************/

/* 
 * These are all #define'd for Unix in config.h.  That way we
 * don't have to worry about these 2 files silently getting out-of-sync.
 */

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

#endif /* _OS_UNIX_H_ */
