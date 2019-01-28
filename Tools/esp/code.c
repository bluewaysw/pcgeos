/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Code Generation
 * FILE:	  code.c
 *
 * AUTHOR:  	  Adam de Boor: Jun 12, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *      Code_Arith2 	    ADD, ADC, AND, XOR, SBB, SUB, OR, CMP
 *      Code_Arpl   	    ARPL
 *	Code_BitNF	    ANDNF, ORNF, XORNF
 *      Code_Bound  	    BOUND
 *      Code_Call   	    CALL
 *	Code_CallStatic	    CALL static method
 *	Code_DPShiftLeft    SHLD
 *	Code_DPShiftRight   SHRD
 *      Code_EnterLeave	    ENTER, LEAVE
 *	Code_Fbiop  	    FADD, FADDP, FSUB, FSUBP, FSUBR, FSUBRP, FMUL,
 *	    	    	    FMULP, FDIV, FDIVP, FDIVR, FDIVRP
 *	Code_Fcom   	    FCOM, FCOMP
 *	Code_Ffree  	    FFREE, FFREEP
 *	Code_Fgroup0  	    FINIT, FNINIT, FCOMPP, FCLEX, FNCLEX, FDISI,
 *	    	    	    FNDISI, FENI, FNENI, FSTSWAX, FNSTSWAX
 *	Code_Fgroup1	    FBLD, FBSTP, FLDCW, FLDENV, FRSTOR, FSAVE, FNSAVE,
 *	    	    	    FNSTSW, FSTSW, FNSTCW, FSTCW, FNSTENV, FSTENV
 *	Code_Fldst 	    FILD, FIST, FISTP
 *	Code_Fint   	    FIADD, FISUB, FISUBR, FIDIV, FIDIVR, FMUL,
 *	    	    	    FICOM, FICOMP, FILD, FIST, FISTP
 *	Code_Fldst  	    FLD, FST, FSTP
 *	Code_Fxch   	    FXCH, FUCOM, FUCOMP
 *	Code_Fzop	    F2XM1, FABS, FCHS, FCOS, FDECSTP, FINCSTP, FLD1,
 *	    	    	    FLDL2E, FLDL2T, FLDLG2, FLDN2, FLDPI, FLDZ, FNOP,
 *	    	    	    FPATAN, FPREM, FPREM1, FPTAN, FRICHOP, FRINEAR,
 *	    	    	    FRINT2, FRNDINT, FRSTPM, FSBP0, FSBP1, FSBP2,
 *	    	    	    FSCALE, FSETPM, FSIN, FSINCOS, FSQRT, FTST, FTSTP,
 *	    	    	    FXAM, FXTRACT, FYL2X, FUCOMPP
 *      Code_Group1 	    NOT, NEG, MUL, IMUL(1 operand), DIV, IDIV
 *      Code_Imul   	    IMUL(2 or 3 operands)
 *      Code_IO	    	    IN, OUT
 *      Code_Ins    	    INS
 *      Code_Int    	    INT
 *      Code_Jmp    	    JMP
 *      Code_Jcc    	    Conditional jumps
 *      Code_LDPtr  	    LDS, LES, LFS, LGS, LSS
 *	Code_Lea    	    LEA
 *	Code_Lock   	    LOCK
 *      Code_Loop   	    LOOP, LOOPNE, LOOPE, LOOPNZ, LOOPZ
 *      Code_LSDt   	    LGDT, LIDT, SGDT, SIDT
 *      Code_LSInfo    	    LAR, LSL
 *      Code_Move   	    MOV
 *	Code_NoArg  	    AAA, AAD, AAM, AAS, CBW, CLC, CLD, CMC, CMPSB,
 *	    	    	    CMPSW, CWD, DAA, DAS, INSB, INSW, INTO, IRET,
 *	    	    	    LAHF, LODSB, LODSW, MOVSB, MOVSW, NOP, OUTSB,
 *	    	    	    OUTSW, POPA, POPF, PUSHA, PUSHF, SAHF, SCASB,
 *	    	    	    SCASW, STC, STD, STOSB, STOSW, WAIT, XLATB
 *      Code_NoArgPriv      CLTS
 *	Code_NoArgIO	    HLT, STI, CLI
 *      Code_Outs   	    OUTS
 *	Code_Override	    Store a segment override
 *      Code_Pop    	    POP
 *      Code_Push   	    PUSH
 *      Code_PWord  	    LMSW, SMSW, LLDT, SLDT, LTR, STR, VERR, VERW
 *	Code_Rep    	    REP, REPE, REPZ, REPNE, REPNZ
 *	Code_Ret    	    RET, RETN, RETF
 *      Code_Shift  	    SAL, SAR, SHL, SHR, ROL, ROR, RCL, RCR
 *      Code_String 	    CMPS, LODS, MOVS, SCAS, STOS, XLAT
 *      Code_Test   	    TEST
 *      Code_IncDec 	    INC, DEC
 *      Code_Xchg   	    XCHG
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	6/12/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Code generators. All functions are FixProc's...
 *
 ***********************************************************************/

#include    "esp.h"
#include    "fixup.h"
#include    "code.h"
#include    "scan.h"
#include    "parse.h"

#undef ASSERT	/* Nuke .assert token... */

#include    <objfmt.h>

/*****************************************************************************
 *
 *			  UTILITY FUNCTIONS
 *
 ****************************************************************************/

/*
 * OVERRIDE produces the correct segment-override opcode given the segment
 * register to use.
 */
#define OVERRIDE(reg)	(((reg) < REG_FS) ? (0x26 | ((reg) << MR_REG_SHIFT)) : \
					  (0x60 + (reg)))

#define	MAX_FLOATSTACK_ELEMENT 7

/*
 * Make sure that the processor type/mode required for the instruction
 * is enabled. This is only done on pass 1 or 2, as any future passes will have
 * made it past this point already (this happens on pass 2 when a forward
 * reference is the operand of some instructions -- ardeb). If the type/mode
 * isn't enabled, calls yyerror with the message and returns an error result.
 */
#define ASSERT(what,message) \
    if (pass <= 2 && !(procType & PROC_##what)) {\
	if (pass == 1) {\
	    yyerror(# message);\
	} else {\
	    if (expr1) {\
		Notify(NOTIFY_ERROR, expr1->file, expr1->line, # message);\
	    } else {\
		Notify(NOTIFY_ERROR, expr2->file, expr2->line, # message);\
	    }\
	}\
	return(FR_ERROR);\
    }
#define ASSERT_PROT() 	ASSERT(PROT,protected-mode instruction not allowed)
#define ASSERT_IO() 	ASSERT(IO,I/O-related instruction not allowed)
#define ASSERT_186()	ASSERT(80186,80186-instruction not supported by current processor)
#define ASSERT_286()	ASSERT(80286,80286-instruction not supported by current processor)
#define ASSERT_386()	ASSERT(80386,80386-instruction not supported by current processor)

#define USE_386()	(procType & (PROC_80386|PROC_80486))

#define RES_IS_CONST(type) (((type) == EXPR_TYPE_CONST) || \
			    ((type) == EXPR_TYPE_STRING))

#define EXPR_IS_LABEL(res) (((res)->type != EXPR_TYPE_CONST) && \
			    ((res)->type != EXPR_TYPE_STRING) && \
			    ((res)->type != EXPR_TYPE_FLOATSTACK) && \
			    ((res)->type != NULL) && \
			    (((res)->type->tn_type == TYPE_NEAR) || \
			     ((res)->type->tn_type == TYPE_FAR)))

/*
 * Evaluates non-zero if an opSize operand requires the operand-size prefix
 * in the current code segment.
 */
#define OPSIZE_NEEDS_PRE_OPERAND(opSize) (((opSize) > 1) && (((opSize) == 4) ? \
	DWORD_OPER_NEEDS_PREFIX() : WORD_OPER_NEEDS_PREFIX()))
/*
 * Evaluates non-zero if an ExprResult * points to a memory ea or register
 * that requires the given prefix in the current code segment.
 */
#define EXPR_NEEDS_PRE_OPERAND(resP) \
	(OPSIZE_NEEDS_PRE_OPERAND(Type_Size((resP)->type)))

#define EXPR_NEEDS_PRE_ADDRESS(resP) (((resP)->data.ea.dword_ea) ? \
			    DWORD_EA_NEEDS_PREFIX() : WORD_EA_NEEDS_PREFIX())
/*
 * Evaluates non-zero if use of the given operand size or memory ea requires
 * the operand-size prefix in the current code segment.
 *
 * TODO: Handle code segments marked USE32, where the rules reverse.
 */
#define DWORD_OPER_NEEDS_PREFIX()	(1)
#define WORD_OPER_NEEDS_PREFIX()	(0)

#define DWORD_EA_NEEDS_PREFIX()		(1)
#define WORD_EA_NEEDS_PREFIX()		(0)


/*
 * Macro to handle things that must be done at the start of every code
 * generator. These include:
 *	- making sure code isn't being generated in an absolute or global
 *	  segment.
 *	- making sure code isn't unreachable, if warn_unreach true.
 *	- returning success if just generating dependencies.
 *	- resetting checkLabel for the current segment.
 */
#define START_CODEGEN(pass,dot,mdretval,errretval) \
    if (makeDepend) return mdretval; \
    if (curSeg->u.segment.data->comb == SEG_ABSOLUTE || \
	curSeg->u.segment.data->comb == SEG_GLOBAL)\
    {\
	yyerror("Code in absolute/global segment %i", curSeg->name);\
	return errretval;\
    }\
    if (warn_unreach && ((pass) == 1) && \
	curSeg->u.segment.data->checkLabel && \
	((dot) != curSeg->u.segment.data->lastLabel))\
    {\
	yywarning("code cannot be reached");\
    }\
    if (fall_thru) \
    { \
	yywarning("code generated after .fall_thru");\
    }\
    if (do_bblock && (pass) == 1 && \
	(curSeg->u.segment.data->checkLabel ||\
	 curSeg->u.segment.data->blockStart ||\
	 ((dot) == curSeg->u.segment.data->lastLabel)))\
    {\
        Code_ProfileBBlock(&(dot));\
    }\
    curSeg->u.segment.data->blockStart = \
	curSeg->u.segment.data->checkLabel = FALSE



    /*
     * These get defined here so that they can be referenced before the
     * actual definitions are done.
     */
FixProc Code_JccWarn;
FixProc Code_JccNoWarn;


/***********************************************************************
 *				CreateCheckSegmentArg
 ***********************************************************************
 * SYNOPSIS:	    Construct the segment from an expression result
 * CALLED BY:	    InvokeCheckMacro
 * RETURN:	    Argument which must be free'd later
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JCW	8/10/94   	Initial Revision
 *
 ***********************************************************************/
void
CreateCheckSegmentArg (Expr *expr, ExprResult *result, Arg *arg, byte stat)
{
    char *seg;
    byte  ovr,
    	  modrm;

    if ((stat & EXPR_STAT_DEFINED) == 0) {
    	/* Not defined */
	seg = "unknown";
    } else {

	/*
	 * Allocate space for the string, and get the override and modrm info,
	 * since we will be using it so frequently.
	 */
	seg   = "ds";
	ovr   = result->data.ea.override;
	modrm = result->data.ea.modrm;

	/*
	 * Check for a segment override, and if there is none, figure out
	 * the default segment, given the expression.
	 */
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
		    seg = "ds";
		    break;

		case MR_BP_SI:	    /* [bp+si+disp] */
		case MR_BP_DI:	    /* [bp+di+disp] */
		    /*
		     * 'ss' is the default for all of these.
		     */
		    seg = "ss";
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
			seg = "ds";
		    } else {
			/*
			 * bp-displacement, use ss as default seg-register
			 */
			seg = "ss";
		    }
		    break;

		default:
		    Notify(NOTIFY_ERROR, expr->file, expr->line,
			   "Unexpected modrm value: %02xh", (int)modrm);
		    exit(1);
		    /*NOTREACHED*/
		}
	    	break;

	    case OVERRIDE(REG_ES):
		seg = "es";
	    	break;

	    case OVERRIDE(REG_CS):
		seg = "cs";
	    	break;

	    case OVERRIDE(REG_SS):
		seg = "ss";
	    	break;

	    case OVERRIDE(REG_DS):
		seg = "ds";
	    	break;

	    case EXPR_NO_OVERRIDE:
	    default:
	    	/*
		 * For both of these cases, we fail. I'm assuming that the
		 * "no override" case is intended as a temporary condition
		 * in esp, and that it is always cleaned up before we generate
		 * any code.
		 */
	    	Notify(NOTIFY_ERROR, expr->file, expr->line,
		       "Unexpected segment override value: %02xh", (int)ovr);
	    	exit(1);
	    	/*NOTREACHED*/
	}
    }

    arg->value	= seg;
    arg->freeIt = FALSE;
    arg->next   = NULL;
}


/***********************************************************************
 *				CreateCheckFlagArg
 ***********************************************************************
 * SYNOPSIS:	    Create a flag argument which indicates if expr is [si]
 * CALLED BY:	    InvokeCheckMacro
 * RETURN:	    arg set up, (must be free'd later)
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JCW	11/15/94   	Initial Revision
 *
 ***********************************************************************/
void
CreateCheckFlagArg (ExprResult *result, Arg *arg, byte stat)
{
    byte  ovr,
    	  modrm;
    char *flag;

    flag = "";			/* Assume not "ds:[si]" */

    if ((stat & EXPR_STAT_DEFINED) == 0) {
    	/* Not defined */
    } else {
	ovr   = result->data.ea.override;
	modrm = result->data.ea.modrm;

	/*
	 * Check for a segment override, and if there is none, figure out
	 * the default segment, given the expression.
	 */
	switch (ovr) {
	    case 0:
	    case EXPR_DEF_OVERRIDE:
	    case OVERRIDE(REG_DS):
	    case OVERRIDE(REG_ES):
	    case OVERRIDE(REG_CS):
	    case OVERRIDE(REG_SS):
	    	switch (modrm & MR_RM_MASK) {
		    case MR_SI:	    /* [si+disp] */
			if (result->data.ea.disp == 0) {
			    flag = "1";
			}
			break;

		    default:
			break;
		}
	    	break;

	    default:
		break;
	}
    }

    arg->value	= flag;
    arg->freeIt = FALSE;
    arg->next   = NULL;
}	/* End of CreateCheckFlagArg.	*/



/***********************************************************************
 *				InvokeCheckMacro
 ***********************************************************************
 * SYNOPSIS:	    Somehow cause the macro to be evaluated right now.
 * CALLED BY:	    CodeCheckExpression
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JCW	9/ 2/94   	Initial Revision
 *
 ***********************************************************************/
int
ICM_yywrap(void)
{
    return(TRUE);		/* Keep going... */
}

static char
ICM_yyinput(void)
{
    return(0);			/* end of something... */
}

void
InvokeCheckMacro(SymbolPtr macroSym, Expr *expr, ExprResult *res, byte stat)
{
    WrapProc   *oldwrap;
    ID	    	id;
    Arg	       *args;
    Expr       *rwDispExpr;
    char       *rwCheckDisplacementName = "??rwCheckDisplacement";
    SymbolPtr   rwDispSym;

    /*
     * Push the current macro state, place the macro on the input
     * stream, and get it to be evaluated.
     */
    Scan_SavePB();

    /*
     * We push yywrap, because PushMacro doesn't do it for us, and we need
     * yywrap to return "all done" in order to complete the recursive
     * invocation of yyparse.
     *
     * We also set a new input vector. The call to yystartmacro() will
     * cause PushMacro() to be called, which will save the input vector
     * we have set, and will restore it when the macro is all done being
     * placed on the input stream. It will then invoke the input vector
     * to get the next byte of input. We want to ensure that an EOF is
     * returned at that point, so that yywrap will be called so that we
     * can complete the recursive yyparse at the end of the macro...
     */
    oldwrap = yywrap;

    yywrap  = ICM_yywrap;
    yyinput = ICM_yyinput;

    /*
     * We create a set of macro arguments:
     *	    1) expression	(for 'lea')
     *	    2) segment	    	(if known, "unknown" if not known)
     *	    3) flag 	    	(non-zero is expression is "[si]")
     */
    rwDispExpr = Expr_Copy(expr, FALSE);

    id = ST_EnterNoLen(output, symStrings, rwCheckDisplacementName);

    rwDispSym = Sym_Enter(id, SYM_NUMBER, rwDispExpr, FALSE);

    assert(rwDispSym != NULL);

    /*
     * Set the argument to be the name of the symbol which is set to
     * the expression to check. This is what we need.
     */
    args    	 = (Arg *)malloc(sizeof(Arg));
    args->value  = rwCheckDisplacementName;
    args->freeIt = FALSE;

    args->next   = (Arg *)malloc(sizeof(Arg));
    CreateCheckSegmentArg(expr, res, args->next, stat);

    args->next->next = (Arg *)malloc(sizeof(Arg));
    CreateCheckFlagArg(res, args->next->next, stat);

    /*
     * Finally invoke the macro.
     */
    yystartmacro(macroSym, args);
    (void) yyparse();

    Scan_RestorePB();		/* restores old yyinput */

    /*
     * Restore the wrap vector.
     */
    yywrap = oldwrap;

    /*
     * We don't need return a parse error, since if there was one, it has
     * been noted already.
     */
}	/* End of InvokeCheckMacro.	*/



/******************************************************************************
  Declaration of CodeInitial() so we can use it.
******************************************************************************/

static FixResult
CodeInitial(int	    	*addrPtr,   /* Start of instruction area */
	    int	    	pass,       /* Current pass */
	    Expr    	*expr1,	    /* First operand (required) */
	    ExprResult	*res1,	    /* Result of evaluation (required) */
	    Expr    	*expr2,	    /* Second operand (may be null) */
	    ExprResult	*res2,	    /* Result of evaluation (may be null) */
	    FixProc 	*proc,	    /* Calling procedure (register in case
				     * of undefined symbols) */
	    int	    	defSize,    /* Default size in case of undefined syms*/
	    Opaque  	data,	    /* Data to pass to Fix_Register */
	    int	    	*delayPtr); /* Place to store if use of either result
				     * should be delayed */


/***********************************************************************
 *				FixupReadWriteCheck
 ***********************************************************************
 * SYNOPSIS:	    Fixup code for a read/write check
 * CALLED BY:	    Fixup called during pass 2 (hopefully)
 * RETURN:	    FR_UNDEF/ERROR/DONE, depending on the situation
 * SIDE EFFECTS:    May remove the read/write check macro invocation
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JCW	10/28/94   	Initial Revision
 *
 ***********************************************************************/
FixResult
FixupReadWriteCheck(int	       *addrPtr,  /* IN/OUT: Address of inst start */
		    int   	prevSize, /* # bytes prev alloc'd to inst */
		    int   	pass, 	  /* Current pass */
		    Expr       *expr1,	  /* Operand 1 */
		    Expr       *expr2,	  /* Operand 2 */
		    Opaque	data)	  /* OpCode/other data */
{
    ExprResult	res1, res2;
    int	    	delay;


    /*
     * Evaluate the expression because we need the result...
     */
    switch (CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			FixupReadWriteCheck, 0, data, &delay))
    {
	case FR_UNDEF: return(FR_UNDEF);
	case FR_ERROR: return (FR_ERROR);
    }

    /*
     * If the expression is any one of the following, then we nuke all the
     * code that was associated with the read/write checking macro.
     *
     *	    register only expression
     *	    label
     *	    segment register
     *	    constant
     *
     * Otherwise I just advance the pointer by the previous size.
     *
     * Nuking code is easy, you just don't advance the address pointer.
     */
    if (Expr_Status(&res1) & (EXPR_STAT_CODE|EXPR_STAT_REGISTER|EXPR_STAT_CONST))
    {
	/* expr1 is not something worth checking */

	Table_Delete(curSeg->u.segment.code, *addrPtr, prevSize);

    } else {
    	/*
	 * Advance the pointer, the expression is checkable.
	 */

	*addrPtr += prevSize;
    }

    return(FR_DONE);
}


/***********************************************************************
 *				CodeCheckExpression
 ***********************************************************************
 * SYNOPSIS:	Verify that an expression we are reading-from/writing-to is valid
 * CALLED BY:	CodeInitial
 * RETURN:	nothing
 * SIDE EFFECTS: may invoke _read/writecheck macro, and that macro
 *	    	    may generate code
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jcw	 4/ 5/94	Initial Revision
 *
 ***********************************************************************/

/*
 * Enumerated type that determines whether we do read or write checking.
 */
typedef enum {
    CHECK_VALID_READ, CHECK_VALID_WRITE
} CheckExpressionType;

static void
CodeCheckExpression(Expr    	    	*checkExpr, /* expression to check */
		    ExprResult	    	*checkRes,  /* result of expr eval */
		    CheckExpressionType  checkType, /* type of check to make */
		    int	    	    	*addrPtr,   /* place to store code */
		    FixProc 	    	 proc, 	    /* fixup procedure */
		    byte    	    	 stat) 	    /* status of the expr */
{
    /*
     * Make sure we haven't screwed up the parameters.
     */
    assert(checkExpr != NULL);
    assert(checkRes  != NULL);
    assert(checkType <= CHECK_VALID_WRITE);

    /*
     * There are certain instructions that we just don't check expressions for.
     */
    if ((proc == Code_Jcc) ||
    	(proc == Code_JccWarn) ||
	(proc == Code_JccNoWarn) ||
	(proc == Code_Jmp) ||
	(proc == Code_Loop) ||
	(proc == Code_NoArg) ||
	(proc == Code_Ret) ||
	(proc == Code_CallStatic) ||
	(proc == Code_Call) ||
	(proc == Code_String) ||
	(proc == Code_Lea) ||
	(proc == Code_EnterLeave)) {

    	return;
    }

    /*
     * If this instruction is preceded by a 'lock' or a 'rep' we want
     * to avoid adding EC code, since it will result in the lock/rep
     * not applying to the code it ought to be applying to. For this
     * reason, the read/write checking simply can't be done when
     * the instruction is prefix'd by lock or rep.
     *
     * Figuring out if the prefix exists is somewhat difficult. I need to
     * check the fixups for the current code segment. If a fixup exists
     * in the current code segment for the location immediately preceding
     * where the current instruction is, and if the fixup callback is
     * either Code_Lock or Code_Rep, then I know we have a prefix and
     * this function should just return. Oh boy...
     */
    if (Fix_Find(Code_Rep, (*addrPtr-1), 1)) {
    	/*
	 * Found a fixup for a 'rep', we should quit.
	 */
	return;
    }

    if (Fix_Find(Code_Lock, (*addrPtr-1), 1)) {
    	/*
	 * Found a fixup for a 'lock', we should quit.
	 */
	return;
    }

    /*
     * We only check address expressions. Not register or segreg expressions.
     *
     * The checks below (in order) are:
     *	- No check if this is a register-only expression
     *	- No check if this is a constant expression
     *  - No check if this is a segment register-only expression
     *	- No check if this is a reference to a local label
     */
    if (((checkRes->data.ea.modrm & MR_DISP_MASK) != MR_REG) &&
	(! RES_IS_CONST(checkRes->type)) &&
	(! EXPR_IS_SEGREG(checkRes))) {

	char	  *macroName;
	SymbolPtr  macroSym;
	ID  	   id;

        /*
	 * It's an address expression, or else it's undefined. We convert
	 * the expression to some meaningful text strings and produce an
	 * argument list for the macro.
	 *
	 * The macro gets passed the expression, and can extract both the
	 * segment and displacement from that expression.
	 *
	 *  	_writecheck ds:[bx+si][1234h]
	 */

	/*
	 * Invoke the macro, if it's defined.
	 */
	if (checkType == CHECK_VALID_READ) {
	    macroName = "_readcheck";
	} else {
	    macroName = "_writecheck";
	}

	id = ST_EnterNoLen(output, symStrings, macroName);
	macroSym = Sym_Find(id, SYM_MACRO, FALSE);

	if (macroSym != NULL) {
	    /*
	     * The macro is actually defined, so we invoke it.
	     */
	    int	    	oldDot;

	    /*
	     * When we invoke the macro, we need to avoid recursively checking
	     * reads and writes.
	     */
	    int	       oreadCheck,
	    	       owriteCheck,
		       odo_bblock;

	    /*
	     * We save the old check values, then reset them to avoid recursing.
	     */
	    oreadCheck  = readCheck;
	    owriteCheck = writeCheck;
	    odo_bblock  = do_bblock;

	    readCheck   = writeCheck = do_bblock = FALSE;

	    /*
	     * Invoke the macro. This frees the argument we malloc'd, and the
	     * strings contained in those arguments.
	     *
	     * We need to preserve the size so that we can register a
	     * fixup to be taken during pass 2. The problem is that we may
	     * be invoking these macros on undefined symbols. These symbols
	     * may not be actual address expressions, which means that rather
	     * than generating an error in the read/write check stuff, we
	     * really want to just nuke the entire read/write check.
	     *
	     * Since we can't wait to invoke the macro (because all code needs
	     * to be present in pass-1) we invoke the macro now, and then
	     * later on we remove the macro code (using the fixup mechanism)
	     * if it turns out the the macro was invoked in error.
	     */
	    oldDot = dot;
	    InvokeCheckMacro(macroSym, checkExpr, checkRes, stat);
	    *addrPtr = dot;

	    Fix_Register(FC_UNDEF, FixupReadWriteCheck, oldDot, (dot-oldDot),
			 (Expr *)checkExpr, (Expr *)NULL, (Opaque)NULL);

	    readCheck  = oreadCheck;
	    writeCheck = owriteCheck;
	    do_bblock  = odo_bblock;
	}
    }
}


/***********************************************************************
 *				CodeCleanup
 ***********************************************************************
 * SYNOPSIS:	    Take care of any extra memory allocated by
 *		    CodeInitial
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    res1 and res2 may become invalid
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/19/94	Initial Revision
 *
 ***********************************************************************/
static void
CodeCleanup(Expr    	*expr1,
	    ExprResult 	*res1,
	    Expr    	*expr2,
	    ExprResult 	*res2)
{
    /*
     * If the 1st result is a string that's not within the element array for
     * the expression, it means it was copied onto the heap by CodeInitial
     * before doing any read/write checking. We need to free it.
     * Note that to cope with the swapping of results CodeCompatible performs,
     * we have to check for the result string being within the elements of
     * both expressions, not just the one from which it ostensibly came.
     */
    if (expr1 &&
	res1->type == EXPR_TYPE_STRING &&
	(res1->data.str >= expr1->elts[expr1->numElts].str ||
	 res1->data.str < expr1->elts[0].str) &&
	(expr2 == NULL ||
	 res1->data.str >= expr2->elts[expr2->numElts].str ||
	 res1->data.str < expr2->elts[0].str))
    {
	free(res1->data.str);
	/* Allow duplicate calls by pointing the thing into the element array */
	res1->data.str = expr1->elts[0].str;
    }

    /*
     * Likewise for the second result.
     */
    if (expr2 &&
	res2->type == EXPR_TYPE_STRING &&
	(res2->data.str >= expr2->elts[expr2->numElts].str ||
	 res2->data.str < expr2->elts[0].str) &&
	(expr1 == NULL ||
	 res2->data.str >= expr1->elts[expr1->numElts].str ||
	 res2->data.str < expr1->elts[0].str))
    {
	free(res2->data.str);
	/* Allow duplicate calls by pointing the thing into the element array */
	res2->data.str = expr2->elts[0].str;
    }
}


/***********************************************************************
 *				CodeInitial
 ***********************************************************************
 * SYNOPSIS:	    Perform initial checks on code generator operands
 * CALLED BY:	    All code generators
 * RETURN:	    FR_ERROR or FR_UNDEF if one of these, or FR_DONE if ok
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/23/89		Initial Revision
 *
 ***********************************************************************/
