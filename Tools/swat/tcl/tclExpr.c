/* 
 * tclExpr.c --
 *
 *	This file contains the code to evaluate expressions for
 *	Tcl.
 *
 * Copyright 1987 Regents of the University of California
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies.  The University of California
 * makes no representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 */

#ifndef lint
static char *rcsid = "$Id: tclExpr.c,v 1.26 97/04/18 12:23:39 dbaumann Exp $ SPRITE (Berkeley)";
#endif not lint

#include <config.h>
#include <compat/string.h>
#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <stdarg.h>
#include "tcl.h"
#include "tclInt.h"
#include <malloc.h>

/* 
 * strtod.c --
 *
 *	Source code for the "strtod" library procedure. Here b/c sun's
 *	strtod doesn't return the end pointer pointing at the char that
 *	stopped the scan, but the char after the char that stopped the
 *	scan.
 *
 * Copyright 1988 Regents of the University of California
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies.  The University of California
 * makes no representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 */

#ifndef TRUE
#define TRUE 1
#define FALSE 0
#endif
#ifndef NULL
#define NULL 0
#endif

static int maxExponent = 511;	/* Largest possible base 10 exponent.  Any
				 * exponent larger than this will already
				 * produce underflow or overflow, so there's
				 * no need to worry about additional digits.
				 */
static double powersOf10[] = {	/* Table giving binary powers of 10.  Entry */
    10.,			/* is 10^2^i.  Used to convert decimal */
    100.,			/* exponents into floating-point numbers. */
    1.0e4,
    1.0e8,
    1.0e16,
    1.0e32,
    1.0e64,
    1.0e128,
    1.0e256
};

/*
 *----------------------------------------------------------------------
 *
 * strtod --
 *
 *	This procedure converts a floating-point number from an ASCII
 *	decimal representation to internal double-precision format.
 *
 * Results:
 *	The return value is the double-precision floating-point
 *	representation of the characters in string.  If endPtr isn't
 *	NULL, then *endPtr is filled in with the address of the
 *	next character after the last one that was part of the
 *	floating-point number.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

double
strtod(const char *string,	/* A decimal ASCII floating-point number,
				 * optionally preceded by white space.
				 * Must have form "-I.FE-X", where I is the
				 * integer part of the mantissa, F is the
				 * fractional part of the mantissa, and X
				 * is the exponent.  Either of the signs
				 * may be "+", "-", or omitted.  Either I
				 * or F may be omitted, or both.  The decimal
				 * point isn't necessary unless F is present.
				 * The "E" may actually be an "e".  E and X
				 * may both be omitted (but not just one).
				 */
       const char **endPtr)	/* If non-NULL, store terminating character's
				 * address here. */
{
    int sign, expSign = FALSE;
    double fraction, dblExp, *d;
    register const char *p;
    register char c;
    int exp = 0;		/* Exponent read from "EX" field. */
    int fracExp = 0;		/* Exponent that derives from the fractional
				 * part.  Under normal circumstatnces, it is
				 * the negative of the number of digits in F.
				 * However, if I is very long, the last digits
				 * of I get dropped (otherwise a long I with a
				 * large negative exponent could cause an
				 * unnecessary overflow on I alone).  In this
				 * case, fracExp is incremented one for each
				 * dropped digit.
				 */
    int mantSize;		/* Number of digits in mantissa. */
    int decPt;			/* Number of mantissa digits BEFORE decimal
				 * point.
				 */
    const char *pExp;		/* Temporarily holds location of exponent
				 * in string.
				 */

    /*
     * Strip off leading blanks and check for a sign.
     */

    p = string;
    while (isspace(*p)) {
	p += 1;
    }
    if (*p == '-') {
	sign = TRUE;
	p += 1;
    } else {
	if (*p == '+') {
	    p += 1;
	}
	sign = FALSE;
    }

    /*
     * Count the number of digits in the mantissa (including the decimal
     * point), and also locate the decimal point.
     */

    decPt = -1;
    for (mantSize = 0; ; mantSize += 1)
    {
	c = *p;
	if (!isdigit(c)) {
	    if ((c != '.') || (decPt >= 0)) {
		break;
	    }
	    decPt = mantSize;
	}
	p += 1;
    }

    /*
     * Now suck up the digits in the mantissa.  Use two integers to
     * collect 9 digits each (this is faster than using floating-point).
     * If the mantissa has more than 18 digits, ignore the extras, since
     * they can't affect the value anyway.
     */
    
    pExp  = p;
    p -= mantSize;
    if (decPt < 0) {
	decPt = mantSize;
    } else {
	mantSize -= 1;			/* One of the digits was the point. */
    }
    if (mantSize > 18) {
	fracExp = decPt - 18;
	mantSize = 18;
    } else {
	fracExp = decPt - mantSize;
    }
    if (mantSize == 0) {
	fraction = 0.0;
	p = string;
	goto done;
    } else {
	int frac1, frac2;
	frac1 = 0;
	for ( ; mantSize > 9; mantSize -= 1)
	{
	    c = *p;
	    p += 1;
	    if (c == '.') {
		c = *p;
		p += 1;
	    }
	    frac1 = 10*frac1 + (c - '0');
	}
	frac2 = 0;
	for (; mantSize > 0; mantSize -= 1)
	{
	    c = *p;
	    p += 1;
	    if (c == '.') {
		c = *p;
		p += 1;
	    }
	    frac2 = 10*frac2 + (c - '0');
	}
	fraction = (1.0e9 * frac1) + frac2;
    }

    /*
     * Skim off the exponent.
     */

    p = pExp;
    if ((*p == 'E') || (*p == 'e')) {
	p += 1;
	if (*p == '-') {
	    expSign = TRUE;
	    p += 1;
	} else {
	    if (*p == '+') {
		p += 1;
	    }
	    expSign = FALSE;
	}
	while (isdigit(*p)) {
	    exp = exp * 10 + (*p - '0');
	    p += 1;
	}
    }
    if (expSign) {
	exp = fracExp - exp;
    } else {
	exp = fracExp + exp;
    }

    /*
     * Generate a floating-point number that represents the exponent.
     * Do this by processing the exponent one bit at a time to combine
     * many powers of 2 of 10. Then combine the exponent with the
     * fraction.
     */
    
    if (exp < 0) {
	expSign = TRUE;
	exp = -exp;
    } else {
	expSign = FALSE;
    }
    if (exp > maxExponent) {
	exp = maxExponent;
    }
    dblExp = 1.0;
    for (d = powersOf10; exp != 0; exp >>= 1, d += 1) {
	if (exp & 01) {
	    dblExp *= *d;
	}
    }
    if (expSign) {
	fraction /= dblExp;
    } else {
	fraction *= dblExp;
    }

done:
    if (endPtr != NULL) {
	*endPtr = p;
    }

    if (sign) {
	return -fraction;
    }
    return fraction;
}

typedef enum {
    TENT_NUMBER,
    TENT_FLOAT,
    TENT_STRING,
    TENT_CODE,
    TENT_OP,
    TENT_VAR
} TclExprNodeType;

typedef struct _TclExprNode {
    TclExprNodeType type;
    union {
	long        	    	number;
	double      	    	fnumber;
	const char      	*string;
	struct {
	    const unsigned char	    *code;
	    unsigned long   	    size;
	}   	    	    	code;
	unsigned    	    	op;
	const char  	    	*var;
    }	    	    	    data;
    struct _TclExprNode	*left, *right;
} TclExprNode;

/*
 * The data structure below describes the state of parsing an expression.
 * It's passed among the routines in this module.
 */

typedef struct {
    Tcl_Interp *interp;		/* Intepreter to use for command execution
				 * and variable lookup. */
    const char *originalExpr;	/* The entire expression, as originally
				 * passed to Tcl_Expr. */
    const char *expr;		/* Position to the next character to be
				 * scanned from the expression string. */
    int token;			/* Type of the last token to be parsed from
				 * expr.  See below for definitions.
				 * Corresponds to the characters just
				 * before expr. */
    int doFloat;	    	/* If TRUE, wants a floating-point result */
    int type;	    	    	/* Type of operand stored */
    int number;		    	/* If token is NUMBER and !doFloat, gives value
				 * of the number. */
    double  fnumber;    	/* If token is NUMBER and doFloat, gives value
				 * of the number */
    const char *str;	    	/* If token is STRING, points to the string */
    TBCCData	*dataPtr;   	/* Place to store bytes */
    TclExprNode	*node;	    	/* If compiling, this is the node just parsed */
} ExprInfo;

/*
 * The token types are defined below.  In addition, there is a table
 * associating a precedence with each operator.  The order of types
 * is important.  Consult the code before changing it.
 */

#define NUMBER		0
#define FNUMBER	    	1   	/* Used only when compiling */
#define STRING	    	2
#define OPEN_PAREN	3
#define CLOSE_PAREN	4
#define END		5
#define UNKNOWN		6
#define VARREF 	    	7   	/* Used only when compiling */
#define CODEREF	    	8   	/* Used only when compiling */
/*
 * Binary operators:
 */
#define FIRST_OP    	10

#define POWER	    	10
#define MULT		11
#define DIVIDE		12
#define MOD		13
#define PLUS		14
#define MINUS		15
#define LEFT_SHIFT	16
#define RIGHT_SHIFT	17
#define LESS		18
#define GREATER		19
#define LEQ		20
#define GEQ		21
#define EQUAL		22
#define NEQ		23
#define BIT_AND		24
#define BIT_XOR		25
#define BIT_OR		26
#define AND		27
#define OR		28

/*
 * Unary operators:
 */
#define FIRST_UNARY 	29

#define	UNARY_MINUS	29
#define NOT		30
#define BIT_NOT		31

