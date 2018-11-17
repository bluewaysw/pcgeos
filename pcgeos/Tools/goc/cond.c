/*-
 * cond.c --
 *	Functions to handle conditionals in a makefile.
 *
 * Copyright (c) 1988, 1989 by the Regents of the University of California
 * Copyright (c) 1988, 1989 by Adam de Boor
 * Copyright (c) 1989 by Berkeley Softworks
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any non-commercial purpose
 * and without fee is hereby granted, provided that the above copyright
 * notice appears in all copies.  The University of California,
 * Berkeley Softworks and Adam de Boor make no representations about
 * the suitability of this software for any purpose.  It is provided
 * "as is" without express or implied warranty.
 *
 * Interface:
 *	Cond_Eval 	Evaluate the conditional in the passed line.
 *
 */
#ifndef lint
static char *rcsid = "$Id: cond.c,v 1.1 92/08/22 10:14:58 josh Exp $ SPRITE (Berkeley)";
#endif lint

#include    <config.h>
#include    <compat/stdlib.h>

#include    "malloc.h"

#if defined(SYSV) || defined(__BORLANDC__)
#include    <math.h>
#endif

#include    <compat/string.h>
#include    <ctype.h>
#include    "goc.h"
#include    "buf.h"
#include    "scan.h"   /* for Scan_MacroIsDefined                     */
#include    "cond.h"    /* yyerror and the COND_SKIP, COND_PARSE, etc. */


typedef enum {
    And, Or, Not, True, False, LParen, RParen, EndOfFile, None, Err
} Token;

#ifdef __BORLANDC__

/**********************prototypes for statis routines ****************/
static void	CondPushBack(Token t);
static int	CondGetArg(char **linePtr, char **argsPtr, char *func, Boolean parens);
static Boolean  CondDoDefined(int argten, char *arg);



static Token	CondToken(Boolean doEval);
static Token	CondT(Boolean doEval);
static Token	CondF(Boolean doEval);
static Token	CondE(Boolean doEval);

#endif
/*
 * The parsing of conditional expressions is based on this grammar:
 *	E -> F || E
 *	E -> F
 *	F -> T && F
 *	F -> T
 *	T -> defined(variable)
 *	T -> symbol
 *	T -> ( E )
 *	T -> ! T
 *	op -> == | != | > | < | >= | <=
 *
 * 'symbol' is some other symbol to which the default function (condDefProc)
 * is applied.
 *
 * Tokens are scanned from the 'condExpr' string. The scanner (CondToken)
 * will return And for '&' and '&&', Or for '|' and '||', Not for '!',
 * LParen for '(', RParen for ')' and will evaluate the other terminal
 * symbols, using either the default function or the function given in the
 * terminal, and return the result as either True or False.
 *
 * All Non-Terminal functions (CondE, CondF and CondT) return Err on error.
 */

/*-
 * Structures to handle elegantly the different forms of #if's. The
 * last two fields are stored in condInvert and condDefProc, respectively.
 */
static Boolean	  CondDoDefined();
static Boolean	  CondDoNotZero();

static struct If {
    char	*form;	      /* Form of if */
    int		formlen;      /* Length of form */
    Boolean	doNot;	      /* TRUE if default function should be negated */
    Boolean	(*defProc)(); /* Default function to apply */
} ifs[] = {
    {"ifdef",	  5,	  FALSE,  CondDoDefined},
    {"ifndef",	  6,	  TRUE,	  CondDoDefined},
    {"if",	  2,	  FALSE,  CondDoNotZero},
    {(char *)0,	  0,	  FALSE,  (Boolean (*)())0}
};

static Boolean	  condInvert;	    	/* Invert the default function */
static Boolean	  (*condDefProc)(); 	/* Default function to apply */
static char 	  *condExpr;	    	/* The expression to parse */
static Token	  condPushBack=None;	/* Single push-back token used in
					 * parsing */

