%{
/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  goc -- parser
 * FILE:	  parse.y
 *
 * AUTHOR:  	  Tony Requist
 *
 * DESCRIPTION:
 *	A grammar to parse a goc file
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: parse.y,v 1.122 96/07/09 12:46:37 adam Exp $";

#endif /*lint*/

#include <config.h>

#define YYERROR_VERBOSE	/* Give the follow set in parse error messages */

#include <ctype.h>

#include "goc.h"
#include "map.h"
#include "scan.h"
#include "stringt.h"
#include "assert.h"
#include "symbol.h"
#include <config.h>

// Required for void type def
#undef __WATCOMC__
#include <malloc.h>
#define __WATCOMC__

#include <compat/string.h> 

#include <symbol.h>

#define bison_malloc(x) (void*)malloc((size_t)x)
#define YYMALLOC bison_malloc

#define bison_free(x) (void)free(x)
#define YYFREE bison_free

/* Initial size of gstring buffer. If this changes, change */
/* GET_NEW_GS_BUF_SIZE() */
#define GS_BUF 256
dynamic_buffer gstringBuf;

/* 
 * We only have one ObjMessage, because we only parse one at a time.    
 * the objMessage rule's semantic value is always the address of this 
 * struct.  
 */
SentMessage  objMessage;     


/* 
 *   A variable to tell the scanner that we're scanning a chunk's
 *   definition and that the identifier should have an '@' before it.
 */ 

Boolean	parse_ScanningAChunk = FALSE;


/*
 * Again only one of these, because we only parse one at a time.
 */

ObjDest  objDest;  /* the destination of the current object being parsed */

/* for parsing VisMonikers */
Boolean haveVMStyle = FALSE;


Symbol 	*chunkToLocalize; /* last chunk declared */

Symbol *classBeingParsed = NullSymbol;

Symbol *curProtoMinor = NullSymbol;

Symbol *classDeclList = NullSymbol;

int currentMPD, numRegs, stackParams, forceRegs, forceNoRegs, multipleReturn;

MethodModels	defaultModel = MM_FAR;

int	specificUI = 0;			/* Allow specific UI shortcuts */


Method *curMethod = NullMethod;   /* needed so method's code can call super*/

Symbol *curMessage = NullSymbol;

char *currentMessageReturnType;

Symbol *curResource = NullSymbol;

Symbol *undefinedList = NullSymbol;

Symbol *resourceList = NullSymbol;

Symbol *curObject = NullSymbol;

Symbol *curVisMoniker = NullSymbol;

Symbol *curVisMonField = NullSymbol;

Symbol 		*curFirstChild;
InstanceValue 	*curLastChild;
Symbol 		*curLastChildObj;
Symbol 		*curLinkPart;

char *curStringType;

Symbol *methClass;
int methModel;
char *methName;
Symbol *methFirst;

char *relocString;
Symbol *relocSym;
char *relocStruct;

char *caHeaderType;
char *caHeaderData;

int realSymbolLineNumber;

Boolean	localizationRequired = FALSE;
/***/

void OutputInstanceData(Symbol *class);

Symbol *MakeInstanceVar(int type, char *name, char *ctype);

InstanceValue *MakeInstanceValue(Symbol *object);

void AddRegDefinition(MessagePassRegs reg);

void GenerateMethodDef(Method *meth);

void GenerateCurRootDefine(Method *meth);

void GenerateReturnType(MsgInvocType mit, Symbol *msgSym, Boolean children);

void GeneratePrototype(MsgInvocType mit, Symbol *Msg, ObjDest *od);

void GenerateComplexPrototype(MsgInvocType mit, Symbol *passMsg,
			      Symbol *retMsg,  ObjDest *od);

char * GenerateComplexMPDString(Symbol *passMsg,Symbol *retMsg, 
				MsgParamPassEnum paramSpec);



char *String_EnterZT(char *s);

void AddChunkToCurResourceAndOutputExtern(Symbol *sym);

void AddChunkToUndefinedList(Symbol *sym);

Symbol *EnterSymbolInGlobal(char *name, int type, int flags);

void AddReloc(Symbol *tag, int type, char *text, int count, char *structName);
void NoReloc(Symbol *instance);

void AddVarData(Symbol *vdSym, char *value,char *arraySize);

static void LocalizationCheck(void);

static int CheckRelated(Symbol *curClass,
			Symbol *otherClass,
			Symbol *bottomClass);

static void AddStringToCurrentGstringBuffer(char *ptr);
static void AddStringCharsToCurrentGstringBuffer(char *ptr);
static void ErrCheck (void);

/*
 * Flags to ObjMessage
 */

#define MF_CALL				0x8000
#define MF_FORCE_QUEUE			0x4000
#define MF_STACK			0x2000
#define MF_RETURN_ERROR			0x1000
#define MF_CHECK_DUPLICATE		0x0800
#define MF_CHECK_LAST_ONLY		0x0400
#define MF_REPLACE			0x0200
#define MF_CUSTOM			0x0100
#define MF_FIXUP_DS			0x0080
#define MF_FIXUP_ES			0x0040
#define MF_DISCARD_IF_NO_MATCH		0x0020
#define MF_MATCH_ALL			0x0010
#define MF_INSERT_AT_FRONT		0x0008
#define MF_CAN_DISCARD_IF_DESPERATE	0x0004
#define MF_RECORD   	    	    	0x0002


/* 
 *  These macros are used on the structs used to hold type-declaration-like
 *  quantities. They are used for methods, messages, vardata, chunks, etc.
 *  
 *  The scanner used to have modes that would return the different pieces
 *  of a type-decl as a bunch of tokens, but now it returns a string and
 *  the parser has to break the string up into three strings. see
 *  the rule below for TypeDeclString
 */
#define AllocTypeDeclString() \
       ((TypeDeclString *) zmalloc(sizeof(TypeDeclString)))
#define TDS_CTYPE(foo) ((foo)->ct)
#define TDS_IDENT(foo) ((foo)->id)
#define TDS_TYPESUF(foo) ((foo)->ts)

#define TDS_TYPESUF_IS_NOT_NULL(x) ( '\0' != *(TDS_TYPESUF(x)))



#define FreeTypeDeclStringAndContents(foo) (free(TDS_CTYPE(foo)), \
	 free(TDS_IDENT(foo)),free(TDS_TYPESUF(foo)),free(foo))


#define REMOVE_LOCALIZATION_DATA(c) 	     do{      \
    if(CHUNK_LOC(c)){                                 \
	free(CHUNK_LOC(c));                 \
        CHUNK_LOC(c) = NULL;                          \
    }                                                 \
}while(0)


/* 
 * Classes need to have a linked-list of their message symbols, so that
 * they can output an enum upon seeing the @endc.
 *
 * These two macros are for initializing the class's message list, and
 * adding an element to the list.
 */

#define INIT_CLASS_MESSAGE_LIST(class) do{                                 \
    (class)->data.symClass.nextMessageElementPtr =                         \
     &((class)->data.symClass.firstMessagePtr);                            \
    (class)->data.symClass.firstMessagePtr = (Symbol *)NULL;  }while (0)   



#define ADD_MESSAGE_LIST_ELEMENT(class,symbolPtr)      do{               \
     *class->data.symClass.nextMessageElementPtr = symbolPtr;            \
      class->data.symClass.nextMessageElementPtr =                       \
	&(symbolPtr->data.symMessage.nextMessage);                       \
      symbolPtr->data.symMessage.nextMessage = (Symbol *)NULL; } while(0)

static int oldContext;

#define SWITCH_CONTEXT(x)  do{oldContext=lexContext;lexContext=(x);}while(0)


/***********************************************************************
 *		          Parse_SetReturnAndPassMessage
 ***********************************************************************
 * SYNOPSIS:    set contents of returnForThisMsg & contents of passForThisMsg
 *              to the Symbol *'s of the message for passing and returning.
 *            
 *              This is used to resolve the kinds of casts that a message
 *              construct should have, given that there are optional 
 *              casts and messages.
 *
 *               If the message invocation type always has the same
 *               returnvalues, this will set the contents of 
 *               returnForThisMsg to NULL.
 *
 * PASS:
 * 	        type of msg invocation
 *              return-cast 
 *              pass-cast
 * 		msg sent
 *		pointer to return-type symbol
 * 		pointer to pass-type symbol
 *
 * RETURN:      void
 *
 * ERROR:  	If there is an error, *passForThisMsg will == NullSymbol.
 *
 * CALLED BY:	sendOrCallOrRecord
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	josh	9/21/92		Initial Revision
 *
 ***********************************************************************/
#define RETURN_WITH_ERROR() \
    do {                                                \
       *passForThisMsg = NullSymbol;                    \
       return;                                          \
    } while(0)

inline void
Parse_SetReturnAndPassMessage(MsgInvocType mit,
			      Symbol *castRet, 
			      Symbol *castPass,
			      Symbol *objmsg,
			      Symbol **returnForThisMsg,
			      Symbol **passForThisMsg)
{
    /* first determine how to pass args  */

    *passForThisMsg = 
	(castPass 	!= NullSymbol ? castPass:   /* first is castPass */
	 (objmsg 	!= NullSymbol? objmsg	:   /* second is msg    */
	  (castRet 	!= NullSymbol ? castRet :  /* third is castRet*/
	   NullSymbol)));

    if (*passForThisMsg == NullSymbol) {

	yyerror("can't determine how to pass parameters");
	RETURN_WITH_ERROR();
    }

    if (!IS_CALL_TYPE(mit)) {
	*returnForThisMsg = NullSymbol;
	/* 
	 * if the cast doesn't get used for passing (and it exists),
	 * they probably don't intend for it to be here.
	 */
	if (castRet != NullSymbol && castRet != *passForThisMsg) {
	    yywarning("return value cast ignored. perhaps you want @call?");
	}
    } else {
	/* set the return value, and check to see if it is bad */
	*returnForThisMsg = 
	    (castRet 	!= NullSymbol ? castRet	:   /* first is castRet */
	     (objmsg 	!= NullSymbol ? objmsg	:   /* second is msg    */
	      (castPass != NullSymbol ? castPass :  /* third is castPass*/
	       NullSymbol)));
	if (*returnForThisMsg == NullSymbol) {
	    yyerror("can't determine how to cast return values");
	    RETURN_WITH_ERROR();
	}

	/* 
	 * Try to be helpful and catch a nasty runtime error now. 
	 *
	 * If the return cast and the msg are different, and either of
	 * them returns multiple values, the cast will never work, 
	 * because there is no way to figure out what registers to put
	 * the return values in.
	 *
	 * We don't check against castPass because we only use it for
	 * passing if there is no other cast/msg specified, and there 
	 * won't be a conflict with itself.
	 */

	if (*returnForThisMsg != objmsg	      	&& 
	    objmsg != NullSymbol    		&&
	    (((objmsg->data.symMessage.mpd & MPD_RETURN_TYPE) ==
	      (MRT_MULTIPLE << MPD_RETURN_TYPE_OFFSET)) ||
	    (((*returnForThisMsg)->data.symMessage.mpd & MPD_RETURN_TYPE) ==
	     (MRT_MULTIPLE << MPD_RETURN_TYPE_OFFSET))))
	{
	    yyerror("cannot cast between messages with multiple "
		    "return values");
	    RETURN_WITH_ERROR();
	}
    }
    if ((castRet != NullSymbol && castRet == objmsg) ||
        (castPass != NullSymbol && castPass == objmsg))
    {
	yywarning("cast and message sym are identical. Cast has no effect");
    }
}
%}

/*
 *	Type returned by yylex()
*/
%union {
    char	*string;
    char	ch;
    int		num;
    Symbol	*sym;
    Method  	*meth;
    MessageParam	*param;
    SymbolListEntry	*sle;
    TypeDeclString      *tdecl;
    ObjDest		*od;
    SentMessage		*sm;
    MsgInvocType	mit;
}

/*
 *****************************************************************************
 *			Declarations
 */

/*
 *	Starting token to try to parse
 */
%start		file

/*
 * Reserved words
 *	These are scarfed by the scanner which returns these tokens.  The
 *	value passed with the token is the string for the reserved word.
 */

%token <string>	CLASS META MASTER VARIANT ENDC CLASSDECL NEVER_SAVED
%token <string>	MESSAGE STACK CARRY AX CX DX BP AL AH CL CH DL DH BPL BPH SS
%token <string>		AXBPCXDX AXCXDXBP CXDXBPAX DXCX BPAXDXCX MULTIPLEAX
%token <string>	ALIAS PROTOTYPE
%token <string>	RESERVE_MESSAGES EXPORT_MESSAGES IMPORT_MESSAGE SET_MESSAGE_NUM
%token <string>	INSTANCE COMPOSITE LINK VIS_MONIKER KBD_ACCELERATOR
%token <string> DEFAULT
%token <string>	RELOC FPTR HPTR OPTR
%token <string>	DEFAULT_MODEL METHOD FAR NEAR BASED
%token <string>	CALL CALL_SUPER SEND RECORD DISPATCH DISPATCHCALL
%token <string>	FORCE_QUEUE RETURN_ERROR CHECK_DUPLICATE NO_FREE
%token <string>	CHECK_LAST_ONLY REPLACE INSERT_AT_FRONT CAN_DISCARD_IF_DESPARATE
%token <string>	NULL_TOKEN PARENT CHILDREN LOCALIZE
%token <string>	COMPILER HIGHC MSC START DATA NOT_LMEM NOT_DETACHABLE END
%token <string>	HEADER CHUNK CHUNK_ARRAY ELEMENT_ARRAY OBJECT SPECIFIC_UI
%token <string> KBD_PATH RESOURCE_OUTPUT
%token <string>	VARDATA VARDATA_ALIAS IGNORE_DIRTY DEFLIB ENDLIB EXTERN
%token <string> GCN_LIST PROTOMINOR PROTORESET
%token <string> OPTIMIZE NORELOC
%token		USES NOT

/*
 * Symbols
 *	The scanner looks up all identifiers in the symbol table and returns
 *	the following tokens when symbols are found.  These tokens are the
 *	type for the symbol
 */
%token <sym> 	FIRSTSYM /*XXX XXX put all symbols after this one XXX XXX*/
%token <sym> 	CLASS_SYM OBJECT_SYM MSG_SYM EXPORT_SYM RESOURCE_SYM
%token <sym> 	CHUNK_SYM VIS_MONIKER_CHUNK_SYM 
%token <sym>	VARDATA_SYM PROTOMINOR_SYM
%token <sym> 	REG_INSTANCE_SYM COMPOSITE_SYM LINK_SYM VIS_MONIKER_SYM
		VARIANT_PTR_SYM
%token <sym> 	KBD_ACCELERATOR_SYM
%token <sym> 	OPTR_SYM CHUNK_INST_SYM

%token <sym>	LIST_SYM GSTRING_SYM ATTRIBUTES_SYM COLOR_SYM SIZE_SYM
%token <sym>	ASPECT_RATIO_SYM CACHED_SIZE_SYM 
%token <sym>	SIZE_COMP_SYM COLOR_COMP_SYM ASPECT_RATIO_COMP_SYM
%token <sym>	STYLE_SYM STYLE_COMP_SYM
%token <sym>	KBD_SYM KBD_MODIFIER_SYM
%token <sym>	GCN_LIST_SYM GCN_LIST_OF_LISTS_SYM
%token <sym> 	LASTSYM /*XXX XXX put all symbols before this one XXX XXX*/
/*
 * Debugging support
 *	Special tokens for debugging
 */
%token	SPECIAL_DEBUG_TOKEN
%token  SPECIAL_UNDEBUG_TOKEN

/*
 * Lexical tokens
 *	These tokens are returned by the scanner when it scans a lexical type
 *	that is recognizes.  Note that the scanning of some of these tokens
 *	are heavily dependant on the current context.
 */
%token <string>	IDENT STRING FAKESTRING
%token <string> ASCIISTRING LSTRING SJISSTRING TSTRING
%token <ch>	CHAR
%token <num>	CONST 



/*
 * Non-terminal symbols
 *	These tokens are intermediate stages during parsing.
 */

%type <sym>	superClass
%type <num>	classFlags classDeclFlags ignoreDirtyFlag cArrayType
%type <sym>	instanceLineType defaultableSym
%type <string>	instanceDefault optionalArraySize

%type <num> 	relocType relocCount

%type <param>	messageParamListOrNull messageParamList messageParam

%type <num>	wordParamReg multipleParamReg wordReturnReg

%type <num>	reserveNum setMessageNum exportNum

%type <num>	methodModel
%type <meth>	methodMessageList methodMessage
%type <sym>	importMessagePrefix

%type <num>	ObjFlagListOrNull objFlag

%type <num>	startFlags

%type <sym>	objectOrIdent visMonikerOrIdent messageSymOrIdentErr

%type <sym>     dispatchOrDispatchCall  newDispatchOrDispatchCall
%type <sym>	exportSymOrError 

%type <sym>	optCastMessage 	optCastWithNoBraces vardataSymOrError
%type <sym>	classOrError  protoMinorSym

%type <sle>    	vmArray vmArrayElement

%type <num>    	kbdAccelChar specificUIOrNothing kbdAccelModList
%type <num>    	kbdPathOrNull  
%type <num>     externMethodOrMethod 
%type <string>  identCommaOrNothing
%type <ch>      openCurlyOrSemiColon
%type <sle>    	aleArrayN aleArray aleArrayElement

%type <string>	identOrConst someString
%type <string>  FakeStringOrNothing
%type <tdecl>   typeDeclString

%type <mit>     sendOrCallOrRecord
%type <od>      objDest
%type <sm>      objMessage
%type <num> 	semiOrParens
%type <string>  GStrings  simpleLocalization

%type <num>	numExpr primary

%%

/*
 *****************************************************************************
 *			Rules
*/

/*
 * A file is just a series of goc constructs. 
 * The lexer will blast out all other lines.
 */

file	:
 	{
	    /*
	     * Output a couple of macros that we need (compiler dependent)
	     */
	    switch (compiler) {
	    case COM_HIGHC:
	      /*
	       * Instruct Glue of true file name
	       */
	      Output("pragma Comment(\"@%s\");\n", inFile);
	      break;
	    case COM_BORL: case COM_MSC: case COM_WATCOM:
	      break;
	    }
	    /* output our first line directive */
	    OutputLineNumber(yylineno,curFile->name);
	}

    	lines
 	{
	    /*
	     * Do a few clean up checks.  We don't want to leave something
	     * open...
	     */
	    if (classBeingParsed != NullSymbol) {
		yyerror("End of file in class declaration (class %s)",
			    	    classBeingParsed->name);
	    }
	    if (curResource != NullSymbol) {
		yyerror("End of file in resource declaration (resource %s)",
			    	    curResource->name);
	    }
	}
    	;

lines	: lines line
        |
	;



/*
 * A line is one of several definition types.  Each is given its own
 * non-terminal for clarity.
 */
line    : classLine {}
	| endcLine {}
	| instanceLine {}
	| norelocLine {}
	| defaultLine {}
	| relocLine {}
	| classdeclLine {}
	| messageLine {}
	| aliasLine {}
	| prototypeLine {}
	| reserveMessagesLine {}
	| exportMessagesLine {}
	| importMessageLine {}
	| setMessageLine {}
        | methodLine {}
	| defaultModelLine {}
	| objectDerefLine {}
	| externLine {}
	| sendOrCallOrRecordLine {}
	| callsuperLine {}
        | dispatchOrDispatchCallLine   {}
        | newDispatchOrDispatchCallLine   {}
 	| compilerLine {}
	| startLine {}
	| endLine {}
	| headerLine {}
	| chunkLine {}
	| objectLine {}
	| visMonikerLine {}
	| LocalizationLine {}
	| vardataLine {}
 	| vardataAliasLine {}
	| protoMinorLine {}
	| protoResetLine {}
 	| deflibLine {}
 	| endlibLine {}
 	| resourceOutputLine {}
 	| SPECIFIC_UI { specificUI = TRUE; }
 	| error { ErrCheck(); SWITCH_CONTEXT(LC_NONE); }
 	| SPECIAL_DEBUG_TOKEN { SWITCH_CONTEXT( LC_NONE); }
 	| SPECIAL_UNDEBUG_TOKEN { SWITCH_CONTEXT( LC_NONE); }
	| optimizeline {SWITCH_CONTEXT( LC_NONE); }
	| usesLine
	;

optimizeline:	OPTIMIZE {
    if(whichToken == FIRST_OF_FILE){
	Scan_StartOptimize();
    }else{
	yyerror("@optimize must appear at the very start of a file.");
    }
}

/*
 * @noreloc VCNI_view;
 */
norelocLine: NORELOC OPTR_SYM ';'
	{
            NoReloc($2);
	}
	;

/*
 * @uses <class>(, <class>)*;
 */
