
/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- lexical analyzer
 * FILE:	  scan.c
 *
 * AUTHOR:  	  Adam de Boor: Mar  6, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	yystdlex  	    Scan off a token from the current input
 *			    and return it
 *	yystartmacro	    Begin the processing of a macro call
 *	yyreadmacro	    Read a macro definition (INTERNAL)
 *	Scan_Init 	    Initialization function
 *	yyflush	  	    Flush to the end of the current line
 *	yyrepeat  	    Execute a REPT directive
 *	yyirp		    Execute an IRP directive
 *	yyirpc		    Execute an IRPC directive
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/ 2/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Lexical analyzer for Esp. Taken mostly from the scanner for Asap.
 *
 ***********************************************************************/

#include    "esp.h"
#include    "scan.h"
#include    "parse.h"

#include    <ctype.h>
/*
 * Deal with SunOS 4.1 internationalization effort...
 */
#ifndef tolower
#define tolower(c) ((c) + ('a' - 'A'))
#define toupper(c) ((c) - ('a' - 'A'))
#elif defined(__HIGHC__)
/*
 * Deal with HighC changing "tolower" and "toupper" to check if the damn thing
 * is lower or upper...
 */
#undef tolower
#undef toupper
#define tolower(c) _tolower(c)
#define toupper(c) _toupper(c)
#endif

#include    <objfmt.h>

int	    	inmacro;
int	    	snarfLine = 0;
int	    	showmacro = 0;
int	    	defStruct = 0;

/*
 * External interface variables
 */
int 	    	lexdebug=0;

#ifdef LEXDEBUG
#define DBPRINTF(args) if(lexdebug){ fprintf args; }
#else
#define DBPRINTF(args)
#endif /* LEXDEBUG */

#ifdef LEXDEBUG
#define DBG(args) if(lexdebug) args
#else
#define DBG(args)
#endif

FILE	    	*yyin;
int	    	yylineno=1;

LexProc	    	*yylex;
InputProc   	*yyinput;
WrapProc    	*yywrap;

#define NUM_MACRO_BLOCKS    20	/* Number of MBlk's to allocate at once */

#define PARAM_SIZE  	    32	/* Number of entries for macro dummy parameters
				 * and local labels to allocate at once */

#ifndef MAX_TOKEN_LENGTH
#define MAX_TOKEN_LENGTH    256
#endif /* MAX_TOKEN_LENGTH */
static char    	  yytext[MAX_TOKEN_LENGTH];

/*
 * noSymTrans is TRUE to prevent the translation of symbolic constants to
 * strings we read. Used by MACRO and the IFN?DEF conditionals.
 */
int	    	noSymTrans = FALSE;
int	    	firstArg = FALSE;
static int  	commaMeansEmpty;    /* If true and a comma is encountered
				     * in yymacarglex, an empty string will
				     * be returned as the argument being
				     * passed is empty. */
static int  	noEquate = FALSE;   /* Don't interpolate string equates --
				     * convert them to STRINGs */
static int	dotid = TRUE;	    /* This is set TRUE if a '.' as the
				     * first character of a token may be a
				     * part of the token. */
static ID   	lineID;	    	    /* ID for recognizing @Line */

#define F   1	/* firstid */
#define O   2	/* otherid */
#define B   3	/* both */
#define N   0	/* none */
#define T   4	/* macro argument terminator */
#define E   8	/* end-of-line character */
static const unsigned char  cbits[] = {
    N,	    	    	    	    	/* EOF */
    T,	N,  N,	N,  N,	N,  N,	N,  	/*  0 -  7 */
    N,	T, T|E, N,  N, T|E, N,	N,  	/*  8 - 15 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 16 - 23 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 24 - 31 */
    T,	N,  N, 	N,  B,	N,  N,	N,  	/* sp ! " # $ % & ' */
    N,	N,  N,	N,  T,	N,  N,	N,  	/* (  ) * + , - . / */
    O,	O,  O,	O,  O,	O,  O,	O,  	/* 0  1 2 3 4 5 6 7 */
    O,	O,  N,	T,  N,	N,  N,	B,  	/* 8  9 : ; < = > ? */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* @  A B C D E F G */
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

/*
 * Forward declarations
 */
static char 	input(void);
static char 	stdinput(void);
static int  	yyreadstring(char open, char close, char duplicate, YYSTYPE *);
static int	ustrcmp(char *s1, char *s2);
static char   	*newstr(char *);
static void    	yyfreemaps(void);
static void	yyreadmacro(YYSTYPE *yylval);


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
#define unput(c) *yysptr++ = c

/*
 * MACRO stuff
 */
MBlk	    	*curBlock=0;	    /* Current text block in macro. 0 if
				     * not in macro */
char	    	*curMacPtr;	    /* Pointer into block */
int	    	curMacCount=0;      /* Number of characters remaining in the
				     * block. */
int	    	numMaps=0;
MBlk	    	**maps = 0;
int	    	bumpLine=0;	    /* If 1, increment yylineno on entry to
				     * yylex. This is done b/c of the nature of
				     * the parser and its grammar -- it will
				     * read the newline long before it's
				     * actually done with the line, but once
				     * it's processed the newline, it will come
				     * back here for more. So the increment
				     * gets done only on the next call -- when
				     * we're sure we're actually on the next
				     * line */

typedef struct _MacState {
    MBlk    	  	*block;	    /* Block being read */
    char    	  	*ptr;	    /* Position in same */
    int	    	  	count;	    /* # chars remaining */
    MBlk    	  	**maps;	    /* Argument maps */
    int	    	  	numMaps;    /* # of same */
    char    	    	*pbBot;	    /* Bottom of the pushback stack */
    int	    	    	bumpLine;   /* Value of bumpLine */
    int	    	    	inmacro;    /* Value of inmacro */
    InputProc	    	*input;	    /* Input function at the time */
    int	    	    	iflevel;    /* level of conditionals on entrance to
				     * the macro. Needed to handle EXITM */
    struct _MacState	*next;	    /* Next frame in stack */
}	MacState;

static MacState     *macros = (MacState *)NULL;
static MacState	    *freeState = (MacState *)NULL;


/***********************************************************************
 *				yynewline
 ***********************************************************************
 * SYNOPSIS:	    Begin a newline
 * CALLED BY:	    yystdlex, yymacarglex
 * RETURN:	    nothing
 * SIDE EFFECTS:    a SYM_LINE symbol is entered for the current file.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/89		Initial Revision
 *
 ***********************************************************************/
static inline void
yynewline(void)
{
    yylineno++;
    bumpLine = 0;

    if (yylineno == 65536) {
	yyerror("I can't handle more than 65535 lines in a single file");
    }

    DBPRINTF((stderr,"Starting line %d\n", yylineno));

    /*
     * If we need to, enter a new line number symbol. "need" is dictated by
     * the location counter for the current segment having changed since the
     * last line number was added to the segment.
     */
    if ((curSeg->u.segment.data->lastLine == NULL) ||
	(curSeg->u.segment.data->lastLine->u.line.common.offset != dot))
    {
	curSeg->u.segment.data->lastLine =
	    Sym_Enter(NullID, SYM_LINE, curFile->name, yylineno, dot);
    } else {
	/*
	 * Overwrite the line number in the previous symbol since the
	 * location counter hasn't moved.
	 */
	curSeg->u.segment.data->lastLine->u.line.line = yylineno;
	curSeg->u.segment.data->lastLine->u.line.file = curFile->name;
    }
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
static MBlk *
NewBlock(void)
{
    static MBlk	*nextBlock;
    static int	numBlocks = 0;

    if (numBlocks == 0) {
	nextBlock = (MBlk *)malloc(NUM_MACRO_BLOCKS * sizeof(MBlk));
	numBlocks = NUM_MACRO_BLOCKS;
    }
    numBlocks -= 1;

    nextBlock->length = 0;
    nextBlock->dynamic = 0;
    nextBlock->next = 0;

    return(nextBlock++);
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
PushMacro(MBlk    *newBlock)	    	/* New block to read */
{
    MacState	  *msp;	    	/* Record of previous state */

    if ((msp = freeState) != NULL) {
	freeState = freeState->next;
    } else {
	msp = (MacState *)malloc(sizeof(MacState));
    }

    /*
     * First the real macro state
     */
    msp->block =  	curBlock;
    msp->ptr =		curMacPtr;
    msp->count =	curMacCount;
    msp->maps =		maps;
    msp->numMaps =	numMaps;
    msp->bumpLine = 	bumpLine;
    msp->inmacro =  	inmacro;
    msp->input =    	yyinput;
    msp->iflevel =  	iflevel;

    DBPRINTF((stderr,"PushMacro(%08x,%08x): bumpLine == %d\n", msp, macros, bumpLine));
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
    bumpLine = 0;
    /*
     * Set the input procedure back to the standard one as we've gone to a
     * different source of input (a macro). When we're done with the
     * macro, we'll go back to the other source. This deals with things
     * like:
     *	    DBItemInfo <strequate,>
     * What used to happen is we'd scan off the strequate, discover it's
     * a string equate and push to its value, leaving yyinput alone. The
     * next call to input would return an EOF (q.v. data.c) and we'd get
     * a parse error, which isn't good. This way, the value for the
     * string equate will be properly interpolated before an EOF is returned.
     */
    yyinput = stdinput;
}


/***********************************************************************
 *				PopMacro
 ***********************************************************************
 * SYNOPSIS:	  Restore the most recent macro.
 * CALLED BY:	  input
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
    if (numMaps != 0) {
	yyfreemaps();
    }

    DBPRINTF((stderr, "PopMacro(%08x, %08x)\n", msp, msp->next));
    /*
     * The real macro stuff
     */
    curBlock = 	    msp->block;
    curMacCount =   msp->count;
    curMacPtr =     msp->ptr;
    maps =  	    msp->maps;
    numMaps = 	    msp->numMaps;
    inmacro =	    msp->inmacro;
    yyinput =	    msp->input;

    switch (msp->bumpLine) {
	case 2:
	    /*
	     * Special case of pushed macro when entering a recursive
	     * parse (Scan_SavePB). Indicates bumpLine is to be made 1 and
	     * no line number increment is to take place here. The effect is
	     * to leave bumpLine the same as when the recursive parse was
	     * started so the line number isn't incremented prematurely
	     * while data are being entered.
	     */
	    bumpLine = 1;
	    break;
	case 1:
	    /*
	     * If bumpLine was TRUE when the state was pushed (which will happen
	     * at the end of reading the macro arguments), it will be ignored
	     * or possibly overwritten if we don't do something about it now.
	     */
	    yynewline();
	    /*FALLTHRU*/
	case 0:
	    bumpLine = 0;
    }

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
	     * because its next == NULL.
	     * Need to do a PopMacro to return from it, or else
	     * we'll never return from the macro -- curBlock is NULL, so
	     * stdinput will take things from the file.
	     *
	     *  Sigh.
	     *
	     * (Note that when PopMacro completes, curMacCount will not
	     * be -1, or curBlock will be NULL, so this loop will terminate)
	     */
	    PopMacro();
	}
    }
}


/***********************************************************************
 *				Scan_SavePB
 ***********************************************************************
 * SYNOPSIS:	    Save current input parameters/pushback
 * CALLED BY:	    Something before changing yyinput()
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Macro state is pushed
 *
 * STRATEGY:	    Just call PushMacro(NULL);
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 1/89		Initial Revision
 *
 ***********************************************************************/
void
Scan_SavePB(void)
{
    if (bumpLine) {
	bumpLine = 2;	/* Signal no yynewline on restoration */
    }
    PushMacro(NULL);
}

/***********************************************************************
 *				Scan_RestorePB
 ***********************************************************************
 * SYNOPSIS:	    Recover pushback characters from previous level
 * CALLED BY:	    Something after restoring yyinput
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Macro state is popped
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 1/89		Initial Revision
 *
 ***********************************************************************/
void
Scan_RestorePB(void)
{
    PopMacro();
}


/***********************************************************************
 *				stdinput
 ***********************************************************************
 * SYNOPSIS:	Standard input function to read from current macro
 *	    	or file.
 * CALLED BY:	input
 * RETURN:	character read
 * SIDE EFFECTS:curBlock, curMacCount, curMacPtr may change
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
 *	Else read a character from the input file. If the character is EOF,
 *	    return 0 (holdover from when this was done using lex)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 3/89		Initial Revision
 *
 ***********************************************************************/
static char
stdinput(void)
{
    int	c;

    if (curBlock != (MBlk *)NULL) {
	/*
	 * In a macro -- fetch the next character from the current block
	 */
	if (curMacCount == 0) {
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
		     * when in fact we need to pop another level. Nor can
		     * we just leave curMacCount <= 0 as something like
		     *
		     * DefDBGroup macro foo, biff
		     * DefDBGroup1 foo, %_curib_&foo
		     * endm
		     *
		     * will leave us with curMacCount == 0 before pushing
		     * to the new macro, as the newline will have been
		     * swallowed by the expression parser. Voice Of Experience
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
		 * character, since the popping could well have introduced
		 * some pushback characters.
		 */
		PopMacro();
		return(input());
	    }
	}
	/*
	 * Still in a macro -- predecrement the count of characters and
	 * return the next character in the macro
	 */
	inmacro = TRUE;
	curMacCount--;
	if (showmacro) {
	    putc(*curMacPtr, stderr);
	}
	return(*curMacPtr++);
    }

    inmacro = FALSE;

    if ((c = getc(yyin)) == EOF) {
	/*
	 * If hit end-of-file on the current input, return 0.
	 */
	return(0);
    } else {
	/*
	 * Filter out carriage returns here to make our life easier.
	 */
	while (c == '\r') {
	    if ((c = getc(yyin)) == EOF) {
		return(0);
	    }
	}
    }

    return(c);
}

