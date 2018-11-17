/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  uic -- lexical analyzer
 * FILE:	  scan.c
 *
 * AUTHOR:  	  Tony Requist
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	yylex	  	    Scan off a token and return it
 *	Scan_Init 	    Initialization function
 *
 * DESCRIPTION:
 *	Lexical analyzer for uic.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: scan.c,v 2.31 93/10/22 17:18:21 cassie Exp $";
#endif lint

#include    <config.h>
#include    "uic.h"
#include    "parse.h"
#include    "sttab.h"
#include    "map.h"

#include    <ctype.h>

#include    <compat/string.h>

/* these define atof in different OSes */
#include    <compat/stdlib.h>
#include    <math.h>

/*
 * External interface variables
 */
extern YYSTYPE 	  yylval;
int 	    	  lexdebug=0;
#ifdef LEXDEBUG
#define DBPRINTF(args) if(lexdebug){ fprintf args; }
#else
#define DBPRINTF(args)
#endif /* LEXDEBUG */

/* FILE	    	  *yyin = stdin; */
int	    	  yylineno=1;

int		  scanStringEndBrace = FALSE;

Scope		  *visMonikerScope;
Scope		  *kbdAcceleratorScope;


#ifndef MAX_TOKEN_LENGTH
#define MAX_TOKEN_LENGTH    150000
#endif /* MAX_TOKEN_LENGTH */
static char    	  yytext[MAX_TOKEN_LENGTH];

/*
 * Structure defining a reserved word
 */
typedef struct _ReservedWord {
    char    *name;
    int	    token;
} 	ReservedWord;

/*
 * Keyword determination
 */
static Hash_Table  reservedWords;    /* Table of opcodes hashed by name */
ReservedWord	    	  *isReservedWord();

#define input() getc(yyin)
#define unput(c) ungetc(c, yyin)

char
readlit(void)
{
    char c;

readlit_loop:
    c = input();
    if (c == '\\') {
	if ((c = input()) == '\n') {
	    yylineno++;
    	    goto readlit_loop;
	} else {
    	    /*
     	    * Anything else and we return the backslash unharmed.
     	    */
    	    unput(c);
    	    return('\\');
	}
    }
    return(c);
}

typedef struct {
    int token;
    Symbol *sym;
} LexPair;

#define	LEX_STACK_SIZE	10
LexPair	lexStack[LEX_STACK_SIZE];
int	lexStackPtr = 0;

void
lexpush(int token, Symbol *sym)
{
    lexStack[lexStackPtr].token = token;
    lexStack[lexStackPtr].sym = sym;
    lexStackPtr++;
    DBPRINTF((stderr, "pushing lex token %d\n",token))
}



