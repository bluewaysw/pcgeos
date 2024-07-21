/*%%%%%% -*- c++ -*- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	LEGOS
MODULE:		Bas runtime
FILE:		builtin.c

AUTHOR:		Jimmy Lefkowitz, Jan  9, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 1/ 9/95	Initial version.

DESCRIPTION:
	Implements most built-in functions.

	$Id: builtin.c,v 1.2 98/10/05 12:49:18 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifdef LIBERTY

#include <Legos/interp.h>
#include <Legos/runint.h>
#include <Legos/stack.h>
#include <jAnsi/string.h>
#include <Ansi/string.h>
#include <Legos/runheap.h>
#include <Legos/builtin.h>
#include <Legos/sst.h>
#include <Legos/prog.h>
#include <driver/keyboard/tchar.h>
#include <driver/fatalerr.h>
#include <Legos/fixds.h>

#include <math.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef EC_DEBUG_SERCOMP
#include <kernel/log.h>
Log *myLog = NULL;
#endif

#include <Legos/runerr.h>
#include <data/array.h>

#include "legosdb.h"

#else	/* GEOS version below */

#include "mystdapp.h"
#include <Ansi/stdio.h>
#include <Ansi/ctype.h>
#include <Ansi/string.h>
#include <timedate.h>
#include <localize.h>
#include <system.h>

#include <lmem.h>
#include <hash.h>
#include <chunkarr.h>

#include <Legos/runheap.h>
#include <Legos/fido.h>

#include "sst.h"
#include "mystdapp.h"
#include "runint.h"
#include "stack.h"
#include "mymath.h"
#include "math.h"
#include "prog.h"
#include "rheapint.h"
#include "builtin.h"

#include "profile.h"
#include "fixds.h"
#include "fidoint.h"
#endif

#define RMS (*rms)

#define MAX_FAST_BUF_SIZE 128

/* FIXME: move */
/* because ent.goh is a .goh file :( */
typedef struct 
{
    LegosType	CD_type;
    LegosData	CD_data;
} ComponentData;

static RunHeapToken
MakeRHString(RMLPtr rms, TCHAR* str);

#ifndef LIBERTY
static Boolean
FRM_CheckRTask(RMLPtr rms, TCHAR* full_ml, RTaskHan rtaskHan);
#endif

static void
FRM_CallInitSafely(RMLPtr rms, RTaskHan found_task);

#ifdef __BORLANDC__
#define strlen StrFuncStrLen



/*********************************************************************
 *			StrFuncStrLen
 *********************************************************************
 * SYNOPSIS:	local copy of strlen
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 6/ 9/95	Initial version
 * 
 *********************************************************************/
#pragma warn -rvl
int strlen(TCHAR *s)
{
asm {	push	es			}
asm {	push	di			}
/*asm {	les	di, ss:[bp][6]		}*/
asm {	les	di, s			}		
asm {	mov	cx, -1			}
asm {	mov	ax, 0			}
#ifdef DO_DBCS
asm {	repne	scasw			}
#else
asm {	repne	scasb			}
#endif
asm {	not	cx			}
asm {	dec	cx			}
asm {	xchg	ax, cx			}
asm {	pop	di			}
asm {	pop	es			}
}
#pragma warn +rvl
#endif


#ifdef LIBERTY
/* workaround a GHS compiler bug for exporting const arrays, the GHS
   compiler thinks the array is in .sdata, which is wrong and winds
   up crashing */
const BuiltInVector *
GetBuiltInFunction(int funcNumber) {
    ASSERT((funcNumber >= 0) && (funcNumber < NUM_BUILT_IN_FUNCTIONS));
    return BuiltInFuncs[funcNumber];
};
#endif


/*********************************************************************
 *			MakeRHString
 *********************************************************************
 * SYNOPSIS:	Return a runheap element containing a string
 * CALLED BY:	INTERNAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/26/96  	Initial version
 * 
 *********************************************************************/
static RunHeapToken
MakeRHString(RMLPtr rms, TCHAR* str)
{
    RunHeapToken	key;
    LONLY(USE_IT(rms));
    key = RunHeapAlloc(rms->rhi, RHT_STRING, 1,
		       (strlen(str)+1)*sizeof(TCHAR), str);
    return key;
}

/*********************************************************************
 *			FunctionRaiseEvent -d-
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	RunMainLoop (through OP_BUILT_IN_FUNC_CALL)
 * PASS:	stack: struct <event args> event-name #args TOS
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	FIXME: uses static buffers unsafely
 *	1. Remove event-name from stack
 *	2. Convert struct to component
 *	3. Construct event handler name using struct and event-name.
 *	   call it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 4/20/95	Initial version			     
 * 
 *********************************************************************/
#define EVENT_MAX_LEN 80
void
FunctionRaiseEvent(register RMLPtr rms, BuiltInFuncEnum id)
{
    TCHAR	event[EVENT_MAX_LEN+1];	/* Full event name: "myComp_clicked" */
    TCHAR*	cp;
    dword	eventNum;
    RunTask*	rt;
    word	numArgs;
    RunHeapToken aggStruct;
    RVal	rvEvent;

    byte*	strucP;
    MemHandle	loadModule;
    dword	proto;

    USE_IT(id);

    ASSERT(TopType() == TYPE_INTEGER);
    numArgs = PopData();
    PopTypeV();
    
    if (NthType(1) != TYPE_STRING || NthType(numArgs) != TYPE_STRUCT)
    {
	/* First arg - event name, last arg - aggregate struct */
	RunSetError(rms->ptask, RTE_BAD_PARAM_TYPE);
	return;
    }
	
    PopVal(rvEvent);

    aggStruct = NthData(numArgs-1);
    NthData(numArgs-1) = STRUCT_TO_AGG(aggStruct);
    NthType(numArgs-1) = TYPE_COMPONENT;
	
    /* Grab the loadModule and proto fields */
    RunHeapLock(rms->rhi, aggStruct, (void**)(&strucP));

    EC_ERROR_IF(strucP[AF_LOAD_MODULE*5+4]!= TYPE_MODULE ||
		strucP[AF_PROTO*5     +4] != TYPE_STRING, RE_FAILED_ASSERTION);
    FieldNMemHandle(strucP, AF_LOAD_MODULE, loadModule);
    FieldNDword(strucP, AF_PROTO, proto);

    RunHeapUnlock(rms->rhi, aggStruct);

    if(loadModule == NullHandle) {
	RunSetError(rms->ptask, RTE_NOT_AGGREGATE_MODULE);
	return;
    }

    if(proto == NullHandle) {
	RunSetError(rms->ptask, RTE_ARG_NOT_A_STRING);
	return;
    }

    /* Push the new number of arguments... */
    PushTypeData(TYPE_INTEGER, numArgs-1);

    RunHeapLock(rms->rhi, proto, (void**)(&cp));
    strcpy(event, cp);
    RunHeapUnlock(rms->rhi, proto);

    strcat(event, _TEXT("_"));

    RunHeapLock(rms->rhi, rvEvent.value, (void**)(&cp));
    strcat(event, cp);
    RunHeapDecRefAndUnlock(rms->rhi, rvEvent.value, cp);

    EC_ERROR_IF(strlen(event) > EVENT_MAX_LEN, RE_FAILED_ASSERTION);

    /* 3. Try and find the function in the other module
     */
    rt = (RunTask*)MemLock(loadModule);
#ifdef LIBERTY
    eventNum = SSTLookup(rt->RT_stringFuncTable, event,
                         rt->RT_stringFuncCount);
#else
    eventNum = SSTLookup(rt->RT_stringFuncTable, event);
#endif
    MemUnlock(loadModule);
    if (eventNum == SST_NULL)
    {
	/* clean up the stack and exit.  We know that the top is an
	 * integer (# args) and the last arg is an aggregate component,
	 * so unroll the first and last iteration */
	numArgs -= 2;
	PopValVoid();
	while (numArgs--) {
	    if (RUN_HEAP_TYPE_CT(TopType())) {
		RunHeapDecRef(rms->rhi, TopData());
	    } else if (TopType() == TYPE_COMPONENT && COMP_IS_AGG(TopData())) {
		RunHeapDecRef(rms->rhi, AGG_TO_STRUCT(TopData()));
	    }
	    PopValVoid();
	}
	RunHeapDecRef(rms->rhi, AGG_TO_STRUCT(TopData()));
	PopValVoid();
	return;
    }

    /* I assume all events are procedures. Safe?! */
    RunSwitchFunctions(rms, loadModule, eventNum,
		       (RunSwitchCheck)(RSC_NUM_ARGS | 
					RSC_PROC | 
					RSC_TYPE_ARGS));
    return;
}

/*********************************************************************
 *			FunctionCurModule -d-
 *********************************************************************
 * SYNOPSIS:	A little hack to return current module.
 * CALLED BY:	RunMainLoop (through OP_BUILT_IN_FUNC_CALL)
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 3/ 6/95	Initial version			     
 * 
 *********************************************************************/
void
FunctionCurModule(register RMLPtr rms, BuiltInFuncEnum id)
{
    USE_IT(id);
    PushTypeData(TYPE_MODULE, rms->rtask->RT_handle);
    return;
}

/*********************************************************************
 *			FunctionGetComplex -d-
 *********************************************************************
 * SYNOPSIS:	Return vm tree by calling into fido
 * CALLED BY:	RunMainLoop (through OP_BUILT_IN_FUNC_CALL)
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 3/ 2/95	Initial version			     
 * 
 *********************************************************************/
void
FunctionGetComplex(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvInt;
    RunHeapToken complex = NULL_TOKEN;
    GONLY(LegosComplex lc);
    Boolean	success;
    USE_IT(id);

    PROFILE_START_SECTION(PS_FUNC_GET_COMPLEX);

    PopVal(rvInt);
    if (rvInt.type != TYPE_INTEGER) {
	RunSetError(rms->ptask, RTE_BAD_PARAM_TYPE);
	return;
    }

#ifdef LIBERTY
    success = (Boolean)FidoGetComplexData(rms->rtask,
					  (word)rvInt.value, &complex);
    ASSERTS_WARN(success, "FidoGetComplexData failed.");
#else
    lc.LC_vmfh = rms->ptask->PT_vmFile;
    success = FidoGetComplexData(rms->rtask->RT_fidoTask,
				 rms->rtask->RT_fidoModule,
				 (word)rvInt.value,
				 lc.LC_vmfh,
				 &lc.LC_chain,
				 &lc.LC_format);
    if (success) {
	complex = RunHeapAlloc(rms->rhi, RHT_COMPLEX, 1,
			       sizeof(LegosComplex), &lc);
    }
#endif

    PushTypeData(TYPE_COMPLEX, complex);

    PROFILE_END_SECTION(PS_FUNC_GET_COMPLEX);
    return;
}

