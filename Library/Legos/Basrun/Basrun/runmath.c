/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		runmath.c

AUTHOR:		Jimmy Lefkowitz, Dec 30, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	12/30/94   	Initial version.

DESCRIPTION:
	code to deal with runtime math operations

	$Revision: 1.2 $

	Liberty version control
	$Id: runmath.c,v 1.2 98/10/05 12:47:43 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifdef LIBERTY
#include <Ansi/string.h>
#include <Legos/interp.h>
#include <Legos/runheap.h>
#include <Legos/runmath.h>
#include <Legos/fixds.h>
#include <Legos/stack.h>
#else
#include <Ansi/stdio.h>
#include <Ansi/string.h>
#include <Legos/runheap.h>
#include <math.h>
#include "mystdapp.h"
#include "runmath.h"
#include "mymath.h"
#include "rheapint.h"
#include "fixds.h"
#include "stack.h"
#endif

#define RMS (*rms)
#define ToFloat(x,type) (( (type) == TYPE_FLOAT) ? \
			 (*(float*) &(x)) : \
			 (( (type) == TYPE_LONG) ? \
			 ((sdword) (x)) : ((sword) (x))))

Boolean almostEqual(float a, float b);


/*********************************************************************
 *			OpNegative
 *********************************************************************
 * SYNOPSIS:	Perform a unary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void OpNegative(RMLPtr rms, RVal rv1)
{
    sword	intRes;
    sdword    	longRes;
    float   	floatRes;

    switch(rv1.type) 
    {
	case TYPE_INTEGER:
	    intRes = -(sword)rv1.value;
	    PushData(intRes);
	    break;
	case TYPE_LONG:
	    longRes = -(sdword)rv1.value;
	    PushData(longRes);
	    break;
	case TYPE_FLOAT:
	    floatRes = *(float*)(&(rv1.value));
	    floatRes = -floatRes;
	    PushData(*(dword*)&floatRes);
	    break;
	default:
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	    return;
    }
    PushType(rv1.type);
    return;
}

/*********************************************************************
 *			OpNot
 *********************************************************************
 * SYNOPSIS:	Perform a unary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void
OpNot(RMLPtr rms, RVal rv1)
{
    sword	intRes;
    sdword    	longRes;
    float   	floatRes;

    switch(rv1.type) 
    {
	case TYPE_INTEGER:
	    intRes = !(sword)rv1.value;
	    PushData(intRes);
	    break;
	case TYPE_LONG:
	    longRes = !(sdword)rv1.value;
	    PushData(longRes);
	    break;
	case TYPE_FLOAT:
	    floatRes = ( (*(float*)(&(rv1.value))) == 0.0 ? -1.0 : 0.0);
	    PushData(*(dword*)&floatRes);
	    break;
	default:
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	    return;
    }

    PushType(rv1.type);
}

/*********************************************************************
 *			OpMod
 *********************************************************************
 * SYNOPSIS:	Perform a binary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void OpMod(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword     	intRes = 0;
    sdword      longRes = 0;
    LegosType  	resType;
    double  	ip;

    /* Figure out result type */
    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
	case TYPE_INTEGER:
	    if ((sword)rv2.value == 0) {
		RunSetError(rms->ptask, RTE_DIVIDE_BY_ZERO);
	    } else {
		intRes = (sword)rv1.value/(sword)rv2.value;
		intRes = (sword)rv1.value - intRes * (sword)rv2.value;
	    }
	    break;
	case TYPE_LONG:
	    if ((sdword)rv2.value == 0L) {
		RunSetError(rms->ptask, RTE_DIVIDE_BY_ZERO);
	    } else {
		longRes = (sdword)rv1.value/(sdword)rv2.value;
		longRes = (sdword)rv1.value - longRes * (sdword)rv2.value;
	    }
	    break;
	case TYPE_FLOAT:

	    if (ToFloat(rv2.value,rv2.type) == 0.0)
	    {
		RunSetError(rms->ptask, RTE_DIVIDE_BY_ZERO);
		return;
	    }