usesLine: USES usesClassList ';'
	{
	    SWITCH_CONTEXT(LC_NONE);
	}
	| USES error ';'
	{
	    if (yychar == IDENT) {
		yyerror("%s is not a defined class.", $<string>1);
	    } else if (yychar > FIRSTSYM && yychar < LASTSYM) {
		if (yychar != CLASS_SYM) {
		    yyerror("%s is not a defined class.", $<sym>1->name);
		}
	    }
	    Scan_Unput(';');
	    yyerrok;
	    yyclearin;
	}
	;

usesClassList: CLASS_SYM
	{
	    if (classBeingParsed != NullSymbol) {
		Symbol_ClassUses(classBeingParsed, $1);
	    } else {
		yyerror("@uses is valid only inside a class definition.");
	    }
	}
	| usesClassList ',' CLASS_SYM
	{
	    if (classBeingParsed != NullSymbol) {
		Symbol_ClassUses(classBeingParsed, $3);
	    }
	    /* error case handled by above rule upon receiving first class */
	}
	;
	    

/*
 * @deflib name
 */

deflibLine  	:
    	DEFLIB IDENT
	{
	    DeflibNode *node;

	    node = (DeflibNode *) malloc(sizeof(DeflibNode));
	    node->next = deflibPtr;
	    node->name = (char *) malloc(strlen($2) + 1);
	    strcpy(node->name, $2);
	    deflibPtr = node;
	    SWITCH_CONTEXT( LC_NONE);
	}
	;

/*
 * @endlib
 */

endlibLine  	:
    	ENDLIB
	{
	    DeflibNode *node;

	    if (deflibPtr == NullDeflibNode) {
		yyerror("mismatched @deflib and @endlib");
	    } else {
	    	node = deflibPtr;
	    	deflibPtr = node->next;
		free(node->name);
		free(node);
	    }
	    SWITCH_CONTEXT( LC_NONE);
	}
	;

 semiColonOrError: ';' | error {yyerror("missing semicolon");}

/*
 * @class MyClass, GenClass, master
 *
 * Set classBeingParsed to the class symbol for class being parsed
 */

commaOrNothing: ',' | /* nothing */ ;

classLine	:
	CLASS IDENT commaOrNothing superClass   /* 1 2 4 */
	{
	    /*
	     * If a class is already being declared, give an error
	     */
	    if (classBeingParsed != NullSymbol) {
		yyerror("class %s declared before class %s closed",
			$2, classBeingParsed->name);
	    }
	    /*
	     * Enter the identifier as a class and create a local symbol
	     * table for it
	     */
	    classBeingParsed = Symbol_Enter($2, CLASS_SYM, SYM_DEFINED);

	    /*
	     * Reset the protoMinor stuff
	     *
	     */

	    curProtoMinor = NullSymbol;

	}
 	classFlags  semiColonOrError    /* 6 7 */
	{
    	    char iname[100];
    	    char *cp;
	    Symbol *class, *super, *bottomClass;

	    /* 
	     * prepare to insert the messages into the class's list. 
	     */

	    INIT_CLASS_MESSAGE_LIST(classBeingParsed);
	    
	    classBeingParsed->data.symClass.superclass = $4;
	    classBeingParsed->flags |= $6;
            classBeingParsed->data.symClass.classSeg = curResource;

	    /*
	     * Generate the root name of the class
	     */
	    strcpy(iname, $2);
	    for (cp = iname; *cp != '\0'; cp++) ;
	    if (!strcmp(cp-5, "Class")) {
		*(cp-5) = '\0';
	    }
	    classBeingParsed->data.symClass.root = String_EnterZT(iname);
	    /*
	     * Set the master level correctly (depends on whether this is
	     * a master class).  Set the first message for the class based
	     * on the first message for the superclass
	     */
	    if ($4 == NullSymbol) {
		classBeingParsed->data.symClass.localSymbols =
		    Symbol_NewScope(currentScope, FALSE);
	        classBeingParsed->data.symClass.firstMessage = 0;
		classBeingParsed->data.symClass.masterLevel = 0;
	    } else {
		if ($6 & SYM_CLASS_VARIANT) {
		    classBeingParsed->data.symClass.localSymbols =
		    	Symbol_NewScope(currentScope, FALSE);
		} else {
		    classBeingParsed->data.symClass.localSymbols =
		    	Symbol_NewScope($4->data.symClass.localSymbols, FALSE);
		}
		/*
		 * Check for this class being ProcessClass or a subclass
		 * thereof.  This affects the method definitions
		 */
		if (!strcmp($2, "ProcessClass") ||
		    ($4->flags & SYM_PROCESS_CLASS)) {
			classBeingParsed->flags |= SYM_PROCESS_CLASS;
		}
		classBeingParsed->data.symClass.masterLevel =
		    $4->data.symClass.masterLevel;
		/*
		 * Output base structure for this class
		 */
		if ((classBeingParsed->data.symClass.superclass != NullSymbol)
		    	&& !(classBeingParsed->flags & SYM_PROCESS_CLASS))
		{
		    if ($6 & SYM_CLASS_MASTER) {
			Output("typedef struct {%sBase %s_metaBase; word %s_offset; } %sBase;",
			       classBeingParsed->data.symClass.superclass->
			       data.symClass.root,
			       classBeingParsed->data.symClass.root,
			       classBeingParsed->data.symClass.root,
			       classBeingParsed->data.symClass.root);

#if 0
			/* This was moved to happen where the @classdecl occurs
			 * so there's only one of these variables in
			 * existence for each class */
			if (compiler == COM_BORL) {
			    /* put out a bogus segment with a variable
			     * of ClassBase so glue will get type info
			     * so pobj on objects whose classes are
			     * sub classes of Master Classes defined in GOC
			     * will work
			     */
			    if (!((deflibPtr != NullDeflibNode) &&
				strcmp(libraryName, deflibPtr->name)))
			    {
				char    foo[205];

				/*
				 * We have to use CompilerStartSegment here,
				 * 'cause using -zE directly will screw us
				 * up later.
				 */
				sprintf(foo, "%sBase", classBeingParsed->data.symClass.root);
				CompilerStartSegment("_BOGUS_", foo);
				Output("\n#pragma option -zFCODE\n%sBase _far %sBaseBogusVariable[1]={0};\n#pragma option -zF*",
				   classBeingParsed->data.symClass.root,
				   classBeingParsed->data.symClass.root);
				CompilerEndSegment("_BOGUS_", foo);
			    }
			}
#endif
		    } else {
			/*
			 * 7/23/92: We used to put this out as a typedef
			 * of the current class's Base structure to be the
			 * super class's Base structure. Unfortunately, 
			 * HighC on the Sparc names the only real Base
			 * structure that exists for the master level
			 * after the final typedef so generated. This
			 * causes us to think there's a type-mismatch between
			 * files, when, for example, there's a subclass of
			 * VisClass used in one file but not in another
			 * (Gen_metaBase becomes of type GrObjBodyBase,
			 * for example, instead of VisBase). To get around
			 * this brain damage, we use a #define instead.
			 * 			-- ardeb
			 */

			/*
			 * If the class is GenApplicationClass output
			 * the typedef as it doesn't seem to cause problems
			 * and it does fix  a major headache.
			 */
			char	*className;

			className = classBeingParsed->data.symClass.root;
			if ((hackFlags & HF_APP_BASE) &&
			    (!strcmp(className, "GenApplication") ||
			    strstr(className, "App")))
			{
			    Output("typedef %sBase %sBase;",
				   classBeingParsed->data.symClass.superclass->
				   data.symClass.root,
				   classBeingParsed->data.symClass.root
				   );
			}
			else
			{
			    Output("#define %sBase %sBase",
				   classBeingParsed->data.symClass.root,
				   classBeingParsed->data.symClass.superclass->
				   data.symClass.root);
			}
		    }
		}
		/*
		 * Figure first message for the class.
		 */
		if ($6 & SYM_CLASS_MASTER) {
		    classBeingParsed->data.symClass.masterLevel += 1;
		    classBeingParsed->data.symClass.firstMessage =
			 FIRST_MASTER_MESSAGE +
			   (classBeingParsed->data.symClass.masterLevel-1)
						*DEFAULT_MASTER_MESSAGES;
		} else {
		    /*
		     * If our superclass is MetaClass then force our first
		     * message to be 8192
		     */
		    if (classBeingParsed->data.symClass.superclass->
			    	data.symClass.superclass == NullSymbol) {
			classBeingParsed->data.symClass.firstMessage = 8192;
		    } else {
			/*
			 * If our superclass is the first class in a master
			 * level then give it 2048
			 */
			if (($4->data.symClass.firstMessage & (8192-1)) ||
			    ($4->data.symClass.firstMessage == 8192)) {
			    classBeingParsed->data.symClass.firstMessage =
			    	$4->data.symClass.firstMessage
				    +DEFAULT_CLASS_MESSAGES;
			} else {
			    classBeingParsed->data.symClass.firstMessage =
			    	$4->data.symClass.firstMessage
				    +2048;
			}
		    }
		}
	    }
	    Output("\n#define _FIRST_%s %d", classBeingParsed->name,
		   classBeingParsed->data.symClass.firstMessage);
            OutputLineNumber(yylineno,curFile->name);
	    Symbol_PushScope(classBeingParsed->data.symClass.localSymbols);
	    
	    classBeingParsed->data.symClass.nextMessage =
		classBeingParsed->data.symClass.firstMessage;
	    classBeingParsed->data.symClass.nextTag =
		classBeingParsed->data.symClass.firstMessage;

	    if (classBeingParsed->flags & SYM_CLASS_VARIANT) {
		char name[100];
		Symbol *inst;
		/*
		 * For a variant class put in the superclass pointer
		 */
		sprintf(name, "%s", classBeingParsed->data.symClass.root);
		inst = MakeInstanceVar(VARIANT_PTR_SYM,
				       String_EnterZT(name), "MetaBase");
		classBeingParsed->data.symClass.instanceData = inst;
	    }

	    /*
	     * Deal with default building of things, going all the way up
	     * the class tree..
	     */
	    for (class = bottomClass = classBeingParsed;
		 class != NullSymbol;
		 class = super)
	    {
		super = class->data.symClass.superclass;
		if (class->flags & SYM_CLASS_VARIANT) {
		    /*
		     * If we have hit a variant class then we need to try to
		     * find the variant class for it
		     */
		    if (LocateSuperForVariant(bottomClass, NullSymbol, &super)){
			/*
			 * Push default superclass's locals too
			 */
			Symbol_PushScope(super->data.symClass.localSymbols);
			bottomClass = super;
		    } else {
			break;
		    }
		}
	    }
	    SWITCH_CONTEXT( LC_NONE);
	}
	;

superClass	:
	CLASS_SYM
	| META { $$ = NullSymbol; }
	| IDENT { 
			yyerror("unidentified class symbol '%s'. Substituting with 'meta'",$1);
			$$ = NullSymbol;
	}
	;

classFlags	:
	',' MASTER ',' VARIANT
	{
	    $$ = SYM_CLASS_MASTER | SYM_CLASS_VARIANT;
	}
	| ',' VARIANT ',' MASTER
	{
	    $$ = SYM_CLASS_MASTER | SYM_CLASS_VARIANT;
	}
	| ',' MASTER
	{
	    $$ = SYM_CLASS_MASTER;
	}
	| { $$ = 0; }
	;

/*
 * @endc
 *
 * Reset classBeingParsed to null and output the instance structure
 */

endcLine	:
	ENDC
	{
	    if (classBeingParsed == NullSymbol) {
		yyerror("@endc outside class declaration");
	    } else {
		/*
		 * Output an extern for the class structure.
		 * If we are in a library that we are not defining then
		 * declare the class to be 'far'.
		 */
		if ((deflibPtr != NullDeflibNode) && strcmp(libraryName, deflibPtr->name)) {

		Output("extern ClassStruct %s %s; ", 
		       compilerFarKeyword, classBeingParsed->name);

		/*
		 * NOTE: for the data to be laid out correctly by HighC, these
		 * four extern declarations must exist and be in the order
		 * in which the components of the class record are placed in
		 * memory, as HighC seems to mark the location where data
		 * should go based on where it saw the extern, effectively
		 * remembering the current offset in the segment and stuffing
		 * the data in there when the variable is encountered.
		 * -- ardeb 3/11/92
		 */
		if (compiler == COM_HIGHC) {
		    Output("extern Message _Messages_%s[]; ", classBeingParsed->name);
		    Output("extern MessageMethod *_Methods_%s[]; ",
			   classBeingParsed->name);
		    Output("extern CMethodDef _htypes_%s[];",
			   classBeingParsed->name);
		    Output("extern MessageMethod *_Reloc_%s;",
			   classBeingParsed->name);
		}
	    } else {

		char    farString[] = " _far";

	        /*
		 * High C will place the following externs into whichever
		 * segment is active when it encounters the following externs,
		 * even if the actual declarations are specified as being
		 * in a different segment, so curResource gets this class,
		 * regardless of which segment is active during the @classdecl.
		 * There's code in the @classdecl handler that'll error if
		 * curResource here is null and curResource during the
		 * @classdecl is some segment if we're targeting the High C
		 * compiler. We also prepend an "_CLASSSEG_" to the name
		 * of the segment, since High C will issue a GRPDEF to
		 * subsume whatever segment we begin here, and glue needs to
		 * recognize that we don't want that to happen.None of this
		 * should be a problem under Borland C, since it seems to
		 * favor the active segment at the time the thing is actually
		 * declared. - jon 19 oct 94
		 */

		if (compiler == COM_BORL) {

#if 1
		    /*
		     * I changed this back to not emit the far unless the
		     * class is known to be in a different segment, as without
		     * this, an @callsuper in a multi-launchable geode yields
		     * death when the class segment remains the resource ID,
		     * not the segment of dgroup. -- ardeb 7/9/96
		     */
		    if (curResource != NullSymbol) {
			CompilerStartSegment("", curResource->name);
			Output("extern ClassStruct far %s[]; ", classBeingParsed->name);
		    } else if (classSegName) {
			CompilerStartSegment("", classSegName);
			Output("extern ClassStruct far %s[]; ", classBeingParsed->name);
		    } else {
			Output("extern ClassStruct %s[]; ", classBeingParsed->name);
		    }
#else
		    /*
		     * I've changed this line to *always* emit the far
		     * keyword so that HP can use the non '-C' method
		     * of declaring classes in segments other than dgroup.
		     * I thought that this caused a problem somewhere else,
		     * but eballot sez he tried it out on a bunch of sample
		     * apps, and it seems to work. - jon 29 feb 96
		     */
			Output("extern ClassStruct far %s[]; ", classBeingParsed->name);
#endif
		 } else {
		    if (curResource != NullSymbol) {
			CompilerStartSegment("_CLASSSEG_", curResource->name);
		    } else if (classSegName) {
			CompilerStartSegment("_CLASSSEG_", classSegName);
		    } else {
			*farString = '\0';
		    }

		    Output("extern%s ClassStruct %s; ",
			   farString, classBeingParsed->name);

		/* NOTE: for the data to be laid out correctly by HighC, these
		 * four extern declarations must exist and be in the order
		 * in which the components of the class record are placed in
		 * memory, as HighC seems to mark the location where data
		 * should go based on where it saw the extern, effectively
		 * remembering the current offset in the segment and stuffing
		 * the data in there when the variable is encountered.
		 * -- ardeb 3/11/92
		 */

		    Output("extern%s Message _Messages_%s[]; ",
			   farString, classBeingParsed->name);
		    Output("extern%s MessageMethod *_Methods_%s[]; ",
			   farString, classBeingParsed->name);
		    Output("extern%s CMethodDef _htypes_%s[];",
			   farString, classBeingParsed->name);
		    Output("extern%s MessageMethod *_Reloc_%s;",
			   farString, classBeingParsed->name);
		
		    /*
		     * End the segment we began
		     */
		    if (curResource != NullSymbol) {
			CompilerEndSegment("_CLASSSEG_", curResource->name);
		    } else if (classSegName) {
			CompilerEndSegment("_CLASSSEG_", classSegName);
		    }
		}
	    }

    	    	if (classBeingParsed->flags & SYM_PROCESS_CLASS) {
		    processClass = classBeingParsed;
	    	} else {
		    /*
		     * Output the instance data structure that we've stored
		     * the pieces of
		     */
		    Output("\ntypedef struct _%sInstance {\n",
			    	    classBeingParsed->data.symClass.root);
		    OutputInstanceData(classBeingParsed);
		    Output("} %sInstance; ",
			    	    classBeingParsed->data.symClass.root);
		    /*
		     * Need to put out a line number directive because
		     * the instance stuff might have changed it, and
		     * there might be stuff on the line after the @endc.
		     */
		    OutputLineNumber(yylineno,curFile->name);
		}
		/* output an extern for the classes messages, if any */
		if(classBeingParsed->data.symClass.firstMessagePtr != NULL){
		  int enumValue = 0;
		  Symbol *mptr;
		  Output("typedef enum{");
		  for(mptr = classBeingParsed->data.symClass.firstMessagePtr; 
		      mptr != (Symbol *)NULL;
		      mptr = mptr->data.symMessage.nextMessage){
		    if(enumValue == mptr->data.symMessage.messageNumber){
		      Output("%s,",mptr->name);
		    }else{
		      Output("%s=%d,",mptr->name,
			     /* cast it so it makes them negative if they */
			     /* are over 32768 				  */
			     (long)(short)
			     mptr->data.symMessage.messageNumber);
		      enumValue = mptr->data.symMessage.messageNumber;
		    }
		    enumValue++;
		  }
		  Output("}%sMessages;", 
			 classBeingParsed->data.symClass.root);
		}

		Symbol_PopScopeTo(classBeingParsed->data.symClass.localSymbols);
	    }
	    classBeingParsed = NullSymbol;
	    SWITCH_CONTEXT( LC_NONE);
	}
	;

/*
 * @instance MemHandle myHandle = NULL;
 * @instance @visMoniker GI_moniker;
 *
 */