const struct {
    const char 	*op;
    const char	*token;
} opNames[] = {
    {"**", "POWER"},
    {"*", "MULT"},
    {"/", "DIVIDE"},
    {"%", "MOD"},
    {"+", "PLUS"},
    {"-", "MINUS"},
    {"<<", "LEFT_SHIFT"},
    {">>", "RIGHT_SHIFT"},
    {"<", "LESS"},
    {">", "GREATER"},
    {"<=", "LEQ"},
    {">=", "GEQ"},
    {"=", "EQUAL"},
    {"!=", "NEQ"},
    {"&", "BIT_AND"},
    {"^", "BIT_XOR"},
    {"|", "BIT_OR"},
    {"&&", "AND"},
    {"||", "OR"},
    {"-", "NEG"},
    {"!", "NOT"},
    {"~", "BIT_NOT"}
};

/*
 * Precedence table.  The values for non-operator token types are ignored.
 */

int precTable[] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    11,	    	    	    	    	/* POWER */
    10, 10, 10,				/* MULT, DIVIDE, MOD */
    9, 9,				/* PLUS, MINUS */
    8, 8,				/* LEFT_SHIFT, RIGHT_SHIFT */
    7, 7, 7, 7,				/* LESS, GREATER, LEQ, GEQ */
    6, 6,				/* EQUAL, NEQ */
    5,					/* BIT_AND */
    4,					/* BIT_XOR */
    3,					/* BIT_OR */
    2,					/* AND */
    1,					/* OR */
    12, 12, 12				/* UNARY_MINUS, NOT, BIT_NOT */
};

/*
 * Library imports:
 */


/*
 *----------------------------------------------------------------------
 *
 * TclExprGetNum --
 *
 *	Parse off a number from a string.
 *
 * Results:
 *	The return value is the integer value corresponding to the
 *	leading digits of string.  If termPtr isn't NULL, *termPtr
 *	is filled in with the address of the character after the
 *	last one that is part of the number.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
TclExprGetNum(register const char *string,    /* ASCII representation of 
					       * number. If leading digit is
					       * "0" then read in base 8, if
					       * "0x", then read in base 16.
					       */
	      register const char **termPtr)  /* If non-NULL, fill in with
					       * address of terminating
					       * character. */
{
    /*
     * Constant -- figure out the radix (can be specified either masm's
     * way or C's way) and convert to an integer, returning that
     * integer.
     */
    int		base = 10, baseSet = 0;
    const char 	*start = string, *end = 0;
    char    	c;
    int	    	n, d;
    int	    	negate = 0;

    if (*string == '-') {
	string++;
	negate = 1;
	start++;
    } else if (*string == '+') {
	string++;
	start++;
    }
    
    /*
     * Read in all valid digits (valid == in hex set)
     */
    if (*string == '0') {
	/*
	 * Deal with C syntax first, looking for an x or an X after the
	 * 0. If so, set the base to be 16 and throw away the two
	 * characters. Otherwise, store the 0 at the front of id.
	 */
	c = *++string;
	if ((c == 'x') || (c == 'X')) {
	    baseSet = base = 16;
	    start = ++string;
	}
    }
    
    while (isxdigit(*string)) {
	string++;
    }
    
    /*
     * See if stopped on one of the MASM base identifiers. The ones
     * that aren't valid hex digits are h, q and o. b and d we deal
     * with later.
     */
    if (!baseSet) {
	switch (*string) {
	    case 'h':
	    case 'H':
		baseSet = base = 16;
		end = string+1;
		break;
	    case 'q':
	    case 'Q':
	    case 'o':
	    case 'O':
		baseSet = base = 8;
		end = string+1;
		break;
	}
    }
    
    if (!baseSet && (*start == '0')) {
	/*
	 * If it begins with a 0, and we haven't already decided on a
	 * base, it's base 8.
	 */
	baseSet = base = 8;
	end = string;
    } 
    
    /*
     * If base still isn't set, the terminator wasn't a radix indicator,
     * nor do we have a C-style radix indication. Unfortunately, the
     * radix characters b and d are both valid hex digits. If they
     * come at the end of the scanned number, they are radix
     * characters.
     */
    if (!baseSet) {
	switch (string[-1]) {
	    case 'b':
	    case 'B':
		base = 2;
		/*FALLTHRU*/
	    case 'd':
	    case 'D':
		baseSet = 1;
		end = string--;
		break;
	    default:
		end = string;
		break;
	}
    } else if (end == NULL) {
	end = string;
    }
    
    n = 0;

    /*
     * If only a radix char, signal our displeasure by indicating nothing
     * parsed.
     */
    if (start == string) {
	end = start;
    }
    
    while (start < string) {
	n *= base;
	if (isdigit(*start)) {
	    d = *start++ - '0';
	} else if (*start <= 'F') {
	    d = *start++ - 'A' + 10;
	} else {
	    d = *start++ - 'a' + 10;
	}
	if (d < base) {
	    n += d;
	} else {
	    /*
	     * Number is out of radix, so stop now.
	     */
	    end = start-1;
	    break;
	}
    }

    if (termPtr) {
	*termPtr = end;
    }

    return(negate ? -n: n);
}

/*
 *----------------------------------------------------------------------
 *
 * ExprGetNumber --
 *
 *	Parse off a number from a string.
 *
 * Results:
 *	Places the number in the number union of the current ExprInfo.
 *	If termPtr isn't NULL, *termPtr is filled in with the address of
 *	the character after the last one that is part of the number.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */
static void
ExprGetNumber(register const char *string,
	      ExprInfo	    *infoPtr,
	      register const char **termPtr)
{
    const char	*term;
    
    if (!infoPtr->doFloat ||
	(*string == '0' && (string[1] ==  'x' || string[1] == 'X')))
    {
	infoPtr->number = TclExprGetNum(string, &term);

	/*
	 * If compiling expression that could be either integer or
	 * floating-point, see if terminating character makes the number
	 * look like floating-point and convert stuff accordingly.
	 */
	if (infoPtr->dataPtr) {
	    /*
	     * When compiling, we have to figure out the best way to cope
	     * with the number. We use integer if that's not going to lose
	     * precision, because it's faster and smaller.
	     */
	    const char	*fterm;
	    double  	fnum;

	    fnum = strtod(string, &fterm);

	    if ((term < fterm) ||
		(term == fterm && fnum != (double)infoPtr->number))
	    {
		/*
		 * If consumed more chars as a float, we assume it's because of
		 * decimal stuff or exponents or whatever
		 *
		 *  -OR-
		 *
		 * If integer converted to a double is not the same as the
		 * floating-point version when both used the same number of
		 * characters, then we'll lose precision treating it as an int.
		 */
		term = fterm;
		infoPtr->token = FNUMBER;
		infoPtr->fnumber = fnum;
	    }
	} else if (infoPtr->doFloat) {
	    /*
	     * Hex number, but doing uncompiled floating-point expression, so
	     * convert the thing to a floating-point number.
	     */
	    infoPtr->fnumber = (double)infoPtr->number;
	}
    } else {
	infoPtr->fnumber = strtod(string, &term);
    }

    if (termPtr) {
	*termPtr = term;
    }
}
	

/***********************************************************************
 *				ExprGetNumberOrString
 ***********************************************************************
 * SYNOPSIS:	    Extract a token (presumed to be a number) from the
 *		    passed string. If it's not actually a number,
 *	    	    just save the entire string as a STRING token.
 * CALLED BY:	    (INTERNAL) ExprLex
 * RETURN:	    infoPtr->number, fnumber, or str set
 *	    	    infoPtr->token set (passed as NUMBER)
 * SIDE EFFECTS:    if STRING is returned, and dynamic is non-zero,
 *	    	    the passed str will be stolen.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/16/92	Initial Revision
 *
 ***********************************************************************/
static void
ExprGetNumberOrString(const char *str,	    /* String from which to extract
					     * a token */
		      ExprInfo 	*infoPtr,   /* Place to which to store it.
					     * infoPtr->type = infoPtr->token =
					     * 	NUMBER */
		      int   	dynamic)    /* Non-zero if str is dynamically
					     * allocated and available for
					     * stealing */
{
    const char	*term;

    ExprGetNumber(str, infoPtr, &term);
    
    if ((term == str) || (*term != 0)) {
	/*
	 * The entire thing didn't make up a number, or it was empty.
	 * Convert it to a string, pending appropriate operator.
	 */
	infoPtr->type = infoPtr->token = STRING;
	if (dynamic) {
	    infoPtr->str = str;
	} else {
	    /*
	     * Have to make a copy.
	     */
	    int len = strlen(str);
	    char    *new;
			
	    new = (char *)malloc(len+1);
	    bcopy(str, new, len+1);
	    infoPtr->str = new;
	}
    } else if (dynamic) {
	/*
	 * Not keeping the string, so we need to free it.
	 */
	free((char *)str);
    }
}


/***********************************************************************
 *				TclExprNewNode
 ***********************************************************************
 * SYNOPSIS:	    Create a new node for the expression being compiled.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    pointer to dynamically-allocated node
 * SIDE EFFECTS:    the fields of the node are filled from the passed args
 *
 * STRATEGY:
 *	    allocate enough memory to hold the node plus any extra
 *	    	data the node type requires (TENT_VAR & TENT_STRING
 *	    	both have a null-terminated string)
 *	    copy the extra data after the node, if the node has any
 *	    	extra data.
 *	    fill in the remaining fields from the remaining args:
 *	    	TENT_VAR:   	char *
 *	    	TENT_STRING:	char *
 *	    	TENT_NUMBER:	long
 *	    	TENT_FLOAT: 	double
 *	    	TENT_CODE:  	const unsigned char *, unsigned long
 *	    	TENT_OP:    	unsigned, TclExprNode *left, TclExprNode *right
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/11/94		Initial Revision
 *
 ***********************************************************************/
