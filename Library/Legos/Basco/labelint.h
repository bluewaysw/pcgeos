/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basco
FILE:		labelint.h

AUTHOR:		Paul L. DuBois, Dec 16, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	12/16/94	Initial version.

DESCRIPTION:
	Internal decls for label module

	$Id: labelint.h,v 1.1 98/10/13 21:43:08 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _LABELINT_H_
#define _LABELINT_H_

#include "faterr.h"
#include <Legos/opcode.h>
#include <Legos/bugdata.h>
#include "label.h"

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %		Types and such
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* Typedef for ChunkArrayEnum callback procedure, used in label2.c */
typedef PCB(Boolean, CAEProcPtr, (void* element, void *enumData));

typedef struct {
    LMemBlockHeader LH_meta;
    ChunkHandle LH_lineArray;
    ChunkHandle	LH_targetArray;
    ChunkHandle LH_jumpArray;
    word	LH_startSeg;
    Boolean	LH_codeSizeChanged; /* FixupJumpCB sets/unsets this...
				       see comments in label2.c */
#if ERROR_CHECK
#define EC_LABEL_HEAP_TAG	0xb015
    word	LH_tag;	/* tag block for error-checking purposes */
#endif    
} LabelHeader;

typedef struct {
    word	TD_offset;
} TargetData;


/* Offsets in the following structs are 4 bits segment#, 12 bits offset
 * Add LH_startSeg to segment# to get HugeArray element containing code.
 */

typedef word JumpFlags;
#define JF_CROSS_SEGMENT (0x04)	/* jump target is in another segment */
#define JF_RELATIVE	(0x02)	/* jump target is 1-byte signed offset */
#define JF_STABLE	(0x01)	/* no more processing needed for this label */

typedef struct {
    word	FD_offset;	/* position of the fixup in code; kept
				 * updated during fixup process. */
    word	FD_origOffset;	/* original position of fixup, used when
				 * committing fixups (writing out code)
				 */

/* Buff new fields */
    FixupType	FD_type;
    word	FD_index;	/* FT_GLOBAL:	index into global vtab
				 * FT_LABEL:	Label
				 * FT_JUMP:	Label
				 */
    word	FD_extraData;	/* FT_JUMP:	JumpFlags
				 * FT_GLOBAL:	GlobalRefType
				 */
} FixupData;
#define JumpData FixupData


typedef struct 
{
    word    	    GRD_offset;
    word    	    GRD_index;	/* value dependant on the type field */
    GlobalRefType   GRD_type;
    word    	    GRD_funcNumber;
} GlobalRefData;

/*
 * This is an assert-type macro; they should never fail
 * (and serve more for documentation than anything else)
 */
#define LABEL_ASSERT(expr) EC_ERROR_IF( !(expr), LABEL_INTERNAL_ERROR )

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %		Internally-used procedures
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

extern void Label_FixupCodeSegments(void);
extern Boolean _pascal Label_FixupJumpCB(void* element, void* enumData);
extern void Label_FixupSizes(TaskPtr task, word offset, sbyte delta);
extern Boolean Label_CommitJumpChanges(TaskPtr task);
extern Opcode Label_ConvertJump(byte opcode, JumpFlags flags);
extern void Label_FlattenJumps(TaskPtr task);

#if ERROR_CHECK
extern void EC_CheckLabelHeap(MemHandle mh);
extern void EC_FinalCheckLabelHeap(MemHandle mh);
#endif

#endif /* _LABELINT_H_ */
