/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		runec.c

AUTHOR:		Jimmy Lefkowitz, Feb 28, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 2/28/95   	Initial version.

DESCRIPTION:
	ec code for runtime module

	$Revision: 1.2 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include "mystdapp.h"
#include "runint.h"

#if ERROR_CHECK

#if 0
/*********************************************************************
 *			GetRunFtabEntry
 *********************************************************************
 * SYNOPSIS:	get the proper RunFTabEntry
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 2/28/95	Initial version			     
 * 
 *********************************************************************/
RunFTabEntry*
GetRunFTabEntry(RunTask *rtask, word seg)
{
    word    count, i, dummy;
    RunFTabEntry	*rfte;

    count = HugeArrayGetCount(rtask->RT_vmFile, rtask->RT_funcArray);
    for (i=0; i < count; i++) 
    {
	HugeArrayLock(rtask->RT_vmFile, rtask->RT_funcArray, i, 
		      (void**)&rfte, &dummy);
	if (seg >= rfte->RFTE_startSeg && 
	    seg < rfte->RFTE_startSeg+rfte->RFTE_numSegs)
	{
	    HugeArrayUnlock(rfte);
	    break;
	}
	HugeArrayUnlock(rfte);
    }
    if (i == count) {
	EC_ERROR(-1);
    }
    return rfte;
}

/*********************************************************************
 *			ValidateStack
 *********************************************************************
 * SYNOPSIS:	validate the stack
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	*sc (stack cursor) moves up the stack, while the various data
 *	structures are verified.  It points at the byte after the
 *	section of stack being examined.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 2/28/95	Initial version			     
 * 
 *********************************************************************/
#pragma argsused

void
ValidateStack(RMLPtr rms)
{
#if 0
    word	off;
    byte	*sc;
    byte	*curVbp;
    word	numLocals;
    Opcode	op;
    RunFTabEntry *rfte;
    word	i, count, dummy;
    ErrorCheckingFlags	ecflags;


    ecflags = SysGetECLevel(&dummy);
    if (! (ecflags & ECF_NORMAL)) {
	return;
    }


    rfte = GetRunFTabEntry(rms->rtask,
			   rms->ptask->PT_context.FC_codeSeg);
    numLocals = rfte->RFTE_numLocals;
    sc = rms->tos + 1;
    curVbp = rms->vbp;

    while (1)
    {
	if (sc < curVbp)	/* Somehow skipped past it */
	{
	    EC_ERROR(RE_FAILED_ASSERTION);
	}
	else if (sc == curVbp)	/* Bottom of frame -- checked all the locals */
	{
	    word	newCodeSeg;

	    if (FRAME_OF(curVbp).FC_vpcUnreloc & VPC_RETURN) {
		if (rfte != NULL) {
		    HugeArrayUnlock(rfte);
		}
		return;
	    }

	    newCodeSeg = FRAME_OF(curVbp).FC_codeSeg;
	    curVbp = rms->stack + FRAME_OF(curVbp).FC_vbpUnreloc;

	    sc -= sizeof(FrameContext);

	    if (rfte != NULL) {
		HugeArrayUnlock(rfte);
	    }

	    rfte = GetRunFTabEntry(rms->rtask, newCodeSeg);
	    numLocals = rfte->RFTE_numLocals;
	}
	else if (sc == curVbp + VAR_SIZE * numLocals)
				/* Just above local vars */
	{
	    while (sc > curVbp) {
		sc -= VAR_SIZE;	/* point at the variable */
		switch(*sc)		/* Type is at bottom */
		{
		case TYPE_VARIANT:	case TYPE_COMPONENT:
		case TYPE_MODULE:	case TYPE_INTEGER:
		case TYPE_LONG:		case TYPE_FLOAT:
		case TYPE_STRING:	case TYPE_ARRAY:
		case TYPE_COMPLEX:
		    break;
		default:
		    EC_ERROR(RE_BAD_LOCAL_VAR_TYPE);
		}
	    }
	    /* Assert: sc == curVbp */
	    /* Could move previous case in here, I guess... */
	}
	else			/* Just a normal rval on the stack */
	{
	    Opcode	op;

	    op = sc[-1];	/* highest byte is type */
	    switch (op)
	    {
	    case OP_SET_MODULE_REF:
		/* This is an interesting case; it's a hint to OP_ASSIGN
		 * that there's a module rval and a string rval following
		 * on the stack, to be interpreted as a module variable.
		 * We'll check all 11 bytes here.
		 */
		sc--;		/* Take into account the extra OP_SET.. byte */
		sc -= RVAL_SIZE;
		EC_ERROR_IF(*sc != TYPE_MODULE,
			    RE_NO_MODULE_AFTER_SET_MODULE_REF);
		ECCheckMemHandle(*(word*)sc);
		sc -= RVAL_SIZE;
		EC_ERROR_IF(*sc != TYPE_STRING,
			    RE_NO_STRING_AFTER_SET_MODULE_REF);
		
		break;
	    case OP_MODULE_ARRAY_REF:
	    case OP_LOCAL_ARRAY_REF:
		/* More-significant-word is a MemHandle */
		sc -= RVAL_SIZE;
		ECCheckMemHandle(*(word *)(sc+2));
		break;

	    case OP_INTEGER_CONST:
	    case OP_LONG_CONST:
	    case OP_FLOAT_CONST:
	    case OP_STRING_CONST:
		sc -= RVAL_SIZE;
		break;
	    case OP_SET_PROPERTY:
	    case OP_LOCAL_VAR:
	    case OP_MODULE_VAR:
		sc -= RVAL_SIZE;
		break;

		/* This should never happen... arrays can be passed by pushing
		 * OP_*_VAR on the stack, but there can't ever be a constant
		 * array just lying on the stack.
		 */
		EC_ERROR(RE_ARRAY_ON_STACK);
		return;

	    default:
		EC_ERROR(RE_BAD_RVAL_TYPE);
		return;
	    }
	}
    }
#endif
}
#endif
#endif
