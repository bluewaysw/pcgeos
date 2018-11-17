/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Fixup Management
 * FILE:	  fixup.c
 *
 * AUTHOR:  	  Adam de Boor: Jun  6, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Fix_Init    	    Initialize fixups for a segment
 *	Fix_Register	    Register an internal fixup
 *	Fix_Enter   	    Register an external (i.e. for linker) fixup
 *	Fix_Pass2   	    Resolve undefined symbols
 *	Fix_Pass3   	    Optimize
 *	Fix_Pass4   	    Finalize fixups
 *	Fix_Write   	    Write external fixups to object file
 *	Fix_Adjust  	    Adjust fixups in a segment for code insertion
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	6/ 6/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for managing internal and external fixups.
 *
 *	For now, internal fixups are doubly-linked. We'll see how
 *	necessary that is.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: fixup.c,v 1.22 95/02/17 16:26:00 adam Exp $";
#endif lint

#include    "esp.h"
#include    <objfmt.h>

typedef struct _Fixup {
    struct _Fixup   *next;  	/* Next fixup in chain */
    struct _Fixup   *prev;  	/* Previous fixup in chain */
    FixClass	    class;  	/* Class of fixup */
    FixProc 	    *func;  	/* Function to be called */
    int	    	    addr;   	/* Address of beginning of data to be fixed */
    int	    	    size;   	/* Size of data allocated */
    Expr    	    *expr1; 	/* Operand 1 (NULL if none) */
    Expr    	    *expr2; 	/* Operand 2 (NULL if none) */
    Opaque  	    data;   	/* Opaque data to pass to func */
} Fixup;

typedef struct _ExtFix {
    struct _ExtFix  *next;  	/* Next fixup in chain */
    struct _ExtFix  *prev;  	/* Previous fixup in chain */
    int	    	    addr;   	/* Address of fixup */
    int	    	    ref;    	/* Reference address */
    FixDesc 	    desc;   	/* Description of fixup */
} ExtFix;

/*
 * Private data attached to segment
 */
typedef struct {
    Fixup   *head;  	/* Head of internal fixup list */
    ExtFix  *ehead; 	/* Head of external fixup list */
} FixPriv;


/***********************************************************************
 *				Fix_Init
 ***********************************************************************
 * SYNOPSIS:	    Create the initial Fixup node for a segment, the
 *	    	    node serving only as the anchor point for the list
 *	    	    of fixups.
 * CALLED BY:	    Sym_Enter
 * RETURN:	    Nothing
 * SIDE EFFECTS:    sym->u.segment.data->fixPriv is set.
 *
 * STRATEGY:
 *	The allocated fixup is empty, save for having its next and prev
 *	pointers pointing at itself. Its addr is 0, just to make sure...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/12/89		Initial Revision
 *
 ***********************************************************************/
void
Fix_Init(SymbolPtr  	sym)
{
    FixPriv 	*priv;

    priv = (FixPriv *)malloc(sizeof(FixPriv));

    priv->head = (Fixup *)malloc(sizeof(Fixup));
    priv->ehead = (ExtFix *)malloc(sizeof(ExtFix));

    bzero(priv->head, sizeof(Fixup));
    priv->head->next = priv->head->prev = priv->head;

    bzero(priv->ehead, sizeof(ExtFix));
    priv->ehead->next = priv->ehead->prev = priv->ehead;

    sym->u.segment.data->fixPriv = (Opaque)priv;
}

/***********************************************************************
 *				Fix_Register
 ***********************************************************************
 * SYNOPSIS:	    Enter an internal fixup for the current segment
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    A Fixup is allocated and linked in order
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/12/89		Initial Revision
 *
 ***********************************************************************/
