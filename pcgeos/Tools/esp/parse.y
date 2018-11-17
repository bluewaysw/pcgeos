%{
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
%}

/*****************************************************************************
 *
 *		      SEMANTIC VALUE DECLARATION
 *
 * This is now defined as union SemVal in scan.h, to avoid problems with
 * High C.
 *****************************************************************************/
%pure_parser

%token <model>	MEMMODEL
%token <lang>	LANGUAGE
%token <block>  EQU
%token <macro>	MACRO
%token <number>	ALIGNMENT BREAK BYTEREG CAST COMBINE CONSTANT COPROCESSOR DEBUG DEF
		DWORDREG MASM PNTR PROCESSOR SEGREG SHOWM STATE WORDREG ST
		IFNDEF IFDEF IFDIF IFE IFIDN IFNB IFB IF IF1 IF2
/**************************************************************
		IMPORTANT!!!!! all opcodes here must be declared
		between FIRSTOP and LASTOP if you want them to
		work, so I suggest doing so...
**************************************************************/
%token <opcode> FIRSTOP AND ARITH2 ARPL BITNF BOUND CALL CMPS ENTER GROUP1 IMUL
		IO INS INT JMP JUMP LDPTR LEA LEAVE LOCK LODS LOOP LSDT LSINFO 
                MOV MOVS NAIO NAPRIV NASTRG NASTRGD NASTRGW NOARG NOARGD NOARGW
		NOT OR OPCODE OUTS POP PWORD PUSH REP RET RETF RETN SCAS SHIFT
		SHL SHLD SHR SHRD STOS TEST WREG1 XCHG XLAT XLATB XOR FGROUP0
		FGROUP1 FBIOP FCOM FUOP FZOP FFREE FINT FLDST FXCH LASTOP
%token <ident>	IDENT
%token <string> STRING PCTOUT MACARG STRUCT_INIT
%token <sym>	MACEXEC FIRSTSYM SYM STRUCT_SYM CLASS_SYM METHOD_SYM MODULE_SYM
		INSTVAR_SYM TYPE_SYM ETYPE_SYM RECORD_SYM EXPR_SYM LASTSYM
		PROTOMINOR_SYM
%token <expr>	EXPR
%token <type>	PTYPE
%token		ABS ALIGN ASSERT ASSUME AT
		CATSTR CHUNK CLASS COMMENT CPUBLIC
		DEFAULT DEFETYPE DOT DOTENTER DOTLEAVE DOTTYPE 
		DUP DYNAMIC
		ELSE END ENDC ENDIF ENDM ENDP ENDS ENUM EQ ERR ERRB
		ERRDEF ERRDIF ERRE ERRIDN ERRNB ERRNDEF ERRNZ EVEN EXITF EXITM
		EXPORT
		FALLTHRU FAR FIRST FLDMASK
		GE GLOBAL GROUP GT
		HANDLE HIGH HIGHPART
		INCLUDE INHERIT INST INSTR IOENABLE IRP IRPC
		LABEL LE LENGTH LMEM LOCAL LOCALIZE LOW LOWPART LT
		MASK MASTER METHOD MOD MODEL
		NE NEAR NORELOC NOTHING
		OFFPART OFFSET ON_STACK ORG
		PRIVATE PROCESSOR PROC PROTOMINOR PROTORESET PTR PUBLIC
		RECORD RELOC REPT RESID
		SEG SEGMENT SEGREGOF SEGPART SIZE SIZESTR STATIC STRUC 
		SUBSTR SUPER
		THIS TYPE
		UNDEF UNION UNREACHED USES
		VARDATA VARIANT VSEG
		WARN WIDTH WRITECHECK NOWRITECHECK READCHECK NOREADCHECK

%type <ident>	localID
%type <type>	fulltype chunktype type defT optype vardataType
%type <number>	cexpr defArgs defList def def2 lexpr align assume
		etypeSize equ localDecl model
		pushLocals pushLocal pushLocalOperandList
%type <sym>	recordDefs recordField recordLineDef recordMLineDef
		recordMLineBody
%type <sym>	groupList groupElement globalSym protoMinorSym
		assumeSeg
%type <classDecl> classDeclArgs
%type <classDef> classDefArgs
%type <opcode>	retInst
%type <seg>	segAttrs segAttr
%type <arg>	macroArg macroArgList
%type <number>  usesArgs usesReg procArgs1 procCallFlag
%type <number>	segment
%type <etype>	etypeArgs
%type <number>	etypeFlags
%type <ident>	recordFieldName
%type <prefix>	prefixInst
%type <opcode>  shiftInst arith2Inst group1Inst noArgInst naStrgInst
%type <block>	strop catstrargs
%type <expr>	numstrop popOperand
%type <number>	methodFlags
%type <sym>	lmemSegDef
%type <number>	method methodDecl methodStatic
%type <sym> 	extMethodSym
%type <sym>	sym classUsesSym
%type <sym>	label
%type <sym> 	rangeSym
%type <sym>	locOptChunkSym optChunkSym
%type <exprSave> setTExpr
%type <number>	CLorCexpr

%nonassoc   	FLDMASK '{' '}'
%right		SHORT DOTTYPE NEAR FAR
%left		OR XOR
%left		AND
%right		NOT
%nonassoc	EQ NE LT LE GT GE
%nonassoc	SEGPART OFFPART HIGHPART LOWPART
%right   	PTR 	/* Only weirdos and macros use this twice */
%right		'[' ']'
%left		'+' '-'
%right		SHL SHR
%left		'*' '/' MOD
%right		HIGH LOW
%right	    	OFFSET SEG TYPE THIS SEGMENT SEGREGOF VSEG
%nonassoc	':'
%right	    	LENGTH SIZE WIDTH MASK FIRST HANDLE RESID ENUM SUPER
%left	    	'.'
%right		UNARY
%left		'(' ')'

/*
 * 1 s/r conflict comes from "THIS type" and pointers. "THIS pntr.something"
 *  can be interpreted as either "this pointer-to-something" or
 *  "this pointer-to-void plus something". Bison will take the former
 *  interpretation by shifting, which is what we want.
 * 2 other s/r conflicts come from the def/defList definition. It does the
 *  right thing, and I've not the time to do it right.
 */
%expect		3

%%
/*
 * Rule to make sure we return non-zero if there were any errors detected.
 * The Data module depends on this to produce meaningful errors
 */
errcheck	: file
		{
		    if (yynerrs) {
			YYABORT;
		    } else {
			YYACCEPT;
		    }
		}
		;
file		: line
		{
		    defStruct = FALSE;
		}
		| file line
		{
		    defStruct = FALSE;
		}
		;

/* Allow for blank lines in certain places, while making sure structure
 * initializers continue to be returned as structure initializers, not just
 * strings. */
multiEOL	: '\n'
		| conditional '\n'
		| multiEOL '\n'
		| multiEOL conditional '\n'
		;
flexiComma	: ','
		| ',' multiEOL
		;
line		: ref_label op '\n'
		| ref_label '\n'
		| labeled_op '\n'
		| dataDef '\n'
		| op '\n'
		| '\n'
		| error '\n'
		{
		    defStruct = 0;
		}
		| END '\n'
		{
		    /*
		     * Boogie, dude
		     */
		    YYACCEPT;
		}
		| END operand1 '\n'
		{
		    /*
		     * Record entry point, and boogie
		     */
		    entryPoint = Expr_Copy(&expr1, TRUE);
		    YYACCEPT;
		}
	/*
	 * Do-nothing rule since % is supposed to cause string equates to
	 * be interpolated and that's done automatically by the scanner...
	 */
		| '%' line
		;

/*
 * Rule to give some indication why there was a parse error. In general, if the
 * first thing on the line is an identifier, we need something to tell us what
 * the identifier is. More often than not, the lack of such a directive means
 * the identifier is a macro that hasn't been defined...but we don't say that.
 */
labeled_op	: IDENT error
		{
		    /*
		     * General error handler
		     */
		    if (yychar > FIRSTOP && yychar < LASTOP) {
			yyerror("missing colon for code label %i", $1);
		    } else {
			yyerror("expected symbol-definition directive for %i",
				$1);
		    }
		    yyerrok;
		}
		;
ref_label	: label {}
		| label ':'
		{
		    Sym_Reference($1);
		}
		;
/*
 * Simple near-label definitions (i.e. ones that don't require a directive)
 */
label		: IDENT ':'
		{
		    /*
		     * Regular near label -- enter it as a FAR so that
		     * it can be called as a procedure
		     */
		    $$ = Sym_Enter($1, curProc ? SYM_LOCALLABEL : SYM_LABEL,
				    dot, TRUE);
		    curSeg->u.segment.data->lastLabel = dot;
		    FilterGenerated($$);
		}
		| SYM ':'
		{
		    if ($1->type == SYM_LOCALLABEL) {
			yyerror("%i is already a local label in this procedure",
				$1->name);
		    } else {
			CheckAndSetLabel(SYM_LABEL, $1, TRUE);
		    }
		    $$ = $1;
		}
		| CONSTANT DOT ':'
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
			sprintf(name, "%d$", $1);
			id = ST_EnterNoLen(output, symStrings, name);
			
			/*
			 * Enter the thing as a local label, but mark it as
			 * something that shouldn't be written out.
			 */
			$$ = Sym_Enter(id, SYM_LOCALLABEL, dot, TRUE);
			$$->flags |= SYM_NOWRITE;
			curSeg->u.segment.data->lastLabel = dot;
		    }
		}
		;
			
		    
labeled_op	: IDENT LABEL type
		{
		    SymbolPtr	sym;

		    if ($3->tn_type == TYPE_NEAR) {
			sym = Sym_Enter($1, SYM_LABEL, dot, TRUE);
			curSeg->u.segment.data->lastLabel = dot;
			FilterGenerated(sym);
		    } else if ($3->tn_type == TYPE_FAR) {
			sym = Sym_Enter($1, SYM_LABEL, dot, FALSE);
			curSeg->u.segment.data->lastLabel = dot;
			FilterGenerated(sym);
		    } else {
			ResetExpr(&expr1, defElts1);
			DefineData($1, $3, FALSE, FALSE);
		    }
		}
		| SYM LABEL type
		{
		    if ($3->tn_type == TYPE_NEAR) {
			CheckAndSetLabel(SYM_LABEL, $1, TRUE);
		    } else if ($3->tn_type == TYPE_FAR) {
			CheckAndSetLabel(SYM_LABEL, $1, FALSE);
		    } else {
			ResetExpr(&expr1, defElts1);
			DefineDataSym($1, $3, FALSE, FALSE);
		    }
		}
		;
/******************************************************************************
 *
 *			      Procedures
 *
 *****************************************************************************/

labeled_op	: IDENT PROC procArgs1
		{
		    Symbol *sym;
		    sym = Sym_Enter($1, SYM_PROC, dot, $3);

		    EnterProc(sym);
		}
		  procArgsArgDeclStart
		| SYM PROC procArgs1
		{
		    CheckAndSetLabel(SYM_PROC, $1, $3 & SYM_NEAR);
		    $1->u.proc.flags |= $3;
		    EnterProc($1);
		}
		  procArgsArgDeclStart
		;
procArgs1	: NEAR procCallFlag procUsesArgs { $$ = $2 | SYM_NEAR; }
		| FAR procCallFlag procUsesArgs { $$ = $2; }
		| procCallFlag procUsesArgs
		{
		    /*
		     * If the current memory model is small or compact,
		     * the procedure defaults to near, else it defaults to
		     * far.
		     */
		    if (model == MM_SMALL || model == MM_COMPACT) {
			$$ = $1 | SYM_NEAR;
		    } else {
		    	$$ = $1;
		    }
		}
		;

procCallFlag	: CALL { $$ = SYM_NO_JMP; }
		| JMP { $$ = SYM_NO_CALL; }
		| { $$ = 0; }
		;

procArgsArgDeclStart: /* empty */
		| procArgsArgDecls
		;

sym		: EXPR_SYM | CLASS_SYM | STRUCT_SYM | METHOD_SYM | MODULE_SYM
		| INSTVAR_SYM | TYPE_SYM | ETYPE_SYM | RECORD_SYM | PROTOMINOR_SYM
		;
procArg		: IDENT ':' fulltype
		{
		    AddArg($1, $3);
		}
		| SYM ':' fulltype
		{
		    if (($1->type != SYM_VAR) || warn_shadow) {
			yywarning("definition of %i as argument shadows global symbol",
				  $1->name);
		    }
		    AddArg($1->name, $3);
		}
		| sym ':' fulltype
		{
		    yywarning("definition of %i as argument shadows global symbol",
			      $1->name);
		    AddArg($1->name, $3);
		}		    
		| ':' fulltype
		{
		    /*
		     * Declaring extra stuff on stack that needn't be
		     * referenced.
		     */
		    AddArg(NullID, $2);
		}
		;
		
procArgsArgDecls: procArg
		| procArgsArgDecls flexiComma procArg
		;

labeled_op	: SYM ENDP
		{
		    if (curProc != $1) {
			if (curProc == NULL) {
			    yyerror("ENDP for %i outside of any procedure",
				    $1->name);
			} else {
			    yyerror("ENDP for %i inside %i",
				    $1->name, curProc->name);
			}
			yynerrs++;
		    } else {
			/*
			 * Reset procedure-specific state variables
			 */
			EndProc(curProc->name);
		    }
		}
		| IDENT ENDP
		{
		    yyerror("procedure %i not defined, so can't be ended", $1);
		    yynerrs++;
		}
		;
op		: ENDP
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
		}
		;

/*
 * Register usage stuff...
 */
usesArgs    	: usesReg
    		| usesArgs flexiComma usesReg 	{ $$ = $1 | $3; }
    		| usesArgs usesReg 	{ $$ = $1 | $2; }
		;
usesReg		: DWORDREG   	    	{ $$ = (1L << $1) | 
					  (1L << ($1 + REG_DI + REG_GS + 2)); }
		| WORDREG   	    	{ $$ = 1L << $1; }
		| BYTEREG   	    	{ $$ = 1L << ($1 & 0x3); }
		| SEGREG    	    	{ $$ = 1L << ($1 + REG_DI + 1); }
		;
op		: USES usesArgs
		{
		    if (enterSeen || leaveSeen) {
			/*
			 * Generated code was incorrect -- give error
			 */
			yyerror("\"uses\" too late: .ENTER or .LEAVE already given for procedure %i",
				curProc->name);
			yynerrs++;
		    }
		    usesMask |= $2;
		    enterNeeded = TRUE;
		}
		;
procUsesArgs	: /* empty */
		| USES usesArgs { usesMask |= $2; enterNeeded = TRUE; }
		;
labeled_op	: localDecl {}
		| localDecl 
		{
		    /*
		     * Initialize first-local-var flag. Doing it here avoids
		     * a spurious error if we bitch b/c this isn't the first
		     * push-initialized variable and the hoser's initializing
		     * this variable with BP (it'll still bitch if the push
		     * bp isn't the first push instruction, though).
		     */
		    isFirstLocalWord = TRUE;
		    if (frameSize != $1) {
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
			frameSize -= $1;
		    }
		}
		 pushLocals
		{
		    if ($3 * 2 < $1) {
			yyerror("not enough PUSHes to initialize local variable");
			yynerrs++;
		    } else if ($3 * 2 > $1) {
			yyerror("too many PUSHes initializing local variable");
			yynerrs++;
		    }
		}
		;
pushLocals	: pushLocal 	{ $$ = $1; }
		| pushLocals pushLocal	{ $$ = $1 + $2; }
		;
pushLocal	: PUSH pushLocalOperandList
		{
		    /*
		     * Return number of words pushed.
		     */
		    $$ = $2;
		}
		;
		    
