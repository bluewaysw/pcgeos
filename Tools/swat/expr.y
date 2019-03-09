%{
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

%}

%union {
    int	    	op;	    	/* Regular operator token */
    Type	type;	    	/* type.name token */
    ExprToken	token;    	/* Everything else */
    Sym	     	sym;	    	/* SYM token */
}

%pure_parser

%token <token> 	  CONSTANT STRING_LITERAL '.' PTR_OP VHIST ADDRESS
%token <type>	  TYPE
%token <sym>	  SYM
%token 	    	  SIZEOF HANDLE VHANDLE LHANDLE
%token  	  LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
		  AND_OP OR_OP

%token <op>	  CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE
		  CONST VOLATILE VOID
		  WORD BYTE DWORD SWORD SBYTE SDWORD
		  DA_NEAR DA_FAR DA_SEG DA_LMEM DA_HANDLE DA_OBJECT
		  DA_VM DA_VIRTUAL
		  FPTR NPTR SPTR LPTR HPTR OPTR VPTR VFPTR
%token <op>	  RANGE

%start expr.return

%left ','
%nonassoc '#' RANGE
%left  OR_OP
%left  AND_OP
%left  '|'
%left  '^'
%left  '&'
%left  EQ_OP NE_OP
%left  '<' '>' LE_OP GE_OP
%left  LEFT_OP RIGHT_OP
%left  '+' '-'
%left  '*' '/' '%'
%right NOT_QUITE_UNARY
%right INC_OP DEC_OP UNARY SIZEOF '!' '~'
%left  '.' PTR_OP '[' ']' '(' ')'
%nonassoc ':'
%nonassoc   HIGHEST HANDLE LHANDLE VHANDLE

%type <token> 	  expr top.expr struct.op
%type <type>	  type.name type.specifier open.paren
		  abstract.declarator abstract.declarator2 ptr.decl
%type <op>	  type.modifier type.modifier.list

%%

/*
 * Return result of expression. Takes the value out of the token
 * and stores it in the appropriate arguments.
 */
expr.return 	: top.expr
		{
		    state->result = $1;
		    if (state->freeStacks) {
			free(state->valStack);
			free(state->stateStack);
			YYACCEPT;
		    }
		}
		| error
		{
		    if (state->freeStacks) {
			free(state->valStack);
			free(state->stateStack);
		    }
		    YYABORT;
		}
		    
		;

top.expr	: type.specifier expr
		{
		    if (!ExprCast(state, &$2, $1, &$$, TRUE)) {
			YYERROR;
		    }
		}
		| top.expr ',' expr  	    	{ $$ = $3; }
		| top.expr '#' expr
		{
		    ExprStandardCoerce(state, &$3);
		    if ($3.what == TOKEN_LITERAL) {
			if (!ExprCast(state, &$1,
				      Type_CreateArray(0,
						       $3.value.literal-1,
						       type_Int,
						       $1.type),
				      &$$, TRUE))
			{
			    YYERROR;
			}
		    } else {
			xyyerror(state, "array length must be integral");
		    }
		}
		| expr
		;

expr		: ADDRESS 
		;

