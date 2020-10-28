/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- breakpoint management
 * FILE:	  break.c
 *
 * AUTHOR:  	  Adam de Boor: Sep 30, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Break_Init	    Initialize this module
 *	Break_Set 	    Set a breakpoint for a patient
 *	Break_Clear	    Clear a set breakpoint
 *	Break_Enable	    Enable a set breakpoint
 *	Break_Disable	    Disable a set breakpoint.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/30/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 * 	Breakpoints are registered for a patient on a handle. When a
 *	breakpoint is taken on the PC, we locate the handle in which
 *	execution is occuring, and from there we can find the breakpoint
 *	and deal with it.
 *
 * 	Modules must always have handles, even if their handle id's are 0.
 *
 *	A breakpoint is set in a handle for a given patient -- where a
 *	patient must be a process. If the handle is shared code and
 *	the breakpoint is hit in a different process, the breakpoint will
 *	not be taken. Note that it is a process, not a thread, that is
 *	the unit of distinction. If the user wishes thread-specific
 *	breakpoints, s/he should test the current thread (available as
 *	a register for expressions and via a tcl command for raw tcl
 *	breakpoints).
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: break.c,v 4.35 97/04/18 14:45:54 dbaumann Exp $";
#endif lint

#include <config.h>
#include <compat/stdlib.h>
#include "swat.h"
#include "break.h"
#include "cmd.h"
#include "event.h"
#include "expr.h"
#include "private.h"
#include "rpc.h"
#include "sym.h"
#include "type.h"
#include "var.h"
#include "gc.h"

#include <ctype.h>

/*
 * Structure used to describe a single breakpoint. Breakpoints for the
 * same address are linked into a chain through their 'next' field.
 *
 * A breakpoint must be set at an offset from a handle. For each offset,
 * a single BreakChainRec is created. All breakpoints at that offset are
 * chained off that single BreakChainRec. If any of the breakpoints in the
 * chain is enabled, the whole breakpoint is enabled (two different orders
 * of "breakpoint" you see).
 */
#define CB_MAX_HANDLES	5   	/* Most handles to keep track of: 1 for bp
				 * itself, 1 for word of memory, and 1 for
				 * each segment register other than CS */
typedef struct {
    Handle  	    	handle;	    	/* Handle to track */
    word	    	*value;	    	/* Place where its segment is stored in
					 * TclBreakRec.criteria */
    char    	    	*fullname;  	/* Full name of symbol involved (label
					 * or module) */
    word    	    	offset;	    	/* Offset from symbol at which address
					 * is located, if not exact */
} CBHandleRec;

typedef struct _CBreak {
    CBreakArgs	    	criteria;   	/* Breakpoint conditions */
    CBHandleRec  	handles[CB_MAX_HANDLES];
} CBreakRec, *CBreakPtr;

typedef struct _Break {
    Handle  	  	handle;	    	/* Handle of block in which it's set */
    Address 	  	offset;    	/* Address for breakpoint. Absolute
					 * address if handle is 0 */
    Patient 	  	patient;    	/* Patient for which it's set */
    BreakHandler 	*func;	    	/* Callback function */
    Opaque	  	data;	    	/* Datum for function */
    char    	    	*fullname;  	/* Full name of symbol relative to
					 * which the breakpoint is set. Used
					 * only when breakpoint has been
					 * saved */
    word    	    	symoff;	    	/* Offset from the symbol, if any */
    byte    	    	enabled:1,  	/* Non-zero if breakpoint enabled */
			inuse:1,    	/* Non-zero if handler being called */
			nukeme:1,   	/* Non-zero if breakpoint should be
					 * nuked when handler finishes */
			isCond:1,   	/* Non-zero if breakpoint is
					 * conditional */
			orphan:1,   	/* Non-zero if breakpoint has been
					 * orphaned by having the patient for
					 * one of its handles destroyed. */
			saved:1;    	/* Non-zero if breakpoint is inactive,
					 * awaiting reloading of the patient
					 * for which it's bound. */
    word    	    	bpNum;	    	/* Breakpoint number returned by the
					 * stub */
#define BP_NOT_INSTALLED 0  	    	    /* Value for bpNum if breakpoint
					     * not yet installed */
    CBreakRec	    	cb; 	    	/* Conditions, if isCond */
    struct _Break	*next;	    	/* Next breakpoint */
} BreakRec, *BreakPtr;

#define BreakIsTcl(bp) ((bp)->func == BreakTclCatch)

static	int    	    	maxBreakPoint=0;/* highest breakpoint number in use */
static Boolean 	  	breakDebug;   	/* TRUE if we're in debugging mode */
static Lst    	  	tclBreaks;	/* List of BreakPtr's set from Tcl */
static BreakPtr	    	allBreaks;  	/* Head of list of all currently-known
					 * breakpoints */
static Lst  	    	tempBreaks; 	/* List of temporary breakpoints to be
					 * nuked when the machine stops next */

static BreakPtr	    	savedBreaks;	/* Breakpoint is awaiting re-activation
					 * of the target patient */

static Type 	    	typeCBreakArgs,
			typeChangeCBreakArgs,
			typeSetBreakArgs;

fstatic EventHandler BreakUninstall;
fstatic EventHandler BreakInstall;
fstatic BreakHandler BreakTclCatch;
fstatic HandleInterestProc CBreakInterest;
fstatic HandleInterestProc BreakInterest;
fstatic int BreakInstallBP(BreakPtr bp);
fstatic int BreakUninstallBP(BreakPtr bp);


/*
 * Private data kept with each tcl-level breakpoint. A TclBreakRec is
 * allocated for each standard tcl breakpoint.
 */
typedef struct {
    int	    	  	id; 	    	/* ID number */
    word 	    	user_enabled:1;	/* TRUE if breakpoint enabled by user */
    char    	    	*delcmd;    	/* Command to execute when the
					 * breakpoint is deleted */
    char		command[LABEL_IN_STRUCT];   	/* Command to execute */
} TclBreakRec, *TclBreakPtr;

static void CBreakFinishCriteriaChange(BreakPtr bp);


/***********************************************************************
 *				BreakDecomposeAddress
 ***********************************************************************
 * SYNOPSIS:	    Break a 32-bit linear address into its segment:offset
 *	    	    components, dealing with the funky addressing of
 *	    	    things above 1Mb
 * CALLED BY:	    INTERNAL
 * RETURN:	    the segment & offset
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/13/91	Initial Revision
 *
 ***********************************************************************/
static void
BreakDecomposeAddress(Address 	addr,
		      word    	*segmentPtr,
		      word    	*offsetPtr)
{
#if GEOS32
	*segmentPtr = ((dword)addr & SEGMENT_MASK) >> SEGMENT_SHIFT;
	*offsetPtr = (dword)addr & OFFSET_MASK;
#else
    if ((addr > (Address)0xfffff) && (addr < (Address)(SEGMENT_MASK + 0xffff)))
    {
	/*
	 * Special case access > 1Mb (for high-loaded DOS and other things)
	 */
	*segmentPtr = 0xffff;
	*offsetPtr = addr - (Address)SEGMENT_MASK;
    } else {
	*segmentPtr = ((dword)addr & SEGMENT_MASK) >> SEGMENT_SHIFT;
	*offsetPtr = (dword)addr & OFFSET_MASK;
    }
#endif
}

/***********************************************************************
 *				BreakSet
 ***********************************************************************
 * SYNOPSIS:	    Set a breakpoint, given a filled-in BreakRec
 * CALLED BY:	    Break_Set, BreakStart
 * RETURN:	    nothing
 * SIDE EFFECTS:    chain may be created, breakpoint installed, etc.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/91	Initial Revision
 *
 ***********************************************************************/
static int
BreakSet(BreakPtr   	bp,
	 Handle	    	handle,
	 Address    	offset)
{
    bp->handle = handle;
    bp->offset = offset;

    if (handle != NullHandle) {
	Handle_Interest(handle, BreakInterest, (Opaque)bp);
    }

    bp->next = allBreaks;
    allBreaks = bp;

    if (breakDebug) {
	Message("Break_Set(%04xh:%04xh, %xh, %xh)\n",
		handle ? Handle_Segment(handle) : 0, offset,
		bp->func, bp->data);
    }

    if (bp->enabled) {
	int status;

	status = BreakInstallBP(bp);
	if (status != RPC_SUCCESS)
	{
	    Break_Clear(bp);
	    return status;
	}
    }
    return RPC_SUCCESS;
}

/***********************************************************************
 *				BreakFindLastTcl
 ***********************************************************************
 * SYNOPSIS:	    Return the last break point's number
 * CALLED BY:
 * RETURN:	    break point id
 * SIDE EFFECTS:
 *
 * STRATEGY:	    walk along the list and return the max id.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	rsf	3/14/91		Initial Revision
 *
 ***********************************************************************/
static int
BreakFindLastTcl(void)
{
    LstNode	ln;
    int	    	lastBreak;
    BreakPtr	bp;
    TclBreakPtr tbPtr;

    lastBreak = 0;

    for (ln = Lst_First(tclBreaks); ln != NILLNODE; ln = Lst_Succ(ln)) {
	bp = (BreakPtr)Lst_Datum(ln);
	tbPtr = (TclBreakPtr)bp->data;
	if (tbPtr->id > lastBreak) {
	    lastBreak = tbPtr->id;
	}
    }

    return lastBreak;
}


/***********************************************************************
 *				BreakReset
 ***********************************************************************
 * SYNOPSIS:	    Handle EVENT_RESET
 * CALLED BY:	    EVENT_RESET
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    The inuse bit for all known breakpoints is set FALSE
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/27/89		Initial Revision
 *
 ***********************************************************************/
static int
BreakReset(Event    	event,	    /* EVENT_RESET (sort of) */
	   Opaque   	callData,   /* Garbage */
	   Opaque	junk)	    /* Garbage */
{
    BreakPtr	    bp;

    for (bp = allBreaks; bp != NULL; bp = bp->next) {
	bp->inuse = FALSE;
    }

    return(EVENT_HANDLED);
}


/*********************************************************************
 *			BreakUpdateMaxBreakPoint
 *********************************************************************
 * SYNOPSIS: 	update maxBreakPoint when a breakpoint is deleted
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	1/14/94		Initial version
 *
 *********************************************************************/
static int
BreakUpdateMaxBreakPoint(BreakPtr bp)
{
    TclBreakPtr	tbPtr = (TclBreakPtr)bp->data;

    if (tbPtr->id > maxBreakPoint)
    {
	maxBreakPoint = tbPtr->id;
    }
    return 0;
}

/***********************************************************************
 *				BreakFree
 ***********************************************************************
 * SYNOPSIS:	    Free a breakpoint and its associated data. The
 *	    	    breakpoint must have already been removed from
 *		    the allBreaks list, but need not be gone from the
 *		    tclBreaks list.
 * CALLED BY:	    Break_Clear, BreakStopped
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Stuff be freed. If breakpoint was set from TCL, the
 *	    	    associated entry in the database is nuked.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/90	Initial Revision
 *
 ***********************************************************************/
static void
BreakFree(BreakPtr  bp)
{
    int	id = 0;			/* ID # of breakpoint being nuked. Initialized
				 * to zero to avoid unnecessary recalcs of
				 * maxBreakPoint when deleting breakpoints
				 * not set by Tcl (do we have those anymore?) */
    /*
     * If breakpoint is special, remove it from the tclBreaks list.
     * Note we can be called if there's an error initializing the tcl
     * breakpoint. In this case, bp->data will be NullOpaque...
     */
    if (BreakIsTcl(bp) && (bp->data != NullOpaque)) {
	TclBreakPtr tbPtr = (TclBreakPtr)bp->data;
	LstNode	    ln;

	id = tbPtr->id;
	if (tbPtr->delcmd != NULL) {
	    /*
	     * Need to execute some command before deleting the breakpoint.
	     */
	    char    	  	name[20];

	    sprintf(name, "brk%d", tbPtr->id);
	    Tcl_SetVar(interp, "breakpoint", name, TRUE);

	    (void)Tcl_Eval(interp, tbPtr->delcmd, 0, NULL);
	    /*
	     * Clear out/ignore the return value.
	     */
	    Tcl_Return(interp, NULL, TCL_STATIC);
	    free(tbPtr->delcmd);
	}

	/*
	 * Remove the breakpoint from the list of tclBreaks and call
	 * Break_Clear to remove the actual breakpoint.
	 */
	ln = Lst_Member(tclBreaks, (LstClientData)bp);

	assert(ln != NILLNODE);

	Lst_Remove(tclBreaks, ln);
	free((char *)tbPtr);

    }
    if (bp->isCond) {
	int 	i;

	/*
	 * Unregister interest in all handles...
	 */
	for (i = 0; i < CB_MAX_HANDLES; i++) {
	    if (bp->cb.handles[i].handle != NullHandle) {
		if (!bp->orphan) {
		    Handle_NoInterest(bp->cb.handles[i].handle, CBreakInterest,
				      (Opaque)bp);
		}
		if (bp->saved) {
		    free((malloc_t)bp->cb.handles[i].fullname);
		}
	    }
	}
    }

    if (bp->saved) {
	/*
	 * Clean up remaining stuff from saving breakpoint.
	 */
	free((malloc_t)bp->fullname);

	if (bp->patient) {
	    free((malloc_t)bp->patient);
	}
    }

    if (bp->handle && !bp->orphan) {
	Handle_NoInterest(bp->handle, BreakInterest, (Opaque)bp);
    }

    /*
     * Make sure the stub knows it's gone.
     */
    BreakUninstallBP(bp);

    /*
     * Done with this thing -- nuke it now
     */
    free((char *)bp);

    /* if this was the highest number break point find the next highest */
    if (id == maxBreakPoint)
    {
	maxBreakPoint = 0;
	Lst_ForEach(tclBreaks, BreakUpdateMaxBreakPoint, (LstClientData)NULL);
    }
}


/***********************************************************************
 *				BreakSave
 ***********************************************************************
 * SYNOPSIS:	    Save a breakpoint for later re-installation
 * CALLED BY:	    BreakInterest, BreakDestroyed
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The BreakRec is added to the front of the savedBreaks
 *	    	    	list, if it could be saved.
 *	    	    In any case, the breakpoint is cleared.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/14/89		Initial Revision
 *
 ***********************************************************************/