/***********************************************************************
 *				input
 ***********************************************************************
 * SYNOPSIS:	  Read the next character of input
 * CALLED BY:	  yystdlex, yyreadmacro, yreadmacrobody, yyflush
 * RETURN:	  the next character or 0 if hit EOF
 * SIDE EFFECTS:  pushback pointer will be altered if char read from there
 *
 * STRATEGY:
 *	If any characters pushed back,
 *	    pop the stack and return the top character.
 *	Else call yyinput to fetch character
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/25/88		Initial Revision
 *
 ***********************************************************************/
static char
input(void)
{
	char ret;
	//do {
    if (yysptr > yysbot) {
			/*
			 * Stuff pushed back -- fetch the next character
			 */
			ret = (*--yysptr);
    } else {
			ret = (*yyinput)();
    }
	//} while(ret == '\r');
	return ret;
}


/***********************************************************************
 *				NextID
 ***********************************************************************
 * SYNOPSIS:	    Read the next identifier from the input stream,
 *	    	    pushing all the characters back.
 * CALLED BY:	    yymacarglex, yystdlex
 * RETURN:	    TRUE if next token is an identifier (identifier
 *	    	    is in yytext), else FALSE and yytext is unchanged.
 *
 *	    	    If pbPtr is non-NULL, yysptr before the identifer
 *	    	    was pushed back is stored there so the pushback
 *	    	    can be easily undone.
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 1/89		Initial Revision
 *
 ***********************************************************************/
static int
NextID(char **pbPtr)	    /* Place to store original pushback pointer
			     * if the next token is indeed an identifier */
{
    char    *cp;
    int     c;
    int	    pushspace = 0; /* Non-zero if should push back
			    * a single space when done. */
    int	    retval = TRUE;

    while ((c = input()) == ' ' || c == '\t') {
	pushspace = 1;
    }

    if (isfirstid(c)) {
	/*
	 * Scan off the ID, then put the characters back
	 * into the input stream
	 */
	cp = yytext;
	*cp++ = c;
	while(isotherid(c = input())) {
	    *cp++ = c;
	}
	if (pbPtr) {
	    *pbPtr = yysptr;
	}

	unput(c);
	*cp = '\0';
	while (--cp >= yytext) {
	    unput(*cp);
	}
    } else {
	/*
	 * Put the character back again.
	 */
	unput(c);
	retval = FALSE;
    }

    /*
     * If any space preceded first character read, put back one of them...
     * that's all we need to put back since whitespace is discarded normally
     * anyway. Only put back one in case we're called because of a STRING
     * symbol, where we might come back from the symbol's value and get
     * really screwed b/c we nuked the space that used to be there
     * to catch the end of things inside the string itself (like an
     * identifier).
     */
    if (pushspace) {
	unput(' ');
    }

    return(retval);
}

/*
 * Include the keyword table definitions.
 */
#define inline static
#define __inline /* nothing */
#undef __GNUC__

#include    "opcodes.h"
#undef MIN_WORD_LENGTH
#undef MAX_WORD_LENGTH
#undef MIN_HASH_VALUE
#undef MAX_HASH_VALUE
#undef TOTAL_KEYWORDS

#include    "flopcode.h"
#undef MIN_WORD_LENGTH
#undef MAX_WORD_LENGTH
#undef MIN_HASH_VALUE
#undef MAX_HASH_VALUE
#undef TOTAL_KEYWORDS

#include    "keywords.h"
#undef MIN_WORD_LENGTH
#undef MAX_WORD_LENGTH
#undef MIN_HASH_VALUE
#undef MAX_HASH_VALUE
#undef TOTAL_KEYWORDS

#include    "class.h"
#undef MIN_WORD_LENGTH
#undef MAX_WORD_LENGTH
#undef MIN_HASH_VALUE
#undef MAX_HASH_VALUE
#undef TOTAL_KEYWORDS

#include    "segment.h"
#undef MIN_WORD_LENGTH
#undef MAX_WORD_LENGTH
#undef MIN_HASH_VALUE
#undef MAX_HASH_VALUE
#undef TOTAL_KEYWORDS

#include    "dword.h"
#undef MIN_WORD_LENGTH
#undef MAX_WORD_LENGTH
#undef MIN_HASH_VALUE
#undef MAX_HASH_VALUE
#undef TOTAL_KEYWORDS

#include    "model.h"
#undef MIN_WORD_LENGTH
#undef MAX_WORD_LENGTH
#undef MIN_HASH_VALUE
#undef MAX_HASH_VALUE
#undef TOTAL_KEYWORDS

#undef inline
#undef __inline

/*
 * Stack of opcode-search functions to try. Certain contexts require special
 * keywords to be recognized, keywords we don't want known in any other
 * context.
 */
#define MAX_OP_FUNCS	16
static OpProc 	*opFuncs[MAX_OP_FUNCS];
static int  	opfTop = -1;


/***********************************************************************
 *				Scan_UseOpProc
 ***********************************************************************
 * SYNOPSIS:	    Register another opcode-search function to be used
 *	    	    when checking out an identifier.
 * CALLED BY:	    yystdlex and yyparse
 * RETURN:	    Index of entry (for removal)
 * SIDE EFFECTS:    opfTop is incremented...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/18/89		Initial Revision
 *
 ***********************************************************************/
int
Scan_UseOpProc(OpProc	*proc)
{
    assert(opfTop != MAX_OP_FUNCS);
    opFuncs[++opfTop] = proc;
    return(opfTop);
}

/***********************************************************************
 *				Scan_DontUseOpProc
 ***********************************************************************
 * SYNOPSIS:	    Stop searching for opcodes with a procedure
 * CALLED BY:	    yystdlex and yyparse
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/18/89		Initial Revision
 *
 ***********************************************************************/
void
Scan_DontUseOpProc(int	idx)
{
    if (idx != opfTop) {
	/*
	 * Need to shift the other functions down.
	 */
	int i;
	for (i = idx; i < opfTop; i++) {
	    opFuncs[i] = opFuncs[i+1];
	}
    }
    opfTop -= 1;
}


/***********************************************************************
 *				isReserved
 ***********************************************************************
 * SYNOPSIS:	  See if a string is a reserved word
 * CALLED BY:	  yylex
 * RETURN:	  the OpCode pointer or NULL if not a reserved word
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *	Downcase the word and call findOpcode and/or findKeyword, depending
 *	on tryOpcode.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 1/89		Initial Revision
 *
 ***********************************************************************/
static inline const OpCode *
isReserved(char *str,		/* String to look up */
	   int len)		/* Length of same */
{
    char    	    buf[12]; 	/* Storage for downcased word */
    char    	    *cp;    	/* Pointer into buf */
    const OpCode    *result;
    int	    	    i;

    if (len > sizeof(buf)-1) {
	/*
	 * If longer than the longest opcode, don't even bother...
	 */
	return(NULL);
    }

    /*
     * Else downcase the whole word (our tables are all in lowercase and
     * MASM is case-insensitive).
     */
    cp = buf;

    do {
	if (isupper(*str)) {
	    *cp++ = tolower(*str++);
	} else {
	    *cp++ = *str++;
	}
    } while (*str != '\0');

    *cp = '\0';

    /*
     * Try the registered opcode-finding procedures first.
     */
    for (result = NULL, i = opfTop; i >= 0 && result == NULL; i--) {
	result = (*opFuncs[i])(buf, len);
    }

    /*
     * If unsuccessful, try findKeyword.
     */
    if (result == NULL) {
	result = findKeyword(buf, len);
    }
    return(result);
}


/***********************************************************************
 *				newstr
 ***********************************************************************
 * SYNOPSIS:	  Create a copy of the given string
 * CALLED BY:	  yylex for IDENT and STRING
 * RETURN:	  a newly-allocate copy of the given string
 * SIDE EFFECTS:  Memory be allocated
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 6/88		Initial Revision
 *
 ***********************************************************************/
static inline char *
newstr(char *str)
{
    return ((char *)strcpy((char *)malloc(strlen(str)+1), str));
}


/***********************************************************************
 *				ScanEquateToString
 ***********************************************************************
 * SYNOPSIS:	    Convert a SYM_STRING to a real string
 * CALLED BY:	    yymacarglex (% of equate), yystdlex (ifidn, ifdif)
 * RETURN:	    The converted string, dynamically allocated
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 6/89		Initial Revision
 *
 ***********************************************************************/
static char *
ScanEquateToString(SymbolPtr	sym)
{
    int 	len;	    /* Length of string being returned */
    char	*cp;	    /* Position in return value */
    MBlk	*mp;	    /* Current chunk of string */
    char    	*retval;    /* Value being returned */

    len = 1;
    for (mp = sym->u.string.value; mp != NULL; mp = mp->next) {
	len += mp->length;
    }
    cp = retval = (char *)malloc(len);

    for (mp = sym->u.string.value; mp != NULL; mp = mp->next) {
	bcopy(mp->text, cp, mp->length);
	cp += mp->length;
    }
    *cp = '\0';

    return(retval);
}


/***********************************************************************
 *				yymacarglex
 ***********************************************************************
 * SYNOPSIS:	    Scan off another macro argument
 * CALLED BY:	    yyparse
 * RETURN:	    STRING or '\n' or '%'
 * SIDE EFFECTS:    firstArg set FALSE. If '%' or '\n' seen, yylex is
 *	    	    set to yystdlex.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 3/89		Initial Revision
 *
 ***********************************************************************/
int
yymacarglex(YYSTYPE *yylval, ...)
{
    register int  c;
    register char *cp;

    if (bumpLine) {
	yynewline();
    }

    /*
     * Skip initial whitespace (including \r)
     */
again:
    while(isspace(c = input()) && (c != '\n')) {
	dotid = TRUE;
    }

    /*
     * Fetching macro arguments.
     */
    switch (c) {
    case '%':
    {
	/*
	 * If the token begins with %, the arg is to be evaluated, so turn
	 * symbol translation back on again and revert to the standard lex
	 * function. The parser will change back when appropriate.
	 *
	 * Have to treat %string_equate specially, however, as we don't want
	 * to interpolate the value of the equate arbitrarily, but rather
	 * want the value of the equate as the macro argument...
	 */
	char	*pb;	/* Pushback in case we need to consume the ID */

	if (NextID(&pb)) {
	    SymbolPtr	sym;

	    sym = Sym_Find(ST_EnterNoLen(output, symStrings, yytext),
			   SYM_ANY, FALSE);
	    if (sym && sym->type == SYM_STRING) {
		/*
		 * Consume the identifier, then merge the string value
		 * into a single string that we can then return.
		 */
		yysptr = pb+1;	/* Leave first non-id character */
		yylval->string = ScanEquateToString(sym);
		DBPRINTF((stderr, "returning macarg(%s) from equate\n",
			  yylval->string));
		commaMeansEmpty = FALSE;
		return(MACARG);
	    }
	}
	/*
	 * Not an ID or not a STRING symbol, so switch to regular parsing
	 */
	firstArg = FALSE;
	noSymTrans = FALSE;
	commaMeansEmpty = FALSE;
	yylex = yystdlex;
	return (c);
    }
    case ';':
	DBPRINTF((stderr,"skipping comment..."));
	while(((c = input()) != '\n') && (c != 0)) {
	    /*
	     * Handle continuation at end of comment by going back to get
	     * another token w/o returning the newline.
	     */
	    if (c == '\\') {
		if ((c = input()) == '\n') {
		    dotid = TRUE;
		    if (curBlock == (MBlk *)NULL) {
			yynewline();
		    }
		    goto again;
		} else if (c == 0) {
		    break;
		}
		/*
		 * Anything else may safely be discarded.
		 */
	    }
	}
	if ((c == 0) && !yywrap()) {
	    /*
	     * If hit end-of-file but should keep going, do so by returning
	     * a newline instead of eof (else we'll get a parse error,
	     * guaranteed).
	     */
	    DBPRINTF((stderr,"Hit end-of-file but continuing\n"));
	    c = '\n';
	}
	/*FALLTHRU*/
    case '|':
	/*
	 * To allow multiple statements on a single line, we treat | as
	 * a newline character. This keeps the parser from being confused...
	 * Do not transform | to \n, however, or we'll incorrectly up the
	 * line number next time...
	 */
    case '\n':
	/*
	 * NOTE: Don't have to deal with commaMeansEmpty as the empty
	 * argument is implied by the lack of any more arguments, if you see
	 * what I mean.
	 */
newline_thing:
	dotid = TRUE;
	noSymTrans = FALSE;
	commaMeansEmpty = FALSE;
	if (!inmacro && c == '\n') {
	    bumpLine = 1;
	}
	DBPRINTF((stderr,"returning '\\n' (bumpLine = %d)\n", bumpLine));
	yylex = yystdlex;
	return(c == '|' ? '\n' : c);
    case ',':
	/*
	 * Macro arg separator -- don't return it (since macro args can
	 * also be separated by white-space and we won't return a comma
	 * in that case), just fetch the next token.
	 */
	if (commaMeansEmpty) {
	    /*
	     * We haven't seen an argument since the last one, so return
	     * an empty string, discarding the comma but leaving
	     * commaMeansEmpty set, since it does.
	     */
	    DBPRINTF((stderr,"commaMeansEmpty, so returning macarg()\n"));
	    yylval->string = (char *)malloc(1);
	    yylval->string[0] = '\0';
	    return(MACARG);
	} else {
	    commaMeansEmpty = TRUE;
	    goto again;
	}
    case '<':
	commaMeansEmpty = FALSE;
	firstArg = FALSE;
	return yyreadstring('<', '>', 0, yylval) ? MACARG : 0;
    case '\'': case '"':
    {
	/*
	 * This is different from a regular string in that we must
	 * return the thing with the quotation marks intact (so it's
	 * recognized as a string when substituted).
	 */
	int c2;

	DBPRINTF((stderr,"entering %c%c string literal...", c, c));
	cp = yytext;
	*cp++ = c;
	while(1) {
	    c2 = input();
	    if (c2 == 0) {
		yyerror("end-of-file in string constant");
		return(0);
	    } else if (c2 == c) {
		c2 = input();
		if (c2 != c) {
		    unput(c2);
		    *cp++ = c;
		    break;
		}
	    } else if (c2 == '\n') {
		unput(c2);
		break;
	    }
	    *cp++ = c2;
	}
	*cp++ = '\0';
	yylval->string = (char *)malloc(cp - yytext);
	strcpy(yylval->string, yytext);
	DBPRINTF((stderr,"returning macarg(%s)\n", yylval->string));
	firstArg = FALSE;
	commaMeansEmpty = FALSE;
	return(MACARG);
    }
    case '\0':
	/*
	 * Shouldn't happen (especially if you use emacs), but if we don't
	 * handle it, we go into an infinite loop allocating butt-loads
	 * of memory before dying.
	 */
	commaMeansEmpty = FALSE;
	yylex = yystdlex;
	yyerror("end-of-file in macro arguments");
	dotid = TRUE;
	DBPRINTF((stderr,"end-of-file..."));
	c = '\n';
	goto newline_thing;
    case '\\':
	/*
	 * Handle continuation lines -- if backslash followed by newline,
	 * go back for another token, not returning the newline to the
	 * parser.
	 */
	if ((c = input()) == '\n') {
	    dotid = TRUE;
	    if (!inmacro) {
		/*
		 * Bump line counter if not in macro
		 */
		yynewline();
	    }
	    goto again;
	} else {
	    /*
	     * Anything else and we return the backslash unharmed, placing it
	     * at the start of the macro argument.
	     */
	    unput(c);
	    c = '\\';
	}
    default:
	/*
	 * Ordinary word...
	 */
	cp = yytext;
	do {
	    *cp++ = c;
	    c = input();
	} while (!isterm(c));
	*cp++ = '\0';
	unput(c);

	/*
	 * Make sure this isn't just a macro re-definition. If it's the
	 * first argument and it's "macro", it is a re-definition.
	 */
	if (firstArg && ustrcmp(yytext, "macro") == 0) {
	    /*
	     * Read in the new definition
	     */
	    yyreadmacro(yylval);
	    yylex = yystdlex;
	    DBPRINTF((stderr,"returning MACRO\n"));
	    return(MACRO);
	}

	commaMeansEmpty = FALSE;
	firstArg = FALSE;

	/*
	 * Copy the arg to non-volatile memory and return a MACARG
	 * token.
	 */
	yylval->string = (char *)malloc(cp - yytext);
	strcpy(yylval->string, yytext);
	DBPRINTF((stderr,"returning macarg(%s)\n", yylval->string));
	return(MACARG);
    }
}

