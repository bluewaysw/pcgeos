/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		AnsiC (NOTE: non ANSI C geos functions)
FILE:		geoMisc.h

AUTHOR:		Allen Schoonmaker, Jun  3, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/ 3/92   	Initial version.

DESCRIPTION:
	This files contains many functions that are common under Unix
	and other operating systems that are not in Standard C.

	$Id: geoMisc.h,v 1.1 97/04/04 15:56:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef __STRMISC_H__
#define __STRMISC_H__

#include <localize.h>

extern word
  _pascal strpos (const TCHAR *__s, int __c);

extern word
  _pascal strrpos (const TCHAR *__s, int __c);

#define strcmpi(a,b)	LocalCmpStringsNoCase((a),(b),0)
#define strlwr(a)	LocalDowncaseString((a),0)
#define strupr(a)	LocalUpcaseString((a),0)

extern void
  _pascal itoa(int __n, TCHAR *__s);

extern void
 _pascal strrev(TCHAR *__s);

extern void
  *_pascal memccpy(void *__dest, void *__src, word __c, word __n);

/*
 *	Notes about using the various malloc-esque routines:
 *
 *	There is no synchronization being done. If you will be calling
 *	malloc routines from multiple threads, you should provide your
 *	own synchronization around the calls.
 *
 *	malloc(), calloc(), realloc(), and free() all work on a heap associated
 *	with the Geode associated with the current process. If you want to
 *	use a heap associated with another geode, you should call _Malloc,
 *	_Realloc, and _Free, and explicitly pass in the geode whose
 *	heap you want to use (this is useful for libraries that want to
 *	perform mallocs).
 */
extern void
    *_pascal _Malloc(word blockSize, GeodeHandle geodeHan, word zeroInit);

#define GeoMalloc _Malloc

/*
 *	Notes about GeoReAlloc()
 *
 *	1) If the space is resized larger, new space is *not* zero-initialized.
 *
 *	2) If realloc() is called to resize the memory *smaller*, it will
 *	   always succeed.
 *
 *	3) If realloc() does not succeed, it will return NULL, and the original
 *	   memory block will be unaffected.
 *
 *	4) If the passed blockPtr is NULL, realloc() acts like malloc().
 *
 *	5) If the passed newSize is 0, the passed blockPtr is freed, and
 *	   NULL is returned.	
 *	   
 */
extern void
    *_pascal _ReAlloc(void *blockPtr, word newSize, GeodeHandle geodeHan);

#define GeoReAlloc _ReAlloc

extern void
    _pascal _Free(void *blockPtr, GeodeHandle geodeHan);

#define GeoFree _Free
#define cfree _Free


#ifdef __HIGHC__

pragma Alias(_Malloc, "_MALLOC");
pragma Alias(strpos, "STRPOS");
pragma Alias(strrpos, "STRRPOS");
pragma Alias(itoa, "ITOA");
pragma Alias(strrev, "STRREV");
pragma Alias(memccpy, "MEMCCPY");

#endif

#endif