static void
BreakSave(BreakPtr  	bp) 	    /* Breakpoint to save, if possible */
{
    Sym	    	    sym;    	/* Symbol we found for an address */
    int	    	    i;
    Address 	    symAddr;

    /*
     * Make sure the breakpoint is still on the active list. We maintain
     * interest in the affected handles so we know when the breakpoint
     * has been orphaned, allowing us to bitch, with justification, on re-load
     * if the breakpoint wasn't set at a label. The important point here is
     * that we could easily have already saved this breakpoint, and doing
     * it twice will lead to our destruction.
     */
    if (bp->saved) {
	return;
    }

    /*
     * Mark the breakpoint as in-use, so when we call Break_Clear, it doesn't
     * actually delete the thing. If we decide we can't actually save the bp,
     * we'll set the flag FALSE again so the beast can be nuked.
     */
    bp->inuse = TRUE;

    /*
     * Look up the address of the breakpoint itself to get the name of
     * the closest code-related symbol.
     */
    sym = Sym_LookupAddr(bp->handle, bp->offset,
			 SYM_LABEL|SYM_FUNCTION|SYM_NAMELESS);

    if (breakDebug && BreakIsTcl(bp)) {
	MessageFlush("Saving breakpoint %d...", ((TclBreakPtr)bp->data)->id);
    }

    if (Sym_IsNull(sym)) {
	bp->inuse = FALSE;
    } else {
	/*
	 * Fetch the fullname of the symbol, always including the patient
	 * name, since we'll need to know when the patient comes back in.
	 */
	bp->fullname = Sym_FullNameWithPatient(sym);

	/*
	 * Set bp->symoff to the breakpoint's offset from the symbol we found,
	 * if any. We know then to disable the bp when the patient is
	 * reloaded, to allow the user to make sure it's still in the
	 * correct position.
	 */
	Sym_GetFuncData(sym, (Boolean *)NULL, &symAddr, (Type *)NULL);
	bp->symoff = bp->offset - symAddr;
	if (breakDebug && BreakIsTcl(bp)) {
	    MessageFlush("%s+%d...", bp->fullname, bp->symoff);
	}
    }


    /*
     * If breakpoint patient-specific, we have to convert the
     * patient handle into a patient name so when things are
     * restarted, if the patient is reloaded and a new patient
     * handle allocated, we can store the proper handle in
     * the breakpoint.
     */
    if (bp->patient) {
	char	*name = malloc(strlen(bp->patient->name) + 1);
	strcpy(name, bp->patient->name);
	bp->patient = (Patient)name;
    }

    if (bp->isCond) {
	/*
	 * Deal with the various handles tracked for the condition.
	 */
	for (i = 0; i < CB_MAX_HANDLES; i++) {
	    if (bp->cb.handles[i].handle != NullHandle) {
		Address	offset;

		if (bp->cb.handles[i].value == &bp->cb.criteria.cb_seg) {
		    /*
		     * If handle is for the word of memory being watched, we
		     * need to use the offset as well and look for a label or
		     * whatnot, rather than a module.
		     */
		    offset = (Address)bp->cb.criteria.cb_off;

		    sym = Sym_LookupAddr(bp->cb.handles[i].handle,
					 offset,
					 SYM_ANY&~SYM_ONSTACK);
		    /*
		     * If no symbol nearby, or the closest symbol isn't a
		     * variable, assume the user is looking for memory-trashing
		     * bug and store only the module, keeping the offset
		     * constant across detach/attach.
		     */
		    if (Sym_IsNull(sym) ||
			!(Sym_Class(sym) & (SYM_VAR|SYM_LOCALVAR)))
		    {
			sym = Sym_LookupAddr(bp->cb.handles[i].handle,
					     0,
					     SYM_MODULE);
			offset = 0;
		    }
		} else {
		    /*
		     * Just the segment involved, so we can look only for
		     * a module symbol.
		     */
		    offset = 0;
		    sym = Sym_LookupAddr(bp->cb.handles[i].handle,
					 0,
					 SYM_MODULE);
		}
		if (Sym_IsNull(sym)) {
		    /*
		     * No symbol appropriate to the address, so we can't
		     * save the breakpoint away.
		     */
		    bp->inuse = FALSE;
		} else {
		    /*
		     * Figure the offset of the symbol, so we can set the
		     * handles[i].offset value appropriately.
		     */
		    int class = Sym_Class(sym);

		    if (class & (SYM_VAR|SYM_LOCALVAR)) {
			Sym_GetVarData(sym, (Type *)NULL,
				       (StorageClass *)NULL,
				       &symAddr);
		    } else if (class & SYM_LABEL) {
			Sym_GetFuncData(sym,
					(Boolean *)NULL,
					&symAddr,
					(Type *)NULL);
		    } else {
			assert(class & SYM_MODULE);
			symAddr = 0;
		    }
		    /*
		     * Save away the fullname of the associated symbol, and
		     * calculate the difference of the offset involved from
		     * the symbol we found.
		     */
		    bp->cb.handles[i].fullname =
			Sym_FullNameWithPatient(sym);
		    bp->cb.handles[i].offset = symAddr - offset;
		    if (breakDebug && BreakIsTcl(bp)) {
			MessageFlush("#%d=%s+%d...", i,
				     bp->cb.handles[i].fullname,
				     bp->cb.handles[i].offset);
		    }
		}

		/*
		 * Express our disinterest in the handle, in case this isn't
		 * the one whose free-ing is causing us to save the bp away.
		 */
		Handle_NoInterest(bp->cb.handles[i].handle,
				  CBreakInterest,
				  (Opaque)bp);
	    }
	}
    }

    if (bp->inuse) {
	/*
	 * Breakpoint can actually be saved, so call Break_Clear to unhook the
	 * beast from everything, but it won't actually delete the thing as
	 * we've marked it in-use.
	 */

	Break_Clear(bp);
	BreakUninstallBP(bp);	/* Break_Clear no longer does this when
				 * bp->inuse is set... */
	/*
	 * Flag breakpoint as saved, so Tcl code can print the thing
	 * correctly.
	 */
	bp->saved = TRUE;

	/*
	 * Clear the inuse flag so the user can nuke the breakpoint if desired.
	 */
	bp->inuse = FALSE;

	/*
	 * Hook the saved breakpoint into the chain of saved breakpoints.
	 */
	bp->next = savedBreaks;
	savedBreaks = bp;
	if (breakDebug && BreakIsTcl(bp)) {
	    Message("done\n");
	}
    } else {
	/*
	 * Warn the user that the breakpoint is being deleted.
	 */
	if (bp->handle != NullHandle) {
	    Warning("Condition or address not symbol/resource-relative, "
		    "so breakpoint at ^h%04xh:%04xh deleted\n",
		    Handle_ID(bp->handle),
		    bp->offset);
	} else {
	    Warning("Condition not symbol/resource-relative, so breakpoint "
		    "at %05xh deleted\n",
		    bp->offset);
	}

	/*
	 * Then do it. Since bp->inuse is clear, the breakpoint will actually
	 * be nuked.
	 */
	Break_Clear(bp);
    }
}


/***********************************************************************
 *				BreakEvalOrNuke
 ***********************************************************************
 * SYNOPSIS:	    Evaluate an expression for a saved breakpoint. If
 *		    the evaluation fails and the expression is in the
 *		    passed patient, it means the breakpoint needs to
 *		    be nuked, as the affected symbol exists no longer.
 * CALLED BY:	    BreakStart
 * RETURN:	    TRUE if parsing successful. FALSE if not.
 * SIDE EFFECTS:    breakpoint will be biffed if the expression
 *		    is in the passed patient.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 4/92	Initial Revision
 *
 ***********************************************************************/
static Boolean
BreakEvalOrNuke(BreakPtr    *prevBPP,
		BreakPtr    bp,
		const char  *expr,
		Patient	    patient,
		GeosAddr    *addrPtr,
		Type	    *typePtr,
		Boolean	    wantAddr)
{
    if (Expr_Eval(expr, NullFrame, addrPtr, typePtr, wantAddr)) {
	return(TRUE);
    } else {
	int len = strlen(patient->name);

	if ((strncmp(expr, patient->name, len) == 0) && (expr[len] == ':')) {
	    /*
	     * Tell the user we're nuking this thing.
	     */
	    if (BreakIsTcl(bp)) {
		Warning("%s no longer valid, so breakpoint %d deleted",
			expr, ((TclBreakPtr)bp->data)->id);
	    } else if (bp->symoff) {
		Warning("%s no longer valid, so breakpoint at %s+%d deleted",
			expr, bp->fullname, bp->symoff);
	    } else {
		Warning("%s no longer valid, so breakpoint at %s deleted",
			expr, bp->fullname);
	    }
	    /*
	     * Unlink the beast.
	     */
	    *prevBPP = bp->next;

	    /*
	     * Make sure BreakFree knows it's fair game.
	     */
	    bp->inuse = FALSE;
	    /*
	     * Clean up after the thing.
	     */
	    BreakFree(bp);
	}
    }
    /*
     * Tell caller evaluation failed miserably.
     */
    return(FALSE);
}

/***********************************************************************
 *				BreakStart
 ***********************************************************************
 * SYNOPSIS:	    Handle the start of a new patient
 * CALLED BY:	    EVENT_START
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    Any saved breakpoints for this patient are
 *	    	    re-installed. If any were set at an offset from a
 *	    	    symbol, as opposed to a symbol itself, the
 *	    	    PATIENT_STOP flag is set in sysFlags and a warning
 *	    	    is issued. The breakpoint in question is disabled.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/10/89		Initial Revision
 *
 ***********************************************************************/
static int
BreakStart(Event    	event,	    /* EVENT_START */
	   Opaque   	callData,   /* Patient starting */
	   Opaque	junk)	    /* Garbage */
{
    BreakPtr	    	bp; 	    /* Saved breakpoint being examined */
    BreakPtr	    	*prevBPP;   /* Pointer for link to current bp */
    int	    	    	len;	    /* Length of patient's name */
    Patient 	    	patient;

    patient = (Patient)callData;
    len = strlen(patient->name);

    if (breakDebug) {
	MessageFlush("%s starting...", patient->name);
    }

    for (bp = savedBreaks, prevBPP = &savedBreaks; bp != NULL; bp = *prevBPP) {
	Boolean	    restore = FALSE;
	GeosAddr    addr;
	Boolean	    disable;

	if (breakDebug && BreakIsTcl(bp)) {
	    MessageFlush("#%d: %s...", ((TclBreakPtr)bp->data)->id,
			 bp->fullname);
	}

	/*
	 * If breakpoint set in a resource owned by this patient, try and
	 * restore it.
	 */
	if ((strncmp(bp->fullname, patient->name, len) == 0) &&
	    (bp->fullname[len] == ':'))
	{
	    restore = TRUE;
	}

	/*
	 * If breakpoint is specific to this patient, try and restore it.
	 */
	if ((bp->patient != NullPatient) &&
	    (strcmp((char *)bp->patient, patient->name) == 0))
	{
	    restore = TRUE;
	}

	/*
	 * If any of the watched handles belong to this patient, try and
	 * restore the breakpoint.
	 */
	if (bp->isCond) {
	    int	    	i;

	    for (i = 0; i < CB_MAX_HANDLES; i++) {
		if (bp->cb.handles[i].handle != NullHandle) {
		    if ((strncmp(bp->cb.handles[i].fullname,
				 patient->name,
				 len) == 0) &&
			(bp->cb.handles[i].fullname[len] == ':'))
		    {
			restore = TRUE;
			break;
		    }
		}
	    }
	}

	/*
	 * If nothing in the saved breakpoint pertains to the patient just
	 * started, then nothing has changed for it, so there's no point
	 * in trying to restore the beast.
	 */
	if (!restore) {
	    if (breakDebug) {
		MessageFlush("ignore that.\n");
	    }
	    prevBPP = &bp->next;
	    continue;
	}

	/*
	 * Assume restored breakpoint should be enabled.
	 */
	disable = FALSE;

	/*
	 * Deal with conditional things first, as they're easiest.
	 */
	if (bp->isCond) {
	    int	    	i;
	    Sym	    	sym;

	    for (i = 0; i < CB_MAX_HANDLES; i++) {
		if (bp->cb.handles[i].handle != NullHandle) {
		    /*
		     * Try and parse the address now, so we get the actual
		     * handle...and offset if the fullname is a label or the
		     * like.
		     */
		    if (!BreakEvalOrNuke(prevBPP, bp,
					 bp->cb.handles[i].fullname,
					 patient,
					 &addr,
					 (Type *)NULL,
					 TRUE) ||
			(addr.handle == NullHandle) ||
			(addr.handle == ValueHandle))
		    {
			break;
		    }
		    /*
		     * Store away the handle and segment.
		     */
		    bp->cb.handles[i].handle = addr.handle;
		    *bp->cb.handles[i].value = Handle_Segment(addr.handle);

		    /*
		     * See if the thing is a variable or label so we can
		     * decide whether it's the memory-word or the cs:ip for
		     * the breakpoint, whose offsets we need to adjust.
		     */
		    sym = Sym_Lookup(bp->cb.handles[i].fullname,
				     SYM_VAR|SYM_LABEL|SYM_LOCALVAR,
				     curPatient->global);
		    if (!Sym_IsNull(sym)) {
			/*
			 * One of the two. If not set at a variable or a label,
			 * the disable the breakpoint if we set it.
			 */
			if (bp->cb.handles[i].offset) {
			    disable = TRUE;
			}
			/*
			 * Figure which one it is by seeing where the value
			 * pointer points and adjust the corresponding offset
			 * accordingly.
			 */
			if (bp->cb.handles[i].value == &bp->cb.criteria.cb_cs){
			    bp->cb.criteria.cb_ip =
				(word)(addr.offset + bp->cb.handles[i].offset);
			} else {
			    bp->cb.criteria.cb_off =
				(word)(addr.offset + bp->cb.handles[i].offset);
			}
		    }
		}
	    }
	    if (i != CB_MAX_HANDLES) {
		/*
		 * Breakpoint might have been nuked, so only set prevBPP to
		 * its next field if *prevBPP still points to the breakpoint
		 * we just decided not to restore.
		 */
		if (*prevBPP == bp) {
		    prevBPP = &bp->next;
		}
		continue;
	    }
	}

	/*
	 * See if the address for the breakpoint is defined yet.
	 */
	if (!BreakEvalOrNuke(prevBPP, bp, bp->fullname, patient,
			     &addr, (Type *)NULL, TRUE) ||
	    (addr.handle == ValueHandle))
	{
	    /*
	     * Breakpoint might have been nuked, so only set prevBPP to
	     * its next field if *prevBPP still points to the breakpoint
	     * we just decided not to restore.
	     */
	    if (*prevBPP == bp) {
		prevBPP = &bp->next;
	    }
	    continue;
	}

	/*
	 * If the breakpoint is patient-specific, look for the patient handle.
	 */
	if (bp->patient != NullPatient) {
	    Patient p = Patient_ByName((char *)bp->patient);
	    if (p == NullPatient) {
		prevBPP = &bp->next;
		continue;
	    }

	    free((char *)bp->patient);
	    bp->patient = p;
	}

	/*
	 * If the breakpoint itself is offset from a label, disable it once
	 * it's been set again.
	 */
	if (bp->symoff != 0) {
	    disable = TRUE;
	}

	/*
	 * Now have everything we need to restore the breakpoint.
	 */
	if (disable && bp->enabled && bp->orphan) {
	    if (bp->symoff) {
		if (BreakIsTcl(bp)) {
		    Warning("Breakpoint %d at %s+%d disabled",
			    ((TclBreakPtr)bp->data)->id,
			    bp->fullname, bp->symoff);
		} else {
		    Warning("Breakpoint at %s+%d disabled",
			    bp->fullname, bp->symoff);
		}
	    } else {
		if (BreakIsTcl(bp)) {
		    Warning("Breakpoint %d at %s disabled",
			    ((TclBreakPtr)bp->data)->id,
			    bp->fullname);
		} else {
		    Warning("Breakpoint at %s disabled", bp->fullname);
		}
	    }
	    sysFlags |= PATIENT_STOP;
	    bp->enabled = FALSE;
	    if (BreakIsTcl(bp)) {
		((TclBreakPtr)bp->data)->user_enabled = FALSE;
	    }
	}
	/*
	 * Unlink from chain of saved breakpoints.
	 */
	*prevBPP = bp->next;

	/*
	 * Get rid of interest procedure for the breakpoint address now, so
	 * long as the handle's still valid (the breakpoint hasn't been
	 * orphaned). We have to wait until now to do it, rather than doing it
	 * when we save the breakpoint, so we know when the resource handle
	 * gets freed and the breakpoint gets orphaned.
	 */
	if (!bp->orphan && bp->handle) {
	    Handle_NoInterest(bp->handle, BreakInterest, (Opaque)bp);
	}

	/*
	 * Hook the thing into any existing chain, or create a new one, etc.
	 * etc. etc.
	 */
	bp->saved = bp->orphan = bp->inuse = bp->nukeme = FALSE;
	BreakSet(bp, addr.handle, addr.offset + bp->symoff);

	/*
	 * Don't need all the strings any more, so free them.
	 */
	free(bp->fullname);
	bp->fullname = NULL;

	if (bp->isCond) {
	    int	    	i;

	    for (i = 0; i < CB_MAX_HANDLES; i++) {
		if (bp->cb.handles[i].handle != NullHandle) {
		    free(bp->cb.handles[i].fullname);
		    bp->cb.handles[i].fullname = NULL;
		}
	    }

	    /*
	     * If conditional, register interest for CBreakInterest
	     * as well...
	     */
	    if (bp->isCond) {
		CBreakFinishCriteriaChange(bp);
	    }
	}
    }

    return(EVENT_HANDLED);
}