static TclExprNode *
TclExprNewNode(TclExprNodeType type, ...)
{
    va_list args;
    TclExprNode	*node;

    va_start(args, type);

    /*
     * Allocate a node, including room after the TclExprNode for any
     * variable-sized data (read: string) the node requires.
     *
     * Note that TENT_CODE doesn't need extra room b/c the code is already
     * dynamically allocated and will be freed by this module eventually,
     * in contrast to strings which are on the stack or within the body of the
     * expression itself.
     */
    if (type == TENT_VAR || type == TENT_STRING) {
	const char	*varname;
	int	len;
	char	*newname;

	varname = va_arg(args, const char *);
	len = va_arg(args, int);

	node = (TclExprNode *)malloc(sizeof(TclExprNode) + len + 1);
	newname = (char *)(node+1);
	bcopy(varname, newname, len);
	newname[len] = '\0';
	node->data.var = newname;
    } else {
	node = (TclExprNode *)malloc(sizeof(TclExprNode));
    }

    /*
     * Common initialization.
     */
    node->type = type;
    node->left = node->right = 0;
    
    /*
     * Copy the rest of the arguments into the data union.
     */
    switch(type) {
    case TENT_NUMBER:
	node->data.number = va_arg(args, long);
	break;
    case TENT_FLOAT:
	node->data.fnumber = va_arg(args, double);
	break;
    case TENT_STRING:
    case TENT_VAR:
	break;
    case TENT_CODE:
	node->data.code.code = va_arg(args, const unsigned char *);
	node->data.code.size = va_arg(args, unsigned long);
	break;
    case TENT_OP:
	node->data.op = va_arg(args, unsigned);
	node->left = va_arg(args, TclExprNode *);
	node->right = va_arg(args, TclExprNode *);
	break;
    }
    va_end(args);

    return (node);
}