#ifdef LIBERTY
	    ip = ToFloat(rv1.value, rv1.type) / 
		 ToFloat(rv2.value, rv2.type);
	    intRes = (word)(ToFloat(rv1.value, rv1.type) - 
			    ToFloat(rv2.value, rv2.type) * ip);
#else
	    modf((double)ToFloat(rv1.value, rv1.type)/ToFloat(rv2.value, rv2.type),&ip);
	    intRes = ToFloat(rv1.value, rv1.type) - ToFloat(rv2.value, rv2.type) * ip;
#endif
	    break;
	default:
	    RunSetError(rms->ptask,RTE_ARG_NOT_A_NUMBER);
	    return;
    }

    if (resType == TYPE_LONG) 
    {
	PushData(longRes);
    } else {
	/* for integer and float types */
	resType = TYPE_INTEGER;
	PushData(intRes);
    }

    PushType(resType);
    return;
}

/*********************************************************************
 *			OpOr
 *********************************************************************
 * SYNOPSIS:	Perform a binary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void
OpOr(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword     	intRes;
    LegosType  	resType;

    /* Figure out result type */
    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
	case TYPE_INTEGER:
	    intRes = (sword) rv1.value || (sword) rv2.value;
	    break;
	case TYPE_LONG:
	    intRes = (sdword) rv1.value || (sdword) rv2.value;
	    break;
	case TYPE_FLOAT:
	    intRes = ToFloat(rv1.value,rv1.type) ||
		ToFloat(rv2.value,rv2.type);
	    break;
	default:
	    RunSetError(rms->ptask,RTE_ARG_NOT_A_NUMBER);
	    return;
    }

    resType = TYPE_INTEGER;
    PushData(intRes);
    PushType(resType);
}

/*********************************************************************
 *			OpAnd
 *********************************************************************
 * SYNOPSIS:	Perform a binary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void
OpAnd(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword     	intRes;
    LegosType  	resType;

    /* figure out all the type possible type casts */
    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
	case TYPE_INTEGER:
	intRes = (sword) rv1.value && (sword) rv2.value;
	    break;
	case TYPE_LONG:
	    intRes = (sdword) rv1.value && (sdword) rv2.value;
	    break;
	case TYPE_FLOAT:
	    intRes = ToFloat(rv1.value,rv1.type) && ToFloat(rv2.value, rv2.type);
	    break;
	default:
	    RunSetError(rms->ptask,RTE_ARG_NOT_A_NUMBER);
	    return;
    }

    resType = TYPE_INTEGER;
    PushData(intRes);
    PushType(resType);
}

/*********************************************************************
 *			OpXor
 *********************************************************************
 * SYNOPSIS:	Perform a binary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void
OpXor(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword     	intRes;
    LegosType  	resType;

    /* figure out all the type possible type casts */
    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
	case TYPE_INTEGER:
	    intRes = (((sword) rv1.value && !((sword) rv2.value)) ||
		      ((sword) rv2.value && !((sword) rv1.value)));
	    break;
	case TYPE_LONG:
	    intRes = (((sdword) rv1.value && !((sdword) rv2.value)) ||
		      ((sdword) rv2.value && !((sdword) rv1.value)));
	    break;
	case TYPE_FLOAT:
	    intRes = ((ToFloat(rv1.value,rv1.type) && !ToFloat(rv2.value,rv2.type)) ||
		      (ToFloat(rv2.value,rv2.type) && !ToFloat(rv1.value,rv1.type)));
	    break;
	default:
	    RunSetError(rms->ptask,RTE_ARG_NOT_A_NUMBER);
	    return;
    }

    resType = TYPE_INTEGER;
    PushData(intRes);
    PushType(resType);
}