instanceLine	:
    	INSTANCE
	{
	    SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	}
 	instanceLineType ';'
	{
	    Symbol **iptr;
	    /*
	     * Add instance variable to class's instance variables
	     */
	    if (classBeingParsed == NullSymbol) {
		yyerror("@instance outside class declaration");
	    } else {
		for (iptr = &(classBeingParsed->data.symClass.instanceData);
		     	*iptr != NullSymbol;
		     	iptr = &((*iptr)->data.symRegInstance.next)) ;
		*iptr = $3;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	}
	;

instanceLineType  :
    	COMPOSITE
	{ SWITCH_CONTEXT( LC_PARSE); }
 	IDENT '=' LINK_SYM
 	{
	    $$ = MakeInstanceVar(COMPOSITE_SYM, $3,
				    	    String_EnterZT("CompPart"));
	    $$->data.symComposite.linkPart = $5;
	    AddReloc(NullSymbol, RT_OPTR, $3, 1, String_EnterZT(""));
	}
    	| LINK
	{ SWITCH_CONTEXT( LC_PARSE); }
 	kbdPathOrNull IDENT
 	{
	    $$ = MakeInstanceVar(LINK_SYM, $4, String_EnterZT("LinkPart"));
	    $$->flags |= $3;
	    AddReloc(NullSymbol, RT_OPTR, $4, 1, String_EnterZT(""));
	}
    	| VIS_MONIKER
	{ SWITCH_CONTEXT( LC_PARSE); }
 	IDENT
 	{
	    $$ = MakeInstanceVar(VIS_MONIKER_SYM, $3,
				    	    String_EnterZT("ChunkHandle"));
	}
    	| KBD_ACCELERATOR
	{ SWITCH_CONTEXT( LC_PARSE); }
 	IDENT
 	{
	    $$ = MakeInstanceVar(KBD_ACCELERATOR_SYM, $3,
				    	    String_EnterZT("word"));
 	}
    	|typeDeclString
	{ SWITCH_CONTEXT( LC_PARSE); }
 	instanceDefault
  	{
	    if (!strcmp(TDS_CTYPE($1), "optr")) {
		$$ = MakeInstanceVar(OPTR_SYM, TDS_IDENT($1), 
				     String_EnterZT("optr"));
		$$->data.symRegInstance.defaultValue = $3;
		AddReloc(NullSymbol, RT_OPTR, TDS_IDENT($1), 
			 1, String_EnterZT(""));
	    } else if (!strcmp(TDS_CTYPE($1), "ChunkHandle")) {
	    	$$ = MakeInstanceVar(CHUNK_INST_SYM, TDS_IDENT($1),
				    	    String_EnterZT("ChunkHandle"));
		$$->data.symRegInstance.defaultValue = $3;
	    } else {
		$$ = MakeInstanceVar(REG_INSTANCE_SYM, TDS_IDENT($1), 
				     TDS_CTYPE($1));
		$$->data.symRegInstance.typeSuffix = TDS_TYPESUF($1);
		$$->data.symRegInstance.defaultValue = $3;
	    }
	    SWITCH_CONTEXT( LC_PARSE);
	}
    	;

kbdPathOrNull	:
    	KBD_PATH { $$ = SYM_IS_KBD_PATH; }
	| { $$ = 0; }
	;

instanceDefault	    :
 	'='
 	{
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	}
    	FAKESTRING {
	    $$ = $3;
	}
 	| { $$ = NULL; }
    	;

/*
 * @vardata MyTriggerTopStruc HINT_MY_TRIGGER_TOP;
 *
 */

vardataLine    :
 	VARDATA
 	{
	  SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	}
 	typeDeclString  /*  XXX  be sure to dealloc its memory. XXX  */
 	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
 	';'
 	{
	  Symbol *sym;
	  
	    if (classBeingParsed == NullSymbol) {
		yyerror("@vardata cannot be outside class declaration");
	    } else {
	        
		sym = Symbol_Enter(TDS_IDENT($3), VARDATA_SYM, SYM_DEFINED);
		sym->data.symVardata.ctype = TDS_CTYPE($3);
		sym->data.symVardata.typeSuffix = TDS_TYPESUF($3);

		sym->data.symVardata.class = classBeingParsed;
		sym->data.symVardata.protoMinor = curProtoMinor;
		sym->data.symVardata.tag =
				classBeingParsed->data.symClass.nextTag;
		classBeingParsed->data.symClass.nextTag += 4;
		Output("#define %s %d\n", sym->name, sym->data.symVardata.tag);
	    }
	    SWITCH_CONTEXT( LC_NONE);
	}
 	;

/*
 * @vardataAlias(HINT_MY_TRIGGER_TOP) MyTBottomStruc HINT_MY_TRIGGER_BOTTOM,
 *
 */
vardataSymOrError :VARDATA_SYM {$$ = $1;}
	| vardataClass VARDATA_SYM
	{
	    $$ = $2;
	    Symbol_PopScope();
	}
	| vardataClass IDENT
	{
	    yyerror("'%s' is not a vardata symbol",$2);
	    Symbol_PopScope();
	    $$ = NullSymbol;
	}
	| vardataClass error
	{
	    Symbol_PopScope();
	    $$ = NullSymbol;
	}
	| IDENT { yyerror("'%s' is not a vardata symbol",$1); $$ = NullSymbol;}
	;

vardataClass: CLASS_SYM
	{
	    Symbol_PushScope($1->data.symClass.localSymbols);
	}
	 ':' ':'
	;


vardataAliasLine  :
 	VARDATA_ALIAS '(' vardataSymOrError ')'
 	{
	    SWITCH_CONTEXT( LC_PARSE_NO_LOOKUP);
	}
 	IDENT
 	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
 	IDENT
 	{
	    Symbol *sym;

	    if($3 != NullSymbol){

		/*
		 * Make sure we're in the scope of the class of whose vardata
		 * this thing will become a member.
		 */
		Symbol_PushScope($3->data.symVardata.class->data.symClass.localSymbols);
		sym = Symbol_Enter($8, VARDATA_SYM, SYM_DEFINED);
		sym->data.symVardata.ctype = $6;
		sym->data.symVardata.class = $3->data.symVardata.class;
		sym->data.symVardata.tag = $3->data.symVardata.tag;
		sym->data.symVardata.typeSuffix = 
		    $3->data.symVardata.typeSuffix;
		Output("#define %s %d", sym->name, sym->data.symVardata.tag);

		Symbol_PopScope();

		SWITCH_CONTEXT( LC_NONE);
	    }
	}
 	;

/*
 * @protominor JonsNewStuff
 *
 */

protoMinorLine    :
 	PROTOMINOR protoMinorSym
 	{
	    if (classBeingParsed == NullSymbol) {
		yyerror("@protominor cannot be outside class declaration");
	    } else {
		curProtoMinor = $2;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	}
 	;

protoResetLine    :
 	PROTORESET
 	{
	    if (classBeingParsed == NullSymbol) {
		yyerror("@protoreset cannot be outside class declaration");
	    } else {
		curProtoMinor = NullSymbol;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	}
 	;

/*
 * @default myStruct = {5, 7, 8};
 *
 */

defaultLine	:
    	DEFAULT defaultableSym '='
 	{
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	}
    	FAKESTRING
  	{
  	    if($2 != NullSymbol){
		InstanceValue *inst;
		char buf[1000];
		/*
		 * Replace any occurrance of @default with 
		 * the old default value
		 */
		if (defaultdebug) {
		    fprintf(stderr, "*** Defaulting %s of class %s...",
			    $2->name, classBeingParsed->name);
		}
		inst = FindDefault(classBeingParsed, $2->name);
		if (inst != NullInstanceValue) {
		    if (defaultdebug) {
			fprintf(stderr, "found %s -> ", inst->value);
		    }
		    CopySubst(buf, $5, "@default", inst->value);
		} else {
		    if (defaultdebug) {
			fprintf(stderr, "using default %s ->",
				$2->data.symRegInstance.defaultValue);
		    }
		    if ($2->data.symRegInstance.defaultValue != NULL) {
			CopySubst(buf, $5, "@default",
				  $2->data.symRegInstance.defaultValue);
		    } else {
			CopySubst(buf, $5, "@default", "0");
		    }
		}
		if (defaultdebug) {
		    fprintf(stderr, "%s\n", buf);
		}
		if ($2->type == VARIANT_PTR_SYM) {
		    Symbol *oldScope, *tempClass;
		    
		    tempClass = Symbol_Find($5, TRUE);
		    if (tempClass == NullSymbol) {
			yyerror("superclass for variant (%s) not defined", $5);
		    } else if (LocateSuperForVariant(classBeingParsed, NullSymbol,
						     &oldScope)) {
			/*
			 * Replace the old scope
			 */
			Symbol_ReplaceScope(oldScope->data.symClass.localSymbols,
					    tempClass->data.symClass.localSymbols);
		    } else {
			Symbol_PushScope(tempClass->data.symClass.localSymbols);
		    }
		}
		
		inst = (InstanceValue *) zmalloc(sizeof(InstanceValue));
		inst->next = classBeingParsed->data.symClass.defaultList;
		classBeingParsed->data.symClass.defaultList = inst;
		inst->name = $2->name;
		inst->value = String_EnterZT(buf);
		SWITCH_CONTEXT( LC_PARSE);
	    }
	}
 	';'
 	{
    	    SWITCH_CONTEXT( LC_NONE);
    	}
	;

defaultableSym	:
    	REG_INSTANCE_SYM
    	| OPTR_SYM
	| VARIANT_PTR_SYM
    	| IDENT {
 	 	yyerror("'%s' not an instance variable, can't set its default",
			$1);
		$$ = NullSymbol;
 	}
    	;

/*
 * @reloc foo.handle, handle
 *
 */

relocLine	:
    	RELOC
 	{
	    SWITCH_CONTEXT( LC_STRING_COMMA);
	}
    	FAKESTRING
 	{
	    relocSym = Symbol_Find($3, TRUE);
	    if ((relocSym == NullSymbol) || (relocSym->type != VARDATA_SYM)) {
	    	SWITCH_CONTEXT( LC_PARSE);
		relocString = $3;
	    }
	}
    	',' relocTail 	

relocTail   	:
    	relocCount relocType
  	{
	    AddReloc(NullSymbol, $2, relocString, $1, relocStruct);
	    SWITCH_CONTEXT( LC_NONE);
	}
 	| FAKESTRING
  	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
 	',' relocCount relocType
 	{
	    AddReloc(relocSym, $5, $1, $4, relocStruct);
	    SWITCH_CONTEXT( LC_NONE);
	}
	;

relocCount   :
    	'(' CONST ','
  	{
	    SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
	}
    	FAKESTRING
  	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
    	')'
  	{
	    $$ = $2;
	    relocStruct = String_EnterZT($5);
	}
    	|
  	{
	    $$ = 1;
	    relocStruct = String_EnterZT("");
	}
    	;

relocType   :
    	FPTR { $$ = RT_FPTR; }
   	| HPTR { $$ = RT_HPTR; }
   	| OPTR { $$ = RT_OPTR; }
 	;

/*
 * @classdecl MyClass, neverSaved ;
 *
 */

classdeclLine	:
    	CLASSDECL CLASS_SYM
	{
	}
    	classDeclFlags semiColonOrError
	{
	    Symbol **sym;

	    if (classBeingParsed != NullSymbol) {
		yyerror("@classdecl for %s must be outside class declaration",
			$2->name);
	    }

	    /*
	     * Check whether the class has already been declared, since
	     * this would cause an endless loop in DoFinalOutput if left
	     * unchecked.
	     */
	    if ($2->flags & SYM_CLASS_DECLARED) {
		yyerror("Duplicate @classdecl for %s", $2->name);
	    } else {
		for (sym = &classDeclList; *sym != NullSymbol;
		     sym= &((*sym)->data.symClass.nextDeclaredClass));
		*sym = $2;
		$2->flags |= $4 | SYM_CLASS_DECLARED;

		if (curResource != NullSymbol) {
		    if ($2->data.symClass.classSeg != NullSymbol) {
			if ($2->data.symClass.classSeg != curResource) {
			    yyerror("%s is already in segment %s, so it can't be redeclared in %s", $2->name, $2->data.symClass.classSeg->name, curResource->name);
			}
		    } else if (compiler == COM_HIGHC) {
			yyerror("%s must be the current segment around the @class/@endc for %s, otherwise High C will put %s into dgroup, which is probably not what you were expecting.", curResource->name, $2->name, $2->name);
		    } else {
			$2->data.symClass.classSeg = curResource;
		    }
		}
	     }
	    SWITCH_CONTEXT( LC_NONE);

	    curProtoMinor = NullSymbol;

           /* put out a bogus segment with a variable of ClassBase so 
	    * glue will get type info so pobj on objects whose classes are
	    * sub classes of Master Classes defined in GOC will work
	    * First: check to make sure the class has a master level
	    * NOTE: only implemented for BORLAND compiler now
	    */
            if ($2->data.symClass.masterLevel != 0)
 	    {
		if (compiler == COM_BORL)
		{
		    char    *cp, foo[205];
#define STRLEN_CLASS 5
		    cp = $2->name + strlen($2->name) - STRLEN_CLASS;
		    *cp = '\0';

		    /*
		     * We have to use CompilerStartSegment here, 'cause
		     * using -zE directly will screw us up later.
		     */
		    sprintf(foo, "%sBase", $2->name);
		    CompilerStartSegment("_BOGUS_", foo);
		    Output("\n#pragma option -zFCODE\n%sBase _far %sBaseBogusVariable[1]={0};\n#pragma option -zF*", $2->name, $2->name);
		    CompilerEndSegment("_BOGUS_", foo);

		    *cp = 'C';
		    OutputLineNumber(yylineno,curFile->name);
		}
	    }
	}

	| CLASSDECL IDENT classDeclFlags semiColonOrError
	{
    	    yyerror("Can't declare class for '%s', not defined.",$2);

	    SWITCH_CONTEXT( LC_NONE);
	}
        ;

classDeclFlags	:
	',' NEVER_SAVED
	{
	    $$ = SYM_NEVER_SAVED;
	}
	| { $$ = 0; }
	;

/*
 * @message char *MSG_GET_NAME(FooStruc *fooptr = cx:dx) = cx:dx
 *
 */

messageLine  	:
    	MESSAGE
 	{
	  SWITCH_CONTEXT( LC_TYPE_STRING_NO_MATCH_PARENS);
	    currentMPD = numRegs = 0;
	    stackParams = forceRegs = forceNoRegs = multipleReturn = FALSE;
	}
 	messageFinish
    	;

messageFinish	:
 	typeDeclString '('   /*  XXX  be sure to dealloc its memory. XXX  */
 	{
	    /*
	     * Enter the identifier as a message and initialize it.  We must
	     * enter it in the global scope so that it is accessable anywhere.
	     */
	    curMessage = EnterSymbolInGlobal(TDS_IDENT($1), 
					     MSG_SYM, SYM_DEFINED);
	    SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	    currentMessageReturnType = TDS_CTYPE($1);
	}
 	stackFlag messageParamListOrNull ')'
 	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
 	messageReturn ';'
 	{
	    if (classBeingParsed == NullSymbol) {
		yyerror("@message cannot be outside class declaration");
	    } else {
		if (TDS_TYPESUF_IS_NOT_NULL($1)) {
		    yyerror("messages cannot return arrays (use *)");
		}
		curMessage->data.symMessage.class = classBeingParsed;
		curMessage->data.symMessage.protoMinor = curProtoMinor;
		curMessage->data.symMessage.messageNumber =
				classBeingParsed->data.symClass.nextMessage++;
		curMessage->data.symMessage.firstParam = $5;
		curMessage->data.symMessage.returnType = TDS_CTYPE($1);
		curMessage->data.symMessage.mpd = currentMPD;
		/*
		 * Output("#define %s %d", TDS_IDENT($1),
		 *  curMessage->data.symMessage.messageNumber);
                 */
                ADD_MESSAGE_LIST_ELEMENT(classBeingParsed,curMessage); 
		if (mpddebug) {
		    Output("\n#define %s_MPD %s", curMessage->name,
			   GenerateMPDString(curMessage, 
					     MPD_PASS_AND_RETURN));
		}
	    }
    	    SWITCH_CONTEXT( LC_NONE);
    	}
 	| '(' 
        {   
	  SWITCH_CONTEXT( LC_PARSE);
	}
        MSG_SYM ')' IDENT ';'   /* NEED TO TEST THIS PRODUCTION */
 	{
	    /*
	     * Enter the identifier as a message and initialize it.  We must
	     * enter it in the global scope so that it is accessable anywhere.
	     */
	    curMessage = EnterSymbolInGlobal($5, MSG_SYM, SYM_DEFINED);

	    if (classBeingParsed == NullSymbol) {
		yyerror("@message cannot be outside class declaration");
		
	    } else {
		curMessage->data.symMessage.class = classBeingParsed;
		curMessage->data.symMessage.messageNumber =
				classBeingParsed->data.symClass.nextMessage++;
		curMessage->data.symMessage.firstParam =
		    	    	    	$3->data.symMessage.firstParam;
		curMessage->data.symMessage.returnType =
		    	    	    	$3->data.symMessage.returnType;
		curMessage->data.symMessage.mpd =
		    	    	    	$3->data.symMessage.mpd;
                /*
		 * Output("#define %s %d", $5,
		 * curMessage->data.symMessage.messageNumber);
                 */
                ADD_MESSAGE_LIST_ELEMENT(classBeingParsed,curMessage);

		if (mpddebug) {
		    Output("\n#define %s_MPD %s", curMessage->name,
			   GenerateMPDString(curMessage, 
					     MPD_PASS_AND_RETURN));
		}
	    }
    	    SWITCH_CONTEXT( LC_NONE);
    	}
    	;

messageParamListOrNull	:
    	messageParamList
 	{
	    /*
	     * If no parameters are given then set to register params
	     */
	    if ( !stackParams && ((currentMPD & MPD_PASS) == 0)) {
	    	currentMPD |= MPD_REGISTER_PARAMS;
	    }
	}
    	|
 	{
	    /*
	     * No parameters given -> set to register params
	     */
	    $$ = NullParam;
	    currentMPD |= MPD_REGISTER_PARAMS;
	}
 	;

messageParamList	:
    	messageParamList ','
 	{
	    SWITCH_CONTEXT(  LC_TYPE_STRING_MATCH_PARENS);
	    $<num>$ = multipleReturn;
	}
    	messageParam
 	{
	    MessageParam **pp;

	    /*
	     * Make sure the value of the global multipleReturn variable hasn't
	     * changed because of this parameter, as any multiple-return
	     * parameter must be the first one passed (that's where the
	     * kernel puts the thing).
	     */
	    if ($<num>3 != multipleReturn) {
		yyerror("multiple-return parameter must be first parameter for message");
	    }
	    
	    if ($1 != NullParam) {
		for (pp = &($1->next); *pp != NullParam; pp = &((*pp)->next));
		*pp = $4;
		$$ = $1;
	    } else {
		$$ = $4;
	    }
	    SWITCH_CONTEXT( LC_PARSE);
	}
    	| messageParam { SWITCH_CONTEXT( LC_PARSE);   $$ = $1; }
    	;

/*
 * We build the MPD by taking advantage of the fact that things parse left to
 * right, which is the basic order in which we build an MPD.
 */

stackFlag   	:
    	STACK
 	{
	    forceNoRegs = TRUE;
	    stackParams = TRUE;
	}
    	|
    	;

messageParam 	:
    	typeDeclString
 	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
 	eqParamRegs
 	{
	    $$ = (MessageParam *) zmalloc(sizeof(MessageParam));
	    $$->name = TDS_IDENT($1);
	    $$->ctype = TDS_CTYPE($1);
	    $$->typeSuffix = TDS_TYPESUF($1);
	}
 	;

eqParamRegs	:
    	'=' paramRegs
 	{
	    if (forceNoRegs) {
		if (numRegs != 0) {
		    if (currentMPD & MPD_C_PARAMS) {
			yyerror("cannot specify registers with @stack");
		    } else {
			yyerror("must specify registers for all params "
				"or none");
		    }
		}
	    } else {
		/*
		 * If we parsed a real register (somsging other tmeth
		 * multiple return values) then force all other parameters
		 * to have registers
		 */
		if (numRegs != 0) {
	    	    forceRegs = TRUE;
		}
	    }
	}
    	|
 	{
	    if (forceRegs) {
		yyerror("must specify registers for all params or none");
	    } else {
		forceNoRegs = TRUE;
		if (!stackParams) {
	            currentMPD |= MPD_C_PARAMS;
		}
	    }
	}
    	;

paramRegs   	:
    	CL { AddRegDefinition(MPR_CL); }
    	| CH { AddRegDefinition(MPR_CH); }
    	| DL { AddRegDefinition(MPR_DL); }
    	| DH { AddRegDefinition(MPR_DH); }
    	| CX { AddRegDefinition(MPR_CX); }
    	| DX { AddRegDefinition(MPR_DX); }
    	| BP { AddRegDefinition(MPR_BP); }
    	| wordParamReg ':' wordParamReg
 	{
	    AddRegDefinition($1);
	    AddRegDefinition($3);
	}
    	| wordParamReg '.' wordParamReg
 	{
	    AddRegDefinition($1);
	    AddRegDefinition($3);
	}
    	| SS ':' BP
 	{
	    if (numRegs != 0) {
		yyerror("ss:bp cannot be used with any other register");
	    } else if (currentMPD & MPD_STRUCT_AT_SS_BP) {
		yyerror("only one ss:bp allowed");
	    } else {
		currentMPD |= MPD_STRUCT_AT_SS_BP;
	    }
	}
    	| multipleParamReg
	{
	    multipleReturn = TRUE;
	    currentMPD |= (MRT_MULTIPLE << MPD_RETURN_TYPE_OFFSET) |
		    	    ($1 << MPD_RET_MULT_OFFSET);
	}
	| IDENT {yyerror("unrecognized register syntax '%s'",$1);}
    	;

wordParamReg	:
    	CX { $$ = MPR_CX; }
    	| DX { $$ = MPR_DX; }
    	| BP { $$ = MPR_BP; }
    	;

multipleParamReg    :
 	AXBPCXDX { $$ = MRMT_AXBPCXDX; }
 	| AXCXDXBP { $$ = MRMT_AXCXDXBP; }
 	| CXDXBPAX { $$ = MRMT_CXDXBPAX; }
	| DXCX { $$ = MRMT_DXCX; }
	| BPAXDXCX { $$ = MRMT_BPAXDXCX; }
	| MULTIPLEAX { $$ = MRMT_MULTIPLEAX; }
	;

messageReturn	:
 	'=' returnReg
	{
	    if (multipleReturn &&
		  ((currentMPD >> MPD_RETURN_TYPE_OFFSET) != MRT_MULTIPLE)) {
		yyerror("cannot have a return type in addition to multiple");
	    }
	}
	|
 	{
	    /*
	     * If no registers given for return type and not multiple
	     * return then set return type to dword dxax *unless* the return
	     * type is "void"
	     */
	    if (!multipleReturn) {
		if (!strcmp(currentMessageReturnType, "void")) {
	    	    currentMPD |= (MRT_VOID << MPD_RETURN_TYPE_OFFSET);
		} else {
	    	    currentMPD |= (MRT_DWORD << MPD_RETURN_TYPE_OFFSET) |
		    	    (MRDWR_DX << MPD_RET_DWORD_HIGH_OFFSET) |
	    	    	    (MRDWR_AX << MPD_RET_DWORD_LOW_OFFSET);
		}
	    }
	}
	;

returnReg   	:
    	AX { currentMPD |= RetTypeBWReg(MRBWT_AX); }
	| CX { currentMPD |= RetTypeBWReg(MRBWT_CX); }
	| DX { currentMPD |= RetTypeBWReg(MRBWT_DX); }
	| BP { currentMPD |= RetTypeBWReg(MRBWT_BP); }
	| AL { currentMPD |= RetTypeBWReg(MRBWT_AL); }
	| AH { currentMPD |= RetTypeBWReg(MRBWT_AH); }
	| CL { currentMPD |= RetTypeBWReg(MRBWT_CL); }
	| CH { currentMPD |= RetTypeBWReg(MRBWT_CH); }
	| DL { currentMPD |= RetTypeBWReg(MRBWT_DL); }
	| DH { currentMPD |= RetTypeBWReg(MRBWT_DH); }
	| BPL { currentMPD |= RetTypeBWReg(MRBWT_BPL); }
	| BPH { currentMPD |= RetTypeBWReg(MRBWT_BPH); }
    	| wordReturnReg ':' wordReturnReg
 	{
	    currentMPD |= (MRT_DWORD << MPD_RETURN_TYPE_OFFSET) |
		    	    ($1 << MPD_RET_DWORD_HIGH_OFFSET) |
	    	    	    ($3 << MPD_RET_DWORD_LOW_OFFSET);
	}
    	| wordReturnReg '.' wordReturnReg
 	{
	    currentMPD |= (MRT_DWORD << MPD_RETURN_TYPE_OFFSET) |
		    	    ($1 << MPD_RET_DWORD_HIGH_OFFSET) |
	    	    	    ($3 << MPD_RET_DWORD_LOW_OFFSET);
	}
	| CARRY
 	{
	    currentMPD |= (MRT_VOID << MPD_RETURN_TYPE_OFFSET);
	}
	| IDENT {yyerror("unrecognized return register '%s'",$1);}
	;

wordReturnReg	:
    	AX { $$ = MRDWR_AX; }
    	| CX { $$ = MRDWR_CX; }
    	| DX { $$ = MRDWR_DX; }
    	| BP { $$ = MRDWR_BP; }
    	;

/*
 * @reserveMessages <num>
 */

reserveMessagesLine   :
    	RESERVE_MESSAGES
	{

	}
    	reserveNum  semiColonOrError
 	{
	    if (classBeingParsed == NullSymbol) {
		yyerror("@reserveMessages outside class declaration");
	    } else {
	      classBeingParsed->data.symClass.nextMessage += $3;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	}
    	| RESERVE_MESSAGES exportSymOrError ','
    	reserveNum  semiColonOrError
 	{
    	    if($2){
		$2->data.symExport.nextMessage += $4;
		SWITCH_CONTEXT( LC_NONE);
	    }
	}
 	;

reserveNum  	    :
    	CONST
    	| { yywarning("reserving one message.");$$ = 1; }
 	;

/*
 * @setMessageNum <num>
 */

setMessageLine   :
    	SET_MESSAGE_NUM
	{

	}
    	setMessageNum  semiColonOrError
 	{
	    if (classBeingParsed == NullSymbol) {
		yyerror("@setMessageNum outside class declaration");
	    } else {
	      classBeingParsed->data.symClass.nextMessage = $3;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	}
    	| SET_MESSAGE_NUM exportSymOrError ','
    	setMessageNum  semiColonOrError
 	{
    	    if($2){
		$2->data.symExport.nextMessage = $4;
		SWITCH_CONTEXT( LC_NONE);
	    }
	}
 	;

setMessageNum  	    :
    	numExpr { $$ = $1; }
	| 	{ yywarning("reserving one message."); $$ = 1; }
 	;

numExpr	            :
    	numExpr '+' primary 	{ $$ = $1 + $3; }
	| numExpr '-' primary 	{ $$ = $1 - $3; }
	| primary		{ $$ = $1; }
	;
primary		    :
	'(' numExpr ')' 	{ $$ = $2; }
	| '-' primary		{ $$ = -$2; }
	| CONST			{ $$ = $1; }
	| MSG_SYM		{ $$ = $1->data.symMessage.messageNumber; }
	;

/*
 * @exportMessages  <name>, <num>;
 */

exportMessagesLine   :
    	EXPORT_MESSAGES IDENT
	{

	}
    	exportNum  semiColonOrError
 	{
	    Symbol *sym;

	    if (classBeingParsed == NullSymbol) {
		yyerror("@exportMessages outside class declaration");
	    } else {
		/*
		 * We want to enter the exported message symbol in the global
		 * scope (so that it can be accessed outside the class), not
		 * within the scope of the class (which is the current scope).
		 * We do this by pushing the global scope temporarily.
		 */
		sym = EnterSymbolInGlobal($2, EXPORT_SYM, SYM_DEFINED);
		sym->data.symExport.class = classBeingParsed;
		sym->data.symExport.firstMessage =
		    sym->data.symExport.nextMessage =
				classBeingParsed->data.symClass.nextMessage;
		classBeingParsed->data.symClass.nextMessage += $4;
	    }

	    SWITCH_CONTEXT( LC_NONE);
	}
	;

exportNum  	    :
    	',' CONST { $$ = $2; }
    	| { 
    		yywarning("using default number of exported messages.");
		$$ = DEFAULT_EXPORTED_MESSAGES; 
	}
 	;

/*
 * @importMessage char *MSG_GET_NAME(FooStruc *fooptr = cx:dx) = cx:dx
 */
exportSymOrError: EXPORT_SYM 
	| IDENT
	{
	    $$ = NullSymbol; 
	    yyerror("'%s' is not an exported message range",$1);
	} 
	;

importMessagePrefix: IMPORT_MESSAGE exportSymOrError ','
	{
	    SWITCH_CONTEXT( LC_TYPE_STRING_NO_MATCH_PARENS);
	    currentMPD = numRegs = 0;
	    stackParams = forceRegs = forceNoRegs = multipleReturn = FALSE;

	    $$ = $2;
	}
	;
	    
importMessageLine  	:
    	importMessagePrefix typeDeclString '('       /* $2  */
 	{
	    SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	    currentMessageReturnType = TDS_CTYPE($2);
	}
 	stackFlag messageParamListOrNull ')' /* $5 $6 */
 	{
	    /*
	     * Enter the identifier as a message and initialize it
	     */
	    curMessage = EnterSymbolInGlobal(TDS_IDENT($2), MSG_SYM, SYM_DEFINED);
	    SWITCH_CONTEXT( LC_PARSE);
	}
 	messageReturn ';' /* $9 */
 	{
	    if (TDS_TYPESUF_IS_NOT_NULL($2)) {
		yyerror("messages cannot return arrays (use *)");
	    }
	    if($1 != NullSymbol){
		curMessage->flags |= SYM_IMPORTED;
		curMessage->data.symMessage.class = $1->data.symExport.class;
		curMessage->data.symMessage.messageNumber =
		    $1->data.symExport.nextMessage++;
		curMessage->data.symMessage.firstParam = $6;
		curMessage->data.symMessage.returnType = TDS_CTYPE($2);
		curMessage->data.symMessage.mpd = currentMPD;
		/* 
		 *  there is not current class, so we don't add the message
		 *  to a list so we can put out the imported messages in an
		 *  enumeration. Nor can we output a define name1 name2 as
		 *  for @alias, because name2 don't exist, because exported 
		 *  messages don't get names.
		 */
		Output("#define %s %d", TDS_IDENT($2),
		       curMessage->data.symMessage.messageNumber);

		if (mpddebug) {
		    Output("\n#define %s_MPD %s", curMessage->name,
			   GenerateMPDString(curMessage, 
					     MPD_PASS_AND_RETURN));
		}
	    }

    	    SWITCH_CONTEXT( LC_NONE);
    	}
	| importMessagePrefix '(' 
        { 
	  SWITCH_CONTEXT( LC_PARSE); 
	}
        messageSymOrIdentErr ')' IDENT ';'
	{
	    if($4 && $1){ /* check the prefix and message */

		/*
		 * Enter the identifier as a message and initialize it.  
		 * We must enter it in the global scope so that it 
		 * is accessable anywhere.
		 */
		curMessage = EnterSymbolInGlobal($6, MSG_SYM,
						 SYM_DEFINED|SYM_IMPORTED);
		
		curMessage->data.symMessage.class = $1->data.symExport.class;
		curMessage->data.symMessage.messageNumber =
		    $1->data.symExport.nextMessage++;
		curMessage->data.symMessage.firstParam =
		    $4->data.symMessage.firstParam;
		curMessage->data.symMessage.returnType =
		    $4->data.symMessage.returnType;
		curMessage->data.symMessage.mpd = $4->data.symMessage.mpd;
		/* can't do this for reasons discussed above.             */
		/* ADD_MESSAGE_LIST_ELEMENT(classBeingParsed,curMessage); */
		
		Output("#define %s %d", $6, 
		       curMessage->data.symMessage.messageNumber);
		
		
		
		if (mpddebug) {
		    Output("\n#define %s_MPD %s", curMessage->name,
			   GenerateMPDString(curMessage, 
					     MPD_PASS_AND_RETURN));
		}
	    }
            SWITCH_CONTEXT( LC_NONE);
	}
    	;

/*
 * @alias(MSG_DRAW) void MSG_REALLY_DRAW();
 *
 * Add a second prototype for a message number
 */

messageSymOrIdentErr: MSG_SYM 
	| IDENT 
	{
 		$$ = NullSymbol; yyerror("'%s' is not a message symbol.",$1);
 	}
	; 

aliasLine  	:
    	ALIAS '(' messageSymOrIdentErr ')'
 	{
	    SWITCH_CONTEXT( LC_TYPE_STRING_NO_MATCH_PARENS);
	    currentMPD = numRegs = 0;
	    stackParams = forceRegs = forceNoRegs = multipleReturn = FALSE;
	}
 	typeDeclString  '('     /* $6 */
 	{
	    SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	    currentMessageReturnType = TDS_CTYPE($6);
	}
 	stackFlag messageParamListOrNull ')'
 	{
	    /*
	     * Enter the identifier as a message and initialize it
	     */
	    curMessage = EnterSymbolInGlobal(TDS_IDENT($6), MSG_SYM, SYM_DEFINED);
	    SWITCH_CONTEXT( LC_PARSE);
	}
 	messageReturn ';'
 	{
	    if (TDS_TYPESUF_IS_NOT_NULL($6)) {
		yyerror("messages cannot return arrays (use *)");
	    }
	    if($3 != NullSymbol){
		if (($3->data.symMessage.class != NullSymbol) &&
		    ($3->data.symMessage.class != classBeingParsed) &&
		    !($3->flags & SYM_IMPORTED))
		{
		    yywarning("%s is not a message for the class being defined now",
			      $3->name);
		}
		curMessage->data.symMessage.class = $3->data.symMessage.class;
		curMessage->data.symMessage.messageNumber =
		    $3->data.symMessage.messageNumber;
		curMessage->data.symMessage.firstParam = $10;
		curMessage->data.symMessage.returnType = TDS_CTYPE($6);
		curMessage->data.symMessage.mpd = currentMPD;
		/* 
		 * We can't output this in an enum, because there is no class,
		 * as this is just an alias. Luckily though, we know the name 
		 * of the message, and it will be in an enumerated type, so we 
		 * define it be the name of the enumeration.
		 */
		Output("#define %s %s", TDS_IDENT($6), $3->name);
		
		if (mpddebug) {
		    Output("\n#define %s_MPD %s", curMessage->name,
			   GenerateMPDString(curMessage, MPD_PASS_AND_RETURN));
		}

	    }
    	    SWITCH_CONTEXT( LC_NONE);
    	}
    	;

/*
 * @prototype void MY_PROTOTYPE();
 *
 * Define a message prototype
 */

prototypeLine  	:
    	PROTOTYPE
 	{
	    SWITCH_CONTEXT( LC_TYPE_STRING_NO_MATCH_PARENS);
	    currentMPD = numRegs = 0;
	    stackParams = forceRegs = forceNoRegs = multipleReturn = FALSE;
	}
 	typeDeclString '('     /* $3   */
 	{
	    SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	    currentMessageReturnType = TDS_CTYPE($3);
	}
 	stackFlag messageParamListOrNull ')'
 	{
	    /*
	     * Enter the identifier as a message and initialize it
	     */
	    curMessage = EnterSymbolInGlobal(TDS_IDENT($3), MSG_SYM, SYM_DEFINED);
	    SWITCH_CONTEXT( LC_PARSE);
	}
 	messageReturn ';'
 	{
	    if (TDS_TYPESUF_IS_NOT_NULL($3)) {
		yyerror("messages cannot return arrays (use *)");
	    }
	    curMessage->data.symMessage.class = NullSymbol;
	    curMessage->data.symMessage.firstParam = $7;
	    curMessage->data.symMessage.returnType = TDS_CTYPE($3);
	    curMessage->data.symMessage.mpd = currentMPD;
	    if (mpddebug) {
		Output("\n#define %s_MPD %s", curMessage->name,
		       GenerateMPDString(curMessage, MPD_PASS_AND_RETURN));
	    }

    	    SWITCH_CONTEXT( LC_NONE);
    	}
    	;

/* so we can piggyback method extern decls and method decls */
externMethodOrMethod: 
        METHOD 
        {
	   $$ = FALSE;
	}
        | 
        EXTERN METHOD 
        {
	  $$ = TRUE;
	}
        ;
/* avoids code duplication in the methodline rule */
identCommaOrNothing:
        IDENT ','   {$$ = $1;} 
        |           {$$ = NULL;}
        ;

/* only exists to avoid duplication of the body of the methodline rule. */
openCurlyOrSemiColon: '{' {$$ = '{'; }
                    | ';' {$$ = ';'; } 
                    ;


/*
 * @method MyGenTriggerDraw, MyGenTriggerClass, MSG_DRAW, _far
 *
 * @method MyGenTriggerClass, MSG_DRAW, _far
 * (generates the name MyGenTriggerDRAW for the method)
 *
 * @extern method MyGenTriggerClass, MSG_DRAW, _far;
 *
 */
classOrError: CLASS_SYM
	| error
	{
	    $$ = NullSymbol;
	    if (yychar == IDENT) {
		yyerror("expecting a class, not the identifier '%s'",
			yylval.string);
	    } else if(yychar > FIRSTSYM && yychar < LASTSYM) {
		yyerror("expecting a class, not the symbol '%s'",
			yylval.sym->name);
	    }
	}
	;

methodLine :
        externMethodOrMethod  /* $1: means "@extern method" or "@method" */

        methodModel identCommaOrNothing classOrError  /* $2 $3 $4 */
	{
	    if($4){
		methClass = $4;
		Symbol_PushScope($4->data.symClass.localSymbols);
	    }
	    methModel = $2;
            methName = $3;  
 	    methFirst = NullSymbol;
	    SWITCH_CONTEXT( LC_PARSE);


	}
        ',' methodMessageList openCurlyOrSemiColon   /* $7 $8 */
	{
    	    if($4 && $7){
		GenerateCurRootDefine($7);
		GenerateMethodDef($7);
		Output("%c", $8);          /* output the ';' or '{'        */
		
		if($1 == FALSE || $8 == '{') { /* @method || @extern method{ */
		    void OutputMethodAntiWarningCode(Method *meth);
		    
		    if($8 == '{'){
			OutputMethodAntiWarningCode($7);
		    }else{
			/* this really isn't bad. we put out the decl, */
			/* but the important thing is that we allow    */
			/* people to assign their own method handler   */
			/* its even good that we put out the decl,     */
			/* because this allows type checking later.    */
			
			/* yyerror("expect method body, not just a ';'"); */
		    }		
		    /* if is @method .... and class not declared... */
		    
		    if($1 == FALSE && !($4->flags & SYM_CLASS_DECLARED)){
			yyerror("you attempted to define method '%s' for the undeclared "
				"class '%s'",$7->name,$4->name);
		    }
		}
	    
		curMethod = $7;
		Symbol_PopScope();
		SWITCH_CONTEXT( LC_NONE);
	    }
	}
      ;

methodMessageList   :
    	/* { $$ = $1; } is default action for both rules */
    	methodMessageList ',' methodMessage 
    	| methodMessage 
    	;

methodMessage	:
    	MSG_SYM
	{
	    Method *meth;
	    char name[200];
	    char *cp;

    	    if (methClass == NullSymbol){
		$$ = NULL;
		goto skip_the_methodMessageProduction;
	    } else if (($1->data.symMessage.class == NullSymbol) &&
		  ($1->data.symMessage.messageNumber != 0))
	    {
		yyerror("%s is a prototype, not a real message",
			$1->name);
		$$ = NULL;
		goto skip_the_methodMessageProduction;
	    } else if ($1->data.symMessage.class != NullSymbol) {
		if (!CheckRelated(methClass, $1->data.symMessage.class,
				  methClass))
		{
		    yyerror("%s is not a message defined by %s or its ancestors",
			    $1->name, methClass->name);
		    $$ = NULL;
		    goto skip_the_methodMessageProduction;
		}
	    }


	    
	    /*
	     * If no method name given then create one
	     */
	    if (methName == NULL) {
		strcpy(name, methClass->name);
		for (cp = name; *cp != '\0'; cp++) ;
		if (!strcmp(cp-5, "Class")) {
		    cp -= 5;
		}
		if (!strncmp($1->name, "MSG_", 4)) {
		    strcpy(cp, ($1->name)+4);
		} else {
		    strcpy(cp, $1->name);
		}
		methName = String_EnterZT(name);
	    }
	    /*
	     * Allocate a structure for the method and link it into the
	     * class's linked list of methods
	     */
	    meth = (Method *) zmalloc(sizeof(Method));
	    meth->next = methClass->data.symClass.firstMethod;
	    methClass->data.symClass.firstMethod = meth;
	    meth->model = methModel;
	    meth->message = $1;
	    meth->class = methClass;

	    meth->name = methName;
	    if ($1->data.symMessage.class == NullSymbol) {
		/*
		 * Relocation message.
		 */
		if (methClass->flags & SYM_CLASS_HAS_RELOC) {
		    yyerror("%s already has a relocation method",
			    methClass->name);
		}
		if (methClass->flags & SYM_PROCESS_CLASS) {
		    yyerror("process classes cannot have relocation methods");
		}
		meth->htd = MTD_RELOC | (MM_FAR << MTD_MODEL_OFFSET);
		methClass->flags |= SYM_CLASS_HAS_RELOC;
	    } else {
		/*
		 * Set the correct master message bit
		 */
		meth->class->data.symClass.masterMessages |=
		   1 << (meth->message->data.symMessage.messageNumber >> 13);
		meth->htd = (meth->model << MTD_MODEL_OFFSET);
		if (meth->class->flags & SYM_PROCESS_CLASS) {
		    meth->htd |= MTD_PROCESS_CLASS;
		}
		/*
		 * Mark another method for the class
		 */
		methClass->data.symClass.methodCount++;
	    }

	    /*
	     * If this is not the first message given for this handler
	     * then make sure that it is compatible with the first message
	     */
	    if (methFirst != NullSymbol) {
		if ($1->data.symMessage.mpd != methFirst->data.symMessage.mpd) {
		    yyerror("method cannot handle incompatible messages");
		}
	    } else {
		methFirst = $1;
	    }
 	    $$ = meth;
	skip_the_methodMessageProduction:
	// Null semicolom required for watcom
	;
	    
	}
	| IDENT
	{
	    $$ = NULL;
	    yyerror("'%s' is not a message symbol.",$1);
        }
 	;

methodModel	:
    	FAR { $$ = MM_FAR; }
    	| NEAR { $$ = MM_NEAR; }
    	| BASED { $$ = MM_BASED; }
    	| { $$ = defaultModel; }
 	;

/*
 * @defaultModel _far
 */

defaultModelLine    :
    	DEFAULT_MODEL FAR { defaultModel = MM_FAR; SWITCH_CONTEXT( LC_NONE); }
    	| DEFAULT_MODEL NEAR { defaultModel = MM_NEAR; SWITCH_CONTEXT( LC_NONE); }
    	| DEFAULT_MODEL BASED { defaultModel = MM_BASED; SWITCH_CONTEXT( LC_NONE); }
 	;

/*
 * @extern obj
 */

externLine	:
    	EXTERN OBJECT IDENT semiColonOrError
 	{
	    Output("extern %s %s %s%s;",
		   compilerOffsetTypeName,
		   compilerFarKeyword, 
		   $3,
		   _ar);
	    (void) EnterSymbolInGlobal($3, OBJECT_SYM,
 		                       SYM_DEFINED | SYM_EXTERN);
	    SWITCH_CONTEXT( LC_NONE);
	}
    	| EXTERN OBJECT OBJECT_SYM  semiColonOrError
 	{
	    yyerror("%s: cannot make extern, already defined in line %d of '%s'\n",
			$3->name, $3->lineNumber, $3->realFileName);
	    SWITCH_CONTEXT( LC_NONE);
	}
    	| EXTERN CHUNK IDENT  semiColonOrError
 	{
	    Output("extern %s %s %s%s;",
		   compilerOffsetTypeName,
		   compilerFarKeyword, 
		   $3,
		   _ar);
	    (void) EnterSymbolInGlobal($3, CHUNK_SYM,
 		                       SYM_DEFINED | SYM_EXTERN);
	    SWITCH_CONTEXT( LC_NONE);
	}
    	| EXTERN CHUNK CHUNK_SYM  semiColonOrError
 	{
	    yyerror("%s: cannot make extern, already defined in line %d of '%s'\n",
			$3->name, $3->lineNumber, $3->realFileName);
	    SWITCH_CONTEXT( LC_NONE);
	}
    	| EXTERN VIS_MONIKER IDENT semiColonOrError
 	{
	    Output("extern %s %s %s%s;", 
		   compilerOffsetTypeName,
		   compilerFarKeyword,
		   $3,
		   _ar);
	    (void) EnterSymbolInGlobal($3, VIS_MONIKER_CHUNK_SYM,
 		                       SYM_DEFINED | SYM_EXTERN);
	    SWITCH_CONTEXT( LC_NONE);
	}
    	| EXTERN VIS_MONIKER VIS_MONIKER_CHUNK_SYM  semiColonOrError
 	{
	    yyerror("%s: cannot make extern, already defined in line %d of '%s'\n",
			$3->name, $3->lineNumber, $3->realFileName);
	    SWITCH_CONTEXT( LC_NONE);
	}
 	;

/*
 * xxx @OBJ yyy
 *
 * xxx (optr)&OBJ yyy
 */

objectDerefLine	:
    	OBJECT_SYM
 	{
	    Output(" (optr)&%s", $1->name);
	    SWITCH_CONTEXT( LC_NONE);
	}
    	| CHUNK_SYM
 	{
	    Output(" (optr)&%s", $1->name);
	    SWITCH_CONTEXT( LC_NONE);
	}
    	| VIS_MONIKER_CHUNK_SYM
 	{
	    Output(" (optr)&%s", $1->name);
	    SWITCH_CONTEXT( LC_NONE);
	}
 	;

/*
 * @call myObj::MSG_FOO(dorf, whiffle);
 * @send myHandle,myChunk::MSG_FOO(dorf, whiffle);
 * @record myHandle,myChunk::MSG_FOO(dorf, whiffle);
 *
 * ((_MSG_FOO_OM *)&CObjMessage)(dorf, whiffle, <flags>, myHandle, myChunk,
 *	    	    	    	    MSG_FOO, MPD);
 */

sendOrCallOrRecord:
	SEND 	{$$ = MIT_SEND;}    
	|CALL 	{$$ = MIT_CALL;}    
        |RECORD {$$ = MIT_RECORD;}
        ;

sendOrCallOrRecordLine:
        sendOrCallOrRecord             		/* $1 */
 	{
	    /*XXX very nasty SWITCH_CONTEXT(XX) */

	    SWITCH_CONTEXT( LC_PARSE_OBJ_FLAGS_AND_CAST); 
	    
	    /*
	     * This tells the scanner that we'll output the string 
	     * on it's line in the output file, so it doesn't have to 
	     * output newlines if the string spans multiple lines.
	     * If it did, we'd put in extra newlines, and would ruin
	     * the linenumber info.
	     */

	    scannerShouldRealignOutputAndInputAfterLC_STRING = 0;
	}
    	ObjFlagListOrNull 			/* $3 */   
    
	optCastWithNoBraces /* $4    XXX scanner removes the '{' and '}'XXX */ 

        /* scanner will switch contexts to read the objDest */  

    	objDest                        		/* $5 */
 	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
    	':' optCastMessage objMessage '('  	/* $8 $9*/
 	{
	    SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
	}
 	FakeStringOrNothing  	/* $12 */
 	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
 	')'
 	{
	    Symbol *passMsg, *retMsg;
	    Parse_SetReturnAndPassMessage($1,$4, $8, MSG($9),&retMsg,&passMsg);

	    if(passMsg != NullSymbol){  /* if no parse error, continue */

		if (HAS_CHILDREN($5)){
		    Output("CObjSendToChildren(oself, ");
		}
		GenerateComplexPrototype($1,passMsg,retMsg,$5);
		
		Output("CObjMessage)(");
		OutputSubst($12, "@", "(optr)&");
		Output("%s 0x%x, %s, (Message) %s, %s)",
		       (strlen($12)!=0) ? ", " : "",    	  
		       ($3 | RECORD_FLAG($1,$5) | CALL_FLAG($1)), /* flags */
		       DEST($5), 	    	    	    	  /* dest */
		       MSG_OUT($9), 		    	          /* message */
		       GenerateComplexMPDString(passMsg,retMsg,   /* mpd */
						COMPLEX_PARAM_ENUM($1,$5)));
		
		if (HAS_CHILDREN($5)){
		    Output(", %s)", OBJ_CHILDREN($5));
		}
	    }
	    SWITCH_CONTEXT( LC_NONE);
	    scannerShouldRealignOutputAndInputAfterLC_STRING = 1; 
	}
    	;
FakeStringOrNothing: 
        FAKESTRING  {$$ = $1;}
        |  {$$ = String_EnterZT("");}
        ;
        
optCastMessage 	:
    	'{' optCastWithNoBraces '}'  	{$$ = $2;}
        | 				{$$ = NullSymbol;}
	;

/* 
 * When parsing optCastMessage, the scanner has already put itself into 
 * the SWITCH_CONTEXT(so) although the message must be surrounded with '{' '}',
 * they are not shown.
 */

optCastWithNoBraces	:
        MSG_SYM  
    	|  { $$ = NullSymbol; }
 	;

/*
 * @callsuper myObj::MyClass::MSG_FOO(dorf, whiffle);
 * @callsuper;
 *
 * ((_MSG_FOO_OCS *)&CObjCallSuper)(dorf, whiffle, &MyClass, myHandle,
 *	    	    	    	       myChunk, MSG_FOO, MPD);
 */

callsuperLine    :
    	CALL_SUPER
 	{
	    SWITCH_CONTEXT( LC_PARSE_CALLSUPER_OBJ_DEST);
	    scannerShouldRealignOutputAndInputAfterLC_STRING = 0;
	}
    	callsuperStuff
        {
	    scannerShouldRealignOutputAndInputAfterLC_STRING = 1;
        }
        ;

/* the semi-colon should disappear when we've changed all apps to not use it */
semiOrParens:      ';'   {$$ = 1;}

	| '(' ')'        {$$ = 0;}
        ;

callsuperStuff	:
    semiOrParens
 	{
	    MessageParam *pp;

	    if($1){
		yywarning("Old syntax. Please use @callsuper().");
	    }

            /*
	     * If we're using Borland's compiler, temporarily disable the
	     * "Suspected Pointer Conversion" warning here, 'cause it's
	     * pissing us off.
	     */

            if (compiler == COM_BORL) {
		Output("\n#pragma warn -sus\n");
		OutputLineNumber(yylineno,curFile->name);
	    }

	    if (curMethod == NullMethod) {
		yyerror("no current method");
	    } else if (curMethod->htd & MTD_RELOC) {
		/*
		 * This is a relocation method, so we need to call something
		 * different.
		 */
		Output("ObjRelocOrUnRelocSuper(oself,&%s,frame)%s",
		       curMethod->class->name,
		       $1 ? ";" : ""); /*XXX should go away */
	    } else {
		/* must set up an objDest before calling GeneratePrototype */
		SET_OBJ_DEST(&objDest,"",PROTO_ONE_PARAM,"");
	    	GeneratePrototype(MIT_CALLSUPER, curMethod->message, &objDest);

	    	Output("CObjCallSuper)(");
		for (pp = curMethod->message->data.symMessage.firstParam;
			    pp != NullParam; pp = pp->next) {
		    Output("%s, ", pp->name);
		}
	    	Output("&%s, oself", curMethod->class->name);
	    	Output(", message, %s)%s",
		   GenerateMPDString(curMethod->message, 
				     PARAM_ENUM(MIT_CALLSUPER)), 
		       $1?";":"");  /* XXX should go away */
	    }

            if (compiler == COM_BORL) {
		Output("\n#pragma warn .sus\n");
		OutputLineNumber(yylineno,curFile->name);
	    }

	    SWITCH_CONTEXT( LC_NONE);
	}
    	| objDest
 	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
    	':' 
        classOrError 	/* $4 */ 
        ':' ':' 
        messageSymOrIdentErr 	/* $7 */
        '('
 	{
	    SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
	}
	FakeStringOrNothing
 	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
 	')'
 	{
	    if($4 && $7){
		GeneratePrototype(MIT_CALLSUPER,$7, $1);
		Output("CObjCallSuper)(");
		OutputSubst($10, "@", "(optr)&");
		
		Output("%s &%s, %s, (Message) %d, %s)",
		       (strlen($10)!=0) ? ", " : "",    /* separator */
		       $4->name,	    	    	    /* class */
		       DEST($1),  	    	    	    /* dest */
		       $7->data.symMessage.messageNumber, /* message */
		       GenerateMPDString($7, PARAM_ENUM(MIT_CALLSUPER))); 
	    }
	    SWITCH_CONTEXT( LC_NONE);
	}
    	;

objDest	    :
    	FAKESTRING ':'
 	{
	    $$ = &objDest;

	    if (!strcmp($1, "process")) {

		SET_OBJ_DEST($$, 
			     "GeodeGetProcessHandle(), 0", 
			     PROTO_TWO_PARAMS,"");

	    } else if (!strcmp($1, "self")) {

		SET_OBJ_DEST($$, "oself",PROTO_ONE_PARAM,"");

	    } else if (!strcmp($1, "application")) {

		SET_OBJ_DEST($$, 
			     "GeodeGetAppObject(0)",
			     PROTO_ONE_PARAM,
			     "");

	    } else if (!strcmp($1, "null")) {
		
		SET_OBJ_DEST($$, "(optr)0",PROTO_ONE_PARAM,"");

	    } else {
		Symbol *sym;
		/*
		 * If there is just one parameter and if that parameter is
		 * an object then we stick a "(optr) &" in front of it.
		 */
		sym = Symbol_Find($1, TRUE);
		if ((sym != NullSymbol) && ((sym->type == OBJECT_SYM) ||
					    (sym->type == CLASS_SYM))) {
		    sprintf(DEST($$), "(optr) &%s", $1);    
		} else {
		    CopySubst(DEST($$), $1, "@", "(optr)&");
		}
		DEST_TYPE($$) = PROTO_ONE_PARAM;
		*OBJ_CHILDREN($$)	='\0';
	    }

	}
    	| FAKESTRING ',' FAKESTRING ':'
 	{
	    char buf1[1000];
	    char buf2[1000];

	    $$ = &objDest;

	    CopySubst(buf1, $1, "@", "(optr)&");
	    CopySubst(buf2, $3, "@", "(optr)&");

	    sprintf(DEST($$), "%s, %s", buf1, buf2);
	    DEST_TYPE($$) 	= PROTO_TWO_PARAMS;
	    *OBJ_CHILDREN($$)	='\0';
	}
    	| PARENT   			{ SWITCH_CONTEXT( LC_STRING_COMMA);	}
    	FAKESTRING /* $3 */   	',' 	{ SWITCH_CONTEXT( LC_STRING_COLON);	}
    	FAKESTRING /* $6 */ 	':'
 	{
	    $$ = &objDest;

	    sprintf(DEST($$), 
		    "ObjLinkFindParent(oself, %s, %s)", $3, $6);

	    DEST_TYPE($$) 	= PROTO_ONE_PARAM;
	    *OBJ_CHILDREN($$)	='\0';

	    SWITCH_CONTEXT(LC_PARSE);

	}
    	| CHILDREN  			{ SWITCH_CONTEXT( LC_STRING_COMMA);	}
    	FAKESTRING  /* $3 */ 	','
    	FAKESTRING  /* $5 */ 	',' 	{SWITCH_CONTEXT( LC_STRING_COLON);}
    	FAKESTRING  /* $8 */ 	':'         
 	{
	    $$ = &objDest;

	    sprintf(DEST($$), "(optr)0");
	    sprintf(OBJ_CHILDREN($$), "%s, %s, %s",
		    	    	$3, $5, $8);
	    DEST_TYPE($$)	= PROTO_ONE_PARAM;

	    SWITCH_CONTEXT( LC_PARSE);
	}
    	;

/* 
 *  If its not a MSG_SYM, we'd better have a cast, else goc can't put
 *  out a cast or mpd.
 */
objMessage	    :
    	MSG_SYM
 	{
	    $$ = &objMessage;

	    MSG($$) = $1;
	    sprintf(MSG_OUT($$), "%d", $1->data.symMessage.messageNumber);
	}
    	| '('
 	{
	    SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
	}
 	FAKESTRING
 	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
 	')'
 	{
	    $$ = &objMessage;

	    MSG($$) = NullSymbol;
	    strcpy(MSG_OUT($$), $3);
	}
	| IDENT 
	{
            char *cp;
	    for(cp = $1; *cp; cp++){
		if(islower(*cp))
		    break;
	    }
	    /* a little hueristic: if the thing is all upper and an ident */
	    /* it is probably not kosher */
	    if(!*cp){
		yywarning("Perhaps you misspelled your message name %s "
			  "(or maybe it is a C variable of type Message)",
			  $1);
	    }
    	    $$ = &objMessage;
	    MSG($$) = NullSymbol;
	    strcpy(MSG_OUT($$),$1);
	}
    	;

ObjFlagListOrNull    :
    	ObjFlagListOrNull objFlag { $$ = $1 | $2; }
    	| { $$ = 0; }
    	;


objFlag	    	:
    	FORCE_QUEUE {$$ = MF_FORCE_QUEUE; }
    	| RETURN_ERROR {$$ = MF_RETURN_ERROR; }
    	| CHECK_DUPLICATE {$$ = MF_CHECK_DUPLICATE; }
    	| CHECK_LAST_ONLY {$$ = MF_CHECK_LAST_ONLY; }
        | REPLACE {$$ = MF_REPLACE; }
        | INSERT_AT_FRONT {$$ = MF_INSERT_AT_FRONT; }
    	| CAN_DISCARD_IF_DESPARATE {$$ = MF_CAN_DISCARD_IF_DESPERATE; }
    	| NO_FREE {$$ = MF_RECORD; }
    	;

/*
 * @dispatchcall (foo_msg)myObj::MSG_FOO::myMessage
 * @dispatch 		  myObj::MSG_FOO::myMessage
 */
dispatchOrDispatchCall :
	DISPATCH
 	{
	    $$ = (Symbol *)NULL;
	}
    	| DISPATCHCALL
        '(' MSG_SYM ')'
 	{
	    $$ = $3;
	}

dispatchOrDispatchCallLine   :
        dispatchOrDispatchCall 
        {
            SWITCH_CONTEXT( LC_PARSE_NO_LOOKUP);
        }
        IDENT   /* $3 */
        {
	    MsgInvocType mit;      

	    if ($1!= NullSymbol){  /* is this a dispatch call? */
		mit = MIT_DISPATCHCALL;

		if (($1->data.symMessage.mpd & MPD_RETURN_TYPE)
		    == (MRT_MULTIPLE << MPD_RETURN_TYPE_OFFSET)) {
		    yyerror("cannot cast to message %s, it has multiple"
			    " return values",$1->name);
		}
	    }else{
		mit = MIT_DISPATCH;
	    }
	    Output("(");
	    GenerateReturnType(mit, $1, FALSE);
	    Output(")CMessageDispatch(%s, 0x%x, %s)",
		   $3,                                 /* Message handle */
		   $1?MF_CALL:0,                       /* flags */
		   GenerateMPDString(NullSymbol,PARAM_ENUM(mit)));  /* mpd   */

	    SWITCH_CONTEXT( LC_NONE);
        }
        ;

newDispatchOrDispatchCall: 	DISPATCH '(' 
 				{ 
				  SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
				  $$ = NullSymbol;
			      	}
				| DISPATCHCALL
			        '(' '(' MSG_SYM ')'   /* $4 */
				{ $$ = $4;
				  SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
			      	}


newDispatchOrDispatchCallLine:	newDispatchOrDispatchCall
				FAKESTRING                  /* $2 */
				{SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);}
				')'
            {
	    MsgInvocType mit;      

	    if ($1!= NullSymbol){  /* is this a dispatch call? */
		mit = MIT_DISPATCHCALL;

		if (($1->data.symMessage.mpd & MPD_RETURN_TYPE)
		    == (MRT_MULTIPLE << MPD_RETURN_TYPE_OFFSET)) {
		    yyerror("cannot cast to message %s, it has multiple"
			    " return values",$1->name);
		}
	    }else{
		mit = MIT_DISPATCH;
	    }
	    Output("(");
	    GenerateReturnType(mit, $1, FALSE);
	    Output(")CMessageDispatch(%s, 0x%x, %s)",
		   $2,                                 /* Message handle */
		   $1?MF_CALL:0,                       /* flags */
		   GenerateMPDString(NullSymbol,PARAM_ENUM(mit)));  /* mpd   */

	    SWITCH_CONTEXT( LC_NONE);
        }

/*
 * @compiler highc
 */

compilerLine	:
    	COMPILER HIGHC { compiler = COM_HIGHC; SWITCH_CONTEXT( LC_NONE); }
    	| COMPILER MSC { compiler = COM_MSC; SWITCH_CONTEXT( LC_NONE);}
	| COMPILER WATCOM { compiler = COM_WATCOM; SWITCH_CONTEXT( LC_NONE);}
 	;

/*
 * @start Interface
 */

startLine   :
    	START IDENT
	{
	    /*
	     * If we're in the middle of defining a resource, bitch
	     */
	    if (curResource != NullSymbol) {
		yyerror("resource %s declared within resource %s",
			    $2, curResource->name);
	    }
	    /*
	     * Enter the identifier as a resource
	     */
	    curResource = Symbol_Enter($2, RESOURCE_SYM, SYM_DEFINED);
	}
 	startFlags  semiColonOrError
	{
	    curResource->flags |= $4;
	    curResource->data.symResource.nextResource = resourceList;
	    resourceList = curResource;

	    if (curResource->flags & SYM_OBJECT_BLOCK) {
		CompilerStartSegment("__HANDLES_", curResource->name);
		if(compiler == COM_WATCOM) {
		    Output("extern %s "
		    	"__based(__segname(\"__HANDLES_%s\")) _%s_Flags%s;",
    			compilerOffsetTypeName,
    			curResource->name, 
    			curResource->name,
    			_ar);
		}
		else { 
		    Output("extern %s %s _%s_Flags%s;",
			compilerOffsetTypeName,
			compilerFarKeyword, 
			curResource->name,
			_ar);
		}
		CompilerEndSegment("__HANDLES_", curResource->name);
	    }

	    SWITCH_CONTEXT( LC_NONE);
	}

    	| START RESOURCE_SYM 
	{
	    /*
	     * If we're in the middle of defining a resource, bitch
	     */
	    if (curResource != NullSymbol) {
		yyerror("resource %s declared within resource %s",
			    $2, curResource->name);
	    }
	    curResource = $2;

	}
        startFlags semiColonOrError
        {
	    if((curResource->flags &(SYM_NOT_DETACHABLE|SYM_OBJECT_BLOCK) )!= $4){
	      yyerror("resource %s declared with different flags\n",curResource->name);
	    }
	    SWITCH_CONTEXT( LC_NONE);
	}
 	;

startFlags	:
	',' NOT_DETACHABLE
	{
	    $$ = SYM_NOT_DETACHABLE | SYM_OBJECT_BLOCK;
	}
	| ',' DATA
	{
	    $$ = 0;
	}
	| ',' NOT_LMEM
	{
	    $$ = SYM_RESOURCE_NOT_LMEM;
	}
	| { $$ = SYM_OBJECT_BLOCK; }
	;

/*
 * @resourceOutput = MyObj
 */

resourceOutputLine	:
	RESOURCE_OUTPUT '=' objectOrIdent
	{
            Scan_WarnForForwardChunk($3->name);

	    if (curResource == NullSymbol) {
		yyerror("@resourceOutput must appear within @start, @end");
	    } else {
		curResource->data.symResource.resourceOutput = $3;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	}
	;

/*
 * @end Interface
 */

endLine	:
	END RESOURCE_SYM
	{
	    if (curResource != $2) {
	      yyerror("mismatched @start (%s) and @end (%s)",
		      curResource?curResource->name:"none", $2->name);
	    }

	    curResource = NullSymbol;
	    SWITCH_CONTEXT( LC_NONE);
	}
	;

/*
 * @header MyLMemHeader = 3, 4;
 */

headerLine  :
    	HEADER IDENT '='
	{
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	}
 	FAKESTRING
	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
 	';'
	{
	    if (curResource == NullSymbol) {
		yyerror("@header outside of resource definition");
	    } else {
		curResource->data.symResource.header_ctype = $2;
		curResource->data.symResource.header_initializer = $5;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	}

/*
 * @chunk char myText[] = "This is a chunk";
 */

chunkLine   :
    	CHUNK
	{
	    SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	    parse_ScanningAChunk = TRUE;
	}
         typeDeclString '='
	{
            parse_ScanningAChunk = FALSE;
	    realSymbolLineNumber = yylineno;
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	}
    	 FAKESTRING
	{
	    Symbol *chunk;

	    if (curResource == NullSymbol) {
		yyerror("chunk %s outside of any resource", TDS_IDENT($3));
	    } else {
		chunk = Symbol_EnterWithLineNumber(TDS_IDENT($3), 
						   CHUNK_SYM, 
						   SYM_DEFINED,
						   realSymbolLineNumber);
/*XXX check here if(! chunk & SYM_MULTIPLY_DEFINED){  */
		AddChunkToCurResourceAndOutputExtern(chunk);
		chunk->data.symChunk.data = $6;
		chunk->data.symChunk.ctype = TDS_CTYPE($3);
		chunk->data.symChunk.typeSuffix = TDS_TYPESUF($3);

		if (strcmp(chunk->data.symChunk.typeSuffix, "[]") == 0 &&
		    ((strcmp(chunk->data.symChunk.ctype, "char") == 0) ||
		     (strcmp(chunk->data.symChunk.ctype, "wchar_t") == 0) ||
		     (strcmp(chunk->data.symChunk.ctype, "TCHAR") == 0)))
		{
		    LOC_HINT(CHUNK_LOC(chunk)) = CDT_text;
		} else {
		    LOC_HINT(CHUNK_LOC(chunk)) = CDT_unknown;
		}

/*	      } */
	    }
	    SWITCH_CONTEXT( LC_PARSE);
	}
	';' 
	{
	    SWITCH_CONTEXT( LC_NONE);
	    LocalizationCheck();
	}
    	| cArrayType      /* 1 */
  	{
	    SWITCH_CONTEXT( LC_PARSE_NO_LOOKUP);
	}
    	IDENT            /* 3 */
  	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
    	caHeader IDENT   /* 5 6 */
        {
	    realSymbolLineNumber = yylineno;
	}
        '='    /* 8 */
  	{
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	}
    	FAKESTRING {              /* 10 */
	    Symbol *chunk;

	    if (curResource == NullSymbol) {
		yyerror("chunk %s outside of any resource", $6);
	    } else {
	    	chunk = Symbol_EnterWithLineNumber($6, CHUNK_SYM, 
				     SYM_DEFINED,realSymbolLineNumber);
		AddChunkToCurResourceAndOutputExtern(chunk);
	    	chunk->data.symChunk.data = $10;
	    	chunk->data.symChunk.ctype = $3;
		chunk->data.symChunk.headerType = caHeaderType;
		chunk->data.symChunk.headerData = caHeaderData;
		chunk->flags |= $1 | SYM_IS_CHUNK_ARRAY;
		LOC_HINT(CHUNK_LOC(chunk)) = CDT_unknown; 
	    }

	    SWITCH_CONTEXT( LC_PARSE);
	}
	';' 
	{
	    SWITCH_CONTEXT( LC_NONE);
	}
	| GSTRING_SYM		/* $1 */
	{ SWITCH_CONTEXT( LC_PARSE_NO_LOOKUP); }
 	  IDENT			/* $3 */
	{
	    /*
	     * Record line number of identifier for later entering
	     */
	    $<num>$ = yylineno; /* $4 */
	}
	  '='			/* $5 */
	{
	    /*
	     * Ask GStrings rule to include open/close curly in the string.
	     */
	    $<num>$ = TRUE;
	}
	  GStrings		/* $7 */
	{
	    Symbol  *chunk;

	    if (curResource == NullSymbol) {
		yyerror("chunk %s outside of any resource", $3);
	    } else {
		chunk = Symbol_EnterWithLineNumber($3, CHUNK_SYM, SYM_DEFINED,
						   $<num>4);
		AddChunkToCurResourceAndOutputExtern(chunk);
		chunk->data.symChunk.data = $7;
		chunk->data.symChunk.ctype = "byte";
		chunk->data.symChunk.typeSuffix = "[]";
		LOC_HINT(CHUNK_LOC(chunk)) = CDT_GString; 
	    }
	    SWITCH_CONTEXT( LC_PARSE);
	}
	  ';'
	{ 
	    SWITCH_CONTEXT( LC_NONE); 
	    LocalizationCheck();
	}
	;

cArrayType  :
    	CHUNK_ARRAY { $$ = 0; }
    	| ELEMENT_ARRAY { $$ = SYM_IS_ELEMENT_ARRAY; }
 	;

caHeader    :
    	'('
  	{
	    SWITCH_CONTEXT( LC_PARSE_NO_LOOKUP);
	}
    	IDENT '('
  	{
	    SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
	}
    	FAKESTRING
  	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
    	')' ')'
  	{
	    caHeaderType = $3;
	    caHeaderData = $6;
	}
    	|
  	{
	    caHeaderType = caHeaderData = String_EnterZT("");
	}
    	;

/*
 * @object GenClass MyGenObject = { <fields> }
 */

objectLine  :
    	OBJECT classOrError objectOrIdent '=' ignoreDirtyFlag '{'
	{
	    Symbol *class, *super, *bottomClass;
	    
	    (void) EnterSymbolInGlobal($3->name, OBJECT_SYM, SYM_DEFINED);
	    $3->flags |= SYM_IS_OBJECT | $5;
	    curObject = $3;
	    $3->data.symObject.class = $2;
	    if ($2){
		Symbol_PushScope($2->data.symClass.localSymbols);
	    }
	    /*
	     * Deal with default building of things, going all the way up
	     * the class tree.. XXX: doesn't handle overriding default super
	     * more than one level up.
	     */
	    for (class = bottomClass = $2; class != NullSymbol; class = super) {
		super = class->data.symClass.superclass;
		if (class->flags & SYM_CLASS_VARIANT) {
		    /*
		     * If we have hit a variant class then we need to try to
		     * find the variant class for it
		     */
		    if (LocateSuperForVariant(bottomClass, curObject, &super)) {
			/*
			 * Push default superclass's locals too
			 */
			Symbol_PushScope(super->data.symClass.localSymbols);
			bottomClass = super;
		    } else {
			break;
		    }
		}
	    }
	}
    	objectFieldList '}'
	{
	    if (curResource == NullSymbol) {
		yyerror("object %s outside of any resource", $3);
	    } else if (!(curObject->flags & SYM_MULTIPLY_DEFINED)) {
		/*Symbol *iptr;*/

		AddChunkToCurResourceAndOutputExtern($3);

	    }
	    curObject = NullSymbol;
	    SWITCH_CONTEXT( LC_NONE);
	    if($2){
		Symbol_PopScopeTo($2->data.symClass.localSymbols);
	    }
	}
    	;

ignoreDirtyFlag	:
    	IGNORE_DIRTY { $$ = SYM_IGNORE_DIRTY; }
    	| { $$ = 0; }
    	;

objectFieldList	:
	objectFieldList objectField
	| /* empty */
	| objectFieldList fieldError ';'
	{
	    yyerrok;
	}
	| objectFieldList fieldError '}'
	{
	    Scan_Unput('}');
	    yyerrok;
	}
	;

fieldError: error
	{
	    if ((yychar == IDENT) ||
		(yychar > FIRSTSYM && yychar < LASTSYM))
	    {
		yyerror("%s is not a valid instance variable or vardata element for this object",
			(yychar == IDENT) ? $<string>1 : $<sym>1->name);
	    }
	}
	;

optionalArraySize: 	'[' 		{SWITCH_CONTEXT( LC_STRING_CLOSE_BRACE);}
			 FAKESTRING 	{SWITCH_CONTEXT( LC_PARSE); }
			']'             {$$ = $3;}
        | {$$ = NULL;}
    	;

objectField :
	REG_INSTANCE_SYM '='
  	{
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	}
	FAKESTRING
  	{
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = $1->name;
	    inst->value = $4;

	    SWITCH_CONTEXT( LC_PARSE);
	}
 	';'
	| VARIANT_PTR_SYM '='
  	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
	CLASS_SYM
  	{
	    InstanceValue *inst;
	    Symbol *oldScope;

	    SWITCH_CONTEXT( LC_PARSE);

	    /*
	     * XXX: doesn't handle changing variant more than one level up
	     */
	    if (LocateSuperForVariant(curObject->data.symObject.class,
				      curObject, &oldScope)) {
		/*
		 * Replace the old scope
		 */
		Symbol_ReplaceScope(oldScope->data.symClass.localSymbols,
				    $4->data.symClass.localSymbols);
	    } else {
		Symbol_PushScope($4->data.symClass.localSymbols);
	    }

	    inst = MakeInstanceValue(curObject);
 	    inst->name = $1->name;
	    inst->value = $4->name;

	}
 	';'
 	| OPTR_SYM '=' IDENT ';'
  	{
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = $1->name;
	    inst->value = $3;
	    inst->data.instReg.flags |= INST_ADD_OPTR;
	}
 	| OPTR_SYM '=' OBJECT_SYM ';'
  	{
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = $1->name;
	    inst->value = $3->name;
	    inst->data.instReg.flags |= INST_ADD_OPTR;
	}
 	| OPTR_SYM '=' '('
  	{
	    SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
	}
	FAKESTRING
  	{
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = $1->name;
	    inst->value = String_EnterZT($5);
	    SWITCH_CONTEXT( LC_PARSE);
	}
	')' ';'
 	| CHUNK_INST_SYM '=' IDENT ';'
  	{
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = $1->name;
	    inst->value = $3;
	}
 	| CHUNK_INST_SYM '=' someString ';'
  	{
	    InstanceValue *inst;
	    char buf[200];
	    Symbol *chunk;

	    if (curResource == NullSymbol) {
		yyerror("object %s outside of any resource", curObject);
	    } else {
		sprintf(buf, "_%s_%s", $1->name, curObject->name);
		chunk = Symbol_Enter(String_EnterZT(buf),
				     CHUNK_SYM, SYM_DEFINED);
		chunk->flags |= SYM_CHUNK_NEEDS_QUOTES;
		AddChunkToCurResourceAndOutputExtern(chunk);
		chunk->data.symChunk.data = $3;
		chunk->data.symChunk.ctype = curStringType;
		chunk->data.symChunk.typeSuffix = String_EnterZT("[]");
		LOC_HINT(CHUNK_LOC(chunk)) = CDT_text; 
		inst = MakeInstanceValue(curObject);
		inst->name = $1->name;
		inst->value = chunk->name;
	    }
	    LocalizationCheck();
	}
 	| CHUNK_INST_SYM '=' CHUNK_SYM ';'
  	{
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = $1->name;
	    inst->value = $3->name;
	}
 	| CHUNK_INST_SYM '=' OBJECT_SYM ';'
  	{
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = $1->name;
	    inst->value = $3->name;
	}
    	| VIS_MONIKER_SYM
 	{
	    Symbol_PushScope(visMonikerScope);
	    curVisMonField = $1;
	}
	visMonikerFieldFinish optSemiColon 

    	| VARDATA_SYM ';'
 	{
	    if ($1->data.symVardata.ctype != String_EnterZT("void")) {
		yyerror("Initializer cannot be given for void vardata %s",
			$1->name);
	    }
	    AddVarData($1, String_EnterZT(""),NULL);
	}
    	| VARDATA_SYM optionalArraySize '='
 	{
	    if ($1->data.symVardata.ctype == String_EnterZT("void")) {
		yyerror("No initializer given for vardata %s (type %s)",
			$1->name, $1->data.symVardata.ctype);
	    }
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	}
    	FAKESTRING
 	{
	    SWITCH_CONTEXT( LC_PARSE);
	}
    	';'
 	{
	    AddVarData($1, $5,$2);
	}
	| GCN_LIST '(' identOrConst ',' identOrConst ')' '=' aleArrayN
	{
	    Symbol *gcnList;
	    char buf[1000];

	    /* define symbol for this particular gcn list */
	    sprintf(buf, "_%s_gcnL_%s_%s", curObject->name, $3, $5);
	    gcnList = Symbol_Enter(String_EnterZT(buf),
						GCN_LIST_SYM, SYM_DEFINED);
	    gcnList->flags |= SYM_DEFINED;
	    gcnList->data.symGCNList.firstItem = $8;
	    AddChunkToCurResourceAndOutputExtern(gcnList);

	    /* create gcn list of lists, if necessary, else, just hook new
	       gcn list onto end of list of lists */
	    if (curObject->data.symObject.gcnListOfLists == NullSymbol) {
		Symbol *listOfLists;
		Symbol *tempMetaGCNSym;
		Symbol *metaClass;
	        char buf[300];

	        sprintf(buf, "_%s_gcnLOL", curObject->name);
	        listOfLists = Symbol_Enter(String_EnterZT(buf),
					GCN_LIST_OF_LISTS_SYM, SYM_DEFINED);
	        listOfLists->flags |= SYM_DEFINED;
	        AddChunkToCurResourceAndOutputExtern(listOfLists);
	        curObject->data.symObject.gcnListOfLists = listOfLists;
		curObject->data.symObject.gcnListOfLists->data.symGCNListOfLists.firstList = gcnList;

		/* new list of lists created, add a piece of var data to point
		   to the list of lists */
		metaClass = Symbol_Find(String_EnterZT("MetaClass"),
					ALL_SCOPES);
		if ((metaClass != NullSymbol) && (metaClass->type == CLASS_SYM))
		{
		    Symbol_PushScope(metaClass->data.symClass.localSymbols);
		    tempMetaGCNSym = Symbol_Find(String_EnterZT("TEMP_META_GCN"), 
						 LOCAL_SCOPE);
		    Symbol_PopScope();
		    if (tempMetaGCNSym != NullSymbol) {
			sprintf(buf, "{{((ChunkHandle)(optr)&_%s_gcnLOL)}, 0}", 
				curObject->name);
			AddVarData(tempMetaGCNSym, String_EnterZT(buf),NULL);
		    } else {
			yyerror("TEMP_META_GCN symbol not found");
		    }
		} else {
		    yyerror("MetaClass not defined");
		}
	    } else {
		Symbol **field;
		for (field = &(curObject->data.symObject.gcnListOfLists->data.symGCNListOfLists.firstList);
			*field != NullSymbol;
			field = &((*field)->data.symGCNList.nextList));
		*field = gcnList;
	    }
	    gcnList->data.symGCNList.manufID = $3;
	    gcnList->data.symGCNList.type = $5;
	}
 	| COMPOSITE_SYM '='
	{
	    curLastChild = NullInstanceValue;
	    curLinkPart = $1->data.symComposite.linkPart;
	}
	childList ';'
	{
	    if (curLastChild != NullInstanceValue) {
		InstanceValue *inst;

	    	inst = MakeInstanceValue(curObject);
		inst->name = $1->name;
		inst->data.instLink.link = curFirstChild;
		curLastChild->data.instLink.isParentLink = TRUE;
		curLastChild->data.instLink.link = curObject;
		if (curLinkPart->flags & SYM_IS_KBD_PATH) {
		    curLastChildObj->data.symObject.kbdPathParent = curObject;
		}
	    }
	}
 	| KBD_ACCELERATOR_SYM kbdAcceleratorStart '=' specificUIOrNothing
    	    	    	kbdAccelModList kbdAccelChar ';'
	{
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = $1->name;
	    inst->data.instKbdAccelerator.specificUI = $4;
	    inst->data.instKbdAccelerator.flags = $5;
	    inst->data.instKbdAccelerator.key = $6;
	    curObject->flags |= SYM_HAS_KBD_ACCEL;
	    (void) Symbol_PopScope();
	}
	| LINK_SYM '=' objectOrIdent ';'
  	{
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = $1->name;
	    inst->value = $3->name;
	    inst->data.instLink.link = $3;
	    inst->data.instLink.isParentLink = TRUE;
	}

	| LocalizationLine
	;
/* the localization stuff works on the last chunk entered with	*/
/* AddChunkToCurResourceAndOutputExtern(). 			*/

someString:
        STRING {$$ = $1; curStringType = defStringType;}
        | ASCIISTRING {$$ = $1; curStringType = asciiStringType;}
        | TSTRING {$$ = $1; curStringType = defStringType;}
        | LSTRING {$$ = $1; curStringType = lStringType;}
        | SJISSTRING {$$ = $1; curStringType = sjisStringType;}
        ;

LocalizationLine	:    	
    	LOCALIZE '{' STRING  CONST '}' ';'
	{
	    localizationRequired = FALSE;
	    if (chunkToLocalize == NULL) {
		yyerror("You have entered no chunk that could need localizing\n");
	    } else if(!CHUNK_LOC(chunkToLocalize)){
		yyerror("This chunk (%s) is not localizable\n",
			chunkToLocalize->name);
	    }else{
		LOC_NAME(CHUNK_LOC(chunkToLocalize)) = chunkToLocalize->name;
		LOC_INST(CHUNK_LOC(chunkToLocalize)) = $3;
		LOC_MIN(CHUNK_LOC(chunkToLocalize))=
		    LOC_MAX(CHUNK_LOC(chunkToLocalize))= $4;
	    }
	    
	}
    	| LOCALIZE '{' STRING  CONST '-' CONST '}' ';'
	{
	    localizationRequired = FALSE;
	    if (chunkToLocalize == NULL) {
		yyerror("You have entered no chunk that could need localizing\n");
	    } else if(!CHUNK_LOC(chunkToLocalize)){
		yyerror("This chunk (%s) is not localizable\n", 
			chunkToLocalize->name);
	    }else{
		LOC_NAME(CHUNK_LOC(chunkToLocalize)) = chunkToLocalize->name;
		LOC_INST(CHUNK_LOC(chunkToLocalize)) = $3;
		LOC_MIN(CHUNK_LOC(chunkToLocalize))  = $4;
		LOC_MAX(CHUNK_LOC(chunkToLocalize))  = $6;
		if($4 > $6){
		    yyerror("Min size is greater than Max size\n");
		}else if ($4 == $6){
		    yywarning("Min size is equal to Max size.");
		    yywarning("Perhaps you want a different syntax");
		}
	    }
	}
    	| LOCALIZE NOT ';'
	{
	    localizationRequired = FALSE;
	    if (chunkToLocalize == NULL) {
		yyerror("You have entered no chunk that could need localizing\n");
	    } else if(!CHUNK_LOC(chunkToLocalize)){
		yyerror("This chunk (%s) is not localizable\n", 
			chunkToLocalize->name);
	    }else{
		LOC_NAME(CHUNK_LOC(chunkToLocalize)) = chunkToLocalize->name;
		LOC_INST(CHUNK_LOC(chunkToLocalize)) = "";
		LOC_MIN(CHUNK_LOC(chunkToLocalize))  = -1;
		LOC_MAX(CHUNK_LOC(chunkToLocalize))  = -1;
	    }
	}
	| simpleLocalization
	{
	    localizationRequired = FALSE;
	    if (chunkToLocalize == NULL) {
		yyerror("You have entered no chunk that could need localizing\n");
	    } else if(!CHUNK_LOC(chunkToLocalize)){
		yyerror("This chunk (%s) is not localizable\n",
			chunkToLocalize->name);
	    }else{
		LOC_NAME(CHUNK_LOC(chunkToLocalize)) = chunkToLocalize->name;
		LOC_INST(CHUNK_LOC(chunkToLocalize)) = $1;
		LOC_MIN(CHUNK_LOC(chunkToLocalize))  = 0;
		LOC_MAX(CHUNK_LOC(chunkToLocalize))  = 0;
	    }
	}
	;

simpleLocalization: 
    	LOCALIZE '{'STRING  '}' ';' {$$ = $3;}
	| LOCALIZE  STRING ';'      {$$ = $2;}
    	;



visMonikerFieldFinish	:
    	| '=' VIS_MONIKER_CHUNK_SYM 
 	{
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = curVisMonField->name;
	    inst->value = $2->name;
	    Symbol_PopScope();
	}
	| '='
 	{
	    char buf[200];

	    sprintf(buf, "_%s_%s", curVisMonField->name, curObject->name);
	    curVisMoniker = Symbol_Enter(String_EnterZT(buf),
					VIS_MONIKER_CHUNK_SYM, SYM_DEFINED);

	}
    	visMonikerDef
 	{
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = curVisMonField->name;
	    inst->value = curVisMoniker->name;

	    SWITCH_CONTEXT( LC_PARSE);
	}

aleArrayN	:
    	aleArray ';' { $$ = $1; }
	| ';' { $$ = NullSymbolListEntry; }
	;

aleArray		:
 	aleArray ',' aleArrayElement
	{
	    SymbolListEntry **sle;

	    $$ = $1;
	    if ($$ == NullSymbolListEntry) {
		$$ = $3;
	    } else {
		for (sle = &($$->next); *sle != NullSymbolListEntry;
		    	    	    	    	sle = &((*sle)->next));
		*sle = $3;
	    }
	}
	| aleArrayElement
	;

aleArrayElement	:
 	objectOrIdent
	{
            Scan_WarnForForwardChunk($1->name);
	    $$ = (SymbolListEntry *) zmalloc(sizeof(SymbolListEntry));
	    $$->entry = $1;
	}
	;

/*
 * Keyboard accelerators:
 *
 * Push kbdAcceleratorScope so that we get all the special stuff
 */

kbdAcceleratorStart :
 	{
	    Symbol_PushScope(kbdAcceleratorScope);
	}
	;

kbdAccelChar	:
    	CHAR
	{
	    $$ = $1;
	    if (isupper($$)) {
		$$ = tolower($$);
	    }
	    if (isalpha($$)) {
		$$ = (KEY_ALPHA << 16) | $$;
	    } else if (isdigit($$)) {
		$$ = (KEY_DIGIT << 16) | $$;
	    } else if (!$$) {
		yyerror("keyboard accelerator must be alpha-numeric");
		$$ = (KEY_ALPHA << 16) | 'a';
	    } else {
		$$ = (KEY_PUNCT << 16) | $$;
	    }
	}
	|
	KBD_SYM
	{
	    $$ = $1->data.symSpecial.value;
	}
	;

specificUIOrNothing : SPECIFIC_UI { $$ = 1; }
	| { $$ = specificUI; }
	;

kbdAccelModList : kbdAccelModList KBD_MODIFIER_SYM
	{
	    $$ = $1 | $2->data.symSpecial.value;
	}
	|  { $$ = 0; }
	;

/*
 * Visual moniker stuff
 */

childList	:
    	childListNN
	|
	;

childListNN	: childListNN ',' childNN
	| childNN
	;

childNN		:
    	objectOrIdent
	{
	    InstanceValue *inst;

            Scan_WarnForForwardChunk($1->name);

	    if($1 == curObject){
		yyerror("The parent %s is its own child. This will "
			"fail at runtime.",$1->name);
	    }

	    $1->flags |= SYM_CANNOT_BE_EXTERN;
	    if (curLastChild != NullInstanceValue) {
		curLastChild->data.instLink.link = $1;
	    } else {
		curFirstChild = $1;
	    }
	    inst = MakeInstanceValue($1);
	    inst->name = curLinkPart->name;
	    curLastChild = inst;
	    curLastChildObj = $1;
	}
	| error

/*
 * @visMoniker mo = 'H', "Hi Mom";
 */

visMonikerLine :
    	VIS_MONIKER visMonikerOrIdent '='
 	{
	    Symbol_Enter($2->name, VIS_MONIKER_CHUNK_SYM, SYM_DEFINED);
	    Symbol_PushScope(visMonikerScope);
	    curVisMoniker = $2;
	}
 	visMonikerDef
  	{
	    SWITCH_CONTEXT( LC_NONE);
	}
	;

optSemiColon:   ';'
 		| /* empty */
    		;

/*
 * Support parsing for vis monikers -- its a kludge, but it is useful
 */

visMonikerDef :
	{
	    curVisMoniker->data.symVisMoniker.vmXSize=0;
	    curVisMoniker->data.symVisMoniker.vmYSize=0;
	    curVisMoniker->data.symVisMoniker.vmType.gsSize = DS_STANDARD;
	    curVisMoniker->data.symVisMoniker.vmType.monikerList = 0;
	    curVisMoniker->data.symVisMoniker.vmType.gstring = 0;
	    curVisMoniker->data.symVisMoniker.vmType.aspectRatio = DAR_NORMAL;
	    curVisMoniker->data.symVisMoniker.vmType.gsColor = DC_GRAY_1;
	    curVisMoniker->data.symVisMoniker.vmType.style = VMS_TEXT;
	    haveVMStyle = FALSE;
	}
	vmMiddle
	{
	    /*
	     * Output the moniker
	     */
	    if (curResource == NullSymbol) {
		yyerror("vis moniker %s outside of any resource",
			    	    	    	curVisMoniker->name);
	    } else {
		AddChunkToCurResourceAndOutputExtern(curVisMoniker);
		LocalizationCheck();
	    }
	    Symbol_PopScope();
	}
	| error
	{
	    Symbol_PopScope();
	}
    	;

vmMiddle      :
    	LIST_SYM '{' vmArray '}' 
	{
	    /* not localizable, so remove the data */
	    REMOVE_LOCALIZATION_DATA(curVisMoniker);
	    curVisMoniker->flags |= SYM_LIST_MONIKER;
	    curVisMoniker->data.symVisMoniker.list = $3;
	}
	| vmMiddleNonList {	    
	    LOC_HINT(CHUNK_LOC(curVisMoniker)) = CDT_visMoniker; 
	}
	;

vmMiddleNonList	:
    	vmNavChar ';'   
	| '{' vmList vmNavChar ';' '}'      
	| GSTRING_SYM vmGStrings            
        { 
	  curVisMoniker->flags |= SYM_GSTRING_MONIKER; 
	  if (!haveVMStyle) {
	      curVisMoniker->data.symVisMoniker.vmType.style = VMS_ICON;
	  }
	}
        | '{' vmList GSTRING_SYM   vmGStrings '}'     
        { 
	  curVisMoniker->flags |= SYM_GSTRING_MONIKER; 
	  if (!haveVMStyle) {
	      curVisMoniker->data.symVisMoniker.vmType.style = VMS_ICON;
	  }
	}
	;

vmNavChar	:
    	CHAR ',' someString
	{
 	    curVisMoniker->data.symVisMoniker.navChar = $1;
 	    curVisMoniker->data.symVisMoniker.navType = NT_CHAR;
 	    curVisMoniker->data.symVisMoniker.vmText = $3;
 	    curVisMoniker->data.symVisMoniker.ctype = curStringType;
	}
	| CONST ',' someString
	{
 	    curVisMoniker->data.symVisMoniker.navConst = $1;
 	    curVisMoniker->data.symVisMoniker.navType = NT_CONST;
 	    curVisMoniker->data.symVisMoniker.vmText = $3;
 	    curVisMoniker->data.symVisMoniker.ctype = curStringType;
	}
	| STRING ',' someString
	{
 	    curVisMoniker->data.symVisMoniker.navString = $1;
 	    curVisMoniker->data.symVisMoniker.navType = NT_STRING;
 	    curVisMoniker->data.symVisMoniker.vmText = $3;
 	    curVisMoniker->data.symVisMoniker.ctype = curStringType;
	}
	| someString
	{
 	    curVisMoniker->data.symVisMoniker.navConst = 0xff;
 	    curVisMoniker->data.symVisMoniker.navType = NT_CONST;
 	    curVisMoniker->data.symVisMoniker.vmText = $1;
 	    curVisMoniker->data.symVisMoniker.ctype = curStringType;
	}
	;

vmList		:
    	vmList vmElement
	|
	;

		  /* get new vmtext for our symbol, set its global */
		  /* state for insertion of the gstring contents   */
/*
 *
 *              
 *
 */

vmGStrings:  /* empty */
	{
	    /* setup up vis moniker in preparation, in case of error */
	    curVisMoniker->data.symVisMoniker.startLine = yylineno;
	    curVisMoniker->data.symVisMoniker.vmText = "";
	    /*
	     * Don't include open/close curly in the string.
	     */
	    $<num>$ = FALSE;
	}
	GStrings 
	{
	    curVisMoniker->data.symVisMoniker.vmText = $2;
	}
	;

GStrings: '{'  
	{
	    INIT_DYNAMIC_BUFFER(gstringBuf,GS_BUF);
	    /*
	     * Add open-curly if calling rule requested it
	     */
	    if ($<num>0) {
		ADD_CHAR_TO_DYNAMIC_BUFFER('{',gstringBuf);
	    }
	    SWITCH_CONTEXT( LC_CLOSE_CURLY_OR_STRING);
	    
	}
	  gstringBodyElementList

	{ 
	    SWITCH_CONTEXT( LC_PARSE); 
	}
          '}'  
	{
	    /*
	     * Add close-curly if calling rule requested it.
	     */
	    if ($<num>0) {
		ADD_CHAR_TO_DYNAMIC_BUFFER('}',gstringBuf);
	    }
	    ADD_CHAR_TO_DYNAMIC_BUFFER('\0',gstringBuf);
	    $$ = DB_STR(gstringBuf);
	}
	;
gstringBodyElementList: gstringBodyElementList gstringBodyElement
	| /* empty */
	;

gstringBodyElement:
           FAKESTRING    {AddStringToCurrentGstringBuffer($1); }
	|  STRING        {AddStringCharsToCurrentGstringBuffer($1); }
	| error
	{
	    yyerror("invalid graphics-string element");
	    yyerrok;
	}
        ;


vmElement	:
	ASPECT_RATIO_SYM '=' ASPECT_RATIO_COMP_SYM ';'
	{
	    curVisMoniker->data.symVisMoniker.vmType.aspectRatio =
		    	    	$3->data.symSpecial.value;
	}
	| STYLE_SYM '=' STYLE_COMP_SYM ';'
	{
 	    curVisMoniker->data.symVisMoniker.vmType.style =
		    	    	$3->data.symSpecial.value;
	    haveVMStyle = TRUE;
	}
	| COLOR_SYM '=' COLOR_COMP_SYM ';'
	{
 	    curVisMoniker->data.symVisMoniker.vmType.gsColor =
		    	    	$3->data.symSpecial.value;
	}
	| SIZE_SYM '=' SIZE_COMP_SYM ';'
	{
 	    curVisMoniker->data.symVisMoniker.vmType.gsSize =
		    	    	$3->data.symSpecial.value;
	}
	| CACHED_SIZE_SYM '=' CONST ',' CONST ';'
	{
 	    curVisMoniker->data.symVisMoniker.vmXSize = $3;
 	    curVisMoniker->data.symVisMoniker.vmYSize = $5;
	}
	| error ';'
	{
	    yyerrok;
	}
	| error '}'
	{
	    Scan_Unput('}');
	    yyerrok;
	}
	;

vmArray		:
 	vmArray ',' vmArrayElement
	{
	    SymbolListEntry **sle;

	    $$ = $1;
	    if ($$ == NullSymbolListEntry) {
		$$ = $3;
	    } else {
		for (sle = &($$->next); *sle != NullSymbolListEntry;
		    	    	    	    	sle = &((*sle)->next));
		*sle = $3;
	    }
	}
	| vmArrayElement
	;

vmArrayElement	:
 	visMonikerOrIdent
	{
            Scan_WarnForForwardChunk($1->name);
	    $$ = (SymbolListEntry *) zmalloc(sizeof(SymbolListEntry));
	    $$->entry = $1;
	}
	| vmArrayError ','
	{
	    Scan_Unput(',');
	    yyerrok;
	}
	| vmArrayError '}'
	{
	    Scan_Unput('}');
	    yyerrok;
	}
	;

vmArrayError: error
	{
	    yyerror("elements of a visMoniker list must be visMoniker chunk names");
	}
	;

/*
 * Little utilities
 */

objectOrIdent	:
    	OBJECT_SYM
    	| IDENT
 	{
	    $$ = EnterSymbolInGlobal($1, OBJECT_SYM, 0);
	    AddChunkToUndefinedList($$);
	}
    	;

protoMinorSym	:
    	PROTOMINOR_SYM
 	{
            $$ = $1;
        }
    	| IDENT
 	{
            Symbol    *sym;

	    sym = EnterSymbolInGlobal($1, PROTOMINOR_SYM, 0);
            sym->data.symProtoMinor.msgOrVardataSym = NullSymbol;
            sym->data.symProtoMinor.references = 0;
            $$ = sym;
	}
    	;

visMonikerOrIdent	:
    	VIS_MONIKER_CHUNK_SYM
    	| IDENT
 	{
	    $$ = EnterSymbolInGlobal($1, VIS_MONIKER_CHUNK_SYM, 0);
	    AddChunkToUndefinedList($$);
	}
    	;

identOrConst		:
	IDENT
	| CONST
	{
	    char buf[100];
	    sprintf(buf, "%d",$1);
	    $$ = String_EnterZT(buf);
	}
	;

typeDeclString	: /* if ctype is blank, SplitTypeString will post a warning */
        STRING 
        {
	  char *ctype;
	  char *id;
	  char *typesuffix;


	  $$ = AllocTypeDeclString();
	  SplitTypeString($1,&ctype,&id,&typesuffix);
	  
	  /* make sure the strings are hashed */
	  TDS_CTYPE($$) = String_EnterZT(ctype);
	  TDS_IDENT($$) = String_EnterZT(id);
	  TDS_TYPESUF($$) = String_EnterZT(typesuffix);
	  
        }
        ;

%%


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
	     Symbol	*otherClass,	    /* Class of symbol being
					     * referenced */
	     Symbol	*bottomClass)	    /* Bottom-most class in current
					     * master level */
{
    int	    retval;

    if (curClass == NULL) {
	return(FALSE);
    }
#define SYM_CLASS_CHECKING SYM_IS_CHUNK_ARRAY	/* overload a bit that
						 * can't possibly be set for
						 * this symbol */
    
    curClass->flags |= SYM_CLASS_CHECKING;

    retval = (curClass == otherClass);
    if (!retval) {
	Symbol  *class;
	int 	i;
	
	for (i = 0; i < curClass->data.symClass.numUsed; i++) {
	    class = curClass->data.symClass.used[i];

	    /*
	     * Check friendly class, assuming it's the bottom-most class in
	     * its master level, so far as we're concerned.
	     */
	    if (!(class->flags & SYM_CLASS_CHECKING) &&
		CheckRelated(class, otherClass, class))
	    {
		retval = TRUE;
		break;
	    }
	}
    }

    if (!retval) {
	Symbol      *super;
	if (!(curClass->flags & SYM_CLASS_VARIANT) ||
	    !LocateSuperForVariant(bottomClass, NullSymbol, &super))
	{
	    retval = CheckRelated(curClass->data.symClass.superclass,
				  otherClass,
				  (curClass->flags & SYM_CLASS_MASTER ?
				   curClass->data.symClass.superclass :
				   bottomClass));
	} else {
	    retval = CheckRelated(super, otherClass, super);
	}
    }

    curClass->flags &= ~SYM_CLASS_CHECKING;

    return(retval);
}
	
/***********************************************************************
 *
 * FUNCTION:	AddChunkToCurResourceAndOutputExtern
 *
 * DESCRIPTION:	Add a chunk to the current resource
 *
 * CALLED BY:	yyparse
 *
 * RETURN:	chunk added, line number and file name set
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
AddChunkToCurResourceAndOutputExtern(Symbol *chunk)
{
    Symbol **cptr;

    /*
     * Remove chunk from undefined list if needed
     */
    for (cptr = &undefinedList; *cptr != NullSymbol;
	 cptr = &((*cptr)->data.symChunk.nextChunk)) {
	if (*cptr == chunk) {
	    *cptr = chunk->data.symChunk.nextChunk;
	    chunk->data.symChunk.nextChunk = NullSymbol;
 	    break;
	}
    }

    chunk->data.symChunk.resource = curResource;
    curResource->data.symResource.numberOfChunks++;
    if(CHUNK_LOC(chunk)){
	LOC_NAME(CHUNK_LOC(chunk))= chunk->name;
    }
    for (cptr = &(curResource->data.symResource.firstChunk);
	 *cptr != NullSymbol;
	 cptr = &((*cptr)->data.symChunk.nextChunk)) ;
    *cptr = chunk;
    /*
     * Output an extern definition for the chunk so that it can
     * be referenced
     */
    if (curResource != NULL) {
	CompilerStartSegment("__HANDLES_", curResource->name);
	if(compiler == COM_WATCOM) {
		Output("extern %s "
		"__based(__segname(\"__HANDLES_%s\")) %s%s;", 
    		compilerOffsetTypeName,
    		curResource->name,
    		chunk->name,
    		_ar);
	}
	else {
	    Output("extern %s %s %s%s;", 
		compilerOffsetTypeName,
		compilerFarKeyword,
		chunk->name,
		_ar);
        }
	CompilerEndSegment("__HANDLES_", curResource->name);
    }

    /* Make sure the previous localizable chunk has the localization
       instruction. */
    if ( localizationRequired ){
	Parse_LocalizationWarning("Missing @localize statement");
	localizationRequired = FALSE;	/* reset the flag */
    }
    chunkToLocalize = chunk;
}

/***********************************************************************
 *
 * FUNCTION:	AddChunkToUndefinedList
 *
 * DESCRIPTION:	Add a chunk to the undefined list
 *
 * CALLED BY:	yyparse
 *
 * RETURN:	chunk added
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
AddChunkToUndefinedList(Symbol *chunk)
{
    chunk->data.symChunk.nextChunk = undefinedList;
    undefinedList = chunk;
}

/***********************************************************************
 *
 * FUNCTION:	EnterSymbolInGlobal
 *
 * DESCRIPTION:	Enter a symbol in the global scope
 *
 * CALLED BY:	yyparse
 *
 * RETURN:	symbol entered
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
Symbol *
EnterSymbolInGlobal(char *name, int type, int flags)
{
    Symbol *sym;

    /*
     * We always want to enter symbols in the global scope
     */
    Symbol_PushScope(globalScope);
    sym = Symbol_Enter(name, type, flags);
    Symbol_PopScope();
    return(sym);
}

/***********************************************************************
 *
 * FUNCTION:	AddRegDefinition
 *
 * DESCRIPTION:	Add a register to a MPD
 *
 * CALLED BY:	yyparse
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
AddRegDefinition(MessagePassRegs reg)
{
    if (numRegs == 3) {
	yyerror("only three registers can be used");
    } else if (currentMPD & MPD_STRUCT_AT_SS_BP) {
	yyerror("ss:bp cannot be used with any other register");
    } else {
    	currentMPD |= MPD_REGISTER_PARAMS | (reg << (numRegs*3));
	numRegs++;
    }
}

char *
String_EnterZT(char *s)
{
    return (String_Enter(s, strlen(s)));
}

/***********************************************************************
 *				yyerror
 ***********************************************************************
 * SYNOPSIS:	  Print an error message with the current line #
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
void
yyerror(const char *fmt, ...)
{
    va_list	args;

    va_start(args, fmt);

#if defined(unix)
    fprintf(stderr, "file %s, line %d: ", curFile->name, yylineno);
#else
    fprintf(stderr, "Error %s %d: ", curFile->name, yylineno);
#endif
    vfprintf(stderr,fmt,args);
    putc('\n', stderr);

    yyerrors++;
    va_end(args);
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
void
yywarning(char *fmt, ...)
{
    va_list	args;

    va_start(args, fmt);

#if defined(unix)
    fprintf(stderr, "file %s, line %d Warning: ", curFile->name, yylineno);
#else
    fprintf(stderr, "Warning %s %d: ", curFile->name, yylineno);
#endif
    vfprintf(stderr,fmt,args);
    putc('\n', stderr);
    va_end(args);
}


/***********************************************************************
 *
 * FUNCTION:	GenerateReturnType
 *
 * DESCRIPTION:	Output a return type for a message invocation
 *
 * PASS:   
 *         
 *         msgInvocType: 	send/record/call/dispatch enum
 *         message symbol:  	tells the message-return-type
 *         Boolean children:    tells if is sending to children
 *         
 * CALLED BY:	yyparse rules
 *
 * SYNOPSIS:  This puts out a return value for the message invocation.
 *       
 *            There are three types of values: 
 *                  EventHandle, void, and a message specific value.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	josh	9/92		Initial Revision
 *
 ***********************************************************************/
void 
GenerateReturnType(MsgInvocType mit, Symbol *msgSym, Boolean children)
{
    /* 
     * If its dest is the children, we can't receive return values,
     */
    if(HAS_RECORD_FLAG(mit,children)){  
	Output("EventHandle");
	if(IS_CALL_TYPE(mit)){
	    yyerror("cannot do @call to children (can't get return values)");
	}
	if((mit == MIT_RECORD) && children){
	    yyerror("can't record message sent to children");
	}
    }else if(IS_CALL_TYPE(mit)){
	assert(msgSym);
	Output("%s _pascal ", msgSym->data.symMessage.returnType);
    }else{
	Output("void");
    }
}

/***********************************************************************
 *
 * FUNCTION:	GeneratePrototype
 *
 * DESCRIPTION:	Generate a prototype for a message call
 *
 * PASS:   MsgInvocType -- type of invocation: either send,record, 
 * 				call or callsuper.
 *         Symbol *msg  -- message symbol telling how to pass/return params
 *                                (overridden for @children, @record)
 *         ObjDest *od  -- objDest value parsed for this invocation.
 *
 * CALLED BY:	yyparse
 *
 * RETURN:	void
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *      josh    9/92            revamp for sdk release
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void 
GeneratePrototype(MsgInvocType mit, Symbol *msg, ObjDest *od)
{
    GenerateComplexPrototype(mit,msg,msg,od);
}




/***********************************************************************
 *
 * FUNCTION:	GenerateComplexPrototype
 *
 * DESCRIPTION:	Generate a prototype for a message call
 *               this is used for @send/@call/@record/@callsuper
 *
 * PASS:   MsgInvocType -- type of invocation: either send,record, 
 * 				call or callsuper.
 *         Symbol *passMsg -- message symbol telling how to pass params
 *                                (overridden for @children, @record)
 *         Symbol *retMsg  -- message symbol telling how to return params
 *
 *         ObjDest *od  -- objDest value parsed for this invocation.
 *
 * CALLED BY:	yyparse
 *
 * SYNOPSIS:  output in order:
 * 		 	return type,
 *                   	params, 
 * 			flags (or "ClassStruct *" for callsuper),
 * 			dest,
 * 			Message,
 *           		mpd
 * 
 * WARNING: Don't call this for  @dispatch[call]; they have fixed 
 *             parameter lists.
 *             
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *      josh    9/92            revamp for sdk release
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
GenerateComplexPrototype(MsgInvocType mit,/* record/call/send/callsuper */
		  Symbol *passMsg,      /* msg symbol being sent.    */
		  Symbol *retMsg,       /* msg symbol being sent.    */
		  ObjDest *od)          /* objDest for this invocation 	*/

{
    MessageParam *pp;

    Output("((");
    GenerateReturnType(mit,retMsg,HAS_CHILDREN(od));
    Output(" _pascal (*)(");
    /* pump out the params for the msg */

    assert(passMsg != NullSymbol);
    for (pp = passMsg->data.symMessage.firstParam;
	 pp != NullParam; pp = pp->next) {
	Output("%s%s,", pp->ctype,pp->typeSuffix);
    }
    
    if (mit != MIT_CALLSUPER){
	Output("word,");    /* XXX */
    } else {
	Output("ClassStruct *,");  /* XXX */
    }

    if (DEST_TYPE(od) == PROTO_ONE_PARAM) {
	Output("optr,");                 /* XXX */
    } else {
	assert(DEST_TYPE(od) == PROTO_TWO_PARAMS);
	Output("MemHandle, ChunkHandle,");
    }

    Output("Message,word))");
}

/***********************************************************************
 *
 * FUNCTION:	GenerateMethodDef
 *
 * DESCRIPTION:	Generate a method definition
 *
 * CALLED BY:	yyparse
 *
 * PASS:        meth: method do dump out, 
 *
 * RETURN:	none
 *
 * note: this thing will output something like:
 *  char * fooBAR(fooInstance *pself, optr oself, Message message, int a)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
GenerateMethodDef(Method *meth)
{
    MessageParam *pp;

    /*
     * We want to prevent any "oself unused in function" (sic) warnings,
     * and we can't do it in Borlnd any later than this, due to oddities
     * unique to that compiler.
     */
    if (issueArgsUsedPragma && (compiler == COM_BORL)) {
	Output("#pragma argsused\n");
	OutputLineNumber(yylineno,curFile->name);
    }

    /*
     * Output start of definition (stuff before parameters) and generate
     * the name of the instance structure (if any)
     */
    Output("%s _pascal %s(", meth->message->data.symMessage.returnType,
	   meth->name);
    if (!(meth->class->flags & SYM_PROCESS_CLASS)) {
	/*
	 * Output parameters based on memory model
	 */
	switch (meth->model) {
	    case MM_FAR:
		Output("%sInstance *pself, ",
		       	    meth->class->data.symClass.root);
		break;
	    case MM_NEAR:
		Output("%sInstance _near *pself, ",
		       	    meth->class->data.symClass.root);
		break;
	    case MM_BASED:
		Output("_segment sself, %sInstance _based(sself) *pself, ",
		       	    meth->class->data.symClass.root);
		break;
	}
    }
    if (meth->message->data.symMessage.class) {
	Output("optr oself, %sMessages message",
	       meth->message->data.symMessage.class->data.symClass.root);
    } else {
	/* relocation method, so message enum unknown */
	Output("optr oself, word message");
    }

    for (pp = meth->message->data.symMessage.firstParam; pp != NullParam;
	    	    	    	    	    	    	pp = pp->next) {
	Output(", %s %s%s", pp->ctype, pp->name,pp->typeSuffix);
    }
    Output(")");
}

/***********************************************************************
 *
 * FUNCTION:	GenerateCurRootDefine
 *
 * DESCRIPTION:	Generate a #define for the current class of the method.
 *
 * CALLED BY:	yyparse
 *
 * PASS:        meth: method do dump out, 
 *
 * RETURN:	none
 *
 * note: this thing will output something like:
 *  #ifdef __CURROOT
 *  #undef __CURROOT
 *  #define __CURROOT foo     (for fooClass)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ron	10/95		Initial Revision
 *
 ***********************************************************************/
void
GenerateCurRootDefine(Method *meth)
{
    /*
     * Undefine the symbol to get rid of warnings.
     * This probably should be moved to the end of the output for this
     * method.
     */
    Output("#ifdef __CURROOT\n#undef __CURROOT\n#endif\n");

    if (!(meth->class->flags & SYM_PROCESS_CLASS)) {
	/*
	 * Output parameters based on memory model
	 */
	Output("#define __CURROOT %s\n",
	       meth->class->data.symClass.root);
    }
    OutputLineNumber(yylineno, curFile->name);
}


/***********************************************************************
 *
 * FUNCTION:	GenerateMPDString
 *
 * DESCRIPTION:	Generate the string for an MPD value
 *
 * PASS:        Symbol 	*message, 
 *              MsgParamPassEnum, telling whether is dispatch/record/default
 *
 * CALLED BY:	msg rules
 *
 * RETURN:	void
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *      josh    9/92            revamp for SDK release
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
char *
GenerateMPDString(Symbol *msg, MsgParamPassEnum paramSpec)
{
    return GenerateComplexMPDString(msg,msg,paramSpec);
}


/***********************************************************************
 *
 * FUNCTION:	GenerateComplexMPDString
 *
 * DESCRIPTION:	Generate the string for an MPD value
 *
 * PASS:        Symbol 	*passMsg,   (how to pass values  )
 *              Symbol 	*retMsg,    (how to return values)
 *              MsgParamPassEnum, telling whether is dispatch/record/default
 *
 * CALLED BY:	msg rules
 *
 * RETURN:	void
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *      josh    9/92            revamp for SDK release
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/

char * GenerateComplexMPDString(Symbol *passMsg,Symbol *retMsg, 
				MsgParamPassEnum paramSpec)
{
    char buf[400];  /* XXX this is just a band-aid and needs to be dynamic */
    char *cp;
    int mpd;

    if(paramSpec != MPD_RETURN_ONLY &&            /* only if not a dispatch */ 
       paramSpec != MPD_PASS_VOID_RETURN_VOID){
    	mpd = passMsg->data.symMessage.mpd & MPD_PASS;
    }else {
	mpd = 0;                           /* the mpd is in the EventHandle */
    }

    switch(paramSpec) {
	/* XXX */
	/* dx:ax is the fastest case, so we make these two return this way */
	/* returning void takes longer than returning dx:ax, so this is    */
	/* the way to do it.                                               */

    case MPD_PASS_ONLY_RETURN_EVENT_HANDLE:              /* @record */
    case MPD_PASS_ONLY_RETURN_VOID:
#if defined OLD_STYLE_DEFAULT_RETURN_TYPE 
    	mpd |= (MRT_BYTE_OR_WORD<<MPD_RETURN_TYPE_OFFSET) |
	    (MRBWT_AX<<MPD_RET_WORD_OFFSET);
#else
	mpd |= ((MRT_DWORD <<  MPD_RETURN_TYPE_OFFSET) 	|     
		(MRDWR_DX << MPD_RET_DWORD_HIGH_OFFSET)	|
		(MRDWR_AX << MPD_RET_DWORD_LOW_OFFSET));
#endif


	break;

    case MPD_PASS_VOID_RETURN_VOID:
	break;
	
    case MPD_PASS_AND_RETURN: case MPD_RETURN_ONLY: 
    	mpd |= retMsg->data.symMessage.mpd & MPD_RETURN;
	break;

      default:
	assert(0);
    }

    sprintf(buf, "0x%x", mpd);
    for (cp = buf; *cp != '\0'; cp++);
    if ((passMsg == NullSymbol) || (mpd & MPD_REGISTER_PARAMS)) {
	/*
	 * If register params (or we don't know the msg, @dispatch perhaps?)
	 * then the number is all of it.
	 */
    } else {
	MessageParam *mp;
	/*
	 * Skip the first parameter if MRT_MULTIPLE
	 */
	mp = passMsg->data.symMessage.firstParam;
	if ((mp != NullParam) && (mpd & MPD_RETURN_TYPE) ==
		      (MRT_MULTIPLE << MPD_RETURN_TYPE_OFFSET)) {
			  mp = mp->next;
	}
	if (mpd & MPD_STRUCT_AT_SS_BP) {
	    char *sp, *xp;
	    char structName[1000];

	    /*
	     * Get the structure name into a local
	     */
	    for (xp = structName, sp = mp->ctype;
		 ((*sp != ' ') && (*sp != '\0'));
		 sp++) {
		     *xp++ = *sp;
	    }
	    *xp = '\0';
	    /*
	     * structure at ss:bp -> the parameter is something like:
	     *	    FooStruct *foo
	     * We need to get:	
	     *	    "+ (sizeof(FooStruct) < 126 ? sizeof(FooStruct) : 126)"
	     */
	    for (; *cp != '\0'; cp++);	    /* Go to the end */
#if 1
	    sprintf(cp, "+(sizeof(%s)<126?sizeof(%s):126)",
		    structName, structName);
#else
	    sprintf(cp, "+(sizeof(%s)&127)", structName);
#endif
	} else {
	    /*
	     * C params -- we must add the size of the parameters to the MPD
	     * definition, and we must round the size of each parameter up
	     * to a word
	     */
	    sprintf(cp, "+((0");
	    for (; *cp != '\0'; cp++);
	    while (mp != NullParam) {
		/* if the param is an array, add in the size of a ptr */
		/* else, the size of the parameter                    */
		if(strchr(mp->typeSuffix,'[')){
		    strcpy(cp, "+sizeof(void *)/2");
		}else{
		    sprintf(cp, "+(sizeof(%s%s)+1)/2", mp->ctype,
			    mp->typeSuffix);
		}
		for (; *cp != '\0'; cp++);
		mp = mp->next;
	    }
	    sprintf(cp, ")*2)");
	    for (; *cp != '\0'; cp++);
	}
    }
    return (String_EnterZT(buf));
}