/*
 *----------------------------------------------------------------------
 *
 * ExprLex --
 *
 *	Lexical analyzer for expression parser.
 *
 * Results:
 *	TCL_OK is returned unless an error occurred while doing lexical
 *	analysis or executing an embedded command.  In that case a
 *	standard Tcl error is returned, using interp->result to hold
 *	an error message.  In the event of a successful return, the token
 *	and (possibly) number fields in infoPtr are updated to refer to
 *	the next symbol in the expression string, and the expr field is
 *	advanced.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
ExprLex(Tcl_Interp	    *interp,	/* Interpreter to use for error
					 * reporting. */
	register ExprInfo   *infoPtr,	/* Describes the state of the parse. */
	int		    noEval)	/* Don't evaluate variables, commands,
					 * etc. b/c we're in a part of a
					 * boolean expression we don't need */
{
    register const char *p;
    register char c;
    const char *var;
    int result;

    /*
     * The next token is either:
     * (a)	a variable name (indicated by a $ sign plus a variable
     *		name in the standard Tcl fashion);  lookup the value
     *		of the variable and return its numeric equivalent as a
     *		number.
     * (b)	an embedded command (anything between '[' and ']').
     *		Execute the command and convert its result to a number.
     * (c)	a series of decimal digits.  Convert it to a number.
     * (d)	space:  skip it.
     * (d)	an operator.  See what kind it is.
     */

    p = infoPtr->expr;
    c = *p;
    while (isspace(c)) {
	p++;  c = *p;
    }
    infoPtr->expr = p+1;
    if (!isascii(c)) {
	infoPtr->token = UNKNOWN;
	return TCL_OK;
    }
    switch (c) {
	case '.':
	    if (!infoPtr->doFloat && !infoPtr->dataPtr) {
		/*
		 * We don't like this if not doing floating point
		 */
		infoPtr->expr = p+1;
		infoPtr->token = UNKNOWN;
		return TCL_OK;
	    }
	    /*FALLTHRU*/
	case '0':
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	case '8':
	case '9':
	    infoPtr->type = infoPtr->token = NUMBER;
	    ExprGetNumber(p, infoPtr, &infoPtr->expr);

	    if (infoPtr->dataPtr) {
		if (infoPtr->token == NUMBER) {
		    infoPtr->node = TclExprNewNode(TENT_NUMBER,
						   infoPtr->number);
		} else {
		    infoPtr->node = TclExprNewNode(TENT_FLOAT,
						   infoPtr->fnumber);
		}
	    }
	    return TCL_OK;

	case '$':
	    infoPtr->type = infoPtr->token = NUMBER;
	    if (infoPtr->dataPtr) {
		int len;
		
		var = TclProcScanVar(interp, p, &len, &infoPtr->expr);
		infoPtr->node = TclExprNewNode(TENT_VAR, var, len);
	    } else {
		var = Tcl_ParseVar(infoPtr->interp, p, &infoPtr->expr);
		if (!noEval) {
		    ExprGetNumberOrString(var, infoPtr, 0);
		}
	    }
	    return TCL_OK;

	case '[':
	    infoPtr->type = infoPtr->token = NUMBER;
	    if (infoPtr->dataPtr) {
		unsigned char	*code;
		unsigned long	size;

		code = TclByteCodeCompileTop(interp, p+1, ']', 0,
					     infoPtr->dataPtr->strings,
					     &infoPtr->expr,
					     &size);

		if (code == 0) {
		    return TCL_ERROR;
		}
		
		infoPtr->node = TclExprNewNode(TENT_CODE, code, size);
		infoPtr->expr++;
	    } else if (!noEval) {
		result = Tcl_Eval(infoPtr->interp, p+1, ']', &infoPtr->expr);
		if (result != TCL_OK) {
		    return result;
		}
		ExprGetNumberOrString(interp->result, infoPtr, interp->dynamic);
		interp->dynamic = 0;
		infoPtr->expr++;
	    } else {
		int braces, brackets;
		int startline;

		startline = 0;

		for (braces = 0, brackets = 1; brackets > 0; infoPtr->expr++)
		{
		    switch (*infoPtr->expr) {
			case ']':
			    if (!braces) {
				brackets--;
			    }
			    break;
			case '[':
			    if (!braces) {
				brackets++;
			    }
			    break;
			case '{':
			    braces++;
			    break;
			case '}':
			    if (braces-- == 0) {
				Tcl_Return(interp, "Unbalanced close brace",
					    TCL_STATIC);
				return TCL_ERROR;
			    }
			    break;
			case '\\':
			{
			    int	count;
			    
			    (void)Tcl_Backslash(infoPtr->expr, &count);
			    infoPtr->expr += count-1;
			}
			case '#':
			    /*
			     * Comments are only valid at the start of a
			     * line -- skip to the end.
			     */
			    if (startline) {
				while (*infoPtr->expr != '\n' &&
				       *infoPtr->expr != '\0')
				{
				    infoPtr->expr++;
				}
				/*
				 * Back up so we don't overrun an erroneous
				 * null byte.
				 */
				infoPtr->expr--;
			    }
			    break;
			case ' ':
			case '\t':
			case '\r':
			    /*
			     * Don't alter the value of startline for
			     * whitespace
			     */
			    continue;
			case '\n':
			    /* Next char is at start of line */
			    startline = 1;
			    continue;
			case '\0':
			    if (braces) {
				Tcl_Return(interp, "unmatched brace",
					   TCL_STATIC);
				return(TCL_ERROR);
			    } else {
				Tcl_Return(interp, "unmatched bracket",
					   TCL_STATIC);
				return(TCL_ERROR);
			    }
		    }
		    /*
		     * If we got here, the character wasn't whitespace at the
		     * start of the line, so # is no longer special.
		     */
		    startline = 0;
		}
	    }
			    
	    Tcl_Return(interp, (char *) NULL, TCL_STATIC);
	    return TCL_OK;

	case '(':
	    infoPtr->token = OPEN_PAREN;
	    return TCL_OK;

	case ')':
	    infoPtr->token = CLOSE_PAREN;
	    return TCL_OK;

	case '*':
	    if (p[1] == '*') {
		infoPtr->expr += 1;
		infoPtr->token = POWER;
	    } else {
		infoPtr->token = MULT;
	    }
	    return TCL_OK;

	case '/':
	    infoPtr->token = DIVIDE;
	    return TCL_OK;

	case '%':
	    infoPtr->token = MOD;
	    return TCL_OK;

	case '+':
	    infoPtr->token = PLUS;
	    return TCL_OK;

	case '-':
	    infoPtr->token = MINUS;
	    return TCL_OK;

	case '<':
	    switch (p[1]) {
		case '<':
		    infoPtr->expr = p+2;
		    infoPtr->token = LEFT_SHIFT;
		    break;
		case '=':
		    infoPtr->expr = p+2;
		    infoPtr->token = LEQ;
		    break;
		default:
		    infoPtr->token = LESS;
		    break;
	    }
	    return TCL_OK;

	case '>':
	    switch (p[1]) {
		case '>':
		    infoPtr->expr = p+2;
		    infoPtr->token = RIGHT_SHIFT;
		    break;
		case '=':
		    infoPtr->expr = p+2;
		    infoPtr->token = GEQ;
		    break;
		default:
		    infoPtr->token = GREATER;
		    break;
	    }
	    return TCL_OK;

	case '=':
	    if (p[1] == '=') {
		infoPtr->expr = p+2;
		infoPtr->token = EQUAL;
	    } else {
		infoPtr->token = UNKNOWN;
	    }
	    return TCL_OK;

	case '!':
	    if (p[1] == '=') {
		infoPtr->expr = p+2;
		infoPtr->token = NEQ;
	    } else {
		infoPtr->token = NOT;
	    }
	    return TCL_OK;

	case '&':
	    if (p[1] == '&') {
		infoPtr->expr = p+2;
		infoPtr->token = AND;
	    } else {
		infoPtr->token = BIT_AND;
	    }
	    return TCL_OK;

	case '^':
	    infoPtr->token = BIT_XOR;
	    return TCL_OK;

	case '|':
	    if (p[1] == '|') {
		infoPtr->expr = p+2;
		infoPtr->token = OR;
	    } else {
		infoPtr->token = BIT_OR;
	    }
	    return TCL_OK;

	case '~':
	    infoPtr->token = BIT_NOT;
	    return TCL_OK;

	case 0:
	    infoPtr->token = END;
	    infoPtr->expr = p;
	    return TCL_OK;

	default:
	{
	    /*
	     * Treat the thing as a potential list, extracting the next
	     * element from the expression. If the thing is a list, we
	     * will get it back minus the enclosing braces.
	     */
	    const char    *str;
	    int	    size;
	    
	    if (TclFindElement(interp, p, &str, &infoPtr->expr, &size,
			       (int *)0) != TCL_OK)
	    {
		return TCL_ERROR;
	    } else {
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_STRING, str, size);
		} else {
		    /*
		     * Make a copy of the element.
		     */
		    char	*new;
		    
		    new = (char *)malloc(size+1);
		    bcopy(str, new, size);
		    new[size] = '\0';
		    infoPtr->str = new;
		}
		infoPtr->type = infoPtr->token = STRING;
		return TCL_OK;
	    }
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * ExprGetValue --
 *
 *	Parse a "value" from the remainder of the expression in infoPtr.
 *
 * Results:
 *	Normally TCL_OK is returned.  The value of the parsed number is
 *	returned in infoPtr->number.  If an error occurred, then
 *	interp->result contains an error message and TCL_ERROR is returned.
 *
 * Side effects:
 *	Information gets parsed from the remaining expression, and the
 *	expr and token fields in infoPtr get updated.  Information is
 *	parsed until either the end of the expression is reached (null
 *	character or close paren), an error occurs, or a binary operator
 *	is encountered with precedence <= prec.  In any of these cases,
 *	infoPtr->token will be left pointing to the token AFTER the
 *	expression.
 *
 *----------------------------------------------------------------------
 */

int
ExprGetValue(Tcl_Interp		*interp,    /* Interpreter to use for error
					     * reporting. */
	     register ExprInfo	*infoPtr,   /* Describes the state of the parse
					     * just before the value (i.e.
					     * ExprLex will be called to get
					     * first token of value). */
	     int		prec,	    /* Treat any un-parenthesized
					     * operator with precedence <= this
					     * as the end of the expression. */
	     int   		noEval)	    /* TRUE if shouldn't actually
					     * evaluate commands, etc. Used
					     * when || or && dictate their
					     * rhs is to be skipped */
{
    int result, operator;
    int operand = 0;
    double foperand = 0.0;
    const char *stroperand = NULL;
    int gotOp;				/* Non-zero means already lexed the
					 * operator (while picking up value
					 * for unary operator).  Don't lex
					 * again. */
    TclExprNode	*left;
    int	lhs;

    /*
     * There are two phases to this procedure.  First, pick off an initial
     * value.  Then, parse (binary operator, value) pairs until done.
     */

    gotOp = 0;
    result = ExprLex(interp, infoPtr, noEval);
    if (result != TCL_OK) {
	return result;
    }
    if (infoPtr->token == OPEN_PAREN) {

	/*
	 * Parenthesized sub-expression.
	 */

	result = ExprGetValue(interp, infoPtr, -1, noEval);
	if (result != TCL_OK) {
	    return result;
	}
	if (infoPtr->token != CLOSE_PAREN) {
	    Tcl_Return(interp, (char *) NULL, TCL_STATIC);
	    sprintf(((Interp *)interp)->resultSpace,
		    "unmatched parentheses in expression \"%.50s\"",
		    infoPtr->originalExpr);
	    return TCL_ERROR;
	}
    } else {
	if (infoPtr->token == MINUS) {
	    infoPtr->token = UNARY_MINUS;
	}
	if (infoPtr->token >= FIRST_UNARY) {

	    /*
	     * Process unary operators.
	     */

	    operator = infoPtr->token;
	    result = ExprGetValue(interp, infoPtr, precTable[infoPtr->token],
				    noEval);
	    if (result != TCL_OK) {
		return result;
	    }
	    
	    if (infoPtr->type != NUMBER) {
		Tcl_RetPrintf(interp, "invalid operand of unary operator in expression \"%.50s\"",
			      infoPtr->originalExpr);
		if (infoPtr->token == STRING) {
		    free(infoPtr->str);
		}
		return TCL_ERROR;
	    }
	    
	    switch (operator) {
		case UNARY_MINUS:
		    if (infoPtr->dataPtr) {
			infoPtr->node = TclExprNewNode(TENT_OP,
						       UNARY_MINUS,
						       infoPtr->node,
						       (TclExprNode *)0);
		    } else if (infoPtr->doFloat) {
			infoPtr->fnumber = -infoPtr->fnumber;
		    } else {
			infoPtr->number = -infoPtr->number;
		    }
		    break;
		case NOT:
		    if (infoPtr->dataPtr) {
			infoPtr->node = TclExprNewNode(TENT_OP,
						       NOT,
						       infoPtr->node,
						       (TclExprNode *)0);
		    } else if (infoPtr->doFloat) {
			Tcl_Return(interp,
				   "! operator illegal for floating point",
				   TCL_STATIC);
			return(TCL_ERROR);
		    } else {
			infoPtr->number = !infoPtr->number;
		    }
		    break;
		case BIT_NOT:
		    if (infoPtr->dataPtr) {
			infoPtr->node = TclExprNewNode(TENT_OP,
						       BIT_NOT,
						       infoPtr->node,
						       (TclExprNode *)0);
		    } else if (infoPtr->doFloat) {
			Tcl_Return(interp,
				   "~ operator illegal for floating point",
				   TCL_STATIC);
			return(TCL_ERROR);
		    } else {
			infoPtr->number = ~infoPtr->number;
		    }
		    break;
	    }
	    gotOp = 1;
	} else if (infoPtr->token != NUMBER && infoPtr->token != STRING &&
		   infoPtr->token != FNUMBER)
	{
	    goto syntaxError;
	}
    }

    /*
     * Got the first operand.  Now fetch (operator, operand) pairs.
     */
    if (infoPtr->type == NUMBER) {
	if (infoPtr->doFloat) {
	    foperand = infoPtr->fnumber;
	} else {
	    operand = infoPtr->number;
	}
	lhs = NUMBER;
    } else {
	stroperand = infoPtr->str;
	lhs = STRING;
    }
    left = infoPtr->node;
    

    if (!gotOp) {
	result = ExprLex(interp, infoPtr, noEval);
	if (result != TCL_OK) {
	    /* lhs should be freed by caller if string, as it remains in
	     * infoPtr */
	    return result;
	}
    }
    while (1) {
	operator = infoPtr->token;
	if ((operator < FIRST_OP) || (operator >= UNARY_MINUS)) {
	    if ((operator == END) || (operator == CLOSE_PAREN)) {
		return TCL_OK;
	    } else {
		/* lhs should be freed by caller if string, as it remains in
		 * infoPtr */
		goto syntaxError;
	    }
	}
	if (precTable[operator] <= prec) {
	    return TCL_OK;
	}
	/*XXX: Doesn't deal with error well. Should be fabs(foperand)<=epsilon
	 */
	if ((operator == AND || operator == OR) && (lhs == STRING)) {
	    Tcl_RetPrintf(interp, "%s operator illegal for strings",
			  operator == AND ? "&&" : "||");
	    /* lhs should be freed by caller if string, as it remains in
	     * infoPtr */
	    return(TCL_ERROR);
	} else if (!infoPtr->dataPtr) {
	    if (operator == AND && ((infoPtr->doFloat && foperand == 0) ||
				    (!infoPtr->doFloat && operand == 0)))
	    {
		noEval = 1;
	    } else if (operator == OR && ((infoPtr->doFloat && foperand != 0) ||
					  (!infoPtr->doFloat && operand)))
	    {
		noEval = 1;
	    }
	}

	result = ExprGetValue(interp, infoPtr, precTable[operator], noEval);
	if (result != TCL_OK) {
	    if (lhs == STRING &&
		(infoPtr->type != STRING || infoPtr->str != stroperand) &&
		!infoPtr->dataPtr)
	    {
		free((char *)stroperand);
	    }
	    return result;
	}
	if ((infoPtr->token < FIRST_OP) && (infoPtr->token != NUMBER) &&
	    (infoPtr->token != FNUMBER) && (infoPtr->token != STRING) &&
	    (infoPtr->token != END) && (infoPtr->token != CLOSE_PAREN))
	{
	    if (lhs == STRING &&
		(infoPtr->type != STRING || infoPtr->str != stroperand) &&
		!infoPtr->dataPtr)
	    {
		free((char *)stroperand);
	    }
	    goto syntaxError;
	}
#define NO_STRING(funcname) \
	if (lhs == STRING || infoPtr->type == STRING) {\
	    if (lhs == STRING &&\
		(infoPtr->type != STRING || infoPtr->str != stroperand) &&\
		!infoPtr->dataPtr)\
	    { free((char *)stroperand);}\
	    Tcl_Error(interp, #funcname " cannot be applied to strings");\
	}

	switch (operator) {
	    case POWER:
		NO_STRING(**);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   POWER,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    infoPtr->fnumber = pow(foperand, infoPtr->fnumber);
		} else {
		    infoPtr->number = pow((double)operand,
					  (double)infoPtr->number);
		}
		break;
	    case MULT:
		NO_STRING(*);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   MULT,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    infoPtr->fnumber = foperand * infoPtr->fnumber;
		} else {
		    infoPtr->number = operand * infoPtr->number;
		}
		break;
	    case DIVIDE:
		NO_STRING(/);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   DIVIDE,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    if (infoPtr->fnumber == 0) {
			Tcl_Error(interp, "divide by zero");
		    } else {
			infoPtr->fnumber = foperand/infoPtr->fnumber;
		    }
		} else if (infoPtr->number == 0) {
		    Tcl_Error(interp, "divide by zero");
		} else {
		    infoPtr->number = operand / infoPtr->number;
		}
		break;
	    case MOD:
		NO_STRING(%);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   MOD,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    if (infoPtr->fnumber == 0) {
			Tcl_Error(interp, "mod by zero");
		    } else {
			double quotient = foperand/infoPtr->fnumber;
			
			infoPtr->fnumber =
			    (quotient-(int)quotient)*infoPtr->fnumber;
		    }
		} else if (infoPtr->number == 0) {
		    Tcl_Error(interp, "mod by zero");
		} else {
		    infoPtr->number = operand % infoPtr->number;
		}
		break;
	    case PLUS:
		NO_STRING(+);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   PLUS,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    infoPtr->fnumber = foperand + infoPtr->fnumber;
		} else {
		    infoPtr->number = operand + infoPtr->number;
		}
		break;
	    case MINUS:
		NO_STRING(-);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   MINUS,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    infoPtr->fnumber = foperand - infoPtr->fnumber;
		} else {
		    infoPtr->number = operand - infoPtr->number;
		}
		break;
	    case LEFT_SHIFT:
		NO_STRING(<<);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   LEFT_SHIFT,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    Tcl_Error(interp, "<< illegal for floating point");
		} else {
		    infoPtr->number = operand << infoPtr->number;
		}
		break;
	    case RIGHT_SHIFT:
		NO_STRING(>>);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   RIGHT_SHIFT,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    Tcl_Error(interp, ">> illegal for floating point");
		} else {
		    infoPtr->number = operand >> infoPtr->number;
		}
		break;
	    case LESS:
		NO_STRING(<);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   LESS,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    infoPtr->fnumber = foperand < infoPtr->fnumber;
		} else {
		    infoPtr->number = operand < infoPtr->number;
		}
		break;
	    case GREATER:
		NO_STRING(>);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   GREATER,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    infoPtr->fnumber = foperand > infoPtr->fnumber;
		} else {
		    infoPtr->number = operand > infoPtr->number;
		}
		break;
	    case LEQ:
		NO_STRING(<=);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   LEQ,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    infoPtr->fnumber = foperand <= infoPtr->fnumber;
		} else {
		    infoPtr->number = operand <= infoPtr->number;
		}
		break;
	    case GEQ:
		NO_STRING(>=);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   GEQ,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    infoPtr->fnumber = foperand >= infoPtr->fnumber;
		} else {
		    infoPtr->number = operand >= infoPtr->number;
		}
		break;
	    case EQUAL:
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   EQUAL,
						   left,
						   infoPtr->node);
		} else if (lhs == STRING) {
		    int	result;
		    
		    if (infoPtr->type == NUMBER) {
			/*
			 * If rhs could be parsed as a string, it can't possibly
			 * be the same as the lhs, which couldn't.
			 */
			result = 0;
		    } else {
			result = (strcmp(stroperand, infoPtr->str) == 0);
			free(infoPtr->str);
		    }
		    free((char *)stroperand);
		    if (infoPtr->doFloat) {
			infoPtr->fnumber = result;
		    } else {
			infoPtr->number = result;
		    }
		} else if (infoPtr->type == STRING) {
		    if (infoPtr->doFloat) {
			infoPtr->fnumber = 0.0;
		    } else {
			infoPtr->number = 0;
		    }
		    free(infoPtr->str);
		} else if (infoPtr->doFloat) {
		    infoPtr->fnumber = foperand == infoPtr->fnumber;
		} else {
		    infoPtr->number = operand == infoPtr->number;
		}
		break;
	    case NEQ:
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   NEQ,
						   left,
						   infoPtr->node);
		} else if (lhs == STRING) {
		    int	result;
		    
		    if (infoPtr->type == NUMBER) {
			/*
			 * If rhs could be parsed as a string, it can't possibly
			 * be the same as the lhs, which couldn't.
			 */
			result = 1;
		    } else {
			result = (strcmp(stroperand, infoPtr->str) != 0);
			free(infoPtr->str);
		    }
		    free((char *)stroperand);
		    if (infoPtr->doFloat) {
			infoPtr->fnumber = result;
		    } else {
			infoPtr->number = result;
		    }
		    infoPtr->type = NUMBER;
		} else if (infoPtr->type == STRING) {
		    if (infoPtr->doFloat) {
			infoPtr->fnumber = 1.0;
		    } else {
			infoPtr->number = 1;
		    }
		    free(infoPtr->str);
		} else if (infoPtr->doFloat) {
		    infoPtr->fnumber = foperand != infoPtr->fnumber;
		} else {
		    infoPtr->number = operand != infoPtr->number;
		}
		break;
	    case BIT_AND:
		NO_STRING(&);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   BIT_AND,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    Tcl_Error(interp, "& illegal for floating point");
		} else {
		    infoPtr->number = operand & infoPtr->number;
		}
		break;
	    case BIT_XOR:
		NO_STRING(^);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   BIT_XOR,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    Tcl_Error(interp, "^ illegal for floating point");
		} else {
		    infoPtr->number = operand ^ infoPtr->number;
		}
		break;
	    case BIT_OR:
		NO_STRING(|);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   BIT_OR,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    Tcl_Error(interp, "| illegal for floating point");
		} else {
		    infoPtr->number = operand | infoPtr->number;
		}
		break;
	    case AND:
		NO_STRING(&&);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   AND,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    Tcl_Error(interp, "&& illegal for floating point");
		} else if (noEval) {
		    infoPtr->number = 0;
		}
		break;
	    case OR:
		NO_STRING(||);
		if (infoPtr->dataPtr) {
		    infoPtr->node = TclExprNewNode(TENT_OP,
						   OR,
						   left,
						   infoPtr->node);
		} else if (infoPtr->doFloat) {
		    Tcl_Error(interp, "|| illegal for floating point");
		} else if (noEval) {
		    infoPtr->number = 1;
		}
		break;
	}
	infoPtr->type = lhs = NUMBER;
	if (infoPtr->doFloat) {
	    foperand = infoPtr->fnumber;
	} else {
	    operand = infoPtr->number;
	}
	left = infoPtr->node;
    }

    syntaxError:
    Tcl_Return(interp, (char *) NULL, TCL_STATIC);
    sprintf(((Interp *)interp)->resultSpace,
	    "syntax error in expression \"%.50s\"",
	    infoPtr->originalExpr);
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_Expr --
 *
 *	Parse and evaluate an expression.
 *
 * Results:
 *	The return value is TCL_OK if the expression was correctly parsed;
 *	if there was a syntax error or some other error during parsing,
 *	then another Tcl return value is returned and Tcl_Result points
 *	to an error message.  If all went well, *valuePtr is filled in
 *	with the result corresponding to the expression string.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