static FixResult
CodeInitial(int	    	*addrPtr,   /* Start of instruction area */
	    int	    	pass,       /* Current pass */
	    Expr    	*expr1,	    /* First operand (required) */
	    ExprResult	*res1,	    /* Result of evaluation (required) */
	    Expr    	*expr2,	    /* Second operand (may be null) */
	    ExprResult	*res2,	    /* Result of evaluation (may be null) */
	    FixProc 	*proc,	    /* Calling procedure (register in case
				     * of undefined symbols) */
	    int	    	defSize,    /* Default size in case of undefined syms*/
	    Opaque  	data,	    /* Data to pass to Fix_Register */
	    int	    	*delayPtr)  /* Place to store if use of either result
				     * should be delayed */
{
    byte    	stat1, stat2;
    int	    	flags;

    flags = ((pass>1) ? EXPR_NOUNDEF : 0) | ((pass==4) ? EXPR_FINALIZE : 0);

    if (expr1) {
	if (!Expr_Eval(expr1, res1, flags, &stat1)) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line, (char *)res1->type);
	    /*
	     * Catch errors in expr2 as well
	     */
	    if (expr2 && !Expr_Eval(expr2, res2, flags, &stat2)) {
		Notify(NOTIFY_ERROR, expr2->file, expr2->line,
			(char *)res2->type);
	    }
	    return(FR_ERROR);
	}
    } else {
	/*
	 * Set stat1 to avoid extra cruft below
	 */
	stat1 = EXPR_STAT_DEFINED;
    }

    if (expr2) {
	if (!Expr_Eval(expr2, res2,
		       flags | (proc == Code_Lea ? EXPR_NOT_OPERAND : 0),
		       &stat2))
	{
	    Notify(NOTIFY_ERROR, expr2->file, expr2->line, (char *)res2->type);
	    return(FR_ERROR);
	}
    } else {
	/*
	 * Set stat2 to avoid extra cruft below
	 */
	stat2 = EXPR_STAT_DEFINED;
    }

    /*
     * When we invoke the macro, the expressions we are using will get
     * nuked. This is bad for us, and is bad for whoever called this
     * routine (because they are depending on these values as well).
     *
     * We therefore need to save and restore expr1/2.
     */
    if (pass == 1 && ((readCheck == TRUE) || (writeCheck == TRUE))) {
	Expr	*e1 = NULL,
	    	*e2 = NULL;
	byte	stat= 0;

	/*
	 * Cope with EXPR_TYPE_STRING results in res1 or res2, as they might
	 * point into expr1->elts or expr2->elts...
	 */
	if (expr1 != NULL && (stat1 & EXPR_STAT_DEFINED) &&
	    res1->type == EXPR_TYPE_STRING &&
	    res1->data.str > expr1->elts[0].str &&
	    res1->data.str < expr1->elts[expr1->numElts].str)
	{
	    char    *cp = (char *)malloc(strlen(res1->data.str)+1);

	    strcpy(cp, res1->data.str);
	    res1->data.str = cp;
	}

	if (expr2 != NULL && (stat2 & EXPR_STAT_DEFINED) &&
	    res2->type == EXPR_TYPE_STRING &&
	    res2->data.str > expr2->elts[0].str &&
	    res2->data.str < expr2->elts[expr2->numElts].str)
	{
	    char    *cp = (char *)malloc(strlen(res2->data.str)+1);

	    strcpy(cp, res2->data.str);
	    res2->data.str = cp;
	}

	/*
	 * Duplicate the expressions so that when they get toasted we can
	 * cope with it.
	 */
	if (expr1 != NULL) {
	    e1 = Expr_Copy(expr1, FALSE);
	}

	if (expr2 != NULL) {
	    e2 = Expr_Copy(expr2, FALSE);
	}

	if (readCheck == TRUE) {
	    /*
	     * Perform read checking. Read checking is done by invoking the
	     * macro '_readcheck' passing it enough information to allow
	     * it to verify that the read is legal. This information includes
	     * the segment register and offset of the read.
	     *
	     * In 80x86 a reasonable rule of thumb is:
	     *  	If there is more than one argument, then the
	     *	    	    second argument is being read from.
	     *  	If there is only one argument, then that argument
	     *	    	    is being read from.
	     */
	     Expr   	*readArg;
	     ExprResult *readRes;

	     if (e2 == NULL) {
		/* One argument to the opcode. Read from it */
		readArg = e1;
		readRes = res1;
		stat	= stat1;
	     } else {
		/* Two arguments to the opcode. Reading from the second */
		readArg = e2;
		readRes = res2;
		stat	= stat2;
	     }

	 CodeCheckExpression(readArg,readRes,CHECK_VALID_READ,addrPtr,proc,stat);
	}

	if (writeCheck == TRUE) {
	    /*
	     * Perform write checking. Write checking is done by invoking the
	     * macro '_writecheck' passing it enough information to allow
	     * it to verify that the write is legal. This information includes
	     * the segment register and offset of the write.
	     *
	     * Write checking is only performed if there are two arguments to
	     * the opcode. If there are two arguments, then write-checking
	     * is performed on the first one only.
	     */
	    if ((e1 != NULL) && (e2 != NULL)) {
	    CodeCheckExpression(e1, res1, CHECK_VALID_WRITE, addrPtr,proc,stat1);
	    }
	}

	/*
	 * To restore the state we set expr1/2 to what they were before
	 * and make sure to clean up after ourselves.
	 */
	if (e1 != NULL) {
	    if (malloc_size((void *)expr1->elts) != 0) {
		/*
		 * 'expr1' may have been reused. Regardless the elements
		 * are now located in some buffer allocated on the heap.
		 * We nuke this space, because it may not be the right
		 * size for the datal
		 */
		if (expr1->elts == (ExprElt *)(expr1+1)) {
		    Expr *q;

		    q = (Expr *)realloc((malloc_t)expr1, sizeof(Expr));
		    assert(q == expr1);

		} else {
		    free((malloc_t)expr1->elts);
		}
	    }
	    /*
	     * Copy the expression.
	     */
	    *expr1 = *e1;

	    /*
	     * Copy the elements to a location we allocate for them.
	     */
	    expr1->elts = (ExprElt *)malloc(e1->numElts*sizeof(ExprElt));
	    bcopy((void *)e1->elts, (void *)expr1->elts, e1->numElts*sizeof(ExprElt));

	    /*
	     * Free the expression we were temporarily using.
	     */
	    Expr_Free(e1);
	}

	if (e2 != NULL) {
	    /*
	     * See the documentation for 'e1' above.
	     */

	    if (malloc_size((void *)expr2->elts) != 0) {
		if (expr2->elts == (ExprElt *)(expr2+1)) {
		    Expr *q;

		    q = (Expr *)realloc((malloc_t)expr2, sizeof(Expr));
		    assert(q == expr2);

		} else {
		    free((malloc_t)expr2->elts);
		}
	    }

	    *expr2 = *e2;

	    expr2->elts = (ExprElt *)malloc(e2->numElts*sizeof(ExprElt));
	    bcopy((void *)e2->elts, (void *)expr2->elts, e2->numElts*sizeof(ExprElt));

	    Expr_Free(e2);
	}
    }

    if (!(stat1 & EXPR_STAT_DEFINED) || !(stat2 & EXPR_STAT_DEFINED)) {
	/*
	 * If either operand is undefined, allocate the usual amount of
	 * space required for this instruction but don't put anything in
	 * there -- it'll be overwritten in later passes. Register an UNDEF
	 * fixup with the Fix module to be called in pass 2 (we must be in
	 * pass 1 or Expr_Eval would have returned 0 for the undefined things).
	 */
	Fix_Register(FC_UNDEF, proc, *addrPtr, defSize, expr1, expr2, data);

	Table_StoreZeroes(curSeg->u.segment.code, defSize, *addrPtr);
	*addrPtr += defSize;

	CodeCleanup((stat1 & EXPR_STAT_DEFINED) ? expr1 : NULL, res1,
		    (stat2 & EXPR_STAT_DEFINED) ? expr2 : NULL, res2);
	return(FR_UNDEF);
    }

    *delayPtr = (stat1 | stat2) & EXPR_STAT_DELAY;

    return(FR_DONE);
}


/***********************************************************************
 *				CodeSimplifyType
 ***********************************************************************
 * SYNOPSIS:	    Simplify an operand type so it's something the
 *	    	    the processor could deal with (i.e. not an array
 *	    	    or a structure).
 * CALLED BY:	    CodeCompatible
 * RETURN:	    *typePtr modified to be proper type.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/23/89		Initial Revision
 *
 ***********************************************************************/
static void
CodeSimplifyType(TypePtr    *typePtr,	/* Ptr to type to simplify */
		 ID	    file,  	/* File in which it occurred */
		 int	    line,   	/* Line at which it occurred */
		 int        warn)   	/* Warn if *typePtr null */
{
    /*
     * Don't die on untyped expressions...
     */
    if (*typePtr == NULL) {
	if (warn) {
	    Notify(NOTIFY_WARNING, file, line,
		   "defaulting operand size to byte");
	}
	*typePtr = Type_Int(1);
	return;
    }

    /*
     * Wade through any layers of typedefs first. This allows us to simplify
     * array typedefs and others to be less bother to the user. It also
     * makes good sense...
     */
    while (((*typePtr)->tn_type == TYPE_STRUCT) &&
	   ((*typePtr)->tn_u.tn_struct->type == SYM_TYPE))
    {
	*typePtr = (*typePtr)->tn_u.tn_struct->u.typeDef.type;
    }

    /*
     * If the thing's an array, get to its most elemental form.
     */
    while ((*typePtr)->tn_type == TYPE_ARRAY) {
	(*typePtr) = (*typePtr)->tn_u.tn_array.tn_base;
    }

    /*
     * See if referring to a structure as a whole and complain about
     * the lack of field usage if so.
     */
    if (((*typePtr)->tn_type == TYPE_STRUCT) &&
	((*typePtr)->tn_u.tn_struct->type == SYM_STRUCT))
    {
	int 	size;

	Notify(NOTIFY_WARNING, file, line,
	       "reference to structure type %i without field name",
	       (*typePtr)->tn_u.tn_struct->name);

	size = Type_Size(*typePtr);

	if (procType & PROC_80386) {
	    if (size > 4) {
		/*
		 * XXX: this isn't right -- base decision on USE size of
		 * current segment.
		 */
		Notify(NOTIFY_WARNING, file, line,
		       "assuming dword-sized operation");
		*typePtr = Type_Int(4);
	    }
	} else if (size > 2) {
	    Notify(NOTIFY_WARNING, file, line,
		   "assuming word-sized operation");
	    *typePtr = Type_Int(2);
	}
    }
}

/***********************************************************************
 *				CodeMangleString
 ***********************************************************************
 * SYNOPSIS:	    Convert a string operand to a numeric operand for
 *	    	    use with the given type.
 * CALLED BY:	    CodeCompatible, various code generators
 * RETURN:	    Size of the given type.
 * SIDE EFFECTS:    res->type and res->data.number altered (string is
 *	    	    lost).
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/28/89		Initial Revision
 *
 ***********************************************************************/
static int
CodeMangleString(Expr	    	*expr1,
		 Expr	    	*expr2,
		 ExprResult 	*res,
		 TypePtr    	type,
		 ID	    	file,
		 int	    	line)
{
    int 	size;
    int 	len;
    char	*str;
    int	    	freeStr;

    size = Type_Size(type);

    /*
     * Convert the string constant to a numeric constant, trimming the
     * string to fit in the dest, as needed (and warning about same,
     * of course).
     */
    str = res->data.str;
    len = strlen(str);
    freeStr = (str < expr1->elts[0].str ||
	       str >= expr1->elts[expr1->numElts].str) &&
		   (expr2 == NULL ||
		    str < expr2->elts[0].str ||
		    str >= expr2->elts[expr2->numElts].str);

    if (len > size) {
	Notify(NOTIFY_WARNING, file, line,
	       "string constant truncated to %d byte%s",
	       size, size == 1 ? "" : "s");
	len = size;
    }
    res->data.number = 0;
    while(len-- > 0) {
	if (masmCompatible || reverseString) {
	    /*
	     * MASM places the first byte higher in the word...
	     */
	    res->data.number <<= 8;
	    res->data.number |= *str++ & 0xff;
	} else {
	    /*
	     * We think it makes more sense to have it lower in the
	     * word, since that's lower in memory...
	     */
	    res->data.number <<= 8;
	    res->data.number |= str[len] & 0xff;
	}
    }
    /*
     * Any unfilled higher bytes are left 0...
     */

    res->type = EXPR_TYPE_CONST;

    if (freeStr) {
	free(str);
    }

    return(size);
}


/***********************************************************************
 *				CodeCompatible
 ***********************************************************************
 * SYNOPSIS:	    Type-check the two operands of an instruction
 * CALLED BY:	    Various Code functions
 * RETURN:	    1 if they're compatible, 0 if not
 * SIDE EFFECTS:    - An error message is generated if they're not
 *	    	    - STRING constants are converted to numeric constants
 *	    	    based on the size of the destination.
 *	    	    - If res1 is constant and res2 isn't and commute is
 *	    	    true, *res1 and *res2 are swapped.
 *	    	    - The types of both operands are simplified to be
 *	    	    something the machine can handle (i.e. their size
 *	    	    is <= the word size of the processor).
 *	    	    - On error, CodeCleanup will have been called
 *
 * STRATEGY:
 *	Checks the following cases:
 *	    - byte/word ea mismatches
 *	    - double mem operands (except for strings)
 *	    - string constant too long to be used as immediate
 *	    - constant in wrong position
 *	    - double immediate operands
 *	    - signed/unsigned immediate constant too big for destination
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/23/89		Initial Revision
 *
 ***********************************************************************/
static int
CodeCompatible(Expr 	    *expr1, 	/* First operand */
	       ExprResult   *res1,  	/* Result of parsing first operand */
	       Expr 	    *expr2, 	/* Second operand */
	       ExprResult   *res2,  	/* Result of parsing second operand */
	       int  	    commute,	/* TRUE if instruction commutative,
					 * so immediate in res1 is ok */
	       int  	    isString,	/* TRUE if instruction is a string
					 * instruction and should have two
					 * memory operands */
	       int  	    delay,  	/* TRUE if constant value may be
					 * inaccurate due to needed delay
					 * until final pass */
	       int  	    *opSize)	/* OUT: Operand size */
{
    ID	    file;
    int	    line;

    if (expr1) {
	file = expr1->file; line = expr1->line;
    } else if (expr2) {
	file = expr2->file; line = expr2->line;
    } else {
	file = NullID; line = 0;
    }

    if (RES_IS_CONST(res1->type)) {
	if (isString) {
	    Notify(NOTIFY_ERROR, file, line,
		   "dual-operand string instructions require both operands to be in memory");
	    CodeCleanup(expr1, res1, expr2, res2);
	    return(0);
	}

	/*
	 * Make sure they're not both immediate...
	 */
	if (RES_IS_CONST(res2->type)) {
	    Notify(NOTIFY_ERROR, file, line,
		   "can't have two immediate operands in one instruction");
	    CodeCleanup(expr1, res1, expr2, res2);
	    return(0);
	} else {
	    /*
	     * First operand immediate -- see if we're allowed to swap it.
	     */
	    if (!commute) {
		Notify(NOTIFY_ERROR, file, line,
		       "immediate value (%d) not allowed as destination",
		       res1->data.number);
		CodeCleanup(expr1, res1, expr2, res2);
		return(0);
	    } else {
		/*
		 * Perform operand swap for caller
		 */
		ExprResult	temp = *res1;
		Expr	    	*texpr = expr1;

		Notify(NOTIFY_WARNING, file, line,
		       "immediate value (%d) not allowed as destination -- swapping with source",
		       res1->data.number);

		expr1 = expr2;
		expr2 = texpr;

		*res1 = *res2;
		*res2 = temp;

		/*
		 * Make sure the other operand isn't a segment register --
		 * can't do anything with an immediate value and a segment
		 * register in this world...
		 */
		if (EXPR_IS_SEGREG(res1)) {
		    Notify(NOTIFY_ERROR, file, line,
			   "immediate data and segment registers don't mix");
		    CodeCleanup(expr1, res1, expr2, res2);
		    return(0);
		}
	    }
	}
    }

    /*
     * If res2 is a string constant, convert it to an immediate constant
     * based on the size of res1 (at this point we know the type isn't
     * a constant, so we can safely call Type_Size).
     */
    if (res2->type == EXPR_TYPE_STRING) {
	/*
	 * Make sure the dest is something the machine can handle
	 */
	if (isString) {
	    Notify(NOTIFY_ERROR, file, line,
		   "dual-operand string instructions require both operands to be in memory");
	    CodeCleanup(expr1, res1, expr2, res2);
	    return(0);
	}

	CodeSimplifyType(&res1->type, file, line, TRUE);

	*opSize = CodeMangleString(expr2, expr1, res2, res1->type, file, line);
    } else if (res2->type == EXPR_TYPE_CONST) {
	/*
	 * Source is straight numeric constant -- make sure it's not too
	 * big for the destination.
	 */
	int 	size;
	int 	highmask;

	if (isString) {
	    Notify(NOTIFY_ERROR, file, line,
		   "dual-operand string instructions require both operands to be in memory");
	    CodeCleanup(expr1, res1, expr2, res2);
	    return(0);
	}

	/*
	 * Deal with immediate constant that can't fit in a byte when
	 * coupled with a typeless destination.
	 */
	if ((res1->type == NULL) &&
	    ((res2->data.number < -128) || (res2->data.number > 127)))
	{
	    res1->type = Type_Int(2);
#if 0
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "defaulting operand size to word");
#endif
	}

	CodeSimplifyType(&res1->type, file, line, TRUE);
	*opSize = size = Type_Size(res1->type);

	/*
	 * Deal with relocatable constants by seeing if the fixup size
	 * is larger than the res1 operand size and generating an error
	 * if so.
	 */
	if (res2->rel.sym) {
	    int	res2size;

	    switch (res2->rel.size) {
		case FIX_SIZE_BYTE:
		    res2size = 1;
		    break;
		case FIX_SIZE_WORD:
		    res2size = 2;
		    break;
		default:
		    assert(0);
		    /*FALLTHRU*/
		case FIX_SIZE_DWORD:
		    res2size = 4;
		    break;
	    }
	    if (res2size > size) {
		Notify(NOTIFY_ERROR, file, line,
		       "relocatable constant too big to fit in %d byte%s",
		       size, (size == 1 ? "" : "s"));
	    }
	}


	if (size != 4) {
	    highmask = ~((1 << (size*8))-1);
	    /*
	     * We allow either signed or unsigned constants here: If the bits
	     * that won't fit are simply an extension of the MSB that will fit,
	     * or if the bits that won't fit are all 0, the constant is ok.
	     *
	     * One more special case arises from the use of the NOT
	     * operator on the MSB of the data type. In this case,
	     * the 1's beyond the type are machine-generate and
	     * thus not significant.
	     */
	    if (!delay && (res2->data.number & highmask)) {
		highmask |= highmask >> 1;
		if (((res2->data.number & highmask) != highmask) &&
		    !Expr_InvolvesOp(expr2, EXPR_NOT))
		{
		    Notify(NOTIFY_WARNING, file, line,
			   "immediate constant won't fit in %d byte%s",
			   size, size == 1 ? "" : "s");
		}
	    }
	} else if (!(procType & (PROC_80386|PROC_80486))) {
	    /*
	     * Processors < '386 cannot handle manipulating a dword in any
	     * instruction but LDS/LES and we're not called for them, so
	     * warn the user...
	     */
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "assuming word-sized operation (current processor can't manipulate something larger than a word)");
	    *opSize = size = 2;
	}
    } else {
	/*
	 * Both operands are ea's. Make sure they're not both memory-oriented.
	 * Note that segment registers appear to be weird memory-oriented
	 * operands, so we have to make sure neither operand is a segment
	 * register before complaining about double memory operands.
	 */
	int 	size1, size2;

	if (((res1->data.ea.modrm & MR_DISP_MASK) != MR_REG) &&
	    ((res2->data.ea.modrm & MR_DISP_MASK) != MR_REG) &&
	    !EXPR_IS_SEGREG(res1) && !EXPR_IS_SEGREG(res2))
	{
	    if (!isString) {
		Notify(NOTIFY_ERROR, file, line,
		       "can't give two memory operands to one instruction");
		CodeCleanup(expr1, res1, expr2, res2);
		return(0);
	    }
	} else if (isString) {
	    Notify(NOTIFY_ERROR, file, line,
		   "dual-operand string instructions require both operands to be in memory");
	    CodeCleanup(expr1, res1, expr2, res2);
	    return(0);
	}

	/*
	 * If only one of the two types is undefined, we take the size for the
	 * operation from the other one.
	 */
	if (res1->type == NULL) {
	    res1->type = res2->type;
	} else if (res2->type == NULL) {
	    res2->type = res1->type;
	}

	/*
	 * Simplify both types so we can perform a reasonable comparison
	 */
	CodeSimplifyType(&res1->type, file, line, FALSE);
	CodeSimplifyType(&res2->type, file, line, FALSE);

	/*
	 * Fetch both their sizes (for use in error message, as well as
	 * compare)
	 */
	*opSize = size1 = Type_Size(res1->type);
	size2 = Type_Size(res2->type);

	if (size1 == 0 && size2 == 0) {
	    Notify(NOTIFY_WARNING, file, line,
		   "defaulting operand size to byte");
	    *opSize = 1;
	} else if (size1 == 0) {
	    /*
	     * Take operand size from second operand if first is unknown.
	     */
	    *opSize = size2;
	} else if (size1 != size2 && size2 != 0) {
	    /*
	     * HONK -- there's no sign-extension for non-immediate values
	     * here.
	     */
	    Notify(NOTIFY_ERROR, file, line,
		   "size mismatch (dest is %d byte%s, source is %d byte%s)",
		   size1, size1 == 1 ? "" : "s",
		   size2, size2 == 1 ? "" : "s");
	    CodeCleanup(expr1, res1, expr2, res2);
	    return(0);
	} else if ((size1 > 2) && !(procType & (PROC_80386|PROC_80486))) {
	    /*
	     * Processors < '386 cannot handle manipulating a dword in any
	     * instruction but LDS/LES and we're not called for them, so
	     * warn the user...
	     */
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "assuming word-sized operation (current processor can't manipulate something larger than a word)");
	    *opSize = 2;
	}
    }

    /*
     * All is groovy.
     */
    return(1);
}

/***********************************************************************
 *				CodeStoreEA
 ***********************************************************************
 * SYNOPSIS:	    Store an effective address
 * CALLED BY:	    Various Code routines
 * RETURN:	    Pointer past stored ea
 * SIDE EFFECTS:    Bytes be stored, mahn
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/23/89		Initial Revision
 *
 ***********************************************************************/
static byte *
CodeStoreEA(byte    	*buf,	    /* Place to start storing */
	    byte    	modrm,	    /* ModRM byte */
	    byte    	reg,	    /* Reg field to merge in */
	    byte	isDWord,    /* 32-bit ea */
	    byte	sib,	    /* optional SIB byte for 32-bit ea */
	    dword    	disp,	    /* Displacement */
	    int	    	prev,	    /* Previous size */
	    int	    	cur,	    /* # bytes stored by caller. If this
				     * plus the number of bytes we will store
				     * gives a length difference >= 1 and odd
				     * and a byte displacement is being used,
				     * the byte will be extended to a word
				     * as that doesn't cost any cycles
				     * while a NOP does. The check for odd
				     * is b/c our two-byte nop is faster than
				     * a single-byte nop, so no point in
				     * forcing a single-byte nop... */
	    int	    	pass,	    /* Pass number. If this is still pass 2
				     * or 3, we're allowed to change the size
				     * of the effective address, rather than
				     * using a word displacement instead of
				     * a byte... */
	    int		*pFixAddr)  /* Pointer to fixup address, so we can
				     * up it in case a SIB byte is used. */
{
    *buf++ = modrm | reg;
    if (!isDWord) {
	/* 16-bit Address Mode */
	if (modrm == MR_DIRECT) {
	    *buf++ = (byte)disp;
	    *buf++ = (byte)(disp >> 8);
	} else {
	    switch(modrm & MR_DISP_MASK) {
	    case MR_BYTE_DISP:
	    {
		int diff = (prev - (cur+2));

		*buf++ = (byte)disp;
		if ((pass == 4) && (diff >= 1) && (diff & 1)) {
		    /*
		     * Too late to adjust the size of the instruction, so
		     * convert the thing to a word displacement.
		     *
		     * Invert bits 7 and 6 (which are 01 for byte disp
		     * while we need 10 for word) of the modrm byte
		     * and sign-extend the displacement.
		     */
		    buf[-2] ^= 0xc0;
		    *buf++ = (disp & 0x80 ? 0xff : 0);
		}
		break;
	    }
	    case MR_WORD_DISP:
		*buf++ = (byte)disp;
		*buf++ = (byte)(disp >> 8);
		break;
	    }
	}
    } else {
	/* 32-bit Address Mode */
	if ((modrm & MR_RM_MASK) == MR_SIB) {
	    *buf++ = sib;
	    *pFixAddr += 1;
	}
	if (modrm == MR_DIRECT32) {
	    *buf++ = (byte)disp;
	    *buf++ = (byte)(disp >> 8);
	    *buf++ = (byte)(disp >> 16);
	    *buf++ = (byte)(disp >> 24);
	} else {
	    switch(modrm & MR_DISP_MASK) {
	    case MR_BYTE_DISP:
		*buf++ = (byte)disp;
		break;
	    case MR_DWORD_DISP:
		*buf++ = (byte)disp;
		*buf++ = (byte)(disp >> 8);
		*buf++ = (byte)(disp >> 16);
		*buf++ = (byte)(disp >> 24);
		break;
	    }
	}
    }

    return(buf);
}


/***********************************************************************
 *				CodeNopPad
 ***********************************************************************
 * SYNOPSIS:	    Pad an instruction buffer out with NOPs.
 * CALLED BY:	    Code_Jcc, Code_Jmp
 * RETURN:	    Pointer to byte after last stored nop
 * SIDE EFFECTS:    A warning message is issued
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/27/89		Initial Revision
 *
 ***********************************************************************/
static byte *
CodeNopPad(byte	    *ip,    	/* Place to store first NOP */
	   int	    diff,   	/* Number of bytes to fill */
	   ID	    file,  	/* File name of offending instruction */
	   int	    line)   	/* Line number of same */
{
    Notify(NOTIFY_WARNING, file, line, "%d NOP%s inserted", diff,
	   diff == 1 ? "" : "s");

    /*
     * Store "fast" NOPs:  MOV AX, AX
     */
    while (diff >= 2) {
	*ip++ = 0x89;
	*ip++ = MR_REG | (REG_AX << MR_REG_SHIFT) | REG_AX;
	diff -= 2;
    }

    /*
     * Store slow NOPs in remaining byte: NOP
     */
    if (diff) {
	*ip++ = 0x90;
    }

    return(ip);
}


/***********************************************************************
 *				CodeFinal
 ***********************************************************************
 * SYNOPSIS:	    Perform final processing on the instruction being
 *	    	    generated.
 * CALLED BY:	    All Code routines
 * RETURN:	    *addrPtr adjusted to point past the instruction.
 * SIDE EFFECTS:    The instruction is stored and the size allocated
 *	    	    for it may have changed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/23/89		Initial Revision
 *
 ***********************************************************************/
static void
CodeFinal(int	    	*addrPtr,   /* Place to store instruction */
	  int	    	pass,       /* Current pass # (tells whether to
				     * resize old area) */
	  int	    	length,     /* Length of instruction being stored */
	  int	    	prevLength, /* Length from earlier pass */
	  byte	    	*ibuf,      /* Instruction bytes */
	  ExprResult	*fixRes,    /* Result for which to generate an
				     * external fixup, if required */
	  int	    	fixAddr,    /* Address of data to be fixed (-1 if
				     * not determined yet). */
	  ID	    	file,	    /* File in which instruction was */
	  int	    	line,	    /* Line number of instruction */
	  int		delay)	    /* Set true by CodeInitial if the use of
				     * one of the results is to be delayed
				     * until the final pass. A delayed result
				     * means we'll be called again during the
				     * final pass, so we shouldn't enter an
				     * external fixup no matter what fixAddr
				     * and fixRes are... */
{
    /*
     * ibuf contains the instruction to store length is its length.
     * Adjust our allocated storage appropriately. This adjustment occurs
     * only after pass 1, as it's only then that we're allowed to insert
     * or delete bytes -- during pass 1, we just get to overwrite things.
     */
    if (pass != 1) {
	int 	diff;

	diff = length - prevLength;
	if (diff < 0) {
	    if (pass == 4) {
		/*
		 * Nothing we can do now -- Pad the thing with NOPs (this
		 * assumes the buffer is big enough to hold the extra, since
		 * it held them in a previous pass).
		 */
		CodeNopPad(ibuf+length,
			   -diff,
			   file,
			   line);
		length = prevLength;
	    } else {
		Table_Delete(curSeg->u.segment.code,
			     *addrPtr, -diff);
	    }
	} else if ((diff > 0)  && (pass != 4)) {
	    /*
	     * Can't do this on pass 4. Note if it is pass 4, the
	     * fixup module will bitch about a change in length...
	     */
	    Table_Insert(curSeg->u.segment.code, *addrPtr, diff);
	}
    }
    /*
     * Now the size is right, store in the bytes we've figured.
     */
    Table_Store(curSeg->u.segment.code, length, (void *)ibuf,
		*addrPtr);

    /*
     * Register external fixup if required. Note that fixAddr < 0 means
     * fixRes may not have been given, hence the order of evaluation here.
     */
    if (!delay && fixAddr >= 0 && fixRes->rel.sym) {
	Fix_Enter(fixRes, fixAddr, *addrPtr);
    }

    /*
     * Adjust the current address to point beyond the instruction just stored
     */
    *addrPtr += length;
}


/***********************************************************************
 *				CodeNoConstant
 ***********************************************************************
 * SYNOPSIS:	    Make sure neither operand to an instruction is
 *	    	    immediate data.
 * CALLED BY:	    Various generators
 * RETURN:	    FR_ERROR if either is immediate, FR_DONE if neither is
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/27/89		Initial Revision
 *
 ***********************************************************************/
static FixResult
CodeNoConstant(Expr 	    *expr1,
	       ExprResult   *res1,  	/* First operand */
	       Expr 	    *expr2,
	       ExprResult   *res2,  	/* Second operand (optional) */
	       ID 	    file,  	/* File containing both */
	       int  	    line,   	/* Line # of first */
	       OpCode	    *op)    	/* Opcode involved */
{
    FixResult	result = FR_DONE;

    if (res1 && RES_IS_CONST(res1->type)) {
	Notify(NOTIFY_ERROR, file, line,
	       "immediate data not allowed as destination for %s",
	       op->name);
	CodeCleanup(expr1, res1, expr2, res2);
	result = FR_ERROR;
    }
    if (res2 && RES_IS_CONST(res2->type)) {
	Notify(NOTIFY_ERROR, file, line,
	       "immediate data not allowed as source for %s",
	       op->name);
	CodeCleanup(expr1, res1, expr2, res2);
	result = FR_ERROR;
    }

    return(result);
}

/*****************************************************************************
 *
 *			   CODE GENERATORS
 *
 ****************************************************************************/


/***********************************************************************
 *				CodeArithCommon
 ***********************************************************************
 * SYNOPSIS:	    Generate the actual code for an arithmetic
 *	    	    instruction now that all the necessary data have been
 *	    	    found by our caller.
 * CALLED BY:	    Code_Arith2, Code_BitNF
 * RETURN:	    FixResult caller should return
 * SIDE EFFECTS:    The instruction is generated
 *
 * STRATEGY:
 *	This is one of the few reasonable groupings supported by the
 *	8086 instruction set. The OpCode record contains the base opcode,
 *	which is mapped to the proper byte based on the addressing modes
 *	for the two operands:
 *	    Modes:  	Encoding:
 *	    ======  	=========
 *	    eb,rb   	base	/r
 *	    ew,rw   	base+1	/r
 *	    rb,eb   	base+2	/r
 *	    rw,ew   	base+3	/r
 *	    al,db  	base+4	db
 *	    ax,dw   	base+5	dw
 *	    eb,db   	80 /n	db
 *	    ew,dw   	81 /n	dw
 *	    ew,db   	83 /n	db (sign-extended by processor)
 *	/n is simply <5:3> of base (just base & MR_REG).
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/28/89	Initial Revision
 *
 ***********************************************************************/