Symbol *
MakeInstanceVar(int type, char *name, char *ctype)
{
    Symbol *inst;

    inst = Symbol_Enter(name, type, SYM_DEFINED);
    inst->data.symRegInstance.ctype = ctype;
    inst->data.symRegInstance.typeSuffix = String_EnterZT("");
    return(inst);
}

InstanceValue *
MakeInstanceValue(Symbol *object)
{
    InstanceValue *inst;

    inst = (InstanceValue *) zmalloc(sizeof(InstanceValue));
    inst->next = object->data.symObject.firstInstance;
    object->data.symObject.firstInstance = inst;
    return(inst);
}

void
AddReloc(Symbol *tag,	    /* Vardata containing the relocatable data */
	 int type,  	    /* Type of data (RT_?PTR) */
	 char *text,	    /* Name of instance variable/field within vardata
			     * extra data holding relocatable data */
	 int count, 	    /* Number of elements that make up the data */
	 char *structName)  /* Field within instance/vardata holding the
			     * relocatable data */
{
    Reloc *rel;

    if (classBeingParsed == NullSymbol) {
	yyerror("@reloc outside class declaration");
    } else {
	for (rel = classBeingParsed->data.symClass.relocList;
	     rel != NULL;
	     rel = rel->next)
	{
	    if ((rel->tag == tag) && !strcmp(rel->text, text)) {
		yyerror("relocation for %s already entered", text);
		return;
	    }
	}
	rel = (Reloc *) zmalloc(sizeof(Reloc));
	rel->text = text;
	rel->type = type;
	rel->tag = tag;
	rel->count = count;
	rel->structName = structName;
	rel->next = classBeingParsed->data.symClass.relocList;
	classBeingParsed->data.symClass.relocList = rel;
	if (tag != NullSymbol) {
	    classBeingParsed->flags |= SYM_CLASS_HAS_VD_RELOC;
	    tag->flags |= SYM_VARDATA_HAS_RELOC;
	} else {
	    classBeingParsed->flags |= SYM_CLASS_HAS_INST_RELOC;
	}
    }
}

