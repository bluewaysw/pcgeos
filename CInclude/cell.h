
/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	cell.h
 * AUTHOR:	Anna Lijphart: January, 1992
 *
 * DESCRIPTION:
 *	C version of cell.def
 *
 *	$Id: cell.h,v 1.1 97/04/04 15:58:05 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__CELL_H
#define __CELL_H

#include <graphics.h>
#include <dbase.h>

/* The CellRef structure is obsolete; you should just use an optr
 * instead. This typedef is left for backwards compatibility. */

typedef optr CellRef;        	/* MemHandle and Chunk of 
				 * locked cell */

#define	CellDeref(cellRef)	LMemDeref(cellRef)


#define	LARGEST_VISIBLE_ROW	16383
#define LARGEST_ROW		(LARGEST_VISIBLE_ROW + 128)
#define	LARGEST_COLUMN		255
#define	MAX_SINGLE_ROW_SIZE	((LARGEST_COLUMN+1) * sizeof(ColumnArrayElement))
#define	N_ROWS_PER_ROW_BLOCK	 32
#define N_ROW_BLOCKS	(((LARGEST_ROW + 1) / N_ROWS_PER_ROW_BLOCK) + 1)

typedef ByteFlags       CellFunctionParameterFlags;
#define CFPF_DIRTY 		0x80	/* apps may read or change this.  */
#define	CFPF_NO_FREE_COUNT 	0x07	

typedef	struct {
    CellFunctionParameterFlags	CFP_flags;
    VMFileHandle		CFP_file;
    VMBlockHandle		CFP_rowBlocks[N_ROW_BLOCKS];
} CellFunctionParameters;


extern void
    _pascal CellReplace(CellFunctionParameters *cfp, word row, 
		word column, const void *cellData, word size);

extern void *	
    _pascal CellLock(CellFunctionParameters *cfp, word row, word column);

extern void *
    _pascal CellLockGetRef(CellFunctionParameters *cfp, word row, word column,
			optr *ref);

#define CellUnlock(cellptr)	DBUnlock(cellptr)

#define CellDirty(cellptr)	DBDirty(cellptr)

extern void 	/* XXX */
    _pascal CellDirty(const void *ptr);

extern DBGroupAndItem /* XXX */
    _pascal CellGetDBItem(CellFunctionParameters *cfp, word row, byte column);

typedef struct {
    word	CAH_numEntries;		/* Number of array entries.	*/
    word	CAH_rowFlags;
} ColumnArrayHeader;

#define	RANGE_ENUM_CALLBACK_RETURN_TYPE	dword
#define	RANGE_ENUM_CALLBACK_RETURN_VALUE(haltEnumP, rangeEnumFlags)	\
		(((dword) ((haltEnumP << 8) | rangeEnumFlags)) << 16)

/*
 *	RangeEnumFlags	record
 */
typedef ByteFlags RangeEnumFlags;

#define REF_ALL_CELLS		    0x80
#define REF_NO_LOCK		    0x40
#define REF_ROW_FLAGS    	    0x20
#define REF_MATCH_ROW_FLAGS	    0x10

#define REF_CELL_ALLOCATED	    0x08
#define REF_CELL_FREED		    0x04
#define REF_OTHER_ALLOC_OR_FREE	    0x02
#define REF_ROW_FLAGS_MODIFIED      0x01


typedef struct {
    struct _RangeEnumParams *RECP_params;
    word    	    	RECP_row;
    word    	    	RECP_column;
    void    	    	*RECP_cellData;
    RangeEnumFlags	RECP_rangeFlags;
} RangeEnumCallbackParams;

typedef struct _RangeEnumParams {
    PCB(RANGE_ENUM_CALLBACK_RETURN_TYPE, REP_callback,
			(RangeEnumCallbackParams));
    Rectangle	    	    REP_bounds;
    word    	    	    REP_rowFlags;
    CellFunctionParameters  *REP_cfp;
    word    	    	    REP_matchFlags;
    word    	    	    REP_flagRow;
    void    	    	    *REP_locals;
} RangeEnumParams;

/*
 * C version of the RangeEnumParams to be passed to the RangeEnum() stub.
 */
typedef struct {
    RangeEnumParams 	    CREP_params;
    void    	    	    *CREP_locals;
    PCB(RANGE_ENUM_CALLBACK_RETURN_TYPE, CREP_callback,
			(RangeEnumCallbackParams));
} CRangeEnumParams;


extern void 	/* XXX */
    _pascal CellGetExtent(CellFunctionParameters *cfp, RangeEnumParams *rep);

typedef	struct {
    Rectangle	RIP_bounds;
    Point	RIP_delta;
    dword	RIP_cfp;
} RangeInsertParams;

extern void
    _pascal RangeInsert(CellFunctionParameters *cfp,
    	    	RangeInsertParams *rip);

extern dword 	/* XXX */
    _pascal RowGetFlags(CellFunctionParameters *cfp, word rowNum);

extern dword 	/* XXX */
    _pascal RowSetFlags(CellFunctionParameters *cfp, word rowNum, word flags);

extern Boolean
    _pascal RangeExists(CellFunctionParameters *cfp,
			word rowStart, word colStart,
			word rowEnd,   word colEnd);
			
extern Boolean /* XXX */
    _pascal RangeEnum(CellFunctionParameters *cfp,
		      CRangeEnumParams *params,
		      RangeEnumFlags flags);

/*
 * NOTE:  I have no idea how to prototype RangeSort for C.
 * Someone else will have to do this.
 */

/*
 *	RangeSortFlags	record
 */
typedef ByteFlags RangeSortFlags;

#define RSF_SORT_ROWS		0x80
#define RSF_SORT_ASCENDING	0x40
#define RSF_IGNORE_CASE		0x20
#define RSF_IGNORE_SPACES   	0x01	/* app only */

/*
 *	RangeSortCellExistsFlags	record
 */
typedef ByteFlags RangeSortCellExistsFlags;

#define RSCEF_SECOND_CELL_EXISTS	0x02
#define RSCEF_FIRST_CELL_EXISTS		0x01

typedef struct {
    Rectangle	RSP_range;
    Point	RSP_active;
    dword	RSP_callback;
    byte	RSP_flags;	/* RangeSortFlags */
    dword	RSP_cfp;
    word	RSP_sourceChunk;
    word	RSP_destChunk;	
    word	RSP_base;
    dword	RSP_lockedEntry;
    byte	RSP_cachedFlags;
} RangeSortParams;

typedef enum /* word */ {
    RSE_NO_ERROR,
    RSE_UNABLE_TO_ALLOC,
} RangeSortError;


#ifdef __HIGHC__
pragma Alias (CellLock, "CELLLOCK");
pragma Alias (CellLockGetRef, "CELLLOCKGETREF");
pragma Alias (CellReplace, "CELLREPLACE");
pragma Alias (RowGetFlags, "ROWGETFLAGS");
pragma Alias (RowSetFlags, "ROWSETFLAGS");
pragma Alias (RangeExists, "RANGEEXISTS");
pragma Alias (RangeEnum, "RANGEENUM");
#if (0)
pragma Alias (CellGetDBItem, "CELLGETDBITEM");
pragma Alias (CellGetExtent, "CELLGETEXTENT");
pragma Alias (RangeInsert, "RANGEINSERT");
pragma Alias (RangeSort, "RANGESORT");
#endif
#endif


#endif