FixResult
CodeArithCommon(int 	    *addrPtr,	    /* Address for instruction.
					     * Modified to point after
					     * instruction */
		int 	    pass,   	    /* Current pass number */
		int 	    prevSize,	    /* Size of instruction during
					     * previous pass */
		Expr	    *expr1, 	    /* First operand */
		ExprResult  *res1,  	    /* Value of same */
		Expr	    *expr2, 	    /* Second operand */
		ExprResult  *res2,  	    /* Value of same */
		int 	    delay,  	    /* Whether any result should be
					     * delayed until final pass */
		OpCode	    *op,    	    /* Opcode being generated */
		int 	    notByte, 	    /* Zero if instruction should
					     * operate on bytes */
		int	    isDWord,	    /* Non-zero if instruction should
					     * operate on dwords */
		FixProc	    *caller)	    /* Pointer to caller (for
					     * registering any fixups) */
{
    ExprResult	*fixRes;    	/* Result holding external fixup data */
    int	    	startAddr;  	/* Address of instruction in case need to
				 * register a FINAL fixup to handle a
				 * delayed result */
    int 	fixAddr;	/* Address of any needed fixup */
    byte    	ibuf[7];    	/* 7 is the most we'll ever need: override,
				 * opcode, modrm, 2 for disp, 2 for data */
    byte    	*ip = ibuf;

    /*
     * Handle any segment override required by either result.
     */
    fixAddr = (*addrPtr) + 2;	/* If fix required, it'll be after ModRM
				 * byte, which is after instruction byte  */

    if (EXPR_NEEDS_OVERRIDE(res1)) {
	/*
	 * Override field is for real (1 is none known, 2 is default, 0
	 * for not mem ea), so store it away.
	 */
	*ip++ = res1->data.ea.override;
	fixAddr++;
    } else if (res2->type != EXPR_TYPE_CONST && EXPR_NEEDS_OVERRIDE(res2)) {
	*ip++ = res2->data.ea.override;
	fixAddr++;
    }
    if (USE_386() && notByte && ((isDWord && DWORD_OPER_NEEDS_PREFIX())
	|| (!isDWord && WORD_OPER_NEEDS_PREFIX()))) {
	*ip++ = PRE_OPERAND;
	fixAddr++;
    }

    if (res2->type == EXPR_TYPE_CONST) {
	/*
	 * First major class -- combining dest with immediate data.
	 */
	fixRes = res1;
	if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(res1)) {
	    *ip++ = PRE_ADDRESS;
	    fixAddr++;
	}

	if ((res1->data.ea.modrm == (MR_REG|REG_SP)) && notByte &&
	    ((op->value == 0x10) || /* ADC */
	     (op->value == 0x00) || /* ADD */
	     (op->value == 0x18) || /* SBB */
	     (op->value == 0x28)) &&/* SUB */
	    (res2->data.number & 1))
	{
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "adjusting SP by odd amount (%d) -- this will confuse Swat",
		   res2->data.number);
	}

	if (res1->data.ea.modrm == (MR_REG|REG_AX)) {
	    /*
	     * Immediate and accumulator: opcode is
	     *	    op->value+4+(notByte?1:0) d[bwd]
	     */
	    fixRes = res2;
	    fixAddr -= 1;

	    *ip++ = (op->value + 4 + notByte);
	    *ip++ = (byte)res2->data.number;
	    if (notByte) {
		*ip++ = (byte)(res2->data.number >> 8);
		if (isDWord) {
		    *ip++ = (byte)(res2->data.number >> 16);
		    *ip++ = (byte)(res2->data.number >> 24);
		}
	    }
	} else if ((((res2->data.number >= -128) &&
		     (res2->data.number <= 127)) ||
		    (!isDWord && (res2->data.number >= 65536-128)) ||
		    isDWord && (res2->data.number >= (0xffffffffUL-127))) &&
		   !res2->rel.sym &&
		   notByte)
	{
	    /*
	     * Use sign-extended form of the instruction. To refresh
	     * your memory, the encoding is 83 /n db. Note the need to
	     * compare the thing against 65536-128 as we can still use the
	     * sign-extension form for something like fffch...
	     */
	    *ip++ = 0x83;
	    ip = CodeStoreEA(ip,
			     res1->data.ea.modrm,
			     (byte)(op->value & MR_REG_MASK),
			     res1->data.ea.dword_ea,
			     res1->data.ea.sib,
			     res1->data.ea.disp,
			     prevSize,
			     (ip-ibuf)+1,
			     pass, &fixAddr);
	    *ip++ = (byte)res2->data.number;
	} else {
	    /*
	     * Use normal e[bwd], d[bwd] form:
	     *	80+w /n d[bwd]
	     */
	    *ip++ = 0x80 + notByte;
	    ip = CodeStoreEA(ip,
			     res1->data.ea.modrm,
			     (byte)(op->value & MR_REG_MASK),
			     res1->data.ea.dword_ea,
			     res1->data.ea.sib,
			     res1->data.ea.disp,
			     prevSize,
			     (ip-ibuf) + (1+notByte),
			     pass, &fixAddr);
	    if (res2->rel.sym) {
		/*
		 * Oy. Constant relocatable...enter special external
		 * fixup for the thing. No need to worry about a delayed result
		 * causing us to enter the fixup twice -- delayed results only
		 * occur for constants and one can only have one constant
		 * per instruction and this is it...
		 */
		Fix_Enter(res2, (*addrPtr)+(ip-ibuf), *addrPtr);
	    }
	    *ip++ = (byte)res2->data.number;
	    if (notByte) {
		*ip++ = (byte)(res2->data.number >> 8);
		if (isDWord) {
		    *ip++ = (byte)(res2->data.number >> 16);
		    *ip++ = (byte)(res2->data.number >> 24);
		}
	    }
	}
    } else if ((res1->data.ea.modrm & MR_DISP_MASK) == MR_REG) {
	/*
	 * Either both source and dest are registers, or source is a
	 * memory ea. In either case we use the
	 *	r[bwd], e[bwd]
	 * form: base+2 /r
	 */
	fixRes = res2;
	if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(res2)) {
	    *ip++ = PRE_ADDRESS;
	    fixAddr++;
	}

	*ip++ = op->value + 2 + notByte;
	ip = CodeStoreEA(ip,
			 res2->data.ea.modrm,
			 (byte)(res1->data.ea.modrm << MR_REG_SHIFT),
			 res2->data.ea.dword_ea,
			 res2->data.ea.sib,
			 res2->data.ea.disp,
			 prevSize,
			 ip-ibuf,
			 pass, &fixAddr);
    } else {
	/*
	 * Dest is memory, so source must be a register
	 */
	fixRes = res1;
	if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(res1)) {
	    *ip++ = PRE_ADDRESS;
	    fixAddr++;
	}

	*ip++ = op->value + notByte;
	ip = CodeStoreEA(ip,
			 res1->data.ea.modrm,
			 (byte)(res2->data.ea.modrm << MR_REG_SHIFT),
			 res1->data.ea.dword_ea,
			 res1->data.ea.sib,
			 res1->data.ea.disp,
			 prevSize,
			 ip-ibuf,
			 pass, &fixAddr);
    }

    /*
     * Finish off instruction.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, fixRes, fixAddr,
	      expr1->file, expr1->line, delay);

    if (delay) {
	if (pass > 1) {
	    /*
	     * Let fixup module promote us to a FINAL fixup.
	     */
	    CodeCleanup(expr1, res1, expr2, res2);
	    return(FR_FINAL);
	} else {
	    /*
	     * First pass -- register FINAL fixup explicitly so parser doesn't
	     * have to deal with it.
	     */
	    Fix_Register(FC_FINAL, caller,
			 startAddr, ip - ibuf, expr1, expr2, (Opaque)op);
	}
    }
    /*
     * This instruction is complete
     */
    CodeCleanup(expr1, res1, expr2, res2);
    return(FR_DONE);
}

/***********************************************************************
 *				Code_Arith2
 ***********************************************************************
 * SYNOPSIS:	    Generate code for ADD, ADC, AND, XOR, SBB, SUB, OR
 *	    	    and CMP instructions.
 * CALLED BY:	    yyparse, Fix module
 * RETURN:	    FR_ERROR, FR_OPTIM or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 *	All but SBB, SUB and CMP are commutative, so if expr1 is immediate,
 *	the operands are reversed.
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Arith2(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* Opcode/other data */
{
    ExprResult	res1, res2;
    OpCode  	*op = (OpCode *)data;
    int	    	opSize;
    int	    	notByte;    	/* 0 if opSize is 1, 1 if not -- used
				 * when forming opcodes */
    int		isDWord;	/* 1 if opSize is 4, 0 if not */
    int	    	delay;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    switch (CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 Code_Arith2, 4, data, &delay))
    {
	case FR_UNDEF: return(FR_UNDEF);
	case FR_ERROR: return (FR_ERROR);
    }

    /*
     * No undefined symbols means the types of the operands are known, so
     * we can type-check.
     */
    if (!CodeCompatible(expr1, &res1, expr2, &res2,
			((op->value != 0x18) &&	/* SBB */
			 (op->value != 0x28) &&	/* SUB */
			 (op->value != 0x38)),	/* CMP */
			FALSE,	/* Not string */
			delay,
			&opSize))
    {
	return(FR_ERROR);
    }
    notByte = (opSize == 1) ? 0 : 1;
    isDWord = (opSize == 4) ? 1 : 0;

    /*
     * Make sure neither operand is a segment register, since we can't
     * perform arithmetic on segment registers (sigh).
     */
    if (EXPR_IS_SEGREG(&res1) ||
	(res2.type != EXPR_TYPE_CONST && EXPR_IS_SEGREG(&res2)))
    {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "can't perform arithmetic on segment registers");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    /*
     * Wow. We can now generate code for the thing. The opcode is
     * generated in ibuf, with ip pointing past the last byte.
     *
     * First figure if a segment override is needed and stuff it in if
     * so.
     *
     * Then figure the opcode bytes and store them.
     *
     * Finally, figure how many bytes we'll need and insert (if not pass 1,
     * else store) or delete enough to install the instruction and operands,
     * do so and update *addrPtr and return FR_DONE to indicate that all fixes
     * are finished.
     */
    return(CodeArithCommon(addrPtr, pass, prevSize,
			   expr1, &res1, expr2, &res2, delay, op,
			   notByte, isDWord, Code_Arith2));
}


/***********************************************************************
 *				Code_Arpl
 ***********************************************************************
 * SYNOPSIS:	    Generate code for ARPL
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted.
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *	Allowed only when PROC_PRIV set.
 *	Usage is ARPL ew, rw and generates 63 /r
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Arpl(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[5];    	/* 1 override, 1 opcode, 1 modrm, 2 disp */
    byte    	*ip = ibuf;
    ExprResult	res1, res2;
    FixResult	result;
    int	    	fixAddr;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ASSERT_PROT();

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 Code_Arpl, 2, data, &delay);

    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure neither operand is a constant -- we don't do constants here
     */
    result = CodeNoConstant(expr1, &res1, expr2, &res2, expr1->file, expr1->line,
			    (OpCode *)data);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure neither operand is a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1) || EXPR_IS_SEGREG(&res2)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "ARPL can't operate on a segment register");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    /*
     * Make sure the source is a word register, but don't leave yet if it's
     * not -- want to catch any errors in the dest.
     */
    if (((res2.data.ea.modrm & MR_DISP_MASK) != MR_REG) ||
	(Type_Size(res2.type) != 2))
    {
	Notify(NOTIFY_ERROR, expr2->file, expr2->line,
	       "second operand for ARPL must be a word register");
	result = FR_ERROR;
    }

    /*
     * Simplify the type of the destination before checking its size
     */
    CodeSimplifyType(&res1.type, expr1->file, expr1->line, FALSE);

    /*
     * Make sure the destination is a word variable.
     */
    if (Type_Size(res1.type) != 2) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "first operand for ARPL must be a word variable");
	result = FR_ERROR;
    }

    if (result == FR_DONE) {
	/*
	 * Store override if needed
	 */
	fixAddr = (*addrPtr) + 2;
	if (EXPR_NEEDS_OVERRIDE(&res1)) {
	    *ip++ = res1.data.ea.override;
	    fixAddr++;
	}
	/*
	 * Store opcode (constant)
	 */
	*ip++ = 0x63;

	/*
	 * Store away the dest ea merged with the source reg
	 */
	ip = CodeStoreEA(ip,
			 res1.data.ea.modrm,
			 (byte)(res2.data.ea.modrm << MR_REG_SHIFT),
			 res1.data.ea.dword_ea,
			 res1.data.ea.sib,
			 res1.data.ea.disp,
			 prevSize,
			 ip-ibuf,
			 pass, &fixAddr);

	/*
	 * Install the instruction itself
	 */
	startAddr = *addrPtr;
	CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
		  expr1->file, expr1->line, delay);

	if (delay) {
	    if (pass > 1) {
		CodeCleanup(expr1, &res1, expr2, &res2);
		return(FR_FINAL);
	    } else {
		Fix_Register(FC_FINAL, Code_Arpl,
			     startAddr, ip - ibuf, expr1, expr2, data);
	    }
	}
    }

    /*
     * Return whatever result we've calculated
     */
    CodeCleanup(expr1, &res1, expr2, &res2);
    return(result);

}


/***********************************************************************
 *				Code_BitNF
 ***********************************************************************
 * SYNOPSIS:	    Generate code for ANDNF, XORNF, and ORNF instructions
 * CALLED BY:	    yyparse, Fix module
 * RETURN:	    FR_ERROR, FR_OPTIM or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *	This grouping is very similar to Code_Arith2, except we are allowed
 *	to optimize the use of an immediate mask with insignificant bits
 *	when combined with a word operand. For ANDNF, if one of the bytes
 *	is all 1's, we can optimize (the bits will not change). For XORNF
 *	and ORNF, if one of the bytes is all 0's, we can optimize (again,
 *	the bits will not change). In the normal forms of these three
 *	instructions, we cannot make these optimizations because the
 *	condition codes are altered based on the existing bits in the
 *	destination, even if the bits themselves don't change.
 *
 *	Ideally, the assembler would figure out if the user tries to use
 *	the condition codes resulting from one of these opcodes. This
 *	is a bit more work than I'm up to right now.
 *
 *	If expr1 is immediate, the operands are reversed.
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/27/89	Initial Revision
 *
 ***********************************************************************/
FixResult
Code_BitNF(int	    *addrPtr,	/* IN/OUT: Address of instruction start/end */
	   int      prevSize,  	/* # bytes previously allocated to inst */
	   int      pass,    	/* Current pass */
	   Expr     *expr1,    	/* Operand 1 */
	   Expr     *expr2,    	/* Operand 2 */
	   Opaque   data)	/* Opcode/other data */
{
    ExprResult	res1, res2;
    OpCode  	*op = (OpCode *)data;
    int	    	opSize;
    int	    	notByte;    	/* 0 if opSize is 1, 1 if not -- used
				 * when forming opcodes */
    int		isDWord;	/* 1 if opSize is 4, 0 if not */
    int	    	delay;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    switch (CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 Code_BitNF, 4, data, &delay))
    {
	case FR_UNDEF: return(FR_UNDEF);
	case FR_ERROR: return (FR_ERROR);
    }

    /*
     * No undefined symbols means the types of the operands are known, so
     * we can type-check.
     */
    if (!CodeCompatible(expr1, &res1, expr2, &res2,
			TRUE,	/* Commutative */
			FALSE,	/* Not string */
			delay,
			&opSize))
    {
	return(FR_ERROR);
    }
    notByte = (opSize == 1) ? 0 : 1;
    isDWord = (opSize == 4) ? 1 : 0;

    /*
     * Make sure neither operand is a segment register, since we can't
     * perform arithmetic on segment registers (sigh).
     */
    if (EXPR_IS_SEGREG(&res1) ||
	(res2.type != EXPR_TYPE_CONST && EXPR_IS_SEGREG(&res2)))
    {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "can't perform arithmetic on segment registers");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    /*
     * See if the instruction can be optimized and mangle res1 if so.
     */
    if (res2.type == EXPR_TYPE_CONST) {
	/*
	 * Set canopt to the value a byte of res2 must have if it is to be
	 * eliminated from the instruction. 0x20 is the opcode for AND.
	 */
	int canopt = ((op->value == 0x20)?0xff:0x00);

#if 0
	if (op->value == 0x20) {
	    char    *user = getenv("USER");
	    if (user && strcmp(user, "adam") == 0 &&
		expr2->numElts == 3 &&
		expr2->elts[0].op == EXPR_SYMOP &&
		expr2->elts[2].op == EXPR_MASK)
	    {
		Notify(NOTIFY_WARNING, expr2->file, expr2->line,
		       "ANDNF with MASK only");
	    }
	}
#endif

	/*
	 * If entire operand would have no effect on the destination other
	 * than setting flags, then optimize the whole thing out of existence.
	 */
	if ((notByte && (res2.data.number == (canopt | (canopt << 8)))) ||
	    (!notByte && ((res2.data.number & 0xff) == canopt)))
	{
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "instruction's only effect is to modify flags");
	}


	if (notByte && !isDWord &&
	    ((((res2.data.number & 0xff00) >> 8) == canopt) ||
	     ((res2.data.number & 0x00ff) == canopt)))
	{
	    /*
	     * If the operand size is a word and either byte of the mask
	     * is zero, it implies we can use a byte instruction anyway,
	     * as the bits in the high or low byte are insignificant.
	     */
	    if ((res1.data.ea.modrm & MR_DISP_MASK) == MR_REG) {
		/*
		 * We can only change to a byte form when the first operand
		 * is a register if it is one of the four general registers.
		 */
		if ((res1.data.ea.modrm & MR_RM_MASK) <= REG_BX) {
		    notByte = 0;
		    if (((res2.data.number & 0xff00) >> 8) != canopt) {
			/*
			 * Need to mangle the high byte -- convert the register
			 * number to the high byte register and shift the
			 * data value down to the low byte.
			 */
			res1.data.ea.modrm |= REG_AH;
			res2.data.number >>= 8;
		    }
		}
	    } else if (((res2.data.number & 0xff00) >> 8) == canopt) {
		/*
		 * Want to mangle the low byte -- nothing to do except set
		 * notByte to 0 so we only deal with bytes.
		 */
		notByte = 0;
	    } else if (res1.data.ea.modrm == MR_DIRECT) {
		/*
		 * Direct addressing mangling the high byte -- up the
		 * displacement by one is all we need to do for the address.
		 * Then we need to indicate it's a byte instruction and
		 * shift the high byte into the low byte for storage.
		 */
		res1.data.ea.disp += 1;
		res2.data.number >>= 8;
		notByte = 0;
	    } else {
		switch(res1.data.ea.modrm & MR_DISP_MASK) {
		    case MR_NULL_DISP:
			/*
			 * For an 8088, having a byte displacement is no
			 * worse than fetching the extra byte from memory.
			 * In fact, it can be better as the displacement
			 * is likely to be in the prefetch queue. On a
			 * better processor, it's better to fetch the byte
			 * displacement from the prefetch queue (there's no
			 * penalty for adding it in) than to fetch a
			 * misaligned word. Thus, in general, it's good to
			 * up the thing to a byte-displacement of 1.
			 */
			res1.data.ea.modrm &= ~MR_DISP_MASK;
			res1.data.ea.modrm |= MR_BYTE_DISP;
			res1.data.ea.disp = 1;
			break;
		    case MR_BYTE_DISP:
			if (res1.data.ea.disp == 127) {
			    /*
			     * Need to up the displacement size to a word
			     * as 128 can't fit in a signed byte.
			     */
			    res1.data.ea.modrm &= ~MR_DISP_MASK;
			    res1.data.ea.modrm |= MR_WORD_DISP;
			}
			/*FALLTHRU*/
		    case MR_WORD_DISP:
			res1.data.ea.disp += 1;
			break;
		}
		/*
		 * Shift high byte into position for the operation.
		 */
		res2.data.number >>= 8;
		/*
		 * Note that we're dealing with a byte...
		 */
		notByte = 0;
	    }
	}
    }

    return(CodeArithCommon(addrPtr, pass, prevSize,
			   expr1, &res1, expr2, &res2, delay, op,
			   notByte, isDWord, Code_BitNF));
}

/***********************************************************************
 *				Code_Bound
 ***********************************************************************
 * SYNOPSIS:	    Generate BOUND instruction
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *	Allowed only for 186 and above.
 *	Usage is BOUND rw, md and generates 62 /r
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Bound(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[5];    	/* 1 override, 1 opcode, 1 modrm, 2 disp */
    byte    	*ip = ibuf;
    ExprResult	res1, res2;
    FixResult	result;
    int	    	fixAddr;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ASSERT_186();

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 Code_Bound, 5, data, &delay);

    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure neither operand is a constant -- we don't do constants here
     */
    result = CodeNoConstant(expr1, &res1, expr2, &res2, expr1->file, expr1->line,
			    (OpCode *)data);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure neither operand is a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1) || EXPR_IS_SEGREG(&res2)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "BOUND can't operate on a segment register");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    /*
     * Make sure the destination is a word register.
     */
    if (((res1.data.ea.modrm & MR_DISP_MASK) != MR_REG) ||
	(Type_Size(res1.type) != 2))
    {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "first operand for BOUND must be a word register");
	result = FR_ERROR;
    }

    /*
     * Can't really ensure the source is a double-word, since it's likely
     * to have been declared with two DWs, but we can make sure it resides
     * in memory...
     */
    if ((res2.data.ea.modrm & MR_DISP_MASK) == MR_REG) {
	Notify(NOTIFY_ERROR, expr2->file, expr2->line,
	       "second operand for BOUND must reside in memory");
	result = FR_ERROR;
    }

    if (result == FR_DONE) {
	/*
	 * Store override if needed
	 */
	fixAddr = (*addrPtr) + 2;
	if (EXPR_NEEDS_OVERRIDE(&res2)) {
	    *ip++ = res2.data.ea.override;
	    fixAddr++;
	}

	/*
	 * Store opcode (constant)
	 */
	*ip++ = 0x62;

	/*
	 * Store away the source ea merged with the dest reg.
	 */
	ip = CodeStoreEA(ip,
			 res2.data.ea.modrm,
			 (byte)(res1.data.ea.modrm << MR_REG_SHIFT),
			 res2.data.ea.dword_ea,
			 res2.data.ea.sib,
			 res2.data.ea.disp,
			 prevSize,
			 ip-ibuf,
			 pass, &fixAddr);

	/*
	 * Install the instruction itself.
	 */
	startAddr = *addrPtr;
	CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res2, fixAddr,
		  expr2->file, expr2->line, delay);
	if (delay) {
	    if (pass > 1) {
		CodeCleanup(expr1, &res1, expr2, &res2);
		return(FR_FINAL);
	    } else {
		Fix_Register(FC_FINAL, Code_Bound,
			     startAddr, ip - ibuf, expr1, expr2, data);
	    }
	}
    }
    /*
     * Return whatever result we've calculated
     */
    CodeCleanup(expr1, &res1, expr2, &res2);
    return(result);
}


/***********************************************************************
 *				Code_Call
 ***********************************************************************
 * SYNOPSIS:	    Handle a CALL of some sort
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_UNDEF or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Call(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[5];	/* FAR call is five bytes */
    byte    	*ip = ibuf;
    ExprResult	res1;
    FixResult	result;
    int	    	fixAddr;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_Call, 3, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line,
			    (OpCode *)data);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make operand is not a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "CALL can't operate on a segment register");
	CodeCleanup(expr1, &res1, NULL, NULL);
	return(FR_ERROR);
    }

    if ((res1.data.ea.modrm == MR_DIRECT) &&
	((res1.type == Type_Near()) || (res1.type == Type_Far())))
    {
	/*
	 * Direct call. Destination of call is res1.rel.sym with optional
	 * displacement...
	 */
	SymbolPtr   dest = res1.rel.sym;

	if ((dest != NULL) && (dest->type == SYM_PROC) &&
	    (dest->u.proc.flags & SYM_NO_CALL))
	{
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "procedure %i may not be called directly",
		   dest->name);
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}

	if (dest == NULL) {
	    /*
	     * Handle a call to an absolute routine (which must be FAR,
	     * since we can't make the call PC-relative if it's to an
	     * absolute address).
	     */
	    if (res1.type == Type_Far()) {
		*ip++ = 0x9a;
		*ip++ = (byte)res1.data.ea.disp;
		*ip++ = (byte)(res1.data.ea.disp >> 8);
		*ip++ = 0;
		*ip++ = 0;
		/*
		 * Modify the FixDesc for the result to be a segment-only
		 * fixup for the frame relative to which the call is being
		 * made...
		 */
		fixAddr = (*addrPtr) + 3;
		res1.rel.size = FIX_SIZE_WORD;
		res1.rel.type = FIX_SEGMENT;
		res1.rel.sym = res1.rel.frame;
		res1.rel.pcrel = 0;
	    } else {
		/*
		 * Absolute near calls are verboten
		 */
		Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "near call to absolute routine not allowed");
		CodeCleanup(expr1, &res1, NULL, NULL);
		return(FR_ERROR);
	    }
	} else if (res1.type == Type_Far()) {
	    /*
	     * Call to a far routine -- see if it's in the same segment
	     * as the call itself. If so, we can perform a
	     *  	PUSH CS; CALL NEAR PTR routine
	     * sort of thing.
	     * Note we have to be careful not to be confused between a
	     * segment that's part of a group and one that's not, the problem
	     * being that the segment for a segment that's not in a group
	     * is simply the global segment into which global, undefined
	     * procedures tend to be put.
	     *
	     * 11/2/93: added check for CAST operator in expr1, allowing a call
	     * to be *forced* to be far by having
	     *	    call    {far}FileEnum
	     * for example. -- ardeb
	     */
	    if (((dest->segment == curSeg) ||
		 ((res1.rel.frame == curSeg->segment) &&
		  (res1.rel.frame != global))) &&
		!Expr_InvolvesOp(expr1, EXPR_CAST))
	    {
		/*
		 * In same segment or group (that's the rel.frame
		 * comparison...), so we can do the CallFN optimization
		 */
		Notify(NOTIFY_DEBUG, expr1->file, expr1->line,
			"Generating CallFN to %i\n", dest->name);
		*ip++ = 0x0e;   /* PUSH CS */
		*ip++ = 0xe8;   /* CALL NEAR PTR */
		*ip++ = (byte)res1.data.ea.disp;
		*ip++ = (byte)(res1.data.ea.disp >> 8);
		res1.rel.pcrel = 1;
		fixAddr = (*addrPtr) + 2;
	    } else {
		if ((res1.rel.frame == global) && warn_unknown) {
		    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
			    "segment for %i not known", dest->name);
		}
		*ip++ = 0x9a;   /* CALL FAR PTR */
		/* Displacement */
		*ip++ = (byte)res1.data.ea.disp;
		*ip++ = (byte)(res1.data.ea.disp >> 8);
		/* Store 0 for segment (just takes up
		 * room */
		*ip++ = 0;
		*ip++ = 0;

		/*
		 * Up the size of the item being fixed by the linker and
		 * set fixAddr to reflect its start...
		 * Mark the fixup as being for a CALL so the linker knows
		 * what to do.
		 */
		fixAddr = (*addrPtr) + 1;
		res1.rel.type = FIX_CALL;
		res1.rel.size = FIX_SIZE_DWORD;
	    }
	} else {
	    /*
	     * Near call...
	     */
	    *ip++ = 0xe8;	/* CALL NEAR PTR */
	    *ip++ = (byte)res1.data.ea.disp;
	    *ip++ = (byte)(res1.data.ea.disp >> 8);
	    res1.rel.pcrel = 1;
	    fixAddr = (*addrPtr) + 1;
	    /*
	     * Make sure the routine being called is in the same segment.
	     * Note we allow the thing to be "in" the global segment -- the
	     * linker will complain about any segment mismatch.
	     */
	    if (!((dest->segment == curSeg) ||
		  (res1.rel.frame == curSeg->segment) ||
		  (res1.rel.frame == global)))
	    {
		Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "near call from segment %i to segment %i",
		       curSeg->name, res1.rel.frame->name);
		CodeCleanup(expr1, &res1, NULL, NULL);
		return(FR_ERROR);
	    }
	}
    } else {
	/*
	 * Indirect call...near indirect is  ff /2, while far is  ff /3
	 */
	byte	reg;
	int 	size;

	/*
	 * Typeless arg is assumed to be a NEAR vector.
	 */
	if (res1.type == NULL) {
	    res1.type = Type_Int(2);
	}

	CodeSimplifyType(&res1.type, expr1->file, expr1->line, FALSE);

	size = Type_Size(res1.type);

	switch(size) {
	    case 2: reg = 2; break;
	    case 4: reg = 3; break;
	    default:
		Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "illegal size (%d) for indirect call vector", size);
		CodeCleanup(expr1, &res1, NULL, NULL);
		return(FR_ERROR);
	}

	/*
	 * Shift /n into position
	 */
	reg <<= MR_REG_SHIFT;

	fixAddr = (*addrPtr) + 2;
	if (EXPR_NEEDS_OVERRIDE(&res1)) {
	    *ip++ = res1.data.ea.override;
	    fixAddr += 1;
	}
	*ip++ = 0xff;
	ip = CodeStoreEA(ip, res1.data.ea.modrm, reg, res1.data.ea.dword_ea,
			 res1.data.ea.sib, res1.data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);
    }

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Call,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }


    CodeCleanup(expr1, &res1, NULL, NULL);
    return(result);
}


