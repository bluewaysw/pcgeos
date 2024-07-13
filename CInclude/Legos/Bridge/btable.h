/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		
FILE:		btable.h

AUTHOR:		Roy Goldman, Jul  9, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 9/95	Initial version.
	dubois	 8/ 3/95  	Merged tables and enum.

DESCRIPTION:
        Built-in function table info common to compiler and runtime.
	To use, #define one of the following constants:

	BTABLE_ENUM		To create the body of an enum
	BTABLE_BASCO_TABLE	To create compile time builtin table
	BTABLE_BASRUN_TABLE	To create runtime builtin table

	and then #include this file.

	$Id: btable.h,v 1.1 98/03/11 04:37:48 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* #define DefFunc(enum, name, numargs, arg1, arg2, arg3, retType, funcName)
 *
 * NOTE: String _must_ be < MAX_BUILT_IN_FUNC_NAME chars!
 * Args are:
 *   Name of enum passed to routine
 *   Name of routine in BASIC
 *   Number of arguments (max 3 right now)
 *   Type of arg 1
 *   Type of arg 2
 *   Type of arg 3
 *   Type of return value
 *   Name of C function which implements the builtin
 *
 *   DefFunc macro defined here to make it easier to increase the
 *   number of arguments.
 */

/* LoadModuleShared is 16 chars plus a null */
#define MAX_BUILT_IN_FUNC_NAME 17

#ifdef BTABLE_ENUM
#define DefFunc(enum, name, numargs, arg1, arg2, arg3, retType, funcName) \
 enum,
#endif

#ifdef BTABLE_HEADER
#define DefFunc(enum, name, numargs, arg1, arg2, arg3, retType, funcName) \
 extern BuiltInVector funcName;
#endif

#ifdef BTABLE_BASCO_TABLE
#define DefFunc(enum, name, numargs, arg1, arg2, arg3, retType, funcName) \
{_TEXT(name), numargs, {arg1, arg2, arg3}, retType},
#endif

#ifdef BTABLE_BASRUN_TABLE
#define DefFunc(e,name,num,t1,t2,t3,tr,funcName) {funcName},
#endif

DefFunc(FUNCTION_MID, "MID", 3,
        TYPE_STRING, TYPE_INTEGER, TYPE_INTEGER, TYPE_STRING,
        FunctionStringCommon)

DefFunc(FUNCTION_LEFT, "LEFT", 2,
        TYPE_STRING, TYPE_INTEGER, 0, TYPE_STRING,
        FunctionStringCommon)

DefFunc(FUNCTION_RIGHT, "RIGHT", 2,
        TYPE_STRING, TYPE_INTEGER, 0, TYPE_STRING,
        FunctionStringCommon)

DefFunc(FUNCTION_SPACE, "SPACE", 1,
        TYPE_INTEGER, 0,0, TYPE_STRING,
        FunctionStringCommon)

DefFunc(FUNCTION_INSTR, "INSTR", 2,
        TYPE_STRING, TYPE_STRING, 0, TYPE_INTEGER,
        FunctionStringInstr)

DefFunc(FUNCTION_ASC, "ASC",  1,
        TYPE_STRING, 0,0, TYPE_INTEGER,
        FunctionCommonStringToNumber)

DefFunc(FUNCTION_LEN, "LEN",  1,
        TYPE_STRING, 0,0, TYPE_INTEGER,
        FunctionCommonStringToNumber)

DefFunc(FUNCTION_VAL, "VAL",  1,
        TYPE_STRING, 0,0, TYPE_FLOAT,
        FunctionCommonStringToNumber)

DefFunc(FUNCTION_HEX, "HEX",  1,
        TYPE_LONG, 0,0, TYPE_STRING,
        FunctionCommonNumberToString)

DefFunc(FUNCTION_OCT, "OCT",  1,
        TYPE_LONG, 0,0, TYPE_STRING,
        FunctionCommonNumberToString)

DefFunc(FUNCTION_CHR, "CHR",  1,
        TYPE_INTEGER, 0,0, TYPE_STRING,
        FunctionCommonNumberToString)

DefFunc(FUNCTION_STR, "STR",  1,
        TYPE_UNKNOWN, 0,0, TYPE_STRING,
        FunctionCommonNumberToString)

DefFunc(FUNCTION_FORMAT, "FORMAT",  3,
	TYPE_FLOAT, TYPE_INTEGER, TYPE_INTEGER, TYPE_STRING,
	FunctionRoundFormat)