/*********************************************************************
 *			FunctionStringCommon -d-
 *********************************************************************
 * SYNOPSIS:	provide some basic string BuiltInFuncEnum
 * CALLED BY:	RunMainLoop (through OP_BUILT_IN_FUNC_CALL)
 * RETURN:	a string on the run time stack
 * SIDE EFFECTS:
 *
 * STRATEGY:	    all these BuiltInFuncEnum create new strings that get added
 *		    to the string constant table
 *
 *		    LEFT takes two arguments, a string (s) 
 *			    and an integer (n)
 *			and returns the left most n characters of s as a 
 *			new string on the stack
 *
 *		    RIGHT takes two arguments, a string (s) 
 *			    and an integer (n)
 *			and returns the right most n characters of s as a 
 *			new string on the stack
 *
 *		    MID takes 3 arguments, a string (s) 
 *			    an integer for the start index (start)
 *			    and an integer (n)
 *			and returns the n characters of s starting at start 
 *			as new string on the stack
 *
 *		    SPACE takes 1 integer argument (n) and returns a string
 *			of n spaces long
 *
 *		We pop arguments from last to first.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/ 9/95	Initial version			     
 * 
 *********************************************************************/
void
FunctionStringCommon(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvN, rvKey;
    word	start = 0;
    word	n = 0, len;
    RunHeapToken newKey;
    TCHAR	*str;
    TCHAR       *buf;

    PROFILE_START_SECTION(PS_FUNC_STRING_COMMON);

    PopVal(rvN);

    if (rvN.type != TYPE_INTEGER)
    {
	rvN.type = AssignTypeCompatible(TYPE_INTEGER, rvN.type, &rvN.value);
	if (rvN.type != TYPE_INTEGER) 
	{
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	    PROFILE_END_SECTION(PS_FUNC_STRING_COMMON);
	    return;
	}
    }
    else {    
	n = rvN.value;
    }


    /* only MID has 3 arguments; the extra one (start) comes in the middle
     */
    if (id == FUNCTION_MID)
    {
	RVal	rvStart;

	PopVal(rvStart);

	if (rvStart.type != TYPE_INTEGER)
	{
	    rvStart.type = AssignTypeCompatible(TYPE_INTEGER, rvStart.type,
					     &rvStart.value);
	    if (rvStart.type != TYPE_INTEGER)
	    {
		RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
		PROFILE_END_SECTION(PS_FUNC_STRING_COMMON);
		return;
	    }
	}
	else {
	    start = rvStart.value;
	}

	/* basic's start is 1 based, and we are 0 based here */
	if (start == 0) {
	    RunSetError(rms->ptask, RTE_BAD_STRING_INDEX);
	    PROFILE_END_SECTION(PS_FUNC_STRING_COMMON);
	    return;
	}
	start -= 1;
    }

    /* the first argument is always the string */
    if (id != FUNCTION_SPACE)
    {
	PopVal(rvKey);

	if (rvKey.type != TYPE_STRING)
	{
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_STRING);
	    PROFILE_END_SECTION(PS_FUNC_STRING_COMMON);
	    return;
	}

	/* now lets get down to business */
	RunHeapLock(rms->rhi,rvKey.value, (void**)(&str));
	EC_ERROR_IF(str == NULL, RE_FAILED_ASSERTION);
	len = strlen(str);
    }
    else
    {
	len = n;
	if ((sword)n < 0) {
	    n = 0;
	}
    }

    /* at this point, start > len only if (id == FUNCTION_MID) */
    if (start > len)
    {
	start = len;
    }
    else if (id == FUNCTION_RIGHT)
    {
	if (len > n) {
	    start = len - n;
	}
    }

    /* if the number of characters requested is longer than the string
     * just return the whole string
     */
    if (n > len - start) {
	n = len - start;
    }

    if (n) 
    {
	newKey = RunHeapAlloc(rms->rhi, RHT_STRING, 1, 
			      (n+1) * sizeof(TCHAR), NULL);

	if (!newKey) {		/* Catch allocation error */
	    LONLY(EC_WARN("Legos BASIC string function - allocation error"));
	    RunSetError(rms->ptask, RTE_OUT_OF_MEMORY);
	    RunHeapUnlock(&(rms->ptask->PT_runHeapInfo), newKey);
	    return;
	}

    	/* God this is annoying. Allocation can invalidate pointers... */

	if (id == FUNCTION_SPACE)
	{
	    int i;
	    RunHeapLock(&(rms->ptask->PT_runHeapInfo), newKey, (void**)(&buf));
	    for(i = 0; i < n; i++) {
		buf[i] = C_SPACE;
	    }
	    buf[n] = C_NULL;
	}
	else
	{
#ifndef LIBERTY
	    if (SAME_HEAP_BLOCK((RunHeapToken)newKey, 
				(RunHeapToken)rvKey.value)) {
		str = (TCHAR*)RunHeapDeref(&(rms->ptask->PT_runHeapInfo),
					   (RunHeapToken) rvKey.value);
	    }
#endif
	    RunHeapLock(&(rms->ptask->PT_runHeapInfo), newKey, (void**)(&buf));
	    EC_ERROR_IF(str[start] == C_NULL, RE_FAILED_ASSERTION);
	    strncpy(buf, str+start, n);
	    buf[n] = C_NULL;
	    RunHeapDecRefAndUnlock(rms->rhi, rvKey.value, str);
	}

	EC_ERROR_IF(strlen(buf) != n || buf[n] != C_NULL, RE_FAILED_ASSERTION);
	RunHeapUnlock(&(rms->ptask->PT_runHeapInfo), newKey);

	/* Differentiate the string as being dynamic by adding the
	   dynamic tag... */

    }
    else
    {
	newKey = EMPTY_STRING_KEY;
	if (id != FUNCTION_SPACE) {
	    RunHeapDecRefAndUnlock(rms->rhi,rvKey.value, str);
	}
    }

    /* now push the result onto the stack an we are done! */
    PushTypeData(TYPE_STRING, newKey);
    PROFILE_END_SECTION(PS_FUNC_STRING_COMMON);
}

/*********************************************************************
 *			FunctionStringInstr -d-
 *********************************************************************
 * SYNOPSIS:	implementation of the basic INSTR function
 * CALLED BY:	
 * RETURN:	ON STACK: 0 if not found, otherwise offset of substring
 *	    	    	    in main string (1 based)
 *	    	NOTE: a null subAnsi/string.has a return value of 1
 * SIDE EFFECTS:
 * STRATEGY:	look for a sub string of s1 in s2
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/ 9/95	Initial version			     
 * 
 *********************************************************************/
void 
FunctionStringInstr(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvKey, rvKey2;		
    TCHAR	*str, *substr, *cp, *cp2;
    int		len;
    dword	retval = 0;
    USE_IT(id);

    PROFILE_START_SECTION(PS_FUNC_STRING_INSTR);

    /* the first argument popped is always the substring */
    if (NthType(1) != TYPE_STRING || NthType(2) != TYPE_STRING)
    {
	RunSetError(rms->ptask, RTE_ARG_NOT_A_STRING);
	return;
    }
    PopVal(rvKey);

    RunHeapLock(rms->rhi,rvKey.value, (void**)(&substr));
    len = strlen(substr);

    /* the second argument popped is always the string */
    PopVal(rvKey2);

    RunHeapLock(rms->rhi,rvKey2.value, (void**)(&str));


    /* the defined behavior for a null substring is to return 1 */
    if (!len) {
	retval = 1;
    } else {

	/* now search for match
	 */
	cp = str;

	/* we are going to run through looking for the first character of the
	 * second string in the first string, and each time we find one, we
	 * will do the full string compare
	 */
	while(1)
	{
	    cp2 = strchr(cp, substr[0]);
	    if (cp2 == NULL)
	    {
		break;
	    }

	    if (!strncmp(cp2, substr, len))
	    {
		/* return 1 based offset */
		retval = (cp2 - str + 1);
		break;
	    }
	    cp = cp2+1;
	}
    }
    RunHeapDecRefAndUnlock(rms->rhi, rvKey2.value,str);
    RunHeapDecRefAndUnlock(rms->rhi, rvKey.value, substr);

    /* now lets push our boolean result as an integer */
    PushTypeData(TYPE_INTEGER, retval);
    PROFILE_END_SECTION(PS_FUNC_STRING_INSTR);

}


/*********************************************************************
 *			FunctionStringStrComp -d-
 *********************************************************************
 * SYNOPSIS:	Implement STRCOMP, comparing two strings.
 *		Return 0 if equal, -1 if first < second,
 *		or 1 if second > first.
 *		
 *		Currently case sensitive...
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 3/22/95	Initial version			     
 * 
 *********************************************************************/
void
FunctionStringStrComp(RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvS1, rvS2, rvCase;
    TCHAR	*s1, *s2;
    int		result;
    USE_IT(id);

    PROFILE_START_SECTION(PS_FUNC_STRING_STR_COMP);

    if (NthType(1) != TYPE_INTEGER) {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_INTEGER);
	return;
    }
    if (NthType(2) != TYPE_STRING || NthType(3) != TYPE_STRING) {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_STRING);
	return;
    }

    PopVal(rvCase);
    PopVal(rvS2);
    PopVal(rvS1);

    RunHeapLock(rms->rhi,rvS1.value, (void**)(&s1));
    RunHeapLock(rms->rhi,rvS2.value, (void**)(&s2));

    EC_BOUNDS(s1);
    EC_BOUNDS(s2);

    if ((word)rvCase.value)
    {
	/* case insensitive compare (NULL terminated) */
#ifdef LIBERTY
	/* I don't know if liberty has a case-insensitive compare */
	TCHAR	*t1, *t2;

	t1 = s1; t2 = s2;
	result = 0;
	/* loop until they differ */
	while (*t1 && *t2)
	{
	    if (toupper(*t1) != toupper(*t2)) 
	    {
		break;
	    }
	    t1++; t2++;
	}
	result = *t1 - *t2;
#else
	result = LocalCmpStringsNoCase(s1, s2, 0);
#endif
    } else {
	/* case sensitive compare (NULL terminated) */
#ifdef LIBERTY
	result = strcmp(s1, s2);
#else
	result = LocalCmpStrings(s1,s2, 0);
#endif
    }
    
    if (result < 0) {
	result = -1;
    }
    if (result > 0) {
	result = 1;
    }

    RunHeapDecRefAndUnlock(rms->rhi, rvS1.value,s1);
    RunHeapDecRefAndUnlock(rms->rhi, rvS2.value,s2);

    PushTypeData(TYPE_INTEGER, result);
    PROFILE_END_SECTION(PS_FUNC_STRING_STR_COMP);
    return;
}

/*********************************************************************
 *			FunctionStringAscLen -d-
 *********************************************************************
 * SYNOPSIS:	implementation of the basic ASC and LEN BuiltInFuncEnum
 * CALLED BY:	
 * RETURN:	relavent values depending on the function
 * SIDE EFFECTS:
 * STRATEGY:	these routines take a string and return a number
 *
 *		ASC: returns the ascii value of the first character in the
 *		     string
 *
 *		LEN: returns the length of the string
 *
 *		VAL: returns the value of numerical string
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/ 9/95	Initial version			     
 * 
 *********************************************************************/