/***********************************************************************
 *				Code_CallStatic
 ***********************************************************************
 * SYNOPSIS:	    Handle a static method call
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_UNDEF or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_CallStatic(int 	*addrPtr,   /* IN/OUT: Address of instruction start */
		int   	prevSize,   /* # bytes previously allocated to inst */
		int   	pass,	    /* Current pass */
		Expr  	*expr1,	    /* Operand 1 */
		Expr  	*expr2,	    /* Operand 2 */
		Opaque	data)	    /* OpCode/other data */
{
    byte    	ibuf[5];	/* FAR call is five bytes */
    byte    	*ip = ibuf;
    ExprResult	res1, res2;
    FixResult	result;
    int	    	delay;
    ID	    	method;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 Code_CallStatic, 5, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    if ((expr1->numElts != 2) || (expr1->elts[0].op != EXPR_SYMOP) ||
	(expr1->elts[1].sym->type != SYM_METHOD))
    {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "first operand for static method call must be a method");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    /*
     * Make sure the second operand refers to a class. We don't just
     * check there's a class symbol involved as that would void the use
     * of the SUPER operator, which wouldn't be good.
     */
    if (!res2.rel.sym || res2.rel.sym->type != SYM_CLASS) {
	Notify(NOTIFY_ERROR, expr2->file, expr2->line,
	       "second operand for static method call must be a class");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    /*
     * A static method call is transmitted to the linker by having the
     * external fixup refer to a class symbol. The name of the method involved
     * is then stored in the four bytes following the opcode (in PC byte
     * order for want of anything else).
     */
    method = ST_Dup(output, expr1->elts[1].sym->name, output, permStrings);

    *ip++ = 0x9a;
    *ip++ = (byte)method; method >>= 8;
    *ip++ = (byte)method; method >>= 8;
    *ip++ = (byte)method; method >>= 8;
    *ip++ = (byte)method;

    /*
     * Adjust the relocation type to be a dword-sized static call, dealing
     * with the difference between call to the superclass and to the object's
     * class.
     */
    if (!Expr_InvolvesOp(expr2, EXPR_SUPER)) {
	res2.rel.type = FIX_METHCALL;
    } else {
	res2.rel.type = FIX_SUPERCALL;
    }
    res2.rel.size = FIX_SIZE_DWORD;

    /*
     * Handle various bookkeeping tasks and store the instruction away.
     */
    CodeFinal(addrPtr, pass, 5, prevSize, ibuf, &res2, (*addrPtr)+1,
	      expr1->file, expr1->line, delay);
    CodeCleanup(expr1, &res1, expr2, &res2);
    return(FR_DONE);
}


/***********************************************************************
 *				Code_NoArgPriv
 ***********************************************************************
 * SYNOPSIS:	    Handle a CLTS instruction
 * CALLED BY:	    yyparse
 * RETURN:	    FR_DONE
 * SIDE EFFECTS:    Code is entered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_NoArgPriv(int  *addrPtr,	/* IN/OUT: Address of instruction start */
	       int  prevSize,  	/* # bytes previously allocated to inst */
	       int  pass,    	/* Current pass */
	       Expr *expr1,    	/* Operand 1 */
	       Expr *expr2,    	/* Operand 2 */
	       Opaque data)    	/* OpCode/other data */
{
    byte    ibuf[2];
    byte    *ip = ibuf;
    OpCode  *op = (OpCode *)data;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ASSERT_PROT();

    /*
     * Store first byte and second byte, if non-zero
     */
    *ip++ = (byte)(op->value);
    if ((*ip = (byte)(op->value >> 8)) != 0) {
	ip++;
    }

    Table_Store(curSeg->u.segment.code, ip-ibuf, (void *)ibuf, *addrPtr);

    *addrPtr += ip-ibuf;

    return(FR_DONE);
}



/***********************************************************************
 *				Code_NoArgIO
 ***********************************************************************
 * SYNOPSIS:	    Handle a HLT, STI, or CLI instruction
 * CALLED BY:	    yyparse
 * RETURN:	    FR_DONE
 * SIDE EFFECTS:    Code is entered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_NoArgIO(int  *addrPtr,	/* IN/OUT: Address of instruction start */
	     int  prevSize,  	/* # bytes previously allocated to inst */
	     int  pass,    	/* Current pass */
	     Expr *expr1,    	/* Operand 1 */
	     Expr *expr2,    	/* Operand 2 */
	     Opaque data)    	/* OpCode/other data */
{
    byte    ibuf[2];
    byte    *ip = ibuf;
    OpCode  *op = (OpCode *)data;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ASSERT_IO();

    /*
     * Store first byte and second byte, if non-zero
     */
    *ip++ = (byte)(op->value);
    if ((*ip = (byte)(op->value >> 8)) != 0) {
	ip++;
    }

    Table_Store(curSeg->u.segment.code, ip-ibuf, (void *)ibuf, *addrPtr);

    *addrPtr += ip-ibuf;

    return(FR_DONE);
}


/***********************************************************************
 *		       Code_DPShiftLeft, CodeDPShiftRight
 ***********************************************************************
 * SYNOPSIS:	    Handle SHLD, SHRD (respectively)
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 *
 * STRATEGY:	    Since we can't pass both the opcode information and
 *		    a third operand, we expose separate routines for
 *		    each opcode, pass the third operand in the Opaque
 *		    data parameter, and call a common routine to handle
 *		    both instructions.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	7/11/2000	Initial Revision
 *
 ***********************************************************************/
FixResult
Code_DPShift(int *addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data,	    	/* Operand 3 (long) */
      byte	opcode,		/* Opcode value */
      FixProc	*proc)		/* Calling procedure */
{
    byte    	ibuf[12];    	/* override + prefixes + 2 opcode + modrm
				 * + sib + 4 disp + db */
    byte    	*ip = ibuf;
    int	    	opSize;
    int		isDWord;	/* 1 if opSize is 4, 0 if not */
    ExprResult	res1, res2;
    FixResult	result;
    long	count = (long)data;
    int	    	fixAddr = -1;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ASSERT_386();

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 proc, 2, data, &delay);
    if (result != FR_DONE)
	return(result);

    /*
     * No undefined symbols means the types of the operands are known, so
     * we can type-check.
     */
    if (!CodeCompatible(expr1, &res1, expr2, &res2,
			FALSE, FALSE, delay, &opSize))
    {
	return(FR_ERROR);
    }
    isDWord = (opSize == 4) ? 1 : 0;

    if (RES_IS_CONST(res1.type) || RES_IS_CONST(res2.type)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "can't shift a constant");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    /*
     * Make sure none of the operands are a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1) || EXPR_IS_SEGREG(&res2)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "can't operate on a segment register");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    if (RES_IS_CONST(res2.type)
	|| ((res2.data.ea.modrm & MR_DISP_MASK) != MR_REG))
    {
	Notify(NOTIFY_ERROR, expr2->file, expr2->line,
	       "second parameter must be register");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    if (count == -1) {
	/*
	 * SHLD-by-CL encoded as 0F A5, not 0F A4.
	 * SHRD-by-CL encoded as 0F AD, not 0F AC.
	 */
	opcode += 0x0001;
    }

    fixAddr = (*addrPtr) + 3;
    if (EXPR_NEEDS_OVERRIDE(&res1)) {
	*ip++ = res1.data.ea.override;
	fixAddr += 1;
    }
    if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res1)) {
	*ip++ = PRE_ADDRESS;
	fixAddr++;
    }
    if (USE_386() && EXPR_NEEDS_PRE_OPERAND(&res1)) {
	*ip++ = PRE_OPERAND;
	fixAddr++;
    }

    CodeSimplifyType(&res1.type, expr1->file, expr1->line, TRUE);

    *ip++ = 0x0f;
    *ip++ = opcode;
    ip = CodeStoreEA(ip,
		     res1.data.ea.modrm,
		     (byte)((res2.data.ea.modrm & MR_RM_MASK) << MR_REG_SHIFT),
		     res1.data.ea.dword_ea,
		     res1.data.ea.sib,
		     res1.data.ea.disp,
		     prevSize, (ip-ibuf) + (((opcode & 0x0001)==0) ? 1 : 0),
		     pass, &fixAddr);
    /*
     * If shift-by-constant, store constant...
     */
    if ((opcode & 0x0001) == 0) {
	*ip++ = (byte)count;
    }

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, proc,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }

    CodeCleanup(expr1, &res1, expr2, &res2);
    return(FR_DONE);
}

FixResult
Code_DPShiftLeft(int *addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* Operand 3 (long) */
{
    return Code_DPShift(addrPtr, prevSize, pass, expr1, expr2, data,
			0xa4, Code_DPShiftLeft);
}

FixResult
Code_DPShiftRight(int *addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* Operand 3 (long) */
{
    return Code_DPShift(addrPtr, prevSize, pass, expr1, expr2, data,
			0xac, Code_DPShiftRight);
}


/***********************************************************************
 *				Code_EnterLeave
 ***********************************************************************
 * SYNOPSIS:	    Handle an ENTER or LEAVE instruction
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_EnterLeave(int 	*addrPtr,   /* IN/OUT: Address of instruction start */
		int   	prevSize,   /* # bytes previously allocated to inst */
		int   	pass,	    /* Current pass */
		Expr  	*expr1,	    /* Operand 1 */
		Expr  	*expr2,	    /* Operand 2 */
		Opaque	data)	    /* OpCode/other data */
{
    byte    	ibuf[4];
    byte    	*ip;
    ExprResult	res1, res2;
    FixResult	result;
    OpCode  	*op = (OpCode *)data;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ASSERT_186();

    ip = ibuf;

    if (op->value == 0xc8) {
	/*
	 * ENTER -- takes two args
	 */
	/*
	 * Handle initial evaluation and registration of FC_UNDEF fixup as
	 * required.
	 */
	result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			     Code_EnterLeave, 4, data, &delay);
	if (result != FR_DONE) {
	    return(result);
	}

	if (res1.type != EXPR_TYPE_CONST) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "first operand for ENTER must be numeric constant");
	    result = FR_ERROR;
	}

	if (res2.type != EXPR_TYPE_CONST) {
	    Notify(NOTIFY_ERROR, expr2->file, expr2->line,
		   "second operand for ENTER must be numeric constant");
	    result = FR_ERROR;
	}

	/*
	 * Make sure the second operand will fit in a byte
	 */
	if ((result == FR_DONE) && ((unsigned long)res2.data.number > 255)) {
	    Notify(NOTIFY_ERROR, expr2->file, expr2->line,
		   "second operand for ENTER must fit in a byte");
	    result = FR_ERROR;
	}

	if (result != FR_DONE) {
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(result);
	}

	/*
	 * ENTER is encoded  c8 dw db
	 */
	*ip++ = 0xc8;
	*ip++ = (byte)res1.data.number;
	*ip++ = (byte)(res1.data.number >> 8);
	*ip++ = (byte)res2.data.number;
	CodeCleanup(expr1, &res1, expr2, &res2);
    } else {
	/*
	 * LEAVE
	 */
	*ip++ = 0xc9;
	delay = 0;
    }

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res2, -1,
	      expr1 ? expr1->file : NullID,
	      expr1 ? expr1->line : 0, delay);

    if (delay) {
	if (pass > 1) {
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_EnterLeave,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }
    return(FR_DONE);
}

#define ADD_FWAIT_FOR_8087(fixAddr, ip) if ((procType) & PROC_8087) { \
    *(ip)++ = 0x9b; fixAddr += 1; \
}

/*********************************************************************
 *			Code_Fbiop
 *********************************************************************
 * SYNOPSIS:	    Handles coprocessor binary operator instructions
 * CALLED BY:	    yyparse, FixUp module
 * RETURN:  	    FR_DONE , FR_ERROR , FR_UNDEF
 * SIDE EFFECTS:    enters code
 * STRATEGY:
 *	    	if (numops == 0) then
 *	    	    ST(i) = ST OP ST(i)
 *	    	    FPOP
 *	    	else
 *	    	    if (numops == 1) then
 *	    	    	if	(op is real) then
 *	    	    	    ST = ST + real op
 *	    	    	else
 *	    	    	    ST(i) = ST(i) + ST
 *	    	    	if (pop routine) then fpop
 *	    	    else
 *	    	    	dest = dest + src
 *	    	    	if (pop routine) then fpop
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	4/12/92		Initial version
 *
 *********************************************************************/
FixResult
Code_Fbiop(int	    *addrPtr, 	/* address of instruction start  */
	   int	    prevSize, 	/*# bytes perviously allocated to inst */
	   int	    pass,     	/* current pass */
	   Expr    *expr1,   	/* Operand 1 */
	   Expr    *expr2,   	/* Operand 2 */
	   Opaque   data)   	/* OpCode/other data */
{
    byte    ibuf[5];
    byte    	*ip;
    ExprResult	res1, res2, *res;
    FixResult	result;
    OpCode  	*op = (OpCode *)data;
    int	    	delay=0, startAddr, fixAddr, typesize;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ip = ibuf;
    fixAddr = *(addrPtr)+2;

    ADD_FWAIT_FOR_8087(fixAddr, ip);
    /* check for no arguments */
    if (expr1 == NULL && expr2 == NULL)
    {
	/* if no arguments, just put in the opcode and split */
	*ip++ = 0xde;
	*ip++ = 0xc1 | (byte)op->value;/* get opcode */
	res = (ExprResult *)NULL;    /* indicates zero operands */
    }
    else
    {
	res = &res1; /* indicates > 0 operands */

	/* check for one operand case */
	if (expr2 == NULL && expr1 != NULL)
    	{
    	    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
		    		 Code_Fbiop, 5, data, &delay);
	    if (result != FR_DONE) {
		   return result;
	    }

	    /* we have one operand, it could be a memory location or
	       a floating point stack element */

	    if (res1.type != EXPR_TYPE_FLOATSTACK)
	    {
	    /* if expr1 is not a stack element it must be a memory
	       location conataining a real32 or real64 float number
	       if the type is 0 (= undefined), use float32 size (4) as
	       default */

		if (EXPR_NEEDS_OVERRIDE(&res1)) {
	    	    *ip++ = res1.data.ea.override;
	    	    fixAddr += 1;
    	    	}

		if (res1.type == 0) {
		    typesize = 4;
		    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
	       	    	"%s : using default operand size, 4 bytes", op->name);
		}
	    	else {
		    typesize = Type_Size(res1.type);
		}

		/* typesize must be either 4 (float32) or 8(float64) bytes*/
		switch (typesize)
		{
		    case 4:
			*ip = 0xd8;
			break;
		    case 8:
			*ip = 0xdc;
			break;
		    default:
			Notify(NOTIFY_ERROR, expr1->file, expr1->line,
			       "%s : invalid operand size", op->name);
			CodeCleanup(expr1, &res1, NULL, NULL);
			return(FR_ERROR);
		}

    	    	ip = CodeStoreEA(ip+1,
		    	         res1.data.ea.modrm,
		     	    	 (byte)((op->value & 0xff) >> 3),
				 res1.data.ea.dword_ea,
				 res1.data.ea.sib,
		     	    	 res1.data.ea.disp,
		     	    	 prevSize,
		     	    	 ip-ibuf,
		     	    	 pass, &fixAddr);

	    }
	    else /* 1 stack operand */
	    {
		/* stack registers must be 0 <= ST <= MAX_FLOATSTACK_ELEMENT */
	    	if ((unsigned long)res1.data.number > MAX_FLOATSTACK_ELEMENT)
	    	{
	    	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
			   "%s : register must be from 0 to 7", op->name);
		    CodeCleanup(expr1, &res1, NULL, NULL);
	    	    return(FR_ERROR);
	    	}

		/* most of the binary operations have two versions,
		   (i.e. fadd/faddp, fmul/fmulp)
		   here we test to see which one we are dealing with */

	    	if (op->value & 0xff00) /* if true, doing a 'p' operation */{
		    *ip++ = 0xde;
		}
	    	else {	    	/* else just a normal one */
		    *ip++ = 0xdc;
		}

		/* both types are the same for the second byte */
            	*ip++ = 0xc0 | (byte)op->value | (byte)res1.data.number;
	    }
	}
    	else /* we have two operands */
    	{
    	    result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
		    		 Code_Fbiop, 5, data, &delay);
	    if (result != FR_DONE) {
		   return result;
	    }

	    /* since we have two operands they must both be stack registers
	       AND one or the other must be st or st(0) */

	    if (res1.type != EXPR_TYPE_FLOATSTACK ||
		res2.type != EXPR_TYPE_FLOATSTACK) {
	    	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       	"%s : invalid operand", op->name);

		CodeCleanup(expr1, &res1, expr2, &res2);
		return(FR_ERROR);
	    }

	    if (((unsigned long)res1.data.number > MAX_FLOATSTACK_ELEMENT) ||
		((unsigned long)res2.data.number > MAX_FLOATSTACK_ELEMENT) ) {
	    	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "%s : register must be from 0 to 7", op->name);

		CodeCleanup(expr1, &res1, expr2, &res2);
		return(FR_ERROR);
	    }


	    if (((unsigned long)res1.data.number != 0) &&
    	    	((unsigned long)res2.data.number != 0) ) {
		Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "%s : one register must be top of stack", op->name);

		CodeCleanup(expr1, &res1, expr2, &res2);
		return (FR_ERROR);
	    }

	    /* there are two cases when we have two operands, they are

	       1) BIOP	st, st(i)
	       2) BIOP	st(i), st

	       here we see which one we are dealing with */

	    if ((unsigned long)res1.data.number == 0)
	    {
		/* st, st(i) case */
		*ip++ = 0xd8;
		*ip++ = 0xc0 | (byte)op->value | (byte)res2.data.number;
	    }
	    else {
		/* st(i), st case, now we must see if we have the 'p'
		   version or the normal one */
	    	if (op->value & 0xff00)
		{
		    /* do 'p' version */
	      	    *ip++ = 0xde;
		    *ip++ = 0xc0 | (byte)op->value | (byte)res1.data.number;
		}
		else /* do BIOP */
		{
		    *ip++ = 0xdc;
		    *ip++ = 0xc0 | (byte)op->value | (byte)res1.data.number;
		}
	    } /* end of st(i), st case */
	} /* end of two operand case */
    } /* end of > 0 operand case */

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;

    /* if we have no operands send call routine with NULLs */
    if (res == NULL) /* no operands */{
    	CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, res,
		    -1, NullID, 0, delay);
    }
    /* otherwise send in the pointers to expr1 */
    else {
    	CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, res, fixAddr,
	      expr1->file, expr1->line, delay);
    }

    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Fbiop,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }
    CodeCleanup(expr1, &res1, expr2, &res2);

    return FR_DONE;
}

/*********************************************************************
 *			Code_Fcom
 *********************************************************************
 * SYNOPSIS:	    Handles FCOM, FCOMP instructions (FCOMPP handled in
 *	    	    Code_Fzop)
 * CALLED BY:	    yyparse, FixUp module
 * RETURN:  	    FR_DONE or FR_ERROR
 * SIDE EFFECTS:    enters code
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	4/12/92		Initial version
 *
 *********************************************************************/
FixResult
Code_Fcom(int	    *addrPtr,	/* address of instruction start */
	  int	    prevSize,   /* # bytes previously allocated */
	  int	    pass,   	/* cuurent pass */
	  Expr    *expr1,   	/* Operand 1 */
	  Expr    *expr2,   	/* Operand 2 */
	  Opaque   data)   	/* OpCode/ other data */
{
    byte    ibuf[5]; /* WAIT, opcode, modrm, 2 disp */
    byte    	*ip = ibuf;
    ExprResult	res1, *res;
    FixResult	result;
    int	    	fixAddr;
    OpCode  	*op = (OpCode *)data;
    int	    	delay=0, startAddr, typesize;
    byte    	regValue;



    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    fixAddr = *(addrPtr)+2;

    ADD_FWAIT_FOR_8087(fixAddr, ip);

    /* regValue contains register info for modrm byte */
    regValue = (byte)((op->value & 0xf000) >> 12);
    if (expr1 == NULL)	/* if no operands, just stick in the opcode */
    {
	*ip = (byte)((op->value & 0x0f00) >> 8);
	*ip++ |= 0xd0;
	*ip++ = (byte)(op->value);
	res = NULL;
    }
    else
    {
	res = &res1;
	result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
		    	     Code_Fcom, 5, data, &delay);
    	if (result != FR_DONE) {
	    return(result);
    	}
	/* now see if its a stack element or a memory operand */
	if (res1.type == EXPR_TYPE_FLOATSTACK)
	{   /* its a stack element */

	    if ((unsigned long)res1.data.number > MAX_FLOATSTACK_ELEMENT){
	    	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "%s : register must be from 0 to 7", op->name);
		CodeCleanup(expr1, &res1, NULL, NULL);
		return(FR_ERROR);
	    }

	    *ip = (byte)((op->value & 0x0f00) >> 8); /* get opcode part */
	    *ip++ |= 0xd0;
	    *ip++ = (byte)(op->value & 0xf8) | (byte)res1.data.number;
	}
	else /* do real operand */
	{
	    /* if the type is 0 (= undefined), use float32 size (4) as
	       default */
	    if (EXPR_NEEDS_OVERRIDE(&res1)) {
	        *ip++ = res1.data.ea.override;
	        fixAddr += 1;
    	    }

	    if (res1.type == 0) {
		typesize = 4;
		Notify(NOTIFY_WARNING, expr1->file, expr1->line,
	       	    	"%s : using default operand size, 4 bytes", op->name);
	    }
	    else {
	        typesize = Type_Size(res1.type);
	    }

	    switch (typesize)
	    {
		    case 4:
			*ip = 0xd8;
			break;
		    case 8:
			*ip = 0xdc;
			break;
		    default:
			Notify(NOTIFY_ERROR, expr1->file, expr1->line,
			       "%s : invalid operand", op->name);
			CodeCleanup(expr1, &res1, NULL, NULL);
			return(FR_ERROR);
	     }

    	     ip = CodeStoreEA(ip+1,
		              res1.data.ea.modrm,
			      (byte)((op->value & 0xff00) >> 11),
			      res1.data.ea.dword_ea,
			      res1.data.ea.sib,
		     	      res1.data.ea.disp,
		     	      prevSize,
		     	      ip-ibuf,
		     	      pass, &fixAddr);
	}
    }
    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    if (res == NULL) /* no operands */ {
    	CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, res,
		    -1, NullID, 0, delay);
    }
    else {
    	CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, res, fixAddr,
	      expr1->file, expr1->line, delay);
    }
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Fcom,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }

    CodeCleanup(expr1, &res1, NULL, NULL);
    return FR_DONE;
}

/*********************************************************************
 *			Code_Ffree
 *********************************************************************
 * SYNOPSIS: 	    Handles FFREE and FFREEP instructions
 * CALLED BY:	    yyparse
 * RETURN:  	    FR_DONE
 * SIDE EFFECTS:    code is entered
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	4/12/92		Initial version
 *
 *********************************************************************/
FixResult
Code_Ffree(int	    *addrPtr,	/* address of instruction start */
	   int	    prevSize,   /* # bytes previously allocated */
	   int	    pass,   	/* cuurent pass */
	   Expr    *expr1,   	/* Operand 1 */
	   Expr    *expr2,   	/* Operand 2 */
	   Opaque   data)   	/* OpCode/ other data */
{
    byte    ibuf[2]; /* WAIT, opcode, modrm, 2 disp */
    byte    *ip = ibuf;
    ExprResult	res1;
    FixResult	result;
    OpCode  	*op = (OpCode *)data;
    int	    	delay;
    int	    	junk = 0;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ADD_FWAIT_FOR_8087(junk, ip);

    	/* get info about expr1 and get ready for FxiUp if needed */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_Ffree, 5, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    if (res1.type != EXPR_TYPE_FLOATSTACK)
    {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "%s : illegal operand", op->name);
	CodeCleanup(expr1, &res1, NULL, NULL);
	return FR_ERROR;
    }

    if ((unsigned long)res1.data.number > MAX_FLOATSTACK_ELEMENT){
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       	"%s : register must be from 0 to 7", op->name);
	CodeCleanup(expr1, &res1, NULL, NULL);
	return(FR_ERROR);
    }
    *ip++ = (byte)(op->value >> 8);
    *ip++ = (byte)op->value | (byte)res1.data.number;

    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, NULL, -1, NullID, 0, 0);

    CodeCleanup(expr1, &res1, NULL, NULL);
    return FR_DONE;
}

/*********************************************************************
 *			Code_Fgroup0
 *********************************************************************
 * SYNOPSIS: 	    handle coprocessor instructions of noarguments that
 *	    	    have wait/no wait versions of same instruction
 * CALLED BY:	    yyparse
 * RETURN:  	    FR_DONE
 * SIDE EFFECTS:    code is entered
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	4/12/92		Initial version
 *
 *********************************************************************/
FixResult
Code_Fgroup0(int	    *addrPtr,	/* address of instruction start */
	     int	    prevSize,   /* # bytes previously allocated */
	     int	    pass,   	/* cuurent pass */
	     Expr    *expr1,   	/* Operand 1 */
	     Expr    *expr2,   	/* Operand 2 */
	     Opaque   data)   	/* OpCode/ other data */
{
    byte    	ibuf[3];
    byte    	*ip = ibuf;
    word    	regValue;
    OpCode  	*op = (OpCode *)data;


    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    if (op->value & 0xf000) {
	*ip++ = 0x9b;	/* WAIT */
    }
    regValue = op->value;
    regValue &= 0x0fff;    /* mask out top nibble, used to contain wait */
    regValue |= 0xd000;    /* top nibble alway d for coproccessor opcodes */
    if ((regValue == 0xfe0) && (procType & PROC_8087)) {
	yyerror("%s is only available for the 80287 or later",
		op->name);
	return(FR_ERROR);
    }

    *ip++ = (byte)((regValue & 0xff00) >> 8);
    *ip++ = (byte)(regValue & 0x00ff);
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, NULL, -1,
	      NullID, 0, 0);

    return  FR_DONE;
}

/*********************************************************************
 *			Code_Fgroup1
 *********************************************************************
 * SYNOPSIS:	    Handles coprocssor instructions of 1 operand
 * CALLED BY:	    yyparse
 * RETURN:  	    FR_DONE or FR_ERROR
 * SIDE EFFECTS:    code is entered
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	4/12/92		Initial version
 *
 *********************************************************************/
FixResult
Code_Fgroup1(int	    *addrPtr,	/* address of instruction start */
	   int	    prevSize,   /* # bytes previously allocated */
	   int	    pass,   	/* cuurent pass */
	   Expr    *expr1,   	/* Operand 1 */
	   Expr    *expr2,   	/* Operand 2 */
	   Opaque   data)   	/* OpCode/ other data */
{
    byte    ibuf[5]; /* WAIT, opcode, modrm, 2 disp */
    byte    	*ip = ibuf;
    ExprResult	res1;
    FixResult	result;
    int	    	fixAddr;
    OpCode  	*op = (OpCode *)data;
    int	    	delay, startAddr;
    byte    	regValue;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_Fgroup1, 5, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    /*	make sure not immediate operand */
    result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line, op);
    if (result != FR_DONE) {
	return result;
    }

    fixAddr = (*addrPtr)+2;

    if (op->value & 0xf000) {
	*ip++ = 0x9b;	/* insert wait */
	fixAddr += 1;
    }
    else
    {
	if (op->name[1] != 'n')
	{
	    ADD_FWAIT_FOR_8087(fixAddr, ip);
	}
    }

    regValue = (byte)((op->value & 0x0f00) >> 8);

    *ip = (byte)op->value;

    ip = CodeStoreEA(ip+1,
		     res1.data.ea.modrm,
		     (byte)(regValue << MR_REG_SHIFT),
		     res1.data.ea.dword_ea,
		     res1.data.ea.sib,
		     res1.data.ea.disp,
		     prevSize,
		     ip-ibuf,
		     pass, &fixAddr);

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Fgroup1,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }

    CodeCleanup(expr1, &res1, NULL, NULL);
    return(FR_DONE);
}


/*********************************************************************
 *			Code_Fint
 *********************************************************************
 * SYNOPSIS: 	    Handle most of coprocessor integer instrutions
 * CALLED BY:	    yyparse, FixUp module
 * RETURN:  	    FR_DONE or FR_ERROR or FR_UNDEF
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	4/13/92		Initial version
 *
 *********************************************************************/
FixResult
Code_Fint(int	    *addrPtr,	/* IN/OUT: Address of instruction start */
	  int     prevSize,  	/* # bytes previously allocated to inst */
	  int     pass,    	/* Current pass */
	  Expr    *expr1,   	/* Operand 1 */
	  Expr    *expr2,   	/* Operand 2 */
	  Opaque  data)    	/* OpCode/other data */
{
    byte    	ibuf[5], regValue;
    byte    	*ip = ibuf;
    ExprResult	res1;
    FixResult	result;
    int	    	fixAddr;
    OpCode  	*op = (OpCode *)data;
    int	    	delay, startAddr, typesize;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    fixAddr = (*addrPtr) + 2;

    ADD_FWAIT_FOR_8087(fixAddr, ip);
    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_Fint, 3, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }
    /* make sure operand is not a constant */
    result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line, op);
    if (result != FR_DONE) {
	return result;
    }

    if (res1.type == EXPR_TYPE_FLOATSTACK) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "%s : operand must be memory location", op->name);
	CodeCleanup(expr1, &res1, NULL, NULL);
	return FR_ERROR;
    }

    if (EXPR_NEEDS_OVERRIDE(&res1)) {
	    *ip++ = res1.data.ea.override;
	    fixAddr += 1;
    }

    if (res1.type == 0) {
	typesize = 2;
	Notify(NOTIFY_WARNING, expr1->file, expr1->line,
	       "%s : using default operand size, 2 bytes", op->name);

    }
    else {
        typesize = Type_Size(res1.type);
    }

    regValue = (byte)(op->value);

