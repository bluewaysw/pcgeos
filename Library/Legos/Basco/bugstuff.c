/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	LEGOS
MODULE:		
FILE:		bugstuff.c

AUTHOR:		Roy Goldman, Jul  7, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 7/95   	Initial version.

DESCRIPTION:
	Debugging stuff that can safely be in the compiler library.

	Currently, only used for initialization & other compile task
	stuff, and also for code used to extract variable values.

	By leaving this out of basrun we can avoid including stable
	there.... Hope you guys agree it was worth it.
	
	$Id: bugstuff.c,v 1.1 98/10/13 21:42:30 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include "mystdapp.h"
#include <math.h>
#include <Legos/bascobug.h>
#include <Legos/rpc.h>
#include <Legos/basrun.h>
#include <Legos/Internal/runtask.h>
#include <Legos/Internal/progtask.h>
#include <Legos/runheap.h>
#include "bascoint.h"
#include "vtab.h"
#include "fixds.h"
#include "stable.h"
#include "btoken.h"
#include "ftab.h"

void BascoDBCS2SBCS(wchar_t *dbcsString);

#if ERROR_CHECK
#define EC_CHECK_PTASKHAN(_p) ECCheckPTaskHan(_p)
void ECCheckPTaskHan(PTaskHan p) {
    PTaskPtr ptask = MemLock(p);
    EC_ERROR_IF(ptask->PT_cookie != PTASK_COOKIE, -1);
    MemUnlock(p);
}
#define ASSERT(_test) EC_ERROR_IF(!(_test), BE_FAILED_ASSERTION)
#else
#define EC_CHECK_PTASKHAN(_p)
#define ASSERT(_test)
#endif

/*********************************************************************
 *                      BascoBugInit
 *********************************************************************
 * SYNOPSIS:    Initialize the debugging information:
 *                 * initialize an empty breakpoint list
 *                 * Fill in the buggerInfo with the build-time
 *                   hugearray with linenumbers for each routine...
 *                 * Fill in buggerInfo with the compile time's function
 *                   array and the compiler task's vmfile.
 * CALLED BY:   
 * RETURN:      Runtask supplied will now contain a reference
 *              to the BugInfo memhandle.
 *      
 * SIDE EFFECTS:
 * STRATEGY:     The BugHandle only gets references to compile
 *               time information...
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/17/95        Initial version                      
 * 
 *********************************************************************/
void BascoBugInit(MemHandle ctaskHan, BugBuilderInfo* bbi)
{
    MemHandle	bugHandle;
    TaskPtr	ctask;
    BugInfoHeader *b;
    ChunkHandle	ca;

    EC_ERROR_IF(bbi == NULL, BUGGER_FAILED_ASSERTION);

    /* Some initial allocation.  Breakpoint list starts out empty.
     */
    bugHandle = MemAllocLMem(LMEM_TYPE_GENERAL, sizeof(BugInfoHeader));
    MemModifyFlags(bugHandle, HF_SHARABLE, 0);
    (void) MemLock(bugHandle);
    ca = ChunkArrayCreate(bugHandle, sizeof(BugBreakPoint), 0,0);
    b = MemDeref(bugHandle);

    /* Fill in most fields
     */
    ctask = MemLock(ctaskHan);
    EC_BOUNDS(ctask);

    /* this can be done later, we are going to call BugInit from
     * BascoAllocTask, and then fill in these fields after compiling
     * code
     */
    ctask->bugHandle = bugHandle;
    MemUnlock(ctaskHan);

    b->BIH_breakArray = ca;
    b->BIH_breakLine = NULL_LINE;
    b->BIH_builderRequest = BBR_NONE;
    b->BIH_displacedInsn = OP_ILLEGAL;

    b->BIH_destObject    = bbi->BBI_destObject;
    b->BIH_destMessage   = bbi->BBI_destMessage;
    b->BIH_finishMessage = bbi->BBI_finishMessage;

    b->BIH_runTaskHan      = NullHandle;
    b->BIH_funcLabelTable   = NullHandle;
    b->BIH_runMainLoopCount = 0;
    MemUnlock(bugHandle);

    /* We need some way to install breakpoints from our source code
     * into our runtime engine.
     *
     * The most efficient way to do this is to keep track of all
     * breakpoints from the builder and communicate those directly.
     * Right now, however, the builder has no clue--all such
     * information is attached to the actual source line within the
     * compile task.
     *
     * The next most efficient method is to keep track of breakpoints
     * as we parse, since we process every line as we do that.
     *
     * The least efficient, but the easiest, hence the one I chose, is
     * to take yet another pass over the source code and collect all
     * breakpoints, and then set them since the compiled code has been
     * transferred to the runtask...
     */
    return;
}