Tcl_Expr(Tcl_Interp *interp,	/* Intepreter to use for variables etc. */
	 const char *string,	/* Expression to evaluate. */
	 int	    *valuePtr)	/* Where to store result of evaluation. */
{
    ExprInfo info;
    int result;

    info.interp = interp;
    info.originalExpr = string;
    info.expr = string;
    info.doFloat = 0;
    info.dataPtr = 0;
    info.node = 0;
    result = ExprGetValue(interp, &info, -1, 0);
    if (result != TCL_OK) {
	if (info.type == STRING) {
	    free(info.str);
	}
	return result;
    }
    if (info.token != END || info.type == STRING) {
	Tcl_Return(interp, (char *) NULL, TCL_STATIC);
	sprintf(((Interp *)interp)->resultSpace,
		"syntax error in expression \"%.50s\"",
		string);
	if (info.type == STRING) {
	    free(info.str);
	}
	return TCL_ERROR;
    }
    *valuePtr = info.number;
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_FExpr --
 *
 *	Parse and evaluate an expression using floating-point.
 *
 * Results:
 *	The return value is TCL_OK if the expression was correctly parsed;
 *	if there was a syntax error or some other error during parsing,
 *	then another Tcl return value is returned and interp->result points
 *	to an error message.  If all went well, *valuePtr is filled in
 *	with the result corresponding to the expression string.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
Tcl_FExpr(Tcl_Interp *interp,	/* Intepreter to use for variables etc. */
	  const char *string,	/* Expression to evaluate. */
	  double *valuePtr)	/* Where to store result of evaluation. */
{
    ExprInfo info;
    int result;

    info.interp = interp;
    info.originalExpr = string;
    info.expr = string;
    info.doFloat = 1;
    info.dataPtr = 0;
    info.node = 0;
    result = ExprGetValue(interp, &info, -1, 0);
    if (result != TCL_OK) {
	if (info.type == STRING) {
	    free(info.str);
	}
	return result;
    }
    if (info.token != END || info.type == STRING) {
	Tcl_Return(interp, (char *) NULL, TCL_STATIC);
	sprintf(((Interp *)interp)->resultSpace,
		"syntax error in expression \"%.50s\"",
		string);
	if (info.type == STRING) {
	    free(info.str);
	}
	return TCL_ERROR;
    }
    *valuePtr = info.fnumber;
    return TCL_OK;
}


/***********************************************************************
 *				TclExprFreeTree
 ***********************************************************************
 * SYNOPSIS:	    Recursive routine to free the tree for a compiled
 *		    expression.
 * CALLED BY:	    (INTERNAL) TclExprByteCompile, self
 * RETURN:	    nothing
 * SIDE EFFECTS:    the node and its children are freed, as is any
 *		    	byte-code it points to
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/14/94		Initial Revision
 *
 ***********************************************************************/
static void
TclExprFreeTree(TclExprNode *root)
{
    if (root) {
	TclExprFreeTree(root->left);
	TclExprFreeTree(root->right);
	if (root->type == TENT_CODE) {
	    free((char *)root->data.code.code);
	}
	free((char *)root);
    }
}


/***********************************************************************
 *				TclExprOutputTree
 ***********************************************************************
 * SYNOPSIS:	    Put out the bytes that make up the compiled expression,
 *		    now the expression has been parsed into a tree.
 * CALLED BY:	    (INTERNAL) TclExprByteCompile, self
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/14/94		Initial Revision
 *
 ***********************************************************************/
static void
TclExprOutputTree(Tcl_Interp *interp,
		  TBCCData  *dataPtr,
		  TclExprNode *root)
{
    if (root) {
	switch(root->type) {
	case TENT_OP:
	    TBCCOutputByte(dataPtr, root->data.op);
	    TclExprOutputTree(interp, dataPtr, root->left);
	    TclExprOutputTree(interp, dataPtr, root->right);
	    break;
	case TENT_NUMBER:
	    TBCCOutputByte(dataPtr, NUMBER);
	    TBCCOutputSignedNum(dataPtr, root->data.number);
	    break;
	case TENT_FLOAT: {
	    /*
	     * For portability between architectures, we convert the float
	     * back into a string (floating-point differences aren't as simple
	     * as just getting the bytes in the right order).
	     */
	    char    fnum[64];

	    sprintf(fnum, "%.20lg", root->data.fnumber);
	    TBCCOutputByte(dataPtr, FNUMBER);
	    TBCCOutputString(dataPtr, fnum, strlen(fnum));
	    break;
	}
	case TENT_VAR:
	    TBCCOutputByte(dataPtr, VARREF);
	    TBCCOutputString(dataPtr, root->data.var, strlen(root->data.var));
	    break;
	case TENT_CODE:
	    TBCCOutputByte(dataPtr, CODEREF);
	    TBCCOutputBytes(dataPtr, root->data.code.code,
			    root->data.code.size);
	    break;
	case TENT_STRING:
	    TBCCOutputByte(dataPtr, STRING);
	    TBCCOutputString(dataPtr, root->data.string,
			     strlen(root->data.string));
	    break;
	}
    }
}


/*
 *----------------------------------------------------------------------
 *
 * TclExprByteCompile --
 *
 *	Compile an expression for later evaluation.
 *
 * Results:
 *	The return value is TCL_OK if the expression was correctly parsed;
 *	if there was a syntax error or some other error during parsing,
 *	then another Tcl return value is returned and Tcl_Result points
 *	to an error message.  
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
TclExprByteCompile(Tcl_Interp *interp,	/* Intepreter to use for errors etc. */
		   const char *string,	/* Expression to evaluate. */
		   TBCCData *dataPtr)
{
    ExprInfo info;
    int result;

    /*
     * Set up the expression-parser state
     */
    info.interp = interp;
    info.originalExpr = string;
    info.expr = string;
    info.doFloat = 0;
    info.dataPtr = dataPtr;
    /*
     * Call the common code to perform the parse. since info.dataPtr is
     * non-zero, the code knows we're compiling the thing and will return
     * the root of the expression tree in info.node.
     */
    result = ExprGetValue(interp, &info, -1, 0);
    if (result != TCL_OK) {
	TclExprFreeTree(info.node);
	return result;
    }
    
    /*
     * Make sure we got to the end of the expression and the result s/b numeric.
     */
    if (info.token != END || info.type == STRING) {
	Tcl_Return(interp, (char *) NULL, TCL_STATIC);
	sprintf(((Interp *)interp)->resultSpace,
		"syntax error in expression \"%.50s\"",
		string);
	TclExprFreeTree(info.node);
	return TCL_ERROR;
    }

    if (!dataPtr->allowJustVarRef && info.node->type == TENT_VAR) {
	/*
	 * If the only thing in the tree is a variable reference, the variable
	 * might hold a full expression, so indicate this problem to our
	 * caller by returning TCL_BREAK.
	 */
	TclExprFreeTree(info.node);
	return TCL_BREAK;
    } else {
	TclExprOutputTree(interp, dataPtr, info.node);
	TclExprFreeTree(info.node);

	return TCL_OK;
    }
}