/*********************************************************************
 *			OpAdd
 *********************************************************************
 * SYNOPSIS:	Perform a binary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void
OpAdd(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword     	intRes;
    sdword    	longRes;
    float   	floatRes;
    LegosType  	resType;
    

    /* Find the result type */

    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
	case TYPE_INTEGER:
	    intRes = (sword) rv1.value + (sword) rv2.value;
	    PushData(intRes);
	    break;
	case TYPE_LONG:
	    longRes = (sdword) rv1.value + (sdword) rv2.value;
	    PushData(longRes);
	    break;
	case TYPE_FLOAT:
	    floatRes = ToFloat(rv1.value,rv1.type) + ToFloat(rv2.value,rv2.type);
	    PushData(*(dword*)&floatRes);
	    break;
	case TYPE_STRING:
	{
	    TCHAR    	*s1, *s2;
	    sword	len1, len2;
/*	    dword   	newKey;	    changed mchen, LIBERTY */
	    RunHeapToken newKey;
	    TCHAR        *buf;

	    /* we need to do a string concatenation here */
	    RunHeapLock(rms->rhi, rv1.value, (void**)(&s1));
	    RunHeapLock(rms->rhi, rv2.value, (void**)(&s2));
	    
	    len1 = strlen(s1);
	    len2 = strlen(s2);

	    if (len1 + len2 == 0) 
	    {
		newKey = EMPTY_STRING_KEY;
	    }
	    else
	    {
		SET_DS_TO_DGROUP;
		newKey = RunHeapAlloc(&(rms->ptask->PT_runHeapInfo), 
				      RHT_STRING, 1,
		    	    	      (len1 + len2 + 1) * sizeof(TCHAR), 
				      NULL);

		if (newKey == NULL_TOKEN) {
		    RunSetError(rms->ptask, RTE_OUT_OF_MEMORY);
		    return;
		}

#ifndef LIBERTY
		if (SAME_HEAP_BLOCK((word) newKey, (word) rv1.value)) {
		    s1 = (TCHAR*)RunHeapDeref(&(rms->ptask->PT_runHeapInfo),
					      (RunHeapToken) rv1.value);
		}
		if (SAME_HEAP_BLOCK((word) newKey, (word) rv2.value)) {
		    s2 = (TCHAR*)RunHeapDeref(&(rms->ptask->PT_runHeapInfo),
					      (RunHeapToken) rv2.value);
		}
#endif
		
		RunHeapLock(&(rms->ptask->PT_runHeapInfo), newKey, 
			    (void**)(&buf));

		/* create new string and add it to string table */
		sprintf(buf, _TEXT("%s%s"), s1, s2);

		RunHeapUnlock(&(rms->ptask->PT_runHeapInfo), newKey);
		RESTORE_DS;
	    }
	    RunHeapDecRefAndUnlock(rms->rhi, rv1.value, s1);
	    RunHeapDecRefAndUnlock(rms->rhi, rv2.value, s2);

	    /* now push the result onto the stack */
	    PushData(newKey);
	}
	break;

	default:
	    RunSetError(rms->ptask,RTE_INCOMPATIBLE_TYPES);
	    return;
    }


    PushType(resType);
}

/*********************************************************************
 *			OpEquals
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 1/ 6/95	Initial version			     
 * 
 *********************************************************************/
void
OpEquals(RMLPtr rms, RVal rv1, RVal rv2)
{
    sword res;
    LegosType resType;

    /* Find the result */

    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
#ifndef LIBERTY
	/* we can treat module values the same as integers since its
	 * just a MemHandle (for GEOS)
	 */
    case TYPE_MODULE:
#endif
    case TYPE_INTEGER:
	res = (sword) rv1.value == (sword) rv2.value;
	break;
    case TYPE_COMPONENT:    	/* FIXME when components become more
				 * than just optrs... */
#ifdef LIBERTY
	/* in liberty, modules are 32 bit values */
    case TYPE_MODULE:
#endif
    case TYPE_LONG:
	res = (sdword) rv1.value == (sdword) rv2.value;
	break;
    case TYPE_FLOAT:
#ifndef LIBERTY
	if (almostEqual(ToFloat(rv1.value,rv1.type),
			ToFloat(rv2.value,rv2.type))) {
	    res = TRUE;
	}
	else
#endif

	res = ToFloat(rv1.value,rv1.type) == ToFloat(rv2.value,rv2.type);
	break;
    case TYPE_STRING:
    {
	TCHAR    	*s1, *s2;

	/* quick check for same token */
	if ((RunHeapToken)rv1.value == (RunHeapToken)rv2.value)
	{
	    RunHeapDecRef(rms->rhi, rv1.value);
	    RunHeapDecRef(rms->rhi, rv2.value);
	    res = TRUE;
	} 
	else 
	{
	    RunHeapLock(rms->rhi, rv1.value, (void**)(&s1));
	    RunHeapLock(rms->rhi, rv2.value, (void**)(&s2));
	    res = !strcmp(s1, s2);
	    RunHeapDecRefAndUnlock(rms->rhi, rv1.value, s1);
	    RunHeapDecRefAndUnlock(rms->rhi, rv2.value, s2);
	}
    }
	break;
	
    default:
	RunSetError(rms->ptask,RTE_ARG_NOT_A_NUMBER);
	return;
    }

    PushData(res);
    PushType(TYPE_INTEGER);
    	
}

