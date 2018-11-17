/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Expression Parsing
 * FILE:	  expr.c
 *
 * AUTHOR:  	  Adam de Boor: Apr 10, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Expr_Copy  	    Duplicate an expression
 *	Expr_Eval   	    Evaluate an expression
 *	Expr_NextPart	    Extract next portion of an expression
 *	Expr_Status 	    Check elements of an expression result.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/10/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for parsing expressions.
 *
 *	XXX: Eventually, this will have to support external constants.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: expr.c,v 3.49 95/02/17 16:25:49 adam Exp $";
#endif lint

#include    "esp.h"
#include    "expr.h"
#include    "type.h"
#include    "object.h"


/*
 * Internal flags (allocated from other end of the word...)
 */
#define EXPR_FINAL_CONVERT  0x8000  /* If passed to ExprConvertSym, indicates
				     * it's the final conversion and structure
				     * fields should be converted as constants
				     */

/*
 * protoMinorRelocationSeg is the segment where we put relocations to
 * protominor symbols
 */
Symbol          *protoMinorRelocationSeg=NULL;

/*
 * OVERRIDE produces the correct segment-override opcode given the segment
 * register to use.
 */
#define OVERRIDE(reg)	(((reg) < REG_FS) ? (0x26 | ((reg) << MR_REG_SHIFT)) : \
					  (0x60 + (reg)))

/*
 * OVERRIDE_TO_SEGREG produces the correct segment register value given the
 * segment-override opcode.
 */
#define OVERRIDE_TO_SEGREG(reg)	(((reg) >= 0x64) ? ((reg) - 0x60) : \
				 (((reg) & MR_SEGREG_MASK) >> MR_REG_SHIFT))

/*
 * Internal form of EXPR_IS_SEGREG as I don't feel comfortable in setting the
 * type to Type_Int(2) when EXPR_SEGREG is encountered -- ardeb 6/16/92
 */
#define IS_SEGREG(resP) (((resP)->type == NULL) && \
			 ((resP)->data.ea.disp == 0) && \
			 ((resP)->data.ea.modrm == MR_SEGREG) && \
			 ((resP)->data.ea.override != 0) && \
			 ((resP)->rel.sym == NULL))
/*
 * Flag to say the override in the result is implicit, based on the segment
 * in which the symbol from which the result was derived was found.
 */
#define EXPR_IMPLICIT_OVERRIDE	0x80

/*
 * Internal types for intermediate results. The ordering here is important.
 * There are a couple things that rely on it (q.v. the CAST operator).
 *
 *	SEGSYM	    points to the element of the expression from which the
 *	    	    segment came. The op field of the element has been
 *	    	    changed to indicate to what register the segment is
 *	    	    bound (not as important now that segments are stored with
 *	    	    the expression...)
 *	SYM 	    any type of symbol other than those expressing a data
 *	    	    type.
 *	TYPE	    a type description. Can be converted to a constant
 *	    	    by ExprConvertSym.
 *	NAN 	    an undefined symbol was discovered. The result of any
 *		    operation on this should always be NAN, with the sole
 *		    exception of the .TYPE operator.
 *
 */
#define EXPR_TYPE_SEGSYM    ((TypePtr)4)
#define EXPR_TYPE_SYM	    ((TypePtr)5)
#define EXPR_TYPE_TYPE	    ((TypePtr)6)
#define EXPR_TYPE_NAN	    ((TypePtr)7)
#define EXPR_TYPE_MAX_SPECIAL ((TypePtr)7)

#define ExprSymOffset(sym) (((sym)->type == SYM_CHUNK) ? \
			    (sym)->u.chunk.handle : \
			    (sym)->u.addrsym.offset)

/*
 * Place to store messages about undefined symbols. Must be out here,
 * rather than a local variable, since we can't return a dynamic error
 * message (caller wouldn't know to free it), and we can't return one on
 * the stack as it'll get overwritten in successive calls...
 */
static char    	undefMsg[256];
static char 	*undefPtr;
static int  	undefErr;
static int  	undefFull;
#define UNDEF_FINISH_STR    " undefined"
#define UNDEF_FINISH_STRLEN 10
#define UNDEF_TOO_MANY_STR  ", ..."
#define UNDEF_TOO_MANY_STRLEN 5

#define UNDEF_END_PTR	(&undefMsg[sizeof(undefMsg)-UNDEF_TOO_MANY_STRLEN-UNDEF_FINISH_STRLEN])

/*
 * Forward declarations
 */
void    ExprOutputProtoMinorRelocation(Symbol    *protoSym);


/***********************************************************************
 *				ExprUndefInit
 ***********************************************************************
 * SYNOPSIS:	    Initialize record of undefined symbols/identifiers
 *	    	    for this expression.
 * CALLED BY:	    Expr_Eval
 * RETURN:	    nothing
 * SIDE EFFECTS:    undefErr is set to 0
 *	    	    undefMsg set to ""
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/16/91	Initial Revision
 *
 ***********************************************************************/
static void
ExprUndefInit(void)
{
    undefMsg[0] = '\0';
    undefPtr = undefMsg;
    undefFull = undefErr = 0;
}


/***********************************************************************
 *				ExprUndefAdd
 ***********************************************************************
 * SYNOPSIS:	    Add another ID to the list of undefined symbols/IDs
 *	    	    for this expression.
 * CALLED BY:	    INTERNAL
 * RETURN:	    nothing
 * SIDE EFFECTS:    the string corresponding to the ID is tacked onto
 *	    	    the end of undefMsg.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/16/91	Initial Revision
 *
 ***********************************************************************/
static void
ExprUndefAdd(ID	    id)
{
    if (!undefFull) {
	char    *name = ST_Lock(output, id);
	int	    namelen = strlen(name);

	if (undefPtr + (undefErr ? 2 : 0) + namelen + 1 > UNDEF_END_PTR) {
	    undefFull = 1;
	    strcpy(undefPtr, UNDEF_TOO_MANY_STR);
	    undefPtr += UNDEF_TOO_MANY_STRLEN;
	} else {
	    if (undefErr) {
		strcpy(undefPtr, ", ");
		undefPtr += strlen(undefPtr);
	    }
	    undefErr = 1;
	    strcpy(undefPtr, name);
	    undefPtr += namelen;
	}
	ST_Unlock(output, id);
    }
}


/***********************************************************************
 *				ExprUndefFinish
 ***********************************************************************
 * SYNOPSIS:	    Finish off a message about the undefined symbols/IDs
 *	    	    in this expression.
 * CALLED BY:	    Expr_Eval
 * RETURN:	    the error message (static storage)
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/16/91	Initial Revision
 *
 ***********************************************************************/
static char *
ExprUndefFinish(void)
{
    strcpy (undefPtr, UNDEF_FINISH_STR);
    return(undefMsg);
}




/***********************************************************************
 *				Expr_Copy
 ***********************************************************************
 * SYNOPSIS:	    Copy an expression into more-permanent storage
 * CALLED BY:	    yyparse
 * RETURN:	    A new Expr *
 * SIDE EFFECTS:    If elements usurped, the elts field of the passed
 *	    	    Expr will be zeroed.
 *
 * STRATEGY:	    If "usurp" is true and elts points into the heap,
 *	    	    	just allocate a new Expr and steal the elts
 *	    	    	from the passed Expr, reseting it to 0 there.
 *	    	    Else, allocate a new Expr and elts array, copying
 *	    	    	the old elts into the new.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/10/89		Initial Revision
 *
 ***********************************************************************/
Expr *
Expr_Copy(Expr	*expr,
	  int	usurp)
{
    Expr    	*newExpr;   /* New expression */

    if (usurp && (malloc_size((char*)expr->elts) != 0)) {
	/*
	 * We're allowed to usurp the elements in the old expression --
	 * just allocate a new Expr structure and steal the old elements,
	 * resetting the old expression to have none.
	 */
	newExpr = (Expr *)malloc(sizeof(Expr));
	*newExpr = *expr;
	expr->numElts = 0;
	expr->elts = (ExprElt *)0;
    } else {
	/*
	 * Allocate a single record with the Expr at the front and the
	 * new elements following it.
	 */
	newExpr = (Expr *)malloc(sizeof(Expr) + expr->numElts*sizeof(ExprElt));
	*newExpr = *expr;
	newExpr->elts = (ExprElt *)(newExpr+1);
	bcopy(expr->elts, newExpr->elts, expr->numElts * sizeof(ExprElt));
    }

    return(newExpr);
}


/***********************************************************************
 *				Expr_Free
 ***********************************************************************
 * SYNOPSIS:	    Free up all memory used by a stored expression
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    See above
 *
 * STRATEGY:
 *	If elts doesn't point immediately following the Expr record
 *	itself, the elements were usurped from somewhere else and must
 *	be freed. This, of course, relies on proper usage of Expr_Copy.
 *	E.g. no one calls Expr_Copy with usurp TRUE for something
 *	that was obtained via Expr_NextPart.
 *
 *	If elts does point immediately following the Expr record, the
 *	two were allocated in the same block and can both be disposed
 *	of by freeing the Expr record.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/26/89		Initial Revision
 *
 ***********************************************************************/
void
Expr_Free(Expr	*expr)
{
    if (expr->elts != (ExprElt *)(expr+1)) {
	free((char *)expr->elts);
    }
    free((char *)expr);
}

/***********************************************************************
 *				Expr_NextPart
 ***********************************************************************
 * SYNOPSIS:	    Extract the next part from an expression.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    dest set to point to the next portion. dest->numElts
 *	    	    is 0  (assuming expression valid) if no next part.
 * SIDE EFFECTS:    Any EXPR_IDENT operators that can be converted to
 *	    	    EXPR_SYMOP operators are converted before the
 *	    	    portion is returned.
 *
 * STRATEGY:	    Skip forward from the end of dest->elts (which
 *	    	    points into the same array as src->elts) to the
 *	    	    next EXPR_COMMA or the end of src.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/10/89		Initial Revision
 *
 ***********************************************************************/
void
Expr_NextPart(Expr  	*src,
	      Expr  	*dest,
	      int   	resolveInherits)
{
    ExprElt 	*elt;
    int	    	n;
    SymbolPtr	prevProc = curProc;

    if (dest->elts < src->elts || dest->elts > src->elts+src->numElts) {
	/*
	 * Doesn't point into the source expression -- start from the beginning
	 */
	*dest = *src;
	n = src->numElts;
    } else {
	/*
	 * Skip over the comma operator and its following line number.
	 */
	dest->elts += dest->numElts+2;
	n = src->numElts - (dest->elts - src->elts);
    }

    /*
     * Assume no identifiers will be left.
     */
    dest->idents = 0;

    curProc = src->curProc;

    elt = dest->elts;
    while (n > 0) {
	switch(elt->op) {
	    case EXPR_DWORDREG:
	    case EXPR_WORDREG:
	    case EXPR_BYTEREG:
	    case EXPR_SEGREG:
	    case EXPR_INDREG:
	    case EXPR_SYMOP:
	    case EXPR_CONST:
	    case EXPR_TYPE:
	    case EXPR_FLOATSTACK:
		elt += 2;
		n -= 2;
		break;
	    case EXPR_COMMA:
		/*
		 * Set the line number of the destination to be that of its
		 * terminating comma operator. The effect, for a table using
		 * flexiCommas, is to step through the table, giving the
		 * line number of the end of each element, rather than
		 * its beginning. We don't do this for the very first one,
		 * however, as I prefer to have the starting line in error
		 * messages in the simple case.
		 */
		if (dest->elts != src->elts) {
		    dest->line = elt[1].value;
		}
		goto done;
	    case EXPR_IDENT:
	    {
		Symbol	*sym;

		sym = Sym_Find(elt[1].ident, SYM_ANY, resolveInherits);
		if (sym == NULL) {
		    dest->idents = 1;
		    elt += 2;
		    n -= 2;
		} else {
		    /*
		     * Wheeeee. Resolved the identifier to a symbol. Replace
		     * the EXPR_IDENT with EXPR_SYMOP and store the symbol
		     * in the next element.
		     */

		    elt->op = EXPR_SYMOP;
		    elt++;
		    elt->sym = sym;
		    elt++;
		    n -= 2;
		}
		break;
	    }
	    case EXPR_INIT:
	    case EXPR_STRING:
	    {
		int nelts = ExprStrElts((const char*)(elt+1));

		elt += nelts+1;
		n -= nelts+1;
		break;
	    }
	    case EXPR_DOTTYPE:
		/*
		 * If .TYPE given, we force the evaluation of the expression
		 * even if there are identifiers in it as the .TYPE could be
		 * being used to decide if the thing is defined or not.
		 */
		dest->musteval = 1;
	    default:
		elt++; n--;
	}
    }
done:
    dest->numElts = elt - dest->elts;
    curProc = prevProc;
}


/***********************************************************************
 *				ExprExtractType
 ***********************************************************************
 * SYNOPSIS:	    Get a TypePtr from the given ExprResult
 * CALLED BY:	    Expr_Eval: LENGTH, SIZE, TYPE operators
 * RETURN:	    Non-zero and *typePtr filled if ok. 0
 *	    	    if not valid operand of the operators that use this.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/16/89		Initial Revision
 *
 ***********************************************************************/
static int
ExprExtractType(ExprResult  *tos,   	/* Element to evaluate */
		TypePtr	    *typePtr)	/* Place to store type, if valid */
{
    TypePtr result;

    switch ((int)tos->type) {
	case (int)EXPR_TYPE_NAN:
	    assert(0);		/* should have been caught by caller */
	case (int)EXPR_TYPE_CONST:
	    /*
	     * Deal with structure fields (typed constants...)
	     */
	    if (!tos->rel.sym && tos->rel.frame) {
		result = (TypePtr)tos->rel.frame;
		break;
	    }
	case (int)EXPR_TYPE_STRING:
	case (int)NULL:
	    /*
	     * Constant -- Null type
	     */
	    result = NULL;
	    break;
	case (int)EXPR_TYPE_TYPE:
	    result = tos->data.type;
	    break;
	case (int)EXPR_TYPE_SYM:
	    switch (tos->data.sym->type) {
		case SYM_STRUCT:
		case SYM_RECORD:
		case SYM_TYPE:
		case SYM_ETYPE:
		    /*
		     * Structured type -- create a type description using the
		     * type...
		     */
		    result = Type_Struct(tos->data.sym);
		    break;
		case SYM_CHUNK:
		    result = tos->data.sym->u.chunk.type;
		    break;
		case SYM_VAR:
		    /*
		     * Variable symbol -- use type of the variable
		     */
		    result = tos->data.sym->u.var.type;
		    break;
		case SYM_LOCAL:
		    /*
		     * Ditto for local variable symbol
		     */
		    result = tos->data.sym->u.localVar.type;
		    break;
		case SYM_INSTVAR:
		    /*
		     * Ditto for instance variable.
		     */
		    result = tos->data.sym->u.instvar.type;
		    break;
		case SYM_FIELD:
		    /*
		     * Ditto for structure field.
		     */
		    result = tos->data.sym->u.field.type;
		    break;
		case SYM_LABEL:
		case SYM_PROC:
		    /*
		     * Label/procedure -- Type_Near or Type_Far...
		     */
		    result = Sym_IsNear(tos->data.sym) ? Type_Near() :
			      Type_Far();
		    break;
		case SYM_CLASS:
		    /*
		     * Class -- call Obj module to get description.
		     */
		    result = Obj_ClassType(tos->data.sym);
		    break;
		case SYM_NUMBER:
		case SYM_ENUM:
		case SYM_METHOD:
		case SYM_PROTOMINOR:
		    /*
		     * Constant -- no type
		     */
		    result = NULL;
		    break;
		default:
		    /*
		     * Anything else (macro, string equate, etc.) is bogus
		     */
		    return(0);
	    }
	    break;
	case (int)EXPR_TYPE_SEGSYM:	/* EXPR_SIZE relies on this... */
	default:
	    /*
	     * Use type in the result
	     */
	    result = tos->type;
	    break;
    }

    *typePtr = result;
    return(1);
}


/***********************************************************************
 *				ExprExtractSegReg
 ***********************************************************************
 * SYNOPSIS:	    Get the segment register associated with an expression.
 * CALLED BY:	    Expr_Eval: SEGREGOF operator
 * RETURN:	    Non-zero and *segreg filled if ok. 0
 *	    	    if not valid operand of the operators that use this.
 *	    	    segreg is one of:
 *	    	    	REG_ES
 *	    	    	REG_CS
 *	    	    	REG_SS
 *	    	    	REG_DS
 *			REG_FS
 *			REG_GS
 *
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jcw	10/27/94	Initial Revision
 *
 ***********************************************************************/
static int
ExprExtractSegReg(ExprResult *tos,   	/* Element to evaluate */
		  int	     *segreg)	/* Place to store segreg, if valid */
{
    byte    ovr;
    byte    modrm;
    int	    result;

    switch((int)tos->type) {
    	case (int)EXPR_TYPE_NAN: /* Caller should handle this case */
	case (int)EXPR_TYPE_CONST:
	    assert(0);

	case (int)EXPR_TYPE_STRING:
	case (int)EXPR_TYPE_SEGSYM:
	    return(0);

	default:
	    break;
    }

    ovr   = (tos->data.ea.override & (~EXPR_IMPLICIT_OVERRIDE));
    modrm = tos->data.ea.modrm;

    switch (ovr) {
	case 0:
	case EXPR_DEF_OVERRIDE:
	    /*
	     * This is the hard one... the segment register is based on
	     * the mod-r/m.
	     */
	    switch (modrm & MR_RM_MASK) {
		case MR_BX_SI:	    /* [bx+si+disp] */
		case MR_BX_DI:	    /* [bx+di+disp] */
		case MR_SI:	    /* [si+disp] */
		case MR_DI:	    /* [di+disp] */
		case MR_BX:	    /* [bx+disp] */
		    /*
		     * 'ds' is the default for all of these.
		     */
		    result = REG_DS;
		    break;

		case MR_BP_SI:	    /* [bp+si+disp] */
		case MR_BP_DI:	    /* [bp+di+disp] */
		    /*
		     * 'ss' is the default for all of these.
		     */
		    result = REG_SS;
		    break;

		case MR_BP: 	    /* [bp+disp], same as MR_DIRECT */
		    /*
		     * 'ss' is the default, unless we are dealing with
		     * just a dword displacement, in which case it will be ds.
		     */
		    if ((modrm & MR_DISP_MASK) == 0) {
			/*
			 * dword displacement, use ds as default seg-register
			 */
			result = REG_DS;
		    } else {
			/*
			 * bp-displacement, use ss as default seg-register
			 */
			result = REG_SS;
		    }
		    break;

		default:
		    return(0);
		    /*NOTREACHED*/
	    }
	    break;

	case OVERRIDE(REG_ES):
	    result = REG_ES;
	    break;

	case OVERRIDE(REG_CS):
	    result = REG_CS;
	    break;

	case OVERRIDE(REG_SS):
	    result = REG_SS;
	    break;

	case OVERRIDE(REG_DS):
	    result = REG_DS;
	    break;

	case OVERRIDE(REG_FS):
	    result = REG_FS;
	    break;

	case OVERRIDE(REG_GS):
	    result = REG_GS;
	    break;

	case EXPR_NO_OVERRIDE:
	default:
	    /*
	     * For both of these cases, we fail. I'm assuming that the
	     * "no override" case is intended as a temporary condition
	     * in esp, and that it is always cleaned up before we generate
	     * any code.
	     */
	    return(0);
	    /*NOTREACHED*/
    }
    *segreg = result;
    return(1);
}


/***********************************************************************
 *				Expr_Status
 ***********************************************************************
 * SYNOPSIS:	    Return the status of an expression
 * CALLED BY:	    Expr_Eval(.TYPE), EXTERNAL
 * RETURN:	    A bitwise-or of the EXPR_STAT flags defined in expr.h.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/89		Initial Revision
 *
 ***********************************************************************/
