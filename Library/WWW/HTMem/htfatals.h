/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Geos WWW Library
MODULE:		htfatals
FILE:		htfatals.h

AUTHOR:		Kok Kin Kee, Feb 18, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kkee    	2/18/97   	Initial version.

DESCRIPTION:

	FatalErrors and Warnings.

	$Id: //depot/pcgeos/Library/WWW/HTMem/htfatals.h#5 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


#ifndef __HT_FATALS_GOH__
#define __HT_FATALS_GOH__

/*
 * FatalErrors
 */
#if ERROR_CHECK
typedef enum {
    CANNOT_FREE_LOCKED_HTMEMORY,
    CANNOT_REALLOC_LOCKED_HTMEMORY,
    CANNOT_UNLOCK_NONLOCKED_HTMEMORY,
    INVALID_ID_FOR_HTMEMORY,
    INVALID_HTMEMORY
} FatalErrors;
#endif /* ERROR_CHECK */

/*
 * Warnings
 */
#if ERROR_CHECK
typedef enum {
    HTMEMORY_EXCEEDING_LIMIT,
    HTMEMORY_USING_OLD_ID
} Warnings;
#endif


#if ERROR_CHECK
extern FatalErrors htmemFatalErrors;
extern Warnings    htmemWarnings;
#endif 

#endif /* __HT_FATALS_GOH__ */