void FunctionCommonStringToNumber(RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvKey;
    LegosType	returnType = TYPE_INTEGER;
    TCHAR	*str;
    dword	retval=0;

    PROFILE_START_SECTION(PS_FUNC_COMMON_STRING_TO_NUM);

    if (TopType() != TYPE_STRING) {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_STRING);
	return;
    }

    /* the first argument popped is always the substring */
    PopVal(rvKey);

    RunHeapLock(rms->rhi,rvKey.value, (void**)(&str));
    switch (id)
    {
	case FUNCTION_LEN:
	    retval = strlen(str);
	    break;
	case FUNCTION_ASC:
	    retval = str[0];
	    break;
	case FUNCTION_VAL:
	{
	    int err=FALSE;

	    /* Make up your mind: added "&& 0" because this "EC" code
	       makes this routine behave differently between EC and
	       non-EC, and since Liberty is run mostly in EC things
	       get filed as bugs. -matta */
#if ERROR_CHECK && 0
	    int	    i, len, isInt=FALSE;
	    long    val=1;
	    TCHAR   *cp;

	    USE_IT(isInt);
	    len = strlen(str);
	    cp = str;
	    for (i = 0; i < len; i++)
	    {
		if (*cp < C_ZERO || *cp > C_NINE)
		{
		    if (i || !(*cp == C_PLUS || *cp == C_MINUS)) {
			isInt = FALSE;
		    } else {
			val *= -1;
		    }
		    
		    if (*cp != C_PERIOD && *cp != C_MINUS && *cp != C_PLUS
			&& *cp != C_CAP_E && *cp != C_SMALL_E)
		    {
			err = TRUE;
			*(float *)&retval = 0;
			returnType = TYPE_FLOAT;
			break;
		    }
		}
#if 0
		else if (isInt) 
		{
		    if ((unsigned long)val < 429000000L) 
		    {
			val = val * 10;
			val += *str - C_ZERO;
		    } 
		    else 
		    {
			isInt = FALSE;
		    }
		}
#endif
		cp++;
	    }
#endif
	    if (!err)
	    {
#if 0
		if (isInt)
		{
		    retval = val;
		    if ((unsigned long)val < 65535L) {
			returnType = TYPE_INTEGER;
		    } else {
			returnType = TYPE_LONG;
		    }
		}
		else
#endif
		{
#ifdef LIBERTY
		    {
			char buffer[100];
			TCHAR* get = str;
			char* put = buffer;
			int i;
			/* Skip past any whitespace at the beginning */
			while (isspace(*get)) {
			    get++;
			}
			/* Copy what we can into a temporary SBCS buffer. */
			for (i = 0; i < 99; i++) {
			    *put++ = *get++;
			    if (!*get) {
				break;
			    }
			}
			*put = 0;
			*(float*)(&retval)= strtod(buffer, NULL);
		    }
#ifdef EC_DEBUG_SERCOMP
		    if(myLog == NULL) {
			myLog = new Log("arraylog", 37000, WRAP_AT_END);
			EC(HeapSetTypeAndOwner(myLog, "SLOG", 0));
			Result r = myLog->Initialize();
			ASSERT(r == SUCCESS);
		    }
		    char *tmp = new char[strlen(str) + 1];
		    EC(HeapSetTypeAndOwner(tmp, "SXYZ", 0));
		    strcpy(tmp, str);
		    myLog->Write("VAL(%s,%s,%s) = %.1f,%.1f,%.1f\n", 
				 tmp, tmp, tmp,
				 *(float*)&retval, *(float*)&retval, 
				 *(float*)&retval);
		    delete tmp;
#endif

#else	/* GEOS */
	    
		    if (FloatAsciiToFloat(FAF_PUSH_RESULT, 
					  strlen(str), str, NULL))
		    {
			*(float *)&retval = 0;
		    }
		    FloatGeos80ToIEEE32((float *)&retval);
#endif /* ifdef LIBERTY */
		    returnType = TYPE_FLOAT;
		}
	    }
	}
        default:    	    /* mchen, LIBERTY, added to surpress warning */
	    break;
    }
    RunHeapDecRefAndUnlock(rms->rhi, rvKey.value, str);

    /* now lets push our boolean result as an integer */
    PushTypeData(returnType, retval);
    PROFILE_END_SECTION(PS_FUNC_COMMON_STRING_TO_NUM);
}

/*********************************************************************
 *		FunctionCommonNumberToString -d-
 *********************************************************************
 * SYNOPSIS:	basic BuiltInFuncEnum that convert numbers to strings
 * CALLED BY:	RunMainLoop through OP_BUILT_IN_FUNC_CALL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	    deal with functionos that take numbers and return strings
 *
 *		    CHR: convert the ascii value to a string of length 1
 *
 *		    OCT: convert a value to the octal string for the value
 *
 *		    HEX: convert a value to the hex string for the value
 *
 *		    STR: convert a value into a decimal string
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/ 9/95	Initial version			     
 * 
 *********************************************************************/

// #define MAX_PRECISION 12
#define MAX_PRECISION 7   // float 32 (pg.19 of Borland Programmer's Guide)

void
FunctionCommonNumberToString(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvVal;
    LegosType	casttype;
    RunHeapToken key;
    sdword	n, prec = 0; 	/* mchen, LIBERTY, set initial value to
				   surpress warning */
    TCHAR	*buf;
    TCHAR	fastbuf[MAX_FAST_BUF_SIZE];
    MemHandle	buf_han = NullHandle; /* mchen, LIBERTY, set initial value to
					 surpress warning */
    Boolean	isStrFloat;

    union {
	sdword	integer;
	dword	gen_dword;
	float	flt;
    } number;

    PROFILE_START_SECTION(PS_FUNC_COMMON_STRING_TO_NUM);

    /* the last argument is a number.  If we're converting to a string,
     * for now just always coerce it to a float first.
     */

    /* the first argument popped is always the substring */
    PopVal(rvVal);

    if (id == FUNCTION_STR && rvVal.type == TYPE_FLOAT) 
    {
	isStrFloat = TRUE;
	casttype = TYPE_FLOAT;
    } 
    else 
    {
	isStrFloat = FALSE;
	if (rvVal.type == TYPE_INTEGER || rvVal.type == TYPE_FLOAT) 
	{
	    casttype = TYPE_LONG;
	    rvVal.type = AssignTypeCompatible(casttype, rvVal.type, 
					      &rvVal.value);
	    if (rvVal.type == TYPE_ILLEGAL || rms->ptask->PT_err)
	    {
		RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
		PushTypeData(rvVal.type, rvVal.value); /* for cleanup */
		return;
	    }
	} 
	else if (rvVal.type != TYPE_LONG)
	{
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	    PushTypeData(rvVal.type, rvVal.value); /* for cleanup */
	    return;
	}
	else
	{
	    casttype = rvVal.type;
	}
    }

    number.gen_dword = rvVal.value;

    /* now since want to add a new string to the same table the old string
     * is from, we need to copy out the old string, and unlock it before
     * adding the new one
     * now I am optimizing for small strings by storing them on the stack
     * rather than allocating a MemBlock for them
     */
    if (isStrFloat)
    {
#ifdef AUTOCALC_FLOAT_PRECISION        // Warning: accuracy problems...
	float		f, d;
	int		remainder;

	/* if its the STR function, the size of the buffer needs to be
	 * large enough to contain the string, which determined by the
	 * precision which is calculated here
	 */
	n = (dword)number.flt;

	/* get the value in nval */

	f = fabs(number.flt);
	/* cycle through until precision is found */
	d = 1.0;
	for ( remainder = 0; remainder < MAX_PRECISION; ++remainder )
	{
	    if ( fmod( f, d ) < 0.0000001 )
	    {
		prec = remainder;
		break;
	    }
	    d /= 10;
	}
#endif 
	/* MAX_PRECISION is also the maximum number of characters before the
	 * decimal point, we also need some extra space for exponential
	 * notation when needed, MAX_PRECISION * 2 should be a good size
	 */
	prec = MAX_PRECISION - 1;       // hard-code precision for float 32
	n    = prec + (MAX_PRECISION << 1);
    }
    else 
    {
	/* the longest string would have to contain the octal value of
	 * 2^32 which is about 12 digits or so, 24 wil be more than enough
	 */
	n = 24 * sizeof(TCHAR);
    }

    if (n < MAX_FAST_BUF_SIZE)
    {
	buf = fastbuf;
    }
    else
    {
	buf_han = (MemHandle)MemAlloc((n+1) * sizeof(TCHAR), 
				      HF_SWAPABLE | HF_SHARABLE, 
				      HAF_ZERO_INIT | HAF_LOCK);
	buf = (TCHAR*)MemDeref(buf_han);
    }


    switch (id) 
    {
	case FUNCTION_HEX:
    	{
	    int	index;
	    SET_DS_TO_DGROUP;
	    /* sprintf does silly things with negative numbers, so deal with
	     * it by hand
	     */
	    if ((sdword)number.integer < 0L ) {
		number.integer = -number.integer;
		*buf = C_MINUS;
		index = 1;
	    } else {
		index = 0;
	    }
	    sprintf( buf + index, _TEXT("%lX"), number.integer);
	    RESTORE_DS;
	}
	    break;
	case FUNCTION_OCT:
	{
	    long    oval;
	    TCHAR    *s1;

	    oval = 8;
	    s1 = buf;

	    /* for negative values, just insert a negative sign at the 
	     * beginning and treat it like a positive number
	     */
	    n = number.gen_dword;
	    if (n < 0) 
	    {
		*s1++ = C_MINUS;
		n = -n;
	    }

	    while(oval <= n)
	    {
		oval *= 8;
	    }

	    while(oval > 1)
	    {
		int	x;

		oval /= 8;
		x = (int)(n/oval);
		*s1++ = x + C_ZERO;
		n = (int)(n - (oval * x));
	    }
	    *s1 = C_NULL;
	}
	    break;
	case FUNCTION_CHR:
	    if (isprint(number.integer))
	    {
		buf[0] = number.integer;
		buf[1] = C_NULL;
	    }
	    else
	    {
		buf[0] = C_NULL;
	    }
	    break;

	case FUNCTION_STR:
	{
	    /* now convert the number to a string using the precision 
	     * calculated above
	     */
	    if (casttype == TYPE_FLOAT) 
	    {
#ifdef LIBERTY
		/* ARGH, a hack until our sprintf works with floats */
		char tmpbuf[80];
		char *point;
		char *end;
		/* FIXME: there is a bug in GHS sprintf() when dealing
                   with negative floats */
		if(number.flt < 0) {
	 	    sprintf(tmpbuf, "-%f", -number.flt);
		} else {
	 	    sprintf(tmpbuf, "%f", number.flt);
		}
		/* Get rid of trailing 0's after the decimal point,
		   and possibly the decimal point itself. */
		point = strrchr(tmpbuf, '.');
		if (point) {
		    end = strrchr(tmpbuf, '0');
		    if (end) {
			while (point <= end && 
			       (*end == '0' || *end == '.')) {
			    *end-- = '\0';
			}
		    }
		}
		strcpy(buf,tmpbuf);	/* char to TCHAR */
/*		sprintf(buf, (TCHAR*)L"%f", number.flt); */
#else
		FloatIEEE32ToGeos80(&(number.flt));
		FloatFloatToAscii_StdFormat(buf, NULL, FFAF_NO_TRAIL_ZEROS, 
					    MAX_PRECISION, prec);
#endif
	    }
	    else
	    {
		TCHAR	*buf2;

		/* deal with negative numbers here as UtilHex32ToAscii
		 * doesn't 
		 */
		buf2 = buf;
#ifdef LIBERTY
#ifdef EC_DEBUG_SERCOMP
if(myLog == NULL) {
    myLog = new Log("arraylog", 37000, WRAP_AT_END);
    EC(HeapSetTypeAndOwner(myLog, "SXYZ"));
    Result r = myLog->Initialize();
    ASSERT(r == SUCCESS);
}
*myLog << '(' << number.integer << ',' << number.integer << ',' << number.integer << ')';
#endif
		sprintf(buf2, _TEXT("%d"), number.integer);
#ifdef EC_DEBUG_SERCOMP
*myLog << '(' << buf2 << ',' << buf2 << ',' << buf2 << ')';
#endif
#else	/* GEOS version below */
		if (number.integer < 0L)
		{
		    *buf2++ = C_MINUS;
		    number.integer = -number.integer;
		}
		UtilHex32ToAscii(buf2, number.gen_dword, UHTAF_NULL_TERMINATE);
#endif
	    }
	}
        default:    	/* mchen, LIBERTY, added to surpress warning */
	break;
    }

    /* for now just add strings like there was no tomorrow, and never 
     * delete them
     */
    key = MakeRHString(rms, buf);

    /* free up memory for long strings */
    if (buf != fastbuf)
    {
        ECL(MemUnlock(buf_han));
	MemFree(buf_han);
    }

    PushTypeData(TYPE_STRING, key);
    PROFILE_END_SECTION(PS_FUNC_COMMON_STRING_TO_NUM);
}

