/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Parser-Scanner interface definitions
 * FILE:	  scan.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for communication between the scanner and parser.
 *	Not in parse.h as that's created automatically by bison.
 *
 *
 * 	$Id: scan.h,v 1.17 95/09/13 23:07:02 adam Exp $
 *
 ***********************************************************************/
#ifndef _SCAN_H_
#define _SCAN_H_

/*
 * State saved when an INCLUDE directive is seen.
 */
typedef struct _File {
    ID    	    name;    	/* File's name */
    int		    line;    	/* Current line */
    FILE    	    *file;    	/* Stream open to input file */
    int	    	    iflevel;	/* Conditional level on entry */
    void    	    *segstack;	/* Top entry in segment stack on
				 * entry */
    SymbolPtr	    chunk;  	/* Any chunk open on entry */
    struct _File    *next;    	/* Next file in stack */
} File;

/*
 * Structure describing a macro argument. Chained with first arg first in the
 * list.
 */
typedef struct _Arg {
    char    	  *value;
    int	    	  freeIt;
    struct _Arg	  *next;
}	Arg;

/*
 * Structure used for interpolating text into the input stream from macros
 * or equates.
 */
#define MACRO_BLOCK_SIZE    32

typedef struct _MBlk {
    short   	    length;    	/* Number of characters in the block */
    short   	    dynamic;	/* Non-zero if block individually allocated
				 * and should be freed if no longer needed */
    struct _MBlk    *next;
    char    	    text[MACRO_BLOCK_SIZE];
}	MBlk;

/*
 * Record to indicate a macro argument should be interpolated
 */
typedef struct _MArg {
    short     	    argNum;   	/* -Argument number */
    short   	    dynamic;	/* Nonzero if record should be freed if
				 * no longer needed */
    struct _MBlk    *next;    	/* Continuation of macro */
}	MArg;

/*
 * Structure describing a conditional.
 */
typedef struct {
    ID	    file;   	/* File in which conditional was started */
    int	    line;   	/* Line at which it started */
    int	    value;  	/* Value of conditional (1 if parsing continued,
			 * 0 if skip started, -1 if else was seen) */
} IfDesc;

typedef enum {
    MM_SMALL, MM_MEDIUM, MM_COMPACT, MM_LARGE, MM_HUGE
} MemoryModel;

typedef enum {
    LANG_PASCAL, LANG_BASIC, LANG_FORTRAN, LANG_C
} Language;

typedef union {
    const OpCode *opcode;	    /* For opcodes */
    long    	number;   	    /* For integer constants */
    char	*string;	    /* For identifiers and string constants */
    Symbol	*sym;		    /* For SYM variants */
    TypePtr	type;		    /* For type rule */
    Arg		*arg;		    /* Macro argument */
    MBlk	*block;		    /* EQU value */
    ID	    	ident;	    	    /* IDENT value */
    struct {
	MBlk	    *text;
	short 	    numArgs;
	short 	    numLocals;
    }		macro;		    /* MACRO definition */
    struct {
	byte	    flags;  	    	/* Attributes defined */
#define SA_COMBINE  	1
#define SA_ALIGNMENT	2
#define SA_CLASS    	4
        byte	    comb;		/* Combine type */
	short	    align;		/* Alignment */
	ID	    class;		/* Class */
    }		seg;		    /* Segment attributes */
    struct _exprSave {
	Expr	    *curExpr;   	/* Saved expression descriptor */
	int 	    curExprSize;	/* Saved curExprSize */
    }	    	exprSave;   	    /* Saved expression (for cexpr) */
    struct {
	Symbol	    *class; 	    	/* Superclass (may be null) */
	int 	    flags;  	    	/* Flags for new class */
    }	    	classDecl;    	    /* Class declaration parameters */
    struct {
	Expr	    *initRoutine;   	/* Expr describing class
					 * initialization routine */
	Expr	    *flags; 	    	/* Expr giving extra flags */
    }	    	classDef;
    Expr    	*expr;	    	    /* EXPR token */
    struct {
	short	    size;    	    	/* Base size for type */
	short	    start;    	    	/* First value */
	short	    skip;   	    	/* Skip value for type */
	byte	    flags;  	    	/* SYM_ETYPE_* */
    } 	    	etype;	    	    /* DEFETYPE args */
    struct {
	FixProc	    *proc;  	    	/* Code generator to call */
	const OpCode*op;    	    	/* OpCode to pass it */
    }	    	prefix;     	    /* prefixInst value */
    struct {
	Symbol	    *curProc;	    	/* curProc before methodList */
	Symbol	    *curClass;	    	/* curClass before methodList */
    }	    	extMeth;    	    /* Saving place for external method decl */
    MemoryModel	model;
    Language	lang;
} SemVal;

