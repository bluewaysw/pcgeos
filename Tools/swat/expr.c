
/*  A Bison parser, made from expr.y
    by GNU Bison version 1.28  */

#define YYBISON 1  /* Identify Bison output.  */

#define	CONSTANT	257
#define	STRING_LITERAL	258
#define	PTR_OP	259
#define	VHIST	260
#define	ADDRESS	261
#define	TYPE	262
#define	SYM	263
#define	SIZEOF	264
#define	HANDLE	265
#define	VHANDLE	266
#define	LHANDLE	267
#define	LEFT_OP	268
#define	RIGHT_OP	269
#define	LE_OP	270
#define	GE_OP	271
#define	EQ_OP	272
#define	NE_OP	273
#define	AND_OP	274
#define	OR_OP	275
#define	CHAR	276
#define	SHORT	277
#define	INT	278
#define	LONG	279
#define	SIGNED	280
#define	UNSIGNED	281
#define	FLOAT	282
#define	DOUBLE	283
#define	CONST	284
#define	VOLATILE	285
#define	VOID	286
#define	WORD	287
#define	BYTE	288
#define	DWORD	289
#define	SWORD	290
#define	SBYTE	291
#define	SDWORD	292
#define	DA_NEAR	293
#define	DA_FAR	294
#define	DA_SEG	295
#define	DA_LMEM	296
#define	DA_HANDLE	297
#define	DA_OBJECT	298
#define	DA_VM	299
#define	DA_VIRTUAL	300
#define	FPTR	301
#define	NPTR	302
#define	SPTR	303
#define	LPTR	304
#define	HPTR	305
#define	OPTR	306
#define	VPTR	307
#define	VFPTR	308
#define	RANGE	309
#define	NOT_QUITE_UNARY	310
#define	INC_OP	311
#define	DEC_OP	312
#define	UNARY	313
#define	HIGHEST	314

#line 1 "expr.y"

/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- address parser
 * FILE:	  expr.y
 *
 * AUTHOR:  	  Adam de Boor: Jun  9, 1992
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Expr_Eval   	    C routine to evaluate an expression
 *	addr-parse  	    Tcl interface to same
 *	expr-debug  	    Enable/disable debugging output during parse
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	6/ 9/92	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *
 *	There are two purposes for expression evaluation in this here
 *	debugger:
 *	    - to print out the value of the expression
 *	    - to obtain an address for examining the contents of memory
 *	      or setting a breakpoint.
 *	There is also a good deal of history (read: lines of code) behind
 *	the existing notion of an address expression providing strictly
 *	an address of data stored on the PC. This interpretation severely
 *	limits the sort of operators the user can employ, as well as
 *	his ability to examine and manipulate variables in the patient.
 *
 *	To correct this, while not screwing lots of other things up, this
 *	parser attempts to keep the result as the address of something
 *	in the PC until the last possible moment.
 *
 *	For example, with the expression "pself", the result will be
 *	the address of the variable "pself", with the data type as a far
 *	pointer to something (the "what" field of the ExprToken is
 *	TOKEN_ADDRESS).
 *
 *	If the expression is "pself+1", however, the parser is forced to
 *	fetch the value of pself and add "1" (i.e. the size of the data
 *	pointed to) to that value. The result remains of type
 *	far-pointer-to-something, but the value is stored in Swat's
 *	memory (the "what" field is TOKEN_POINTER).
 *
 *	When it comes time to return the value of the expression, the
 *	treatment of a TOKEN_POINTER result is governed by a passed flag
 *	that indicates for which of the above-mentioned two purposes the
 *	expression is being parsed.
 *
 *	If it's to obtain a value, the result is returned as fetched
 *	(the handle portion of the GeosAddr is set to ValueHandle and the
 *	offset portion points to the fetched data; the type is the type
 *	of data stored in the buffer). If it's to obtain an address,
 *	however, and the fetched value is a far pointer, the value of
 *	the pointer is returned as if the user had indirected through it
 *	(which generates a TOKEN_ADDRESS ExprToken).
 *
 *	Whenever any pointer variable must actually be fetched, the parser
 *	performs any indirections required to get to its actual data
 *	(e.g. dereferencing the chunk handle of an _lmem *) to convert
 *	the pointer into a far pointer. The buffer to which value.ptr
 *	in the ExprToken points is a GeosAddr structure. If its handle
 *	token is null, the offset is a 32-bit far pointer (low word is
 *	offset, high word is segment). THIS IS HOW FETCHED POINTERS ARE
 *	RETURNED WHEN wantAddr IS PASSED AS FALSE TO Expr_Eval.
 *
 *	When a value must be fetched (the token type is TOKEN_ADDRESS and
 *	some arithmetic operation is about to be performed on it):
 *	    - if it is TYPE_ARRAY, the result is a TOKEN_ADDRESS whose
 *	      type is the element type of the array; the address itself
 *	      remains untouched.
 *	    - if it is TYPE_POINTER, it is converted to a far pointer
 *	      and stored as a GeosAddr in memory pointed to by value.ptr
 *	      (TOKEN_POINTER is the resulting token type). The type remains
 *	      as TYPE_POINTER, but is converted to TYPE_PTR_FAR to the
 *	      same base type.
 *	    - if it is integral (enum, int, char), its value is fetched and
 *	      converted to a long, resulting in a TOKEN_LITERAL. Its
 *	      original type is set as ExprToken.type.
 *
 *	When a pointer is indirected through, the token is converted from
 *	TOKEN_POINTER to TOKEN_ADDRESS by copying the GeosAddr at value.ptr
 *	to value.addr; the type is set to the base of the pointer.
 *	
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: expr.y,v 4.42 97/04/18 15:15:28 dbaumann Exp $";
#endif lint

#include <config.h>
#include <compat/stdlib.h>

#ifdef __BORLANDC__
/* 
 * !@#!@#!@ Borland hoses us by not defining this unless you pass -A,
 * which we don't want to do because it's too restrictive.  But if _STDC_
 * isn't defined, then bison.simple will #define "const" to nothing.
 *
 * XXX: maybe move this to cm-bor.h?
 */
#define __STDC__ 1
#endif

#include "swat.h"
#include "buf.h"
#include "cmd.h"
#include "expr.h"
#include "handle.h"
#include "private.h"
#include "sym.h"
#include "type.h"
#include "value.h"
#include "var.h"
#include "malloc.h"

#include <stdarg.h>
#include <ctype.h>
extern Type type_VoidProc;


/*
 * Token definition
 */
typedef struct {
    enum {
	TOKEN_LITERAL,  	    	/* value is one of int, or char *,
					 * depending on 'type' */
	TOKEN_POINTER,  	    	/* value points to dynamically-allocated
					 * data of a type given by 'type' */
	TOKEN_ADDRESS,  	    	/* value is the address of data in the
					 * patient whose type is 'type'. If
					 * a value is a proper lvalue, this will
					 * be its 'what'. */
	TOKEN_STRING,			/* value is a pointer to a string in
					 * our address space. */
    }	    	what;	    	/* What the token is */
    union {
	GeosAddr    addr;
	void	    *ptr;
	char	    *str;
	long 	    literal;
    }	    	value;      	/* Value of token */
    Type	type;		/* Type of token */
    int	    	flags;
#define ETF_HANDLE_FROM_INDIR	0x0001	    /* Set if value.addr.handle
					     * comes from indirecting through
					     * a near pointer and should
					     * not be held against the user
					     * when processing a ':' operator */
#define ETF_LMEM_INDIR_PENDING	0x0002	    /* Set if segment portion of ':'
					     * operator involved ^l, so we
					     * must indirect through the offset
					     * portion to get the real offset
					     * for the expression */
#define ETF_VMEM_INDIR_PENDING	0x0004	    /* Set if segment portion of ':'
					     * operator involved ^v, so we must
					     * perform various manipulations
					     * to end up with the final
					     * segment:0 */
} ExprToken;

/*
 * Definition of all the state required during parsing. We define it in a
 * structure to avoid passing lots and lots o' arguments around.
 */
#define PARSE_MAX_SIDE	50

typedef struct {
    const char 	    *startExpr;	    	    	/* Original start of
						 * expression */
    Boolean 	    sideStack[PARSE_MAX_SIDE];	/* Side-effects stack.
						 * state->noSideEffects can be
						 * pushed on top of this when
						 * its state changes... */
    Boolean	    *sideStackTop;    	    	/* Top of said stack */
    Boolean	    noSideEffects;    	    	/* TRUE if shouldn't generate
						 * side effects */
    ExprToken	    result;
    Frame	    *frame;   	    	    	/* Frame for reference */
    int		    column;   	    	    	/* Current column */
    Lst	    	    data;			/* List on which to place
						 * allocated data. All
						 * things pointed to by this
						 * list are freed when parsing
						 * is complete. */
    Patient  	    patient;	    	    	/* Patient in whose context
						 * we're parsing */
    Boolean 	    doneError;	    	    	/* Non-zero if already seen
						 * and returned an error. */
    Boolean 	    wantAddr;	    	    	/* Non-zero if looking
						 * to obtain an address. Zero
						 * if looking to get a value.
						 */
    Boolean 	    freeStacks;	    	    	/* Non-zero if state and value
						 * stacks were dynamically
						 * allocated */
    void    	    *valStack;	    	    	/* Value stack, if freeStacks */
    void    	    *stateStack;    	    	/* State stack, if freeStacks */
} ExprState;

#define ExprIsLVal(token) (((token).what == TOKEN_ADDRESS) || \
			    ((token).what == TOKEN_REGISTER))


/*
 * Function redefinitions.
 *	- yyerror needs to have the original expression pointer to print
 *	  messages
 *	- yyparse needs the patient, the expression (twice so one can be passed
 *	  to yylex), the frame in which to evaluate the expression and the
 *	  places to store the value and type.
 *	- yylex must have the patient, a modifiable pointer to the expression
 *	  being parsed, a token to fill in, a location to ignore and the
 *	  parse state.
 */
#define yyerror(s) xyyerror(state, s)
/*#define yylex(token, loc) ExprScan(&expr, (token), state)*/
#define yylex(token) ExprScan(&expr, (token), state)

#ifdef YYPARSE_PARAM
#define yyparse(arg) \
xyyparse(const char *expr, ExprState *state, arg)
#else
#define yyparse(arg) \
xyyparse(const char *expr, ExprState *state)
#endif

/*
 * Provide our own handler for the parser-stack overflow so the default one
 * that uses "alloca" isn't used, since alloca is forbidden to us owing to
 * the annoying hidden non-support of said function by our dearly beloved
 * HighC from MetaWare, A.M.D.G.
 */
#define yyoverflow(m,s,S,v,V,d) ExprStackOverflow(state, m,s,S,(void **)v,V,d)
static void ExprStackOverflow(ExprState *,
			      char *,
			      short **, size_t,
			      void **, size_t,
			      int *);

/*
 * Forward declarations. Each function
 */
static Boolean ExprFetch(ExprState *state, ExprToken *tokenPtr);
static Boolean ExprArithOrPointerOp(ExprState *state, int op, ExprToken *lhs,
				    ExprToken *rhs, ExprToken *result);
static Boolean ExprArithOp(ExprState *state, int op, ExprToken *lhs,
			   ExprToken *rhs, ExprToken *result);
static Boolean ExprIntOp(ExprState *state, int op, ExprToken *lhs,
			 ExprToken *rhs, ExprToken *result);
static Boolean ExprRelOp(ExprState *state, int op, ExprToken *lhs,
			 ExprToken *rhs, ExprToken *result);

static int ExprEvalBoolean(ExprState *state, ExprToken *token);
static Boolean ExprCoerce(ExprState *state, ExprToken *token1,
			  ExprToken *token2, Boolean floatOk);
static void ExprStandardCoerce(ExprState *state, ExprToken *token);
static Boolean ExprIndirectVMPart1(ExprState *state, long hid,
				   GeosAddr *result);
static Boolean ExprIndirectVMPart2(ExprState *state, Handle handleVM,
				   word block, GeosAddr *result);
static Boolean ExprIndirect(ExprState *state, ExprToken *tokenPtr,
			    ExprToken *resultPtr);
static Boolean ExprTypeCheck(Type	type1,
			     Type	type2,
			     Boolean	coerce);

static Handle ExprModuleToHandle(ExprState   *state, Sym	sym);
static void xyyerror(ExprState *state, const char *fmt, ...);
static Boolean ExprCast(ExprState *state, ExprToken *tokenPtr,
			Type type, ExprToken *resultPtr, Boolean oldStyleCast);
static void ExprSetAsPointer(ExprState *state,
			     ExprToken *resultPtr,
			     int ptrType,
			     Type baseType,
			     Handle handle,
			     Address offset);
static malloc_t ExprMalloc(ExprState *state, unsigned size);

/*
 * Stuff for tracking whether to generate side effects.
 */
#define ExprSidePush(side, state) \
    if (state->sideStackTop - state->sideStack == PARSE_MAX_SIDE) {\
        yyerror("side-effects stack overflow");\
	YYERROR;\
    }\
    *state->sideStackTop = state->noSideEffects;\
    state->sideStackTop += 1;\
    state->noSideEffects = side

#define ExprSidePop(state) \
    if (state->sideStackTop > state->sideStack) {\
	state->sideStackTop -= 1;\
	state->noSideEffects = *state->sideStackTop;\
    } else {\
	yyerror("side-effects stack underflow");\
    }

#define TYPE_MOD_UNSIGNED   0x00000001
#define TYPE_MOD_SIGNED	    0x00000002
#define TYPE_MOD_CONST	    0x00000004
#define TYPE_MOD_VOLATILE   0x00000008
#define TYPE_MOD_LONG	    0x00000010
#define TYPE_MOD_SHORT	    0x00000020
#define TYPE_MOD_INT	    0x00000040
#define TYPE_MOD_CHAR	    0x00000080
#define TYPE_MOD_FLOAT	    0x00000100
#define TYPE_MOD_DOUBLE	    0x00000200
#define TYPE_MOD_VOID	    0x00000400

static int	  exprDebug = 0;

/*
 * Replacement for "fprintf" for parser debug output. Allows us to
 * get the message into the windowing system, of which we approve most
 * heartily.
 */
static void ExprDebug(FILE *stream, const char *fmt, ...);
#define fprintf ExprDebug


#line 333 "expr.y"
typedef union {
    int	    	op;	    	/* Regular operator token */
    Type	type;	    	/* type.name token */
    ExprToken	token;    	/* Everything else */
    Sym	     	sym;	    	/* SYM token */
} YYSTYPE;
#include <stdio.h>

#ifndef __cplusplus
#ifndef __STDC__
#define const
#endif
#endif



#define	YYFINAL		167
#define	YYFLAG		-32768
#define	YYNTBASE	83

#define YYTRANSLATE(x) ((unsigned)(x) <= 314 ? yytranslate[x] : 98)

static const char yytranslate[] = {     0,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,    73,     2,    58,     2,    68,    61,     2,    77,
    78,    66,    64,    57,    65,     5,    67,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,    79,     2,    62,
     2,    63,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
    75,     2,    76,    60,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,    81,    59,    82,    74,     2,     2,     2,     2,
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
     2,     2,     2,     2,     2,     1,     3,     4,     6,     7,
     8,     9,    10,    11,    12,    13,    14,    15,    16,    17,
    18,    19,    20,    21,    22,    23,    24,    25,    26,    27,
    28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
    38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
    48,    49,    50,    51,    52,    53,    54,    55,    56,    69,
    70,    71,    72,    80
};

#if YYDEBUG != 0
static const short yyprhs[] = {     0,
     0,     2,     4,     7,    11,    15,    17,    19,    21,    24,
    26,    28,    30,    34,    38,    43,    50,    52,    54,    57,
    60,    63,    66,    69,    72,    75,    78,    83,    86,    89,
    91,    96,   100,   104,   108,   112,   116,   120,   124,   128,
   132,   136,   140,   144,   148,   152,   156,   160,   161,   166,
   167,   172,   176,   178,   180,   182,   184,   186,   188,   190,
   192,   194,   196,   198,   200,   202,   204,   206,   208,   210,
   212,   215,   218,   220,   222,   224,   226,   228,   230,   232,
   234,   236,   238,   239,   241,   243,   246,   249,   252,   255,
   258,   261,   264,   267,   269,   273,   276,   278,   282,   285,
   289,   294,   297
};

static const short yyrhs[] = {    84,
     0,     1,     0,    93,    85,     0,    84,    57,    85,     0,
    84,    58,    85,     0,    85,     0,     8,     0,    10,     0,
    12,    85,     0,     7,     0,     3,     0,     4,     0,    77,
    84,    78,     0,    81,    84,    82,     0,    85,    75,    85,
    76,     0,    85,    75,    85,    56,    85,    76,     0,     5,
     0,     6,     0,    85,    86,     0,    61,    85,     0,    66,
    85,     0,    64,    85,     0,    65,    85,     0,    74,    85,
     0,    73,    85,     0,    87,    85,     0,    87,    77,    92,
    78,     0,    14,    85,     0,    13,    85,     0,    11,     0,
    77,    92,    78,    85,     0,    85,    66,    85,     0,    85,
    67,    85,     0,    85,    68,    85,     0,    85,    64,    85,
     0,    85,    65,    85,     0,    85,    15,    85,     0,    85,
    16,    85,     0,    85,    62,    85,     0,    85,    63,    85,
     0,    85,    17,    85,     0,    85,    18,    85,     0,    85,
    19,    85,     0,    85,    20,    85,     0,    85,    61,    85,
     0,    85,    60,    85,     0,    85,    59,    85,     0,     0,
    85,    21,    88,    85,     0,     0,    85,    22,    89,    85,
     0,    85,    79,    85,     0,    23,     0,    24,     0,    25,
     0,    26,     0,    27,     0,    29,     0,    30,     0,    28,
     0,    33,     0,    31,     0,    32,     0,    34,     0,    35,
     0,    36,     0,    37,     0,    38,     0,    39,     0,    90,
     0,    91,    90,     0,    93,    94,     0,    91,     0,     9,
     0,    51,     0,    48,     0,    49,     0,    50,     0,    53,
     0,    52,     0,    54,     0,    55,     0,     0,    97,     0,
    66,     0,    43,    66,     0,    41,    66,     0,    40,    66,
     0,    42,    66,     0,    45,    66,     0,    44,    66,     0,
    47,    66,     0,    46,    66,     0,    77,     0,    96,    97,
    78,     0,    95,    97,     0,    95,     0,    97,    96,    78,
     0,    96,    78,     0,    97,    75,    76,     0,    97,    75,
    85,    76,     0,    75,    76,     0,    75,    85,    76,     0
};

#endif

#if YYDEBUG != 0
static const short yyrline[] = { 0,
   388,   397,   408,   414,   415,   432,   435,   438,   547,   561,
   562,   563,   564,   565,   566,   604,   674,   674,   675,   881,
   894,   898,   908,   921,   936,   948,   956,   964,   978,  1005,
  1011,  1021,  1027,  1033,  1039,  1045,  1051,  1057,  1063,  1069,
  1075,  1081,  1087,  1093,  1099,  1105,  1111,  1117,  1142,  1160,
  1185,  1203,  1408,  1409,  1410,  1411,  1412,  1413,  1414,  1415,
  1416,  1417,  1418,  1419,  1420,  1421,  1422,  1423,  1424,  1427,
  1428,  1439,  1445,  1517,  1518,  1522,  1526,  1530,  1534,  1538,
  1542,  1546,  1552,  1556,  1563,  1567,  1571,  1575,  1579,  1583,
  1587,  1591,  1595,  1600,  1602,  1606,  1610,  1611,  1641,  1671,
  1678,  1689,  1699
};
#endif


#if YYDEBUG != 0 || defined (YYERROR_VERBOSE)

static const char * const yytname[] = {   "$","error","$undefined.","CONSTANT",
"STRING_LITERAL","'.'","PTR_OP","VHIST","ADDRESS","TYPE","SYM","SIZEOF","HANDLE",
"VHANDLE","LHANDLE","LEFT_OP","RIGHT_OP","LE_OP","GE_OP","EQ_OP","NE_OP","AND_OP",
"OR_OP","CHAR","SHORT","INT","LONG","SIGNED","UNSIGNED","FLOAT","DOUBLE","CONST",
"VOLATILE","VOID","WORD","BYTE","DWORD","SWORD","SBYTE","SDWORD","DA_NEAR","DA_FAR",
"DA_SEG","DA_LMEM","DA_HANDLE","DA_OBJECT","DA_VM","DA_VIRTUAL","FPTR","NPTR",
"SPTR","LPTR","HPTR","OPTR","VPTR","VFPTR","RANGE","','","'#'","'|'","'^'","'&'",
"'<'","'>'","'+'","'-'","'*'","'/'","'%'","NOT_QUITE_UNARY","INC_OP","DEC_OP",
"UNARY","'!'","'~'","'['","']'","'('","')'","':'","HIGHEST","'{'","'}'","expr.return",
"top.expr","expr","struct.op","sizeof","@1","@2","type.modifier","type.modifier.list",
"type.name","type.specifier","abstract.declarator","ptr.decl","open.paren","abstract.declarator2", NULL
};
#endif