/***********************************************************************
 *				yylex
 ***********************************************************************
 * SYNOPSIS:	  Scan a token out of the input stream and return it.
 * CALLED BY:	  yyparse
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
yylex(void)
{
    register int  c;
    register char *cp;
    int	c2;
    int floatFlag;
    Hash_Entry	*entry;

    /*
     * If values on the pushback stack then return them
     */

    if (lexStackPtr != 0) {
	DBPRINTF((stderr,
		  "reading pushed token %d\n",
		  lexStack[lexStackPtr-1].token))
	yylval.sym = lexStack[lexStackPtr-1].sym;
	return(lexStack[--lexStackPtr].token);
    }

    /*
     *If in special mode then do it
     */

    if (scanStringEndBrace) {
	int 	level = 0;
    	char    errMess[80];

	DBPRINTF((stderr, "reading special string literal (until '}')..."));
	cp = yytext;
	while ((c = input()) != 0) {
	    switch(c) {
		case '\\':
		    *cp++ = c;
		    if ( (cp - yytext) >= MAX_TOKEN_LENGTH ) {
			strncpy(errMess, yytext, 80);
			FatalError("token {%s...} too long", errMess);
		    }
		    c = input();
		    if (c == 0) {
			goto haveSpecialString;
		    }
		    break;
		case '{':
		    level++;
		    break;
		case '}':
		    if (level-- == 0) {
			goto haveSpecialString;
		    }
		    break;
		case '\n':
		    yylineno++;
		    break;
	    }
	    *cp++ = c;
	    if ( (cp - yytext) >= MAX_TOKEN_LENGTH ) {
		strncpy(errMess, yytext, 80);
		FatalError("token {%s...} too long", errMess);
	    }
	}
	haveSpecialString:

	DBPRINTF((stderr, "done\n"));
	if (c == 0) {
	    yyerror("end-of-file in string constant");
	    return(0);
	}
	unput(c);
	*cp++ = '\0';
	yylval.string = String_Enter(yytext, strlen(yytext));
	DBPRINTF((stderr,
		  "returning special string <%s>\n",
		  yylval.string));
	return(STRING);
    }

    /*
     * Skip initial whitespace
     */
 again:
    while( isspace( c = input() ) ) {
	if (c == '\n') {
	    yylineno++;
	}
    }

    switch(c) {
    case '#':
	/*
	 * From pre-processor -- indicates line # and file name
	 */
	fscanf(yyin," %d %s", &yylineno, inFile);
	DBPRINTF((stderr, "reading cpp info, line #%d, file %s ...", \
							yylineno,inFile));
	while(((c = input()) != '\n') && (c != 0)) {
	    ;
	}
	DBPRINTF((stderr, "done\n"));
	goto again;
    case '<':
    case '>':
    case '{':
    case '}':
    case '(':
    case ')':
    case '=':
    case ';':
    case ':':
    case ',':
    case '+':
	/*
	 * Operator character -- return it
	 */
return_c:
	DBPRINTF((stderr, "returning '%c'\n", c));
	return(c);
    case EOF:
	/*
	 * Handle the last localizable chunk at the end of the file.
	 */
	if ( localizationWarning && localizationRequired ){
	    Parse_LastChunkWarning("Missing @localize instruction");
	    localizationRequired = 0;
	}

	/*
	 * End of file. Try and wrap it up.
	 */
	DBPRINTF((stderr, "all done\n"));
	return 0;
    case '\"':
	cp = yytext;
      getMoreString:
	DBPRINTF((stderr, "reading string literal..."));
	while (((c = input()) != '"') && (c != 0) && (c != '\\')
							&& (c != '\n')) {
	    *cp++ = c;
	}
	if (c == '\\') {
	    if ((c = input()) == '\n') {
		yylineno++;
		goto getMoreString;
	    } else {
		/*
		* Use anything else
		*/
		*cp++ = c;
		goto getMoreString;
	    }
	}

	DBPRINTF((stderr, "done\n"));
	if (c == '\n') {
	    yylineno++;
	    yyerror("non terminated string constant");
	    return(0);
	}
	if (c == 0) {
	    yyerror("end-of-file in string constant");
	    return(0);
	}
		/* Check for back to back string constants */
	while( isspace( c = input() ) ) {
	    if (c == '\n') {
		yylineno++;
	    }
	}
	if (c == '"') {
	    goto getMoreString;
	}
	unput(c);

	*cp++ = '\0';

	yylval.string = String_Enter(yytext, strlen(yytext));
	DBPRINTF((stderr, "returning string <%s>\n", yylval.string));
	return(STRING);
    case '\'':
	c = readlit();
	if (c == 0) {
	    yyerror("end-of-file in character constant");
	    return(0);
	}
	c2 = input();
	if (c2 !='\'') {
	    yyerror("malformed character constant");
	    unput(c2);
	}
	yylval.ch = c;
	DBPRINTF((stderr, "returning char #%d <%c>\n", yylval.ch, yylval.ch));
	return(CHAR);

    case '-':
	c2 = input();			/* take a peek */
	unput(c2);
	if ( !isdigit(c2) ) {
	    goto return_c;
	}
	/* else fall thru */
    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9':
	cp = yytext;

	*cp++ = c;
	floatFlag = FALSE;
	while (1) {
	    c = input();
	    if (!isdigit(c) && (c != '.')) {
		break;
	    }
	    *cp++ = c;
	    if (c == '.') {
		floatFlag = TRUE;
	    }
	}
	unput(c);
	*cp++ = '\0';
	if (floatFlag) {
	    yylval.floatNum = atof(yytext);
	    DBPRINTF((stderr, "returning float <%f>\n", yylval.floatNum));
	    return(CONST_FLOAT);
	} else {
	    yylval.fixedNum = atoi(yytext);
	    DBPRINTF((stderr, "returning fixed <%ld>\n", yylval.fixedNum));
	    return(CONST_FIXED);
	}

    default: {
	ReservedWord  *opp;

	if (!isalpha(c) && (c != '_')) {
	    yyerror("Extraneous character 0x%02.2x discarded", c);
	    goto again;
	}
	cp = yytext;

	*cp++ = c;
	while (1) {
	    c = input();
	    if (!isalnum(c) && (c != '_')) {
		break;
	    }
	    *cp++ = c;
	}
	unput(c);
	*cp++ = '\0';

	cp = String_Enter(yytext, strlen(yytext));
	entry = Hash_FindEntry(&reservedWords, cp);
	if (entry != NullHash_Entry) {
	    opp = (ReservedWord *)Hash_GetValue(entry);
#ifdef LEXDEBUG
#ifdef YYDEBUG
	    if (opp->token == SPECIAL_DEBUG_TOKEN) {
		lexdebug = yydebug = symdebug = outdebug = 1;
		DBPRINTF((stderr, "\n**** DEBUGGING ON (line %d) ****\n\n",\
								yylineno));
		goto again;
	    }
	    if (opp->token == SPECIAL_UNDEBUG_TOKEN) {
		lexdebug = yydebug = symdebug = outdebug = 0;
		DBPRINTF((stderr, "\n**** DEBUGGING OFF (line %d) ****\n\n",\
								yylineno));
		goto again;
	    }
#endif
#endif
	    DBPRINTF((stderr, "returning reserved word <%s>\n", opp->name));
	    yylval.sym = NullSymbol;
	    return(opp->token);
	} else {
	    Symbol *sym;

		/*
		 * If the string is a symbol then return the symbol
		 */
	    sym = Symbol_Find(cp,ALL_SCOPES);
	    if (sym != NullSymbol) {
		/*
		 * Special hack for version 2.0 -- since we recognize "hints"
		 * as a special reserved word (see below), we cannot allow it
		 * to be a normal symbol
		 */
		if ((version20) && (!strcmp(cp,"hints"))) {
		    yyerror("cannot have 'hints' as a symbol");
		    return(0);
		}
		yylval.sym = sym;
		DBPRINTF((stderr, "returning sym #%d, <%s>\n", sym->type, cp));
		return (sym->type);
	    }
	    /*
	     * Special hack for version 2.0 -- recognize "hints" as a special
	     * substitute keyword for the "varData" reserved word, return the
	     * VAR_DATA token
	     */
	    if ((version20) && (!strcmp(cp,"hints"))) {
		return(VAR_DATA);
	    }
	    yylval.string = cp;
	    DBPRINTF((stderr, "returning identifier <%s>\n", yylval.string));
	    return(IDENT);
	}
    }
    }
}