expr 		: SYM
		{
		    int	class = Sym_Class($1);
		    $$.flags = 0;
		    $$.what = TOKEN_ADDRESS;

		    if (class & SYM_MODULE) {
			$$.value.addr.handle = ExprModuleToHandle(state, $1);
			$$.value.addr.offset = 0;
			$$.type = NullType;
		    } else if (class & (SYM_FUNCTION|SYM_LABEL)) {
			Type	retType;
			
			Sym_GetFuncData($1, (Boolean *)NULL,
					&$$.value.addr.offset,
					&retType);
			$$.type = Type_CreateFunction(retType);
			$$.value.addr.handle =
			    ExprModuleToHandle(state,
					       Sym_Scope($1, FALSE));
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
			
			Sym_GetVarData($1, &type, &sClass, &offset);
			    
			switch(sClass) {
			    case SC_Static:
				$$.value.addr.offset = offset;
				$$.type = type;
				$$.value.addr.handle =
				    ExprModuleToHandle(state,
						       Sym_Scope($1, FALSE));
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
				    $$.value.addr.handle = Ibm_StackHandle();
				    $$.value.addr.offset = offset+fp;
				    $$.type = type;
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
				    $$.what = TOKEN_LITERAL;
				    $$.value.literal = val;
				    /* try using the actual type rather than
				     * type_Word so things like enums whose
				     * values are stored in register variables
				     * will have type info in them
				     * 12/30/94 - jimmy
				     */
				    $$.type = type;
				}
				break;
			    default:
				xyyerror(state,
					 "unknown storage class %d for %s",
					 sClass, Sym_Name($1));
				YYERROR;
			}
		    } else if (class & SYM_FIELD) {
			int 	offset;
			Type	type;
			
			Sym_GetFieldData($1, &offset, (int *)NULL, &type,
					 (Type *)NULL);
			ExprSetAsPointer(state, &$$,
					 TYPE_PTR_FAR,
					 type,
					 NullHandle,
					 (Address)(offset/8));
		    } else {
			xyyerror(state,
				 "Unknown symbol class for %s",
				 Sym_Name($1));
		    }
		}
		| HANDLE expr
		{
		    ExprStandardCoerce(state, &$2);
		    if ($2.what != TOKEN_LITERAL) {
			yyerror("operand of ^h must be an integer");
			YYERROR;
		    } else {
			$$.what = TOKEN_ADDRESS;
			$$.value.addr.handle = Handle_Lookup((unsigned short)$2.value.literal);
			$$.value.addr.offset = 0;
			$$.type = NullType;
			$$.flags = 0;
		    }
		}
		| VHIST
		| CONSTANT
		| STRING_LITERAL
		| '(' top.expr ')'		    { $$ = $2; }
		| '{' top.expr '}'	    	    	    { $$ = $2; }
		| expr '[' expr ']'
		{
		    if (($1.what != TOKEN_ADDRESS) &&
			(($1.what != TOKEN_POINTER) ||
			 (Type_Class($1.type) != TYPE_POINTER)))
		    {
			yyerror("operand of [] must be a pointer or array");
			YYERROR;
		    } else {
			switch (Type_Class($1.type)) {
			    default:
			    {
				/*
				 * Make life a bit easier by coercing the thing
				 * to an array of infinite size.
				 */
				unsigned	  	bound;
				
				bound = (1<<(Type_Sizeof(type_Int)*8-1))-1;
				$1.type =
				    Type_CreateArray(0, bound, type_Int,
						     $1.type);
				/*FALLTHRU*/
			    }
			    case TYPE_ARRAY:
			    case TYPE_POINTER:
				if (!ExprArithOrPointerOp(state, '+', &$1, &$3,
							  &$$))
				{
				    YYERROR;
				}
		    	    	if (!ExprIndirect(state, &$$, &$$)) {
				    YYERROR;
				}
				break;
			}
		    }
		}
		| expr '[' expr RANGE expr ']'
		{
		    if (($1.what != TOKEN_ADDRESS) &&
			(($1.what != TOKEN_POINTER) ||
			 (Type_Class($1.type) != TYPE_POINTER)))
		    {
			yyerror("operand of [] must be a pointer or array");
			YYERROR;
		    } else {
			ExprStandardCoerce(state, &$3);
			ExprStandardCoerce(state, &$5);
			if ($3.what != TOKEN_LITERAL) {
			    yyerror("first index of array range must be integral");
			    YYERROR;
			}
			if ($5.what != TOKEN_LITERAL) {
			    yyerror("second index of array range must be integral");
			    YYERROR;
			}
			
			switch (Type_Class($1.type)) {
			    default:
			    {
				/*
				 * Make life a bit easier by coercing the thing
				 * to an array of infinite size.
				 */
				unsigned	  	bound;
				
				bound = (1<<(Type_Sizeof(type_Int)*8-1))-1;
				$1.type =
				    Type_CreateArray(0, bound, type_Int,
						     $1.type);
				/*FALLTHRU*/
			    }
			    case TYPE_ARRAY:
			    case TYPE_POINTER:
				if (!ExprArithOrPointerOp(state, '+', &$1, &$3,
							  &$$))
				{
				    YYERROR;
				}
				
				/*
				 * Now convert the thing back into an array
				 * starting at the address of the first element.
				 */
				if ($$.what == TOKEN_POINTER &&
					   Type_Class($1.type) == TYPE_POINTER)
				{
				    if (!ExprIndirect(state, &$1, &$$)) {
					YYERROR;
				    }
				}
				if ($$.what == TOKEN_ADDRESS) {
				    $$.type =
					Type_CreateArray(0,
							 ($5.value.literal-
							  $3.value.literal),
							 type_Int,
							 $$.type);
				} else {
				    xyyerror(state, "expression cannot be converted to an array");
				    YYERROR;
				}
				break;
			}
		    }
		}
		;
