/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basco / Runtime
FILE:		faterr.h

AUTHOR:		Paul L. DuBois, Mar  9, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 3/ 9/95	Initial version.

DESCRIPTION:
	These errors are phat!

	This is where the fatal error and warning defns go.  Putting
	them in a separate file is so the runtime and compiler can
	be separated more easily (and so people can nuke faterr.h from
	their dependencies file)

	$Id: faterr.h,v 1.1 98/10/13 21:42:51 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _FATERR_H_
#define _FATERR_H_

/* - Warnings and Fatal Errors */
typedef enum
{
    /* Compiler errors go here */
    BE_HACK_ERROR = 50,		/* don't ask */
    BE_FAILED_ASSERTION,	/* all-purpose error */
    BE_OVERWRITING_RTASK_FIELD,
    BE_TASK_FIELD_IS_EMPTY,
    BE_BAD_RTASK,
    BE_REPLACING_NONEXISTENT_PAGE,
    BE_OCU_NOT_ALLOWED_HERE,
    BE_INVALID_TYPE,
    BE_INVALID_FUNCTION_CALL,
    BE_INVALID_PAGE_MARKER,
    BE_INVALID_CLEANUP,
    BE_INVALID_VTAB,

    /* Some label shme */
    LABEL_INTERNAL_ERROR,
    LABEL_OFFSET_ALREADY_SET,
    LABEL_OFFSET_TOO_LARGE,
    LABEL_BAD_SEG_OR_OFFSET,
    LABEL_BAD_LABEL_NUMBER,
    LABEL_BAD_LABEL_HEAP,
    LABEL_NULL_OFFSET_AFTER_CODEGEN,

    PAGE_INTERNAL_ERROR,
    PAGE_INVALID_FUNCTION_NUMBER,
    PAGE_FUNCTION_TOO_LARGE,
    PAGE_SEGMENT_TOO_LARGE,
    PAGE_INVALID_MARKER,

    /* Bugger errors here */
    BUGGER_FAILED_ASSERTION,
    BUG_INVALID_FUNC_SEG
} FatalErrors;

typedef enum
{
    /* Compiler warnings go here */
    BW_RTASK_NOT_EMPTY,		/* Probably a memory leak */
    BW_OLD_KERNEL,		/* Oops, we have to work around a kernel bug */
    BW_UNHANDLED_CASE,

} Warnings;

#define ASSERT(_cond) \
 EC_ERROR_IF(!(_cond), BE_FAILED_ASSERTION)

extern FatalErrors phat;
extern Warnings	   homie;

#endif /* _FATERR_H_ */