/******************************************************************************
 *
 *		    COMPILED-EXPRESSION EVALUATION
 *
 ******************************************************************************/

typedef struct {
    int	    type;   	/* NUMBER, FNUMBER or STRING */
    
    union {
	long    number;
	double  fnumber;
	struct {
	    const char 	*string;
	    int	    	dynamic;
	}   	string;
    }	    data;
} TBExprToken;

#define TEBE_NO_EVAL	    0x0001  	/* Result won't be used -- we're just
					 * skipping the data */
#define TEBE_FLOAT  	    0x0002  	/* End result will be converted to
					 * floating-point, so preserve precision
					 */


/***********************************************************************
 *				TEBCheckArgType
 ***********************************************************************
 * SYNOPSIS:	    See if the data type of an operand is compatible with
 *		    the operator that's going to be performed on it.
 * CALLED BY:	    (INTERNAL) TclExprByteEvalLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    STRING tokens can only be operated on by == and !=
 *	    	    FNUMBER tokens cannot have bit-manipulation performed
 *			    on them
 *	    	    everything else is fine
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/14/93	Initial Revision
 *
 ***********************************************************************/
static int
TEBCheckArgType(Tcl_Interp *interp,
		unsigned op,
		TBExprToken *token)
{
    if (op != EQUAL && op != NEQ && token->type == STRING) {
	Tcl_RetPrintf(interp, "string not valid as operand of %s operator",
		      opNames[op-FIRST_OP].op);
	return(TCL_ERROR);
    }

    if (token->type == FNUMBER &&
	((op >= BIT_AND && op <= OR) || op == NOT || op == BIT_NOT ||
	 op == LEFT_SHIFT || op == RIGHT_SHIFT))
    {
	/*
	 * Force the darn thing to be an integer if the operator is invalid
	 * for floating-point. Otherwise we can get screwed if someone uses
	 * an unsigned number that won't fit in 32-bits. In an interpreted
	 * expression, the number would be treated as signed and the programmer
	 * would just have to be careful to mask things. In a compiled one,
	 * however, the thing gets converted to floating-point.
	 */
	token->type = NUMBER;
	token->data.number = (unsigned long)token->data.fnumber;
    }

    return (TCL_OK);
}

/***********************************************************************
 *				TEBEGetNumber
 ***********************************************************************
 * SYNOPSIS:	    Extract a number (integer or float) from a string,
 *	    	    if possible. The string comes from a variable or
 *	    	    a nested command.
 * CALLED BY:	    (INTERNAL) TclExprByteEvalLow
 * RETURN:	    the appropriate TBExprToken
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/14/93	Initial Revision
 *
 ***********************************************************************/
static void
TEBEGetNumber(const char *str,
	      TBExprToken *val,
	      int dynamic)
{
    const char	*term;
    const char	*fterm;
    double  	fnum = 0.0;
    long    	inum;
    int	    	havefnum;

    /*
     * First convert it as an integer
     */
    inum = TclExprGetNum(str, &term);
    
    /*
     * Now convert it as a floating-point number.
     * 3/9/94: A lot of the things we get are one or two characters long, which
     * cannot possibly require floating-point representation. To speed things
     * up, we quickly make sure the string is at least 3 chars long. -- ardeb
     */
    if (str[1] != '\0' && str[2] != '\0') {
	fnum = strtod(str, &fterm);
	havefnum = 1;
    } else {
	havefnum = 0;
    }

    if (havefnum &&
	((term < fterm) ||
	 (term == fterm && fnum != (double)inum)))
    {
	/*
	 * If consumed more chars as a float, we assume it's because of
	 * decimal stuff or exponents or whatever
	 *
	 *  -OR-
	 *
	 * If integer converted to a double is not the same as the
	 * floating-point version when both used the same number of
	 * characters, then we'll lose precision treating it as an int.
	 */
	term = fterm;
	val->type = FNUMBER;
	val->data.fnumber = fnum;
    } else {
	/*
	 * If consumed more chars as an int, we assume it's because of
	 * radix stuff
	 *
	 *  -OR-
	 *
	 * If integer converted to a double is the same as the
	 * floating-point version when both used the same number of
	 * characters, then we can save space and time by using the
	 * integer representation.
	 */
	val->type = NUMBER;
	val->data.number = inum;
    }

    
    if ((term == str) || (*term != 0)) {
	/*
	 * The entire thing didn't make up a number, or it was empty.
	 * Convert it to a string, pending appropriate operator.
	 */
	val->type = STRING;
	val->data.string.string = str;
	val->data.string.dynamic = dynamic;
    } else if (dynamic) {
	/*
	 * Not keeping the string, so we need to free it.
	 */
	free((char *)str);
    }
}
    

/***********************************************************************
 *				TclExprByteEvalLow
 ***********************************************************************
 * SYNOPSIS:	    Perform a single operator for a compiled expression.
 * CALLED BY:	    (INTERNAL) TclExprByteEval, self
 * RETURN:	    TCL_OK/TCL_ERROR, *val, *exprPtr
 * SIDE EFFECTS:    *exprPtr is advanced beyond the operands & operator
 *	    	    	for the operation performed
 *	    	    embedded byte-code will be evaluated if TEBE_NO_EVAL
 *	    	    	not set.
 *
 * STRATEGY:	    
 *	Snag opcode
 *	If terminal, evaluate and return as current thing
 *
 *	Recurse.
 *	If lhs is string & opcode doesn't accept strings, return error
 *	If opcode is binary and lhs is string:
 *	    if in iPtr->resultSpace, copy to local var
 *	If opcode is binary:
 *	    If opcode is logical AND & lhs is 0
 *	    	Recurse(flags | TEBE_NO_EVAL)
 *	    elif opcode is logical OR & lhs is !0
 *	        Recurse(flags | TEBE_NO_EVAL)
 *	    else
 *	    	Recurse(flags)
 *	evaluate opcode
 *	if lhs or rhs is dynamic string: free it
 *	return result
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/14/93	Initial Revision
 *
 ***********************************************************************/