#define	MAXIF		30	  /* greatest depth of #if'ing */

static Boolean	  condStack[MAXIF]; 	/* Stack of conditionals's values */
static int  	  condTop = MAXIF;  	/* Top-most conditional */
static int  	  skipIfLevel=0;    	/* Depth of skipped conditionals */
static Boolean	  skipLine = FALSE; 	/* Whether the parse module is skipping
					 * lines */

static Token	  CondT(), CondF(), CondE();

/*-
 *-----------------------------------------------------------------------
 * CondPushBack --
 *	Push back the most recent token read. We only need one level of
 *	this, so the thing is just stored in 'condPushback'.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	condPushback is overwritten.
 *
 *-----------------------------------------------------------------------
 */
static void
CondPushBack (Token t)	/* Token to push back into the "stream" */
{
    condPushBack = t;
}

/*-
 *-----------------------------------------------------------------------
 * CondGetArg --
 *	Find the argument of a built-in function.
 *
 * Results:
 *	The length of the argument and the address of the argument.
 *
 * Side Effects:
 *	The pointer is set to point to the closing parenthesis of the
 *	function call.
 *
 *-----------------------------------------------------------------------
 */
static int
CondGetArg (char    	  **linePtr,
	    char    	  **argPtr,
	    char    	  *func,
	    Boolean 	  parens) /* TRUE if arg should be bounded by parens */
{
    register char *cp;
    int	    	  argLen;
    register Buffer buf;

    cp = *linePtr;
    if (parens) {
	while (*cp != '(' && *cp != '\0') {
	    cp++;
	}
	if (*cp == '(') {
	    cp++;
	}
    }

    if (*cp == '\0') {
	/*
	 * No arguments whatsoever. Because 'make' and 'defined' aren't really
	 * "reserved words", we don't print a message. I think this is better
	 * than hitting the user with a warning message every time s/he uses
	 * the word 'make' or 'defined' at the beginning of a symbol...
	 */
	*argPtr = cp;
	return (0);
    }

    while (*cp == ' ' || *cp == '\t') {
	cp++;
    }

    /*
     * Create a buffer for the argument and start it out at 16 characters
     * long. Why 16? Why not?
     */
    buf = Buf_Init(16);

    while ((strchr(" \t)&|", *cp) == 
	    (char *)NULL) && (*cp != '\0')) {
      Buf_AddB(buf, (B)*cp);
      cp++;
    }

    Buf_AddB(buf, (B)'\0');
    *argPtr = (char *)Buf_GetAll(buf, &argLen);
    Buf_Destroy(buf, FALSE);

    while (*cp == ' ' || *cp == '\t') {
	cp++;
    }
    if (parens && *cp != ')') {
	yyerror( "Missing closing parenthesis for %s()",
		     (unsigned long)func, 0);
	return (0);
    } else if (parens) {
	/*
	 * Advance pointer past close parenthesis.
	 */
	cp++;
    }
    
    *linePtr = cp;
    return (argLen);
}

/*-
 *-----------------------------------------------------------------------
 * CondDoNotZero --
 *	Handle the Boolean TRUE function for conditionals.
 *
 * Results:
 *	TRUE if the given variable is not zero.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
CondDoNotZero (int   argLen,
	       char *arg)
{
    char    savec = arg[argLen];
    Boolean result;

    arg[argLen] = '\0';
    if (atoi(arg) != 0) {
	result = TRUE;
    } else {
	result = FALSE;
    }
    arg[argLen] = savec;
    return (result);
}




/*-
 *-----------------------------------------------------------------------
 * CondDoDefined --
 *	Handle the 'defined' function for conditionals.
 *
 * Results:
 *	TRUE if the given variable is defined.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
CondDoDefined (argLen, arg)
    int	    argLen;
    char    *arg;
{
    char    savec = arg[argLen];
    Boolean result;

    arg[argLen] = '\0';
    if (Scan_MacroIsDefined(arg)) {
	result = TRUE;
    } else {
	result = FALSE;
    }
    arg[argLen] = savec;
    return (result);
}






/*-
 *-----------------------------------------------------------------------
 * CondToken --
 *	Return the next token from the input.
 *
 * Results:
 *	A Token for the next lexical token in the stream.
 *
 * Side Effects:
 *	condPushback will be set back to None if it is used.
 *
 *-----------------------------------------------------------------------
 */
