/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basco
FILE:		label.h

AUTHOR:		Paul L. DuBois, Dec 14, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	12/14/94	Initial version.

DESCRIPTION:
	Declarations for Label module

	$Id: label.h,v 1.1 98/10/13 21:43:05 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _LABEL_H_
#define _LABEL_H_

#include "bascoint.h"

typedef word Label;

typedef enum {
    FT_GLOBAL,		/* Fixup that should go in GlobalRefData array */
    FT_LABEL,		/* Reference to a code label */
    FT_JUMP		/* Jump opcode, a superset of FT_LABEL */
} FixupType;

#define UNSET_OFFSET	0xffff
#define NULL_LABEL	0xffff


/*
 * Create and return a new heap used to store label data.
 * Returns NullHandle on error.
 */
Boolean	LabelInitHeap(TaskPtr task);

/*
 * Use this to create labels that are targets of jumps.
 * You must set the offset at some point with LabelSetOffset.
 */
Label	LabelCreateTarget(TaskPtr task);

/*
 * Use this to create line number labels.
 * Note that nothing is returned.
 */
void	LabelCreateLine(TaskPtr task, word line);

/* Use for Fixups.  Pass FT_JUMP and a Label, or FT_LABEL and a Label.
 */
void	LabelCreateFixup(TaskPtr task, FixupType type, word index);

/*
 * Set the offset for a label.  You should only have to do
 * this once per label; in fact, you'll get a failed
 * assertion (in EC) if it's set twice.
 */
void	LabelSetOffset(TaskPtr task, Label l);

/*
 * Perform fixups for all functions and emit code suitable for
 * runtime evaluation.  Also, when creating a debuggable
 * app, emits line number label info
 * into the task's line label huge array...
 */

typedef enum 
{
    GRT_MODULE_VAR=1,
    GRT_PROC_CALL=2,
    GRT_FUNC_CALL=4,
    GRT_CONSTANT=8,
    GRT_MODULE_VAR_INDEX=16,
} GlobalRefType;

#define GRT_ROUTINE_CALL (GRT_PROC_CALL|GRT_FUNC_CALL)
#define GRT_MOD_VAR (GRT_MODULE_VAR|GRT_MODULE_VAR_INDEX)

Boolean	LabelDoLocalFixups(TaskPtr task);
Boolean	LabelDoGlobalRefFixups(TaskPtr task, GlobalRefType type, word data);

void	LabelDestroyHeap(TaskPtr task);

/* get number of entries in various label tables */
void	LabelGetCounts(MemHandle heap, word *numTargets,
		       word *numjumpArray, word *numLines);

/* delete entries in label tables */
void LabelDeleteEntries(MemHandle heap, 
		   word jumpStart, word jumpCount,
		   word targetStart, word targetCount,
		   word lineStart, word lineCount);



void LabelCreateGlobalFixup(TaskPtr task, word index, GlobalRefType grt);
void LabelDeleteGlobalRefsForFunction(TaskPtr    task, int funcNumber, 
				      Boolean deleteFunc);

#endif /* _LABEL_H_ */