static int
TclExprByteEvalLow(Tcl_Interp	*interp,
		   const unsigned char **exprPtr,
		   TBExprToken	*val,
		   int flags)
{
    TBExprToken	lhs, rhs;
    const unsigned char *expr = *exprPtr;
    int	result;
    
    rhs.type = lhs.type = NUMBER;

    if (*expr < FIRST_OP) {
	/*
	 * The thing is a terminal. Copy it from the byte-code into the
	 * passed TBExprToken for our caller to use.
	 */
	switch (*expr++) {
	case NUMBER:
	    /*
	     * NUMBER is stored as a signed integer in the standard byte-code
	     * format.
	     */
	    val->type = NUMBER;
	    val->data.number = TclByteCodeFetchSignedNum(&expr);
	    break;
	case FNUMBER: {
	    /*
	     * For portability, floating-point numbers are stored as strings.
	     * These must be converted to floats here.
	     */
	    const char *num;

	    num = TclByteCodeFetchString((Interp *)interp, &expr, 0);
	    val->type = FNUMBER;
	    val->data.fnumber = strtod(num, 0);
	    break;
	}
	case STRING:
	    /*
	     * Strings are embedded in the byte-code as usual.
	     */
	    val->type = STRING;
	    val->data.string.string = TclByteCodeFetchString((Interp *)interp,
							     &expr, 0);
	    val->data.string.dynamic = 0;
	    break;
	case VARREF: {
	    /*
	     * Extract the variable name (a byte-code string) and, if
	     * TEBE_NO_EVAL is clear, fetch its value [if TEBE_NO_EVAL,
	     * there's no point in wasting time searching for the variable,
	     * as its value won't be used anyway]
	     */
	    const char	*varname = TclByteCodeFetchString((Interp *)interp,
							  &expr, 0);
	    const char	*varval;

	    if (!(flags & TEBE_NO_EVAL)) {
		varval = Tcl_GetVar(interp, varname, 0);
		TEBEGetNumber(varval, val, 0);
	    } else {
		val->type = NUMBER;
		val->data.number = 1; /* Safest constant (no divide-by-zero) */
	    }
	    break;
	}
	case CODEREF: {
	    /*
	     * Evaluate the byte-code, if TEBE_NO_EVAL clear.
	     */
	    const unsigned char *code;
	    unsigned long len;

	    len = TclByteCodeFetchNum(&expr);
	    code = expr;
	    expr += len;

	    if (!(flags & TEBE_NO_EVAL)) {
		result = TclByteCodeEval(interp, len, code);
		if (result != TCL_OK) {
		    return (result);
		}
		TEBEGetNumber(interp->result, val, interp->dynamic);
		interp->dynamic = 0;
	    } else {
		val->type = NUMBER;
		val->data.number = 1; /* Safest constant (no divide-by-zero) */
	    }
	    break;
	}
	default:
	    Tcl_Error(interp, "ack");
	}
    } else {
	/*
	 * At an operator node. First recurse to fetch the value of the lhs
	 * operand.
	 */
	unsigned op = *expr++;
	char	lhsBuf[TCL_RESULT_SIZE];
	Interp	*iPtr = (Interp *)interp;

	result = TclExprByteEvalLow(interp, &expr, &lhs, flags);
	if (result != TCL_OK) {
	    /*
	     * Error getting lhs, so free any dynamic string and return
	     * the result.
	     */
	    if (lhs.type == STRING && lhs.data.string.dynamic) {
		free((char *)lhs.data.string.string);
	    }
	    return (result);
	}
	/*
	 * Make sure the lhs is compatible with the operator.
	 */
	result = TEBCheckArgType(interp, op, &lhs);
	if (result != TCL_OK) {
	    if (lhs.type == STRING && lhs.data.string.dynamic) {
		free((char *)lhs.data.string.string);
	    }
	    return (result);
	}
	
	/*
	 * Fetch rhs for binary operator.
	 */
	if (op < FIRST_UNARY) {
	    /*
	     * If string resides in interpreter's resultSpace, it's in peril,
	     * so copy it to our own private storage.
	     */
	    if (lhs.type == STRING &&
		lhs.data.string.string == iPtr->resultSpace)
	    {
		strcpy(lhsBuf, lhs.data.string.string);
		lhs.data.string.string = lhsBuf;
	    }
	    /*
	     * Cope with logical AND & OR, telling our recursive selves not to
	     * evaluate anything if the lhs is 0 or non-0, respectively. We know
	     * the lhs is an integer, b/c that's what the TEBCheckArgType
	     * routine checks.
	     */
	    if (op == AND) {
		result = TclExprByteEvalLow(interp, &expr, &rhs,
					    (flags |
					     (lhs.data.number == 0 ?
					      TEBE_NO_EVAL : 0)));
	    } else if (op == OR) {
		result = TclExprByteEvalLow(interp, &expr, &rhs,
					    (flags |
					     (lhs.data.number != 0 ?
					      TEBE_NO_EVAL : 0)));
	    } else {
		result = TclExprByteEvalLow(interp, &expr, &rhs, flags);
	    }
	    
	    /*
	     * On error, free up the lhs & rhs strings, if necessary, and
	     * get out.
	     */
	    if (result != TCL_OK) {
		if (lhs.type == STRING && lhs.data.string.dynamic) {
		    free((char *)lhs.data.string.string);
		}
		if (rhs.type == STRING && rhs.data.string.dynamic) {
		    free((char *)rhs.data.string.string);
		}
		return(result);
	    }

	    /*
	     * If one of the operands is floating-point and the other is
	     * integral, convert the integer to floating-point.
	     */
	    if ((lhs.type == FNUMBER) && (rhs.type == NUMBER)) {
		rhs.type = FNUMBER;
		rhs.data.fnumber = rhs.data.number;
	    } else if ((rhs.type == FNUMBER) && (lhs.type == NUMBER)) {
		lhs.type = FNUMBER;
		lhs.data.fnumber = lhs.data.number;
	    }

	    /*
	     * Make sure the rhs is valid for the operator we've got.
	     */
	    result = TEBCheckArgType(interp, op, &rhs);
	    if (result != TCL_OK) {
		if (lhs.type == STRING && lhs.data.string.dynamic) {
		    free((char *)lhs.data.string.string);
		}
		if (rhs.type == STRING && rhs.data.string.dynamic) {
		    free((char *)rhs.data.string.string);
		}
		return(result);
	    }
	}

	/*
	 * Assume the result will be the same type as the lhs (in the case
	 * of string operands, this is false, but we'll deal with that special
	 * case when we encounter it). For binary operators, both the lhs and
	 * the rhs will be the same type of number, so we need only look at
	 * the lhs to determine whether to do floating-point or integer math
	 */
	val->type = lhs.type;
	switch(op) {
	    case POWER:
		if (lhs.type == FNUMBER) {
		    val->data.fnumber = pow(lhs.data.fnumber, rhs.data.fnumber);
		} else {
		    /*
		     * Switch to using floating-point when generating a power...
		     */
		    val->type = FNUMBER;
		    val->data.fnumber = pow((double)lhs.data.number,
					    (double)rhs.data.number);
		}
		break;
	    case MULT:
		if (lhs.type == FNUMBER) {
		    val->data.fnumber = lhs.data.fnumber * rhs.data.fnumber;
		} else {
		    val->data.number = lhs.data.number * rhs.data.number;
		}
		break;
	    case DIVIDE:
		if (lhs.type == FNUMBER) {
		    if (rhs.data.fnumber == 0) {
			Tcl_Error(interp, "divide by zero");
		    } else {
			val->data.fnumber = lhs.data.fnumber/rhs.data.fnumber;
		    }
		} else if (rhs.data.number == 0) {
		    Tcl_Error(interp, "divide by zero");
		} else if (flags & TEBE_FLOAT) {
		    /*
		     * If end result of evaluation is float, then be sure to
		     * maintain precision.
		     */
		    val->type = FNUMBER;
		    val->data.fnumber =
			(double)lhs.data.number / rhs.data.number;
		} else {
		    val->data.number = lhs.data.number / rhs.data.number;
		}
		break;
	    case MOD:
		if (lhs.type == FNUMBER) {
		    if (rhs.data.fnumber == 0) {
			Tcl_Error(interp, "mod by zero");
		    } else {
			double quotient = lhs.data.fnumber/rhs.data.fnumber;
			
			val->data.fnumber =
			    (quotient-(int)quotient)*rhs.data.fnumber;
		    }
		} else if (rhs.data.number == 0) {
		    Tcl_Error(interp, "mod by zero");
		} else {
		    val->data.number = lhs.data.number % rhs.data.number;
		}
		break;
	    case PLUS:
		if (lhs.type == FNUMBER) {
		    val->data.fnumber = lhs.data.fnumber + rhs.data.fnumber;
		} else {
		    val->data.number = lhs.data.number + rhs.data.number;
		}
		break;
	    case MINUS:
		if (lhs.type == FNUMBER) {
		    val->data.fnumber = lhs.data.fnumber - rhs.data.fnumber;
		} else {
		    val->data.number = lhs.data.number - rhs.data.number;
		}
		break;
	    case LEFT_SHIFT:
		val->data.number = lhs.data.number << rhs.data.number;
		break;
	    case RIGHT_SHIFT:
		val->data.number = lhs.data.number >> rhs.data.number;
		break;
	    case LESS:
		val->type = NUMBER;
		if (lhs.type == FNUMBER) {
		    val->data.number = lhs.data.fnumber < rhs.data.fnumber;
		} else {
		    val->data.number = lhs.data.number < rhs.data.number;
		}
		break;
	    case GREATER:
		val->type = NUMBER;
		if (lhs.type == FNUMBER) {
		    val->data.number = lhs.data.fnumber > rhs.data.fnumber;
		} else {
		    val->data.number = lhs.data.number > rhs.data.number;
		}
		break;
	    case LEQ:
		val->type = NUMBER;
		if (lhs.type == FNUMBER) {
		    val->data.number = lhs.data.fnumber <= rhs.data.fnumber;
		} else {
		    val->data.number = lhs.data.number <= rhs.data.number;
		}
		break;
	    case GEQ:
		val->type = NUMBER;
		if (lhs.type == FNUMBER) {
		    val->data.number = lhs.data.fnumber >= rhs.data.fnumber;
		} else {
		    val->data.number = lhs.data.number >= rhs.data.number;
		}
		break;
	    case EQUAL:
		val->type = NUMBER;

		if (lhs.type == STRING) {
		    if (rhs.type == NUMBER || rhs.type == FNUMBER) {
			/*
			 * If rhs could be parsed as a number, it can't
			 *  possibly be the same as the lhs, which couldn't.
			 */
			val->data.number = 0;
		    } else {
			val->data.number =
			    (strcmp(lhs.data.string.string,
				    rhs.data.string.string) == 0);
			if (rhs.data.string.dynamic) {
			    free((char *)rhs.data.string.string);
			}
		    }
		    if (lhs.data.string.dynamic) {
			free((char *)lhs.data.string.string);
		    }
		} else if (rhs.type == STRING) {
		    val->data.number = 0;
		    if (rhs.data.string.dynamic) {
			free((char *)rhs.data.string.string);
		    }
		} else if (lhs.type == FNUMBER) {
		    val->data.number = lhs.data.fnumber == rhs.data.fnumber;
		} else {
		    val->data.number = lhs.data.number == rhs.data.number;
		}
		break;
	    case NEQ:
		val->type = NUMBER;
		if (lhs.type == STRING) {
		    if (rhs.type == NUMBER || rhs.type == FNUMBER) {
			/*
			 * If rhs could be parsed as a number, it can't
			 * possibly be the same as the lhs, which couldn't.
			 */
			val->data.number = !0;
		    } else {
			val->data.number =
			    (strcmp(lhs.data.string.string,
				    rhs.data.string.string) != 0);
			if (rhs.data.string.dynamic) {
			    free((char *)rhs.data.string.string);
			}
		    }
		    if (lhs.data.string.dynamic) {
			free((char *)lhs.data.string.string);
		    }
		} else if (rhs.type == STRING) {
		    val->data.number = !0;
		    if (rhs.data.string.dynamic) {
			free((char *)rhs.data.string.string);
		    }
		} else if (lhs.type == FNUMBER) {
		    val->data.number = lhs.data.fnumber != rhs.data.fnumber;
		} else {
		    val->data.number = lhs.data.number != rhs.data.number;
		}

		break;
	    case BIT_AND:
		val->data.number = lhs.data.number & rhs.data.number;
		break;
	    case BIT_XOR:
		val->data.number = lhs.data.number ^ rhs.data.number;
		break;
	    case BIT_OR:
		val->data.number = lhs.data.number | rhs.data.number;
		break;
	    case AND:
		val->data.number = lhs.data.number && rhs.data.number;
		break;
	    case OR:
		val->data.number = lhs.data.number || rhs.data.number;
		break;
	    case UNARY_MINUS:
		if (lhs.type == FNUMBER) {
		    val->data.fnumber = -lhs.data.fnumber;
		} else {
		    val->data.number = -lhs.data.number;
		}
		break;
	    case NOT:
		val->data.number = !lhs.data.number;
		break;
	    case BIT_NOT:
		val->data.number = ~lhs.data.number;
		break;
	    default:
		Tcl_Error(interp, "ack pthht");
	}
    }

    *exprPtr = expr;

    return (TCL_OK);
}
	
	    
	    
	    

