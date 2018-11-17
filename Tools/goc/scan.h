/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  goc -- Definitions file for scanner
 * FILE:	  scan.h
 *
 * AUTHOR:  	  Tony Requist
 *
 * DESCRIPTION:
 *	Header file for scanner
 *
 * 	$Id: scan.h,v 1.17 96/07/08 17:38:11 tbradley Exp $
 *
 ***********************************************************************/
#ifndef _SCAN_H_
#define _SCAN_H_

/* Lexical contexts that the scanner can be in */

typedef enum {
    LC_NONE,			/* 
				 * Not parsing anything in particular,
				 * just looking for @ to signal goc stuff.
				 * This will send input to yyout until
				 * it detects goc input.
				 */
    LC_PARSE,			/* Standard parsing,  punctuation, syms */
    LC_PARSE_NO_LOOKUP,		/* Standard parsing, no reserved word lookup */
    LC_STRING_SEMI_COLON,	/* Parse chars as fakestring until ; */
    LC_STRING_COMMA,		/* Parse chars as fakestring until , */
    LC_STRING_RIGHT_PAREN,	/* Parse chars as fakestring until ) */
    LC_STRING_COLON,            /* for parent/child object destinations */
    LC_STRING_CLOSE_BRACE,      /* for [asdf] */
    LC_CLOSE_CURLY_OR_STRING,  /* just for gstrings. returns everything up*/
                               /* to the next string or '}' as a FAKESTRING */
                               /* returns a string as STRING. */
    /*       
     * The next two are for scanning type declarations and related things.
     *
     * these two do the same thing: scan chars as a string up to the next
     *  ',' ';' '=' ')' 
     * in LC_STRING_MATCH_PARENS, scan things surrounded with parentheses too.
     * in LC_STRING_NO_MATCH_PARENS, '(' is also a delimiter 
     *
     */

    LC_TYPE_STRING_MATCH_PARENS, /* parse a normal type decl or msg_params */
    LC_TYPE_STRING_NO_MATCH_PARENS, /* parse a method decl */

    /*
     * This is used to scan parts of an @send/@call (the flags and cast).
     * 
     * This one reads a list of flags (each prefaced with a comma) and only
     * returns the flags (NOT the commas).
     *
     * After the flags may come a msg cast (e.g. {MSG_FOO}), or the object
     * dest. if there is a cast, only the MSG is returned, not the 
     * characters '{' '}' that delimit it.
     *
     * After scanning the cast and flags, the scanner will switch
     * lexContexts and enter the PARSE_OBJ_DEST scanning mode to get the 
     * destination of the message. This is necessary because the object
     * destination is several tokens long.
     * 
     */
    LC_PARSE_OBJ_FLAGS_AND_CAST, /* Used to read the comma separated list of */
                                 /* flags before an object destination.      */
                                 /* inserts a ';' into the token stream at   */
                                 /* the end of the flag list.                */
    LC_PARSE_OBJ_DEST,
    LC_PARSE_CALLSUPER_OBJ_DEST, /* Just like LC_PARSE_OBJ_DEST, but it      */
                                 /* first for "()" before looking for and    */
                                 /* objdest. This state exists because after */
                                 /* the callsuper, one may either have an    */
                                 /* objdest or just "()" to signal the end   */
                                 /* before, one used ";" instead of "()",    */
                                 /* but that doesn't make sense for:         */
                                 /* if(@callsuper;), and besides that form   */
                                 /* used to put out a semi-colon too.        */
                                 /* So what this context does is look forward*/
                                 /* to see if there is "()" ahead. If so, it */
                                 /* returns them as characters. If those are */
                                 /* not what comes next, it switches into    */
                                 /* LC_PARSE_OBJ_DEST to read them as strings*/
                                 /* so " (  )" will get read as '(' and ')', */
                                 /* but "(a),(optr) b:" would get returned as*/
                                 /* FAKESTRING ',' FAKESTRING ':'.           */
} LexicalContexts;

extern LexicalContexts lexContext;

enum tokNum{BEFORE_FILE,FIRST_OF_FILE,AFTER_FIRST_OF_FILE };
extern enum tokNum  whichToken;
/* 
 * Tells the scanner whether or not it should output newlines or a directive
 * after scanning a multi-line thing with LC_STRING_XXX.
 * 
 * Default is TRUE. For @send,@call and @callsuper, which generate function
 * calls _in_place_, it should be false.
 */
extern int scannerShouldRealignOutputAndInputAfterLC_STRING;

extern 	char preTokenBuffer[];
extern 	char yytext[];

extern int	parse_TokenStart, parse_TokenEnd;
extern Boolean	parse_ScanningAChunk;

extern 	Boolean Scan_IdentHadApostropheBeforeIt;

extern	void Scan_WarnForForwardChunk (char *ident);

extern  unsigned short Scan_ScanSJISChar(unsigned char **str);
extern  Boolean Scan_CheckForConditional(void);

extern char *OurStrPos(char *str, char *find);
extern void SplitTypeString(char *typeDecl,char **ctype,char **id,char **typeSuffix);

char *OurStrPos(char *str, char *find);
void SplitTypeString(char *typeDecl,char **ctype,char **id,char **typeSuffix);


char 	*Scan_MacroIsUndefForFromFile (char *name,char *file);

extern void Scan_OutputMultiByteString(char prefix, char *str);


extern void Scan_StartOptimize(void);

extern Boolean Scan_MacroIsDefined (char *macroName);

extern void Scan_Unput(char c);

/*
 * Structure used for interpolating text into the input stream from macros
 */

#define MACRO_BLOCK_SIZE    32
#define NUM_MACRO_BLOCKS    20	/* Number of MBlk's to allocate at once */




/*
 * Structure describing a macro argument. Chained with first arg first in the
 * list.
 */
typedef struct _Arg {
    char    	  *value;
    int	    	  freeIt;
    struct _Arg	  *next;
} Arg;

/* XXX the Mblk structure might point to a MArg structure. XXX */
/* They are the same except for the text field. Tricky         */
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
 *  Used to hold the three types of macro defns:
 *
 *   @define FOO             text   (numParams = -1)
 *   @define FOO()           text   (numParams =  0)
 *   @define FOO(a,b,c,...)  text   (numParams =  N)
 */

typedef struct {
  MBlk *body;       /* list of blocks returned by yyreadmacrobody()     */
  int numParams;    /* -1 if macro is a constants, 0 if blank, else n */
  char *name;
  char *fileName;   /* file where defined */
  int   lineNo;     /* line where defined */
} Mac;

typedef struct _MacState {
    MBlk    	  	*block;	    /* Block being read */
    char    	  	*ptr;	    /* Position in same */
    int	    	  	count;	    /* # chars remaining */
    MBlk    	  	**maps;	    /* Argument maps */
    int	    	  	numMaps;    /* # of same */
    char    	    	*pbBot;	    /* Bottom of the pushback stack */
    struct _MacState	*next;	    /* Next frame in stack */
}	MacState;



#endif /* _SCAN_H_ */