pushLocalOperandList: pushLocalOperand { $$ = 1; }
		| pushLocalOperandList flexiComma pushLocalOperand
		{
		    /*
		     * Count another word pushed.
		     */
		    $$ = $1 + 1;
		}
		;

pushLocalOperand: operand1
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
		}
		;

localDecl	: localID LOCAL fulltype
		{
		    $$ = 0;

		    if (enterSeen || leaveSeen) {
			yyerror("\"local\" too late: .ENTER or .LEAVE already given for procedure %i",
				curProc->name);
			yynerrs++;
		    } else if (!curProc) {
			yyerror("LOCAL directive for %i when not in a procedure",
				$1);
			yynerrs++;
		    } else {
			/*
			 * Add the size of the variable to the current
			 * frame size to get the offset for the variable.
			 * No need to word-align the thing as we'll do that
			 * when we encounter the ENTER. 
			 */
			$$ = Type_Size($3);

			localSize += $$; frameSize += $$;

			(void)Sym_Enter($1, SYM_LOCAL, -localSize, $3);

			frameNeeded = enterNeeded = TRUE;
		    }
		}
		;

localID		: IDENT
		| SYM
		{
		    if (($1->type != SYM_VAR) || warn_shadow) {
			yywarning("definition of %i as local variable shadows global symbol",
				  $1->name);
		    }
		    $$ = $1->name
		}
		| /* empty */ { $$ = NullID; }
		| sym
		{
		    yywarning("definition of %i as local variable shadows global symbol",
			      $1->name);
		    $$ = $1->name;
		}
		;

op		: DOTENTER
		{
		    if (curProc != NULL) {
			Code_Prologue(frameNeeded, usesMask, frameSize,
				      frameSetup);
			enterSeen = TRUE;
		    } else {
			yyerror(".ENTER is outside any procedure");
			yynerrs++;
		    }
		}
		| DOTENTER inherit
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
		}
		| DOTLEAVE
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
		}
		| DOTLEAVE UNREACHED
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
		}
		;
inherit		: INHERIT
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
		}
		| INHERIT NEAR
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
		}
		| INHERIT FAR
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
		}
		| INHERIT IDENT
		{
		    /*
		     * Inherit from a procedure that's not yet defined.
		     */
		    if (curProc != NULL) {
			Sym_Enter($2, SYM_INHERIT, NullSymbol, curFile->name,
				  yylineno);
		    }
		}
		| INHERIT SYM
		{
		    /*
		     * Inherit from a known procedure.
		     */
		    if ($2->type != SYM_PROC) {
			yyerror("cannot inherit locals from non-procedure %i",
				$2->name);
			yynerrs++;
		    } else if (curProc != NULL) {
			Sym_Enter($2->name, SYM_INHERIT, $2, curFile->name,
				  yylineno);
		    }
		}
		;
/******************************************************************************
 *
 *		   Macro Definitions and Expansions
 *
 *****************************************************************************/
labeled_op	: IDENT MACRO
		{
		    Sym_Enter($1, SYM_MACRO, $2.text, $2.numArgs,
			      $2.numLocals);
		}
		| MACEXEC MACRO
		{
		    /*
		     * Macro redefinitions -- can't free the old text since
		     * blocks are allocated in chunks, so just store in the
		     * new parameters.
		     */

		    $1->u.macro.text = $2.text;
		    $1->u.macro.numArgs = $2.numArgs;
		    $1->u.macro.numLocals = $2.numLocals;
		}
		| IDENT EQU
		{
		    /*
		     * Nothing follows, so must be a string equate. Value
		     * has been parsed into pieces by the scanner and
		     * is the value of the EQU token
		     */
		    Sym_Enter($1, SYM_STRING, $2);
		}
		| SYM EQU
		{
		    if (yychar != '\n') {
			yyerror("%i cannot be redefined as an equate",
				$1->name);
		    } else {
			RedefineString($1, $2);
		    }
		}
		| SYM EQU STRING
		{
		    /*
		     * This can happen if you redefine a string equate
		     * with another string equate. Form the string into
		     * a macro block and call RedefineString.
		     */
		    int	    len = strlen($3);
		    MBlk    *val;

		    if (len > 0) {
			val = (MBlk *)malloc_tagged(sizeof(MArg)+len,
							 TAG_MBLK);

			val->next = (MBlk *)NULL;
			val->length = len;
			val->dynamic = TRUE;
			bcopy($3, val->text, len);
		    } else {
			val = NULL;
		    }
		    
		    free($3);

		    RedefineString($1, val);
		}
		| IDENT strop
		{
		    Sym_Enter($1, SYM_STRING, $2);
		}
		| SYM strop
		{
		    RedefineString($1, $2);
		}
		;
strop		: SUBSTR STRING flexiComma cexpr
		{
		    /*
		     * Substring from position to end (1-origin)
		     */
		    int	    len = strlen($2);

		    /*
		     * We like zero-origin...
		     */
		    $4 -= 1;
		    
		    if ($4 < 0) {
			yyerror("invalid start position %d (must be >= 1)",
				$4+1);
			$$ = NULL;
			yynerrs++;
		    } else if ($4 >= len) {
			yyerror("start position %d too big (string is %d byte%s long)",
				$4+1, len, len == 1 ? "" : "s");
			$$ = NULL;
			yynerrs++;
		    } else {
			$$ = (MBlk *)malloc_tagged(sizeof(MArg)+(len-$4),
						   TAG_MBLK);
			$$->dynamic = TRUE;
			$$->next = (MBlk *)NULL;
			$$->length = len-$4;
			bcopy($2+$4, $$->text, len-$4);
		    }
		    free($2);
		}
		| SUBSTR STRING flexiComma cexpr flexiComma cexpr
		{
		    /*
		     * Substring from position of given length.
		     */
		    int	    len = strlen($2);

		    /*
		     * We like zero-origin...
		     */
		    $4 -= 1;
		    
		    if ($4 < 0) {
			yyerror("invalid start position %d (must be >= 1)",
				$4+1);
			$$ = NULL;
			yynerrs++;
		    } else if ($4 >= len) {
			yyerror("start position %d too big (string is %d byte%s long)",
				$4+1, len, len == 1 ? "" : "s");
			$$ = NULL;
			yynerrs++;
		    } else if ($4+$6 > len) {
			yyerror("length %d too big (string is %d byte%s long)",
				$6, len, len == 1 ? "" : "s");
			$$ = NULL;
			yynerrs++;
		    } else if ($6 > 0) {
			$$ = (MBlk *)malloc_tagged(sizeof(MArg)+$6,
						   TAG_MBLK);
			$$->dynamic = TRUE;
			$$->next = (MBlk *)NULL;
			$$->length = $6;
			bcopy($2+$4, $$->text, $6);
		    } else {
			$$ = NULL;
		    }
		    free($2);
		}
		| CATSTR catstrargs { $$ = $2; }
		;
		/*
		 * Args for catstr. The rule is right-recursive because
		 * we need to get the blocks chained in the right order and
		 * this is the easiest way to do it. We don't worry about
		 * overflowing the stack because this directive won't usually
		 * be used with too many arguments.
		 */
catstrargs	: STRING
		{
		    /*
		     * Convert the string into a macro block.
		     */
		    int	    len = strlen($1);

		    if (len > 0) {
			$$ = (MBlk *)malloc_tagged(sizeof(MArg)+len,
						   TAG_MBLK);
			$$->dynamic = TRUE;
			$$->length = len;
			$$->next = NULL;
			bcopy($1, $$->text, len);
		    } else {
			$$ = NULL;
		    }

		    free($1);
		}
		| STRING flexiComma catstrargs
		{
		    /*
		     * Convert the string into a macro block and link to the
		     * next block in the list.
		     */
		    int	    len = strlen($1);

		    if (len > 0) {
			$$ = (MBlk *)malloc_tagged(sizeof(MArg)+len,
						   TAG_MBLK);
			$$->dynamic = TRUE;
			$$->length = len;
			$$->next = $3;
			bcopy($1, $$->text, len);
		    } else {
			/*
			 * Zero-length string, so just use the chain from
			 * the strings to our right.
			 */
			$$ = $3;
		    }

		    free($1);
		}
		;
op		: REPT cexpr 	    	    	    	{ yyrepeat($2); }
		| IRP IDENT { defStruct = 1; } flexiComma STRUCT_INIT
		{
		    char    *id = ST_Lock(output, $2);
		    
		    yyirp(id, $5);
		    free($5);
		    ST_Unlock(output, $2);
		    defStruct = 0;
		}
		| IRPC IDENT { defStruct = 1; } flexiComma STRUCT_INIT
		{
		    char    *id = ST_Lock(output, $2);

		    yyirpc(id, $5);
		    free($5);
		
		    ST_Unlock(output, $2);
		    defStruct = 0;
		}
		| MACEXEC macroArgList          { yystartmacro($1, $2); }
		| MACEXEC   	    	    	{ yystartmacro($1, NULL); }
		;
	/*
	 * Arguments for a macro. Right-recursive b/c we need the args in their
	 * proper order... yymacarglex will only return STRING or % or \n,
	 * so that's all that macroArg deals with
	 */
macroArgList	: macroArg
		| macroArg macroArgList   { $$ = $1; $$->next = $2; }
		;
macroArg	: MACARG
		{
		    $$ = (Arg *)malloc_tagged(sizeof(Arg),
					      TAG_MACRO_ARG);
		    $$->next = NULL;
		    $$->value = $1;
		    $$->freeIt = TRUE;
		}
	/*
	 * yymacarglex sets noSymTrans back to false before returning %.
	 */
		| '%' cexpr		
		{
		    $$ = (Arg *)malloc_tagged(sizeof(Arg),
					      TAG_MACRO_ARG);
		    $$->next = 0;
		    $$->value = (char *)malloc_tagged(12, TAG_MACRO_ARG_VALUE);
		    $$->freeIt = TRUE;

		    sprintf($$->value, "%d", $2);
		    noSymTrans = TRUE;
		    /*
		     * If the look-ahead token is a newline, we do *not*
		     * want to switch back to parsing macro arguments.
		     */
		    if (yychar != '\n') {
			yylex = yymacarglex;
		    }
		}
	/*
	 * This thing is needed b/c the operand rule will fetch the next
	 * token (',') in order to decide if it's done, but macroArgList
	 * doesn't do commas, so we have to handle it specially here.
	 */
		| '%' cexpr ','
		{
		    $$ = (Arg *)malloc_tagged(sizeof(Arg), TAG_MACRO_ARG);
		    $$->next = 0;
		    $$->value = (char *)malloc_tagged(12,
						      TAG_MACRO_ARG_VALUE);
		    $$->freeIt = TRUE;

		    sprintf($$->value, "%d", $2);
		    noSymTrans = TRUE;
		    /*
		     * If the look-ahead token is a newline, we do *not*
		     * want to switch back to parsing macro arguments.
		     */
		    if (yychar != '\n') {
			yylex = yymacarglex;
		    }
		}
		;

/******************************************************************************
 *
 *		    Numeric/expression constants.
 *
 * Their value is parsed into an expression (must obey normal expression rules
 * unless it's a string equate, see above) and a copy stored in the symbol.
 * An equate created with EQU is considered "read-only": any subsequent
 * attempt to change the value is flagged with a warning (some people use
 * EQU and = interchangably, and MASM in fact doesn't make the distinction
 * it claims to in its manual, I don't think, but it is a good distinction to
 * make).
 *
 *****************************************************************************/
equ	    	: EQU { $$ = TRUE; }
		| '=' { $$ = FALSE; }
		;
equ_value	: operand1
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
		}
		;
labeled_op	: IDENT equ equ_value
		{
		    Sym_Enter($1, SYM_NUMBER, Expr_Copy(&expr1, TRUE), $2);
		}
		| EXPR_SYM equ equ_value
		{
		    if ($1->u.equate.rdonly) {
			/*
			 * Generate a warning if the new value differs from the
			 * old.
			 */
			if (($1->u.equate.value->numElts != 2) ||
			    (expr1.numElts != 2) ||
			    ($1->u.equate.value->elts[0].op != EXPR_CONST) ||
			    (expr1.elts[0].op != EXPR_CONST) ||
			    ($1->u.equate.value->elts[1].value !=
			     expr1.elts[1].value))
			{
			    yywarning("%i redefined", $1->name);
			}
		    } else if ($2) {
			yywarning("%i was defined with '=' before",
				  $1->name);
		    }
		    $1->u.equate.rdonly = $2;
		    Expr_Free($1->u.equate.value);
		    $1->u.equate.value = Expr_Copy(&expr1, TRUE);
		}
		| ETYPE_SYM equ cexpr
		{
		    /*
		     * This can be used to set the value given to the next
		     * member added to the type.
		     */
		    $1->u.eType.nextVal = $3;
		}
		| IDENT numstrop
		{
		    Sym_Enter($1, SYM_NUMBER, $2, FALSE);
		}
		| EXPR_SYM numstrop
		{
		    if ($1->u.equate.rdonly) {
			yywarning("%i redefined with string operator",
				  $1->name);
		    }
		    Expr_Free($1->u.equate.value);
		    
		    $1->u.equate.value = $2;
		}
		;
numstrop    	: SIZESTR STRING
		{
		    ResetExpr(&expr1, defElts1);
		    StoreExprConst((long)strlen($2));
		    free($2);

		    $$ = Expr_Copy(&expr1, TRUE);
		    malloc_settag((void *)$$, TAG_EQUATE_EXPR);
		}
		| INSTR operand1 flexiComma STRING
		{
		    if (expr1.elts[0].op != EXPR_STRING) {
			yyerror("two-operand INSTR directive requires string as first operand");
			yynerrs++;
			ResetExpr(&expr1, defElts1);
			StoreExprConst(0L);
			free($4);
		    } else {
			long	n = FindSubstring(expr1.elts[1].str, $4);

			free($4);
			ResetExpr(&expr1, defElts1);
			/*
			 * Wants the index to be 1-origin with 0 => no such
			 * substring around.
			 */
			StoreExprConst(n+1);
		    }

		    $$ = Expr_Copy(&expr1, TRUE);
		    malloc_settag((void *)$$, TAG_EQUATE_EXPR);
		}
		| INSTR operand1 flexiComma STRING flexiComma STRING
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
			} else if (start >= strlen($4)) {
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
			    StoreExprConst(FindSubstring($4+start,$6)+1);
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
		    free($4);
		    free($6);

		    $$ = Expr_Copy(&expr1, TRUE);
		    malloc_settag((void *)$$, TAG_EQUATE_EXPR);
		}
		;
		
		    
/******************************************************************************
 *
 *			   Data Definition
 *
 * Handles standard DEF terminals and arbitrary types...most of the work is
 * done by the DefineDataSym and Data_Enter functions...
 *
 *****************************************************************************/
defT	    	: DEF
		{
		    /*
		     * Has to be numeric, so set emptyIsConst true, then
		     * convert the data size into a type description.
		     */
		    emptyIsConst = 1;
		    if ($1 == 0) {
		        $$ = Type_Char(1);
		    } else if ($1 == 'z') {
		        $$ = Type_Char(2);
		    } else {
		        $$ = Type_Int($1);
		    }
		    checkForStrings = ($1 >= -1 && $1 <= 1);
		}
		| type
		{
		    /*
		     * Set emptyIsConst true if type isn't complex (array or
		     * a structured type whose initializer must be a string).
		     * Note that we have to be careful of typedefs here (and
		     * later on). If $1 is a typedef, reduce it to its
		     * basest type. This allows us to properly handle
		     * array typedef initializers, for example.
		     */
		    TypePtr checkType = $1;

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
		    $$ = $1;

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
		}
		;
