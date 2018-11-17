/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Expression format definition
 * FILE:	  expr.h
 *
 * AUTHOR:  	  Adam de Boor: Mar  7, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/ 7/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Description of stored expression format.
 *
 *	Expressions are stored in postfix form, except for terminals,
 *	which are stored as the operator followed by the value.
 *
 * 	$Id: expr.h,v 1.21 94/11/16 18:35:09 john Exp $
 *
 ***********************************************************************/
#ifndef _EXPR_H_
#define _EXPR_H_

/*
 * These are required to deal with the mutually-recursive nature of the
 * fixup.h and expr.h include files. They are used only in the
 * Fix_Register and Fix_Enter functions...
 */
typedef struct _Expr	    *FExpr;
typedef struct _ExprResult  *FExprResult;

#include    "fixup.h"
#include    "type.h"

/*
 * Constants for the registers, ordered as the processor orders them...
 * it being the weird thing that it is.
 */
#define REG_EAX	  	0
#define	REG_ECX	  	1
#define	REG_EDX	  	2
#define REG_EBX	  	3
#define REG_ESP	  	4
#define REG_EBP	  	5
#define REG_ESI	  	6
#define	REG_EDI	  	7

#define REG_AX	  	0
#define	REG_CX	  	1
#define	REG_DX	  	2
#define REG_BX	  	3
#define REG_SP	  	4
#define REG_BP	  	5
#define REG_SI	  	6
#define	REG_DI	  	7

#define REG_ES	  	0
#define REG_CS	  	1
#define REG_SS	  	2
#define REG_DS	  	3
#define REG_FS		4
#define REG_GS		5

#define REG_AL	  	0
#define REG_CL	  	1
#define REG_DL	  	2
#define REG_BL	  	3
#define REG_AH	  	4
#define REG_CH	  	5
#define REG_DH	  	6
#define REG_BH	  	7

/*
 * Mod R/M definitions
 */
#define MR_DISP_MASK	0xc0	    /* Displacement portion of Mod R/M byte */
#define MR_DISP_SHIFT	6   	    /* Bits to shift to get DISP part to b0 */
#define MR_REG_MASK 	0x38	    /* Reg portion of Mod R/M byte */
#define MR_REG_SHIFT	3   	    /* Bits to shift to get REG part to b0 */
#define MR_SEGREG_MASK	0x18	    /* Bits in override containing segment
				     * register number */
#define MR_RM_MASK  	0x07	    /* R/M portion of Mod R/M byte */

/*
 * Mod R/M displacement size values
 */
#define MR_NULL_DISP	0x00	    /* Displacement of 0 */
#define MR_BYTE_DISP	0x40	    /* Sign-extended 8-bit displacement */
#define MR_WORD_DISP	0x80	    /* Word displacement */
#define MR_REG	    	0xc0	    /* Register, not memory */

/*
 * Register assignments. Note MR_BP is also MR_DIRECT. [bp] is encoded as
 * MR_BYTE_DISP + MR_BP.
 */
#define MR_BX_SI    	0x00	    /* [bx+si+disp] */
#define MR_BX_DI    	0x01	    /* [bx+di+disp] */
#define MR_BP_SI    	0x02	    /* [bp+si+disp] */
#define MR_BP_DI    	0x03	    /* [bp+di+disp] */
#define MR_SI	    	0x04	    /* [si+disp] */
#define MR_DI	    	0x05	    /* [di+disp] */
#define MR_BP	    	0x06	    /* [bp+disp] */
#define MR_BX	    	0x07	    /* [bx+disp] */

#define MR_DIRECT   	0x06	    /* disp */
#define MR_SEGREG   	0x80	    /* segment register; internal to Esp
				     * only */

/*
 * 32-bit addressing form of the Mod R/M byte.
 *
 * The R/M portion contains the REG_E?X constant, MR_SIB if a SIB byte
 * follows the ModR/M byte, or MR_DIRECT32 if a 32-bit direct address
 * is used (Mod = 00). DWord displacement replaces word displacement.
 */

#define MR_SIB		0x04	    /* s-i-b is present */
#define MR_DIRECT32	0x05	    /* disp */
#define MR_DWORD_DISP	0x80	    /* DWord displacement */