byte
Expr_Status(ExprResult	*result)
{
    byte    value;

    value = EXPR_STAT_DEFINED;

    /*
     * Figure if it's code-related, data-related, constant,
     * a register, uses direct addressing.
     */
    switch((int)result->type) {
    	case (int)EXPR_TYPE_NAN:
	    value = 0;
	    break;
	case (int)EXPR_TYPE_CONST:
	case (int)EXPR_TYPE_STRING:
	    value |= EXPR_STAT_CONST;
	    if (result->rel.sym) {
		/*
		 * Relocatable constants are always global (that's why they
		 * are relocatable...)
		 */
		value |= EXPR_STAT_GLOBAL;
	    }
	    break;
	case (int)EXPR_TYPE_SEGSYM:
	    break;
	case (int)NULL:
	    /*
	     * See if it's a register (INDREG gives type NULL
	     * too).
	     */
	    if (((result->data.ea.modrm & 0xc0) == 0xc0) || (IS_SEGREG(result)))
	    {
		value |= EXPR_STAT_REGISTER;
	    }
	    break;
	default:
	    if (EXPR_IS_SEGREG(result)) {
		/*
		 * Segment registers are registers, not labels... Since
		 * they are integers, Type_Int(2), we need to account for
		 * them here.
		 */
		value |= EXPR_STAT_REGISTER;

	    } else if (result->type == Type_Near() ||
		       result->type == Type_Far())
	    {
		/*
		 * near/far label/procedure -- code-related
		 */
		value |= EXPR_STAT_CODE;
	    } else {
		/*
		 * Anything else must be data-related
		 */
		value |= EXPR_STAT_DATA;
	    }
	    if ((result->data.ea.modrm & MR_DISP_MASK) == MR_REG) {
		value |= EXPR_STAT_REGISTER;
	    }
	    if (result->data.ea.modrm == 0x06) {
		/*
		 * Direct addressing only comes with mode 06
		 */
		value |= EXPR_STAT_DIRECT;
	    }
	    break;
    }
    if (result->rel.sym && (result->rel.sym->flags & SYM_GLOBAL)) {
	value |= EXPR_STAT_GLOBAL;
    }

    return(value);
}

/***********************************************************************
 *				ExprSetDispSize
 ***********************************************************************
 * SYNOPSIS:	  Set the displacement size of an effective address
 * CALLED BY:	  Expr_Eval
 * RETURN:	  nothing
 * SIDE EFFECTS:  the modrm byte for the result is modified based on
 *		  the current offset.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 2/88	Initial Revision
 *
 ***********************************************************************/
static void
ExprSetDispSize(ExprResult  *result,
		int 	    delay)  	/* Non-zero if result being delayed.
					 * => should always use word disp
					 * to make sure don't get hemmed in. */
{
    if ((!(result->data.ea.dword_ea) && result->data.ea.modrm == MR_DIRECT) ||
	((result->data.ea.dword_ea) && result->data.ea.modrm == MR_DIRECT32)) {
	/*
	 * Direct addressing means we've got nothing to do here.
	 */
	return;
    }

    if (result->rel.sym || delay) {
	/*
	 * Offset is relocatable -- use 16-bit displacement.
	 * XXX: How do we handle 32-bit relocatable offsets?
	 */
 	result->data.ea.modrm &= ~MR_DISP_MASK;
	result->data.ea.modrm |= MR_WORD_DISP;
    } else if (result->data.ea.disp == 0 &&
	       /* 16-bit address and (Mod == 0 || R/M != BP) */
	       ((!(result->data.ea.dword_ea) &&
		 ((result->data.ea.modrm & MR_DISP_MASK) == MR_NULL_DISP ||
		  ((result->data.ea.modrm & MR_RM_MASK) != MR_BP))) ||
	       /* 32-bit address */
		(result->data.ea.dword_ea &&
		 /* R/M != SIB && (Mod == 0 || R/M != EBP) */
		 (((result->data.ea.modrm & MR_RM_MASK) != MR_SIB &&
		   ((result->data.ea.modrm & MR_DISP_MASK) == MR_NULL_DISP ||
		    (result->data.ea.modrm & MR_RM_MASK) != REG_EBP)) ||
		 /* R/M == SIB && (Mod == 0 || base != EBP) */
		  ((result->data.ea.modrm & MR_RM_MASK) == MR_SIB &&
		   ((result->data.ea.modrm & MR_DISP_MASK) == MR_NULL_DISP ||
		    (result->data.ea.sib & SIB_BASE_MASK) != REG_EBP))))))
    {
	/*
	 * Displacement of 0 and not using just BP (which can't use
	 * a null displacement) -- switch back to a null displacement.
	 */
	result->data.ea.modrm &= ~MR_DISP_MASK;
	result->data.ea.modrm |= MR_NULL_DISP;
    } else if (result->data.ea.disp >= -128 &&
	       result->data.ea.disp <= 127)
    {
	/*
	 * We can re-create the thing by sign-extension -- use 8-bit
	 */
	result->data.ea.modrm &= ~MR_DISP_MASK;
	result->data.ea.modrm |= MR_BYTE_DISP;
    } else {
	/*
	 * Use a 16-bit (or 32-bit) displacement.
	 */
	result->data.ea.modrm &= ~MR_DISP_MASK;
	result->data.ea.modrm |= MR_WORD_DISP;
    }
}

/***********************************************************************
 *				ExprConvertSym
 ***********************************************************************
 * SYNOPSIS:	    If an element is EXPR_TYPE_SYM, convert it to
 *	    	    a regular expression value.
 * CALLED BY:	    ExprConvertConstOperand, Expr_Eval
 * RETURN:	    0 if symbol not valid in expression
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/19/89		Initial Revision
 *
 ***********************************************************************/
static int
ExprConvertSym(Expr 	    *expr,  	/* Expression, for figuring any
					 * needed override. */
	       ExprResult   *result,
	       char 	    **msgPtr,
	       int  	    flags,
	       byte 	    *statusPtr)
{
    if (result->type == EXPR_TYPE_SYM) {
	Symbol	*sym = result->data.sym;

	switch(sym->type) {
/*
 * Things with addresses. The displacement is 0, since the things are
 * relocatable (we let the linker take care of it). The relocation frame is
 * the group in which the symbol resides, if its segment is in a group, or
 * the symbol's segment, if not.
 */
	    case SYM_VAR:
		result->type = sym->u.var.type;
addr_sym_init:
		result->data.ea.override = 0;
		result->data.ea.modrm = MR_DIRECT;
		result->data.ea.dword_ea = 0;
#if 0
		if (sym->segment->u.segment.data->comb == SEG_ABSOLUTE) {
		    /*
		     * If symbol lies in an absolute segment, it ain't
		     * relocatable, so use the offset directly.
		     */
		    result->rel.sym = NULL;
		    result->rel.frame = NULL;
		    result->data.ea.disp = ExprSymOffset(sym);
		} else {
#endif
		    result->rel.pcrel = 0;
		    result->rel.fixed = 0;
		    result->rel.sym = sym;
		    result->data.ea.disp = 0;
		    result->rel.frame = sym->segment;
		    if (sym->segment->segment &&
			(sym->segment->segment->type == SYM_GROUP))
		    {
			result->rel.frame = sym->segment->segment;
		    }
		    if (expr->segments[REG_DS] != result->rel.frame) {
			int	i;

			for (i = REG_ES; i < REG_DS; i++) {
			    if (expr->segments[i] == result->rel.frame) {
				/*
				 * Flag the override as implicit so we don't
				 * belch if the user specifies one later
				 */
				result->data.ea.override =
				    OVERRIDE(i)|EXPR_IMPLICIT_OVERRIDE;
				break;
			    }
			}
		    } else {
			/*
			 * Still need implicit override for REG_DS in case
			 * symbol is involved with REG_BP later on down the
			 * line...
			 */
			result->data.ea.override =
			    OVERRIDE(REG_DS)|EXPR_IMPLICIT_OVERRIDE;
		    }
		    result->rel.size = FIX_SIZE_WORD;
		    result->rel.type = FIX_OFFSET;
#if 0
		}
#endif
		break;
	    case SYM_LABEL:
	    case SYM_LOCALLABEL:
	    case SYM_PROC:
		result->type = Sym_IsNear(sym) ? Type_Near() : Type_Far();
		goto addr_sym_init;
	    case SYM_CLASS:
		result->type = Obj_ClassType(sym);
		goto addr_sym_init;
	    case SYM_CHUNK:
		/*
		 * This one's kind of weird. We need to say the beast is
		 * relocatable, since any data/code declared outside
		 * CHUNK/ENDC directives goes before the handle table,
		 * hence this thing could shift, but the linker needn't
		 * really fix the thing up, since lmem segments can't be
		 * combined. We say the thing's relocatable and rely on
		 * the LMem module to run through all fixups and nuke the
		 * ones for chunks, adding the chunk handle to the word.
		 *
		 * Actually, the Fix module won't write out a relocation
		 * to a chunk, preferring to handle it itself...
		 *
		 * 8/12/92: what really happens is the relocation is written
		 * out to the object file (since the LMem segment is really
		 * two segments that need to be combined) but the "address"
		 * of the chunk symbol is its chunk handle, not the offset
		 * of the data. -- ardeb
		 */
/*		result->type = sym->u.chunk.type;*/
		result->type = Type_Ptr(TYPE_PTR_LMEM, sym->u.chunk.type);
		goto addr_sym_init;
/*
 * Everything else
 */
	    case SYM_BITFIELD:
		/*
		 * Evaluates to bit offset and a warning (unless the expression
		 * contains the .TYPE operator, which we assume will be applied
		 * here and is being used to determine what kind of symbol the
		 * bitfield is...)
		 */
		result->type = EXPR_TYPE_CONST;
		if (!masmCompatible && !Expr_InvolvesOp(expr, EXPR_DOTTYPE)) {
		    Notify(NOTIFY_WARNING, expr->file, expr->line,
			   "%i used without MASK or OFFSET operator",
			   sym->name);
		}
		result->data.number = sym->u.bitField.offset;
		result->rel.sym = NULL;
		result->rel.frame = NULL; /* No known type */
		break;
	    case SYM_FIELD:
		/*
		 * A field gets converted to a non-relocatable constant with
		 * its type stored in the "frame" field of the relocation
		 * datum. Any use of the thing as a true address (e.g.
		 * with an override or indirection) will cause the things
		 * that do so to take the type from the frame field. Also
		 * any combination of the field with a true effective
		 * address will yield the field's type.
		 */
		result->type = EXPR_TYPE_CONST;
		result->rel.sym = NULL;
		result->rel.frame = (SymbolPtr)sym->u.field.type;
		result->data.number = sym->u.field.offset;
		break;
	    case SYM_INSTVAR:
		/*
		 * Ditto (hee hee)
		 */
		result->type = EXPR_TYPE_CONST;
		result->rel.sym = NULL;
		result->rel.frame = (SymbolPtr)sym->u.instvar.type;
		result->data.number = sym->u.instvar.offset;
		break;
	    case SYM_STRUCT:
		/*
		 * Evaluates to structure size as a constant.
		 */
		result->type = EXPR_TYPE_CONST;
		result->rel.sym = NULL;
		result->data.number = sym->u.sType.common.size;
		break;
	    case SYM_MACRO:
	    case SYM_STRING:
	    case SYM_PUBLIC:
		*msgPtr = "invalid symbol for expression";
		return(0);
	    case SYM_NUMBER:
		/*
		 * Evaluate the thing recursively, placing the result in
		 * result.
		 */
		if (sym->flags & SYM_UNDEF) {
		    /*
		     * External undefined constant: the result is a constant
		     * with a word-sized "offset" relocation. The value
		     * is 0, of course.
		     */
		    result->type = EXPR_TYPE_CONST;
		    result->rel.sym = sym;
		    result->rel.pcrel = 0;
		    result->rel.fixed = 0;
		    result->rel.sym = sym;
		    result->rel.size = FIX_SIZE_WORD;
		    result->rel.type = FIX_OFFSET;
		    result->rel.frame = sym->segment;
		    if (sym->segment->segment &&
			(sym->segment->segment->type == SYM_GROUP))
		    {
			result->rel.frame = sym->segment->segment;
		    }
		    result->data.number = 0;
		} else if (sym->u.equate.value == expr) {
		    *msgPtr = "using recursive constant";
		    return(0);
		} else if (!Expr_Eval(sym->u.equate.value, result,
				      flags | EXPR_RECURSIVE,
				      statusPtr))
		{
		    *msgPtr = (char *)result->type;
		    return(0);
		}
		break;
	    default:
		*msgPtr = "internal error: unhandled symbol type";
		return(0);
	    case SYM_SEGMENT:
	    case SYM_GROUP:
		result->type = EXPR_TYPE_CONST;
		result->rel.pcrel = 0;
		result->rel.fixed = 0;
		result->rel.sym = result->rel.frame = sym;
		result->rel.size = FIX_SIZE_WORD;
		result->rel.type = FIX_SEGMENT;
		result->data.number = 0;
		break;
	    case SYM_ETYPE:
		result->type = EXPR_TYPE_CONST;
		result->rel.sym = NULL;
		result->rel.frame = NULL;
		result->data.number = sym->u.eType.nextVal;
		break;
	    case SYM_PROTOMINOR:
		*msgPtr = "protominor symbol cannot be used in an expression as it has no value";
		return(0);
	    case SYM_METHOD:
	    case SYM_VARDATA:
	    case SYM_ENUM:
		/*
		 * Put out a protominor relocation for a particular symbol. If
		 * the EXPR_NOREF flag is set, then we do not put out the
		 * relocation, as it's not actually a reference to the symbol
		 * that points to the protominor symbol. Furthermore, if
		 * EXPR_NOREF is set but EXPR_FINALIZE isn't, we set the
		 * EXPR_STAT_DELAY flag so the EQU handler knows it shouldn't
		 * parse the thing down to a constant, else users of the equate
		 * would not get the protominor reference.
		 */
		if (sym->u.econst.protoMinor != NullSymbol) {
		    if (!(flags & EXPR_NOREF)) {
			ExprOutputProtoMinorRelocation(sym->u.econst.protoMinor);
		    } else if (!(flags & EXPR_FINALIZE)) {
			*statusPtr |= EXPR_STAT_DELAY;
		    }
		}

		result->type = EXPR_TYPE_CONST;
		result->rel.sym = NULL;
		result->rel.frame = NULL;
		result->data.number = sym->u.econst.value;
		break;
	    case SYM_TYPE:
		/*
		 * Size of type (bytes)
		 */
		result->type = EXPR_TYPE_CONST;
		result->rel.sym = NULL;
		result->rel.frame = NULL;
		result->data.number = Type_Length(sym->u.typeDef.type) *
		    Type_Size(sym->u.typeDef.type);
		break;
	    case SYM_RECORD:
		/*
		 * Evaluates to mask for whole record as a constant.
		 */
		result->type = EXPR_TYPE_CONST;
		result->rel.sym = NULL;
		result->rel.frame = NULL;
		result->data.number = sym->u.record.mask;
		break;
	    case SYM_LOCAL:
		/*
		 * EA of [bp-offset]
		 * XXX: 32-bits anyone?
		 */
		result->type = sym->u.localVar.type;
		result->rel.sym = NULL;
		result->rel.frame = NULL;
		result->data.ea.modrm = MR_BP|MR_BYTE_DISP;
		result->data.ea.disp = sym->u.localVar.offset;
		result->data.ea.override = 0;
		result->data.ea.dword_ea = 0;
		ExprSetDispSize(result, 0);
		break;
	}
    } else if (result->type == EXPR_TYPE_SEGSYM) {
	/*
	 * Convert segments and groups into relocatable constants....
	 */
#if 0
	if ((result->data.elt[1].sym->type == SYM_SEGMENT) &&
	    (result->data.elt[1].sym->u.segment.data->comb == SEG_ABSOLUTE))
	{
	    /*
	     * Absolute segments are non-relocatable and evaluate to their
	     * segment value.
	     */
	    result->type = EXPR_TYPE_CONST;
	    result->rel.sym = NULL;
	    result->rel.frame = NULL;
	    result->data.number =
		result->data.elt[1].sym->u.segment.data->segment;
	} else {
#endif
	    /*
	     * Anything else *is* relocatable.
	     */
	    result->type = EXPR_TYPE_CONST;
	    result->rel.pcrel = 0;
	    result->rel.fixed = 0;
	    result->rel.sym = result->rel.frame = result->data.elt[1].sym;
	    result->rel.size = FIX_SIZE_WORD;
	    result->rel.type = FIX_SEGMENT;
	    result->data.number = 0;
#if 0
	}
#endif
    } else if (result->type == EXPR_TYPE_TYPE) {
	/*
	 * We now know the type is to be used as a term in the expression,
	 * rather than for casting purposes. We need to convert the thing
	 * to a constant:
	 *  TYPE_STRUCT:
	 *  	SYM_STRUCT  	structure size
	 *  	SYM_ETYPE   	eType.nextVal
	 *  	SYM_RECORD  	record.mask
	 *  	SYM_TYPEDEF 	type size
	 *  anything else:   	type size
	 */
	if (result->data.type->tn_type == TYPE_STRUCT) {
	    SymbolPtr	sym = result->data.type->tn_u.tn_struct;

	    switch(sym->type) {
		case SYM_STRUCT:
		    result->data.number = sym->u.sType.common.size;
		    break;
		case SYM_ETYPE:
		    result->data.number = sym->u.eType.nextVal;
		    break;
		case SYM_RECORD:
		    result->data.number = sym->u.record.mask;
		    break;
		case SYM_TYPE:
		    result->data.number = sym->u.typeDef.common.size;
		    break;
	    }
	} else {
	    switch(result->data.type->tn_type) {
		case TYPE_NEAR:
		    result->data.number = -1;
		    break;
		case TYPE_FAR:
		    result->data.number = -2;
		    break;
		case TYPE_ARRAY:
		    result->data.number =
			Type_Size(result->data.type->tn_u.tn_array.tn_base);
		    break;
		default:
		    result->data.number = Type_Size(result->data.type);
		    break;
	    }
	}
	result->type = EXPR_TYPE_CONST;
	result->rel.sym = NULL;
	result->rel.frame = NULL;
    }
    return(1);
}


/***********************************************************************
 *				ExprMangleString
 ***********************************************************************
 * SYNOPSIS:	    Mangle a string into an integer constant
 * CALLED BY:	    ExprConvertConstOperand, ExprRelOp
 * RETURN:	    0 if error, 1 if ok.
 * SIDE EFFECTS:    result is changed to EXPR_TYPE_CONST if originally
 *	    	    EXPR_TYPE_STRING
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/27/89	Initial Revision
 *
 ***********************************************************************/
static int
ExprMangleString(Expr	    *expr,
		 ExprResult  *result,
		 char	    **msgPtr,
		 int 	    flags,
		 byte	    *statusPtr)
{
    /*
     * If result is a string constant, we need it as
     * a word constant. For whatever reason, MASM places the
     * first character of a two-character constant in the high
     * byte. I don't feel too strongly about this now, but I
     * may later.
     */
    if (result->type == EXPR_TYPE_STRING) {
	result->type = EXPR_TYPE_CONST;
	if (result->data.str[1]) {
	    if (result->data.str[2]) {
		*msgPtr = "string constant may only be 1 or 2 chars";
		return(0);
	    }
	    if (masmCompatible || reverseString) {
		result->data.number = (result->data.str[0] << 8) |
		    (result->data.str[1] & 0xff);
	    } else {
		result->data.number = (result->data.str[0] & 0xff) |
		    (result->data.str[1] << 8);
	    }
	} else {
	    result->data.number = result->data.str[0] & 0xff;
	}
    }
    return(1);
}