/***********************************************************************
 *				BreakDestroyed
 ***********************************************************************
 * SYNOPSIS:	    Deal with any patient-specific breakpoints for a
 *	    	    patient being destroyed.
 * CALLED BY:	    EVENT_DESTROY
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    Any breakpoints specific to the patient are saved
 *	    	    and cleared.
 *
 * STRATEGY:
 *	Go through all known breakpoints calling BreakSave for and
 *	deleting any breakpoint that is specific to the patient being
 *	blown away.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/14/89		Initial Revision
 *
 ***********************************************************************/
static int
BreakDestroyed(Event	event,	    /* Event that called us */
	       Opaque	callData,   /* Patient being destroyed */
	       Opaque	junk)	    /* Our (non-)data */
{
    BreakPtr	    bp, nextBP;
    Patient 	    patient = (Patient)callData;

    for (bp = allBreaks; bp != NULL; bp = nextBP) {
	/*
	 * In case breakpoint is saved and deleted...
	 */
	nextBP = bp->next;

	if (bp->patient == patient) {
	    bp->orphan = TRUE;
	    BreakSave(bp);
	}
    }

    return(EVENT_HANDLED);
}

/***********************************************************************
 *				BreakReload
 ***********************************************************************
 * SYNOPSIS:	    Deal with the system being reloaded.
 * CALLED BY:	    EVENT_RELOAD
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    Breakpoints are installed.
 *
 * STRATEGY:
 *	We have a problem in that any breakpoints placed in the resident
 *	portion of the kernel remain there, while anything that was in
 *	the transient portion is gone. We don't want to double-install
 *	any breakpoints, however, so we just uninstall and re-install
 *	everything -- it doesn't matter if we overwrite trashed data...
 *
 *	XXX: We will, for hardware-assist support, need to know when
 *	the kernel goes away so we can shut off any hardware breakpoints...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 3/89	Initial Revision
 *
 ***********************************************************************/
static int
BreakReload(Event	event,	    /* Event that called us */
	    Opaque	callData,   /* Patient being destroyed */
	    Opaque	junk)	    /* Our (non-)data */
{
    BreakUninstall(NullEvent, NullOpaque, NullOpaque);
    BreakInstall(event, CONTINUE_FULL, NullOpaque);

    return(EVENT_HANDLED);
}

/*-
 *-----------------------------------------------------------------------
 * BreakStopped --
 *	Handler for EVENT_STOP and EVENT_STEP. Calls all callback functions
 *	for the breakpoints at the given address and if any of them returns
 *	TRUE, says the patient should stop.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The callback functions in the breakpoint chain are called.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static int
BreakStopped(Event  event,	/* EVENT_STOP or EVENT_STEP */
	     Opaque callData,   /* Pointer to Boolean where we should say
				 * whether the patient should remain stopped */
	     Opaque junk)
{
    register BreakPtr	bp; 	    /* The current breakpoint */
    BreakPtr		nextBP;	    /* Next breakpoint */
    register Boolean	stop;       /* TRUE if should keep patient stopped */
    Handle  	    	handle;	    /* Handle in which it stopped */
    Address 	    	pc; 	    /* PC at which it stopped (full 32-bit
				     * address) */
    Frame   	    	*frame;	    /* Current frame */
    Boolean 	    	*stayStopped;/* Cast version of callData */
    Boolean 	    	seenOne;

    frame = curPatient->frame;
    stayStopped = (Boolean *)callData;

    /*
     * Figure out where we stopped. We need to get the PC since the IP is
     * relative to CS, which may not point the same place as the handle.
     * Since all breakpoints here are stored handle-relative, we need the
     * offset from the handle, not CS. Note that we use the frame handle
     * if it's known, otherwise we try and find one ourselves (when will
     * this ever work?).
     */
    Ibm_ReadRegister(REG_MACHINE, REG_PC, (regval *)&pc);
    handle = frame->handle ? frame->handle : Handle_Find(pc);

    if (handle != NullHandle) {
	Address diff = (Address)(pc - Handle_Address(handle));

	if (diff >= (Address)65536) {
	    /*
	     * When setting a breakpoint in an enormous segment (read: DOS),
	     * the expression parser will sometimes give us back an absolute
	     * address so as not to lose information. We need to use the
	     * actual PC and a null handle instead of doing the search handle-
	     * relative...
	     */
	    handle = NullHandle;
	} else {
	    pc = diff;
	}
    }


    stop = FALSE;		/* Initialize stop flag */
    seenOne = FALSE;

    if (breakDebug) {
	Message("BREAK(%xh [%08xh]) ", pc, handle);
    }

    /*
     * Step down the list of breakpoints. Note that we fetch the
     * nextBP before calling the handler so we can continue down the
     * list unperturbed even if the handler removes the current
     * breakpoint and the "next" field is overwritten.
     */
    for (bp = allBreaks; bp != (BreakPtr)NULL; bp = nextBP) {
	nextBP = bp->next;
	if ((bp->handle == handle) && (bp->offset == pc)) {
	    seenOne = TRUE;
	    if (!bp->enabled) {
		if (breakDebug) {
		    Message("disabled ");
		}
	    } else if (!bp->inuse &&
		       ((bp->patient == NullPatient) ||
			(bp->patient == curPatient)))
	    {
		if (breakDebug) {
		    Message("call %x ", bp->func);
		}
		bp->inuse = TRUE;
		stop = ((* bp->func) ((Break)bp, bp->data) || stop);
		bp->inuse = FALSE;
		if (bp->nukeme) {
		    BreakFree(bp);
		}
	    }
	}
    }

    /*
     * If any breakpoint returned TRUE, keep the patient stopped,
     * generating a FULLSTOP event. Else continue the patient.
     * Note that if we generate a FULLSTOP event, we don't let the STEP
     * or STOP event propagate. This is to prevent a trace function from
     * continuing the machine...
     */
    if (!seenOne) {
	if (breakDebug) {
	    Message("not ours\n");
	}
	return(EVENT_NOT_HANDLED);
    } else if (stop) {
	if (breakDebug) {
	    Message("taken\n");
	}
	sysFlags |= PATIENT_BREAKPOINT;
	*stayStopped = TRUE;
	return(EVENT_STOP_HANDLING);
    } else {
	/*
	 * Well, we handled it, but there may be someone else who wants
	 * to stop the patient, so don't tell Event_Dispatch to stop.
	 */
	if (breakDebug) {
	    Message("not taken\n");
	}
	return(EVENT_HANDLED);
    }
}


/***********************************************************************
 *				BreakInstallBP
 ***********************************************************************
 * SYNOPSIS:	  Install a single breakpoint into the PC
 * CALLED BY:	  BreakInstall via Lst_ForEach
 * RETURN:	  === 0
 * SIDE EFFECTS:  The 'data' field of the chain is changed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/30/88		Initial Revision
 *
 ***********************************************************************/
static int
BreakInstallBP(BreakPtr 	bp)
{
    Rpc_Stat	status = RPC_SUCCESS;

    if (bp->enabled && bp->bpNum == BP_NOT_INSTALLED &&
	(!bp->handle || (Handle_XipPage(bp->handle) != HANDLE_NOT_XIP) ||
	 ((Handle_State(bp->handle) & HANDLE_IN) &&
	  ((word)bp->offset < Handle_Size(bp->handle)))))
    {

	if (bp->isCond) {
	    CBreakArgs	cba;	    /* Sacrificial lamb (byte-swapping...) */

	    cba	= bp->cb.criteria;

	    /* if the thing is an XIP handle we need to pass the handle
	     * not the segment
	     */
	    cba.cb_xipPage = Handle_XipPage(bp->handle);
	    if (cba.cb_xipPage != HANDLE_NOT_XIP) {
		cba.cb_cs = Handle_ID(bp->handle);
	    }
	    status = Rpc_Call(RPC_CBREAK,
			      sizeof(cba), typeCBreakArgs, (Opaque)&cba,
			      sizeof(word), type_Word, (Opaque)&bp->bpNum);
	} else {
	    SetBreakArgs sba;

	    if (bp->handle) {

		sba.sba_ip = (word)bp->offset;

		/* if the thing is an XIP resource, it might not be banked
		 * in, so to help things out, we pass in the handle instead
		 * so that when it gets banked in, the bpt module will be
		 * able to properly install it
		 */
		sba.sba_xip = Handle_XipPage(bp->handle);
		if (sba.sba_xip == HANDLE_NOT_XIP) {
		    sba.sba_cs = Handle_Segment(bp->handle);
		} else {
		    sba.sba_cs = Handle_ID(bp->handle);
	    	}
	    } else {
		sba.sba_xip = HANDLE_NOT_XIP;
		BreakDecomposeAddress(bp->offset, &sba.sba_cs, &sba.sba_ip);
	    }

	    status = Rpc_Call(RPC_SETBREAK,
			      sizeof(sba), typeSetBreakArgs, (Opaque)&sba,
			      sizeof(word), type_Word, (Opaque)&bp->bpNum);
	}

	if (status != RPC_SUCCESS) {
	    Warning("Unable to install breakpoint: %s",
		    Rpc_ErrorMessage(status));
	    bp->bpNum = BP_NOT_INSTALLED;
	}
    }
    return(status);
}

/*-
 *-----------------------------------------------------------------------
 * BreakInstall --
 *	Install all the breakpoints for the given patient. Handler
 *	for EVENT_CONTINUE. If the patient is going to single step
 *	(how is CONTINUE_STEP), then remove all the breakpoints, since we
 *	don't need them. If the patient is going from a full stop to
 *	a free run, make sure we skip over any breakpoint we're on.
 *
 * Results:
 *	=== EVENT_HANDLED
 *
 * Side Effects:
 *	Breakpoints are installed in the patient.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static int
BreakInstall(Event  event,	    /* Event that called us */
	     Opaque how,	    /* What sort of continue... */
	     Opaque junk)
{
    Address 	  	    	pc;

    /*
     * If going from full-stop to free-run, see if there's a breakpoint at
     * the place we're going to continue. If so, remove it, but we
     * don't want to lose control of the process, so set the
     * PATIENT_SKIPBPT flag in sysFlags to invoke the SKIPBPT call.
     */
    if (how == CONTINUE_FULL) {
	Handle	  handle;
	BreakPtr    bp;

	Ibm_ReadRegister(REG_MACHINE, REG_PC, (regval *)&pc);
	handle = Handle_Find(pc);

	if (handle != NullHandle) {
	    Address  	offset;

	    /*
	     * Figure the offset from the handle (again we don't use
	     * IP since CS may not be pointing at the handle (e.g. in DOS))
	     */
	    offset = (Address)(pc - Handle_Address(handle));

	    /*
	     * q.v. BreakStopped, above, for why this is done.
	     */
	    if (offset < (Address)65536) {
		pc = offset;
	    } else {
	    	handle = NullHandle;
	    }
	}

	for (bp = allBreaks; bp != NULL; bp = bp->next) {
	    if (bp->handle == handle && bp->offset == pc && bp->enabled) {
		if (breakDebug) {
		    Message("\tstepping over bpt at %04xh:%04xh\n",
			    handle ? Handle_Segment(handle) : 0, pc);
		}
		sysFlags |= PATIENT_SKIPBPT;
		skipBP = bp->bpNum;
		break;
	    }
	}
    }

    return(EVENT_HANDLED);
}


/***********************************************************************
 *				BreakUninstallBP
 ***********************************************************************
 * SYNOPSIS:	  Uninstall an individual breakpoint
 * CALLED BY:	  BreakUninstall via Lst_ForEach
 * RETURN:	  === 0
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/30/88		Initial Revision
 *
 ***********************************************************************/
static int
BreakUninstallBP(BreakPtr 	bp)	/* Breakpoint to remove */
{
    /*
     * XXX: We cheat here and just use RPC_CLEARBREAK rather than
     * differentiating between conditional and unconditional, as we know the
     * same sort of code gets executed by the stub.
     */
    if (bp->bpNum != BP_NOT_INSTALLED) {
	if (breakDebug) {
	    Message("Removed %04xh:%04xh, bpNum = %xh\n",
		    bp->handle ? Handle_Segment(bp->handle) : 0,
		    bp->offset, bp->bpNum);
	}
	(void)Rpc_Call(RPC_CLEARBREAK,
		       sizeof(word), type_Word, (Opaque)&bp->bpNum,
		       0, type_Void, NullOpaque);
	bp->bpNum = BP_NOT_INSTALLED;
    }

    return(0);
}

/*-
 *-----------------------------------------------------------------------
 * BreakUninstall --
 *	Remove all breakpoints from the given patient. Callback function
 *	for EVENT_FULLSTOP and EVENT_EXIT handling.
 *
 * Results:
 *	=== EVENT_HANDLED
 *
 * Side Effects:
 *	BreakUninstallBP is called for all known breakpoints.
 *
 *-----------------------------------------------------------------------
 */
static int
BreakUninstall(Event	event,
	       Opaque	callData,
	       Opaque	clientData)
{
    int			eventNum;
    BreakPtr	    	bp;

    eventNum = ((event != NullEvent) ? Event_Number(event) : EVENT_FULLSTOP);


    switch (eventNum) {
	case EVENT_DETACH:
	    /*
	     * We're detaching -- remove all active breakpoints
	     */
	    for (bp = allBreaks; bp != NULL; bp = bp->next) {
		BreakUninstallBP(bp);
	    }
	    /*FALLTHRU*/
	case EVENT_FULLSTOP:
	    /*
	     * Nuke all the temporary breakpoints.
	     */
	    if (!Lst_IsEmpty(tempBreaks)) {
		/*
		 * Copy it so Break_Clear doesn't remove the thing from
		 * under Lst_Destroy.
		 */
		Lst tb = tempBreaks;

		tempBreaks = Lst_Init(FALSE);
		Lst_Destroy(tb, Break_Clear);
	    }
	    break;
	default:
	{
	    /*
	     * A patient (callData) has exited. We need to mark its
	     * breakpoints as inactive and save them away while its symbol
	     * file is still open.
	     */
	    Patient	patient = (Patient)callData;
	    BreakPtr	next;

	    for (bp = allBreaks; bp != NULL; bp = next) {
		/*
		 * If the breakpoint is specific to the exiting patient,
		 * save it away.
		 */
		Boolean	save = (bp->patient == patient);

		next = bp->next;

		if (bp->isCond) {
		    /*
		     * Check the owner of all the handles associated with the
		     * breakpoint. If the exiting patient owns any of them,
		     * save the whole breakpoint away.
		     */
		    int	    i;

		    for (i = 0; i < CB_MAX_HANDLES; i++) {
			if ((bp->cb.handles[i].handle != NullHandle) &&
			    (Handle_Patient(bp->cb.handles[i].handle) ==
			     patient))
			{
			    save = TRUE;
			    break;
			}
		    }
		} else if (bp->handle != NullHandle) {
		    /*
		     * If the exiting patient owns the handle in which the
		     * breakpoint is set, save the breakpoint away.
		     */
		    save = save || (Handle_Patient(bp->handle) == patient);
		}

		if (save) {
		    BreakUninstallBP(bp);
		    BreakSave(bp);
		}
	    }
	    break;
	}
    }

    return(EVENT_HANDLED);
}