static Token
CondToken(Boolean doEval)
{
    Token	  t;

    if (condPushBack == None) {
	while (*condExpr == ' ' || *condExpr == '\t') {
	    condExpr++;
	}
	switch (*condExpr) {
	    case '(':
		t = LParen;
		condExpr++;
		break;
	    case ')':
		t = RParen;
		condExpr++;
		break;
	    case '|':
		if (condExpr[1] == '|') {
		    condExpr++;
		}
		condExpr++;
		t = Or;
		break;
	    case '&':
		if (condExpr[1] == '&') {
		    condExpr++;
		}
		condExpr++;
		t = And;
		break;
	    case '!':
		t = Not;
		condExpr++;
		break;
	    case '\n':
	    case '\0':
		t = EndOfFile;
		break;
	    default: {
		Boolean (*evalProc)();
		Boolean invert = FALSE;
		char	*arg;
		int	arglen;
		
		if (strncmp (condExpr, "defined", 7) == 0) {
		    /*
		     * Use CondDoDefined to evaluate the argument and
		     * CondGetArg to extract the argument from the 'function
		     * call'.
		     */
		    evalProc = CondDoDefined;
		    condExpr += 7;
		    arglen = CondGetArg (&condExpr, &arg, "defined", TRUE);
		    if (arglen == 0) {
			condExpr -= 7;
			goto use_default;
		    }
		} else {
		    /*
		     * The symbol is itself the argument to the default
		     * function. We advance condExpr to the end of the symbol
		     * by hand (the next whitespace, closing paren or
		     * binary operator) and set to invert the evaluation
		     * function if condInvert is TRUE.
		     */
		use_default:
		    invert = condInvert;
		    evalProc = condDefProc;
		    arglen = CondGetArg(&condExpr, &arg, "", FALSE);
		}

		/*
		 * Evaluate the argument using the set function. If invert
		 * is TRUE, we invert the sense of the function.
		 */
		t = (!doEval || (* evalProc) (arglen, arg) ?
		     (invert ? False : True) :
		     (invert ? True : False));
		free((malloc_t)arg);
		break;
	    }
	}
    } else {
	t = condPushBack;
	condPushBack = None;
    }
    return (t);
}

/*-
 *-----------------------------------------------------------------------
 * CondT --
 *	Parse a single term in the expression. This consists of a terminal
 *	symbol or Not and a terminal symbol (not including the binary
 *	operators):
 *	    T -> defined(variable) | make(target) | exists(file) | symbol
 *	    T -> ! T | ( E )
 *
 * Results:
 *	True, False or Err.
 *
 * Side Effects:
 *	Tokens are consumed.
 *
 *-----------------------------------------------------------------------
 */
static Token
CondT(Boolean doEval)
{
    Token   t;

    t = CondToken(doEval);

    if (t == EndOfFile) {
	/*
	 * If we reached the end of the expression, the expression
	 * is malformed...
	 */
	t = Err;
    } else if (t == LParen) {
	/*
	 * T -> ( E )
	 */
	t = CondE(doEval);
	if (t != Err) {
	    if (CondToken(doEval) != RParen) {
		t = Err;
	    }
	}
    } else if (t == Not) {
	t = CondT(doEval);
	if (t == True) {
	    t = False;
	} else if (t == False) {
	    t = True;
	}
    }
    return (t);
}