void
Fix_Register(FixClass   class,  	/* Class of fixup */
	     FixProc    *func,  	/* Function to be called */
	     int 	addr,   	/* Address of beginning of
					 * data to be fixed */
	     int	size,   	/* Current size of data */
	     FExpr	expr1, 	    	/* Operand 1 */
	     FExpr	expr2, 	    	/* Operand 2 */
	     Opaque	data)	  	/* Arbitrary datum */
{
    SegData 	*seg = curSeg->u.segment.data;
    Fixup   	*fix;
    Fixup   	*new;
    Fixup   	*head;

    /*
     * This comment is old. Check the comment below it... 10/31/94 -jw
     *
     * Fixups are almost always added at the end...we need to find the
     * element after which we want to insert the new one. This loop ends
     * up with fix pointing at the first element whose address is <= that
     * of the new fixup. Note that if there are two fixups at the same
     * address, the one added later will be processed later, thereby
     * overriding the data that were stored by the previous one, as it should.
     * XXX: What about overlapping fixups?
     */

    /*
     * We need to handle overlapping fixups, since the read/write checking
     * code generates a fixup for the entire range of the macro invocation
     * and since there may be fixups within the macro invocation.
     *
     * In addition we need to ensure that if two fixups share the same
     * address, the fixup that is added last is handled first. This is
     * important because the read/write check fixup might nuke other
     * fixups which would normally cause an error (which is what we want).
     *
     * Since the rw-check fixup is added after the macro is invoked (so we
     * know the size of the macro) it must be executed first.
     */

    head = ((FixPriv *)seg->fixPriv)->head;
    for (fix = head->prev; fix != head && fix->addr >= addr; fix = fix->prev) {
	;
    }

    /*
     * Create the fixup record
     */
    new = (Fixup *)malloc(sizeof(Fixup));

    new->class	    = class;
    new->func	    = func;
    new->addr	    = addr;
    new->size	    = size;
    new->expr1      = expr1 ? Expr_Copy(expr1, FALSE) : NULL;
    new->expr2	    = expr2 ? Expr_Copy(expr2, FALSE) : NULL;
    new->data	    = data;

    if (new->expr1) {
	malloc_settag((void *)new->expr1, TAG_FIX_EXPR);
    }
    if (new->expr2) {
	malloc_settag((void *)new->expr2, TAG_FIX_EXPR);
    }

    insque((struct qelem*) new, (struct qelem*) fix);
}


/***********************************************************************
 *				FixDoFixups
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JCW	10/28/94   	Initial Revision
 *
 ***********************************************************************/
typedef struct {
    short   error;
    short   change;
} Pass3Res;