/*********************************************************************
 *		FunctionMathCommon -d-
 *********************************************************************
 * SYNOPSIS:	a common routine to handle all the math stuff
 * CALLED BY:	RunMainLoop through OP_BUILT_IN_FUNC_CALL
 * RETURN:	a floating point value on the run time stack
 * SIDE EFFECTS:
 * STRATEGY:	do whatever math function is being called and return the value
 *
 *
 *			RND: random value [0..1)
 *
 *		all these routines take a floating point argument n
 *		NOTE: pow takes a second argument for the exponent
 *
 *			ABS: absolute value of n
 *			COS: cosine of n
 *			SIN: sine of n
 *			SQR: square root of n
 *			SGN: sign of n (-1 for < 0, 0 for 0 and 1 for > 0)
 *			EXP: exponential (e to the n)
 *			POW: power function (n to the m)
 *			ATN: arc tangent of n
 *			INT: integer value of n
 *			LOG: log of n
 *			TAN:  tangent of n
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/10/95	Initial version			     
 * 
 *********************************************************************/
void
FunctionMathCommon(RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvNum;
    RVal	rvM;
    float	n, retval;

    PROFILE_START_SECTION(PS_FUNC_MATH_COMMON);

    if (id != FUNCTION_RND)
    {
	/* the last argument is a number, since its the second argument
	 * it gets pushed last, and thus popped first
	 */
	PopVal(rvNum);

	rvNum.type = AssignTypeCompatible(TYPE_FLOAT, rvNum.type, &rvNum.value);
	if (rvNum.type == TYPE_ILLEGAL || rms->ptask->PT_err)
	{
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	    PushTypeData(rvNum.type, rvNum.value); /* for cleanup */
	    return;
	}
	n = *(float*)(&rvNum.value);

	switch (id)
	{
	    case FUNCTION_ABS:
		retval = fabs(n);
		break;
	    case FUNCTION_SIN:
		retval = sin(n);
		break;
	    case FUNCTION_COS:
		retval = cos(n);
		break;
	    case FUNCTION_SGN:
		if (n == 0.0) {
		    retval = n;
		} else if ( n > 0.0 ) {
		    retval = 1.0;
		} else {
		    retval = -1.0;
		}
		break;
	    case FUNCTION_SQR:
		retval = sqrt(n);
		break;
	    case FUNCTION_ATN:
		retval = atan(n);
		break;

	    case FUNCTION_INT:
		retval = floor (n);
		break;
	    case FUNCTION_LOG:
		retval = log (n);
		break;
	    case FUNCTION_EXP:
		/* the limit for 32 bit floats is 0x59 so just check
		 * for that
		 */
		if (n > 0x59 || n < -(0x59)) {
		    RunSetError(rms->ptask, RTE_OVERFLOW);
		    return;
		} else {
		    retval = exp(n);
		}
		break;
	    case FUNCTION_POW:
	    {
		PopVal(rvM);

		rvM.type = AssignTypeCompatible(TYPE_FLOAT, rvM.type,
						&rvM.value);
		if (rvM.type == TYPE_ILLEGAL || rms->ptask->PT_err)
		{
		    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
		    PushTypeData(rvM.type, rvM.value); /* for cleanup */
		    return;
		}
		retval = pow(*(float*)(&rvM.value), n);
	    }
		break;
	    case FUNCTION_TAN:
		retval = tan(n);
	    default:
#if ERROR_CHECK
		EC_ERROR(-1);
#endif
		break;
	}
    }
    else
    {
#ifdef LIBERTY
	/* ANSI has a RAND_MAX that we should probably use here, but
	   the SunOS 4 doesn't provide it, so we use the lowest common
	   denominator here.  This math insures that retval gets
	   [0..1) even when rand() returns values up to
	   0xffffffff. This also prevents overflow when casting to
	   float when RAND_MAX is 0xffffffff */
	retval = (float)(rand() & INT16_MAX) / (INT16_MAX + 1L);
#else
	FloatRandom();
	FloatGeos80ToIEEE32(&retval);
#endif
    }

    /* now lets push our result as an integer */
    PushTypeData(TYPE_FLOAT, *(dword *)&retval);

    PROFILE_END_SECTION(PS_FUNC_MATH_COMMON);

}

/*********************************************************************
 *		ModuleAlreadyLoadedLocally -d-
 *********************************************************************
 * SYNOPSIS:	Given a absolute module locator, check if any of the
 *		modules loaded by this one has the same module locator.
 *		If yes, then return the runtask for that module.  If not
 *		return NullHandle.
 * CALLED BY:	INTERNAL FunctionLoadModuleShared
 * RETURN:	Runtask handle
 * SIDE EFFECTS:
 * STRATEGY:
 *	Look through all loaded modules of this module to see if one
 *	of them matches the module locator given.  If so, return the
 *	runtask handle of that module.  If not, return NullHandle.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	9/11/96  	Initial version
 * 
 *********************************************************************/
// unused with optimized version
#if 0
#ifdef LIBERTY
static RTaskHan
ModuleAlreadyLoadedLocally(register RMLPtr rms, TCHAR *moduleLocatorToFind)
{
    RTaskHan *rtaskArr;
    RTaskHan result = NullHandle;
    word numTasks = rms->rtask->RT_childModules->GetCount();
    if (numTasks >= 1) {
	rtaskArr = (RTaskHan*)rms->rtask->RT_childModules->LockElement(0);
	for(int i = 0; i < numTasks; i++) {
	    if(FRM_CheckRTask(rms, moduleLocatorToFind, rtaskArr[i])) {
		result = rtaskArr[i];
		break;
	    }
	}
	rms->rtask->RT_childModules->UnlockElement(0);
    }
    return result;
} /* ModuleAlreadyLoadedLocally() */
#endif
#endif

/*********************************************************************
 *		ModuleAlreadyLoadedGlobally -d-
 *********************************************************************
 * SYNOPSIS:	Given a absolute module locator, check if any of the
 *		modules loaded globally has the same module locator.
 *		If yes, then return the runtask for that module.  If not
 *		return NullHandle.
 * CALLED BY:	INTERNAL FunctionLoadModuleShared
 * RETURN:	Runtask handle
 * SIDE EFFECTS:
 * STRATEGY:
 *	Look through all globally loaded modules to see if one
 *	of them matches the module locator given.  If so, return the
 *	runtask handle of that module.  If not, return NullHandle.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	mchen	9/11/96  	Initial version
 * 
 *********************************************************************/
// unused with optimized version
#if 0
#ifdef LIBERTY
static RTaskHan
ModuleAlreadyLoadedGlobally(register RMLPtr rms, TCHAR *moduleLocatorToFind)
{
    RTaskHan result = NullHandle;
    RTaskHan *rtaskArr = (RTaskHan*)MemLock(rms->ptask->PT_tasks);
    for(int i = 0; i < rms->ptask->PT_numTasks; i++) {
	if(FRM_CheckRTask(rms, moduleLocatorToFind, rtaskArr[i])) {
	    result = rtaskArr[i];
	    break;
	}
    }
    MemUnlock(rms->ptask->PT_tasks);
    return result;
} /* ModuleAlreadyLoadedGlobally() */
#endif
#endif

/*********************************************************************
 *		FunctionLoadModuleShared
 *********************************************************************
 * SYNOPSIS:	Load a module if it wasn't already loaded
 * CALLED BY:	EXTERNAL OP_BUILT_IN_FUNC
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Look through all loaded modules to see if a shared version
 *	has already been loaded.  If so, increment its use count and
 *	return that.  Otherwise, load a fresh copy.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/23/96  	Initial version
 * 
 *********************************************************************/
#define FRM_BUFFER_LEN 200

// Liberty uses a special optimized version, below
#ifndef LIBERTY
void
FunctionLoadModuleShared(register RMLPtr rms, BuiltInFuncEnum id)
{
    GONLY(MemHandle	mlBuf;)
    TCHAR	*old_ml, *full_ml;
    RVal	rvKey;

    GONLY(RTaskHan*	rtaskArr;)
    GONLY(word	i;)
    RTaskHan	found_task = NullHandle;
    Boolean	found_locally = FALSE;
    Boolean	call_init = FALSE;
    RunTask*	rtTemp;
    USE_IT(id);

    if (rms->rtask->RT_flags & RT_UNLOADING) {
	RunSetError(rms->ptask, RTE_CANT_LOAD_WHEN_UNLOADING);
	return;
    }

    if (TopType() != TYPE_STRING)
    {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_STRING);
	return;
    }
    PopVal(rvKey);