dataDef		: IDENT defT defArgs
		{
		    if ($3 != 1) {
			DefineData($1, Type_Array($3, $2), TRUE, TRUE);
		    } else {
			DefineData($1, $2, TRUE, FALSE);
		    }
		    defStruct = FALSE;
		}
		| SYM defT defArgs
		{
		    if ($3 != 1) {
			DefineDataSym($1, Type_Array($3, $2), TRUE, TRUE);
		    } else {
			DefineDataSym($1, $2, TRUE, FALSE);
		    }
		    defStruct = FALSE;
		}
		| INSTVAR_SYM defT defArgs
		{
		    yyerror("%i is already an instance variable for %i",
			    $1->name, $1->u.instvar.class->name);
		    yynerrs++;
		}
		| defT defArgs
		{
		    if ($2 != 1) {
			DefineData(NullID, Type_Array($2, $1), TRUE, TRUE);
		    } else {
			DefineData(NullID, $1, TRUE, FALSE);
		    }
		    defStruct = FALSE;
		}
		;
		/*
		 * Special chunk-definition rules. The semantic value of
		 * anything to the immediate left of "chunkDef" in a rule must
		 * be the <ident> of the chunk being defined. This allows for
		 * shorthand chunk definitions like "foo chunk.char 'hi mom', 0"
		 */
labeled_op	: IDENT CHUNK
		{
		    $<ident>$ = NullID;
		    if (curSeg->u.segment.data->comb != SEG_LMEM) {
			yyerror("CHUNK directive is not allowed inside non-lmem segment %i",
				curSeg->name);
			yynerrs++;
		    } else if (curChunk) {
			yyerror("Nested CHUNK declarations are not allowed (defining %i now)",
				curChunk->name);
			yynerrs++;
		    } else {
			$<ident>$ = $1;
		    }
		} chunkDef
		| SYM CHUNK 
		{
		    $<ident>$ = NullID;
		    if (curSeg->u.segment.data->comb != SEG_LMEM) {
			yyerror("CHUNK directive is not allowed inside non-lmem segment %i",
				curSeg->name);
			yynerrs++;
		    } else if (curChunk) {
			yyerror("Nested CHUNK declarations are not allowed (defining %i now)",
				curChunk->name);
			yynerrs++;
		    } else if (($1->type == SYM_CHUNK) &&
			       (($1->flags & SYM_UNDEF) == 0))
		    {
			yyerror("chunk %i is already defined", $1->name);
			yynerrs++;
		    } else if (($1->type == SYM_CHUNK) &&
			       ($1->flags & SYM_UNDEF))
		    {
			/*
			 * Declared global before with :chunk, so it's ok.
			 */
			$<ident>$ = $1->name;
			if (!LMem_UsesHandles(curSeg)) {
			    /*
			     * Chunk will be redefined as a SYM_VAR, so
			     * prevent death.
			     * XXX: this should be in LMem module.
			     */
			    $1->type = SYM_VAR;
			}
		    } else if ((LMem_UsesHandles(curSeg) &&
				($1->type != SYM_CHUNK)) ||
			       (!LMem_UsesHandles(curSeg) &&
				($1->type != SYM_VAR)))
		    {
			yyerror("%i is already something other than a chunk",
				$1->name);
			yynerrs++;
		    } else {
			$<ident>$ = $1->name;
		    }
		} chunkDef
		| CHUNK
		{
		    $<ident>$ = NullID;
		    if (curSeg->u.segment.data->comb != SEG_LMEM) {
			yyerror("CHUNK directive is not allowed inside non-lmem segment %i",
				curSeg->name);
			yynerrs++;
		    } else if (curChunk) {
			yyerror("Nested CHUNK declarations are not allowed (defining %i now)",
				curChunk->name);
			yynerrs++;
		    }
		} chunkDef
		;

chunkDef	: chunktype
		{
		    if ( warn_localize && localizationRequired ){
			Parse_LastChunkWarning("Missing @localize instruction");
			localizationRequired = 0;
		    }
		    lastChunk = curChunk = LMem_DefineChunk($1, $<ident>0);
		    ParseSetLastChunkWarningInfo();
		}
		| '.' defT defArgs
		{
		    SymbolPtr   chunk;
		    if ($3 > 1) {
			TypePtr	t = Type_Array($3, $2);
			
			if ( warn_localize && localizationRequired ){
			    Parse_LastChunkWarning("Missing @localize instruction");
			    localizationRequired = 0;
			}
		    	lastChunk = chunk = LMem_DefineChunk(t, $<ident>0);
			ParseSetLastChunkWarningInfo();
			DefineData(NullID, t, TRUE, TRUE);
		    } else {
			if ( warn_localize && localizationRequired ){
			    Parse_LastChunkWarning("Missing @localize instruction");
			    localizationRequired = 0;
			}
			lastChunk = chunk = LMem_DefineChunk($2, $<ident>0);
			ParseSetLastChunkWarningInfo();
			DefineData(NullID, $2, TRUE, FALSE);
		    }
		    defStruct = FALSE;

		    if (chunk != NullSymbol) {
			LMem_EndChunk(chunk);
			ParseLocalizationCheck();
		    }
		}
		;
chunktype	: fulltype
		| /* empty => byte */ { $$ = Type_Void(); }
		;
labeled_op	: SYM ENDC
		{
		    if (curChunk == NULL) {
			yyerror("not defining a chunk, so %i can't be ending",
				$1->name);
			yynerrs++;
		    } else if ($1 != curChunk) {
			yyerror("%i is not the current chunk (%i is)",
				$1->name, curChunk->name);
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
		}
		;
op		: ENDC
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
		}
		| INST defT defArgs
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
		    if ($3 > 1) {
			DefineData(NullID, Type_Array($3, $2), TRUE, TRUE);
		    } else {
			DefineData(NullID, $2, TRUE, FALSE);
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
		}
		;
			
/*
 * List of expressions for defining things. Simply places all the elements into
 * expr1 and sticks COMMA operators between them, as it were. The rules
 * return the number of elements defined.
 */
defArgs		: setExpr1 defList
		{
		    $$ = $2;
		}
		;
defList		: def
		| defList flexiComma def
		{
		    $$ = $1 + $3;
		}
		;
def		: /* empty => (?) */
		{
		    $$ = 1;
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
		}
		| def2
		{
		    if (checkForStrings &&
			(curExpr->elts[$1].op == EXPR_STRING))
		    {
			int nelts = ExprStrElts(curExpr->elts[$1+1].str);
			int len = strlen(curExpr->elts[$1+1].str);

			if (curExpr->numElts == $1+1+nelts && len > 1) {
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
			    $$ = len;
			} else {
			    $$ = 1;
			}
		    } else {
			$$ = 1;
		    }
		    StoreExprComma();
		}
		| def2 DUP /* ... */
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
		    cexpr.elts += $1;
		    cexpr.numElts -= $1;
		    
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
		    curExpr->numElts = $1;
		    /*
		     * Record the length of the array as our semantic value
		     */
		    $<number>$ = value;
		}
		  '(' defList ')'
 	    	{
		    /*
		     * Copy all elements between start and now the number of
		     * times indicated by the cexpr. We reduce that number
		     * by one b/c we've already got one copy...
		     */
		    if ($<number>3 > 1) {
		    	DupExpr($<number>3-1, $1);
		    } else if ($<number>3 == 0) {
			/*
			 * No duplications, so return the expression to the
			 * state it was in before this whole hoax was
			 * perpetrated on us.
			 */
			curExpr->numElts = $1;
		    }
		    $$ = $<number>3 * $5;
		}
		;
	/*
	 * Rule used to record the starting numElts without making the
	 * parser commit too soon. Return value is the numElts before
	 * the operand is parsed. Enclosing rule is responsible for
	 * converting the thing to a value, if needed, and removing
	 * the elements stored.
	 */
def2		: /* empty */
		{
		    /*
		     * Record current element count in case DUP operator given
		     */
		    $<number>$ = curExpr->numElts;
		}
		  operand
		{
		    /*
		     * Return initial element count as our value
		     */
		    $$ = $<number>1;
		}
		;
		    
/*****************************************************************************
 *
 *			  Localization Stuff
 *
 ****************************************************************************/
op		: LOCALIZE locOptChunkSym STRING 
		{
		    if (localize) {
			$2->u.chunk.loc->instructions = $3;
		    }
		    localizationRequired = 0;
		}
		| LOCALIZE locOptChunkSym STRING flexiComma cexpr
		{
		    if (localize) {
			$2->u.chunk.loc->instructions = $3;
			$2->u.chunk.loc->max = $5;
		    }
		    localizationRequired = 0;
		}
		| LOCALIZE locOptChunkSym STRING flexiComma cexpr flexiComma cexpr 
		{
		    if (localize) {
			$2->u.chunk.loc->instructions = $3;
			$2->u.chunk.loc->min = $5;
			$2->u.chunk.loc->max = $7;
		    }
		    localizationRequired = 0;
		}
		| LOCALIZE locOptChunkSym STRING flexiComma cexpr flexiComma cexpr flexiComma cexpr 
		{
		    if (localize) {
			$2->u.chunk.loc->instructions = $3;
			$2->u.chunk.loc->min = $5;
			$2->u.chunk.loc->max = $7;
			$2->u.chunk.loc->dataTypeHint = $9;
		    }
		    localizationRequired = 0;
		}
		| LOCALIZE locOptChunkSym NOT
		{
		    if (localize) {
			/*
			 *  mark it as not localizable for localize.c
			 */
			$2->u.chunk.loc->min = -1;
			$2->u.chunk.loc->max = -1;
		    }
		    localizationRequired = 0;
		}
		;

locOptChunkSym	: optChunkSym
		{
		    if (localize) {
			/*
			 * Make sure the thing has a localization record.
			 */
			if ($1->u.chunk.loc == 0) {
			    $1->u.chunk.loc = Sym_AllocLoc($1, CDT_unknown);
			}
			/*
			 * Free any previous instructions and warn the user of
			 * the redefinition.
			 */
			if ($1->u.chunk.loc->instructions != 0) {
			    yywarning("localization instructions already given for %i", $1->name);
			    free($1->u.chunk.loc->instructions);
			}
		    }
		    $$ = $1;
		}
		;

optChunkSym	: SYM flexiComma
		{
		    if ($1->type == SYM_CHUNK) {
			$$ = $1;
		    } else {
			yyerror("%i is not an lmem chunk.", $1->name);
			YYERROR;
		    }
		}
		| /* empty */
		{
		    if (lastChunk == 0) {
			yyerror("You haven't defined an lmem chunk yet, so there's nothing to localize.");
			YYERROR;
		    } else if (lastChunk->name == NullID) {
			yyerror("The most-recent chunk cannot be localized as it has no name");
			YYERROR;
		    } else {
			$$ = lastChunk;
		    }
		}
		;

/*****************************************************************************
 *
 *			  Global Definitions
 *
 ****************************************************************************/
op	    	: GLOBAL globalDefs
		{
		    /*
		     * Process macros again...
		     */
		    ignore = FALSE;
		}
		| PUBLIC pubDefs
		{
		    ignore = FALSE;
		}
		;
globalDef	: globalSym ':' fulltype
		{
		    switch($1->type) {
			case SYM_PUBLIC:
			    /*
			     * Transform to the proper, undefined type of
			     * symbol.
			     */
			    switch($3->tn_type) {
				case TYPE_NEAR:
				    $1->type = SYM_PROC;
				    $1->u.proc.flags = SYM_NEAR;
				    $1->u.proc.locals = NULL;
				    break;
				case TYPE_FAR:
				    $1->type = SYM_PROC;
				    $1->u.proc.flags = 0;
				    $1->u.proc.locals = NULL;
				    break;
				default:
				    $1->type = SYM_VAR;
				    $1->u.var.type = $3;
				    break;
			    }
			    $1->u.addrsym.offset = 0;
			    $1->flags |= SYM_UNDEF;
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
				    $1->name);
			    yynerrs++;
			    break;
			default:
			    /*
			     * Make sure the type corresponds to the existing
			     * one.
			     */
			    switch($3->tn_type) {
				case TYPE_NEAR:
				    if (!Sym_IsNear($1)) {
					yyerror("%i: type mismatch: not a near procedure or label",
						$1->name);
					yynerrs++;
				    } 
				    break;
				case TYPE_FAR:
				    if (($1->type != SYM_LABEL &&
					 $1->type != SYM_PROC) ||
					Sym_IsNear($1))
				    {
					yyerror("%i: type mismatch: not a far procedure or label",
						$1->name);
					yynerrs++;
				    } 
				    break;
				default:
				{
				    TypePtr type;
				    
				    switch($1->type) {
					case SYM_VAR:
					    type = $1->u.var.type;
					    break;
					case SYM_INSTVAR:
					    type = $1->u.instvar.type;
					    break;
					case SYM_FIELD:
					    type = $1->u.field.type;
					    break;
					default:
					    type = NULL;
					    break;
				    }
				    if (!Type_Equal(type, $3)) {
					yyerror("%i: type mismatch",
						$1->name);
					yynerrs++;
				    }
				    break;
				}
			    }
#if 0
/* if symbol already exists, it is unlikely to be undefined, wot? */
			    $1->flags |= SYM_UNDEF;
#endif
			    break;
		    }
		}
		| globalSym ':' CHUNK chunktype
		{
		    if ($1->type == SYM_PUBLIC) {
			/*
			 * Transform to undefined chunk...
			 */
			if ((curSeg->u.segment.data->comb != SEG_LMEM) &&
			    (curSeg->u.segment.data->comb != SEG_GLOBAL))
			{
			    yyerror("%i: segment mismatch (chunk symbol can't be in non-lmem segment)",
				    $1->name);
			    yynerrs++;
			} else {
			    /*
			     * Switch the segment to be the heap part of the
			     * group so glue doesn't bitch. Note we only do
			     * this if not defining a chunk. If defining a
			     * chunk, we're already in the correct subsegment.
			     */
			    $1->type = SYM_CHUNK;
			    if (curChunk == NULL &&
				curSeg->u.segment.data->comb == SEG_LMEM)
			    {
				$1->segment = curSeg->u.segment.data->pair;
			    }
			    $1->flags = SYM_UNDEF|SYM_GLOBAL;
			    $1->u.chunk.common.offset = 0;
			    $1->u.chunk.handle = 0;
			    $1->u.chunk.type = $4;
			}
		    } else if ($1->type == SYM_CHUNK) {
			if (!Type_Equal($1->u.chunk.type, $4)) {
			    yyerror("%i: type mismatch",
				    $1->name);
			    yynerrs++;
			}
		    } else {
			yyerror("%i: type mismatch: not a chunk symbol",
				$1->name);
			yynerrs++;
		    }
		}
		| globalSym ':' LABEL FAR
		{
		    if ($1->type == SYM_PUBLIC) {
			/*
			 * Transform to undefined FAR label
			 */
			$1->type = SYM_LABEL;
			$1->flags = SYM_UNDEF|SYM_GLOBAL;
			$1->u.label.near = 0;
		    } else if ($1->type != SYM_LABEL || $1->u.label.near) {
			yyerror("%i: type mismatch: wasn't a far label before",
				$1->name);
			yynerrs++;
		    }
		}
		| globalSym ':' LABEL NEAR
		{
		    if ($1->type == SYM_PUBLIC) {
			/*
			 * Transform to undefined NEAR label
			 */
			$1->type = SYM_LABEL;
			$1->flags = SYM_UNDEF|SYM_GLOBAL;
			$1->u.label.near = TRUE;
		    } else if ($1->type != SYM_LABEL || !$1->u.label.near) {
			yyerror("%i: type mismatch: wasn't a near label before",
				$1->name);
			yynerrs++;
		    }
		}
		;
globalDefs	: globalDef
		| globalDefs flexiComma globalDef
		;