static int
FixDoFixups (SymbolPtr  sym,	    /* Segment to fix up */
	     Opaque     data,	    /* Place to store result */
	     FixClass	fclass,	    /* Which fixups to do */
	     int    	pass)	    /* Which pass we're on */
{
    Fixup   	*fix;	    /* Fixup being performed */
    Fixup	*next;	    /* Next fixup to process */
    Fixup   	*head;	    /* Head fixup record */
    ExtFix  	*efix;	    /* External fixup to adjust */
    ExtFix  	*ehead;	    /* Head of external fixup list */

    int	    	*errorPtr;  /* Our version of data for pass=2*/
    Pass3Res	*resultPtr; /* Our version of 'data' for pass=3 */

    assert((pass==2) || (pass==3));

    errorPtr  = (int *)data;
    resultPtr = (Pass3Res *)data;

    head = ((FixPriv *)sym->u.segment.data->fixPriv)->head;
    ehead = ((FixPriv *)sym->u.segment.data->fixPriv)->ehead;

    efix = ehead->next;
    sym = sym->u.segment.data->first;

    for (fix = head->next; fix != head; fix = next) {
	next = fix->next;

	if (fix->class == fclass) {
	    int	    	addr = fix->addr;
	    FixResult	res;

	    res = (*fix->func)(&addr, fix->size, pass, fix->expr1, fix->expr2,
			       fix->data);

	    if (res != FR_ERROR && (addr - fix->addr) != fix->size) {
		/*
		 * Not an error and the thing changed size -- adjust following
		 * symbols and fixups to match.
		 */
		SymbolPtr   tsym;   /* Symbol being adjusted */
		SymbolPtr   symNext;

		Fixup	    *tfix;  /* Fixup being adjusted */
		Fixup	    *tfixNext;

		ExtFix	    *tefix; /* External fixup being adjusted */
		ExtFix	    *tefixNext;

		int 	    diff;   /* Size difference */

		int 	    fixOldEnd,
		    	    fixNewEnd;


		diff = (addr - fix->addr) - fix->size;

		/*
		 * If the difference is less than zero, then part of the
		 * code is nuked, and this means that fixups which fall
		 * into that area should also be nuked. The range is:
		 *
		 *	    start == (fix->addr + fix->size) + diff
		 *	    end   == (fix->addr + fix->size)
		 */
		fixOldEnd = (fix->addr + fix->size);
		fixNewEnd = (fix->addr + fix->size) + diff;

		/*
		 * If we're on pass3, set the 'change' flag so that we know
		 * to make another pass.
		 */
		if (pass == 3) {
		    resultPtr->change = 1;
		}

		/*
		 * If the new size of the thing is zero, then we've nuked it
		 * entirely.
		 *
		 * This could never happen before, but with the addition
		 * of the read/write checking stuff, it is possible for
		 * an entire macro invocation to vanish, if the macro
		 * was invoked to read/write check something like a constant.
		 *
		 * If it's gone... (when a fixup is resized to zero), we
		 * assume that this means that the fixup is no longer
		 * needed, and it will be removed by the FR_DONE case
		 * in the switch below.
		 */

		/*
		 * If the fixup got smaller, any fixups or symbols which fall
		 * between the new end of the fixup and the old end should
		 * be nuked.
		 *
		 * Overlapping fixups simply didn't exist in esp, but the
		 * read/write checking stuff leaves the possibility that
		 * the fixup associated with the entire read/write check macro
		 * will overlap fixups which might be inside the macro.
		 *
		 * If the macro was invoked in error (eg: on a constant) then
		 * the entire macro is nuked, and we certainly don't want to
		 * keep around any fixups and symbols which fall into the area
		 * which was nuked.
		 *
		 * The actual nuking is done in the update loops below.
		 */

		/*
		 * Find first affected symbol and external fixup (address must
		 * be > than that of fixup).
		 */
		while (sym && sym->u.addrsym.offset <= fix->addr) {
		    sym = sym->u.addrsym.next;
		}

		while (efix != ehead && efix->addr <= fix->addr) {
		    efix = efix->next;
		}

		/*
		 * Adjust all following symbols (can't accumulate,
		 * unfortunately, because you never know when the symbol will
		 * be used next.
		 */
		for (tsym = sym; tsym; tsym = symNext) {
		    symNext = tsym->u.addrsym.next;

		    /*
		     * Symbols are *never* removed. The problem is that
		     * line-number symbols can creep in and give us real
		     * problems...
		     */
		    tsym->u.addrsym.offset += diff;
	    	}


		/*
		 * Adjust all following fixups (no need to search, of course)
		 */
		for (tfix=fix->next; tfix != head; tfix=tfixNext) {
		    tfixNext = tfix->next;

		    /*
		     * It is possible to have multiple fixups at the same
		     * address. We only want to adjust the size for
		     * fixups that fall after the current address associated
		     * with the fixup we're on.
		     */
		    if (tfix->addr > fix->addr) {
			if ((diff < 0) &&
			    ((tfix->addr >= fixNewEnd) &&
			     (tfix->addr <  fixOldEnd))) {
			    /*
			     * Unlink the fixup, setting the 'next' fixup for
			     * the big 'for' loop we're in.
			     */
			    next = tfixNext;
			    remque((struct qelem*) tfix);
			}
			tfix->addr += diff;
		    }
		}

		/*
		 * Adjust all following external fixups
		 */
		for (tefix = efix; tefix != ehead; tefix = tefixNext) {

		    tefixNext = tefix->next;

		    /*
		     * Nuke fixups which aren't valid anymore.
		     */
		    if ((diff < 0) &&
			((tefix->addr >= fixNewEnd) &&
			 (tefix->addr <  fixOldEnd))) {
			/*
			 * Unlink the fixup, but make sure that 'efix' is
			 * updated if that's the element we're nuking.
			 */
			if (tefix == efix) {
			    efix = efix->next;
			}
			remque((struct qelem*) tefix);
			continue;
		    }

		    if (tefix->ref != fix->addr) {
			/*
			 * Not associated with the instruction -- adjust it
			 * and its reference point by the requisite amount
			 */
			tefix->addr += diff;
			tefix->ref += diff;
		    } else {
			/*
			 * Percollate the fixup back through the list until
			 * it is once again in order. Note that we need to set
			 * tefix to the final predecessor of the next fixup or
			 * we'll process anything with which we swap twice.
			 */
			ExtFix	*next = tefix->next;

			while (tefix->addr < tefix->prev->addr) {
			    ExtFix	*pred = tefix->prev->prev;

			    remque((struct qelem*) tefix);
			    insque((struct qelem*) tefix, (struct qelem*) pred);
			}
			tefix = next->prev;
			tefixNext = tefix->next;
		    }
		}

		/*
		 * Adjust size allocated to fixup for next pass
		 */
		fix->size += diff;
	    }

	    /*
	     * Figure out what to do with the fixup now the procedure's
	     * been called.
	     */
	    switch(res) {
		case FR_ERROR:
		    if (pass == 2) {
			*errorPtr = 1;
		    } else {	    /* pass == 3 */
			resultPtr->error = 1;
		    }
		    /*FALLTHRU*/
		default:
		case FR_DONE:
		    /*
		     * Complete or error -- remove the fixup from the queue
		     */
		    remque((struct qelem*) fix);
		    if (fix->expr1) {
			Expr_Free(fix->expr1);
		    }
		    if (fix->expr2) {
			Expr_Free(fix->expr2);
		    }
		    free((void *)fix);
		    break;
		case FR_OPTIM:
		    /*
		     * Promote to pass 3, if on pass 2
		     */
		    if (pass == 2) {
			fix->class = FC_OPTIM;
		    }
		    break;
		case FR_FINAL:
		    /*
		     * Promote to pass 4
		     */
		    fix->class = FC_FINAL;
		    break;
	    }
	}
    }

    return(0);
}