/*
 * Table of keywords that are reserved.
 */
static ReservedWord keywords[] = {
#ifdef LEXDEBUG
#ifdef YYDEBUG
    {"__DEBUG_HERE__", SPECIAL_DEBUG_TOKEN},
    {"__UNDEBUG_HERE__", SPECIAL_UNDEBUG_TOKEN},
#endif
#endif
/*
 * Components
 */
    {"byteComp", BYTE_COMP},
    {"typeComp", TYPE_COMP},
    {"wordComp", WORD_COMP},
    {"dwordComp", DWORD_COMP},
    {"fptrComp", FPTR_COMP},
    {"bitFieldComp", BIT_FIELD_COMP},
    {"enumComp", ENUM_COMP},
    {"compositeComp", COMPOSITE_COMP},
    {"linkComp", LINK_COMP},
    {"visMonikerComp", VIS_MONIKER_COMP},
    {"kbdAcceleratorComp", KBD_ACCELERATOR_COMP},
    {"hintComp", HINT_COMP},
    {"helpComp", HELP_COMP},
    {"optrComp", OPTR_COMP},
    {"actionComp", ACTION_COMP},
    {"activeListComp", ACTIVE_LIST_COMP},
    {"nptrComp", NPTR_COMP},
    {"hptrComp", HPTR_COMP},

/*
 *	To add a component, add a line here:    "biffComp", BIFF_COMP,
 */

/*
 * Other reserved words
 */
    {"structure", STRUCTURE},
    {"class", CLASS},
    {"static", STATIC},
    {"default", DEFAULT},
    {"visMoniker", VIS_MONIKER},
    {"hintList", HINT_LIST},
    {"helpEntry", HELP_ENTRY},
    {"activeList", ACTIVE_LIST},
    {"chunk", CHUNK},

    {"byte", BYTE},
    {"word", WORD},
    {"dword", DWORD},
    {"meta", META},
    {"master", MASTER},
    {"variant", VARIANT},

    {"kbdPath", KBD_PATH},
    {"null", NULL_TOKEN},
    {"empty", EMPTY},
    {"data", DATA},
    {"process", PROCESS},
    {"start", START},
    {"end", END},
    {"ignoreDirty", IGNORE_DIRTY},
    {"vardataReloc", VARDATA_RELOC},
    {"notDetachable", NOT_DETACHABLE},
    {"specificUI", SPECIFIC_UI},

    {"PrintMessage", PRINT_MESSAGE},
    {"ErrorMessage", ERROR_MESSAGE},
    {"version20", VERSION20},
    {"varData", VAR_DATA},
    {"resourceOutput", RESOURCE_OUTPUT},
    {"gcnList", GCN_LIST},
    {"localize", LOCALIZE},
    {"not", NOT},

    {"gstring", GSTRING},

    {"extern", EXTERN}
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
    {"list",		LIST_SYM,		0},

    /* this is used for 1.2 only */
    {"attributes",	ATTRIBUTES_SYM,		0},

    {"color",		COLOR_SYM,		0},
    {"size",		SIZE_SYM,		0},
    {"aspectRatio",	ASPECT_RATIO_SYM,	0},
    {"cachedSize",	CACHED_SIZE_SYM,	0},

    /* this is used for 2.0 only */
    {"style",		STYLE_SYM,		0},

    /* these are used for 1.2 only */
    {"gstringText",	ATTRIBUTES_COMP_SYM,	V12_VMT_GS_TEXT},
    {"abbreviatedText",	ATTRIBUTES_COMP_SYM,	V12_VMT_ABBREV_TEXT},

    /* these are in 2.0 only */
    {"text",		STYLE_COMP_SYM,		(0 << V20_VMT_STYLE_FIELD)},
    {"abbrevText",	STYLE_COMP_SYM,		(1 << V20_VMT_STYLE_FIELD)},
    {"graphicText",	STYLE_COMP_SYM,		(2 << V20_VMT_STYLE_FIELD)},
    {"icon",		STYLE_COMP_SYM,		(3 << V20_VMT_STYLE_FIELD)},
    {"tool",		STYLE_COMP_SYM,		(4 << V20_VMT_STYLE_FIELD)},

    {"tiny",		SIZE_COMP_SYM,		(0 << VMT_GS_SIZE_FIELD)},
    {"standard",	SIZE_COMP_SYM,		(1 << VMT_GS_SIZE_FIELD)},
    {"large",		SIZE_COMP_SYM,		(2 << VMT_GS_SIZE_FIELD)},
    {"huge",		SIZE_COMP_SYM,		(3 << VMT_GS_SIZE_FIELD)},

    {"gray1",		COLOR_COMP_SYM,		(1 << VMT_GS_COLOR_FIELD)},
    {"gray2",		COLOR_COMP_SYM,		(2 << VMT_GS_COLOR_FIELD)},
    {"gray4",		COLOR_COMP_SYM,		(3 << VMT_GS_COLOR_FIELD)},
    {"gray8",		COLOR_COMP_SYM,		(4 << VMT_GS_COLOR_FIELD)},
    {"color2",		COLOR_COMP_SYM,		(5 << VMT_GS_COLOR_FIELD)},
    {"color4",		COLOR_COMP_SYM,		(6 << VMT_GS_COLOR_FIELD)},
    {"color8",		COLOR_COMP_SYM,		(7 << VMT_GS_COLOR_FIELD)},
    {"colorRGB",	COLOR_COMP_SYM,		(8 << VMT_GS_COLOR_FIELD)},

    {"normal",		ASPECT_RATIO_COMP_SYM, (0 << VMT_GS_ASPECT_RATIO_FIELD)},
    {"squished",	ASPECT_RATIO_COMP_SYM, (1 << VMT_GS_ASPECT_RATIO_FIELD)},
    {"verySquished",	ASPECT_RATIO_COMP_SYM, (2 << VMT_GS_ASPECT_RATIO_FIELD)}
};