void
NoReloc(Symbol *instance)    /* Name of instance variable/field within vardata
			      * extra data holding relocatable data */
{
    Reloc *rel;
    Reloc *prev;

    if (classBeingParsed == NullSymbol) {
	yyerror("@noreloc outside class declaration");
    } else {
	for (prev = NULL, rel = classBeingParsed->data.symClass.relocList;
	     rel != NULL;
	     rel = rel->next)
	{
	    if (!strcmp(rel->text, instance->name)) {
		/*
		 * We've found the relocation... nuke it.
		 */
		if (prev == NULL) {
		    classBeingParsed->data.symClass.relocList = rel->next;
		} else {
		    prev->next = rel->next;
		}

		/*
		 * Free the relocation
		 */
		free(rel);
	    }
	}
    }
}

/***********************************************************************
 *				AddVarData
 ***********************************************************************
 * SYNOPSIS:	    Add a vardata element to this object.
 *		    Add the element at the END of the list, so that
 *		    the if/else/endif hints can be used.
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	CB	4/22/93   	added header
 *
 ***********************************************************************/
void
AddVarData(Symbol *vdSym, char *value,char *arraySize)
{
    VardataValue *vd, *lastPtr;

    vd = (VardataValue *) zmalloc(sizeof(VardataValue));

    lastPtr = curObject->data.symObject.vardata;
    if (lastPtr == NULL) {
    	curObject->data.symObject.vardata = vd;
    } else {
	while ( lastPtr->next != NULL ) {
	    lastPtr = lastPtr->next;
	}
	lastPtr->next = vd;
    }

    vd->type = vdSym;
    vd->value = value;
    vd->arraySize = arraySize;      /* hack for hints that take arrays */
    if (vdSym->flags & SYM_VARDATA_HAS_RELOC) {
	curObject->flags |= SYM_OBJECT_HAS_VD_RELOC;
    }
}

