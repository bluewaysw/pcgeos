/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  stdlib.h
 *
 * AUTHOR:  	  Jacob A. Gabrielson: May 14, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/14/96   	Initial version
 *
 * DESCRIPTION:
 *	"Safe" stdlib.h that you can include without fear of
 *	conflicting with our malloc.h.
 *
 *      Usage: #include <compat/stdlib.h>
 *
 *
 * 	$Id: stdlib.h,v 1.3 97/04/17 16:18:30 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _COMPAT_STDLIB_H_
#define _COMPAT_STDLIB_H_

#define mallinfo _biff_stdlib_mallinfo 
#define malloc_t _biff_stdlib_t 
#define calloc _biff_stdlib_calloc 
#define free _biff_stdlib_free 
#define malloc _biff_stdlib_malloc 
#define realloc _biff_stdlib_realloc 
#define mallopt _biff_stdlib_mallopt 
#define mallinfo _biff_stdlib_mallinfo 

#if defined(__GNUC__)
# define abort _biff_stdlib_abort
#endif

#include <stdlib.h>

#if defined(__GNUC__)
# undef abort
#endif

#undef mallinfo
#undef malloc_t
#undef calloc
#undef free
#undef malloc
#undef realloc
#undef mallopt
#undef mallinfo

#endif /* _COMPAT_STDLIB_H_ */