static const short yyr1[] = {     0,
    83,    83,    84,    84,    84,    84,    85,    85,    85,    85,
    85,    85,    85,    85,    85,    85,    86,    86,    85,    85,
    85,    85,    85,    85,    85,    85,    85,    85,    85,    87,
    85,    85,    85,    85,    85,    85,    85,    85,    85,    85,
    85,    85,    85,    85,    85,    85,    85,    88,    85,    89,
    85,    85,    90,    90,    90,    90,    90,    90,    90,    90,
    90,    90,    90,    90,    90,    90,    90,    90,    90,    91,
    91,    92,    93,    93,    93,    93,    93,    93,    93,    93,
    93,    93,    94,    94,    95,    95,    95,    95,    95,    95,
    95,    95,    95,    96,    97,    97,    97,    97,    97,    97,
    97,    97,    97
};

static const short yyr2[] = {     0,
     1,     1,     2,     3,     3,     1,     1,     1,     2,     1,
     1,     1,     3,     3,     4,     6,     1,     1,     2,     2,
     2,     2,     2,     2,     2,     2,     4,     2,     2,     1,
     4,     3,     3,     3,     3,     3,     3,     3,     3,     3,
     3,     3,     3,     3,     3,     3,     3,     0,     4,     0,
     4,     3,     1,     1,     1,     1,     1,     1,     1,     1,
     1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
     2,     2,     1,     1,     1,     1,     1,     1,     1,     1,
     1,     1,     0,     1,     1,     2,     2,     2,     2,     2,
     2,     2,     2,     1,     3,     2,     1,     3,     2,     3,
     4,     2,     3
};

static const short yydefact[] = {     0,
     2,    11,    12,    10,     7,    74,     8,    30,     0,     0,
     0,    53,    54,    55,    56,    57,    60,    58,    59,    62,
    63,    61,    64,    65,    66,    67,    68,    69,    76,    77,
    78,    75,    80,    79,    81,    82,     0,     0,     0,     0,
     0,     0,     0,     0,     1,     6,     0,    70,    73,     0,
     9,    29,    28,    20,    22,    23,    21,    25,    24,     0,
     0,    83,     0,     0,     0,    17,    18,     0,     0,     0,
     0,     0,     0,    48,    50,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,    19,     0,    26,
    71,     3,    13,     0,     0,     0,     0,     0,     0,     0,
     0,     0,    85,     0,    94,    72,    97,     0,    84,    14,
     4,     5,    37,    38,    41,    42,    43,    44,     0,     0,
    47,    46,    45,    39,    40,    35,    36,    32,    33,    34,
     0,    52,     0,    31,    88,    87,    89,    86,    91,    90,
    93,    92,   102,     0,    85,    94,    96,    99,     0,     0,
     0,    49,    51,     0,    15,    27,   103,    95,   100,     0,
    98,     0,   101,    16,     0,     0,     0
};

static const short yydefgoto[] = {   165,
    60,    46,    88,    47,   119,   120,    48,    49,    61,    62,
   106,   107,   108,   109
};

static const short yypact[] = {   125,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,   392,   392,
   392,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,   392,   392,   392,   392,
   392,   392,   200,   200,   -50,   673,   464,-32768,   757,   392,
-32768,-32768,-32768,    46,    46,    46,    46,    46,    46,   -52,
   -63,   347,   -33,   392,   392,-32768,-32768,   392,   392,   392,
   392,   392,   392,-32768,-32768,   392,   392,   392,   392,   392,
   392,   392,   392,   392,   392,   392,   392,-32768,   200,   -57,
-32768,   673,-32768,   392,   -39,   -32,   -29,   -12,    -1,     0,
    15,    16,   478,    32,   275,-32768,   922,   909,   -54,-32768,
   673,   673,    52,    52,   429,   429,   915,   915,   392,   392,
   824,   843,   861,   429,   429,   117,   117,    46,    46,    46,
   501,     5,     8,    46,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,   566,-32768,-32768,   -54,-32768,    14,   365,
    21,   759,   738,   392,-32768,     6,-32768,-32768,-32768,   587,
-32768,   652,-32768,-32768,   100,   101,-32768
};

static const short yypgoto[] = {-32768,
     3,    -9,-32768,-32768,-32768,-32768,    53,-32768,    18,     4,
-32768,-32768,   -59,   -96
};


#define	YYLAST		999


static const short yytable[] = {    51,
    52,    53,    45,    50,    64,    65,    64,    65,     2,     3,
   147,   149,     4,     5,    94,     7,     8,     9,    10,    11,
   150,    87,   146,    64,    65,    93,   135,    54,    55,    56,
    57,    58,    59,   136,     2,     3,   137,    90,     4,     5,
    92,     7,     8,     9,    10,    11,    63,    50,   110,   151,
    66,    67,    92,   138,   111,   112,    66,    67,   113,   114,
   115,   116,   117,   118,   139,   140,   121,   122,   123,   124,
   125,   126,   127,   128,   129,   130,   131,   132,    41,    42,
   141,   142,    43,-32768,   134,   156,    44,   151,   150,   151,
   146,   158,    37,    57,   144,    38,    39,    40,   161,   166,
   167,    91,     0,     0,    41,    42,   133,   143,    43,   152,
   153,     0,    44,     0,     0,    81,    82,    83,    84,    85,
    86,    66,    67,     0,    87,     1,    86,     2,     3,     0,
    87,     4,     5,     6,     7,     8,     9,    10,    11,     0,
   160,     0,     0,     0,   162,     0,   134,    12,    13,    14,
    15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
    25,    26,    27,    28,     0,     0,     0,     0,     0,     0,
     0,     0,    29,    30,    31,    32,    33,    34,    35,    36,
     0,     0,    83,    84,    85,    37,     0,     0,    38,    39,
    40,    86,     0,     0,     0,    87,     0,    41,    42,     0,
     0,    43,     2,     3,     0,    44,     4,     5,     6,     7,
     8,     9,    10,    11,     0,     0,     0,     0,     0,     0,
     0,     0,    12,    13,    14,    15,    16,    17,    18,    19,
    20,    21,    22,    23,    24,    25,    26,    27,    28,     0,
     0,     0,     0,     0,     0,     0,     0,    29,    30,    31,
    32,    33,    34,    35,    36,     0,     0,     0,     0,     0,
    37,     0,     0,    38,    39,    40,     0,     0,     0,     0,
     0,     0,    41,    42,     0,     0,    43,     2,     3,     0,
    44,     4,     5,     6,     7,     8,     9,    10,    11,     0,
     0,     0,     0,     0,     0,     0,     0,    12,    13,    14,
    15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
    25,    26,    27,    28,     0,     0,     0,     0,     0,     0,
     0,     0,    29,    30,    31,    32,    33,    34,    35,    36,
     0,     0,     0,     0,     0,    37,     0,     0,    38,    39,
     0,     0,     0,     0,     0,     0,     0,    41,    42,     2,
     3,     0,     0,     4,     5,    44,     7,     8,     9,    10,
    11,     0,     0,     0,     0,     0,     0,     2,     3,     0,
     0,     4,     5,     0,     7,     8,     9,    10,    11,     0,
     0,     0,     0,     0,     0,     0,    95,    96,    97,    98,
    99,   100,   101,   102,     2,     3,     0,     0,     4,     5,
     0,     7,     8,     9,    10,    11,     0,    37,     0,     0,
    38,    39,   103,     0,     0,     0,     0,     0,     0,    41,
    42,   104,     0,   105,     0,    37,     0,    44,    38,    39,
    40,     0,     0,    66,    67,     0,     0,    41,    42,     0,
   159,    43,     0,    68,    69,    44,     0,     0,     0,     0,
     0,     0,    37,     0,     0,    38,    39,    40,     0,     0,
     0,     0,     0,     0,    41,    42,     2,     3,    43,     0,
     4,     5,    44,     7,     8,     9,    10,    11,     0,     0,
     2,     3,     0,     0,     4,     5,     0,     7,     8,     9,
    10,    11,    81,    82,    83,    84,    85,     0,     0,     0,
     0,     0,     0,    86,     0,    66,    67,    87,     0,     0,
     0,     0,     0,     0,     0,    68,    69,    70,    71,    72,
    73,    74,    75,     0,    37,     0,     0,    38,    39,    40,
     0,     0,     0,     0,     0,     0,    41,    42,    37,     0,
    89,    38,    39,     0,    44,     0,     0,     0,     0,     0,
    41,    42,     0,     0,    43,     0,   154,     0,    44,    76,
    77,    78,    79,    80,    81,    82,    83,    84,    85,     0,
    66,    67,     0,     0,     0,    86,   155,     0,     0,    87,
    68,    69,    70,    71,    72,    73,    74,    75,     0,     0,
     0,    66,    67,     0,     0,     0,     0,     0,     0,     0,
     0,    68,    69,    70,    71,    72,    73,    74,    75,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,    76,    77,    78,    79,    80,    81,
    82,    83,    84,    85,     0,     0,     0,     0,     0,     0,
    86,   157,     0,     0,    87,    76,    77,    78,    79,    80,
    81,    82,    83,    84,    85,     0,    66,    67,     0,     0,
     0,    86,   163,     0,     0,    87,    68,    69,    70,    71,
    72,    73,    74,    75,     0,     0,     0,    66,    67,     0,
     0,     0,     0,     0,     0,     0,     0,    68,    69,    70,
    71,    72,    73,    74,    75,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
    76,    77,    78,    79,    80,    81,    82,    83,    84,    85,
     0,     0,     0,     0,     0,     0,    86,   164,     0,     0,
    87,    76,    77,    78,    79,    80,    81,    82,    83,    84,
    85,     0,    66,    67,     0,     0,     0,    86,     0,     0,
     0,    87,    68,    69,    70,    71,    72,    73,    74,     0,
     0,     0,     0,    66,    67,     0,     0,     0,     0,     0,
     0,     0,     0,    68,    69,    70,    71,    72,    73,    12,
    13,    14,    15,    16,    17,    18,    19,    20,    21,    22,
    23,    24,    25,    26,    27,    28,    76,    77,    78,    79,
    80,    81,    82,    83,    84,    85,     0,     0,     0,     0,
     0,     0,    86,     0,     0,     0,    87,    76,    77,    78,
    79,    80,    81,    82,    83,    84,    85,     0,    66,    67,
     0,     0,     0,    86,     0,     0,     0,    87,    68,    69,
    70,    71,    72,    73,     0,     0,     0,    66,    67,     0,
     0,     0,     0,     0,     0,     0,     0,    68,    69,    70,
    71,    72,    73,     0,     0,    66,    67,     0,     0,     0,
     0,     0,     0,     0,     0,    68,    69,    70,    71,    72,
    73,     0,     0,    77,    78,    79,    80,    81,    82,    83,
    84,    85,     0,     0,     0,     0,     0,     0,    86,     0,
     0,     0,    87,    78,    79,    80,    81,    82,    83,    84,
    85,     0,     0,     0,     0,     0,     0,    86,     0,    66,
    67,    87,    79,    80,    81,    82,    83,    84,    85,    68,
    69,    70,    71,     0,     0,    86,     0,     0,     0,    87,
     0,     0,     0,     0,     0,     0,     0,     0,    95,    96,
    97,    98,    99,   100,   101,   102,     0,     0,     0,     0,
     0,    95,    96,    97,    98,    99,   100,   101,   102,     0,
     0,     0,     0,     0,   145,     0,    79,    80,    81,    82,
    83,    84,    85,   104,     0,   146,   148,   145,     0,    86,
     0,     0,     0,    87,     0,     0,   104,     0,   146
};