/***********************************************************************
 *				TclExprByteEval
 ***********************************************************************
 * SYNOPSIS:	    Evaluate a compiled expression
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    only those inherent in the expression
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/93	Initial Revision
 *
 ***********************************************************************/
int
TclExprByteEval(Tcl_Interp *interp,
		const unsigned char *expr,
		unsigned long len,
		int *valuePtr)
{
    TBExprToken	    val;
    int	    	    result;

    result = TclExprByteEvalLow(interp, &expr, &val, 0);
    if (result != TCL_OK) {
	return (result);
    }

    if (val.type == STRING) {
	Tcl_Return(interp, "compiled expression doesn't evaluate to a number",
		   TCL_STATIC);
	return (TCL_ERROR);
    } else if (val.type == FNUMBER) {
	*valuePtr = (int)val.data.fnumber;
    } else {
	*valuePtr = val.data.number;
    }

    return (TCL_OK);
}
	    

/***********************************************************************
 *				TclFExprByteEval
 ***********************************************************************
 * SYNOPSIS:	    Evaluate a compiled expression to a floating-point value
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    only those inherent in the expression
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/93	Initial Revision
 *
 ***********************************************************************/
int
TclFExprByteEval(Tcl_Interp *interp,
		const unsigned char *expr,
		unsigned long len,
		double *valuePtr)
{
    TBExprToken	    val;
    int	    	    result;

    result = TclExprByteEvalLow(interp, &expr, &val, TEBE_FLOAT);
    if (result != TCL_OK) {
	return (result);
    }

    if (val.type == STRING) {
	Tcl_Return(interp, "compiled expression doesn't evaluate to a number",
		   TCL_STATIC);
	return (TCL_ERROR);
    } else if (val.type == FNUMBER) {
	*valuePtr = val.data.fnumber;
    } else {
	*valuePtr = val.data.number;
    }

    return (TCL_OK);
}


/***********************************************************************
 *				TclExprByteDisasmLow
 ***********************************************************************
 * SYNOPSIS:	    Recursive routine to print out a compiled expression
 * CALLED BY:	    (INTERNAL) TclExprByteDisasm, self
 * RETURN:	    nothing
 * SIDE EFFECTS:    output
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/11/94		Initial Revision
 *
 ***********************************************************************/
#define MAX_LEVEL  (32)
static void
TclExprByteDisasmLow(Tcl_Interp *interp,
		     const unsigned char **pPtr,
		     unsigned base,
		     unsigned long branch,
		     unsigned level)
{
    const unsigned char *p = *pPtr;
    
    if (level < MAX_LEVEL) {
	unsigned i;
	unsigned long mask;

	(*interp->output)("%*s", base, "");
	for (i = 1, mask = 1; i < level; i++, mask <<= 1) {
	    (*interp->output)("%c ", (branch & mask) ? '|' : ' ');
	}
	(*interp->output)("+-");
    }
    
    switch (*p++) {
    case NUMBER: {
	long	n = TclByteCodeFetchSignedNum(&p);
	if (level < MAX_LEVEL) {
	    (*interp->output)("%ld\n",n);
	}
	break;
    }
    case FNUMBER: {
	const char *str = TclByteCodeFetchString((Interp *)interp, &p, 0);
	if (level < MAX_LEVEL) {
	    (*interp->output)("%s\n", str);
	}
	break;
    }
    case STRING: {
	const char *str = TclByteCodeFetchString((Interp *)interp, &p, 0);
	if (level < MAX_LEVEL) {
	    (*interp->output)("{%s}\n",str);
	}
	break;
    }
    case VARREF: {
	const char *str = TclByteCodeFetchString((Interp *)interp, &p, 0);
	if (level < MAX_LEVEL) {
	    (*interp->output)("$%s\n", str);
	}
	break;
    }
    case CODEREF: {
	unsigned long len = TclByteCodeFetchNum(&p);
	if (level < MAX_LEVEL) {
	    (*interp->output)("CODE (%d byte%s)\n", len,
			      len == 1 ? "" : "s");
	    TclByteCodeDisasm(interp, p, len, base + level * 2 + 2);
	}
	p += len;
	break;
    }

	
    default:
	if (level < MAX_LEVEL) {
	    (*interp->output)("%s\n", opNames[p[-1]-FIRST_OP].token);
	}
	TclExprByteDisasmLow(interp, &p, base,
			     branch | (1 << level), level+1);
	TclExprByteDisasmLow(interp, &p, base, branch, level+1);
	break;
    case UNARY_MINUS:
    case NOT:
    case BIT_NOT:
	if (level < MAX_LEVEL) {
	    (*interp->output)("%s\n", opNames[p[-1]-FIRST_OP].token);
	}
	TclExprByteDisasmLow(interp, &p, base, branch, level+1);
	break;
    }

    *pPtr = p;
}

/***********************************************************************
 *				TclExprByteDisasm
 ***********************************************************************
 * SYNOPSIS:	    Print out a compiled expression
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    output
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/14/93	Initial Revision
 *
 ***********************************************************************/
void
TclExprByteDisasm(Tcl_Interp *interp,
		  const unsigned char *p,
		  unsigned long len,
		  unsigned indent)
{
    TclExprByteDisasmLow(interp, &p, indent, 0, 1);
}


/***********************************************************************
 *				TclExprByteChangeStringReferencesLow
 ***********************************************************************
 * SYNOPSIS:	    Recursive routine to print out a compiled expression
 * CALLED BY:	    (INTERNAL) TclExprByteChangeStringReferences, self
 * RETURN:	    nothing
 * SIDE EFFECTS:    output
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/11/94		Initial Revision
 *
 ***********************************************************************/
static void
TclExprByteChangeStringReferencesLow(TBCCData *dataPtr,
				     unsigned char **pPtr,
				     const TBCCStringChange *changes)
{
    unsigned char *p = *pPtr;
    
    switch (*p++) {
    case NUMBER: {
	(void)TclByteCodeFetchSignedNum((const unsigned char **)(&p));
	break;
    }
    case FNUMBER: {
	TBCCChangeReference(dataPtr, &p, pPtr, 0, changes);
	break;
    }
    case STRING: {
	TBCCChangeReference(dataPtr, &p, pPtr, 0, changes);
	break;
    }
    case VARREF: {
	TBCCChangeReference(dataPtr, &p, pPtr, 0, changes);
	break;
    }
    case CODEREF: {
	TBCCChangeCodeStringReferences(dataPtr, &p, 0, changes);
	break;
    }
    default:
	TclExprByteChangeStringReferencesLow(dataPtr, &p, changes);
	TclExprByteChangeStringReferencesLow(dataPtr, &p, changes);
	break;
    case UNARY_MINUS:
    case NOT:
    case BIT_NOT:
	TclExprByteChangeStringReferencesLow(dataPtr, &p, changes);
	break;
    }

    *pPtr = p;
}

/***********************************************************************
 *				TclExprByteChangeStringReferences
 ***********************************************************************
 * SYNOPSIS:	    Fix up references to strings in the passed compiled
 *		    expression to make everything as small as possible.
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    output
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/14/93	Initial Revision
 *
 ***********************************************************************/
unsigned long
TclExprByteChangeStringReferences(TBCCData *dataPtr,
				  unsigned char *p,
				  unsigned long len,
				  const TBCCStringChange *changes)
{
    unsigned long   baseOff = p - dataPtr->data;

    TclExprByteChangeStringReferencesLow(dataPtr, &p, changes);
    return ((p - dataPtr->data) - baseOff);
}


