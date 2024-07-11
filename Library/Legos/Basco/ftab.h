/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		ftab.h

AUTHOR:		Paul L. Du Bois, May 13, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/13/96  	Initial version.

DESCRIPTION:
	Header for ftab.c -- routines to do with compiler's
	function table.

	$Id: ftab.h,v 1.1 98/10/13 21:42:57 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _FTAB_H_
#define _FTAB_H_

#include <tree.h>
#include "label.h"

typedef enum
{
    CS_NAKED,
    CS_PARSED,
    CS_VAR_ANALYZED,
    CS_TYPE_CHECKED,
    CS_CODE_GENERATED
} CompStatus;

typedef struct 
{
    BascoFuncType   funcType;	/* function or subroutine */
    CompStatus	compStatus;

    /*- Text code storage */
    dword	lineElement;    /* pointer to first line in function */
    word    	numLines;   	/* number of lines */

    VMBlockHandle tree;		/* AST */
    optr	labelNameTable;	/* chunkarray; map label name to AST node */

    /*- Local variables */
    word	vtab;		/* index of this function's VTab */

    /*- Bytecode storage */
    word	startSeg;	/* offset into task->codeBlock harray */
    byte	size;		/* # of segments */

    /*- Line labels for bytecode; map line # to bytecode offset */
    word	labelOffset;	/* offset into task->hugeLineArray harray */
    word	labelSize;	/* # of labels */

    /*- Random */
    byte	numParams;
    word	lastCompileError;	/* set to NONE if it compiled ok */
    word	lastCompileLine;

    /* these should really be moved into a flags word */
    byte	global;
    byte	hasErrorTrap;	/* set/unset during parsing */
    byte	hasResumeNext;	/* set/unset during parsing */

    Boolean    	deleted;    /* set true if slated for nukage */
    word    	index;	    /* position to be moved to */
} FTabEntry;

/* Contents of chunkarray in labelNameTable
 * These store information about named labels; targets of goto, etc.
 */
typedef struct
{
    word	identKey;	/* string in ID_TABLE */
    word	node;		/* node in ftab->tree */
    Label	label;		/* used during codegen */
} NamedLabel;

#ifdef DOS
#define FTAB_TableToChunk(table) table
#define FTAB_CHUNK task->funcTable
#else
#define FTAB_CHUNK 0x10
#define FTAB_TableToChunk(table) FTAB_CHUNK
#endif

/* unlock block chunk is in */
#define FTabUnlock(ftab) MemUnlock(*(MemHandle*)((unsigned long)ftab&0xffff0000))
#define FTabDirty(ftab)
extern FTabEntry* FTabLock(MemHandle table, int funcNumber);
extern FTabEntry* FTabDeref(MemHandle table, int funcNumber);

extern word FTabGetCount(MemHandle table);
extern int FTabAddEntry(TaskPtr task, TCHAR* name, BascoFuncType type, word self);
extern void FTabIncrementNumLines(TaskPtr task, int funcNumber);
extern MemHandle FTabCreate(void);
extern void FTabClean(MemHandle taskHan);
extern void FTabDestroy(MemHandle taskHan);

/* Routines to manipulate named labels */
extern void FTabAddLabel(TaskPtr task, word labelNameKey, Node labelNode);
extern NamedLabel* FTabGetLabelEntry(TaskPtr task, word labelNameKey);
extern void FTabResetLabelEntries(TaskPtr task);
#endif /* _FTAB_H_ */
