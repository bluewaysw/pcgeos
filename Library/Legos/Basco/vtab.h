/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		vtab.h

AUTHOR:		Paul L. DuBois, May 16, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 5/16/95	Initial version.

DESCRIPTION:
	

	$Id: vtab.h,v 1.1 98/10/13 21:43:59 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _VTAB_H_
#define _VTAB_H_

#include <geos.h>
#include <Legos/legtype.h>
#include <Legos/basrun.h>

#define STD_SIZE 5
#define GLOBAL_VTAB	0
#define NULL_VTAB	0xffff

#define VTAB_NORMAL 0
typedef struct
{
    LMemBlockHeader	VTH_meta;
    ChunkHandle	VTH_tableArray;		/* Chunkarray of chunkhandles */
    word	VTH_freeHead;		/* Freelist head for tableArray */
} VTabHeap;



/* Header for chunkarrays pointed to by VTH_tableArray
 */
typedef struct
{
    ChunkArrayHeader VT_meta;
    word	VT_size;
} VTab;

/* Format for entries in a VTab
 */
typedef struct 
{
    word	VTE_name;	/* ID in stringIdentTable */
    word	VTE_offset;
    byte	VTE_size;
    byte	VTE_flags;	/* now: only VTF_FORWARD_REF */
    LegosType	VTE_type;	/* basic type */
    word	VTE_extraInfo;	/* string table id:
				 * components: compTypeNameTable
				 * structs: structIndex
				 */
    word    	VTE_funcNumber; /* so we know where a global variable came
				 * from, so we can figure out if its gone
				 * away.
				 */
    word    	VTE_index;	/* place in array once unsused variables
				 * are deleted
				 */
} VTabEntry;


/* Arrays within struct VTabs might have one of these around
 */
typedef struct
{
    byte	VTSD_num;
    word	VTSD_dim[MAX_DIMS];
} VTabStaticDims;

#define VTAB_ERROR 0xffff
#define VTAB_RECOMPILE 0xfffe

/* #define VTF_ARRAY		(0x1) obsolete */
#define VTF_FORWARD_REF		(0x2)
/* #define VTF_REDIM   	    	(0x4) obsolete */

MemHandle VTabInit(void);		/* Init/de-init this module */
void	VTabExit(MemHandle vtHeap);


word	VTAlloc(MemHandle vtHeap);	/* Create/destroy a var table */
void	VTDestroy(MemHandle vtHeap, word table);

word	VTAdd(MemHandle vtHeap, word table, word nameId,
	      LegosType type, byte varSize, byte flags, word extraInfo,
	      word funcNumber);

void	VTMove(MemHandle vtHeap, word table, word element, word newOffset);

void	VTAppendDims(MemHandle vtHeap, word table, word nameId,
		     VTabStaticDims* dims);

Boolean	VTLookup(MemHandle vtHeap, word table, word nameId,
		 VTabEntry* retVte, word* eltNum);

void	VTLookupIndex(MemHandle vtHeap, word table, word element,
		      VTabEntry* retVte);
void	VTLookupOffset(MemHandle vtHeap, word table, word offset,
		      VTabEntry* retVte);

void	VTLookupDimsIndex(MemHandle vtHeap, word table, word element,
			  VTabStaticDims* retDims);

word	VTGetCount(MemHandle vtHeap, word table);
word	VTGetSize(MemHandle vtHeap, word table);

void	VTResetGlobalsForFunction(MemHandle VTHeap, word funcNumber, 
				  Boolean delete);

optr	VTCreateIndex(MemHandle vtHeap, word table);
word	VTCompactUncompactGlobals(MemHandle VTHeap, optr index, Boolean uncompact);
#define VTCompactGlobals(vtHeap, index) VTCompactUncompactGlobals(vtHeap, index, FALSE)
#define VTUncompactGlobals(vtHeap, index) VTCompactUncompactGlobals(vtHeap, index, TRUE)

void	VTDeleteUnusedGlobals(MemHandle vtHeap);

word    VTGetFlags(MemHandle vtHeap, word table);
word    VTSetFlags(MemHandle vtHeap, word table, word set, word clear);
Boolean	VTCompareTables(MemHandle vtHeap, word table1, word table2);

#endif /* _VTAB_H_ */