/*-
 *-----------------------------------------------------------------------
 * CondF --
 *	Parse a conjunctive factor (nice name, wot?)
 *	    F -> T && F | T
 *
 * Results:
 *	True, False or Err
 *
 * Side Effects:
 *	Tokens are consumed.
 *
 *-----------------------------------------------------------------------
 */
static Token
CondF(Boolean doEval)
{
    Token   l, o;

    l = CondT(doEval);
    if (l != Err) {
	o = CondToken(doEval);

	if (o == And) {
	    /*
	     * F -> T && F
	     *
	     * If T is False, the whole thing will be False, but we have to
	     * parse the r.h.s. anyway (to throw it away).
	     * If T is True, the result is the r.h.s., be it an Err or no.
	     */
	    if (l == True) {
		l = CondF(doEval);
	    } else {
		(void) CondF(FALSE);
	    }
	} else {
	    /*
	     * F -> T
	     */
	    CondPushBack (o);
	}
    }
    return (l);
}

/*-
 *-----------------------------------------------------------------------
 * CondE --
 *	Main expression production.
 *	    E -> F || E | F
 *
 * Results:
 *	True, False or Err.
 *
 * Side Effects:
 *	Tokens are, of course, consumed.
 *
 *-----------------------------------------------------------------------
 */
static Token
CondE(Boolean doEval)
{
    Token   l, o;

    l = CondF(doEval);
    if (l != Err) {
	o = CondToken(doEval);

	if (o == Or) {
	    /*
	     * E -> F || E
	     *
	     * A similar thing occurs for ||, except that here we make sure
	     * the l.h.s. is False before we bother to evaluate the r.h.s.
	     * Once again, if l is False, the result is the r.h.s. and once
	     * again if l is True, we parse the r.h.s. to throw it away.
	     */
	    if (l == False) {
		l = CondE(doEval);
	    } else {
		(void) CondE(FALSE);
	    }
	} else {
	    /*
	     * E -> F
	     */
	    CondPushBack (o);
	}
    }
    return (l);
}