DefFunc(FUNCTION_ROUND, "ROUND",  2,
	TYPE_FLOAT, TYPE_INTEGER, 0, TYPE_FLOAT,
	FunctionRoundFormat)

DefFunc(FUNCTION_RND, "RND",  0,
        0,0,0, TYPE_FLOAT,
        FunctionMathCommon)

DefFunc(FUNCTION_ABS, "ABS",  1,
        TYPE_FLOAT, 0,0, TYPE_FLOAT,
        FunctionMathCommon)

DefFunc(FUNCTION_COS, "COS",  1,
        TYPE_FLOAT, 0,0, TYPE_FLOAT,
        FunctionMathCommon)

DefFunc(FUNCTION_SIN, "SIN",  1,
        TYPE_FLOAT, 0,0, TYPE_FLOAT,
        FunctionMathCommon)

DefFunc(FUNCTION_SQR, "SQR",  1,
        TYPE_FLOAT, 0,0, TYPE_FLOAT,
        FunctionMathCommon)

DefFunc(FUNCTION_SGN, "SGN",  1,
        TYPE_FLOAT, 0,0, TYPE_FLOAT,
        FunctionMathCommon)

DefFunc(FUNCTION_EXP, "EXP",  1,
        TYPE_FLOAT, 0,0, TYPE_FLOAT,
        FunctionMathCommon)

DefFunc(FUNCTION_POW, "POW",  2,
        TYPE_FLOAT, TYPE_FLOAT, 0, TYPE_FLOAT,
        FunctionMathCommon)

DefFunc(FUNCTION_ATN, "ATN",  1,
        TYPE_FLOAT, 0,0, TYPE_FLOAT,
        FunctionMathCommon)

DefFunc(FUNCTION_INT, "INT",  1,
        TYPE_FLOAT, 0,0, TYPE_FLOAT,
        FunctionMathCommon)

DefFunc(FUNCTION_TAN, "TAN",  1,
        TYPE_FLOAT, 0,0, TYPE_FLOAT,
        FunctionMathCommon)

DefFunc(FUNCTION_LOG, "LOG",  1,
        TYPE_FLOAT, 0,0, TYPE_FLOAT,
        FunctionMathCommon)

DefFunc(FUNCTION_MAKE_COMPONENT, "MAKECOMPONENT", 2,
        TYPE_STRING, TYPE_UNKNOWN, 0, TYPE_COMPONENT,
        FunctionComponent)

DefFunc(FUNCTION_LOAD_MODULE, "LOADMODULE",  1,
        TYPE_STRING, 0,0, TYPE_MODULE,
        FunctionLoadModule)

DefFunc(FUNCTION_SET_TOP, "SETTOP",     1,
        TYPE_COMPONENT, 0,0, TYPE_VOID,
        SubroutineSetTop)

DefFunc(FUNCTION_VALID_PARENT, "VALIDPARENT", 2,
        TYPE_COMPONENT, TYPE_COMPONENT, 0, TYPE_INTEGER,
        FunctionValidParent)

DefFunc(FUNCTION_HAS_PROPERTY, "HASPROPERTY", 2,
        TYPE_COMPONENT, TYPE_STRING, 0, TYPE_INTEGER,
        FunctionHasProperty)

DefFunc(FUNCTION_UPDATE, "UPDATE",     0,
        0,0,0, TYPE_VOID,
        FunctionUpdate)

DefFunc(FUNCTION_GET_COMPLEX, "GETCOMPLEX", 1,
        TYPE_INTEGER, 0,0, TYPE_COMPLEX,
        FunctionGetComplex)

DefFunc(FUNCTION_CUR_MODULE, "CURMODULE", 0,
        0,0,0, TYPE_MODULE,
        FunctionCurModule)

DefFunc(FUNCTION_IS_NULL_COMPONENT, "ISNULLCOMPONENT", 1,
        TYPE_COMPONENT, 0,0, TYPE_INTEGER,
        FunctionIsNullComponent)

DefFunc(FUNCTION_STRCOMP, "STRCOMP", 3,
        TYPE_STRING, TYPE_STRING, TYPE_INTEGER, TYPE_INTEGER,
        FunctionStringStrComp)

DefFunc(FUNCTION_RAISE_EVENT, "RAISEEVENT", VARIABLE_NUM_ARGS,
        0,0,0, TYPE_VOID,
        FunctionRaiseEvent)

