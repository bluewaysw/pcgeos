/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Assertion Handling
 * FILE:	  assert.c
 *
 * AUTHOR:  	  Adam de Boor: Aug 27, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Assert_Enter	    Enter an expression to be evaluated
 *	Assert_DoAll	    Handle all the extant assertions.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/27/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Module to handle assertions. This takes the place of the second
 *	source pass in MASM.
 *
 ***********************************************************************/

#include    "esp.h"

#define ASSERTS_PER_SEG	32

typedef struct _ARec {
    Expr    	*expr;	    /* Expression to evaluate */
    char    	*msg;	    /* Message to give if failed */
} ARec;

typedef struct _Assert {
    ARec    	    exprs[ASSERTS_PER_SEG];
    ARec    	    *ptr;   	/* Next available slot */
    struct _Assert  *next;
} Assertions;


static Assertions    *head;

		

/***********************************************************************
 *				AssertProcessResult
 ***********************************************************************
 * SYNOPSIS:	    Process the result of evaluating an assertion
 * CALLED BY:	    Assert_DoAll, Assert_Enter
 * RETURN:	    0 if assertion failed
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/8/91		Initial Revision
 *
 ***********************************************************************/
static int
AssertProcessResult(Expr    	*expr,
		    ExprResult	*res,
		    char    	*msg)
{
    if (res->type != EXPR_TYPE_CONST) {
	Notify(NOTIFY_ERROR, expr->file, expr->line,
	       "Assertion yields non-numeric result");
	return (0);
    } else if (res->data.number == 0) {
	if (msg) {
	    /*
	     * If message given, use it.
	     */
	    Notify(NOTIFY_ERROR, expr->file, expr->line, msg);
	    free(msg);
	} else {
	    /*
	     * Else just give general "Failed assertion" message.
	     * Perhaps we should attempt to print out the
	     * expression?
	     */
	    Notify(NOTIFY_ERROR, expr->file, expr->line, "Failed assertion");
	}
	return (0);
    } else if (msg) {
	free(msg);
    }
    return(1);
}


/***********************************************************************
 *				Assert_Enter
 ***********************************************************************
 * SYNOPSIS:	    Enter another assertion to be checked once all
 *	    	    the source has been read.
 * CALLED BY:	    yyparse.
 * RETURN:	    Nothing
 * SIDE EFFECTS:    A new assertion is entered.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/27/89		Initial Revision
 *
 ***********************************************************************/
void
Assert_Enter(Expr   *expr,  /* Assertion to be checked. Ownership of same
			     * is transfered to this module, so it should
			     * have been copied before being passed */
	     char   *msg)   /* Message to give if expression evaluates false.
			     * If null, standard "Assertion failed" is given.
			     * As for "expr", ownership is transfered to this
			     * module */
{
    ExprResult	res;
    byte    	status;

    /*
     * First see if we can evaluate the thing now. If we can, there's no
     * point in saving it for later, wot? Also, if there's an error in the
     * expression, we might as well catch it now, too.
     * 11/7/91: if the expression involves .TYPE, always delay it until
     * the second pass, as it will almost always be defined for the
     * first pass, but will yield the wrong result.
     */
    if (Expr_InvolvesOp(expr, EXPR_DOTTYPE)) {
	status = 0;
    } else if (!Expr_Eval(expr, &res, EXPR_NOREF, &status)) {
	Notify(NOTIFY_ERROR, expr->file, expr->line, (char *)res.type);
	free(msg);
	return;
    }
    
    if ((status & EXPR_STAT_DELAY) || !(status & EXPR_STAT_DEFINED)) {
	/*
	 * Expression not resolvable yet, so save it and its message.
	 */
        if (head == NULL || (head->ptr == &head->exprs[ASSERTS_PER_SEG])) {
	    Assertions  *a;
	    
	    a = (Assertions *)malloc(sizeof(Assertions));
	    a->ptr = a->exprs;
	    a->next = head;
	    head = a;
	}
	
	head->ptr->expr = Expr_Copy(expr, TRUE);
	head->ptr->msg = msg;
	head->ptr += 1;
    } else {
	(void)AssertProcessResult(expr, &res, msg);
    }
}


/***********************************************************************
 *				Assert_DoAll
 ***********************************************************************
 * SYNOPSIS:	    Check all assertions made during the course of
 *	    	    the assembly.
 * CALLED BY:	    main
 * RETURN:	    0 if an error occurred. All assertions are evaluated.
 * SIDE EFFECTS:    The assertions list is deleted.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/27/89		Initial Revision
 *
 ***********************************************************************/
int
Assert_DoAll(void)
{
    ExprResult	    res;    	/* Result of evaluating the expression */
    byte    	    status; 	/* Status byte from Expr_Eval (UNUSED) */
    Assertions	    *a;	    	/* Current assertion segment */
    ARec    	    *ePtr; 	/* Address of next expr to evaluate */
    int	    	    retval = 1;	/* Assume everything's groovy */

    for (a = head; a != NULL; a = head) {
	for (ePtr = a->exprs; ePtr < a->ptr; ePtr++) {
	    /*
	     * We lie about the symbols being in a final state b/c I can't
	     * think of a case where you'd use assert to test the difference
	     * of two symbols where the actual value would make a difference.
	     * The only case that would matter is if they are equal, and if
	     * they're not now, they never will be (code doesn't optimize to
	     * nothing).
	     */
	    if (!Expr_Eval(ePtr->expr,
			   &res,
			   EXPR_NOUNDEF|EXPR_FINALIZE|EXPR_NOREF,
			   &status))
	    {
		Notify(NOTIFY_ERROR, ePtr->expr->file, ePtr->expr->line,
		       (char *)res.type);
		retval = 0;
	    } else {
		retval = (AssertProcessResult(ePtr->expr, &res, ePtr->msg) 
			  && retval);
	    }
	}
	head = a->next;
	free((char *)a);
    }

    return(retval);
}
