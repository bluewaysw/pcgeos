/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           stabint.h

AUTHOR:         Roy Goldman, Dec  8, 1994

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	roy       12/ 8/94           Initial version.

DESCRIPTION:
	Header info specific to the string table

	$Id: stabint.h,v 1.1 98/10/13 21:43:35 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _STABINT_H_
#define _STABINT_H_

#include <mystdapp.h>
#include <hash.h>


#ifdef DOS
#define STableOptrToHandle OptrToChunk
#else
#define STableOptrToHandle OptrToHandle
#endif

#define CAST_ARR(type, array) *( (type *) (& (array)) )

extern word _pascal STHash(dword, void*);
extern Boolean _pascal STCompare(dword, dword, void*);

/* Each string table keeps the vmFile and vmBlock where the info
   is actually stored */

typedef struct {
    HashTableHeader	TH_meta;
    VMFileHandle	TH_vmFile;
    VMBlockHandle	TH_vmBlock;
} TableHeader;


#endif /* _STABINT_H_ */