/**********************************************************
  there are special cases for the FST, FSTP and FLD instructions,
  I put them in here because all the code up to here, and the last piece
 of this routine is identical for all these instructions
**********************************************************/

    if (op->value & 0xf000) /* FILD instruction */
    {
	switch (typesize)
	{
	    case 2:
	    	    *ip = 0xdf;
		    regValue = 0x00;
		    break;
	    case 4:
		    *ip = 0xdb;
		    regValue = 0x00;
		    break;
	    case 8:
		    *ip = 0xdf;
		    regValue = 0x28;
		    break;
	   default:
		    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	            	    "%s : invalid operand size", op->name);
		    CodeCleanup(expr1, &res1, NULL, NULL);
	    	    return(FR_ERROR);
	}
    }
    else {
	if (op->value & 0x0200) /* FIST instruction */
	{
	    regValue = 0x10;
	    switch (typesize)
	    {
		case 2:
		    	*ip = 0xdf;
			break;
		case 4:
		    	*ip = 0xdb;
			break;
		default:
		    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	            	    "%s : invalid operand size", op->name);
		    CodeCleanup(expr1, &res1, NULL, NULL);
	    	    return(FR_ERROR);
	    }
	}
	else {
	    if (op->value & 0x0100) /* FISTP instruction */
	    {
		switch (typesize)
		{
		    case 2:
		    	    *ip = 0xdf;
			    regValue = 0x18;
			    break;
		    case 4:
		    	    *ip = 0xdb;
			    regValue = 0x18;
			    break;
		    case 8:
		    	    *ip = 0xdf;
			    regValue = 0x38;
			    break;
		    default:
		    	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	            	    "%s : invalid operand size", op->name);
			    CodeCleanup(expr1, &res1, NULL, NULL);
	    	    	    return(FR_ERROR);
		 }
	    }
	    else    	/* all the other instructions */
	    {
		switch (typesize)
    	    	{
	    	    case 2:
	            	    *ip = 0xde;
		    	    break;
            	    case 4:
	            	    *ip = 0xda;
		    	    break;
            	    default:
	    	    	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	            	"%s : invalid operand size", op->name);
			CodeCleanup(expr1, &res1, NULL, NULL);
	    	    	return(FR_ERROR);
		}
	    }
	}
    }
    ip = CodeStoreEA(ip+1,
		     res1.data.ea.modrm,
		     regValue,
		     res1.data.ea.dword_ea,
		     res1.data.ea.sib,
	    	     res1.data.ea.disp,
		     prevSize,
		     ip-ibuf,
		     pass, &fixAddr);


    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Fint,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }

    CodeCleanup(expr1, &res1, NULL, NULL);
    return(FR_DONE);
}

/*********************************************************************
 *			Code_Fldst
 *********************************************************************
 * SYNOPSIS: 	    Handle FLD, FST and FSTP instructions
 * CALLED BY:	    yyparse, FixUp module
 * RETURN:  	    FR_DONE, FR_ERROR, FR_UNDEF
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	4/13/92		Initial version
 *
 *********************************************************************/
FixResult
Code_Fldst(int	    *addrPtr,	/* IN/OUT: Address of instruction start */
	   int     prevSize,  	/* # bytes previously allocated to inst */
	   int     pass,    	/* Current pass */
	   Expr    *expr1,   	/* Operand 1 */
	   Expr    *expr2,   	/* Operand 2 */
	   Opaque  data)    	/* OpCode/other data */
{
    byte    	ibuf[5], regValue = 0;
    byte    	*ip = ibuf;
    ExprResult	res1;
    FixResult	result;
    int	    	fixAddr;
    OpCode  	*op = (OpCode *)data;
    int	    	delay, startAddr, typesize;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    fixAddr = (*addrPtr)+2;

    ADD_FWAIT_FOR_8087(fixAddr, ip);

    /* make sure operand is not a constant */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
	    		 Code_Fldst, 3, data, &delay);
    if (result != FR_DONE) {
     	    return(result);
    }
    result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line, op);
    if (result != FR_DONE) {
	return result;
    }

    if (res1.type == EXPR_TYPE_FLOATSTACK)
    {
	if ((unsigned long)res1.data.number > MAX_FLOATSTACK_ELEMENT){
	    	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       	"%s : register must be from 0 to 7", op->name);
		CodeCleanup(expr1, &res1, NULL, NULL);
		return(FR_ERROR);
    	}

	*ip++ = (byte)((op->value & 0xff00) >> 8);
	*ip++ = (byte)op->value | (byte)res1.data.number;
    }
    else {
	/*
     	* Handle initial evaluation and registration of FC_UNDEF fixup as
     	* required.
     	*/
	if (EXPR_NEEDS_OVERRIDE(&res1)) {
	    *ip++ = res1.data.ea.override;
	    fixAddr += 1;
    	}

	if (res1.type == 0) {
	    typesize = 4;
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
	       "%s : using default operand size, 4 bytes", op->name);

    	}
    	else {
            typesize = Type_Size(res1.type);
    	}

	switch (typesize)
	{
	    case 4:
	    case 8:
	    	    if (typesize == 4) {
	    	    	*ip = 0xd9;
		    }
		    else {
			*ip = 0xdd;
		    }
		    /* only three possibilites here */
		    switch ((byte)op->value)
		    {
			case 0xc0: /* FLD */
		    	    	    regValue =  0x00;
				    break;
		    	case 0xd0: /* FST */
				    regValue = 0x10;
				    break;
		        case 0xd8: /* FSTP */
				    regValue = 0x18;
		    }
		    break;
	    case 10:
		    *ip = 0xdb;
		    switch ((byte)op->value)
		    {
			case 0xc0: /* FLD */
			    	    regValue = 0x28;
				    break;
		        case 0xd8: /* FSTP */
				    regValue = 0x38;
				    break;
			case 0xd0: /* FST */
				Notify(NOTIFY_ERROR, expr1->file, expr1->line,
				       "%s cannot operate on tbyte operands",
				       op->name);
			    	CodeCleanup(expr1, &res1, NULL, NULL);
	    	    	    	 return(FR_ERROR);
		    }
		    break;
	    default:
		    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		     "%s : illegal operand size", op->name);
		    CodeCleanup(expr1, &res1, NULL, NULL);
		    return FR_ERROR;
       }
       ip = CodeStoreEA(ip+1,
	        	res1.data.ea.modrm,
		        regValue,
			res1.data.ea.dword_ea,
			res1.data.ea.sib,
	    	        res1.data.ea.disp,
		        prevSize,
		        ip-ibuf,
		        pass, &fixAddr);
    }

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);

    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Fldst,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }

    CodeCleanup(expr1, &res1, NULL, NULL);
    return FR_DONE;
}

/*********************************************************************
 *			Code_Fxch
 *********************************************************************
 * SYNOPSIS: 	    Handles FXCH
 * CALLED BY:	    yyparse
 * RETURN:  	    FR_DONE, FR_ERROR
 * SIDE EFFECTS:    enters code
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	4/13/92		Initial version
 *
 *********************************************************************/
FixResult
Code_Fxch(int	    *addrPtr,	/* IN/OUT: Address of instruction start */
	  int     prevSize,  	/* # bytes previously allocated to inst */
	  int     pass,    	/* Current pass */
	  Expr    *expr1,   	/* Operand 1 */
	  Expr    *expr2,   	/* Operand 2 */
	  Opaque  data)    	/* OpCode/other data */
{
    byte    	ibuf[5];
    byte    	*ip = ibuf;
    ExprResult	res1, *res;
    FixResult	result;
    int	    	fixAddr;
    OpCode  	*op = (OpCode *)data;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    fixAddr = (*addrPtr) + 2;
    ADD_FWAIT_FOR_8087(fixAddr, ip);

    if (expr1 == NULL)
    {
	*ip++ = (byte)((op->value & 0xff00) >> 8);
	*ip++ = (byte)(op->value);
	res = NULL;
    }
    else
    {
	res = &res1;
    	result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
	    		 Code_Fxch, 3, data, &delay);
   	if (result != FR_DONE) {
     	    return(result);
    	}

	if (res1.type != EXPR_TYPE_FLOATSTACK)
    	{
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	           "%s can't operate on a segment register", op->name);
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}

	if ((unsigned long)res1.data.number > MAX_FLOATSTACK_ELEMENT){
	    	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       	"%s : register must be from 0 to 7", op->name);
		CodeCleanup(expr1, &res1, NULL, NULL);
		return(FR_ERROR);
    	}
	*ip++ = (byte)((op->value & 0xff00) >> 8);
	*ip++ = ((byte)(op->value) & 0xf8) | (byte)res1.data.number;
	CodeCleanup(expr1, &res1, NULL, NULL);
    }

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    if (res == NULL) /* no operands */ {
    	CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, res,
		    -1, NullID, 0, delay);
    }
    else {
    	CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, res, fixAddr,
	      expr1->file, expr1->line, delay);
    }

    return FR_DONE;
}

/*********************************************************************
 *			Code_Fzop
 *********************************************************************
 * SYNOPSIS:	    Handles coprocessor instructions of zero operands
 * CALLED BY:	    yyparse
 * RETURN:  	    FR_DONE
 * SIDE EFFECTS:    code is entered
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	4/12/92		Initial version
 *
 *********************************************************************/
FixResult
Code_Fzop(int	    *addrPtr,	/* IN/OUT: Address of instruction start */
	    int     prevSize,  	/* # bytes previously allocated to inst */
	    int     pass,    	/* Current pass */
	    Expr    *expr1,   	/* Operand 1 */
	    Expr    *expr2,   	/* Operand 2 */
	    Opaque  data)    	/* OpCode/other data */
{
    byte    	ibuf[2];    	/* override, opcode, modrm, 2 disp */
    OpCode  	*op = (OpCode *)data;
    byte    	*ip = ibuf;
    int	    	junk=0;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ADD_FWAIT_FOR_8087(junk, ip);

    *ip++ = (byte)(op->value >> 8);
    *ip++ = (byte)(op->value);
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, NULL, -1,
	      NullID, 0, 0);

    return  FR_DONE;

}

/***********************************************************************
 *				Code_Group1
 ***********************************************************************
 * SYNOPSIS:	    Handle NOT, NEG, MUL, IMUL (1-operand), DIV and IDIV
 *	    	    instructions
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Group1(int	    *addrPtr,	/* IN/OUT: Address of instruction start */
	    int     prevSize,  	/* # bytes previously allocated to inst */
	    int     pass,    	/* Current pass */
	    Expr    *expr1,   	/* Operand 1 */
	    Expr    *expr2,   	/* Operand 2 */
	    Opaque  data)    	/* OpCode/other data */
{
    byte    	ibuf[10];    	/* override, prefixes, opcode, modrm, sib,
				 * 4 disp */
    byte    	*ip = ibuf;
    ExprResult	res1;
    FixResult	result;
    int	    	fixAddr;
    OpCode  	*op = (OpCode *)data;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_Group1, 3, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    if ((op->value == 0x18f6) ||	/* NEG */
	(op->value == 0x10f6))		/* NOT */
    {
	/*
	 * Count the operand as the destination for the NEG and NOT
	 * instructions.
	 */
	result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line,
				op);
    } else {
	/*
	 * Count operand as the source for all the other group 1 instructions
	 */
	result = CodeNoConstant(NULL, NULL, expr1, &res1, expr1->file, expr1->line,
				op);
    }

    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure neither operand is a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "%s can't operate on a segment register", op->name);
	CodeCleanup(expr1, &res1, NULL, NULL);
	return(FR_ERROR);
    }

    /*
     * If the instruction is DIV or IDIV, make sure the divisor isn't one
     * of the registers that make up the dividend.
     */
    if (((op->value == 0x30f6) || (op->value == 0x38f6)) &&
	((res1.data.ea.modrm & MR_DISP_MASK) == MR_REG))
    {
	switch(Type_Size(res1.type)) {
	    case 0:
	    case 1:
		switch (res1.data.ea.modrm & MR_RM_MASK) {
		    case REG_AL:
		    case REG_AH:
			Notify(NOTIFY_WARNING, expr1->file, expr1->line,
			       "dividing by register that's in the dividend");
			break;
		}
		break;
	    case 2:
		switch (res1.data.ea.modrm & MR_RM_MASK) {
		    case REG_AX:
		    case REG_DX:
			Notify(NOTIFY_WARNING, expr1->file, expr1->line,
			       "dividing by register that's in the dividend");
			break;
		}
		break;
	}
    }

    fixAddr = (*addrPtr)+2;

    /*
     * Store override and prefixes if required
     */
    if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res1)) {
	*ip++ = PRE_ADDRESS;
	fixAddr += 1;
    }
    if (USE_386() && EXPR_NEEDS_PRE_OPERAND(&res1)) {
	*ip++ = PRE_OPERAND;
	fixAddr += 1;
    }
    if (EXPR_NEEDS_OVERRIDE(&res1)) {
	*ip++ = res1.data.ea.override;
	fixAddr += 1;
    }

    /*
     * Install instruction (value for opcode contains base opcode and reg
     * field)
     */
    *ip = (byte)op->value;
    switch(Type_Size(res1.type)) {
	case 0:
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "defaulting operand size to byte");
	case 1:
	    break;
	default:
	    *ip += 1;
	    break;
    }
    ip = CodeStoreEA(ip+1,
		     res1.data.ea.modrm,
		     (byte)(op->value >> 8),
		     res1.data.ea.dword_ea,
		     res1.data.ea.sib,
		     res1.data.ea.disp,
		     prevSize,
		     ip-ibuf,
		     pass, &fixAddr);

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Group1,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }

    CodeCleanup(expr1, &res1, NULL, NULL);
    return(FR_DONE);
}


/***********************************************************************
 *				Code_Imul
 ***********************************************************************
 * SYNOPSIS:	    Handle a 186-level IMUL instruction (> 1 operand)
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_OPTIM or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Imul(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* 0 or Expr for operand 3 */
{
    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ASSERT_186();

    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	   "extended IMUL not supported (yet)");

    return(FR_ERROR);
}


/***********************************************************************
 *				Code_IO
 ***********************************************************************
 * SYNOPSIS:	    Handle IN and OUT instructions
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_IO(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[2];    	/* opcode, db */
    byte    	*ip = ibuf;
    ExprResult	res1, res2;
    ExprResult	*r1, *r2;
    FixResult	result;
    OpCode  	*op = (OpCode *)data;
    int	    	delay;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ASSERT_IO();

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 Code_IO, 2, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }
    /*
     * IN and OUT have the same operand constraints, they just use different
     * opcodes, so we pick one (IN) arbitrarily and swap operands for the
     * other...
     * When this is done, r1 should point to AL/AX and r2 should point to
     * DX or a byte immediate value.
     */
    if (op->value & 2) {
	/*
	 * OUT
	 */
	r1 = &res2;
	r2 = &res1;
    } else {
	/*
	 * IN
	 */
	r1 = &res1;
	r2 = &res2;
    }

    if (RES_IS_CONST(r1->type)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "should be AL or AX, not an immediate value");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    } else if (r1->data.ea.modrm != (MR_REG | REG_AX)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "can only perform I/O via AL or AX");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    } else if (RES_IS_CONST(r2->type)) {
	if (r2->type == EXPR_TYPE_STRING) {
	    Notify(NOTIFY_ERROR, expr2->file, expr2->line,
		   "cannot specify port number with a string constant");
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_ERROR);
	} else if ((unsigned long)r2->data.number > 255) {
	    Notify(NOTIFY_ERROR, expr2->file, expr2->line,
		   "immediate port number must be < 256");
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_ERROR);
	} else {
	    /*
	     * The opcode is in the value field of op, with 1 added if the
	     * operand size is a word. The port number follows immediately.
	     */
	    *ip++ = (byte)(op->value + (Type_Size(r1->type) == 2));
	    *ip++ = (byte)r2->data.number;
	}
    } else if (r2->data.ea.modrm != (MR_REG | REG_DX)) {
	Notify(NOTIFY_ERROR, expr2->file, expr2->line,
	       "port must be DX or an immediate value < 256");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    } else {
	/*
	 * The opcode is in the value field of op, but is offset by 8, with
	 * 1 added if the operand size is a word.
	 */
	*ip++ = (byte)(op->value + 8 + (Type_Size(r1->type) == 2));
    }

    /*
     * Install the instruction itself.
     */
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, NULL, -1,
	      expr1->file, expr1->line, 0);

    CodeCleanup(expr1, &res1, expr2, &res2);
    return(FR_DONE);
}


/***********************************************************************
 *				Code_Ins
 ***********************************************************************
 * SYNOPSIS:	    Handle an INS instruction
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Ins(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);
    ASSERT_186();
    ASSERT_IO();

    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	   "INS not supported");

    return(FR_ERROR);
}


/***********************************************************************
 *				Code_Int
 ***********************************************************************
 * SYNOPSIS:	    Handle an INT instruction
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Int(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[2];
    byte    	*ip = ibuf;
    ExprResult	res1;
    FixResult	result;
    int	    	delay;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_Int, 2, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Range- and type-check operands
     */
    if (res1.type != EXPR_TYPE_CONST) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "INT requires numeric constant as operand");
	CodeCleanup(expr1, &res1, NULL, NULL);
	return(FR_ERROR);
    }

    if ((unsigned long)res1.data.number > 255) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "INT operand must be < 256");
	CodeCleanup(expr1, &res1, NULL, NULL);
	return(FR_ERROR);
    }

    /*
     * Prepare instruction
     */
    if (res1.data.number == 3) {
	*ip++ = 0xcc;
    } else {
	*ip++ = 0xcd;
	*ip++ = (byte)res1.data.number;
    }

    /*
     * Install the instruction itself.
     */
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, NULL, -1,
	      expr1->file, expr1->line, 0);

    CodeCleanup(expr1, &res1, NULL, NULL);
    return(FR_DONE);
}


/***********************************************************************
 *				Code_Jmp
 ***********************************************************************
 * SYNOPSIS:	    Deal with a JMP instruction.
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_OPTIM or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Jmp(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[5];	/* FAR jump is five bytes */
    byte    	*ip = ibuf;
    ExprResult	res1;
    FixResult	result;
    int	    	fixAddr = -1;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     * 5/5/94: use a default size of 2 if short operator specified and
     * expr contains undefined stuff -- ardeb
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_Jmp,
			 Expr_InvolvesOp(expr1, EXPR_SHORT) ? 2 : 3,
			 data, &delay);
    if (result != FR_DONE) {
	if (result == FR_UNDEF) {
	    curSeg->u.segment.data->checkLabel = TRUE;
	}
	return(result);
    }

    /*
     * Passes 1 and 2 only serve to type-check the arguments for the
     * direct mode of this instruction. For indirect jumps (e.g. "JMP AX"),
     * the code is generated in either pass 1 or 2.
     */
    if (pass <= 2) {
	result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line,
				(OpCode *)data);
	if (result != FR_DONE) {
	    return(result);
	}
	/*
	 * Make sure operand is not a segment register, since we can't
	 * use segment registers here.
	 */
	if (EXPR_IS_SEGREG(&res1)) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "JMP can't operate on a segment register");
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}
    }

    if ((res1.data.ea.modrm == MR_DIRECT) &&
	((res1.type == Type_Near()) || (res1.type == Type_Far())))
    {
	/*
	 * Direct jump. Destination of jump is res1.rel.sym with optional
	 * displacement...
	 */
	SymbolPtr   dest = res1.rel.sym;

	if (dest == NULL) {
	    /*
	     * Handle a jump to an absolute routine (which must be FAR,
	     * since a near jump to an absolute address makes no sense
	     * in this universe, what with code blocks moving and
	     * linking of object modules, etc.).
	     */
	    if (res1.type == Type_Far()) {
		*ip++ = 0xea;
		*ip++ = (byte)res1.data.ea.disp;
		*ip++ = (byte)(res1.data.ea.disp >> 8);
		*ip++ = 0;
		*ip++ = 0;
		/*
		 * Modify the FixDesc for the result to be a segment-only
		 * fixup for the frame relative to which the call is being
		 * made...
		 */
		fixAddr = (*addrPtr) + 3;
		res1.rel.size = FIX_SIZE_WORD;
		res1.rel.type = FIX_SEGMENT;
		res1.rel.sym = res1.rel.frame;
		res1.rel.pcrel = 0;
	    } else {
		/*
		 * Absolute near jumps are verboten
		 */
		Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "near jump to absolute routine not allowed");
		CodeCleanup(expr1, &res1, NULL, NULL);
		return(FR_ERROR);
	    }
	} else if (res1.type == Type_Far()) {
	    /*
	     * Jump to a far routine -- see if it's in the same segment
	     * as the jump itself. If so, we can just use a near
	     * jump instead.
	     */
	    if ((dest->segment == curSeg) ||
		((res1.rel.frame == curSeg->segment) &&
		 (res1.rel.frame != global)))
	    {
		/*
		 * In same segment or group (that's the rel.frame
		 * comparison...), so we can do a near jump, which means
		 * we try to optimize.
		 */
		result = FR_OPTIM;
	    } else {
		/*
		 * Straight far jump -- no optimization possible.
		 */
		if ((res1.rel.frame == global) && warn_unknown) {
		    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
			    "segment for %i not known", dest->name);
		}

		*ip++ = 0xea;   /* JMP FAR PTR */
		/* Displacement */
		*ip++ = (byte)res1.data.ea.disp;
		*ip++ = (byte)(res1.data.ea.disp >> 8);
		/* Store 0 for segment (just takes up
		 * room */
		*ip++ = 0;
		*ip++ = 0;

		/*
		 * Take care of any funkiness induced by this being the second
		 * half of a transformed conditional
		 */
		res1.rel.type = FIX_OFFSET;
		res1.rel.size = FIX_SIZE_WORD;
		res1.rel.pcrel = 0;

		/*
		 * Far jumps must be made to fixed segments...
		 */
		res1.rel.fixed = 1;

		/*
		 * Set fixAddr to reflect the field's offset
		 */
		fixAddr = (*addrPtr) + 1;
	    }
	} else if (dest->segment != curSeg) {
	    /*
	     * XXX: Check to see if segment is known and unrelated and bitch if
	     * so. For now, just punt the buck to the linker, entering a pc-
	     * relative relocation for it.
	     */
	    if (res1.rel.size == FIX_SIZE_BYTE) {
		Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		       "can't be reached with short jump -- SHORT override ignored");
		res1.rel.size = FIX_SIZE_WORD;
		res1.rel.type = FIX_OFFSET;
	    }
	    *ip++ = 0xe9;
	    *ip++ = (byte)res1.data.ea.disp;
	    *ip++ = (byte)(res1.data.ea.disp >> 8);
	    fixAddr = (*addrPtr) + 1;
	    res1.rel.pcrel = 1;
	    result = FR_DONE;
	} else {
	    /*
	     * Near jump...optimize
	     */
	    result = FR_OPTIM;
	}
	if ((dest != NULL) && (dest->type == SYM_PROC) &&
	    (dest->u.proc.flags & SYM_NO_JMP))
	{
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
			"routine %i may not be jumped to",
			dest->name);
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}

	if (result == FR_OPTIM) {
	    /*
	     * This is one of those things that can be optimized by
	     * choosing between a short jump and a near one.
	     *
	     * During passes 2, 3 and 4, we decide on what instruction
	     * we want, but only on pass 2 or 3 are we allowed to adjust
	     * the size allocated for the instruction. On pass 4, if the
	     * size allocated doesn't match that desired, we need to
	     * either stuff in a nop or generate an error. This
	     * can only be caused by certain pathological cases:
	     *
	     *  label1:
	     *  	jmp label2
	     *
	     *  	org label1+125
	     *
	     *  	jmp label1
	     *  label2:
	     *
	     * On each pass optimization pass, the two jumps would
	     * switch style (go from short to near or vice versa),
	     * finally ending with one being unable to reach the
	     * desired label because it can't expand.
	     */
	    int disp;

	    /*
	     * Figure displacement, assuming short jump. Since the
	     * current offset of the destination symbol isn't added
	     * in by Expr_Eval (it would confuse the linker), we have to
	     * add it in ourselves.
	     */
	    disp = (dest->u.addrsym.offset + res1.data.ea.disp) -
		((*addrPtr) + 2);

	    if (pass == 4) {
		/*
		 * Final pass -- must store something w/o  modifying the
		 * instruction size.
		 */
		if (!(dest->flags & SYM_UNDEF) &&
		    (disp >= -128) &&
		    (disp <= 127))
		{
		    /*
		     * We can get to it with a short jump and there's
		     * nothing the linker need do for us, so null out
		     * res1.rel.sym.
		     */
		    *ip++ = 0xeb;
		    *ip++ = (byte)disp;
		    res1.rel.sym = NULL;

		    if (prevSize != 2) {
			/*
			 * Fill out with NOPs
			 */
			ip = CodeNopPad(ip, prevSize-2, expr1->file,
					expr1->line);
		    }
		} else {
		    if (res1.rel.size == FIX_SIZE_BYTE) {
			/*
			 * User gave a SHORT override, but we can't use
			 * it, so warn him/her and reset the FixDesc to
			 * be as for a regular near jump.
			 */
			Notify(NOTIFY_WARNING, expr1->file, expr1->line,
			       "can't be reached with short jump -- SHORT override ignored");
			res1.rel.size = FIX_SIZE_WORD;
			res1.rel.type = FIX_OFFSET;
		    }

		    /*
		     * Make sure things aren't horribly confused, warning
		     * the user if they are...
		     */
		    if (prevSize < 3) {
			Notify(NOTIFY_ERROR, expr1->file, expr1->line,
			       "can't store near jump -- optimization error");
			CodeCleanup(expr1, &res1, NULL, NULL);
			return(FR_ERROR);
		    }

		    /*
		     * Store a near direct jump using the displacement
		     * in the result -- the final symbol offset will
		     * be added in by the linker.
		     */
		    *ip++ = 0xe9;
		    *ip++ = (byte)res1.data.ea.disp;
		    *ip++ = (byte)(res1.data.ea.disp >> 8);
		    fixAddr = (*addrPtr) + 1;
		    /*
		     * Near-jumps are PC-relative
		     */
		    res1.rel.pcrel = 1;
		}
	    } else {
		/*
		 * Not in final pass -- figure how big we'd make the
		 * instruction given the current state of the world and
		 * allocate that much space (the adjustment is performed
		 * by CodeFinal).
		 */
		if (!(dest->flags & SYM_UNDEF) &&
		    (disp >= -128) &&
		    (disp <= 127))
		{
		    *ip++ = 0xeb;
		    *ip++ = (byte)disp;
		    /*
		     * Special case for "jmp $+2" used for delay on an AT. If
		     * we don't do this, we get bogus warnings about unreachable
		     * code.
		     */
		    if (disp == 0) {
			curSeg->u.segment.data->lastLabel = (*addrPtr)+2;
		    }
		} else {
		    *ip++ = 0xe9;
		    *ip++ = (byte)res1.data.ea.disp;
		    *ip++ = (byte)(res1.data.ea.disp >> 8);
		}
		if (pass == 1) {
		    /*
		     * First pass with backward jump -- register an
		     * FC_OPTIM fixup for this address. For pass 2,
		     * the result is already FR_OPTIM, so the fixup
		     * will be transformed automatically.
		     */
		    Fix_Register(FC_OPTIM, Code_Jmp,
				 *addrPtr, ip - ibuf, expr1, expr2, data);
		}
	    }
	}
    } else {
	/*
	 * Indirect jump... near indirect is encoded ff /4, while far is ff /5
	 */
	byte 	reg;
	int 	size;

	CodeSimplifyType(&res1.type, expr1->file, expr1->line, FALSE);

	size = Type_Size(res1.type);

	switch(size) {
	    case 2: reg = 4; break;
	    case 4: reg = 5; break;
	    default:
		Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "illegal size (%d) for indirect jump vector", size);
		CodeCleanup(expr1, &res1, NULL, NULL);
		return(FR_ERROR);
	}

	/*
	 * Shift /n into position
	 */
	reg <<= MR_REG_SHIFT;

	fixAddr = (*addrPtr) + 2;
	if (EXPR_NEEDS_OVERRIDE(&res1)) {
	    *ip++ = res1.data.ea.override;
	    fixAddr += 1;
	}
	*ip++ = 0xff;
	ip = CodeStoreEA(ip, res1.data.ea.modrm, reg, res1.data.ea.dword_ea,
			 res1.data.ea.sib, res1.data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);
    }

    /*
     * Install the instruction itself. Note that if optimizing and not
     * in final pass, fixAddr remains -1, so no external fixup is
     * registered for the address until pass 4.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);

    curSeg->u.segment.data->checkLabel = TRUE;

    if (fixAddr >= 0 && ibuf[0] == 0xea && res1.rel.sym) {
	/*
	 * FAR jump and we entered a fixup for it -- need to enter an
	 * external fixup for the segment portion as well. The linker
	 * takes dword offset relocations to be just that -- it doesn't
	 * treat the dword as a far pointer.
	 */
	res1.rel.type = FIX_SEGMENT;
	fixAddr += 2;
	Fix_Enter(&res1, fixAddr, startAddr);
    }

    if (delay && result != FR_OPTIM) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Jmp,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }

    CodeCleanup(expr1, &res1, NULL, NULL);
    return(result);
}


/***********************************************************************
 *				Code_JccWarn
 ***********************************************************************
 * SYNOPSIS:	    Front-end for Code_Jcc during fixup to set warn_jmp
 *		    to its value at the time Code_Jcc was initially called
 * CALLED BY:	    Fixup module
 * RETURN:	    whatever Code_Jcc returns
 * SIDE EFFECTS:    warn_jmp is set non-zero
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_JccWarn(int *addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 (NULL) */
      Opaque	data)	    	/* OpCode/other data */
{
    warn_jmp = 1;

    return (Code_Jcc(addrPtr, prevSize, pass, expr1, expr2, data));
}

/***********************************************************************
 *				Code_JccNoWarn
 ***********************************************************************
 * SYNOPSIS:	    Front-end for Code_Jcc during fixup to set warn_jmp
 *		    to its value at the time Code_Jcc was initially called
 * CALLED BY:	    Fixup module
 * RETURN:	    whatever Code_Jcc returns
 * SIDE EFFECTS:    warn_jmp is set zero
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_JccNoWarn(int *addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 (NULL) */
      Opaque	data)	    	/* OpCode/other data */
{
    warn_jmp = 0;

    return (Code_Jcc(addrPtr, prevSize, pass, expr1, expr2, data));
}