/***********************************************************************
 *			ExprOutputProtoMinorRelocation
 ***********************************************************************
 * SYNOPSIS:	    Output a relocation to a protoMinor symbol
 * CALLED BY:	    ExprConvertSym
 * RETURN:	    nothing
 * SIDE EFFECTS:    Creates a bogus segment to house these bogus relocations
 *                  the first time called
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----------	----------------
 *	jon	1 jul 1993      initial revision
 *
 ***********************************************************************/
void
ExprOutputProtoMinorRelocation(Symbol	    *protoSym)
{
    ExprResult    *fixResult;

    Sym_Reference(protoSym);

    fixResult = (ExprResult *)malloc(sizeof(ExprResult));

    fixResult->type = EXPR_TYPE_CONST;
    fixResult->rel.type = FIX_PROTOMINOR;
    fixResult->rel.size = FIX_SIZE_BOGUS;
    fixResult->rel.pcrel = 0;
    fixResult->rel.fixed = 0;
    fixResult->rel.sym = protoSym;
    fixResult->rel.frame = protoSym->segment;

    if (protoMinorRelocationSeg == NullSymbol) {
	ID	    	bogusId;

	bogusId = ST_EnterNoLen(output, symStrings, "ProtoMinorRelocationSegment");
	protoMinorRelocationSeg = Sym_Enter(bogusId, SYM_SEGMENT,
					    SEG_LIBRARY, 0, NullID);
    }

    Fix_EnterSegment(protoMinorRelocationSeg, fixResult, 0, 0);
}

/***********************************************************************
 *				ExprConvertConstOperand
 ***********************************************************************
 * SYNOPSIS:	    Convert an ExprResult to something suitable for
 *	    	    operation on by one of the constant-only operators.
 * CALLED BY:	    ExprConstBinOp, ExprConstUnOp
 * RETURN:	    0 if operand invalid.
 * SIDE EFFECTS:    EXPR_TYPE_STRING elements converted to EXPR_TYPE_CONST.
 *	    	    EXPR_TYPE_SYM elements converted properly.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/19/89		Initial Revision
 *
 ***********************************************************************/
static int
ExprConvertConstOperand(Expr	    *expr,
			ExprResult  *result,
			char	    **msgPtr,
			int 	    flags,
			byte	    *statusPtr)
{
    /*
     * Convert any symbol to something more tenable.
     */
    if (!ExprConvertSym(expr, result, msgPtr, flags, statusPtr)) {
	return(0);
    }

    if (!ExprMangleString(expr, result, msgPtr, flags, statusPtr)) {
	return(0);
    }

    if (result->type != EXPR_TYPE_CONST) {
	*msgPtr = "operand must be constant";
	return(0);
    }
    return(1);
}

/***********************************************************************
 *				ExprIndirect
 ***********************************************************************
 * SYNOPSIS:	    Perform indirection through something.
 * CALLED BY:	    Expr_Eval, ExprCombine
 * RETURN:	    TRUE if successful
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/11/91		Initial Revision
 *
 ***********************************************************************/
static int
ExprIndirect(Expr   	*expr,
	     ExprResult *result,
	     char	**errMsgPtr,
	     int 	flags,
	     byte	*statusPtr)
{
    if (result->type == EXPR_TYPE_CONST) {
	if (result->rel.sym) {
	    /*
	     * Either this is a relocatable constant, or the user has something
	     * like [offset foo] in his/her code. It depends on the type of the
	     * symbol... Easiest way to handle it is to convert the result back
	     * into an EXPR_TYPE_SYM result and call ExprConvertSym on it. We
	     * record the current value, in case someone did [offset foo+34]
	     */
	    long	val = result->data.number;

	    result->type = EXPR_TYPE_SYM;
	    result->data.sym = result->rel.sym;
	    if (!(flags & EXPR_NOREF)) {
		Sym_Reference(result->rel.sym);
	    }
	    if (!ExprConvertSym(expr, result, errMsgPtr, flags, statusPtr)) {
		return(0);
	    }
	    /*
	     * If wasn't a relocatable constant, add any extra offset back into
	     * the displacement.
	     */
	    if (result->type != EXPR_TYPE_CONST) {
		result->data.ea.disp += val;
		ExprSetDispSize(result, *statusPtr & EXPR_STAT_DELAY);
	    }
	} else {
	    /*
	     * Constants are allowed here -- we convert them to a direct
	     * reference using the value as an offset. The type we get from the
	     * frame field of the relocation, to deal with things like
	     * ds:field, where field is a structure field.
	     */
	    result->type = (TypePtr)result->rel.frame;
	    result->rel.sym = NULL;
	    result->data.ea.disp = result->data.number;
	    result->data.ea.override = 0;
	    result->data.ea.sib = 0;
	    /* XXX: Use 32-bit ea if USE32. */
	    if (result->data.ea.disp >= -65536 &&
		result->data.ea.disp <= 65535) {
		result->data.ea.modrm = MR_DIRECT;
		result->data.ea.dword_ea = 0;
	    } else {
		result->data.ea.modrm = MR_DIRECT32;
		result->data.ea.dword_ea = 1;
	    }
	}
    }
    return(1);
}


/***********************************************************************
 *				ExprIsGlobalUndef
 ***********************************************************************
 * SYNOPSIS:	    See if the passed intermediate result is for a
 *	    	    global symbol that's (still) undefined.
 * CALLED BY:	    ExprAddCurrentDisp, Expr_Eval
 * RETURN:	    non-zero if the result is global undefined
 * SIDE EFFECTS:    if symbol is global undefined, its name is added
 *	    	    to the list of undefined things and undefErr is set.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/24/91	Initial Revision
 *
 ***********************************************************************/
static int
ExprIsGlobalUndef(Expr	    	*expr,
		  ExprResult	*result,
		  char	    	**msgPtr,
		  int	    	flags,
		  byte	    	*statusPtr)
{
    if (result->type == EXPR_TYPE_SYM) {
	if (result->data.sym->flags & SYM_UNDEF) {
	    ExprUndefAdd(result->data.sym->name);
	    return(1);
	}
    } else if ((result->type > EXPR_TYPE_MAX_SPECIAL) &&
	       result->rel.sym &&
	       (result->rel.sym->flags & SYM_UNDEF))
    {
	ExprUndefAdd(result->rel.sym->name);
	return(1);
    }
    return(0);
}

/***********************************************************************
 *				ExprAddCurrentDisp
 ***********************************************************************
 * SYNOPSIS:	    Add the current offset of the symbol in the
 *	    	    relocation for the passed ExprResult to the
 *	    	    displacement in its data.ea. This checks for
 *	    	    undefined symbols when they must be defined and
 *	    	    complains if so.
 * CALLED BY:	    ExprRelOp
 * RETURN:	    0 if the symbol the result refers to is undefined/external
 *
 * SIDE EFFECTS:    If the result is a symbol and is marked as SYM_UNDEF,
 *	    	    ExprUndefAdd is called, which will result in the
 *	    	    expression being marked as undefined, or an appropriate
 *	    	    error being generated (depending on the pass).
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/9/91		Initial Revision
 *
 ***********************************************************************/
static int
ExprAddCurrentDisp(ExprResult	*result)
{
    if (result->rel.sym) {
	result->data.ea.disp += ExprSymOffset(result->rel.sym);
	if (result->rel.sym->flags & SYM_UNDEF) {
	    ExprUndefAdd(result->rel.sym->name);
	    return(0);
	}
    }
    return(1);
}

/***********************************************************************
 *				ExprRelOp
 ***********************************************************************
 * SYNOPSIS:	    Handle relational operators. This is a separate
 *	    	    function from ExprConstBinOp as we've got more
 *	    	    latitude in dealing with the operands here, so long
 *	    	    as everything's defined.
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/27/89	Initial Revision
 *
 ***********************************************************************/
static int
ExprRelOp(Expr 	    	*expr,
	  ExprOp    	op,
	  ExprResult	*lhs,
	  ExprResult   	*rhs,
	  char 	    	**msgPtr,
	  int  	    	flags,
	  byte 	    	*statusPtr)
{
    int	    resval;

    /*
     * If either side is undefined, the result is undefined.
     */
    if (lhs->type == EXPR_TYPE_NAN || rhs->type == EXPR_TYPE_NAN) {
	lhs->type = EXPR_TYPE_NAN;
	lhs->rel.frame = lhs->rel.sym = NULL;
	return(1);
    }

    if (!ExprConvertSym(expr, lhs, msgPtr, flags, statusPtr)) {
	return(0);
    }
    if (!ExprConvertSym(expr, rhs, msgPtr, flags, statusPtr)) {
	return(0);
    }

    if ((op == EXPR_EQ) || (op == EXPR_NEQ)) {
	/*
	 * Perform comparison as if it were EXPR_EQ, if it isn't, we'll
	 * just invert the result. These are the only cases with which we
	 * need to deal as ExprConvertSym handles everything else.
	 */
	switch((long)lhs->type) {
	    case (int)EXPR_TYPE_STRING:
		if (rhs->type == EXPR_TYPE_STRING) {
		    resval = (strcmp(lhs->data.str, rhs->data.str) == 0);
		    break;
		} else if (!ExprMangleString(expr, lhs, msgPtr, flags,
					     statusPtr))
		{
		    return(0);
		}
		/*FALLTHRU*/
	    case (int)EXPR_TYPE_CONST:
		if (!ExprMangleString(expr, rhs, msgPtr, flags, statusPtr)) {
		    return(0);
		}
		if (rhs->type == EXPR_TYPE_CONST) {
		    if (lhs->rel.sym && rhs->rel.sym) {
			if ((lhs->rel.type == FIX_SEGMENT) &&
			    (rhs->rel.type == FIX_SEGMENT))
			{
			    /*
			     * If both sides are segment fixups, we're
			     * performing a segment comparison, so we have
			     * to compare the frames, not the symbols, as
			     * "segment sym" will give "sym" as the symbol,
			     * which isn't what we want to compare...
			     */
			    resval = (lhs->rel.frame == rhs->rel.frame);
			} else {
			    resval = ((ExprSymOffset(lhs->rel.sym) +
				       lhs->data.number) ==
				      (ExprSymOffset(rhs->rel.sym) +
				       rhs->data.number));
			}
		    } else if (lhs->rel.sym || rhs->rel.sym) {
			*msgPtr = "cannot compare constants and non-constants";
			return(0);
		    } else {
			resval = (lhs->data.number == rhs->data.number);
		    }
		} else {
		    *msgPtr = "cannot compare constants and non-constants";
		    return(0);
		}
		break;
	    default:
		if (!ExprAddCurrentDisp(lhs) || !ExprAddCurrentDisp(rhs)) {
		    /*
		     * If either is undefined, it's either an error our caller
		     * will handle, or the result doesn't matter, as we'll
		     * be called again on a later pass. In either case, the
		     * segment for the undefined symbol might be wrong, so
		     * we can't decide whether it's legal to compare the
		     * operands until both are defined.
		     */
		    lhs->type = EXPR_TYPE_NAN;
		    lhs->rel.frame = lhs->rel.sym = NULL;
		    return (1);
		} else if ((lhs->rel.sym && !rhs->rel.sym) ||
			   (!lhs->rel.sym && rhs->rel.sym))
		{
		    *msgPtr = "operands cannot be compared";
		    return(0);
		} else if (lhs->rel.sym &&
			   (lhs->rel.sym->segment != rhs->rel.sym->segment))
		{
		    /*
		     * If symbols are in different segments, they are manifestly
		     * not equal.
		     */
		    resval = 0;
		} else if ((rhs->type > EXPR_TYPE_MAX_SPECIAL) ||
			   (rhs->type == NULL))
		{
		    resval = ((lhs->data.ea.disp == rhs->data.ea.disp) &&
			      (lhs->data.ea.modrm == rhs->data.ea.modrm) &&
			      (lhs->data.ea.override==rhs->data.ea.override));
		} else {
		    *msgPtr = "operands cannot be compared";
		    return(0);
		}
		break;
	}
	if (op == EXPR_NEQ) {
	    resval = !resval;
	}
    } else if ((op == EXPR_LT) || (op == EXPR_GE)) {
	/*
	 * Perform comparison as if it were EXPR_GE, if it isn't, we'll
	 * just invert the result. These are the only cases with which we
	 * need to deal as ExprConvertSym handles everything else.
	 */
	switch((long)lhs->type) {
	    case (int)EXPR_TYPE_STRING:
		if (rhs->type == EXPR_TYPE_STRING) {
		    resval = (strcmp(lhs->data.str, rhs->data.str) >= 0);
		    break;
		} else if (!ExprMangleString(expr, lhs, msgPtr, flags,
					     statusPtr))
		{
		    return(0);
		}
		/*FALLTHRU*/
	    case (int)EXPR_TYPE_CONST:
		if (!ExprMangleString(expr, rhs, msgPtr, flags, statusPtr)) {
		    return(0);
		}
		if (rhs->type == EXPR_TYPE_CONST) {
		    if (lhs->rel.sym || rhs->rel.sym) {
			*msgPtr = "can only compare external constants with EQ and NE";
			return(0);
		    } else {
			resval = (lhs->data.number >= rhs->data.number);
		    }
		} else {
		    *msgPtr = "cannot compare constants and non-constants";
		    return(0);
		}
		break;
	    default:
		if (!ExprAddCurrentDisp(lhs) || !ExprAddCurrentDisp(rhs)) {
		    /*
		     * If either is undefined, it's either an error our caller
		     * will handle, or the result doesn't matter, as we'll
		     * be called again on a later pass. In either case, the
		     * segment for the undefined symbol might be wrong, so
		     * we can't decide whether it's legal to compare the
		     * operands until both are defined.
		     */
		    lhs->type = EXPR_TYPE_NAN;
		    lhs->rel.frame = lhs->rel.sym = NULL;
		    return (1);
		} else if ((lhs->rel.sym && !rhs->rel.sym) ||
		    (!lhs->rel.sym && rhs->rel.sym) ||
		    (lhs->rel.sym &&
		     (lhs->rel.sym->segment != rhs->rel.sym->segment)))
		{
		    *msgPtr = "operands cannot be compared";
		    return(0);
		} else if ((rhs->type > EXPR_TYPE_MAX_SPECIAL) ||
			   (rhs->type == NULL))
		{
		    if ((lhs->data.ea.modrm != MR_DIRECT) ||
			(rhs->data.ea.modrm != MR_DIRECT))
		    {
			*msgPtr = "addressing modes can only be compared with EQ and NE";
			return(0);
		    } else {
			resval = (lhs->data.ea.disp >= rhs->data.ea.disp);
		    }
		} else {
		    *msgPtr = "operands cannot be compared";
		    return(0);
		}
		break;
	}
	if (op == EXPR_LT) {
	    resval = !resval;
	}
    } else if ((op == EXPR_LE) || (op == EXPR_GT)) {
	/*
	 * Perform comparison as if it were EXPR_GT, if it isn't, we'll
	 * just invert the result. These are the only cases with which we
	 * need to deal as ExprConvertSym handles everything else.
	 */
	switch((long)lhs->type) {
	    case (int)EXPR_TYPE_STRING:
		if (rhs->type == EXPR_TYPE_STRING) {
		    resval = (strcmp(lhs->data.str, rhs->data.str) > 0);
		    break;
		} else if (!ExprMangleString(expr, lhs, msgPtr, flags,
					     statusPtr))
		{
		    return(0);
		}
		/*FALLTHRU*/
	    case (int)EXPR_TYPE_CONST:
		if (!ExprMangleString(expr, rhs, msgPtr, flags, statusPtr)) {
		    return(0);
		}
		if (rhs->type == EXPR_TYPE_CONST) {
		    if (lhs->rel.sym || rhs->rel.sym) {
			*msgPtr = "can only compare external constants with EQ and NE";
			return(0);
		    } else {
			resval = (lhs->data.number > rhs->data.number);
		    }
		} else {
		    *msgPtr = "cannot compare constants and non-constants";
		    return(0);
		}
		break;
	    default:
		if (!ExprAddCurrentDisp(lhs) || !ExprAddCurrentDisp(rhs)) {
		    /*
		     * If either is undefined, it's either an error our caller
		     * will handle, or the result doesn't matter, as we'll
		     * be called again on a later pass. In either case, the
		     * segment for the undefined symbol might be wrong, so
		     * we can't decide whether it's legal to compare the
		     * operands until both are defined.
		     */
		    lhs->type = EXPR_TYPE_NAN;
		    lhs->rel.frame = lhs->rel.sym = NULL;
		    return (1);
		} else if ((lhs->rel.sym && !rhs->rel.sym) ||
		    (!lhs->rel.sym && rhs->rel.sym) ||
		    (lhs->rel.sym &&
		     (lhs->rel.sym->segment != rhs->rel.sym->segment)))
		{
		    *msgPtr = "operands cannot be compared";
		    return(0);
		} else if ((rhs->type > EXPR_TYPE_MAX_SPECIAL) ||
			   (rhs->type == NULL))
		{
		    if ((lhs->data.ea.modrm != MR_DIRECT) ||
			(rhs->data.ea.modrm != MR_DIRECT))
		    {
			*msgPtr = "addressing modes can only be compared with EQ and NE";
			return(0);
		    } else {
			resval = (lhs->data.ea.disp > rhs->data.ea.disp);
		    }
		} else {
		    *msgPtr = "operands cannot be compared";
		    return(0);
		}
		break;
	}
	if (op == EXPR_LE) {
	    resval = !resval;
	}
    } else {
	*msgPtr = "internal error: unhandled operator in ExprRelOp";
	return(0);
    }

    lhs->type = EXPR_TYPE_CONST;
    lhs->rel.frame = lhs->rel.sym = NULL;

    lhs->data.number = resval ? -1 : 0;

    return(1);
}


/***********************************************************************
 *				ExprConstBinOp
 ***********************************************************************
 * SYNOPSIS:	    Perform a binary operator on two constant operands
 * CALLED BY:	    Expr_Eval
 * RETURN:	    0 if operands bad
 * SIDE EFFECTS:    lhs replaced by result
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/19/89		Initial Revision
 *
 ***********************************************************************/
static int
ExprConstBinOp(Expr 	    *expr,
	       ExprOp	    op,
	       ExprResult   *lhs,
	       ExprResult   *rhs,
	       char 	    **msgPtr,
	       int  	    flags,
	       byte 	    *statusPtr)
{
    /*
     * If either side is undefined, the result is undefined.
     */
    if (lhs->type == EXPR_TYPE_NAN || rhs->type == EXPR_TYPE_NAN) {
	lhs->type = EXPR_TYPE_NAN;
	lhs->rel.frame = lhs->rel.sym = NULL;
	return(1);
    }

    if (!ExprConvertConstOperand(expr, lhs, msgPtr, flags, statusPtr)) {
	return(0);
    }
    if (!ExprConvertConstOperand(expr, rhs, msgPtr, flags, statusPtr)) {
	return(0);
    }
    if (lhs->rel.sym || rhs->rel.sym) {
	*msgPtr = "cannot operate on external constants";
	return(0);
    }

    switch(op) {
	case EXPR_TIMES:
	    lhs->data.number *= rhs->data.number;
	    break;
	case EXPR_DIV:
	    if (rhs->data.number == 0) {
		*msgPtr = "divide by 0";
		return(0);
	    }
	    lhs->data.number /= rhs->data.number;
	    break;
	case EXPR_OR:
	    lhs->data.number |= rhs->data.number;
	    break;
	case EXPR_XOR:
	    lhs->data.number ^= rhs->data.number;
	    break;
	case EXPR_AND:
	    lhs->data.number &= rhs->data.number;
	    break;
	case EXPR_SHL:
	    lhs->data.number <<= rhs->data.number;
	    break;
	case EXPR_SHR:
	    lhs->data.number >>= rhs->data.number;
	    break;
	case EXPR_MOD:
	    if (rhs->data.number == 0) {
		*msgPtr = "mod by 0";
		return(0);
	    }
	    lhs->data.number %= rhs->data.number;
	    break;
	case EXPR_FMASK:
	    /*
	     * Make sure lhs fits within bitmask defined by rhs. Used
	     * when encoding record initializers
	     */
	    if (lhs->data.number & ~rhs->data.number) {
		long	msbit = rhs->data.number & ~(rhs->data.number >> 1);

		if ((lhs->data.number & msbit) &&
		    !(lhs->data.number & ((msbit-1) & ~rhs->data.number)) &&
		    ((lhs->data.number | (msbit-1)) == -1))
		{
		    /*
		     * Field value appears to be negative and the bits outside
		     * the record field are insignificant, so we let it slide
		     * after masking out the insignificant bits.
		     */
		    lhs->data.number &= rhs->data.number;
		} else {
		    *msgPtr = "value too large for field";
		    return(0);
		}
	    }
	    break;
    }
    lhs->rel.frame = NULL;
    return(1);
}

