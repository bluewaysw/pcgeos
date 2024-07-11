/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		profile.h

AUTHOR:		Roy Goldman, Mar 30, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 3/30/95	Initial version.

DESCRIPTION:
	Macro interface to system profiling mechanism.

	This profiler isn't very sophisticated and requires
	manual instrumentation of code.

	At the time of writing, there was no built-in support
	for automatic function entry/exit detection for non-XIP'ed code.

	So, I've written a cheesy but flexible interface.

	The basic profiling block is a called a "region." These
	are user-defined through an enumeration. In the code
	to be profiled, the user marks the start and end of each region.

	$Id: profile.h,v 1.1 98/10/05 12:54:20 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _PROFILE_H_
#define _PROFILE_H_

extern void _far _pascal ProfileWriteGenericEntry(word data);

/* The high bit of any section must stay zero. Hence there
   are up to 32768 profile sections allowed...
*/

typedef enum
{
    PS_RUN_MAIN_LOOP,
    PS_RUN_DO_ARRAY_REF,
    PS_POP_DEREF_ARRAY_REF,
    PS_POP_SET_ARRAY_REF,
    PS_POP_RVAL,
    PS_POP_RVAL_WITH_PTRS,
    PS_ASSIGN_TYPE_COMPATIBLE,
    PS_SET_UP_FRAME,
    PS_RUN_SET_ERROR,

    PS_OP_START_ROUTINE,
    PS_OP_END_ROUTINE,
    PS_OP_CALL_PRIMITIVE,
    PS_OP_CALL,
    PS_OP_ACTION_ROUTINE,
    PS_OP_BRANCH_REL,
    PS_OP_JMP_REL,
    PS_OP_BRANCH,
    PS_OP_JMP,
    PS_OP_POP,
    PS_OP_DUP,
    PS_OP_INTEGER,
    PS_OP_STRING,
    PS_OP_LONG_OR_FLOAT,
    PS_OP_ARRAY_REF,
    PS_OP_GET_MODULE_REF,
    PS_OP_GET_PROPERTY,
    PS_OP_VAR_PROPERTY_ARRAY_REF,
    PS_OP_ASSIGN,
    PS_OP_UNARY_OPS,
    PS_OP_BINARY_OPS,
    PS_OP_DIM,

    PS_FUNC_STRING_COMMON,
    PS_FUNC_STRING_INSTR,
    PS_FUNC_STRING_STR_COMP,
    PS_FUNC_COMMON_STRING_TO_NUM,
    PS_FUNC_STRING_DATE_AND_TIME,
    PS_FUNC_MATH_COMMON,
    PS_FUNC_LOAD_MODULE,
    PS_FUNC_END_MODULE,

    PS_FUNC_COMPONENT,
    PS_FUNC_VALID_PARENT,
    PS_FUNC_UPDATE,
    PS_FUNC_GET_COMPLEX,
    PS_ROUTINE_SET_TOP,
    PS_FUNC_CUR_MODULE,
    PS_FUNC_HAS_PROPERTY,
    PS_FUNC_IS_NULL_COMPONENT,
    PS_FUNC_GET_ARRAY_DIMS,
    PS_FUNC_GET_ARRAY_SIZE,

    PS_RUN_SET_PC,
    PS_RUN_PUSH_CLEANUP,
    PS_RUN_POP_CLEANUP,
    PS_MEM_GET_INFO,
    PS_RUN_GET_FUNC_SEG


} ProfileSections;

#define START_MASK 0x8000
#define END_MASK   0x0000

#ifdef PROFILE

#define PROFILE_START_SECTION(section)  \
  ProfileWriteGenericEntry((START_MASK | (section)))

#define PROFILE_END_SECTION(section) \
  ProfileWriteGenericEntry((END_MASK | (section)))

#else

#define PROFILE_START_SECTION(section) 

#define PROFILE_END_SECTION(section)

#endif
			   

    

#endif /* _PROFILE_H_ */