/*********************************************************************
 *                      BascoBugGetBugHandleFromCTask
 *********************************************************************
 * SYNOPSIS:    Return the bug handle of an rtask
 * CALLED BY:   GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      2/12/95        Initial version                      
 * 
 *********************************************************************/
MemHandle BascoBugGetBugHandleFromCTask(MemHandle ctaskHan) 
{
    Task *task;
    MemHandle ret;

    task = MemLock(ctaskHan);
    EC_BOUNDS(task);
    ret = task->bugHandle;
    MemUnlock(ctaskHan);

    return ret;
}

/* --------------------------------------------- */
/* VARIABLES                                     */
/* --------------------------------------------- */

/*********************************************************************
 *                      BascoBugGetNumVars
 *********************************************************************
 * SYNOPSIS:  Returns the number of variables in the given frame
 *            or the number of module-level variables if MODULE_LEVEL
 *            is passed in as the frameNum.  
 * CALLED BY:   GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Uses return value of zero as an error condition
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/24/95        Initial version                      
 * 
 *********************************************************************/
word
BascoBugGetNumVars(PTaskHan ptaskHan, sword frameNum) 
{
    word	result;
     
    if (IsRpcPTask(ptaskHan)) {
	BasrunRpcCall(RpcRTask2SerialUnit(ptaskHan),
		      RPC_DEFAULT_TIMEOUT, RPC_GET_NUM_VARS,
		      sizeof(word), &frameNum,
		      sizeof(word), &result);
    } else {
	result = BugGetNumVars(ptaskHan, frameNum);
    }
    
    EC_ERROR_IF (result > 32000, BUGGER_FAILED_ASSERTION);
    return result;
}

/*********************************************************************
 *			BascoBugGetNumFields
 *********************************************************************
 * SYNOPSIS:	get number of fields in a struct
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Return 0 if operation failed for some reason.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 7/ 5/95	Initial version
 * 
 *********************************************************************/
word
BascoBugGetNumFields(PTaskHan ptaskHan, sword frameNumber, word varNum)
{
    PTaskPtr	ptask;
    BugInfoHeader *b;

    VTabEntry	vte;
    word	fields;
    word	gotVte = 0;

    EC_ERROR_IF(IsRpcPTask(ptaskHan), -1);

    ptask = MemLock(ptaskHan);
    EC_ERROR_IF(ptask->PT_cookie != PTASK_COOKIE, -1);
    b = MemLock(ptask->PT_bugHandle);

    if (frameNumber == MODULE_LEVEL)
    {
	/* need to use LookupOffset since things might be out of order */
	/* therefore, this only works for debugged modules */
	VTLookupOffset(b->BIH_vtabHeap, GLOBAL_VTAB, varNum*VAR_SIZE, &vte);
	gotVte = 1;
    }
    else
    {
	word		funcNum;
	FTabEntry*	ftab;
	Boolean		isDebugged;

	isDebugged = BugGetFrameInfo(ptaskHan, frameNumber, &funcNum);
	if (isDebugged && (funcNum < FTabGetCount(b->BIH_funcTable)))
	{
	    ftab = FTabLock(b->BIH_funcTable, funcNum);
	    VTLookupIndex(b->BIH_vtabHeap, ftab->vtab, varNum, &vte);
	    FTabUnlock(ftab);
	    gotVte = 1;
	}
    }

    if (gotVte)
    {
	word	s_vte;		/* vte for the struct */

	/*bv = BascoBugGetSetVar(ptaskHan, frameNumber, varNum, bv, GET_VAR);*/
	s_vte = StringTableGetData(b->BIH_structIndex, vte.VTE_extraInfo);
	fields = VTGetCount(b->BIH_vtabHeap, s_vte);
    } else {
	fields = 0;
    }

    MemUnlock(ptask->PT_bugHandle);
    MemUnlock(ptaskHan);
    return fields;
}

