/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	LEGOS
MODULE:		Bas run
FILE:		faterr.h

AUTHOR:		Roy Goldman, Jul  9, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 9/95	Initial version.

DESCRIPTION:
	Runtime fatal errors and warnings.

	$Id: faterr.h,v 1.1 98/10/05 12:54:18 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _FATERR_H_
#define _FATERR_H_

typedef enum 
{
    RE_FAILED_ASSERTION = 50,    /* Dont overlap ec.def fatal errors :( */
    RE_NOT_ROUTINE_BEGINNING,
    RE_BAD_RTASK,
    RE_INVALID_TYPE,
    RE_BAD_TYPE,
    RE_BAD_LOCAL_VAR_TYPE,
    RE_BAD_RVAL_TYPE,
    RE_NO_MODULE_AFTER_SET_MODULE_REF,
    RE_NO_STRING_AFTER_SET_MODULE_REF,
    RE_ARRAY_ON_STACK,
    RE_INVALID_STACK,
    RE_NO_FIDO,
    RE_DESTROYING_REFERENCES,
    RE_TYPE_ASSUMPTION_FAILED,
    RE_OCU_NOT_ALLOWED_HERE,
    RE_HEAP_LOCKED_BUT_COULD_MOVE,
    RE_POINTER_NOT_ALIGNED,
    
    PAGE_INTERNAL_ERROR,
    PAGE_INVALID_FUNCTION_NUMBER,
    PAGE_FUNCTION_TOO_LARGE,
    PAGE_SEGMENT_TOO_LARGE,
    PAGE_INVALID_MARKER,

    /* Bugger errors here */
    BUGGER_FAILED_ASSERTION,
    BUG_INVALID_FUNC_SEG
} FatalErrors;

typedef enum {
    /* Runtime warnings go here and in manager.asm */
    RW_SOMETHING_STRANGE = 300,
    RW_NULL_HUGE_ARRAY_IN_RTASK,
    RW_NULL_STABLE_IN_RTASK,
    RW_DESTROYING_RTASK_WITH_REFERENCES,
    RW_OVERWRITING_BUGINFO_BLOCK,
    RW_RTASKS_DO_NOT_MATCH,
    RW_STACK_UNBALANCED,
    RW_FUNC_CALL_WHEN_BUSY,
    RW_FUNC_CALL_FAILED,
    RW_FUNC_CALL_WHEN_DISABLED,
    RW_CANT_UNLOAD_DEBUGGED_MODULE,
    RW_NULLHANDLE_TO_RUN_SWITCH_FUNCTIONS
} Warnings;

extern FatalErrors hormoos;
extern Warnings    booglie;

#endif /* _FATERR_H_ */