/***********************************************************************
 *				ScanEquate
 ***********************************************************************
 * SYNOPSIS:	    Scan off an equate of some sort
 * CALLED BY:	    yystdlex
 * RETURN:	    Nothing
 * SIDE EFFECTS:    yylval->block points to the head of the MBlk chain
 *	    	    scanned off (if string equate).
 *
 * STRATEGY:
 *      There are two types of equates in this system: numeric and string.
 *	A string equate is created by one of
 *      the following:
 *       	equ <string>
 *       	equ 'string'
 *       	equ "string"
 *      in any of these cases, the string is scanned off into a
 *      chain of MBlk's and interpolated into the input by us
 *      at a later time. For '' and "" strings, the delimiters
 *      remain in the text. For <> strings, however, the angle-
 *      brackets are stripped. This is used to create simple
 *      text aliases. If the first non-whitespace character after
 *      the EQU isn't ', " or <, the equate is assumed numeric, the
 *      character pushed back into the input stream and the parser
 *      is left to figure out the value.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 5/89		Initial Revision
 *
 ***********************************************************************/
static void
ScanEquate(YYSTYPE  *yylval)
{
    char    quote;
    MBlk    *head;
    MBlk    *tail;
    char    *cp;
    int      c;

    /*
     * Skip leading white-space
     */
    while ((c  = input()) == ' ' || c == '\t') {
	;
    }
    if (iseol(c)) {
	yyerror("No value given for EQU directive");
	return;
    }

    if ((c != '<') && (c != '\'') && (c != '"')) {
	DBPRINTF((stderr,"Beginning numeric equate\n"));
	unput(c);
	return;
    }

    DBPRINTF((stderr,"Beginning %c string equate\n", c));

    tail = head = NewBlock();

    cp = head->text;

    quote = c;

    if ((quote == '\'') || (quote == '"')) {
	*cp++ = quote;
	tail->length++;

	while(1) {
	    while(((c = input()) != quote) && !iseol(c)) {
		if (tail->length == MACRO_BLOCK_SIZE) {
		    tail->next = NewBlock();
		    tail = tail->next;
		    cp = tail->text;
		}
		*cp++ = c;
		tail->length++;
	    }
	    if (iseol(c)) {
		/*
		 * Ick. No trailing mark seen -- complain
		 * bitterly and put the newline back
		 */
		yyerror("Unterminated %c constant", quote);
		unput(c);
		break;
	    } else if ((c = input()) != quote) {
		/*
		 * Add the trailing quotation mark
		 */
		if (tail->length == MACRO_BLOCK_SIZE) {
		    tail->next = NewBlock();
		    tail = tail->next;
		    cp = tail->text;
		}
		*cp++ = quote;
		tail->length++;
		unput(c);
		break;
	    } else {
		/*
		 * Put in a doubled delimiter for later
		 * consumption.
		 */
		if (tail->length == MACRO_BLOCK_SIZE) {
		    tail->next = NewBlock();
		    tail = tail->next;
		    cp = tail->text;
		}
		*cp++ = quote;
		tail->length++;
		if (tail->length == MACRO_BLOCK_SIZE) {
		    tail->next = NewBlock();
		    tail = tail->next;
		    cp = tail->text;
		}
		*cp++ = quote;
		tail->length++;
	    }
	}
    } else {
	/*
	 * Scan off a literal string, but discard the brackets. Match brackets,
	 * though...
	 */
	int 	level = 0;
	int 	close = 0;

	while (((c = input()) != 0) && !iseol(c)) {
	    if (c == '<' && !close) {
		level++;
	    } else if (c == '>' && !close) {
		if (level-- == 0) {
		    break;
		}
	    } else if (c == '\'' || c == '"') {
		/*
		 * If we're looking for a close quote and this is it, just
		 * reset "close" to 0. If it's a duplicate that's to be one,
		 * we'll just re-open the case when the duplicate comes in
		 * next, and no-one will be the wiser.
		 */
		if (c == close) {
		    close = 0;
		} else if (!close) {
		    close = c;
		}
	    }

	    if (tail->length == MACRO_BLOCK_SIZE) {
		tail->next = NewBlock();
		tail = tail->next;
		cp = tail->text;
	    }
	    /*
	     * Deal with escaped line-terminators by stuffing a newline into
	     * the resulting string equate. Makes some lives a good deal
	     * simpler...anything else following a backslash gets put in
	     * literally. Also allow right-angle bracket to be escaped, what
	     * the hell. -- ardeb 2/21/92
	     */
	    if (c == '\\') {
		c = input();
		if (iseol(c)) {
		    if (!inmacro) {
			yynewline();
		    }
		} else if (c != '>') {
		    unput(c);
		    c = '\\';
		}
	    }
	    *cp++ = c;
	    tail->length++;
	}
	if (c != '>') {
	    yyerror("Unterminated <> constant");
	    unput(c);
	}
    }

    yylval->block = head;
}

/***********************************************************************
 *				ScanComment
 ***********************************************************************
 * SYNOPSIS:	    Skip over a COMMENT block.
 * CALLED BY:	    yystdlex, Scan_ToEndif
 * RETURN:	    Nothing
 * SIDE EFFECTS:    input stream is left at the line terminator after the
 *		    closing delimiter.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 4/89	Initial Revision
 *
 ***********************************************************************/
static void
ScanComment(void)
{
    /*
     * COMMENT<space><delimiter>...<delimiter>.*$
     *
     * Find the delimiter, skip characters until we get to the
     * next occurence of it, then skip the rest of the characters
     * on that line and go back and fetch another token.
     */
    char    delim;
    int     c;

    DBPRINTF((stderr,"Skipping comment block\n"));
    while((c = input()) == ' ' || c == '\t') {
	;
    }
    if (iseol(c)) {
	yyerror("Missing delimiter for COMMENT");
	unput(c);
	return;
    }
    delim = c;
    if (!inmacro && yysptr == yysbot && yyinput == stdinput) {
	/*
	 * Optimized scanning when comment block is in a regular file with
	 * no input pushed back.
	 */
	while (((c = getc(yyin)) != delim) && (c != EOF)) {
      while(c == '\r') {
        c = getc(yyin);
      }
	    if (c == '\n') {
		yynewline();
	    }
	}
    } else {
	/*
	 * Skip to next occurrence of delimiter
	 */
	while(((c = input()) != delim) && (c != 0)) {
      while(c == '\r') {
        c = input();
        if(c == 0) {
          break;
        }
      }
	    if ((c == '\n') && !inmacro) {
		yynewline();
	    }
	}
    }
    /*
     * Skip rest of text on that line
     */
    while(!iseol(c = input()) && (c != 0)) {
	;
    }
    unput(c);
}

/***********************************************************************
 *				ScanInclude
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
ScanInclude(void)
{
    File	*f;		/* New File structure */
    char    	c;		/* Input character */
    char    	*cp;		/* Pointer into yytext */
    FILE    	*newin;	    	/* New input file */

    /*
     * Skip to filename
     */
    while ((c = input()) == ' ' || c == '\t') {
	;
    }
    /*
     * Copy it into yytext
     */
    cp = yytext;
    *cp++ = c;
    while(!isspace(c = input()) && (c != 0) && (c != ';')) {
	*cp++ = c;
    }
    unput(c);
    *cp++ = '\0';

    if (!ignore) {
	/*
	 * INCLUDE should actually be taken. Allocate a new File structure
	 * and locate the file itself.
	 */
	char	*path;
	char    *suffixcp;		/* Pointer into yytext */

	f = (File *)malloc(sizeof(File));

#ifdef _MSDOS
	/*
	 * Special case .RDEF files for the PC SDK.
	 * Look for FOO.RDF file instead of FOO.RDEF
	 */

	suffixcp = yytext + strlen(yytext) - 5;

	if (ustrcmp(suffixcp, ".rdef") == 0) {
	    suffixcp += 3;
	    *suffixcp++ = 'f';
	    *suffixcp = '\0';   /* change to .RDF */
	}
	/*
	 * Truncate file names to 8 characters for the PC SDK.
	 * For example: 123456789012.asm -> 12345678.asm
	 */
	char    *frontOfName;  /* pointer to front of the file name */
	char    *endOfName;    /* pointer to right after the end of the
				  file name. (without the extension) */

	/*
	 * Find the front of the filename by searching backwards in the
	 * string for a '/' or a '\'. If neither characters are in the
	 * string, it means that the string does not contain a path to
	 * the filename so the front of the file name is the front of
	 * the string.
	 *
	 * NOTE: This does not deal with mixed '/' and '\' in the path
	 *       correctly.
	 *
	 * In order to deal correctly with cases where there are both
	 * '/' and '\' in the file name path, we would need to check for
	 * the '/' and '\' characters independently and then see which
	 * one was last.
	 */
	if (((frontOfName = strrchr(yytext, '\\')) != NULL) ||
	    ((frontOfName = strrchr(yytext, '/')) != NULL)) {
	    frontOfName++;   /* move pointer to front of file name */
	}
	else {
	    frontOfName = yytext;  /* no path to file name */
	}

	/*
	 * Find the end of the filename by searching backwards in the
	 * string for a '.'. If no '.' is in the name, it means that
	 * the file name does not have an extension.
	 */
        if ((endOfName = strrchr(frontOfName, '.')) == NULL) {
	    /* no .extension so point to right after the last character */
	    endOfName = frontOfName + strlen(frontOfName);
	}

        /*
	 * Check if the file name if longer than 8 characters.
	 * If it is, truncate the file name to 8 characters.
	 */
        if ((endOfName - frontOfName) > 8) {
	    strcpy((frontOfName + 8), endOfName);
	}

	/* upcase everything for the PC */
	while(*frontOfName)
	{
	    if(islower(*frontOfName)) {
		*frontOfName = toupper(*frontOfName);
	    }
	    frontOfName++;
	}
#endif  /* _msdos */

	path = FindFile(yytext);

	if (path == (char *)NULL) {
	    if (makeDepend) {
		/*
		 * If generating dependencies, warn about the
		 * absence of the file, but add it to the list
		 * anyway. This is to handle catch-22 cases
		 * where a header is produced because someone
		 * depends on it...
		 */
		Notify(NOTIFY_WARNING, curFile->name, yylineno,
			"Couldn't find include file %s\n", yytext);
		printf("%s : %s\n", dependFile, yytext);
		fflush(stdout);
	    } else {
		yyerror("Couldn't find include file %s\n", yytext);
	    }
	    free((char *)f);
	    return;
	} else if (makeDepend) {
	    /*
	     * Print name of file being included since we found it. Note
	     * absence of full path! Only works for pmake...
	     */
	    printf("%s : %s\n", dependFile, yytext);
	    fflush(stdout);
	}

	DBPRINTF((stderr,"INCLUDE %s\n", path));

	newin = fopen(path, "r");

	if (newin == NULL) {
	    yyerror("Couldn't open include file %s\n", path);
	    free((char *)f);
	    free(path);
	    return;
	}

	/*
	 * Enter the path into the permanent string table for use by various
	 * things
	 */
	f->name = ST_EnterNoLen(output, permStrings, path);

	/*
	 * Preserve current state
	 */
	curFile->line = yylineno;
	curFile->file = yyin;
	PushMacro((MBlk *)NULL);

	/*
	 * Set up for new file
	 */
	yylineno = 1;
	f->next = curFile;
	f->chunk = curChunk;
	f->iflevel = iflevel;
	yyin = newin;
	curFile = f;

	Parse_FileChange(TRUE);
    }
}