/*********************************************************************
 *                      BascoBugGetSetVar
 *********************************************************************
 * SYNOPSIS:    Returns the data for the variable of index varIndex
 *              in the frameNumber frame on the call stack OR
 *              from the module level variables if MODULE_LEVEL
 *              is supplied as the frame number.
 * CALLED BY:   GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/24/95        Initial version                      
 * 
 *********************************************************************/
BugVar
BascoBugGetSetVar(PTaskHan ptaskHan,
		    sword frameNumber, word varIndex,
		    BugVar sVar, Boolean set) 
{
    BugVar	bv;

    if (IsRpcPTask(ptaskHan)) {
	if (set) {
	    RpcSetVarArgs    rsva;

	    rsva.rsva_frame = frameNumber;
	    rsva.rsva_varIndex = varIndex;
	    rsva.rsva_bugVar = sVar;

    	    BasrunRpcCall(RpcRTask2SerialUnit(ptaskHan), RPC_DEFAULT_TIMEOUT,
			  RPC_SET_VAR,
			  sizeof(RpcSetVarArgs), &rsva,
			  0, 0);
	} else {
	    RpcGetVarArgs    rgva;

	    rgva.rgva_frame = frameNumber;
	    rgva.rgva_varIndex = varIndex;
    	    BasrunRpcCall(RpcRTask2SerialUnit(ptaskHan), RPC_DEFAULT_TIMEOUT,
			  RPC_GET_VAR,
			  sizeof(RpcSetVarArgs), &rgva,
			  sizeof(BugVar), &bv);
	}
    } else {
	bv = BugGetSetVar(ptaskHan, frameNumber, varIndex, sVar, set);
    }

    return bv;
}

/*********************************************************************
 *			BascoBugGetArrayDims
 *********************************************************************
 * SYNOPSIS:	get the number of elements in an array
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 7/ 5/95	Initial version
 * 
 *********************************************************************/
word
BascoBugGetArrayDims(PTaskHan ptaskHan, sword frame,
		       word varNum, word dims[])
{
    ArrayHeader *ah;
    word	numDims, i;
    BugVar	bv;

#if ERROR_CHECK
    PTaskPtr	ptask;
    ptask = MemLock(ptaskHan); (void)ptask;
    EC_ERROR_IF(ptask->PT_cookie != PTASK_COOKIE, -1);
    MemUnlock(ptaskHan);
#endif

    bv = BascoBugGetSetVar(ptaskHan, frame, varNum, bv, GET_VAR);
    ASSERT(bv.BV_type == TYPE_ARRAY);

    ah = MemLock(bv.BV_data);
    numDims = ah->AH_numDims;
    for (i = 0; i < numDims; i++)
    {
	EC_BOUNDS(&(dims[i]));
	dims[i] = ah->AH_dims[i];
    }
    MemUnlock(bv.BV_data);

    return numDims;
}


/*********************************************************************
 *			BascoBugGetArrayElement
 *********************************************************************
 * SYNOPSIS:	get an array element
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	Set operation does not support tethered
 *		Supports !debug modules
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 7/ 5/95	Initial version
 * 
 *********************************************************************/
BugVar
BascoBugGetSetArrayElement(PTaskHan ptaskHan, sword frame, word varNum,
			     word element, BugVar sVar, Boolean set)
{
    ArrayHeader	*ah;
    BugVar  	bv_arr, bv_elt;
    
    if (IsRpcPTask(ptaskHan)) {
	ASSERT(!set);
    } else {
	EC_CHECK_PTASKHAN(ptaskHan);
    }

    bv_arr = BascoBugGetSetVar(ptaskHan, frame, varNum, bv_arr, GET_VAR);
    ASSERT(bv_arr.BV_type == TYPE_ARRAY);
    ah = MemLock(bv_arr.BV_data);
    ASSERT(element < ah->AH_maxElt);

    bv_elt.BV_type = ah->AH_type;
    ah++;

    switch (bv_elt.BV_type) {
    case TYPE_STRING:
    case TYPE_COMPLEX:
    case TYPE_STRUCT:
				/* FIXME: decref */
    case TYPE_INTEGER:
    case TYPE_MODULE:
	if (set) {
	    if (bv_elt.BV_type == sVar.BV_type) {
		*(word *)(((word *)ah)+element) = sVar.BV_data;
	    }
	} else {
	    bv_elt.BV_data = *(word *)(((word *)ah)+element);
	}
	break;
    case TYPE_LONG:
    case TYPE_FLOAT:
    case TYPE_COMPONENT:
	if (set) {
	    if (bv_elt.BV_type == sVar.BV_type) {
		*(dword *)(((dword *)ah)+element) = sVar.BV_data;
	    } else if (bv_elt.BV_type == TYPE_LONG &&
		       sVar.BV_type == TYPE_INTEGER)
	    {
		*((sdword*)(((sdword *)ah)+element)) = (sword)sVar.BV_data;
	    }
	} else {
	    bv_elt.BV_data = *(dword *)(((dword *)ah)+element);
	}

	break;
    default:
	EC_ERROR(BE_FAILED_ASSERTION);
    }
    
    MemUnlock(bv_arr.BV_data);
    return bv_elt;
}