/***********************************************************************
 *				Code_Jcc
 ***********************************************************************
 * SYNOPSIS:	    Generate code for all conditional jumps.
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_OPTIM or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Jcc(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 (NULL) */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[7];    	/* short jump + far jump */
    byte    	*ip = ibuf; 	/* Current location in ibuf */
    ExprResult	res1;	    	/* Result of evaluating expr1 */
    FixResult	result;	    	/* Result to return */
    int	    	fixAddr = -1;	/* Address for fixup from inst */
    OpCode  	*op = (OpCode *)data;
    int	    	disp;	    	/* Displacement for short jump */
    int	    	startAddr;  	/* Start address (for Fix_Register) */
    int	    	delay;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    curSeg->u.segment.data->blockStart = TRUE;

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 warn_jmp ? Code_JccWarn : Code_JccNoWarn,
			 2, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * First type-check the destination -- it must be a direct-addressed
     * near or far label. This checking is skipped on passes 3 and 4.
     */
    if (pass <= 2) {
	result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line,
				(OpCode *)data);
	if (result != FR_DONE) {
	    return(result);
	}

	/*
	 * Make sure operand is not a segment register, since we can't
	 * use segment registers here.
	 */
	if (EXPR_IS_SEGREG(&res1)) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "%s can't operate on a segment register", op->name);
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}

	if (res1.data.ea.modrm != MR_DIRECT) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "operand of %s must be addressable directly",
		   op->name);
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}
	if (res1.type != Type_Near() && res1.type != Type_Far()) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "operand of %s must be (offset from) a near or far label",
		   op->name);
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}
	if (res1.rel.sym == NULL) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "can't %s to an absolute address",
		   op->name);
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}
	if (res1.rel.sym->flags & SYM_UNDEF) {
	    if (pass == 1) {
		/*
		 * Wait for pass 2 to resolve this
		 */
		Table_Store(curSeg->u.segment.code, 2, (void *)ibuf,
			    *addrPtr);
		Fix_Register(FC_UNDEF,
			     warn_jmp ? Code_JccWarn : Code_JccNoWarn,
			     *addrPtr, 2, expr1, NULL,
			     data);
		*addrPtr += 2;
		CodeCleanup(expr1, &res1, NULL, NULL);
		return(FC_UNDEF);
	    }
	}

    }

    /*
     * At this point, we know the operand is valid, but it might be too
     * far away.
     */

    /*
     * Figure displacement: Since the current offset of the destination
     * symbol isn't added in by Expr_Eval (it would confuse the linker),
     * we have to add it in ourselves.
     *
     * If the symbol isn't in the current segment, we set disp to by 65536
     * (beyond the bounds of a near jump) to force a change to a far jump.
     * If the symbol's in the current segment but is undefined, we set
     * disp to be -256 (beyond the bounds of a near jump) to force a
     * change to a near jump.
     */
    disp = ((res1.rel.sym->segment == curSeg) ?
	    ((res1.rel.sym->flags & SYM_UNDEF) ? -256 :
	     ((res1.rel.sym->u.addrsym.offset + res1.data.ea.disp) -
	      ((*addrPtr)+2))) : 65536);

#define JCXZ 0xe3

    if ((disp >= -128) && (disp <= 127)) {
	/*
	 * It all fits...
	 */
	*ip++ = (byte)op->value;
	*ip++ = (byte)disp;

	if (pass == 4 && prevSize != 2) {
	    /*
	     * Final pass: previous pass allocated more room than we
	     * need. Nothing for it but to insert extra NOPs and warn
	     * the user.
	     */
	    ip = CodeNopPad(ip, prevSize - 2, expr1->file, expr1->line);
	}

	/*
	 * No linker fixup needed
	 */
	res1.rel.sym = NULL;
    } else if ((pass != 4) &&
	       (disp > 0) &&
	       (prevSize > 2) &&
	       ((disp - (prevSize-2)) <= 127))
    {
	/*
	 * We are impeding progress: we enlarged ourself on a previous pass,
	 * but it is our own size that is preventing us from jumping forward
	 * without transformation. Scale ourselves back appropriately please.
	 */
	disp -= (prevSize - 2);
	*ip++ = (byte)op->value;
	*ip++ = (byte)disp;

	res1.rel.sym = NULL;
    } else if ((disp >= -32768) && (disp <= 32767)) {
	if (op->value != JCXZ) {
	    /*
	     * Transform it into !Jcc $+3; jmp dest. The negation of each
	     * Jcc is formed by inverting the low bit (pretty cool...).
	     * NOTE: We cannot do this for JCXZ.
	     */
	    *ip++ = (byte)(op->value ^ 1);
	    *ip++ = 3;  	/* Jump over a near jump */
	    *ip++ = 0xe9;
	    *ip++ = (byte)res1.data.ea.disp;
	    *ip++ = (byte)(res1.data.ea.disp >> 8);
	} else {
	    /*
	     * Transform it into jcxz $+2; jmp $+3; jmp dest
	     */
	    *ip++ = JCXZ;
	    *ip++ = 2;
	    *ip++ = 0xeb;
	    *ip++ = 3;
	    *ip++ = 0xe9;
	    *ip++ = (byte)res1.data.ea.disp;
	    *ip++ = (byte)(res1.data.ea.disp >> 8);
	}

	if (pass == 4) {
	    /*
	     * Make sure there's actually enough room allocated to store
	     * this thing.
	     */
	    if (prevSize < ip - ibuf) {
		Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "can't store transformed out-of-range jump -- optimization error");
		CodeCleanup(expr1, &res1, NULL, NULL);
		return(FR_ERROR);
	    }

	    /*
	     * Figure amount by which the jump is out-of-range and warn
	     * the user about the pending transformation.
	     */
	    if (disp < 0) {
		disp = -disp - 128;
	    } else {
		disp -= 127;
	    }
	    if (warn_jmp && !(readCheck || writeCheck)) {
		Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		       "jump out of range by %d byte%s -- transformed to %s jump",
		       disp, disp == 1 ? "" : "s",
		       op->value == JCXZ ? "triple" : "double");
	    }
	    /*
	     * Take note of the pc-relative fixup needed in near jump
	     */
	    if (op->value == JCXZ) {
		fixAddr = (*addrPtr) + 5;
	    } else {
		fixAddr = (*addrPtr) + 3;
	    }
	    res1.rel.pcrel = 1;
	    /*
	     * Set type & size in case short override was used.
	     */
	    res1.rel.type = FIX_OFFSET;
	    res1.rel.size = FIX_SIZE_WORD;
	}
    } else {
	/*
	 * Conditional jump to another segment. What the hell. Might as well
	 * support it.
	 */
	if (op->value != JCXZ) {
	    /*
	     * Conditional jump to another segment. What the hell. Might as
	     * well support it. This thing gets transformed into
	     * !Jcc $+5; jmp dest. Negation performed as above.
	     */
	    *ip++ = (byte)(op->value ^ 1);
	    *ip++ = 5;  /* Jump over a far jump */
	} else {
	    *ip++ = JCXZ;
	    *ip++ = 2;
	    *ip++ = 0xeb;
	    *ip++ = 5;
	}
	res1.rel.sym = NULL;

	Notify(NOTIFY_WARNING, expr1->file, expr1->line,
	       "%s to a different segment -- transformed to far jump",
	       op->name);
    }

    if ((res1.rel.sym != NULL) &&
	(res1.rel.sym->type == SYM_PROC) &&
	(res1.rel.sym->u.proc.flags & SYM_NO_JMP))
    {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		    "routine %i may not be jumped to",
		    res1.rel.sym->name);
	CodeCleanup(expr1, &res1, NULL, NULL);
	return(FR_ERROR);
    }

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, 0);

    if (disp > 32767) {
	/*
	 * Thing was transformed into a jump over a far jump, but we need
	 * to get the far jump stored. In addition, there's no need
	 * for optimizing this thing, since a far jump will stay a far
	 * jump for ever, symbols not being able to switch segments...
	 */
	result = Code_Jmp(addrPtr, 0, pass, expr1, expr2, data);
	curSeg->u.segment.data->checkLabel = FALSE;
    } else {
	/*
	 * Deal with registration for optimization
	 */
	if (pass >= 2) {
	    /*
	     * If on pass 2 or later, change this fixup to an optimization
	     * fixup. If actually on pass 3, need to return FR_OPTIM to keep
	     * being called. If on pass 4, it doesn't matter what we return.
	     */
	    result = FR_OPTIM;
	} else if (pass == 1) {
	    Fix_Register(FC_OPTIM,
			 warn_jmp ? Code_JccWarn : Code_JccNoWarn,
			 startAddr, ip-ibuf, expr1, NULL, data);
	}
    }

    /*
     * Return calculated result
     */
    CodeCleanup(expr1, &res1, NULL, NULL);
    return(result);
}


/***********************************************************************
 *				Code_LSInfo
 ***********************************************************************
 * SYNOPSIS:	    Handle the LAR and LSL instructions
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_LSInfo(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[6];    	/* 1 override, 2 opcode, 1 modrm, 2 disp */
    byte    	*ip = ibuf;
    ExprResult	res1, res2;
    FixResult	result;
    OpCode  	*op = (OpCode *)data;
    int	    	fixAddr;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ASSERT_286();
    ASSERT_PROT();

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 Code_LSInfo, 3, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure neither operand is a constant -- we don't do constants here
     */
    result = CodeNoConstant(expr1, &res1, expr2, &res2, expr1->file, expr1->line,
			    op);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure neither operand is a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1) || EXPR_IS_SEGREG(&res2)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "%s can't operate on a segment register", op->name);
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    /*
     * Make sure the dest is a word register, but don't leave yet if it's
     * not -- want to catch any errors in the source.
     */
    if (((res1.data.ea.modrm & MR_DISP_MASK) != MR_REG) ||
	(Type_Size(res1.type) != 2))
    {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "first operand for %s must be a word register", op->name);
	result = FR_ERROR;
    }

    /*
     * Simplify the type of the source before checking its size
     */
    CodeSimplifyType(&res2.type, expr2->file, expr2->line, FALSE);

    /*
     * Make sure the destination is a word variable.
     */
    if (Type_Size(res2.type) != 2) {
	Notify(NOTIFY_ERROR, expr2->file, expr2->line,
	       "second operand for %s must be a word variable/register",
	       op->name);
	result = FR_ERROR;
    }

    if (result == FR_DONE) {
	/*
	 * Store override if needed
	 */
	fixAddr = (*addrPtr) + 2;
	if (EXPR_NEEDS_OVERRIDE(&res2)) {
	    *ip++ = res2.data.ea.override;
	    fixAddr++;
	}
	/*
	 * Store opcode (constant)
	 */
	*ip++ = (byte)op->value;
	*ip++ = (byte)(op->value >> 8);

	/*
	 * Store away the source ea merged with the dest reg
	 */
	ip = CodeStoreEA(ip,
			 res2.data.ea.modrm,
			 (byte)(res1.data.ea.modrm << MR_REG_SHIFT),
			 res2.data.ea.dword_ea,
			 res2.data.ea.sib,
			 res2.data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);

	/*
	 * Install the instruction itself
	 */
	startAddr = *addrPtr;
	CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res2, fixAddr,
		  expr2->file, expr2->line, delay);
	if (delay) {
	    if (pass > 1) {
		CodeCleanup(expr1, &res1, expr2, &res2);
		return(FR_FINAL);
	    } else {
		Fix_Register(FC_FINAL, Code_LSInfo,
			     startAddr, ip - ibuf, expr1, expr2, data);
	    }
	}
    }
    /*
     * Return whatever result we've calculated
     */
    CodeCleanup(expr1, &res1, expr2, &res2);
    return(result);
}


/***********************************************************************
 *				Code_LDPtr
 ***********************************************************************
 * SYNOPSIS:	    Handle LGS/LSS/LDS/LES/LFS instructions
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_LDPtr(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[11];    	/* override, prefixes, 2 opcode, modrm,
				 * sib, 4 disp */
    byte    	*ip = ibuf; 	/* Current byte in ibuf */
    ExprResult	res1, res2; 	/* Results of evaluating expr1 and expr2 */
    FixResult	result;	    	/* Result to return */
    int	    	fixAddr;    	/* Address of any necessary fixup */
    OpCode  	*op = (OpCode *)data;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 Code_LDPtr, 4, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure neither operand is a constant
     */
    result = CodeNoConstant(expr1, &res1, expr2, &res2, expr1->file, expr1->line,
			    (OpCode *)data);

    if (result == FR_DONE) {
	/*
	 * Make sure neither operand is a segment register, since we can't
	 * use segment registers here.
	 */
	if (EXPR_IS_SEGREG(&res1) || EXPR_IS_SEGREG(&res2)) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "%s can't operate on a segment register", op->name);
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_ERROR);
	}

	/*
	 * Make sure the desintation is a [d]word register and the
	 * source is a memory operand
	 */
	if (((res1.data.ea.modrm & MR_DISP_MASK) != MR_REG) ||
	    (Type_Size(res1.type) < 2))
	{
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "destination of %s must be a word or dword register",
		   op->name);
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_ERROR);
	}

	if ((res2.data.ea.modrm & MR_DISP_MASK) == MR_REG) {
	    Notify(NOTIFY_ERROR, expr2->file, expr2->line,
		   "source for %s must be in memory",
		   op->name);
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_ERROR);
	}

	/*
	 * LGS, LSS, and LFS are only available on the 80386 or better.
	 */
	if (op->value & 0xff00)
	    ASSERT_386();

	/*
	 * Store segment override and prefixes if required.
	 */
	fixAddr = (*addrPtr) + 2;
	if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res2)) {
	    *ip++ = PRE_ADDRESS;
	    fixAddr += 1;
	}
	if (USE_386() && EXPR_NEEDS_PRE_OPERAND(&res1)) {
	    *ip++ = PRE_OPERAND;
	    fixAddr += 1;
	}
	if (EXPR_NEEDS_OVERRIDE(&res2)) {
	    *ip++ = res2.data.ea.override;
	    fixAddr++;
	}
	/*
	 * Store the rest of the instruction.
	 */
	if (op->value & 0xff00) {
	    *ip++ = (byte)(op->value >> 8);
	    fixAddr ++;
	}
	*ip++ = (byte)op->value;
	ip = CodeStoreEA(ip,
			 res2.data.ea.modrm,
			 (byte)(res1.data.ea.modrm << MR_REG_SHIFT),
			 res2.data.ea.dword_ea,
			 res2.data.ea.sib,
			 res2.data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);
	/*
	 * Install the instruction itself.
	 */
	startAddr = *addrPtr;
	CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res2, fixAddr,
		  expr2->file, expr2->line, delay);
	if (delay) {
	    if (pass > 1) {
		CodeCleanup(expr1, &res1, expr2, &res2);
		return(FR_FINAL);
	    } else {
		Fix_Register(FC_FINAL, Code_LDPtr,
			     startAddr, ip - ibuf, expr1, expr2, data);
	    }
	}
    }

    CodeCleanup(expr1, &res1, expr2, &res2);
    return(result);
}


/***********************************************************************
 *				Code_Lea
 ***********************************************************************
 * SYNOPSIS:	    Handle an LEA
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Lea(int	*addrPtr,	/* IN/OUT: Address of instruction start */
	 int   	prevSize,   	/* # bytes previously allocated to inst */
	 int   	pass,	    	/* Current pass */
	 Expr  	*expr1,	    	/* Operand 1 */
	 Expr  	*expr2,	    	/* Operand 2 */
	 Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[4];    	/* opcode, modrm, 2 disp */
    byte    	*ip = ibuf;
    ExprResult	res1, res2;
    FixResult	result;
    int	    	fixAddr=-1;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 Code_Lea, 4, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    result = CodeNoConstant(expr1, &res1, expr2, &res2, expr1->file, expr1->line,
			    (OpCode *)data);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure neither operand is a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1) || EXPR_IS_SEGREG(&res2)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "LEA can't operate on a segment register");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    /*
     * Make sure the desintation is a word register and the
     * source is a memory operand (can't take effective address of a
     * register)
     */
    if (((res1.data.ea.modrm & MR_DISP_MASK) != MR_REG) ||
	(Type_Size(res1.type) != 2))
    {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "destination of LEA must be a word register");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    if ((res2.data.ea.modrm & MR_DISP_MASK) == MR_REG) {
	Notify(NOTIFY_ERROR, expr2->file, expr2->line,
	       "source for LEA must be in memory");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    if (res2.data.ea.modrm == MR_DIRECT) {
	/*
	 * Switch to be a MOV rw, dw, since that's faster and smaller
	 */
	*ip++ = 0xb8 + (res1.data.ea.modrm & MR_RM_MASK);
	*ip++ = (byte)res2.data.ea.disp;
	*ip++ = (byte)(res2.data.ea.disp >> 8);
	fixAddr = (*addrPtr) + 1;
    } else if ((((res2.data.ea.modrm & MR_DISP_MASK) == MR_NULL_DISP) &&
		((res2.data.ea.modrm & MR_RM_MASK) > MR_BP_DI)) ||
	       (((res2.data.ea.modrm & ~MR_REG_MASK) == (MR_BYTE_DISP|MR_BP))&&
		(res2.data.ea.disp == 0)))
    {
	/*
	 * Displacement used is 0, so there's no point in generating a full LEA
	 * instruction. Instead, we just generate a register MOV instruction,
	 * unless the source and destination registers are the same, in which
	 * case we generate nothing.
	 */
	int reg2 = -1;

	switch(res2.data.ea.modrm & MR_RM_MASK) {
	    case MR_BX: reg2 = REG_BX; break;
	    case MR_BP: reg2 = REG_BP; break;
	    case MR_SI: reg2 = REG_SI; break;
	    case MR_DI: reg2 = REG_DI; break;
	}

	if ((res1.data.ea.modrm & MR_RM_MASK) != reg2) {
	    /*
	     * Just a register load...
	     */
	    *ip++ = 0x8b;
	    *ip++ = MR_REG | (res1.data.ea.modrm << MR_REG_SHIFT) | reg2;
	}
    } else {
	/*
	 * Store the instruction, ignoring any segment override on the
	 * source (it's used only for figuring out the relocation frame...)
	 */
	*ip++ = 0x8d;
	ip = CodeStoreEA(ip,
			 res2.data.ea.modrm,
			 (byte)(res1.data.ea.modrm << MR_REG_SHIFT),
			 res2.data.ea.dword_ea,
			 res2.data.ea.sib,
			 res2.data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);
	fixAddr = (*addrPtr)+2;
    }
    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res2, fixAddr,
	      expr2->file, expr2->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Lea,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }

    CodeCleanup(expr1, &res1, expr2, &res2);
    return(FR_DONE);
}


/***********************************************************************
 *				Code_Lock
 ***********************************************************************
 * SYNOPSIS:	    Deal with LOCK
 * CALLED BY:	    yyparse, Fixup
 * RETURN:	    FR_DONE or FR_ERROR
 * SIDE EFFECTS:    An FC_FINAL fixup is registered in pass 1
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/29/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Lock(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    if (pass == 1) {
	/*
	 * First pass -- store the prefix and register an FC_FINAL fixup
	 */
	byte	ibuf[1];

	ibuf[0] = ((OpCode *)data)->value;

	Table_Store(curSeg->u.segment.code, 1, (void *)ibuf, *addrPtr);

	Fix_Register(FC_FINAL, Code_Lock, *addrPtr, 1, expr1, NULL, data);

	*addrPtr += 1;

	return(FR_DONE);
    } else {
	/*
	 * Make sure the stored instruction matches the prefix.
	 */
	byte	ibuf[2];
	int 	addr;

	/*
	 * Skip over segment overrides and prefixes...
	 */
	addr = *addrPtr;
	do {
	    addr++;
	    Table_Fetch(curSeg->u.segment.code, 2, (void *)ibuf, addr);
	} while ((ibuf[0] & 0xe7) == 0x26 || (ibuf[0] & 0xfc) == 0x64);

	/*
	 * Update address so caller doesn't think we shrank or grew...
	 */
	*addrPtr += 1;

	/*
	 * There is only a small set of instructions the '386 allows to be
	 * prefixed by LOCK. These are:
	 *  BT, BTS, BTR, BTC, XCHG, ADD, OR, ADC, SBB, AND, SUB, XOR,
	 *  NOT, NEG, INC and DEC
	 * In addition, they may only be LOCKed if they modify memory
	 * The following ugly switch encodes this...
	 */
	switch(ibuf[0]) {
	    case 0x86:	case 0x87:  /* XCHG w/mem */
		return(FR_DONE);
	    case 0xf6: case 0xf7:   /* NOT/NEG */
		switch (ibuf[1] & MR_REG_MASK) {
		    case 2: case 3:
			if ((ibuf[1] & MR_DISP_MASK) != MR_REG) {
			    return(FR_DONE);
			}
		}
		break;
	    case 0xfe: case 0xff:   /* INC/DEC */
		if (((ibuf[1] & MR_REG_MASK) <= (1 << MR_REG_SHIFT)) &&
		    ((ibuf[1] & MR_DISP_MASK) != MR_REG))
		{
		    return(FR_DONE);
		}
		break;
	    case 0x00: case 0x01:   /* ADD */
	    case 0x08: case 0x09:   /* OR  */
	    case 0x10: case 0x11:   /* ADC */
	    case 0x18: case 0x19:   /* SBB */
	    case 0x20: case 0x21:   /* AND */
	    case 0x28: case 0x29:   /* SUB */
	    case 0x30: case 0x31:   /* XOR */
		/*
		 * Make sure destination is memory
		 */
		if ((ibuf[1] & MR_DISP_MASK) != MR_REG) {
		    return(FR_DONE);
		}
		break;
	}
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "instruction may not be LOCKed (see p. 17-100 of '386 manual)");
	return(FR_ERROR);
    }
}

/***********************************************************************
 *				Code_Loop
 ***********************************************************************
 * SYNOPSIS:	    Handle a LOOP, LOOPE, LOOPNE, LOOPZ or LOOPNZ
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_OPTIM or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Loop(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[7];    	/* opcode + cb */
    byte    	*ip = ibuf;
    ExprResult	res1;
    FixResult	result;
    OpCode  	*op = (OpCode *)data;
    int	    	disp;
    int	    	delay;
    int	    	fixAddr = -1;	/* Address for fixup from inst */
    int	    	startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    curSeg->u.segment.data->blockStart = TRUE;

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_Loop, 2, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line,
			    (OpCode *)data);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure operand is not a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "%s can't operate on a segment register", op->name);
	CodeCleanup(expr1, &res1, NULL, NULL);
	return(FR_ERROR);
    }

    if (res1.rel.sym == NULL) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "can't %s to an absolute address", op->name);
	CodeCleanup(expr1, &res1, NULL, NULL);
	return(FR_ERROR);
    }

    /*
     * Figure displacement: Since the current offset of the destination
     * symbol isn't added in by Expr_Eval (it would confuse the linker),
     * we have to add it in ourselves.
     */
    disp = (res1.rel.sym->u.addrsym.offset+res1.data.ea.disp) - ((*addrPtr)+2);

    if ((disp >= -128) && (disp <= 127)) {
	/*
	 * It all fits...
	 */
	*ip++ = (byte)op->value;
	*ip++ = (byte)disp;

	if ((pass == 4) && (prevSize != 2)) {
	    /*
	     * Final pass: previous pass allocated more room than we
	     * need. Nothing for it but to insert extra NOPs and warn
	     * the user.
	     */
	    ip = CodeNopPad(ip, prevSize - 2, expr1->file, expr1->line);
	}

	/*
	 * No linker fixup needed
	 */
	res1.rel.sym = NULL;

    } else if ((pass != 4) &&
	       (disp > 0) &&
	       (prevSize > 2) &&
	       ((disp - (prevSize-2)) <= 127)) {
	/*
	 * We are impeding progress: we enlarged ourself on a previous pass,
	 * but it is our own size that is preventing us from jumping forward
	 * without transformation. Scale ourselves back appropriately please.
	 */
	disp -= (prevSize - 2);
	*ip++ = (byte)op->value;
	*ip++ = (byte)disp;

	res1.rel.sym = NULL;

    } else {

	/*
	 * The instruction can't work. The displacement is too large.
	 * We transform it into:
	 *    $:    	    	    	    <- current instruction pointer
	 *  	    loop doLoop	    	    <- 2 byte instruction
	 *  	    jmp  failure    	    <- 2 byte instruction
	 *    doLoop:	    	    	    <- $+4
	 *  	    jmp	 originalLoopDest   <- 3 byte instruction
	 *    failure:	    	    	    <- $+7
	 */
	*ip++ = (byte)op->value;	    /* loop doLoop */
	*ip++ = 2;

	*ip++ = 0xeb;			    /* jmp failure */
	*ip++ = 3;

	*ip++ = 0xe9;			    /* jmp originalLoopDest */
	*ip++ = (byte)res1.data.ea.disp;
	*ip++ = (byte)(res1.data.ea.disp >> 8);
    }

    if ((pass == 4) && ((disp < -128) || (disp > 127))) {
	/*
	 * Make sure there's actually enough room allocated to store
	 * this thing.
	 */
	if (prevSize < ip - ibuf) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "can't store transformed out-of-range loop -- optimization error");
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}

	/*
	 * Figure amount by which the loop is out-of-range and warn
	 * the user about the pending transformation.
	 */
	if (disp < 0) {
	    disp = -disp - 128;
	} else {
	    disp -= 127;
	}
	if (warn_jmp && !(readCheck || writeCheck)) {
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "loop out of range by %d byte%s -- transformed to triple jump",
		   disp, disp == 1 ? "" : "s");
	}
	/*
	 * Take note of the pc-relative fixup needed in near jump
	 */
	fixAddr = (*addrPtr) + 5;
	res1.rel.pcrel = 1;
    }

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, 0);

    if (pass >= 2) {
	/*
	 * If on pass 2 or later, change this fixup to an optimization
	 * fixup. If actually on pass 3, need to return FR_OPTIM to keep
	 * being called. If on pass 4, it doesn't matter what we return.
	 */
	result = FR_OPTIM;
    } else if (pass == 1) {
	/*
	 * If we got here on pass 1, we need to register a FINAL fixup
	 * to deal with any optimizations.
	 */
	Fix_Register(FC_OPTIM, Code_Loop, startAddr, ip-ibuf, expr1, NULL,
		     data);
    }

    CodeCleanup(expr1, &res1, NULL, NULL);
    return(result);
}


/***********************************************************************
 *				Code_LSDt
 ***********************************************************************
 * SYNOPSIS:	    Handle LGDT, LIDT, SGDT, SIDT
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_LSDt(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[7];    	/* 2 opcode + override + modrm + 2 disp */
    byte    	*ip = ibuf;
    ExprResult	res1;
    FixResult	result;
    OpCode  	*op = (OpCode *)data;
    int	    	fixAddr;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    ASSERT_PROT();

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_LSDt, 2, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line,
			    (OpCode *)data);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure operand is not a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "%s can't operate on a segment register", op->name);
	CodeCleanup(expr1, &res1, NULL, NULL);
	return(FR_ERROR);
    }

    if ((res1.data.ea.modrm & MR_DISP_MASK) == MR_REG) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "register illegal as destination of %s", op->name);
	CodeCleanup(expr1, &res1, NULL, NULL);
	return(FR_ERROR);
    }

    fixAddr = (*addrPtr)+3;
    if (EXPR_NEEDS_OVERRIDE(&res1)) {
	*ip++ = res1.data.ea.override;
	fixAddr++;
    }

    /*
     * The value of the opcode is the reg field of the modrm byte. The
     * opcode is always 0f 01
     */
    *ip++ = 0x0f;
    *ip++ = 0x01;
    ip = CodeStoreEA(ip,
		     res1.data.ea.modrm,
		     (byte)op->value,
		     res1.data.ea.dword_ea,
		     res1.data.ea.sib,
		     res1.data.ea.disp,
		     prevSize, ip-ibuf,
		     pass, &fixAddr);

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_LSDt,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }


    CodeCleanup(expr1, &res1, NULL, NULL);
    return(result);
}