/***********************************************************************
 *				FixPass2
 ***********************************************************************
 * SYNOPSIS:	    Internal callback function to perform all the pass2
 *	    	    actions.
 * CALLED BY:	    Sym_ForEachSegment
 * RETURN:	    0 === don't stop
 * SIDE EFFECTS:    If an error occurs *errorPtr is set true
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 9/89		Initial Revision
 *
 ***********************************************************************/
static int
FixPass2(SymbolPtr  	sym,	    /* Segment to fix up */
	 Opaque	    	data)  	    /* Place to store error */
{
    return(FixDoFixups(sym, data, FC_UNDEF, 2));
}

/***********************************************************************
 *				Fix_Pass2
 ***********************************************************************
 * SYNOPSIS:	    Perform Assembly Pass 2 -- resolution of undefined
 *	    	    symbols.
 * CALLED BY:	    main
 * RETURN:	    1 if successful, 0 if not (number of errors tracked
 *	    	    by Notify)
 * SIDE EFFECTS:    No.
 *
 * STRATEGY:
 *	Run through all known segments, processing all FC_UNDEF fixups
 *	properly.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/12/89		Initial Revision
 *
 ***********************************************************************/
int
Fix_Pass2(void)
{
    int	    error;

    error = 0;
    Sym_ForEachSegment(FixPass2, (Opaque)&error);

    return(!error);
}


/***********************************************************************
 *				FixPass3
 ***********************************************************************
 * SYNOPSIS:	    Internal callback function to perform all the pass3
 *	    	    actions.
 * CALLED BY:	    Sym_ForEachSegment
 * RETURN:	    0 === don't stop
 * SIDE EFFECTS:    If an error occurs resultPtr->error is set true
 *	    	    If a fixup changes size, resultPtr->change is set true
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 9/89		Initial Revision
 *
 ***********************************************************************/
static int
FixPass3(SymbolPtr  	sym,	    /* Segment to fix up */
	 Opaque	    	data)	    /* Place to store result */
{
    return(FixDoFixups(sym, data, FC_OPTIM, 3));
}


/***********************************************************************
 *				Fix_Pass3
 ***********************************************************************
 * SYNOPSIS:	    Perform Assembly Pass 3 -- determination of
 *	    	    optimizations.
 * CALLED BY:	    main
 * RETURN:	    1 if successful, 0 if not (number of errors tracked
 *	    	    by Notify)
 * SIDE EFFECTS:    No.
 *
 * STRATEGY:
 *	Run through all known segments, processing all FC_OPTIM fixups
 *	properly.
 *
 *	To deal with optimizations allowing/disallowing other
 *	optimizations, we pass through all the fixups a number
 *	of times until either (a) nothing changes size, indicating
 *	nothing could be optimized further or (b) we reach the limit
 *	on the number of passes permitted (currently 5). (b) is to
 *	deal with certain pathological cases, allowing human intervention
 *	when the final pass eventually generates an error.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/12/89		Initial Revision
 *
 ***********************************************************************/
int
Fix_Pass3(void)
{
    Pass3Res	result;	    /* Result of fixups. Zeroed before each pass */
    int	    	pass = 5;   /* Times left through the loop */

    while (pass-- > 0) {
	/*
	 * Clear the result out for this pass.
	 */
	result.change = 0;
	result.error = 0;

	/*
	 * Run through all the fixups
	 */
	Sym_ForEachSegment(FixPass3, (Opaque)&result);

	/*
	 * If error or no change, get out of the loop; our job is complete.
	 */
	if (result.error || !result.change) {
	    break;
	}
    }

    return(!result.error);
}


/***********************************************************************
 *				FixPass4
 ***********************************************************************
 * SYNOPSIS:	    Internal callback function to perform all the pass4
 *	    	    actions.
 * CALLED BY:	    Sym_ForEachSegment
 * RETURN:	    Nothing
 * SIDE EFFECTS:    If an error occurs *errorPtr is set true
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/ 9/89		Initial Revision
 *
 ***********************************************************************/