/***********************************************************************
 *				BreakInterest
 ***********************************************************************
 * SYNOPSIS:	  Interest function for handle changes.
 * CALLED BY:	  Handle module
 * RETURN:	  Nothing
 * SIDE EFFECTS:  The breakpoint may be installed or at least have its
 *	'state' changed.
 *
 * STRATEGY:	  See comments below
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/30/88		Initial Revision
 *
 ***********************************************************************/
static void
BreakInterest(Handle  	  	handle,	    /* Handle that changed */
	      Handle_Status 	status,	    /* What happened to it */
	      Opaque 	    	data)	    /* Our data */
{
    BreakPtr   	bp = (BreakPtr)data;

    switch(status) {
	case HANDLE_SWAPIN:
	case HANDLE_LOAD:
	    /*
	     * This may be the first time the block has come in since the
	     * breakpoint was set, so make sure the stub knows about it.
	     */
	    if (!bp->isCond) {
		BreakInstallBP(bp);
	    }
	    break;
	case HANDLE_FREE:
	    /*
	     * Nuke the breakpoint record. Break_Clear takes care of nuking
	     * the BreakChain itself.
	     */
	    bp->orphan = TRUE;
	    BreakSave(bp);
	    break;
	case HANDLE_DISCARD:
	    /*
	     * Deal with loader/kernel things for which the stub isn't
	     * notified by handle (and besides, it can't find a handle for
	     * the loader stuff anyway...)
	     */
	    if (Handle_State(handle) & HANDLE_KERNEL) {
		BreakUninstallBP(bp);
	    }
	    break;
    }
}


/***********************************************************************
 *				CBreakInterest
 ***********************************************************************
 * SYNOPSIS:	    Interest procedure for conditional breakpoints
 * CALLED BY:	    Handle module, BreakInit for initial setting.
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Criteria may be installed, removed or changed for
 *	    the breakpoint.
 *
 * STRATEGY:
 *	Much, but not all, of our work is taken care of by the stub
 *	itself once the CBREAK has been established there. The part
 *	that's not taken care of is tracking of the segment for any
 *	block that's part of the condition.
 *
 *
 *	When the block is freed, we need do nothing as the breakpoint
 *	will be nuked and BreakFree will take care of removing
 *	the conditional breakpoint if it's installed.
 *
 *	When the block is loaded or swapped in, we need to re-establish
 *	the conditional breakpoint.
 *
 *	When the block is resized, install or remove the breakpoint
 *	depending on if it is within or out of bounds. If it is and
 *	was within bounds and installed, change the segment for it.
 *
 *	When the block is moved, change the segment for the breakpoint.
 *
 *	NOTE: This is called on state changes for either the handle in
 *	which the breakpoint is set or the handle in which the word
 *	being examined by the conditional breakpoint is located, if any.
 *	Hence, the code here doesn't use "handle" at all. The same
 *	considerations for the breakpoint apply regardless of which
 *	handle changed state, since the breakpoint cannot check the
 *	word if it's not in memory.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/89		Initial Revision
 *
 ***********************************************************************/
static void
CBreakInterest(Handle  	  	handle,	    /* Handle that changed */
	       Handle_Status 	status,	    /* What happened to it */
	       Opaque 	    	data)	    /* Our data */
{
    BreakPtr	    bp = (BreakPtr)data;
    int	    	    i;
    int	    	    resident;

    /*
     * Adjust the criteria for anything tracking the given handle and see
     * if all the handles are resident. Wait until we see what's happened
     * before we do anything with this information, however.
     */
    resident = HANDLE_IN;
    for (i = 0; i < CB_MAX_HANDLES; i++) {
	if (bp->cb.handles[i].handle != NullHandle) {
	    resident &= Handle_State(bp->cb.handles[i].handle);
	    *bp->cb.handles[i].value =
	                 Handle_Segment(bp->cb.handles[i].handle);
	}
    }

    if (bp->cb.criteria.cb_ip >= (word)Handle_Size(bp->handle)) {
	resident = 0;
    }
    resident &= HANDLE_IN;

    switch(status) {
	case HANDLE_SWAPIN:
	    /*
	     * Block swapped in -- breakpoint was nuked, so install it again.
	     */
	case HANDLE_LOAD:
	    /*
	     * Block has come in from disk in its original form -- also
	     * need to install the criteria (again).
	     */
	    if (resident & HANDLE_IN) {
		BreakInstallBP(bp);
	    }
	    break;
	case HANDLE_FREE:
	    /*
	     * If any handle in which we're interested goes away, we want to
	     * save the breakpoint away, getting rid of it.
	     *
	     * We don't do this if handle is bp->handle as BreakInterest will
	     * have done/will do this instead.
	     */
	    if (handle != bp->handle) {
		bp->orphan = TRUE;
		BreakSave(bp);
	    }
	    break;
	case HANDLE_SWAPOUT:
	    /*
	     * Block has been swapped to disk -- remove the criteria to avoid
	     * possible conflict with other breakpoints.
	     */
	case HANDLE_DISCARD:
	    /*
	     * Block has been discarded -- ditto. If the affected handle is
	     * the one in which the block is located, don't bother, as the
	     * stub will take care of disabling the thing.
	     */
	    if (handle != bp->handle) {
		BreakUninstallBP(bp);
	    }
	    break;
	case HANDLE_RESIZE:
	case HANDLE_MOVE:
	    /*
	     * Adjust criteria if installed (criteria fixed up by loop
	     * at the start already).
	     */
	    if (bp->bpNum != BP_NOT_INSTALLED) {
		ChangeCBreakArgs    ccba;

		ccba.ccba_num = bp->bpNum;
		ccba.ccba_crit = bp->cb.criteria;

		if (Rpc_Call(RPC_CHGCBREAK, sizeof(ccba),
			     typeChangeCBreakArgs, (Opaque)&ccba,
			     0, NullType, NullOpaque) != RPC_SUCCESS)
		{
		    Warning("Couldn't change conditional breakpoint: %s",
			    Rpc_LastError());
		}
	    }
	    break;
    }
}
/*-
 *-----------------------------------------------------------------------
 * Break_Set --
 *	Set a breakpoint at the given address in the given patient to
 *	call the given function with the given data.
 *
 * Results:
 *	The Break token.
 *
 * Side Effects:
 *	A BreakRec is allocated and linked into the hash table
 *	for the patient.
 *
 *-----------------------------------------------------------------------
 */
Break
Break_Set(Patient 	patient,    	/* Patient for which to set it */
	  Handle  	handle,	    	/* Handle of block in which... */
	  Address	offset,	    	/* Offset into handle at which... */
	  BreakHandler	*func,  	/* Function to call when it's hit */
	  Opaque	data) 	    	/* Data to pass it */
{
    BreakPtr	  	bp; 	    	/* Breakpoint being set */
    int	    	    	status;

    bp = (BreakPtr)malloc_tagged(sizeof(BreakRec), TAG_BREAK);

    bp->func = 	  	func;
    bp->data = 	    	data;
    bp->enabled = 	TRUE;
    bp->inuse =	    	FALSE;
    bp->nukeme =    	FALSE;
    bp->isCond =    	FALSE;
    bp->orphan =    	FALSE;
    bp->saved =	    	FALSE;
    bp->bpNum =	    	BP_NOT_INSTALLED;
    bp->patient =   	patient;
    bzero(&bp->cb, sizeof(bp->cb));

    status = BreakSet(bp, handle, offset);
    if (status != RPC_SUCCESS)
    {
	return (Break)NULL;
    }

    return ((Break)bp);
}

/*-
 *-----------------------------------------------------------------------
 * Break_TSet --
 *	Set a breakpoint at the given address in the given patient to
 *	call the given function with the given data. The breakpoint will
 *	be removed the next time the machine stops completely, even if it's
 *	in a different patient.
 *
 * Results:
 *	The Break token.
 *
 * Side Effects:
 *	A BreakRec is allocated and linked into the hash table
 *	for the patient.
 *
 *-----------------------------------------------------------------------
 */
Break
Break_TSet(Patient 	patient,    	/* Patient for which to set it */
	  Handle  	handle,	    	/* Handle of block in which... */
	  Address	offset,	    	/* Offset into handle at which... */
	  BreakHandler	*func,  	/* Function to call when it's hit */
	  Opaque	data) 	    	/* Data to pass it */
{
    Break	  	brk; 	    	/* Breakpoint being set */

    brk = Break_Set(patient, handle, offset, func, data);
    if (brk != (Break)NULL)
    {
	Lst_AtEnd(tempBreaks, (LstClientData)brk);
    }

    return(brk);
}

/*-
 *-----------------------------------------------------------------------
 * Break_Clear --
 *	Clear the given breakpoint for the given patient.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The BreakRec is free'd and removed from the hash table.
 *
 *-----------------------------------------------------------------------
 */
void
Break_Clear(Break	brkpt)
{
    register BreakPtr	bp,
			*prevPtr;
    LstNode 	    	ln;

    if (((BreakPtr)brkpt)->saved) {
	prevPtr = &savedBreaks;
    } else {
	prevPtr = &allBreaks;
    }

    for (bp = *prevPtr; bp != NULL; bp = *prevPtr) {
	if (bp == (BreakPtr)brkpt) {
	    break;
	} else {
	    prevPtr = &bp->next;
	}
    }

    assert(bp != NULL);

    /*
     * Advance to next element before freeing the breakpoint record.
     */
    if (breakDebug) {
	Message("Break_Clear(%04xh:%04xh, %xh, %xh)\n",
		bp->handle ? Handle_Segment(bp->handle) : 0,
		bp->offset, bp->func, bp->data);
    }

    /*
     * Unlink
     */
    *prevPtr = bp->next;

    /*
     * If breakpoint is temporary, remove it from the list of temporary bp's
     */
    ln = Lst_Member(tempBreaks, (LstClientData)bp);
    if (ln != NILLNODE) {
	Lst_Remove(tempBreaks, ln);
    }

    /*
     * Free the breakpoint, either by setting nukeme, if the breakpoint is
     * actively being used (e.g. its handler is being called), or by calling
     * BreakFree().
     */

    if (bp->inuse) {
	bp->nukeme = TRUE;
    } else {
	BreakFree(bp);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Break_Enable --
 *	Re-enable the given breakpoint for the patient.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The breakpoint is enabled and installed if all other breakpoints
 *	are installed.
 *
 *-----------------------------------------------------------------------
 */
void
Break_Enable(Break   	  	brkpt)
{
    register BreakPtr	bp;

    bp = (BreakPtr)brkpt;

    bp->enabled = TRUE;

    /*
     * If other breakpoints are installed, install this one
     * (it won't have been installed before because it wasn't
     * enabled).
     */
    BreakInstallBP(bp);
}

/*-
 *-----------------------------------------------------------------------
 * Break_Disable --
 *	Disable a breakpoint.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The breakpoint is disabled and removed if it's in and all
 *	breakpoints at that address are disabled.
 *
 *-----------------------------------------------------------------------
 */
void
Break_Disable(Break		brkpt)
{
    register BreakPtr	bp;

    bp = (BreakPtr)brkpt;

    bp->enabled = FALSE;

    BreakUninstallBP(bp);
}

/*-
 *-----------------------------------------------------------------------
 * Break_Address --
 *	Return the address of an installed breakpoint.
 *
 * Results:
 *	The address of the breakpoint.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Address
Break_Address(Break   	  	brkpt)
{
    return (((BreakPtr)brkpt)->offset);
}


/***********************************************************************
 *
 *	    BRK COMMAND IMPLEMENTATION
 *
 *********************************************************************/

/*
 * Array to map comparison nibbles to operators and vice-versa. The nibbles
 * are the low four bits of the Jcc opcode in the 8086. Which instruction
 * to use is complicated by the operand ordering of the CMPSW instruction and
 * the stub's use of the jump taken as indicating a mismatch.  It's got [SI]
 * pointing at the desired value, while [DI] points at the actual one. Since
 * the processor does [SI]-[DI] (effectively executing a CMP desired,current),
 * all the branches used must match their operators, except the equality test
 * is inverted. E.g. ">" requires a JAE, while "+>=" (signed greater-equal)
 * requires JG. For "=" and "!=", the same holds true, though they are only
 * tests for equality, so they appear to be inverted.
 */
static const char *cOps[] = {
    NULL,   	/* Uninteresting */
    NULL,   	/* Bogus */
    "<=",    	/* JB    */
    ">",   	/* JAE   */
    "!=",   	/* JE    */
    "=",    	/* JNE   */
    "<",   	/* JBE   */
    ">=",    	/* JA    */
    NULL,   	/* Bogus */
    NULL,   	/* Bogus */
    NULL,   	/* Bogus */
    NULL,   	/* Bogus */
    "+<=",   	/* JL    */
    "+>",  	/* JGE   */
    "+<",  	/* JLE   */
    "+>=",   	/* JG    */
};
#define COP_LE	2
#define COP_GT	3
#define COP_NE	4
#define COP_EQ	5
#define COP_LT	6
#define COP_GE	7
#define COP_LES	12
#define COP_GTS	13
#define COP_LTS	14
#define COP_GES	15

/*-
 *-----------------------------------------------------------------------
 * BreakTclCatch --
 *	Catch a breakpoint at the tcl level and invoke its command. If the
 *	command returns a value of 0, return FALSE to our caller. Else
 *	return TRUE (this includes errors).
 *
 * Results:
 *	FALSE or TRUE (see above).
 *
 * Side Effects:
 *	The tcl command is evaluated and the breakpoint variable set to
 *	the name of the breakpoint being taken.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static Boolean
BreakTclCatch(Break	    brkpt,
	      Opaque	    data)
{
    TclBreakPtr	    	tbPtr = (TclBreakPtr)data;
    char    	  	name[20];
    int	    	    	result;

    sprintf(name, "brk%d", tbPtr->id);
    Tcl_SetVar(interp, "breakpoint", name, TRUE);

    /*
     * If the evaluation returns an error, or a non-zero or empty result,
     * tell our caller to stop the patient.
     */
    result = Tcl_Eval(interp, tbPtr->command, 0, (const char **)NULL);

    if (result != TCL_OK) {
	if (interp->result[0]) {
	    Warning("brk%d: error: %s", tbPtr->id, interp->result);
	} else {
	    Warning("brk%d returned error", tbPtr->id);
	}
	return(TRUE);		/* Stop machine */
    } else if ((interp->result[0] == '\0') || (atoi(interp->result) != 0))
    {
	return(TRUE);		/* Stop machine */
    } else {
	return(FALSE);		/* Keep going */
    }
}


/*-
 *-----------------------------------------------------------------------
 * BreakTclPrint --
 *	Print out a breakpoint, telling if it is active or not, as well
 *	as the address at which it was set and the command that is executed
 *	when it is reached.
 *
 * Results:
 *	=== 0.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static int
BreakTclPrint(BreakPtr	bp)
{
    TclBreakPtr	    tbPtr = (TclBreakPtr)bp->data;
    Sym	    	    sym;
    char    	    *cp;
    char    	    *fullname;	    /* Full name of the closest symbol */
    int 	    fnlen;  	    /* Length of the full name */
    Address	    base;   	    /* Address of closest symbol */
    char	    diff[16];	    /* Space for difference */
    int	    	    offset; 	    /* Offset from symbol */
    char    	    state;
    char    	    addrBuf[16];    /* Space for address, if not
				     * symbol-relative */
    char    	    *pname; 	    /* Name of patient for which it's
				     * specific (NULL if none) */

    /*
     * Figure the fullname and offset from the symbol for the breakpoint.
     */
    if (bp->saved) {
	/*
	 * We figured this out when we saved the breakpoint away.
	 */
	offset = bp->symoff;
	fullname = (char *)malloc(strlen(bp->fullname)+1);
	strcpy(fullname, bp->fullname);
	/*
	 * Downcase the state letter to indicate the thing isn't really
	 * active
	 */
	state = tbPtr->user_enabled ? 'e' : 'd';
	/*
	 * Set the name of the patient for which the thing is specific (it's
	 * stored where the Patient would normally be stored in an active
	 * breakpoint).
	 */
	pname = (char *)bp->patient;
    } else {
	/*
	 * Breakpoint is active, so lookup the symbol closest to the beast.
	 */
	sym = Sym_LookupAddr(bp->handle, bp->offset, SYM_LABEL|SYM_FUNCTION);

	if (!Sym_IsNull(sym)) {
	    /*
	     * Fetch the full name of the symbol and figure how far away from
	     * the symbol the breakpoint was set.
	     */
	    Sym_GetFuncData(sym, (Boolean *)NULL, &base, (Type *)NULL);
	    fullname = Sym_FullName(sym);
	    offset = bp->offset -  base;
	} else {
	    /*
	     * Not relative to a symbol at all. Produce the segment and
	     * offset of the breakpoint instead.
	     */
	    word    seg, off;

	    if (bp->handle) {
		seg = Handle_Segment(bp->handle);
		off = (word)bp->offset;
	    } else {
		BreakDecomposeAddress(bp->offset, &seg, &off);
	    }
	    sprintf(addrBuf, "%04xh:%04xh", seg, off);
	    fullname = addrBuf;
	    offset = 0;
	}
	/*
	 * Set the name of the patient for which this breakpoint is specific,
	 * as well as the state letter for the breakpoint (uppercase, since
	 * the breakpoint is active.
	 */
	pname = bp->patient ? bp->patient->name : 0;
	state = tbPtr->user_enabled ? 'E' : 'D';
    }
    fnlen = strlen(fullname);

    if (!offset) {
	if (fnlen > 30) {
	    /*
	     * Name too long -- trim from the left, placing a < at the
	     * start to indicate the trimming.
	     */
	    cp = fullname + (fnlen-30);
	    *cp = '<';
	} else {
	    cp = fullname;
	}
	Message("%-3d %c %-30s %-11s",
		tbPtr->id, state, cp, (pname ? pname : "all"));
    } else {
	sprintf(diff, "+%d", offset);

	fnlen += strlen(diff);
	if (fnlen > 30) {
	    /*
	     * Address too long -- trim from left, as above except we
	     * take into account the length of the difference string.
	     */
	    cp = fullname + (fnlen-30);
	    *cp = '<';
	} else {
	    cp = fullname;
	}

	Message("%-3d %c %s%-*s %-11s",
		tbPtr->id, state, cp, 30 - strlen(cp), diff,
		pname ? pname : "all");
    }
    /*
     * Free the fullname buffer, if it was dynamically allocated.
     */
    if (fullname != addrBuf) {
	free(fullname);
    }

    /*
     * Print the conditional criteria, if any, first.
     */
    if (bp->isCond) {
	int 	    	i;
	byte	    	*cbyte,
			comp;
	static char 	*vals[] = {
#if REGS_32
	    "thread", "ax", "eax", "cx", "ecx", "dx", "edx", "bx", "ebx", "sp", "esp", "bp", "ebp", "si", "esi", "di", "edi", "es", "cs", "ss", "ds", "fs", "gs"
#else
	    "thread", "ax", "cx", "dx", "bx", "sp", "bp", "si", "di", "es", "cs", "ss", "ds"
#endif
	};

	for (i = 0, cbyte = bp->cb.criteria.cb_comps;
	     i < REG_NUM_REGS+1;
	     i++)
	{
	    comp = ((i & 1) ? (*cbyte++ >> 4) : *cbyte) & 0xf;

	    if (comp) {
		assert(cOps[comp] != NULL);

#if REGS_32
		if (i >= (reg_eax/2)+1 && i < (reg_es/2)+1 && !(i & 1))
		    Message("%s%s%08xh ", vals[i], cOps[comp],
			    (dword)(bp->cb.criteria.cb_regs[i-2])
			    | (dword)((bp->cb.criteria.cb_regs[i-1]) << 16));
		else
#endif
		Message("%s%s%04xh ", vals[i], cOps[comp],
			bp->cb.criteria.cb_regs[i-1]);
	    }
	}
	/*
	 * Deal with memory word comparison, if given.
	 */
	if (*cbyte >> 4) {
	    Message("(%04xh:%04xh)%s%04xh ",
		    bp->cb.criteria.cb_seg,
		    bp->cb.criteria.cb_off,
		    cOps[*cbyte >> 4],
		    bp->cb.criteria.cb_value);
	}
    }

    /*
     * Finally, print the command to be executed when the breakpoint
     * is hit/taken.
     */
    if ((cp = index(tbPtr->command, '\n')) != NULL) {
	/*
	 * Deal with newlines in the command by left-justifying the
	 * commands at the start of the Command/Condition field
	 */
	int 	offset = 0;
	char	*start = tbPtr->command;

	do {
	    Message("%*s%.*s", offset, "", cp-start+1, start);
	    offset = 48;	/* MAGIC (see banner) */
	    start = cp+1;
	    cp = index(start, '\n');
	} while (cp != NULL);

	if (*start != '\0') {
	    Message("%*s%s\n", offset, "", start);
	}
    } else {
	Message("%s\n", *tbPtr->command ? tbPtr->command : "halt");
    }
    return(0);
}