/*********************************************************************
 *			OpLessThan
 *********************************************************************
 * SYNOPSIS:	implement the < operator
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/ 6/95	Initial version			     
 * 
 *********************************************************************/
void
OpLessThan(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword res;
    LegosType resType;

    /* Find the result */

    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
    case TYPE_INTEGER:
	res = (sword) rv1.value < (sword) rv2.value;
	break;
    case TYPE_LONG:
	res = (sdword) rv1.value < (sdword) rv2.value;
	break;
    case TYPE_FLOAT:

#ifndef LIBERTY
	if (almostEqual(ToFloat(rv1.value,rv1.type),
			ToFloat(rv2.value,rv2.type))) {
	    res = FALSE;
	}
	else
#endif
	    res = ToFloat(rv1.value,rv1.type) < ToFloat(rv2.value,rv2.type);
	
	break;
    default:
	RunSetError(rms->ptask,RTE_ARG_NOT_A_NUMBER);
	return;
    }

    PushData(res);
    PushType(TYPE_INTEGER);
    	
}

/*********************************************************************
 *			OpGreaterThan
 *********************************************************************
 * SYNOPSIS:	implement > operator
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 1/ 6/95	Initial version			     
 * 
 *********************************************************************/
void
OpGreaterThan(RMLPtr rms, RVal rv1, RVal rv2)
{
    sword res;
    LegosType resType;

    /* Find the result */

    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
    case TYPE_INTEGER:
	res = (sword) rv1.value > (sword) rv2.value;
	break;
    case TYPE_LONG:
	res = (sdword) rv1.value > (sdword) rv2.value;
	break;
    case TYPE_FLOAT:
#ifndef LIBERTY
	if (almostEqual(ToFloat(rv1.value,rv1.type),
			ToFloat(rv2.value,rv2.type))) {
	    res = FALSE;
	}
	else
#endif
	res = ToFloat(rv1.value,rv1.type) > ToFloat(rv2.value,rv2.type);
	break;
    default:
	RunSetError(rms->ptask,RTE_ARG_NOT_A_NUMBER);
	return;
    }

    PushData(res);
    PushType(TYPE_INTEGER);
    	
}

/*********************************************************************
 *			OpLessEqual
 *********************************************************************
 * SYNOPSIS:	implement <= operator
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 1/ 6/95	Initial version			     
 * 
 *********************************************************************/
void
OpLessEqual(RMLPtr rms, RVal rv1, RVal rv2)
{
    sword res;
    LegosType resType;

    /* Find the result */

    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
    case TYPE_INTEGER:
	res = (sword) rv1.value <= (sword) rv2.value;
	break;
    case TYPE_LONG:
	res = (sdword) rv1.value <= (sdword) rv2.value;
	break;
    case TYPE_FLOAT:
#ifndef LIBERTY
	if (almostEqual(ToFloat(rv1.value,rv1.type),
			ToFloat(rv2.value,rv2.type))) {
	    res = TRUE;
	}
	else
#endif

	res = ToFloat(rv1.value,rv1.type) <= ToFloat(rv2.value,rv2.type);
	break;
    default:
	RunSetError(rms->ptask,RTE_ARG_NOT_A_NUMBER);
	return;
    }

    PushData(res);
    PushType(TYPE_INTEGER);
    	
}