/***********************************************************************
 *				ExprConstUnOp
 ***********************************************************************
 * SYNOPSIS:	    Do a unary operator that takes only a constant operand
 * CALLED BY:	    Expr_Eval
 * RETURN:	    0 if operand invalid
 * SIDE EFFECTS:    operand replaced by result
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/19/89		Initial Revision
 *
 ***********************************************************************/
static int
ExprConstUnOp(Expr  	    *expr,
	      ExprOp	    op,
	      ExprResult    *operand,
	      char  	    **msgPtr,
	      int   	    flags,
	      byte  	    *statusPtr)
{
    /*
     * If undefined, the result is undefined.
     */
    if (operand->type == EXPR_TYPE_NAN) {
	return(1);
    }

    if (!ExprConvertConstOperand(expr, operand, msgPtr, flags, statusPtr)) {
	return(0);
    }
    /*
     * Only operators we've got are NOT and NEG...
     */
    operand->data.number = ~operand->data.number;
    if (op == EXPR_NEG) {
	operand->data.number++;
    }
    return(1);
}

/***********************************************************************
 *				ExprSubtract
 ***********************************************************************
 * SYNOPSIS:	    Subtract two operands.
 * CALLED BY:	    Expr_Eval
 * RETURN:	    non-zero if subtraction ok
 * SIDE EFFECTS:    EXPR_STAT_DELAY is set in *statusPtr if the operands
 *	    	    are relocatable but can actually be subtracted.
 *
 * STRATEGY:
 *
 *	lhs \ rhs | const | rel const | direct | ea    | rel ea
 *	-------------------------------------------------------
 *	const	  | ok    | err       | err    | err   | err
 *	-------------------------------------------------------
 *	rel const | ok	  | delay     | delay  | ok    | delay
 *	-------------------------------------------------------
 *	direct    | ok	  | delay     | delay  | ok    | delay
 *	-------------------------------------------------------
 *      ea  	  | ok	  | delay     | delay  | err   | err
 *	-------------------------------------------------------
 *	rel ea    | ok    | delay     | delay  | err   | err
 *
 *	const	    = any absolute constant
 *	rel const   = a constant that must be fixed up by the linker.
 *	    	      caused by OFFSET, SEGMENT, HANDLE and RESID operators
 *	    	      as well as direct use of a segment
 *	direct	    = effective address using direct addressing with
 *	    	      possible displacement.
 *	ea  	    = effective address w/o need for relocation. [bx+2], e.g.
 *	rel ea	    = effective address requiring relocation.
 *
 *	delay	    = ok, but set EXPR_STAT_DELAY if EXPR_FINALIZE not
 *	    	      set in flags word.
 *	err 	    = we can't do it b/c there's no way to tell the
 *	    	      linker to subtract the relocation rather than add.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 3/89	Initial Revision
 *
 ***********************************************************************/
static int
ExprSubtract(Expr   	*expr,
	     ExprResult	*tos,
	     char   	**errMsgPtr,
	     int    	flags,
	     byte   	*statusPtr)
{
    ExprResult	    *lhs = tos+1;
    ExprResult	    *rhs = tos;

    /*
     * If either side is undefined, the result is undefined.
     */
    if (lhs->type == EXPR_TYPE_NAN || rhs->type == EXPR_TYPE_NAN) {
	lhs->type = EXPR_TYPE_NAN;
	lhs->rel.frame = lhs->rel.sym = NULL;
	return(1);
    }

    /*
     * Perform any delayed conversions of any kind on either operand.
     */
    if (!ExprConvertSym(expr, lhs, errMsgPtr, flags, statusPtr)) {
	return(0);
    }
    if (!ExprConvertSym(expr, rhs, errMsgPtr, flags, statusPtr)){
	return(0);
    }

    /*
     * If either lhs or rhs is a string constant, we need it as a word
     * constant. For whatever reason, MASM places the first character of a
     * two-character constant in the high byte. I don't feel too strongly
     * about this now, but I may later....
     */
    if (!ExprMangleString(expr, lhs, errMsgPtr, flags, statusPtr)) {
	return(0);
    }
    if (!ExprMangleString(expr, rhs, errMsgPtr, flags, statusPtr)) {
	return(0);
    }

    if (lhs->type == EXPR_TYPE_CONST) {
	if (!lhs->rel.sym && (rhs->type != EXPR_TYPE_CONST || rhs->rel.sym)) {
	    *errMsgPtr = "cannot subtract anything but a constant from a constant";
	    return(0);
	} else if (!lhs->rel.sym) {
	    lhs->data.number -= rhs->data.number;
	    if (rhs->rel.frame) {
		lhs->rel.frame = rhs->rel.frame;
	    }
	} else {
	    /*
	     * Make sure the operands are in the same segment.
	     */
	    if (rhs->rel.sym && lhs->rel.frame != rhs->rel.frame) {
		*errMsgPtr="cannot subtract operands from different segments";
		return(0);
	    }

	    if ((rhs->type != EXPR_TYPE_CONST) &&
		(rhs->data.ea.modrm == MR_DIRECT))
	    {
		/*
		 * To make life easy, convert direct operand to a constant
		 * and fall into common code.
		 */
		rhs->data.number = rhs->data.ea.disp;
		rhs->type = EXPR_TYPE_CONST;
	    }


	    /*
	     * If both operands are relocatable, instruct our caller to delay
	     * using this result until things are final. The result of such
	     * a subtraction isn't relocatable, so biff the rel.sym from the
	     * lhs.
	     */
	    if (rhs->rel.sym) {
		/*
		 * Add in actual offset of symbol involved since it wasn't done
		 * by ExprConvertSym or whomever (it never is).
		 *
		 * Note this is only done if we're actually forming the
		 * difference between two symbols.
		 */
		lhs->data.number += ExprSymOffset(lhs->rel.sym);
		lhs->data.number &= 0xffff;

		if ((lhs->rel.type == FIX_SEGMENT) ||
		    (rhs->rel.type == FIX_SEGMENT))
		{
		    *errMsgPtr="cannot perform arithmetic on segments or groups";
		    return(0);
		}

		if (!(flags & EXPR_FINALIZE)) {
		    *statusPtr |= EXPR_STAT_DELAY;
		}
		lhs->rel.sym = NULL;
		lhs->rel.frame = NULL;
		if (rhs->type == EXPR_TYPE_CONST) {
		    rhs->data.number += ExprSymOffset(rhs->rel.sym);
		    rhs->data.number &= 0xffff;
		} else {
		    rhs->data.ea.disp += ExprSymOffset(rhs->rel.sym);
		}
	    }

	    if (rhs->type != EXPR_TYPE_CONST) {
		/*
		 * Subtracting an EA from a constant involves subtracting
		 * the displacement from the constant. The only way this
		 * should happen is if the bozo does something like
		 *  CONSTANT-(biff[bx]+2)
		 * which is really, really weird.
		 */
		lhs->data.ea.disp = lhs->data.number - rhs->data.ea.disp;
		lhs->data.ea.modrm = rhs->data.ea.modrm;
		lhs->data.ea.override = rhs->data.ea.modrm;
		ExprSetDispSize(lhs, *statusPtr & EXPR_STAT_DELAY);
	    } else {
		lhs->data.number -= rhs->data.number;
	    }
	}
    } else if (lhs->data.ea.modrm == MR_DIRECT) {
	if ((rhs->type == EXPR_TYPE_CONST) && !rhs->rel.sym) {
	    /*
	     * Subtracting a simple constant from a direct address is easy.
	     */
	    lhs->data.ea.disp -= rhs->data.number;
	} else if (rhs->type == EXPR_TYPE_CONST) {
	    if (rhs->rel.type == FIX_SEGMENT) {
		*errMsgPtr="cannot perform arithmetic on segments or groups";
		return(0);
	    } else if (lhs->rel.sym) {
		if (lhs->rel.frame != rhs->rel.frame) {
		    *errMsgPtr="cannot subtract operands from different segments";
		    return(0);
		}
		/*
		 * Deal with possible delay. When subtracting two relocatable
		 * values, result is absolute.
		 */
		if (!(flags & EXPR_FINALIZE)) {
		    *statusPtr |= EXPR_STAT_DELAY;
		}
		/*
		 * Actual symbol offset wasn't included on the lhs before.
		 */
		lhs->data.ea.disp += ExprSymOffset(lhs->rel.sym);
		lhs->rel.sym = lhs->rel.frame = NULL;
		/*
		 * Need to add in actual symbol offset on rhs as well. Note
		 * that addition *must* be carried out MOD 64K
		 */
		rhs->data.number += ExprSymOffset(rhs->rel.sym);
		rhs->data.number &= 0xffff;
	    }
	    /*
	     * Convert the LHS to a constant by taking the difference of
	     * the ea displacement (to which was added the lhs's symbol's
	     * offset, above) and the relocatable constant on the rhs (to
	     * which a similar modification was made).
	     *
	     * changed 3/20/92 to fix "$ - offset foo", which was generating
	     * a bogus relocation -- ardeb
	     */
	    lhs->data.number = lhs->data.ea.disp - rhs->data.number;
	    lhs->type = EXPR_TYPE_CONST;
	} else {
	    /*
	     * Subtracting EA. This involves subtracting the displacement of
	     * the RHS from the LHS. The modrm is inherited from the RHS.
	     * The override remains the same.
	     */
	    if (lhs->rel.sym && rhs->rel.sym) {
		if (lhs->rel.frame != rhs->rel.frame) {
		    *errMsgPtr="cannot subtract operands from different segments";
		    return(0);
		}
		if (!(flags & EXPR_FINALIZE)) {
		    *statusPtr |= EXPR_STAT_DELAY;
		} else if ((lhs->rel.sym->flags & SYM_UNDEF) ||
			   (rhs->rel.sym->flags & SYM_UNDEF))
		{
		    /*
		     * We've no way to generate a relocation for this case,
		     * especially with the result being constant and all
		     * that, so we must generate an error if either symbol
		     * in the equation is undefined external in this final
		     * pass.
		     */
		    *errMsgPtr="cannot use external symbol in subtraction";
		    return(0);
		}
		/*
		 * Actual symbol displacements must be added to the two
		 * displacements as they weren't before.
		 *
		 * 6/30/91: added special handling of SYM_CHUNK to provide
		 * results consistent with fixup-module's behaviour, where
		 * a relocation to a chunk symbol yields an assembly-time
		 * constant of the chunk handle. Note that for lmem segments
		 * that have no chunk handles, the "chunk" directive does
		 * not actually create SYM_CHUNK symbols, but creates SYM_VAR
		 * symbols instead. -- ardeb
		 */
		lhs->data.ea.disp += ExprSymOffset(lhs->rel.sym);
		rhs->data.ea.disp += ExprSymOffset(rhs->rel.sym);

		/*
		 * Result is absolute.
		 */
		lhs->rel.sym = lhs->rel.frame = NULL;
	    }
	    lhs->data.ea.disp -= rhs->data.ea.disp;
	    if (rhs->data.ea.modrm == MR_DIRECT) {
		/*
		 * When subtracting two directly addressed operands,
		 * the result is an absolute constant, so make it so.
		 */
		lhs->data.number = lhs->data.ea.disp;
		lhs->type = EXPR_TYPE_CONST;
	    } else {
		lhs->data.ea.modrm = rhs->data.ea.modrm;
		ExprSetDispSize(lhs, *statusPtr & EXPR_STAT_DELAY);
	    }
	}
    } else if ((rhs->type == EXPR_TYPE_CONST) ||
	       (rhs->data.ea.modrm == MR_DIRECT))
    {
	/*
	 * LHS is indirect operand. Note special casing of direct operand on
	 * the RHS. We (and the processor) can deal with such. It's things
	 * like [bx-di] that are illegal.
	 */
	if (lhs->rel.sym && rhs->rel.sym) {
	    if (lhs->rel.frame != rhs->rel.frame) {
		*errMsgPtr="cannot subtract operands from different segments";
		return(0);
	    }
	    if (!(flags & EXPR_FINALIZE)) {
		*statusPtr |= EXPR_STAT_DELAY;
	    }
	    lhs->data.ea.disp += ExprSymOffset(lhs->rel.sym);
	    if (rhs->type == EXPR_TYPE_CONST) {
		rhs->data.number += ExprSymOffset(rhs->rel.sym);
		rhs->data.number &= 0xffff;
	    } else {
		rhs->data.ea.disp += ExprSymOffset(rhs->rel.sym);
	    }
	    lhs->rel.sym = lhs->rel.frame = NULL;
	} else if (rhs->rel.sym) {
	    *errMsgPtr = "cannot subtract a relocatable value from a non-relocatable value";
	    return(0);
	}

	if (rhs->type == EXPR_TYPE_CONST) {
	    lhs->data.ea.disp -= rhs->data.number;
	} else {
	    lhs->data.ea.disp -= rhs->data.ea.disp;
	}
	ExprSetDispSize(lhs, *statusPtr & EXPR_STAT_DELAY);
    } else {
	*errMsgPtr="cannot subtract effective addresses containing registers";
	return(0);
    }

    return(1);
}

/***********************************************************************
 *				ExprCombine
 ***********************************************************************
 * SYNOPSIS:	    Combine two results into a single address.
 * CALLED BY:	    Expr_Eval (EXPR_PLUS or EXPR_MINUS)
 * RETURN:	    0 on error (errMsgPtr filled with reason); non-zero
 *	    	    if ok. tos+1 is replaced with the combination.
 *	    	    The caller must pop the rhs.
 * SIDE EFFECTS:    *statusPtr may be altered.
 *
 * STRATEGY:
 * 	This is the bear's behind. We need to combine modrm bytes,
 * 	displacements, etc., making sure that no bogus register
 * 	combinations are coming into play, trimming displacement
 *  	size bits to match displacement size, etc....
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/14/89	Initial Revision
 *
 ***********************************************************************/