static int
FixPass4(SymbolPtr  	sym,	    /* Segment to fix up */
	 Opaque	    	data)	    /* Place to store error */
{
    Fixup   	*fix;	    /* Fixup being performed */
    Fixup	*next;	    /* Next fixup to process */
    Fixup   	*head;	    /* Head fixup record */
    int	    	*errorPtr;  /* Our version of data */

    errorPtr = (int *)data;

    head = ((FixPriv *)sym->u.segment.data->fixPriv)->head;
    sym = sym->u.segment.data->first;

    for (fix = head->next; fix != head; fix = next) {
	int	    	addr = fix->addr;
	FixResult	res;

	next = fix->next;

	res = (*fix->func)(&addr, fix->size, 4, fix->expr1, fix->expr2,
			   fix->data);

	if (res != FR_ERROR && (addr - fix->addr) != fix->size) {
	    /*
	     * Not an error and the thing changed size -- this is an error.
	     */
	    Expr    *expr;

	    expr = fix->expr1 ? fix->expr1 : fix->expr2;

	    Notify(NOTIFY_ERROR,
		   expr ? expr->file : NullID,
		   expr ? expr->line : 0,
		   "Fixup changed size during final pass");

	    *errorPtr = 1;
	} else if (res == FR_ERROR) {
	    *errorPtr = 1;
	}

	/*
	 * Remove the fixup from the queue -- there are no more passes to be
	 * made.
	 */

	remque((struct qelem*) fix);
	if (fix->expr1) {
	    Expr_Free(fix->expr1);
	}
	if (fix->expr2) {
	    Expr_Free(fix->expr2);
	}
	free((void *)fix);
    }

    return(0);
}

/***********************************************************************
 *				Fix_Pass4
 ***********************************************************************
 * SYNOPSIS:	    Perform Assembly Pass 4 -- final storage of data.
 * CALLED BY:	    main
 * RETURN:	    1 if successful, 0 if not (number of errors tracked
 *	    	    by Notify)
 * SIDE EFFECTS:    No.
 *
 * STRATEGY:
 *	Run through all known segments, processing all fixups properly.
 *	The only fixups that should be left are FC_FINAL ones.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/12/89		Initial Revision
 *
 ***********************************************************************/
int
Fix_Pass4(void)
{
    int	    error;

    error = 0;

    Sym_ForEachSegment(FixPass4, (Opaque)&error);

    return(!error);
}


/***********************************************************************
 *				Fix_Adjust
 ***********************************************************************
 * SYNOPSIS:	    Adjust fixups for the segment
 * CALLED BY:	    LMem module
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Well...guess
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/10/89		Initial Revision
 *
 ***********************************************************************/
void
Fix_Adjust(SymbolPtr	sym,	    /* Segment needing adjustment */
	   int	    	addr,	    /* First affected address */
	   int	    	diff)	    /* Amount by which to adjust the fixups */
{
    Fixup   	*fix, *head;
    ExtFix  	*efix, *ehead;

    head = ((FixPriv *)sym->u.segment.data->fixPriv)->head;
    ehead = ((FixPriv *)sym->u.segment.data->fixPriv)->ehead;

    /*
     * Adjust internal fixups first. Need to find the first fixup at or
     * after the given address, then adjust that one and all succeeding
     * fixups by the indicated amount.
     */
    for (fix = head->next; fix != head && fix->addr < addr; fix = fix->next) {
	;
    }

    while (fix != head) {
	fix->addr += diff;
	fix = fix->next;
    }

    /*
     * Ditto for external fixups.
     */
    for (efix=ehead->next; efix!=ehead && efix->addr < addr; efix=efix->next) {
	;
    }

    while (efix != ehead) {
	efix->addr += diff;
	efix->ref += diff;
	efix = efix->next;
    }
}


/***********************************************************************
 *				Fix_EnterSegment
 ***********************************************************************
 * SYNOPSIS:	    Register an external fixup for a specific segment
 * CALLED BY:	    Code and Data modules.
 * RETURN:	    Nothing
 * SIDE EFFECTS:    An ExtFix record is added to the chain.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/10/89		Initial Revision
 *
 ***********************************************************************/