/*********************************************************************
 *			BascoBugGetSetStructFieldData
 *********************************************************************
 * SYNOPSIS:	get info from a runtime struct
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	Does not support tethering
 *		Does not support !debugged modules
 *		On error, return <TYPE_ILLEGAL, 0>
 *
 *	The requested variable can be an array, in which case we
 *	will extract the field from the <arrayElement>th struct.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 7/ 3/95	Initial version
 * 
 *********************************************************************/
BugVar
BascoBugGetSetStructFieldData
    (PTaskHan ptaskHan, sword frame, word varNum, word fieldNum,
     TCHAR *dest,		/* <- Name of the struct field */
     word arrayElement,
     BugVar sVar, Boolean set	/* if set, set to value in svar */
     )
{
    word	funcNum;

    PTaskPtr	ptask;
    BugInfoHeader *bih;
    BugVar  	bv;
    BugVar	fv;
    byte    	*data;

    VTabEntry	fte;
    word    	stab;
    TCHAR	*name;
    word    	structData;

    /* in case of problems, start out returing a NULL string in dest */
    dest[0] = C_NULL;

    /* Currently no tether or non-debugged module support */
    EC_ERROR_IF(IsRpcPTask(ptaskHan), -1);
    if (frame != MODULE_LEVEL)
    {
	Boolean		hasBugInfo;
	hasBugInfo = BugGetFrameInfo(ptaskHan, frame, &funcNum);
	if (!hasBugInfo) goto error;
    }

    ptask = MemLock(ptaskHan);
    EC_ERROR_IF(ptask->PT_cookie != PTASK_COOKIE, -1);
    bih = MemLock(ptask->PT_bugHandle);

    /* stab <- var table for the structure
     */
    if (frame == MODULE_LEVEL)
    {
	VTabEntry	vte;
	/* need to use LookupOffset since things might be out of order */
	VTLookupOffset(bih->BIH_vtabHeap, GLOBAL_VTAB, varNum*VAR_SIZE, &vte);
	stab = StringTableGetData(bih->BIH_structIndex, vte.VTE_extraInfo);
    }
    else
    {
	VTabEntry	vte;
	FTabEntry*	ftab;

	if (funcNum >= FTabGetCount(bih->BIH_funcTable)) goto error;
	ftab = FTabLock(bih->BIH_funcTable, funcNum);
	VTLookupIndex(bih->BIH_vtabHeap, ftab->vtab, varNum, &vte);
	FTabUnlock(ftab);
	stab = StringTableGetData(bih->BIH_structIndex, vte.VTE_extraInfo);
    }

    /* get the RunHeap key for the struct variable */
    bv = BascoBugGetSetVar(ptaskHan, frame, varNum, bv, GET_VAR);
    if (bv.BV_type == TYPE_ARRAY) 
    {	
	word	*temp;

	/* lock down the array and grab the info */
	temp = (word *)((byte *)MemLock(bv.BV_data) + sizeof(ArrayHeader));
	structData = *(temp+arrayElement);
	MemUnlock(bv.BV_data);
    } else {
	structData = bv.BV_data;
	/* nothing to get if its a Null Structure */
	if ((structData == NULL_TOKEN) && set) goto errorUnlock;
    }

    /* ok, this means we are trying to look at a field that does not
     * exist, so punt -
     */
    if ((RunHeapDataSize(&(ptask->PT_runHeapInfo), structData)/VAR_SIZE <=
	fieldNum) && (structData != NULL_TOKEN))
    {
	goto errorUnlock;
    }


    if (set)
    {
	/* if we are overwriting a RunHeapToken type, we need to decref it
	 * FIXME - for now the only thing you can do in the builder that
	 * would cause this to happen is change a string
	 * theoretically, we will be able to do other types in the future
	 */
	if (structData != NULL_TOKEN) {
	    RunHeapLock(&(ptask->PT_runHeapInfo), structData, (void**)&data);
	    data += (fieldNum * VAR_SIZE);
	    if (*(LegosType *)(data+VAR_SIZE-1) == sVar.BV_type) {
		if (*(LegosType *)(data+VAR_SIZE-1) == TYPE_STRING) {
		    RunHeapDecRef(&(ptask->PT_runHeapInfo),
				  *(RunHeapToken *)data);
		}
		*(dword *)data = sVar.BV_data;
	    }
	    RunHeapUnlock(&(ptask->PT_runHeapInfo), structData);
	}
    }
    else
    {
	word	oldDS;

	VTLookupIndex(bih->BIH_vtabHeap, stab, fieldNum, &fte);
	name = StringTableLock(bih->BIH_stringIdentTable, fte.VTE_name);

	if (name == NULL) goto errorUnlock;

	oldDS = setDSToDgroup();
	sprintf(dest, _TEXT("%s"), name);
	restoreDS(oldDS);
	StringTableUnlock(name);
    
	fv.BV_type = fte.VTE_type;
	if (structData == NULL_TOKEN) {
	    fv.BV_data = 0;
	} else {
	    RunHeapLock(&(ptask->PT_runHeapInfo), structData, (void**)&data);
	    data = (byte *)data + VAR_SIZE * fieldNum;
	    fv.BV_data = *(dword *)data;
	    RunHeapUnlock(&(ptask->PT_runHeapInfo), structData);
	}
    }
 unlock:
    MemUnlock(ptask->PT_bugHandle);
    MemUnlock(ptaskHan);
    return fv;

 errorUnlock:
    MemUnlock(ptask->PT_bugHandle);
    MemUnlock(ptaskHan);
 error:
    fv.BV_type = TYPE_ILLEGAL;
    fv.BV_data = 0;
    return fv;
    
}