static int
ExprCombine(Expr    	*expr,
	    ExprResult	*tos,
	    char    	**errMsgPtr,
	    int	    	flags,
	    byte    	*statusPtr)
{
    ExprResult  *lhs = tos+1;
    ExprResult  *rhs = tos;

    /*
     * If either side is undefined, the result is undefined.
     */
    if (lhs->type == EXPR_TYPE_NAN || rhs->type == EXPR_TYPE_NAN) {
	lhs->type = EXPR_TYPE_NAN;
	lhs->rel.frame = lhs->rel.sym = NULL;
	return(1);
    }

    if (!ExprConvertSym(expr, rhs, errMsgPtr, flags, statusPtr)) {
	return(0);
    }
    if (!ExprConvertSym(expr, lhs, errMsgPtr, flags, statusPtr)) {
	return(0);
    }

    /*
     * For now, segment math is not allowed
     */
    if (rhs->type == EXPR_TYPE_SEGSYM || lhs->type == EXPR_TYPE_SEGSYM)
    {
	*errMsgPtr = "segment arithmetic not allowed";
	return(0);
    }

    /*
     * Addition of relocatable values makes no sense. Catch
     * it now to make life easier later on.
     */
    if (rhs->rel.sym && lhs->rel.sym) {
	*errMsgPtr = "addition of relocatable values illegal";
	return(0);
    }

    /*
     * If either lhs or rhs is a string constant, we need it as
     * a word constant. For whatever reason, MASM places the
     * first character of a two-character constant in the high
     * byte. I don't feel too strongly about this now, but I
     * may later....
     */
    if (!ExprMangleString(expr, lhs, errMsgPtr, flags, statusPtr)) {
	return(0);
    }
    if (!ExprMangleString(expr, rhs, errMsgPtr, flags, statusPtr)) {
	return(0);
    }

    /*
     * Check the type of the LHS and combine properly with the
     * RHS.
     */
    if ((lhs->type == EXPR_TYPE_CONST) &&
	(rhs->type == EXPR_TYPE_CONST))
    {
	/*
	 * Add the two constants together
	 */
	lhs->data.number += rhs->data.number;
	/*
	 * If LHS not relocatable, copy RHS's fixup
	 * info over if it's relocatable (else no point in
	 * copying it, is there?).
	 */
	if (rhs->rel.sym) {
	    lhs->rel = rhs->rel;
	} else if (!lhs->rel.sym && rhs->rel.frame) {
	    /*
	     * Use RHS type info if it has it.
	     */
	    lhs->rel.frame = rhs->rel.frame;
	}
    } else if (rhs->type == EXPR_TYPE_CONST) {
	/*
	 * LHS is EA If RHS is a constant, combination is fairly simple. It's
	 * the combination of two EA's that is hairy.
	 *
	 * Add constant to current displacement and adjust displacement size.
	 */

	if ((lhs->data.ea.modrm & MR_DISP_MASK) == MR_REG) {
	    /*
	     * si+3 is illegal
	     */
	    *errMsgPtr = "need []'s around register";
	    return(0);
	}

	lhs->data.ea.disp   += rhs->data.number;
	/*
	 * If RHS relocatable, use that (if so, LHS isn't relocatable...).
	 */
	if (rhs->rel.sym) {
	    lhs->rel = rhs->rel;
	} else if (rhs->rel.frame) {
	    /*
	     * RHS had type hidden away -- result takes on that type.
	     */
	    lhs->type = (TypePtr)rhs->rel.frame;
	}
	/*
	 * Set displacement size after setting lhs->rel, as that affects
	 * the displacment size used.
	 */
	ExprSetDispSize(lhs, *statusPtr & EXPR_STAT_DELAY);
    } else {
	/*
	 * lhs may be a constant. Convert it to an effective address first
	 * to make life easier.
	 */
	if (!ExprIndirect(expr, lhs, errMsgPtr, flags, statusPtr)) {
	    return(0);
	}

	/*
	 * If either ea is a register, they can't combine.
	 */
	if (((lhs->data.ea.modrm & MR_DISP_MASK) == MR_REG) ||
	    ((rhs->data.ea.modrm & MR_DISP_MASK) == MR_REG))
	{
	    *errMsgPtr = "need []'s around register";
	    return(0);
	}

	/*
	 * Both ea's must have the same addressing mode. The only exception
	 * is if one was a 16-bit constant (MR_DIRECT), in which case it can
	 * become a 32-bit constant (MR_DIRECT32).
	 */
	if ((lhs->data.ea.dword_ea && !(rhs->data.ea.dword_ea)) ||
	    (!(lhs->data.ea.dword_ea) && rhs->data.ea.dword_ea))
	{
	    if (!(lhs->data.ea.dword_ea) && lhs->data.ea.modrm == MR_DIRECT) {
		lhs->data.ea.modrm = MR_DIRECT32;
		lhs->data.ea.dword_ea = 1;
	    } else if (!(rhs->data.ea.dword_ea) &&
		       rhs->data.ea.modrm == MR_DIRECT) {
		rhs->data.ea.modrm = MR_DIRECT32;
		rhs->data.ea.dword_ea = 1;
	    } else {
		*errMsgPtr = "cannot mix 16-bit and 32-bit address modes";
		return(0);
	    }
	}

	/*
	 * If either is a directly-addressed something, treat
	 * it as a constant. The places to which we leap
	 * understand these things...
	 *
	 * We prefer to use the segment override from the rhs
	 * of the equation (WHY?), but if the lhs has an
	 * override and the rhs doesn't, we use the lhs's override
	 */
	if ((!(lhs->data.ea.dword_ea) && lhs->data.ea.modrm == MR_DIRECT) ||
	    ((lhs->data.ea.dword_ea) && lhs->data.ea.modrm == MR_DIRECT32)) {
	    /*
	     * If RHS relocatable, use that (if so, LHS
	     * isn't relocatable...).
	     */
	    if (rhs->rel.sym) {
		lhs->rel = rhs->rel;
	    }
	    /*
	     * Combine the displacements. The modrm of the combination is
	     * taken from the RHS. If the RHS is also MR_DIRECT, the
	     * result is still MR_DIRECT. If the RHS is register-indirect,
	     * the result should still be indirect, but the displacement
	     * size may have changed.
	     */
	    lhs->data.ea.disp += rhs->data.ea.disp;
	    lhs->data.ea.modrm = rhs->data.ea.modrm;
	    if (rhs->data.ea.override) {
		lhs->data.ea.override = rhs->data.ea.override;
	    }
	    ExprSetDispSize(lhs, *statusPtr & EXPR_STAT_DELAY);

	    /*
	     * If rhs is typed, we choose that, else just
	     * stick to the one we have. E.g.
	     *
	     *  	comData[bx]
	     *
	     * where comData is an array of bytes will cause us
	     * to continue using the byte array type ([bx] is
	     * of type NULL), while
	     *
	     *  	buffer.headPtr
	     *
	     * where buffer is a structure and headPtr is an
	     * nptr in the structure, will make the result be
	     * an nptr.
	     */
	    if (rhs->type != NULL) {
		lhs->type = rhs->type;
	    }
	} else if ((!(rhs->data.ea.dword_ea) && rhs->data.ea.modrm == MR_DIRECT) ||
		   ((rhs->data.ea.dword_ea) && rhs->data.ea.modrm == MR_DIRECT32)) {
	    /*
	     * Similar to above, except lhs keeps its modrm, barring
	     * displacement size change, of course.
	     */
	    lhs->data.ea.disp += rhs->data.ea.disp;
	    if (rhs->data.ea.override) {
		lhs->data.ea.override = rhs->data.ea.override;
	    }
	    if (rhs->rel.sym) {
		lhs->rel = rhs->rel;
	    }
	    ExprSetDispSize(lhs, *statusPtr & EXPR_STAT_DELAY);

	    /*
	     * Similar to above...
	     */
	    if (rhs->type != NULL) {
		lhs->type = rhs->type;
	    }
	} else {
	    if (!(lhs->data.ea.dword_ea)) {
		/*
		 * Register/register combination. Use a bi-level switch to
		 * deal with the various combinations.
		 */
		switch (lhs->data.ea.modrm & MR_RM_MASK) {
		case MR_BX_SI:
		case MR_BX_DI:
		case MR_BP_SI:
		case MR_BP_DI:
		    *errMsgPtr = "invalid register combination";
		    return(0);
		case MR_BX:
		    switch(rhs->data.ea.modrm & MR_RM_MASK) {
			case MR_SI:
			    lhs->data.ea.modrm = MR_BX_SI;
			    break;
			case MR_DI:
			    lhs->data.ea.modrm = MR_BX_DI;
			    break;
			default:
			    *errMsgPtr = "invalid register combination";
			    return(0);
		    }
		    break;
		case MR_BP:
		    switch(rhs->data.ea.modrm & MR_RM_MASK) {
			case MR_SI:
			    lhs->data.ea.modrm = MR_BP_SI;
			    break;
			case MR_DI:
			    lhs->data.ea.modrm = MR_BP_DI;
			    break;
			default:
			    *errMsgPtr = "invalid register combination";
			    return(0);
		    }
		    break;
		case MR_DI:
		    switch(rhs->data.ea.modrm & MR_RM_MASK) {
			case MR_BX:
			    lhs->data.ea.modrm = MR_BX_DI;
			    break;
			case MR_BP:
			    lhs->data.ea.modrm = MR_BP_DI;
			    break;
			default:
			    *errMsgPtr = "invalid register combination";
			    return(0);
		    }
		    break;
		case MR_SI:
		    switch(rhs->data.ea.modrm & MR_RM_MASK) {
			case MR_BX:
			    lhs->data.ea.modrm = MR_BX_SI;
			    break;
			case MR_BP:
			    lhs->data.ea.modrm = MR_BP_SI;
			    break;
			default:
			    *errMsgPtr = "invalid register combination";
			    return(0);
		    }
		    break;
		}
	    } else {
		/*
		 * 32-bit register combinations, a.k.a. life made easy.
		 * Any register combination can be made, barring the
		 * exception that ESP cannot be used as an index
		 * register and therefore cannot be combined with itself.
		 */
		if ((rhs->data.ea.modrm & MR_RM_MASK) == REG_ESP) {
		    if ((lhs->data.ea.modrm & MR_RM_MASK) == REG_ESP) {
			*errMsgPtr = "invalid register combination";
			return(0);
		    } else {
			lhs->data.ea.sib = (rhs->data.ea.modrm & MR_RM_MASK) |
			    ((lhs->data.ea.modrm & MR_RM_MASK) << SIB_INDEX_SHIFT);
			lhs->data.ea.modrm = MR_SIB;
		    }
		} else {
		    lhs->data.ea.sib = (lhs->data.ea.modrm & MR_RM_MASK) |
			((rhs->data.ea.modrm & MR_RM_MASK) << SIB_INDEX_SHIFT);
		    lhs->data.ea.modrm &= ~MR_RM_MASK;
		    lhs->data.ea.modrm |= MR_SIB;
		}
 	    }
	    /*
	     * If RHS is relocatable or has a type, the result
	     * takes them on (if RHS relocatable, LHS isn't).
	     */
	    if (rhs->rel.sym) {
		lhs->rel = rhs->rel;
	    }
	    if (rhs->type) {
		lhs->type = rhs->type;
	    }
	    /*
	     * Add the two displacements and adjust the size accordingly.
	     * Must do this *after* possibly copying over rhs->rel.sym, else
	     * ExprSetDispSize won't notice that the thing requires a word
	     * displacement to account for the relocation.
	     */
	    lhs->data.ea.disp += rhs->data.ea.disp;
	    ExprSetDispSize(lhs, *statusPtr & EXPR_STAT_DELAY);
	}
    }
    return(1);
}

/***********************************************************************
 *				ExprDotCombine
 ***********************************************************************
 * SYNOPSIS:	    Preprocessing of operands that are to be added with
 *	    	    the dot operator. Makes certain the rhs is a field
 *	    	    of the lhs (unless the lhs is typeless, of course).
 * CALLED BY:	    Expr_Eval
 * RETURN:	    zero on error, with *errMsgPtr filled in.
 * SIDE EFFECTS:    If successful, tos[1] filled with the result.
 *
 * STRATEGY:
 *	Check for rhs being a field. If so and lhs is typed, make sure
 *	the rhs is a field in the lhs's type. If not, print a warning.
 *
 *	Finally, pass all operands to ExprCombine, returning its result.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/89	Initial Revision
 *
 ***********************************************************************/
static int
ExprDotCombine(Expr    	    *expr,
	       ExprResult   *tos,
	       char    	    **errMsgPtr,
	       int	    flags,
	       byte    	    *statusPtr)
{
    /*
     * If either side is undefined, the result is undefined.
     */
    if (tos[1].type == EXPR_TYPE_NAN || tos->type == EXPR_TYPE_NAN) {
	tos[1].type = EXPR_TYPE_NAN;
	tos[1].rel.frame = tos[1].rel.sym = NULL;
	return(1);
    }

    if ((tos->type == EXPR_TYPE_SYM) &&
	((tos->data.sym->type == SYM_FIELD) ||
	 (tos->data.sym->type == SYM_INSTVAR)))
    {
	SymbolPtr   field = tos->data.sym;

	/*
	 * Advance to the containing structure.
	 */
	while ((field->type == SYM_FIELD) ||
	       (field->type == SYM_INSTVAR))
	{
	    field = field->u.field.common.next;
	}

	if (field->type == SYM_STRUCT) {
	    TypePtr	    ltype;  	/* Type from lhs against which to
					 * check */
	    char	    *msg;   	/* Message to print if mismatch */
	    ID  	    id;	    	/* Extra ID parameter if required */

	    ltype = NULL;
	    msg = "%i not a field in given expression";
	    id = NullID;

	    if (tos[1].type == EXPR_TYPE_SYM) {
		SymbolPtr   sym;

		sym = tos[1].data.sym;

		switch(sym->type) {
		    case SYM_VAR:
			ltype = sym->u.var.type;
			break;
		    case SYM_CHUNK:
			ltype = sym->u.chunk.type;
			break;
		    case SYM_STRUCT:
			ltype = Type_Struct(sym);
			break;
		    case SYM_TYPE:
			ltype = sym->u.typeDef.type;
			break;
		    case SYM_FIELD:
			ltype = sym->u.field.type;
			break;
		    case SYM_INSTVAR:
			ltype = sym->u.instvar.type;
			break;
		    case SYM_LOCAL:
			ltype = sym->u.localVar.type;
			break;
		}

		msg = "%i not a field in %i";
		id = sym->name;
	    } else if (tos[1].type == EXPR_TYPE_TYPE) {
		ltype = tos[1].data.type;
		msg = "%i not a field in given type";
	    } else if (tos[1].type == EXPR_TYPE_CONST) {
		if (tos[1].rel.frame) {
		    ltype = (TypePtr)tos[1].rel.frame;
		    msg = "%i not a field in given field/instance variable";
		}
	    } else {
		ltype = tos[1].type;
	    }
	    if (ltype) {
		while (ltype->tn_type == TYPE_ARRAY) {
		    ltype = ltype->tn_u.tn_array.tn_base;
		}
		if ((ltype->tn_type != TYPE_STRUCT) ||
		    (ltype->tn_u.tn_struct != field))
		{
		    Notify(NOTIFY_WARNING, expr->file, expr->line,
			   msg, tos->data.sym->name, id);
		}
	    }
	}
    }
    /*
     * Now perform the needed combination.
     */
    return (ExprCombine(expr, tos, errMsgPtr, flags, statusPtr));
}

byte ExprGetDefaultSegment(ExprResult *result)
{
    byte defSeg;

    if (!result->data.ea.dword_ea) {
	if (result->data.ea.modrm == MR_DIRECT) {
	    defSeg = REG_DS; /* Direct addressing always off DS */
	} else {
	    switch(result->data.ea.modrm & MR_RM_MASK) {
	    case MR_BX_SI:
	    case MR_BX_DI:
	    case MR_SI:
	    case MR_DI:
	    case MR_BX:
		defSeg = REG_DS;
		break;
	    default:
		defSeg = REG_SS;
		break;
	    }
	}
    } else {
	/* When ESP or EBP is used as the base register, the default segment
	 * is SS. In all other cases the default segment is DS. */
	defSeg = REG_DS;	/* Assume DS */

	if (result->data.ea.modrm != MR_DIRECT32 &&
	    (result->data.ea.modrm != MR_SIB ||
	     (result->data.ea.sib & SIB_BASE_MASK) != SIB_NO_BASE) &&
	    ((result->data.ea.modrm & MR_RM_MASK) == REG_EBP ||
		((result->data.ea.modrm & MR_RM_MASK) == MR_SIB &&
		 ((result->data.ea.sib & SIB_BASE_MASK) == REG_EBP ||
		  (result->data.ea.sib & SIB_BASE_MASK) == REG_ESP))))
		defSeg = REG_SS;
    }
    return defSeg;
}


/***********************************************************************
 *				Expr_Eval
 ***********************************************************************
 * SYNOPSIS:	    Evaluate a parsed expression
 * CALLED BY:	    EXTERNAL
 * RETURN:	    0 on error.
 * SIDE EFFECTS:    EXPR_IDENT's are replaced with EXPR_SYMOP's if possible.
 *	    	    EXPR_SYMOP's are mapped to EXPR_SEGSYM_[ESDC]S's if
 *	    	    they are in the 'segments' array.
 *
 * STRATEGY:	    Since the expressions are stored in postfix order,
 *	    	    we have to maintain a stack of ExprResult's (which
 *	    	    is expanded if necessary) that holds partial results.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/10/89		Initial Revision
 *
 ***********************************************************************/