void
Fix_EnterSegment(SymbolPtr  seg,
		 FExprResult result,
		 int	    addr,
		 int	    ref)
{
    ExtFix  	*efix;
    ExtFix  	*enew;
    ExtFix   	*ehead;

    /*
     * Fixups are almost always added at the end...we need to find the
     * element after which we want to insert the new one. This loop ends
     * up with fix pointing at the first element whose address is <= that
     * of the new fixup. Note that if there are two fixups at the same
     * address, the one added later will be processed later, thereby
     * overriding the data that were stored by the previous one, as it should.
     * XXX: What about overlapping fixups (not at same addr)?
     */

    ehead = ((FixPriv *)seg->u.segment.data->fixPriv)->ehead;
    for (efix=ehead->prev; efix!=ehead && efix->addr > addr; efix=efix->prev) {
	;
    }

    /*
     * Create the fixup record
     */
    enew = (ExtFix *)malloc(sizeof(ExtFix));

    enew->addr = addr;
    enew->ref = ref;
    enew->desc = result->rel;

    insque((struct qelem*) enew, (struct qelem*) efix);
}


/***********************************************************************
 *				Fix_OutputRel
 ***********************************************************************
 * SYNOPSIS:	    Prepare an external relocation for writing
 * CALLED BY:	    Fix_Write, Sym_ProcessSegments
 * RETURN:	    1 if the relocation should be written
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/20/90		Initial Revision
 *
 ***********************************************************************/