/*
 * Deal with IDENT's and all the types of symbol tokens we can get back
 * (MACEXEC is avoided by setting "ignore" in yystdlex). We don't object to
 * any bogus types, as that's taken care of by the globalDef rule.
 */
globalSym	: IDENT
		{
		    $$ = Sym_Enter($1, SYM_PUBLIC, curFile->name, yylineno);
		}
		| SYM
		{
		    $$ = $1;
		    $$->flags |= SYM_GLOBAL;
		    /*
		     * If symbol was previously declared within the global
		     * (nameless) segment, switch it to be this segment
		     * instead.
		     */
		    if ($$->segment->name == NullID) {
			$$->segment = curSeg;
		    }
		}
		| EXPR_SYM
		{
		    $$ = $1;
		    $$->flags |= SYM_GLOBAL;
		    /*
		     * If symbol was previously declared within the global
		     * (nameless) segment, switch it to be this segment
		     * instead.
		     */
		    if ($$->segment->name == NullID) {
			$$->segment = curSeg;
		    }
		}
		| CLASS_SYM
		{
		    $$ = $1;
		    $$->flags |= SYM_GLOBAL;
		    /*
		     * If symbol was previously declared within the global
		     * (nameless) segment, switch it to be this segment
		     * instead.
		     */
		    if ($$->segment->name == NullID) {
			$$->segment = curSeg;
		    }
		}
		| STRUCT_SYM
		| METHOD_SYM
		| MODULE_SYM
		| INSTVAR_SYM
		| TYPE_SYM
		| ETYPE_SYM
		| RECORD_SYM
		;
pubSym	    	: globalSym
		{
		    switch($1->type) {
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
				    $1->name);
			    yynerrs++;
			    break;
			default:
			    /*
			     * Anything else can safely be marked global.
			     */
			    $1->flags |= SYM_GLOBAL;
			    break;
		    }
		}
		;
pubDefs		: pubSym
		| pubDefs flexiComma pubSym
		;

/*****************************************************************************
 *
 *			   Type definitions
 *
 ****************************************************************************/
labeled_op	: IDENT STRUC
		{
		    if (inStruct) {
			yyerror("already defining %i; nested definitions not allowed",
				inStruct->name);
		    } else {
			inStruct = Sym_Enter($1, SYM_STRUCT);
		    }
		}
		| STRUCT_SYM STRUC
		{
		    if ($1->type != SYM_STRUCT) {
			yyerror("cannot redefine union %i", $1->name);
			yynerrs++;
		    } else if ($1->u.typesym.size == 0) {
			/*
			 * Structure was referenced before either by
			 * declaring it empty or by declaring something
			 * to be a pointer to it.
			 * Allow a true definition now. Set the segment
			 * of the symbol to match the current one, rather
			 * than the one where it was first used...
			 */
			inStruct = $1;
			$1->flags &= ~SYM_NOWRITE;
			$1->segment = curSeg;
		    } else {
			yyerror("cannot redefine structure %i", $1->name);
			yynerrs++;
		    }
		}
		| STRUCT_SYM ENDS
		{
		    if ($1 != inStruct) {
			if (inStruct) {
			    yyerror("cannot end struct/union %i while in %i",
				    $1->name, inStruct->name);
			} else {
			    yyerror("not defining any struct/union, so can't end %i",
				    $1->name);
			}
			yynerrs++;
		    } else {
			inStruct = NullSymbol;
		    }
		}
		| IDENT UNION
		{
		    inStruct = Sym_Enter($1, SYM_UNION);
		}
		| STRUCT_SYM UNION
		{
		    if ($1->type != SYM_UNION) {
			yyerror("cannot redefine structure %i", $1->name);
			yynerrs++;
		    } else if ($1->u.typesym.size == 0) {
			/*
			 * Union was referenced before either by
			 * declaring it empty or by declaring something
			 * to be a pointer to it.
			 * Allow a true definition now. Set the segment
			 * of the symbol to match the current one, rather
			 * than the one where it was first used...
			 */
			inStruct = $1;
			$1->flags &= ~SYM_NOWRITE;
			$1->segment = curSeg;
		    } else {
			yyerror("cannot redefine union %i", $1->name);
			yynerrs++;
		    }
		}
		| STRUCT_SYM END
		{
		    if ($1 != inStruct) {
			if (inStruct) {
			    yyerror("cannot end struct/union %i while in %i",
				    $1->name, inStruct->name);
			} else {
			    yyerror("not defining any struct/union, so can't end %i",
				    $1->name);
			}
			yynerrs++;
		    } else {
			inStruct = NullSymbol;
		    }
		}
	/*------------------------------------------------------------
	 *  	    	    	Records
	 *-----------------------------------------------------------*/
labeled_op	: IDENT RECORD recordDefs
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
		    SymbolPtr	sym = Sym_Enter($1, SYM_RECORD);
		    SymbolPtr	fld;

		    sym->u.record.first = $3;

		    if ($3) {
			int limit = ($3->u.bitField.offset +
				     $3->u.bitField.width);
			
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
			for (fld = $3;
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
		}
		| IDENT TYPE fulltype
		{
		    Sym_Enter($1, SYM_TYPE, $3);
		}
		;
recordDefs	: recordLineDef
		| recordMLineDef
		;
       /*
	* Single-line record definition. Fields are separated by commas
	* and must all appear on the same line (or with escaped newlines
	* between them)
	*/
recordLineDef	: recordField
		{
		    $1->u.bitField.common.next = NULL;
		    $$ = $1;
		}
		| recordField ',' recordLineDef
		{
		    $1->u.bitField.offset = $3->u.bitField.offset +
			$3->u.bitField.width;
		    $1->u.bitField.common.next = $3;
		    $$ = $1;
		}
		;
	/*
	 * Multi-line record definition. Fields are separated by newlines.
	 * End of definition is signalled with either IDENT END or just END.
	 * IDENT should be the name of the record, but this isn't enforced.
	 */
recordMLineDef	: multiEOL recordMLineBody { $$ = $2; }
		;
recordMLineBody	: recordFieldName END	    { $$ = NULL; }
		| recordField multiEOL recordMLineBody
		{
		    if ($3 != NULL) {
			$1->u.bitField.offset = $3->u.bitField.offset +
			    $3->u.bitField.width;
		    }
		    $1->u.bitField.common.next = $3;
		    $$ = $1;
		}
		| recordField ',' multiEOL recordMLineBody
		{
		    if ($4 != NULL) {
			$1->u.bitField.offset = $4->u.bitField.offset +
			    $4->u.bitField.width;
		    }
		    $1->u.bitField.common.next = $4;
		    $$ = $1;
		}
		;
	
	/*
	 * Individual field. With or without name, with or without value.
	 * Value is the BITFIELD symbol of the defined width but offset 0.
	 */
recordFieldName	: IDENT
		| /* nameless */ { $$ = NullID; }
		;
recordField	: recordFieldName ':' lexpr recordFieldVal
		{
		    $$ = Sym_Enter($1, SYM_BITFIELD, 0, $3,
				   CopyExprCheckingIfZero(&expr1),
				   (TypePtr)NULL);
		}
		| recordFieldName type ':' lexpr recordFieldVal
		{
		    $$ = Sym_Enter($1, SYM_BITFIELD, 0, $4,
				   CopyExprCheckingIfZero(&expr1), $2);
		}
		;
recordFieldVal	: '=' operand1
		{
		    /* Value left in expr1 */
		}
		| /* empty */
		{
		    /*
		     * Fields with no value default to 0
		     */
		    ResetExpr(&expr1, defElts1);
		    StoreExprConst(0);
		}
		;

	/*------------------------------------------------------------
	 *  	    	    Enumerated types
	 *-----------------------------------------------------------*/
etypeSize	: CAST
		| CONSTANT
		;
etypeFlags	: /* empty */
		{
		    $$ = 0;
		}
		| etypeFlags PROTOMINOR
		{
		    $$ = $1 | SYM_ETYPE_PROTOMINOR;
		    if (curProtoMinor != NullSymbol) {
			yywarning("protominor %i still active. Are you sure you want that?",
				  curProtoMinor->name);
		    }
		}
		;
etypeArgs   	: etypeFlags /* empty -- default to WORD size */
		{
		    $$.size = 2;
		    $$.start = 0;
		    $$.skip = 1;
		    $$.flags = $1;
		}
		| etypeFlags etypeSize
		{
		    $$.size = $2;
		    $$.start = 0;
		    $$.skip = 1;
		    $$.flags = $1;
		}
		| etypeFlags etypeSize flexiComma cexpr
		{
		    $$.size = $2;
		    $$.start = $4;
		    $$.skip = 1;
		    $$.flags = $1;
		}
		| etypeFlags etypeSize flexiComma cexpr flexiComma cexpr
		{
		    $$.size = $2;
		    $$.start = $4;
		    $$.skip = $6;
		    if ($6 == 0) {
			yywarning("are you sure you want a skip value of 0?");
		    }
		    $$.flags = $1;
		}
		;
labeled_op	: IDENT DEFETYPE etypeArgs
		{
		    Sym_Enter($1, SYM_ETYPE, $3.start, $3.skip, $3.size, 
			      $3.flags);
		}
		| IDENT ENUM ETYPE_SYM
		{
		    SymbolPtr e;

		    e = Sym_Enter($1, SYM_ENUM, $3, $3->u.eType.nextVal);
		    if ($3->u.eType.flags & SYM_ETYPE_PROTOMINOR) {
			e->u.econst.protoMinor = curProtoMinor;
		    }
		}
		| IDENT ENUM ETYPE_SYM flexiComma cexpr
		{
		    SymbolPtr e;

		    e = Sym_Enter($1, SYM_ENUM, $3, $5);
		    if ($3->u.eType.flags & SYM_ETYPE_PROTOMINOR) {
			e->u.econst.protoMinor = curProtoMinor;
		    }
		}
		| SYM ENUM ETYPE_SYM
		{
		    if ($1->type != SYM_ENUM) {
			yyerror("%i: type mismatch: wasn't an enum before",
				$1->name);
			yynerrs++;
		    } else {
			/*
			 * Let Sym_Enter worry about linkage etc.
			 */
			SymbolPtr e;

			e = Sym_Enter($1->name,SYM_ENUM, $3,
				      $3->u.eType.nextVal);
			if ($3->u.eType.flags & SYM_ETYPE_PROTOMINOR) {
			    e->u.econst.protoMinor = curProtoMinor;
			}
		    }
		}
		| SYM ENUM ETYPE_SYM flexiComma cexpr
		{
		    if ($1->type != SYM_ENUM) {
			yyerror("%i: type mismatch: wasn't an enum before",
				$1->name);
			yynerrs++;
		    } else {
			/*
			 * Let Sym_Enter worry about linkage etc.
			 */
			SymbolPtr e;

			e = Sym_Enter($1->name,SYM_ENUM, $3, $5);
			if ($3->u.eType.flags & SYM_ETYPE_PROTOMINOR) {
			    e->u.econst.protoMinor = curProtoMinor;
			}
		    }
		}
		;
			
/*
 * General type definition rule -- result is a TypePtr for the thing.
 * Note that Type_Struct is not limited to just SYM_STRUCT symbols, but
 * encompasses all structured types -- things with typesym data defined.
 * type is the type constructs that may be used to define data. This is
 * everything except the array constructor (the DUP operator) as the parser
 * can't tell until too late if the thing is a type or not, and even then
 * it can run into problems.
 */
fulltype	: lexpr DUP '(' fulltype ')'
		{
		    $$ = Type_Array($1, $4);
		}
		| type
		;
       /*
	* Simple length expression. Allows only simple arithmetic operators,
	* constants and numeric equates. Needed to avoid shift/reduce
	* conflicts caused by the empty first part of cexpr rule.
	*/
lexpr	    	: CONSTANT
		{
		    $$ = $1;
		}
		| EXPR_SYM
		{
		    ExprResult	result;

		    $$ = 0;
		    if (!Expr_Eval($1->u.equate.value, &result,
				   EXPR_NOUNDEF|EXPR_FINALIZE, NULL))
		    {
			yyerror((char *)result.type);
			yynerrs++;
		    } else if (result.type == EXPR_TYPE_CONST &&
			       !result.rel.sym)
		    {
			$$ = result.data.number;
		    } else {
			yyerror("equate %i is not constant", $1->name);
			yynerrs++;
		    }
		}
		| WIDTH SYM
		{
		    if ($2->type != SYM_BITFIELD) {
			yyerror("invalid operand of WIDTH (%i)", $2->name);
		    } else {
			$$ = $2->u.bitField.width;
			yynerrs++;
		    }
		}
		| WIDTH RECORD_SYM
		{
		    /*
		     * Width of a record is just the position of the last
		     * bit in the mask, which we can find by nuking all the
		     * preceding bits and calling ffs to find the remaining
		     * one.
		     */
		    word    m = $2->u.record.mask;
		    
		    $$ = ffs(m ^ (m >> 1));
		}
		| WIDTH error
		{
		    if (yychar == IDENT) {
			yyerror("%i not defined yet and cannot be forward-referenced here",
			    $<ident>2);
		    } else {
			yyerror("invalid operand of WIDTH");
		    }
		}
		| lexpr '+' lexpr   { $$ = $1 + $3; }
		| lexpr '-' lexpr   { $$ = $1 - $3; }
		| lexpr '*' lexpr   { $$ = $1 * $3; }
		| lexpr '/' lexpr
		{
		    if ($3 == 0) {
			yyerror("divide by 0");
			yynerrs++;
			$$ = 0;
		    } else {
			$$ = $1 / $3;
		    }
		}
		| lexpr MOD lexpr
		{
		    if ($3 == 0) {
			yyerror("mod by 0");
			yynerrs++;
			$$ = 0;
		    } else {
			$$ = $1 % $3;
		    }
		}
		| lexpr SHL lexpr
		{
		    $$ = $1 << $3;
		}
		| lexpr SHR lexpr
		{
		    $$ = $1 >> $3;
		}
		| '(' cexpr ')'
		{
		    $$ = $2;
		}
		;

optype		: STRUCT_SYM 	    	    { $$ = Type_Struct($1); }
		| ETYPE_SYM		    { $$ = Type_Struct($1); }
		| RECORD_SYM		    { $$ = Type_Struct($1); }
		| TYPE_SYM		    { $$ = Type_Struct($1); }
		| PTYPE		/* Pre-parsed type description */
		| CAST
		{
		     if ($1 == 0) {
		        $$ = Type_Char(1);
		    } else if ($1 == 'z') {
		        $$ = Type_Char(2);
		    } else {
			$$ = Type_Int($1);
		    }
		}
		| FAR 	    	    	    { $$ = Type_Far(); }
		| NEAR			    { $$ = Type_Near(); }
		| PNTR			    { $$ = Type_Ptr($1, Type_Void()); }
		;
type		: PNTR '.' fulltype	    { $$ = Type_Ptr($1, $3); }
		| PNTR '.' IDENT
		{
		    /*
		     * Assume it's a structure of some sort. Create a 0-sized
		     * SYM_STRUCT symbol for it -- Swat will know it's
		     * external if it has no fields...
		     */
		    SymbolPtr	ssym = Sym_Enter($3, SYM_STRUCT);

		    ssym->flags |= SYM_NOWRITE;
		    
		    $$ = Type_Ptr($1,Type_Struct(ssym));
		}
		| optype
		;
/******************************************************************************
 *
 * Rules to initialize and set which static expression variables to use (expr1,
 * expr2 or texpr).
 *
 *****************************************************************************/
setExpr1    	: /* empty */ { ResetExpr(&expr1, defElts1); } ;
setExpr2	: /* empty */ { ResetExpr(&expr2, defElts2); } ;
setTExpr	: /* empty */
		{
		    /*
		     * Save previous expression state and reset the temporary
		     * expression for our own use.
		     */
		    $<exprSave>$.curExpr = curExpr;
		    $<exprSave>$.curExprSize = curExprSize;
		    
		    ResetExpr(&texpr, defTElts);
		}
		;
operand1	: setExpr1 operand ;
operand2	: setExpr2 operand ;
foperand1	: setExpr1 foperand ;
foperand2	: setExpr2 foperand ;
cexpr		: setTExpr operand
		{
		    ExprResult	result;

		    $$ = 0;
		    
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
			$$ = 0;
		    } else if (result.type == EXPR_TYPE_CONST &&
			       !result.rel.sym)
		    {
			/*
			 * Use the value we got back
			 */
			$$ = result.data.number;
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
			    $$ = 0;
			} else {
			    $$ = result.data.str[0]|(result.data.str[1] << 8);
			}
		    } else {
			/*
			 * Expression valid but not constant -- choke.
			 */
			yyerror("constant expected");
			yynerrs++;
			$$ = 0;
		    }

		    /*
		     * Free any extra elements and go back to the
		     * interrupted expression.
		     */
		    RestoreExpr(&$1);
		}
		;
