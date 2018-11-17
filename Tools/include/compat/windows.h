/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  windows.h
 *
 * AUTHOR:  	  Jacob A. Gabrielson: May 14, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/14/96   	Initial version
 *
 * DESCRIPTION:
 *	"Safe" windows.h that you can include without fear of
 *	conflicting with our malloc.h.
 *
 *	In case you're wondering, starting with version 5.0
 *	Borland C's windows.h #include's stdlib.h.  Argh!
 *
 *      Usage: #include <compat/windows.h>
 *
 *
 * 	$Id: windows.h,v 1.2 97/04/17 16:20:40 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _COMPAT_WINDOWS_H_
#define _COMPAT_WINDOWS_H_

#ifdef _WIN32

#define mallinfo _biff_stdlib_mallinfo 
#define malloc_t _biff_stdlib_t 
#define calloc _biff_stdlib_calloc 
#define free _biff_stdlib_free 
#define malloc _biff_stdlib_malloc 
#define realloc _biff_stdlib_realloc 
#define mallopt _biff_stdlib_mallopt 
#define mallinfo _biff_stdlib_mallinfo 

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#undef mallinfo
#undef malloc_t
#undef calloc
#undef free
#undef malloc
#undef realloc
#undef mallopt
#undef mallinfo

#endif /* _WIN32 */

#endif /* _COMPAT_WINDOWS_H_ */