/*********************************************************************
 *                      BascoBugGetVarName
 *********************************************************************
 * SYNOPSIS:    Gets a pointer to the string representation
 *              of a variable name, either for local variables
 *              in the specified frame or for module-level variables
 *              if MODULE_LEVEL is supplied as the frame number.
 * CALLED BY:   GLOBAL
 * RETURN:      dest
 * SIDE EFFECTS:
 * STRATEGY:	Returns NULL on error, sets dest to "?".
 *		Doesn't support !debug modules
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/25/95        Initial version                      
 * 
 *********************************************************************/
TCHAR*
BascoBugGetVarName(PTaskHan ptaskHan, MemHandle ctaskHan,
		     sword frame, word varNum,
		     TCHAR *dest) 
{
    MemHandle   bugHan;
    BugInfoHeader *bih;

    word	nameId;
    TCHAR   	*name;
    VTabEntry	vte;

    EC_BOUNDS(dest);
    dest[0] = '\0';

    if (IsRpcPTask(ptaskHan)) {
	bugHan = BascoBugGetBugHandleFromCTask(ctaskHan);
    } else {
	PTaskPtr	ptask;
	ptask = MemLock(ptaskHan);
	ASSERT(ptask->PT_cookie == PTASK_COOKIE);
	bugHan = ptask->PT_bugHandle;
	MemUnlock(ptaskHan);
    }

    bih = MemLock(bugHan);

    if (frame == MODULE_LEVEL)
    {
	if (varNum >= VTGetCount(bih->BIH_vtabHeap, GLOBAL_VTAB)) {
	    goto errorDone;
	}
	/* need to use LookupOffset since things might be out of order */
	VTLookupOffset(bih->BIH_vtabHeap, GLOBAL_VTAB, varNum*VAR_SIZE, &vte);
    }
    else
    {
	word		funcNum;
	FTabEntry*	ftab;
	Boolean		debug;

	debug = BascoBugGetFrameInfo(ptaskHan, frame, &funcNum);
	if (!debug) {
	    /* Just create one */
	    word	oldDS = setDSToDgroup();

	    strcpy(dest, _TEXT("var"));
	    dest += 3;
	    UtilHex32ToAscii(dest, varNum, UHTAF_NULL_TERMINATE);
	    
	    restoreDS(oldDS);
	    goto done;
	}
	if (funcNum >= FTabGetCount(bih->BIH_funcTable))
	    goto errorDone;

	ftab = FTabLock(bih->BIH_funcTable, funcNum);
	if (varNum >= VTGetCount(bih->BIH_vtabHeap, ftab->vtab))
	{
	    FTabUnlock(ftab);
	    goto errorDone;
	}

	VTLookupIndex(bih->BIH_vtabHeap, ftab->vtab, varNum, &vte);
	FTabUnlock(ftab);
    }

    nameId = vte.VTE_name;

    name = StringTableLock(bih->BIH_stringIdentTable, nameId);

    EC_BOUNDS(name);
    EC_BOUNDS(dest+strlen(name));
    strcpy(dest, name);

    StringTableUnlock(name);
    
 done:
    MemUnlock(bugHan);
    return dest;
 errorDone:
    MemUnlock(bugHan);
    return NULL;
}

