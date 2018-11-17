/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  goc -- lexical analyzer
 * FILE:	  scan.c
 *
 * AUTHOR:  	  Tony Requist
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	yystdlex	    Scan off a token and return it
 *	Scan_Init 	    Initialization function
 *      Scan_MacroIsDefined tell if ident is defined as macro
 *
 * DESCRIPTION:
 *	Lexical analyzer for goc.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: scan.c,v 1.76 96/07/09 17:09:21 jimmy Exp $";
#endif lint

/* MetaBlam is ridulously picky about signed/unsigned chars. e.g., unsigned */
/* chars can never equal EOF. */
#if defined(__HIGHC__)
#pragma Off(Char_default_unsigned)
#pragma On(Char_is_rep)
#pragma Off(Behaved)
#endif

#include    <config.h>
#include    "goc.h"
#include    "cond.h"
#include    "parse.h"
#include    "scan.h"
#include    "hash.h"
#include    "stringt.h"
#include    "symbol.h"
#include    "map.h"
#include    "depends.h"
#include    <stdio.h>
#include    <ctype.h>
#include    <malloc.h>
#include    <compat/string.h>
#include    <compat/stdlib.h>
#include    <compat/file.h>
#include    <assert.h>
#include    "japan.h"

#if defined(unix)
#include    <memory.h>
#include    <unistd.h>
#endif


int yystdlex(void);
int  (*yylex)(void) = yystdlex;
static int IsLineAConditional (char *buf);

/* see ScanStringToTopLevelDelimiters() */
int scannerShouldRealignOutputAndInputAfterLC_STRING = 1;

/* a line can be one of the following */
enum PPDirectiveType  {noDirective,definition,inclusion,self,macroExpansion};


#define MALLOC_CHECK(X) do{                                     \
                           if(NULL == (X)){                     \
                             fprintf(stderr,"malloc failed\n"); \
			     exit(1);                           \
			    }                                   \
                         }while(0)

Boolean Scan_IdentHadApostropheBeforeIt;

/*
 * SCANNED_BYTE_IS_UNICODE_CHAR is or'd into the value returned from
 * ScanSJISByte to indicate that the value is a unicode character, and
 * not part of a SJIS sequence.
 */
#define SCANNED_BYTE_IS_UNICODE_CHAR 0x10000

/*
 * External interface variables
 */
extern FILE       *foutput;       /* so ScanNoContext can blast out chars */
extern YYSTYPE 	  yylval;
int 	    	  lexdebug=0;
#ifdef LEXDEBUG
#define DBPRINTF(args) (lexdebug)? fprintf args : 0
#else
#define DBPRINTF(args)
#endif /* LEXDEBUG */


#define F   1	/* firstid */
#define O   2	/* otherid */
#define B   3	/* both */
#define N   0	/* none */
#define T   4	/* macro argument terminator */
#define E   8	/* end-of-line character */
static const unsigned char  cbits[] = {
    N,	    	    	    	    	/* EOF */
    T,	N,  N,	N,  N,	N,  N,	N,  	/*  0 -  7 */
    N,	N,  N,  N,  N,  N,  N,	N,  	/*  8 - 15 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 16 - 23 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 24 - 31 */
    T,	N,  N, 	N,  N,	N,  N,	N,  	/* sp ! " # $ % & ' */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* (  ) * + , - . / */
    O,	O,  O,	O,  O,	O,  O,	O,  	/* 0  1 2 3 4 5 6 7 */
    O,	O,  N,	N,  N,	N,  N,	N,  	/* 8  9 : ; < = > ? */
    N,	B,  B,	B,  B,	B,  B,	B,  	/* @  A B C D E F G */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* H  I J K L M N O */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* P  Q R S T U V W */
    B,	B,  B,	N,  N, 	N,  N,	B,  	/* X  Y Z [ \ ] ^ _ */
    N,	B,  B,	B,  B,	B,  B,	B,  	/* `  a b c d e f g */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* h  i j k l m n o */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* p  q r s t u v w */
    B,	B,  B,	N,  N, 	N,  N,	N,  	/* x  y z { | } ~ del */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 128 - 135 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 136 - 143 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 144 - 151 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 152 - 159 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 160 - 167 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 168 - 175 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 176 - 183 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 184 - 191 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 192 - 199 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 200 - 207 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 208 - 215 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 216 - 223 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 224 - 231 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 232 - 239 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 240 - 247 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 248 - 255 */
};

#define isfirstid(c)	((cbits+1)[c]&F)
#define isotherid(c)	((cbits+1)[c]&O)
#define isterm(c)   	((cbits+1)[c]&T)
#define iseol(c)	((cbits+1)[c]&E)

/* XXX  this should  go away XXX */
#define IS_IDENT_CHAR(x) isotherid(x)






/*
 * macro code is extracted from "/s/p/Tools/esp/scan.c"
 *
 * MACRO  and input stuff
 */



/*
 * Pushback definitions. The pushback buffer is arranged as a stack whose
 * bottom shifts with the macro level. I.e. when a macro is pushed, the bottom
 * of the stack shifts to the current top so the characters pushed back in
 * the previous level are unavailable until a return to that level.
 */
#define MAX_PUSH_BACK	256
static char 	yysbuf[MAX_PUSH_BACK];
static char 	*yysbot = yysbuf;
static char	*yysptr = yysbuf;

/*
 *      When we read newlines, we inc the line count, and we might put them
 *      back and read them again and put them back and .....  Hence we need
 *      to see if it is a newline and adjust the line count accordingly.
 *
 *      This should remain a macro, because it gets called far too much.
 *
 *      This is a tricky macro though, because it can only use the char once.
 */
#define  unput(ch) (((*yysptr++ = ch) == '\n') ? yylineno-- : 0)





#define GET_BIT(b) (internalLexFlags & b)
#define SET_BIT(v,b) (internalLexFlags = v ? internalLexFlags|b:   \
		                             internalLexFlags&(~b))




#define ILF_IN_CONDITIONAL		(1<<0) /* 0 means look for cond */
#define ILF_VERBATIM			(1<<1) /* 1 means  input=output */
#define ILF_IN_STRING			(1<<2) /* no conditionals string */
#define ILF_RETURN_COMMENT_AS_NEWLINES  (1<<3) /* see note below */
#define ILF_IN_COMMENT			(1<<4) /* 1 means in comment */

typedef int lexFlags;
lexFlags internalLexFlags = ILF_VERBATIM;


#define GET_CONDITIONAL() (GET_BIT(ILF_IN_CONDITIONAL))
#define SET_CONDITIONAL(a) (SET_BIT(a,ILF_IN_CONDITIONAL))

/* used by ScanNoContext to say it wants no characters eliminated */
#define GET_VERBATIM() (GET_BIT(ILF_VERBATIM))
#define SET_VERBATIM(a) (SET_BIT(a,ILF_VERBATIM))

#define GET_IN_STRING() (GET_BIT(ILF_IN_STRING))
#define SET_IN_STRING(a) (SET_BIT(a,ILF_IN_STRING))

#define GET_IN_COMMENT() (GET_BIT(ILF_IN_COMMENT))
#define SET_IN_COMMENT(a) (SET_BIT(a,ILF_IN_COMMENT))

/*
 * This flag tells the scanner to return multi-line comments as
 * a series of newlines, and not output newlines or a directive to the
 * file.  Normally this flag isfalse, and the comment
 * reader (PreProcInput) will output newlines or a line directive for
 * the comment, AND RETURN A SINGLE SPACE.
 *
 * That doesn't work for gstrings though, because when we finally
 * output the chunk for the gstring, we need the output to match the
 * input, or the line number info will be off.
 *
 * Therefore the lexcial context for gstrings gets newlines for comments
 * that span multiple lines. The the lexical context calls
 * incRemovedNewLines() so that yystdlex will put out a directive or newlines
 * after the gstring. Because the newlines get stored in the string,
 * the chunk gets output with the newlines in them and everything works.
 *
 */

#define GET_COMMENT_AS_NEWLINES() \
    (GET_BIT(ILF_RETURN_COMMENT_AS_NEWLINES))
#define SET_COMMENT_AS_NEWLINES(a)   \
    (SET_BIT(a,ILF_RETURN_COMMENT_AS_NEWLINES))


extern FILE	*yyin;
int	yylineno=1;

/*
 * While Scanning a token, it might be split across multiple lines.
 * if it is, we'll just scan the token as though it were on one line,
 * but we need to make sure to adjust the line count and resynch the
 * input and output files.
 *
 * The sorts of lines that might do this are comments and escaped newlines.
 */
int numberOfNewlinesDeleted = 0;

/*
 * numberOfOpenBraces: Used to determine when we are inside a method or func.
 */
int numberOfOpenBraces = 0;

/*
 * curMethod: Used to determine whether we are inside a method or not.
 */
extern Method *curMethod;


#ifndef MAX_TOKEN_LENGTH
#define MAX_TOKEN_LENGTH    400
#endif /* MAX_TOKEN_LENGTH */
char    	  yytext[(MAX_TOKEN_LENGTH > 1024)?MAX_TOKEN_LENGTH:1024];

/* buffer used to hold conditional lines for the cond module */
char conditionalLineBuffer[1000];


/* This tells the scanner how to make tokens from input characters */
LexicalContexts lexContext = LC_NONE;



/*
 * Structure defining a reserved word
 */
typedef struct ReservedWord {
    char    *name;
    int	    token;
} ReservedWord;

/*
 * Keyword determination
 */
static Hash_Table  ReservedWords;    /* Table of opcodes hashed by name */
static Hash_Table  macroWords;       /* table of macros */


#define PTR_TO_LAST_CHAR_OF_STRING(a)  ((a) + strlen(a) -1)


/*
 * constants that specify how a identifier-string gets classified
 *
 *   e.g. in certain contexts, the string "start" might be a keyword,
 *   or maybe just an identifier. The flags passed to ScanIdentifierThing
 *   determine what sort of token "start" is.
 */
#define  ICF_RES_ONLY      1
#define  ICF_RES_SYM       2
#define  ICF_RES_SYM_IDENT 3
#define  ICF_IDENT_ONLY    4




MBlk	    	*curBlock=0;	    /* Current text block in macro. 0 if
				     * not in macro */
char	    	*curMacPtr;	    /* Pointer into block */
int	    	curMacCount=0;      /* Number of characters remaining in the
				     * block. */
int	    	numMaps=0;
MBlk	    	**maps = 0;         /* maps for the current macro's args */


char **filesIncluded = NULL;        /* table of file names included so far */
int  numFilesIncluded = 0;          /* count of files included so far      */

File *curFile;




int	    	showmacro = 0;  /* show macros as they get expanded */



static MacState     *macros = (MacState *)NULL;
static MacState	    *freeState = (MacState *)NULL;



/*
 *  INPUT ROUTINES
 *
 *
 * PreProcInput: reads from PMFInput. This routine will strip out
 * 		comments, preform macro processing and  include files.
 *              Not called while scanning string constants.
 *
 *
 * PMFInput:	If there is pushback,
 *                 if the char to be returned is a newline
 *                    increment the linecount
 *                 return the pushback char
 *              else call MFInput()
 *
 * MFInput:
 *              returns macro or file input.
 * 		increments linecount on return (from ile input only)
 *
 *              it may (depending on internalLexFlags):
 *                   expand conditionals
 *             	     remove \r from file input
 * 		     remove escaped newlines
 *
 */

/*
 * This is the last character returned from the pushback/macro/file input
 * stream. It is necessary because MFInput checks it to see if it should
 * look for a conditional, which should only appear after a newline.
 *
 * The lastchar variable is global because the low-level routine  to get
 * characters from the pushback code is now just a macro, and therefore
 * has global scope.
 */
static char MFInput_lastChar = '\n';

/****************************************************
 *             PMFInput                             *
 ****************************************************
 *
 * PMFinput is the low-level input routine (macro), that returns
 * pushback/macro/file input.
 *
 *  Although this is somewhat ugly, and requires making MFInput_lastChar
 *  a global variable, it cuts down the number of calls to PMFInput by
 *  15%, so it's probably worth the trouble.
 *
 * STRATEGY:
 *
 *   return MFInput_lastChar, where that equals
 *    if there is pushback,
 *       the pushback char
 *    else the macro or file input
 *
 *    at the same time, if the pushback char is a newline, inc the linecount
 *
 * NOTE: this is the only routine that calls MFInput(), so it is the
 *    only routine to set MFInput_lastChar. If one must call MFInput,
 *    one must also set MFInput_lastChar to the returned value.
 */

#define PMFInput() (MFInput_lastChar =                                  \
		      ((yysptr > yysbot) ?                              \
	                ((yylineno += (*--yysptr=='\n'?1:0)),*yysptr)   \
		        : MFInput()))


/* macro to take a pathname and make output a #ifndef XXX #define XXX for */
/* a goh include of an optimized file */
/* We need this because if we @optimize files, we may wind up copying */
/* in a file into two generated files more than once, and we'll */
/* run into trouble at compile time */

/* If the OS uses a backslash for a delimter, do this extra step
 * to make sure we treat '/' and '\\' the same. */
#if (PATHNAME_SLASH == '\\')
#define ScanOutputIfndefDefine_DOS_CODE(name) \
    	{   /* if we're in the dos world, \ is a path separator */	 \
	    char *temp = strrchr((name), '\\');				 \
	    if(cp1 < temp){						 \
		cp1 = temp;						 \
	    }								 \
	}
#else
#define ScanOutputIfndefDefine_DOS_CODE(name)
#endif

#define ScanOutputIfndefDefine(name) if(foutput){                        \
	char *cp1,*cp2;							 \
                                                                         \
	cp2 = strrchr((name),'.');					 \
	*cp2 = '\0';							 \
	cp1 = strrchr((name), '/');					 \
	ScanOutputIfndefDefine_DOS_CODE(name)                            \
	cp1 = cp1?cp1+1:(name);						 \
	fprintf(foutput,"#ifndef __GOC%s\n#define __GOC%s\n",cp1,cp1); 	 \
	*cp2 = '.';						         \
}



typedef char	               InputProc(void);

static InputProc               MFInput;      /* input function */
static InputProc               PreProcInput;  /* input function */


/* we use this to keep track of @optimize, which must appear as the first */
/* token in a file */
enum tokNum whichToken = BEFORE_FILE;



/* other forward declarations */

static MBlk *NewBlock(void);
static void PushMacro(MBlk    *newBlock);
static void PopMacro(void);
static void yyfreemaps(MBlk **m, int count);

static void Scan_Include(void);
/*
static void ScanProcessStringForProtoMinorReferences(char *symName);
*/
static int yystdwrap(void);

static void ScanQuotedQuantityAndOutput(char delim);
static void ScanQuotedMultiByteQuantityAndOutput(char prefix, char delim);
static char ScanNoContext(void);
static char *CopyStringSection(char *start, char *end);
static void SkipWhiteSpace(void);
static int ScanIdentifierThing(YYSTYPE *yylv,char flags);
static int DevourRestOfComment(Boolean outputChars, Boolean cppComment);

static char *ScanQuotedConstantAndReturn(char delim,
				  Boolean nullTerminate,
				  char *firstCharOfStringPtr,
				  dynamic_buffer *buffer);
void    Scan_ScanMacroDef(void);
Boolean ShouldntDefineThisMacro(char *text);

static char *ScanStringViaTopLevelDelimiters(char delim1,
					     char delim2,
					     Boolean nullTerminate,
					     dynamic_buffer *buffer,
					     Boolean nestBraces);
static char *ScanStringToTopLevelDelimiters(char delim1, char delim2,
					    Boolean nestBraces);
static int ScanIntFromStream(char c);
static char *ScanIdentString(Boolean);

static MBlk * yyreadmacrobody(char **params, int numParams);
void  printmacro(Mac *macroPtr);

static void       Scan_ExpandMacro(Mac *macPtr);


static int ScanConditional(char *command,int index);
static int topLevelConditionalLineNo = 0;
static char *topLevelCondFileName;
void ProcessDirective(enum PPDirectiveType type, char *text);
enum PPDirectiveType PreProcessorDirectiveType(char *yytext);

Mac *DefineMacro(char *name,       /* name of macro                 */
		 char *fileName,   /* filename where defined        */
		 int lineNo,         /* line number of definition     */
		 int numParams,    /* number of parameters to macro */
		 MBlk *body);       /* result of yyreadmacrobody     */

/*
 * Scan_Self handles replacement of '@self' with pself/&pself/*pself/(*pself).
 */
static void Scan_Self(void);

/*
 * count the newlines in the string, and increment the global tally of
 * lines that the curren token spans.
 */
void       incRemovedNewLines(char *str);


/***********************************************************************
 *				MFInput
 ***********************************************************************
 * SYNOPSIS:	Standard input function to read from macro or file
 * CALLED BY:	PMFInput
 * RETURN:	character read
 * SIDE EFFECTS:curBlock, curMacCount, curMacPtr may change
 *
 * WARNING:  Don't EVER call this routine directly. Use PMFInput to get
 *           any pushback first. Also, always set MFInput_lastChar to
 *           the returned value, or conditionals will get screwed up.
 *
 * STRATEGY:
 *	If in a macro,
 *	    If no characters left,
 *	        fetch the next block.
 *		if next block is an argument, push to the argument text,
 *		    if it exists, and drop through to read its first char
 *		if the argument text is empty (its pointer is null), just
 *		    advance to the next block and try again.
 *	    Fetch the next character from the macro block and return it.
 *
 *	Else read a character from the input file.
 *         if it is an '@' sign and we should look for conditionals,
 *           and we are not scanning a string or already in a conditional,
 *           process the conditional (if it is one), returning an '@' if
 *           it isn't a conditional. If it is a condtional, THIS ROUTINE
 *           WILL OUTPUT A BUNCH OF NEWLINES OR A LINE DIRECTIVE.
 *         if it is a \r or an escaped newline, remove it if it is
 *           and we are not in verbatim mode, remove it and call
 *           ourselves again.
 *
 *         if it is a return, inc the linecount.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *      josh    9/92
 *	ardeb	4/ 3/89		Initial Revision
 *
 ***********************************************************************/
inline static char
MFInput(void)
{
    char c,c2;

    if (curBlock != (MBlk *)NULL) {
	/*
	 * In a macro -- fetch the next character from the current block
	 */
	if (curMacCount == 0) {             /* finished with this block */
	next_block:
	    curBlock = curBlock->next;
	    if (curBlock) {
		curMacCount = curBlock->length;
		if (curMacCount <= 0) {
		    /*
		     * If length is <= 0, it's actually a macro parameter. The
		     * length is the negation of the argument number, so
		     * fetch the argument from the -curMacCount'th entry
		     * in maps.
		     */
		    MBlk    *arg = maps[-curMacCount];

		    /*
		     * Signal push into argument. We need to know this so
		     * PopMacro can properly advance to the next block, as
		     * we don't want to do it here or we could end up with
		     * curBlock being null and just go back to the file,
		     * when in fact we need to pop another level.
		     */
		    curMacCount = -1;

		    if (arg) {
			PushMacro(arg);
		    } else {
			/*
			 * Argument is empty -- advance to the next block
			 */
		      goto next_block;
		    }
		  } else {
		    curMacPtr = curBlock->text;
		  }
	      } else {
		/*
		 * Pop the current macro state and recurse to fetch the next
		 * character. this will return any pushback that the last
		 * macro added, so it will work.
		 */
		PopMacro();
		return(PMFInput());
	      }
	  }
	/*
	 * Still in a macro -- predecrement the count of characters and
	 * return the next character in the macro
	 */
	curMacCount--;
	return(MFInput_lastChar = (*curMacPtr++));
    }
    /*
     * get a char from a file.
     * try to remove useless things from the input stream like:
     *   escaped newlines and \r.
     *
     * Also, keep track of the line number.
     * This is easy to do because the line number only changes after
     * reading a newline from a file.
     */
  next_char:

    switch(c = getc(yyin)){
	/*
	 * If we're not already processing a conditional, and we just read an
	 * '@' following a newline, look for conditionals
	 */
    case '@': {
	if(!GET_IN_STRING() && !GET_CONDITIONAL()&& MFInput_lastChar=='\n'){
	    /*If may be a conditional*/
	    int linesSkipped;

	    if((linesSkipped = Scan_CheckForConditional())){
		OutputLineDirectiveOrNewlines(linesSkipped -1);
		c = '\n';
	    }
	}
	break;
    }
    case '{':
	if(!GET_IN_STRING() && !GET_IN_COMMENT())
	    numberOfOpenBraces++;
	break;
    case '}':
	if(!GET_IN_STRING() && !GET_IN_COMMENT())
	    if (--numberOfOpenBraces == 0)
		curMethod = NullMethod;
	break;
    case '\r':          /* eliminate if possible */
      if(GET_VERBATIM())
	break;
      goto next_char;
    case '\n':
      yylineno++;
      break;
    case '\\':
      if (!GET_VERBATIM()){ /* if we should elminate escaped newlines */
	c2 = getc(yyin);
	/* I wonder if we should do this in unix too, it shouldn't hurt ... */
#if defined(_MSDOS) || defined (_WIN32) || defined(_LINUX)
	if (c2 == '\r') {
	  if ((c2 = getc(yyin)) != '\n') {
	    unput(c2);
	    c2 = '\r';
	  }
        }
#endif
	if(c2 == '\n')  {
	  numberOfNewlinesDeleted++;  /* record for yystdlex's sake */
	  yylineno++;
	  goto next_char;
	}
	if(c2 != EOF){   /* if it is ^Z, put it back and read it again */
	  unput(c2);
	}
      }
      break;
    }
    return((c==26)?EOF:c);  /* ctrl-Z maps to EOF (dos world) */
}





/***********************************************************************
 *				NewBlock
 ***********************************************************************
 * SYNOPSIS:	    Return a new macro block
 * CALLED BY:	    yyreadmacro, yylex, ...
 * RETURN:	    Pointer to a new block
 * SIDE EFFECTS:    Another chunk of blocks may be allocated.
 *	    	    The length and next fields of the returned block
 *	    	    are initialized to 0.
 *
 * STRATEGY:
 *	Since macro blocks are never freed, but are allocated fairly
 *	frequently, to avoid excessive overhead, both speedwise and
 *	memorywise, we allocate them in groups of...NUM_MACRO_BLOCKS
 *	internally to this function.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/15/89		Initial Revision
 *
 ***********************************************************************/
static MBlk *NewBlock(void)
{
    static MBlk	*nextBlock;
    static int	numBlocks = 0;

    if (numBlocks == 0) {
	nextBlock = (MBlk *)malloc(NUM_MACRO_BLOCKS * sizeof(MBlk));
	MALLOC_CHECK(nextBlock);
	numBlocks = NUM_MACRO_BLOCKS;
    }
    numBlocks -= 1;

    nextBlock->length = 0;
    nextBlock->dynamic = 0;
    nextBlock->next = 0;

    return(nextBlock++);
}


/***********************************************************************
 *				yystartmacro
 ***********************************************************************
 * SYNOPSIS:	  Enter macro-processing mode.
 * CALLED BY:	  PreProcInput()
 * RETURN:	  Nothing
 * SIDE EFFECTS:
 *	    	  Any previously-active macro is pushed.
 *	    	  maps is set-up with the passed arguments.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *      josh    8/7/92          goc version
 *	ardeb	8/31/88		Initial Revision  <esp>
 *
 ***********************************************************************/
void
yystartmacro(Mac *which, MBlk **args)
{
  /*
   * Save the previous macro state, pushing to the symbol's text.
   */
  PushMacro(which->body);
  numMaps = which->numParams;

  DBPRINTF((stderr,"Expanding %s with %d maps --\n", which->name, numMaps));

  if(numMaps > 0){
    /*
     * There are actually parameters for this macro.
     * arrange to use them. can't set maps before the pushmacro
     * or the old maps get blown away.
     */
    maps = args;
    /*
     * For each actual argument, transform it into a chain of MBlk
     * structures for the actual interpolation.
     */
  }

  /*
   * Handle the case where the first block is an argument.
   * Skip forward to a non-empty argument or a block of real text.
   */
  while ((curBlock != NULL) &&
	 (curMacCount <= 0) &&
	 (maps[-curMacCount] == NULL))
    {
      curBlock = curBlock->next;
      if (curBlock != NULL) {
	curMacCount = curBlock->length;
	curMacPtr = curBlock->text;
      }
    }

  if (curMacCount <= 0) {
    /*
     * Hit a viable argument -- push to its text.
     */
    MBlk	*mp = maps[-curMacCount];

    curMacCount = -1;

    PushMacro(mp);
  } else if (curBlock == NULL) {
    /*
     * Ran out of macro -- go back to the previous state.
     */
    PopMacro();
  }
}


/***********************************************************************
 *				PushMacro
 ***********************************************************************
 * SYNOPSIS:	  Push the current macro state for later recovery
 * CALLED BY:	  yylex, yystartmacro
 * RETURN:	  Nothing
 * SIDE EFFECTS:  curBlock is set to newBlock with curMacPtr and
 *	    	  curMacCount updated accordingly. In addition, numMaps
 *	    	  is zeroed.
 *	    	  macros also points to the previous state, which has
 *	    	  been pushed.
 *		  All characters pushed-back are saved with the state
 *	    	  and the push-back buffer cleared.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 2/88		Initial Revision
 *
 ***********************************************************************/
static void
PushMacro(MBlk    *newBlock)  /* New block to read */
{
    MacState	  *msp;	    	/* Record of previous state */

    if ((msp = freeState) != NULL) {  /* try to get one from the free list */
	freeState = freeState->next;  /* succeeded, so change free list */
    } else {
	msp = (MacState *)malloc(sizeof(MacState));   /*did not succeed*/
	MALLOC_CHECK(msp);
    }

    /*
     * First the real macro state
     */
    msp->block =  	curBlock;
    msp->ptr =		curMacPtr;
    msp->count =	curMacCount;
    msp->maps =		maps;
    msp->numMaps =	numMaps;


    DBPRINTF((stderr,"PushMacro(%08x,%08x)\n", (unsigned) msp,
	      (unsigned) macros));
    /*
     * Then the push-back buffer. Save the current bottom and reset it to
     * the current position.
     */
    msp->pbBot =    	yysbot;
    yysbot = 	    	yysptr;

    /*
     * Pushez le
     */
    msp->next = macros;
    macros = msp;

    /*
     * Set up the new state -- the given macro/string block, but no argument
     * mappings. yystartmacro will set those up later, and strings don't
     * have arguments. Note that newBlock may be NULL (e.g. when including
     * a file from w/in a macro call) so we have to deal with that case.
     */
    curBlock = newBlock;
    if (curBlock != (MBlk *)NULL) {
	curMacCount = curBlock->length;
	curMacPtr = curBlock->text;
    } else {
	curMacCount = 0;
    }
    maps = (MBlk **)0;
    numMaps = 0;
}


/***********************************************************************
 *				PopMacro
 ***********************************************************************
 * SYNOPSIS:	  Restore the most recent macro.
 * CALLED BY:	  PreProcInput
 * RETURN:	  Nothing
 * SIDE EFFECTS:  The previous state (see PushMacro above) is restored.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 2/88		Initial Revision
 *
 ***********************************************************************/
static void
PopMacro(void)
{
    MacState	  *msp = macros;    /* State to restore */

    /*FIREWALL*/
    if (msp == (MacState *)NULL) {
	yyerror("PopMacro: macros is NULL?!\n");
	return;
    }

    /*
     * If any arguments to the macro, free them up before restoring the old
     * ones.
     */
    if (numMaps > 0) {
	yyfreemaps(maps,numMaps);
    }

    DBPRINTF((stderr, "PopMacro(%08x, %08x)\n", (unsigned) msp,
	      (unsigned) msp->next));
    /*
     * The real macro stuff
     */
    curBlock = 	    msp->block;
    curMacCount =   msp->count;
    curMacPtr =     msp->ptr;
    maps =  	    msp->maps;
    numMaps = 	    msp->numMaps;

    /*
     * Allow access to any pushed characters by lowering the bottom of
     * the stack to where it was before.
     */
    yysbot = msp->pbBot;

    /*
     * Popez le
     */
    macros = msp->next;

    /*
     * Cache the thing by sticking it on the free list
     */
    msp->next = freeState;
    freeState = msp;

    /*
     * Handle multiple macro arguments in a row:
     *
     * If the count is -1, but curBlock isn't null, we were pushed into a
     * macro argument. Advance to the next block and, if it too is a macro
     * argument, push it.
     */
    if ((curMacCount == -1) && (curBlock != (MBlk *)NULL)) {
next_block:
	curBlock = curBlock->next;
	if (curBlock != (MBlk *)NULL) {
	    curMacCount = curBlock->length;

	    if(curMacCount <= 0) {
		MBlk	    *arg = maps[-curMacCount];

		curMacCount = -1;

		if (arg) {
		    PushMacro(arg);
		} else {
		    /*
		     * Arg is empty -- advance to next
		     */
		    goto next_block;
		}
	    } else {
		curMacPtr = curBlock->text;
	    }
	  } else {
	    /*
	     * The arg just expanded was the last token of the macro,
	     * because it's next == NULL.
	     * Need to do a PopMacro to return from it, or else we'll
	     * never return from the macro -- curBlock is NULL, so
	     * MFInput will go to the file for input.
	     */
	    PopMacro();
	  }
    }
}


/***********************************************************************
 *				yyfreemaps
 ***********************************************************************
 * SYNOPSIS:	  Free the argument maps and their values
 * CALLED BY:	  MFInput()
 * RETURN:	  Nothing
 * SIDE EFFECTS:  See above.
 *
 * NOTE:  m may be NULL. if so, mapCount better be zero.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 1/88		Initial Revision
 *
 ***********************************************************************/
static void
yyfreemaps(MBlk **m, int mapCount)
{
  int	    i;
  MBlk    **map;
  MBlk    *mp, *mpnext;

  for (map = m, i = mapCount; i > 0; map++, i--) {
    for (mp = *map; mp != (MBlk *)NULL; mp = mpnext) {
      mpnext = mp->next;
      if (mp->dynamic) {
	free((char *)mp);
      }
    }
  }
  if (m)
    free((char *)m);
}


/***********************************************************************
 *				yyreadmacrobody
 ***********************************************************************
 * SYNOPSIS:	  Read the body of a macro into a chain of MBlk and
 *	    	  MArg structures.
 * CALLED BY:	  yyreadmacro
 * RETURN:	  A pointer to the head of the chain.
 * SIDE EFFECTS:  Text is consumed from the input stream.
 *
 * STRATEGY:
 *
 * NOTE:          numParams must be greater than zero
 * WARNING:       uses yytext
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *      josh    8/9/92          for goc
 *	ardeb	9/ 6/88		Initial Revision  <esp>
 *
 ***********************************************************************/
static MBlk *
yyreadmacrobody(char  **params,/* Array of words to be mapped when macro
				     * is expanded
				     */
		int 	numParams)  /* Number of parameters in params*/
{
  MBlk    	*mp,	    	/* Current block in chain */
  *pmp = NULL,                  /* previous block in chain, MBlk or MArg *  */
  *head;    	                /* Head of the chain of text */
  char	*cp;	    	        /* Current place in mp->text */
  char        *cp2;             /* used to scan identifiers */
  char	c,c2;                   /* Character read */
  int		i;	    	/* Argument number */
  char        instring = 0;     /*  is the close quote char if not \0 */
  char        lastChar = ' '; /* allows us to handle strings with quotes
			       * in them (by checking for lastChar = \,
			       * and allows us to get rid of excess space
			       * characters at before other tokens -- if
			       * the current char is a ' ' or \t, and the
			       * last char was too, we ignore it.
			       * this initialized to ' ' so we'll skip
			       * any blanks at the start of a definition.
			       */


  head = mp = NewBlock();
  cp = mp->text;

  /*
   * This loop is a bit weird:
   *   we want to scan forward to the next thing that could be a macro
   *   parameter, so we want to look for a char that could start an id.
   *   on the other hand, if there are no params for the macro (-1)
   */
  for(;;){
    int linesSkipped;
    while((c = PMFInput()) != EOF
	  &&(!isfirstid(c) || instring)
	  && c != '\n'){
      switch(c){ /* break out of the case with c = current-char-to-insert */

      case '/':  /* look for a comment */
	if (instring)
	  break;
	c2 = PMFInput();
	if(c2 != '*' && c2 != '/'){
	  unput(c2);
	  break;
	}
	/* read comment, from non-preprocessed input stream */
	if((linesSkipped = DevourRestOfComment(FALSE, c2 == '/'))== -1){
	  return((MBlk *)NULL);
	}
	OutputLineDirectiveOrNewlines(linesSkipped);
	c = ' ';        /* comments get replaced with a single space */
	break;
      case '"': case '\'':
	if(!instring) {         /* if not in string, now we are */
	  instring = c;
	  break;
	}
	if(lastChar != '\\' && c == instring)    /* in string, see if done */
	  instring = 0;
	break;
      case ' ': case '\t':                     /* eliminate extra whitespace */
	if((lastChar == ' ' || lastChar == '\t') && !instring)
	  continue;                            /* continue == goto next char */
	break;
      }
      /* XXX
       *
       * if the lastChar was a "\" and this char is too, we don't set
       * lastchar to "\\", because if we are in a string and the next
       *  char is the close quote, we'll think it was escaped.
       * we set it to 'a' in this case, as that has no meaning to
       * any of the things that look at lastChar.
       */
      lastChar = (c == '\\' && lastChar == '\\')?'a':c;
      *cp++ = c;
      if (++mp->length == MACRO_BLOCK_SIZE) {
	/*
	 * Hit end of current block -- allocate a new one
	 */
	pmp = mp;
	mp = mp->next = NewBlock();
	cp = mp->text;
      }
    }
    /* we need to set lastChar to be something besides ' ', or we will not */
    /* recognize any spaces that come after the identifier.                */
    lastChar = 'a';

    if(c == EOF || c == '\n'){   /* all done */
      unput(c);
      if(instring) yyerror("%s before string in macro ends.",
			   (c == EOF)?"EOF":"Return");
      /*
       * If the current block has no text, we have to eliminate it, or
       * when we expand it, it will appear as though it is param 0.
       * we free tha blank block, and make sure that the previous block,
       * if it exists, points to NULL.
       */
      if(mp->length == 0){
	if(pmp)
	  pmp->next = NULL;
	if(head == mp)          /* mp has no text, and it is the start, */
	  head = NULL;          /* so no text for this macro */
      }
      return head;
    } else {             /* scan the identifier and see if it is a param */
      cp2 = yytext;
      do {
	*cp2++ = c;
	c = PMFInput();
      } while (isotherid(c));
      unput(c);
      *cp2 = '\0';


      for (i=0; i < numParams; i++) {
	if ((params[i][0] == yytext[0]) && (strcmp(params[i], yytext) == 0)){

	  MArg	*margp;      	             /* IT IS A PARAMETER */

	  if (mp->length == 0) {
	    /*
	     * If the current block has nothing in it.
	     * use the current block for the argument,
	     * ignoring the it has.
	     */
	    margp = (MArg *)mp;
	  } else {
	    margp = (MArg *)malloc(sizeof(MArg));
	    MALLOC_CHECK(margp);
	    margp->dynamic = TRUE;
	    mp->next = (MBlk *)margp;
	  }
	  margp->argNum = -i;
	  pmp = (MBlk *) margp;
	  mp = margp->next = NewBlock();
	  cp = mp->text;
	  break;
	}
      }
      /*
       * If found an argument, don't store the thing...
       */
      if (i != numParams) {
	continue;
      }
      /* no match, so need to copy the id into the macro's text */
    }
    if (cp2 - yytext < MACRO_BLOCK_SIZE - mp->length) {
      /*
       * The whole word will fit in the current block. Copy
       * it in and update both cp and mp->length.
       */
      bcopy(yytext, cp, cp2 - yytext);
      mp->length += cp2 - yytext;
      cp = &mp->text[mp->length];
    } else {
      /*
       * Won't fit. Copy what will fit into the current block,
       * and allocate blocks, copying successive chunks into
       * them, until the word is completely stored.
       */
      i = MACRO_BLOCK_SIZE - mp->length;

      bcopy(yytext, cp, i);
      mp->length = MACRO_BLOCK_SIZE;

      /*
       * Point cp at the next chunk to copy
       */
      cp = yytext + i;

      /*
       * Allocate the next block
       */
      pmp = mp;
      mp = mp->next = NewBlock();

      while(cp2 - cp >= MACRO_BLOCK_SIZE) {
	/*
	 * Copy in another MACRO_BLOCK_SIZE bytes, advancing
	 * cp.
	 */
	mp->length = MACRO_BLOCK_SIZE;
	bcopy(cp, mp->text, MACRO_BLOCK_SIZE);
	cp += MACRO_BLOCK_SIZE;

	/*
	 * Allocate another block for "the rest"
	 */
	pmp = mp;
	mp  = mp->next = NewBlock();
      }

      if (cp2 != cp) {
	/*
	 * Still some stuff left over -- copy it into the
	 * final block and set its length.
	 */
	bcopy(cp, mp->text, cp2-cp);
	mp->length = cp2-cp;
      }

      /*
       * Point cp at the next place to store text again.
       */
      cp = mp->text + mp->length;
    }
  }
}

/***********************************************************************
 *		      Scan_CheckForConditional
 ***********************************************************************
 * SYNOPSIS:	check for a conditional, if so, process the conditional
 *              and return the number of lines skipped over.
 *              assumes caller read the '@' before any conditional.
 * CALLED BY:	MFInput, ScanNoContext
 * RETURN:	0 if no conditional, else number of lines scanned.
 * SIDE EFFECTS:scans from input. If the line is not a conditional,
 *              the input will get put back for processing again.
 *
 * NOTES:   this routine just sets up input flags (verbatim = false
 *      and conditional = true), and calls the conditional processing
 *      functions. It is necessary to set the input flags because:
 *      the conditional processing code expects escaped newlines to be
 *      filtered out, and if we don't set 'conditional', MFInput (when
 *      called by the conditional code) would look for more conditionals,
 *      which would lead to (very bad) recursion.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	josh	9/8/92		Initial Revision
 *
 ***********************************************************************/

Boolean Scan_CheckForConditional(void)
{
    int numCondCharsScanned;
    int linesSkipped = 0;
    lexFlags flags = internalLexFlags;           /* save flags */


    SET_VERBATIM(FALSE);  /* remove escaped newlines */

    if((numCondCharsScanned = IsLineAConditional(conditionalLineBuffer))){
	SET_CONDITIONAL(TRUE); 	/* don't look for another conditional */
	topLevelConditionalLineNo = yylineno;
	topLevelCondFileName = curFile->name;
	linesSkipped = ScanConditional(conditionalLineBuffer,
				       numCondCharsScanned);
	SET_CONDITIONAL(FALSE);           /* no longer in conditional */
    }
    internalLexFlags = flags;

    return linesSkipped;
}



/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreProcInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return the next char from the input stream (which may
                be pushed back input, macro input, or source file
		input), after processing conditionals, macro expansion,
		file inclusion and removing comments.

		If this routine sees a comment, it will output a line
		directive or a bunch of newlines.

CALLED BY:	yylex  and its helpers

PASS:           void
RETURN:		char

PSEUDO CODE/STRATEGY:
                 get the next character.

		 if it is a '/' and a comment follows,
		      scan the comment, and put out a line directive or
		      newlines and return a space.

		 if it is an '@', see if it is a macro/include/definition
		      if so, do the processing and return the next
		           character.
		      else return the '@'.
		 else return the character

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	8/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

inline static char
PreProcInput (void)
{
  register char c;
  signed int linesSkipped;

 next_char:

  switch(c = PMFInput()){
  case '/':                                   /* maybe a comment?     */
    c = PMFInput();
    if(c != '*' && c != '/') {	              /* nope */
      unput(c);
      c =  '/';
      break;
    }
    linesSkipped = DevourRestOfComment(FALSE, c == '/');
    /*
     * normally, output a directive or newlines for multi-line comments
     * immediately, and return a space.
     *
     * the gstring lexical context LC_CLOSE_CURLY_OR_STRING just returns
     * a bunch of newlines for the comment (if it spans multiple lines).
     * yystdlex will ouput a directive (or newlines) to compensate,
     * because the lexcontext will increment numberOfNewlinesDeleted --
     * the newlines are deleted in the sense that they are not immediately
     * output.
     *
     */
    if(!GET_COMMENT_AS_NEWLINES()){
	OutputLineDirectiveOrNewlines(linesSkipped);
    } else {
	while(linesSkipped--){
	    unput('\n');
	}
    }
    c = ' ';
    break;
  case '@':
    {
      enum PPDirectiveType directive;
      Boolean verbatim = GET_VERBATIM();

      SET_VERBATIM(FALSE);                       /* remove escaped newlines */
      directive = PreProcessorDirectiveType(yytext);
      if(directive == noDirective){
	c = '@';
	break;
      }
      ProcessDirective(directive,yytext);
      SET_VERBATIM(verbatim);
      goto next_char;
    }
  default:                                    /* not special */
    break;
  }
  return c;
}

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessDirective
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
CALLED BY:	ScanNoContext, PreProcInput

PASS:           buffer with name of directive (really needed only for macros)
RETURN:		void

KNOWN BUGS/SIDE EFFECTS/IDEAS:
      dispatch on the type of directive and call the appropriate function

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	8/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


void ProcessDirective(enum PPDirectiveType type, char *text)
{
  Hash_Entry	*entry;

  switch(type){
  case definition:
    Scan_ScanMacroDef();
    break;
  case inclusion:
    Scan_Include();
    break;
  case self:
    Scan_Self();
    break;
  case macroExpansion:
    assert ((entry = Hash_FindEntry(&macroWords, yytext)) != NullHash_Entry);
    Scan_ExpandMacro((Mac *)Hash_GetValue(entry));
    break;
  default:
    assert(0);
  }
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PreProcessorDirectiveType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	assuming we just read an '@', tell what sort of preprocessor
                directive follows. Routines that read from PMFInput need
		to use this (unless they're inside strings or comments)
		when they read an '@' from PMFInput, e.g. ScanNoContext,
		or PreProcinput.

CALLED BY:	PreProcInput, ScanNoContext
PASS:           buffer for scanning identifier
RETURN:		enum PPDirectiveType
DESTROYED:	nothing

STRATEGY:       read in the identifier after the '@'.
                compare it with keywords (define, include, self, macro names)
		if no match, unput the characters,
		else return the type of directive.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	8/ 6/92   	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
enum PPDirectiveType PreProcessorDirectiveType(char *yytext)
{
  register char c;
  Hash_Entry	*entry;
  char *id;

  if(isfirstid(c = PMFInput())){
    id = yytext;
    do{
      *id++ = c;
    }while(isotherid(c = PMFInput()));
    unput(c);
    *id = '\0';

    if(yytext[0] == 'd' && (strcmp(yytext,"define") == 0)){
      return definition;
    }else if(yytext[0] == 'i' && strcmp(yytext,"include") == 0){
      return inclusion;
    }else if(yytext[0] == 's' && strcmp(yytext,"self") == 0){
      return self;
    }
    entry = Hash_FindEntry(&macroWords, yytext);   /* maybe a macro */
    if(entry != NullHash_Entry) {
      return macroExpansion;
    }
    /* not a directive */
    do{                              /* put back all of the chars  */
      unput(*(--id));
    }while(id > yytext);
  }
  return noDirective;
}




/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                IsLineAConditional
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan in chars from PMFInput and determine if the line
                is a conditional.

		If the line is not, unput the characters and return 0.

		If the line is, leave the start of the line in the buffer
		and return the number of characters read from the input
		stream. This is so the caller can then scan in the
		rest of the line after the start of the conditional.

CALLED BY:	Scan_CheckForConditional, ScanConditional

PASS:           void

RETURN:		number of chars read.

SIDE EFFECTS:   reads from input file via PMFInput

WARNING:        assumes that the caller read the '@', but did not put it
                in the buffer. This is so that PMFInput can just call
		this routine after reading the '@'.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	8/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


int IsLineAConditional(char *buf)
{
  char endC;
  char *bufStart = buf;
  int i;

  *buf++ = '@';

  /* read a max of 7 chars  (ifndef + blank), stoppping for blanks */
  /* at the end, buf will point to the last character read */

  for(i = 0;
      (*buf = PMFInput()) != EOF && *buf != '\n'
           &&  *buf != ' ' && *buf != '\t';
      buf++){
    if(i++ == 7)
      break;
  }
  endC = *buf;
  *buf = '\0';

  /* if it is EOF, we didn't wrap to the next file, because we turned off */
  /* wrapping. We'll wrap the next time we read from yystdinput though.   */
  /* otherwise, we should unput it.                                       */
  if(endC != EOF){
    unput(endC);
  }
  if(!isspace(endC))     /* we have too long an identifier */
    goto unput_chars_and_return_false;

  if(strncmp(bufStart,   "@if"    ,3) &&
        strncmp(bufStart,"@ifdef" ,6) &&
        strncmp(bufStart,"@ifndef",7) &&
        strncmp(bufStart,"@elif"  ,5) &&
        strncmp(bufStart,"@else"  ,5) &&
        strncmp(bufStart,"@endif" ,6)){            /* NO MATCH */

  unput_chars_and_return_false:

    /* unput all of the id, but not the '@' we inserted in buf[0]. */
    while(--buf > bufStart){
      unput(*buf);
    }
    return 0;
  } else {
    return buf - bufStart;
  }
}

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanConditional
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given that the line is a conditional, evaluate the
                conditional and return the number of lines skipped
		while reading the conditional and any excluded lines.

		The '@' character signalling the start of the line should
		have been read before calling this function.

		We read from PreProcInput, even though conditionals only
		are in files, because we want the macros on the line
		to get expanded. Because we are calling PreProcInput,
		which will call PMFInput, we need to set a flag saying
		that we should not look for more conditional directives.

CALLED BY:	MFInput

PASS:           void

RETURN:		number of lines skipped.
                e.g. we return 3 if we read from PreProcInput:

		if defined FOO
		foo();
		@endif

		return 0 if the line is not a conditional.

SIDE EFFECTS:   reads from input file via PreProcInput

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	8/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
static int
ScanConditional(char *buf,int index)
{
  char *cp = buf + index;
  char c;
  int startLine = yylineno;
  int i,cc;


 /*scanCondLine:*/    /* scan in a line for Cond_Eval, so use PreProcInput */
  do{
    *cp = PreProcInput();
  }while (*cp != EOF && *cp++ != '\n');
  cp--;
  if(*cp == EOF){
    yyerror("EOF before end of conditional directive line");
    goto done;
  }
  assert(*cp == '\n');
  *cp = '\0';

  switch(i = Cond_Eval(buf)){
  case COND_SKIP:

    while(1){  /* assert: just read a newline, so we look for a conditional */

    /*
     * If no starting '@', or has one and isn't conditional, ignore
     * if is a conditional, cc gets the buf's index for the conditional
     */
    c = PMFInput();		/* initial value for while */
    while(isspace(c) && c != '\n' && c != EOF)	  /* skip any spaces */
	c = PMFInput();
    if(c == '\n')
      continue;                         /* see assertion */
    if(c != '@' ||  (0 == (cc = IsLineAConditional(buf)))){
      while((c = PreProcInput()) != '\n' && c != EOF);
      if(c == EOF){
	Cond_End();  /* give up. Open conditionals = FUBAR */
	yyerror("top level conditional began on line %d,file %s",
		topLevelConditionalLineNo,
		topLevelCondFileName);
	exit(-1);
      }
      continue;
    }
    /* else A CONDITIONAL, Yippee!  */
    cp = buf + cc;

    /* copy in the rest of the line for evaluation */
    do{
      *cp = PreProcInput();
    }while (*cp != EOF && *cp++ != '\n');
    cp--;
    if(*cp == EOF){
      yyerror("EOF before end of conditional directive line");
      goto done;
    }
    *cp++ = '\0';

    if(Cond_Eval(buf) == COND_PARSE)
      break;
  }
    goto done;
  case COND_INVALID:
    yyerror("bad condtiional line");
    goto done;
  case COND_PARSE:
    goto done;
  }
 done:
  assert(yylineno - startLine > 0);  /* we always read at least one line */
  return yylineno - startLine;
}




/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Scan_ExpandMacro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've recognized the macro's name, so now we scan its
                parameters and call yystartmacro (to scan the body).

		We place the parameters in maps, where yystartmacro
		and MFInput look for them.

CALLED BY:	PreProcInput

PASS:           macro pointer

RETURN:		void

SIDE EFFECTS:   maps gets set, macro gets pushed, so curBlock changes,
                along with all the input state.

CHECKS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	8/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


void Scan_ExpandMacro(Mac *macPtr)
{
  MBlk **newMaps;    /* maps for this macro invocation */
  int curParam = 0;  /* which map we are processing    */
  MBlk *mp;          /* current  block where we put the text */
  MBlk *pmp;         /* previous block */
  char *cp;          /* where to put text */
  char c;
  int parenCount;    /* number of open parentheses for current param */
  char lastChar = 'a'; /* previous char read, or an approximation thereof */
  char  instring = 0; /* 0 or close-string character (either ' or ") */

  Depends_FileUsesMacro(macPtr);

  if(macPtr->numParams >= 0){
    newMaps = (MBlk **) calloc(macPtr->numParams,sizeof(MBlk*));
    MALLOC_CHECK(newMaps);
    while(isspace(c = PMFInput()) && c != EOF);  /* skip any spaces */
    if(c != '('){
      yyerror("macro %s invocation is missing its parameter list",
	      macPtr->name);
      unput(c);
      return;
    }
    parenCount = 0;
  next_param:
    pmp = NULL;
    newMaps[curParam] = mp = NewBlock();
    cp = mp->text;

    /* skip any spaces before the arg */
    while((c = PMFInput()) != EOF && isspace(c));
    if(c == EOF)
      goto eof_error;
    else unput(c);

    while((c = PMFInput())!= EOF      /* always quit on EOF */
	  && (c != ',' || parenCount || instring)   /* quit if toplevel    */
	  && (c != ')' || parenCount || instring)){ /* and not in a string */
      int linesSkipped;
      switch(c){
      case '(':
	if(instring)
	  break;
	parenCount ++;   /* inc the nesting count, add char to the block */
	break;
      case ')':
	if(instring)
	  break;
	parenCount--;   /* inc the nesting count, add char to block */
	break;
      case '*':
      case '/':
	if(instring || lastChar != '/'){
	    break;
	}
	/* read the comment, with no preprocessing */
	if((linesSkipped = DevourRestOfComment(FALSE, c == '/'))==-1){
	  return;
	}
	OutputLineDirectiveOrNewlines(linesSkipped);
	c = ' ';  /* replace comments with a single space */
	break;


      case '"': case '\\':   /* if not in string, now we are */
	if(!instring){
	  instring = c;
	  break;
	}
	if(lastChar != '\\' && c == instring)   /* in a string, see if done */
	  instring = 0;
	break;
      }
      /* XXX
       *
       * if the lastChar was a "\" and this char is too, we don't set
       * lastchar to "\\", because if we are in a string and the next
       * char is the close quote, we'll think it was escaped.
       * we set it to 'a' in this case, as that has no meaning to
       * any of the things that look at lastChar.
       */
      lastChar = (c == '\\' && lastChar == '\\')?'a':c;

      *cp++ = c;
      if (++mp->length == MACRO_BLOCK_SIZE) {
	/*
	 * Hit end of current block -- allocate a new one
	 */
	if(pmp)
	  pmp->next = mp;
	mp = mp->next = NewBlock();
	cp = mp->text;
      }
      /* add c to the current parameter's text */
    }
    /* done with a parameter */
    if(c == ',' || c == ')'){
      /* if the current block is blank, remove the text */
      if(mp->length == 0){
	if(pmp)
	  pmp->next = NULL;
	if(newMaps[curParam] == mp) /* mp has no text, and it is the start, */
	  newMaps[curParam] = NULL; /* so no text for this macro */
      }
      if(c == ')'){
	/*
	 * check to see if they gave the right number of args
	 * for ones with actual args, the index of the array should be one
	 * less than the array length.
	 *
	 * For macros with void params, like @foo(), the index and
	 * the count should both be zero.
	 */
	if(curParam+1 == macPtr->numParams||
	   (!curParam && !macPtr->numParams))
	  yystartmacro(macPtr,newMaps);
	else
	  yyerror("Expect %d parameters for macro %s, not %d",
		  macPtr->numParams,macPtr->name,curParam+1);
	return;
      }
      curParam++;
      if(curParam == macPtr->numParams){
	yyerror("Too many params to macro %s",macPtr->name);
	yyfreemaps(newMaps,curParam);
	return;
      }
      goto next_param;
    }                    /* must be EOF */
  eof_error:
    yyerror("EOF encountered in macro parameter list");

  }else{
    yystartmacro(macPtr,NULL);
  }
}



#ifdef LEXDEBUG
void
printmacro(Mac *macroPtr)
{
  MBlk *m;
  int i;

  if(macroPtr->numParams >= 0){
    printf("macro <%s> has %d params\n",macroPtr->name, macroPtr->numParams);
  }else {
    printf("macro <%s> has no params\n",macroPtr->name);
  }
  for(m = macroPtr->body; m; m = m->next){
    if(m->length > 0) {
      putchar('<');
      for(i = 0; i < m->length; i++)
	putchar(m->text[i]);
      putchar('>');
      putchar('\n');
    } else{
      printf("arg %d\n", - m->length);
      continue;
    }
  }
}
#endif



/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                ShouldntDefineThisMacro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Can't just blindly (re)define  macros.
                someone might @define a keyword like @call,
		or they might try to define a macro again.

RETURN:		TRUE if shouldn't  define, else FALSE

CALLED BY:      Scan_ScanMacroDef

PASS:		name of macro

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	8/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
Boolean
ShouldntDefineThisMacro(char *text)
{
  Hash_Entry	*entry;
  char          *stringTableText = String_Enter(yytext,strlen(yytext));

  entry =    Hash_FindEntry(&ReservedWords, stringTableText);
  if((entry != NullHash_Entry ||
      !strcmp(text,"define")) ||
     !strcmp(text,"inlcude")){

    yyerror("can't define macro <%s>, it is already a goc keyword\n", text);
    return TRUE;
  }

  if((entry = Hash_FindEntry(&macroWords, text)) != NullHash_Entry){
    Mac *macroPtr = (Mac *)Hash_GetValue(entry);
    yyerror("redefining macro %s previously defined in %s line %d. DONT!",
	      text, macroPtr->fileName, macroPtr->lineNo);
  }
  return FALSE;
}


/*****************************************************************
 *		Scan_MacroIsDefined                              *
 *****************************************************************
 * PASS: name of macro
 * RETURN: true iff 'name' is a defined macro
 */
Boolean
Scan_MacroIsDefined(char *macroName)
{
  return (NullHash_Entry!= Hash_FindEntry(&macroWords, macroName));
}


/***********************************************************************
 *               Scan_MacroIsUndefForFromFile
 ***********************************************************************
 * SYNOPSIS:	  depend module needs to know when macros move from a file
 * CALLED BY:
 * RETURN:	  0 if macro undefined or from given file, else its file
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/23/92   	Initial Revision
 *
 ***********************************************************************/
char *
Scan_MacroIsUndefForFromFile (char *name,char *file)
{
    Hash_Entry 	*entry = Hash_FindEntry(&macroWords, name);
    char 	*macrosFile;

    if(entry == NULL)
	return FALSE;
    macrosFile = ((Mac *) Hash_GetValue(entry))->fileName;
    if(macrosFile == file)
	return FALSE;
    return macrosFile;
}	/* End of Scan_MacroIsUndefinedOrFileIsAsGiven.	*/



/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Scan_DefineMacro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create a macro with a given name and value
CALLED BY:      ParseArgs
PASS:		name, value    (both char *)
RETURN:		Void
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	8/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
void
Scan_DefineMacro(char *name, char *value)
{
    MBlk    	*block;
    int	    	vlen = strlen(value);

    if(vlen){  /* if its blank, the body is just NULL  */
      block = (MBlk *)malloc(sizeof(MArg) + vlen);
      MALLOC_CHECK(block);
      block->next = NULL;
      block->length = (vlen > 0)?vlen:-1;  /* if no text, make neg */
      block->dynamic = TRUE;
      bcopy(value, block->text, vlen);
    }else{
      block = NULL;
    }

    DefineMacro(name,
		"command_line",    /* our macro is not in a file      */
		0,                 /* but we must give a "filename "  */
		-1 /*no params*/,
		block);
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefineMacro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	enter a macro into the macro symbol table
CALLED BY:      Scan_DefineMacro, Scan_ScanMacroDef
PASS:		name, value    (both char *)
RETURN:		Void
REVISION HISTORY:
NOTES:
        numParams = -1 if no args, 0 if void args, else arg count

	Name	Date		Description
	----	----		-----------
	JP	8/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
Mac *
DefineMacro(char *name,       /* name of macro                 */
	    char *fileName,   /* filename where defined        */
	    int lineNo,       /* line number of definition     */
	    int numParams,    /* number of parameters to macro */
	    MBlk *body)       /* result of yyreadmacrobody     */
{
  Hash_Entry     *ent;    /* entry for this macro in the symbol table */
  Boolean   new;            /* needed for Hash_CreateEntry */
  Mac *macroPtr = (Mac *) malloc(sizeof(Mac));
  MALLOC_CHECK(macroPtr);

  macroPtr->name 	= name;
  macroPtr->fileName 	= fileName;
  macroPtr->lineNo 	= lineNo;
  macroPtr->numParams 	= numParams;
  macroPtr->body      	= body;

  /* our key (how we look it up) is the name,  */
  ent = Hash_CreateEntry(&macroWords, macroPtr->name, &new);

  /* the value is the structure pointer */
  Hash_SetValue(ent,macroPtr);

  return macroPtr;
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Scan_ScanMacroDef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	scan in a macro definition
CALLED BY:      PreProcInput

PASS:		void
RETURN:		Void.
DESTROYED:	Nothing.

PSEUDO CODE/STRATEGY:
CHECKS:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

     scans in the name of the macro
     scans in its args
     scans in the body
     puts it all in a structure and enters it in the macro table

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	8/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#define RMD_ERROR(cond,x)  {if(cond) {yyerror x;return;}}
#define PARAM_SIZE 10
void
Scan_ScanMacroDef (void)
{
  Mac *macroPtr;
  char *cp;                 /* used for name and parameter scanning */
  char c;

  char    **params = NULL;  /* Array of parameter names to match in
			     * yyreadmacrobody */
  int	    maxParams;	    /* Length of above */
  int	    numParams;	    /* Number of parameters actually in params */
  char      *name;          /* name of macro */


  /* scan up to the name of the macro */

  while(isspace(c = PMFInput()) && c != '\n' && c != EOF);
  RMD_ERROR((c == '\n'|| c== EOF),
	    ("can't define a macro if it doesn't have a name"));
  RMD_ERROR(!isfirstid(c),
	    ("expect macro identifer, not garbage char %c",c));

  /* scan the name of the macro into yytext */
  cp = yytext;
  do{
    *cp++ =  c;
  }while(isotherid(c = PMFInput()));
  *cp = '\0';
  if(ShouldntDefineThisMacro(yytext)){
    return;
  }
  name =  CopyStringSection(yytext,cp);
  /* now see if the macro takes args */
  if(c == '('){                   /* macro takes args */
    /*
     * First fetch the args. They must be comma-separated.
     */
    numParams = 0;
    maxParams = PARAM_SIZE;
    params = (char **)malloc(maxParams * sizeof(char *));
    MALLOC_CHECK(params);
    while(1){
      do{                            /* skip past initial blanks */
	c = PMFInput();
      } while(isspace(c) && c != '\n' && c != EOF);

      if(c == ')')                   /* e.g. @define foo()  expr */
	break;

      RMD_ERROR(!isfirstid(c),
		("expect macro parameter, not garbage char %c",c));

      cp = yytext;
      do{               /* scan parameter into yytext */
	*cp++ =  c;
      }while(isotherid(c = PMFInput()));
      *cp++ = '\0';
      RMD_ERROR((c == '\n')|| (c == EOF),
		("poorly terminated macro parameter list"));

      /*
       * Make sure the array can hold another pointer, allocating
       * a new array on the stack and copying the old pointers
       * into it if not. Old array allocated on stack, too, so
       * no need to free it.
       */
      if (numParams == maxParams) {
	params = (char **)realloc((void *)params,
				  (maxParams+PARAM_SIZE)*sizeof(char *));
	MALLOC_CHECK(params);
	maxParams += PARAM_SIZE;
      }
      /*
       * Copy the identifier into more permanent storage on
       * the stack and point the array to it.
       */
      params[numParams] = (char *)malloc(cp - yytext);
      MALLOC_CHECK(params[numParams]);
      bcopy(yytext, params[numParams], (cp-yytext));
      numParams += 1;

      /* skip forward to the , or ). c might be that char already. */

      while(isspace(c) && c != '\n' && c != EOF )
	c = PMFInput();
      RMD_ERROR((c == '\n')|| (c == EOF),
		("poorly terminated macro parameter list"));

      if(c == ')')
	break;
      RMD_ERROR((c != ','),("garbage char: %c after macro parameter",c));

      /* c must be a ','  so   continue fetching parameters */
    }
  } else {                         /* macro does not have args */
    numParams = -1;
    unput(c);
  }
  macroPtr = DefineMacro(name,
			 curFile->name,
			 yylineno,
			 numParams,
			 yyreadmacrobody(params,(numParams < 0)?0:numParams));


#ifdef LEXDEBUG
  if(lexdebug)
    printmacro(macroPtr);
#endif
}






/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  MarkFileAsIncluded
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  SYNOPSIS:   record the argument in a table of filenames

  see FileHasBeenIncluded().

  CALLED BY:	Scan_Include

  PASS:		char *name

  RETURN:		Void.

  DESTROYED:	Nothing.

  PSEUDO CODE/STRATEGY:
  enter the string in the table so we can just compare pointers
  when we want to look up a string.

  CHECKS:

  KNOWN BUGS/SIDE EFFECTS/IDEAS:

  REVISION HISTORY:
  Name	Date		Description
  ----	----		-----------
  JP	8/11/92   	Initial version.

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

void
MarkFileAsIncluded(char *name)
{
    if(filesIncluded == NULL){                 /* ENTERING FIRST FILE NAME */
	filesIncluded = (char **) malloc(sizeof(char *));
	MALLOC_CHECK(filesIncluded);
	*filesIncluded = name;
	numFilesIncluded++;
    }else{                                     /* ALL OTHER FILES          */
	filesIncluded = (char **) realloc((malloc_t)filesIncluded,
					  (numFilesIncluded + 1) *
					     sizeof(char *));
	MALLOC_CHECK(filesIncluded);
	filesIncluded[numFilesIncluded++] = name;
    }
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  FileHasBeenIncluded
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  SYNOPSIS:	look up filename

  CALLED BY:	Scan_Include

  PASS:		char *name

  RETURN:		T if file has been entered in the table previously

  DESTROYED:	Nothing.

  PSEUDO CODE/STRATEGY:

  CHECKS:

  KNOWN BUGS/SIDE EFFECTS/IDEAS:

  REVISION HISTORY:
  Name	Date		Description
  ----	----		-----------
  JP	8/11/92   	Initial version.

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

Boolean
FileHasBeenIncludedAlready(char *name)
{
    int i;
    for(i = 0; i < numFilesIncluded; i++)
	if(filesIncluded[i] == name)
	    return TRUE;
    return FALSE;
}


/***********************************************************************
 *				ScanIncludeFileName
 ***********************************************************************
 * SYNOPSIS:	    scan an include directive from yystdin
 * CALLED BY:
 * RETURN:	    TRUE if no error, else FALSE
 * SIDE EFFECTS:    set localSearch if its a localSearch
 *                  output a newline for the include line that disappears
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/17/92   	Initial Revision
 *
 ***********************************************************************/
Boolean
ScanIncludeFileName(char *buffer,Boolean *localSearch)
{
    char    	c;		/* Input character */
    char    	*cp;		/* Pointer into yytext */

    /*
     * Skip to filename
     */
    while ((c = PreProcInput()) == ' ' || c == '\t');

    if(c != '<' && c != '"'){
	yyerror("your @include not followed by '<' or '\"' \n");
	goto false;
    }
    *localSearch = (c == '"')?TRUE:FALSE;
    /*
     * Copy path into buffer
     */
    cp = buffer;
    while(((c = PreProcInput()) != EOF) &&
	  (c != '"') && (c != '>') && (c != '\n')){
	*cp++ = c;
    }
    *cp = '\0';
    {
	char *dot = strrchr(buffer,'.');
	if(dot == NULL || buffer == dot){
	    yyerror("You should only @include \".g*\" files, "
		    "'%s' isn't", buffer);

	    goto false;
	}
    }
    if(c == EOF || c == '\n'){
	yyerror("file to @include does not end before %s",
		(c==EOF)?"EOF":"newline");
	goto false;
    }

    while((c = PreProcInput()) != '\n' && c != EOF && isspace(c));
    if(c != EOF && c != '\n'){
	yyerror("garbage char <%c> after @include directive",c);
	goto false;
    }
    if(c == '\n'){
	Output("\n");    /*  Necessary in case we don't take the include. */
    }


    return TRUE;
 false:
    return FALSE;
}	/* End of ScanIncludeFileName.	*/


/***********************************************************************
 *				ScanMaybeIncludeFile
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:        Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/17/92   	Initial Revision
 *
 ***********************************************************************/
void
ScanMaybeIncludeFile (char *path,
		      char *includeName,
		      FILE *newin,
		      Boolean localSearch)
{
    File 	*f;

    for(f = curFile; f; f = f->next){
	if(f->name == path){
	    yyerror("circular include of %s is not allowed. File stack:",path);
	    for(f = curFile; f; f = f->next){
		fprintf(stderr,"\t%s\n",f->name);
		fflush(stderr);
	    }
	    goto dont_store_include;
	}
    }
    /* Store the depend info even if it has been read already. */
    /* XXX uses curFile implicitly. XXX */
    Depends_StoreInclude(includeName,path,localSearch);
 dont_store_include:

    /* make sure to use full file name.   */
    /* DON'T include file more than once into the same output */
    if(FileHasBeenIncludedAlready(path)){
	DBPRINTF((stderr,"file %s already included\n",path));
	if(Depends_WasOptimized(path)){
	    ScanOutputIfndefDefine(path);
	    Output("#include \"%s\"\n",Depends_GetFileName(path,FALSE));
	    Output("#endif\n");
	    OutputLineNumber(yylineno,curFile->name);
	}
	fclose(newin);
	return;
    }
    MarkFileAsIncluded(path);

    DBPRINTF((stderr,"INCLUDE %s\n", path));

    if (newin == NULL) {
	yyerror("Couldn't open include file %s\n", path);
	return;
    }
    f = (File *)malloc(sizeof(File)); /* New File structure */
    MALLOC_CHECK(f);

    f->name = path;
    f->includeName = includeName;
    /*
     * Preserve current state
     */
    curFile->line = 	yylineno;
    curFile->file = 	yyin;

    /* the first 2 get set by the optimizeline rule in the parser */

    curFile->optimizeThisFile 	= optimizeThisFile;
    curFile->foutput 		= foutput;

    PushMacro((MBlk *)NULL);

    /*
     * Set up for new file
     */
    optimizeThisFile = FALSE;  /* don't optimize  until we see a @optimize.*/
    yylineno = 1;
    f->next = curFile;
    yyin = newin;
    whichToken = BEFORE_FILE;
    curFile = f;

    if(foutput){
	ScanOutputIfndefDefine(curFile->name);
    }
    OutputLineNumber(yylineno,curFile->name);
}



/***********************************************************************
 *				Scan_Include
 ***********************************************************************
 * SYNOPSIS:	    Handle INCLUDE directive
 * CALLED BY:	    yystdlex
 * RETURN:	    Nothing
 * SIDE EFFECTS:    A new File is pushed onto the file stack.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 5/89		Initial Revision
 *
 ***********************************************************************/
static void
Scan_Include(void)
{
    FILE    	*newin;	    	/* New input file */
    char	        *path;
    char 	*includeName;
    Boolean       localSearch;    /* is it @include "file" or <file> */


    if(!ScanIncludeFileName(yytext,&localSearch)){
	return;
    }
    includeName = String_EnterNoLen(yytext);    /* save for curFile */

#if 0
    /*
     * Removing this, as a test.  This code is a hack to speed
     * up dependency generation.  However, I don't think that
     * separating out stdapp.goh's dependencies into a separate
     * depedency:
     *
     * foo.eobj: stdapp.goh
     *
     * stdapp.goh: blah blah
     *
     * because pmake does not add in stdapp.goh's dependencies
     * into foo.eobj, even though it depends on it.
     */
    if (makeDepend)
    {
	if (!strcmp(includeName, "stdapp.goh"))
	{
	    printf("%s : stdapp.goh\n", outFile);
	    fflush(stdout);
	    Output("\n#include <stdapp.h>\n");
	    return;
	}
    }
#endif
    path = Depends_GetResolved(includeName,localSearch,&newin);

    if(path == curFile->name){
	yyerror("Files should NOT @include themselves\n");
	return;
    }else if (path == (char *)NULL) {
	if(makeDepend){
	    /* warn, but add to dependencies anyway. */
	    yywarning("Couldn't find the include file %s\n",yytext);
	    printf("%s : %s\n", outFile, yytext);
	    fflush(stdout);
	} else {
	    yyerror("Couldn't find include file %s\n", yytext);
	}
	return;
    } else if(makeDepend) {
	printf("%s : %s\n", outFile, includeName);
	fflush(stdout);
    }

    ScanMaybeIncludeFile(path,includeName,newin,localSearch);
}



/***********************************************************************
 *			Scan_Self
 ***********************************************************************
 * SYNOPSIS:	    Handle @self directive
 * CALLED BY:	    ProcessDirective
 * RETURN:	    Nothing
 * SIDE EFFECTS:    '@self' is replaced by 'pself' or '&pself' or '*pselfPtr'
 *		    or '(*pselfPtr)' or 'pselfPtr' as appropriate.
 * STRATEGY:
 *	    if (inside a method) {
 *		if ('@self' is being used as a pointer in a method) {
 *		    we replace '@self' with 'pself'
 *
 *		    Ex.  The typical usage of @self will be as a direct
 *			 replacement for pself.
 *
 *			 'moniker = @self->GI_visMoniker;'
 *
 *					becomes
 *
 *			 'moniker = pself->GI_visMoniker;'
 *
 *		} else ('@self' is not being used as a pointer in a method) {
 *		    we replace '@self' with '&pself'
 *
 *		    Ex.  Assume @self is being passed to a function.
 *			 We want to pass the address of pself so the function
 *			 can access instance data without having to fixup pself
 *
 *			 MyFunc(@self, foo);
 *
 *					becomes
 *
 *			 MyFunc(&pself, foo);
 *
 *	    } else (inside a function) {
 *		if ('@self' is being used in the argument list of a function) {
 *		    we replace '@self' with '*pselfPtr'
 *
 *		    Ex.  When @self is passed to a function, it is really being
 *			 passed a pointer to pself which is a pointer to
 *			 instance data.
 *
 *			 'void MyFunc(GenInstance *@self, int foo)'
 *
 *					becomes
 *
 *			 'void MyFunc(GenInstance **pselfPtr, int foo)'
 *
 *		} else if ('@self' is being used as a pointer in a function) {
 *		    we replace '@self' with '(*pselfPtr)'
 *
 *		    Ex.	 Since @self in a function is a pointer to pself,
 *			 we need to dereference it to get pself.
 *
 *			 'moniker = @self->GI_visMoniker;'
 *
 *					becomes
 *
 *			 'moniker = (*pselfPtr)->GI_visMoniker;'
 *
 *		} else ('@self' is not being used as a pointer in a function) {
 *		    we replace '@self' with 'pselfPtr'
 *
 *		    Ex.	 Assume @self is being passed to another function.
 *			 Then we just pass the pointer to pself.
 *
 *			 'MyFunc(@self, foo);'
 *
 *					becomes
 *
 *			 'MyFunc(pselfPtr, foo);'
 *		}
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Joon	2/ 9/96		Initial Revision
 *
 ***********************************************************************/
static void
Scan_Self(void)
{
    int numberOfCloseParens = 0, isPointer = FALSE;
    register char *strPtr;
    register int c;

    /*
     * If inside the body of a function or method.
     */
    if (numberOfOpenBraces) {
	/*
	 * Find out if @self is being used as a pointer (is followed by '->').
	 */
	do {
	    c = PreProcInput();
	    if (c == ')') {		/* allow ')'s between @self and -> */
		numberOfCloseParens++;
	    } else if (c == '-') {
		c = PreProcInput();
		if (c == '>')
		    isPointer = TRUE;
		unput(c);
		c = '-';
		break;
	    }
	} while (isspace(c) || c == ')');

	/*
	 * Put back all the ')'s and the non-whitespace character.
	 */
	unput(c);
	while (numberOfCloseParens--) {
	    unput(')');
	}
    }

    /*
     * Find out what we want to replace the '@self' keyword with.
     */
    if (curMethod != NullMethod) {
	/*
	 * We're inside a method.
	 */
	if (isPointer) {
	    strPtr = "flesp";		/* 'pself' if used as pointer */
	} else {
	    strPtr = "flesp&";		/* '&pself' if not used as pointer */
	}
    } else {
	/*
	 * We're inside a function.
	 */
	if (numberOfOpenBraces == 0) {
	    strPtr = "rtPflesp*";	/* '*pselfPtr' if function arg list */
	} else if (isPointer) {
	    strPtr = ")rtPflesp*(";	/* '(*pselfPtr)' if used as pointer */
	} else {
	    strPtr = "rtPflesp";	/* 'pselfPtr' if not used as pointer */
	}
    }

    /*
     * Now spit out the '@self' replacement string.
     */
    for (; *strPtr; strPtr++)
	unput(*strPtr);
}


/***********************************************************************
 *				yystdwrap
 ***********************************************************************
 * SYNOPSIS:	  Handle an end-of-file on the current file.
 * CALLED BY:	  yylex when 0 returned from input
 * RETURN:	  FALSE if shouldn't wrap it up.
 * SIDE EFFECTS:  curFile is freed and adjusted
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 2/88		Initial Revision
 *
 ***********************************************************************/
static int
yystdwrap(void)
{
    File    	    	*f;
    char 		*includedFileName = NULL;
    int			result;
    File		*freedFile;

    /*
     * Handle the last localizable chunk at the end of the file.
     */
    if ( localizationRequired ){
	Parse_LocalizationWarning("Missing @localize statement");
	localizationRequired = FALSE;	/* reset the flag */
    }

    /*
     * Close current file
     */
    fclose(yyin);


    /*
     * Switch to next file
     */
    f = curFile->next;

    /*
     * Free up the memory for the ending file
     */
    freedFile = curFile;

    if (f == 0) {
	/*
	 * Nowhere to go from here -- all done
	 */
	result = TRUE;
	goto done;
    } else {
	/*
	 * If we're putting the @include results into a special file
	 * for optimization, close it and write the depends file, and write
	 * out a #include into the file that @included this one.
	 * We don't use the fully resolved pathname, because this
	 * the compiler will find the right one (because its search
	 * path and algorithm is identical to this one).
	 */
	if(optimizeThisFile && allowOptimize){
	    if(foutput){
		fclose(foutput);
		Depends_WriteDepends();
	    }
	    /* we have the choice of putting out something based on the absolute */
	    /* name or the one that cpp will find. We choose to put out an */
	    /* absolute one. Otherwise the use has to set his C path to his -p arg */
	    /*includedFileName = curFile->includeName;*/ /*set for code below*/

	    includedFileName = curFile->name;
	}else if(!optimizeThisFile){
	    File 	*f;
	    char 	*optimizedFile = NULL;
	    for(f = curFile->next; f; f = f->next){
		if(f->optimizeThisFile){
		    optimizedFile = f->name;
		    break;
		}
	    }
	    if(optimizedFile){
		yyerror("the file that @includes this one (%s) is @optimized,"
			"so this one must be too. Please add @optimize to "
			"it, or remove it from the includer.",optimizedFile);
	    }
	}
#if 0
	if(!optimizeThisFile){
	    FILE *x; FILE *y;

	    curFile->name[strlen(curFile->name)]

	    yywarning("looks like it should be an @optimized file(because"
		      "it has \na .gph/.gdh file), but"
		      "doesn't have an @optimized directive.");
	}
#endif
	/*
	 * Switch to previous file
	 */
	curFile = f;
	yyin = f->file;		/* Previous stream */
	yylineno = f->line;	/* previous line number */

	foutput = f->foutput;  /* restore this file's special output file */
	optimizeThisFile 	= f->optimizeThisFile;

	yysptr = yysbot;	/* Discard pushback from current file */
	PopMacro();		/* Recover macro state from previous */

	/*
	 * If we @included an optimized file, put out a #include
	 * we know that fouput is set correctly because we just set it.
	 */
	if(includedFileName){
	    Output("#include \"%s\"\n",
		   Depends_GetFileName(includedFileName,FALSE));
	}
	/* output an #endif for the included file. */
	/* we do this for files that get copied in and for pre-goced ones */
	Output("#endif\n");
	OutputLineNumber(yylineno,curFile->name);

	result = FALSE;
	goto done;
    }
 done:
    if (freedFile != curFile) {
	free((malloc_t)freedFile);
    }
    return result;
}


/* macros used in the lexical analyzer */
/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 *     QUOTE_PROCESS  and    QUOTE_PROCESS_NO_ESCAPE
 * %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 *
 * macros used for processing sequences of chars from input.
 *
 * QUOTE_PROCESS_NO_ESCAPE only looks for EOF or the delimiter(s),
 * QUOTE_PROCESS  looks for EOF, the delimiter(s), and the ESCAPE_CONST.
 *
 *
 * INPUT_CHAR        name of the char to set to input, run checks on
 * LABEL_PREFIX      a unique string (used to generate automatic labels)
 *                   Needed when there are 2+ invocations of the macro
 *                   within the same scope.
 *
 * DELIM_EXP         expression to tell if c is a delimiter
 * ESCAPE_CONST      the escape character, usu. will be '\\'
 *                        (for QUOTE_PROCESS only)
 *
 * INIT_CODE         code to run before processing the input
 * PROCESS_CHAR_CODE   code to process a normal data character from input
 * PROCESS_DELIM_CODE  code to process the delimiter character
 * EOF_ERROR_CODE    code to run after reading the quoted thing
 * END_CODE          code to run after reading the quoted thing
 * STASH_VAR         name of local var for scratchpad use
 * INPUT             name of input function to use
 *
 * if input() returns EOF, executes EOF_ERROR_CODE, then  END_CODE
 *
 *
 * NOTE: for proper termination of the string, stick code that must
 *      be executed into END_CODE, not just PROCESS_DELIM, because
 *      PROCESS_DELIM_CODE will not get executed in case of EOF,
 *      but END_CODE always will.
 *
 *
 *
 *  algorithm:   INIT_CODE
 *               process input chars, escaping those preceded by ESCAPE
 *
 *  terminates on either:
 *              EOF->                EOF_ERROR_CODE, then END_CODE
 *              DELIM->              PROCESS_DELIM_CODE, then END_CODE
 *
 * I had to add SJIS support to this EVIL macro.  If it reads in
 * the 1st byte of a 2-byte SJIS character, it will not treat a
 * following backslash as an escape character.  This is because
 * a byte with the same encoding as backslash is a valid 2nd character
 * of a 2-byte SJIS character.
 */

static inline Boolean
ScanIsSJISSB1(unsigned short c)
{
    return ((defStringType == sjisStringType)
	    && (((c > SJIS_SB_END_1) && (c < SJIS_SB_START_2))
		|| (c > SJIS_SB_END_2)));
}

#define  QUOTE_PROCESS(INPUT_CHAR,LABEL_PREFIX,DELIM_EXP,ESC_CONST,INIT_CODE, \
		       PROCESS_CHAR_CODE, PROCESS_DELIM_CODE, EOF_ERROR_CODE, \
		       END_CODE,INPUT)            \
      INIT_CODE                                   \
{                                                 \
      unsigned short _lastChar = 'a';             \
      for(;;){                                    \
	switch(INPUT_CHAR = INPUT){               \
	case EOF:                                 \
	  goto CONCAT(LABEL_PREFIX,EOF_ERROR);    \
	case ESC_CONST:				  \
	  PROCESS_CHAR_CODE     		  \
          if ((ESC_CONST != '\\')                 \
              || !ScanIsSJISSB1(_lastChar)) {     \
	    INPUT_CHAR = INPUT;			  \
	    if(INPUT_CHAR == EOF)                   \
	      goto CONCAT(LABEL_PREFIX,EOF_ERROR);  \
	    else {				  \
	      PROCESS_CHAR_CODE			  \
	    }					  \
          }                                       \
	  break;				  \
	default:				  \
	    if (DELIM_EXP){                       \
              PROCESS_DELIM_CODE                  \
              goto CONCAT(LABEL_PREFIX,mac_end);  \
	    } else {                              \
	      PROCESS_CHAR_CODE                   \
            }                                     \
	}                                         \
        if (ScanIsSJISSB1(_lastChar)) {           \
	    _lastChar = 'a'; /* cannot be 2 in a row */ \
        } else {                                  \
            _lastChar = INPUT_CHAR;               \
        }            				  \
      }                                           \
}                                                 \
	                                          \
    CONCAT(LABEL_PREFIX,EOF_ERROR):               \
      EOF_ERROR_CODE                              \
    /* FALL THROUGH */                            \
    CONCAT(LABEL_PREFIX,mac_end):                 \
      END_CODE

#define  QUOTE_PROCESS_NO_ESCAPE(INPUT_CHAR,LABEL_PREFIX,DELIM_EXP,INIT_CODE, \
		       PROCESS_CHAR_CODE, PROCESS_DELIM_CODE, EOF_ERROR_CODE, \
		       END_CODE,INPUT)   \
      INIT_CODE                                   \
      for(;;){                                    \
	switch(INPUT_CHAR = INPUT){               \
	case EOF:                                 \
	  goto CONCAT(LABEL_PREFIX,EOF_ERROR);    \
	default:				  \
	    if (DELIM_EXP){                       \
              PROCESS_DELIM_CODE                  \
              goto CONCAT(LABEL_PREFIX,mac_end);  \
	    } else {                              \
	      PROCESS_CHAR_CODE                   \
            }                                     \
	}                                         \
      }						  \
	                                          \
    CONCAT(LABEL_PREFIX,EOF_ERROR):               \
      EOF_ERROR_CODE                              \
    /* FALL THROUGH */                            \
    CONCAT(LABEL_PREFIX,mac_end):                 \
      END_CODE




/*
 * Scan without context  code
 *
 */



/***********************************************************************
 *
 * FUNCTION:	ScanQuotedQuantityAndOutput
 *
 * DESCRIPTION:	Scan a string delmited by  single ('') or double quotes ("")
 *              Put out the delimiter char, followed by
 *              the quoted thing.
 *
 *
 * CALLED BY:	yystdlex, ScanNoContext
 *
 * RETURN:	void
 *
 *
 * GLOBALS USED:  reads from the input stream
 *
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * It is assumed that the delimiter character already got Outputted.
 *
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	josh	7/92		created for goc scanner overhaul
 ***********************************************************************/


static void
ScanQuotedQuantityAndOutput(char delim)
{
  register char c;

  SET_IN_STRING(TRUE);  /* so won't see conditionals after escaped newlines */

#define OUTPUT1 Output("%c", c);
#define OUTPUT2 Output("%c", delim);

  QUOTE_PROCESS(c,                           /* name of input char         */
		lab,                         /* label prefix               */
		(c == delim|| c=='\n'),      /* delim exp                  */
		'\\',                        /* escape is backslash        */
		;,                            /* No INIT CODE               */
		OUTPUT1,             /* output each char           */
		if(c=='\n')                  /* check if ended due to \n   */
   		  yyerror("string does not end before newline");,
		{ /* EOF error:  unterminated string/char const           */
		  if(delim == '\'')
		    yyerror("error in character constant");
		  else if (delim == '"')
		    yyerror("error in string constant");
		},
		OUTPUT2,         /* END CODE: output delimiter */
		PMFInput())                        /* name of temp storage */
#undef OUTPUT1
#undef OUTPUT2

   SET_IN_STRING(FALSE);
}


/***********************************************************************
 *
 * FUNCTION:	ScanQuotedMultiByteStringAndOutput
 *
 * DESCRIPTION:	Scan a multi-byte string delmited by double quotes ("")
 *
 * CALLED BY:	yystdlex, ScanNoContext
 *
 * RETURN:	void
 *
 * GLOBALS USED:  reads from the input stream
 *
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon	7 jun 1994      modifications for GEOS-J
 *
 ***********************************************************************/
static void
ScanQuotedMultiByteStringAndOutput(char prefix)
{
  register unsigned short    c;

  if (prefix == 'L') {
      Output("L\"");
      ScanQuotedQuantityAndOutput('"');
  } else {
      SET_IN_STRING(TRUE);  /* won't see conditionals after escaped newlines */
      QUOTE_PROCESS(c,                           /* name of input char       */
		    lab,                         /* label prefix             */
		    (c == '"' || c == '\n'),     /* delim exp                */
		    '\\',                        /* escape is backslash      */
		    Output("{");,                /* Output the initial quote */
		    /*
		     * See comment in Scan_OutputMultiByteString
		     * for why we output in hex.
		     */
		    Output("0x%04x,", c);
		    ,
		    if(c=='\n')                  /* check if ended due to \n */
		        yyerror("string does not end before newline");,
		    { /* EOF error:  unterminated string/char const          */
			yyerror("error in string constant");
		    },
		Output("0x00}");,       /* END CODE: output delimiter */
		Scan_ScanSJISChar(NULL))        /* name of temp storage */
    SET_IN_STRING(FALSE);
  }
}

/***********************************************************************
 *
 * FUNCTION:	ScanQuotedMultiByteStringAndOutput
 *
 * DESCRIPTION:	Scan a SJIS char delmited by single ('').
 *
 * CALLED BY:	yystdlex, ScanNoContext
 *
 * RETURN:	void
 *
 * GLOBALS USED:  reads from the input stream
 *
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon	7 jun 1994      modifications for GEOS-J
 ***********************************************************************/
static void
ScanQuotedMultiByteCharAndOutput(char prefix)
{
  register unsigned short    c;

#define OUTPUT3 Output("0x%04x", c);

  if (prefix == 'L') {
      Output("L'");
      ScanQuotedQuantityAndOutput('\'');
  } else {
      SET_IN_STRING(TRUE);  /* won't see conditionals after escaped newlines */
      QUOTE_PROCESS(c,                           /* name of input char       */
		    lab,                         /* label prefix             */
		    (c == '\'' || c == '\n'),    /* delim exp                */
		    '\\',                        /* escape is backslash      */
		    ;,                            /* Output the initial quote */
		    /*
		     * See comment in Scan_OutputMultiByteString
		     * for why we output in hex.
		     */
		    OUTPUT3
		    ,
		    if(c=='\n')                  /* check if ended due to \n */
		        yyerror("char constant does not end before newline");,
		    { /* EOF error:  unterminated string/char const          */
			yyerror("error in character constant");
		    },
		    ;,                          /* END CODE: output delimiter */
		    Scan_ScanSJISChar(NULL))          /* name of temp storage */
    SET_IN_STRING(FALSE);
  }
}

/***********************************************************************
 *
 * FUNCTION:	ScanQuotedMultiByteQuantityAndOutput
 *
 * DESCRIPTION:	A simple switch between ScanQuotedMultiByteCharAndOutput
 *              and ScanQuotedMultiByteStringAndOutput.
 *
 * CALLED BY:	ScanNoContext
 *
 * RETURN:	void
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon	7 jun 1994      modifications for GEOS-J
 ***********************************************************************/
static void
ScanQuotedMultiByteQuantityAndOutput(char prefix, char delim)
{
    if (delim == '\'') {
	ScanQuotedMultiByteCharAndOutput(prefix);
    } else {
	ScanQuotedMultiByteStringAndOutput(prefix);
    }
}

/***********************************************************************
 *
 * FUNCTION:	Scan_OutputMultiByteString
 *
 * DESCRIPTION:	Depending on the prefix, this routine will either output
 *              the passed string as an L"" string, or will process the
 *              string as an SJIS encoded string, and will output the
 *              corresponding array of Unicode characters.
 *
 * CALLED BY:	OutputChunk
 *
 * RETURN:	void
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon	7 jun 1994      modifications for GEOS-J
 ***********************************************************************/
void
Scan_OutputMultiByteString(char prefix, char *str)
{
    unsigned short c;
    if (prefix == 'L') {
	Output("L\"%s\"", str);
    } else {
	SET_IN_STRING(TRUE);  /* won't see conditionals after esc'd newlines */
	Output("{");
	while (c = Scan_ScanSJISChar((unsigned char **) &str)) {
	    /*
	     * If we output the strings as characters, i.e. L'\123' or
	     * L'\222\234', then BC4.5J will reverse them, for some
	     * weird reason I don't understand.  But if you output
	     * the characters as hex values (i.e. 0x2354), it won't
	     * touch them.
	     */
	    Output("0x%04x,", c);
	}
	Output("0x00}");
	/* Output("L'\\0'}"); */
	SET_IN_STRING(FALSE);
    }
}

/***********************************************************************
 *
 * FUNCTION:	ScanNoContext
 *
 * DESCRIPTION:	copy input to output while searching for a goc token starting
 *              with an '@', but not the start of a definition,include or
 *              conditional, even though they start with '@'.
 *
 * CALLED BY:	yystdlex
 *
 * RETURN:	last char read from input stream
 *
 *
 * GLOBALS USED:
 *
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * This is the first filter that code goes through.
 *
 *  Reads the input stream, Outputting all the non-goc stuff it can,
 *  when we see an '@', determine if it is a preprocessor directive or not.
 *  if it is not a directive, return.
 *
 *  This uses the SET_VERBATIM macro to ensure that the output looks
 *   EXACTLY like the input.
 *
 *  This routine has been complicated a lot by the need to make it fast.
 *  It does its own processing of conditionals, inclusions and macros,
 *  even though MFInput can do some of those things. The reason is that
 *  this routine buffers up characters to be output (so as to avoid calling
 *  Output for each character). This is necessary because conditionals cause
 *  line directives or sequences or newlines to be output, and we need to
 *  ensure that our buffer gets flushed before either of those get put out.
 *  For example, suppose we flush our buffers mid-token, and start to buffer
 *  up the rest of the token. Then we see a conditional. We must flush the
 *  the buffer and output the end of the word, else we'll output a bunch
 *  of newlines or a line directive, and THEN we'll put out the rest of the
 *  word. Of course, the word will now be split across multiple lines, and
 *  we have two tokens, not one.
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	josh	7/92		change for new goc scanner
 *
 ***********************************************************************/
#define SCAN_NO_CONTEXT_BUF_SIZE 256
#define SCAN_NO_CONTEXT_BUFFER_NEED_TO_FLUSH()   (bufP == endBuf)
#define SCAN_NO_CONTEXT_FLUSH_BUFFER()    do{                        \
        if(bufP!= outBuf){					     \
	    if(foutput){					     \
		fwrite(outBuf,sizeof(char),bufP - outBuf,foutput);   \
	    }           					     \
	    bufP = outBuf;					     \
	}							     \
    }while(0)

#define SCAN_NO_CONTEXT_BUFFER_CHAR(c)               \
    do{                                              \
       (*bufP++ = (c));                              \
       if(SCAN_NO_CONTEXT_BUFFER_NEED_TO_FLUSH()){   \
         SCAN_NO_CONTEXT_FLUSH_BUFFER();      \
       }                                             \
    }while(0)

static char
ScanNoContext(void)
{
  register char c;
  char c2;
  enum PPDirectiveType directive;
  char outBuf[SCAN_NO_CONTEXT_BUF_SIZE];
  register char *bufP = outBuf;
  register char *endBuf = outBuf + SCAN_NO_CONTEXT_BUF_SIZE -1;
  int linesSkipped;

  /*
   * Here we tell MFInput that we want the input unprocessed, and that
   * this routine will handle any conditionals.
   */
  SET_VERBATIM(TRUE); SET_CONDITIONAL(TRUE);
  for(;;){
    c = PMFInput();
  next_char:
    switch(c){
    case '"': case '\'':
      SCAN_NO_CONTEXT_FLUSH_BUFFER();
      Output("%c",c);
      ScanQuotedQuantityAndOutput(c);
      break;

    case '1':                            /* maybe start of ascii string */
      SCAN_NO_CONTEXT_FLUSH_BUFFER();
      c2 = PMFInput();
      if((c2 == '"') || (c2 == '\'')){
	  Output("%c",c2);
	  ScanQuotedQuantityAndOutput(c2);
      } else if(c2 != EOF) {
	  Output("1%c",c2);
      } else {
	  Output("1");
      }
      break;

    case 'T':                            /* maybe start of multi-byte string */
    case 'L':                            /* maybe start of multi-byte string */
    case 'S':                            /* maybe start of multi-byte string */
    case 'J':                            /* maybe start of multi-byte string */
    case 'E':                            /* maybe start of multi-byte string */
      SCAN_NO_CONTEXT_FLUSH_BUFFER();
      c2 = PMFInput();
      if((c2 == '"') || (c2 == '\'')){
	  if (c == 'T') {
	      if (defStringType == lStringType) {
		  ScanQuotedMultiByteQuantityAndOutput('L', c2);
	      } else if (defStringType == sjisStringType) {
		  ScanQuotedMultiByteQuantityAndOutput('S', c2);
	      } else {
		  Output("%c",c2);
		  ScanQuotedQuantityAndOutput(c2);
	      }
	  } else {
	      ScanQuotedMultiByteQuantityAndOutput(c, c2);
	  }
      } else if(c2 != EOF) {
	  Output("%c%c",c,c2);
      } else {
	  Output("%c", c);
      }
      break;

    case '@':                   /* conditional/keyword/cpp-directive follows */
      SCAN_NO_CONTEXT_FLUSH_BUFFER();

      if((linesSkipped = Scan_CheckForConditional())){ /* is a conditional   */
      	  /* after processing, align output with input */
	  OutputLineDirectiveOrNewlines(linesSkipped);
	  break;
      }
      directive = PreProcessorDirectiveType(yytext);    /* check for keyword */
      if(directive == noDirective){              /* not include/define/macro */
	lexContext = LC_PARSE;                   /* XXX switch to parsing */
	goto done;
      }
      SET_VERBATIM(FALSE);               /* remove cruft from input stream   */
      ProcessDirective(directive,yytext);/* process include/macro/definition */
      SET_VERBATIM(TRUE);
      break;

    case EOF:                            /* start next file if possible */
      SCAN_NO_CONTEXT_FLUSH_BUFFER();
      if(yystdwrap() == TRUE)
	goto done;
      break;

    case '/':                            /* may be start of a comment */
      SCAN_NO_CONTEXT_FLUSH_BUFFER();
      c2 = PMFInput();
      if(c2 == '*' || c2 == '/'){
	int linesSkipped = DevourRestOfComment(FALSE, c2 == '/');
	OutputLineDirectiveOrNewlines(linesSkipped);
      } else if(c2 != EOF)
	Output("/%c",c2);
      else
	Output("/");
      break;

    default:
      SCAN_NO_CONTEXT_BUFFER_CHAR(c);
      break;
    }
  }
 done:
  SET_VERBATIM(FALSE);     /* remove cruft from the input stream */
  SET_CONDITIONAL(FALSE);  /* MFInput should process conditionals now */
  return c;
}




/* return a copy of the bytes including start to end-1 */

static char *
CopyStringSection(char *start, char *end)
{
  register char c = *end;
  char *temp = (char *) malloc(end - start + 1);
  MALLOC_CHECK(temp);
  *end = '\0';
  strcpy(temp,start);
  *end = c;
  return temp;
}



/***********************************************************************
 *
 * function:	SkipWhiteSpace
 *
 * description: read from input() up to the next non-blank character.
 *              if it reads any newlines, it will output a line number
 *              directive or newlines to keep the output file in sync
 *              with the input file.
 *
 *              We do it here, rather than at the end of yylex, because
 *              some of the special lexcontexts read many tokens, perhaps
 *              spread over multiple lines, and outputting newlines
 *              between words keeps things in synch much better than doing
 *              the after reading all of the lines.
 *
 * called by:	yystdlex and any other lex functions
 *
 * return:	void
 *
 * known bugs/side effects/caveats/ideas:
 *
 *
 *
 * revision history:
 *	name	date		description
 *	----	----		-----------
 *	josh	7/92		initial revision
 *
 ***********************************************************************/
static void
SkipWhiteSpace(void)
{
  register int newLineCount = 0;
  register char c;
  do{
    c = PreProcInput();
    if(c == EOF)                 /* end of source file */
      break;
    if(c == '\n')
      newLineCount++;
  }while(isspace(c));
  unput(c);
  OutputLineDirectiveOrNewlines(newLineCount);
}




/***********************************************************************
 *
 * function:	ScanIdentifierThing
 *
 * description:	read an identifier from the stream and return a token.
 *              set yylv appropriately. the way the identifier-thing
 *              gets classified (token,symbol,identifier) depends on
 *              the flags passed to this routine, which specify in which
 *              tables the token should be looke up.
 *
 *
 * called by:	yystdlex
 *
 * pass:        yylv             pointer to yystype
 *              icf_flags        identifier classification flags
 *
 * return:	token
 *
 *
 * known bugs/side effects/caveats/ideas:
 *
 *    if the identifier is not one of the types that the flags allow
 *    (e.g. a reserved word or symbol)  return ident as the token.
 *
 *
 * algorithm:
 *
 *   try to scan an identifier.
 *
 *   if fails, print error message and return ident.
 *
 *   icf_res_only: check to see if reserved, return token or ident
 *   icf_res_sym: check to see if reserved, then if sym
 *   icf_res_sym_ident:same as for icf_res_sym, then fallthrough to icf_ident
 *   icf_ident:   return as ident.
 *
 *
 * revision history:
 *	name	date		description
 *	----	----		-----------
 *      josh    7/92            initial version
 *
 ***********************************************************************/
static int
ScanIdentifierThing(YYSTYPE *yylv,char flags)
{
  ReservedWord  *opp;
  Hash_Entry	*entry;
  Symbol        *sym;

  char *text = ScanIdentString(TRUE);

  if(*text == '\0'){                       /* nothing */
    DBPRINTF((stderr, "returning IDENT\n"));
    goto return_ident;
  }


  /*
   * See if the identifier thing was something that we might need to generate
   * a protoMinor reference over.
   */

/*
  ScanProcessStringForProtoMinorReferences(text);
*/

  sym = Symbol_Find(text, TRUE);

  switch(flags){
  case ICF_RES_ONLY:
  case ICF_RES_SYM:
  case ICF_RES_SYM_IDENT:         /* check to see if is a reserved word */

    entry =  Hash_FindEntry(&ReservedWords, text);
    if(entry != NullHash_Entry) {
      opp = (ReservedWord *)Hash_GetValue(entry);

      /* check for special (un)debug tokens */

#ifdef LEXDEBUG
#ifdef  YYDEBUG
      if (opp->token == SPECIAL_DEBUG_TOKEN) {
	lexdebug = yydebug = symdebug = outdebug = 1;
	DBPRINTF((stderr, "\n**** DEBUGGING ON (file %s line %d) ****\n\n",
		  curFile->name, yylineno));
      }
      if (opp->token == SPECIAL_UNDEBUG_TOKEN) {
	lexdebug = yydebug = symdebug = outdebug = 0;
	DBPRINTF((stderr, "\n**** DEBUGGING OFF (file %s line %d) ****\n\n",
		  curFile->name, yylineno));
      }
#endif
#endif
	DBPRINTF((stderr, "returning reserved word <%s>\n", opp->name));
	yylv->sym = NullSymbol;
	return(opp->token);
    }

    if(flags == ICF_RES_ONLY){

      /* flags say that token must be a reserved word and it wasn't */

      yyerror("unrecognized reserved word <%s>", text);
      goto return_ident;
    }

    sym = Symbol_Find(text, TRUE);
    if (sym != NullSymbol) {
      /*
       * special hack -- since we recognize "gi_hints" as a
       * special reserved word (see below), we cannot allow it
       * to be a normal symbol
       */
      yylv->sym = sym;
      DBPRINTF((stderr, "returning sym #%d, <%s>\n",
		sym->type, text));
      return (sym->type);
    }

    if(flags == ICF_RES_SYM){
      yyerror("unrecognized reserved word <%s>", text);
      goto return_ident;
    }

    /* xxx fallthrough for icf_res_sym_ident xxx */

  case ICF_IDENT_ONLY:
    DBPRINTF((stderr, "returning identifier <%s>\n", text));

  return_ident:

    yylv->string = text;
    return IDENT;
  }
  goto return_ident;   /* added by TB to suppress control reaches end of
			* non-void function warning */
}

/***********************************************************************
 *
 * function:	DevourRestOfComment
 *
 * description:	read a comment from input, assuming another routine already
 *              read the first two characters of it: "/*" or "//".
 *              if outputChars is TRUE, devour the comment, else pass it out.
 *		if cppComment is TRUE, then devour c++ comment,
 *		else devour c comment.
 *
 * called by:	ScanNoContext
 *
 * return:	-1 if error, else number of lines skipped.
 *
 *
 * globals used:  reads from the input stream
 *
 *
 * known bugs/side effects/caveats/ideas:
 *
 * read until hitting a '*' or EOF. then:
 *    on EOF: error
 *    on *:  read next char and see if it is a "/".
 *
 * revision history:
 *	name	date		description
 *	----	----		-----------
 *	josh	7/92		change for new goc scanner
 *
 ***********************************************************************/

static int
DevourRestOfComment(Boolean outputChars, Boolean cppComment)
{
  register char c;
  int startline = yylineno;
  int haveError = 0;

  SET_IN_COMMENT(TRUE);
  for (;;) {
    c = PMFInput();
    if (outputChars && c != EOF) {
      Output("%c",c);
    }
  got_char:
    switch(c) {
    case '*':			/* perhaps the end of the comment */
      c = PMFInput();
      if (c == EOF) {
	goto EOF_error;
      }
      if (outputChars) {
	Output("%c",c);
      }
      if (c == '/') {
	goto done;
      }
      goto got_char;		/* might be '*', so go to switch */
    case EOF:
  EOF_error:
      yyerror("EOF before end of comment which began on line %d",startline);
      haveError = 1;
      goto done;
    case '\n':
      if (cppComment) {		/* EOL is end of c++ comment */
	unput('\n');		/* but it's not part of the comment itself */
	goto done;
      }
    }
  }
done:
  SET_IN_COMMENT(FALSE);
  return (haveError)?(-1):(yylineno-startline);
}






/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  ScanQuotedConstantAndReturn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

synopsis:

called by:	yylex

pass:		 delim                 delimiter of constant

                 nullterminate         terminate or not flag

		 firstcharofstringptr  character pointer who's contents
		                       get set to the first character
				       of the string if the pointer is
				       not null. a hack for the character
				       constant routine of yylex, which
				       only wants the read one character.

                 buf                   where string goes

		 pass null (for buf) if this routine needs to make the
		 dynamic buffer.

return:		(char *) to  scanned string. is not surrounded by delimiters,
                so the input sequence:

  		abc"

		would return in a char array =   {a,b,c,0}
		and not
		                                 {'"',a,b,c,'"',0}

                newlines may not appear in character constants.

destroyed:

pseudo code/strategy: iterate through input chars and buffer
                      skipping over escaped chars.

checks:

known bugs/side effects/ideas:

        character constants are not converted from things like 	octal
	chars and \n \t \r. this is sufficient because 	mostly they
	just get output at some later time. when they 	are used for
	kbd_nav or kbd_accel chars, only the simplest 	form 'x' is
	the only one used anyway. therfore it is ok for this routine
	to return them as characters and not just a byte. if the
	caller only wants the first byte, it should pass in
	firstcharofstringptr a pointer to where it wants the byte to go.

	the pointer returned should be deallocated with free().

revision history:
	name	date		description
	----	----		-----------
	jp	7/16/92   	initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

static char *
ScanQuotedConstantAndReturn(char            delim,
			    Boolean         nullTerminate,
			    char           *firstCharOfStringPtr,
			    dynamic_buffer *buffer)
{
  register char c;
  dynamic_buffer dbuf;
  dynamic_buffer *db = &dbuf;           /* init code */

  SET_IN_STRING(TRUE);
  if(buffer == NULL)
    INIT_DYNAMIC_BUFFER(*db,10);
  else
    db = buffer;

#define A_C_T_D_B1 ADD_CHAR_TO_DYNAMIC_BUFFER(c, *db);
#define A_C_T_D_B2 ADD_CHAR_TO_DYNAMIC_BUFFER('\0', *db);
#define A_C_T_D_B3 ADD_CHAR_TO_DYNAMIC_BUFFER((c=='\n')?' ':c,*db);

  QUOTE_PROCESS(c,                           /* name of input char  */
		label,                       /* label prefix        */
		(c == delim || c == '\n'),   /* delim expression    */
		'\\',                        /* escape is backslash */
		;,                            /* no init_code */
		A_C_T_D_B1, /* process normal char */
		;,                            /* do nothing for end quote */
		{ /* EOF error:  unterminated string/char const          */
		  if(delim == '\'')
		    yyerror("error in character constant");
		  else if (delim == '"')
		    yyerror("error in string constant");
		},
		{                            /* end code */
		  if(c == '\n')
		    yyerror("newline before end of string/character constant");
		  if(nullTerminate)
		    A_C_T_D_B2

		  if(firstCharOfStringPtr != NULL)
		    *firstCharOfStringPtr = *(DB_STR(*db));
		},
		PMFInput())
  SET_IN_STRING(FALSE);
  return DB_STR(*db);
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanStringViaTopLevelDelimiters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

synopsis:	buffer input up to and including
                one of two special chars.

		The delimiters
		will be treated as normal chars if they are inside
		special nesting characters or strings ("" or '').
		parentheses always nest, and the parameter nestBraces
		may cause [] and {} to nest too.


		ScanStringViaTopLevelDelimiters(',', '=',...)
		would return:

                v--------------------------v
		 foo(bar,baz(sd,dsf),bop)  = chunklala(asdf ,asdf ) ,

		the reason why it includes the delimiters in the final
		string is that it gets called recursively, and otherwise
		it would always leave out the ])} " ' characters.

		[] and {} do not always nest (e.g. macros)

called by:	yylex

pass:		delimiter_1
		delimiter_2
		nullTerminate          whether or not to finish off the string.
                b                      where to put chars (if not null)
		  pass b=null if this routine needs to create the buffer.



return:		(char *) with chars buffered up to and including a delimiter.
                the buffer will be null terminated if nullTerminate is TRUE.
		the (char *) should be freed later by the caller if this
		routine had to create it.

		EOF from input() will cause an error and terminate the
		scanning loop, although there will be no delimiter in
		the string.


destroyed:	nothing.

pseudo code/strategy:
    iterate through the input characters one at a time.

    if EOF, error and return current buffer.
    else if  current char is  a delimiter, add to buffer and return.
    else if is one of the following: (,",', or perhaps [ and { scan the thing


    therefore, the args to the quote_process_no_escape macro are:

    delim_exp == exp to see if c is one of two delimiters
    process_char_code ==
            append it to the buffer
            if c is special char that needs balancing
	         scan recursively to get past the thunk


    process_delim_code == add delimiter to buffer. for the case of ) et al.
    EOF_error_code == yyerror ("scanner is screwed")
    end_code == terminate buffer, return char *.


checks:

known bugs/side effects/ideas:

revision history:
	name	date		description
	----	----		-----------
	jp	7/16/92   	initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
static char *
ScanStringViaTopLevelDelimiters(char            delim1,
				char            delim2,
				Boolean         nullTerminate,
				dynamic_buffer *buffer,
				Boolean         nestBraces)
{

#define S_Q_C_A_R ScanQuotedConstantAndReturn(c,FALSE,FALSE,db);
#define S_S_V_T_L_D ScanStringViaTopLevelDelimiters(')', ')', FALSE, db, nestBraces);
#define S_S_V_T_L_D2 ScanStringViaTopLevelDelimiters(']', ']', FALSE, db, nestBraces);
#define S_S_V_T_L_D3 ScanStringViaTopLevelDelimiters('}', '}', FALSE, db, nestBraces);
#define S_S_V_T_L_D4 ScanStringViaTopLevelDelimiters(')', ')', FALSE, db, TRUE);
#define S_S_V_T_L_D5 ScanStringViaTopLevelDelimiters(']', ']', FALSE, db, TRUE);
#define S_S_V_T_L_D6 ScanStringViaTopLevelDelimiters('}', '}', FALSE, db, TRUE);

#define Y_Y_E yyerror("goc scanner confused: no '%c' or '%c' found " "before end of file\n", delim1, delim2);

  register char c;
  dynamic_buffer dbuf;
  dynamic_buffer *db = &dbuf;           /* init code */
  if(buffer == NULL)
    INIT_DYNAMIC_BUFFER(*db,10);
  else
    db = buffer;

  QUOTE_PROCESS_NO_ESCAPE(
		c,                                 /* name of input char  */
		lab,                               /* label prefix        */
		(c == delim1 || c == delim2),      /* delim match expression */
		;,                                    /* no init_code */
/* process_char_code */

		A_C_T_D_B1
                switch(c){
		case '"': case '\'':

		  S_Q_C_A_R

		  A_C_T_D_B1 /* put quotes in */
		  break;

		case '(':
		  S_S_V_T_L_D
		  break;
		case '[':
		  if(nestBraces)
		    S_S_V_T_L_D2
		  break;
		case '{':
		  if(nestBraces)
		    S_S_V_T_L_D3
		  break;
		},
    	        A_C_T_D_B1,  /* delimiter */
		{
		  /* EOF error */
		  Y_Y_E
		},
                {                            /* end code */
		  if(nullTerminate)
		    A_C_T_D_B2
		  return DB_STR(*db);
		},
		PreProcInput());
}



void
incRemovedNewLines(char *str)
{
    if(scannerShouldRealignOutputAndInputAfterLC_STRING){
	while(*str!='\0'){
	    if(*str == '\n'){
		numberOfNewlinesDeleted++;
	    }
	    str++;
	}
    }
}



/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanStringToTopLevelDelimiters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

synopsis:	buffer input up to (but not including)
                one of two special chars. the delimiters
		will be skipped if they are inside:
		 () "" '', and if nestbraces is true, [] and {}

		e.g.  ScanStringToTopLevelDelimiters(',', '=',TRUE)
		would return:

                v----------------v
		 foo(bar,baz,bop)  = chunklala(asdf ,asdf ) ,

called by:	yylex

pass:		two delimiter characters
                nestBraces Boolean

return:		(char *) of chars buffered up before delimiter.

destroyed:	nothing.

pseudo code/strategy:
    call ScanStringViaTopLevelDelimiters() to read the string up to
    and including one of the delimiters.

    push the delimiter at the end of the string returned from
    ScanStringViaTopLevelDelimiters().

    must remove blanks from the end of the string, as it might get
    looked up in the symbol table. If the blanks are newlines, inc
    "numberOfNewlinesDeleted" so that yystdlex will realign
    things correctly.


checks:

known bugs/side effects/ideas:

revision history:
	name	date		description
	----	----		-----------
	jp	7/16/92   	initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

static char *
ScanStringToTopLevelDelimiters(char delim1, char delim2,
			       Boolean nestBraces)
{
  char *foo = ScanStringViaTopLevelDelimiters(delim1, delim2,TRUE,NULL,TRUE);
  char *last = PTR_TO_LAST_CHAR_OF_STRING(foo);
  char *old_foo;

  if(*foo == '\0')         /* no text in string */
    goto end;

  /* if there is a delimiter, unput it. */

  if((*last == delim1 || *last == delim2)){
    unput (*last);
    *last-- = '\0';
  }
  /*
   * XXX XXX XXX
   *
   *  Most of the time, we scan the string, but don't put out anything
   *  until later. This is the case with vardata, defaultvalues, objects,
   *  etc.
   *
   * This means that if the string spans multiple lines, we must align
   * the input and output files before we output more stuff to the output
   * file, or it'll be as though the string (and it's newlines) were cut
   * out of the file.
   *
   *  On the other hand, if we do output the string scanned in its place
   *  in the file (perhaps prefacing and followin it with stuff as for
   *  @send,@call,@callsuper, we MUST NOT output newlines, or it'll be
   *  as though we added a bunch of lines in the file.
   *
   * Therefore, we use a flag to say whether or not to output blanks/line
   * directives in the file.
   *
   * Also, the string might have a bunch of blanks at the end, between the
   * end of the string and the terminator.
   * We need to get rid of these because the parser may look up the string
   * we give back in the symbol table, and it can't have newlines, tabs
   * and blanks to identify symbols.
   */
  while(last >= foo && isspace(*last)){  /* remove blanks from end of string */
      if(*last=='\n'){
	  numberOfNewlinesDeleted++;
      }
      *last-- = '\0';
  }
  /* tally up the newlines in the string so we can output them later
   * it will only output if
   * (scannerShouldRealignOutputAndInputAfterLC_STRING == TRUE)
   */

  incRemovedNewLines(foo);

  /*
   * XXX
   * Put foo in the string table. This is wrong for some strings (those
   * that will NEVER get repeated, but it makes sense for things that will
   * appear more than once.
   *
   *  This should change so that the parser will put things into the
   *  string table when it really makes sense. This is not the place
   *  where it should be done.
   */
  old_foo = foo;
  foo = String_Enter(foo, strlen(foo)),
  free(old_foo);

  end:
    return foo;
}







/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanIntFromStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

synopsis: at times, yylex would like to read in an integer from the input
          file. this allows it to read a valid c integer constant.

called by:  yystdlex

pass:	       c:   first character of number (scanned by the caller)

return:		integer scanned from input.

destroyed:	nothing.

pseudo code/strategy:

checks:

known bugs/side effects/ideas:

this code was copied from esp's scanner.


revision history:
	name	date		description
	----	----		-----------
	jp	7/20/92   	initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

static int
ScanIntFromStream(char c)
{
  /*  constant -- figure out the radix  and convert to an integer. */
  int	base = 10;
  long 	n, d;
  char *cp;

  if (c == '0') {
    c = PreProcInput();
    if ((c == 'x') || (c == 'x')) {
      base = 16;
      c = PreProcInput();
    } else {
      /*
       * assume base 8 unless overridden by a suffix character.
       * note for this reason we don't set "baseset".
       */
      base = 8;
    }
  }
  cp = yytext;
  while(isxdigit(c)) {
    *cp++ = c;
    c = PreProcInput();
  }
  *cp++ = '\0';
  unput(c);

  cp = yytext;
  n = 0;
  while (*cp != '\0') {
    n *= base;

    if (*cp <= '9') {
      d = *cp++ - '0';
    } else if (*cp <= 'f') {
      d = *cp++ - 'a' + 10;
    } else {
      d = *cp++ - 'a' + 10;
    }
    if (d < base) {
      n += d;
    } else {
      yyerror("digit %c out of range for base %d number",
	      cp[-1], base);
      break;
    }
  }
  return n;
}



/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanIdentString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

synopsis:	scan an identifier from the input, using yyerror to
                report any errors. If there is an identifier
		at the input and the paramater tells us to, enter it
		into the string table.

		If an identifer is not found, the text will be blank.

called by:	yystdlex

pass:           nothing

return:		char *  to ident's text

destroyed:	nothing.

pseudo code/strategy:

checks:

known bugs/side effects/ideas:

WARNING: if the string is not enterered, it is in a static buffer and
       best not be freed.


revision history:
	name	date		description
	----	----		-----------
	jp	7/21/92   	initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

static char *
ScanIdentString(Boolean should_enter)
{
  register char c;
  int yytext_index; /* where we put the next identifier character */

  for(yytext_index = 0;yytext_index < MAX_TOKEN_LENGTH - 1;yytext_index++){
    c = PreProcInput();
    if(IS_IDENT_CHAR(c))
      yytext[yytext_index] = c;
    else{
      unput(c);
      break;
    }
  }
  yytext[yytext_index] = '\0';
  if(yytext_index == 0){
    yyerror("expected identifier-like-thing but found the char %c",c);
  }

  return should_enter?String_Enter(yytext,strlen(yytext)):yytext;
}






/***********************************************************************
 *				yystdlex
 ***********************************************************************
 * synopsis:	  scan a token out of the input stream and return it.
 * called by:	  yyparse
 * return:	  the token and yylval set appropriately.
 * side effects:  input is taken from the input stream.
 *
 * strategy:
 *
 * revision history:
 *	name	date		description
 *	----	----		-----------
 *	ardeb	9/ 2/88		initial revision
 *
 ***********************************************************************/
int
yystdlex(void)
{
    char *ScanTypeString(Boolean nomatchparens);
    char c, c2;
    char endchar1, endchar2;
    int retValue;

    /*
     * the scanner is heavily dependent on the current context, as reflected
     * the the enumerated variable lexcontext.
     *
     */

 lexcontext_switch_and_scan:
/* turning off optimzied scanner for "depends" mode to avoid problems with '#'
   characters etc. -- mgroeber 5/20/00 */
#if 0
    if (makeDepend)
    {
	/* in make depend mode, we only want to pay attention to defines
	 * and includes
	 */
	while (1)
	{
	    SkipWhiteSpace();
	    c = PreProcInput();
	    switch(c)
	    {
	    	char    *buf;

		/* for '#' characters pass this line on to the output file */
		case '#':
		    buf = ScanStringToTopLevelDelimiters('\n', '\n', TRUE);
		    Output("#");
		    Output(buf);
#if 0
		    if (!strncmp(buf, "line", 4) ||
			!strncmp(buf, "include", 7) ||
			!strncmp(buf, "define", 6) ||
			!strncmp(buf, "if", 2) ||
			!strncmp(buf, "end", 3))
		    {
		    	Output("#");
			Output(buf);
		    }
#endif
		    break;
		case '@':
		    ScanStringToTopLevelDelimiters('\n', '\n', TRUE);
		    break;

                /*
                 * for '"', skip to the end of string, so that we won't
                 * incorrectly treat '#' and '@' within strings as directives.
                 */
                case '"':
                    free(ScanQuotedConstantAndReturn('"', FALSE, NULL, NULL));
                    break;
		case EOF:
		    if (yystdwrap() == TRUE)
		    {
	    	    	return 0;
		    }
	    }
	}
    }
#endif
    DBPRINTF((stderr, "lexcontext is %d\n", lexContext));
    switch (lexContext) {
    case LC_NONE :
    {        /* context means search for '@' or EOF  */
	char c;


	/* scan forward to next important char */
	switch(c = ScanNoContext()){

	case '@':  /* can only return a sym or a reserved word */
	    retValue = ScanIdentifierThing(&yylval,ICF_RES_SYM);
	    goto done;
	case EOF:  	/* wind things up */
	    retValue =  0;
	    goto done;
	}
    }
    case LC_PARSE:           /* context means basic parsing mode */
    case LC_PARSE_NO_LOOKUP:  {
	/*
	 * skip initial whitespace
	 */
    parseLoop:
	SkipWhiteSpace();

	c = PreProcInput();
	switch(c) {
	case '(':
	case ')':
	case '=':
	case ':':
	case ',':
	case ';':
	case '.':
	case '{':
	case '}':
	case '|':
	case '-':
	case '+':
	case '&':
	case '[':   /* for vardata hints with arrays */
	case ']':
	    /*
	     * operator character -- return it
	     */
	    DBPRINTF((stderr, "returning '%c'\n", c));
	    retValue = c;
	    goto done;
	case EOF:  /* wind things up */
	    if(yystdwrap() == TRUE){
		retValue = c;
		goto doneNoRealignOutput;
	    }
	    goto parseLoop;

	case '1':
	    /* Let's see if it's an STRING constant */
	    c2 = PreProcInput();
	    if (c2 == '"') {
		yylval.string = ScanQuotedConstantAndReturn('"', TRUE, NULL,NULL);
		DBPRINTF((stderr, "returning  ascii string <%s>\n", yylval.string));
		retValue = ASCIISTRING;
		goto done;
	    } else {
		unput(c2);
		/*
		 * Must fall through to default handler for '1'
		 */
	    }

	case '0': case '2': case '3': case '4':
	case '5': case '6': case '7': case '8': case '9':
	    yylval.num = ScanIntFromStream(c);
	    DBPRINTF((stderr, "returning constant <%d>\n", yylval.num));
	    retValue = CONST;
	    goto done;
	case '\'':
	    /* character constant */
	{
	    /*
	     * read in up to the ending '\''. put the first char of the const
	     * in yylval.ch.
	     */
	    char *charconstptr;

	    charconstptr= ScanQuotedConstantAndReturn('\'',FALSE,&yylval.ch,NULL);

	    if(strlen(charconstptr) != 1)
		yyerror("malformed character constant");
	    free(charconstptr);
	    DBPRINTF((stderr, "returning char #%d <%c>\n", yylval.ch, yylval.ch));
	    retValue = CHAR;
	    goto done;
	}
	case '"':
	    /* string constant */

	    yylval.string = ScanQuotedConstantAndReturn('"', TRUE, NULL,NULL);

	    DBPRINTF((stderr, "returning string <%s>\n", yylval.string));
	    retValue = STRING;
	    goto done;

	case 'T':
	    retValue = TSTRING;
	    goto stringCommon;
	case 'S':
	    retValue = SJISSTRING;
	    goto stringCommon;
	case 'L':
	    retValue = LSTRING;

	stringCommon:

	    /* Let's see if it's an LSTRING constant */
	    c2 = PreProcInput();
	    if (c2 == '"') {
		yylval.string = ScanQuotedConstantAndReturn('"', TRUE, NULL,NULL);
		DBPRINTF((stderr, "returning %cstring <%s>\n", c, yylval.string));
		goto done;
	    } else {
		unput(c2);
		/*
		 * Must fall through to default handler for S,J,E,L
		 */
	    }

	case '@':  /* skip the '@', look for an identifier */
	default:

	    if(c == '@'){
		Scan_IdentHadApostropheBeforeIt = TRUE;
		c = PreProcInput();
	    }else {
		Scan_IdentHadApostropheBeforeIt = FALSE;
	    }

	    if(IS_IDENT_CHAR(c)){        /* c is the start of an identifier */
		char identsearchflags;

		unput(c);
		/* reserved word, symbol, ident */
		if(lexContext != LC_PARSE_NO_LOOKUP){
		    identsearchflags = ICF_RES_SYM_IDENT;
		} else {
		    identsearchflags = ICF_IDENT_ONLY;
		}

		retValue = ScanIdentifierThing(&yylval,identsearchflags);

		goto done;
	    } else {  /* char is not an identifier char, but it should be */
		yyerror("extraneous characters '@%c' = 0x%02.2x discarded",c, c);
	    }
	    goto parseLoop;
	}
    }
    case LC_STRING_COLON:
        endchar1 = endchar2 = ':';
        goto continuestring;
    case LC_STRING_SEMI_COLON:
        endchar1 = endchar2 = ';';
        goto continuestring;
    case LC_STRING_RIGHT_PAREN:
        endchar1 = endchar2 = ')';
        goto continuestring;
    case LC_STRING_COMMA:
        endchar1 = endchar2 = ',';
        goto continuestring;
    case LC_STRING_CLOSE_BRACE:
        endchar1 = endchar2 = ']';
        goto continuestring;

 continuestring:{
     int 	startLineNo = yylineno;

     SkipWhiteSpace();

     yylval.string = ScanStringToTopLevelDelimiters(endchar1,endchar2,TRUE);
     if (yylval.string[0] == '\0') { 	/* oh no: no string */
	 goto parseLoop; 		/* go back. returns delimiter or EOF */
     } else {
	 DBPRINTF((stderr, "lc_string_XXX returning <%s>\n", yylval.string));
	 parse_TokenStart = startLineNo;
	 parse_TokenEnd = yylineno;
	 retValue = (FAKESTRING);
	 goto done;
     }
 }
    /*
     * we don't use ScanStringToTopLevelDelimiters because it matches
     * parentheses, and we don't want that. We just want all the crap up
     * to a string.
     * This does the following:
     *   if the next thing is a string or '}', goto parseloop to get it.
     *   if not, it buffers up the characters, processing character
     *   constants correctly (even '}' and '"'), and returns them.
     */
 case LC_CLOSE_CURLY_OR_STRING: {

     register char c;
     dynamic_buffer dbuf;
     dynamic_buffer *db = &dbuf;           /* init code */

     /*
      * This makes sure that we see multi-line comments as a bunch of
      * newlines. The scanner will NOT output newlines (or a directive)
      * but we're cool because we call incRemovedNewLines, which will
      * count the newlines in our string.
      *
      * This crap is necessary so that when we output the gstring, the
      * line  number info in it will be correct, even if there are multi-
      * line comments.
      *
      * XXX Make sure to turn this off before exiting this block! XXX
      */
     SET_COMMENT_AS_NEWLINES(TRUE);

     if((c = PreProcInput())  != '"' && c != '}' && c != EOF){
	 INIT_DYNAMIC_BUFFER(*db,10);
	 do{
	     ADD_CHAR_TO_DYNAMIC_BUFFER(c,*db);
	     if(c == '\''){
		 ScanQuotedConstantAndReturn('\'',FALSE,NULL,db);
		 ADD_CHAR_TO_DYNAMIC_BUFFER(c,*db);
	     }
	 }while((c = PreProcInput()) != '"' && c != '}' && c != EOF);
	 if(c != EOF){
	     unput(c);
	 }
	 ADD_CHAR_TO_DYNAMIC_BUFFER('\0',*db);
	 yylval.string = DB_STR(*db);
	 DBPRINTF((stderr,
		   "lc_close_curly_or_string returning <%s>\n",
		   yylval.string));
	 retValue = (FAKESTRING);
	 /*
	  * Now align the output to the input because the newlines in the
	  * string won't get put out until much later.
	  */
	 incRemovedNewLines(yylval.string);
	 SET_COMMENT_AS_NEWLINES(FALSE);
	 goto done;
     } else {
	 unput(c);
	 SET_COMMENT_AS_NEWLINES(FALSE);
	 goto parseLoop;
     }
 }
 case LC_TYPE_STRING_MATCH_PARENS:
 case LC_TYPE_STRING_NO_MATCH_PARENS: {
     SkipWhiteSpace();
     c = PreProcInput();                       /* check for special goc type */

     if(c == '@'){
	 retValue =  ScanIdentifierThing(&yylval,ICF_RES_ONLY);
	 goto done;
     }
     unput(c);
     /* try to read a string */
     yylval.string=
	 ScanTypeString((lexContext == LC_TYPE_STRING_MATCH_PARENS)?0:1);
     if(*yylval.string != '\0'){
	 DBPRINTF((stderr, "returning STRING  <%s>\n", yylval.string));
	 retValue =  STRING;
	 goto done;
     }
     goto parseLoop;       /* so we return the delimiter */
     /* break; */
 }

    /*
     * messages are screwy because there is an optional list of flags without
     * a clear terminating character. The scanner needs to determine if there
     * is a list, or if it should return something else.
     *
     * after the optionali list of flags comes an optional msg cast:
     *   {MSG_SYM}
     * (e.g. @call ,forceQueue {MSG_FOO} obj::MSG(); )
     *
     * Here is how it works:
     *    If there is a comma, there should be a flag following. eat the comma,
     *       and return the flag.
     *    If the next char is a '{', it is the start of a cast.
     *       return the MSG_SYM  after eating the following '}'.
     *
     *    Otherwise, there appears the object destination. switch
     *    lexical contexts (because it may be more than one token,
     *    and we don't want to buffer up tokens) and then jumpt to
     *    the top of the scanning loop. It will switch on the new
     *    lexContext and return the first token of the object's
     *    destination.
     */

 case LC_PARSE_OBJ_FLAGS_AND_CAST: {
     SkipWhiteSpace();

     if((c = PreProcInput()) == ','){  /* eat comma. no commas in parse.y */
	 SkipWhiteSpace();
	 goto parseLoop;          /* return reserved word */
     }else {                    /* now at a cast or the start of the objdest */
	 if(c == '{'){                        /* start of a cast. */
	     int token = ScanIdentifierThing(&yylval,ICF_RES_SYM);
	     if(token != IDENT){
		 SkipWhiteSpace();
		 if((c = PreProcInput()) == '}'){         /* eat the '}' */
		     retValue = token;
		     goto done;
		 }else{
		     yyerror("expected to see a '}' after the message symbol cast" );
		     /* fallthrough to ident (an bad token) return */
		 }
	     }
	     retValue =  IDENT;
	     goto done;
	 }	else {   /* go back to the top and scan with new context */
	     unput(c);
	     lexContext = LC_PARSE_OBJ_DEST;
	     goto lexcontext_switch_and_scan;
	 }
     }
 }
    /* just like LC_PARSE_OBJ_DEST, but looks for '(' ')' first */

 case LC_PARSE_CALLSUPER_OBJ_DEST: {

     static next_char_is_close_paren = FALSE;

     SkipWhiteSpace();

     if ((c = PreProcInput()) == '('){
	 SkipWhiteSpace();

	 if((c = PreProcInput()) == ')'){
	     /* SUCCESS */

	     unput(')');
	     next_char_is_close_paren = TRUE;
	     retValue = '(';
	     goto done;

	 } else {  /* unput both chars, rescan */

	     unput(c);
	     unput('(');
	     goto switch_context_and_rescan;
	 }

     } else if(next_char_is_close_paren){
	 assert(c == ')');
	 next_char_is_close_paren = FALSE;
	 retValue =  ')';
	 goto done;
     }
     else {
	 unput(c);
     }

     /* FALLTTHROUGH */
 switch_context_and_rescan:

     next_char_is_close_paren = FALSE;
     lexContext = LC_PARSE_OBJ_DEST;
     goto lexcontext_switch_and_scan;

 }



    /*
     * This lexical context returns the various pieces of an object
     * destination (the thing that receives a message in a @call/@send).
     *
     * This context either returns punctuation, strings or reserved
     * words. The reserved words will have '@' chars before them,
     * so this routine cannot be implemented like the other contexts
     * that scan up to punctuation (e.g. LC_STRING_RIGHT_PAREN),
     * as those would return the '@' character and not the token.
     */

 case LC_PARSE_OBJ_DEST: {  /* start of the objDest */
     /*
      * either looking for:                    look for '@'
      *  - string                              return reserved word
      *  - string ',' string                   else scan to ':' or ','
      *  - ';'
      *  - '@'
      */
     SkipWhiteSpace();

     switch(c = PreProcInput()){
     case '@':
	 retValue =  ScanIdentifierThing(&yylval,ICF_RES_ONLY);
	 goto done;

     case ';': case ':': case ',':
	 retValue =  c;
	 goto done;

     default:
	 unput(c);
	 yylval.string = ScanStringToTopLevelDelimiters(',',':',TRUE);
	 if(yylval.string[0] == '\0')
	     yyerror("goc can't determine the object of your message: "
		     "can't find a ':'");

     }
     DBPRINTF((stderr, "LC_PARSE_OBJ_DEST returning STRING <%s>\n",
	       yylval.string));
     retValue = (FAKESTRING);
     goto done;
 }

}  /* end of switch(lexContext)  */

    /* should NEVER EVER be here */
    assert(FALSE);

 done:
    OutputLineDirectiveOrNewlines(numberOfNewlinesDeleted);
 doneNoRealignOutput:
    whichToken++;
    if(whichToken > AFTER_FIRST_OF_FILE){
	whichToken = BEFORE_FILE;
    }
    numberOfNewlinesDeleted = 0;
    return retValue;
}








/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplitTypeString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	break a type declaration string into three parts:
                ctype, ident, typeSuffix.

		assumes there is no blank space at the start of the string.

		e.g.  if typeDecl is "char (*foo)()"

		        ctype = "char (*"
		        ident = "foo"
		        typeSuffix = ")()"

CALLED BY:      yystdlex

PASS:           typeDecl: pointer to declaration in a char[].
                NOTE: typeDecl may not be a null string.

RETURN:		void

DESTROYED:	Nothing.

PSEUDO CODE/STRATEGY:

CHECKS:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
        set *ctype, *id and *typeSuffix to dynamically allocated
	strings that contain the ctype, identifier and typeSuffix.

	How it works:
	  if the last non-blank char of the typeDecl is alpha-numeric,
	      the identifier is at the end of the string.

	  if the last non-blank char of the typeDecl is a ']' or ')',
	     return the id to the left of the leftmost ')' or '['.

	  This only works because we disallow decls of functions,
	  which would look like "foo()" implying id = "foo("

    This function removes spaces from the ends of the three parts.
    e.g.   ctype will be <void>, and not <void    >.
    This is necessary because the parser uses strcmp() to note
    certain special types.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	7/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#define COPY_OF_BLANK_STRING() String_Enter("",0)

void
SplitTypeString(char *typeDecl,char **ctype,char **id,char **typeSuffix)
{
    char *startOfIdent;
    char *endOfIdent;
    char *startOfTypeSuffix;
    char *fromWhereToScan = typeDecl;
    char *endOfTypeDecl = PTR_TO_LAST_CHAR_OF_STRING(typeDecl);

    assert(*typeDecl!= '\0');  /* string must not be null  */

    /* make endOfTypeDecl point to the last non-blank char in typeDecl*/
    while(endOfTypeDecl > typeDecl && isspace(*endOfTypeDecl)){
	endOfTypeDecl--;
    }

    if(isspace (*endOfTypeDecl)){
	yyerror("can't extract type information from a blank declaration");
	goto error;
    }

    switch(*endOfTypeDecl){

    case ')': case ']':  /* id will be to left of the leftmost  ')' OR '[' */
    {
	if((*endOfTypeDecl == ']') && !strchr(typeDecl,'[')){
	    yyerror("can't find necessary '[' in type declaration %s",typeDecl);
	    goto error;
	}
	/* we are guaranteed that one of the two will be in the string */
	while( !(')' == *fromWhereToScan || '[' == *fromWhereToScan))
	    fromWhereToScan++;

	if(fromWhereToScan == typeDecl){
	    yyerror("garbage char(%c) at the start of the type declaration %s",
		    *typeDecl,typeDecl);
	    goto error;
	}

	/* make endOfIdent point to the byte just after the id's last char */

	for(endOfIdent = --fromWhereToScan;isspace(*endOfIdent);--endOfIdent);
	++endOfIdent;

	/* make startOfIdent point to the very first byte */
	for(startOfIdent = endOfIdent -1;
	    startOfIdent >= typeDecl && isotherid(*startOfIdent);
	    startOfIdent--);
	startOfIdent++;

	/*
	 * Scan past any leading whitespace, to deal with defnitions such as:
	 *
	 * @chunk char foo   [] = "whatever";
	 *
	 * Notice the whitespace before the "[]".  It would hose later
	 * usage of strcmp() to identify the type of the identifier.
	 */
	startOfTypeSuffix = endOfIdent;
	while(isspace(*startOfTypeSuffix)) {
	    startOfTypeSuffix++;
	}

	break;
    }
 default:
    endOfIdent   = endOfTypeDecl+1;

    for(startOfIdent = endOfTypeDecl;
	startOfIdent >= typeDecl && isotherid(*startOfIdent);
	startOfIdent--);
    startOfIdent++;

    /*
     * Don't try to skip past any whitespace in this case, because
     * there is no type suffix.  Our pointer would sail off into
     * parts unknown.
     */
    startOfTypeSuffix = endOfIdent;

    break;
}

    /* first cut out the identifier */
    *id         = CopyStringSection(startOfIdent,endOfIdent);

    /* If the ident starts the line, set the ctype to a null string */
    if(startOfIdent == typeDecl){
	yywarning("Expected to find a type for identifer %s",*id);
	*ctype = COPY_OF_BLANK_STRING();  /* THERE IS NO CTYPE */
    } else {
	while(isspace(* (--startOfIdent)));
	startOfIdent++;

	if(*startOfIdent == '@'){
	    startOfIdent--;
	}

	*ctype = CopyStringSection(typeDecl,startOfIdent);
    }

    assert(startOfTypeSuffix <= (endOfTypeDecl + 1));
    *typeSuffix = CopyStringSection(startOfTypeSuffix, endOfTypeDecl + 1);

    DBPRINTF((stderr,"broke the type-declaration-like-string %s into:\n"
	      "\tctype:%s\n\tident:%s\n\ttypeSuffix:%s\n",
	      typeDecl,*ctype,*id,*typeSuffix));
    return;

 error:
    *ctype = *id = *typeSuffix = COPY_OF_BLANK_STRING();
}





/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanTypeStringAndDelimiter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read from the input stream a type declaration like
                (or similar construct) and return a pointer to it.
		This is used to scan the following type sequences:

		char (*foo)() =
		@chunk char foo[];
		@message void MSG_META_OBJ_FLUSH_INPUT_QUEUE(
		          char *foo, char *baz, char *zop)

		goc rarely processes the type information, it usually
		only wants to know the declared identifier. There are
		other routines to break out the identifier.

CALLED BY:	ScanTypeString

PASS:		flag telling whether the '(' is a delmiter of the
                declaration, as in the case of "@message char *foo ("
		or whether they serve the normal duties of parentheses
		in type declarations:  char (*foo)() = baz;

RETURN:		pointer to the scanned characters.

DESTROYED:

PSEUDO CODE/STRATEGY:
     while scanning forward to a delimiter character ',' ';' '=' ')'
            or maybe '('
     scan things surrounded with '(' '[' and '{'  and ')' ']' '}'


CHECKS:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	7/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

static char *
ScanTypeStringAndDelimiter(Boolean parensAsDelimsOrMatch)
{

#define COMMA ','

  register char c;
  dynamic_buffer dbuf;
  dynamic_buffer *db = &dbuf;
  INIT_DYNAMIC_BUFFER(*db,10);

  QUOTE_PROCESS_NO_ESCAPE(
		c,                                 /* name of input char  */
		lab,                               /* label prefix        */
		(c== COMMA ||                      /* delim match expression */
		 c== ';' ||
		 c== '=' ||
		 c== ')' ||
		 (parensAsDelimsOrMatch && c=='(')),
		;,                                    /* no INIT_CODE */
                /* PROCESS_CHAR_CODE */
                switch(c){
		case '(':  /* must be in match mode if '(' wasn't delimiter */
  		  A_C_T_D_B1
		  S_S_V_T_L_D4
		  break;
		case '[':
  		  A_C_T_D_B1
		  S_S_V_T_L_D5
		  break;
		case '{':
  		  A_C_T_D_B1
		  S_S_V_T_L_D6
		  break;
		default:
		  /* If the character is a newline, don't put it in the   */
		  /* string or when we put it out we'll screw up the line */
		  /* number info, because we assume that they're one-line */
		  A_C_T_D_B3
		},
    	        A_C_T_D_B1, /* add delimiter in */
		{
		  /* EOF error */
		  yyerror("goc scanner confused: file ends before "
			  "type declaration ");
		  exit(-1);
		},
                {   /* END code: always null terminate string. */
		  A_C_T_D_B2
		  return DB_STR(*db);
		},
                PreProcInput());
}

char *
ScanTypeString(Boolean noMatchParens)
{
  char *foo = ScanTypeStringAndDelimiter(noMatchParens);
  char *last = PTR_TO_LAST_CHAR_OF_STRING(foo);

  /*
   * unput the final character if the string has any chars at all
   * and the final char is a delimiter.
   * unput the delimiter and set the delimiter in the string to be null.
   */
  if((*foo != '\0') && (*last == ','  ||
			*last == ';'  ||
			*last == '='  ||
			*last == ')'  ||
			(*last == '(' &&
			 noMatchParens))){
    unput(*last);
    *last = '\0';
  }
  return foo;
}










/***********************************************************************
 *
 * FUNCTION:	SkipString
 *
 * DESCRIPTION:	Skip a quoted string
 *
 * CALLED BY:	ScanNoContext, yylex
 *
 * RETURN:	pointer to first charcater after string or NULL
 *	    	if none
 *
 * GLOBALS USED:
 *		linePtr - position in line
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
char *
SkipString(char *cp)
{
    char c;

    switch (c = *cp++) {
        case '"':
	    while ((c = *cp++) != '"') {
		switch (c) {
		    case 0: case '\n':   /* XXX This Was broken */
			return(NULL);
		    case '\\':
			c = *cp++;
			if ((c == 0) || (c == '\n')) {
			    return(NULL);
			}
		}
	    }
	    break;
	case '\'':
	    c = *cp++;
	    if ((c == 0) || (c == '\n')) {
		return(NULL);
	    }
	    c = *cp++;
	    if (c != '\'') {
		return(NULL);
	    }
	    break;
	case '\\':
	    c = *cp++;
	    if ((c == 0) || (c == '\n')) {
		return(NULL);
	    }
	    break;
    }
    return(cp);
}




/***********************************************************************
 *
 * FUNCTION:	FindCharSkipQuotes
 *
 * DESCRIPTION:	Find a character in a string, skipping quoted stuff
 *
 * CALLED BY:	misc
 *
 * RETURN:	pointer to first occurrance of char in string or NULL
 *	    	if not found
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
/*
 * josh:
 *   search for a char in the target, skipping quotes and such, unless the
 *   the desired character is one of the quote delmiters, e.g. " or '.
 *   very much like strindex, but a bit more intelligent.
 */

char *
FindCharSkipQuotes(char *cp, char target)
{
    char c;

    while ( *cp != '\0' ) {
	switch (c = *cp) {
	    case '"': case '\'': case '\\':   /*XXX This Was Broken. */
		/*
		 * Skip quoted strings
		 */
	        if (c == target) {
	            return(cp);
		}
	    	if ((cp = SkipString(cp)) == NULL) {
		    return(NULL);
	    	}
		break;
#if  0   /* REMOVED by josh    Wed Sep 16 */
	    case '\n':
	    	Output("\n");
#endif
	    default:
	        if (c == target) {
	            return(cp);
		}
	    	cp++;
	}
    }
    return NULL;
}



/***********************************************************************
 *
 * FUNCTION:	OurStrPos
 *
 * DESCRIPTION:	Find a string within a string ingoring string constants
 *	    	and character constants
 *
 * CALLED BY:	yyparse
 *
 * RETURN:	pointer to position found (or end of string if none)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
char *
OurStrPos(char *str, char *find)
{
    char *cp;
    char *endPtr = str + strlen(str);

    while (1) {
    	cp = FindCharSkipQuotes(str, find[0]);
    	if (cp == NULL) {
	    return(endPtr);
    	}
	if (!strncmp(cp, find, strlen(find))) {
	    return(cp);
	}
	str = cp + 1;
    }
}




/*
 * Table of keywords that are reserved.
 */
static ReservedWord keywords[] = {
#ifdef LEXDEBUG
#ifdef YYDEBUG
    {"debug", SPECIAL_DEBUG_TOKEN},
    {"undebug", SPECIAL_UNDEBUG_TOKEN},
#endif
#endif

    {"class", CLASS},
    {"meta", META},
    {"master", MASTER},
    {"variant", VARIANT},
    {"endc", ENDC},
    {"classdecl", CLASSDECL},
    {"neverSaved", NEVER_SAVED},
    {"message", MESSAGE},
    {"stack", STACK},
    {"carry", CARRY},
    {"ax", AX},
    {"cx", CX},
    {"dx", DX},
    {"bp", BP},
    {"al", AL},
    {"ah", AH},
    {"cl", CL},
    {"ch", CH},
    {"dl", DL},
    {"dh", DH},
    {"bpl", BPL},
    {"bph", BPH},
    {"ss", SS},
    {"axbpcxdx", AXBPCXDX},
    {"axcxdxbp", AXCXDXBP},
    {"cxdxbpax", CXDXBPAX},
    {"dxcx", DXCX},
    {"bpaxdxcx", BPAXDXCX},
    {"multipleax", MULTIPLEAX},

    {"alias", ALIAS},
    {"prototype", PROTOTYPE},
    {"reserveMessages", RESERVE_MESSAGES},
    {"exportMessages", EXPORT_MESSAGES},
    {"importMessage", IMPORT_MESSAGE},
    {"setMessageNum", SET_MESSAGE_NUM},

    {"instance", INSTANCE},
    {"composite", COMPOSITE},
    {"link", LINK},
    {"visMoniker", VIS_MONIKER},
    {"kbdAccelerator", KBD_ACCELERATOR},
    {"default", DEFAULT},
    {"vardata", VARDATA},
    {"protominor", PROTOMINOR},
    {"protoreset", PROTORESET},
    {"vardataAlias", VARDATA_ALIAS},

    {"reloc", RELOC},
    {"noreloc", NORELOC},
    {"ptr", FPTR},
    {"handle", HPTR},
    {"optr", OPTR},

    {"defaultModel", DEFAULT_MODEL},
    {"method", METHOD},
    {"_far", FAR},
    {"_near", NEAR},
    {"_based", BASED},

    {"call", CALL},
    {"callsuper", CALL_SUPER},
    {"send", SEND},
    {"record", RECORD},
    {"dispatch", DISPATCH},
    {"dispatchcall", DISPATCHCALL},
    {"forceQueue", FORCE_QUEUE},
    {"returnError", RETURN_ERROR},
    {"checkDuplicate", CHECK_DUPLICATE},
    {"checkLastOnly", CHECK_LAST_ONLY},
    {"replace", REPLACE},
    {"insertAtFront", INSERT_AT_FRONT},
    {"canDiscardIfDesperate", CAN_DISCARD_IF_DESPARATE},
    {"noFree", NO_FREE},

    {"parent", PARENT},
    {"children", CHILDREN},

    {"compiler", COMPILER},
    {"highc", HIGHC},
    {"msc", MSC},
    {"start", START},
    {"data", DATA},
    {"notDetachable", NOT_DETACHABLE},
    {"notLMem", NOT_LMEM},
    {"end", END},
    {"header", HEADER},
    {"chunk", CHUNK},
    {"chunkArray", CHUNK_ARRAY},
    {"elementArray", ELEMENT_ARRAY},
    {"object", OBJECT},
    {"specificUI", SPECIFIC_UI},
    {"kbdPath", KBD_PATH},
    {"deflib", DEFLIB},
    {"endlib", ENDLIB},
    {"ignoreDirty", IGNORE_DIRTY},
    {"resourceOutput", RESOURCE_OUTPUT},
    {"extern", EXTERN},
    {"gcnList", GCN_LIST},
    {"gstring", GSTRING_SYM},
    {"localize", LOCALIZE},
    {"optimize", OPTIMIZE},

    {"uses", USES},
    {"not", NOT}
};

/*
 * Structure defining a vis moniker symbol
 */
typedef struct _SpecialSym {
    char    *name;
    int	    type;
    int	    value;
} 	SpecialSym;

static SpecialSym vmSyms[] = {
    {"style",		STYLE_SYM,		0},
    {"size",		SIZE_SYM,		0},
    {"list",		LIST_SYM,		0},
    {"gstring",		GSTRING_SYM,		0},
    {"aspectRatio",	ASPECT_RATIO_SYM,	0},
    {"color",		COLOR_SYM,		0},
    {"cachedSize",	CACHED_SIZE_SYM,	0},

    {"text",		STYLE_COMP_SYM,		VMS_TEXT},
    {"abbrevText",	STYLE_COMP_SYM,		VMS_ABBREV_TEXT},
    {"graphicText",	STYLE_COMP_SYM,		VMS_GRAPHIC_TEXT},
    {"icon",		STYLE_COMP_SYM,		VMS_ICON},
    {"tool",		STYLE_COMP_SYM,		VMS_TOOL},

    {"tiny",	SIZE_COMP_SYM,		DS_TINY},
    {"standard",	SIZE_COMP_SYM,		DS_STANDARD},
    {"large",	SIZE_COMP_SYM,		DS_LARGE},
    {"huge",	SIZE_COMP_SYM,		DS_HUGE},

    {"gray1",	COLOR_COMP_SYM,		DC_GRAY_1},
    {"gray2",	COLOR_COMP_SYM,		DC_GRAY_2},
    {"gray4",	COLOR_COMP_SYM,		DC_GRAY_4},
    {"gray8",	COLOR_COMP_SYM,		DC_GRAY_8},
    {"color2",	COLOR_COMP_SYM,		DC_COLOR_2},
    {"color4",	COLOR_COMP_SYM,		DC_COLOR_4},
    {"color8",  COLOR_COMP_SYM,         DC_COLOR_8},
    {"colorRGB",	COLOR_COMP_SYM,		DC_COLOR_RGB},

    {"normal",	ASPECT_RATIO_COMP_SYM,	DAR_NORMAL},
    {"squished",	ASPECT_RATIO_COMP_SYM,	DAR_SQUISHED},
    {"verySquished", ASPECT_RATIO_COMP_SYM, DAR_VERY_SQUISHED}
};

static SpecialSym kbdSyms[] = {
    {"alt",		KBD_MODIFIER_SYM,	M_ALT},
    {"control",		KBD_MODIFIER_SYM,	M_CTRL},
    {"ctrl",		KBD_MODIFIER_SYM,	M_CTRL},
    {"shift",		KBD_MODIFIER_SYM,	M_SHIFT},

    {"NUMPAD_0",	    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '0'},
    {"NUMPAD_1",	    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '1'},
    {"NUMPAD_2",	    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '2'},
    {"NUMPAD_3",	    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '3'},
    {"NUMPAD_4",	    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '4'},
    {"NUMPAD_5",	    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '5'},
    {"NUMPAD_6",	    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '6'},
    {"NUMPAD_7",	    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '7'},
    {"NUMPAD_8",	    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '8'},
    {"NUMPAD_9",	    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '9'},
    {"NUMPAD_PLUS",    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '+'},
    {"NUMPAD_MINUS",   	KBD_SYM,    	(KEY_NAVIGATION << 16) | '-'},
    {"NUMPAD_DIV",    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '/'},
    {"NUMPAD_MULT",    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '*'},
    {"NUMPAD_PERIOD",   	KBD_SYM,    	(KEY_NAVIGATION << 16) | '.'},
    {"NUMPAD_ENTER",	KBD_SYM,    	(KEY_NAVIGATION << 16) | '\r'},

    {"SPACE",		KBD_SYM,	(KEY_MISC << 16) | 0x20},
    {"TAB",		KBD_SYM,	(KEY_MISC << 16) | 0x9},
    {"ESCAPE",		KBD_SYM,	(KEY_MISC << 16) | 0x1b},
    {"F1",		KBD_SYM,	(KEY_MISC << 16) | 0x80},
    {"F2",		KBD_SYM,	(KEY_MISC << 16) | 0x81},
    {"F3",		KBD_SYM,	(KEY_MISC << 16) | 0x82},
    {"F4",		KBD_SYM,	(KEY_MISC << 16) | 0x83},
    {"F5",		KBD_SYM,	(KEY_MISC << 16) | 0x84},
    {"F6",		KBD_SYM,	(KEY_MISC << 16) | 0x85},
    {"F7",		KBD_SYM,	(KEY_MISC << 16) | 0x86},
    {"F8",		KBD_SYM,	(KEY_MISC << 16) | 0x87},
    {"F9",		KBD_SYM,	(KEY_MISC << 16) | 0x88},
    {"F10",		KBD_SYM,	(KEY_MISC << 16) | 0x89},
    {"F11",		KBD_SYM,	(KEY_MISC << 16) | 0x8a},
    {"F12",		KBD_SYM,	(KEY_MISC << 16) | 0x8b},

    {"UP",		KBD_SYM,	(KEY_NAVIGATION << 16) | 0x90},
    {"DOWN",		KBD_SYM,	(KEY_NAVIGATION << 16) | 0x91},
    {"RIGHT",		KBD_SYM,	(KEY_NAVIGATION << 16) | 0x92},
    {"LEFT",		KBD_SYM,	(KEY_NAVIGATION << 16) | 0x93},
    {"HOME",		KBD_SYM,	(KEY_NAVIGATION << 16) | 0x94},
    {"END",		KBD_SYM,	(KEY_NAVIGATION << 16) | 0x95},
    {"PAGEUP",		KBD_SYM,	(KEY_NAVIGATION << 16) | 0x96},
    {"PAGEDOWN",		KBD_SYM,	(KEY_NAVIGATION << 16) | 0x97},
    {"INSERT",		KBD_SYM,	(KEY_NAVIGATION << 16) | 0x98},
    {"DELETE",		KBD_SYM,	(KEY_NAVIGATION << 16) | 0x9a},
    {"BACKSPACE",	KBD_SYM,	(KEY_NAVIGATION << 16) | 0x8},

    {"MINUS",		KBD_SYM,	(KEY_DIGIT << 16) | '-'},
    {"ENTER",		KBD_SYM,	(KEY_MISC << 16) | '\r'}
};


/***********************************************************************
 *				Scan_MacroInit
 ***********************************************************************
 * SYNOPSIS:	  Initialize the macro module of the scanner
 * CALLED BY:	  main
 * RETURN:	  Nothing
 * SIDE EFFECTS:  inits the macro symbol table
 * WARNING:       Must call this before defining cmdline macros, else
 *                there won't be a macro hash table to insert them into.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	josh	Aug 29, 1992    Initial Revision
 *
 ***********************************************************************/
void
Scan_MacroInit(void)
{
    Hash_InitTable(&macroWords, 16, HASH_STRING_KEYS,3);
}



/***********************************************************************
 *				Scan_Init
 ***********************************************************************
 * SYNOPSIS:	  Initialize the lexical scanner
 * CALLED BY:	  main
 * RETURN:	  Nothing
 * SIDE EFFECTS:  Many and sundry
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 6/88		Initial Revision
 *
 ***********************************************************************/
static MessageParam reloc_params[] = {
{ "vmRelocType", "word", "",&reloc_params[1]},
{ "frame", "word", "",NullParam }
};

void
Scan_Init(void)
{
    ReservedWord	*opp;
    Symbol		*sym;
    SpecialSym	    	*vmp;
    Hash_Entry		*entry;
    Boolean		new;
    int			i;

    Depends_Init();

    Hash_InitTable(&ReservedWords, 16, HASH_ONE_WORD_KEYS, 5);


    i = sizeof(keywords)/sizeof(keywords[0]);
    for (opp = keywords; i > 0; opp++, i--) {
	entry = Hash_CreateEntry(&ReservedWords,
			String_Enter(opp->name, strlen(opp->name)), &new);
	Hash_SetValue(entry, opp);
    }

	/* Initialize the visMonikerScope */

    Symbol_PushScope ( Symbol_NewScope(globalScope, TRUE) );

    i = sizeof(vmSyms)/sizeof(vmSyms[0]);
    for (vmp = vmSyms; i > 0; vmp++, i--) {
	sym = Symbol_Enter( String_Enter(vmp->name, strlen(vmp->name)),
						vmp->type, SYM_DEFINED);
	sym->data.symSpecial.value = vmp->value;
    }
    visMonikerScope = Symbol_PopScope();

	/* Initialize the kbdAcceleratorScope */

    Symbol_PushScope ( Symbol_NewScope(globalScope, TRUE) );

    i = sizeof(kbdSyms)/sizeof(kbdSyms[0]);
    for (vmp = kbdSyms; i > 0; vmp++, i--) {
	sym = Symbol_Enter( String_Enter(vmp->name, strlen(vmp->name)),
						vmp->type, SYM_DEFINED);
	sym->data.symSpecial.value = vmp->value;
    }
    kbdAcceleratorScope = Symbol_PopScope();

    	/* Create the "reloc" message in all its glory. */

    sym = Symbol_Enter(String_Enter("_reloc", 6), MSG_SYM, SYM_DEFINED);
    sym->data.symMessage.class = NullSymbol;
    sym->data.symMessage.nextMessage = NullSymbol;
    sym->data.symMessage.messageNumber = 0;
    sym->data.symMessage.mpd = ((MRT_BYTE_OR_WORD << MPD_RETURN_TYPE_OFFSET) |
				(MRBWT_AX << MPD_RET_WORD_OFFSET) |
				(MPD_REGISTER_PARAMS) |
				(MPR_DX << MPD_PARAM_1_OFFSET) |
				(MPR_BP << MPD_PARAM_2_OFFSET) |
				(MPR_NONE << MPD_PARAM_3_OFFSET));
    sym->data.symMessage.mpdString = "0x623e";
    sym->data.symMessage.firstParam = &reloc_params[0];
    sym->data.symMessage.returnType = "Boolean";
}







/***********************************************************************
*				Scan_StartOptimize
***********************************************************************
* SYNOPSIS:	 if the file needs to be remade, open a file for the
*                output and dependencies.
*
* CALLED BY:	 parser
* RETURN:
* SIDE EFFECTS:
*
* STRATEGY:
*
* REVISION HISTORY:
*	Name	Date		Description
*	----	----		-----------
*	JP	12/ 1/92        Initial Revision
*
***********************************************************************/
void
Scan_StartOptimize (void) {

    char *mutate = 1 + strrchr(curFile->name,'.');

    if(optimizeThisFile == TRUE){
	/* already been here */
	return;
    }

    if(mutate != (char *)1 && *mutate == 'g'){

	if(!allowOptimize){
	    /*
	     * When running under UNIX, this is never true
	     * We've put the check in here so we'll be sure
	     * to see if the thing ends in ".goh".
	     *
	     * Do nothing. 'optimizeThisFile' will remain FALSE.
	     * fouput will still point to the output file.
	     */
	}else if(Depends_ShouldRemake(curFile->name)){
	    OPEN_AND_ASSIGN_OUTPUT_FILE(foutput,
					Depends_GetFileName(curFile->name,
							    FALSE));
	}else{
	    /* if we shouldn't optimize the file, set these to null so */
	    /* we won't output anything.                               */
	    foutput = NULL;
	}
	/*
	 * Record that this file should be optimized. If allowOptimize
	 * is false we won't output anything elsewhere, but we'll do
	 * checks on macro usage. This way people that create bogus UNIX
	 * goh files will find out before other suckers try to make them
	 * on the PC.
	 */
	Depends_MarkOptimize();
	optimizeThisFile 	= TRUE;
    } else{
	yyerror("may only put @optimize in '.g*' files (this avoids file "
		"name clashes).");
    }
}	/* End of Scan_StartOptimize.	*/



/***********************************************************************
 *				Scan_WarnForForwardChunk
 ***********************************************************************
 * SYNOPSIS: assuming the scanner just returned an identifer that should
 *               have had and '@' before it, check that it did and warn
 * 		 if necessary.
 *
 * 		This is meant to be called only for forwardly referenced
 * 		chunks
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	1/ 6/93   	Initial Revision
 *
 ***********************************************************************/
void
Scan_WarnForForwardChunk (char *ident)
{
    if(!Scan_IdentHadApostropheBeforeIt){
	yywarning("The chunk '%s' should have an '@' before it.",
		  ident);
    }
}	/* End of Scan_WarnForForwardChunk.	*/


/***********************************************************************
 *				Scan_Unput
 ***********************************************************************
 * SYNOPSIS:	    Push a character back into the input stream.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    nothing
 * SIDE EFFECTS:    the character will be read on the next call to yylex
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/11/93		Initial Revision
 *
 ***********************************************************************/
void
Scan_Unput(char c)
{
    unput(c);
}


/*
 * This massive table is the heart of the SJIS -> Unicode conversion.
 *
 * Note the gaps from 0x??00 to 0x??3f, and the huge gap from 0xa000 to 0xe03f
 *
 */
static const unsigned short SJISToUnicodeTable[] = {
	C_IDEOGRAPHIC_SPACE,				/* 0x8140 */
	C_IDEOGRAPHIC_COMMA,
	C_IDEOGRAPHIC_PERIOD,
	C_FULLWIDTH_COMMA,
	C_FULLWIDTH_PERIOD,
	C_KATAKANA_MIDDLE_DOT,
	C_FULLWIDTH_COLON,
	C_FULLWIDTH_SEMICOLON,
	C_FULLWIDTH_QUESTION_MARK,			/* 0x8148 */
	C_FULLWIDTH_EXCLAMATION_MARK,
	C_KATAKANA_HIRAGANA_VOICED_SOUND_MARK,
	C_KATAKANA_HIRAGANA_SEMI_VOICED_SOUND_MARK,
	C_SPACING_ACUTE,
	C_FULLWIDTH_SPACING_GRAVE,
	C_SPACING_DIAERESIS,
	C_FULLWIDTH_SPACING_CIRCUMFLEX,
	C_FULLWIDTH_SPACING_MACRON,			/* 0x8150 */
	C_FULLWIDTH_SPACING_UNDERSCORE,
	C_KATAKANA_ITERATION_MARK,
	C_KATAKANA_VOICED_ITERATION_MARK,
	C_HIRAGANA_ITERATION_MARK,
	C_HIRAGANA_VOICED_ITERATION_MARK,
	C_DITTO_MARK,
	C_IDEOGRAPHIC_DITTO_MARK,
	C_IDEOGRAPHIC_ITERATION_MARK,			/* 0x8158 */
	C_IDEOGRAPHIC_CLOSING_MARK,
	C_IDEOGRAPHIC_NUMBER_ZERO,
	C_KATAKANA_HIRAGANA_PROLONGED_SOUND_MARK,
	C_QUOTATION_DASH,
	C_SOFT_HYPHEN,
	C_FULLWIDTH_SLASH,
	C_FULLWIDTH_BACKSLASH,
	C_FULLWIDTH_SPACING_TILDE,			/* 0x8160 */
	C_PARALLEL_TO,
	C_FULLWIDTH_VERTICAL_BAR,
	C_HORIZONTAL_ELLIPSIS,
	C_TWO_DOT_LEADER,
	C_SINGLE_TURNED_COMMA_QUOTATION_MARK,
	C_SINGLE_COMMA_QUOTATION_MARK,
	C_DOUBLE_TURNED_COMMA_QUOTATION_MARK,
	C_DOUBLE_COMMA_QUOTATION_MARK,			/* 0x8168 */
	C_FULLWIDTH_OPENING_PARENTHESIS,
	C_FULLWIDTH_CLOSING_PARENTHESIS,
	C_OPENING_TORTOISE_SHELL_BRACKET,
	C_CLOSING_TORTOISE_SHELL_BRACKET,
	C_FULLWIDTH_OPENING_SQUARE_BRACKET,
	C_FULLWIDTH_CLOSING_SQUARE_BRACKET,
	C_FULLWIDTH_OPENING_CURLY_BRACKET,
	C_FULLWIDTH_CLOSING_CURLY_BRACKET,		/* 0x8170 */
	C_OPENING_ANGLE_BRACKET,
	C_CLOSING_ANGLE_BRACKET,
	C_OPENING_DOUBLE_ANGLE_BRACKET,
	C_CLOSING_DOUBLE_ANGLE_BRACKET,
	C_OPENING_CORNER_BRACKET,
	C_CLOSING_CORNER_BRACKET,
	C_OPENING_WHITE_CORNER_BRACKET,
	C_CLOSING_WHITE_CORNER_BRACKET,			/* 0x8178 */
	C_OPENING_BLACK_LENTICULAR_BRACKET,
	C_CLOSING_BLACK_LENTICULAR_BRACKET,
	C_FULLWIDTH_PLUS_SIGN,
	C_FULLWIDTH_HYPHEN_MINUS,
	C_PLUS_OR_MINUS_SIGN,
	C_MULTIPLICATION_SIGN,
	0,
	C_DIVISION_SIGN,				/* 0x8180 */
	C_FULLWIDTH_EQUALS_SIGN,
	C_NOT_EQUAL_TO,
	C_FULLWIDTH_LESS_THAN_SIGN,
	C_FULLWIDTH_GREATER_THAN_SIGN,
	C_LESS_THAN_OVER_EQUAL_TO,
	C_GREATER_THAN_OVER_EQUAL_TO,
	C_INFINITY,
	C_THEREFORE,					/* 0x8188 */
	C_MALE_SIGN,
	C_FEMALE_SIGN,
	C_DEGREE_SIGN,
	C_PRIME,
	C_DOUBLE_PRIME,
	C_DEGREES_CENTIGRADE,
	C_FULLWIDTH_YEN_SIGN,
	C_FULLWIDTH_DOLLAR_SIGN,			/* 0x8190 */
	C_FULLWIDTH_CENT_SIGN,
	C_FULLWIDTH_POUND_SIGN,
	C_FULLWIDTH_PERCENT_SIGN,
	C_FULLWIDTH_NUMBER_SIGN,
	C_FULLWIDTH_AMPERSAND,
	C_FULLWIDTH_ASTERISK,
	C_FULLWIDTH_COMMERCIAL_AT,
	C_SECTION_SIGN,					/* 0x8198 */
	C_WHITE_STAR,
	C_BLACK_STAR,
	C_WHITE_CIRCLE,
	C_BLACK_CIRCLE,
	C_BULLSEYE,
	C_WHITE_DIAMOND,
	C_BLACK_DIAMOND,
	C_WHITE_SQUARE,					/* 0x81a0 */
	C_BLACK_SQUARE,
	C_WHITE_UP_POINTING_TRIANGLE,
	C_BLACK_UP_POINTING_TRIANGLE,
	C_WHITE_DOWN_POINTING_TRIANGLE,
	C_BLACK_DOWN_POINTING_TRIANGLE,
	C_REFERENCE_MARK,
	C_POSTAL_MARK,
	C_RIGHT_ARROW,					/* 0x81a8 */
	C_LEFT_ARROW,
	C_UP_ARROW,
	C_DOWN_ARROW,
	C_GETA_MARK,
	0,
	0,
	0,
	0,						/* 0x81b0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_ELEMENT_OF,					/* 0x81b8 */
	C_CONTAINS_AS_MEMBER,
	C_SUBSET_OF_OR_EQUAL_TO,
	C_SUPERSET_OF_OR_EQUAL_TO,
	C_SUBSET_OF,
	C_SUPERSET_OF,
	C_UNION,
	C_INTERSECTION,
	0,						/* 0x81c0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_LOGICAL_AND,					/* 0x81c8 */
	C_LOGICAL_OR,
	C_FULLWIDTH_NOT_SIGN,
	C_RIGHT_DOUBLE_ARROW,
	C_LEFT_RIGHT_DOUBLE_ARROW,
	C_FOR_ALL,
	C_THERE_EXISTS,
	0,
	0,						/* 0x81d0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x81d8 */
	0,
	C_ANGLE,
	C_UP_TACK,
	C_ARC,
	C_PARTIAL_DIFFERENTIAL,
	C_NABLA,
	C_IDENTICAL_TO,
	C_APPROXIMATELY_EQUAL_TO_OR_THE_IMAGE_OF,	/* 0x81e0 */
	C_MUCH_LESS_THAN,
	C_MUCH_GREATER_THAN,
	C_SQUARE_ROOT,
	C_REVERSED_TILDE,
	C_PROPORTIONAL_TO,
	C_BECAUSE,
	C_INTEGRAL,
	C_DOUBLE_INTEGRAL,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_ANGSTROM_UNIT,				/* 0x81f0 */
	C_PER_MILLE_SIGN,
	C_SHARP,
	C_FLAT,
	C_EIGHTH_NOTE,
	C_DAGGER,
	C_DOUBLE_DAGGER,
	C_PARAGRAPH_SIGN,
	0,
	0,
	0,
	0,
	C_ENCLOSING_CIRCLE,
	0,
	0,
	0,

	0,						/* 0x8240 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_FULLWIDTH_DIGIT_ZERO,				/* 0x8250 */
	C_FULLWIDTH_DIGIT_ONE,
	C_FULLWIDTH_DIGIT_TWO,
	C_FULLWIDTH_DIGIT_THREE,
	C_FULLWIDTH_DIGIT_FOUR,
	C_FULLWIDTH_DIGIT_FIVE,
	C_FULLWIDTH_DIGIT_SIX,
	C_FULLWIDTH_DIGIT_SEVEN,
	C_FULLWIDTH_DIGIT_EIGHT,
	C_FULLWIDTH_DIGIT_NINE,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_A,		/* 0x8260 */
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_B,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_C,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_D,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_E,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_F,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_G,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_H,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_I,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_J,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_K,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_L,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_M,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_N,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_O,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_P,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_Q,		/* 0x8270 */
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_R,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_S,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_T,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_U,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_V,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_W,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_X,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_Y,
	C_FULLWIDTH_LATIN_CAPITAL_LETTER_Z,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8280 */
	C_FULLWIDTH_LATIN_SMALL_LETTER_A,
	C_FULLWIDTH_LATIN_SMALL_LETTER_B,
	C_FULLWIDTH_LATIN_SMALL_LETTER_C,
	C_FULLWIDTH_LATIN_SMALL_LETTER_D,
	C_FULLWIDTH_LATIN_SMALL_LETTER_E,
	C_FULLWIDTH_LATIN_SMALL_LETTER_F,
	C_FULLWIDTH_LATIN_SMALL_LETTER_G,
	C_FULLWIDTH_LATIN_SMALL_LETTER_H,
	C_FULLWIDTH_LATIN_SMALL_LETTER_I,
	C_FULLWIDTH_LATIN_SMALL_LETTER_J,
	C_FULLWIDTH_LATIN_SMALL_LETTER_K,
	C_FULLWIDTH_LATIN_SMALL_LETTER_L,
	C_FULLWIDTH_LATIN_SMALL_LETTER_M,
	C_FULLWIDTH_LATIN_SMALL_LETTER_N,
	C_FULLWIDTH_LATIN_SMALL_LETTER_O,
	C_FULLWIDTH_LATIN_SMALL_LETTER_P,		/* 0x8290 */
	C_FULLWIDTH_LATIN_SMALL_LETTER_Q,
	C_FULLWIDTH_LATIN_SMALL_LETTER_R,
	C_FULLWIDTH_LATIN_SMALL_LETTER_S,
	C_FULLWIDTH_LATIN_SMALL_LETTER_T,
	C_FULLWIDTH_LATIN_SMALL_LETTER_U,
	C_FULLWIDTH_LATIN_SMALL_LETTER_V,
	C_FULLWIDTH_LATIN_SMALL_LETTER_W,
	C_FULLWIDTH_LATIN_SMALL_LETTER_X,
	C_FULLWIDTH_LATIN_SMALL_LETTER_Y,
	C_FULLWIDTH_LATIN_SMALL_LETTER_Z,
	0,
	0,
	0,
	0,
	C_HIRAGANA_LETTER_SMALL_A,
	C_HIRAGANA_LETTER_A,				/* 0x82a0 */
	C_HIRAGANA_LETTER_SMALL_I,
	C_HIRAGANA_LETTER_I,
	C_HIRAGANA_LETTER_SMALL_U,
	C_HIRAGANA_LETTER_U,
	C_HIRAGANA_LETTER_SMALL_E,
	C_HIRAGANA_LETTER_E,
	C_HIRAGANA_LETTER_SMALL_O,
	C_HIRAGANA_LETTER_O,
	C_HIRAGANA_LETTER_KA,
	C_HIRAGANA_LETTER_GA,
	C_HIRAGANA_LETTER_KI,
	C_HIRAGANA_LETTER_GI,
	C_HIRAGANA_LETTER_KU,
	C_HIRAGANA_LETTER_GU,
	C_HIRAGANA_LETTER_KE,
	C_HIRAGANA_LETTER_GE,				/* 0x82b0 */
	C_HIRAGANA_LETTER_KO,
	C_HIRAGANA_LETTER_GO,
	C_HIRAGANA_LETTER_SA,
	C_HIRAGANA_LETTER_ZA,
	C_HIRAGANA_LETTER_SI,
	C_HIRAGANA_LETTER_ZI,
	C_HIRAGANA_LETTER_SU,
	C_HIRAGANA_LETTER_ZU,
	C_HIRAGANA_LETTER_SE,
	C_HIRAGANA_LETTER_ZE,
	C_HIRAGANA_LETTER_SO,
	C_HIRAGANA_LETTER_ZO,
	C_HIRAGANA_LETTER_TA,
	C_HIRAGANA_LETTER_DA,
	C_HIRAGANA_LETTER_TI,
	C_HIRAGANA_LETTER_DI,				/* 0x82c0 */
	C_HIRAGANA_LETTER_SMALL_TU,
	C_HIRAGANA_LETTER_TU,
	C_HIRAGANA_LETTER_DU,
	C_HIRAGANA_LETTER_TE,
	C_HIRAGANA_LETTER_DE,
	C_HIRAGANA_LETTER_TO,
	C_HIRAGANA_LETTER_DO,
	C_HIRAGANA_LETTER_NA,
	C_HIRAGANA_LETTER_NI,
	C_HIRAGANA_LETTER_NU,
	C_HIRAGANA_LETTER_NE,
	C_HIRAGANA_LETTER_NO,
	C_HIRAGANA_LETTER_HA,
	C_HIRAGANA_LETTER_BA,
	C_HIRAGANA_LETTER_PA,
	C_HIRAGANA_LETTER_HI,				/* 0x82d0 */
	C_HIRAGANA_LETTER_BI,
	C_HIRAGANA_LETTER_PI,
	C_HIRAGANA_LETTER_HU,
	C_HIRAGANA_LETTER_BU,
	C_HIRAGANA_LETTER_PU,
	C_HIRAGANA_LETTER_HE,
	C_HIRAGANA_LETTER_BE,
	C_HIRAGANA_LETTER_PE,
	C_HIRAGANA_LETTER_HO,
	C_HIRAGANA_LETTER_BO,
	C_HIRAGANA_LETTER_PO,
	C_HIRAGANA_LETTER_MA,
	C_HIRAGANA_LETTER_MI,
	C_HIRAGANA_LETTER_MU,
	C_HIRAGANA_LETTER_ME,
	C_HIRAGANA_LETTER_MO,				/* 0x82e0 */
	C_HIRAGANA_LETTER_SMALL_YA,
	C_HIRAGANA_LETTER_YA,
	C_HIRAGANA_LETTER_SMALL_YU,
	C_HIRAGANA_LETTER_YU,
	C_HIRAGANA_LETTER_SMALL_YO,
	C_HIRAGANA_LETTER_YO,
	C_HIRAGANA_LETTER_RA,
	C_HIRAGANA_LETTER_RI,
	C_HIRAGANA_LETTER_RU,
	C_HIRAGANA_LETTER_RE,
	C_HIRAGANA_LETTER_RO,
	C_HIRAGANA_LETTER_SMALL_WA,
	C_HIRAGANA_LETTER_WA,
	C_HIRAGANA_LETTER_WI,
	C_HIRAGANA_LETTER_WE,
	C_HIRAGANA_LETTER_WO,				/* 0x82f0 */
	C_HIRAGANA_LETTER_N,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_KATAKANA_LETTER_SMALL_A,			/* 0x8340 */
	C_KATAKANA_LETTER_A,
	C_KATAKANA_LETTER_SMALL_I,
	C_KATAKANA_LETTER_I,
	C_KATAKANA_LETTER_SMALL_U,
	C_KATAKANA_LETTER_U,
	C_KATAKANA_LETTER_SMALL_E,
	C_KATAKANA_LETTER_E,
	C_KATAKANA_LETTER_SMALL_O,
	C_KATAKANA_LETTER_O,
	C_KATAKANA_LETTER_KA,
	C_KATAKANA_LETTER_GA,
	C_KATAKANA_LETTER_KI,
	C_KATAKANA_LETTER_GI,
	C_KATAKANA_LETTER_KU,
	C_KATAKANA_LETTER_GU,
	C_KATAKANA_LETTER_KE,				/* 0x8350 */
	C_KATAKANA_LETTER_GE,
	C_KATAKANA_LETTER_KO,
	C_KATAKANA_LETTER_GO,
	C_KATAKANA_LETTER_SA,
	C_KATAKANA_LETTER_ZA,
	C_KATAKANA_LETTER_SI,
	C_KATAKANA_LETTER_ZI,
	C_KATAKANA_LETTER_SU,				/* 0x8358 */
	C_KATAKANA_LETTER_ZU,
	C_KATAKANA_LETTER_SE,
	C_KATAKANA_LETTER_ZE,
	C_KATAKANA_LETTER_SO,
	C_KATAKANA_LETTER_ZO,
	C_KATAKANA_LETTER_TA,
	C_KATAKANA_LETTER_DA,
	C_KATAKANA_LETTER_TI,				/* 0x8360 */
	C_KATAKANA_LETTER_DI,
	C_KATAKANA_LETTER_SMALL_TU,
	C_KATAKANA_LETTER_TU,
	C_KATAKANA_LETTER_DU,
	C_KATAKANA_LETTER_TE,
	C_KATAKANA_LETTER_DE,
	C_KATAKANA_LETTER_TO,
	C_KATAKANA_LETTER_DO,				/* 0x8368 */
	C_KATAKANA_LETTER_NA,
	C_KATAKANA_LETTER_NI,
	C_KATAKANA_LETTER_NU,
	C_KATAKANA_LETTER_NE,
	C_KATAKANA_LETTER_NO,
	C_KATAKANA_LETTER_HA,
	C_KATAKANA_LETTER_BA,
	C_KATAKANA_LETTER_PA,				/* 0x8370 */
	C_KATAKANA_LETTER_HI,
	C_KATAKANA_LETTER_BI,
	C_KATAKANA_LETTER_PI,
	C_KATAKANA_LETTER_HU,
	C_KATAKANA_LETTER_BU,
	C_KATAKANA_LETTER_PU,
	C_KATAKANA_LETTER_HE,
	C_KATAKANA_LETTER_BE,				/* 0x8378 */
	C_KATAKANA_LETTER_PE,
	C_KATAKANA_LETTER_HO,
	C_KATAKANA_LETTER_BO,
	C_KATAKANA_LETTER_PO,
	C_KATAKANA_LETTER_MA,
	C_KATAKANA_LETTER_MI,
	0,
	C_KATAKANA_LETTER_MU,				/* 0x8380 */
	C_KATAKANA_LETTER_ME,
	C_KATAKANA_LETTER_MO,
	C_KATAKANA_LETTER_SMALL_YA,
	C_KATAKANA_LETTER_YA,
	C_KATAKANA_LETTER_SMALL_YU,
	C_KATAKANA_LETTER_YU,
	C_KATAKANA_LETTER_SMALL_YO,
	C_KATAKANA_LETTER_YO,				/* 0x8388 */
	C_KATAKANA_LETTER_RA,
	C_KATAKANA_LETTER_RI,
	C_KATAKANA_LETTER_RU,
	C_KATAKANA_LETTER_RE,
	C_KATAKANA_LETTER_RO,
	C_KATAKANA_LETTER_SMALL_WA,
	C_KATAKANA_LETTER_WA,
	C_KATAKANA_LETTER_WI,				/* 0x8390 */
	C_KATAKANA_LETTER_WE,
	C_KATAKANA_LETTER_WO,
	C_KATAKANA_LETTER_N,
	C_KATAKANA_LETTER_VU,
	C_KATAKANA_LETTER_SMALL_KA,
	C_KATAKANA_LETTER_SMALL_KE,
	0,
	0,						/* 0x8398 */
	0,
	0,
	0,
	0,
	0,
	0,
	C_GREEK_CAPITAL_LETTER_ALPHA,
	C_GREEK_CAPITAL_LETTER_BETA,			/* 0x83a0 */
	C_GREEK_CAPITAL_LETTER_GAMMA,
	C_GREEK_CAPITAL_LETTER_DELTA,
	C_GREEK_CAPITAL_LETTER_EPSILON,
	C_GREEK_CAPITAL_LETTER_ZETA,
	C_GREEK_CAPITAL_LETTER_ETA,
	C_GREEK_CAPITAL_LETTER_THETA,
	C_GREEK_CAPITAL_LETTER_IOTA,
	C_GREEK_CAPITAL_LETTER_KAPPA,			/* 0x83a8 */
	C_GREEK_CAPITAL_LETTER_LAMBDA,
	C_GREEK_CAPITAL_LETTER_MU,
	C_GREEK_CAPITAL_LETTER_NU,
	C_GREEK_CAPITAL_LETTER_XI,
	C_GREEK_CAPITAL_LETTER_OMICRON,
	C_GREEK_CAPITAL_LETTER_PI,
	C_GREEK_CAPITAL_LETTER_RHO,
	C_GREEK_CAPITAL_LETTER_SIGMA,			/* 0x83b0 */
	C_GREEK_CAPITAL_LETTER_TAU,
	C_GREEK_CAPITAL_LETTER_UPSILON,
	C_GREEK_CAPITAL_LETTER_PHI,
	C_GREEK_CAPITAL_LETTER_CHI,
	C_GREEK_CAPITAL_LETTER_PSI,
	C_GREEK_CAPITAL_LETTER_OMEGA,
	0,
	0,						/* 0x83b8 */
	0,
	0,
	0,
	0,
	0,
	0,
	C_GREEK_SMALL_LETTER_ALPHA,
	C_GREEK_SMALL_LETTER_BETA,			/* 0x83c0 */
	C_GREEK_SMALL_LETTER_GAMMA,
	C_GREEK_SMALL_LETTER_DELTA,
	C_GREEK_SMALL_LETTER_EPSILON,
	C_GREEK_SMALL_LETTER_ZETA,
	C_GREEK_SMALL_LETTER_ETA,
	C_GREEK_SMALL_LETTER_THETA,
	C_GREEK_SMALL_LETTER_IOTA,
	C_GREEK_SMALL_LETTER_KAPPA,			/* 0x83c8 */
	C_GREEK_SMALL_LETTER_LAMBDA,
	C_GREEK_SMALL_LETTER_MU,
	C_GREEK_SMALL_LETTER_NU,
	C_GREEK_SMALL_LETTER_XI,
	C_GREEK_SMALL_LETTER_OMICRON,
	C_GREEK_SMALL_LETTER_PI,
	C_GREEK_SMALL_LETTER_RHO,
	C_GREEK_SMALL_LETTER_SIGMA,			/* 0x83d0 */
	C_GREEK_SMALL_LETTER_TAU,
	C_GREEK_SMALL_LETTER_UPSILON,
	C_GREEK_SMALL_LETTER_PHI,
	C_GREEK_SMALL_LETTER_CHI,
	C_GREEK_SMALL_LETTER_PSI,
	C_GREEK_SMALL_LETTER_OMEGA,
	0,
	0,						/* 0x83d8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x83e0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x83e8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x83f0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x83f8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_CYRILLIC_CAPITAL_LETTER_A,			/* 0x8440 */
	C_CYRILLIC_CAPITAL_LETTER_BE,
	C_CYRILLIC_CAPITAL_LETTER_VE,
	C_CYRILLIC_CAPITAL_LETTER_GE,
	C_CYRILLIC_CAPITAL_LETTER_DE,
	C_CYRILLIC_CAPITAL_LETTER_IE,
	C_CYRILLIC_CAPITAL_LETTER_IO,
	C_CYRILLIC_CAPITAL_LETTER_ZHE,
	C_CYRILLIC_CAPITAL_LETTER_ZE,			/* 0x8448 */
	C_CYRILLIC_CAPITAL_LETTER_II,
	C_CYRILLIC_CAPITAL_LETTER_SHORT_II,
	C_CYRILLIC_CAPITAL_LETTER_KA,
	C_CYRILLIC_CAPITAL_LETTER_EL,
	C_CYRILLIC_CAPITAL_LETTER_EM,
	C_CYRILLIC_CAPITAL_LETTER_EN,
	C_CYRILLIC_CAPITAL_LETTER_O,
	C_CYRILLIC_CAPITAL_LETTER_PE,			/* 0x8450 */
	C_CYRILLIC_CAPITAL_LETTER_ER,
	C_CYRILLIC_CAPITAL_LETTER_ES,
	C_CYRILLIC_CAPITAL_LETTER_TE,
	C_CYRILLIC_CAPITAL_LETTER_U,
	C_CYRILLIC_CAPITAL_LETTER_EF,
	C_CYRILLIC_CAPITAL_LETTER_KHA,
	C_CYRILLIC_CAPITAL_LETTER_TSE,
	C_CYRILLIC_CAPITAL_LETTER_CHE,			/* 0x8458 */
	C_CYRILLIC_CAPITAL_LETTER_SHA,
	C_CYRILLIC_CAPITAL_LETTER_SHCHA,
	C_CYRILLIC_CAPITAL_LETTER_HARD_SIGN,
	C_CYRILLIC_CAPITAL_LETTER_YERI,
	C_CYRILLIC_CAPITAL_LETTER_SOFT_SIGN,
	C_CYRILLIC_CAPITAL_LETTER_REVERSED_E,
	C_CYRILLIC_CAPITAL_LETTER_IU,
	C_CYRILLIC_CAPITAL_LETTER_IA,			/* 0x8460 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8468 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_CYRILLIC_SMALL_LETTER_A,			/* 0x8470 */
	C_CYRILLIC_SMALL_LETTER_BE,
	C_CYRILLIC_SMALL_LETTER_VE,
	C_CYRILLIC_SMALL_LETTER_GE,
	C_CYRILLIC_SMALL_LETTER_DE,
	C_CYRILLIC_SMALL_LETTER_IE,
	C_CYRILLIC_SMALL_LETTER_IO,
	C_CYRILLIC_SMALL_LETTER_ZHE,
	C_CYRILLIC_SMALL_LETTER_ZE,			/* 0x8478 */
	C_CYRILLIC_SMALL_LETTER_II,
	C_CYRILLIC_SMALL_LETTER_SHORT_II,
	C_CYRILLIC_SMALL_LETTER_KA,
	C_CYRILLIC_SMALL_LETTER_EL,
	C_CYRILLIC_SMALL_LETTER_EM,
	C_CYRILLIC_SMALL_LETTER_EN,
	0,
	C_CYRILLIC_SMALL_LETTER_O,			/* 0x8480 */
	C_CYRILLIC_SMALL_LETTER_PE,
	C_CYRILLIC_SMALL_LETTER_ER,
	C_CYRILLIC_SMALL_LETTER_ES,
	C_CYRILLIC_SMALL_LETTER_TE,
	C_CYRILLIC_SMALL_LETTER_U,
	C_CYRILLIC_SMALL_LETTER_EF,
	C_CYRILLIC_SMALL_LETTER_KHA,
	C_CYRILLIC_SMALL_LETTER_TSE,			/* 0x8488 */
	C_CYRILLIC_SMALL_LETTER_CHE,
	C_CYRILLIC_SMALL_LETTER_SHA,
	C_CYRILLIC_SMALL_LETTER_SHCHA,
	C_CYRILLIC_SMALL_LETTER_HARD_SIGN,
	C_CYRILLIC_SMALL_LETTER_YERI,
	C_CYRILLIC_SMALL_LETTER_SOFT_SIGN,
	C_CYRILLIC_SMALL_LETTER_REVERSED_E,
	C_CYRILLIC_SMALL_LETTER_IU,			/* 0x8490 */
	C_CYRILLIC_SMALL_LETTER_IA,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8498 */
	0,
	0,
	0,
	0,
	0,
	0,
	C_FORMS_LIGHT_HORIZONTAL,
	C_FORMS_LIGHT_VERTICAL,				/* 0x84a0 */
	C_FORMS_LIGHT_DOWN_AND_RIGHT,
	C_FORMS_LIGHT_DOWN_AND_LEFT,
	C_FORMS_LIGHT_UP_AND_LEFT,
	C_FORMS_LIGHT_UP_AND_RIGHT,
	C_FORMS_LIGHT_VERTICAL_AND_RIGHT,
	C_FORMS_LIGHT_DOWN_AND_HORIZONTAL,
	C_FORMS_LIGHT_VERTICAL_AND_LEFT,
	C_FORMS_LIGHT_UP_AND_HORIZONTAL,		/* 0x84a8 */
	C_FORMS_LIGHT_VERTICAL_AND_HORIZONTAL,
	C_FORMS_HEAVY_HORIZONTAL,
	C_FORMS_HEAVY_VERTICAL,
	C_FORMS_HEAVY_DOWN_AND_RIGHT,
	C_FORMS_HEAVY_DOWN_AND_LEFT,
	C_FORMS_HEAVY_UP_AND_LEFT,
	C_FORMS_HEAVY_UP_AND_RIGHT,
	C_FORMS_HEAVY_VERTICAL_AND_RIGHT,		/* 0x84b0 */
	C_FORMS_HEAVY_DOWN_AND_HORIZONTAL,
	C_FORMS_HEAVY_VERTICAL_AND_LEFT,
	C_FORMS_HEAVY_UP_AND_HORIZONTAL,
	C_FORMS_HEAVY_VERTICAL_AND_HORIZONTAL,
	C_FORMS_VERTICAL_HEAVY_AND_RIGHT_LIGHT,
	C_FORMS_DOWN_LIGHT_AND_HORIZONTAL_HEAVY,
	C_FORMS_VERTICAL_HEAVY_AND_LEFT_LIGHT,
	C_FORMS_UP_LIGHT_AND_HORIZONTAL_HEAVY,		/* 0x84b8 */
	C_FORMS_VERTICAL_LIGHT_AND_HORIZONTAL_HEAVY,
	C_FORMS_VERTICAL_LIGHT_AND_RIGHT_HEAVY,
	C_FORMS_DOWN_HEAVY_AND_HORIZONTAL_LIGHT,
	C_FORMS_VERTICAL_LIGHT_AND_LEFT_HEAVY,
	C_FORMS_UP_HEAVY_AND_HORIZONTAL_LIGHT,
	C_FORMS_VERTICAL_HEAVY_AND_HORIZONTAL_LIGHT,
	0,
	0,						/* 0x84c0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x84c8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x84d0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x84d8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x84e0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x84e8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x84f0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x84f8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8540 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8548 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8550 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8558 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8560 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8568 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8570 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8578 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8580 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8588 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8590 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8598 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x85a0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x85a8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x85b0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x85b8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x85c0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x85c8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x85d0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x85d8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x85e0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x85e8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x85f0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x85f8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8640 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8648 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8650 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8658 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8660 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8668 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8670 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8678 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8680 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8688 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8690 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x8698 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x86a0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x86a8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x86b0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x86b8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x86c0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x86c8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x86d0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x86d8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x86e0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x86e8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x86f0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x86f8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	C_CIRCLED_DIGIT_ONE,				/*  (U+2460) 0x8740 */
	C_CIRCLED_DIGIT_TWO,				/*  (U+2461) */
	C_CIRCLED_DIGIT_THREE,				/*  (U+2462) */
	C_CIRCLED_DIGIT_FOUR,				/*  (U+2463) */
	C_CIRCLED_DIGIT_FIVE,				/*  (U+2464) */
	C_CIRCLED_DIGIT_SIX,				/*  (U+2465) */
	C_CIRCLED_DIGIT_SEVEN,				/*  (U+2466) */
	C_CIRCLED_DIGIT_EIGHT,				/*  (U+2467) */
	C_CIRCLED_DIGIT_NINE,				/*  (U+2468) 0x8748 */
	C_CIRCLED_NUMBER_TEN,				/*  (U+2469) */
	C_CIRCLED_NUMBER_ELEVEN,			/*  (U+246a) */
	C_CIRCLED_NUMBER_TWELVE,			/*  (U+246b) */
	C_CIRCLED_NUMBER_THIRTEEN,			/*  (U+246c) */
	C_CIRCLED_NUMBER_FOURTEEN,			/*  (U+246d) */
	C_CIRCLED_NUMBER_FIFTEEN,			/*  (U+246e) */
	C_CIRCLED_NUMBER_SIXTEEN,			/*  (U+246f) */
	C_CIRCLED_NUMBER_SEVENTEEN,			/*  (U+2470) 0x8750 */
	C_CIRCLED_NUMBER_EIGHTEEN,			/*  (U+2471) */
	C_CIRCLED_NUMBER_NINETEEN,			/*  (U+2472) */
	C_CIRCLED_NUMBER_TWENTY,			/*  (U+2473) */
	C_ROMAN_NUMERAL_ONE,				/*  (U+2160) */
	C_ROMAN_NUMERAL_TWO,				/*  (U+2161) */
	C_ROMAN_NUMERAL_THREE,				/*  (U+2162) */
	C_ROMAN_NUMERAL_FOUR,				/*  (U+2163) */
	C_ROMAN_NUMERAL_FIVE,				/*  (U+2164) 0x8758 */
	C_ROMAN_NUMERAL_SIX,				/*  (U+2165) */
	C_ROMAN_NUMERAL_SEVEN,				/*  (U+2166) */
	C_ROMAN_NUMERAL_EIGHT,				/*  (U+2167) */
	C_ROMAN_NUMERAL_NINE,				/*  (U+2168) */
	C_ROMAN_NUMERAL_TEN,				/*  (U+2169) */
	0,
	C_SQUARED_MIRI,					/*  (U+3349) */
	C_SQUARED_KIRO,					/*  (U+3314) 0x8760 */
	C_SQUARED_SENTI,				/*  (U+3322) */
	C_SQUARED_MEETORU,				/*  (U+334d) */
	C_SQUARED_GURAMU,				/*  (U+3318) */
	C_SQUARED_TON,					/*  (U+3327) */
	C_SQUARED_AARU,					/*  (U+3303) */
	C_SQUARED_HEKUTAARU,				/*  (U+3336) */
	C_SQUARED_RITTORU,				/*  (U+3351) */
	C_SQUARED_WATTO,				/*  (U+3357) 0x8768 */
	C_SQUARED_KARORII,				/*  (U+330d) */
	C_SQUARED_DORU,					/*  (U+3326) */
	C_SQUARED_SENTO,				/*  (U+3323) */
	C_SQUARED_PAASENTO,				/*  (U+332b) */
	C_SQUARED_MIRIBAARU,				/*  (U+334a) */
	C_SQUARED_PEEZI,				/*  (U+333b) */
	C_SQUARED_MM,					/*  (U+339c) */
	C_SQUARED_CM,					/*  (U+339d) 0x8770 */
	C_SQUARED_KM,					/*  (U+339e) */
	C_SQUARED_MG,					/*  (U+338e) */
	C_SQUARED_KG,					/*  (U+338f) */
	C_SQUARED_CC,					/*  (U+33c4) */
	C_SQUARED_M_SQUARED,				/*  (U+33a1) */
	0,
	0,
	0,						/*          0x8778 */
	0,
	0,
	0,
	0,
	0,
	C_SQUARED_TWO_IDEOGRAPHS_ERA_NAME_HEISEI,	/*  (U+337b) */
	0,
	C_REVERSED_DOUBLE_PRIME_QUOTATION_MARK,		/*  (U+301d) 0x8780 */
	C_LOW_DOUBLE_PRIME_QUOTATION_MARK,		/*  (U+301f) */
	C_NUMERO,					/*  (U+2116) */
	C_SQUARED_KK,					/*  (U+33cd) */
	C_T_E_L_SYMBOL,					/*  (U+2121) */
	C_CIRCLED_IDEOGRAPH_HIGH,			/*  (U+32a4) */
	C_CIRCLED_IDEOGRAPH_CENTER,			/*  (U+32a5) */
	C_CIRCLED_IDEOGRAPH_LOW,			/*  (U+32a6) */
	C_CIRCLED_IDEOGRAPH_LEFT,			/*  (U+32a7) 0x8788 */
	C_CIRCLED_IDEOGRAPH_RIGHT,			/*  (U+32a8) */
	C_PARENTHESIZED_IDEOGRAPH_STOCK,		/*  (U+3231) */
	C_PARENTHESIZED_IDEOGRAPH_HAVE,			/*  (U+3232) */
	C_PARENTHESIZED_IDEOGRAPH_REPRESENT,		/*  (U+3239) */
	C_SQUARED_TWO_IDEOGRAPHS_ERA_NAME_MEIZI,	/*  (U+337e) */
	C_SQUARED_TWO_IDEOGRAPHS_ERA_NAME_TAISYOU,	/*  (U+337d) */
	C_SQUARED_TWO_IDEOGRAPHS_ERA_NAME_SYOUWA,	/*  (U+337c) */
	C_APPROXIMATELY_EQUAL_TO_OR_THE_IMAGE_OF,	/*  (U+2252) 0x8790 */
	C_IDENTICAL_TO,					/*  (U+2261) */
	C_INTEGRAL,					/*  (U+222b) */
	C_CONTOUR_INTEGRAL,				/*  (U+222e) */
	C_N_ARY_SUMMATION,				/*  (U+2211) */
	C_SQUARE_ROOT,					/*  (U+221a) */
	C_UP_TACK,					/*  (U+22a5) */
	C_ANGLE,					/*  (U+2220) */
	C_RIGHT_ANGLE,					/*  (U+221f) 0x8798 */
	C_RIGHT_TRIANGLE,				/*  (U+22bf) */
	C_BECAUSE,					/*  (U+2235) */
	C_INTERSECTION,					/*  (U+2229) */
	C_UNION,					/*  (U+222a) */
	0,
	0,
	0,
	0,						/* 0x87a0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x87a8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x87b0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x87b8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x87c0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x87c8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x87d0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x87d8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x87e0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x87e8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x87f0 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,						/* 0x87f8 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,

/* Kanji start */

	0,					/* 0x8840 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,					/* 0x8850 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,					/* 0x8860 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,					/* 0x8870 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,					/* 0x8880 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,					/* 0x8890 */
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,					/* 0x889e */
	C_KANJI_JIS_3021, /*  0x889f (U+4e9c) */
	C_KANJI_JIS_3022, /*  0x88a0 (U+5516) */
	C_KANJI_JIS_3023, /*  0x88a1 (U+5a03) */
	C_KANJI_JIS_3024, /*  0x88a2 (U+963f) */
	C_KANJI_JIS_3025, /*  0x88a3 (U+54c0) */
	C_KANJI_JIS_3026, /*  0x88a4 (U+611b) */
	C_KANJI_JIS_3027, /*  0x88a5 (U+6328) */
	C_KANJI_JIS_3028, /*  0x88a6 (U+59f6) */
	C_KANJI_JIS_3029, /*  0x88a7 (U+9022) */
	C_KANJI_JIS_302A, /*  0x88a8 (U+8475) */
	C_KANJI_JIS_302B, /*  0x88a9 (U+831c) */
	C_KANJI_JIS_302C, /*  0x88aa (U+7a50) */
	C_KANJI_JIS_302D, /*  0x88ab (U+60aa) */
	C_KANJI_JIS_302E, /*  0x88ac (U+63e1) */
	C_KANJI_JIS_302F, /*  0x88ad (U+6e25) */
	C_KANJI_JIS_3030, /*  0x88ae (U+65ed) */
	C_KANJI_JIS_3031, /*  0x88af (U+8466) */
	C_KANJI_JIS_3032, /*  0x88b0 (U+82a6) */
	C_KANJI_JIS_3033, /*  0x88b1 (U+9bf5) */
	C_KANJI_JIS_3034, /*  0x88b2 (U+6893) */
	C_KANJI_JIS_3035, /*  0x88b3 (U+5727) */
	C_KANJI_JIS_3036, /*  0x88b4 (U+65a1) */
	C_KANJI_JIS_3037, /*  0x88b5 (U+6271) */
	C_KANJI_JIS_3038, /*  0x88b6 (U+5b9b) */
	C_KANJI_JIS_3039, /*  0x88b7 (U+59d0) */
	C_KANJI_JIS_303A, /*  0x88b8 (U+867b) */
	C_KANJI_JIS_303B, /*  0x88b9 (U+98f4) */
	C_KANJI_JIS_303C, /*  0x88ba (U+7d62) */
	C_KANJI_JIS_303D, /*  0x88bb (U+7dbe) */
	C_KANJI_JIS_303E, /*  0x88bc (U+9b8e) */
	C_KANJI_JIS_303F, /*  0x88bd (U+6216) */
	C_KANJI_JIS_3040, /*  0x88be (U+7c9f) */
	C_KANJI_JIS_3041, /*  0x88bf (U+88b7) */
	C_KANJI_JIS_3042, /*  0x88c0 (U+5b89) */
	C_KANJI_JIS_3043, /*  0x88c1 (U+5eb5) */
	C_KANJI_JIS_3044, /*  0x88c2 (U+6309) */
	C_KANJI_JIS_3045, /*  0x88c3 (U+6697) */
	C_KANJI_JIS_3046, /*  0x88c4 (U+6848) */
	C_KANJI_JIS_3047, /*  0x88c5 (U+95c7) */
	C_KANJI_JIS_3048, /*  0x88c6 (U+978d) */
	C_KANJI_JIS_3049, /*  0x88c7 (U+674f) */
	C_KANJI_JIS_304A, /*  0x88c8 (U+4ee5) */
	C_KANJI_JIS_304B, /*  0x88c9 (U+4f0a) */
	C_KANJI_JIS_304C, /*  0x88ca (U+4f4d) */
	C_KANJI_JIS_304D, /*  0x88cb (U+4f9d) */
	C_KANJI_JIS_304E, /*  0x88cc (U+5049) */
	C_KANJI_JIS_304F, /*  0x88cd (U+56f2) */
	C_KANJI_JIS_3050, /*  0x88ce (U+5937) */
	C_KANJI_JIS_3051, /*  0x88cf (U+59d4) */
	C_KANJI_JIS_3052, /*  0x88d0 (U+5a01) */
	C_KANJI_JIS_3053, /*  0x88d1 (U+5c09) */
	C_KANJI_JIS_3054, /*  0x88d2 (U+60df) */
	C_KANJI_JIS_3055, /*  0x88d3 (U+610f) */
	C_KANJI_JIS_3056, /*  0x88d4 (U+6170) */
	C_KANJI_JIS_3057, /*  0x88d5 (U+6613) */
	C_KANJI_JIS_3058, /*  0x88d6 (U+6905) */
	C_KANJI_JIS_3059, /*  0x88d7 (U+70ba) */
	C_KANJI_JIS_305A, /*  0x88d8 (U+754f) */
	C_KANJI_JIS_305B, /*  0x88d9 (U+7570) */
	C_KANJI_JIS_305C, /*  0x88da (U+79fb) */
	C_KANJI_JIS_305D, /*  0x88db (U+7dad) */
	C_KANJI_JIS_305E, /*  0x88dc (U+7def) */
	C_KANJI_JIS_305F, /*  0x88dd (U+80c3) */
	C_KANJI_JIS_3060, /*  0x88de (U+840e) */
	C_KANJI_JIS_3061, /*  0x88df (U+8863) */
	C_KANJI_JIS_3062, /*  0x88e0 (U+8b02) */
	C_KANJI_JIS_3063, /*  0x88e1 (U+9055) */
	C_KANJI_JIS_3064, /*  0x88e2 (U+907a) */
	C_KANJI_JIS_3065, /*  0x88e3 (U+533b) */
	C_KANJI_JIS_3066, /*  0x88e4 (U+4e95) */
	C_KANJI_JIS_3067, /*  0x88e5 (U+4ea5) */
	C_KANJI_JIS_3068, /*  0x88e6 (U+57df) */
	C_KANJI_JIS_3069, /*  0x88e7 (U+80b2) */
	C_KANJI_JIS_306A, /*  0x88e8 (U+90c1) */
	C_KANJI_JIS_306B, /*  0x88e9 (U+78ef) */
	C_KANJI_JIS_306C, /*  0x88ea (U+4e00) */
	C_KANJI_JIS_306D, /*  0x88eb (U+58f1) */
	C_KANJI_JIS_306E, /*  0x88ec (U+6ea2) */
	C_KANJI_JIS_306F, /*  0x88ed (U+9038) */
	C_KANJI_JIS_3070, /*  0x88ee (U+7a32) */
	C_KANJI_JIS_3071, /*  0x88ef (U+8328) */
	C_KANJI_JIS_3072, /*  0x88f0 (U+828b) */
	C_KANJI_JIS_3073, /*  0x88f1 (U+9c2f) */
	C_KANJI_JIS_3074, /*  0x88f2 (U+5141) */
	C_KANJI_JIS_3075, /*  0x88f3 (U+5370) */
	C_KANJI_JIS_3076, /*  0x88f4 (U+54bd) */
	C_KANJI_JIS_3077, /*  0x88f5 (U+54e1) */
	C_KANJI_JIS_3078, /*  0x88f6 (U+56e0) */
	C_KANJI_JIS_3079, /*  0x88f7 (U+59fb) */
	C_KANJI_JIS_307A, /*  0x88f8 (U+5f15) */
	C_KANJI_JIS_307B, /*  0x88f9 (U+98f2) */
	C_KANJI_JIS_307C, /*  0x88fa (U+6deb) */
	C_KANJI_JIS_307D, /*  0x88fb (U+80e4) */
	C_KANJI_JIS_307E, /*  0x88fc (U+852d) */
	0, /*  0x88fd */
	0, /*  0x88fe */
	0, /*  0x88ff */

	C_KANJI_JIS_3121, /*  0x8940 (U+9662) */
	C_KANJI_JIS_3122, /*  0x8941 (U+9670) */
	C_KANJI_JIS_3123, /*  0x8942 (U+96a0) */
	C_KANJI_JIS_3124, /*  0x8943 (U+97fb) */
	C_KANJI_JIS_3125, /*  0x8944 (U+540b) */
	C_KANJI_JIS_3126, /*  0x8945 (U+53f3) */
	C_KANJI_JIS_3127, /*  0x8946 (U+5b87) */
	C_KANJI_JIS_3128, /*  0x8947 (U+70cf) */
	C_KANJI_JIS_3129, /*  0x8948 (U+7fbd) */
	C_KANJI_JIS_312A, /*  0x8949 (U+8fc2) */
	C_KANJI_JIS_312B, /*  0x894a (U+96e8) */
	C_KANJI_JIS_312C, /*  0x894b (U+536f) */
	C_KANJI_JIS_312D, /*  0x894c (U+9d5c) */
	C_KANJI_JIS_312E, /*  0x894d (U+7aba) */
	C_KANJI_JIS_312F, /*  0x894e (U+4e11) */
	C_KANJI_JIS_3130, /*  0x894f (U+7893) */
	C_KANJI_JIS_3131, /*  0x8950 (U+81fc) */
	C_KANJI_JIS_3132, /*  0x8951 (U+6e26) */
	C_KANJI_JIS_3133, /*  0x8952 (U+5618) */
	C_KANJI_JIS_3134, /*  0x8953 (U+5504) */
	C_KANJI_JIS_3135, /*  0x8954 (U+6b1d) */
	C_KANJI_JIS_3136, /*  0x8955 (U+851a) */
	C_KANJI_JIS_3137, /*  0x8956 (U+9c3b) */
	C_KANJI_JIS_3138, /*  0x8957 (U+59e5) */
	C_KANJI_JIS_3139, /*  0x8958 (U+53a9) */
	C_KANJI_JIS_313A, /*  0x8959 (U+6d66) */
	C_KANJI_JIS_313B, /*  0x895a (U+74dc) */
	C_KANJI_JIS_313C, /*  0x895b (U+958f) */
	C_KANJI_JIS_313D, /*  0x895c (U+5642) */
	C_KANJI_JIS_313E, /*  0x895d (U+4e91) */
	C_KANJI_JIS_313F, /*  0x895e (U+904b) */
	C_KANJI_JIS_3140, /*  0x895f (U+96f2) */
	C_KANJI_JIS_3141, /*  0x8960 (U+834f) */
	C_KANJI_JIS_3142, /*  0x8961 (U+990c) */
	C_KANJI_JIS_3143, /*  0x8962 (U+53e1) */
	C_KANJI_JIS_3144, /*  0x8963 (U+55b6) */
	C_KANJI_JIS_3145, /*  0x8964 (U+5b30) */
	C_KANJI_JIS_3146, /*  0x8965 (U+5f71) */
	C_KANJI_JIS_3147, /*  0x8966 (U+6620) */
	C_KANJI_JIS_3148, /*  0x8967 (U+66f3) */
	C_KANJI_JIS_3149, /*  0x8968 (U+6804) */
	C_KANJI_JIS_314A, /*  0x8969 (U+6c38) */
	C_KANJI_JIS_314B, /*  0x896a (U+6cf3) */
	C_KANJI_JIS_314C, /*  0x896b (U+6d29) */
	C_KANJI_JIS_314D, /*  0x896c (U+745b) */
	C_KANJI_JIS_314E, /*  0x896d (U+76c8) */
	C_KANJI_JIS_314F, /*  0x896e (U+7a4e) */
	C_KANJI_JIS_3150, /*  0x896f (U+9834) */
	C_KANJI_JIS_3151, /*  0x8970 (U+82f1) */
	C_KANJI_JIS_3152, /*  0x8971 (U+885b) */
	C_KANJI_JIS_3153, /*  0x8972 (U+8a60) */
	C_KANJI_JIS_3154, /*  0x8973 (U+92ed) */
	C_KANJI_JIS_3155, /*  0x8974 (U+6db2) */
	C_KANJI_JIS_3156, /*  0x8975 (U+75ab) */
	C_KANJI_JIS_3157, /*  0x8976 (U+76ca) */
	C_KANJI_JIS_3158, /*  0x8977 (U+99c5) */
	C_KANJI_JIS_3159, /*  0x8978 (U+60a6) */
	C_KANJI_JIS_315A, /*  0x8979 (U+8b01) */
	C_KANJI_JIS_315B, /*  0x897a (U+8d8a) */
	C_KANJI_JIS_315C, /*  0x897b (U+95b2) */
	C_KANJI_JIS_315D, /*  0x897c (U+698e) */
	C_KANJI_JIS_315E, /*  0x897d (U+53ad) */
	C_KANJI_JIS_315F, /*  0x897e (U+5186) */
	0, /*  0x897f */
	C_KANJI_JIS_3160, /*  0x8980 (U+5712) */
	C_KANJI_JIS_3161, /*  0x8981 (U+5830) */
	C_KANJI_JIS_3162, /*  0x8982 (U+5944) */
	C_KANJI_JIS_3163, /*  0x8983 (U+5bb4) */
	C_KANJI_JIS_3164, /*  0x8984 (U+5ef6) */
	C_KANJI_JIS_3165, /*  0x8985 (U+6028) */
	C_KANJI_JIS_3166, /*  0x8986 (U+63a9) */
	C_KANJI_JIS_3167, /*  0x8987 (U+63f4) */
	C_KANJI_JIS_3168, /*  0x8988 (U+6cbf) */
	C_KANJI_JIS_3169, /*  0x8989 (U+6f14) */
	C_KANJI_JIS_316A, /*  0x898a (U+708e) */
	C_KANJI_JIS_316B, /*  0x898b (U+7114) */
	C_KANJI_JIS_316C, /*  0x898c (U+7159) */
	C_KANJI_JIS_316D, /*  0x898d (U+71d5) */
	C_KANJI_JIS_316E, /*  0x898e (U+733f) */
	C_KANJI_JIS_316F, /*  0x898f (U+7e01) */
	C_KANJI_JIS_3170, /*  0x8990 (U+8276) */
	C_KANJI_JIS_3171, /*  0x8991 (U+82d1) */
	C_KANJI_JIS_3172, /*  0x8992 (U+8597) */
	C_KANJI_JIS_3173, /*  0x8993 (U+9060) */
	C_KANJI_JIS_3174, /*  0x8994 (U+925b) */
	C_KANJI_JIS_3175, /*  0x8995 (U+9d1b) */
	C_KANJI_JIS_3176, /*  0x8996 (U+5869) */
	C_KANJI_JIS_3177, /*  0x8997 (U+65bc) */
	C_KANJI_JIS_3178, /*  0x8998 (U+6c5a) */
	C_KANJI_JIS_3179, /*  0x8999 (U+7525) */
	C_KANJI_JIS_317A, /*  0x899a (U+51f9) */
	C_KANJI_JIS_317B, /*  0x899b (U+592e) */
	C_KANJI_JIS_317C, /*  0x899c (U+5965) */
	C_KANJI_JIS_317D, /*  0x899d (U+5f80) */
	C_KANJI_JIS_317E, /*  0x899e (U+5fdc) */
	C_KANJI_JIS_3221, /*  0x899f (U+62bc) */
	C_KANJI_JIS_3222, /*  0x89a0 (U+65fa) */
	C_KANJI_JIS_3223, /*  0x89a1 (U+6a2a) */
	C_KANJI_JIS_3224, /*  0x89a2 (U+6b27) */
	C_KANJI_JIS_3225, /*  0x89a3 (U+6bb4) */
	C_KANJI_JIS_3226, /*  0x89a4 (U+738b) */
	C_KANJI_JIS_3227, /*  0x89a5 (U+7fc1) */
	C_KANJI_JIS_3228, /*  0x89a6 (U+8956) */
	C_KANJI_JIS_3229, /*  0x89a7 (U+9d2c) */
	C_KANJI_JIS_322A, /*  0x89a8 (U+9d0e) */
	C_KANJI_JIS_322B, /*  0x89a9 (U+9ec4) */
	C_KANJI_JIS_322C, /*  0x89aa (U+5ca1) */
	C_KANJI_JIS_322D, /*  0x89ab (U+6c96) */
	C_KANJI_JIS_322E, /*  0x89ac (U+837b) */
	C_KANJI_JIS_322F, /*  0x89ad (U+5104) */
	C_KANJI_JIS_3230, /*  0x89ae (U+5c4b) */
	C_KANJI_JIS_3231, /*  0x89af (U+61b6) */
	C_KANJI_JIS_3232, /*  0x89b0 (U+81c6) */
	C_KANJI_JIS_3233, /*  0x89b1 (U+6876) */
	C_KANJI_JIS_3234, /*  0x89b2 (U+7261) */
	C_KANJI_JIS_3235, /*  0x89b3 (U+4e59) */
	C_KANJI_JIS_3236, /*  0x89b4 (U+4ffa) */
	C_KANJI_JIS_3237, /*  0x89b5 (U+5378) */
	C_KANJI_JIS_3238, /*  0x89b6 (U+6069) */
	C_KANJI_JIS_3239, /*  0x89b7 (U+6e29) */
	C_KANJI_JIS_323A, /*  0x89b8 (U+7a4f) */
	C_KANJI_JIS_323B, /*  0x89b9 (U+97f3) */
	C_KANJI_JIS_323C, /*  0x89ba (U+4e0b) */
	C_KANJI_JIS_323D, /*  0x89bb (U+5316) */
	C_KANJI_JIS_323E, /*  0x89bc (U+4eee) */
	C_KANJI_JIS_323F, /*  0x89bd (U+4f55) */
	C_KANJI_JIS_3240, /*  0x89be (U+4f3d) */
	C_KANJI_JIS_3241, /*  0x89bf (U+4fa1) */
	C_KANJI_JIS_3242, /*  0x89c0 (U+4f73) */
	C_KANJI_JIS_3243, /*  0x89c1 (U+52a0) */
	C_KANJI_JIS_3244, /*  0x89c2 (U+53ef) */
	C_KANJI_JIS_3245, /*  0x89c3 (U+5609) */
	C_KANJI_JIS_3246, /*  0x89c4 (U+590f) */
	C_KANJI_JIS_3247, /*  0x89c5 (U+5ac1) */
	C_KANJI_JIS_3248, /*  0x89c6 (U+5bb6) */
	C_KANJI_JIS_3249, /*  0x89c7 (U+5be1) */
	C_KANJI_JIS_324A, /*  0x89c8 (U+79d1) */
	C_KANJI_JIS_324B, /*  0x89c9 (U+6687) */
	C_KANJI_JIS_324C, /*  0x89ca (U+679c) */
	C_KANJI_JIS_324D, /*  0x89cb (U+67b6) */
	C_KANJI_JIS_324E, /*  0x89cc (U+6b4c) */
	C_KANJI_JIS_324F, /*  0x89cd (U+6cb3) */
	C_KANJI_JIS_3250, /*  0x89ce (U+706b) */
	C_KANJI_JIS_3251, /*  0x89cf (U+73c2) */
	C_KANJI_JIS_3252, /*  0x89d0 (U+798d) */
	C_KANJI_JIS_3253, /*  0x89d1 (U+79be) */
	C_KANJI_JIS_3254, /*  0x89d2 (U+7a3c) */
	C_KANJI_JIS_3255, /*  0x89d3 (U+7b87) */
	C_KANJI_JIS_3256, /*  0x89d4 (U+82b1) */
	C_KANJI_JIS_3257, /*  0x89d5 (U+82db) */
	C_KANJI_JIS_3258, /*  0x89d6 (U+8304) */
	C_KANJI_JIS_3259, /*  0x89d7 (U+8377) */
	C_KANJI_JIS_325A, /*  0x89d8 (U+83ef) */
	C_KANJI_JIS_325B, /*  0x89d9 (U+83d3) */
	C_KANJI_JIS_325C, /*  0x89da (U+8766) */
	C_KANJI_JIS_325D, /*  0x89db (U+8ab2) */
	C_KANJI_JIS_325E, /*  0x89dc (U+5629) */
	C_KANJI_JIS_325F, /*  0x89dd (U+8ca8) */
	C_KANJI_JIS_3260, /*  0x89de (U+8fe6) */
	C_KANJI_JIS_3261, /*  0x89df (U+904e) */
	C_KANJI_JIS_3262, /*  0x89e0 (U+971e) */
	C_KANJI_JIS_3263, /*  0x89e1 (U+868a) */
	C_KANJI_JIS_3264, /*  0x89e2 (U+4fc4) */
	C_KANJI_JIS_3265, /*  0x89e3 (U+5ce8) */
	C_KANJI_JIS_3266, /*  0x89e4 (U+6211) */
	C_KANJI_JIS_3267, /*  0x89e5 (U+7259) */
	C_KANJI_JIS_3268, /*  0x89e6 (U+753b) */
	C_KANJI_JIS_3269, /*  0x89e7 (U+81e5) */
	C_KANJI_JIS_326A, /*  0x89e8 (U+82bd) */
	C_KANJI_JIS_326B, /*  0x89e9 (U+86fe) */
	C_KANJI_JIS_326C, /*  0x89ea (U+8cc0) */
	C_KANJI_JIS_326D, /*  0x89eb (U+96c5) */
	C_KANJI_JIS_326E, /*  0x89ec (U+9913) */
	C_KANJI_JIS_326F, /*  0x89ed (U+99d5) */
	C_KANJI_JIS_3270, /*  0x89ee (U+4ecb) */
	C_KANJI_JIS_3271, /*  0x89ef (U+4f1a) */
	C_KANJI_JIS_3272, /*  0x89f0 (U+89e3) */
	C_KANJI_JIS_3273, /*  0x89f1 (U+56de) */
	C_KANJI_JIS_3274, /*  0x89f2 (U+584a) */
	C_KANJI_JIS_3275, /*  0x89f3 (U+58ca) */
	C_KANJI_JIS_3276, /*  0x89f4 (U+5efb) */
	C_KANJI_JIS_3277, /*  0x89f5 (U+5feb) */
	C_KANJI_JIS_3278, /*  0x89f6 (U+602a) */
	C_KANJI_JIS_3279, /*  0x89f7 (U+6094) */
	C_KANJI_JIS_327A, /*  0x89f8 (U+6062) */
	C_KANJI_JIS_327B, /*  0x89f9 (U+61d0) */
	C_KANJI_JIS_327C, /*  0x89fa (U+6212) */
	C_KANJI_JIS_327D, /*  0x89fb (U+62d0) */
	C_KANJI_JIS_327E, /*  0x89fc (U+6539) */
	0, /*  0x89fd */
	0, /*  0x89fe */
	0, /*  0x89ff */

	C_KANJI_JIS_3321, /*  0x8a40 (U+9b41) */
	C_KANJI_JIS_3322, /*  0x8a41 (U+6666) */
	C_KANJI_JIS_3323, /*  0x8a42 (U+68b0) */
	C_KANJI_JIS_3324, /*  0x8a43 (U+6d77) */
	C_KANJI_JIS_3325, /*  0x8a44 (U+7070) */
	C_KANJI_JIS_3326, /*  0x8a45 (U+754c) */
	C_KANJI_JIS_3327, /*  0x8a46 (U+7686) */
	C_KANJI_JIS_3328, /*  0x8a47 (U+7d75) */
	C_KANJI_JIS_3329, /*  0x8a48 (U+82a5) */
	C_KANJI_JIS_332A, /*  0x8a49 (U+87f9) */
	C_KANJI_JIS_332B, /*  0x8a4a (U+958b) */
	C_KANJI_JIS_332C, /*  0x8a4b (U+968e) */
	C_KANJI_JIS_332D, /*  0x8a4c (U+8c9d) */
	C_KANJI_JIS_332E, /*  0x8a4d (U+51f1) */
	C_KANJI_JIS_332F, /*  0x8a4e (U+52be) */
	C_KANJI_JIS_3330, /*  0x8a4f (U+5916) */
	C_KANJI_JIS_3331, /*  0x8a50 (U+54b3) */
	C_KANJI_JIS_3332, /*  0x8a51 (U+5bb3) */
	C_KANJI_JIS_3333, /*  0x8a52 (U+5d16) */
	C_KANJI_JIS_3334, /*  0x8a53 (U+6168) */
	C_KANJI_JIS_3335, /*  0x8a54 (U+6982) */
	C_KANJI_JIS_3336, /*  0x8a55 (U+6daf) */
	C_KANJI_JIS_3337, /*  0x8a56 (U+788d) */
	C_KANJI_JIS_3338, /*  0x8a57 (U+84cb) */
	C_KANJI_JIS_3339, /*  0x8a58 (U+8857) */
	C_KANJI_JIS_333A, /*  0x8a59 (U+8a72) */
	C_KANJI_JIS_333B, /*  0x8a5a (U+93a7) */
	C_KANJI_JIS_333C, /*  0x8a5b (U+9ab8) */
	C_KANJI_JIS_333D, /*  0x8a5c (U+6d6c) */
	C_KANJI_JIS_333E, /*  0x8a5d (U+99a8) */
	C_KANJI_JIS_333F, /*  0x8a5e (U+86d9) */
	C_KANJI_JIS_3340, /*  0x8a5f (U+57a3) */
	C_KANJI_JIS_3341, /*  0x8a60 (U+67ff) */
	C_KANJI_JIS_3342, /*  0x8a61 (U+86ce) */
	C_KANJI_JIS_3343, /*  0x8a62 (U+920e) */
	C_KANJI_JIS_3344, /*  0x8a63 (U+5283) */
	C_KANJI_JIS_3345, /*  0x8a64 (U+5687) */
	C_KANJI_JIS_3346, /*  0x8a65 (U+5404) */
	C_KANJI_JIS_3347, /*  0x8a66 (U+5ed3) */
	C_KANJI_JIS_3348, /*  0x8a67 (U+62e1) */
	C_KANJI_JIS_3349, /*  0x8a68 (U+64b9) */
	C_KANJI_JIS_334A, /*  0x8a69 (U+683c) */
	C_KANJI_JIS_334B, /*  0x8a6a (U+6838) */
	C_KANJI_JIS_334C, /*  0x8a6b (U+6bbb) */
	C_KANJI_JIS_334D, /*  0x8a6c (U+7372) */
	C_KANJI_JIS_334E, /*  0x8a6d (U+78ba) */
	C_KANJI_JIS_334F, /*  0x8a6e (U+7a6b) */
	C_KANJI_JIS_3350, /*  0x8a6f (U+899a) */
	C_KANJI_JIS_3351, /*  0x8a70 (U+89d2) */
	C_KANJI_JIS_3352, /*  0x8a71 (U+8d6b) */
	C_KANJI_JIS_3353, /*  0x8a72 (U+8f03) */
	C_KANJI_JIS_3354, /*  0x8a73 (U+90ed) */
	C_KANJI_JIS_3355, /*  0x8a74 (U+95a3) */
	C_KANJI_JIS_3356, /*  0x8a75 (U+9694) */
	C_KANJI_JIS_3357, /*  0x8a76 (U+9769) */
	C_KANJI_JIS_3358, /*  0x8a77 (U+5b66) */
	C_KANJI_JIS_3359, /*  0x8a78 (U+5cb3) */
	C_KANJI_JIS_335A, /*  0x8a79 (U+697d) */
	C_KANJI_JIS_335B, /*  0x8a7a (U+984d) */
	C_KANJI_JIS_335C, /*  0x8a7b (U+984e) */
	C_KANJI_JIS_335D, /*  0x8a7c (U+639b) */
	C_KANJI_JIS_335E, /*  0x8a7d (U+7b20) */
	C_KANJI_JIS_335F, /*  0x8a7e (U+6a2b) */
	0, /*  0x8a7f */
	C_KANJI_JIS_3360, /*  0x8a80 (U+6a7f) */
	C_KANJI_JIS_3361, /*  0x8a81 (U+68b6) */
	C_KANJI_JIS_3362, /*  0x8a82 (U+9c0d) */
	C_KANJI_JIS_3363, /*  0x8a83 (U+6f5f) */
	C_KANJI_JIS_3364, /*  0x8a84 (U+5272) */
	C_KANJI_JIS_3365, /*  0x8a85 (U+559d) */
	C_KANJI_JIS_3366, /*  0x8a86 (U+6070) */
	C_KANJI_JIS_3367, /*  0x8a87 (U+62ec) */
	C_KANJI_JIS_3368, /*  0x8a88 (U+6d3b) */
	C_KANJI_JIS_3369, /*  0x8a89 (U+6e07) */
	C_KANJI_JIS_336A, /*  0x8a8a (U+6ed1) */
	C_KANJI_JIS_336B, /*  0x8a8b (U+845b) */
	C_KANJI_JIS_336C, /*  0x8a8c (U+8910) */
	C_KANJI_JIS_336D, /*  0x8a8d (U+8f44) */
	C_KANJI_JIS_336E, /*  0x8a8e (U+4e14) */
	C_KANJI_JIS_336F, /*  0x8a8f (U+9c39) */
	C_KANJI_JIS_3370, /*  0x8a90 (U+53f6) */
	C_KANJI_JIS_3371, /*  0x8a91 (U+691b) */
	C_KANJI_JIS_3372, /*  0x8a92 (U+6a3a) */
	C_KANJI_JIS_3373, /*  0x8a93 (U+9784) */
	C_KANJI_JIS_3374, /*  0x8a94 (U+682a) */
	C_KANJI_JIS_3375, /*  0x8a95 (U+515c) */
	C_KANJI_JIS_3376, /*  0x8a96 (U+7ac3) */
	C_KANJI_JIS_3377, /*  0x8a97 (U+84b2) */
	C_KANJI_JIS_3378, /*  0x8a98 (U+91dc) */
	C_KANJI_JIS_3379, /*  0x8a99 (U+938c) */
	C_KANJI_JIS_337A, /*  0x8a9a (U+565b) */
	C_KANJI_JIS_337B, /*  0x8a9b (U+9d28) */
	C_KANJI_JIS_337C, /*  0x8a9c (U+6822) */
	C_KANJI_JIS_337D, /*  0x8a9d (U+8305) */
	C_KANJI_JIS_337E, /*  0x8a9e (U+8431) */
	C_KANJI_JIS_3421, /*  0x8a9f (U+7ca5) */
	C_KANJI_JIS_3422, /*  0x8aa0 (U+5208) */
	C_KANJI_JIS_3423, /*  0x8aa1 (U+82c5) */
	C_KANJI_JIS_3424, /*  0x8aa2 (U+74e6) */
	C_KANJI_JIS_3425, /*  0x8aa3 (U+4e7e) */
	C_KANJI_JIS_3426, /*  0x8aa4 (U+4f83) */
	C_KANJI_JIS_3427, /*  0x8aa5 (U+51a0) */
	C_KANJI_JIS_3428, /*  0x8aa6 (U+5bd2) */
	C_KANJI_JIS_3429, /*  0x8aa7 (U+520a) */
	C_KANJI_JIS_342A, /*  0x8aa8 (U+52d8) */
	C_KANJI_JIS_342B, /*  0x8aa9 (U+52e7) */
	C_KANJI_JIS_342C, /*  0x8aaa (U+5dfb) */
	C_KANJI_JIS_342D, /*  0x8aab (U+559a) */
	C_KANJI_JIS_342E, /*  0x8aac (U+582a) */
	C_KANJI_JIS_342F, /*  0x8aad (U+59e6) */
	C_KANJI_JIS_3430, /*  0x8aae (U+5b8c) */
	C_KANJI_JIS_3431, /*  0x8aaf (U+5b98) */
	C_KANJI_JIS_3432, /*  0x8ab0 (U+5bdb) */
	C_KANJI_JIS_3433, /*  0x8ab1 (U+5e72) */
	C_KANJI_JIS_3434, /*  0x8ab2 (U+5e79) */
	C_KANJI_JIS_3435, /*  0x8ab3 (U+60a3) */
	C_KANJI_JIS_3436, /*  0x8ab4 (U+611f) */
	C_KANJI_JIS_3437, /*  0x8ab5 (U+6163) */
	C_KANJI_JIS_3438, /*  0x8ab6 (U+61be) */
	C_KANJI_JIS_3439, /*  0x8ab7 (U+63db) */
	C_KANJI_JIS_343A, /*  0x8ab8 (U+6562) */
	C_KANJI_JIS_343B, /*  0x8ab9 (U+67d1) */
	C_KANJI_JIS_343C, /*  0x8aba (U+6853) */
	C_KANJI_JIS_343D, /*  0x8abb (U+68fa) */
	C_KANJI_JIS_343E, /*  0x8abc (U+6b3e) */
	C_KANJI_JIS_343F, /*  0x8abd (U+6b53) */
	C_KANJI_JIS_3440, /*  0x8abe (U+6c57) */
	C_KANJI_JIS_3441, /*  0x8abf (U+6f22) */
	C_KANJI_JIS_3442, /*  0x8ac0 (U+6f97) */
	C_KANJI_JIS_3443, /*  0x8ac1 (U+6f45) */
	C_KANJI_JIS_3444, /*  0x8ac2 (U+74b0) */
	C_KANJI_JIS_3445, /*  0x8ac3 (U+7518) */
	C_KANJI_JIS_3446, /*  0x8ac4 (U+76e3) */
	C_KANJI_JIS_3447, /*  0x8ac5 (U+770b) */
	C_KANJI_JIS_3448, /*  0x8ac6 (U+7aff) */
	C_KANJI_JIS_3449, /*  0x8ac7 (U+7ba1) */
	C_KANJI_JIS_344A, /*  0x8ac8 (U+7c21) */
	C_KANJI_JIS_344B, /*  0x8ac9 (U+7de9) */
	C_KANJI_JIS_344C, /*  0x8aca (U+7f36) */
	C_KANJI_JIS_344D, /*  0x8acb (U+7ff0) */
	C_KANJI_JIS_344E, /*  0x8acc (U+809d) */
	C_KANJI_JIS_344F, /*  0x8acd (U+8266) */
	C_KANJI_JIS_3450, /*  0x8ace (U+839e) */
	C_KANJI_JIS_3451, /*  0x8acf (U+89b3) */
	C_KANJI_JIS_3452, /*  0x8ad0 (U+8acc) */
	C_KANJI_JIS_3453, /*  0x8ad1 (U+8cab) */
	C_KANJI_JIS_3454, /*  0x8ad2 (U+9084) */
	C_KANJI_JIS_3455, /*  0x8ad3 (U+9451) */
	C_KANJI_JIS_3456, /*  0x8ad4 (U+9593) */
	C_KANJI_JIS_3457, /*  0x8ad5 (U+9591) */
	C_KANJI_JIS_3458, /*  0x8ad6 (U+95a2) */
	C_KANJI_JIS_3459, /*  0x8ad7 (U+9665) */
	C_KANJI_JIS_345A, /*  0x8ad8 (U+97d3) */
	C_KANJI_JIS_345B, /*  0x8ad9 (U+9928) */
	C_KANJI_JIS_345C, /*  0x8ada (U+8218) */
	C_KANJI_JIS_345D, /*  0x8adb (U+4e38) */
	C_KANJI_JIS_345E, /*  0x8adc (U+542b) */
	C_KANJI_JIS_345F, /*  0x8add (U+5cb8) */
	C_KANJI_JIS_3460, /*  0x8ade (U+5dcc) */
	C_KANJI_JIS_3461, /*  0x8adf (U+73a9) */
	C_KANJI_JIS_3462, /*  0x8ae0 (U+764c) */
	C_KANJI_JIS_3463, /*  0x8ae1 (U+773c) */
	C_KANJI_JIS_3464, /*  0x8ae2 (U+5ca9) */
	C_KANJI_JIS_3465, /*  0x8ae3 (U+7feb) */
	C_KANJI_JIS_3466, /*  0x8ae4 (U+8d0b) */
	C_KANJI_JIS_3467, /*  0x8ae5 (U+96c1) */
	C_KANJI_JIS_3468, /*  0x8ae6 (U+9811) */
	C_KANJI_JIS_3469, /*  0x8ae7 (U+9854) */
	C_KANJI_JIS_346A, /*  0x8ae8 (U+9858) */
	C_KANJI_JIS_346B, /*  0x8ae9 (U+4f01) */
	C_KANJI_JIS_346C, /*  0x8aea (U+4f0e) */
	C_KANJI_JIS_346D, /*  0x8aeb (U+5371) */
	C_KANJI_JIS_346E, /*  0x8aec (U+559c) */
	C_KANJI_JIS_346F, /*  0x8aed (U+5668) */
	C_KANJI_JIS_3470, /*  0x8aee (U+57fa) */
	C_KANJI_JIS_3471, /*  0x8aef (U+5947) */
	C_KANJI_JIS_3472, /*  0x8af0 (U+5b09) */
	C_KANJI_JIS_3473, /*  0x8af1 (U+5bc4) */
	C_KANJI_JIS_3474, /*  0x8af2 (U+5c90) */
	C_KANJI_JIS_3475, /*  0x8af3 (U+5e0c) */
	C_KANJI_JIS_3476, /*  0x8af4 (U+5e7e) */
	C_KANJI_JIS_3477, /*  0x8af5 (U+5fcc) */
	C_KANJI_JIS_3478, /*  0x8af6 (U+63ee) */
	C_KANJI_JIS_3479, /*  0x8af7 (U+673a) */
	C_KANJI_JIS_347A, /*  0x8af8 (U+65d7) */
	C_KANJI_JIS_347B, /*  0x8af9 (U+65e2) */
	C_KANJI_JIS_347C, /*  0x8afa (U+671f) */
	C_KANJI_JIS_347D, /*  0x8afb (U+68cb) */
	C_KANJI_JIS_347E, /*  0x8afc (U+68c4) */
	0, /*  0x8afd */
	0, /*  0x8afe */
	0, /*  0x8aff */

	C_KANJI_JIS_3521, /*  0x8b40 (U+6a5f) */
	C_KANJI_JIS_3522, /*  0x8b41 (U+5e30) */
	C_KANJI_JIS_3523, /*  0x8b42 (U+6bc5) */
	C_KANJI_JIS_3524, /*  0x8b43 (U+6c17) */
	C_KANJI_JIS_3525, /*  0x8b44 (U+6c7d) */
	C_KANJI_JIS_3526, /*  0x8b45 (U+757f) */
	C_KANJI_JIS_3527, /*  0x8b46 (U+7948) */
	C_KANJI_JIS_3528, /*  0x8b47 (U+5b63) */
	C_KANJI_JIS_3529, /*  0x8b48 (U+7a00) */
	C_KANJI_JIS_352A, /*  0x8b49 (U+7d00) */
	C_KANJI_JIS_352B, /*  0x8b4a (U+5fbd) */
	C_KANJI_JIS_352C, /*  0x8b4b (U+898f) */
	C_KANJI_JIS_352D, /*  0x8b4c (U+8a18) */
	C_KANJI_JIS_352E, /*  0x8b4d (U+8cb4) */
	C_KANJI_JIS_352F, /*  0x8b4e (U+8d77) */
	C_KANJI_JIS_3530, /*  0x8b4f (U+8ecc) */
	C_KANJI_JIS_3531, /*  0x8b50 (U+8f1d) */
	C_KANJI_JIS_3532, /*  0x8b51 (U+98e2) */
	C_KANJI_JIS_3533, /*  0x8b52 (U+9a0e) */
	C_KANJI_JIS_3534, /*  0x8b53 (U+9b3c) */
	C_KANJI_JIS_3535, /*  0x8b54 (U+4e80) */
	C_KANJI_JIS_3536, /*  0x8b55 (U+507d) */
	C_KANJI_JIS_3537, /*  0x8b56 (U+5100) */
	C_KANJI_JIS_3538, /*  0x8b57 (U+5993) */
	C_KANJI_JIS_3539, /*  0x8b58 (U+5b9c) */
	C_KANJI_JIS_353A, /*  0x8b59 (U+622f) */
	C_KANJI_JIS_353B, /*  0x8b5a (U+6280) */
	C_KANJI_JIS_353C, /*  0x8b5b (U+64ec) */
	C_KANJI_JIS_353D, /*  0x8b5c (U+6b3a) */
	C_KANJI_JIS_353E, /*  0x8b5d (U+72a0) */
	C_KANJI_JIS_353F, /*  0x8b5e (U+7591) */
	C_KANJI_JIS_3540, /*  0x8b5f (U+7947) */
	C_KANJI_JIS_3541, /*  0x8b60 (U+7fa9) */
	C_KANJI_JIS_3542, /*  0x8b61 (U+87fb) */
	C_KANJI_JIS_3543, /*  0x8b62 (U+8abc) */
	C_KANJI_JIS_3544, /*  0x8b63 (U+8b70) */
	C_KANJI_JIS_3545, /*  0x8b64 (U+63ac) */
	C_KANJI_JIS_3546, /*  0x8b65 (U+83ca) */
	C_KANJI_JIS_3547, /*  0x8b66 (U+97a0) */
	C_KANJI_JIS_3548, /*  0x8b67 (U+5409) */
	C_KANJI_JIS_3549, /*  0x8b68 (U+5403) */
	C_KANJI_JIS_354A, /*  0x8b69 (U+55ab) */
	C_KANJI_JIS_354B, /*  0x8b6a (U+6854) */
	C_KANJI_JIS_354C, /*  0x8b6b (U+6a58) */
	C_KANJI_JIS_354D, /*  0x8b6c (U+8a70) */
	C_KANJI_JIS_354E, /*  0x8b6d (U+7827) */
	C_KANJI_JIS_354F, /*  0x8b6e (U+6775) */
	C_KANJI_JIS_3550, /*  0x8b6f (U+9ecd) */
	C_KANJI_JIS_3551, /*  0x8b70 (U+5374) */
	C_KANJI_JIS_3552, /*  0x8b71 (U+5ba2) */
	C_KANJI_JIS_3553, /*  0x8b72 (U+811a) */
	C_KANJI_JIS_3554, /*  0x8b73 (U+8650) */
	C_KANJI_JIS_3555, /*  0x8b74 (U+9006) */
	C_KANJI_JIS_3556, /*  0x8b75 (U+4e18) */
	C_KANJI_JIS_3557, /*  0x8b76 (U+4e45) */
	C_KANJI_JIS_3558, /*  0x8b77 (U+4ec7) */
	C_KANJI_JIS_3559, /*  0x8b78 (U+4f11) */
	C_KANJI_JIS_355A, /*  0x8b79 (U+53ca) */
	C_KANJI_JIS_355B, /*  0x8b7a (U+5438) */
	C_KANJI_JIS_355C, /*  0x8b7b (U+5bae) */
	C_KANJI_JIS_355D, /*  0x8b7c (U+5f13) */
	C_KANJI_JIS_355E, /*  0x8b7d (U+6025) */
	C_KANJI_JIS_355F, /*  0x8b7e (U+6551) */
	0, /*  0x8b7f */
	C_KANJI_JIS_3560, /*  0x8b80 (U+673d) */
	C_KANJI_JIS_3561, /*  0x8b81 (U+6c42) */
	C_KANJI_JIS_3562, /*  0x8b82 (U+6c72) */
	C_KANJI_JIS_3563, /*  0x8b83 (U+6ce3) */
	C_KANJI_JIS_3564, /*  0x8b84 (U+7078) */
	C_KANJI_JIS_3565, /*  0x8b85 (U+7403) */
	C_KANJI_JIS_3566, /*  0x8b86 (U+7a76) */
	C_KANJI_JIS_3567, /*  0x8b87 (U+7aae) */
	C_KANJI_JIS_3568, /*  0x8b88 (U+7b08) */
	C_KANJI_JIS_3569, /*  0x8b89 (U+7d1a) */
	C_KANJI_JIS_356A, /*  0x8b8a (U+7cfe) */
	C_KANJI_JIS_356B, /*  0x8b8b (U+7d66) */
	C_KANJI_JIS_356C, /*  0x8b8c (U+65e7) */
	C_KANJI_JIS_356D, /*  0x8b8d (U+725b) */
	C_KANJI_JIS_356E, /*  0x8b8e (U+53bb) */
	C_KANJI_JIS_356F, /*  0x8b8f (U+5c45) */
	C_KANJI_JIS_3570, /*  0x8b90 (U+5de8) */
	C_KANJI_JIS_3571, /*  0x8b91 (U+62d2) */
	C_KANJI_JIS_3572, /*  0x8b92 (U+62e0) */
	C_KANJI_JIS_3573, /*  0x8b93 (U+6319) */
	C_KANJI_JIS_3574, /*  0x8b94 (U+6e20) */
	C_KANJI_JIS_3575, /*  0x8b95 (U+865a) */
	C_KANJI_JIS_3576, /*  0x8b96 (U+8a31) */
	C_KANJI_JIS_3577, /*  0x8b97 (U+8ddd) */
	C_KANJI_JIS_3578, /*  0x8b98 (U+92f8) */
	C_KANJI_JIS_3579, /*  0x8b99 (U+6f01) */
	C_KANJI_JIS_357A, /*  0x8b9a (U+79a6) */
	C_KANJI_JIS_357B, /*  0x8b9b (U+9b5a) */
	C_KANJI_JIS_357C, /*  0x8b9c (U+4ea8) */
	C_KANJI_JIS_357D, /*  0x8b9d (U+4eab) */
	C_KANJI_JIS_357E, /*  0x8b9e (U+4eac) */
	C_KANJI_JIS_3621, /*  0x8b9f (U+4f9b) */
	C_KANJI_JIS_3622, /*  0x8ba0 (U+4fa0) */
	C_KANJI_JIS_3623, /*  0x8ba1 (U+50d1) */
	C_KANJI_JIS_3624, /*  0x8ba2 (U+5147) */
	C_KANJI_JIS_3625, /*  0x8ba3 (U+7af6) */
	C_KANJI_JIS_3626, /*  0x8ba4 (U+5171) */
	C_KANJI_JIS_3627, /*  0x8ba5 (U+51f6) */
	C_KANJI_JIS_3628, /*  0x8ba6 (U+5354) */
	C_KANJI_JIS_3629, /*  0x8ba7 (U+5321) */
	C_KANJI_JIS_362A, /*  0x8ba8 (U+537f) */
	C_KANJI_JIS_362B, /*  0x8ba9 (U+53eb) */
	C_KANJI_JIS_362C, /*  0x8baa (U+55ac) */
	C_KANJI_JIS_362D, /*  0x8bab (U+5883) */
	C_KANJI_JIS_362E, /*  0x8bac (U+5ce1) */
	C_KANJI_JIS_362F, /*  0x8bad (U+5f37) */
	C_KANJI_JIS_3630, /*  0x8bae (U+5f4a) */
	C_KANJI_JIS_3631, /*  0x8baf (U+602f) */
	C_KANJI_JIS_3632, /*  0x8bb0 (U+6050) */
	C_KANJI_JIS_3633, /*  0x8bb1 (U+606d) */
	C_KANJI_JIS_3634, /*  0x8bb2 (U+631f) */
	C_KANJI_JIS_3635, /*  0x8bb3 (U+6559) */
	C_KANJI_JIS_3636, /*  0x8bb4 (U+6a4b) */
	C_KANJI_JIS_3637, /*  0x8bb5 (U+6cc1) */
	C_KANJI_JIS_3638, /*  0x8bb6 (U+72c2) */
	C_KANJI_JIS_3639, /*  0x8bb7 (U+72ed) */
	C_KANJI_JIS_363A, /*  0x8bb8 (U+77ef) */
	C_KANJI_JIS_363B, /*  0x8bb9 (U+80f8) */
	C_KANJI_JIS_363C, /*  0x8bba (U+8105) */
	C_KANJI_JIS_363D, /*  0x8bbb (U+8208) */
	C_KANJI_JIS_363E, /*  0x8bbc (U+854e) */
	C_KANJI_JIS_363F, /*  0x8bbd (U+90f7) */
	C_KANJI_JIS_3640, /*  0x8bbe (U+93e1) */
	C_KANJI_JIS_3641, /*  0x8bbf (U+97ff) */
	C_KANJI_JIS_3642, /*  0x8bc0 (U+9957) */
	C_KANJI_JIS_3643, /*  0x8bc1 (U+9a5a) */
	C_KANJI_JIS_3644, /*  0x8bc2 (U+4ef0) */
	C_KANJI_JIS_3645, /*  0x8bc3 (U+51dd) */
	C_KANJI_JIS_3646, /*  0x8bc4 (U+5c2d) */
	C_KANJI_JIS_3647, /*  0x8bc5 (U+6681) */
	C_KANJI_JIS_3648, /*  0x8bc6 (U+696d) */
	C_KANJI_JIS_3649, /*  0x8bc7 (U+5c40) */
	C_KANJI_JIS_364A, /*  0x8bc8 (U+66f2) */
	C_KANJI_JIS_364B, /*  0x8bc9 (U+6975) */
	C_KANJI_JIS_364C, /*  0x8bca (U+7389) */
	C_KANJI_JIS_364D, /*  0x8bcb (U+6850) */
	C_KANJI_JIS_364E, /*  0x8bcc (U+7c81) */
	C_KANJI_JIS_364F, /*  0x8bcd (U+50c5) */
	C_KANJI_JIS_3650, /*  0x8bce (U+52e4) */
	C_KANJI_JIS_3651, /*  0x8bcf (U+5747) */
	C_KANJI_JIS_3652, /*  0x8bd0 (U+5dfe) */
	C_KANJI_JIS_3653, /*  0x8bd1 (U+9326) */
	C_KANJI_JIS_3654, /*  0x8bd2 (U+65a4) */
	C_KANJI_JIS_3655, /*  0x8bd3 (U+6b23) */
	C_KANJI_JIS_3656, /*  0x8bd4 (U+6b3d) */
	C_KANJI_JIS_3657, /*  0x8bd5 (U+7434) */
	C_KANJI_JIS_3658, /*  0x8bd6 (U+7981) */
	C_KANJI_JIS_3659, /*  0x8bd7 (U+79bd) */
	C_KANJI_JIS_365A, /*  0x8bd8 (U+7b4b) */
	C_KANJI_JIS_365B, /*  0x8bd9 (U+7dca) */
	C_KANJI_JIS_365C, /*  0x8bda (U+82b9) */
	C_KANJI_JIS_365D, /*  0x8bdb (U+83cc) */
	C_KANJI_JIS_365E, /*  0x8bdc (U+887f) */
	C_KANJI_JIS_365F, /*  0x8bdd (U+895f) */
	C_KANJI_JIS_3660, /*  0x8bde (U+8b39) */
	C_KANJI_JIS_3661, /*  0x8bdf (U+8fd1) */
	C_KANJI_JIS_3662, /*  0x8be0 (U+91d1) */
	C_KANJI_JIS_3663, /*  0x8be1 (U+541f) */
	C_KANJI_JIS_3664, /*  0x8be2 (U+9280) */
	C_KANJI_JIS_3665, /*  0x8be3 (U+4e5d) */
	C_KANJI_JIS_3666, /*  0x8be4 (U+5036) */
	C_KANJI_JIS_3667, /*  0x8be5 (U+53e5) */
	C_KANJI_JIS_3668, /*  0x8be6 (U+533a) */
	C_KANJI_JIS_3669, /*  0x8be7 (U+72d7) */
	C_KANJI_JIS_366A, /*  0x8be8 (U+7396) */
	C_KANJI_JIS_366B, /*  0x8be9 (U+77e9) */
	C_KANJI_JIS_366C, /*  0x8bea (U+82e6) */
	C_KANJI_JIS_366D, /*  0x8beb (U+8eaf) */
	C_KANJI_JIS_366E, /*  0x8bec (U+99c6) */
	C_KANJI_JIS_366F, /*  0x8bed (U+99c8) */
	C_KANJI_JIS_3670, /*  0x8bee (U+99d2) */
	C_KANJI_JIS_3671, /*  0x8bef (U+5177) */
	C_KANJI_JIS_3672, /*  0x8bf0 (U+611a) */
	C_KANJI_JIS_3673, /*  0x8bf1 (U+865e) */
	C_KANJI_JIS_3674, /*  0x8bf2 (U+55b0) */
	C_KANJI_JIS_3675, /*  0x8bf3 (U+7a7a) */
	C_KANJI_JIS_3676, /*  0x8bf4 (U+5076) */
	C_KANJI_JIS_3677, /*  0x8bf5 (U+5bd3) */
	C_KANJI_JIS_3678, /*  0x8bf6 (U+9047) */
	C_KANJI_JIS_3679, /*  0x8bf7 (U+9685) */
	C_KANJI_JIS_367A, /*  0x8bf8 (U+4e32) */
	C_KANJI_JIS_367B, /*  0x8bf9 (U+6adb) */
	C_KANJI_JIS_367C, /*  0x8bfa (U+91e7) */
	C_KANJI_JIS_367D, /*  0x8bfb (U+5c51) */
	C_KANJI_JIS_367E, /*  0x8bfc (U+5c48) */
	0, /*  0x8bfd */
	0, /*  0x8bfe */
	0, /*  0x8bff */
	C_KANJI_JIS_3721, /*  0x8c40 (U+6398) */
	C_KANJI_JIS_3722, /*  0x8c41 (U+7a9f) */
	C_KANJI_JIS_3723, /*  0x8c42 (U+6c93) */
	C_KANJI_JIS_3724, /*  0x8c43 (U+9774) */
	C_KANJI_JIS_3725, /*  0x8c44 (U+8f61) */
	C_KANJI_JIS_3726, /*  0x8c45 (U+7aaa) */
	C_KANJI_JIS_3727, /*  0x8c46 (U+718a) */
	C_KANJI_JIS_3728, /*  0x8c47 (U+9688) */
	C_KANJI_JIS_3729, /*  0x8c48 (U+7c82) */
	C_KANJI_JIS_372A, /*  0x8c49 (U+6817) */
	C_KANJI_JIS_372B, /*  0x8c4a (U+7e70) */
	C_KANJI_JIS_372C, /*  0x8c4b (U+6851) */
	C_KANJI_JIS_372D, /*  0x8c4c (U+936c) */
	C_KANJI_JIS_372E, /*  0x8c4d (U+52f2) */
	C_KANJI_JIS_372F, /*  0x8c4e (U+541b) */
	C_KANJI_JIS_3730, /*  0x8c4f (U+85ab) */
	C_KANJI_JIS_3731, /*  0x8c50 (U+8a13) */
	C_KANJI_JIS_3732, /*  0x8c51 (U+7fa4) */
	C_KANJI_JIS_3733, /*  0x8c52 (U+8ecd) */
	C_KANJI_JIS_3734, /*  0x8c53 (U+90e1) */
	C_KANJI_JIS_3735, /*  0x8c54 (U+5366) */
	C_KANJI_JIS_3736, /*  0x8c55 (U+8888) */
	C_KANJI_JIS_3737, /*  0x8c56 (U+7941) */
	C_KANJI_JIS_3738, /*  0x8c57 (U+4fc2) */
	C_KANJI_JIS_3739, /*  0x8c58 (U+50be) */
	C_KANJI_JIS_373A, /*  0x8c59 (U+5211) */
	C_KANJI_JIS_373B, /*  0x8c5a (U+5144) */
	C_KANJI_JIS_373C, /*  0x8c5b (U+5553) */
	C_KANJI_JIS_373D, /*  0x8c5c (U+572d) */
	C_KANJI_JIS_373E, /*  0x8c5d (U+73ea) */
	C_KANJI_JIS_373F, /*  0x8c5e (U+578b) */
	C_KANJI_JIS_3740, /*  0x8c5f (U+5951) */
	C_KANJI_JIS_3741, /*  0x8c60 (U+5f62) */
	C_KANJI_JIS_3742, /*  0x8c61 (U+5f84) */
	C_KANJI_JIS_3743, /*  0x8c62 (U+6075) */
	C_KANJI_JIS_3744, /*  0x8c63 (U+6176) */
	C_KANJI_JIS_3745, /*  0x8c64 (U+6167) */
	C_KANJI_JIS_3746, /*  0x8c65 (U+61a9) */
	C_KANJI_JIS_3747, /*  0x8c66 (U+63b2) */
	C_KANJI_JIS_3748, /*  0x8c67 (U+643a) */
	C_KANJI_JIS_3749, /*  0x8c68 (U+656c) */
	C_KANJI_JIS_374A, /*  0x8c69 (U+666f) */
	C_KANJI_JIS_374B, /*  0x8c6a (U+6842) */
	C_KANJI_JIS_374C, /*  0x8c6b (U+6e13) */
	C_KANJI_JIS_374D, /*  0x8c6c (U+7566) */
	C_KANJI_JIS_374E, /*  0x8c6d (U+7a3d) */
	C_KANJI_JIS_374F, /*  0x8c6e (U+7cfb) */
	C_KANJI_JIS_3750, /*  0x8c6f (U+7d4c) */
	C_KANJI_JIS_3751, /*  0x8c70 (U+7d99) */
	C_KANJI_JIS_3752, /*  0x8c71 (U+7e4b) */
	C_KANJI_JIS_3753, /*  0x8c72 (U+7f6b) */
	C_KANJI_JIS_3754, /*  0x8c73 (U+830e) */
	C_KANJI_JIS_3755, /*  0x8c74 (U+834a) */
	C_KANJI_JIS_3756, /*  0x8c75 (U+86cd) */
	C_KANJI_JIS_3757, /*  0x8c76 (U+8a08) */
	C_KANJI_JIS_3758, /*  0x8c77 (U+8a63) */
	C_KANJI_JIS_3759, /*  0x8c78 (U+8b66) */
	C_KANJI_JIS_375A, /*  0x8c79 (U+8efd) */
	C_KANJI_JIS_375B, /*  0x8c7a (U+981a) */
	C_KANJI_JIS_375C, /*  0x8c7b (U+9d8f) */
	C_KANJI_JIS_375D, /*  0x8c7c (U+82b8) */
	C_KANJI_JIS_375E, /*  0x8c7d (U+8fce) */
	C_KANJI_JIS_375F, /*  0x8c7e (U+9be8) */
	0, /*  0x8c7f */
	C_KANJI_JIS_3760, /*  0x8c80 (U+5287) */
	C_KANJI_JIS_3761, /*  0x8c81 (U+621f) */
	C_KANJI_JIS_3762, /*  0x8c82 (U+6483) */
	C_KANJI_JIS_3763, /*  0x8c83 (U+6fc0) */
	C_KANJI_JIS_3764, /*  0x8c84 (U+9699) */
	C_KANJI_JIS_3765, /*  0x8c85 (U+6841) */
	C_KANJI_JIS_3766, /*  0x8c86 (U+5091) */
	C_KANJI_JIS_3767, /*  0x8c87 (U+6b20) */
	C_KANJI_JIS_3768, /*  0x8c88 (U+6c7a) */
	C_KANJI_JIS_3769, /*  0x8c89 (U+6f54) */
	C_KANJI_JIS_376A, /*  0x8c8a (U+7a74) */
	C_KANJI_JIS_376B, /*  0x8c8b (U+7d50) */
	C_KANJI_JIS_376C, /*  0x8c8c (U+8840) */
	C_KANJI_JIS_376D, /*  0x8c8d (U+8a23) */
	C_KANJI_JIS_376E, /*  0x8c8e (U+6708) */
	C_KANJI_JIS_376F, /*  0x8c8f (U+4ef6) */
	C_KANJI_JIS_3770, /*  0x8c90 (U+5039) */
	C_KANJI_JIS_3771, /*  0x8c91 (U+5026) */
	C_KANJI_JIS_3772, /*  0x8c92 (U+5065) */
	C_KANJI_JIS_3773, /*  0x8c93 (U+517c) */
	C_KANJI_JIS_3774, /*  0x8c94 (U+5238) */
	C_KANJI_JIS_3775, /*  0x8c95 (U+5263) */
	C_KANJI_JIS_3776, /*  0x8c96 (U+55a7) */
	C_KANJI_JIS_3777, /*  0x8c97 (U+570f) */
	C_KANJI_JIS_3778, /*  0x8c98 (U+5805) */
	C_KANJI_JIS_3779, /*  0x8c99 (U+5acc) */
	C_KANJI_JIS_377A, /*  0x8c9a (U+5efa) */
	C_KANJI_JIS_377B, /*  0x8c9b (U+61b2) */
	C_KANJI_JIS_377C, /*  0x8c9c (U+61f8) */
	C_KANJI_JIS_377D, /*  0x8c9d (U+62f3) */
	C_KANJI_JIS_377E, /*  0x8c9e (U+6372) */
	C_KANJI_JIS_3821, /*  0x8c9f (U+691c) */
	C_KANJI_JIS_3822, /*  0x8ca0 (U+6a29) */
	C_KANJI_JIS_3823, /*  0x8ca1 (U+727d) */
	C_KANJI_JIS_3824, /*  0x8ca2 (U+72ac) */
	C_KANJI_JIS_3825, /*  0x8ca3 (U+732e) */
	C_KANJI_JIS_3826, /*  0x8ca4 (U+7814) */
	C_KANJI_JIS_3827, /*  0x8ca5 (U+786f) */
	C_KANJI_JIS_3828, /*  0x8ca6 (U+7d79) */
	C_KANJI_JIS_3829, /*  0x8ca7 (U+770c) */
	C_KANJI_JIS_382A, /*  0x8ca8 (U+80a9) */
	C_KANJI_JIS_382B, /*  0x8ca9 (U+898b) */
	C_KANJI_JIS_382C, /*  0x8caa (U+8b19) */
	C_KANJI_JIS_382D, /*  0x8cab (U+8ce2) */
	C_KANJI_JIS_382E, /*  0x8cac (U+8ed2) */
	C_KANJI_JIS_382F, /*  0x8cad (U+9063) */
	C_KANJI_JIS_3830, /*  0x8cae (U+9375) */
	C_KANJI_JIS_3831, /*  0x8caf (U+967a) */
	C_KANJI_JIS_3832, /*  0x8cb0 (U+9855) */
	C_KANJI_JIS_3833, /*  0x8cb1 (U+9a13) */
	C_KANJI_JIS_3834, /*  0x8cb2 (U+9e78) */
	C_KANJI_JIS_3835, /*  0x8cb3 (U+5143) */
	C_KANJI_JIS_3836, /*  0x8cb4 (U+539f) */
	C_KANJI_JIS_3837, /*  0x8cb5 (U+53b3) */
	C_KANJI_JIS_3838, /*  0x8cb6 (U+5e7b) */
	C_KANJI_JIS_3839, /*  0x8cb7 (U+5f26) */
	C_KANJI_JIS_383A, /*  0x8cb8 (U+6e1b) */
	C_KANJI_JIS_383B, /*  0x8cb9 (U+6e90) */
	C_KANJI_JIS_383C, /*  0x8cba (U+7384) */
	C_KANJI_JIS_383D, /*  0x8cbb (U+73fe) */
	C_KANJI_JIS_383E, /*  0x8cbc (U+7d43) */
	C_KANJI_JIS_383F, /*  0x8cbd (U+8237) */
	C_KANJI_JIS_3840, /*  0x8cbe (U+8a00) */
	C_KANJI_JIS_3841, /*  0x8cbf (U+8afa) */
	C_KANJI_JIS_3842, /*  0x8cc0 (U+9650) */
	C_KANJI_JIS_3843, /*  0x8cc1 (U+4e4e) */
	C_KANJI_JIS_3844, /*  0x8cc2 (U+500b) */
	C_KANJI_JIS_3845, /*  0x8cc3 (U+53e4) */
	C_KANJI_JIS_3846, /*  0x8cc4 (U+547c) */
	C_KANJI_JIS_3847, /*  0x8cc5 (U+56fa) */
	C_KANJI_JIS_3848, /*  0x8cc6 (U+59d1) */
	C_KANJI_JIS_3849, /*  0x8cc7 (U+5b64) */
	C_KANJI_JIS_384A, /*  0x8cc8 (U+5df1) */
	C_KANJI_JIS_384B, /*  0x8cc9 (U+5eab) */
	C_KANJI_JIS_384C, /*  0x8cca (U+5f27) */
	C_KANJI_JIS_384D, /*  0x8ccb (U+6238) */
	C_KANJI_JIS_384E, /*  0x8ccc (U+6545) */
	C_KANJI_JIS_384F, /*  0x8ccd (U+67af) */
	C_KANJI_JIS_3850, /*  0x8cce (U+6e56) */
	C_KANJI_JIS_3851, /*  0x8ccf (U+72d0) */
	C_KANJI_JIS_3852, /*  0x8cd0 (U+7cca) */
	C_KANJI_JIS_3853, /*  0x8cd1 (U+88b4) */
	C_KANJI_JIS_3854, /*  0x8cd2 (U+80a1) */
	C_KANJI_JIS_3855, /*  0x8cd3 (U+80e1) */
	C_KANJI_JIS_3856, /*  0x8cd4 (U+83f0) */
	C_KANJI_JIS_3857, /*  0x8cd5 (U+864e) */
	C_KANJI_JIS_3858, /*  0x8cd6 (U+8a87) */
	C_KANJI_JIS_3859, /*  0x8cd7 (U+8de8) */
	C_KANJI_JIS_385A, /*  0x8cd8 (U+9237) */
	C_KANJI_JIS_385B, /*  0x8cd9 (U+96c7) */
	C_KANJI_JIS_385C, /*  0x8cda (U+9867) */
	C_KANJI_JIS_385D, /*  0x8cdb (U+9f13) */
	C_KANJI_JIS_385E, /*  0x8cdc (U+4e94) */
	C_KANJI_JIS_385F, /*  0x8cdd (U+4e92) */
	C_KANJI_JIS_3860, /*  0x8cde (U+4f0d) */
	C_KANJI_JIS_3861, /*  0x8cdf (U+5348) */
	C_KANJI_JIS_3862, /*  0x8ce0 (U+5449) */
	C_KANJI_JIS_3863, /*  0x8ce1 (U+543e) */
	C_KANJI_JIS_3864, /*  0x8ce2 (U+5a2f) */
	C_KANJI_JIS_3865, /*  0x8ce3 (U+5f8c) */
	C_KANJI_JIS_3866, /*  0x8ce4 (U+5fa1) */
	C_KANJI_JIS_3867, /*  0x8ce5 (U+609f) */
	C_KANJI_JIS_3868, /*  0x8ce6 (U+68a7) */
	C_KANJI_JIS_3869, /*  0x8ce7 (U+6a8e) */
	C_KANJI_JIS_386A, /*  0x8ce8 (U+745a) */
	C_KANJI_JIS_386B, /*  0x8ce9 (U+7881) */
	C_KANJI_JIS_386C, /*  0x8cea (U+8a9e) */
	C_KANJI_JIS_386D, /*  0x8ceb (U+8aa4) */
	C_KANJI_JIS_386E, /*  0x8cec (U+8b77) */
	C_KANJI_JIS_386F, /*  0x8ced (U+9190) */
	C_KANJI_JIS_3870, /*  0x8cee (U+4e5e) */
	C_KANJI_JIS_3871, /*  0x8cef (U+9bc9) */
	C_KANJI_JIS_3872, /*  0x8cf0 (U+4ea4) */
	C_KANJI_JIS_3873, /*  0x8cf1 (U+4f7c) */
	C_KANJI_JIS_3874, /*  0x8cf2 (U+4faf) */
	C_KANJI_JIS_3875, /*  0x8cf3 (U+5019) */
	C_KANJI_JIS_3876, /*  0x8cf4 (U+5016) */
	C_KANJI_JIS_3877, /*  0x8cf5 (U+5149) */
	C_KANJI_JIS_3878, /*  0x8cf6 (U+516c) */
	C_KANJI_JIS_3879, /*  0x8cf7 (U+529f) */
	C_KANJI_JIS_387A, /*  0x8cf8 (U+52b9) */
	C_KANJI_JIS_387B, /*  0x8cf9 (U+52fe) */
	C_KANJI_JIS_387C, /*  0x8cfa (U+539a) */
	C_KANJI_JIS_387D, /*  0x8cfb (U+53e3) */
	C_KANJI_JIS_387E, /*  0x8cfc (U+5411) */
	0, /*  0x8cfd */
	0, /*  0x8cfe */
	0, /*  0x8cff */
	C_KANJI_JIS_3921, /*  0x8d40 (U+540e) */
	C_KANJI_JIS_3922, /*  0x8d41 (U+5589) */
	C_KANJI_JIS_3923, /*  0x8d42 (U+5751) */
	C_KANJI_JIS_3924, /*  0x8d43 (U+57a2) */
	C_KANJI_JIS_3925, /*  0x8d44 (U+597d) */
	C_KANJI_JIS_3926, /*  0x8d45 (U+5b54) */
	C_KANJI_JIS_3927, /*  0x8d46 (U+5b5d) */
	C_KANJI_JIS_3928, /*  0x8d47 (U+5b8f) */
	C_KANJI_JIS_3929, /*  0x8d48 (U+5de5) */
	C_KANJI_JIS_392A, /*  0x8d49 (U+5de7) */
	C_KANJI_JIS_392B, /*  0x8d4a (U+5df7) */
	C_KANJI_JIS_392C, /*  0x8d4b (U+5e78) */
	C_KANJI_JIS_392D, /*  0x8d4c (U+5e83) */
	C_KANJI_JIS_392E, /*  0x8d4d (U+5e9a) */
	C_KANJI_JIS_392F, /*  0x8d4e (U+5eb7) */
	C_KANJI_JIS_3930, /*  0x8d4f (U+5f18) */
	C_KANJI_JIS_3931, /*  0x8d50 (U+6052) */
	C_KANJI_JIS_3932, /*  0x8d51 (U+614c) */
	C_KANJI_JIS_3933, /*  0x8d52 (U+6297) */
	C_KANJI_JIS_3934, /*  0x8d53 (U+62d8) */
	C_KANJI_JIS_3935, /*  0x8d54 (U+63a7) */
	C_KANJI_JIS_3936, /*  0x8d55 (U+653b) */
	C_KANJI_JIS_3937, /*  0x8d56 (U+6602) */
	C_KANJI_JIS_3938, /*  0x8d57 (U+6643) */
	C_KANJI_JIS_3939, /*  0x8d58 (U+66f4) */
	C_KANJI_JIS_393A, /*  0x8d59 (U+676d) */
	C_KANJI_JIS_393B, /*  0x8d5a (U+6821) */
	C_KANJI_JIS_393C, /*  0x8d5b (U+6897) */
	C_KANJI_JIS_393D, /*  0x8d5c (U+69cb) */
	C_KANJI_JIS_393E, /*  0x8d5d (U+6c5f) */
	C_KANJI_JIS_393F, /*  0x8d5e (U+6d2a) */
	C_KANJI_JIS_3940, /*  0x8d5f (U+6d69) */
	C_KANJI_JIS_3941, /*  0x8d60 (U+6e2f) */
	C_KANJI_JIS_3942, /*  0x8d61 (U+6e9d) */
	C_KANJI_JIS_3943, /*  0x8d62 (U+7532) */
	C_KANJI_JIS_3944, /*  0x8d63 (U+7687) */
	C_KANJI_JIS_3945, /*  0x8d64 (U+786c) */
	C_KANJI_JIS_3946, /*  0x8d65 (U+7a3f) */
	C_KANJI_JIS_3947, /*  0x8d66 (U+7ce0) */
	C_KANJI_JIS_3948, /*  0x8d67 (U+7d05) */
	C_KANJI_JIS_3949, /*  0x8d68 (U+7d18) */
	C_KANJI_JIS_394A, /*  0x8d69 (U+7d5e) */
	C_KANJI_JIS_394B, /*  0x8d6a (U+7db1) */
	C_KANJI_JIS_394C, /*  0x8d6b (U+8015) */
	C_KANJI_JIS_394D, /*  0x8d6c (U+8003) */
	C_KANJI_JIS_394E, /*  0x8d6d (U+80af) */
	C_KANJI_JIS_394F, /*  0x8d6e (U+80b1) */
	C_KANJI_JIS_3950, /*  0x8d6f (U+8154) */
	C_KANJI_JIS_3951, /*  0x8d70 (U+818f) */
	C_KANJI_JIS_3952, /*  0x8d71 (U+822a) */
	C_KANJI_JIS_3953, /*  0x8d72 (U+8352) */
	C_KANJI_JIS_3954, /*  0x8d73 (U+884c) */
	C_KANJI_JIS_3955, /*  0x8d74 (U+8861) */
	C_KANJI_JIS_3956, /*  0x8d75 (U+8b1b) */
	C_KANJI_JIS_3957, /*  0x8d76 (U+8ca2) */
	C_KANJI_JIS_3958, /*  0x8d77 (U+8cfc) */
	C_KANJI_JIS_3959, /*  0x8d78 (U+90ca) */
	C_KANJI_JIS_395A, /*  0x8d79 (U+9175) */
	C_KANJI_JIS_395B, /*  0x8d7a (U+9271) */
	C_KANJI_JIS_395C, /*  0x8d7b (U+783f) */
	C_KANJI_JIS_395D, /*  0x8d7c (U+92fc) */
	C_KANJI_JIS_395E, /*  0x8d7d (U+95a4) */
	C_KANJI_JIS_395F, /*  0x8d7e (U+964d) */
	0, /*  0x8d7f */
	C_KANJI_JIS_3960, /*  0x8d80 (U+9805) */
	C_KANJI_JIS_3961, /*  0x8d81 (U+9999) */
	C_KANJI_JIS_3962, /*  0x8d82 (U+9ad8) */
	C_KANJI_JIS_3963, /*  0x8d83 (U+9d3b) */
	C_KANJI_JIS_3964, /*  0x8d84 (U+525b) */
	C_KANJI_JIS_3965, /*  0x8d85 (U+52ab) */
	C_KANJI_JIS_3966, /*  0x8d86 (U+53f7) */
	C_KANJI_JIS_3967, /*  0x8d87 (U+5408) */
	C_KANJI_JIS_3968, /*  0x8d88 (U+58d5) */
	C_KANJI_JIS_3969, /*  0x8d89 (U+62f7) */
	C_KANJI_JIS_396A, /*  0x8d8a (U+6fe0) */
	C_KANJI_JIS_396B, /*  0x8d8b (U+8c6a) */
	C_KANJI_JIS_396C, /*  0x8d8c (U+8f5f) */
	C_KANJI_JIS_396D, /*  0x8d8d (U+9eb9) */
	C_KANJI_JIS_396E, /*  0x8d8e (U+514b) */
	C_KANJI_JIS_396F, /*  0x8d8f (U+523b) */
	C_KANJI_JIS_3970, /*  0x8d90 (U+544a) */
	C_KANJI_JIS_3971, /*  0x8d91 (U+56fd) */
	C_KANJI_JIS_3972, /*  0x8d92 (U+7a40) */
	C_KANJI_JIS_3973, /*  0x8d93 (U+9177) */
	C_KANJI_JIS_3974, /*  0x8d94 (U+9d60) */
	C_KANJI_JIS_3975, /*  0x8d95 (U+9ed2) */
	C_KANJI_JIS_3976, /*  0x8d96 (U+7344) */
	C_KANJI_JIS_3977, /*  0x8d97 (U+6f09) */
	C_KANJI_JIS_3978, /*  0x8d98 (U+8170) */
	C_KANJI_JIS_3979, /*  0x8d99 (U+7511) */
	C_KANJI_JIS_397A, /*  0x8d9a (U+5ffd) */
	C_KANJI_JIS_397B, /*  0x8d9b (U+60da) */
	C_KANJI_JIS_397C, /*  0x8d9c (U+9aa8) */
	C_KANJI_JIS_397D, /*  0x8d9d (U+72db) */
	C_KANJI_JIS_397E, /*  0x8d9e (U+8fbc) */
	C_KANJI_JIS_3A21, /*  0x8d9f (U+6b64) */
	C_KANJI_JIS_3A22, /*  0x8da0 (U+9803) */
	C_KANJI_JIS_3A23, /*  0x8da1 (U+4eca) */
	C_KANJI_JIS_3A24, /*  0x8da2 (U+56f0) */
	C_KANJI_JIS_3A25, /*  0x8da3 (U+5764) */
	C_KANJI_JIS_3A26, /*  0x8da4 (U+58be) */
	C_KANJI_JIS_3A27, /*  0x8da5 (U+5a5a) */
	C_KANJI_JIS_3A28, /*  0x8da6 (U+6068) */
	C_KANJI_JIS_3A29, /*  0x8da7 (U+61c7) */
	C_KANJI_JIS_3A2A, /*  0x8da8 (U+660f) */
	C_KANJI_JIS_3A2B, /*  0x8da9 (U+6606) */
	C_KANJI_JIS_3A2C, /*  0x8daa (U+6839) */
	C_KANJI_JIS_3A2D, /*  0x8dab (U+68b1) */
	C_KANJI_JIS_3A2E, /*  0x8dac (U+6df7) */
	C_KANJI_JIS_3A2F, /*  0x8dad (U+75d5) */
	C_KANJI_JIS_3A30, /*  0x8dae (U+7d3a) */
	C_KANJI_JIS_3A31, /*  0x8daf (U+826e) */
	C_KANJI_JIS_3A32, /*  0x8db0 (U+9b42) */
	C_KANJI_JIS_3A33, /*  0x8db1 (U+4e9b) */
	C_KANJI_JIS_3A34, /*  0x8db2 (U+4f50) */
	C_KANJI_JIS_3A35, /*  0x8db3 (U+53c9) */
	C_KANJI_JIS_3A36, /*  0x8db4 (U+5506) */
	C_KANJI_JIS_3A37, /*  0x8db5 (U+5d6f) */
	C_KANJI_JIS_3A38, /*  0x8db6 (U+5de6) */
	C_KANJI_JIS_3A39, /*  0x8db7 (U+5dee) */
	C_KANJI_JIS_3A3A, /*  0x8db8 (U+67fb) */
	C_KANJI_JIS_3A3B, /*  0x8db9 (U+6c99) */
	C_KANJI_JIS_3A3C, /*  0x8dba (U+7473) */
	C_KANJI_JIS_3A3D, /*  0x8dbb (U+7802) */
	C_KANJI_JIS_3A3E, /*  0x8dbc (U+8a50) */
	C_KANJI_JIS_3A3F, /*  0x8dbd (U+9396) */
	C_KANJI_JIS_3A40, /*  0x8dbe (U+88df) */
	C_KANJI_JIS_3A41, /*  0x8dbf (U+5750) */
	C_KANJI_JIS_3A42, /*  0x8dc0 (U+5ea7) */
	C_KANJI_JIS_3A43, /*  0x8dc1 (U+632b) */
	C_KANJI_JIS_3A44, /*  0x8dc2 (U+50b5) */
	C_KANJI_JIS_3A45, /*  0x8dc3 (U+50ac) */
	C_KANJI_JIS_3A46, /*  0x8dc4 (U+518d) */
	C_KANJI_JIS_3A47, /*  0x8dc5 (U+6700) */
	C_KANJI_JIS_3A48, /*  0x8dc6 (U+54c9) */
	C_KANJI_JIS_3A49, /*  0x8dc7 (U+585e) */
	C_KANJI_JIS_3A4A, /*  0x8dc8 (U+59bb) */
	C_KANJI_JIS_3A4B, /*  0x8dc9 (U+5bb0) */
	C_KANJI_JIS_3A4C, /*  0x8dca (U+5f69) */
	C_KANJI_JIS_3A4D, /*  0x8dcb (U+624d) */
	C_KANJI_JIS_3A4E, /*  0x8dcc (U+63a1) */
	C_KANJI_JIS_3A4F, /*  0x8dcd (U+683d) */
	C_KANJI_JIS_3A50, /*  0x8dce (U+6b73) */
	C_KANJI_JIS_3A51, /*  0x8dcf (U+6e08) */
	C_KANJI_JIS_3A52, /*  0x8dd0 (U+707d) */
	C_KANJI_JIS_3A53, /*  0x8dd1 (U+91c7) */
	C_KANJI_JIS_3A54, /*  0x8dd2 (U+7280) */
	C_KANJI_JIS_3A55, /*  0x8dd3 (U+7815) */
	C_KANJI_JIS_3A56, /*  0x8dd4 (U+7826) */
	C_KANJI_JIS_3A57, /*  0x8dd5 (U+796d) */
	C_KANJI_JIS_3A58, /*  0x8dd6 (U+658e) */
	C_KANJI_JIS_3A59, /*  0x8dd7 (U+7d30) */
	C_KANJI_JIS_3A5A, /*  0x8dd8 (U+83dc) */
	C_KANJI_JIS_3A5B, /*  0x8dd9 (U+88c1) */
	C_KANJI_JIS_3A5C, /*  0x8dda (U+8f09) */
	C_KANJI_JIS_3A5D, /*  0x8ddb (U+969b) */
	C_KANJI_JIS_3A5E, /*  0x8ddc (U+5264) */
	C_KANJI_JIS_3A5F, /*  0x8ddd (U+5728) */
	C_KANJI_JIS_3A60, /*  0x8dde (U+6750) */
	C_KANJI_JIS_3A61, /*  0x8ddf (U+7f6a) */
	C_KANJI_JIS_3A62, /*  0x8de0 (U+8ca1) */
	C_KANJI_JIS_3A63, /*  0x8de1 (U+51b4) */
	C_KANJI_JIS_3A64, /*  0x8de2 (U+5742) */
	C_KANJI_JIS_3A65, /*  0x8de3 (U+962a) */
	C_KANJI_JIS_3A66, /*  0x8de4 (U+583a) */
	C_KANJI_JIS_3A67, /*  0x8de5 (U+698a) */
	C_KANJI_JIS_3A68, /*  0x8de6 (U+80b4) */
	C_KANJI_JIS_3A69, /*  0x8de7 (U+54b2) */
	C_KANJI_JIS_3A6A, /*  0x8de8 (U+5d0e) */
	C_KANJI_JIS_3A6B, /*  0x8de9 (U+57fc) */
	C_KANJI_JIS_3A6C, /*  0x8dea (U+7895) */
	C_KANJI_JIS_3A6D, /*  0x8deb (U+9dfa) */
	C_KANJI_JIS_3A6E, /*  0x8dec (U+4f5c) */
	C_KANJI_JIS_3A6F, /*  0x8ded (U+524a) */
	C_KANJI_JIS_3A70, /*  0x8dee (U+548b) */
	C_KANJI_JIS_3A71, /*  0x8def (U+643e) */
	C_KANJI_JIS_3A72, /*  0x8df0 (U+6628) */
	C_KANJI_JIS_3A73, /*  0x8df1 (U+6714) */
	C_KANJI_JIS_3A74, /*  0x8df2 (U+67f5) */
	C_KANJI_JIS_3A75, /*  0x8df3 (U+7a84) */
	C_KANJI_JIS_3A76, /*  0x8df4 (U+7b56) */
	C_KANJI_JIS_3A77, /*  0x8df5 (U+7d22) */
	C_KANJI_JIS_3A78, /*  0x8df6 (U+932f) */
	C_KANJI_JIS_3A79, /*  0x8df7 (U+685c) */
	C_KANJI_JIS_3A7A, /*  0x8df8 (U+9bad) */
	C_KANJI_JIS_3A7B, /*  0x8df9 (U+7b39) */
	C_KANJI_JIS_3A7C, /*  0x8dfa (U+5319) */
	C_KANJI_JIS_3A7D, /*  0x8dfb (U+518a) */
	C_KANJI_JIS_3A7E, /*  0x8dfc (U+5237) */
	0, /*  0x8dfd */
	0, /*  0x8dfe */
	0, /*  0x8dff */
	C_KANJI_JIS_3B21, /*  0x8e40 (U+5bdf) */
	C_KANJI_JIS_3B22, /*  0x8e41 (U+62f6) */
	C_KANJI_JIS_3B23, /*  0x8e42 (U+64ae) */
	C_KANJI_JIS_3B24, /*  0x8e43 (U+64e6) */
	C_KANJI_JIS_3B25, /*  0x8e44 (U+672d) */
	C_KANJI_JIS_3B26, /*  0x8e45 (U+6bba) */
	C_KANJI_JIS_3B27, /*  0x8e46 (U+85a9) */
	C_KANJI_JIS_3B28, /*  0x8e47 (U+96d1) */
	C_KANJI_JIS_3B29, /*  0x8e48 (U+7690) */
	C_KANJI_JIS_3B2A, /*  0x8e49 (U+9bd6) */
	C_KANJI_JIS_3B2B, /*  0x8e4a (U+634c) */
	C_KANJI_JIS_3B2C, /*  0x8e4b (U+9306) */
	C_KANJI_JIS_3B2D, /*  0x8e4c (U+9bab) */
	C_KANJI_JIS_3B2E, /*  0x8e4d (U+76bf) */
	C_KANJI_JIS_3B2F, /*  0x8e4e (U+6652) */
	C_KANJI_JIS_3B30, /*  0x8e4f (U+4e09) */
	C_KANJI_JIS_3B31, /*  0x8e50 (U+5098) */
	C_KANJI_JIS_3B32, /*  0x8e51 (U+53c2) */
	C_KANJI_JIS_3B33, /*  0x8e52 (U+5c71) */
	C_KANJI_JIS_3B34, /*  0x8e53 (U+60e8) */
	C_KANJI_JIS_3B35, /*  0x8e54 (U+6492) */
	C_KANJI_JIS_3B36, /*  0x8e55 (U+6563) */
	C_KANJI_JIS_3B37, /*  0x8e56 (U+685f) */
	C_KANJI_JIS_3B38, /*  0x8e57 (U+71e6) */
	C_KANJI_JIS_3B39, /*  0x8e58 (U+73ca) */
	C_KANJI_JIS_3B3A, /*  0x8e59 (U+7523) */
	C_KANJI_JIS_3B3B, /*  0x8e5a (U+7b97) */
	C_KANJI_JIS_3B3C, /*  0x8e5b (U+7e82) */
	C_KANJI_JIS_3B3D, /*  0x8e5c (U+8695) */
	C_KANJI_JIS_3B3E, /*  0x8e5d (U+8b83) */
	C_KANJI_JIS_3B3F, /*  0x8e5e (U+8cdb) */
	C_KANJI_JIS_3B40, /*  0x8e5f (U+9178) */
	C_KANJI_JIS_3B41, /*  0x8e60 (U+9910) */
	C_KANJI_JIS_3B42, /*  0x8e61 (U+65ac) */
	C_KANJI_JIS_3B43, /*  0x8e62 (U+66ab) */
	C_KANJI_JIS_3B44, /*  0x8e63 (U+6b8b) */
	C_KANJI_JIS_3B45, /*  0x8e64 (U+4ed5) */
	C_KANJI_JIS_3B46, /*  0x8e65 (U+4ed4) */
	C_KANJI_JIS_3B47, /*  0x8e66 (U+4f3a) */
	C_KANJI_JIS_3B48, /*  0x8e67 (U+4f7f) */
	C_KANJI_JIS_3B49, /*  0x8e68 (U+523a) */
	C_KANJI_JIS_3B4A, /*  0x8e69 (U+53f8) */
	C_KANJI_JIS_3B4B, /*  0x8e6a (U+53f2) */
	C_KANJI_JIS_3B4C, /*  0x8e6b (U+55e3) */
	C_KANJI_JIS_3B4D, /*  0x8e6c (U+56db) */
	C_KANJI_JIS_3B4E, /*  0x8e6d (U+58eb) */
	C_KANJI_JIS_3B4F, /*  0x8e6e (U+59cb) */
	C_KANJI_JIS_3B50, /*  0x8e6f (U+59c9) */
	C_KANJI_JIS_3B51, /*  0x8e70 (U+59ff) */
	C_KANJI_JIS_3B52, /*  0x8e71 (U+5b50) */
	C_KANJI_JIS_3B53, /*  0x8e72 (U+5c4d) */
	C_KANJI_JIS_3B54, /*  0x8e73 (U+5e02) */
	C_KANJI_JIS_3B55, /*  0x8e74 (U+5e2b) */
	C_KANJI_JIS_3B56, /*  0x8e75 (U+5fd7) */
	C_KANJI_JIS_3B57, /*  0x8e76 (U+601d) */
	C_KANJI_JIS_3B58, /*  0x8e77 (U+6307) */
	C_KANJI_JIS_3B59, /*  0x8e78 (U+652f) */
	C_KANJI_JIS_3B5A, /*  0x8e79 (U+5b5c) */
	C_KANJI_JIS_3B5B, /*  0x8e7a (U+65af) */
	C_KANJI_JIS_3B5C, /*  0x8e7b (U+65bd) */
	C_KANJI_JIS_3B5D, /*  0x8e7c (U+65e8) */
	C_KANJI_JIS_3B5E, /*  0x8e7d (U+679d) */
	C_KANJI_JIS_3B5F, /*  0x8e7e (U+6b62) */
	0, /*  0x8e7f */
	C_KANJI_JIS_3B60, /*  0x8e80 (U+6b7b) */
	C_KANJI_JIS_3B61, /*  0x8e81 (U+6c0f) */
	C_KANJI_JIS_3B62, /*  0x8e82 (U+7345) */
	C_KANJI_JIS_3B63, /*  0x8e83 (U+7949) */
	C_KANJI_JIS_3B64, /*  0x8e84 (U+79c1) */
	C_KANJI_JIS_3B65, /*  0x8e85 (U+7cf8) */
	C_KANJI_JIS_3B66, /*  0x8e86 (U+7d19) */
	C_KANJI_JIS_3B67, /*  0x8e87 (U+7d2b) */
	C_KANJI_JIS_3B68, /*  0x8e88 (U+80a2) */
	C_KANJI_JIS_3B69, /*  0x8e89 (U+8102) */
	C_KANJI_JIS_3B6A, /*  0x8e8a (U+81f3) */
	C_KANJI_JIS_3B6B, /*  0x8e8b (U+8996) */
	C_KANJI_JIS_3B6C, /*  0x8e8c (U+8a5e) */
	C_KANJI_JIS_3B6D, /*  0x8e8d (U+8a69) */
	C_KANJI_JIS_3B6E, /*  0x8e8e (U+8a66) */
	C_KANJI_JIS_3B6F, /*  0x8e8f (U+8a8c) */
	C_KANJI_JIS_3B70, /*  0x8e90 (U+8aee) */
	C_KANJI_JIS_3B71, /*  0x8e91 (U+8cc7) */
	C_KANJI_JIS_3B72, /*  0x8e92 (U+8cdc) */
	C_KANJI_JIS_3B73, /*  0x8e93 (U+96cc) */
	C_KANJI_JIS_3B74, /*  0x8e94 (U+98fc) */
	C_KANJI_JIS_3B75, /*  0x8e95 (U+6b6f) */
	C_KANJI_JIS_3B76, /*  0x8e96 (U+4e8b) */
	C_KANJI_JIS_3B77, /*  0x8e97 (U+4f3c) */
	C_KANJI_JIS_3B78, /*  0x8e98 (U+4f8d) */
	C_KANJI_JIS_3B79, /*  0x8e99 (U+5150) */
	C_KANJI_JIS_3B7A, /*  0x8e9a (U+5b57) */
	C_KANJI_JIS_3B7B, /*  0x8e9b (U+5bfa) */
	C_KANJI_JIS_3B7C, /*  0x8e9c (U+6148) */
	C_KANJI_JIS_3B7D, /*  0x8e9d (U+6301) */
	C_KANJI_JIS_3B7E, /*  0x8e9e (U+6642) */
	C_KANJI_JIS_3C21, /*  0x8e9f (U+6b21) */
	C_KANJI_JIS_3C22, /*  0x8ea0 (U+6ecb) */
	C_KANJI_JIS_3C23, /*  0x8ea1 (U+6cbb) */
	C_KANJI_JIS_3C24, /*  0x8ea2 (U+723e) */
	C_KANJI_JIS_3C25, /*  0x8ea3 (U+74bd) */
	C_KANJI_JIS_3C26, /*  0x8ea4 (U+75d4) */
	C_KANJI_JIS_3C27, /*  0x8ea5 (U+78c1) */
	C_KANJI_JIS_3C28, /*  0x8ea6 (U+793a) */
	C_KANJI_JIS_3C29, /*  0x8ea7 (U+800c) */
	C_KANJI_JIS_3C2A, /*  0x8ea8 (U+8033) */
	C_KANJI_JIS_3C2B, /*  0x8ea9 (U+81ea) */
	C_KANJI_JIS_3C2C, /*  0x8eaa (U+8494) */
	C_KANJI_JIS_3C2D, /*  0x8eab (U+8f9e) */
	C_KANJI_JIS_3C2E, /*  0x8eac (U+6c50) */
	C_KANJI_JIS_3C2F, /*  0x8ead (U+9e7f) */
	C_KANJI_JIS_3C30, /*  0x8eae (U+5f0f) */
	C_KANJI_JIS_3C31, /*  0x8eaf (U+8b58) */
	C_KANJI_JIS_3C32, /*  0x8eb0 (U+9d2b) */
	C_KANJI_JIS_3C33, /*  0x8eb1 (U+7afa) */
	C_KANJI_JIS_3C34, /*  0x8eb2 (U+8ef8) */
	C_KANJI_JIS_3C35, /*  0x8eb3 (U+5b8d) */
	C_KANJI_JIS_3C36, /*  0x8eb4 (U+96eb) */
	C_KANJI_JIS_3C37, /*  0x8eb5 (U+4e03) */
	C_KANJI_JIS_3C38, /*  0x8eb6 (U+53f1) */
	C_KANJI_JIS_3C39, /*  0x8eb7 (U+57f7) */
	C_KANJI_JIS_3C3A, /*  0x8eb8 (U+5931) */
	C_KANJI_JIS_3C3B, /*  0x8eb9 (U+5ac9) */
	C_KANJI_JIS_3C3C, /*  0x8eba (U+5ba4) */
	C_KANJI_JIS_3C3D, /*  0x8ebb (U+6089) */
	C_KANJI_JIS_3C3E, /*  0x8ebc (U+6e7f) */
	C_KANJI_JIS_3C3F, /*  0x8ebd (U+6f06) */
	C_KANJI_JIS_3C40, /*  0x8ebe (U+75be) */
	C_KANJI_JIS_3C41, /*  0x8ebf (U+8cea) */
	C_KANJI_JIS_3C42, /*  0x8ec0 (U+5b9f) */
	C_KANJI_JIS_3C43, /*  0x8ec1 (U+8500) */
	C_KANJI_JIS_3C44, /*  0x8ec2 (U+7be0) */
	C_KANJI_JIS_3C45, /*  0x8ec3 (U+5072) */
	C_KANJI_JIS_3C46, /*  0x8ec4 (U+67f4) */
	C_KANJI_JIS_3C47, /*  0x8ec5 (U+829d) */
	C_KANJI_JIS_3C48, /*  0x8ec6 (U+5c61) */
	C_KANJI_JIS_3C49, /*  0x8ec7 (U+854a) */
	C_KANJI_JIS_3C4A, /*  0x8ec8 (U+7e1e) */
	C_KANJI_JIS_3C4B, /*  0x8ec9 (U+820e) */
	C_KANJI_JIS_3C4C, /*  0x8eca (U+5199) */
	C_KANJI_JIS_3C4D, /*  0x8ecb (U+5c04) */
	C_KANJI_JIS_3C4E, /*  0x8ecc (U+6368) */
	C_KANJI_JIS_3C4F, /*  0x8ecd (U+8d66) */
	C_KANJI_JIS_3C50, /*  0x8ece (U+659c) */
	C_KANJI_JIS_3C51, /*  0x8ecf (U+716e) */
	C_KANJI_JIS_3C52, /*  0x8ed0 (U+793e) */
	C_KANJI_JIS_3C53, /*  0x8ed1 (U+7d17) */
	C_KANJI_JIS_3C54, /*  0x8ed2 (U+8005) */
	C_KANJI_JIS_3C55, /*  0x8ed3 (U+8b1d) */
	C_KANJI_JIS_3C56, /*  0x8ed4 (U+8eca) */
	C_KANJI_JIS_3C57, /*  0x8ed5 (U+906e) */
	C_KANJI_JIS_3C58, /*  0x8ed6 (U+86c7) */
	C_KANJI_JIS_3C59, /*  0x8ed7 (U+90aa) */
	C_KANJI_JIS_3C5A, /*  0x8ed8 (U+501f) */
	C_KANJI_JIS_3C5B, /*  0x8ed9 (U+52fa) */
	C_KANJI_JIS_3C5C, /*  0x8eda (U+5c3a) */
	C_KANJI_JIS_3C5D, /*  0x8edb (U+6753) */
	C_KANJI_JIS_3C5E, /*  0x8edc (U+707c) */
	C_KANJI_JIS_3C5F, /*  0x8edd (U+7235) */
	C_KANJI_JIS_3C60, /*  0x8ede (U+914c) */
	C_KANJI_JIS_3C61, /*  0x8edf (U+91c8) */
	C_KANJI_JIS_3C62, /*  0x8ee0 (U+932b) */
	C_KANJI_JIS_3C63, /*  0x8ee1 (U+82e5) */
	C_KANJI_JIS_3C64, /*  0x8ee2 (U+5bc2) */
	C_KANJI_JIS_3C65, /*  0x8ee3 (U+5f31) */
	C_KANJI_JIS_3C66, /*  0x8ee4 (U+60f9) */
	C_KANJI_JIS_3C67, /*  0x8ee5 (U+4e3b) */
	C_KANJI_JIS_3C68, /*  0x8ee6 (U+53d6) */
	C_KANJI_JIS_3C69, /*  0x8ee7 (U+5b88) */
	C_KANJI_JIS_3C6A, /*  0x8ee8 (U+624b) */
	C_KANJI_JIS_3C6B, /*  0x8ee9 (U+6731) */
	C_KANJI_JIS_3C6C, /*  0x8eea (U+6b8a) */
	C_KANJI_JIS_3C6D, /*  0x8eeb (U+72e9) */
	C_KANJI_JIS_3C6E, /*  0x8eec (U+73e0) */
	C_KANJI_JIS_3C6F, /*  0x8eed (U+7a2e) */
	C_KANJI_JIS_3C70, /*  0x8eee (U+816b) */
	C_KANJI_JIS_3C71, /*  0x8eef (U+8da3) */
	C_KANJI_JIS_3C72, /*  0x8ef0 (U+9152) */
	C_KANJI_JIS_3C73, /*  0x8ef1 (U+9996) */
	C_KANJI_JIS_3C74, /*  0x8ef2 (U+5112) */
	C_KANJI_JIS_3C75, /*  0x8ef3 (U+53d7) */
	C_KANJI_JIS_3C76, /*  0x8ef4 (U+546a) */
	C_KANJI_JIS_3C77, /*  0x8ef5 (U+5bff) */
	C_KANJI_JIS_3C78, /*  0x8ef6 (U+6388) */
	C_KANJI_JIS_3C79, /*  0x8ef7 (U+6a39) */
	C_KANJI_JIS_3C7A, /*  0x8ef8 (U+7dac) */
	C_KANJI_JIS_3C7B, /*  0x8ef9 (U+9700) */
	C_KANJI_JIS_3C7C, /*  0x8efa (U+56da) */
	C_KANJI_JIS_3C7D, /*  0x8efb (U+53ce) */
	C_KANJI_JIS_3C7E, /*  0x8efc (U+5468) */
	0, /*  0x8efd */
	0, /*  0x8efe */
	0, /*  0x8eff */
	C_KANJI_JIS_3D21, /*  0x8f40 (U+5b97) */
	C_KANJI_JIS_3D22, /*  0x8f41 (U+5c31) */
	C_KANJI_JIS_3D23, /*  0x8f42 (U+5dde) */
	C_KANJI_JIS_3D24, /*  0x8f43 (U+4fee) */
	C_KANJI_JIS_3D25, /*  0x8f44 (U+6101) */
	C_KANJI_JIS_3D26, /*  0x8f45 (U+62fe) */
	C_KANJI_JIS_3D27, /*  0x8f46 (U+6d32) */
	C_KANJI_JIS_3D28, /*  0x8f47 (U+79c0) */
	C_KANJI_JIS_3D29, /*  0x8f48 (U+79cb) */
	C_KANJI_JIS_3D2A, /*  0x8f49 (U+7d42) */
	C_KANJI_JIS_3D2B, /*  0x8f4a (U+7e4d) */
	C_KANJI_JIS_3D2C, /*  0x8f4b (U+7fd2) */
	C_KANJI_JIS_3D2D, /*  0x8f4c (U+81ed) */
	C_KANJI_JIS_3D2E, /*  0x8f4d (U+821f) */
	C_KANJI_JIS_3D2F, /*  0x8f4e (U+8490) */
	C_KANJI_JIS_3D30, /*  0x8f4f (U+8846) */
	C_KANJI_JIS_3D31, /*  0x8f50 (U+8972) */
	C_KANJI_JIS_3D32, /*  0x8f51 (U+8b90) */
	C_KANJI_JIS_3D33, /*  0x8f52 (U+8e74) */
	C_KANJI_JIS_3D34, /*  0x8f53 (U+8f2f) */
	C_KANJI_JIS_3D35, /*  0x8f54 (U+9031) */
	C_KANJI_JIS_3D36, /*  0x8f55 (U+914b) */
	C_KANJI_JIS_3D37, /*  0x8f56 (U+916c) */
	C_KANJI_JIS_3D38, /*  0x8f57 (U+96c6) */
	C_KANJI_JIS_3D39, /*  0x8f58 (U+919c) */
	C_KANJI_JIS_3D3A, /*  0x8f59 (U+4ec0) */
	C_KANJI_JIS_3D3B, /*  0x8f5a (U+4f4f) */
	C_KANJI_JIS_3D3C, /*  0x8f5b (U+5145) */
	C_KANJI_JIS_3D3D, /*  0x8f5c (U+5341) */
	C_KANJI_JIS_3D3E, /*  0x8f5d (U+5f93) */
	C_KANJI_JIS_3D3F, /*  0x8f5e (U+620e) */
	C_KANJI_JIS_3D40, /*  0x8f5f (U+67d4) */
	C_KANJI_JIS_3D41, /*  0x8f60 (U+6c41) */
	C_KANJI_JIS_3D42, /*  0x8f61 (U+6e0b) */
	C_KANJI_JIS_3D43, /*  0x8f62 (U+7363) */
	C_KANJI_JIS_3D44, /*  0x8f63 (U+7e26) */
	C_KANJI_JIS_3D45, /*  0x8f64 (U+91cd) */
	C_KANJI_JIS_3D46, /*  0x8f65 (U+9283) */
	C_KANJI_JIS_3D47, /*  0x8f66 (U+53d4) */
	C_KANJI_JIS_3D48, /*  0x8f67 (U+5919) */
	C_KANJI_JIS_3D49, /*  0x8f68 (U+5bbf) */
	C_KANJI_JIS_3D4A, /*  0x8f69 (U+6dd1) */
	C_KANJI_JIS_3D4B, /*  0x8f6a (U+795d) */
	C_KANJI_JIS_3D4C, /*  0x8f6b (U+7e2e) */
	C_KANJI_JIS_3D4D, /*  0x8f6c (U+7c9b) */
	C_KANJI_JIS_3D4E, /*  0x8f6d (U+587e) */
	C_KANJI_JIS_3D4F, /*  0x8f6e (U+719f) */
	C_KANJI_JIS_3D50, /*  0x8f6f (U+51fa) */
	C_KANJI_JIS_3D51, /*  0x8f70 (U+8853) */
	C_KANJI_JIS_3D52, /*  0x8f71 (U+8ff0) */
	C_KANJI_JIS_3D53, /*  0x8f72 (U+4fca) */
	C_KANJI_JIS_3D54, /*  0x8f73 (U+5cfb) */
	C_KANJI_JIS_3D55, /*  0x8f74 (U+6625) */
	C_KANJI_JIS_3D56, /*  0x8f75 (U+77ac) */
	C_KANJI_JIS_3D57, /*  0x8f76 (U+7ae3) */
	C_KANJI_JIS_3D58, /*  0x8f77 (U+821c) */
	C_KANJI_JIS_3D59, /*  0x8f78 (U+99ff) */
	C_KANJI_JIS_3D5A, /*  0x8f79 (U+51c6) */
	C_KANJI_JIS_3D5B, /*  0x8f7a (U+5faa) */
	C_KANJI_JIS_3D5C, /*  0x8f7b (U+65ec) */
	C_KANJI_JIS_3D5D, /*  0x8f7c (U+696f) */
	C_KANJI_JIS_3D5E, /*  0x8f7d (U+6b89) */
	C_KANJI_JIS_3D5F, /*  0x8f7e (U+6df3) */
	0, /*  0x8f7f */
	C_KANJI_JIS_3D60, /*  0x8f80 (U+6e96) */
	C_KANJI_JIS_3D61, /*  0x8f81 (U+6f64) */
	C_KANJI_JIS_3D62, /*  0x8f82 (U+76fe) */
	C_KANJI_JIS_3D63, /*  0x8f83 (U+7d14) */
	C_KANJI_JIS_3D64, /*  0x8f84 (U+5de1) */
	C_KANJI_JIS_3D65, /*  0x8f85 (U+9075) */
	C_KANJI_JIS_3D66, /*  0x8f86 (U+9187) */
	C_KANJI_JIS_3D67, /*  0x8f87 (U+9806) */
	C_KANJI_JIS_3D68, /*  0x8f88 (U+51e6) */
	C_KANJI_JIS_3D69, /*  0x8f89 (U+521d) */
	C_KANJI_JIS_3D6A, /*  0x8f8a (U+6240) */
	C_KANJI_JIS_3D6B, /*  0x8f8b (U+6691) */
	C_KANJI_JIS_3D6C, /*  0x8f8c (U+66d9) */
	C_KANJI_JIS_3D6D, /*  0x8f8d (U+6e1a) */
	C_KANJI_JIS_3D6E, /*  0x8f8e (U+5eb6) */
	C_KANJI_JIS_3D6F, /*  0x8f8f (U+7dd2) */
	C_KANJI_JIS_3D70, /*  0x8f90 (U+7f72) */
	C_KANJI_JIS_3D71, /*  0x8f91 (U+66f8) */
	C_KANJI_JIS_3D72, /*  0x8f92 (U+85af) */
	C_KANJI_JIS_3D73, /*  0x8f93 (U+85f7) */
	C_KANJI_JIS_3D74, /*  0x8f94 (U+8af8) */
	C_KANJI_JIS_3D75, /*  0x8f95 (U+52a9) */
	C_KANJI_JIS_3D76, /*  0x8f96 (U+53d9) */
	C_KANJI_JIS_3D77, /*  0x8f97 (U+5973) */
	C_KANJI_JIS_3D78, /*  0x8f98 (U+5e8f) */
	C_KANJI_JIS_3D79, /*  0x8f99 (U+5f90) */
	C_KANJI_JIS_3D7A, /*  0x8f9a (U+6055) */
	C_KANJI_JIS_3D7B, /*  0x8f9b (U+92e4) */
	C_KANJI_JIS_3D7C, /*  0x8f9c (U+9664) */
	C_KANJI_JIS_3D7D, /*  0x8f9d (U+50b7) */
	C_KANJI_JIS_3D7E, /*  0x8f9e (U+511f) */
	C_KANJI_JIS_3E21, /*  0x8f9f (U+52dd) */
	C_KANJI_JIS_3E22, /*  0x8fa0 (U+5320) */
	C_KANJI_JIS_3E23, /*  0x8fa1 (U+5347) */
	C_KANJI_JIS_3E24, /*  0x8fa2 (U+53ec) */
	C_KANJI_JIS_3E25, /*  0x8fa3 (U+54e8) */
	C_KANJI_JIS_3E26, /*  0x8fa4 (U+5546) */
	C_KANJI_JIS_3E27, /*  0x8fa5 (U+5531) */
	C_KANJI_JIS_3E28, /*  0x8fa6 (U+5617) */
	C_KANJI_JIS_3E29, /*  0x8fa7 (U+5968) */
	C_KANJI_JIS_3E2A, /*  0x8fa8 (U+59be) */
	C_KANJI_JIS_3E2B, /*  0x8fa9 (U+5a3c) */
	C_KANJI_JIS_3E2C, /*  0x8faa (U+5bb5) */
	C_KANJI_JIS_3E2D, /*  0x8fab (U+5c06) */
	C_KANJI_JIS_3E2E, /*  0x8fac (U+5c0f) */
	C_KANJI_JIS_3E2F, /*  0x8fad (U+5c11) */
	C_KANJI_JIS_3E30, /*  0x8fae (U+5c1a) */
	C_KANJI_JIS_3E31, /*  0x8faf (U+5e84) */
	C_KANJI_JIS_3E32, /*  0x8fb0 (U+5e8a) */
	C_KANJI_JIS_3E33, /*  0x8fb1 (U+5ee0) */
	C_KANJI_JIS_3E34, /*  0x8fb2 (U+5f70) */
	C_KANJI_JIS_3E35, /*  0x8fb3 (U+627f) */
	C_KANJI_JIS_3E36, /*  0x8fb4 (U+6284) */
	C_KANJI_JIS_3E37, /*  0x8fb5 (U+62db) */
	C_KANJI_JIS_3E38, /*  0x8fb6 (U+638c) */
	C_KANJI_JIS_3E39, /*  0x8fb7 (U+6377) */
	C_KANJI_JIS_3E3A, /*  0x8fb8 (U+6607) */
	C_KANJI_JIS_3E3B, /*  0x8fb9 (U+660c) */
	C_KANJI_JIS_3E3C, /*  0x8fba (U+662d) */
	C_KANJI_JIS_3E3D, /*  0x8fbb (U+6676) */
	C_KANJI_JIS_3E3E, /*  0x8fbc (U+677e) */
	C_KANJI_JIS_3E3F, /*  0x8fbd (U+68a2) */
	C_KANJI_JIS_3E40, /*  0x8fbe (U+6a1f) */
	C_KANJI_JIS_3E41, /*  0x8fbf (U+6a35) */
	C_KANJI_JIS_3E42, /*  0x8fc0 (U+6cbc) */
	C_KANJI_JIS_3E43, /*  0x8fc1 (U+6d88) */
	C_KANJI_JIS_3E44, /*  0x8fc2 (U+6e09) */
	C_KANJI_JIS_3E45, /*  0x8fc3 (U+6e58) */
	C_KANJI_JIS_3E46, /*  0x8fc4 (U+713c) */
	C_KANJI_JIS_3E47, /*  0x8fc5 (U+7126) */
	C_KANJI_JIS_3E48, /*  0x8fc6 (U+7167) */
	C_KANJI_JIS_3E49, /*  0x8fc7 (U+75c7) */
	C_KANJI_JIS_3E4A, /*  0x8fc8 (U+7701) */
	C_KANJI_JIS_3E4B, /*  0x8fc9 (U+785d) */
	C_KANJI_JIS_3E4C, /*  0x8fca (U+7901) */
	C_KANJI_JIS_3E4D, /*  0x8fcb (U+7965) */
	C_KANJI_JIS_3E4E, /*  0x8fcc (U+79f0) */
	C_KANJI_JIS_3E4F, /*  0x8fcd (U+7ae0) */
	C_KANJI_JIS_3E50, /*  0x8fce (U+7b11) */
	C_KANJI_JIS_3E51, /*  0x8fcf (U+7ca7) */
	C_KANJI_JIS_3E52, /*  0x8fd0 (U+7d39) */
	C_KANJI_JIS_3E53, /*  0x8fd1 (U+8096) */
	C_KANJI_JIS_3E54, /*  0x8fd2 (U+83d6) */
	C_KANJI_JIS_3E55, /*  0x8fd3 (U+848b) */
	C_KANJI_JIS_3E56, /*  0x8fd4 (U+8549) */
	C_KANJI_JIS_3E57, /*  0x8fd5 (U+885d) */
	C_KANJI_JIS_3E58, /*  0x8fd6 (U+88f3) */
	C_KANJI_JIS_3E59, /*  0x8fd7 (U+8a1f) */
	C_KANJI_JIS_3E5A, /*  0x8fd8 (U+8a3c) */
	C_KANJI_JIS_3E5B, /*  0x8fd9 (U+8a54) */
	C_KANJI_JIS_3E5C, /*  0x8fda (U+8a73) */
	C_KANJI_JIS_3E5D, /*  0x8fdb (U+8c61) */
	C_KANJI_JIS_3E5E, /*  0x8fdc (U+8cde) */
	C_KANJI_JIS_3E5F, /*  0x8fdd (U+91a4) */
	C_KANJI_JIS_3E60, /*  0x8fde (U+9266) */
	C_KANJI_JIS_3E61, /*  0x8fdf (U+937e) */
	C_KANJI_JIS_3E62, /*  0x8fe0 (U+9418) */
	C_KANJI_JIS_3E63, /*  0x8fe1 (U+969c) */
	C_KANJI_JIS_3E64, /*  0x8fe2 (U+9798) */
	C_KANJI_JIS_3E65, /*  0x8fe3 (U+4e0a) */
	C_KANJI_JIS_3E66, /*  0x8fe4 (U+4e08) */
	C_KANJI_JIS_3E67, /*  0x8fe5 (U+4e1e) */
	C_KANJI_JIS_3E68, /*  0x8fe6 (U+4e57) */
	C_KANJI_JIS_3E69, /*  0x8fe7 (U+5197) */
	C_KANJI_JIS_3E6A, /*  0x8fe8 (U+5270) */
	C_KANJI_JIS_3E6B, /*  0x8fe9 (U+57ce) */
	C_KANJI_JIS_3E6C, /*  0x8fea (U+5834) */
	C_KANJI_JIS_3E6D, /*  0x8feb (U+58cc) */
	C_KANJI_JIS_3E6E, /*  0x8fec (U+5b22) */
	C_KANJI_JIS_3E6F, /*  0x8fed (U+5e38) */
	C_KANJI_JIS_3E70, /*  0x8fee (U+60c5) */
	C_KANJI_JIS_3E71, /*  0x8fef (U+64fe) */
	C_KANJI_JIS_3E72, /*  0x8ff0 (U+6761) */
	C_KANJI_JIS_3E73, /*  0x8ff1 (U+6756) */
	C_KANJI_JIS_3E74, /*  0x8ff2 (U+6d44) */
	C_KANJI_JIS_3E75, /*  0x8ff3 (U+72b6) */
	C_KANJI_JIS_3E76, /*  0x8ff4 (U+7573) */
	C_KANJI_JIS_3E77, /*  0x8ff5 (U+7a63) */
	C_KANJI_JIS_3E78, /*  0x8ff6 (U+84b8) */
	C_KANJI_JIS_3E79, /*  0x8ff7 (U+8b72) */
	C_KANJI_JIS_3E7A, /*  0x8ff8 (U+91b8) */
	C_KANJI_JIS_3E7B, /*  0x8ff9 (U+9320) */
	C_KANJI_JIS_3E7C, /*  0x8ffa (U+5631) */
	C_KANJI_JIS_3E7D, /*  0x8ffb (U+57f4) */
	C_KANJI_JIS_3E7E, /*  0x8ffc (U+98fe) */
	0, /*  0x8ffd */
	0, /*  0x8ffe */
	0, /*  0x8fff */
	C_KANJI_JIS_3F21, /*  0x9040 (U+62ed) */
	C_KANJI_JIS_3F22, /*  0x9041 (U+690d) */
	C_KANJI_JIS_3F23, /*  0x9042 (U+6b96) */
	C_KANJI_JIS_3F24, /*  0x9043 (U+71ed) */
	C_KANJI_JIS_3F25, /*  0x9044 (U+7e54) */
	C_KANJI_JIS_3F26, /*  0x9045 (U+8077) */
	C_KANJI_JIS_3F27, /*  0x9046 (U+8272) */
	C_KANJI_JIS_3F28, /*  0x9047 (U+89e6) */
	C_KANJI_JIS_3F29, /*  0x9048 (U+98df) */
	C_KANJI_JIS_3F2A, /*  0x9049 (U+8755) */
	C_KANJI_JIS_3F2B, /*  0x904a (U+8fb1) */
	C_KANJI_JIS_3F2C, /*  0x904b (U+5c3b) */
	C_KANJI_JIS_3F2D, /*  0x904c (U+4f38) */
	C_KANJI_JIS_3F2E, /*  0x904d (U+4fe1) */
	C_KANJI_JIS_3F2F, /*  0x904e (U+4fb5) */
	C_KANJI_JIS_3F30, /*  0x904f (U+5507) */
	C_KANJI_JIS_3F31, /*  0x9050 (U+5a20) */
	C_KANJI_JIS_3F32, /*  0x9051 (U+5bdd) */
	C_KANJI_JIS_3F33, /*  0x9052 (U+5be9) */
	C_KANJI_JIS_3F34, /*  0x9053 (U+5fc3) */
	C_KANJI_JIS_3F35, /*  0x9054 (U+614e) */
	C_KANJI_JIS_3F36, /*  0x9055 (U+632f) */
	C_KANJI_JIS_3F37, /*  0x9056 (U+65b0) */
	C_KANJI_JIS_3F38, /*  0x9057 (U+664b) */
	C_KANJI_JIS_3F39, /*  0x9058 (U+68ee) */
	C_KANJI_JIS_3F3A, /*  0x9059 (U+699b) */
	C_KANJI_JIS_3F3B, /*  0x905a (U+6d78) */
	C_KANJI_JIS_3F3C, /*  0x905b (U+6df1) */
	C_KANJI_JIS_3F3D, /*  0x905c (U+7533) */
	C_KANJI_JIS_3F3E, /*  0x905d (U+75b9) */
	C_KANJI_JIS_3F3F, /*  0x905e (U+771f) */
	C_KANJI_JIS_3F40, /*  0x905f (U+795e) */
	C_KANJI_JIS_3F41, /*  0x9060 (U+79e6) */
	C_KANJI_JIS_3F42, /*  0x9061 (U+7d33) */
	C_KANJI_JIS_3F43, /*  0x9062 (U+81e3) */
	C_KANJI_JIS_3F44, /*  0x9063 (U+82af) */
	C_KANJI_JIS_3F45, /*  0x9064 (U+85aa) */
	C_KANJI_JIS_3F46, /*  0x9065 (U+89aa) */
	C_KANJI_JIS_3F47, /*  0x9066 (U+8a3a) */
	C_KANJI_JIS_3F48, /*  0x9067 (U+8eab) */
	C_KANJI_JIS_3F49, /*  0x9068 (U+8f9b) */
	C_KANJI_JIS_3F4A, /*  0x9069 (U+9032) */
	C_KANJI_JIS_3F4B, /*  0x906a (U+91dd) */
	C_KANJI_JIS_3F4C, /*  0x906b (U+9707) */
	C_KANJI_JIS_3F4D, /*  0x906c (U+4eba) */
	C_KANJI_JIS_3F4E, /*  0x906d (U+4ec1) */
	C_KANJI_JIS_3F4F, /*  0x906e (U+5203) */
	C_KANJI_JIS_3F50, /*  0x906f (U+5875) */
	C_KANJI_JIS_3F51, /*  0x9070 (U+58ec) */
	C_KANJI_JIS_3F52, /*  0x9071 (U+5c0b) */
	C_KANJI_JIS_3F53, /*  0x9072 (U+751a) */
	C_KANJI_JIS_3F54, /*  0x9073 (U+5c3d) */
	C_KANJI_JIS_3F55, /*  0x9074 (U+814e) */
	C_KANJI_JIS_3F56, /*  0x9075 (U+8a0a) */
	C_KANJI_JIS_3F57, /*  0x9076 (U+8fc5) */
	C_KANJI_JIS_3F58, /*  0x9077 (U+9663) */
	C_KANJI_JIS_3F59, /*  0x9078 (U+976d) */
	C_KANJI_JIS_3F5A, /*  0x9079 (U+7b25) */
	C_KANJI_JIS_3F5B, /*  0x907a (U+8acf) */
	C_KANJI_JIS_3F5C, /*  0x907b (U+9808) */
	C_KANJI_JIS_3F5D, /*  0x907c (U+9162) */
	C_KANJI_JIS_3F5E, /*  0x907d (U+56f3) */
	C_KANJI_JIS_3F5F, /*  0x907e (U+53a8) */
	0, /*  0x907f */
	C_KANJI_JIS_3F60, /*  0x9080 (U+9017) */
	C_KANJI_JIS_3F61, /*  0x9081 (U+5439) */
	C_KANJI_JIS_3F62, /*  0x9082 (U+5782) */
	C_KANJI_JIS_3F63, /*  0x9083 (U+5e25) */
	C_KANJI_JIS_3F64, /*  0x9084 (U+63a8) */
	C_KANJI_JIS_3F65, /*  0x9085 (U+6c34) */
	C_KANJI_JIS_3F66, /*  0x9086 (U+708a) */
	C_KANJI_JIS_3F67, /*  0x9087 (U+7761) */
	C_KANJI_JIS_3F68, /*  0x9088 (U+7c8b) */
	C_KANJI_JIS_3F69, /*  0x9089 (U+7fe0) */
	C_KANJI_JIS_3F6A, /*  0x908a (U+8870) */
	C_KANJI_JIS_3F6B, /*  0x908b (U+9042) */
	C_KANJI_JIS_3F6C, /*  0x908c (U+9154) */
	C_KANJI_JIS_3F6D, /*  0x908d (U+9310) */
	C_KANJI_JIS_3F6E, /*  0x908e (U+9318) */
	C_KANJI_JIS_3F6F, /*  0x908f (U+968f) */
	C_KANJI_JIS_3F70, /*  0x9090 (U+745e) */
	C_KANJI_JIS_3F71, /*  0x9091 (U+9ac4) */
	C_KANJI_JIS_3F72, /*  0x9092 (U+5d07) */
	C_KANJI_JIS_3F73, /*  0x9093 (U+5d69) */
	C_KANJI_JIS_3F74, /*  0x9094 (U+6570) */
	C_KANJI_JIS_3F75, /*  0x9095 (U+67a2) */
	C_KANJI_JIS_3F76, /*  0x9096 (U+8da8) */
	C_KANJI_JIS_3F77, /*  0x9097 (U+96db) */
	C_KANJI_JIS_3F78, /*  0x9098 (U+636e) */
	C_KANJI_JIS_3F79, /*  0x9099 (U+6749) */
	C_KANJI_JIS_3F7A, /*  0x909a (U+6919) */
	C_KANJI_JIS_3F7B, /*  0x909b (U+83c5) */
	C_KANJI_JIS_3F7C, /*  0x909c (U+9817) */
	C_KANJI_JIS_3F7D, /*  0x909d (U+96c0) */
	C_KANJI_JIS_3F7E, /*  0x909e (U+88fe) */
	C_KANJI_JIS_4021, /*  0x909f (U+6f84) */
	C_KANJI_JIS_4022, /*  0x90a0 (U+647a) */
	C_KANJI_JIS_4023, /*  0x90a1 (U+5bf8) */
	C_KANJI_JIS_4024, /*  0x90a2 (U+4e16) */
	C_KANJI_JIS_4025, /*  0x90a3 (U+702c) */
	C_KANJI_JIS_4026, /*  0x90a4 (U+755d) */
	C_KANJI_JIS_4027, /*  0x90a5 (U+662f) */
	C_KANJI_JIS_4028, /*  0x90a6 (U+51c4) */
	C_KANJI_JIS_4029, /*  0x90a7 (U+5236) */
	C_KANJI_JIS_402A, /*  0x90a8 (U+52e2) */
	C_KANJI_JIS_402B, /*  0x90a9 (U+59d3) */
	C_KANJI_JIS_402C, /*  0x90aa (U+5f81) */
	C_KANJI_JIS_402D, /*  0x90ab (U+6027) */
	C_KANJI_JIS_402E, /*  0x90ac (U+6210) */
	C_KANJI_JIS_402F, /*  0x90ad (U+653f) */
	C_KANJI_JIS_4030, /*  0x90ae (U+6574) */
	C_KANJI_JIS_4031, /*  0x90af (U+661f) */
	C_KANJI_JIS_4032, /*  0x90b0 (U+6674) */
	C_KANJI_JIS_4033, /*  0x90b1 (U+68f2) */
	C_KANJI_JIS_4034, /*  0x90b2 (U+6816) */
	C_KANJI_JIS_4035, /*  0x90b3 (U+6b63) */
	C_KANJI_JIS_4036, /*  0x90b4 (U+6e05) */
	C_KANJI_JIS_4037, /*  0x90b5 (U+7272) */
	C_KANJI_JIS_4038, /*  0x90b6 (U+751f) */
	C_KANJI_JIS_4039, /*  0x90b7 (U+76db) */
	C_KANJI_JIS_403A, /*  0x90b8 (U+7cbe) */
	C_KANJI_JIS_403B, /*  0x90b9 (U+8056) */
	C_KANJI_JIS_403C, /*  0x90ba (U+58f0) */
	C_KANJI_JIS_403D, /*  0x90bb (U+88fd) */
	C_KANJI_JIS_403E, /*  0x90bc (U+897f) */
	C_KANJI_JIS_403F, /*  0x90bd (U+8aa0) */
	C_KANJI_JIS_4040, /*  0x90be (U+8a93) */
	C_KANJI_JIS_4041, /*  0x90bf (U+8acb) */
	C_KANJI_JIS_4042, /*  0x90c0 (U+901d) */
	C_KANJI_JIS_4043, /*  0x90c1 (U+9192) */
	C_KANJI_JIS_4044, /*  0x90c2 (U+9752) */
	C_KANJI_JIS_4045, /*  0x90c3 (U+9759) */
	C_KANJI_JIS_4046, /*  0x90c4 (U+6589) */
	C_KANJI_JIS_4047, /*  0x90c5 (U+7a0e) */
	C_KANJI_JIS_4048, /*  0x90c6 (U+8106) */
	C_KANJI_JIS_4049, /*  0x90c7 (U+96bb) */
	C_KANJI_JIS_404A, /*  0x90c8 (U+5e2d) */
	C_KANJI_JIS_404B, /*  0x90c9 (U+60dc) */
	C_KANJI_JIS_404C, /*  0x90ca (U+621a) */
	C_KANJI_JIS_404D, /*  0x90cb (U+65a5) */
	C_KANJI_JIS_404E, /*  0x90cc (U+6614) */
	C_KANJI_JIS_404F, /*  0x90cd (U+6790) */
	C_KANJI_JIS_4050, /*  0x90ce (U+77f3) */
	C_KANJI_JIS_4051, /*  0x90cf (U+7a4d) */
	C_KANJI_JIS_4052, /*  0x90d0 (U+7c4d) */
	C_KANJI_JIS_4053, /*  0x90d1 (U+7e3e) */
	C_KANJI_JIS_4054, /*  0x90d2 (U+810a) */
	C_KANJI_JIS_4055, /*  0x90d3 (U+8cac) */
	C_KANJI_JIS_4056, /*  0x90d4 (U+8d64) */
	C_KANJI_JIS_4057, /*  0x90d5 (U+8de1) */
	C_KANJI_JIS_4058, /*  0x90d6 (U+8e5f) */
	C_KANJI_JIS_4059, /*  0x90d7 (U+78a9) */
	C_KANJI_JIS_405A, /*  0x90d8 (U+5207) */
	C_KANJI_JIS_405B, /*  0x90d9 (U+62d9) */
	C_KANJI_JIS_405C, /*  0x90da (U+63a5) */
	C_KANJI_JIS_405D, /*  0x90db (U+6442) */
	C_KANJI_JIS_405E, /*  0x90dc (U+6298) */
	C_KANJI_JIS_405F, /*  0x90dd (U+8a2d) */
	C_KANJI_JIS_4060, /*  0x90de (U+7a83) */
	C_KANJI_JIS_4061, /*  0x90df (U+7bc0) */
	C_KANJI_JIS_4062, /*  0x90e0 (U+8aac) */
	C_KANJI_JIS_4063, /*  0x90e1 (U+96ea) */
	C_KANJI_JIS_4064, /*  0x90e2 (U+7d76) */
	C_KANJI_JIS_4065, /*  0x90e3 (U+820c) */
	C_KANJI_JIS_4066, /*  0x90e4 (U+8749) */
	C_KANJI_JIS_4067, /*  0x90e5 (U+4ed9) */
	C_KANJI_JIS_4068, /*  0x90e6 (U+5148) */
	C_KANJI_JIS_4069, /*  0x90e7 (U+5343) */
	C_KANJI_JIS_406A, /*  0x90e8 (U+5360) */
	C_KANJI_JIS_406B, /*  0x90e9 (U+5ba3) */
	C_KANJI_JIS_406C, /*  0x90ea (U+5c02) */
	C_KANJI_JIS_406D, /*  0x90eb (U+5c16) */
	C_KANJI_JIS_406E, /*  0x90ec (U+5ddd) */
	C_KANJI_JIS_406F, /*  0x90ed (U+6226) */
	C_KANJI_JIS_4070, /*  0x90ee (U+6247) */
	C_KANJI_JIS_4071, /*  0x90ef (U+64b0) */
	C_KANJI_JIS_4072, /*  0x90f0 (U+6813) */
	C_KANJI_JIS_4073, /*  0x90f1 (U+6834) */
	C_KANJI_JIS_4074, /*  0x90f2 (U+6cc9) */
	C_KANJI_JIS_4075, /*  0x90f3 (U+6d45) */
	C_KANJI_JIS_4076, /*  0x90f4 (U+6d17) */
	C_KANJI_JIS_4077, /*  0x90f5 (U+67d3) */
	C_KANJI_JIS_4078, /*  0x90f6 (U+6f5c) */
	C_KANJI_JIS_4079, /*  0x90f7 (U+714e) */
	C_KANJI_JIS_407A, /*  0x90f8 (U+717d) */
	C_KANJI_JIS_407B, /*  0x90f9 (U+65cb) */
	C_KANJI_JIS_407C, /*  0x90fa (U+7a7f) */
	C_KANJI_JIS_407D, /*  0x90fb (U+7bad) */
	C_KANJI_JIS_407E, /*  0x90fc (U+7dda) */
	0, /*  0x90fd */
	0, /*  0x90fe */
	0, /*  0x90ff */
	C_KANJI_JIS_4121, /*  0x9140 (U+7e4a) */
	C_KANJI_JIS_4122, /*  0x9141 (U+7fa8) */
	C_KANJI_JIS_4123, /*  0x9142 (U+817a) */
	C_KANJI_JIS_4124, /*  0x9143 (U+821b) */
	C_KANJI_JIS_4125, /*  0x9144 (U+8239) */
	C_KANJI_JIS_4126, /*  0x9145 (U+85a6) */
	C_KANJI_JIS_4127, /*  0x9146 (U+8a6e) */
	C_KANJI_JIS_4128, /*  0x9147 (U+8cce) */
	C_KANJI_JIS_4129, /*  0x9148 (U+8df5) */
	C_KANJI_JIS_412A, /*  0x9149 (U+9078) */
	C_KANJI_JIS_412B, /*  0x914a (U+9077) */
	C_KANJI_JIS_412C, /*  0x914b (U+92ad) */
	C_KANJI_JIS_412D, /*  0x914c (U+9291) */
	C_KANJI_JIS_412E, /*  0x914d (U+9583) */
	C_KANJI_JIS_412F, /*  0x914e (U+9bae) */
	C_KANJI_JIS_4130, /*  0x914f (U+524d) */
	C_KANJI_JIS_4131, /*  0x9150 (U+5584) */
	C_KANJI_JIS_4132, /*  0x9151 (U+6f38) */
	C_KANJI_JIS_4133, /*  0x9152 (U+7136) */
	C_KANJI_JIS_4134, /*  0x9153 (U+5168) */
	C_KANJI_JIS_4135, /*  0x9154 (U+7985) */
	C_KANJI_JIS_4136, /*  0x9155 (U+7e55) */
	C_KANJI_JIS_4137, /*  0x9156 (U+81b3) */
	C_KANJI_JIS_4138, /*  0x9157 (U+7cce) */
	C_KANJI_JIS_4139, /*  0x9158 (U+564c) */
	C_KANJI_JIS_413A, /*  0x9159 (U+5851) */
	C_KANJI_JIS_413B, /*  0x915a (U+5ca8) */
	C_KANJI_JIS_413C, /*  0x915b (U+63aa) */
	C_KANJI_JIS_413D, /*  0x915c (U+66fe) */
	C_KANJI_JIS_413E, /*  0x915d (U+66fd) */
	C_KANJI_JIS_413F, /*  0x915e (U+695a) */
	C_KANJI_JIS_4140, /*  0x915f (U+72d9) */
	C_KANJI_JIS_4141, /*  0x9160 (U+758f) */
	C_KANJI_JIS_4142, /*  0x9161 (U+758e) */
	C_KANJI_JIS_4143, /*  0x9162 (U+790e) */
	C_KANJI_JIS_4144, /*  0x9163 (U+7956) */
	C_KANJI_JIS_4145, /*  0x9164 (U+79df) */
	C_KANJI_JIS_4146, /*  0x9165 (U+7c97) */
	C_KANJI_JIS_4147, /*  0x9166 (U+7d20) */
	C_KANJI_JIS_4148, /*  0x9167 (U+7d44) */
	C_KANJI_JIS_4149, /*  0x9168 (U+8607) */
	C_KANJI_JIS_414A, /*  0x9169 (U+8a34) */
	C_KANJI_JIS_414B, /*  0x916a (U+963b) */
	C_KANJI_JIS_414C, /*  0x916b (U+9061) */
	C_KANJI_JIS_414D, /*  0x916c (U+9f20) */
	C_KANJI_JIS_414E, /*  0x916d (U+50e7) */
	C_KANJI_JIS_414F, /*  0x916e (U+5275) */
	C_KANJI_JIS_4150, /*  0x916f (U+53cc) */
	C_KANJI_JIS_4151, /*  0x9170 (U+53e2) */
	C_KANJI_JIS_4152, /*  0x9171 (U+5009) */
	C_KANJI_JIS_4153, /*  0x9172 (U+55aa) */
	C_KANJI_JIS_4154, /*  0x9173 (U+58ee) */
	C_KANJI_JIS_4155, /*  0x9174 (U+594f) */
	C_KANJI_JIS_4156, /*  0x9175 (U+723d) */
	C_KANJI_JIS_4157, /*  0x9176 (U+5b8b) */
	C_KANJI_JIS_4158, /*  0x9177 (U+5c64) */
	C_KANJI_JIS_4159, /*  0x9178 (U+531d) */
	C_KANJI_JIS_415A, /*  0x9179 (U+60e3) */
	C_KANJI_JIS_415B, /*  0x917a (U+60f3) */
	C_KANJI_JIS_415C, /*  0x917b (U+635c) */
	C_KANJI_JIS_415D, /*  0x917c (U+6383) */
	C_KANJI_JIS_415E, /*  0x917d (U+633f) */
	C_KANJI_JIS_415F, /*  0x917e (U+63bb) */
	0, /*  0x917f */
	C_KANJI_JIS_4160, /*  0x9180 (U+64cd) */
	C_KANJI_JIS_4161, /*  0x9181 (U+65e9) */
	C_KANJI_JIS_4162, /*  0x9182 (U+66f9) */
	C_KANJI_JIS_4163, /*  0x9183 (U+5de3) */
	C_KANJI_JIS_4164, /*  0x9184 (U+69cd) */
	C_KANJI_JIS_4165, /*  0x9185 (U+69fd) */
	C_KANJI_JIS_4166, /*  0x9186 (U+6f15) */
	C_KANJI_JIS_4167, /*  0x9187 (U+71e5) */
	C_KANJI_JIS_4168, /*  0x9188 (U+4e89) */
	C_KANJI_JIS_4169, /*  0x9189 (U+75e9) */
	C_KANJI_JIS_416A, /*  0x918a (U+76f8) */
	C_KANJI_JIS_416B, /*  0x918b (U+7a93) */
	C_KANJI_JIS_416C, /*  0x918c (U+7cdf) */
	C_KANJI_JIS_416D, /*  0x918d (U+7dcf) */
	C_KANJI_JIS_416E, /*  0x918e (U+7d9c) */
	C_KANJI_JIS_416F, /*  0x918f (U+8061) */
	C_KANJI_JIS_4170, /*  0x9190 (U+8349) */
	C_KANJI_JIS_4171, /*  0x9191 (U+8358) */
	C_KANJI_JIS_4172, /*  0x9192 (U+846c) */
	C_KANJI_JIS_4173, /*  0x9193 (U+84bc) */
	C_KANJI_JIS_4174, /*  0x9194 (U+85fb) */
	C_KANJI_JIS_4175, /*  0x9195 (U+88c5) */
	C_KANJI_JIS_4176, /*  0x9196 (U+8d70) */
	C_KANJI_JIS_4177, /*  0x9197 (U+9001) */
	C_KANJI_JIS_4178, /*  0x9198 (U+906d) */
	C_KANJI_JIS_4179, /*  0x9199 (U+9397) */
	C_KANJI_JIS_417A, /*  0x919a (U+971c) */
	C_KANJI_JIS_417B, /*  0x919b (U+9a12) */
	C_KANJI_JIS_417C, /*  0x919c (U+50cf) */
	C_KANJI_JIS_417D, /*  0x919d (U+5897) */
	C_KANJI_JIS_417E, /*  0x919e (U+618e) */
	C_KANJI_JIS_4221, /*  0x919f (U+81d3) */
	C_KANJI_JIS_4222, /*  0x91a0 (U+8535) */
	C_KANJI_JIS_4223, /*  0x91a1 (U+8d08) */
	C_KANJI_JIS_4224, /*  0x91a2 (U+9020) */
	C_KANJI_JIS_4225, /*  0x91a3 (U+4fc3) */
	C_KANJI_JIS_4226, /*  0x91a4 (U+5074) */
	C_KANJI_JIS_4227, /*  0x91a5 (U+5247) */
	C_KANJI_JIS_4228, /*  0x91a6 (U+5373) */
	C_KANJI_JIS_4229, /*  0x91a7 (U+606f) */
	C_KANJI_JIS_422A, /*  0x91a8 (U+6349) */
	C_KANJI_JIS_422B, /*  0x91a9 (U+675f) */
	C_KANJI_JIS_422C, /*  0x91aa (U+6e2c) */
	C_KANJI_JIS_422D, /*  0x91ab (U+8db3) */
	C_KANJI_JIS_422E, /*  0x91ac (U+901f) */
	C_KANJI_JIS_422F, /*  0x91ad (U+4fd7) */
	C_KANJI_JIS_4230, /*  0x91ae (U+5c5e) */
	C_KANJI_JIS_4231, /*  0x91af (U+8cca) */
	C_KANJI_JIS_4232, /*  0x91b0 (U+65cf) */
	C_KANJI_JIS_4233, /*  0x91b1 (U+7d9a) */
	C_KANJI_JIS_4234, /*  0x91b2 (U+5352) */
	C_KANJI_JIS_4235, /*  0x91b3 (U+8896) */
	C_KANJI_JIS_4236, /*  0x91b4 (U+5176) */
	C_KANJI_JIS_4237, /*  0x91b5 (U+63c3) */
	C_KANJI_JIS_4238, /*  0x91b6 (U+5b58) */
	C_KANJI_JIS_4239, /*  0x91b7 (U+5b6b) */
	C_KANJI_JIS_423A, /*  0x91b8 (U+5c0a) */
	C_KANJI_JIS_423B, /*  0x91b9 (U+640d) */
	C_KANJI_JIS_423C, /*  0x91ba (U+6751) */
	C_KANJI_JIS_423D, /*  0x91bb (U+905c) */
	C_KANJI_JIS_423E, /*  0x91bc (U+4ed6) */
	C_KANJI_JIS_423F, /*  0x91bd (U+591a) */
	C_KANJI_JIS_4240, /*  0x91be (U+592a) */
	C_KANJI_JIS_4241, /*  0x91bf (U+6c70) */
	C_KANJI_JIS_4242, /*  0x91c0 (U+8a51) */
	C_KANJI_JIS_4243, /*  0x91c1 (U+553e) */
	C_KANJI_JIS_4244, /*  0x91c2 (U+5815) */
	C_KANJI_JIS_4245, /*  0x91c3 (U+59a5) */
	C_KANJI_JIS_4246, /*  0x91c4 (U+60f0) */
	C_KANJI_JIS_4247, /*  0x91c5 (U+6253) */
	C_KANJI_JIS_4248, /*  0x91c6 (U+67c1) */
	C_KANJI_JIS_4249, /*  0x91c7 (U+8235) */
	C_KANJI_JIS_424A, /*  0x91c8 (U+6955) */
	C_KANJI_JIS_424B, /*  0x91c9 (U+9640) */
	C_KANJI_JIS_424C, /*  0x91ca (U+99c4) */
	C_KANJI_JIS_424D, /*  0x91cb (U+9a28) */
	C_KANJI_JIS_424E, /*  0x91cc (U+4f53) */
	C_KANJI_JIS_424F, /*  0x91cd (U+5806) */
	C_KANJI_JIS_4250, /*  0x91ce (U+5bfe) */
	C_KANJI_JIS_4251, /*  0x91cf (U+8010) */
	C_KANJI_JIS_4252, /*  0x91d0 (U+5cb1) */
	C_KANJI_JIS_4253, /*  0x91d1 (U+5e2f) */
	C_KANJI_JIS_4254, /*  0x91d2 (U+5f85) */
	C_KANJI_JIS_4255, /*  0x91d3 (U+6020) */
	C_KANJI_JIS_4256, /*  0x91d4 (U+614b) */
	C_KANJI_JIS_4257, /*  0x91d5 (U+6234) */
	C_KANJI_JIS_4258, /*  0x91d6 (U+66ff) */
	C_KANJI_JIS_4259, /*  0x91d7 (U+6cf0) */
	C_KANJI_JIS_425A, /*  0x91d8 (U+6ede) */
	C_KANJI_JIS_425B, /*  0x91d9 (U+80ce) */
	C_KANJI_JIS_425C, /*  0x91da (U+817f) */
	C_KANJI_JIS_425D, /*  0x91db (U+82d4) */
	C_KANJI_JIS_425E, /*  0x91dc (U+888b) */
	C_KANJI_JIS_425F, /*  0x91dd (U+8cb8) */
	C_KANJI_JIS_4260, /*  0x91de (U+9000) */
	C_KANJI_JIS_4261, /*  0x91df (U+902e) */
	C_KANJI_JIS_4262, /*  0x91e0 (U+968a) */
	C_KANJI_JIS_4263, /*  0x91e1 (U+9edb) */
	C_KANJI_JIS_4264, /*  0x91e2 (U+9bdb) */
	C_KANJI_JIS_4265, /*  0x91e3 (U+4ee3) */
	C_KANJI_JIS_4266, /*  0x91e4 (U+53f0) */
	C_KANJI_JIS_4267, /*  0x91e5 (U+5927) */
	C_KANJI_JIS_4268, /*  0x91e6 (U+7b2c) */
	C_KANJI_JIS_4269, /*  0x91e7 (U+918d) */
	C_KANJI_JIS_426A, /*  0x91e8 (U+984c) */
	C_KANJI_JIS_426B, /*  0x91e9 (U+9df9) */
	C_KANJI_JIS_426C, /*  0x91ea (U+6edd) */
	C_KANJI_JIS_426D, /*  0x91eb (U+7027) */
	C_KANJI_JIS_426E, /*  0x91ec (U+5353) */
	C_KANJI_JIS_426F, /*  0x91ed (U+5544) */
	C_KANJI_JIS_4270, /*  0x91ee (U+5b85) */
	C_KANJI_JIS_4271, /*  0x91ef (U+6258) */
	C_KANJI_JIS_4272, /*  0x91f0 (U+629e) */
	C_KANJI_JIS_4273, /*  0x91f1 (U+62d3) */
	C_KANJI_JIS_4274, /*  0x91f2 (U+6ca2) */
	C_KANJI_JIS_4275, /*  0x91f3 (U+6fef) */
	C_KANJI_JIS_4276, /*  0x91f4 (U+7422) */
	C_KANJI_JIS_4277, /*  0x91f5 (U+8a17) */
	C_KANJI_JIS_4278, /*  0x91f6 (U+9438) */
	C_KANJI_JIS_4279, /*  0x91f7 (U+6fc1) */
	C_KANJI_JIS_427A, /*  0x91f8 (U+8afe) */
	C_KANJI_JIS_427B, /*  0x91f9 (U+8338) */
	C_KANJI_JIS_427C, /*  0x91fa (U+51e7) */
	C_KANJI_JIS_427D, /*  0x91fb (U+86f8) */
	C_KANJI_JIS_427E, /*  0x91fc (U+53ea) */
	0, /*  0x91fd */
	0, /*  0x91fe */
	0, /*  0x91ff */
	C_KANJI_JIS_4321, /*  0x9240 (U+53e9) */
	C_KANJI_JIS_4322, /*  0x9241 (U+4f46) */
	C_KANJI_JIS_4323, /*  0x9242 (U+9054) */
	C_KANJI_JIS_4324, /*  0x9243 (U+8fb0) */
	C_KANJI_JIS_4325, /*  0x9244 (U+596a) */
	C_KANJI_JIS_4326, /*  0x9245 (U+8131) */
	C_KANJI_JIS_4327, /*  0x9246 (U+5dfd) */
	C_KANJI_JIS_4328, /*  0x9247 (U+7aea) */
	C_KANJI_JIS_4329, /*  0x9248 (U+8fbf) */
	C_KANJI_JIS_432A, /*  0x9249 (U+68da) */
	C_KANJI_JIS_432B, /*  0x924a (U+8c37) */
	C_KANJI_JIS_432C, /*  0x924b (U+72f8) */
	C_KANJI_JIS_432D, /*  0x924c (U+9c48) */
	C_KANJI_JIS_432E, /*  0x924d (U+6a3d) */
	C_KANJI_JIS_432F, /*  0x924e (U+8ab0) */
	C_KANJI_JIS_4330, /*  0x924f (U+4e39) */
	C_KANJI_JIS_4331, /*  0x9250 (U+5358) */
	C_KANJI_JIS_4332, /*  0x9251 (U+5606) */
	C_KANJI_JIS_4333, /*  0x9252 (U+5766) */
	C_KANJI_JIS_4334, /*  0x9253 (U+62c5) */
	C_KANJI_JIS_4335, /*  0x9254 (U+63a2) */
	C_KANJI_JIS_4336, /*  0x9255 (U+65e6) */
	C_KANJI_JIS_4337, /*  0x9256 (U+6b4e) */
	C_KANJI_JIS_4338, /*  0x9257 (U+6de1) */
	C_KANJI_JIS_4339, /*  0x9258 (U+6e5b) */
	C_KANJI_JIS_433A, /*  0x9259 (U+70ad) */
	C_KANJI_JIS_433B, /*  0x925a (U+77ed) */
	C_KANJI_JIS_433C, /*  0x925b (U+7aef) */
	C_KANJI_JIS_433D, /*  0x925c (U+7baa) */
	C_KANJI_JIS_433E, /*  0x925d (U+7dbb) */
	C_KANJI_JIS_433F, /*  0x925e (U+803d) */
	C_KANJI_JIS_4340, /*  0x925f (U+80c6) */
	C_KANJI_JIS_4341, /*  0x9260 (U+86cb) */
	C_KANJI_JIS_4342, /*  0x9261 (U+8a95) */
	C_KANJI_JIS_4343, /*  0x9262 (U+935b) */
	C_KANJI_JIS_4344, /*  0x9263 (U+56e3) */
	C_KANJI_JIS_4345, /*  0x9264 (U+58c7) */
	C_KANJI_JIS_4346, /*  0x9265 (U+5f3e) */
	C_KANJI_JIS_4347, /*  0x9266 (U+65ad) */
	C_KANJI_JIS_4348, /*  0x9267 (U+6696) */
	C_KANJI_JIS_4349, /*  0x9268 (U+6a80) */
	C_KANJI_JIS_434A, /*  0x9269 (U+6bb5) */
	C_KANJI_JIS_434B, /*  0x926a (U+7537) */
	C_KANJI_JIS_434C, /*  0x926b (U+8ac7) */
	C_KANJI_JIS_434D, /*  0x926c (U+5024) */
	C_KANJI_JIS_434E, /*  0x926d (U+77e5) */
	C_KANJI_JIS_434F, /*  0x926e (U+5730) */
	C_KANJI_JIS_4350, /*  0x926f (U+5f1b) */
	C_KANJI_JIS_4351, /*  0x9270 (U+6065) */
	C_KANJI_JIS_4352, /*  0x9271 (U+667a) */
	C_KANJI_JIS_4353, /*  0x9272 (U+6c60) */
	C_KANJI_JIS_4354, /*  0x9273 (U+75f4) */
	C_KANJI_JIS_4355, /*  0x9274 (U+7a1a) */
	C_KANJI_JIS_4356, /*  0x9275 (U+7f6e) */
	C_KANJI_JIS_4357, /*  0x9276 (U+81f4) */
	C_KANJI_JIS_4358, /*  0x9277 (U+8718) */
	C_KANJI_JIS_4359, /*  0x9278 (U+9045) */
	C_KANJI_JIS_435A, /*  0x9279 (U+99b3) */
	C_KANJI_JIS_435B, /*  0x927a (U+7bc9) */
	C_KANJI_JIS_435C, /*  0x927b (U+755c) */
	C_KANJI_JIS_435D, /*  0x927c (U+7af9) */
	C_KANJI_JIS_435E, /*  0x927d (U+7b51) */
	C_KANJI_JIS_435F, /*  0x927e (U+84c4) */
	0, /*  0x927f */
	C_KANJI_JIS_4360, /*  0x9280 (U+9010) */
	C_KANJI_JIS_4361, /*  0x9281 (U+79e9) */
	C_KANJI_JIS_4362, /*  0x9282 (U+7a92) */
	C_KANJI_JIS_4363, /*  0x9283 (U+8336) */
	C_KANJI_JIS_4364, /*  0x9284 (U+5ae1) */
	C_KANJI_JIS_4365, /*  0x9285 (U+7740) */
	C_KANJI_JIS_4366, /*  0x9286 (U+4e2d) */
	C_KANJI_JIS_4367, /*  0x9287 (U+4ef2) */
	C_KANJI_JIS_4368, /*  0x9288 (U+5b99) */
	C_KANJI_JIS_4369, /*  0x9289 (U+5fe0) */
	C_KANJI_JIS_436A, /*  0x928a (U+62bd) */
	C_KANJI_JIS_436B, /*  0x928b (U+663c) */
	C_KANJI_JIS_436C, /*  0x928c (U+67f1) */
	C_KANJI_JIS_436D, /*  0x928d (U+6ce8) */
	C_KANJI_JIS_436E, /*  0x928e (U+866b) */
	C_KANJI_JIS_436F, /*  0x928f (U+8877) */
	C_KANJI_JIS_4370, /*  0x9290 (U+8a3b) */
	C_KANJI_JIS_4371, /*  0x9291 (U+914e) */
	C_KANJI_JIS_4372, /*  0x9292 (U+92f3) */
	C_KANJI_JIS_4373, /*  0x9293 (U+99d0) */
	C_KANJI_JIS_4374, /*  0x9294 (U+6a17) */
	C_KANJI_JIS_4375, /*  0x9295 (U+7026) */
	C_KANJI_JIS_4376, /*  0x9296 (U+732a) */
	C_KANJI_JIS_4377, /*  0x9297 (U+82e7) */
	C_KANJI_JIS_4378, /*  0x9298 (U+8457) */
	C_KANJI_JIS_4379, /*  0x9299 (U+8caf) */
	C_KANJI_JIS_437A, /*  0x929a (U+4e01) */
	C_KANJI_JIS_437B, /*  0x929b (U+5146) */
	C_KANJI_JIS_437C, /*  0x929c (U+51cb) */
	C_KANJI_JIS_437D, /*  0x929d (U+558b) */
	C_KANJI_JIS_437E, /*  0x929e (U+5bf5) */
	C_KANJI_JIS_4421, /*  0x929f (U+5e16) */
	C_KANJI_JIS_4422, /*  0x92a0 (U+5e33) */
	C_KANJI_JIS_4423, /*  0x92a1 (U+5e81) */
	C_KANJI_JIS_4424, /*  0x92a2 (U+5f14) */
	C_KANJI_JIS_4425, /*  0x92a3 (U+5f35) */
	C_KANJI_JIS_4426, /*  0x92a4 (U+5f6b) */
	C_KANJI_JIS_4427, /*  0x92a5 (U+5fb4) */
	C_KANJI_JIS_4428, /*  0x92a6 (U+61f2) */
	C_KANJI_JIS_4429, /*  0x92a7 (U+6311) */
	C_KANJI_JIS_442A, /*  0x92a8 (U+66a2) */
	C_KANJI_JIS_442B, /*  0x92a9 (U+671d) */
	C_KANJI_JIS_442C, /*  0x92aa (U+6f6e) */
	C_KANJI_JIS_442D, /*  0x92ab (U+7252) */
	C_KANJI_JIS_442E, /*  0x92ac (U+753a) */
	C_KANJI_JIS_442F, /*  0x92ad (U+773a) */
	C_KANJI_JIS_4430, /*  0x92ae (U+8074) */
	C_KANJI_JIS_4431, /*  0x92af (U+8139) */
	C_KANJI_JIS_4432, /*  0x92b0 (U+8178) */
	C_KANJI_JIS_4433, /*  0x92b1 (U+8776) */
	C_KANJI_JIS_4434, /*  0x92b2 (U+8abf) */
	C_KANJI_JIS_4435, /*  0x92b3 (U+8adc) */
	C_KANJI_JIS_4436, /*  0x92b4 (U+8d85) */
	C_KANJI_JIS_4437, /*  0x92b5 (U+8df3) */
	C_KANJI_JIS_4438, /*  0x92b6 (U+929a) */
	C_KANJI_JIS_4439, /*  0x92b7 (U+9577) */
	C_KANJI_JIS_443A, /*  0x92b8 (U+9802) */
	C_KANJI_JIS_443B, /*  0x92b9 (U+9ce5) */
	C_KANJI_JIS_443C, /*  0x92ba (U+52c5) */
	C_KANJI_JIS_443D, /*  0x92bb (U+6357) */
	C_KANJI_JIS_443E, /*  0x92bc (U+76f4) */
	C_KANJI_JIS_443F, /*  0x92bd (U+6715) */
	C_KANJI_JIS_4440, /*  0x92be (U+6c88) */
	C_KANJI_JIS_4441, /*  0x92bf (U+73cd) */
	C_KANJI_JIS_4442, /*  0x92c0 (U+8cc3) */
	C_KANJI_JIS_4443, /*  0x92c1 (U+93ae) */
	C_KANJI_JIS_4444, /*  0x92c2 (U+9673) */
	C_KANJI_JIS_4445, /*  0x92c3 (U+6d25) */
	C_KANJI_JIS_4446, /*  0x92c4 (U+589c) */
	C_KANJI_JIS_4447, /*  0x92c5 (U+690e) */
	C_KANJI_JIS_4448, /*  0x92c6 (U+69cc) */
	C_KANJI_JIS_4449, /*  0x92c7 (U+8ffd) */
	C_KANJI_JIS_444A, /*  0x92c8 (U+939a) */
	C_KANJI_JIS_444B, /*  0x92c9 (U+75db) */
	C_KANJI_JIS_444C, /*  0x92ca (U+901a) */
	C_KANJI_JIS_444D, /*  0x92cb (U+585a) */
	C_KANJI_JIS_444E, /*  0x92cc (U+6802) */
	C_KANJI_JIS_444F, /*  0x92cd (U+63b4) */
	C_KANJI_JIS_4450, /*  0x92ce (U+69fb) */
	C_KANJI_JIS_4451, /*  0x92cf (U+4f43) */
	C_KANJI_JIS_4452, /*  0x92d0 (U+6f2c) */
	C_KANJI_JIS_4453, /*  0x92d1 (U+67d8) */
	C_KANJI_JIS_4454, /*  0x92d2 (U+8fbb) */
	C_KANJI_JIS_4455, /*  0x92d3 (U+8526) */
	C_KANJI_JIS_4456, /*  0x92d4 (U+7db4) */
	C_KANJI_JIS_4457, /*  0x92d5 (U+9354) */
	C_KANJI_JIS_4458, /*  0x92d6 (U+693f) */
	C_KANJI_JIS_4459, /*  0x92d7 (U+6f70) */
	C_KANJI_JIS_445A, /*  0x92d8 (U+576a) */
	C_KANJI_JIS_445B, /*  0x92d9 (U+58f7) */
	C_KANJI_JIS_445C, /*  0x92da (U+5b2c) */
	C_KANJI_JIS_445D, /*  0x92db (U+7d2c) */
	C_KANJI_JIS_445E, /*  0x92dc (U+722a) */
	C_KANJI_JIS_445F, /*  0x92dd (U+540a) */
	C_KANJI_JIS_4460, /*  0x92de (U+91e3) */
	C_KANJI_JIS_4461, /*  0x92df (U+9db4) */
	C_KANJI_JIS_4462, /*  0x92e0 (U+4ead) */
	C_KANJI_JIS_4463, /*  0x92e1 (U+4f4e) */
	C_KANJI_JIS_4464, /*  0x92e2 (U+505c) */
	C_KANJI_JIS_4465, /*  0x92e3 (U+5075) */
	C_KANJI_JIS_4466, /*  0x92e4 (U+5243) */
	C_KANJI_JIS_4467, /*  0x92e5 (U+8c9e) */
	C_KANJI_JIS_4468, /*  0x92e6 (U+5448) */
	C_KANJI_JIS_4469, /*  0x92e7 (U+5824) */
	C_KANJI_JIS_446A, /*  0x92e8 (U+5b9a) */
	C_KANJI_JIS_446B, /*  0x92e9 (U+5e1d) */
	C_KANJI_JIS_446C, /*  0x92ea (U+5e95) */
	C_KANJI_JIS_446D, /*  0x92eb (U+5ead) */
	C_KANJI_JIS_446E, /*  0x92ec (U+5ef7) */
	C_KANJI_JIS_446F, /*  0x92ed (U+5f1f) */
	C_KANJI_JIS_4470, /*  0x92ee (U+608c) */
	C_KANJI_JIS_4471, /*  0x92ef (U+62b5) */
	C_KANJI_JIS_4472, /*  0x92f0 (U+633a) */
	C_KANJI_JIS_4473, /*  0x92f1 (U+63d0) */
	C_KANJI_JIS_4474, /*  0x92f2 (U+68af) */
	C_KANJI_JIS_4475, /*  0x92f3 (U+6c40) */
	C_KANJI_JIS_4476, /*  0x92f4 (U+7887) */
	C_KANJI_JIS_4477, /*  0x92f5 (U+798e) */
	C_KANJI_JIS_4478, /*  0x92f6 (U+7a0b) */
	C_KANJI_JIS_4479, /*  0x92f7 (U+7de0) */
	C_KANJI_JIS_447A, /*  0x92f8 (U+8247) */
	C_KANJI_JIS_447B, /*  0x92f9 (U+8a02) */
	C_KANJI_JIS_447C, /*  0x92fa (U+8ae6) */
	C_KANJI_JIS_447D, /*  0x92fb (U+8e44) */
	C_KANJI_JIS_447E, /*  0x92fc (U+9013) */
	0, /*  0x92fd */
	0, /*  0x92fe */
	0, /*  0x92ff */

	C_KANJI_JIS_4521, /*  0x9340 (U+90b8) */
	C_KANJI_JIS_4522, /*  0x9341 (U+912d) */
	C_KANJI_JIS_4523, /*  0x9342 (U+91d8) */
	C_KANJI_JIS_4524, /*  0x9343 (U+9f0e) */
	C_KANJI_JIS_4525, /*  0x9344 (U+6ce5) */
	C_KANJI_JIS_4526, /*  0x9345 (U+6458) */
	C_KANJI_JIS_4527, /*  0x9346 (U+64e2) */
	C_KANJI_JIS_4528, /*  0x9347 (U+6575) */
	C_KANJI_JIS_4529, /*  0x9348 (U+6ef4) */
	C_KANJI_JIS_452A, /*  0x9349 (U+7684) */
	C_KANJI_JIS_452B, /*  0x934a (U+7b1b) */
	C_KANJI_JIS_452C, /*  0x934b (U+9069) */
	C_KANJI_JIS_452D, /*  0x934c (U+93d1) */
	C_KANJI_JIS_452E, /*  0x934d (U+6eba) */
	C_KANJI_JIS_452F, /*  0x934e (U+54f2) */
	C_KANJI_JIS_4530, /*  0x934f (U+5fb9) */
	C_KANJI_JIS_4531, /*  0x9350 (U+64a4) */
	C_KANJI_JIS_4532, /*  0x9351 (U+8f4d) */
	C_KANJI_JIS_4533, /*  0x9352 (U+8fed) */
	C_KANJI_JIS_4534, /*  0x9353 (U+9244) */
	C_KANJI_JIS_4535, /*  0x9354 (U+5178) */
	C_KANJI_JIS_4536, /*  0x9355 (U+586b) */
	C_KANJI_JIS_4537, /*  0x9356 (U+5929) */
	C_KANJI_JIS_4538, /*  0x9357 (U+5c55) */
	C_KANJI_JIS_4539, /*  0x9358 (U+5e97) */
	C_KANJI_JIS_453A, /*  0x9359 (U+6dfb) */
	C_KANJI_JIS_453B, /*  0x935a (U+7e8f) */
	C_KANJI_JIS_453C, /*  0x935b (U+751c) */
	C_KANJI_JIS_453D, /*  0x935c (U+8cbc) */
	C_KANJI_JIS_453E, /*  0x935d (U+8ee2) */
	C_KANJI_JIS_453F, /*  0x935e (U+985b) */
	C_KANJI_JIS_4540, /*  0x935f (U+70b9) */
	C_KANJI_JIS_4541, /*  0x9360 (U+4f1d) */
	C_KANJI_JIS_4542, /*  0x9361 (U+6bbf) */
	C_KANJI_JIS_4543, /*  0x9362 (U+6fb1) */
	C_KANJI_JIS_4544, /*  0x9363 (U+7530) */
	C_KANJI_JIS_4545, /*  0x9364 (U+96fb) */
	C_KANJI_JIS_4546, /*  0x9365 (U+514e) */
	C_KANJI_JIS_4547, /*  0x9366 (U+5410) */
	C_KANJI_JIS_4548, /*  0x9367 (U+5835) */
	C_KANJI_JIS_4549, /*  0x9368 (U+5857) */
	C_KANJI_JIS_454A, /*  0x9369 (U+59ac) */
	C_KANJI_JIS_454B, /*  0x936a (U+5c60) */
	C_KANJI_JIS_454C, /*  0x936b (U+5f92) */
	C_KANJI_JIS_454D, /*  0x936c (U+6597) */
	C_KANJI_JIS_454E, /*  0x936d (U+675c) */
	C_KANJI_JIS_454F, /*  0x936e (U+6e21) */
	C_KANJI_JIS_4550, /*  0x936f (U+767b) */
	C_KANJI_JIS_4551, /*  0x9370 (U+83df) */
	C_KANJI_JIS_4552, /*  0x9371 (U+8ced) */
	C_KANJI_JIS_4553, /*  0x9372 (U+9014) */
	C_KANJI_JIS_4554, /*  0x9373 (U+90fd) */
	C_KANJI_JIS_4555, /*  0x9374 (U+934d) */
	C_KANJI_JIS_4556, /*  0x9375 (U+7825) */
	C_KANJI_JIS_4557, /*  0x9376 (U+783a) */
	C_KANJI_JIS_4558, /*  0x9377 (U+52aa) */
	C_KANJI_JIS_4559, /*  0x9378 (U+5ea6) */
	C_KANJI_JIS_455A, /*  0x9379 (U+571f) */
	C_KANJI_JIS_455B, /*  0x937a (U+5974) */
	C_KANJI_JIS_455C, /*  0x937b (U+6012) */
	C_KANJI_JIS_455D, /*  0x937c (U+5012) */
	C_KANJI_JIS_455E, /*  0x937d (U+515a) */
	C_KANJI_JIS_455F, /*  0x937e (U+51ac) */
	0, /*  0x937f */
	C_KANJI_JIS_4560, /*  0x9380 (U+51cd) */
	C_KANJI_JIS_4561, /*  0x9381 (U+5200) */
	C_KANJI_JIS_4562, /*  0x9382 (U+5510) */
	C_KANJI_JIS_4563, /*  0x9383 (U+5854) */
	C_KANJI_JIS_4564, /*  0x9384 (U+5858) */
	C_KANJI_JIS_4565, /*  0x9385 (U+5957) */
	C_KANJI_JIS_4566, /*  0x9386 (U+5b95) */
	C_KANJI_JIS_4567, /*  0x9387 (U+5cf6) */
	C_KANJI_JIS_4568, /*  0x9388 (U+5d8b) */
	C_KANJI_JIS_4569, /*  0x9389 (U+60bc) */
	C_KANJI_JIS_456A, /*  0x938a (U+6295) */
	C_KANJI_JIS_456B, /*  0x938b (U+642d) */
	C_KANJI_JIS_456C, /*  0x938c (U+6771) */
	C_KANJI_JIS_456D, /*  0x938d (U+6843) */
	C_KANJI_JIS_456E, /*  0x938e (U+68bc) */
	C_KANJI_JIS_456F, /*  0x938f (U+68df) */
	C_KANJI_JIS_4570, /*  0x9390 (U+76d7) */
	C_KANJI_JIS_4571, /*  0x9391 (U+6dd8) */
	C_KANJI_JIS_4572, /*  0x9392 (U+6e6f) */
	C_KANJI_JIS_4573, /*  0x9393 (U+6d9b) */
	C_KANJI_JIS_4574, /*  0x9394 (U+706f) */
	C_KANJI_JIS_4575, /*  0x9395 (U+71c8) */
	C_KANJI_JIS_4576, /*  0x9396 (U+5f53) */
	C_KANJI_JIS_4577, /*  0x9397 (U+75d8) */
	C_KANJI_JIS_4578, /*  0x9398 (U+7977) */
	C_KANJI_JIS_4579, /*  0x9399 (U+7b49) */
	C_KANJI_JIS_457A, /*  0x939a (U+7b54) */
	C_KANJI_JIS_457B, /*  0x939b (U+7b52) */
	C_KANJI_JIS_457C, /*  0x939c (U+7cd6) */
	C_KANJI_JIS_457D, /*  0x939d (U+7d71) */
	C_KANJI_JIS_457E, /*  0x939e (U+5230) */
	C_KANJI_JIS_4621, /*  0x939f (U+8463) */
	C_KANJI_JIS_4622, /*  0x93a0 (U+8569) */
	C_KANJI_JIS_4623, /*  0x93a1 (U+85e4) */
	C_KANJI_JIS_4624, /*  0x93a2 (U+8a0e) */
	C_KANJI_JIS_4625, /*  0x93a3 (U+8b04) */
	C_KANJI_JIS_4626, /*  0x93a4 (U+8c46) */
	C_KANJI_JIS_4627, /*  0x93a5 (U+8e0f) */
	C_KANJI_JIS_4628, /*  0x93a6 (U+9003) */
	C_KANJI_JIS_4629, /*  0x93a7 (U+900f) */
	C_KANJI_JIS_462A, /*  0x93a8 (U+9419) */
	C_KANJI_JIS_462B, /*  0x93a9 (U+9676) */
	C_KANJI_JIS_462C, /*  0x93aa (U+982d) */
	C_KANJI_JIS_462D, /*  0x93ab (U+9a30) */
	C_KANJI_JIS_462E, /*  0x93ac (U+95d8) */
	C_KANJI_JIS_462F, /*  0x93ad (U+50cd) */
	C_KANJI_JIS_4630, /*  0x93ae (U+52d5) */
	C_KANJI_JIS_4631, /*  0x93af (U+540c) */
	C_KANJI_JIS_4632, /*  0x93b0 (U+5802) */
	C_KANJI_JIS_4633, /*  0x93b1 (U+5c0e) */
	C_KANJI_JIS_4634, /*  0x93b2 (U+61a7) */
	C_KANJI_JIS_4635, /*  0x93b3 (U+649e) */
	C_KANJI_JIS_4636, /*  0x93b4 (U+6d1e) */
	C_KANJI_JIS_4637, /*  0x93b5 (U+77b3) */
	C_KANJI_JIS_4638, /*  0x93b6 (U+7ae5) */
	C_KANJI_JIS_4639, /*  0x93b7 (U+80f4) */
	C_KANJI_JIS_463A, /*  0x93b8 (U+8404) */
	C_KANJI_JIS_463B, /*  0x93b9 (U+9053) */
	C_KANJI_JIS_463C, /*  0x93ba (U+9285) */
	C_KANJI_JIS_463D, /*  0x93bb (U+5ce0) */
	C_KANJI_JIS_463E, /*  0x93bc (U+9d07) */
	C_KANJI_JIS_463F, /*  0x93bd (U+533f) */
	C_KANJI_JIS_4640, /*  0x93be (U+5f97) */
	C_KANJI_JIS_4641, /*  0x93bf (U+5fb3) */
	C_KANJI_JIS_4642, /*  0x93c0 (U+6d9c) */
	C_KANJI_JIS_4643, /*  0x93c1 (U+7279) */
	C_KANJI_JIS_4644, /*  0x93c2 (U+7763) */
	C_KANJI_JIS_4645, /*  0x93c3 (U+79bf) */
	C_KANJI_JIS_4646, /*  0x93c4 (U+7be4) */
	C_KANJI_JIS_4647, /*  0x93c5 (U+6bd2) */
	C_KANJI_JIS_4648, /*  0x93c6 (U+72ec) */
	C_KANJI_JIS_4649, /*  0x93c7 (U+8aad) */
	C_KANJI_JIS_464A, /*  0x93c8 (U+6803) */
	C_KANJI_JIS_464B, /*  0x93c9 (U+6a61) */
	C_KANJI_JIS_464C, /*  0x93ca (U+51f8) */
	C_KANJI_JIS_464D, /*  0x93cb (U+7a81) */
	C_KANJI_JIS_464E, /*  0x93cc (U+6934) */
	C_KANJI_JIS_464F, /*  0x93cd (U+5c4a) */
	C_KANJI_JIS_4650, /*  0x93ce (U+9cf6) */
	C_KANJI_JIS_4651, /*  0x93cf (U+82eb) */
	C_KANJI_JIS_4652, /*  0x93d0 (U+5bc5) */
	C_KANJI_JIS_4653, /*  0x93d1 (U+9149) */
	C_KANJI_JIS_4654, /*  0x93d2 (U+701e) */
	C_KANJI_JIS_4655, /*  0x93d3 (U+5678) */
	C_KANJI_JIS_4656, /*  0x93d4 (U+5c6f) */
	C_KANJI_JIS_4657, /*  0x93d5 (U+60c7) */
	C_KANJI_JIS_4658, /*  0x93d6 (U+6566) */
	C_KANJI_JIS_4659, /*  0x93d7 (U+6c8c) */
	C_KANJI_JIS_465A, /*  0x93d8 (U+8c5a) */
	C_KANJI_JIS_465B, /*  0x93d9 (U+9041) */
	C_KANJI_JIS_465C, /*  0x93da (U+9813) */
	C_KANJI_JIS_465D, /*  0x93db (U+5451) */
	C_KANJI_JIS_465E, /*  0x93dc (U+66c7) */
	C_KANJI_JIS_465F, /*  0x93dd (U+920d) */
	C_KANJI_JIS_4660, /*  0x93de (U+5948) */
	C_KANJI_JIS_4661, /*  0x93df (U+90a3) */
	C_KANJI_JIS_4662, /*  0x93e0 (U+5185) */
	C_KANJI_JIS_4663, /*  0x93e1 (U+4e4d) */
	C_KANJI_JIS_4664, /*  0x93e2 (U+51ea) */
	C_KANJI_JIS_4665, /*  0x93e3 (U+8599) */
	C_KANJI_JIS_4666, /*  0x93e4 (U+8b0e) */
	C_KANJI_JIS_4667, /*  0x93e5 (U+7058) */
	C_KANJI_JIS_4668, /*  0x93e6 (U+637a) */
	C_KANJI_JIS_4669, /*  0x93e7 (U+934b) */
	C_KANJI_JIS_466A, /*  0x93e8 (U+6962) */
	C_KANJI_JIS_466B, /*  0x93e9 (U+99b4) */
	C_KANJI_JIS_466C, /*  0x93ea (U+7e04) */
	C_KANJI_JIS_466D, /*  0x93eb (U+7577) */
	C_KANJI_JIS_466E, /*  0x93ec (U+5357) */
	C_KANJI_JIS_466F, /*  0x93ed (U+6960) */
	C_KANJI_JIS_4670, /*  0x93ee (U+8edf) */
	C_KANJI_JIS_4671, /*  0x93ef (U+96e3) */
	C_KANJI_JIS_4672, /*  0x93f0 (U+6c5d) */
	C_KANJI_JIS_4673, /*  0x93f1 (U+4e8c) */
	C_KANJI_JIS_4674, /*  0x93f2 (U+5c3c) */
	C_KANJI_JIS_4675, /*  0x93f3 (U+5f10) */
	C_KANJI_JIS_4676, /*  0x93f4 (U+8fe9) */
	C_KANJI_JIS_4677, /*  0x93f5 (U+5302) */
	C_KANJI_JIS_4678, /*  0x93f6 (U+8cd1) */
	C_KANJI_JIS_4679, /*  0x93f7 (U+8089) */
	C_KANJI_JIS_467A, /*  0x93f8 (U+8679) */
	C_KANJI_JIS_467B, /*  0x93f9 (U+5eff) */
	C_KANJI_JIS_467C, /*  0x93fa (U+65e5) */
	C_KANJI_JIS_467D, /*  0x93fb (U+4e73) */
	C_KANJI_JIS_467E, /*  0x93fc (U+5165) */
	0, /*  0x93fd */
	0, /*  0x93fe */
	0, /*  0x93ff */

	C_KANJI_JIS_4721, /*  0x9440 (U+5982) */
	C_KANJI_JIS_4722, /*  0x9441 (U+5c3f) */
	C_KANJI_JIS_4723, /*  0x9442 (U+97ee) */
	C_KANJI_JIS_4724, /*  0x9443 (U+4efb) */
	C_KANJI_JIS_4725, /*  0x9444 (U+598a) */
	C_KANJI_JIS_4726, /*  0x9445 (U+5fcd) */
	C_KANJI_JIS_4727, /*  0x9446 (U+8a8d) */
	C_KANJI_JIS_4728, /*  0x9447 (U+6fe1) */
	C_KANJI_JIS_4729, /*  0x9448 (U+79b0) */
	C_KANJI_JIS_472A, /*  0x9449 (U+7962) */
	C_KANJI_JIS_472B, /*  0x944a (U+5be7) */
	C_KANJI_JIS_472C, /*  0x944b (U+8471) */
	C_KANJI_JIS_472D, /*  0x944c (U+732b) */
	C_KANJI_JIS_472E, /*  0x944d (U+71b1) */
	C_KANJI_JIS_472F, /*  0x944e (U+5e74) */
	C_KANJI_JIS_4730, /*  0x944f (U+5ff5) */
	C_KANJI_JIS_4731, /*  0x9450 (U+637b) */
	C_KANJI_JIS_4732, /*  0x9451 (U+649a) */
	C_KANJI_JIS_4733, /*  0x9452 (U+71c3) */
	C_KANJI_JIS_4734, /*  0x9453 (U+7c98) */
	C_KANJI_JIS_4735, /*  0x9454 (U+4e43) */
	C_KANJI_JIS_4736, /*  0x9455 (U+5efc) */
	C_KANJI_JIS_4737, /*  0x9456 (U+4e4b) */
	C_KANJI_JIS_4738, /*  0x9457 (U+57dc) */
	C_KANJI_JIS_4739, /*  0x9458 (U+56a2) */
	C_KANJI_JIS_473A, /*  0x9459 (U+60a9) */
	C_KANJI_JIS_473B, /*  0x945a (U+6fc3) */
	C_KANJI_JIS_473C, /*  0x945b (U+7d0d) */
	C_KANJI_JIS_473D, /*  0x945c (U+80fd) */
	C_KANJI_JIS_473E, /*  0x945d (U+8133) */
	C_KANJI_JIS_473F, /*  0x945e (U+81bf) */
	C_KANJI_JIS_4740, /*  0x945f (U+8fb2) */
	C_KANJI_JIS_4741, /*  0x9460 (U+8997) */
	C_KANJI_JIS_4742, /*  0x9461 (U+86a4) */
	C_KANJI_JIS_4743, /*  0x9462 (U+5df4) */
	C_KANJI_JIS_4744, /*  0x9463 (U+628a) */
	C_KANJI_JIS_4745, /*  0x9464 (U+64ad) */
	C_KANJI_JIS_4746, /*  0x9465 (U+8987) */
	C_KANJI_JIS_4747, /*  0x9466 (U+6777) */
	C_KANJI_JIS_4748, /*  0x9467 (U+6ce2) */
	C_KANJI_JIS_4749, /*  0x9468 (U+6d3e) */
	C_KANJI_JIS_474A, /*  0x9469 (U+7436) */
	C_KANJI_JIS_474B, /*  0x946a (U+7834) */
	C_KANJI_JIS_474C, /*  0x946b (U+5a46) */
	C_KANJI_JIS_474D, /*  0x946c (U+7f75) */
	C_KANJI_JIS_474E, /*  0x946d (U+82ad) */
	C_KANJI_JIS_474F, /*  0x946e (U+99ac) */
	C_KANJI_JIS_4750, /*  0x946f (U+4ff3) */
	C_KANJI_JIS_4751, /*  0x9470 (U+5ec3) */
	C_KANJI_JIS_4752, /*  0x9471 (U+62dd) */
	C_KANJI_JIS_4753, /*  0x9472 (U+6392) */
	C_KANJI_JIS_4754, /*  0x9473 (U+6557) */
	C_KANJI_JIS_4755, /*  0x9474 (U+676f) */
	C_KANJI_JIS_4756, /*  0x9475 (U+76c3) */
	C_KANJI_JIS_4757, /*  0x9476 (U+724c) */
	C_KANJI_JIS_4758, /*  0x9477 (U+80cc) */
	C_KANJI_JIS_4759, /*  0x9478 (U+80ba) */
	C_KANJI_JIS_475A, /*  0x9479 (U+8f29) */
	C_KANJI_JIS_475B, /*  0x947a (U+914d) */
	C_KANJI_JIS_475C, /*  0x947b (U+500d) */
	C_KANJI_JIS_475D, /*  0x947c (U+57f9) */
	C_KANJI_JIS_475E, /*  0x947d (U+5a92) */
	C_KANJI_JIS_475F, /*  0x947e (U+6885) */
	0, /*  0x947f */
	C_KANJI_JIS_4760, /*  0x9480 (U+6973) */
	C_KANJI_JIS_4761, /*  0x9481 (U+7164) */
	C_KANJI_JIS_4762, /*  0x9482 (U+72fd) */
	C_KANJI_JIS_4763, /*  0x9483 (U+8cb7) */
	C_KANJI_JIS_4764, /*  0x9484 (U+58f2) */
	C_KANJI_JIS_4765, /*  0x9485 (U+8ce0) */
	C_KANJI_JIS_4766, /*  0x9486 (U+966a) */
	C_KANJI_JIS_4767, /*  0x9487 (U+9019) */
	C_KANJI_JIS_4768, /*  0x9488 (U+877f) */
	C_KANJI_JIS_4769, /*  0x9489 (U+79e4) */
	C_KANJI_JIS_476A, /*  0x948a (U+77e7) */
	C_KANJI_JIS_476B, /*  0x948b (U+8429) */
	C_KANJI_JIS_476C, /*  0x948c (U+4f2f) */
	C_KANJI_JIS_476D, /*  0x948d (U+5265) */
	C_KANJI_JIS_476E, /*  0x948e (U+535a) */
	C_KANJI_JIS_476F, /*  0x948f (U+62cd) */
	C_KANJI_JIS_4770, /*  0x9490 (U+67cf) */
	C_KANJI_JIS_4771, /*  0x9491 (U+6cca) */
	C_KANJI_JIS_4772, /*  0x9492 (U+767d) */
	C_KANJI_JIS_4773, /*  0x9493 (U+7b94) */
	C_KANJI_JIS_4774, /*  0x9494 (U+7c95) */
	C_KANJI_JIS_4775, /*  0x9495 (U+8236) */
	C_KANJI_JIS_4776, /*  0x9496 (U+8584) */
	C_KANJI_JIS_4777, /*  0x9497 (U+8feb) */
	C_KANJI_JIS_4778, /*  0x9498 (U+66dd) */
	C_KANJI_JIS_4779, /*  0x9499 (U+6f20) */
	C_KANJI_JIS_477A, /*  0x949a (U+7206) */
	C_KANJI_JIS_477B, /*  0x949b (U+7e1b) */
	C_KANJI_JIS_477C, /*  0x949c (U+83ab) */
	C_KANJI_JIS_477D, /*  0x949d (U+99c1) */
	C_KANJI_JIS_477E, /*  0x949e (U+9ea6) */
	C_KANJI_JIS_4821, /*  0x949f (U+51fd) */
	C_KANJI_JIS_4822, /*  0x94a0 (U+7bb1) */
	C_KANJI_JIS_4823, /*  0x94a1 (U+7872) */
	C_KANJI_JIS_4824, /*  0x94a2 (U+7bb8) */
	C_KANJI_JIS_4825, /*  0x94a3 (U+8087) */
	C_KANJI_JIS_4826, /*  0x94a4 (U+7b48) */
	C_KANJI_JIS_4827, /*  0x94a5 (U+6ae8) */
	C_KANJI_JIS_4828, /*  0x94a6 (U+5e61) */
	C_KANJI_JIS_4829, /*  0x94a7 (U+808c) */
	C_KANJI_JIS_482A, /*  0x94a8 (U+7551) */
	C_KANJI_JIS_482B, /*  0x94a9 (U+7560) */
	C_KANJI_JIS_482C, /*  0x94aa (U+516b) */
	C_KANJI_JIS_482D, /*  0x94ab (U+9262) */
	C_KANJI_JIS_482E, /*  0x94ac (U+6e8c) */
	C_KANJI_JIS_482F, /*  0x94ad (U+767a) */
	C_KANJI_JIS_4830, /*  0x94ae (U+9197) */
	C_KANJI_JIS_4831, /*  0x94af (U+9aea) */
	C_KANJI_JIS_4832, /*  0x94b0 (U+4f10) */
	C_KANJI_JIS_4833, /*  0x94b1 (U+7f70) */
	C_KANJI_JIS_4834, /*  0x94b2 (U+629c) */
	C_KANJI_JIS_4835, /*  0x94b3 (U+7b4f) */
	C_KANJI_JIS_4836, /*  0x94b4 (U+95a5) */
	C_KANJI_JIS_4837, /*  0x94b5 (U+9ce9) */
	C_KANJI_JIS_4838, /*  0x94b6 (U+567a) */
	C_KANJI_JIS_4839, /*  0x94b7 (U+5859) */
	C_KANJI_JIS_483A, /*  0x94b8 (U+86e4) */
	C_KANJI_JIS_483B, /*  0x94b9 (U+96bc) */
	C_KANJI_JIS_483C, /*  0x94ba (U+4f34) */
	C_KANJI_JIS_483D, /*  0x94bb (U+5224) */
	C_KANJI_JIS_483E, /*  0x94bc (U+534a) */
	C_KANJI_JIS_483F, /*  0x94bd (U+53cd) */
	C_KANJI_JIS_4840, /*  0x94be (U+53db) */
	C_KANJI_JIS_4841, /*  0x94bf (U+5e06) */
	C_KANJI_JIS_4842, /*  0x94c0 (U+642c) */
	C_KANJI_JIS_4843, /*  0x94c1 (U+6591) */
	C_KANJI_JIS_4844, /*  0x94c2 (U+677f) */
	C_KANJI_JIS_4845, /*  0x94c3 (U+6c3e) */
	C_KANJI_JIS_4846, /*  0x94c4 (U+6c4e) */
	C_KANJI_JIS_4847, /*  0x94c5 (U+7248) */
	C_KANJI_JIS_4848, /*  0x94c6 (U+72af) */
	C_KANJI_JIS_4849, /*  0x94c7 (U+73ed) */
	C_KANJI_JIS_484A, /*  0x94c8 (U+7554) */
	C_KANJI_JIS_484B, /*  0x94c9 (U+7e41) */
	C_KANJI_JIS_484C, /*  0x94ca (U+822c) */
	C_KANJI_JIS_484D, /*  0x94cb (U+85e9) */
	C_KANJI_JIS_484E, /*  0x94cc (U+8ca9) */
	C_KANJI_JIS_484F, /*  0x94cd (U+7bc4) */
	C_KANJI_JIS_4850, /*  0x94ce (U+91c6) */
	C_KANJI_JIS_4851, /*  0x94cf (U+7169) */
	C_KANJI_JIS_4852, /*  0x94d0 (U+9812) */
	C_KANJI_JIS_4853, /*  0x94d1 (U+98ef) */
	C_KANJI_JIS_4854, /*  0x94d2 (U+633d) */
	C_KANJI_JIS_4855, /*  0x94d3 (U+6669) */
	C_KANJI_JIS_4856, /*  0x94d4 (U+756a) */
	C_KANJI_JIS_4857, /*  0x94d5 (U+76e4) */
	C_KANJI_JIS_4858, /*  0x94d6 (U+78d0) */
	C_KANJI_JIS_4859, /*  0x94d7 (U+8543) */
	C_KANJI_JIS_485A, /*  0x94d8 (U+86ee) */
	C_KANJI_JIS_485B, /*  0x94d9 (U+532a) */
	C_KANJI_JIS_485C, /*  0x94da (U+5351) */
	C_KANJI_JIS_485D, /*  0x94db (U+5426) */
	C_KANJI_JIS_485E, /*  0x94dc (U+5983) */
	C_KANJI_JIS_485F, /*  0x94dd (U+5e87) */
	C_KANJI_JIS_4860, /*  0x94de (U+5f7c) */
	C_KANJI_JIS_4861, /*  0x94df (U+60b2) */
	C_KANJI_JIS_4862, /*  0x94e0 (U+6249) */
	C_KANJI_JIS_4863, /*  0x94e1 (U+6279) */
	C_KANJI_JIS_4864, /*  0x94e2 (U+62ab) */
	C_KANJI_JIS_4865, /*  0x94e3 (U+6590) */
	C_KANJI_JIS_4866, /*  0x94e4 (U+6bd4) */
	C_KANJI_JIS_4867, /*  0x94e5 (U+6ccc) */
	C_KANJI_JIS_4868, /*  0x94e6 (U+75b2) */
	C_KANJI_JIS_4869, /*  0x94e7 (U+76ae) */
	C_KANJI_JIS_486A, /*  0x94e8 (U+7891) */
	C_KANJI_JIS_486B, /*  0x94e9 (U+79d8) */
	C_KANJI_JIS_486C, /*  0x94ea (U+7dcb) */
	C_KANJI_JIS_486D, /*  0x94eb (U+7f77) */
	C_KANJI_JIS_486E, /*  0x94ec (U+80a5) */
	C_KANJI_JIS_486F, /*  0x94ed (U+88ab) */
	C_KANJI_JIS_4870, /*  0x94ee (U+8ab9) */
	C_KANJI_JIS_4871, /*  0x94ef (U+8cbb) */
	C_KANJI_JIS_4872, /*  0x94f0 (U+907f) */
	C_KANJI_JIS_4873, /*  0x94f1 (U+975e) */
	C_KANJI_JIS_4874, /*  0x94f2 (U+98db) */
	C_KANJI_JIS_4875, /*  0x94f3 (U+6a0b) */
	C_KANJI_JIS_4876, /*  0x94f4 (U+7c38) */
	C_KANJI_JIS_4877, /*  0x94f5 (U+5099) */
	C_KANJI_JIS_4878, /*  0x94f6 (U+5c3e) */
	C_KANJI_JIS_4879, /*  0x94f7 (U+5fae) */
	C_KANJI_JIS_487A, /*  0x94f8 (U+6787) */
	C_KANJI_JIS_487B, /*  0x94f9 (U+6bd8) */
	C_KANJI_JIS_487C, /*  0x94fa (U+7435) */
	C_KANJI_JIS_487D, /*  0x94fb (U+7709) */
	C_KANJI_JIS_487E, /*  0x94fc (U+7f8e) */
	0, /*  0x94fd */
	0, /*  0x94fe */
	0, /*  0x94ff */

	C_KANJI_JIS_4921, /*  0x9540 (U+9f3b) */
	C_KANJI_JIS_4922, /*  0x9541 (U+67ca) */
	C_KANJI_JIS_4923, /*  0x9542 (U+7a17) */
	C_KANJI_JIS_4924, /*  0x9543 (U+5339) */
	C_KANJI_JIS_4925, /*  0x9544 (U+758b) */
	C_KANJI_JIS_4926, /*  0x9545 (U+9aed) */
	C_KANJI_JIS_4927, /*  0x9546 (U+5f66) */
	C_KANJI_JIS_4928, /*  0x9547 (U+819d) */
	C_KANJI_JIS_4929, /*  0x9548 (U+83f1) */
	C_KANJI_JIS_492A, /*  0x9549 (U+8098) */
	C_KANJI_JIS_492B, /*  0x954a (U+5f3c) */
	C_KANJI_JIS_492C, /*  0x954b (U+5fc5) */
	C_KANJI_JIS_492D, /*  0x954c (U+7562) */
	C_KANJI_JIS_492E, /*  0x954d (U+7b46) */
	C_KANJI_JIS_492F, /*  0x954e (U+903c) */
	C_KANJI_JIS_4930, /*  0x954f (U+6867) */
	C_KANJI_JIS_4931, /*  0x9550 (U+59eb) */
	C_KANJI_JIS_4932, /*  0x9551 (U+5a9b) */
	C_KANJI_JIS_4933, /*  0x9552 (U+7d10) */
	C_KANJI_JIS_4934, /*  0x9553 (U+767e) */
	C_KANJI_JIS_4935, /*  0x9554 (U+8b2c) */
	C_KANJI_JIS_4936, /*  0x9555 (U+4ff5) */
	C_KANJI_JIS_4937, /*  0x9556 (U+5f6a) */
	C_KANJI_JIS_4938, /*  0x9557 (U+6a19) */
	C_KANJI_JIS_4939, /*  0x9558 (U+6c37) */
	C_KANJI_JIS_493A, /*  0x9559 (U+6f02) */
	C_KANJI_JIS_493B, /*  0x955a (U+74e2) */
	C_KANJI_JIS_493C, /*  0x955b (U+7968) */
	C_KANJI_JIS_493D, /*  0x955c (U+8868) */
	C_KANJI_JIS_493E, /*  0x955d (U+8a55) */
	C_KANJI_JIS_493F, /*  0x955e (U+8c79) */
	C_KANJI_JIS_4940, /*  0x955f (U+5edf) */
	C_KANJI_JIS_4941, /*  0x9560 (U+63cf) */
	C_KANJI_JIS_4942, /*  0x9561 (U+75c5) */
	C_KANJI_JIS_4943, /*  0x9562 (U+79d2) */
	C_KANJI_JIS_4944, /*  0x9563 (U+82d7) */
	C_KANJI_JIS_4945, /*  0x9564 (U+9328) */
	C_KANJI_JIS_4946, /*  0x9565 (U+92f2) */
	C_KANJI_JIS_4947, /*  0x9566 (U+849c) */
	C_KANJI_JIS_4948, /*  0x9567 (U+86ed) */
	C_KANJI_JIS_4949, /*  0x9568 (U+9c2d) */
	C_KANJI_JIS_494A, /*  0x9569 (U+54c1) */
	C_KANJI_JIS_494B, /*  0x956a (U+5f6c) */
	C_KANJI_JIS_494C, /*  0x956b (U+658c) */
	C_KANJI_JIS_494D, /*  0x956c (U+6d5c) */
	C_KANJI_JIS_494E, /*  0x956d (U+7015) */
	C_KANJI_JIS_494F, /*  0x956e (U+8ca7) */
	C_KANJI_JIS_4950, /*  0x956f (U+8cd3) */
	C_KANJI_JIS_4951, /*  0x9570 (U+983b) */
	C_KANJI_JIS_4952, /*  0x9571 (U+654f) */
	C_KANJI_JIS_4953, /*  0x9572 (U+74f6) */
	C_KANJI_JIS_4954, /*  0x9573 (U+4e0d) */
	C_KANJI_JIS_4955, /*  0x9574 (U+4ed8) */
	C_KANJI_JIS_4956, /*  0x9575 (U+57e0) */
	C_KANJI_JIS_4957, /*  0x9576 (U+592b) */
	C_KANJI_JIS_4958, /*  0x9577 (U+5a66) */
	C_KANJI_JIS_4959, /*  0x9578 (U+5bcc) */
	C_KANJI_JIS_495A, /*  0x9579 (U+51a8) */
	C_KANJI_JIS_495B, /*  0x957a (U+5e03) */
	C_KANJI_JIS_495C, /*  0x957b (U+5e9c) */
	C_KANJI_JIS_495D, /*  0x957c (U+6016) */
	C_KANJI_JIS_495E, /*  0x957d (U+6276) */
	C_KANJI_JIS_495F, /*  0x957e (U+6577) */
	0, /*  0x957f */
	C_KANJI_JIS_4960, /*  0x9580 (U+65a7) */
	C_KANJI_JIS_4961, /*  0x9581 (U+666e) */
	C_KANJI_JIS_4962, /*  0x9582 (U+6d6e) */
	C_KANJI_JIS_4963, /*  0x9583 (U+7236) */
	C_KANJI_JIS_4964, /*  0x9584 (U+7b26) */
	C_KANJI_JIS_4965, /*  0x9585 (U+8150) */
	C_KANJI_JIS_4966, /*  0x9586 (U+819a) */
	C_KANJI_JIS_4967, /*  0x9587 (U+8299) */
	C_KANJI_JIS_4968, /*  0x9588 (U+8b5c) */
	C_KANJI_JIS_4969, /*  0x9589 (U+8ca0) */
	C_KANJI_JIS_496A, /*  0x958a (U+8ce6) */
	C_KANJI_JIS_496B, /*  0x958b (U+8d74) */
	C_KANJI_JIS_496C, /*  0x958c (U+961c) */
	C_KANJI_JIS_496D, /*  0x958d (U+9644) */
	C_KANJI_JIS_496E, /*  0x958e (U+4fae) */
	C_KANJI_JIS_496F, /*  0x958f (U+64ab) */
	C_KANJI_JIS_4970, /*  0x9590 (U+6b66) */
	C_KANJI_JIS_4971, /*  0x9591 (U+821e) */
	C_KANJI_JIS_4972, /*  0x9592 (U+8461) */
	C_KANJI_JIS_4973, /*  0x9593 (U+856a) */
	C_KANJI_JIS_4974, /*  0x9594 (U+90e8) */
	C_KANJI_JIS_4975, /*  0x9595 (U+5c01) */
	C_KANJI_JIS_4976, /*  0x9596 (U+6953) */
	C_KANJI_JIS_4977, /*  0x9597 (U+98a8) */
	C_KANJI_JIS_4978, /*  0x9598 (U+847a) */
	C_KANJI_JIS_4979, /*  0x9599 (U+8557) */
	C_KANJI_JIS_497A, /*  0x959a (U+4f0f) */
	C_KANJI_JIS_497B, /*  0x959b (U+526f) */
	C_KANJI_JIS_497C, /*  0x959c (U+5fa9) */
	C_KANJI_JIS_497D, /*  0x959d (U+5e45) */
	C_KANJI_JIS_497E, /*  0x959e (U+670d) */
	C_KANJI_JIS_4A21, /*  0x959f (U+798f) */
	C_KANJI_JIS_4A22, /*  0x95a0 (U+8179) */
	C_KANJI_JIS_4A23, /*  0x95a1 (U+8907) */
	C_KANJI_JIS_4A24, /*  0x95a2 (U+8986) */
	C_KANJI_JIS_4A25, /*  0x95a3 (U+6df5) */
	C_KANJI_JIS_4A26, /*  0x95a4 (U+5f17) */
	C_KANJI_JIS_4A27, /*  0x95a5 (U+6255) */
	C_KANJI_JIS_4A28, /*  0x95a6 (U+6cb8) */
	C_KANJI_JIS_4A29, /*  0x95a7 (U+4ecf) */
	C_KANJI_JIS_4A2A, /*  0x95a8 (U+7269) */
	C_KANJI_JIS_4A2B, /*  0x95a9 (U+9b92) */
	C_KANJI_JIS_4A2C, /*  0x95aa (U+5206) */
	C_KANJI_JIS_4A2D, /*  0x95ab (U+543b) */
	C_KANJI_JIS_4A2E, /*  0x95ac (U+5674) */
	C_KANJI_JIS_4A2F, /*  0x95ad (U+58b3) */
	C_KANJI_JIS_4A30, /*  0x95ae (U+61a4) */
	C_KANJI_JIS_4A31, /*  0x95af (U+626e) */
	C_KANJI_JIS_4A32, /*  0x95b0 (U+711a) */
	C_KANJI_JIS_4A33, /*  0x95b1 (U+596e) */
	C_KANJI_JIS_4A34, /*  0x95b2 (U+7c89) */
	C_KANJI_JIS_4A35, /*  0x95b3 (U+7cde) */
	C_KANJI_JIS_4A36, /*  0x95b4 (U+7d1b) */
	C_KANJI_JIS_4A37, /*  0x95b5 (U+96f0) */
	C_KANJI_JIS_4A38, /*  0x95b6 (U+6587) */
	C_KANJI_JIS_4A39, /*  0x95b7 (U+805e) */
	C_KANJI_JIS_4A3A, /*  0x95b8 (U+4e19) */
	C_KANJI_JIS_4A3B, /*  0x95b9 (U+4f75) */
	C_KANJI_JIS_4A3C, /*  0x95ba (U+5175) */
	C_KANJI_JIS_4A3D, /*  0x95bb (U+5840) */
	C_KANJI_JIS_4A3E, /*  0x95bc (U+5e63) */
	C_KANJI_JIS_4A3F, /*  0x95bd (U+5e73) */
	C_KANJI_JIS_4A40, /*  0x95be (U+5f0a) */
	C_KANJI_JIS_4A41, /*  0x95bf (U+67c4) */
	C_KANJI_JIS_4A42, /*  0x95c0 (U+4e26) */
	C_KANJI_JIS_4A43, /*  0x95c1 (U+853d) */
	C_KANJI_JIS_4A44, /*  0x95c2 (U+9589) */
	C_KANJI_JIS_4A45, /*  0x95c3 (U+965b) */
	C_KANJI_JIS_4A46, /*  0x95c4 (U+7c73) */
	C_KANJI_JIS_4A47, /*  0x95c5 (U+9801) */
	C_KANJI_JIS_4A48, /*  0x95c6 (U+50fb) */
	C_KANJI_JIS_4A49, /*  0x95c7 (U+58c1) */
	C_KANJI_JIS_4A4A, /*  0x95c8 (U+7656) */
	C_KANJI_JIS_4A4B, /*  0x95c9 (U+78a7) */
	C_KANJI_JIS_4A4C, /*  0x95ca (U+5225) */
	C_KANJI_JIS_4A4D, /*  0x95cb (U+77a5) */
	C_KANJI_JIS_4A4E, /*  0x95cc (U+8511) */
	C_KANJI_JIS_4A4F, /*  0x95cd (U+7b86) */
	C_KANJI_JIS_4A50, /*  0x95ce (U+504f) */
	C_KANJI_JIS_4A51, /*  0x95cf (U+5909) */
	C_KANJI_JIS_4A52, /*  0x95d0 (U+7247) */
	C_KANJI_JIS_4A53, /*  0x95d1 (U+7bc7) */
	C_KANJI_JIS_4A54, /*  0x95d2 (U+7de8) */
	C_KANJI_JIS_4A55, /*  0x95d3 (U+8fba) */
	C_KANJI_JIS_4A56, /*  0x95d4 (U+8fd4) */
	C_KANJI_JIS_4A57, /*  0x95d5 (U+904d) */
	C_KANJI_JIS_4A58, /*  0x95d6 (U+4fbf) */
	C_KANJI_JIS_4A59, /*  0x95d7 (U+52c9) */
	C_KANJI_JIS_4A5A, /*  0x95d8 (U+5a29) */
	C_KANJI_JIS_4A5B, /*  0x95d9 (U+5f01) */
	C_KANJI_JIS_4A5C, /*  0x95da (U+97ad) */
	C_KANJI_JIS_4A5D, /*  0x95db (U+4fdd) */
	C_KANJI_JIS_4A5E, /*  0x95dc (U+8217) */
	C_KANJI_JIS_4A5F, /*  0x95dd (U+92ea) */
	C_KANJI_JIS_4A60, /*  0x95de (U+5703) */
	C_KANJI_JIS_4A61, /*  0x95df (U+6355) */
	C_KANJI_JIS_4A62, /*  0x95e0 (U+6b69) */
	C_KANJI_JIS_4A63, /*  0x95e1 (U+752b) */
	C_KANJI_JIS_4A64, /*  0x95e2 (U+88dc) */
	C_KANJI_JIS_4A65, /*  0x95e3 (U+8f14) */
	C_KANJI_JIS_4A66, /*  0x95e4 (U+7a42) */
	C_KANJI_JIS_4A67, /*  0x95e5 (U+52df) */
	C_KANJI_JIS_4A68, /*  0x95e6 (U+5893) */
	C_KANJI_JIS_4A69, /*  0x95e7 (U+6155) */
	C_KANJI_JIS_4A6A, /*  0x95e8 (U+620a) */
	C_KANJI_JIS_4A6B, /*  0x95e9 (U+66ae) */
	C_KANJI_JIS_4A6C, /*  0x95ea (U+6bcd) */
	C_KANJI_JIS_4A6D, /*  0x95eb (U+7c3f) */
	C_KANJI_JIS_4A6E, /*  0x95ec (U+83e9) */
	C_KANJI_JIS_4A6F, /*  0x95ed (U+5023) */
	C_KANJI_JIS_4A70, /*  0x95ee (U+4ff8) */
	C_KANJI_JIS_4A71, /*  0x95ef (U+5305) */
	C_KANJI_JIS_4A72, /*  0x95f0 (U+5446) */
	C_KANJI_JIS_4A73, /*  0x95f1 (U+5831) */
	C_KANJI_JIS_4A74, /*  0x95f2 (U+5949) */
	C_KANJI_JIS_4A75, /*  0x95f3 (U+5b9d) */
	C_KANJI_JIS_4A76, /*  0x95f4 (U+5cf0) */
	C_KANJI_JIS_4A77, /*  0x95f5 (U+5cef) */
	C_KANJI_JIS_4A78, /*  0x95f6 (U+5d29) */
	C_KANJI_JIS_4A79, /*  0x95f7 (U+5e96) */
	C_KANJI_JIS_4A7A, /*  0x95f8 (U+62b1) */
	C_KANJI_JIS_4A7B, /*  0x95f9 (U+6367) */
	C_KANJI_JIS_4A7C, /*  0x95fa (U+653e) */
	C_KANJI_JIS_4A7D, /*  0x95fb (U+65b9) */
	C_KANJI_JIS_4A7E, /*  0x95fc (U+670b) */
	0, /*  0x95fd */
	0, /*  0x95fe */
	0, /*  0x95ff */

	C_KANJI_JIS_4B21, /*  0x9640 (U+6cd5) */
	C_KANJI_JIS_4B22, /*  0x9641 (U+6ce1) */
	C_KANJI_JIS_4B23, /*  0x9642 (U+70f9) */
	C_KANJI_JIS_4B24, /*  0x9643 (U+7832) */
	C_KANJI_JIS_4B25, /*  0x9644 (U+7e2b) */
	C_KANJI_JIS_4B26, /*  0x9645 (U+80de) */
	C_KANJI_JIS_4B27, /*  0x9646 (U+82b3) */
	C_KANJI_JIS_4B28, /*  0x9647 (U+840c) */
	C_KANJI_JIS_4B29, /*  0x9648 (U+84ec) */
	C_KANJI_JIS_4B2A, /*  0x9649 (U+8702) */
	C_KANJI_JIS_4B2B, /*  0x964a (U+8912) */
	C_KANJI_JIS_4B2C, /*  0x964b (U+8a2a) */
	C_KANJI_JIS_4B2D, /*  0x964c (U+8c4a) */
	C_KANJI_JIS_4B2E, /*  0x964d (U+90a6) */
	C_KANJI_JIS_4B2F, /*  0x964e (U+92d2) */
	C_KANJI_JIS_4B30, /*  0x964f (U+98fd) */
	C_KANJI_JIS_4B31, /*  0x9650 (U+9cf3) */
	C_KANJI_JIS_4B32, /*  0x9651 (U+9d6c) */
	C_KANJI_JIS_4B33, /*  0x9652 (U+4e4f) */
	C_KANJI_JIS_4B34, /*  0x9653 (U+4ea1) */
	C_KANJI_JIS_4B35, /*  0x9654 (U+508d) */
	C_KANJI_JIS_4B36, /*  0x9655 (U+5256) */
	C_KANJI_JIS_4B37, /*  0x9656 (U+574a) */
	C_KANJI_JIS_4B38, /*  0x9657 (U+59a8) */
	C_KANJI_JIS_4B39, /*  0x9658 (U+5e3d) */
	C_KANJI_JIS_4B3A, /*  0x9659 (U+5fd8) */
	C_KANJI_JIS_4B3B, /*  0x965a (U+5fd9) */
	C_KANJI_JIS_4B3C, /*  0x965b (U+623f) */
	C_KANJI_JIS_4B3D, /*  0x965c (U+66b4) */
	C_KANJI_JIS_4B3E, /*  0x965d (U+671b) */
	C_KANJI_JIS_4B3F, /*  0x965e (U+67d0) */
	C_KANJI_JIS_4B40, /*  0x965f (U+68d2) */
	C_KANJI_JIS_4B41, /*  0x9660 (U+5192) */
	C_KANJI_JIS_4B42, /*  0x9661 (U+7d21) */
	C_KANJI_JIS_4B43, /*  0x9662 (U+80aa) */
	C_KANJI_JIS_4B44, /*  0x9663 (U+81a8) */
	C_KANJI_JIS_4B45, /*  0x9664 (U+8b00) */
	C_KANJI_JIS_4B46, /*  0x9665 (U+8c8c) */
	C_KANJI_JIS_4B47, /*  0x9666 (U+8cbf) */
	C_KANJI_JIS_4B48, /*  0x9667 (U+927e) */
	C_KANJI_JIS_4B49, /*  0x9668 (U+9632) */
	C_KANJI_JIS_4B4A, /*  0x9669 (U+5420) */
	C_KANJI_JIS_4B4B, /*  0x966a (U+982c) */
	C_KANJI_JIS_4B4C, /*  0x966b (U+5317) */
	C_KANJI_JIS_4B4D, /*  0x966c (U+50d5) */
	C_KANJI_JIS_4B4E, /*  0x966d (U+535c) */
	C_KANJI_JIS_4B4F, /*  0x966e (U+58a8) */
	C_KANJI_JIS_4B50, /*  0x966f (U+64b2) */
	C_KANJI_JIS_4B51, /*  0x9670 (U+6734) */
	C_KANJI_JIS_4B52, /*  0x9671 (U+7267) */
	C_KANJI_JIS_4B53, /*  0x9672 (U+7766) */
	C_KANJI_JIS_4B54, /*  0x9673 (U+7a46) */
	C_KANJI_JIS_4B55, /*  0x9674 (U+91e6) */
	C_KANJI_JIS_4B56, /*  0x9675 (U+52c3) */
	C_KANJI_JIS_4B57, /*  0x9676 (U+6ca1) */
	C_KANJI_JIS_4B58, /*  0x9677 (U+6b86) */
	C_KANJI_JIS_4B59, /*  0x9678 (U+5800) */
	C_KANJI_JIS_4B5A, /*  0x9679 (U+5e4c) */
	C_KANJI_JIS_4B5B, /*  0x967a (U+5954) */
	C_KANJI_JIS_4B5C, /*  0x967b (U+672c) */
	C_KANJI_JIS_4B5D, /*  0x967c (U+7ffb) */
	C_KANJI_JIS_4B5E, /*  0x967d (U+51e1) */
	C_KANJI_JIS_4B5F, /*  0x967e (U+76c6) */
	0, /*  0x967f */
	C_KANJI_JIS_4B60, /*  0x9680 (U+6469) */
	C_KANJI_JIS_4B61, /*  0x9681 (U+78e8) */
	C_KANJI_JIS_4B62, /*  0x9682 (U+9b54) */
	C_KANJI_JIS_4B63, /*  0x9683 (U+9ebb) */
	C_KANJI_JIS_4B64, /*  0x9684 (U+57cb) */
	C_KANJI_JIS_4B65, /*  0x9685 (U+59b9) */
	C_KANJI_JIS_4B66, /*  0x9686 (U+6627) */
	C_KANJI_JIS_4B67, /*  0x9687 (U+679a) */
	C_KANJI_JIS_4B68, /*  0x9688 (U+6bce) */
	C_KANJI_JIS_4B69, /*  0x9689 (U+54e9) */
	C_KANJI_JIS_4B6A, /*  0x968a (U+69d9) */
	C_KANJI_JIS_4B6B, /*  0x968b (U+5e55) */
	C_KANJI_JIS_4B6C, /*  0x968c (U+819c) */
	C_KANJI_JIS_4B6D, /*  0x968d (U+6795) */
	C_KANJI_JIS_4B6E, /*  0x968e (U+9baa) */
	C_KANJI_JIS_4B6F, /*  0x968f (U+67fe) */
	C_KANJI_JIS_4B70, /*  0x9690 (U+9c52) */
	C_KANJI_JIS_4B71, /*  0x9691 (U+685d) */
	C_KANJI_JIS_4B72, /*  0x9692 (U+4ea6) */
	C_KANJI_JIS_4B73, /*  0x9693 (U+4fe3) */
	C_KANJI_JIS_4B74, /*  0x9694 (U+53c8) */
	C_KANJI_JIS_4B75, /*  0x9695 (U+62b9) */
	C_KANJI_JIS_4B76, /*  0x9696 (U+672b) */
	C_KANJI_JIS_4B77, /*  0x9697 (U+6cab) */
	C_KANJI_JIS_4B78, /*  0x9698 (U+8fc4) */
	C_KANJI_JIS_4B79, /*  0x9699 (U+4fad) */
	C_KANJI_JIS_4B7A, /*  0x969a (U+7e6d) */
	C_KANJI_JIS_4B7B, /*  0x969b (U+9ebf) */
	C_KANJI_JIS_4B7C, /*  0x969c (U+4e07) */
	C_KANJI_JIS_4B7D, /*  0x969d (U+6162) */
	C_KANJI_JIS_4B7E, /*  0x969e (U+6e80) */
	C_KANJI_JIS_4C21, /*  0x969f (U+6f2b) */
	C_KANJI_JIS_4C22, /*  0x96a0 (U+8513) */
	C_KANJI_JIS_4C23, /*  0x96a1 (U+5473) */
	C_KANJI_JIS_4C24, /*  0x96a2 (U+672a) */
	C_KANJI_JIS_4C25, /*  0x96a3 (U+9b45) */
	C_KANJI_JIS_4C26, /*  0x96a4 (U+5df3) */
	C_KANJI_JIS_4C27, /*  0x96a5 (U+7b95) */
	C_KANJI_JIS_4C28, /*  0x96a6 (U+5cac) */
	C_KANJI_JIS_4C29, /*  0x96a7 (U+5bc6) */
	C_KANJI_JIS_4C2A, /*  0x96a8 (U+871c) */
	C_KANJI_JIS_4C2B, /*  0x96a9 (U+6e4a) */
	C_KANJI_JIS_4C2C, /*  0x96aa (U+84d1) */
	C_KANJI_JIS_4C2D, /*  0x96ab (U+7a14) */
	C_KANJI_JIS_4C2E, /*  0x96ac (U+8108) */
	C_KANJI_JIS_4C2F, /*  0x96ad (U+5999) */
	C_KANJI_JIS_4C30, /*  0x96ae (U+7c8d) */
	C_KANJI_JIS_4C31, /*  0x96af (U+6c11) */
	C_KANJI_JIS_4C32, /*  0x96b0 (U+7720) */
	C_KANJI_JIS_4C33, /*  0x96b1 (U+52d9) */
	C_KANJI_JIS_4C34, /*  0x96b2 (U+5922) */
	C_KANJI_JIS_4C35, /*  0x96b3 (U+7121) */
	C_KANJI_JIS_4C36, /*  0x96b4 (U+725f) */
	C_KANJI_JIS_4C37, /*  0x96b5 (U+77db) */
	C_KANJI_JIS_4C38, /*  0x96b6 (U+9727) */
	C_KANJI_JIS_4C39, /*  0x96b7 (U+9d61) */
	C_KANJI_JIS_4C3A, /*  0x96b8 (U+690b) */
	C_KANJI_JIS_4C3B, /*  0x96b9 (U+5a7f) */
	C_KANJI_JIS_4C3C, /*  0x96ba (U+5a18) */
	C_KANJI_JIS_4C3D, /*  0x96bb (U+51a5) */
	C_KANJI_JIS_4C3E, /*  0x96bc (U+540d) */
	C_KANJI_JIS_4C3F, /*  0x96bd (U+547d) */
	C_KANJI_JIS_4C40, /*  0x96be (U+660e) */
	C_KANJI_JIS_4C41, /*  0x96bf (U+76df) */
	C_KANJI_JIS_4C42, /*  0x96c0 (U+8ff7) */
	C_KANJI_JIS_4C43, /*  0x96c1 (U+9298) */
	C_KANJI_JIS_4C44, /*  0x96c2 (U+9cf4) */
	C_KANJI_JIS_4C45, /*  0x96c3 (U+59ea) */
	C_KANJI_JIS_4C46, /*  0x96c4 (U+725d) */
	C_KANJI_JIS_4C47, /*  0x96c5 (U+6ec5) */
	C_KANJI_JIS_4C48, /*  0x96c6 (U+514d) */
	C_KANJI_JIS_4C49, /*  0x96c7 (U+68c9) */
	C_KANJI_JIS_4C4A, /*  0x96c8 (U+7dbf) */
	C_KANJI_JIS_4C4B, /*  0x96c9 (U+7dec) */
	C_KANJI_JIS_4C4C, /*  0x96ca (U+9762) */
	C_KANJI_JIS_4C4D, /*  0x96cb (U+9eba) */
	C_KANJI_JIS_4C4E, /*  0x96cc (U+6478) */
	C_KANJI_JIS_4C4F, /*  0x96cd (U+6a21) */
	C_KANJI_JIS_4C50, /*  0x96ce (U+8302) */
	C_KANJI_JIS_4C51, /*  0x96cf (U+5984) */
	C_KANJI_JIS_4C52, /*  0x96d0 (U+5b5f) */
	C_KANJI_JIS_4C53, /*  0x96d1 (U+6bdb) */
	C_KANJI_JIS_4C54, /*  0x96d2 (U+731b) */
	C_KANJI_JIS_4C55, /*  0x96d3 (U+76f2) */
	C_KANJI_JIS_4C56, /*  0x96d4 (U+7db2) */
	C_KANJI_JIS_4C57, /*  0x96d5 (U+8017) */
	C_KANJI_JIS_4C58, /*  0x96d6 (U+8499) */
	C_KANJI_JIS_4C59, /*  0x96d7 (U+5132) */
	C_KANJI_JIS_4C5A, /*  0x96d8 (U+6728) */
	C_KANJI_JIS_4C5B, /*  0x96d9 (U+9ed9) */
	C_KANJI_JIS_4C5C, /*  0x96da (U+76ee) */
	C_KANJI_JIS_4C5D, /*  0x96db (U+6762) */
	C_KANJI_JIS_4C5E, /*  0x96dc (U+52ff) */
	C_KANJI_JIS_4C5F, /*  0x96dd (U+9905) */
	C_KANJI_JIS_4C60, /*  0x96de (U+5c24) */
	C_KANJI_JIS_4C61, /*  0x96df (U+623b) */
	C_KANJI_JIS_4C62, /*  0x96e0 (U+7c7e) */
	C_KANJI_JIS_4C63, /*  0x96e1 (U+8cb0) */
	C_KANJI_JIS_4C64, /*  0x96e2 (U+554f) */
	C_KANJI_JIS_4C65, /*  0x96e3 (U+60b6) */
	C_KANJI_JIS_4C66, /*  0x96e4 (U+7d0b) */
	C_KANJI_JIS_4C67, /*  0x96e5 (U+9580) */
	C_KANJI_JIS_4C68, /*  0x96e6 (U+5301) */
	C_KANJI_JIS_4C69, /*  0x96e7 (U+4e5f) */
	C_KANJI_JIS_4C6A, /*  0x96e8 (U+51b6) */
	C_KANJI_JIS_4C6B, /*  0x96e9 (U+591c) */
	C_KANJI_JIS_4C6C, /*  0x96ea (U+723a) */
	C_KANJI_JIS_4C6D, /*  0x96eb (U+8036) */
	C_KANJI_JIS_4C6E, /*  0x96ec (U+91ce) */
	C_KANJI_JIS_4C6F, /*  0x96ed (U+5f25) */
	C_KANJI_JIS_4C70, /*  0x96ee (U+77e2) */
	C_KANJI_JIS_4C71, /*  0x96ef (U+5384) */
	C_KANJI_JIS_4C72, /*  0x96f0 (U+5f79) */
	C_KANJI_JIS_4C73, /*  0x96f1 (U+7d04) */
	C_KANJI_JIS_4C74, /*  0x96f2 (U+85ac) */
	C_KANJI_JIS_4C75, /*  0x96f3 (U+8a33) */
	C_KANJI_JIS_4C76, /*  0x96f4 (U+8e8d) */
	C_KANJI_JIS_4C77, /*  0x96f5 (U+9756) */
	C_KANJI_JIS_4C78, /*  0x96f6 (U+67f3) */
	C_KANJI_JIS_4C79, /*  0x96f7 (U+85ae) */
	C_KANJI_JIS_4C7A, /*  0x96f8 (U+9453) */
	C_KANJI_JIS_4C7B, /*  0x96f9 (U+6109) */
	C_KANJI_JIS_4C7C, /*  0x96fa (U+6108) */
	C_KANJI_JIS_4C7D, /*  0x96fb (U+6cb9) */
	C_KANJI_JIS_4C7E, /*  0x96fc (U+7652) */
	0, /*  0x96fd */
	0, /*  0x96fe */
	0, /*  0x96ff */
	C_KANJI_JIS_4D21, /*  0x9740 (U+8aed) */
	C_KANJI_JIS_4D22, /*  0x9741 (U+8f38) */
	C_KANJI_JIS_4D23, /*  0x9742 (U+552f) */
	C_KANJI_JIS_4D24, /*  0x9743 (U+4f51) */
	C_KANJI_JIS_4D25, /*  0x9744 (U+512a) */
	C_KANJI_JIS_4D26, /*  0x9745 (U+52c7) */
	C_KANJI_JIS_4D27, /*  0x9746 (U+53cb) */
	C_KANJI_JIS_4D28, /*  0x9747 (U+5ba5) */
	C_KANJI_JIS_4D29, /*  0x9748 (U+5e7d) */
	C_KANJI_JIS_4D2A, /*  0x9749 (U+60a0) */
	C_KANJI_JIS_4D2B, /*  0x974a (U+6182) */
	C_KANJI_JIS_4D2C, /*  0x974b (U+63d6) */
	C_KANJI_JIS_4D2D, /*  0x974c (U+6709) */
	C_KANJI_JIS_4D2E, /*  0x974d (U+67da) */
	C_KANJI_JIS_4D2F, /*  0x974e (U+6e67) */
	C_KANJI_JIS_4D30, /*  0x974f (U+6d8c) */
	C_KANJI_JIS_4D31, /*  0x9750 (U+7336) */
	C_KANJI_JIS_4D32, /*  0x9751 (U+7337) */
	C_KANJI_JIS_4D33, /*  0x9752 (U+7531) */
	C_KANJI_JIS_4D34, /*  0x9753 (U+7950) */
	C_KANJI_JIS_4D35, /*  0x9754 (U+88d5) */
	C_KANJI_JIS_4D36, /*  0x9755 (U+8a98) */
	C_KANJI_JIS_4D37, /*  0x9756 (U+904a) */
	C_KANJI_JIS_4D38, /*  0x9757 (U+9091) */
	C_KANJI_JIS_4D39, /*  0x9758 (U+90f5) */
	C_KANJI_JIS_4D3A, /*  0x9759 (U+96c4) */
	C_KANJI_JIS_4D3B, /*  0x975a (U+878d) */
	C_KANJI_JIS_4D3C, /*  0x975b (U+5915) */
	C_KANJI_JIS_4D3D, /*  0x975c (U+4e88) */
	C_KANJI_JIS_4D3E, /*  0x975d (U+4f59) */
	C_KANJI_JIS_4D3F, /*  0x975e (U+4e0e) */
	C_KANJI_JIS_4D40, /*  0x975f (U+8a89) */
	C_KANJI_JIS_4D41, /*  0x9760 (U+8f3f) */
	C_KANJI_JIS_4D42, /*  0x9761 (U+9810) */
	C_KANJI_JIS_4D43, /*  0x9762 (U+50ad) */
	C_KANJI_JIS_4D44, /*  0x9763 (U+5e7c) */
	C_KANJI_JIS_4D45, /*  0x9764 (U+5996) */
	C_KANJI_JIS_4D46, /*  0x9765 (U+5bb9) */
	C_KANJI_JIS_4D47, /*  0x9766 (U+5eb8) */
	C_KANJI_JIS_4D48, /*  0x9767 (U+63da) */
	C_KANJI_JIS_4D49, /*  0x9768 (U+63fa) */
	C_KANJI_JIS_4D4A, /*  0x9769 (U+64c1) */
	C_KANJI_JIS_4D4B, /*  0x976a (U+66dc) */
	C_KANJI_JIS_4D4C, /*  0x976b (U+694a) */
	C_KANJI_JIS_4D4D, /*  0x976c (U+69d8) */
	C_KANJI_JIS_4D4E, /*  0x976d (U+6d0b) */
	C_KANJI_JIS_4D4F, /*  0x976e (U+6eb6) */
	C_KANJI_JIS_4D50, /*  0x976f (U+7194) */
	C_KANJI_JIS_4D51, /*  0x9770 (U+7528) */
	C_KANJI_JIS_4D52, /*  0x9771 (U+7aaf) */
	C_KANJI_JIS_4D53, /*  0x9772 (U+7f8a) */
	C_KANJI_JIS_4D54, /*  0x9773 (U+8000) */
	C_KANJI_JIS_4D55, /*  0x9774 (U+8449) */
	C_KANJI_JIS_4D56, /*  0x9775 (U+84c9) */
	C_KANJI_JIS_4D57, /*  0x9776 (U+8981) */
	C_KANJI_JIS_4D58, /*  0x9777 (U+8b21) */
	C_KANJI_JIS_4D59, /*  0x9778 (U+8e0a) */
	C_KANJI_JIS_4D5A, /*  0x9779 (U+9065) */
	C_KANJI_JIS_4D5B, /*  0x977a (U+967d) */
	C_KANJI_JIS_4D5C, /*  0x977b (U+990a) */
	C_KANJI_JIS_4D5D, /*  0x977c (U+617e) */
	C_KANJI_JIS_4D5E, /*  0x977d (U+6291) */
	C_KANJI_JIS_4D5F, /*  0x977e (U+6b32) */
	0, /*  0x977f */
	C_KANJI_JIS_4D60, /*  0x9780 (U+6c83) */
	C_KANJI_JIS_4D61, /*  0x9781 (U+6d74) */
	C_KANJI_JIS_4D62, /*  0x9782 (U+7fcc) */
	C_KANJI_JIS_4D63, /*  0x9783 (U+7ffc) */
	C_KANJI_JIS_4D64, /*  0x9784 (U+6dc0) */
	C_KANJI_JIS_4D65, /*  0x9785 (U+7f85) */
	C_KANJI_JIS_4D66, /*  0x9786 (U+87ba) */
	C_KANJI_JIS_4D67, /*  0x9787 (U+88f8) */
	C_KANJI_JIS_4D68, /*  0x9788 (U+6765) */
	C_KANJI_JIS_4D69, /*  0x9789 (U+83b1) */
	C_KANJI_JIS_4D6A, /*  0x978a (U+983c) */
	C_KANJI_JIS_4D6B, /*  0x978b (U+96f7) */
	C_KANJI_JIS_4D6C, /*  0x978c (U+6d1b) */
	C_KANJI_JIS_4D6D, /*  0x978d (U+7d61) */
	C_KANJI_JIS_4D6E, /*  0x978e (U+843d) */
	C_KANJI_JIS_4D6F, /*  0x978f (U+916a) */
	C_KANJI_JIS_4D70, /*  0x9790 (U+4e71) */
	C_KANJI_JIS_4D71, /*  0x9791 (U+5375) */
	C_KANJI_JIS_4D72, /*  0x9792 (U+5d50) */
	C_KANJI_JIS_4D73, /*  0x9793 (U+6b04) */
	C_KANJI_JIS_4D74, /*  0x9794 (U+6feb) */
	C_KANJI_JIS_4D75, /*  0x9795 (U+85cd) */
	C_KANJI_JIS_4D76, /*  0x9796 (U+862d) */
	C_KANJI_JIS_4D77, /*  0x9797 (U+89a7) */
	C_KANJI_JIS_4D78, /*  0x9798 (U+5229) */
	C_KANJI_JIS_4D79, /*  0x9799 (U+540f) */
	C_KANJI_JIS_4D7A, /*  0x979a (U+5c65) */
	C_KANJI_JIS_4D7B, /*  0x979b (U+674e) */
	C_KANJI_JIS_4D7C, /*  0x979c (U+68a8) */
	C_KANJI_JIS_4D7D, /*  0x979d (U+7406) */
	C_KANJI_JIS_4D7E, /*  0x979e (U+7483) */
	C_KANJI_JIS_4E21, /*  0x979f (U+75e2) */
	C_KANJI_JIS_4E22, /*  0x97a0 (U+88cf) */
	C_KANJI_JIS_4E23, /*  0x97a1 (U+88e1) */
	C_KANJI_JIS_4E24, /*  0x97a2 (U+91cc) */
	C_KANJI_JIS_4E25, /*  0x97a3 (U+96e2) */
	C_KANJI_JIS_4E26, /*  0x97a4 (U+9678) */
	C_KANJI_JIS_4E27, /*  0x97a5 (U+5f8b) */
	C_KANJI_JIS_4E28, /*  0x97a6 (U+7387) */
	C_KANJI_JIS_4E29, /*  0x97a7 (U+7acb) */
	C_KANJI_JIS_4E2A, /*  0x97a8 (U+844e) */
	C_KANJI_JIS_4E2B, /*  0x97a9 (U+63a0) */
	C_KANJI_JIS_4E2C, /*  0x97aa (U+7565) */
	C_KANJI_JIS_4E2D, /*  0x97ab (U+5289) */
	C_KANJI_JIS_4E2E, /*  0x97ac (U+6d41) */
	C_KANJI_JIS_4E2F, /*  0x97ad (U+6e9c) */
	C_KANJI_JIS_4E30, /*  0x97ae (U+7409) */
	C_KANJI_JIS_4E31, /*  0x97af (U+7559) */
	C_KANJI_JIS_4E32, /*  0x97b0 (U+786b) */
	C_KANJI_JIS_4E33, /*  0x97b1 (U+7c92) */
	C_KANJI_JIS_4E34, /*  0x97b2 (U+9686) */
	C_KANJI_JIS_4E35, /*  0x97b3 (U+7adc) */
	C_KANJI_JIS_4E36, /*  0x97b4 (U+9f8d) */
	C_KANJI_JIS_4E37, /*  0x97b5 (U+4fb6) */
	C_KANJI_JIS_4E38, /*  0x97b6 (U+616e) */
	C_KANJI_JIS_4E39, /*  0x97b7 (U+65c5) */
	C_KANJI_JIS_4E3A, /*  0x97b8 (U+865c) */
	C_KANJI_JIS_4E3B, /*  0x97b9 (U+4e86) */
	C_KANJI_JIS_4E3C, /*  0x97ba (U+4eae) */
	C_KANJI_JIS_4E3D, /*  0x97bb (U+50da) */
	C_KANJI_JIS_4E3E, /*  0x97bc (U+4e21) */
	C_KANJI_JIS_4E3F, /*  0x97bd (U+51cc) */
	C_KANJI_JIS_4E40, /*  0x97be (U+5bee) */
	C_KANJI_JIS_4E41, /*  0x97bf (U+6599) */
	C_KANJI_JIS_4E42, /*  0x97c0 (U+6881) */
	C_KANJI_JIS_4E43, /*  0x97c1 (U+6dbc) */
	C_KANJI_JIS_4E44, /*  0x97c2 (U+731f) */
	C_KANJI_JIS_4E45, /*  0x97c3 (U+7642) */
	C_KANJI_JIS_4E46, /*  0x97c4 (U+77ad) */
	C_KANJI_JIS_4E47, /*  0x97c5 (U+7a1c) */
	C_KANJI_JIS_4E48, /*  0x97c6 (U+7ce7) */
	C_KANJI_JIS_4E49, /*  0x97c7 (U+826f) */
	C_KANJI_JIS_4E4A, /*  0x97c8 (U+8ad2) */
	C_KANJI_JIS_4E4B, /*  0x97c9 (U+907c) */
	C_KANJI_JIS_4E4C, /*  0x97ca (U+91cf) */
	C_KANJI_JIS_4E4D, /*  0x97cb (U+9675) */
	C_KANJI_JIS_4E4E, /*  0x97cc (U+9818) */
	C_KANJI_JIS_4E4F, /*  0x97cd (U+529b) */
	C_KANJI_JIS_4E50, /*  0x97ce (U+7dd1) */
	C_KANJI_JIS_4E51, /*  0x97cf (U+502b) */
	C_KANJI_JIS_4E52, /*  0x97d0 (U+5398) */
	C_KANJI_JIS_4E53, /*  0x97d1 (U+6797) */
	C_KANJI_JIS_4E54, /*  0x97d2 (U+6dcb) */
	C_KANJI_JIS_4E55, /*  0x97d3 (U+71d0) */
	C_KANJI_JIS_4E56, /*  0x97d4 (U+7433) */
	C_KANJI_JIS_4E57, /*  0x97d5 (U+81e8) */
	C_KANJI_JIS_4E58, /*  0x97d6 (U+8f2a) */
	C_KANJI_JIS_4E59, /*  0x97d7 (U+96a3) */
	C_KANJI_JIS_4E5A, /*  0x97d8 (U+9c57) */
	C_KANJI_JIS_4E5B, /*  0x97d9 (U+9e9f) */
	C_KANJI_JIS_4E5C, /*  0x97da (U+7460) */
	C_KANJI_JIS_4E5D, /*  0x97db (U+5841) */
	C_KANJI_JIS_4E5E, /*  0x97dc (U+6d99) */
	C_KANJI_JIS_4E5F, /*  0x97dd (U+7d2f) */
	C_KANJI_JIS_4E60, /*  0x97de (U+985e) */
	C_KANJI_JIS_4E61, /*  0x97df (U+4ee4) */
	C_KANJI_JIS_4E62, /*  0x97e0 (U+4f36) */
	C_KANJI_JIS_4E63, /*  0x97e1 (U+4f8b) */
	C_KANJI_JIS_4E64, /*  0x97e2 (U+51b7) */
	C_KANJI_JIS_4E65, /*  0x97e3 (U+52b1) */
	C_KANJI_JIS_4E66, /*  0x97e4 (U+5dba) */
	C_KANJI_JIS_4E67, /*  0x97e5 (U+601c) */
	C_KANJI_JIS_4E68, /*  0x97e6 (U+73b2) */
	C_KANJI_JIS_4E69, /*  0x97e7 (U+793c) */
	C_KANJI_JIS_4E6A, /*  0x97e8 (U+82d3) */
	C_KANJI_JIS_4E6B, /*  0x97e9 (U+9234) */
	C_KANJI_JIS_4E6C, /*  0x97ea (U+96b7) */
	C_KANJI_JIS_4E6D, /*  0x97eb (U+96f6) */
	C_KANJI_JIS_4E6E, /*  0x97ec (U+970a) */
	C_KANJI_JIS_4E6F, /*  0x97ed (U+9e97) */
	C_KANJI_JIS_4E70, /*  0x97ee (U+9f62) */
	C_KANJI_JIS_4E71, /*  0x97ef (U+66a6) */
	C_KANJI_JIS_4E72, /*  0x97f0 (U+6b74) */
	C_KANJI_JIS_4E73, /*  0x97f1 (U+5217) */
	C_KANJI_JIS_4E74, /*  0x97f2 (U+52a3) */
	C_KANJI_JIS_4E75, /*  0x97f3 (U+70c8) */
	C_KANJI_JIS_4E76, /*  0x97f4 (U+88c2) */
	C_KANJI_JIS_4E77, /*  0x97f5 (U+5ec9) */
	C_KANJI_JIS_4E78, /*  0x97f6 (U+604b) */
	C_KANJI_JIS_4E79, /*  0x97f7 (U+6190) */
	C_KANJI_JIS_4E7A, /*  0x97f8 (U+6f23) */
	C_KANJI_JIS_4E7B, /*  0x97f9 (U+7149) */
	C_KANJI_JIS_4E7C, /*  0x97fa (U+7c3e) */
	C_KANJI_JIS_4E7D, /*  0x97fb (U+7df4) */
	C_KANJI_JIS_4E7E, /*  0x97fc (U+806f) */
	0, /*  0x97fd */
	0, /*  0x97fe */
	0, /*  0x97ff */
	C_KANJI_JIS_4F21, /*  0x9840 (U+84ee) */
	C_KANJI_JIS_4F22, /*  0x9841 (U+9023) */
	C_KANJI_JIS_4F23, /*  0x9842 (U+932c) */
	C_KANJI_JIS_4F24, /*  0x9843 (U+5442) */
	C_KANJI_JIS_4F25, /*  0x9844 (U+9b6f) */
	C_KANJI_JIS_4F26, /*  0x9845 (U+6ad3) */
	C_KANJI_JIS_4F27, /*  0x9846 (U+7089) */
	C_KANJI_JIS_4F28, /*  0x9847 (U+8cc2) */
	C_KANJI_JIS_4F29, /*  0x9848 (U+8def) */
	C_KANJI_JIS_4F2A, /*  0x9849 (U+9732) */
	C_KANJI_JIS_4F2B, /*  0x984a (U+52b4) */
	C_KANJI_JIS_4F2C, /*  0x984b (U+5a41) */
	C_KANJI_JIS_4F2D, /*  0x984c (U+5eca) */
	C_KANJI_JIS_4F2E, /*  0x984d (U+5f04) */
	C_KANJI_JIS_4F2F, /*  0x984e (U+6717) */
	C_KANJI_JIS_4F30, /*  0x984f (U+697c) */
	C_KANJI_JIS_4F31, /*  0x9850 (U+6994) */
	C_KANJI_JIS_4F32, /*  0x9851 (U+6d6a) */
	C_KANJI_JIS_4F33, /*  0x9852 (U+6f0f) */
	C_KANJI_JIS_4F34, /*  0x9853 (U+7262) */
	C_KANJI_JIS_4F35, /*  0x9854 (U+72fc) */
	C_KANJI_JIS_4F36, /*  0x9855 (U+7bed) */
	C_KANJI_JIS_4F37, /*  0x9856 (U+8001) */
	C_KANJI_JIS_4F38, /*  0x9857 (U+807e) */
	C_KANJI_JIS_4F39, /*  0x9858 (U+874b) */
	C_KANJI_JIS_4F3A, /*  0x9859 (U+90ce) */
	C_KANJI_JIS_4F3B, /*  0x985a (U+516d) */
	C_KANJI_JIS_4F3C, /*  0x985b (U+9e93) */
	C_KANJI_JIS_4F3D, /*  0x985c (U+7984) */
	C_KANJI_JIS_4F3E, /*  0x985d (U+808b) */
	C_KANJI_JIS_4F3F, /*  0x985e (U+9332) */
	C_KANJI_JIS_4F40, /*  0x985f (U+8ad6) */
	C_KANJI_JIS_4F41, /*  0x9860 (U+502d) */
	C_KANJI_JIS_4F42, /*  0x9861 (U+548c) */
	C_KANJI_JIS_4F43, /*  0x9862 (U+8a71) */
	C_KANJI_JIS_4F44, /*  0x9863 (U+6b6a) */
	C_KANJI_JIS_4F45, /*  0x9864 (U+8cc4) */
	C_KANJI_JIS_4F46, /*  0x9865 (U+8107) */
	C_KANJI_JIS_4F47, /*  0x9866 (U+60d1) */
	C_KANJI_JIS_4F48, /*  0x9867 (U+67a0) */
	C_KANJI_JIS_4F49, /*  0x9868 (U+9df2) */
	C_KANJI_JIS_4F4A, /*  0x9869 (U+4e99) */
	C_KANJI_JIS_4F4B, /*  0x986a (U+4e98) */
	C_KANJI_JIS_4F4C, /*  0x986b (U+9c10) */
	C_KANJI_JIS_4F4D, /*  0x986c (U+8a6b) */
	C_KANJI_JIS_4F4E, /*  0x986d (U+85c1) */
	C_KANJI_JIS_4F4F, /*  0x986e (U+8568) */
	C_KANJI_JIS_4F50, /*  0x986f (U+6900) */
	C_KANJI_JIS_4F51, /*  0x9870 (U+6e7e) */
	C_KANJI_JIS_4F52, /*  0x9871 (U+7897) */
	C_KANJI_JIS_4F53, /*  0x9872 (U+8155) */
	0, /*  0x9873 */
	0, /*  0x9874 */
	0, /*  0x9875 */
	0, /*  0x9876 */
	0, /*  0x9877 */
	0, /*  0x9878 */
	0, /*  0x9879 */
	0, /*  0x987a */
	0, /*  0x987b */
	0, /*  0x987c */
	0, /*  0x987d */
	0, /*  0x987e */
	0, /*  0x987f */
	0, /*  0x9880 */
	0, /*  0x9881 */
	0, /*  0x9882 */
	0, /*  0x9883 */
	0, /*  0x9884 */
	0, /*  0x9885 */
	0, /*  0x9886 */
	0, /*  0x9887 */
	0, /*  0x9888 */
	0, /*  0x9889 */
	0, /*  0x988a */
	0, /*  0x988b */
	0, /*  0x988c */
	0, /*  0x988d */
	0, /*  0x988e */
	0, /*  0x988f */
	0, /*  0x9890 */
	0, /*  0x9891 */
	0, /*  0x9892 */
	0, /*  0x9893 */
	0, /*  0x9894 */
	0, /*  0x9895 */
	0, /*  0x9896 */
	0, /*  0x9897 */
	0, /*  0x9898 */
	0, /*  0x9899 */
	0, /*  0x989a */
	0, /*  0x989b */
	0, /*  0x989c */
	0, /*  0x989d */
	0, /*  0x989e */
	C_KANJI_JIS_5021, /*  0x989f (U+5f0c) */
	C_KANJI_JIS_5022, /*  0x98a0 (U+4e10) */
	C_KANJI_JIS_5023, /*  0x98a1 (U+4e15) */
	C_KANJI_JIS_5024, /*  0x98a2 (U+4e2a) */
	C_KANJI_JIS_5025, /*  0x98a3 (U+4e31) */
	C_KANJI_JIS_5026, /*  0x98a4 (U+4e36) */
	C_KANJI_JIS_5027, /*  0x98a5 (U+4e3c) */
	C_KANJI_JIS_5028, /*  0x98a6 (U+4e3f) */
	C_KANJI_JIS_5029, /*  0x98a7 (U+4e42) */
	C_KANJI_JIS_502A, /*  0x98a8 (U+4e56) */
	C_KANJI_JIS_502B, /*  0x98a9 (U+4e58) */
	C_KANJI_JIS_502C, /*  0x98aa (U+4e82) */
	C_KANJI_JIS_502D, /*  0x98ab (U+4e85) */
	C_KANJI_JIS_502E, /*  0x98ac (U+8c6b) */
	C_KANJI_JIS_502F, /*  0x98ad (U+4e8a) */
	C_KANJI_JIS_5030, /*  0x98ae (U+8212) */
	C_KANJI_JIS_5031, /*  0x98af (U+5f0d) */
	C_KANJI_JIS_5032, /*  0x98b0 (U+4e8e) */
	C_KANJI_JIS_5033, /*  0x98b1 (U+4e9e) */
	C_KANJI_JIS_5034, /*  0x98b2 (U+4e9f) */
	C_KANJI_JIS_5035, /*  0x98b3 (U+4ea0) */
	C_KANJI_JIS_5036, /*  0x98b4 (U+4ea2) */
	C_KANJI_JIS_5037, /*  0x98b5 (U+4eb0) */
	C_KANJI_JIS_5038, /*  0x98b6 (U+4eb3) */
	C_KANJI_JIS_5039, /*  0x98b7 (U+4eb6) */
	C_KANJI_JIS_503A, /*  0x98b8 (U+4ece) */
	C_KANJI_JIS_503B, /*  0x98b9 (U+4ecd) */
	C_KANJI_JIS_503C, /*  0x98ba (U+4ec4) */
	C_KANJI_JIS_503D, /*  0x98bb (U+4ec6) */
	C_KANJI_JIS_503E, /*  0x98bc (U+4ec2) */
	C_KANJI_JIS_503F, /*  0x98bd (U+4ed7) */
	C_KANJI_JIS_5040, /*  0x98be (U+4ede) */
	C_KANJI_JIS_5041, /*  0x98bf (U+4eed) */
	C_KANJI_JIS_5042, /*  0x98c0 (U+4edf) */
	C_KANJI_JIS_5043, /*  0x98c1 (U+4ef7) */
	C_KANJI_JIS_5044, /*  0x98c2 (U+4f09) */
	C_KANJI_JIS_5045, /*  0x98c3 (U+4f5a) */
	C_KANJI_JIS_5046, /*  0x98c4 (U+4f30) */
	C_KANJI_JIS_5047, /*  0x98c5 (U+4f5b) */
	C_KANJI_JIS_5048, /*  0x98c6 (U+4f5d) */
	C_KANJI_JIS_5049, /*  0x98c7 (U+4f57) */
	C_KANJI_JIS_504A, /*  0x98c8 (U+4f47) */
	C_KANJI_JIS_504B, /*  0x98c9 (U+4f76) */
	C_KANJI_JIS_504C, /*  0x98ca (U+4f88) */
	C_KANJI_JIS_504D, /*  0x98cb (U+4f8f) */
	C_KANJI_JIS_504E, /*  0x98cc (U+4f98) */
	C_KANJI_JIS_504F, /*  0x98cd (U+4f7b) */
	C_KANJI_JIS_5050, /*  0x98ce (U+4f69) */
	C_KANJI_JIS_5051, /*  0x98cf (U+4f70) */
	C_KANJI_JIS_5052, /*  0x98d0 (U+4f91) */
	C_KANJI_JIS_5053, /*  0x98d1 (U+4f6f) */
	C_KANJI_JIS_5054, /*  0x98d2 (U+4f86) */
	C_KANJI_JIS_5055, /*  0x98d3 (U+4f96) */
	C_KANJI_JIS_5056, /*  0x98d4 (U+5118) */
	C_KANJI_JIS_5057, /*  0x98d5 (U+4fd4) */
	C_KANJI_JIS_5058, /*  0x98d6 (U+4fdf) */
	C_KANJI_JIS_5059, /*  0x98d7 (U+4fce) */
	C_KANJI_JIS_505A, /*  0x98d8 (U+4fd8) */
	C_KANJI_JIS_505B, /*  0x98d9 (U+4fdb) */
	C_KANJI_JIS_505C, /*  0x98da (U+4fd1) */
	C_KANJI_JIS_505D, /*  0x98db (U+4fda) */
	C_KANJI_JIS_505E, /*  0x98dc (U+4fd0) */
	C_KANJI_JIS_505F, /*  0x98dd (U+4fe4) */
	C_KANJI_JIS_5060, /*  0x98de (U+4fe5) */
	C_KANJI_JIS_5061, /*  0x98df (U+501a) */
	C_KANJI_JIS_5062, /*  0x98e0 (U+5028) */
	C_KANJI_JIS_5063, /*  0x98e1 (U+5014) */
	C_KANJI_JIS_5064, /*  0x98e2 (U+502a) */
	C_KANJI_JIS_5065, /*  0x98e3 (U+5025) */
	C_KANJI_JIS_5066, /*  0x98e4 (U+5005) */
	C_KANJI_JIS_5067, /*  0x98e5 (U+4f1c) */
	C_KANJI_JIS_5068, /*  0x98e6 (U+4ff6) */
	C_KANJI_JIS_5069, /*  0x98e7 (U+5021) */
	C_KANJI_JIS_506A, /*  0x98e8 (U+5029) */
	C_KANJI_JIS_506B, /*  0x98e9 (U+502c) */
	C_KANJI_JIS_506C, /*  0x98ea (U+4ffe) */
	C_KANJI_JIS_506D, /*  0x98eb (U+4fef) */
	C_KANJI_JIS_506E, /*  0x98ec (U+5011) */
	C_KANJI_JIS_506F, /*  0x98ed (U+5006) */
	C_KANJI_JIS_5070, /*  0x98ee (U+5043) */
	C_KANJI_JIS_5071, /*  0x98ef (U+5047) */
	C_KANJI_JIS_5072, /*  0x98f0 (U+6703) */
	C_KANJI_JIS_5073, /*  0x98f1 (U+5055) */
	C_KANJI_JIS_5074, /*  0x98f2 (U+5050) */
	C_KANJI_JIS_5075, /*  0x98f3 (U+5048) */
	C_KANJI_JIS_5076, /*  0x98f4 (U+505a) */
	C_KANJI_JIS_5077, /*  0x98f5 (U+5056) */
	C_KANJI_JIS_5078, /*  0x98f6 (U+506c) */
	C_KANJI_JIS_5079, /*  0x98f7 (U+5078) */
	C_KANJI_JIS_507A, /*  0x98f8 (U+5080) */
	C_KANJI_JIS_507B, /*  0x98f9 (U+509a) */
	C_KANJI_JIS_507C, /*  0x98fa (U+5085) */
	C_KANJI_JIS_507D, /*  0x98fb (U+50b4) */
	C_KANJI_JIS_507E, /*  0x98fc (U+50b2) */
	0, /*  0x98fd */
	0, /*  0x98fe */
	0, /*  0x98ff */
	C_KANJI_JIS_5121, /*  0x9940 (U+50c9) */
	C_KANJI_JIS_5122, /*  0x9941 (U+50ca) */
	C_KANJI_JIS_5123, /*  0x9942 (U+50b3) */
	C_KANJI_JIS_5124, /*  0x9943 (U+50c2) */
	C_KANJI_JIS_5125, /*  0x9944 (U+50d6) */
	C_KANJI_JIS_5126, /*  0x9945 (U+50de) */
	C_KANJI_JIS_5127, /*  0x9946 (U+50e5) */
	C_KANJI_JIS_5128, /*  0x9947 (U+50ed) */
	C_KANJI_JIS_5129, /*  0x9948 (U+50e3) */
	C_KANJI_JIS_512A, /*  0x9949 (U+50ee) */
	C_KANJI_JIS_512B, /*  0x994a (U+50f9) */
	C_KANJI_JIS_512C, /*  0x994b (U+50f5) */
	C_KANJI_JIS_512D, /*  0x994c (U+5109) */
	C_KANJI_JIS_512E, /*  0x994d (U+5101) */
	C_KANJI_JIS_512F, /*  0x994e (U+5102) */
	C_KANJI_JIS_5130, /*  0x994f (U+5116) */
	C_KANJI_JIS_5131, /*  0x9950 (U+5115) */
	C_KANJI_JIS_5132, /*  0x9951 (U+5114) */
	C_KANJI_JIS_5133, /*  0x9952 (U+511a) */
	C_KANJI_JIS_5134, /*  0x9953 (U+5121) */
	C_KANJI_JIS_5135, /*  0x9954 (U+513a) */
	C_KANJI_JIS_5136, /*  0x9955 (U+5137) */
	C_KANJI_JIS_5137, /*  0x9956 (U+513c) */
	C_KANJI_JIS_5138, /*  0x9957 (U+513b) */
	C_KANJI_JIS_5139, /*  0x9958 (U+513f) */
	C_KANJI_JIS_513A, /*  0x9959 (U+5140) */
	C_KANJI_JIS_513B, /*  0x995a (U+5152) */
	C_KANJI_JIS_513C, /*  0x995b (U+514c) */
	C_KANJI_JIS_513D, /*  0x995c (U+5154) */
	C_KANJI_JIS_513E, /*  0x995d (U+5162) */
	C_KANJI_JIS_513F, /*  0x995e (U+7af8) */
	C_KANJI_JIS_5140, /*  0x995f (U+5169) */
	C_KANJI_JIS_5141, /*  0x9960 (U+516a) */
	C_KANJI_JIS_5142, /*  0x9961 (U+516e) */
	C_KANJI_JIS_5143, /*  0x9962 (U+5180) */
	C_KANJI_JIS_5144, /*  0x9963 (U+5182) */
	C_KANJI_JIS_5145, /*  0x9964 (U+56d8) */
	C_KANJI_JIS_5146, /*  0x9965 (U+518c) */
	C_KANJI_JIS_5147, /*  0x9966 (U+5189) */
	C_KANJI_JIS_5148, /*  0x9967 (U+518f) */
	C_KANJI_JIS_5149, /*  0x9968 (U+5191) */
	C_KANJI_JIS_514A, /*  0x9969 (U+5193) */
	C_KANJI_JIS_514B, /*  0x996a (U+5195) */
	C_KANJI_JIS_514C, /*  0x996b (U+5196) */
	C_KANJI_JIS_514D, /*  0x996c (U+51a4) */
	C_KANJI_JIS_514E, /*  0x996d (U+51a6) */
	C_KANJI_JIS_514F, /*  0x996e (U+51a2) */
	C_KANJI_JIS_5150, /*  0x996f (U+51a9) */
	C_KANJI_JIS_5151, /*  0x9970 (U+51aa) */
	C_KANJI_JIS_5152, /*  0x9971 (U+51ab) */
	C_KANJI_JIS_5153, /*  0x9972 (U+51b3) */
	C_KANJI_JIS_5154, /*  0x9973 (U+51b1) */
	C_KANJI_JIS_5155, /*  0x9974 (U+51b2) */
	C_KANJI_JIS_5156, /*  0x9975 (U+51b0) */
	C_KANJI_JIS_5157, /*  0x9976 (U+51b5) */
	C_KANJI_JIS_5158, /*  0x9977 (U+51bd) */
	C_KANJI_JIS_5159, /*  0x9978 (U+51c5) */
	C_KANJI_JIS_515A, /*  0x9979 (U+51c9) */
	C_KANJI_JIS_515B, /*  0x997a (U+51db) */
	C_KANJI_JIS_515C, /*  0x997b (U+51e0) */
	C_KANJI_JIS_515D, /*  0x997c (U+8655) */
	C_KANJI_JIS_515E, /*  0x997d (U+51e9) */
	C_KANJI_JIS_515F, /*  0x997e (U+51ed) */
	0, /*  0x997f */
	C_KANJI_JIS_5160, /*  0x9980 (U+51f0) */
	C_KANJI_JIS_5161, /*  0x9981 (U+51f5) */
	C_KANJI_JIS_5162, /*  0x9982 (U+51fe) */
	C_KANJI_JIS_5163, /*  0x9983 (U+5204) */
	C_KANJI_JIS_5164, /*  0x9984 (U+520b) */
	C_KANJI_JIS_5165, /*  0x9985 (U+5214) */
	C_KANJI_JIS_5166, /*  0x9986 (U+520e) */
	C_KANJI_JIS_5167, /*  0x9987 (U+5227) */
	C_KANJI_JIS_5168, /*  0x9988 (U+522a) */
	C_KANJI_JIS_5169, /*  0x9989 (U+522e) */
	C_KANJI_JIS_516A, /*  0x998a (U+5233) */
	C_KANJI_JIS_516B, /*  0x998b (U+5239) */
	C_KANJI_JIS_516C, /*  0x998c (U+524f) */
	C_KANJI_JIS_516D, /*  0x998d (U+5244) */
	C_KANJI_JIS_516E, /*  0x998e (U+524b) */
	C_KANJI_JIS_516F, /*  0x998f (U+524c) */
	C_KANJI_JIS_5170, /*  0x9990 (U+525e) */
	C_KANJI_JIS_5171, /*  0x9991 (U+5254) */
	C_KANJI_JIS_5172, /*  0x9992 (U+526a) */
	C_KANJI_JIS_5173, /*  0x9993 (U+5274) */
	C_KANJI_JIS_5174, /*  0x9994 (U+5269) */
	C_KANJI_JIS_5175, /*  0x9995 (U+5273) */
	C_KANJI_JIS_5176, /*  0x9996 (U+527f) */
	C_KANJI_JIS_5177, /*  0x9997 (U+527d) */
	C_KANJI_JIS_5178, /*  0x9998 (U+528d) */
	C_KANJI_JIS_5179, /*  0x9999 (U+5294) */
	C_KANJI_JIS_517A, /*  0x999a (U+5292) */
	C_KANJI_JIS_517B, /*  0x999b (U+5271) */
	C_KANJI_JIS_517C, /*  0x999c (U+5288) */
	C_KANJI_JIS_517D, /*  0x999d (U+5291) */
	C_KANJI_JIS_517E, /*  0x999e (U+8fa8) */
	C_KANJI_JIS_5221, /*  0x999f (U+8fa7) */
	C_KANJI_JIS_5222, /*  0x99a0 (U+52ac) */
	C_KANJI_JIS_5223, /*  0x99a1 (U+52ad) */
	C_KANJI_JIS_5224, /*  0x99a2 (U+52bc) */
	C_KANJI_JIS_5225, /*  0x99a3 (U+52b5) */
	C_KANJI_JIS_5226, /*  0x99a4 (U+52c1) */
	C_KANJI_JIS_5227, /*  0x99a5 (U+52cd) */
	C_KANJI_JIS_5228, /*  0x99a6 (U+52d7) */
	C_KANJI_JIS_5229, /*  0x99a7 (U+52de) */
	C_KANJI_JIS_522A, /*  0x99a8 (U+52e3) */
	C_KANJI_JIS_522B, /*  0x99a9 (U+52e6) */
	C_KANJI_JIS_522C, /*  0x99aa (U+98ed) */
	C_KANJI_JIS_522D, /*  0x99ab (U+52e0) */
	C_KANJI_JIS_522E, /*  0x99ac (U+52f3) */
	C_KANJI_JIS_522F, /*  0x99ad (U+52f5) */
	C_KANJI_JIS_5230, /*  0x99ae (U+52f8) */
	C_KANJI_JIS_5231, /*  0x99af (U+52f9) */
	C_KANJI_JIS_5232, /*  0x99b0 (U+5306) */
	C_KANJI_JIS_5233, /*  0x99b1 (U+5308) */
	C_KANJI_JIS_5234, /*  0x99b2 (U+7538) */
	C_KANJI_JIS_5235, /*  0x99b3 (U+530d) */
	C_KANJI_JIS_5236, /*  0x99b4 (U+5310) */
	C_KANJI_JIS_5237, /*  0x99b5 (U+530f) */
	C_KANJI_JIS_5238, /*  0x99b6 (U+5315) */
	C_KANJI_JIS_5239, /*  0x99b7 (U+531a) */
	C_KANJI_JIS_523A, /*  0x99b8 (U+5323) */
	C_KANJI_JIS_523B, /*  0x99b9 (U+532f) */
	C_KANJI_JIS_523C, /*  0x99ba (U+5331) */
	C_KANJI_JIS_523D, /*  0x99bb (U+5333) */
	C_KANJI_JIS_523E, /*  0x99bc (U+5338) */
	C_KANJI_JIS_523F, /*  0x99bd (U+5340) */
	C_KANJI_JIS_5240, /*  0x99be (U+5346) */
	C_KANJI_JIS_5241, /*  0x99bf (U+5345) */
	C_KANJI_JIS_5242, /*  0x99c0 (U+4e17) */
	C_KANJI_JIS_5243, /*  0x99c1 (U+5349) */
	C_KANJI_JIS_5244, /*  0x99c2 (U+534d) */
	C_KANJI_JIS_5245, /*  0x99c3 (U+51d6) */
	C_KANJI_JIS_5246, /*  0x99c4 (U+535e) */
	C_KANJI_JIS_5247, /*  0x99c5 (U+5369) */
	C_KANJI_JIS_5248, /*  0x99c6 (U+536e) */
	C_KANJI_JIS_5249, /*  0x99c7 (U+5918) */
	C_KANJI_JIS_524A, /*  0x99c8 (U+537b) */
	C_KANJI_JIS_524B, /*  0x99c9 (U+5377) */
	C_KANJI_JIS_524C, /*  0x99ca (U+5382) */
	C_KANJI_JIS_524D, /*  0x99cb (U+5396) */
	C_KANJI_JIS_524E, /*  0x99cc (U+53a0) */
	C_KANJI_JIS_524F, /*  0x99cd (U+53a6) */
	C_KANJI_JIS_5250, /*  0x99ce (U+53a5) */
	C_KANJI_JIS_5251, /*  0x99cf (U+53ae) */
	C_KANJI_JIS_5252, /*  0x99d0 (U+53b0) */
	C_KANJI_JIS_5253, /*  0x99d1 (U+53b6) */
	C_KANJI_JIS_5254, /*  0x99d2 (U+53c3) */
	C_KANJI_JIS_5255, /*  0x99d3 (U+7c12) */
	C_KANJI_JIS_5256, /*  0x99d4 (U+96d9) */
	C_KANJI_JIS_5257, /*  0x99d5 (U+53df) */
	C_KANJI_JIS_5258, /*  0x99d6 (U+66fc) */
	C_KANJI_JIS_5259, /*  0x99d7 (U+71ee) */
	C_KANJI_JIS_525A, /*  0x99d8 (U+53ee) */
	C_KANJI_JIS_525B, /*  0x99d9 (U+53e8) */
	C_KANJI_JIS_525C, /*  0x99da (U+53ed) */
	C_KANJI_JIS_525D, /*  0x99db (U+53fa) */
	C_KANJI_JIS_525E, /*  0x99dc (U+5401) */
	C_KANJI_JIS_525F, /*  0x99dd (U+543d) */
	C_KANJI_JIS_5260, /*  0x99de (U+5440) */
	C_KANJI_JIS_5261, /*  0x99df (U+542c) */
	C_KANJI_JIS_5262, /*  0x99e0 (U+542d) */
	C_KANJI_JIS_5263, /*  0x99e1 (U+543c) */
	C_KANJI_JIS_5264, /*  0x99e2 (U+542e) */
	C_KANJI_JIS_5265, /*  0x99e3 (U+5436) */
	C_KANJI_JIS_5266, /*  0x99e4 (U+5429) */
	C_KANJI_JIS_5267, /*  0x99e5 (U+541d) */
	C_KANJI_JIS_5268, /*  0x99e6 (U+544e) */
	C_KANJI_JIS_5269, /*  0x99e7 (U+548f) */
	C_KANJI_JIS_526A, /*  0x99e8 (U+5475) */
	C_KANJI_JIS_526B, /*  0x99e9 (U+548e) */
	C_KANJI_JIS_526C, /*  0x99ea (U+545f) */
	C_KANJI_JIS_526D, /*  0x99eb (U+5471) */
	C_KANJI_JIS_526E, /*  0x99ec (U+5477) */
	C_KANJI_JIS_526F, /*  0x99ed (U+5470) */
	C_KANJI_JIS_5270, /*  0x99ee (U+5492) */
	C_KANJI_JIS_5271, /*  0x99ef (U+547b) */
	C_KANJI_JIS_5272, /*  0x99f0 (U+5480) */
	C_KANJI_JIS_5273, /*  0x99f1 (U+5476) */
	C_KANJI_JIS_5274, /*  0x99f2 (U+5484) */
	C_KANJI_JIS_5275, /*  0x99f3 (U+5490) */
	C_KANJI_JIS_5276, /*  0x99f4 (U+5486) */
	C_KANJI_JIS_5277, /*  0x99f5 (U+54c7) */
	C_KANJI_JIS_5278, /*  0x99f6 (U+54a2) */
	C_KANJI_JIS_5279, /*  0x99f7 (U+54b8) */
	C_KANJI_JIS_527A, /*  0x99f8 (U+54a5) */
	C_KANJI_JIS_527B, /*  0x99f9 (U+54ac) */
	C_KANJI_JIS_527C, /*  0x99fa (U+54c4) */
	C_KANJI_JIS_527D, /*  0x99fb (U+54c8) */
	C_KANJI_JIS_527E, /*  0x99fc (U+54a8) */
	0, /*  0x99fd */
	0, /*  0x99fe */
	0, /*  0x99ff */
	C_KANJI_JIS_5321, /*  0x9a40 (U+54ab) */
	C_KANJI_JIS_5322, /*  0x9a41 (U+54c2) */
	C_KANJI_JIS_5323, /*  0x9a42 (U+54a4) */
	C_KANJI_JIS_5324, /*  0x9a43 (U+54be) */
	C_KANJI_JIS_5325, /*  0x9a44 (U+54bc) */
	C_KANJI_JIS_5326, /*  0x9a45 (U+54d8) */
	C_KANJI_JIS_5327, /*  0x9a46 (U+54e5) */
	C_KANJI_JIS_5328, /*  0x9a47 (U+54e6) */
	C_KANJI_JIS_5329, /*  0x9a48 (U+550f) */
	C_KANJI_JIS_532A, /*  0x9a49 (U+5514) */
	C_KANJI_JIS_532B, /*  0x9a4a (U+54fd) */
	C_KANJI_JIS_532C, /*  0x9a4b (U+54ee) */
	C_KANJI_JIS_532D, /*  0x9a4c (U+54ed) */
	C_KANJI_JIS_532E, /*  0x9a4d (U+54fa) */
	C_KANJI_JIS_532F, /*  0x9a4e (U+54e2) */
	C_KANJI_JIS_5330, /*  0x9a4f (U+5539) */
	C_KANJI_JIS_5331, /*  0x9a50 (U+5540) */
	C_KANJI_JIS_5332, /*  0x9a51 (U+5563) */
	C_KANJI_JIS_5333, /*  0x9a52 (U+554c) */
	C_KANJI_JIS_5334, /*  0x9a53 (U+552e) */
	C_KANJI_JIS_5335, /*  0x9a54 (U+555c) */
	C_KANJI_JIS_5336, /*  0x9a55 (U+5545) */
	C_KANJI_JIS_5337, /*  0x9a56 (U+5556) */
	C_KANJI_JIS_5338, /*  0x9a57 (U+5557) */
	C_KANJI_JIS_5339, /*  0x9a58 (U+5538) */
	C_KANJI_JIS_533A, /*  0x9a59 (U+5533) */
	C_KANJI_JIS_533B, /*  0x9a5a (U+555d) */
	C_KANJI_JIS_533C, /*  0x9a5b (U+5599) */
	C_KANJI_JIS_533D, /*  0x9a5c (U+5580) */
	C_KANJI_JIS_533E, /*  0x9a5d (U+54af) */
	C_KANJI_JIS_533F, /*  0x9a5e (U+558a) */
	C_KANJI_JIS_5340, /*  0x9a5f (U+559f) */
	C_KANJI_JIS_5341, /*  0x9a60 (U+557b) */
	C_KANJI_JIS_5342, /*  0x9a61 (U+557e) */
	C_KANJI_JIS_5343, /*  0x9a62 (U+5598) */
	C_KANJI_JIS_5344, /*  0x9a63 (U+559e) */
	C_KANJI_JIS_5345, /*  0x9a64 (U+55ae) */
	C_KANJI_JIS_5346, /*  0x9a65 (U+557c) */
	C_KANJI_JIS_5347, /*  0x9a66 (U+5583) */
	C_KANJI_JIS_5348, /*  0x9a67 (U+55a9) */
	C_KANJI_JIS_5349, /*  0x9a68 (U+5587) */
	C_KANJI_JIS_534A, /*  0x9a69 (U+55a8) */
	C_KANJI_JIS_534B, /*  0x9a6a (U+55da) */
	C_KANJI_JIS_534C, /*  0x9a6b (U+55c5) */
	C_KANJI_JIS_534D, /*  0x9a6c (U+55df) */
	C_KANJI_JIS_534E, /*  0x9a6d (U+55c4) */
	C_KANJI_JIS_534F, /*  0x9a6e (U+55dc) */
	C_KANJI_JIS_5350, /*  0x9a6f (U+55e4) */
	C_KANJI_JIS_5351, /*  0x9a70 (U+55d4) */
	C_KANJI_JIS_5352, /*  0x9a71 (U+5614) */
	C_KANJI_JIS_5353, /*  0x9a72 (U+55f7) */
	C_KANJI_JIS_5354, /*  0x9a73 (U+5616) */
	C_KANJI_JIS_5355, /*  0x9a74 (U+55fe) */
	C_KANJI_JIS_5356, /*  0x9a75 (U+55fd) */
	C_KANJI_JIS_5357, /*  0x9a76 (U+561b) */
	C_KANJI_JIS_5358, /*  0x9a77 (U+55f9) */
	C_KANJI_JIS_5359, /*  0x9a78 (U+564e) */
	C_KANJI_JIS_535A, /*  0x9a79 (U+5650) */
	C_KANJI_JIS_535B, /*  0x9a7a (U+71df) */
	C_KANJI_JIS_535C, /*  0x9a7b (U+5634) */
	C_KANJI_JIS_535D, /*  0x9a7c (U+5636) */
	C_KANJI_JIS_535E, /*  0x9a7d (U+5632) */
	C_KANJI_JIS_535F, /*  0x9a7e (U+5638) */
	0, /*  0x9a7f */
	C_KANJI_JIS_5360, /*  0x9a80 (U+566b) */
	C_KANJI_JIS_5361, /*  0x9a81 (U+5664) */
	C_KANJI_JIS_5362, /*  0x9a82 (U+562f) */
	C_KANJI_JIS_5363, /*  0x9a83 (U+566c) */
	C_KANJI_JIS_5364, /*  0x9a84 (U+566a) */
	C_KANJI_JIS_5365, /*  0x9a85 (U+5686) */
	C_KANJI_JIS_5366, /*  0x9a86 (U+5680) */
	C_KANJI_JIS_5367, /*  0x9a87 (U+568a) */
	C_KANJI_JIS_5368, /*  0x9a88 (U+56a0) */
	C_KANJI_JIS_5369, /*  0x9a89 (U+5694) */
	C_KANJI_JIS_536A, /*  0x9a8a (U+568f) */
	C_KANJI_JIS_536B, /*  0x9a8b (U+56a5) */
	C_KANJI_JIS_536C, /*  0x9a8c (U+56ae) */
	C_KANJI_JIS_536D, /*  0x9a8d (U+56b6) */
	C_KANJI_JIS_536E, /*  0x9a8e (U+56b4) */
	C_KANJI_JIS_536F, /*  0x9a8f (U+56c2) */
	C_KANJI_JIS_5370, /*  0x9a90 (U+56bc) */
	C_KANJI_JIS_5371, /*  0x9a91 (U+56c1) */
	C_KANJI_JIS_5372, /*  0x9a92 (U+56c3) */
	C_KANJI_JIS_5373, /*  0x9a93 (U+56c0) */
	C_KANJI_JIS_5374, /*  0x9a94 (U+56c8) */
	C_KANJI_JIS_5375, /*  0x9a95 (U+56ce) */
	C_KANJI_JIS_5376, /*  0x9a96 (U+56d1) */
	C_KANJI_JIS_5377, /*  0x9a97 (U+56d3) */
	C_KANJI_JIS_5378, /*  0x9a98 (U+56d7) */
	C_KANJI_JIS_5379, /*  0x9a99 (U+56ee) */
	C_KANJI_JIS_537A, /*  0x9a9a (U+56f9) */
	C_KANJI_JIS_537B, /*  0x9a9b (U+5700) */
	C_KANJI_JIS_537C, /*  0x9a9c (U+56ff) */
	C_KANJI_JIS_537D, /*  0x9a9d (U+5704) */
	C_KANJI_JIS_537E, /*  0x9a9e (U+5709) */
	C_KANJI_JIS_5421, /*  0x9a9f (U+5708) */
	C_KANJI_JIS_5422, /*  0x9aa0 (U+570b) */
	C_KANJI_JIS_5423, /*  0x9aa1 (U+570d) */
	C_KANJI_JIS_5424, /*  0x9aa2 (U+5713) */
	C_KANJI_JIS_5425, /*  0x9aa3 (U+5718) */
	C_KANJI_JIS_5426, /*  0x9aa4 (U+5716) */
	C_KANJI_JIS_5427, /*  0x9aa5 (U+55c7) */
	C_KANJI_JIS_5428, /*  0x9aa6 (U+571c) */
	C_KANJI_JIS_5429, /*  0x9aa7 (U+5726) */
	C_KANJI_JIS_542A, /*  0x9aa8 (U+5737) */
	C_KANJI_JIS_542B, /*  0x9aa9 (U+5738) */
	C_KANJI_JIS_542C, /*  0x9aaa (U+574e) */
	C_KANJI_JIS_542D, /*  0x9aab (U+573b) */
	C_KANJI_JIS_542E, /*  0x9aac (U+5740) */
	C_KANJI_JIS_542F, /*  0x9aad (U+574f) */
	C_KANJI_JIS_5430, /*  0x9aae (U+5769) */
	C_KANJI_JIS_5431, /*  0x9aaf (U+57c0) */
	C_KANJI_JIS_5432, /*  0x9ab0 (U+5788) */
	C_KANJI_JIS_5433, /*  0x9ab1 (U+5761) */
	C_KANJI_JIS_5434, /*  0x9ab2 (U+577f) */
	C_KANJI_JIS_5435, /*  0x9ab3 (U+5789) */
	C_KANJI_JIS_5436, /*  0x9ab4 (U+5793) */
	C_KANJI_JIS_5437, /*  0x9ab5 (U+57a0) */
	C_KANJI_JIS_5438, /*  0x9ab6 (U+57b3) */
	C_KANJI_JIS_5439, /*  0x9ab7 (U+57a4) */
	C_KANJI_JIS_543A, /*  0x9ab8 (U+57aa) */
	C_KANJI_JIS_543B, /*  0x9ab9 (U+57b0) */
	C_KANJI_JIS_543C, /*  0x9aba (U+57c3) */
	C_KANJI_JIS_543D, /*  0x9abb (U+57c6) */
	C_KANJI_JIS_543E, /*  0x9abc (U+57d4) */
	C_KANJI_JIS_543F, /*  0x9abd (U+57d2) */
	C_KANJI_JIS_5440, /*  0x9abe (U+57d3) */
	C_KANJI_JIS_5441, /*  0x9abf (U+580a) */
	C_KANJI_JIS_5442, /*  0x9ac0 (U+57d6) */
	C_KANJI_JIS_5443, /*  0x9ac1 (U+57e3) */
	C_KANJI_JIS_5444, /*  0x9ac2 (U+580b) */
	C_KANJI_JIS_5445, /*  0x9ac3 (U+5819) */
	C_KANJI_JIS_5446, /*  0x9ac4 (U+581d) */
	C_KANJI_JIS_5447, /*  0x9ac5 (U+5872) */
	C_KANJI_JIS_5448, /*  0x9ac6 (U+5821) */
	C_KANJI_JIS_5449, /*  0x9ac7 (U+5862) */
	C_KANJI_JIS_544A, /*  0x9ac8 (U+584b) */
	C_KANJI_JIS_544B, /*  0x9ac9 (U+5870) */
	C_KANJI_JIS_544C, /*  0x9aca (U+6bc0) */
	C_KANJI_JIS_544D, /*  0x9acb (U+5852) */
	C_KANJI_JIS_544E, /*  0x9acc (U+583d) */
	C_KANJI_JIS_544F, /*  0x9acd (U+5879) */
	C_KANJI_JIS_5450, /*  0x9ace (U+5885) */
	C_KANJI_JIS_5451, /*  0x9acf (U+58b9) */
	C_KANJI_JIS_5452, /*  0x9ad0 (U+589f) */
	C_KANJI_JIS_5453, /*  0x9ad1 (U+58ab) */
	C_KANJI_JIS_5454, /*  0x9ad2 (U+58ba) */
	C_KANJI_JIS_5455, /*  0x9ad3 (U+58de) */
	C_KANJI_JIS_5456, /*  0x9ad4 (U+58bb) */
	C_KANJI_JIS_5457, /*  0x9ad5 (U+58b8) */
	C_KANJI_JIS_5458, /*  0x9ad6 (U+58ae) */
	C_KANJI_JIS_5459, /*  0x9ad7 (U+58c5) */
	C_KANJI_JIS_545A, /*  0x9ad8 (U+58d3) */
	C_KANJI_JIS_545B, /*  0x9ad9 (U+58d1) */
	C_KANJI_JIS_545C, /*  0x9ada (U+58d7) */
	C_KANJI_JIS_545D, /*  0x9adb (U+58d9) */
	C_KANJI_JIS_545E, /*  0x9adc (U+58d8) */
	C_KANJI_JIS_545F, /*  0x9add (U+58e5) */
	C_KANJI_JIS_5460, /*  0x9ade (U+58dc) */
	C_KANJI_JIS_5461, /*  0x9adf (U+58e4) */
	C_KANJI_JIS_5462, /*  0x9ae0 (U+58df) */
	C_KANJI_JIS_5463, /*  0x9ae1 (U+58ef) */
	C_KANJI_JIS_5464, /*  0x9ae2 (U+58fa) */
	C_KANJI_JIS_5465, /*  0x9ae3 (U+58f9) */
	C_KANJI_JIS_5466, /*  0x9ae4 (U+58fb) */
	C_KANJI_JIS_5467, /*  0x9ae5 (U+58fc) */
	C_KANJI_JIS_5468, /*  0x9ae6 (U+58fd) */
	C_KANJI_JIS_5469, /*  0x9ae7 (U+5902) */
	C_KANJI_JIS_546A, /*  0x9ae8 (U+590a) */
	C_KANJI_JIS_546B, /*  0x9ae9 (U+5910) */
	C_KANJI_JIS_546C, /*  0x9aea (U+591b) */
	C_KANJI_JIS_546D, /*  0x9aeb (U+68a6) */
	C_KANJI_JIS_546E, /*  0x9aec (U+5925) */
	C_KANJI_JIS_546F, /*  0x9aed (U+592c) */
	C_KANJI_JIS_5470, /*  0x9aee (U+592d) */
	C_KANJI_JIS_5471, /*  0x9aef (U+5932) */
	C_KANJI_JIS_5472, /*  0x9af0 (U+5938) */
	C_KANJI_JIS_5473, /*  0x9af1 (U+593e) */
	C_KANJI_JIS_5474, /*  0x9af2 (U+7ad2) */
	C_KANJI_JIS_5475, /*  0x9af3 (U+5955) */
	C_KANJI_JIS_5476, /*  0x9af4 (U+5950) */
	C_KANJI_JIS_5477, /*  0x9af5 (U+594e) */
	C_KANJI_JIS_5478, /*  0x9af6 (U+595a) */
	C_KANJI_JIS_5479, /*  0x9af7 (U+5958) */
	C_KANJI_JIS_547A, /*  0x9af8 (U+5962) */
	C_KANJI_JIS_547B, /*  0x9af9 (U+5960) */
	C_KANJI_JIS_547C, /*  0x9afa (U+5967) */
	C_KANJI_JIS_547D, /*  0x9afb (U+596c) */
	C_KANJI_JIS_547E, /*  0x9afc (U+5969) */
	0, /*  0x9afd */
	0, /*  0x9afe */
	0, /*  0x9aff */
	C_KANJI_JIS_5521, /*  0x9b40 (U+5978) */
	C_KANJI_JIS_5522, /*  0x9b41 (U+5981) */
	C_KANJI_JIS_5523, /*  0x9b42 (U+599d) */
	C_KANJI_JIS_5524, /*  0x9b43 (U+4f5e) */
	C_KANJI_JIS_5525, /*  0x9b44 (U+4fab) */
	C_KANJI_JIS_5526, /*  0x9b45 (U+59a3) */
	C_KANJI_JIS_5527, /*  0x9b46 (U+59b2) */
	C_KANJI_JIS_5528, /*  0x9b47 (U+59c6) */
	C_KANJI_JIS_5529, /*  0x9b48 (U+59e8) */
	C_KANJI_JIS_552A, /*  0x9b49 (U+59dc) */
	C_KANJI_JIS_552B, /*  0x9b4a (U+598d) */
	C_KANJI_JIS_552C, /*  0x9b4b (U+59d9) */
	C_KANJI_JIS_552D, /*  0x9b4c (U+59da) */
	C_KANJI_JIS_552E, /*  0x9b4d (U+5a25) */
	C_KANJI_JIS_552F, /*  0x9b4e (U+5a1f) */
	C_KANJI_JIS_5530, /*  0x9b4f (U+5a11) */
	C_KANJI_JIS_5531, /*  0x9b50 (U+5a1c) */
	C_KANJI_JIS_5532, /*  0x9b51 (U+5a09) */
	C_KANJI_JIS_5533, /*  0x9b52 (U+5a1a) */
	C_KANJI_JIS_5534, /*  0x9b53 (U+5a40) */
	C_KANJI_JIS_5535, /*  0x9b54 (U+5a6c) */
	C_KANJI_JIS_5536, /*  0x9b55 (U+5a49) */
	C_KANJI_JIS_5537, /*  0x9b56 (U+5a35) */
	C_KANJI_JIS_5538, /*  0x9b57 (U+5a36) */
	C_KANJI_JIS_5539, /*  0x9b58 (U+5a62) */
	C_KANJI_JIS_553A, /*  0x9b59 (U+5a6a) */
	C_KANJI_JIS_553B, /*  0x9b5a (U+5a9a) */
	C_KANJI_JIS_553C, /*  0x9b5b (U+5abc) */
	C_KANJI_JIS_553D, /*  0x9b5c (U+5abe) */
	C_KANJI_JIS_553E, /*  0x9b5d (U+5acb) */
	C_KANJI_JIS_553F, /*  0x9b5e (U+5ac2) */
	C_KANJI_JIS_5540, /*  0x9b5f (U+5abd) */
	C_KANJI_JIS_5541, /*  0x9b60 (U+5ae3) */
	C_KANJI_JIS_5542, /*  0x9b61 (U+5ad7) */
	C_KANJI_JIS_5543, /*  0x9b62 (U+5ae6) */
	C_KANJI_JIS_5544, /*  0x9b63 (U+5ae9) */
	C_KANJI_JIS_5545, /*  0x9b64 (U+5ad6) */
	C_KANJI_JIS_5546, /*  0x9b65 (U+5afa) */
	C_KANJI_JIS_5547, /*  0x9b66 (U+5afb) */
	C_KANJI_JIS_5548, /*  0x9b67 (U+5b0c) */
	C_KANJI_JIS_5549, /*  0x9b68 (U+5b0b) */
	C_KANJI_JIS_554A, /*  0x9b69 (U+5b16) */
	C_KANJI_JIS_554B, /*  0x9b6a (U+5b32) */
	C_KANJI_JIS_554C, /*  0x9b6b (U+5ad0) */
	C_KANJI_JIS_554D, /*  0x9b6c (U+5b2a) */
	C_KANJI_JIS_554E, /*  0x9b6d (U+5b36) */
	C_KANJI_JIS_554F, /*  0x9b6e (U+5b3e) */
	C_KANJI_JIS_5550, /*  0x9b6f (U+5b43) */
	C_KANJI_JIS_5551, /*  0x9b70 (U+5b45) */
	C_KANJI_JIS_5552, /*  0x9b71 (U+5b40) */
	C_KANJI_JIS_5553, /*  0x9b72 (U+5b51) */
	C_KANJI_JIS_5554, /*  0x9b73 (U+5b55) */
	C_KANJI_JIS_5555, /*  0x9b74 (U+5b5a) */
	C_KANJI_JIS_5556, /*  0x9b75 (U+5b5b) */
	C_KANJI_JIS_5557, /*  0x9b76 (U+5b65) */
	C_KANJI_JIS_5558, /*  0x9b77 (U+5b69) */
	C_KANJI_JIS_5559, /*  0x9b78 (U+5b70) */
	C_KANJI_JIS_555A, /*  0x9b79 (U+5b73) */
	C_KANJI_JIS_555B, /*  0x9b7a (U+5b75) */
	C_KANJI_JIS_555C, /*  0x9b7b (U+5b78) */
	C_KANJI_JIS_555D, /*  0x9b7c (U+6588) */
	C_KANJI_JIS_555E, /*  0x9b7d (U+5b7a) */
	C_KANJI_JIS_555F, /*  0x9b7e (U+5b80) */
	0, /*  0x9b7f */
	C_KANJI_JIS_5560, /*  0x9b80 (U+5b83) */
	C_KANJI_JIS_5561, /*  0x9b81 (U+5ba6) */
	C_KANJI_JIS_5562, /*  0x9b82 (U+5bb8) */
	C_KANJI_JIS_5563, /*  0x9b83 (U+5bc3) */
	C_KANJI_JIS_5564, /*  0x9b84 (U+5bc7) */
	C_KANJI_JIS_5565, /*  0x9b85 (U+5bc9) */
	C_KANJI_JIS_5566, /*  0x9b86 (U+5bd4) */
	C_KANJI_JIS_5567, /*  0x9b87 (U+5bd0) */
	C_KANJI_JIS_5568, /*  0x9b88 (U+5be4) */
	C_KANJI_JIS_5569, /*  0x9b89 (U+5be6) */
	C_KANJI_JIS_556A, /*  0x9b8a (U+5be2) */
	C_KANJI_JIS_556B, /*  0x9b8b (U+5bde) */
	C_KANJI_JIS_556C, /*  0x9b8c (U+5be5) */
	C_KANJI_JIS_556D, /*  0x9b8d (U+5beb) */
	C_KANJI_JIS_556E, /*  0x9b8e (U+5bf0) */
	C_KANJI_JIS_556F, /*  0x9b8f (U+5bf6) */
	C_KANJI_JIS_5570, /*  0x9b90 (U+5bf3) */
	C_KANJI_JIS_5571, /*  0x9b91 (U+5c05) */
	C_KANJI_JIS_5572, /*  0x9b92 (U+5c07) */
	C_KANJI_JIS_5573, /*  0x9b93 (U+5c08) */
	C_KANJI_JIS_5574, /*  0x9b94 (U+5c0d) */
	C_KANJI_JIS_5575, /*  0x9b95 (U+5c13) */
	C_KANJI_JIS_5576, /*  0x9b96 (U+5c20) */
	C_KANJI_JIS_5577, /*  0x9b97 (U+5c22) */
	C_KANJI_JIS_5578, /*  0x9b98 (U+5c28) */
	C_KANJI_JIS_5579, /*  0x9b99 (U+5c38) */
	C_KANJI_JIS_557A, /*  0x9b9a (U+5c39) */
	C_KANJI_JIS_557B, /*  0x9b9b (U+5c41) */
	C_KANJI_JIS_557C, /*  0x9b9c (U+5c46) */
	C_KANJI_JIS_557D, /*  0x9b9d (U+5c4e) */
	C_KANJI_JIS_557E, /*  0x9b9e (U+5c53) */
	C_KANJI_JIS_5621, /*  0x9b9f (U+5c50) */
	C_KANJI_JIS_5622, /*  0x9ba0 (U+5c4f) */
	C_KANJI_JIS_5623, /*  0x9ba1 (U+5b71) */
	C_KANJI_JIS_5624, /*  0x9ba2 (U+5c6c) */
	C_KANJI_JIS_5625, /*  0x9ba3 (U+5c6e) */
	C_KANJI_JIS_5626, /*  0x9ba4 (U+4e62) */
	C_KANJI_JIS_5627, /*  0x9ba5 (U+5c76) */
	C_KANJI_JIS_5628, /*  0x9ba6 (U+5c79) */
	C_KANJI_JIS_5629, /*  0x9ba7 (U+5c8c) */
	C_KANJI_JIS_562A, /*  0x9ba8 (U+5c91) */
	C_KANJI_JIS_562B, /*  0x9ba9 (U+5c94) */
	C_KANJI_JIS_562C, /*  0x9baa (U+599b) */
	C_KANJI_JIS_562D, /*  0x9bab (U+5cab) */
	C_KANJI_JIS_562E, /*  0x9bac (U+5cbb) */
	C_KANJI_JIS_562F, /*  0x9bad (U+5cb6) */
	C_KANJI_JIS_5630, /*  0x9bae (U+5cbc) */
	C_KANJI_JIS_5631, /*  0x9baf (U+5cb7) */
	C_KANJI_JIS_5632, /*  0x9bb0 (U+5cc5) */
	C_KANJI_JIS_5633, /*  0x9bb1 (U+5cbe) */
	C_KANJI_JIS_5634, /*  0x9bb2 (U+5cc7) */
	C_KANJI_JIS_5635, /*  0x9bb3 (U+5cd9) */
	C_KANJI_JIS_5636, /*  0x9bb4 (U+5ce9) */
	C_KANJI_JIS_5637, /*  0x9bb5 (U+5cfd) */
	C_KANJI_JIS_5638, /*  0x9bb6 (U+5cfa) */
	C_KANJI_JIS_5639, /*  0x9bb7 (U+5ced) */
	C_KANJI_JIS_563A, /*  0x9bb8 (U+5d8c) */
	C_KANJI_JIS_563B, /*  0x9bb9 (U+5cea) */
	C_KANJI_JIS_563C, /*  0x9bba (U+5d0b) */
	C_KANJI_JIS_563D, /*  0x9bbb (U+5d15) */
	C_KANJI_JIS_563E, /*  0x9bbc (U+5d17) */
	C_KANJI_JIS_563F, /*  0x9bbd (U+5d5c) */
	C_KANJI_JIS_5640, /*  0x9bbe (U+5d1f) */
	C_KANJI_JIS_5641, /*  0x9bbf (U+5d1b) */
	C_KANJI_JIS_5642, /*  0x9bc0 (U+5d11) */
	C_KANJI_JIS_5643, /*  0x9bc1 (U+5d14) */
	C_KANJI_JIS_5644, /*  0x9bc2 (U+5d22) */
	C_KANJI_JIS_5645, /*  0x9bc3 (U+5d1a) */
	C_KANJI_JIS_5646, /*  0x9bc4 (U+5d19) */
	C_KANJI_JIS_5647, /*  0x9bc5 (U+5d18) */
	C_KANJI_JIS_5648, /*  0x9bc6 (U+5d4c) */
	C_KANJI_JIS_5649, /*  0x9bc7 (U+5d52) */
	C_KANJI_JIS_564A, /*  0x9bc8 (U+5d4e) */
	C_KANJI_JIS_564B, /*  0x9bc9 (U+5d4b) */
	C_KANJI_JIS_564C, /*  0x9bca (U+5d6c) */
	C_KANJI_JIS_564D, /*  0x9bcb (U+5d73) */
	C_KANJI_JIS_564E, /*  0x9bcc (U+5d76) */
	C_KANJI_JIS_564F, /*  0x9bcd (U+5d87) */
	C_KANJI_JIS_5650, /*  0x9bce (U+5d84) */
	C_KANJI_JIS_5651, /*  0x9bcf (U+5d82) */
	C_KANJI_JIS_5652, /*  0x9bd0 (U+5da2) */
	C_KANJI_JIS_5653, /*  0x9bd1 (U+5d9d) */
	C_KANJI_JIS_5654, /*  0x9bd2 (U+5dac) */
	C_KANJI_JIS_5655, /*  0x9bd3 (U+5dae) */
	C_KANJI_JIS_5656, /*  0x9bd4 (U+5dbd) */
	C_KANJI_JIS_5657, /*  0x9bd5 (U+5d90) */
	C_KANJI_JIS_5658, /*  0x9bd6 (U+5db7) */
	C_KANJI_JIS_5659, /*  0x9bd7 (U+5dbc) */
	C_KANJI_JIS_565A, /*  0x9bd8 (U+5dc9) */
	C_KANJI_JIS_565B, /*  0x9bd9 (U+5dcd) */
	C_KANJI_JIS_565C, /*  0x9bda (U+5dd3) */
	C_KANJI_JIS_565D, /*  0x9bdb (U+5dd2) */
	C_KANJI_JIS_565E, /*  0x9bdc (U+5dd6) */
	C_KANJI_JIS_565F, /*  0x9bdd (U+5ddb) */
	C_KANJI_JIS_5660, /*  0x9bde (U+5deb) */
	C_KANJI_JIS_5661, /*  0x9bdf (U+5df2) */
	C_KANJI_JIS_5662, /*  0x9be0 (U+5df5) */
	C_KANJI_JIS_5663, /*  0x9be1 (U+5e0b) */
	C_KANJI_JIS_5664, /*  0x9be2 (U+5e1a) */
	C_KANJI_JIS_5665, /*  0x9be3 (U+5e19) */
	C_KANJI_JIS_5666, /*  0x9be4 (U+5e11) */
	C_KANJI_JIS_5667, /*  0x9be5 (U+5e1b) */
	C_KANJI_JIS_5668, /*  0x9be6 (U+5e36) */
	C_KANJI_JIS_5669, /*  0x9be7 (U+5e37) */
	C_KANJI_JIS_566A, /*  0x9be8 (U+5e44) */
	C_KANJI_JIS_566B, /*  0x9be9 (U+5e43) */
	C_KANJI_JIS_566C, /*  0x9bea (U+5e40) */
	C_KANJI_JIS_566D, /*  0x9beb (U+5e4e) */
	C_KANJI_JIS_566E, /*  0x9bec (U+5e57) */
	C_KANJI_JIS_566F, /*  0x9bed (U+5e54) */
	C_KANJI_JIS_5670, /*  0x9bee (U+5e5f) */
	C_KANJI_JIS_5671, /*  0x9bef (U+5e62) */
	C_KANJI_JIS_5672, /*  0x9bf0 (U+5e64) */
	C_KANJI_JIS_5673, /*  0x9bf1 (U+5e47) */
	C_KANJI_JIS_5674, /*  0x9bf2 (U+5e75) */
	C_KANJI_JIS_5675, /*  0x9bf3 (U+5e76) */
	C_KANJI_JIS_5676, /*  0x9bf4 (U+5e7a) */
	C_KANJI_JIS_5677, /*  0x9bf5 (U+9ebc) */
	C_KANJI_JIS_5678, /*  0x9bf6 (U+5e7f) */
	C_KANJI_JIS_5679, /*  0x9bf7 (U+5ea0) */
	C_KANJI_JIS_567A, /*  0x9bf8 (U+5ec1) */
	C_KANJI_JIS_567B, /*  0x9bf9 (U+5ec2) */
	C_KANJI_JIS_567C, /*  0x9bfa (U+5ec8) */
	C_KANJI_JIS_567D, /*  0x9bfb (U+5ed0) */
	C_KANJI_JIS_567E, /*  0x9bfc (U+5ecf) */
	0, /*  0x9bfd */
	0, /*  0x9bfe */
	0, /*  0x9bff */
	C_KANJI_JIS_5721, /*  0x9c40 (U+5ed6) */
	C_KANJI_JIS_5722, /*  0x9c41 (U+5ee3) */
	C_KANJI_JIS_5723, /*  0x9c42 (U+5edd) */
	C_KANJI_JIS_5724, /*  0x9c43 (U+5eda) */
	C_KANJI_JIS_5725, /*  0x9c44 (U+5edb) */
	C_KANJI_JIS_5726, /*  0x9c45 (U+5ee2) */
	C_KANJI_JIS_5727, /*  0x9c46 (U+5ee1) */
	C_KANJI_JIS_5728, /*  0x9c47 (U+5ee8) */
	C_KANJI_JIS_5729, /*  0x9c48 (U+5ee9) */
	C_KANJI_JIS_572A, /*  0x9c49 (U+5eec) */
	C_KANJI_JIS_572B, /*  0x9c4a (U+5ef1) */
	C_KANJI_JIS_572C, /*  0x9c4b (U+5ef3) */
	C_KANJI_JIS_572D, /*  0x9c4c (U+5ef0) */
	C_KANJI_JIS_572E, /*  0x9c4d (U+5ef4) */
	C_KANJI_JIS_572F, /*  0x9c4e (U+5ef8) */
	C_KANJI_JIS_5730, /*  0x9c4f (U+5efe) */
	C_KANJI_JIS_5731, /*  0x9c50 (U+5f03) */
	C_KANJI_JIS_5732, /*  0x9c51 (U+5f09) */
	C_KANJI_JIS_5733, /*  0x9c52 (U+5f5d) */
	C_KANJI_JIS_5734, /*  0x9c53 (U+5f5c) */
	C_KANJI_JIS_5735, /*  0x9c54 (U+5f0b) */
	C_KANJI_JIS_5736, /*  0x9c55 (U+5f11) */
	C_KANJI_JIS_5737, /*  0x9c56 (U+5f16) */
	C_KANJI_JIS_5738, /*  0x9c57 (U+5f29) */
	C_KANJI_JIS_5739, /*  0x9c58 (U+5f2d) */
	C_KANJI_JIS_573A, /*  0x9c59 (U+5f38) */
	C_KANJI_JIS_573B, /*  0x9c5a (U+5f41) */
	C_KANJI_JIS_573C, /*  0x9c5b (U+5f48) */
	C_KANJI_JIS_573D, /*  0x9c5c (U+5f4c) */
	C_KANJI_JIS_573E, /*  0x9c5d (U+5f4e) */
	C_KANJI_JIS_573F, /*  0x9c5e (U+5f2f) */
	C_KANJI_JIS_5740, /*  0x9c5f (U+5f51) */
	C_KANJI_JIS_5741, /*  0x9c60 (U+5f56) */
	C_KANJI_JIS_5742, /*  0x9c61 (U+5f57) */
	C_KANJI_JIS_5743, /*  0x9c62 (U+5f59) */
	C_KANJI_JIS_5744, /*  0x9c63 (U+5f61) */
	C_KANJI_JIS_5745, /*  0x9c64 (U+5f6d) */
	C_KANJI_JIS_5746, /*  0x9c65 (U+5f73) */
	C_KANJI_JIS_5747, /*  0x9c66 (U+5f77) */
	C_KANJI_JIS_5748, /*  0x9c67 (U+5f83) */
	C_KANJI_JIS_5749, /*  0x9c68 (U+5f82) */
	C_KANJI_JIS_574A, /*  0x9c69 (U+5f7f) */
	C_KANJI_JIS_574B, /*  0x9c6a (U+5f8a) */
	C_KANJI_JIS_574C, /*  0x9c6b (U+5f88) */
	C_KANJI_JIS_574D, /*  0x9c6c (U+5f91) */
	C_KANJI_JIS_574E, /*  0x9c6d (U+5f87) */
	C_KANJI_JIS_574F, /*  0x9c6e (U+5f9e) */
	C_KANJI_JIS_5750, /*  0x9c6f (U+5f99) */
	C_KANJI_JIS_5751, /*  0x9c70 (U+5f98) */
	C_KANJI_JIS_5752, /*  0x9c71 (U+5fa0) */
	C_KANJI_JIS_5753, /*  0x9c72 (U+5fa8) */
	C_KANJI_JIS_5754, /*  0x9c73 (U+5fad) */
	C_KANJI_JIS_5755, /*  0x9c74 (U+5fbc) */
	C_KANJI_JIS_5756, /*  0x9c75 (U+5fd6) */
	C_KANJI_JIS_5757, /*  0x9c76 (U+5ffb) */
	C_KANJI_JIS_5758, /*  0x9c77 (U+5fe4) */
	C_KANJI_JIS_5759, /*  0x9c78 (U+5ff8) */
	C_KANJI_JIS_575A, /*  0x9c79 (U+5ff1) */
	C_KANJI_JIS_575B, /*  0x9c7a (U+5fdd) */
	C_KANJI_JIS_575C, /*  0x9c7b (U+60b3) */
	C_KANJI_JIS_575D, /*  0x9c7c (U+5fff) */
	C_KANJI_JIS_575E, /*  0x9c7d (U+6021) */
	C_KANJI_JIS_575F, /*  0x9c7e (U+6060) */
	0, /*  0x9c7f */
	C_KANJI_JIS_5760, /*  0x9c80 (U+6019) */
	C_KANJI_JIS_5761, /*  0x9c81 (U+6010) */
	C_KANJI_JIS_5762, /*  0x9c82 (U+6029) */
	C_KANJI_JIS_5763, /*  0x9c83 (U+600e) */
	C_KANJI_JIS_5764, /*  0x9c84 (U+6031) */
	C_KANJI_JIS_5765, /*  0x9c85 (U+601b) */
	C_KANJI_JIS_5766, /*  0x9c86 (U+6015) */
	C_KANJI_JIS_5767, /*  0x9c87 (U+602b) */
	C_KANJI_JIS_5768, /*  0x9c88 (U+6026) */
	C_KANJI_JIS_5769, /*  0x9c89 (U+600f) */
	C_KANJI_JIS_576A, /*  0x9c8a (U+603a) */
	C_KANJI_JIS_576B, /*  0x9c8b (U+605a) */
	C_KANJI_JIS_576C, /*  0x9c8c (U+6041) */
	C_KANJI_JIS_576D, /*  0x9c8d (U+606a) */
	C_KANJI_JIS_576E, /*  0x9c8e (U+6077) */
	C_KANJI_JIS_576F, /*  0x9c8f (U+605f) */
	C_KANJI_JIS_5770, /*  0x9c90 (U+604a) */
	C_KANJI_JIS_5771, /*  0x9c91 (U+6046) */
	C_KANJI_JIS_5772, /*  0x9c92 (U+604d) */
	C_KANJI_JIS_5773, /*  0x9c93 (U+6063) */
	C_KANJI_JIS_5774, /*  0x9c94 (U+6043) */
	C_KANJI_JIS_5775, /*  0x9c95 (U+6064) */
	C_KANJI_JIS_5776, /*  0x9c96 (U+6042) */
	C_KANJI_JIS_5777, /*  0x9c97 (U+606c) */
	C_KANJI_JIS_5778, /*  0x9c98 (U+606b) */
	C_KANJI_JIS_5779, /*  0x9c99 (U+6059) */
	C_KANJI_JIS_577A, /*  0x9c9a (U+6081) */
	C_KANJI_JIS_577B, /*  0x9c9b (U+608d) */
	C_KANJI_JIS_577C, /*  0x9c9c (U+60e7) */
	C_KANJI_JIS_577D, /*  0x9c9d (U+6083) */
	C_KANJI_JIS_577E, /*  0x9c9e (U+609a) */
	C_KANJI_JIS_5821, /*  0x9c9f (U+6084) */
	C_KANJI_JIS_5822, /*  0x9ca0 (U+609b) */
	C_KANJI_JIS_5823, /*  0x9ca1 (U+6096) */
	C_KANJI_JIS_5824, /*  0x9ca2 (U+6097) */
	C_KANJI_JIS_5825, /*  0x9ca3 (U+6092) */
	C_KANJI_JIS_5826, /*  0x9ca4 (U+60a7) */
	C_KANJI_JIS_5827, /*  0x9ca5 (U+608b) */
	C_KANJI_JIS_5828, /*  0x9ca6 (U+60e1) */
	C_KANJI_JIS_5829, /*  0x9ca7 (U+60b8) */
	C_KANJI_JIS_582A, /*  0x9ca8 (U+60e0) */
	C_KANJI_JIS_582B, /*  0x9ca9 (U+60d3) */
	C_KANJI_JIS_582C, /*  0x9caa (U+60b4) */
	C_KANJI_JIS_582D, /*  0x9cab (U+5ff0) */
	C_KANJI_JIS_582E, /*  0x9cac (U+60bd) */
	C_KANJI_JIS_582F, /*  0x9cad (U+60c6) */
	C_KANJI_JIS_5830, /*  0x9cae (U+60b5) */
	C_KANJI_JIS_5831, /*  0x9caf (U+60d8) */
	C_KANJI_JIS_5832, /*  0x9cb0 (U+614d) */
	C_KANJI_JIS_5833, /*  0x9cb1 (U+6115) */
	C_KANJI_JIS_5834, /*  0x9cb2 (U+6106) */
	C_KANJI_JIS_5835, /*  0x9cb3 (U+60f6) */
	C_KANJI_JIS_5836, /*  0x9cb4 (U+60f7) */
	C_KANJI_JIS_5837, /*  0x9cb5 (U+6100) */
	C_KANJI_JIS_5838, /*  0x9cb6 (U+60f4) */
	C_KANJI_JIS_5839, /*  0x9cb7 (U+60fa) */
	C_KANJI_JIS_583A, /*  0x9cb8 (U+6103) */
	C_KANJI_JIS_583B, /*  0x9cb9 (U+6121) */
	C_KANJI_JIS_583C, /*  0x9cba (U+60fb) */
	C_KANJI_JIS_583D, /*  0x9cbb (U+60f1) */
	C_KANJI_JIS_583E, /*  0x9cbc (U+610d) */
	C_KANJI_JIS_583F, /*  0x9cbd (U+610e) */
	C_KANJI_JIS_5840, /*  0x9cbe (U+6147) */
	C_KANJI_JIS_5841, /*  0x9cbf (U+613e) */
	C_KANJI_JIS_5842, /*  0x9cc0 (U+6128) */
	C_KANJI_JIS_5843, /*  0x9cc1 (U+6127) */
	C_KANJI_JIS_5844, /*  0x9cc2 (U+614a) */
	C_KANJI_JIS_5845, /*  0x9cc3 (U+613f) */
	C_KANJI_JIS_5846, /*  0x9cc4 (U+613c) */
	C_KANJI_JIS_5847, /*  0x9cc5 (U+612c) */
	C_KANJI_JIS_5848, /*  0x9cc6 (U+6134) */
	C_KANJI_JIS_5849, /*  0x9cc7 (U+613d) */
	C_KANJI_JIS_584A, /*  0x9cc8 (U+6142) */
	C_KANJI_JIS_584B, /*  0x9cc9 (U+6144) */
	C_KANJI_JIS_584C, /*  0x9cca (U+6173) */
	C_KANJI_JIS_584D, /*  0x9ccb (U+6177) */
	C_KANJI_JIS_584E, /*  0x9ccc (U+6158) */
	C_KANJI_JIS_584F, /*  0x9ccd (U+6159) */
	C_KANJI_JIS_5850, /*  0x9cce (U+615a) */
	C_KANJI_JIS_5851, /*  0x9ccf (U+616b) */
	C_KANJI_JIS_5852, /*  0x9cd0 (U+6174) */
	C_KANJI_JIS_5853, /*  0x9cd1 (U+616f) */
	C_KANJI_JIS_5854, /*  0x9cd2 (U+6165) */
	C_KANJI_JIS_5855, /*  0x9cd3 (U+6171) */
	C_KANJI_JIS_5856, /*  0x9cd4 (U+615f) */
	C_KANJI_JIS_5857, /*  0x9cd5 (U+615d) */
	C_KANJI_JIS_5858, /*  0x9cd6 (U+6153) */
	C_KANJI_JIS_5859, /*  0x9cd7 (U+6175) */
	C_KANJI_JIS_585A, /*  0x9cd8 (U+6199) */
	C_KANJI_JIS_585B, /*  0x9cd9 (U+6196) */
	C_KANJI_JIS_585C, /*  0x9cda (U+6187) */
	C_KANJI_JIS_585D, /*  0x9cdb (U+61ac) */
	C_KANJI_JIS_585E, /*  0x9cdc (U+6194) */
	C_KANJI_JIS_585F, /*  0x9cdd (U+619a) */
	C_KANJI_JIS_5860, /*  0x9cde (U+618a) */
	C_KANJI_JIS_5861, /*  0x9cdf (U+6191) */
	C_KANJI_JIS_5862, /*  0x9ce0 (U+61ab) */
	C_KANJI_JIS_5863, /*  0x9ce1 (U+61ae) */
	C_KANJI_JIS_5864, /*  0x9ce2 (U+61cc) */
	C_KANJI_JIS_5865, /*  0x9ce3 (U+61ca) */
	C_KANJI_JIS_5866, /*  0x9ce4 (U+61c9) */
	C_KANJI_JIS_5867, /*  0x9ce5 (U+61f7) */
	C_KANJI_JIS_5868, /*  0x9ce6 (U+61c8) */
	C_KANJI_JIS_5869, /*  0x9ce7 (U+61c3) */
	C_KANJI_JIS_586A, /*  0x9ce8 (U+61c6) */
	C_KANJI_JIS_586B, /*  0x9ce9 (U+61ba) */
	C_KANJI_JIS_586C, /*  0x9cea (U+61cb) */
	C_KANJI_JIS_586D, /*  0x9ceb (U+7f79) */
	C_KANJI_JIS_586E, /*  0x9cec (U+61cd) */
	C_KANJI_JIS_586F, /*  0x9ced (U+61e6) */
	C_KANJI_JIS_5870, /*  0x9cee (U+61e3) */
	C_KANJI_JIS_5871, /*  0x9cef (U+61f6) */
	C_KANJI_JIS_5872, /*  0x9cf0 (U+61fa) */
	C_KANJI_JIS_5873, /*  0x9cf1 (U+61f4) */
	C_KANJI_JIS_5874, /*  0x9cf2 (U+61ff) */
	C_KANJI_JIS_5875, /*  0x9cf3 (U+61fd) */
	C_KANJI_JIS_5876, /*  0x9cf4 (U+61fc) */
	C_KANJI_JIS_5877, /*  0x9cf5 (U+61fe) */
	C_KANJI_JIS_5878, /*  0x9cf6 (U+6200) */
	C_KANJI_JIS_5879, /*  0x9cf7 (U+6208) */
	C_KANJI_JIS_587A, /*  0x9cf8 (U+6209) */
	C_KANJI_JIS_587B, /*  0x9cf9 (U+620d) */
	C_KANJI_JIS_587C, /*  0x9cfa (U+620c) */
	C_KANJI_JIS_587D, /*  0x9cfb (U+6214) */
	C_KANJI_JIS_587E, /*  0x9cfc (U+621b) */
	0, /*  0x9cfd */
	0, /*  0x9cfe */
	0, /*  0x9cff */
	C_KANJI_JIS_5921, /*  0x9d40 (U+621e) */
	C_KANJI_JIS_5922, /*  0x9d41 (U+6221) */
	C_KANJI_JIS_5923, /*  0x9d42 (U+622a) */
	C_KANJI_JIS_5924, /*  0x9d43 (U+622e) */
	C_KANJI_JIS_5925, /*  0x9d44 (U+6230) */
	C_KANJI_JIS_5926, /*  0x9d45 (U+6232) */
	C_KANJI_JIS_5927, /*  0x9d46 (U+6233) */
	C_KANJI_JIS_5928, /*  0x9d47 (U+6241) */
	C_KANJI_JIS_5929, /*  0x9d48 (U+624e) */
	C_KANJI_JIS_592A, /*  0x9d49 (U+625e) */
	C_KANJI_JIS_592B, /*  0x9d4a (U+6263) */
	C_KANJI_JIS_592C, /*  0x9d4b (U+625b) */
	C_KANJI_JIS_592D, /*  0x9d4c (U+6260) */
	C_KANJI_JIS_592E, /*  0x9d4d (U+6268) */
	C_KANJI_JIS_592F, /*  0x9d4e (U+627c) */
	C_KANJI_JIS_5930, /*  0x9d4f (U+6282) */
	C_KANJI_JIS_5931, /*  0x9d50 (U+6289) */
	C_KANJI_JIS_5932, /*  0x9d51 (U+627e) */
	C_KANJI_JIS_5933, /*  0x9d52 (U+6292) */
	C_KANJI_JIS_5934, /*  0x9d53 (U+6293) */
	C_KANJI_JIS_5935, /*  0x9d54 (U+6296) */
	C_KANJI_JIS_5936, /*  0x9d55 (U+62d4) */
	C_KANJI_JIS_5937, /*  0x9d56 (U+6283) */
	C_KANJI_JIS_5938, /*  0x9d57 (U+6294) */
	C_KANJI_JIS_5939, /*  0x9d58 (U+62d7) */
	C_KANJI_JIS_593A, /*  0x9d59 (U+62d1) */
	C_KANJI_JIS_593B, /*  0x9d5a (U+62bb) */
	C_KANJI_JIS_593C, /*  0x9d5b (U+62cf) */
	C_KANJI_JIS_593D, /*  0x9d5c (U+62ff) */
	C_KANJI_JIS_593E, /*  0x9d5d (U+62c6) */
	C_KANJI_JIS_593F, /*  0x9d5e (U+64d4) */
	C_KANJI_JIS_5940, /*  0x9d5f (U+62c8) */
	C_KANJI_JIS_5941, /*  0x9d60 (U+62dc) */
	C_KANJI_JIS_5942, /*  0x9d61 (U+62cc) */
	C_KANJI_JIS_5943, /*  0x9d62 (U+62ca) */
	C_KANJI_JIS_5944, /*  0x9d63 (U+62c2) */
	C_KANJI_JIS_5945, /*  0x9d64 (U+62c7) */
	C_KANJI_JIS_5946, /*  0x9d65 (U+629b) */
	C_KANJI_JIS_5947, /*  0x9d66 (U+62c9) */
	C_KANJI_JIS_5948, /*  0x9d67 (U+630c) */
	C_KANJI_JIS_5949, /*  0x9d68 (U+62ee) */
	C_KANJI_JIS_594A, /*  0x9d69 (U+62f1) */
	C_KANJI_JIS_594B, /*  0x9d6a (U+6327) */
	C_KANJI_JIS_594C, /*  0x9d6b (U+6302) */
	C_KANJI_JIS_594D, /*  0x9d6c (U+6308) */
	C_KANJI_JIS_594E, /*  0x9d6d (U+62ef) */
	C_KANJI_JIS_594F, /*  0x9d6e (U+62f5) */
	C_KANJI_JIS_5950, /*  0x9d6f (U+6350) */
	C_KANJI_JIS_5951, /*  0x9d70 (U+633e) */
	C_KANJI_JIS_5952, /*  0x9d71 (U+634d) */
	C_KANJI_JIS_5953, /*  0x9d72 (U+641c) */
	C_KANJI_JIS_5954, /*  0x9d73 (U+634f) */
	C_KANJI_JIS_5955, /*  0x9d74 (U+6396) */
	C_KANJI_JIS_5956, /*  0x9d75 (U+638e) */
	C_KANJI_JIS_5957, /*  0x9d76 (U+6380) */
	C_KANJI_JIS_5958, /*  0x9d77 (U+63ab) */
	C_KANJI_JIS_5959, /*  0x9d78 (U+6376) */
	C_KANJI_JIS_595A, /*  0x9d79 (U+63a3) */
	C_KANJI_JIS_595B, /*  0x9d7a (U+638f) */
	C_KANJI_JIS_595C, /*  0x9d7b (U+6389) */
	C_KANJI_JIS_595D, /*  0x9d7c (U+639f) */
	C_KANJI_JIS_595E, /*  0x9d7d (U+63b5) */
	C_KANJI_JIS_595F, /*  0x9d7e (U+636b) */
	0, /*  0x9d7f */
	C_KANJI_JIS_5960, /*  0x9d80 (U+6369) */
	C_KANJI_JIS_5961, /*  0x9d81 (U+63be) */
	C_KANJI_JIS_5962, /*  0x9d82 (U+63e9) */
	C_KANJI_JIS_5963, /*  0x9d83 (U+63c0) */
	C_KANJI_JIS_5964, /*  0x9d84 (U+63c6) */
	C_KANJI_JIS_5965, /*  0x9d85 (U+63e3) */
	C_KANJI_JIS_5966, /*  0x9d86 (U+63c9) */
	C_KANJI_JIS_5967, /*  0x9d87 (U+63d2) */
	C_KANJI_JIS_5968, /*  0x9d88 (U+63f6) */
	C_KANJI_JIS_5969, /*  0x9d89 (U+63c4) */
	C_KANJI_JIS_596A, /*  0x9d8a (U+6416) */
	C_KANJI_JIS_596B, /*  0x9d8b (U+6434) */
	C_KANJI_JIS_596C, /*  0x9d8c (U+6406) */
	C_KANJI_JIS_596D, /*  0x9d8d (U+6413) */
	C_KANJI_JIS_596E, /*  0x9d8e (U+6426) */
	C_KANJI_JIS_596F, /*  0x9d8f (U+6436) */
	C_KANJI_JIS_5970, /*  0x9d90 (U+651d) */
	C_KANJI_JIS_5971, /*  0x9d91 (U+6417) */
	C_KANJI_JIS_5972, /*  0x9d92 (U+6428) */
	C_KANJI_JIS_5973, /*  0x9d93 (U+640f) */
	C_KANJI_JIS_5974, /*  0x9d94 (U+6467) */
	C_KANJI_JIS_5975, /*  0x9d95 (U+646f) */
	C_KANJI_JIS_5976, /*  0x9d96 (U+6476) */
	C_KANJI_JIS_5977, /*  0x9d97 (U+644e) */
	C_KANJI_JIS_5978, /*  0x9d98 (U+652a) */
	C_KANJI_JIS_5979, /*  0x9d99 (U+6495) */
	C_KANJI_JIS_597A, /*  0x9d9a (U+6493) */
	C_KANJI_JIS_597B, /*  0x9d9b (U+64a5) */
	C_KANJI_JIS_597C, /*  0x9d9c (U+64a9) */
	C_KANJI_JIS_597D, /*  0x9d9d (U+6488) */
	C_KANJI_JIS_597E, /*  0x9d9e (U+64bc) */
	C_KANJI_JIS_5A21, /*  0x9d9f (U+64da) */
	C_KANJI_JIS_5A22, /*  0x9da0 (U+64d2) */
	C_KANJI_JIS_5A23, /*  0x9da1 (U+64c5) */
	C_KANJI_JIS_5A24, /*  0x9da2 (U+64c7) */
	C_KANJI_JIS_5A25, /*  0x9da3 (U+64bb) */
	C_KANJI_JIS_5A26, /*  0x9da4 (U+64d8) */
	C_KANJI_JIS_5A27, /*  0x9da5 (U+64c2) */
	C_KANJI_JIS_5A28, /*  0x9da6 (U+64f1) */
	C_KANJI_JIS_5A29, /*  0x9da7 (U+64e7) */
	C_KANJI_JIS_5A2A, /*  0x9da8 (U+8209) */
	C_KANJI_JIS_5A2B, /*  0x9da9 (U+64e0) */
	C_KANJI_JIS_5A2C, /*  0x9daa (U+64e1) */
	C_KANJI_JIS_5A2D, /*  0x9dab (U+62ac) */
	C_KANJI_JIS_5A2E, /*  0x9dac (U+64e3) */
	C_KANJI_JIS_5A2F, /*  0x9dad (U+64ef) */
	C_KANJI_JIS_5A30, /*  0x9dae (U+652c) */
	C_KANJI_JIS_5A31, /*  0x9daf (U+64f6) */
	C_KANJI_JIS_5A32, /*  0x9db0 (U+64f4) */
	C_KANJI_JIS_5A33, /*  0x9db1 (U+64f2) */
	C_KANJI_JIS_5A34, /*  0x9db2 (U+64fa) */
	C_KANJI_JIS_5A35, /*  0x9db3 (U+6500) */
	C_KANJI_JIS_5A36, /*  0x9db4 (U+64fd) */
	C_KANJI_JIS_5A37, /*  0x9db5 (U+6518) */
	C_KANJI_JIS_5A38, /*  0x9db6 (U+651c) */
	C_KANJI_JIS_5A39, /*  0x9db7 (U+6505) */
	C_KANJI_JIS_5A3A, /*  0x9db8 (U+6524) */
	C_KANJI_JIS_5A3B, /*  0x9db9 (U+6523) */
	C_KANJI_JIS_5A3C, /*  0x9dba (U+652b) */
	C_KANJI_JIS_5A3D, /*  0x9dbb (U+6534) */
	C_KANJI_JIS_5A3E, /*  0x9dbc (U+6535) */
	C_KANJI_JIS_5A3F, /*  0x9dbd (U+6537) */
	C_KANJI_JIS_5A40, /*  0x9dbe (U+6536) */
	C_KANJI_JIS_5A41, /*  0x9dbf (U+6538) */
	C_KANJI_JIS_5A42, /*  0x9dc0 (U+754b) */
	C_KANJI_JIS_5A43, /*  0x9dc1 (U+6548) */
	C_KANJI_JIS_5A44, /*  0x9dc2 (U+6556) */
	C_KANJI_JIS_5A45, /*  0x9dc3 (U+6555) */
	C_KANJI_JIS_5A46, /*  0x9dc4 (U+654d) */
	C_KANJI_JIS_5A47, /*  0x9dc5 (U+6558) */
	C_KANJI_JIS_5A48, /*  0x9dc6 (U+655e) */
	C_KANJI_JIS_5A49, /*  0x9dc7 (U+655d) */
	C_KANJI_JIS_5A4A, /*  0x9dc8 (U+6572) */
	C_KANJI_JIS_5A4B, /*  0x9dc9 (U+6578) */
	C_KANJI_JIS_5A4C, /*  0x9dca (U+6582) */
	C_KANJI_JIS_5A4D, /*  0x9dcb (U+6583) */
	C_KANJI_JIS_5A4E, /*  0x9dcc (U+8b8a) */
	C_KANJI_JIS_5A4F, /*  0x9dcd (U+659b) */
	C_KANJI_JIS_5A50, /*  0x9dce (U+659f) */
	C_KANJI_JIS_5A51, /*  0x9dcf (U+65ab) */
	C_KANJI_JIS_5A52, /*  0x9dd0 (U+65b7) */
	C_KANJI_JIS_5A53, /*  0x9dd1 (U+65c3) */
	C_KANJI_JIS_5A54, /*  0x9dd2 (U+65c6) */
	C_KANJI_JIS_5A55, /*  0x9dd3 (U+65c1) */
	C_KANJI_JIS_5A56, /*  0x9dd4 (U+65c4) */
	C_KANJI_JIS_5A57, /*  0x9dd5 (U+65cc) */
	C_KANJI_JIS_5A58, /*  0x9dd6 (U+65d2) */
	C_KANJI_JIS_5A59, /*  0x9dd7 (U+65db) */
	C_KANJI_JIS_5A5A, /*  0x9dd8 (U+65d9) */
	C_KANJI_JIS_5A5B, /*  0x9dd9 (U+65e0) */
	C_KANJI_JIS_5A5C, /*  0x9dda (U+65e1) */
	C_KANJI_JIS_5A5D, /*  0x9ddb (U+65f1) */
	C_KANJI_JIS_5A5E, /*  0x9ddc (U+6772) */
	C_KANJI_JIS_5A5F, /*  0x9ddd (U+660a) */
	C_KANJI_JIS_5A60, /*  0x9dde (U+6603) */
	C_KANJI_JIS_5A61, /*  0x9ddf (U+65fb) */
	C_KANJI_JIS_5A62, /*  0x9de0 (U+6773) */
	C_KANJI_JIS_5A63, /*  0x9de1 (U+6635) */
	C_KANJI_JIS_5A64, /*  0x9de2 (U+6636) */
	C_KANJI_JIS_5A65, /*  0x9de3 (U+6634) */
	C_KANJI_JIS_5A66, /*  0x9de4 (U+661c) */
	C_KANJI_JIS_5A67, /*  0x9de5 (U+664f) */
	C_KANJI_JIS_5A68, /*  0x9de6 (U+6644) */
	C_KANJI_JIS_5A69, /*  0x9de7 (U+6649) */
	C_KANJI_JIS_5A6A, /*  0x9de8 (U+6641) */
	C_KANJI_JIS_5A6B, /*  0x9de9 (U+665e) */
	C_KANJI_JIS_5A6C, /*  0x9dea (U+665d) */
	C_KANJI_JIS_5A6D, /*  0x9deb (U+6664) */
	C_KANJI_JIS_5A6E, /*  0x9dec (U+6667) */
	C_KANJI_JIS_5A6F, /*  0x9ded (U+6668) */
	C_KANJI_JIS_5A70, /*  0x9dee (U+665f) */
	C_KANJI_JIS_5A71, /*  0x9def (U+6662) */
	C_KANJI_JIS_5A72, /*  0x9df0 (U+6670) */
	C_KANJI_JIS_5A73, /*  0x9df1 (U+6683) */
	C_KANJI_JIS_5A74, /*  0x9df2 (U+6688) */
	C_KANJI_JIS_5A75, /*  0x9df3 (U+668e) */
	C_KANJI_JIS_5A76, /*  0x9df4 (U+6689) */
	C_KANJI_JIS_5A77, /*  0x9df5 (U+6684) */
	C_KANJI_JIS_5A78, /*  0x9df6 (U+6698) */
	C_KANJI_JIS_5A79, /*  0x9df7 (U+669d) */
	C_KANJI_JIS_5A7A, /*  0x9df8 (U+66c1) */
	C_KANJI_JIS_5A7B, /*  0x9df9 (U+66b9) */
	C_KANJI_JIS_5A7C, /*  0x9dfa (U+66c9) */
	C_KANJI_JIS_5A7D, /*  0x9dfb (U+66be) */
	C_KANJI_JIS_5A7E, /*  0x9dfc (U+66bc) */
	0, /*  0x9dfd */
	0, /*  0x9dfe */
	0, /*  0x9dff */
	C_KANJI_JIS_5B21, /*  0x9e40 (U+66c4) */
	C_KANJI_JIS_5B22, /*  0x9e41 (U+66b8) */
	C_KANJI_JIS_5B23, /*  0x9e42 (U+66d6) */
	C_KANJI_JIS_5B24, /*  0x9e43 (U+66da) */
	C_KANJI_JIS_5B25, /*  0x9e44 (U+66e0) */
	C_KANJI_JIS_5B26, /*  0x9e45 (U+663f) */
	C_KANJI_JIS_5B27, /*  0x9e46 (U+66e6) */
	C_KANJI_JIS_5B28, /*  0x9e47 (U+66e9) */
	C_KANJI_JIS_5B29, /*  0x9e48 (U+66f0) */
	C_KANJI_JIS_5B2A, /*  0x9e49 (U+66f5) */
	C_KANJI_JIS_5B2B, /*  0x9e4a (U+66f7) */
	C_KANJI_JIS_5B2C, /*  0x9e4b (U+670f) */
	C_KANJI_JIS_5B2D, /*  0x9e4c (U+6716) */
	C_KANJI_JIS_5B2E, /*  0x9e4d (U+671e) */
	C_KANJI_JIS_5B2F, /*  0x9e4e (U+6726) */
	C_KANJI_JIS_5B30, /*  0x9e4f (U+6727) */
	C_KANJI_JIS_5B31, /*  0x9e50 (U+9738) */
	C_KANJI_JIS_5B32, /*  0x9e51 (U+672e) */
	C_KANJI_JIS_5B33, /*  0x9e52 (U+673f) */
	C_KANJI_JIS_5B34, /*  0x9e53 (U+6736) */
	C_KANJI_JIS_5B35, /*  0x9e54 (U+6741) */
	C_KANJI_JIS_5B36, /*  0x9e55 (U+6738) */
	C_KANJI_JIS_5B37, /*  0x9e56 (U+6737) */
	C_KANJI_JIS_5B38, /*  0x9e57 (U+6746) */
	C_KANJI_JIS_5B39, /*  0x9e58 (U+675e) */
	C_KANJI_JIS_5B3A, /*  0x9e59 (U+6760) */
	C_KANJI_JIS_5B3B, /*  0x9e5a (U+6759) */
	C_KANJI_JIS_5B3C, /*  0x9e5b (U+6763) */
	C_KANJI_JIS_5B3D, /*  0x9e5c (U+6764) */
	C_KANJI_JIS_5B3E, /*  0x9e5d (U+6789) */
	C_KANJI_JIS_5B3F, /*  0x9e5e (U+6770) */
	C_KANJI_JIS_5B40, /*  0x9e5f (U+67a9) */
	C_KANJI_JIS_5B41, /*  0x9e60 (U+677c) */
	C_KANJI_JIS_5B42, /*  0x9e61 (U+676a) */
	C_KANJI_JIS_5B43, /*  0x9e62 (U+678c) */
	C_KANJI_JIS_5B44, /*  0x9e63 (U+678b) */
	C_KANJI_JIS_5B45, /*  0x9e64 (U+67a6) */
	C_KANJI_JIS_5B46, /*  0x9e65 (U+67a1) */
	C_KANJI_JIS_5B47, /*  0x9e66 (U+6785) */
	C_KANJI_JIS_5B48, /*  0x9e67 (U+67b7) */
	C_KANJI_JIS_5B49, /*  0x9e68 (U+67ef) */
	C_KANJI_JIS_5B4A, /*  0x9e69 (U+67b4) */
	C_KANJI_JIS_5B4B, /*  0x9e6a (U+67ec) */
	C_KANJI_JIS_5B4C, /*  0x9e6b (U+67b3) */
	C_KANJI_JIS_5B4D, /*  0x9e6c (U+67e9) */
	C_KANJI_JIS_5B4E, /*  0x9e6d (U+67b8) */
	C_KANJI_JIS_5B4F, /*  0x9e6e (U+67e4) */
	C_KANJI_JIS_5B50, /*  0x9e6f (U+67de) */
	C_KANJI_JIS_5B51, /*  0x9e70 (U+67dd) */
	C_KANJI_JIS_5B52, /*  0x9e71 (U+67e2) */
	C_KANJI_JIS_5B53, /*  0x9e72 (U+67ee) */
	C_KANJI_JIS_5B54, /*  0x9e73 (U+67b9) */
	C_KANJI_JIS_5B55, /*  0x9e74 (U+67ce) */
	C_KANJI_JIS_5B56, /*  0x9e75 (U+67c6) */
	C_KANJI_JIS_5B57, /*  0x9e76 (U+67e7) */
	C_KANJI_JIS_5B58, /*  0x9e77 (U+6a9c) */
	C_KANJI_JIS_5B59, /*  0x9e78 (U+681e) */
	C_KANJI_JIS_5B5A, /*  0x9e79 (U+6846) */
	C_KANJI_JIS_5B5B, /*  0x9e7a (U+6829) */
	C_KANJI_JIS_5B5C, /*  0x9e7b (U+6840) */
	C_KANJI_JIS_5B5D, /*  0x9e7c (U+684d) */
	C_KANJI_JIS_5B5E, /*  0x9e7d (U+6832) */
	C_KANJI_JIS_5B5F, /*  0x9e7e (U+684e) */
	0, /*  0x9e7f */
	C_KANJI_JIS_5B60, /*  0x9e80 (U+68b3) */
	C_KANJI_JIS_5B61, /*  0x9e81 (U+682b) */
	C_KANJI_JIS_5B62, /*  0x9e82 (U+6859) */
	C_KANJI_JIS_5B63, /*  0x9e83 (U+6863) */
	C_KANJI_JIS_5B64, /*  0x9e84 (U+6877) */
	C_KANJI_JIS_5B65, /*  0x9e85 (U+687f) */
	C_KANJI_JIS_5B66, /*  0x9e86 (U+689f) */
	C_KANJI_JIS_5B67, /*  0x9e87 (U+688f) */
	C_KANJI_JIS_5B68, /*  0x9e88 (U+68ad) */
	C_KANJI_JIS_5B69, /*  0x9e89 (U+6894) */
	C_KANJI_JIS_5B6A, /*  0x9e8a (U+689d) */
	C_KANJI_JIS_5B6B, /*  0x9e8b (U+689b) */
	C_KANJI_JIS_5B6C, /*  0x9e8c (U+6883) */
	C_KANJI_JIS_5B6D, /*  0x9e8d (U+6aae) */
	C_KANJI_JIS_5B6E, /*  0x9e8e (U+68b9) */
	C_KANJI_JIS_5B6F, /*  0x9e8f (U+6874) */
	C_KANJI_JIS_5B70, /*  0x9e90 (U+68b5) */
	C_KANJI_JIS_5B71, /*  0x9e91 (U+68a0) */
	C_KANJI_JIS_5B72, /*  0x9e92 (U+68ba) */
	C_KANJI_JIS_5B73, /*  0x9e93 (U+690f) */
	C_KANJI_JIS_5B74, /*  0x9e94 (U+688d) */
	C_KANJI_JIS_5B75, /*  0x9e95 (U+687e) */
	C_KANJI_JIS_5B76, /*  0x9e96 (U+6901) */
	C_KANJI_JIS_5B77, /*  0x9e97 (U+68ca) */
	C_KANJI_JIS_5B78, /*  0x9e98 (U+6908) */
	C_KANJI_JIS_5B79, /*  0x9e99 (U+68d8) */
	C_KANJI_JIS_5B7A, /*  0x9e9a (U+6922) */
	C_KANJI_JIS_5B7B, /*  0x9e9b (U+6926) */
	C_KANJI_JIS_5B7C, /*  0x9e9c (U+68e1) */
	C_KANJI_JIS_5B7D, /*  0x9e9d (U+690c) */
	C_KANJI_JIS_5B7E, /*  0x9e9e (U+68cd) */
	C_KANJI_JIS_5C21, /*  0x9e9f (U+68d4) */
	C_KANJI_JIS_5C22, /*  0x9ea0 (U+68e7) */
	C_KANJI_JIS_5C23, /*  0x9ea1 (U+68d5) */
	C_KANJI_JIS_5C24, /*  0x9ea2 (U+6936) */
	C_KANJI_JIS_5C25, /*  0x9ea3 (U+6912) */
	C_KANJI_JIS_5C26, /*  0x9ea4 (U+6904) */
	C_KANJI_JIS_5C27, /*  0x9ea5 (U+68d7) */
	C_KANJI_JIS_5C28, /*  0x9ea6 (U+68e3) */
	C_KANJI_JIS_5C29, /*  0x9ea7 (U+6925) */
	C_KANJI_JIS_5C2A, /*  0x9ea8 (U+68f9) */
	C_KANJI_JIS_5C2B, /*  0x9ea9 (U+68e0) */
	C_KANJI_JIS_5C2C, /*  0x9eaa (U+68ef) */
	C_KANJI_JIS_5C2D, /*  0x9eab (U+6928) */
	C_KANJI_JIS_5C2E, /*  0x9eac (U+692a) */
	C_KANJI_JIS_5C2F, /*  0x9ead (U+691a) */
	C_KANJI_JIS_5C30, /*  0x9eae (U+6923) */
	C_KANJI_JIS_5C31, /*  0x9eaf (U+6921) */
	C_KANJI_JIS_5C32, /*  0x9eb0 (U+68c6) */
	C_KANJI_JIS_5C33, /*  0x9eb1 (U+6979) */
	C_KANJI_JIS_5C34, /*  0x9eb2 (U+6977) */
	C_KANJI_JIS_5C35, /*  0x9eb3 (U+695c) */
	C_KANJI_JIS_5C36, /*  0x9eb4 (U+6978) */
	C_KANJI_JIS_5C37, /*  0x9eb5 (U+696b) */
	C_KANJI_JIS_5C38, /*  0x9eb6 (U+6954) */
	C_KANJI_JIS_5C39, /*  0x9eb7 (U+697e) */
	C_KANJI_JIS_5C3A, /*  0x9eb8 (U+696e) */
	C_KANJI_JIS_5C3B, /*  0x9eb9 (U+6939) */
	C_KANJI_JIS_5C3C, /*  0x9eba (U+6974) */
	C_KANJI_JIS_5C3D, /*  0x9ebb (U+693d) */
	C_KANJI_JIS_5C3E, /*  0x9ebc (U+6959) */
	C_KANJI_JIS_5C3F, /*  0x9ebd (U+6930) */
	C_KANJI_JIS_5C40, /*  0x9ebe (U+6961) */
	C_KANJI_JIS_5C41, /*  0x9ebf (U+695e) */
	C_KANJI_JIS_5C42, /*  0x9ec0 (U+695d) */
	C_KANJI_JIS_5C43, /*  0x9ec1 (U+6981) */
	C_KANJI_JIS_5C44, /*  0x9ec2 (U+696a) */
	C_KANJI_JIS_5C45, /*  0x9ec3 (U+69b2) */
	C_KANJI_JIS_5C46, /*  0x9ec4 (U+69ae) */
	C_KANJI_JIS_5C47, /*  0x9ec5 (U+69d0) */
	C_KANJI_JIS_5C48, /*  0x9ec6 (U+69bf) */
	C_KANJI_JIS_5C49, /*  0x9ec7 (U+69c1) */
	C_KANJI_JIS_5C4A, /*  0x9ec8 (U+69d3) */
	C_KANJI_JIS_5C4B, /*  0x9ec9 (U+69be) */
	C_KANJI_JIS_5C4C, /*  0x9eca (U+69ce) */
	C_KANJI_JIS_5C4D, /*  0x9ecb (U+5be8) */
	C_KANJI_JIS_5C4E, /*  0x9ecc (U+69ca) */
	C_KANJI_JIS_5C4F, /*  0x9ecd (U+69dd) */
	C_KANJI_JIS_5C50, /*  0x9ece (U+69bb) */
	C_KANJI_JIS_5C51, /*  0x9ecf (U+69c3) */
	C_KANJI_JIS_5C52, /*  0x9ed0 (U+69a7) */
	C_KANJI_JIS_5C53, /*  0x9ed1 (U+6a2e) */
	C_KANJI_JIS_5C54, /*  0x9ed2 (U+6991) */
	C_KANJI_JIS_5C55, /*  0x9ed3 (U+69a0) */
	C_KANJI_JIS_5C56, /*  0x9ed4 (U+699c) */
	C_KANJI_JIS_5C57, /*  0x9ed5 (U+6995) */
	C_KANJI_JIS_5C58, /*  0x9ed6 (U+69b4) */
	C_KANJI_JIS_5C59, /*  0x9ed7 (U+69de) */
	C_KANJI_JIS_5C5A, /*  0x9ed8 (U+69e8) */
	C_KANJI_JIS_5C5B, /*  0x9ed9 (U+6a02) */
	C_KANJI_JIS_5C5C, /*  0x9eda (U+6a1b) */
	C_KANJI_JIS_5C5D, /*  0x9edb (U+69ff) */
	C_KANJI_JIS_5C5E, /*  0x9edc (U+6b0a) */
	C_KANJI_JIS_5C5F, /*  0x9edd (U+69f9) */
	C_KANJI_JIS_5C60, /*  0x9ede (U+69f2) */
	C_KANJI_JIS_5C61, /*  0x9edf (U+69e7) */
	C_KANJI_JIS_5C62, /*  0x9ee0 (U+6a05) */
	C_KANJI_JIS_5C63, /*  0x9ee1 (U+69b1) */
	C_KANJI_JIS_5C64, /*  0x9ee2 (U+6a1e) */
	C_KANJI_JIS_5C65, /*  0x9ee3 (U+69ed) */
	C_KANJI_JIS_5C66, /*  0x9ee4 (U+6a14) */
	C_KANJI_JIS_5C67, /*  0x9ee5 (U+69eb) */
	C_KANJI_JIS_5C68, /*  0x9ee6 (U+6a0a) */
	C_KANJI_JIS_5C69, /*  0x9ee7 (U+6a12) */
	C_KANJI_JIS_5C6A, /*  0x9ee8 (U+6ac1) */
	C_KANJI_JIS_5C6B, /*  0x9ee9 (U+6a23) */
	C_KANJI_JIS_5C6C, /*  0x9eea (U+6a13) */
	C_KANJI_JIS_5C6D, /*  0x9eeb (U+6a44) */
	C_KANJI_JIS_5C6E, /*  0x9eec (U+6a0c) */
	C_KANJI_JIS_5C6F, /*  0x9eed (U+6a72) */
	C_KANJI_JIS_5C70, /*  0x9eee (U+6a36) */
	C_KANJI_JIS_5C71, /*  0x9eef (U+6a78) */
	C_KANJI_JIS_5C72, /*  0x9ef0 (U+6a47) */
	C_KANJI_JIS_5C73, /*  0x9ef1 (U+6a62) */
	C_KANJI_JIS_5C74, /*  0x9ef2 (U+6a59) */
	C_KANJI_JIS_5C75, /*  0x9ef3 (U+6a66) */
	C_KANJI_JIS_5C76, /*  0x9ef4 (U+6a48) */
	C_KANJI_JIS_5C77, /*  0x9ef5 (U+6a38) */
	C_KANJI_JIS_5C78, /*  0x9ef6 (U+6a22) */
	C_KANJI_JIS_5C79, /*  0x9ef7 (U+6a90) */
	C_KANJI_JIS_5C7A, /*  0x9ef8 (U+6a8d) */
	C_KANJI_JIS_5C7B, /*  0x9ef9 (U+6aa0) */
	C_KANJI_JIS_5C7C, /*  0x9efa (U+6a84) */
	C_KANJI_JIS_5C7D, /*  0x9efb (U+6aa2) */
	C_KANJI_JIS_5C7E, /*  0x9efc (U+6aa3) */
	0, /*  0x9efd */
	0, /*  0x9efe */
	0, /*  0x9eff */
	C_KANJI_JIS_5D21, /*  0x9f40 (U+6a97) */
	C_KANJI_JIS_5D22, /*  0x9f41 (U+8617) */
	C_KANJI_JIS_5D23, /*  0x9f42 (U+6abb) */
	C_KANJI_JIS_5D24, /*  0x9f43 (U+6ac3) */
	C_KANJI_JIS_5D25, /*  0x9f44 (U+6ac2) */
	C_KANJI_JIS_5D26, /*  0x9f45 (U+6ab8) */
	C_KANJI_JIS_5D27, /*  0x9f46 (U+6ab3) */
	C_KANJI_JIS_5D28, /*  0x9f47 (U+6aac) */
	C_KANJI_JIS_5D29, /*  0x9f48 (U+6ade) */
	C_KANJI_JIS_5D2A, /*  0x9f49 (U+6ad1) */
	C_KANJI_JIS_5D2B, /*  0x9f4a (U+6adf) */
	C_KANJI_JIS_5D2C, /*  0x9f4b (U+6aaa) */
	C_KANJI_JIS_5D2D, /*  0x9f4c (U+6ada) */
	C_KANJI_JIS_5D2E, /*  0x9f4d (U+6aea) */
	C_KANJI_JIS_5D2F, /*  0x9f4e (U+6afb) */
	C_KANJI_JIS_5D30, /*  0x9f4f (U+6b05) */
	C_KANJI_JIS_5D31, /*  0x9f50 (U+8616) */
	C_KANJI_JIS_5D32, /*  0x9f51 (U+6afa) */
	C_KANJI_JIS_5D33, /*  0x9f52 (U+6b12) */
	C_KANJI_JIS_5D34, /*  0x9f53 (U+6b16) */
	C_KANJI_JIS_5D35, /*  0x9f54 (U+9b31) */
	C_KANJI_JIS_5D36, /*  0x9f55 (U+6b1f) */
	C_KANJI_JIS_5D37, /*  0x9f56 (U+6b38) */
	C_KANJI_JIS_5D38, /*  0x9f57 (U+6b37) */
	C_KANJI_JIS_5D39, /*  0x9f58 (U+76dc) */
	C_KANJI_JIS_5D3A, /*  0x9f59 (U+6b39) */
	C_KANJI_JIS_5D3B, /*  0x9f5a (U+98ee) */
	C_KANJI_JIS_5D3C, /*  0x9f5b (U+6b47) */
	C_KANJI_JIS_5D3D, /*  0x9f5c (U+6b43) */
	C_KANJI_JIS_5D3E, /*  0x9f5d (U+6b49) */
	C_KANJI_JIS_5D3F, /*  0x9f5e (U+6b50) */
	C_KANJI_JIS_5D40, /*  0x9f5f (U+6b59) */
	C_KANJI_JIS_5D41, /*  0x9f60 (U+6b54) */
	C_KANJI_JIS_5D42, /*  0x9f61 (U+6b5b) */
	C_KANJI_JIS_5D43, /*  0x9f62 (U+6b5f) */
	C_KANJI_JIS_5D44, /*  0x9f63 (U+6b61) */
	C_KANJI_JIS_5D45, /*  0x9f64 (U+6b78) */
	C_KANJI_JIS_5D46, /*  0x9f65 (U+6b79) */
	C_KANJI_JIS_5D47, /*  0x9f66 (U+6b7f) */
	C_KANJI_JIS_5D48, /*  0x9f67 (U+6b80) */
	C_KANJI_JIS_5D49, /*  0x9f68 (U+6b84) */
	C_KANJI_JIS_5D4A, /*  0x9f69 (U+6b83) */
	C_KANJI_JIS_5D4B, /*  0x9f6a (U+6b8d) */
	C_KANJI_JIS_5D4C, /*  0x9f6b (U+6b98) */
	C_KANJI_JIS_5D4D, /*  0x9f6c (U+6b95) */
	C_KANJI_JIS_5D4E, /*  0x9f6d (U+6b9e) */
	C_KANJI_JIS_5D4F, /*  0x9f6e (U+6ba4) */
	C_KANJI_JIS_5D50, /*  0x9f6f (U+6baa) */
	C_KANJI_JIS_5D51, /*  0x9f70 (U+6bab) */
	C_KANJI_JIS_5D52, /*  0x9f71 (U+6baf) */
	C_KANJI_JIS_5D53, /*  0x9f72 (U+6bb2) */
	C_KANJI_JIS_5D54, /*  0x9f73 (U+6bb1) */
	C_KANJI_JIS_5D55, /*  0x9f74 (U+6bb3) */
	C_KANJI_JIS_5D56, /*  0x9f75 (U+6bb7) */
	C_KANJI_JIS_5D57, /*  0x9f76 (U+6bbc) */
	C_KANJI_JIS_5D58, /*  0x9f77 (U+6bc6) */
	C_KANJI_JIS_5D59, /*  0x9f78 (U+6bcb) */
	C_KANJI_JIS_5D5A, /*  0x9f79 (U+6bd3) */
	C_KANJI_JIS_5D5B, /*  0x9f7a (U+6bdf) */
	C_KANJI_JIS_5D5C, /*  0x9f7b (U+6bec) */
	C_KANJI_JIS_5D5D, /*  0x9f7c (U+6beb) */
	C_KANJI_JIS_5D5E, /*  0x9f7d (U+6bf3) */
	C_KANJI_JIS_5D5F, /*  0x9f7e (U+6bef) */
	0, /*  0x9f7f */
	C_KANJI_JIS_5D60, /*  0x9f80 (U+9ebe) */
	C_KANJI_JIS_5D61, /*  0x9f81 (U+6c08) */
	C_KANJI_JIS_5D62, /*  0x9f82 (U+6c13) */
	C_KANJI_JIS_5D63, /*  0x9f83 (U+6c14) */
	C_KANJI_JIS_5D64, /*  0x9f84 (U+6c1b) */
	C_KANJI_JIS_5D65, /*  0x9f85 (U+6c24) */
	C_KANJI_JIS_5D66, /*  0x9f86 (U+6c23) */
	C_KANJI_JIS_5D67, /*  0x9f87 (U+6c5e) */
	C_KANJI_JIS_5D68, /*  0x9f88 (U+6c55) */
	C_KANJI_JIS_5D69, /*  0x9f89 (U+6c62) */
	C_KANJI_JIS_5D6A, /*  0x9f8a (U+6c6a) */
	C_KANJI_JIS_5D6B, /*  0x9f8b (U+6c82) */
	C_KANJI_JIS_5D6C, /*  0x9f8c (U+6c8d) */
	C_KANJI_JIS_5D6D, /*  0x9f8d (U+6c9a) */
	C_KANJI_JIS_5D6E, /*  0x9f8e (U+6c81) */
	C_KANJI_JIS_5D6F, /*  0x9f8f (U+6c9b) */
	C_KANJI_JIS_5D70, /*  0x9f90 (U+6c7e) */
	C_KANJI_JIS_5D71, /*  0x9f91 (U+6c68) */
	C_KANJI_JIS_5D72, /*  0x9f92 (U+6c73) */
	C_KANJI_JIS_5D73, /*  0x9f93 (U+6c92) */
	C_KANJI_JIS_5D74, /*  0x9f94 (U+6c90) */
	C_KANJI_JIS_5D75, /*  0x9f95 (U+6cc4) */
	C_KANJI_JIS_5D76, /*  0x9f96 (U+6cf1) */
	C_KANJI_JIS_5D77, /*  0x9f97 (U+6cd3) */
	C_KANJI_JIS_5D78, /*  0x9f98 (U+6cbd) */
	C_KANJI_JIS_5D79, /*  0x9f99 (U+6cd7) */
	C_KANJI_JIS_5D7A, /*  0x9f9a (U+6cc5) */
	C_KANJI_JIS_5D7B, /*  0x9f9b (U+6cdd) */
	C_KANJI_JIS_5D7C, /*  0x9f9c (U+6cae) */
	C_KANJI_JIS_5D7D, /*  0x9f9d (U+6cb1) */
	C_KANJI_JIS_5D7E, /*  0x9f9e (U+6cbe) */
	C_KANJI_JIS_5E21, /*  0x9f9f (U+6cba) */
	C_KANJI_JIS_5E22, /*  0x9fa0 (U+6cdb) */
	C_KANJI_JIS_5E23, /*  0x9fa1 (U+6cef) */
	C_KANJI_JIS_5E24, /*  0x9fa2 (U+6cd9) */
	C_KANJI_JIS_5E25, /*  0x9fa3 (U+6cea) */
	C_KANJI_JIS_5E26, /*  0x9fa4 (U+6d1f) */
	C_KANJI_JIS_5E27, /*  0x9fa5 (U+884d) */
	C_KANJI_JIS_5E28, /*  0x9fa6 (U+6d36) */
	C_KANJI_JIS_5E29, /*  0x9fa7 (U+6d2b) */
	C_KANJI_JIS_5E2A, /*  0x9fa8 (U+6d3d) */
	C_KANJI_JIS_5E2B, /*  0x9fa9 (U+6d38) */
	C_KANJI_JIS_5E2C, /*  0x9faa (U+6d19) */
	C_KANJI_JIS_5E2D, /*  0x9fab (U+6d35) */
	C_KANJI_JIS_5E2E, /*  0x9fac (U+6d33) */
	C_KANJI_JIS_5E2F, /*  0x9fad (U+6d12) */
	C_KANJI_JIS_5E30, /*  0x9fae (U+6d0c) */
	C_KANJI_JIS_5E31, /*  0x9faf (U+6d63) */
	C_KANJI_JIS_5E32, /*  0x9fb0 (U+6d93) */
	C_KANJI_JIS_5E33, /*  0x9fb1 (U+6d64) */
	C_KANJI_JIS_5E34, /*  0x9fb2 (U+6d5a) */
	C_KANJI_JIS_5E35, /*  0x9fb3 (U+6d79) */
	C_KANJI_JIS_5E36, /*  0x9fb4 (U+6d59) */
	C_KANJI_JIS_5E37, /*  0x9fb5 (U+6d8e) */
	C_KANJI_JIS_5E38, /*  0x9fb6 (U+6d95) */
	C_KANJI_JIS_5E39, /*  0x9fb7 (U+6fe4) */
	C_KANJI_JIS_5E3A, /*  0x9fb8 (U+6d85) */
	C_KANJI_JIS_5E3B, /*  0x9fb9 (U+6df9) */
	C_KANJI_JIS_5E3C, /*  0x9fba (U+6e15) */
	C_KANJI_JIS_5E3D, /*  0x9fbb (U+6e0a) */
	C_KANJI_JIS_5E3E, /*  0x9fbc (U+6db5) */
	C_KANJI_JIS_5E3F, /*  0x9fbd (U+6dc7) */
	C_KANJI_JIS_5E40, /*  0x9fbe (U+6de6) */
	C_KANJI_JIS_5E41, /*  0x9fbf (U+6db8) */
	C_KANJI_JIS_5E42, /*  0x9fc0 (U+6dc6) */
	C_KANJI_JIS_5E43, /*  0x9fc1 (U+6dec) */
	C_KANJI_JIS_5E44, /*  0x9fc2 (U+6dde) */
	C_KANJI_JIS_5E45, /*  0x9fc3 (U+6dcc) */
	C_KANJI_JIS_5E46, /*  0x9fc4 (U+6de8) */
	C_KANJI_JIS_5E47, /*  0x9fc5 (U+6dd2) */
	C_KANJI_JIS_5E48, /*  0x9fc6 (U+6dc5) */
	C_KANJI_JIS_5E49, /*  0x9fc7 (U+6dfa) */
	C_KANJI_JIS_5E4A, /*  0x9fc8 (U+6dd9) */
	C_KANJI_JIS_5E4B, /*  0x9fc9 (U+6de4) */
	C_KANJI_JIS_5E4C, /*  0x9fca (U+6dd5) */
	C_KANJI_JIS_5E4D, /*  0x9fcb (U+6dea) */
	C_KANJI_JIS_5E4E, /*  0x9fcc (U+6dee) */
	C_KANJI_JIS_5E4F, /*  0x9fcd (U+6e2d) */
	C_KANJI_JIS_5E50, /*  0x9fce (U+6e6e) */
	C_KANJI_JIS_5E51, /*  0x9fcf (U+6e2e) */
	C_KANJI_JIS_5E52, /*  0x9fd0 (U+6e19) */
	C_KANJI_JIS_5E53, /*  0x9fd1 (U+6e72) */
	C_KANJI_JIS_5E54, /*  0x9fd2 (U+6e5f) */
	C_KANJI_JIS_5E55, /*  0x9fd3 (U+6e3e) */
	C_KANJI_JIS_5E56, /*  0x9fd4 (U+6e23) */
	C_KANJI_JIS_5E57, /*  0x9fd5 (U+6e6b) */
	C_KANJI_JIS_5E58, /*  0x9fd6 (U+6e2b) */
	C_KANJI_JIS_5E59, /*  0x9fd7 (U+6e76) */
	C_KANJI_JIS_5E5A, /*  0x9fd8 (U+6e4d) */
	C_KANJI_JIS_5E5B, /*  0x9fd9 (U+6e1f) */
	C_KANJI_JIS_5E5C, /*  0x9fda (U+6e43) */
	C_KANJI_JIS_5E5D, /*  0x9fdb (U+6e3a) */
	C_KANJI_JIS_5E5E, /*  0x9fdc (U+6e4e) */
	C_KANJI_JIS_5E5F, /*  0x9fdd (U+6e24) */
	C_KANJI_JIS_5E60, /*  0x9fde (U+6eff) */
	C_KANJI_JIS_5E61, /*  0x9fdf (U+6e1d) */
	C_KANJI_JIS_5E62, /*  0x9fe0 (U+6e38) */
	C_KANJI_JIS_5E63, /*  0x9fe1 (U+6e82) */
	C_KANJI_JIS_5E64, /*  0x9fe2 (U+6eaa) */
	C_KANJI_JIS_5E65, /*  0x9fe3 (U+6e98) */
	C_KANJI_JIS_5E66, /*  0x9fe4 (U+6ec9) */
	C_KANJI_JIS_5E67, /*  0x9fe5 (U+6eb7) */
	C_KANJI_JIS_5E68, /*  0x9fe6 (U+6ed3) */
	C_KANJI_JIS_5E69, /*  0x9fe7 (U+6ebd) */
	C_KANJI_JIS_5E6A, /*  0x9fe8 (U+6eaf) */
	C_KANJI_JIS_5E6B, /*  0x9fe9 (U+6ec4) */
	C_KANJI_JIS_5E6C, /*  0x9fea (U+6eb2) */
	C_KANJI_JIS_5E6D, /*  0x9feb (U+6ed4) */
	C_KANJI_JIS_5E6E, /*  0x9fec (U+6ed5) */
	C_KANJI_JIS_5E6F, /*  0x9fed (U+6e8f) */
	C_KANJI_JIS_5E70, /*  0x9fee (U+6ea5) */
	C_KANJI_JIS_5E71, /*  0x9fef (U+6ec2) */
	C_KANJI_JIS_5E72, /*  0x9ff0 (U+6e9f) */
	C_KANJI_JIS_5E73, /*  0x9ff1 (U+6f41) */
	C_KANJI_JIS_5E74, /*  0x9ff2 (U+6f11) */
	C_KANJI_JIS_5E75, /*  0x9ff3 (U+704c) */
	C_KANJI_JIS_5E76, /*  0x9ff4 (U+6eec) */
	C_KANJI_JIS_5E77, /*  0x9ff5 (U+6ef8) */
	C_KANJI_JIS_5E78, /*  0x9ff6 (U+6efe) */
	C_KANJI_JIS_5E79, /*  0x9ff7 (U+6f3f) */
	C_KANJI_JIS_5E7A, /*  0x9ff8 (U+6ef2) */
	C_KANJI_JIS_5E7B, /*  0x9ff9 (U+6f31) */
	C_KANJI_JIS_5E7C, /*  0x9ffa (U+6eef) */
	C_KANJI_JIS_5E7D, /*  0x9ffb (U+6f32) */
	C_KANJI_JIS_5E7E, /*  0x9ffc (U+6ecc) */
	0, /*  0x9ffd */
	0, /*  0x9ffe */
	0, /*  0x9fff */

/*
 * There is a gap in the SJIS character set between 0xa000-0xe000.
 * Considering it is 16K in size, it is worthwhile to skip it.
 */
	C_KANJI_JIS_5F21, /*  0xe040 (U+6f3e) */
	C_KANJI_JIS_5F22, /*  0xe041 (U+6f13) */
	C_KANJI_JIS_5F23, /*  0xe042 (U+6ef7) */
	C_KANJI_JIS_5F24, /*  0xe043 (U+6f86) */
	C_KANJI_JIS_5F25, /*  0xe044 (U+6f7a) */
	C_KANJI_JIS_5F26, /*  0xe045 (U+6f78) */
	C_KANJI_JIS_5F27, /*  0xe046 (U+6f81) */
	C_KANJI_JIS_5F28, /*  0xe047 (U+6f80) */
	C_KANJI_JIS_5F29, /*  0xe048 (U+6f6f) */
	C_KANJI_JIS_5F2A, /*  0xe049 (U+6f5b) */
	C_KANJI_JIS_5F2B, /*  0xe04a (U+6ff3) */
	C_KANJI_JIS_5F2C, /*  0xe04b (U+6f6d) */
	C_KANJI_JIS_5F2D, /*  0xe04c (U+6f82) */
	C_KANJI_JIS_5F2E, /*  0xe04d (U+6f7c) */
	C_KANJI_JIS_5F2F, /*  0xe04e (U+6f58) */
	C_KANJI_JIS_5F30, /*  0xe04f (U+6f8e) */
	C_KANJI_JIS_5F31, /*  0xe050 (U+6f91) */
	C_KANJI_JIS_5F32, /*  0xe051 (U+6fc2) */
	C_KANJI_JIS_5F33, /*  0xe052 (U+6f66) */
	C_KANJI_JIS_5F34, /*  0xe053 (U+6fb3) */
	C_KANJI_JIS_5F35, /*  0xe054 (U+6fa3) */
	C_KANJI_JIS_5F36, /*  0xe055 (U+6fa1) */
	C_KANJI_JIS_5F37, /*  0xe056 (U+6fa4) */
	C_KANJI_JIS_5F38, /*  0xe057 (U+6fb9) */
	C_KANJI_JIS_5F39, /*  0xe058 (U+6fc6) */
	C_KANJI_JIS_5F3A, /*  0xe059 (U+6faa) */
	C_KANJI_JIS_5F3B, /*  0xe05a (U+6fdf) */
	C_KANJI_JIS_5F3C, /*  0xe05b (U+6fd5) */
	C_KANJI_JIS_5F3D, /*  0xe05c (U+6fec) */
	C_KANJI_JIS_5F3E, /*  0xe05d (U+6fd4) */
	C_KANJI_JIS_5F3F, /*  0xe05e (U+6fd8) */
	C_KANJI_JIS_5F40, /*  0xe05f (U+6ff1) */
	C_KANJI_JIS_5F41, /*  0xe060 (U+6fee) */
	C_KANJI_JIS_5F42, /*  0xe061 (U+6fdb) */
	C_KANJI_JIS_5F43, /*  0xe062 (U+7009) */
	C_KANJI_JIS_5F44, /*  0xe063 (U+700b) */
	C_KANJI_JIS_5F45, /*  0xe064 (U+6ffa) */
	C_KANJI_JIS_5F46, /*  0xe065 (U+7011) */
	C_KANJI_JIS_5F47, /*  0xe066 (U+7001) */
	C_KANJI_JIS_5F48, /*  0xe067 (U+700f) */
	C_KANJI_JIS_5F49, /*  0xe068 (U+6ffe) */
	C_KANJI_JIS_5F4A, /*  0xe069 (U+701b) */
	C_KANJI_JIS_5F4B, /*  0xe06a (U+701a) */
	C_KANJI_JIS_5F4C, /*  0xe06b (U+6f74) */
	C_KANJI_JIS_5F4D, /*  0xe06c (U+701d) */
	C_KANJI_JIS_5F4E, /*  0xe06d (U+7018) */
	C_KANJI_JIS_5F4F, /*  0xe06e (U+701f) */
	C_KANJI_JIS_5F50, /*  0xe06f (U+7030) */
	C_KANJI_JIS_5F51, /*  0xe070 (U+703e) */
	C_KANJI_JIS_5F52, /*  0xe071 (U+7032) */
	C_KANJI_JIS_5F53, /*  0xe072 (U+7051) */
	C_KANJI_JIS_5F54, /*  0xe073 (U+7063) */
	C_KANJI_JIS_5F55, /*  0xe074 (U+7099) */
	C_KANJI_JIS_5F56, /*  0xe075 (U+7092) */
	C_KANJI_JIS_5F57, /*  0xe076 (U+70af) */
	C_KANJI_JIS_5F58, /*  0xe077 (U+70f1) */
	C_KANJI_JIS_5F59, /*  0xe078 (U+70ac) */
	C_KANJI_JIS_5F5A, /*  0xe079 (U+70b8) */
	C_KANJI_JIS_5F5B, /*  0xe07a (U+70b3) */
	C_KANJI_JIS_5F5C, /*  0xe07b (U+70ae) */
	C_KANJI_JIS_5F5D, /*  0xe07c (U+70df) */
	C_KANJI_JIS_5F5E, /*  0xe07d (U+70cb) */
	C_KANJI_JIS_5F5F, /*  0xe07e (U+70dd) */
	0, /*  0xe07f */
	C_KANJI_JIS_5F60, /*  0xe080 (U+70d9) */
	C_KANJI_JIS_5F61, /*  0xe081 (U+7109) */
	C_KANJI_JIS_5F62, /*  0xe082 (U+70fd) */
	C_KANJI_JIS_5F63, /*  0xe083 (U+711c) */
	C_KANJI_JIS_5F64, /*  0xe084 (U+7119) */
	C_KANJI_JIS_5F65, /*  0xe085 (U+7165) */
	C_KANJI_JIS_5F66, /*  0xe086 (U+7155) */
	C_KANJI_JIS_5F67, /*  0xe087 (U+7188) */
	C_KANJI_JIS_5F68, /*  0xe088 (U+7166) */
	C_KANJI_JIS_5F69, /*  0xe089 (U+7162) */
	C_KANJI_JIS_5F6A, /*  0xe08a (U+714c) */
	C_KANJI_JIS_5F6B, /*  0xe08b (U+7156) */
	C_KANJI_JIS_5F6C, /*  0xe08c (U+716c) */
	C_KANJI_JIS_5F6D, /*  0xe08d (U+718f) */
	C_KANJI_JIS_5F6E, /*  0xe08e (U+71fb) */
	C_KANJI_JIS_5F6F, /*  0xe08f (U+7184) */
	C_KANJI_JIS_5F70, /*  0xe090 (U+7195) */
	C_KANJI_JIS_5F71, /*  0xe091 (U+71a8) */
	C_KANJI_JIS_5F72, /*  0xe092 (U+71ac) */
	C_KANJI_JIS_5F73, /*  0xe093 (U+71d7) */
	C_KANJI_JIS_5F74, /*  0xe094 (U+71b9) */
	C_KANJI_JIS_5F75, /*  0xe095 (U+71be) */
	C_KANJI_JIS_5F76, /*  0xe096 (U+71d2) */
	C_KANJI_JIS_5F77, /*  0xe097 (U+71c9) */
	C_KANJI_JIS_5F78, /*  0xe098 (U+71d4) */
	C_KANJI_JIS_5F79, /*  0xe099 (U+71ce) */
	C_KANJI_JIS_5F7A, /*  0xe09a (U+71e0) */
	C_KANJI_JIS_5F7B, /*  0xe09b (U+71ec) */
	C_KANJI_JIS_5F7C, /*  0xe09c (U+71e7) */
	C_KANJI_JIS_5F7D, /*  0xe09d (U+71f5) */
	C_KANJI_JIS_5F7E, /*  0xe09e (U+71fc) */
	C_KANJI_JIS_6021, /*  0xe09f (U+71f9) */
	C_KANJI_JIS_6022, /*  0xe0a0 (U+71ff) */
	C_KANJI_JIS_6023, /*  0xe0a1 (U+720d) */
	C_KANJI_JIS_6024, /*  0xe0a2 (U+7210) */
	C_KANJI_JIS_6025, /*  0xe0a3 (U+721b) */
	C_KANJI_JIS_6026, /*  0xe0a4 (U+7228) */
	C_KANJI_JIS_6027, /*  0xe0a5 (U+722d) */
	C_KANJI_JIS_6028, /*  0xe0a6 (U+722c) */
	C_KANJI_JIS_6029, /*  0xe0a7 (U+7230) */
	C_KANJI_JIS_602A, /*  0xe0a8 (U+7232) */
	C_KANJI_JIS_602B, /*  0xe0a9 (U+723b) */
	C_KANJI_JIS_602C, /*  0xe0aa (U+723c) */
	C_KANJI_JIS_602D, /*  0xe0ab (U+723f) */
	C_KANJI_JIS_602E, /*  0xe0ac (U+7240) */
	C_KANJI_JIS_602F, /*  0xe0ad (U+7246) */
	C_KANJI_JIS_6030, /*  0xe0ae (U+724b) */
	C_KANJI_JIS_6031, /*  0xe0af (U+7258) */
	C_KANJI_JIS_6032, /*  0xe0b0 (U+7274) */
	C_KANJI_JIS_6033, /*  0xe0b1 (U+727e) */
	C_KANJI_JIS_6034, /*  0xe0b2 (U+7282) */
	C_KANJI_JIS_6035, /*  0xe0b3 (U+7281) */
	C_KANJI_JIS_6036, /*  0xe0b4 (U+7287) */
	C_KANJI_JIS_6037, /*  0xe0b5 (U+7292) */
	C_KANJI_JIS_6038, /*  0xe0b6 (U+7296) */
	C_KANJI_JIS_6039, /*  0xe0b7 (U+72a2) */
	C_KANJI_JIS_603A, /*  0xe0b8 (U+72a7) */
	C_KANJI_JIS_603B, /*  0xe0b9 (U+72b9) */
	C_KANJI_JIS_603C, /*  0xe0ba (U+72b2) */
	C_KANJI_JIS_603D, /*  0xe0bb (U+72c3) */
	C_KANJI_JIS_603E, /*  0xe0bc (U+72c6) */
	C_KANJI_JIS_603F, /*  0xe0bd (U+72c4) */
	C_KANJI_JIS_6040, /*  0xe0be (U+72ce) */
	C_KANJI_JIS_6041, /*  0xe0bf (U+72d2) */
	C_KANJI_JIS_6042, /*  0xe0c0 (U+72e2) */
	C_KANJI_JIS_6043, /*  0xe0c1 (U+72e0) */
	C_KANJI_JIS_6044, /*  0xe0c2 (U+72e1) */
	C_KANJI_JIS_6045, /*  0xe0c3 (U+72f9) */
	C_KANJI_JIS_6046, /*  0xe0c4 (U+72f7) */
	C_KANJI_JIS_6047, /*  0xe0c5 (U+500f) */
	C_KANJI_JIS_6048, /*  0xe0c6 (U+7317) */
	C_KANJI_JIS_6049, /*  0xe0c7 (U+730a) */
	C_KANJI_JIS_604A, /*  0xe0c8 (U+731c) */
	C_KANJI_JIS_604B, /*  0xe0c9 (U+7316) */
	C_KANJI_JIS_604C, /*  0xe0ca (U+731d) */
	C_KANJI_JIS_604D, /*  0xe0cb (U+7334) */
	C_KANJI_JIS_604E, /*  0xe0cc (U+732f) */
	C_KANJI_JIS_604F, /*  0xe0cd (U+7329) */
	C_KANJI_JIS_6050, /*  0xe0ce (U+7325) */
	C_KANJI_JIS_6051, /*  0xe0cf (U+733e) */
	C_KANJI_JIS_6052, /*  0xe0d0 (U+734e) */
	C_KANJI_JIS_6053, /*  0xe0d1 (U+734f) */
	C_KANJI_JIS_6054, /*  0xe0d2 (U+9ed8) */
	C_KANJI_JIS_6055, /*  0xe0d3 (U+7357) */
	C_KANJI_JIS_6056, /*  0xe0d4 (U+736a) */
	C_KANJI_JIS_6057, /*  0xe0d5 (U+7368) */
	C_KANJI_JIS_6058, /*  0xe0d6 (U+7370) */
	C_KANJI_JIS_6059, /*  0xe0d7 (U+7378) */
	C_KANJI_JIS_605A, /*  0xe0d8 (U+7375) */
	C_KANJI_JIS_605B, /*  0xe0d9 (U+737b) */
	C_KANJI_JIS_605C, /*  0xe0da (U+737a) */
	C_KANJI_JIS_605D, /*  0xe0db (U+73c8) */
	C_KANJI_JIS_605E, /*  0xe0dc (U+73b3) */
	C_KANJI_JIS_605F, /*  0xe0dd (U+73ce) */
	C_KANJI_JIS_6060, /*  0xe0de (U+73bb) */
	C_KANJI_JIS_6061, /*  0xe0df (U+73c0) */
	C_KANJI_JIS_6062, /*  0xe0e0 (U+73e5) */
	C_KANJI_JIS_6063, /*  0xe0e1 (U+73ee) */
	C_KANJI_JIS_6064, /*  0xe0e2 (U+73de) */
	C_KANJI_JIS_6065, /*  0xe0e3 (U+74a2) */
	C_KANJI_JIS_6066, /*  0xe0e4 (U+7405) */
	C_KANJI_JIS_6067, /*  0xe0e5 (U+746f) */
	C_KANJI_JIS_6068, /*  0xe0e6 (U+7425) */
	C_KANJI_JIS_6069, /*  0xe0e7 (U+73f8) */
	C_KANJI_JIS_606A, /*  0xe0e8 (U+7432) */
	C_KANJI_JIS_606B, /*  0xe0e9 (U+743a) */
	C_KANJI_JIS_606C, /*  0xe0ea (U+7455) */
	C_KANJI_JIS_606D, /*  0xe0eb (U+743f) */
	C_KANJI_JIS_606E, /*  0xe0ec (U+745f) */
	C_KANJI_JIS_606F, /*  0xe0ed (U+7459) */
	C_KANJI_JIS_6070, /*  0xe0ee (U+7441) */
	C_KANJI_JIS_6071, /*  0xe0ef (U+745c) */
	C_KANJI_JIS_6072, /*  0xe0f0 (U+7469) */
	C_KANJI_JIS_6073, /*  0xe0f1 (U+7470) */
	C_KANJI_JIS_6074, /*  0xe0f2 (U+7463) */
	C_KANJI_JIS_6075, /*  0xe0f3 (U+746a) */
	C_KANJI_JIS_6076, /*  0xe0f4 (U+7476) */
	C_KANJI_JIS_6077, /*  0xe0f5 (U+747e) */
	C_KANJI_JIS_6078, /*  0xe0f6 (U+748b) */
	C_KANJI_JIS_6079, /*  0xe0f7 (U+749e) */
	C_KANJI_JIS_607A, /*  0xe0f8 (U+74a7) */
	C_KANJI_JIS_607B, /*  0xe0f9 (U+74ca) */
	C_KANJI_JIS_607C, /*  0xe0fa (U+74cf) */
	C_KANJI_JIS_607D, /*  0xe0fb (U+74d4) */
	C_KANJI_JIS_607E, /*  0xe0fc (U+73f1) */
	0, /*  0xe0fd */
	0, /*  0xe0fe */
	0, /*  0xe0ff */
	C_KANJI_JIS_6121, /*  0xe140 (U+74e0) */
	C_KANJI_JIS_6122, /*  0xe141 (U+74e3) */
	C_KANJI_JIS_6123, /*  0xe142 (U+74e7) */
	C_KANJI_JIS_6124, /*  0xe143 (U+74e9) */
	C_KANJI_JIS_6125, /*  0xe144 (U+74ee) */
	C_KANJI_JIS_6126, /*  0xe145 (U+74f2) */
	C_KANJI_JIS_6127, /*  0xe146 (U+74f0) */
	C_KANJI_JIS_6128, /*  0xe147 (U+74f1) */
	C_KANJI_JIS_6129, /*  0xe148 (U+74f8) */
	C_KANJI_JIS_612A, /*  0xe149 (U+74f7) */
	C_KANJI_JIS_612B, /*  0xe14a (U+7504) */
	C_KANJI_JIS_612C, /*  0xe14b (U+7503) */
	C_KANJI_JIS_612D, /*  0xe14c (U+7505) */
	C_KANJI_JIS_612E, /*  0xe14d (U+750c) */
	C_KANJI_JIS_612F, /*  0xe14e (U+750e) */
	C_KANJI_JIS_6130, /*  0xe14f (U+750d) */
	C_KANJI_JIS_6131, /*  0xe150 (U+7515) */
	C_KANJI_JIS_6132, /*  0xe151 (U+7513) */
	C_KANJI_JIS_6133, /*  0xe152 (U+751e) */
	C_KANJI_JIS_6134, /*  0xe153 (U+7526) */
	C_KANJI_JIS_6135, /*  0xe154 (U+752c) */
	C_KANJI_JIS_6136, /*  0xe155 (U+753c) */
	C_KANJI_JIS_6137, /*  0xe156 (U+7544) */
	C_KANJI_JIS_6138, /*  0xe157 (U+754d) */
	C_KANJI_JIS_6139, /*  0xe158 (U+754a) */
	C_KANJI_JIS_613A, /*  0xe159 (U+7549) */
	C_KANJI_JIS_613B, /*  0xe15a (U+755b) */
	C_KANJI_JIS_613C, /*  0xe15b (U+7546) */
	C_KANJI_JIS_613D, /*  0xe15c (U+755a) */
	C_KANJI_JIS_613E, /*  0xe15d (U+7569) */
	C_KANJI_JIS_613F, /*  0xe15e (U+7564) */
	C_KANJI_JIS_6140, /*  0xe15f (U+7567) */
	C_KANJI_JIS_6141, /*  0xe160 (U+756b) */
	C_KANJI_JIS_6142, /*  0xe161 (U+756d) */
	C_KANJI_JIS_6143, /*  0xe162 (U+7578) */
	C_KANJI_JIS_6144, /*  0xe163 (U+7576) */
	C_KANJI_JIS_6145, /*  0xe164 (U+7586) */
	C_KANJI_JIS_6146, /*  0xe165 (U+7587) */
	C_KANJI_JIS_6147, /*  0xe166 (U+7574) */
	C_KANJI_JIS_6148, /*  0xe167 (U+758a) */
	C_KANJI_JIS_6149, /*  0xe168 (U+7589) */
	C_KANJI_JIS_614A, /*  0xe169 (U+7582) */
	C_KANJI_JIS_614B, /*  0xe16a (U+7594) */
	C_KANJI_JIS_614C, /*  0xe16b (U+759a) */
	C_KANJI_JIS_614D, /*  0xe16c (U+759d) */
	C_KANJI_JIS_614E, /*  0xe16d (U+75a5) */
	C_KANJI_JIS_614F, /*  0xe16e (U+75a3) */
	C_KANJI_JIS_6150, /*  0xe16f (U+75c2) */
	C_KANJI_JIS_6151, /*  0xe170 (U+75b3) */
	C_KANJI_JIS_6152, /*  0xe171 (U+75c3) */
	C_KANJI_JIS_6153, /*  0xe172 (U+75b5) */
	C_KANJI_JIS_6154, /*  0xe173 (U+75bd) */
	C_KANJI_JIS_6155, /*  0xe174 (U+75b8) */
	C_KANJI_JIS_6156, /*  0xe175 (U+75bc) */
	C_KANJI_JIS_6157, /*  0xe176 (U+75b1) */
	C_KANJI_JIS_6158, /*  0xe177 (U+75cd) */
	C_KANJI_JIS_6159, /*  0xe178 (U+75ca) */
	C_KANJI_JIS_615A, /*  0xe179 (U+75d2) */
	C_KANJI_JIS_615B, /*  0xe17a (U+75d9) */
	C_KANJI_JIS_615C, /*  0xe17b (U+75e3) */
	C_KANJI_JIS_615D, /*  0xe17c (U+75de) */
	C_KANJI_JIS_615E, /*  0xe17d (U+75fe) */
	C_KANJI_JIS_615F, /*  0xe17e (U+75ff) */
	0, /*  0xe17f */
	C_KANJI_JIS_6160, /*  0xe180 (U+75fc) */
	C_KANJI_JIS_6161, /*  0xe181 (U+7601) */
	C_KANJI_JIS_6162, /*  0xe182 (U+75f0) */
	C_KANJI_JIS_6163, /*  0xe183 (U+75fa) */
	C_KANJI_JIS_6164, /*  0xe184 (U+75f2) */
	C_KANJI_JIS_6165, /*  0xe185 (U+75f3) */
	C_KANJI_JIS_6166, /*  0xe186 (U+760b) */
	C_KANJI_JIS_6167, /*  0xe187 (U+760d) */
	C_KANJI_JIS_6168, /*  0xe188 (U+7609) */
	C_KANJI_JIS_6169, /*  0xe189 (U+761f) */
	C_KANJI_JIS_616A, /*  0xe18a (U+7627) */
	C_KANJI_JIS_616B, /*  0xe18b (U+7620) */
	C_KANJI_JIS_616C, /*  0xe18c (U+7621) */
	C_KANJI_JIS_616D, /*  0xe18d (U+7622) */
	C_KANJI_JIS_616E, /*  0xe18e (U+7624) */
	C_KANJI_JIS_616F, /*  0xe18f (U+7634) */
	C_KANJI_JIS_6170, /*  0xe190 (U+7630) */
	C_KANJI_JIS_6171, /*  0xe191 (U+763b) */
	C_KANJI_JIS_6172, /*  0xe192 (U+7647) */
	C_KANJI_JIS_6173, /*  0xe193 (U+7648) */
	C_KANJI_JIS_6174, /*  0xe194 (U+7646) */
	C_KANJI_JIS_6175, /*  0xe195 (U+765c) */
	C_KANJI_JIS_6176, /*  0xe196 (U+7658) */
	C_KANJI_JIS_6177, /*  0xe197 (U+7661) */
	C_KANJI_JIS_6178, /*  0xe198 (U+7662) */
	C_KANJI_JIS_6179, /*  0xe199 (U+7668) */
	C_KANJI_JIS_617A, /*  0xe19a (U+7669) */
	C_KANJI_JIS_617B, /*  0xe19b (U+766a) */
	C_KANJI_JIS_617C, /*  0xe19c (U+7667) */
	C_KANJI_JIS_617D, /*  0xe19d (U+766c) */
	C_KANJI_JIS_617E, /*  0xe19e (U+7670) */
	C_KANJI_JIS_6221, /*  0xe19f (U+7672) */
	C_KANJI_JIS_6222, /*  0xe1a0 (U+7676) */
	C_KANJI_JIS_6223, /*  0xe1a1 (U+7678) */
	C_KANJI_JIS_6224, /*  0xe1a2 (U+767c) */
	C_KANJI_JIS_6225, /*  0xe1a3 (U+7680) */
	C_KANJI_JIS_6226, /*  0xe1a4 (U+7683) */
	C_KANJI_JIS_6227, /*  0xe1a5 (U+7688) */
	C_KANJI_JIS_6228, /*  0xe1a6 (U+768b) */
	C_KANJI_JIS_6229, /*  0xe1a7 (U+768e) */
	C_KANJI_JIS_622A, /*  0xe1a8 (U+7696) */
	C_KANJI_JIS_622B, /*  0xe1a9 (U+7693) */
	C_KANJI_JIS_622C, /*  0xe1aa (U+7699) */
	C_KANJI_JIS_622D, /*  0xe1ab (U+769a) */
	C_KANJI_JIS_622E, /*  0xe1ac (U+76b0) */
	C_KANJI_JIS_622F, /*  0xe1ad (U+76b4) */
	C_KANJI_JIS_6230, /*  0xe1ae (U+76b8) */
	C_KANJI_JIS_6231, /*  0xe1af (U+76b9) */
	C_KANJI_JIS_6232, /*  0xe1b0 (U+76ba) */
	C_KANJI_JIS_6233, /*  0xe1b1 (U+76c2) */
	C_KANJI_JIS_6234, /*  0xe1b2 (U+76cd) */
	C_KANJI_JIS_6235, /*  0xe1b3 (U+76d6) */
	C_KANJI_JIS_6236, /*  0xe1b4 (U+76d2) */
	C_KANJI_JIS_6237, /*  0xe1b5 (U+76de) */
	C_KANJI_JIS_6238, /*  0xe1b6 (U+76e1) */
	C_KANJI_JIS_6239, /*  0xe1b7 (U+76e5) */
	C_KANJI_JIS_623A, /*  0xe1b8 (U+76e7) */
	C_KANJI_JIS_623B, /*  0xe1b9 (U+76ea) */
	C_KANJI_JIS_623C, /*  0xe1ba (U+862f) */
	C_KANJI_JIS_623D, /*  0xe1bb (U+76fb) */
	C_KANJI_JIS_623E, /*  0xe1bc (U+7708) */
	C_KANJI_JIS_623F, /*  0xe1bd (U+7707) */
	C_KANJI_JIS_6240, /*  0xe1be (U+7704) */
	C_KANJI_JIS_6241, /*  0xe1bf (U+7729) */
	C_KANJI_JIS_6242, /*  0xe1c0 (U+7724) */
	C_KANJI_JIS_6243, /*  0xe1c1 (U+771e) */
	C_KANJI_JIS_6244, /*  0xe1c2 (U+7725) */
	C_KANJI_JIS_6245, /*  0xe1c3 (U+7726) */
	C_KANJI_JIS_6246, /*  0xe1c4 (U+771b) */
	C_KANJI_JIS_6247, /*  0xe1c5 (U+7737) */
	C_KANJI_JIS_6248, /*  0xe1c6 (U+7738) */
	C_KANJI_JIS_6249, /*  0xe1c7 (U+7747) */
	C_KANJI_JIS_624A, /*  0xe1c8 (U+775a) */
	C_KANJI_JIS_624B, /*  0xe1c9 (U+7768) */
	C_KANJI_JIS_624C, /*  0xe1ca (U+776b) */
	C_KANJI_JIS_624D, /*  0xe1cb (U+775b) */
	C_KANJI_JIS_624E, /*  0xe1cc (U+7765) */
	C_KANJI_JIS_624F, /*  0xe1cd (U+777f) */
	C_KANJI_JIS_6250, /*  0xe1ce (U+777e) */
	C_KANJI_JIS_6251, /*  0xe1cf (U+7779) */
	C_KANJI_JIS_6252, /*  0xe1d0 (U+778e) */
	C_KANJI_JIS_6253, /*  0xe1d1 (U+778b) */
	C_KANJI_JIS_6254, /*  0xe1d2 (U+7791) */
	C_KANJI_JIS_6255, /*  0xe1d3 (U+77a0) */
	C_KANJI_JIS_6256, /*  0xe1d4 (U+779e) */
	C_KANJI_JIS_6257, /*  0xe1d5 (U+77b0) */
	C_KANJI_JIS_6258, /*  0xe1d6 (U+77b6) */
	C_KANJI_JIS_6259, /*  0xe1d7 (U+77b9) */
	C_KANJI_JIS_625A, /*  0xe1d8 (U+77bf) */
	C_KANJI_JIS_625B, /*  0xe1d9 (U+77bc) */
	C_KANJI_JIS_625C, /*  0xe1da (U+77bd) */
	C_KANJI_JIS_625D, /*  0xe1db (U+77bb) */
	C_KANJI_JIS_625E, /*  0xe1dc (U+77c7) */
	C_KANJI_JIS_625F, /*  0xe1dd (U+77cd) */
	C_KANJI_JIS_6260, /*  0xe1de (U+77d7) */
	C_KANJI_JIS_6261, /*  0xe1df (U+77da) */
	C_KANJI_JIS_6262, /*  0xe1e0 (U+77dc) */
	C_KANJI_JIS_6263, /*  0xe1e1 (U+77e3) */
	C_KANJI_JIS_6264, /*  0xe1e2 (U+77ee) */
	C_KANJI_JIS_6265, /*  0xe1e3 (U+77fc) */
	C_KANJI_JIS_6266, /*  0xe1e4 (U+780c) */
	C_KANJI_JIS_6267, /*  0xe1e5 (U+7812) */
	C_KANJI_JIS_6268, /*  0xe1e6 (U+7926) */
	C_KANJI_JIS_6269, /*  0xe1e7 (U+7820) */
	C_KANJI_JIS_626A, /*  0xe1e8 (U+792a) */
	C_KANJI_JIS_626B, /*  0xe1e9 (U+7845) */
	C_KANJI_JIS_626C, /*  0xe1ea (U+788e) */
	C_KANJI_JIS_626D, /*  0xe1eb (U+7874) */
	C_KANJI_JIS_626E, /*  0xe1ec (U+7886) */
	C_KANJI_JIS_626F, /*  0xe1ed (U+787c) */
	C_KANJI_JIS_6270, /*  0xe1ee (U+789a) */
	C_KANJI_JIS_6271, /*  0xe1ef (U+788c) */
	C_KANJI_JIS_6272, /*  0xe1f0 (U+78a3) */
	C_KANJI_JIS_6273, /*  0xe1f1 (U+78b5) */
	C_KANJI_JIS_6274, /*  0xe1f2 (U+78aa) */
	C_KANJI_JIS_6275, /*  0xe1f3 (U+78af) */
	C_KANJI_JIS_6276, /*  0xe1f4 (U+78d1) */
	C_KANJI_JIS_6277, /*  0xe1f5 (U+78c6) */
	C_KANJI_JIS_6278, /*  0xe1f6 (U+78cb) */
	C_KANJI_JIS_6279, /*  0xe1f7 (U+78d4) */
	C_KANJI_JIS_627A, /*  0xe1f8 (U+78be) */
	C_KANJI_JIS_627B, /*  0xe1f9 (U+78bc) */
	C_KANJI_JIS_627C, /*  0xe1fa (U+78c5) */
	C_KANJI_JIS_627D, /*  0xe1fb (U+78ca) */
	C_KANJI_JIS_627E, /*  0xe1fc (U+78ec) */
	0, /*  0xe1fd */
	0, /*  0xe1fe */
	0, /*  0xe1ff */
	C_KANJI_JIS_6321, /*  0xe240 (U+78e7) */
	C_KANJI_JIS_6322, /*  0xe241 (U+78da) */
	C_KANJI_JIS_6323, /*  0xe242 (U+78fd) */
	C_KANJI_JIS_6324, /*  0xe243 (U+78f4) */
	C_KANJI_JIS_6325, /*  0xe244 (U+7907) */
	C_KANJI_JIS_6326, /*  0xe245 (U+7912) */
	C_KANJI_JIS_6327, /*  0xe246 (U+7911) */
	C_KANJI_JIS_6328, /*  0xe247 (U+7919) */
	C_KANJI_JIS_6329, /*  0xe248 (U+792c) */
	C_KANJI_JIS_632A, /*  0xe249 (U+792b) */
	C_KANJI_JIS_632B, /*  0xe24a (U+7940) */
	C_KANJI_JIS_632C, /*  0xe24b (U+7960) */
	C_KANJI_JIS_632D, /*  0xe24c (U+7957) */
	C_KANJI_JIS_632E, /*  0xe24d (U+795f) */
	C_KANJI_JIS_632F, /*  0xe24e (U+795a) */
	C_KANJI_JIS_6330, /*  0xe24f (U+7955) */
	C_KANJI_JIS_6331, /*  0xe250 (U+7953) */
	C_KANJI_JIS_6332, /*  0xe251 (U+797a) */
	C_KANJI_JIS_6333, /*  0xe252 (U+797f) */
	C_KANJI_JIS_6334, /*  0xe253 (U+798a) */
	C_KANJI_JIS_6335, /*  0xe254 (U+799d) */
	C_KANJI_JIS_6336, /*  0xe255 (U+79a7) */
	C_KANJI_JIS_6337, /*  0xe256 (U+9f4b) */
	C_KANJI_JIS_6338, /*  0xe257 (U+79aa) */
	C_KANJI_JIS_6339, /*  0xe258 (U+79ae) */
	C_KANJI_JIS_633A, /*  0xe259 (U+79b3) */
	C_KANJI_JIS_633B, /*  0xe25a (U+79b9) */
	C_KANJI_JIS_633C, /*  0xe25b (U+79ba) */
	C_KANJI_JIS_633D, /*  0xe25c (U+79c9) */
	C_KANJI_JIS_633E, /*  0xe25d (U+79d5) */
	C_KANJI_JIS_633F, /*  0xe25e (U+79e7) */
	C_KANJI_JIS_6340, /*  0xe25f (U+79ec) */
	C_KANJI_JIS_6341, /*  0xe260 (U+79e1) */
	C_KANJI_JIS_6342, /*  0xe261 (U+79e3) */
	C_KANJI_JIS_6343, /*  0xe262 (U+7a08) */
	C_KANJI_JIS_6344, /*  0xe263 (U+7a0d) */
	C_KANJI_JIS_6345, /*  0xe264 (U+7a18) */
	C_KANJI_JIS_6346, /*  0xe265 (U+7a19) */
	C_KANJI_JIS_6347, /*  0xe266 (U+7a20) */
	C_KANJI_JIS_6348, /*  0xe267 (U+7a1f) */
	C_KANJI_JIS_6349, /*  0xe268 (U+7980) */
	C_KANJI_JIS_634A, /*  0xe269 (U+7a31) */
	C_KANJI_JIS_634B, /*  0xe26a (U+7a3b) */
	C_KANJI_JIS_634C, /*  0xe26b (U+7a3e) */
	C_KANJI_JIS_634D, /*  0xe26c (U+7a37) */
	C_KANJI_JIS_634E, /*  0xe26d (U+7a43) */
	C_KANJI_JIS_634F, /*  0xe26e (U+7a57) */
	C_KANJI_JIS_6350, /*  0xe26f (U+7a49) */
	C_KANJI_JIS_6351, /*  0xe270 (U+7a61) */
	C_KANJI_JIS_6352, /*  0xe271 (U+7a62) */
	C_KANJI_JIS_6353, /*  0xe272 (U+7a69) */
	C_KANJI_JIS_6354, /*  0xe273 (U+9f9d) */
	C_KANJI_JIS_6355, /*  0xe274 (U+7a70) */
	C_KANJI_JIS_6356, /*  0xe275 (U+7a79) */
	C_KANJI_JIS_6357, /*  0xe276 (U+7a7d) */
	C_KANJI_JIS_6358, /*  0xe277 (U+7a88) */
	C_KANJI_JIS_6359, /*  0xe278 (U+7a97) */
	C_KANJI_JIS_635A, /*  0xe279 (U+7a95) */
	C_KANJI_JIS_635B, /*  0xe27a (U+7a98) */
	C_KANJI_JIS_635C, /*  0xe27b (U+7a96) */
	C_KANJI_JIS_635D, /*  0xe27c (U+7aa9) */
	C_KANJI_JIS_635E, /*  0xe27d (U+7ac8) */
	C_KANJI_JIS_635F, /*  0xe27e (U+7ab0) */
	0, /*  0xe27f */
	C_KANJI_JIS_6360, /*  0xe280 (U+7ab6) */
	C_KANJI_JIS_6361, /*  0xe281 (U+7ac5) */
	C_KANJI_JIS_6362, /*  0xe282 (U+7ac4) */
	C_KANJI_JIS_6363, /*  0xe283 (U+7abf) */
	C_KANJI_JIS_6364, /*  0xe284 (U+9083) */
	C_KANJI_JIS_6365, /*  0xe285 (U+7ac7) */
	C_KANJI_JIS_6366, /*  0xe286 (U+7aca) */
	C_KANJI_JIS_6367, /*  0xe287 (U+7acd) */
	C_KANJI_JIS_6368, /*  0xe288 (U+7acf) */
	C_KANJI_JIS_6369, /*  0xe289 (U+7ad5) */
	C_KANJI_JIS_636A, /*  0xe28a (U+7ad3) */
	C_KANJI_JIS_636B, /*  0xe28b (U+7ad9) */
	C_KANJI_JIS_636C, /*  0xe28c (U+7ada) */
	C_KANJI_JIS_636D, /*  0xe28d (U+7add) */
	C_KANJI_JIS_636E, /*  0xe28e (U+7ae1) */
	C_KANJI_JIS_636F, /*  0xe28f (U+7ae2) */
	C_KANJI_JIS_6370, /*  0xe290 (U+7ae6) */
	C_KANJI_JIS_6371, /*  0xe291 (U+7aed) */
	C_KANJI_JIS_6372, /*  0xe292 (U+7af0) */
	C_KANJI_JIS_6373, /*  0xe293 (U+7b02) */
	C_KANJI_JIS_6374, /*  0xe294 (U+7b0f) */
	C_KANJI_JIS_6375, /*  0xe295 (U+7b0a) */
	C_KANJI_JIS_6376, /*  0xe296 (U+7b06) */
	C_KANJI_JIS_6377, /*  0xe297 (U+7b33) */
	C_KANJI_JIS_6378, /*  0xe298 (U+7b18) */
	C_KANJI_JIS_6379, /*  0xe299 (U+7b19) */
	C_KANJI_JIS_637A, /*  0xe29a (U+7b1e) */
	C_KANJI_JIS_637B, /*  0xe29b (U+7b35) */
	C_KANJI_JIS_637C, /*  0xe29c (U+7b28) */
	C_KANJI_JIS_637D, /*  0xe29d (U+7b36) */
	C_KANJI_JIS_637E, /*  0xe29e (U+7b50) */
	C_KANJI_JIS_6421, /*  0xe29f (U+7b7a) */
	C_KANJI_JIS_6422, /*  0xe2a0 (U+7b04) */
	C_KANJI_JIS_6423, /*  0xe2a1 (U+7b4d) */
	C_KANJI_JIS_6424, /*  0xe2a2 (U+7b0b) */
	C_KANJI_JIS_6425, /*  0xe2a3 (U+7b4c) */
	C_KANJI_JIS_6426, /*  0xe2a4 (U+7b45) */
	C_KANJI_JIS_6427, /*  0xe2a5 (U+7b75) */
	C_KANJI_JIS_6428, /*  0xe2a6 (U+7b65) */
	C_KANJI_JIS_6429, /*  0xe2a7 (U+7b74) */
	C_KANJI_JIS_642A, /*  0xe2a8 (U+7b67) */
	C_KANJI_JIS_642B, /*  0xe2a9 (U+7b70) */
	C_KANJI_JIS_642C, /*  0xe2aa (U+7b71) */
	C_KANJI_JIS_642D, /*  0xe2ab (U+7b6c) */
	C_KANJI_JIS_642E, /*  0xe2ac (U+7b6e) */
	C_KANJI_JIS_642F, /*  0xe2ad (U+7b9d) */
	C_KANJI_JIS_6430, /*  0xe2ae (U+7b98) */
	C_KANJI_JIS_6431, /*  0xe2af (U+7b9f) */
	C_KANJI_JIS_6432, /*  0xe2b0 (U+7b8d) */
	C_KANJI_JIS_6433, /*  0xe2b1 (U+7b9c) */
	C_KANJI_JIS_6434, /*  0xe2b2 (U+7b9a) */
	C_KANJI_JIS_6435, /*  0xe2b3 (U+7b8b) */
	C_KANJI_JIS_6436, /*  0xe2b4 (U+7b92) */
	C_KANJI_JIS_6437, /*  0xe2b5 (U+7b8f) */
	C_KANJI_JIS_6438, /*  0xe2b6 (U+7b5d) */
	C_KANJI_JIS_6439, /*  0xe2b7 (U+7b99) */
	C_KANJI_JIS_643A, /*  0xe2b8 (U+7bcb) */
	C_KANJI_JIS_643B, /*  0xe2b9 (U+7bc1) */
	C_KANJI_JIS_643C, /*  0xe2ba (U+7bcc) */
	C_KANJI_JIS_643D, /*  0xe2bb (U+7bcf) */
	C_KANJI_JIS_643E, /*  0xe2bc (U+7bb4) */
	C_KANJI_JIS_643F, /*  0xe2bd (U+7bc6) */
	C_KANJI_JIS_6440, /*  0xe2be (U+7bdd) */
	C_KANJI_JIS_6441, /*  0xe2bf (U+7be9) */
	C_KANJI_JIS_6442, /*  0xe2c0 (U+7c11) */
	C_KANJI_JIS_6443, /*  0xe2c1 (U+7c14) */
	C_KANJI_JIS_6444, /*  0xe2c2 (U+7be6) */
	C_KANJI_JIS_6445, /*  0xe2c3 (U+7be5) */
	C_KANJI_JIS_6446, /*  0xe2c4 (U+7c60) */
	C_KANJI_JIS_6447, /*  0xe2c5 (U+7c00) */
	C_KANJI_JIS_6448, /*  0xe2c6 (U+7c07) */
	C_KANJI_JIS_6449, /*  0xe2c7 (U+7c13) */
	C_KANJI_JIS_644A, /*  0xe2c8 (U+7bf3) */
	C_KANJI_JIS_644B, /*  0xe2c9 (U+7bf7) */
	C_KANJI_JIS_644C, /*  0xe2ca (U+7c17) */
	C_KANJI_JIS_644D, /*  0xe2cb (U+7c0d) */
	C_KANJI_JIS_644E, /*  0xe2cc (U+7bf6) */
	C_KANJI_JIS_644F, /*  0xe2cd (U+7c23) */
	C_KANJI_JIS_6450, /*  0xe2ce (U+7c27) */
	C_KANJI_JIS_6451, /*  0xe2cf (U+7c2a) */
	C_KANJI_JIS_6452, /*  0xe2d0 (U+7c1f) */
	C_KANJI_JIS_6453, /*  0xe2d1 (U+7c37) */
	C_KANJI_JIS_6454, /*  0xe2d2 (U+7c2b) */
	C_KANJI_JIS_6455, /*  0xe2d3 (U+7c3d) */
	C_KANJI_JIS_6456, /*  0xe2d4 (U+7c4c) */
	C_KANJI_JIS_6457, /*  0xe2d5 (U+7c43) */
	C_KANJI_JIS_6458, /*  0xe2d6 (U+7c54) */
	C_KANJI_JIS_6459, /*  0xe2d7 (U+7c4f) */
	C_KANJI_JIS_645A, /*  0xe2d8 (U+7c40) */
	C_KANJI_JIS_645B, /*  0xe2d9 (U+7c50) */
	C_KANJI_JIS_645C, /*  0xe2da (U+7c58) */
	C_KANJI_JIS_645D, /*  0xe2db (U+7c5f) */
	C_KANJI_JIS_645E, /*  0xe2dc (U+7c64) */
	C_KANJI_JIS_645F, /*  0xe2dd (U+7c56) */
	C_KANJI_JIS_6460, /*  0xe2de (U+7c65) */
	C_KANJI_JIS_6461, /*  0xe2df (U+7c6c) */
	C_KANJI_JIS_6462, /*  0xe2e0 (U+7c75) */
	C_KANJI_JIS_6463, /*  0xe2e1 (U+7c83) */
	C_KANJI_JIS_6464, /*  0xe2e2 (U+7c90) */
	C_KANJI_JIS_6465, /*  0xe2e3 (U+7ca4) */
	C_KANJI_JIS_6466, /*  0xe2e4 (U+7cad) */
	C_KANJI_JIS_6467, /*  0xe2e5 (U+7ca2) */
	C_KANJI_JIS_6468, /*  0xe2e6 (U+7cab) */
	C_KANJI_JIS_6469, /*  0xe2e7 (U+7ca1) */
	C_KANJI_JIS_646A, /*  0xe2e8 (U+7ca8) */
	C_KANJI_JIS_646B, /*  0xe2e9 (U+7cb3) */
	C_KANJI_JIS_646C, /*  0xe2ea (U+7cb2) */
	C_KANJI_JIS_646D, /*  0xe2eb (U+7cb1) */
	C_KANJI_JIS_646E, /*  0xe2ec (U+7cae) */
	C_KANJI_JIS_646F, /*  0xe2ed (U+7cb9) */
	C_KANJI_JIS_6470, /*  0xe2ee (U+7cbd) */
	C_KANJI_JIS_6471, /*  0xe2ef (U+7cc0) */
	C_KANJI_JIS_6472, /*  0xe2f0 (U+7cc5) */
	C_KANJI_JIS_6473, /*  0xe2f1 (U+7cc2) */
	C_KANJI_JIS_6474, /*  0xe2f2 (U+7cd8) */
	C_KANJI_JIS_6475, /*  0xe2f3 (U+7cd2) */
	C_KANJI_JIS_6476, /*  0xe2f4 (U+7cdc) */
	C_KANJI_JIS_6477, /*  0xe2f5 (U+7ce2) */
	C_KANJI_JIS_6478, /*  0xe2f6 (U+9b3b) */
	C_KANJI_JIS_6479, /*  0xe2f7 (U+7cef) */
	C_KANJI_JIS_647A, /*  0xe2f8 (U+7cf2) */
	C_KANJI_JIS_647B, /*  0xe2f9 (U+7cf4) */
	C_KANJI_JIS_647C, /*  0xe2fa (U+7cf6) */
	C_KANJI_JIS_647D, /*  0xe2fb (U+7cfa) */
	C_KANJI_JIS_647E, /*  0xe2fc (U+7d06) */
	0, /*  0xe2fd */
	0, /*  0xe2fe */
	0, /*  0xe2ff */
	C_KANJI_JIS_6521, /*  0xe340 (U+7d02) */
	C_KANJI_JIS_6522, /*  0xe341 (U+7d1c) */
	C_KANJI_JIS_6523, /*  0xe342 (U+7d15) */
	C_KANJI_JIS_6524, /*  0xe343 (U+7d0a) */
	C_KANJI_JIS_6525, /*  0xe344 (U+7d45) */
	C_KANJI_JIS_6526, /*  0xe345 (U+7d4b) */
	C_KANJI_JIS_6527, /*  0xe346 (U+7d2e) */
	C_KANJI_JIS_6528, /*  0xe347 (U+7d32) */
	C_KANJI_JIS_6529, /*  0xe348 (U+7d3f) */
	C_KANJI_JIS_652A, /*  0xe349 (U+7d35) */
	C_KANJI_JIS_652B, /*  0xe34a (U+7d46) */
	C_KANJI_JIS_652C, /*  0xe34b (U+7d73) */
	C_KANJI_JIS_652D, /*  0xe34c (U+7d56) */
	C_KANJI_JIS_652E, /*  0xe34d (U+7d4e) */
	C_KANJI_JIS_652F, /*  0xe34e (U+7d72) */
	C_KANJI_JIS_6530, /*  0xe34f (U+7d68) */
	C_KANJI_JIS_6531, /*  0xe350 (U+7d6e) */
	C_KANJI_JIS_6532, /*  0xe351 (U+7d4f) */
	C_KANJI_JIS_6533, /*  0xe352 (U+7d63) */
	C_KANJI_JIS_6534, /*  0xe353 (U+7d93) */
	C_KANJI_JIS_6535, /*  0xe354 (U+7d89) */
	C_KANJI_JIS_6536, /*  0xe355 (U+7d5b) */
	C_KANJI_JIS_6537, /*  0xe356 (U+7d8f) */
	C_KANJI_JIS_6538, /*  0xe357 (U+7d7d) */
	C_KANJI_JIS_6539, /*  0xe358 (U+7d9b) */
	C_KANJI_JIS_653A, /*  0xe359 (U+7dba) */
	C_KANJI_JIS_653B, /*  0xe35a (U+7dae) */
	C_KANJI_JIS_653C, /*  0xe35b (U+7da3) */
	C_KANJI_JIS_653D, /*  0xe35c (U+7db5) */
	C_KANJI_JIS_653E, /*  0xe35d (U+7dc7) */
	C_KANJI_JIS_653F, /*  0xe35e (U+7dbd) */
	C_KANJI_JIS_6540, /*  0xe35f (U+7dab) */
	C_KANJI_JIS_6541, /*  0xe360 (U+7e3d) */
	C_KANJI_JIS_6542, /*  0xe361 (U+7da2) */
	C_KANJI_JIS_6543, /*  0xe362 (U+7daf) */
	C_KANJI_JIS_6544, /*  0xe363 (U+7ddc) */
	C_KANJI_JIS_6545, /*  0xe364 (U+7db8) */
	C_KANJI_JIS_6546, /*  0xe365 (U+7d9f) */
	C_KANJI_JIS_6547, /*  0xe366 (U+7db0) */
	C_KANJI_JIS_6548, /*  0xe367 (U+7dd8) */
	C_KANJI_JIS_6549, /*  0xe368 (U+7ddd) */
	C_KANJI_JIS_654A, /*  0xe369 (U+7de4) */
	C_KANJI_JIS_654B, /*  0xe36a (U+7dde) */
	C_KANJI_JIS_654C, /*  0xe36b (U+7dfb) */
	C_KANJI_JIS_654D, /*  0xe36c (U+7df2) */
	C_KANJI_JIS_654E, /*  0xe36d (U+7de1) */
	C_KANJI_JIS_654F, /*  0xe36e (U+7e05) */
	C_KANJI_JIS_6550, /*  0xe36f (U+7e0a) */
	C_KANJI_JIS_6551, /*  0xe370 (U+7e23) */
	C_KANJI_JIS_6552, /*  0xe371 (U+7e21) */
	C_KANJI_JIS_6553, /*  0xe372 (U+7e12) */
	C_KANJI_JIS_6554, /*  0xe373 (U+7e31) */
	C_KANJI_JIS_6555, /*  0xe374 (U+7e1f) */
	C_KANJI_JIS_6556, /*  0xe375 (U+7e09) */
	C_KANJI_JIS_6557, /*  0xe376 (U+7e0b) */
	C_KANJI_JIS_6558, /*  0xe377 (U+7e22) */
	C_KANJI_JIS_6559, /*  0xe378 (U+7e46) */
	C_KANJI_JIS_655A, /*  0xe379 (U+7e66) */
	C_KANJI_JIS_655B, /*  0xe37a (U+7e3b) */
	C_KANJI_JIS_655C, /*  0xe37b (U+7e35) */
	C_KANJI_JIS_655D, /*  0xe37c (U+7e39) */
	C_KANJI_JIS_655E, /*  0xe37d (U+7e43) */
	C_KANJI_JIS_655F, /*  0xe37e (U+7e37) */
	0, /*  0xe37f */
	C_KANJI_JIS_6560, /*  0xe380 (U+7e32) */
	C_KANJI_JIS_6561, /*  0xe381 (U+7e3a) */
	C_KANJI_JIS_6562, /*  0xe382 (U+7e67) */
	C_KANJI_JIS_6563, /*  0xe383 (U+7e5d) */
	C_KANJI_JIS_6564, /*  0xe384 (U+7e56) */
	C_KANJI_JIS_6565, /*  0xe385 (U+7e5e) */
	C_KANJI_JIS_6566, /*  0xe386 (U+7e59) */
	C_KANJI_JIS_6567, /*  0xe387 (U+7e5a) */
	C_KANJI_JIS_6568, /*  0xe388 (U+7e79) */
	C_KANJI_JIS_6569, /*  0xe389 (U+7e6a) */
	C_KANJI_JIS_656A, /*  0xe38a (U+7e69) */
	C_KANJI_JIS_656B, /*  0xe38b (U+7e7c) */
	C_KANJI_JIS_656C, /*  0xe38c (U+7e7b) */
	C_KANJI_JIS_656D, /*  0xe38d (U+7e83) */
	C_KANJI_JIS_656E, /*  0xe38e (U+7dd5) */
	C_KANJI_JIS_656F, /*  0xe38f (U+7e7d) */
	C_KANJI_JIS_6570, /*  0xe390 (U+8fae) */
	C_KANJI_JIS_6571, /*  0xe391 (U+7e7f) */
	C_KANJI_JIS_6572, /*  0xe392 (U+7e88) */
	C_KANJI_JIS_6573, /*  0xe393 (U+7e89) */
	C_KANJI_JIS_6574, /*  0xe394 (U+7e8c) */
	C_KANJI_JIS_6575, /*  0xe395 (U+7e92) */
	C_KANJI_JIS_6576, /*  0xe396 (U+7e90) */
	C_KANJI_JIS_6577, /*  0xe397 (U+7e93) */
	C_KANJI_JIS_6578, /*  0xe398 (U+7e94) */
	C_KANJI_JIS_6579, /*  0xe399 (U+7e96) */
	C_KANJI_JIS_657A, /*  0xe39a (U+7e8e) */
	C_KANJI_JIS_657B, /*  0xe39b (U+7e9b) */
	C_KANJI_JIS_657C, /*  0xe39c (U+7e9c) */
	C_KANJI_JIS_657D, /*  0xe39d (U+7f38) */
	C_KANJI_JIS_657E, /*  0xe39e (U+7f3a) */
	C_KANJI_JIS_6621, /*  0xe39f (U+7f45) */
	C_KANJI_JIS_6622, /*  0xe3a0 (U+7f4c) */
	C_KANJI_JIS_6623, /*  0xe3a1 (U+7f4d) */
	C_KANJI_JIS_6624, /*  0xe3a2 (U+7f4e) */
	C_KANJI_JIS_6625, /*  0xe3a3 (U+7f50) */
	C_KANJI_JIS_6626, /*  0xe3a4 (U+7f51) */
	C_KANJI_JIS_6627, /*  0xe3a5 (U+7f55) */
	C_KANJI_JIS_6628, /*  0xe3a6 (U+7f54) */
	C_KANJI_JIS_6629, /*  0xe3a7 (U+7f58) */
	C_KANJI_JIS_662A, /*  0xe3a8 (U+7f5f) */
	C_KANJI_JIS_662B, /*  0xe3a9 (U+7f60) */
	C_KANJI_JIS_662C, /*  0xe3aa (U+7f68) */
	C_KANJI_JIS_662D, /*  0xe3ab (U+7f69) */
	C_KANJI_JIS_662E, /*  0xe3ac (U+7f67) */
	C_KANJI_JIS_662F, /*  0xe3ad (U+7f78) */
	C_KANJI_JIS_6630, /*  0xe3ae (U+7f82) */
	C_KANJI_JIS_6631, /*  0xe3af (U+7f86) */
	C_KANJI_JIS_6632, /*  0xe3b0 (U+7f83) */
	C_KANJI_JIS_6633, /*  0xe3b1 (U+7f88) */
	C_KANJI_JIS_6634, /*  0xe3b2 (U+7f87) */
	C_KANJI_JIS_6635, /*  0xe3b3 (U+7f8c) */
	C_KANJI_JIS_6636, /*  0xe3b4 (U+7f94) */
	C_KANJI_JIS_6637, /*  0xe3b5 (U+7f9e) */
	C_KANJI_JIS_6638, /*  0xe3b6 (U+7f9d) */
	C_KANJI_JIS_6639, /*  0xe3b7 (U+7f9a) */
	C_KANJI_JIS_663A, /*  0xe3b8 (U+7fa3) */
	C_KANJI_JIS_663B, /*  0xe3b9 (U+7faf) */
	C_KANJI_JIS_663C, /*  0xe3ba (U+7fb2) */
	C_KANJI_JIS_663D, /*  0xe3bb (U+7fb9) */
	C_KANJI_JIS_663E, /*  0xe3bc (U+7fae) */
	C_KANJI_JIS_663F, /*  0xe3bd (U+7fb6) */
	C_KANJI_JIS_6640, /*  0xe3be (U+7fb8) */
	C_KANJI_JIS_6641, /*  0xe3bf (U+8b71) */
	C_KANJI_JIS_6642, /*  0xe3c0 (U+7fc5) */
	C_KANJI_JIS_6643, /*  0xe3c1 (U+7fc6) */
	C_KANJI_JIS_6644, /*  0xe3c2 (U+7fca) */
	C_KANJI_JIS_6645, /*  0xe3c3 (U+7fd5) */
	C_KANJI_JIS_6646, /*  0xe3c4 (U+7fd4) */
	C_KANJI_JIS_6647, /*  0xe3c5 (U+7fe1) */
	C_KANJI_JIS_6648, /*  0xe3c6 (U+7fe6) */
	C_KANJI_JIS_6649, /*  0xe3c7 (U+7fe9) */
	C_KANJI_JIS_664A, /*  0xe3c8 (U+7ff3) */
	C_KANJI_JIS_664B, /*  0xe3c9 (U+7ff9) */
	C_KANJI_JIS_664C, /*  0xe3ca (U+98dc) */
	C_KANJI_JIS_664D, /*  0xe3cb (U+8006) */
	C_KANJI_JIS_664E, /*  0xe3cc (U+8004) */
	C_KANJI_JIS_664F, /*  0xe3cd (U+800b) */
	C_KANJI_JIS_6650, /*  0xe3ce (U+8012) */
	C_KANJI_JIS_6651, /*  0xe3cf (U+8018) */
	C_KANJI_JIS_6652, /*  0xe3d0 (U+8019) */
	C_KANJI_JIS_6653, /*  0xe3d1 (U+801c) */
	C_KANJI_JIS_6654, /*  0xe3d2 (U+8021) */
	C_KANJI_JIS_6655, /*  0xe3d3 (U+8028) */
	C_KANJI_JIS_6656, /*  0xe3d4 (U+803f) */
	C_KANJI_JIS_6657, /*  0xe3d5 (U+803b) */
	C_KANJI_JIS_6658, /*  0xe3d6 (U+804a) */
	C_KANJI_JIS_6659, /*  0xe3d7 (U+8046) */
	C_KANJI_JIS_665A, /*  0xe3d8 (U+8052) */
	C_KANJI_JIS_665B, /*  0xe3d9 (U+8058) */
	C_KANJI_JIS_665C, /*  0xe3da (U+805a) */
	C_KANJI_JIS_665D, /*  0xe3db (U+805f) */
	C_KANJI_JIS_665E, /*  0xe3dc (U+8062) */
	C_KANJI_JIS_665F, /*  0xe3dd (U+8068) */
	C_KANJI_JIS_6660, /*  0xe3de (U+8073) */
	C_KANJI_JIS_6661, /*  0xe3df (U+8072) */
	C_KANJI_JIS_6662, /*  0xe3e0 (U+8070) */
	C_KANJI_JIS_6663, /*  0xe3e1 (U+8076) */
	C_KANJI_JIS_6664, /*  0xe3e2 (U+8079) */
	C_KANJI_JIS_6665, /*  0xe3e3 (U+807d) */
	C_KANJI_JIS_6666, /*  0xe3e4 (U+807f) */
	C_KANJI_JIS_6667, /*  0xe3e5 (U+8084) */
	C_KANJI_JIS_6668, /*  0xe3e6 (U+8086) */
	C_KANJI_JIS_6669, /*  0xe3e7 (U+8085) */
	C_KANJI_JIS_666A, /*  0xe3e8 (U+809b) */
	C_KANJI_JIS_666B, /*  0xe3e9 (U+8093) */
	C_KANJI_JIS_666C, /*  0xe3ea (U+809a) */
	C_KANJI_JIS_666D, /*  0xe3eb (U+80ad) */
	C_KANJI_JIS_666E, /*  0xe3ec (U+5190) */
	C_KANJI_JIS_666F, /*  0xe3ed (U+80ac) */
	C_KANJI_JIS_6670, /*  0xe3ee (U+80db) */
	C_KANJI_JIS_6671, /*  0xe3ef (U+80e5) */
	C_KANJI_JIS_6672, /*  0xe3f0 (U+80d9) */
	C_KANJI_JIS_6673, /*  0xe3f1 (U+80dd) */
	C_KANJI_JIS_6674, /*  0xe3f2 (U+80c4) */
	C_KANJI_JIS_6675, /*  0xe3f3 (U+80da) */
	C_KANJI_JIS_6676, /*  0xe3f4 (U+80d6) */
	C_KANJI_JIS_6677, /*  0xe3f5 (U+8109) */
	C_KANJI_JIS_6678, /*  0xe3f6 (U+80ef) */
	C_KANJI_JIS_6679, /*  0xe3f7 (U+80f1) */
	C_KANJI_JIS_667A, /*  0xe3f8 (U+811b) */
	C_KANJI_JIS_667B, /*  0xe3f9 (U+8129) */
	C_KANJI_JIS_667C, /*  0xe3fa (U+8123) */
	C_KANJI_JIS_667D, /*  0xe3fb (U+812f) */
	C_KANJI_JIS_667E, /*  0xe3fc (U+814b) */
	0, /*  0xe3fd */
	0, /*  0xe3fe */
	0, /*  0xe3ff */
	C_KANJI_JIS_6721, /*  0xe440 (U+968b) */
	C_KANJI_JIS_6722, /*  0xe441 (U+8146) */
	C_KANJI_JIS_6723, /*  0xe442 (U+813e) */
	C_KANJI_JIS_6724, /*  0xe443 (U+8153) */
	C_KANJI_JIS_6725, /*  0xe444 (U+8151) */
	C_KANJI_JIS_6726, /*  0xe445 (U+80fc) */
	C_KANJI_JIS_6727, /*  0xe446 (U+8171) */
	C_KANJI_JIS_6728, /*  0xe447 (U+816e) */
	C_KANJI_JIS_6729, /*  0xe448 (U+8165) */
	C_KANJI_JIS_672A, /*  0xe449 (U+8166) */
	C_KANJI_JIS_672B, /*  0xe44a (U+8174) */
	C_KANJI_JIS_672C, /*  0xe44b (U+8183) */
	C_KANJI_JIS_672D, /*  0xe44c (U+8188) */
	C_KANJI_JIS_672E, /*  0xe44d (U+818a) */
	C_KANJI_JIS_672F, /*  0xe44e (U+8180) */
	C_KANJI_JIS_6730, /*  0xe44f (U+8182) */
	C_KANJI_JIS_6731, /*  0xe450 (U+81a0) */
	C_KANJI_JIS_6732, /*  0xe451 (U+8195) */
	C_KANJI_JIS_6733, /*  0xe452 (U+81a4) */
	C_KANJI_JIS_6734, /*  0xe453 (U+81a3) */
	C_KANJI_JIS_6735, /*  0xe454 (U+815f) */
	C_KANJI_JIS_6736, /*  0xe455 (U+8193) */
	C_KANJI_JIS_6737, /*  0xe456 (U+81a9) */
	C_KANJI_JIS_6738, /*  0xe457 (U+81b0) */
	C_KANJI_JIS_6739, /*  0xe458 (U+81b5) */
	C_KANJI_JIS_673A, /*  0xe459 (U+81be) */
	C_KANJI_JIS_673B, /*  0xe45a (U+81b8) */
	C_KANJI_JIS_673C, /*  0xe45b (U+81bd) */
	C_KANJI_JIS_673D, /*  0xe45c (U+81c0) */
	C_KANJI_JIS_673E, /*  0xe45d (U+81c2) */
	C_KANJI_JIS_673F, /*  0xe45e (U+81ba) */
	C_KANJI_JIS_6740, /*  0xe45f (U+81c9) */
	C_KANJI_JIS_6741, /*  0xe460 (U+81cd) */
	C_KANJI_JIS_6742, /*  0xe461 (U+81d1) */
	C_KANJI_JIS_6743, /*  0xe462 (U+81d9) */
	C_KANJI_JIS_6744, /*  0xe463 (U+81d8) */
	C_KANJI_JIS_6745, /*  0xe464 (U+81c8) */
	C_KANJI_JIS_6746, /*  0xe465 (U+81da) */
	C_KANJI_JIS_6747, /*  0xe466 (U+81df) */
	C_KANJI_JIS_6748, /*  0xe467 (U+81e0) */
	C_KANJI_JIS_6749, /*  0xe468 (U+81e7) */
	C_KANJI_JIS_674A, /*  0xe469 (U+81fa) */
	C_KANJI_JIS_674B, /*  0xe46a (U+81fb) */
	C_KANJI_JIS_674C, /*  0xe46b (U+81fe) */
	C_KANJI_JIS_674D, /*  0xe46c (U+8201) */
	C_KANJI_JIS_674E, /*  0xe46d (U+8202) */
	C_KANJI_JIS_674F, /*  0xe46e (U+8205) */
	C_KANJI_JIS_6750, /*  0xe46f (U+8207) */
	C_KANJI_JIS_6751, /*  0xe470 (U+820a) */
	C_KANJI_JIS_6752, /*  0xe471 (U+820d) */
	C_KANJI_JIS_6753, /*  0xe472 (U+8210) */
	C_KANJI_JIS_6754, /*  0xe473 (U+8216) */
	C_KANJI_JIS_6755, /*  0xe474 (U+8229) */
	C_KANJI_JIS_6756, /*  0xe475 (U+822b) */
	C_KANJI_JIS_6757, /*  0xe476 (U+8238) */
	C_KANJI_JIS_6758, /*  0xe477 (U+8233) */
	C_KANJI_JIS_6759, /*  0xe478 (U+8240) */
	C_KANJI_JIS_675A, /*  0xe479 (U+8259) */
	C_KANJI_JIS_675B, /*  0xe47a (U+8258) */
	C_KANJI_JIS_675C, /*  0xe47b (U+825d) */
	C_KANJI_JIS_675D, /*  0xe47c (U+825a) */
	C_KANJI_JIS_675E, /*  0xe47d (U+825f) */
	C_KANJI_JIS_675F, /*  0xe47e (U+8264) */
	0, /*  0xe47f */
	C_KANJI_JIS_6760, /*  0xe480 (U+8262) */
	C_KANJI_JIS_6761, /*  0xe481 (U+8268) */
	C_KANJI_JIS_6762, /*  0xe482 (U+826a) */
	C_KANJI_JIS_6763, /*  0xe483 (U+826b) */
	C_KANJI_JIS_6764, /*  0xe484 (U+822e) */
	C_KANJI_JIS_6765, /*  0xe485 (U+8271) */
	C_KANJI_JIS_6766, /*  0xe486 (U+8277) */
	C_KANJI_JIS_6767, /*  0xe487 (U+8278) */
	C_KANJI_JIS_6768, /*  0xe488 (U+827e) */
	C_KANJI_JIS_6769, /*  0xe489 (U+828d) */
	C_KANJI_JIS_676A, /*  0xe48a (U+8292) */
	C_KANJI_JIS_676B, /*  0xe48b (U+82ab) */
	C_KANJI_JIS_676C, /*  0xe48c (U+829f) */
	C_KANJI_JIS_676D, /*  0xe48d (U+82bb) */
	C_KANJI_JIS_676E, /*  0xe48e (U+82ac) */
	C_KANJI_JIS_676F, /*  0xe48f (U+82e1) */
	C_KANJI_JIS_6770, /*  0xe490 (U+82e3) */
	C_KANJI_JIS_6771, /*  0xe491 (U+82df) */
	C_KANJI_JIS_6772, /*  0xe492 (U+82d2) */
	C_KANJI_JIS_6773, /*  0xe493 (U+82f4) */
	C_KANJI_JIS_6774, /*  0xe494 (U+82f3) */
	C_KANJI_JIS_6775, /*  0xe495 (U+82fa) */
	C_KANJI_JIS_6776, /*  0xe496 (U+8393) */
	C_KANJI_JIS_6777, /*  0xe497 (U+8303) */
	C_KANJI_JIS_6778, /*  0xe498 (U+82fb) */
	C_KANJI_JIS_6779, /*  0xe499 (U+82f9) */
	C_KANJI_JIS_677A, /*  0xe49a (U+82de) */
	C_KANJI_JIS_677B, /*  0xe49b (U+8306) */
	C_KANJI_JIS_677C, /*  0xe49c (U+82dc) */
	C_KANJI_JIS_677D, /*  0xe49d (U+8309) */
	C_KANJI_JIS_677E, /*  0xe49e (U+82d9) */
	C_KANJI_JIS_6821, /*  0xe49f (U+8335) */
	C_KANJI_JIS_6822, /*  0xe4a0 (U+8334) */
	C_KANJI_JIS_6823, /*  0xe4a1 (U+8316) */
	C_KANJI_JIS_6824, /*  0xe4a2 (U+8332) */
	C_KANJI_JIS_6825, /*  0xe4a3 (U+8331) */
	C_KANJI_JIS_6826, /*  0xe4a4 (U+8340) */
	C_KANJI_JIS_6827, /*  0xe4a5 (U+8339) */
	C_KANJI_JIS_6828, /*  0xe4a6 (U+8350) */
	C_KANJI_JIS_6829, /*  0xe4a7 (U+8345) */
	C_KANJI_JIS_682A, /*  0xe4a8 (U+832f) */
	C_KANJI_JIS_682B, /*  0xe4a9 (U+832b) */
	C_KANJI_JIS_682C, /*  0xe4aa (U+8317) */
	C_KANJI_JIS_682D, /*  0xe4ab (U+8318) */
	C_KANJI_JIS_682E, /*  0xe4ac (U+8385) */
	C_KANJI_JIS_682F, /*  0xe4ad (U+839a) */
	C_KANJI_JIS_6830, /*  0xe4ae (U+83aa) */
	C_KANJI_JIS_6831, /*  0xe4af (U+839f) */
	C_KANJI_JIS_6832, /*  0xe4b0 (U+83a2) */
	C_KANJI_JIS_6833, /*  0xe4b1 (U+8396) */
	C_KANJI_JIS_6834, /*  0xe4b2 (U+8323) */
	C_KANJI_JIS_6835, /*  0xe4b3 (U+838e) */
	C_KANJI_JIS_6836, /*  0xe4b4 (U+8387) */
	C_KANJI_JIS_6837, /*  0xe4b5 (U+838a) */
	C_KANJI_JIS_6838, /*  0xe4b6 (U+837c) */
	C_KANJI_JIS_6839, /*  0xe4b7 (U+83b5) */
	C_KANJI_JIS_683A, /*  0xe4b8 (U+8373) */
	C_KANJI_JIS_683B, /*  0xe4b9 (U+8375) */
	C_KANJI_JIS_683C, /*  0xe4ba (U+83a0) */
	C_KANJI_JIS_683D, /*  0xe4bb (U+8389) */
	C_KANJI_JIS_683E, /*  0xe4bc (U+83a8) */
	C_KANJI_JIS_683F, /*  0xe4bd (U+83f4) */
	C_KANJI_JIS_6840, /*  0xe4be (U+8413) */
	C_KANJI_JIS_6841, /*  0xe4bf (U+83eb) */
	C_KANJI_JIS_6842, /*  0xe4c0 (U+83ce) */
	C_KANJI_JIS_6843, /*  0xe4c1 (U+83fd) */
	C_KANJI_JIS_6844, /*  0xe4c2 (U+8403) */
	C_KANJI_JIS_6845, /*  0xe4c3 (U+83d8) */
	C_KANJI_JIS_6846, /*  0xe4c4 (U+840b) */
	C_KANJI_JIS_6847, /*  0xe4c5 (U+83c1) */
	C_KANJI_JIS_6848, /*  0xe4c6 (U+83f7) */
	C_KANJI_JIS_6849, /*  0xe4c7 (U+8407) */
	C_KANJI_JIS_684A, /*  0xe4c8 (U+83e0) */
	C_KANJI_JIS_684B, /*  0xe4c9 (U+83f2) */
	C_KANJI_JIS_684C, /*  0xe4ca (U+840d) */
	C_KANJI_JIS_684D, /*  0xe4cb (U+8422) */
	C_KANJI_JIS_684E, /*  0xe4cc (U+8420) */
	C_KANJI_JIS_684F, /*  0xe4cd (U+83bd) */
	C_KANJI_JIS_6850, /*  0xe4ce (U+8438) */
	C_KANJI_JIS_6851, /*  0xe4cf (U+8506) */
	C_KANJI_JIS_6852, /*  0xe4d0 (U+83fb) */
	C_KANJI_JIS_6853, /*  0xe4d1 (U+846d) */
	C_KANJI_JIS_6854, /*  0xe4d2 (U+842a) */
	C_KANJI_JIS_6855, /*  0xe4d3 (U+843c) */
	C_KANJI_JIS_6856, /*  0xe4d4 (U+855a) */
	C_KANJI_JIS_6857, /*  0xe4d5 (U+8484) */
	C_KANJI_JIS_6858, /*  0xe4d6 (U+8477) */
	C_KANJI_JIS_6859, /*  0xe4d7 (U+846b) */
	C_KANJI_JIS_685A, /*  0xe4d8 (U+84ad) */
	C_KANJI_JIS_685B, /*  0xe4d9 (U+846e) */
	C_KANJI_JIS_685C, /*  0xe4da (U+8482) */
	C_KANJI_JIS_685D, /*  0xe4db (U+8469) */
	C_KANJI_JIS_685E, /*  0xe4dc (U+8446) */
	C_KANJI_JIS_685F, /*  0xe4dd (U+842c) */
	C_KANJI_JIS_6860, /*  0xe4de (U+846f) */
	C_KANJI_JIS_6861, /*  0xe4df (U+8479) */
	C_KANJI_JIS_6862, /*  0xe4e0 (U+8435) */
	C_KANJI_JIS_6863, /*  0xe4e1 (U+84ca) */
	C_KANJI_JIS_6864, /*  0xe4e2 (U+8462) */
	C_KANJI_JIS_6865, /*  0xe4e3 (U+84b9) */
	C_KANJI_JIS_6866, /*  0xe4e4 (U+84bf) */
	C_KANJI_JIS_6867, /*  0xe4e5 (U+849f) */
	C_KANJI_JIS_6868, /*  0xe4e6 (U+84d9) */
	C_KANJI_JIS_6869, /*  0xe4e7 (U+84cd) */
	C_KANJI_JIS_686A, /*  0xe4e8 (U+84bb) */
	C_KANJI_JIS_686B, /*  0xe4e9 (U+84da) */
	C_KANJI_JIS_686C, /*  0xe4ea (U+84d0) */
	C_KANJI_JIS_686D, /*  0xe4eb (U+84c1) */
	C_KANJI_JIS_686E, /*  0xe4ec (U+84c6) */
	C_KANJI_JIS_686F, /*  0xe4ed (U+84d6) */
	C_KANJI_JIS_6870, /*  0xe4ee (U+84a1) */
	C_KANJI_JIS_6871, /*  0xe4ef (U+8521) */
	C_KANJI_JIS_6872, /*  0xe4f0 (U+84ff) */
	C_KANJI_JIS_6873, /*  0xe4f1 (U+84f4) */
	C_KANJI_JIS_6874, /*  0xe4f2 (U+8517) */
	C_KANJI_JIS_6875, /*  0xe4f3 (U+8518) */
	C_KANJI_JIS_6876, /*  0xe4f4 (U+852c) */
	C_KANJI_JIS_6877, /*  0xe4f5 (U+851f) */
	C_KANJI_JIS_6878, /*  0xe4f6 (U+8515) */
	C_KANJI_JIS_6879, /*  0xe4f7 (U+8514) */
	C_KANJI_JIS_687A, /*  0xe4f8 (U+84fc) */
	C_KANJI_JIS_687B, /*  0xe4f9 (U+8540) */
	C_KANJI_JIS_687C, /*  0xe4fa (U+8563) */
	C_KANJI_JIS_687D, /*  0xe4fb (U+8558) */
	C_KANJI_JIS_687E, /*  0xe4fc (U+8548) */
	0, /*  0xe4fd */
	0, /*  0xe4fe */
	0, /*  0xe4ff */
	C_KANJI_JIS_6921, /*  0xe540 (U+8541) */
	C_KANJI_JIS_6922, /*  0xe541 (U+8602) */
	C_KANJI_JIS_6923, /*  0xe542 (U+854b) */
	C_KANJI_JIS_6924, /*  0xe543 (U+8555) */
	C_KANJI_JIS_6925, /*  0xe544 (U+8580) */
	C_KANJI_JIS_6926, /*  0xe545 (U+85a4) */
	C_KANJI_JIS_6927, /*  0xe546 (U+8588) */
	C_KANJI_JIS_6928, /*  0xe547 (U+8591) */
	C_KANJI_JIS_6929, /*  0xe548 (U+858a) */
	C_KANJI_JIS_692A, /*  0xe549 (U+85a8) */
	C_KANJI_JIS_692B, /*  0xe54a (U+856d) */
	C_KANJI_JIS_692C, /*  0xe54b (U+8594) */
	C_KANJI_JIS_692D, /*  0xe54c (U+859b) */
	C_KANJI_JIS_692E, /*  0xe54d (U+85ea) */
	C_KANJI_JIS_692F, /*  0xe54e (U+8587) */
	C_KANJI_JIS_6930, /*  0xe54f (U+859c) */
	C_KANJI_JIS_6931, /*  0xe550 (U+8577) */
	C_KANJI_JIS_6932, /*  0xe551 (U+857e) */
	C_KANJI_JIS_6933, /*  0xe552 (U+8590) */
	C_KANJI_JIS_6934, /*  0xe553 (U+85c9) */
	C_KANJI_JIS_6935, /*  0xe554 (U+85ba) */
	C_KANJI_JIS_6936, /*  0xe555 (U+85cf) */
	C_KANJI_JIS_6937, /*  0xe556 (U+85b9) */
	C_KANJI_JIS_6938, /*  0xe557 (U+85d0) */
	C_KANJI_JIS_6939, /*  0xe558 (U+85d5) */
	C_KANJI_JIS_693A, /*  0xe559 (U+85dd) */
	C_KANJI_JIS_693B, /*  0xe55a (U+85e5) */
	C_KANJI_JIS_693C, /*  0xe55b (U+85dc) */
	C_KANJI_JIS_693D, /*  0xe55c (U+85f9) */
	C_KANJI_JIS_693E, /*  0xe55d (U+860a) */
	C_KANJI_JIS_693F, /*  0xe55e (U+8613) */
	C_KANJI_JIS_6940, /*  0xe55f (U+860b) */
	C_KANJI_JIS_6941, /*  0xe560 (U+85fe) */
	C_KANJI_JIS_6942, /*  0xe561 (U+85fa) */
	C_KANJI_JIS_6943, /*  0xe562 (U+8606) */
	C_KANJI_JIS_6944, /*  0xe563 (U+8622) */
	C_KANJI_JIS_6945, /*  0xe564 (U+861a) */
	C_KANJI_JIS_6946, /*  0xe565 (U+8630) */
	C_KANJI_JIS_6947, /*  0xe566 (U+863f) */
	C_KANJI_JIS_6948, /*  0xe567 (U+864d) */
	C_KANJI_JIS_6949, /*  0xe568 (U+4e55) */
	C_KANJI_JIS_694A, /*  0xe569 (U+8654) */
	C_KANJI_JIS_694B, /*  0xe56a (U+865f) */
	C_KANJI_JIS_694C, /*  0xe56b (U+8667) */
	C_KANJI_JIS_694D, /*  0xe56c (U+8671) */
	C_KANJI_JIS_694E, /*  0xe56d (U+8693) */
	C_KANJI_JIS_694F, /*  0xe56e (U+86a3) */
	C_KANJI_JIS_6950, /*  0xe56f (U+86a9) */
	C_KANJI_JIS_6951, /*  0xe570 (U+86aa) */
	C_KANJI_JIS_6952, /*  0xe571 (U+868b) */
	C_KANJI_JIS_6953, /*  0xe572 (U+868c) */
	C_KANJI_JIS_6954, /*  0xe573 (U+86b6) */
	C_KANJI_JIS_6955, /*  0xe574 (U+86af) */
	C_KANJI_JIS_6956, /*  0xe575 (U+86c4) */
	C_KANJI_JIS_6957, /*  0xe576 (U+86c6) */
	C_KANJI_JIS_6958, /*  0xe577 (U+86b0) */
	C_KANJI_JIS_6959, /*  0xe578 (U+86c9) */
	C_KANJI_JIS_695A, /*  0xe579 (U+8823) */
	C_KANJI_JIS_695B, /*  0xe57a (U+86ab) */
	C_KANJI_JIS_695C, /*  0xe57b (U+86d4) */
	C_KANJI_JIS_695D, /*  0xe57c (U+86de) */
	C_KANJI_JIS_695E, /*  0xe57d (U+86e9) */
	C_KANJI_JIS_695F, /*  0xe57e (U+86ec) */
	0, /*  0xe57f */
	C_KANJI_JIS_6960, /*  0xe580 (U+86df) */
	C_KANJI_JIS_6961, /*  0xe581 (U+86db) */
	C_KANJI_JIS_6962, /*  0xe582 (U+86ef) */
	C_KANJI_JIS_6963, /*  0xe583 (U+8712) */
	C_KANJI_JIS_6964, /*  0xe584 (U+8706) */
	C_KANJI_JIS_6965, /*  0xe585 (U+8708) */
	C_KANJI_JIS_6966, /*  0xe586 (U+8700) */
	C_KANJI_JIS_6967, /*  0xe587 (U+8703) */
	C_KANJI_JIS_6968, /*  0xe588 (U+86fb) */
	C_KANJI_JIS_6969, /*  0xe589 (U+8711) */
	C_KANJI_JIS_696A, /*  0xe58a (U+8709) */
	C_KANJI_JIS_696B, /*  0xe58b (U+870d) */
	C_KANJI_JIS_696C, /*  0xe58c (U+86f9) */
	C_KANJI_JIS_696D, /*  0xe58d (U+870a) */
	C_KANJI_JIS_696E, /*  0xe58e (U+8734) */
	C_KANJI_JIS_696F, /*  0xe58f (U+873f) */
	C_KANJI_JIS_6970, /*  0xe590 (U+8737) */
	C_KANJI_JIS_6971, /*  0xe591 (U+873b) */
	C_KANJI_JIS_6972, /*  0xe592 (U+8725) */
	C_KANJI_JIS_6973, /*  0xe593 (U+8729) */
	C_KANJI_JIS_6974, /*  0xe594 (U+871a) */
	C_KANJI_JIS_6975, /*  0xe595 (U+8760) */
	C_KANJI_JIS_6976, /*  0xe596 (U+875f) */
	C_KANJI_JIS_6977, /*  0xe597 (U+8778) */
	C_KANJI_JIS_6978, /*  0xe598 (U+874c) */
	C_KANJI_JIS_6979, /*  0xe599 (U+874e) */
	C_KANJI_JIS_697A, /*  0xe59a (U+8774) */
	C_KANJI_JIS_697B, /*  0xe59b (U+8757) */
	C_KANJI_JIS_697C, /*  0xe59c (U+8768) */
	C_KANJI_JIS_697D, /*  0xe59d (U+876e) */
	C_KANJI_JIS_697E, /*  0xe59e (U+8759) */
	C_KANJI_JIS_6A21, /*  0xe59f (U+8753) */
	C_KANJI_JIS_6A22, /*  0xe5a0 (U+8763) */
	C_KANJI_JIS_6A23, /*  0xe5a1 (U+876a) */
	C_KANJI_JIS_6A24, /*  0xe5a2 (U+8805) */
	C_KANJI_JIS_6A25, /*  0xe5a3 (U+87a2) */
	C_KANJI_JIS_6A26, /*  0xe5a4 (U+879f) */
	C_KANJI_JIS_6A27, /*  0xe5a5 (U+8782) */
	C_KANJI_JIS_6A28, /*  0xe5a6 (U+87af) */
	C_KANJI_JIS_6A29, /*  0xe5a7 (U+87cb) */
	C_KANJI_JIS_6A2A, /*  0xe5a8 (U+87bd) */
	C_KANJI_JIS_6A2B, /*  0xe5a9 (U+87c0) */
	C_KANJI_JIS_6A2C, /*  0xe5aa (U+87d0) */
	C_KANJI_JIS_6A2D, /*  0xe5ab (U+96d6) */
	C_KANJI_JIS_6A2E, /*  0xe5ac (U+87ab) */
	C_KANJI_JIS_6A2F, /*  0xe5ad (U+87c4) */
	C_KANJI_JIS_6A30, /*  0xe5ae (U+87b3) */
	C_KANJI_JIS_6A31, /*  0xe5af (U+87c7) */
	C_KANJI_JIS_6A32, /*  0xe5b0 (U+87c6) */
	C_KANJI_JIS_6A33, /*  0xe5b1 (U+87bb) */
	C_KANJI_JIS_6A34, /*  0xe5b2 (U+87ef) */
	C_KANJI_JIS_6A35, /*  0xe5b3 (U+87f2) */
	C_KANJI_JIS_6A36, /*  0xe5b4 (U+87e0) */
	C_KANJI_JIS_6A37, /*  0xe5b5 (U+880f) */
	C_KANJI_JIS_6A38, /*  0xe5b6 (U+880d) */
	C_KANJI_JIS_6A39, /*  0xe5b7 (U+87fe) */
	C_KANJI_JIS_6A3A, /*  0xe5b8 (U+87f6) */
	C_KANJI_JIS_6A3B, /*  0xe5b9 (U+87f7) */
	C_KANJI_JIS_6A3C, /*  0xe5ba (U+880e) */
	C_KANJI_JIS_6A3D, /*  0xe5bb (U+87d2) */
	C_KANJI_JIS_6A3E, /*  0xe5bc (U+8811) */
	C_KANJI_JIS_6A3F, /*  0xe5bd (U+8816) */
	C_KANJI_JIS_6A40, /*  0xe5be (U+8815) */
	C_KANJI_JIS_6A41, /*  0xe5bf (U+8822) */
	C_KANJI_JIS_6A42, /*  0xe5c0 (U+8821) */
	C_KANJI_JIS_6A43, /*  0xe5c1 (U+8831) */
	C_KANJI_JIS_6A44, /*  0xe5c2 (U+8836) */
	C_KANJI_JIS_6A45, /*  0xe5c3 (U+8839) */
	C_KANJI_JIS_6A46, /*  0xe5c4 (U+8827) */
	C_KANJI_JIS_6A47, /*  0xe5c5 (U+883b) */
	C_KANJI_JIS_6A48, /*  0xe5c6 (U+8844) */
	C_KANJI_JIS_6A49, /*  0xe5c7 (U+8842) */
	C_KANJI_JIS_6A4A, /*  0xe5c8 (U+8852) */
	C_KANJI_JIS_6A4B, /*  0xe5c9 (U+8859) */
	C_KANJI_JIS_6A4C, /*  0xe5ca (U+885e) */
	C_KANJI_JIS_6A4D, /*  0xe5cb (U+8862) */
	C_KANJI_JIS_6A4E, /*  0xe5cc (U+886b) */
	C_KANJI_JIS_6A4F, /*  0xe5cd (U+8881) */
	C_KANJI_JIS_6A50, /*  0xe5ce (U+887e) */
	C_KANJI_JIS_6A51, /*  0xe5cf (U+889e) */
	C_KANJI_JIS_6A52, /*  0xe5d0 (U+8875) */
	C_KANJI_JIS_6A53, /*  0xe5d1 (U+887d) */
	C_KANJI_JIS_6A54, /*  0xe5d2 (U+88b5) */
	C_KANJI_JIS_6A55, /*  0xe5d3 (U+8872) */
	C_KANJI_JIS_6A56, /*  0xe5d4 (U+8882) */
	C_KANJI_JIS_6A57, /*  0xe5d5 (U+8897) */
	C_KANJI_JIS_6A58, /*  0xe5d6 (U+8892) */
	C_KANJI_JIS_6A59, /*  0xe5d7 (U+88ae) */
	C_KANJI_JIS_6A5A, /*  0xe5d8 (U+8899) */
	C_KANJI_JIS_6A5B, /*  0xe5d9 (U+88a2) */
	C_KANJI_JIS_6A5C, /*  0xe5da (U+888d) */
	C_KANJI_JIS_6A5D, /*  0xe5db (U+88a4) */
	C_KANJI_JIS_6A5E, /*  0xe5dc (U+88b0) */
	C_KANJI_JIS_6A5F, /*  0xe5dd (U+88bf) */
	C_KANJI_JIS_6A60, /*  0xe5de (U+88b1) */
	C_KANJI_JIS_6A61, /*  0xe5df (U+88c3) */
	C_KANJI_JIS_6A62, /*  0xe5e0 (U+88c4) */
	C_KANJI_JIS_6A63, /*  0xe5e1 (U+88d4) */
	C_KANJI_JIS_6A64, /*  0xe5e2 (U+88d8) */
	C_KANJI_JIS_6A65, /*  0xe5e3 (U+88d9) */
	C_KANJI_JIS_6A66, /*  0xe5e4 (U+88dd) */
	C_KANJI_JIS_6A67, /*  0xe5e5 (U+88f9) */
	C_KANJI_JIS_6A68, /*  0xe5e6 (U+8902) */
	C_KANJI_JIS_6A69, /*  0xe5e7 (U+88fc) */
	C_KANJI_JIS_6A6A, /*  0xe5e8 (U+88f4) */
	C_KANJI_JIS_6A6B, /*  0xe5e9 (U+88e8) */
	C_KANJI_JIS_6A6C, /*  0xe5ea (U+88f2) */
	C_KANJI_JIS_6A6D, /*  0xe5eb (U+8904) */
	C_KANJI_JIS_6A6E, /*  0xe5ec (U+890c) */
	C_KANJI_JIS_6A6F, /*  0xe5ed (U+890a) */
	C_KANJI_JIS_6A70, /*  0xe5ee (U+8913) */
	C_KANJI_JIS_6A71, /*  0xe5ef (U+8943) */
	C_KANJI_JIS_6A72, /*  0xe5f0 (U+891e) */
	C_KANJI_JIS_6A73, /*  0xe5f1 (U+8925) */
	C_KANJI_JIS_6A74, /*  0xe5f2 (U+892a) */
	C_KANJI_JIS_6A75, /*  0xe5f3 (U+892b) */
	C_KANJI_JIS_6A76, /*  0xe5f4 (U+8941) */
	C_KANJI_JIS_6A77, /*  0xe5f5 (U+8944) */
	C_KANJI_JIS_6A78, /*  0xe5f6 (U+893b) */
	C_KANJI_JIS_6A79, /*  0xe5f7 (U+8936) */
	C_KANJI_JIS_6A7A, /*  0xe5f8 (U+8938) */
	C_KANJI_JIS_6A7B, /*  0xe5f9 (U+894c) */
	C_KANJI_JIS_6A7C, /*  0xe5fa (U+891d) */
	C_KANJI_JIS_6A7D, /*  0xe5fb (U+8960) */
	C_KANJI_JIS_6A7E, /*  0xe5fc (U+895e) */
	0, /*  0xe5fd */
	0, /*  0xe5fe */
	0, /*  0xe5ff */
	C_KANJI_JIS_6B21, /*  0xe640 (U+8966) */
	C_KANJI_JIS_6B22, /*  0xe641 (U+8964) */
	C_KANJI_JIS_6B23, /*  0xe642 (U+896d) */
	C_KANJI_JIS_6B24, /*  0xe643 (U+896a) */
	C_KANJI_JIS_6B25, /*  0xe644 (U+896f) */
	C_KANJI_JIS_6B26, /*  0xe645 (U+8974) */
	C_KANJI_JIS_6B27, /*  0xe646 (U+8977) */
	C_KANJI_JIS_6B28, /*  0xe647 (U+897e) */
	C_KANJI_JIS_6B29, /*  0xe648 (U+8983) */
	C_KANJI_JIS_6B2A, /*  0xe649 (U+8988) */
	C_KANJI_JIS_6B2B, /*  0xe64a (U+898a) */
	C_KANJI_JIS_6B2C, /*  0xe64b (U+8993) */
	C_KANJI_JIS_6B2D, /*  0xe64c (U+8998) */
	C_KANJI_JIS_6B2E, /*  0xe64d (U+89a1) */
	C_KANJI_JIS_6B2F, /*  0xe64e (U+89a9) */
	C_KANJI_JIS_6B30, /*  0xe64f (U+89a6) */
	C_KANJI_JIS_6B31, /*  0xe650 (U+89ac) */
	C_KANJI_JIS_6B32, /*  0xe651 (U+89af) */
	C_KANJI_JIS_6B33, /*  0xe652 (U+89b2) */
	C_KANJI_JIS_6B34, /*  0xe653 (U+89ba) */
	C_KANJI_JIS_6B35, /*  0xe654 (U+89bd) */
	C_KANJI_JIS_6B36, /*  0xe655 (U+89bf) */
	C_KANJI_JIS_6B37, /*  0xe656 (U+89c0) */
	C_KANJI_JIS_6B38, /*  0xe657 (U+89da) */
	C_KANJI_JIS_6B39, /*  0xe658 (U+89dc) */
	C_KANJI_JIS_6B3A, /*  0xe659 (U+89dd) */
	C_KANJI_JIS_6B3B, /*  0xe65a (U+89e7) */
	C_KANJI_JIS_6B3C, /*  0xe65b (U+89f4) */
	C_KANJI_JIS_6B3D, /*  0xe65c (U+89f8) */
	C_KANJI_JIS_6B3E, /*  0xe65d (U+8a03) */
	C_KANJI_JIS_6B3F, /*  0xe65e (U+8a16) */
	C_KANJI_JIS_6B40, /*  0xe65f (U+8a10) */
	C_KANJI_JIS_6B41, /*  0xe660 (U+8a0c) */
	C_KANJI_JIS_6B42, /*  0xe661 (U+8a1b) */
	C_KANJI_JIS_6B43, /*  0xe662 (U+8a1d) */
	C_KANJI_JIS_6B44, /*  0xe663 (U+8a25) */
	C_KANJI_JIS_6B45, /*  0xe664 (U+8a36) */
	C_KANJI_JIS_6B46, /*  0xe665 (U+8a41) */
	C_KANJI_JIS_6B47, /*  0xe666 (U+8a5b) */
	C_KANJI_JIS_6B48, /*  0xe667 (U+8a52) */
	C_KANJI_JIS_6B49, /*  0xe668 (U+8a46) */
	C_KANJI_JIS_6B4A, /*  0xe669 (U+8a48) */
	C_KANJI_JIS_6B4B, /*  0xe66a (U+8a7c) */
	C_KANJI_JIS_6B4C, /*  0xe66b (U+8a6d) */
	C_KANJI_JIS_6B4D, /*  0xe66c (U+8a6c) */
	C_KANJI_JIS_6B4E, /*  0xe66d (U+8a62) */
	C_KANJI_JIS_6B4F, /*  0xe66e (U+8a85) */
	C_KANJI_JIS_6B50, /*  0xe66f (U+8a82) */
	C_KANJI_JIS_6B51, /*  0xe670 (U+8a84) */
	C_KANJI_JIS_6B52, /*  0xe671 (U+8aa8) */
	C_KANJI_JIS_6B53, /*  0xe672 (U+8aa1) */
	C_KANJI_JIS_6B54, /*  0xe673 (U+8a91) */
	C_KANJI_JIS_6B55, /*  0xe674 (U+8aa5) */
	C_KANJI_JIS_6B56, /*  0xe675 (U+8aa6) */
	C_KANJI_JIS_6B57, /*  0xe676 (U+8a9a) */
	C_KANJI_JIS_6B58, /*  0xe677 (U+8aa3) */
	C_KANJI_JIS_6B59, /*  0xe678 (U+8ac4) */
	C_KANJI_JIS_6B5A, /*  0xe679 (U+8acd) */
	C_KANJI_JIS_6B5B, /*  0xe67a (U+8ac2) */
	C_KANJI_JIS_6B5C, /*  0xe67b (U+8ada) */
	C_KANJI_JIS_6B5D, /*  0xe67c (U+8aeb) */
	C_KANJI_JIS_6B5E, /*  0xe67d (U+8af3) */
	C_KANJI_JIS_6B5F, /*  0xe67e (U+8ae7) */
	0, /*  0xe67f */
	C_KANJI_JIS_6B60, /*  0xe680 (U+8ae4) */
	C_KANJI_JIS_6B61, /*  0xe681 (U+8af1) */
	C_KANJI_JIS_6B62, /*  0xe682 (U+8b14) */
	C_KANJI_JIS_6B63, /*  0xe683 (U+8ae0) */
	C_KANJI_JIS_6B64, /*  0xe684 (U+8ae2) */
	C_KANJI_JIS_6B65, /*  0xe685 (U+8af7) */
	C_KANJI_JIS_6B66, /*  0xe686 (U+8ade) */
	C_KANJI_JIS_6B67, /*  0xe687 (U+8adb) */
	C_KANJI_JIS_6B68, /*  0xe688 (U+8b0c) */
	C_KANJI_JIS_6B69, /*  0xe689 (U+8b07) */
	C_KANJI_JIS_6B6A, /*  0xe68a (U+8b1a) */
	C_KANJI_JIS_6B6B, /*  0xe68b (U+8ae1) */
	C_KANJI_JIS_6B6C, /*  0xe68c (U+8b16) */
	C_KANJI_JIS_6B6D, /*  0xe68d (U+8b10) */
	C_KANJI_JIS_6B6E, /*  0xe68e (U+8b17) */
	C_KANJI_JIS_6B6F, /*  0xe68f (U+8b20) */
	C_KANJI_JIS_6B70, /*  0xe690 (U+8b33) */
	C_KANJI_JIS_6B71, /*  0xe691 (U+97ab) */
	C_KANJI_JIS_6B72, /*  0xe692 (U+8b26) */
	C_KANJI_JIS_6B73, /*  0xe693 (U+8b2b) */
	C_KANJI_JIS_6B74, /*  0xe694 (U+8b3e) */
	C_KANJI_JIS_6B75, /*  0xe695 (U+8b28) */
	C_KANJI_JIS_6B76, /*  0xe696 (U+8b41) */
	C_KANJI_JIS_6B77, /*  0xe697 (U+8b4c) */
	C_KANJI_JIS_6B78, /*  0xe698 (U+8b4f) */
	C_KANJI_JIS_6B79, /*  0xe699 (U+8b4e) */
	C_KANJI_JIS_6B7A, /*  0xe69a (U+8b49) */
	C_KANJI_JIS_6B7B, /*  0xe69b (U+8b56) */
	C_KANJI_JIS_6B7C, /*  0xe69c (U+8b5b) */
	C_KANJI_JIS_6B7D, /*  0xe69d (U+8b5a) */
	C_KANJI_JIS_6B7E, /*  0xe69e (U+8b6b) */
	C_KANJI_JIS_6C21, /*  0xe69f (U+8b5f) */
	C_KANJI_JIS_6C22, /*  0xe6a0 (U+8b6c) */
	C_KANJI_JIS_6C23, /*  0xe6a1 (U+8b6f) */
	C_KANJI_JIS_6C24, /*  0xe6a2 (U+8b74) */
	C_KANJI_JIS_6C25, /*  0xe6a3 (U+8b7d) */
	C_KANJI_JIS_6C26, /*  0xe6a4 (U+8b80) */
	C_KANJI_JIS_6C27, /*  0xe6a5 (U+8b8c) */
	C_KANJI_JIS_6C28, /*  0xe6a6 (U+8b8e) */
	C_KANJI_JIS_6C29, /*  0xe6a7 (U+8b92) */
	C_KANJI_JIS_6C2A, /*  0xe6a8 (U+8b93) */
	C_KANJI_JIS_6C2B, /*  0xe6a9 (U+8b96) */
	C_KANJI_JIS_6C2C, /*  0xe6aa (U+8b99) */
	C_KANJI_JIS_6C2D, /*  0xe6ab (U+8b9a) */
	C_KANJI_JIS_6C2E, /*  0xe6ac (U+8c3a) */
	C_KANJI_JIS_6C2F, /*  0xe6ad (U+8c41) */
	C_KANJI_JIS_6C30, /*  0xe6ae (U+8c3f) */
	C_KANJI_JIS_6C31, /*  0xe6af (U+8c48) */
	C_KANJI_JIS_6C32, /*  0xe6b0 (U+8c4c) */
	C_KANJI_JIS_6C33, /*  0xe6b1 (U+8c4e) */
	C_KANJI_JIS_6C34, /*  0xe6b2 (U+8c50) */
	C_KANJI_JIS_6C35, /*  0xe6b3 (U+8c55) */
	C_KANJI_JIS_6C36, /*  0xe6b4 (U+8c62) */
	C_KANJI_JIS_6C37, /*  0xe6b5 (U+8c6c) */
	C_KANJI_JIS_6C38, /*  0xe6b6 (U+8c78) */
	C_KANJI_JIS_6C39, /*  0xe6b7 (U+8c7a) */
	C_KANJI_JIS_6C3A, /*  0xe6b8 (U+8c82) */
	C_KANJI_JIS_6C3B, /*  0xe6b9 (U+8c89) */
	C_KANJI_JIS_6C3C, /*  0xe6ba (U+8c85) */
	C_KANJI_JIS_6C3D, /*  0xe6bb (U+8c8a) */
	C_KANJI_JIS_6C3E, /*  0xe6bc (U+8c8d) */
	C_KANJI_JIS_6C3F, /*  0xe6bd (U+8c8e) */
	C_KANJI_JIS_6C40, /*  0xe6be (U+8c94) */
	C_KANJI_JIS_6C41, /*  0xe6bf (U+8c7c) */
	C_KANJI_JIS_6C42, /*  0xe6c0 (U+8c98) */
	C_KANJI_JIS_6C43, /*  0xe6c1 (U+621d) */
	C_KANJI_JIS_6C44, /*  0xe6c2 (U+8cad) */
	C_KANJI_JIS_6C45, /*  0xe6c3 (U+8caa) */
	C_KANJI_JIS_6C46, /*  0xe6c4 (U+8cbd) */
	C_KANJI_JIS_6C47, /*  0xe6c5 (U+8cb2) */
	C_KANJI_JIS_6C48, /*  0xe6c6 (U+8cb3) */
	C_KANJI_JIS_6C49, /*  0xe6c7 (U+8cae) */
	C_KANJI_JIS_6C4A, /*  0xe6c8 (U+8cb6) */
	C_KANJI_JIS_6C4B, /*  0xe6c9 (U+8cc8) */
	C_KANJI_JIS_6C4C, /*  0xe6ca (U+8cc1) */
	C_KANJI_JIS_6C4D, /*  0xe6cb (U+8ce4) */
	C_KANJI_JIS_6C4E, /*  0xe6cc (U+8ce3) */
	C_KANJI_JIS_6C4F, /*  0xe6cd (U+8cda) */
	C_KANJI_JIS_6C50, /*  0xe6ce (U+8cfd) */
	C_KANJI_JIS_6C51, /*  0xe6cf (U+8cfa) */
	C_KANJI_JIS_6C52, /*  0xe6d0 (U+8cfb) */
	C_KANJI_JIS_6C53, /*  0xe6d1 (U+8d04) */
	C_KANJI_JIS_6C54, /*  0xe6d2 (U+8d05) */
	C_KANJI_JIS_6C55, /*  0xe6d3 (U+8d0a) */
	C_KANJI_JIS_6C56, /*  0xe6d4 (U+8d07) */
	C_KANJI_JIS_6C57, /*  0xe6d5 (U+8d0f) */
	C_KANJI_JIS_6C58, /*  0xe6d6 (U+8d0d) */
	C_KANJI_JIS_6C59, /*  0xe6d7 (U+8d10) */
	C_KANJI_JIS_6C5A, /*  0xe6d8 (U+9f4e) */
	C_KANJI_JIS_6C5B, /*  0xe6d9 (U+8d13) */
	C_KANJI_JIS_6C5C, /*  0xe6da (U+8ccd) */
	C_KANJI_JIS_6C5D, /*  0xe6db (U+8d14) */
	C_KANJI_JIS_6C5E, /*  0xe6dc (U+8d16) */
	C_KANJI_JIS_6C5F, /*  0xe6dd (U+8d67) */
	C_KANJI_JIS_6C60, /*  0xe6de (U+8d6d) */
	C_KANJI_JIS_6C61, /*  0xe6df (U+8d71) */
	C_KANJI_JIS_6C62, /*  0xe6e0 (U+8d73) */
	C_KANJI_JIS_6C63, /*  0xe6e1 (U+8d81) */
	C_KANJI_JIS_6C64, /*  0xe6e2 (U+8d99) */
	C_KANJI_JIS_6C65, /*  0xe6e3 (U+8dc2) */
	C_KANJI_JIS_6C66, /*  0xe6e4 (U+8dbe) */
	C_KANJI_JIS_6C67, /*  0xe6e5 (U+8dba) */
	C_KANJI_JIS_6C68, /*  0xe6e6 (U+8dcf) */
	C_KANJI_JIS_6C69, /*  0xe6e7 (U+8dda) */
	C_KANJI_JIS_6C6A, /*  0xe6e8 (U+8dd6) */
	C_KANJI_JIS_6C6B, /*  0xe6e9 (U+8dcc) */
	C_KANJI_JIS_6C6C, /*  0xe6ea (U+8ddb) */
	C_KANJI_JIS_6C6D, /*  0xe6eb (U+8dcb) */
	C_KANJI_JIS_6C6E, /*  0xe6ec (U+8dea) */
	C_KANJI_JIS_6C6F, /*  0xe6ed (U+8deb) */
	C_KANJI_JIS_6C70, /*  0xe6ee (U+8ddf) */
	C_KANJI_JIS_6C71, /*  0xe6ef (U+8de3) */
	C_KANJI_JIS_6C72, /*  0xe6f0 (U+8dfc) */
	C_KANJI_JIS_6C73, /*  0xe6f1 (U+8e08) */
	C_KANJI_JIS_6C74, /*  0xe6f2 (U+8e09) */
	C_KANJI_JIS_6C75, /*  0xe6f3 (U+8dff) */
	C_KANJI_JIS_6C76, /*  0xe6f4 (U+8e1d) */
	C_KANJI_JIS_6C77, /*  0xe6f5 (U+8e1e) */
	C_KANJI_JIS_6C78, /*  0xe6f6 (U+8e10) */
	C_KANJI_JIS_6C79, /*  0xe6f7 (U+8e1f) */
	C_KANJI_JIS_6C7A, /*  0xe6f8 (U+8e42) */
	C_KANJI_JIS_6C7B, /*  0xe6f9 (U+8e35) */
	C_KANJI_JIS_6C7C, /*  0xe6fa (U+8e30) */
	C_KANJI_JIS_6C7D, /*  0xe6fb (U+8e34) */
	C_KANJI_JIS_6C7E, /*  0xe6fc (U+8e4a) */
	0, /*  0xe6fd */
	0, /*  0xe6fe */
	0, /*  0xe6ff */
	C_KANJI_JIS_6D21, /*  0xe740 (U+8e47) */
	C_KANJI_JIS_6D22, /*  0xe741 (U+8e49) */
	C_KANJI_JIS_6D23, /*  0xe742 (U+8e4c) */
	C_KANJI_JIS_6D24, /*  0xe743 (U+8e50) */
	C_KANJI_JIS_6D25, /*  0xe744 (U+8e48) */
	C_KANJI_JIS_6D26, /*  0xe745 (U+8e59) */
	C_KANJI_JIS_6D27, /*  0xe746 (U+8e64) */
	C_KANJI_JIS_6D28, /*  0xe747 (U+8e60) */
	C_KANJI_JIS_6D29, /*  0xe748 (U+8e2a) */
	C_KANJI_JIS_6D2A, /*  0xe749 (U+8e63) */
	C_KANJI_JIS_6D2B, /*  0xe74a (U+8e55) */
	C_KANJI_JIS_6D2C, /*  0xe74b (U+8e76) */
	C_KANJI_JIS_6D2D, /*  0xe74c (U+8e72) */
	C_KANJI_JIS_6D2E, /*  0xe74d (U+8e7c) */
	C_KANJI_JIS_6D2F, /*  0xe74e (U+8e81) */
	C_KANJI_JIS_6D30, /*  0xe74f (U+8e87) */
	C_KANJI_JIS_6D31, /*  0xe750 (U+8e85) */
	C_KANJI_JIS_6D32, /*  0xe751 (U+8e84) */
	C_KANJI_JIS_6D33, /*  0xe752 (U+8e8b) */
	C_KANJI_JIS_6D34, /*  0xe753 (U+8e8a) */
	C_KANJI_JIS_6D35, /*  0xe754 (U+8e93) */
	C_KANJI_JIS_6D36, /*  0xe755 (U+8e91) */
	C_KANJI_JIS_6D37, /*  0xe756 (U+8e94) */
	C_KANJI_JIS_6D38, /*  0xe757 (U+8e99) */
	C_KANJI_JIS_6D39, /*  0xe758 (U+8eaa) */
	C_KANJI_JIS_6D3A, /*  0xe759 (U+8ea1) */
	C_KANJI_JIS_6D3B, /*  0xe75a (U+8eac) */
	C_KANJI_JIS_6D3C, /*  0xe75b (U+8eb0) */
	C_KANJI_JIS_6D3D, /*  0xe75c (U+8ec6) */
	C_KANJI_JIS_6D3E, /*  0xe75d (U+8eb1) */
	C_KANJI_JIS_6D3F, /*  0xe75e (U+8ebe) */
	C_KANJI_JIS_6D40, /*  0xe75f (U+8ec5) */
	C_KANJI_JIS_6D41, /*  0xe760 (U+8ec8) */
	C_KANJI_JIS_6D42, /*  0xe761 (U+8ecb) */
	C_KANJI_JIS_6D43, /*  0xe762 (U+8edb) */
	C_KANJI_JIS_6D44, /*  0xe763 (U+8ee3) */
	C_KANJI_JIS_6D45, /*  0xe764 (U+8efc) */
	C_KANJI_JIS_6D46, /*  0xe765 (U+8efb) */
	C_KANJI_JIS_6D47, /*  0xe766 (U+8eeb) */
	C_KANJI_JIS_6D48, /*  0xe767 (U+8efe) */
	C_KANJI_JIS_6D49, /*  0xe768 (U+8f0a) */
	C_KANJI_JIS_6D4A, /*  0xe769 (U+8f05) */
	C_KANJI_JIS_6D4B, /*  0xe76a (U+8f15) */
	C_KANJI_JIS_6D4C, /*  0xe76b (U+8f12) */
	C_KANJI_JIS_6D4D, /*  0xe76c (U+8f19) */
	C_KANJI_JIS_6D4E, /*  0xe76d (U+8f13) */
	C_KANJI_JIS_6D4F, /*  0xe76e (U+8f1c) */
	C_KANJI_JIS_6D50, /*  0xe76f (U+8f1f) */
	C_KANJI_JIS_6D51, /*  0xe770 (U+8f1b) */
	C_KANJI_JIS_6D52, /*  0xe771 (U+8f0c) */
	C_KANJI_JIS_6D53, /*  0xe772 (U+8f26) */
	C_KANJI_JIS_6D54, /*  0xe773 (U+8f33) */
	C_KANJI_JIS_6D55, /*  0xe774 (U+8f3b) */
	C_KANJI_JIS_6D56, /*  0xe775 (U+8f39) */
	C_KANJI_JIS_6D57, /*  0xe776 (U+8f45) */
	C_KANJI_JIS_6D58, /*  0xe777 (U+8f42) */
	C_KANJI_JIS_6D59, /*  0xe778 (U+8f3e) */
	C_KANJI_JIS_6D5A, /*  0xe779 (U+8f4c) */
	C_KANJI_JIS_6D5B, /*  0xe77a (U+8f49) */
	C_KANJI_JIS_6D5C, /*  0xe77b (U+8f46) */
	C_KANJI_JIS_6D5D, /*  0xe77c (U+8f4e) */
	C_KANJI_JIS_6D5E, /*  0xe77d (U+8f57) */
	C_KANJI_JIS_6D5F, /*  0xe77e (U+8f5c) */
	0, /*  0xe77f */
	C_KANJI_JIS_6D60, /*  0xe780 (U+8f62) */
	C_KANJI_JIS_6D61, /*  0xe781 (U+8f63) */
	C_KANJI_JIS_6D62, /*  0xe782 (U+8f64) */
	C_KANJI_JIS_6D63, /*  0xe783 (U+8f9c) */
	C_KANJI_JIS_6D64, /*  0xe784 (U+8f9f) */
	C_KANJI_JIS_6D65, /*  0xe785 (U+8fa3) */
	C_KANJI_JIS_6D66, /*  0xe786 (U+8fad) */
	C_KANJI_JIS_6D67, /*  0xe787 (U+8faf) */
	C_KANJI_JIS_6D68, /*  0xe788 (U+8fb7) */
	C_KANJI_JIS_6D69, /*  0xe789 (U+8fda) */
	C_KANJI_JIS_6D6A, /*  0xe78a (U+8fe5) */
	C_KANJI_JIS_6D6B, /*  0xe78b (U+8fe2) */
	C_KANJI_JIS_6D6C, /*  0xe78c (U+8fea) */
	C_KANJI_JIS_6D6D, /*  0xe78d (U+8fef) */
	C_KANJI_JIS_6D6E, /*  0xe78e (U+9087) */
	C_KANJI_JIS_6D6F, /*  0xe78f (U+8ff4) */
	C_KANJI_JIS_6D70, /*  0xe790 (U+9005) */
	C_KANJI_JIS_6D71, /*  0xe791 (U+8ff9) */
	C_KANJI_JIS_6D72, /*  0xe792 (U+8ffa) */
	C_KANJI_JIS_6D73, /*  0xe793 (U+9011) */
	C_KANJI_JIS_6D74, /*  0xe794 (U+9015) */
	C_KANJI_JIS_6D75, /*  0xe795 (U+9021) */
	C_KANJI_JIS_6D76, /*  0xe796 (U+900d) */
	C_KANJI_JIS_6D77, /*  0xe797 (U+901e) */
	C_KANJI_JIS_6D78, /*  0xe798 (U+9016) */
	C_KANJI_JIS_6D79, /*  0xe799 (U+900b) */
	C_KANJI_JIS_6D7A, /*  0xe79a (U+9027) */
	C_KANJI_JIS_6D7B, /*  0xe79b (U+9036) */
	C_KANJI_JIS_6D7C, /*  0xe79c (U+9035) */
	C_KANJI_JIS_6D7D, /*  0xe79d (U+9039) */
	C_KANJI_JIS_6D7E, /*  0xe79e (U+8ff8) */
	C_KANJI_JIS_6E21, /*  0xe79f (U+904f) */
	C_KANJI_JIS_6E22, /*  0xe7a0 (U+9050) */
	C_KANJI_JIS_6E23, /*  0xe7a1 (U+9051) */
	C_KANJI_JIS_6E24, /*  0xe7a2 (U+9052) */
	C_KANJI_JIS_6E25, /*  0xe7a3 (U+900e) */
	C_KANJI_JIS_6E26, /*  0xe7a4 (U+9049) */
	C_KANJI_JIS_6E27, /*  0xe7a5 (U+903e) */
	C_KANJI_JIS_6E28, /*  0xe7a6 (U+9056) */
	C_KANJI_JIS_6E29, /*  0xe7a7 (U+9058) */
	C_KANJI_JIS_6E2A, /*  0xe7a8 (U+905e) */
	C_KANJI_JIS_6E2B, /*  0xe7a9 (U+9068) */
	C_KANJI_JIS_6E2C, /*  0xe7aa (U+906f) */
	C_KANJI_JIS_6E2D, /*  0xe7ab (U+9076) */
	C_KANJI_JIS_6E2E, /*  0xe7ac (U+96a8) */
	C_KANJI_JIS_6E2F, /*  0xe7ad (U+9072) */
	C_KANJI_JIS_6E30, /*  0xe7ae (U+9082) */
	C_KANJI_JIS_6E31, /*  0xe7af (U+907d) */
	C_KANJI_JIS_6E32, /*  0xe7b0 (U+9081) */
	C_KANJI_JIS_6E33, /*  0xe7b1 (U+9080) */
	C_KANJI_JIS_6E34, /*  0xe7b2 (U+908a) */
	C_KANJI_JIS_6E35, /*  0xe7b3 (U+9089) */
	C_KANJI_JIS_6E36, /*  0xe7b4 (U+908f) */
	C_KANJI_JIS_6E37, /*  0xe7b5 (U+90a8) */
	C_KANJI_JIS_6E38, /*  0xe7b6 (U+90af) */
	C_KANJI_JIS_6E39, /*  0xe7b7 (U+90b1) */
	C_KANJI_JIS_6E3A, /*  0xe7b8 (U+90b5) */
	C_KANJI_JIS_6E3B, /*  0xe7b9 (U+90e2) */
	C_KANJI_JIS_6E3C, /*  0xe7ba (U+90e4) */
	C_KANJI_JIS_6E3D, /*  0xe7bb (U+6248) */
	C_KANJI_JIS_6E3E, /*  0xe7bc (U+90db) */
	C_KANJI_JIS_6E3F, /*  0xe7bd (U+9102) */
	C_KANJI_JIS_6E40, /*  0xe7be (U+9112) */
	C_KANJI_JIS_6E41, /*  0xe7bf (U+9119) */
	C_KANJI_JIS_6E42, /*  0xe7c0 (U+9132) */
	C_KANJI_JIS_6E43, /*  0xe7c1 (U+9130) */
	C_KANJI_JIS_6E44, /*  0xe7c2 (U+914a) */
	C_KANJI_JIS_6E45, /*  0xe7c3 (U+9156) */
	C_KANJI_JIS_6E46, /*  0xe7c4 (U+9158) */
	C_KANJI_JIS_6E47, /*  0xe7c5 (U+9163) */
	C_KANJI_JIS_6E48, /*  0xe7c6 (U+9165) */
	C_KANJI_JIS_6E49, /*  0xe7c7 (U+9169) */
	C_KANJI_JIS_6E4A, /*  0xe7c8 (U+9173) */
	C_KANJI_JIS_6E4B, /*  0xe7c9 (U+9172) */
	C_KANJI_JIS_6E4C, /*  0xe7ca (U+918b) */
	C_KANJI_JIS_6E4D, /*  0xe7cb (U+9189) */
	C_KANJI_JIS_6E4E, /*  0xe7cc (U+9182) */
	C_KANJI_JIS_6E4F, /*  0xe7cd (U+91a2) */
	C_KANJI_JIS_6E50, /*  0xe7ce (U+91ab) */
	C_KANJI_JIS_6E51, /*  0xe7cf (U+91af) */
	C_KANJI_JIS_6E52, /*  0xe7d0 (U+91aa) */
	C_KANJI_JIS_6E53, /*  0xe7d1 (U+91b5) */
	C_KANJI_JIS_6E54, /*  0xe7d2 (U+91b4) */
	C_KANJI_JIS_6E55, /*  0xe7d3 (U+91ba) */
	C_KANJI_JIS_6E56, /*  0xe7d4 (U+91c0) */
	C_KANJI_JIS_6E57, /*  0xe7d5 (U+91c1) */
	C_KANJI_JIS_6E58, /*  0xe7d6 (U+91c9) */
	C_KANJI_JIS_6E59, /*  0xe7d7 (U+91cb) */
	C_KANJI_JIS_6E5A, /*  0xe7d8 (U+91d0) */
	C_KANJI_JIS_6E5B, /*  0xe7d9 (U+91d6) */
	C_KANJI_JIS_6E5C, /*  0xe7da (U+91df) */
	C_KANJI_JIS_6E5D, /*  0xe7db (U+91e1) */
	C_KANJI_JIS_6E5E, /*  0xe7dc (U+91db) */
	C_KANJI_JIS_6E5F, /*  0xe7dd (U+91fc) */
	C_KANJI_JIS_6E60, /*  0xe7de (U+91f5) */
	C_KANJI_JIS_6E61, /*  0xe7df (U+91f6) */
	C_KANJI_JIS_6E62, /*  0xe7e0 (U+921e) */
	C_KANJI_JIS_6E63, /*  0xe7e1 (U+91ff) */
	C_KANJI_JIS_6E64, /*  0xe7e2 (U+9214) */
	C_KANJI_JIS_6E65, /*  0xe7e3 (U+922c) */
	C_KANJI_JIS_6E66, /*  0xe7e4 (U+9215) */
	C_KANJI_JIS_6E67, /*  0xe7e5 (U+9211) */
	C_KANJI_JIS_6E68, /*  0xe7e6 (U+925e) */
	C_KANJI_JIS_6E69, /*  0xe7e7 (U+9257) */
	C_KANJI_JIS_6E6A, /*  0xe7e8 (U+9245) */
	C_KANJI_JIS_6E6B, /*  0xe7e9 (U+9249) */
	C_KANJI_JIS_6E6C, /*  0xe7ea (U+9264) */
	C_KANJI_JIS_6E6D, /*  0xe7eb (U+9248) */
	C_KANJI_JIS_6E6E, /*  0xe7ec (U+9295) */
	C_KANJI_JIS_6E6F, /*  0xe7ed (U+923f) */
	C_KANJI_JIS_6E70, /*  0xe7ee (U+924b) */
	C_KANJI_JIS_6E71, /*  0xe7ef (U+9250) */
	C_KANJI_JIS_6E72, /*  0xe7f0 (U+929c) */
	C_KANJI_JIS_6E73, /*  0xe7f1 (U+9296) */
	C_KANJI_JIS_6E74, /*  0xe7f2 (U+9293) */
	C_KANJI_JIS_6E75, /*  0xe7f3 (U+929b) */
	C_KANJI_JIS_6E76, /*  0xe7f4 (U+925a) */
	C_KANJI_JIS_6E77, /*  0xe7f5 (U+92cf) */
	C_KANJI_JIS_6E78, /*  0xe7f6 (U+92b9) */
	C_KANJI_JIS_6E79, /*  0xe7f7 (U+92b7) */
	C_KANJI_JIS_6E7A, /*  0xe7f8 (U+92e9) */
	C_KANJI_JIS_6E7B, /*  0xe7f9 (U+930f) */
	C_KANJI_JIS_6E7C, /*  0xe7fa (U+92fa) */
	C_KANJI_JIS_6E7D, /*  0xe7fb (U+9344) */
	C_KANJI_JIS_6E7E, /*  0xe7fc (U+932e) */
	0, /*  0xe7fd */
	0, /*  0xe7fe */
	0, /*  0xe7ff */
	C_KANJI_JIS_6F21, /*  0xe840 (U+9319) */
	C_KANJI_JIS_6F22, /*  0xe841 (U+9322) */
	C_KANJI_JIS_6F23, /*  0xe842 (U+931a) */
	C_KANJI_JIS_6F24, /*  0xe843 (U+9323) */
	C_KANJI_JIS_6F25, /*  0xe844 (U+933a) */
	C_KANJI_JIS_6F26, /*  0xe845 (U+9335) */
	C_KANJI_JIS_6F27, /*  0xe846 (U+933b) */
	C_KANJI_JIS_6F28, /*  0xe847 (U+935c) */
	C_KANJI_JIS_6F29, /*  0xe848 (U+9360) */
	C_KANJI_JIS_6F2A, /*  0xe849 (U+937c) */
	C_KANJI_JIS_6F2B, /*  0xe84a (U+936e) */
	C_KANJI_JIS_6F2C, /*  0xe84b (U+9356) */
	C_KANJI_JIS_6F2D, /*  0xe84c (U+93b0) */
	C_KANJI_JIS_6F2E, /*  0xe84d (U+93ac) */
	C_KANJI_JIS_6F2F, /*  0xe84e (U+93ad) */
	C_KANJI_JIS_6F30, /*  0xe84f (U+9394) */
	C_KANJI_JIS_6F31, /*  0xe850 (U+93b9) */
	C_KANJI_JIS_6F32, /*  0xe851 (U+93d6) */
	C_KANJI_JIS_6F33, /*  0xe852 (U+93d7) */
	C_KANJI_JIS_6F34, /*  0xe853 (U+93e8) */
	C_KANJI_JIS_6F35, /*  0xe854 (U+93e5) */
	C_KANJI_JIS_6F36, /*  0xe855 (U+93d8) */
	C_KANJI_JIS_6F37, /*  0xe856 (U+93c3) */
	C_KANJI_JIS_6F38, /*  0xe857 (U+93dd) */
	C_KANJI_JIS_6F39, /*  0xe858 (U+93d0) */
	C_KANJI_JIS_6F3A, /*  0xe859 (U+93c8) */
	C_KANJI_JIS_6F3B, /*  0xe85a (U+93e4) */
	C_KANJI_JIS_6F3C, /*  0xe85b (U+941a) */
	C_KANJI_JIS_6F3D, /*  0xe85c (U+9414) */
	C_KANJI_JIS_6F3E, /*  0xe85d (U+9413) */
	C_KANJI_JIS_6F3F, /*  0xe85e (U+9403) */
	C_KANJI_JIS_6F40, /*  0xe85f (U+9407) */
	C_KANJI_JIS_6F41, /*  0xe860 (U+9410) */
	C_KANJI_JIS_6F42, /*  0xe861 (U+9436) */
	C_KANJI_JIS_6F43, /*  0xe862 (U+942b) */
	C_KANJI_JIS_6F44, /*  0xe863 (U+9435) */
	C_KANJI_JIS_6F45, /*  0xe864 (U+9421) */
	C_KANJI_JIS_6F46, /*  0xe865 (U+943a) */
	C_KANJI_JIS_6F47, /*  0xe866 (U+9441) */
	C_KANJI_JIS_6F48, /*  0xe867 (U+9452) */
	C_KANJI_JIS_6F49, /*  0xe868 (U+9444) */
	C_KANJI_JIS_6F4A, /*  0xe869 (U+945b) */
	C_KANJI_JIS_6F4B, /*  0xe86a (U+9460) */
	C_KANJI_JIS_6F4C, /*  0xe86b (U+9462) */
	C_KANJI_JIS_6F4D, /*  0xe86c (U+945e) */
	C_KANJI_JIS_6F4E, /*  0xe86d (U+946a) */
	C_KANJI_JIS_6F4F, /*  0xe86e (U+9229) */
	C_KANJI_JIS_6F50, /*  0xe86f (U+9470) */
	C_KANJI_JIS_6F51, /*  0xe870 (U+9475) */
	C_KANJI_JIS_6F52, /*  0xe871 (U+9477) */
	C_KANJI_JIS_6F53, /*  0xe872 (U+947d) */
	C_KANJI_JIS_6F54, /*  0xe873 (U+945a) */
	C_KANJI_JIS_6F55, /*  0xe874 (U+947c) */
	C_KANJI_JIS_6F56, /*  0xe875 (U+947e) */
	C_KANJI_JIS_6F57, /*  0xe876 (U+9481) */
	C_KANJI_JIS_6F58, /*  0xe877 (U+947f) */
	C_KANJI_JIS_6F59, /*  0xe878 (U+9582) */
	C_KANJI_JIS_6F5A, /*  0xe879 (U+9587) */
	C_KANJI_JIS_6F5B, /*  0xe87a (U+958a) */
	C_KANJI_JIS_6F5C, /*  0xe87b (U+9594) */
	C_KANJI_JIS_6F5D, /*  0xe87c (U+9596) */
	C_KANJI_JIS_6F5E, /*  0xe87d (U+9598) */
	C_KANJI_JIS_6F5F, /*  0xe87e (U+9599) */
	0, /*  0xe87f */
	C_KANJI_JIS_6F60, /*  0xe880 (U+95a0) */
	C_KANJI_JIS_6F61, /*  0xe881 (U+95a8) */
	C_KANJI_JIS_6F62, /*  0xe882 (U+95a7) */
	C_KANJI_JIS_6F63, /*  0xe883 (U+95ad) */
	C_KANJI_JIS_6F64, /*  0xe884 (U+95bc) */
	C_KANJI_JIS_6F65, /*  0xe885 (U+95bb) */
	C_KANJI_JIS_6F66, /*  0xe886 (U+95b9) */
	C_KANJI_JIS_6F67, /*  0xe887 (U+95be) */
	C_KANJI_JIS_6F68, /*  0xe888 (U+95ca) */
	C_KANJI_JIS_6F69, /*  0xe889 (U+6ff6) */
	C_KANJI_JIS_6F6A, /*  0xe88a (U+95c3) */
	C_KANJI_JIS_6F6B, /*  0xe88b (U+95cd) */
	C_KANJI_JIS_6F6C, /*  0xe88c (U+95cc) */
	C_KANJI_JIS_6F6D, /*  0xe88d (U+95d5) */
	C_KANJI_JIS_6F6E, /*  0xe88e (U+95d4) */
	C_KANJI_JIS_6F6F, /*  0xe88f (U+95d6) */
	C_KANJI_JIS_6F70, /*  0xe890 (U+95dc) */
	C_KANJI_JIS_6F71, /*  0xe891 (U+95e1) */
	C_KANJI_JIS_6F72, /*  0xe892 (U+95e5) */
	C_KANJI_JIS_6F73, /*  0xe893 (U+95e2) */
	C_KANJI_JIS_6F74, /*  0xe894 (U+9621) */
	C_KANJI_JIS_6F75, /*  0xe895 (U+9628) */
	C_KANJI_JIS_6F76, /*  0xe896 (U+962e) */
	C_KANJI_JIS_6F77, /*  0xe897 (U+962f) */
	C_KANJI_JIS_6F78, /*  0xe898 (U+9642) */
	C_KANJI_JIS_6F79, /*  0xe899 (U+964c) */
	C_KANJI_JIS_6F7A, /*  0xe89a (U+964f) */
	C_KANJI_JIS_6F7B, /*  0xe89b (U+964b) */
	C_KANJI_JIS_6F7C, /*  0xe89c (U+9677) */
	C_KANJI_JIS_6F7D, /*  0xe89d (U+965c) */
	C_KANJI_JIS_6F7E, /*  0xe89e (U+965e) */
	C_KANJI_JIS_7021, /*  0xe89f (U+965d) */
	C_KANJI_JIS_7022, /*  0xe8a0 (U+965f) */
	C_KANJI_JIS_7023, /*  0xe8a1 (U+9666) */
	C_KANJI_JIS_7024, /*  0xe8a2 (U+9672) */
	C_KANJI_JIS_7025, /*  0xe8a3 (U+966c) */
	C_KANJI_JIS_7026, /*  0xe8a4 (U+968d) */
	C_KANJI_JIS_7027, /*  0xe8a5 (U+9698) */
	C_KANJI_JIS_7028, /*  0xe8a6 (U+9695) */
	C_KANJI_JIS_7029, /*  0xe8a7 (U+9697) */
	C_KANJI_JIS_702A, /*  0xe8a8 (U+96aa) */
	C_KANJI_JIS_702B, /*  0xe8a9 (U+96a7) */
	C_KANJI_JIS_702C, /*  0xe8aa (U+96b1) */
	C_KANJI_JIS_702D, /*  0xe8ab (U+96b2) */
	C_KANJI_JIS_702E, /*  0xe8ac (U+96b0) */
	C_KANJI_JIS_702F, /*  0xe8ad (U+96b4) */
	C_KANJI_JIS_7030, /*  0xe8ae (U+96b6) */
	C_KANJI_JIS_7031, /*  0xe8af (U+96b8) */
	C_KANJI_JIS_7032, /*  0xe8b0 (U+96b9) */
	C_KANJI_JIS_7033, /*  0xe8b1 (U+96ce) */
	C_KANJI_JIS_7034, /*  0xe8b2 (U+96cb) */
	C_KANJI_JIS_7035, /*  0xe8b3 (U+96c9) */
	C_KANJI_JIS_7036, /*  0xe8b4 (U+96cd) */
	C_KANJI_JIS_7037, /*  0xe8b5 (U+894d) */
	C_KANJI_JIS_7038, /*  0xe8b6 (U+96dc) */
	C_KANJI_JIS_7039, /*  0xe8b7 (U+970d) */
	C_KANJI_JIS_703A, /*  0xe8b8 (U+96d5) */
	C_KANJI_JIS_703B, /*  0xe8b9 (U+96f9) */
	C_KANJI_JIS_703C, /*  0xe8ba (U+9704) */
	C_KANJI_JIS_703D, /*  0xe8bb (U+9706) */
	C_KANJI_JIS_703E, /*  0xe8bc (U+9708) */
	C_KANJI_JIS_703F, /*  0xe8bd (U+9713) */
	C_KANJI_JIS_7040, /*  0xe8be (U+970e) */
	C_KANJI_JIS_7041, /*  0xe8bf (U+9711) */
	C_KANJI_JIS_7042, /*  0xe8c0 (U+970f) */
	C_KANJI_JIS_7043, /*  0xe8c1 (U+9716) */
	C_KANJI_JIS_7044, /*  0xe8c2 (U+9719) */
	C_KANJI_JIS_7045, /*  0xe8c3 (U+9724) */
	C_KANJI_JIS_7046, /*  0xe8c4 (U+972a) */
	C_KANJI_JIS_7047, /*  0xe8c5 (U+9730) */
	C_KANJI_JIS_7048, /*  0xe8c6 (U+9739) */
	C_KANJI_JIS_7049, /*  0xe8c7 (U+973d) */
	C_KANJI_JIS_704A, /*  0xe8c8 (U+973e) */
	C_KANJI_JIS_704B, /*  0xe8c9 (U+9744) */
	C_KANJI_JIS_704C, /*  0xe8ca (U+9746) */
	C_KANJI_JIS_704D, /*  0xe8cb (U+9748) */
	C_KANJI_JIS_704E, /*  0xe8cc (U+9742) */
	C_KANJI_JIS_704F, /*  0xe8cd (U+9749) */
	C_KANJI_JIS_7050, /*  0xe8ce (U+975c) */
	C_KANJI_JIS_7051, /*  0xe8cf (U+9760) */
	C_KANJI_JIS_7052, /*  0xe8d0 (U+9764) */
	C_KANJI_JIS_7053, /*  0xe8d1 (U+9766) */
	C_KANJI_JIS_7054, /*  0xe8d2 (U+9768) */
	C_KANJI_JIS_7055, /*  0xe8d3 (U+52d2) */
	C_KANJI_JIS_7056, /*  0xe8d4 (U+976b) */
	C_KANJI_JIS_7057, /*  0xe8d5 (U+9771) */
	C_KANJI_JIS_7058, /*  0xe8d6 (U+9779) */
	C_KANJI_JIS_7059, /*  0xe8d7 (U+9785) */
	C_KANJI_JIS_705A, /*  0xe8d8 (U+977c) */
	C_KANJI_JIS_705B, /*  0xe8d9 (U+9781) */
	C_KANJI_JIS_705C, /*  0xe8da (U+977a) */
	C_KANJI_JIS_705D, /*  0xe8db (U+9786) */
	C_KANJI_JIS_705E, /*  0xe8dc (U+978b) */
	C_KANJI_JIS_705F, /*  0xe8dd (U+978f) */
	C_KANJI_JIS_7060, /*  0xe8de (U+9790) */
	C_KANJI_JIS_7061, /*  0xe8df (U+979c) */
	C_KANJI_JIS_7062, /*  0xe8e0 (U+97a8) */
	C_KANJI_JIS_7063, /*  0xe8e1 (U+97a6) */
	C_KANJI_JIS_7064, /*  0xe8e2 (U+97a3) */
	C_KANJI_JIS_7065, /*  0xe8e3 (U+97b3) */
	C_KANJI_JIS_7066, /*  0xe8e4 (U+97b4) */
	C_KANJI_JIS_7067, /*  0xe8e5 (U+97c3) */
	C_KANJI_JIS_7068, /*  0xe8e6 (U+97c6) */
	C_KANJI_JIS_7069, /*  0xe8e7 (U+97c8) */
	C_KANJI_JIS_706A, /*  0xe8e8 (U+97cb) */
	C_KANJI_JIS_706B, /*  0xe8e9 (U+97dc) */
	C_KANJI_JIS_706C, /*  0xe8ea (U+97ed) */
	C_KANJI_JIS_706D, /*  0xe8eb (U+9f4f) */
	C_KANJI_JIS_706E, /*  0xe8ec (U+97f2) */
	C_KANJI_JIS_706F, /*  0xe8ed (U+7adf) */
	C_KANJI_JIS_7070, /*  0xe8ee (U+97f6) */
	C_KANJI_JIS_7071, /*  0xe8ef (U+97f5) */
	C_KANJI_JIS_7072, /*  0xe8f0 (U+980f) */
	C_KANJI_JIS_7073, /*  0xe8f1 (U+980c) */
	C_KANJI_JIS_7074, /*  0xe8f2 (U+9838) */
	C_KANJI_JIS_7075, /*  0xe8f3 (U+9824) */
	C_KANJI_JIS_7076, /*  0xe8f4 (U+9821) */
	C_KANJI_JIS_7077, /*  0xe8f5 (U+9837) */
	C_KANJI_JIS_7078, /*  0xe8f6 (U+983d) */
	C_KANJI_JIS_7079, /*  0xe8f7 (U+9846) */
	C_KANJI_JIS_707A, /*  0xe8f8 (U+984f) */
	C_KANJI_JIS_707B, /*  0xe8f9 (U+984b) */
	C_KANJI_JIS_707C, /*  0xe8fa (U+986b) */
	C_KANJI_JIS_707D, /*  0xe8fb (U+986f) */
	C_KANJI_JIS_707E, /*  0xe8fc (U+9870) */
	0, /*  0xe8fd */
	0, /*  0xe8fe */
	0, /*  0xe8ff */
	C_KANJI_JIS_7121, /*  0xe940 (U+9871) */
	C_KANJI_JIS_7122, /*  0xe941 (U+9874) */
	C_KANJI_JIS_7123, /*  0xe942 (U+9873) */
	C_KANJI_JIS_7124, /*  0xe943 (U+98aa) */
	C_KANJI_JIS_7125, /*  0xe944 (U+98af) */
	C_KANJI_JIS_7126, /*  0xe945 (U+98b1) */
	C_KANJI_JIS_7127, /*  0xe946 (U+98b6) */
	C_KANJI_JIS_7128, /*  0xe947 (U+98c4) */
	C_KANJI_JIS_7129, /*  0xe948 (U+98c3) */
	C_KANJI_JIS_712A, /*  0xe949 (U+98c6) */
	C_KANJI_JIS_712B, /*  0xe94a (U+98e9) */
	C_KANJI_JIS_712C, /*  0xe94b (U+98eb) */
	C_KANJI_JIS_712D, /*  0xe94c (U+9903) */
	C_KANJI_JIS_712E, /*  0xe94d (U+9909) */
	C_KANJI_JIS_712F, /*  0xe94e (U+9912) */
	C_KANJI_JIS_7130, /*  0xe94f (U+9914) */
	C_KANJI_JIS_7131, /*  0xe950 (U+9918) */
	C_KANJI_JIS_7132, /*  0xe951 (U+9921) */
	C_KANJI_JIS_7133, /*  0xe952 (U+991d) */
	C_KANJI_JIS_7134, /*  0xe953 (U+991e) */
	C_KANJI_JIS_7135, /*  0xe954 (U+9924) */
	C_KANJI_JIS_7136, /*  0xe955 (U+9920) */
	C_KANJI_JIS_7137, /*  0xe956 (U+992c) */
	C_KANJI_JIS_7138, /*  0xe957 (U+992e) */
	C_KANJI_JIS_7139, /*  0xe958 (U+993d) */
	C_KANJI_JIS_713A, /*  0xe959 (U+993e) */
	C_KANJI_JIS_713B, /*  0xe95a (U+9942) */
	C_KANJI_JIS_713C, /*  0xe95b (U+9949) */
	C_KANJI_JIS_713D, /*  0xe95c (U+9945) */
	C_KANJI_JIS_713E, /*  0xe95d (U+9950) */
	C_KANJI_JIS_713F, /*  0xe95e (U+994b) */
	C_KANJI_JIS_7140, /*  0xe95f (U+9951) */
	C_KANJI_JIS_7141, /*  0xe960 (U+9952) */
	C_KANJI_JIS_7142, /*  0xe961 (U+994c) */
	C_KANJI_JIS_7143, /*  0xe962 (U+9955) */
	C_KANJI_JIS_7144, /*  0xe963 (U+9997) */
	C_KANJI_JIS_7145, /*  0xe964 (U+9998) */
	C_KANJI_JIS_7146, /*  0xe965 (U+99a5) */
	C_KANJI_JIS_7147, /*  0xe966 (U+99ad) */
	C_KANJI_JIS_7148, /*  0xe967 (U+99ae) */
	C_KANJI_JIS_7149, /*  0xe968 (U+99bc) */
	C_KANJI_JIS_714A, /*  0xe969 (U+99df) */
	C_KANJI_JIS_714B, /*  0xe96a (U+99db) */
	C_KANJI_JIS_714C, /*  0xe96b (U+99dd) */
	C_KANJI_JIS_714D, /*  0xe96c (U+99d8) */
	C_KANJI_JIS_714E, /*  0xe96d (U+99d1) */
	C_KANJI_JIS_714F, /*  0xe96e (U+99ed) */
	C_KANJI_JIS_7150, /*  0xe96f (U+99ee) */
	C_KANJI_JIS_7151, /*  0xe970 (U+99f1) */
	C_KANJI_JIS_7152, /*  0xe971 (U+99f2) */
	C_KANJI_JIS_7153, /*  0xe972 (U+99fb) */
	C_KANJI_JIS_7154, /*  0xe973 (U+99f8) */
	C_KANJI_JIS_7155, /*  0xe974 (U+9a01) */
	C_KANJI_JIS_7156, /*  0xe975 (U+9a0f) */
	C_KANJI_JIS_7157, /*  0xe976 (U+9a05) */
	C_KANJI_JIS_7158, /*  0xe977 (U+99e2) */
	C_KANJI_JIS_7159, /*  0xe978 (U+9a19) */
	C_KANJI_JIS_715A, /*  0xe979 (U+9a2b) */
	C_KANJI_JIS_715B, /*  0xe97a (U+9a37) */
	C_KANJI_JIS_715C, /*  0xe97b (U+9a45) */
	C_KANJI_JIS_715D, /*  0xe97c (U+9a42) */
	C_KANJI_JIS_715E, /*  0xe97d (U+9a40) */
	C_KANJI_JIS_715F, /*  0xe97e (U+9a43) */
	0, /*  0xe97f */
	C_KANJI_JIS_7160, /*  0xe980 (U+9a3e) */
	C_KANJI_JIS_7161, /*  0xe981 (U+9a55) */
	C_KANJI_JIS_7162, /*  0xe982 (U+9a4d) */
	C_KANJI_JIS_7163, /*  0xe983 (U+9a5b) */
	C_KANJI_JIS_7164, /*  0xe984 (U+9a57) */
	C_KANJI_JIS_7165, /*  0xe985 (U+9a5f) */
	C_KANJI_JIS_7166, /*  0xe986 (U+9a62) */
	C_KANJI_JIS_7167, /*  0xe987 (U+9a65) */
	C_KANJI_JIS_7168, /*  0xe988 (U+9a64) */
	C_KANJI_JIS_7169, /*  0xe989 (U+9a69) */
	C_KANJI_JIS_716A, /*  0xe98a (U+9a6b) */
	C_KANJI_JIS_716B, /*  0xe98b (U+9a6a) */
	C_KANJI_JIS_716C, /*  0xe98c (U+9aad) */
	C_KANJI_JIS_716D, /*  0xe98d (U+9ab0) */
	C_KANJI_JIS_716E, /*  0xe98e (U+9abc) */
	C_KANJI_JIS_716F, /*  0xe98f (U+9ac0) */
	C_KANJI_JIS_7170, /*  0xe990 (U+9acf) */
	C_KANJI_JIS_7171, /*  0xe991 (U+9ad1) */
	C_KANJI_JIS_7172, /*  0xe992 (U+9ad3) */
	C_KANJI_JIS_7173, /*  0xe993 (U+9ad4) */
	C_KANJI_JIS_7174, /*  0xe994 (U+9ade) */
	C_KANJI_JIS_7175, /*  0xe995 (U+9adf) */
	C_KANJI_JIS_7176, /*  0xe996 (U+9ae2) */
	C_KANJI_JIS_7177, /*  0xe997 (U+9ae3) */
	C_KANJI_JIS_7178, /*  0xe998 (U+9ae6) */
	C_KANJI_JIS_7179, /*  0xe999 (U+9aef) */
	C_KANJI_JIS_717A, /*  0xe99a (U+9aeb) */
	C_KANJI_JIS_717B, /*  0xe99b (U+9aee) */
	C_KANJI_JIS_717C, /*  0xe99c (U+9af4) */
	C_KANJI_JIS_717D, /*  0xe99d (U+9af1) */
	C_KANJI_JIS_717E, /*  0xe99e (U+9af7) */
	C_KANJI_JIS_7221, /*  0xe99f (U+9afb) */
	C_KANJI_JIS_7222, /*  0xe9a0 (U+9b06) */
	C_KANJI_JIS_7223, /*  0xe9a1 (U+9b18) */
	C_KANJI_JIS_7224, /*  0xe9a2 (U+9b1a) */
	C_KANJI_JIS_7225, /*  0xe9a3 (U+9b1f) */
	C_KANJI_JIS_7226, /*  0xe9a4 (U+9b22) */
	C_KANJI_JIS_7227, /*  0xe9a5 (U+9b23) */
	C_KANJI_JIS_7228, /*  0xe9a6 (U+9b25) */
	C_KANJI_JIS_7229, /*  0xe9a7 (U+9b27) */
	C_KANJI_JIS_722A, /*  0xe9a8 (U+9b28) */
	C_KANJI_JIS_722B, /*  0xe9a9 (U+9b29) */
	C_KANJI_JIS_722C, /*  0xe9aa (U+9b2a) */
	C_KANJI_JIS_722D, /*  0xe9ab (U+9b2e) */
	C_KANJI_JIS_722E, /*  0xe9ac (U+9b2f) */
	C_KANJI_JIS_722F, /*  0xe9ad (U+9b32) */
	C_KANJI_JIS_7230, /*  0xe9ae (U+9b44) */
	C_KANJI_JIS_7231, /*  0xe9af (U+9b43) */
	C_KANJI_JIS_7232, /*  0xe9b0 (U+9b4f) */
	C_KANJI_JIS_7233, /*  0xe9b1 (U+9b4d) */
	C_KANJI_JIS_7234, /*  0xe9b2 (U+9b4e) */
	C_KANJI_JIS_7235, /*  0xe9b3 (U+9b51) */
	C_KANJI_JIS_7236, /*  0xe9b4 (U+9b58) */
	C_KANJI_JIS_7237, /*  0xe9b5 (U+9b74) */
	C_KANJI_JIS_7238, /*  0xe9b6 (U+9b93) */
	C_KANJI_JIS_7239, /*  0xe9b7 (U+9b83) */
	C_KANJI_JIS_723A, /*  0xe9b8 (U+9b91) */
	C_KANJI_JIS_723B, /*  0xe9b9 (U+9b96) */
	C_KANJI_JIS_723C, /*  0xe9ba (U+9b97) */
	C_KANJI_JIS_723D, /*  0xe9bb (U+9b9f) */
	C_KANJI_JIS_723E, /*  0xe9bc (U+9ba0) */
	C_KANJI_JIS_723F, /*  0xe9bd (U+9ba8) */
	C_KANJI_JIS_7240, /*  0xe9be (U+9bb4) */
	C_KANJI_JIS_7241, /*  0xe9bf (U+9bc0) */
	C_KANJI_JIS_7242, /*  0xe9c0 (U+9bca) */
	C_KANJI_JIS_7243, /*  0xe9c1 (U+9bb9) */
	C_KANJI_JIS_7244, /*  0xe9c2 (U+9bc6) */
	C_KANJI_JIS_7245, /*  0xe9c3 (U+9bcf) */
	C_KANJI_JIS_7246, /*  0xe9c4 (U+9bd1) */
	C_KANJI_JIS_7247, /*  0xe9c5 (U+9bd2) */
	C_KANJI_JIS_7248, /*  0xe9c6 (U+9be3) */
	C_KANJI_JIS_7249, /*  0xe9c7 (U+9be2) */
	C_KANJI_JIS_724A, /*  0xe9c8 (U+9be4) */
	C_KANJI_JIS_724B, /*  0xe9c9 (U+9bd4) */
	C_KANJI_JIS_724C, /*  0xe9ca (U+9be1) */
	C_KANJI_JIS_724D, /*  0xe9cb (U+9c3a) */
	C_KANJI_JIS_724E, /*  0xe9cc (U+9bf2) */
	C_KANJI_JIS_724F, /*  0xe9cd (U+9bf1) */
	C_KANJI_JIS_7250, /*  0xe9ce (U+9bf0) */
	C_KANJI_JIS_7251, /*  0xe9cf (U+9c15) */
	C_KANJI_JIS_7252, /*  0xe9d0 (U+9c14) */
	C_KANJI_JIS_7253, /*  0xe9d1 (U+9c09) */
	C_KANJI_JIS_7254, /*  0xe9d2 (U+9c13) */
	C_KANJI_JIS_7255, /*  0xe9d3 (U+9c0c) */
	C_KANJI_JIS_7256, /*  0xe9d4 (U+9c06) */
	C_KANJI_JIS_7257, /*  0xe9d5 (U+9c08) */
	C_KANJI_JIS_7258, /*  0xe9d6 (U+9c12) */
	C_KANJI_JIS_7259, /*  0xe9d7 (U+9c0a) */
	C_KANJI_JIS_725A, /*  0xe9d8 (U+9c04) */
	C_KANJI_JIS_725B, /*  0xe9d9 (U+9c2e) */
	C_KANJI_JIS_725C, /*  0xe9da (U+9c1b) */
	C_KANJI_JIS_725D, /*  0xe9db (U+9c25) */
	C_KANJI_JIS_725E, /*  0xe9dc (U+9c24) */
	C_KANJI_JIS_725F, /*  0xe9dd (U+9c21) */
	C_KANJI_JIS_7260, /*  0xe9de (U+9c30) */
	C_KANJI_JIS_7261, /*  0xe9df (U+9c47) */
	C_KANJI_JIS_7262, /*  0xe9e0 (U+9c32) */
	C_KANJI_JIS_7263, /*  0xe9e1 (U+9c46) */
	C_KANJI_JIS_7264, /*  0xe9e2 (U+9c3e) */
	C_KANJI_JIS_7265, /*  0xe9e3 (U+9c5a) */
	C_KANJI_JIS_7266, /*  0xe9e4 (U+9c60) */
	C_KANJI_JIS_7267, /*  0xe9e5 (U+9c67) */
	C_KANJI_JIS_7268, /*  0xe9e6 (U+9c76) */
	C_KANJI_JIS_7269, /*  0xe9e7 (U+9c78) */
	C_KANJI_JIS_726A, /*  0xe9e8 (U+9ce7) */
	C_KANJI_JIS_726B, /*  0xe9e9 (U+9cec) */
	C_KANJI_JIS_726C, /*  0xe9ea (U+9cf0) */
	C_KANJI_JIS_726D, /*  0xe9eb (U+9d09) */
	C_KANJI_JIS_726E, /*  0xe9ec (U+9d08) */
	C_KANJI_JIS_726F, /*  0xe9ed (U+9ceb) */
	C_KANJI_JIS_7270, /*  0xe9ee (U+9d03) */
	C_KANJI_JIS_7271, /*  0xe9ef (U+9d06) */
	C_KANJI_JIS_7272, /*  0xe9f0 (U+9d2a) */
	C_KANJI_JIS_7273, /*  0xe9f1 (U+9d26) */
	C_KANJI_JIS_7274, /*  0xe9f2 (U+9daf) */
	C_KANJI_JIS_7275, /*  0xe9f3 (U+9d23) */
	C_KANJI_JIS_7276, /*  0xe9f4 (U+9d1f) */
	C_KANJI_JIS_7277, /*  0xe9f5 (U+9d44) */
	C_KANJI_JIS_7278, /*  0xe9f6 (U+9d15) */
	C_KANJI_JIS_7279, /*  0xe9f7 (U+9d12) */
	C_KANJI_JIS_727A, /*  0xe9f8 (U+9d41) */
	C_KANJI_JIS_727B, /*  0xe9f9 (U+9d3f) */
	C_KANJI_JIS_727C, /*  0xe9fa (U+9d3e) */
	C_KANJI_JIS_727D, /*  0xe9fb (U+9d46) */
	C_KANJI_JIS_727E, /*  0xe9fc (U+9d48) */
	0, /*  0xe9fd */
	0, /*  0xe9fe */
	0, /*  0xe9ff */
	C_KANJI_JIS_7321, /*  0xea40 (U+9d5d) */
	C_KANJI_JIS_7322, /*  0xea41 (U+9d5e) */
	C_KANJI_JIS_7323, /*  0xea42 (U+9d64) */
	C_KANJI_JIS_7324, /*  0xea43 (U+9d51) */
	C_KANJI_JIS_7325, /*  0xea44 (U+9d50) */
	C_KANJI_JIS_7326, /*  0xea45 (U+9d59) */
	C_KANJI_JIS_7327, /*  0xea46 (U+9d72) */
	C_KANJI_JIS_7328, /*  0xea47 (U+9d89) */
	C_KANJI_JIS_7329, /*  0xea48 (U+9d87) */
	C_KANJI_JIS_732A, /*  0xea49 (U+9dab) */
	C_KANJI_JIS_732B, /*  0xea4a (U+9d6f) */
	C_KANJI_JIS_732C, /*  0xea4b (U+9d7a) */
	C_KANJI_JIS_732D, /*  0xea4c (U+9d9a) */
	C_KANJI_JIS_732E, /*  0xea4d (U+9da4) */
	C_KANJI_JIS_732F, /*  0xea4e (U+9da9) */
	C_KANJI_JIS_7330, /*  0xea4f (U+9db2) */
	C_KANJI_JIS_7331, /*  0xea50 (U+9dc4) */
	C_KANJI_JIS_7332, /*  0xea51 (U+9dc1) */
	C_KANJI_JIS_7333, /*  0xea52 (U+9dbb) */
	C_KANJI_JIS_7334, /*  0xea53 (U+9db8) */
	C_KANJI_JIS_7335, /*  0xea54 (U+9dba) */
	C_KANJI_JIS_7336, /*  0xea55 (U+9dc6) */
	C_KANJI_JIS_7337, /*  0xea56 (U+9dcf) */
	C_KANJI_JIS_7338, /*  0xea57 (U+9dc2) */
	C_KANJI_JIS_7339, /*  0xea58 (U+9dd9) */
	C_KANJI_JIS_733A, /*  0xea59 (U+9dd3) */
	C_KANJI_JIS_733B, /*  0xea5a (U+9df8) */
	C_KANJI_JIS_733C, /*  0xea5b (U+9de6) */
	C_KANJI_JIS_733D, /*  0xea5c (U+9ded) */
	C_KANJI_JIS_733E, /*  0xea5d (U+9def) */
	C_KANJI_JIS_733F, /*  0xea5e (U+9dfd) */
	C_KANJI_JIS_7340, /*  0xea5f (U+9e1a) */
	C_KANJI_JIS_7341, /*  0xea60 (U+9e1b) */
	C_KANJI_JIS_7342, /*  0xea61 (U+9e1e) */
	C_KANJI_JIS_7343, /*  0xea62 (U+9e75) */
	C_KANJI_JIS_7344, /*  0xea63 (U+9e79) */
	C_KANJI_JIS_7345, /*  0xea64 (U+9e7d) */
	C_KANJI_JIS_7346, /*  0xea65 (U+9e81) */
	C_KANJI_JIS_7347, /*  0xea66 (U+9e88) */
	C_KANJI_JIS_7348, /*  0xea67 (U+9e8b) */
	C_KANJI_JIS_7349, /*  0xea68 (U+9e8c) */
	C_KANJI_JIS_734A, /*  0xea69 (U+9e92) */
	C_KANJI_JIS_734B, /*  0xea6a (U+9e95) */
	C_KANJI_JIS_734C, /*  0xea6b (U+9e91) */
	C_KANJI_JIS_734D, /*  0xea6c (U+9e9d) */
	C_KANJI_JIS_734E, /*  0xea6d (U+9ea5) */
	C_KANJI_JIS_734F, /*  0xea6e (U+9ea9) */
	C_KANJI_JIS_7350, /*  0xea6f (U+9eb8) */
	C_KANJI_JIS_7351, /*  0xea70 (U+9eaa) */
	C_KANJI_JIS_7352, /*  0xea71 (U+9ead) */
	C_KANJI_JIS_7353, /*  0xea72 (U+9761) */
	C_KANJI_JIS_7354, /*  0xea73 (U+9ecc) */
	C_KANJI_JIS_7355, /*  0xea74 (U+9ece) */
	C_KANJI_JIS_7356, /*  0xea75 (U+9ecf) */
	C_KANJI_JIS_7357, /*  0xea76 (U+9ed0) */
	C_KANJI_JIS_7358, /*  0xea77 (U+9ed4) */
	C_KANJI_JIS_7359, /*  0xea78 (U+9edc) */
	C_KANJI_JIS_735A, /*  0xea79 (U+9ede) */
	C_KANJI_JIS_735B, /*  0xea7a (U+9edd) */
	C_KANJI_JIS_735C, /*  0xea7b (U+9ee0) */
	C_KANJI_JIS_735D, /*  0xea7c (U+9ee5) */
	C_KANJI_JIS_735E, /*  0xea7d (U+9ee8) */
	C_KANJI_JIS_735F, /*  0xea7e (U+9eef) */
	0, /*  0xea7f */
	C_KANJI_JIS_7360, /*  0xea80 (U+9ef4) */
	C_KANJI_JIS_7361, /*  0xea81 (U+9ef6) */
	C_KANJI_JIS_7362, /*  0xea82 (U+9ef7) */
	C_KANJI_JIS_7363, /*  0xea83 (U+9ef9) */
	C_KANJI_JIS_7364, /*  0xea84 (U+9efb) */
	C_KANJI_JIS_7365, /*  0xea85 (U+9efc) */
	C_KANJI_JIS_7366, /*  0xea86 (U+9efd) */
	C_KANJI_JIS_7367, /*  0xea87 (U+9f07) */
	C_KANJI_JIS_7368, /*  0xea88 (U+9f08) */
	C_KANJI_JIS_7369, /*  0xea89 (U+76b7) */
	C_KANJI_JIS_736A, /*  0xea8a (U+9f15) */
	C_KANJI_JIS_736B, /*  0xea8b (U+9f21) */
	C_KANJI_JIS_736C, /*  0xea8c (U+9f2c) */
	C_KANJI_JIS_736D, /*  0xea8d (U+9f3e) */
	C_KANJI_JIS_736E, /*  0xea8e (U+9f4a) */
	C_KANJI_JIS_736F, /*  0xea8f (U+9f52) */
	C_KANJI_JIS_7370, /*  0xea90 (U+9f54) */
	C_KANJI_JIS_7371, /*  0xea91 (U+9f63) */
	C_KANJI_JIS_7372, /*  0xea92 (U+9f5f) */
	C_KANJI_JIS_7373, /*  0xea93 (U+9f60) */
	C_KANJI_JIS_7374, /*  0xea94 (U+9f61) */
	C_KANJI_JIS_7375, /*  0xea95 (U+9f66) */
	C_KANJI_JIS_7376, /*  0xea96 (U+9f67) */
	C_KANJI_JIS_7377, /*  0xea97 (U+9f6c) */
	C_KANJI_JIS_7378, /*  0xea98 (U+9f6a) */
	C_KANJI_JIS_7379, /*  0xea99 (U+9f77) */
	C_KANJI_JIS_737A, /*  0xea9a (U+9f72) */
	C_KANJI_JIS_737B, /*  0xea9b (U+9f76) */
	C_KANJI_JIS_737C, /*  0xea9c (U+9f95) */
	C_KANJI_JIS_737D, /*  0xea9d (U+9f9c) */
	C_KANJI_JIS_737E, /*  0xea9e (U+9fa0) */
	C_KANJI_JIS_7421, /*  0xea9f (U+582f) */
	C_KANJI_JIS_7422, /*  0xeaa0 (U+69c7) */
	C_KANJI_JIS_7423, /*  0xeaa1 (U+9059) */
	C_KANJI_JIS_7424, /*  0xeaa2 (U+7464) */
	C_KANJI_JIS_7425, /*  0xeaa3 (U+51dc) */
	C_KANJI_JIS_7426, /*  0xeaa4 (U+7199) */
	0, /*  0xeaa5 */
	0, /*  0xeaa6 */
	0, /*  0xeaa7 */
	0, /*  0xeaa8 */
	0, /*  0xeaa9 */
	0, /*  0xeaaa */
	0, /*  0xeaab */
	0, /*  0xeaac */
	0, /*  0xeaad */
	0}; /*  0xeaae */


/***********************************************************************
 *			ScanSJISByte
 ***********************************************************************
 * SYNOPSIS:	  Reads and returns the next SJIS "byte" from the
 *                passed string, after dealing with \escape sequences.
 *
 * PASS:          A pointer to the SJIS input string. If this string is NULL,
 *                then this routine gets its input from PMFInput().
 *
 * CALLED BY:	  Scan_ScanSJISChar
 *
 * RETURN:	  The next SJIS byte from the input stream *unless* the routine
 *                encounters a hex number larger than 0xff, in which case
 *                it returns that number, which is interpreted by
 *                Scan_ScanSJISChar as an already-converted Unicode character.
 *
 * SIDE EFFECTS:  The input stream (either str or PMFInput()) is advanced
 *                beyond the byte(s) read.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon     28 jun 1994     Happy Birthday, ChrisB
 *
 ***********************************************************************/
unsigned long
ScanSJISByte(unsigned char **str, Boolean getVerbatim)
{
    unsigned short    c, c2;
    unsigned long     overflowCheck;

    /*
     * Input the next byte
     */
    c = str ? *(*str)++ : PMFInput() & 0xff;

    /*
     * Check for escape sequences. If no escape, or if they asked us to
     * get the thing with no interpretation (the only known case where
     * this is needed is in the 2nd byte of a 2-byte SJIS character,
     * since it can contain a backslash that should not be interpreted
     * as such), simply return the byte.
     */
    if (c != '\\' || getVerbatim) {
	return c;
    } else {

	/*
	 * Process the escape.
	 */
	c = str ? *(*str)++ : PMFInput() & 0xff;

	switch (c) {
	    /*
	     * Here are all the escape codes supported by Borland C, along
	     * with the values they represent.
	     */
	    case 'a':  return 0x07;
	    case 'b':  return 0x08;
	    case 'f':  return 0x0c;
	    case 'n':  return 0x0a;
	    case 'r':  return 0x0d;
	    case 't':  return 0x09;
	    case 'v':  return 0x0b;
	    case '\\': return 0x5c;
	    case '\'': return 0x27;
	    case '"':  return 0x22;
	    case '?':  return 0x3f;

	    /*
	     * If the thing is an octal value, read in up to 3 octal digits
	     */
	    case '0': case '1': case '2': case '3':
	    case '4': case '5': case '6': case '7':

		/*
		 * Convert the charcter to a digit
		 */
		c -= '0';

		c2 = str ? *(*str)++ : PMFInput() & 0xff;
		c2 -= '0';
		if (c2 < 8) {
	            /*
		     * Multiply the first character by 8 and add the second
		     */
		    c = (c << 3) + c2;

		    /*
		     * Read in the 3rd character
		     */
		    c2 = str ? *(*str)++ : PMFInput() & 0xff;
		    c2 -= '0';
		    if (c2 < 8) {
			/*
			 * Multiply the result so far by 8 and add the new
			 */
		        c = (c << 3) + c2;
		    } else {
			/*
			 * The third character wasn't part of our octal
			 * number, so throw it back.
			 */
			if (str) {
			    (*str)--;
			} else {
			    unput(c2 + '0');
			}
		    }
		} else {
		    /*
		     * The second character wasn't part of our octal
		     * number, so throw it back.
		     */
		    if (str) {
			(*str)--;
		    } else {
			unput(c2 + '0');
		    }
		}

		return c;

	    /*
	     * If the thing is an hex value, read the value up to 65536
	     */
	    case 'x': case 'X':

		/*
		 * Get the first hex digit following the \x and convert
		 * it to a number
		 */
		c = str ? *(*str)++ : PMFInput() & 0xff;
		switch (c) {
		    case '0': case '1': case '2': case '3': case '4':
		    case '5': case '6': case '7': case '8': case '9':
		        c -= '0';
			break;
		    case 'a': case 'b': case 'c':
		    case 'd': case 'e': case 'f':
			c -= 'a' - 10;
			break;
		    case 'A': case 'B': case 'C':
		    case 'D': case 'E': case 'F':
			c -= 'A' - 10;
			break;
		    default:
			yyerror("Illegal hex character '%c'", c);
		}

		/*
		 * Loop through successive digits
		 */
		while(c2 = str ? *(*str)++ : PMFInput() & 0xff) {
		    switch (c2) {
		        case '0': case '1': case '2': case '3': case '4':
		        case '5': case '6': case '7': case '8': case '9':
		            c2 -= '0';
			    break;
			case 'a': case 'b': case 'c':
			case 'd': case 'e': case 'f':
			    c2 -= 'a' - 10;
			    break;
			case 'A': case 'B': case 'C':
			case 'D': case 'E': case 'F':
			    c2 -= 'A' - 10;
			    break;
			default:
			    if (str) {
				(*str)--;
			    } else {
				unput(c2);
			    }
			    return c | SCANNED_BYTE_IS_UNICODE_CHAR;
		    }
		    overflowCheck = (unsigned long) (c << 4) + c2;
		    if (overflowCheck > SJIS_DBCS_END_2) {
			yyerror("Hex character constant \\x%x greater than largest Unicode character.", overflowCheck);
		    } else {
			c = (c << 4) + c2;
		    }
		}

		if (str) {
		    (*str)--;
		} else {
		    unput(c2);
		}
		return c | SCANNED_BYTE_IS_UNICODE_CHAR;

	    default:
		yyerror("Unrecognized escape character '%c'", c);
		return 0;	/* to keep compiler warnings at bay */
	    }
    }
}


/***********************************************************************
 *			Scan_ScanSJISChar
 ***********************************************************************
 * SYNOPSIS:	  Reads and returns the next SJIS character from the
 *                passed string, after dealing with \escape sequences.
 *
 * PASS:          A pointer to the SJIS input string. If this string is NULL,
 *                then this routine gets its input from PMFInput().
 *
 * CALLED BY:	  ScanQuotedMultiByteStringAndOutput,
 *                Scan_OutputMultiByteString
 *
 * RETURN:	  The next SJIS byte from the input stream *unless* the routine
 *                encounters a hex number larger than 0xff, in which case
 *                it returns that number, which is interpreted by
 *                Scan_ScanSJISChar as an already-converted Unicode character.
 *
 * SIDE EFFECTS:  The input stream (either str or PMFInput()) is advanced
 *                beyond the byte(s) read.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon     28 jun 1994     Happy Birthday, ChrisB
 *
 ***********************************************************************/
unsigned short
Scan_ScanSJISChar(unsigned char **str)
{
    unsigned long      scanChar;
    unsigned short     sjisChar, c1, c2 = 0;

    scanChar = ScanSJISByte(str, FALSE);
    c1 = scanChar & 0xffff;

    if (scanChar & SCANNED_BYTE_IS_UNICODE_CHAR) {
	return c1;
    }

    /*
     * If the first byte indicates a need for a second, read it in here
     */
    if (((c1 > SJIS_SB_END_1) && (c1 < SJIS_SB_START_2)) ||
	(c1 > SJIS_SB_END_2)) {
	c2 = c1;
	scanChar = ScanSJISByte(str, TRUE); /* TRUE = pass '\' to us verb. */
	c1 = scanChar & 0xffff;

	if (scanChar & SCANNED_BYTE_IS_UNICODE_CHAR) {
	    yyerror("Unicode character 0x%x cannot be used as the second byte of the two-byte sequence initiated by \\%03o. Please use the octal escape.", c1, c2);
	}

	/*
	 * Make sure the second byte falls within the legal limits
	 */
	if ((c1 < SJIS_DB2_START_1) ||
	    ((c1 > SJIS_DB2_END_1) && (c1 < SJIS_DB2_START_2)) ||
	    (c1 > SJIS_DB2_END_2)) {
	    yyerror("Illegal SJIS character: \\%03o follows \\%03o", c1, c2);
	}
    }

    sjisChar = (c2 << 8) + c1;

    /*
     * Check for the trivial case (ASCII == single byte)
     */
    if (sjisChar <= SJIS_SB_END_1) {
	return sjisChar;

    /*
     * Check for halfwidth katakana
     */
    } else if (sjisChar <= SJIS_SB_END_2) {
	if (sjisChar < SJIS_SB_START_2) {
	    yyerror("Illegal SJIS character 0x%x", sjisChar);
	} else {
	    return sjisChar + C_HALFWIDTH_IDEOGRAPHIC_PERIOD - SJIS_SB_START_2;
	}

    /*
     * See if it's a valid DBCS character
     */
    } else if ((sjisChar < SJIS_DBCS_START_1) || (c1 < SJIS_DB2_START_1)) {
	yyerror("Illegal SJIS character 0x%x", sjisChar);

    /*
     * If the character is beyond the supported range, complain.
     */
    } else if (sjisChar > 0xeaa4) {
    	yyerror("SJIS characters beyond 0xEAA4 not supported (0x%x)",
		sjisChar);

    /*
     * If the character falls within the 16K gap, complain.
     */
    } else if ((sjisChar > SJIS_DBCS_END_1) &&
	       (sjisChar < SJIS_DBCS_START_2)) {
	yyerror("Illegal SJIS character 0x%x", sjisChar);

    /*
     * It's a DBCS character. Let's map the thing.
     */
    } else {
	/*
	 * Check for the gap from 0xa000 -> 0xe000
	 */
	if (sjisChar >= SJIS_DBCS_START_2) {
	    sjisChar -= (SJIS_DB1_START_2 << 8) - SJIS_DBCS_END_1 - 1;
	}

	/*
	 * Adjust to table start
	 */
	sjisChar -= SJIS_DBCS_START_1;

	c1 = sjisChar % 256;
	sjisChar = (sjisChar >> 8) * 192;
	sjisChar += c1;

	return SJISToUnicodeTable[sjisChar];
    }

    return 0;			/* to keep compiler warnings at bay */
}