/***********************************************************************
 *				BreakGetNextTCLId
 ***********************************************************************
 * SYNOPSIS:	    Determine the next available ID number for a TCL
 *	    	    breakpoint, being careful of saved breakpoints
 *	    	    as well as those actively present.
 * CALLED BY:	    BreakInit, CBreakInit
 * RETURN:	    the ID number to use.
 * SIDE EFFECTS:    none.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 4/91		Initial Revision
 *
 ***********************************************************************/
static int
BreakGetNextTCLId(void)
{
    int	    	    id;

    if (!Lst_IsEmpty(tclBreaks)) {
	BreakPtr    bp2 = (BreakPtr)Lst_Datum(Lst_Last(tclBreaks));

	id = ((TclBreakPtr)bp2->data)->id + 1;
    } else {
	id = 1;
    }
    if (id > maxBreakPoint)
    {
	maxBreakPoint = id;
    }
    return (id);
}

/***********************************************************************
 *				BreakInit
 ***********************************************************************
 * SYNOPSIS:	    Initialize for a standard TCL breakpoint
 * CALLED BY:	    BreakCmd
 * RETURN:	    TRUE if successful
 * SIDE EFFECTS:    bp->private is filled and a TclBreakRec allocated
 *
 * STRATEGY:
 *	If a command was given, allocate a TclBreakRec big enough to
 *	hold the standard data and the command, then copy the command
 *	into the proper place.
 *
 *	Else create a TclBreakRec with a single byte at the end and
 *	initialize the command string for the record to be empty.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
BreakInit(Tcl_Interp	*interp,
	  BreakPtr  	bp,
	  int	    	start,
	  char	    	**argv)
{
    TclBreakPtr	tbPtr;

    if (argv[start]) {
	tbPtr = (TclBreakPtr)malloc_tagged(sizeof(TclBreakRec) +
					   strlen(argv[start])+1,
					   TAG_BREAK);
	strcpy(tbPtr->command, argv[start]);
    } else {
	tbPtr = (TclBreakPtr)malloc_tagged(sizeof(TclBreakRec)+1, TAG_BREAK);
	*tbPtr->command = '\0';
    }

    /*
     * Initialize standard fields and store the thing in the private field.
     */
    tbPtr->id = BreakGetNextTCLId();
    tbPtr->user_enabled = TRUE;
    tbPtr->delcmd = NULL;

    bp->data = (Opaque)tbPtr;
    return(TRUE);
}


/***********************************************************************
 *				CBreakSetComp
 ***********************************************************************
 * SYNOPSIS:	    Set a comparison in a set of criteria.
 * CALLED BY:	    CBreakParseCriteria
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The proper nibble in the cb_comps array is set, as
 *	    	    is the proper value.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/10/89		Initial Revision
 *
 ***********************************************************************/
static void
CBreakSetComp(CBreakPtr     cbPtr,  	/* Record containing criteria for
					 * the breakpoint */
	      int   	    wordNum,	/* Word being compared (0-REG_NUM_REGS+1) */
	      int   	    opNum,  	/* Operator nibble */
	      dword  	    value)  	/* Value against which to compare */
{
    /*
     * Store the value first. We subtract 1 from wordNum so we can address
     * cb_thread, since it comes before cb_regs.
     */
#if REGS_32
    if ((wordNum == 0 || wordNum >= (reg_es/2)+1) || (wordNum & 1))
	cbPtr->criteria.cb_regs[wordNum-1] = (word)value;
    else {
	cbPtr->criteria.cb_regs[wordNum-2] = (word)value;
	cbPtr->criteria.cb_regs[wordNum-1] = (word)(value >> 16);
    }
#endif

    /*
     * First clear out the field to be nuked, then OR in the operator...
     */
    if (wordNum & 1) {
	cbPtr->criteria.cb_comps[wordNum/2] &= 0x0f;
	cbPtr->criteria.cb_comps[wordNum/2] |= opNum << 4;
    } else {
	cbPtr->criteria.cb_comps[wordNum/2] &= 0xf0;
	cbPtr->criteria.cb_comps[wordNum/2] |= opNum & 0xf;
    }
}


/***********************************************************************
 *				CBreakRegisterHandle
 ***********************************************************************
 * SYNOPSIS:	    Register another handle to be tracked for a
 *		    conditional breakpoint.
 * CALLED BY:	    CBreakParseCriteria, CBreakInit
 * RETURN:	    nothing
 * SIDE EFFECTS:    the handle and pointer are stored in the criteria
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/91	Initial Revision
 *
 ***********************************************************************/
static void
CBreakRegisterHandle(CBreakPtr      cbPtr,
		     Handle 	    handle,
		     word   	    *valuePtr)
{
    int	    i;

    /*
     * Find an empty slot in the handles array.
     */
    for (i = 0; i < CB_MAX_HANDLES; i++) {
	if (cbPtr->handles[i].handle == NullHandle) {
	    break;
	}
    }
    assert(i != CB_MAX_HANDLES);

    /*
     * Record the handle in the array.
     */
    cbPtr->handles[i].handle = handle;
    cbPtr->handles[i].value = valuePtr;

    /*
     * Set the initial value to the current segment of the block.
     */
    *valuePtr = Handle_Segment(handle);
}

/***********************************************************************
 *				CBreakParseCriteria
 ***********************************************************************
 * SYNOPSIS:	    Parse a criteria specification for a breakpoint
 *	    	    into a CBreakArgs structure.
 * CALLED BY:	    CBreakInit, BreakCondCmd
 * RETURN:	    TCL_OK or TCL_ERROR
 * SIDE EFFECTS:    The criteria field is completely overwritten.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 9/89		Initial Revision
 *
 ***********************************************************************/