/******************************************************************************
 *
 * General operand rule -- should be invoked only from operand1 or operand2
 * or perhaps from an operandList rule
 *
 *****************************************************************************/
operand		: DWORDREG
		{
		    if (indir) {
			StoreExprReg(EXPR_EINDREG, $1);
		    } else {
			StoreExprReg(EXPR_DWORDREG, $1);
		    }
		}
		| WORDREG
		{
		    if (indir) {
			if ($1 != REG_BP && $1 != REG_SI && $1 != REG_DI &&
			    $1 != REG_BX)
			{
			    yyerror("illegal register for indirection");
			    yynerrs++;
			    /*  Fake a valid register to prevent Expr_Eval
				from dying. */
			    StoreExprReg(EXPR_INDREG, REG_SI);
			} else {
			    StoreExprReg(EXPR_INDREG, $1);
			}
		    } else {
			StoreExprReg(EXPR_WORDREG, $1);
		    }
		}
		| BYTEREG
		{
		    if (indir) {
			yyerror("cannot indirect through a byte-sized register");
			yynerrs++;
			/*  Fake a valid register to prevent Expr_Eval
			    from dying. */
			StoreExprReg(EXPR_INDREG, REG_SI);
		    } else {
			StoreExprReg(EXPR_BYTEREG, $1);
		    }
		}
		| SEGREG    	    	    { StoreExprReg(EXPR_SEGREG, $1); }
		| UNDEF
		{
		    /*
		     * Undefined things count as 0, since we don't do any sort
		     * of compression or object record stuff to isolate
		     * undefined regions...This probably shouldn't be
		     * allowed in a general expression, but it makes it easier
		     * in "def" if we do this here.
		     */
		    StoreExprConst(0);
		}
		| operand ':' operand 	{ StoreExprOp(EXPR_OVERRIDE); }
		| operand PTR operand
		{
		    StoreExprOp(EXPR_CAST);
		}
		| '{' type '}' { StoreExprType($2); } operand
		{
		    StoreExprOp(EXPR_CAST);
		}
		| optype    	    	    	    { StoreExprType($1); }
		| SHORT operand		    { StoreExprOp(EXPR_SHORT); }
		| RECORD_SYM STRUCT_INIT
		{
		    if ($1->u.record.first == NULL) {
			yyerror("cannot initialize record %i -- it has no fields",
				$1->name);
			free($2);
			YYERROR;
		    } else {
			Data_EncodeRecord($1, $2);
		    }
		}
		  '(' operand ')'
		{
		    free($2);
		}
		| '[' indir ']'
		| operand '[' indir ']'  	    { StoreExprOp(EXPR_PLUS); }
		| '[' indir ']' operand     	    { StoreExprOp(EXPR_PLUS); }
		| '(' operand ')'
		| STRING
		{
		    StoreExprString(EXPR_STRING, $1);
		    free($1);
		}
		| STRUCT_INIT
		{
		    StoreExprString(EXPR_INIT, $1);
		    free($1);
		}
		| MODULE_SYM	    	{ StoreExprSymbol($1); }
		| EXPR 	    	    	{ StoreSubExpr($1); }
		| EXPR_SYM  	    	{ StoreSubExpr($1->u.equate.value); }
		| METHOD_SYM
		{
		    /*
		     * Make sure it's accessible
		     */
		    if (!($1->u.method.flags & SYM_METH_PUBLIC) &&
			warn_private &&
			!CheckRelated(curClass, $1->u.method.class))
		    {
			yywarning("private method %i used outside class %i",
				  $1->name, $1->u.method.class->name);
		    }
		    StoreExprSymbol($1);
		}
		| INSTVAR_SYM
		{
		    /*
		     * Make sure it's accessible
		     */
		    if (! ($1->u.instvar.flags & SYM_VAR_PUBLIC) &&
			warn_private &&
			!CheckRelated(curClass, $1->u.instvar.class))
		    {
			yywarning("private instance variable %i used outside class %i",
				  $1->name, $1->u.instvar.class->name);
		    }
		    StoreExprSymbol($1);
		}
		| CLASS_SYM 	    	    	{ StoreExprSymbol($1); }
		| IDENT			    	{ StoreExprIdent($1); }
		| SYM 			    	{ StoreExprSymbol($1); }
		| DOT
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
		}
		| THIS type
		{
		    if ($2 == Type_Near() || $2 == Type_Far()) {
			StoreExprSymbol(Sym_Enter(NullID, SYM_LABEL, dot,
						  $2->tn_type==TYPE_NEAR));
		    } else {
			StoreExprSymbol(Sym_Enter(NullID, SYM_VAR, dot, $2));
		    }
		}
		| CONSTANT 		{ StoreExprConst($1); }
		| CONSTANT DOT
		{
		    /*
		     * Local label -- find the thing, if possible, else
		     * store IDENT
		     */
		    ID	    	id;
		    char    	buf[20];
		    SymbolPtr	sym;

		    sprintf(buf, "%d$", $1);
		    id = ST_EnterNoLen(output, symStrings, buf);
		    sym = Sym_Find(id, SYM_LOCALLABEL, FALSE);
		    if (sym != NULL) {
			StoreExprSymbol(sym);
		    } else {
			StoreExprIdent(id);
		    }
		}
		| operand SEGPART    	{ StoreExprOp(EXPR_SEGPART); }
		| operand OFFPART	{ StoreExprOp(EXPR_OFFPART); }
		| operand HIGHPART    	{ StoreExprOp(EXPR_HIGHPART); }
		| operand LOWPART	{ StoreExprOp(EXPR_LOWPART); }
		| SUPER operand	    	{ StoreExprOp(EXPR_SUPER); }
		| operand '+' operand 	{ StoreExprOp(EXPR_PLUS); }
		| operand '.' operand	{ StoreExprOp(EXPR_DOT); }
		| operand '-' operand	{ StoreExprOp(EXPR_MINUS); }
		| operand '*' operand	{ StoreExprOp(EXPR_TIMES); }
		| operand '/' operand	{ StoreExprOp(EXPR_DIV); }
		| operand MOD operand	{ StoreExprOp(EXPR_MOD); }
		| operand FLDMASK operand { StoreExprOp(EXPR_FMASK); }
		| '-' operand %prec UNARY	{ StoreExprOp(EXPR_NEG); }
		| '+' operand %prec UNARY	{ /* Do nothing */ }
		| NOT operand		{ StoreExprOp(EXPR_NOT); }
		| operand SHR operand	{ StoreExprOp(EXPR_SHR); }
		| operand SHL operand	{ StoreExprOp(EXPR_SHL); }
		| operand EQ operand	{ StoreExprOp(EXPR_EQ); }
		| operand NE operand	{ StoreExprOp(EXPR_NEQ); }
		| operand LT operand	{ StoreExprOp(EXPR_LT); }
		| operand LE operand	{ StoreExprOp(EXPR_LE); }
		| operand GT operand	{ StoreExprOp(EXPR_GT); }
		| operand GE operand	{ StoreExprOp(EXPR_GE); }
		| operand AND operand	{ StoreExprOp(EXPR_AND); }
		| operand OR operand	{ StoreExprOp(EXPR_OR); }
		| operand XOR operand	{ StoreExprOp(EXPR_XOR); }
		| HIGH operand		{ StoreExprOp(EXPR_HIGH); }
		| LOW operand		{ StoreExprOp(EXPR_LOW); }
		| SEG operand		{ StoreExprOp(EXPR_SEG); }
		| SEGMENT operand   	{ StoreExprOp(EXPR_SEG); }
		| SEGREGOF operand   	{ StoreExprOp(EXPR_SEGREGOF); }
		| VSEG operand	    	{ StoreExprOp(EXPR_VSEG); }
		| OFFSET operand	{ StoreExprOp(EXPR_OFFSET); }
		| TYPE operand		{ StoreExprOp(EXPR_TYPEOP); }
		| LENGTH operand	{ StoreExprOp(EXPR_LENGTH); }
		| SIZE operand		{ StoreExprOp(EXPR_SIZE); }
		| WIDTH operand		{ StoreExprOp(EXPR_WIDTH); }
		| MASK operand		{ StoreExprOp(EXPR_MASK); }
		| FIRST operand		{ StoreExprOp(EXPR_FIRST); }
		| DOTTYPE operand    	{ StoreExprOp(EXPR_DOTTYPE); }
		| HANDLE operand    	{ StoreExprOp(EXPR_HANDLE); }
		| RESID operand	    	{ StoreExprOp(EXPR_RESID); }
		| ENUM operand		{ StoreExprOp(EXPR_ENUM); }
		;
foperand	: ST {StoreExprFloatStack(0L);}
		| ST '(' CONSTANT ')' {StoreExprFloatStack($3);}
		| operand
		;
indir		: indirStart operand {indir=0; StoreExprOp(EXPR_INDIRECT); } 
		| indirStart error {indir = 0; } 
		;
indirStart	: {indir = 1; } ;

/******************************************************************************
 *
 *		      SEGMENT/GROUP DEFINITIONS
 *
 *****************************************************************************/
	/*
	 * Segment bindings. These things are kept in the three 'segments'
	 * arrays in the three temporary expression records.
	 */
op	    	: assume assumeArgs
		{
		    Scan_DontUseOpProc($1);
		}
		| assume error
		{
		    Scan_DontUseOpProc($1);
		}
		| assume NOTHING
		{
		    int	    i;

		    for (i = NumElts(exprs)-1; i >= 0; i--) {
			bzero(exprs[i]->segments, sizeof(exprs[i]->segments));
		    }
		    
		    Scan_DontUseOpProc($1);
		}
		;
assume		: ASSUME
		{
		    $$ = Scan_UseOpProc(findSegToken);
		}
		;
assumeSegSegOp	: SEGMENT | SEG ;
assumeSeg	: MODULE_SYM
		| NOTHING { $$ = NullSymbol; }
		| IDENT
		{
		    if (makeDepend) {
			/*
			 * If creating dependencies, ignore undefined
			 * segments, as they might be defined in a .rdef
			 * file...which will go away eventually, but until
			 * it does, it's really annoying.
			 */
			$$ = NullSymbol;
		    } else {
			yyerror("%i is neither a segment nor a group", $1);
			YYERROR;
		    }
		}
		| assumeSegSegOp operand1
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
			$$ = result.rel.frame;
		    }
		}
		;
assumeArg	: SEGREG ':' assumeSeg
		{
		    /*
		     * Bind the segment symbol to the register in all the
		     * temporary expressions. SEGREG gives us a number from
		     * 0 to 5...
		     */
		    int	    i;

		    for (i = NumElts(exprs)-1; i >= 0; i--) {
			exprs[i]->segments[$1] = $3;
		    }
		}
		;
assumeArgs	: assumeArg
		| assumeArgs flexiComma assumeArg
		;
segment		: SEGMENT
		{
		    $$ = Scan_UseOpProc(findSegToken);
		}
		;
optComma    	: ',' | /* empty */ ;
lmemSegDef	: IDENT segment LMEM optComma
		{
		    /*
		     * Declaration of a segment as an LMem group whose
		     * data are (possibly) defined in a different object
		     * file. We need to have LMem create the segments
		     * but not fill them in.
		     */
		    Scan_DontUseOpProc($2);

		    if (ParseIsLibName($1)) {
			yyerror("cannot create a non-library segment whose name matches the permanent name of this library");
			$$ = NullSymbol;
		    } else {
			$$ = LMem_CreateSegment($1);
		    }
		}
		| MODULE_SYM segment LMEM optComma
		{
		    Scan_DontUseOpProc($2);

		    if (($1->type != SYM_GROUP) ||
			($1->u.group.nSegs != 2) ||
			($1->u.group.segs[0]->u.segment.data->comb!=SEG_LMEM)||
			($1->u.group.segs[1]->u.segment.data->comb!=SEG_LMEM))
		    {
			yyerror("cannot redefine segment %i as an lmem segment",
				$1->name);
			yynerrs++;
			$$ = NullSymbol;
		    } else {
			$$ = $1;
		    }
		}
		;
labeled_op	: IDENT segment segAttrs
		{
		    Scan_DontUseOpProc($2);

		    if (!ParseIsLibName($1)) {
			PushSegment(Sym_Enter($1, SYM_SEGMENT, $3.comb,
					      $3.align, $3.class));
		    } else if ($3.comb != SEG_LIBRARY) {
			yyerror("cannot create a non-library segment whose name matches the permanent name of this library");
		    } else {
			/*
			 * When defining symbols for this library, always
			 * enter the global scope, thereby exiting any library
			 * segment scopes we might be in currently.
			 */
			PushSegment(global);
		    }
		}
		| lmemSegDef cexpr flexiComma cexpr flexiComma cexpr
		{
		    /*
		     * Create an LMem segment. $2 is the segment type.
		     * $4 is the flags for the segment. $6 is the extra
		     * free space requested.
		     */
		    if ($1 != NullSymbol) {
			LMem_InitSegment($1, $2, $4, $6);
		    }
		}
		| lmemSegDef cexpr flexiComma cexpr
		{
		    /*
		     * Create an LMem segment. $2 is the segment type.
		     * $4 is the flags for the segment.
		     */
		    if ($1 != NullSymbol) {
			LMem_InitSegment($1, $2, $4, 0);
		    }
		}
		| lmemSegDef cexpr
		{
		    /*
		     * Like above, except defaults flags to 0, since
		     * for now, none of them should be set anyway :)
		     */

		    if ($1 != NullSymbol) {
			LMem_InitSegment($1, $2, 0, 0);
		    }
		}
		| lmemSegDef
		{
		    /*
		     * Push to the data portion of the group to allow the
		     * user to continue entering data or to add chunks or
		     * whatever.
		     */
		    if ($1 != NullSymbol) {
			PushSegment($1->u.group.segs[0]);
		    }
		}
		| MODULE_SYM segment AT cexpr
		{
		    if (($1->type != SYM_SEGMENT) ||
			($1->u.segment.data->comb != SEG_ABSOLUTE))
		    {
			yyerror("cannot redefine %i as an absolute segment",
				$1->name);
			yynerrs++;
		    }
		    Scan_DontUseOpProc($2);
		    PushSegment($1); /* XXX */
		}
		| IDENT segment AT cexpr
		{
		    Scan_DontUseOpProc($2);
		    if (ParseIsLibName($1)) {
			yyerror("cannot create a non-library segment whose name matches the permanent name of this library");
		    } else {
			PushSegment(Sym_Enter($1, SYM_SEGMENT, SEG_ABSOLUTE,
					      $4));
		    }
		}
		| MODULE_SYM segment segAttrs
		{
		    Scan_DontUseOpProc($2);
		    
		    if ($1->type == SYM_GROUP) {
			/*
			 * User only allowed to do this for LMem segments,
			 * which are groups masquerading as segments. 
			 * An LMem segment (group) may only have two segment
			 * elements and both must be marked as LMem segments.
			 * Anything else is a faux pas.
			 */
			if (($1->u.group.nSegs != 2) ||
			    ($1->u.group.segs[0]->u.segment.data->comb!=SEG_LMEM) ||
			    ($1->u.group.segs[1]->u.segment.data->comb!=SEG_LMEM))
			{
			    yyerror("%i is not a segment", $1->name);
			    yynerrs++;
			} else {
			    /*
			     * Switch to the data segment of the LMem group,
			     * since not w/in a chunk.
			     */
			    PushSegment($1->u.group.segs[0]);
			}
		    } else if ($1->type != SYM_SEGMENT) {
			yyerror("%i is not a segment", $1->name);
			yynerrs++;
		    } else {
			/*
			 * Check each type of attribute for conflicts with
			 * existing ones. An attribute was given if it is
			 * non-zero in the segAttrs semantic value.
			 */
			if ($3.comb) {
			    if ($1->u.segment.data->comb &&
				($1->u.segment.data->comb != $3.comb))
			    {
				yyerror("inconsistent combine types for %i",
					$1->name);
				yynerrs++;
			    } else if ($3.comb == SEG_LMEM) {
				yyerror("lmem segments must be denoted as such when first declared");
				yynerrs++;
			    } else {
				$1->u.segment.data->comb = $3.comb;
			    }
			}
			if ($3.align) {
			    if ($1->u.segment.data->align &&
				($1->u.segment.data->align != $3.align))
			    {
				yyerror("inconsistent alignments for %i",
					$1->name);
				yynerrs++;
			    } else {
				$1->u.segment.data->align = $3.align;
			    }
			}
			if ($3.class) {
			    if ($1->u.segment.data->class &&
				$1->u.segment.data->class != $3.class)
			    {
				yyerror("inconsistent classes for %i",
					$1->name);
				yynerrs++;
			    } else {
				$1->u.segment.data->class = $3.class;
			    }
			}
			/*
			 * Enter into the segment.
			 */
			PushSegment($1);
		    }
		}
	        ;