/*********************************************************************
 *			OpGreaterEqual
 *********************************************************************
 * SYNOPSIS:	implement >= operator
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 1/ 6/95	Initial version			     
 * 
 *********************************************************************/
void
OpGreaterEqual(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword res;
    LegosType resType;

    /* Find the result */

    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
    case TYPE_INTEGER:
	res = (sword) rv1.value >= (sword) rv2.value;
	break;
    case TYPE_LONG:
	res = (sdword) rv1.value >= (sdword) rv2.value;
	break;
    case TYPE_FLOAT:
#ifndef LIBERTY
	if (almostEqual(ToFloat(rv1.value,rv1.type),
			ToFloat(rv2.value,rv2.type))) {
	    res = TRUE;
	}
	else
#endif
	res = ToFloat(rv1.value,rv1.type) >= ToFloat(rv2.value,rv2.type);
	break;
    default:
	RunSetError(rms->ptask,RTE_ARG_NOT_A_NUMBER);
	return;
    }

    PushData(res);
    PushType(TYPE_INTEGER);
    	
}

/*********************************************************************
 *			OpLessGreater
 *********************************************************************
 * SYNOPSIS:	implement <> operator
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 1/ 6/95	Initial version			     
 * 
 *********************************************************************/
void
OpLessGreater(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword res;
    LegosType resType;

    /* Find the result */

    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
#ifndef LIBERTY
    case TYPE_MODULE:
#endif
    case TYPE_INTEGER:
	res = (sword) rv1.value != (sword) rv2.value;
	break;
    case TYPE_COMPONENT:    	/* FIXME when components become more
				 * than just optrs... */
#ifdef LIBERTY
    case TYPE_MODULE:
#endif
    case TYPE_LONG:
	res = (sdword) rv1.value != (sdword) rv2.value;
	break;
    case TYPE_FLOAT:
#ifndef LIBERTY
	if (almostEqual(ToFloat(rv1.value,rv1.type),
			ToFloat(rv2.value,rv2.type))) {
	    res = FALSE;
	}
	else
#endif

	res = ToFloat(rv1.value,rv1.type) != ToFloat(rv2.value,rv2.type);
	break;
    case TYPE_STRING:
    {
	TCHAR    	*s1, *s2;

	RunHeapLock(rms->rhi, rv1.value, (void**)(&s1));
	RunHeapLock(rms->rhi, rv2.value, (void**)(&s2));
	res = strcmp(s1, s2);
	RunHeapDecRefAndUnlock(rms->rhi, rv1.value, s1);
	RunHeapDecRefAndUnlock(rms->rhi, rv2.value, s2);
    }
	break;
    default:
	RunSetError(rms->ptask,RTE_INCOMPATIBLE_TYPES);
	return;
    }

    PushData(res);
    PushType(TYPE_INTEGER);
    	
}

/*********************************************************************
 *			OpSubtract
 *********************************************************************
 * SYNOPSIS:	Perform a binary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void
OpSubtract(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword intRes;
    sdword longRes;
    float floatRes;
    LegosType resType;
    
    /* figure out all the type possible type casts */
    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
	case TYPE_INTEGER:
	    intRes = (sword) rv1.value - (sword) rv2.value;
	    PushData(intRes);
	    break;
	case TYPE_LONG:
	    longRes = (sdword) rv1.value - (sdword) rv2.value;
	    PushData(longRes);
	    break;
	case TYPE_FLOAT:
	    floatRes = ToFloat(rv1.value,rv1.type) - ToFloat(rv2.value,rv2.type);
	    PushData(*(dword*)&floatRes);
	    break;
	default:
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	    return;
    }


    PushType(resType);
   
}

/*********************************************************************
 *			OpBitAnd
 *********************************************************************
 * SYNOPSIS:	Perform a binary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void
OpBitAnd(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword     	intRes;
    sdword    	longRes;
    LegosType  	resType;


    /* figure out all the type possible type casts */
    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
	case TYPE_INTEGER:
	    intRes = (word)rv1.value & (word)rv2.value;
	    PushData(intRes);
	    break;
	case TYPE_LONG:
	    longRes = (dword)rv1.value & (dword)rv2.value;
	    PushData(longRes);
	    break;
	default:
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	    return;
    }


    PushType(resType);
}