/***********************************************************************
 *				Code_Move
 ***********************************************************************
 * SYNOPSIS:	    Handle MOV
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_OPTIM or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Move(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    ExprResult	res1, res2;
    byte    	ibuf[14];    	/* 14 is the most we'll ever need: prefixes,
				 * override, opcode, modrm, SIB, 4 for disp,
				 * 4 for data */
    byte    	*ip = ibuf;
    int	    	opSize;
    int	    	fixAddr=-1;    	/* Address for external fixup, if needed */
    int	    	notByte;    	/* 0 if opSize is 1, 1 if not -- used
				 * when forming opcodes */
    int		isDWord;	/* 1 if opSize is 4, 0 if not */
    ExprResult	*fixRes=NULL; 	/* Result that may need an external fixup */
    int	    	delay, startAddr;
    int		preOperand;	/* non-zero if opSize requires operand prefix */

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    switch (CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			Code_Move, 4, data, &delay))
    {
	case FR_UNDEF: return(FR_UNDEF);
	case FR_ERROR: return (FR_ERROR);
    }

    /*
     * No undefined symbols means the types of the operands are known, so
     * we can type-check.
     */
    if (!CodeCompatible(expr1, &res1, expr2, &res2,
			FALSE, FALSE, delay, &opSize))
    {
	return(FR_ERROR);
    }
    notByte = (opSize == 1) ? 0 : 1;
    isDWord = (opSize == 4) ? 1 : 0;
    preOperand = USE_386() && OPSIZE_NEEDS_PRE_OPERAND(opSize);

    if (EXPR_IS_SEGREG(&res1)) {
	byte	segreg;

	if (RES_IS_CONST(res2.type)) {
	    Notify(NOTIFY_ERROR, expr2->file, expr2->line,
		   "can't move immediate data to a segment register");
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_ERROR);
	}
	if (EXPR_IS_SEGREG(&res2)) {
	    Notify(NOTIFY_ERROR, expr2->file, expr2->line,
		   "can't move between segment registers");
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_ERROR);
	}
	if (res1.data.ea.override == OVERRIDE(REG_CS)) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "can't move to CS");
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_ERROR);
	}

	fixAddr = (*addrPtr) + 2;
	fixRes = &res2;

	if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res2)) {
	    *ip++ = PRE_ADDRESS;
	    fixAddr++;
	}
	if (USE_386() && preOperand) {
	    *ip++ = PRE_OPERAND;
	    fixAddr++;
	}
	if (EXPR_NEEDS_OVERRIDE(&res2)) {
	    *ip++ = res2.data.ea.override;
	    fixAddr++;
	}

	/*
	 * MOV segreg, ew is encoded 8e /s where /s is the segment register,
	 * as recorded in the proper bits of the override byte (no shifting
	 * required -- they must have re-used the microcode and logic for
	 * extracting the Reg field from the ModRM byte...). The exceptions
	 * are, of course, FS and GS.
	 */
	*ip++ = 0x8e;
	segreg = res1.data.ea.override;
	if (segreg >= OVERRIDE(REG_FS))
	    segreg = (segreg - 0x60) << MR_REG_SHIFT;
	else
	    segreg &= MR_SEGREG_MASK;
	ip = CodeStoreEA(ip,
			 res2.data.ea.modrm,
			 segreg,
			 res2.data.ea.dword_ea,
			 res2.data.ea.sib,
			 res2.data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);
    } else if (EXPR_IS_SEGREG(&res2)) {
	byte	segreg;

	/*
	 * All bogus cases should have been checked by now...
	 */
	fixAddr = (*addrPtr) + 2;
	fixRes = &res1;

	if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res1)) {
	    *ip++ = PRE_ADDRESS;
	    fixAddr++;
	}
	if (USE_386() && preOperand) {
	    *ip++ = PRE_OPERAND;
	    fixAddr++;
	}
	if (EXPR_NEEDS_OVERRIDE(&res1)) {
	    *ip++ = res1.data.ea.override;
	    fixAddr++;
	}

	/*
	 * MOV ew, segreg is encoded 8c /s where /s is the segment register,
	 * as recorded in the proper bits of the override byte (no shifting
	 * required -- they must have re-used the microcode and logic for
	 * extracting the Reg field from the ModRM byte...). The exceptions
	 * are, of course, FS and GS.
	 */
	*ip++ = 0x8c;
	segreg = res2.data.ea.override;
	if (segreg >= OVERRIDE(REG_FS))
	    segreg = (segreg - 0x60) << MR_REG_SHIFT;
	else
	    segreg &= MR_SEGREG_MASK;
	ip = CodeStoreEA(ip,
			 res1.data.ea.modrm,
			 segreg,
			 res1.data.ea.dword_ea,
			 res1.data.ea.sib,
			 res1.data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);
    } else  if (res2.type == EXPR_TYPE_CONST) {
	if ((res1.data.ea.modrm & MR_DISP_MASK) == MR_REG) {
	    /*
	     * Move immediate to register has two sets of encodings, one for
	     * (d)word registers and one for byte registers.
	     */
	    fixAddr = (*addrPtr) + 1;
	    fixRes = &res2;
	    if (USE_386() && OPSIZE_NEEDS_PRE_OPERAND(opSize)) {
		*ip++ = PRE_OPERAND;
		fixAddr++;
	    }
	    *ip++ = 0xb0 + (notByte ? 8 : 0) + (res1.data.ea.modrm & MR_RM_MASK);
	    *ip++ = (byte)res2.data.number;
	    if (notByte) {
		*ip++ = (byte)(res2.data.number >> 8);
		if (isDWord) {
		    *ip++ = (byte)(res2.data.number >> 16);
		    *ip++ = (byte)(res2.data.number >> 24);
		}
	    }
	} else {
	    /*
	     * MOV m,d is encoded c6 /0
	     */
	    fixAddr = (*addrPtr) + 2;
	    fixRes = &res1;
	    if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res1)) {
		*ip++ = PRE_ADDRESS;
		fixAddr++;
	    }
	    if (USE_386() && preOperand) {
		*ip++ = PRE_OPERAND;
		fixAddr++;
	    }
	    if (EXPR_NEEDS_OVERRIDE(&res1)) {
		*ip++ = res1.data.ea.override;
		fixAddr += 1;
	    }

	    *ip++ = 0xc6 + notByte;
	    ip = CodeStoreEA(ip,
			     res1.data.ea.modrm,
			     0 << MR_REG_SHIFT,
			     res1.data.ea.dword_ea,
			     res1.data.ea.sib,
			     res1.data.ea.disp,
			     prevSize,
			     (ip-ibuf) + (1+notByte),
			     pass, &fixAddr);
	    if (res2.rel.sym) {
		/*
		 * Oy. Constant relocatable, too...
		 */
		Fix_Enter(&res2, (*addrPtr)+(ip-ibuf), *addrPtr);
	    }
	    *ip++ = (byte)res2.data.number;
	    if (notByte) {
		*ip++ = (byte)(res2.data.number >> 8);
		if (isDWord) {
		    *ip++ = (byte)(res2.data.number >> 16);
		    *ip++ = (byte)(res2.data.number >> 24);
		}
	    }
	}
    } else if ((res1.data.ea.modrm == (MR_REG | REG_AX)) &&
	       ((!(res2.data.ea.dword_ea) && res2.data.ea.modrm == MR_DIRECT) ||
		((res2.data.ea.dword_ea) && res2.data.ea.modrm == MR_DIRECT32)))
    {
	/*
	 * Move from static variable to AL/AX/EAX.
	 */
	fixAddr = (*addrPtr) + 1;
	fixRes = &res2;
	if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res2)) {
	    *ip++ = PRE_ADDRESS;
	    fixAddr++;
	}
	if (USE_386() && preOperand) {
	    *ip++ = PRE_OPERAND;
	    fixAddr++;
	}
	if (EXPR_NEEDS_OVERRIDE(&res2)) {
	    *ip++ = res2.data.ea.override;
	    fixAddr += 1;
	}

	*ip++ = 0xa0 + notByte;
	*ip++ = (byte)res2.data.ea.disp;
	*ip++ = (byte)(res2.data.ea.disp >> 8);
	if (isDWord) {
	    *ip++ = (byte)(res2.data.number >> 16);
	    *ip++ = (byte)(res2.data.number >> 24);
	}
    } else if (((!(res1.data.ea.dword_ea) && res1.data.ea.modrm == MR_DIRECT) ||
		((res1.data.ea.dword_ea) && res1.data.ea.modrm == MR_DIRECT32)) &&
	       (res2.data.ea.modrm == (MR_REG | REG_AX)))
    {
	/*
	 * Move from AL/AX/EAX to static variable
	 */
	fixAddr = (*addrPtr) + 1;
	fixRes = &res1;
	if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res1)) {
	    *ip++ = PRE_ADDRESS;
	    fixAddr++;
	}
	if (USE_386() && preOperand) {
	    *ip++ = PRE_OPERAND;
	    fixAddr++;
	}
	if (EXPR_NEEDS_OVERRIDE(&res1)) {
	    *ip++ = res1.data.ea.override;
	    fixAddr += 1;
	}

	*ip++ = 0xa2 + notByte;
	*ip++ = (byte)res1.data.ea.disp;
	*ip++ = (byte)(res1.data.ea.disp >> 8);
	if (isDWord) {
	    *ip++ = (byte)(res1.data.number >> 16);
	    *ip++ = (byte)(res1.data.number >> 24);
	}
    } else if ((res1.data.ea.modrm & MR_DISP_MASK) == MR_REG) {
	/*
	 * MOV rx,ex
	 */
	if (res1.data.ea.modrm == res2.data.ea.modrm) {
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "mov from a register to itself is normally considered useless");
	}
	fixAddr = (*addrPtr) + 2;
	fixRes = &res2;
	if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res2)) {
	    *ip++ = PRE_ADDRESS;
	    fixAddr++;
	}
	if (USE_386() && preOperand) {
	    *ip++ = PRE_OPERAND;
	    fixAddr++;
	}
	if (EXPR_NEEDS_OVERRIDE(&res2)) {
	    *ip++ = res2.data.ea.override;
	    fixAddr += 1;
	}

	*ip++ = 0x8a + notByte;
	ip = CodeStoreEA(ip,
			 res2.data.ea.modrm,
			 (byte)(res1.data.ea.modrm << MR_REG_SHIFT),
			 res2.data.ea.dword_ea,
			 res2.data.ea.sib,
			 res2.data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);
    } else {
	/*
	 * MOV ex,rx
	 */
	fixAddr = (*addrPtr) + 2;
	fixRes = &res1;
	if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res1)) {
	    *ip++ = PRE_ADDRESS;
	    fixAddr++;
	}
	if (USE_386() && preOperand) {
	    *ip++ = PRE_OPERAND;
	    fixAddr++;
	}
	if (EXPR_NEEDS_OVERRIDE(&res1)) {
	    *ip++ = res1.data.ea.override;
	    fixAddr += 1;
	}

	*ip++ = 0x88 + notByte;
	ip = CodeStoreEA(ip,
			 res1.data.ea.modrm,
			 (byte)(res2.data.ea.modrm << MR_REG_SHIFT),
			 res1.data.ea.dword_ea,
			 res1.data.ea.sib,
			 res1.data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);
    }

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, fixRes, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Move,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }


    CodeCleanup(expr1, &res1, expr2, &res2);
    return(FR_DONE);
}


/***********************************************************************
 *				Code_NoArg
 ***********************************************************************
 * SYNOPSIS:	    Handle AAA, AAD, AAM, AAS, CBW, CDQ, CLC, CLD, CMC,
 *		    CMPSB, CMPSD, CMPSW, CWD, CWDE, DAA, DAS, INSB, INSD,
 *                  INSW, INTO, IRET, IRETD, LAHF, LODSB, LODSD, LODSW,
 *                  MOVSB, MOVSD, MOVSW, NOP, OUTSB, OUTSD, OUTSW, POPA,
 *                  POPAD, POPF, POPFD, PUSHA, PUSHAD, PUSHF, PUSHFD,
 *                  SAHF, SCASB, SCASD, SCASW, STC, STD, STOSB, STOSD,
 *                  STOSW, WAIT, XLATB
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *	Warn about STI/CLI
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_NoArg(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    OpCode  	*op = (OpCode *)data;
    byte    	ibuf[3], *ip = ibuf;
    int	    	len = 1;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Deal with instruction restrictions
     */
    switch(op->value) {
	case 0x6e:  case 0x6f:	/* OUTS */
	case 0x6c:  case 0x6d:	/* INS */
	    ASSERT_IO();
	    /*FALLTHRU*/
	case 0x61:  	    	/* POPA/POPAD */
	case 0x60:  	    	/* PUSHA/PUSHAD */
	    ASSERT_186();
	    break;
	case 0xcf:  	    	/* IRET/IRETD */
	    curSeg->u.segment.data->checkLabel = TRUE;
	    break;
    }
    if (op->token == NOARGD || op->token == NASTRGD)
    {
	ASSERT_386();
	if (DWORD_OPER_NEEDS_PREFIX())
	    *ip++ = PRE_OPERAND;
    }
    else if (op->token == NOARGW || op->token == NASTRGW)
    {
	if (USE_386() && WORD_OPER_NEEDS_PREFIX())
	    *ip++ = PRE_OPERAND;
    }

    *ip++ = (byte)op->value;
    if (op->value & 0xff00) {
	*ip++ = (byte)(op->value >> 8);
    }

    /*
     * Install the instruction itself.
     */
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, NULL, -1,
	      NullID, 0, 0);

    return(FR_DONE);
}


/***********************************************************************
 *				Code_Outs
 ***********************************************************************
 * SYNOPSIS:	    Handle OUTS with operands
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_OPTIM or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Outs(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);
    ASSERT_186();
    ASSERT_IO();

    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	   "OUTS not supported");

    return(FR_ERROR);
}


/***********************************************************************
 *				Code_Override
 ***********************************************************************
 * SYNOPSIS:	    Store a segment override
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    *addrPtr is advanced
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/28/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Override(int   	*addrPtr,   /* IN/OUT: Address of instruction start */
	      int   	prevSize,
	      int   	pass,
	      Expr  	*expr1,
	      Expr  	*expr2,
	      Opaque	data)
{
    byte    	ibuf[1];
    ExprResult	res;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    if (!Expr_Eval(expr1, &res, EXPR_NOUNDEF|EXPR_FINALIZE, NULL)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line, (char *)res.type);
	return(FR_ERROR);
    } else if (!EXPR_IS_SEGREG(&res)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "Code_Override given a non-segment register operand");
	return(FR_ERROR);
    } else {
	ibuf[0] = res.data.ea.override;

	Table_Store(curSeg->u.segment.code, 1, (void *)ibuf, *addrPtr);

	*addrPtr += 1;
	return(FR_DONE);
    }
}

/***********************************************************************
 *				Code_Pop
 ***********************************************************************
 * SYNOPSIS:	    Handle a POP.
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_OPTIM or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Pop(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[10];
    byte    	*ip = ibuf;
    int	    	fixAddr = -1;
    ExprResult	res1;
    FixResult	result;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required. Default size is 4 b/c anything undefined will be memory
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_Pop, 4, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line,
			    (OpCode *)data);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Typeless things default to WORD always.
     * XXX: Default to dword if code is USE32?
     */
    if (res1.type == NULL) {
	res1.type = Type_Int(2);
    }
    CodeSimplifyType(&res1.type, expr1->file, expr1->line, FALSE);
    if (USE_386()) {
	if (Type_Size(res1.type) != 2 && Type_Size(res1.type) != 4) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "operand of POP must be a word or dword");
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}
    } else {
	if (Type_Size(res1.type) != 2) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "operand of POP must be a word");
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}
    }

    if (EXPR_IS_SEGREG(&res1)) {
	if (res1.data.ea.override == OVERRIDE(REG_CS)) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "can't POP CS");
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}
	if (res1.data.ea.override < 0x64)
	    *ip++ = 0x07 + (res1.data.ea.override & MR_SEGREG_MASK);
	else {
	    *ip++ = 0x0F;
	    *ip++ = 0xA1 + (((byte)(res1.data.ea.override - 0x64)) << 3);
	}
    } else if ((res1.data.ea.modrm & MR_DISP_MASK) == MR_REG) {
	if (EXPR_NEEDS_PRE_OPERAND(&res1))
	    *ip++ = PRE_OPERAND;
	*ip++ = 0x58 + (res1.data.ea.modrm & MR_RM_MASK);
    } else {
	fixAddr = (*addrPtr) + 2;
	if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res1)) {
	    *ip++ = PRE_ADDRESS;
	    fixAddr += 1;
	}
	if (USE_386() && EXPR_NEEDS_PRE_OPERAND(&res1)) {
	    *ip++ = PRE_OPERAND;
	    fixAddr += 1;
	}
	if (EXPR_NEEDS_OVERRIDE(&res1)) {
	    *ip++ = res1.data.ea.override;
	    fixAddr += 1;
	}
	*ip++ = 0x8f;
	ip = CodeStoreEA(ip,
			 res1.data.ea.modrm,
			 0 << MR_REG_SHIFT,
			 res1.data.ea.dword_ea,
			 res1.data.ea.sib,
			 res1.data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);
    }
    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Pop,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }


    CodeCleanup(expr1, &res1, NULL, NULL);
    return(FR_DONE);
}


/***********************************************************************
 *				Code_Push
 ***********************************************************************
 * SYNOPSIS:	    Handle a PUSH
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Push(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[10];
    byte    	*ip = ibuf;
    int	    	fixAddr = -1;
    ExprResult	res1;
    FixResult	result;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required. Default size is 4 b/c anything undefined will be memory
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_Push, 4, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    if (RES_IS_CONST(res1.type)) {
	ASSERT_186();
	if (res1.type == EXPR_TYPE_STRING) {
	    (void)CodeMangleString(expr1, expr2, &res1, Type_Int(2),
				   expr1->file, expr1->line);
	}
	if (res1.rel.sym) {
	    /*
	     * If relocatable, must use a word.
	     */
	    fixAddr = (*addrPtr)+1;
	    if (USE_386() && WORD_OPER_NEEDS_PREFIX()) {
		*ip++ = PRE_OPERAND;
		fixAddr ++;
	    }
	    *ip++ = 0x68;
	    *ip++ = (byte)res1.data.number;
	    *ip++ = (byte)(res1.data.number >> 8);
	} else if (res1.data.number >= -128 && res1.data.number <= 127) {
	    /*
	     * Push sign-extended byte: 6a db
	     */
	    *ip++ = 0x6a;
	    *ip++ = (byte)res1.data.number;
	} else if (res1.data.number >= -65536 && res1.data.number <= 65535) {
	    /*
	     * Push immediate word: 68 dw
	     * XXX: Use immediate dword if code is USE32 to avoid prefix?
	     */
	    if (USE_386() && WORD_OPER_NEEDS_PREFIX())
		*ip++ = PRE_OPERAND;
	    *ip++ = 0x68;
	    *ip++ = (byte)res1.data.number;
	    *ip++ = (byte)(res1.data.number >> 8);
	} else {
	    /*
	     * (386) Push immediate dword: 68 dw
	     */
	    ASSERT_386();
	    if (DWORD_OPER_NEEDS_PREFIX())
		*ip++ = PRE_OPERAND;
	    *ip++ = 0x68;
	    *ip++ = (byte)res1.data.number;
	    *ip++ = (byte)(res1.data.number >> 8);
	    *ip++ = (byte)(res1.data.number >> 16);
	    *ip++ = (byte)(res1.data.number >> 24);
	}
    } else {
	/*
	 * Typeless things default to WORD always.
	 * XXX: Default to dword if code is USE32?
	 */
	if (res1.type == NULL) {
	    res1.type = Type_Int(2);
	}
	CodeSimplifyType(&res1.type, expr1->file, expr1->line, FALSE);
	if (USE_386()) {
	    if (Type_Size(res1.type) != 2 && Type_Size(res1.type) != 4) {
		Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "operand of PUSH must be a word or dword");
		CodeCleanup(expr1, &res1, NULL, NULL);
		return(FR_ERROR);
	    }
	} else {
	    if (Type_Size(res1.type) != 2) {
		Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "operand of PUSH must be a word");
		CodeCleanup(expr1, &res1, NULL, NULL);
		return(FR_ERROR);
	    }
	}

	if (EXPR_IS_SEGREG(&res1)) {
	    if (res1.data.ea.override < 0x64)
		*ip++ = 0x06 + (res1.data.ea.override & MR_SEGREG_MASK);
	    else {
		*ip++ = 0x0F;
		*ip++ = 0xA0 + (((byte)(res1.data.ea.override - 0x64)) << 3);
	    }
	} else if ((res1.data.ea.modrm & MR_DISP_MASK) == MR_REG) {
	    int reg = res1.data.ea.modrm & MR_RM_MASK;

	    if (EXPR_NEEDS_PRE_OPERAND(&res1))
		*ip++ = PRE_OPERAND;
	    *ip++ = 0x50 + (reg);
	    if (reg == REG_SP) {
		Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		       "PUSH SP yields different values on different processors");
	    }
	} else {
	    fixAddr = (*addrPtr) + 2;

	    if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res1)) {
		*ip++ = PRE_ADDRESS;
		fixAddr += 1;
	    }
	    if (USE_386() && EXPR_NEEDS_PRE_OPERAND(&res1)) {
		*ip++ = PRE_OPERAND;
		fixAddr += 1;
	    }
	    if (EXPR_NEEDS_OVERRIDE(&res1)) {
		*ip++ = res1.data.ea.override;
		fixAddr += 1;
	    }
	    *ip++ = 0xff;
	    ip = CodeStoreEA(ip,
			     res1.data.ea.modrm,
			     6 << MR_REG_SHIFT,
			     res1.data.ea.dword_ea,
			     res1.data.ea.sib,
			     res1.data.ea.disp,
			     prevSize, ip-ibuf,
			     pass, &fixAddr);
	}
    }

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Push,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }


    CodeCleanup(expr1, &res1, NULL, NULL);
    return(FR_DONE);
}


/***********************************************************************
 *				Code_PWord
 ***********************************************************************
 * SYNOPSIS:	    Handle LLDT, SLDT, LTR, STR, LMSW, SMSW, VERR and VERW
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_PWord(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[7];    	/* 2 opcode + override + modrm + 2 disp */
    byte    	*ip = ibuf;
    ExprResult	res1;
    FixResult	result;
    OpCode  	*op = (OpCode *)data;
    int	    	fixAddr;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);
    ASSERT_PROT();

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_PWord, 2, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line,
			    (OpCode *)data);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure operand isn't a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "%s can't operate on a segment register", op->name);
	CodeCleanup(expr1, &res1, NULL, NULL);
	return(FR_ERROR);
    }

    fixAddr = (*addrPtr)+3;
    if (EXPR_NEEDS_OVERRIDE(&res1)) {
	*ip++ = res1.data.ea.override;
	fixAddr++;
    }

    /*
     * The first byte of the opcode is always 0f. The second and the reg field
     * of the modrm byte are contained in op->value, in that order.
     */
    *ip++ = 0x0f;
    *ip++ = (byte)op->value;
    ip = CodeStoreEA(ip,
		     res1.data.ea.modrm,
		     (byte)(op->value >> 8),
		     res1.data.ea.dword_ea,
		     res1.data.ea.sib,
		     res1.data.ea.disp,
		     prevSize, ip-ibuf,
		     pass, &fixAddr);

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_PWord,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }


    CodeCleanup(expr1, &res1, NULL, NULL);
    return(FR_DONE);
}


/***********************************************************************
 *				Code_Rep
 ***********************************************************************
 * SYNOPSIS:	    Deal with REP, REPE, REPNE, REPZ and REPNZ
 * CALLED BY:	    yyparse, Fixup
 * RETURN:	    FR_DONE or FR_ERROR
 * SIDE EFFECTS:    An FC_FINAL fixup is registered in pass 1
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/29/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Rep(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    if (pass == 1) {
	/*
	 * First pass -- store the prefix and register an FC_FINAL fixup
	 */
	byte	ibuf[1];

	ibuf[0] = ((OpCode *)data)->value;

	Table_Store(curSeg->u.segment.code, 1, (void *)ibuf, *addrPtr);

	Fix_Register(FC_FINAL, Code_Rep, *addrPtr, 1, expr1, NULL, data);

	*addrPtr += 1;
    } else {
	/*
	 * Make sure the stored instruction matches the prefix.
	 */
	byte	ibuf[1];
	int 	addr;
	char	*cp;
	OpCode	*op = (OpCode *)data;

	/*
	 * Skip over segment overrides and prefixes...
	 */
	addr = *addrPtr;
	do {
	    addr++;
	    Table_Fetch(curSeg->u.segment.code, 1, (void *)ibuf, addr);
	} while ((ibuf[0] & 0xe7) == 0x26 || (ibuf[0] & 0xfc) == 0x64);

	/*
	 * Update address so caller doesn't think we shrank or grew...
	 */
	*addrPtr += 1;

	/*
	 * Point cp at trailing char so we know what type of REP prefix this is
	 */
	cp = op->name + strlen(op->name) - 1;

	switch (*cp) {
	    case 'e':
	    case 'z':
		/*
		 * REPE or REPNE or REPZ or REPNZ
		 */
		switch(ibuf[0]) {
		    case 0xa6: case 0xa7:   /* CMPS */
		    case 0xae: case 0xaf:   /* SCAS */
			break;
		    default:
			Notify(NOTIFY_ERROR, expr1->file, expr1->line,
			       "%s may only be used with CMPS or SCAS",
			       op->name);
			return(FR_ERROR);
		}
		break;
	    default:
		switch(ibuf[0]) {
		    case 0x6c: case 0x6d:   /* INS */
		    case 0xa4: case 0xa5:   /* MOVS */
		    case 0x6e: case 0x6f:   /* OUTS */
		    case 0xaa: case 0xab:   /* STOS */
			break;
		    default:
			Notify(NOTIFY_ERROR, expr1->file, expr1->line,
			       "REP may only be used with INS, MOVS, OUTS or STOS");
			return(FR_ERROR);
		}
	}

    }
    return(FR_DONE);
}


/***********************************************************************
 *				Code_Ret
 ***********************************************************************
 * SYNOPSIS:	    Handle a RET, RETN or RETF
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_UNDEF or FR_DONE
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/29/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Ret(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 (non-zero if opcode should be
				 * converted to a FAR return) */
      Opaque	data)	    	/* OpCode */
{
    ExprResult	res1;
    OpCode  	*op = (OpCode *)data;
    byte    	ibuf[2];    	/* opcode, count*/
    byte    	*ip = ibuf;
    byte    	opcode;
    byte    	stat1;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    opcode = op->value;

    if (expr2) {
	/*
	 * OpCode should be converted to FAR return. This is accomplished
	 * by adding 8, since c3 is a near return and cb is a far (c2 is
	 * near when popping things and ca is far)
	 */
	opcode += 8;
    }

    if (expr1) {
	/*
	 * Return, popping bytes of the stack -- final opcode needs to
	 * have 1 subtracted from it...
	 */
	opcode -= 1;

	/*
	 * Evaluate arg w/o allowing undefined symbols. The problem is our
	 * expr2 isn't a real expression, so we can't do the regular
	 * fixup thing, so we disallow forward references for RET
	 * instructions. Not exactly a major restriction...
	 */
	if (!Expr_Eval(expr1, &res1, EXPR_NOUNDEF, &stat1)) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line, (char *)res1.type);
	    return(FR_ERROR);
	}
	if (res1.type != EXPR_TYPE_CONST) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "operand of %s must be numeric constant", op->name);
	    return(FR_ERROR);
	}
	/*
	 * If result should be delayed, tell user we can't do it, then
	 * re-evaluate the expression, ignoring such things.
	 */
	if (stat1 & EXPR_STAT_DELAY) {
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "ret cannot handle difference between symbols well");
	    (void)Expr_Eval(expr1, &res1, EXPR_NOUNDEF|EXPR_FINALIZE, &stat1);
	}

	*ip++ = opcode;
	*ip++ = (byte)res1.data.number;
	*ip++ = (byte)(res1.data.number >> 8);
    } else {
	*ip++ = opcode;
    }

    /*
     * Install the instruction itself.
     */
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, -1,
	      expr1 ? expr1->file : NullID,
	      expr1 ? expr1->line : 0, 0);

    curSeg->u.segment.data->checkLabel = TRUE;

    return(FR_DONE);
}


/***********************************************************************
 *				Code_String
 ***********************************************************************
 * SYNOPSIS:	    Handle all unsized string instructions
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *	This one's a little different from all the other code generators,
 *	in that it takes its operands a little differently. It can take
 *	one or two operands, depending on the instruction.
 *
 *	If expr1 is given, it is used to figure the size of the operand,
 *	and any segment override generates an error.
 *
 *	If expr2 is given, it is used to figure the size of the operand
 *	and any segment override is stored before the opcode.
 *
 *	If both expr1 and expr2 are given, they are checked for size-
 *	compatibility and any segment override for expr2 is accepted and
 *	stored. An override for expr1 generates an error.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_String(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    ExprResult	res1, res2;
    OpCode  	*op = (OpCode *)data;
    byte    	ibuf[2];    	/* override, opcode */
    byte    	*ip = ibuf;
    int	    	opSize;
    FixResult	result;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    if (expr1 && expr2) {
	ExprResult  *r1, *r2;

	if (op->name[0] == 'c') {
	    /* CMPS -- takes operands ass-backwards */
	    r1 = &res2; r2 = &res1;
	} else {
	    r1 = &res1; r2 = &res2;
	}

	/*
	 * Handle undefined symbols
	 */
	result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			     Code_String, 2, data, &delay);
	if (result != FR_DONE) {
	    return(result);
	}
	/*
	 * Weed out constants
	 */
	result = CodeNoConstant(expr1, &res1, expr2, &res2, expr1->file, expr1->line,
				op);
	if (result != FR_DONE) {
	    return(result);
	}
	/*
	 * Make sure operands are compatible
	 */
	if (!CodeCompatible(expr1, &res1, expr2, &res2,
			    FALSE, TRUE, delay, &opSize))
	{
	    return(FR_ERROR);
	}
	/*
	 * Make sure dest has no override but es:
	 */
	if (r1->data.ea.override != OVERRIDE(REG_ES)) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "ES override required (or use abbreviated form)");
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_ERROR);
	}
	/*
	 * The User Is Stupid checks
	 */
	if (r1->data.ea.modrm != MR_DIRECT && r1->data.ea.modrm != MR_DI){
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "%s only stores into ES:[DI]", op->name);
	}
	if (r2->data.ea.modrm != MR_DIRECT && r2->data.ea.modrm != MR_SI){
	    Notify(NOTIFY_WARNING, expr2->file, expr2->line,
		   "%s only reads from DS:[SI] (segment override possible)",
		   op->name);
	}
	/*
	 * Store the instruction now we know the operand size (check against
	 * OVERRIDE(REG_DS) guards against idiot doing
	 *  	movs	word ptr es:[di], word ptr ds:[bp]
	 */
	if (EXPR_NEEDS_OVERRIDE(r2) &&
	    (r2->data.ea.override != OVERRIDE(REG_DS)))
	{
	    *ip++ = r2->data.ea.override;
	}
	*ip++ = (byte)(op->value + (opSize == 2 ? 1 : 0));
    } else if (expr1) {
	/*
	 * Can't override, but need size...
	 */
	/*
	 * Handle undefined symbols
	 */
	result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			     Code_String, 1, data, &delay);
	if (result != FR_DONE) {
	    return(result);
	}
	/*
	 * Weed out constants
	 */
	result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line,
				op);
	if (result != FR_DONE) {
	    return(result);
	}
	if (res1.data.ea.override != OVERRIDE(REG_ES)) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "ES override required (or use abbreviated form)");
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_ERROR);
	}
	if (res1.data.ea.modrm != MR_DIRECT && res1.data.ea.modrm != MR_DI){
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "%s only uses ES:[DI]", op->name);
	}

	CodeSimplifyType(&res1.type, expr1->file, expr1->line, TRUE);
	/*
	 * Store the instruction...
	 */
	*ip++ = (byte)(op->value + (Type_Size(res1.type) == 2 ? 1 : 0));
    } else if (expr2) {
	int 	opsize;

	/*
	 * Handle undefined symbols
	 */
	result = CodeInitial(addrPtr, pass, NULL, NULL, expr2, &res2,
			     Code_String, 2, data, &delay);
	if (result != FR_DONE) {
	    return(result);
	}
	/*
	 * Weed out constants
	 */
	result = CodeNoConstant(expr1, &res2, NULL, NULL, expr2->file, expr2->line,
				op);
	if (result != FR_DONE) {
	    return(result);
	}

	if (res2.data.ea.modrm != MR_DIRECT) {
	    if ((byte)op->value == 0xd7) {
		/* XLAT instruction -- must read from [bx] */
		if (res2.data.ea.modrm != MR_BX) {
		    Notify(NOTIFY_WARNING, expr2->file, expr2->line,
			   "%s only reads from DS:[BX] (segment override possible)",
			   op->name);
		}
	    } else if (res2.data.ea.modrm != MR_SI) {
		/* Anything else is string instruction that's not using [si] */
		Notify(NOTIFY_WARNING, expr2->file, expr2->line,
		       "%s only reads from DS:[SI] (segment override possible)",
		       op->name);
	    }
	}
	/*
	 * Store the instruction now we know the operand size (check against
	 * OVERRIDE(REG_DS) guards against idiot doing
	 *  	lods	word ptr ds:[bp]
	 */
	if (EXPR_NEEDS_OVERRIDE(&res2) &&
	    (res2.data.ea.override != OVERRIDE(REG_DS)))
	{
	    *ip++ = res2.data.ea.override;
	}
	/*
	 * Simplify the operand type so we know which instruction to generate.
	 * We only warn the user of any assumptions we had to make if the
	 * instruction isn't XLAT, which always works on bytes.
	 */
	CodeSimplifyType(&res2.type, expr2->file, expr2->line,
			 (op->value != 0xd7));

	opsize = Type_Size(res2.type);

	if (op->value == 0xd7) {
	    if (opsize > 1) {
		Notify(NOTIFY_WARNING, expr2->file, expr2->line,
		       "XLAT operates only on a table of bytes, while the given operand is made of %d-byte values",
		       opsize);
		opsize = 1;
	    }
	}

	*ip++ = (byte)(op->value + (opsize == 2 ? 1 : 0));
    }
    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, -1,
	      expr1 ? expr1->file : (expr2 ? expr2->file : NullID),
	      expr1 ? expr1->line : (expr2 ? expr2->line : 0), delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_String,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }

    CodeCleanup(expr1, &res1, expr2, &res2);
    return(FR_DONE);
}