/*
 * Segment attribute defintions
 */
segAttrs	: /* empty */
		{
		    /*
		     * Initialize our return value; this always gets reduced
		     * first.
		     */
		    $$.align = $$.comb = 0; $$.class = NullID;
		    $$.flags = 0;
		}
		| segAttrs segAttr
		{
		    $$ = $1;
		    if ($1.flags & $2.flags) {
			yyerror("duplicate definition of segment %s attribute",
				$2.flags == SA_COMBINE ? "combine type" :
				($2.flags == SA_ALIGNMENT ? "alignment" :
				 "class"));
		    } else {
			/*
			 * Copy appropriate value from $2 into final value.
			 */
			switch ($2.flags) {
			case SA_COMBINE:
			    $$.comb = $2.comb;
			    break;
			case SA_ALIGNMENT:
			    $$.align = $2.align;
			    break;
			case SA_CLASS:
			    $$.class = $2.class;
			    break;
			}
			$$.flags |= $2.flags;
		    }
		}
		;
segAttr		: ALIGNMENT
		{
		    $$.align = $1; $$.flags = SA_ALIGNMENT;
		}
		| COMBINE
		{
		    $$.comb = $1; $$.flags = SA_COMBINE;
		}
		| STRING
		{
		    $$.class = ST_EnterNoLen(output, permStrings, $1);
		    $$.flags = SA_CLASS;
		    free($1);
		}
		;

labeled_op	: MODULE_SYM ENDS
		{
		    if ($1->type == SYM_GROUP) {
			/*
			 * User only allowed to do this for LMem segments,
			 * which are groups masquerading as segments. 
			 * An LMem segment (group) may only have two segment
			 * elements and both must be marked as LMem segments.
			 * Anything else is a faux pas.
			 */
			if (($1->u.group.nSegs != 2) ||
			    ($1->u.group.segs[0]->u.segment.data->comb!=SEG_LMEM) ||
			    ($1->u.group.segs[1]->u.segment.data->comb!=SEG_LMEM))
			{
			    yyerror("%i is not a segment", $1->name);
			    yynerrs++;
			} else if ((curSeg != $1->u.group.segs[0]) &&
				   (curSeg != $1->u.group.segs[1]))
			{
			    yyerror("%i is not current segment (%i is)",
				    $1->name, curSeg->name);
			    yynerrs++;
			} else {
			    PopSegment();
			}
		    } else if ($1->type != SYM_SEGMENT) {
			yyerror("%i is not a segment", $1->name);
			yynerrs++;
		    } else if ($1 != curSeg) {
			yyerror("%i is not the current segment (%i is)",
				$1->name, curSeg->name);
			yynerrs++;
		    } else {
			PopSegment();
		    }
		}
		| IDENT ENDS
		{
		    if (!ParseIsLibName($1)) {
			yyerror("cannot end segment/structure %i as it doesn't exist", $1);
			yynerrs++;
		    } else if (curSeg != global || segStack == NULL) {
			yyerror("%i is not the current segment (%i is)",
				$1, curSeg->name);
			yynerrs++;
		    } else {
			/*
			 * Get out of the global scope we entered when we
			 * were asked to enter the <this_library_name> segment
			 */
			PopSegment();
		    }
		}
		| IDENT GROUP { $<sym>$=Sym_Enter($1,SYM_GROUP,0); } groupList
		| MODULE_SYM GROUP
		{
		    if ($1->type != SYM_GROUP) {
			yyerror("%i is not a group", $1->name);
			yynerrs++;
		    }
		    $<sym>$ = $1; /* Pass to groupList even if bogus */
		}
		  groupList
		;
		/*
		 * List of segments (possibly not-yet-defined) to add to
		 * group. Group symbol brought in from enclosing rule (see
		 * above) and propagated as the rule's semantic value.
		 * Need to check for the group symbol actually being a group
		 * symbol to handle the case of using a segment
		 * symbol in the MODULE_SYM GROUP rule, above.
		 */
groupElement	: IDENT
		{
		    $$ = Sym_Enter($1, SYM_SEGMENT,0,0,0);
		}
		| MODULE_SYM
		{
		    if ($1->type != SYM_SEGMENT) {
			yyerror("%i is not a segment", $1->name);
			yynerrs++;
		    }
		    $$ = $1;
		}
		| SEG SYM
		{
		    $$ = $2->segment;
		}
		;
groupList	: groupElement
		{
		    /*
		     * Propagate the group symbol to the $1 position for later
		     * incarnations of this rule
		     */
		    $$ = $<sym>0;
		    if ($$->type == SYM_GROUP) {
			Sym_AddToGroup($$, $1);
		    }
		}
		| groupList flexiComma groupElement
		{
		    $$ = $1;	/* Propagate */
		    if ($$->type == SYM_GROUP) {
			Sym_AddToGroup($$, $3);
		    }
		}
		;

		    
		    
		    
/******************************************************************************
 *
 *			     Object rules
 *
 *****************************************************************************/
/*
 * Add in class keyword table so "default" can be specified as a method.
 */
method		: METHOD
		{
		    $$ = Scan_UseOpProc(findClassToken);
		}
		;
methodStatic	: STATIC    	    { $$ = OBJ_STATIC; }
		| PRIVATE STATIC    { $$ = OBJ_PRIVSTATIC; }
		| STATIC PRIVATE    { $$ = OBJ_PRIVSTATIC; }
		| DYNAMIC	    { $$ = OBJ_DYNAMIC; }
		| /* empty */	    { $$ = OBJ_DYNAMIC_CALLABLE; }
		;

methodDecl	: method methodStatic
		{
		    $$ = $1;
		    methFlags = $2;
		}
		| method GLOBAL { ignore = FALSE; } methodStatic
		{
		    $$ = $1;
		    methFlags = OBJ_EXTERN | $4;
		}
		;
/*
 * Method handlers
 */
labeled_op	: IDENT methodDecl CLASS_SYM
		{
		    EnterProc(Sym_Enter($1, SYM_PROC, dot, 0));
		    /*
		     * If marked external, it needs to be made global so it
		     * will link successfully with the module that has the
		     * class record.
		     */
		    if (methFlags & OBJ_EXTERN) {
			curProc->flags |= SYM_GLOBAL;
		    }
		    EnterClass($3);
		    /*
		     * Create expression for use by Obj_EnterHandler.
		     */
		    ResetExpr(&expr1, defElts1);
		    StoreExprSymbol(curProc);
		}
		  flexiComma methodList procUsesArgs
		{
		    Scan_DontUseOpProc($2);
		}
		| IDENT methodDecl error
		{
		    /*
		     * Generate special messages if given an identifier (class
		     * not defined) or something symbol other than a class
		     * (symbol not a class). Anything else we leave as a generic
		     * parse error.
		     */
		    if (yychar == IDENT) {
			yyerror("class %i not defined", $<ident>3);
			yynerrs++;
		    } else if (yychar > FIRSTSYM && yychar < LASTSYM) {
			yyerror("%i not a class", $<sym>3->name);
			yynerrs++;
		    }
		    Scan_DontUseOpProc($2);
		}
		| SYM methodDecl CLASS_SYM
		{
		    CheckAndSetLabel(SYM_PROC, $1, 0);
		    /*
		     * Prepare for creating expression for use by
		     * Obj_EnterHandler.
		     */
		    ResetExpr(&expr1, defElts1);
		    if ($1->type != SYM_PROC) {
			yyerror("%i cannnot be a method handler as it's not a procedure",
				$1->name);
			yynerrs++;
			/*
			 * Tell methodList not to do anything.
			 */
			curExpr = NULL;
		    } else {
			EnterProc($1);
			EnterClass($3);
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
		}
		 flexiComma methodList procUsesArgs
		{
		    Scan_DontUseOpProc($2);
		}
		| SYM methodDecl error
		{
		    /*
		     * Generate special messages if given an identifier (class
		     * not defined) or something symbol other than a class
		     * (symbol not a class). Anything else we leave as a generic
		     * parse error.
		     */
		    if (yychar == IDENT) {
			yyerror("class %i not defined", $<ident>3);
			yynerrs++;
		    } else if (yychar > FIRSTSYM && yychar < LASTSYM) {
			yyerror("%i not a class", $<sym>3->name);
			yynerrs++;
		    }
		    Scan_DontUseOpProc($2);
		}
		| CLASS CLASS_SYM
		{
		    /*
		     * Make the current procedure into a "friend" of the given
		     * class, to use the C++ term. This allows it to access
		     * private methods and instance variables of the class
		     * without getting a warning.
		     */
		    if (curProc == NULL) {
			yyerror("friend declaration for %i must be inside a procedure",
				$2->name);
			yynerrs++;
		    } else if (curClass && curClass != $2) {
			yyerror("%i is already bound to class `%i'",
				curProc->name, curClass->name);
			yynerrs++;
		    } else {
			EnterClass($2);
			defClass = FALSE;
		    }
		}
		;
op		: methodDecl extMethodSym flexiComma CLASS_SYM
		{
		    $<extMeth>$.curProc = curProc;
		    $<extMeth>$.curClass = curClass;
		    curClass = $4;
		    curProc = $2;
		    /*
		     * Create expression for use by Obj_EnterHandler.
		     */
		    ResetExpr(&expr1, defElts1);
		    StoreExprSymbol(curProc);
		}
		  flexiComma methodList
		{
		    curClass = $<extMeth>5.curClass;
		    curProc = $<extMeth>5.curProc;
		    Scan_DontUseOpProc($1);
		}
		| methodDecl error 
		{
		    Scan_DontUseOpProc($1);
		}
		;

extMethodSym	: SYM
		{
		    /*
		     * Make sure the specified method is a far procedure.
		     */
		    if ($1->type != SYM_PROC || Sym_IsNear($1))
		    {
			yyerror("methods must be FAR procedures");
			yynerrs++;
			YYERROR;
		    } else {
			$$ = $1;
		    }
		}
		| IDENT
		{
		    /*
		     * Manufacture an undefined far SYM_PROC symbol for the
		     * thing...
		     */
		    $$ = Sym_Enter($1, SYM_PUBLIC, curFile->name, yylineno);
		    $$->type = SYM_PROC;
		    $$->u.proc.flags = 0;
		    $$->u.proc.locals = NULL;
		    $$->u.addrsym.offset = 0;
		    $$->flags |= SYM_UNDEF;
		    $$->segment = global;
		}
		;

methodList	: methodListItem
		| methodList flexiComma methodListItem
		;
methodListItem 	: METHOD_SYM
		{
		    if (curExpr) {
			if (!CheckRelated(curClass, $1->u.method.class)) {
			    yywarning("%i is not a valid method for %i",
				      $1->name, curClass->name);
			}

			if (curClass->flags & SYM_UNDEF) {
			    if (!(methFlags & OBJ_EXTERN)) {
				yyerror("class record for %i is not defined yet",
					curClass->name);
				yynerrs++;
			    }
			} else {
			    Obj_EnterHandler(curClass, curProc, $1, curExpr,
					     methFlags & OBJ_STATIC_MASK);
			}
		    }
		}
		| DEFAULT
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
		}
		| RELOC
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
		}
		| error
		{
		    /*
		     * Elaborate a bit if the method constant isn't defined.
		     */
		    if (yychar == IDENT) {
			yyerror("message %i not defined", $<ident>1);
			yyclearin;
		    }
		}
		;

labeled_op	: SYM ENDM
		{
		    if (curProc != $1) {
			if (curProc == NULL) {
			    yyerror("ENDM for %i is outside of any method",
				    $1->name);
			} else {
			    yyerror("ENDM for %i is inside %i",
				    $1->name, curProc->name);
			}
			yynerrs++;
		    } else if (curClass == NULL) {
			yyerror("ENDM for non-method %i", $1->name);
			yynerrs++;
		    } else {
			/*
			 * Reset procedure-specific state variables
			 */
			EndProc(curProc->name);
		    }
		}
		| IDENT ENDM
		{
		    yyerror("method %i not defined, so can't be ended", $1);
		    yynerrs++;
		}
		;
/*
 * Class declaration
 */
labeled_op	: IDENT CLASS
		{
		    $<number>$ = classProc;
		    classProc = Scan_UseOpProc(findClassToken);
		}
		  classDeclArgs
		{
		    if (curClass) {
			yyerror("nested class declarations are not allowed (in %i now)",
				curClass->name);
			yynerrs++;
			Scan_DontUseOpProc(classProc);
			classProc = $<number>3;
		    } else if ($4.class != (SymbolPtr)1) {
			EnterClass(Obj_DeclareClass($1, $4.class, $4.flags));
			defClass = TRUE;
			isPublic = FALSE;

			/*
			 * Since we're declaring a new class, we have to
			 * reset the protominor symbol
			 */
			curProtoMinor = NullSymbol;
		    }
		}
		| CLASS_SYM CLASS
		{
		    $<number>$ = classProc;
		    classProc = Scan_UseOpProc(findClassToken);
		}
		  classDeclArgs
		{
		    if ((($1->flags & SYM_UNDEF) == 0) ||
			($1->u.class.instance != NULL))
		    {
			yyerror("class %i is already defined", $1->name);
			yynerrs++;
			Scan_DontUseOpProc(classProc);
			classProc = $<number>3;
		    } else if (curClass) {
			yyerror("nested class declarations are not allowed (in %i now)",
				curClass->name);
			yynerrs++;
			Scan_DontUseOpProc(classProc);
			classProc = $<number>3;
		    } else if ($4.class != (SymbolPtr)1) {
			EnterClass(Obj_DeclareClass($1->name, $4.class,
						    $4.flags));
			defClass = TRUE;
			isPublic = FALSE;
		    }
		}
		;