static int
CBreakParseCriteria(Tcl_Interp	*interp,    /* Interpreter for errors */
		    CBreakPtr	cbPtr,	    /* Record into which to parse
					     * the criteria */
		    BreakPtr	bp, 	    /* Real breakpoint record */
		    int	    	start,	    /* First arg in criteria */
		    char    	**argv)	    /* Arguments to command */
{
    int	    i;

    /*
     * Set up initial CS:IP and criteria comparison array, marking the
     * breakpoint as conditional if it wasn't so marked already.
     */
    cbPtr->criteria.cb_ip = (word)bp->offset;

    /*
     * Express our distinct lack of interest in all the previous handles,
     * if any.
     */
    for (i = 0; i < CB_MAX_HANDLES; i++) {
	if (cbPtr->handles[i].handle != NullHandle) {
	    Handle_NoInterest(cbPtr->handles[i].handle, CBreakInterest,
			      (Opaque)bp);
	}
    }

    /*
     * Zero the array of handles tracked so we know where the last one is.
     */
    bzero(&cbPtr->handles, sizeof(cbPtr->handles));

    /*
     * Set the first handle tracked to be the one in which the breakpoint
     * is located, setting it to store its segment in the cb_cs part of
     * the criteria.
     */
    CBreakRegisterHandle(cbPtr, bp->handle, &cbPtr->criteria.cb_cs);


    bzero(cbPtr->criteria.cb_comps, sizeof(cbPtr->criteria.cb_comps));

    /*
     * Clear out previous breakpoint, if any
     */
    BreakUninstallBP(bp);

    if (bp->patient) {
	Warning("Can't set patient-specific conditional breakpoints now");
    }

    /*
     * Process the remaining criteria
     */
    for (i = start; argv[i] != (char *)NULL; i++) {
	char	    *cp;	/* Current position in arg */
	int 	    wordNum;    /* Word to compare (0-12) */
	int 	    opNum;	/* Operator nibble */
	GeosAddr    value;  	/* Value with which to compare */
	Type	    valType;	/* Type of data returned, if ValueHandle */

	/*
	 * Figure out what word of the criteria is being compared, leaving the
	 * result in wordNum.
	 */
	if (strncmp(argv[i], "thread", 6) == 0) {
	    wordNum = 0;
	    cp = argv[i]+6;
	} else if (argv[i][0] == '(') {
	    int	    	level;
	    GeosAddr	addr;
	    char    	savec;

	    for (cp = &argv[i][1], level = 1; level && *cp; cp++) {
		if (*cp == '(') {
		    level++;
		} else if (*cp == ')') {
		    level--;
		}
	    }
	    if (level) {
		Tcl_Error(interp, "missing closing parenthesis");
	    }
	    savec = *cp;
	    *cp = '\0';
	    if (!Expr_Eval(argv[i], NullFrame, &addr, (Type *)NULL, TRUE) ||
		(addr.handle == ValueHandle))
	    {
		Tcl_RetPrintf(interp, "%s: malformed address", argv[i]);
		return(TCL_ERROR);
	    }
	    *cp = savec;
	    if (addr.handle) {
		CBreakRegisterHandle(cbPtr, addr.handle,
				     &cbPtr->criteria.cb_seg);
		cbPtr->criteria.cb_off = (word)addr.offset;
	    } else {
		BreakDecomposeAddress(addr.offset,
				      &cbPtr->criteria.cb_seg,
				      &cbPtr->criteria.cb_off);
	    }
	    wordNum = REG_NUM_REGS+1;
	} else {
	    Reg_Data	*rdp;
	    char    	savec;

#if REGS_32
	    cp = &argv[i][0];
	    while (*cp != '\0' && isalpha(*cp))
		cp++;
#else
	    cp = &argv[i][2];
#endif
	    savec = *cp;
	    *cp = '\0';
	    rdp = (Reg_Data *)Private_GetData(argv[i]);

	    if (rdp == NULL) {
		Tcl_RetPrintf(interp, "%s: unknown register", argv[i]);
		return (TCL_ERROR);
	    } else if (rdp->type != REG_MACHINE) {
		Tcl_RetPrintf(interp, "%s: not a machine register",
			      argv[i]);
		return(TCL_ERROR);
#if REGS_32
	    } else if (rdp->number >= REG_NUM_REGS && rdp->number < REG_EAX) {
		Tcl_RetPrintf(interp, "%s: not a word or dword register", argv[i]);
		return(TCL_ERROR);
#else
	    } else if (rdp->number >= REG_NUM_REGS) {
		Tcl_RetPrintf(interp, "%s: not a word register", argv[i]);
		return(TCL_ERROR);
#endif
	    } else {
#if REGS_32
		if (rdp->number >= REG_FS)
		    wordNum = rdp->number+(reg_fs/2-REG_FS)+1;
		else if (rdp->number >= REG_EAX) {
		    wordNum = ((rdp->number-REG_EAX)*2)+2;
		    /* The operator nibble for the word-sized version of this
		       register is in the upper nibble of the previous byte. */
		    if (cbPtr->criteria.cb_comps[(wordNum/2)-1] & 0xf0) {
			Tcl_RetPrintf(interp, "%s: cannot test both word and dword contents of same register", argv[i]);
			return(TCL_ERROR);
		    }
		}
		else if (rdp->number >= REG_ES)
		    wordNum = rdp->number+((reg_es/2)-REG_ES)+1;
		else {
		    wordNum = ((rdp->number-REG_AX)*2)+1;
		    /* The operator nibble for the dword-sized version of this
		       register is in the lower nibble of the following byte. */
		    if (cbPtr->criteria.cb_comps[(wordNum/2)+1] & 0x0f) {
			Tcl_RetPrintf(interp, "%s: cannot test both word and dword contents of same register", argv[i]);
			return(TCL_ERROR);
		    }
		}
#else
		wordNum = rdp->number+1;
#endif
		*cp = savec;
	    }
	}

	/*
	 * Now figure out what the operator is. We know 0 and 1 are bogus,
	 * so don't even look at them...
	 */
	while(isspace(*cp)) {
	    cp++;
	}

	switch(*cp) {
	    case '+':
		switch(cp[1]) {
		    case '>':
			if (cp[2] == '=') {
			    opNum = COP_GES; cp += 3;
			} else {
			    opNum = COP_GTS; cp += 2;
			}
			break;
		    case '<':
			if (cp[2] == '=') {
			    opNum = COP_LES; cp += 3;
			} else {
			    opNum = COP_LTS; cp += 2;
			}
			break;
		    default:
			Tcl_RetPrintf(interp, "Bogus operator %.2s", cp);
			return(TCL_ERROR);
		}
		break;
	    case '>':
		if (cp[1] == '=') {
		    opNum = COP_GE; cp += 2;
		} else {
		    opNum = COP_GT; cp += 1;
		}
		break;
	    case '<':
		if (cp[1] == '=') {
		    opNum = COP_LE; cp += 2;
		} else {
		    opNum = COP_LT; cp += 1;
		}
		break;
	    case '!':
		if (cp[1] != '=') {
		    Tcl_Error(interp, "! not followed by =");
		} else {
		    opNum = COP_NE; cp += 2;
		}
		break;
	    case '=':
		opNum = COP_EQ; cp += 1;
		break;
	    default:
		Tcl_RetPrintf(interp, "Bogus operator %c", *cp);
		return(TCL_ERROR);
	}

	/*
	 * Figure out the value with which to compare it and store the whole
	 * thing.
	 */
	if (!Expr_Eval(cp, NullFrame, &value, &valType, FALSE)) {
	    Tcl_RetPrintf(interp, "%s: malformed value", cp);
	    return(TCL_ERROR);
	} else {
	    if (value.handle == ValueHandle) {
		dword	    condition;
		Handle	    handle;

		switch(Type_Class(valType)) {
		    case TYPE_POINTER:
#if REGS_32
			if (wordNum >= (reg_es/2)+1 && wordNum <= (reg_gs/2)+1) {
#else
			if (wordNum >= REG_ES+1) {
#endif
			    /*
			     * Segment register. Pointer, by definition,
			     * is a far pointer, so use its segment.
			     */
			    assert(Type_Sizeof(valType) == 4);

			    condition = (*(dword *)value.offset) >> 16;
			    handle = Handle_Find(MakeAddress(condition, 0)) ;
			    if ((handle != NullHandle) &&
				(Handle_Segment(handle) != (word)condition))
			    {
				/*
				 * Segment falls within a block, but isn't
				 * actually the start of that block, so stick
				 * with the offset that we've already got
				 * stored.
				 */
				handle = NullHandle;
			    }
			} else {
			    /*
			     * Just use the offset portion of the pointer,
			     * since the register isn't a segment register.
			     */
			    condition = (*(dword *)value.offset) & 0xffff;
			    handle = NullHandle;
			}
			break;
		    default:
		    {
#if REGS_32
			if ((wordNum > 0 && wordNum < (reg_es/2)+1)
			    && !(wordNum & 1)) {
			    dword	*newval =
				(dword *)Var_Cast((genptr)value.offset,
						  valType,
						  type_DWord);
			    if (newval != NULL) {
				/*
				 * Cast successful. Free the old value and set
				 * condition to be the new value as a dword.
				 */
				free((malloc_t)value.offset);
				value.offset = (Address)newval;
				condition = *newval;
				handle = NullHandle;
			    } else {
				/*
				 * Cast failed, so generate an error after freeing
				 * the value.
				 */
				free((malloc_t)value.offset);
				Tcl_RetPrintf(interp,
					      "%s: cannot be cast to a dword",
					      cp);
				return(TCL_ERROR);
			    }
			    break;
			} else {
#endif
			word	*newval = (word *)Var_Cast((genptr)value.offset,
							   valType,
							   type_Word);
			if (newval != NULL) {
			    /*
			     * Cast successful. Free the old value and set
			     * condition to be the new value as a word.
			     */
			    free((malloc_t)value.offset);
			    value.offset = (Address)newval;
			    condition = *newval;
			    handle = NullHandle;
			} else {
			    /*
			     * Cast failed, so generate an error after freeing
			     * the value.
			     */
			    free((malloc_t)value.offset);
			    Tcl_RetPrintf(interp,
					  "%s: cannot be cast to a word",
					  cp);
			    return(TCL_ERROR);
			}
			break;
#if REGS_32
			}
#endif
		    }
		}
		CBreakSetComp(cbPtr, wordNum, opNum, (dword)condition);

		/*
		 * Free the buffer containing the value.
		 */
		free((malloc_t)value.offset);

#if REGS_32
		if ((wordNum >= (reg_es/2)+1 && wordNum <= (reg_gs/2)+1)
		     && (handle != NullHandle)) {
#else
		if ((wordNum >= REG_ES+1) && (handle != NullHandle)) {
#endif
		    CBreakRegisterHandle(cbPtr, handle,
					 &cbPtr->criteria.cb_regs[wordNum-1]);
		}
	    } else {
		CBreakSetComp(cbPtr, wordNum, opNum, value.offset);

		/*
		 * If the register is a segment register and the value is
		 * handle-relative, register the handle as the value for
		 * the register (note that the CBreakSetComp above only
		 * sets the operator in this case, as the value is overridden
		 * by fetching the segment of the handle we register).
		 */
#if REGS_32
		if ((wordNum >= (reg_es/2)+1 && wordNum <= (reg_gs/2)+1)
		    && (value.handle != NullHandle)) {
#else
		if ((wordNum >= REG_ES+1) && (value.handle != NullHandle)) {
#endif
		    CBreakRegisterHandle(cbPtr, value.handle,
					 &cbPtr->criteria.cb_regs[wordNum-1]);
		}
	    }
	}
    }

    /*
     * Now criteria are parsed, mark the thing as a conditional BP
     */
    bp->isCond = TRUE;

    return(TCL_OK);
}


/***********************************************************************
 *				CBreakFinishCriteriaChange
 ***********************************************************************
 * SYNOPSIS:	    Finish changing the criteria for a conditional
 *		    breakpoint by registering interest in all the
 *		    tracked handles, and installing the criteria if
 *		    we can safely do so.
 * CALLED BY:	    CBreakInit, BrkCmd
 * RETURN:	    nothing
 * SIDE EFFECTS:    handle interest records are created and the
 *		    breakpoint is installed if appropriate (so
 *		    tbPtr->bnum will be set)
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/91	Initial Revision
 *
 ***********************************************************************/
static void
CBreakFinishCriteriaChange(BreakPtr 	bp)
{
    int	    	i;
    int	    	resident;

    /*
     * Register interest in the handle(s) for this thing so we set, change and
     * unset the breakpoint criteria. Also set resident's HANDLE_IN bit to
     * non-zero if all the handles in which we are interested are loaded.
     */
    resident = HANDLE_IN;
    for (i = 0; i < CB_MAX_HANDLES; i++) {
	if (bp->cb.handles[i].handle != NullHandle) {
	    resident &= Handle_State(bp->cb.handles[i].handle);
	    Handle_Interest(bp->cb.handles[i].handle, CBreakInterest,
			    (Opaque)bp);
	}
    }

    /*
     * If all handles are resident, pretend the breakpoint handle just came in
     * so we install the criteria right away.
     */
    if (resident & HANDLE_IN) {
	BreakInstallBP(bp);
    }
}


/***********************************************************************
 *				CBreakInit
 ***********************************************************************
 * SYNOPSIS:	    Initialize a conditional breakpoint
 * CALLED BY:	    BreakCmd
 * RETURN:	    TRUE if successful.
 * SIDE EFFECTS:    bp->private filled with private data.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
CBreakInit(Tcl_Interp	*interp,
	   BreakPtr  	bp,
	   int	    	start,
	   char	    	**argv)
{
    TclBreakPtr     tbPtr = (TclBreakPtr)malloc_tagged(sizeof(TclBreakRec)+1,
						      TAG_BREAK);

    /*
     * Make the command empty.
     */
    *tbPtr->command = '\0';

    tbPtr->delcmd = NULL;

    /*
     * Initialize to have no interest in anything...
     */
    bzero(&bp->cb.handles, sizeof(bp->cb.handles));

    /*
     * Parse the criteria specification. If it doesn't say life is good,
     * free the record we allocated, clear the breakpoint and tell the
     * user to f*** off.
     */
    if (CBreakParseCriteria(interp, &bp->cb, bp, start, argv) != TCL_OK) {
	free((char *)tbPtr);
	return(FALSE);
    }

    /*
     * Criteria now processed -- record the private data.
     */
    bp->data = (Opaque)tbPtr;

    tbPtr->id = BreakGetNextTCLId();
    tbPtr->user_enabled = TRUE;

    CBreakFinishCriteriaChange(bp);

    return(TRUE);
}

/***********************************************************************
 *				BreakTclEnable
 ***********************************************************************
 * SYNOPSIS:	    Enable a Tcl breakpoint.
 * CALLED BY:	    BrkCmd
 * RETURN:	    nothing
 * SIDE EFFECTS:    tbPtr->user_enabled is set true.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/91	Initial Revision
 *
 ***********************************************************************/
static void
BreakTclEnable(Break brkpt)
{
    TclBreakPtr	tbPtr = (TclBreakPtr)((BreakPtr)brkpt)->data;

    if (!tbPtr->user_enabled) {
	tbPtr->user_enabled = TRUE;

	/*
	 * If the breakpoint is conditional, let CBreakInterest enable the thing
	 * if all affected handles are resident.
	 */
	Break_Enable(brkpt);
    }
}

/***********************************************************************
 *				BreakTclDisable
 ***********************************************************************
 * SYNOPSIS:	    Disable a Tcl breakpoint.
 * CALLED BY:	    BrkCmd
 * RETURN:	    nothing
 * SIDE EFFECTS:    tbPtr->user_enabled is set true.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/91	Initial Revision
 *
 ***********************************************************************/
static void
BreakTclDisable(Break brkpt)
{
    if (((TclBreakPtr)((BreakPtr)brkpt)->data)->user_enabled) {
	((TclBreakPtr)((BreakPtr)brkpt)->data)->user_enabled = FALSE;
	Break_Disable(brkpt);
    }
}

/***********************************************************************
 *				BreakFindTclByNumber
 ***********************************************************************
 * SYNOPSIS:	    Locate a Tcl breakpoint given its ID number.
 * CALLED BY:	    BrkCmd, BreakFindTcl
 * RETURN:	    BreakPtr, or NULL if not found
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/91	Initial Revision
 *
 ***********************************************************************/
static BreakPtr
BreakFindTclByNumber(int    id)
{
    LstNode 	ln;
    BreakPtr	bp;

    for (ln = Lst_First(tclBreaks); ln != NILLNODE; ln = Lst_Succ(ln)) {
	bp = (BreakPtr)Lst_Datum(ln);
	if (((TclBreakPtr)bp->data)->id == id) {
	    return(bp);
	}
    }

    return ((BreakPtr)NULL);
}

/***********************************************************************
 *				BreakFindTcl
 ***********************************************************************
 * SYNOPSIS:	    Find a Tcl breakpoint given its name or number in
 *		    ascii.
 * CALLED BY:	    BrkCmd
 * RETURN:	    BreakPtr, or NULL
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/91	Initial Revision
 *
 ***********************************************************************/
static BreakPtr
BreakFindTcl(char   *name)
{
    int	    	id;
    char    	*end;

    if (strncmp(name, "brk", 3) == 0) {
	name += 3;
    }
    id = cvtnum(name, &end);
    if (end == name) {
	/*
	 * Not a valid number, so bitch.
	 */
	return((BreakPtr)NULL);
    }

    return (BreakFindTclByNumber(id));
}
/*-
 *-----------------------------------------------------------------------
 * BreakCmd --
 *	Function to implement the TCL "brk" command.
 *
 * Results:
 *	TCL_OK or TCL_ERROR.
 *
 * Side Effects:
 *	Breakpoints may be set.
 *
 *-----------------------------------------------------------------------
 */
#define BRK_SET	    (ClientData)0
#define BRK_CLEAR   (ClientData)1
#define BRK_ENABLE  (ClientData)2
#define BRK_DISABLE (ClientData)3
#define BRK_ADDRESS (ClientData)4
#define BRK_LIST    (ClientData)5
#define BRK_SSET    (ClientData)6
#define BRK_DEBUG   (ClientData)7
#define BRK_ISSET   (ClientData)8
#define BRK_COND    (ClientData)9
#define BRK_CMD	    (ClientData)10
#define BRK_DELCMD  (ClientData)11
#define BRK_ISENABLED (ClientData)12
static const CmdSubRec brkCmds[] = {
    {"pset",  	BRK_SET,    1, 2, "<addr> [<command>]"},
    {"aset", 	BRK_SET,    1, 2, "<addr> [<command>]"},
    {"tset", 	BRK_SET,    1, 2, "<addr> [<command>]"},
    {"clear", 	BRK_CLEAR,  0, CMD_NOCHECK, "<break>*"},
    {"delete", 	BRK_CLEAR,  0, CMD_NOCHECK, "<break>*"},
    {"enable",	BRK_ENABLE, 0, CMD_NOCHECK, "<break>*"},
    {"disable",	BRK_DISABLE,0, CMD_NOCHECK, "<break>*"},
    {"address",	BRK_ADDRESS,1, 1, "<break>"},
    {"isenabled",BRK_ISENABLED, 1, 1, "<break>"},
    {"list", 	BRK_LIST,   0, 1, "[<addr>]"},
    {"debug",	BRK_DEBUG,  0, 1, "[<flag>]"},
    {"isset", 	BRK_ISSET,  1, 1, "<addr>"},
    {"cond", 	BRK_COND,   1, CMD_NOCHECK, "<break> <condition>*"},
    {"cmd",  	BRK_CMD,    1, 2, "<break> [<command>]"},
    {"delcmd",	BRK_DELCMD, 1, 2, "<break> [<command>]"},
    {"",	    	BRK_SSET,   0, 1, "<addr> [<command>]"},
    {NULL,   	0,  	    0, 0, NULL}
};

DEFCMD(brk,Break,0,brkCmds,top.breakpoint|swat_prog.breakpoint,
"Usage:\n\
    brk <addr> [<command>]\n\
    brk pset <addr> [<command>]\n\
    brk aset <addr> [<command>]\n\
    brk tset <addr> [<command>]\n\
    brk clear <break>*\n\
    brk delete <break>*\n\
    brk enable <break>*\n\
    brk disable <break>*\n\
    brk address <break>\n\
    brk isenabled <break>\n\
    brk list [<addr>]\n\
    brk debug [<flag>]\n\
    brk isset <addr>\n\
    brk cond <break> <condition>*\n\
    brk cmd <break> [<command>]\n\
    brk delcmd <break> [<command>]\n\
\n\
Examples:\n\
    \"brk WinOpen\"	    	Sets the machine to stop unconditionally\n\
				when any thread calls WinOpen.\n\
    \"brk pset WinOpen\"	    	Sets the machine to stop when any thread for\n\
				the current patient calls WinOpen.\n\
    \"brk tset WinOpen\"	    	Sets the machine to stop when any thread for\n\
				the current patient calls WinOpen, and deletes\n\
				the breakpoint when the machine next stops.\n\
    \"brk enable 1 3-5\"	    	Re-enables breakpoints 1, 3, 4, and 5\n\
    \"brk clear 2-\"  	    	Clears all breakpoints from number 2 onward.\n\
    \"brk cond 3 cx=42\"	    	Sets breakpoint 3 to be conditional, stopping\n\
				when the machine reaches the breakpoint's\n\
				address with CX being 42.\n\
    \"brk cond 2 (ss:0)!=1b80h\"	Sets breakpoint 2 to be conditional, stopping\n\
				when the machine reaches the breakpoint's\n\
				address with the word at ss:0 not being\n\
				1b80h. Note that the \"ss\" is the value of ss\n\
				when the \"brk cond\" command is executed, not\n\
				when the breakpoint is reached.\n\
\n\
Synopsis:\n\
    Allows you to specify that execution should stop when it reaches a\n\
    particular point. These breakpoints can be conditional, and can execute\n\
    an arbitrary Tcl command, which can say whether the machine is to remain\n\
    stopped, or continue on its way.\n\
\n\
Notes:\n\
    * Once you've set a breakpoint, \"brk\" will return to you a token for that\n\
      breakpoint that begins with \"brk\" and ends with a number. When you refer\n\
      to the breakpoint, you can use either the full name (as you'll usually\n\
      do from a Tcl procedure), or just the number (if you're lazy like me).\n\
\n\
    * Breakpoints have four attributes: the address at which they are set,\n\
      the condition set on their being recognized, the Tcl command string\n\
      to execute when they are recognized, and the Tcl command string to\n\
      execute when they are deleted.\n\
\n\
    * The condition is set either when the breakpoint is set, using the \"cbrk\"\n\
      command, or after you've set the breakpoint, by invoking the \"brk cond\"\n\
      command.\n\
\n\
    * A breakpoint's condition is evaluated (very quickly) on the PC and can\n\
      check only word registers (the 8 general registers, the three segment\n\
      registers other than CS, and the current thread; each register may be\n\
      checked only once in a condition) and a single word of memory. Each\n\
      <condition> argument is of the form \"<reg><op><value>\". <reg> is one\n\
      of the 16-bit machine registers, \"thread\" (for the current thread), or\n\
      the address of a word of memory to check, enclosed in parentheses.\n\
      <op> is a relational operator taken from the following set:\n\
	=   	    	equal-to\n\
	!=  	    	not-equal-to\n\
	> < >= <=  	unsigned greater-than, less-than, greater-or-equal,\n\
			and less-or-equal\n\
	+> +< +>= +<=	signed greater-than, less-than, greater-or-equal,\n\
			and less-or-equal\n\
      <value> is a regular Swat address expression. If it is handle-relative,\n\
      and the <reg> is one of the three non-CS segment registers, the condition\n\
      will be for the segment of that handle and will change automatically\n\
      as the handle's memory shifts about on the heap. Similar things will\n\
      happen if you specify a number as the <value> for a segment register and\n\
      the number is the current segment of a block on the heap.\n\
\n\
    * If you give no <condition> argument to the \"brk cond\" command, you\n\
      will remove any condition the breakpoint might have, making it,\n\
      therefore, unconditional.\n\
\n\
    * If a breakpoint is given an associated <command> string, it will be\n\
      evaluated before the breakpoint is taken. If the result of the\n\
      evaluation is an error, a non-numeric string, or a numeric string that's\n\
      non-zero, the breakpoint will be taken. Else the machine will be allowed\n\
      to continue (so long as no other breakpoint command or other part of\n\
      Swat insists that it remain stopped). You can use this to simply\n\
      print out information when execution reaches the breakpoint address\n\
      without interrupting the machine's execution.\n\
\n\
    * The global variable \"breakpoint\" contains the name of the breakpoint\n\
      whose command is being evaluated while that command is being evaluated.\n\
\n\
    * You can change the command associated with a breakpoint with the \"brk\n\
      cmd\" command. If you give no <command> argument, then no command\n\
      will be executed and the breakpoint will always be taken, so long as\n\
      any associated condition is also met.\n\
\n\
    * If a breakpoint has both a condition and a command, the command will\n\
      not be executed until the condition has been met, unless there's another\n\
      breakpoint at the same address with a different, or no, condition.\n\
\n\
    * You can set a breakpoint to last only during the next continuation of the\n\
      machine by calling \"brk tset\". The breakpoint thus set will be removed\n\
      when next the machine comes to a full stop, regardless of why it stopped\n\
      (i.e. if it hits a different breakpoint, the temporary breakpoint will\n\
      still be removed). The breakpoint will only be taken if the thread\n\
      executing when it is hit is owned by the patient that was current when\n\
      the breakpoint was set.\n\
\n\
    * Each <break> argument to the \"brk clear\", \"brk enable\" and \"brk\n\
      disable\" commands can be either a single breakpoint token (or number), or\n\
      a range of the form <start>-<end>, where either <start> or <end> may\n\
      be absent. If <start> is missing, the command affects all breakpoints\n\
      from number 1 to <end>. If <end> is missing, the command affects all\n\
      breakpoints from <start> to the last one in existence.\n\
\n\
    * If you give no <break> argument to \"brk clear\", \"brk enable\" or\n\
      \"brk disable\", the command will apply to all breakpoints that are\n\
      specific to the current patient, i.e. that were set with the \"brk pset\"\n\
      command, unless the current patient is the kernel, in which case they\n\
      will apply to all breakpoints that are specific to no patient (i.e.\n\
      those set with the \"brk aset\" or \"brk <addr>\" commands).\n\
\n\
    * \"brk address\" returns the address expression for where the breakpoint\n\
      is set. This will usually be of the form ^h<handle-id>:<offset>, with\n\
      both <handle-id> and <offset> in hex (followed by an \"h\", of course).\n\
      If the breakpoint is set at an absolute address, you will get back only\n\
      a single hex number, being the linear address at which the breakpoint\n\
      is set.\n\
\n\
    * If you type \"brk list\" with no argument, Swat will print out a listing\n\
      of the currently-active breakpoints. If you give an <addr> (address\n\
      expression) argument, however, you'll be returned a list of the\n\
      breakpoints set at the given address. If there are no breakpoints\n\
      there, the list will be empty.\n\
\n\
    * As a shortcut, you can invoke \"brk isset\" to see if any breakpoints\n\
      are set at the given address, if you're not interested in which\n\
      ones they are.\n\
\n\
    * For Tcl commands that make use of breakpoints, but maintain additional\n\
      data elsewhere, you can specify a Tcl command to execute when the break-\n\
      point is deleted, to allow you to clean up the extra data. As for the\n\
      regular command, the global variable \"breakpoint\" is set to the name of\n\
      the breakpoint being deleted while the command is being evaluated.\n\
\n\
See also:\n\
    cbrk, tbrk, objbrk\n\
")
{
    TclBreakPtr  	tbPtr;	    /* Our private data */
    BreakPtr	    	bp; 	    /* Real breakpoint record */
    char    	    	*addrExpr;  /* Where to set breakpoint */
    int	    	    	firstArg;   /* Index of first arg after address */
    int	    	    	i;  	    /* General index */
    Break	    	(*setFunc)(Patient, Handle, Address, BreakHandler *, Opaque);
    Patient 	    	patient=curPatient;
    char    	    	*cp;	    	/* For cvtnum... */
    int	    	    	refresh = 1;	/* for BRK_CLEAR srcwin refreshes */

#define BreakGetNum(n,endPtr)	    \
    ((strncmp(n, "brk", 3) == 0) ? \
     cvtnum(&(n)[3], (endPtr)) : \
     cvtnum((n), (endPtr)))

    switch((int)clientData) {
    case BRK_SSET:
	/*
	 * Assuming we're to set a non-patient-specific, permanent breakpoint.
	 * Set up parameters and skip down to actually setting things.
	 */
	addrExpr = argv[1];
	firstArg = 2;
	setFunc = Break_Set;
	patient = NullPatient;
	goto set_brk;
    case BRK_SET:
    {
	GeosAddr    	addr;	/* Place at which to set breakpoint */

	/*
	 * Set up parameters for breakpoint setting
	 */
	addrExpr = argv[2];
	firstArg = 3;
	setFunc = (argv[1][0] == 't' ? Break_TSet : Break_Set);
	patient = argv[1][0] == 'a' ? NullPatient : curPatient;

set_brk:

	if (!Expr_Eval(addrExpr, NullFrame, &addr, (Type *)NULL, TRUE))
	{
	    Tcl_Error(interp, "Invalid address");
	} else if (argv[0][0] == 'c' && addr.handle == NullHandle) {
	    Tcl_Error(interp, "Conditional breakpoint must be set relative to a handle");
	} else if (argv[0][0] == 'c' && addr.offset > (Address)0xffff) {
	    Tcl_Error(interp, "Can't set conditional breakpoint beyond 64K in a segment");
	} else {
	    /*
	     * Set the proper sort of breakpoint, according to the type
	     */
	    bp = (BreakPtr) (* setFunc)(patient, addr.handle, addr.offset,
					BreakTclCatch, NullOpaque);

	    if (bp == (Break)NULL)
	    {
		/* an error message is put out by the RPC module
		 * so just return ok here
		 */
		return TCL_OK;
	    }
	    if ((argv[0][0]=='c' && !CBreakInit(interp, bp, firstArg, argv))||
		(argv[0][0]!='c' && !BreakInit(interp, bp, firstArg, argv)))
	    {
		Break_Clear(bp);
		return(TCL_ERROR);
	    }

	    /*
	     * Private data initialized -- add the thing to the list of
	     * Tcl breakpoints.
	     */
	    (void)Lst_AtEnd(tclBreaks, (LstClientData)bp);

	    if (addr.handle == NullHandle && breakDebug) {
		Warning("Breakpoint %d set at absolute address",
			((TclBreakPtr)bp->data)->id);
	    }
	    /* update the srcwin just in case the break point is in
	     * code current being viewed
	     */
	    if ((int)clientData == (int)BRK_SSET)
	    {
	    	Tcl_Eval(interp, "dss", 0, NULL);
	    }
	    Tcl_RetPrintf(interp, "brk%d", ((TclBreakPtr)bp->data)->id);
	}
	break;
    }
    case BRK_ISENABLED:
	bp = BreakFindTclByNumber(atoi(argv[2]));
	Tcl_Return(interp, bp->enabled ? "1" : "0", TCL_STATIC);
	return TCL_OK;
    case BRK_CLEAR:
	if (argc == 2) {
	    LstNode	ln;
	    char    	ans[32];
	    Patient 	patient = curPatient;

	    if (patient == kernel || patient == loader) {
		MessageFlush("Clear all non-patient-specific breakpoints?[yn](n) ");
		patient = NullPatient;
	    } else {
		MessageFlush("Clear all breakpoints for %s?[yn](n) ",
			     patient->name);
	    }
	    Ui_ReadLine(ans);
	    if ((*ans != 'Y') && (*ans != 'y')) {
		Tcl_Return(interp, "not confirmed", TCL_STATIC);
		return(TCL_OK);
	    }
	    /*
	     * Use sequential access functions since we'll be nuking things.
	     */
	    Lst_Open(tclBreaks);
	    while ((ln = Lst_Next(tclBreaks)) != NILLNODE) {
		bp = (BreakPtr)Lst_Datum(ln);
		tbPtr = (TclBreakPtr)bp->data;

		if (bp->patient == patient)
		{
		    /* if we are clearing non-standard breakpoints don't
		     * refresh as these are usually internal calls in things
		     * like istep and sstep
		     */
		    if ((unsigned int)bp->func != (unsigned int)Break_Set)
		    {
			refresh = 0;
		    }
		    Break_Clear(bp);
		}
	    }
	    Lst_Close(tclBreaks);
	    break;
	}

	/* update the srcwin just in case the break point is in
	 * code current being viewed
	 */

	/* BRK_CLEAR falls through */

    case BRK_ENABLE:
    case BRK_DISABLE:
    {
	void	(*func)(Break brkpt);

	if (clientData == BRK_ENABLE) {
	    func = BreakTclEnable;
	} else if (clientData == BRK_DISABLE) {
	    func = BreakTclDisable;
	} else {
	    func = Break_Clear;
	}

	/* Note - (argc == 2) for BRK_CLEAR is handled above */
	if (argc == 2) {
	    LstNode 	ln;
	    Patient 	patient = curPatient;

	    if (patient == kernel || patient == loader) {
		patient = NullPatient;
	    }

	    for (ln = Lst_First(tclBreaks); ln != NILLNODE; ln = Lst_Succ(ln)){
		bp = (BreakPtr)Lst_Datum(ln);
		tbPtr = (TclBreakPtr)bp->data;

		if (bp->patient == patient) {
		    (*func)((Break)bp);
		}
	    }
	} else {
	    int	    result = TCL_OK;
	    int	    j;
	    char    *hyphen;
	    char    *lastBreakPointPtr = NULL;

	    for (i = argc-1; i >= 2; i--) {
		hyphen = index(argv[i], '-');
		if (hyphen != NULL) {
		    int	    breakPointRangeBound = 0;

		    if (*(hyphen+1) != ' ' && *(hyphen+1) != '\0') {
			/*
			 * Something meaningful follows the hyphen, so assume
			 * it's the end of the range.
			 */
			lastBreakPointPtr = hyphen + 1;
			if (hyphen == argv[i]) {
			    /*
			     * Open-ended range starting from the first bp
			     */
			    breakPointRangeBound = 1;
			}
		    } else if (argv[i][0] == '-') {
			/*
			 * Argument is all hyphen. The start of the range
			 * is the preceding arg.
			 */
			i--;
		    }

		    if (!breakPointRangeBound) {
			breakPointRangeBound = BreakGetNum(argv[i], &cp);
			if (*cp != '\0' && *cp != '-') {
			    Tcl_RetPrintf(interp, "%s: bad range-start",
					  argv[i]);
			    result = TCL_ERROR;
			    continue;
			}
		    }

		    if (breakPointRangeBound == 0) {
			if (i > 1) {
		    	    Tcl_Return(interp,
				       "Bad argument before '-'.",
				       TCL_STATIC);
			    result = TCL_ERROR;
			    continue;
			} else {
			    /*
			     * Assume open-ended at the start
			     */
			    breakPointRangeBound = 1;
			}
		    }

		    if (lastBreakPointPtr == NULL) {
			/*
			 * End of the range not given -- use the highest
			 * existing breakpoint.
			 */
	    		j = BreakFindLastTcl();

			/* if the last break point is less than
			   breakPointRangeBound then they get
			   reversed and the last breakpoint gets
			   deleted. This was bad. This fixes it. */
			if (j < breakPointRangeBound)
			    j = breakPointRangeBound;

		    } else {
		        j  = BreakGetNum(lastBreakPointPtr, &cp);
			if (*cp != '\0') {
			    Tcl_RetPrintf(interp, "%s: bad range-end",
					  lastBreakPointPtr);
			    result = TCL_ERROR;
			    continue;
			}
		    }

		    /* if the ranges are backwards, reverse them */
		    if (j < breakPointRangeBound) {
			int temp;

			temp = breakPointRangeBound;
			breakPointRangeBound = j;
			j = temp;
		    }

		    /* go do the action on the breakpoints */
		    for ( ; j >= breakPointRangeBound; j--) {
			 bp = BreakFindTclByNumber(j);
			 if (bp != (BreakPtr)NULL) {
			     (*func)((Break)bp);
			 }
		    }
		    lastBreakPointPtr = NULL;
		} else if (argv[i][0] == '*') {
		    /*
		     * apply to all the breakpoints
		     */
		    for (j = BreakFindLastTcl(); j >= 1; j--) {
			 bp = BreakFindTclByNumber(j);
			 if (bp != (BreakPtr)NULL) {
			     (*func)((Break)bp);
			 }
		    }
		    lastBreakPointPtr = NULL;
		} else {
		    bp = BreakFindTcl(argv[i]);
		    if (bp == (BreakPtr)NULL) {
		    	Tcl_RetPrintf(interp, "%s: no such breakpoint defined",
				      argv[i]);
	    	        result = TCL_ERROR;
		    } else {
			lastBreakPointPtr = argv[i];
		    	(*func)((Break)bp);
		    }
		}
	    }
	    if (result == TCL_OK && refresh)
	    {
	    /* refresh srcwin in case the breakpoint was in the code currently
	     * being viewed
	     */
	    	Tcl_Eval(interp, "dss", 0, NULL);
	    }
	    return(result);
	}
	break;
    }
    case BRK_ADDRESS:
	bp = (BreakPtr)BreakFindTcl(argv[2]);
	if (bp == (BreakPtr)NULL) {
	    Tcl_Error(interp, "No such breakpoint defined");
	} else if (bp->handle) {
	    Tcl_RetPrintf(interp, "^h%04xh:%04xh",
			  Handle_ID(bp->handle),
			  bp->offset);
	} else {
	    Tcl_RetPrintf(interp, "%xh", bp->offset);
	}
	break;
    case BRK_LIST:
	if (argc == 2) {
	    Message("Num S Address                        Patient    Command/Condition\n");
	    Lst_ForEach(tclBreaks, BreakTclPrint, (LstClientData)NULL);
	} else {
	    /*
	     * Wants the ID's for all breakpoints set at the given address
	     */
	    GeosAddr	addr;

	    if (!Expr_Eval(argv[2], NullFrame, &addr, (Type *)NULL, TRUE))
	    {
		Tcl_Error(interp, "Invalid address");
	    } else {
		BreakPtr	bp;
		TclBreakPtr	tbPtr;
		char    	*cp;

		/*
		 * Initialize to empty
		 */
		Tcl_Return(interp, NULL, TCL_STATIC);

		/*
		 * If anything set at the given address, store in the id
		 * numbers of any breakpoints that are ours.
		 */
		cp = (char *)interp->result;

		for (bp = allBreaks; bp != NULL; bp = bp->next) {
		    if ((bp->handle == addr.handle) &&
			(bp->offset == addr.offset) &&
			BreakIsTcl(bp) &&
			bp->enabled)
		    {
			tbPtr = (TclBreakPtr)bp->data;
			sprintf(cp, "%d ", tbPtr->id);
			cp += strlen(cp);
		    }
		}
	    }
	}
	break;
    case BRK_DEBUG:
	if (argc == 3) {
	    breakDebug = atoi(argv[2]);
	} else {
	    Tcl_RetPrintf(interp, "%s", breakDebug ? "on" : "off");
	}
	break;
    case BRK_ISSET:
    {
	GeosAddr    addr;

	if (!Expr_Eval(argv[2], NullFrame, &addr, (Type *)NULL, TRUE))
	{
	    Tcl_Error(interp, "Invalid address");
	} else {
	    BreakPtr	bp;

	    for (bp = allBreaks; bp != NULL; bp = bp->next) {
		if ((bp->handle == addr.handle) && (bp->offset == addr.offset))
		{
		    break;
		}
	    }
	    Tcl_Return(interp, (bp == NULL) ? "0" : "1", TCL_STATIC);
	}
	break;
    }
    case BRK_COND:
    {
	bp = BreakFindTcl(argv[2]);
	if (bp == (BreakPtr)NULL) {
	    Tcl_RetPrintf(interp, "%s: undefined breakpoint", argv[2]);
	    return(TCL_ERROR);
	}

	tbPtr = (TclBreakPtr)bp->data;

	if (argc == 3 || strcmp(argv[3], "none") == 0) {
	    int	    i;

	    /*
	     * Remove the breakpoint's condition.
	     */
	    if (!bp->isCond) {
		Tcl_RetPrintf(interp, "%s: not conditional", argv[2]);
		return(TCL_ERROR);
	    }
	    BreakUninstallBP(bp);
	    bp->isCond = FALSE;

	    /*
	     * Remove the call to CBreakInterest since breakpoint now
	     * unconditional.
	     */
	    for (i = 0; i < CB_MAX_HANDLES; i++) {
		if (bp->cb.handles[i].handle != NullHandle) {
		    Handle_NoInterest(bp->cb.handles[i].handle,
				      CBreakInterest,
				      (Opaque)bp);
		}
	    }

	    BreakInstallBP(bp);
	} else {
	    if (!bp->handle) {
		Tcl_Error(interp,
			  "Conditional breakpoints must be handle-relative");
	    }

	    /*
	     * Just parse them puppies. CBreakParseCriteria takes care of
	     * clearing out the old one, if any.
	     */
	    if (CBreakParseCriteria(interp, &bp->cb, bp, 3, argv) != TCL_OK) {
		return(TCL_ERROR);
	    }

	    CBreakFinishCriteriaChange(bp);
	}
	break;
    }
    case BRK_CMD:
    {
	bp = BreakFindTcl(argv[2]);
	if (bp == (BreakPtr)NULL) {
	    Tcl_RetPrintf(interp, "%s: undefined breakpoint", argv[2]);
	    return(TCL_ERROR);
	}

	tbPtr = (TclBreakPtr)bp->data;

	if (argc == 3) {
	    /*
	     * Remove command from breakpoint by storing a null byte at the
	     * command's beginning.
	     */
	    tbPtr->command[0] = '\0';
	} else {
	    tbPtr =
		(TclBreakPtr)realloc((malloc_t)tbPtr,
				     sizeof(TclBreakRec)+strlen(argv[3])+1);
	    bp->data = (Opaque)tbPtr;
	    strcpy(tbPtr->command, argv[3]);
	}
	break;
    }
    case BRK_DELCMD:
    {
	bp = BreakFindTcl(argv[2]);
	if (bp == (BreakPtr)NULL) {
	    Tcl_RetPrintf(interp, "%s: undefined breakpoint", argv[2]);
	    return(TCL_ERROR);
	}

	tbPtr = (TclBreakPtr)bp->data;

	if (argc == 3) {
	    /*
	     * Remove command from breakpoint by storing a null byte at the
	     * command's beginning.
	     */
	    if (tbPtr->delcmd != NULL) {
		free(tbPtr->delcmd);
	    }
	    tbPtr->delcmd = NULL;
	} else {
	    tbPtr->delcmd = (char *)malloc_tagged(strlen(argv[3])+1,
						  TAG_BREAK);
	    strcpy(tbPtr->delcmd, argv[3]);
	}
	break;
    }
    } /* switch */
    return(TCL_OK);
}


/***********************************************************************
 *				BreakInterceptCmd
 ***********************************************************************
 * SYNOPSIS:	    A little front-end to decide whether BreakCmd or
 *	    	    Tcl_BreakCmd should be called. If no args are given,
 *	    	    Tcl_BreakCmd is called, else BreakCmd is called via
 *	    	    the function bound to the "brk" command...
 * CALLED BY:	    Tcl interpreter.
 * RETURN:	    whatever the called routine returns
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/19/91		Initial Revision
 *
 ***********************************************************************/
static int
BreakInterceptCmd(ClientData	clientData,
		  Tcl_Interp	*interp,
		  int	    	argc,
		  char	    	**argv)
{
    if (argc == 1) {
	return (Tcl_BreakCmd(clientData, interp, argc, argv));
    } else {
	Tcl_CmdProc *brkCmd;
	int 	    junkFlags;
	Tcl_DelProc *junkDelProc;
	const char  *junkName;

	Tcl_FetchCommand(interp, "brk", &junkName, &brkCmd, &junkFlags,
			 &clientData, &junkDelProc);

	return ((*brkCmd)(clientData, interp, argc, argv));
    }
}

/*-
 *-----------------------------------------------------------------------
 * CBreakCmd --
 *	Function to implement the TCL "cbrk" command.
 *
 * Results:
 *	TCL_OK or TCL_ERROR.
 *
 * Side Effects:
 *	Breakpoints may be set.
 *
 *-----------------------------------------------------------------------
 */
static const CmdSubRec cbrkCmds[] = {
    {"aset", 	BRK_SET,    1, CMD_NOCHECK, "<addr> <condition>*"},
    {"tset", 	BRK_SET,    1, CMD_NOCHECK, "<addr> <condition>*"},
    {"clear", 	BRK_CLEAR,  0, CMD_NOCHECK, "<break>*"},
    {"delete", 	BRK_CLEAR,  0, CMD_NOCHECK, "<break>*"},
    {"enable",	BRK_ENABLE, 0, CMD_NOCHECK, "<break>*"},
    {"disable",	BRK_DISABLE,0, CMD_NOCHECK, "<break>*"},
    {"address",	BRK_ADDRESS,1, 1, "<break>"},
    {"list", 	BRK_LIST,   0, 1, "[<addr>]"},
    {"debug",	BRK_DEBUG,  0, 1, "[<flag>]"},
    {"isset", 	BRK_ISSET,  1, 1, "<addr>"},
    {"cond", 	BRK_COND,   1, CMD_NOCHECK, "<break> <condition>*"},
    {"cmd",  	BRK_CMD,    1, 2, "<break> [<command>]"},
    {"delcmd",	BRK_DELCMD, 1, 2, "<break> [<command>]"},
    {"",	    	BRK_SSET,   0, CMD_NOCHECK, "<addr> <condition>*"},
    {NULL,   	0,  	    0, 0, NULL}
};
DEFCMD(cbrk,CBreak,1,cbrkCmds,top.breakpoint|swat_prog.breakpoint,
"Usage:\n\
    cbrk <addr> <condition>*\n\
    cbrk aset <addr> <condition>*\n\
    cbrk tset <addr> <condition>*\n\
    cbrk clear <break>*\n\
    cbrk delete <break>*\n\
    cbrk enable <break>*\n\
    cbrk disable <break>*\n\
    cbrk address <break>\n\
    cbrk list [<addr>]\n\
    cbrk debug [<flag>]\n\
    cbrk isset <addr>\n\
    cbrk cond <break> <condition>*\n\
    cbrk cmd <break> [<command>]\n\
    cbrk delcmd <break> [<command>]\n\
\n\
Examples:\n\
    \"cbrk WinOpen di=1b80h\"	Stops the machine when execution reaches\n\
				WinOpen with DI set to 1b80h\n\
\n\
Synopsis:\n\
    Allows you to set fast conditional breakpoints in the PC.\n\
\n\
Notes:\n\
    * All these subcommands function the same as for the \"brk\" command,\n\
      with the exception of the \"aset\" and \"tset\" commands, which expect\n\
      the condition for the breakpoint, rather than an associated command.\n\
\n\
    * There are a limited number of these sorts of breakpoints that can\n\
      be set in the PC (currently 8), so they should be used mostly for\n\
      heavily-travelled areas of code (e.g. inner loops, or functions like\n\
      ObjCallMethodTable in the kernel).\n\
\n\
    * For more information on the subcommands and the format of arguments,\n\
      see the documentation for the \"brk\" command.\n\
\n\
See also:\n\
    brk, tbrk\n\
")
{
    return(BreakCmd(clientData, interp, argc, argv));
}


/*********************************************************************
 *			BreakGetMaxBreakPointNumber
 *********************************************************************
 * SYNOPSIS: get the highest used break point number
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	1/13/94		Initial version
 *
 *********************************************************************/
DEFCMD(get-max-bpt-number, BreakGetMaxBreakPointNumber,1,NULL,swat_prog.breakpoint,
"")
{
    Tcl_RetPrintf(interp, "%d", maxBreakPoint);
    return TCL_OK;
}

/******************************************************************************
 *
 *			    INITIALIZATION
 *
 ******************************************************************************/
/*-
 *-----------------------------------------------------------------------
 * Break_Init --
 *	Initialize breakpoint handling.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Maybe.
 *
 *-----------------------------------------------------------------------
 */
void
Break_Init(void)
{
    breakDebug =  FALSE;
    tclBreaks =   Lst_Init(FALSE);
    tempBreaks =  Lst_Init(FALSE);
    allBreaks =   (BreakPtr)NULL;
    savedBreaks = (BreakPtr)NULL;

    (void)Event_Handle(EVENT_STOP,  	0, BreakStopped, NullOpaque),
    (void)Event_Handle(EVENT_STEP,  	0, BreakStopped, NullOpaque),
    (void)Event_Handle(EVENT_CONTINUE, 	0, BreakInstall, NullOpaque),
    (void)Event_Handle(EVENT_FULLSTOP, 	0, BreakUninstall,NullOpaque),
    (void)Event_Handle(EVENT_EXIT,  	0, BreakUninstall, NullOpaque);
    (void)Event_Handle(EVENT_DETACH, 	0, BreakUninstall, NullOpaque);
    (void)Event_Handle(EVENT_START, 	0, BreakStart, NullOpaque);
    (void)Event_Handle(EVENT_RESET, 	0, BreakReset, NullOpaque);
    (void)Event_Handle(EVENT_DESTROY,	0, BreakDestroyed, NullOpaque);
    (void)Event_Handle(EVENT_RELOAD,	0, BreakReload, NullOpaque);

    Cmd_Create(&BreakCmdRec);
    Cmd_Create(&CBreakCmdRec);
    Cmd_Create(&BreakGetMaxBreakPointNumberCmdRec);
    Tcl_CreateCommand(interp, "break", BreakInterceptCmd, 0, (ClientData)NULL,
		      (Tcl_DelProc *)NULL);


    typeCBreakArgs =
	Type_CreatePackedStruct("cb_ip", type_Word,
				"cb_cs", type_Word,
#if REGS_32
				"cb_comps", Type_CreateArray(0, 11, type_Int,
							     type_Byte),
#else
				"cb_comps", Type_CreateArray(0, 6, type_Int,
							     type_Byte),
				"cb_pad", type_Byte,
#endif
				"cb_thread", type_Word,
				"cb_regs", Type_CreateArray(0, REG_NUM_REGS-1,
							    type_Int,
							    type_Word),
				"cb_value", type_Word,
				"cb_off", type_Word,
				"cb_seg", type_Word,
				"cb_xipPage", type_Word,
				0);
    GC_RegisterType(typeCBreakArgs);

    typeChangeCBreakArgs =
	Type_CreatePackedStruct("ccba_num", type_Word,
				"ccba_crit", typeCBreakArgs,
				0);
    GC_RegisterType(typeChangeCBreakArgs);
    Tcl_SetVar(interp, "type-cbreak-args", Type_ToAscii(typeCBreakArgs), TRUE);

    typeSetBreakArgs =
	Type_CreatePackedStruct("sba_ip", type_Word,
				"sba_cs", type_Word,
				"sba_xip", type_Word,
				0);
    GC_RegisterType(typeSetBreakArgs);
}
