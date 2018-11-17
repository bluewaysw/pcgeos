/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  lmem.h
 *
 * AUTHOR:  	  Adam de Boor: Dec  3, 1992
 *
 * REVISION HISTORY:
 *	Name	  Date	    Description
 *	----	  ----	    -----------
 *	ardeb	  12/ 3/92	    Initial version
 *
 * DESCRIPTION:
 *	Definition of various lmem and object structures from the kernel.
 *
 *
 * 	$Id: lmem.h,v 1.3 93/04/12 21:24:02 adam Exp $
 *
 ***********************************************************************/
#ifndef _LMEM_H_
#define _LMEM_H_
typedef struct {
    word    	LMBH_handle;
    word    	LMBH_offset;
    word    	LMBH_flags;
    word    	LMBH_lmemType;
    word    	LMBH_blockSize;
    word    	LMBH_nHandles;
    word    	LMBH_freeList;
    word    	LMBH_totalFree;
} LMemBlockHeader;

typedef struct {
    LMemBlockHeader	OLMBH_header;
    word		OLMBH_inUseCount;
    word		OLMBH_interactibleCount;
    dword		OLMBH_output;
    word		OLMBH_resourceSize;
} ObjLMemBlockHeader;

typedef enum /* word */ {
    LMEM_TYPE_GENERAL,
    LMEM_TYPE_WINDOW,
    LMEM_TYPE_OBJ_BLOCK,
    LMEM_TYPE_GSTATE,
    LMEM_TYPE_FONT_BLK,
    LMEM_TYPE_GSTRING,
    LMEM_TYPE_DB_ITEMS
} LMemType;

#define LMF_HAS_FLAGS		0x8000
#define LMF_IN_RESOURCE		0x4000
#define LMF_DETACHABLE		0x2000
#define LMF_DUPLICATED		0x1000
#define LMF_RELOCATED		0x0800
#define LMF_AUTO_FREE		0x0400
#define LMF_IN_LMEM_ALLOC	0x0200
#define LMF_IS_VM		0x0100
#define LMF_NO_HANDLES		0x0080
#define LMF_NO_ENLARGE		0x0040
#define LMF_RETURN_ERRORS	0x0020
#define LMF_HAS_TEMP_CHUNKS	0x0010
#define LMF_DEATH_COUNT		0x0007


/*
 * ObjChunkFlags for each chunk in an lmem block with LMF_HAS_FLAGS set.
 */
#define OCF_VARDATA_RELOC   0x10
#define OCF_DIRTY   	    0x08
#define OCF_IGNORE_DIRTY    0x04
#define OCF_IN_RESOURCE	    0x02
#define OCF_IS_OBJECT	    0x01


#define CA_NULL_ELEMENT	    0xffff

typedef struct {
    word	CAH_count;
    word	CAH_elementSize;
    word	CAH_curOffset;
    word	CAH_offset;
} ChunkArrayHeader;

#define EA_FREE_LIST_TERMINATOR	CA_NULL_ELEMENT

typedef struct {
    ChunkArrayHeader	EAH_meta;
    word		EAH_freePtr;
} ElementArrayHeader;

typedef struct {
    word	WAAH_low;
    byte	WAAH_high;
} WordAndAHalf;

typedef struct {
    WordAndAHalf	REH_refCount;
} RefElementHeader;

#define NAME_ARRAY_MAX_NAME_SIZE 256
#define NAME_ARRAY_MAX_DATA_SIZE 64

typedef struct {
    ElementArrayHeader	NAH_meta;
    word    	    	NAH_dataSize;
} NameArrayHeader;

typedef struct {
    RefElementHeader	NAE_meta;
} NameArrayElement;

typedef struct {
    RefElementHeader	NAME_meta;
    byte    	    	NAME_data[NAME_ARRAY_MAX_DATA_SIZE];
    char    	    	NAME_name[NAME_ARRAY_MAX_NAME_SIZE];
} NameArrayMaxElement;

#endif /* _LMEM_H_ */