#ifdef LIBERTY
    /* check whether this module has already been loaded by this module */

    /* first check if the given module locator has a source already
       defined, so that it is a absolute path rather than a relative one */
    old_ml = (TCHAR*)LRunHeapLock(rvKey.value);
    TCHAR *ml = strchr(old_ml, _CHAR(':'));
    if((ml) && (ml[1] == _CHAR('/')) && (ml[2] == _CHAR('/'))) {
	/* yes this is an absolute path, just check it as is */
	full_ml = old_ml;
	found_task = ModuleAlreadyLoadedLocally(rms, full_ml);
	if(found_task != NullHandle) {
	    found_locally = TRUE;
	} else {
	    found_task = ModuleAlreadyLoadedGlobally(rms, full_ml);
	}
    } else {
	/* no, this is a relative path, we will have to append all elements
	   of the module loading search path to the old_ml and see if any
	   of these have already been loaded */

	/* allocate work space for string path checking */
	full_ml = new TCHAR[FRM_BUFFER_LEN];
	EC(HeapSetTypeAndOwner(full_ml, "FMLT"));
	if (full_ml == NULL) {
	    LRunHeapDecRefAndUnlock(rvKey.value);
	    /* Bad ml passed -- too big? */
	    RunSetError(rms->ptask, RTE_BAD_MODULE);
	    return;
	}

	/* first, add the loading module's source */
	Fido_MakeMLCanonical(rms->ptask->PT_fidoTask,
			     rms->rtask->RT_fidoModule,
			     old_ml, full_ml, FRM_BUFFER_LEN);

	/* check locally, and then globally */
	found_task = ModuleAlreadyLoadedLocally(rms, full_ml);
	if(found_task != NullHandle) {
	    found_locally = TRUE;
	} else {
	    /* check globally */
	    found_task = ModuleAlreadyLoadedGlobally(rms, full_ml);
	}

	if(found_task == NullHandle) {
	    /* not found using the current modules's source, now try 
	       the search path */
	
	    /* find how big of a buffer we need to get a copy of the path,
	       add an extra 1 for NULL terminator, plus an extra ';' we
	       add right before last NULL which helps us scan below */
	    uint32 pathLength = FidoGetPath(NULL, 0) + 2;
	    if(pathLength > 0) {
		TCHAR *searchPathCopy = new TCHAR[pathLength];
		EC(HeapSetTypeAndOwner(searchPathCopy, "FSPC"));
		TCHAR *searchPathPtr = searchPathCopy;
		if(searchPathCopy == NULL) {
		    LRunHeapDecRefAndUnlock(rvKey.value);
		    RunSetError(rms->ptask, RTE_BAD_MODULE);
		    delete[] full_ml;
		    return;
		}
		FidoGetPath(searchPathCopy, pathLength);

		/* replace terminating '\0' with ";\0" for easier scanning */
		searchPathCopy[pathLength-2] = _CHAR(';');
		searchPathCopy[pathLength-1] = 0;
		while(found_task == NullHandle) {
		    TCHAR *ml = strchr(searchPathPtr, _CHAR(';'));
		    if(ml == NULL) {
			break;
		    } else {
			/* null terminate the source name */
			*ml = 0;
			/* copy the source name to the full_ml buffer */
			strcpy(full_ml, searchPathPtr);
			/* move searchPathPtr to pointer after last :// */
			searchPathPtr = ml + 1;
			/* append the old_ml relative path to full_ml buffer */
			strcat(full_ml, old_ml);
			
			/* now check if loaded locally */
			found_task = ModuleAlreadyLoadedLocally(rms, full_ml);
			if(found_task != NullHandle) {
			    found_locally = TRUE;
			} else {
			    /* check globally */
			    found_task = ModuleAlreadyLoadedGlobally(rms, 
								     full_ml);
			}
		    }
		}
		delete[] searchPathCopy;
	    }
	}
	delete[] full_ml;

	/* if we haven't been able to find the module using any of the
	   search paths, then we will need to load the module */
	full_ml = old_ml;
    }

#else	/* GEOS version below, they do not have a path */
    mlBuf = MemAlloc(FRM_BUFFER_LEN*sizeof(TCHAR),
		     HF_DYNAMIC, HAF_STANDARD_LOCK);
    if (mlBuf == NullHandle) {
	/* Bad ml passed -- too big? */
	RunSetError(rms->ptask, RTE_BAD_MODULE);
	return;
    }
    full_ml = (TCHAR*)MemDeref(mlBuf);

    MemLock(rms->ptask->PT_fidoTask);

    /* Construct ML to search for
     */
    RunHeapLock(rms->rhi,rvKey.value, (void**)(&old_ml));
    Fido_MakeMLCanonical(rms->ptask->PT_fidoTask,
			 rms->rtask->RT_fidoModule,
			 old_ml, full_ml, FRM_BUFFER_LEN);
    RunHeapDecRefAndUnlock(rms->rhi, rvKey.value, old_ml);


    /* Check first in modules already loaded by this module.
     * If a module always uses Require() to get at its modules
     * we won't keep adding to the child list and incrementing
     * the module's use count
     */
    ;{
	ChunkArrayHeader*	cah;
	optr	children;
	word	numTasks;

	children = rms->rtask->RT_childModules;
	(void) MemLock(OptrToHandle(children));
	numTasks = ChunkArrayGetCount(children);
	rtaskArr = (RTaskHan*)ChunkArrayElementToPtr(children, 0, NULL);
	for (i=0; i<numTasks; i++)
	{
	    if (FRM_CheckRTask(rms, full_ml, rtaskArr[i])) {
		found_task = rtaskArr[i];
		found_locally = TRUE;
		break;
	    }
	}
	MemUnlock(OptrToHandle(rms->rtask->RT_childModules));
    }

    /* Check all modules created
     */
    if (found_task == NullHandle)
    {
	rtaskArr = (RTaskHan*)MemLock(rms->ptask->PT_tasks);
	for (i=0; i<rms->ptask->PT_numTasks; i++)
	{
	    if (FRM_CheckRTask(rms, full_ml, rtaskArr[i])) {
		found_task = rtaskArr[i];
		break;
	    }
	}
	MemUnlock(rms->ptask->PT_tasks);
    }

    MemUnlock(rms->ptask->PT_fidoTask);

#endif

    /* If newly loaded, push module, mark as shared, exec module_init
     * Otherwise, inc use count and push.
     */
    if (found_task == NullHandle)
    {
	found_task = RunLoadModuleLow(rms->ptask->PT_handle, full_ml,
				      rms->rtask->RT_uiParent,
				      rms->rtask->RT_fidoModule);
	if (found_task == NullHandle) {
	    GONLY(MemFree(mlBuf);)
	    RunSetError(rms->ptask, RTE_BAD_MODULE);
	    LONLY(LRunHeapDecRefAndUnlock(rvKey.value);)
	    return;
	}
	rtTemp = (RunTask*)MemLock(found_task);
	rtTemp->RT_shared = TRUE;
#if 1
/* FIXME HACK -- inherit RT_OWNED_BY_BUILDER flag, so aggs added to sn-delx
 * don't go away on "new module"
 */
	if (rms->rtask->RT_flags & RT_OWNED_BY_BUILDER) {
	    rtTemp->RT_flags |= RT_OWNED_BY_BUILDER;
	}
#endif
	MemUnlock(found_task);
	call_init = TRUE;
    }
    else if (!found_locally)
    {
	rtTemp = (RunTask*)MemLock(found_task);
	ASSERT(rtTemp->RT_shared != FALSE);
	rtTemp->RT_useCount++;
	MemUnlock(found_task);
    }

    LONLY(LRunHeapDecRefAndUnlock(rvKey.value);)
    GONLY(MemUnlock(mlBuf);)
    GONLY(MemFree(mlBuf);)

    PushTypeData(TYPE_MODULE, found_task);

    /* And add it to list of loaded modules
     */
    if (!found_locally)
    {
#ifdef LIBERTY
	RTaskHan* pointer = (RTaskHan*)rms->rtask->RT_childModules->Append();
	if (!pointer) {
	    EC_FAIL("Allocation failed, returning NULL\n");
	    FatalErrorDriver::FatalError(OUT_OF_MEMORY_FATAL_ERROR);
	}
	*pointer = found_task;
	rms->rtask->RT_childModules->UnlockElement(0);
#else
	(void)MemLock(OptrToHandle(rms->rtask->RT_childModules));
	*(RTaskHan*)ChunkArrayAppend(rms->rtask->RT_childModules, 0) =
	    found_task;
	MemUnlock(OptrToHandle(rms->rtask->RT_childModules));
#endif
    }

    if (call_init) {
	FRM_CallInitSafely(rms, found_task);
    }

    return;
}

#else /* ifndef LIBERTY */

/* This is a faster, but less functional version
 * It assumes that there are no subdirectories (true in liberty?)
 * and does not take into account the load path
 */

void
FunctionLoadModuleShared(register RMLPtr rms, BuiltInFuncEnum id)
{
    TCHAR	*full_ml, *ml;
    RVal	rvKey;

    RTaskHan	found_task = NullHandle;
    Boolean	found_locally = FALSE;
    Boolean	call_init = FALSE;
    RunTask*	rtTemp;
    USE_IT(id);

    if (rms->rtask->RT_flags & RT_UNLOADING) {
	RunSetError(rms->ptask, RTE_CANT_LOAD_WHEN_UNLOADING);
	return;
    }

    if (TopType() != TYPE_STRING)
    {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_STRING);
	return;
    }
    PopVal(rvKey);

    full_ml = (TCHAR*) LRunHeapLock(rvKey.value);

    // If absolute, make ml point after the <driver>://
    ml = strchr(full_ml, _CHAR(':'));
    if ((ml) && (ml[1] == _CHAR('/')) && (ml[2] == _CHAR('/'))) {
	ml += 3;
    } else {
	ml = full_ml;
    }

    FTRACE_LOG(*theLegosFunctionTraceLog << "LMS " << ml << ':');

    // After this loop exits, found_task and found_locally should be set.
    // Might have to call FidoFindML a few times, because some of the
    // matches might be non-shared modules :-/
    ModuleToken	found_module = NULL_MODULE;	/* don't move this inside */
    while (1) {
	RTaskHan*	rtaskArr;
	RunTask*	rtask;
	Boolean		shared = FALSE;

	if ((found_module = FidoFindML(ml, found_module)) == NULL_MODULE) {
	    break;
	}

	/* Linear scan through all rtasks, finding the one that matches
	 * the module token.  It's a 1-1 mapping, but the pointers only
	 * go one way, unfortunately.
	 */
	rtaskArr = (RTaskHan*) MemLock(rms->ptask->PT_tasks);
	for (int i=0; i < rms->ptask->PT_numTasks; i++) {
	    rtask = (RunTask*)MemLock(rtaskArr[i]);
	    if (MODULE_TOKEN_DECODE(rtask->RT_fidoModule) == found_module) {
		found_task = rtaskArr[i];
		shared = rtask->RT_shared;
		MemUnlock(found_task);
		break;
	    }
	    MemUnlock(rtaskArr[i]);
	}
	MemUnlock(rms->ptask->PT_tasks);

	/* ASSERT(found_task != NullHandle);
	 * I lied, it's not a 1-1 mapping.  If a module is being unloaded,
	 * its RT_fidoModule is nulled out, but the element in fido's
	 * module array is not deleted; in this case we won't find the task.
	 */
	if (found_task == NullHandle || shared == FALSE) {
	    found_task = NullHandle;
	    continue;
	}

	/* Found a match -- break out of loop after setting up some vars
	 * if it's in child array, set found_locally
	 */
	word numTasks = rms->rtask->RT_childModules->GetCount();
	if (numTasks > 0) {
	    rtaskArr = (RTaskHan*)rms->rtask->RT_childModules->LockElement(0);
	    for (int i=0; i<numTasks; i++) {
		if (rtaskArr[i] == found_task) {
		    found_locally = TRUE;
		    break;
		}
	    }
	    rms->rtask->RT_childModules->UnlockElement(0);
	}
	break;
    }

    /* If newly loaded, push module, mark as shared, exec module_init
     * Otherwise, inc use count and push.
     */
    if (found_task == NullHandle)
    {
	found_task = RunLoadModuleLow(rms->ptask->PT_handle, full_ml,
				      rms->rtask->RT_uiParent,
				      rms->rtask->RT_fidoModule);
	if (found_task == NullHandle) {
	    GONLY(MemFree(mlBuf);)
	    RunSetError(rms->ptask, RTE_BAD_MODULE);
	    LONLY(LRunHeapDecRefAndUnlock(rvKey.value);)
	    return;
	}
	rtTemp = (RunTask*)MemLock(found_task);
	rtTemp->RT_shared = TRUE;

	FTRACE_LOG(*theLegosFunctionTraceLog << "LOAD ");
#if 1
/* FIXME HACK -- inherit RT_OWNED_BY_BUILDER flag, so aggs added to sn-delx
 * don't go away on "new module"
 */
	if (rms->rtask->RT_flags & RT_OWNED_BY_BUILDER) {
	    rtTemp->RT_flags |= RT_OWNED_BY_BUILDER;
	}
#endif
	MemUnlock(found_task);
	call_init = TRUE;
    }
    else if (!found_locally)
    {
	rtTemp = (RunTask*)MemLock(found_task);
	ASSERT(rtTemp->RT_shared != FALSE);
	rtTemp->RT_useCount++;
	FTRACE_LOG(*theLegosFunctionTraceLog << "inc " << rtTemp->RT_useCount);
	MemUnlock(found_task);
    }
    FTRACE_LOG(*theLegosFunctionTraceLog << '\n');

    LONLY(LRunHeapDecRefAndUnlock(rvKey.value);)
    GONLY(MemUnlock(mlBuf);)
    GONLY(MemFree(mlBuf);)

    PushTypeData(TYPE_MODULE, found_task);

    /* And add it to list of loaded modules
     */
    if (!found_locally)
    {
	RTaskHan* pointer = (RTaskHan*)rms->rtask->RT_childModules->Append();
	if (!pointer) {
	    EC_FAIL("Allocation failed, returning NULL\n");
	    FatalErrorDriver::FatalError(OUT_OF_MEMORY_FATAL_ERROR);
	}
	*pointer = found_task;
	rms->rtask->RT_childModules->UnlockElement(0);
    }

    if (call_init) {
	FRM_CallInitSafely(rms, found_task);	
    }


    return;
}
#endif /* LIBERTY */