/***********************************************************************
 *
 * FUNCTION:	OutputInstanceData
 *
 * DESCRIPTION:	Output the instance data for a class
 *
 * CALLED BY:   endcLine
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
OutputInstanceData(Symbol *class)
{
    Symbol *iptr;
    
    char *previousSymbolFileName = NULL; /* set to illegal */
    int previousSymLineNumber = 0;   


    if (!(class->flags & SYM_CLASS_MASTER) &&
	(class->data.symClass.superclass != NullSymbol)) {
	OutputInstanceData(class->data.symClass.superclass);
    }
    for (iptr = class->data.symClass.instanceData;
	 iptr != NullSymbol;
	 iptr = iptr->data.symRegInstance.next) {

	if(previousSymbolFileName == iptr->fileName){
	    OutputLineDirectiveOrNewlinesForFile(iptr->lineNumber - 
						 previousSymLineNumber,
						 iptr->fileName,
						 iptr->lineNumber);
	} else {
	    OutputLineNumberForSym(iptr);
	}
	Output("    %s %s%s;", iptr->data.symRegInstance.ctype,
	       iptr->name,iptr->data.symRegInstance.typeSuffix);

	previousSymLineNumber  = iptr->lineNumber;
	previousSymbolFileName = iptr->fileName;
    }
}





