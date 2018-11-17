
/*  A Bison parser, made from parse.y
    by GNU Bison version 1.28  */

#define YYBISON 1  /* Identify Bison output.  */

#define	MEMMODEL	257
#define	LANGUAGE	258
#define	EQU	259
#define	MACRO	260
#define	ALIGNMENT	261
#define	BREAK	262
#define	BYTEREG	263
#define	CAST	264
#define	COMBINE	265
#define	CONSTANT	266
#define	COPROCESSOR	267
#define	DEBUG	268
#define	DEF	269
#define	DWORDREG	270
#define	MASM	271
#define	PNTR	272
#define	PROCESSOR	273
#define	SEGREG	274
#define	SHOWM	275
#define	STATE	276
#define	WORDREG	277
#define	ST	278
#define	IFNDEF	279
#define	IFDEF	280
#define	IFDIF	281
#define	IFE	282
#define	IFIDN	283
#define	IFNB	284
#define	IFB	285
#define	IF	286
#define	IF1	287
#define	IF2	288
#define	FIRSTOP	289
#define	AND	290
#define	ARITH2	291
#define	ARPL	292
#define	BITNF	293
#define	BOUND	294
#define	CALL	295
#define	CMPS	296
#define	ENTER	297
#define	GROUP1	298
#define	IMUL	299
#define	IO	300
#define	INS	301
#define	INT	302
#define	JMP	303
#define	JUMP	304
#define	LDPTR	305
#define	LEA	306
#define	LEAVE	307
#define	LOCK	308
#define	LODS	309
#define	LOOP	310
#define	LSDT	311
#define	LSINFO	312
#define	MOV	313
#define	MOVS	314
#define	NAIO	315
#define	NAPRIV	316
#define	NASTRG	317
#define	NASTRGD	318
#define	NASTRGW	319
#define	NOARG	320
#define	NOARGD	321
#define	NOARGW	322
#define	NOT	323
#define	OR	324
#define	OPCODE	325
#define	OUTS	326
#define	POP	327
#define	PWORD	328
#define	PUSH	329
#define	REP	330
#define	RET	331
#define	RETF	332
#define	RETN	333
#define	SCAS	334
#define	SHIFT	335
#define	SHL	336
#define	SHLD	337
#define	SHR	338
#define	SHRD	339
#define	STOS	340
#define	TEST	341
#define	WREG1	342
#define	XCHG	343
#define	XLAT	344
#define	XLATB	345
#define	XOR	346
#define	FGROUP0	347
#define	FGROUP1	348
#define	FBIOP	349
#define	FCOM	350
#define	FUOP	351
#define	FZOP	352
#define	FFREE	353
#define	FINT	354
#define	FLDST	355
#define	FXCH	356
#define	LASTOP	357
#define	IDENT	358
#define	STRING	359
#define	PCTOUT	360
#define	MACARG	361
#define	STRUCT_INIT	362
#define	MACEXEC	363
#define	FIRSTSYM	364
#define	SYM	365
#define	STRUCT_SYM	366
#define	CLASS_SYM	367
#define	METHOD_SYM	368
#define	MODULE_SYM	369
#define	INSTVAR_SYM	370
#define	TYPE_SYM	371
#define	ETYPE_SYM	372
#define	RECORD_SYM	373
#define	EXPR_SYM	374
#define	LASTSYM	375
#define	PROTOMINOR_SYM	376
#define	EXPR	377
#define	PTYPE	378
#define	ABS	379
#define	ALIGN	380
#define	ASSERT	381
#define	ASSUME	382
#define	AT	383
#define	CATSTR	384
#define	CHUNK	385
#define	CLASS	386
#define	COMMENT	387
#define	CPUBLIC	388
#define	DEFAULT	389
#define	DEFETYPE	390
#define	DOT	391
#define	DOTENTER	392
#define	DOTLEAVE	393
#define	DOTTYPE	394
#define	DUP	395
#define	DYNAMIC	396
#define	ELSE	397
#define	END	398
#define	ENDC	399
#define	ENDIF	400
#define	ENDM	401
#define	ENDP	402
#define	ENDS	403
#define	ENUM	404
#define	EQ	405
#define	ERR	406
#define	ERRB	407
#define	ERRDEF	408
#define	ERRDIF	409
#define	ERRE	410
#define	ERRIDN	411
#define	ERRNB	412
#define	ERRNDEF	413
#define	ERRNZ	414
#define	EVEN	415
#define	EXITF	416
#define	EXITM	417
#define	EXPORT	418
#define	FALLTHRU	419
#define	FAR	420
#define	FIRST	421
#define	FLDMASK	422
#define	GE	423
#define	GLOBAL	424
#define	GROUP	425
#define	GT	426
#define	HANDLE	427
#define	HIGH	428
#define	HIGHPART	429
#define	INCLUDE	430
#define	INHERIT	431
#define	INST	432
#define	INSTR	433
#define	IOENABLE	434
#define	IRP	435
#define	IRPC	436
#define	LABEL	437
#define	LE	438
#define	LENGTH	439
#define	LMEM	440
#define	LOCAL	441
#define	LOCALIZE	442
#define	LOW	443
#define	LOWPART	444
#define	LT	445
#define	MASK	446
#define	MASTER	447
#define	METHOD	448
#define	MOD	449
#define	MODEL	450
#define	NE	451
#define	NEAR	452
#define	NORELOC	453
#define	NOTHING	454
#define	OFFPART	455
#define	OFFSET	456
#define	ON_STACK	457
#define	ORG	458
#define	PRIVATE	459
#define	PROC	460
#define	PROTOMINOR	461
#define	PROTORESET	462
#define	PTR	463
#define	PUBLIC	464
#define	RECORD	465
#define	RELOC	466
#define	REPT	467
#define	RESID	468
#define	SEG	469
#define	SEGMENT	470
#define	SEGREGOF	471
#define	SEGPART	472
#define	SIZE	473
#define	SIZESTR	474
#define	STATIC	475
#define	STRUC	476
#define	SUBSTR	477
#define	SUPER	478
#define	THIS	479
#define	TYPE	480
#define	UNDEF	481
#define	UNION	482
#define	UNREACHED	483
#define	USES	484
#define	VARDATA	485
#define	VARIANT	486
#define	VSEG	487
#define	WARN	488
#define	WIDTH	489
#define	WRITECHECK	490
#define	NOWRITECHECK	491
#define	READCHECK	492
#define	NOREADCHECK	493
#define	SHORT	494
#define	UNARY	495

#line 1 "parse.y"

/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- parser
 * FILE:	  parse.y
 *
 * AUTHOR:  	  Adam de Boor: Aug 26, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	yyparse	    	    Main parsing function
 *	yyerror	    	    Error reporter for use when you know you've
 *	    	    	    been called from the parser.
 *	yywarning   	    Warning message producer for use when you know
 *	    	    	    you've been called from the parser.
 *	Parse_Init  	    Set up initial parser state
 *	Parse_DefineString  Define a string equate.
 *	Parse_CheckClosure  Make sure things are closed up properly at
 *	    	    	    major code junctures (usually the end of a file)
 *	Parse_Complete	    Perform any final processing necessary when
 *	    	    	    all source code has been read.
 *	Parse_FileChange    Note a switch to a different source file.
 *	PushSegment 	    Switch to a new segment.
 *	PopSegment  	    Return to previous segment.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/26/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	A grammar to parse code for the assembler.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid = "$Id: parse.y,v 3.73 95/09/20 14:46:15 weber Exp $";
#endif lint

#include    <config.h>

#include    "esp.h"
#include    "code.h"
#include    "expr.h"
#include    "object.h"
#include    "scan.h"
#include    "type.h"
#include    "data.h"

#include    <stddef.h>

#include    <ctype.h>

#define YYERROR_VERBOSE  /* Give the follow set in parse error messages */

/*
 * Provide our own handler for the parser-stack overflow so the default one
 * that uses "alloca" isn't used, since alloca is forbidden to us owing to
 * the annoying hidden non-support of said function by our dearly beloved
 * HighC from MetaWare, A.M.D.G.
 */
#define yyoverflow ParseStackOverflow
#define YYLTYPE	byte	/* We don't use this, so minimize overhead */
static void ParseStackOverflow(char *,
			       short **, size_t,
			       YYSTYPE **, size_t,
			       int *);

#include    <objfmt.h>
/*
 * Current expression. There are two staticly-allocated expressions for
 * this parser (since no rule requires more than two operands of this
 * type), with a third used to evaluate things that must be constant
 * without interfering with either of the two main ones.
 *
 * The rules operand1 and operand2 decide which one to use, with curExpr
 * pointing to the one into which elements are to be stuffed.
 *
 * Each static expression points to its corresponding defElts array at
 * the beginning. A new array is allocated if the expression is too long
 * to fit in the default area.
 *
 * If the one of the expressions needs to be saved. Expr_Copy should
 * be called to copy things.
 */
#define DEF_EXPR_SIZE	128	/* Initial number of elements */
static Expr	*curExpr,	/* Expression being parsed */
		expr1,		/* Operand 1 */
		expr2,		/* Operand 2 */
		texpr;	    	/* Temporary expr for use in cexpr */
static int	curExprSize;	/* # of elements allocated for curExpr */
static ExprElt	defElts1[DEF_EXPR_SIZE],
		defElts2[DEF_EXPR_SIZE],
		defTElts[DEF_EXPR_SIZE];

static Expr 	zeroExpr;
static ExprElt	zeroElts[4];	/* EXPR_CONST, 0, EXPR_COMMA, linenum */

/*
 * Array of all staticly-allocated Expr's for ASSUME directive and EnterProc.
 */
static Expr    	*exprs[] = {
    &expr1, &expr2, &texpr
};

/*
 * inStruct contains a pointer to the structure currently being defined. If
 * it is NULL, no structure is being defined and data definitions are real.
 */
Symbol		*inStruct=0;

/*
 * curClass points to the Symbol for the class currently being defined or
 * to the class for which the current procedure is implementing a method.
 *
 * defClass is non-zero if defining a class and zero if just assembling
 * a method handler. When defining a class, inStruct points to the partial-
 * instance structure being defined.
 *
 * isPublic indicates if the methods/instance variables are to be
 * considered public or not.
 *
 * methFlags indicates if the current method can be called statically,
 * and whether it's an external method (OBJ_* constants defined in object.h)
 *
 *
 * classProc holds an index to pass to Scan_DontUseOpProc when a class
 * declaration is complete.
 */
Symbol		*curClass=NULL;
int		defClass=FALSE;
int		isPublic=FALSE;
int	    	methFlags;
int	    	classProc=-1;

/*
 * curProtoMinor points to the Symbol for the protominor most recently seen
 * in the current class declaration
 *
 */

Symbol		*curProtoMinor=NULL;

/*
 * protoMinorSymbolSeg is the segment where we put protoMinor symbols if the
 * current segment at the time was null
 */
Symbol          *protoMinorSymbolSeg=NULL;

/*
 * ignore is set TRUE if anything being read will be ignored. This includes
 * INCLUDE and MACRO directives. It is turned on while skipping false
 * conditionals.
 */
int		ignore=FALSE;

/*
 * Stack of nested if's. iflevel == -1 => no nested ifs in progress. The
 * stack is necessary to handle elseifs properly. The way these things work
 * is to process things normally if a conditional is true, but when it is
 * false, to call Scan_ToEndif, which reads the file until the end of the
 * conditional is reached. The terminating token, be it an ELSE, ELSEIF or
 * ENDIF, is pushed back into the input stream, preceded by a newline,
 * to be read next.
 */
#define MAX_IF_LEVEL	30
IfDesc 		ifStack[MAX_IF_LEVEL];
int		iflevel=-1;

/*
 * curFile describes the current input file. The 'line' and 'file' fields
 * are filled in only when the file is pushed on the stack of files when an
 * INCLUDE directive is acted on. The 'name' field, however, is always valid.
 *
 * The current line number is in yylineno, while the stream being read from is
 * in yyin.
 */
File		*curFile;	/* Info for current input file */

/*
 * dot is the current offset in the current segment. The current segment is
 * maintained in curSeg.
 */
int		dot;
Symbol		*curSeg;

/*
 * fall_thru is set whenever a .fall_thru directive is encountered. If code
 * is generated when fall_thru is set, we generate a warning. If checkLabel
 * isn't set for the segment when a procedure is ended while fall_thru is false,
 * we also generate a warning if warn_fall_thru is set.
 */
int		fall_thru = 0;

/*
 * curChunk is the symbol of the LMem chunk currently being defined. Null
 * if none.
 * lastChunk holds the most-recently defined chunk, for use by the LOCALIZE
 * directive.
 */
Symbol	    	*curChunk;
Symbol		*lastChunk;
int		lastChunkLine;		/* Line number of the lastChunk */
char		lastChunkFile[66];	/* File name of the lastChunk */

/*
 * Procedure-specific things (all reset by EndProc()).
 *	curProc	    Symbol of current procedure.
 *	localSize   Size of local variables so far.
 *	frameSize   Size of frame to be created (subtracted from frame pointer
 *	    	    on entry; this is different from localSize if any local
 *	    	    variables are initialized with pushes)
 *	usesMask    Mask of registers used by procedure.
 *	enterNeeded Non-zero if .ENTER should be given for procedure (any of
 *	    	    local variables being given, USES being encountered,
 *		    or arguments being declared cause this to be set)
 *	enterSeen   Non-zero if .ENTER directive seen in this procedure.
 *	leaveSeen   Non-zero if .LEAVE directive seen in this procedure.
 *	frameNeeded related to enterNeeded but indicates if a stack frame
 *	    	    needs to be set up. Can't just use REG_BP set in usesMask
 *	    	    as someone could very well have a function that thrashes
 *	    	    bp.
 *	frameSetup  Set if frame pointer has already been setup, owing to
 *	    	    push-initialized variables.
 *	isFirstLocalWord  is set each time a local variable is defined and push-
 *	    	    initialized. It is not pushed on the segment stack.
 */
Symbol	    	*curProc=NULL;
int	    	argOffset=0;
int	    	localSize=0;
int	    	frameSize=0;
dword	    	usesMask=0;
int		enterNeeded=FALSE;
int	    	enterSeen=FALSE;
int	    	leaveSeen=FALSE;
int	    	frameNeeded=FALSE;
int	    	frameSetup=FALSE;
int	    	isFirstLocalWord;

/*
 * Arguments from the .MODEL directive. Used to control how procedures are
 * declared.
 */
MemoryModel	  model = MM_SMALL;
Language	  language = LANG_C;

/*
 * Flag to indicate if we are doing memory write-checking. This form of
 * checking causes the _writecheck macro to be invoked whenever esp detects
 * that a write to memory is occuring. The macro is passed enough information
 * that it should be able to attempt validate the passed address.
 *
 * By default this sort of checking is off, because it can incur a great
 * expense.
 */
int		writeCheck = FALSE;

/*
 * This is a similar flag that verifies that reads from memory locations are
 * valid.
 */
int		readCheck = FALSE;

/*
 * Stuff for defArgs:
 *
 * emptyIsConst is non-zero if the base type of the data being defined
 * calls for a CONST(0) to be stored, as opposed to STRING(""), if an
 * element of the initializer is empty.
 *
 * checkForStrings is used to get the proper array length from the
 * initializer for a byte-sized variable. For each element in the initializer,
 * the parser will see if the thing is a multi-character string w/o any
 * other expression pieces (no 'hi'+3 or anything) and, if so, use the length
 * of the string as the number of elements for that part of the initializer,
 * rather than the 1 it usually uses.
 */
int	    	emptyIsConst;	    /* Non-zero if CONST(0) on empty */
int	    	checkForStrings;    /* Non-zero if should be on the lookout
				     * for string elements in initializer */
int	    	indir=0;    	    /* Non-zero if indirecting in an operand.
				     * i.e. WORDREG gets stored as EXPR_INDREG,
				     * DWORDREG gets stored as EXPR_EINDREG,
				     * BYTEREG is illegal, etc. */

/*
 * PREDEFINED STRING SYMBOLS:
 *
 *	@CurSeg	    	name of the current segment
 *	@Cpu	    	bits describing current CPU setting
 *	@CurProc    	name of the current procedure
 *	@FileName   	name of the main file
 *	@CurClass   	name of the current class, either in a class
 *	    	        declaration or in a method handler.
 *	@File	    	name of the current file.
 *	@Line	    	the current line number. This is handled specially
 *	    	    	by the scanner and returned as CONSTANT, not
 *	    	    	a string equate, as it changes so rapidly.
 *	@ArgSize    	number of bytes of arguments declared for the procedure
 */
static struct {
    char    *name;  	/* Name of predefined */
    MBlk    *value; 	/* Record allocated to hold value -- no need to store
			 * the symbol again. When the value changes (e.g.
			 * for @CurSeg), we just copy the new value into the
			 * block and alter the length */
}	    predefs[] = {
    "@CurSeg",	    NULL,
#define PD_CURSEG   	0
    "@Cpu", 	    NULL,
#define PD_CPU	    	1
    "@CurProc",	    NULL,
#define PD_CURPROC  	2
    "@FileName",    NULL,
#define PD_FILENAME 	3
    "@CurClass",    NULL,
#define PD_CURCLASS 	4
    "@File",	    NULL,
#define PD_FILE	    	5
    "@ArgSize",	    NULL,
#define PD_ARGSIZE  	6
};

#define PD_VAL_LEN  (256-MACRO_BLOCK_SIZE)

/*
 * FUNCTION DECLARATIONS
 *
 * SkipToEndif skips to the end of a false conditional.
 *
 * SetDispSize takes a pointer to a YYSTYPE structure and figures out the
 * smallest displacement permisible -- either 8- or 16-bit, never null.
 * It is used by the ea rules after merging offsets.
 *
 * OVERRIDE produces the correct segment-override opcode given the segment
 * register to use.
 */
#define OVERRIDE(reg)	(0x26 | (reg << 3))
static void	ResetExpr(Expr *, ExprElt *);	/* Reset curExpr, freeing any
						 * previously-allocated elts */
static void 	StoreExprOp(ExprOp);
static void 	StoreExprString(ExprOp, char *);
static void 	StoreExprConst(long);
static void	StoreExprFloatStack(long);
static void 	StoreExprIdent(ID);
static void 	StoreExprSymbol(Symbol *);
static void 	StoreExprType(TypePtr);
static void 	StoreExprReg(ExprOp, int);
static void 	DupExpr(int num, int start);
static void 	StoreSubExpr(Expr *);

static void 	FilterGenerated(SymbolPtr   sym);
void 		yyerror(char *fmt, ...);
void 		yywarning(char *fmt, ...);
static int  	ParseAdjustLocals(SymbolPtr, Opaque);
static int  	ParseCountLocals(SymbolPtr, Opaque);

/*
 * These two deal with the definition of a variable/instance variable/structure
 * field. They implicitly take curExpr as the initial/default value for
 * the thing. If advance is FALSE, then structOffset/dot are not advanced
 * (used by the LABEL directive).
 */
static void 	DefineData(ID name, TypePtr type, int advance, int usebase);
static void 	DefineDataSym(Symbol *sym, TypePtr type, int advance,
			      int usebase);

/*
 * Verifies that a label isn't multiply defined and was declared global or
 * public in the proper segment.
 */
static void 	CheckAndSetLabel(SymType type, Symbol *sym, int near);

/*
 * Begins a procedure, resolving the procedure pointer for unresolved local
 * variables and recording the symbol for the procedure for later use.
 */
static void 	EnterProc(SymbolPtr proc);

/*
 * Finishes out the current procedure, performing error checking on the
 * various special things we support.
 */
static void 	EndProc(ID name);
static void 	AddArg(ID name, TypePtr type);

static void 	EnterClass(SymbolPtr class);
static void 	EndClass(void);
static int  	CheckRelated(Symbol *curClass, Symbol *otherClass);

/*
 * Deal with an IF or ELSEIF token. Condition stored in curExpr and
 * must evaluate to a numeric constant.
 */
static void HandleIF(int isElse);

/*
 * Redefine a string equate.
 */
static void RedefineString(SymbolPtr sym, MBlk *val);

/*
 * Search a string for an occurrence of another string.
 */
static long FindSubstring(char *string, char *substring);

/*
 * Fixup procedure to verify the target of .fall_thru pseudo-op during pass 2
 */
static FixResult ParseFallThruCheck(int *dotPtr, int prevSize, int pass,
				    Expr *expr1, Expr *expr2, Opaque data);

/*
 * See if the passed ID is one of the library names specified on the command
 * line.
 */
static int	  ParseIsLibName(ID id);

static void	ParseSetLastChunkWarningInfo (void);
static void	ParseLocalizationCheck (void);

/*
 * Segment-stack definitions.
 *
 * The stack contains not only the value of dot and the segment involved,
 * but all the other crufty state variables for the definition of procedures,
 * classes and chunks.
 */
typedef struct _SegStack {
    struct _SegStack	*next;
    SymbolPtr	    	seg;	    /* Segment */
    SymbolPtr	    	inStruct;   /* Current structure */
    /*
     * Procedure stuff
     */
    SymbolPtr	    	curProc;    /* Current procedure */
    int	    	    	localSize;
    int	    	    	frameSize;
    int	    	    	frameSetup;
    dword    	    	usesMask;
    int	    	    	enterNeeded;
    int	    	    	enterSeen;
    int	    	    	leaveSeen;
    int	    	    	frameNeeded;
    int	    	    	fall_thru;
    /*
     * Chunk state
     */
    SymbolPtr	    	curChunk;
    /*
     * Class state
     */
    SymbolPtr	    	curClass;
    int	    	    	defClass;
    int	    	    	isPublic;
    int	    	    	classProc;
} SegStack;

SegStack    *segStack = NULL;

/******************************************************************************
 *
 *			 EXPRESSION FUNCTIONS
 *
 * These are up here with the variables so they can be inlined by the compiler
 * if reasonable.
 *****************************************************************************/

/***********************************************************************
 *				CopyExprCheckingIfZero
 ***********************************************************************
 * SYNOPSIS:	    Copy the passed expression, unless it's a constant
 *	    	    zero, in which case use the static zeroExpr instead
 * CALLED BY:	    recordField, DefineData, DefineDataSym
 * RETURN:	    Expr * to use
 * SIDE EFFECTS:    elements for the passed expression will be stolen if
 *	    	    the expression is copied and those elements are
 *	    	    dynamically allocated
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 9/92		Initial Revision
 *
 ***********************************************************************/
static Expr *
CopyExprCheckingIfZero(Expr *expr)
{
    if ((curExpr->numElts == 4) &&
	(curExpr->elts[2].op == EXPR_COMMA) &&
	(curExpr->elts[0].op == EXPR_CONST) &&
	(curExpr->elts[1].value == 0))
    {
	return &zeroExpr;
    } else if ((curExpr->numElts == 2) &&
	       (curExpr->elts[0].op == EXPR_CONST) &&
	       (curExpr->elts[1].value == 0))
    {
	return &zeroExpr;
    } else {
	return Expr_Copy(expr, TRUE);
    }
}

/***********************************************************************
 *				ResetExpr
 ***********************************************************************
 * SYNOPSIS:	    Reset curExpr to its default state.
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    If curExpr.elts points anywhere but at defElts,
 *		    it is freed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
static void
ResetExpr(Expr	    *expr,  /* Static Expr structure to use */
	  ExprElt   *elts)  /* Array of DEF_EXPR_SIZE elements to use */
{
    if (expr->numElts > DEF_EXPR_SIZE) {
	/*
	 * If expression held more than DEF_EXPR_SIZE elements, the elts array
	 * must have been dynamically allocated, so free it now before it
	 * goes away.
	 */
	free((char *)expr->elts);
    }
    curExpr = expr;
    curExpr->elts = elts;
    curExpr->numElts = 0;
    curExprSize = DEF_EXPR_SIZE;
    curExpr->line = yylineno;
    curExpr->file = curFile->name;
    curExpr->idents = 0;
    curExpr->musteval = 0;
}

/***********************************************************************
 *				RestoreExpr
 ***********************************************************************
 * SYNOPSIS:	Restore the current expression following something that
 *		used texpr.
 * CALLED BY:	(INTERNAL) yyparse
 * RETURN:	nothing
 * SIDE EFFECTS:curExpr and curExprSize are set
 *	    	texpr is reset
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/22/95		Initial Revision
 *
 ***********************************************************************/
static void
RestoreExpr(struct _exprSave *saved)
{
    ResetExpr(&texpr, defTElts);
    curExpr = saved->curExpr;
    curExprSize = saved->curExprSize;
}

/***********************************************************************
 *				CheckExprRoom
 ***********************************************************************
 * SYNOPSIS:	    Make sure curExpr has enough room for desired thing.
 * CALLED BY:	    StoreExprOp, StoreExprSymbol, StoreExprString,
 *  	    	    StoreExprReg, StoreExprConst
 * RETURN:	    Elt in which to store desired things.
 * SIDE EFFECTS:    curExpr.elts and curExprSize may change.
 *  	    	    curExpr.numElts is updated by the given amount.
 *
 * STRATEGY:	    None, really.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
inline static ExprElt *
CheckExprRoom(int   numNeeded)
{
    ExprElt 	*result;

    if (curExpr->numElts + numNeeded > curExprSize) {
	int oldSize = curExprSize;

	do {
	    curExprSize += DEF_EXPR_SIZE;
	} while (curExpr->numElts + numNeeded > curExprSize);

	if (oldSize != DEF_EXPR_SIZE) {
	    /*
	     * Use realloc to get more memory and possibly copy the stuff over
	     */
	    curExpr->elts =
		(ExprElt *)realloc_tagged((char *)curExpr->elts,
					  curExprSize * sizeof(ExprElt));
	} else {
	    /*
	     * Allocate a buffer for the expression and copy over the stuff
	     * we've already got.
	     */
	    ExprElt	*oldElts = curExpr->elts;

	    curExpr->elts =
		(ExprElt *)malloc_tagged(curExprSize * sizeof(ExprElt),
					 TAG_EXPR_ELTS);
	    bcopy(oldElts, curExpr->elts, curExpr->numElts * sizeof(ExprElt));
	}
    }

    /*
     * Figure where the caller can store stuff.
     */
    result = curExpr->elts + curExpr->numElts;

    /*
     * Up the number of elements stored.
     */
    curExpr->numElts += numNeeded;

    /*
     * Return the place to the caller
     */
    return(result);
}


/***********************************************************************
 *				StoreExprOp
 ***********************************************************************
 * SYNOPSIS:	    Store an ExprOp in the expression
 * CALLED BY:	    yyparse.
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
static void
StoreExprOp(ExprOp  op)
{
    ExprElt 	*elt = CheckExprRoom(1);

    elt->op = op;
}


/***********************************************************************
 *				StoreExprString
 ***********************************************************************
 * SYNOPSIS:	    Store a string value preceded by an ExprOp
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
static void
StoreExprString(ExprOp op, char *string)
{
    ExprElt 	*elt = CheckExprRoom(1 + ExprStrElts(string));

    elt->op = op;
    strcpy((char *)(elt+1), string);
}

/***********************************************************************
 *				StoreExprConst
 ***********************************************************************
 * SYNOPSIS:	    Store a short constant
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
static void
StoreExprConst(long value)
{
    ExprElt 	*elt = CheckExprRoom(2);

    elt->op = EXPR_CONST;
    elt[1].value = value;
}

/***********************************************************************
 *				StoreExprFloatStack
 ***********************************************************************
 * SYNOPSIS:	    Store a short constant
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
static void
StoreExprFloatStack(long value)
{
    ExprElt 	*elt = CheckExprRoom(2);

    elt->op = EXPR_FLOATSTACK;
    elt[1].value = value;
}

/***********************************************************************
 *				StoreExprIdent
 ***********************************************************************
 * SYNOPSIS:	    Store an identifier
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
static void
StoreExprIdent(ID id)
{
    ExprElt 	*elt = CheckExprRoom(2);

    curExpr->idents = 1;

    elt->op = EXPR_IDENT;
    elt[1].ident = id;
}

/***********************************************************************
 *				StoreExprComma
 ***********************************************************************
 * SYNOPSIS:	Store a comma operator in the current expression.
 * CALLED BY:	yyparse
 * RETURN:	nothing
 * SIDE EFFECTS:...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/15/91		Initial Revision
 *
 ***********************************************************************/
static void
StoreExprComma(void)
{
    ExprElt 	*elt = CheckExprRoom(2);

    elt->op = EXPR_COMMA;
    elt[1].value = yylineno;
}


/***********************************************************************
 *				StoreExprSymbol
 ***********************************************************************
 * SYNOPSIS:	    Store a Symbol * in the expression
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
static void
StoreExprSymbol(Symbol *sym)
{
    ExprElt 	*elt = CheckExprRoom(2);

    elt->op = EXPR_SYMOP;
    elt[1].sym = sym;
}

/***********************************************************************
 *				StoreExprType
 ***********************************************************************
 * SYNOPSIS:	    Store a TypePtr in the expression
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
static void
StoreExprType(TypePtr type)
{
    ExprElt 	*elt = CheckExprRoom(2);

    elt->op = EXPR_TYPE;
    elt[1].type = type;
}

/***********************************************************************
 *				StoreExprReg
 ***********************************************************************
 * SYNOPSIS:	    Store some sort of register in curExpr
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
static void
StoreExprReg(ExprOp regOp, int regNum)
{
    ExprElt 	*elt = CheckExprRoom(2);

    elt->op = regOp;
    elt[1].reg = regNum;
}


/***********************************************************************
 *				DupExpr
 ***********************************************************************
 * SYNOPSIS:	    Duplicate a portion of curExpr a specified number
 *	    	    of times to implement the DUP operator.
 * CALLED BY:	    def rule
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The expression is expanded. Each copy is separated from
 *	    	    each other copy by EXPR_COMMA elements, the whole effect
 *	    	    being as if all the elements were typed individually
 *		    with commas between them.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 3/89		Initial Revision
 *
 ***********************************************************************/
static void
DupExpr(int numCopies,	    /* Number of copies to make */
	int startElt)	    /* Element at which to start */
{
    ExprElt *elt, *source;
    int	    numElts;
    int	    copySize;
    int	    eltsPerCopy;

    assert(numCopies > 0);

    /*
     * No need to place an EXPR_COMMA element before each copy, since
     * defList places one at the end...
     */
    eltsPerCopy = curExpr->numElts - startElt;
    copySize = eltsPerCopy * sizeof(ExprElt);
    numElts = eltsPerCopy * numCopies;

    elt = CheckExprRoom(numElts);

    source = curExpr->elts+startElt;

    while(numCopies--) {
	/*
	 * Copy in the expression.
	 */
	bcopy(source, elt, copySize);
	/*
	 * Shift focus past copy
	 */
	elt += eltsPerCopy;
    }
}


/***********************************************************************
 *				StoreSubExpr
 ***********************************************************************
 * SYNOPSIS:	    Store a subexpression in the current expression
 * CALLED BY:	    yyparse (EXPR token)
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 4/89		Initial Revision
 *
 ***********************************************************************/
static void
StoreSubExpr(Expr   *expr)
{
    ExprElt 	*elt;
    Expr    	part;

    /*
     * Deal with subexpressions that contain EXPR_COMMA, as zero-initialized
     * bitfields do these days...
     */
    part.elts = NULL;		/* So Expr_NextPart knows this is the first
				 * time */
    Expr_NextPart(expr, &part, FALSE);

    elt = CheckExprRoom(part.numElts);

    bcopy(part.elts, elt, part.numElts * sizeof(ExprElt));
    curExpr->idents = curExpr->idents || part.idents;
}
#include <stdio.h>

#ifndef __cplusplus
#ifndef __STDC__
#define const
#endif
#endif



#define	YYFINAL		980
#define	YYFLAG		-32768
#define	YYNTBASE	258

#define YYTRANSLATE(x) ((unsigned)(x) <= 495 ? yytranslate[x] : 402)

static const short yytranslate[] = {     0,
     2,     2,     2,     2,     2,     2,     2,     2,     2,   254,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,   256,     2,     2,   252,
   253,   247,   245,   255,   246,   250,   248,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,   249,     2,     2,
   257,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
   243,     2,   244,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,   240,     2,   241,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     1,     3,     4,     5,     6,
     7,     8,     9,    10,    11,    12,    13,    14,    15,    16,
    17,    18,    19,    20,    21,    22,    23,    24,    25,    26,
    27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
    37,    38,    39,    40,    41,    42,    43,    44,    45,    46,
    47,    48,    49,    50,    51,    52,    53,    54,    55,    56,
    57,    58,    59,    60,    61,    62,    63,    64,    65,    66,
    67,    68,    69,    70,    71,    72,    73,    74,    75,    76,
    77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
    87,    88,    89,    90,    91,    92,    93,    94,    95,    96,
    97,    98,    99,   100,   101,   102,   103,   104,   105,   106,
   107,   108,   109,   110,   111,   112,   113,   114,   115,   116,
   117,   118,   119,   120,   121,   122,   123,   124,   125,   126,
   127,   128,   129,   130,   131,   132,   133,   134,   135,   136,
   137,   138,   139,   140,   141,   142,   143,   144,   145,   146,
   147,   148,   149,   150,   151,   152,   153,   154,   155,   156,
   157,   158,   159,   160,   161,   162,   163,   164,   165,   166,
   167,   168,   169,   170,   171,   172,   173,   174,   175,   176,
   177,   178,   179,   180,   181,   182,   183,   184,   185,   186,
   187,   188,   189,   190,   191,   192,   193,   194,   195,   196,
   197,   198,   199,   200,   201,   202,   203,   204,   205,   206,
   207,   208,   209,   210,   211,   212,   213,   214,   215,   216,
   217,   218,   219,   220,   221,   222,   223,   224,   225,   226,
   227,   228,   229,   230,   231,   232,   233,   234,   235,   236,
   237,   238,   239,   242,   251
};

#if YYDEBUG != 0
static const short yyprhs[] = {     0,
     0,     2,     4,     7,     9,    12,    15,    19,    21,    24,
    28,    31,    34,    37,    40,    42,    45,    48,    52,    55,
    58,    60,    63,    66,    69,    73,    77,    81,    82,    88,
    89,    95,    99,   103,   106,   108,   110,   111,   112,   114,
   116,   118,   120,   122,   124,   126,   128,   130,   132,   134,
   138,   142,   146,   149,   151,   155,   158,   161,   163,   165,
   169,   172,   174,   176,   178,   180,   183,   184,   187,   189,
   190,   194,   196,   199,   202,   204,   208,   210,   214,   216,
   218,   219,   221,   223,   226,   228,   231,   233,   236,   239,
   242,   245,   248,   251,   254,   257,   261,   264,   267,   272,
   279,   282,   284,   288,   291,   292,   298,   299,   305,   308,
   310,   312,   315,   317,   320,   324,   326,   328,   330,   334,
   338,   342,   345,   348,   351,   356,   363,   365,   367,   371,
   375,   379,   382,   383,   388,   389,   394,   395,   399,   401,
   405,   407,   408,   411,   413,   417,   420,   422,   426,   427,
   429,   430,   437,   438,   441,   445,   451,   459,   469,   473,
   475,   478,   479,   482,   485,   489,   494,   499,   504,   506,
   510,   512,   514,   516,   518,   520,   522,   524,   526,   528,
   530,   532,   534,   536,   540,   543,   546,   549,   552,   555,
   558,   562,   566,   568,   570,   572,   576,   579,   582,   586,
   591,   593,   594,   599,   605,   608,   609,   611,   613,   614,
   617,   619,   622,   627,   634,   638,   642,   648,   652,   658,
   664,   666,   668,   670,   673,   676,   679,   683,   687,   691,
   695,   699,   703,   707,   711,   713,   715,   717,   719,   721,
   723,   725,   727,   729,   733,   737,   739,   740,   741,   742,
   745,   748,   751,   754,   757,   759,   761,   763,   765,   767,
   771,   775,   776,   782,   784,   787,   788,   795,   799,   804,
   809,   813,   815,   817,   819,   821,   823,   825,   827,   829,
   831,   833,   835,   838,   840,   843,   846,   849,   852,   855,
   858,   862,   866,   870,   874,   878,   882,   886,   889,   892,
   895,   899,   903,   907,   911,   915,   919,   923,   927,   931,
   935,   939,   942,   945,   948,   951,   954,   957,   960,   963,
   966,   969,   972,   975,   978,   981,   984,   987,   990,   992,
   997,   999,  1002,  1005,  1006,  1009,  1012,  1015,  1017,  1019,
  1021,  1023,  1025,  1027,  1030,  1034,  1036,  1040,  1042,  1044,
  1045,  1050,  1055,  1059,  1066,  1071,  1074,  1076,  1081,  1086,
  1090,  1091,  1094,  1096,  1098,  1100,  1103,  1106,  1107,  1112,
  1113,  1118,  1120,  1122,  1125,  1127,  1131,  1133,  1135,  1138,
  1141,  1143,  1144,  1147,  1148,  1153,  1154,  1162,  1166,  1167,
  1175,  1179,  1182,  1183,  1191,  1194,  1196,  1198,  1200,  1204,
  1206,  1208,  1210,  1212,  1215,  1218,  1219,  1224,  1225,  1230,
  1232,  1234,  1238,  1242,  1248,  1254,  1256,  1258,  1260,  1261,
  1265,  1269,  1271,  1273,  1275,  1279,  1280,  1282,  1285,  1287,
  1289,  1291,  1293,  1296,  1298,  1300,  1302,  1306,  1308,  1313,
  1315,  1317,  1321,  1324,  1326,  1328,  1331,  1333,  1335,  1337,
  1339,  1342,  1346,  1350,  1353,  1356,  1357,  1359,  1363,  1365,
  1367,  1369,  1371,  1376,  1381,  1386,  1391,  1396,  1399,  1404,
  1407,  1412,  1414,  1417,  1422,  1424,  1427,  1430,  1432,  1435,
  1438,  1441,  1443,  1446,  1448,  1451,  1453,  1455,  1457,  1459,
  1461,  1463,  1465,  1467,  1470,  1477,  1482,  1487,  1492,  1495,
  1498,  1501,  1506,  1511,  1513,  1516,  1519,  1522,  1527,  1532,
  1537,  1540,  1542,  1544,  1546,  1550,  1552,  1557,  1560,  1562,
  1566,  1568,  1571,  1573,  1577,  1579,  1582,  1584,  1587,  1590,
  1592,  1594,  1597,  1599,  1602,  1604,  1607,  1609,  1611,  1614,
  1616,  1618,  1620,  1625,  1628,  1630,  1632,  1639,  1646,  1649,
  1654,  1657,  1662,  1665,  1667,  1669,  1671,  1673,  1675,  1677,
  1680,  1682,  1684,  1686,  1688,  1691,  1692,  1698,  1701,  1704,
  1707,  1709,  1711,  1712,  1716,  1717,  1721,  1723,  1726,  1727,
  1731,  1733,  1736,  1741,  1744,  1746,  1748,  1750,  1752,  1754,
  1758,  1761,  1764,  1768,  1772,  1775,  1781,  1785,  1791,  1795,
  1799,  1802,  1804,  1806,  1808,  1811,  1814,  1817,  1822,  1825,
  1830,  1833,  1836
};

static const short yyrhs[] = {   259,
     0,   262,     0,   259,   262,     0,   254,     0,   401,   254,
     0,   260,   254,     0,   260,   401,   254,     0,   255,     0,
   255,   260,     0,   264,   274,   254,     0,   264,   254,     0,
   263,   254,     0,   296,   254,     0,   274,   254,     0,   254,
     0,     1,   254,     0,   144,   254,     0,   144,   332,   254,
     0,   256,   262,     0,   104,     1,     0,   265,     0,   265,
   249,     0,   104,   249,     0,   111,   249,     0,    12,   137,
   249,     0,   104,   183,   328,     0,   111,   183,   328,     0,
     0,   104,   206,   268,   266,   270,     0,     0,   111,   206,
   268,   267,   270,     0,   198,   269,   277,     0,   166,   269,
   277,     0,   269,   277,     0,    41,     0,    49,     0,     0,
     0,   273,     0,   120,     0,   113,     0,   112,     0,   114,
     0,   115,     0,   116,     0,   117,     0,   118,     0,   119,
     0,   122,     0,   104,   249,   325,     0,   111,   249,   325,
     0,   271,   249,   325,     0,   249,   325,     0,   272,     0,
   273,   261,   272,     0,   111,   148,     0,   104,   148,     0,
   148,     0,   276,     0,   275,   261,   276,     0,   275,   276,
     0,    16,     0,    23,     0,     9,     0,    20,     0,   230,
   275,     0,     0,   230,   275,     0,   283,     0,     0,   283,
   278,   279,     0,   280,     0,   279,   280,     0,    75,   281,
     0,   282,     0,   281,   261,   282,     0,   332,     0,   284,
   187,   325,     0,   104,     0,   111,     0,     0,   271,     0,
   138,     0,   138,   285,     0,   139,     0,   139,   229,     0,
   177,     0,   177,   198,     0,   177,   166,     0,   177,   104,
     0,   177,   111,     0,   104,     6,     0,   109,     6,     0,
   104,     5,     0,   111,     5,     0,   111,     5,   105,     0,
   104,   286,     0,   111,   286,     0,   223,   105,   261,   336,
     0,   223,   105,   261,   336,   261,   336,     0,   130,   287,
     0,   105,     0,   105,   261,   287,     0,   213,   336,     0,
     0,   181,   104,   288,   261,   108,     0,     0,   182,   104,
   289,   261,   108,     0,   109,   290,     0,   109,     0,   291,
     0,   291,   290,     0,   107,     0,   256,   336,     0,   256,
   336,   255,     0,     5,     0,   257,     0,   332,     0,   104,
   292,   293,     0,   120,   292,   293,     0,   118,   292,   336,
     0,   104,   294,     0,   120,   294,     0,   220,   105,     0,
   179,   332,   261,   105,     0,   179,   332,   261,   105,   261,
   105,     0,    15,     0,   328,     0,   104,   295,   302,     0,
   111,   295,   302,     0,   116,   295,   302,     0,   295,   302,
     0,     0,   104,   131,   297,   300,     0,     0,   111,   131,
   298,   300,     0,     0,   131,   299,   300,     0,   301,     0,
   250,   295,   302,     0,   325,     0,     0,   111,   145,     0,
   145,     0,   178,   295,   302,     0,   329,   303,     0,   304,
     0,   303,   261,   304,     0,     0,   306,     0,     0,   306,
   141,   305,   252,   303,   253,     0,     0,   307,   337,     0,
   188,   308,   105,     0,   188,   308,   105,   261,   336,     0,
   188,   308,   105,   261,   336,   261,   336,     0,   188,   308,
   105,   261,   336,   261,   336,   261,   336,     0,   188,   308,
    69,     0,   309,     0,   111,   261,     0,     0,   170,   311,
     0,   210,   314,     0,   312,   249,   325,     0,   312,   249,
   131,   301,     0,   312,   249,   183,   166,     0,   312,   249,
   183,   198,     0,   310,     0,   311,   261,   310,     0,   104,
     0,   111,     0,   120,     0,   113,     0,   112,     0,   114,
     0,   115,     0,   116,     0,   117,     0,   118,     0,   119,
     0,   312,     0,   313,     0,   314,   261,   313,     0,   104,
   222,     0,   112,   222,     0,   112,   149,     0,   104,   228,
     0,   112,   228,     0,   112,   144,     0,   104,   211,   315,
     0,   104,   226,   325,     0,   316,     0,   317,     0,   320,
     0,   320,   255,   316,     0,   260,   318,     0,   319,   144,
     0,   320,   260,   318,     0,   320,   255,   260,   318,     0,
   104,     0,     0,   319,   249,   326,   321,     0,   319,   328,
   249,   326,   321,     0,   257,   332,     0,     0,    10,     0,
    12,     0,     0,   323,   207,     0,   323,     0,   323,   322,
     0,   323,   322,   261,   336,     0,   323,   322,   261,   336,
   261,   336,     0,   104,   136,   324,     0,   104,   150,   118,
     0,   104,   150,   118,   261,   336,     0,   111,   150,   118,
     0,   111,   150,   118,   261,   336,     0,   326,   141,   252,
   325,   253,     0,   328,     0,    12,     0,   120,     0,   235,
   111,     0,   235,   119,     0,   235,     1,     0,   326,   245,
   326,     0,   326,   246,   326,     0,   326,   247,   326,     0,
   326,   248,   326,     0,   326,   195,   326,     0,   326,    82,
   326,     0,   326,    84,   326,     0,   252,   336,   253,     0,
   112,     0,   118,     0,   119,     0,   117,     0,   124,     0,
    10,     0,   166,     0,   198,     0,    18,     0,    18,   250,
   325,     0,    18,   250,   104,     0,   327,     0,     0,     0,
     0,   329,   337,     0,   330,   337,     0,   329,   340,     0,
   330,   340,     0,   331,   337,     0,    16,     0,    23,     0,
     9,     0,    20,     0,   227,     0,   337,   249,   337,     0,
   337,   209,   337,     0,     0,   240,   328,   241,   338,   337,
     0,   327,     0,   242,   337,     0,     0,   119,   108,   339,
   252,   337,   253,     0,   243,   341,   244,     0,   337,   243,
   341,   244,     0,   243,   341,   244,   337,     0,   252,   337,
   253,     0,   105,     0,   108,     0,   115,     0,   123,     0,
   120,     0,   114,     0,   116,     0,   113,     0,   104,     0,
   111,     0,   137,     0,   225,   328,     0,    12,     0,    12,
   137,     0,   337,   218,     0,   337,   201,     0,   337,   175,
     0,   337,   190,     0,   224,   337,     0,   337,   245,   337,
     0,   337,   250,   337,     0,   337,   246,   337,     0,   337,
   247,   337,     0,   337,   248,   337,     0,   337,   195,   337,
     0,   337,   168,   337,     0,   246,   337,     0,   245,   337,
     0,    69,   337,     0,   337,    84,   337,     0,   337,    82,
   337,     0,   337,   151,   337,     0,   337,   197,   337,     0,
   337,   191,   337,     0,   337,   184,   337,     0,   337,   172,
   337,     0,   337,   169,   337,     0,   337,    36,   337,     0,
   337,    70,   337,     0,   337,    92,   337,     0,   174,   337,
     0,   189,   337,     0,   215,   337,     0,   216,   337,     0,
   217,   337,     0,   233,   337,     0,   202,   337,     0,   226,
   337,     0,   185,   337,     0,   219,   337,     0,   235,   337,
     0,   192,   337,     0,   167,   337,     0,   140,   337,     0,
   173,   337,     0,   214,   337,     0,   150,   337,     0,    24,
     0,    24,   252,    12,   253,     0,   337,     0,   342,   337,
     0,   342,     1,     0,     0,   343,   347,     0,   343,     1,
     0,   343,   200,     0,   128,     0,   216,     0,   215,     0,
   115,     0,   200,     0,   104,     0,   344,   332,     0,    20,
   249,   345,     0,   346,     0,   347,   261,   346,     0,   216,
     0,   255,     0,     0,   104,   348,   186,   349,     0,   115,
   348,   186,   349,     0,   104,   348,   351,     0,   350,   336,
   261,   336,   261,   336,     0,   350,   336,   261,   336,     0,
   350,   336,     0,   350,     0,   115,   348,   129,   336,     0,
   104,   348,   129,   336,     0,   115,   348,   351,     0,     0,
   351,   352,     0,     7,     0,    11,     0,   105,     0,   115,
   149,     0,   104,   149,     0,     0,   104,   171,   353,   356,
     0,     0,   115,   171,   354,   356,     0,   104,     0,   115,
     0,   215,   111,     0,   355,     0,   356,   261,   355,     0,
   194,     0,   221,     0,   205,   221,     0,   221,   205,     0,
   142,     0,     0,   357,   358,     0,     0,   357,   170,   360,
   358,     0,     0,   104,   359,   113,   361,   261,   365,   277,
     0,   104,   359,     1,     0,     0,   111,   359,   113,   362,
   261,   365,   277,     0,   111,   359,     1,     0,   132,   113,
     0,     0,   359,   364,   261,   113,   363,   261,   365,     0,
   359,     1,     0,   111,     0,   104,     0,   366,     0,   365,
   261,   366,     0,   114,     0,   135,     0,   212,     0,     1,
     0,   111,   147,     0,   104,   147,     0,     0,   104,   132,
   367,   369,     0,     0,   113,   132,   368,   369,     0,   113,
     0,    12,     0,   113,   261,   193,     0,   113,   261,   232,
     0,   113,   261,   193,   261,   232,     0,   113,   261,   232,
   261,   193,     0,     1,     0,   205,     0,   134,     0,     0,
   104,   357,   370,     0,   104,   357,   371,     0,   118,     0,
   114,     0,   104,     0,   104,   231,   372,     0,     0,   325,
     0,   207,   373,     0,   122,     0,   104,     0,   208,     0,
   134,     0,   134,   375,     0,   116,     0,     1,     0,   374,
     0,   375,   261,   374,     0,   332,     0,   332,   252,   333,
   253,     0,     1,     0,   376,     0,   377,   261,   376,     0,
   199,   377,     0,   205,     0,    22,     0,   230,   380,     0,
   379,     0,   113,     0,   104,     0,   378,     0,   380,   378,
     0,   380,   261,   378,     0,   104,   164,   332,     0,   113,
   145,     0,   113,   381,     0,     0,   332,     0,   332,   261,
   333,     0,    37,     0,    36,     0,    70,     0,    92,     0,
   382,   332,   261,   333,     0,    38,   332,   261,   333,     0,
    39,   332,   261,   333,     0,    40,   332,   261,   333,     0,
    41,   332,   261,   333,     0,    41,   332,     0,    42,   332,
   261,   333,     0,    42,   332,     0,    43,   332,   261,   333,
     0,    95,     0,    95,   334,     0,    95,   334,   261,   335,
     0,    96,     0,    96,   334,     0,    99,   334,     0,    93,
     0,    94,   332,     0,   100,   332,     0,   101,   334,     0,
   102,     0,   102,   334,     0,    98,     0,   383,   332,     0,
    44,     0,    69,     0,    66,     0,    68,     0,    67,     0,
    63,     0,    65,     0,    64,     0,    45,   332,     0,    45,
   332,   261,   333,   261,   336,     0,    45,   332,   261,   333,
     0,    46,   332,   261,   333,     0,    47,   332,   261,   333,
     0,    48,   332,     0,    49,   332,     0,    50,   332,     0,
    51,   332,   261,   333,     0,    52,   332,   261,   333,     0,
    53,     0,    55,   332,     0,    56,   332,     0,    57,   332,
     0,    58,   332,   261,   333,     0,    59,   332,   261,   333,
     0,    60,   332,   261,   333,     0,    60,   332,     0,    61,
     0,    62,     0,   385,     0,   385,    20,   249,     0,   384,
     0,    72,   332,   261,   333,     0,    73,   386,     0,   387,
     0,   387,   261,   386,     0,   332,     0,    75,   388,     0,
   389,     0,   388,   261,   389,     0,   332,     0,    74,   332,
     0,   390,     0,   390,   274,     0,   329,   391,     0,    76,
     0,    54,     0,    20,   249,     0,    77,     0,    77,   332,
     0,   392,     0,   392,   332,     0,    79,     0,    78,     0,
    80,   332,     0,    81,     0,    82,     0,    84,     0,   393,
   332,   261,   333,     0,   393,   332,     0,     9,     0,   336,
     0,    83,   332,   261,   333,   261,   394,     0,    85,   332,
   261,   333,   261,   394,     0,    86,   332,     0,    87,   332,
   261,   333,     0,    88,   332,     0,    89,   332,   261,   333,
     0,    90,   332,     0,    90,     0,    14,     0,    21,     0,
    17,     0,     8,     0,   165,     0,   165,   332,     0,   229,
     0,    19,     0,    13,     0,   180,     0,   127,   332,     0,
     0,   127,   332,   395,   261,   105,     0,   396,     7,     0,
   396,   336,     0,   396,     1,     0,   161,     0,   126,     0,
     0,   203,   397,   105,     0,     0,   234,   398,   105,     0,
   106,     0,   204,   332,     0,     0,    71,   399,   105,     0,
   196,     0,   400,     3,     0,   400,     3,   261,     4,     0,
   400,     1,     0,   236,     0,   237,     0,   238,     0,   239,
     0,   401,     0,    32,   331,   337,     0,    33,   331,     0,
    34,   331,     0,    31,   105,   331,     0,    26,   104,   331,
     0,    26,   331,     0,    27,   105,   255,   105,   331,     0,
    28,   331,   337,     0,    29,   105,   255,   105,   331,     0,
    30,   105,   331,     0,    25,   104,   331,     0,    25,   331,
     0,   143,     0,   146,     0,   152,     0,   152,   105,     0,
   153,   105,     0,   154,   104,     0,   155,   105,   255,   105,
     0,   156,   336,     0,   157,   105,   255,   105,     0,   158,
   105,     0,   159,   104,     0,   160,   336,     0
};

#endif

#if YYDEBUG != 0
static const short yyrline[] = { 0,
  1089,  1098,  1102,  1111,  1112,  1113,  1114,  1116,  1117,  1119,
  1120,  1121,  1122,  1123,  1124,  1125,  1129,  1136,  1148,  1157,
  1171,  1172,  1180,  1191,  1201,  1228,  1245,  1263,  1271,  1271,
  1278,  1279,  1280,  1281,  1296,  1297,  1298,  1301,  1302,  1305,
  1305,  1305,  1305,  1305,  1306,  1306,  1306,  1306,  1306,  1308,
  1312,  1320,  1326,  1336,  1337,  1340,  1358,  1364,  1381,  1382,
  1383,  1385,  1387,  1388,  1389,  1391,  1405,  1406,  1408,  1409,
  1450,  1460,  1461,  1463,  1472,  1473,  1482,  1516,  1546,  1547,
  1555,  1556,  1564,  1575,  1594,  1606,  1622,  1635,  1651,  1667,
  1677,  1697,  1702,  1714,  1723,  1732,  1758,  1762,  1767,  1799,
  1838,  1847,  1867,  1893,  1894,  1894,  1903,  1903,  1913,  1914,
  1921,  1922,  1924,  1935,  1958,  1991,  1992,  1994,  2026,  2030,
  2054,  2062,  2066,  2077,  2086,  2109,  2183,  2199,  2260,  2269,
  2278,  2284,  2300,  2315,  2315,  2358,  2358,  2371,  2373,  2382,
  2412,  2413,  2415,  2440,  2459,  2519,  2524,  2525,  2530,  2546,
  2574,  2624,  2651,  2659,  2672,  2679,  2687,  2696,  2706,  2719,
  2741,  2750,  2769,  2776,  2781,  2877,  2919,  2934,  2950,  2951,
  2958,  2962,  2975,  2988,  3001,  3002,  3003,  3004,  3005,  3006,
  3007,  3009,  3034,  3035,  3043,  3052,  3074,  3089,  3093,  3115,
  3133,  3203,  3208,  3209,  3216,  3221,  3234,  3236,  3237,  3246,
  3261,  3262,  3264,  3270,  3276,  3280,  3293,  3294,  3296,  3300,
  3309,  3316,  3323,  3330,  3341,  3346,  3355,  3364,  3383,  3412,
  3416,  3423,  3427,  3446,  3455,  3467,  3476,  3477,  3478,  3479,
  3489,  3499,  3503,  3507,  3513,  3514,  3515,  3516,  3517,  3518,
  3528,  3529,  3530,  3532,  3533,  3546,  3554,  3555,  3556,  3568,
  3569,  3570,  3571,  3572,  3636,  3644,  3662,  3674,  3675,  3686,
  3687,  3691,  3692,  3695,  3696,  3697,  3708,  3712,  3713,  3714,
  3715,  3716,  3721,  3726,  3727,  3728,  3729,  3743,  3757,  3758,
  3759,  3760,  3778,  3787,  3788,  3807,  3808,  3809,  3810,  3811,
  3812,  3813,  3814,  3815,  3816,  3817,  3818,  3819,  3820,  3821,
  3822,  3823,  3824,  3825,  3826,  3827,  3828,  3829,  3830,  3831,
  3832,  3833,  3834,  3835,  3836,  3837,  3838,  3839,  3840,  3841,
  3842,  3843,  3844,  3845,  3846,  3847,  3848,  3849,  3851,  3852,
  3853,  3855,  3856,  3858,  3869,  3873,  3877,  3888,  3893,  3893,
  3894,  3895,  3896,  3911,  3935,  3949,  3950,  3952,  3957,  3957,
  3958,  3975,  3993,  4011,  4022,  4032,  4043,  4054,  4066,  4076,
  4156,  4165,  4192,  4196,  4200,  4208,  4244,  4261,  4262,  4262,
  4271,  4280,  4284,  4292,  4297,  4308,  4328,  4333,  4334,  4335,
  4336,  4337,  4340,  4345,  4346,  4354,  4372,  4376,  4393,  4427,
  4431,  4448,  4470,  4482,  4488,  4494,  4508,  4524,  4525,  4527,
  4547,  4562,  4576,  4588,  4609,  4618,  4624,  4643,  4649,  4671,
  4681,  4695,  4700,  4709,  4714,  4719,  4736,  4740,  4744,  4753,
  4776,  4840,  4841,  4851,  4873,  4892,  4893,  4896,  4902,  4906,
  4962,  4972,  4986,  4988,  4992,  5028,  5029,  5031,  5050,  5061,
  5097,  5098,  5100,  5105,  5109,  5114,  5116,  5142,  5143,  5152,
  5153,  5154,  5156,  5165,  5188,  5200,  5204,  5209,  5222,  5222,
  5222,  5222,  5223,  5227,  5231,  5235,  5239,  5243,  5247,  5251,
  5255,  5260,  5264,  5268,  5272,  5276,  5280,  5284,  5288,  5292,
  5296,  5300,  5304,  5308,  5312,  5317,  5317,  5318,  5318,  5318,
  5319,  5319,  5319,  5320,  5324,  5328,  5332,  5336,  5340,  5344,
  5348,  5352,  5356,  5360,  5364,  5368,  5372,  5377,  5382,  5386,
  5390,  5394,  5399,  5404,  5409,  5422,  5426,  5430,  5432,  5437,
  5443,  5449,  5451,  5452,  5454,  5459,  5464,  5465,  5473,  5485,
  5486,  5487,  5498,  5530,  5542,  5546,  5551,  5552,  5554,  5559,
  5560,  5561,  5563,  5567,  5578,  5587,  5597,  5601,  5605,  5609,
  5613,  5618,  5622,  5626,  5636,  5637,  5638,  5639,  5640,  5641,
  5661,  5662,  5667,  5672,  5677,  5681,  5681,  5685,  5736,  5785,
  5789,  5808,  5813,  5814,  5839,  5840,  5905,  5915,  5967,  5968,
  5974,  5979,  5984,  5990,  5999,  6005,  6011,  6017,  6029,  6031,
  6036,  6044,  6052,  6059,  6065,  6076,  6084,  6091,  6099,  6106,
  6112,  6118,  6140,  6150,  6151,  6157,  6165,  6172,  6181,  6188,
  6197,  6206,  6213
};
#endif


#if YYDEBUG != 0 || defined (YYERROR_VERBOSE)

static const char * const yytname[] = {   "$","error","$undefined.","MEMMODEL",
"LANGUAGE","EQU","MACRO","ALIGNMENT","BREAK","BYTEREG","CAST","COMBINE","CONSTANT",
"COPROCESSOR","DEBUG","DEF","DWORDREG","MASM","PNTR","PROCESSOR","SEGREG","SHOWM",
"STATE","WORDREG","ST","IFNDEF","IFDEF","IFDIF","IFE","IFIDN","IFNB","IFB","IF",
"IF1","IF2","FIRSTOP","AND","ARITH2","ARPL","BITNF","BOUND","CALL","CMPS","ENTER",
"GROUP1","IMUL","IO","INS","INT","JMP","JUMP","LDPTR","LEA","LEAVE","LOCK","LODS",
"LOOP","LSDT","LSINFO","MOV","MOVS","NAIO","NAPRIV","NASTRG","NASTRGD","NASTRGW",
"NOARG","NOARGD","NOARGW","NOT","OR","OPCODE","OUTS","POP","PWORD","PUSH","REP",
"RET","RETF","RETN","SCAS","SHIFT","SHL","SHLD","SHR","SHRD","STOS","TEST","WREG1",
"XCHG","XLAT","XLATB","XOR","FGROUP0","FGROUP1","FBIOP","FCOM","FUOP","FZOP",
"FFREE","FINT","FLDST","FXCH","LASTOP","IDENT","STRING","PCTOUT","MACARG","STRUCT_INIT",
"MACEXEC","FIRSTSYM","SYM","STRUCT_SYM","CLASS_SYM","METHOD_SYM","MODULE_SYM",
"INSTVAR_SYM","TYPE_SYM","ETYPE_SYM","RECORD_SYM","EXPR_SYM","LASTSYM","PROTOMINOR_SYM",
"EXPR","PTYPE","ABS","ALIGN","ASSERT","ASSUME","AT","CATSTR","CHUNK","CLASS",
"COMMENT","CPUBLIC","DEFAULT","DEFETYPE","DOT","DOTENTER","DOTLEAVE","DOTTYPE",
"DUP","DYNAMIC","ELSE","END","ENDC","ENDIF","ENDM","ENDP","ENDS","ENUM","EQ",
"ERR","ERRB","ERRDEF","ERRDIF","ERRE","ERRIDN","ERRNB","ERRNDEF","ERRNZ","EVEN",
"EXITF","EXITM","EXPORT","FALLTHRU","FAR","FIRST","FLDMASK","GE","GLOBAL","GROUP",
"GT","HANDLE","HIGH","HIGHPART","INCLUDE","INHERIT","INST","INSTR","IOENABLE",
"IRP","IRPC","LABEL","LE","LENGTH","LMEM","LOCAL","LOCALIZE","LOW","LOWPART",
"LT","MASK","MASTER","METHOD","MOD","MODEL","NE","NEAR","NORELOC","NOTHING",
"OFFPART","OFFSET","ON_STACK","ORG","PRIVATE","PROC","PROTOMINOR","PROTORESET",
"PTR","PUBLIC","RECORD","RELOC","REPT","RESID","SEG","SEGMENT","SEGREGOF","SEGPART",
"SIZE","SIZESTR","STATIC","STRUC","SUBSTR","SUPER","THIS","TYPE","UNDEF","UNION",
"UNREACHED","USES","VARDATA","VARIANT","VSEG","WARN","WIDTH","WRITECHECK","NOWRITECHECK",
"READCHECK","NOREADCHECK","'{'","'}'","SHORT","'['","']'","'+'","'-'","'*'",
"'/'","':'","'.'","UNARY","'('","')'","'\\n'","','","'%'","'='","errcheck","file",
"multiEOL","flexiComma","line","labeled_op","ref_label","label","@1","@2","procArgs1",
"procCallFlag","procArgsArgDeclStart","sym","procArg","procArgsArgDecls","op",
"usesArgs","usesReg","procUsesArgs","@3","pushLocals","pushLocal","pushLocalOperandList",
"pushLocalOperand","localDecl","localID","inherit","strop","catstrargs","@4",
"@5","macroArgList","macroArg","equ","equ_value","numstrop","defT","dataDef",
"@6","@7","@8","chunkDef","chunktype","defArgs","defList","def","@9","def2",
"@10","locOptChunkSym","optChunkSym","globalDef","globalDefs","globalSym","pubSym",
"pubDefs","recordDefs","recordLineDef","recordMLineDef","recordMLineBody","recordFieldName",
"recordField","recordFieldVal","etypeSize","etypeFlags","etypeArgs","fulltype",
"lexpr","optype","type","setExpr1","setExpr2","setTExpr","operand1","operand2",
"foperand1","foperand2","cexpr","operand","@11","@12","foperand","indir","indirStart",
"assume","assumeSegSegOp","assumeSeg","assumeArg","assumeArgs","segment","optComma",
"lmemSegDef","segAttrs","segAttr","@13","@14","groupElement","groupList","method",
"methodStatic","methodDecl","@15","@16","@17","@18","extMethodSym","methodList",
"methodListItem","@19","@20","classDeclArgs","methodFlags","rangeSym","vardataType",
"protoMinorSym","cpubDef","cpubDefs","nrDef","nrDefs","classUsesArg","classUsesSym",
"classUsesArgs","classDefArgs","arith2Inst","group1Inst","noArgInst","naStrgInst",
"popOperandList","popOperand","pushOperandList","pushOperand","prefix","prefixInst",
"retInst","shiftInst","CLorCexpr","@21","align","@22","@23","@24","model","conditional", NULL
};
#endif

static const short yyr1[] = {     0,
   258,   259,   259,   260,   260,   260,   260,   261,   261,   262,
   262,   262,   262,   262,   262,   262,   262,   262,   262,   263,
   264,   264,   265,   265,   265,   263,   263,   266,   263,   267,
   263,   268,   268,   268,   269,   269,   269,   270,   270,   271,
   271,   271,   271,   271,   271,   271,   271,   271,   271,   272,
   272,   272,   272,   273,   273,   263,   263,   274,   275,   275,
   275,   276,   276,   276,   276,   274,   277,   277,   263,   278,
   263,   279,   279,   280,   281,   281,   282,   283,   284,   284,
   284,   284,   274,   274,   274,   274,   285,   285,   285,   285,
   285,   263,   263,   263,   263,   263,   263,   263,   286,   286,
   286,   287,   287,   274,   288,   274,   289,   274,   274,   274,
   290,   290,   291,   291,   291,   292,   292,   293,   263,   263,
   263,   263,   263,   294,   294,   294,   295,   295,   296,   296,
   296,   296,   297,   263,   298,   263,   299,   263,   300,   300,
   301,   301,   263,   274,   274,   302,   303,   303,   304,   304,
   305,   304,   307,   306,   274,   274,   274,   274,   274,   308,
   309,   309,   274,   274,   310,   310,   310,   310,   311,   311,
   312,   312,   312,   312,   312,   312,   312,   312,   312,   312,
   312,   313,   314,   314,   263,   263,   263,   263,   263,   263,
   263,   263,   315,   315,   316,   316,   317,   318,   318,   318,
   319,   319,   320,   320,   321,   321,   322,   322,   323,   323,
   324,   324,   324,   324,   263,   263,   263,   263,   263,   325,
   325,   326,   326,   326,   326,   326,   326,   326,   326,   326,
   326,   326,   326,   326,   327,   327,   327,   327,   327,   327,
   327,   327,   327,   328,   328,   328,   329,   330,   331,   332,
   333,   334,   335,   336,   337,   337,   337,   337,   337,   337,
   337,   338,   337,   337,   337,   339,   337,   337,   337,   337,
   337,   337,   337,   337,   337,   337,   337,   337,   337,   337,
   337,   337,   337,   337,   337,   337,   337,   337,   337,   337,
   337,   337,   337,   337,   337,   337,   337,   337,   337,   337,
   337,   337,   337,   337,   337,   337,   337,   337,   337,   337,
   337,   337,   337,   337,   337,   337,   337,   337,   337,   337,
   337,   337,   337,   337,   337,   337,   337,   337,   340,   340,
   340,   341,   341,   342,   274,   274,   274,   343,   344,   344,
   345,   345,   345,   345,   346,   347,   347,   348,   349,   349,
   350,   350,   263,   263,   263,   263,   263,   263,   263,   263,
   351,   351,   352,   352,   352,   263,   263,   353,   263,   354,
   263,   355,   355,   355,   356,   356,   357,   358,   358,   358,
   358,   358,   359,   360,   359,   361,   263,   263,   362,   263,
   263,   263,   363,   274,   274,   364,   364,   365,   365,   366,
   366,   366,   366,   263,   263,   367,   263,   368,   263,   369,
   369,   369,   369,   369,   369,   369,   370,   370,   370,   263,
   263,   371,   371,   371,   263,   372,   372,   263,   373,   373,
   263,   274,   274,   374,   374,   375,   375,   376,   376,   376,
   377,   377,   274,   274,   274,   274,   378,   379,   379,   380,
   380,   380,   263,   263,   274,   381,   381,   381,   382,   382,
   382,   382,   274,   274,   274,   274,   274,   274,   274,   274,
   274,   274,   274,   274,   274,   274,   274,   274,   274,   274,
   274,   274,   274,   274,   274,   383,   383,   384,   384,   384,
   385,   385,   385,   274,   274,   274,   274,   274,   274,   274,
   274,   274,   274,   274,   274,   274,   274,   274,   274,   274,
   274,   274,   274,   274,   274,   274,   274,   274,   386,   386,
   387,   274,   388,   388,   389,   274,   274,   274,   390,   391,
   391,   391,   274,   274,   274,   274,   392,   392,   274,   393,
   393,   393,   274,   274,   394,   394,   274,   274,   274,   274,
   274,   274,   274,   274,   274,   274,   274,   274,   274,   274,
   274,   274,   274,   274,   274,   395,   274,   274,   274,   274,
   274,   396,   397,   274,   398,   274,   274,   274,   399,   274,
   400,   274,   274,   274,   274,   274,   274,   274,   274,   401,
   401,   401,   401,   401,   401,   401,   401,   401,   401,   401,
   401,   401,   401,   274,   274,   274,   274,   274,   274,   274,
   274,   274,   274
};

static const short yyr2[] = {     0,
     1,     1,     2,     1,     2,     2,     3,     1,     2,     3,
     2,     2,     2,     2,     1,     2,     2,     3,     2,     2,
     1,     2,     2,     2,     3,     3,     3,     0,     5,     0,
     5,     3,     3,     2,     1,     1,     0,     0,     1,     1,
     1,     1,     1,     1,     1,     1,     1,     1,     1,     3,
     3,     3,     2,     1,     3,     2,     2,     1,     1,     3,
     2,     1,     1,     1,     1,     2,     0,     2,     1,     0,
     3,     1,     2,     2,     1,     3,     1,     3,     1,     1,
     0,     1,     1,     2,     1,     2,     1,     2,     2,     2,
     2,     2,     2,     2,     2,     3,     2,     2,     4,     6,
     2,     1,     3,     2,     0,     5,     0,     5,     2,     1,
     1,     2,     1,     2,     3,     1,     1,     1,     3,     3,
     3,     2,     2,     2,     4,     6,     1,     1,     3,     3,
     3,     2,     0,     4,     0,     4,     0,     3,     1,     3,
     1,     0,     2,     1,     3,     2,     1,     3,     0,     1,
     0,     6,     0,     2,     3,     5,     7,     9,     3,     1,
     2,     0,     2,     2,     3,     4,     4,     4,     1,     3,
     1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
     1,     1,     1,     3,     2,     2,     2,     2,     2,     2,
     3,     3,     1,     1,     1,     3,     2,     2,     3,     4,
     1,     0,     4,     5,     2,     0,     1,     1,     0,     2,
     1,     2,     4,     6,     3,     3,     5,     3,     5,     5,
     1,     1,     1,     2,     2,     2,     3,     3,     3,     3,
     3,     3,     3,     3,     1,     1,     1,     1,     1,     1,
     1,     1,     1,     3,     3,     1,     0,     0,     0,     2,
     2,     2,     2,     2,     1,     1,     1,     1,     1,     3,
     3,     0,     5,     1,     2,     0,     6,     3,     4,     4,
     3,     1,     1,     1,     1,     1,     1,     1,     1,     1,
     1,     1,     2,     1,     2,     2,     2,     2,     2,     2,
     3,     3,     3,     3,     3,     3,     3,     2,     2,     2,
     3,     3,     3,     3,     3,     3,     3,     3,     3,     3,
     3,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     1,     4,
     1,     2,     2,     0,     2,     2,     2,     1,     1,     1,
     1,     1,     1,     2,     3,     1,     3,     1,     1,     0,
     4,     4,     3,     6,     4,     2,     1,     4,     4,     3,
     0,     2,     1,     1,     1,     2,     2,     0,     4,     0,
     4,     1,     1,     2,     1,     3,     1,     1,     2,     2,
     1,     0,     2,     0,     4,     0,     7,     3,     0,     7,
     3,     2,     0,     7,     2,     1,     1,     1,     3,     1,
     1,     1,     1,     2,     2,     0,     4,     0,     4,     1,
     1,     3,     3,     5,     5,     1,     1,     1,     0,     3,
     3,     1,     1,     1,     3,     0,     1,     2,     1,     1,
     1,     1,     2,     1,     1,     1,     3,     1,     4,     1,
     1,     3,     2,     1,     1,     2,     1,     1,     1,     1,
     2,     3,     3,     2,     2,     0,     1,     3,     1,     1,
     1,     1,     4,     4,     4,     4,     4,     2,     4,     2,
     4,     1,     2,     4,     1,     2,     2,     1,     2,     2,
     2,     1,     2,     1,     2,     1,     1,     1,     1,     1,
     1,     1,     1,     2,     6,     4,     4,     4,     2,     2,
     2,     4,     4,     1,     2,     2,     2,     4,     4,     4,
     2,     1,     1,     1,     3,     1,     4,     2,     1,     3,
     1,     2,     1,     3,     1,     2,     1,     2,     2,     1,
     1,     2,     1,     2,     1,     2,     1,     1,     2,     1,
     1,     1,     4,     2,     1,     1,     6,     6,     2,     4,
     2,     4,     2,     1,     1,     1,     1,     1,     1,     2,
     1,     1,     1,     1,     2,     0,     5,     2,     2,     2,
     1,     1,     0,     3,     0,     3,     1,     2,     0,     3,
     1,     2,     4,     2,     1,     1,     1,     1,     1,     3,
     2,     2,     3,     3,     2,     5,     3,     5,     3,     3,
     2,     1,     1,     1,     2,     2,     2,     4,     2,     4,
     2,     2,     2
};

static const short yydefact[] = {     0,
     0,   558,   240,     0,   563,   555,   127,   557,   243,   562,
   556,   445,   249,   249,     0,   249,     0,     0,     0,   249,
   249,   249,   460,   459,   247,   247,   247,   247,   247,   247,
   486,   247,   247,   247,   247,   247,   247,   247,   247,   504,
   247,   247,   247,   247,   247,   247,   512,   513,   491,   493,
   492,   488,   490,   489,   487,   461,   579,   247,   247,   247,
   247,   247,   538,   537,   247,   540,   541,   247,   542,   247,
   247,   247,   247,   247,   247,   462,   478,   247,   247,   247,
   484,   247,   247,   247,   247,     0,   577,   110,    80,   235,
   247,    43,    44,    45,   238,   236,   237,    40,    49,   239,
   572,   247,   338,   137,     0,     0,    83,    85,   602,   247,
   144,   603,    58,   604,     0,     0,     0,   249,     0,     0,
     0,   249,   571,   247,   241,     0,     0,   564,     0,     0,
   162,   377,   581,   242,     0,   573,   247,   444,     0,   431,
     0,   249,   561,     0,   575,   585,   586,   587,   588,    15,
     0,     0,     2,     0,   247,    21,    82,     0,    69,     0,
   247,     0,   246,   128,     0,     0,   249,   382,     0,   247,
   247,   516,   514,   247,   247,   247,     0,     0,   589,    16,
     0,     0,   249,   601,   249,   595,     0,     0,     0,   249,
   249,     0,   591,   592,     0,     0,     0,     0,   468,   470,
     0,   494,     0,     0,   499,   500,   501,     0,     0,   505,
   506,   507,     0,     0,   511,     0,     0,   521,   518,   519,
   526,   525,   522,   523,   534,   539,     0,     0,   549,     0,
   551,     0,   553,   479,     0,   473,   476,   477,   480,   481,
   483,    20,   116,    92,   235,   238,   236,   237,     0,   133,
   406,   209,   405,    57,   367,     0,   247,   368,   247,     0,
    37,   202,   348,     0,   185,     0,     0,   188,   426,    23,
   117,    97,   247,   122,   247,   361,   382,     0,    93,   113,
   249,   109,   111,    95,   135,   143,   404,    56,     0,     0,
    37,    24,    98,   247,     0,   190,   187,   186,   189,   408,
   454,   457,   455,   366,   370,   361,   247,   116,   249,   247,
   123,   565,   142,   392,   435,   434,   436,   433,    87,    84,
    86,    17,     0,   605,   606,   607,     0,     0,   609,     0,
   611,   612,   613,   560,   171,   172,   175,   174,   176,   177,
   178,   179,   180,   181,   173,   169,   163,     0,   247,   105,
   107,     0,     0,   160,   440,   438,   441,   443,     0,   578,
   430,   429,   428,   182,   183,   164,   104,    64,    62,    65,
    63,   449,   448,    66,    59,   450,   447,   446,     0,    19,
     3,    12,   110,   247,    11,     0,    22,    14,     0,     0,
   132,   153,    13,     0,   531,   530,   529,   336,     0,   337,
   346,   335,   356,   381,   384,     0,   378,   383,   395,   397,
   396,     0,     0,   485,     0,   528,   536,   544,   570,   568,
   569,   584,   582,    25,   222,   245,   223,     0,   249,   244,
     0,   221,   600,   594,     0,   257,   284,   255,   243,   258,
   256,     0,   280,   272,   273,   281,   279,   277,   274,   278,
   237,   276,   275,   282,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,   259,     0,     0,     0,     0,   334,     0,     0,     0,
   264,   597,     0,   599,   593,   590,   250,     8,   248,   248,
   248,   248,   248,   248,   248,   248,   248,   248,   248,   248,
   248,   248,   580,   248,   247,   247,   248,   248,   248,   248,
   329,   331,   252,   248,   102,   101,   142,     0,   211,   215,
   216,   453,     0,     0,    26,    35,    36,    37,    37,    28,
    67,   201,     4,   202,   191,   193,   194,     0,   195,     0,
   124,     0,   192,   427,   425,   119,   118,   129,   249,   350,
   353,   424,   423,   422,   418,   417,   420,   421,   388,   386,
   114,   112,    96,   142,   218,    27,    30,   130,   391,   389,
     0,   248,     0,   249,   350,   360,   131,   121,   120,     0,
     0,   138,   139,   141,     0,    90,    91,    89,    88,    18,
     0,   254,     0,     0,     0,   145,     0,     0,   161,   159,
   155,   248,     0,   574,     0,     0,    61,     0,   451,   576,
    10,   247,    71,    72,    78,   146,   147,   150,     0,   532,
     0,     0,   249,   382,   379,   380,     0,   248,   515,   248,
     0,   226,   224,   225,     0,     0,     0,     0,     0,     0,
     0,     0,     0,   249,   285,   300,   266,   325,   328,   324,
   326,   312,   320,   313,   323,   318,   327,   314,   315,   316,
   321,   290,   283,   319,   317,   322,     0,   265,     0,     0,
   299,   298,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,   288,     0,   289,     0,     0,     0,   287,     0,
   286,   334,     0,     0,     0,     0,     0,     0,   249,     9,
     0,   464,   465,   466,   467,   469,   471,   496,   497,   498,
   502,   503,   508,   509,   510,   517,   520,   524,     0,     0,
   550,   552,     0,     0,   474,     0,   134,   416,   411,   410,
   407,   207,   208,   210,   212,   249,   372,   373,     0,   375,
   369,     0,    67,    67,    38,     0,    34,     6,   197,     0,
     0,     0,     0,     0,   202,     5,   249,   359,   349,   351,
   363,   364,   365,   362,     0,   115,   136,   249,    38,     0,
   409,   458,   371,   358,   352,     0,   247,   437,   608,   610,
   170,   142,     0,   165,     0,     0,   249,     0,   442,   184,
    60,   452,    74,    75,    77,    73,   153,   151,   154,   343,
   341,   342,   340,   339,   247,   345,   347,   355,   385,   393,
   463,   543,   583,   234,   232,   233,     0,   231,   227,   228,
   229,   230,   596,     0,   262,   268,   333,   332,   271,   309,
   310,   302,   301,   311,   303,   297,   308,   307,   306,   305,
   296,   304,   261,     0,   291,   293,   294,   295,   260,   292,
   598,   251,   249,   249,   249,     0,   253,   103,     0,   249,
   217,   374,     0,   125,    33,    32,     0,     0,    42,    41,
    44,    45,    46,    47,    48,    40,     0,    29,     0,    54,
    39,    68,   198,     0,   202,     7,   206,     0,   196,    99,
     0,   219,    31,     0,   567,   140,   166,   167,   168,   106,
   108,   156,   439,   247,   148,     0,   344,   249,     0,     0,
     0,     0,   270,   269,   495,   545,   546,   547,   548,   330,
   412,   413,   213,   376,     0,     0,     0,    53,     0,     0,
   202,   199,   247,   203,   206,   249,   403,   400,   401,   402,
    67,   398,    67,   249,    76,   153,   354,     0,   220,     0,
   263,     0,     0,   249,   126,    50,    51,    52,    55,   200,
   205,   204,   100,     0,   387,   390,   157,     0,   394,   267,
   414,   415,   214,   399,   249,   152,   158,     0,     0,     0
};

static const short yydefgoto[] = {   978,
   152,   534,   964,   153,   154,   155,   156,   745,   769,   530,
   531,   878,   157,   880,   881,   158,   374,   375,   747,   389,
   613,   614,   793,   794,   159,   160,   320,   272,   516,   597,
   598,   282,   283,   273,   546,   274,   161,   162,   517,   564,
   313,   582,   583,   391,   616,   617,   906,   618,   619,   353,
   354,   346,   347,   348,   365,   366,   535,   536,   537,   749,
   750,   751,   934,   735,   519,   520,   584,   431,   481,   432,
   195,   701,   328,   218,   702,   236,   725,   917,   512,   912,
   824,   513,   669,   670,   166,   805,   806,   401,   402,   276,
   760,   167,   551,   764,   523,   573,   740,   741,   168,   408,
   169,   624,   765,   770,   909,   412,   941,   942,   518,   571,
   731,   557,   558,   545,   363,   317,   318,   357,   358,   376,
   377,   378,   303,   170,   171,   172,   173,   219,   220,   223,
   224,   174,   397,   175,   176,   918,   580,   177,   359,   379,
   216,   178,   179
};

static const short yypact[] = {  1625,
  -155,-32768,-32768,     5,-32768,-32768,-32768,-32768,  -124,-32768,
-32768,-32768,    97,   134,    92,-32768,   113,   143,   149,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,    12,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,    24,-32768,-32768,-32768,    40,    67,
-32768,-32768,-32768,-32768,    87,  1392,-32768,    33,   225,    63,
   -39,-32768,   -21,   676,    72,    30,   101,    -1,-32768,-32768,
-32768,-32768,-32768,-32768,   201,     7,   154,   129,-32768,   117,
-32768,-32768,-32768,   262,   269,   272,   273,-32768,   287,   288,
   285,-32768,-32768,   140,-32768,   986,   676,-32768,   292,   302,
   296,-32768,-32768,-32768,  1982,-32768,-32768,-32768,   124,-32768,
   986,-32768,-32768,   123,-32768,-32768,-32768,-32768,-32768,-32768,
  1625,  1196,-32768,   164,  2370,   168,-32768,   167,   349,   235,
-32768,   171,-32768,-32768,   221,    64,   172,   -29,    77,-32768,
-32768,-32768,   407,  2604,   174,-32768,  1830,   156,-32768,-32768,
   181,   347,-32768,-32768,-32768,-32768,   177,  2933,   178,-32768,
-32768,  2933,-32768,-32768,  2933,   180,   180,   180,   180,   180,
   180,   180,   180,   180,-32768,-32768,-32768,   180,   180,-32768,
-32768,-32768,   180,   180,   180,   332,   180,-32768,-32768,   180,
-32768,-32768,   180,-32768,-32768,-32768,   180,   180,-32768,   180,
-32768,   180,-32768,-32768,  2781,   180,-32768,-32768,-32768,-32768,
-32768,-32768,   184,-32768,-32768,-32768,-32768,-32768,   334,-32768,
-32768,-32768,-32768,-32768,-32768,   322,-32768,-32768,-32768,   489,
    36,   695,-32768,   336,-32768,   341,   424,-32768,   424,-32768,
-32768,-32768,-32768,-32768,-32768,   -24,   384,    81,-32768,-32768,
-32768,-32768,   -33,   342,-32768,-32768,-32768,-32768,   338,   489,
    36,-32768,-32768,-32768,    91,-32768,-32768,-32768,-32768,-32768,
-32768,   180,-32768,-32768,-32768,   -11,-32768,-32768,-32768,-32768,
-32768,   195,   443,-32768,-32768,-32768,-32768,   180,    34,-32768,
-32768,-32768,   203,-32768,-32768,-32768,   207,  2933,-32768,   208,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,   180,   209,-32768,-32768,
-32768,   180,   120,-32768,-32768,   217,-32768,   180,   376,-32768,
-32768,-32768,-32768,-32768,-32768,   180,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,    28,-32768,-32768,-32768,   -42,   377,-32768,
-32768,-32768,   -33,   229,-32768,   230,-32768,-32768,   410,   424,
-32768,   -85,-32768,   238,-32768,-32768,-32768,-32768,   240,-32768,
-32768,   180,   180,-32768,-32768,   271,   298,-32768,-32768,-32768,
-32768,   180,   180,-32768,   241,-32768,-32768,   180,-32768,-32768,
-32768,-32768,   180,-32768,-32768,-32768,-32768,    66,-32768,-32768,
   155,-32768,-32768,-32768,   396,-32768,   369,-32768,-32768,-32768,
-32768,  2933,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
   404,-32768,-32768,-32768,  2933,  2933,  2933,  2933,  2933,  2933,
  2933,  2933,  2933,  2933,  2933,  2933,  2933,  2933,  2933,   489,
  2933,-32768,  2933,  2933,   489,  2933,-32768,  2933,  2933,  2933,
-32768,  3209,   411,-32768,-32768,  3209,  3209,   821,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
   267,  3209,-32768,-32768,   180,-32768,   443,    96,    69,-32768,
   180,-32768,     6,   180,-32768,-32768,-32768,   150,   150,-32768,
   291,-32768,-32768,   740,-32768,-32768,-32768,   468,   268,   270,
-32768,   180,-32768,-32768,-32768,-32768,-32768,-32768,-32768,   280,
   160,-32768,-32768,-32768,-32768,   271,-32768,-32768,-32768,-32768,
   282,-32768,-32768,   443,   180,-32768,-32768,-32768,-32768,-32768,
    96,-32768,     6,-32768,   280,   160,-32768,-32768,-32768,   180,
   676,-32768,-32768,-32768,    74,-32768,-32768,-32768,-32768,-32768,
   423,  3209,   442,   986,   162,-32768,   180,   180,-32768,-32768,
   180,-32768,  1982,-32768,   986,   389,-32768,    60,-32768,-32768,
-32768,-32768,   410,-32768,-32768,   180,-32768,   398,  2933,-32768,
   295,   529,-32768,   103,-32768,-32768,   437,-32768,-32768,-32768,
   553,-32768,-32768,-32768,   306,    88,    88,   313,    88,    88,
    88,    88,    88,-32768,-32768,  1287,-32768,  3354,   316,   316,
   316,    86,   316,    86,   316,    86,   316,    86,    86,    86,
   316,   316,-32768,    86,    86,   316,   327,  3354,   325,  2134,
-32768,-32768,  3019,  2933,  2933,  2933,  2933,  2933,  2933,  2933,
  2933,  2933,-32768,  2933,-32768,  2933,  2933,  2933,-32768,  2933,
-32768,-32768,  2933,  2933,  2933,  2933,  2933,  2933,-32768,   945,
  2933,-32768,-32768,-32768,-32768,-32768,-32768,   180,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,   180,   180,
-32768,-32768,   558,  2781,-32768,   334,-32768,-32768,-32768,   180,
-32768,-32768,-32768,-32768,   180,-32768,-32768,-32768,   461,-32768,
   180,   469,   291,   291,   917,   389,-32768,-32768,-32768,   434,
   714,   319,    88,   326,   472,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,   180,-32768,-32768,-32768,   917,   180,
-32768,-32768,   180,-32768,-32768,   474,-32768,-32768,-32768,-32768,
-32768,   424,   -19,-32768,   476,   483,-32768,   324,-32768,-32768,
-32768,-32768,   180,-32768,-32768,-32768,    93,-32768,  3209,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,   180,-32768,-32768,
-32768,-32768,-32768,-32768,   132,   132,   424,-32768,   132,   132,
-32768,-32768,-32768,   344,-32768,  2933,-32768,  3209,-32768,  1287,
   876,   114,   114,   876,  1714,  3244,  1714,  1714,  1714,  1714,
    86,  1714,   284,   350,   114,   114,    86,    86,   104,-32768,
-32768,  3209,-32768,   584,   584,   345,-32768,-32768,   -69,-32768,
-32768,-32768,     6,   180,-32768,-32768,   353,   354,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,   424,-32768,   355,-32768,
   180,    28,-32768,   821,   740,-32768,   138,    88,-32768,   180,
    51,-32768,-32768,    51,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,   180,-32768,-32768,-32768,   358,-32768,-32768,   180,   359,
  2933,  2933,   752,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
   180,   180,   180,-32768,   506,   424,   424,-32768,   424,   917,
   740,-32768,-32768,-32768,   138,-32768,-32768,-32768,-32768,-32768,
    -4,-32768,    -4,-32768,-32768,    18,-32768,    51,-32768,  3120,
  3244,   382,   422,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,    51,-32768,-32768,   180,    65,   180,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,   616,   618,-32768
};

static const short yypgoto[] = {-32768,
-32768,  -439,   102,   200,-32768,-32768,-32768,-32768,-32768,   328,
  -141,  -149,  -662,  -309,-32768,    -6,  -122,  -373,  -671,-32768,
-32768,    16,-32768,  -279,-32768,-32768,-32768,   541,   -95,-32768,
-32768,   352,-32768,   157,   323,   538,   -25,-32768,-32768,-32768,
-32768,  -398,  -145,  -269,  -307,  -157,-32768,-32768,-32768,-32768,
-32768,    48,-32768,  -132,    38,-32768,-32768,  -110,-32768,  -787,
  -259,  -255,  -289,-32768,-32768,-32768,  -166,  -506,     0,     2,
    32,   133,    20,   -15,  2849,   331,-32768,   -52,   477,-32768,
-32768,   -76,   -43,-32768,-32768,-32768,-32768,    31,-32768,   557,
    79,-32768,   346,-32768,-32768,-32768,  -207,    84,   572,    37,
   163,-32768,-32768,-32768,-32768,-32768,  -790,  -304,-32768,-32768,
    99,-32768,-32768,-32768,-32768,    78,-32768,    59,-32768,  -324,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,   166,-32768,-32768,
   169,-32768,-32768,-32768,-32768,  -187,-32768,-32768,-32768,-32768,
-32768,-32768,  -257
};


#define	YYLAST		3604


static const short yytable[] = {   163,
   607,   164,   538,   308,   540,   548,   539,   315,   364,   196,
   197,   198,   199,   200,   201,   430,   202,   203,   204,   205,
   206,   207,   208,   209,   568,   210,   211,   212,   213,   214,
   215,   165,   184,   186,   308,   188,   368,   577,   279,   192,
   193,   194,   217,   369,   221,   222,   225,   370,   700,   226,
   371,   937,   227,   609,   228,   229,   230,   231,   232,   233,
   275,   372,   234,   294,   398,   329,   632,   239,   307,   333,
   373,   865,   866,   280,   315,   302,   526,   409,   732,   596,
   733,   559,   879,   399,   527,   163,   312,   164,   163,   367,
   164,   569,   300,   163,   323,   164,   728,   932,   180,   425,
   543,   349,   544,   943,   549,   301,   879,   729,   334,   737,
   235,   235,   404,   235,   403,   235,   235,   574,   727,   356,
   738,   360,   316,   921,   421,   182,   163,   304,   164,   815,
   816,   368,   818,   819,   820,   821,   822,   586,   369,   280,
   405,   181,   370,   960,   587,   371,   898,   -41,   386,   305,
   163,   163,   164,   164,   413,   414,   422,   969,   423,   417,
   418,   550,   922,   372,   938,   767,   761,   416,  -149,  -149,
   762,     3,   373,   425,   575,   406,   633,   259,   899,     9,
   410,   163,   165,   165,   634,   939,   165,   411,   600,   316,
   526,   407,   392,   560,   263,   676,   187,   677,   527,   588,
   183,   528,   433,   570,   434,   165,   296,   427,   730,   484,
   485,   297,   488,   636,  -456,   637,   -47,   189,   264,   636,
   739,   637,   281,   615,   601,   746,   372,   361,   561,   284,
   540,   589,   791,   529,     3,   373,   636,   185,   637,     7,
   394,   522,     9,   524,   404,   362,   887,   190,   278,   -42,
   488,   295,   309,   191,   310,   271,   578,   547,   -46,   163,
  -432,   525,   940,   400,   763,  -533,   163,   879,   163,   965,
  -149,   966,  -149,   245,   395,   734,   752,  -554,   246,   247,
   248,   427,   488,   792,   298,   100,   271,   -48,   281,   163,
   299,   566,   782,  -472,   547,   638,   396,   489,   490,   491,
   492,   493,   494,   495,   496,   497,   392,   406,   687,   498,
   499,   885,   163,   314,   500,   501,   502,   976,   504,   488,
  -475,   505,   428,   407,   506,   392,   639,   125,   507,   508,
   319,   509,   639,   510,   697,   698,   245,   514,   392,   429,
  -482,   246,   247,   248,   783,  -149,  -149,  -149,   100,   639,
   380,   381,-32768,   698,   249,   285,     3,   321,   425,   134,
   695,   696,   697,   698,     9,   676,   324,   677,   302,   286,
   322,   287,   288,   325,   289,   326,   635,   327,   642,   643,
   392,   935,   640,   641,   642,   643,   743,   744,   332,   163,
   125,   330,   331,  -559,   933,   350,   428,   368,   800,   640,
   641,   642,   643,   572,   369,   351,   352,   290,   370,   801,
   237,   371,   238,   429,   240,   241,   387,   382,   132,   585,
   388,   390,   134,   -70,   393,  -357,   415,  -535,   784,   424,
   291,   435,   483,     3,   488,   425,   503,   -94,   515,   521,
   541,     9,   752,     3,   931,   542,   563,   266,   594,  -566,
   426,     9,     3,   599,   425,   565,   590,   595,   245,   603,
     9,   591,   593,   246,   247,   248,   427,   605,   602,   163,
   100,   663,   364,   292,   163,   606,   667,     3,   687,   608,
   604,   610,  -456,   611,   612,     9,   620,   552,   621,   629,
   222,   625,   690,   540,   802,   538,   758,   553,     3,   539,
   644,   554,   626,   622,   623,   645,     9,   896,   607,   803,
   804,   647,   125,   627,   628,   699,   163,   555,   723,   630,
   746,   774,   755,   756,   631,   404,   692,   779,   693,   694,
   695,   696,   697,   698,   759,   245,   766,   163,   798,   754,
   246,   247,   248,   427,   134,   245,   780,   100,   399,   810,
   246,   247,   248,   405,   245,   777,   813,   100,   814,   246,
   247,   248,   427,   163,   817,   698,   100,   825,   826,   856,
   808,   862,   886,   864,   888,   532,   903,   883,   895,   245,
   163,   428,   164,   900,   246,   247,   248,   356,   556,   125,
   901,   100,   916,   914,   163,   911,   795,   920,   429,   125,
   245,   926,   927,   929,   407,   246,   247,   248,   125,   946,
   955,   949,   100,   971,   972,   979,   726,   980,   567,   893,
   959,   134,   736,   882,   945,   742,   540,   752,   796,   293,
   858,   134,   579,   125,   562,   311,   897,  -419,   968,   905,
   134,   781,   790,   757,   889,   962,   724,   857,   844,   306,
   910,   576,   807,   775,   125,   924,   773,   277,   428,   974,
   809,   789,   778,   823,   482,   134,   768,   919,   486,   771,
   717,   487,     0,   752,   718,   429,     0,   428,     0,     0,
     0,   776,   753,   861,     0,     3,   134,     0,     0,     0,
     7,     0,   581,     9,   429,     0,     0,     0,   785,   786,
     0,     0,   787,     0,   890,     0,     0,     0,     0,     0,
   928,     0,     0,     0,     0,   892,   753,   797,   851,    13,
    14,    15,    16,    17,    18,    19,    20,    21,    22,     0,
     0,     0,     0,     0,   902,     0,     0,     0,    13,    14,
    15,    16,    17,    18,    19,    20,    21,    22,     0,   163,
     0,   754,     0,     0,     0,     0,     0,     0,     0,   956,
   957,     0,   958,     0,    13,    14,    15,    16,    17,    18,
    19,    20,    21,    22,     0,     0,     0,     0,     0,     0,
     0,   163,     0,     0,     0,     0,     0,   245,     0,   907,
     0,     0,   246,   247,   248,     0,     0,     0,   532,   100,
   915,     0,     0,     0,   592,     0,     0,   923,   392,   853,
     0,     0,     0,     0,     0,     0,   163,     0,     0,     0,
   854,   855,     0,     0,     0,     0,     0,     0,     0,     0,
     0,   859,     0,   676,     0,   677,   860,   109,     0,     0,
   112,   125,   863,   532,     0,    13,    14,    15,    16,    17,
    18,    19,    20,    21,    22,   947,   109,     0,     0,   112,
     0,     0,     0,     0,     0,     0,   891,     0,     0,     0,
     0,   894,     0,   134,   863,     0,   163,     0,     0,     0,
     0,     0,   109,   963,     0,   112,     0,     0,   795,     0,
     0,   967,     0,     0,   904,     0,     0,     0,     0,     0,
     0,   973,     0,     0,     0,     0,     0,     0,     0,   908,
     0,   674,     0,     0,     0,     0,     0,   961,   646,     0,
     0,     0,   977,     0,     0,   163,   163,     0,   163,     0,
     0,   648,   649,   650,   651,   652,   653,   654,   655,   656,
   657,   658,   659,   660,   661,   662,   687,   664,   533,   665,
   666,     0,   668,     0,   671,   672,   673,   676,     0,   677,
     0,     0,     0,   109,     0,   925,   112,   533,   884,    13,
    14,    15,    16,    17,    18,    19,    20,    21,    22,     0,
     0,     0,   930,   606,     0,     0,     0,     0,     0,     0,
     0,   936,     0,   748,   692,     0,   693,   694,   695,   696,
   697,   698,     0,   944,     0,     0,     0,     0,     0,     0,
   948,     0,     0,     0,     0,     0,     0,     0,     0,     0,
   867,     0,   952,   953,   954,     0,   679,   868,   869,   870,
    92,   871,   872,   873,   874,   875,   876,     0,    99,     0,
     0,     0,     0,     0,   681,     0,     0,   682,     0,     0,
   683,     0,     0,     0,     0,     0,     0,     0,     0,   684,
     0,     0,     0,     0,     0,   685,   686,     0,   975,   797,
   687,     0,   688,     0,   533,     0,   689,     0,     0,     0,
     0,     0,     0,     0,   690,     0,     0,   109,     0,   335,
   112,     0,     0,   691,     0,   799,   336,   337,   338,   339,
   340,   341,   342,   343,   344,   345,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,   692,     0,
   693,   694,   695,   696,   697,   698,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,   828,     0,     0,     0,
   830,   831,   832,   833,   834,   835,   836,   837,   838,     0,
   839,     0,   840,   841,   842,   877,   843,     0,     0,   845,
   846,   847,   848,   849,   850,     0,     0,   852,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,    -1,     1,     0,   748,     0,
     0,     0,     0,     2,     0,     3,     0,     4,     5,     6,
     7,     0,     8,     9,    10,  -247,    11,    12,     0,     0,
    13,    14,    15,    16,    17,    18,    19,    20,    21,    22,
     0,    23,    24,    25,    26,    27,    28,    29,    30,    31,
    32,    33,    34,    35,    36,    37,    38,    39,    40,  -247,
    41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
    51,    52,    53,    54,    55,    56,    57,    58,    59,    60,
    61,  -247,    62,    63,    64,    65,    66,    67,    68,    69,
    70,    71,    72,    73,    74,    75,     0,    76,    77,    78,
    79,    80,     0,    81,    82,    83,    84,    85,     0,    86,
     0,    87,   913,     0,    88,     0,    89,    90,    91,    92,
    93,    94,    95,    96,    97,    98,     0,    99,     0,   100,
     0,   101,   102,   103,     0,     0,   104,   105,     0,   106,
     0,     0,     0,   107,   108,     0,     0,     0,   109,   110,
   111,   112,     0,   113,     0,     0,     0,   114,   115,   116,
   117,   118,   119,   120,   121,   122,   123,     0,     0,     0,
   124,   125,     0,     0,     0,   126,     0,     0,   676,     0,
   677,     0,     0,   127,     0,   128,   129,   130,     0,     0,
     0,     0,   -81,   131,     0,     0,     0,   950,   951,   132,
     0,   133,   242,   134,   135,     0,   243,   244,   136,   137,
   138,     3,   139,   140,     0,   141,     7,     0,   142,     9,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,   143,   144,     0,     0,     0,   145,
     0,   146,   147,   148,   149,     0,     0,   679,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,   150,
     0,   151,     0,     0,     0,   681,     0,     0,   682,     0,
     0,   683,     0,     0,     0,     0,     0,     0,     0,     0,
   684,     0,     0,     0,     0,     0,   685,   686,     0,     0,
     0,   687,     0,   688,     0,     0,     0,   689,     0,     0,
     0,     0,     0,     0,     0,   690,     0,     0,     0,     0,
     0,     0,     0,   245,   691,     0,     0,     0,   246,   247,
   248,     0,     0,     0,     0,   100,     0,     0,     0,     0,
     0,   249,   250,   251,     0,     0,     0,   252,     0,   692,
     0,   693,   694,   695,   696,   697,   698,     0,   253,   254,
   255,   256,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,   257,     0,   125,     0,     0,
     0,     0,   258,     0,     0,     0,     0,     0,     0,     0,
   259,     0,     0,     0,   260,     0,     0,     0,   -79,     0,
     0,     0,     0,     0,     0,   132,     0,     0,     0,   134,
     0,     0,     0,     0,     0,     0,     0,   261,     0,     0,
     0,     0,   262,     0,     0,     0,     0,   263,     0,     0,
     0,   264,     0,   265,   266,     0,     0,   267,     0,   268,
     0,     0,   269,     0,     0,     1,     0,     0,     0,     0,
     0,     0,     2,     0,     3,     0,     4,     5,     6,     7,
   270,     8,     9,    10,  -247,    11,    12,     0,   271,    13,
    14,    15,    16,    17,    18,    19,    20,    21,    22,     0,
    23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
    33,    34,    35,    36,    37,    38,    39,    40,  -247,    41,
    42,    43,    44,    45,    46,    47,    48,    49,    50,    51,
    52,    53,    54,    55,    56,    57,    58,    59,    60,    61,
  -247,    62,    63,    64,    65,    66,    67,    68,    69,    70,
    71,    72,    73,    74,    75,     0,    76,    77,    78,    79,
    80,     0,    81,    82,    83,    84,    85,     0,    86,     0,
    87,     0,     0,    88,     0,    89,    90,    91,    92,    93,
    94,    95,    96,    97,    98,     0,    99,     0,   100,     0,
   101,   102,   103,     0,     0,   104,   105,     0,   106,     0,
     0,     0,   107,   108,     0,     0,     0,   109,   110,   111,
   112,     0,   113,     0,     0,     0,   114,   115,   116,   117,
   118,   119,   120,   121,   122,   123,     0,     0,     0,   124,
   125,     0,     0,     0,   126,   676,     0,   677,     0,     0,
     0,     0,   127,     0,   128,   129,   130,     0,     0,     0,
     0,   -81,   131,     0,     0,     0,     0,     0,   132,     0,
   133,     0,   134,   135,     0,     0,     0,   136,   137,   138,
   419,   139,   140,     0,   141,     0,   420,   142,  -249,  -249,
     0,  -249,     0,     0,     0,  -249,     0,  -249,     0,  -249,
     0,     0,  -249,   143,   144,     0,     0,     0,   145,     0,
   146,   147,   148,   149,-32768,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,   150,     0,
   151,     0,-32768,     0,     0,-32768,     0,     0,   683,     0,
     0,     0,     0,     0,     0,     0,     0,-32768,  -249,     0,
     0,     0,     0,   685,-32768,     0,     0,     0,   687,     0,
-32768,     0,     0,     0,   689,     0,     0,     0,     0,     0,
     0,     0,   690,     0,     0,     0,     0,     0,     0,     0,
     0,   691,     0,  -249,  -249,     0,     0,  -249,     0,     0,
  -249,  -249,  -249,  -249,  -249,  -249,  -249,  -249,  -249,  -249,
     0,     0,  -249,  -249,     0,     0,   692,     0,   693,   694,
   695,   696,   697,   698,     0,     0,  -249,     0,     0,  -249,
     0,     0,     0,     0,     0,     0,     0,     0,     0,  -249,
     0,     0,   355,     0,     0,     0,     0,     0,     0,     0,
  -247,  -247,     0,  -247,     0,  -249,  -249,  -247,     0,  -247,
     0,  -247,  -249,  -249,  -247,     0,     0,     0,     0,     0,
     0,     0,     0,     0,  -249,     0,     0,     0,  -249,     0,
     0,  -249,     0,     0,     0,     0,     0,  -249,     0,     0,
     0,  -249,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,  -249,  -249,  -249,  -249,     0,  -249,     0,
  -247,     0,     0,  -249,  -249,  -249,  -249,     0,     0,     0,
     0,     0,  -249,     0,  -249,     0,     0,     0,     0,  -249,
     0,  -249,  -249,     0,  -249,  -249,     0,     0,     0,     0,
     0,  -249,     0,     0,     0,  -247,  -247,     0,     0,  -247,
     0,     0,  -247,  -247,  -247,  -247,  -247,  -247,  -247,  -247,
  -247,  -247,     0,     0,  -247,  -247,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,  -247,     0,
     0,  -247,     0,     0,     0,     0,     0,     0,     0,     0,
     0,  -247,     0,     0,   827,     0,     0,     0,     0,     0,
     0,     0,   436,     3,     0,   437,     0,  -247,  -247,   438,
     0,   439,     0,   440,  -247,  -247,   441,     0,     0,     0,
     0,     0,     0,     0,     0,     0,  -247,     0,     0,     0,
  -247,     0,     0,  -247,     0,     0,     0,     0,     0,  -247,
     0,     0,     0,  -247,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,  -247,  -247,  -247,  -247,     0,
  -247,     0,   442,     0,     0,  -247,  -247,  -247,  -247,     0,
     0,     0,     0,     0,  -247,     0,  -247,     0,     0,     0,
     0,  -247,     0,  -247,  -247,     0,  -247,  -247,     0,     0,
     0,     0,     0,  -247,     0,     0,     0,   443,   444,     0,
     0,   445,     0,     0,   446,   245,   447,   448,   449,   450,
   246,   247,   451,   452,     0,     0,   453,   100,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
   454,     0,     0,   455,     0,     0,     0,     0,     0,     0,
     0,     0,     0,   456,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,   125,
   457,     0,     0,     0,     0,     0,   458,   459,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,   460,     0,
     0,     0,   461,     0,     0,   462,     0,     0,     0,     0,
     0,   134,     0,     0,     0,   463,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,   464,   465,   466,
   467,     0,   468,     0,     0,     0,     0,   469,   470,   471,
   472,     0,     0,     0,     0,     0,   473,     0,   474,     0,
     0,     0,     0,   475,     0,   476,   477,     2,   478,   479,
     0,     0,     5,     6,     0,   480,     8,     0,    10,     0,
    11,    12,     0,     0,    13,    14,    15,    16,    17,    18,
    19,    20,    21,    22,     0,    23,    24,    25,    26,    27,
    28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
    38,    39,    40,     0,    41,    42,    43,    44,    45,    46,
    47,    48,    49,    50,    51,    52,    53,    54,    55,    56,
    57,    58,    59,    60,    61,     0,    62,    63,    64,    65,
    66,    67,    68,    69,    70,    71,    72,    73,    74,    75,
     0,    76,    77,    78,    79,    80,     0,    81,    82,    83,
    84,    85,     0,     0,     0,    87,     0,     0,   383,     0,
     0,     0,   384,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,   101,   102,   103,     0,     0,
     0,     0,     0,   106,     0,     0,     0,   107,   108,     0,
     0,     0,   109,     0,   111,   112,     0,   113,     0,     0,
     0,   114,   115,   116,   117,   118,   119,   120,   121,   122,
   123,     0,     0,     0,   124,     0,     0,     0,     0,   126,
     0,     0,     0,     0,     0,     0,     0,   127,     0,   128,
   129,   130,     0,     0,     0,     0,     0,   131,     0,     0,
     0,     0,     0,   132,     0,   133,     0,     0,   135,     0,
     0,     0,   136,   137,   138,     0,     0,     0,     0,   141,
     0,     0,   142,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,   143,   144,
     0,     0,     0,   145,     0,   146,   147,   148,   149,     0,
     0,     2,     0,     0,     0,     0,     5,     6,     0,     0,
     8,     0,    10,   385,    11,    12,     0,     0,    13,    14,
    15,    16,    17,    18,    19,    20,    21,    22,     0,    23,
    24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
    34,    35,    36,    37,    38,    39,    40,     0,    41,    42,
    43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
    53,    54,    55,    56,    57,    58,    59,    60,    61,     0,
    62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
    72,    73,    74,    75,     0,    76,    77,    78,    79,    80,
     0,    81,    82,    83,    84,    85,     0,     0,     0,    87,
     0,     0,   383,     0,     0,     0,   384,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,   101,
   102,   103,     0,     0,     0,     0,     0,   106,     0,     0,
     0,   107,   108,     0,     0,     0,   109,     0,   111,   112,
     0,   113,     0,     0,     0,   114,   115,   116,   117,   118,
   119,   120,   121,   122,   123,     0,     0,     0,   124,     0,
     0,     0,     0,   126,     0,     0,     0,     0,     0,     0,
     0,   127,     0,   128,   129,   130,     0,     0,     0,   436,
     3,   131,   437,     0,     0,     0,   438,   132,   439,   133,
   440,     0,   135,   441,   511,     0,   136,   137,   138,     0,
     0,     0,     0,   141,     0,     0,   142,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,   143,   144,     0,     0,     0,   145,     0,   146,
   147,   148,   149,     0,     0,     0,     0,     0,     0,   442,
     0,     0,     0,     0,     0,     0,     0,  -527,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,   443,   444,     0,     0,   445,     0,
     0,   446,   245,   447,   448,   449,   450,   246,   247,   451,
   452,     0,     0,   453,   100,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,   454,     0,     0,
   455,     0,     0,     0,     0,     0,     0,     0,     0,     0,
   456,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,   436,     3,     0,   437,     0,   125,   457,   438,     0,
   439,     0,   440,   458,   459,   441,     0,     0,     0,     0,
     0,     0,     0,     0,     0,   460,     0,     0,     0,   461,
     0,     0,   462,     0,     0,     0,     0,     0,   134,     0,
     0,     0,   463,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,   464,   465,   466,   467,     0,   468,
     0,   442,     0,     0,   469,   470,   471,   472,     0,     0,
     0,     0,     0,   473,     0,   474,     0,     0,     0,     0,
   475,     0,   476,   477,     0,   478,   479,     0,     0,     0,
     0,     0,   480,     0,     0,     0,   443,   444,     0,     0,
   445,     0,     0,   446,   245,   447,   448,   449,   450,   246,
   247,   451,   452,     0,   674,   453,   100,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,   454,
     0,     0,   455,     0,     0,     0,     0,     0,     0,     0,
     0,     0,   456,     0,     0,     0,     0,     0,   675,     0,
     0,     0,     0,     0,     0,     0,     0,     0,   125,   457,
   676,     0,   677,     0,     0,   458,   459,     0,     0,     0,
   678,     0,     0,     0,     0,     0,     0,   460,     0,     0,
     0,   461,     0,     0,   462,     0,     0,     0,     0,     0,
   134,     0,     0,     0,   463,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,   464,   465,   466,   467,
     0,   468,     0,     0,     0,   674,   469,   470,   471,   472,
     0,     0,     0,     0,     0,   473,     0,   474,     0,   679,
     0,     0,   475,     0,   476,   477,     0,   478,   479,     0,
     0,     0,     0,     0,   480,     0,   680,   681,     0,   675,
   682,     0,     0,   683,     0,     0,     0,     0,     0,     0,
     0,   676,   684,   677,     0,     0,     0,     0,   685,   686,
     0,   678,     0,   687,     0,   688,     0,     0,     0,   689,
     0,     0,     0,     0,     0,     0,     0,   690,     0,     0,
     0,     0,     0,     0,     0,     0,   691,     0,     0,     0,
     0,     0,     0,     0,   674,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,   692,     0,   693,   694,   695,   696,   697,   698,     0,
   679,   829,     0,     0,     0,     0,     0,     0,   675,   674,
     0,     0,     0,     0,     0,     0,     0,   680,   681,     0,
   676,   682,   677,     0,   683,     0,     0,     0,     0,     0,
   678,     0,     0,   684,     0,     0,     0,     0,     0,   685,
   686,     0,     0,   675,   687,     0,   688,     0,     0,     0,
   689,     0,     0,     0,     0,   676,     0,   677,   690,     0,
     0,     0,     0,     0,     0,   678,     0,   691,   703,   704,
   705,   706,   707,   708,   709,   710,   711,   712,   713,   714,
   715,     0,   716,     0,     0,   719,   720,   721,   722,   679,
     0,     0,   692,     0,   693,   694,   695,   696,   697,   698,
     0,     0,   970,     0,     0,     0,   680,   681,     0,     0,
   682,     0,     0,   683,     0,     0,     0,     0,     0,   674,
     0,     0,   684,     0,   679,     0,     0,     0,   685,   686,
     0,     0,     0,   687,     0,   688,     0,     0,     0,   689,
     0,-32768,   681,     0,     0,   682,     0,   690,   683,     0,
   772,     0,     0,   675,     0,     0,   691,   684,     0,     0,
     0,     0,     0,   685,   686,   676,     0,   677,   687,     0,
   688,     0,     0,     0,   689,   678,     0,     0,     0,     0,
   788,   692,   690,   693,   694,   695,   696,   697,   698,     0,
     0,   691,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,   811,     0,   812,     0,
     0,     0,     0,     0,     0,     0,   692,     0,   693,   694,
   695,   696,   697,   698,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,   679,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,   681,     0,     0,   682,     0,     0,   683,     0,
     0,     0,     0,     0,     0,     0,     0,   684,     0,     0,
     0,     0,     0,   685,   686,     0,     0,     0,   687,     0,
   688,     0,     0,     0,   689,     0,     0,     0,     0,     0,
     0,     0,   690,     0,     0,     0,     0,     0,     0,     0,
     0,   691,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,   692,     0,   693,   694,
   695,   696,   697,   698
};

static const short yycheck[] = {     0,
   374,     0,   262,     5,   262,   275,   262,     1,   141,    25,
    26,    27,    28,    29,    30,   182,    32,    33,    34,    35,
    36,    37,    38,    39,   294,    41,    42,    43,    44,    45,
    46,     0,    13,    14,     5,    16,     9,   307,     6,    20,
    21,    22,    58,    16,    60,    61,    62,    20,   488,    65,
    23,     1,    68,   378,    70,    71,    72,    73,    74,    75,
    86,   104,    78,    89,     1,   118,     1,    83,    94,   122,
   113,   743,   744,   107,     1,    91,    41,     1,    10,   349,
    12,     1,   745,    20,    49,    86,   102,    86,    89,   142,
    89,     1,   132,    94,   110,    94,     1,   885,   254,    12,
   267,   127,   269,   894,   129,   145,   769,    12,   124,   104,
    79,    80,   142,    82,   167,    84,    85,   129,   517,   135,
   115,   137,   116,   193,   177,   250,   127,   149,   127,   636,
   637,     9,   639,   640,   641,   642,   643,   104,    16,   107,
   170,   137,    20,   931,   111,    23,   166,   187,   155,   171,
   151,   152,   151,   152,   170,   171,     1,   948,     3,   175,
   176,   186,   232,   104,   114,   564,     7,   174,   254,   255,
    11,    10,   113,    12,   186,   205,   111,   179,   198,    18,
   104,   182,   151,   152,   119,   135,   155,   111,    69,   116,
    41,   221,   161,   113,   216,    82,   105,    84,    49,   166,
   104,   166,   183,   113,   185,   174,   144,   120,   113,   190,
   191,   149,   255,    82,   254,    84,   187,   105,   220,    82,
   215,    84,   256,   390,   105,   230,   104,   104,   281,     5,
   488,   198,   606,   198,    10,   113,    82,   104,    84,    15,
    20,   257,    18,   259,   142,   122,   753,   105,    86,   187,
   255,    89,    96,   105,    98,   257,   309,   273,   187,   260,
   254,   260,   212,   200,   105,   254,   267,   930,   269,   941,
   253,   943,   255,   112,    54,   207,   534,   254,   117,   118,
   119,   120,   255,   608,   222,   124,   257,   187,   256,   290,
   228,   290,   131,   254,   310,   141,    76,   196,   197,   198,
   199,   200,   201,   202,   203,   204,   275,   205,   195,   208,
   209,   751,   313,   113,   213,   214,   215,   253,   217,   255,
   254,   220,   235,   221,   223,   294,   195,   166,   227,   228,
   177,   230,   195,   232,   249,   250,   112,   236,   307,   252,
   254,   117,   118,   119,   183,   253,   254,   255,   124,   195,
   151,   152,   249,   250,   130,   131,    10,   229,    12,   198,
   247,   248,   249,   250,    18,    82,   105,    84,   384,   145,
   254,   147,   148,   105,   150,   104,   429,   105,   247,   248,
   349,   888,   245,   246,   247,   248,   528,   529,   104,   390,
   166,   105,   105,   254,   257,   104,   235,     9,   104,   245,
   246,   247,   248,   302,    16,   104,   111,   183,    20,   115,
    80,    23,    82,   252,    84,    85,   249,   254,   194,   318,
   254,   187,   198,    75,   254,   254,    20,   254,   595,   249,
   206,   255,   255,    10,   255,    12,   105,   254,   105,   118,
   105,    18,   700,    10,   884,   105,   105,   223,   347,   255,
   104,    18,    10,   352,    12,   118,   254,   249,   112,   358,
    18,   255,   255,   117,   118,   119,   120,   366,   252,   470,
   124,   470,   605,   249,   475,   374,   475,    10,   195,   378,
   105,   105,   254,   254,    75,    18,   249,   104,   249,   249,
   506,   221,   209,   751,   200,   755,   549,   114,    10,   755,
   105,   118,   205,   402,   403,   137,    18,   777,   882,   215,
   216,   108,   166,   412,   413,   105,   517,   134,   252,   418,
   230,   574,   255,   254,   423,   142,   243,   105,   245,   246,
   247,   248,   249,   250,   255,   112,   255,   538,   141,   538,
   117,   118,   119,   120,   198,   112,   105,   124,    20,   113,
   117,   118,   119,   170,   112,   581,     4,   124,   253,   117,
   118,   119,   120,   564,   252,   250,   124,   241,   244,    12,
   623,   111,   254,   105,   249,   104,   253,   144,   105,   112,
   581,   235,   581,   108,   117,   118,   119,   603,   205,   166,
   108,   124,     9,   244,   595,   252,   612,   253,   252,   166,
   112,   249,   249,   249,   221,   117,   118,   119,   166,   252,
   105,   253,   124,   232,   193,     0,   515,     0,   291,   769,
   930,   198,   521,   746,   904,   524,   884,   885,   613,    89,
   726,   198,   310,   166,   283,    98,   782,   254,   946,   797,
   198,   594,   605,   542,   755,   935,   514,   724,   692,    93,
   817,   306,   622,   575,   166,   863,   573,    86,   235,   964,
   624,   603,   585,   644,   188,   198,   565,   855,   192,   571,
   505,   195,    -1,   931,   506,   252,    -1,   235,    -1,    -1,
    -1,   580,   249,   736,    -1,    10,   198,    -1,    -1,    -1,
    15,    -1,   250,    18,   252,    -1,    -1,    -1,   597,   598,
    -1,    -1,   601,    -1,   757,    -1,    -1,    -1,    -1,    -1,
   877,    -1,    -1,    -1,    -1,   768,   249,   616,   699,    25,
    26,    27,    28,    29,    30,    31,    32,    33,    34,    -1,
    -1,    -1,    -1,    -1,   787,    -1,    -1,    -1,    25,    26,
    27,    28,    29,    30,    31,    32,    33,    34,    -1,   750,
    -1,   750,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   926,
   927,    -1,   929,    -1,    25,    26,    27,    28,    29,    30,
    31,    32,    33,    34,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,   782,    -1,    -1,    -1,    -1,    -1,   112,    -1,   805,
    -1,    -1,   117,   118,   119,    -1,    -1,    -1,   104,   124,
   853,    -1,    -1,    -1,   328,    -1,    -1,   860,   777,   708,
    -1,    -1,    -1,    -1,    -1,    -1,   817,    -1,    -1,    -1,
   719,   720,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,   730,    -1,    82,    -1,    84,   735,   143,    -1,    -1,
   146,   166,   741,   104,    -1,    25,    26,    27,    28,    29,
    30,    31,    32,    33,    34,   908,   143,    -1,    -1,   146,
    -1,    -1,    -1,    -1,    -1,    -1,   765,    -1,    -1,    -1,
    -1,   770,    -1,   198,   773,    -1,   877,    -1,    -1,    -1,
    -1,    -1,   143,   936,    -1,   146,    -1,    -1,   904,    -1,
    -1,   944,    -1,    -1,   793,    -1,    -1,    -1,    -1,    -1,
    -1,   954,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   808,
    -1,    36,    -1,    -1,    -1,    -1,    -1,   933,   442,    -1,
    -1,    -1,   975,    -1,    -1,   926,   927,    -1,   929,    -1,
    -1,   455,   456,   457,   458,   459,   460,   461,   462,   463,
   464,   465,   466,   467,   468,   469,   195,   471,   254,   473,
   474,    -1,   476,    -1,   478,   479,   480,    82,    -1,    84,
    -1,    -1,    -1,   143,    -1,   864,   146,   254,   255,    25,
    26,    27,    28,    29,    30,    31,    32,    33,    34,    -1,
    -1,    -1,   881,   882,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,   890,    -1,   254,   243,    -1,   245,   246,   247,   248,
   249,   250,    -1,   902,    -1,    -1,    -1,    -1,    -1,    -1,
   909,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
   104,    -1,   921,   922,   923,    -1,   151,   111,   112,   113,
   114,   115,   116,   117,   118,   119,   120,    -1,   122,    -1,
    -1,    -1,    -1,    -1,   169,    -1,    -1,   172,    -1,    -1,
   175,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   184,
    -1,    -1,    -1,    -1,    -1,   190,   191,    -1,   967,   968,
   195,    -1,   197,    -1,   254,    -1,   201,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,   209,    -1,    -1,   143,    -1,   104,
   146,    -1,    -1,   218,    -1,   619,   111,   112,   113,   114,
   115,   116,   117,   118,   119,   120,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   243,    -1,
   245,   246,   247,   248,   249,   250,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,   670,    -1,    -1,    -1,
   674,   675,   676,   677,   678,   679,   680,   681,   682,    -1,
   684,    -1,   686,   687,   688,   249,   690,    -1,    -1,   693,
   694,   695,   696,   697,   698,    -1,    -1,   701,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,     0,     1,    -1,   254,    -1,
    -1,    -1,    -1,     8,    -1,    10,    -1,    12,    13,    14,
    15,    -1,    17,    18,    19,    20,    21,    22,    -1,    -1,
    25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
    -1,    36,    37,    38,    39,    40,    41,    42,    43,    44,
    45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
    55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
    65,    66,    67,    68,    69,    70,    71,    72,    73,    74,
    75,    76,    77,    78,    79,    80,    81,    82,    83,    84,
    85,    86,    87,    88,    89,    90,    -1,    92,    93,    94,
    95,    96,    -1,    98,    99,   100,   101,   102,    -1,   104,
    -1,   106,   826,    -1,   109,    -1,   111,   112,   113,   114,
   115,   116,   117,   118,   119,   120,    -1,   122,    -1,   124,
    -1,   126,   127,   128,    -1,    -1,   131,   132,    -1,   134,
    -1,    -1,    -1,   138,   139,    -1,    -1,    -1,   143,   144,
   145,   146,    -1,   148,    -1,    -1,    -1,   152,   153,   154,
   155,   156,   157,   158,   159,   160,   161,    -1,    -1,    -1,
   165,   166,    -1,    -1,    -1,   170,    -1,    -1,    82,    -1,
    84,    -1,    -1,   178,    -1,   180,   181,   182,    -1,    -1,
    -1,    -1,   187,   188,    -1,    -1,    -1,   911,   912,   194,
    -1,   196,     1,   198,   199,    -1,     5,     6,   203,   204,
   205,    10,   207,   208,    -1,   210,    15,    -1,   213,    18,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,   229,   230,    -1,    -1,    -1,   234,
    -1,   236,   237,   238,   239,    -1,    -1,   151,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   254,
    -1,   256,    -1,    -1,    -1,   169,    -1,    -1,   172,    -1,
    -1,   175,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
   184,    -1,    -1,    -1,    -1,    -1,   190,   191,    -1,    -1,
    -1,   195,    -1,   197,    -1,    -1,    -1,   201,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,   209,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,   112,   218,    -1,    -1,    -1,   117,   118,
   119,    -1,    -1,    -1,    -1,   124,    -1,    -1,    -1,    -1,
    -1,   130,   131,   132,    -1,    -1,    -1,   136,    -1,   243,
    -1,   245,   246,   247,   248,   249,   250,    -1,   147,   148,
   149,   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,   164,    -1,   166,    -1,    -1,
    -1,    -1,   171,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
   179,    -1,    -1,    -1,   183,    -1,    -1,    -1,   187,    -1,
    -1,    -1,    -1,    -1,    -1,   194,    -1,    -1,    -1,   198,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,   206,    -1,    -1,
    -1,    -1,   211,    -1,    -1,    -1,    -1,   216,    -1,    -1,
    -1,   220,    -1,   222,   223,    -1,    -1,   226,    -1,   228,
    -1,    -1,   231,    -1,    -1,     1,    -1,    -1,    -1,    -1,
    -1,    -1,     8,    -1,    10,    -1,    12,    13,    14,    15,
   249,    17,    18,    19,    20,    21,    22,    -1,   257,    25,
    26,    27,    28,    29,    30,    31,    32,    33,    34,    -1,
    36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
    46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
    56,    57,    58,    59,    60,    61,    62,    63,    64,    65,
    66,    67,    68,    69,    70,    71,    72,    73,    74,    75,
    76,    77,    78,    79,    80,    81,    82,    83,    84,    85,
    86,    87,    88,    89,    90,    -1,    92,    93,    94,    95,
    96,    -1,    98,    99,   100,   101,   102,    -1,   104,    -1,
   106,    -1,    -1,   109,    -1,   111,   112,   113,   114,   115,
   116,   117,   118,   119,   120,    -1,   122,    -1,   124,    -1,
   126,   127,   128,    -1,    -1,   131,   132,    -1,   134,    -1,
    -1,    -1,   138,   139,    -1,    -1,    -1,   143,   144,   145,
   146,    -1,   148,    -1,    -1,    -1,   152,   153,   154,   155,
   156,   157,   158,   159,   160,   161,    -1,    -1,    -1,   165,
   166,    -1,    -1,    -1,   170,    82,    -1,    84,    -1,    -1,
    -1,    -1,   178,    -1,   180,   181,   182,    -1,    -1,    -1,
    -1,   187,   188,    -1,    -1,    -1,    -1,    -1,   194,    -1,
   196,    -1,   198,   199,    -1,    -1,    -1,   203,   204,   205,
     1,   207,   208,    -1,   210,    -1,     7,   213,     9,    10,
    -1,    12,    -1,    -1,    -1,    16,    -1,    18,    -1,    20,
    -1,    -1,    23,   229,   230,    -1,    -1,    -1,   234,    -1,
   236,   237,   238,   239,   151,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   254,    -1,
   256,    -1,   169,    -1,    -1,   172,    -1,    -1,   175,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,   184,    69,    -1,
    -1,    -1,    -1,   190,   191,    -1,    -1,    -1,   195,    -1,
   197,    -1,    -1,    -1,   201,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,   209,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,   218,    -1,   104,   105,    -1,    -1,   108,    -1,    -1,
   111,   112,   113,   114,   115,   116,   117,   118,   119,   120,
    -1,    -1,   123,   124,    -1,    -1,   243,    -1,   245,   246,
   247,   248,   249,   250,    -1,    -1,   137,    -1,    -1,   140,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   150,
    -1,    -1,     1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
     9,    10,    -1,    12,    -1,   166,   167,    16,    -1,    18,
    -1,    20,   173,   174,    23,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,   185,    -1,    -1,    -1,   189,    -1,
    -1,   192,    -1,    -1,    -1,    -1,    -1,   198,    -1,    -1,
    -1,   202,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,   214,   215,   216,   217,    -1,   219,    -1,
    69,    -1,    -1,   224,   225,   226,   227,    -1,    -1,    -1,
    -1,    -1,   233,    -1,   235,    -1,    -1,    -1,    -1,   240,
    -1,   242,   243,    -1,   245,   246,    -1,    -1,    -1,    -1,
    -1,   252,    -1,    -1,    -1,   104,   105,    -1,    -1,   108,
    -1,    -1,   111,   112,   113,   114,   115,   116,   117,   118,
   119,   120,    -1,    -1,   123,   124,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   137,    -1,
    -1,   140,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,   150,    -1,    -1,     1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,     9,    10,    -1,    12,    -1,   166,   167,    16,
    -1,    18,    -1,    20,   173,   174,    23,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,   185,    -1,    -1,    -1,
   189,    -1,    -1,   192,    -1,    -1,    -1,    -1,    -1,   198,
    -1,    -1,    -1,   202,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,   214,   215,   216,   217,    -1,
   219,    -1,    69,    -1,    -1,   224,   225,   226,   227,    -1,
    -1,    -1,    -1,    -1,   233,    -1,   235,    -1,    -1,    -1,
    -1,   240,    -1,   242,   243,    -1,   245,   246,    -1,    -1,
    -1,    -1,    -1,   252,    -1,    -1,    -1,   104,   105,    -1,
    -1,   108,    -1,    -1,   111,   112,   113,   114,   115,   116,
   117,   118,   119,   120,    -1,    -1,   123,   124,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
   137,    -1,    -1,   140,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,   150,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   166,
   167,    -1,    -1,    -1,    -1,    -1,   173,   174,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   185,    -1,
    -1,    -1,   189,    -1,    -1,   192,    -1,    -1,    -1,    -1,
    -1,   198,    -1,    -1,    -1,   202,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,   214,   215,   216,
   217,    -1,   219,    -1,    -1,    -1,    -1,   224,   225,   226,
   227,    -1,    -1,    -1,    -1,    -1,   233,    -1,   235,    -1,
    -1,    -1,    -1,   240,    -1,   242,   243,     8,   245,   246,
    -1,    -1,    13,    14,    -1,   252,    17,    -1,    19,    -1,
    21,    22,    -1,    -1,    25,    26,    27,    28,    29,    30,
    31,    32,    33,    34,    -1,    36,    37,    38,    39,    40,
    41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
    51,    52,    53,    -1,    55,    56,    57,    58,    59,    60,
    61,    62,    63,    64,    65,    66,    67,    68,    69,    70,
    71,    72,    73,    74,    75,    -1,    77,    78,    79,    80,
    81,    82,    83,    84,    85,    86,    87,    88,    89,    90,
    -1,    92,    93,    94,    95,    96,    -1,    98,    99,   100,
   101,   102,    -1,    -1,    -1,   106,    -1,    -1,   109,    -1,
    -1,    -1,   113,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,   126,   127,   128,    -1,    -1,
    -1,    -1,    -1,   134,    -1,    -1,    -1,   138,   139,    -1,
    -1,    -1,   143,    -1,   145,   146,    -1,   148,    -1,    -1,
    -1,   152,   153,   154,   155,   156,   157,   158,   159,   160,
   161,    -1,    -1,    -1,   165,    -1,    -1,    -1,    -1,   170,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,   178,    -1,   180,
   181,   182,    -1,    -1,    -1,    -1,    -1,   188,    -1,    -1,
    -1,    -1,    -1,   194,    -1,   196,    -1,    -1,   199,    -1,
    -1,    -1,   203,   204,   205,    -1,    -1,    -1,    -1,   210,
    -1,    -1,   213,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   229,   230,
    -1,    -1,    -1,   234,    -1,   236,   237,   238,   239,    -1,
    -1,     8,    -1,    -1,    -1,    -1,    13,    14,    -1,    -1,
    17,    -1,    19,   254,    21,    22,    -1,    -1,    25,    26,
    27,    28,    29,    30,    31,    32,    33,    34,    -1,    36,
    37,    38,    39,    40,    41,    42,    43,    44,    45,    46,
    47,    48,    49,    50,    51,    52,    53,    -1,    55,    56,
    57,    58,    59,    60,    61,    62,    63,    64,    65,    66,
    67,    68,    69,    70,    71,    72,    73,    74,    75,    -1,
    77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
    87,    88,    89,    90,    -1,    92,    93,    94,    95,    96,
    -1,    98,    99,   100,   101,   102,    -1,    -1,    -1,   106,
    -1,    -1,   109,    -1,    -1,    -1,   113,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   126,
   127,   128,    -1,    -1,    -1,    -1,    -1,   134,    -1,    -1,
    -1,   138,   139,    -1,    -1,    -1,   143,    -1,   145,   146,
    -1,   148,    -1,    -1,    -1,   152,   153,   154,   155,   156,
   157,   158,   159,   160,   161,    -1,    -1,    -1,   165,    -1,
    -1,    -1,    -1,   170,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,   178,    -1,   180,   181,   182,    -1,    -1,    -1,     9,
    10,   188,    12,    -1,    -1,    -1,    16,   194,    18,   196,
    20,    -1,   199,    23,    24,    -1,   203,   204,   205,    -1,
    -1,    -1,    -1,   210,    -1,    -1,   213,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,   229,   230,    -1,    -1,    -1,   234,    -1,   236,
   237,   238,   239,    -1,    -1,    -1,    -1,    -1,    -1,    69,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,   254,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,   104,   105,    -1,    -1,   108,    -1,
    -1,   111,   112,   113,   114,   115,   116,   117,   118,   119,
   120,    -1,    -1,   123,   124,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,   137,    -1,    -1,
   140,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,     9,    10,    -1,    12,    -1,   166,   167,    16,    -1,
    18,    -1,    20,   173,   174,    23,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,   185,    -1,    -1,    -1,   189,
    -1,    -1,   192,    -1,    -1,    -1,    -1,    -1,   198,    -1,
    -1,    -1,   202,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,   214,   215,   216,   217,    -1,   219,
    -1,    69,    -1,    -1,   224,   225,   226,   227,    -1,    -1,
    -1,    -1,    -1,   233,    -1,   235,    -1,    -1,    -1,    -1,
   240,    -1,   242,   243,    -1,   245,   246,    -1,    -1,    -1,
    -1,    -1,   252,    -1,    -1,    -1,   104,   105,    -1,    -1,
   108,    -1,    -1,   111,   112,   113,   114,   115,   116,   117,
   118,   119,   120,    -1,    36,   123,   124,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   137,
    -1,    -1,   140,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,   150,    -1,    -1,    -1,    -1,    -1,    70,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   166,   167,
    82,    -1,    84,    -1,    -1,   173,   174,    -1,    -1,    -1,
    92,    -1,    -1,    -1,    -1,    -1,    -1,   185,    -1,    -1,
    -1,   189,    -1,    -1,   192,    -1,    -1,    -1,    -1,    -1,
   198,    -1,    -1,    -1,   202,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,   214,   215,   216,   217,
    -1,   219,    -1,    -1,    -1,    36,   224,   225,   226,   227,
    -1,    -1,    -1,    -1,    -1,   233,    -1,   235,    -1,   151,
    -1,    -1,   240,    -1,   242,   243,    -1,   245,   246,    -1,
    -1,    -1,    -1,    -1,   252,    -1,   168,   169,    -1,    70,
   172,    -1,    -1,   175,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    82,   184,    84,    -1,    -1,    -1,    -1,   190,   191,
    -1,    92,    -1,   195,    -1,   197,    -1,    -1,    -1,   201,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,   209,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,   218,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    36,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,   243,    -1,   245,   246,   247,   248,   249,   250,    -1,
   151,   253,    -1,    -1,    -1,    -1,    -1,    -1,    70,    36,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,   168,   169,    -1,
    82,   172,    84,    -1,   175,    -1,    -1,    -1,    -1,    -1,
    92,    -1,    -1,   184,    -1,    -1,    -1,    -1,    -1,   190,
   191,    -1,    -1,    70,   195,    -1,   197,    -1,    -1,    -1,
   201,    -1,    -1,    -1,    -1,    82,    -1,    84,   209,    -1,
    -1,    -1,    -1,    -1,    -1,    92,    -1,   218,   490,   491,
   492,   493,   494,   495,   496,   497,   498,   499,   500,   501,
   502,    -1,   504,    -1,    -1,   507,   508,   509,   510,   151,
    -1,    -1,   243,    -1,   245,   246,   247,   248,   249,   250,
    -1,    -1,   253,    -1,    -1,    -1,   168,   169,    -1,    -1,
   172,    -1,    -1,   175,    -1,    -1,    -1,    -1,    -1,    36,
    -1,    -1,   184,    -1,   151,    -1,    -1,    -1,   190,   191,
    -1,    -1,    -1,   195,    -1,   197,    -1,    -1,    -1,   201,
    -1,   168,   169,    -1,    -1,   172,    -1,   209,   175,    -1,
   572,    -1,    -1,    70,    -1,    -1,   218,   184,    -1,    -1,
    -1,    -1,    -1,   190,   191,    82,    -1,    84,   195,    -1,
   197,    -1,    -1,    -1,   201,    92,    -1,    -1,    -1,    -1,
   602,   243,   209,   245,   246,   247,   248,   249,   250,    -1,
    -1,   218,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,   628,    -1,   630,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,   243,    -1,   245,   246,
   247,   248,   249,   250,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,   151,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,   169,    -1,    -1,   172,    -1,    -1,   175,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,   184,    -1,    -1,
    -1,    -1,    -1,   190,   191,    -1,    -1,    -1,   195,    -1,
   197,    -1,    -1,    -1,   201,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,   209,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,   218,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,   243,    -1,   245,   246,
   247,   248,   249,   250
};
#define YYPURE 1

/* -*-C-*-  Note some compilers choke on comments on `#line' lines.  */
#line 3 "/usr/local/share/bison.simple"
/* This file comes from bison-1.28.  */

/* Skeleton output parser for bison,
   Copyright (C) 1984, 1989, 1990 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

/* As a special exception, when this file is copied by Bison into a
   Bison output file, you may use that output file without restriction.
   This special exception was added by the Free Software Foundation
   in version 1.24 of Bison.  */

/* This is the parser code that is written into each bison parser
  when the %semantic_parser declaration is not specified in the grammar.
  It was written by Richard Stallman by simplifying the hairy parser
  used when %semantic_parser is specified.  */

#ifndef YYSTACK_USE_ALLOCA
#ifdef alloca
#define YYSTACK_USE_ALLOCA
#else /* alloca not defined */
#ifdef __GNUC__
#define YYSTACK_USE_ALLOCA
#define alloca __builtin_alloca
#else /* not GNU C.  */
#if (!defined (__STDC__) && defined (sparc)) || defined (__sparc__) || defined (__sparc) || defined (__sgi) || (defined (__sun) && defined (__i386))
#define YYSTACK_USE_ALLOCA
#include <alloca.h>
#else /* not sparc */
/* We think this test detects Watcom and Microsoft C.  */
/* This used to test MSDOS, but that is a bad idea
   since that symbol is in the user namespace.  */
#if (defined (_MSDOS) || defined (_MSDOS_)) && !defined (__TURBOC__)
#if 0 /* No need for malloc.h, which pollutes the namespace;
	 instead, just don't use alloca.  */
#include <malloc.h>
#endif
#else /* not MSDOS, or __TURBOC__ */
#if defined(_AIX)
/* I don't know what this was needed for, but it pollutes the namespace.
   So I turned it off.   rms, 2 May 1997.  */
/* #include <malloc.h>  */
 #pragma alloca
#define YYSTACK_USE_ALLOCA
#else /* not MSDOS, or __TURBOC__, or _AIX */
#if 0
#ifdef __hpux /* haible@ilog.fr says this works for HPUX 9.05 and up,
		 and on HPUX 10.  Eventually we can turn this on.  */
#define YYSTACK_USE_ALLOCA
#define alloca __builtin_alloca
#endif /* __hpux */
#endif
#endif /* not _AIX */
#endif /* not MSDOS, or __TURBOC__ */
#endif /* not sparc */
#endif /* not GNU C */
#endif /* alloca not defined */
#endif /* YYSTACK_USE_ALLOCA not defined */

#ifdef YYSTACK_USE_ALLOCA
#define YYSTACK_ALLOC alloca
#else
#define YYSTACK_ALLOC malloc
#endif

/* Note: there must be only one dollar sign in this file.
   It is replaced by the list of actions, each action
   as one case of the switch.  */

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		-2
#define YYEOF		0
#define YYACCEPT	goto yyacceptlab
#define YYABORT 	goto yyabortlab
#define YYERROR		goto yyerrlab1
/* Like YYERROR except do call yyerror.
   This remains here temporarily to ease the
   transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */
#define YYFAIL		goto yyerrlab
#define YYRECOVERING()  (!!yyerrstatus)
#define YYBACKUP(token, value) \
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    { yychar = (token), yylval = (value);			\
      yychar1 = YYTRANSLATE (yychar);				\
      YYPOPSTACK;						\
      goto yybackup;						\
    }								\
  else								\
    { yyerror ("syntax error: cannot back up"); YYERROR; }	\
while (0)

#define YYTERROR	1
#define YYERRCODE	256

#ifndef YYPURE
#define YYLEX		yylex()
#endif

#ifdef YYPURE
#ifdef YYLSP_NEEDED
#ifdef YYLEX_PARAM
#define YYLEX		yylex(&yylval, &yylloc, YYLEX_PARAM)
#else
#define YYLEX		yylex(&yylval, &yylloc)
#endif
#else /* not YYLSP_NEEDED */
#ifdef YYLEX_PARAM
#define YYLEX		yylex(&yylval, YYLEX_PARAM)
#else
#define YYLEX		yylex(&yylval)
#endif
#endif /* not YYLSP_NEEDED */
#endif

/* If nonreentrant, generate the variables here */

#ifndef YYPURE

int	yychar;			/*  the lookahead symbol		*/
YYSTYPE	yylval;			/*  the semantic value of the		*/
				/*  lookahead symbol			*/

#ifdef YYLSP_NEEDED
YYLTYPE yylloc;			/*  location data for the lookahead	*/
				/*  symbol				*/
#endif

int yynerrs;			/*  number of parse errors so far       */
#endif  /* not YYPURE */

#if YYDEBUG != 0
int yydebug;			/*  nonzero means print parse trace	*/
/* Since this is uninitialized, it does not stop multiple parsers
   from coexisting.  */
#endif

/*  YYINITDEPTH indicates the initial size of the parser's stacks	*/

#ifndef	YYINITDEPTH
#define YYINITDEPTH 200
#endif

/*  YYMAXDEPTH is the maximum size the stacks can grow to
    (effective only if the built-in stack extension method is used).  */

#if YYMAXDEPTH == 0
#undef YYMAXDEPTH
#endif

#ifndef YYMAXDEPTH
#define YYMAXDEPTH 10000
#endif

/* Define __yy_memcpy.  Note that the size argument
   should be passed with type unsigned int, because that is what the non-GCC
   definitions require.  With GCC, __builtin_memcpy takes an arg
   of type size_t, but it can handle unsigned int.  */

#if __GNUC__ > 1		/* GNU C and GNU C++ define this.  */
#define __yy_memcpy(TO,FROM,COUNT)	__builtin_memcpy(TO,FROM,COUNT)
#else				/* not GNU C or C++ */
#ifndef __cplusplus

/* This is the most reliable way to avoid incompatibilities
   in available built-in functions on various systems.  */
static void
__yy_memcpy (to, from, count)
     char *to;
     char *from;
     unsigned int count;
{
  register char *f = from;
  register char *t = to;
  register int i = count;

  while (i-- > 0)
    *t++ = *f++;
}

#else /* __cplusplus */

/* This is the most reliable way to avoid incompatibilities
   in available built-in functions on various systems.  */
static void
__yy_memcpy (char *to, char *from, unsigned int count)
{
  register char *t = to;
  register char *f = from;
  register int i = count;

  while (i-- > 0)
    *t++ = *f++;
}

#endif
#endif

#line 217 "/usr/local/share/bison.simple"

/* The user can define YYPARSE_PARAM as the name of an argument to be passed
   into yyparse.  The argument should have type void *.
   It should actually point to an object.
   Grammar actions can access the variable by casting it
   to the proper pointer type.  */

#ifdef YYPARSE_PARAM
#ifdef __cplusplus
#define YYPARSE_PARAM_ARG void *YYPARSE_PARAM
#define YYPARSE_PARAM_DECL
#else /* not __cplusplus */
#define YYPARSE_PARAM_ARG YYPARSE_PARAM
#define YYPARSE_PARAM_DECL void *YYPARSE_PARAM;
#endif /* not __cplusplus */
#else /* not YYPARSE_PARAM */
#define YYPARSE_PARAM_ARG
#define YYPARSE_PARAM_DECL
#endif /* not YYPARSE_PARAM */

/* Prevent warning if -Wstrict-prototypes.  */
#ifdef __GNUC__
#ifdef YYPARSE_PARAM
int yyparse (void *);
#else
int yyparse (void);
#endif
#endif

int
yyparse(YYPARSE_PARAM_ARG)
     YYPARSE_PARAM_DECL
{
  register int yystate;
  register int yyn;
  register short *yyssp;
  register YYSTYPE *yyvsp;
  int yyerrstatus;	/*  number of tokens to shift before error messages enabled */
  int yychar1 = 0;		/*  lookahead token as an internal (translated) token number */

  short	yyssa[YYINITDEPTH];	/*  the state stack			*/
  YYSTYPE yyvsa[YYINITDEPTH];	/*  the semantic value stack		*/

  short *yyss = yyssa;		/*  refer to the stacks thru separate pointers */
  YYSTYPE *yyvs = yyvsa;	/*  to allow yyoverflow to reallocate them elsewhere */

#ifdef YYLSP_NEEDED
  YYLTYPE yylsa[YYINITDEPTH];	/*  the location stack			*/
  YYLTYPE *yyls = yylsa;
  YYLTYPE *yylsp;

#define YYPOPSTACK   (yyvsp--, yyssp--, yylsp--)
#else
#define YYPOPSTACK   (yyvsp--, yyssp--)
#endif

  int yystacksize = YYINITDEPTH;
  int yyfree_stacks = 0;

#ifdef YYPURE
  int yychar;
  YYSTYPE yylval;
  int yynerrs;
#ifdef YYLSP_NEEDED
  YYLTYPE yylloc;
#endif
#endif

  YYSTYPE yyval;		/*  the variable used to return		*/
				/*  semantic values from the action	*/
				/*  routines				*/

  int yylen;

#if YYDEBUG != 0
  if (yydebug)
    fprintf(stderr, "Starting parse\n");
#endif

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY;		/* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */

  yyssp = yyss - 1;
  yyvsp = yyvs;
#ifdef YYLSP_NEEDED
  yylsp = yyls;
#endif

/* Push a new state, which is found in  yystate  .  */
/* In all cases, when you get here, the value and location stacks
   have just been pushed. so pushing a state here evens the stacks.  */
yynewstate:

  *++yyssp = yystate;

  if (yyssp >= yyss + yystacksize - 1)
    {
      /* Give user a chance to reallocate the stack */
      /* Use copies of these so that the &'s don't force the real ones into memory. */
      YYSTYPE *yyvs1 = yyvs;
      short *yyss1 = yyss;
#ifdef YYLSP_NEEDED
      YYLTYPE *yyls1 = yyls;
#endif

      /* Get the current used size of the three stacks, in elements.  */
      int size = yyssp - yyss + 1;

#ifdef yyoverflow
      /* Each stack pointer address is followed by the size of
	 the data in use in that stack, in bytes.  */
#ifdef YYLSP_NEEDED
      /* This used to be a conditional around just the two extra args,
	 but that might be undefined if yyoverflow is a macro.  */
      yyoverflow("parser stack overflow",
		 &yyss1, size * sizeof (*yyssp),
		 &yyvs1, size * sizeof (*yyvsp),
		 &yyls1, size * sizeof (*yylsp),
		 &yystacksize);
#else
      yyoverflow("parser stack overflow",
		 &yyss1, size * sizeof (*yyssp),
		 &yyvs1, size * sizeof (*yyvsp),
		 &yystacksize);
#endif

      yyss = yyss1; yyvs = yyvs1;
#ifdef YYLSP_NEEDED
      yyls = yyls1;
#endif
#else /* no yyoverflow */
      /* Extend the stack our own way.  */
      if (yystacksize >= YYMAXDEPTH)
	{
	  yyerror("parser stack overflow");
	  if (yyfree_stacks)
	    {
	      free ((malloc_t) yyss);
	      free ((malloc_t) yyvs);
#ifdef YYLSP_NEEDED
	      free (yyls);
#endif
	    }
	  return 2;
	}
      yystacksize *= 2;
      if (yystacksize > YYMAXDEPTH)
	yystacksize = YYMAXDEPTH;
#ifndef YYSTACK_USE_ALLOCA
      yyfree_stacks = 1;
#endif
      yyss = (short *) YYSTACK_ALLOC (yystacksize * sizeof (*yyssp));
      __yy_memcpy ((char *)yyss, (char *)yyss1,
		   size * (unsigned int) sizeof (*yyssp));
      yyvs = (YYSTYPE *) YYSTACK_ALLOC (yystacksize * sizeof (*yyvsp));
      __yy_memcpy ((char *)yyvs, (char *)yyvs1,
		   size * (unsigned int) sizeof (*yyvsp));
#ifdef YYLSP_NEEDED
      yyls = (YYLTYPE *) YYSTACK_ALLOC (yystacksize * sizeof (*yylsp));
      __yy_memcpy ((char *)yyls, (char *)yyls1,
		   size * (unsigned int) sizeof (*yylsp));
#endif
#endif /* no yyoverflow */

      yyssp = yyss + size - 1;
      yyvsp = yyvs + size - 1;
#ifdef YYLSP_NEEDED
      yylsp = yyls + size - 1;
#endif

#if YYDEBUG != 0
      if (yydebug)
	fprintf(stderr, "Stack size increased to %d\n", yystacksize);
#endif

      if (yyssp >= yyss + yystacksize - 1)
	YYABORT;
    }

#if YYDEBUG != 0
  if (yydebug)
    fprintf(stderr, "Entering state %d\n", yystate);
#endif

  goto yybackup;
 yybackup:

/* Do appropriate processing given the current state.  */
/* Read a lookahead token if we need one and don't already have one.  */
/* yyresume: */

  /* First try to decide what to do without reference to lookahead token.  */

  yyn = yypact[yystate];
  if (yyn == YYFLAG)
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* yychar is either YYEMPTY or YYEOF
     or a valid token in external form.  */

  if (yychar == YYEMPTY)
    {
#if YYDEBUG != 0
      if (yydebug)
	fprintf(stderr, "Reading a token: ");
#endif
      yychar = YYLEX;
    }

  /* Convert token to internal form (in yychar1) for indexing tables with */

  if (yychar <= 0)		/* This means end of input. */
    {
      yychar1 = 0;
      yychar = YYEOF;		/* Don't call YYLEX any more */

#if YYDEBUG != 0
      if (yydebug)
	fprintf(stderr, "Now at end of input.\n");
#endif
    }
  else
    {
      yychar1 = YYTRANSLATE(yychar);

#if YYDEBUG != 0
      if (yydebug)
	{
	  fprintf (stderr, "Next token is %d (%s", yychar, yytname[yychar1]);
	  /* Give the individual parser a way to print the precise meaning
	     of a token, for further debugging info.  */
#ifdef YYPRINT
	  YYPRINT (stderr, yychar, yylval);
#endif
	  fprintf (stderr, ")\n");
	}
#endif
    }

  yyn += yychar1;
  if (yyn < 0 || yyn > YYLAST || yycheck[yyn] != yychar1)
    goto yydefault;

  yyn = yytable[yyn];

  /* yyn is what to do for this token type in this state.
     Negative => reduce, -yyn is rule number.
     Positive => shift, yyn is new state.
       New state is final state => don't bother to shift,
       just return success.
     0, or most negative number => error.  */

  if (yyn < 0)
    {
      if (yyn == YYFLAG)
	goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }
  else if (yyn == 0)
    goto yyerrlab;

  if (yyn == YYFINAL)
    YYACCEPT;

  /* Shift the lookahead token.  */

#if YYDEBUG != 0
  if (yydebug)
    fprintf(stderr, "Shifting token %d (%s), ", yychar, yytname[yychar1]);
#endif

  /* Discard the token being shifted unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  *++yyvsp = yylval;
#ifdef YYLSP_NEEDED
  *++yylsp = yylloc;
#endif

  /* count tokens shifted since error; after three, turn off error status.  */
  if (yyerrstatus) yyerrstatus--;

  yystate = yyn;
  goto yynewstate;

/* Do the default action for the current state.  */
yydefault:

  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;

/* Do a reduction.  yyn is the number of a rule to reduce with.  */
yyreduce:
  yylen = yyr2[yyn];
  if (yylen > 0)
    yyval = yyvsp[1-yylen]; /* implement default value of the action */

#if YYDEBUG != 0
  if (yydebug)
    {
      int i;

      fprintf (stderr, "Reducing via rule %d (line %d), ",
	       yyn, yyrline[yyn]);

      /* Print the symbols being reduced, and their result.  */
      for (i = yyprhs[yyn]; yyrhs[i] > 0; i++)
	fprintf (stderr, "%s ", yytname[yyrhs[i]]);
      fprintf (stderr, " -> %s\n", yytname[yyr1[yyn]]);
    }
#endif


  switch (yyn) {

case 1:
#line 1090 "parse.y"
{
		    if (yynerrs) {
			YYABORT;
		    } else {
			YYACCEPT;
		    }
		;
    break;}
case 2:
#line 1099 "parse.y"
{
		    defStruct = FALSE;
		;
    break;}
case 3:
#line 1103 "parse.y"
{
		    defStruct = FALSE;
		;
    break;}
case 16:
#line 1126 "parse.y"
{
		    defStruct = 0;
		;
    break;}
case 17:
#line 1130 "parse.y"
{
		    /*
		     * Boogie, dude
		     */
		    YYACCEPT;
		;
    break;}
case 18:
#line 1137 "parse.y"
{
		    /*
		     * Record entry point, and boogie
		     */
		    entryPoint = Expr_Copy(&expr1, TRUE);
		    YYACCEPT;
		;
    break;}
case 20:
#line 1158 "parse.y"
{
		    /*
		     * General error handler
		     */
		    if (yychar > FIRSTOP && yychar < LASTOP) {
			yyerror("missing colon for code label %i", yyvsp[-1].ident);
		    } else {
			yyerror("expected symbol-definition directive for %i",
				yyvsp[-1].ident);
		    }
		    yyerrok;
		;
    break;}
case 21:
#line 1171 "parse.y"
{;
    break;}
case 22:
#line 1173 "parse.y"
{
		    Sym_Reference(yyvsp[-1].sym);
		;
    break;}
case 23:
#line 1181 "parse.y"
{
		    /*
		     * Regular near label -- enter it as a FAR so that
		     * it can be called as a procedure
		     */
		    yyval.sym = Sym_Enter(yyvsp[-1].ident, curProc ? SYM_LOCALLABEL : SYM_LABEL,
				    dot, TRUE);
		    curSeg->u.segment.data->lastLabel = dot;
		    FilterGenerated(yyval.sym);
		;
    break;}
case 24:
#line 1192 "parse.y"
{
		    if (yyvsp[-1].sym->type == SYM_LOCALLABEL) {
			yyerror("%i is already a local label in this procedure",
				yyvsp[-1].sym->name);
		    } else {
			CheckAndSetLabel(SYM_LABEL, yyvsp[-1].sym, TRUE);
		    }
		    yyval.sym = yyvsp[-1].sym;
		;
    break;}
case 25:
#line 1202 "parse.y"
{
		    if (curProc == NULL) {
			yyerror("local labels must occur within a procedure");
			YYERROR;
		    } else {
			char    	name[12];
			ID	    	id;

			/*
			 * Form the name and enter it into the string table
			 */
			sprintf(name, "%d$", yyvsp[-2].number);
			id = ST_EnterNoLen(output, symStrings, name);

			/*
			 * Enter the thing as a local label, but mark it as
			 * something that shouldn't be written out.
			 */
			yyval.sym = Sym_Enter(id, SYM_LOCALLABEL, dot, TRUE);
			yyval.sym->flags |= SYM_NOWRITE;
			curSeg->u.segment.data->lastLabel = dot;
		    }
		;
    break;}
case 26:
#line 1229 "parse.y"
{
		    SymbolPtr	sym;

		    if (yyvsp[0].type->tn_type == TYPE_NEAR) {
			sym = Sym_Enter(yyvsp[-2].ident, SYM_LABEL, dot, TRUE);
			curSeg->u.segment.data->lastLabel = dot;
			FilterGenerated(sym);
		    } else if (yyvsp[0].type->tn_type == TYPE_FAR) {
			sym = Sym_Enter(yyvsp[-2].ident, SYM_LABEL, dot, FALSE);
			curSeg->u.segment.data->lastLabel = dot;
			FilterGenerated(sym);
		    } else {
			ResetExpr(&expr1, defElts1);
			DefineData(yyvsp[-2].ident, yyvsp[0].type, FALSE, FALSE);
		    }
		;
    break;}
case 27:
#line 1246 "parse.y"
{
		    if (yyvsp[0].type->tn_type == TYPE_NEAR) {
			CheckAndSetLabel(SYM_LABEL, yyvsp[-2].sym, TRUE);
		    } else if (yyvsp[0].type->tn_type == TYPE_FAR) {
			CheckAndSetLabel(SYM_LABEL, yyvsp[-2].sym, FALSE);
		    } else {
			ResetExpr(&expr1, defElts1);
			DefineDataSym(yyvsp[-2].sym, yyvsp[0].type, FALSE, FALSE);
		    }
		;
    break;}
case 28:
#line 1264 "parse.y"
{
		    Symbol *sym;
		    sym = Sym_Enter(yyvsp[-2].ident, SYM_PROC, dot, yyvsp[0].number);

		    EnterProc(sym);
		;
    break;}
case 30:
#line 1272 "parse.y"
{
		    CheckAndSetLabel(SYM_PROC, yyvsp[-2].sym, yyvsp[0].number & SYM_NEAR);
		    yyvsp[-2].sym->u.proc.flags |= yyvsp[0].number;
		    EnterProc(yyvsp[-2].sym);
		;
    break;}
case 32:
#line 1279 "parse.y"
{ yyval.number = yyvsp[-1].number | SYM_NEAR; ;
    break;}
case 33:
#line 1280 "parse.y"
{ yyval.number = yyvsp[-1].number; ;
    break;}
case 34:
#line 1282 "parse.y"
{
		    /*
		     * If the current memory model is small or compact,
		     * the procedure defaults to near, else it defaults to
		     * far.
		     */
		    if (model == MM_SMALL || model == MM_COMPACT) {
			yyval.number = yyvsp[-1].number | SYM_NEAR;
		    } else {
		    	yyval.number = yyvsp[-1].number;
		    }
		;
    break;}
case 35:
#line 1296 "parse.y"
{ yyval.number = SYM_NO_JMP; ;
    break;}
case 36:
#line 1297 "parse.y"
{ yyval.number = SYM_NO_CALL; ;
    break;}
case 37:
#line 1298 "parse.y"
{ yyval.number = 0; ;
    break;}
case 50:
#line 1309 "parse.y"
{
		    AddArg(yyvsp[-2].ident, yyvsp[0].type);
		;
    break;}
case 51:
#line 1313 "parse.y"
{
		    if ((yyvsp[-2].sym->type != SYM_VAR) || warn_shadow) {
			yywarning("definition of %i as argument shadows global symbol",
				  yyvsp[-2].sym->name);
		    }
		    AddArg(yyvsp[-2].sym->name, yyvsp[0].type);
		;
    break;}
case 52:
#line 1321 "parse.y"
{
		    yywarning("definition of %i as argument shadows global symbol",
			      yyvsp[-2].sym->name);
		    AddArg(yyvsp[-2].sym->name, yyvsp[0].type);
		;
    break;}
case 53:
#line 1327 "parse.y"
{
		    /*
		     * Declaring extra stuff on stack that needn't be
		     * referenced.
		     */
		    AddArg(NullID, yyvsp[0].type);
		;
    break;}
case 56:
#line 1341 "parse.y"
{
		    if (curProc != yyvsp[-1].sym) {
			if (curProc == NULL) {
			    yyerror("ENDP for %i outside of any procedure",
				    yyvsp[-1].sym->name);
			} else {
			    yyerror("ENDP for %i inside %i",
				    yyvsp[-1].sym->name, curProc->name);
			}
			yynerrs++;
		    } else {
			/*
			 * Reset procedure-specific state variables
			 */
			EndProc(curProc->name);
		    }
		;
    break;}
case 57:
#line 1359 "parse.y"
{
		    yyerror("procedure %i not defined, so can't be ended", yyvsp[-1].ident);
		    yynerrs++;
		;
    break;}
case 58:
#line 1365 "parse.y"
{
		    /*
		     * Just terminate the current procedure.
		     */
		    if (curProc == NULL) {
			yyerror("ENDP outside of any procedure");
			yynerrs++;
		    } else {
			EndProc(curProc->name);
		    }
		;
    break;}
case 60:
#line 1382 "parse.y"
{ yyval.number = yyvsp[-2].number | yyvsp[0].number; ;
    break;}
case 61:
#line 1383 "parse.y"
{ yyval.number = yyvsp[-1].number | yyvsp[0].number; ;
    break;}
case 62:
#line 1385 "parse.y"
{ yyval.number = (1L << yyvsp[0].number) |
					  (1L << (yyvsp[0].number + REG_DI + REG_GS + 2)); ;
    break;}
case 63:
#line 1387 "parse.y"
{ yyval.number = 1L << yyvsp[0].number; ;
    break;}
case 64:
#line 1388 "parse.y"
{ yyval.number = 1L << (yyvsp[0].number & 0x3); ;
    break;}
case 65:
#line 1389 "parse.y"
{ yyval.number = 1L << (yyvsp[0].number + REG_DI + 1); ;
    break;}
case 66:
#line 1392 "parse.y"
{
		    if (enterSeen || leaveSeen) {
			/*
			 * Generated code was incorrect -- give error
			 */
			yyerror("\"uses\" too late: .ENTER or .LEAVE already given for procedure %i",
				curProc->name);
			yynerrs++;
		    }
		    usesMask |= yyvsp[0].number;
		    enterNeeded = TRUE;
		;
    break;}
case 68:
#line 1406 "parse.y"
{ usesMask |= yyvsp[0].number; enterNeeded = TRUE; ;
    break;}
case 69:
#line 1408 "parse.y"
{;
    break;}
case 70:
#line 1410 "parse.y"
{
		    /*
		     * Initialize first-local-var flag. Doing it here avoids
		     * a spurious error if we bitch b/c this isn't the first
		     * push-initialized variable and the hoser's initializing
		     * this variable with BP (it'll still bitch if the push
		     * bp isn't the first push instruction, though).
		     */
		    isFirstLocalWord = TRUE;
		    if (frameSize != yyvsp[0].number) {
			yyerror("all push-initialized local variables must be declared first");
			yynerrs++;
		    } else {
			/*
			 * Set special flag for pushLocal rule so it can tell
			 * if it's the first one (to deal with push bp).
			 * Besides, we need to know for sure ourselves, and
			 * "push bp" handling requires us to reduce localSize
			 * by two, so we couldn't rely on that anymore anyway.
			 */
			int numLocals;

			numLocals = 0;
			Sym_ForEachLocal(curProc, ParseCountLocals,
					 (Opaque)&numLocals);
			if (numLocals == 1) {
			    /*
			     * First initialized local variable, so perform
			     * first part of frame setup now.
			     */
			    Code_PrologueSaveFP();

			    frameSetup = TRUE;

			    isFirstLocalWord = TRUE;
			}
			frameSize -= yyvsp[0].number;
		    }
		;
    break;}
case 71:
#line 1450 "parse.y"
{
		    if (yyvsp[0].number * 2 < yyvsp[-2].number) {
			yyerror("not enough PUSHes to initialize local variable");
			yynerrs++;
		    } else if (yyvsp[0].number * 2 > yyvsp[-2].number) {
			yyerror("too many PUSHes initializing local variable");
			yynerrs++;
		    }
		;
    break;}
case 72:
#line 1460 "parse.y"
{ yyval.number = yyvsp[0].number; ;
    break;}
case 73:
#line 1461 "parse.y"
{ yyval.number = yyvsp[-1].number + yyvsp[0].number; ;
    break;}
case 74:
#line 1464 "parse.y"
{
		    /*
		     * Return number of words pushed.
		     */
		    yyval.number = yyvsp[0].number;
		;
    break;}
case 75:
#line 1472 "parse.y"
{ yyval.number = 1; ;
    break;}
case 76:
#line 1474 "parse.y"
{
		    /*
		     * Count another word pushed.
		     */
		    yyval.number = yyvsp[-2].number + 1;
		;
    break;}
case 77:
#line 1483 "parse.y"
{
		    if ((expr1.elts[0].op == EXPR_WORDREG) &&
			(expr1.elts[1].reg == REG_BP))
		    {
			/*
			 * Wheee. Variable being initialized by pushing BP, so
			 * (a) this must be the very first local variable, and
			 * (b) this must be the first word of the variable being
			 * pushed, so we can use the automatic "push bp" of the
			 * prologue as this push.
			 *
			 * If these special conditions are met, we adjust "all"
			 * (the current one is the only one) locals by +2 to
			 * overlap with the bp saved by Code_PrologueSaveFP().
			 */
			if (!isFirstLocalWord) {
			    yyerror("a local variable push-initialized with BP must be the first variable in the frame, with BP the first word pushed");
			    yynerrs++;
			} else {
			    Sym_ForEachLocal(curProc, ParseAdjustLocals,
					     (Opaque)2);
			    /*
			     * Adjust for word not actually in the local frame.
			     */
			    localSize -= 2;
			}
		    } else {
			(void)Code_Push(&dot, 0, 1, &expr1, NULL, (Opaque)NULL);
		    }
		    isFirstLocalWord = FALSE;
		;
    break;}
case 78:
#line 1517 "parse.y"
{
		    yyval.number = 0;

		    if (enterSeen || leaveSeen) {
			yyerror("\"local\" too late: .ENTER or .LEAVE already given for procedure %i",
				curProc->name);
			yynerrs++;
		    } else if (!curProc) {
			yyerror("LOCAL directive for %i when not in a procedure",
				yyvsp[-2].ident);
			yynerrs++;
		    } else {
			/*
			 * Add the size of the variable to the current
			 * frame size to get the offset for the variable.
			 * No need to word-align the thing as we'll do that
			 * when we encounter the ENTER.
			 */
			yyval.number = Type_Size(yyvsp[0].type);

			localSize += yyval.number; frameSize += yyval.number;

			(void)Sym_Enter(yyvsp[-2].ident, SYM_LOCAL, -localSize, yyvsp[0].type);

			frameNeeded = enterNeeded = TRUE;
		    }
		;
    break;}
case 80:
#line 1548 "parse.y"
{
		    if ((yyvsp[0].sym->type != SYM_VAR) || warn_shadow) {
			yywarning("definition of %i as local variable shadows global symbol",
				  yyvsp[0].sym->name);
		    }
		    yyval.ident = yyvsp[0].sym->name
		;
    break;}
case 81:
#line 1555 "parse.y"
{ yyval.ident = NullID; ;
    break;}
case 82:
#line 1557 "parse.y"
{
		    yywarning("definition of %i as local variable shadows global symbol",
			      yyvsp[0].sym->name);
		    yyval.ident = yyvsp[0].sym->name;
		;
    break;}
case 83:
#line 1565 "parse.y"
{
		    if (curProc != NULL) {
			Code_Prologue(frameNeeded, usesMask, frameSize,
				      frameSetup);
			enterSeen = TRUE;
		    } else {
			yyerror(".ENTER is outside any procedure");
			yynerrs++;
		    }
		;
    break;}
case 84:
#line 1576 "parse.y"
{
		    if (curProc != NULL) {
			/*
			 * Inherit the frame from our caller. This allows us to
			 * use the same local variables through several frames
			 * so long as BP isn't changed. Typically, all the local
			 * vars will be defined in a structure and a single
			 * variable of that structure declared. Using the
			 * INHERIT kewyord turns off the frameNeeded flag.
			 */
			frameNeeded = FALSE;
			Code_Prologue(FALSE, usesMask, 0, 1);
			enterSeen = TRUE;
		    } else {
			yyerror(".ENTER is outside any procedure");
			yynerrs++;
		    }
		;
    break;}
case 85:
#line 1595 "parse.y"
{
		    if (curProc != NULL) {
			/* Use localSize, not frameSize, so we know about
			 * push-initialized locals... */
			Code_Epilogue(frameNeeded, usesMask, localSize);
			leaveSeen = TRUE;
		    } else {
			yyerror(".LEAVE is outside any procedure");
			yynerrs++;
		    }
		;
    break;}
case 86:
#line 1607 "parse.y"
{
		    /*
		     * This is a special form of .leave that allows weird
		     * functions that never return, but set up a stack
		     * frame, to shut us up...
		     */
		    if (curProc != NULL) {
			leaveSeen = TRUE;
			curSeg->u.segment.data->checkLabel=TRUE;
		    } else {
			yyerror(".LEAVE is outside any procedure");
			yynerrs++;
		    }
		;
    break;}
case 87:
#line 1623 "parse.y"
{
		    /*
		     * All local variables and arguments are marked as
		     * referenced to avoid annoying warnings when one has
		     * inherited some variables that one doesn't use, since
		     * one must inherit all variables to keep the frames
		     * consistent.
		     */
		    if (curProc != NULL) {
			Sym_ReferenceAllLocals(curProc);
		    }
		;
    break;}
case 88:
#line 1636 "parse.y"
{
		    /*
		     * Inherit from a near procedure. Adjust offsets of all
		     * declared args down (to account for extra word of return
		     * address in the current function) if current procedure is
		     * far.
		     */
		    if (curProc != NULL && !(curProc->u.proc.flags & SYM_NEAR))
		    {
			Sym_AdjustArgOffset(curProc, -2);
		    }
		    if (curProc != NULL) {
			Sym_ReferenceAllLocals(curProc);
		    }
		;
    break;}
case 89:
#line 1652 "parse.y"
{
		    /*
		     * Inherit from a far procedure. Adjust offsets of all
		     * declared args up (to account for extra word of return
		     * address in function where frame was set up) if
		     * current procedure is near.
		     */
		    if (curProc != NULL && (curProc->u.proc.flags & SYM_NEAR))
		    {
			Sym_AdjustArgOffset(curProc, 2);
		    }
		    if (curProc != NULL) {
			Sym_ReferenceAllLocals(curProc);
		    }
		;
    break;}
case 90:
#line 1668 "parse.y"
{
		    /*
		     * Inherit from a procedure that's not yet defined.
		     */
		    if (curProc != NULL) {
			Sym_Enter(yyvsp[0].ident, SYM_INHERIT, NullSymbol, curFile->name,
				  yylineno);
		    }
		;
    break;}
case 91:
#line 1678 "parse.y"
{
		    /*
		     * Inherit from a known procedure.
		     */
		    if (yyvsp[0].sym->type != SYM_PROC) {
			yyerror("cannot inherit locals from non-procedure %i",
				yyvsp[0].sym->name);
			yynerrs++;
		    } else if (curProc != NULL) {
			Sym_Enter(yyvsp[0].sym->name, SYM_INHERIT, yyvsp[0].sym, curFile->name,
				  yylineno);
		    }
		;
    break;}
case 92:
#line 1698 "parse.y"
{
		    Sym_Enter(yyvsp[-1].ident, SYM_MACRO, yyvsp[0].macro.text, yyvsp[0].macro.numArgs,
			      yyvsp[0].macro.numLocals);
		;
    break;}
case 93:
#line 1703 "parse.y"
{
		    /*
		     * Macro redefinitions -- can't free the old text since
		     * blocks are allocated in chunks, so just store in the
		     * new parameters.
		     */

		    yyvsp[-1].sym->u.macro.text = yyvsp[0].macro.text;
		    yyvsp[-1].sym->u.macro.numArgs = yyvsp[0].macro.numArgs;
		    yyvsp[-1].sym->u.macro.numLocals = yyvsp[0].macro.numLocals;
		;
    break;}
case 94:
#line 1715 "parse.y"
{
		    /*
		     * Nothing follows, so must be a string equate. Value
		     * has been parsed into pieces by the scanner and
		     * is the value of the EQU token
		     */
		    Sym_Enter(yyvsp[-1].ident, SYM_STRING, yyvsp[0].block);
		;
    break;}
case 95:
#line 1724 "parse.y"
{
		    if (yychar != '\n') {
			yyerror("%i cannot be redefined as an equate",
				yyvsp[-1].sym->name);
		    } else {
			RedefineString(yyvsp[-1].sym, yyvsp[0].block);
		    }
		;
    break;}
case 96:
#line 1733 "parse.y"
{
		    /*
		     * This can happen if you redefine a string equate
		     * with another string equate. Form the string into
		     * a macro block and call RedefineString.
		     */
		    int	    len = strlen(yyvsp[0].string);
		    MBlk    *val;

		    if (len > 0) {
			val = (MBlk *)malloc_tagged(sizeof(MArg)+len,
							 TAG_MBLK);

			val->next = (MBlk *)NULL;
			val->length = len;
			val->dynamic = TRUE;
			bcopy(yyvsp[0].string, val->text, len);
		    } else {
			val = NULL;
		    }

		    free(yyvsp[0].string);

		    RedefineString(yyvsp[-2].sym, val);
		;
    break;}
case 97:
#line 1759 "parse.y"
{
		    Sym_Enter(yyvsp[-1].ident, SYM_STRING, yyvsp[0].block);
		;
    break;}
case 98:
#line 1763 "parse.y"
{
		    RedefineString(yyvsp[-1].sym, yyvsp[0].block);
		;
    break;}
case 99:
#line 1768 "parse.y"
{
		    /*
		     * Substring from position to end (1-origin)
		     */
		    int	    len = strlen(yyvsp[-2].string);

		    /*
		     * We like zero-origin...
		     */
		    yyvsp[0].number -= 1;

		    if (yyvsp[0].number < 0) {
			yyerror("invalid start position %d (must be >= 1)",
				yyvsp[0].number+1);
			yyval.block = NULL;
			yynerrs++;
		    } else if (yyvsp[0].number >= len) {
			yyerror("start position %d too big (string is %d byte%s long)",
				yyvsp[0].number+1, len, len == 1 ? "" : "s");
			yyval.block = NULL;
			yynerrs++;
		    } else {
			yyval.block = (MBlk *)malloc_tagged(sizeof(MArg)+(len-yyvsp[0].number),
						   TAG_MBLK);
			yyval.block->dynamic = TRUE;
			yyval.block->next = (MBlk *)NULL;
			yyval.block->length = len-yyvsp[0].number;
			bcopy(yyvsp[-2].string+yyvsp[0].number, yyval.block->text, len-yyvsp[0].number);
		    }
		    free(yyvsp[-2].string);
		;
    break;}
case 100:
#line 1800 "parse.y"
{
		    /*
		     * Substring from position of given length.
		     */
		    int	    len = strlen(yyvsp[-4].string);

		    /*
		     * We like zero-origin...
		     */
		    yyvsp[-2].number -= 1;

		    if (yyvsp[-2].number < 0) {
			yyerror("invalid start position %d (must be >= 1)",
				yyvsp[-2].number+1);
			yyval.block = NULL;
			yynerrs++;
		    } else if (yyvsp[-2].number >= len) {
			yyerror("start position %d too big (string is %d byte%s long)",
				yyvsp[-2].number+1, len, len == 1 ? "" : "s");
			yyval.block = NULL;
			yynerrs++;
		    } else if (yyvsp[-2].number+yyvsp[0].number > len) {
			yyerror("length %d too big (string is %d byte%s long)",
				yyvsp[0].number, len, len == 1 ? "" : "s");
			yyval.block = NULL;
			yynerrs++;
		    } else if (yyvsp[0].number > 0) {
			yyval.block = (MBlk *)malloc_tagged(sizeof(MArg)+yyvsp[0].number,
						   TAG_MBLK);
			yyval.block->dynamic = TRUE;
			yyval.block->next = (MBlk *)NULL;
			yyval.block->length = yyvsp[0].number;
			bcopy(yyvsp[-4].string+yyvsp[-2].number, yyval.block->text, yyvsp[0].number);
		    } else {
			yyval.block = NULL;
		    }
		    free(yyvsp[-4].string);
		;
    break;}
case 101:
#line 1838 "parse.y"
{ yyval.block = yyvsp[0].block; ;
    break;}
case 102:
#line 1848 "parse.y"
{
		    /*
		     * Convert the string into a macro block.
		     */
		    int	    len = strlen(yyvsp[0].string);

		    if (len > 0) {
			yyval.block = (MBlk *)malloc_tagged(sizeof(MArg)+len,
						   TAG_MBLK);
			yyval.block->dynamic = TRUE;
			yyval.block->length = len;
			yyval.block->next = NULL;
			bcopy(yyvsp[0].string, yyval.block->text, len);
		    } else {
			yyval.block = NULL;
		    }

		    free(yyvsp[0].string);
		;
    break;}
case 103:
#line 1868 "parse.y"
{
		    /*
		     * Convert the string into a macro block and link to the
		     * next block in the list.
		     */
		    int	    len = strlen(yyvsp[-2].string);

		    if (len > 0) {
			yyval.block = (MBlk *)malloc_tagged(sizeof(MArg)+len,
						   TAG_MBLK);
			yyval.block->dynamic = TRUE;
			yyval.block->length = len;
			yyval.block->next = yyvsp[0].block;
			bcopy(yyvsp[-2].string, yyval.block->text, len);
		    } else {
			/*
			 * Zero-length string, so just use the chain from
			 * the strings to our right.
			 */
			yyval.block = yyvsp[0].block;
		    }

		    free(yyvsp[-2].string);
		;
    break;}
case 104:
#line 1893 "parse.y"
{ yyrepeat(yyvsp[0].number); ;
    break;}
case 105:
#line 1894 "parse.y"
{ defStruct = 1; ;
    break;}
case 106:
#line 1895 "parse.y"
{
		    char    *id = ST_Lock(output, yyvsp[-3].ident);

		    yyirp(id, yyvsp[0].string);
		    free(yyvsp[0].string);
		    ST_Unlock(output, yyvsp[-3].ident);
		    defStruct = 0;
		;
    break;}
case 107:
#line 1903 "parse.y"
{ defStruct = 1; ;
    break;}
case 108:
#line 1904 "parse.y"
{
		    char    *id = ST_Lock(output, yyvsp[-3].ident);

		    yyirpc(id, yyvsp[0].string);
		    free(yyvsp[0].string);

		    ST_Unlock(output, yyvsp[-3].ident);
		    defStruct = 0;
		;
    break;}
case 109:
#line 1913 "parse.y"
{ yystartmacro(yyvsp[-1].sym, yyvsp[0].arg); ;
    break;}
case 110:
#line 1914 "parse.y"
{ yystartmacro(yyvsp[0].sym, NULL); ;
    break;}
case 112:
#line 1922 "parse.y"
{ yyval.arg = yyvsp[-1].arg; yyval.arg->next = yyvsp[0].arg; ;
    break;}
case 113:
#line 1925 "parse.y"
{
		    yyval.arg = (Arg *)malloc_tagged(sizeof(Arg),
					      TAG_MACRO_ARG);
		    yyval.arg->next = NULL;
		    yyval.arg->value = yyvsp[0].string;
		    yyval.arg->freeIt = TRUE;
		;
    break;}
case 114:
#line 1936 "parse.y"
{
		    yyval.arg = (Arg *)malloc_tagged(sizeof(Arg),
					      TAG_MACRO_ARG);
		    yyval.arg->next = 0;
		    yyval.arg->value = (char *)malloc_tagged(12, TAG_MACRO_ARG_VALUE);
		    yyval.arg->freeIt = TRUE;

		    sprintf(yyval.arg->value, "%d", yyvsp[0].number);
		    noSymTrans = TRUE;
		    /*
		     * If the look-ahead token is a newline, we do *not*
		     * want to switch back to parsing macro arguments.
		     */
		    if (yychar != '\n') {
			yylex = yymacarglex;
		    }
		;
    break;}
case 115:
#line 1959 "parse.y"
{
		    yyval.arg = (Arg *)malloc_tagged(sizeof(Arg), TAG_MACRO_ARG);
		    yyval.arg->next = 0;
		    yyval.arg->value = (char *)malloc_tagged(12,
						      TAG_MACRO_ARG_VALUE);
		    yyval.arg->freeIt = TRUE;

		    sprintf(yyval.arg->value, "%d", yyvsp[-1].number);
		    noSymTrans = TRUE;
		    /*
		     * If the look-ahead token is a newline, we do *not*
		     * want to switch back to parsing macro arguments.
		     */
		    if (yychar != '\n') {
			yylex = yymacarglex;
		    }
		;
    break;}
case 116:
#line 1991 "parse.y"
{ yyval.number = TRUE; ;
    break;}
case 117:
#line 1992 "parse.y"
{ yyval.number = FALSE; ;
    break;}
case 118:
#line 1995 "parse.y"
{
		    ExprResult	result;
		    byte    	status;

		    if (!Expr_Eval(&expr1, &result,
				   EXPR_RECURSIVE | EXPR_NOREF,
				   &status))
		    {
			/*
			 * Give error now, rather than each time the constant
			 * is used, then pretend the value was a constant 0.
			 */
			yyerror((char *)result.type);
			yynerrs++;
			ResetExpr(&expr1, defElts1);
			StoreExprConst(0L);
		    } else if ((status & EXPR_STAT_DEFINED) &&
			       !(status & EXPR_STAT_DELAY) &&
			       (result.type == EXPR_TYPE_CONST) &&
			       !result.rel.sym)
		    {
			/*
			 * If it evaluates to a constant, replace the
			 * expression with the final result. This prevents
			 * us from generating recursive EXPR_SYMs
			 */
			ResetExpr(&expr1, defElts1);
			StoreExprConst(result.data.number);
		    }
		;
    break;}
case 119:
#line 2027 "parse.y"
{
		    Sym_Enter(yyvsp[-2].ident, SYM_NUMBER, Expr_Copy(&expr1, TRUE), yyvsp[-1].number);
		;
    break;}
case 120:
#line 2031 "parse.y"
{
		    if (yyvsp[-2].sym->u.equate.rdonly) {
			/*
			 * Generate a warning if the new value differs from the
			 * old.
			 */
			if ((yyvsp[-2].sym->u.equate.value->numElts != 2) ||
			    (expr1.numElts != 2) ||
			    (yyvsp[-2].sym->u.equate.value->elts[0].op != EXPR_CONST) ||
			    (expr1.elts[0].op != EXPR_CONST) ||
			    (yyvsp[-2].sym->u.equate.value->elts[1].value !=
			     expr1.elts[1].value))
			{
			    yywarning("%i redefined", yyvsp[-2].sym->name);
			}
		    } else if (yyvsp[-1].number) {
			yywarning("%i was defined with '=' before",
				  yyvsp[-2].sym->name);
		    }
		    yyvsp[-2].sym->u.equate.rdonly = yyvsp[-1].number;
		    Expr_Free(yyvsp[-2].sym->u.equate.value);
		    yyvsp[-2].sym->u.equate.value = Expr_Copy(&expr1, TRUE);
		;
    break;}
case 121:
#line 2055 "parse.y"
{
		    /*
		     * This can be used to set the value given to the next
		     * member added to the type.
		     */
		    yyvsp[-2].sym->u.eType.nextVal = yyvsp[0].number;
		;
    break;}
case 122:
#line 2063 "parse.y"
{
		    Sym_Enter(yyvsp[-1].ident, SYM_NUMBER, yyvsp[0].expr, FALSE);
		;
    break;}
case 123:
#line 2067 "parse.y"
{
		    if (yyvsp[-1].sym->u.equate.rdonly) {
			yywarning("%i redefined with string operator",
				  yyvsp[-1].sym->name);
		    }
		    Expr_Free(yyvsp[-1].sym->u.equate.value);

		    yyvsp[-1].sym->u.equate.value = yyvsp[0].expr;
		;
    break;}
case 124:
#line 2078 "parse.y"
{
		    ResetExpr(&expr1, defElts1);
		    StoreExprConst((long)strlen(yyvsp[0].string));
		    free(yyvsp[0].string);

		    yyval.expr = Expr_Copy(&expr1, TRUE);
		    malloc_settag((void *)yyval.expr, TAG_EQUATE_EXPR);
		;
    break;}
case 125:
#line 2087 "parse.y"
{
		    if (expr1.elts[0].op != EXPR_STRING) {
			yyerror("two-operand INSTR directive requires string as first operand");
			yynerrs++;
			ResetExpr(&expr1, defElts1);
			StoreExprConst(0L);
			free(yyvsp[0].string);
		    } else {
			long	n = FindSubstring(expr1.elts[1].str, yyvsp[0].string);

			free(yyvsp[0].string);
			ResetExpr(&expr1, defElts1);
			/*
			 * Wants the index to be 1-origin with 0 => no such
			 * substring around.
			 */
			StoreExprConst(n+1);
		    }

		    yyval.expr = Expr_Copy(&expr1, TRUE);
		    malloc_settag((void *)yyval.expr, TAG_EQUATE_EXPR);
		;
    break;}
case 126:
#line 2110 "parse.y"
{
		    ExprResult	result;
		    int	    	start;

		    /*
		     * Evaluate the expression we just parsed, disallowing
		     * any undefined symbols. XXX: What about scope
		     * checks for methods and instance variables? Still
		     * enabled at the moment...
		     */
		    if (!Expr_Eval(&expr1, &result, EXPR_NOUNDEF|EXPR_FINALIZE,
				   NULL))
		    {
			/*
			 * Give error message we got back
			 */
			yyerror((char *)result.type);
			yynerrs++;
			ResetExpr(&expr1, defElts1);
			StoreExprConst(0L);
		    } else if (result.type == EXPR_TYPE_CONST &&
			       !result.rel.sym)
		    {
			/*
			 * Use the value we got back, converting it to 0-origin
			 */
			start = result.data.number-1;
			ResetExpr(&expr1, defElts1);

			if (start < 0) {
			    yyerror("search start must be >= 1");
			    yynerrs++;
			    StoreExprConst(0);
			} else if (start >= strlen(yyvsp[-2].string)) {
			    yyerror("search start %d is beyond end of string",
				    start+1);
			    yynerrs++;
			    StoreExprConst(0);
			} else {
			    /*
			     * Find the index, converting it to 1-origin.
			     * Since FindSubstring returns -1 if the substring
			     * can't be found, this also takes care of
			     * evaluating to 0 if the string can't be found.
			     */
			    StoreExprConst(FindSubstring(yyvsp[-2].string+start,yyvsp[0].string)+1);
			}
		    } else {
			/*
			 * Expression valid but not constant -- choke.
			 */
			yyerror("numeric constant expected for search start");
			yynerrs++;
			ResetExpr(&expr1, defElts1);
			StoreExprConst(0L);
		    }
		    free(yyvsp[-2].string);
		    free(yyvsp[0].string);

		    yyval.expr = Expr_Copy(&expr1, TRUE);
		    malloc_settag((void *)yyval.expr, TAG_EQUATE_EXPR);
		;
    break;}
case 127:
#line 2184 "parse.y"
{
		    /*
		     * Has to be numeric, so set emptyIsConst true, then
		     * convert the data size into a type description.
		     */
		    emptyIsConst = 1;
		    if (yyvsp[0].number == 0) {
		        yyval.type = Type_Char(1);
		    } else if (yyvsp[0].number == 'z') {
		        yyval.type = Type_Char(2);
		    } else {
		        yyval.type = Type_Int(yyvsp[0].number);
		    }
		    checkForStrings = (yyvsp[0].number >= -1 && yyvsp[0].number <= 1);
		;
    break;}
case 128:
#line 2200 "parse.y"
{
		    /*
		     * Set emptyIsConst true if type isn't complex (array or
		     * a structured type whose initializer must be a string).
		     * Note that we have to be careful of typedefs here (and
		     * later on). If $1 is a typedef, reduce it to its
		     * basest type. This allows us to properly handle
		     * array typedef initializers, for example.
		     */
		    TypePtr checkType = yyvsp[0].type;

		    while (checkType->tn_type == TYPE_STRUCT &&
			   checkType->tn_u.tn_struct->type == SYM_TYPE)
		    {
			checkType = checkType->tn_u.tn_struct->u.typeDef.type;
		    }
		    emptyIsConst =
			!(checkType->tn_type==TYPE_ARRAY ||
			  (checkType->tn_type==TYPE_STRUCT &&
			   (checkType->tn_u.tn_struct->type==SYM_STRUCT ||
			    checkType->tn_u.tn_struct->type==SYM_RECORD ||
			    checkType->tn_u.tn_struct->type==SYM_UNION)));

		    /*
		     * If defining an array, structure, record or union, we
		     * allow for comments and newlines inside <> strings in
		     * the scanner (the scanner strips all newlines and comments
		     * from the string before returning it)
		     */
		    defStruct = !emptyIsConst;

		    /*
		     * If type descriptor describes either an array of
		     * bytes/chars or it is "char" or "byte", we have to
		     * be careful about strings and count each character as
		     * an individual element...
		     */
		    checkForStrings =
			((checkType->tn_type == TYPE_ARRAY &&
			 Type_Size(checkType->tn_u.tn_array.tn_base)==1) ||
			 (checkType->tn_type == TYPE_CHAR) ||
			 (checkType->tn_type == TYPE_INT &&
			  checkType->tn_u.tn_int == 1))
;
		    yyval.type = yyvsp[0].type;

		    if ((checkType->tn_type == TYPE_STRUCT) &&
			(checkType->tn_u.tn_struct == inStruct))
		    {
			yyerror("recursive structure/union");
			yynerrs++;
		    } else if ((checkType->tn_type == TYPE_STRUCT) &&
			       (checkType->tn_u.tn_struct->u.typesym.size == 0))
		    {
			yyerror("illegal use of zero-sized structure");
			yynerrs++;
			YYERROR;
		    }
		;
    break;}
case 129:
#line 2261 "parse.y"
{
		    if (yyvsp[0].number != 1) {
			DefineData(yyvsp[-2].ident, Type_Array(yyvsp[0].number, yyvsp[-1].type), TRUE, TRUE);
		    } else {
			DefineData(yyvsp[-2].ident, yyvsp[-1].type, TRUE, FALSE);
		    }
		    defStruct = FALSE;
		;
    break;}
case 130:
#line 2270 "parse.y"
{
		    if (yyvsp[0].number != 1) {
			DefineDataSym(yyvsp[-2].sym, Type_Array(yyvsp[0].number, yyvsp[-1].type), TRUE, TRUE);
		    } else {
			DefineDataSym(yyvsp[-2].sym, yyvsp[-1].type, TRUE, FALSE);
		    }
		    defStruct = FALSE;
		;
    break;}
case 131:
#line 2279 "parse.y"
{
		    yyerror("%i is already an instance variable for %i",
			    yyvsp[-2].sym->name, yyvsp[-2].sym->u.instvar.class->name);
		    yynerrs++;
		;
    break;}
case 132:
#line 2285 "parse.y"
{
		    if (yyvsp[0].number != 1) {
			DefineData(NullID, Type_Array(yyvsp[0].number, yyvsp[-1].type), TRUE, TRUE);
		    } else {
			DefineData(NullID, yyvsp[-1].type, TRUE, FALSE);
		    }
		    defStruct = FALSE;
		;
    break;}
case 133:
#line 2301 "parse.y"
{
		    yyval.ident = NullID;
		    if (curSeg->u.segment.data->comb != SEG_LMEM) {
			yyerror("CHUNK directive is not allowed inside non-lmem segment %i",
				curSeg->name);
			yynerrs++;
		    } else if (curChunk) {
			yyerror("Nested CHUNK declarations are not allowed (defining %i now)",
				curChunk->name);
			yynerrs++;
		    } else {
			yyval.ident = yyvsp[-1].ident;
		    }
		;
    break;}
case 135:
#line 2316 "parse.y"
{
		    yyval.ident = NullID;
		    if (curSeg->u.segment.data->comb != SEG_LMEM) {
			yyerror("CHUNK directive is not allowed inside non-lmem segment %i",
				curSeg->name);
			yynerrs++;
		    } else if (curChunk) {
			yyerror("Nested CHUNK declarations are not allowed (defining %i now)",
				curChunk->name);
			yynerrs++;
		    } else if ((yyvsp[-1].sym->type == SYM_CHUNK) &&
			       ((yyvsp[-1].sym->flags & SYM_UNDEF) == 0))
		    {
			yyerror("chunk %i is already defined", yyvsp[-1].sym->name);
			yynerrs++;
		    } else if ((yyvsp[-1].sym->type == SYM_CHUNK) &&
			       (yyvsp[-1].sym->flags & SYM_UNDEF))
		    {
			/*
			 * Declared global before with :chunk, so it's ok.
			 */
			yyval.ident = yyvsp[-1].sym->name;
			if (!LMem_UsesHandles(curSeg)) {
			    /*
			     * Chunk will be redefined as a SYM_VAR, so
			     * prevent death.
			     * XXX: this should be in LMem module.
			     */
			    yyvsp[-1].sym->type = SYM_VAR;
			}
		    } else if ((LMem_UsesHandles(curSeg) &&
				(yyvsp[-1].sym->type != SYM_CHUNK)) ||
			       (!LMem_UsesHandles(curSeg) &&
				(yyvsp[-1].sym->type != SYM_VAR)))
		    {
			yyerror("%i is already something other than a chunk",
				yyvsp[-1].sym->name);
			yynerrs++;
		    } else {
			yyval.ident = yyvsp[-1].sym->name;
		    }
		;
    break;}
case 137:
#line 2359 "parse.y"
{
		    yyval.ident = NullID;
		    if (curSeg->u.segment.data->comb != SEG_LMEM) {
			yyerror("CHUNK directive is not allowed inside non-lmem segment %i",
				curSeg->name);
			yynerrs++;
		    } else if (curChunk) {
			yyerror("Nested CHUNK declarations are not allowed (defining %i now)",
				curChunk->name);
			yynerrs++;
		    }
		;
    break;}
case 139:
#line 2374 "parse.y"
{
		    if ( warn_localize && localizationRequired ){
			Parse_LastChunkWarning("Missing @localize instruction");
			localizationRequired = 0;
		    }
		    lastChunk = curChunk = LMem_DefineChunk(yyvsp[0].type, yyvsp[-1].ident);
		    ParseSetLastChunkWarningInfo();
		;
    break;}
case 140:
#line 2383 "parse.y"
{
		    SymbolPtr   chunk;
		    if (yyvsp[0].number > 1) {
			TypePtr	t = Type_Array(yyvsp[0].number, yyvsp[-1].type);

			if ( warn_localize && localizationRequired ){
			    Parse_LastChunkWarning("Missing @localize instruction");
			    localizationRequired = 0;
			}
		    	lastChunk = chunk = LMem_DefineChunk(t, yyvsp[-3].ident);
			ParseSetLastChunkWarningInfo();
			DefineData(NullID, t, TRUE, TRUE);
		    } else {
			if ( warn_localize && localizationRequired ){
			    Parse_LastChunkWarning("Missing @localize instruction");
			    localizationRequired = 0;
			}
			lastChunk = chunk = LMem_DefineChunk(yyvsp[-1].type, yyvsp[-3].ident);
			ParseSetLastChunkWarningInfo();
			DefineData(NullID, yyvsp[-1].type, TRUE, FALSE);
		    }
		    defStruct = FALSE;

		    if (chunk != NullSymbol) {
			LMem_EndChunk(chunk);
			ParseLocalizationCheck();
		    }
		;
    break;}
case 142:
#line 2413 "parse.y"
{ yyval.type = Type_Void(); ;
    break;}
case 143:
#line 2416 "parse.y"
{
		    if (curChunk == NULL) {
			yyerror("not defining a chunk, so %i can't be ending",
				yyvsp[-1].sym->name);
			yynerrs++;
		    } else if (yyvsp[-1].sym != curChunk) {
			yyerror("%i is not the current chunk (%i is)",
				yyvsp[-1].sym->name, curChunk->name);
			yynerrs++;
		    } else {
			/*
			 * Note: Need to set curChunk to NULL before calling
			 * LMem_EndChunk as that will in turn call PopSegment,
			 * which will be upset if curChunk is non-null, call
			 * LMem_EndChunk, which will call PopSegment, ...
			 */
			SymbolPtr   chunk = curChunk;

			curChunk = NULL;
			LMem_EndChunk(chunk);
			ParseLocalizationCheck();
		    }
		;
    break;}
case 144:
#line 2441 "parse.y"
{
		    if (curChunk == NULL) {
			yyerror("not defining a chunk, so you can't end it");
			yynerrs++;
		    } else {
			/*
			 * Note: Need to set curChunk to NULL before calling
			 * LMem_EndChunk as that will in turn call PopSegment,
			 * which will be upset if curChunk is non-null, call
			 * LMem_EndChunk, which will call PopSegment, ...
			 */
			SymbolPtr   chunk = curChunk;

			curChunk = NULL;
			LMem_EndChunk(chunk);
			ParseLocalizationCheck();
		    }
		;
    break;}
case 145:
#line 2460 "parse.y"
{
		    /*
		     * Pretend code can't be reached so Data_Enter won't
		     * bitch about in-line data.
		     */
		    int	prevLast = curSeg->u.segment.data->lastLabel;

		    /*
		     * Following taken from the START_CODEGEN macro in
		     * code.c....
		     */
		    if (warn_unreach && curSeg->u.segment.data->checkLabel &&
			((dot) != curSeg->u.segment.data->lastLabel))
		    {
			yywarning("code cannot be reached");
		    }
		    if (fall_thru)
		    {
			yywarning("code generated after .fall_thru");
		    }
		    if (do_bblock &&
			(curSeg->u.segment.data->checkLabel ||
			 curSeg->u.segment.data->blockStart ||
			 ((dot) == curSeg->u.segment.data->lastLabel)))
		    {
			Code_ProfileBBlock(&dot);
		    }

		    curSeg->u.segment.data->checkLabel = TRUE;
		    curSeg->u.segment.data->lastLabel = dot-1;
		    /*
		     * Now enter the data into the segment.
		     */
		    if (yyvsp[0].number > 1) {
			DefineData(NullID, Type_Array(yyvsp[0].number, yyvsp[-1].type), TRUE, TRUE);
		    } else {
			DefineData(NullID, yyvsp[-1].type, TRUE, FALSE);
		    }
		    /*
		     * Set checkLabel false to avoid multiple code-cannot-be-
		     * reached warnings.
		     */
		    curSeg->u.segment.data->checkLabel = FALSE;
		    curSeg->u.segment.data->lastLabel = prevLast;
		    /*
		     * Set blockStart to true, as we don't know what type of
		     * instruction we just put in, and it's better to have too
		     * many profile markers than too few...
		     */
		    curSeg->u.segment.data->blockStart = TRUE;
		    defStruct = FALSE;
		;
    break;}
case 146:
#line 2520 "parse.y"
{
		    yyval.number = yyvsp[0].number;
		;
    break;}
case 148:
#line 2526 "parse.y"
{
		    yyval.number = yyvsp[-2].number + yyvsp[0].number;
		;
    break;}
case 149:
#line 2531 "parse.y"
{
		    yyval.number = 1;
		    if (emptyIsConst) {
			/*
			 * Non-structured type -- store a constant 0
			 */
			StoreExprConst(0);
		    } else {
			/*
			 * Structured type -- store an empty string.
			 */
			StoreExprString(EXPR_INIT, "");
		    }
		    StoreExprComma();
		;
    break;}
case 150:
#line 2547 "parse.y"
{
		    if (checkForStrings &&
			(curExpr->elts[yyvsp[0].number].op == EXPR_STRING))
		    {
			int nelts = ExprStrElts(curExpr->elts[yyvsp[0].number+1].str);
			int len = strlen(curExpr->elts[yyvsp[0].number+1].str);

			if (curExpr->numElts == yyvsp[0].number+1+nelts && len > 1) {
			    /*
			     * If we're defining byte-data and this component
			     * is a multi-character string all its own (i.e.
			     * without any accompanying operators), then
			     * we want to use the length of the string to be
			     * the number of elements for the definition.
			     * Otherwise, we'd say
			     *	db  "hi there"
			     * is an array of 1 byte, and we'd be wrong.
			     */
			    yyval.number = len;
			} else {
			    yyval.number = 1;
			}
		    } else {
			yyval.number = 1;
		    }
		    StoreExprComma();
		;
    break;}
case 151:
#line 2575 "parse.y"
{
		    /*
		     * Record the number of elements for proper duplication.
		     * The number must be a constant. We default the thing to
		     * 1 in case of error to avoid confusing DupExpr.
		     */
		    Expr    	cexpr;
		    ExprResult	result;
		    int	    	value = 1;

		    /*
		     * Manufacture a new expression that points to the
		     * elements we just entered, disallowing any
		     * undefined symbols.
		     */
		    cexpr = *curExpr;
		    cexpr.elts += yyvsp[-1].number;
		    cexpr.numElts -= yyvsp[-1].number;

		    if (!Expr_Eval(&cexpr, &result, EXPR_NOUNDEF|EXPR_FINALIZE,
				   NULL))
		    {
			/*
			 * Give error message we got back
			 */
			yyerror((char *)result.type);
			yynerrs++;
		    } else if (result.type == EXPR_TYPE_CONST &&
			       !result.rel.sym)
		    {
			/*
			 * Use the result we got back
			 */
			value = result.data.number;
		    } else {
			yyerror("invalid length for DUP operator");
			yynerrs++;
		    }

		    /*
		     * Reset current expression back to where it was before
		     * we usurped it to store the length
		     */
		    curExpr->numElts = yyvsp[-1].number;
		    /*
		     * Record the length of the array as our semantic value
		     */
		    yyval.number = value;
		;
    break;}
case 152:
#line 2625 "parse.y"
{
		    /*
		     * Copy all elements between start and now the number of
		     * times indicated by the cexpr. We reduce that number
		     * by one b/c we've already got one copy...
		     */
		    if (yyvsp[-3].number > 1) {
		    	DupExpr(yyvsp[-3].number-1, yyvsp[-5].number);
		    } else if (yyvsp[-3].number == 0) {
			/*
			 * No duplications, so return the expression to the
			 * state it was in before this whole hoax was
			 * perpetrated on us.
			 */
			curExpr->numElts = yyvsp[-5].number;
		    }
		    yyval.number = yyvsp[-3].number * yyvsp[-1].number;
		;
    break;}
case 153:
#line 2652 "parse.y"
{
		    /*
		     * Record current element count in case DUP operator given
		     */
		    yyval.number = curExpr->numElts;
		;
    break;}
case 154:
#line 2659 "parse.y"
{
		    /*
		     * Return initial element count as our value
		     */
		    yyval.number = yyvsp[-1].number;
		;
    break;}
case 155:
#line 2673 "parse.y"
{
		    if (localize) {
			yyvsp[-1].sym->u.chunk.loc->instructions = yyvsp[0].string;
		    }
		    localizationRequired = 0;
		;
    break;}
case 156:
#line 2680 "parse.y"
{
		    if (localize) {
			yyvsp[-3].sym->u.chunk.loc->instructions = yyvsp[-2].string;
			yyvsp[-3].sym->u.chunk.loc->max = yyvsp[0].number;
		    }
		    localizationRequired = 0;
		;
    break;}
case 157:
#line 2688 "parse.y"
{
		    if (localize) {
			yyvsp[-5].sym->u.chunk.loc->instructions = yyvsp[-4].string;
			yyvsp[-5].sym->u.chunk.loc->min = yyvsp[-2].number;
			yyvsp[-5].sym->u.chunk.loc->max = yyvsp[0].number;
		    }
		    localizationRequired = 0;
		;
    break;}
case 158:
#line 2697 "parse.y"
{
		    if (localize) {
			yyvsp[-7].sym->u.chunk.loc->instructions = yyvsp[-6].string;
			yyvsp[-7].sym->u.chunk.loc->min = yyvsp[-4].number;
			yyvsp[-7].sym->u.chunk.loc->max = yyvsp[-2].number;
			yyvsp[-7].sym->u.chunk.loc->dataTypeHint = yyvsp[0].number;
		    }
		    localizationRequired = 0;
		;
    break;}
case 159:
#line 2707 "parse.y"
{
		    if (localize) {
			/*
			 *  mark it as not localizable for localize.c
			 */
			yyvsp[-1].sym->u.chunk.loc->min = -1;
			yyvsp[-1].sym->u.chunk.loc->max = -1;
		    }
		    localizationRequired = 0;
		;
    break;}
case 160:
#line 2720 "parse.y"
{
		    if (localize) {
			/*
			 * Make sure the thing has a localization record.
			 */
			if (yyvsp[0].sym->u.chunk.loc == 0) {
			    yyvsp[0].sym->u.chunk.loc = Sym_AllocLoc(yyvsp[0].sym, CDT_unknown);
			}
			/*
			 * Free any previous instructions and warn the user of
			 * the redefinition.
			 */
			if (yyvsp[0].sym->u.chunk.loc->instructions != 0) {
			    yywarning("localization instructions already given for %i", yyvsp[0].sym->name);
			    free(yyvsp[0].sym->u.chunk.loc->instructions);
			}
		    }
		    yyval.sym = yyvsp[0].sym;
		;
    break;}
case 161:
#line 2742 "parse.y"
{
		    if (yyvsp[-1].sym->type == SYM_CHUNK) {
			yyval.sym = yyvsp[-1].sym;
		    } else {
			yyerror("%i is not an lmem chunk.", yyvsp[-1].sym->name);
			YYERROR;
		    }
		;
    break;}
case 162:
#line 2751 "parse.y"
{
		    if (lastChunk == 0) {
			yyerror("You haven't defined an lmem chunk yet, so there's nothing to localize.");
			YYERROR;
		    } else if (lastChunk->name == NullID) {
			yyerror("The most-recent chunk cannot be localized as it has no name");
			YYERROR;
		    } else {
			yyval.sym = lastChunk;
		    }
		;
    break;}
case 163:
#line 2770 "parse.y"
{
		    /*
		     * Process macros again...
		     */
		    ignore = FALSE;
		;
    break;}
case 164:
#line 2777 "parse.y"
{
		    ignore = FALSE;
		;
    break;}
case 165:
#line 2782 "parse.y"
{
		    switch(yyvsp[-2].sym->type) {
			case SYM_PUBLIC:
			    /*
			     * Transform to the proper, undefined type of
			     * symbol.
			     */
			    switch(yyvsp[0].type->tn_type) {
				case TYPE_NEAR:
				    yyvsp[-2].sym->type = SYM_PROC;
				    yyvsp[-2].sym->u.proc.flags = SYM_NEAR;
				    yyvsp[-2].sym->u.proc.locals = NULL;
				    break;
				case TYPE_FAR:
				    yyvsp[-2].sym->type = SYM_PROC;
				    yyvsp[-2].sym->u.proc.flags = 0;
				    yyvsp[-2].sym->u.proc.locals = NULL;
				    break;
				default:
				    yyvsp[-2].sym->type = SYM_VAR;
				    yyvsp[-2].sym->u.var.type = yyvsp[0].type;
				    break;
			    }
			    yyvsp[-2].sym->u.addrsym.offset = 0;
			    yyvsp[-2].sym->flags |= SYM_UNDEF;
			    break;
			case SYM_MACRO:
			case SYM_SEGMENT:
			case SYM_GROUP:
			case SYM_ETYPE:
			case SYM_TYPE:
			case SYM_STRUCT:
			case SYM_RECORD:
			case SYM_LOCAL:
			case SYM_LOCALLABEL:
			    yyerror("%i: inappropriate symbol type for GLOBAL",
				    yyvsp[-2].sym->name);
			    yynerrs++;
			    break;
			default:
			    /*
			     * Make sure the type corresponds to the existing
			     * one.
			     */
			    switch(yyvsp[0].type->tn_type) {
				case TYPE_NEAR:
				    if (!Sym_IsNear(yyvsp[-2].sym)) {
					yyerror("%i: type mismatch: not a near procedure or label",
						yyvsp[-2].sym->name);
					yynerrs++;
				    }
				    break;
				case TYPE_FAR:
				    if ((yyvsp[-2].sym->type != SYM_LABEL &&
					 yyvsp[-2].sym->type != SYM_PROC) ||
					Sym_IsNear(yyvsp[-2].sym))
				    {
					yyerror("%i: type mismatch: not a far procedure or label",
						yyvsp[-2].sym->name);
					yynerrs++;
				    }
				    break;
				default:
				{
				    TypePtr type;

				    switch(yyvsp[-2].sym->type) {
					case SYM_VAR:
					    type = yyvsp[-2].sym->u.var.type;
					    break;
					case SYM_INSTVAR:
					    type = yyvsp[-2].sym->u.instvar.type;
					    break;
					case SYM_FIELD:
					    type = yyvsp[-2].sym->u.field.type;
					    break;
					default:
					    type = NULL;
					    break;
				    }
				    if (!Type_Equal(type, yyvsp[0].type)) {
					yyerror("%i: type mismatch",
						yyvsp[-2].sym->name);
					yynerrs++;
				    }
				    break;
				}
			    }
#if 0
/* if symbol already exists, it is unlikely to be undefined, wot? */
			    yyvsp[-2].sym->flags |= SYM_UNDEF;
#endif
			    break;
		    }
		;
    break;}
case 166:
#line 2878 "parse.y"
{
		    if (yyvsp[-3].sym->type == SYM_PUBLIC) {
			/*
			 * Transform to undefined chunk...
			 */
			if ((curSeg->u.segment.data->comb != SEG_LMEM) &&
			    (curSeg->u.segment.data->comb != SEG_GLOBAL))
			{
			    yyerror("%i: segment mismatch (chunk symbol can't be in non-lmem segment)",
				    yyvsp[-3].sym->name);
			    yynerrs++;
			} else {
			    /*
			     * Switch the segment to be the heap part of the
			     * group so glue doesn't bitch. Note we only do
			     * this if not defining a chunk. If defining a
			     * chunk, we're already in the correct subsegment.
			     */
			    yyvsp[-3].sym->type = SYM_CHUNK;
			    if (curChunk == NULL &&
				curSeg->u.segment.data->comb == SEG_LMEM)
			    {
				yyvsp[-3].sym->segment = curSeg->u.segment.data->pair;
			    }
			    yyvsp[-3].sym->flags = SYM_UNDEF|SYM_GLOBAL;
			    yyvsp[-3].sym->u.chunk.common.offset = 0;
			    yyvsp[-3].sym->u.chunk.handle = 0;
			    yyvsp[-3].sym->u.chunk.type = yyvsp[0].type;
			}
		    } else if (yyvsp[-3].sym->type == SYM_CHUNK) {
			if (!Type_Equal(yyvsp[-3].sym->u.chunk.type, yyvsp[0].type)) {
			    yyerror("%i: type mismatch",
				    yyvsp[-3].sym->name);
			    yynerrs++;
			}
		    } else {
			yyerror("%i: type mismatch: not a chunk symbol",
				yyvsp[-3].sym->name);
			yynerrs++;
		    }
		;
    break;}
case 167:
#line 2920 "parse.y"
{
		    if (yyvsp[-3].sym->type == SYM_PUBLIC) {
			/*
			 * Transform to undefined FAR label
			 */
			yyvsp[-3].sym->type = SYM_LABEL;
			yyvsp[-3].sym->flags = SYM_UNDEF|SYM_GLOBAL;
			yyvsp[-3].sym->u.label.near = 0;
		    } else if (yyvsp[-3].sym->type != SYM_LABEL || yyvsp[-3].sym->u.label.near) {
			yyerror("%i: type mismatch: wasn't a far label before",
				yyvsp[-3].sym->name);
			yynerrs++;
		    }
		;
    break;}
case 168:
#line 2935 "parse.y"
{
		    if (yyvsp[-3].sym->type == SYM_PUBLIC) {
			/*
			 * Transform to undefined NEAR label
			 */
			yyvsp[-3].sym->type = SYM_LABEL;
			yyvsp[-3].sym->flags = SYM_UNDEF|SYM_GLOBAL;
			yyvsp[-3].sym->u.label.near = TRUE;
		    } else if (yyvsp[-3].sym->type != SYM_LABEL || !yyvsp[-3].sym->u.label.near) {
			yyerror("%i: type mismatch: wasn't a near label before",
				yyvsp[-3].sym->name);
			yynerrs++;
		    }
		;
    break;}
case 171:
#line 2959 "parse.y"
{
		    yyval.sym = Sym_Enter(yyvsp[0].ident, SYM_PUBLIC, curFile->name, yylineno);
		;
    break;}
case 172:
#line 2963 "parse.y"
{
		    yyval.sym = yyvsp[0].sym;
		    yyval.sym->flags |= SYM_GLOBAL;
		    /*
		     * If symbol was previously declared within the global
		     * (nameless) segment, switch it to be this segment
		     * instead.
		     */
		    if (yyval.sym->segment->name == NullID) {
			yyval.sym->segment = curSeg;
		    }
		;
    break;}
case 173:
#line 2976 "parse.y"
{
		    yyval.sym = yyvsp[0].sym;
		    yyval.sym->flags |= SYM_GLOBAL;
		    /*
		     * If symbol was previously declared within the global
		     * (nameless) segment, switch it to be this segment
		     * instead.
		     */
		    if (yyval.sym->segment->name == NullID) {
			yyval.sym->segment = curSeg;
		    }
		;
    break;}
case 174:
#line 2989 "parse.y"
{
		    yyval.sym = yyvsp[0].sym;
		    yyval.sym->flags |= SYM_GLOBAL;
		    /*
		     * If symbol was previously declared within the global
		     * (nameless) segment, switch it to be this segment
		     * instead.
		     */
		    if (yyval.sym->segment->name == NullID) {
			yyval.sym->segment = curSeg;
		    }
		;
    break;}
case 182:
#line 3010 "parse.y"
{
		    switch(yyvsp[0].sym->type) {
			case SYM_MACRO:
			case SYM_SEGMENT:
			case SYM_GROUP:
			case SYM_ETYPE:
			case SYM_TYPE:
			case SYM_STRUCT:
			case SYM_RECORD:
			case SYM_LOCAL:
			case SYM_LOCALLABEL:
			    yyerror("%i: inappropriate symbol type for PUBLIC",
				    yyvsp[0].sym->name);
			    yynerrs++;
			    break;
			default:
			    /*
			     * Anything else can safely be marked global.
			     */
			    yyvsp[0].sym->flags |= SYM_GLOBAL;
			    break;
		    }
		;
    break;}
case 185:
#line 3044 "parse.y"
{
		    if (inStruct) {
			yyerror("already defining %i; nested definitions not allowed",
				inStruct->name);
		    } else {
			inStruct = Sym_Enter(yyvsp[-1].ident, SYM_STRUCT);
		    }
		;
    break;}
case 186:
#line 3053 "parse.y"
{
		    if (yyvsp[-1].sym->type != SYM_STRUCT) {
			yyerror("cannot redefine union %i", yyvsp[-1].sym->name);
			yynerrs++;
		    } else if (yyvsp[-1].sym->u.typesym.size == 0) {
			/*
			 * Structure was referenced before either by
			 * declaring it empty or by declaring something
			 * to be a pointer to it.
			 * Allow a true definition now. Set the segment
			 * of the symbol to match the current one, rather
			 * than the one where it was first used...
			 */
			inStruct = yyvsp[-1].sym;
			yyvsp[-1].sym->flags &= ~SYM_NOWRITE;
			yyvsp[-1].sym->segment = curSeg;
		    } else {
			yyerror("cannot redefine structure %i", yyvsp[-1].sym->name);
			yynerrs++;
		    }
		;
    break;}
case 187:
#line 3075 "parse.y"
{
		    if (yyvsp[-1].sym != inStruct) {
			if (inStruct) {
			    yyerror("cannot end struct/union %i while in %i",
				    yyvsp[-1].sym->name, inStruct->name);
			} else {
			    yyerror("not defining any struct/union, so can't end %i",
				    yyvsp[-1].sym->name);
			}
			yynerrs++;
		    } else {
			inStruct = NullSymbol;
		    }
		;
    break;}
case 188:
#line 3090 "parse.y"
{
		    inStruct = Sym_Enter(yyvsp[-1].ident, SYM_UNION);
		;
    break;}
case 189:
#line 3094 "parse.y"
{
		    if (yyvsp[-1].sym->type != SYM_UNION) {
			yyerror("cannot redefine structure %i", yyvsp[-1].sym->name);
			yynerrs++;
		    } else if (yyvsp[-1].sym->u.typesym.size == 0) {
			/*
			 * Union was referenced before either by
			 * declaring it empty or by declaring something
			 * to be a pointer to it.
			 * Allow a true definition now. Set the segment
			 * of the symbol to match the current one, rather
			 * than the one where it was first used...
			 */
			inStruct = yyvsp[-1].sym;
			yyvsp[-1].sym->flags &= ~SYM_NOWRITE;
			yyvsp[-1].sym->segment = curSeg;
		    } else {
			yyerror("cannot redefine union %i", yyvsp[-1].sym->name);
			yynerrs++;
		    }
		;
    break;}
case 190:
#line 3116 "parse.y"
{
		    if (yyvsp[-1].sym != inStruct) {
			if (inStruct) {
			    yyerror("cannot end struct/union %i while in %i",
				    yyvsp[-1].sym->name, inStruct->name);
			} else {
			    yyerror("not defining any struct/union, so can't end %i",
				    yyvsp[-1].sym->name);
			}
			yynerrs++;
		    } else {
			inStruct = NullSymbol;
		    }
		;
    break;}
case 191:
#line 3134 "parse.y"
{
		    /*
		     * Create a symbol for the thing and point the 'first'
		     * field at the list of BITFIELD symbols returned by
		     * recordDefs.
		     *
		     * The first element of that list will be the one with
		     * the highest bit offset (offsets are allocated from
		     * the right), so from it we can figure out how many
		     * bytes the record should take, as well as forming the
		     * overall mask for the type.
		     */
		    SymbolPtr	sym = Sym_Enter(yyvsp[-2].ident, SYM_RECORD);
		    SymbolPtr	fld;

		    sym->u.record.first = yyvsp[0].sym;

		    if (yyvsp[0].sym) {
			int limit = (yyvsp[0].sym->u.bitField.offset +
				     yyvsp[0].sym->u.bitField.width);

			if (limit > 16) {
			    yyerror("record may not be larger than a word");
			    yynerrs++;
			}

			sym->u.record.mask = (1 << limit) - 1;
			sym->u.record.common.size = (limit+7)/8;
			/*
			 * Now traverse the list to get to the last
			 * one and link it back to the record type.
			 * Sure this is inefficient, but no more so
			 * than creating the record symbol first and
			 * carrying it along as $<sym>0 through all the
			 * recordDefs rules... Besides, you're never
			 * going to have more than 32 of these things,
			 * even on a '386, so bugger off if you don't
			 * like this :)
			 */
			for (fld = yyvsp[0].sym;
			     fld->u.bitField.common.next;
			     fld = fld->u.bitField.common.next)
			{
			    if (fld->name == NullID) {
				/*
				 * Remove nameless fields from the record mask.
				 * This allows the NOT record_sym to test the
				 * unused bits...
				 */
				sym->u.record.mask &=
				    ~(((1<<(fld->u.bitField.offset+
					    fld->u.bitField.width))-1) ^
				      ((1<<fld->u.bitField.offset)-1));
			    }
			}
			if (fld->name == NullID) {
			    /*
			     * Remove nameless fields from the record mask.
			     * This allows the NOT record_sym to test the
			     * unused bits...
			     */
			    sym->u.record.mask &=
				~(((1<<(fld->u.bitField.offset+
					fld->u.bitField.width))-1) ^
				  ((1<<fld->u.bitField.offset)-1));
			}
			fld->u.bitField.common.next = sym;
		    }
		;
    break;}
case 192:
#line 3204 "parse.y"
{
		    Sym_Enter(yyvsp[-2].ident, SYM_TYPE, yyvsp[0].type);
		;
    break;}
case 195:
#line 3217 "parse.y"
{
		    yyvsp[0].sym->u.bitField.common.next = NULL;
		    yyval.sym = yyvsp[0].sym;
		;
    break;}
case 196:
#line 3222 "parse.y"
{
		    yyvsp[-2].sym->u.bitField.offset = yyvsp[0].sym->u.bitField.offset +
			yyvsp[0].sym->u.bitField.width;
		    yyvsp[-2].sym->u.bitField.common.next = yyvsp[0].sym;
		    yyval.sym = yyvsp[-2].sym;
		;
    break;}
case 197:
#line 3234 "parse.y"
{ yyval.sym = yyvsp[0].sym; ;
    break;}
case 198:
#line 3236 "parse.y"
{ yyval.sym = NULL; ;
    break;}
case 199:
#line 3238 "parse.y"
{
		    if (yyvsp[0].sym != NULL) {
			yyvsp[-2].sym->u.bitField.offset = yyvsp[0].sym->u.bitField.offset +
			    yyvsp[0].sym->u.bitField.width;
		    }
		    yyvsp[-2].sym->u.bitField.common.next = yyvsp[0].sym;
		    yyval.sym = yyvsp[-2].sym;
		;
    break;}
case 200:
#line 3247 "parse.y"
{
		    if (yyvsp[0].sym != NULL) {
			yyvsp[-3].sym->u.bitField.offset = yyvsp[0].sym->u.bitField.offset +
			    yyvsp[0].sym->u.bitField.width;
		    }
		    yyvsp[-3].sym->u.bitField.common.next = yyvsp[0].sym;
		    yyval.sym = yyvsp[-3].sym;
		;
    break;}
case 202:
#line 3262 "parse.y"
{ yyval.ident = NullID; ;
    break;}
case 203:
#line 3265 "parse.y"
{
		    yyval.sym = Sym_Enter(yyvsp[-3].ident, SYM_BITFIELD, 0, yyvsp[-1].number,
				   CopyExprCheckingIfZero(&expr1),
				   (TypePtr)NULL);
		;
    break;}
case 204:
#line 3271 "parse.y"
{
		    yyval.sym = Sym_Enter(yyvsp[-4].ident, SYM_BITFIELD, 0, yyvsp[-1].number,
				   CopyExprCheckingIfZero(&expr1), yyvsp[-3].type);
		;
    break;}
case 205:
#line 3277 "parse.y"
{
		    /* Value left in expr1 */
		;
    break;}
case 206:
#line 3281 "parse.y"
{
		    /*
		     * Fields with no value default to 0
		     */
		    ResetExpr(&expr1, defElts1);
		    StoreExprConst(0);
		;
    break;}
case 209:
#line 3297 "parse.y"
{
		    yyval.number = 0;
		;
    break;}
case 210:
#line 3301 "parse.y"
{
		    yyval.number = yyvsp[-1].number | SYM_ETYPE_PROTOMINOR;
		    if (curProtoMinor != NullSymbol) {
			yywarning("protominor %i still active. Are you sure you want that?",
				  curProtoMinor->name);
		    }
		;
    break;}
case 211:
#line 3310 "parse.y"
{
		    yyval.etype.size = 2;
		    yyval.etype.start = 0;
		    yyval.etype.skip = 1;
		    yyval.etype.flags = yyvsp[0].number;
		;
    break;}
case 212:
#line 3317 "parse.y"
{
		    yyval.etype.size = yyvsp[0].number;
		    yyval.etype.start = 0;
		    yyval.etype.skip = 1;
		    yyval.etype.flags = yyvsp[-1].number;
		;
    break;}
case 213:
#line 3324 "parse.y"
{
		    yyval.etype.size = yyvsp[-2].number;
		    yyval.etype.start = yyvsp[0].number;
		    yyval.etype.skip = 1;
		    yyval.etype.flags = yyvsp[-3].number;
		;
    break;}
case 214:
#line 3331 "parse.y"
{
		    yyval.etype.size = yyvsp[-4].number;
		    yyval.etype.start = yyvsp[-2].number;
		    yyval.etype.skip = yyvsp[0].number;
		    if (yyvsp[0].number == 0) {
			yywarning("are you sure you want a skip value of 0?");
		    }
		    yyval.etype.flags = yyvsp[-5].number;
		;
    break;}
case 215:
#line 3342 "parse.y"
{
		    Sym_Enter(yyvsp[-2].ident, SYM_ETYPE, yyvsp[0].etype.start, yyvsp[0].etype.skip, yyvsp[0].etype.size,
			      yyvsp[0].etype.flags);
		;
    break;}
case 216:
#line 3347 "parse.y"
{
		    SymbolPtr e;

		    e = Sym_Enter(yyvsp[-2].ident, SYM_ENUM, yyvsp[0].sym, yyvsp[0].sym->u.eType.nextVal);
		    if (yyvsp[0].sym->u.eType.flags & SYM_ETYPE_PROTOMINOR) {
			e->u.econst.protoMinor = curProtoMinor;
		    }
		;
    break;}
case 217:
#line 3356 "parse.y"
{
		    SymbolPtr e;

		    e = Sym_Enter(yyvsp[-4].ident, SYM_ENUM, yyvsp[-2].sym, yyvsp[0].number);
		    if (yyvsp[-2].sym->u.eType.flags & SYM_ETYPE_PROTOMINOR) {
			e->u.econst.protoMinor = curProtoMinor;
		    }
		;
    break;}
case 218:
#line 3365 "parse.y"
{
		    if (yyvsp[-2].sym->type != SYM_ENUM) {
			yyerror("%i: type mismatch: wasn't an enum before",
				yyvsp[-2].sym->name);
			yynerrs++;
		    } else {
			/*
			 * Let Sym_Enter worry about linkage etc.
			 */
			SymbolPtr e;

			e = Sym_Enter(yyvsp[-2].sym->name,SYM_ENUM, yyvsp[0].sym,
				      yyvsp[0].sym->u.eType.nextVal);
			if (yyvsp[0].sym->u.eType.flags & SYM_ETYPE_PROTOMINOR) {
			    e->u.econst.protoMinor = curProtoMinor;
			}
		    }
		;
    break;}
case 219:
#line 3384 "parse.y"
{
		    if (yyvsp[-4].sym->type != SYM_ENUM) {
			yyerror("%i: type mismatch: wasn't an enum before",
				yyvsp[-4].sym->name);
			yynerrs++;
		    } else {
			/*
			 * Let Sym_Enter worry about linkage etc.
			 */
			SymbolPtr e;

			e = Sym_Enter(yyvsp[-4].sym->name,SYM_ENUM, yyvsp[-2].sym, yyvsp[0].number);
			if (yyvsp[-2].sym->u.eType.flags & SYM_ETYPE_PROTOMINOR) {
			    e->u.econst.protoMinor = curProtoMinor;
			}
		    }
		;
    break;}
case 220:
#line 3413 "parse.y"
{
		    yyval.type = Type_Array(yyvsp[-4].number, yyvsp[-1].type);
		;
    break;}
case 222:
#line 3424 "parse.y"
{
		    yyval.number = yyvsp[0].number;
		;
    break;}
case 223:
#line 3428 "parse.y"
{
		    ExprResult	result;

		    yyval.number = 0;
		    if (!Expr_Eval(yyvsp[0].sym->u.equate.value, &result,
				   EXPR_NOUNDEF|EXPR_FINALIZE, NULL))
		    {
			yyerror((char *)result.type);
			yynerrs++;
		    } else if (result.type == EXPR_TYPE_CONST &&
			       !result.rel.sym)
		    {
			yyval.number = result.data.number;
		    } else {
			yyerror("equate %i is not constant", yyvsp[0].sym->name);
			yynerrs++;
		    }
		;
    break;}
case 224:
#line 3447 "parse.y"
{
		    if (yyvsp[0].sym->type != SYM_BITFIELD) {
			yyerror("invalid operand of WIDTH (%i)", yyvsp[0].sym->name);
		    } else {
			yyval.number = yyvsp[0].sym->u.bitField.width;
			yynerrs++;
		    }
		;
    break;}
case 225:
#line 3456 "parse.y"
{
		    /*
		     * Width of a record is just the position of the last
		     * bit in the mask, which we can find by nuking all the
		     * preceding bits and calling ffs to find the remaining
		     * one.
		     */
		    word    m = yyvsp[0].sym->u.record.mask;

		    yyval.number = ffs(m ^ (m >> 1));
		;
    break;}
case 226:
#line 3468 "parse.y"
{
		    if (yychar == IDENT) {
			yyerror("%i not defined yet and cannot be forward-referenced here",
			    yyvsp[0].ident);
		    } else {
			yyerror("invalid operand of WIDTH");
		    }
		;
    break;}
case 227:
#line 3476 "parse.y"
{ yyval.number = yyvsp[-2].number + yyvsp[0].number; ;
    break;}
case 228:
#line 3477 "parse.y"
{ yyval.number = yyvsp[-2].number - yyvsp[0].number; ;
    break;}
case 229:
#line 3478 "parse.y"
{ yyval.number = yyvsp[-2].number * yyvsp[0].number; ;
    break;}
case 230:
#line 3480 "parse.y"
{
		    if (yyvsp[0].number == 0) {
			yyerror("divide by 0");
			yynerrs++;
			yyval.number = 0;
		    } else {
			yyval.number = yyvsp[-2].number / yyvsp[0].number;
		    }
		;
    break;}
case 231:
#line 3490 "parse.y"
{
		    if (yyvsp[0].number == 0) {
			yyerror("mod by 0");
			yynerrs++;
			yyval.number = 0;
		    } else {
			yyval.number = yyvsp[-2].number % yyvsp[0].number;
		    }
		;
    break;}
case 232:
#line 3500 "parse.y"
{
		    yyval.number = yyvsp[-2].number << yyvsp[0].number;
		;
    break;}
case 233:
#line 3504 "parse.y"
{
		    yyval.number = yyvsp[-2].number >> yyvsp[0].number;
		;
    break;}
case 234:
#line 3508 "parse.y"
{
		    yyval.number = yyvsp[-1].number;
		;
    break;}
case 235:
#line 3513 "parse.y"
{ yyval.type = Type_Struct(yyvsp[0].sym); ;
    break;}
case 236:
#line 3514 "parse.y"
{ yyval.type = Type_Struct(yyvsp[0].sym); ;
    break;}
case 237:
#line 3515 "parse.y"
{ yyval.type = Type_Struct(yyvsp[0].sym); ;
    break;}
case 238:
#line 3516 "parse.y"
{ yyval.type = Type_Struct(yyvsp[0].sym); ;
    break;}
case 240:
#line 3519 "parse.y"
{
		     if (yyvsp[0].number == 0) {
		        yyval.type = Type_Char(1);
		    } else if (yyvsp[0].number == 'z') {
		        yyval.type = Type_Char(2);
		    } else {
			yyval.type = Type_Int(yyvsp[0].number);
		    }
		;
    break;}
case 241:
#line 3528 "parse.y"
{ yyval.type = Type_Far(); ;
    break;}
case 242:
#line 3529 "parse.y"
{ yyval.type = Type_Near(); ;
    break;}
case 243:
#line 3530 "parse.y"
{ yyval.type = Type_Ptr(yyvsp[0].number, Type_Void()); ;
    break;}
case 244:
#line 3532 "parse.y"
{ yyval.type = Type_Ptr(yyvsp[-2].number, yyvsp[0].type); ;
    break;}
case 245:
#line 3534 "parse.y"
{
		    /*
		     * Assume it's a structure of some sort. Create a 0-sized
		     * SYM_STRUCT symbol for it -- Swat will know it's
		     * external if it has no fields...
		     */
		    SymbolPtr	ssym = Sym_Enter(yyvsp[0].ident, SYM_STRUCT);

		    ssym->flags |= SYM_NOWRITE;

		    yyval.type = Type_Ptr(yyvsp[-2].number,Type_Struct(ssym));
		;
    break;}
case 247:
#line 3554 "parse.y"
{ ResetExpr(&expr1, defElts1); ;
    break;}
case 248:
#line 3555 "parse.y"
{ ResetExpr(&expr2, defElts2); ;
    break;}
case 249:
#line 3557 "parse.y"
{
		    /*
		     * Save previous expression state and reset the temporary
		     * expression for our own use.
		     */
		    yyval.exprSave.curExpr = curExpr;
		    yyval.exprSave.curExprSize = curExprSize;

		    ResetExpr(&texpr, defTElts);
		;
    break;}
case 254:
#line 3573 "parse.y"
{
		    ExprResult	result;

		    yyval.number = 0;

		    /*
		     * Evaluate the expression we just parsed, disallowing
		     * any undefined symbols. XXX: What about scope
		     * checks for methods and instance variables? Still
		     * enabled at the moment...
		     */
		    if (!Expr_Eval(&texpr, &result, EXPR_NOUNDEF|EXPR_FINALIZE,
				   NULL))
		    {
			/*
			 * Give error message we got back
			 */
			yyerror((char *)result.type);
			yynerrs++;
			yyval.number = 0;
		    } else if (result.type == EXPR_TYPE_CONST &&
			       !result.rel.sym)
		    {
			/*
			 * Use the value we got back
			 */
			yyval.number = result.data.number;
		    } else if (result.type == EXPR_TYPE_STRING) {
			/*
			 * Make sure the string constant is small enough. By
			 * definition, only single or double-character
			 * strings will fit in a single word...
			 */
			if (strlen(result.data.str) > 2) {
			    yyerror("string \"%s\" too long -- 2 characters max",
				    result.data.str);
			    yynerrs++;
			    yyval.number = 0;
			} else {
			    yyval.number = result.data.str[0]|(result.data.str[1] << 8);
			}
		    } else {
			/*
			 * Expression valid but not constant -- choke.
			 */
			yyerror("constant expected");
			yynerrs++;
			yyval.number = 0;
		    }

		    /*
		     * Free any extra elements and go back to the
		     * interrupted expression.
		     */
		    RestoreExpr(&yyvsp[-1].exprSave);
		;
    break;}
case 255:
#line 3637 "parse.y"
{
		    if (indir) {
			StoreExprReg(EXPR_EINDREG, yyvsp[0].number);
		    } else {
			StoreExprReg(EXPR_DWORDREG, yyvsp[0].number);
		    }
		;
    break;}
case 256:
#line 3645 "parse.y"
{
		    if (indir) {
			if (yyvsp[0].number != REG_BP && yyvsp[0].number != REG_SI && yyvsp[0].number != REG_DI &&
			    yyvsp[0].number != REG_BX)
			{
			    yyerror("illegal register for indirection");
			    yynerrs++;
			    /*  Fake a valid register to prevent Expr_Eval
				from dying. */
			    StoreExprReg(EXPR_INDREG, REG_SI);
			} else {
			    StoreExprReg(EXPR_INDREG, yyvsp[0].number);
			}
		    } else {
			StoreExprReg(EXPR_WORDREG, yyvsp[0].number);
		    }
		;
    break;}
case 257:
#line 3663 "parse.y"
{
		    if (indir) {
			yyerror("cannot indirect through a byte-sized register");
			yynerrs++;
			/*  Fake a valid register to prevent Expr_Eval
			    from dying. */
			StoreExprReg(EXPR_INDREG, REG_SI);
		    } else {
			StoreExprReg(EXPR_BYTEREG, yyvsp[0].number);
		    }
		;
    break;}
case 258:
#line 3674 "parse.y"
{ StoreExprReg(EXPR_SEGREG, yyvsp[0].number); ;
    break;}
case 259:
#line 3676 "parse.y"
{
		    /*
		     * Undefined things count as 0, since we don't do any sort
		     * of compression or object record stuff to isolate
		     * undefined regions...This probably shouldn't be
		     * allowed in a general expression, but it makes it easier
		     * in "def" if we do this here.
		     */
		    StoreExprConst(0);
		;
    break;}
case 260:
#line 3686 "parse.y"
{ StoreExprOp(EXPR_OVERRIDE); ;
    break;}
case 261:
#line 3688 "parse.y"
{
		    StoreExprOp(EXPR_CAST);
		;
    break;}
case 262:
#line 3691 "parse.y"
{ StoreExprType(yyvsp[-1].type); ;
    break;}
case 263:
#line 3692 "parse.y"
{
		    StoreExprOp(EXPR_CAST);
		;
    break;}
case 264:
#line 3695 "parse.y"
{ StoreExprType(yyvsp[0].type); ;
    break;}
case 265:
#line 3696 "parse.y"
{ StoreExprOp(EXPR_SHORT); ;
    break;}
case 266:
#line 3698 "parse.y"
{
		    if (yyvsp[-1].sym->u.record.first == NULL) {
			yyerror("cannot initialize record %i -- it has no fields",
				yyvsp[-1].sym->name);
			free(yyvsp[0].string);
			YYERROR;
		    } else {
			Data_EncodeRecord(yyvsp[-1].sym, yyvsp[0].string);
		    }
		;
    break;}
case 267:
#line 3709 "parse.y"
{
		    free(yyvsp[-4].string);
		;
    break;}
case 269:
#line 3713 "parse.y"
{ StoreExprOp(EXPR_PLUS); ;
    break;}
case 270:
#line 3714 "parse.y"
{ StoreExprOp(EXPR_PLUS); ;
    break;}
case 272:
#line 3717 "parse.y"
{
		    StoreExprString(EXPR_STRING, yyvsp[0].string);
		    free(yyvsp[0].string);
		;
    break;}
case 273:
#line 3722 "parse.y"
{
		    StoreExprString(EXPR_INIT, yyvsp[0].string);
		    free(yyvsp[0].string);
		;
    break;}
case 274:
#line 3726 "parse.y"
{ StoreExprSymbol(yyvsp[0].sym); ;
    break;}
case 275:
#line 3727 "parse.y"
{ StoreSubExpr(yyvsp[0].expr); ;
    break;}
case 276:
#line 3728 "parse.y"
{ StoreSubExpr(yyvsp[0].sym->u.equate.value); ;
    break;}
case 277:
#line 3730 "parse.y"
{
		    /*
		     * Make sure it's accessible
		     */
		    if (!(yyvsp[0].sym->u.method.flags & SYM_METH_PUBLIC) &&
			warn_private &&
			!CheckRelated(curClass, yyvsp[0].sym->u.method.class))
		    {
			yywarning("private method %i used outside class %i",
				  yyvsp[0].sym->name, yyvsp[0].sym->u.method.class->name);
		    }
		    StoreExprSymbol(yyvsp[0].sym);
		;
    break;}
case 278:
#line 3744 "parse.y"
{
		    /*
		     * Make sure it's accessible
		     */
		    if (! (yyvsp[0].sym->u.instvar.flags & SYM_VAR_PUBLIC) &&
			warn_private &&
			!CheckRelated(curClass, yyvsp[0].sym->u.instvar.class))
		    {
			yywarning("private instance variable %i used outside class %i",
				  yyvsp[0].sym->name, yyvsp[0].sym->u.instvar.class->name);
		    }
		    StoreExprSymbol(yyvsp[0].sym);
		;
    break;}
case 279:
#line 3757 "parse.y"
{ StoreExprSymbol(yyvsp[0].sym); ;
    break;}
case 280:
#line 3758 "parse.y"
{ StoreExprIdent(yyvsp[0].ident); ;
    break;}
case 281:
#line 3759 "parse.y"
{ StoreExprSymbol(yyvsp[0].sym); ;
    break;}
case 282:
#line 3761 "parse.y"
{
		    /*
		     * Handle the use of this specially when defining a
		     * structure, where it refers to the current structOffset
		     */
		    if (inStruct) {
			StoreExprConst(inStruct->u.typesym.size);
		    } else {
			/*
			 * We use a nameless local label for all occurrences of
			 * DOT. There's no need to refer to the thing again,
			 * but it does need to be in the segment's address
			 * chain so it can be shifted as necessary.
			 */
			StoreExprSymbol(Sym_Enter(NullID, SYM_LABEL,dot,TRUE));
		    }
		;
    break;}
case 283:
#line 3779 "parse.y"
{
		    if (yyvsp[0].type == Type_Near() || yyvsp[0].type == Type_Far()) {
			StoreExprSymbol(Sym_Enter(NullID, SYM_LABEL, dot,
						  yyvsp[0].type->tn_type==TYPE_NEAR));
		    } else {
			StoreExprSymbol(Sym_Enter(NullID, SYM_VAR, dot, yyvsp[0].type));
		    }
		;
    break;}
case 284:
#line 3787 "parse.y"
{ StoreExprConst(yyvsp[0].number); ;
    break;}
case 285:
#line 3789 "parse.y"
{
		    /*
		     * Local label -- find the thing, if possible, else
		     * store IDENT
		     */
		    ID	    	id;
		    char    	buf[20];
		    SymbolPtr	sym;

		    sprintf(buf, "%d$", yyvsp[-1].number);
		    id = ST_EnterNoLen(output, symStrings, buf);
		    sym = Sym_Find(id, SYM_LOCALLABEL, FALSE);
		    if (sym != NULL) {
			StoreExprSymbol(sym);
		    } else {
			StoreExprIdent(id);
		    }
		;
    break;}
case 286:
#line 3807 "parse.y"
{ StoreExprOp(EXPR_SEGPART); ;
    break;}
case 287:
#line 3808 "parse.y"
{ StoreExprOp(EXPR_OFFPART); ;
    break;}
case 288:
#line 3809 "parse.y"
{ StoreExprOp(EXPR_HIGHPART); ;
    break;}
case 289:
#line 3810 "parse.y"
{ StoreExprOp(EXPR_LOWPART); ;
    break;}
case 290:
#line 3811 "parse.y"
{ StoreExprOp(EXPR_SUPER); ;
    break;}
case 291:
#line 3812 "parse.y"
{ StoreExprOp(EXPR_PLUS); ;
    break;}
case 292:
#line 3813 "parse.y"
{ StoreExprOp(EXPR_DOT); ;
    break;}
case 293:
#line 3814 "parse.y"
{ StoreExprOp(EXPR_MINUS); ;
    break;}
case 294:
#line 3815 "parse.y"
{ StoreExprOp(EXPR_TIMES); ;
    break;}
case 295:
#line 3816 "parse.y"
{ StoreExprOp(EXPR_DIV); ;
    break;}
case 296:
#line 3817 "parse.y"
{ StoreExprOp(EXPR_MOD); ;
    break;}
case 297:
#line 3818 "parse.y"
{ StoreExprOp(EXPR_FMASK); ;
    break;}
case 298:
#line 3819 "parse.y"
{ StoreExprOp(EXPR_NEG); ;
    break;}
case 299:
#line 3820 "parse.y"
{ /* Do nothing */ ;
    break;}
case 300:
#line 3821 "parse.y"
{ StoreExprOp(EXPR_NOT); ;
    break;}
case 301:
#line 3822 "parse.y"
{ StoreExprOp(EXPR_SHR); ;
    break;}
case 302:
#line 3823 "parse.y"
{ StoreExprOp(EXPR_SHL); ;
    break;}
case 303:
#line 3824 "parse.y"
{ StoreExprOp(EXPR_EQ); ;
    break;}
case 304:
#line 3825 "parse.y"
{ StoreExprOp(EXPR_NEQ); ;
    break;}
case 305:
#line 3826 "parse.y"
{ StoreExprOp(EXPR_LT); ;
    break;}
case 306:
#line 3827 "parse.y"
{ StoreExprOp(EXPR_LE); ;
    break;}
case 307:
#line 3828 "parse.y"
{ StoreExprOp(EXPR_GT); ;
    break;}
case 308:
#line 3829 "parse.y"
{ StoreExprOp(EXPR_GE); ;
    break;}
case 309:
#line 3830 "parse.y"
{ StoreExprOp(EXPR_AND); ;
    break;}
case 310:
#line 3831 "parse.y"
{ StoreExprOp(EXPR_OR); ;
    break;}
case 311:
#line 3832 "parse.y"
{ StoreExprOp(EXPR_XOR); ;
    break;}
case 312:
#line 3833 "parse.y"
{ StoreExprOp(EXPR_HIGH); ;
    break;}
case 313:
#line 3834 "parse.y"
{ StoreExprOp(EXPR_LOW); ;
    break;}
case 314:
#line 3835 "parse.y"
{ StoreExprOp(EXPR_SEG); ;
    break;}
case 315:
#line 3836 "parse.y"
{ StoreExprOp(EXPR_SEG); ;
    break;}
case 316:
#line 3837 "parse.y"
{ StoreExprOp(EXPR_SEGREGOF); ;
    break;}
case 317:
#line 3838 "parse.y"
{ StoreExprOp(EXPR_VSEG); ;
    break;}
case 318:
#line 3839 "parse.y"
{ StoreExprOp(EXPR_OFFSET); ;
    break;}
case 319:
#line 3840 "parse.y"
{ StoreExprOp(EXPR_TYPEOP); ;
    break;}
case 320:
#line 3841 "parse.y"
{ StoreExprOp(EXPR_LENGTH); ;
    break;}
case 321:
#line 3842 "parse.y"
{ StoreExprOp(EXPR_SIZE); ;
    break;}
case 322:
#line 3843 "parse.y"
{ StoreExprOp(EXPR_WIDTH); ;
    break;}
case 323:
#line 3844 "parse.y"
{ StoreExprOp(EXPR_MASK); ;
    break;}
case 324:
#line 3845 "parse.y"
{ StoreExprOp(EXPR_FIRST); ;
    break;}
case 325:
#line 3846 "parse.y"
{ StoreExprOp(EXPR_DOTTYPE); ;
    break;}
case 326:
#line 3847 "parse.y"
{ StoreExprOp(EXPR_HANDLE); ;
    break;}
case 327:
#line 3848 "parse.y"
{ StoreExprOp(EXPR_RESID); ;
    break;}
case 328:
#line 3849 "parse.y"
{ StoreExprOp(EXPR_ENUM); ;
    break;}
case 329:
#line 3851 "parse.y"
{StoreExprFloatStack(0L);;
    break;}
case 330:
#line 3852 "parse.y"
{StoreExprFloatStack(yyvsp[-1].number);;
    break;}
case 332:
#line 3855 "parse.y"
{indir=0; StoreExprOp(EXPR_INDIRECT); ;
    break;}
case 333:
#line 3856 "parse.y"
{indir = 0; ;
    break;}
case 334:
#line 3858 "parse.y"
{indir = 1; ;
    break;}
case 335:
#line 3870 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-1].number);
		;
    break;}
case 336:
#line 3874 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-1].number);
		;
    break;}
case 337:
#line 3878 "parse.y"
{
		    int	    i;

		    for (i = NumElts(exprs)-1; i >= 0; i--) {
			bzero(exprs[i]->segments, sizeof(exprs[i]->segments));
		    }

		    Scan_DontUseOpProc(yyvsp[-1].number);
		;
    break;}
case 338:
#line 3889 "parse.y"
{
		    yyval.number = Scan_UseOpProc(findSegToken);
		;
    break;}
case 342:
#line 3895 "parse.y"
{ yyval.sym = NullSymbol; ;
    break;}
case 343:
#line 3897 "parse.y"
{
		    if (makeDepend) {
			/*
			 * If creating dependencies, ignore undefined
			 * segments, as they might be defined in a .rdef
			 * file...which will go away eventually, but until
			 * it does, it's really annoying.
			 */
			yyval.sym = NullSymbol;
		    } else {
			yyerror("%i is neither a segment nor a group", yyvsp[0].ident);
			YYERROR;
		    }
		;
    break;}
case 344:
#line 3912 "parse.y"
{
		    ExprResult	result;

		    StoreExprOp(EXPR_SEG);
		    if (!Expr_Eval(&expr1, &result, EXPR_NOUNDEF|EXPR_FINALIZE,
				   NULL))
		    {
			/*
			 * Give error message we got back.
			 */
			yyerror((char *)result.type);
			yynerrs++;
		    } else {
			/*
			 * Result must be a segment constant b/c the last
			 * thing we stuck in was an EXPR_SEG operator.
			 */
			assert(result.type == EXPR_TYPE_CONST &&
			       result.rel.type == FIX_SEGMENT);
			yyval.sym = result.rel.frame;
		    }
		;
    break;}
case 345:
#line 3936 "parse.y"
{
		    /*
		     * Bind the segment symbol to the register in all the
		     * temporary expressions. SEGREG gives us a number from
		     * 0 to 5...
		     */
		    int	    i;

		    for (i = NumElts(exprs)-1; i >= 0; i--) {
			exprs[i]->segments[yyvsp[-2].number] = yyvsp[0].sym;
		    }
		;
    break;}
case 348:
#line 3953 "parse.y"
{
		    yyval.number = Scan_UseOpProc(findSegToken);
		;
    break;}
case 351:
#line 3959 "parse.y"
{
		    /*
		     * Declaration of a segment as an LMem group whose
		     * data are (possibly) defined in a different object
		     * file. We need to have LMem create the segments
		     * but not fill them in.
		     */
		    Scan_DontUseOpProc(yyvsp[-2].number);

		    if (ParseIsLibName(yyvsp[-3].ident)) {
			yyerror("cannot create a non-library segment whose name matches the permanent name of this library");
			yyval.sym = NullSymbol;
		    } else {
			yyval.sym = LMem_CreateSegment(yyvsp[-3].ident);
		    }
		;
    break;}
case 352:
#line 3976 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-2].number);

		    if ((yyvsp[-3].sym->type != SYM_GROUP) ||
			(yyvsp[-3].sym->u.group.nSegs != 2) ||
			(yyvsp[-3].sym->u.group.segs[0]->u.segment.data->comb!=SEG_LMEM)||
			(yyvsp[-3].sym->u.group.segs[1]->u.segment.data->comb!=SEG_LMEM))
		    {
			yyerror("cannot redefine segment %i as an lmem segment",
				yyvsp[-3].sym->name);
			yynerrs++;
			yyval.sym = NullSymbol;
		    } else {
			yyval.sym = yyvsp[-3].sym;
		    }
		;
    break;}
case 353:
#line 3994 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-1].number);

		    if (!ParseIsLibName(yyvsp[-2].ident)) {
			PushSegment(Sym_Enter(yyvsp[-2].ident, SYM_SEGMENT, yyvsp[0].seg.comb,
					      yyvsp[0].seg.align, yyvsp[0].seg.class));
		    } else if (yyvsp[0].seg.comb != SEG_LIBRARY) {
			yyerror("cannot create a non-library segment whose name matches the permanent name of this library");
		    } else {
			/*
			 * When defining symbols for this library, always
			 * enter the global scope, thereby exiting any library
			 * segment scopes we might be in currently.
			 */
			PushSegment(global);
		    }
		;
    break;}
case 354:
#line 4012 "parse.y"
{
		    /*
		     * Create an LMem segment. $2 is the segment type.
		     * $4 is the flags for the segment. $6 is the extra
		     * free space requested.
		     */
		    if (yyvsp[-5].sym != NullSymbol) {
			LMem_InitSegment(yyvsp[-5].sym, yyvsp[-4].number, yyvsp[-2].number, yyvsp[0].number);
		    }
		;
    break;}
case 355:
#line 4023 "parse.y"
{
		    /*
		     * Create an LMem segment. $2 is the segment type.
		     * $4 is the flags for the segment.
		     */
		    if (yyvsp[-3].sym != NullSymbol) {
			LMem_InitSegment(yyvsp[-3].sym, yyvsp[-2].number, yyvsp[0].number, 0);
		    }
		;
    break;}
case 356:
#line 4033 "parse.y"
{
		    /*
		     * Like above, except defaults flags to 0, since
		     * for now, none of them should be set anyway :)
		     */

		    if (yyvsp[-1].sym != NullSymbol) {
			LMem_InitSegment(yyvsp[-1].sym, yyvsp[0].number, 0, 0);
		    }
		;
    break;}
case 357:
#line 4044 "parse.y"
{
		    /*
		     * Push to the data portion of the group to allow the
		     * user to continue entering data or to add chunks or
		     * whatever.
		     */
		    if (yyvsp[0].sym != NullSymbol) {
			PushSegment(yyvsp[0].sym->u.group.segs[0]);
		    }
		;
    break;}
case 358:
#line 4055 "parse.y"
{
		    if ((yyvsp[-3].sym->type != SYM_SEGMENT) ||
			(yyvsp[-3].sym->u.segment.data->comb != SEG_ABSOLUTE))
		    {
			yyerror("cannot redefine %i as an absolute segment",
				yyvsp[-3].sym->name);
			yynerrs++;
		    }
		    Scan_DontUseOpProc(yyvsp[-2].number);
		    PushSegment(yyvsp[-3].sym); /* XXX */
		;
    break;}
case 359:
#line 4067 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-2].number);
		    if (ParseIsLibName(yyvsp[-3].ident)) {
			yyerror("cannot create a non-library segment whose name matches the permanent name of this library");
		    } else {
			PushSegment(Sym_Enter(yyvsp[-3].ident, SYM_SEGMENT, SEG_ABSOLUTE,
					      yyvsp[0].number));
		    }
		;
    break;}
case 360:
#line 4077 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-1].number);

		    if (yyvsp[-2].sym->type == SYM_GROUP) {
			/*
			 * User only allowed to do this for LMem segments,
			 * which are groups masquerading as segments.
			 * An LMem segment (group) may only have two segment
			 * elements and both must be marked as LMem segments.
			 * Anything else is a faux pas.
			 */
			if ((yyvsp[-2].sym->u.group.nSegs != 2) ||
			    (yyvsp[-2].sym->u.group.segs[0]->u.segment.data->comb!=SEG_LMEM) ||
			    (yyvsp[-2].sym->u.group.segs[1]->u.segment.data->comb!=SEG_LMEM))
			{
			    yyerror("%i is not a segment", yyvsp[-2].sym->name);
			    yynerrs++;
			} else {
			    /*
			     * Switch to the data segment of the LMem group,
			     * since not w/in a chunk.
			     */
			    PushSegment(yyvsp[-2].sym->u.group.segs[0]);
			}
		    } else if (yyvsp[-2].sym->type != SYM_SEGMENT) {
			yyerror("%i is not a segment", yyvsp[-2].sym->name);
			yynerrs++;
		    } else {
			/*
			 * Check each type of attribute for conflicts with
			 * existing ones. An attribute was given if it is
			 * non-zero in the segAttrs semantic value.
			 */
			if (yyvsp[0].seg.comb) {
			    if (yyvsp[-2].sym->u.segment.data->comb &&
				(yyvsp[-2].sym->u.segment.data->comb != yyvsp[0].seg.comb))
			    {
				yyerror("inconsistent combine types for %i",
					yyvsp[-2].sym->name);
				yynerrs++;
			    } else if (yyvsp[0].seg.comb == SEG_LMEM) {
				yyerror("lmem segments must be denoted as such when first declared");
				yynerrs++;
			    } else {
				yyvsp[-2].sym->u.segment.data->comb = yyvsp[0].seg.comb;
			    }
			}
			if (yyvsp[0].seg.align) {
			    if (yyvsp[-2].sym->u.segment.data->align &&
				(yyvsp[-2].sym->u.segment.data->align != yyvsp[0].seg.align))
			    {
				yyerror("inconsistent alignments for %i",
					yyvsp[-2].sym->name);
				yynerrs++;
			    } else {
				yyvsp[-2].sym->u.segment.data->align = yyvsp[0].seg.align;
			    }
			}
			if (yyvsp[0].seg.class) {
			    if (yyvsp[-2].sym->u.segment.data->class &&
				yyvsp[-2].sym->u.segment.data->class != yyvsp[0].seg.class)
			    {
				yyerror("inconsistent classes for %i",
					yyvsp[-2].sym->name);
				yynerrs++;
			    } else {
				yyvsp[-2].sym->u.segment.data->class = yyvsp[0].seg.class;
			    }
			}
			/*
			 * Enter into the segment.
			 */
			PushSegment(yyvsp[-2].sym);
		    }
		;
    break;}
case 361:
#line 4157 "parse.y"
{
		    /*
		     * Initialize our return value; this always gets reduced
		     * first.
		     */
		    yyval.seg.align = yyval.seg.comb = 0; yyval.seg.class = NullID;
		    yyval.seg.flags = 0;
		;
    break;}
case 362:
#line 4166 "parse.y"
{
		    yyval.seg = yyvsp[-1].seg;
		    if (yyvsp[-1].seg.flags & yyvsp[0].seg.flags) {
			yyerror("duplicate definition of segment %s attribute",
				yyvsp[0].seg.flags == SA_COMBINE ? "combine type" :
				(yyvsp[0].seg.flags == SA_ALIGNMENT ? "alignment" :
				 "class"));
		    } else {
			/*
			 * Copy appropriate value from $2 into final value.
			 */
			switch (yyvsp[0].seg.flags) {
			case SA_COMBINE:
			    yyval.seg.comb = yyvsp[0].seg.comb;
			    break;
			case SA_ALIGNMENT:
			    yyval.seg.align = yyvsp[0].seg.align;
			    break;
			case SA_CLASS:
			    yyval.seg.class = yyvsp[0].seg.class;
			    break;
			}
			yyval.seg.flags |= yyvsp[0].seg.flags;
		    }
		;
    break;}
case 363:
#line 4193 "parse.y"
{
		    yyval.seg.align = yyvsp[0].number; yyval.seg.flags = SA_ALIGNMENT;
		;
    break;}
case 364:
#line 4197 "parse.y"
{
		    yyval.seg.comb = yyvsp[0].number; yyval.seg.flags = SA_COMBINE;
		;
    break;}
case 365:
#line 4201 "parse.y"
{
		    yyval.seg.class = ST_EnterNoLen(output, permStrings, yyvsp[0].string);
		    yyval.seg.flags = SA_CLASS;
		    free(yyvsp[0].string);
		;
    break;}
case 366:
#line 4209 "parse.y"
{
		    if (yyvsp[-1].sym->type == SYM_GROUP) {
			/*
			 * User only allowed to do this for LMem segments,
			 * which are groups masquerading as segments.
			 * An LMem segment (group) may only have two segment
			 * elements and both must be marked as LMem segments.
			 * Anything else is a faux pas.
			 */
			if ((yyvsp[-1].sym->u.group.nSegs != 2) ||
			    (yyvsp[-1].sym->u.group.segs[0]->u.segment.data->comb!=SEG_LMEM) ||
			    (yyvsp[-1].sym->u.group.segs[1]->u.segment.data->comb!=SEG_LMEM))
			{
			    yyerror("%i is not a segment", yyvsp[-1].sym->name);
			    yynerrs++;
			} else if ((curSeg != yyvsp[-1].sym->u.group.segs[0]) &&
				   (curSeg != yyvsp[-1].sym->u.group.segs[1]))
			{
			    yyerror("%i is not current segment (%i is)",
				    yyvsp[-1].sym->name, curSeg->name);
			    yynerrs++;
			} else {
			    PopSegment();
			}
		    } else if (yyvsp[-1].sym->type != SYM_SEGMENT) {
			yyerror("%i is not a segment", yyvsp[-1].sym->name);
			yynerrs++;
		    } else if (yyvsp[-1].sym != curSeg) {
			yyerror("%i is not the current segment (%i is)",
				yyvsp[-1].sym->name, curSeg->name);
			yynerrs++;
		    } else {
			PopSegment();
		    }
		;
    break;}
case 367:
#line 4245 "parse.y"
{
		    if (!ParseIsLibName(yyvsp[-1].ident)) {
			yyerror("cannot end segment/structure %i as it doesn't exist", yyvsp[-1].ident);
			yynerrs++;
		    } else if (curSeg != global || segStack == NULL) {
			yyerror("%i is not the current segment (%i is)",
				yyvsp[-1].ident, curSeg->name);
			yynerrs++;
		    } else {
			/*
			 * Get out of the global scope we entered when we
			 * were asked to enter the <this_library_name> segment
			 */
			PopSegment();
		    }
		;
    break;}
case 368:
#line 4261 "parse.y"
{ yyval.sym=Sym_Enter(yyvsp[-1].ident,SYM_GROUP,0); ;
    break;}
case 370:
#line 4263 "parse.y"
{
		    if (yyvsp[-1].sym->type != SYM_GROUP) {
			yyerror("%i is not a group", yyvsp[-1].sym->name);
			yynerrs++;
		    }
		    yyval.sym = yyvsp[-1].sym; /* Pass to groupList even if bogus */
		;
    break;}
case 372:
#line 4281 "parse.y"
{
		    yyval.sym = Sym_Enter(yyvsp[0].ident, SYM_SEGMENT,0,0,0);
		;
    break;}
case 373:
#line 4285 "parse.y"
{
		    if (yyvsp[0].sym->type != SYM_SEGMENT) {
			yyerror("%i is not a segment", yyvsp[0].sym->name);
			yynerrs++;
		    }
		    yyval.sym = yyvsp[0].sym;
		;
    break;}
case 374:
#line 4293 "parse.y"
{
		    yyval.sym = yyvsp[0].sym->segment;
		;
    break;}
case 375:
#line 4298 "parse.y"
{
		    /*
		     * Propagate the group symbol to the $1 position for later
		     * incarnations of this rule
		     */
		    yyval.sym = yyvsp[-1].sym;
		    if (yyval.sym->type == SYM_GROUP) {
			Sym_AddToGroup(yyval.sym, yyvsp[0].sym);
		    }
		;
    break;}
case 376:
#line 4309 "parse.y"
{
		    yyval.sym = yyvsp[-2].sym;	/* Propagate */
		    if (yyval.sym->type == SYM_GROUP) {
			Sym_AddToGroup(yyval.sym, yyvsp[0].sym);
		    }
		;
    break;}
case 377:
#line 4329 "parse.y"
{
		    yyval.number = Scan_UseOpProc(findClassToken);
		;
    break;}
case 378:
#line 4333 "parse.y"
{ yyval.number = OBJ_STATIC; ;
    break;}
case 379:
#line 4334 "parse.y"
{ yyval.number = OBJ_PRIVSTATIC; ;
    break;}
case 380:
#line 4335 "parse.y"
{ yyval.number = OBJ_PRIVSTATIC; ;
    break;}
case 381:
#line 4336 "parse.y"
{ yyval.number = OBJ_DYNAMIC; ;
    break;}
case 382:
#line 4337 "parse.y"
{ yyval.number = OBJ_DYNAMIC_CALLABLE; ;
    break;}
case 383:
#line 4341 "parse.y"
{
		    yyval.number = yyvsp[-1].number;
		    methFlags = yyvsp[0].number;
		;
    break;}
case 384:
#line 4345 "parse.y"
{ ignore = FALSE; ;
    break;}
case 385:
#line 4346 "parse.y"
{
		    yyval.number = yyvsp[-3].number;
		    methFlags = OBJ_EXTERN | yyvsp[0].number;
		;
    break;}
case 386:
#line 4355 "parse.y"
{
		    EnterProc(Sym_Enter(yyvsp[-2].ident, SYM_PROC, dot, 0));
		    /*
		     * If marked external, it needs to be made global so it
		     * will link successfully with the module that has the
		     * class record.
		     */
		    if (methFlags & OBJ_EXTERN) {
			curProc->flags |= SYM_GLOBAL;
		    }
		    EnterClass(yyvsp[0].sym);
		    /*
		     * Create expression for use by Obj_EnterHandler.
		     */
		    ResetExpr(&expr1, defElts1);
		    StoreExprSymbol(curProc);
		;
    break;}
case 387:
#line 4373 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-5].number);
		;
    break;}
case 388:
#line 4377 "parse.y"
{
		    /*
		     * Generate special messages if given an identifier (class
		     * not defined) or something symbol other than a class
		     * (symbol not a class). Anything else we leave as a generic
		     * parse error.
		     */
		    if (yychar == IDENT) {
			yyerror("class %i not defined", yyvsp[0].ident);
			yynerrs++;
		    } else if (yychar > FIRSTSYM && yychar < LASTSYM) {
			yyerror("%i not a class", yyvsp[0].sym->name);
			yynerrs++;
		    }
		    Scan_DontUseOpProc(yyvsp[-1].number);
		;
    break;}
case 389:
#line 4394 "parse.y"
{
		    CheckAndSetLabel(SYM_PROC, yyvsp[-2].sym, 0);
		    /*
		     * Prepare for creating expression for use by
		     * Obj_EnterHandler.
		     */
		    ResetExpr(&expr1, defElts1);
		    if (yyvsp[-2].sym->type != SYM_PROC) {
			yyerror("%i cannnot be a method handler as it's not a procedure",
				yyvsp[-2].sym->name);
			yynerrs++;
			/*
			 * Tell methodList not to do anything.
			 */
			curExpr = NULL;
		    } else {
			EnterProc(yyvsp[-2].sym);
			EnterClass(yyvsp[0].sym);
			/*
			 * Store the name of the procedure for use by
			 * Obj_EnterHandler
			 */
			StoreExprSymbol(curProc);
			/*
			 * If marked external, it needs to be made global so it
			 * will link successfully with the module that has the
			 * class record.
			 */
			if (methFlags & OBJ_EXTERN) {
			    curProc->flags |= SYM_GLOBAL;
			}
		    }
		;
    break;}
case 390:
#line 4428 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-5].number);
		;
    break;}
case 391:
#line 4432 "parse.y"
{
		    /*
		     * Generate special messages if given an identifier (class
		     * not defined) or something symbol other than a class
		     * (symbol not a class). Anything else we leave as a generic
		     * parse error.
		     */
		    if (yychar == IDENT) {
			yyerror("class %i not defined", yyvsp[0].ident);
			yynerrs++;
		    } else if (yychar > FIRSTSYM && yychar < LASTSYM) {
			yyerror("%i not a class", yyvsp[0].sym->name);
			yynerrs++;
		    }
		    Scan_DontUseOpProc(yyvsp[-1].number);
		;
    break;}
case 392:
#line 4449 "parse.y"
{
		    /*
		     * Make the current procedure into a "friend" of the given
		     * class, to use the C++ term. This allows it to access
		     * private methods and instance variables of the class
		     * without getting a warning.
		     */
		    if (curProc == NULL) {
			yyerror("friend declaration for %i must be inside a procedure",
				yyvsp[0].sym->name);
			yynerrs++;
		    } else if (curClass && curClass != yyvsp[0].sym) {
			yyerror("%i is already bound to class `%i'",
				curProc->name, curClass->name);
			yynerrs++;
		    } else {
			EnterClass(yyvsp[0].sym);
			defClass = FALSE;
		    }
		;
    break;}
case 393:
#line 4471 "parse.y"
{
		    yyval.extMeth.curProc = curProc;
		    yyval.extMeth.curClass = curClass;
		    curClass = yyvsp[0].sym;
		    curProc = yyvsp[-2].sym;
		    /*
		     * Create expression for use by Obj_EnterHandler.
		     */
		    ResetExpr(&expr1, defElts1);
		    StoreExprSymbol(curProc);
		;
    break;}
case 394:
#line 4483 "parse.y"
{
		    curClass = yyvsp[-2].extMeth.curClass;
		    curProc = yyvsp[-2].extMeth.curProc;
		    Scan_DontUseOpProc(yyvsp[-6].number);
		;
    break;}
case 395:
#line 4489 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-1].number);
		;
    break;}
case 396:
#line 4495 "parse.y"
{
		    /*
		     * Make sure the specified method is a far procedure.
		     */
		    if (yyvsp[0].sym->type != SYM_PROC || Sym_IsNear(yyvsp[0].sym))
		    {
			yyerror("methods must be FAR procedures");
			yynerrs++;
			YYERROR;
		    } else {
			yyval.sym = yyvsp[0].sym;
		    }
		;
    break;}
case 397:
#line 4509 "parse.y"
{
		    /*
		     * Manufacture an undefined far SYM_PROC symbol for the
		     * thing...
		     */
		    yyval.sym = Sym_Enter(yyvsp[0].ident, SYM_PUBLIC, curFile->name, yylineno);
		    yyval.sym->type = SYM_PROC;
		    yyval.sym->u.proc.flags = 0;
		    yyval.sym->u.proc.locals = NULL;
		    yyval.sym->u.addrsym.offset = 0;
		    yyval.sym->flags |= SYM_UNDEF;
		    yyval.sym->segment = global;
		;
    break;}
case 400:
#line 4528 "parse.y"
{
		    if (curExpr) {
			if (!CheckRelated(curClass, yyvsp[0].sym->u.method.class)) {
			    yywarning("%i is not a valid method for %i",
				      yyvsp[0].sym->name, curClass->name);
			}

			if (curClass->flags & SYM_UNDEF) {
			    if (!(methFlags & OBJ_EXTERN)) {
				yyerror("class record for %i is not defined yet",
					curClass->name);
				yynerrs++;
			    }
			} else {
			    Obj_EnterHandler(curClass, curProc, yyvsp[0].sym, curExpr,
					     methFlags & OBJ_STATIC_MASK);
			}
		    }
		;
    break;}
case 401:
#line 4548 "parse.y"
{
		    if (curExpr) {
			if (curClass->flags & SYM_UNDEF) {
			    if (!(methFlags & OBJ_EXTERN)) {
				yyerror("class record for %i is not defined yet",
					curClass->name);
				yynerrs++;
			    }
			} else {
			    Obj_EnterDefault(curClass, curProc, curExpr,
					     methFlags & OBJ_STATIC_MASK);
			}
		    }
		;
    break;}
case 402:
#line 4563 "parse.y"
{
		    if (curExpr) {
			if (curClass->flags & SYM_UNDEF) {
			    if (!(methFlags & OBJ_EXTERN)) {
				yyerror("class record for %i is not defined yet",
					curClass->name);
				yynerrs++;
			    }
			} else {
			    Obj_EnterReloc(curClass, curProc, curExpr);
			}
		    }
		;
    break;}
case 403:
#line 4577 "parse.y"
{
		    /*
		     * Elaborate a bit if the method constant isn't defined.
		     */
		    if (yychar == IDENT) {
			yyerror("message %i not defined", yyvsp[0].ident);
			yyclearin;
		    }
		;
    break;}
case 404:
#line 4589 "parse.y"
{
		    if (curProc != yyvsp[-1].sym) {
			if (curProc == NULL) {
			    yyerror("ENDM for %i is outside of any method",
				    yyvsp[-1].sym->name);
			} else {
			    yyerror("ENDM for %i is inside %i",
				    yyvsp[-1].sym->name, curProc->name);
			}
			yynerrs++;
		    } else if (curClass == NULL) {
			yyerror("ENDM for non-method %i", yyvsp[-1].sym->name);
			yynerrs++;
		    } else {
			/*
			 * Reset procedure-specific state variables
			 */
			EndProc(curProc->name);
		    }
		;
    break;}
case 405:
#line 4610 "parse.y"
{
		    yyerror("method %i not defined, so can't be ended", yyvsp[-1].ident);
		    yynerrs++;
		;
    break;}
case 406:
#line 4619 "parse.y"
{
		    yyval.number = classProc;
		    classProc = Scan_UseOpProc(findClassToken);
		;
    break;}
case 407:
#line 4624 "parse.y"
{
		    if (curClass) {
			yyerror("nested class declarations are not allowed (in %i now)",
				curClass->name);
			yynerrs++;
			Scan_DontUseOpProc(classProc);
			classProc = yyvsp[-1].number;
		    } else if (yyvsp[0].classDecl.class != (SymbolPtr)1) {
			EnterClass(Obj_DeclareClass(yyvsp[-3].ident, yyvsp[0].classDecl.class, yyvsp[0].classDecl.flags));
			defClass = TRUE;
			isPublic = FALSE;

			/*
			 * Since we're declaring a new class, we have to
			 * reset the protominor symbol
			 */
			curProtoMinor = NullSymbol;
		    }
		;
    break;}
case 408:
#line 4644 "parse.y"
{
		    yyval.number = classProc;
		    classProc = Scan_UseOpProc(findClassToken);
		;
    break;}
case 409:
#line 4649 "parse.y"
{
		    if (((yyvsp[-3].sym->flags & SYM_UNDEF) == 0) ||
			(yyvsp[-3].sym->u.class.instance != NULL))
		    {
			yyerror("class %i is already defined", yyvsp[-3].sym->name);
			yynerrs++;
			Scan_DontUseOpProc(classProc);
			classProc = yyvsp[-1].number;
		    } else if (curClass) {
			yyerror("nested class declarations are not allowed (in %i now)",
				curClass->name);
			yynerrs++;
			Scan_DontUseOpProc(classProc);
			classProc = yyvsp[-1].number;
		    } else if (yyvsp[0].classDecl.class != (SymbolPtr)1) {
			EnterClass(Obj_DeclareClass(yyvsp[-3].sym->name, yyvsp[0].classDecl.class,
						    yyvsp[0].classDecl.flags));
			defClass = TRUE;
			isPublic = FALSE;
		    }
		;
    break;}
case 410:
#line 4672 "parse.y"
{
		    if (yyvsp[0].sym->u.class.data->flags & SYM_CLASS_FORWARD) {
			yyerror("%i must be defined before it can be used as a superclass.",
				yyvsp[0].sym->name);
			YYERROR;
		    }
		    yyval.classDecl.class = yyvsp[0].sym;
		    yyval.classDecl.flags = 0;
		;
    break;}
case 411:
#line 4682 "parse.y"
{
		    /*
		     * Class with no super class. NOTE: This is *only* for
		     * MetaClass, hence it accepts neither "master" nor
		     * "variant".
		     */
		    if (yyvsp[0].number != 0) {
			yyerror("superclass must be another class or 0");
			yynerrs++;
		    }
		    yyval.classDecl.class = NULL;
		    yyval.classDecl.flags = 0;
		;
    break;}
case 412:
#line 4696 "parse.y"
{
		    yyval.classDecl.class = yyvsp[-2].sym;
		    yyval.classDecl.flags = SYM_CLASS_MASTER;
		;
    break;}
case 413:
#line 4701 "parse.y"
{
		    /*
		     * By definition, a variant class must be the beginning
		     * of a group, so it must be a master class.
		     */
		    yyval.classDecl.class = yyvsp[-2].sym;
		    yyval.classDecl.flags = SYM_CLASS_MASTER | SYM_CLASS_VARIANT;
		;
    break;}
case 414:
#line 4710 "parse.y"
{
		    yyval.classDecl.class = yyvsp[-4].sym;
		    yyval.classDecl.flags = SYM_CLASS_MASTER | SYM_CLASS_VARIANT;
		;
    break;}
case 415:
#line 4715 "parse.y"
{
		    yyval.classDecl.class = yyvsp[-4].sym;
		    yyval.classDecl.flags = SYM_CLASS_MASTER | SYM_CLASS_VARIANT;
		;
    break;}
case 416:
#line 4720 "parse.y"
{
		    if (yychar == '\n' ||
			yychar == MASTER ||
			yychar == VARIANT)
		    {
			yyerror("class declaration missing superclass");
		    } else {
			yyerror("superclass must be another class or 0");
		    }
		    yyval.classDecl.class = (SymbolPtr)1;
		    yyval.classDecl.flags = 0;
		;
    break;}
case 417:
#line 4737 "parse.y"
{
		    yyval.number = 0;
		;
    break;}
case 418:
#line 4741 "parse.y"
{
		    yyval.number = SYM_METH_PUBLIC;
		;
    break;}
case 419:
#line 4745 "parse.y"
{
		    /*
		     * A method is public unless explicitly designated as
		     * private.
		     */
		    yyval.number = SYM_METH_PUBLIC;
		;
    break;}
case 420:
#line 4754 "parse.y"
{
		    if (!defClass) {
			yyerror("MESSAGE declaration for %i not inside class declaration",
				yyvsp[-2].ident);
			yynerrs++;
		    } else {
			SymbolPtr methodSym;
			Obj_CheckMessageBounds(curClass);
			methodSym = Sym_Enter(yyvsp[-2].ident, SYM_METHOD, curClass, yyvsp[0].number);

			/*
			 * Point the new message's protominor pointer at
			 * the current protominor symbol.
			 */

			methodSym->u.method.common.protoMinor = curProtoMinor;
		    }
		    Scan_DontUseOpProc(yyvsp[-1].number);
		;
    break;}
case 421:
#line 4777 "parse.y"
{
		    if (yyvsp[0].sym->type == SYM_METHOD) {
			/*
			 * 1.X-style exported message range
			 */
			SymbolPtr   class = yyvsp[0].sym->u.method.class;
			SymbolPtr   methods = class->u.class.data->methods;
			SymbolPtr   methodSym;
			int 	    offset;

			/*
			 * Switch counter for the Methods enumerated type to be
			 * that of the indicated method plus its current offset,
			 * then up the offset by one in case there's a next
			 * time.
			 */
			offset = (yyvsp[0].sym->u.method.flags & SYM_METH_RANGE_LENGTH) >>
			    SYM_METH_RANGE_LENGTH_OFFSET;

			methods->u.eType.nextVal =
			    yyvsp[0].sym->u.method.common.value + offset;

			yyvsp[0].sym->u.method.flags =
			    (yyvsp[0].sym->u.method.flags & ~SYM_METH_RANGE_LENGTH) |
				((offset+1) << SYM_METH_RANGE_LENGTH_OFFSET);

			methodSym = Sym_Enter(yyvsp[-2].ident, SYM_METHOD, class, SYM_METH_PUBLIC);
			methodSym->u.method.common.protoMinor = curProtoMinor;

		    } else {
			SymbolPtr	range;

			range = Sym_Find(yyvsp[0].sym->name, SYM_METHOD, FALSE);

			if (range == NullSymbol) {
			    yyerror("%i is not an exported message range, so you cannot import %i into it",
				    yyvsp[0].sym->name, yyvsp[-2].ident);
			} else if (yyvsp[0].sym->u.eType.nextVal ==
				   (range->u.method.common.value +
				    ((range->u.method.flags & SYM_METH_RANGE_LENGTH) >>
				     SYM_METH_RANGE_LENGTH_OFFSET)))
			{
			    yyerror("too many messages imported into %i", range->name);
			} else {
			    SymbolPtr   class = range->u.method.class;
			    SymbolPtr   msg;

			    msg = Sym_Enter(yyvsp[-2].ident, SYM_ENUM, yyvsp[0].sym,
					    yyvsp[0].sym->u.eType.nextVal);

			    msg->type = SYM_METHOD;
			    msg->u.method.common.protoMinor = curProtoMinor;
			    msg->u.method.class = class;
			    msg->u.method.flags = SYM_METH_PUBLIC;
			}
		    }
		    Scan_DontUseOpProc(yyvsp[-1].number);
		;
    break;}
case 423:
#line 4842 "parse.y"
{
		    if (geosRelease >= 2) {
			yyerror("%i is not an exported message range.",
				yyvsp[0].sym->name);
			YYERROR;
		    } else {
			yyval.sym = yyvsp[0].sym;
		    }
		;
    break;}
case 424:
#line 4852 "parse.y"
{
		    /*
		     * See if this thing is an exported message range by looking
		     * explicitly for a SYM_METHOD symbol of the same name.
		     */
		    yyval.sym = Sym_Find(yyvsp[0].ident, SYM_METHOD, FALSE);
		    if (yyval.sym != NullSymbol) {
			/*
			 * It is indeed. Create the appropriate enumerated
			 * type, starting at the value bound to the METHOD
			 * symbol, increasing by 1, and taking 2 bytes to
			 * hold it.
			 */
			yyval.sym = Sym_Enter(yyvsp[0].ident, SYM_ETYPE, yyval.sym->u.method.common.value,
				       1, 2, 0);
		    } else {
			yyerror("%i is not an exported message range.", yyvsp[0].ident);
			YYERROR;
		    }
		;
    break;}
case 425:
#line 4874 "parse.y"
{
		    if (!curClass || !defClass) {
			yyerror("VarData can only be declared while declaring a class");
		    } else {
			SymbolPtr varSym;
			Obj_CheckVarDataBounds(curClass);
			varSym = Sym_Enter(yyvsp[-2].ident, SYM_VARDATA,
					curClass->u.class.data->vardata,
					curClass->u.class.data->vardata->u.eType.nextVal,
					yyvsp[0].type);
			/*
			 * Point the new vardata's protominor pointer at
			 * the current protominor symbol.
			 */
			varSym->u.varData.common.protoMinor = curProtoMinor;
		    }
		;
    break;}
case 426:
#line 4892 "parse.y"
{ yyval.type = (TypePtr)NULL; ;
    break;}
case 428:
#line 4897 "parse.y"
{
                    curProtoMinor = yyvsp[0].sym;
                ;
    break;}
case 429:
#line 4903 "parse.y"
{
                    yyval.sym = yyvsp[0].sym;
                ;
    break;}
case 430:
#line 4907 "parse.y"
{
                    /*
		     * We can't enter it into the (null) segment, since
		     * that would cause Sym_SetAddress to die, so if
		     * there's no current segment, we'll make one
		     */

                    if (curSeg->name == NullID) {

			/*
			 * If there's already a bogus segment for us to
			 * use, we'll just use it. Otherwise, we need a
			 * new one.
			 * 12/21/94: use word alignment to flag special
			 * proto minor segment in Glue -- ardeb
			 */

			if (protoMinorSymbolSeg == NullSymbol) {
			    char    	name[25];
			    ID	    	bogusId;

			    sprintf(name, "ProtoMinorSymbolSegment");
			    bogusId = ST_EnterNoLen(output, symStrings, name);
			    protoMinorSymbolSeg = Sym_Enter(bogusId,
							    SYM_SEGMENT,
							    SEG_LIBRARY,
							    1, NullID);
			}

			/*
			 * Make the bogus segment the current segment so
			 * that our symbol ends up there
			 */

			PushSegment(protoMinorSymbolSeg);
		    }

                    /*
		     * Enter the protominor symbol into the current segment
		     * as an undefined global.
		     */
                    curProtoMinor = Sym_Enter(yyvsp[0].ident, SYM_PROTOMINOR);
                    curProtoMinor->flags |= SYM_GLOBAL|SYM_UNDEF;
                    yyval.sym = curProtoMinor;

                    /*
		     * Clean up the segment stack if we had to use a
		     * bogus segment.
		     */
                    if (curSeg == protoMinorSymbolSeg) {
			PopSegment();
		    }
                ;
    break;}
case 431:
#line 4963 "parse.y"
{
                    curProtoMinor = NullSymbol;
                ;
    break;}
case 432:
#line 4973 "parse.y"
{
		    if (!curClass || !defClass) {
			yyerror("PUBLIC when not declaring a class");
			yynerrs++;
		    } else {
			isPublic = TRUE;
		    }
		    /*
		     * Scan turns on ignoring when PUBLIC seen. We need to
		     * turn it off again...
		     */
		    ignore = FALSE;
		;
    break;}
case 434:
#line 4989 "parse.y"
{
		    yyvsp[0].sym->u.instvar.flags |= SYM_VAR_PUBLIC;
		;
    break;}
case 435:
#line 4993 "parse.y"
{
		    switch(yychar) {
			case IDENT:
			    /*
			     * Assume "public" came too soon.
			     */
			    yyerror("instance variable %i not defined yet",
				    yyvsp[0].ident);
			    break;
			case SYM:
			case EXPR_SYM:
			case CLASS_SYM:
			case STRUCT_SYM:
			case METHOD_SYM:
			case MODULE_SYM:
			case TYPE_SYM:
			case ETYPE_SYM:
			case RECORD_SYM:
			case PROTOMINOR_SYM:
			    /*
			     * Can only declare instance variables public
			     * here, mate.
			     */
			    yyerror("symbol %i is not an instance variable, so it cannot be given as the argument for PUBLIC inside a class definition",
				    yyvsp[0].sym->name);
			    break;
		    }
		    /*
		     * Biff the erroneous token and move on to the next element
		     * in the list by allowing errors to happen.
		     */
		    yyclearin;
		    yyerrok;
		;
    break;}
case 438:
#line 5032 "parse.y"
{
		    if ((expr1.numElts == 2) &&
			(expr1.elts[0].op == EXPR_SYMOP) &&
			(expr1.elts[1].sym->type == SYM_VARDATA))
		    {
			/*
			 * If only element of the operand is a VARDATA tag,
			 * it means the user doesn't want a relocation table
			 * for anything in the associated data, so pass NULL
			 * to Obj_NoReloc to indicate this, along with the
			 * tag from the bowels of the expression.
			 */
			Obj_NoReloc(curClass, expr1.elts[1].sym, NULL);
		    } else {
			Obj_NoReloc(curClass, NullSymbol, &expr1);
		    }

		;
    break;}
case 439:
#line 5051 "parse.y"
{
		    if ((expr1.numElts != 2) ||
			(expr1.elts[0].op != EXPR_SYMOP) ||
			(expr1.elts[1].sym->type != SYM_VARDATA))
		    {
			yyerror("this form of noreloc operand requires a defined vardata type before the parenthesized field that's not to be relocated");
		    } else {
			Obj_NoReloc(curClass, expr1.elts[1].sym, &expr2);
		    }
		;
    break;}
case 440:
#line 5062 "parse.y"
{
		    switch(yychar) {
			case IDENT:
			    /*
			     * Assume "noreloc" came too soon.
			     */
			    yyerror("instance variable %i not defined yet",
				    yyvsp[0].ident);
			    break;
			case SYM:
			case EXPR_SYM:
			case CLASS_SYM:
			case STRUCT_SYM:
			case METHOD_SYM:
			case PROTOMINOR_SYM:
			case MODULE_SYM:
			case TYPE_SYM:
			case ETYPE_SYM:
			case RECORD_SYM:
			    /*
			     * Can only declare instance variables public
			     * here, mate.
			     */
			    yyerror("symbol %i is not an instance variable",
				    yyvsp[0].sym->name);
			    break;
		    }
		    /*
		     * Biff the erroneous token and move on to the next element
		     * in the list by allowing errors to happen.
		     */
		    yyclearin;
		    yyerrok;
		;
    break;}
case 444:
#line 5106 "parse.y"
{
		    isPublic = FALSE;
		;
    break;}
case 445:
#line 5110 "parse.y"
{
		    yyerror("state variables are not supported");
		    yynerrs++;
		;
    break;}
case 447:
#line 5117 "parse.y"
{
		    if (!curClass || !defClass) {
			yyerror("not in class declaration");
			yynerrs++;
		    } else {
			ClassData   *cd = curClass->u.class.data;

			/*
			 * Make room for another symbol in the list of used
			 * classes
			 */
			cd->numUsed += 1;
			cd = (ClassData *)realloc((void *)cd,
 		                                   sizeof(ClassData) +
						   (cd->numUsed *
						   sizeof(SymbolPtr)));
			curClass->u.class.data = cd;

			/*
			 * Stick the indicated one into the list
			 */
			cd->used[cd->numUsed-1] = yyvsp[0].sym;
		    }
		;
    break;}
case 449:
#line 5144 "parse.y"
{
		    /*
		     * Assume this thing will be declared a class later and
		     * enter a forward declaration for it.
		     */
		    yyval.sym = Obj_DeclareClass(yyvsp[0].ident, NullSymbol, SYM_CLASS_FORWARD);
		;
    break;}
case 453:
#line 5157 "parse.y"
{
		    if (!curClass || !defClass) {
			yyerror("cannot export a message range when not defining a class");
			yynerrs++;
		    } else {
			Obj_ExportMessages(curClass, yyvsp[-2].ident, &expr1);
		    }
		;
    break;}
case 454:
#line 5166 "parse.y"
{
		    if (!curClass || !defClass) {
			yyerror("ENDC when not defining class %i", yyvsp[-1].sym->name);
			yynerrs++;
		    } else {
			defClass = FALSE;
			EndClass();
			Scan_DontUseOpProc(classProc);
			classProc = -1;

			/*
			 * We'll reset curProtoMinor here as well so that
			 * wacky things like exported message ranges don't
			 * inherit this class's curProtoMinor.
			 */
			curProtoMinor = NullSymbol;
		    }
		;
    break;}
case 455:
#line 5189 "parse.y"
{
		    if (yyvsp[-1].sym->u.class.data->flags & SYM_CLASS_FORWARD) {
			yyerror("class %i not defined", yyvsp[-1].sym->name);
		    } else if (yyvsp[-1].sym->flags & SYM_UNDEF) {
			Obj_DefineClass(yyvsp[-1].sym, yyvsp[0].classDef.flags, yyvsp[0].classDef.initRoutine);
		    } else {
			yyerror("class %i is multiply defined", yyvsp[-1].sym->name);
			yynerrs++;
		    }
		;
    break;}
case 456:
#line 5201 "parse.y"
{
		    yyval.classDef.initRoutine = yyval.classDef.flags = (Expr *)NULL;
		;
    break;}
case 457:
#line 5205 "parse.y"
{
		    yyval.classDef.flags = &expr1;
		    yyval.classDef.initRoutine = (Expr *)NULL;
		;
    break;}
case 458:
#line 5210 "parse.y"
{
		    yyval.classDef.flags = &expr1;
		    yyval.classDef.initRoutine = &expr2;
		;
    break;}
case 463:
#line 5224 "parse.y"
{
		    (void)Code_Arith2(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 464:
#line 5228 "parse.y"
{
		    (void)Code_Arpl(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 465:
#line 5232 "parse.y"
{
		    (void)Code_BitNF(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 466:
#line 5236 "parse.y"
{
		    (void)Code_Bound(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 467:
#line 5240 "parse.y"
{
		    Code_CallStatic(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 468:
#line 5244 "parse.y"
{
		    (void)Code_Call(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 469:
#line 5248 "parse.y"
{
		    (void)Code_String(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 470:
#line 5252 "parse.y"
{
		    (void)Code_String(&dot, 0, 1, NULL, &expr1, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 471:
#line 5256 "parse.y"
{
		    (void)Code_EnterLeave(&dot, 0, 1, &expr1, &expr2,
					  (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 472:
#line 5261 "parse.y"
{
		    (void)Code_Fbiop(&dot, 0, 1, NULL, NULL, (Opaque)yyvsp[0].opcode);
		;
    break;}
case 473:
#line 5265 "parse.y"
{
		    (void)Code_Fbiop(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 474:
#line 5269 "parse.y"
{
		    (void)Code_Fbiop(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 475:
#line 5273 "parse.y"
{
		    (void)Code_Fcom(&dot, 0, 1, NULL, NULL, (Opaque)yyvsp[0].opcode);
		;
    break;}
case 476:
#line 5277 "parse.y"
{
		    (void)Code_Fcom(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 477:
#line 5281 "parse.y"
{
		    (void)Code_Ffree(&dot, 0, 1, &expr1, NULL, (Opaque)1);
		;
    break;}
case 478:
#line 5285 "parse.y"
{
		    (void)Code_Fgroup0(&dot, 0, 1,NULL, NULL, (Opaque)yyvsp[0].opcode);
		;
    break;}
case 479:
#line 5289 "parse.y"
{
		    (void)Code_Fgroup1(&dot, 0, 1, &expr1, NULL,(Opaque)yyvsp[-1].opcode);
		;
    break;}
case 480:
#line 5293 "parse.y"
{
		    (void)Code_Fint(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 481:
#line 5297 "parse.y"
{
                    (void)Code_Fldst(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 482:
#line 5301 "parse.y"
{
		    (void)Code_Fxch(&dot, 0, 1, NULL, NULL, (Opaque)yyvsp[0].opcode);
		;
    break;}
case 483:
#line 5305 "parse.y"
{
		    (void)Code_Fxch(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 484:
#line 5309 "parse.y"
{
		    (void)Code_Fzop(&dot, 0, 1, NULL, NULL, (Opaque)yyvsp[0].opcode);
		;
    break;}
case 485:
#line 5313 "parse.y"
{
		    (void)Code_Group1(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 494:
#line 5321 "parse.y"
{
		    (void)Code_Group1(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 495:
#line 5325 "parse.y"
{
		    (void)Code_Imul(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[0].number);
		;
    break;}
case 496:
#line 5329 "parse.y"
{
		    (void)Code_Imul(&dot, 0, 1, &expr1, &expr2, (Opaque)0);
		;
    break;}
case 497:
#line 5333 "parse.y"
{
		    (void)Code_IO(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 498:
#line 5337 "parse.y"
{
		    (void)Code_Ins(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 499:
#line 5341 "parse.y"
{
		    (void)Code_Int(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 500:
#line 5345 "parse.y"
{
		    (void)Code_Jmp(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 501:
#line 5349 "parse.y"
{
		    (void)Code_Jcc(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 502:
#line 5353 "parse.y"
{
		    (void)Code_LDPtr(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 503:
#line 5357 "parse.y"
{
		    (void)Code_Lea(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 504:
#line 5361 "parse.y"
{
		    (void)Code_EnterLeave(&dot, 0, 1, NULL, NULL, (Opaque)yyvsp[0].opcode);
		;
    break;}
case 505:
#line 5365 "parse.y"
{
		    (void)Code_String(&dot, 0, 1, NULL, &expr1, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 506:
#line 5369 "parse.y"
{
		    (void)Code_Loop(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 507:
#line 5373 "parse.y"
{
		    /* Load/Store GDT/IDT */
		    (void)Code_LSDt(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 508:
#line 5378 "parse.y"
{
		    /* Load Selector Info: LAR/LSL */
		    (void)Code_LSInfo(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 509:
#line 5383 "parse.y"
{
		    (void)Code_Move(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 510:
#line 5387 "parse.y"
{
		    (void)Code_String(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 511:
#line 5391 "parse.y"
{
		    (void)Code_String(&dot, 0, 1, NULL, &expr1, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 512:
#line 5395 "parse.y"
{
		    /* I/O instruction w/o arg */
		    (void)Code_NoArgIO(&dot, 0, 1, NULL, NULL, (Opaque)yyvsp[0].opcode);
		;
    break;}
case 513:
#line 5400 "parse.y"
{
		    /* privileged instruction w/o arg */
		    (void)Code_NoArgPriv(&dot, 0, 1, NULL, NULL, (Opaque)yyvsp[0].opcode);
		;
    break;}
case 514:
#line 5405 "parse.y"
{
		    /* String Inst w/o override */
		    (void)Code_NoArg(&dot, 0, 1, NULL, NULL, (Opaque)yyvsp[0].opcode);
		;
    break;}
case 515:
#line 5410 "parse.y"
{
		    /*
		     * Invoke Code_Override ourselves, allowing us to
		     * use Code_NoArg to store the instruction itself
		     */
		    if (yyvsp[-1].number != REG_DS) {
			ResetExpr(&expr1, defElts1);
			StoreExprReg(EXPR_SEGREG, yyvsp[-1].number);
			Code_Override(&dot, 0, 1, &expr1, 0, (Opaque)NULL);
		    }
		    (void)Code_NoArg(&dot, 0, 1, NULL, NULL, (Opaque)yyvsp[-2].opcode);
		;
    break;}
case 516:
#line 5423 "parse.y"
{
		    (void)Code_NoArg(&dot, 0, 1, NULL, NULL, (Opaque)yyvsp[0].opcode);
		;
    break;}
case 517:
#line 5427 "parse.y"
{
		    (void)Code_Outs(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 518:
#line 5430 "parse.y"
{;
    break;}
case 519:
#line 5433 "parse.y"
{
		    (void)Code_Pop(&dot, 0, 1, yyvsp[0].expr, NULL, (Opaque)NULL);
		    Expr_Free(yyvsp[0].expr);
		;
    break;}
case 520:
#line 5438 "parse.y"
{
		    (void)Code_Pop(&dot, 0, 1, yyvsp[-2].expr, NULL, (Opaque)NULL);
		    Expr_Free(yyvsp[-2].expr);
		;
    break;}
case 521:
#line 5444 "parse.y"
{
		    yyval.expr = Expr_Copy(&expr1, TRUE);
		    malloc_settag((void *)yyval.expr, TAG_POP_OPERAND);
		;
    break;}
case 522:
#line 5449 "parse.y"
{;
    break;}
case 525:
#line 5455 "parse.y"
{
		    (void)Code_Push(&dot, 0, 1, &expr1, NULL, (Opaque)NULL);
		;
    break;}
case 526:
#line 5460 "parse.y"
{
		    /* Load/Store LDT/TR/MSW; Verify selector */
		    (void)Code_PWord(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 529:
#line 5474 "parse.y"
{
		    /*
		     * Call the procedure to handle the prefix.
		     */
		    (*yyvsp[0].prefix.proc)(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[0].prefix.op);
		;
    break;}
case 530:
#line 5485 "parse.y"
{ yyval.prefix.proc = Code_Rep; yyval.prefix.op = yyvsp[0].opcode; ;
    break;}
case 531:
#line 5486 "parse.y"
{ yyval.prefix.proc = Code_Lock; yyval.prefix.op = yyvsp[0].opcode; ;
    break;}
case 532:
#line 5488 "parse.y"
{
		    /*
		     * Little more work here -- have to store the segment
		     * register in question.
		     */
		    StoreExprReg(EXPR_SEGREG, yyvsp[-1].number);
		    yyval.prefix.proc = Code_Override;
		    yyval.prefix.op = (OpCode *)NULL;
		;
    break;}
case 533:
#line 5499 "parse.y"
{
		    if (curProc) {
			Expr	*arg = (Expr *)NULL;

			/*
			 * If language isn't C and there are actually args
			 * for the procedure, and they weren't just inherited,
			 * generate an expression for the number of bytes in
			 * the parameters and pass that as the argument to
			 * Code_Ret to have it pop the args off the stack upon
			 * return.
			 */
			if (language != LANG_C) {
			    int	argSize = argOffset -
					    (Sym_IsNear(curProc) ? 4 : 6);

			    if (argSize != 0 && frameNeeded) {
				ResetExpr(&expr1, defElts1);
				StoreExprConst(argSize);
				arg = &expr1;
			    }
			}
			(void)Code_Ret(&dot, 0, 1, arg,
				       (Expr *)!Sym_IsNear(curProc),
				       (Opaque)yyvsp[0].opcode);
		    } else {
			yywarning("RET outside of procedure -- defaulting to RETF");
			(void)Code_Ret(&dot, 0, 1, NULL, (Expr *)1,
				       (Opaque)yyvsp[0].opcode);
		    }
		;
    break;}
case 534:
#line 5531 "parse.y"
{
		    if (curProc) {
			(void)Code_Ret(&dot, 0, 1, &expr1,
				       (Expr *)!Sym_IsNear(curProc),
				       (Opaque)yyvsp[-1].opcode);
		    } else {
			yywarning("RET outside of procedure -- defaulting to RETF");
			(void)Code_Ret(&dot, 0, 1, &expr1, (Expr *)1,
				       (Opaque)yyvsp[-1].opcode);
		    }
		;
    break;}
case 535:
#line 5543 "parse.y"
{
		    (void)Code_Ret(&dot, 0, 1, NULL, NULL, (Opaque)yyvsp[0].opcode);
		;
    break;}
case 536:
#line 5547 "parse.y"
{
		    (void)Code_Ret(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 539:
#line 5555 "parse.y"
{
		    (void)Code_String(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 543:
#line 5564 "parse.y"
{
		    (void)Code_Shift(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 544:
#line 5568 "parse.y"
{
		    /*
		     * Perform single-bit shift
		     */
		    ResetExpr(&expr2, defElts2);
		    StoreExprConst(1);

		    (void)Code_Shift(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 545:
#line 5579 "parse.y"
{
		    if (yyvsp[0].number != REG_CL) {
			yyerror("can only shift by CL or a constant");
			yynerrs++;
		    } else {
			yyval.number = -1;
		    }
		;
    break;}
case 546:
#line 5588 "parse.y"
{
		    if (yyvsp[0].number == -1) {
			yyerror("isn't that a funny shift count?");
			yynerrs++;
		    } else {
			yyval.number = yyvsp[0].number;
		    }
		;
    break;}
case 547:
#line 5598 "parse.y"
{
		    (void)Code_DPShiftLeft(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[0].number);
		;
    break;}
case 548:
#line 5602 "parse.y"
{
		    (void)Code_DPShiftRight(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[0].number);
		;
    break;}
case 549:
#line 5606 "parse.y"
{
		    (void)Code_String(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 550:
#line 5610 "parse.y"
{
		    (void)Code_Test(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 551:
#line 5614 "parse.y"
{
		    /* INC/DEC */
		    (void)Code_IncDec(&dot, 0, 1, &expr1, NULL, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 552:
#line 5619 "parse.y"
{
		    (void)Code_Xchg(&dot, 0, 1, &expr1, &expr2, (Opaque)yyvsp[-3].opcode);
		;
    break;}
case 553:
#line 5623 "parse.y"
{
		    (void)Code_String(&dot, 0, 1, NULL, &expr1, (Opaque)yyvsp[-1].opcode);
		;
    break;}
case 554:
#line 5627 "parse.y"
{
		    (void)Code_NoArg(&dot, 0, 1, NULL, NULL, (Opaque)yyvsp[0].opcode);
		;
    break;}
case 555:
#line 5636 "parse.y"
{ lexdebug = yydebug = yyvsp[0].number; ;
    break;}
case 556:
#line 5637 "parse.y"
{ showmacro = yyvsp[0].number; ;
    break;}
case 557:
#line 5638 "parse.y"
{ masmCompatible = yyvsp[0].number; ;
    break;}
case 558:
#line 5639 "parse.y"
{ _asm int 3; ;
    break;}
case 559:
#line 5640 "parse.y"
{ fall_thru = 1; ;
    break;}
case 560:
#line 5642 "parse.y"
{
		    /*
		     * Set flag allowing procedure to be closed without
		     * appropriate unconditional branch or return.
		     */
		    fall_thru = 1;
		    /*
		     * Register a fixup for the second pass for us to evaluate
		     * the operand and make sure its offset matches the offset
		     * of the .fall_thru.
		     */
		    Fix_Register(FC_UNDEF,
				 ParseFallThruCheck,
				 dot,
				 0,
				 Expr_Copy(&expr1, TRUE),
				 0,
				 (Opaque)0);
		;
    break;}
case 561:
#line 5661 "parse.y"
{ curSeg->u.segment.data->checkLabel=TRUE; ;
    break;}
case 562:
#line 5663 "parse.y"
{
		    procType &= ~PROC_MASK; procType |= yyvsp[0].number;
		    sprintf(predefs[PD_CPU].value->text, "0x%04x", procType);
		;
    break;}
case 563:
#line 5668 "parse.y"
{
		    procType &= ~PROC_CO_MASK; procType |= yyvsp[0].number;
		    sprintf(predefs[PD_CPU].value->text, "0x%04x", procType);
		;
    break;}
case 564:
#line 5673 "parse.y"
{
		    procType |= PROC_IO;
		    sprintf(predefs[PD_CPU].value->text, "0x%04x", procType);
		;
    break;}
case 565:
#line 5678 "parse.y"
{
		    Assert_Enter(&expr1, NULL);
		;
    break;}
case 566:
#line 5681 "parse.y"
{ defStruct = 0; ;
    break;}
case 567:
#line 5682 "parse.y"
{
		    Assert_Enter(&expr1, yyvsp[0].string);
		;
    break;}
case 568:
#line 5686 "parse.y"
{
		    if (inStruct) {
			int 	diff =
			    ((inStruct->u.sType.common.size+yyvsp[0].number)&~yyvsp[0].number)-
				inStruct->u.sType.common.size;

			if (diff != 0) {
			    /*
			     * Create a nameless array field to take up
			     * the slack. Need to create a DupExpr of 0 bytes
			     * as initializing with an empty string causes
			     * nothing to be actually entered...
			     */
			    ResetExpr(&expr1, defElts1);
			    StoreExprConst(0);
			    StoreExprComma();
			    if (diff > 1) {
			        DupExpr(diff-1, 0);
			        (void)Sym_Enter(NullID, SYM_FIELD, inStruct,
					        Type_Array(diff, Type_Int(1)),
					        Expr_Copy(curExpr, TRUE));
			    } else {
			        (void)Sym_Enter(NullID, SYM_FIELD, inStruct,
					        Type_Int(1),
					        &zeroExpr);
			    }
			}
		    } else {
			int segSize;

			dot += yyvsp[0].number;
			dot &= ~yyvsp[0].number;

			/*
			 * Make sure the bytes are actually in the segment...
			 * in case this alignment comes at the very end of
			 * the segment and needs to be propagated to the
			 * linker.
			 */
			segSize = Table_Size(curSeg->u.segment.code);

			if (segSize < dot) {
			    (void)Table_StoreZeroes(curSeg->u.segment.code,
						    dot - segSize,
						    segSize);
			}

		    }
		    Scan_DontUseOpProc(yyvsp[-1].number);
		;
    break;}
case 569:
#line 5737 "parse.y"
{
		    if (inStruct) {
			int 	diff =
			    (((inStruct->u.sType.common.size+yyvsp[0].number-1)/yyvsp[0].number)*yyvsp[0].number)-
				inStruct->u.sType.common.size;

			if (diff != 0) {
			    /*
			     * Create a nameless array field to take up
			     * the slack. Need to create a DupExpr of 0 bytes
			     * as initializing with an empty string causes
			     * nothing to be actually entered...
			     */
			    ResetExpr(&expr1, defElts1);
			    StoreExprConst(0);
			    StoreExprComma();
			    if (diff > 1) {
			        DupExpr(diff-1, 0);
			        (void)Sym_Enter(NullID, SYM_FIELD, inStruct,
					        Type_Array(diff, Type_Int(1)),
					        Expr_Copy(curExpr, TRUE));
			    } else {
			        (void)Sym_Enter(NullID, SYM_FIELD, inStruct,
					        Type_Int(1),
					        &zeroExpr);
			    }
			}
		    } else {
			int segSize;

			dot = ((dot + yyvsp[0].number - 1) / yyvsp[0].number) * yyvsp[0].number;

			/*
			 * Make sure the bytes are actually in the segment...
			 * in case this alignment comes at the very end of
			 * the segment and needs to be propagated to the
			 * linker.
			 */
			segSize = Table_Size(curSeg->u.segment.code);

			if (segSize < dot) {
			    (void)Table_StoreZeroes(curSeg->u.segment.code,
						    dot - segSize,
						    segSize);
			}
		    }
		    Scan_DontUseOpProc(yyvsp[-1].number);
		;
    break;}
case 570:
#line 5786 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-1].number);
		;
    break;}
case 571:
#line 5790 "parse.y"
{
		    if (inStruct) {
			/*
			 * Create a nameless byte field to take up
			 * the slack. The thing is initialized with a 0
			 * constant as initializing with an empty string causes
			 * nothing to be entered.
			 */
			if (inStruct->u.sType.common.size & 1) {
			    Sym_Enter(NullID, SYM_FIELD, inStruct,
				      Type_Int(1), &zeroExpr);
			}
		    } else {
			dot += 1;
			dot &= ~1;
		    }
		;
    break;}
case 572:
#line 5809 "parse.y"
{
		    yyval.number = Scan_UseOpProc(findSegToken);
		;
    break;}
case 573:
#line 5813 "parse.y"
{ snarfLine=1; ;
    break;}
case 574:
#line 5814 "parse.y"
{
		    ID	    desc;
		    char    *cp;

		    if (!curProc) {
			yyerror("on_stack only valid inside a procedure");
			yynerrs++;
		    } else {
			curProc->u.proc.flags |= SYM_WEIRD;
			/*
			 * Trim off trailing spaces or comments
			 */
			cp = index(yyvsp[0].string, ';');
			if (cp == NULL) {
			    cp = yyvsp[0].string+strlen(yyvsp[0].string);
			}
			while (isspace(*--cp)) {
			    ;
			}
			cp[1] = '\0';
			desc = ST_Enter(output, permStrings, yyvsp[0].string, cp-yyvsp[0].string+1);
			Sym_Enter(NullID, SYM_ONSTACK, dot, desc);
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 575:
#line 5839 "parse.y"
{ snarfLine = 1; ;
    break;}
case 576:
#line 5840 "parse.y"
{
		    char    *cp;
		    char    *start;
		    char    savec;
		    int	    i;

		    start = yyvsp[0].string;

		    for (start=yyvsp[0].string; *start!='\0' && *start!=';'; start=cp) {
			while (isspace(*start) || *start == ',') {
			    start++;
			}
			for (cp = start;
			     !isspace(*cp) && (*cp != '\0') && (*cp != ',') &&
			     (*cp != ';');
			     cp++)
			{
			    ;
			}
			if (cp == start) {
			    break;
			}
			savec = *cp;
			*cp = '\0';
			if ((*start == '@') &&
			    ((start[1] == '+') || (start[1] == '-')))
			{
			    for (i = 0; i < numWarnOpts; i++) {
				if (strcmp(warnOpts[i].flag, start+2) == 0) {
				    break;
				}
			    }
			}
			else {
			    for (i = 0; i < numWarnOpts; i++) {
				if (strcmp(warnOpts[i].flag, start+1) == 0) {
				    break;
				}
			    }
			}

			if (i == numWarnOpts) {
			    yyerror("unknown .warn option: %s", start);
			    yynerrs++;
			} else if (*start == '+') {
			    *warnOpts[i].var = 1;
			} else if (*start == '-') {
			    *warnOpts[i].var = 0;
			} else if (*start == '@') {
			    if (start[1] == '+') {
				warnOpts[i].defval = 1;
			    } else if (start[1] == '-') {
				warnOpts[i].defval = 0;
			    }
			    *warnOpts[i].var = warnOpts[i].defval;
			} else {
			    yyerror("unknown .warn command '%c'",
				    *start);
			    yynerrs++;
			}

			*cp = savec;
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 577:
#line 5906 "parse.y"
{
		    if (makeDepend != TRUE)
		    {
		        fputs(yyvsp[0].string, stderr);
		        putc('\n', stderr);
		        fflush(stderr);
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 578:
#line 5916 "parse.y"
{
		    ExprResult	result;

		    if (!Expr_Eval(&expr1, &result,
				   EXPR_NOUNDEF|EXPR_FINALIZE|EXPR_NOT_OPERAND,
				   NULL))
		    {
			/*
			 * Give error message we got back
			 */
			yyerror((char *)result.type);
			yynerrs++;
		    } else if (result.type == EXPR_TYPE_CONST)
		    {
			/*
			 * Use the value we got back
			 */
			if (result.rel.sym) {
			    yyerror("org: constant expected");
			    yynerrs++;
			} else {
			    dot = result.data.number;
			}
		    } else if (result.type == EXPR_TYPE_STRING) {
			yyerror("org: argument may not be a string");
			yynerrs++;
		    } else if (result.data.ea.modrm != MR_DIRECT) {
			yyerror("org: argument must be constant or a direct address");
			yynerrs++;
		    } else {
			if (result.rel.sym) {
			    if ((result.rel.frame != curSeg) &&
				(result.rel.frame != curSeg->segment))
			    {
				yyerror("org: address not in current segment");
			    } else if (result.rel.sym->flags & SYM_UNDEF) {
				yyerror("org: symbol %i's address must be defined", result.rel.sym->name);
			    } else {
				/*
				 * Add in the symbol's offset, since the
				 * expression evaluator won't have.
				 */
				dot = (word)(result.data.ea.disp +
					     result.rel.sym->u.addrsym.offset);
			    }
			} else {
			    /*XXX: Should we disallow this? */
			    dot = result.data.ea.disp;
			}
		    }
		;
    break;}
case 579:
#line 5967 "parse.y"
{ snarfLine = 1; ;
    break;}
case 580:
#line 5968 "parse.y"
{
		    yywarning("%s not supported -- rest of line discarded",
			      yyvsp[-2].opcode->name);
		    free(yyvsp[0].string);
		;
    break;}
case 581:
#line 5975 "parse.y"
{
		    yyval.number = Scan_UseOpProc(findModelToken);
		;
    break;}
case 582:
#line 5980 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-1].number);
		    model = yyvsp[0].model;
		;
    break;}
case 583:
#line 5985 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-3].number);
		    model = yyvsp[-2].model;
		    language = yyvsp[0].lang;
		;
    break;}
case 584:
#line 5991 "parse.y"
{
		    Scan_DontUseOpProc(yyvsp[-1].number);
		    yyerrok;
		    if (yychar != '\n') {
			yyclearin;
		    }
		;
    break;}
case 585:
#line 6000 "parse.y"
{
		    /* Turn on memory-write checking */
		    writeCheck = TRUE;
		;
    break;}
case 586:
#line 6006 "parse.y"
{
		    /* Turn off memory-write checking */
		    writeCheck = FALSE;
		;
    break;}
case 587:
#line 6012 "parse.y"
{
		    /* Turn on memory-read checking */
		    readCheck = TRUE;
		;
    break;}
case 588:
#line 6018 "parse.y"
{
		    /* Turn off memory-read checking */
		    readCheck = FALSE;
		;
    break;}
case 590:
#line 6032 "parse.y"
{
		    HandleIF(yyvsp[-2].number);
		    RestoreExpr(&yyvsp[-1].exprSave);
		;
    break;}
case 591:
#line 6037 "parse.y"
{
		    yywarning("%sIF1 is meaningless (only one source pass)",
			      yyvsp[-1].number ? "ELSE" : "");
		    StoreExprConst(1);
		    HandleIF(yyvsp[-1].number);
		    RestoreExpr(&yyvsp[0].exprSave);
		;
    break;}
case 592:
#line 6045 "parse.y"
{
		    yywarning("%sIF2 is meaningless (only one source pass)",
			      yyvsp[-1].number ? "ELSE" : "");
		    StoreExprConst(1);
		    HandleIF(yyvsp[-1].number);
		    RestoreExpr(&yyvsp[0].exprSave);
		;
    break;}
case 593:
#line 6053 "parse.y"
{
		    StoreExprConst(*yyvsp[-1].string == '\0');
		    free(yyvsp[-1].string);
		    HandleIF(yyvsp[-2].number);
		    RestoreExpr(&yyvsp[0].exprSave);
		;
    break;}
case 594:
#line 6060 "parse.y"
{
		    StoreExprConst(Sym_Find(yyvsp[-1].ident, SYM_ANY, FALSE) != 0);
		    HandleIF(yyvsp[-2].number);
		    RestoreExpr(&yyvsp[0].exprSave);
		;
    break;}
case 595:
#line 6066 "parse.y"
{
		    /*
		     * Masm supports empty ifdefs to allow one to use it
		     * to test for a macro argument having been given...
		     * Gross.
		     */
		    StoreExprConst(0);
		    HandleIF(yyvsp[-1].number);
		    RestoreExpr(&yyvsp[0].exprSave);
		;
    break;}
case 596:
#line 6077 "parse.y"
{
		    StoreExprConst(strcmp(yyvsp[-3].string, yyvsp[-1].string) != 0);
		    free(yyvsp[-3].string);
		    free(yyvsp[-1].string);
		    HandleIF(yyvsp[-4].number);
		    RestoreExpr(&yyvsp[0].exprSave);
		;
    break;}
case 597:
#line 6085 "parse.y"
{
		    StoreExprConst(0);
		    StoreExprOp(EXPR_EQ);
		    HandleIF(yyvsp[-2].number);
		    RestoreExpr(&yyvsp[-1].exprSave);
		;
    break;}
case 598:
#line 6092 "parse.y"
{
		    StoreExprConst(strcmp(yyvsp[-3].string, yyvsp[-1].string)==0);
		    free(yyvsp[-3].string);
		    free(yyvsp[-1].string);
		    HandleIF(yyvsp[-4].number);
		    RestoreExpr(&yyvsp[0].exprSave);
		;
    break;}
case 599:
#line 6100 "parse.y"
{
		    StoreExprConst(*yyvsp[-1].string != '\0');
		    free(yyvsp[-1].string);
		    HandleIF(yyvsp[-2].number);
		    RestoreExpr(&yyvsp[0].exprSave);
		;
    break;}
case 600:
#line 6107 "parse.y"
{
		    StoreExprConst(!Sym_Find(yyvsp[-1].ident, SYM_ANY, FALSE));
		    HandleIF(yyvsp[-2].number);
		    RestoreExpr(&yyvsp[0].exprSave);
		;
    break;}
case 601:
#line 6113 "parse.y"
{
		    StoreExprConst(1);
		    HandleIF(yyvsp[-1].number);
		    RestoreExpr(&yyvsp[0].exprSave);
		;
    break;}
case 602:
#line 6119 "parse.y"
{
		    if (iflevel == -1) {
			yyerror("IF-less ELSE");
			yynerrs++;
		    } else if (ifStack[iflevel].value == -1) {
			yyerror("Already had an ELSE for this level");
			yynerrs++;
		    } else if (ifStack[iflevel].value) {
			/*
			 * Remember ELSE and go to the endif
			 */
			ifStack[iflevel].value = -1;
			Scan_ToEndif(FALSE);
		    } else {
			/*
			 * IF was false, so continue parsing, but remember
			 * we had an ELSE already.
			 */
			ifStack[iflevel].value = -1;
		    }
		;
    break;}
case 603:
#line 6141 "parse.y"
{
		    if (iflevel == -1) {
			yyerror("IF-less ENDIF");
			yynerrs++;
		    } else {
			iflevel -= 1;
		    }
		;
    break;}
case 604:
#line 6150 "parse.y"
{ yyerror(".ERR encountered"); yynerrs++;;
    break;}
case 605:
#line 6152 "parse.y"
{
		    yyerror(".ERR encountered: %s", yyvsp[0].string);
		    free(yyvsp[0].string);
		    yynerrs++;
		;
    break;}
case 606:
#line 6158 "parse.y"
{
		    if (*yyvsp[0].string == '\0') {
			yyerror(".ERRB: String blank");
			yynerrs++;
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 607:
#line 6166 "parse.y"
{
		    if (Sym_Find(yyvsp[0].ident, SYM_ANY, FALSE) != NULL) {
			yyerror(".ERRDEF: Symbol %i defined", yyvsp[0].ident);
			yynerrs++;
		    }
		;
    break;}
case 608:
#line 6173 "parse.y"
{
		    if (strcmp(yyvsp[-2].string, yyvsp[0].string) != 0) {
			yyerror(".ERRDIF: <%s> and <%s> differ",
				yyvsp[-2].string, yyvsp[0].string);
			yynerrs++;
		    }
		    free(yyvsp[-2].string); free(yyvsp[0].string);
		;
    break;}
case 609:
#line 6182 "parse.y"
{
		    if (yyvsp[0].number == 0) {
			yyerror(".ERRE: expression is zero");
			yynerrs++;
		    }
		;
    break;}
case 610:
#line 6189 "parse.y"
{
		    if (strcmp(yyvsp[-2].string, yyvsp[0].string) == 0) {
			yyerror(".ERRIDN: <%s> and <%s> are identical",
				yyvsp[-2].string, yyvsp[0].string);
			yynerrs++;
		    }
		    free(yyvsp[-2].string); free(yyvsp[0].string);
		;
    break;}
case 611:
#line 6198 "parse.y"
{
		    if (*yyvsp[0].string != '\0') {
			yyerror(".ERRNB: <%s> isn't blank",
				yyvsp[0].string);
			yynerrs++;
		    }
		    free(yyvsp[0].string);
		;
    break;}
case 612:
#line 6207 "parse.y"
{
		    if (Sym_Find(yyvsp[0].ident, SYM_ANY, FALSE) == NULL) {
			yyerror(".ERRNDEF: %i isn't defined", yyvsp[0].ident);
			yynerrs++;
		    }
		;
    break;}
case 613:
#line 6214 "parse.y"
{
		    if (yyvsp[0].number != 0) {
			yyerror(".ERRNZ: expression is non-zero");
			yynerrs++;
		    }
		;
    break;}
}
   /* the action file gets copied in in place of this dollarsign */
#line 543 "/usr/local/share/bison.simple"

  yyvsp -= yylen;
  yyssp -= yylen;
#ifdef YYLSP_NEEDED
  yylsp -= yylen;
#endif

#if YYDEBUG != 0
  if (yydebug)
    {
      short *ssp1 = yyss - 1;
      fprintf (stderr, "state stack now");
      while (ssp1 != yyssp)
	fprintf (stderr, " %d", *++ssp1);
      fprintf (stderr, "\n");
    }
#endif

  *++yyvsp = yyval;

#ifdef YYLSP_NEEDED
  yylsp++;
  if (yylen == 0)
    {
      yylsp->first_line = yylloc.first_line;
      yylsp->first_column = yylloc.first_column;
      yylsp->last_line = (yylsp-1)->last_line;
      yylsp->last_column = (yylsp-1)->last_column;
      yylsp->text = 0;
    }
  else
    {
      yylsp->last_line = (yylsp+yylen-1)->last_line;
      yylsp->last_column = (yylsp+yylen-1)->last_column;
    }
#endif

  /* Now "shift" the result of the reduction.
     Determine what state that goes to,
     based on the state we popped back to
     and the rule number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTBASE] + *yyssp;
  if (yystate >= 0 && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTBASE];

  goto yynewstate;

yyerrlab:   /* here on detecting error */

  if (! yyerrstatus)
    /* If not already recovering from an error, report this error.  */
    {
      ++yynerrs;

#ifdef YYERROR_VERBOSE
      yyn = yypact[yystate];

      if (yyn > YYFLAG && yyn < YYLAST)
	{
	  int size = 0;
	  char *msg;
	  int x, count;

	  count = 0;
	  /* Start X at -yyn if nec to avoid negative indexes in yycheck.  */
	  for (x = (yyn < 0 ? -yyn : 0);
	       x < (sizeof(yytname) / sizeof(char *)); x++)
	    if (yycheck[x + yyn] == x)
	      size += strlen(yytname[x]) + 15, count++;
	  msg = (char *) malloc(size + 15);
	  if (msg != 0)
	    {
	      strcpy(msg, "parse error");

	      if (count < 5)
		{
		  count = 0;
		  for (x = (yyn < 0 ? -yyn : 0);
		       x < (sizeof(yytname) / sizeof(char *)); x++)
		    if (yycheck[x + yyn] == x)
		      {
			strcat(msg, count == 0 ? ", expecting `" : " or `");
			strcat(msg, yytname[x]);
			strcat(msg, "'");
			count++;
		      }
		}
	      yyerror(msg);
	      free(msg);
	    }
	  else
	    yyerror ("parse error; also virtual memory exceeded");
	}
      else
#endif /* YYERROR_VERBOSE */
	yyerror("parse error");
    }

  goto yyerrlab1;
yyerrlab1:   /* here on error raised explicitly by an action */

  if (yyerrstatus == 3)
    {
      /* if just tried and failed to reuse lookahead token after an error, discard it.  */

      /* return failure if at end of input */
      if (yychar == YYEOF)
	YYABORT;

#if YYDEBUG != 0
      if (yydebug)
	fprintf(stderr, "Discarding token %d (%s).\n", yychar, yytname[yychar1]);
#endif

      yychar = YYEMPTY;
    }

  /* Else will try to reuse lookahead token
     after shifting the error token.  */

  yyerrstatus = 3;		/* Each real token shifted decrements this */

  goto yyerrhandle;

yyerrdefault:  /* current state does not do anything special for the error token. */

#if 0
  /* This is wrong; only states that explicitly want error tokens
     should shift them.  */
  yyn = yydefact[yystate];  /* If its default is to accept any token, ok.  Otherwise pop it.*/
  if (yyn) goto yydefault;
#endif

yyerrpop:   /* pop the current state because it cannot handle the error token */

  if (yyssp == yyss) YYABORT;
  yyvsp--;
  yystate = *--yyssp;
#ifdef YYLSP_NEEDED
  yylsp--;
#endif

#if YYDEBUG != 0
  if (yydebug)
    {
      short *ssp1 = yyss - 1;
      fprintf (stderr, "Error: state stack now");
      while (ssp1 != yyssp)
	fprintf (stderr, " %d", *++ssp1);
      fprintf (stderr, "\n");
    }
#endif

yyerrhandle:

  yyn = yypact[yystate];
  if (yyn == YYFLAG)
    goto yyerrdefault;

  yyn += YYTERROR;
  if (yyn < 0 || yyn > YYLAST || yycheck[yyn] != YYTERROR)
    goto yyerrdefault;

  yyn = yytable[yyn];
  if (yyn < 0)
    {
      if (yyn == YYFLAG)
	goto yyerrpop;
      yyn = -yyn;
      goto yyreduce;
    }
  else if (yyn == 0)
    goto yyerrpop;

  if (yyn == YYFINAL)
    YYACCEPT;

#if YYDEBUG != 0
  if (yydebug)
    fprintf(stderr, "Shifting error token, ");
#endif

  *++yyvsp = yylval;
#ifdef YYLSP_NEEDED
  *++yylsp = yylloc;
#endif

  yystate = yyn;
  goto yynewstate;

 yyacceptlab:
  /* YYACCEPT comes here.  */
  if (yyfree_stacks)
    {
      free ((malloc_t) yyss);
      free ((malloc_t) yyvs);
#ifdef YYLSP_NEEDED
      free (yyls);
#endif
    }
  return 0;

 yyabortlab:
  /* YYABORT comes here.  */
  if (yyfree_stacks)
    {
      free ((malloc_t) yyss);
      free ((malloc_t) yyvs);
#ifdef YYLSP_NEEDED
      free (yyls);
#endif
    }
  return 1;
}
#line 6221 "parse.y"



/***********************************************************************
 *				ParseStackOverflow
 ***********************************************************************
 * SYNOPSIS:	  Enlarge the parser's internal stacks.
 * CALLED BY:	  yyparse()
 * RETURN:	  Nothing. *maxDepth left unaltered if we don't want to
 *		  allow the increase. yyerror is called with msg if so.
 * SIDE EFFECTS:
 *
 * STRATEGY:	  This implementation relies on the "errcheck" rule
 *		  freeing stacks up, if necessary. Sadly, there's no
 *		  opportunity to do this, so it be a core leak...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/31/88		Initial Revision
 *
 ***********************************************************************/
static void
ParseStackOverflow(char		*msg,	    /* Message if we decide not to */
		   short	**state,    /* Current state stack */
		   size_t	stateSize,  /* Current state stack size */
		   YYSTYPE	**vals,	    /* Current value stack */
		   size_t	valsSize,   /* Current value stack size */
		   int		*maxDepth)  /* Current maximum stack depth of
					     * all stacks */
{
    *maxDepth *= 2;

    if (malloc_size((malloc_t) *state) != 0) {
	/*
	 * we've been called before. Just use realloc()
	 */
	*state = (short *)realloc_tagged((char *)*state, stateSize * 2);
	*vals = (YYSTYPE *)realloc_tagged((char *)*vals, valsSize * 2);
    } else {
	short	*newstate;
	YYSTYPE	*newvals;

	newstate = (short *)malloc_tagged(stateSize * 2,
					  TAG_PARSER_STACK);
	newvals = (YYSTYPE *)malloc_tagged(valsSize * 2,
					   TAG_PARSER_STACK);

	bcopy(*state, newstate, stateSize);
	bcopy(*vals, newvals, valsSize);

	*state = newstate;
	*vals = newvals;
    }
}

/***********************************************************************
 *				yyerror
 ***********************************************************************
 * SYNOPSIS:	  Print an error message with the current line #
 * CALLED BY:	  yyparse() and others
 * RETURN:	  Nothing
 * SIDE EFFECTS:  A message be printed. 'errors' is incremented
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/31/88		Initial Revision
 *
 ***********************************************************************/
/*VARARGS1*/
void
yyerror(char *fmt, ...)
{
    va_list	args;

    va_start(args, fmt);

    NotifyInt(NOTIFY_ERROR, curFile->name, yylineno, fmt, args);

    va_end(args);
}


/***********************************************************************
 *				FilterGenerated
 ***********************************************************************
 * SYNOPSIS:	    Filter out any generated symbols now.
 * CALLED BY:	    DefineData, various rules
 * RETURN:	    Nothing
 * SIDE EFFECTS:    If the symbol's name begins with two question marks,
 *	    	    its NOWRITE flag is set.
 *
 * STRATEGY:
 *     	Any symbol that begins with two question marks is understood to be
 *     	generated and hence of no interest to the programmer, so it doesn't
 *     	get written to the object file.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/19/90		Initial Revision
 *
 ***********************************************************************/
static void
FilterGenerated(SymbolPtr   sym)
{
    if (sym != NULL && sym->name != NullID) {
	char 	*name = ST_Lock(output, sym->name);

	if ((*name == '?') && (name[1] == '?')) {
	    sym->flags |= SYM_NOWRITE;
	}
	ST_Unlock(output, sym->name);
    }
}

/***********************************************************************
 *				yywarning
 ***********************************************************************
 * SYNOPSIS:	  Print a warning message with the current line #
 * CALLED BY:	  yyparse() and others
 * RETURN:	  Nothing
 * SIDE EFFECTS:  A message be printed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/31/88		Initial Revision
 *
 ***********************************************************************/
/*VARARGS1*/
void
yywarning(char *fmt, ...)
{
    va_list	args;

    va_start(args, fmt);

    NotifyInt(NOTIFY_WARNING, curFile->name, yylineno, fmt, args);

    va_end(args);
}

/***********************************************************************
 *				EnterClass
 ***********************************************************************
 * SYNOPSIS:	    Deal with things required on entry to a class,
 *	    	    either the declaration of one or the definition
 *	    	    of a method handler for one.
 * CALLED BY:	    yyparse in various rules
 * RETURN:	    nothing
 * SIDE EFFECTS:    curClass is set, the @CurClass string altered
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/22/89	Initial Revision
 *
 ***********************************************************************/
static void
EnterClass(SymbolPtr	class)
{
    char    	*name;

    curClass = class;

    /*
     * Set the @CurClass equate to match the current procedure name.
     */
    name = ST_Lock(output, curClass->name);
    predefs[PD_CURCLASS].value->length = strlen(name);
    bcopy(name,
	  predefs[PD_CURCLASS].value->text,
	  predefs[PD_CURCLASS].value->length);
    ST_Unlock(output, curClass->name);
}

/***********************************************************************
 *				EndClass
 ***********************************************************************
 * SYNOPSIS:	    Finish out things in the current class
 * CALLED BY:	    EndProc and yyparse.
 * RETURN:	    Nothing
 * SIDE EFFECTS:    @CurClass is emptied, curClass is zeroed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/22/89	Initial Revision
 *
 ***********************************************************************/
static void
EndClass(void)
{
    curClass = NULL;

    predefs[PD_CURCLASS].value->length = 0;
}


/***********************************************************************
 *				EnterProc
 ***********************************************************************
 * SYNOPSIS:	    Start a new procedure
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    all symbols in the locals list have their procedure
 *	    	    pointer altered to the one being entered.
 *	    	    curProc is set to the passed procedure.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/11/89		Initial Revision
 *
 ***********************************************************************/
static void
EnterProc(SymbolPtr proc)
{
    char    *name;
    int	    i;

    curSeg->u.segment.data->lastLabel = dot;
    curSeg->u.segment.data->checkLabel = FALSE;

    /*
     * Bitch if procedure is nested.
     */
    if (curProc) {
	yyerror("procedure %i may not nest inside procedure %i",
		proc->name, curProc->name);
    } else if (proc->type == SYM_PROC) {
	curProc = proc;

	/*
	 * Set the @CurProc equate to match the current procedure name.
	 */
	name = ST_Lock(output, curProc->name);
	predefs[PD_CURPROC].value->length = strlen(name);
	bcopy(name,
	      predefs[PD_CURPROC].value->text,
	      predefs[PD_CURPROC].value->length);
	ST_Unlock(output, curProc->name);

	/*
	 * Set the curProc field for the temporary expressions.
	 */
	for (i = NumElts(exprs)-1; i >= 0; i--) {
	    exprs[i]->curProc = curProc;
	}

	/*
	 * Set the initial argument offset.
	 */
	if (Sym_IsNear(curProc)) {
	    argOffset = 4;	/* saved BP + 2-byte ret addr */
	} else {
	    argOffset = 6;  	/* saved BP + 4-byte ret addr */
	}
    }
}

/***********************************************************************
 *				EndProc
 ***********************************************************************
 * SYNOPSIS:	    Finish out a procedure
 * CALLED BY:	    yyparse (ENDM and ENDP rules)
 * RETURN:	    Nothing
 * SIDE EFFECTS:    curProc, curClass set to NULL, localOffset, usesMask,
 *	    	    and enterSeen set to 0.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/23/89		Initial Revision
 *
 ***********************************************************************/
static void
EndProc(ID	name)
{
    int	    i;

    if (!enterSeen && enterNeeded) {
	if (localSize) {
	    yywarning("local variables declared for %i but no .ENTER given",
		      name);
	}
	if (usesMask) {
	    yywarning("USES given for %i, but no .ENTER", name);
	}
	if (!localSize && !usesMask) {
	    yywarning("arguments declared for %i but no .ENTER given",
		      name);
	}
    } else if (enterSeen && !leaveSeen) {
	yywarning(".ENTER given for %i, but no .LEAVE in sight", name);
    }

    if (warn_fall_thru && !curSeg->u.segment.data->checkLabel && !fall_thru) {
	yywarning("execution falls out of %i with no .FALL_THRU in sight",
		  name);
    }

    curProc = NULL;
    EndClass();
    frameSize = localSize = 0;
    usesMask = 0;
    fall_thru = frameSetup = frameNeeded = enterNeeded = leaveSeen =
	enterSeen = FALSE;

    for (i = NumElts(exprs)-1; i >= 0; i--) {
	exprs[i]->curProc = NULL;
    }

    /*
     * Zero out the @CurProc predef quickly.
     */
    predefs[PD_CURPROC].value->length = 0;
    predefs[PD_ARGSIZE].value->length = 0;

    curSeg->u.segment.data->checkLabel = TRUE;
}


/***********************************************************************
 *				AddArg
 ***********************************************************************
 * SYNOPSIS:	    Add another argument to the current procedure
 * CALLED BY:	    yyparse for any of four argument rules
 * RETURN:	    Nothing
 * SIDE EFFECTS:    @ArgSize is adjusted, argOffset is adjusted
 *
 * STRATEGY:
 *	    If symbol name given, create a LOCAL symbol with the current
 *	    argOffset as its offset.
 *
 *	    Adjust argOffset by the size of the type given for the arg and
 *	    set @ArgSize to match.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 8/89	Initial Revision
 *
 ***********************************************************************/
static void
AddArg(ID   	name,	    /* Argument name */
       TypePtr	type)	    /* Argument type */
{
    int		  size = Type_Size(type);
    int		  argBase = Sym_IsNear(curProc) ? 4 : 6;

    if (language != LANG_C) {
	/*
	 * If arguments pushed in left-to-right order, we need to shift the
	 * existing arguments up by the size of this argument.
	 */
	Sym_AdjustArgOffset(curProc, size);

	if (name != NullID) {
	    /*
	     * Make this arg the first one.
	     * XXX: should be able to use just argOffset, but then we'd need
	     * something else to track the argument size. This seems
	     * easier for now. Besides, we were needing to check
	     * Sym_IsNear(curProc) to set @ArgSize anyway...
	     */
	    (void)Sym_Enter(name, SYM_LOCAL, argBase, type, curProc);
	    frameNeeded = enterNeeded = TRUE;
	}
    } else if (name != NullID) {
	(void)Sym_Enter(name, SYM_LOCAL, argOffset, type, curProc);
    	frameNeeded = enterNeeded = TRUE;
    }

    argOffset += size;

    sprintf(predefs[PD_ARGSIZE].value->text, "%d", argOffset - argBase);
    predefs[PD_ARGSIZE].value->length = strlen(predefs[PD_ARGSIZE].value->text);

    curProc->u.proc.flags |= SYM_NO_JMP;
}


/***********************************************************************
 *				CheckAndSetLabel
 ***********************************************************************
 * SYNOPSIS:	    Make sure a label/proc isn't being multiply defined
 *	    	    and set its data properly.
 * CALLED BY:	    yyparse (label and labeled_op rules)
 * RETURN:	    Nothing
 * SIDE EFFECTS:    error messages, altered states...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/27/89		Initial Revision
 *
 ***********************************************************************/
static void
CheckAndSetLabel(SymType    type,	    /* Symbol type */
		 Symbol	    *sym,	    /* Symbol to check */
		 int	    near)	    /* TRUE if near label */
{
    if (curSeg == NULL || curSeg->u.segment.data->comb == SEG_GLOBAL) {
	yyerror("%s %i is not in any segment",
		type == SYM_LABEL ? "label" : "procedure", sym->name);
    } else if ((sym->segment != curSeg) && (sym->segment->name != NullID)) {
	yyerror("%i is declared in segment %i, defined in %i",
		sym->name, sym->segment->name, curSeg->name);
	if (sym->type == type) {
	    goto def_sym;	/* Define it anyway to avoid later errors */
	}
    } else if (((sym->flags & SYM_UNDEF) &&
		((sym->type != type) &&
		 (sym->type != (type == SYM_LABEL ? SYM_PROC : SYM_LABEL)))) ||
	       (!(sym->flags & SYM_UNDEF) && (sym->type != type)))
    {
	/*
	 * Undefined and not either a label or a procedure, or defined and
	 * not of the given type -- choke. (XXX: Give line/file of previous
	 * definition?). Do *not* define the thing anyway. In the case of
	 * a procedure, we will be expecting the proc.locals field to contain
	 * something meaningful, which it won't.
	 */
	yyerror("%i is already defined as something other than a %s",
		sym->name, type == SYM_LABEL ? "label" : "procedure");
    } else if (!(sym->flags & SYM_UNDEF)) {
	yyerror("%i multiply defined", sym->name);
    } else if (Sym_IsNear(sym) ? !near : near) {
	yyerror(near ? "near %s %i previously declared far" :
		"far %s %i previously declared near",
		type == SYM_LABEL ? "label" : "procedure",
		sym->name);
	goto def_sym;		/* Define it anyway to avoid later errors */
    } else {
def_sym:
	/* Set segment, to deal with declaration in global segment */
	sym->segment = curSeg;
	sym->type = type;	/* Make sure it's the correct type... */
	sym->flags &= ~SYM_UNDEF;
	if (sym->type == SYM_LABEL) {
	    sym->u.label.unreach = curSeg->u.segment.data->checkLabel;
	}

	Sym_SetAddress(sym, dot);
	curSeg->u.segment.data->lastLabel = dot;
    }
}


/***********************************************************************
 *				DefineData
 ***********************************************************************
 * SYNOPSIS:	    Define a data element by name
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Lots
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/30/89		Initial Revision
 *
 ***********************************************************************/
static void
DefineData(ID	    name,  	/* Name of symbol to define */
	   TypePtr  type,   	/* Type of data */
	   int      advance,	/* TRUE if should enter curExpr and advance
				 * dot */
	   int	    usebase)	/* TRUE if the type is an array put together
				 * by the parser, as opposed to a real
				 * array typedef. Tells us to pass the base
				 * type and length to Data_Enter separately */
{
    SymbolPtr	sym;

    if (curSeg == NULL || curSeg->u.segment.data->comb == SYM_GLOBAL) {
	yyerror("%i is not in any segment", name);
    }

    if (type->tn_type == TYPE_NEAR || type->tn_type == TYPE_FAR) {
	yyerror("why are you defining a code label with data?");
	return;
    } else if (inStruct) {
	/*
	 * Defining a structure -- create a field with curExpr as its
	 * default value.
	 *
	 * NOTE: The test for inStruct MUST come before that for
	 * curClass && defClass to allow class-related structures to be
	 * defined w/in a class declaration.
	 */
	Expr	*expr;

	if (advance) {
	    expr = CopyExprCheckingIfZero(curExpr);
	} else {
	    expr = NULL;
	}
	sym = Sym_Enter(name, SYM_FIELD, inStruct, type, expr);
    } else if (curClass && defClass) {
	/*
	 * Defining a class -- create an instance variable with curExpr as
	 * its default value.
	 */
	Expr	*expr;

	if (advance) {
	    /*
	     * If default value for field is a zero constant, use the static
	     * zeroExpr, rather than allocating a whole new expression that
	     * means the same thing...
	     */
	    expr = CopyExprCheckingIfZero(curExpr);
	} else {
	    expr = NULL;
	}
	sym = Sym_Enter(name, SYM_INSTVAR, curClass, type, expr,
			isPublic);
    } else {
	/*
	 * Defining a regular variable.
	 */
	sym = Sym_Enter(name, SYM_VAR, dot, type);

	if (advance) {
	    /*
	     * Enter the data definition if not just a label. May need to
	     * copy the curExpr in case of recursive parser call.
	     */
	    int	    	maxElts = 0;	/* As many as needed... */

	    if (usebase) {
		maxElts = type->tn_u.tn_array.tn_length;
		type = type->tn_u.tn_array.tn_base;
	    }

	    switch(type->tn_type) {
		case TYPE_STRUCT:
		case TYPE_ARRAY:
		{
		    /*
		     * These are things that could cause the parser to be
		     * called recursively, so we need to duplicate the
		     * current expression before trying to enter the data.
		     */
		    Expr	*expr = Expr_Copy(curExpr, TRUE);
		    Data_Enter(&dot, type, expr, maxElts);
		    Expr_Free(expr);
		    break;
		}
		default:
		    Data_Enter(&dot, type, curExpr, 0);
		    break;
	    }
	}
    }
    FilterGenerated(sym);
}


/***********************************************************************
 *				DefineDataSym
 ***********************************************************************
 * SYNOPSIS:	    Define the data for a symbol
 * CALLED BY:	    DefineData, yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Lots
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/30/89		Initial Revision
 *
 ***********************************************************************/
static void
DefineDataSym(SymbolPtr	    sym,    	/* Symbol for which to define data */
	      TypePtr	    type,   	/* Type of data being defined */
	      int	    advance,	/* TRUE if should enter curExpr
					 * and advance dot */
	      int	    usebase)	/* TRUE if the type is an array put
					 * together by the parser, as opposed
					 * to a real array typedef. Tells us
					 * to pass the base type and length to
					 * Data_Enter separately */
{
    if ((sym->flags & SYM_UNDEF) == 0) {
	yyerror("%i already defined", sym->name);
    } else if (sym->type != SYM_VAR) {
	/*
	 * Since we're defining data here, this thing should have been declared
	 * as a variable.
	 */
	yyerror("declaration mismatch (should be variable)");
	goto def_sym;		/* Define it anyway to avoid later errors */
    } else if ((sym->segment != curSeg) && (sym->segment->name != NullID)) {
	yyerror("%i is declared in segment %i, defined in %i", sym->name,
		sym->segment->name, curSeg->name);
	goto def_sym;		/* Define it anyway to avoid later errors */
    } else if (!Type_Equal(sym->u.var.type, type) &&
	       (!usebase ||
		!Type_Equal(sym->u.var.type, type->tn_u.tn_array.tn_base)))
    {
	/*
	 * Type didn't match previous declaration. Note comparison with
	 * element type of array if usebase true. This allows indeterminate
	 * definitions (e.g. geosStr db "geosec.exe",0) to be declared
	 * global with just their base type (e.g. global geosStr:byte)
	 */
	yyerror("declaration mismatch (different data types)");
	goto def_sym;		/* Define it anyway to avoid later errors */
    } else if (inStruct) {
	/*
	 * Defining a structure -- need to convert the VAR to a FIELD and
	 * link it in...
	 *
	 * NOTE: The test for inStruct MUST come before that for
	 * curClass && defClass to allow class-related structures to be
	 * defined w/in a class declaration.
	 */
	Expr	*expr;

	if (advance) {
	    expr = CopyExprCheckingIfZero(curExpr);
	} else {
	    expr = NULL;
	}
	Sym_Enter(sym->name, SYM_FIELD, inStruct, type, expr);
    } else if (curClass && defClass) {
	/*
	 * Defining a class -- convert the VAR to an INSTVAR and link it
	 * into the instance structure.
	 */
	Expr	*expr;

	if (advance) {
	    /*
	     * If default value for field is a zero constant, use the static
	     * zeroExpr, rather than allocating a whole new expression that
	     * means the same thing...
	     */
	    expr = CopyExprCheckingIfZero(curExpr);
	} else {
	    expr = NULL;
	}
	Sym_Enter(sym->name, SYM_INSTVAR, curClass, type, expr, isPublic);
    } else {
	/*
	 * Just a regular variable definition -- set the addrsym.offset and
	 * deal with the data...
	 */
def_sym:
	/* Set segment, to deal with declaration in global segment */
	sym->segment = curSeg;

	/* Set type to handle global definition as pointer to void, which will
	 * match actual pointer definition */
	sym->u.var.type = type;

	sym->flags &= ~SYM_UNDEF;

	Sym_SetAddress(sym, dot);

	if (advance) {
	    /*
	     * Enter the data definition if not just a label. May need to
	     * copy the curExpr in case of recursive parser call.
	     */
	    int	    	maxElts = 0;	/* As many as needed... */

	    if (usebase) {
		maxElts = type->tn_u.tn_array.tn_length;
		type = type->tn_u.tn_array.tn_base;
	    }

	    switch(type->tn_type) {
		case TYPE_STRUCT:
		case TYPE_ARRAY:
		{
		    /*
		     * These are things that could cause the parser to be
		     * called recursively, so we need to duplicate the
		     * current expression before trying to enter the data.
		     */
		    Expr	*expr = Expr_Copy(curExpr, TRUE);
		    Data_Enter(&dot, type, expr, maxElts);
		    Expr_Free(expr);
		    break;
		}
		default:
		    Data_Enter(&dot, type, curExpr, 0);
		    break;
	    }
	}
    }
}


/***********************************************************************
 *				Parse_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize parser state.
 * CALLED BY:	    main
 * RETURN:	    nothing
 * SIDE EFFECTS:    curSeg is set and the predefined STRING symbols
 *	    	    are created.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/89		Initial Revision
 *
 ***********************************************************************/
void
Parse_Init(SymbolPtr	global)
{
    int	    i;
    char    *name;
    char    *cp;

    /*
     * Set the initial segment
     */
    curSeg = global;

    /*
     * Allocate a 256-byte MBlk record for each predefined string symbol,
     * then enter the symbol into the table.
     */
    for (i = NumElts(predefs)-1; i >= 0; i--) {
	ID	    id;

	predefs[i].value = (MBlk *)malloc(sizeof(MBlk)+PD_VAL_LEN);
	predefs[i].value->length = 0;
	predefs[i].value->dynamic = TRUE;
	predefs[i].value->next = NULL;

	id = ST_EnterNoLen(output, symStrings, predefs[i].name);
	(void)Sym_Enter(id, SYM_STRING, predefs[i].value);
    }

    /*
     * Setup the initial @Cpu...
     */
    sprintf(predefs[PD_CPU].value->text, "0%04xh", procType);
    predefs[PD_CPU].value->length = strlen(predefs[PD_CPU].value->text);

    /*
     * The @FileName gets set to the base of the first file.
     */
    name = ST_Lock(output, curFile->name);
    /*
     * Point CP at the final component.
     */
    cp = rindex(name, PATHNAME_SLASH);
    if (cp++ == NULL) {
	cp = name;
    }
    /*
     * Copy the final component in.
     */
    predefs[PD_FILENAME].value->length = strlen(cp);
    bcopy(cp,
	  predefs[PD_FILENAME].value->text,
	  predefs[PD_FILENAME].value->length);
    /*
     * See if there's a suffix on the thing.
     */
    cp = rindex(cp, '.');
    if (cp != NULL) {
	/*
	 * Yup -- remove the length of the suffix from the length of the
	 * equate.
	 */
	predefs[PD_FILENAME].value->length -= strlen(cp);
    }
    ST_Unlock(output, curFile->name);

    curFile->iflevel = iflevel;
    curFile->chunk = NULL;

    Parse_FileChange(TRUE);

    ResetExpr(&zeroExpr, zeroElts);
    StoreExprConst(0);
    StoreExprComma();
}


/***********************************************************************
 *				Parse_DefineString
 ***********************************************************************
 * SYNOPSIS:	    Define a string equate
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    A SYM_STRING symbol is entered into the current
 *	    	    scope (which should be global).
 *
 * STRATEGY:	    Not much. Allocates a single MBlk to hold the value,
 *	    	    maps the name to an ID and enters the combination
 *	    	    into the symbol table.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/15/89	Initial Revision
 *
 ***********************************************************************/
void
Parse_DefineString(char	    *name,
		   char	    *value)
{
    ID	    	  id = ST_EnterNoLen(output, symStrings, name);
    MBlk    	  *block;
    int	    	  vlen = strlen(value);
    SymbolPtr	  sym;

    sym = Sym_Find(id, SYM_STRING, FALSE);

    block = (MBlk *)malloc(sizeof(MArg) + vlen);
    block->next = NULL;
    block->length = vlen;
    block->dynamic = TRUE;
    bcopy(value, block->text, vlen);

    if (sym != NULL) {
	if (sym->type != SYM_STRING) {
	    yyerror("cannot redefine %i as a string equate", id);
	    free((malloc_t)block);
	} else {
	    MBlk    *mp, *next;

	    for (mp = sym->u.string.value; mp != NULL; mp = next) {
		next = mp->next;
		if (mp->dynamic) {
		    free((malloc_t)mp);
		}
	    }
	    sym->u.string.value = block;
	}
    } else {
	Sym_Enter(id, SYM_STRING, block);
    }
}


/***********************************************************************
 *				Parse_CheckClosure
 ***********************************************************************
 * SYNOPSIS:	    Make sure no important things are being left open
 * CALLED BY:	    Parse_Complete, PopSegment, yystdwrap
 * RETURN:	    non-zero if chunk was closed. This is used by
 *	    	    PopSegment to deal with recursive call by LMem_EndChunk
 * SIDE EFFECTS:    An error may be generated.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/27/89	Initial Revision
 *
 ***********************************************************************/
int
Parse_CheckClosure(int *okPtr,
		   int	checkSegStack)
{
    int		  retval = 0;

    *okPtr = 1;			/* Assume user not a bozo */

    /*
     * Always close the current protominor thing, without generating a warning.
     */
    curProtoMinor = NullSymbol;

    /*
     * Make sure things aren't being left open/unresolved...
     */
    if (curProc != NULL) {
	if (curClass != NULL) {
	    Notify(NOTIFY_ERROR, curFile->name, -1,
		   "Method %i missing ENDM", curProc->name);
	    *okPtr = 0;
	} else {
	     Notify(NOTIFY_ERROR, curFile->name, -1,
		    "Procedure %i missing ENDP", curProc->name);
	     *okPtr = 0;
	 }
    } else if (curClass != NULL) {
	Notify(NOTIFY_ERROR, curFile->name, -1,
	       "Class declaration for %i missing ENDC", curClass->name);
	*okPtr = 0;
    } else if (!checkSegStack && curChunk != NULL) {
	/*
	 * Code executed on the closing of a segment.
	 */
	SymbolPtr   chunk = curChunk;

	Notify(NOTIFY_ERROR, curFile->name, -1,
	       "Chunk %i missing ENDC", curChunk->name);
	*okPtr = 0;
	curChunk = NULL;
	LMem_EndChunk(chunk);
	ParseLocalizationCheck();
	/*
	 * Signal potential recursion.
	 */
	return(1);
    } else if (inStruct != NULL) {
	if (inStruct->type == SYM_STRUCT) {
	    Notify(NOTIFY_ERROR, curFile->name, -1,
		   "Structure definition for %i missing ENDS", inStruct->name);
	} else {
	    Notify(NOTIFY_ERROR, curFile->name, -1,
		   "Union definition for %i missing END", inStruct->name);
	}
	*okPtr = 0;
    } else if (usesMask) {
	Notify(NOTIFY_ERROR, curFile->name, -1,
	       "USES given without procedure");
	*okPtr = 0;
    }

    /*
     * Code executed on the closing of a file.
     */
    if (checkSegStack) {
	/*
	 * Chunk needn't be closed as long as it's the one that
	 * was open when the file was entered.
	 */
	if (curChunk != curFile->chunk && curChunk != NULL) {
	    SymbolPtr	chunk = curChunk;

	    Notify(NOTIFY_ERROR, curFile->name, -1,
		   "Chunk %i missing ENDC", curChunk->name);
	    curChunk = NULL;
	    LMem_EndChunk(chunk);
	    ParseLocalizationCheck();
	    retval = 1;
	    *okPtr = 0;
	}

	/*
	 * Now any chunk is closed, make sure all segments are closed.
	 */
	if (segStack != curFile->segstack) {
	    SegStack    *seg;

	    Notify(NOTIFY_ERROR, curFile->name, -1,
		   "Open segments:\n\t%i", curSeg->name);
	    for (seg = segStack; seg != curFile->segstack; seg = seg->next) {
		fprintf(stderr, "\t%i\n", seg->seg->name);
	    }
	    retval = 1;
	    *okPtr = 0;
	}
    }

    return(retval);
}

/***********************************************************************
 *				Parse_Complete
 ***********************************************************************
 * SYNOPSIS:	    Parsing is complete -- make sure no important things
 *	    	    are left open.
 * CALLED BY:	    main
 * RETURN:	    0 on error
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/15/89		Initial Revision
 *
 ***********************************************************************/
int
Parse_Complete(void)
{
    int	    retval;

    Parse_CheckClosure(&retval, TRUE);
    return(retval);
}

/***********************************************************************
 *				Parse_FileChange
 ***********************************************************************
 * SYNOPSIS:	    Note another change in files.
 * CALLED BY:	    ScanInclude
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The value for the @File equate is changed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/27/89	Initial Revision
 *
 ***********************************************************************/
void
Parse_FileChange(int entry)
{
    char    	*file = ST_Lock(output, curFile->name);
    int	    	vlen = strlen(file);
    MBlk    	*mp, *mpNext;

    for (mp = predefs[PD_FILE].value->next;
	 mp != NULL;
	 mp = mpNext)
    {
	mpNext = mp->next;
	free((char *)mp);
    }
    for (mp = predefs[PD_FILE].value;
	 vlen > 0;
	 mp = mp->next)
    {
	int 	n = vlen;

	if (n > PD_VAL_LEN) {
	    n = PD_VAL_LEN;
	}
	bcopy(file, mp->text, n);
	mp->dynamic = TRUE;
	mp->length = n;
	vlen -= n;
	file += n;

	if (vlen > 0) {
	    mp->next = (MBlk *)malloc(sizeof(MArg)+PD_VAL_LEN);
	} else {
	    break;
	}
    }
    mp->next = NULL;

    ST_Unlock(output, curFile->name);

    /*
     * Record segment stack level on entry to the file.
     */
    if (entry) {
	curFile->segstack = segStack;
    }
}


/***********************************************************************
 *				PushSegment
 ***********************************************************************
 * SYNOPSIS:	    Save the current state and switch to a new segment
 *	    	    with the default state set up.
 * CALLED BY:	    Lots o' things
 * RETURN:	    Nothing
 * SIDE EFFECTS:    segStack is altered.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/89		Initial Revision
 *
 ***********************************************************************/
void
PushSegment(SymbolPtr	sym)
{
    SegStack	*seg;
    char    	*name;
    int	    	i;
    SymbolPtr	newCS;

    seg = (SegStack *)malloc(sizeof(SegStack));
    seg->next =     	segStack;
    seg->seg =	    	curSeg;
    seg->inStruct = 	inStruct;
    seg->curProc =  	curProc;
    seg->localSize =	localSize;
    seg->frameSize =	frameSize;
    seg->usesMask = 	usesMask;
    seg->enterNeeded =	enterNeeded;
    seg->enterSeen =	enterSeen;
    seg->leaveSeen =	leaveSeen;
    seg->frameNeeded =	frameNeeded;
    seg->frameSetup = 	frameSetup;
    seg->fall_thru =	fall_thru;
    seg->curChunk = 	curChunk;
    seg->curClass = 	curClass;
    seg->defClass = 	defClass;
    seg->isPublic = 	isPublic;
    seg->classProc =	classProc;

    segStack = seg;
    curSeg->u.segment.data->lastdot = dot;

    curSeg = 	    	sym;
    dot =   	    	sym->u.segment.data->lastdot;
    inStruct =	    	(SymbolPtr)NULL;
    curProc =	    	(SymbolPtr)NULL;
    localSize =	    	0;
    frameSize =	    	0;
    usesMask =	    	0;
    enterNeeded =   	FALSE;
    enterSeen =	    	FALSE;
    leaveSeen =	    	FALSE;
    frameNeeded =   	FALSE;
    frameSetup =    	FALSE;
    curChunk =	    	(SymbolPtr)NULL;
    defClass =	    	FALSE;
    isPublic =	    	FALSE;

    EndClass();

    /*
     * Shut off class tokens if they were on before.
     */
    if (classProc != -1) {
	Scan_DontUseOpProc(classProc);
    }
    classProc =	    	-1;

    if (sym->name != NullID) {
	name = ST_Lock(output, sym->name);
    } else {
	name = "(null)";
    }

    predefs[PD_CURSEG].value->length = strlen(name);
    bcopy(name,
	  predefs[PD_CURSEG].value->text,
	  predefs[PD_CURSEG].value->length);
    ST_Unlock(output, sym->name);

    /*
     * Bind CS to the new segment or its group, if it's in one. This
     * makes sure that if someone uses a cs: override for something
     * not in the current segment, s/he will get an error message from
     * glue. If the current segment contains only data, the user shouldn't
     * be using a cs: override. If it contains code, cs: has to be pointing
     * to the segment or the group (this is the way we do things here).
     */
    newCS = curSeg;
    if (newCS->segment && newCS->segment->type == SYM_GROUP) {
	newCS = newCS->segment;
    }
    for (i = NumElts(exprs)-1; i >= 0; i--) {
	exprs[i]->segments[REG_CS] = newCS;
    }
}

/***********************************************************************
 *				PopSegment
 ***********************************************************************
 * SYNOPSIS:	    Go back to the previously-saved segment
 * CALLED BY:	    External
 * RETURN:	    Nothing
 * SIDE EFFECTS:    All the parser state variables are changed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/89		Initial Revision
 *
 ***********************************************************************/
void
PopSegment(void)
{
    SegStack	*seg;
    char    	*name;
    int	    	junk;
    int		i;
    SymbolPtr	newCS;


    /*
     * Record final location counter for later entry
     */
    curSeg->u.segment.data->lastdot = dot;

    if (Parse_CheckClosure(&junk, FALSE)) {
	/*
	 * Recursed -- get ooout
	 */
	return;
    }

    seg = segStack;

    curSeg =	    seg->seg;
    inStruct = 	    seg->inStruct;
    curProc =  	    seg->curProc;
    localSize =	    seg->localSize;
    frameSize =	    seg->frameSize;
    usesMask = 	    seg->usesMask;
    enterNeeded =   seg->enterNeeded;
    enterSeen =	    seg->enterSeen;
    leaveSeen =	    seg->leaveSeen;
    frameNeeded =   seg->frameNeeded;
    frameSetup =    seg->frameSetup;
    fall_thru =	    seg->fall_thru;
    curChunk = 	    seg->curChunk;
    defClass = 	    seg->defClass;
    isPublic = 	    seg->isPublic;

    if (seg->curClass) {
	EnterClass(seg->curClass);
    } else {
	EndClass();
    }

    /*
     * Turn the class tokens back on if they were on in the segment
     */
    classProc =	    seg->classProc;
    if (classProc != -1) {
	classProc = Scan_UseOpProc(findClassToken);
    }

    /*
     * Set the location counter back to wherever it was when last we left
     * this segment -- this makes the object method table creation a bit
     * easier, since it can just push to the class's segment, insert stuff,
     * then adjust dot if it's in the way and we will take care of things as
     * necessary.
     */
    dot =	    curSeg->u.segment.data->lastdot;

    /*
     * Pop and free the record.
     */
    segStack = seg->next;
    free((char *)seg);

    /*
     * Fix up the @CurSeg equate.
     */
    if (curSeg->name != NullID) {
	name = ST_Lock(output, curSeg->name);

	predefs[PD_CURSEG].value->length = strlen(name);
	bcopy(name,
	      predefs[PD_CURSEG].value->text,
	      predefs[PD_CURSEG].value->length);
	ST_Unlock(output, curSeg->name);
    } else {
	/*
	 * Data can't be entered into the global segment, so no need to worry
	 * about leaving the previous one as the current resource for
	 * localization info
	 */
	predefs[PD_CURSEG].value->length = 0;
    }
    /*
     * Bind CS to the new segment or its group, if it's in one. This
     * makes sure that if someone uses a cs: override for something
     * not in the current segment, s/he will get an error message from
     * glue. If the current segment contains only data, the user shouldn't
     * be using a cs: override. If it contains code, cs: has to be pointing
     * to the segment or the group (this is the way we do things here).
     */
    newCS = curSeg;
    if (newCS->segment && newCS->segment->type == SYM_GROUP) {
	newCS = newCS->segment;
    }
    for (i = NumElts(exprs)-1; i >= 0; i--) {
	exprs[i]->segments[REG_CS] = newCS;
    }
}


/***********************************************************************
 *				HandleIF
 ***********************************************************************
 * SYNOPSIS:	    Deal with the start of a conditional. curExpr contains
 *	    	    an expression to be evaluated if necessary to
 *	    	    decide if the conditional code is to be assembled.
 *	    	    If the result is a non-zero constant, the conditional
 *	    	    is taken.
 * CALLED BY:	    parser for all IF and ELSEIF tokens
 * RETURN:	    Nothing
 * SIDE EFFECTS:    iflevel is altered. Scan_ToEndif may be called.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/89		Initial Revision
 *
 ***********************************************************************/
static void
HandleIF(int	isElse)	    /* Non-zero if token was ELSEIF */
{
    ExprResult	result;

    if (isElse) {
	/*
	 * ELSEIF: if no nested ifs, bitch. Else, if last
	 * if was TRUE, switch to FALSE and skip to the endif.
	 */
	if (iflevel == -1) {
	    yyerror("IF-less ELSEIF");
	} else if (ifStack[iflevel].value) {
	    /*
	     * Prev was TRUE -- skip to end of conditional without evaluating
	     * expression (this is important)
	     */
	    ifStack[iflevel].value = 0;
	    Scan_ToEndif(FALSE);
	} else {
	    int	    cond;

	    if (!Expr_Eval(curExpr, &result, EXPR_NOUNDEF|EXPR_FINALIZE, NULL))
	    {
		yyerror((char *)result.type);
		cond = 0;	/* Don't take the conditional */
	    } else if (result.type == EXPR_TYPE_CONST) {
		cond = result.data.number;
	    } else {
		yyerror("condition must be a numeric constant");
		cond = 0;
	    }
	    if (cond) {
		/*
		 * Prev was FALSE, this is TRUE -- continue parsing
		 */
		ifStack[iflevel].value = 1;
	    } else {
		/*
		 * Prev was FALSE, this is FALSE -- skip to
		 * ENDIF, ELSE or another ELSEIF.
		 */
		Scan_ToEndif(TRUE);
	    }
	}
    } else if (iflevel == MAX_IF_LEVEL) {
	yyerror("Too many nested IF's (%d max)", MAX_IF_LEVEL);
    } else {
	int	    cond;

	if (!Expr_Eval(curExpr, &result, EXPR_NOUNDEF|EXPR_FINALIZE, NULL)) {
	    yyerror((char *)result.type);
	    cond = 0;	/* Don't take the conditional */
	} else if (result.type == EXPR_TYPE_CONST) {
	    cond = result.data.number;
	} else {
	    yyerror("condition must be a numeric constant");
	    cond = 0;
	}
	if (cond) {
	    ifStack[++iflevel].value = 1;
	    ifStack[iflevel].file = curFile->name;
	    ifStack[iflevel].line = yylineno;
	} else {
	    /*
	     * Record a false IF and go to an ELSE or ENDIF
	     */
	    ifStack[++iflevel].value = 0;
	    ifStack[iflevel].file = curFile->name;
	    ifStack[iflevel].line = yylineno;
	    Scan_ToEndif(TRUE);
	}
    }
}

/***********************************************************************
 *				RedefineString
 ***********************************************************************
 * SYNOPSIS:	    Redefine a string equate, giving an error if
 *	    	    the symbol in question isn't a string equate.
 * CALLED BY:	    yyparse string rules
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The previous value is freed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/12/89	Initial Revision
 *
 ***********************************************************************/
static void
RedefineString(SymbolPtr    sym,    	/* Symbol to redefine */
	       MBlk 	    *val)   	/* New value chain */
{
    /*
     * Redefinition of text macro. Free old value and
     * store new.
     */
    if (sym->type != SYM_STRING) {
	yyerror("%i is not a string constant", sym->name);
    } else {
	MBlk    *mp, *mpNext;

	for(mp = sym->u.string.value; mp != (MBlk *)NULL; mp = mpNext) {
	    mpNext = mp->next;
	    if (mp->dynamic) {
		free((char *)mp);
	    }
	}
	sym->u.string.value = val;
    }
}

/***********************************************************************
 *				FindSubstring
 ***********************************************************************
 * SYNOPSIS:	    Locate a string inside another string.
 * CALLED BY:	    yyparse for INSTR directive
 * RETURN:	    the offset of the start of the string in the other
 *		    string, zero-origin. -1 if substring not found.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/12/89	Initial Revision
 *
 ***********************************************************************/
static long
FindSubstring(char  *string,	/* String to search. */
	      char  *substring)	/* Substring to try to find in string. */
{
    register char *a, *b;
    char    	*strstart = string;

    /*
     * First scan quickly through the two strings looking for a
     * single-character match.  When it's found, then compare the
     * rest of the substring.
     */

    b = substring;
    for ( ; *string != 0; string += 1) {
	if (*string != *b) {
	    continue;
	}
	a = string;
	while (TRUE) {
	    if (*b == 0) {
		return string-strstart;
	    }
	    if (*a++ != *b++) {
		break;
	    }
	}
	b = substring;
    }
    return -1;
}


/***********************************************************************
 *				CheckRelated
 ***********************************************************************
 * SYNOPSIS:	    Make sure a symbol is related to a class.
 * CALLED BY:	    parser for methods, method handlers and instance variables
 * RETURN:	    0 if the class of the symbol and the current class
 *	    	    are unrelated.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/30/89	Initial Revision
 *
 ***********************************************************************/
static int
CheckRelated(Symbol	*curClass,	    /* Currently-active class */
	     Symbol	*otherClass)	    /* Class of symbol being
					     * referenced */
{
    int	    retval;

    if (curClass == NULL) {
	return(FALSE);
    }

    curClass->u.class.data->flags |= SYM_CLASS_CHECKING;

    retval = (curClass == otherClass);
    if (!retval) {
	Symbol  *class;
	int 	i;

	for (i = 0; i < curClass->u.class.data->numUsed; i++) {
	    class = curClass->u.class.data->used[i];

	    if (!(class->u.class.data->flags & SYM_CLASS_CHECKING) &&
		CheckRelated(class, otherClass))
	    {
		retval = TRUE;
		break;
	    }
	}
    }

    if (!retval) {
	retval = CheckRelated(curClass->u.class.super, otherClass);
    }

    curClass->u.class.data->flags &= ~SYM_CLASS_CHECKING;

    return(retval);
}


/***********************************************************************
 *				ParseCountLocals
 ***********************************************************************
 * SYNOPSIS:	    Callback function to count the local variables already
 *	    	    defined for the current procedure.
 * CALLED BY:	    handler for push-initialized local variable setup
 *	    	    via Sym_ForEachLocal
 * RETURN:	    0 (continue scan)
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 3/91		Initial Revision
 *
 ***********************************************************************/
static int
ParseCountLocals(SymbolPtr	sym,
		 Opaque 	data)
{
    if (sym->u.localVar.offset <= 0) {
	*(int *)data += 1;
    }
    return(0);
}


/***********************************************************************
 *				ParseAdjustLocals
 ***********************************************************************
 * SYNOPSIS:	    Callback function to adjust all local variable offsets
 *	    	    for a procedure by a set amount. This does not adjust
 *		    the offsets for arguments, just locals.
 * CALLED BY:	    handler for "push bp"-initialized local variables
 *	    	    via Sym_ForEachLocal
 * RETURN:	    0 (continue scan)
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 3/91		Initial Revision
 *
 ***********************************************************************/
static int
ParseAdjustLocals(SymbolPtr	sym,
		  Opaque 	data)
{
    if (sym->u.localVar.offset < 0) {
	/*
	 * Offset < 0 => it's local, so adjust it.
	 */
	sym->u.localVar.offset += (int)data;
    }
    return(0);
}


/***********************************************************************
 *				ParseFallThruCheck
 ***********************************************************************
 * SYNOPSIS:	    Make sure the operand given to a .fall_thru is
 *		    in fact the thing that follows the .fall_thru.
 * CALLED BY:	    Fixup module during pass 2
 * RETURN:	    FR_ERROR or FR_DONE
 * SIDE EFFECTS:    operand of .fall_thru is marked referenced
 *
 * STRATEGY:
 *	    	    Evaluate the operand (which marks it referenced) and
 *		    make sure the offset in the result (plus the symbol's
 *		    own offset) matches the offset of the .fall_thru, as
 *		    encoded in the fixup's own address.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/26/94		Initial Revision
 *
 ***********************************************************************/
static FixResult
ParseFallThruCheck(int	    *dotPtr,	    /* location of .fall_thru. */
		   int	    prevSize,	    /* Size of data-to-fixup during
					     * previous pass (0) */
		   int	    pass,   	    /* Current pass */
		   Expr	    *expr1, 	    /* Operand of .fall_thru */
		   Expr	    *expr2, 	    /* NULL */
		   Opaque   data)   	    /* Ignored */
{
    ExprResult	result;
    byte    	status;
    int	    	targ;

    /*
     * Evaluate the operand to something useful.
     */
    if (!Expr_Eval(expr1, &result, EXPR_FINALIZE|EXPR_NOT_OPERAND, &status)) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "%s", (char *)result.type);
	return(FR_ERROR);
    }

    /*
     * The result must be a direct code-related value (i.e. the expression
     * must have been a procedure, method, or label).
     */
    if ((status & (EXPR_STAT_DIRECT|EXPR_STAT_CODE)) !=
	(EXPR_STAT_DIRECT|EXPR_STAT_CODE))
    {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "invalid operand for .fall_thru: must be procedure or label");
	return(FR_ERROR);
    }
    /*
     * Compute the actual offset, including any symbol offset, of the operand
     * so we can compare it to the .fall_thru's own.
     */
    targ = result.data.ea.disp;
    if (result.rel.sym != NULL) {
	targ += result.rel.sym->u.addrsym.offset;
    }

    if (*dotPtr != targ) {
	if (result.rel.sym != NULL) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "%i does not immediately follow .fall_thru, off by %d bytes",
		   result.rel.sym->name, (targ - *dotPtr));
	} else {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   ".fall_thru not immediately followed by what you said followed it");
	}
	return(FR_ERROR);
    }
    /*
     * Happiness. Fixup module will free the expression, etc.
     */
    return (FR_DONE);
}

/***********************************************************************
 *				ParseIsLibName
 ***********************************************************************
 * SYNOPSIS:	    See if the passed ID is one of those specified with
 *		    the -n flag as being a library name for this here
 *		    geode.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    TRUE if it is
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/17/95		Initial Revision
 *
 ***********************************************************************/
static int
ParseIsLibName(ID id)
{
    int	i;

    for (i = 0; i < numLibNames; i++) {
	if (libNames[i] == id) {
	    return (TRUE);
	}
    }
    return(FALSE);
}


/***********************************************************************
 *				Parse_LastChunkWarning
 ***********************************************************************
 * SYNOPSIS:	    Display the warning related to the lastChunk.
 * CALLED BY:	    EXTERN
 * RETURN:	    nothing
 * SIDE EFFECTS:    nothing
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	clee	2/ 4/97   	Initial Revision
 *
 ***********************************************************************/
void
Parse_LastChunkWarning (char *fmt, ...)
{
    va_list args;

    /*
     * We only give warnings to the .asm files. The localization warnings
     * in .rdef have been handled by UIC.
     */
    if ( strstr(lastChunkFile, ".rdef") == NULL ){	/* not .rdef file */
	va_start(args,fmt);

#if defined(unix) || defined(_WIN32)
	fprintf(stderr, "file %s, line %d: Warning: ",
		lastChunkFile, lastChunkLine);
#else
	fprintf(stderr, "Warning %s %d: ",
		lastChunkFile, lastChunkLine);
#endif
	vfprintf(stderr, fmt, args);

	va_end(args);

	putc('\n', stderr);
    }

}	/* End of Parse_LastChunkWarning.	*/


/***********************************************************************
 *				ParseSetLastChunkWarningInfo
 ***********************************************************************
 * SYNOPSIS:	    Set the file name and line number for the lastChunk.
 * CALLED BY:	    parser
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *		lastChunkLine and lastChunkFile are set.
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	clee	2/ 4/97   	Initial Revision
 *
 ***********************************************************************/
static void
ParseSetLastChunkWarningInfo (void)
{
    if ( warn_localize ){
	/* Set the line number */
	lastChunkLine = yylineno;

	/* Set the file name */
	sprintf(lastChunkFile, "%i", curFile->name);
    }
}	/* End of ParseSetLastChunkWarningInfo.	*/


/***********************************************************************
 *				ParseLocalizationCheck
 ***********************************************************************
 * SYNOPSIS:	    Check the lastChunk to see if it is localizable.
 * CALLED BY:	    parser
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *		localizationRequired may change.
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	clee	2/ 5/97   	Initial Revision
 *
 ***********************************************************************/
static void
ParseLocalizationCheck (void)
{
    if (warn_localize &&
	lastChunk != NULL &&
	lastChunk->u.chunk.loc != NULL &&
	lastChunk->u.chunk.loc->dataTypeHint == CDT_text ){
	    localizationRequired = 1;
    }
}	/* End of ParseLocalizationCheck.	*/