/*********************************************************************
 *                      BascoBugNumVarToString
 *********************************************************************
 * SYNOPSIS:    Assumes that the given variable represents a number,
 *              TYPE_INTEGER, TYPE_LONG, or TYPE_FLOAT, and writes
 *              out the ASCII representation of that value into
 *              the supplied dest buffer, which MUST be large
 *              enough. To be safe, something like a 32 byte buffer
 *              should always be big enough.... 
 *
 *              NOTE NOTE NOTE NOTE:
 *              
 *              Do NOT use this routine for variables of type OP_STRING.
 *              Use the string table routines to get a pointer to
 *              the actual string...
 *              
 * CALLED BY:   GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy      1/25/95        Initial version                      
 * 
 *********************************************************************/
void
BascoBugNumVarToString(BugVar bv, TCHAR *dest) 
{
    float f;

    if (bv.BV_type != TYPE_FLOAT)
    {
	long	l;

	if (bv.BV_type == TYPE_INTEGER) {
	    l = *(int*)&(bv.BV_data);
	} else {
	    l = *(long*)&(bv.BV_data);
	}

	if (l < 0) 
	{
	    *dest++ = C_MINUS;
	    l = -l;
	}
	UtilHex32ToAscii(dest, l, UHTAF_NULL_TERMINATE);
	return;
    }

    if (bv.BV_type == TYPE_FLOAT) {
	f = *(float*)&(bv.BV_data);
    }
#if ERROR_CHECK
    else
	EC_ERROR(-1);
#endif

    FloatIEEE32ToGeos80(&f);
    FloatFloatToAscii_StdFormat(dest, NULL, 0, 12, 6);
}

/*********************************************************************
 *			BascoBugGetString
 *********************************************************************
 * SYNOPSIS:	Fill in a character buffer with a string constant
 *              if maxLen is 0, copy entire string.
 *              Otherwise, copy over maxLen bytes followed by a null
 *              terminator.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 2/16/95	Initial version			     
 * 
 *********************************************************************/
void 
BascoBugGetString(PTaskHan ptaskHan, dword stringIndex,
		    TCHAR *dest, word maxLen) 
{
    if (IsRpcPTask(ptaskHan)) {
	wchar_t    buffer[128];

	BasrunRpcCall(RpcRTask2SerialUnit(ptaskHan), RPC_DEFAULT_TIMEOUT, RPC_GET_STRING,
		      sizeof(dword), &stringIndex, 255, buffer);

	if (maxLen > 127) {
	    maxLen = 127;
	}

#ifndef DO_DBCS
	BascoDBCS2SBCS(buffer);
#endif
	strncpy(dest, (TCHAR*)buffer,  maxLen);
    } else {
	BugGetString(ptaskHan, stringIndex, dest, maxLen);
    }
}

/*********************************************************************
 *			BascoBugCreateString
 *********************************************************************
 * SYNOPSIS:	Fill in a character buffer with a string constant
 *              if maxLen is 0, copy entire string.
 *              Otherwise, copy over maxLen bytes followed by a null
 *              terminator.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 2/16/95	Initial version			     
 * 
 *********************************************************************/
