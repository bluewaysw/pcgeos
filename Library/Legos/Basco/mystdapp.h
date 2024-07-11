/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mystdapp.h

AUTHOR:		Roy Goldman, Dec 19, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/19/94		Initial version.

DESCRIPTION:
	Just an easy way to include basic GEOS header stuff
	without loading in the .goh file

	$Id: mystdapp.h,v 1.1 98/10/13 21:43:12 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _MYSTDAPP_H_
#define _MYSTDAPP_H_

#include <geos.h>
#include <heap.h>
#include <geode.h>
#include <resource.h>
#include <ec.h>
#include <object.h>
#include <vm.h>
#include <hugearr.h>
#include <system.h>
#include <geoworks.h>
#include <lmem.h>
#include <chunkarr.h>

#include <char.h>
#include <file.h>

#include "faterr.h"

#ifdef DOS
#include "btoken.h"
#include "bascoint.h"
#include "tree.h"
#include "comtask.h"

#define LocalStringLength strlen

typedef struct
{
    int	    numElements;
    int	    maxElements;
    int	    elementSize;
    char    *firstElement;
    void    **indexTable;
    int	    *sizeTable;
} MyHugeArrayHeader;



extern void 	**globalLMemBlocks;
extern int	numGlobalLMemBlocks;
extern TCHAR *ConvertTokenCodeToString(TokenCode c);
extern TCHAR *ConvertCompileErrorCodeToString(ErrorCode c);
extern void  PrintTree(MemHandle tree, Node n, int indent);
extern void GetTreeSize(MemHandle tree, Node n, long *size);
extern void *MyMalloc(int size);
extern void *MyRealloc(void *ptr, int size);
extern void _pascal HugeArraySetNumElements(VMBlockHandle arr, word numElements);
extern long HugeArrayTotalSize(MemHandle arr);
extern long ChunkArrayTotalSize(MemHandle arr);
extern long HashTableTotalSize(MemHandle table);
extern long StringTableTotalSize(optr table);
extern unsigned long CoreLeft(void);

#endif /* ifdef DOS */
#endif /* _MYSTDAPP_H_ */