classDeclArgs	: CLASS_SYM
		{
		    if ($1->u.class.data->flags & SYM_CLASS_FORWARD) {
			yyerror("%i must be defined before it can be used as a superclass.", 
				$1->name);
			YYERROR;
		    }
		    $$.class = $1;
		    $$.flags = 0;
		}
		| CONSTANT
		{
		    /*
		     * Class with no super class. NOTE: This is *only* for
		     * MetaClass, hence it accepts neither "master" nor
		     * "variant".
		     */
		    if ($1 != 0) {
			yyerror("superclass must be another class or 0");
			yynerrs++;
		    }
		    $$.class = NULL;
		    $$.flags = 0;
		}
		| CLASS_SYM flexiComma MASTER
		{
		    $$.class = $1;
		    $$.flags = SYM_CLASS_MASTER;
		}
		| CLASS_SYM flexiComma VARIANT
		{
		    /*
		     * By definition, a variant class must be the beginning
		     * of a group, so it must be a master class.
		     */
		    $$.class = $1;
		    $$.flags = SYM_CLASS_MASTER | SYM_CLASS_VARIANT;
		}
		| CLASS_SYM flexiComma MASTER flexiComma VARIANT
		{
		    $$.class = $1;
		    $$.flags = SYM_CLASS_MASTER | SYM_CLASS_VARIANT;
		}
		| CLASS_SYM flexiComma VARIANT flexiComma MASTER
		{
		    $$.class = $1;
		    $$.flags = SYM_CLASS_MASTER | SYM_CLASS_VARIANT;
		}
		| error
		{
		    if (yychar == '\n' ||
			yychar == MASTER ||
			yychar == VARIANT)
		    {
			yyerror("class declaration missing superclass");
		    } else {
			yyerror("superclass must be another class or 0");
		    }
		    $$.class = (SymbolPtr)1;
		    $$.flags = 0;
		}
		;
	/*
	 * Method declaration
	 */
methodFlags	: PRIVATE
		{
		    $$ = 0;
		}
		| CPUBLIC
		{
		    $$ = SYM_METH_PUBLIC;
		}
		| /* empty */
		{
		    /*
		     * A method is public unless explicitly designated as
		     * private.
		     */
		    $$ = SYM_METH_PUBLIC;
		}
		;
labeled_op	: IDENT method methodFlags
		{
		    if (!defClass) {
			yyerror("MESSAGE declaration for %i not inside class declaration",
				$1);
			yynerrs++;
		    } else {
			SymbolPtr methodSym;
			Obj_CheckMessageBounds(curClass);
			methodSym = Sym_Enter($1, SYM_METHOD, curClass, $3);

			/*
			 * Point the new message's protominor pointer at
			 * the current protominor symbol.
			 */

			methodSym->u.method.common.protoMinor = curProtoMinor;
		    }
		    Scan_DontUseOpProc($2);
		}
		/*
		 * Deal with exported method ranges...
		 */
		| IDENT method rangeSym
		{
		    if ($3->type == SYM_METHOD) {
			/*
			 * 1.X-style exported message range
			 */
			SymbolPtr   class = $3->u.method.class;
			SymbolPtr   methods = class->u.class.data->methods;
			SymbolPtr   methodSym;
			int 	    offset;
			
			/*
			 * Switch counter for the Methods enumerated type to be
			 * that of the indicated method plus its current offset,
			 * then up the offset by one in case there's a next
			 * time.
			 */
			offset = ($3->u.method.flags & SYM_METH_RANGE_LENGTH) >>
			    SYM_METH_RANGE_LENGTH_OFFSET;
			
			methods->u.eType.nextVal =
			    $3->u.method.common.value + offset;
			
			$3->u.method.flags =
			    ($3->u.method.flags & ~SYM_METH_RANGE_LENGTH) |
				((offset+1) << SYM_METH_RANGE_LENGTH_OFFSET);
			
			methodSym = Sym_Enter($1, SYM_METHOD, class, SYM_METH_PUBLIC);
			methodSym->u.method.common.protoMinor = curProtoMinor;

		    } else {
			SymbolPtr	range;
			
			range = Sym_Find($3->name, SYM_METHOD, FALSE);
			
			if (range == NullSymbol) {
			    yyerror("%i is not an exported message range, so you cannot import %i into it",
				    $3->name, $1);
			} else if ($3->u.eType.nextVal ==
				   (range->u.method.common.value +
				    ((range->u.method.flags & SYM_METH_RANGE_LENGTH) >>
				     SYM_METH_RANGE_LENGTH_OFFSET)))
			{
			    yyerror("too many messages imported into %i", range->name);
			} else {
			    SymbolPtr   class = range->u.method.class;
			    SymbolPtr   msg;
			    
			    msg = Sym_Enter($1, SYM_ENUM, $3,
					    $3->u.eType.nextVal);
			    
			    msg->type = SYM_METHOD;
			    msg->u.method.common.protoMinor = curProtoMinor;
			    msg->u.method.class = class;
			    msg->u.method.flags = SYM_METH_PUBLIC;
			}
		    }
		    Scan_DontUseOpProc($2);
		}
		/* Note that we don't have to have an "error" rule here, as
		 * the Scan_DontUseOpProc is taken care of in the
		 * IDENT methodDecl error rule for dealing with a hosed
		 * message handler declaration */
		;
rangeSym	: ETYPE_SYM
		| METHOD_SYM
		{
		    if (geosRelease >= 2) {
			yyerror("%i is not an exported message range.",
				$1->name);
			YYERROR;
		    } else {
			$$ = $1;
		    }
		}
		| IDENT
		{
		    /*
		     * See if this thing is an exported message range by looking
		     * explicitly for a SYM_METHOD symbol of the same name.
		     */
		    $$ = Sym_Find($1, SYM_METHOD, FALSE);
		    if ($$ != NullSymbol) {
			/*
			 * It is indeed. Create the appropriate enumerated
			 * type, starting at the value bound to the METHOD
			 * symbol, increasing by 1, and taking 2 bytes to
			 * hold it.
			 */
			$$ = Sym_Enter($1, SYM_ETYPE, $$->u.method.common.value,
				       1, 2, 0);
		    } else {
			yyerror("%i is not an exported message range.", $1);
			YYERROR;
		    }
		}
		;
labeled_op  	: IDENT VARDATA vardataType
		{
		    if (!curClass || !defClass) {
			yyerror("VarData can only be declared while declaring a class");
		    } else {
			SymbolPtr varSym;
			Obj_CheckVarDataBounds(curClass);
			varSym = Sym_Enter($1, SYM_VARDATA,
					curClass->u.class.data->vardata,
					curClass->u.class.data->vardata->u.eType.nextVal,
					$3);
			/*
			 * Point the new vardata's protominor pointer at
			 * the current protominor symbol.
			 */
			varSym->u.varData.common.protoMinor = curProtoMinor;
		    }
		}
		;
vardataType	: /* nothing */ { $$ = (TypePtr)NULL; }
		| fulltype
		;

labeled_op  	: PROTOMINOR protoMinorSym
		{
                    curProtoMinor = $2;
                }
                ;

protoMinorSym   : PROTOMINOR_SYM
                {
                    $$ = $1;
                }
                | IDENT
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
                    curProtoMinor = Sym_Enter($1, SYM_PROTOMINOR);
                    curProtoMinor->flags |= SYM_GLOBAL|SYM_UNDEF;
                    $$ = curProtoMinor;

                    /*
		     * Clean up the segment stack if we had to use a
		     * bogus segment.
		     */
                    if (curSeg == protoMinorSymbolSeg) {
			PopSegment();
		    }
                }
		;

labeled_op  	: PROTORESET
		{
                    curProtoMinor = NullSymbol;
                }
		;

	/*
	 * Special pseudo-ops that appear on a line by themselves and
	 * are only valid inside class declarations
	 */
op		: CPUBLIC
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
		}
		| CPUBLIC cpubDefs
		;
cpubDef		: INSTVAR_SYM
		{
		    $1->u.instvar.flags |= SYM_VAR_PUBLIC;
		}
		| error
		{
		    switch(yychar) {
			case IDENT:
			    /*
			     * Assume "public" came too soon.
			     */
			    yyerror("instance variable %i not defined yet",
				    $<ident>1);
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
				    $<sym>1->name);
			    break;
		    }
		    /*
		     * Biff the erroneous token and move on to the next element
		     * in the list by allowing errors to happen.
		     */
		    yyclearin;
		    yyerrok;
		}
		;
cpubDefs	: cpubDef
		| cpubDefs flexiComma cpubDef
		;
nrDef		: operand1
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
		    
		}
		| operand1 '(' operand2 ')'
		{
		    if ((expr1.numElts != 2) ||
			(expr1.elts[0].op != EXPR_SYMOP) ||
			(expr1.elts[1].sym->type != SYM_VARDATA))
		    {
			yyerror("this form of noreloc operand requires a defined vardata type before the parenthesized field that's not to be relocated");
		    } else {
			Obj_NoReloc(curClass, expr1.elts[1].sym, &expr2);
		    }
		}
		| error
		{
		    switch(yychar) {
			case IDENT:
			    /*
			     * Assume "noreloc" came too soon.
			     */
			    yyerror("instance variable %i not defined yet",
				    $<ident>1);
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
				    $<sym>1->name);
			    break;
		    }
		    /*
		     * Biff the erroneous token and move on to the next element
		     * in the list by allowing errors to happen.
		     */
		    yyclearin;
		    yyerrok;
		}
		;
nrDefs		  : nrDef
		| nrDefs flexiComma nrDef
		;
op		: NORELOC nrDefs
		;
		/*
		 * These next few are only returned inside a class declaration
		 */
op		: PRIVATE
		{
		    isPublic = FALSE;
		}
		| STATE
		{
		    yyerror("state variables are not supported");
		    yynerrs++;
		}
		| USES classUsesArgs
		;
classUsesArg	: classUsesSym
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
			cd->used[cd->numUsed-1] = $1;
		    }
		}
		;
classUsesSym	: CLASS_SYM
		| IDENT
		{
		    /*
		     * Assume this thing will be declared a class later and 
		     * enter a forward declaration for it.
		     */
		    $$ = Obj_DeclareClass($1, NullSymbol, SYM_CLASS_FORWARD);
		}
		;
classUsesArgs	: classUsesArg
		| classUsesArgs classUsesArg
		| classUsesArgs flexiComma classUsesArg
		;