/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  AddStringCharsToCurrentGstringBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:  format a string's contents as chars into the current gstring buffer
           prefacing it with its length.
         e.g.  "\\\"foo" --> '\', '"', 'f', 'o', 'o'

CALLED BY:   rule for parsing gstring body

PASS:		(char *) to formate into buffer

RETURN:		void

DESTROYED:	the buffer might get realloced.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	
   uses global vars to keep track of the size of the buffer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	5/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
static void
AddStringCharsToCurrentGstringBuffer(char *st)
{
    char translationShort[] = ",'X'";   /* short substitution                 */
    char translationLong[] =  ",'\\X'"; /* make enough space for biggest xlat */
    char *translation;
    char lengthBuf[10];
    int length;
    
    /* put out the length first. no trailing comma required as the
     * translation strings (above) lead off with one */
    
    length = strlen(st);
    sprintf(lengthBuf,"%d,%d",length&0xff, (length&0xff00)>>8);
    AddStringToCurrentGstringBuffer(lengthBuf);
    

    /*
     *   all escaped chars go out directly.
     * XXX: DOESN'T DEAL WITH \206
     */
    
    for(;*st;st++){
	int tlen;
	
	switch(*st){
	case '\0':
	    return;
	case '\\':                       /* note:  this handles "\'" properly */
	    st++;
	    /*FALLTHRU*/
	case '\'':                       /* if "'", need to make it '\'' */
	    translation = translationLong;
	    tlen = sizeof(translationLong);
	    break;
	    
	default:
	    translation = translationShort;
	    tlen = sizeof(translationShort);
	    break;
	}
	/* tlen-1 gets to the null byte, -2 skips over the ending single-
	 * quote and points to the X in the translation strings. */
	 
	translation[tlen-1-2] = *st;
	AddStringToCurrentGstringBuffer(translation);
    }
}