/*********************************************************************
 *			OpBitXor
 *********************************************************************
 * SYNOPSIS:	Perform a binary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void
OpBitXor(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword     	intRes;
    sdword    	longRes;
    LegosType  	resType;


    /* figure out all the type possible type casts */
    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
	case TYPE_INTEGER:
	    intRes = (word) rv1.value ^ (word) rv2.value;
	    PushData(intRes);
	    break;
	case TYPE_LONG:
	    longRes = (dword) rv1.value ^ (dword) rv2.value;
	    PushData(longRes);
	    break;
	default:
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	    return;
    }


    PushType(resType);

}

/*********************************************************************
 *			OpBitOr
 *********************************************************************
 * SYNOPSIS:	Perform a binary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void
OpBitOr(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword     	intRes;
    sdword    	longRes;
    LegosType  	resType;


    /* figure out all the type possible type casts */
    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
	case TYPE_INTEGER:
	    intRes = (word) rv1.value | (word) rv2.value;
	    PushData(intRes);
	    break;
	case TYPE_LONG:
	    longRes = (dword) rv1.value | (dword) rv2.value;
	    PushData(longRes);
	    break;
	default:
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	    return;
    }


    PushType(resType);
}

/*********************************************************************
 *			OpMultiply
 *********************************************************************
 * SYNOPSIS:	Perform a binary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void
OpMultiply(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword     	intRes;
    sdword    	longRes;
    float   	floatRes;
    LegosType  	resType;


    /* figure out all the type possible type casts */
    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
	case TYPE_INTEGER:
	    intRes = (sword) rv1.value * (sword) rv2.value;
	    PushData(intRes);
	    break;
	case TYPE_LONG:
	    longRes = (sdword) rv1.value * (sdword) rv2.value;
	    PushData(longRes);
	    break;
	case TYPE_FLOAT:
	    floatRes = ToFloat(rv1.value,rv1.type) * ToFloat(rv2.value,rv2.type);
	    PushData(*(dword*)&floatRes);
	    break;
	default:
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	    return;
    }


    PushType(resType);

}

/*********************************************************************
 *			OpDivide
 *********************************************************************
 * SYNOPSIS:	Perform a binary operation on the given
 *              operands (and their types) and push the result.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/29/94	Initial version			     
 * 
 *********************************************************************/
void
OpDivide(RMLPtr rms, RVal rv1, RVal rv2) 
{
    sword     	intRes;
    sdword    	longRes;
    float   	floatRes;
    LegosType  	resType;

    /* figure out all the type possible type casts */
    resType = FindResultType(rv1.type, rv2.type);

    switch(resType) 
    {
	case TYPE_INTEGER:
	    if ((sword) rv2.value == 0)
	    {
		RunSetError(rms->ptask, RTE_DIVIDE_BY_ZERO);
		return;
	    }
	    intRes = (sword) rv1.value / (sword) rv2.value;
	    PushData(intRes);
	    break;
	case TYPE_LONG:
	    if ((sdword) rv2.value == 0)
	    {
		RunSetError(rms->ptask, RTE_DIVIDE_BY_ZERO);
		return;
	    }
	    longRes = (sdword) rv1.value / (sdword) rv2.value;
	    PushData(longRes);
	    break;
	case TYPE_FLOAT:
	    if (ToFloat(rv2.value,rv2.type) == 0.0)
	    {
		RunSetError(rms->ptask, RTE_DIVIDE_BY_ZERO);
		return;
	    }
	    floatRes = ToFloat(rv1.value,rv1.type) / ToFloat(rv2.value,rv2.type);
	    PushData(*(dword*)&floatRes);
	    break;
	default:
	    RunSetError(rms->ptask, RTE_ARG_NOT_A_NUMBER);
	    return;
    }


    PushType(resType);
}

/*********************************************************************
 *			FindResultType
 *********************************************************************
 * SYNOPSIS:	Figure out the highest cast level required
 *              to compute an operation between these two types.
 *              Can be INT, LONG, or FLOAT.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	10/24/94		Initial version			     
 * 
 *********************************************************************/