/*
 * SIB (Scale Index Base) byte definitions
 *
 * The SIB byte format has the same bit fields as ModR/M. The index portion
 * (same as R/M) contains the REG_E?X constant or SIB_NO_INDEX for no scaled
 * index. The base portion (same as REG) contains the REG_E?X constant or
 * SIB_NO_BASE for no base (SS = 0).
 *
 * NOTE: If the index portion is SIB_NO_INDEX, then ss must equal SIB_SS_1,
 * otherwise results are undefined.
 */
#define SIB_SS_MASK	0xc0	    /* ss (Scale) portion of SIB byte */
#define SIB_SS_SHIFT	6	    /* Bits to shift to get ss part to b0 */
#define SIB_INDEX_MASK	0x38	    /* index portion of SIB byte */
#define SIB_INDEX_SHIFT	3	    /* Bits to shift to get index part to b0 */
#define SIB_BASE_MASK	0x07	    /* base portion of SIB byte */

#define SIB_NO_INDEX	0x04
#define SIB_NO_BASE	0x05

/*
 * SIB Scaling values
 */
#define SIB_SS_1	0x00
#define SIB_SS_2	0x40
#define SIB_SS_4	0x80
#define SIB_SS_8	0xc0

/*
 * Additional opcode prefixes
 */
#define PRE_OPERAND	0x66	    /* operand-size prefix */
#define PRE_ADDRESS	0x67	    /* address-size prefix */

typedef enum {
    /*
     * Binary operators
     */
    EXPR_PLUS, EXPR_DOT, EXPR_MINUS, EXPR_TIMES, EXPR_DIV, EXPR_OR, EXPR_XOR,
    EXPR_AND, EXPR_SHL, EXPR_SHR, EXPR_MOD, EXPR_EQ, EXPR_NEQ, EXPR_LT,
    EXPR_GT, EXPR_LE, EXPR_GE, EXPR_FMASK,
    /*
     * Unary operators
     */
    EXPR_NEG, EXPR_HIGH, EXPR_LOW, EXPR_TYPEOP, EXPR_NOT, EXPR_LENGTH,
    EXPR_VSEG, EXPR_SEG, EXPR_SEGREGOF, EXPR_OFFSET, EXPR_SIZE, EXPR_DOTTYPE,
    EXPR_WIDTH, EXPR_MASK, EXPR_FIRST, EXPR_HANDLE, EXPR_RESID,
    EXPR_INDIRECT, EXPR_ENUM, EXPR_SUPER, EXPR_OFFPART, EXPR_SEGPART,
    EXPR_LOWPART, EXPR_HIGHPART,
    /*
     * Distance (for jumps, etc.)
     */
    EXPR_SHORT,
    /*
     * Random binary operators
     */
    EXPR_OVERRIDE,  	/* Override op2 with segment op1 (either segment
			 * or EXPR_REGISTER) */
    EXPR_CAST,	    	/* Cast op2 to type op1 */
    /*
     * Terminals. For all these, the data for the operator
     * follow immediately after the operator. E.g.
     *	EXPR_WORDREG, REG_AX
     */
    EXPR_DWORDREG,	/* DWord register (register #) */
    EXPR_WORDREG,  	/* Word register (register #) */
    EXPR_BYTEREG, 	/* Byte register (register #) */
    EXPR_SEGREG,    	/* Segment register (register #) */
    EXPR_EINDREG,	/* Indirect through dword register (register #) */
    EXPR_INDREG,    	/* Indirect through word register (register #) */
    EXPR_SYMOP,	    	/* Symbol (Symbol token) */
    EXPR_CONST,	    	/* Integer constant */
    EXPR_IDENT,	    	/* Pointer to ident in next element */
    EXPR_STRING,    	/* String embedded in following bytes */
    EXPR_INIT,    	/* Structure initializer embedded in following bytes */
    EXPR_TYPE,	    	/* TypePtr in next element */
    EXPR_FLOATSTACK,	/* stack element for coprocessor */
    /*
     * These are used internally by the expression parser...
     */
    EXPR_SEGSYM_ES, 	/* Segment-type symbol attached to ES */
    EXPR_SEGSYM_CS, 	/* Segment-type symbol attached to CS */
    EXPR_SEGSYM_SS, 	/* Segment-type symbol attached to SS */
    EXPR_SEGSYM_DS, 	/* Segment-type symbol attached to DS */
    EXPR_SEGSYM_FS, 	/* Segment-type symbol attached to FS */
    EXPR_SEGSYM_GS, 	/* Segment-type symbol attached to GS */
    /*
     * Special operators.
     */
    EXPR_COMMA,	    	/* Indicates separator between data elements.
			 * Used for default values, etc. Following
			 * element.long is line number at which comma was
			 * seen */
    EXPR_UNDEF,	    	/* Placed at start if identifier undefined when all
			 * source has been read -- allows for fast reject of
			 * erroneous expressions on optimization passes */
} ExprOp;