#define YYSTYPE SemVal

typedef int 	LexProc(YYSTYPE *, ...);    /* Return a token */
typedef char	InputProc();	    	    /* Return a char to yylex */
typedef int 	WrapProc();	    	    /* Return 0 if not at real EOF */
typedef const OpCode *OpProc(const char *,  /* Search a table for an opcode */
			     unsigned int len); 	    	 



extern File 	*curFile; 	/* Current input file */
extern int  	ignore;   	/* TRUE if should ignore include directives and
				 * other drastic things */
extern int  	noSymTrans;	/* TRUE if shouldn't translate identifiers to
				 * Symbol *'s */
extern int  	snarfLine;  	/* Non-zero if rest of line should be returned
				 * as a string */
extern int  	defStruct;  	/* Non-zero if <> strings should be treated
				 * specially, allowing them to span multiple
				 * lines with comments stripped out. */
extern int  	firstArg;   	/* First macro argument being fetched */
extern int  	inmacro;    	/* Token read from macro */
extern int  	showmacro;  	/* Non-zero if all characters from a macro
				 * block are to be sent to stdout */
extern int  	yylineno; 	/* Current line number in file */
extern int  	makeDepend;	/* TRUE if should print a file's dependencies
				 * to stdout. */
extern FILE 	*yyin;    	/* Stream for current input file */


extern LexProc 	*yylex;     	/* Function to return a token to the parser */
/*
 * Vectors used by standard scanners (yystdlex and yymacarglex)
 */
extern InputProc *yyinput;	/* Function to read a character (pushback
				 * handled automatically) */
extern WrapProc	*yywrap;    	/* Function to tell if at real EOF */

/*
 * Standard values for above vectors, provided by scan.c
 */
extern LexProc 	yystdlex;	/* Standard scanner */
extern LexProc  yymacarglex;	/* Scanner for macro args */
extern WrapProc	yystdwrap;	/* Standard wrapup function */

/*
 * Pushback manipulation. Before switching yyinput, should call
 * Scan_SavePB to hide any pushback from the previous yyinput. When restoring
 * yyinput, call Scan_RestorePB
 */
extern void 	Scan_SavePB(void);	/* Preserve current pushback */
extern void 	Scan_RestorePB(void);/* Recover previously-saved pushback */

/*
 * For setting the search functions used by yystdlex when seeing if a string
 * is a reserved word. The function takes a string and a length and looks
 * the string up in its own table, returning a pointer to a constant
 * OpCode structure describing the opcode/keyword/thing.
 */
extern int  	Scan_UseOpProc(OpProc *proc);
extern void 	Scan_DontUseOpProc(int idx);

/*
 * For main.c.
 */
extern void	Scan_Init(void);

extern void	yystartmacro(Symbol *which, /* Macro to interpolate */
			     Arg *args); /* Arguments to pass */


extern OpProc	findClassToken;
extern OpProc 	findSegToken;
extern OpProc	findOpcode;
extern OpProc	findModelToken;
extern int  	opIdx;

/*
 * Discard input to the end of a conditional. If orElse is non-zero, it
 * means an ELSE or ELSEIF may also terminate the scan. When the function
 * returns...to be continued later.
 */
extern void 	Scan_ToEndif(int orElse);

/*
 * Things defined by parser module
 */
extern int  	dot;	    /* Current offset in segment */
extern SymbolPtr curSeg;	    /* Current segment */
extern int  	iflevel;    /* Current level of nested conditionals */
extern IfDesc	ifStack[];  /* Stack of nested conditionals */
extern void 	Parse_FileChange(int entry);
extern int  	Parse_CheckClosure(int *okPtr, int checkSegStack);
extern SymbolPtr curChunk;

#endif /* _SCAN_H_ */