int
Fix_OutputRel(SymbolPtr	seg,	    /* Segment in which relocation is
				     * occurring */
	      int   	addr,	    /* Address of the relocation */
	      FixDesc	*desc,	    /* Relocation descriptor */
	      Opaque 	dest)	    /* Destination */
{
    ObjRel  	*rel = (ObjRel *)dest;

    switch(desc->type) {
	case FIX_LOW_OFFSET:
	case FIX_HIGH_OFFSET:
	    if (desc->sym->type == SYM_SEGMENT) {
		/*
		 * Looking for major or minor protocol of a library/driver.
		 * Set the symbol to 0 to tell the linker this.
		 */
		rel->symOff = rel->symBlock = 0;
		break;
	    }
	case FIX_OFFSET:
	    if ((desc->sym->flags & SYM_NOWRITE) ||
		(desc->sym->type == SYM_LOCALLABEL) ||
		(desc->sym->type == SYM_PROFILE_MARK) ||
		(desc->pcrel &&
		 !(desc->sym->flags & SYM_UNDEF) &&
		 (desc->sym->segment == seg)) ||
		(desc->frame->type == SYM_SEGMENT &&
		 desc->frame->u.segment.data->comb == SEG_ABSOLUTE))
	    {
		/*
		 * This is a fixup for a local symbol or a pc-relative fixup to
		 * a defined symbol, or a fixup to a symbol in an absolute
		 * segment. If it's local, we need to store the final
		 * offset of the symbol involved and set the rel->sym* fields
		 * to 0 to indicate that the relocation requires only the
		 * relocation factor of the segment chunk.
		 *
		 * If a pc-relative fixup to a defined symbol, we also need to
		 * store the offset, subtracting off the offset of the first
		 * byte after the relocation, but we don't actually output a
		 * relocation as there's nothing more the linker needs to do.
		 *
		 * If a fixup to a symbol in an absolute segment, we store
		 * the offset, but don't actually output a relocation, as
		 * there's nothing more the linker needs to do.
		 *
		 * XXX: Doesn't handle byte-sized pc-relative relocations, but
		 * we don't enter any of those, so it's ok for now.
		 *
		 * Note: the destination must lie in the same segment for us to
		 * handle pcrelatives correctly. A destination can be
		 * pc-relative yet lie in a different segment if the
		 * destination and the source are in the same group.
		 */
		switch(desc->size) {
		    case FIX_SIZE_BYTE:
		    {
			byte	b;

			Table_Fetch(seg->u.segment.code, 1, (void *)&b, addr);
			if (desc->type == FIX_HIGH_OFFSET) {
			    b += desc->sym->u.addrsym.offset>>8;
			} else {
			    b += desc->sym->u.addrsym.offset;
			}
			Table_Store(seg->u.segment.code, 1, (void *)&b, addr);
			break;
		    }
		    case FIX_SIZE_WORD:
		    case FIX_SIZE_DWORD:
		    {
			/*
			 * Word and dword are lumped together since
			 * an offset can only be a word...
			 */
			byte	b[2];
			word	w;

			Table_Fetch(seg->u.segment.code, 2, (void *)b, addr);

			w = b[0] | (b[1] << 8);
			w += desc->sym->u.addrsym.offset;
			if (desc->pcrel) {
			    w -= addr + (desc->size == FIX_SIZE_WORD? 2 : 4);
			}
			b[0] = w;
			b[1] = w >> 8;

			Table_Store(seg->u.segment.code, 2, (void *)b, addr);

			break;
		    }
		}
		/*
		 * If the relocation is PC-relative or absolute, it
		 * is complete at this point, so advance to the next external
		 * fixup and continue with the loop without storing anything
		 * away.
		 */
		if (desc->pcrel ||
		    (desc->frame->type == SYM_SEGMENT &&
		     desc->frame->u.segment.data->comb == SEG_ABSOLUTE))
		{
		    return(0);
		}
		rel->symOff = rel->symBlock = 0;
		break;
	    }
	    /*FALLTHRU*/
	case FIX_PROTOMINOR:
	case FIX_CALL:
	    if (desc->frame->type == SYM_SEGMENT &&
		desc->frame->u.segment.data->comb == SEG_ABSOLUTE)
	    {
		/*
		 * More complex case of the above, as we have to add in the
		 * offset of the symbol and store the segment value away
		 * as well. We still don't send anything to the linker, of
		 * course...
		 */
		byte	b[4];
		word	w;

		Table_Fetch(seg->u.segment.code, 2, (void *)b, addr);

		w = b[0] | (b[1] << 8);
		w += desc->sym->u.addrsym.offset;
		if (desc->pcrel) {
		    /* Just for kicks... */
		    w -= addr + (desc->size == FIX_SIZE_WORD? 2 : 4);
		}
		b[0] = w;
		b[1] = w >> 8;
		b[2] = desc->frame->u.segment.data->segment;
		b[3] = desc->frame->u.segment.data->segment >> 8;

		Table_Store(seg->u.segment.code, 4, (void *)b, addr);
		return (0);
	    }
	    /*FALLTHRU*/
	case FIX_ENTRY:
	case FIX_METHCALL:
	case FIX_SUPERCALL:
	    /*
	     * Target must have been put in the file and converted -- use saved
	     * offset and block for the exported fixup.
	     */
	    assert(!(desc->sym->flags & SYM_NOWRITE));
	    rel->symOff     = desc->sym->u.objsym.offset;
	    rel->symBlock   = desc->sym->u.objsym.block;
	    break;
	case FIX_SEGMENT:
	case FIX_HANDLE:
	case FIX_RESID:
	    if (desc->frame->type == SYM_SEGMENT &&
		desc->frame->u.segment.data->comb == SEG_ABSOLUTE)
	    {
		/*
		 * Just store the segment value away and don't generate
		 * a relocation.
		 */
		byte	b[2];

		b[0] = desc->frame->u.segment.data->segment;
		b[1] = desc->frame->u.segment.data->segment >> 8;
		Table_Store(seg->u.segment.code, 2, (void *)b, addr);
		return (0);
	    } else if ((desc->sym->type == SYM_SEGMENT) ||
		(desc->sym->type == SYM_GROUP) ||
		(desc->sym->flags & SYM_NOWRITE) ||
		(desc->sym->type == SYM_LOCALLABEL))
	    {
		/*
		 * These things use the frame, only -- set the symbol
		 * pointer to 0 to indicate this
		 */
		rel->symOff = rel->symBlock = 0;
	    } else {
		/*
		 * If it's something that has made it to the symbol
		 * table but only in the global segment, we want to
		 * provide it so the linker can find its actual
		 * segment.
		 */
		rel->symOff = desc->sym->u.objsym.offset;
		rel->symBlock = desc->sym->u.objsym.block;
	    }
	    break;
	default:
	    assert(0);
    }

    /*
     * Set up the constant pieces of the relocation. Note how
     * this depends on the 'type' values for the internal and
     * external versions matching....
     */
    rel->offset	    = addr;
    if (desc->frame->type == SYM_SEGMENT) {
	rel->frame  = desc->frame->u.segment.data->offset;
    } else {
	rel->frame  = desc->frame->u.group.offset;
    }
    rel->type 	    = desc->type;
    rel->size 	    = desc->size;
    rel->pcrel 	    = desc->pcrel;
    rel->fixed	    = desc->fixed;

    return(1);
}


/***********************************************************************
 *				Fix_Write
 ***********************************************************************
 * SYNOPSIS:	    Write the external fixups for a segment to the
 *	    	    output file.
 * CALLED BY:	    DoOutput
 * RETURN:	    Block handle of first block in chain
 * SIDE EFFECTS:    Any fixups for CHUNK symbols are fixed up
 *
 * STRATEGY:
 *	We place the fixups in blocks no bigger than 8K. Since each ObjRel
 *	is 12 bytes long, and we need two bytes at the beginning of the
 *	block for the "next" pointer of the chain, this gives us 682
 *	relocations per block.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/10/89		Initial Revision
 *
 ***********************************************************************/