/*
 * Element of an expression
 */
typedef union {
    ExprOp  	op;   	/* Operator */
    long    	value;	/* EXPR_CONST, EXPR_COMMA value */
    SymbolPtr  	sym;	/* EXPR_SYM value */
    TypePtr 	type;	/* EXPR_TYPE value */
    int	    	reg;	/* EXPR_REGISTER, EXPR_BYTEREG, EXPR_INDREG,
			 * EXPR_SEGREG */
    ID	    	ident;	/* EXPR_IDENT value */
#if defined _MSC_VER
    char        str[1]; /* MSC won't allow arrays of 0 length objects
                         * so make this array 1 byte long because the union
                         * will be the size of the largest member anyway */
#else
    char    	str[LABEL_IN_STRUCT];	/* EXPR_STRING start JAG */
#endif
} ExprElt;

				     

/*
 * An expression descriptor. Passed to Expr_Eval
 */
typedef struct _Expr {
    int	    	numElts;    	/* Number of elements in the expression */
    ID    	file;	    	/* Name of file in which expression was */
    long    	line:24,    	/* Line number at which expression started */
		idents:1,   	/* Set if expression has an EXPR_IDENT
				 * operator in it somewhere. Used to avoid
				 * repeated compressions in Expr_Eval if
				 * expression evaluated more than once. */
		musteval:1; 	/* Set if expression must be evaluated anyway,
				 * i.e. if EXPR_DOTTYPE present so identifiers
				 * will produce a reasonable result */
    SymbolPtr	curProc;    	/* Procedure active when expression was
				 * parsed */
    SymbolPtr	segments[6];	/* Segment bindings */
    ExprElt 	*elts;	    	/* The elements themselves */
} Expr;

/*
 * ExprStrElts --
 *	Return the number of ExprElts required to hold the string pointed to
 *	by (cptr).
 */
#define ExprStrElts(cptr) (((strlen(cptr)+1)+sizeof(ExprElt)-1)/sizeof(ExprElt))
/*
 * ExprSkipString --
 *	Advance an ExprElt * (eptr) past the string that starts at its
 *	location.
 */
#define ExprSkipString(eptr) ((ExprElt *)(eptr) + \
			      ExprStrElts(((ExprElt *)(eptr))->str))

/*
 * Result of evaluating an expression.
 */
#define EXPR_TYPE_CONST	    ((TypePtr)1)   /* Integer constant */
#define EXPR_TYPE_STRING    ((TypePtr)2)   /* String constant. */
#define EXPR_TYPE_FLOATSTACK ((TypePtr)3)  /* coprocessor stack element */

typedef struct _ExprResult {
    TypePtr type;  	/* Expression type. Possibly one of the
			 * the EXPR_TYPE constants, above */
    FixDesc rel;    	/* Relocation data */
    
    union {
	struct {
	    long    disp;   	/* Displacement/constant value */
	    byte    modrm;  	/* ModRM byte for effective address */
	    byte    dword_ea;	/* Indicates 32-bit effective address mode */
	    byte    sib;	/* optional SIB byte for effective address */
	    byte    override; 	/* Segment override to use (if known) */
#define EXPR_NO_OVERRIDE    1	    /* Override unknown */
#define EXPR_DEF_OVERRIDE   2	    /* Use default override (ie. none needed)*/
	}   	    ea;	    /* Effective address (includes registers) */
	char	    *str;   /* String constant */
	long 	    number; /* Numeric constant */
	ExprElt	    *elt;   /* Pointer to EXPR_SYM for override (INTERNAL) */
	SymbolPtr   sym;    /* General symbol (INTERNAL) */
	TypePtr	    type;   /* To hold a type while we decide what to do with
			     * it */
    }	    data;
} ExprResult;

/*
 * Evaluates non-zero if an ExprResult * (which points to an ea result) is
 * a segment register.
 */
#define EXPR_IS_SEGREG(resP) (((resP)->data.ea.disp == 0) && \
			      ((resP)->data.ea.modrm == MR_SEGREG) && \
			      ((resP)->data.ea.override != 0) && \
			      ((resP)->rel.sym == NULL))