/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   AddStringToCurrentGstringBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:  add a string the the current resource's gstring buffer.

CALLED BY:   rule for parsing gstrings	 

PASS:		(char *) to copy to buffer

RETURN:		void

DESTROYED:	the buffer might get realloced.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	5/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


static void AddStringToCurrentGstringBuffer(char *ptr)
{
     ADD_STRING_TO_DYNAMIC_BUFFER(ptr,gstringBuf);
}




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
#if 0
static void
ParseStackOverflow(char		*msg,	    /* Message if we decide not to */
		   short	**state,    /* Current state stack */
		   size_t	stateSize,  /* Current state stack size */
		   void   	**vals,	    /* Current value stack */
		   size_t	valsSize,   /* Current value stack size */
		   int		*maxDepth)  /* Current maximum stack depth of
					     * all stacks */
{
    *maxDepth *= 2;

    if (malloc_size(*state) != NULL) {
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

#endif

/***********************************************************************
 *				ErrCheck
 ***********************************************************************
 * SYNOPSIS:	    Simple routine to help a programmer who forgets a
 *		    semi-colon or close-brace out by detecting if the input
 *		    for something whose structure is unknown to GOC, but
 *		    which is ended by one of the above, extends over an
 *		    unusually large number of lines.
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	10/26/92	Initial Revision
 *
 ***********************************************************************/
int 	parse_TokenStart;  /* the scanner kindly remembers where its 	*/
int 	parse_TokenEnd;    /* LC_STRING_XXX token starts/ends 		*/
static void
ErrCheck (void)
{
    switch(oldContext){
    case LC_STRING_SEMI_COLON:
    case LC_STRING_COMMA:
    case LC_STRING_RIGHT_PAREN:
    case LC_STRING_COLON:
    case LC_STRING_CLOSE_BRACE:
	yywarning(": did you really mean to end the expression beginning "
		  "on line %d on line %d?\n", 
		  parse_TokenStart, 
		  parse_TokenEnd);
    default:
	break;
    }
}


/***********************************************************************
 *				LocalizationCheck
 ***********************************************************************
 * SYNOPSIS:	    Determine if current chunk needs localization instruction.
 * CALLED BY:	    
 * RETURN:	    nothing
 * SIDE EFFECTS:    
 *	localizationRequired may be changed.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	clee	1/29/97   	Initial Revision
 *
 ***********************************************************************/
static void
LocalizationCheck (void)
{
    /* Set the flag if this is a localizable chunk. */
    if (localizationWarning &&
	(chunkToLocalize != NULL) &&
	(CHUNK_LOC(chunkToLocalize) != NULL) && 
	(LOC_HINT(CHUNK_LOC(chunkToLocalize)) != CDT_unknown)){
	localizationRequired = TRUE;
    }
}	/* End of LocalizationCheck.	*/


/***********************************************************************
 *				Parse_LocalizationWarning
 ***********************************************************************
 * SYNOPSIS:	    Issue the localization warning.
 * CALLED BY:	    
 * RETURN:	    nothing
 * SIDE EFFECTS:    nothing
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	clee	1/30/97   	Initial Revision
 *
 ***********************************************************************/
void
Parse_LocalizationWarning (char *fmt, ...)
{
    va_list	args;

    va_start(args, fmt);

#if defined(unix)
    fprintf(stderr, "file %s, line %d: Warning: ", 
	    chunkToLocalize->fileName, chunkToLocalize->lineNumber);
#else
    fprintf(stderr, "Warning %s %d: ",
	    chunkToLocalize->fileName, chunkToLocalize->lineNumber);
#endif
    vfprintf(stderr,fmt,args);
    putc('\n', stderr);
    va_end(args);
}	/* End of LocalizationWarning.	*/

/*
 * Local Variables:
 * yacc-action-column: 8
 * yacc-rule-column: 8
 * end:
 */
