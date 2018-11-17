/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		heap.h

AUTHOR:		Chris Boyke, Jan  3, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CB	1/ 3/94   	Initial version.

DESCRIPTION:
	

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef	__HEAP_H
#define __HEAP_H

typedef ByteFlags HeapFlags;
#define HF_FIXED	0x80
#define HF_SHARABLE	0x40
#define HF_DISCARDABLE	0x20
#define HF_SWAPABLE	0x10
#define HF_LMEM		0x08
#define HF_DISCARDED	0x02
#define HF_SWAPPED	0x01

#define HF_STATIC	(HF_DISCARDABLE | HF_SWAPABLE)
#define HF_DYNAMIC	(HF_SWAPABLE)

/* Flags for allocation type */

typedef ByteFlags HeapAllocFlags;
#define HAF_ZERO_INIT		0x80
#define HAF_LOCK		0x40
#define HAF_NO_ERR		0x20
#define HAF_UI			0x10
#define HAF_READ_ONLY		0x08
#define HAF_OBJECT_RESOURCE	0x04
#define HAF_CODE		0x02
#define HAF_CONFORMING		0x01

/*
 * a few shortcuts for allocation flags
 */

/* standard block allocation flags */

#define HAF_STANDARD		0
#define HAF_STANDARD_NO_ERR	(HAF_NO_ERR)

/* allocation flags to allocate locked block */

#define HAF_STANDARD_LOCK	(HAF_LOCK)
#define HAF_STANDARD_NO_ERR_LOCK (HAF_NO_ERR | HAF_LOCK)

/***/

#endif