DefFunc(FUNCTION_REGISTER_AGG, "EXPORTAGGREGATE", 2,
	TYPE_STRING, TYPE_STRING, 0, TYPE_VOID,
	SubroutineExportAggregate)

DefFunc(FUNCTION_GET_ARRAY_DIMS, "GETARRAYDIMS", 1,
	TYPE_ARRAY, 0, 0, TYPE_INTEGER,
	FunctionGetArrayDims)

DefFunc(FUNCTION_GET_ARRAY_SIZE, "GETARRAYSIZE", 2,
	TYPE_ARRAY, TYPE_INTEGER, 0, TYPE_INTEGER,
	FunctionGetArraySize)

DefFunc(FUNCTION_SYSTEM_MODULE, "SYSTEMMODULE", 0,
	0,0,0, TYPE_MODULE,
	FunctionSystemModule)

DefFunc(FUNCTION_IS_NULL_COMPLEX, "ISNULLCOMPLEX", 1,
	TYPE_COMPLEX, 0, 0, TYPE_INTEGER,
	FunctionIsNullComplex)

DefFunc(FUNCTION_GET_ERROR, "GETERROR", 0,
	0,0,0, TYPE_INTEGER,
	FunctionGetError)

DefFunc(FUNCTION_RAISE_ERROR, "RAISEERROR", 1,
	TYPE_INTEGER,0,0, TYPE_VOID,
	SubroutineRaiseError)

DefFunc(FUNCTION_REF_COUNTS, "REFCOUNTS", 1,
	TYPE_UNKNOWN,0,0, TYPE_INTEGER,
	FunctionRefCounts)

DefFunc(FUNCTION_ENABLE_EVENTS, "ENABLEEVENTS", 0,
	0, 0, 0, TYPE_VOID,
	FunctionEnableDisableEvents)

DefFunc(FUNCTION_DISABLE_EVENTS, "DISABLEEVENTS", 0,
	0, 0, 0, TYPE_VOID,
	FunctionEnableDisableEvents)

DefFunc(FUNCTION_BASIC_TYPE, "BASICTYPE", 1,
	TYPE_UNKNOWN, 0, 0, TYPE_STRING,
	FunctionType)

DefFunc(FUNCTION_TYPE, "TYPE", 1,
	TYPE_UNKNOWN, 0, 0, TYPE_STRING,
	FunctionType)

DefFunc(FUNCTION_SUB_TYPE, "SUBTYPE", 1,
	TYPE_UNKNOWN, 0, 0, TYPE_STRING,
	FunctionType)

DefFunc(FUNCTION_UNLOAD_MODULE, "UNLOADMODULE", 1,
	TYPE_MODULE, 0, 0, TYPE_VOID,
	FunctionUnloadModuleCommon)

DefFunc(FUNCTION_REQUIRE_MODULE, "LOADMODULESHARED", 1,
	TYPE_STRING, 0, 0, TYPE_MODULE,
	FunctionLoadModuleShared)

DefFunc(FUNCTION_USE_LIBRARY, "USELIBRARY", 1,
	TYPE_UNKNOWN, 0, 0, TYPE_VOID,
	SubroutineUseLibrary)

DefFunc(FUNCTION_DESTROY_MODULE, "DESTROYMODULE", 1,
	TYPE_MODULE, 0, 0, TYPE_VOID,
	FunctionUnloadModuleCommon)

DefFunc(FUNCTION_IS_NULL, "ISNULL", 1,
	TYPE_UNKNOWN, 0, 0, TYPE_INTEGER,
	FunctionIsNull)

DefFunc(FUNCTION_GET_SOURCE, "GETSOURCE", 1,
	TYPE_MODULE, 0, 0, TYPE_STRING,
	FunctionGetSourceExport)

DefFunc(FUNCTION_GET_EXPORT, "GETEXPORT", 1,
	TYPE_MODULE, 0, 0, TYPE_STRING,
	FunctionGetSourceExport)

DefFunc(FUNCTION_GET_MEMORY_USED_BY, "GETMEMORYUSEDBY", 1,
	TYPE_MODULE, 0, 0, TYPE_LONG,
	FunctionGetMemoryUsedBy)

#undef DefFunc
#undef BTABLE_BASRUN_TABLE
#undef BTABLE_BASCO_TABLE
#undef BTABLE_ENUM