int
Expr_Eval(Expr      	*expr,	    	/* Expression to evaluate */
	  ExprResult 	*result,    	/* Place to store result */
	  int    	flags,   	/* Flags to control eval. See
					 * expr.h */
	  byte	    	*statusPtr)    	/* Set to OR of EXPR_STAT flags to
					 * indicate status of the evaluation */
{
#define EXPR_DEF_STACK	32  /* Initial size for partial results */
    ExprResult	defStack[EXPR_DEF_STACK];
    ExprResult	*stackBase; 	    	/* base of result stack */
    ExprResult	*tos;	    	    	/* Top-most element of same */
    int	    	stackSize;  	    	/* Number of elements in same */
    ExprElt 	*elt;	    	    	/* Current element in expression */
    int	    	n;  	    	    	/* Number of elements remaining */
    Expr    	junk;	    	    	/* Junk expression for compressing
					 * out EXPR_IDENTs using
					 * Expr_NextPart */
    int	    	retVal = 1; 	    	/* Value to return -- default to
					 * success */
    char    	*errMsg;    	    	/* Message to return on error */
    byte    	status = 0; 	    	/* Current status. For now, either
					 * 0 or EXPR_STAT_DELAY, until the
					 * end. */

    /*
     * Macro to make room for a new element at the top of the stack. Resizes
     * the stack as necessary. To make life easier, tos starts at the end of
     * the stack array and works down. Allows us to not have an 'endStack'
     * but does force us to always copy the data. However, we don't expect
     * expressions to be all that complex and EXPR_DEF_STACK is very generous.
     * Initializes the new element to be non-relocatable.
     */
#define Push() \
    if (--tos < stackBase) {\
	ExprResult *newStack;\
\
	stackSize += EXPR_DEF_STACK;\
	newStack = (ExprResult *)malloc(stackSize * sizeof(ExprResult));\
	bcopy(stackBase, (newStack+EXPR_DEF_STACK),\
	      (stackSize-EXPR_DEF_STACK)*sizeof(ExprResult));\
	tos = newStack + EXPR_DEF_STACK-1;\
	if (stackBase != defStack) {\
	    free((char *)stackBase);\
	}\
	stackBase = newStack;\
    }\
    tos->rel.sym = NULL

    /*
     * Initialize the result stack.
     */
    stackSize = EXPR_DEF_STACK;
    stackBase = defStack;
    tos = defStack+stackSize;

#define ExprError(msg)	errMsg = msg; retVal = 0; goto finish
#define ASSERT_386()	if (!(procType & PROC_80386)) {\
	ExprError("80386-register/addressing form not supported by current processor"); }
    /*
     * Initialize loop variables
     */
    n = expr->numElts; elt = expr->elts;

    if (elt->op == EXPR_UNDEF) {
	result->type = (TypePtr)"undefined";
	return(0);
    }

    /*
     * To deal with multiple symbols in an expression being undefined, we
     * keep a buffer in which the symbols are entered, separated by commas.
     * undefErr tracks whether any undefineds were found.
     */
    ExprUndefInit();


    /*
     * Compress out EXPR_IDENT operators
     */
    if (expr->idents) {
	junk.elts = NULL;
	Expr_NextPart(expr, &junk, flags & EXPR_NOUNDEF);

	if (!junk.idents) {
	    /*
	     * Mark the original expression as having no identifiers in case
	     * the thing needs to be evaluated again later.
	     */
	    expr->idents = 0;
	} else if (!(flags & EXPR_NOUNDEF) && !junk.musteval && statusPtr) {
	    /*
	     * If undefined's are allowed and there are some in the expression,
	     * there's not much point in going on -- the caller will take one
	     * look at the missing EXPR_STAT_DEFINED flag and give up until
	     * pass2 (XXX: IF THIS EVER CHANGES WE'LL BE IN TROUBLE. AS OF
	     * NOW [11/9/89] THIS IS TRUE). So just return now as if we'd
	     * gone through everything...
	     *
	     * If Expr_NextPart says we must evaluate it, or if undefined
	     * symbols are an error, or if the caller hasn't given us a
	     * way to tell it there's something undefined, we can't
	     * do this but must evaluate the whole thing.
	     *
	     * Otherwise, we return a status byte of 0 and say the expression
	     * itself is ok...at least until the next pass :)
	     */
	    *statusPtr = 0;
	    return(1);
	}
    }


    while (n > 0) {
	switch(elt->op) {
/*
 * Take care of the easy parts first -- the terms
 */
	    case EXPR_DWORDREG:
		ASSERT_386();		/* 32-bit registers are 386-only */
		/*
		 * Straight dword register -- make up modrm byte for
		 * it. Everything else is 0. type is int(4) to indicate
		 * dword
		 */
		elt++;
		Push();
		tos->type = Type_Int(4);
		tos->data.ea.disp = 0;
		tos->data.ea.override = 0;
		tos->data.ea.modrm = 0xc0 | elt->reg;
		tos->data.ea.dword_ea = 0;
		tos->data.ea.sib = 0;
		elt++;
		n -= 2;
		break;
	    case EXPR_WORDREG:
		/*
		 * Straight word register -- make up modrm byte for
		 * it. Everything else is 0. type is int(2) to indicate
		 * word
		 */
		elt++;
		Push();
		tos->type = Type_Int(2);
		tos->data.ea.disp = 0;
		tos->data.ea.override = 0;
		tos->data.ea.modrm = 0xc0 | elt->reg;
		tos->data.ea.dword_ea = 0;
		tos->data.ea.sib = 0;
		elt++;
		n -= 2;
		break;
	    case EXPR_BYTEREG:
		/*
		 * Straight byte register -- make up modrm byte for
		 * it. Everything else is 0. type is int(1) to indicate
		 * byte
		 */
		elt++;
		Push();
		tos->type = Type_Int(1);
		tos->data.ea.disp = 0;
		tos->data.ea.override = 0;
		tos->data.ea.modrm = 0xc0 | elt->reg;
		tos->data.ea.dword_ea = 0;
		tos->data.ea.sib = 0;
		elt++;
		n -= 2;
		break;
	    case EXPR_SEGREG:
		/*
		 * Segment register -- tos becomes a type-less thing with
		 * only the data.ea.override filled in to indicate the
		 * register and data.ea.dword_ea to indicate the assumed
		 * operand size (as the 80386 can treat a segment register
		 * as a 32-bit register).
		 */
		elt++;
		Push();
		if (elt->reg >= REG_FS)		/* FS and GS are 386-only */
		    ASSERT_386();

		tos->type = NULL;
		tos->data.ea.disp = 0;
		tos->data.ea.override = OVERRIDE(elt->reg);
		tos->data.ea.modrm = MR_SEGREG;
		tos->data.ea.dword_ea = 0;	/* XXX: Set for USE32 code */
		tos->data.ea.sib = 0;
		elt++;
		n -= 2;
		break;
	    case EXPR_INDREG:
		/*
		 * Indirect register. Only four word registers are allowed.
		 * Create the proper modrm byte for the thing. Note that
		 * for BP, we need to use a byte displacement of 0. Since
		 * there's no rel.sym component, however, we know later
		 * on that we can nuke the displacement if BP is combined
		 * with something else.
		 */
		elt++;
		Push();
		switch(elt->reg) {
		    case REG_BX:
			tos->data.ea.modrm = 0x07;
			break;
		    case REG_SI:
			tos->data.ea.modrm = 0x04;
			break;
		    case REG_DI:
			tos->data.ea.modrm = 0x05;
			break;
		    case REG_BP:
			tos->data.ea.modrm = 0x46;
			break;
		    default:
			ExprError("invalid register indirection");
		}
		tos->type = NULL;
		tos->data.ea.disp = tos->data.ea.override = 0;
		tos->data.ea.dword_ea = 0;
		tos->data.ea.sib = 0;
		elt++;
		n -= 2;
		break;
	    case EXPR_EINDREG:
		/*
		 * Indirect dword register. All dword registers are allowed.
		 * Create the proper modrm byte for the thing. Note that for
		 * EBP, we need to use a byte displacement of 0. Since there's
		 * no rel.sym component, however, we know later on that we can
		 * nuke the displacement if EBP is combined with something else.
		 */
		elt++;
		Push();
		tos->data.ea.modrm = elt->reg;
		if (elt->reg == REG_EBP)
		    tos->data.ea.modrm |= MR_BYTE_DISP;
		tos->type = NULL;
		tos->data.ea.disp = tos->data.ea.override = 0;
		tos->data.ea.sib = 0;
		tos->data.ea.dword_ea = 1;
		elt++;
		n -= 2;
		break;
	    case EXPR_SYMOP:
		/*
		 * We delay evaluation of symbols until the last possible
		 * moment, since certain operators require to know the
		 * type of the symbol involved. ExprConvertSym does the
		 * actual conversion of symbol to value for most operators.
		 */
		elt++;
		Push();
		if (elt->sym->type == SYM_SEGMENT ||
		    elt->sym->type == SYM_GROUP)
		{
		    tos->type = EXPR_TYPE_SEGSYM;
		    tos->data.elt = elt-1;
		} else {
		    assert(elt->sym->type != SYM_PUBLIC);
		    tos->type = EXPR_TYPE_SYM;
		    tos->data.sym = elt->sym;
		    if (!(flags & EXPR_NOREF)) {
			Sym_Reference(elt->sym);
		    }
		}
		elt++;
		n -= 2;
		break;
	    case EXPR_SEGSYM_ES:
	    case EXPR_SEGSYM_DS:
	    case EXPR_SEGSYM_CS:
	    case EXPR_SEGSYM_SS:
	    case EXPR_SEGSYM_FS:
	    case EXPR_SEGSYM_GS:
		/*
		 * Same as a SYM with a segment, but we know the segment
		 * register -- we'll use that knowledge in the OVERRIDE
		 * operator.
		 */
		Push();
		tos->type = EXPR_TYPE_SEGSYM;
		tos->data.elt = elt;
		elt += 2;
		n -= 2;
		break;
	    case EXPR_CONST:
		elt++;
		Push();
		tos->type = EXPR_TYPE_CONST;
		tos->rel.frame = NULL;
		tos->data.number = elt->value;
		elt++;
		n -= 2;
		break;
	    case EXPR_FLOATSTACK:
		elt++;
		Push();
		tos->type = EXPR_TYPE_FLOATSTACK;
		tos->rel.frame = NULL;
		tos->data.number = elt->value;
		elt++;
		n -= 2;
		break;
	    case EXPR_IDENT:
		/*
		 * If still an IDENT, must be undefined (would have been
		 * compressed out by Expr_NextPart).
		 */

		/*
		 * Push NaN
		 */
		Push();
		tos->type = EXPR_TYPE_NAN;
		tos->rel.frame = tos->rel.sym = NULL;

		ExprUndefAdd(elt[1].ident);

		/*
		 * Skip over the thing
		 */
		elt += 2;
		n -= 2;
		break;
	    case EXPR_INIT:
	    case EXPR_STRING:
	    {
		/*
		 * String constant -- point the top-most element at the
		 * embeded string and skip over the thing.
		 *
		 * NOTE: CodeCleanup() in code.c relies on our always returning
		 * data.str pointing into the array of elements. If we ever
		 * change this, that macro will have to change lest it free
		 * something it shouldn't.
		 */
		int nelts;

		Push();
		tos->type = EXPR_TYPE_STRING;
		tos->rel.frame = NULL;
		tos->data.str = elt[1].str;

		nelts = ExprStrElts(elt[1].str);
		elt += nelts+1;
		n -= nelts+1;
		break;
	    }
	    case EXPR_TYPE:
		/*
		 * Type description for casting or something else -- create
		 * a TYPE intermediate result.
		 */
		Push();
		tos->type = EXPR_TYPE_TYPE;
		tos->data.type = elt[1].type;
		elt += 2;
		n -= 2;
		break;
/*
 * Yrgg. Now the operators themselves.
 */
	    case EXPR_NEG:
	    case EXPR_NOT:
		/*
		 * Unary operators that can operate only on a constant
		 */
		retVal = ExprConstUnOp(expr, elt->op, tos, &errMsg, flags,
				       &status);
		if (!retVal) {
		    goto finish;
		}
		elt++;
		n--;
		break;
	    case EXPR_EQ:
	    case EXPR_NEQ:
	    case EXPR_LT:
	    case EXPR_GT:
	    case EXPR_LE:
	    case EXPR_GE:
		retVal = ExprRelOp(expr, elt->op, tos+1, tos, &errMsg,
				   flags, &status);
		if (!retVal) {
		    goto finish;
		}
		tos++;	/* POP */
		elt++;
		n--;
		break;
	    case EXPR_TIMES:
	    case EXPR_DIV:
	    case EXPR_OR:
	    case EXPR_XOR:
	    case EXPR_AND:
	    case EXPR_SHL:
	    case EXPR_SHR:
	    case EXPR_MOD:
	    case EXPR_FMASK:
		/*
		 * Binary operators that can operate only on two constants
		 */
		retVal = ExprConstBinOp(expr, elt->op, tos+1, tos, &errMsg,
					flags, &status);
		if (!retVal) {
		    goto finish;
		}
		tos++;	/* POP */
		elt++;
		n--;
		break;
	    case EXPR_MINUS:
		if (!ExprSubtract(expr, tos, &errMsg, flags, &status)) {
		    retVal = 0;
		    goto finish;
		}
		/*
		 * Pop top-most element since not needed...
		 */
		tos++;		/* Pop */
		elt++, n--;
		break;
	    case EXPR_DOT:
		if (warn_field) {
		    if (!ExprDotCombine(expr, tos, &errMsg, flags, &status)) {
			retVal = 0;
			goto finish;
		    }
		    tos++;
		    elt++, n--;
		    break;
		}
		/*FALLTHRU*/
	    case EXPR_PLUS:
		if (!ExprCombine(expr, tos, &errMsg, flags, &status)) {
		    retVal = 0;
		    goto finish;
		}
		/*
		 * Pop top-most element since not needed...
		 */
		tos++;		/* Pop */
		elt++, n--;
		break;
	    case EXPR_ENUM:
		if (tos->type == EXPR_TYPE_NAN) {
		    /* result is NaN */ ;
		} else if (tos->type != EXPR_TYPE_SYM) {
		    ExprError("invalid operand of ENUM");
		} else {
		    switch(tos->data.sym->type) {
			case SYM_VAR:
			case SYM_LABEL:
			case SYM_PROC:
			case SYM_CLASS:
			case SYM_CHUNK:
			    tos->type = EXPR_TYPE_CONST;
			    tos->rel.sym = tos->data.sym;
			    tos->rel.frame = tos->data.sym->segment;
			    tos->rel.pcrel = 0;
			    tos->rel.fixed = 0;
			    tos->rel.size = FIX_SIZE_WORD;
			    tos->rel.type = FIX_ENTRY;
			    tos->data.number = 0;
			    break;
			default:
			    ExprError("invalid operand of ENUM");
			    break;
		    }
		}
		elt++, n--;
		break;
	    case EXPR_OFFSET:
		switch ((int)tos->type) {
		    case (int)EXPR_TYPE_NAN:
			/* result remains NaN */
			break;
		    case (int)EXPR_TYPE_CONST:
			if (tos->rel.frame) {
			    /*
			     * Constant comes from a structure field. We're
			     * *happy* to allow the user to ask for the offset
			     * of the thing, even if s/he can get the thing
			     * by just using the field name.
			     */
			    break;
			}
		    case (int)EXPR_TYPE_STRING:
		    case (int)EXPR_TYPE_SEGSYM:
		    case (int)NULL:
			ExprError("invalid operand of OFFSET");
		    default:
			if (tos->data.ea.modrm != 0x06) {
			    /*
			     * Direct addressing only -- what's the offset
			     * of ds:[bx].VCI_winHandle?
			     */
			    ExprError("invalid operand of OFFSET");
			}
			tos->data.number = tos->data.ea.disp;
			tos->type = EXPR_TYPE_CONST;
			break;
		    case (int)EXPR_TYPE_SYM:
			switch(tos->data.sym->type) {
			    case SYM_BITFIELD:
				tos->data.number =
				    tos->data.sym->u.bitField.offset;
				tos->rel.frame = NullSymbol;
				tos->type = EXPR_TYPE_CONST;
				break;
			    case SYM_FIELD:
				tos->rel.frame =
				    (SymbolPtr)tos->data.sym->u.field.type;
				tos->data.number =
				    tos->data.sym->u.field.offset;
				tos->type = EXPR_TYPE_CONST;
				break;
			    case SYM_INSTVAR:
				tos->rel.frame =
				    (SymbolPtr)tos->data.sym->u.instvar.type;
				tos->data.number =
				    tos->data.sym->u.instvar.offset;
				tos->type = EXPR_TYPE_CONST;
				break;
			    case SYM_VAR:
			    case SYM_LABEL:
			    case SYM_LOCALLABEL:
			    case SYM_PROC:
			    case SYM_CLASS:
			    case SYM_CHUNK: 	/* XXX */
			    {
				Symbol	*seg;

				tos->type = EXPR_TYPE_CONST;
				tos->rel.pcrel = 0;
				tos->rel.fixed = 0;
				tos->rel.size = FIX_SIZE_WORD;
				tos->rel.type = FIX_OFFSET;
				seg = tos->data.sym->segment;
#if 0
				if (seg->u.segment.data->comb ==
				    SEG_ABSOLUTE)
				{
				    /*
				     * If in absolute segment, there's nothing
				     * to relocate, so store the offset
				     * in the thing and mark the result
				     * non-relocatable.
				     */
				    tos->rel.sym = NULL;
				    tos->data.number =
					ExprSymOffset(tos->data.sym);
				    tos->rel.frame = NULL;
				} else {
#endif
				    /*
				     * Use value 0 -- linker will fill in real
				     * value
				     */
				    tos->rel.sym = tos->data.sym;
				    tos->data.number = 0;
				    /*
				     * Default to offset from group if
				     * enclosing segment is in a group.
				     */
				    if (!masmCompatible &&
					seg->segment &&
					seg->segment->type == SYM_GROUP)
				    {
					seg = seg->segment;
				    }
				    tos->rel.frame = seg;
				}
				break;
#if 0
			    }
#endif
			    case SYM_LOCAL:
				tos->rel.frame =
				    (SymbolPtr)tos->data.sym->u.localVar.type;
				tos->data.number =
				    tos->data.sym->u.localVar.offset;
				tos->type = EXPR_TYPE_CONST;
				break;
			    default:
				assert(tos->data.sym->type != SYM_PUBLIC);
				ExprError("invalid operand of OFFSET");
			}
		}
		elt++, n--;
		break;
	    case EXPR_HIGH:
	    case EXPR_LOW:
	    {
		void	*tp;

		if (!ExprConvertSym(expr, tos, &errMsg, flags, &status)) {
		    retVal = 0;
		    goto finish;
		}

		tp = (void *)&(tos->type);
		switch(*(long *)tp)
		{
		    case (int)EXPR_TYPE_NAN:
			/* result remains NaN */
			break;
		    case (int)EXPR_TYPE_CONST:
			if (elt->op == EXPR_HIGH) {
			    tos->data.number >>= 8;
			}
			/*
			 * If constant is relocatable, adjust fixup type.
			 * NOTE: We allow segments only if they're library
			 * segments, as then it means we're going for the
			 * major or minor protocol number we expect for the
			 * thing.
			 */
			if (tos->rel.sym) {
			    if ((tos->rel.sym->type == SYM_SEGMENT &&
				 tos->rel.sym->u.segment.data->comb !=
				 SEG_LIBRARY) ||
				(tos->rel.sym->type == SYM_GROUP))
			    {
				goto invalid_high_low_operand;
			    }
			    tos->rel.type =
				((elt->op == EXPR_HIGH) ? FIX_HIGH_OFFSET :
				 FIX_LOW_OFFSET);
			    /*
			     * Set the size of the fixup, please. For major /
			     * minor protocol number stuff (symbol is a segment)
			     * it is a word. For all other things, it's a byte.
			     */
			    tos->rel.size =
				(tos->rel.sym->type == SYM_SEGMENT) ?
				    FIX_SIZE_WORD : FIX_SIZE_BYTE;
			}
			tos->data.number &= 0xff;
			break;
		    case (int)EXPR_TYPE_STRING:
			/*
			 * XXX: This ordering is weird, but it's what MASM
			 * does...
			 */
			if (elt->op == EXPR_HIGH) {
			    tos->data.number = tos->data.str[0];
			} else {
			    tos->data.number = tos->data.str[1];
			}
			tos->type = EXPR_TYPE_CONST;
			tos->rel.frame = NullSymbol;
			break;
		    default:
			if (tos->data.ea.modrm == MR_DIRECT) {
			    /*
			     * Only direct addressing is permitted here.
			     * Nothing involving registers or anything like
			     * that.
			     */
			    if (elt->op == EXPR_HIGH) {
				tos->data.ea.disp >>= 8;
				tos->rel.type = FIX_HIGH_OFFSET;
			    } else {
				tos->rel.type = FIX_LOW_OFFSET;
			    }
			    tos->rel.size = FIX_SIZE_BYTE;
			    tos->data.number = tos->data.ea.disp & 0xff;
			    tos->type = EXPR_TYPE_CONST;
			    break;
			}
			/*FALLTHRU*/
		    case (int)NULL:
		    invalid_high_low_operand:
			if (elt->op == EXPR_HIGH) {
			    ExprError("invalid operand of HIGH");
			} else {
			    ExprError("invalid operand of LOW");
			}
		}
		elt++, n--;
	    }
		break;
	    case EXPR_TYPEOP:
	    {
		/*
		 * "If expression evaluates to a variable, the operator
		 * returns the number of bytes in each data object in the
		 * variable. If expression evaluates to a structure or
		 * structure variable, the operator returns the number
		 * of bytes in the structure. If expression is a label,
		 * the operator returns 0ffffh for NEAR labels and
		 * 0fffeh for FAR labels. If expression is a constant,
		 * the operator returns 0" -- that about sums it up.
		 */
		TypePtr	type;

		if (tos->type == EXPR_TYPE_NAN) {
		    /* result remains NaN */;
		} else if (masmCompatible &&
		    (tos->type != NULL) &&
		    (tos->type != EXPR_TYPE_CONST) &&
		    (tos->type != EXPR_TYPE_STRING) &&
		    (tos->type != EXPR_TYPE_TYPE) &&
		    ((tos->data.ea.modrm & MR_DISP_MASK) == MR_REG))
		{
		    /*
		     * Masm gives a value of zero for TYPE <reg>
		     */
		    tos->data.number = 0;
		    tos->type = EXPR_TYPE_CONST;
		    tos->rel.sym = NULL;
		    tos->rel.frame = NULL;
		} else if ((tos->type == EXPR_TYPE_CONST) &&
			   (tos->rel.sym) &&
			   (tos->rel.type == FIX_SEGMENT) &&
			   (tos->rel.sym->type != SYM_GROUP))
		{
		    /*
		     * OPERATOR ABUSE: (sorry "overloading"...every day
		     * in every way this language is getting closer to C++)
		     *
		     * Anyway. It has proven useful to be able to determine
		     * the combine type of a segment (or rather, the segment
		     * containing something). To facilitate this, applying
		     * the TYPE operator to a segment yields its combine type.
		     */
		    if (tos->rel.sym->type == SYM_SEGMENT) {
			tos->data.number = tos->rel.sym->u.segment.data->comb;
		    } else {
			tos->data.number =
			    tos->rel.sym->segment->u.segment.data->comb;
		    }

		    tos->rel.sym = tos->rel.frame = NULL;
		} else if (!(flags & EXPR_NOUNDEF) &&
			   ExprIsGlobalUndef(expr, tos, &errMsg, flags,
					     &status))
		{
		    /*
		     * Delay evaluation of something that's global and undefined
		     * until pass 2, at which point we allow it.
		     */
		    tos->type = EXPR_TYPE_NAN;
		    tos->rel.sym = tos->rel.frame = NULL;
		} else if (ExprExtractType(tos, &type)) {
		    if (type == NULL) {
			ExprError("cannot determine type for TYPE operator");
		    }

		    switch(type->tn_type) {
			case TYPE_NEAR:
			    tos->data.number = -1;
			    break;
			case TYPE_FAR:
			    tos->data.number = -2;
			    break;
			case TYPE_ARRAY:
			    tos->data.number =
				Type_Size(type->tn_u.tn_array.tn_base);
			    break;
			default:
			    tos->data.number = Type_Size(type);
			    break;
		    }
		    tos->type = EXPR_TYPE_CONST;
		    tos->rel.sym = NULL;
		    tos->rel.frame = NULL;
		} else {
		    ExprError("invalid operand of TYPE");
		}
		elt++, n--;
		break;
	    }
	    case EXPR_LENGTH:
	    {
		TypePtr	type;

		if (tos->type == EXPR_TYPE_NAN) {
		    /* result remains NaN */;
		} else if (!(flags & EXPR_NOUNDEF) &&
		    ExprIsGlobalUndef(expr, tos, &errMsg, flags, &status))
		{
		    /*
		     * Delay evaluation of something that's global and undefined
		     * until pass 2, at which point we allow it.
		     */
		    tos->type = EXPR_TYPE_NAN;
		    tos->rel.sym = tos->rel.frame = NULL;
		} else if (ExprExtractType(tos, &type)) {
		    tos->data.number = Type_Length(type);
		    tos->type = EXPR_TYPE_CONST;
		    tos->rel.sym = NULL;
		    tos->rel.frame = NULL;
		} else {
		    ExprError("invalid operand of LENGTH");
		}
		elt++, n--;
 		break;
	    }
	    case EXPR_SIZE:
	    {
		TypePtr	type;

		if (tos->type == EXPR_TYPE_NAN) {
		    /* result remains NaN */;
		} else if (!(flags & EXPR_NOUNDEF) &&
		    ExprIsGlobalUndef(expr, tos, &errMsg, flags, &status))
		{
		    /*
		     * Delay evaluation of something that's global and undefined
		     * until pass 2, at which point we allow it.
		     */
		    tos->type = EXPR_TYPE_NAN;
		    tos->rel.sym = tos->rel.frame = NULL;
		} else if (ExprExtractType(tos, &type)) {
		    if (type == EXPR_TYPE_SEGSYM) {
			/*
			 * PSEUDO-KLUDGE: if finalizing, we set the result
			 * to be the total size of the segment. If not
			 * finalizing, we set it to be the current size but
			 * set the delay flag in the status.
			 */
			SymbolPtr   sym = tos->data.elt[1].sym;

			if (sym->type == SYM_SEGMENT) {
			    /*
			     * Just a segment -- take the size of its code
			     * table
			     */
			    tos->data.number = Table_Size(sym->u.segment.code);
			} else {
			    /*
			     * A group! Need to add the sizes of all its
			     * segments after padding them to their proper
			     * alignment boundary.
			     */
			    SymbolPtr	seg;
			    int	    	k;

			    tos->data.number = 0;
			    for (k = 0; k < sym->u.group.nSegs; k++) {
				seg = sym->u.group.segs[k];

				/*
				 * Add in the size of this segment, padded
				 * to its alignment boundary as the linker
				 * will do.
				 */
				tos->data.number +=
				    (Table_Size(seg->u.segment.code)+
				     seg->u.segment.data->align) &
					 ~seg->u.segment.data->align;
			    }
			}

			if (!(flags & EXPR_FINALIZE)) {
			    status |= EXPR_STAT_DELAY;
			}
			tos->type = EXPR_TYPE_CONST;
			tos->rel.sym = NULL;
			tos->rel.frame = NULL;
		    } else if (type == NULL) {
			ExprError("cannot determine SIZE of operand");
		    } else {
			tos->data.number = Type_Size(type);
			tos->type = EXPR_TYPE_CONST;
			tos->rel.sym = NULL;
			tos->rel.frame = NULL;
		    }
		} else {
		    ExprError("invalid operand of SIZE");
		}
		elt++, n--;
		break;
	    }
/*****************************************************************************/
	    case EXPR_SEGREGOF:
	    {
		int segreg;

		if (tos->type == EXPR_TYPE_NAN) {
		    /* remains NaN */ ;
		} else if (!(flags & EXPR_NOUNDEF) &&
		    ExprIsGlobalUndef(expr, tos, &errMsg, flags, &status))
		{
		    /*
		     * Delay evaluation of something that's global and undefined
		     * until pass 2, at which point we allow it.
		     */
		    tos->type = EXPR_TYPE_NAN;
		    tos->rel.sym = tos->rel.frame = NULL;
		} else if (ExprConvertSym(expr, tos, &errMsg, flags, &status)) {
		    if (ExprExtractSegReg(tos, &segreg)) {
			tos->type = NULL;
			tos->data.ea.disp = 0;
			tos->data.ea.modrm = MR_SEGREG;
			tos->data.ea.override = OVERRIDE(segreg);
			tos->data.ea.dword_ea = 0;
			tos->data.ea.sib = 0;
			tos->rel.sym = NULL;
			status |= EXPR_STAT_REGISTER;
		    } else {
			ExprError("invalid operand of SEGREGOF");
		    }
		} else {
		    ExprError(errMsg);
		}
		elt++, n--;
		break;
	    }
/*****************************************************************************/
	    case EXPR_DOTTYPE:
	    {
		/*
		 *  Position	Meaning if set
		 *  0	    	code-related
		 *  1	    	data-related
		 *  2	    	constant
		 *  3	    	direct addressing
		 *  4	    	register
		 *  5	    	defined
		 *  6	    	delayed result
		 *  7	    	global scope
		 *  High bit semantics based on low bit settings.
		 *
		 * If bit 0 set (code-related expression):
		 *  8	    	near
		 *  9	    	procedure contains ON_STACK symbols
		 *  10	    	may not be jumped to
		 *  11	    	may not be called
		 *  12	    	is a static method handler
		 *  13	    	is a private static method handler
		 *  14	    	is a dynamic method handler
		 *  15	    	is a method handler
		 *
		 * If bit 4 set (register expression):
		 *  8-10    	register number
		 * 11		undefined
		 * 12		undefined
		 * 13		can be used for addressing (bx, si, di, bp)
		 * 14		segment register
		 * 15		byte register
		 *
		 * If bit 2 set (constant):
		 *  8	    	operand is enumerated type-related
		 *  9	    	operand is record type-related
		 * 10	    	operand is struct type-related
		 * 11	    	operand is type itself (modified by bits 8, 9,
		 *		& 10; if none set, operand is typedef)
		 * 12	    	operand is segment/group
		 * 13	    	undefined
		 * 14	    	operand is numeric equate
		 * 15	    	operand is object-related (e.g. if struct
		 *		field & object related => instance var,
		 *		if enum & object related => vardata or message)
		 *
		 * If bit 1 set (data-related):
		 *  8	    	static variable
		 *  9	    	object class
		 * 10	    	local variable
		 * 11	    	lmem chunk
		 * 12-14	r/m field:
		 *	0	= [bx+si](+disp)
		 *	1	= [bx+di](+disp)
		 *	2	= [bp+si](+disp)
		 *	3	= [bp+di](+disp)
		 *	4	= [si]
		 *	5	= [di]
		 *	6	= [bp] (direct addressing if bit 3 set)
		 *	7	= [bx]
		 * 15		set if non-zero displacement
		 *
		 * If none of 0, 1, 2, 4 set (type-less effective address):
		 *  8	    	undefined
		 *  9		undefined
		 * 10		undefined
		 * 11		undefined
		 * 12-14	r/m field:
		 *	0	= [bx+si](+disp)
		 *	1	= [bx+di](+disp)
		 *	2	= [bp+si](+disp)
		 *	3	= [bp+di](+disp)
		 *	4	= [si]
		 *	5	= [di]
		 *	6	= [bp] (direct addressing if bit 3 set)
		 *	7	= [bx]
		 * 15		set if non-zero displacement
		 */
		long	val = 0;

		/*
		 * Set the high bits of the result based on the type of symbol
		 */
		if (tos->type == EXPR_TYPE_SYM) {
		    switch(tos->data.sym->type) {
			/* Constants */
		    case SYM_BITFIELD: 	val = (1<< 9); break;
		    case SYM_FIELD:    	val = (1<<10); break;
		    case SYM_INSTVAR:  	val = (1<<10)|(1<<15); break;
		    case SYM_STRUCT:   	val = (1<<10)|(1<<11); break;
		    case SYM_NUMBER:	val = (1<<14); break;
		    case SYM_SEGMENT:
		    case SYM_GROUP: 	val = (1<<12); break;
		    case SYM_ETYPE: 	val = (1<< 8)|(1<<11); break;
		    case SYM_METHOD:
		    case SYM_VARDATA:	val = (1<< 8)|(1<<15); break;
		    case SYM_ENUM:  	val = (1<< 8); break;
		    case SYM_TYPE:  	val = (1<<11); break;
		    case SYM_RECORD:	val = (1<< 9)|(1<<11); break;
			/* Code-related */
		    case SYM_PROC:
			val = tos->data.sym->u.proc.flags << 8; break;
		    case SYM_LOCALLABEL:
		    case SYM_LABEL:
			val = tos->data.sym->u.label.near ? (1 << 8) : 0; break;
			/* Data-related */
		    case SYM_VAR:
			val = (1<<8); break;
		    case SYM_CLASS:
			val = (1<<9); break;
		    case SYM_LOCAL:
			val = (1<<10); break;
		    case SYM_CHUNK:
			val = (1<<11); break;
		    }
		} else if (tos->type == EXPR_TYPE_SEGSYM) {
		    /* segment constant */
		    val = (1 << 12);
		} else if (tos->type == EXPR_TYPE_TYPE) {
		    if (tos->data.type->tn_type == TYPE_STRUCT) {
			switch(tos->data.type->tn_u.tn_struct->type) {
			case SYM_STRUCT:   	val = (1<<10)|(1<<11); break;
			case SYM_ETYPE: 	val = (1<< 8)|(1<<11); break;
			case SYM_TYPE:  	val = (1<<11); break;
			case SYM_RECORD:	val = (1<< 9)|(1<<11); break;
			}
		    } else if (tos->data.type->tn_type == TYPE_NEAR) {
			/* near code */
			val = (1<< 8);
		    } else if (tos->data.type->tn_type != TYPE_FAR) {
			/* typedef constant */
			val = (1<<11);
		    }
		}

		/*
		 * Convert tos to proper form if it's a symbol
		 */
		if (!ExprConvertSym(expr, tos, &errMsg, flags, &status)) {
		    retVal = 0;
		    goto finish;
		}

		/*
		 * Set the low bits
		 */
		val |= Expr_Status(tos);

		/*
		 * If the expression is a register, figure the type of register
		 */
		if (val & EXPR_STAT_REGISTER) {
		    if (IS_SEGREG(tos)) {
			val |= (1<<14) |
			    (OVERRIDE_TO_SEGREG(tos->data.ea.override) << 8);
		    } else if (tos->type->tn_u.tn_int == 2) {
			switch(tos->data.ea.modrm & MR_RM_MASK) {
			case REG_BX:
			case REG_SI:
			case REG_DI:
			case REG_BP:
			    val |= (1<<13);
			    break;
			}
		    } else {
			val |= (1<<15);
		    }
		    /* put reg number into low bits of high byte (R/M field of
		     * modrm for seg reg is always 0, so setting of register
		     * in segreg handling above is unharmed, here) */
		    val |= (tos->data.ea.modrm & MR_RM_MASK) << 8;
		} else if (((val & (EXPR_STAT_DATA|EXPR_STAT_CONST)) ==
			    EXPR_STAT_DATA) ||
			   (tos->type == NULL))
		{
		    /*
		     * Return r/m field in bits 12-14.
		     */
		    val |= ((word)(tos->data.ea.modrm & MR_RM_MASK)) << 12;
		    /*
		     * If using a displacement, set bit 15
		     */
		    if (tos->data.ea.modrm & MR_DISP_MASK) {
			val |= 1<<15;
		    }
		}

		tos->data.number = val|status;

		/*
		 * If anything undefined at this point the result is 0 (as
		 * returned by Expr_Status), as we've no idea what sort of
		 * thing we're dealing with. Re-initialize undefMsg et al as
		 * well (don't want to return an error, now do we?)...
		 */
		if (!val) {
		    tos->data.number = val; /* (don't include status) */
		    ExprUndefInit();
		}
		tos->type = EXPR_TYPE_CONST;
		tos->rel.sym = NULL;
		tos->rel.frame = NULL;
		elt++, n--;
		break;
	    }
	    case EXPR_WIDTH:
	    {
		Symbol	*sym;

		if (tos->type == EXPR_TYPE_NAN) {
		    /* result remains NaN */
		    elt++, n--;
		    break;
		}

		if ((tos->type == EXPR_TYPE_TYPE) &&
		    (tos->data.type->tn_type == TYPE_STRUCT) &&
		    (tos->data.type->tn_u.tn_struct->type == SYM_RECORD))
		{
		    sym = tos->data.type->tn_u.tn_struct;
		} else if ((tos->type == EXPR_TYPE_SYM) &&
			   ((tos->data.sym->type == SYM_BITFIELD) ||
			    (tos->data.sym->type == SYM_RECORD)))
		{
		    sym = tos->data.sym;
		} else {
		    ExprError("invalid operand of WIDTH");
		}

		if (sym->type == SYM_BITFIELD) {
		    tos->data.number = sym->u.bitField.width;
		} else {
		    /*
		     * Width of a record is just the position of the last
		     * bit in the mask, which we can find by nuking all the
		     * preceding bits and calling ffs to find the remaining
		     * one.
		     */
		    word    m = sym->u.record.mask;

		    tos->data.number = ffs(m ^ (m >> 1));
		}
		tos->type = EXPR_TYPE_CONST;
		tos->rel.sym = NULL;
		tos->rel.frame = NULL;
		elt++, n--;
		break;
	    }
	    case EXPR_MASK:
	    {
		Symbol	*sym;

		if (tos->type == EXPR_TYPE_NAN) {
		    /* result remains NaN */
		    elt++, n--;
		    break;
		}

		if ((tos->type == EXPR_TYPE_TYPE) &&
		    (tos->data.type->tn_type == TYPE_STRUCT) &&
		    (tos->data.type->tn_u.tn_struct->type == SYM_RECORD))
		{
		    sym = tos->data.type->tn_u.tn_struct;
		} else if ((tos->type == EXPR_TYPE_SYM) &&
			   ((tos->data.sym->type == SYM_BITFIELD) ||
			    (tos->data.sym->type == SYM_RECORD)))
		{
		    sym = tos->data.sym;
		} else {
		    ExprError("invalid operand of MASK");
		}

		if (sym->type == SYM_BITFIELD) {
		    tos->data.number = (((1<<(sym->u.bitField.offset+
					     sym->u.bitField.width))-1) ^
				       ((1<<sym->u.bitField.offset)-1));
		} else {
		    tos->data.number = sym->u.record.mask;
		}
		tos->type = EXPR_TYPE_CONST;
		tos->rel.sym = NULL;
		tos->rel.frame = NULL;
		elt++, n--;
		break;
	    }
	    case EXPR_FIRST:
		if (tos->type == EXPR_TYPE_NAN) {
		    /* result remains NaN */
		    elt++, n--;
		    break;
		}

		if ((tos->type == EXPR_TYPE_TYPE) &&
		    (tos->data.type->tn_type == TYPE_STRUCT) &&
		    (tos->data.type->tn_u.tn_struct->type == SYM_ETYPE))
		{
		    tos->data.number =
			tos->data.type->tn_u.tn_struct->u.eType.firstVal;
		} else if ((tos->type == EXPR_TYPE_SYM) &&
			   (tos->data.sym->type == SYM_ETYPE))
		{
		    tos->data.number =
			tos->data.sym->u.eType.firstVal;
		} else {
		    ExprError("invalid operand of FIRST");
		}
		tos->type = EXPR_TYPE_CONST;
		tos->rel.frame = NULL;
		elt++, n--;
		break;
	    case EXPR_HANDLE:
		if (tos->type == EXPR_TYPE_NAN) {
		    /* result remains NaN */;
		} else if (tos->type == EXPR_TYPE_SEGSYM) {
		    tos->type = EXPR_TYPE_CONST;
		    tos->rel.pcrel = 0;
		    tos->rel.fixed = 0;
		    tos->rel.size = FIX_SIZE_WORD;
		    tos->rel.type = FIX_HANDLE;
		    tos->rel.frame = tos->rel.sym = tos->data.elt[1].sym;
		    tos->data.number = 0;
		} else if (tos->type == EXPR_TYPE_SYM) {
		    tos->type = EXPR_TYPE_CONST;
		    tos->rel.pcrel = 	0;
		    tos->rel.fixed = 	0;
		    tos->rel.size = 	FIX_SIZE_WORD;
		    tos->rel.type = 	FIX_HANDLE;
		    tos->rel.frame = 	tos->data.sym->segment;
		    tos->rel.sym =  	tos->data.sym;
		    tos->data.number = 0;
		} else if ((tos->type == EXPR_TYPE_CONST) &&
			   ((tos->data.number == 0) ||
			    (tos->data.number == -1)))
		{
		    /*
		     * This is a kludge to allow libraries to obtain their
		     * geode handle. The idea is to use HANDLE 0 to obtain
		     * the handle as an immediate value. This gets mapped
		     * to a HANDLE fixup on the (nameless) global segment,
		     * which the linker will map to the proper geos relocation
		     */
		    tos->rel.pcrel = 0;
		    tos->rel.fixed = 0;
		    tos->rel.size = FIX_SIZE_WORD;
		    tos->rel.type = FIX_HANDLE;
		    tos->rel.frame = tos->rel.sym = global;
		} else {
		    ExprError("invalid operand of HANDLE");
		}
		elt++, n--;
		break;
	    case EXPR_RESID:
		if (tos->type == EXPR_TYPE_NAN) {
		    /* result remains NaN */;
		} else if (tos->type == EXPR_TYPE_SEGSYM) {
		    tos->type = EXPR_TYPE_CONST;
		    tos->rel.pcrel = 0;
		    tos->rel.fixed = 0;
		    tos->rel.size = FIX_SIZE_WORD;
		    tos->rel.type = FIX_RESID;
		    tos->rel.frame = tos->rel.sym = tos->data.elt[1].sym;
		    tos->data.number = 0;
		} else if (tos->type == EXPR_TYPE_SYM) {
		    tos->type = EXPR_TYPE_CONST;
		    tos->rel.pcrel = 	0;
		    tos->rel.fixed =	0;
		    tos->rel.size = 	FIX_SIZE_WORD;
		    tos->rel.type = 	FIX_RESID;
		    tos->rel.frame = 	tos->data.sym->segment;
		    tos->rel.sym =  	tos->data.sym;
		    tos->data.number = 0;
		} else {
		    ExprError("invalid operand of RESID");
		}
		elt++, n--;
		break;
	    case EXPR_SEG:
	    case EXPR_VSEG:
		if (tos->type == EXPR_TYPE_NAN) {
		    /* result remains NaN */;
		} else if (tos->type == EXPR_TYPE_SEGSYM) {
		    tos->type = EXPR_TYPE_CONST;
		    tos->rel.pcrel = 0;
		    tos->rel.fixed = (elt->op == EXPR_SEG);
		    tos->rel.size = FIX_SIZE_WORD;
		    tos->rel.type = FIX_SEGMENT;
		    tos->rel.frame = tos->rel.sym = tos->data.elt[1].sym;
		    tos->data.number = 0;
		} else if (tos->type == EXPR_TYPE_SYM) {
		    switch(tos->data.sym->type) {
			case SYM_VAR:
			case SYM_LABEL:
			case SYM_LOCALLABEL:
			case SYM_PROC:
			case SYM_CLASS:
			case SYM_CHUNK:
			    tos->type = EXPR_TYPE_CONST;
			    tos->rel.pcrel = 	0;
			    tos->rel.fixed =	(elt->op == EXPR_SEG);
			    tos->rel.size = 	FIX_SIZE_WORD;
			    tos->rel.type = 	FIX_SEGMENT;
			    tos->rel.frame = 	tos->data.sym->segment;
			    tos->rel.sym =  	tos->data.sym;
			    tos->data.number = 0;
			    break;
			default:
			    ExprError("invalid operand of SEG/SEGMENT");
		    }
		} else {
		    ExprError("invalid operand of SEG/SEGMENT");
		}
		elt++, n--;
		break;
	    case EXPR_SHORT:
		if (!ExprConvertSym(expr, tos, &errMsg, flags, &status)) {
		    ExprError(errMsg);
		}
		if (tos->type == EXPR_TYPE_NAN) {
		    /* result remains NaN */;
		} else if (tos->type == EXPR_TYPE_CONST ||
		    tos->type == EXPR_TYPE_STRING ||
		    tos->data.ea.modrm != MR_DIRECT)
		{
		    ExprError("invalid operand of SHORT");
		} else {
		    tos->rel.pcrel = 1;
		    tos->rel.fixed = 0;
		    tos->rel.size = FIX_SIZE_BYTE;
		    tos->rel.type = FIX_LOW_OFFSET;
		}
		elt++, n--;
		break;
	    case EXPR_CAST:
	    {
		/*
		 * Easiest to preserve the type (LHS) and copy the RHS into
		 * the LHS, replacing the type when done.
		 * We allow a symbol on the LHS
		 */
		TypePtr	type = tos[1].type;

		if (tos->type == EXPR_TYPE_NAN || tos[1].type == EXPR_TYPE_NAN)
		{
		    tos[1].type = EXPR_TYPE_NAN;
		    tos[1].rel.sym = tos[1].rel.frame = NULL;
		} else {
		    if (type <= EXPR_TYPE_TYPE) {
			if (type == EXPR_TYPE_CONST) {
			    /*
			     * Deal with MASM casting semantics:
			     *  numbers <= 4 are Type_Int(value),
			     *  ffff is NEAR, fffe is FAR
			     */
			    switch(tos[1].data.number) {
			    case 1:
			    case 2:
			    case 4:
				type = Type_Int(tos[1].data.number);
				break;
			    case -1:
			    case 0xffff:
				type = Type_Near();
				break;
			    case -2:
			    case 0xfffe:
				type = Type_Far();
				break;
			    default:
				ExprError("illegal type for cast operator");
			    }
			} else if ((type < EXPR_TYPE_SYM) ||
				   !ExprExtractType(tos+1, &type))
			{
			    ExprError("illegal type for cast operator");
			}
		    }

		    /*
		     * Because we'll be biffing the type field of this thing,
		     * we need to perform any delayed symbol conversion now.
		     */
		    if (!ExprConvertSym(expr, tos, &errMsg, flags, &status)) {
			ExprError(errMsg);
		    }

		    tos[1] = *tos;
		    if (tos->type != EXPR_TYPE_CONST &&
			tos->type != EXPR_TYPE_STRING)
		    {
			tos[1].type = type;
		    } else if (tos->type == EXPR_TYPE_CONST &&
			       tos->rel.sym == NULL &&
			       tos->rel.frame != NULL)
		    {
			tos->rel.frame = (SymbolPtr)type;
		    } else {
			ExprError("constants can't be cast");
		    }
		}
		tos++;
		elt++, n--;
		break;
	    }
	    case EXPR_OVERRIDE:
	    {
		/*
		 * Override by segment.
		 */
		byte	defSeg;	    /* Default segment for addressing */

		if (tos->type == EXPR_TYPE_NAN || tos[1].type == EXPR_TYPE_NAN)
		{
		    tos[1].type = EXPR_TYPE_NAN;
		    tos[1].rel.sym = tos[1].rel.frame = NULL;
		    tos++;
		    elt++, n--;
		    break;
		}

		/*
		 * First convert RHS to internal format if necessary.
		 */
		if (!ExprConvertSym(expr, tos, &errMsg, flags, &status)) {
		    ExprError(errMsg);
		}

		/*
		 * Check for badness...
		 */
		if (tos->type == EXPR_TYPE_CONST) {
		    if (tos->rel.sym != NULL && tos->rel.type == FIX_SEGMENT) {
			ExprError("can't give segment override to segment symbol");
		    } else {
			/*
			 * Constants are allowed here -- we convert them to a
			 * direct reference using the value as an offset.
			 * The type we get from the frame field of the relocation,
			 * to deal with things like ds:field, where field is a
			 * structure field.
			 */
			tos->type = (TypePtr)tos->rel.frame;
			tos->rel.sym = NULL;
			tos->data.ea.disp = tos->data.number;
			tos->data.ea.modrm = MR_DIRECT;
			tos->data.ea.override = 0;
			tos->data.ea.dword_ea = 0;
			tos->data.ea.sib = 0;
		    }
		} else if (tos->type == EXPR_TYPE_STRING) {
		    ExprError("can't give segment override to a string");
		}

		/*
		 * Figure which segment will be used by the processor by
		 * default, placing its number in defSeg.
		 */
		if ((tos->data.ea.modrm & MR_DISP_MASK) == MR_REG) {
		    ExprError("missing []'s around register");
		}
		defSeg = ExprGetDefaultSegment(tos);

		/*
		 * Only three possible types for LHS -- SEGSYM, NULL and
		 * a FIX_SEGMENT-relocatable CONST.
		 * Anything else can't possibly be a segment. The final
		 * result is complicated by things like
		 *  dw	dgroup:foo
		 * where no segment register may be pointing at dgroup, yet
		 * this is perfectly legal. So we need to set things up for
		 * this to be possible, but still indicate to the code
		 * generator that we don't know to what segment the thing
		 * is attached so it can generate an error in the case of
		 *  mov ax, dgroup:foo
		 * where no segment register is known to point to dgroup.
		 */
		if (tos[1].type == EXPR_TYPE_SEGSYM) {
		    ExprElt *elt = tos[1].data.elt;

		    /*
		     * Copy the address and relocation and type data from
		     * the rhs -- all we need here is the segment symbol
		     * and we've got that in elt.
		     */
		    tos[1] = *tos;

		    if (elt->op == EXPR_SYMOP) {
			/*
			 * Just have a symbol -- see if segment/group bound
			 * to default segreg. If not, find any segment bound
			 * to the given one.
			 */
			if (expr->segments[defSeg] == elt[1].sym) {
			    /*
			     * Update expression operator to contain the
			     * segment register to use in case this thing
			     * is re-evaluated, then indicate that the
			     * default override is good for this beast.
			     */
			    elt->op = EXPR_SEGSYM_ES + defSeg - REG_ES;
			    tos[1].data.ea.override = EXPR_DEF_OVERRIDE;
			} else {
			    int	    i;

			    /*
			     * Assume no binding
			     */
			    tos[1].data.ea.override = EXPR_NO_OVERRIDE;
			    /*
			     * Search for binding on all segment registers.
			     * It doesn't matter which one we find now that
			     * the default one is out.
			     */
			    for (i = REG_ES; i <= REG_GS; i++) {
				if (expr->segments[i] == elt[1].sym) {
				    elt->op = EXPR_SEGSYM_ES + i - REG_ES;
				    tos[1].data.ea.override = OVERRIDE(i);
				    break;
				}
			    }
			}
		    } else {
			/*
			 * Use the segment register encoded in the operator.
			 */
			tos[1].data.ea.override =
			    OVERRIDE((elt->op-EXPR_SEGSYM_ES)+REG_ES);
		    }
		    /*
		     * Set the frame for relocation to be the symbol involved,
		     * regardless of whether a segment register was found
		     * or not.
		     */
		    tos[1].rel.frame = elt[1].sym;
		} else if (tos[1].type == EXPR_TYPE_CONST && tos[1].rel.sym &&
			   tos[1].rel.type == FIX_SEGMENT)
		{
		    /*
		     * Segment given as SEG <expr> : <expr> -- use
		     * segment stored in LHS as relocation frame. Look for
		     * segment register in same way as for EXPR_TYPE_SEGSYM.
		     */
		    Symbol  *sym = tos[1].rel.sym;

		    tos[1] = *tos;
		    if (expr->segments[defSeg] == sym) {
			/*
			 * Signal override with default
			 */
			tos[1].data.ea.override = EXPR_DEF_OVERRIDE;
		    } else {
			int i;

			/*
			 * Assume no register bound to segment.
			 */
			tos[1].data.ea.override = EXPR_NO_OVERRIDE;
			/*
			 * Search for binding on all segment registers.
			 * It doesn't matter which one we find now that
			 * the default one is out.
			 */
			for (i = REG_ES; i <= REG_GS; i++) {
			    if (expr->segments[i] == sym) {
				elt->op = EXPR_SEGSYM_ES + i - REG_ES;
				tos[1].data.ea.override = OVERRIDE(i);
				break;
			    }
			}
		    }
		    /*
		     * Use symbol as relocation frame.
		     */
		    tos[1].rel.frame = sym;
		} else if (tos[1].type) {
		    ExprError("invalid segment for override");
		} else {
		    /*
		     * Override using indicated segment register. If nothing
		     * bound to the register, we leave the relocation frame
		     * alone, else we replace it with the segment bound
		     * to the segment register.
		     */
		    int	segReg = OVERRIDE_TO_SEGREG(tos[1].data.ea.override);

		    tos[1] = *tos;
		    if (expr->segments[segReg]) {
			tos[1].rel.frame = expr->segments[segReg];
		    }
		    tos[1].data.ea.override = OVERRIDE(segReg);
		}
		tos++;		/* Pop result stack */
		elt++, n--;	/* Advance to next expr element */
		break;
	    }
	    case EXPR_INDIRECT:
		/*
		 * Operator placed in the expression to indicate the
		 * presence of []'s in the original source. This is used
		 * to allow things like [field] and [constant] to be
		 * interpreted as an effective address. The operator has no
		 * effect unless the tos is a constant.
		 */
		if (tos->type != EXPR_TYPE_NAN) {
		    if (!ExprConvertSym(expr, tos, &errMsg, flags, &status)) {
			ExprError(errMsg);
		    }
		    if (!ExprIndirect(expr, tos, &errMsg, flags, &status)) {
			ExprError(errMsg);
		    }
		}
		elt++, n--;
		break;
	    case EXPR_SUPER:
		if (tos->type == EXPR_TYPE_NAN) {
		    /* result remains NaN */;
		} else if (tos->type != EXPR_TYPE_SYM) {
		    ExprError("invalid operand of SUPER operator");
		} else if (tos->data.sym->type != SYM_CLASS) {
		    ExprError("SUPER operator requires a class-symbol operand");
		} else if (tos->data.sym->u.class.super == NullSymbol) {
		    ExprError("class has no superclass");
		} else {
		    tos->data.sym = tos->data.sym->u.class.super;
		}
		elt++, n--;
		break;
	    case EXPR_OFFPART:
	    case EXPR_SEGPART:
	    case EXPR_LOWPART:
	    case EXPR_HIGHPART:
		/*
		 * Wants offset or segment portion of a far pointer (can also
		 * be applied to optrs or dwords in general).
		 */
		if (!ExprConvertSym(expr, tos, &errMsg, flags, &status)) {
		    ExprError(errMsg);
		}
		if (tos->type != NULL && tos->type <= EXPR_TYPE_MAX_SPECIAL) {
		    if (tos->type == EXPR_TYPE_NAN) {
			/* result remains NaN */;
		    } else if (tos->type == EXPR_TYPE_CONST && tos->rel.frame) {
			int	size = Type_Size((TypePtr)tos->rel.frame);

			if (elt->op == EXPR_LOWPART ||
			     elt->op == EXPR_HIGHPART)
			{
			    if ((size != 4) && (size != 2)) {
				goto lowHighSizeErr;
			    }
			} else if (size != 4) {
			    goto segOffSizeErr;
			}
			tos->rel.frame = (SymbolPtr)Type_Int(size/2);
			if (elt->op == EXPR_HIGHPART || elt->op == EXPR_SEGPART)
			{
			    tos->data.number += size/2;
			}
		    } else {
			switch(elt->op) {
			    case EXPR_OFFPART:
				ExprError("cannot find offset/chunk portion of expression");
			    case EXPR_SEGPART:
				ExprError("cannot find segment/handle portion of expression");
			    case EXPR_LOWPART:
				ExprError("cannot find low portion of expression");
			    case EXPR_HIGHPART:
				ExprError("cannot find high portion of expression");
			}
		    }
		} else if (elt->op == EXPR_LOWPART || elt->op == EXPR_HIGHPART){
		    /*
		     * Must be either a word or dword. Untyped expressions are
		     * assumed to be dwords - if the assumption is wrong, it
		     * will/should generate errors when generating the code.
		     */
		    int	size;
		    TypePtr type = tos->type;

		    if (type == NULL) {
			type = Type_Int(4);
		    }

		    while (type->tn_type == TYPE_ARRAY) {
			type = type->tn_u.tn_array.tn_base;
		    }

		    size = Type_Size(type);

		    if (size != 2 && size != 4) {
    lowHighSizeErr:
			ExprError("operand of .low/.high must be 2 or 4 bytes long");
		    } else {
			tos->type = Type_Int(size/2);
			if (elt->op == EXPR_HIGHPART) {
			    tos->data.ea.disp += size/2;
			    ExprSetDispSize(tos, status & EXPR_STAT_DELAY);
			}
		    }
		} else {
		    if (tos->type != NULL) {
			TypePtr type = tos->type;

			while (type->tn_type == TYPE_ARRAY) {
			    type = type->tn_u.tn_array.tn_base;
			}

			if (Type_Size(type) != 4) {
    segOffSizeErr:
			    ExprError("operand of .offset/.chunk/.segment/.handle must be four bytes long");
			}
		    }
		    /*
		     * Cast the result to be a word, as is proper
		     */
		    tos->type = Type_Int(2);
		    /*
		     * If want the segment portion, add two to the displacement
		     * and adjust the displacement size.
		     */
		    if (elt->op == EXPR_SEGPART) {
			tos->data.ea.disp += 2;
			ExprSetDispSize(tos, status & EXPR_STAT_DELAY);
		    }
		}
		elt++, n--;
		break;
	    default:
		ExprError("internal error: unhandled operator");
	}
    }

    /*
     * Evaluation complete -- Standardize return value, figure status and
     * clean up.
     */
    finish:

    if (retVal) {
	/*
	 * Everything's ok. Make sure the top of the stack is in the
	 * proper format for return and return it.
	 */

	if (tos != (stackBase + stackSize - 1)) {
	    errMsg = "operator(s) missing";
	    retVal = 0;
	} else if (ExprConvertSym(expr, tos, &errMsg,
				  flags|EXPR_FINAL_CONVERT, &status))
	{
	    /*
	     * Trim off the implicit-override bit from the
	     * override produced by ExprConvertSym, if necessary.
	     */
	    if (tos->type > EXPR_TYPE_MAX_SPECIAL) {
		if (warn_assume &&
		    !(flags & (EXPR_RECURSIVE|EXPR_NOT_OPERAND)) &&
		    (tos->data.ea.override & EXPR_IMPLICIT_OVERRIDE) &&
		    (tos->rel.sym != NULL) &&
		    (tos->rel.sym->type != SYM_PROC) &&
		    (tos->rel.sym->type != SYM_LABEL) &&
		    (tos->rel.sym->type != SYM_LOCALLABEL) &&
		    (tos->rel.sym->type != SYM_LOCAL) &&
		    (tos->rel.sym->type != SYM_CLASS))
		{
		    Notify(NOTIFY_WARNING, expr->file, expr->line,
			   "implicit override for variable %i generated by segment assumptions",
			   tos->rel.sym->name);
		}
		/* XXX: deal with var[bp] when both ds and ss point to segment
		 * in which var is located. generates ds override now... */
		tos->data.ea.override &= ~EXPR_IMPLICIT_OVERRIDE;
	    }
	    /*
	     * Decide if the override is actually necessary or if it
	     * corresponds to the default segment to be used.
	     */
	    if (!IS_SEGREG(tos) &&
		((tos->type == NULL) || (tos->type > EXPR_TYPE_MAX_SPECIAL)))
	    {
		/*
		 * Figure which segment will be used by the processor by
		 * default, setting override to EXPR_DEF_OVERRIDE if the
		 * current override matches the default.
		 */
		if (tos->data.ea.override ==
		  OVERRIDE(ExprGetDefaultSegment(tos))) {
		    tos->data.ea.override = EXPR_DEF_OVERRIDE;
		}
	    }

	    /*
	     * Deal with extra indirection requested when entering data.
	     */
	    if ((flags & EXPR_DATA_ENTER) &&
		(tos->type == EXPR_TYPE_CONST) &&
		(tos->rel.sym) &&
		(tos->rel.type == FIX_OFFSET))
	    {
		(void)ExprIndirect(expr, tos, &errMsg, flags, &status);
	    }

	    *result = *tos;
	    if (tos->type == EXPR_TYPE_NAN) {
		status = 0;
	    } else {
		assert(!undefErr);
		status |= Expr_Status(tos);
	    }

	    /*
	     * If any symbols undefined, or there's a symbol who's UNDEF bit
	     * is set and we're still in pass1 (EXPR_NOUNDEF is clear in our
	     * flags argument), pretend the result is undefined, forcing the
	     * caller to call us back in the second pass. This allows us to
	     * gracefully handle forward references whose symbols have been
	     * defined with the "global" or "extrn" directives.
	     */
	    if (tos->type == EXPR_TYPE_NAN ||
		(result->rel.sym && (result->rel.sym->flags & SYM_UNDEF) &&
		 !(flags & EXPR_NOUNDEF)))
	    {
		status &= ~EXPR_STAT_DEFINED;
		if (flags & EXPR_NOUNDEF) {
		    /*
		     * Only return an error if undefined's aren't allowed
		     */
		    retVal = 0;
		    errMsg = ExprUndefFinish();
		} else {
		    /*
		     * Assume default override until symbol is defined.
		     */
		    result->data.ea.override = EXPR_DEF_OVERRIDE;
		}
	    } else if (result->type==EXPR_TYPE_SEGSYM || IS_SEGREG(result)) {
		/*
		 * Just a segment register -- we can't let the result have
		 * type EXPR_TYPE_SEGSYM, since that's internal, so instead
		 * we make the result of type [d]word, letting EXPR_IS_SEGREG
		 * tell the client it's a segment register. The choice
		 * of 0 for the modrm field was bad, since modrm of 0 with
		 * displacement 0 is perfectly valid. Instead, we switch
		 * to use 0x80, which, with a displacement of 0, is
		 * something we'd never produce...
		 */
		if (result->type == EXPR_TYPE_SEGSYM) {
		    /*
		     * Convert a SEGSYM to an actual override.
		     */
		    result->data.ea.override =
			OVERRIDE(result->data.elt->op - EXPR_SEGSYM_ES);
		}
		result->type = (result->data.ea.dword_ea) ?
		    Type_Int(4) : Type_Int(2);
		result->data.ea.modrm = MR_SEGREG;
		result->data.ea.disp = 0;
		result->data.ea.dword_ea = 0;
		result->data.ea.sib = 0;
		status |= EXPR_STAT_REGISTER;
	    } else if ((result->type > EXPR_TYPE_MAX_SPECIAL) &&
		       ((result->data.ea.modrm & MR_DISP_MASK) != MR_REG))
	    {
		/*
		 * Now the final form of the expression has been decided upon,
		 * if the result is an effective address, see if the segment
		 * override matches the default segment for the addressing
		 * mode. If so, change the override to be EXPR_DEF_OVERRIDE to
		 * note that no real override is necessary.
		 */
		int defSeg = ExprGetDefaultSegment(result);

		if (result->data.ea.override == OVERRIDE(defSeg)) {
		    result->data.ea.override = EXPR_DEF_OVERRIDE;
		}
	    }
	} else {
	    retVal = 0;
	    status |= EXPR_STAT_DEFINED;
	}
    } else if (undefErr) {
	if (!(flags & EXPR_NOUNDEF)) {
	    /*
	     * If anything is undefined and it's ok for there to be something
	     * undefined, any other error message is suspect. Since any
	     * expression evaluated with undefined symbols ok will eventually
	     * be re-evaluated with such symbols being an error, we prefer
	     * to re-generate the error we've gotten when all the elements
	     * are defined. Otherwise, you end up with expressions like:
	     *  	dw  endOfStuff-$
	     * where endOfStuff is a forward reference, endOfStuff is converted
	     * to a constant, and EXPR_MINUS complains about subtracting
	     * something non-constant from a constant.
	     */
	    status = 0;
	    retVal = 1;
	} else {
	    status = retVal = 0;
	    errMsg = ExprUndefFinish();
	}
    } else {
	status |= EXPR_STAT_DEFINED;
    }

    /*
     * Return status if desired.
     */
    if (statusPtr) {
	*statusPtr = status;
    }

    /*
     * Free the result stack if we had to enlarge it
     */
    if (stackBase != defStack) {
	free((char *)stackBase);
    }

    /*
     * Return the error message in the type field of the result if returning
     * 0.
     */
    if (!retVal) {
	result->type = (TypePtr)errMsg;
    }

    return(retVal);
}