#define FIX_MAX	    ((8192-2)/sizeof(ObjRel))
VMBlockHandle
Fix_Write(SymbolPtr sym)    	/* Segment whose fixups want writing */
{
    VMBlockHandle   block;  	/* Current block */
    VMBlockHandle   first;  	/* Start of the chain */
    VMBlockHandle   prev;   	/* Previous block (for linking) */
    ObjRel  	    *rel;   	/* Current external relocation */
    int	    	    i;	    	/* Number of relocations in block */
    ExtFix  	    *ehead; 	/* Head of whole list */
    ExtFix  	    *efix;  	/* Current/last fixup of block */
    ExtFix  	    *estart;	/* First fixup for block */
    ObjRelHeader    *orh;  	/* Base of current block */
    ObjRelHeader    *porh; 	/* Base of previous block */

    ehead = ((FixPriv *)sym->u.segment.data->fixPriv)->ehead;

    prev = first = 0;
    porh = (ObjRelHeader *)NULL;

    estart = ehead->next;

    while (estart != ehead) {
	/*
	 * Point efix either FIX_MAX fixes down the line or at the end of
	 * the chain. This gives us a termination condition for the next
	 * loop when we actually convert fixups...
	 */
	for (i=0, efix=estart; efix != ehead && i < FIX_MAX; efix=efix->next){
	    if ((efix->desc.frame->type != SYM_SEGMENT ||
		 efix->desc.frame->u.segment.data->comb != SEG_ABSOLUTE) &&
		(!efix->desc.pcrel || (efix->desc.sym->flags & SYM_UNDEF) ||
		 (efix->desc.sym->segment != sym)))
	    {
		/*
		 * PC-relative fixups to defined symbols, or fixups to symbols
		 * in absolute segments, don't make it to the object file...
		 */
		i++;
	    }
	}

	/*
	 * Allocate a(nother) block to hold the number of relocations we've
	 * determined should go in this block, plus room for the link
	 * to the next block.
	 * The block has our distinguishing ID so it can be byte-swapped
	 * by the linker, if necessary.
	 */
	block = VMAlloc(output, i * sizeof(ObjRel) + sizeof(ObjRelHeader),
			OID_REL_BLOCK);

	if (prev == 0) {
	    /*
	     * No previous -- this one must be first (really? Gosh!)
	     */
	    first = block;
	} else {
	    /*
	     * Link new block into chain, then release the previous block,
	     * as we have no further need of it.
	     */
	    porh->next = block;
	    VMUnlockDirty(output, prev);
	}

	/*
	 * Lock down the block for our use, then null-terminate the chain
	 * and point rel at its first available space...
	 */
	orh = (ObjRelHeader *)VMLock(output, block, (MemHandle *)NULL);
	orh->next = 0;
	orh->num = i;
	rel = (ObjRel *)(orh + 1);

	/*
	 * Process all the relocations we've decided should go in this block
	 */
	while (estart != efix) {
	    if (Fix_OutputRel(sym, estart->addr, &estart->desc, (Opaque)rel)) {
		/*
		 * Another relocation stored...
		 */
		rel++;
	    }
	    estart = estart->next;
	}

	/*
	 * Track this block for linking the next...
	 */
	prev = block;
	porh = orh;
    }

    /*
     * Unlock the previous block, if any, now we're done.
     */
    if (prev != 0) {
	VMUnlock(output, prev);
    }

    return(first);
}


/***********************************************************************
 *				Fix_Find
 ***********************************************************************
 * SYNOPSIS:	    Check to see if a fixup exists
 * CALLED BY:	    Utility
 * RETURN:	    TRUE if the fixup exists, FALSE otherwise
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JCW	10/13/94   	Initial Revision
 *
 ***********************************************************************/
int
Fix_Find (FixProc   *func,	/* Callback of the fixup */
	  int	     addr,	/* Address of the fixup */
	  int	     size)	/* Size of the fixup */
{
    SegData 	*seg = curSeg->u.segment.data;
    Fixup   	*fix;
    Fixup   	*head;

    head = ((FixPriv *)seg->fixPriv)->head;

    for (fix = head->prev; fix != head && fix->addr >= addr; fix = fix->prev) {
	if (fix->addr == addr) {
	    if ((fix->func == func) && (fix->size == size)) {
		return(TRUE);
	    }
	}
    }

    return(FALSE);

}	/* End of Fix_Find.	*/