/*********************************************************************
 *			FRM_CallInitSafely
 *********************************************************************
 * SYNOPSIS:	Call duplo_ui safely, not propagating any of its errors
 * CALLED BY:	INTERNAL FunctionLoadModule{Shared}
 * RETURN:	
 * SIDE EFFECTS:
 *	May set PT_err to RTE_ERROR_IN_MODULE_INIT
 *
 * STRATEGY:
 *	Assume module has already been pushed on runtime stack
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	10/ 4/96  	Initial version
 * 
 *********************************************************************/
static void
FRM_CallInitSafely(RMLPtr rms, RTaskHan found_task)
{
    LegosType	retType;

    INT_ON(rms);
    RunCallFunctionWithKey(found_task, 0, NULL, &retType, NULL);
    /*RunSwitchFunctions(rms, found_task, 0, RSC_NONE);*/
    INT_OFF(rms);

    if (retType == TYPE_ERROR)
    {
	RuntimeErrorCode	prevError;

	/* This will pop it off the stack */
	FunctionUnloadModuleCommon(rms, FUNCTION_DESTROY_MODULE);

	/* Override RTE_QUIET_EXIT that might have been generated
	 * by duplo_ui or module_exit calls */
	prevError = rms->ptask->PT_err;
	rms->ptask->PT_err = RTE_NONE; /* or SetError will fail */
	RunSetErrorWithData(rms->ptask, RTE_ERROR_IN_MODULE_INIT, prevError);
    }
}

/*********************************************************************
 *		FRM_CheckRTask
 *********************************************************************
 * SYNOPSIS:	Common code to find a shared rtask with a given ML
 * CALLED BY:	INTERNAL FunctionLoadModule
 * RETURN:	TRUE if compare successful
 * SIDE EFFECTS:
 * STRATEGY:
 *	Assume locked FidoTask
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/23/96  	Initial version
 * 
 *********************************************************************/
/* Right now, is geos-only */
#ifndef LIBERTY
static Boolean
FRM_CheckRTask(RMLPtr rms, TCHAR* full_ml, RTaskHan rtaskHan)
{
    RunTask*	rtTemp;
    TCHAR*	module_ml;
    word	fidoMod;
    Boolean	shared;

    LONLY(USE_IT(rms));

    rtTemp = (RunTask*)MemLock(rtaskHan);
    fidoMod = rtTemp->RT_fidoModule;
    shared = rtTemp->RT_shared;
    MemUnlock(rtTemp->RT_handle);

    /* We can get some of these sometimes... @#(*$ special cases */
    if (fidoMod == NULL_MODULE) return FALSE;
    if (!shared) return FALSE;

    module_ml = Fido_GetML(rms->ptask->PT_fidoTask, fidoMod);

    if (module_ml != NULL) {
        if (!strcmp(module_ml, full_ml)) {
	    LONLY(free(module_ml));
	    return TRUE;
        }
        LONLY(free(module_ml));
    }
    return FALSE;
}
#endif

/*********************************************************************
 *			FunctionLoadModule -d-
 *********************************************************************
 * SYNOPSIS:	load a module
 * CALLED BY:	RunMainLoop by OP_BUILT_IN_FUNC
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/26/95	Initial version			     
 * 
 *********************************************************************/
void
FunctionLoadModule(register RMLPtr rms, BuiltInFuncEnum id)
{
    RTaskHan	newRTaskHan;
    TCHAR	*str;
    RVal	rvKey;
    USE_IT(id);

    PROFILE_START_SECTION(PS_FUNC_LOAD_MODULE);

    if (rms->rtask->RT_flags & RT_UNLOADING) {
	RunSetError(rms->ptask, RTE_CANT_LOAD_WHEN_UNLOADING);
	return;
    }

    /* Argument is name of file to load (currently relative to SP_TOP).
     * Copy into fullPath and convert to an absolute path, if it isn't
     * already.
     */
    if (TopType() != TYPE_STRING)
    {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_STRING);
	return;
    }
    PopVal(rvKey);

    RunHeapLock(rms->rhi,rvKey.value, (void**)(&str));
    newRTaskHan = RunLoadModuleLow(rms->ptask->PT_handle, str,
				   rms->rtask->RT_uiParent,
				   rms->rtask->RT_fidoModule);
    /* the string might have moved, can't call RunHeapDecRefAndUnlock(),
       must do it separately */
    RunHeapUnlock(rms->rhi, rvKey.value);
    RunHeapDecRef(rms->rhi, rvKey.value);
    if (newRTaskHan == NullHandle) {
	goto errorDone;
    }
#if 1
/* FIXME HACK -- inherit RT_OWNED_BY_BUILDER flag, so aggs added to sn-delx
 * don't go away on "new module"
 */
    ;{
	RunTask* rtTemp = (RunTask*)MemLock(newRTaskHan);
	if (rms->rtask->RT_flags & RT_OWNED_BY_BUILDER) {
	    rtTemp->RT_flags |= RT_OWNED_BY_BUILDER;
	}
	MemUnlock(newRTaskHan);
    }
#endif

    /* Success -- push new module as return value. */
    PushTypeData(TYPE_MODULE, newRTaskHan);

    /* And add it to list of loaded modules
     */
#ifdef LIBERTY
    {
	RTaskHan* pointer = (RTaskHan*)rms->rtask->RT_childModules->Append();
	if (!pointer) {
	    EC_WARN("Allocation failure in FunctionLoadModule()");
	    FatalErrorDriver::FatalError(OUT_OF_MEMORY_FATAL_ERROR);
	}
	*pointer = newRTaskHan;
    }
    rms->rtask->RT_childModules->UnlockElement(0);
#else
    (void)MemLock(OptrToHandle(rms->rtask->RT_childModules));
    *(RTaskHan*)ChunkArrayAppend(rms->rtask->RT_childModules, 0) = newRTaskHan;
    MemUnlock(OptrToHandle(rms->rtask->RT_childModules));
#endif

    FRM_CallInitSafely(rms, newRTaskHan);

 done:
    PROFILE_END_SECTION(PS_FUNC_LOAD_MODULE);
    return;

 errorDone:
    RunSetError(rms->ptask, RTE_BAD_MODULE);
    goto done;
}

/*********************************************************************
 *			SubroutineExportAggregate -d-
 *********************************************************************
 * SYNOPSIS:	Register an aggregate component name with Fido
 * CALLED BY:	RunMainLoop (built-in function)
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 *	Takes two args on the stack:
 *	 STRING		aggregate name
 *	 STRING		function name
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 8/ 4/95	Initial version
 * 
 *********************************************************************/
void
SubroutineExportAggregate(RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvFunc, rvAgg;
    TCHAR	*func;
    TCHAR	*agg;
    word	funcNum;
    USE_IT(id);

    if (NthType(1) != TYPE_STRING || NthType(2) != TYPE_STRING) {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_STRING);
	return;
    }
    PopVal(rvFunc);
    PopVal(rvAgg);

    RunHeapLock(rms->rhi, rvFunc.value, (void**)(&func));
#ifdef LIBERTY
    funcNum = SSTLookup(rms->rtask->RT_stringFuncTable, func,
			rms->rtask->RT_stringFuncCount);
#else
    funcNum = SSTLookup(rms->rtask->RT_stringFuncTable, func);
#endif
    RunHeapDecRefAndUnlock(rms->rhi, rvFunc.value, func);

    if (funcNum == SST_NULL)
    {
	RunSetError(rms->ptask, RTE_INVALID_MODULE_CALL);
	RunHeapDecRef(rms->rhi, rvAgg.value);
	return;
    }

    RunHeapLock(rms->rhi, rvAgg.value, (void**)(&agg));
    ECG(ECRunHeapLockHeap(rms->rhi));

#ifdef LIBERTY
    /* in Liberty, fido stores the handle and NOT a copy of the
     * actual string.  so we don't want to decref either
     */
    FidoRegisterAgg(rms->rtask->RT_fidoModule, agg,
		    rms->rtask->RT_handle, funcNum);

#else	/* GEOS version below */

    FidoRegisterAgg(rms->rtask->RT_fidoTask, rms->rtask->RT_fidoModule,
		    agg, rms->rtask->RT_handle, funcNum);

#endif

    /* stuff here */

    ECG(ECRunHeapUnlockHeap(rms->rhi));
    RunHeapDecRefAndUnlock(rms->rhi, rvAgg.value, agg);

    return;
}

extern void RunMainMessageDispatch(RTaskHan rtaskHan);

#ifndef LIBERTY

/* This nicely commented function is in componen.cpp in Liberty
   because it needs the lpp preprocessor */

void
FunctionUpdate(RMLPtr rms, BuiltInFuncEnum id)
{
    USE_IT(rms);
    USE_IT(id);
    INT_ON(rms);
    RunMainMessageDispatch(rms->rtask->RT_handle);
    INT_OFF(rms);
    return;
}
#endif



/*********************************************************************
 *			FunctionGetArrayDims -d-
 *********************************************************************
 * SYNOPSIS:	Return the number of dimension in an array.
 * CALLED BY:	RunMainLoop (built-in function)
 * PASS:	stack: <array>
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	RON	8/28/95	    	Initial version
 * 
 *********************************************************************/