/***********************************************************************
 *				Expr_InvolvesOp
 ***********************************************************************
 * SYNOPSIS:	    See if an expression involves the indicated operator.
 * CALLED BY:	    CodeCompatible to decide if out-of-range bits are
 *	    	    significant. Code_CallStatic to decide if the call
 *	    	    is a static call or a super-static call.
 * RETURN:	    1 if it does. 0 if it doesn't
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    For now, we just look for a NOT operator anywhere
 *	    	    in the expression. It might be good (read: useful)
 *	    	    to see if the bits could have been cancelled (e.g.
 *	    	    with an AND) but weren't, implying they're significant.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/14/89	Initial Revision
 *
 ***********************************************************************/
int
Expr_InvolvesOp(Expr	    *expr,
		ExprOp	    op)
{
    int 	i;
    ExprElt	*elt;

    i = expr->numElts;
    elt = expr->elts;
    while (i > 0) {
	if (elt->op == op) {
	    return(1);
	}
	switch (elt->op) {
	    case EXPR_DWORDREG:
	    case EXPR_WORDREG:
	    case EXPR_BYTEREG:
	    case EXPR_SEGREG:
	    case EXPR_INDREG:
	    case EXPR_SYMOP:
	    case EXPR_CONST:
	    case EXPR_IDENT:
	    case EXPR_TYPE:
	    case EXPR_SEGSYM_ES:
	    case EXPR_SEGSYM_CS:
	    case EXPR_SEGSYM_SS:
	    case EXPR_SEGSYM_DS:
	    case EXPR_SEGSYM_FS:
	    case EXPR_SEGSYM_GS:
	    case EXPR_COMMA:
	    case EXPR_FLOATSTACK:
		/*
		 * Special operators that have a single following element
		 */
		elt += 2, i -= 2;
		break;
	    case EXPR_INIT:
	    case EXPR_STRING:
	    {
		int nelts = ExprStrElts(elt[1].str)+1;

		elt += nelts;
		i -= nelts;
		break;
	    }
	    default:
		elt++, i--;
		break;
	}
    }

    return(0);
}
