/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		runerr.h

AUTHOR:		Jimmy Lefkowitz, Feb  8, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 2/ 8/95	Initial version.

DESCRIPTION:
	
        $Id: runerr.h,v 1.1 97/12/05 12:16:00 gene Exp $
        $Revision: 1.1 $

	Liberty version control

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _RUNERR_H_
#define _RUNERR_H_

#ifdef LIBERTY

#define	RTE_NONE			0
#define RTE_INTERNAL_ERROR		1
#define RTE_BAD_PARAM_TYPE		2
#define RTE_BAD_RETURN_TYPE		3
#define RTE_ARRAY_REF_SANS_DIM		4
#define RTE_BAD_MODULE			5
#define RTE_BAD_MODULE_REFERENCE	6
#define RTE_TYPE_MISMATCH		7
#define RTE_BAD_TYPE			8
#define RTE_BAD_ARRAY_REF		9
#define RTE_BAD_OPCODE			10
#define RTE_BAD_RVAL			11
#define RTE_BAD_NUM_ARGS		12
#define RTE_ARG_NOT_A_NUMBER		13
#define RTE_ARG_NOT_A_STRING		14
#define RTE_ARG_INVALID_TYPE		15
#define RTE_DIVIDE_BY_ZERO		16
#define RTE_INCOMPATIBLE_TYPES		17
#define RTE_UNKNOWN_COMPONENT_CLASS	18
#define RTE_INVALID_ACTION		19

        /* component errors */

#define RTE_READONLY_PROPERTY		20

        /* naughty code tried to set a read-only property */

#define RTE_UNKNOWN_PROPERTY		21

    	/* property that the component does not know about */

#define RTE_PROPERTY_TYPE_MISMATCH	22

	/* wrong type passed in and the component won't convert it for you */
#define RTE_PROPERTY_SIZE_MISMATCH	23
#define RTE_PROPERTY_NOT_SET		24

	/* the component knows about this property, but it can't determine
	 * what the current value is. */
#define RTE_WRONG_NUMBER_ARGS		25

        /* the action expected a different number of args than passed in. */
#define RTE_WRONG_TYPE			26
#define RTE_SPECIFIC_PROPERTY		27

        /* function not found in module */
#define RTE_INVALID_MODULE_CALL		28	
#define RTE_LOOP_OVERFLOW		29
#define RTE_OVERFLOW			30
#define RTE_EXPECT_FUNC			31
#define RTE_EXPECT_PROC			32
#define RTE_BAD_STRING_INDEX		33
#define RTE_VALUE_IS_NULL		34
#define RTE_PASS_BY_REF_UNSUPPORTED	35
#define RTE_INVALID_PARENT		36
#define RTE_STACK_OVERFLOW		37
#define RTE_COMP_INIT_WITH_AGG		38
#define RTE_ARRAY_TOO_BIG		39
#define RTE_ACTIVE_EHAN			40
#define RTE_INACTIVE_EHAN		41
#define RTE_NEGATIVE_DIM		42
#define RTE_QUIET_EXIT	    	    	43
#define RTE_BEING_UNLOADED		44
#define RTE_UNEXPECTED_END_OF_LOOP	45
#define RTE_UNEXPECTED_END_OF_ROUTINE	46
#define RTE_LIBRARY_NOT_FOUND		47
#define RTE_NOT_AGGREGATE_MODULE	48
#define RTE_OUT_OF_MEMORY		49
#define RTE_ERROR_IN_MODULE_INIT	50
#define RTE_CANT_LOAD_WHEN_UNLOADING	51
#define RTE_LAST_ERROR			52

typedef word RuntimeErrorCode;

#else	/* GEOS version below */

typedef enum 
{
    RTE_NONE,
    RTE_INTERNAL_ERROR,
    RTE_BAD_PARAM_TYPE,
    RTE_BAD_RETURN_TYPE,
    RTE_ARRAY_REF_SANS_DIM,
    RTE_BAD_MODULE,
    RTE_BAD_MODULE_REFERENCE,
    RTE_TYPE_MISMATCH,
    RTE_BAD_TYPE,
    RTE_BAD_ARRAY_REF,
    RTE_BAD_OPCODE,
    RTE_BAD_RVAL,
    RTE_BAD_NUM_ARGS,
    RTE_ARG_NOT_A_NUMBER,
    RTE_ARG_NOT_A_STRING,
    RTE_ARG_INVALID_TYPE,
    RTE_DIVIDE_BY_ZERO,
    RTE_INCOMPATIBLE_TYPES,
    RTE_UNKNOWN_COMPONENT_CLASS,
    RTE_INVALID_ACTION,

    /* component errors */
    RTE_READONLY_PROPERTY,
        /* naughty code tried to set a read-only property */
    RTE_UNKNOWN_PROPERTY,
    	/* property that the component does not know about */

    RTE_PROPERTY_TYPE_MISMATCH,
	/* wrong type passed in and the component won't convert it for you */

    RTE_PROPERTY_SIZE_MISMATCH,
    RTE_PROPERTY_NOT_SET,
	/* the component knows about this property, but it can't determine
	 * what the current value is. */

    RTE_WRONG_NUMBER_ARGS,
    /* the action expected a different number of args than passed in. */
    RTE_WRONG_TYPE,
    RTE_SPECIFIC_PROPERTY,

    RTE_INVALID_MODULE_CALL,	/* function not found in module */
    RTE_LOOP_OVERFLOW,
    RTE_OVERFLOW,
    RTE_EXPECT_FUNC,
    RTE_EXPECT_PROC,
    RTE_BAD_STRING_INDEX,
    RTE_VALUE_IS_NULL,
    RTE_PASS_BY_REF_UNSUPPORTED,
    RTE_INVALID_PARENT,
    RTE_STACK_OVERFLOW,
    RTE_COMP_INIT_WITH_AGG,
    RTE_ARRAY_TOO_BIG,
    RTE_ACTIVE_EHAN,
    RTE_INACTIVE_EHAN,
    RTE_NEGATIVE_DIM,
    RTE_QUIET_EXIT,
    RTE_BEING_UNLOADED,
    RTE_UNEXPECTED_END_OF_LOOP,
    RTE_UNEXPECTED_END_OF_ROUTINE,
    RTE_LIBRARY_NOT_FOUND,
    RTE_NOT_AGGREGATE_MODULE,
    RTE_OUT_OF_MEMORY,
    RTE_ERROR_IN_MODULE_INIT,
    RTE_CANT_LOAD_WHEN_UNLOADING,
    RTE_LAST_ERROR
} RuntimeErrorCode;

#endif

#define FIRST_COMPONENT_ERROR RTE_INVALID_ACTION


#endif /* _RUNERR_H_ */