/*-
 *-----------------------------------------------------------------------
 * Cond_Eval --
 *	Evaluate the conditional in the passed line. The line
 *	looks like this:
 *	    #<cond-type> <expr>
 *	where <cond-type> is any of if, ifdef,
 *	ifndef, elif, elifdef, elifndef
 *	and <expr> consists of &&, ||, !, defined(variable)
 *	and parenthetical groupings thereof.
 *
 * Results:
 *	COND_PARSE	if should parse lines after the conditional
 *	COND_SKIP	if should skip lines after the conditional
 *	COND_INVALID  	if not a valid conditional.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Cond_Eval (char *line)    /* Line to parse */
{
    struct If	    *ifp;
    Boolean 	    isElse;
    Boolean 	    value = FALSE; /* I think this is the correct initial
				    * value (TB)*/

    for (line++; *line == ' ' || *line == '\t'; line++) {
	continue;
    }

    /*
     * Find what type of if we're dealing with. The result is left
     * in ifp and isElse is set TRUE if it's an elif line.
     */
    if (line[0] == 'e' && line[1] == 'l') {
	line += 2;
	isElse = TRUE;
    } else if (strncmp (line, "endif", 5) == 0) {
	/*
	 * End of a conditional section. If skipIfLevel is non-zero, that
	 * conditional was skipped, so lines following it should also be
	 * skipped. Hence, we return COND_SKIP. Otherwise, the conditional
	 * was read so succeeding lines should be parsed (think about it...)
	 * so we return COND_PARSE, unless this endif isn't paired with
	 * a decent if.
	 */
	if (skipIfLevel != 0) {
	    skipIfLevel -= 1;
	    return (COND_SKIP);
	} else {
	    if (condTop == MAXIF) {
		yyerror ("if-less endif", 0, 0);
		return (COND_INVALID);
	    } else {
		skipLine = FALSE;
		condTop += 1;
		return (COND_PARSE);
	    }
	}
    } else {
	isElse = FALSE;
    }
    
    /*
     * Figure out what sort of conditional it is -- what its default
     * function is, etc. -- by looking in the table of valid "ifs"
     */
    for (ifp = ifs; ifp->form != (char *)0; ifp++) {
	if (strncmp (ifp->form, line, ifp->formlen) == 0) {
	    break;
	}
    }

    if (ifp->form == (char *) 0) {
	/*
	 * Nothing fit. If the first word on the line is actually
	 * "else", it's a valid conditional whose value is the inverse
	 * of the previous if we parsed.
	 */
	if (isElse && (line[0] == 's') && (line[1] == 'e')) {
	    if (condTop == MAXIF) {
		yyerror ("if-less else", 0, 0);
		return (COND_INVALID);
	    } else if (skipIfLevel == 0) {
		value = !condStack[condTop];
	    } else {
		return (COND_SKIP);
	    }
	} else {
	    /*
	     * Not a valid conditional type. No error...
	     */
	    return (COND_INVALID);
	}
    } else {
	if (isElse) {
	    if (condTop == MAXIF) {
		yyerror ("if-less elif", 0, 0);
		return (COND_INVALID);
	    } else if (skipIfLevel != 0) {
		/*
		 * If skipping this conditional, just ignore the whole thing.
		 * If we don't, the user might be employing a variable that's
		 * undefined, for which there's an enclosing ifdef that
		 * we're skipping...
		 */
		return(COND_SKIP);
	    }
	} else if (skipLine) {
	    /*
	     * Don't even try to evaluate a conditional that's not an else if
	     * we're skipping things...
	     */
	    skipIfLevel += 1;
	    return(COND_SKIP);
	}

	/*
	 * Initialize file-global variables for parsing
	 */
	condDefProc = ifp->defProc;
	condInvert = ifp->doNot;
	
	line += ifp->formlen;
	
	while (*line == ' ' || *line == '\t') {
	    line++;
	}
	
	condExpr = line;
	condPushBack = None;
	
	switch (CondE(TRUE)) {
	    case True:
		if (CondToken(TRUE) == EndOfFile) {
		    value = TRUE;
		    break;
		}
		goto err;
		/*FALLTHRU*/
	    case False:
		if (CondToken(TRUE) == EndOfFile) {
		    value = FALSE;
		    break;
		}
		/*FALLTHRU*/
	    case Err:
	    err:
		yyerror("Malformed conditional (%s)",
			     (unsigned long)line, 0);
		return (COND_INVALID);
	    default:
		fprintf(stderr, "Bad choice for switch in cond.c:673\n");
		break;
	}
    }
    if (!isElse) {
	condTop -= 1;
    } else if ((skipIfLevel != 0) || condStack[condTop]) {
	/*
	 * If this is an else-type conditional, it should only take effect
	 * if its corresponding if was evaluated and FALSE. If its if was
	 * TRUE or skipped, we return COND_SKIP (and start skipping in case
	 * we weren't already), leaving the stack unmolested so later elif's
	 * don't screw up...
	 */
	skipLine = TRUE;
	return (COND_SKIP);
    }

    if (condTop < 0) {
	/*
	 * This is the one case where we can definitely proclaim a fatal
	 * error. If we don't, we're hosed.
	 */
	yyerror ("Too many nested if's. %d max.", MAXIF, 0);
	return (COND_INVALID);
    } else {
	condStack[condTop] = value;
	skipLine = !value;
	return (value ? COND_PARSE : COND_SKIP);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Cond_End --
 *	Make sure everything's clean at the end of a makefile.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	yyerror will be called if open conditionals are around.
 *
 *-----------------------------------------------------------------------
 */
void
Cond_End(void)
{
    if (condTop != MAXIF) {
      yyerror("%d open conditional%s", MAXIF-condTop,
	      (unsigned long)(MAXIF-condTop == 1 ? "" : "s"));
    }
    condTop = MAXIF;
}