void
FunctionGetArrayDims(register RMLPtr rms, BuiltInFuncEnum id)
{
    int	    	    numDims;
    RVal	    rvArr;
    MemHandle	    array;
    ArrayHeader*    arrayPtr;
    USE_IT(id);

    PROFILE_START_SECTION(PS_FUNC_GET_ARRAY_DIMS);
    if (TopType() != TYPE_ARRAY) 
    {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_ARRAY);
	return;
    }
    PopVal(rvArr);

    array = (MemHandle) rvArr.value;
    if (array == NullHandle)
    {
	RunSetError(rms->ptask, RTE_ARRAY_REF_SANS_DIM);
	PROFILE_END_SECTION(PS_FUNC_GET_ARRAY_DIMS);
	return;
    }
    arrayPtr = (ArrayHeader*)MemLock(array);
    numDims = arrayPtr->AH_numDims;
    MemUnlock(array);
    
    /* Push the number or dimensions */
    PushTypeData(TYPE_INTEGER, numDims);
    PROFILE_END_SECTION(PS_FUNC_GET_ARRAY_DIMS);
    return;
}


/*********************************************************************
 *			FunctionGetArraySize
 *********************************************************************
 * SYNOPSIS:	Return the size of a dimension in an array.
 * CALLED BY:	RunMainLoop (built-in function)
 * PASS:	stack: <array>
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	RON	8/28/95	    	Initial version
 * 
 *********************************************************************/
void
FunctionGetArraySize(register RMLPtr rms, BuiltInFuncEnum id)
{
    int	    	numElts;
    RVal	rvArr;
    RVal	rvDim;
    MemHandle	array;
    ArrayHeader *arrayPtr;
    int	    	dim;
    USE_IT(id);

    PROFILE_START_SECTION(PS_FUNC_GET_ARRAY_SIZE);
    if (NthType(1) != TYPE_INTEGER) {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_INTEGER);
	return;
    }
    if (NthType(2) != TYPE_ARRAY) {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_ARRAY);
	return;
    }

    PopVal(rvDim);
    PopVal(rvArr);

    dim = (int) rvDim.value;
    array = (MemHandle) rvArr.value;
    if (array == NullHandle)
    {
	RunSetError(rms->ptask, RTE_ARRAY_REF_SANS_DIM);
	return;
    }

    arrayPtr = (ArrayHeader*)MemLock(array);
    if (dim >= arrayPtr->AH_numDims || dim < 0) 
    {
	MemUnlock(array);
	RunSetError(rms->ptask, RTE_BAD_ARRAY_REF);
	return;
    }
	
    numElts = (arrayPtr->AH_dims)[dim];
    MemUnlock(array);
#ifdef EC_DEBUG_SERCOMP
if(myLog == NULL) {
    myLog = new Log("arraylog", 37000, WRAP_AT_END);
    EC(HeapSetTypeAndOwner(myLog, "SXYZ"));
    Result r = myLog->Initialize();
    ASSERT(r == SUCCESS);
}

*myLog << '(' << numElts << ',' << numElts << ',' << numElts << ')';
if(numElts == 0) {
    *myLog << "arg\n";
}
if(numElts > 10000) {
    *myLog << "bad num elts\n";
}
#endif

    /* Push the number or dimensions */
    PushTypeData(TYPE_INTEGER, numElts);
    PROFILE_END_SECTION(PS_FUNC_GET_ARRAY_SIZE);
    return;
}

/*********************************************************************
 *			FunctionEnableDisableEvents
 *********************************************************************
 * SYNOPSIS:	enable or disable events
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:    
 * STRATEGY:	just turn the events disabled flag on or off
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/14/96  	Initial version
 * 
 *********************************************************************/
void
FunctionEnableDisableEvents(register RMLPtr rms, BuiltInFuncEnum id)
{
    if (id == FUNCTION_ENABLE_EVENTS) {
	rms->rtask->RT_flags &= ~RT_EVENTS_DISABLED;
    } else {
	rms->rtask->RT_flags |= RT_EVENTS_DISABLED;
    }
}

/*********************************************************************
 *			SubroutineUseLibrary -d-
 *********************************************************************
 * SYNOPSIS:	Call into fido to add a new component library
 * CALLED BY:	EXTERNAL OP_BUILT_IN_FUNC
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/24/96  	Initial version
 * 
 *********************************************************************/
void
SubroutineUseLibrary(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvArg;
    Boolean	success;
    USE_IT(id);

    PopVal(rvArg);
    switch (rvArg.type)
    {
    case TYPE_STRING:
    {
	TCHAR*	lib_name;

	RunHeapLock(rms->rhi, rvArg.value, (void**)(&lib_name));
	success = FidoUseLibrary_Geode
	    (rms->ptask->PT_fidoTask, rms->rtask->RT_fidoModule, lib_name);
	RunHeapDecRefAndUnlock(rms->rhi, rvArg.value, lib_name);
	if (!success) {
	    RunSetError(rms->ptask, RTE_LIBRARY_NOT_FOUND);
	}
	break;
    }

    case TYPE_MODULE:
    {
	RTaskHan	agg_task_han;
	RunTask*	agg_task;
	ModuleToken	agg_module;

	agg_task_han = rvArg.value;
	// If we have an invalid task handle, return an error.
	if (agg_task_han == NullHandle) {
	    RunSetError(rms->ptask, RTE_VALUE_IS_NULL);
	    return;
	}
	agg_task = (RunTask*)MemLock(agg_task_han);
	agg_module = agg_task->RT_fidoModule;
	MemUnlock(agg_task_han);

	success = FidoUseLibrary_Agg
	    (rms->ptask->PT_fidoTask, rms->rtask->RT_fidoModule, agg_module);
	if (!success) {
	    RunSetError(rms->ptask, RTE_NOT_AGGREGATE_MODULE);
	}
	break;
    }

    default:
	RunSetError(rms->ptask, RTE_ARG_INVALID_TYPE);
	PushTypeData(rvArg.type, rvArg.value);
	break;
    }
    return;
}

/*********************************************************************
 *			FunctionIsNull -d-
 *********************************************************************
 * SYNOPSIS:	Determine if a non-numeric is "null"
 * CALLED BY:	EXTERNAL OP_BUILT_IN_FUNC
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/24/96  	Initial version
 * 
 *********************************************************************/
void
FunctionIsNull(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvArg;
    dword	val = 0;
    USE_IT(id);

    PopVal(rvArg);

    switch (rvArg.type)
    {
    case TYPE_COMPLEX:
    case TYPE_STRING:
    case TYPE_STRUCT:
	val = ((RunHeapToken)rvArg.value == NULL_TOKEN);
	RunHeapDecRef(rms->rhi, rvArg.value);
	break;

    case TYPE_MODULE:
    case TYPE_ARRAY:
	val = ((MemHandle)rvArg.value == NullHandle);
	break;

    case TYPE_UNKNOWN:
	val = 1;
	break;

    case TYPE_COMPONENT:
	if (COMP_IS_AGG(rvArg.value))
	{
	    byte*	structP;
	    RunHeapToken agg;
	    RTaskHan	agg_library;

	    /* An agg could become null if its library was unloaded by
	     * some evil person.  However, all references to the library
	     * will be nulled out, hah!  So that's what we check.
	     */
	    agg = AGG_TO_STRUCT(rvArg.value);
	    RunHeapLock(rms->rhi, agg, (void**)(&structP));
	    FieldNMemHandle(structP, AF_LIB_MODULE, agg_library);
	    RunHeapDecRefAndUnlock(rms->rhi, agg, structP);

	    val = (agg_library == NullHandle);
	} else {
	    val = (rvArg.value == NullOptr);
	}
	break;

    default:
	RunSetError(rms->ptask, RTE_ARG_INVALID_TYPE);
	PushTypeData(rvArg.type, rvArg.value);
	return;
    }

    PushTypeData(TYPE_INTEGER, val);
}

/*********************************************************************
 *			FunctionGetSourceExport -d-
 *********************************************************************
 * SYNOPSIS:	Return the ML
 * CALLED BY:	EXTERNAL OP_BUILT_IN_FUNC
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	4/26/96  	Initial version
 * 
 *********************************************************************/
void
FunctionGetSourceExport(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvMod;
    ModuleToken	mod;
    RunTask*	rtask;
    TCHAR*	ml_or_export;
    RunHeapToken key;

    if (TopType() != TYPE_MODULE) {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_MODULE);
	return;
    }

    PopVal(rvMod);

    if ((MemHandle)rvMod.value == NullHandle) {
	RunSetError(rms->ptask, RTE_BAD_MODULE);
	return;
    }
    
    rtask = (RunTask*)MemLock(rvMod.value);
    mod = rtask->RT_fidoModule;
    MemUnlock(rvMod.value);

    GONLY((void)MemLock(rms->ptask->PT_fidoTask);)

    if (id == FUNCTION_GET_SOURCE) {
	ml_or_export = Fido_GetML(rms->ptask->PT_fidoTask, mod);
    } else {
	/* This is only really needed for some builder support
	 * in liberty this can raise a runtime error or something --
	 * the GetExport function will not be documented
	 */
	ml_or_export = Fido_GetExport(rms->ptask->PT_fidoTask, mod);
    }

    if (ml_or_export == NULL) {
	key = EMPTY_STRING_KEY;
    } else {
	key = MakeRHString(rms, ml_or_export);
	LONLY(free(ml_or_export));
    }

    GONLY(MemUnlock(rms->ptask->PT_fidoTask);)

    PushTypeData(TYPE_STRING, key);
    return;
}

/***********************************************************************
 *			FunctionWTMFinish()
 ***********************************************************************
 *
 * SYNOPSIS:	    
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:
 *	On stack:	wttable[], int SetNo, ta0[], mta0[], TOS
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dubois	12/ 3/96  	Initial Revision
 *
 ***********************************************************************/