static const short yycheck[] = {     9,
    10,    11,     0,     0,    57,    58,    57,    58,     3,     4,
   107,   108,     7,     8,    78,    10,    11,    12,    13,    14,
    75,    79,    77,    57,    58,    78,    66,    37,    38,    39,
    40,    41,    42,    66,     3,     4,    66,    47,     7,     8,
    50,    10,    11,    12,    13,    14,    44,    44,    82,   109,
     5,     6,    62,    66,    64,    65,     5,     6,    68,    69,
    70,    71,    72,    73,    66,    66,    76,    77,    78,    79,
    80,    81,    82,    83,    84,    85,    86,    87,    73,    74,
    66,    66,    77,    79,    94,    78,    81,   147,    75,   149,
    77,    78,    61,   103,   104,    64,    65,    66,    78,     0,
     0,    49,    -1,    -1,    73,    74,    89,    76,    77,   119,
   120,    -1,    81,    -1,    -1,    64,    65,    66,    67,    68,
    75,     5,     6,    -1,    79,     1,    75,     3,     4,    -1,
    79,     7,     8,     9,    10,    11,    12,    13,    14,    -1,
   150,    -1,    -1,    -1,   154,    -1,   156,    23,    24,    25,
    26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
    36,    37,    38,    39,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    48,    49,    50,    51,    52,    53,    54,    55,
    -1,    -1,    66,    67,    68,    61,    -1,    -1,    64,    65,
    66,    75,    -1,    -1,    -1,    79,    -1,    73,    74,    -1,
    -1,    77,     3,     4,    -1,    81,     7,     8,     9,    10,
    11,    12,    13,    14,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    23,    24,    25,    26,    27,    28,    29,    30,
    31,    32,    33,    34,    35,    36,    37,    38,    39,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    48,    49,    50,
    51,    52,    53,    54,    55,    -1,    -1,    -1,    -1,    -1,
    61,    -1,    -1,    64,    65,    66,    -1,    -1,    -1,    -1,
    -1,    -1,    73,    74,    -1,    -1,    77,     3,     4,    -1,
    81,     7,     8,     9,    10,    11,    12,    13,    14,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    23,    24,    25,
    26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
    36,    37,    38,    39,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    48,    49,    50,    51,    52,    53,    54,    55,
    -1,    -1,    -1,    -1,    -1,    61,    -1,    -1,    64,    65,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    73,    74,     3,
     4,    -1,    -1,     7,     8,    81,    10,    11,    12,    13,
    14,    -1,    -1,    -1,    -1,    -1,    -1,     3,     4,    -1,
    -1,     7,     8,    -1,    10,    11,    12,    13,    14,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    40,    41,    42,    43,
    44,    45,    46,    47,     3,     4,    -1,    -1,     7,     8,
    -1,    10,    11,    12,    13,    14,    -1,    61,    -1,    -1,
    64,    65,    66,    -1,    -1,    -1,    -1,    -1,    -1,    73,
    74,    75,    -1,    77,    -1,    61,    -1,    81,    64,    65,
    66,    -1,    -1,     5,     6,    -1,    -1,    73,    74,    -1,
    76,    77,    -1,    15,    16,    81,    -1,    -1,    -1,    -1,
    -1,    -1,    61,    -1,    -1,    64,    65,    66,    -1,    -1,
    -1,    -1,    -1,    -1,    73,    74,     3,     4,    77,    -1,
     7,     8,    81,    10,    11,    12,    13,    14,    -1,    -1,
     3,     4,    -1,    -1,     7,     8,    -1,    10,    11,    12,
    13,    14,    64,    65,    66,    67,    68,    -1,    -1,    -1,
    -1,    -1,    -1,    75,    -1,     5,     6,    79,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    15,    16,    17,    18,    19,
    20,    21,    22,    -1,    61,    -1,    -1,    64,    65,    66,
    -1,    -1,    -1,    -1,    -1,    -1,    73,    74,    61,    -1,
    77,    64,    65,    -1,    81,    -1,    -1,    -1,    -1,    -1,
    73,    74,    -1,    -1,    77,    -1,    56,    -1,    81,    59,
    60,    61,    62,    63,    64,    65,    66,    67,    68,    -1,
     5,     6,    -1,    -1,    -1,    75,    76,    -1,    -1,    79,
    15,    16,    17,    18,    19,    20,    21,    22,    -1,    -1,
    -1,     5,     6,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    15,    16,    17,    18,    19,    20,    21,    22,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    59,    60,    61,    62,    63,    64,
    65,    66,    67,    68,    -1,    -1,    -1,    -1,    -1,    -1,
    75,    76,    -1,    -1,    79,    59,    60,    61,    62,    63,
    64,    65,    66,    67,    68,    -1,     5,     6,    -1,    -1,
    -1,    75,    76,    -1,    -1,    79,    15,    16,    17,    18,
    19,    20,    21,    22,    -1,    -1,    -1,     5,     6,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    15,    16,    17,
    18,    19,    20,    21,    22,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    59,    60,    61,    62,    63,    64,    65,    66,    67,    68,
    -1,    -1,    -1,    -1,    -1,    -1,    75,    76,    -1,    -1,
    79,    59,    60,    61,    62,    63,    64,    65,    66,    67,
    68,    -1,     5,     6,    -1,    -1,    -1,    75,    -1,    -1,
    -1,    79,    15,    16,    17,    18,    19,    20,    21,    -1,
    -1,    -1,    -1,     5,     6,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    15,    16,    17,    18,    19,    20,    23,
    24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
    34,    35,    36,    37,    38,    39,    59,    60,    61,    62,
    63,    64,    65,    66,    67,    68,    -1,    -1,    -1,    -1,
    -1,    -1,    75,    -1,    -1,    -1,    79,    59,    60,    61,
    62,    63,    64,    65,    66,    67,    68,    -1,     5,     6,
    -1,    -1,    -1,    75,    -1,    -1,    -1,    79,    15,    16,
    17,    18,    19,    20,    -1,    -1,    -1,     5,     6,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    15,    16,    17,
    18,    19,    20,    -1,    -1,     5,     6,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    15,    16,    17,    18,    19,
    20,    -1,    -1,    60,    61,    62,    63,    64,    65,    66,
    67,    68,    -1,    -1,    -1,    -1,    -1,    -1,    75,    -1,
    -1,    -1,    79,    61,    62,    63,    64,    65,    66,    67,
    68,    -1,    -1,    -1,    -1,    -1,    -1,    75,    -1,     5,
     6,    79,    62,    63,    64,    65,    66,    67,    68,    15,
    16,    17,    18,    -1,    -1,    75,    -1,    -1,    -1,    79,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    40,    41,
    42,    43,    44,    45,    46,    47,    -1,    -1,    -1,    -1,
    -1,    40,    41,    42,    43,    44,    45,    46,    47,    -1,
    -1,    -1,    -1,    -1,    66,    -1,    62,    63,    64,    65,
    66,    67,    68,    75,    -1,    77,    78,    66,    -1,    75,
    -1,    -1,    -1,    79,    -1,    -1,    75,    -1,    77
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
	      free (yyss);
	      free (yyvs);
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
#line 389 "expr.y"
{
		    state->result = yyvsp[0].token;
		    if (state->freeStacks) {
			free(state->valStack);
			free(state->stateStack);
			YYACCEPT;
		    }
		;
    break;}
case 2:
#line 398 "expr.y"
{
		    if (state->freeStacks) {
			free(state->valStack);
			free(state->stateStack);
		    }
		    YYABORT;
		;
    break;}
case 3:
#line 409 "expr.y"
{
		    if (!ExprCast(state, &yyvsp[0].token, yyvsp[-1].type, &yyval.token, TRUE)) {
			YYERROR;
		    }
		;
    break;}
case 4:
#line 414 "expr.y"
{ yyval.token = yyvsp[0].token; ;
    break;}
case 5:
#line 416 "expr.y"
{
		    ExprStandardCoerce(state, &yyvsp[0].token);
		    if (yyvsp[0].token.what == TOKEN_LITERAL) {
			if (!ExprCast(state, &yyvsp[-2].token,
				      Type_CreateArray(0,
						       yyvsp[0].token.value.literal-1,
						       type_Int,
						       yyvsp[-2].token.type),
				      &yyval.token, TRUE))
			{
			    YYERROR;
			}
		    } else {
			xyyerror(state, "array length must be integral");
		    }
		;
    break;}
case 8:
#line 439 "expr.y"
{
		    int	class = Sym_Class(yyvsp[0].sym);
		    yyval.token.flags = 0;
		    yyval.token.what = TOKEN_ADDRESS;

		    if (class & SYM_MODULE) {
			yyval.token.value.addr.handle = ExprModuleToHandle(state, yyvsp[0].sym);
			yyval.token.value.addr.offset = 0;
			yyval.token.type = NullType;
		    } else if (class & (SYM_FUNCTION|SYM_LABEL)) {
			Type	retType;
			
			Sym_GetFuncData(yyvsp[0].sym, (Boolean *)NULL,
					&yyval.token.value.addr.offset,
					&retType);
			yyval.token.type = Type_CreateFunction(retType);
			yyval.token.value.addr.handle =
			    ExprModuleToHandle(state,
					       Sym_Scope(yyvsp[0].sym, FALSE));
		    } else if (class & (SYM_VAR|SYM_LOCALVAR)) {
			/*
			 * For variable symbols, we do as for function/
			 * label symbols, but we need to get the variable's
			 * type as well (plus there's the matter of the
			 * greater range of address types for variables
			 * [registers, etc.]).
			 */
			StorageClass	sClass;
			Address	    	offset;
			Type	    	type;
			
			Sym_GetVarData(yyvsp[0].sym, &type, &sClass, &offset);
			    
			switch(sClass) {
			    case SC_Static:
				yyval.token.value.addr.offset = offset;
				yyval.token.type = type;
				yyval.token.value.addr.handle =
				    ExprModuleToHandle(state,
						       Sym_Scope(yyvsp[0].sym, FALSE));
				break;
			    case SC_Parameter:
			    case SC_Local:
				if (state->frame == NullFrame) {
				    xyyerror(state, "%s has no stack",
					     state->patient->name);
				    YYERROR;
				} else {
				    word	fp;
                                    regval      fpval ;
				    
				    MD_GetFrameRegister(state->frame,
							REG_MACHINE,
							REG_FP,
							&fpval);
                                    fp = (word)fpval ;
				    yyval.token.value.addr.handle = Ibm_StackHandle();
				    yyval.token.value.addr.offset = offset+fp;
				    yyval.token.type = type;
				}
				break;
			    case SC_Register:
			    case SC_RegParam:
				if (state->frame == NullFrame) {
				    xyyerror(state, "%s has no stack",
					     state->patient->name);
				    YYERROR;
				} else {
				    regval	val;
				    
				    (*MD_GetFrameRegister)(state->frame,
							   REG_MACHINE,
							   (int)offset,
							   &val);
				    yyval.token.what = TOKEN_LITERAL;
				    yyval.token.value.literal = val;
				    /* try using the actual type rather than
				     * type_Word so things like enums whose
				     * values are stored in register variables
				     * will have type info in them
				     * 12/30/94 - jimmy
				     */
				    yyval.token.type = type;
				}
				break;
			    default:
				xyyerror(state,
					 "unknown storage class %d for %s",
					 sClass, Sym_Name(yyvsp[0].sym));
				YYERROR;
			}
		    } else if (class & SYM_FIELD) {
			int 	offset;
			Type	type;
			
			Sym_GetFieldData(yyvsp[0].sym, &offset, (int *)NULL, &type,
					 (Type *)NULL);
			ExprSetAsPointer(state, &yyval.token,
					 TYPE_PTR_FAR,
					 type,
					 NullHandle,
					 (Address)(offset/8));
		    } else {
			xyyerror(state,
				 "Unknown symbol class for %s",
				 Sym_Name(yyvsp[0].sym));
		    }
		;
    break;}
case 9:
#line 548 "expr.y"
{
		    ExprStandardCoerce(state, &yyvsp[0].token);
		    if (yyvsp[0].token.what != TOKEN_LITERAL) {
			yyerror("operand of ^h must be an integer");
			YYERROR;
		    } else {
			yyval.token.what = TOKEN_ADDRESS;
			yyval.token.value.addr.handle = Handle_Lookup((unsigned short)yyvsp[0].token.value.literal);
			yyval.token.value.addr.offset = 0;
			yyval.token.type = NullType;
			yyval.token.flags = 0;
		    }
		;
    break;}
case 13:
#line 564 "expr.y"
{ yyval.token = yyvsp[-1].token; ;
    break;}
case 14:
#line 565 "expr.y"
{ yyval.token = yyvsp[-1].token; ;
    break;}
case 15:
#line 567 "expr.y"
{
		    if ((yyvsp[-3].token.what != TOKEN_ADDRESS) &&
			((yyvsp[-3].token.what != TOKEN_POINTER) ||
			 (Type_Class(yyvsp[-3].token.type) != TYPE_POINTER)))
		    {
			yyerror("operand of [] must be a pointer or array");
			YYERROR;
		    } else {
			switch (Type_Class(yyvsp[-3].token.type)) {
			    default:
			    {
				/*
				 * Make life a bit easier by coercing the thing
				 * to an array of infinite size.
				 */
				unsigned	  	bound;
				
				bound = (1<<(Type_Sizeof(type_Int)*8-1))-1;
				yyvsp[-3].token.type =
				    Type_CreateArray(0, bound, type_Int,
						     yyvsp[-3].token.type);
				/*FALLTHRU*/
			    }
			    case TYPE_ARRAY:
			    case TYPE_POINTER:
				if (!ExprArithOrPointerOp(state, '+', &yyvsp[-3].token, &yyvsp[-1].token,
							  &yyval.token))
				{
				    YYERROR;
				}
		    	    	if (!ExprIndirect(state, &yyval.token, &yyval.token)) {
				    YYERROR;
				}
				break;
			}
		    }
		;
    break;}
case 16:
#line 605 "expr.y"
{
		    if ((yyvsp[-5].token.what != TOKEN_ADDRESS) &&
			((yyvsp[-5].token.what != TOKEN_POINTER) ||
			 (Type_Class(yyvsp[-5].token.type) != TYPE_POINTER)))
		    {
			yyerror("operand of [] must be a pointer or array");
			YYERROR;
		    } else {
			ExprStandardCoerce(state, &yyvsp[-3].token);
			ExprStandardCoerce(state, &yyvsp[-1].token);
			if (yyvsp[-3].token.what != TOKEN_LITERAL) {
			    yyerror("first index of array range must be integral");
			    YYERROR;
			}
			if (yyvsp[-1].token.what != TOKEN_LITERAL) {
			    yyerror("second index of array range must be integral");
			    YYERROR;
			}
			
			switch (Type_Class(yyvsp[-5].token.type)) {
			    default:
			    {
				/*
				 * Make life a bit easier by coercing the thing
				 * to an array of infinite size.
				 */
				unsigned	  	bound;
				
				bound = (1<<(Type_Sizeof(type_Int)*8-1))-1;
				yyvsp[-5].token.type =
				    Type_CreateArray(0, bound, type_Int,
						     yyvsp[-5].token.type);
				/*FALLTHRU*/
			    }
			    case TYPE_ARRAY:
			    case TYPE_POINTER:
				if (!ExprArithOrPointerOp(state, '+', &yyvsp[-5].token, &yyvsp[-3].token,
							  &yyval.token))
				{
				    YYERROR;
				}
				
				/*
				 * Now convert the thing back into an array
				 * starting at the address of the first element.
				 */
				if (yyval.token.what == TOKEN_POINTER &&
					   Type_Class(yyvsp[-5].token.type) == TYPE_POINTER)
				{
				    if (!ExprIndirect(state, &yyvsp[-5].token, &yyval.token)) {
					YYERROR;
				    }
				}
				if (yyval.token.what == TOKEN_ADDRESS) {
				    yyval.token.type =
					Type_CreateArray(0,
							 (yyvsp[-1].token.value.literal-
							  yyvsp[-3].token.value.literal),
							 type_Int,
							 yyval.token.type);
				} else {
				    xyyerror(state, "expression cannot be converted to an array");
				    YYERROR;
				}
				break;
			}
		    }
		;
    break;}
case 19:
#line 676 "expr.y"
{
		    int	  	offset;
		    int		length;
		    Type	type;

		    if (strcmp(yyvsp[0].token.value.str, "handle") == 0) {
			offset = 16;
			length = 16;
			type = Type_CreatePointer(type_Void,
						  TYPE_PTR_HANDLE);
		    } else if (strcmp(yyvsp[0].token.value.str, "segment") == 0) {
			offset = 16;
			length = 16;
			type = Type_CreatePointer(type_Void,
						  TYPE_PTR_SEG);
		    } else if (strcmp(yyvsp[0].token.value.str, "offset") == 0) {
			offset = 0;
			length = 16;
			type = type_Word;
		    } else if (strcmp(yyvsp[0].token.value.str, "chunk") == 0) {
			offset = 0;
			length = 16;
			type = Type_CreatePointer(type_Void,
						  TYPE_PTR_LMEM);
		    } else if (strcmp(yyvsp[0].token.value.str, "low") == 0) {
			offset = 0;
			if (Type_IsNull(yyvsp[-1].token.type) ||
			    Type_Sizeof(yyvsp[-1].token.type) == 4)
			{
			    length = 16;
			    type = type_Word;
			} else {
			    length = 8;
			    type = type_Byte;
			}
		    } else if (strcmp(yyvsp[0].token.value.str, "high") == 0) {
			if (Type_IsNull(yyvsp[-1].token.type) ||
			    Type_Sizeof(yyvsp[-1].token.type) == 4)
			{
			    offset = 16;
			    length = 16;
			    type = type_Word;
			} else {
			    offset = 8;
			    length = 8;
			    type = type_Byte;
			}
		    } else {
			switch(Type_Class(yyvsp[-1].token.type)) {
			    case TYPE_POINTER:
			    {
				Type    baseType;
				
				Type_GetPointerData(yyvsp[-1].token.type, (int *)NULL,
						    &baseType);
				
				switch(Type_Class(baseType)){
				    case TYPE_STRUCT:
				    case TYPE_UNION:
					ExprIndirect(state, &yyvsp[-1].token, &yyvsp[-1].token);
					break;
				    default:
					goto try_for_field_sym;
				}
				/*FALLTHRU*/
			    }
			    case TYPE_STRUCT:
			    case TYPE_UNION:
				if (Type_GetFieldData(yyvsp[-1].token.type,
						      yyvsp[0].token.value.str,
						      &offset,
						      &length, &type))
				{
				    break;
				}
				/*FALLTHRU*/
			    default:
			    {
				Sym	sym;
				
				try_for_field_sym:
				
				sym = Expr_FindSym(state->patient,
						   yyvsp[0].token.value.str);
				if (Sym_IsNull(sym)) {
				    xyyerror(state, "Field %s undefined",
					     yyvsp[0].token.value.str);
				    free((malloc_t)yyvsp[0].token.value.str);
				    YYERROR;
				} else if (!(Sym_Class(sym) & SYM_FIELD)) {
				    xyyerror(state,
					     "%s not a structure/union field",
					     yyvsp[0].token.value.str);
				    free((malloc_t)yyvsp[0].token.value.str);
				    YYERROR;
				} else {
				    Sym_GetFieldData(sym, &offset, &length,
						     &type, (Type *)NULL);
				}
				break;
			    }
			}
		    }

		    if (Type_IsRecord(yyvsp[-1].token.type)) {
			/*
			 * Must remove the bit offset of the data within
			 * the overarching field from the offset of the
			 * field itself, to deal with bitfields from the
			 * high byte of a 16-bit containing field (the
			 * bit offset will be dealt with when the value
			 * is fetched, but is also a part of "offset";
			 * if we didn't subtract out the bit offset, we'd
			 * be off by 8...)
			 */
			unsigned	fieldOff;
			unsigned    	widthOff;

			Type_GetFieldData(yyvsp[-1].token.type,
					  yyvsp[0].token.value.str,
					  (int *)&fieldOff,
					  (int *)&widthOff, NULL);
			offset -= fieldOff;
			/* if the type is not a bitfield type then create a
			 * bitfield type whose sub-type is type of the field
			 * so that assign and print can deal with these fields
			 * properly
			 */
			if (Type_Class(type) != TYPE_BITFIELD)
			{
			    type = Type_CreateBitField(fieldOff, widthOff, type);
			}
		    }
		    /*
		     * Now know the bit offset, data type, etc. of the field
		     * being referenced.
		     */
		    if (yyvsp[-1].token.what == TOKEN_ADDRESS) {
			/*
			 * The result is $1 after offseting by the byte offset
			 * that corresponds to the bit offset. 
			 */
			yyval.token = yyvsp[-1].token;
			yyval.token.value.addr.offset += offset/8;
			yyval.token.type = type;
			yyval.token.flags = 0;
		    } else if (yyvsp[-1].token.what == TOKEN_POINTER) {
			switch(Type_Class(yyvsp[-1].token.type)) {
			    case TYPE_POINTER:
			    {
				GeosAddr    *gap = yyvsp[-1].token.value.ptr;

				yyval.token.what = TOKEN_ADDRESS;
				yyval.token.value.addr.handle = gap->handle;
				yyval.token.value.addr.offset =
				    gap->offset + offset/8;
				break;
			    }
			    case TYPE_STRUCT:
				yyval.token.what = TOKEN_POINTER;
				yyval.token.value.ptr = (Opaque)
				    ((genptr)yyvsp[-1].token.value.ptr + offset/8);
				break;
			    case TYPE_UNION:
				yyval.token.what = TOKEN_POINTER;
				yyval.token.value.ptr = (Opaque)
				    ((genptr)yyvsp[-1].token.value.ptr + offset/8);
				if ((Type_Class(type) != TYPE_UNION) &&
				    swap)
				{
				    /*
				     * If was a union and now is a non-union,
				     * byte-swap data as necessary.
				     */
				    Var_SwapValue(VAR_FETCH, type,
						  Type_Sizeof(type),
						  yyval.token.value.ptr);
				}
				break;
			    default:
				xyyerror(state,
					 "expression is not a structure or union");
				free((malloc_t)yyvsp[0].token.value.str);
				YYERROR;
			}
			yyval.token.type = type;
			yyval.token.flags = 0;
		    } else if (yyvsp[-1].token.what == TOKEN_LITERAL) {
			/*
			 * To support ds:si.foo, pretend a literal is
			 * actually an address...
			 */
			yyval.token.what = TOKEN_ADDRESS;
			yyval.token.flags = 0;
			yyval.token.value.addr.handle = NullHandle;
			yyval.token.value.addr.offset = (Address)
			    (yyvsp[-1].token.value.literal + offset/8);
			yyval.token.type = type;
		    } else {
			assert(0);
		    }
		    free((malloc_t)yyvsp[0].token.value.str);
		;
    break;}
case 20:
#line 882 "expr.y"
{
		    if (yyvsp[0].token.what != TOKEN_ADDRESS) {
			yyerror("inappropriate operand of &");
			YYERROR;
		    } else {
			ExprSetAsPointer(state, &yyval.token,
					 TYPE_PTR_FAR,
					 yyvsp[0].token.type,
					 yyvsp[0].token.value.addr.handle,
					 yyvsp[0].token.value.addr.offset);
		    }
		;
    break;}
case 21:
#line 895 "expr.y"
{
		    ExprIndirect(state, &yyvsp[0].token, &yyval.token);
		;
    break;}
case 22:
#line 899 "expr.y"
{
		    ExprFetch(state, &yyvsp[0].token);
		    if (!ExprCoerce(state, &yyvsp[0].token, (ExprToken *)NULL, TRUE)) {
			yyerror("operand of unary + not arithmetic");
			YYERROR;
		    } else {
			yyval.token = yyvsp[0].token;
		    }
		;
    break;}
case 23:
#line 909 "expr.y"
{
		    ExprToken  zero;
		    
		    zero.what = TOKEN_LITERAL;
		    zero.value.literal = 0;
		    zero.flags = 0;
		    zero.type = type_Int;
		    
		    if (!ExprArithOp(state, '-', &zero, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 24:
#line 922 "expr.y"
{
		    ExprFetch(state, &yyvsp[0].token);
		    
		    if (!ExprCoerce(state, &yyvsp[0].token, (ExprToken *)NULL, FALSE)) {
			yyerror("operand of ~ must be integral");
			YYERROR;
		    } else if (yyvsp[0].token.what == TOKEN_LITERAL) {
			yyval.token = yyvsp[0].token;
			yyval.token.value.literal = ~yyval.token.value.literal;
		    } else {
			yyerror("invalid operand of ~");
			YYERROR;
		    }
		;
    break;}
case 25:
#line 937 "expr.y"
{
		    yyval.token.what = TOKEN_LITERAL;
		    yyval.token.type = type_Int;
		    yyval.token.flags = 0;
		    yyval.token.value.literal = ExprEvalBoolean(state, &yyvsp[0].token);
		    if (yyval.token.value.literal == -1) {
			yyerror("operand of ! must be arithmetic");
		    } else {
			yyval.token.value.literal = !yyval.token.value.literal;
		    }
		;
    break;}
case 26:
#line 949 "expr.y"
{
		    yyval.token.what = TOKEN_LITERAL;
		    yyval.token.value.literal = Type_Sizeof(yyvsp[0].token.type);
		    yyval.token.type = type_Int;
		    yyval.token.flags = 0;
		    ExprSidePop(state);
		;
    break;}
case 27:
#line 957 "expr.y"
{
		    yyval.token.what = TOKEN_LITERAL;
		    yyval.token.value.literal = Type_Sizeof(yyvsp[-1].type);
		    yyval.token.type = type_Int;
		    yyval.token.flags = 0;
		    ExprSidePop(state);
		;
    break;}
case 28:
#line 965 "expr.y"
{
		    ExprStandardCoerce(state, &yyvsp[0].token);
		    if (yyvsp[0].token.what != TOKEN_LITERAL) {
			yyerror("operand of ^l must be an integer");
			YYERROR;
		    } else {
			yyval.token.what = TOKEN_ADDRESS;
			yyval.token.value.addr.handle = Handle_Lookup((unsigned short)yyvsp[0].token.value.literal);
			yyval.token.value.addr.offset = 0;
			yyval.token.type = NullType;
			yyval.token.flags = ETF_LMEM_INDIR_PENDING;
		    }
		;
    break;}
case 29:
#line 979 "expr.y"
{
		    /*
		     * VMem handle -- segment is actually a VM file handle ID.
		     * Offset will be a VM block, but that's taken care of
		     * by expr ':' expr
		     */

		    ExprStandardCoerce(state, &yyvsp[0].token);
		    if (yyvsp[0].token.what != TOKEN_LITERAL) {
			yyerror("operand of ^v must be an integer");
			YYERROR;
		    } else {
			if (ExprIndirectVMPart1(state,
						yyvsp[0].token.value.literal,
						&yyval.token.value.addr))
			{
			    yyval.token.what = TOKEN_ADDRESS;
			    yyval.token.type = NullType;
			    yyval.token.flags = ETF_VMEM_INDIR_PENDING;
			} else {
			    YYERROR;
			}
		    }
		;
    break;}
case 30:
#line 1006 "expr.y"
{
		    ExprSidePush(TRUE, state);
		;
    break;}
case 31:
#line 1012 "expr.y"
{
		    /*
		     * We're gonna need the value, at least we need to correct
		     * for the types of functions and arrays...
		     */
		    if (!ExprCast(state, &yyvsp[0].token, yyvsp[-2].type, &yyval.token, FALSE)) {
			YYERROR;
		    }
		;
    break;}
case 32:
#line 1022 "expr.y"
{
		    if (!ExprArithOp(state, '*', &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 33:
#line 1028 "expr.y"
{
		    if (!ExprArithOp(state, '/', &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 34:
#line 1034 "expr.y"
{
		    if (!ExprIntOp(state, '%', &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 35:
#line 1040 "expr.y"
{
		    if (!ExprArithOrPointerOp(state, '+', &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 36:
#line 1046 "expr.y"
{
		    if (!ExprArithOrPointerOp(state, '-', &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 37:
#line 1052 "expr.y"
{
		    if (!ExprIntOp(state, LEFT_OP, &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 38:
#line 1058 "expr.y"
{
		    if (!ExprIntOp(state, RIGHT_OP, &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 39:
#line 1064 "expr.y"
{
		    if (!ExprRelOp(state, '<', &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 40:
#line 1070 "expr.y"
{
		    if (!ExprRelOp(state, '>', &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 41:
#line 1076 "expr.y"
{
		    if (!ExprRelOp(state, LE_OP, &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 42:
#line 1082 "expr.y"
{
		    if (!ExprRelOp(state, GE_OP, &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 43:
#line 1088 "expr.y"
{
		    if (!ExprRelOp(state, EQ_OP, &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 44:
#line 1094 "expr.y"
{
		    if (!ExprRelOp(state, NE_OP, &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 45:
#line 1100 "expr.y"
{
		    if (!ExprIntOp(state, '&', &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 46:
#line 1106 "expr.y"
{
		    if (!ExprIntOp(state, '^', &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 47:
#line 1112 "expr.y"
{
		    if (!ExprIntOp(state, '|', &yyvsp[-2].token, &yyvsp[0].token, &yyval.token)) {
			YYERROR;
		    }
		;
    break;}
case 48:
#line 1118 "expr.y"
{
		    /*
		     * See if we should evaluate the rhs. If the lhs is FALSE,
		     * we shouldn't. We use the value of this action to tell the
		     * later action what we decided. 1 means don't worry about
		     * the rhs. 0 means use the rhs.
		     */
		    if (!state->noSideEffects) {
			Boolean	    newSideEffects;
			int	    val;
			
			val = ExprEvalBoolean(state, &yyvsp[-1].token);
			if (val < 0) {
			    YYERROR;
			} else {
			    newSideEffects = !val;
			}
			yyval.op = newSideEffects;
			ExprSidePush(newSideEffects, state);
		    } else {
			yyval.op = 0;
		    }
		;
    break;}
case 49:
#line 1142 "expr.y"
{
		    yyval.token.what = TOKEN_LITERAL;
		    if (yyvsp[-1].op) {
			ExprSidePop(state);
			yyval.token.value.literal = 0;
		    } else if (!state->noSideEffects) {
			int	val;
			
			val = ExprEvalBoolean(state, &yyvsp[0].token);
			if (val < 0) {
			    YYERROR;
			} else {
			    yyval.token.value.literal = val;
			}
		    }
		    yyval.token.type = type_Int;
		    yyval.token.flags = 0;
		;
    break;}
case 50:
#line 1161 "expr.y"
{
		    /*
		     * See if we should evaluate the rhs. If the lhs is TRUE,
		     * we shouldn't. We use the value of this action to tell
		     * the later action what we decided. 1 means don't worry
		     * about the rhs. 0 means use the rhs.
		     */
		    if (!state->noSideEffects) {
			Boolean	    newSideEffects;
			int	    val;
			
			val = ExprEvalBoolean(state, &yyvsp[-1].token);
			if (val < 0) {
			    YYERROR;
			} else {
			    newSideEffects = val;
			}
			yyval.op = newSideEffects;
			ExprSidePush(newSideEffects, state);
		    } else {
			yyval.op = 0;
		    }
		;
    break;}
case 51:
#line 1185 "expr.y"
{
		    yyval.token.what = TOKEN_LITERAL;
		    if (yyvsp[-1].op) {
			ExprSidePop(state);
			yyval.token.value.literal = 1;
		    } else if (!state->noSideEffects) {
			int	val;
			
			val = ExprEvalBoolean(state, &yyvsp[0].token);
			if (val < 0) {
			    YYERROR;
			} else {
			    yyval.token.value.literal = val;
			}
		    }
		    yyval.token.type = type_Int;
		    yyval.token.flags = 0;
		;
    break;}
case 52:
#line 1204 "expr.y"
{
		    Handle	handle;
		    Address 	offset;

		    ExprFetch(state, &yyvsp[-2].token);
		    ExprFetch(state, &yyvsp[0].token);
		    
		    /*
		     * Cope with fetched pointer values by indirecting
		     * through them. This reduces the cases with which we
		     * have to deal, converting the darn things to
		     * TOKEN_ADDRESS tokens.
		     */
		    if ((yyvsp[-2].token.what == TOKEN_POINTER) &&
			(Type_Class(yyvsp[-2].token.type) == TYPE_POINTER))
		    {
			ExprIndirect(state, &yyvsp[-2].token, &yyvsp[-2].token);
		    }
		    
		    if ((yyvsp[0].token.what == TOKEN_POINTER) &&
			(Type_Class(yyvsp[0].token.type) == TYPE_POINTER))
		    {
			ExprIndirect(state, &yyvsp[0].token, &yyvsp[0].token);
		    }
		    
		    /*
		     * Find the right handle.
		     */
		    if ((yyvsp[-2].token.what == TOKEN_ADDRESS) &&
			(yyvsp[-2].token.value.addr.handle != NullHandle) &&
			!(yyvsp[-2].token.flags & ETF_HANDLE_FROM_INDIR))
		    {
			/*
			 * Handle is real (not just carried along from an
			 * indirection)
			 */
			handle = yyvsp[-2].token.value.addr.handle;

			/*
			 * Deal with special indirections (lmem & vmem)
			 */
			if (yyvsp[-2].token.flags & ETF_LMEM_INDIR_PENDING) {
			    /*
			     * Perform LMem indirection, using $3.offset as
			     * a chunk handle.
			     */
			    word    w;	    /* value in chunk handle */

			    ExprStandardCoerce(state, &yyvsp[0].token);

			    if (yyvsp[0].token.what == TOKEN_ADDRESS) {
				Var_FetchInt(2, yyvsp[-2].token.value.addr.handle,
					     yyvsp[0].token.value.addr.offset,
					     (genptr)&w);
				yyval.token.type = yyvsp[0].token.type;
			    } else if (yyvsp[0].token.what == TOKEN_LITERAL) {
				Var_FetchInt(2, yyvsp[-2].token.value.addr.handle,
					     (Address)yyvsp[0].token.value.literal,
					     (genptr)&w);
				yyval.token.type = NullType;
			    } else {
				YYERROR;
			    }
			    offset = (Address)w;
			} else if (yyvsp[-2].token.flags & ETF_VMEM_INDIR_PENDING) {
			    /*
			     * Perform VMem indirection, using $3.offset as
			     * a VM block handle.
			     */
			    word    block;

			    ExprStandardCoerce(state, &yyvsp[0].token);
			    /*
			     * Now extract the memory handle from
			     * header:offset, which is where the thing is
			     * stored in an in-use VM block handle.
			     * XXX: Make sure block is in-use
			     */
			    
			    if (yyvsp[0].token.what == TOKEN_ADDRESS) {
				block = (word)yyvsp[0].token.value.addr.offset;
				yyval.token.type = yyvsp[0].token.type;
			    } else if (yyvsp[0].token.what == TOKEN_LITERAL) {
				block = yyvsp[0].token.value.literal;
				yyval.token.type = NullType;
			    } else {
				YYERROR;
			    }

			    if (ExprIndirectVMPart2(state,
						    yyvsp[-2].token.value.addr.handle,
						    block,
						    &yyval.token.value.addr))
			    {
				yyval.token.flags = 0;
				handle = yyval.token.value.addr.handle;
				offset = yyval.token.value.addr.offset;
			    } else {
				YYERROR;
			    }
			} else if (yyvsp[0].token.what == TOKEN_ADDRESS) {
			    offset = yyvsp[0].token.value.addr.offset;
			    yyval.token.type = yyvsp[0].token.type;
			} else if (yyvsp[0].token.what == TOKEN_LITERAL) {
			    offset = (Address)yyvsp[0].token.value.literal;
			    yyval.token.type = NullType;
			} else {
			    YYERROR;
			}
		    } else {
			/*
			 * Handle in $1 uninteresting -- use the offset
			 * as a segment address to find the right one.
			 * Add the offset from $3 in so we resolve to the
			 * handle that covers the absolute address, rather
			 * than the one whose segment we have...
			 */
			word	    segment;
			
			if (yyvsp[-2].token.what == TOKEN_ADDRESS) {
			    segment = (word)yyvsp[-2].token.value.addr.offset;
			} else if (yyvsp[-2].token.what == TOKEN_LITERAL) {
			    segment = (word)yyvsp[-2].token.value.literal;
			} else {
			    YYERROR;
			}
			if (yyvsp[0].token.what == TOKEN_ADDRESS) {
			    handle = Handle_Find(MakeAddress(segment,
						 yyvsp[0].token.value.addr.offset));
			    yyval.token.type = yyvsp[0].token.type;
			} else if (yyvsp[0].token.what == TOKEN_LITERAL) {
			    handle = Handle_Find(MakeAddress(segment,
						 yyvsp[0].token.value.literal));
			    yyval.token.type = NullType;
			} else {
			    YYERROR;
			}

			if (handle == NullHandle) {
			    /*
			     * No handle covering it -- make it absolute
			     */
			    handle = NullHandle;
			    if (yyvsp[0].token.what == TOKEN_ADDRESS) {
				offset = MakeAddress(segment, yyvsp[0].token.value.addr.offset);
			    } else {
				offset = MakeAddress(segment, yyvsp[0].token.value.literal);
			    }
			} else if (Handle_Segment(handle) != segment) {
			    /*
			     * The segment of the handle doesn't match the
			     * desired one. If the difference is too great for
			     * the stub to handle (i.e. > 64K), turn the thing
			     * into an absolute address. Otherwise, add the
			     * difference into the offset so we're referencing
			     * the right address.
			     */
			    dword	off;
			    dword	diff;
			    
			    diff = MakeSegOff((segment-Handle_Segment(handle)), 0) ;
			    if (yyvsp[0].token.what == TOKEN_ADDRESS) {
				off = (dword)yyvsp[0].token.value.addr.offset;
			    } else if (yyvsp[0].token.what == TOKEN_LITERAL) {
				off = yyvsp[0].token.value.literal;
			    } else {
				YYERROR;
			    }

#if GEOS32
			    handle = NullHandle;
			    offset = MakeAddress(segment, off) ;
#else			    
			    if (off+diff >= 0x10000) {
				/*
				 * More than can be encompassed...
				 */
				handle = NullHandle;
				offset = MakeAddress(segment, off) ;
			    } else {
				offset = (Address)(off+diff);
			    }
#endif
			} else {
			    if (yyvsp[0].token.what == TOKEN_ADDRESS) {
				offset = yyvsp[0].token.value.addr.offset;
			    } else if (yyvsp[0].token.what == TOKEN_LITERAL) {
				offset = (Address)yyvsp[0].token.value.literal;
			    } else {
				YYERROR;
			    }
			}
		    }
		    /*
		     * This used to make it a TOKEN_POINTER if the type was
		     * non-null, but I can't see why...
		     */
		    yyval.token.what = TOKEN_ADDRESS;
		    yyval.token.value.addr.handle = handle;
		    yyval.token.value.addr.offset = offset;
		    yyval.token.flags = 0;
		;
    break;}
case 53:
#line 1408 "expr.y"
{ yyval.op = TYPE_MOD_CHAR; ;
    break;}
case 54:
#line 1409 "expr.y"
{ yyval.op = TYPE_MOD_SHORT; ;
    break;}
case 55:
#line 1410 "expr.y"
{ yyval.op = TYPE_MOD_INT; ;
    break;}
case 56:
#line 1411 "expr.y"
{ yyval.op = TYPE_MOD_LONG; ;
    break;}
case 57:
#line 1412 "expr.y"
{ yyval.op = TYPE_MOD_SIGNED; ;
    break;}
case 58:
#line 1413 "expr.y"
{ yyval.op = TYPE_MOD_FLOAT; ;
    break;}
case 59:
#line 1414 "expr.y"
{ yyval.op = TYPE_MOD_DOUBLE; ;
    break;}
case 60:
#line 1415 "expr.y"
{ yyval.op = TYPE_MOD_UNSIGNED; ;
    break;}
case 61:
#line 1416 "expr.y"
{ yyval.op = TYPE_MOD_VOID; ;
    break;}
case 62:
#line 1417 "expr.y"
{ yyval.op = TYPE_MOD_CONST; ;
    break;}
case 63:
#line 1418 "expr.y"
{ yyval.op = TYPE_MOD_VOLATILE; ;
    break;}
case 64:
#line 1419 "expr.y"
{ yyval.op = TYPE_MOD_SHORT|TYPE_MOD_UNSIGNED; ;
    break;}
case 65:
#line 1420 "expr.y"
{ yyval.op = TYPE_MOD_CHAR|TYPE_MOD_UNSIGNED; ;
    break;}
case 66:
#line 1421 "expr.y"
{ yyval.op = TYPE_MOD_LONG|TYPE_MOD_UNSIGNED; ;
    break;}
case 67:
#line 1422 "expr.y"
{ yyval.op = TYPE_MOD_SHORT; ;
    break;}
case 68:
#line 1423 "expr.y"
{ yyval.op = TYPE_MOD_CHAR; ;
    break;}
case 69:
#line 1424 "expr.y"
{ yyval.op = TYPE_MOD_LONG; ;
    break;}
case 71:
#line 1429 "expr.y"
{
		    yyval.op = yyvsp[-1].op | yyvsp[0].op;
		;
    break;}
case 72:
#line 1440 "expr.y"
{
		    yyval.type = yyvsp[0].type;
		;
    break;}
case 73:
#line 1446 "expr.y"
{
		    switch (yyvsp[0].op & ~(TYPE_MOD_VOLATILE|TYPE_MOD_CONST|
				   TYPE_MOD_UNSIGNED|TYPE_MOD_SIGNED))
		    {
			case TYPE_MOD_SHORT:
			case TYPE_MOD_SHORT|TYPE_MOD_INT:
			    if (yyvsp[0].op & TYPE_MOD_UNSIGNED) {
				yyval.type = type_UnsignedShort;
			    } else {
				yyval.type = type_Short;
			    }
			    break;
			case TYPE_MOD_LONG:
			case TYPE_MOD_LONG|TYPE_MOD_INT:
			    if (yyvsp[0].op & TYPE_MOD_UNSIGNED) {
				yyval.type = type_UnsignedLong;
			    } else {
				yyval.type = type_Long;
			    }
			    break;
			case 0:
			case TYPE_MOD_INT:
			    if (yyvsp[0].op & TYPE_MOD_UNSIGNED) {
				yyval.type = type_UnsignedInt;
			    } else {
				yyval.type = type_Int;
			    }
			    break;
		        case TYPE_MOD_LONG|TYPE_MOD_DOUBLE:
			    if (yyvsp[0].op & (TYPE_MOD_UNSIGNED|TYPE_MOD_SIGNED)) {
				yyerror("invalid type combination");
				YYERROR;
			    } else {
				yyval.type = type_LongDouble;
			    }
			    break;
			case TYPE_MOD_LONG|TYPE_MOD_FLOAT:
			case TYPE_MOD_DOUBLE:
			    if (yyvsp[0].op & (TYPE_MOD_UNSIGNED|TYPE_MOD_SIGNED)) {
				yyerror("invalid type combination");
				YYERROR;
			    } else {
				yyval.type = type_Double;
			    }
			    break;
			case TYPE_MOD_FLOAT:
			    if (yyvsp[0].op & (TYPE_MOD_UNSIGNED|TYPE_MOD_SIGNED)) {
				yyerror("invalid type combination");
				YYERROR;
			    } else {
				yyval.type = type_Float;
			    }
			    break;
			case TYPE_MOD_CHAR:
			    if (yyvsp[0].op & TYPE_MOD_UNSIGNED) {
				yyval.type = type_Byte;
			    } else {
				yyval.type = type_Char;
			    }
			    break;
			case TYPE_MOD_VOID:
			    if ((yyvsp[0].op & ~TYPE_MOD_VOID) == 0) {
				yyval.type = type_Void;
				break;
			    }
			    /*FALLTHRU*/
			default:
			    yyerror("illegal type combination");
			    YYERROR;
		    }
		;
    break;}
case 75:
#line 1519 "expr.y"
{
		    yyval.type = Type_CreatePointer(type_Void, TYPE_PTR_LMEM);
		;
    break;}
case 76:
#line 1523 "expr.y"
{
		    yyval.type = Type_CreatePointer(type_Void, TYPE_PTR_FAR);
		;
    break;}
case 77:
#line 1527 "expr.y"
{
		    yyval.type = Type_CreatePointer(type_Void, TYPE_PTR_NEAR);
		;
    break;}
case 78:
#line 1531 "expr.y"
{
		    yyval.type = Type_CreatePointer(type_Void, TYPE_PTR_SEG);
		;
    break;}
case 79:
#line 1535 "expr.y"
{
		    yyval.type = Type_CreatePointer(type_Void, TYPE_PTR_OBJECT);
		;
    break;}
case 80:
#line 1539 "expr.y"
{
		    yyval.type = Type_CreatePointer(type_Void, TYPE_PTR_HANDLE);
		;
    break;}
case 81:
#line 1543 "expr.y"
{
		    yyval.type = Type_CreatePointer(type_Void, TYPE_PTR_VM);
		;
    break;}
case 82:
#line 1547 "expr.y"
{
		    yyval.type = Type_CreatePointer(type_Void, TYPE_PTR_VIRTUAL);
		;
    break;}
case 83:
#line 1553 "expr.y"
{
		    yyval.type = yyvsp[0].type;
		;
    break;}
case 85:
#line 1564 "expr.y"
{
		    yyval.type = Type_CreatePointer(yyvsp[-1].type, TYPE_PTR_FAR);
		;
    break;}
case 86:
#line 1568 "expr.y"
{
		    yyval.type = Type_CreatePointer(yyvsp[-2].type, TYPE_PTR_LMEM);
		;
    break;}
case 87:
#line 1572 "expr.y"
{
		    yyval.type = Type_CreatePointer(yyvsp[-2].type, TYPE_PTR_FAR);
		;
    break;}
case 88:
#line 1576 "expr.y"
{
		    yyval.type = Type_CreatePointer(yyvsp[-2].type, TYPE_PTR_NEAR);
		;
    break;}
case 89:
#line 1580 "expr.y"
{
		    yyval.type = Type_CreatePointer(yyvsp[-2].type, TYPE_PTR_SEG);
		;
    break;}
case 90:
#line 1584 "expr.y"
{
		    yyval.type = Type_CreatePointer(yyvsp[-2].type, TYPE_PTR_OBJECT);
		;
    break;}
case 91:
#line 1588 "expr.y"
{
		    yyval.type = Type_CreatePointer(yyvsp[-2].type, TYPE_PTR_HANDLE);
		;
    break;}
case 92:
#line 1592 "expr.y"
{
		    yyval.type = Type_CreatePointer(yyvsp[-2].type, TYPE_PTR_VIRTUAL);
		;
    break;}
case 93:
#line 1596 "expr.y"
{
		    yyval.type = Type_CreatePointer(yyvsp[-2].type, TYPE_PTR_VM);
		;
    break;}
case 94:
#line 1600 "expr.y"
{ yyval.type = yyvsp[-1].type; ;
    break;}
case 95:
#line 1603 "expr.y"
{
		    yyval.type = yyvsp[-1].type;
		;
    break;}
case 96:
#line 1607 "expr.y"
{
		    yyval.type = yyvsp[0].type;
		;
    break;}
case 98:
#line 1612 "expr.y"
{
		    switch (Type_Class(yyvsp[-2].type)) {
			case TYPE_POINTER:
			{
			    Type	baseType;
			    int 	ptrType;
			
			    Type_GetPointerData(yyvsp[-2].type, &ptrType, &baseType);
			    yyval.type = Type_CreatePointer(Type_CreateFunction(baseType),
						    ptrType);
			    break;
			}
			case TYPE_ARRAY:
			{
			    Type    	baseType;
			    Type    	indexType;
			    int	    	min, max;

			    Type_GetArrayData(yyvsp[-2].type, &min, &max, &indexType,
					      &baseType);
			    yyval.type = Type_CreateArray(min, max, indexType,
						  Type_CreateFunction(baseType));
			    break;
			}
			default:
			    yyerror("cannot cast to a function");
			    YYERROR;
		    }
		;
    break;}
case 99:
#line 1642 "expr.y"
{
		    switch (Type_Class(yyvsp[-2].type)) {
			case TYPE_POINTER:
			{
			    Type	baseType;
			    int 	ptrType;
			
			    Type_GetPointerData(yyvsp[-2].type, &ptrType, &baseType);
			    yyval.type = Type_CreatePointer(Type_CreateFunction(baseType),
						    ptrType);
			    break;
			}
			case TYPE_ARRAY:
			{
			    Type    	baseType;
			    Type    	indexType;
			    int	    	min, max;

			    Type_GetArrayData(yyvsp[-2].type, &min, &max, &indexType,
					      &baseType);
			    yyval.type = Type_CreateArray(min, max, indexType,
						  Type_CreateFunction(baseType));
			    break;
			}
			default:
			    yyerror("cannot cast to a function");
			    YYERROR;
		    }
		;
    break;}
case 100:
#line 1672 "expr.y"
{
		    unsigned	  	bound;
		    
		    bound = (1 << (Type_Sizeof(type_Int) * 8 - 1)) - 1;
		    yyval.type = Type_CreateArray(0, bound, type_Int, yyvsp[-2].type);
		;
    break;}
case 101:
#line 1679 "expr.y"
{
		    if (!ExprCoerce(state, &yyvsp[-1].token, (ExprToken *)NULL, FALSE)) {
			YYERROR;
		    } else if (yyvsp[-1].token.what == TOKEN_LITERAL) {
			yyval.type = Type_CreateArray(0, yyvsp[-1].token.value.literal-1,
					      type_Int, yyvsp[-3].type);
		    } else {
			yyerror("array dimension must be integral");
		    }
		;
    break;}
case 102:
#line 1690 "expr.y"
{
		    unsigned	  	bound;
		    
		    /*
		     * Figure max unsigned int and use as upper bound for array.
		     */
		    bound = (1 << (Type_Sizeof(type_Int) * 8 - 1)) - 1;
		    yyval.type = Type_CreateArray(0, bound, type_Int, yyvsp[-2].type);
		;
    break;}
case 103:
#line 1700 "expr.y"
{
		    if (!ExprCoerce(state, &yyvsp[-1].token, (ExprToken *)NULL, FALSE)) {
			YYERROR;
		    } else if (yyvsp[-1].token.what == TOKEN_LITERAL) {
			yyval.type = Type_CreateArray(0, yyvsp[-1].token.value.literal-1, type_Int,
					      yyvsp[-3].type);
		    } else {
			yyerror("array dimension must be integral");
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
      free (yyss);
      free (yyvs);
#ifdef YYLSP_NEEDED
      free (yyls);
#endif
    }
  return 0;

 yyabortlab:
  /* YYABORT comes here.  */
  if (yyfree_stacks)
    {
      free (yyss);
      free (yyvs);
#ifdef YYLSP_NEEDED
      free (yyls);
#endif
    }
  return 1;
}
#line 1712 "expr.y"



/***********************************************************************
 *				ExprMalloc
 ***********************************************************************
 * SYNOPSIS:	Allocate memory for the expression parser, making sure
 *	    	result ends up on the "data" list of the parser state
 *	    	so it gets freed at the end of the parse.
 * CALLED BY:	(INTERNAL)
 * RETURN:	allocated block
 * SIDE EFFECTS:element added to data list
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/19/94		Initial Revision
 *
 ***********************************************************************/
static malloc_t
ExprMalloc(ExprState *state, unsigned size)
{
    malloc_t	  result = malloc_tagged(size, TAG_EXPR);

    (void)Lst_AtEnd(state->data, (LstClientData)result);

    return(result);
}

/***********************************************************************
 *				ExprStackOverflow
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
ExprStackOverflow(ExprState *state,
		  char	    *msg,   	    /* Message if we decide not to */
		  short	    **stateStack,   /* Current state stack */
		  size_t    stateSize,      /* Current state stack size */
		  void	    **valStack,	    /* Current value stack */
		  size_t    valsSize,       /* Current value stack size */
		  int	    *maxDepth)      /* Current maximum stack depth of
					     * all stacks */
{
    *maxDepth *= 2;

    if (malloc_size((malloc_t)(*stateStack)) != 0) {
	/*
	 * we've been called before. Just use realloc()
	 */
	*stateStack = (short *)realloc((char *)*stateStack, stateSize * 2);
	*valStack = (YYSTYPE *)realloc((char *)*valStack, valsSize * 2);
    } else {
	short	*newstate;
	YYSTYPE	*newvals;

	newstate = (short *)malloc(stateSize * 2);
	newvals = (YYSTYPE *)malloc(valsSize * 2);

	bcopy((char *)*stateStack, (char *)newstate, stateSize);
	bcopy((char *)*valStack, (char *)newvals, valsSize);

	*stateStack = newstate;
	*valStack = newvals;
    }

    state->freeStacks = TRUE;
    state->valStack = *valStack;
    state->stateStack = *stateStack;
}


/***********************************************************************
 *				ExprSetAsPointer
 ***********************************************************************
 * SYNOPSIS:	    Set a handle and offset as a value fetched from a
 *	    	    pointer in a manner appropriate to the way we're
 *	    	    parsing the address.
 * CALLED BY:	    xyyparse
 * RETURN:	    nothing
 * SIDE EFFECTS:    *resultPtr set up. GeosAddr may be allocated.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/23/92		Initial Revision
 *
 ***********************************************************************/
static void
ExprSetAsPointer(ExprState *state,
		 ExprToken  *resultPtr,
		 int	    ptrType,
		 Type	    baseType,
		 Handle	    handle,
		 Address    offset)
{
    resultPtr->type = Type_CreatePointer(baseType, ptrType);
    resultPtr->value.ptr = (Opaque)ExprMalloc(state,sizeof(GeosAddr));
    resultPtr->what = TOKEN_POINTER;
    ((GeosAddr *)resultPtr->value.ptr)->handle = handle;
    ((GeosAddr *)resultPtr->value.ptr)->offset = offset;
    resultPtr->flags = 0;
}
	

/***********************************************************************
 *				ExprDebug
 ***********************************************************************
 * SYNOPSIS:	  Routine for controlled debug output
 * CALLED BY:	  xyyparse
 * RETURN:	  nothing
 * SIDE EFFECTS:  ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/23/92		Initial Revision
 *
 ***********************************************************************/
static void
ExprDebug(FILE *stream, const char *fmt, ...)
{
    va_list args;
    char    str[1024];

    va_start(args, fmt);
    vsprintf(str, fmt, args);
    Message(str);

    va_end(args);
}

/*
 * Lexical analyzer. Must be here to catch the token values.
 */

/***********************************************************************
 *				ExprModuleToHandle
 ***********************************************************************
 * SYNOPSIS:	    Map a module symbol to its handle
 * CALLED BY:	    yyparse
 * RETURN:	    The Handle for the module
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Look through the resource descriptors for the patient
 *		    that owns the module for one whose sym field matches.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 3/89		Initial Revision
 *
 ***********************************************************************/
static Handle
ExprModuleToHandle(ExprState   *state,
		   Sym	    	sym)
{
    Patient	patient;
    ResourcePtr	rp;
    int		i;
    
    patient = Sym_Patient(sym);
    
    /*
     * If the module has a parent that isn't the global
     * scope, it must just be a segment in a group. Its
     * enclosing scope is the symbol we want when
     * trying to find the proper handle.
     */
    if (!Sym_Equal(Sym_Scope(sym, FALSE),patient->global)) {
	sym = Sym_Scope(sym, FALSE);
	if (Sym_IsNull(sym))
	{
	    xyyerror(state, "Bad scope");
	    return (NullHandle);
	}
    }
    
    assert(patient != NullPatient);
    assert(patient->resources != (ResourcePtr)NULL);
    
    for(i = patient->numRes, rp = patient->resources; i > 0; i--, rp++) {
	if (Sym_Equal(rp->sym,sym)) {
	    return(rp->handle);
	}
    }
    
    xyyerror(state, "%s has no handle?", Sym_Name(sym));
    return(NullHandle);
}

/***********************************************************************
 *				xyyerror
 ***********************************************************************
 * SYNOPSIS:	    Report an error in an expression
 * CALLED BY:	    yyparse, yylex
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 9/88	Initial Revision
 *
 ***********************************************************************/
static void
xyyerror(ExprState *state, const char *fmt, ...)
{
    va_list args;
    
    if (!state->doneError) {
	state->doneError = TRUE;

	/*
	 * Point to default return area...
	 */
	Tcl_Return(interp, NULL, TCL_STATIC);
	
	va_start(args, fmt);
	vsprintf((char *)interp->result, fmt, args);
	va_end(args);
    }
}

/***********************************************************************
 *				yyid
 ***********************************************************************
 * SYNOPSIS:	    Scan off an identifier from the expression
 * CALLED BY:	    yylex
 * RETURN:	    Buffer is filled.
 * SIDE EFFECTS:    curExpr advanced to first non-blank following id.
 *
 * STRATEGY:	    None.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 9/88	Initial Revision
 *
 ***********************************************************************/
static void
yyid(char   **exprPtr,
     char *buffer)
{
    while (isalnum(**exprPtr) || (**exprPtr == '$') || (**exprPtr == '?') ||
	   (**exprPtr == '_') || (**exprPtr == '@'))
    {
	*buffer++ = *(*exprPtr)++;
    }
    while (isspace(**exprPtr)) {
	(*exprPtr)++;
    }
    *buffer = '\0';
}


/***********************************************************************
 *				yyfullid
 ***********************************************************************
 * SYNOPSIS:	    Fetch the full identifier (i.e. including any
 *	    	    symbol path information) into the passed buffer
 * CALLED BY:	    ExprScan
 * RETURN:	    passed buffer filled with identifier
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/11/92		Initial Revision
 *
 ***********************************************************************/
static void
yyfullid(char	**exprPtr,
	 char	*buffer)
{
    char    	  *cp;
    
    yyid(exprPtr, buffer);
    
    /*
     * If field is followed by a double colon, we need to get to the
     * part that isn't followed by a double colon so the parser
     * can pass the whole thing off to Sym_Lookup at once and
     * it can deal with the mapping of the path. The final symbol
     * path is left (null-terminated) in  id .
     */
    cp = buffer;

    while (1) {
	/*
	 * HACK
	 */
	if (ustrcmp(cp, "kdata") == 0) {
	    strcpy(cp, "geos::dgroup");
	}
	
	if (**exprPtr == ':' && (*exprPtr)[1] == ':') {
	    cp += strlen(cp);
	    *cp++ = *(*exprPtr)++;
	    *cp++ = *(*exprPtr)++;
	} else if ((ustrcmp(cp, "struct") == 0) || (ustrcmp(cp, "union") == 0))
	{
	    const char *stOrUnion;

	    if (cp[0] == 's' || cp[0] == 'S') {
		stOrUnion = "struct";
	    } else {
		stOrUnion = "union";
	    }
	    strcpy(cp, stOrUnion);
	    
	    while (**exprPtr == ' ' || **exprPtr == '\t') {
		(*exprPtr)++;
	    }

	    cp += strlen(cp);
	    *cp++ = ' ';
	} else {
	    break;
	}
	yyid(exprPtr, cp);
    }
}

/***********************************************************************
 *				ustrcmp
 ***********************************************************************
 * SYNOPSIS:	  Perform an unsigned (case-insensitive) string comparison
 * CALLED BY:	  MapFilename
 * RETURN:	  <0 if s1 is less than s2, 0 if they're equal and >0 if
 *		  s1 is greater than s2. Upper- and lower-case letters are
 *	    	  equivalent in the comparison.
 *		  
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *	Subtract each character in s1 from its corresponding character
 *	in s2 in turn. Save that difference in case the strings are unequal.
 *
 *	If the characters are different, and the one that might be upper case
 *	actually is a letter, map that upper-case letter to lower case and
 *	subtract again (if the difference is < 0, *s1 must come before *s2 in
 *	the character set and vice versa if the difference is > 0).
 *
 *	If the characters are still different, return the original difference.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/27/88		Initial Revision
 *
 ***********************************************************************/
int
ustrcmp(char *s1, char *s2)
{
    int	    	  diff;
    
    while (*s1 && *s2) {
	diff = *s1 - *s2;
	if (diff < 0) {
	    if (!isalpha(*s1) || (tolower(*s1) - *s2)) {
		return(diff);
	    }
	} else if (diff > 0) {
	    if (!isalpha(*s2) || (*s1 - tolower(*s2))) {
		return(diff);
	    }
	}
	s1++, s2++;
    }
    return(!(*s1 == *s2));
}


/***********************************************************************
 *				ExprLookInScopeChain
 ***********************************************************************
 * SYNOPSIS:	    Look for a symbol in all the scopes from a given scope
 *	    	    up to its module.
 * CALLED BY:	    yylex
 * RETURN:	    The symbol, if found.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/10/90		Initial Revision
 *
 ***********************************************************************/
static Sym
ExprLookInScopeChain(const char  *name,
		      Sym   scope)
{
    Sym sym = NullSym;
    
    while (!(Sym_Class(scope) & SYM_MODULE)) {
	sym = Sym_LookupInScope(name, SYM_ANY, scope);
	if (!Sym_IsNull(sym)) {
	    break;
	}
	scope = Sym_Scope(scope, TRUE);
    }

    return (sym);
}

/***********************************************************************
 *				Expr_FindSym
 ***********************************************************************
 * SYNOPSIS:	  Locate a symbol in a variety of scopes appropriate
 *		  to the current context.
 * CALLED BY:	  yylex, CmdWhatIs
 * RETURN:	  Sym found
 * SIDE EFFECTS:  none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/90	Initial Revision
 *
 ***********************************************************************/
Sym
Expr_FindSym(Patient	patient,
	     const char *id)
{
    Sym	    sym = NullSym;	/* Assume not symbol */
	    
    /*
     * If the patient has a current frame, we need to handle local
     * symbols by looking them up specially.
     */
    if ((patient->frame != NullFrame) && !Sym_IsNull(patient->frame->scope)) {
	/*
	 * Look in all the scopes individually from the current scope
	 * up to, but not including, the containing module. If we
	 * call Sym_Lookup, it will go searching from here to hell
	 * and back when we really need to look in all the local
	 * scopes one by one. If we reach the module scope without
	 * having found the thing, then we can look in the current
	 * patient's global scope (note that the current patient could
	 * well be different from the current patient's current frame's
	 * patient [got that?], so that's another reason not to just
	 * do a lookup in the current scope).
	 */
	sym = ExprLookInScopeChain(id, patient->frame->scope);
    }
    
    /*
     * If the current scope for the patient has been set with the
     * "scope" command, look in that scope chain as well.
     */
    if (Sym_IsNull(sym) && !Sym_IsNull(patient->scope)) {
	sym = ExprLookInScopeChain(id, patient->scope);
    }
    
    if (Sym_IsNull(sym)) {
	sym = Sym_Lookup(id, SYM_ANY, patient->global);
    }

    return(sym);
}
/*
 * Include hash function for reserved words
 */
#include    "tokens.h"


/***********************************************************************
 *				ExprScan
 ***********************************************************************
 * SYNOPSIS:	    Lexical analyzer for address parser
 * CALLED BY:	    yyparse
 * RETURN:	    token # plus data in yylval
 * SIDE EFFECTS:    curExpr is advanced.
 *
 * STRATEGY:	    Same as always.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 9/88	Initial Revision
 *
 ***********************************************************************/
int
ExprScan(char	    **exprPtr,
	 YYSTYPE    *yylval,
	 ExprState *state)
{
    char	c;  	    /* Current character */
    char	id[256];    /* Space for identifier */

    do {
	c = *(*exprPtr)++;
    } while ((c == ' ') || (c == '\t'));

    switch (c) {
	case '\0':
	    /*
	     * Make sure we continue to return 0 if called again...
	     */
	    (*exprPtr)--;
	    return(0);
	case '-':
	    if (**exprPtr == '>') {
		/*
		 * Similar to '.', but return PTR_OP instead.
		 */
		*exprPtr += 1;
		yyfullid(exprPtr, id);
		yylval->token.what = TOKEN_STRING;
		yylval->token.value.str = (char *)malloc(strlen(id)+1);
		strcpy(yylval->token.value.str, id);
		yylval->token.flags = 0;
		return(PTR_OP);
	    } else {
		return(c);
	    }
	case '.':
	    if (**exprPtr == '.') {
		(*exprPtr)++;
		return RANGE;
	    }
	    
	    yyfullid(exprPtr, id);
	    yylval->token.what = TOKEN_STRING;
	    yylval->token.value.str = (char *)malloc(strlen(id)+1);
	    strcpy(yylval->token.value.str, id);
	    yylval->token.flags = 0;
	    /*FALLTHRU*/
	    /*
	     * Various Operators...
	     */
	case '/':
	case '*':
	case '(':
	case ')':
	case '+':
	case ':':
	case '#':
	case '[':
	case ']':
	case '{':
	case '}':
	case '~':
	case '%':
	    /*
	     * Operator -- return the character itself
	     */
	    return(c);
	case '|':
	    if (**exprPtr == '|') {
		*exprPtr += 1;
		return(OR_OP);
	    } else {
		return(c);
	    }
	case '&':
	    if (**exprPtr == '&') {
		*exprPtr += 1;
		return(AND_OP);
	    } else {
		return(c);
	    }
	case '=':
	    if (**exprPtr == '=') {
		*exprPtr += 1;
		return(EQ_OP);
	    } else {
		return(c);
	    }
	case '!':
	    if (**exprPtr == '=') {
		*exprPtr += 1;
		return(NE_OP);
	    } else {
		return(c);
	    }
	case '<':
	    if (**exprPtr == '<') {
		*exprPtr += 1;
		return(LEFT_OP);
	    } else if (**exprPtr == '=') {
		*exprPtr += 1;
		return(LE_OP);
	    } else {
		return(c);
	    }
	case '>':
	    if (**exprPtr == '>') {
		*exprPtr += 1;
		return(RIGHT_OP);
	    } else if (**exprPtr == '=') {
		*exprPtr += 1;
		return(GE_OP);
	    } else {
		return(c);
	    }
	case '^':
	    if (**exprPtr == 'h') {
		(*exprPtr)++;
		return (HANDLE);
	    } else if (**exprPtr == 'l') {
		(*exprPtr)++;
		return (LHANDLE);
	    } else if (**exprPtr == 'v') {
		(*exprPtr)++;
		return (VHANDLE);
	    } else {
		return ('^');
	    }
	case '@':
	{
	    /*
	     * History element -- fetch its value from the Value module and
	     * return VHIST.
	     *
	     * Register -- figure out which one and return its value in the
	     * current frame as a CONSTANT.
	     */
	    Reg_Data	*rdp;
	    
	    yyid(exprPtr, id);
	    
	    if (*id == '\0') {
		int	number = 0;

		if (**exprPtr == '-') {
		    /*
		     * If next char is a -, then it must be a relative
		     * history invocation, so scan off the number and use
		     * that...
		     */
		    number = cvtnum(*exprPtr, exprPtr);
		}

		/*
		 * Nothing identifier-like following the @ => the most-recent
		 * entry in the value history.
		 */
		if (!Value_HistoryFetch(number,
					&yylval->token.value.addr.handle,
					&yylval->token.value.addr.offset,
					&yylval->token.type))
		{
		    xyyerror(state, "Value history not that big");
		    return(0);
		} else {
		    yylval->token.what = TOKEN_ADDRESS;
		    yylval->token.flags = 0;
		    return(VHIST);
		}
	    } else if (isdigit(*id)) {
	    	/*
		 * It begins with a digit, so it must be an entry
		 * in the value history -- find it and tell the parser
		 * about it.
		 */
	    	if (!Value_HistoryFetch(atoi(id),
					&yylval->token.value.addr.handle,
					&yylval->token.value.addr.offset,
					&yylval->token.type))
		{
		    xyyerror(state, "Element %s not in value history", id);
		    return(0);
		} else {
		    yylval->token.what = TOKEN_ADDRESS;
		    yylval->token.flags = 0;
		    return(VHIST);
		}
	    }
	    
		
	    rdp = (Reg_Data *)Private_GetData(id);
	    
	    if (rdp == (Reg_Data *)NULL) {
		xyyerror(state, "Unknown register %s", id);
		return(0);
	    } else if (state->frame == NullFrame) {
	    	xyyerror(state, "%s has no current frame",
			 state->patient->name);
		return(0);
	    } else {
		regval	val;

		(*MD_GetFrameRegister)(state->frame,
				       rdp->type,
				       rdp->number,
				       &val);
		yylval->token.what = TOKEN_LITERAL;
		yylval->token.value.literal = val;
		yylval->token.type = type_Word;
		yylval->token.flags = 0;
		return(CONSTANT);
	    }
	}
	case '0': case '1': case '2': case '3': case '4':
	case '5': case '6': case '7': case '8': case '9':
	{
	    char    *cp;
	    double  val;
	    extern double strtod();

	    /*
	     * Convert the thing both as an integer constant and as a
	     * floating-point one. Whichever uses up more characters is
	     * the one we use...If the last character parsed by strtod is a
	     * decimal point, however, we treat the thing as decimal instead,
	     * to allow things like kdata:5520.HM_size, of which we're quite
	     * fond...
	     */
	    cp = (*exprPtr)-1;
	    yylval->token.value.literal = cvtnum((*exprPtr)-1, exprPtr);
	    val = strtod(cp, &cp);

	    if (cp > *exprPtr && cp[-1] != '.') {
		*exprPtr = cp;
		yylval->token.value.ptr = ExprMalloc(state, sizeof(double));
		*(double *)yylval->token.value.ptr = val;
		yylval->token.what = TOKEN_POINTER;
		yylval->token.type = type_Double;
	    } else {
		if ((long)yylval->token.value.literal > 32767
		    || (long)yylval->token.value.literal < -32768) {
		    yylval->token.type = type_Long;
		} else {
		    yylval->token.type = type_Int;
		}
		yylval->token.what = TOKEN_LITERAL;
	    }
	    yylval->token.flags = 0;
	    return(CONSTANT);
	}
/*
 * IDENTIFIERS
 */
	default:
	{
	    Sym  	sym;
	    char	*idStart;
	    Reg_Data	*rdp;
	    int	    	class;
	    const struct _ScanToken *st;
	    
	    
	    /*
	     * Back up the expression pointer so we get the first character
	     * (useful thing, that). Save the start in idStart for possible
	     * numeric conversion.
	     */
	    idStart = --*exprPtr;
	    
	    /*
	     * Scan the identifier off into the  id  buffer.
	     */
	    yyfullid(exprPtr, id);

	    /*
	     * If didn't scan off anything, generate an error and return
	     * end-of-input.
	     */
	    if (idStart == *exprPtr) {
		xyyerror(state, "unhandled character '%c'", *idStart);
		return(0);
	    }
	    
	    /*
	     * Check against well-known types & keywords first
	     */
	    st = in_word_set(id, strlen(id));
	    if (st != NULL) {
		return(st->token);
	    }

	    /*
	     * See if it's a register
	     */
	    rdp = (Reg_Data *)Private_GetData(id);
	    if (rdp != NULL) {
		regval	val;

		(*MD_GetFrameRegister)(state->frame,
				       rdp->type,
				       rdp->number,
				       &val);
		yylval->token.what = TOKEN_LITERAL;
		yylval->token.value.literal = val;
		yylval->token.type = type_Long;
		yylval->token.flags = 0;
		return(CONSTANT);
	    }
	    

	    sym = Expr_FindSym(state->patient, id);

	    if (Sym_IsNull(sym)) {
		/*
		 * Hmmm. Not a valid symbol. Try and convert it as a hex
		 * number. For the conversion to be valid, the number must
		 * extend all the way to the current position in the
		 * expression.
		 */
		int	val;
		char	*vEnd;
		    
		val = cvtnum(idStart, &vEnd);
		if (vEnd == *exprPtr) {
		    yylval->token.what = TOKEN_LITERAL;
		    yylval->token.value.literal = val;
		    if ((long)yylval->token.value.literal > 32767
			|| (long)yylval->token.value.literal < -32768) {
			yylval->token.type = type_Long;
		    } else {
			yylval->token.type = type_Int;
		    }
		    yylval->token.flags = 0;
		    return(CONSTANT);
		} else {
		    GeosAddr  *ga;

		    /* lets see if we have a class::msg thingee */
		    if ((ga=Sym_GetCachedMethod())->handle) {
			yylval->token.what = TOKEN_ADDRESS;
			yylval->token.value.addr.handle = ga->handle;
			yylval->token.value.addr.offset = ga->offset;
			yylval->token.type = type_VoidProc;
			yylval->token.flags = 0;
			return(ADDRESS);
		    } else {
			xyyerror(state, "%s undefined", id);
			return(0);
		    }
		}
	    }
	    
	    /*
	     * Figure out what token to return.
	     */
	    class = Sym_Class(sym);
	    if (class & SYM_TYPE) {
		yylval->type = TypeCast(sym);
		return(TYPE);
	    } else if (class & SYM_ENUM) {
		int val;
		
		Sym_GetEnumData(sym, &val, &yylval->token.type);
		yylval->token.value.literal = val;
		yylval->token.what = TOKEN_LITERAL;
		yylval->token.flags = 0;
		return(CONSTANT);
	    } else if (class & SYM_ABS) {
		yylval->token.value.literal = Sym_GetAbsData(sym);
		yylval->token.what = TOKEN_LITERAL;
		yylval->token.type = type_Int;
		yylval->token.flags = 0;
		return(CONSTANT);
	    } else {
		yylval->sym = sym;
		return(SYM);
	    }
	}
    }
}


/***********************************************************************
 *				Expr_Eval
 ***********************************************************************
 * SYNOPSIS:	    Front-end to xyyparse function.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    FALSE if error (invalid expression, or wantAddr
 *	    	    non-zero but expr can't evaluate to an address)
 *	    	    TRUE if success (*addrPtr and *typePtr filled in)
 * SIDE EFFECTS:    If addrPtr->handle is returned as ValueHandle, the
 *	    	    data pointed to by addrPtr->offset must be freed
 *	    	    by the caller.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/25/92		Initial Revision
 *
 ***********************************************************************/
Boolean
Expr_Eval(const char	*expr,
	  Frame   	*frame,
	  GeosAddr  	*addrPtr,
	  Type	    	*typePtr,
	  Boolean   	wantAddr)
{
    Buffer	realExpr;
    const char 	*cp;
    Boolean 	result;
    ExprState	state;
    regval      curXIP ;

    /*
     * 10/17/95: force curXIPPage to be that of the current frame -- ardeb
     */
    if (frame != NullFrame) {
	MD_GetFrameRegister(frame, REG_OTHER, (int)"xipPage",
			    &curXIP);
        curXIPPage = curXIP ;
    } else if (curPatient->frame != NullFrame) {
	MD_GetFrameRegister(curPatient->frame, REG_OTHER, (int)"xipPage",
			    &curXIP);
        curXIPPage = curXIP ;
    }


    realExpr = 0;


#if YYDEBUG != 0
    yydebug = exprDebug;
#endif /* YYDEBUG */

    /*
     * See if there are any Tcl variables or nested commands we have to deal
     * with here.
     */
    for (cp = expr; *cp != '\0'; cp++) {
	if (*cp == '$' || *cp == '[') {
	    realExpr = Buf_Init(strlen(expr)+1);
	    break;
	}
    }

    if (realExpr != 0) {
	/*
	 * Pre-process the buffer, looking for TCL variables or nested commands.
	 */
	while (*expr != '\0') {
	    if (*expr == '$') {
		/*
		 * Parse the variable specification and copy the result into
		 * the buffer.
		 */
		const char  *next;
		const char  *var = Tcl_ParseVar(interp, expr, &next);
		
		Buf_AddBytes(realExpr, strlen(var), (Byte *)var);

		expr = next;
	    } else if (*expr == '[') {
		/*
		 * Evaluate the nested command.
		 */
		const char    *next;
		
		if (Tcl_Eval(interp, expr+1, ']', &next) == TCL_OK) {
		    /*
		     * Happiness -- copy the result into the expression.
		     */
		    Buf_AddBytes(realExpr, strlen(interp->result),
				 (Byte *)interp->result);
		} else {
		    /*
		     * Assume it's the start of an array index instead and
		     * just copy the beast in. Clear out the error message
		     * in interp->result first, though.
		     */
		    Tcl_Return(interp, NULL, TCL_STATIC);
		    Buf_AddByte(realExpr, (Byte)'[');
		    next = expr;
		}
		expr = next+1;
	    } else {
		Buf_AddByte(realExpr, *(Byte *)expr);
		expr += 1;
	    }
	}
	state.startExpr = (char *)Buf_GetAll(realExpr, (int *)NULL);
    } else {
	state.startExpr = expr;
    }
    
    if (frame != NullFrame) {
	state.frame = frame;
	state.patient = frame->execPatient;
    } else {
	state.frame = curPatient->frame;
	state.patient = curPatient;
    }

    state.noSideEffects = FALSE;;
    state.sideStackTop = state.sideStack;
    state.doneError = FALSE;
    state.data = Lst_Init(FALSE);
    state.freeStacks = FALSE;

    result = (!xyyparse(state.startExpr, &state));

    if (result)
    {		  
	if (addrPtr != (GeosAddr *)NULL) {
	    /*
	     * Deal with wantAddr when end result is a fetched pointer by
	     * performing extra indirection to convert the beast to a
	     * TOKEN_ADDRESS.
	     */
	    if (wantAddr &&
		(state.result.what == TOKEN_POINTER) &&
		(Type_Class(state.result.type) == TYPE_POINTER))
	    {
		ExprIndirect(&state, &state.result, &state.result);
	    }
	    
	    switch(state.result.what) {
		case TOKEN_LITERAL:
		    if (wantAddr) {
			result = FALSE;
		    } else {
			addrPtr->handle = ValueHandle;
			addrPtr->offset =
			    (Address)Var_Cast((genptr)&state.result.value.literal,
					      type_Long,
					      state.result.type);
		    }
		    break;
		case TOKEN_POINTER:
		    /*
		     * If the fetched value is a pointer, convert it to a
		     * 32-bit far pointer return value. Else just return
		     * whatever we fetched.
		     */
		    if (wantAddr) {
			Tcl_Return(interp, "expression must be an address",
				   TCL_STATIC);
			result = FALSE;
		    } else {
			addrPtr->handle = ValueHandle;
			if (Type_Class(state.result.type) == TYPE_POINTER) {
			    GeosAddr	*gap = state.result.value.ptr;
			    Type    	baseType;
			    
			    /* Don't use ExprMalloc here, as we'll be returning
			     * the allocated memory. */
			    addrPtr->offset =
				(Address)malloc_tagged(sizeof(dword), TAG_EXPR);

			    if (gap->handle == NullHandle) {
				*(dword *)addrPtr->offset = (dword)gap->offset;
			    } else {
				*(dword *)addrPtr->offset =
				    (Handle_Segment(gap->handle) << 16) |
					(word)gap->offset;
			    }
			    Type_GetPointerData(state.result.type, (int *)NULL,
						&baseType);
			    state.result.type = Type_CreatePointer(baseType,
								   TYPE_PTR_FAR);
			} else {
			    Lst_Remove(state.data,
				       Lst_Member(state.data,
						  (LstClientData)state.result.value.ptr));
			    addrPtr->offset = (Address)state.result.value.ptr;
			}
		    }
		    break;
		case TOKEN_STRING:
		    if (wantAddr) {
			Tcl_Return(interp, "expression must be an address",
				   TCL_STATIC);
			result = FALSE;
		    } else {
			/*
			 * Remove the string from the list of data to be freed.
			 */
			Lst_Remove(state.data,
				   Lst_Member(state.data,
					      (LstClientData)state.result.value.str));
			/*
			 * Set the string as the result.
			 */
			addrPtr->handle = ValueHandle;
			addrPtr->offset = (Address)state.result.value.str;
			/*
			 * Adjust the type we're going to return to match the
			 * size of the string.
			 */
			state.result.type =
			    Type_CreateArray(0,
					     strlen(state.result.value.str)-1,
					     type_Int,
					     type_Char);
		    }
		    break;
		case TOKEN_ADDRESS:
		    *addrPtr = state.result.value.addr;
		    break;
	    }
	}
	
	if (typePtr != NULL) {
	    *typePtr = state.result.type;
	}
    }

    /*
     * If we had to process the expression, nuke the resulting string.
     */
    if (realExpr != 0) {
	Buf_Destroy(realExpr, TRUE);
    }

    
    Lst_Destroy(state.data, (void (*)())free);

    return(result);
}


/***********************************************************************
 *				ExprCast
 ***********************************************************************
 * SYNOPSIS:	    Cast an expression to a new type.
 * CALLED BY:	    xyyparse
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/22/92		Initial Revision
 *
 ***********************************************************************/
static Boolean
ExprCast(ExprState *state,
	 ExprToken  *tokenPtr,
	 Type	    type,
	 ExprToken  *resultPtr,
	 Boolean    oldStyleCast /* used for tcl and asm casting */)
{
    if (tokenPtr->what == TOKEN_ADDRESS) {
	/*
	 * In theory, we should check for a compatible cast. In actuality,
	 * it's more useful to not do any checking in this case, as it allows
	 * the manufacturing of arrays, etc.
	 */
	*resultPtr = *tokenPtr;
	resultPtr->type = type;
    } else {
	ExprFetch(state, tokenPtr);
    
	*resultPtr = *tokenPtr;
    
	if (!ExprTypeCheck(tokenPtr->type, type, TRUE)) {
	    xyyerror(state, "casting between incompatible types");
	    return(FALSE);
	}
	if (resultPtr->what == TOKEN_POINTER) {
	    /*
	     * Special-case casting of one pointer-type to another, as
	     * Var_Cast doesn't know about the special format we use for
	     * pointers... 
	     */
	    if (Type_Class(tokenPtr->type) != TYPE_POINTER) {
		resultPtr->value.ptr =
		    (Opaque)Var_Cast(resultPtr->value.ptr,
				     tokenPtr->type, type);
		(void)Lst_AtEnd(state->data, (LstClientData)resultPtr->value.ptr);
	    } else {
		/*
		 * Make sure the beast is a far pointer, as that's what all
		 * fetched pointers are converted to...
		 */
		Type	baseType;
		int 	ptrType;

		if (Type_Class(type) != TYPE_POINTER) {
		    Type_GetPointerData(tokenPtr->type, &ptrType, &baseType);
		    /*
		     * Regardless of the kind of cast we're performing, if
		     * we're  casting to a pointer, we need only change
		     * the type stored to describe the already-fetched
		     * data, as all pointers are "fetched" as a GeosAddr
		     */
		    if (oldStyleCast) {
			/*
			 * This means we got a pointer but really want
			 * Swat to know that the data pointed to by
			 * the pointer is of the indicated type, so we
			 * create a new pointer type whose base is the
			 * casted-to type
			 */
			type = Type_CreatePointer(type, ptrType);
		    } else {
			/* deal with C type casts... */
			assert(0);
		    }
		}
	    }
	} else if (resultPtr->what == TOKEN_LITERAL) {
	    int	    size = Type_Sizeof(tokenPtr->type);
	    genptr  p;

	    if (swap) {
		p = (genptr)&tokenPtr->value.literal + (sizeof(long)-size);
	    } else {
		p = (genptr)&tokenPtr->value.literal;
	    }

	    resultPtr->value.ptr = (void *)Var_Cast(p, tokenPtr->type, type);
	    (void)Lst_AtEnd(state->data, (LstClientData)resultPtr->value.ptr);
	    resultPtr->what = TOKEN_POINTER;
	}
	resultPtr->type = type;
    }
    return(TRUE);
}

/***********************************************************************
 *				ExprIndirectVMPart1
 ***********************************************************************
 * SYNOPSIS:	Begin the process of indirecting through a file handle
 *		and VM block handle.
 * CALLED BY:	(INTERNAL) xyyparse, ExprFetch
 * RETURN:	TRUE if passed handle is valid
 * SIDE EFFECTS:if passed handle not a valid VM handle, then xyyerror is
 *		called
 *	    	else *result is filled in (with an offset of 0)
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 9/94		Initial Revision
 *
 ***********************************************************************/
static Boolean
ExprIndirectVMPart1(ExprState	*state,
		    long    	hid,
		    GeosAddr	*result)
{
    Handle	handle;
    
    handle = Handle_Lookup((unsigned short)hid);
		    
    if (handle == NullHandle) {
	xyyerror(state, "%xh not a valid handle ID", hid);
	return(FALSE);
    } else if (Handle_IsFile(Handle_State(handle))) {
	/*
	 * If it's a file handle, we need to get the associated VM handle,
	 * whose ID is stored in the HF_otherInfo field at offset 12.
	 */
	word	w;

	Var_FetchInt(2, kernel->resources[1].handle, (Address)(hid+12),
		     (genptr)&w);
	handle = Handle_Lookup(w);

	if (handle == NullHandle) {
	    xyyerror(state,
		     "%04xh: file handle has no associated VM handle",
		     hid);
	    return(FALSE);
	}
    } else if (!Handle_IsVM(Handle_State(handle))) {
	xyyerror(state, "%04xh is neither a VM nor a file handle",
		 hid);
	return(FALSE);
    }
    result->handle = handle;
    result->offset = 0;
    return(TRUE);
}


/***********************************************************************
 *				ExprIndirectVMPart2
 ***********************************************************************
 * SYNOPSIS:	Perform the second part of indirecting through a file
 *	    	handle + a vm block handle
 * CALLED BY:	(INTERNAL) xyyparse, ExprFetch
 * RETURN:	TRUE if successful
 * SIDE EFFECTS:if return FALSE, xyyerror has been called
 *	    	*result filled in if TRUE
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 9/94		Initial Revision
 *
 ***********************************************************************/
static Boolean
ExprIndirectVMPart2(ExprState *state,
		    Handle handleVM,
		    word block,
		    GeosAddr *result)
{
    word    w;
    Handle  handle;

    /*
     * Handle ID of header block is stored at offset 4 (release 2+) or offset
     * 2 (release 1.X) in the HandleVM. Fetch it now.
     */
    Var_FetchInt(2, kernel->resources[1].handle,
		 (Address)(Handle_ID(handleVM)+4), (genptr)&w);
			    
    /*
     * Lookup header handle
     */
    if (w == 0) {
	xyyerror(state, "VM header of %04xh not in memory",
		 Handle_ID(handleVM));
	return(FALSE);
    }
    
    handle = Handle_Lookup(w);
			    
    if (handle == NullHandle) {
	xyyerror(state, "VM header handle %04xh not a valid", w);
	return(FALSE);
    } else {
	Var_FetchInt(2, handle, (Address)block, (genptr)&w);
				
	if (w == 0) {
	    xyyerror(state, "VM block %04xh not in memory", block);
	    return(FALSE);
	} else {
	    result->handle = Handle_Lookup(w);
	    result->offset = (Address)0;
	    return(TRUE);
	}
    }
}

/***********************************************************************
 *				ExprIndirect
 ***********************************************************************
 * SYNOPSIS:	  Perform indirection through an expression
 * CALLED BY:	  '*' and '^' rules.
 * RETURN:	  TRUE if the indirection was successful
 * SIDE EFFECTS:  *dest is set to the result of the indirection
 *
 * STRATEGY:
 *	    copy flags when dealing with TOKEN_POINTER/TYPE_POINTER, so
 *	    ETF_HANDLE_FROM_INDIR works.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/29/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
ExprIndirect(ExprState	*state,
	     ExprToken	*tokenPtr,
	     ExprToken	*resultPtr)
{
    if (tokenPtr->what == TOKEN_POINTER) {
	if (Type_Class(tokenPtr->type) != TYPE_POINTER) {
	    xyyerror(state, "illegal indirection");
	    return(FALSE);
	}
	resultPtr->what = TOKEN_ADDRESS;
	resultPtr->value.addr = *(GeosAddr *)tokenPtr->value.ptr;
	resultPtr->flags = tokenPtr->flags;
	Type_GetPointerData(tokenPtr->type, (int *)NULL, &resultPtr->type);
    } else if (tokenPtr->what != TOKEN_ADDRESS) {
	xyyerror(state, "illegal indirection");
	return(FALSE);
    } else {
	resultPtr->flags = ETF_HANDLE_FROM_INDIR;
	resultPtr->what = TOKEN_ADDRESS;
	/*
	 * See if the expression's type is simple enough (read: integer) that we
	 * can use the result of the indirection.
	 */
	if (Type_IsNull(tokenPtr->type) ||
	    (Type_Class(tokenPtr->type) == TYPE_INT))
	{
	    /*
	     * Expression is simple enough that we can indirect
	     * through it. Wheee.
	     */
	    int	size;
	    
	    size = !Type_IsNull(tokenPtr->type) ?
		Type_Sizeof(tokenPtr->type) : sizeof(word);
	    resultPtr->value.addr.handle = tokenPtr->value.addr.handle;
	    resultPtr->type = NullType;
	    
	    if (size == sizeof(byte)) {
		byte	b;
		
		Ibm_ReadBytes(1, tokenPtr->value.addr.handle,
			      tokenPtr->value.addr.offset, (genptr)&b);
		resultPtr->value.addr.offset = (Address)b;
	    } else if (size == sizeof(word)) {
		word	w;
		
		Var_FetchInt(2, tokenPtr->value.addr.handle,
			     tokenPtr->value.addr.offset, (genptr)&w);
		resultPtr->value.addr.offset = (Address)w;
	    } else if (size == sizeof(dword)) {
		dword	d;
		Address	seg;
		
		Var_FetchInt(4, tokenPtr->value.addr.handle,
			     tokenPtr->value.addr.offset, (genptr)&d);
		/*
		 * Treat the value as a FAR pointer, using the
		 * low 16 bits as the offset and the high 16 bits
		 * as the segment, resolving the segment to
		 * a handle if possible.
		 */
		resultPtr->value.addr.offset = (Address)(d & 0xffff);
		seg = (Address)((d >> 12) & 0xffff0);
		resultPtr->value.addr.handle = Handle_Find(seg);
		
		/*
		 * If couldn't resolve to a handle, make the thing
		 * absolute.
		 */
		if (resultPtr->value.addr.handle == NullHandle) {
		    resultPtr->value.addr.offset += (dword)seg;
		} else if (Handle_Address(resultPtr->value.addr.handle)!=seg) {
		    /*
		     * Segment of dword doesn't match the segment
		     * of the handle -- adjust the offset
		     * accordingly.
		     */
		    resultPtr->value.addr.offset +=
			seg - Handle_Address(resultPtr->value.addr.handle);
		    resultPtr->flags = 0;
		    resultPtr->value.addr.handle = NullHandle;
		}
	    } else {
		xyyerror(state, "weird-sized word (%d bytes?)", size);
		return(FALSE);
	    }
	} else if (Type_Class(tokenPtr->type) == TYPE_POINTER) {
	    /*
	     * The expression is a pointer, so we know we can indirect through
	     * it. The result is the pointer and the type at which it points.
	     */
	    ExprFetch(state, tokenPtr);
	    return(ExprIndirect(state, tokenPtr, resultPtr));
	} else {
	    yyerror("illegal indirection (must be byte/word/dword or pointer)");
	    return(FALSE);
	}
    }
    return(TRUE);
}
/*-
 *-----------------------------------------------------------------------
 * ExprTypeCheck --
 *	See if the two types are compatible.
 *
 * Results:
 *	TRUE if they are, FALSE if they are not.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
ExprTypeCheck(Type	type1,
	      Type	type2,
	      Boolean	coerce)	    /* TRUE if implicit conversion may be used */
{
    if ((Type_Class(type1) == TYPE_VOID) || (Type_Class(type2) == TYPE_VOID)) {
	return(TRUE);
    }
    
    switch (Type_Class(type1)) {
	case TYPE_INT:
	    switch(Type_Class(type2)) {
		case TYPE_RANGE:
		    Type_GetRangeData(type2, (int *)NULL, (int *)NULL, &type2);
		    return(ExprTypeCheck(type1, type2, coerce));
		case TYPE_POINTER:
		case TYPE_FLOAT:
		case TYPE_ENUM:
		    if (!coerce) {
			break;
		    }
		case TYPE_INT:
		case TYPE_CHAR:
		    return(TRUE);
		default:
		    break;
	    }
	    break;
	case TYPE_CHAR:
	    switch(Type_Class(type2)) {
		case TYPE_RANGE:
		    Type_GetRangeData(type2, (int *)NULL, (int *)NULL, &type2);
		    return(ExprTypeCheck(type1, type2, coerce));
		case TYPE_ENUM:
		    if (!coerce) {
			break;
		    }
		case TYPE_INT:
		case TYPE_CHAR:
		    return(TRUE);
		default:
		    break;
	    }
	    break;
	case TYPE_FLOAT:
	    switch(Type_Class(type2)) {
		case TYPE_ENUM:
		case TYPE_INT:
		case TYPE_CHAR:
		    if (!coerce) {
			break;
		    }
		case TYPE_FLOAT:
		    return(TRUE);
		default:
		    break;
	    }
	    break;
	case TYPE_ENUM:
	    switch(Type_Class(type2)) {
		case TYPE_INT:
		case TYPE_CHAR:
		    if (coerce) {
			return(TRUE);
		    }
		    break;
		case TYPE_ENUM:
		    return(Type_Equal(type1, type2));
		default:
		    break;
	    }
	    break;
	case TYPE_STRUCT:
	case TYPE_UNION:
	    return(Type_Equal(type1, type2));
	case TYPE_RANGE:
	    Type_GetRangeData(type1, (int *)NULL, (int *)NULL, &type1);
	    return(ExprTypeCheck(type1, type2, coerce));
	case TYPE_ARRAY:
	    switch(Type_Class(type2)) {
		case TYPE_ARRAY:
		    return(Type_Equal(type1, type2));
		case TYPE_POINTER:
		{
		    Type    baseType;
		    
		    Type_GetArrayData(type1, (int *)NULL, (int *)NULL,
				      (Type *)NULL, &type1);
		    Type_GetPointerData(type2, (int *)NULL, &baseType);

		    return(Type_Equal(type1, baseType));
		}
		default:
		    break;
	    }
	    break;
	case TYPE_POINTER:
	    switch(Type_Class(type2)) {
		case TYPE_ARRAY:
		{
		    Type    baseType;
		    
		    Type_GetArrayData(type2, (int *)NULL, (int *)NULL,
				      (Type *)NULL, &type2);
		    Type_GetPointerData(type1, (int *)NULL, &baseType);
		    
		    return(Type_Equal(baseType, type2));
		}
		case TYPE_POINTER:
		    if (coerce) {
			return(TRUE);
		    } else {
			Type	btype1, btype2;
			int 	ptype1, ptype2;

			Type_GetPointerData(type1, &ptype1, &btype1);
			Type_GetPointerData(type2, &ptype2, &btype2);
			
			return((ptype1 == ptype2) &&
			       Type_Equal(btype1, btype2));
		    }
		case TYPE_INT:
		case TYPE_CHAR:
		    if (coerce) {
			return(TRUE);
		    }
		default:
		    break;
	    }
	    break;
	case TYPE_VOID:
	    return (Type_Class(type2) == TYPE_VOID);
	case TYPE_FUNCTION:
	case TYPE_EXTERNAL:
	    return(Type_Equal(type1, type2));
    }
    return(FALSE);
}

/*-
 *-----------------------------------------------------------------------
 * ExprFetch --
 *	Fetch the value of a token, so long as state->noSideEffects is FALSE.
 *	In addition, if the token is of type TYPE_FUNCTION, it is converted
 *	to a literal pointer to a function returning the function's return
 *	type. If the token is of type TYPE_ARRAY, it is converted to a
 *	literal pointer to the array's element type, as opposed to having
 *	its entire data fetched..
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The value, what and (occasionally) type fields of the passed
 *	token are overwritten.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
ExprFetch(ExprState	*state,
	  ExprToken	*tokenPtr)
{
    /*
     * Fetch that beastie
     */
    if (!state->noSideEffects) {
	if (tokenPtr->what == TOKEN_ADDRESS) {
	    switch(Type_Class(tokenPtr->type)) {
		case TYPE_NULL:
		    /*
		     * Do nothing -- we want to keep the address unmolested.
		     */
		case TYPE_ARRAY:
		    /*
		     * Do nothing? Operators will deal with derefing to the
		     * base type when appropriate...
		     *
		     * May need to coerce to fetched pointer...
		     */
		    break;
		case TYPE_FUNCTION:
		    /*
		     * Do nothing for functions...for now.
		     */
		    break;
		case TYPE_POINTER:
		{
		    /*
		     * Pointer variables get mapped into a GeosAddr structure
		     * always.
		     */
		    Type    	baseType;
		    int	    	ptrType;
		    GeosAddr	*gap;

		    gap = (GeosAddr *)ExprMalloc(state, sizeof(GeosAddr));
		    
		    Type_GetPointerData(tokenPtr->type, &ptrType, &baseType);
		    switch(ptrType) {
			case TYPE_PTR_NEAR:
			{
			    /*
			     * Fetch offset. handle stays the same. type is
			     * baseType.
			     */
			    word    val;

			    (void)Var_FetchInt(2,
					       tokenPtr->value.addr.handle,
					       tokenPtr->value.addr.offset,
					       (genptr)&val);
			    gap->offset = (Address)val;
			    gap->handle = tokenPtr->value.addr.handle;
			    tokenPtr->flags = ETF_HANDLE_FROM_INDIR;
			    break;
			}
			case TYPE_PTR_FAR:
			{
			    /*
			     * Fetch offset & segment. look up segment's handle.
			     * form absolute address if not found.
			     */
			    dword   val;

			    (void)Var_FetchInt(4,
					       tokenPtr->value.addr.handle,
					       tokenPtr->value.addr.offset,
					       (genptr)&val);
			    gap->offset = (Address)
				(((val >> 12) & 0xffff0) + (val & 0xffff));
			    gap->handle = Handle_Find(gap->offset);

			    /*
			     * If points into a handle, adjust the offset
			     * to be handle-relative.
			     */
			    if (gap->handle != NullHandle) {
				gap->offset =
				    (Address)(gap->offset -
					      Handle_Address(gap->handle));
			    }
			    tokenPtr->flags = 0;
			    break;
			}
			case TYPE_PTR_VIRTUAL:
			{
			    /*
			     * Fetch offset & virtual segment. decide if the
			     * segment is actually handle & look up by
			     * handle ID or segment, as appropriate.
			     */
			    dword   val;
			    word    seg;

			    (void)Var_FetchInt(4,
					       tokenPtr->value.addr.handle,
					       tokenPtr->value.addr.offset,
					       (genptr)&val);
			    seg = (val>>16) & 0xffff;
			    
			    /* 0xffff conditional is for things that have kcode
			     * in the HMA... */
			    if (seg != 0xffff && seg >= 0xf000) {
				/*
				 * Segment is a munged handle. Convert to
				 * handle ID and look that up...
				 */
				gap->offset = (Address)(val & 0xffff);
				gap->handle = Handle_Lookup((unsigned short)
							    ((seg<<4) & 0xfff0));

				if (gap->handle == NullHandle) {
				    xyyerror(state, "handle %04xh invalid",
					     (seg<<4)&0xfff0);
				}
			    } else {
				gap->offset = (Address)
				    (((val >> 12) & 0xffff0) + (val & 0xffff));
				gap->handle = Handle_Find(gap->offset);
				/*
				 * If points into a handle, adjust the offset
				 * to be handle-relative.
				 */
				if (gap->handle != NullHandle) {
				    gap->offset =
					(Address)(gap->offset -
						  Handle_Address(gap->handle));
				}
			    }

			    tokenPtr->flags = 0;
			    break;
			}
			case TYPE_PTR_SEG:
			{
			    /*
			     * Fetch segment & look up its handle. offset is 0.
			     * form absolute address if not found.
			     */
			    word    val;

			    (void)Var_FetchInt(2,
					       tokenPtr->value.addr.handle,
					       tokenPtr->value.addr.offset,
					       (genptr)&val);
			    gap->offset = MakeAddress(val, 0);
			    gap->handle = Handle_Find(gap->offset);

			    /*
			     * If points into a handle, adjust the offset
			     * to be handle-relative.
			     */
			    if (gap->handle != NullHandle) {
				gap->offset =
				    (Address)(gap->offset -
					      Handle_Address(gap->handle));
			    }
			    tokenPtr->flags = 0;
			    break;
			}
			case TYPE_PTR_LMEM:
			{
			    /*
			     * Similar to near, but with extra indirection.
			     */
			    word    val;

			    (void)Var_FetchInt(2,
					       tokenPtr->value.addr.handle,
					       tokenPtr->value.addr.offset,
					       (genptr)&val);
			    (void)Var_FetchInt(2,
					       tokenPtr->value.addr.handle,
					       (Address)val,
					       (genptr)&val);
			    gap->offset = (Address)val;
			    gap->handle = tokenPtr->value.addr.handle;
			    tokenPtr->flags = ETF_HANDLE_FROM_INDIR;
			    break;
			}
			case TYPE_PTR_HANDLE:
			{
			    /*
			     * Similar to seg, but lookup handle by ID, not
			     * segment. XXX: what if handle invalid?
			     * We deal with all types of handles that can be
			     * chained here. If the handle ID is for a memory
			     * handle, we just use the handle we got with
			     * offset 0. Otherwise, we use kdata:ID as the
			     * address with the type being an appropriate one
			     * for the handle type, as defined by
			     * Handle_TypeStruct().
			     */
			    word    val;

			    (void)Var_FetchInt(2,
					       tokenPtr->value.addr.handle,
					       tokenPtr->value.addr.offset,
					       (genptr)&val);
			    gap->offset = 0;
			    gap->handle = Handle_Lookup(val);
			    if (gap->handle == NullHandle) {
				xyyerror(state, "handle %04xh invalid",
					 val);
			    } else if (!Handle_IsMemory(Handle_State(gap->handle)))
			    {
				if (Type_Equal(baseType, type_Void)) {
				    tokenPtr->type =
					Type_CreatePointer(Handle_TypeStruct(gap->handle),
							   TYPE_PTR_FAR);
				}
				gap->handle =
				    kernel->resources[1].handle;
				gap->offset = (Address)val;
			    }
			    tokenPtr->flags = 0;
			    break;
			}
			case TYPE_PTR_OBJECT:
			{
			    /*
			     * Combo of HANDLE & LMEM.
			     */
			    dword   val;

			    (void)Var_FetchInt(4,
					       tokenPtr->value.addr.handle,
					       tokenPtr->value.addr.offset,
					       (genptr)&val);

			    gap->handle = Handle_Lookup((unsigned short)
							((val >> 16) & 0xffff));

			    if (gap->handle != NullHandle) {
				word	off;

				Var_FetchInt(2, gap->handle,
					     (Address)(val & 0xffff),
					     (genptr)&off);
				gap->offset = (Address)off;
			    } else {
				xyyerror(state, "handle %04xh invalid",
					 (val >> 16) & 0xffff);
			    }
			    tokenPtr->flags = 0;
			    break;
			}
		    	case TYPE_PTR_VM:
			{
			    dword   val;

			    (void)Var_FetchInt(4,
					       tokenPtr->value.addr.handle,
					       tokenPtr->value.addr.offset,
					       (genptr)&val);

			    if (!ExprIndirectVMPart1(state,
						     ((val >> 16) & 0xffff),
						     gap))
			    {
				return(FALSE);
			    }
			    if (!ExprIndirectVMPart2(state,
						     gap->handle,
						     (unsigned short)(val & 0xffff),
						     gap))
			    {
				return(FALSE);
			    }
			    tokenPtr->flags = 0;
			    break;
			}
			    
		    }
		    tokenPtr->what = TOKEN_POINTER;
		    tokenPtr->value.ptr = gap;
		    break;
		}
		default:
		    Var_FetchAlloc(tokenPtr->type,
				   tokenPtr->value.addr.handle,
				   tokenPtr->value.addr.offset,
				   (genptr *)&tokenPtr->value.ptr);
		    malloc_settag((malloc_t)tokenPtr->value.ptr, TAG_EXPR);
		    (void)Lst_AtEnd(state->data,
				    (LstClientData)tokenPtr->value.ptr);
		    tokenPtr->what = TOKEN_POINTER;
		    tokenPtr->flags = 0;
		    break;
	    }
	}
    } else {
	/*
	 * Kludge it. The value won't be used anyway and this is the most
	 * harmless thing we can do.
	 */
	if ((Type_Class(tokenPtr->type) != TYPE_ARRAY) &&
	    (Type_Class(tokenPtr->type) != TYPE_FUNCTION))
	{
	    tokenPtr->what = TOKEN_LITERAL;
	    tokenPtr->value.literal = 1;
	    tokenPtr->type = type_Int;
	    tokenPtr->flags = 0;
	}
    }
    return(TRUE);
}

/*-
 *-----------------------------------------------------------------------
 * ExprArithOrPointerOp --
 *	Perform an arithmetic operation on either ints, chars, floats,
 *	doubles or pointers.
 *
 * Results:
 *	...
 *
 * Side Effects:
 *	...
 *
 *-----------------------------------------------------------------------
 */
static Boolean
ExprArithOrPointerOp(ExprState	*state,
		     int	op,
		     ExprToken	*lhs,
		     ExprToken	*rhs,
		     ExprToken	*result)
{
    /*
     * Fetch both sides and perform standard coercion for arithmetic
     * expressions.
     */

    if (ExprCoerce(state, lhs, rhs, TRUE)) {
	if ((lhs->what == TOKEN_ADDRESS) ||
	    ((lhs->what == TOKEN_POINTER) &&
	     (Type_Class(lhs->type) == TYPE_POINTER)))
	{
	    GeosAddr	*gap;
	    int	    	size;

	    if (lhs->what == TOKEN_POINTER) {
		Type	baseType;

		Type_GetPointerData(lhs->type, (int *)NULL, &baseType);
		gap = lhs->value.ptr;

		size = Type_Sizeof(baseType);
	    } else {
		gap = &lhs->value.addr;
		size = Type_Sizeof(lhs->type);
	    }
	    
	    /*
	     * Must have been a pointer or array. Play with the offset
	     * portion of value.addr
	     */

	    if (rhs->what == TOKEN_LITERAL) {
		if (op == '+') {
		    gap->offset += size * rhs->value.literal;
		} else {
		    gap->offset -= size * rhs->value.literal;
		}
		*result = *lhs;
	    } else if (rhs->what == TOKEN_ADDRESS) {
		/*
		 * Another pointer.
		 */
		if ((op == '+') || !Type_Equal(lhs->type, rhs->type)) {
		    /*
		     * Adding pointers, or subtracting pointers to different
		     * data types: honk.
		     */
		    xyyerror(state,"operands have incompatible types");
		    return(FALSE);
		} else if ((gap->handle != rhs->value.addr.handle) &&
			   !(rhs->flags & ETF_HANDLE_FROM_INDIR))
		{
		    xyyerror(state, "pointers are to different blocks");
		    return(FALSE);
		} else {
		    result->value.literal =
			(gap->offset - rhs->value.addr.offset)/size;
		    result->type = type_Int;
		    result->what = TOKEN_LITERAL;
		    result->flags = 0;
		}
	    } else if ((rhs->what == TOKEN_POINTER) &&
		       (Type_Class(rhs->type) == TYPE_POINTER) &&
		       (op == '-') &&
		       Type_Equal(lhs->type, rhs->type))
	    {
		result->value.literal =
		    (gap->offset - ((GeosAddr *)rhs->value.ptr)->offset)/size;
		result->type = type_Int;
		result->what = TOKEN_LITERAL;
		result->flags = 0;
	    } else {
		xyyerror(state, "operands have incompatible types");
		return(FALSE);
	    }
	} else if ((rhs->what == TOKEN_ADDRESS) ||
		   ((rhs->what == TOKEN_POINTER) &&
		    (Type_Class(rhs->type) == TYPE_POINTER)))
	{
	    GeosAddr	*gap;
	    int	    	size;

	    if (rhs->what == TOKEN_POINTER) {
		Type	baseType;
		
		gap = rhs->value.ptr;
		Type_GetPointerData(rhs->type, (int *)NULL, &baseType);
		size = Type_Sizeof(baseType);
	    } else {
		gap = &rhs->value.addr;
		size = Type_Sizeof(rhs->type);
	    }

	    /*
	     * RHS is pointer or array
	     */

	    if (Type_Class(rhs->type) == TYPE_ARRAY) {
		Type	baseType;

		Type_GetArrayData(rhs->type, (int *)NULL,
				  (int *)NULL, (Type *)NULL, &baseType);
		rhs->type = baseType;
		size = Type_Sizeof(baseType);
	    }
		
	    if (lhs->what == TOKEN_LITERAL) {
		if (op == '-') {
		    xyyerror(state,"invalid operand for operator");
		    return(FALSE);
		} else {
		    gap->offset += lhs->value.literal * size;
		    *result = *rhs;
		}
	    } else {
		xyyerror(state, "operands have incompatible types");
		return(FALSE);
	    }
	} else {
	    return (ExprArithOp(state, op, lhs, rhs, result));
	}
    } else {
	xyyerror(state, "operands have incompatible types");
	return(FALSE);
    }
    return (TRUE);
}

/*-
 *-----------------------------------------------------------------------
 * ExprArithOp --
 *	Perform an arithmetic operation on two integers, floats, doubles
 *	or characters.
 *
 * Results:
 *	A token for the result.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
ExprArithOp(ExprState		*state,
	    int			op,
	    ExprToken		*lhs,
	    ExprToken		*rhs,
	    ExprToken		*result)
{
    if (!ExprCoerce(state, lhs, rhs, TRUE)) {
	xyyerror(state, "operands have incompatible types");
	return(FALSE);
    } else if (Type_Class(lhs->type) == TYPE_INT) {
	return (ExprIntOp(state, op, lhs, rhs, result));
    } else if (Type_Class(lhs->type) != TYPE_FLOAT) {
	/*
	 * If either one is a float, they both will be, so it suffices to
	 * check just the lhs. If it's not a float, guess what? Bad
	 * typeage!
	 */
	xyyerror(state, "improper operands for operator");
	return(FALSE);
    } else {
	/*
	 * Cast both to double and operate on them
	 */
	double *dp = (double *)malloc_tagged(sizeof(double), TAG_EXPR);

	(void)Lst_AtEnd(state->data, (LstClientData)dp);
	result->what = TOKEN_POINTER;
	result->type = type_Double;
	result->value.ptr = dp;
	result->flags = 0;
	
	switch(op) {
	    case '+':
		*dp = *(double *)lhs->value.ptr + *(double *)rhs->value.ptr;
		break;
	    case '-':
		*dp = *(double *)lhs->value.ptr - *(double *)rhs->value.ptr;
		break;
	    case '*':
		*dp = *(double *)lhs->value.ptr * *(double *)rhs->value.ptr;
		break;
	    case '/':
		*dp = *(double *)lhs->value.ptr / *(double *)rhs->value.ptr;
		break;
	}
	return(TRUE);
    }
}

/*-
 *-----------------------------------------------------------------------
 * ExprIntOp --
 *	Perform an arithmetic operation on two integers or characters.
 *
 * Results:
 *	The token for the result.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
ExprIntOp(ExprState	*state,
	  int		op,
	  ExprToken	*lhs,
	  ExprToken	*rhs,
	  ExprToken	*result)
{
    if (!ExprCoerce(state, lhs, rhs, FALSE)) {
	yyerror("operands must be integers");
	return(FALSE);
    } else if (Type_IsSigned(lhs->type)) {
	long 	  res;
	long 	  left, right;

	if (lhs->what == TOKEN_POINTER) {
	    if (Type_Sizeof(lhs->type) == 2) {
		left = *(short *)lhs->value.ptr;
	    } else {
		left = *(long *)lhs->value.ptr;
	    }
	} else {
	    left = lhs->value.literal;
	}
	if (rhs->what == TOKEN_POINTER) {
	    if (Type_Sizeof(rhs->type) == 2) {
		right = *(short *)rhs->value.ptr;
	    } else {
		right = *(long *)rhs->value.ptr;
	    }
	} else {
	    right = rhs->value.literal;
	}
	switch(op) {
	    case '+': 	    res = left + right; break;
	    case '-':	    res = left - right; break;
	    case LEFT_OP:   res = left << right; break;
	    case RIGHT_OP:  res = left >> right; break;
	    case '&':	    res = left & right; break;
	    case '^':	    res = left ^ right; break;
	    case '|':	    res = left | right; break;
	    case '*':	    res = left * right; break;
	    case '/':	    res = left / right; break;
	    case '%':	    res = left % right; break;
	    default:	    assert(0); res = 0; break;
	}
	result->what = TOKEN_LITERAL;
	if (Type_Equal(lhs->type, type_Long) ||
	    Type_Equal(rhs->type, type_Long))
	{
	    result->value.literal = res;
	    result->type = type_Long;
	} else {
	    result->value.literal = (short)res;
	    result->type = type_Int;
	}
	result->flags = 0;
    } else {
	unsigned long 	  res;
	unsigned long 	  left, right;

	if (lhs->what == TOKEN_POINTER) {
	    if (Type_Sizeof(lhs->type) == 2) {
		left = *(unsigned short *)lhs->value.ptr;
	    } else {
		left = *(unsigned long *)lhs->value.ptr;
	    }
	} else {
	    left = lhs->value.literal;
	}
	if (rhs->what == TOKEN_POINTER) {
	    if (Type_Sizeof(rhs->type) == 2) {
		right = *(unsigned short *)rhs->value.ptr;
	    } else {
		right = *(unsigned long *)rhs->value.ptr;
	    }
	} else {
	    right = rhs->value.literal;
	}
	switch(op) {
	    case '+': 	    res = left + right; break;
	    case '-':	    res = left - right; break;
	    case LEFT_OP:   res = left << right; break;
	    case RIGHT_OP:  res = left >> right; break;
	    case '&':	    res = left & right; break;
	    case '^':	    res = left ^ right; break;
	    case '|':	    res = left | right; break;
	    case '*':	    res = left * right; break;
	    case '/':	    res = left / right; break;
	    case '%':	    res = left % right; break;
	    default:	    assert(0); res = 0; break;
	}
	result->what = TOKEN_LITERAL;
	if (Type_Equal(lhs->type, type_UnsignedLong) ||
	    Type_Equal(rhs->type, type_UnsignedLong))
	{
	    result->value.literal = res;
	    result->type = type_UnsignedLong;
	} else {
	    result->value.literal = (unsigned short)res;
	    result->type = type_UnsignedInt;
	}
	result->flags = 0;
    }
    return(TRUE);
}

/*-
 *-----------------------------------------------------------------------
 * ExprRelOp --
 *	Perform a relational operation on two values
 *
 * Results:
 *	The token for the result.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
ExprRelOp(ExprState	*state,
	  int		op,
	  ExprToken	*lhs,
	  ExprToken	*rhs,
	  ExprToken	*result)
{
    if (!ExprCoerce(state, lhs, rhs, TRUE)) {
	xyyerror(state, "operands have incompatible types");
	return(FALSE);
    } else if (Type_Class(lhs->type) == TYPE_INT) {
	assert(lhs->what == TOKEN_LITERAL && rhs->what == TOKEN_LITERAL);
	switch(op) {
	    case '<':
		result->value.literal =
		    (lhs->value.literal < rhs->value.literal);
		break;
	    case LE_OP:
		result->value.literal =
		    (lhs->value.literal <= rhs->value.literal);
		break;
	    case '>':
		result->value.literal =
		    (lhs->value.literal > rhs->value.literal);
		break;
	    case GE_OP:
		result->value.literal =
		    (lhs->value.literal >= rhs->value.literal);
		break;
	    case EQ_OP:
		result->value.literal =
		    (lhs->value.literal == rhs->value.literal);
		break;
	    case NE_OP:
		result->value.literal =
		    (lhs->value.literal != rhs->value.literal);
		break;
	}
	result->what = TOKEN_LITERAL;
	result->type = type_Int;
	result->flags = 0;
	return(TRUE);
    } else if ((Type_Class(lhs->type) == TYPE_POINTER) &&
	       (Type_Class(rhs->type) == TYPE_POINTER))
    {
	if (((GeosAddr *)lhs->value.ptr)->handle !=
	    ((GeosAddr *)rhs->value.ptr)->handle)
	{
	    xyyerror(state, "cannot compare pointers to different blocks");
	    return(FALSE);
	} else {
	    result->what = TOKEN_LITERAL;
	    result->type = type_Int;
	    result->flags = 0;
	    
	    switch(op) {
		case '<':
		    result->value.literal =
			(((GeosAddr *)lhs->value.ptr)->offset <
			 ((GeosAddr *)rhs->value.ptr)->offset);
		    break;
		case LE_OP:
		    result->value.literal =
			(((GeosAddr *)lhs->value.ptr)->offset <=
			 ((GeosAddr *)rhs->value.ptr)->offset);
		    break;
		case '>':
		    result->value.literal =
			(((GeosAddr *)lhs->value.ptr)->offset >
			 ((GeosAddr *)rhs->value.ptr)->offset);
		    break;
		case GE_OP:
		    result->value.literal =
			(((GeosAddr *)lhs->value.ptr)->offset >=
			 ((GeosAddr *)rhs->value.ptr)->offset);
		    break;
		case EQ_OP:
		    result->value.literal =
			(((GeosAddr *)lhs->value.ptr)->offset ==
			 ((GeosAddr *)rhs->value.ptr)->offset);
		    break;
		case NE_OP:
		    result->value.literal =
			(((GeosAddr *)lhs->value.ptr)->offset !=
			 ((GeosAddr *)rhs->value.ptr)->offset);
		    break;
	    }
	    return(TRUE);
	}
    } else if (Type_Class(lhs->type) != TYPE_FLOAT) {
	/*
	 * If either one is a float, they both will be, so it suffices to
	 * check just the lhs. If it's not a float, guess what? Bad
	 * typeage!
	 */
	xyyerror(state, "improper operands for operator");
	return(FALSE);
    } else {
	/*
	 * Cast both to double and operate on them
	 */
	result->what = TOKEN_LITERAL;
	result->type = type_Int;
	result->flags = 0;
	
	switch(op) {
	    case '<':
		result->value.literal =
		    (*(double *)lhs->value.ptr < *(double *)rhs->value.ptr);
		break;
	    case LE_OP:
		result->value.literal =
		    (*(double *)lhs->value.ptr <= *(double *)rhs->value.ptr);
		break;
	    case '>':
		result->value.literal =
		    (*(double *)lhs->value.ptr > *(double *)rhs->value.ptr);
		break;
	    case GE_OP:
		result->value.literal =
		    (*(double *)lhs->value.ptr >= *(double *)rhs->value.ptr);
		break;
	    case EQ_OP:
		result->value.literal =
		    (*(double *)lhs->value.ptr == *(double *)rhs->value.ptr);
		break;
	    case NE_OP:
		result->value.literal =
		    (*(double *)lhs->value.ptr != *(double *)rhs->value.ptr);
		break;
	}
	return(TRUE);
    }
}

/*-
 *-----------------------------------------------------------------------
 * ExprEvalBoolean --
 *	Evaluate a token as a boolean value and return its value.
 *
 * Results:
 *	0 if the token is 0, 1 if it is non-zero and -1 if it's an error.
 *
 * Side Effects:
 *	The value will be fetched from the patient if necessary.
 *
 *-----------------------------------------------------------------------
 */
static int
ExprEvalBoolean(ExprState  *state,
		ExprToken   *token)
{
    if (!ExprCoerce(state, token, (ExprToken *)NULL, TRUE)) {
	return (-1);
    } else if (token->what == TOKEN_POINTER) {
	if (Type_Equal(token->type, type_Double)) {
	    if (*(double *)token->value.ptr == 0.0) {
		return (0);
	    } else {
		return (1);
	    }
	} else {
	    short 	  *value;
	    int 	  retVal;
	    
	    value = (short *) Var_Cast(token->value.ptr,
				       token->type, type_Int);
	    if (*value) {
		retVal = 1;
	    } else {
		retVal = 0;
	    }
	    free((char *)value);
	    return(retVal);
	}
    } else if (token->what == TOKEN_LITERAL) {
	switch (Type_Class(token->type)) {
	    case TYPE_INT:
	    case TYPE_POINTER:
		return (token->value.literal ? 1 : 0);
	    default:
		return (-1);
	}
    } else if (token->what == TOKEN_ADDRESS) {
	return(((token->value.addr.handle == NullHandle) &&
		(token->value.addr.offset == 0)) ?
	       0 : 1);
    } else {
	return(-1);
    }
}

/*-
 *-----------------------------------------------------------------------
 * ExprStandardCoerce --
 *	Perform the standard single-token coercions.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The value may be altered.
 *
 *-----------------------------------------------------------------------
 */
static void
ExprStandardCoerce(ExprState	*state,
		   ExprToken	*token)
{
    ExprFetch(state, token);
    
    switch (Type_Class(token->type)) {
	case TYPE_CHAR: {
	    /*
	     * Characters are promoted to be ints.
	     *
	     * Can only have TYPE_CHAR if 'what' is TOKEN_POINTER since
	     * it must have been fetched from the patient by ExprFetch
	     * (& character literals are cast to be ints).
	     */
	    int	  	*value;

	    value = (int *)Var_Cast(token->value.ptr,
				    token->type, type_Int);
	    token->what = TOKEN_LITERAL;
	    token->value.literal = *value;
	    token->type = type_Int;
	    free((char *)value);
	    break;
	}
	case TYPE_INT:
	    if (Type_IsSigned(token->type)) {
		if (Type_Sizeof(token->type) < Type_Sizeof(type_Int)) {
		    if (!Type_Equal(token->type, type_Int)) {
			/*
			 * Non-int ints are promoted to be ints.
			 */
			if (token->what == TOKEN_POINTER) {
			    short 	*value;

			    value = (short *)Var_Cast(token->value.ptr,
						      token->type,
						      type_Int);
			    token->what = TOKEN_LITERAL;
			    token->value.literal = *value;
			    token->type = type_Int;
			    free((char *)value);
			} else {
			    /*
			     * If it's literal, it must already be an int.
			     */
			    token->type = type_Int;
			}
		    } else if (token->what == TOKEN_POINTER) {
			/*
			 * Ints are expected to be literals during operations...
			 */
			token->what = TOKEN_LITERAL;
			token->value.literal = *(short *)token->value.ptr;
		    }
		} else if (token->what == TOKEN_POINTER) {
		/*
		 * Ints are expected to be literals during operations.
		 */
		    if (Type_Equal(token->type, type_UnsignedLong)) {
		    /*
		     * Cope with unsigned longs, converting them to literals
		     */
			token->what = TOKEN_LITERAL;
			token->value.literal = *(unsigned long *)token->value.ptr;
		    } else {
			/*
			 * Must be unsigned short or unsigned int...
			 */
			token->what = TOKEN_LITERAL;
			token->value.literal = *(unsigned short *)token->value.ptr;
		    }
		}
	    } else if (Type_Sizeof(token->type)<Type_Sizeof(type_UnsignedInt)) {
		/*
		 * Non-int ints are promoted to be ints...plus unsigned,
		 * in this case.
		 */
		if (!Type_Equal(token->type, type_UnsignedInt)) {
		    if (token->what == TOKEN_POINTER) {
			unsigned short    *value;

			value =
			    (unsigned short *)Var_Cast(token->value.ptr,
						       token->type,
						       type_UnsignedInt);
			token->what = TOKEN_LITERAL;
			token->value.literal = *value;
			token->type = type_UnsignedInt;
			free((char *)value);
		    } else {
			token->type = type_UnsignedInt;
		    }
		} else if (token->what == TOKEN_POINTER) {
		    /*
		     * Ints are expected to be literals...
		     */
		    token->what = TOKEN_LITERAL;
		    token->value.literal = *(unsigned short *)token->value.ptr;
		}
	    } else if (token->what == TOKEN_POINTER) {
		/*
		 * Ints are expected to be literals during operations.
		 */
		if (Type_Equal(token->type, type_UnsignedLong)) {
		    /*
		     * Cope with unsigned longs, converting them to literals
		     */
		    token->what = TOKEN_LITERAL;
		    token->value.literal = *(unsigned long *)token->value.ptr;
		} else {
		    /*
		     * Must be unsigned short or unsigned int...
		     */
		    token->what = TOKEN_LITERAL;
		    token->value.literal = *(unsigned short *)token->value.ptr;
		}
	    }
	    break;
	case TYPE_FLOAT:
	    /*
	     * floats are promoted to be long doubles.
	     */
	    if (!Type_Equal(token->type, type_LongDouble)) {
		token->value.ptr = (Opaque)Var_Cast(token->value.ptr,
						    token->type,
						    type_LongDouble);
		token->what = TOKEN_POINTER;
		token->type = type_LongDouble;
		(void)Lst_AtEnd(state->data, (LstClientData)token->value.ptr);
	    }
	    break;
        case TYPE_ARRAY:
	    /*
	     * Convert address of base of array to far pointer
	     */
	    if (token->what == TOKEN_ADDRESS) {
		Type    baseType;

		Type_GetArrayData(token->type, (int *)NULL,
				  (int *)NULL, (Type *)NULL, &baseType);
		ExprSetAsPointer(state, token, TYPE_PTR_FAR, baseType,
				 token->value.addr.handle,
				 token->value.addr.offset);
	    }
	    break;
	default:
	    /*
	     * What else?
	     */
	    break;
    }
}
/*-
 *-----------------------------------------------------------------------
 * ExprCoerce --
 *	Fetch and perform standard arithmetic coercion on the given tokens
 *	to make them type-compatible. If floatOk is TRUE, then we allow
 *	floating-point tokens. The coercions are as follows:
 *	    char, short -> int
 *	    float -> long double
 *	    if either token is a long double, both are made long double
 *	    if either token is unsigned, both are made unsigned
 *	    if either is long, both are made long.
 *
 * Results:
 *	TRUE if the coercion could be accomplished and FALSE otherwise.
 *
 * Side Effects:
 *	The values of the tokens are fetched, if they're not already in
 *	our address space, and the types and values manipulated.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
ExprCoerce(ExprState	*state,
	   ExprToken	*token1,
	   ExprToken	*token2,
	   Boolean	floatOk)
{
    /*
     * Perform type coercion that is performed regardless of the type of
     * the other operand, after fetching anything from the patient that
     * needs to be fetched.
     */
    if (token1) {
	ExprStandardCoerce(state, token1);
    }
    if (token2) {
	ExprStandardCoerce(state, token2);
    }

    if (token1 && token2) {
	/*
	 * Now coerce the values based on what the types of the two operands
	 * are.
	 */
	int class1 = Type_Class(token1->type);
	int class2 = Type_Class(token2->type);
	
	if (!floatOk && ((class1 == TYPE_FLOAT) || (class2 == TYPE_FLOAT))){
	    return(FALSE);
	}
	if ((class1 == TYPE_FLOAT) && (class2 != TYPE_FLOAT)) {
	    if (token2->what == TOKEN_POINTER) {
		token2->value.ptr = (Opaque)Var_Cast(token2->value.ptr,
						     token2->type,
						     type_Double);
		(void)Lst_AtEnd(state->data, (LstClientData)token2->value.ptr);
	    } else if (token2->what == TOKEN_LITERAL) {
		long double	*dp;

		dp = (long double *)malloc_tagged(sizeof(long double),
						  TAG_EXPR);
		*dp = (long double)token2->value.literal;

		token2->what = TOKEN_POINTER;
		token2->value.ptr = (Opaque)dp;
		(void)Lst_AtEnd(state->data, (LstClientData)token2->value.ptr);
	    }
	    token2->type = type_LongDouble;
	    token2->flags = 0;
	} else if ((class2 == TYPE_FLOAT) && (class1 != TYPE_FLOAT)) {
	    if (token1->what == TOKEN_POINTER) {
		token1->value.ptr = (Opaque)Var_Cast(token1->value.ptr,
						     token1->type,
						     type_Double);
		(void)Lst_AtEnd(state->data, (LstClientData)token1->value.ptr);
	    } else if (token1->what == TOKEN_LITERAL) {
		long double *dp;

		dp = (long double *)malloc(sizeof(long double));
		*dp = (long double)token1->value.literal;

		token1->what = TOKEN_POINTER;
		token1->value.ptr = dp;
		(void)Lst_AtEnd(state->data, (LstClientData)token1->value.ptr);
	    }
	    token1->type = type_LongDouble;
	} else if (!Type_IsSigned(token1->type)) {
	    if (Type_IsSigned(token2->type)) {
		Type	dst = type_UnsignedInt;

		/*
		 * If token1 is long, we need token2 to be long, too.
		 */
		if (Type_Equal(token1->type, type_UnsignedLong)) {
		    dst = type_UnsignedLong;
		}
		if (token2->what == TOKEN_POINTER) {
		    token2->value.ptr =
			(Opaque)Var_Cast(token2->value.ptr,
					 token2->type,
					 dst);
		    (void)Lst_AtEnd(state->data, (LstClientData)token2->value.ptr);
		}
		token2->type = dst;
	    }
	} else if (!Type_IsSigned(token2->type)) {
	    Type    dst = type_UnsignedInt;

	    /*
	     * If token2 is long, we need token1 to be long, too.
	     */
	    if (Type_Equal(token2->type, type_UnsignedLong)) {
		dst = type_UnsignedLong;
	    }
	    
	    if (token1->what == TOKEN_POINTER) {
		token1->value.ptr = (Opaque)Var_Cast(token1->value.ptr,
						     token1->type,
						     dst);
		(void)Lst_AtEnd(state->data, (LstClientData)token1->value.ptr);
	    }
	    token1->type = dst;
	}
	return(TRUE);
    } else if (token1) {
	return(floatOk ? TRUE : (Type_Class(token1->type) != TYPE_FLOAT));
    } else if (token2) {
	return(floatOk ? TRUE : (Type_Class(token2->type) != TYPE_FLOAT));
    } else {
	return(TRUE);
    }
}
/*-
 *-----------------------------------------------------------------------
 * Expr_DebugCmd --
 *	Switch the state of expression debugging.
 *
 * Results:
 *	TCL_OK.
 *
 * Side Effects:
 *	exprDebug is altered.
 *
 *-----------------------------------------------------------------------
 */
DEFCMD(expr-debug,ExprDebug,TCL_EXACT,NULL,obscure,
"Usage:\n\
    expr-debug (on|off)\n\
\n\
Examples:\n\
    \"expr-debug on\"	Turn on debugging output for parsing of address\n\
			expressions.\n\
\n\
Synopsis:\n\
    Enables or disables debugging output during the parsing of address\n\
    expressions.\n\
\n\
See also:\n\
    addr-parse.\n\
")
{
    if (argc == 2 && strcmp(argv[1], "on") == 0) {
	exprDebug = 1;
    } else {
	exprDebug = (argc == 2) ? atoi(argv[1]) : 0;
    }
    return(TCL_OK);
}


/***********************************************************************
 *				AddrParseCmd
 ***********************************************************************
 * SYNOPSIS:	Parse an address into its components
 * CALLED BY:	Tcl
 * RETURN:	A list {handle offset type}
 * SIDE EFFECTS:None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(addr-parse,AddrParse,TCL_EXACT,NULL,swat_prog,
"Usage:\n\
    addr-parse <addr> [<addr-only> [<frame>]]\n\
\n\
Examples:\n\
    \"addr-parse *ds:si\"		Parse the address \"*ds:si\" into its handle,\n\
    				offset and data-type components. In this\n\
				case, the data-type will be \"nil\".\n\
    \"addr-parse ILLEGAL_HANDLE 0\"	Figures the value for the enumerated constant\n\
				\"ILLEGAL_HANDLE\". The handle for this 'address'\n\
				will be \"value\".\n\
\n\
Synopsis:\n\
    This command parses the address expression into its components, returning\n\
    a list {<handle> <offset> <type>} as its value.\n\
\n\
Notes:\n\
    * This will generate an error if there's an error parsing the <addr>\n\
\n\
    * <handle> is the token for the handle in which the address resides, or\n\
      \"nil\" if the address is absolute. This token can be given to the \"handle\"\n\
      command for further processing.\n\
\n\
    * <offset> is a decimal number and is the offset of the address within\n\
      the block indicated by the <handle> token. If <handle> is \"nil\", this\n\
      can be a 32-bit linear address.\n\
\n\
    * <type> is a type token for the data at the given address, if any could\n\
      be determined. For example the address \"ds:bx\" has no type, as it's\n\
      just a memory reference, but \"ds:bx.VDE_extraData\" will have whatever\n\
      type the structure field \"VDE_extraData\" possesses. This token can be\n\
      passed to the \"type\" or \"value\" commands for further processing.\n\
\n\
    * If the expression doesn't refer to data that can be fetched from the\n\
      patient (e.g. \"foo*3\") <handle> will be returned as the string\n\
      \"value\" instead of a normal handle token. <offset> is then a value-\n\
      list for the resulting value, and <type> is the type description by\n\
      means of which the value list can be interpreted.\n\
\n\
    * The optional <addr-only> argument is 0 or non-zero to indicate the\n\
      willingness or unwillingness, respectively, of the caller to receive\n\
      a value list in return. If <addr-only> is absent or non-zero, any\n\
      expression that can only be expressed as a value will generate an error.\n\
      the single exception to this is if the expression involves pointer\n\
      arithmetic. For example \"pself+1\" normally would be returned as a\n\
      value list for a far pointer, as the result cannot be fetched from the\n\
      PC. When <addr-only> is absent or non-zero, \"addr-parse\" pretends the\n\
      expression was \"*(pself+1)\", allowing simple specification of an\n\
      address by the user for those commands that just address memory.\n\
\n\
    * The <offset> element of the returned list is very useful when you want\n\
      to allow the user to give you anything, be it a register or a number or\n\
      an enumerated constant or whatever. You can pass the argument you were\n\
      given to [index [addr-parse $arg] 1] and end up with an appropriate\n\
      decimal number. Be sure to pass <addr-only> as 0, however, or else\n\
      you'll generate an error.\n\
\n\
    * The optional <frame> argument is the token for a frame (as returned by\n\
      the \"frame\" command) in whose context the expression should be\n\
      evaluated. All registers, XIP mappings, local variables, etc., come\n\
      from that frame.\n\
\n\
See also:\n\
    value, handle, type\n\
")
{
    GeosAddr	addr;
    Type	type;
    Frame   	*frame;

    if (argc < 2) {
	Tcl_Error(interp, "Usage: addr-parse <addr> [<addr-only> [<frame>]]");
    }

    if (argc > 3) {
	frame = (Frame *)atoi(argv[3]);
	if (!VALIDTPTR(frame, TAG_FRAME)) {
	    Tcl_RetPrintf(interp, "%.50s: not a valid frame", argv[3]);
	    return (TCL_ERROR);
	}
    } else {
	frame = NullFrame;
    }
    
    if (!Expr_Eval(argv[1], frame, &addr, &type,
		   (argc > 2) ? atoi(argv[2]) : TRUE))
    {
	return(TCL_ERROR);
    }

    switch((long)addr.handle) {
	case (long)NullHandle:
	    if (Type_IsNull(type)) {
		Tcl_RetPrintf(interp, "nil %d nil", addr.offset);
	    } else {
		Tcl_RetPrintf(interp, "nil %d {%s}", addr.offset,
			      Type_ToAscii(type));
	    }
	    break;
	case (long)ValueHandle:
	{
	    char    *retargv[3];

	    retargv[0] = "value";
	    retargv[1] = Value_ConvertToString(type, (Opaque)addr.offset);
	    retargv[2] = Type_ToAscii(type);
	    
	    Tcl_Return(interp, Tcl_Merge(3, retargv), TCL_DYNAMIC);
	    free(retargv[1]);
	    free((malloc_t)addr.offset);
	    break;
	}
	default:
	    if (!Type_IsNull(type)) {
		Tcl_RetPrintf(interp, "%d %d {%s}", addr.handle, addr.offset,
			      Type_ToAscii(type));
	    } else {
		Tcl_RetPrintf(interp, "%d %d nil", addr.handle, addr.offset);
	    }
	    break;
    }
    return(TCL_OK);
}