BugVar
BascoBugCreateString(PTaskHan ptaskHan, TCHAR *src, BugVar oldVar)
{
    BugVar     bv;

    if (IsRpcPTask(ptaskHan)) {
	byte       buffer[254];
	word       srcLen;

	/*
	 * This is kind of a pain in the ass; we have to tack the
	 * BugVar on to the front of the string so as to pass the thing
	 * over the serial line in one big lump.
	 */

	*((BugVar *) buffer) = oldVar;
	srcLen = strlen(src) + 1;

	if ((srcLen * sizeof(TCHAR)) > (254 - sizeof(BugVar))) {
	    srcLen = (254 - sizeof(BugVar)) / sizeof(TCHAR);
	}

	strncpy((char *)&(buffer[sizeof(BugVar)]), src, srcLen);

	BasrunRpcCall(RpcRTask2SerialUnit(ptaskHan), RPC_DEFAULT_TIMEOUT, RPC_CREATE_STRING,
		      sizeof(BugVar) + (srcLen * sizeof(TCHAR)),
		      &buffer, sizeof(BugVar), &bv);
    } else {
	bv = BugCreateString(ptaskHan, src, oldVar);
    }
    return bv;
}

/*********************************************************************
 *		    	BascoBugStringToNumber
 *********************************************************************
 * SYNOPSIS:	convert a string into a number
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/14/96  	Initial version
 * 
 *********************************************************************/
extern Token ScanNumber(TCHAR *str, word *pos);
BugVar
BascoBugStringToNumber(TCHAR *str, LegosType type)
{
    Token   token;
    word    pos;
    BugVar  bvar;
    sword   minus;
    TCHAR   *cp;
    word    oldDS;

    oldDS = setDSToDgroup();
    pos = 0;
    minus = 1;
    adv_ws(str, (int*)&pos);
    if (str[pos] == C_MINUS)
    {
	minus  = -1;
	pos++;
    }
    cp = str+pos;
    pos = 0;
    token = ScanNumber(cp, &pos);
    bvar.BV_type = TokenToType(token.code);
    bvar.BV_data = token.data.long_int;
    if (minus == -1)
    {
	switch (bvar.BV_type)
	{
	case TYPE_INTEGER:
	    *(sword *)&bvar.BV_data = -1 * (*(sword *)&bvar.BV_data);
	    break;
	case TYPE_LONG:
	    *(sdword *)&bvar.BV_data = -1 * (*(sdword *)&bvar.BV_data);
	    break;
	case TYPE_FLOAT:
	    *(float *)&bvar.BV_data = -1 * (*(float *)&bvar.BV_data);
	    break;
	}
    }

    if (type != bvar.BV_type)
    {
	switch(type)
	{
	case TYPE_INTEGER:
	    if (bvar.BV_type == TYPE_FLOAT) {
		if (*(float *)&bvar.BV_data < -32767.0 ||
		    *(float *)&bvar.BV_data > 32767.0)
		{
		    bvar.BV_type = TYPE_ILLEGAL;
		}
		*(sword *)&bvar.BV_data = *(float *)&bvar.BV_data;
	    } else {
		if (*(sdword *)&bvar.BV_data < -32767 ||
		    *(sdword *)&bvar.BV_data > 32767)
		{
		    bvar.BV_type = TYPE_ILLEGAL;
		}
		*(sword *)&bvar.BV_data = *(sdword *)&bvar.BV_data;
	    }
	    break;
	case TYPE_LONG:
	    if (bvar.BV_type == TYPE_FLOAT) {
		if (*(float *)&bvar.BV_data < -2147483647.0 ||
		    *(float *)&bvar.BV_data > 2147483647.0)
		{
		    bvar.BV_type = TYPE_ILLEGAL;
		}
		*(sdword *)&bvar.BV_data = *(float *)&bvar.BV_data;
	    } else {
		*(sdword *)&bvar.BV_data = *(sword *)&bvar.BV_data;
	    }
	    break;
	case TYPE_FLOAT:
	    if (bvar.BV_type == TYPE_INTEGER) {
		*(float *)&bvar.BV_data = *(sword *)&bvar.BV_data;
	    } else {
		*(float *)&bvar.BV_data = *(sdword *)&bvar.BV_data;
	    }
	    break;
	}
    }
    if (bvar.BV_type != TYPE_ILLEGAL) {
	bvar.BV_type = type;
    }
    restoreDS(oldDS);
    return bvar;
}