/*
 * Evaluates non-zero if an ExprResult * points to a memory ea with a
 * segment override.
 */
#define EXPR_NEEDS_OVERRIDE(resP) ((resP)->data.ea.override>EXPR_DEF_OVERRIDE)

/*
 * Evaluate an expression. If noUndef is TRUE and an element of the expression
 * is undefined, the expression is replaced with an EXPR_UNDEF token at its
 * front. This should be done only after all source files have been read.
 * Returns non-zero if evaluation was successful. If returns 0,
 * the type field points to an error message explaining the problem. The
 * message is in a statically-allocated buffer.
 */
extern int Expr_Eval(Expr   	*expr,	    	/* Expression to evaluate */
		     ExprResult *result,    	/* Place to store result */
		     int    	flags,   	/* Flags controlling eval */
		     byte   	*status);    	/* Status of the evaluation.
						 * See Expr_Status, below, for
						 * more info */
#define EXPR_NOUNDEF	0x0001	    /* Don't allow EXPR_IDENT terms -- if
				     * they're still there, the symbols to
				     * which they refer are undefined and an
				     * error should be declared */
#define EXPR_FINALIZE	0x0002	    /* Evaluation occurring during final pass,
				     * so difference of relocatable values
				     * can be declared final */
#define EXPR_DATA_ENTER	0x0004	    /* Value is being entered as data, not
				     * used as an instruction operand, so
				     * "offset foo" should be returned as
				     * an address, not a constant */
#define EXPR_RECURSIVE	0x0008	    /* Used internally when evaluating
				     * a SYM_NUMBER */
#define EXPR_NOT_OPERAND 0x0010	    /* Expression is not the operand of
				     * an instruction, so complaints about
				     * using an assumed segment override need
				     * not be generated */
#define EXPR_NOREF  	0x0020	    /* Use of a symbol within the expression
				     * should not be counted as a reference to
				     * the symbol. Used by (1) the parser when
				     * reducing the value of a numeric equate
				     * to a constant to avoid spuriously
				     * marking library symbols as referenced,
				     * and (2) the assert module when evaluating
				     * assertions. Also prevents protominor
				     * stuff from happening */
/*
 * Used to extract the next part (between EXPR_COMMA operators) from an
 * expression. 'dest' must be the same Expr structure for the entire
 * extraction process. Its 'elts' field should be initialized to NULL
 * before Expr_NextPart is called for the first time.
 */
extern void  Expr_NextPart(Expr	    *src,   	/* Source expression from
						 * which a part is being
						 * extracted */
			   Expr	    *dest,  	/* Place to store result. */
			   int	    resolveInherits);

/*
 * Duplicate an expression. Original expression is untouched. If usurp is
 * true and 
 */
extern Expr *Expr_Copy(Expr *expr, int usurp);
extern void Expr_Free(Expr *expr);

/*
 * Figure the status of an expression result, returning a bitwise-or of the
 * EXPR_STAT flags defined below. EXPR_STAT_DEFINED is always set. Use the
 * return value and status from Expr_Eval to determine if the expression
 * contained any undefined elements.
 */
#define EXPR_STAT_CODE	    0x01    /* Code-related (program label involved) */
#define EXPR_STAT_DATA	    0x02    /* Data-related (variable label involved)*/
#define EXPR_STAT_CONST	    0x04    /* Constant */
#define EXPR_STAT_DIRECT    0x08    /* Uses direct addressing (CODE or DATA
				     * also set) */
#define EXPR_STAT_REGISTER  0x10    /* Is a register */
#define EXPR_STAT_DEFINED   0x20    /* All symbols defined */
#define EXPR_STAT_DELAY	    0x40    /* Don't use value until final pass --
				     * expression involves subtraction of
				     * relocatable symbols that will not be
				     * resolved until then */
#define EXPR_STAT_GLOBAL    0x80    /* Symbol w.r.t. which relocation will
				     * occur has global scope. */

extern byte Expr_Status(ExprResult *result);

/*
 * Routine used by code generators to decide various things. So far:
 *	EXPR_NOT    are excess bits significant or were they generated by a
 *	    	    NOT operator and can be safely ignored?
 *	EXPR_SUPER  Is a static method call directed to the object's
 *	    	    class or to its superclass?
 */
extern int Expr_InvolvesOp(Expr *expr, ExprOp op);

#endif /* _EXPR_H_ */