labeled_op	: IDENT EXPORT operand1
		{
		    if (!curClass || !defClass) {
			yyerror("cannot export a message range when not defining a class");
			yynerrs++;
		    } else {
			Obj_ExportMessages(curClass, $1, &expr1);
		    }
		}
		| CLASS_SYM ENDC
		{
		    if (!curClass || !defClass) {
			yyerror("ENDC when not defining class %i", $1->name);
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
		}
		;
/*
 * Class record definition
 */
op		: CLASS_SYM classDefArgs
		{
		    if ($1->u.class.data->flags & SYM_CLASS_FORWARD) {
			yyerror("class %i not defined", $1->name);
		    } else if ($1->flags & SYM_UNDEF) {
			Obj_DefineClass($1, $2.flags, $2.initRoutine);
		    } else {
			yyerror("class %i is multiply defined", $1->name);
			yynerrs++;
		    }
		}
		;
classDefArgs	: /* empty */
		{
		    $$.initRoutine = $$.flags = (Expr *)NULL;
		}
		| operand1
		{
		    $$.flags = &expr1;
		    $$.initRoutine = (Expr *)NULL;
		}
		| operand1 flexiComma operand2
		{
		    $$.flags = &expr1;
		    $$.initRoutine = &expr2;
		}
		;


/******************************************************************************
 *
 *			     INSTRUCTIONS
 *
 *****************************************************************************/
arith2Inst	: ARITH2 | AND | OR | XOR ;
op	    	: arith2Inst operand1 flexiComma operand2
		{
		    (void)Code_Arith2(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| ARPL operand1 flexiComma operand2
		{
		    (void)Code_Arpl(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| BITNF operand1 flexiComma operand2
		{
		    (void)Code_BitNF(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| BOUND operand1 flexiComma operand2
		{
		    (void)Code_Bound(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| CALL operand1 flexiComma operand2
		{
		    Code_CallStatic(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| CALL operand1
		{
		    (void)Code_Call(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| CMPS operand1 flexiComma operand2
		{
		    (void)Code_String(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| CMPS operand1
		{
		    (void)Code_String(&dot, 0, 1, NULL, &expr1, (Opaque)$1);
		}
		| ENTER operand1 flexiComma operand2
		{
		    (void)Code_EnterLeave(&dot, 0, 1, &expr1, &expr2,
					  (Opaque)$1);
		}
		| FBIOP
		{
		    (void)Code_Fbiop(&dot, 0, 1, NULL, NULL, (Opaque)$1);
		}
		| FBIOP foperand1
		{
		    (void)Code_Fbiop(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| FBIOP foperand1 flexiComma foperand2
		{
		    (void)Code_Fbiop(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| FCOM
		{
		    (void)Code_Fcom(&dot, 0, 1, NULL, NULL, (Opaque)$1);
		}
		| FCOM foperand1
		{
		    (void)Code_Fcom(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| FFREE foperand1
		{
		    (void)Code_Ffree(&dot, 0, 1, &expr1, NULL, (Opaque)1);
		}
		| FGROUP0 
		{
		    (void)Code_Fgroup0(&dot, 0, 1,NULL, NULL, (Opaque)$1);
		}
		| FGROUP1 operand1
		{
		    (void)Code_Fgroup1(&dot, 0, 1, &expr1, NULL,(Opaque)$1);
		}
		| FINT operand1
		{
		    (void)Code_Fint(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| FLDST foperand1
		{
                    (void)Code_Fldst(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| FXCH 
		{
		    (void)Code_Fxch(&dot, 0, 1, NULL, NULL, (Opaque)$1);
		}
		| FXCH foperand1
		{
		    (void)Code_Fxch(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| FZOP 
	        {
		    (void)Code_Fzop(&dot, 0, 1, NULL, NULL, (Opaque)$1);
		}
		| group1Inst operand1
		{
		    (void)Code_Group1(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		;
group1Inst	: GROUP1 | NOT ;
noArgInst	: NOARG | NOARGW | NOARGD ;
naStrgInst	: NASTRG | NASTRGW | NASTRGD ;
op		: IMUL operand1
		{
		    (void)Code_Group1(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| IMUL operand1 flexiComma operand2 flexiComma cexpr
		{
		    (void)Code_Imul(&dot, 0, 1, &expr1, &expr2, (Opaque)$6);
		}
		| IMUL operand1 flexiComma operand2
		{
		    (void)Code_Imul(&dot, 0, 1, &expr1, &expr2, (Opaque)0);
		}
		| IO operand1 flexiComma operand2
		{
		    (void)Code_IO(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| INS operand1 flexiComma operand2
		{
		    (void)Code_Ins(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| INT operand1
		{
		    (void)Code_Int(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| JMP operand1
		{
		    (void)Code_Jmp(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| JUMP operand1
		{
		    (void)Code_Jcc(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| LDPTR operand1 flexiComma operand2
		{
		    (void)Code_LDPtr(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| LEA operand1 flexiComma operand2
		{
		    (void)Code_Lea(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| LEAVE
		{
		    (void)Code_EnterLeave(&dot, 0, 1, NULL, NULL, (Opaque)$1);
		}
		| LODS operand1
		{
		    (void)Code_String(&dot, 0, 1, NULL, &expr1, (Opaque)$1);
		}
		| LOOP operand1
		{
		    (void)Code_Loop(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| LSDT operand1
		{
		    /* Load/Store GDT/IDT */
		    (void)Code_LSDt(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| LSINFO operand1 flexiComma operand2
		{
		    /* Load Selector Info: LAR/LSL */
		    (void)Code_LSInfo(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| MOV operand1 flexiComma operand2
		{
		    (void)Code_Move(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| MOVS operand1 flexiComma operand2
		{
		    (void)Code_String(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| MOVS operand1
		{
		    (void)Code_String(&dot, 0, 1, NULL, &expr1, (Opaque)$1);
		}
		| NAIO
		{
		    /* I/O instruction w/o arg */
		    (void)Code_NoArgIO(&dot, 0, 1, NULL, NULL, (Opaque)$1);
		}
		| NAPRIV
		{
		    /* privileged instruction w/o arg */
		    (void)Code_NoArgPriv(&dot, 0, 1, NULL, NULL, (Opaque)$1);
		}
		| naStrgInst
		{
		    /* String Inst w/o override */
		    (void)Code_NoArg(&dot, 0, 1, NULL, NULL, (Opaque)$1);
		}
		| naStrgInst SEGREG ':'
		{
		    /*
		     * Invoke Code_Override ourselves, allowing us to
		     * use Code_NoArg to store the instruction itself
		     */
		    if ($2 != REG_DS) {
			ResetExpr(&expr1, defElts1);
			StoreExprReg(EXPR_SEGREG, $2);
			Code_Override(&dot, 0, 1, &expr1, 0, (Opaque)NULL);
		    }
		    (void)Code_NoArg(&dot, 0, 1, NULL, NULL, (Opaque)$1);
		}
		| noArgInst
		{
		    (void)Code_NoArg(&dot, 0, 1, NULL, NULL, (Opaque)$1);
		}
		| OUTS operand1 flexiComma operand2
		{
		    (void)Code_Outs(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| POP popOperandList {}
		;
popOperandList	: popOperand
		{
		    (void)Code_Pop(&dot, 0, 1, $1, NULL, (Opaque)NULL);
		    Expr_Free($1);
		}
		| popOperand flexiComma popOperandList
		{
		    (void)Code_Pop(&dot, 0, 1, $1, NULL, (Opaque)NULL);
		    Expr_Free($1);
		}
		;
popOperand	: operand1
		{
		    $$ = Expr_Copy(&expr1, TRUE);
		    malloc_settag((void *)$$, TAG_POP_OPERAND);
		}
		;
op		: PUSH pushOperandList {}
		;
pushOperandList	: pushOperand
		| pushOperandList flexiComma pushOperand
		;
pushOperand	: operand1
		{
		    (void)Code_Push(&dot, 0, 1, &expr1, NULL, (Opaque)NULL);
		}
		;
op		: PWORD operand1
		{
		    /* Load/Store LDT/TR/MSW; Verify selector */
		    (void)Code_PWord(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| prefix
		| prefix op
		;
	/*
	 * Set up expr1 as the code generators need a file and
	 * line number for the generation of errors, and a
	 * segment-override prefix requires someplace to
	 * store the segment register to employ.
	 */
prefix		: setExpr1 prefixInst
		{
		    /*
		     * Call the procedure to handle the prefix.
		     */
		    (*$2.proc)(&dot, 0, 1, &expr1, NULL, (Opaque)$2.op);
		}
		;
/*
 * Instructions that represent prefixes -- returns the code generator to call
 * to store the prefix, along with the OpCode to pass the thing.
 */
prefixInst	: REP	    { $$.proc = Code_Rep; $$.op = $1; }
		| LOCK	    { $$.proc = Code_Lock; $$.op = $1; }
		| SEGREG ':'
		{
		    /*
		     * Little more work here -- have to store the segment
		     * register in question.
		     */
		    StoreExprReg(EXPR_SEGREG, $1);
		    $$.proc = Code_Override;
		    $$.op = (OpCode *)NULL;
		}
		;
op		: RET
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
				       (Opaque)$1);
		    } else {
			yywarning("RET outside of procedure -- defaulting to RETF");
			(void)Code_Ret(&dot, 0, 1, NULL, (Expr *)1,
				       (Opaque)$1);
		    }
		}
		| RET operand1
		{
		    if (curProc) {
			(void)Code_Ret(&dot, 0, 1, &expr1,
				       (Expr *)!Sym_IsNear(curProc),
				       (Opaque)$1);
		    } else {
			yywarning("RET outside of procedure -- defaulting to RETF");
			(void)Code_Ret(&dot, 0, 1, &expr1, (Expr *)1,
				       (Opaque)$1);
		    }
		}
		| retInst
		{
		    (void)Code_Ret(&dot, 0, 1, NULL, NULL, (Opaque)$1);
		}
		| retInst operand1
		{
		    (void)Code_Ret(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		;
retInst		: RETN
		| RETF
		;
op		: SCAS operand1
		{
		    (void)Code_String(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		;
shiftInst	: SHIFT
		| SHL
		| SHR
		;
op		: shiftInst operand1 flexiComma operand2
		{
		    (void)Code_Shift(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| shiftInst operand1
		{
		    /*
		     * Perform single-bit shift
		     */
		    ResetExpr(&expr2, defElts2);
		    StoreExprConst(1);
		    
		    (void)Code_Shift(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		;
CLorCexpr	: BYTEREG
		{
		    if ($1 != REG_CL) {
			yyerror("can only shift by CL or a constant");
			yynerrs++;
		    } else {
			$$ = -1;
		    }
		}
		| cexpr
		{
		    if ($1 == -1) {
			yyerror("isn't that a funny shift count?");
			yynerrs++;
		    } else {
			$$ = $1;
		    }
		}
		;
op		: SHLD operand1 flexiComma operand2 flexiComma CLorCexpr
		{
		    (void)Code_DPShiftLeft(&dot, 0, 1, &expr1, &expr2, (Opaque)$6);
		}
		| SHRD operand1 flexiComma operand2 flexiComma CLorCexpr
		{
		    (void)Code_DPShiftRight(&dot, 0, 1, &expr1, &expr2, (Opaque)$6);
		}
		| STOS operand1
		{
		    (void)Code_String(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| TEST operand1 flexiComma operand2
		{
		    (void)Code_Test(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| WREG1 operand1
		{
		    /* INC/DEC */
		    (void)Code_IncDec(&dot, 0, 1, &expr1, NULL, (Opaque)$1);
		}
		| XCHG operand1 flexiComma operand2
		{
		    (void)Code_Xchg(&dot, 0, 1, &expr1, &expr2, (Opaque)$1);
		}
		| XLAT operand1
		{
		    (void)Code_String(&dot, 0, 1, NULL, &expr1, (Opaque)$1);
		}
		| XLAT
		{
		    (void)Code_NoArg(&dot, 0, 1, NULL, NULL, (Opaque)$1);
		}
		;
/******************************************************************************
 *
 *			      PSEUDO OPS
 *
 ****************************************************************************/
op		: DEBUG	    	    { lexdebug = yydebug = $1; }
		| SHOWM	    	    { showmacro = $1; }
		| MASM	    	    { masmCompatible = $1; }
		| BREAK 	    { _asm int 3; }
		| FALLTHRU	    { fall_thru = 1; }
		| FALLTHRU operand1
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
		}
		| UNREACHED 	    { curSeg->u.segment.data->checkLabel=TRUE; }
		| PROCESSOR
		{
		    procType &= ~PROC_MASK; procType |= $1;
		    sprintf(predefs[PD_CPU].value->text, "0x%04x", procType);
		}
		| COPROCESSOR
		{
		    procType &= ~PROC_CO_MASK; procType |= $1;
		    sprintf(predefs[PD_CPU].value->text, "0x%04x", procType);
		}
		| IOENABLE
		{
		    procType |= PROC_IO;
		    sprintf(predefs[PD_CPU].value->text, "0x%04x", procType);
		}
		| ASSERT operand1 
		{
		    Assert_Enter(&expr1, NULL);
		}
		| ASSERT operand1 { defStruct = 0; } flexiComma STRING
		{
		    Assert_Enter(&expr1, $5);
		}
		| align ALIGNMENT
		{
		    if (inStruct) {
			int 	diff =
			    ((inStruct->u.sType.common.size+$2)&~$2)-
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
			
			dot += $2;
			dot &= ~$2;

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
		    Scan_DontUseOpProc($1);
		}
		| align cexpr
		{
		    if (inStruct) {
			int 	diff =
			    (((inStruct->u.sType.common.size+$2-1)/$2)*$2)-
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
			
			dot = ((dot + $2 - 1) / $2) * $2;

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
		    Scan_DontUseOpProc($1);
		}
		| align error
		{
		    Scan_DontUseOpProc($1);
		}
		| EVEN
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
		}
		;
align	    	: ALIGN
		{
		    $$ = Scan_UseOpProc(findSegToken);
		}
		;
op		: ON_STACK { snarfLine=1; } STRING
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
			cp = index($3, ';');
			if (cp == NULL) {
			    cp = $3+strlen($3);
			}
			while (isspace(*--cp)) {
			    ;
			}
			cp[1] = '\0';
			desc = ST_Enter(output, permStrings, $3, cp-$3+1);
			Sym_Enter(NullID, SYM_ONSTACK, dot, desc);
		    }
		    free($3);
		}
		| WARN { snarfLine = 1; } STRING
		{
		    char    *cp;
		    char    *start;
		    char    savec;
		    int	    i;

		    start = $3;

		    for (start=$3; *start!='\0' && *start!=';'; start=cp) {
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
		    free($3);
		}
		| PCTOUT
		{
		    if (makeDepend != TRUE)
		    {
		        fputs($1, stderr);
		        putc('\n', stderr);
		        fflush(stderr);
		    }
		    free($1);
		}
		| ORG operand1
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
		}
		| OPCODE { snarfLine = 1; } STRING
		{
		    yywarning("%s not supported -- rest of line discarded",
			      $1->name);
		    free($3);
		}
		;
model		: MODEL
		{
		    $$ = Scan_UseOpProc(findModelToken);
		}
		;
op		: model MEMMODEL
		{
		    Scan_DontUseOpProc($1);
		    model = $2;
		}
		| model MEMMODEL flexiComma LANGUAGE
		{
		    Scan_DontUseOpProc($1);
		    model = $2;
		    language = $4;
		}
		| model error
		{
		    Scan_DontUseOpProc($1);
		    yyerrok;
		    if (yychar != '\n') {
			yyclearin;
		    }
		}
		;
op	        : WRITECHECK
		{
		    /* Turn on memory-write checking */
		    writeCheck = TRUE;
		}
		;
op	        : NOWRITECHECK
		{
		    /* Turn off memory-write checking */
		    writeCheck = FALSE;
		}
		;
op	        : READCHECK
		{
		    /* Turn on memory-read checking */
		    readCheck = TRUE;
		}
		;
op	        : NOREADCHECK
		{
		    /* Turn off memory-read checking */
		    readCheck = FALSE;
		}
		;

/******************************************************************************
 *
 *			     CONDITIONALS
 *
 *****************************************************************************/
op		: conditional
		;
conditional	: IF setTExpr operand
		{
		    HandleIF($1);
		    RestoreExpr(&$2);
		}
		| IF1 setTExpr
		{
		    yywarning("%sIF1 is meaningless (only one source pass)",
			      $1 ? "ELSE" : "");
		    StoreExprConst(1);
		    HandleIF($1);
		    RestoreExpr(&$2);
		}
		| IF2 setTExpr
		{
		    yywarning("%sIF2 is meaningless (only one source pass)",
			      $1 ? "ELSE" : "");
		    StoreExprConst(1);
		    HandleIF($1);
		    RestoreExpr(&$2);
		}
		| IFB STRING setTExpr
		{
		    StoreExprConst(*$2 == '\0');
		    free($2);
		    HandleIF($1);
		    RestoreExpr(&$3);
		}
		| IFDEF IDENT setTExpr
		{
		    StoreExprConst(Sym_Find($2, SYM_ANY, FALSE) != 0);
		    HandleIF($1);
		    RestoreExpr(&$3);
		}
		| IFDEF setTExpr
		{
		    /*
		     * Masm supports empty ifdefs to allow one to use it
		     * to test for a macro argument having been given...
		     * Gross.
		     */
		    StoreExprConst(0);
		    HandleIF($1);
		    RestoreExpr(&$2);
		}
		| IFDIF STRING ',' STRING setTExpr
		{
		    StoreExprConst(strcmp($2, $4) != 0);
		    free($2);
		    free($4);
		    HandleIF($1);
		    RestoreExpr(&$5);
		}
		| IFE setTExpr operand
		{
		    StoreExprConst(0);
		    StoreExprOp(EXPR_EQ);
		    HandleIF($1);
		    RestoreExpr(&$2);
		}
		| IFIDN STRING ',' STRING setTExpr
		{
		    StoreExprConst(strcmp($2, $4)==0);
		    free($2);
		    free($4);
		    HandleIF($1);
		    RestoreExpr(&$5);
		}
		| IFNB STRING setTExpr
		{
		    StoreExprConst(*$2 != '\0');
		    free($2);
		    HandleIF($1);
		    RestoreExpr(&$3);
		}
		| IFNDEF IDENT setTExpr
		{
		    StoreExprConst(!Sym_Find($2, SYM_ANY, FALSE));
		    HandleIF($1);
		    RestoreExpr(&$3);
		}
		| IFNDEF setTExpr
		{
		    StoreExprConst(1);
		    HandleIF($1);
		    RestoreExpr(&$2);
		}
		| ELSE
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
		}
		| ENDIF
		{
		    if (iflevel == -1) {
			yyerror("IF-less ENDIF");
			yynerrs++;
		    } else {
			iflevel -= 1;
		    }
		}
		;
op	    	: ERR  	       	{ yyerror(".ERR encountered"); yynerrs++;}
		| ERR STRING	
		{
		    yyerror(".ERR encountered: %s", $2);
		    free($2);
		    yynerrs++;
		}
		| ERRB STRING
		{
		    if (*$2 == '\0') {
			yyerror(".ERRB: String blank");
			yynerrs++;
		    }
		    free($2);
		}
		| ERRDEF IDENT
		{
		    if (Sym_Find($2, SYM_ANY, FALSE) != NULL) {
			yyerror(".ERRDEF: Symbol %i defined", $2);
			yynerrs++;
		    }
		}
		| ERRDIF STRING ',' STRING
		{
		    if (strcmp($2, $4) != 0) {
			yyerror(".ERRDIF: <%s> and <%s> differ",
				$2, $4);
			yynerrs++;
		    }
		    free($2); free($4);
		}
		| ERRE cexpr
		{
		    if ($2 == 0) {
			yyerror(".ERRE: expression is zero");
			yynerrs++;
		    }
		}
		| ERRIDN STRING ',' STRING
		{
		    if (strcmp($2, $4) == 0) {
			yyerror(".ERRIDN: <%s> and <%s> are identical",
				$2, $4);
			yynerrs++;
		    }
		    free($2); free($4);
		}
		| ERRNB STRING
		{
		    if (*$2 != '\0') {
			yyerror(".ERRNB: <%s> isn't blank",
				$2);
			yynerrs++;
		    }
		    free($2);
		}
		| ERRNDEF IDENT
		{
		    if (Sym_Find($2, SYM_ANY, FALSE) == NULL) {
			yyerror(".ERRNDEF: %i isn't defined", $2);
			yynerrs++;
		    }
		}
		| ERRNZ cexpr
		{
		    if ($2 != 0) {
			yyerror(".ERRNZ: expression is non-zero");
			yynerrs++;
		    }
		}
		;
%%


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

    if (malloc_size(*state) != 0) {
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