/***********************************************************************
 *				Code_Shift
 ***********************************************************************
 * SYNOPSIS:	    Handle SAL, SAR, SHL, SHR, ROL, ROR, RCL, and RCR
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Shift(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[11];    	/* override + prefixes + opcode + modrm
				 * + sib + 4 disp + db */
    byte    	*ip = ibuf;
    ExprResult	res1, res2;
    FixResult	result;
    OpCode  	*op = (OpCode *)data;
    int	    	fixAddr = -1;
    word    	opcode;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 Code_Shift, 2, data, &delay);

    if (result != FR_DONE) {
	return(result);
    }

    if (RES_IS_CONST(res1.type)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "can't shift a constant");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    /*
     * Make sure neither operand is a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1) || EXPR_IS_SEGREG(&res2)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "%s can't operate on a segment register", op->name);
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    if (res2.type == EXPR_TYPE_CONST) {
	if (res2.data.number == 1) {
	    opcode = op->value;
	} else {
	    /*
	     * Shift-by-constant encoded as c0 /n, not d0 /n
	     */
	    ASSERT_186();
	    opcode = op->value & ~0x0010;
	}
    } else if (res2.type == EXPR_TYPE_STRING) {
	Notify(NOTIFY_ERROR, expr2->file, expr2->line,
	       "shift by '%s'?", res2.data.str);
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    } else if ((Type_Size(res2.type) != 1) ||
	       (res2.data.ea.modrm != (MR_REG|REG_CL)))
    {
	if (procType & PROC_80186) {
	    Notify(NOTIFY_ERROR, expr2->file, expr2->line,
		   "can only shift by CL or a constant");
	} else {
	    Notify(NOTIFY_ERROR, expr2->file, expr2->line,
		   "can only shift by 1 or CL");
	}
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    } else {
	/*
	 * Shift-by-CL encoded as d2 /n, not d0 /n
	 */
	opcode = op->value + 0x0002;
    }

    fixAddr = (*addrPtr) + 2;
    if (EXPR_NEEDS_OVERRIDE(&res1)) {
	*ip++ = res1.data.ea.override;
	fixAddr += 1;
    }
    if (USE_386() && EXPR_NEEDS_PRE_ADDRESS(&res1)) {
	*ip++ = PRE_ADDRESS;
	fixAddr++;
    }
    if (USE_386() && EXPR_NEEDS_PRE_OPERAND(&res1)) {
	*ip++ = PRE_OPERAND;
	fixAddr++;
    }

    CodeSimplifyType(&res1.type, expr1->file, expr1->line, TRUE);

    *ip++ = (byte)(opcode + (Type_Size(res1.type) != 1 ? 1 : 0));
    ip = CodeStoreEA(ip,
		     res1.data.ea.modrm,
		     (byte)(opcode >> 8),
		     res1.data.ea.dword_ea,
		     res1.data.ea.sib,
		     res1.data.ea.disp,
		     prevSize, (ip-ibuf) + (((opcode & 0x0010)==0) ? 1 : 0),
		     pass, &fixAddr);
    /*
     * If shift-by-constant, store constant...
     */
    if ((opcode & 0x0010) == 0) {
	*ip++ = (byte)(res2.data.number);
    }

    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Shift,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }


    CodeCleanup(expr1, &res1, expr2, &res2);
    return(FR_DONE);
}


/***********************************************************************
 *				Code_Test
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, FR_OPTIM or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Test(int	    *addrPtr,	/* IN/OUT: Address of instruction start */
	  int  	    prevSize,  	/* # bytes previously allocated to inst */
	  int  	    pass,	/* Current pass */
	  Expr 	    *expr1,    	/* Operand 1 */
	  Expr 	    *expr2,    	/* Operand 2 */
	  Opaque    data)   	/* OpCode/other data */
{
    byte    	ibuf[7];    	/* override + opcode + modrm + 2 disp + dw */
    byte    	*ip = ibuf;
    ExprResult	res1, res2;
    FixResult	result;
    int	    	fixAddr;
    ExprResult	*fixRes;
    int	    	opSize;
    int	    	notByte;    	/* 0 if opSize is 1, 1 if not -- used
				 * when forming opcodes */
    int		isDWord;	/* 1 if opSize is 4, 0 if not */
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 Code_Test, 4, data, &delay);

    if (result != FR_DONE) {
	return(result);
    }

    /*
     * No undefined symbols means the types of the operands are known, so
     * we can type-check.
     */
    if (!CodeCompatible(expr1, &res1, expr2, &res2,
			TRUE, FALSE, delay, &opSize))
    {
	return(FR_ERROR);
    }

    /*
     * Make sure neither operand is a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1) || EXPR_IS_SEGREG(&res2)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "TEST can't operate on a segment register");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    notByte = (opSize == 1) ? 0 : 1;
    isDWord = (opSize == 4) ? 1 : 0;

    fixAddr = (*addrPtr) + 2;

    if (res2.type == EXPR_TYPE_CONST) {
	/*
	 * Optimize word test to byte test if possible.
	 */
	if (notByte && !isDWord &&
	    (((res2.data.number & 0xff00) == 0) ||
	     ((res2.data.number & 0x00ff) == 0)))
	{
	    /*
	     * If the operand size is a word and either byte of the mask
	     * is zero, it implies we can use a byte instruction anyway,
	     * as the bits in the high or low byte are insignificant.
	     */
	    if ((res1.data.ea.modrm & MR_DISP_MASK) == MR_REG) {
		/*
		 * We can only change to a byte form when the first operand
		 * is a register if it is one of the four general registers.
		 */
		if ((res1.data.ea.modrm & MR_RM_MASK) <= REG_BX) {
		    notByte = 0;
		    if ((res2.data.number & 0xff00) != 0) {
			/*
			 * Need to test the high byte -- convert the register
			 * number to the high byte register and shift the
			 * data value down to the low byte.
			 */
			res1.data.ea.modrm |= REG_AH;
			res2.data.number >>= 8;
		    }
		}
	    } else if ((res2.data.number & 0xff00) == 0) {
		/*
		 * Want to test the low byte -- nothing to do except set
		 * notByte to 0 so we only deal with bytes.
		 */
		notByte = 0;
	    } else if (res1.data.ea.modrm == MR_DIRECT) {
		/*
		 * Direct addressing testing the high byte -- up the
		 * displacement by one is all we need to do for the address.
		 * Then we need to indicate it's a byte instruction and
		 * shift the high byte into the low byte for storage.
		 */
		res1.data.ea.disp += 1;
		res2.data.number >>= 8;
		notByte = 0;
	    } else {
		switch(res1.data.ea.modrm & MR_DISP_MASK) {
		    case MR_NULL_DISP:
			/*
			 * For an 8088, having a byte displacement is no
			 * worse than fetching the extra byte from memory.
			 * In fact, it can be better as the displacement
			 * is likely to be in the prefetch queue. On a
			 * better processor, it's better to fetch the byte
			 * displacement from the prefetch queue (there's no
			 * penalty for adding it in) than to fetch a
			 * misaligned word. Thus, in general, it's good to
			 * up the thing to a byte-displacement of 1.
			 */
			res1.data.ea.modrm &= ~MR_DISP_MASK;
			res1.data.ea.modrm |= MR_BYTE_DISP;
			res1.data.ea.disp = 1;
			break;
		    case MR_BYTE_DISP:
			if (res1.data.ea.disp == 127) {
			    /*
			     * Need to up the displacement size to a word
			     * as 128 can't fit in a signed byte.
			     */
			    res1.data.ea.modrm &= ~MR_DISP_MASK;
			    res1.data.ea.modrm |= MR_WORD_DISP;
			}
			/*FALLTHRU*/
		    case MR_WORD_DISP:
			res1.data.ea.disp += 1;
			break;
		}
		/*
		 * Shift high byte into position for the test.
		 */
		res2.data.number >>= 8;
		/*
		 * Note that we're dealing with a byte...
		 */
		notByte = 0;
	    }
	}

	fixRes = &res1;
	if (res1.data.ea.modrm == (MR_REG|REG_AX)) {
	    /*
	     * Special TEST a, d encoding: a[89] d[bwd]
	     */
	    *ip++ = 0xa8 + notByte;
	} else {
	    /*
	     * Test e, d encoded f[67] /0 d[bwd]
	     */
	    if (EXPR_NEEDS_OVERRIDE(&res1)) {
		*ip++ = res1.data.ea.override;
		fixAddr += 1;
	    }
	    *ip++ = 0xf6 + notByte;
	    ip = CodeStoreEA(ip,
			     res1.data.ea.modrm,
			     0 << MR_REG_SHIFT,
			     res1.data.ea.dword_ea,
			     res1.data.ea.sib,
			     res1.data.ea.disp,
			     prevSize, (ip-ibuf)+(1+notByte),
			     pass, &fixAddr);
	}
	*ip++ = (byte)res2.data.number;
	if (notByte) {
	    *ip++ = (byte)(res2.data.number >> 8);
	    if (isDWord) {
		*ip++ = (byte)(res2.data.number >> 16);
		*ip++ = (byte)(res2.data.number >> 24);
	    }
	}
    } else {
	ExprResult  *regRes;

	if ((res1.data.ea.modrm & MR_DISP_MASK) == MR_REG) {
	    regRes = &res1;
	    fixRes = &res2;
	} else {
	    regRes = &res2;
	    fixRes = &res1;
	}

	if (EXPR_NEEDS_OVERRIDE(fixRes)) {
	    *ip++ = fixRes->data.ea.override;
	    fixAddr += 1;
	}

	*ip++ = 0x84 + notByte;
	ip = CodeStoreEA(ip,
			 fixRes->data.ea.modrm,
			 (byte)(regRes->data.ea.modrm << MR_REG_SHIFT),
			 fixRes->data.ea.dword_ea,
			 fixRes->data.ea.sib,
			 fixRes->data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);
    }

    /*
     * Finish off instruction.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, fixRes, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Test,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }


    /*
     * This instruction is complete
     */
    CodeCleanup(expr1, &res1, expr2, &res2);
    return(FR_DONE);

}


/***********************************************************************
 *				Code_IncDec
 ***********************************************************************
 * SYNOPSIS:	    Handle INC and DEC
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *	Similar to Code_Group1 with the added wrinkle of handling inc/dec
 *	of word registers specially (op + rw). The opcode to use for this
 *	is in op->value.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_IncDec(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[5];    	/* override, opcode, modrm, 2 disp */
    byte    	*ip = ibuf;
    ExprResult	res1;
    FixResult	result;
    int	    	fixAddr;
    OpCode  	*op = (OpCode *)data;
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, NULL, NULL,
			 Code_IncDec, 3, data, &delay);
    if (result != FR_DONE) {
	return(result);
    }

    result = CodeNoConstant(expr1, &res1, NULL, NULL, expr1->file, expr1->line,
			    (OpCode *)data);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Make sure operand isn't a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "%s can't operate on a segment register", op->name);
	CodeCleanup(expr1, &res1, NULL, NULL);
	return(FR_ERROR);
    }

    fixAddr = (*addrPtr)+2;
    if (((res1.data.ea.modrm & MR_DISP_MASK) == MR_REG) &&
	(Type_Size(res1.type) == 2))
    {
	/*
	 * Deal with word register stuff
	 */
	*ip++ = op->value + (res1.data.ea.modrm & MR_RM_MASK);
    } else {
	/*
	 * Store override if required
	 */
	if (EXPR_NEEDS_OVERRIDE(&res1)) {
	    *ip++ = res1.data.ea.override;
	    fixAddr += 1;
	}

	CodeSimplifyType(&res1.type, expr1->file, expr1->line, TRUE);
	/*
	 * Install instruction (encoded fe+w /n where /n is the reg field
	 * of the word-register opcode)
	 */
	*ip++ = 0xfe + (Type_Size(res1.type) == 2 ? 1 : 0);
	ip = CodeStoreEA(ip,
			 res1.data.ea.modrm,
			 (byte)(op->value & MR_REG_MASK),
			 res1.data.ea.dword_ea,
			 res1.data.ea.sib,
			 res1.data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);
    }
    /*
     * Install the instruction itself.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, &res1, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, NULL, NULL);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_IncDec,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }


    CodeCleanup(expr1, &res1, NULL, NULL);
    return(FR_DONE);
}


/***********************************************************************
 *				Code_Xchg
 ***********************************************************************
 * SYNOPSIS:	    Handle XCHG
 * CALLED BY:	    yyparse, Fixup module
 * RETURN:	    FR_ERROR, or FR_DONE
 * SIDE EFFECTS:    Code is entered, bytes may be inserted or deleted
 *		    FC_UNDEF fixup may be registered
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/12/89		Initial Revision
 *
 ***********************************************************************/
FixResult
Code_Xchg(int	*addrPtr,	/* IN/OUT: Address of instruction start */
      int   	prevSize,   	/* # bytes previously allocated to inst */
      int   	pass,	    	/* Current pass */
      Expr  	*expr1,	    	/* Operand 1 */
      Expr  	*expr2,	    	/* Operand 2 */
      Opaque	data)	    	/* OpCode/other data */
{
    byte    	ibuf[5];    	/* override + opcode + modrm + 2 disp */
    byte    	*ip = ibuf;
    ExprResult	res1, res2;
    FixResult	result;
    int	    	fixAddr=-1;
    ExprResult	*fixRes, *regRes;
    int	    	opSize;
    int	    	notByte;    	/* 0 if opSize is 1, 1 if not -- used
				 * when forming opcodes */
    int		isDWord;	/* 1 if opSize is 4, 0 if not */
    int	    	delay, startAddr;

    START_CODEGEN(pass, *addrPtr, FR_DONE, FR_ERROR);

    /*
     * Handle initial evaluation and registration of FC_UNDEF fixup as
     * required.
     */
    result = CodeInitial(addrPtr, pass, expr1, &res1, expr2, &res2,
			 Code_Xchg, 4, data, &delay);

    if (result != FR_DONE) {
	return(result);
    }

    /*
     * Can't exchange constants with anything...
     */
    result = CodeNoConstant(expr1, &res1, expr2, &res2, expr1->file, expr1->line,
			    (OpCode *)data);
    if (result != FR_DONE) {
	return(result);
    }

    /*
     * No undefined symbols means the types of the operands are known, so
     * we can type-check.
     */
    if (!CodeCompatible(expr1, &res1, expr2, &res2,
			TRUE, FALSE, delay, &opSize))
    {
	return(FR_ERROR);
    }

    /*
     * Make sure neither operand is a segment register, since we can't
     * use segment registers here.
     */
    if (EXPR_IS_SEGREG(&res1) || EXPR_IS_SEGREG(&res2)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "XCHG can't operate on a segment register");
	CodeCleanup(expr1, &res1, expr2, &res2);
	return(FR_ERROR);
    }

    notByte = (opSize == 1) ? 0 : 1;
    isDWord = (opSize == 4) ? 1 : 0;

    /*
     * Handle special case of exchanging AX with a word register...
     */
    if (((res1.data.ea.modrm & MR_DISP_MASK) == MR_REG) &&
	((res2.data.ea.modrm & MR_DISP_MASK) == MR_REG) &&
	((res1.data.ea.modrm == (MR_REG|REG_AX)) ||
	 (res2.data.ea.modrm == (MR_REG|REG_AX))) &&
	notByte)
    {
	if (res1.data.ea.modrm == (MR_REG|REG_AX)) {
	    *ip++ = 0x90 + (res2.data.ea.modrm & MR_RM_MASK);
	} else {
	    *ip++ = 0x90 + (res1.data.ea.modrm & MR_RM_MASK);
	}
	fixRes = NULL;
    } else {
	fixAddr = (*addrPtr) + 2;

	if ((res1.data.ea.modrm & MR_DISP_MASK) == MR_REG) {
	    regRes = &res1;
	    fixRes = &res2;
	} else {
	    regRes = &res2;
	    fixRes = &res1;
	}

	if (EXPR_NEEDS_OVERRIDE(fixRes)) {
	    *ip++ = fixRes->data.ea.override;
	    fixAddr += 1;
	}

	*ip++ = 0x86 + notByte;
	ip = CodeStoreEA(ip,
			 fixRes->data.ea.modrm,
			 (byte)(regRes->data.ea.modrm << MR_REG_SHIFT),
			 fixRes->data.ea.dword_ea,
			 fixRes->data.ea.sib,
			 fixRes->data.ea.disp,
			 prevSize, ip-ibuf,
			 pass, &fixAddr);
    }

    /*
     * Finish off instruction.
     */
    startAddr = *addrPtr;
    CodeFinal(addrPtr, pass, ip-ibuf, prevSize, ibuf, fixRes, fixAddr,
	      expr1->file, expr1->line, delay);
    if (delay) {
	if (pass > 1) {
	    CodeCleanup(expr1, &res1, expr2, &res2);
	    return(FR_FINAL);
	} else {
	    Fix_Register(FC_FINAL, Code_Xchg,
			 startAddr, ip - ibuf, expr1, expr2, data);
	}
    }


    /*
     * This instruction is complete
     */
    CodeCleanup(expr1, &res1, expr2, &res2);
    return(FR_DONE);
}

/*
 * Opcodes for pushing registers in register-number order.
 */
#define REG_SEGBASE (REG_DI+1)
#define REG_DWFLAGBASE (REG_SEGBASE+REG_GS+1)
static const struct {
    word    push;
    word    pop;
    int	    mask;
} regsave[] = {
    0x50,   0x58,   1L << REG_AX,
    0x51,   0x59,   1L << REG_CX,
    0x52,   0x5a,   1L << REG_DX,
    0x53,   0x5b,   1L << REG_BX,
    0x54,   0x5c,   1L << REG_SP,
    0x55,   0x5d,   1L << REG_BP,
    0x56,   0x5e,   1L << REG_SI,
    0x57,   0x5f,   1L << REG_DI,
    0x06,   0x07,   1L << (REG_SEGBASE+REG_ES),
    0x16,   0x17,   1L << (REG_SEGBASE+REG_SS),
    0x1e,   0x1f,   1L << (REG_SEGBASE+REG_DS),
    0x0fa0, 0x0fa1, 1L << (REG_SEGBASE+REG_FS),
    0x0fa8, 0x0fa9, 1L << (REG_SEGBASE+REG_GS),
};

#define ALL_REG	((1L<<REG_SEGBASE)-1)
#define CAN_PUSHA (procType & (PROC_80186|PROC_80286|PROC_80386|PROC_80486))
#define CAN_PUSHAD (procType & (PROC_80386|PROC_80486))


/***********************************************************************
 *				Code_PrologueSaveFP
 ***********************************************************************
 * SYNOPSIS:	    Save and establish the frame pointer for a frame.
 * CALLED BY:	    parser when first push-initialized local var encountered
 * RETURN:	    nothing
 * SIDE EFFECTS:    fp-setup code is emitted
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/13/90		Initial Revision
 *
 ***********************************************************************/
void
Code_PrologueSaveFP(void)
{
    static byte	fpSetup[] = {
	    0x55,	/* PUSH BP */
	    0x8b,	/* MOV reg, reg */
	    0xec	/* MOV bp, sp */
    };

    START_CODEGEN(1, dot,,);

    Table_Store(curSeg->u.segment.code, sizeof(fpSetup), (void *)fpSetup, dot);
    dot += sizeof(fpSetup);
}


/***********************************************************************
 *				Code_Prologue
 ***********************************************************************
 * SYNOPSIS:	    Generate code for a procedure prologue.
 * CALLED BY:	    yyparse (.enter)
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Code be generated
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 5/89		Initial Revision
 *
 ***********************************************************************/
void
Code_Prologue(int   	frameNeeded,	/* Non-zero if frame-pointer required*/
	      dword   	usesMask,   	/* Mask of registers to push */
	      int   	localSize,  	/* Space to reserve for local
					 * variables */
	      int   	fpSaved)    	/* True if FP already saved */
{
    byte    	ibuf[29];   	/* 7 for frame setup, 22 for all regs */
    byte    	*ip;

    START_CODEGEN(1, dot,,);
    /*
     * Pad the size of local variables out to a word boundary so stack stays
     * word-aligned.
     */
    localSize = (localSize + 1) & ~1;

    ip = ibuf;

    if (frameNeeded) {
	if (!fpSaved) {
	    *ip++ = 0x55;	/* PUSH BP */
	    *ip++ = 0x8b;	/* MOV reg, reg */
	    *ip++ = 0xec;	/* MOV bp, sp */
	}
	/* XXX: Handle 32-bit localSize? */
	if (localSize < 128) {
	    if (localSize != 0) {
		*ip++ = 0x83;	/* ARITH2 w/ sign extend */
		*ip++ = 0xec;	/* SUB from SP */
		*ip++ = localSize;
	    }
	} else {
	    *ip++ = 0x81;   /* ARITH2 word */
	    *ip++ = 0xec;   /* SUB from SP */
	    *ip++ = localSize;
	    *ip++ = localSize >> 8;
	}
	/*
	 * BP saved, so remove it from the usesMask if it's there.
	 */
	usesMask &= ~ (1 << REG_BP);
    }

    if (usesMask) {
	int 	i;
	long 	ignoreMask = 0;
	int	usesAllRegs = !((~usesMask) & (ALL_REG&~(1L<<REG_SP)));

	if (CAN_PUSHAD && usesAllRegs
	    && !((~usesMask) & (ALL_REG<<REG_DWFLAGBASE))) {
	    /*
	     * Wants to save all dword registers and specified machine
	     * type implements PUSHAD, so do it.
	     */
	    if (DWORD_OPER_NEEDS_PREFIX())
		*ip++ = PRE_OPERAND;
	    *ip++ = 0x60;
	    ignoreMask = ALL_REG;
	}

	if (CAN_PUSHA && usesAllRegs
	    && !(usesMask & (ALL_REG<<REG_DWFLAGBASE))) {
	    /*
	     * Wants to save all word registers and specified machine
	     * type implements PUSHA, so do it.
	     */
	    if (WORD_OPER_NEEDS_PREFIX())
		*ip++ = PRE_OPERAND;
	    *ip++ = 0x60;
	    ignoreMask = ALL_REG;
	}

	for (i = 0; i < NumElts(regsave); i++) {
	    if ((usesMask & regsave[i].mask) &&
		!(regsave[i].mask & ignoreMask))
	    {
		if (USE_386()) {
		    int opSize = (usesMask &
			((dword)(regsave[i].mask) << REG_DWFLAGBASE)) ? 4 : 2;
		    if (OPSIZE_NEEDS_PRE_OPERAND(opSize))
			*ip++ = PRE_OPERAND;
		}
		if (regsave[i].push & 0xff00)
		    *ip++ = (byte)(regsave[i].push >> 8);
		*ip++ = (byte)regsave[i].push;
	    }
	}
    }

    if (ip != ibuf) {
	Table_Store(curSeg->u.segment.code, ip-ibuf, (void *)ibuf, dot);

	dot += ip-ibuf;
    }
}

/***********************************************************************
 *				Code_Epilogue
 ***********************************************************************
 * SYNOPSIS:	    Produce the epilogue for a function to clean up
 *	    	    the stack
 * CALLED BY:	    yyparse on DOTLEAVE
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Code be generated, mon.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 5/89		Initial Revision
 *
 ***********************************************************************/
void
Code_Epilogue(int   	frameNeeded,
	      int   	usesMask,
	      int   	localSize)
{
    byte    	ibuf[25];   	/* 22 registers, 3 bytes for sp move & bp pop*/
    byte    	*ip;

    START_CODEGEN(1, dot,,);

    ip = ibuf;

    /*
     * Remove BP from the usesMask if frame was set up (bp saved during
     * setup, after all)...
     */
    if (frameNeeded) {
	usesMask &= ~(1 << REG_BP);
    }

    if (usesMask) {
	/*
	 * Recover the registers in reverse order.
	 */
	int 	i;
	int 	ignoreMask = 0;
	int	usesAllRegs = !((~usesMask) & (ALL_REG&~(1L<<REG_SP)));
	int	popa = 0, popaOpSize;

	if (CAN_PUSHAD && usesAllRegs
	    && !((~usesMask) & (ALL_REG<<REG_DWFLAGBASE))) {
	    /*
	     * Wants to save all dword registers and specified machine
	     * type implements POPAD, so do it.  However, as we initially
	     * did the PUSHA before saving the rest of the REGS, it would
	     * be a good idea to do the POPA after the restoration.
	     * (FIFO and all that other stuff, ya know...)
	     */
	    ignoreMask = ALL_REG;
	    popa = 1;
	    popaOpSize = 4;
	}

	if (CAN_PUSHA && usesAllRegs
	    && !(usesMask & (ALL_REG<<REG_DWFLAGBASE))) {
	    /*
	     * Wants to save all word registers and specified machine
	     * type implements POPA, so do it.
	     */
	    ignoreMask = ALL_REG;
	    popa = 1;
	    popaOpSize = 2;
	}


	for (i = NumElts(regsave)-1; i >= 0; i--) {
	    if ((usesMask & regsave[i].mask) &&
		!(regsave[i].mask & ignoreMask))
	    {
		if (USE_386()) {
		    int opSize = (usesMask &
			((dword)(regsave[i].mask) << REG_DWFLAGBASE)) ? 4 : 2;
		    if (OPSIZE_NEEDS_PRE_OPERAND(opSize))
			*ip++ = PRE_OPERAND;
		}
		if (regsave[i].pop & 0xff00)
		    *ip++ = (byte)(regsave[i].pop >> 8);
		*ip++ = (byte)regsave[i].pop;
	    }
	}

	if (popa) {
	    /*
	     * Now do that there POPA if appropriate...
	     */
	    if (OPSIZE_NEEDS_PRE_OPERAND(popaOpSize))
		*ip++ = PRE_OPERAND;
	    *ip++ = 0x61;
	}
    }

    if (frameNeeded) {
	if (localSize) {
	    /*
	     * Only recover sp from bp if the two differed (i.e. we allocated
	     * room for local variables).
	     */
	    *ip++ = 0x8b;   /* MOV reg, reg */
	    *ip++ = 0xe5;   /* sp, bp */
	}
	*ip++ = 0x5d;	/* POP BP */
    }

    if (ip != ibuf) {
	Table_Store(curSeg->u.segment.code, ip-ibuf, (void *)ibuf, dot);

	dot += ip-ibuf;
    }
}

/***********************************************************************
 *				Code_ProfileBBlock
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    Put out the code:
 *	    	mov cs:foo+1, 11001001b
 *	    foo:
 *	    	mov ax, ax
 *
 *	    2e c6 06 01 00 c9
 *	    89 c0
 *
 *	    In actuality, we set the symbol on the place that gets modified.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/17/93		Initial Revision
 *
 ***********************************************************************/
void
Code_ProfileBBlock(int 	*addrPtr)
{
    ExprResult	    res;
    static byte	    ibuf[8] = {
	0x2e, 0xc6, 0x06, 0x00, 0x00, 0xc9, 0x89, 0xc0
    };

    res.rel.type = FIX_OFFSET;
    res.rel.size = FIX_SIZE_WORD;
    res.rel.pcrel = 0;
    res.rel.fixed = 0;
    res.rel.sym = Sym_Enter(NullID, SYM_PROFILE_MARK, (*addrPtr)+7,
			    SYM_PROF_BBLOCK);
    res.rel.frame = curSeg;
    if (curSeg->segment && curSeg->segment->type == SYM_GROUP) {
	res.rel.frame = curSeg->segment;
    }

    Table_Store(curSeg->u.segment.code, sizeof(ibuf), (void *)ibuf,
		*addrPtr);

    Fix_Enter(&res, (*addrPtr)+3, *addrPtr);

    *addrPtr += sizeof(ibuf);
}
