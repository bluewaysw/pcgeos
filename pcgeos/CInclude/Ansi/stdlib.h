/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Ansi C Library
MODULE:		AnsiC
FILE:		stdlib.h

AUTHOR:		Allen Schoonmaker, Jun 11, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/11/92   	Initial version.

DESCRIPTION:
	This is the header file for the ANSI C stdlib.h header file

	$Id: stdlib.h,v 1.1 97/04/04 15:50:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef __STDLIB_H
#define __STDLIB_H

#include <geos.h>
extern int
    _pascal atoi (const TCHAR *__s);

extern void
    _pascal itoa(int __n, TCHAR *__s);

#ifdef DO_DBCS
extern int
    _pascal atoisbcs (const char *__s);
extern void
    _pascal itoasbcs(int __n, char *__s);
#endif

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

#define malloc(blockSize) _Malloc(blockSize,NullHandle,0)

#define calloc(n, size) _Malloc(n*size,NullHandle,1)

/*
 *	Notes about realloc()/_ReAlloc():
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

#define realloc(blockPtr,newSize) _ReAlloc(blockPtr, newSize, NullHandle)

extern void
    _pascal _Free(void *blockPtr, GeodeHandle geodeHan);

#define free(blockPtr) _Free(blockPtr, NullHandle);

extern void
    _pascal qsort(void *array, word count, word elementSize,
		  PCB(int, compare, (const void *, const void *)));

extern void
    *_pascal bsearch(const void *key, const void *array,
		     word count, word elementSize,
		     PCB(int, compare, (const void *, const void *)));

#ifdef __HIGHC__
pragma Alias(atoi, "ATOI");
pragma Alias(itoa, "ITOA");
pragma Alias(_Malloc, "_MALLOC");
pragma Alias(_ReAlloc, "_REALLOC");
pragma Alias(_Free, "_FREE");
pragma Alias(qsort, "QSORT");
pragma Alias(bsearch, "BSEARCH");
#endif

#endif



/* This stuff has gotta go ! *


#define cfree free
*/