/***********************************************************************
 *				ScanStruct
 ***********************************************************************
 * SYNOPSIS:	    Read a structured-type initializer
 * CALLED BY:	    yylex (< if defStruct set)
 * RETURN:	    Token to return
 * SIDE EFFECTS:    yylval->string is set to the string read, dynamically
 *	    	    allocated.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/31/89		Initial Revision
 *
 ***********************************************************************/
static int
ScanStruct(YYSTYPE *yylval)	/* Place to store result */
{
    int  	c;
    char	*base = yytext;
    int 	size = sizeof(yytext);
    char    	*cp;
    int	    	level = 0;
    int	    	start = yylineno;
    char    	close = 0;  	/* close quote being sought */

    DBPRINTF((stderr,"reading structured initializer..."));
    cp = base;
    while(1) {
	c = input();
	switch(c) {
	case 0:
	    yyerror("end-of-file in initializer (began on line %d)\n", start);
	    return(0);
	case '<':
	    /*
	     * Open character -- up the nesting level
	     */
	    if (!close) {
		level++;
	    }
	    break;
	case '\r':
	    /*
	     * Discard carriage returns completely.
	     */
	    continue;
	case '\n':
	    /*
	     * Just discard any newlines we see, after upping the current
	     * line number of course.
	     */
	    if (close) {
		yywarning("%c-terminated string constant terminated by newline",
			  close);
		c = close;
		close = 0;
		if (!inmacro) {
		    yynewline();
		}
		break;
	    } else {
		if (!inmacro) {
		    yynewline();
		}
		continue;
	    }
	case '>':
	    if (!close) {
		if (--level < 0) {
		    /*
		     * Close on bottom level -- get out of here.
		     */
		    goto complete;
		}
	    }
	    break;
	case '\'':
	case '"':
	    /*
	     * If we're looking for a close quote and this is it, just
	     * reset "close" to 0. If it's a duplicate that's to be one, we'll
	     * just re-open the case when the duplicate comes in next, and
	     * no-one will be the wiser.
	     */
	    if (c == close) {
		close = 0;
	    } else if (!close) {
		close = c;
	    }
	    break;
	case '\\':
	    /*
	     * Handle C-style escape sequences. First stick the backslash in
	     * the initializer.
	     */
	    *cp++ = c;

	    if (cp == base+size) {
		/*
		 * Extend buffer as needed.
		 */
		if (base == yytext) {
		    base = (char *)malloc(size*2);
		    bcopy(yytext, base, sizeof(yytext));
		} else {
		    base = (char *)realloc(base, size*2);
		}
		cp = base + size;
		size *= 2;
	    }

	    /*
	     * Now fetch the next char
	     */
	    c = input();

	    if (!close && !level && c == '>') {
		/*
		 * Not inside a string or a nested initializer and we've
		 * encountered an escaped close angle -- swallow the backslash
		 * but include the close-angle in the string.
		 */
		cp--;
	    } else if (c == '\n') {
		/*
		 * Swallow both the \ and the newline when newline is escaped
		 * like this.
		 */
		cp--;
		c = input();
		if (!inmacro) {
		    yynewline();
		}
		continue;
	    } else {
		/*
		 * XXX: take this out once everything assembles correctly
		 */
		yywarning("not molesting \\%c escape inside structure initializer; is this what you expect?",
			  c);
	    }
	    break;
	case ';':
	    /*
	     * Comment -- Skip to the end of the line.
	     */
	    if (!close) {
		while ((c = input()) != '\n' && c != 0) {
		    ;
		}
		unput(c);
		continue;
	    } else {
		break;
	    }
	} /* switch */

	*cp++ = c;

	if (cp == base+size) {
	    /*
	     * Extend buffer as needed.
	     */
	    if (base == yytext) {
		base = (char *)malloc(size*2);
		bcopy(yytext, base, sizeof(yytext));
	    } else {
		base = (char *)realloc(base, size*2);
	    }
	    cp = base + size;
	    size *= 2;
	}
    }
 complete:

    DBPRINTF((stderr,"done\n"));

    *cp++ = '\0';

    if (base == yytext) {
	/*
	 * Copy to non-volatile storage now we know how big it is.
	 */
	base = (char *)malloc(cp - yytext);
	bcopy(yytext, base, cp-yytext);
    }

    yylval->string = base;

    DBPRINTF((stderr,"returning structure init %s\n", yylval->string));
    return(STRUCT_INIT);
}

/***********************************************************************
 *				yystdlex
 ***********************************************************************
 * SYNOPSIS:	  Scan a token out of the input stream and return it.
 * CALLED BY:	  yyparse, SkipToEndif (parse.c)
 * RETURN:	  the token and yylval set appropriately.
 * SIDE EFFECTS:  input is taken from the input stream.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 2/88		Initial Revision
 *
 ***********************************************************************/