void FunctionWTMFinish(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvWttable, rvTa0, rvSetNo, rvMta0;
    word	setNo;
    MemHandle	wttableArr, ta0Arr, mta0Arr;
    ArrayHeader *wttableAH, *ta0AH, *mta0AH;
    sword	*wttable, *ta0, *mta0;

    USE_IT(id);
    if (TopData() != 4) {
	RunSetError(rms->ptask, RTE_WRONG_NUMBER_ARGS);
	return;
    }
    PopValVoid();

    if (NthType(1) != TYPE_ARRAY ||
	NthType(2) != TYPE_ARRAY ||
	NthType(3) != TYPE_INTEGER ||
	NthType(4) != TYPE_ARRAY)
    {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_ARRAY);
	return;
    }
    PopVal(rvMta0); PopVal(rvTa0); PopVal(rvSetNo); PopVal(rvWttable);
    setNo = rvSetNo.value;

    /* Get handles, pointers to array headers, pointers to array data
     * not all of this might be needed/used... whatever */
    wttableArr = (MemHandle)rvWttable.value;
    wttableAH = (ArrayHeader*)MemLock(wttableArr);
    wttable = (sword*)(wttableAH+1);
    ta0Arr = (MemHandle)rvTa0.value;
    ta0AH = (ArrayHeader*)MemLock(ta0Arr);
    ta0 = (sword*)(ta0AH+1);
    mta0Arr = (MemHandle)rvMta0.value;
    mta0AH = (ArrayHeader*)MemLock(mta0Arr);
    mta0 = (sword*)(mta0AH+1);

    /* Main body of WTMfinish routine */
    ;{
	sword	i, k;
	sword*	cursor;
	word	kSize;

	/* NOTE: In Legos arrays the first dimension varies fastest */

	cursor = wttable;
	cursor += setNo + wttableAH->AH_dims[0];
	kSize = wttableAH->AH_dims[0] * wttableAH->AH_dims[1];
	for (i=k=0; i <= 479; i += 4, k++) {
	    /* wttable[SetNo,1,k] = */
	    /* cursor[setNo + 1*maxdim[0] + k*maxdim[0]*maxdim[1]] =
	     *   move maxdim[0]*maxdim[1] out of iteration and we get
	     * cursor[setNo + 1*maxdim[0]] =
	     *   move the setNo + 1*maxdim[1] out of the loop and we get:
	     */
	    *cursor = (ta0[i]<<3) | (ta0[i+1]<<2) |
		(ta0[i+2]<<1) | (ta0[i+3]);
	    cursor += kSize;
	}

	for (i=0,k=0; i<=1439; i += 3,k++) {
	    /* set ta0 iff any of the 3 mta0 are set */
	    ta0[k] = ( mta0[i] || mta0[i+1] || mta0[i+2] );
	}

	cursor = wttable + setNo;
	for (i=k=0; i<=479; i+=4, k++) {
	    /* wttable[SetNo,0,k] -- see above loop for derivation */
	    *cursor = ta0[i]<<3 | ta0[i+1]<<2 | ta0[i+2]<<1 | ta0[i+3];
	    cursor += kSize;
	}

	/* Punt on these
	 * tno0 = tno1
	 * tno1 = 1 - tno1
	 */

	/* redim ta0[480] */
	/* redim mta0[1440] */
	ASSERT((ta0AH->AH_dims[0] == 480) && (ta0AH->AH_numDims == 1));
	ASSERT((mta0AH->AH_dims[0] == 1440) && (mta0AH->AH_numDims == 1));
	memset(ta0, 0, 480 * sizeof(sword));
	memset(mta0, 0, 1440 * sizeof(sword));
    }

    MemUnlock(mta0Arr);
    MemUnlock(ta0Arr);
    MemUnlock(wttableArr);
}

/***********************************************************************
 *			FunctionDTMFinish()
 ***********************************************************************
 *
 * SYNOPSIS:	    
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:
 *	On stack:	wttable[], ta0[], mta0[], TOS
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dubois	12/ 3/96  	Initial Revision
 *
 ***********************************************************************/
void FunctionDTMFinish(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvWttable, rvTa0, rvMta0;
    MemHandle	wttableArr, ta0Arr, mta0Arr;
    ArrayHeader *wttableAH, *ta0AH, *mta0AH;
    sword	*wttable, *ta0, *mta0;

    USE_IT(id);
    if (TopData() != 3) {
	RunSetError(rms->ptask, RTE_WRONG_NUMBER_ARGS);
	return;
    }
    PopValVoid();

    if (NthType(1) != TYPE_ARRAY ||
	NthType(2) != TYPE_ARRAY ||
	NthType(3) != TYPE_ARRAY)
    {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_ARRAY);
	return;
    }
    PopVal(rvMta0); PopVal(rvTa0); PopVal(rvWttable);

    /* Get handles, pointers to array headers, pointers to array data
     * not all of this might be needed/used... whatever */
    wttableArr = (MemHandle)rvWttable.value;
    wttableAH = (ArrayHeader*)MemLock(wttableArr);
    wttable = (sword*)(wttableAH+1);
    ta0Arr = (MemHandle)rvTa0.value;
    ta0AH = (ArrayHeader*)MemLock(ta0Arr);
    ta0 = (sword*)(ta0AH+1);
    mta0Arr = (MemHandle)rvMta0.value;
    mta0AH = (ArrayHeader*)MemLock(mta0Arr);
    mta0 = (sword*)(mta0AH+1);

    /* Main body of WTMfinish routine */
    ;{
	sword	i, j;
	sword*	cursor;
	word	kSize;

	/* NOTE: In Legos arrays the first dimension varies fastest */

	cursor = wttable;
	cursor++;
	kSize = wttableAH->AH_dims[0];
	for (i=j=0; i <= 479; i+=4, j++) {
	    *cursor = (ta0[i]<<3) | (ta0[i+1]<<2) |
		(ta0[i+2]<<1) | (ta0[i+3]);
	    cursor += kSize;
	}

	for (i=0,j=0; i<=1439; i += 3,j++) {
	    /* set ta0 iff any of the 3 mta0 are set */
	    ta0[j] = ( mta0[i] || mta0[i+1] || mta0[i+2] );
	}

	cursor = wttable;
	for (i=j=0; i<=479; i+=4, j++) {
	    *cursor = ta0[i]<<3 | ta0[i+1]<<2 | ta0[i+2]<<1 | ta0[i+3];
	    cursor += kSize;
	}

	/* Punt on these
	 * tno0 = tno1
	 * tno1 = 1 - tno1
	 */

	/* redim ta0[480] */
	/* redim mta0[1440] */
	ASSERT((ta0AH->AH_dims[0] == 480) && (ta0AH->AH_numDims == 1));
	ASSERT((mta0AH->AH_dims[0] == 1440) && (mta0AH->AH_numDims == 1));
	memset(ta0, 0, 480 * sizeof(sword));
	memset(mta0, 0, 1440 * sizeof(sword));
    }

    MemUnlock(mta0Arr);
    MemUnlock(ta0Arr);
    MemUnlock(wttableArr);
}

/***********************************************************************
 *			FunctionSGetTableB()
 ***********************************************************************
 *
 * SYNOPSIS:	    Hack -- SH-WGRA::SGetTableB
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:
 *	On stack:	int[] wttable, int dno, int tano, int gtime, int[] ata TOS
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dubois	12/ 3/96  	Initial Revision
 *
 ***********************************************************************/
void FunctionSGetTableB(register RMLPtr rms, BuiltInFuncEnum id)
{
    RVal	rvtano, rvgtime, rvata;
    sword	dno, tano, gtime;

    RVal	rvwttable, rvdno;
    MemHandle	ataArr, wttableArr;
    ArrayHeader *ataAH, *wttableAH;
    sword	*ata, *wttable;

    dword	hasNonZero = 0;

    USE_IT(id);
    if (TopData() != 5) {
	RunSetError(rms->ptask, RTE_WRONG_NUMBER_ARGS);
	return;
    }
    PopValVoid();
    if (NthType(1) != TYPE_ARRAY || NthType(2) != TYPE_INTEGER ||
	NthType(3) != TYPE_INTEGER || NthType(4) != TYPE_INTEGER ||
	NthType(5) != TYPE_ARRAY)
    {
	RunSetErrorWithData(rms->ptask, RTE_TYPE_MISMATCH, TYPE_ARRAY);
	return;
    }
    PopVal(rvata); PopVal(rvgtime); PopVal(rvtano); PopVal(rvdno);
    PopVal(rvwttable);

    ataArr = (MemHandle)rvata.value;
    gtime = rvgtime.value; tano = rvtano.value; dno = rvdno.value;
    wttableArr = (MemHandle)rvwttable.value;

    /* Lock dem arrays */
    ataAH = (ArrayHeader*)MemLock(ataArr);
    ata = (sword*)(ataAH+1);
    ASSERT((ataAH->AH_numDims == 1) && (ataAH->AH_dims[0] == 20));

    wttableAH = (ArrayHeader*)MemLock(wttableArr);
    wttable = (sword*)(wttableAH+1);
    ASSERT(wttableAH->AH_numDims == 3);

    /* Main body of WTMfinish routine */
    ;{
	sword i,is,iw;
	/* sword j, icnt; unused */
	sword* cursor;
	word kSize;

	is = gtime * 5;

	/* redim ata[20] */
	memset(ata, '\0', 40);

	cursor = wttable + dno + tano * wttableAH->AH_dims[0];
	kSize = wttableAH->AH_dims[0] * wttableAH->AH_dims[1];
	for(i=is; i<=is+4; i++, cursor += kSize) {
	    /* iw = wttable[dno, tano, i] */
	    iw = *cursor;
	    if (iw) {
		hasNonZero = 1;
		*ata++ = iw & 0x8;
		*ata++ = iw & 0x4;
		*ata++ = iw & 0x2;
		*ata++ = iw & 0x1;
	    }
	}
    }

    PushTypeData(TYPE_INTEGER, hasNonZero);

    MemUnlock(ataArr);
    MemUnlock(wttableArr);
}



/*********************************************************************
 *			FunctionRoundFormat
 *********************************************************************
 * SYNOPSIS:	Round(#,n) and Format(#,flags,n)
 * CALLED BY:	RunMainLoop()
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	eca	9/ 8/97  	Initial version
 * 
 *********************************************************************/
void
FunctionRoundFormat(RMLPtr rms, BuiltInFuncEnum id)
{
    RVal        rvNum, rvN, rvFlags;
    float       num, retval;
    IEEE64FloatNum      n2;
    TCHAR       buf[FLOAT_TO_ASCII_NORMAL_BUF_LEN];
    RunHeapToken key;

    /*
     * Get the number of places
     */
    PopVal(rvN);
    if (rvN.type != TYPE_INTEGER) {
	RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	PushTypeData(rvN.type, rvN.value); /* for cleanup */
	return;
    }

    /*
     * if format, get the format flags
     */
    if (id == FUNCTION_FORMAT) {
	PopVal(rvFlags);
	if (rvFlags.type != TYPE_INTEGER) {
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	    PushTypeData(rvFlags.type, rvFlags.value); /* for cleanup */
	    return;
	}
	rvFlags.value = rvFlags.value & (FFAF_SCIENTIFIC | \
					 FFAF_PERCENT | \
					 FFAF_USE_COMMAS | \
					 FFAF_NO_TRAIL_ZEROS | \
					 FFAF_NO_LEAD_ZERO);
    }
    /*
     * Get the number to round or format
     */ 
    PopVal(rvNum);
    rvNum.type = AssignTypeCompatible(TYPE_FLOAT, rvNum.type, &rvNum.value);
    if (rvNum.type == TYPE_ILLEGAL || rms->ptask->PT_err) {
	RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	PushTypeData(rvNum.type, rvNum.value); /* for cleanup */
	return;
    }
    num = *(float*)(&rvNum.value);

    if (id == FUNCTION_ROUND) {
	/*
	 * Round the number
	 */
	retval = round(num, rvN.value);
	PushTypeData(TYPE_FLOAT, *(dword *)&retval);
    } else {
	/*
	 * Format the number
	 */
	FloatIEEE32ToGeos80(&num);
	FloatFloatToAscii_StdFormat(buf, NULL, rvFlags.value, MAX_PRECISION, rvN.value);
	key = MakeRHString(rms, buf);
	PushTypeData(TYPE_STRING, key);
    }
    
}
