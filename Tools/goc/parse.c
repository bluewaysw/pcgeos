/* A Bison parser, made by GNU Bison 1.875.  */

/* Skeleton parser for Yacc-like parsing with Bison,
   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002 Free Software Foundation, Inc.

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

/* Written by Richard Stallman by simplifying the original so called
   ``semantic'' parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Using locations.  */
#define YYLSP_NEEDED 0



/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     CLASS = 258,
     META = 259,
     MASTER = 260,
     VARIANT = 261,
     ENDC = 262,
     CLASSDECL = 263,
     NEVER_SAVED = 264,
     MESSAGE = 265,
     STACK = 266,
     CARRY = 267,
     AX = 268,
     CX = 269,
     DX = 270,
     BP = 271,
     AL = 272,
     AH = 273,
     CL = 274,
     CH = 275,
     DL = 276,
     DH = 277,
     BPL = 278,
     BPH = 279,
     SS = 280,
     AXBPCXDX = 281,
     AXCXDXBP = 282,
     CXDXBPAX = 283,
     DXCX = 284,
     BPAXDXCX = 285,
     MULTIPLEAX = 286,
     ALIAS = 287,
     PROTOTYPE = 288,
     RESERVE_MESSAGES = 289,
     EXPORT_MESSAGES = 290,
     IMPORT_MESSAGE = 291,
     SET_MESSAGE_NUM = 292,
     INSTANCE = 293,
     COMPOSITE = 294,
     LINK = 295,
     VIS_MONIKER = 296,
     KBD_ACCELERATOR = 297,
     DEFAULT = 298,
     RELOC = 299,
     FPTR = 300,
     HPTR = 301,
     OPTR = 302,
     DEFAULT_MODEL = 303,
     METHOD = 304,
     FAR = 305,
     NEAR = 306,
     BASED = 307,
     CALL = 308,
     CALL_SUPER = 309,
     SEND = 310,
     RECORD = 311,
     DISPATCH = 312,
     DISPATCHCALL = 313,
     FORCE_QUEUE = 314,
     RETURN_ERROR = 315,
     CHECK_DUPLICATE = 316,
     NO_FREE = 317,
     CHECK_LAST_ONLY = 318,
     REPLACE = 319,
     INSERT_AT_FRONT = 320,
     CAN_DISCARD_IF_DESPARATE = 321,
     NULL_TOKEN = 322,
     PARENT = 323,
     CHILDREN = 324,
     LOCALIZE = 325,
     COMPILER = 326,
     HIGHC = 327,
     MSC = 328,
     START = 329,
     DATA = 330,
     NOT_LMEM = 331,
     NOT_DETACHABLE = 332,
     END = 333,
     HEADER = 334,
     CHUNK = 335,
     CHUNK_ARRAY = 336,
     ELEMENT_ARRAY = 337,
     OBJECT = 338,
     SPECIFIC_UI = 339,
     KBD_PATH = 340,
     RESOURCE_OUTPUT = 341,
     VARDATA = 342,
     VARDATA_ALIAS = 343,
     IGNORE_DIRTY = 344,
     DEFLIB = 345,
     ENDLIB = 346,
     EXTERN = 347,
     GCN_LIST = 348,
     PROTOMINOR = 349,
     PROTORESET = 350,
     OPTIMIZE = 351,
     NORELOC = 352,
     USES = 353,
     NOT = 354,
     FIRSTSYM = 355,
     CLASS_SYM = 356,
     OBJECT_SYM = 357,
     MSG_SYM = 358,
     EXPORT_SYM = 359,
     RESOURCE_SYM = 360,
     CHUNK_SYM = 361,
     VIS_MONIKER_CHUNK_SYM = 362,
     VARDATA_SYM = 363,
     PROTOMINOR_SYM = 364,
     REG_INSTANCE_SYM = 365,
     COMPOSITE_SYM = 366,
     LINK_SYM = 367,
     VIS_MONIKER_SYM = 368,
     VARIANT_PTR_SYM = 369,
     KBD_ACCELERATOR_SYM = 370,
     OPTR_SYM = 371,
     CHUNK_INST_SYM = 372,
     LIST_SYM = 373,
     GSTRING_SYM = 374,
     ATTRIBUTES_SYM = 375,
     COLOR_SYM = 376,
     SIZE_SYM = 377,
     ASPECT_RATIO_SYM = 378,
     CACHED_SIZE_SYM = 379,
     SIZE_COMP_SYM = 380,
     COLOR_COMP_SYM = 381,
     ASPECT_RATIO_COMP_SYM = 382,
     STYLE_SYM = 383,
     STYLE_COMP_SYM = 384,
     KBD_SYM = 385,
     KBD_MODIFIER_SYM = 386,
     GCN_LIST_SYM = 387,
     GCN_LIST_OF_LISTS_SYM = 388,
     LASTSYM = 389,
     SPECIAL_DEBUG_TOKEN = 390,
     SPECIAL_UNDEBUG_TOKEN = 391,
     IDENT = 392,
     STRING = 393,
     FAKESTRING = 394,
     ASCIISTRING = 395,
     LSTRING = 396,
     SJISSTRING = 397,
     TSTRING = 398,
     CHAR = 399,
     CONST = 400
   };
#endif
#define CLASS 258
#define META 259
#define MASTER 260
#define VARIANT 261
#define ENDC 262
#define CLASSDECL 263
#define NEVER_SAVED 264
#define MESSAGE 265
#define STACK 266
#define CARRY 267
#define AX 268
#define CX 269
#define DX 270
#define BP 271
#define AL 272
#define AH 273
#define CL 274
#define CH 275
#define DL 276
#define DH 277
#define BPL 278
#define BPH 279
#define SS 280
#define AXBPCXDX 281
#define AXCXDXBP 282
#define CXDXBPAX 283
#define DXCX 284
#define BPAXDXCX 285
#define MULTIPLEAX 286
#define ALIAS 287
#define PROTOTYPE 288
#define RESERVE_MESSAGES 289
#define EXPORT_MESSAGES 290
#define IMPORT_MESSAGE 291
#define SET_MESSAGE_NUM 292
#define INSTANCE 293
#define COMPOSITE 294
#define LINK 295
#define VIS_MONIKER 296
#define KBD_ACCELERATOR 297
#define DEFAULT 298
#define RELOC 299
#define FPTR 300
#define HPTR 301
#define OPTR 302
#define DEFAULT_MODEL 303
#define METHOD 304
#define FAR 305
#define NEAR 306
#define BASED 307
#define CALL 308
#define CALL_SUPER 309
#define SEND 310
#define RECORD 311
#define DISPATCH 312
#define DISPATCHCALL 313
#define FORCE_QUEUE 314
#define RETURN_ERROR 315
#define CHECK_DUPLICATE 316
#define NO_FREE 317
#define CHECK_LAST_ONLY 318
#define REPLACE 319
#define INSERT_AT_FRONT 320
#define CAN_DISCARD_IF_DESPARATE 321
#define NULL_TOKEN 322
#define PARENT 323
#define CHILDREN 324
#define LOCALIZE 325
#define COMPILER 326
#define HIGHC 327
#define MSC 328
#define START 329
#define DATA 330
#define NOT_LMEM 331
#define NOT_DETACHABLE 332
#define END 333
#define HEADER 334
#define CHUNK 335
#define CHUNK_ARRAY 336
#define ELEMENT_ARRAY 337
#define OBJECT 338
#define SPECIFIC_UI 339
#define KBD_PATH 340
#define RESOURCE_OUTPUT 341
#define VARDATA 342
#define VARDATA_ALIAS 343
#define IGNORE_DIRTY 344
#define DEFLIB 345
#define ENDLIB 346
#define EXTERN 347
#define GCN_LIST 348
#define PROTOMINOR 349
#define PROTORESET 350
#define OPTIMIZE 351
#define NORELOC 352
#define USES 353
#define NOT 354
#define FIRSTSYM 355
#define CLASS_SYM 356
#define OBJECT_SYM 357
#define MSG_SYM 358
#define EXPORT_SYM 359
#define RESOURCE_SYM 360
#define CHUNK_SYM 361
#define VIS_MONIKER_CHUNK_SYM 362
#define VARDATA_SYM 363
#define PROTOMINOR_SYM 364
#define REG_INSTANCE_SYM 365
#define COMPOSITE_SYM 366
#define LINK_SYM 367
#define VIS_MONIKER_SYM 368
#define VARIANT_PTR_SYM 369
#define KBD_ACCELERATOR_SYM 370
#define OPTR_SYM 371
#define CHUNK_INST_SYM 372
#define LIST_SYM 373
#define GSTRING_SYM 374
#define ATTRIBUTES_SYM 375
#define COLOR_SYM 376
#define SIZE_SYM 377
#define ASPECT_RATIO_SYM 378
#define CACHED_SIZE_SYM 379
#define SIZE_COMP_SYM 380
#define COLOR_COMP_SYM 381
#define ASPECT_RATIO_COMP_SYM 382
#define STYLE_SYM 383
#define STYLE_COMP_SYM 384
#define KBD_SYM 385
#define KBD_MODIFIER_SYM 386
#define GCN_LIST_SYM 387
#define GCN_LIST_OF_LISTS_SYM 388
#define LASTSYM 389
#define SPECIAL_DEBUG_TOKEN 390
#define SPECIAL_UNDEBUG_TOKEN 391
#define IDENT 392
#define STRING 393
#define FAKESTRING 394
#define ASCIISTRING 395
#define LSTRING 396
#define SJISSTRING 397
#define TSTRING 398
#define CHAR 399
#define CONST 400




/* Copy the first part of user declarations.  */
#line 1 "parse.y"

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

#include <malloc.h>
#include <compat/string.h>

#include <symbol.h>

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
	free((malloc_t)CHUNK_LOC(c));                 \
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



/*
 * Provide our own handler for the parser-stack overflow so the default one
 * that uses "alloca" isn't used, since alloca is forbidden to us owing to
 * the annoying hidden non-support of said function by our dearly beloved
 * HighC from MetaWare, A.M.D.G.
 */
#define yyoverflow(m,s,S,v,V,d) ParseStackOverflow(m,s,S,(void **)v,V,d)
static void ParseStackOverflow(char *,
			       short **, size_t,
			       void **, size_t,
			       int *);

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


/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif

#if ! defined (YYSTYPE) && ! defined (YYSTYPE_IS_DECLARED)
#line 384 "parse.y"
typedef union YYSTYPE {
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
} YYSTYPE;
/* Line 191 of yacc.c.  */
#line 759 "parse.tab.c"
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



/* Copy the second part of user declarations.  */


/* Line 214 of yacc.c.  */
#line 771 "parse.tab.c"

#if ! defined (yyoverflow) || YYERROR_VERBOSE

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# if YYSTACK_USE_ALLOCA
#  define YYSTACK_ALLOC alloca
# else
#  ifndef YYSTACK_USE_ALLOCA
#   if defined (alloca) || defined (_ALLOCA_H)
#    define YYSTACK_ALLOC alloca
#   else
#    ifdef __GNUC__
#     define YYSTACK_ALLOC __builtin_alloca
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's `empty if-body' warning. */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
# else
#  if defined (__STDC__) || defined (__cplusplus)
#if !defined(__WATCOMC__)
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#endif
#   define YYSIZE_T size_t
#  endif
#  define YYSTACK_ALLOC malloc
#  define YYSTACK_FREE free
# endif
#endif /* ! defined (yyoverflow) || YYERROR_VERBOSE */


#if (! defined (yyoverflow) \
     && (! defined (__cplusplus) \
	 || (YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  short yyss;
  YYSTYPE yyvs;
  };

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (short) + sizeof (YYSTYPE))				\
      + YYSTACK_GAP_MAXIMUM)

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if 1 < __GNUC__
#   define YYCOPY(To, From, Count) \
      __builtin_memcpy (To, From, (Count) * sizeof (*(From)))
#  else
#   define YYCOPY(To, From, Count)		\
      do					\
	{					\
	  register YYSIZE_T yyi;		\
	  for (yyi = 0; yyi < (Count); yyi++)	\
	    (To)[yyi] = (From)[yyi];		\
	}					\
      while (0)
#  endif
# endif

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack)					\
    do									\
      {									\
	YYSIZE_T yynewbytes;						\
	YYCOPY (&yyptr->Stack, Stack, yysize);				\
	Stack = &yyptr->Stack;						\
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAXIMUM; \
	yyptr += yynewbytes / sizeof (*yyptr);				\
      }									\
    while (0)

#endif

#if defined (__STDC__) || defined (__cplusplus)
   typedef signed char yysigned_char;
#else
   typedef short yysigned_char;
#endif

/* YYFINAL -- State number of the termination state. */
#define YYFINAL  3
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   673

/* YYNTOKENS -- Number of terminals. */
#define YYNTOKENS  159
/* YYNNTS -- Number of nonterminals. */
#define YYNNTS  232
/* YYNRULES -- Number of rules. */
#define YYNRULES  472
/* YYNRULES -- Number of states. */
#define YYNSTATES  779

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   400

#define YYTRANSLATE(YYX) 						\
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const unsigned char yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     150,   151,     2,   153,   147,   154,   152,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,   149,   146,
       2,   148,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,   157,     2,   158,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,   155,     2,   156,     2,     2,     2,     2,
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
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,    66,    67,    68,    69,    70,    71,    72,    73,    74,
      75,    76,    77,    78,    79,    80,    81,    82,    83,    84,
      85,    86,    87,    88,    89,    90,    91,    92,    93,    94,
      95,    96,    97,    98,    99,   100,   101,   102,   103,   104,
     105,   106,   107,   108,   109,   110,   111,   112,   113,   114,
     115,   116,   117,   118,   119,   120,   121,   122,   123,   124,
     125,   126,   127,   128,   129,   130,   131,   132,   133,   134,
     135,   136,   137,   138,   139,   140,   141,   142,   143,   144,
     145
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const unsigned short yyprhs[] =
{
       0,     0,     3,     4,     7,    10,    11,    13,    15,    17,
      19,    21,    23,    25,    27,    29,    31,    33,    35,    37,
      39,    41,    43,    45,    47,    49,    51,    53,    55,    57,
      59,    61,    63,    65,    67,    69,    71,    73,    75,    77,
      79,    81,    83,    85,    87,    89,    91,    93,    95,    97,
      99,   103,   107,   111,   113,   117,   120,   122,   124,   126,
     128,   129,   130,   138,   140,   142,   144,   149,   154,   157,
     158,   160,   161,   166,   167,   173,   174,   179,   180,   184,
     185,   189,   190,   194,   196,   197,   198,   202,   203,   204,
     205,   211,   213,   216,   219,   222,   224,   225,   230,   231,
     232,   241,   244,   246,   247,   248,   256,   258,   260,   262,
     264,   265,   266,   273,   276,   277,   283,   284,   285,   293,
     294,   296,   298,   300,   301,   307,   312,   315,   316,   317,
     321,   322,   323,   333,   334,   341,   343,   344,   345,   350,
     352,   354,   355,   356,   360,   363,   364,   366,   368,   370,
     372,   374,   376,   378,   382,   386,   390,   392,   394,   396,
     398,   400,   402,   404,   406,   408,   410,   412,   415,   416,
     418,   420,   422,   424,   426,   428,   430,   432,   434,   436,
     438,   440,   444,   448,   450,   452,   454,   456,   458,   460,
     461,   466,   472,   474,   475,   476,   481,   487,   489,   490,
     494,   498,   500,   504,   507,   509,   511,   512,   518,   521,
     522,   524,   526,   530,   531,   532,   543,   544,   552,   554,
     556,   557,   558,   559,   574,   575,   576,   577,   589,   591,
     594,   597,   598,   600,   602,   604,   606,   607,   616,   620,
     622,   624,   626,   628,   630,   632,   633,   636,   639,   642,
     647,   652,   657,   662,   667,   672,   674,   676,   678,   680,
     682,   684,   685,   686,   687,   688,   703,   705,   706,   710,
     711,   713,   714,   715,   719,   721,   724,   726,   727,   728,
     729,   742,   745,   750,   751,   752,   760,   761,   762,   772,
     774,   775,   776,   782,   784,   787,   788,   790,   792,   794,
     796,   798,   800,   802,   804,   806,   811,   812,   816,   819,
     825,   826,   831,   834,   837,   838,   844,   845,   851,   854,
     857,   860,   861,   865,   868,   869,   870,   878,   879,   880,
     881,   890,   891,   892,   893,   894,   895,   908,   909,   910,
     911,   912,   922,   924,   926,   927,   928,   929,   939,   940,
     941,   951,   953,   954,   957,   958,   962,   966,   968,   969,
     970,   976,   977,   978,   979,   986,   987,   988,   995,  1000,
    1005,  1006,  1007,  1016,  1021,  1026,  1031,  1036,  1037,  1042,
    1045,  1046,  1047,  1055,  1064,  1065,  1071,  1079,  1084,  1086,
    1088,  1090,  1092,  1094,  1096,  1103,  1112,  1116,  1118,  1124,
    1128,  1129,  1132,  1133,  1137,  1140,  1142,  1146,  1148,  1150,
    1151,  1153,  1155,  1157,  1158,  1161,  1162,  1164,  1165,  1169,
    1171,  1173,  1175,  1176,  1182,  1184,  1185,  1186,  1189,  1191,
    1196,  1198,  1201,  1207,  1210,  1216,  1220,  1224,  1228,  1230,
    1233,  1234,  1235,  1238,  1239,  1240,  1246,  1249,  1250,  1252,
    1254,  1256,  1261,  1266,  1271,  1276,  1283,  1286,  1289,  1293,
    1295,  1297,  1300,  1303,  1305,  1307,  1309,  1311,  1313,  1315,
    1317,  1319,  1321
};