struct.op	: '.' | PTR_OP ;
expr		: expr struct.op
		{
		    int	  	offset;
		    int		length;
		    Type	type;

		    if (strcmp($2.value.str, "handle") == 0) {
			offset = 16;
			length = 16;
			type = Type_CreatePointer(type_Void,
						  TYPE_PTR_HANDLE);
		    } else if (strcmp($2.value.str, "segment") == 0) {
			offset = 16;
			length = 16;
			type = Type_CreatePointer(type_Void,
						  TYPE_PTR_SEG);
		    } else if (strcmp($2.value.str, "offset") == 0) {
			offset = 0;
			length = 16;
			type = type_Word;
		    } else if (strcmp($2.value.str, "chunk") == 0) {
			offset = 0;
			length = 16;
			type = Type_CreatePointer(type_Void,
						  TYPE_PTR_LMEM);
		    } else if (strcmp($2.value.str, "low") == 0) {
			offset = 0;
			if (Type_IsNull($1.type) ||
			    Type_Sizeof($1.type) == 4)
			{
			    length = 16;
			    type = type_Word;
			} else {
			    length = 8;
			    type = type_Byte;
			}
		    } else if (strcmp($2.value.str, "high") == 0) {
			if (Type_IsNull($1.type) ||
			    Type_Sizeof($1.type) == 4)
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
			switch(Type_Class($1.type)) {
			    case TYPE_POINTER:
			    {
				Type    baseType;
				
				Type_GetPointerData($1.type, (int *)NULL,
						    &baseType);
				
				switch(Type_Class(baseType)){
				    case TYPE_STRUCT:
				    case TYPE_UNION:
					ExprIndirect(state, &$1, &$1);
					break;
				    default:
					goto try_for_field_sym;
				}
				/*FALLTHRU*/
			    }
			    case TYPE_STRUCT:
			    case TYPE_UNION:
				if (Type_GetFieldData($1.type,
						      $2.value.str,
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
						   $2.value.str);
				if (Sym_IsNull(sym)) {
				    xyyerror(state, "Field %s undefined",
					     $2.value.str);
				    free((malloc_t)$2.value.str);
				    YYERROR;
				} else if (!(Sym_Class(sym) & SYM_FIELD)) {
				    xyyerror(state,
					     "%s not a structure/union field",
					     $2.value.str);
				    free((malloc_t)$2.value.str);
				    YYERROR;
				} else {
				    Sym_GetFieldData(sym, &offset, &length,
						     &type, (Type *)NULL);
				}
				break;
			    }
			}
		    }

		    if (Type_IsRecord($1.type)) {
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

			Type_GetFieldData($1.type,
					  $2.value.str,
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
		    if ($1.what == TOKEN_ADDRESS) {
			/*
			 * The result is $1 after offseting by the byte offset
			 * that corresponds to the bit offset. 
			 */
			$$ = $1;
			$$.value.addr.offset += offset/8;
			$$.type = type;
			$$.flags = 0;
		    } else if ($1.what == TOKEN_POINTER) {
			switch(Type_Class($1.type)) {
			    case TYPE_POINTER:
			    {
				GeosAddr    *gap = $1.value.ptr;

				$$.what = TOKEN_ADDRESS;
				$$.value.addr.handle = gap->handle;
				$$.value.addr.offset =
				    gap->offset + offset/8;
				break;
			    }
			    case TYPE_STRUCT:
				$$.what = TOKEN_POINTER;
				$$.value.ptr = (Opaque)
				    ((genptr)$1.value.ptr + offset/8);
				break;
			    case TYPE_UNION:
				$$.what = TOKEN_POINTER;
				$$.value.ptr = (Opaque)
				    ((genptr)$1.value.ptr + offset/8);
				if ((Type_Class(type) != TYPE_UNION) &&
				    swap)
				{
				    /*
				     * If was a union and now is a non-union,
				     * byte-swap data as necessary.
				     */
				    Var_SwapValue(VAR_FETCH, type,
						  Type_Sizeof(type),
						  $$.value.ptr);
				}
				break;
			    default:
				xyyerror(state,
					 "expression is not a structure or union");
				free((malloc_t)$2.value.str);
				YYERROR;
			}
			$$.type = type;
			$$.flags = 0;
		    } else if ($1.what == TOKEN_LITERAL) {
			/*
			 * To support ds:si.foo, pretend a literal is
			 * actually an address...
			 */
			$$.what = TOKEN_ADDRESS;
			$$.flags = 0;
			$$.value.addr.handle = NullHandle;
			$$.value.addr.offset = (Address)
			    ($1.value.literal + offset/8);
			$$.type = type;
		    } else {
			assert(0);
		    }
		    free((malloc_t)$2.value.str);
		}
		;

expr 		: '&' expr %prec UNARY
		{
		    if ($2.what != TOKEN_ADDRESS) {
			yyerror("inappropriate operand of &");
			YYERROR;
		    } else {
			ExprSetAsPointer(state, &$$,
					 TYPE_PTR_FAR,
					 $2.type,
					 $2.value.addr.handle,
					 $2.value.addr.offset);
		    }
		}
		| '*' expr %prec UNARY
		{
		    ExprIndirect(state, &$2, &$$);
		}
		| '+' expr %prec UNARY
		{
		    ExprFetch(state, &$2);
		    if (!ExprCoerce(state, &$2, (ExprToken *)NULL, TRUE)) {
			yyerror("operand of unary + not arithmetic");
			YYERROR;
		    } else {
			$$ = $2;
		    }
		}
		| '-' expr %prec UNARY
		{
		    ExprToken  zero;
		    
		    zero.what = TOKEN_LITERAL;
		    zero.value.literal = 0;
		    zero.flags = 0;
		    zero.type = type_Int;
		    
		    if (!ExprArithOp(state, '-', &zero, &$2, &$$)) {
			YYERROR;
		    }
		}
		| '~' expr
		{
		    ExprFetch(state, &$2);
		    
		    if (!ExprCoerce(state, &$2, (ExprToken *)NULL, FALSE)) {
			yyerror("operand of ~ must be integral");
			YYERROR;
		    } else if ($2.what == TOKEN_LITERAL) {
			$$ = $2;
			$$.value.literal = ~$$.value.literal;
		    } else {
			yyerror("invalid operand of ~");
			YYERROR;
		    }
		}
		| '!' expr
		{
		    $$.what = TOKEN_LITERAL;
		    $$.type = type_Int;
		    $$.flags = 0;
		    $$.value.literal = ExprEvalBoolean(state, &$2);
		    if ($$.value.literal == -1) {
			yyerror("operand of ! must be arithmetic");
		    } else {
			$$.value.literal = !$$.value.literal;
		    }
		}
		| sizeof expr %prec ')'
		{
		    $$.what = TOKEN_LITERAL;
		    $$.value.literal = Type_Sizeof($2.type);
		    $$.type = type_Int;
		    $$.flags = 0;
		    ExprSidePop(state);
		}
		| sizeof '(' type.name ')'
		{
		    $$.what = TOKEN_LITERAL;
		    $$.value.literal = Type_Sizeof($3);
		    $$.type = type_Int;
		    $$.flags = 0;
		    ExprSidePop(state);
		}
		| LHANDLE expr
		{
		    ExprStandardCoerce(state, &$2);
		    if ($2.what != TOKEN_LITERAL) {
			yyerror("operand of ^l must be an integer");
			YYERROR;
		    } else {
			$$.what = TOKEN_ADDRESS;
			$$.value.addr.handle = Handle_Lookup((unsigned short)$2.value.literal);
			$$.value.addr.offset = 0;
			$$.type = NullType;
			$$.flags = ETF_LMEM_INDIR_PENDING;
		    }
		}
		| VHANDLE expr
		{
		    /*
		     * VMem handle -- segment is actually a VM file handle ID.
		     * Offset will be a VM block, but that's taken care of
		     * by expr ':' expr
		     */

		    ExprStandardCoerce(state, &$2);
		    if ($2.what != TOKEN_LITERAL) {
			yyerror("operand of ^v must be an integer");
			YYERROR;
		    } else {
			if (ExprIndirectVMPart1(state,
						$2.value.literal,
						&$$.value.addr))
			{
			    $$.what = TOKEN_ADDRESS;
			    $$.type = NullType;
			    $$.flags = ETF_VMEM_INDIR_PENDING;
			} else {
			    YYERROR;
			}
		    }
		}
		;

sizeof		: SIZEOF
		{
		    ExprSidePush(TRUE, state);
		}
		;

expr 		: '(' type.name ')' expr %prec UNARY
		{
		    /*
		     * We're gonna need the value, at least we need to correct
		     * for the types of functions and arrays...
		     */
		    if (!ExprCast(state, &$4, $2, &$$, FALSE)) {
			YYERROR;
		    }
		}
		| expr '*' expr
		{
		    if (!ExprArithOp(state, '*', &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
		| expr '/' expr
		{
		    if (!ExprArithOp(state, '/', &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
		| expr '%' expr
		{
		    if (!ExprIntOp(state, '%', &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
 		| expr '+' expr
		{
		    if (!ExprArithOrPointerOp(state, '+', &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
		| expr '-' expr
		{
		    if (!ExprArithOrPointerOp(state, '-', &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
 		| expr LEFT_OP expr
		{
		    if (!ExprIntOp(state, LEFT_OP, &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
		| expr RIGHT_OP expr
		{
		    if (!ExprIntOp(state, RIGHT_OP, &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
 		| expr '<' expr
		{
		    if (!ExprRelOp(state, '<', &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
		| expr '>' expr
		{
		    if (!ExprRelOp(state, '>', &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
		| expr LE_OP expr
		{
		    if (!ExprRelOp(state, LE_OP, &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
		| expr GE_OP expr
		{
		    if (!ExprRelOp(state, GE_OP, &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
 		| expr EQ_OP expr
		{
		    if (!ExprRelOp(state, EQ_OP, &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
		| expr NE_OP expr
		{
		    if (!ExprRelOp(state, NE_OP, &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
 		| expr '&' expr
		{
		    if (!ExprIntOp(state, '&', &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
		| expr '^' expr
		{
		    if (!ExprIntOp(state, '^', &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
		| expr '|' expr
		{
		    if (!ExprIntOp(state, '|', &$1, &$3, &$$)) {
			YYERROR;
		    }
		}
		| expr AND_OP
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
			
			val = ExprEvalBoolean(state, &$1);
			if (val < 0) {
			    YYERROR;
			} else {
			    newSideEffects = !val;
			}
			$<op>$ = newSideEffects;
			ExprSidePush(newSideEffects, state);
		    } else {
			$<op>$ = 0;
		    }
		}
		  expr
		{
		    $$.what = TOKEN_LITERAL;
		    if ($<op>3) {
			ExprSidePop(state);
			$$.value.literal = 0;
		    } else if (!state->noSideEffects) {
			int	val;
			
			val = ExprEvalBoolean(state, &$4);
			if (val < 0) {
			    YYERROR;
			} else {
			    $$.value.literal = val;
			}
		    }
		    $$.type = type_Int;
		    $$.flags = 0;
		}
 		| expr OR_OP
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
			
			val = ExprEvalBoolean(state, &$1);
			if (val < 0) {
			    YYERROR;
			} else {
			    newSideEffects = val;
			}
			$<op>$ = newSideEffects;
			ExprSidePush(newSideEffects, state);
		    } else {
			$<op>$ = 0;
		    }
		}
		  expr
		{
		    $$.what = TOKEN_LITERAL;
		    if ($<op>3) {
			ExprSidePop(state);
			$$.value.literal = 1;
		    } else if (!state->noSideEffects) {
			int	val;
			
			val = ExprEvalBoolean(state, &$4);
			if (val < 0) {
			    YYERROR;
			} else {
			    $$.value.literal = val;
			}
		    }
		    $$.type = type_Int;
		    $$.flags = 0;
		}
		| expr ':' expr
		{
		    Handle	handle;
		    Address 	offset;

		    ExprFetch(state, &$1);
		    ExprFetch(state, &$3);
		    
		    /*
		     * Cope with fetched pointer values by indirecting
		     * through them. This reduces the cases with which we
		     * have to deal, converting the darn things to
		     * TOKEN_ADDRESS tokens.
		     */
		    if (($1.what == TOKEN_POINTER) &&
			(Type_Class($1.type) == TYPE_POINTER))
		    {
			ExprIndirect(state, &$1, &$1);
		    }
		    
		    if (($3.what == TOKEN_POINTER) &&
			(Type_Class($3.type) == TYPE_POINTER))
		    {
			ExprIndirect(state, &$3, &$3);
		    }
		    
		    /*
		     * Find the right handle.
		     */
		    if (($1.what == TOKEN_ADDRESS) &&
			($1.value.addr.handle != NullHandle) &&
			!($1.flags & ETF_HANDLE_FROM_INDIR))
		    {
			/*
			 * Handle is real (not just carried along from an
			 * indirection)
			 */
			handle = $1.value.addr.handle;

			/*
			 * Deal with special indirections (lmem & vmem)
			 */
			if ($1.flags & ETF_LMEM_INDIR_PENDING) {
			    /*
			     * Perform LMem indirection, using $3.offset as
			     * a chunk handle.
			     */
			    word    w;	    /* value in chunk handle */

			    ExprStandardCoerce(state, &$3);

			    if ($3.what == TOKEN_ADDRESS) {
				Var_FetchInt(2, $1.value.addr.handle,
					     $3.value.addr.offset,
					     (genptr)&w);
				$$.type = $3.type;
			    } else if ($3.what == TOKEN_LITERAL) {
				Var_FetchInt(2, $1.value.addr.handle,
					     (Address)$3.value.literal,
					     (genptr)&w);
				$$.type = NullType;
			    } else {
				YYERROR;
			    }
			    offset = (Address)w;
			} else if ($1.flags & ETF_VMEM_INDIR_PENDING) {
			    /*
			     * Perform VMem indirection, using $3.offset as
			     * a VM block handle.
			     */
			    word    block;

			    ExprStandardCoerce(state, &$3);
			    /*
			     * Now extract the memory handle from
			     * header:offset, which is where the thing is
			     * stored in an in-use VM block handle.
			     * XXX: Make sure block is in-use
			     */
			    
			    if ($3.what == TOKEN_ADDRESS) {
				block = (word)$3.value.addr.offset;
				$$.type = $3.type;
			    } else if ($3.what == TOKEN_LITERAL) {
				block = $3.value.literal;
				$$.type = NullType;
			    } else {
				YYERROR;
			    }

			    if (ExprIndirectVMPart2(state,
						    $1.value.addr.handle,
						    block,
						    &$$.value.addr))
			    {
				$$.flags = 0;
				handle = $$.value.addr.handle;
				offset = $$.value.addr.offset;
			    } else {
				YYERROR;
			    }
			} else if ($3.what == TOKEN_ADDRESS) {
			    offset = $3.value.addr.offset;
			    $$.type = $3.type;
			} else if ($3.what == TOKEN_LITERAL) {
			    offset = (Address)$3.value.literal;
			    $$.type = NullType;
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
			
			if ($1.what == TOKEN_ADDRESS) {
			    segment = (word)$1.value.addr.offset;
			} else if ($1.what == TOKEN_LITERAL) {
			    segment = (word)$1.value.literal;
			} else {
			    YYERROR;
			}
			if ($3.what == TOKEN_ADDRESS) {
			    handle = Handle_Find(MakeAddress(segment,
						 $3.value.addr.offset));
			    $$.type = $3.type;
			} else if ($3.what == TOKEN_LITERAL) {
			    handle = Handle_Find(MakeAddress(segment,
						 $3.value.literal));
			    $$.type = NullType;
			} else {
			    YYERROR;
			}

			if (handle == NullHandle) {
			    /*
			     * No handle covering it -- make it absolute
			     */
			    handle = NullHandle;
			    if ($3.what == TOKEN_ADDRESS) {
				offset = MakeAddress(segment, $3.value.addr.offset);
			    } else {
				offset = MakeAddress(segment, $3.value.literal);
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
			    if ($3.what == TOKEN_ADDRESS) {
				off = (dword)$3.value.addr.offset;
			    } else if ($3.what == TOKEN_LITERAL) {
				off = $3.value.literal;
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
			    if ($3.what == TOKEN_ADDRESS) {
				offset = $3.value.addr.offset;
			    } else if ($3.what == TOKEN_LITERAL) {
				offset = (Address)$3.value.literal;
			    } else {
				YYERROR;
			    }
			}
		    }
		    /*
		     * This used to make it a TOKEN_POINTER if the type was
		     * non-null, but I can't see why...
		     */
		    $$.what = TOKEN_ADDRESS;
		    $$.value.addr.handle = handle;
		    $$.value.addr.offset = offset;
		    $$.flags = 0;
		}
		;

type.modifier 	: CHAR	  	    { $$ = TYPE_MOD_CHAR; }
		| SHORT		    { $$ = TYPE_MOD_SHORT; }
		| INT		    { $$ = TYPE_MOD_INT; }
		| LONG		    { $$ = TYPE_MOD_LONG; }
		| SIGNED	    { $$ = TYPE_MOD_SIGNED; }
		| FLOAT		    { $$ = TYPE_MOD_FLOAT; }
		| DOUBLE	    { $$ = TYPE_MOD_DOUBLE; }
		| UNSIGNED	    { $$ = TYPE_MOD_UNSIGNED; }
		| VOID		    { $$ = TYPE_MOD_VOID; }
		| CONST		    { $$ = TYPE_MOD_CONST; }
		| VOLATILE	    { $$ = TYPE_MOD_VOLATILE; }
		| WORD	    	    { $$ = TYPE_MOD_SHORT|TYPE_MOD_UNSIGNED; }
		| BYTE	    	    { $$ = TYPE_MOD_CHAR|TYPE_MOD_UNSIGNED; }
		| DWORD	    	    { $$ = TYPE_MOD_LONG|TYPE_MOD_UNSIGNED; }
		| SWORD	    	    { $$ = TYPE_MOD_SHORT; }
		| SBYTE	    	    { $$ = TYPE_MOD_CHAR; }
		| SDWORD    	    { $$ = TYPE_MOD_LONG; }
		;

type.modifier.list: type.modifier
		| type.modifier.list type.modifier
		{
		    $$ = $1 | $2;
		}
		;

/*
 * Type specification. We have to use some gross intermediate actions to
 * make sure we can always refer to $-1 in abstract.declarator and get the
 * type we're building.
 */
type.name 	: type.specifier abstract.declarator
		{
		    $$ = $2;
		}
		;

type.specifier : type.modifier.list
		{
		    switch ($1 & ~(TYPE_MOD_VOLATILE|TYPE_MOD_CONST|
				   TYPE_MOD_UNSIGNED|TYPE_MOD_SIGNED))
		    {
			case TYPE_MOD_SHORT:
			case TYPE_MOD_SHORT|TYPE_MOD_INT:
			    if ($1 & TYPE_MOD_UNSIGNED) {
				$$ = type_UnsignedShort;
			    } else {
				$$ = type_Short;
			    }
			    break;
			case TYPE_MOD_LONG:
			case TYPE_MOD_LONG|TYPE_MOD_INT:
			    if ($1 & TYPE_MOD_UNSIGNED) {
				$$ = type_UnsignedLong;
			    } else {
				$$ = type_Long;
			    }
			    break;
			case 0:
			case TYPE_MOD_INT:
			    if ($1 & TYPE_MOD_UNSIGNED) {
				$$ = type_UnsignedInt;
			    } else {
				$$ = type_Int;
			    }
			    break;
		        case TYPE_MOD_LONG|TYPE_MOD_DOUBLE:
			    if ($1 & (TYPE_MOD_UNSIGNED|TYPE_MOD_SIGNED)) {
				yyerror("invalid type combination");
				YYERROR;
			    } else {
				$$ = type_LongDouble;
			    }
			    break;
			case TYPE_MOD_LONG|TYPE_MOD_FLOAT:
			case TYPE_MOD_DOUBLE:
			    if ($1 & (TYPE_MOD_UNSIGNED|TYPE_MOD_SIGNED)) {
				yyerror("invalid type combination");
				YYERROR;
			    } else {
				$$ = type_Double;
			    }
			    break;
			case TYPE_MOD_FLOAT:
			    if ($1 & (TYPE_MOD_UNSIGNED|TYPE_MOD_SIGNED)) {
				yyerror("invalid type combination");
				YYERROR;
			    } else {
				$$ = type_Float;
			    }
			    break;
			case TYPE_MOD_CHAR:
			    if ($1 & TYPE_MOD_UNSIGNED) {
				$$ = type_Byte;
			    } else {
				$$ = type_Char;
			    }
			    break;
			case TYPE_MOD_VOID:
			    if (($1 & ~TYPE_MOD_VOID) == 0) {
				$$ = type_Void;
				break;
			    }
			    /*FALLTHRU*/
			default:
			    yyerror("illegal type combination");
			    YYERROR;
		    }
		}
		| TYPE
		| LPTR 
		{
		    $$ = Type_CreatePointer(type_Void, TYPE_PTR_LMEM);
		}
		| FPTR 
		{
		    $$ = Type_CreatePointer(type_Void, TYPE_PTR_FAR);
		}
		| NPTR 
		{
		    $$ = Type_CreatePointer(type_Void, TYPE_PTR_NEAR);
		}
		| SPTR 
		{
		    $$ = Type_CreatePointer(type_Void, TYPE_PTR_SEG);
		}
		| OPTR 
		{
		    $$ = Type_CreatePointer(type_Void, TYPE_PTR_OBJECT);
		}
		| HPTR 
		{
		    $$ = Type_CreatePointer(type_Void, TYPE_PTR_HANDLE);
		}
		| VPTR
		{
		    $$ = Type_CreatePointer(type_Void, TYPE_PTR_VM);
		}
		| VFPTR
		{
		    $$ = Type_CreatePointer(type_Void, TYPE_PTR_VIRTUAL);
		}
		;

abstract.declarator : /* empty */
		{
		    $$ = $<type>0;
		}
		| abstract.declarator2
		;

/*
 * ptr.decl is used only at the left of abstract.declarator2, which is defined
 * as having $0 be the Type for the base type of the pointer/array/etc.
 */
ptr.decl	: '*'
		{
		    $$ = Type_CreatePointer($<type>0, TYPE_PTR_FAR);
		}
		| DA_LMEM '*' 
		{
		    $$ = Type_CreatePointer($<type>0, TYPE_PTR_LMEM);
		}
		| DA_FAR '*' 
		{
		    $$ = Type_CreatePointer($<type>0, TYPE_PTR_FAR);
		}
		| DA_NEAR '*' 
		{
		    $$ = Type_CreatePointer($<type>0, TYPE_PTR_NEAR);
		}
		| DA_SEG '*' 
		{
		    $$ = Type_CreatePointer($<type>0, TYPE_PTR_SEG);
		}
		| DA_OBJECT '*' 
		{
		    $$ = Type_CreatePointer($<type>0, TYPE_PTR_OBJECT);
		}
		| DA_HANDLE '*' 
		{
		    $$ = Type_CreatePointer($<type>0, TYPE_PTR_HANDLE);
		}
		| DA_VIRTUAL '*'
		{
		    $$ = Type_CreatePointer($<type>0, TYPE_PTR_VIRTUAL);
		}
		| DA_VM '*'
		{
		    $$ = Type_CreatePointer($<type>0, TYPE_PTR_VM);
		}
		;
open.paren	: '(' { $<type>$ = $<type>0; } ;

abstract.declarator2 : open.paren abstract.declarator2 ')'
		{
		    $$ = $2;
		}
		| ptr.decl abstract.declarator2		%prec NOT_QUITE_UNARY
		{
		    $$ = $2;
		}
		| ptr.decl				%prec NOT_QUITE_UNARY
		| abstract.declarator2 open.paren ')'	%prec UNARY
		{
		    switch (Type_Class($1)) {
			case TYPE_POINTER:
			{
			    Type	baseType;
			    int 	ptrType;
			
			    Type_GetPointerData($1, &ptrType, &baseType);
			    $$ = Type_CreatePointer(Type_CreateFunction(baseType),
						    ptrType);
			    break;
			}
			case TYPE_ARRAY:
			{
			    Type    	baseType;
			    Type    	indexType;
			    int	    	min, max;

			    Type_GetArrayData($1, &min, &max, &indexType,
					      &baseType);
			    $$ = Type_CreateArray(min, max, indexType,
						  Type_CreateFunction(baseType));
			    break;
			}
			default:
			    yyerror("cannot cast to a function");
			    YYERROR;
		    }
		}
		| open.paren ')'			%prec UNARY
		{
		    switch (Type_Class($<type>0)) {
			case TYPE_POINTER:
			{
			    Type	baseType;
			    int 	ptrType;
			
			    Type_GetPointerData($<type>0, &ptrType, &baseType);
			    $$ = Type_CreatePointer(Type_CreateFunction(baseType),
						    ptrType);
			    break;
			}
			case TYPE_ARRAY:
			{
			    Type    	baseType;
			    Type    	indexType;
			    int	    	min, max;

			    Type_GetArrayData($<type>0, &min, &max, &indexType,
					      &baseType);
			    $$ = Type_CreateArray(min, max, indexType,
						  Type_CreateFunction(baseType));
			    break;
			}
			default:
			    yyerror("cannot cast to a function");
			    YYERROR;
		    }
		}
		| abstract.declarator2 '[' ']'			%prec '.'
		{
		    unsigned	  	bound;
		    
		    bound = (1 << (Type_Sizeof(type_Int) * 8 - 1)) - 1;
		    $$ = Type_CreateArray(0, bound, type_Int, $1);
		}
		| abstract.declarator2 '[' expr ']'	%prec '.'
		{
		    if (!ExprCoerce(state, &$3, (ExprToken *)NULL, FALSE)) {
			YYERROR;
		    } else if ($3.what == TOKEN_LITERAL) {
			$$ = Type_CreateArray(0, $3.value.literal-1,
					      type_Int, $1);
		    } else {
			yyerror("array dimension must be integral");
		    }
		}
		| '[' ']'					%prec '.'
		{
		    unsigned	  	bound;
		    
		    /*
		     * Figure max unsigned int and use as upper bound for array.
		     */
		    bound = (1 << (Type_Sizeof(type_Int) * 8 - 1)) - 1;
		    $$ = Type_CreateArray(0, bound, type_Int, $<type>0);
		}
		| '[' expr ']'				%prec '.'
		{
		    if (!ExprCoerce(state, &$2, (ExprToken *)NULL, FALSE)) {
			YYERROR;
		    } else if ($2.what == TOKEN_LITERAL) {
			$$ = Type_CreateArray(0, $2.value.literal-1, type_Int,
					      $<type>0);
		    } else {
			yyerror("array dimension must be integral");
		    }
		}
		;

%%


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