static SpecialSym kbdSyms[] = {
    {"alt",		KBD_MODIFIER_SYM,	M_ALT},
    {"control",		KBD_MODIFIER_SYM,	M_CTRL},
    {"ctrl",		KBD_MODIFIER_SYM,	M_CTRL},
    {"shift",		KBD_MODIFIER_SYM,	M_SHIFT},

    {"NUMPAD_0",	KBD_SYM,    	(KEY_NAVIGATION << 16) | '0'},
    {"NUMPAD_1",	KBD_SYM,    	(KEY_NAVIGATION << 16) | '1'},
    {"NUMPAD_2",	KBD_SYM,    	(KEY_NAVIGATION << 16) | '2'},
    {"NUMPAD_3",	KBD_SYM,    	(KEY_NAVIGATION << 16) | '3'},
    {"NUMPAD_4",	KBD_SYM,    	(KEY_NAVIGATION << 16) | '4'},
    {"NUMPAD_5",	KBD_SYM,    	(KEY_NAVIGATION << 16) | '5'},
    {"NUMPAD_6",	KBD_SYM,    	(KEY_NAVIGATION << 16) | '6'},
    {"NUMPAD_7",	KBD_SYM,    	(KEY_NAVIGATION << 16) | '7'},
    {"NUMPAD_8",	KBD_SYM,    	(KEY_NAVIGATION << 16) | '8'},
    {"NUMPAD_9",	KBD_SYM,    	(KEY_NAVIGATION << 16) | '9'},
    {"NUMPAD_PLUS",    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '+'},
    {"NUMPAD_MINUS",   	KBD_SYM,    	(KEY_NAVIGATION << 16) | '-'},
    {"NUMPAD_DIV",    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '/'},
    {"NUMPAD_MULT",    	KBD_SYM,    	(KEY_NAVIGATION << 16) | '*'},
    {"NUMPAD_PERIOD",   KBD_SYM,    	(KEY_NAVIGATION << 16) | '.'},
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
    ReservedWord  *opp;
    SpecialSym	  *vmp;
    Symbol	  *sym;
    Hash_Entry	  *entry;
    Boolean 	  new;
    int	    	  i;

    Hash_InitTable(&reservedWords, 16, HASH_ONE_WORD_KEYS, 5);

    i = sizeof(keywords)/sizeof(keywords[0]);
    for (opp = keywords; i > 0; opp++, i--) {
	entry = Hash_CreateEntry(&reservedWords,
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
}