LegosType
FindResultType(LegosType 	    type1, 
	       LegosType	    type2) 
{
    switch (type1) 
    {
    case TYPE_INTEGER:

	if (type2 == TYPE_INTEGER || type2 == TYPE_LONG || type2 == TYPE_FLOAT)
	{
	    /* type2 will have a cast level >= int, so just return that */
	    return type2;
	}
	else
	{
	    /* numbers must be assigned to numbers, 
	     * ie.  no STRINGS or COMPONENTS or ARRAYS
	     */
	    return TYPE_ILLEGAL;
	}

    case TYPE_LONG:
	switch (type2) 
	{
	case TYPE_INTEGER:
	    /* If second is integer, we need to return long */
	    return TYPE_LONG;
	default:
	    /* Otherwise, type2 will be long or float, that's fine */
	    if (type2 == TYPE_LONG || type2 == TYPE_FLOAT) {
		return type2;
	    } else {
		return TYPE_ILLEGAL;
	    }
	}

    case TYPE_FLOAT:
	if (type2 == TYPE_FLOAT || type2 == TYPE_LONG || type2 == TYPE_INTEGER) {
	    return TYPE_FLOAT;
	} else {
	    return TYPE_ILLEGAL;
	}

    default:
	/* for non-numbers, either the two are the same, or we can a problem
	 */
	if (type2 == type1) {
	    return type1;
	} else {
	    return TYPE_ILLEGAL;
	}
    }
}
#ifndef LIBERTY

/*********************************************************************
 *			almostEqual
 *********************************************************************
 * SYNOPSIS:	Check to see if two floats are "almost" equal.
 *              A GEOS hack to deal with the fact that our software FP
 *              library isn't IEEE compliant.
 * 
 *              The floating point representation of 1.2 + .8 isn't
 *              the same as the representation of 2.0. Fortunately,
 *              however, if the bit reps are casted into unsigned longs
 *              and compared they will be off by exactly one. 
 *              So that's the current strategy...
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/ 1/95	Initial version
 * 
 *********************************************************************/
Boolean
almostEqual(float a, float b)
{
    LegosData		x,y;
    unsigned long	diff;

    x.LD_float = a;
    y.LD_float = b;

    if (x.LD_gen_dword > y.LD_gen_dword)
	diff = x.LD_gen_dword - y.LD_gen_dword;
    else
	diff = y.LD_gen_dword - x.LD_gen_dword;

    return (diff <= 1);
}


/*********************************************************************
 *			SmartRound
 *********************************************************************
 * SYNOPSIS:	If a float is very close to an integer, set it to be
 *              the right value....
 *             
 *              This is again to "solve" some cruddy fp problems.
 *
 *              when coercing 1.2 + .8 to an int, we should get 2.
 *
 *              Assumes the float can be converted into a long without
 *              overflow..
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 6/ 2/95	Initial version
 * 
 *********************************************************************/
long SmartTrunc(float f) {

    LegosData x;
    long l1,l2;
    int i,tolerance;

    /* Sorry if this is cryptic, but this is a hack in every
       sense of the word... 

       The key to the strategy is to cast the float's bit rep.
       into an unsigned long. Then, try subtracting one or
       adding one to that value, and see the new value does
       a better job of truncating.

       We say a better job by checking to see if we get a 
       different answer which is closer to the original float.

       Amazingly, this works for cases like

       1.2 + .8 --> 2,  12.3 + 12.7 --> 25.

       Hopefully this is good enough.   You can muck
       with the tolerance if you wish.  Note that this is damn slow...
    */

    
    tolerance = 1;

    l1 = f;
    x.LD_float = f;
    x.LD_gen_dword -= tolerance;

    for (i = 0; i <= 2*tolerance; i+= 2*tolerance) {

	x.LD_gen_dword += i;
	
	l2 = x.LD_float;
	
	if (l1 != l2) {
	
	    if ( fabs(f - l1) < fabs(f - l2) ) { 
		return l1;
	    }
	    else {
		return l2;
	    }
	}
    }

    return l1;
}
    

    

#endif