int
yystdlex(YYSTYPE *yylval, ...)
{
    register int  c;
    register char *cp;

    /*
     * Deal with delayed newline crap.
     */
    if (bumpLine) {
	yynewline();
    }

    /*
     * Skip initial whitespace (including carriage returns)
     */
again:
    while(isspace(c = input()) && (c != '\n')) {
	dotid = TRUE;
    }

    if (snarfLine) {
	/*
	 * Put initial character back so yyreadstring gets it.
	 */
	unput(c);
	snarfLine = 0;
	return yyreadstring(0, '\n', 0, yylval);
    }
    /*
     * Fetching a regular token. Decide what to do based on the first char.
     */
    switch(c) {
    case '&':
	/*
	 * '&' characters are ignored completely. This allows for the MASM
	 * string equate substitution semantics:
	 *  % equate_name&biffy	...
	 * to work without error.
	 */
	goto again;
    case '\\':
	/*
	 * Handle continuation lines -- if backslash followed by newline,
	 * go back for another token, not returning the newline to the
	 * parser.
	 */
	if ((c = input()) == '\n') {
	    dotid = TRUE;
	    if (!inmacro) {
		/*
		 * Bump line counter if not in macro
		 */
		yynewline();
	    }
	    goto again;
	} else {
	    /*
	     * Anything else and we tell the user the backslash is unwanted
	     * and will be ignored.
	     */
	    unput(c);
	    if (!ignore) {
		/*
		 * SOME people (who shall remain nameless) like to put weird
		 * things inside
		 *
		 * if 0
		 * endif
		 *
		 * blocks. Rather than annoy them, we don't notify the
		 * user of discarded weird characters if we're in the
		 * middle of a false conditional.
		 */
		yyerror("Extraneous character 0x%02.2x discarded", c);
	    }
	    goto again;
	}
    case '%':
	if ((c = input()) == 'O' || (c == 'o')) {
	    int	savec = c;
	    if ((c = input()) == 'U' || (c == 'u')) {
		int savec = c;
		if ((c = input()) == 'T' || (c == 't')) {
		    int savec = c;
		    if (isspace(c = input())) {
/* XXX: Doesn't handle string equates */
			yyreadstring(0, '\n', 0, yylval);
			return(PCTOUT);
		    } else {
			unput(c);
		    }
		    unput(savec);
		}
		unput(savec);
	    }
	    unput(savec);
	} else {
	    unput(c);
	}
	c = '%';
	goto return_c;
    case '.':
	if (dotid) {
	    goto do_id;
	} else {
	    /*
	     * Handle special dword-part operators (.segment, .chunk, etc.)
	     */
	    const   OpCode  *opp;

	    cp = yytext;
	    *cp++ = c;
	    while (isotherid(c = input())) {
		*cp++ = c;
	    }
	    unput(c);
	    *cp = '\0';
	    opp = isDWordPart(yytext, cp-yytext);
	    if (opp != NULL) {
		return(opp->token);
	    } else {
		/*
		 * Push back the chars we read and just return a '.'
		 */
		while (--cp > yytext) {
		    unput(*cp);
		}
		c = '.';
	    }
	}
	/*FALLTHRU*/
    case '+':
    case '-':
    case '/':
    case '*':
    case ':':
    case '=':
    case '(':
    case ')':
    case '[':
    case ']':
    case '{':
    case '}':
    case ',':
	/*
	 * Operator character -- return it. To support the structure
	 * operator in such expressions as "[bx].field", we don't allow
	 * periods to begin an id after a closing square brace.
	 */
return_c:
	DBPRINTF((stderr,"returning '%c'\n", c));
	dotid = (c != ']' && c != ')');
	return(c);
    case 0:
	/*
	 * End of file. Try and wrap it up. If yywrap says no, go fetch
	 * another token.
	 */
	dotid = TRUE;
	DBPRINTF((stderr,"end-of-file..."));
	if (!yywrap()) {
	    DBPRINTF((stderr,"continuing\n"));
	    return(yylex(yylval));
	} else {
	    DBPRINTF((stderr,"all done\n"));
	    return 0;
	}
    case ';':
	/*
	 * Single-line comment -- read until get a newline or EOF
	 */
skip_comment:
	DBPRINTF((stderr,"skipping comment..."));

	if (!inmacro && yysptr == yysbot && yyinput == stdinput) {
	    /*
	     * Optimized comment scanner when input coming from a file --
	     * just use normally-inlined getc() macro to avoid layering
	     * of normal input function.
	     */
	    while (((c = getc(yyin)) != EOF) && !iseol(c)) {
				if (c == '\\') {
					if ((c = getc(yyin)) && iseol(c)) {
						/*
						 * Continuation at end of comment by going back to
						 * get another token w/o returning the newline.
						 */
						 while(c == '\r') {
							 c = getc(yyin);
						 }
						 dotid = TRUE;
						 yynewline();
						 goto again;
					 } else if (c == EOF) {
						 break;
					 }
				 }
	    }
			while(c == '\r') {
				c = getc(yyin);
			}
	    if (c == EOF) {
				c = 0;
			}
		} else {
	    while(!iseol(c = input()) && (c != 0)) {
				/*
				* Handle continuation at end of comment by going back to get
				* another token w/o returning the newline.
				*/
				if (c == '\\') {
		    	if ((c = input()) && iseol(c)) {
						while(c == '\r') {
							c = getc(yyin);
						}
						dotid = TRUE;
						if (!inmacro) {
							yynewline();
						}
						goto again;
		    	} else if (c == 0) {
						break;
					}
					/*
					 * Anything else may safely be discarded.
					 */
			 }
		}
	}
	if ((c == 0) && !yywrap()) {
	    /*
	     * If hit end-of-file but should keep going, do so.
	     */
	    DBPRINTF((stderr,"Hit end-of-file but continuing\n"));
	    return(yylex(yylval));
	}
	/*FALLTHRU*/
    case '|':
	/*
	 * To allow multiple statements on a single line, we treat | as
	 * a newline character. This keeps the parser from being confused...
	 * Do not transform | to \n, however, or we'll incorrectly up the
	 * line number next time...
	 */
    case '\n':
newline_thing:
	dotid = TRUE;
	noEquate = noSymTrans = FALSE;
	if (!inmacro && c == '\n') {
	    bumpLine = 1;
	}
	DBPRINTF((stderr,"returning '\\n' (bumpLine=%d)\n", bumpLine));
	return(c == '|' ? '\n' : c);
    case '<':
	return defStruct ? ScanStruct(yylval) : yyreadstring('<', '>', 0, yylval);
    case '\'':
	return yyreadstring(0, '\'', '\'', yylval);
    case '"':
	return yyreadstring(0, '"', '"', yylval);
    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9':
    {
	/*
	 * Constant -- figure out the radix (can be specified either masm's
	 * way or C's way) and convert to an integer, returning that
	 * integer and CONSTANT.
	 */
	int	base = 10, baseSet = 0;
	long 	n, d;

	if (c == '0') {
	    c = input();
	    if ((c == 'x') || (c == 'X')) {
		baseSet = base = 16;
		c = input();
	    } else {
		/*
		 * Assume base 8 unless overridden by a suffix character.
		 * Note for this reason we don't set "baseSet".
		 */
		base = 8;
	    }
	}
	cp = yytext;

	while(isxdigit(c)) {
	    *cp++ = c;
	    c = input();
	}

	DBPRINTF((stderr,"converting '%.*s'...", cp - yytext, yytext));
	if (!baseSet) {
	    switch(c) {
	    case 'h':
	    case 'H':
		/*
		 * Consume hex radix char and set the base properly
		 */
		baseSet = base = 16;
		break;
	    case 'Q':
	    case 'q':
	    case 'O':
	    case 'o':
		/*
		 * Consume octal radix char and set the base properly
		 */
		baseSet = base = 8;
		break;
	    default:
		/*
		 * Final char not part of the number -- put it back and
		 * look for binary or decimal radix char as trailer. They
		 * will be in the digits read as they are valid hex
		 * characters.
		 */
		unput(c);
		if (cp != yytext) {
		    cp--;
		    if ((*cp == 'B') || (*cp == 'b')) {
			base = 2;
		    } else if ((*cp == 'D') || (*cp == 'd')) {
			base = 10;
		    } else {
			/*
			 * Current radix -- we default to 10 for now.
			 */
			base = 10;
			cp++;
		    }
		}
		break;
	    }
	} else {
	    /*
	     * If base already determined, just put the non-hex character
	     * back again.
	     */
	    unput(c);
	}

	*cp++ = '\0';
	cp = yytext;
	n = 0;
	while (*cp != '\0') {
	    n *= base;

	    if (*cp <= '9') {
		d = *cp++ - '0';
	    } else if (*cp <= 'F') {
		d = *cp++ - 'A' + 10;
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
	yylval->number = n;
	DBPRINTF((stderr,"returning CONSTANT(%d)\n", yylval->number));
	dotid = TRUE;
	return(CONSTANT);
    }
    default: {
	const OpCode  *opp;

	if (!isfirstid(c)) {
	    if (!ignore) {
		/*
		 * SOME people (who shall remain nameless) like to put weird
		 * things inside
		 *
		 * if 0
		 * endif
		 *
		 * blocks. Rather than annoy them, we don't notify the
		 * user of discarded weird characters if we're in the
		 * middle of a false conditional.
		 */
		yyerror("Extraneous character 0x%02.2x discarded", c);
	    }
	    goto again;
	}
    do_id:
	dotid = FALSE;
	cp = yytext;

	*cp++ = c;
	while(isotherid(c = input())) {
	    *cp++ = c;
	}
	unput(c);
	*cp = '\0';

	opp = isReserved(yytext, cp - yytext);

	if ((opp != (const OpCode *)NULL) && !noSymTrans) {
	    /*
	     * First handle any special processing the opcode requires.
	     */
	    if (opp->token >= FIRSTOP && opp->token <= LASTOP) {
		yylval->opcode = opp;
	    } else {
		yylval->number = opp->value; /* Most things need this. */
	    }
	    switch(opp->token) {
	    case COMMENT:
		ScanComment();
		goto again;
	    case EQU:
		ScanEquate(yylval);
		break;
	    case EXITM:
		/*
		 * Exit the current macro call by popping the macro state (if
		 * any) and going back for another token.
		 */
		if (!ignore) {
		    DBPRINTF((stderr,"Exiting current macro\n"));
		    if (!inmacro) {
			yyerror("EXITM outside of macro call\n");
		    } else {
			/*
			 * Discard any pushback from after the EXITM before
			 * popping the macro state.
			 * NOTE: set iflevel only here, not in PopMacro, to
			 * deal with conditionals inside macro arguments,
			 * where the conditional is seen, iflevel is set,
			 * then the end of the argument is reached and iflevel
			 * gets reset by PopMacro, as was happening before.
			 * -- ardeb 3/18/92
			 */
			yysptr = yysbot;
			iflevel = macros->iflevel;
			PopMacro();
		    }
		}
		goto again;
	    case PUBLIC:
	    case GLOBAL:
		/*
		 * Don't do macros...
		 */
		ignore = TRUE;
		break;
	    case SUBSTR:
	    case CATSTR:
	    case SIZESTR:
	    case INSTR:
		/*
		 * All the string operators can take a string equate in
		 * place of a string. In fact, they need to else the user
		 * will get confused, since the equate doesn't have the
		 * bounding <>'s and won't be returned as a STRING otherwise...
		 */
		noEquate = TRUE;
		break;
	    case IFIDN:
	    case IFDIF:
	    case IFB:
	    case IFNB:
	    case ERRIDN:
	    case ERRDIF:
	    case ERRB:
	    case ERRNB:
		/*
		 * For the string-related conditionals, we need to allow
		 * a string equate to take the place of a <>-enclosed string
		 * as one of its arguments (it's just good sense...). To
		 * accomplish this, we set noEquate to TRUE so the handling
		 * of SYM_STRING below doesn't interpolate anything.
		 */
		noEquate = TRUE;
		break;
	    case IRP:
	    case IRPC:
	    case IFNDEF:
	    case IFDEF:
	    case ERRNDEF:
	    case ERRDEF:
		/*
		 * IFNDEF and IFDEF require that symbols not be
		 * translated since we don't want what it means but rather the
		 * identifier itself.
		 * IRP and IRPC essentially want just an identifier. Rather
		 * than write a rule to handle the use of any type of symbol,
		 * as we'd have to do if we left symbol translation on, we
		 * just turn it off for them and return the appropriate
		 * identifier.
		 */
		noSymTrans = TRUE;
		break;
	    case INCLUDE:
		ScanInclude();
		/*
		 * Fetch next token, either from new file or from old...
		 */
		goto again;
	    case MACRO:
		/*
		 * Read to the end of the definition -- yyreadmacro deals
		 * with "ignore" state.
		 */
		yyreadmacro(yylval);
		break;
	    case EXITF:
		/*
		 * Exit current input file -- get out of the current macro.
		 */
		while (curBlock != NULL) {
		    PopMacro();
		}
		iflevel = curFile->iflevel;
		if (yywrap()) {
		    return(0);
		} else {
		    return(yylex(yylval));
		}
	    } /* switch */
	    DBPRINTF((stderr,"Returning opcode %s\n", opp->name));
	    return(opp->token);
	} else if (!noSymTrans) {
	    Symbol  *sym;
	    ID	    id = ST_Enter(output, symStrings, yytext, cp - yytext);

	    sym = Sym_Find(id, SYM_ANY, FALSE);
	    if (sym != (Symbol *)NULL) {
		yylval->sym = sym;

		switch(sym->type) {
		case SYM_STRING:
		{
		    /*
		     * To handle the redefinition of string constants, we
		     * need to look ahead in the stream to see if the next
		     * token might be EQU. If it is, we push the token back
		     * and just return a SYM token. Else we push to the
		     * constant's value and start over.
		     */
		    if (noEquate) {
			yylval->string = ScanEquateToString(sym);
			DBPRINTF((stderr,"Returning string from %i <%s>\n",
				  sym->name, yylval->string));
			return(STRING);
		    } else if (NextID(NULL) &&
			       ((ustrcmp(yytext, "equ") == 0) ||
				(ustrcmp(yytext, "catstr") == 0) ||
				(ustrcmp(yytext, "substr") == 0)))
		    {
			/*
			 * Followed by EQU, CATSTR or SUBSTR -- return SYM
			 * for redefinition
			 */
			noEquate = TRUE;
			return SYM;
		    } else {
			if (c == '&') {
			    /*
			     * If ID name ended in &, throw away the &. Again,
			     * this is to deal with the MASM semantics
			     * mentioned above...
			     */
			    (void)input();
			}

			DBPRINTF((stderr,"Interpolating string for %i\n", sym->name));
			if ((sym->u.string.value != NULL) &&
			    (((MBlk *)sym->u.string.value)->length != 0))
			{
			    PushMacro(sym->u.string.value);
			}
			return yylex(yylval);
		    }
		}
		case SYM_MACRO:
		    if (!ignore) {
			/*
			 * Invoking a macro -- switch into special macro-
			 * processing mode and tell the parser what it's got.
			 */
			commaMeansEmpty = firstArg = noSymTrans = TRUE;
			yylex = yymacarglex;
			DBPRINTF((stderr,"Returning MACEXEC(%i)\n", sym->name));
			return MACEXEC;
		    } else {
			return SYM;
		    }
		case SYM_ETYPE:
		    DBPRINTF((stderr,"Returning ETYPE_SYM(%i)\n", sym->name));
		    return ETYPE_SYM;
		case SYM_UNION:
		case SYM_STRUCT:
		    /*
		     * Differentiate between regular symbols and
		     * structured-type symbols to make life easier and cleaner.
		     */
		    DBPRINTF((stderr,"Returning STRUCT_SYM(%i)\n", sym->name));
		    defStruct = TRUE;
		    return STRUCT_SYM;
		case SYM_SEGMENT:
		case SYM_GROUP:
		    DBPRINTF((stderr,"Returning MODULE_SYM(%i)\n", sym->name));
		    return MODULE_SYM;
		case SYM_TYPE:
		    DBPRINTF((stderr,"Returning TYPE_SYM(%i)\n", sym->name));
		    defStruct = TRUE;
		    return TYPE_SYM;
		case SYM_METHOD:
		    DBPRINTF((stderr,"Returning METHOD_SYM(%i)\n", sym->name));
		    return METHOD_SYM;
		case SYM_INSTVAR:
		    DBPRINTF((stderr,"Returning INSTVAR_SYM(%i)\n", sym->name));
		    return INSTVAR_SYM;
		case SYM_PROTOMINOR:
		    DBPRINTF((stderr,"Returning PROTOMINOR_SYM(%i)\n", sym->name));
		    return PROTOMINOR_SYM;
		case SYM_CLASS:
		    DBPRINTF((stderr,"Returning CLASS_SYM(%i)\n", sym->name));
		    return CLASS_SYM;
		case SYM_RECORD:
		    DBPRINTF((stderr,"Returning RECORD_SYM(%i)\n", sym->name));
		    defStruct = TRUE;
		    return RECORD_SYM;
		case SYM_NUMBER:
		    DBPRINTF((stderr,"Returning EXPR_SYM(%i)\n", sym->name));
		    return(EXPR_SYM);
		default:
		    /*
		     * Not an opcode, but it's defined -- tell the parser it's
		     * got a defined symbol on its hands.
		     */
		    DBPRINTF((stderr,"Returning SYM(%i)\n", sym->name));
		    return SYM;
		}
	    } else {
		yylval->ident = id;
	    }
	} else {
	    yylval->ident = ST_Enter(output, symStrings, yytext, cp - yytext);
	}

	/*
	 * Deal with @Line thing.
	 */
	if (yylval->ident == lineID) {
	    yylval->number = yylineno;
	    return(CONSTANT);
	}

	DBPRINTF((stderr,"Returning IDENT(%i)\n", yylval->ident));
	return IDENT;
    }
    }
}


/***********************************************************************
 *				yyreadstring
 ***********************************************************************
 * SYNOPSIS:	    Read a string literal
 * CALLED BY:	    yylex (<, {, ' and " cases)
 * RETURN:	    Token to return
 * SIDE EFFECTS:    yylval->string is set to the string read, dynamically
 *	    	    allocated. findOpcode removed from the list of procedures
 *	    	    tried.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/31/89		Initial Revision
 *
 ***********************************************************************/
static int
yyreadstring(char   open,   	/* If matched, ignore next close */
	     char   close,  	/* Character to close the string */
	     char   duplicate, 	/* If matched and follows, place one
				 * in string and continue */
	     YYSTYPE *yylval)	/* Place to store result */
{
    int  	c;
    char	*base = yytext;
    int 	size = sizeof(yytext);
    char    	*cp;
    int	    	level = 0;
    int	    	start = yylineno;

    DBPRINTF((stderr,"reading %c%c string literal...", open ? open : close,
		close));
    cp = base;
    while(1) {
	c = input();
	if (c == 0) {
	    if (close != '\n') {
		yyerror("end-of-file in string constant (began on line %d)",
			start);
		return(0);
	    } else {
		/*
		 * Snarfing to the end of the line. We don't complain here.
		 * Just return what we've got after pushing a newline
		 * back into the input stream -- the EOF will be handled
		 * gracefully elsewhere.
		 */
		unput('\n');
		break;
	    }
	} else if (c == duplicate) {
	    int	c2 = input();

	    if (c2 != duplicate) {
		unput(c2);
		if (c == close) {
		    break;
		}
	    }
	} else if (c == open) {
	    /*
	     * Open character -- up the nesting level
	     */
	    level++;
	} else if (c == '\n') {
	    /*
	     * Allow a newline to terminate the string, but don't
	     * swallow the thing. Since MASM accepts things like
	     *	MACEXEC <.....\n
	     * we don't give a warning should this happen in a <> string,
	     * but otherwise we do....just to be safe :)
	     */
	    if (close != '>' && close != '\n') {
		yywarning("%c-terminated string constant terminated by newline",
			  close);
	    }
	    unput(c);
	    break;
	} else if (c == close && --level < 0) {
	    /*
	     * Close on bottom level -- get out of here.
	     */
	    break;
	} else if (c == '\\') {
	    /*
	     * Handle C-style escape sequences.
	     */
	    switch(c = input()) {
	    case 'n': c = '\n'; break;
	    case 'b': c = '\b'; break;
	    case 'f': c = '\f'; break;
	    case 'r': c = '\r'; break;
	    case 't': c = '\t'; break;
	    case '0': case '1': case '2': case '3': case '4':
	    case '5': case '6': case '7': case '8': case '9':
	    {
		/*
		 * Convert from octal.
		 */
		int	val;

		for (val = c - '0';
		     isdigit(c=input()) && c < '8';
		     val += c - '0')
		{
		    val <<= 3;
		}
		/*
		 * Put back the non-digit char
		 */
		unput(c);
		/*
		 * Convert to a character
		 */
		c = val & 0xff;
		break;
	    }
	    case 'x':
	    {
		/*
		 * Convert following 2 digits from hex
		 */
		int val;

		/*
		 * First character MUST be hex...
		 */
		c = input();
		if (isxdigit(c)) {
		    if (c <= '9') {
			val = c - '0';
		    } else if (c <= 'F') {
			val = c - 'A' + 10;
		    } else {
			val = c - 'a' + 10;
		    }
		} else {
		    yyerror("\\x followed by '%c', not hex digit", c);
		    break;
		}
		/*
		 * Second character is optional
		 */
		c = input();
		if (isxdigit(c)) {
		    val <<= 4;
		    if (c <= '9') {
			val += c - '0';
		    } else if (c <= 'F') {
			val += c - 'A' + 10;
		    } else {
			val += c - 'a' + 10;
		    }
		} else {
		    /*
		     * Ok for there only to be one hex digit. Just put
		     * the character we got, back.
		     */
		    unput(c);
		}
		c = val;
		break;
	    }
	    case '\n':
		/*
		 * Swallow both the \ and the newline when newline is escaped
		 * like this.
		 */
		if (!inmacro) {
		    yynewline();
		}
		continue;
	    } /* switch */
	} /* if */

	*cp++ = c;

	if (cp == base+size) {
	    /*
	     * Extend buffer as needed.
	     */
	    if (base == yytext) {
		base = (char *)malloc(size*2);
		bcopy(yytext, base, sizeof(yytext));
	    } else {
		base = (char *)realloc(base, size*2);
	    }
	    cp = base + size;
	    size *= 2;
	}
    }
    DBPRINTF((stderr,"done\n"));

    *cp++ = '\0';

    if (base == yytext) {
	/*
	 * Copy to non-volatile storage now we know how big it is.
	 */
	base = (char *)malloc(cp - yytext);
	bcopy(yytext, base, cp-yytext);
    }

    yylval->string = base;

    DBPRINTF((stderr,"returning string %s\n", yylval->string));
    return(STRING);
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
int
yystdwrap(void)
{
    File    	    *f;
    int	    	    junk;

    /*
     * This is to handle the last localizable chunk at the end of the end.
     */
    if ( warn_localize && localizationRequired ){
	Parse_LastChunkWarning("Missing @localize instruction");
	localizationRequired = 0;
    }

    /*
     * Close current file
     */
    fclose(yyin);

    /*
     * Since the parser won't know if we hit the end of an include file, we
     * must produce an error messages our own selves
     */
    if (ignore) {
	yyerror("end-of-file in false conditional\n");
	ignore = FALSE;
    }

    if (iflevel != curFile->iflevel) {
	int 	diff = iflevel - curFile->iflevel;

	if (diff < 0) {
	    Notify(NOTIFY_ERROR, curFile->name, -1,
		   "%d too many endifs", -diff);
	} else {
	    Notify(NOTIFY_ERROR, curFile->name, -1,
		   "%d open conditional%s:", diff, diff == 1 ? "" : "s");
	    while (diff > 0) {
		fprintf(stderr, "\tstarted at file \"%i\", line %d\n",
			ifStack[iflevel].file, ifStack[iflevel].line);
		iflevel--;
		diff--;
	    }
	}
    }

    /*
     * Switch to next file
     */
    f = curFile->next;

    (void)Parse_CheckClosure(&junk, TRUE);

    /*
     * Free up the memory for the ending file
     */
    free((void *)curFile);

    if (f == 0) {
	/*
	 * Nowhere to go from here -- all done
	 */
	return(TRUE);
    } else {
	/*
	 * Switch to previous file
	 */
	curFile = f;
	yyin = f->file;		/* Previous stream */
	yysptr = yysbot;	/* Discard pushback from current file */
	PopMacro();		/* Recover macro state from previous */
	yylineno = f->line;	/* Line is from previous */
	Parse_FileChange(FALSE);
	return(FALSE);
    }
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
void
Scan_Init(void)
{
    /*
     * Initialize the two input vectors and the wrapup vector
     */
    yylex = yystdlex;
    yyinput = stdinput;
    yywrap = yystdwrap;

    (void)Scan_UseOpProc(findOpcode);
    (void)Scan_UseOpProc(findFlopcode);

    lineID = ST_EnterNoLen(output, symStrings, "@Line");
}


/***********************************************************************
 *				yyflush
 ***********************************************************************
 * SYNOPSIS:	  Flush to the end of the current line
 * CALLED BY:	  yyparse (opcode), yylex (comment)
 * RETURN:	  nothing
 * SIDE EFFECTS:  Input is discarded to the next newline or the end of
 *	    	  the file and a newline pushed back into the stream.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 6/88		Initial Revision
 *
 ***********************************************************************/
void
yyflush(void)
{
    char    c;

    while((c = input()) != '\n' && c != '\0') {
	;
    }
    unput('\n');
}


/***********************************************************************
 *				yycreatelocals
 ***********************************************************************
 * SYNOPSIS:	    Create maps for the local labels in this macro block
 * CALLED BY:	    yystartmacro, yyrept, yyirp, yyirpc
 * RETURN:	    Nothing
 * SIDE EFFECTS:    maps[numMaps-numLocals..numMaps-1] point to MASM-
 *	    	    style local labels.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/24/89		Initial Revision
 *
 ***********************************************************************/
static void
yycreatelocals(int  numLocals)
{
    static int	localCount = 0;	/* Number for next masm-style label */
    int	    	i;

    for (i = numMaps - numLocals; i < numMaps; i++) {
	maps[i] = (MBlk *)malloc(sizeof(MBlk));
	sprintf(maps[i]->text, "??%04x", localCount++);
	maps[i]->length = 6;
	maps[i]->dynamic = TRUE;
	maps[i]->next = NULL;
    }
}


/***********************************************************************
 *				yystartmacro
 ***********************************************************************
 * SYNOPSIS:	  Enter macro-processing mode.
 * CALLED BY:	  yyparse()
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
 *	ardeb	8/31/88		Initial Revision
 *
 ***********************************************************************/
void
yystartmacro(Symbol *which, /* Macro to interpolate */
	     Arg *args)		/* Arguments to pass */
{
    Arg	    	*ap;	    /* Current argument */
    int		i;	    /* Index into maps */
    MBlk    	*mp;	    /* Current block of argument */
    char	*cp,
		*cp2;
    int		count;

    noSymTrans = FALSE;

    /*
     * Save the previous macro state, pushing to the symbol's text.
     */
    PushMacro(which->u.macro.text);

    numMaps = which->u.macro.numArgs + which->u.macro.numLocals;

    DBPRINTF((stderr,"Expanding %i with %d maps --\n", which->name, numMaps));

    ap = args;

    if (numMaps != 0) {
	/*
	 * There are actually parameters for this macro. Allocate space for
	 * pointers to the arguments themselves.
	 * XXX: Use some sort of map stack so don't have to alloc/free so much?
	 */
	maps = (MBlk **)calloc(numMaps, sizeof(MBlk *));
	/*
	 * For each actual argument, transform it into a chain of MBlk
	 * structures for the actual interpolation.
	 */
	for (i = 0;
	     i < which->u.macro.numArgs && ap != (Arg *)NULL;
	     ap = ap->next, i++)
	{
	    /*
	     * We may not have a MBlk of length 0, so make sure the value is
	     * non-blank and only create a chain if it is. Blank args are
	     * special-cased by having their entry in the maps array be
	     * NULL.
	     */
	    if ((ap->value != (char *)NULL) && (*ap->value != '\0')) {
		DBPRINTF((stderr,"\targ[%d] = \"%s\"\n", i, ap->value));

		maps[i] = mp = (MBlk *)malloc(sizeof(MBlk));

		cp  = ap->value;
		mp->length = 0;
		mp->dynamic = TRUE;
		while (*cp != '\0') {
		    /*
		     * Copy in as many characters as will fit and exist.
		     */
		    for (count = 0, cp2 = mp->text;
			 *cp != '\0' && count < MACRO_BLOCK_SIZE;
			 *cp2++ = *cp++, count++)
		    {
			;
		    }
		    /*
		     * Set the length of the block
		     */
		    mp->length = count;

		    if (*cp != '\0') {
			/*
			 * More to come, so allocate another block for the arg
			 */
			mp->next = (MBlk *)malloc(sizeof(MBlk));
			mp = mp->next;
			mp->length = 0;
			mp->dynamic = TRUE;
		    }
		}
		/*
		 * Null-terminate the chain
		 */
		mp->next = (MBlk *)NULL;
		/*
		 * If the argument value needs to be freed, do it now (as good
		 * a time as any and better than most)
		 */
		if (ap->freeIt) {
		    free(ap->value);
		}
	    } else {
		/*
		 * No arg for the parameter, so mark it as empty
		 */
		DBPRINTF((stderr,"\targ[%d] = \"\"\n", i));
		maps[i] = (MBlk *)NULL;
		if (ap->freeIt) {
		    free(ap->value);
		}
	    }
	}

	/*
	 * Any parameters that don't have actual arguments get NULL, since
	 * we can't have a block of length 0.
	 */
	while (i < which->u.macro.numArgs) {
	    DBPRINTF((stderr,"\targ[%d] = \"\"\n", i));
	    maps[i++] = (MBlk *)NULL;
	}
    }

    /*
     * Any parameters that don't have formal parameters still may need to
     * be freed.
     */
    while (ap != NULL) {
	if (ap->freeIt) {
	    free(ap->value);
	}
	ap = ap->next;
    }

    /*
     * Free the Arg descriptors themselves.
     */
    if (args != NULL) {
	Arg *next;

	for(ap = args; ap != NULL; ap = next) {
	    next = ap->next;
	    free((void *)ap);
	}
    }

    /*
     * Create mappings for labels local to this macro
     */
    yycreatelocals(which->u.macro.numLocals);

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
    } else {
        /*
         * In case we skipped over a zero-length argument, set curMacPtr
         * to be the text in the current block.
         */
        curMacPtr = curBlock->text;
    }
}


/***********************************************************************
 *				ustrcmp
 ***********************************************************************
 * SYNOPSIS:	  Perform an unsigned (case-insensitive) string comparison
 * CALLED BY:	  yylex
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
    int	    	    diff;
    char    	    c1, c2;

    while ((c1 = *s1) && (c2 = *s2)) {
	diff = c1 - c2;
	if (diff < 0) {
	    if (!isalpha(c1) || (tolower(c1) - c2)) {
		return(diff);
	    }
	} else if (diff > 0) {
	    if (!isalpha(c2) || (c1 - tolower(c2))) {
		return(diff);
	    }
	}
	s1++, s2++;
    }
    /*
     * Can't use c1 and c2 here because c2 may not be set right.
     */
    return(!(*s1 == *s2));
}



/***********************************************************************
 *				yyreadmacrobody
 ***********************************************************************
 * SYNOPSIS:	  Read the body of a macro into a chain of MBlk and
 *	    	  MArg structures.
 * CALLED BY:	  yyreadmacro, yyrepeat, yyirp, yyirpc.
 * RETURN:	  A pointer to the head of the chain.
 * SIDE EFFECTS:  Text is consumed from the input stream.
 *
 * STRATEGY:
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 6/88		Initial Revision
 *
 ***********************************************************************/
static MBlk *
yyreadmacrobody(char	***paramsPtr,/* Array of words to be mapped when macro
				     * is expanded. This starts out as the
				     * dummy parameters for the macro and may
				     * be expanded to include local labels */
		int 	maxParams,  /* Length of params array */
		int 	*numPPtr,   /* In/Out: Number of parameters in params*/
		int 	startLine)  /* Line at which definition started */
{
    MBlk    	*mp,	    	/* Current block in chain */
		**mpp,    	/* Place to store address of next block */
		*head;    	/* Head of the chain of text */
    char	*cp;	    	/* Current place in mp->text */
    int  	c;	    	/* Character read */
    int		i;	    	/* Argument number */
    int	    	nesting=0;  	/* Macro nesting level to determine when an
				 * "endm" is actually for this macro */
    int	    	instring=0; 	/* Non-zero if w/in a <>, "" or '' string and
				 * should thus not skip over comments. Holds
				 * termination character for string. */
    int	    	numParams;  	/* Number of words currently in params */
    int	    	lookForLocal;	/* Non-zero if should look for LOCAL
				 * directive */
    char	**params;

    params = *paramsPtr;

    if (bumpLine) {
	yynewline();
    }

    /*
     * Set up to read the macro definition into a chain of MBlk and MArg
     * structures. mpp points to the place to stuff the next block's address.
     */
    if (!ignore) {
	head = mp = NewBlock();

	mpp = &mp->next;

	cp = mp->text;
    } else {
	mp = head = (MBlk *)NULL;	/* So return value not nonsense */
    }

    lookForLocal = 1;
    numParams = *numPPtr;

    while(1) {
	/*
	 * Skip to the next identifier by looking for a character that
	 * can begin one. Note that &'s don't get copied -- they simply
	 * serve as delimiters for identifiers.
	 */
	while(!isfirstid(c = input()) && (c != 0)) {
	    if (!instring && c == ';') {
		/*
		 * Skip over a comment -- why bother storing the thing?
		 * It will just get nuked when the macro's expanded.
		 */
		do {
		    c = input();
		    if (c == '\\' && ((c = input()) == '\n')) {
			/*
			 * If have escaped newline, have to copy the escape
			 * and the newline into the macro, so put the newline
			 * back and fall out with c being the backslash.
			 */
			unput(c);
			c = '\\';
			break;
		    }
		} while (c != '\n' && c != 0);

		/*
		 * Fall through to store the newline, but break out if
		 * hit the end of the file.
		 */
		if (c == 0) {
		    break;
		}
	    } else if (c == instring) {
		/*
		 * Reached end of string.
		 * XXX: Doesn't handle escaped closings (either with \ or
		 * via doubling), nor does it deal with nested <> strings
		 */
		instring = 0;
	    } else if ((c == '"' || c == '\'') && !instring) {
		/*
		 * Found start of string -- avoid recognizing and skipping
		 * comments inside it.
		 */
		instring = c;
	    } else if (c == '<') {
		/*
		 * Same as above, but need to give different close character
		 */
		instring = '>';
	    }

	    if (c != '&') {
		if (c == '\n') {
		    lookForLocal = 1;
		    if (!inmacro) {
			yynewline();
		    }
		    /*
		     * Newline terminates any in-progress string. No message,
		     * as it can actually be legal (e.g. after a %out).
		     */
		    instring = 0;
		} else if (!isspace(c)) {
		    /*
		     * If not whitespace, can't be a line with local labels
		     * defined...
		     */
		    lookForLocal = 0;
		}
		if (!ignore) {
		    *cp++ = c;
		    if (++mp->length == MACRO_BLOCK_SIZE) {
			/*
			 * Hit end of current block -- allocate a new one
			 */
			*mpp = mp = NewBlock();
			mpp = &mp->next;
			cp = mp->text;
		    }
		}
	    } else {
		/*
		 * Copy any succeeding &'s into the block, dropping the
		 * one we've got. This loop is slightly twisted. Since
		 * the condition for the outer loop calls input(), whatever
		 * characters we read must be stored here rather than being
		 * saved for the next iteration of the outer loop. Thus
		 * we read and store until the character we read is no
		 * longer an &. We have to special case id-beginning
		 * characters, however, so we get out w/o storing them.
		 */
		lookForLocal = 0;
		while (c == '&') {
		    /*
		     * Fetch next character
		     */
		    c = input();
		    /*
		     * Get out of this loop now
		     */
		    if (isfirstid(c)) {
			goto scan_id;
		    }
		    /*
		     * Store the next character, whatever it is.
		     */
		    if (!ignore) {
			*cp++ = c;
			if (++mp->length == MACRO_BLOCK_SIZE) {
			    /*
			     * Hit end of current block -- allocate a new one
			     */
			    *mpp = mp = NewBlock();
			    mpp = &mp->next;
			    cp = mp->text;
			}
		    }
		}
	    }
	}
	/*
	 * Got an ID character or an end-of-file...
	 */
	if (isfirstid(c)) {
	    /*
	     * Hit the start of an identifier. Scan it off into word.
	     */
	    char  word[MAX_TOKEN_LENGTH];
	    char  *cp2;

scan_id:
	    cp2 = word;

	    do {
		*cp2++ = c;
		c = input();
	    } while (isotherid(c));

	    *cp2 = '\0';	/* null terminate */

	    /*
	     * Restore extra character to the input
	     */
	    unput(c);

	    if (!instring && (ustrcmp(word, "endm") == 0) && !(nesting--)) {
		/*
		 * Hit the end of the definition. Return now, making sure
		 * the last block is of non-zero length.
		 */
		if (!ignore && mp->length == 0) {
		    /*KLUDGE*/
		    *cp = ' ';
		    mp->length = 1;
		}
		*numPPtr = numParams;
		break;
	    } else if (!instring && lookForLocal && !nesting &&
		       (ustrcmp(word, "local") == 0) &&
		       (c == ' ' || c == '\t'))
	    {
		/*
		 * Told to look for LOCAL directive and found one that's
		 * followed by whitespace. Now need to snarf the names of
		 * the local labels and stuff them into the params array
		 * for proper mapping.
		 */
		while(1) {
		    /*
		     * Skip whitespace and commas between words
		     */
		    do {
			c = input();
			if (c == ';') {
			    do {
				c = input();
				if (c == '\\' && ((c = input()) == '\n')) {
				    /*
				     * Escaped newline -- up the line count
				     * if input source not a macro, then fetch
				     * the next character and get out of
				     * this comment-reading loop.
				     */
				    if (!inmacro) {
					yynewline();
				    }
				    c = input();
				    break;
				}
			    } while (c != '\n' && c != 0);
			}
		    } while (c == ' ' || c == '\t' || c == ',');

		    if (c == '\n') {
			/*
			 * End-of-line -- done, but need to up the line number
			 */
			if (!inmacro) {
			    yynewline();
			}
			break;
		    } else if (c == 0) {
			break;
		    }

		    /*
		     * Scan off the identifier
		     */
		    cp2 = word;
		    do {
			*cp2++ = c;
			c = input();
		    } while (isotherid(c));

		    unput(c);
		    *cp2++ = '\0';

		    /*
		     * Make sure the array can hold another pointer, allocating
		     * a new array on the stack and copying the old pointers
		     * into it if not. Old array allocated on stack, too, so
		     * no need to free it.
		     */
		    if (!ignore) {
			if (numParams == maxParams) {
			    params = (char **)realloc((void *)params,
						      (maxParams+PARAM_SIZE)*
						      sizeof(char *));
			    maxParams += PARAM_SIZE;
			}
			/*
			 * Copy the identifier into more permanent storage on
			 * the stack and point the array to it.
			 */
			params[numParams] = (char *)malloc((cp2-word)+1);
			bcopy(word, params[numParams], (cp2-word)+1);
			numParams += 1;
		    }
		}
	    } else {
		if (!instring &&
		    ((ustrcmp(word, "macro") == 0) ||
		     (ustrcmp(word, "rept") == 0) ||
		     (ustrcmp(word, "irp") == 0) ||
		     (ustrcmp(word, "irpc") == 0)))
		{
		    /*
		     * Yuck -- nested macro. Up the nesting level
		     */
		    nesting++;
		} else if (!ignore) {
		    /*
		     * Compare the string against the parameters for the macro
		     * in a case sensitive manner. If we find a match, place
		     * a MArg structure in the chain with the proper argument
		     * number in the argNum field. Note these numbers count
		     * down from 0 (qv. esp.h & input())
		     */
		    for (i=0; i < numParams; i++) {
			if ((params[i][1] == word[1]) &&
			    (strcmp(params[i], word) == 0))
			{
			    /*
			     * It be a parameter
			     */
			    MArg	*margp;

			    if (mp->length == 0) {
				/*
				 * If the current block has nothing in it (as
				 * will happen if there's something like
				 * param1&param2 in the macro), we just use the
				 * current block for the argument, ignoring the
				 * array it has, since we can't go backwards in
				 * the list.
				 */
				margp = (MArg *)mp;
			    } else {
				margp = (MArg *)malloc(sizeof(MArg));
				margp->dynamic = TRUE;
				*mpp = (MBlk *)margp;
			    }
			    margp->argNum = -i;
			    mp = margp->next = NewBlock();
			    mpp = &mp->next;
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
		} else {
		    /*
		     * Ignoring macro -- don't bother storing it (gosh!)
		     */
		    continue;
		}
		if (cp2 - word < MACRO_BLOCK_SIZE - mp->length) {
		    /*
		     * The whole word will fit in the current block. Copy
		     * it in and update both cp and mp->length.
		     */
		    bcopy(word, cp, cp2 - word);
		    mp->length += cp2 - word;
		    cp = &mp->text[mp->length];
		} else {
		    /*
		     * Won't fit. Copy what will fit into the current block,
		     * and allocate blocks, copying successive chunks into
		     * them, until the word is completely stored.
		     */
		    i = MACRO_BLOCK_SIZE - mp->length;

		    bcopy(word, cp, i);
		    mp->length = MACRO_BLOCK_SIZE;

		    /*
		     * Point cp at the next chunk to copy
		     */
		    cp = word + i;

		    /*
		     * Allocate the next block
		     */
		    *mpp = mp = NewBlock();
		    mpp = &mp->next;

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
			*mpp = mp = NewBlock();
			mpp = &mp->next;
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
	} else {
	    /*
	     * Can only have gotten here b/c of an end-of-file
	     */
	    yyerror("End-of-file during macro definition starting at %d\n",
		    startLine);
	    *numPPtr = numParams;
	    break;
	}
    }
    *paramsPtr = params;
    return(head);
}

/***********************************************************************
 *				yyreadmacro
 ***********************************************************************
 * SYNOPSIS:	    Read a macro from the input, discarding it all if
 *	    	    ignore is set.
 * CALLED BY:	    yyparse
 * RETURN:	    yylval->macro.{numLocals,numArgs,text} filled in
 * SIDE EFFECTS:    MBlks are allocated if ignore is FALSE
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 1/88		Initial Revision
 *
 ***********************************************************************/
static void
yyreadmacro(YYSTYPE *yylval)
{
    char    *cp;    	    /* Generic pointer */
    int	    c;	    	    /* Current input character */
    int	    startLine = yylineno;   /* Starting line number for bitching
				     * about end-of-file */
    char    **params;	    /* Array of parameter names to match in
			     * yyreadmacrobody */
    int	    maxParams;	    /* Length of above */
    int	    numParams;	    /* Number of parameters actually in params */
    int	    numLocals;	    /* Number of local labels required */
    int	    i;

    /*
     * First fetch the args. They must be comma-separated.
     */
    numParams = 0;
    maxParams = PARAM_SIZE;
    params = (char **)malloc(maxParams * sizeof(char *));

    while(1) {
fetch_param:
	do {
	    c = input();
	} while (isspace(c) && (c != '\n'));

	if (isfirstid(c)) {
	    /*
	     * An(other) argument. Scan off the IDENT and
	     * stuff it into an Arg structure linked to the end of the
	     * chain.
	     */
	    char  arg[MAX_TOKEN_LENGTH];

	    cp = arg;
	    *cp++ = c;

	    while (isotherid(c = input())) {
		*cp++ = c;
	    }
	    *cp++ = '\0';
	    /*
	     * Make sure the array can hold another pointer, allocating
	     * a new array on the stack and copying the old pointers
	     * into it if not. Old array allocated on stack, too, so
	     * no need to free it.
	     */
	    if (numParams == maxParams) {
		params = (char **)realloc((void *)params,
					  (maxParams+PARAM_SIZE)*sizeof(char *));
		maxParams += PARAM_SIZE;
	    }
	    /*
	     * Copy the identifier into more permanent storage on
	     * the stack and point the array to it.
	     */
	    params[numParams] = (char *)malloc((cp-arg)+1);
	    bcopy(arg, params[numParams], (cp-arg)+1);
	    numParams += 1;

	    /*
	     * Skip trailing whitespace without complaining.
	     */
	    while (isspace(c) && (c != '\n')) {
		c = input();
	    }
	}
	if (c == ';') {
	    /*
	     * It's a comment. Read to the end of the line. If the final
	     * newline is escaped, continue processing IDENT's as macro
	     * dummy-arguments. Else get out of here.
	     */
	    do {
		c = input();
		if (c == '\\' && ((c = input()) == '\n')) {
		    if (!inmacro) {
			yynewline();
		    }
		    c = input();
		    goto fetch_param;
		}
	    } while (c != '\n' && c != 0);
	    goto readezle;	/* Ignore newline */
	} else if (c == '\n') {
	    /*
	     * Hit the end of the line -- go to process the rest of the
	     * macro w/o checking for a newline we just got.
	     */
	    goto readezle;
	} else if (c != ',') {
	    yyerror("Garbage character (0x%x) ignored\n", c);
	    goto choke_me_jesus;
	} else if (c == 0) {
	    yyerror("end-of-file in macro definition\n");
	    goto choke_me_jesus;
	}
	/*
	 * Any other character can be discarded.
	 */
    }
    /*
     * Make sure we hit the end of the line.
     */
    if ((c = input()) != '\n') {
	if (c == 0) {
	    yyerror("end-of-file in macro definition (began on line %d)\n", startLine);
	} else {
	    yyerror("bogus character (0x%x) after macro parameters\n", c);
	}
choke_me_jesus:
	yylval->macro.text = (MBlk *)NULL;
	yylval->macro.numArgs = yylval->macro.numLocals = 0;
	goto done;
    }
 readezle:
    if (curBlock == NULL) {
	yynewline();		/* update line number since read a newline */
    }
    /*
     * Call yyreadmacrobody to read the actual body of the macro into
     * a chain of MBlk and MArg structures. Note: can't pass
     * &yylval->macro.numLocals since that's a short and yyreadmacrobody
     * wants an int *...
     */
    numLocals = yylval->macro.numArgs = numParams;
    yylval->macro.text = yyreadmacrobody(&params, maxParams,
					 &numLocals, startLine);
    yylval->macro.numLocals = numLocals - yylval->macro.numArgs;

done:
    for (i = numParams-1; i >= 0; i--) {
	free(params[i]);
    }
    free((char *)params);
}

/***********************************************************************
 *				yyfreemaps
 ***********************************************************************
 * SYNOPSIS:	  Free the argument maps and their values
 * CALLED BY:	  input()
 * RETURN:	  Nothing
 * SIDE EFFECTS:  See above.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 1/88		Initial Revision
 *
 ***********************************************************************/
static void
yyfreemaps()
{
    int	    i;
    MBlk    **map;
    MBlk    *mp, *mpnext;

    for (map = maps, i = numMaps; i > 0; map++, i--) {
	for (mp = *map; mp != (MBlk *)NULL; mp = mpnext) {
	    mpnext = mp->next;
	    if (mp->dynamic) {
		free((char *)mp);
	    }
	}
    }
    assert (maps);
    free((char *)maps);
}


/***********************************************************************
 *				yyrepeat
 ***********************************************************************
 * SYNOPSIS:	  Repeat a set of statements
 * CALLED BY:	  yyparse when REPT seen
 * RETURN:	  Nothing
 * SIDE EFFECTS:  The text is pushed as a macro the number of times
 *		  indicated.
 *
 * STRATEGY:
 *	We first read the text to be repeated by calling yyreadmacrobody
 *	then perform n PushMacro()'s of the returned text.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 6/88		Initial Revision
 *
 ***********************************************************************/
void
yyrepeat(n)
    int	    	n;	    /* Number of times to repeat */
{
    MBlk    	*text;
    int	     	numLocal;
    char	**params;
    int		i;

    /*
     * Read the text to repeat w/o parameter substitution. Note the
     * startLine for yyreadmacrobody is 1 less than the current line since
     * the parser will have had to read the \n token to determine the
     * expression was at an end.
     */
    numLocal = 0;
    params = (char **)malloc(sizeof(char *));
    text = yyreadmacrobody(&params, 0, &numLocal, yylineno-1);

    if (text->length != 0) {
	/*
	 * Interpolate it as many times as we need to repeat it.
	 */
	while(n) {
	    PushMacro(text);
	    n--;
	    if (numLocal) {
		numMaps = numLocal;
		maps = (MBlk **)malloc(numLocal * sizeof(MBlk *));
		yycreatelocals(numLocal);
	    }
	}
    }

    for (i = numLocal - 1; i >= 0; i--) {
	free(params[i]);
    }
    free((char *)params);

    /*
     * XXX: Need to free up the text
     */
}


/***********************************************************************
 *				yyirp
 ***********************************************************************
 * SYNOPSIS:	  Repeat the following text the number of times indicated
 *	    	  by the argument list.
 * CALLED BY:	  yyparse when IRP is seen
 * RETURN:	  Nothing
 * SIDE EFFECTS:  The text is interpolated one or more times.
 *
 * STRATEGY:
 *	Read the macro text into a chain of MBlk's.
 *	Build up a stack of the arguments in the argument list.
 *	For each item in the argument list, starting at the end,
 *	    PushMacro to the read text
 *	    create 1-item maps array with the argument
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 6/88		Initial Revision
 *
 ***********************************************************************/
void
yyirp(char    	  *paramName,	/* The dummy-parameter name to use */
    	char	  *args)    	/* Comma-separated list of args */
{
#define DEF_NUM_ARGS	32  	/* First estimate of the number of args */
    int		    i;
    MBlk	    *text, *mp;
    MBlk 	    **iap;  	/* Stack of arguments */
    int	    	    cur;    	/* Current argument slot */
    int	    	    numArgs;	/* Number of slots in iap */
    MBlk    	    *defIAP[DEF_NUM_ARGS];
    char	    *cp, *cp2;
    char    	    **params;
    int	    	    numParams;

    /*
     * Set up the Arg for yyreadmacrobody
     */
    params = (char **)malloc(PARAM_SIZE * sizeof(char *));
    params[0] = paramName;
    numParams = 1;

    /*
     * Read the text to be repeated.
     */
    text = yyreadmacrobody(&params, PARAM_SIZE, &numParams, yylineno);

    cp = args;

    /*
     * Initialize the argument stack
     */
    iap = defIAP;
    numArgs = DEF_NUM_ARGS;
    cur = 0;
    iap[0] = (MBlk *)NULL;

    while(*cp != '\0') {
	/*
	 * Skip over white-space
	 */
	while(isspace(*cp)) {
	    cp++;
	}

	/*
	 * Allocate a new chain for the next argument. Note we don't
	 * use NewBlock here b/c we can free these things in yyfreemaps.
	 */
	if ((*cp == ',') || (*cp == '\0')) {
	    iap[cur++] = (MBlk *)NULL;
	} else {
	    iap[cur++] = mp = (MBlk *)malloc(sizeof(MBlk));
	    mp->length = 0;
	    mp->dynamic = TRUE;
	    mp->next = (MBlk *)NULL;
	    cp2 = mp->text;

	    do {
		*cp2++ = *cp++;
		if (++mp->length == MACRO_BLOCK_SIZE) {
		    if ((*cp != ',') && (*cp != '\0')) {
			/*
			 * That wasn't the last character in the block --
			 * allocate a new one for the next character(s) and
			 * reset cp2 to the start of the new block's text.
			 */
			mp->next = (MBlk *)malloc(sizeof(MBlk));
			mp = mp->next;
			mp->length = 0;
			mp->dynamic = TRUE;
			mp->next = (MBlk *)NULL;
			cp2 = mp->text;
		    } else {
			/*
			 * End of the argument -- stop now.
			 */
			break;
		    }
		}
	    } while((*cp != ',') && (*cp != '\0'));
	}

	if (*cp != '\0') {
	    /*
	     * Still not at the end of the list -- make sure we've got room
	     * in the argument stack, resizing it as necessary.
	     */
	    if (cur == numArgs) {
		numArgs *= 2;

		if (iap != defIAP) {
		    iap = (MBlk **)realloc((void *)iap, numArgs * sizeof(MBlk *));
		} else {
		    iap = (MBlk **)malloc(numArgs * sizeof(MBlk *));
		    bcopy(defIAP, iap, DEF_NUM_ARGS * sizeof(MBlk *));
		}
	    }

	    /*
	     * Skip over delimiter
	     */
	    cp++;
	} else {
	    break;
	}
    }

    /*
     * Now have cur being the index of the last argument in the stack.
     * Start pushing the text we read onto the macro stack, installing the
     * argument in the maps array before looping. Since both structures are
     * stacks, we end up with the first argument in the list being in the
     * maps array and curBlock et al pointing to the start of the text
     * when this is all done. As the text is processed, we will work our
     * way down the list of arguments until we get back to where we started
     * from.
     */
    for (i = cur-1; i >= 0; i--) {
	PushMacro(text);

	numMaps = numParams;
	maps = (MBlk **)malloc(sizeof(MBlk *) * numParams);

	*maps = iap[i];
	yycreatelocals(numParams-1);
    }

    if (iap != defIAP) {
	free((char *)iap);
    }

    /*
     * This one ends at 1 b/c params[0] is something we were passed, not
     * something we allocated...
     */
    for (i = numParams-1; i > 0; i--) {
	free(params[i]);
    }
    free((char *)params);

    /*
     * XXX: Need to free the text chain when done...
     */
}


/***********************************************************************
 *				yyirpc
 ***********************************************************************
 * SYNOPSIS:	  Repeat the following text the number of times indicated
 *	    	  by the argument list.
 * CALLED BY:	  yyparse when IRPC is seen
 * RETURN:	  Nothing
 * SIDE EFFECTS:  The text is interpolated one or more times.
 *
 * STRATEGY:
 *	Read the macro text into a chain of MBlk's.
 *	Build up a stack of the arguments in the argument list.
 *	For each item in the argument list, starting at the end,
 *	    PushMacro to the read text
 *	    create 1-item maps array with the argument
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 6/88		Initial Revision
 *
 ***********************************************************************/
void
yyirpc(char    	*paramName,	/* The dummy-parameter name to use */
       char	*args)    	/* String of argument characters */
{
    MBlk	*text, *mp;
    char	*cp;
    char    	**params;
    int	    	numParams;
    int		i;

    params = (char **)malloc(PARAM_SIZE * sizeof(char *));
    params[0] = paramName;
    numParams = 1;

    /*
     * Read the text to be repeated.
     */
    text = yyreadmacrobody(&params, PARAM_SIZE, &numParams, yylineno);

    /*
     * This is much simpler. For each of the characters in the argument
     * string, starting at the end and working toward the beginning, we
     * create a single MBlk structure and register it as the sole argument in
     * the maps array. Before doing this, of course, we push to the text
     * we read. The result is much as for yyirp, above, but with less work.
     */
    cp = args + strlen(args);

    while(--cp >= args) {
	PushMacro(text);

	maps = (MBlk **)malloc(sizeof(MBlk *) * numParams);
	numMaps = numParams;
	*maps = mp = (MBlk *)malloc(sizeof(MBlk));
	mp->length = 1;
	mp->dynamic = TRUE;
	mp->next = (MBlk *)NULL;
	mp->text[0] = *cp;
	yycreatelocals(numParams-1);
    }

    /*
     * This one ends at 1 b/c params[0] is something we were passed, not
     * something we allocated...
     */
    for (i = numParams - 1; i > 0; i--) {
	free(params[i]);
    }
    free((char *)params);
    /*
     * XXX: Need to free the text chain when done...
     */
}

#include    "cond.h"
#undef MIN_WORD_LENGTH
#undef MAX_WORD_LENGTH
#undef MIN_HASH_VALUE
#undef MAX_HASH_VALUE

/***********************************************************************
 *				Scan_ToEndif
 ***********************************************************************
 * SYNOPSIS:	    Skip to the ENDIF (or ELSE if orElse is TRUE)
 *		    corresponding to this IF.
 * CALLED BY:	    HandleIF on failed conditional
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Characters are discarded. The terminating token is
 *	    	    pushed back into the input stream.
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
Scan_ToEndif(int orElse)
{
    int	    	    nesting=0;	/* Level of IF nesting */
    int	    	    c;	    	/* Current character */
    const OpCode    *opp;   	/* Conditional opcode, if any */
    char    	    word[MAX_TOKEN_LENGTH]; /* Buffer for scanning of token */
    char    	    *cp2;   	/* Address in same */
    int	    	    startLine = yylineno;   /* Record of initial line in
					     * case of EOF */
    int	    	    wasmacro;	/* State of inmacro at last \n.
				 * Required to determine if we should
				 * decrement yylineno after pushing a
				 * newline back into the input stream */
    int	    	    oldsm = showmacro;

    /*
     * Turn off macro display during a false conditional.
     */
    showmacro = 0;

    /*
     * If parser read the final newline, we need to account for it.
     */
    if (bumpLine) {
	yynewline();
	wasmacro = FALSE;
    } else {
	/*
	 * If newline was read and bumpLine is still false, we were in
	 * a macro. If newline wasn't read and we're not in a macro,
	 * the code below will catch this. We need to set wasmacro to
	 * TRUE here to catch empty conditionals...
	 */
	wasmacro = TRUE;
    }


    while (1) {
	/*
	 * Skip to the next identifier by looking for a character that
	 * can begin one.
	 */
	while(!isfirstid(c = input()) && (c != 0)) {
	    if (c == ';') {
		/*
		 * Skip over a comment.
		 */
		do {
		    c = input();
		} while (c != '\n' && c != 0);

		/*
		 * Fall through to handle the newline, but break out if
		 * hit the end of the file.
		 */
		if (c == 0) {
		    yyerror("end-of-file in false conditional starting on line %d",
			    startLine);
		    opp = NULL;
		    break;
		}
	    } else if (c == '"' || c == '\'') {
		/*
		 * Found start of string -- avoid recognizing tokens
		 * inside it by skipping it in its entirety
		 */
		YYSTYPE	yylval;

		if (!yyreadstring(0, c, c, &yylval)) {
		    showmacro = oldsm;
		    return;
		}
		free(yylval.string);
	    } else if (c == '<') {
		/*
		 * Same as above, but need to give different close character
		 */
		YYSTYPE	yylval;

		if (!yyreadstring(c, '>', 0, &yylval)) {
		    return;
		}
		free(yylval.string);
	    }

	    if (c == '\n') {
		wasmacro = inmacro;
		if (!inmacro) {
		    yynewline();
		}
	    }
	}

	/*
	 * Got an ID character or an end-of-file...
	 */
	if (isfirstid(c)) {
	    /*
	     * Hit the start of an identifier. Scan it off into word,
	     * downcasing it as we go, as that's what we need to do for
	     * the keywords for which we search.
	     */

	    cp2 = word;

	    do {
		if (isupper(c)) {
		    *cp2++ = tolower(c);
		} else {
		    *cp2++ = c;
		}
		c = input();
	    } while (isotherid(c));

	    *cp2 = '\0';	/* null terminate */

	    /*
	     * Restore extra character to the input
	     */
	    unput(c);

	    opp = findCondToken(word, cp2-word);

	    if (opp != NULL) {
		if (opp->token == COMMENT) {
		    ScanComment();
#if 0
		    /*
		     * ScanComment() pushes the newline back into the input
		     * stream, so this is superfluous.
		     */
		    if (!(wasmacro = inmacro)) {
			yynewline();
		    }
#else
		    wasmacro = inmacro;
#endif
		} else if (opp->token == ENDIF) {
		    if (nesting-- == 0) {
			/*
			 * If no more nesting, we're done.
			 */
			break;
		    }
		} else if (!nesting &&
			   (opp->token == ELSE || opp->value == 1) && orElse)
		{
		    /*
		     * Hit an ELSE at the highest level and we're allowed to
		     * stop on an else, so get out.
		     */
		    break;
		} else if (opp->token != ELSE && opp->value == 0) {
		    /*
		     * Another nested IF (yech). Up the nesting level and
		     * keep going.
		     */
		    nesting++;
		}
	    } else {
		/*
		 * If not at the start of the line (barring whitespace),
		 * this line can't contain the end or anything nested -- skip
		 * to the end to avoid running into ghosts (e.g. in comments
		 * or %out's)
		 */
		while ((c = input()) != '\n' && (c != 0)) {
		    ;
		}
		if (c == 0) {
		    /*
		     * yrg. EOF -- bitch and get out
		     */
		    yyerror("end-of-file in false conditional starting on line %d",
			    startLine);
		    opp = NULL;
		    break;
		} else {
		    wasmacro = inmacro;
		    if (!inmacro) {
			yynewline();
		    }
		}
	    }
	} else if (c == 0) {
	    /*
	     * yrg. EOF -- bitch and get out
	     */
	    yyerror("end-of-file in false conditional starting on line %d",
		    startLine);
	    opp = NULL;
	    break;
	}
    }

    if (opp != NULL) {
	/*
	 * Make sure the user sees the token if it came from a macro and
	 * macro display was on on entry.
	 */
	if (oldsm && wasmacro) {
	    fprintf(stderr, "%.*s", cp2-word, word);
	}
	/*
	 * Broke out properly -- push the token back into the input stream
	 */
	while (--cp2 >= word) {
	    unput(*cp2);
	}
	/*
	 * Push a newline back into the input stream to
	 * account for the one we swallowed from the pushback
	 * queue when we were first called, else we'll get
	 * an error for the rule that was false...
	 *
	 * Set bumpLine false to account for conditionals that actually
	 * read the newline for the IF line as the lookahead token (both
	 * IF and IFE have to do this to determine the end of the
	 * expression). We want the newline we shove back to cause the line
	 * number to increment.
	 */
	bumpLine = 0;
	unput('\n');
	if (!wasmacro) {
	    yylineno -= 1;
	}
    }
    showmacro = oldsm;
}

/*
 * Local Variables:
 * c-label-offset: -4
 * end:
 */