/* YYRHS -- A `-1'-separated list of the rules' RHS. */
static const short yyrhs[] =
{
     160,     0,    -1,    -1,   161,   162,    -1,   162,   163,    -1,
      -1,   172,    -1,   176,    -1,   177,    -1,   165,    -1,   199,
      -1,   203,    -1,   212,    -1,   215,    -1,   252,    -1,   256,
      -1,   234,    -1,   242,    -1,   247,    -1,   237,    -1,   264,
      -1,   269,    -1,   271,    -1,   270,    -1,   273,    -1,   281,
      -1,   299,    -1,   302,    -1,   304,    -1,   305,    -1,   310,
      -1,   311,    -1,   314,    -1,   332,    -1,   366,    -1,   352,
      -1,   188,    -1,   194,    -1,   197,    -1,   198,    -1,   168,
      -1,   169,    -1,   309,    -1,    84,    -1,     1,    -1,   135,
      -1,   136,    -1,   164,    -1,   166,    -1,    96,    -1,    97,
     116,   146,    -1,    98,   167,   146,    -1,    98,     1,   146,
      -1,   101,    -1,   167,   147,   101,    -1,    90,   137,    -1,
      91,    -1,   146,    -1,     1,    -1,   147,    -1,    -1,    -1,
       3,   137,   171,   174,   173,   175,   170,    -1,   101,    -1,
       4,    -1,   137,    -1,   147,     5,   147,     6,    -1,   147,
       6,   147,     5,    -1,   147,     5,    -1,    -1,     7,    -1,
      -1,    38,   178,   179,   146,    -1,    -1,    39,   180,   137,
     148,   112,    -1,    -1,    40,   181,   185,   137,    -1,    -1,
      41,   182,   137,    -1,    -1,    42,   183,   137,    -1,    -1,
     390,   184,   186,    -1,    85,    -1,    -1,    -1,   148,   187,
     139,    -1,    -1,    -1,    -1,    87,   189,   390,   190,   146,
      -1,   108,    -1,   192,   108,    -1,   192,   137,    -1,   192,
       1,    -1,   137,    -1,    -1,   101,   193,   149,   149,    -1,
      -1,    -1,    88,   150,   191,   151,   195,   137,   196,   137,
      -1,    94,   387,    -1,    95,    -1,    -1,    -1,    43,   202,
     148,   200,   139,   201,   146,    -1,   110,    -1,   116,    -1,
     114,    -1,   137,    -1,    -1,    -1,    44,   204,   139,   205,
     147,   206,    -1,   208,   211,    -1,    -1,   139,   207,   147,
     208,   211,    -1,    -1,    -1,   150,   145,   147,   209,   139,
     210,   151,    -1,    -1,    45,    -1,    46,    -1,    47,    -1,
      -1,     8,   101,   213,   214,   170,    -1,     8,   137,   214,
     170,    -1,   147,     9,    -1,    -1,    -1,    10,   216,   217,
      -1,    -1,    -1,   390,   150,   218,   224,   221,   151,   219,
     231,   146,    -1,    -1,   150,   220,   103,   151,   137,   146,
      -1,   222,    -1,    -1,    -1,   222,   147,   223,   225,    -1,
     225,    -1,    11,    -1,    -1,    -1,   390,   226,   227,    -1,
     148,   228,    -1,    -1,    19,    -1,    20,    -1,    21,    -1,
      22,    -1,    14,    -1,    15,    -1,    16,    -1,   229,   149,
     229,    -1,   229,   152,   229,    -1,    25,   149,    16,    -1,
     230,    -1,   137,    -1,    14,    -1,    15,    -1,    16,    -1,
      26,    -1,    27,    -1,    28,    -1,    29,    -1,    30,    -1,
      31,    -1,   148,   232,    -1,    -1,    13,    -1,    14,    -1,
      15,    -1,    16,    -1,    17,    -1,    18,    -1,    19,    -1,
      20,    -1,    21,    -1,    22,    -1,    23,    -1,    24,    -1,
     233,   149,   233,    -1,   233,   152,   233,    -1,    12,    -1,
     137,    -1,    13,    -1,    14,    -1,    15,    -1,    16,    -1,
      -1,    34,   235,   236,   170,    -1,    34,   245,   147,   236,
     170,    -1,   145,    -1,    -1,    -1,    37,   238,   239,   170,
      -1,    37,   245,   147,   239,   170,    -1,   240,    -1,    -1,
     240,   153,   241,    -1,   240,   154,   241,    -1,   241,    -1,
     150,   240,   151,    -1,   154,   241,    -1,   145,    -1,   103,
      -1,    -1,    35,   137,   243,   244,   170,    -1,   147,   145,
      -1,    -1,   104,    -1,   137,    -1,    36,   245,   147,    -1,
      -1,    -1,   246,   390,   150,   248,   224,   221,   151,   249,
     231,   146,    -1,    -1,   246,   150,   250,   251,   151,   137,
     146,    -1,   103,    -1,   137,    -1,    -1,    -1,    -1,    32,
     150,   251,   151,   253,   390,   150,   254,   224,   221,   151,
     255,   231,   146,    -1,    -1,    -1,    -1,    33,   257,   390,
     150,   258,   224,   221,   151,   259,   231,   146,    -1,    49,
      -1,    92,    49,    -1,   137,   147,    -1,    -1,   155,    -1,
     146,    -1,   101,    -1,     1,    -1,    -1,   260,   268,   261,
     263,   265,   147,   266,   262,    -1,   266,   147,   267,    -1,
     267,    -1,   103,    -1,   137,    -1,    50,    -1,    51,    -1,
      52,    -1,    -1,    48,    50,    -1,    48,    51,    -1,    48,
      52,    -1,    92,    83,   137,   170,    -1,    92,    83,   102,
     170,    -1,    92,    80,   137,   170,    -1,    92,    80,   106,
     170,    -1,    92,    41,   137,   170,    -1,    92,    41,   107,
     170,    -1,   102,    -1,   106,    -1,   107,    -1,    55,    -1,
      53,    -1,    56,    -1,    -1,    -1,    -1,    -1,   272,   274,
     296,   280,   288,   275,   149,   279,   293,   150,   276,   278,
     277,   151,    -1,   139,    -1,    -1,   155,   280,   156,    -1,
      -1,   103,    -1,    -1,    -1,    54,   282,   284,    -1,   146,
      -1,   150,   151,    -1,   283,    -1,    -1,    -1,    -1,   288,
     285,   149,   263,   149,   149,   251,   150,   286,   278,   287,
     151,    -1,   139,   149,    -1,   139,   147,   139,   149,    -1,
      -1,    -1,    68,   289,   139,   147,   290,   139,   149,    -1,
      -1,    -1,    69,   291,   139,   147,   139,   147,   292,   139,
     149,    -1,   103,    -1,    -1,    -1,   150,   294,   139,   295,
     151,    -1,   137,    -1,   296,   297,    -1,    -1,    59,    -1,
      60,    -1,    61,    -1,    63,    -1,    64,    -1,    65,    -1,
      66,    -1,    62,    -1,    57,    -1,    58,   150,   103,   151,
      -1,    -1,   298,   300,   137,    -1,    57,   150,    -1,    58,
     150,   150,   103,   151,    -1,    -1,   301,   139,   303,   151,
      -1,    71,    72,    -1,    71,    73,    -1,    -1,    74,   137,
     306,   308,   170,    -1,    -1,    74,   105,   307,   308,   170,
      -1,   147,    77,    -1,   147,    75,    -1,   147,    76,    -1,
      -1,    86,   148,   386,    -1,    78,   105,    -1,    -1,    -1,
      79,   137,   148,   312,   139,   313,   146,    -1,    -1,    -1,
      -1,    80,   315,   390,   148,   316,   139,   317,   146,    -1,
      -1,    -1,    -1,    -1,    -1,   327,   318,   137,   319,   328,
     137,   320,   148,   321,   139,   322,   146,    -1,    -1,    -1,
      -1,    -1,   119,   323,   137,   324,   148,   325,   377,   326,
     146,    -1,    81,    -1,    82,    -1,    -1,    -1,    -1,   150,
     329,   137,   150,   330,   139,   331,   151,   151,    -1,    -1,
      -1,    83,   263,   386,   148,   334,   155,   333,   335,   156,
      -1,    89,    -1,    -1,   335,   340,    -1,    -1,   335,   336,
     146,    -1,   335,   336,   156,    -1,     1,    -1,    -1,    -1,
     157,   338,   139,   339,   158,    -1,    -1,    -1,    -1,   110,
     148,   341,   139,   342,   146,    -1,    -1,    -1,   114,   148,
     343,   101,   344,   146,    -1,   116,   148,   137,   146,    -1,
     116,   148,   102,   146,    -1,    -1,    -1,   116,   148,   150,
     345,   139,   346,   151,   146,    -1,   117,   148,   137,   146,
      -1,   117,   148,   351,   146,    -1,   117,   148,   106,   146,
      -1,   117,   148,   102,   146,    -1,    -1,   113,   347,   354,
     368,    -1,   108,   146,    -1,    -1,    -1,   108,   337,   148,
     348,   139,   349,   146,    -1,    93,   150,   389,   147,   389,
     151,   148,   356,    -1,    -1,   111,   148,   350,   363,   146,
      -1,   115,   359,   148,   361,   362,   360,   146,    -1,   112,
     148,   386,   146,    -1,   352,    -1,   138,    -1,   140,    -1,
     143,    -1,   141,    -1,   142,    -1,    70,   155,   138,   145,
     156,   146,    -1,    70,   155,   138,   145,   154,   145,   156,
     146,    -1,    70,    99,   146,    -1,   353,    -1,    70,   155,
     138,   156,   146,    -1,    70,   138,   146,    -1,    -1,   148,
     107,    -1,    -1,   148,   355,   369,    -1,   357,   146,    -1,
     146,    -1,   357,   147,   358,    -1,   358,    -1,   386,    -1,
      -1,   144,    -1,   130,    -1,    84,    -1,    -1,   362,   131,
      -1,    -1,   364,    -1,    -1,   364,   147,   365,    -1,   365,
      -1,   386,    -1,     1,    -1,    -1,    41,   388,   148,   367,
     369,    -1,   146,    -1,    -1,    -1,   370,   371,    -1,     1,
      -1,   118,   155,   383,   156,    -1,   372,    -1,   373,   146,
      -1,   155,   374,   373,   146,   156,    -1,   119,   375,    -1,
     155,   374,   119,   375,   156,    -1,   144,   147,   351,    -1,
     145,   147,   351,    -1,   138,   147,   351,    -1,   351,    -1,
     374,   382,    -1,    -1,    -1,   376,   377,    -1,    -1,    -1,
     155,   378,   380,   379,   156,    -1,   380,   381,    -1,    -1,
     139,    -1,   138,    -1,     1,    -1,   123,   148,   127,   146,
      -1,   128,   148,   129,   146,    -1,   121,   148,   126,   146,
      -1,   122,   148,   125,   146,    -1,   124,   148,   145,   147,
     145,   146,    -1,     1,   146,    -1,     1,   156,    -1,   383,
     147,   384,    -1,   384,    -1,   388,    -1,   385,   147,    -1,
     385,   156,    -1,     1,    -1,   102,    -1,   137,    -1,   109,
      -1,   137,    -1,   107,    -1,   137,    -1,   137,    -1,   145,
      -1,   138,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const unsigned short yyrline[] =
{
       0,   545,   545,   545,   580,   581,   590,   591,   592,   593,
     594,   595,   596,   597,   598,   599,   600,   601,   602,   603,
     604,   605,   606,   607,   608,   609,   610,   611,   612,   613,
     614,   615,   616,   617,   618,   619,   620,   621,   622,   623,
     624,   625,   626,   627,   628,   629,   630,   631,   632,   635,
     646,   655,   659,   674,   682,   697,   715,   731,   731,   739,
     739,   743,   742,   993,   994,   995,  1002,  1006,  1010,  1014,
    1024,  1210,  1209,  1233,  1232,  1242,  1241,  1250,  1249,  1257,
    1256,  1264,  1263,  1288,  1289,  1294,  1293,  1300,  1310,  1314,
    1309,  1344,  1345,  1350,  1356,  1361,  1365,  1364,  1374,  1378,
    1373,  1413,  1425,  1443,  1447,  1442,  1513,  1514,  1515,  1516,
    1530,  1534,  1529,  1544,  1550,  1549,  1562,  1566,  1561,  1575,
    1582,  1583,  1584,  1594,  1593,  1664,  1673,  1677,  1687,  1686,
    1697,  1708,  1696,  1740,  1739,  1781,  1791,  1802,  1801,  1829,
    1838,  1843,  1848,  1847,  1861,  1884,  1897,  1898,  1899,  1900,
    1901,  1902,  1903,  1904,  1909,  1914,  1924,  1930,  1934,  1935,
    1936,  1940,  1941,  1942,  1943,  1944,  1945,  1949,  1957,  1976,
    1977,  1978,  1979,  1980,  1981,  1982,  1983,  1984,  1985,  1986,
    1987,  1988,  1994,  2000,  2004,  2008,  2009,  2010,  2011,  2020,
    2019,  2032,  2043,  2044,  2053,  2052,  2065,  2076,  2077,  2081,
    2082,  2083,  2086,  2087,  2088,  2089,  2098,  2097,  2127,  2128,
    2137,  2138,  2145,  2157,  2162,  2156,  2202,  2201,  2249,  2250,
    2258,  2264,  2269,  2257,  2321,  2327,  2332,  2320,  2359,  2364,
    2371,  2372,  2376,  2377,  2390,  2391,  2408,  2405,  2458,  2459,
    2463,  2564,  2572,  2573,  2574,  2575,  2583,  2584,  2585,  2593,
    2604,  2610,  2621,  2627,  2638,  2653,  2658,  2663,  2680,  2681,
    2682,  2687,  2709,  2713,  2717,  2686,  2751,  2752,  2756,  2757,
    2767,  2768,  2781,  2780,  2792,  2794,  2798,  2852,  2860,  2864,
    2851,  2886,  2929,  2943,  2944,  2943,  2958,  2960,  2958,  2979,
    2987,  2991,  2986,  3001,  3022,  3023,  3028,  3029,  3030,  3031,
    3032,  3033,  3034,  3035,  3043,  3047,  3055,  3054,  3084,  3089,
    3098,  3096,  3129,  3130,  3139,  3138,  3172,  3171,  3193,  3197,
    3201,  3205,  3213,  3231,  3249,  3253,  3248,  3273,  3278,  3284,
    3272,  3320,  3324,  3328,  3332,  3335,  3319,  3359,  3361,  3368,
    3375,  3358,  3399,  3400,  3405,  3409,  3413,  3404,  3422,  3433,
    3432,  3486,  3487,  3491,  3492,  3493,  3497,  3504,  3515,  3516,
    3515,  3518,  3523,  3527,  3522,  3538,  3542,  3537,  3568,  3577,
    3587,  3591,  3586,  3600,  3608,  3632,  3640,  3649,  3648,  3655,
    3664,  3672,  3663,  3679,  3739,  3738,  3758,  3771,  3782,  3788,
    3789,  3790,  3791,  3792,  3796,  3812,  3833,  3848,  3866,  3867,
    3872,  3873,  3883,  3882,  3903,  3904,  3908,  3921,  3925,  3940,
    3946,  3964,  3970,  3971,  3974,  3978,  3986,  3987,  3990,  3991,
    3995,  4017,  4025,  4024,  4036,  4037,  4045,  4045,  4070,  4077,
    4084,  4090,  4091,  4092,  4099,  4109,  4116,  4123,  4130,  4140,
    4141,  4153,  4153,  4169,  4182,  4168,  4197,  4198,  4202,  4203,
    4204,  4213,  4218,  4224,  4229,  4234,  4239,  4243,  4251,  4264,
    4268,  4274,  4279,  4286,  4297,  4298,  4306,  4310,  4322,  4323,
    4331,  4332,  4341
};
#endif

#if YYDEBUG || YYERROR_VERBOSE
/* YYTNME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals. */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "CLASS", "META", "MASTER", "VARIANT",
  "ENDC", "CLASSDECL", "NEVER_SAVED", "MESSAGE", "STACK", "CARRY", "AX",
  "CX", "DX", "BP", "AL", "AH", "CL", "CH", "DL", "DH", "BPL", "BPH",
  "SS", "AXBPCXDX", "AXCXDXBP", "CXDXBPAX", "DXCX", "BPAXDXCX",
  "MULTIPLEAX", "ALIAS", "PROTOTYPE", "RESERVE_MESSAGES",
  "EXPORT_MESSAGES", "IMPORT_MESSAGE", "SET_MESSAGE_NUM", "INSTANCE",
  "COMPOSITE", "LINK", "VIS_MONIKER", "KBD_ACCELERATOR", "DEFAULT",
  "RELOC", "FPTR", "HPTR", "OPTR", "DEFAULT_MODEL", "METHOD", "FAR",
  "NEAR", "BASED", "CALL", "CALL_SUPER", "SEND", "RECORD", "DISPATCH",
  "DISPATCHCALL", "FORCE_QUEUE", "RETURN_ERROR", "CHECK_DUPLICATE",
  "NO_FREE", "CHECK_LAST_ONLY", "REPLACE", "INSERT_AT_FRONT",
  "CAN_DISCARD_IF_DESPARATE", "NULL_TOKEN", "PARENT", "CHILDREN",
  "LOCALIZE", "COMPILER", "HIGHC", "MSC", "START", "DATA", "NOT_LMEM",
  "NOT_DETACHABLE", "END", "HEADER", "CHUNK", "CHUNK_ARRAY",
  "ELEMENT_ARRAY", "OBJECT", "SPECIFIC_UI", "KBD_PATH", "RESOURCE_OUTPUT",
  "VARDATA", "VARDATA_ALIAS", "IGNORE_DIRTY", "DEFLIB", "ENDLIB",
  "EXTERN", "GCN_LIST", "PROTOMINOR", "PROTORESET", "OPTIMIZE", "NORELOC",
  "USES", "NOT", "FIRSTSYM", "CLASS_SYM", "OBJECT_SYM", "MSG_SYM",
  "EXPORT_SYM", "RESOURCE_SYM", "CHUNK_SYM", "VIS_MONIKER_CHUNK_SYM",
  "VARDATA_SYM", "PROTOMINOR_SYM", "REG_INSTANCE_SYM", "COMPOSITE_SYM",
  "LINK_SYM", "VIS_MONIKER_SYM", "VARIANT_PTR_SYM", "KBD_ACCELERATOR_SYM",
  "OPTR_SYM", "CHUNK_INST_SYM", "LIST_SYM", "GSTRING_SYM",
  "ATTRIBUTES_SYM", "COLOR_SYM", "SIZE_SYM", "ASPECT_RATIO_SYM",
  "CACHED_SIZE_SYM", "SIZE_COMP_SYM", "COLOR_COMP_SYM",
  "ASPECT_RATIO_COMP_SYM", "STYLE_SYM", "STYLE_COMP_SYM", "KBD_SYM",
  "KBD_MODIFIER_SYM", "GCN_LIST_SYM", "GCN_LIST_OF_LISTS_SYM", "LASTSYM",
  "SPECIAL_DEBUG_TOKEN", "SPECIAL_UNDEBUG_TOKEN", "IDENT", "STRING",
  "FAKESTRING", "ASCIISTRING", "LSTRING", "SJISSTRING", "TSTRING", "CHAR",
  "CONST", "';'", "','", "'='", "':'", "'('", "')'", "'.'", "'+'", "'-'",
  "'{'", "'}'", "'['", "']'", "$accept", "file", "@1", "lines", "line",
  "optimizeline", "norelocLine", "usesLine", "usesClassList",
  "deflibLine", "endlibLine", "semiColonOrError", "commaOrNothing",
  "classLine", "@2", "superClass", "classFlags", "endcLine",
  "instanceLine", "@3", "instanceLineType", "@4", "@5", "@6", "@7", "@8",
  "kbdPathOrNull", "instanceDefault", "@9", "vardataLine", "@10", "@11",
  "vardataSymOrError", "vardataClass", "@12", "vardataAliasLine", "@13",
  "@14", "protoMinorLine", "protoResetLine", "defaultLine", "@15", "@16",
  "defaultableSym", "relocLine", "@17", "@18", "relocTail", "@19",
  "relocCount", "@20", "@21", "relocType", "classdeclLine", "@22",
  "classDeclFlags", "messageLine", "@23", "messageFinish", "@24", "@25",
  "@26", "messageParamListOrNull", "messageParamList", "@27", "stackFlag",
  "messageParam", "@28", "eqParamRegs", "paramRegs", "wordParamReg",
  "multipleParamReg", "messageReturn", "returnReg", "wordReturnReg",
  "reserveMessagesLine", "@29", "reserveNum", "setMessageLine", "@30",
  "setMessageNum", "numExpr", "primary", "exportMessagesLine", "@31",
  "exportNum", "exportSymOrError", "importMessagePrefix",
  "importMessageLine", "@32", "@33", "@34", "messageSymOrIdentErr",
  "aliasLine", "@35", "@36", "@37", "prototypeLine", "@38", "@39", "@40",
  "externMethodOrMethod", "identCommaOrNothing", "openCurlyOrSemiColon",
  "classOrError", "methodLine", "@41", "methodMessageList",
  "methodMessage", "methodModel", "defaultModelLine", "externLine",
  "objectDerefLine", "sendOrCallOrRecord", "sendOrCallOrRecordLine",
  "@42", "@43", "@44", "@45", "FakeStringOrNothing", "optCastMessage",
  "optCastWithNoBraces", "callsuperLine", "@46", "semiOrParens",
  "callsuperStuff", "@47", "@48", "@49", "objDest", "@50", "@51", "@52",
  "@53", "objMessage", "@54", "@55", "ObjFlagListOrNull", "objFlag",
  "dispatchOrDispatchCall", "dispatchOrDispatchCallLine", "@56",
  "newDispatchOrDispatchCall", "newDispatchOrDispatchCallLine", "@57",
  "compilerLine", "startLine", "@58", "@59", "startFlags",
  "resourceOutputLine", "endLine", "headerLine", "@60", "@61",
  "chunkLine", "@62", "@63", "@64", "@65", "@66", "@67", "@68", "@69",
  "@70", "@71", "@72", "@73", "cArrayType", "caHeader", "@74", "@75",
  "@76", "objectLine", "@77", "ignoreDirtyFlag", "objectFieldList",
  "fieldError", "optionalArraySize", "@78", "@79", "objectField", "@80",
  "@81", "@82", "@83", "@84", "@85", "@86", "@87", "@88", "@89",
  "someString", "LocalizationLine", "simpleLocalization",
  "visMonikerFieldFinish", "@90", "aleArrayN", "aleArray",
  "aleArrayElement", "kbdAcceleratorStart", "kbdAccelChar",
  "specificUIOrNothing", "kbdAccelModList", "childList", "childListNN",
  "childNN", "visMonikerLine", "@91", "optSemiColon", "visMonikerDef",
  "@92", "vmMiddle", "vmMiddleNonList", "vmNavChar", "vmList",
  "vmGStrings", "@93", "GStrings", "@94", "@95", "gstringBodyElementList",
  "gstringBodyElement", "vmElement", "vmArray", "vmArrayElement",
  "vmArrayError", "objectOrIdent", "protoMinorSym", "visMonikerOrIdent",
  "identOrConst", "typeDeclString", 0
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[YYLEX-NUM] -- Internal token number corresponding to
   token YYLEX-NUM.  */
static const unsigned short yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
     275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   287,   288,   289,   290,   291,   292,   293,   294,
     295,   296,   297,   298,   299,   300,   301,   302,   303,   304,
     305,   306,   307,   308,   309,   310,   311,   312,   313,   314,
     315,   316,   317,   318,   319,   320,   321,   322,   323,   324,
     325,   326,   327,   328,   329,   330,   331,   332,   333,   334,
     335,   336,   337,   338,   339,   340,   341,   342,   343,   344,
     345,   346,   347,   348,   349,   350,   351,   352,   353,   354,
     355,   356,   357,   358,   359,   360,   361,   362,   363,   364,
     365,   366,   367,   368,   369,   370,   371,   372,   373,   374,
     375,   376,   377,   378,   379,   380,   381,   382,   383,   384,
     385,   386,   387,   388,   389,   390,   391,   392,   393,   394,
     395,   396,   397,   398,   399,   400,    59,    44,    61,    58,
      40,    41,    46,    43,    45,   123,   125,    91,    93
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const unsigned short yyr1[] =
{
       0,   159,   161,   160,   162,   162,   163,   163,   163,   163,
     163,   163,   163,   163,   163,   163,   163,   163,   163,   163,
     163,   163,   163,   163,   163,   163,   163,   163,   163,   163,
     163,   163,   163,   163,   163,   163,   163,   163,   163,   163,
     163,   163,   163,   163,   163,   163,   163,   163,   163,   164,
     165,   166,   166,   167,   167,   168,   169,   170,   170,   171,
     171,   173,   172,   174,   174,   174,   175,   175,   175,   175,
     176,   178,   177,   180,   179,   181,   179,   182,   179,   183,
     179,   184,   179,   185,   185,   187,   186,   186,   189,   190,
     188,   191,   191,   191,   191,   191,   193,   192,   195,   196,
     194,   197,   198,   200,   201,   199,   202,   202,   202,   202,
     204,   205,   203,   206,   207,   206,   209,   210,   208,   208,
     211,   211,   211,   213,   212,   212,   214,   214,   216,   215,
     218,   219,   217,   220,   217,   221,   221,   223,   222,   222,
     224,   224,   226,   225,   227,   227,   228,   228,   228,   228,
     228,   228,   228,   228,   228,   228,   228,   228,   229,   229,
     229,   230,   230,   230,   230,   230,   230,   231,   231,   232,
     232,   232,   232,   232,   232,   232,   232,   232,   232,   232,
     232,   232,   232,   232,   232,   233,   233,   233,   233,   235,
     234,   234,   236,   236,   238,   237,   237,   239,   239,   240,
     240,   240,   241,   241,   241,   241,   243,   242,   244,   244,
     245,   245,   246,   248,   249,   247,   250,   247,   251,   251,
     253,   254,   255,   252,   257,   258,   259,   256,   260,   260,
     261,   261,   262,   262,   263,   263,   265,   264,   266,   266,
     267,   267,   268,   268,   268,   268,   269,   269,   269,   270,
     270,   270,   270,   270,   270,   271,   271,   271,   272,   272,
     272,   274,   275,   276,   277,   273,   278,   278,   279,   279,
     280,   280,   282,   281,   283,   283,   284,   285,   286,   287,
     284,   288,   288,   289,   290,   288,   291,   292,   288,   293,
     294,   295,   293,   293,   296,   296,   297,   297,   297,   297,
     297,   297,   297,   297,   298,   298,   300,   299,   301,   301,
     303,   302,   304,   304,   306,   305,   307,   305,   308,   308,
     308,   308,   309,   310,   312,   313,   311,   315,   316,   317,
     314,   318,   319,   320,   321,   322,   314,   323,   324,   325,
     326,   314,   327,   327,   329,   330,   331,   328,   328,   333,
     332,   334,   334,   335,   335,   335,   335,   336,   338,   339,
     337,   337,   341,   342,   340,   343,   344,   340,   340,   340,
     345,   346,   340,   340,   340,   340,   340,   347,   340,   340,
     348,   349,   340,   340,   350,   340,   340,   340,   340,   351,
     351,   351,   351,   351,   352,   352,   352,   352,   353,   353,
     354,   354,   355,   354,   356,   356,   357,   357,   358,   359,
     360,   360,   361,   361,   362,   362,   363,   363,   364,   364,
     365,   365,   367,   366,   368,   368,   370,   369,   369,   371,
     371,   372,   372,   372,   372,   373,   373,   373,   373,   374,
     374,   376,   375,   378,   379,   377,   380,   380,   381,   381,
     381,   382,   382,   382,   382,   382,   382,   382,   383,   383,
     384,   384,   384,   385,   386,   386,   387,   387,   388,   388,
     389,   389,   390
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const unsigned char yyr2[] =
{
       0,     2,     0,     2,     2,     0,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       3,     3,     3,     1,     3,     2,     1,     1,     1,     1,
       0,     0,     7,     1,     1,     1,     4,     4,     2,     0,
       1,     0,     4,     0,     5,     0,     4,     0,     3,     0,
       3,     0,     3,     1,     0,     0,     3,     0,     0,     0,
       5,     1,     2,     2,     2,     1,     0,     4,     0,     0,
       8,     2,     1,     0,     0,     7,     1,     1,     1,     1,
       0,     0,     6,     2,     0,     5,     0,     0,     7,     0,
       1,     1,     1,     0,     5,     4,     2,     0,     0,     3,
       0,     0,     9,     0,     6,     1,     0,     0,     4,     1,
       1,     0,     0,     3,     2,     0,     1,     1,     1,     1,
       1,     1,     1,     3,     3,     3,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     2,     0,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     3,     3,     1,     1,     1,     1,     1,     1,     0,
       4,     5,     1,     0,     0,     4,     5,     1,     0,     3,
       3,     1,     3,     2,     1,     1,     0,     5,     2,     0,
       1,     1,     3,     0,     0,    10,     0,     7,     1,     1,
       0,     0,     0,    14,     0,     0,     0,    11,     1,     2,
       2,     0,     1,     1,     1,     1,     0,     8,     3,     1,
       1,     1,     1,     1,     1,     0,     2,     2,     2,     4,
       4,     4,     4,     4,     4,     1,     1,     1,     1,     1,
       1,     0,     0,     0,     0,    14,     1,     0,     3,     0,
       1,     0,     0,     3,     1,     2,     1,     0,     0,     0,
      12,     2,     4,     0,     0,     7,     0,     0,     9,     1,
       0,     0,     5,     1,     2,     0,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     4,     0,     3,     2,     5,
       0,     4,     2,     2,     0,     5,     0,     5,     2,     2,
       2,     0,     3,     2,     0,     0,     7,     0,     0,     0,
       8,     0,     0,     0,     0,     0,    12,     0,     0,     0,
       0,     9,     1,     1,     0,     0,     0,     9,     0,     0,
       9,     1,     0,     2,     0,     3,     3,     1,     0,     0,
       5,     0,     0,     0,     6,     0,     0,     6,     4,     4,
       0,     0,     8,     4,     4,     4,     4,     0,     4,     2,
       0,     0,     7,     8,     0,     5,     7,     4,     1,     1,
       1,     1,     1,     1,     6,     8,     3,     1,     5,     3,
       0,     2,     0,     3,     2,     1,     3,     1,     1,     0,
       1,     1,     1,     0,     2,     0,     1,     0,     3,     1,
       1,     1,     0,     5,     1,     0,     0,     2,     1,     4,
       1,     2,     5,     2,     5,     3,     3,     3,     1,     2,
       0,     0,     2,     0,     0,     5,     2,     0,     1,     1,
       1,     4,     4,     4,     4,     6,     2,     2,     3,     1,
       1,     2,     2,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const unsigned short yydefact[] =
{
       2,     0,     5,     1,     0,    44,     0,    70,     0,   128,
       0,   224,   189,     0,     0,   194,    71,     0,     0,   110,
       0,   228,   259,   272,   258,   260,   304,     0,     0,     0,
       0,     0,     0,   327,   342,   343,     0,    43,     0,    88,
       0,     0,    56,     0,     0,   102,    49,     0,     0,   255,
     256,   257,   337,    45,    46,     4,    47,     9,    48,    40,
      41,     6,     7,     8,    36,    37,    38,    39,    10,    11,
      12,    13,    16,    19,    17,     0,    18,    14,    15,   245,
      20,    21,    23,    22,   261,    24,    25,   306,    26,     0,
      27,    28,    29,    42,    30,    31,    32,   331,    33,    35,
     397,    34,    60,   123,   127,     0,     0,     0,   210,   211,
     193,     0,   206,     0,   198,     0,     0,   468,   469,     0,
     106,   108,   107,   109,     0,     0,   246,   247,   248,     0,
     308,     0,     0,     0,     0,   312,   313,   316,   314,   323,
       0,     0,   235,   234,     0,     0,     0,     0,    55,     0,
     229,     0,     0,   466,   467,   101,     0,     0,    53,     0,
       0,   472,   216,     0,   242,   243,   244,   231,   295,     0,
     310,     0,    59,     0,   127,     0,     0,   133,   129,     0,
     218,   219,     0,     0,   192,     0,   193,   209,   212,   205,
     204,     0,     0,     0,   197,   201,   198,    73,    75,    77,
      79,     0,    81,   422,   103,   111,   283,   286,     0,   274,
       0,   276,   273,   277,     0,     0,   396,   399,     0,   321,
     321,   324,     0,   464,   465,     0,   322,    89,    96,    91,
      95,     0,     0,     0,     0,     0,     0,     0,     0,    50,
      52,    51,     0,   338,     0,   213,     0,     0,   271,   307,
       0,   332,    64,    63,    65,    61,     0,   126,    58,    57,
     125,     0,   130,   220,   225,   190,     0,     0,     0,     0,
     203,   195,     0,     0,     0,     0,    84,     0,     0,    72,
      87,     0,     0,     0,     0,     0,     0,   281,   275,     0,
     305,     0,     0,     0,     0,     0,     0,     0,   328,   352,
       0,     0,    98,    94,    92,    93,   254,   253,   252,   251,
     250,   249,    54,     0,     0,   141,   230,   236,   296,   297,
     298,   303,   299,   300,   301,   302,   270,     0,   294,   311,
     348,    69,   124,     0,   141,     0,   141,   191,   208,   207,
     202,   199,   200,   196,     0,    83,     0,    78,    80,    85,
      82,   428,   423,     0,   104,   119,     0,     0,     0,     0,
     309,     0,     0,   398,   319,   320,   318,   317,   315,   325,
       0,   351,     0,    90,     0,     0,   339,     0,   140,   136,
       0,   262,   344,     0,     0,     0,     0,   136,     0,   136,
       0,    76,     0,     0,   441,   389,   390,   392,   393,   391,
       0,     0,   440,   438,   427,   430,     0,     0,   114,     0,
     112,     0,   284,     0,   282,     0,     0,   394,     0,   329,
     349,    97,    99,     0,     0,     0,   135,   139,   142,     0,
       0,     0,   333,    68,     0,    62,     0,     0,   221,     0,
      74,    86,     0,   433,     0,     0,     0,     0,     0,   431,
     105,     0,     0,   120,   121,   122,   113,     0,     0,     0,
       0,   326,     0,   354,     0,   443,   340,   217,   214,   137,
     145,   240,   241,     0,   239,   269,     0,     0,     0,     0,
     134,   131,   141,   226,   463,     0,   459,     0,   460,   442,
     389,   437,   435,   436,     0,   441,     0,     0,     0,     0,
       0,     0,   439,   119,   116,     0,   287,     0,   395,   330,
       0,   100,   447,     0,   168,     0,     0,   143,   233,     0,
     232,   237,   271,     0,   345,   334,    66,    67,   168,   136,
     168,     0,   429,   461,   462,   456,   457,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   285,     0,     0,   357,
       0,   361,     0,     0,     0,   377,     0,   409,     0,     0,
     350,     0,   353,   388,     0,   341,     0,     0,   138,   150,
     151,   152,   146,   147,   148,   149,     0,   161,   162,   163,
     164,   165,   166,   157,   144,     0,   156,   238,     0,   289,
     293,   290,     0,     0,     0,     0,     0,     0,   458,   434,
       0,     0,     0,     0,     0,   432,   115,   117,     0,   278,
       0,   379,   358,     0,   362,   384,     0,   400,   365,     0,
       0,     0,   355,   356,   450,   449,   448,     0,   446,   183,
     185,   186,   187,   188,   173,   174,   175,   176,   177,   178,
     179,   180,   184,   167,     0,   215,     0,     0,     0,   268,
       0,   263,   346,   335,   132,   222,   227,   453,   454,   451,
       0,   452,     0,   288,   267,   470,   471,     0,     0,   380,
       0,     0,     0,   402,   425,     0,   413,     0,     0,   370,
       0,     0,     0,     0,   445,     0,     0,   155,   158,   159,
     160,   153,   154,   291,   267,     0,     0,   168,     0,   118,
     266,   279,     0,   359,     0,   363,   421,     0,   416,   419,
     420,   387,   401,     0,   424,   378,   366,   412,   415,   369,
     368,     0,   376,   375,   373,   374,   185,   186,   187,   188,
     181,   182,     0,   264,     0,   336,     0,   455,     0,     0,
       0,   381,     0,   385,     0,   403,     0,     0,   371,   292,
       0,   347,   223,   280,     0,   360,     0,   364,   418,   367,
     411,   414,   410,     0,     0,   265,     0,   382,   386,     0,
     405,   383,     0,   407,   408,   372,   404,     0,   406
};

/* YYDEFGOTO[NTERM-NUM]. */
static const short yydefgoto[] =
{
      -1,     1,     2,     4,    55,    56,    57,    58,   159,    59,
      60,   260,   173,    61,   331,   255,   385,    62,    63,   116,
     201,   275,   276,   277,   278,   280,   346,   350,   392,    64,
     146,   300,   231,   232,   301,    65,   375,   464,    66,    67,
      68,   282,   407,   124,    69,   125,   283,   410,   451,   411,
     545,   662,   456,    70,   174,   176,    71,   105,   178,   334,
     528,   261,   425,   426,   515,   379,   427,   470,   517,   584,
     585,   586,   567,   643,   644,    72,   110,   185,    73,   114,
     193,   194,   195,    74,   187,   268,   111,    75,    76,   315,
     514,   244,   182,    77,   335,   482,   697,    78,   107,   336,
     530,    79,   247,   521,   144,    80,   380,   473,   474,   167,
      81,    82,    83,    84,    85,   168,   430,   694,   750,   701,
     523,   327,    86,   129,   211,   212,   289,   664,   738,   213,
     284,   457,   285,   547,   592,   650,   732,   248,   328,    87,
      88,   169,    89,    90,   250,    91,    92,   220,   219,   295,
      93,    94,    95,   297,   418,    96,   141,   370,   462,   171,
     330,   477,   594,   696,   160,   313,   423,   513,    97,   383,
     431,   593,   695,    98,   463,   372,   510,   561,   613,   668,
     740,   562,   670,   742,   675,   746,   721,   764,   617,   704,
     756,   671,   403,    99,   100,   674,   713,   771,   772,   773,
     619,   763,   718,   747,   707,   708,   709,   101,   281,   715,
     352,   353,   404,   405,   406,   448,   443,   444,   466,   512,
     627,   564,   628,   502,   485,   486,   487,   710,   155,   488,
     667,   428
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -521
static const short yypact[] =
{
    -521,    49,  -521,  -521,   198,  -521,   -47,  -521,   -56,  -521,
     -38,  -521,   -73,    -1,   -73,   -73,  -521,    -2,    66,  -521,
     193,  -521,  -521,  -521,  -521,  -521,    15,    57,   -78,    36,
     -34,    46,    72,  -521,  -521,  -521,    27,  -521,    80,  -521,
      99,   146,  -521,     9,   -61,  -521,  -521,   171,    33,  -521,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,  -521,    87,  -521,  -521,  -521,   299,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,   152,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,   156,  -521,   159,    88,   -65,   178,  -521,  -521,
     190,   211,  -521,   221,   -66,   226,     1,  -521,  -521,   192,
    -521,  -521,  -521,  -521,   235,   158,  -521,  -521,  -521,   -39,
    -521,   -77,   238,   239,   248,  -521,  -521,  -521,  -521,  -521,
     240,   178,  -521,  -521,   -41,   -41,   178,   -42,  -521,    31,
    -521,   -20,   -40,  -521,  -521,  -521,   241,   243,  -521,   164,
     253,  -521,  -521,   242,  -521,  -521,  -521,   254,  -521,   256,
    -521,   257,  -521,    42,   159,   386,    14,  -521,  -521,   246,
    -521,  -521,   247,   249,  -521,    14,   190,   250,  -521,  -521,
    -521,   -66,   -66,    14,   202,  -521,   -66,  -521,  -521,  -521,
    -521,   255,  -521,  -521,  -521,  -521,  -521,  -521,   -84,  -521,
     251,  -521,  -521,  -521,   252,   297,  -521,  -521,    40,   258,
     258,  -521,   259,  -521,  -521,   260,  -521,  -521,  -521,  -521,
    -521,   261,    21,    14,    14,    14,    14,    14,    14,  -521,
    -521,  -521,   303,  -521,   -65,  -521,   262,    27,   266,  -521,
     263,  -521,  -521,  -521,  -521,  -521,    14,  -521,  -521,  -521,
    -521,   307,  -521,  -521,  -521,  -521,    14,   268,    14,   113,
    -521,  -521,   -66,   -66,    14,   269,   326,   278,   279,  -521,
     270,    12,   280,   273,   282,   283,   284,  -521,  -521,   275,
    -521,   274,   119,   271,   277,    14,    14,   287,  -521,   338,
     285,   286,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,   281,   288,   417,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,   -45,  -521,  -521,
     290,   289,  -521,   291,   417,   178,   417,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,   295,  -521,   296,  -521,  -521,  -521,
    -521,  -521,  -521,   219,  -521,    90,   294,   298,   300,    27,
    -521,   292,   301,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
     305,  -521,   302,  -521,   304,   309,  -521,   311,  -521,   178,
     308,  -521,  -521,   313,   181,    14,   314,   178,   306,   178,
     322,  -521,   315,   310,  -521,   312,  -521,  -521,  -521,  -521,
     316,   317,  -521,  -521,  -521,  -521,   321,   323,  -521,   325,
    -521,   320,  -521,   319,  -521,   324,   276,  -521,   328,  -521,
    -521,  -521,  -521,   327,   329,   330,   331,  -521,  -521,   -35,
     334,   339,  -521,   333,   337,  -521,   340,   336,  -521,   341,
    -521,  -521,    26,  -521,   327,   201,   201,   201,    50,  -521,
    -521,   342,   343,  -521,  -521,  -521,  -521,   346,   344,   345,
     347,  -521,   349,  -521,   351,  -521,  -521,  -521,  -521,  -521,
     318,  -521,  -521,   115,  -521,   348,   350,   353,   432,   447,
    -521,  -521,   417,  -521,  -521,   -43,  -521,   103,  -521,  -521,
    -521,  -521,  -521,  -521,   -19,  -521,   354,   357,   358,   359,
     360,   352,  -521,   361,  -521,   355,  -521,   -65,  -521,  -521,
       8,  -521,  -521,   363,   362,   178,   293,  -521,  -521,   -35,
    -521,  -521,   365,   -67,  -521,  -521,  -521,  -521,   362,   178,
     362,    26,  -521,  -521,  -521,  -521,  -521,   364,   335,   371,
     370,   368,   383,   366,   320,   375,  -521,   376,   369,  -521,
     373,    43,   377,   378,   379,  -521,   380,  -521,   381,   382,
    -521,   102,  -521,  -521,    10,  -521,   199,   372,  -521,    75,
     108,   122,  -521,  -521,  -521,  -521,   384,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,  -521,   149,  -521,  -521,   385,  -521,
    -521,  -521,   374,   392,   393,   388,   387,   389,  -521,  -521,
     390,   391,   394,   395,   397,  -521,  -521,  -521,   396,  -521,
      65,  -521,  -521,   398,  -521,  -521,   -41,   399,  -521,   400,
     -70,     4,  -521,  -521,  -521,  -521,  -521,   401,  -521,  -521,
     403,   404,   405,   406,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,   150,  -521,   444,   356,   356,  -521,
     414,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
     409,  -521,   407,  -521,   416,  -521,  -521,   412,   421,  -521,
     422,    24,   410,   437,   418,   415,   433,   419,   420,  -521,
     423,   424,   425,   426,  -521,   332,   332,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,   416,   411,   427,   362,   428,  -521,
    -521,  -521,    65,  -521,   429,  -521,  -521,   430,   431,  -521,
    -521,  -521,  -521,    12,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,   436,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,   434,  -521,   435,  -521,   438,  -521,   439,   440,
     441,  -521,   442,  -521,    38,  -521,   443,    53,  -521,  -521,
     445,  -521,  -521,  -521,   446,  -521,   449,  -521,  -521,  -521,
    -521,  -521,  -521,   451,   450,  -521,   -55,  -521,  -521,   452,
    -521,  -521,   229,  -521,  -521,  -521,  -521,   -41,  -521
};

/* YYPGOTO[NTERM-NUM].  */
static const short yypgoto[] =
{
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -181,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,   -32,
    -521,  -521,   -82,  -521,  -521,   408,  -521,  -521,  -521,  -521,
    -521,  -521,  -370,  -521,  -521,  -320,   -36,  -521,  -521,  -521,
    -270,  -521,  -520,  -521,  -306,  -521,  -521,   448,  -521,  -521,
     413,   402,  -174,  -521,  -521,  -521,   367,  -521,  -521,  -521,
    -521,  -521,  -242,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,  -227,  -521,  -521,  -521,     2,  -521,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -217,
    -521,   -23,  -521,  -521,  -521,  -521,  -521,  -521,  -521,   212,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,   453,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,  -521,
    -521,  -521,  -440,    67,  -521,  -521,  -521,  -521,  -521,  -214,
    -521,  -521,  -521,  -521,  -521,  -521,  -177,  -521,  -521,  -521,
    -134,  -521,  -521,  -521,   132,  -521,    86,  -521,   139,  -521,
    -521,  -521,  -521,  -521,  -521,    56,  -521,  -144,  -521,   575,
    -102,   -72
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -445
static const short yytable[] =
{
     225,   226,   314,   163,   265,   491,   492,   493,   595,   549,
     597,   624,   271,   351,   387,   258,   389,   437,   270,   439,
     317,   132,   303,   206,   207,   706,   214,   484,   142,   206,
     207,   108,   677,   179,   157,   183,   589,   189,   180,   706,
     197,   198,   199,   200,   202,   103,   252,   223,   153,     3,
     149,   494,   306,   307,   308,   309,   310,   311,   150,   228,
     133,   223,   237,   286,   109,   287,   229,   678,   471,   222,
     590,   137,   181,   215,   227,   332,   154,   134,    28,   190,
     679,   104,   224,   591,   191,   337,   235,   339,   192,   151,
     102,   770,   152,   343,   208,   230,   224,   238,   341,   342,
     208,   550,   472,   138,   531,   117,   680,   209,   135,   136,
     681,   210,   106,   532,   367,   368,   551,   236,   552,   553,
     554,   555,   556,   557,   558,   559,   223,   535,   143,   304,
    -426,  -426,   415,   117,   158,   118,   112,   536,   233,   161,
     223,   682,   490,   253,   396,   397,   398,   399,   625,   626,
    -426,   139,  -426,  -426,  -426,  -426,  -426,  -426,   305,   596,
     259,   224,   529,   118,   560,   130,  -444,  -426,   234,   495,
    -417,   496,   497,   498,   499,   224,   120,   736,   500,   254,
     121,   683,   122,   760,   761,   292,   433,   434,   395,   611,
     396,   397,   398,   399,   400,   401,   293,   762,    -3,     5,
     612,     6,   665,   123,   435,     7,     8,   131,     9,   140,
     666,   629,   630,   631,   632,   633,   634,   635,   636,   637,
     638,   639,   640,   641,  -158,   161,   161,  -158,   145,   408,
      10,    11,    12,    13,    14,    15,    16,   162,   177,    17,
     409,    18,    19,   126,   127,   128,    20,    21,   622,   147,
     533,    22,    23,    24,    25,    26,    27,  -159,   623,   534,
    -159,   518,   519,   388,   340,   548,   272,   273,    28,    29,
     520,  -160,    30,   361,  -160,   362,    31,    32,    33,    34,
      35,    36,    37,   148,    38,    39,    40,   156,    41,    42,
      43,   170,    44,    45,    46,    47,    48,   205,   647,   685,
      49,   648,   686,   172,    50,    51,   175,   569,   570,   571,
     241,   242,   572,   573,   574,   575,   161,    52,   576,   577,
     578,   579,   580,   581,   582,   318,   319,   320,   321,   322,
     323,   324,   325,    53,    54,   184,   642,   393,   394,   490,
     203,   396,   397,   398,   399,   726,   727,   728,   729,   164,
     165,   166,   364,   365,   366,   272,   273,   395,   186,   396,
     397,   398,   399,   400,   401,   453,   454,   455,   188,   326,
     688,   689,   690,   196,   402,   776,   777,   691,   692,   730,
     731,   113,   115,   204,   216,   217,   218,   239,   221,   240,
     243,   246,   245,   249,   251,   257,   262,   267,   263,   264,
     291,   279,   288,   290,   312,   294,   344,   298,   299,   316,
     333,   345,   302,   338,   329,   347,   348,   363,   349,   354,
     355,   356,   357,   358,   359,   360,   369,   371,   378,   376,
     583,   373,   460,   391,   440,   374,   384,   416,   526,   377,
     382,   412,   386,   390,   419,   413,   422,   417,   424,   414,
     432,   436,   527,   421,   441,   429,   438,   420,   458,   445,
     687,   600,   606,   446,   447,   442,   516,   449,   326,   450,
     452,   544,   672,   459,   461,   467,   476,   733,   469,   568,
     478,   468,   465,   475,   479,   505,   480,   481,   511,   503,
     504,   506,   483,   508,   507,   509,   601,   602,   543,   588,
     524,   525,   538,   522,   546,   539,   540,   541,   542,   565,
     566,   409,   604,   603,   607,   608,   716,   717,   645,   609,
     599,   587,   605,   610,   651,   614,   615,   616,   618,   620,
     621,   652,   653,   646,   654,   656,   657,   658,   655,   381,
     659,   649,   660,   661,   712,   663,   669,   673,   676,  -169,
    -170,  -171,  -172,   693,   698,   700,   711,   684,   699,   702,
     703,   705,   734,   778,   714,   719,   720,   758,   741,   722,
     723,   724,   725,   735,   737,   748,   743,   563,   744,   745,
     501,   537,   256,   489,   752,   749,   751,   598,   757,   759,
     753,   754,   119,   269,   766,   767,   765,   768,   775,   755,
     739,   769,     0,     0,     0,     0,     0,     0,     0,   274,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,   774,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,   774,   266,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,   296
};

static const short yycheck[] =
{
     144,   145,   244,    75,   185,   445,   446,   447,   528,     1,
     530,     1,   193,     1,   334,     1,   336,   387,   192,   389,
     247,    99,     1,    68,    69,     1,   103,     1,     1,    68,
      69,   104,   102,   105,     1,   107,   103,   103,   103,     1,
      39,    40,    41,    42,   116,   101,     4,   102,   109,     0,
      41,     1,   233,   234,   235,   236,   237,   238,    49,   101,
     138,   102,   102,   147,   137,   149,   108,   137,   103,   141,
     137,   105,   137,   150,   146,   256,   137,   155,    70,   145,
     150,   137,   137,   150,   150,   266,   106,   268,   154,    80,
     137,   146,    83,   274,   139,   137,   137,   137,   272,   273,
     139,    93,   137,   137,   147,   107,   102,   146,    72,    73,
     106,   150,   150,   156,   295,   296,   108,   137,   110,   111,
     112,   113,   114,   115,   116,   117,   102,   146,   101,   108,
     118,   119,   359,   107,   101,   137,   137,   156,   107,   138,
     102,   137,   138,   101,   140,   141,   142,   143,   138,   139,
     138,   105,   140,   141,   142,   143,   144,   145,   137,   529,
     146,   137,   482,   137,   156,   150,   156,   155,   137,   119,
     146,   121,   122,   123,   124,   137,   110,   697,   128,   137,
     114,   621,   116,   130,   131,   145,     5,     6,   138,   146,
     140,   141,   142,   143,   144,   145,   156,   144,     0,     1,
     157,     3,   137,   137,   385,     7,     8,   150,    10,   137,
     145,    12,    13,    14,    15,    16,    17,    18,    19,    20,
      21,    22,    23,    24,   149,   138,   138,   152,   148,   139,
      32,    33,    34,    35,    36,    37,    38,   150,   150,    41,
     150,    43,    44,    50,    51,    52,    48,    49,   146,   150,
     147,    53,    54,    55,    56,    57,    58,   149,   156,   156,
     152,   146,   147,   335,   151,   507,   153,   154,    70,    71,
     155,   149,    74,   154,   152,   156,    78,    79,    80,    81,
      82,    83,    84,   137,    86,    87,    88,   116,    90,    91,
      92,   139,    94,    95,    96,    97,    98,   139,   149,   149,
     102,   152,   152,   147,   106,   107,   147,    14,    15,    16,
     146,   147,    19,    20,    21,    22,   138,   119,    25,    26,
      27,    28,    29,    30,    31,    59,    60,    61,    62,    63,
      64,    65,    66,   135,   136,   145,   137,   118,   119,   138,
     148,   140,   141,   142,   143,    13,    14,    15,    16,    50,
      51,    52,    75,    76,    77,   153,   154,   138,   147,   140,
     141,   142,   143,   144,   145,    45,    46,    47,   147,   103,
      14,    15,    16,   147,   155,   146,   147,   647,   648,   685,
     686,    14,    15,   148,   146,   146,   138,   146,   148,   146,
     137,   137,   150,   137,   137,     9,   150,   147,   151,   150,
     103,   146,   151,   151,   101,   147,   137,   148,   148,   147,
     103,    85,   151,   145,   151,   137,   137,   146,   148,   139,
     147,   139,   139,   139,   149,   151,   139,    89,    11,   148,
     137,   146,   156,   137,   112,   149,   147,   145,     6,   151,
     150,   147,   151,   148,   139,   147,   137,   146,   137,   149,
     137,   137,     5,   149,   139,   147,   150,   155,   139,   147,
      16,   126,   544,   147,   147,   155,   148,   146,   103,   146,
     145,   503,   616,   149,   146,   146,   137,   694,   147,   515,
     147,   151,   155,   149,   147,   139,   146,   151,   137,   147,
     147,   147,   151,   146,   149,   146,   125,   127,   146,   522,
     150,   148,   148,   155,   149,   148,   148,   148,   148,   146,
     148,   150,   129,   145,   139,   139,   101,    84,   146,   150,
     156,   519,   156,   150,   150,   148,   148,   148,   148,   148,
     148,   139,   139,   149,   146,   146,   146,   146,   151,   327,
     146,   156,   147,   146,   107,   149,   148,   148,   148,   146,
     146,   146,   146,   139,   145,   139,   146,   156,   151,   147,
     139,   139,   151,   777,   146,   146,   146,   744,   139,   146,
     146,   146,   146,   146,   146,   139,   146,   510,   147,   713,
     448,   495,   174,   444,   146,   151,   151,   531,   146,   146,
     151,   151,    17,   191,   148,   146,   151,   146,   146,   158,
     702,   151,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   196,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,   766,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   777,   186,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   220
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const unsigned short yystos[] =
{
       0,   160,   161,     0,   162,     1,     3,     7,     8,    10,
      32,    33,    34,    35,    36,    37,    38,    41,    43,    44,
      48,    49,    53,    54,    55,    56,    57,    58,    70,    71,
      74,    78,    79,    80,    81,    82,    83,    84,    86,    87,
      88,    90,    91,    92,    94,    95,    96,    97,    98,   102,
     106,   107,   119,   135,   136,   163,   164,   165,   166,   168,
     169,   172,   176,   177,   188,   194,   197,   198,   199,   203,
     212,   215,   234,   237,   242,   246,   247,   252,   256,   260,
     264,   269,   270,   271,   272,   273,   281,   298,   299,   301,
     302,   304,   305,   309,   310,   311,   314,   327,   332,   352,
     353,   366,   137,   101,   137,   216,   150,   257,   104,   137,
     235,   245,   137,   245,   238,   245,   178,   107,   137,   388,
     110,   114,   116,   137,   202,   204,    50,    51,    52,   282,
     150,   150,    99,   138,   155,    72,    73,   105,   137,   105,
     137,   315,     1,   101,   263,   148,   189,   150,   137,    41,
      49,    80,    83,   109,   137,   387,   116,     1,   101,   167,
     323,   138,   150,   390,    50,    51,    52,   268,   274,   300,
     139,   318,   147,   171,   213,   147,   214,   150,   217,   390,
     103,   137,   251,   390,   145,   236,   147,   243,   147,   103,
     145,   150,   154,   239,   240,   241,   147,    39,    40,    41,
      42,   179,   390,   148,   148,   139,    68,    69,   139,   146,
     150,   283,   284,   288,   103,   150,   146,   146,   138,   307,
     306,   148,   390,   102,   137,   386,   386,   390,   101,   108,
     137,   191,   192,   107,   137,   106,   137,   102,   137,   146,
     146,   146,   147,   137,   250,   150,   137,   261,   296,   137,
     303,   137,     4,   101,   137,   174,   214,     9,     1,   146,
     170,   220,   150,   151,   150,   170,   236,   147,   244,   240,
     241,   170,   153,   154,   239,   180,   181,   182,   183,   146,
     184,   367,   200,   205,   289,   291,   147,   149,   151,   285,
     151,   103,   145,   156,   147,   308,   308,   312,   148,   148,
     190,   193,   151,     1,   108,   137,   170,   170,   170,   170,
     170,   170,   101,   324,   251,   248,   147,   263,    59,    60,
      61,    62,    63,    64,    65,    66,   103,   280,   297,   151,
     319,   173,   170,   103,   218,   253,   258,   170,   145,   170,
     151,   241,   241,   170,   137,    85,   185,   137,   137,   148,
     186,     1,   369,   370,   139,   147,   139,   139,   139,   149,
     151,   154,   156,   146,    75,    76,    77,   170,   170,   139,
     316,    89,   334,   146,   149,   195,   148,   151,    11,   224,
     265,   288,   150,   328,   147,   175,   151,   224,   390,   224,
     148,   137,   187,   118,   119,   138,   140,   141,   142,   143,
     144,   145,   155,   351,   371,   372,   373,   201,   139,   150,
     206,   208,   147,   147,   149,   263,   145,   146,   313,   139,
     155,   149,   137,   325,   137,   221,   222,   225,   390,   147,
     275,   329,   137,     5,     6,   170,   137,   221,   150,   221,
     112,   139,   155,   375,   376,   147,   147,   147,   374,   146,
     146,   207,   145,    45,    46,    47,   211,   290,   139,   149,
     156,   146,   317,   333,   196,   155,   377,   146,   151,   147,
     226,   103,   137,   266,   267,   149,   137,   320,   147,   147,
     146,   151,   254,   151,     1,   383,   384,   385,   388,   377,
     138,   351,   351,   351,     1,   119,   121,   122,   123,   124,
     128,   373,   382,   147,   147,   139,   147,   149,   146,   146,
     335,   137,   378,   326,   249,   223,   148,   227,   146,   147,
     155,   262,   155,   279,   150,   148,     6,     5,   219,   224,
     259,   147,   156,   147,   156,   146,   156,   375,   148,   148,
     148,   148,   148,   146,   208,   209,   149,   292,   251,     1,
      93,   108,   110,   111,   112,   113,   114,   115,   116,   117,
     156,   336,   340,   352,   380,   146,   148,   231,   225,    14,
      15,    16,    19,    20,    21,    22,    25,    26,    27,    28,
      29,    30,    31,   137,   228,   229,   230,   267,   280,   103,
     137,   150,   293,   330,   321,   231,   221,   231,   384,   156,
     126,   125,   127,   145,   129,   156,   211,   139,   139,   150,
     150,   146,   157,   337,   148,   148,   148,   347,   148,   359,
     148,   148,   146,   156,     1,   138,   139,   379,   381,    12,
      13,    14,    15,    16,    17,    18,    19,    20,    21,    22,
      23,    24,   137,   232,   233,   146,   149,   149,   152,   156,
     294,   150,   139,   139,   146,   151,   146,   146,   146,   146,
     147,   146,   210,   149,   286,   137,   145,   389,   338,   148,
     341,   350,   386,   148,   354,   343,   148,   102,   137,   150,
     102,   106,   137,   351,   156,   149,   152,    16,    14,    15,
      16,   229,   229,   139,   276,   331,   322,   255,   145,   151,
     139,   278,   147,   139,   348,   139,     1,   363,   364,   365,
     386,   146,   107,   355,   146,   368,   101,    84,   361,   146,
     146,   345,   146,   146,   146,   146,    13,    14,    15,    16,
     233,   233,   295,   278,   151,   146,   231,   146,   287,   389,
     339,   139,   342,   146,   147,   369,   344,   362,   139,   151,
     277,   151,   146,   151,   151,   158,   349,   146,   365,   146,
     130,   131,   144,   360,   346,   151,   148,   146,   146,   151,
     146,   356,   357,   358,   386,   146,   146,   147,   358
};

#if ! defined (YYSIZE_T) && defined (__SIZE_TYPE__)
# define YYSIZE_T __SIZE_TYPE__
#endif
#if ! defined (YYSIZE_T) && defined (size_t)
# define YYSIZE_T size_t
#endif
#if ! defined (YYSIZE_T)
# if defined (__STDC__) || defined (__cplusplus)
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# endif
#endif
#if ! defined (YYSIZE_T)
# define YYSIZE_T unsigned int
#endif

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		(-2)
#define YYEOF		0

#define YYACCEPT	goto yyacceptlab
#define YYABORT		goto yyabortlab
#define YYERROR		goto yyerrlab1

/* Like YYERROR except do call yyerror.  This remains here temporarily
   to ease the transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */

#define YYFAIL		goto yyerrlab

#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)					\
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    {								\
      yychar = (Token);						\
      yylval = (Value);						\
      yytoken = YYTRANSLATE (yychar);				\
      YYPOPSTACK;						\
      goto yybackup;						\
    }								\
  else								\
    { 								\
      yyerror ("syntax error: cannot back up");\
      YYERROR;							\
    }								\
while (0)

#define YYTERROR	1
#define YYERRCODE	256

/* YYLLOC_DEFAULT -- Compute the default location (before the actions
   are run).  */

#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)         \
  Current.first_line   = Rhs[1].first_line;      \
  Current.first_column = Rhs[1].first_column;    \
  Current.last_line    = Rhs[N].last_line;       \
  Current.last_column  = Rhs[N].last_column;
#endif

/* YYLEX -- calling `yylex' with the right arguments.  */

#ifdef YYLEX_PARAM
# define YYLEX yylex (YYLEX_PARAM)
#else
# define YYLEX yylex ()
#endif

/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)			\
do {						\
  if (yydebug)					\
    YYFPRINTF Args;				\
} while (0)

# define YYDSYMPRINT(Args)			\
do {						\
  if (yydebug)					\
    yysymprint Args;				\
} while (0)

# define YYDSYMPRINTF(Title, Token, Value, Location)		\
do {								\
  if (yydebug)							\
    {								\
      YYFPRINTF (stderr, "%s ", Title);				\
      yysymprint (stderr, 					\
                  Token, Value);	\
      YYFPRINTF (stderr, "\n");					\
    }								\
} while (0)

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (cinluded).                                                   |
`------------------------------------------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yy_stack_print (short *bottom, short *top)
#else
static void
yy_stack_print (bottom, top)
    short *bottom;
    short *top;
#endif
{
  YYFPRINTF (stderr, "Stack now");
  for (/* Nothing. */; bottom <= top; ++bottom)
    YYFPRINTF (stderr, " %d", *bottom);
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)				\
do {								\
  if (yydebug)							\
    yy_stack_print ((Bottom), (Top));				\
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yy_reduce_print (int yyrule)
#else
static void
yy_reduce_print (yyrule)
    int yyrule;
#endif
{
  int yyi;
  unsigned int yylineno = yyrline[yyrule];
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %u), ",
             yyrule - 1, yylineno);
  /* Print the symbols being reduced, and their result.  */
  for (yyi = yyprhs[yyrule]; 0 <= yyrhs[yyi]; yyi++)
    YYFPRINTF (stderr, "%s ", yytname [yyrhs[yyi]]);
  YYFPRINTF (stderr, "-> %s\n", yytname [yyr1[yyrule]]);
}

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug)				\
    yy_reduce_print (Rule);		\
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
# define YYDSYMPRINT(Args)
# define YYDSYMPRINTF(Title, Token, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef	YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   SIZE_MAX < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#if YYMAXDEPTH == 0
# undef YYMAXDEPTH
#endif

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif



#if YYERROR_VERBOSE

# ifndef yystrlen
#  if defined (__GLIBC__) && defined (_STRING_H)
#   define yystrlen strlen
#  else
/* Return the length of YYSTR.  */
static YYSIZE_T
#   if defined (__STDC__) || defined (__cplusplus)
yystrlen (const char *yystr)
#   else
yystrlen (yystr)
     const char *yystr;
#   endif
{
  register const char *yys = yystr;

  while (*yys++ != '\0')
    continue;

  return yys - yystr - 1;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined (__GLIBC__) && defined (_STRING_H) && defined (_GNU_SOURCE)
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
#   if defined (__STDC__) || defined (__cplusplus)
yystpcpy (char *yydest, const char *yysrc)
#   else
yystpcpy (yydest, yysrc)
     char *yydest;
     const char *yysrc;
#   endif
{
  register char *yyd = yydest;
  register const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif

#endif /* !YYERROR_VERBOSE */



#if YYDEBUG
/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yysymprint (FILE *yyoutput, int yytype, YYSTYPE *yyvaluep)
#else
static void
yysymprint (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  /* Pacify ``unused variable'' warnings.  */
  (void) yyvaluep;

  if (yytype < YYNTOKENS)
    {
      YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
# ifdef YYPRINT
      YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# endif
    }
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

  switch (yytype)
    {
      default:
        break;
    }
  YYFPRINTF (yyoutput, ")");
}

#endif /* ! YYDEBUG */
/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yydestruct (int yytype, YYSTYPE *yyvaluep)
#else
static void
yydestruct (yytype, yyvaluep)
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  /* Pacify ``unused variable'' warnings.  */
  (void) yyvaluep;

  switch (yytype)
    {

      default:
        break;
    }
}


/* Prevent warnings from -Wmissing-prototypes.  */

#ifdef YYPARSE_PARAM
# if defined (__STDC__) || defined (__cplusplus)
int yyparse (void *YYPARSE_PARAM);
# else
int yyparse ();
# endif
#else /* ! YYPARSE_PARAM */
#if defined (__STDC__) || defined (__cplusplus)
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */



/* The lookahead symbol.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;

/* Number of syntax errors so far.  */
int yynerrs;



/*----------.
| yyparse.  |
`----------*/

#ifdef YYPARSE_PARAM
# if defined (__STDC__) || defined (__cplusplus)
int yyparse (void *YYPARSE_PARAM)
# else
int yyparse (YYPARSE_PARAM)
  void *YYPARSE_PARAM;
# endif
#else /* ! YYPARSE_PARAM */
#if defined (__STDC__) || defined (__cplusplus)
int
yyparse (void)
#else
int
yyparse ()

#endif
#endif
{

  register int yystate;
  register int yyn;
  int yyresult;
  /* Number of tokens to shift before error messages enabled.  */
  int yyerrstatus;
  /* Lookahead token as an internal (translated) token number.  */
  int yytoken = 0;

  /* Three stacks and their tools:
     `yyss': related to states,
     `yyvs': related to semantic values,
     `yyls': related to locations.

     Refer to the stacks thru separate pointers, to allow yyoverflow
     to reallocate them elsewhere.  */

  /* The state stack.  */
  short	yyssa[YYINITDEPTH];
  short *yyss = yyssa;
  register short *yyssp;

  /* The semantic value stack.  */
  YYSTYPE yyvsa[YYINITDEPTH];
  YYSTYPE *yyvs = yyvsa;
  register YYSTYPE *yyvsp;



#define YYPOPSTACK   (yyvsp--, yyssp--)

  YYSIZE_T yystacksize = YYINITDEPTH;

  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;


  /* When reducing, the number of symbols on the RHS of the reduced
     rule.  */
  int yylen;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY;		/* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */

  yyssp = yyss;
  yyvsp = yyvs;

  goto yysetstate;

/*------------------------------------------------------------.
| yynewstate -- Push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
 yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed. so pushing a state here evens the stacks.
     */
  yyssp++;

 yysetstate:
  *yyssp = yystate;

  if (yyss + yystacksize - 1 <= yyssp)
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
      {
	/* Give user a chance to reallocate the stack. Use copies of
	   these so that the &'s don't force the real ones into
	   memory.  */
	YYSTYPE *yyvs1 = yyvs;
	short *yyss1 = yyss;


	/* Each stack pointer address is followed by the size of the
	   data in use in that stack, in bytes.  This used to be a
	   conditional around just the two extra args, but that might
	   be undefined if yyoverflow is a macro.  */
	yyoverflow ("parser stack overflow",
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),

		    &yystacksize);

	yyss = yyss1;
	yyvs = yyvs1;
      }
#else /* no yyoverflow */
# ifndef YYSTACK_RELOCATE
      goto yyoverflowlab;
# else
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
	goto yyoverflowlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
	yystacksize = YYMAXDEPTH;

      {
	short *yyss1 = yyss;
	union yyalloc *yyptr =
	  (union yyalloc *) YYSTACK_ALLOC (YYSTACK_BYTES (yystacksize));
	if (! yyptr)
	  goto yyoverflowlab;
	YYSTACK_RELOCATE (yyss);
	YYSTACK_RELOCATE (yyvs);

#  undef YYSTACK_RELOCATE
	if (yyss1 != yyssa)
	  YYSTACK_FREE (yyss1);
      }
# endif
#endif /* no yyoverflow */

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;


      YYDPRINTF ((stderr, "Stack size increased to %lu\n",
		  (unsigned long int) yystacksize));

      if (yyss + yystacksize - 1 <= yyssp)
	YYABORT;
    }

  YYDPRINTF ((stderr, "Entering state %d\n", yystate));

  goto yybackup;

/*-----------.
| yybackup.  |
`-----------*/
yybackup:

/* Do appropriate processing given the current state.  */
/* Read a lookahead token if we need one and don't already have one.  */
/* yyresume: */

  /* First try to decide what to do without reference to lookahead token.  */

  yyn = yypact[yystate];
  if (yyn == YYPACT_NINF)
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either YYEMPTY or YYEOF or a valid lookahead symbol.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = YYLEX;
    }

  if (yychar <= YYEOF)
    {
      yychar = yytoken = YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YYDSYMPRINTF ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yyn == 0 || yyn == YYTABLE_NINF)
	goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  /* Shift the lookahead token.  */
  YYDPRINTF ((stderr, "Shifting token %s, ", yytname[yytoken]));

  /* Discard the token being shifted unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  *++yyvsp = yylval;


  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  yystate = yyn;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- Do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     `$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
        case 2:
#line 545 "parse.y"
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
	    case COM_BORL: case COM_MSC:
	      break;
	    }

	    /* output our first line directive */
	    OutputLineNumber(yylineno,curFile->name);
	;}
    break;

  case 3:
#line 564 "parse.y"
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
	;}
    break;

  case 6:
#line 590 "parse.y"
    {;}
    break;

  case 7:
#line 591 "parse.y"
    {;}
    break;

  case 8:
#line 592 "parse.y"
    {;}
    break;

  case 9:
#line 593 "parse.y"
    {;}
    break;

  case 10:
#line 594 "parse.y"
    {;}
    break;

  case 11:
#line 595 "parse.y"
    {;}
    break;

  case 12:
#line 596 "parse.y"
    {;}
    break;

  case 13:
#line 597 "parse.y"
    {;}
    break;

  case 14:
#line 598 "parse.y"
    {;}
    break;

  case 15:
#line 599 "parse.y"
    {;}
    break;

  case 16:
#line 600 "parse.y"
    {;}
    break;

  case 17:
#line 601 "parse.y"
    {;}
    break;

  case 18:
#line 602 "parse.y"
    {;}
    break;

  case 19:
#line 603 "parse.y"
    {;}
    break;

  case 20:
#line 604 "parse.y"
    {;}
    break;

  case 21:
#line 605 "parse.y"
    {;}
    break;

  case 22:
#line 606 "parse.y"
    {;}
    break;

  case 23:
#line 607 "parse.y"
    {;}
    break;

  case 24:
#line 608 "parse.y"
    {;}
    break;

  case 25:
#line 609 "parse.y"
    {;}
    break;

  case 26:
#line 610 "parse.y"
    {;}
    break;

  case 27:
#line 611 "parse.y"
    {;}
    break;

  case 28:
#line 612 "parse.y"
    {;}
    break;

  case 29:
#line 613 "parse.y"
    {;}
    break;

  case 30:
#line 614 "parse.y"
    {;}
    break;

  case 31:
#line 615 "parse.y"
    {;}
    break;

  case 32:
#line 616 "parse.y"
    {;}
    break;

  case 33:
#line 617 "parse.y"
    {;}
    break;

  case 34:
#line 618 "parse.y"
    {;}
    break;

  case 35:
#line 619 "parse.y"
    {;}
    break;

  case 36:
#line 620 "parse.y"
    {;}
    break;

  case 37:
#line 621 "parse.y"
    {;}
    break;

  case 38:
#line 622 "parse.y"
    {;}
    break;

  case 39:
#line 623 "parse.y"
    {;}
    break;

  case 40:
#line 624 "parse.y"
    {;}
    break;

  case 41:
#line 625 "parse.y"
    {;}
    break;

  case 42:
#line 626 "parse.y"
    {;}
    break;

  case 43:
#line 627 "parse.y"
    { specificUI = TRUE; ;}
    break;

  case 44:
#line 628 "parse.y"
    { ErrCheck(); SWITCH_CONTEXT(LC_NONE); ;}
    break;

  case 45:
#line 629 "parse.y"
    { SWITCH_CONTEXT( LC_NONE); ;}
    break;

  case 46:
#line 630 "parse.y"
    { SWITCH_CONTEXT( LC_NONE); ;}
    break;

  case 47:
#line 631 "parse.y"
    {SWITCH_CONTEXT( LC_NONE); ;}
    break;

  case 49:
#line 635 "parse.y"
    {
    if(whichToken == FIRST_OF_FILE){
	Scan_StartOptimize();
    }else{
	yyerror("@optimize must appear at the very start of a file.");
    }
;}
    break;

  case 50:
#line 647 "parse.y"
    {
            NoReloc(yyvsp[-1].sym);
	;}
    break;

  case 51:
#line 656 "parse.y"
    {
	    SWITCH_CONTEXT(LC_NONE);
	;}
    break;

  case 52:
#line 660 "parse.y"
    {
	    if (yychar == IDENT) {
		yyerror("%s is not a defined class.", yyvsp[-2].string);
	    } else if (yychar > FIRSTSYM && yychar < LASTSYM) {
		if (yychar != CLASS_SYM) {
		    yyerror("%s is not a defined class.", yyvsp[-2].sym->name);
		}
	    }
	    Scan_Unput(';');
	    yyerrok;
	    yyclearin;
	;}
    break;

  case 53:
#line 675 "parse.y"
    {
	    if (classBeingParsed != NullSymbol) {
		Symbol_ClassUses(classBeingParsed, yyvsp[0].sym);
	    } else {
		yyerror("@uses is valid only inside a class definition.");
	    }
	;}
    break;

  case 54:
#line 683 "parse.y"
    {
	    if (classBeingParsed != NullSymbol) {
		Symbol_ClassUses(classBeingParsed, yyvsp[0].sym);
	    }
	    /* error case handled by above rule upon receiving first class */
	;}
    break;

  case 55:
#line 698 "parse.y"
    {
	    DeflibNode *node;

	    node = (DeflibNode *) malloc(sizeof(DeflibNode));
	    node->next = deflibPtr;
	    node->name = (char *) malloc(strlen(yyvsp[0].string) + 1);
	    strcpy(node->name, yyvsp[0].string);
	    deflibPtr = node;
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 56:
#line 716 "parse.y"
    {
	    DeflibNode *node;

	    if (deflibPtr == NullDeflibNode) {
		yyerror("mismatched @deflib and @endlib");
	    } else {
	    	node = deflibPtr;
	    	deflibPtr = node->next;
		free(node->name);
		free((malloc_t)node);
	    }
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 58:
#line 731 "parse.y"
    {yyerror("missing semicolon");;}
    break;

  case 61:
#line 743 "parse.y"
    {
	    /*
	     * If a class is already being declared, give an error
	     */
	    if (classBeingParsed != NullSymbol) {
		yyerror("class %s declared before class %s closed",
			yyvsp[-2].string, classBeingParsed->name);
	    }
	    /*
	     * Enter the identifier as a class and create a local symbol
	     * table for it
	     */
	    classBeingParsed = Symbol_Enter(yyvsp[-2].string, CLASS_SYM, SYM_DEFINED);

	    /*
	     * Reset the protoMinor stuff
	     *
	     */

	    curProtoMinor = NullSymbol;

	;}
    break;

  case 62:
#line 766 "parse.y"
    {
    	    char iname[100];
    	    char *cp;
	    Symbol *class, *super, *bottomClass;

	    /*
	     * prepare to insert the messages into the class's list.
	     */

	    INIT_CLASS_MESSAGE_LIST(classBeingParsed);

	    classBeingParsed->data.symClass.superclass = yyvsp[-3].sym;
	    classBeingParsed->flags |= yyvsp[-1].num;
            classBeingParsed->data.symClass.classSeg = curResource;

	    /*
	     * Generate the root name of the class
	     */
	    strcpy(iname, yyvsp[-5].string);
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
	    if (yyvsp[-3].sym == NullSymbol) {
		classBeingParsed->data.symClass.localSymbols =
		    Symbol_NewScope(currentScope, FALSE);
	        classBeingParsed->data.symClass.firstMessage = 0;
		classBeingParsed->data.symClass.masterLevel = 0;
	    } else {
		if (yyvsp[-1].num & SYM_CLASS_VARIANT) {
		    classBeingParsed->data.symClass.localSymbols =
		    	Symbol_NewScope(currentScope, FALSE);
		} else {
		    classBeingParsed->data.symClass.localSymbols =
		    	Symbol_NewScope(yyvsp[-3].sym->data.symClass.localSymbols, FALSE);
		}
		/*
		 * Check for this class being ProcessClass or a subclass
		 * thereof.  This affects the method definitions
		 */
		if (!strcmp(yyvsp[-5].string, "ProcessClass") ||
		    (yyvsp[-3].sym->flags & SYM_PROCESS_CLASS)) {
			classBeingParsed->flags |= SYM_PROCESS_CLASS;
		}
		classBeingParsed->data.symClass.masterLevel =
		    yyvsp[-3].sym->data.symClass.masterLevel;
		/*
		 * Output base structure for this class
		 */
		if ((classBeingParsed->data.symClass.superclass != NullSymbol)
		    	&& !(classBeingParsed->flags & SYM_PROCESS_CLASS))
		{
		    if (yyvsp[-1].num & SYM_CLASS_MASTER) {
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
		if (yyvsp[-1].num & SYM_CLASS_MASTER) {
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
			if ((yyvsp[-3].sym->data.symClass.firstMessage & (8192-1)) ||
			    (yyvsp[-3].sym->data.symClass.firstMessage == 8192)) {
			    classBeingParsed->data.symClass.firstMessage =
			    	yyvsp[-3].sym->data.symClass.firstMessage
				    +DEFAULT_CLASS_MESSAGES;
			} else {
			    classBeingParsed->data.symClass.firstMessage =
			    	yyvsp[-3].sym->data.symClass.firstMessage
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
	;}
    break;

  case 64:
#line 994 "parse.y"
    { yyval.sym = NullSymbol; ;}
    break;

  case 65:
#line 995 "parse.y"
    {
			yyerror("unidentified class symbol '%s'. Substituting with 'meta'",yyvsp[0].string);
			yyval.sym = NullSymbol;
	;}
    break;

  case 66:
#line 1003 "parse.y"
    {
	    yyval.num = SYM_CLASS_MASTER | SYM_CLASS_VARIANT;
	;}
    break;

  case 67:
#line 1007 "parse.y"
    {
	    yyval.num = SYM_CLASS_MASTER | SYM_CLASS_VARIANT;
	;}
    break;

  case 68:
#line 1011 "parse.y"
    {
	    yyval.num = SYM_CLASS_MASTER;
	;}
    break;

  case 69:
#line 1014 "parse.y"
    { yyval.num = 0; ;}
    break;

  case 70:
#line 1025 "parse.y"
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
	;}
    break;

  case 71:
#line 1210 "parse.y"
    {
	    SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	;}
    break;

  case 72:
#line 1214 "parse.y"
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
		*iptr = yyvsp[-1].sym;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 73:
#line 1233 "parse.y"
    { SWITCH_CONTEXT( LC_PARSE); ;}
    break;

  case 74:
#line 1235 "parse.y"
    {
	    yyval.sym = MakeInstanceVar(COMPOSITE_SYM, yyvsp[-2].string,
				    	    String_EnterZT("CompPart"));
	    yyval.sym->data.symComposite.linkPart = yyvsp[0].sym;
	    AddReloc(NullSymbol, RT_OPTR, yyvsp[-2].string, 1, String_EnterZT(""));
	;}
    break;

  case 75:
#line 1242 "parse.y"
    { SWITCH_CONTEXT( LC_PARSE); ;}
    break;

  case 76:
#line 1244 "parse.y"
    {
	    yyval.sym = MakeInstanceVar(LINK_SYM, yyvsp[0].string, String_EnterZT("LinkPart"));
	    yyval.sym->flags |= yyvsp[-1].num;
	    AddReloc(NullSymbol, RT_OPTR, yyvsp[0].string, 1, String_EnterZT(""));
	;}
    break;

  case 77:
#line 1250 "parse.y"
    { SWITCH_CONTEXT( LC_PARSE); ;}
    break;

  case 78:
#line 1252 "parse.y"
    {
	    yyval.sym = MakeInstanceVar(VIS_MONIKER_SYM, yyvsp[0].string,
				    	    String_EnterZT("ChunkHandle"));
	;}
    break;

  case 79:
#line 1257 "parse.y"
    { SWITCH_CONTEXT( LC_PARSE); ;}
    break;

  case 80:
#line 1259 "parse.y"
    {
	    yyval.sym = MakeInstanceVar(KBD_ACCELERATOR_SYM, yyvsp[0].string,
				    	    String_EnterZT("word"));
 	;}
    break;

  case 81:
#line 1264 "parse.y"
    { SWITCH_CONTEXT( LC_PARSE); ;}
    break;

  case 82:
#line 1266 "parse.y"
    {
	    if (!strcmp(TDS_CTYPE(yyvsp[-2].tdecl), "optr")) {
		yyval.sym = MakeInstanceVar(OPTR_SYM, TDS_IDENT(yyvsp[-2].tdecl),
				     String_EnterZT("optr"));
		yyval.sym->data.symRegInstance.defaultValue = yyvsp[0].string;
		AddReloc(NullSymbol, RT_OPTR, TDS_IDENT(yyvsp[-2].tdecl),
			 1, String_EnterZT(""));
	    } else if (!strcmp(TDS_CTYPE(yyvsp[-2].tdecl), "ChunkHandle")) {
	    	yyval.sym = MakeInstanceVar(CHUNK_INST_SYM, TDS_IDENT(yyvsp[-2].tdecl),
				    	    String_EnterZT("ChunkHandle"));
		yyval.sym->data.symRegInstance.defaultValue = yyvsp[0].string;
	    } else {
		yyval.sym = MakeInstanceVar(REG_INSTANCE_SYM, TDS_IDENT(yyvsp[-2].tdecl),
				     TDS_CTYPE(yyvsp[-2].tdecl));
		yyval.sym->data.symRegInstance.typeSuffix = TDS_TYPESUF(yyvsp[-2].tdecl);
		yyval.sym->data.symRegInstance.defaultValue = yyvsp[0].string;
	    }
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 83:
#line 1288 "parse.y"
    { yyval.num = SYM_IS_KBD_PATH; ;}
    break;

  case 84:
#line 1289 "parse.y"
    { yyval.num = 0; ;}
    break;

  case 85:
#line 1294 "parse.y"
    {
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	;}
    break;

  case 86:
#line 1297 "parse.y"
    {
	    yyval.string = yyvsp[0].string;
	;}
    break;

  case 87:
#line 1300 "parse.y"
    { yyval.string = NULL; ;}
    break;

  case 88:
#line 1310 "parse.y"
    {
	  SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	;}
    break;

  case 89:
#line 1314 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 90:
#line 1318 "parse.y"
    {
	  Symbol *sym;

	    if (classBeingParsed == NullSymbol) {
		yyerror("@vardata cannot be outside class declaration");
	    } else {

		sym = Symbol_Enter(TDS_IDENT(yyvsp[-2].tdecl), VARDATA_SYM, SYM_DEFINED);
		sym->data.symVardata.ctype = TDS_CTYPE(yyvsp[-2].tdecl);
		sym->data.symVardata.typeSuffix = TDS_TYPESUF(yyvsp[-2].tdecl);

		sym->data.symVardata.class = classBeingParsed;
		sym->data.symVardata.protoMinor = curProtoMinor;
		sym->data.symVardata.tag =
				classBeingParsed->data.symClass.nextTag;
		classBeingParsed->data.symClass.nextTag += 4;
		Output("#define %s %d\n", sym->name, sym->data.symVardata.tag);
	    }
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 91:
#line 1344 "parse.y"
    {yyval.sym = yyvsp[0].sym;;}
    break;

  case 92:
#line 1346 "parse.y"
    {
	    yyval.sym = yyvsp[0].sym;
	    Symbol_PopScope();
	;}
    break;

  case 93:
#line 1351 "parse.y"
    {
	    yyerror("'%s' is not a vardata symbol",yyvsp[0].string);
	    Symbol_PopScope();
	    yyval.sym = NullSymbol;
	;}
    break;

  case 94:
#line 1357 "parse.y"
    {
	    Symbol_PopScope();
	    yyval.sym = NullSymbol;
	;}
    break;

  case 95:
#line 1361 "parse.y"
    { yyerror("'%s' is not a vardata symbol",yyvsp[0].string); yyval.sym = NullSymbol;;}
    break;

  case 96:
#line 1365 "parse.y"
    {
	    Symbol_PushScope(yyvsp[0].sym->data.symClass.localSymbols);
	;}
    break;

  case 98:
#line 1374 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE_NO_LOOKUP);
	;}
    break;

  case 99:
#line 1378 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 100:
#line 1382 "parse.y"
    {
	    Symbol *sym;

	    if(yyvsp[-5].sym != NullSymbol){

		/*
		 * Make sure we're in the scope of the class of whose vardata
		 * this thing will become a member.
		 */
		Symbol_PushScope(yyvsp[-5].sym->data.symVardata.class->data.symClass.localSymbols);
		sym = Symbol_Enter(yyvsp[0].string, VARDATA_SYM, SYM_DEFINED);
		sym->data.symVardata.ctype = yyvsp[-2].string;
		sym->data.symVardata.class = yyvsp[-5].sym->data.symVardata.class;
		sym->data.symVardata.tag = yyvsp[-5].sym->data.symVardata.tag;
		sym->data.symVardata.typeSuffix =
		    yyvsp[-5].sym->data.symVardata.typeSuffix;
		Output("#define %s %d", sym->name, sym->data.symVardata.tag);

		Symbol_PopScope();

		SWITCH_CONTEXT( LC_NONE);
	    }
	;}
    break;

  case 101:
#line 1414 "parse.y"
    {
	    if (classBeingParsed == NullSymbol) {
		yyerror("@protominor cannot be outside class declaration");
	    } else {
		curProtoMinor = yyvsp[0].sym;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 102:
#line 1426 "parse.y"
    {
	    if (classBeingParsed == NullSymbol) {
		yyerror("@protoreset cannot be outside class declaration");
	    } else {
		curProtoMinor = NullSymbol;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 103:
#line 1443 "parse.y"
    {
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	;}
    break;

  case 104:
#line 1447 "parse.y"
    {
  	    if(yyvsp[-3].sym != NullSymbol){
		InstanceValue *inst;
		char buf[1000];
		/*
		 * Replace any occurrance of @default with
		 * the old default value
		 */
		if (defaultdebug) {
		    fprintf(stderr, "*** Defaulting %s of class %s...",
			    yyvsp[-3].sym->name, classBeingParsed->name);
		}
		inst = FindDefault(classBeingParsed, yyvsp[-3].sym->name);
		if (inst != NullInstanceValue) {
		    if (defaultdebug) {
			fprintf(stderr, "found %s -> ", inst->value);
		    }
		    CopySubst(buf, yyvsp[0].string, "@default", inst->value);
		} else {
		    if (defaultdebug) {
			fprintf(stderr, "using default %s ->",
				yyvsp[-3].sym->data.symRegInstance.defaultValue);
		    }
		    if (yyvsp[-3].sym->data.symRegInstance.defaultValue != NULL) {
			CopySubst(buf, yyvsp[0].string, "@default",
				  yyvsp[-3].sym->data.symRegInstance.defaultValue);
		    } else {
			CopySubst(buf, yyvsp[0].string, "@default", "0");
		    }
		}
		if (defaultdebug) {
		    fprintf(stderr, "%s\n", buf);
		}
		if (yyvsp[-3].sym->type == VARIANT_PTR_SYM) {
		    Symbol *oldScope, *tempClass;

		    tempClass = Symbol_Find(yyvsp[0].string, TRUE);
		    if (tempClass == NullSymbol) {
			yyerror("superclass for variant (%s) not defined", yyvsp[0].string);
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
		inst->name = yyvsp[-3].sym->name;
		inst->value = String_EnterZT(buf);
		SWITCH_CONTEXT( LC_PARSE);
	    }
	;}
    break;

  case 105:
#line 1507 "parse.y"
    {
    	    SWITCH_CONTEXT( LC_NONE);
    	;}
    break;

  case 109:
#line 1516 "parse.y"
    {
 	 	yyerror("'%s' not an instance variable, can't set its default",
			yyvsp[0].string);
		yyval.sym = NullSymbol;
 	;}
    break;

  case 110:
#line 1530 "parse.y"
    {
	    SWITCH_CONTEXT( LC_STRING_COMMA);
	;}
    break;

  case 111:
#line 1534 "parse.y"
    {
	    relocSym = Symbol_Find(yyvsp[0].string, TRUE);
	    if ((relocSym == NullSymbol) || (relocSym->type != VARDATA_SYM)) {
	    	SWITCH_CONTEXT( LC_PARSE);
		relocString = yyvsp[0].string;
	    }
	;}
    break;

  case 113:
#line 1545 "parse.y"
    {
	    AddReloc(NullSymbol, yyvsp[0].num, relocString, yyvsp[-1].num, relocStruct);
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 114:
#line 1550 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 115:
#line 1554 "parse.y"
    {
	    AddReloc(relocSym, yyvsp[0].num, yyvsp[-4].string, yyvsp[-1].num, relocStruct);
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 116:
#line 1562 "parse.y"
    {
	    SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
	;}
    break;

  case 117:
#line 1566 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 118:
#line 1570 "parse.y"
    {
	    yyval.num = yyvsp[-5].num;
	    relocStruct = String_EnterZT(yyvsp[-2].string);
	;}
    break;

  case 119:
#line 1575 "parse.y"
    {
	    yyval.num = 1;
	    relocStruct = String_EnterZT("");
	;}
    break;

  case 120:
#line 1582 "parse.y"
    { yyval.num = RT_FPTR; ;}
    break;

  case 121:
#line 1583 "parse.y"
    { yyval.num = RT_HPTR; ;}
    break;

  case 122:
#line 1584 "parse.y"
    { yyval.num = RT_OPTR; ;}
    break;

  case 123:
#line 1594 "parse.y"
    {
	;}
    break;

  case 124:
#line 1597 "parse.y"
    {
	    Symbol **sym;

	    if (classBeingParsed != NullSymbol) {
		yyerror("@classdecl for %s must be outside class declaration",
			yyvsp[-3].sym->name);
	    }

	    /*
	     * Check whether the class has already been declared, since
	     * this would cause an endless loop in DoFinalOutput if left
	     * unchecked.
	     */
	    if (yyvsp[-3].sym->flags & SYM_CLASS_DECLARED) {
		yyerror("Duplicate @classdecl for %s", yyvsp[-3].sym->name);
	    } else {
		for (sym = &classDeclList; *sym != NullSymbol;
		     sym= &((*sym)->data.symClass.nextDeclaredClass));
		*sym = yyvsp[-3].sym;
		yyvsp[-3].sym->flags |= yyvsp[-1].num | SYM_CLASS_DECLARED;

		if (curResource != NullSymbol) {
		    if (yyvsp[-3].sym->data.symClass.classSeg != NullSymbol) {
			if (yyvsp[-3].sym->data.symClass.classSeg != curResource) {
			    yyerror("%s is already in segment %s, so it can't be redeclared in %s", yyvsp[-3].sym->name, yyvsp[-3].sym->data.symClass.classSeg->name, curResource->name);
			}
		    } else if (compiler == COM_HIGHC) {
			yyerror("%s must be the current segment around the @class/@endc for %s, otherwise High C will put %s into dgroup, which is probably not what you were expecting.", curResource->name, yyvsp[-3].sym->name, yyvsp[-3].sym->name);
		    } else {
			yyvsp[-3].sym->data.symClass.classSeg = curResource;
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
            if (yyvsp[-3].sym->data.symClass.masterLevel != 0)
 	    {
		if (compiler == COM_BORL)
		{
		    char    *cp, foo[205];
#define STRLEN_CLASS 5
		    cp = yyvsp[-3].sym->name + strlen(yyvsp[-3].sym->name) - STRLEN_CLASS;
		    *cp = '\0';

		    /*
		     * We have to use CompilerStartSegment here, 'cause
		     * using -zE directly will screw us up later.
		     */
		    sprintf(foo, "%sBase", yyvsp[-3].sym->name);
		    CompilerStartSegment("_BOGUS_", foo);
		    Output("\n#pragma option -zFCODE\n%sBase _far %sBaseBogusVariable[1]={0};\n#pragma option -zF*", yyvsp[-3].sym->name, yyvsp[-3].sym->name);
		    CompilerEndSegment("_BOGUS_", foo);

		    *cp = 'C';
		    OutputLineNumber(yylineno,curFile->name);
		}
	    }
	;}
    break;

  case 125:
#line 1665 "parse.y"
    {
    	    yyerror("Can't declare class for '%s', not defined.",yyvsp[-2].string);

	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 126:
#line 1674 "parse.y"
    {
	    yyval.num = SYM_NEVER_SAVED;
	;}
    break;

  case 127:
#line 1677 "parse.y"
    { yyval.num = 0; ;}
    break;

  case 128:
#line 1687 "parse.y"
    {
	  SWITCH_CONTEXT( LC_TYPE_STRING_NO_MATCH_PARENS);
	    currentMPD = numRegs = 0;
	    stackParams = forceRegs = forceNoRegs = multipleReturn = FALSE;
	;}
    break;

  case 130:
#line 1697 "parse.y"
    {
	    /*
	     * Enter the identifier as a message and initialize it.  We must
	     * enter it in the global scope so that it is accessable anywhere.
	     */
	    curMessage = EnterSymbolInGlobal(TDS_IDENT(yyvsp[-1].tdecl),
					     MSG_SYM, SYM_DEFINED);
	    SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	    currentMessageReturnType = TDS_CTYPE(yyvsp[-1].tdecl);
	;}
    break;

  case 131:
#line 1708 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 132:
#line 1712 "parse.y"
    {
	    if (classBeingParsed == NullSymbol) {
		yyerror("@message cannot be outside class declaration");
	    } else {
		if (TDS_TYPESUF_IS_NOT_NULL(yyvsp[-8].tdecl)) {
		    yyerror("messages cannot return arrays (use *)");
		}
		curMessage->data.symMessage.class = classBeingParsed;
		curMessage->data.symMessage.protoMinor = curProtoMinor;
		curMessage->data.symMessage.messageNumber =
				classBeingParsed->data.symClass.nextMessage++;
		curMessage->data.symMessage.firstParam = yyvsp[-4].param;
		curMessage->data.symMessage.returnType = TDS_CTYPE(yyvsp[-8].tdecl);
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
    	;}
    break;

  case 133:
#line 1740 "parse.y"
    {
	  SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 134:
#line 1744 "parse.y"
    {
	    /*
	     * Enter the identifier as a message and initialize it.  We must
	     * enter it in the global scope so that it is accessable anywhere.
	     */
	    curMessage = EnterSymbolInGlobal(yyvsp[-1].string, MSG_SYM, SYM_DEFINED);

	    if (classBeingParsed == NullSymbol) {
		yyerror("@message cannot be outside class declaration");

	    } else {
		curMessage->data.symMessage.class = classBeingParsed;
		curMessage->data.symMessage.messageNumber =
				classBeingParsed->data.symClass.nextMessage++;
		curMessage->data.symMessage.firstParam =
		    	    	    	yyvsp[-3].sym->data.symMessage.firstParam;
		curMessage->data.symMessage.returnType =
		    	    	    	yyvsp[-3].sym->data.symMessage.returnType;
		curMessage->data.symMessage.mpd =
		    	    	    	yyvsp[-3].sym->data.symMessage.mpd;
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
    	;}
    break;

  case 135:
#line 1782 "parse.y"
    {
	    /*
	     * If no parameters are given then set to register params
	     */
	    if ( !stackParams && ((currentMPD & MPD_PASS) == 0)) {
	    	currentMPD |= MPD_REGISTER_PARAMS;
	    }
	;}
    break;

  case 136:
#line 1791 "parse.y"
    {
	    /*
	     * No parameters given -> set to register params
	     */
	    yyval.param = NullParam;
	    currentMPD |= MPD_REGISTER_PARAMS;
	;}
    break;

  case 137:
#line 1802 "parse.y"
    {
	    SWITCH_CONTEXT(  LC_TYPE_STRING_MATCH_PARENS);
	    yyval.num = multipleReturn;
	;}
    break;

  case 138:
#line 1807 "parse.y"
    {
	    MessageParam **pp;

	    /*
	     * Make sure the value of the global multipleReturn variable hasn't
	     * changed because of this parameter, as any multiple-return
	     * parameter must be the first one passed (that's where the
	     * kernel puts the thing).
	     */
	    if (yyvsp[-1].num != multipleReturn) {
		yyerror("multiple-return parameter must be first parameter for message");
	    }

	    if (yyvsp[-3].param != NullParam) {
		for (pp = &(yyvsp[-3].param->next); *pp != NullParam; pp = &((*pp)->next));
		*pp = yyvsp[0].param;
		yyval.param = yyvsp[-3].param;
	    } else {
		yyval.param = yyvsp[0].param;
	    }
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 139:
#line 1829 "parse.y"
    { SWITCH_CONTEXT( LC_PARSE);   yyval.param = yyvsp[0].param; ;}
    break;

  case 140:
#line 1839 "parse.y"
    {
	    forceNoRegs = TRUE;
	    stackParams = TRUE;
	;}
    break;

  case 142:
#line 1848 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 143:
#line 1852 "parse.y"
    {
	    yyval.param = (MessageParam *) zmalloc(sizeof(MessageParam));
	    yyval.param->name = TDS_IDENT(yyvsp[-2].tdecl);
	    yyval.param->ctype = TDS_CTYPE(yyvsp[-2].tdecl);
	    yyval.param->typeSuffix = TDS_TYPESUF(yyvsp[-2].tdecl);
	;}
    break;

  case 144:
#line 1862 "parse.y"
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
	;}
    break;

  case 145:
#line 1884 "parse.y"
    {
	    if (forceRegs) {
		yyerror("must specify registers for all params or none");
	    } else {
		forceNoRegs = TRUE;
		if (!stackParams) {
	            currentMPD |= MPD_C_PARAMS;
		}
	    }
	;}
    break;

  case 146:
#line 1897 "parse.y"
    { AddRegDefinition(MPR_CL); ;}
    break;

  case 147:
#line 1898 "parse.y"
    { AddRegDefinition(MPR_CH); ;}
    break;

  case 148:
#line 1899 "parse.y"
    { AddRegDefinition(MPR_DL); ;}
    break;

  case 149:
#line 1900 "parse.y"
    { AddRegDefinition(MPR_DH); ;}
    break;

  case 150:
#line 1901 "parse.y"
    { AddRegDefinition(MPR_CX); ;}
    break;

  case 151:
#line 1902 "parse.y"
    { AddRegDefinition(MPR_DX); ;}
    break;

  case 152:
#line 1903 "parse.y"
    { AddRegDefinition(MPR_BP); ;}
    break;

  case 153:
#line 1905 "parse.y"
    {
	    AddRegDefinition(yyvsp[-2].num);
	    AddRegDefinition(yyvsp[0].num);
	;}
    break;

  case 154:
#line 1910 "parse.y"
    {
	    AddRegDefinition(yyvsp[-2].num);
	    AddRegDefinition(yyvsp[0].num);
	;}
    break;

  case 155:
#line 1915 "parse.y"
    {
	    if (numRegs != 0) {
		yyerror("ss:bp cannot be used with any other register");
	    } else if (currentMPD & MPD_STRUCT_AT_SS_BP) {
		yyerror("only one ss:bp allowed");
	    } else {
		currentMPD |= MPD_STRUCT_AT_SS_BP;
	    }
	;}
    break;

  case 156:
#line 1925 "parse.y"
    {
	    multipleReturn = TRUE;
	    currentMPD |= (MRT_MULTIPLE << MPD_RETURN_TYPE_OFFSET) |
		    	    (yyvsp[0].num << MPD_RET_MULT_OFFSET);
	;}
    break;

  case 157:
#line 1930 "parse.y"
    {yyerror("unrecognized register syntax '%s'",yyvsp[0].string);;}
    break;

  case 158:
#line 1934 "parse.y"
    { yyval.num = MPR_CX; ;}
    break;

  case 159:
#line 1935 "parse.y"
    { yyval.num = MPR_DX; ;}
    break;

  case 160:
#line 1936 "parse.y"
    { yyval.num = MPR_BP; ;}
    break;

  case 161:
#line 1940 "parse.y"
    { yyval.num = MRMT_AXBPCXDX; ;}
    break;

  case 162:
#line 1941 "parse.y"
    { yyval.num = MRMT_AXCXDXBP; ;}
    break;

  case 163:
#line 1942 "parse.y"
    { yyval.num = MRMT_CXDXBPAX; ;}
    break;

  case 164:
#line 1943 "parse.y"
    { yyval.num = MRMT_DXCX; ;}
    break;

  case 165:
#line 1944 "parse.y"
    { yyval.num = MRMT_BPAXDXCX; ;}
    break;

  case 166:
#line 1945 "parse.y"
    { yyval.num = MRMT_MULTIPLEAX; ;}
    break;

  case 167:
#line 1950 "parse.y"
    {
	    if (multipleReturn &&
		  ((currentMPD >> MPD_RETURN_TYPE_OFFSET) != MRT_MULTIPLE)) {
		yyerror("cannot have a return type in addition to multiple");
	    }
	;}
    break;

  case 168:
#line 1957 "parse.y"
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
	;}
    break;

  case 169:
#line 1976 "parse.y"
    { currentMPD |= RetTypeBWReg(MRBWT_AX); ;}
    break;

  case 170:
#line 1977 "parse.y"
    { currentMPD |= RetTypeBWReg(MRBWT_CX); ;}
    break;

  case 171:
#line 1978 "parse.y"
    { currentMPD |= RetTypeBWReg(MRBWT_DX); ;}
    break;

  case 172:
#line 1979 "parse.y"
    { currentMPD |= RetTypeBWReg(MRBWT_BP); ;}
    break;

  case 173:
#line 1980 "parse.y"
    { currentMPD |= RetTypeBWReg(MRBWT_AL); ;}
    break;

  case 174:
#line 1981 "parse.y"
    { currentMPD |= RetTypeBWReg(MRBWT_AH); ;}
    break;

  case 175:
#line 1982 "parse.y"
    { currentMPD |= RetTypeBWReg(MRBWT_CL); ;}
    break;

  case 176:
#line 1983 "parse.y"
    { currentMPD |= RetTypeBWReg(MRBWT_CH); ;}
    break;

  case 177:
#line 1984 "parse.y"
    { currentMPD |= RetTypeBWReg(MRBWT_DL); ;}
    break;

  case 178:
#line 1985 "parse.y"
    { currentMPD |= RetTypeBWReg(MRBWT_DH); ;}
    break;

  case 179:
#line 1986 "parse.y"
    { currentMPD |= RetTypeBWReg(MRBWT_BPL); ;}
    break;

  case 180:
#line 1987 "parse.y"
    { currentMPD |= RetTypeBWReg(MRBWT_BPH); ;}
    break;

  case 181:
#line 1989 "parse.y"
    {
	    currentMPD |= (MRT_DWORD << MPD_RETURN_TYPE_OFFSET) |
		    	    (yyvsp[-2].num << MPD_RET_DWORD_HIGH_OFFSET) |
	    	    	    (yyvsp[0].num << MPD_RET_DWORD_LOW_OFFSET);
	;}
    break;

  case 182:
#line 1995 "parse.y"
    {
	    currentMPD |= (MRT_DWORD << MPD_RETURN_TYPE_OFFSET) |
		    	    (yyvsp[-2].num << MPD_RET_DWORD_HIGH_OFFSET) |
	    	    	    (yyvsp[0].num << MPD_RET_DWORD_LOW_OFFSET);
	;}
    break;

  case 183:
#line 2001 "parse.y"
    {
	    currentMPD |= (MRT_VOID << MPD_RETURN_TYPE_OFFSET);
	;}
    break;

  case 184:
#line 2004 "parse.y"
    {yyerror("unrecognized return register '%s'",yyvsp[0].string);;}
    break;

  case 185:
#line 2008 "parse.y"
    { yyval.num = MRDWR_AX; ;}
    break;

  case 186:
#line 2009 "parse.y"
    { yyval.num = MRDWR_CX; ;}
    break;

  case 187:
#line 2010 "parse.y"
    { yyval.num = MRDWR_DX; ;}
    break;

  case 188:
#line 2011 "parse.y"
    { yyval.num = MRDWR_BP; ;}
    break;

  case 189:
#line 2020 "parse.y"
    {

	;}
    break;

  case 190:
#line 2024 "parse.y"
    {
	    if (classBeingParsed == NullSymbol) {
		yyerror("@reserveMessages outside class declaration");
	    } else {
	      classBeingParsed->data.symClass.nextMessage += yyvsp[-1].num;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 191:
#line 2034 "parse.y"
    {
    	    if(yyvsp[-3].sym){
		yyvsp[-3].sym->data.symExport.nextMessage += yyvsp[-1].num;
		SWITCH_CONTEXT( LC_NONE);
	    }
	;}
    break;

  case 193:
#line 2044 "parse.y"
    { yywarning("reserving one message.");yyval.num = 1; ;}
    break;

  case 194:
#line 2053 "parse.y"
    {

	;}
    break;

  case 195:
#line 2057 "parse.y"
    {
	    if (classBeingParsed == NullSymbol) {
		yyerror("@setMessageNum outside class declaration");
	    } else {
	      classBeingParsed->data.symClass.nextMessage = yyvsp[-1].num;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 196:
#line 2067 "parse.y"
    {
    	    if(yyvsp[-3].sym){
		yyvsp[-3].sym->data.symExport.nextMessage = yyvsp[-1].num;
		SWITCH_CONTEXT( LC_NONE);
	    }
	;}
    break;

  case 197:
#line 2076 "parse.y"
    { yyval.num = yyvsp[0].num; ;}
    break;

  case 198:
#line 2077 "parse.y"
    { yywarning("reserving one message."); yyval.num = 1; ;}
    break;

  case 199:
#line 2081 "parse.y"
    { yyval.num = yyvsp[-2].num + yyvsp[0].num; ;}
    break;

  case 200:
#line 2082 "parse.y"
    { yyval.num = yyvsp[-2].num - yyvsp[0].num; ;}
    break;

  case 201:
#line 2083 "parse.y"
    { yyval.num = yyvsp[0].num; ;}
    break;

  case 202:
#line 2086 "parse.y"
    { yyval.num = yyvsp[-1].num; ;}
    break;

  case 203:
#line 2087 "parse.y"
    { yyval.num = -yyvsp[0].num; ;}
    break;

  case 204:
#line 2088 "parse.y"
    { yyval.num = yyvsp[0].num; ;}
    break;

  case 205:
#line 2089 "parse.y"
    { yyval.num = yyvsp[0].sym->data.symMessage.messageNumber; ;}
    break;

  case 206:
#line 2098 "parse.y"
    {

	;}
    break;

  case 207:
#line 2102 "parse.y"
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
		sym = EnterSymbolInGlobal(yyvsp[-3].string, EXPORT_SYM, SYM_DEFINED);
		sym->data.symExport.class = classBeingParsed;
		sym->data.symExport.firstMessage =
		    sym->data.symExport.nextMessage =
				classBeingParsed->data.symClass.nextMessage;
		classBeingParsed->data.symClass.nextMessage += yyvsp[-1].num;
	    }

	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 208:
#line 2127 "parse.y"
    { yyval.num = yyvsp[0].num; ;}
    break;

  case 209:
#line 2128 "parse.y"
    {
    		yywarning("using default number of exported messages.");
		yyval.num = DEFAULT_EXPORTED_MESSAGES;
	;}
    break;

  case 211:
#line 2139 "parse.y"
    {
	    yyval.sym = NullSymbol;
	    yyerror("'%s' is not an exported message range",yyvsp[0].string);
	;}
    break;

  case 212:
#line 2146 "parse.y"
    {
	    SWITCH_CONTEXT( LC_TYPE_STRING_NO_MATCH_PARENS);
	    currentMPD = numRegs = 0;
	    stackParams = forceRegs = forceNoRegs = multipleReturn = FALSE;

	    yyval.sym = yyvsp[-1].sym;
	;}
    break;

  case 213:
#line 2157 "parse.y"
    {
	    SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	    currentMessageReturnType = TDS_CTYPE(yyvsp[-1].tdecl);
	;}
    break;

  case 214:
#line 2162 "parse.y"
    {
	    /*
	     * Enter the identifier as a message and initialize it
	     */
	    curMessage = EnterSymbolInGlobal(TDS_IDENT(yyvsp[-5].tdecl), MSG_SYM, SYM_DEFINED);
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 215:
#line 2170 "parse.y"
    {
	    if (TDS_TYPESUF_IS_NOT_NULL(yyvsp[-8].tdecl)) {
		yyerror("messages cannot return arrays (use *)");
	    }
	    if(yyvsp[-9].sym != NullSymbol){
		curMessage->flags |= SYM_IMPORTED;
		curMessage->data.symMessage.class = yyvsp[-9].sym->data.symExport.class;
		curMessage->data.symMessage.messageNumber =
		    yyvsp[-9].sym->data.symExport.nextMessage++;
		curMessage->data.symMessage.firstParam = yyvsp[-4].param;
		curMessage->data.symMessage.returnType = TDS_CTYPE(yyvsp[-8].tdecl);
		curMessage->data.symMessage.mpd = currentMPD;
		/*
		 *  there is not current class, so we don't add the message
		 *  to a list so we can put out the imported messages in an
		 *  enumeration. Nor can we output a define name1 name2 as
		 *  for @alias, because name2 don't exist, because exported
		 *  messages don't get names.
		 */
		Output("#define %s %d", TDS_IDENT(yyvsp[-8].tdecl),
		       curMessage->data.symMessage.messageNumber);

		if (mpddebug) {
		    Output("\n#define %s_MPD %s", curMessage->name,
			   GenerateMPDString(curMessage,
					     MPD_PASS_AND_RETURN));
		}
	    }

    	    SWITCH_CONTEXT( LC_NONE);
    	;}
    break;

  case 216:
#line 2202 "parse.y"
    {
	  SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 217:
#line 2206 "parse.y"
    {
	    if(yyvsp[-3].sym && yyvsp[-6].sym){ /* check the prefix and message */

		/*
		 * Enter the identifier as a message and initialize it.
		 * We must enter it in the global scope so that it
		 * is accessable anywhere.
		 */
		curMessage = EnterSymbolInGlobal(yyvsp[-1].string, MSG_SYM,
						 SYM_DEFINED|SYM_IMPORTED);

		curMessage->data.symMessage.class = yyvsp[-6].sym->data.symExport.class;
		curMessage->data.symMessage.messageNumber =
		    yyvsp[-6].sym->data.symExport.nextMessage++;
		curMessage->data.symMessage.firstParam =
		    yyvsp[-3].sym->data.symMessage.firstParam;
		curMessage->data.symMessage.returnType =
		    yyvsp[-3].sym->data.symMessage.returnType;
		curMessage->data.symMessage.mpd = yyvsp[-3].sym->data.symMessage.mpd;
		/* can't do this for reasons discussed above.             */
		/* ADD_MESSAGE_LIST_ELEMENT(classBeingParsed,curMessage); */

		Output("#define %s %d", yyvsp[-1].string,
		       curMessage->data.symMessage.messageNumber);



		if (mpddebug) {
		    Output("\n#define %s_MPD %s", curMessage->name,
			   GenerateMPDString(curMessage,
					     MPD_PASS_AND_RETURN));
		}
	    }
            SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 219:
#line 2251 "parse.y"
    {
 		yyval.sym = NullSymbol; yyerror("'%s' is not a message symbol.",yyvsp[0].string);
 	;}
    break;

  case 220:
#line 2258 "parse.y"
    {
	    SWITCH_CONTEXT( LC_TYPE_STRING_NO_MATCH_PARENS);
	    currentMPD = numRegs = 0;
	    stackParams = forceRegs = forceNoRegs = multipleReturn = FALSE;
	;}
    break;

  case 221:
#line 2264 "parse.y"
    {
	    SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	    currentMessageReturnType = TDS_CTYPE(yyvsp[-1].tdecl);
	;}
    break;

  case 222:
#line 2269 "parse.y"
    {
	    /*
	     * Enter the identifier as a message and initialize it
	     */
	    curMessage = EnterSymbolInGlobal(TDS_IDENT(yyvsp[-5].tdecl), MSG_SYM, SYM_DEFINED);
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 223:
#line 2277 "parse.y"
    {
	    if (TDS_TYPESUF_IS_NOT_NULL(yyvsp[-8].tdecl)) {
		yyerror("messages cannot return arrays (use *)");
	    }
	    if(yyvsp[-11].sym != NullSymbol){
		if ((yyvsp[-11].sym->data.symMessage.class != NullSymbol) &&
		    (yyvsp[-11].sym->data.symMessage.class != classBeingParsed) &&
		    !(yyvsp[-11].sym->flags & SYM_IMPORTED))
		{
		    yywarning("%s is not a message for the class being defined now",
			      yyvsp[-11].sym->name);
		}
		curMessage->data.symMessage.class = yyvsp[-11].sym->data.symMessage.class;
		curMessage->data.symMessage.messageNumber =
		    yyvsp[-11].sym->data.symMessage.messageNumber;
		curMessage->data.symMessage.firstParam = yyvsp[-4].param;
		curMessage->data.symMessage.returnType = TDS_CTYPE(yyvsp[-8].tdecl);
		curMessage->data.symMessage.mpd = currentMPD;
		/*
		 * We can't output this in an enum, because there is no class,
		 * as this is just an alias. Luckily though, we know the name
		 * of the message, and it will be in an enumerated type, so we
		 * define it be the name of the enumeration.
		 */
		Output("#define %s %s", TDS_IDENT(yyvsp[-8].tdecl), yyvsp[-11].sym->name);

		if (mpddebug) {
		    Output("\n#define %s_MPD %s", curMessage->name,
			   GenerateMPDString(curMessage, MPD_PASS_AND_RETURN));
		}

	    }
    	    SWITCH_CONTEXT( LC_NONE);
    	;}
    break;

  case 224:
#line 2321 "parse.y"
    {
	    SWITCH_CONTEXT( LC_TYPE_STRING_NO_MATCH_PARENS);
	    currentMPD = numRegs = 0;
	    stackParams = forceRegs = forceNoRegs = multipleReturn = FALSE;
	;}
    break;

  case 225:
#line 2327 "parse.y"
    {
	    SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	    currentMessageReturnType = TDS_CTYPE(yyvsp[-1].tdecl);
	;}
    break;

  case 226:
#line 2332 "parse.y"
    {
	    /*
	     * Enter the identifier as a message and initialize it
	     */
	    curMessage = EnterSymbolInGlobal(TDS_IDENT(yyvsp[-5].tdecl), MSG_SYM, SYM_DEFINED);
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 227:
#line 2340 "parse.y"
    {
	    if (TDS_TYPESUF_IS_NOT_NULL(yyvsp[-8].tdecl)) {
		yyerror("messages cannot return arrays (use *)");
	    }
	    curMessage->data.symMessage.class = NullSymbol;
	    curMessage->data.symMessage.firstParam = yyvsp[-4].param;
	    curMessage->data.symMessage.returnType = TDS_CTYPE(yyvsp[-8].tdecl);
	    curMessage->data.symMessage.mpd = currentMPD;
	    if (mpddebug) {
		Output("\n#define %s_MPD %s", curMessage->name,
		       GenerateMPDString(curMessage, MPD_PASS_AND_RETURN));
	    }

    	    SWITCH_CONTEXT( LC_NONE);
    	;}
    break;

  case 228:
#line 2360 "parse.y"
    {
	   yyval.num = FALSE;
	;}
    break;

  case 229:
#line 2365 "parse.y"
    {
	  yyval.num = TRUE;
	;}
    break;

  case 230:
#line 2371 "parse.y"
    {yyval.string = yyvsp[-1].string;;}
    break;

  case 231:
#line 2372 "parse.y"
    {yyval.string = NULL;;}
    break;

  case 232:
#line 2376 "parse.y"
    {yyval.ch = '{'; ;}
    break;

  case 233:
#line 2377 "parse.y"
    {yyval.ch = ';'; ;}
    break;

  case 235:
#line 2392 "parse.y"
    {
	    yyval.sym = NullSymbol;
	    if (yychar == IDENT) {
		yyerror("expecting a class, not the identifier '%s'",
			yylval.string);
	    } else if(yychar > FIRSTSYM && yychar < LASTSYM) {
		yyerror("expecting a class, not the symbol '%s'",
			yylval.sym->name);
	    }
	;}
    break;

  case 236:
#line 2408 "parse.y"
    {
	    if(yyvsp[0].sym){
		methClass = yyvsp[0].sym;
		Symbol_PushScope(yyvsp[0].sym->data.symClass.localSymbols);
	    }
	    methModel = yyvsp[-2].num;
            methName = yyvsp[-1].string;
 	    methFirst = NullSymbol;
	    SWITCH_CONTEXT( LC_PARSE);


	;}
    break;

  case 237:
#line 2421 "parse.y"
    {
    	    if(yyvsp[-4].sym && yyvsp[-1].meth){
		GenerateCurRootDefine(yyvsp[-1].meth);
		GenerateMethodDef(yyvsp[-1].meth);
		Output("%c", yyvsp[0].ch);          /* output the ';' or '{'        */

		if(yyvsp[-7].num == FALSE || yyvsp[0].ch == '{') { /* @method || @extern method{ */
		    void OutputMethodAntiWarningCode(Method *meth);

		    if(yyvsp[0].ch == '{'){
			OutputMethodAntiWarningCode(yyvsp[-1].meth);
		    }else{
			/* this really isn't bad. we put out the decl, */
			/* but the important thing is that we allow    */
			/* people to assign their own method handler   */
			/* its even good that we put out the decl,     */
			/* because this allows type checking later.    */

			/* yyerror("expect method body, not just a ';'"); */
		    }
		    /* if is @method .... and class not declared... */

		    if(yyvsp[-7].num == FALSE && !(yyvsp[-4].sym->flags & SYM_CLASS_DECLARED)){
			yyerror("you attempted to define method '%s' for the undeclared "
				"class '%s'",yyvsp[-1].meth->name,yyvsp[-4].sym->name);
		    }
		}

		curMethod = yyvsp[-1].meth;
		Symbol_PopScope();
		SWITCH_CONTEXT( LC_NONE);
	    }
	;}
    break;

  case 240:
#line 2464 "parse.y"
    {
	    Method *meth;
	    char name[200];
	    char *cp;

    	    if (methClass == NullSymbol){
		yyval.meth = NULL;
		goto skip_the_methodMessageProduction;
	    } else if ((yyvsp[0].sym->data.symMessage.class == NullSymbol) &&
		  (yyvsp[0].sym->data.symMessage.messageNumber != 0))
	    {
		yyerror("%s is a prototype, not a real message",
			yyvsp[0].sym->name);
		yyval.meth = NULL;
		goto skip_the_methodMessageProduction;
	    } else if (yyvsp[0].sym->data.symMessage.class != NullSymbol) {
		if (!CheckRelated(methClass, yyvsp[0].sym->data.symMessage.class,
				  methClass))
		{
		    yyerror("%s is not a message defined by %s or its ancestors",
			    yyvsp[0].sym->name, methClass->name);
		    yyval.meth = NULL;
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
		if (!strncmp(yyvsp[0].sym->name, "MSG_", 4)) {
		    strcpy(cp, (yyvsp[0].sym->name)+4);
		} else {
		    strcpy(cp, yyvsp[0].sym->name);
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
	    meth->message = yyvsp[0].sym;
	    meth->class = methClass;

	    meth->name = methName;
	    if (yyvsp[0].sym->data.symMessage.class == NullSymbol) {
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
		if (yyvsp[0].sym->data.symMessage.mpd != methFirst->data.symMessage.mpd) {
		    yyerror("method cannot handle incompatible messages");
		}
	    } else {
		methFirst = yyvsp[0].sym;
	    }
 	    yyval.meth = meth;
	skip_the_methodMessageProduction:

	;}
    break;

  case 241:
#line 2565 "parse.y"
    {
	    yyval.meth = NULL;
	    yyerror("'%s' is not a message symbol.",yyvsp[0].string);
        ;}
    break;

  case 242:
#line 2572 "parse.y"
    { yyval.num = MM_FAR; ;}
    break;

  case 243:
#line 2573 "parse.y"
    { yyval.num = MM_NEAR; ;}
    break;

  case 244:
#line 2574 "parse.y"
    { yyval.num = MM_BASED; ;}
    break;

  case 245:
#line 2575 "parse.y"
    { yyval.num = defaultModel; ;}
    break;

  case 246:
#line 2583 "parse.y"
    { defaultModel = MM_FAR; SWITCH_CONTEXT( LC_NONE); ;}
    break;

  case 247:
#line 2584 "parse.y"
    { defaultModel = MM_NEAR; SWITCH_CONTEXT( LC_NONE); ;}
    break;

  case 248:
#line 2585 "parse.y"
    { defaultModel = MM_BASED; SWITCH_CONTEXT( LC_NONE); ;}
    break;

  case 249:
#line 2594 "parse.y"
    {
	    Output("extern %s %s %s%s;",
		   compilerOffsetTypeName,
		   compilerFarKeyword,
		   yyvsp[-1].string,
		   _ar);
	    (void) EnterSymbolInGlobal(yyvsp[-1].string, OBJECT_SYM,
 		                       SYM_DEFINED | SYM_EXTERN);
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 250:
#line 2605 "parse.y"
    {
	    yyerror("%s: cannot make extern, already defined in line %d of '%s'\n",
			yyvsp[-1].sym->name, yyvsp[-1].sym->lineNumber, yyvsp[-1].sym->realFileName);
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 251:
#line 2611 "parse.y"
    {
	    Output("extern %s %s %s%s;",
		   compilerOffsetTypeName,
		   compilerFarKeyword,
		   yyvsp[-1].string,
		   _ar);
	    (void) EnterSymbolInGlobal(yyvsp[-1].string, CHUNK_SYM,
 		                       SYM_DEFINED | SYM_EXTERN);
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 252:
#line 2622 "parse.y"
    {
	    yyerror("%s: cannot make extern, already defined in line %d of '%s'\n",
			yyvsp[-1].sym->name, yyvsp[-1].sym->lineNumber, yyvsp[-1].sym->realFileName);
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 253:
#line 2628 "parse.y"
    {
	    Output("extern %s %s %s%s;",
		   compilerOffsetTypeName,
		   compilerFarKeyword,
		   yyvsp[-1].string,
		   _ar);
	    (void) EnterSymbolInGlobal(yyvsp[-1].string, VIS_MONIKER_CHUNK_SYM,
 		                       SYM_DEFINED | SYM_EXTERN);
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 254:
#line 2639 "parse.y"
    {
	    yyerror("%s: cannot make extern, already defined in line %d of '%s'\n",
			yyvsp[-1].sym->name, yyvsp[-1].sym->lineNumber, yyvsp[-1].sym->realFileName);
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 255:
#line 2654 "parse.y"
    {
	    Output(" (optr)&%s", yyvsp[0].sym->name);
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 256:
#line 2659 "parse.y"
    {
	    Output(" (optr)&%s", yyvsp[0].sym->name);
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 257:
#line 2664 "parse.y"
    {
	    Output(" (optr)&%s", yyvsp[0].sym->name);
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 258:
#line 2680 "parse.y"
    {yyval.mit = MIT_SEND;;}
    break;

  case 259:
#line 2681 "parse.y"
    {yyval.mit = MIT_CALL;;}
    break;

  case 260:
#line 2682 "parse.y"
    {yyval.mit = MIT_RECORD;;}
    break;

  case 261:
#line 2687 "parse.y"
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
	;}
    break;

  case 262:
#line 2709 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 263:
#line 2713 "parse.y"
    {
	    SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
	;}
    break;

  case 264:
#line 2717 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 265:
#line 2721 "parse.y"
    {
	    Symbol *passMsg, *retMsg;
	    Parse_SetReturnAndPassMessage(yyvsp[-13].mit,yyvsp[-10].sym, yyvsp[-6].sym, MSG(yyvsp[-5].sm),&retMsg,&passMsg);

	    if(passMsg != NullSymbol){  /* if no parse error, continue */

		if (HAS_CHILDREN(yyvsp[-9].od)){
		    Output("CObjSendToChildren(oself, ");
		}
		GenerateComplexPrototype(yyvsp[-13].mit,passMsg,retMsg,yyvsp[-9].od);

		Output("CObjMessage)(");
		OutputSubst(yyvsp[-2].string, "@", "(optr)&");
		Output("%s 0x%x, %s, (Message) %s, %s)",
		       (strlen(yyvsp[-2].string)!=0) ? ", " : "",
		       (yyvsp[-11].num | RECORD_FLAG(yyvsp[-13].mit,yyvsp[-9].od) | CALL_FLAG(yyvsp[-13].mit)), /* flags */
		       DEST(yyvsp[-9].od), 	    	    	    	  /* dest */
		       MSG_OUT(yyvsp[-5].sm), 		    	          /* message */
		       GenerateComplexMPDString(passMsg,retMsg,   /* mpd */
						COMPLEX_PARAM_ENUM(yyvsp[-13].mit,yyvsp[-9].od)));

		if (HAS_CHILDREN(yyvsp[-9].od)){
		    Output(", %s)", OBJ_CHILDREN(yyvsp[-9].od));
		}
	    }
	    SWITCH_CONTEXT( LC_NONE);
	    scannerShouldRealignOutputAndInputAfterLC_STRING = 1;
	;}
    break;

  case 266:
#line 2751 "parse.y"
    {yyval.string = yyvsp[0].string;;}
    break;

  case 267:
#line 2752 "parse.y"
    {yyval.string = String_EnterZT("");;}
    break;

  case 268:
#line 2756 "parse.y"
    {yyval.sym = yyvsp[-1].sym;;}
    break;

  case 269:
#line 2757 "parse.y"
    {yyval.sym = NullSymbol;;}
    break;

  case 271:
#line 2768 "parse.y"
    { yyval.sym = NullSymbol; ;}
    break;

  case 272:
#line 2781 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE_CALLSUPER_OBJ_DEST);
	    scannerShouldRealignOutputAndInputAfterLC_STRING = 0;
	;}
    break;

  case 273:
#line 2786 "parse.y"
    {
	    scannerShouldRealignOutputAndInputAfterLC_STRING = 1;
        ;}
    break;

  case 274:
#line 2792 "parse.y"
    {yyval.num = 1;;}
    break;

  case 275:
#line 2794 "parse.y"
    {yyval.num = 0;;}
    break;

  case 276:
#line 2799 "parse.y"
    {
	    MessageParam *pp;

	    if(yyvsp[0].num){
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
		       yyvsp[0].num ? ";" : ""); /*XXX should go away */
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
		       yyvsp[0].num?";":"");  /* XXX should go away */
	    }

            if (compiler == COM_BORL) {
		Output("\n#pragma warn .sus\n");
		OutputLineNumber(yylineno,curFile->name);
	    }

	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 277:
#line 2852 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 278:
#line 2860 "parse.y"
    {
	    SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
	;}
    break;

  case 279:
#line 2864 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 280:
#line 2868 "parse.y"
    {
	    if(yyvsp[-8].sym && yyvsp[-5].sym){
		GeneratePrototype(MIT_CALLSUPER,yyvsp[-5].sym, yyvsp[-11].od);
		Output("CObjCallSuper)(");
		OutputSubst(yyvsp[-2].string, "@", "(optr)&");

		Output("%s &%s, %s, (Message) %d, %s)",
		       (strlen(yyvsp[-2].string)!=0) ? ", " : "",    /* separator */
		       yyvsp[-8].sym->name,	    	    	    /* class */
		       DEST(yyvsp[-11].od),  	    	    	    /* dest */
		       yyvsp[-5].sym->data.symMessage.messageNumber, /* message */
		       GenerateMPDString(yyvsp[-5].sym, PARAM_ENUM(MIT_CALLSUPER)));
	    }
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 281:
#line 2887 "parse.y"
    {
	    yyval.od = &objDest;

	    if (!strcmp(yyvsp[-1].string, "process")) {

		SET_OBJ_DEST(yyval.od,
			     "GeodeGetProcessHandle(), 0",
			     PROTO_TWO_PARAMS,"");

	    } else if (!strcmp(yyvsp[-1].string, "self")) {

		SET_OBJ_DEST(yyval.od, "oself",PROTO_ONE_PARAM,"");

	    } else if (!strcmp(yyvsp[-1].string, "application")) {

		SET_OBJ_DEST(yyval.od,
			     "GeodeGetAppObject(0)",
			     PROTO_ONE_PARAM,
			     "");

	    } else if (!strcmp(yyvsp[-1].string, "null")) {

		SET_OBJ_DEST(yyval.od, "(optr)0",PROTO_ONE_PARAM,"");

	    } else {
		Symbol *sym;
		/*
		 * If there is just one parameter and if that parameter is
		 * an object then we stick a "(optr) &" in front of it.
		 */
		sym = Symbol_Find(yyvsp[-1].string, TRUE);
		if ((sym != NullSymbol) && ((sym->type == OBJECT_SYM) ||
					    (sym->type == CLASS_SYM))) {
		    sprintf(DEST(yyval.od), "(optr) &%s", yyvsp[-1].string);
		} else {
		    CopySubst(DEST(yyval.od), yyvsp[-1].string, "@", "(optr)&");
		}
		DEST_TYPE(yyval.od) = PROTO_ONE_PARAM;
		*OBJ_CHILDREN(yyval.od)	='\0';
	    }

	;}
    break;

  case 282:
#line 2930 "parse.y"
    {
	    char buf1[1000];
	    char buf2[1000];

	    yyval.od = &objDest;

	    CopySubst(buf1, yyvsp[-3].string, "@", "(optr)&");
	    CopySubst(buf2, yyvsp[-1].string, "@", "(optr)&");

	    sprintf(DEST(yyval.od), "%s, %s", buf1, buf2);
	    DEST_TYPE(yyval.od) 	= PROTO_TWO_PARAMS;
	    *OBJ_CHILDREN(yyval.od)	='\0';
	;}
    break;

  case 283:
#line 2943 "parse.y"
    { SWITCH_CONTEXT( LC_STRING_COMMA);	;}
    break;

  case 284:
#line 2944 "parse.y"
    { SWITCH_CONTEXT( LC_STRING_COLON);	;}
    break;

  case 285:
#line 2946 "parse.y"
    {
	    yyval.od = &objDest;

	    sprintf(DEST(yyval.od),
		    "ObjLinkFindParent(oself, %s, %s)", yyvsp[-4].string, yyvsp[-1].string);

	    DEST_TYPE(yyval.od) 	= PROTO_ONE_PARAM;
	    *OBJ_CHILDREN(yyval.od)	='\0';

	    SWITCH_CONTEXT(LC_PARSE);

	;}
    break;

  case 286:
#line 2958 "parse.y"
    { SWITCH_CONTEXT( LC_STRING_COMMA);	;}
    break;

  case 287:
#line 2960 "parse.y"
    {SWITCH_CONTEXT( LC_STRING_COLON);;}
    break;

  case 288:
#line 2962 "parse.y"
    {
	    yyval.od = &objDest;

	    sprintf(DEST(yyval.od), "(optr)0");
	    sprintf(OBJ_CHILDREN(yyval.od), "%s, %s, %s",
		    	    	yyvsp[-6].string, yyvsp[-4].string, yyvsp[-1].string);
	    DEST_TYPE(yyval.od)	= PROTO_ONE_PARAM;

	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 289:
#line 2980 "parse.y"
    {
	    yyval.sm = &objMessage;

	    MSG(yyval.sm) = yyvsp[0].sym;
	    sprintf(MSG_OUT(yyval.sm), "%d", yyvsp[0].sym->data.symMessage.messageNumber);
	;}
    break;

  case 290:
#line 2987 "parse.y"
    {
	    SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
	;}
    break;

  case 291:
#line 2991 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 292:
#line 2995 "parse.y"
    {
	    yyval.sm = &objMessage;

	    MSG(yyval.sm) = NullSymbol;
	    strcpy(MSG_OUT(yyval.sm), yyvsp[-2].string);
	;}
    break;

  case 293:
#line 3002 "parse.y"
    {
            char *cp;
	    for(cp = yyvsp[0].string; *cp; cp++){
		if(islower(*cp))
		    break;
	    }
	    /* a little hueristic: if the thing is all upper and an ident */
	    /* it is probably not kosher */
	    if(!*cp){
		yywarning("Perhaps you misspelled your message name %s "
			  "(or maybe it is a C variable of type Message)",
			  yyvsp[0].string);
	    }
    	    yyval.sm = &objMessage;
	    MSG(yyval.sm) = NullSymbol;
	    strcpy(MSG_OUT(yyval.sm),yyvsp[0].string);
	;}
    break;

  case 294:
#line 3022 "parse.y"
    { yyval.num = yyvsp[-1].num | yyvsp[0].num; ;}
    break;

  case 295:
#line 3023 "parse.y"
    { yyval.num = 0; ;}
    break;

  case 296:
#line 3028 "parse.y"
    {yyval.num = MF_FORCE_QUEUE; ;}
    break;

  case 297:
#line 3029 "parse.y"
    {yyval.num = MF_RETURN_ERROR; ;}
    break;

  case 298:
#line 3030 "parse.y"
    {yyval.num = MF_CHECK_DUPLICATE; ;}
    break;

  case 299:
#line 3031 "parse.y"
    {yyval.num = MF_CHECK_LAST_ONLY; ;}
    break;

  case 300:
#line 3032 "parse.y"
    {yyval.num = MF_REPLACE; ;}
    break;

  case 301:
#line 3033 "parse.y"
    {yyval.num = MF_INSERT_AT_FRONT; ;}
    break;

  case 302:
#line 3034 "parse.y"
    {yyval.num = MF_CAN_DISCARD_IF_DESPERATE; ;}
    break;

  case 303:
#line 3035 "parse.y"
    {yyval.num = MF_RECORD; ;}
    break;

  case 304:
#line 3044 "parse.y"
    {
	    yyval.sym = (Symbol *)NULL;
	;}
    break;

  case 305:
#line 3049 "parse.y"
    {
	    yyval.sym = yyvsp[-1].sym;
	;}
    break;

  case 306:
#line 3055 "parse.y"
    {
            SWITCH_CONTEXT( LC_PARSE_NO_LOOKUP);
        ;}
    break;

  case 307:
#line 3059 "parse.y"
    {
	    MsgInvocType mit;

	    if (yyvsp[-2].sym!= NullSymbol){  /* is this a dispatch call? */
		mit = MIT_DISPATCHCALL;

		if ((yyvsp[-2].sym->data.symMessage.mpd & MPD_RETURN_TYPE)
		    == (MRT_MULTIPLE << MPD_RETURN_TYPE_OFFSET)) {
		    yyerror("cannot cast to message %s, it has multiple"
			    " return values",yyvsp[-2].sym->name);
		}
	    }else{
		mit = MIT_DISPATCH;
	    }
	    Output("(");
	    GenerateReturnType(mit, yyvsp[-2].sym, FALSE);
	    Output(")CMessageDispatch(%s, 0x%x, %s)",
		   yyvsp[0].string,                                 /* Message handle */
		   yyvsp[-2].sym?MF_CALL:0,                       /* flags */
		   GenerateMPDString(NullSymbol,PARAM_ENUM(mit)));  /* mpd   */

	    SWITCH_CONTEXT( LC_NONE);
        ;}
    break;

  case 308:
#line 3085 "parse.y"
    {
				  SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
				  yyval.sym = NullSymbol;
			      	;}
    break;

  case 309:
#line 3091 "parse.y"
    { yyval.sym = yyvsp[-1].sym;
				  SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
			      	;}
    break;

  case 310:
#line 3098 "parse.y"
    {SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);;}
    break;

  case 311:
#line 3100 "parse.y"
    {
	    MsgInvocType mit;

	    if (yyvsp[-3].sym!= NullSymbol){  /* is this a dispatch call? */
		mit = MIT_DISPATCHCALL;

		if ((yyvsp[-3].sym->data.symMessage.mpd & MPD_RETURN_TYPE)
		    == (MRT_MULTIPLE << MPD_RETURN_TYPE_OFFSET)) {
		    yyerror("cannot cast to message %s, it has multiple"
			    " return values",yyvsp[-3].sym->name);
		}
	    }else{
		mit = MIT_DISPATCH;
	    }
	    Output("(");
	    GenerateReturnType(mit, yyvsp[-3].sym, FALSE);
	    Output(")CMessageDispatch(%s, 0x%x, %s)",
		   yyvsp[-2].string,                                 /* Message handle */
		   yyvsp[-3].sym?MF_CALL:0,                       /* flags */
		   GenerateMPDString(NullSymbol,PARAM_ENUM(mit)));  /* mpd   */

	    SWITCH_CONTEXT( LC_NONE);
        ;}
    break;

  case 312:
#line 3129 "parse.y"
    { compiler = COM_HIGHC; SWITCH_CONTEXT( LC_NONE); ;}
    break;

  case 313:
#line 3130 "parse.y"
    { compiler = COM_MSC; SWITCH_CONTEXT( LC_NONE); ;}
    break;

  case 314:
#line 3139 "parse.y"
    {
	    /*
	     * If we're in the middle of defining a resource, bitch
	     */
	    if (curResource != NullSymbol) {
		yyerror("resource %s declared within resource %s",
			    yyvsp[0].string, curResource->name);
	    }
	    /*
	     * Enter the identifier as a resource
	     */
	    curResource = Symbol_Enter(yyvsp[0].string, RESOURCE_SYM, SYM_DEFINED);
	;}
    break;

  case 315:
#line 3153 "parse.y"
    {
	    curResource->flags |= yyvsp[-1].num;
	    curResource->data.symResource.nextResource = resourceList;
	    resourceList = curResource;

	    if (curResource->flags & SYM_OBJECT_BLOCK) {
		CompilerStartSegment("__HANDLES_", curResource->name);
		Output("extern %s %s _%s_Flags%s;",
		       compilerOffsetTypeName,
		       compilerFarKeyword,
		       curResource->name,
		       _ar);
		CompilerEndSegment("__HANDLES_", curResource->name);
	    }

	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 316:
#line 3172 "parse.y"
    {
	    /*
	     * If we're in the middle of defining a resource, bitch
	     */
	    if (curResource != NullSymbol) {
		yyerror("resource %s declared within resource %s",
			    yyvsp[0].sym, curResource->name);
	    }
	    curResource = yyvsp[0].sym;

	;}
    break;

  case 317:
#line 3184 "parse.y"
    {
	    if((curResource->flags &(SYM_NOT_DETACHABLE|SYM_OBJECT_BLOCK) )!= yyvsp[-1].num){
	      yyerror("resource %s declared with different flags\n",curResource->name);
	    }
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 318:
#line 3194 "parse.y"
    {
	    yyval.num = SYM_NOT_DETACHABLE | SYM_OBJECT_BLOCK;
	;}
    break;

  case 319:
#line 3198 "parse.y"
    {
	    yyval.num = 0;
	;}
    break;

  case 320:
#line 3202 "parse.y"
    {
	    yyval.num = SYM_RESOURCE_NOT_LMEM;
	;}
    break;

  case 321:
#line 3205 "parse.y"
    { yyval.num = SYM_OBJECT_BLOCK; ;}
    break;

  case 322:
#line 3214 "parse.y"
    {
            Scan_WarnForForwardChunk(yyvsp[0].sym->name);

	    if (curResource == NullSymbol) {
		yyerror("@resourceOutput must appear within @start, @end");
	    } else {
		curResource->data.symResource.resourceOutput = yyvsp[0].sym;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 323:
#line 3232 "parse.y"
    {
	    if (curResource != yyvsp[0].sym) {
	      yyerror("mismatched @start (%s) and @end (%s)",
		      curResource?curResource->name:"none", yyvsp[0].sym->name);
	    }

	    curResource = NullSymbol;
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 324:
#line 3249 "parse.y"
    {
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	;}
    break;

  case 325:
#line 3253 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 326:
#line 3257 "parse.y"
    {
	    if (curResource == NullSymbol) {
		yyerror("@header outside of resource definition");
	    } else {
		curResource->data.symResource.header_ctype = yyvsp[-5].string;
		curResource->data.symResource.header_initializer = yyvsp[-2].string;
	    }
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 327:
#line 3273 "parse.y"
    {
	    SWITCH_CONTEXT( LC_TYPE_STRING_MATCH_PARENS);
	    parse_ScanningAChunk = TRUE;
	;}
    break;

  case 328:
#line 3278 "parse.y"
    {
            parse_ScanningAChunk = FALSE;
	    realSymbolLineNumber = yylineno;
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	;}
    break;

  case 329:
#line 3284 "parse.y"
    {
	    Symbol *chunk;

	    if (curResource == NullSymbol) {
		yyerror("chunk %s outside of any resource", TDS_IDENT(yyvsp[-3].tdecl));
	    } else {
		chunk = Symbol_EnterWithLineNumber(TDS_IDENT(yyvsp[-3].tdecl),
						   CHUNK_SYM,
						   SYM_DEFINED,
						   realSymbolLineNumber);
/*XXX check here if(! chunk & SYM_MULTIPLY_DEFINED){  */
		AddChunkToCurResourceAndOutputExtern(chunk);
		chunk->data.symChunk.data = yyvsp[0].string;
		chunk->data.symChunk.ctype = TDS_CTYPE(yyvsp[-3].tdecl);
		chunk->data.symChunk.typeSuffix = TDS_TYPESUF(yyvsp[-3].tdecl);

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
	;}
    break;

  case 330:
#line 3315 "parse.y"
    {
	    SWITCH_CONTEXT( LC_NONE);
	    LocalizationCheck();
	;}
    break;

  case 331:
#line 3320 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE_NO_LOOKUP);
	;}
    break;

  case 332:
#line 3324 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 333:
#line 3328 "parse.y"
    {
	    realSymbolLineNumber = yylineno;
	;}
    break;

  case 334:
#line 3332 "parse.y"
    {
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	;}
    break;

  case 335:
#line 3335 "parse.y"
    {              /* 10 */
	    Symbol *chunk;

	    if (curResource == NullSymbol) {
		yyerror("chunk %s outside of any resource", yyvsp[-4].string);
	    } else {
	    	chunk = Symbol_EnterWithLineNumber(yyvsp[-4].string, CHUNK_SYM,
				     SYM_DEFINED,realSymbolLineNumber);
		AddChunkToCurResourceAndOutputExtern(chunk);
	    	chunk->data.symChunk.data = yyvsp[0].string;
	    	chunk->data.symChunk.ctype = yyvsp[-7].string;
		chunk->data.symChunk.headerType = caHeaderType;
		chunk->data.symChunk.headerData = caHeaderData;
		chunk->flags |= yyvsp[-9].num | SYM_IS_CHUNK_ARRAY;
		LOC_HINT(CHUNK_LOC(chunk)) = CDT_unknown;
	    }

	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 336:
#line 3355 "parse.y"
    {
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 337:
#line 3359 "parse.y"
    { SWITCH_CONTEXT( LC_PARSE_NO_LOOKUP); ;}
    break;

  case 338:
#line 3361 "parse.y"
    {
	    /*
	     * Record line number of identifier for later entering
	     */
	    yyval.num = yylineno; /* $4 */
	;}
    break;

  case 339:
#line 3368 "parse.y"
    {
	    /*
	     * Ask GStrings rule to include open/close curly in the string.
	     */
	    yyval.num = TRUE;
	;}
    break;

  case 340:
#line 3375 "parse.y"
    {
	    Symbol  *chunk;

	    if (curResource == NullSymbol) {
		yyerror("chunk %s outside of any resource", yyvsp[-4].string);
	    } else {
		chunk = Symbol_EnterWithLineNumber(yyvsp[-4].string, CHUNK_SYM, SYM_DEFINED,
						   yyvsp[-3].num);
		AddChunkToCurResourceAndOutputExtern(chunk);
		chunk->data.symChunk.data = yyvsp[0].string;
		chunk->data.symChunk.ctype = "byte";
		chunk->data.symChunk.typeSuffix = "[]";
		LOC_HINT(CHUNK_LOC(chunk)) = CDT_GString;
	    }
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 341:
#line 3392 "parse.y"
    {
	    SWITCH_CONTEXT( LC_NONE);
	    LocalizationCheck();
	;}
    break;

  case 342:
#line 3399 "parse.y"
    { yyval.num = 0; ;}
    break;

  case 343:
#line 3400 "parse.y"
    { yyval.num = SYM_IS_ELEMENT_ARRAY; ;}
    break;

  case 344:
#line 3405 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE_NO_LOOKUP);
	;}
    break;

  case 345:
#line 3409 "parse.y"
    {
	    SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
	;}
    break;

  case 346:
#line 3413 "parse.y"
    {

	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 347:
#line 3417 "parse.y"
    {
	    caHeaderType = yyvsp[-6].string;
	    caHeaderData = yyvsp[-3].string;
	;}
    break;

  case 348:
#line 3422 "parse.y"
    {
	    caHeaderType = caHeaderData = String_EnterZT("");
	;}
    break;

  case 349:
#line 3433 "parse.y"
    {
	    Symbol *class, *super, *bottomClass;

	    (void) EnterSymbolInGlobal(yyvsp[-3].sym->name, OBJECT_SYM, SYM_DEFINED);
	    yyvsp[-3].sym->flags |= SYM_IS_OBJECT | yyvsp[-1].num;
	    curObject = yyvsp[-3].sym;
	    yyvsp[-3].sym->data.symObject.class = yyvsp[-4].sym;
	    if (yyvsp[-4].sym){
		Symbol_PushScope(yyvsp[-4].sym->data.symClass.localSymbols);
	    }
	    /*
	     * Deal with default building of things, going all the way up
	     * the class tree.. XXX: doesn't handle overriding default super
	     * more than one level up.
	     */
	    for (class = bottomClass = yyvsp[-4].sym; class != NullSymbol; class = super) {
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
	;}
    break;

  case 350:
#line 3468 "parse.y"
    {
	    if (curResource == NullSymbol) {
		yyerror("object %s outside of any resource", yyvsp[-6].sym);
	    } else if (!(curObject->flags & SYM_MULTIPLY_DEFINED)) {
		/*Symbol *iptr;*/

		AddChunkToCurResourceAndOutputExtern(yyvsp[-6].sym);

	    }
	    curObject = NullSymbol;
	    SWITCH_CONTEXT( LC_NONE);
	    if(yyvsp[-7].sym){
		Symbol_PopScopeTo(yyvsp[-7].sym->data.symClass.localSymbols);
	    }
	;}
    break;

  case 351:
#line 3486 "parse.y"
    { yyval.num = SYM_IGNORE_DIRTY; ;}
    break;

  case 352:
#line 3487 "parse.y"
    { yyval.num = 0; ;}
    break;

  case 355:
#line 3494 "parse.y"
    {
	    yyerrok;
	;}
    break;

  case 356:
#line 3498 "parse.y"
    {
	    Scan_Unput('}');
	    yyerrok;
	;}
    break;

  case 357:
#line 3505 "parse.y"
    {
	    if ((yychar == IDENT) ||
		(yychar > FIRSTSYM && yychar < LASTSYM))
	    {
		yyerror("%s is not a valid instance variable or vardata element for this object",
			(yychar == IDENT) ? yyvsp[0].string : yyvsp[0].sym->name);
	    }
	;}
    break;

  case 358:
#line 3515 "parse.y"
    {SWITCH_CONTEXT( LC_STRING_CLOSE_BRACE);;}
    break;

  case 359:
#line 3516 "parse.y"
    {SWITCH_CONTEXT( LC_PARSE); ;}
    break;

  case 360:
#line 3517 "parse.y"
    {yyval.string = yyvsp[-2].string;;}
    break;

  case 361:
#line 3518 "parse.y"
    {yyval.string = NULL;;}
    break;

  case 362:
#line 3523 "parse.y"
    {
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	;}
    break;

  case 363:
#line 3527 "parse.y"
    {
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = yyvsp[-3].sym->name;
	    inst->value = yyvsp[0].string;

	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 365:
#line 3538 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 366:
#line 3542 "parse.y"
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
				    yyvsp[0].sym->data.symClass.localSymbols);
	    } else {
		Symbol_PushScope(yyvsp[0].sym->data.symClass.localSymbols);
	    }

	    inst = MakeInstanceValue(curObject);
 	    inst->name = yyvsp[-3].sym->name;
	    inst->value = yyvsp[0].sym->name;

	;}
    break;

  case 368:
#line 3569 "parse.y"
    {
	    InstanceValue *inst;

 inst = MakeInstanceValue(curObject);
 	    inst->name = yyvsp[-3].sym->name;
	    inst->value = yyvsp[-1].string;
	    inst->data.instReg.flags |= INST_ADD_OPTR;
	;}
    break;

  case 369:
#line 3578 "parse.y"
    {
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = yyvsp[-3].sym->name;
	    inst->value = yyvsp[-1].sym->name;
	    inst->data.instReg.flags |= INST_ADD_OPTR;
	;}
    break;

  case 370:
#line 3587 "parse.y"
    {
	    SWITCH_CONTEXT( LC_STRING_RIGHT_PAREN);
	;}
    break;

  case 371:
#line 3591 "parse.y"
    {
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = yyvsp[-4].sym->name;
	    inst->value = String_EnterZT(yyvsp[0].string);
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 373:
#line 3601 "parse.y"
    {
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = yyvsp[-3].sym->name;
	    inst->value = yyvsp[-1].string;
	;}
    break;

  case 374:
#line 3609 "parse.y"
    {
	    InstanceValue *inst;
	    char buf[200];
	    Symbol *chunk;

	    if (curResource == NullSymbol) {
		yyerror("object %s outside of any resource", curObject);
	    } else {
		sprintf(buf, "_%s_%s", yyvsp[-3].sym->name, curObject->name);
		chunk = Symbol_Enter(String_EnterZT(buf),
				     CHUNK_SYM, SYM_DEFINED);
		chunk->flags |= SYM_CHUNK_NEEDS_QUOTES;
		AddChunkToCurResourceAndOutputExtern(chunk);
		chunk->data.symChunk.data = yyvsp[-1].string;
		chunk->data.symChunk.ctype = curStringType;
		chunk->data.symChunk.typeSuffix = String_EnterZT("[]");
		LOC_HINT(CHUNK_LOC(chunk)) = CDT_text;
		inst = MakeInstanceValue(curObject);
		inst->name = yyvsp[-3].sym->name;
		inst->value = chunk->name;
	    }
	    LocalizationCheck();
	;}
    break;

  case 375:
#line 3633 "parse.y"
    {
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = yyvsp[-3].sym->name;
	    inst->value = yyvsp[-1].sym->name;
	;}
    break;

  case 376:
#line 3641 "parse.y"
    {
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = yyvsp[-3].sym->name;
	    inst->value = yyvsp[-1].sym->name;
	;}
    break;

  case 377:
#line 3649 "parse.y"
    {
	    Symbol_PushScope(visMonikerScope);
	    curVisMonField = yyvsp[0].sym;
	;}
    break;

  case 379:
#line 3656 "parse.y"
    {
	    if (yyvsp[-1].sym->data.symVardata.ctype != String_EnterZT("void")) {
		yyerror("Initializer cannot be given for void vardata %s",
			yyvsp[-1].sym->name);
	    }
	    AddVarData(yyvsp[-1].sym, String_EnterZT(""),NULL);
	;}
    break;

  case 380:
#line 3664 "parse.y"
    {
	    if (yyvsp[-2].sym->data.symVardata.ctype == String_EnterZT("void")) {
		yyerror("No initializer given for vardata %s (type %s)",
			yyvsp[-2].sym->name, yyvsp[-2].sym->data.symVardata.ctype);
	    }
	    SWITCH_CONTEXT( LC_STRING_SEMI_COLON);
	;}
    break;

  case 381:
#line 3672 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 382:
#line 3676 "parse.y"
    {
	    AddVarData(yyvsp[-6].sym, yyvsp[-2].string,yyvsp[-5].string);
	;}
    break;

  case 383:
#line 3680 "parse.y"
    {
	    Symbol *gcnList;
	    char buf[1000];

	    /* define symbol for this particular gcn list */
	    sprintf(buf, "_%s_gcnL_%s_%s", curObject->name, yyvsp[-5].string, yyvsp[-3].string);
	    gcnList = Symbol_Enter(String_EnterZT(buf),
						GCN_LIST_SYM, SYM_DEFINED);
	    gcnList->flags |= SYM_DEFINED;
	    gcnList->data.symGCNList.firstItem = yyvsp[0].sle;
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
	    gcnList->data.symGCNList.manufID = yyvsp[-5].string;
	    gcnList->data.symGCNList.type = yyvsp[-3].string;
	;}
    break;

  case 384:
#line 3739 "parse.y"
    {
	    curLastChild = NullInstanceValue;
	    curLinkPart = yyvsp[-1].sym->data.symComposite.linkPart;
	;}
    break;

  case 385:
#line 3744 "parse.y"
    {
	    if (curLastChild != NullInstanceValue) {
		InstanceValue *inst;

	    	inst = MakeInstanceValue(curObject);
		inst->name = yyvsp[-4].sym->name;
		inst->data.instLink.link = curFirstChild;
		curLastChild->data.instLink.isParentLink = TRUE;
		curLastChild->data.instLink.link = curObject;
		if (curLinkPart->flags & SYM_IS_KBD_PATH) {
		    curLastChildObj->data.symObject.kbdPathParent = curObject;
		}
	    }
	;}
    break;

  case 386:
#line 3760 "parse.y"
    {
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = yyvsp[-6].sym->name;
	    inst->data.instKbdAccelerator.specificUI = yyvsp[-3].num;
	    inst->data.instKbdAccelerator.flags = yyvsp[-2].num;
	    inst->data.instKbdAccelerator.key = yyvsp[-1].num;
	    curObject->flags |= SYM_HAS_KBD_ACCEL;
	    (void) Symbol_PopScope();
	;}
    break;

  case 387:
#line 3772 "parse.y"
    {
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = yyvsp[-3].sym->name;
	    inst->value = yyvsp[-1].sym->name;
	    inst->data.instLink.link = yyvsp[-1].sym;
	    inst->data.instLink.isParentLink = TRUE;
	;}
    break;

  case 389:
#line 3788 "parse.y"
    {yyval.string = yyvsp[0].string; curStringType = defStringType;;}
    break;

  case 390:
#line 3789 "parse.y"
    {yyval.string = yyvsp[0].string; curStringType = asciiStringType;;}
    break;

  case 391:
#line 3790 "parse.y"
    {yyval.string = yyvsp[0].string; curStringType = defStringType;;}
    break;

  case 392:
#line 3791 "parse.y"
    {yyval.string = yyvsp[0].string; curStringType = lStringType;;}
    break;

  case 393:
#line 3792 "parse.y"
    {yyval.string = yyvsp[0].string; curStringType = sjisStringType;;}
    break;

  case 394:
#line 3797 "parse.y"
    {
	    localizationRequired = FALSE;
	    if (chunkToLocalize == NULL) {
		yyerror("You have entered no chunk that could need localizing\n");
	    } else if(!CHUNK_LOC(chunkToLocalize)){
		yyerror("This chunk (%s) is not localizable\n",
			chunkToLocalize->name);
	    }else{
		LOC_NAME(CHUNK_LOC(chunkToLocalize)) = chunkToLocalize->name;
		LOC_INST(CHUNK_LOC(chunkToLocalize)) = yyvsp[-3].string;
		LOC_MIN(CHUNK_LOC(chunkToLocalize))=
		    LOC_MAX(CHUNK_LOC(chunkToLocalize))= yyvsp[-2].num;
	    }

	;}
    break;

  case 395:
#line 3813 "parse.y"
    {
	    localizationRequired = FALSE;
	    if (chunkToLocalize == NULL) {
		yyerror("You have entered no chunk that could need localizing\n");
	    } else if(!CHUNK_LOC(chunkToLocalize)){
		yyerror("This chunk (%s) is not localizable\n",
			chunkToLocalize->name);
	    }else{
		LOC_NAME(CHUNK_LOC(chunkToLocalize)) = chunkToLocalize->name;
		LOC_INST(CHUNK_LOC(chunkToLocalize)) = yyvsp[-5].string;
		LOC_MIN(CHUNK_LOC(chunkToLocalize))  = yyvsp[-4].num;
		LOC_MAX(CHUNK_LOC(chunkToLocalize))  = yyvsp[-2].num;
		if(yyvsp[-4].num > yyvsp[-2].num){
		    yyerror("Min size is greater than Max size\n");
		}else if (yyvsp[-4].num == yyvsp[-2].num){
		    yywarning("Min size is equal to Max size.");
		    yywarning("Perhaps you want a different syntax");
		}
	    }
	;}
    break;

  case 396:
#line 3834 "parse.y"
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
	;}
    break;

  case 397:
#line 3849 "parse.y"
    {
	    localizationRequired = FALSE;
	    if (chunkToLocalize == NULL) {
		yyerror("You have entered no chunk that could need localizing\n");
	    } else if(!CHUNK_LOC(chunkToLocalize)){
		yyerror("This chunk (%s) is not localizable\n",
			chunkToLocalize->name);
	    }else{
		LOC_NAME(CHUNK_LOC(chunkToLocalize)) = chunkToLocalize->name;
		LOC_INST(CHUNK_LOC(chunkToLocalize)) = yyvsp[0].string;
		LOC_MIN(CHUNK_LOC(chunkToLocalize))  = 0;
		LOC_MAX(CHUNK_LOC(chunkToLocalize))  = 0;
	    }
	;}
    break;

  case 398:
#line 3866 "parse.y"
    {yyval.string = yyvsp[-2].string;;}
    break;

  case 399:
#line 3867 "parse.y"
    {yyval.string = yyvsp[-1].string;;}
    break;

  case 401:
#line 3874 "parse.y"
    {
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = curVisMonField->name;
	    inst->value = yyvsp[0].sym->name;
	    Symbol_PopScope();
	;}
    break;

  case 402:
#line 3883 "parse.y"
    {
	    char buf[200];

	    sprintf(buf, "_%s_%s", curVisMonField->name, curObject->name);
	    curVisMoniker = Symbol_Enter(String_EnterZT(buf),
					VIS_MONIKER_CHUNK_SYM, SYM_DEFINED);

	;}
    break;

  case 403:
#line 3892 "parse.y"
    {
	    InstanceValue *inst;

	    inst = MakeInstanceValue(curObject);
 	    inst->name = curVisMonField->name;
	    inst->value = curVisMoniker->name;

	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 404:
#line 3903 "parse.y"
    { yyval.sle = yyvsp[-1].sle; ;}
    break;

  case 405:
#line 3904 "parse.y"
    { yyval.sle = NullSymbolListEntry; ;}
    break;

  case 406:
#line 3909 "parse.y"
    {
	    SymbolListEntry **sle;

	    yyval.sle = yyvsp[-2].sle;
	    if (yyval.sle == NullSymbolListEntry) {
		yyval.sle = yyvsp[0].sle;
	    } else {
		for (sle = &(yyval.sle->next); *sle != NullSymbolListEntry;
		    	    	    	    	sle = &((*sle)->next));
		*sle = yyvsp[0].sle;
	    }
	;}
    break;

  case 408:
#line 3926 "parse.y"
    {
            Scan_WarnForForwardChunk(yyvsp[0].sym->name);
	    yyval.sle = (SymbolListEntry *) zmalloc(sizeof(SymbolListEntry));
	    yyval.sle->entry = yyvsp[0].sym;
	;}
    break;

  case 409:
#line 3940 "parse.y"
    {
	    Symbol_PushScope(kbdAcceleratorScope);
	;}
    break;

  case 410:
#line 3947 "parse.y"
    {
	    yyval.num = yyvsp[0].ch;
	    if (isupper(yyval.num)) {
		yyval.num = tolower(yyval.num);
	    }
	    if (isalpha(yyval.num)) {
		yyval.num = (KEY_ALPHA << 16) | yyval.num;
	    } else if (isdigit(yyval.num)) {
		yyval.num = (KEY_DIGIT << 16) | yyval.num;
	    } else if (!yyval.num) {
		yyerror("keyboard accelerator must be alpha-numeric");
		yyval.num = (KEY_ALPHA << 16) | 'a';
	    } else {
		yyval.num = (KEY_PUNCT << 16) | yyval.num;
	    }
	;}
    break;

  case 411:
#line 3965 "parse.y"
    {
	    yyval.num = yyvsp[0].sym->data.symSpecial.value;
	;}
    break;

  case 412:
#line 3970 "parse.y"
    { yyval.num = 1; ;}
    break;

  case 413:
#line 3971 "parse.y"
    { yyval.num = specificUI; ;}
    break;

  case 414:
#line 3975 "parse.y"
    {
	    yyval.num = yyvsp[-1].num | yyvsp[0].sym->data.symSpecial.value;
	;}
    break;

  case 415:
#line 3978 "parse.y"
    { yyval.num = 0; ;}
    break;

  case 420:
#line 3996 "parse.y"
    {
	    InstanceValue *inst;

            Scan_WarnForForwardChunk(yyvsp[0].sym->name);

	    if(yyvsp[0].sym == curObject){
		yyerror("The parent %s is its own child. This will "
			"fail at runtime.",yyvsp[0].sym->name);
	    }

	    yyvsp[0].sym->flags |= SYM_CANNOT_BE_EXTERN;
	    if (curLastChild != NullInstanceValue) {
		curLastChild->data.instLink.link = yyvsp[0].sym;
	    } else {
		curFirstChild = yyvsp[0].sym;
	    }
	    inst = MakeInstanceValue(yyvsp[0].sym);
	    inst->name = curLinkPart->name;
	    curLastChild = inst;
	    curLastChildObj = yyvsp[0].sym;
	;}
    break;

  case 422:
#line 4025 "parse.y"
    {
	    Symbol_Enter(yyvsp[-1].sym->name, VIS_MONIKER_CHUNK_SYM, SYM_DEFINED);
	    Symbol_PushScope(visMonikerScope);
	    curVisMoniker = yyvsp[-1].sym;
	;}
    break;

  case 423:
#line 4031 "parse.y"
    {
	    SWITCH_CONTEXT( LC_NONE);
	;}
    break;

  case 426:
#line 4045 "parse.y"
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
	;}
    break;

  case 427:
#line 4057 "parse.y"
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
	;}
    break;

  case 428:
#line 4071 "parse.y"
    {
	    Symbol_PopScope();
	;}
    break;

  case 429:
#line 4078 "parse.y"
    {
	    /* not localizable, so remove the data */
	    REMOVE_LOCALIZATION_DATA(curVisMoniker);
	    curVisMoniker->flags |= SYM_LIST_MONIKER;
	    curVisMoniker->data.symVisMoniker.list = yyvsp[-1].sle;
	;}
    break;

  case 430:
#line 4084 "parse.y"
    {
	    LOC_HINT(CHUNK_LOC(curVisMoniker)) = CDT_visMoniker;
	;}
    break;

  case 433:
#line 4093 "parse.y"
    {
	  curVisMoniker->flags |= SYM_GSTRING_MONIKER;
	  if (!haveVMStyle) {
	      curVisMoniker->data.symVisMoniker.vmType.style = VMS_ICON;
	  }
	;}
    break;

  case 434:
#line 4100 "parse.y"
    {
	  curVisMoniker->flags |= SYM_GSTRING_MONIKER;
	  if (!haveVMStyle) {
	      curVisMoniker->data.symVisMoniker.vmType.style = VMS_ICON;
	  }
	;}
    break;

  case 435:
#line 4110 "parse.y"
    {
 	    curVisMoniker->data.symVisMoniker.navChar = yyvsp[-2].ch;
 	    curVisMoniker->data.symVisMoniker.navType = NT_CHAR;
 	    curVisMoniker->data.symVisMoniker.vmText = yyvsp[0].string;
 	    curVisMoniker->data.symVisMoniker.ctype = curStringType;
	;}
    break;

  case 436:
#line 4117 "parse.y"
    {
 	    curVisMoniker->data.symVisMoniker.navConst = yyvsp[-2].num;
 	    curVisMoniker->data.symVisMoniker.navType = NT_CONST;
 	    curVisMoniker->data.symVisMoniker.vmText = yyvsp[0].string;
 	    curVisMoniker->data.symVisMoniker.ctype = curStringType;
	;}
    break;

  case 437:
#line 4124 "parse.y"
    {
 	    curVisMoniker->data.symVisMoniker.navString = yyvsp[-2].string;
 	    curVisMoniker->data.symVisMoniker.navType = NT_STRING;
 	    curVisMoniker->data.symVisMoniker.vmText = yyvsp[0].string;
 	    curVisMoniker->data.symVisMoniker.ctype = curStringType;
	;}
    break;

  case 438:
#line 4131 "parse.y"
    {
 	    curVisMoniker->data.symVisMoniker.navConst = 0xff;
 	    curVisMoniker->data.symVisMoniker.navType = NT_CONST;
 	    curVisMoniker->data.symVisMoniker.vmText = yyvsp[0].string;
 	    curVisMoniker->data.symVisMoniker.ctype = curStringType;
	;}
    break;

  case 441:
#line 4153 "parse.y"
    {
	    /* setup up vis moniker in preparation, in case of error */
	    curVisMoniker->data.symVisMoniker.startLine = yylineno;
	    curVisMoniker->data.symVisMoniker.vmText = "";
	    /*
	     * Don't include open/close curly in the string.
	     */
	    yyval.num = FALSE;
	;}
    break;

  case 442:
#line 4163 "parse.y"
    {
	    curVisMoniker->data.symVisMoniker.vmText = yyvsp[0].string;
	;}
    break;

  case 443:
#line 4169 "parse.y"
    {
	    INIT_DYNAMIC_BUFFER(gstringBuf,GS_BUF);
	    /*
	     * Add open-curly if calling rule requested it
	     */
	    if (yyvsp[-1].num) {
		ADD_CHAR_TO_DYNAMIC_BUFFER('{',gstringBuf);
	    }
	    SWITCH_CONTEXT( LC_CLOSE_CURLY_OR_STRING);

	;}
    break;

  case 444:
#line 4182 "parse.y"
    {
	    SWITCH_CONTEXT( LC_PARSE);
	;}
    break;

  case 445:
#line 4186 "parse.y"
    {
	    /*
	     * Add close-curly if calling rule requested it.
	     */
	    if (yyvsp[-5].num) {
		ADD_CHAR_TO_DYNAMIC_BUFFER('}',gstringBuf);
	    }
	    ADD_CHAR_TO_DYNAMIC_BUFFER('\0',gstringBuf);
	    yyval.string = DB_STR(gstringBuf);
	;}
    break;

  case 448:
#line 4202 "parse.y"
    {AddStringToCurrentGstringBuffer(yyvsp[0].string); ;}
    break;

  case 449:
#line 4203 "parse.y"
    {AddStringCharsToCurrentGstringBuffer(yyvsp[0].string); ;}
    break;

  case 450:
#line 4205 "parse.y"
    {
	    yyerror("invalid graphics-string element");
	    yyerrok;
	;}
    break;

  case 451:
#line 4214 "parse.y"
    {
	    curVisMoniker->data.symVisMoniker.vmType.aspectRatio =
		    	    	yyvsp[-1].sym->data.symSpecial.value;
	;}
    break;

  case 452:
#line 4219 "parse.y"
    {
 	    curVisMoniker->data.symVisMoniker.vmType.style =
		    	    	yyvsp[-1].sym->data.symSpecial.value;
	    haveVMStyle = TRUE;
	;}
    break;

  case 453:
#line 4225 "parse.y"
    {
 	    curVisMoniker->data.symVisMoniker.vmType.gsColor =
		    	    	yyvsp[-1].sym->data.symSpecial.value;
	;}
    break;

  case 454:
#line 4230 "parse.y"
    {
 	    curVisMoniker->data.symVisMoniker.vmType.gsSize =
		    	    	yyvsp[-1].sym->data.symSpecial.value;
	;}
    break;

  case 455:
#line 4235 "parse.y"
    {
 	    curVisMoniker->data.symVisMoniker.vmXSize = yyvsp[-3].num;
 	    curVisMoniker->data.symVisMoniker.vmYSize = yyvsp[-1].num;
	;}
    break;

  case 456:
#line 4240 "parse.y"
    {
	    yyerrok;
	;}
    break;

  case 457:
#line 4244 "parse.y"
    {
	    Scan_Unput('}');
	    yyerrok;
	;}
    break;

  case 458:
#line 4252 "parse.y"
    {
	    SymbolListEntry **sle;

	    yyval.sle = yyvsp[-2].sle;
	    if (yyval.sle == NullSymbolListEntry) {
		yyval.sle = yyvsp[0].sle;
	    } else {
		for (sle = &(yyval.sle->next); *sle != NullSymbolListEntry;
		    	    	    	    	sle = &((*sle)->next));
		*sle = yyvsp[0].sle;
	    }
	;}
    break;

  case 460:
#line 4269 "parse.y"
    {
            Scan_WarnForForwardChunk(yyvsp[0].sym->name);
	    yyval.sle = (SymbolListEntry *) zmalloc(sizeof(SymbolListEntry));
	    yyval.sle->entry = yyvsp[0].sym;
	;}
    break;

  case 461:
#line 4275 "parse.y"
    {
	    Scan_Unput(',');
	    yyerrok;
	;}
    break;

  case 462:
#line 4280 "parse.y"
    {
	    Scan_Unput('}');
	    yyerrok;
	;}
    break;

  case 463:
#line 4287 "parse.y"
    {
	    yyerror("elements of a visMoniker list must be visMoniker chunk names");
	;}
    break;

  case 465:
#line 4299 "parse.y"
    {
	    yyval.sym = EnterSymbolInGlobal(yyvsp[0].string, OBJECT_SYM, 0);
	    AddChunkToUndefinedList(yyval.sym);
	;}
    break;

  case 466:
#line 4307 "parse.y"
    {
            yyval.sym = yyvsp[0].sym;
        ;}
    break;

  case 467:
#line 4311 "parse.y"
    {
            Symbol    *sym;

	    sym = EnterSymbolInGlobal(yyvsp[0].string, PROTOMINOR_SYM, 0);
            sym->data.symProtoMinor.msgOrVardataSym = NullSymbol;
            sym->data.symProtoMinor.references = 0;
            yyval.sym = sym;
	;}
    break;

  case 469:
#line 4324 "parse.y"
    {
	    yyval.sym = EnterSymbolInGlobal(yyvsp[0].string, VIS_MONIKER_CHUNK_SYM, 0);
	    AddChunkToUndefinedList(yyval.sym);
	;}
    break;

  case 471:
#line 4333 "parse.y"
    {
	    char buf[100];
	    sprintf(buf, "%d",yyvsp[0].num);
	    yyval.string = String_EnterZT(buf);
	;}
    break;

  case 472:
#line 4342 "parse.y"
    {
	  char *ctype;
	  char *id;
	  char *typesuffix;


	  yyval.tdecl = AllocTypeDeclString();
	  SplitTypeString(yyvsp[0].string,&ctype,&id,&typesuffix);

	  /* make sure the strings are hashed */
	  TDS_CTYPE(yyval.tdecl) = String_EnterZT(ctype);
	  TDS_IDENT(yyval.tdecl) = String_EnterZT(id);
	  TDS_TYPESUF(yyval.tdecl) = String_EnterZT(typesuffix);

        ;}
    break;


    }

/* Line 991 of yacc.c.  */
#line 7053 "parse.tab.c"

  yyvsp -= yylen;
  yyssp -= yylen;


  YY_STACK_PRINT (yyss, yyssp);

  *++yyvsp = yyval;


  /* Now `shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTOKENS] + *yyssp;
  if (0 <= yystate && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTOKENS];

  goto yynewstate;


/*------------------------------------.
| yyerrlab -- here on detecting error |
`------------------------------------*/
yyerrlab:
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
#if YYERROR_VERBOSE
      yyn = yypact[yystate];

      if (YYPACT_NINF < yyn && yyn < YYLAST)
	{
	  YYSIZE_T yysize = 0;
	  int yytype = YYTRANSLATE (yychar);
	  char *yymsg;
	  int yyx, yycount;

	  yycount = 0;
	  /* Start YYX at -YYN if negative to avoid negative indexes in
	     YYCHECK.  */
	  for (yyx = yyn < 0 ? -yyn : 0;
	       yyx < (int) (sizeof (yytname) / sizeof (char *)); yyx++)
	    if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
	      yysize += yystrlen (yytname[yyx]) + 15, yycount++;
	  yysize += yystrlen ("syntax error, unexpected ") + 1;
	  yysize += yystrlen (yytname[yytype]);
	  yymsg = (char *) YYSTACK_ALLOC (yysize);
	  if (yymsg != 0)
	    {
	      char *yyp = yystpcpy (yymsg, "syntax error, unexpected ");
	      yyp = yystpcpy (yyp, yytname[yytype]);

	      if (yycount < 5)
		{
		  yycount = 0;
		  for (yyx = yyn < 0 ? -yyn : 0;
		       yyx < (int) (sizeof (yytname) / sizeof (char *));
		       yyx++)
		    if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
		      {
			const char *yyq = ! yycount ? ", expecting " : " or ";
			yyp = yystpcpy (yyp, yyq);
			yyp = yystpcpy (yyp, yytname[yyx]);
			yycount++;
		      }
		}
	      yyerror (yymsg);
	      YYSTACK_FREE (yymsg);
	    }
	  else
	    yyerror ("syntax error; also virtual memory exhausted");
	}
      else
#endif /* YYERROR_VERBOSE */
	yyerror ("syntax error");
    }



  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
	 error, discard it.  */

      /* Return failure if at end of input.  */
      if (yychar == YYEOF)
        {
	  /* Pop the error token.  */
          YYPOPSTACK;
	  /* Pop the rest of the stack.  */
	  while (yyss < yyssp)
	    {
	      YYDSYMPRINTF ("Error: popping", yystos[*yyssp], yyvsp, yylsp);
	      yydestruct (yystos[*yyssp], yyvsp);
	      YYPOPSTACK;
	    }
	  YYABORT;
        }

      YYDSYMPRINTF ("Error: discarding", yytoken, &yylval, &yylloc);
      yydestruct (yytoken, &yylval);
      yychar = YYEMPTY;

    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab2;


/*----------------------------------------------------.
| yyerrlab1 -- error raised explicitly by an action.  |
`----------------------------------------------------*/
yyerrlab1:

  /* Suppress GCC warning that yyerrlab1 is unused when no action
     invokes YYERROR.  */
#if defined (__GNUC_MINOR__) && 2093 <= (__GNUC__ * 1000 + __GNUC_MINOR__) \
    && !defined __cplusplus
  __attribute__ ((__unused__))
#endif


  goto yyerrlab2;


/*---------------------------------------------------------------.
| yyerrlab2 -- pop states until the error token can be shifted.  |
`---------------------------------------------------------------*/
yyerrlab2:
  yyerrstatus = 3;	/* Each real token shifted decrements this.  */

  for (;;)
    {
      yyn = yypact[yystate];
      if (yyn != YYPACT_NINF)
	{
	  yyn += YYTERROR;
	  if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYTERROR)
	    {
	      yyn = yytable[yyn];
	      if (0 < yyn)
		break;
	    }
	}

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
	YYABORT;

      YYDSYMPRINTF ("Error: popping", yystos[*yyssp], yyvsp, yylsp);
      yydestruct (yystos[yystate], yyvsp);
      yyvsp--;
      yystate = *--yyssp;

      YY_STACK_PRINT (yyss, yyssp);
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  YYDPRINTF ((stderr, "Shifting error token, "));

  *++yyvsp = yylval;


  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;

/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;

#ifndef yyoverflow
/*----------------------------------------------.
| yyoverflowlab -- parser overflow comes here.  |
`----------------------------------------------*/
yyoverflowlab:
  yyerror ("parser stack overflow");
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
  return yyresult;
}


#line 4359 "parse.y"



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
	Output("extern %s %s %s%s;",
	       compilerOffsetTypeName,
	       compilerFarKeyword,
	       chunk->name,
	       _ar);
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
yyerror(char *fmt, ...)
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
	Output("%s", msgSym->data.symMessage.returnType);
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
    Output("(*)(");
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
		free((malloc_t)rel);
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

    if (malloc_size((malloc_t)*state) != 0) {
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
