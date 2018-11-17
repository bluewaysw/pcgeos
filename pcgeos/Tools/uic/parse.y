%{
/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  uic -- parser
 * FILE:	  parse.y
 *
 * AUTHOR:  	  Tony Requist
 *
 * DESCRIPTION:
 *	A grammar to parse a user interface description file.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: parse.y,v 2.48 97/06/08 15:24:56 clee Exp $";
#endif lint

#include <stdarg.h>
#include <ctype.h>

#include "uic.h"
#include "sttab.h"
#include "map.h"
#include <config.h>
#include <compat/string.h>
#include <malloc.h>

void		AddDataDef(Symbol *);
ObjectField	*NewObjectFieldType(Symbol *type);
ObjectField	*NewObjectFieldString(char *str);
ObjectField	*NewObjectFieldSym(Symbol *sym);
ObjectField	*NewObjectFieldField(ObjectField *field);

void		MakeVisMoniker(Symbol *sym, char *data);
void		MakeHelpEntry(Symbol *sym, char *data);
void		MakeHintList(Symbol *sym, ObjectField *data);
void		MakeActiveList(Symbol *sym, ObjectField *data);
void		MakeChunk(Symbol *sym, ChunkArgs ca, ChunkDataType cdt);

Symbol	*curClass = NullSymbol;		/* Current class being defined */
Symbol	*curStructureComp = NullSymbol;	/* Current */
Symbol	*curClassField = NullSymbol;	/* Current bit field or enum symbol */
Symbol	*curResource = NullSymbol;	/* Current resource */
Symbol	*curObject = NullSymbol;	/* Current object */
Symbol	*curVisMoniker = NullSymbol;	/* Current vis moniker */

int	curBitPos = 0;			/* Current bitField bit position */
int	curKbdMask = 0;			/* Current bitField bit position */
int	curEnumValue = 0;		/* Current enum decl value */
int	curEnumSkip = 0;		/* Skip value for defining enums */
int	curEnumMax = 0;			/* Current maximum enum value */

Symbol	*lastChunk = NullSymbol;    	/* Most-recently created chunk */
ChunkDataType	lastChunkType = CDT_unknown;	/* Type of data in it */
int	lastChunkLine;			/* Line number of the lastChunk */
char	*lastChunkFile = NULL;		/* File name of the lastChunk */

int	specificUI = 0;			/* Allow specific UI shortcuts */
int	version20 = FALSE;

Boolean	haveVMStyle = FALSE;		/* For parsing VisMonikers,
					   TRUE if "style = X" */

Symbol *curLinkPart = NullSymbol;	/* Current link tyoe */
ObjectField *curLastChild = NullObjectField;	/* Current end child on list */
Symbol *curFirstChild = NullSymbol;

#define NEW_LOC(var, inst,min,max)                                \
    do{                                                           \
	(var) = (LocalizeInfo *)malloc(sizeof(LocalizeInfo));    \
	LOC_INST(var) = (inst);                                  \
	LOC_MIN(var) = (min);                                    \
	LOC_MAX(var) = (max);                                    \
    }while(0)


#ifdef __HIGHC__
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

#endif  /* highc */

static char *FormInstVarName(Symbol *instvar);
static void ParseSetLastChunkWarningInfo (void);
static char *ParseSetMonikerListItem (char* prefix);


%}

/*
 *	Type returned by yylex()
*/
%union {
    char	*string;
    int		num;
    long	fixedNum;
    double	floatNum;
    char	ch;
    Symbol	*sym;
    ObjectField	*field;
    Scope	*scope;
    struct {
	int type;
	ObjectField *def;
    } classData;
    struct {
	int value;
	int maskOut;
	int modifiesDefault;
    } bfData;
    struct {
	ChunkArgs	chData;
	ChunkDataType	chDataType;
    } chData;
    LocalizeInfo	*locInfo;
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
 *	Component keyword tokens -- used in the Symbol structure and in the
 * ObjectField structure to record the type of symbol
 *
 *	All reserved words a (char *) to the name of the reserved word.
*/

%token <string>	STRUCTURE_COMP TYPE_COMP FPTR_COMP
%token <string>	BYTE_COMP WORD_COMP DWORD_COMP BIT_FIELD_COMP ENUM_COMP
%token <string>	LINK_COMP COMPOSITE_COMP VIS_MONIKER_COMP KBD_ACCELERATOR_COMP
%token <string>	HINT_COMP HELP_COMP OPTR_COMP ACTION_COMP ACTIVE_LIST_COMP
%token <string>	NPTR_COMP HPTR_COMP
%token <string> VARIANT_PTR GSTRING EXTERN

/*
 *	To add a component, add a "BIFF_COMP" token here
 */

/*
 *	Symbol types -- The scanner looks up all identifiers in the symbol
 *			table and returns the following tokens when symbols
 *			are found
*/

%token <sym> 	STRUCTURE_COMP_SYM TYPE_COMP_SYM FPTR_COMP_SYM
%token <sym> 	BYTE_COMP_SYM WORD_COMP_SYM DWORD_COMP_SYM BIT_FIELD_COMP_SYM
%token <sym>	ENUM_COMP_SYM LINK_COMP_SYM COMPOSITE_COMP_SYM
%token <sym>	VIS_MONIKER_COMP_SYM KBD_ACCELERATOR_COMP_SYM HINT_COMP_SYM
%token <sym>	HELP_COMP_SYM OPTR_COMP_SYM ACTION_COMP_SYM
%token <sym>	ACTIVE_LIST_COMP_SYM NPTR_COMP_SYM HPTR_COMP_SYM
%token <sym>	VARIANT_PTR_SYM

/*
 *	To add a component, add a "BIFF_COMP_SYM" token here
 */

%token <sym>	BIT_FIELD_SYM ENUM_ELEMENT_SYM

%token <sym>	ATTRIBUTES_SYM ATTRIBUTES_COMP_SYM COLOR_SYM COLOR_COMP_SYM
%token <sym>	SIZE_SYM SIZE_COMP_SYM ASPECT_RATIO_SYM ASPECT_RATIO_COMP_SYM
%token <sym>	CACHED_SIZE_SYM LIST_SYM
%token <sym>	STYLE_SYM STYLE_COMP_SYM
%token <sym>	KBD_SYM KBD_MODIFIER_SYM

	/* Data definers */

%token <sym>	UNKNOWN_DATA_SYM

%token <sym> 	VIS_MONIKER_SYM HINT_LIST_SYM HELP_ENTRY_SYM
%token <sym> 	ACTIVE_LIST_SYM GCN_LIST_SYM GCN_LIST_OF_LISTS_SYM CHUNK_SYM

%token <sym> 	CLASS_SYM HINT_SYM
%token <sym> 	RESOURCE_SYM OBJECT_SYM METHOD_SYM PROCESS_RESOURCE_SYM

	/* Other definers */

%token <sym> 	STRUCTURE_SYM

/*
 *	Other keyword tokens
 */

%token <> 	CLASS VIS_MONIKER HINT_LIST HELP_ENTRY ACTIVE_LIST CHUNK
%token <> 	STRUCTURE PRINT_MESSAGE ERROR_MESSAGE SPECIFIC_UI KBD_PATH

%token <> 	BYTE WORD DWORD META MASTER VARIANT DEFAULT IGNORE_DIRTY
%token <>	PROCESS START END NULL_TOKEN EMPTY DATA STATIC NOT_DETACHABLE
%token <>	VERSION20 VARDATA_RELOC RESOURCE_OUTPUT VAR_DATA GCN_LIST
%token		LOCALIZE NOT
/*
 *	Special tokens for debugging (not actually returned by scanner)
 */
%token	SPECIAL_DEBUG_TOKEN
%token  SPECIAL_UNDEBUG_TOKEN

/*
 *	Lexical tokens
*/
%token <string>	IDENT STRING
%token <ch>	CHAR
%token <fixedNum>	CONST_FIXED
%token <floatNum>	CONST_FLOAT

/*
 *	Non-terminal symbols
*/

/*%type <>	file commonDecl classDecl objectDecl structureDecl	*/
/*%type <>	messageDecl						*/
%type <sym>	superclass
%type <sym>	classFieldList classFieldSt
%type <sym>	structureFieldList structureFieldSt
%type <classData>	classField
/*%type <>	bfCompList bfCompElement enumCompList enumCompElement	*/

%type <num>	dataSize classFlags classFlag resourceFlags
%type <num>	objFlagList objFlag kbdPathOrNull

%type <field>	fieldList anyFieldEl fieldElementDef fieldElement
%type <field>	structureInitList structureInitListNN
%type <field>	activeListNN activeNN hintList hintDef
%type <field>	childList childListNN childNN

%type <sym>	bitFieldElSt
%type <num>	bitFieldListNN bitFieldEl enumCompDef vmAttrList
/*%type <>	enumFlags  vmElement					*/
%type <field>	vmArray vmArrayElement
%type <bfData>	bitFieldCompDef bitFieldListXX bitFieldElXX

%type <sym>	objectOrIdent methodOrIdent hintOrIdent
%type <sym>	visMonikerOrIdent helpEntryOrIdent hintListOrIdent
%type <sym>	activeListOrIdent chunkOrIdent

%type <string>	anyString identOrConst typeNameOrNull vmNavChar

%type <chData>	chunkDef chunkDataDef

/*
 * To add a component -- add an entry here
*/

%type <field>	structureCompDef anyStringDef
%type <field>	byteCompDef wordCompDef dwordCompDef fptrCompDef
%type <field>	kbdAcceleratorCompDef optrCompDef actionCompDef
%type <field>	activeListCompDef nptrCompDef hptrCompDef typeCompDef

%type <string>	visMonikerCompDef helpCompDef vmMiddle vmMiddleNonList
%type <string>	visMonikerDataDef
/*%type <>	visMonikerCompStart kbdAcceleratorCompStart 	    */
%type <sym>	fieldVisMonStart
%type <field>	hintCompDef

%type <num>	kbdAccelModList specificUIOrNothing

%type <sym>	varDataDef gcnListDef

%type <sym> 	variantPtrSym
%type <locInfo> localization
%type <sym>	externSym

%%

/*
 *****************************************************************************
 *			Rules
*/

/*
 ****************** High level rules
*/

file		: commonDecl
		| file commonDecl
		;

commonDecl	: START IDENT resourceFlags ';'
		{
		    Symbol *sym;

		    if (curResource != NullSymbol) {
			yyerror("Resource definitions cannot be nested");
		    }
		    sym = Symbol_Enter($2, RESOURCE_SYM, SYM_DEFINED);
		    sym->flags |= $3;
		    curResource = sym;
		    if (version20) {
			/*
			 * In 2.0 put resources on the list in the order
			 * that we encounter them so that we will generate
			 * code for them in this order.  This helps when
			 * defining and using constants
			 */
			Symbol **tempsym;
			for (tempsym = &firstResource;
			     *tempsym != NullSymbol;
			     tempsym = &((*tempsym)->data.symResource.
					    	    	    nextResource));
			*tempsym = sym;
		    } else {
		    	sym->data.symResource.nextResource = firstResource;
		    	firstResource = sym;
		    }
		}
		| START RESOURCE_SYM resourceFlags ';'
		{
		    if (curResource != NullSymbol) {
			yyerror("Resource definitions cannot be nested");
		    }
		    curResource = $2;
		    $2->flags |= $3;
		}
		| END RESOURCE_SYM ';'
		{
		    if ($2 != curResource) {
			yyerror("Mis-matched start/end");
		    }
		    curResource = NullSymbol;
		}
		| RESOURCE_OUTPUT '=' objectOrIdent ';'
		{
		    if (curResource == NullSymbol) {
			yyerror("resourceOutput must be inside a resource");
		    }
		    curResource->data.symResource.resourceOutput = $3;
		}
		| SPECIFIC_UI ';'
		{
		    specificUI = TRUE;
		}
		| classDecl {}
		| objectDecl {}
		| structureDecl {}
		| VIS_MONIKER visMonikerOrIdent visMonikerCompStart
		    {
			curVisMoniker = $2;
		    }
		    '=' visMonikerCompDef
		    {
			MakeVisMoniker(curVisMoniker,$6);
		    }
		| HELP_ENTRY helpEntryOrIdent '=' helpCompDef
		{
		    MakeHelpEntry($2,$4);
		}
		| HINT_LIST hintListOrIdent '=' hintCompDef
		{
		    MakeHintList($2,$4);
		}
		| ACTIVE_LIST activeListOrIdent '=' activeListCompDef
		{
		    MakeActiveList($2,$4);
		}
		| CHUNK chunkOrIdent '=' chunkDef
		{
		    MakeChunk($2,$4.chData,$4.chDataType);
		}
		| VERSION20 {
		    version20 = TRUE;
		}
		| messageDecl
		| localizationLine
		| externDecl
		| errorReset ';'
		| errorReset
		;

errorReset  	: error
		{
		    scanStringEndBrace = FALSE;
		}
		;

messageDecl	: PRINT_MESSAGE STRING
		{
		    fprintf(stderr, "file %s, line %d: %s\n",
						inFile, yylineno, $2);
		}
		| ERROR_MESSAGE STRING
		{
		    yyerror("forced error -- %s", $2);
		}
		;

resourceFlags	: ',' DATA { $$ = SYM_DATA_RESOURCE; }
		| ',' NOT_DETACHABLE { $$ = SYM_NOT_DETACHABLE; }
		| { $$ = 0; }
		;

objectOrIdent	: OBJECT_SYM
		| UNKNOWN_DATA_SYM
		{
		    $$ = $1;
		    $$->type = OBJECT_SYM;
		}
		| IDENT
		{
		    Symbol_PushScope(globalScope);
		    $$ = Symbol_Enter($1, OBJECT_SYM, SYM_REFERENCED);
		    (void) Symbol_PopScope();
		}
		;

visMonikerOrIdent	: VIS_MONIKER_SYM
		| UNKNOWN_DATA_SYM
		{
		    $$ = $1;
		    $$->type = VIS_MONIKER_SYM;
		}
		| CHUNK_SYM
		{
		    fprintf(stderr,
			    "file %s, line %d: warning: using chunk %s as moniker\n",
			    inFile, yylineno, $1->name);
		    $$ = $1;
		}
		| IDENT
		{
		    Symbol_PushScope(globalScope);
		    $$ = Symbol_Enter($1, VIS_MONIKER_SYM, SYM_REFERENCED);
		    (void) Symbol_PopScope();
		}
		;

helpEntryOrIdent	: HELP_ENTRY_SYM
		| UNKNOWN_DATA_SYM
		{
		    $$ = $1;
		    $$->type = HELP_ENTRY_SYM;
		}
		| IDENT
		{
		    Symbol_PushScope(globalScope);
		    $$ = Symbol_Enter($1, HELP_ENTRY_SYM, SYM_REFERENCED);
		    (void) Symbol_PopScope();
		}
		;

hintListOrIdent	: HINT_LIST_SYM
		| UNKNOWN_DATA_SYM
		{
		    $$ = $1;
		    $$->type = HINT_LIST_SYM;
		}
		| IDENT
		{
		    Symbol_PushScope(globalScope);
		    $$ = Symbol_Enter($1, HINT_LIST_SYM, SYM_REFERENCED);
		    (void) Symbol_PopScope();
		}
		;

activeListOrIdent	: ACTIVE_LIST_SYM
		| UNKNOWN_DATA_SYM
		{
		    $$ = $1;
		    $$->type = ACTIVE_LIST_SYM;
		}
		| IDENT
		{
		    Symbol_PushScope(globalScope);
		    $$ = Symbol_Enter($1, ACTIVE_LIST_SYM, SYM_REFERENCED);
		    (void) Symbol_PopScope();
		}
		;

chunkOrIdent	: CHUNK_SYM
		| UNKNOWN_DATA_SYM
		{
		    $$ = $1;
		    $$->type = CHUNK_SYM;
		}
		| IDENT
		{
		    Symbol_PushScope(globalScope);
		    $$ = Symbol_Enter($1, CHUNK_SYM, SYM_REFERENCED);
		    (void) Symbol_PopScope();
		}
		| OBJECT_SYM
		{
		    if ($1->flags & SYM_DEFINED) {
			yyerror("cannot redefine object as a data chunk");
		    } else {
			$1->type = CHUNK_SYM;
		    }
		    $$ = $1;
		}
		;

/*
 ****************** Class definition rules
*/

classDecl	: CLASS IDENT '=' superclass
		    {
			Scope *parentScope;

			curClass = Symbol_Enter($2, CLASS_SYM, SYM_DEFINED);
			if ($4 != NullSymbol) {
			    parentScope = $4->data.symClass.localSymbols;
			    curClass->flags |=
				    	($4->flags & SYM_CLASS_FORCE_KBD_PATH);
			} else {
			    parentScope = currentScope;
			}
			curClass->data.symClass.localSymbols =
						Symbol_NewScope(parentScope,
								FALSE);
			Symbol_PushScope(curClass->data.symClass.localSymbols);
		    }
		    classFlags '{' classFieldList '}'
		    {
			/*
			 * If class is variant, add name of class as instance
			 * variable to allow resolving of variant classes.
			 */
			if ($6 & SYM_CLASS_VARIANT) {
			    curClassField = Symbol_Enter($2, VARIANT_PTR_SYM,
							 SYM_DEFINED);
			    curClassField->data.symVariantPtr.next = $8;
			    curClassField->data.symVariantPtr.class =
				curClass;
			    $8 = curClassField;
			}

			Symbol_PopScopeTo(curClass->data.symClass.localSymbols);
			curClass->data.symClass.superclass = $4;
			curClass->flags |= $6;
			curClass->data.symClass.componentPtr = $8;
			if ($4 == NullSymbol) {
			    curClass->data.symClass.masterLevel = 0;
			} else {
			    curClass->data.symClass.masterLevel =
				$4->data.symClass.masterLevel;
			    if (curClass->flags & SYM_CLASS_MASTER) {
				curClass->data.symClass.masterLevel += 1;
			    }
			}
			curClass = NullSymbol;
		    }
		;

superclass	: CLASS_SYM
		| META { $$ = NullSymbol; }
		;

classFlags 	: classFlags classFlag { $$ = $1 | $2; }
    	    	| { $$ = 0; }
 	    	;

classFlag	: ',' MASTER
		{
		    $$ = SYM_CLASS_MASTER
		}
		| ',' VARIANT
		{
		    $$ = SYM_CLASS_VARIANT;
		}
		| ',' KBD_PATH
		{
		    $$ = SYM_CLASS_FORCE_KBD_PATH;
		}
		;

classFieldList	: classFieldList classFieldSt
		{
		    $$ = $1;
		    if ($$ == NullSymbol) {
			$$ = $2;
		    } else {
			Symbol **sym;

			for (sym = &($$->data.symByteComp.next);
				*sym != NullSymbol;
				sym = &((*sym)->data.symByteComp.next));
			*sym = $2;
		    }
		}
		|
		{
		    $$ = NullSymbol;
		}
		;

classFieldSt	: STATIC
		    {
			curClassField = Symbol_Enter(UniqueName(), 0,
								SYM_DEFINED);
			curClassField->flags |= SYM_STATIC;
		    }
		    classField
		    {
			curClassField->type = $3.type;
			if ($3.def != NullObjectField) {
			    $3.def->type = curClassField;
			}
			curClassField->data.symByteComp.defaultValue = $3.def;
			$$ = curClassField;
		    }
		| DEFAULT fieldElementDef
		{
		    $$ = NullSymbol;
		    $2->next = curClass->data.symClass.firstDefault;
		    curClass->data.symClass.firstDefault = $2;
		}
		| IDENT '='
		    {
			curClassField = Symbol_Enter($1, 0, SYM_DEFINED);
		    }
		    classField
		    {
			curClassField->type = $4.type;
			if ($4.def != NullObjectField) {
			    $4.def->type = curClassField;
			}
			curClassField->data.symByteComp.defaultValue = $4.def;
			$$ = curClassField;
		    }
		| messageDecl
		{
		    $$ = NullSymbol;
		}
		| error ';' { $$ = NullSymbol; }
		| error { $$ = NullSymbol; }
		;

/*
 ****************** Structure definition rules
*/

structureDecl	: STRUCTURE IDENT '='
		    {
			curClass = Symbol_Enter($2, STRUCTURE_SYM, SYM_DEFINED);
			curClass->data.symStructure.localSymbols =
						Symbol_NewScope(currentScope,
								TRUE);
			Symbol_PushScope(
				curClass->data.symStructure.localSymbols);
		    }
		    '{' structureFieldList '}'
		    {
			(void) Symbol_PopScope();
			curClass->data.symStructure.firstField = $6;
			curClass = NullSymbol;
		    }
		;

structureFieldList	: structureFieldList structureFieldSt
		{
		    $$ = $1;
		    if ($$ == NullSymbol) {
			$$ = $2;
		    } else {
			Symbol **sym;

			for (sym = &($$->data.symByteComp.next);
				*sym != NullSymbol;
				sym = &((*sym)->data.symByteComp.next));
			*sym = $2;
		    }
		}
		|
		{
		    $$ = NullSymbol;
		}
		;

structureFieldSt	: STATIC
		    {
			curClassField = Symbol_Enter(UniqueName(), 0,
								SYM_DEFINED);
			curClassField->flags |= SYM_STATIC;
		    }
		    classField
		    {
			curClassField->type = $3.type;
			if ($3.def != NullObjectField) {
			    $3.def->type = curClassField;
			}
			curClassField->data.symByteComp.defaultValue = $3.def;
			$$ = curClassField;
		    }
		| IDENT '='
		    {
			curClassField = Symbol_Enter($1, 0, SYM_DEFINED);
		    }
		    classField
		    {
			curClassField->type = $4.type;
			if ($4.def != NullObjectField) {
			    $4.def->type = curClassField;
			}
			curClassField->data.symByteComp.defaultValue = $4.def;
			$$ = curClassField;
		    }
		| messageDecl
		{
		    $$ = NullSymbol;
		}
		| error ';' { $$ = NullSymbol; }
		| error { $$ = NullSymbol; }
		;

/*
 ****************** Component rules (used in declaring classes and structures)
 *
*/

/*
 *	To add a component, add a "| BIFF_COMP ..." rule here
 */

classField	: STRUCTURE_SYM
		    {
			Symbol_PushScope( $1->data.symStructure.localSymbols );
			$<sym>$ = curStructureComp;
			curStructureComp =
				$1->data.symStructure.firstField;
		    }
		    ':' structureCompDef
		    {
			(void) Symbol_PopScope();
			curStructureComp = $<sym>2;
			$$.type = STRUCTURE_COMP_SYM; $$.def = $4;
			curClassField->data.symStructureComp.structureType = $1;
		    }
		| BYTE_COMP ':' byteCompDef
			{ $$.type = BYTE_COMP_SYM; $$.def = $3; }
		| TYPE_COMP STRING ':' typeCompDef
		    {
			$$.type = TYPE_COMP_SYM;
			curClassField->data.symTypeComp.typeName = $2;
			$$.def = $4;
		    }
		| WORD_COMP ':' wordCompDef
			{ $$.type = WORD_COMP_SYM; $$.def = $3; }
		| DWORD_COMP ':' dwordCompDef
			{ $$.type = DWORD_COMP_SYM; $$.def = $3; }
		| FPTR_COMP ':' fptrCompDef
			{ $$.type = FPTR_COMP_SYM; $$.def = $3; }
		| OPTR_COMP ':' optrCompDef ';'
			{ $$.type = OPTR_COMP_SYM; $$.def = $3; }
		| ACTION_COMP ':' actionCompDef ';'
			{ $$.type = ACTION_COMP_SYM; $$.def = $3; }
		| NPTR_COMP ':' nptrCompDef ';'
			{ $$.type = NPTR_COMP_SYM; $$.def = $3; }
		| HPTR_COMP ':' hptrCompDef ';'
			{ $$.type = HPTR_COMP_SYM; $$.def = $3; }

		| BIT_FIELD_COMP dataSize
		    {
			Symbol_PushScope( Symbol_NewScope(NullScope, TRUE) );
			curBitPos = $2;
		    }
		    '{' bfCompList '}' ':' bitFieldCompDef ';'
		    {
			if ($8.modifiesDefault) {
			    yyerror("default not allowed in field def");
			}
			curClassField->data.symBitFieldComp.localSymbols =
							Symbol_PopScope();
			curClassField->data.symBitFieldComp.bitSize = $2;
			$$.type = BIT_FIELD_COMP_SYM;
			$$.def = NewObjectFieldType(curClassField);
			$$.def->data.fieldBitField.value = $8.value;
			$$.def->data.fieldBitField.maskOut = $8.maskOut;
			$$.def->data.fieldBitField.modifiesDefault = FALSE;
		    }
		| ENUM_COMP dataSize
		    {
			curEnumMax = (1 << $2) - 1;
			Symbol_PushScope( Symbol_NewScope(NullScope, TRUE) );
		    }
		    enumFlags
		    {
			if (curEnumValue > curEnumMax) {
			    yyerror("illegal enum start value");
			}
		    }
		    '{' enumCompList '}' ':' enumCompDef ';'
		    {
			curClassField->data.symEnumComp.localSymbols =
							Symbol_PopScope();
			curClassField->data.symEnumComp.bitSize = $2;
			$$.type = ENUM_COMP_SYM;
			$$.def = NewObjectFieldType(curClassField);
			$$.def->data.fieldEnum.value = $10;
		    }

		| KBD_ACCELERATOR_COMP ';'
		{
		    $$.type = KBD_ACCELERATOR_COMP_SYM;
		    $$.def = NullObjectField;
		}
		| ACTIVE_LIST_COMP ';'
		{
		    $$.type = ACTIVE_LIST_COMP_SYM; $$.def = NullObjectField;
		}
		| LINK_COMP kbdPathOrNull ';'
		{
		    $$.type = LINK_COMP_SYM; $$.def = NullObjectField;
		    curClassField->flags |= $2;
		}
		| COMPOSITE_COMP LINK_COMP_SYM ';'
		{
		    $$.type = COMPOSITE_COMP_SYM; $$.def = NullObjectField;
		    curClassField->data.symCompositeComp.linkSym = $2;
		}
		| VIS_MONIKER_COMP ';'
		{
		    $$.type = VIS_MONIKER_COMP_SYM; $$.def = NullObjectField;
		}
		| HINT_COMP ';'
		{
		    $$.type = HINT_COMP_SYM; $$.def = NullObjectField;
		}
		| HELP_COMP ';'
		{
		    $$.type = HELP_COMP_SYM; $$.def = NullObjectField;
		}
		;

kbdPathOrNull	: KBD_PATH { $$ = SYM_IS_KBD_PATH; }
		| { $$ = 0; }
		;

dataSize	: BYTE { $$ = 8; }
		| WORD { $$ = 16; }
		| DWORD { $$ = 32; }
		;

enumFlags	: '(' CONST_FIXED ',' CONST_FIXED ')'
		{
		    curEnumValue = $2;
		    curEnumSkip = $4;
		}
		| '(' CONST_FIXED ')'
		{
		    curEnumValue = $2;
		    curEnumSkip = 1;
		}
		|
		{
		    curEnumValue = 0;
		    curEnumSkip = 1;
		}
		;

bfCompList	: bfCompList ',' bfCompElement
		| bfCompElement
		;

bfCompElement	: IDENT ':' CONST_FIXED
		{
		    Symbol *sym;

		    sym = Symbol_Enter($1, BIT_FIELD_SYM, SYM_DEFINED);
		    sym->data.symBitField.max = (1 << $3) - 1;
		    sym->data.symBitField.position = curBitPos - $3;
		    if (sym->data.symBitField.position < 0) {
			yyerror("bit field overflow");
			break;
		    }
		    curBitPos -= $3;
		}
		| IDENT ':' CONST_FIXED '='
		    {
			Symbol *sym;

			sym = Symbol_Enter($1, BIT_FIELD_SYM, SYM_DEFINED);
			sym->data.symBitField.max = (1 << $3) - 1;
			sym->data.symBitField.position = curBitPos - $3;
			if (sym->data.symBitField.position < 0) {
			    yyerror("bit field overflow");
			    break;
			}
			curBitPos -= $3;
			sym->data.symBitField.localSymbols =
						Symbol_NewScope(NullScope,
								TRUE);
			Symbol_PushScope(sym->data.symBitField.localSymbols);
			curEnumValue = 0;
			curEnumSkip = 1;
			curEnumMax = sym->data.symBitField.max;
		    }
		    '{' enumCompList '}'
		    {
			(void) Symbol_PopScope();
		    }
		| IDENT
		{
		    Symbol *sym;

		    sym = Symbol_Enter($1, BIT_FIELD_SYM, SYM_DEFINED);
		    sym->data.symBitField.max = 1;
		    curBitPos -= 1;
		    sym->data.symBitField.position = curBitPos;
		    if (curBitPos < 0) {
			yyerror("bit field overflow");
		    }
		}
		| KBD_PATH
		{
		    curBitPos -= 1;
		    curClassField->data.symBitFieldComp.kbdPathMask =
							1 << curBitPos;
		    if (curBitPos < 0) {
			yyerror("bit field overflow");
		    }
		}
		;

enumCompList	: enumCompList ',' enumCompElement
		| enumCompElement
		;

enumCompElement	: IDENT
		{
		    Symbol *sym;

		    if (curEnumValue > curEnumMax) {
			yyerror("illegal enum value");
		    }
		    sym = Symbol_Enter($1, ENUM_ELEMENT_SYM, SYM_DEFINED);
		    sym->data.symEnum.value = curEnumValue;
		    curEnumValue += curEnumSkip;
		}
		| IDENT '=' CONST_FIXED
		{
		    Symbol *sym;

		    sym = Symbol_Enter($1, ENUM_ELEMENT_SYM, SYM_DEFINED);
		    curEnumValue = $3;
		    if (curEnumValue > curEnumMax) {
			yyerror("illegal enum value");
		    }
		    sym->data.symEnum.value = curEnumValue;
		    curEnumValue += curEnumSkip;
		}
		;

/*
 ****************** Object definition rules
*/

objectDecl	: objectOrIdent '=' CLASS_SYM objFlagList
		    {
			Symbol	*class, *super;
			
			$1->flags |= SYM_DEFINED | $4;
			$1->data.symObject.class = $3;
			AddDataDef($1);
			curObject = $1;
			Symbol_PushScope($3->data.symClass.localSymbols);

			if ($3->flags & SYM_CLASS_FORCE_KBD_PATH) {
			    $1->flags |= SYM_HAS_KBD_ACCEL;
			}

			/*
			 * Deal with default building of things
			 */
			for (class = $3; class != NullSymbol; class = super) {
			    if (class->flags & SYM_CLASS_VARIANT) {
				ObjectField *def;

				def =
				    FindDefault($3,
						class->data.symClass.componentPtr);
				if (def == (ObjectField *)class)
				{
				    /*
				     * The predefined default value for a
				     * variant superclass pointer is the class
				     * to which the pointer belongs, so if
				     * we get back the class itself, there
				     * is no default.
				     */
				    super = class->data.symClass.superclass;
				} else {
				    /*
				     * Default given, so push that class' local
				     * symbols.
				     */
				    super =
					def->data.fieldVariantPtr.target;
				    Symbol_PushScope(super->data.symClass.localSymbols);
				}
			    } else {
				super = class->data.symClass.superclass;
			    }
			}
		    }
		    '{' fieldList '}'
		    {
			ObjectField **ofp;

			Symbol_PopScopeTo($3->data.symClass.localSymbols);
			for (ofp = &($1->data.symObject.firstField);
				*ofp != NullObjectField; ofp = &((*ofp)->next));
			*ofp = $7;
			curObject = NullSymbol;
		    }
		;

objFlagList 	: objFlagList objFlag { $$ = $1 | $2; }
    	    	| { $$ = 0; }
 	    	;

objFlag	:   	IGNORE_DIRTY
		{
		    $$ = SYM_IGNORE_DIRTY;
		}
		| VARDATA_RELOC
		{
		    $$ = SYM_VARDATA_RELOC;
		}
		| KBD_PATH
		{
		    $$ = SYM_HAS_KBD_ACCEL;
		}
		;

fieldList	: fieldList anyFieldEl
		{
		    if ($2 != NullObjectField) {
			$$ = $2;
			$2->next = $1;
		    } else {
			$$ = $1;
		    }
		}
		|
		{
		    $$ = NullObjectField;
		}
		;

anyFieldEl	: fieldElement
		| fieldElementDef
		| localizationLine
		{
		    $$ = NullObjectField;
		}
		;

/*
 ****************** Structure definition rules
*/

structureCompDef : '{' fieldList '}'
		{
		    $$ = NewObjectFieldField($2);
		} 
		| '<'
		    {
			if (curStructureComp != NullSymbol) {
			    lexpush('=', NullSymbol);
			    lexpush(curStructureComp->type,curStructureComp);
			    curStructureComp =
				    curStructureComp->data.symByteComp.next;
			}
		    }
		    structureInitList '>'
		    {
			$$ = NewObjectFieldField($3);
		    }
		;

structureInitList : structureInitListNN
		|
		{
		    $$ = NullObjectField;
		}
		;

structureInitListNN : structureInitListNN fieldElementDef
		{
		    if ($2 != NullObjectField) {
			$$ = $2;
			$2->next = $1;
		    } else {
			$$ = $1;
		    }
		    if (curStructureComp != NullSymbol) {
			lexpush('=', NullSymbol);
			lexpush(curStructureComp->type,curStructureComp);
			curStructureComp =
				curStructureComp->data.symByteComp.next;
		    }
		}
		| fieldElementDef
		{
		    $$ = $1;
		    if (curStructureComp != NullSymbol) {
			lexpush('=', NullSymbol);
			lexpush(curStructureComp->type,curStructureComp);
			curStructureComp =
				curStructureComp->data.symByteComp.next;
		    }
		}
		;

/*
 ****************** Field definition rules
 *
 *	Field definitions are broken into two rules, one rule for components
 *	with default values (fieldElementDef) and one rule for components
 *	without default values. (fieldElement).
*/

/*
 *	To add a component, add a "| BIFF_COMP_SYM ..." rule here
 */

fieldElementDef	: BYTE_COMP_SYM '=' byteCompDef
		    { $$ = $3; $$->type = $1; }
		| TYPE_COMP_SYM '=' typeCompDef
		    { $$ = $3; $$->type = $1; }
		| WORD_COMP_SYM '=' wordCompDef
		    { $$ = $3; $$->type = $1; }
		| DWORD_COMP_SYM '=' dwordCompDef
		    { $$ = $3; $$->type = $1; }
		| FPTR_COMP_SYM '=' fptrCompDef
		    { $$ = $3; $$->type = $1; }
		| OPTR_COMP_SYM '=' optrCompDef ';'
		    { $$ = $3; $$->type = $1; }
		| ACTION_COMP_SYM '=' actionCompDef ';'
		    { $$ = $3; $$->type = $1; }
		| HPTR_COMP_SYM '=' hptrCompDef ';'
		    { $$ = $3; $$->type = $1; }

		| LINK_COMP_SYM '=' optrCompDef ';'
		{ 
		    if ( $3->data.fieldOptr.type != OPTR_OBJECT) 
			yyerror("Parent must be an object");
	
		    $$ = $3; 
		    $$->type = $1;
			/* This line shouldn't be necessary, but we'll
			   leave it up to GCC to optimize it out */
		    $$->data.fieldLink.link = $3->data.fieldOptr.data.obj.dest;
		    $$->data.fieldLink.isParentLink = TRUE;
		    $$->data.fieldLink.parent = NullSymbol;
 		}	

		| NPTR_COMP_SYM '=' nptrCompDef ';'
		    { $$ = $3; $$->type = $1; }
		| NPTR_COMP_SYM chunkOrIdent '=' chunkDef
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldNptr.target = $2;
		    MakeChunk($2,$4.chData,$4.chDataType);
		}
		| NPTR_COMP_SYM '=' chunkDef
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldNptr.target =
			Symbol_Enter(FormInstVarName($1), CHUNK_SYM,
				     SYM_DEFINED);
		    MakeChunk($$->data.fieldNptr.target,$3.chData,$3.chDataType);
		}

		| BIT_FIELD_COMP_SYM
		    {
			Symbol_PushScope($1->data.symBitFieldComp.localSymbols);
		    }
		    '=' bitFieldCompDef ';'
		    {
			(void) Symbol_PopScope();
			$$ = NewObjectFieldType($1);
			$$->data.fieldBitField.value = $4.value;
			$$->data.fieldBitField.maskOut = $4.maskOut;
			$$->data.fieldBitField.modifiesDefault =
							$4.modifiesDefault;
		    }
		| ENUM_COMP_SYM
		    {
			Symbol_PushScope($1->data.symEnumComp.localSymbols);
		    }
		    '=' enumCompDef ';'
		    {
			(void) Symbol_PopScope();
			$$ = NewObjectFieldType($1);
			$$->data.fieldEnum.value = $4;
		    }
		| STRUCTURE_COMP_SYM
		    {
			$<sym>$ = curStructureComp;
			curStructureComp = $1->data.symStructureComp.
				structureType->data.symStructure.firstField;
			Symbol_PushScope($1->data.symStructureComp.
				structureType->data.symStructure.localSymbols);
		    }
		    '=' structureCompDef
		    {
			(void) Symbol_PopScope();
			curStructureComp = $<sym>2;
			$$ = $4;
			$$->type = $1;
		    }
		| variantPtrSym '=' CLASS_SYM ';'
		{
		    if ($1->data.symVariantPtr.class->data.symClass.masterLevel
			!= $3->data.symClass.masterLevel + 1)
		    {
			yyerror("variant class %s cannot resolve to %s",
				$1->data.symVariantPtr.class->name,
				$3->name);
		    } else {
			ObjectField *def;
			
			/*
			 * Create a new object field pointing to the superclass
			 */
			$$ = NewObjectFieldSym($3);
			/*
			 * And add its symbols to our own. If there was a
			 * default value for the pointer, we need to replace the
			 * scope previously pushed with the scope for the
			 * actual variant superclass. If there was no default
			 * value, we need only push the super's scope.
			 */
			def = FindDefault(curClass,
					  $1->data.symVariantPtr.class->data.symClass.componentPtr);
			if (def == (ObjectField *)$1->data.symVariantPtr.class)
			{
			    Symbol_PushScope($3->data.symClass.localSymbols);
			} else {
			    (void)Symbol_ReplaceScope(def->data.fieldVariantPtr.target->data.symClass.localSymbols,
						      $3->data.symClass.localSymbols);
			}
			$$->type = $1;
		    }
		}
		;
variantPtrSym	: VARIANT_PTR_SYM
		| CLASS_SYM
		{
		    if ($1->flags & SYM_CLASS_VARIANT) {
			$$ = $1->data.symClass.componentPtr;
		    } else {
			yyerror("parse error");
			YYERROR;
		    }
		}
		;

fieldElement	: KBD_ACCELERATOR_COMP_SYM kbdAcceleratorCompStart '='
						kbdAcceleratorCompDef ';'
		    {
			$$ = $4;
			$$->type = $1;
			curObject->flags |= SYM_HAS_KBD_ACCEL;
		    }
		| fieldVisMonStart visMonikerOrIdent '='
		    {
			curVisMoniker = $2;
		    }
		    visMonikerCompDef
		    {
			$$ = NewObjectFieldType($1);
			$$->data.fieldVisMoniker.moniker = curVisMoniker;
			MakeVisMoniker(curVisMoniker,$5);
		    }
		| fieldVisMonStart '='
		    {
			/*
			 * Form chunk name from the object name and the
			 * instvar name, so it doesn't change arbitrarily
			 * from compilation to compilation.
			 */
			curVisMoniker = Symbol_Enter(FormInstVarName($1),
						VIS_MONIKER_SYM, SYM_DEFINED);
		    }
		    visMonikerCompDef
		    {
			$$ = NewObjectFieldType($1);
			$$->data.fieldVisMoniker.moniker = curVisMoniker;
			MakeVisMoniker(curVisMoniker,$4);
		    }
		| fieldVisMonStart '=' visMonikerOrIdent ';'
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldVisMoniker.moniker = $3;
		    Symbol_PopScope();	    /* Pushed by fieldVisMonStart */
		}

		| HELP_COMP_SYM helpEntryOrIdent '=' helpCompDef
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldHelp.helpEntry = $2;
		    MakeHelpEntry($2,$4);
		}
		| HELP_COMP_SYM '=' helpCompDef
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldHelp.helpEntry = Symbol_Enter(
				UniqueName(), HELP_ENTRY_SYM, SYM_DEFINED);
		    MakeHelpEntry($$->data.fieldHelp.helpEntry,$3);
		}
		| HELP_COMP_SYM '=' HELP_ENTRY_SYM ';'
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldHelp.helpEntry = $3;
		}

		| HINT_COMP_SYM hintListOrIdent '=' hintCompDef
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldHint.hintList = $2;
		    MakeHintList($2,$4);
		}
		| HINT_COMP_SYM '=' hintCompDef
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldHint.hintList = Symbol_Enter(
				UniqueName(), HINT_LIST_SYM, SYM_DEFINED);
		    MakeHintList($$->data.fieldHint.hintList,$3);
		}
		| HINT_COMP_SYM '=' hintListOrIdent ';'
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldHint.hintList = $3;
		}
		| HINT_COMP_SYM '=' CHUNK_SYM ';'
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldHint.hintList = $3;
		}

		| ACTIVE_LIST_COMP_SYM activeListOrIdent '='
							activeListCompDef
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldActiveList.list = $2;
		    curObject->flags |= SYM_HAS_KBD_ACCEL;
		    MakeActiveList($2,$4);
		}
		| ACTIVE_LIST_COMP_SYM '=' activeListCompDef
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldActiveList.list = Symbol_Enter(
				UniqueName(), ACTIVE_LIST_SYM, SYM_DEFINED);
		    MakeActiveList($$->data.fieldActiveList.list,$3);
		}
		| ACTIVE_LIST_COMP_SYM '=' ACTIVE_LIST_SYM ';'
		{
		    $$ = NewObjectFieldType($1);
		    $$->data.fieldActiveList.list = $3;
		}
		| COMPOSITE_COMP_SYM '='
		    {
			curLastChild = NullObjectField;
			curLinkPart = $1->data.symCompositeComp.linkSym;
		    }
		    childList ';'
		    {
			if ($4 == NullObjectField) {
			    $$ = NullObjectField;
			} else {
			    $$ = NewObjectFieldType($1);
			    $$->data.fieldComposite.firstChild = curFirstChild;
			    curLastChild->data.fieldLink.link = curObject;
			    curLastChild->data.fieldLink.isParentLink = TRUE;
			}
		    }
		| VAR_DATA '='		/* 'varData' keyword */
		    {
			/*
			 * create a symbol for the var data
			 */
		    }
		    varDataDef
		    {
			curObject->data.symObject.varData = $4;
			$$ = NullObjectField;
		    }
		| GCN_LIST '(' identOrConst ',' identOrConst ')' '=' gcnListDef
		{
		    if (curObject->data.symObject.gcnListOfLists == NullSymbol) {
			Symbol *listOfLists;
		        listOfLists = Symbol_Enter(UniqueName(),
					GCN_LIST_OF_LISTS_SYM, SYM_DEFINED);
		        listOfLists->flags |= SYM_DEFINED;
		        AddDataDef(listOfLists);
		        curObject->data.symObject.gcnListOfLists = listOfLists;
			curObject->data.symObject.gcnListOfLists->data.symGCNListOfLists.firstList = $8;
		    } else {
			Symbol **field;
			for (field = &(curObject->data.symObject.gcnListOfLists->data.symGCNListOfLists.firstList);
				*field != NullSymbol;
				field = &((*field)->data.symGCNList.nextList));
			*field = $8;
		    }
		    $8->data.symGCNList.manufID = $3;
		    $8->data.symGCNList.type = $5;
		    $$ = NullObjectField;
		}
		| messageDecl
		{
		    $$ = NullObjectField;
		}
		| error ';' { $$ = NullObjectField; }
		| error { $$ = NullObjectField; }
		;

varDataDef	:
		{
		    if (curObject == NullSymbol) {
			yyerror("var data outside of any object");
		    }
		    if (!version20) {
			yyerror("varData is only for version 2.0");
		    }
		}
		hintCompDef
		{
		    $$ = Symbol_Enter(UniqueName(), HINT_LIST_SYM, SYM_DEFINED);
		    /*
		     * Do the work of MakeHintList, but don't add chunk to
		     * resource
		     */
		    $$->flags |= SYM_DEFINED;
		    $$->data.symHintList.firstHint = $2;
		}
		;

gcnListDef	:
		{
		    if (curObject == NullSymbol) {
			yyerror("gcn list outside of any object");
		    }
		    if (!version20) {
			yyerror("gcn list is only for version 2.0");
		    }
		}
		activeListCompDef
		{
		    $$ = Symbol_Enter(UniqueName(), GCN_LIST_SYM, SYM_DEFINED);
		    $$->flags |= SYM_DEFINED;
		    $$->data.symGCNList.firstItem = $2;
		    AddDataDef($$);
		}

fieldVisMonStart : VIS_MONIKER_COMP_SYM visMonikerCompStart
		;

bitFieldCompDef	: DEFAULT bitFieldListXX
		{
		    $$.modifiesDefault = TRUE;
		    $$.value = $2.value;
		    $$.maskOut = $2.maskOut;
		}
		| bitFieldListNN
		{
		    $$.modifiesDefault = FALSE;
		    $$.value = $1;
		    $$.maskOut = 0;
		}
		| '{' '}'
		{
		    $$.modifiesDefault = FALSE;
		    $$.value = 0;
		    $$.maskOut = 0;
		}
		;

bitFieldListNN	: bitFieldListNN ',' bitFieldEl
		{
		    $$ = $1 | $3;
		}
		| bitFieldEl
		;

bitFieldEl	: bitFieldElSt enumCompDef
		{
		    (void) Symbol_PopScope();
		    $$ = $2 << $1->data.symBitField.position;
		}
		| bitFieldElSt CONST_FIXED
		{
		    int i;

		    (void) Symbol_PopScope();
		    i = $2;
		    if (i > $1->data.symBitField.max) {
			yyerror("bit field overflow");
		    }
		    $$ = i << $1->data.symBitField.position;
		}
		| bitFieldElSt CHAR
		{
		    int i;

		    (void) Symbol_PopScope();
		    i = $2;
		    if (i > $1->data.symBitField.max) {
			yyerror("bit field overflow");
		    }
		    $$ = i << $1->data.symBitField.position;
		}
		| bitFieldElSt
		{
		    (void) Symbol_PopScope();
		    $$ = 1 << $1->data.symBitField.position;
		}
		;

bitFieldElSt	: BIT_FIELD_SYM
		{
		    Symbol_PushScope($1->data.symBitField.localSymbols);
		    $$ = $1;
		}
		;

bitFieldListXX	: bitFieldListXX ',' bitFieldElXX
		{
		    $$.value = $1.value | $3.value;
		    $$.maskOut = $1.maskOut | $3.maskOut;
		}
		| bitFieldElXX
		;

bitFieldElXX	: '+' bitFieldElSt
		{
		    (void) Symbol_PopScope();
		    $$.value = 1 << $2->data.symBitField.position;
		    $$.maskOut = 0
		}
		| '-' bitFieldElSt
		{
		    (void) Symbol_PopScope();
		    $$.maskOut = 1 << $2->data.symBitField.position;
		    $$.value = 0
		}
		| bitFieldElSt enumCompDef
		{
		    (void) Symbol_PopScope();
		    $$.maskOut = $1->data.symBitField.max
					<< $1->data.symBitField.position;
		    $$.value = $2 << $1->data.symBitField.position;
		}
		| bitFieldElSt CONST_FIXED
		{
		    (void) Symbol_PopScope();
		    if ($2 > $1->data.symBitField.max) {
			yyerror("bit field overflow");
		    }
		    $$.maskOut = $1->data.symBitField.max
					<< $1->data.symBitField.position;
		    $$.value = $2 << $1->data.symBitField.position;
		}
		;

enumCompDef	: ENUM_ELEMENT_SYM
		{
		    $$ = $1->data.symEnum.value;
		}
		;

childList	: childListNN
		| { $$ = NullObjectField; }
		;

childListNN	: childListNN ',' childNN
		| childNN
		;

childNN		: objectOrIdent
		{
		    if (curLastChild != NullObjectField) {
			curLastChild->data.fieldLink.link = $1;
		    } else {
			curFirstChild = $1;
		    }
		    $$ = NewObjectFieldType(curLinkPart);
		    $$->next = $1->data.symObject.firstField;
		    $$->data.fieldLink.parent = curObject;
		    $1->data.symObject.firstField = $$;
		    curLastChild = $$;
		}
		;
anyStringDef	: anyString { $$ = NewObjectFieldString($1); }
		| identOrConst ';' { $$ = NewObjectFieldString($1); }
		;

identOrConst	: IDENT
		| CONST_FLOAT
		{
		    char buf[100];

		    sprintf(buf, "%f",$1);
		    $$ = String_Enter(buf, strlen(buf));
		}
		| CONST_FIXED
		{
		    char buf[100];

		    sprintf(buf, "%ld",$1);
		    $$ = String_Enter(buf, strlen(buf));
		}
		;

byteCompDef	: typeNameOrNull anyStringDef
		{
		    $$ = $2;
		    $$->data.fieldByte.type = $1;
		}
		;
wordCompDef	: typeNameOrNull anyStringDef
		{
		    $$ = $2;
		    $$->data.fieldWord.type = $1;
		}
		;
dwordCompDef	: typeNameOrNull anyStringDef
		{
		    $$ = $2;
		    $$->data.fieldDWord.type = $1;
		}
		;

fptrCompDef	: anyStringDef
typeCompDef	: anyStringDef

typeNameOrNull	: '(' STRING ')'
		{
		    $$ = $2;
		}
		| { $$ = NULL; }
		;

nptrCompDef	: OBJECT_SYM { $$ = NewObjectFieldSym($1); }
		| VIS_MONIKER_SYM { $$ = NewObjectFieldSym($1); }
		| HELP_ENTRY_SYM { $$ = NewObjectFieldSym($1); }
		| HINT_LIST_SYM { $$ = NewObjectFieldSym($1); }
		| ACTIVE_LIST_SYM { $$ = NewObjectFieldSym($1); }
		| CHUNK_SYM { $$ = NewObjectFieldSym($1); }
		| IDENT
		{
		    Symbol_PushScope(globalScope);
		    $$ = NewObjectFieldSym( Symbol_Enter($1, UNKNOWN_DATA_SYM,
							SYM_REFERENCED) );
		    (void) Symbol_PopScope();
		}
		| UNKNOWN_DATA_SYM { $$ = NewObjectFieldSym($1); }
		| NULL_TOKEN
		{
		    $$ = NewObjectFieldSym(NullSymbol);
		}
		;

hptrCompDef	: objectOrIdent
		{
		    $$ = NewObjectFieldSym($1);
		}
		| PROCESS
		{
		    $$ = NewObjectFieldSym(processResource);
		}
		| RESOURCE_SYM
		{
		    $$ = NewObjectFieldSym($1);
		}
		| NULL_TOKEN
		{
		    $$ = NewObjectFieldSym(NullSymbol);
		}
		;

chunkDef	: chunkDataDef
		| IGNORE_DIRTY chunkDataDef
		{
		    $$.chData = $2.chData;
		    $$.chData.chunkFlags |= SYM_IGNORE_DIRTY
		}
		;
chunkDataDef	: anyString
		{
		    $$.chData.chunkFlags = SYM_CHUNK_IS_TEXT;
		    $$.chData.data.chunkText = $1;
		    $$.chDataType = CDT_text;
		}
		| DATA anyString
		{
		    $$.chData.chunkFlags = 0;
		    $$.chData.data.chunkText = $2;
		    $$.chDataType = CDT_unknown;
		}
		| EMPTY ';'
		{
		    $$.chData.chunkFlags = SYM_CHUNK_IS_EMPTY;
		    $$.chData.data.chunkText = NULL;
		    $$.chDataType = CDT_unknown;
		}
		| STRUCTURE_SYM
		    {
			Symbol_PushScope( $1->data.symStructure.localSymbols );
			$<sym>$ = curStructureComp;
			curStructureComp =
				$1->data.symStructure.firstField;
		    }
		    structureCompDef
		    {
			(void) Symbol_PopScope();
			curStructureComp = $<sym>2;
			$$.chData.chunkFlags = SYM_CHUNK_IS_STRUCTURE;
			$$.chData.data.chunkStructure.strucType = $1;
			$$.chData.data.chunkStructure.strucData = $3;
			$$.chDataType = CDT_unknown;
		    }
		| GSTRING '{'
		{
		    scanStringEndBrace = TRUE;
		}
		  STRING
		{
		    scanStringEndBrace = FALSE;
		}
		  '}'
		{
		    $$.chData.chunkFlags = 0;
		    $$.chData.data.chunkText = $4;
		    $$.chDataType = CDT_GString;
		}
		;

localization	: LOCALIZE STRING ',' CONST_FIXED ',' CONST_FIXED ';'
		{
		    NEW_LOC($$,$2,$4,$6);
		}
		| LOCALIZE STRING ',' CONST_FIXED ';'
		{
		    NEW_LOC($$,$2,0,$4);
		}
    		| LOCALIZE STRING ';'
		{
		    NEW_LOC($$,$2,0,0);
		}
    		| LOCALIZE NOT ';' 
		{
		    NEW_LOC($$,"",-1,-1);
		}
		;
localizationLine: localization
		{
		    if (lastChunk == NullSymbol) {
			yyerror("you've not defined a chunk chat could be localized");
		    } else if (lastChunk->data.symChunk.loc != NULL) {
			yyerror("you've already specified localization info for %s",
				lastChunk->name);
		    } else {
			$1->dataTypeHint = lastChunkType;
			lastChunk->data.symChunk.loc = $1;
			lastChunk->flags |= SYM_LOC;
			localizationRequired = 0;
		    }
		}
		;


anyString	: '{'
		    {
			scanStringEndBrace = TRUE;
		    }
		    STRING
		    {
			scanStringEndBrace = FALSE;
		    }
		    '}'
		    {
			$$ = $3;
		    }
		| STRING ';'
		;

activeListCompDef	: activeListNN ';'
		{
		    $$ = $1;
		}
		| ';'
		{
		    $$ = NullObjectField;
		}
		;

activeListNN	: activeListNN ',' activeNN
		{
		    ObjectField **of;

		    $$ = $1;
		    if ($$ == NullObjectField) {
			$$ = $3;
		    } else {
			for (of = &($$->next); *of != NullObjectField;
						of = &((*of)->next));
			*of = $3;
		    }
		}
		| activeNN
		;

activeNN	: objectOrIdent
		{
		    $$ = NewObjectFieldSym($1);
		}
		;

optrCompDef	: PROCESS ',' identOrConst
		{
		    $$ = NewObjectFieldString($3);
		    $$->data.fieldOptr.type = OPTR_PROCESS;
		}
		| PROCESS ',' STRING
		{
		    $$ = NewObjectFieldString($3);
		    $$->data.fieldOptr.type = OPTR_PROCESS;
		}
		| PROCESS
		{
		    $$ = NewObjectFieldString(NULL);
		    $$->data.fieldOptr.type = OPTR_PROCESS;
		}
		| objectOrIdent
		{
		    $$ = NewObjectFieldSym($1);
		    $$->data.fieldOptr.type = OPTR_OBJECT;
		}
		| CHUNK_SYM
		{
		    $$ = NewObjectFieldSym($1);
		    $$->data.fieldOptr.type = OPTR_OBJECT;
		}
		| STRING
		{
		    $$ = NewObjectFieldString($1);
		    $$->data.fieldOptr.type = OPTR_STRING;
		}
		| OPTR_COMP STRING
		{
		    $$ = NewObjectFieldString($2);
		    $$->data.fieldOptr.type = OPTR_STRING_OPTR;
		}
		| NULL_TOKEN
		{
		    $$ = NewObjectFieldString(NULL);
		    $$->data.fieldOptr.type = OPTR_NULL;
		}
		;

actionCompDef	: methodOrIdent ',' optrCompDef
		{
		    $$ = $3;
		    $$->data.fieldAction.method = $1;
		}
		| NULL_TOKEN
		{
		    $$ = NewObjectFieldString(NULL);
		    $$->data.fieldAction.type = OPTR_OBJECT;
		    $$->data.fieldAction.method = NullSymbol;
		}
		;

methodOrIdent	: METHOD_SYM
		| identOrConst
		{
		    $$ = Symbol_Enter($1, METHOD_SYM, SYM_REFERENCED);
		}
		;

	/*
	 * Keyboard accelerators:
	 *
	 * Push kbdAcceleratorScope so that we get all the special stuff
	 */

kbdAcceleratorCompStart :
		    {
			Symbol_PushScope(kbdAcceleratorScope);
		    }
		;

kbdAcceleratorCompDef	: specificUIOrNothing kbdAccelModList CHAR
		{
		    $$ = (ObjectField *) calloc(1, sizeof(ObjectField) );
		    $$->data.fieldKbdAccelerator.specificUI = $1;
		    $$->data.fieldKbdAccelerator.flags = $2;
		    if (isupper($3)) {
			$3 = tolower($3);
		    }
		    if (isalpha($3)) {
			$$->data.fieldKbdAccelerator.key =
						(KEY_ALPHA << 16) | $3;
		    } else if (isdigit($3)) {
			$$->data.fieldKbdAccelerator.key =
						(KEY_DIGIT << 16) | $3;
		    } else if (!$1) {
			yyerror("keyboard accelerator must be alpha-numeric");
			$$->data.fieldKbdAccelerator.key =
						(KEY_ALPHA << 16) | 'a';
		    } else {
			$$->data.fieldKbdAccelerator.key =
			    	    	    	(KEY_PUNCT << 16) | $3;
		    }
		    (void) Symbol_PopScope();
		}
		|
		specificUIOrNothing kbdAccelModList KBD_SYM
		{
		    $$ = (ObjectField *) calloc(1, sizeof(ObjectField) );
		    $$->data.fieldKbdAccelerator.specificUI = $1;
		    $$->data.fieldKbdAccelerator.flags = $2;
		    $$->data.fieldKbdAccelerator.key =
						$3->data.symSpecial.value;
		    (void) Symbol_PopScope();
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

	/*********/

visMonikerCompStart :
		    {
			Symbol_PushScope(visMonikerScope);
		    }
		;

visMonikerCompDef : IGNORE_DIRTY visMonikerDataDef
 	    	    {
		    	curVisMoniker->flags |= SYM_IGNORE_DIRTY;
			$$ = $2;
		    }
    	    	  | visMonikerDataDef
 	    	    {
			$$ = $1;
		    }
    	    	  ;

visMonikerDataDef : 
		    {
			if (version20) {
			curVisMoniker->data.symVisMoniker.data.nonList.flags=V20_VMT_DEFAULT;
			} else {
			curVisMoniker->data.symVisMoniker.data.nonList.flags=V12_VMT_DEFAULT;
			}
			curVisMoniker->data.symVisMoniker.data.nonList.xSize=0;
			curVisMoniker->data.symVisMoniker.data.nonList.ySize=0;
			haveVMStyle = FALSE;
		    }
		    vmMiddle
		    {
			(void) Symbol_PopScope();
			$$ = $2;
		    }
		;

vmMiddle	: LIST_SYM '{' vmArray '}'
		{
		    curVisMoniker->flags |= SYM_LIST_MONIKER;
		    curVisMoniker->data.symVisMoniker.data.list.firstField = $3;
		    $$ = NULL;
		}
		| vmMiddleNonList
		;
vmMiddleNonList	: vmNavChar ';'
		{
		    $$ = $1;
		}
		| DATA anyString
		{
		    curVisMoniker->flags |= SYM_DATA_MONIKER;
		    $$ = $2;
		}
		| GSTRING anyString
		{
		    curVisMoniker->flags |= SYM_GRAPHIC_MONIKER;
		    curVisMoniker->data.symVisMoniker.data.nonList.flags
							|= VMT_GSTRING;
		    /* default to style = icon */
		    if (!haveVMStyle) {
			curVisMoniker->data.symVisMoniker.data.nonList.flags
					&= ~V20_VMT_STYLE;
			curVisMoniker->data.symVisMoniker.data.nonList.flags
					|= VMS_ICON << V20_VMT_STYLE_FIELD;
		    }
		    $$ = $2;
		}
		| '{' vmList vmNavChar ';' '}'
		{
		    $$ = $3;
		}
		| '{' vmList DATA anyString '}'
		{
		    curVisMoniker->flags |= SYM_DATA_MONIKER;
		    $$ = $4;
		}
		| '{' vmList GSTRING anyString '}'
		{
		    $$ = $4;
		    curVisMoniker->flags |= SYM_GRAPHIC_MONIKER;
		    curVisMoniker->data.symVisMoniker.data.nonList.flags
							|= VMT_GSTRING;
		    /* default to style = icon */
		    if (!haveVMStyle) {
			curVisMoniker->data.symVisMoniker.data.nonList.flags
					&= ~V20_VMT_STYLE;
			curVisMoniker->data.symVisMoniker.data.nonList.flags
					|= VMS_ICON << V20_VMT_STYLE_FIELD;
		    }
		}
		;


vmNavChar	: CHAR ',' STRING
		{
		    $$ = $3;
		    curVisMoniker->data.symVisMoniker.data.
						nonList.nav.navChar = $1;
		}
		| CONST_FIXED ',' STRING
		{
		    $$ = $3;
		    curVisMoniker->data.symVisMoniker.data.
						nonList.nav.navChar = $1;
		    curVisMoniker->flags |= SYM_CONST_NAV_MONIKER;
		}
		| STRING ',' STRING
		{
		    $$ = $3;
		    curVisMoniker->data.symVisMoniker.data.
						nonList.nav.navString = $1;
		    curVisMoniker->flags |= SYM_STRING_NAV_MONIKER;
		}
		| STRING
		{
		    $$ = $1;
		    curVisMoniker->data.symVisMoniker.data.
						nonList.nav.navChar = -1;
		}
		;

vmArray		: vmArray ',' vmArrayElement
		{
		    ObjectField **of;

		    $$ = $1;
		    if ($$ == NullObjectField) {
			$$ = $3;
		    } else {
			for (of = &($$->next); *of != NullObjectField;
						of = &((*of)->next));
			*of = $3;
		    }
		}
		| vmArrayElement
		;

vmArrayElement	: visMonikerOrIdent
		{
		    $$ = NewObjectFieldSym($1);
		}
		| /* empty */
		{
		    $<sym>$ = curVisMoniker;
		    curVisMoniker = Symbol_Enter(ParseSetMonikerListItem(curVisMoniker->name),
						 VIS_MONIKER_SYM,
						 SYM_DEFINED);
		}
		 vmMiddleNonList
		{
		    $$ = NewObjectFieldSym(curVisMoniker);
		    MakeVisMoniker(curVisMoniker, $2);
		    curVisMoniker = $<sym>1;
		}
 	    	| { $$ = NullObjectField; }
		;

vmList		: vmList vmElement
		|
		;

vmElement	: ATTRIBUTES_SYM '=' vmAttrList ';'
		{
		    if (version20) {
			yyerror("No VisMoniker attributes in 2.0");
		    }
		    curVisMoniker->data.symVisMoniker.data.nonList.flags |= $3;
		}
		| ASPECT_RATIO_SYM '=' ASPECT_RATIO_COMP_SYM ';'
		{
		    curVisMoniker->data.symVisMoniker.data.nonList.flags =
		    	(curVisMoniker->data.symVisMoniker.data.nonList.flags
			    & ~VMT_GS_ASPECT_RATIO) | $3->data.symSpecial.value;
		}
		| COLOR_SYM '=' COLOR_COMP_SYM ';'
		{
		    curVisMoniker->data.symVisMoniker.data.nonList.flags =
		    	(curVisMoniker->data.symVisMoniker.data.nonList.flags
				& ~VMT_GS_COLOR) | $3->data.symSpecial.value;
		}
		| STYLE_SYM '=' STYLE_COMP_SYM ';'
		{
		    if (!version20) {
			yyerror("No VisMoniker style in pre-2.0");
		    }
		    curVisMoniker->data.symVisMoniker.data.nonList.flags =
		    	(curVisMoniker->data.symVisMoniker.data.nonList.flags
				& ~V20_VMT_STYLE) | $3->data.symSpecial.value;
		    haveVMStyle = TRUE;
		}
		| SIZE_SYM '=' SIZE_COMP_SYM ';'
		{
		    curVisMoniker->data.symVisMoniker.data.nonList.flags =
		    	(curVisMoniker->data.symVisMoniker.data.nonList.flags
				& ~VMT_GS_SIZE) | $3->data.symSpecial.value;
		}
		| CACHED_SIZE_SYM '=' CONST_FIXED ',' CONST_FIXED ';'
		{
		    curVisMoniker->data.symVisMoniker.data.nonList.xSize = $3;
		    curVisMoniker->data.symVisMoniker.data.nonList.ySize = $5;
		}
		| messageDecl
		| error ';' {}
		| error {}
		;

vmAttrList	: vmAttrList ',' ATTRIBUTES_COMP_SYM
		{
		    $$ = $1 | $3->data.symSpecial.value;
		}
		| ATTRIBUTES_COMP_SYM
		{
		    $$ = $1->data.symSpecial.value;
		}
		;

helpCompDef	: anyString
		;

hintCompDef	: '{' hintList '}'
		{
		    $$ = $2;
		}
		;

hintList	: hintList ',' hintDef
		{
		    $$ = $1;
		    if ($$ == NullObjectField) {
			$$ = $3;
		    } else {
			ObjectField **field;

			for (field = &($$->next);
				*field != NullObjectField;
				field = &((*field)->next));
			*field = $3;
		    }
		}
		| hintDef
		;

hintDef		: hintOrIdent
		{
		    $$ = NewObjectFieldSym($1);
		    $$->data.fieldHintEntry.data = NULL;
		}
		| hintOrIdent anyString
		{
		    $$ = NewObjectFieldSym($1);
		    $$->data.fieldHintEntry.data = $2;
		}
 	    	| { $$ = NullObjectField; }
		;

hintOrIdent	: HINT_SYM
		| identOrConst
		{
		    $$ = Symbol_Enter($1, HINT_SYM, SYM_REFERENCED);
		}
		;

externDecl	: EXTERN IDENT ';'
		{
		    Symbol_PushScope(globalScope);
		    Symbol_Enter($2, UNKNOWN_DATA_SYM, 
				 SYM_REFERENCED|SYM_EXTERNAL);
		    (void) Symbol_PopScope();
		}
		| EXTERN externSym ';'
		{
		    $2->flags |= SYM_EXTERNAL;
		}
		;
externSym	: VIS_MONIKER_SYM | CHUNK_SYM | OBJECT_SYM | STRUCTURE_SYM ;

%%


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
/*VARARGS1*/
void
yyerror(char *fmt, ...)
{
    va_list args;

    va_start(args,fmt);

    fprintf(stderr, "file %s, line %d: ", inFile, yylineno);
    vfprintf(stderr, fmt, args);

    va_end(args);

    putc('\n', stderr);

    yyerrors++;
}


/***********************************************************************
 *				NewObjectField
 ***********************************************************************
 * SYNOPSIS:	  Create a new ObjectField structure
 * CALLED BY:	  misc
 * RETURN:	  Name (entered in string table)
 * SIDE EFFECTS:  Lots
 *
 * STRATEGY:
 *
 ***********************************************************************/

ObjectField *
NewObjectFieldType(Symbol *type)
{
    ObjectField *of;

    of = (ObjectField *) calloc(1, sizeof(ObjectField) );
    of->type = type;
    return(of);
}

ObjectField *
NewObjectFieldString(char *str)
{
    ObjectField *of;

    of = (ObjectField *) calloc(1, sizeof(ObjectField) );
    of->data.fieldByte.value = str;
    return(of);
}

ObjectField *
NewObjectFieldSym(Symbol *sym)
{
    ObjectField *of;

    of = (ObjectField *) calloc(1, sizeof(ObjectField) );
    of->data.fieldHint.hintList = sym;
    return(of);
}

ObjectField *
NewObjectFieldField(ObjectField *field)
{
    ObjectField *of;

    of = (ObjectField *) calloc(1, sizeof(ObjectField) );
    of->data.fieldStructure.firstValue = field;
    return(of);
}


/***********************************************************************
 *				AddDataDef
 ***********************************************************************
 * SYNOPSIS:	  Add a data definition symbol to the current resource
 * CALLED BY:	  misc
 * SIDE EFFECTS:  Lots
 *
 * STRATEGY:
 *
 ***********************************************************************/

void
AddDataDef(Symbol *sym)
{
    if (curResource == NullSymbol) {
	yyerror("object definition outside resource");
    } else if (sym->flags & SYM_DATA_ADDED) {
	yyerror("symbol <%s> multiply defined",sym->name);
    } else if ( (curResource->flags & SYM_DATA_RESOURCE) &&
				( (sym->type == OBJECT_SYM) ||
				  (sym->type == HINT_LIST_SYM) ||
				  (sym->type == ACTIVE_LIST_SYM) ||
				  (sym->type == GCN_LIST_SYM) ||
				  (sym->type == GCN_LIST_OF_LISTS_SYM) ) ) {
	yyerror("illegal definition in data resource");
    } else {
	sym->data.symObject.resource = curResource;
	if (curResource->data.symResource.firstObject == NullSymbol) {
	    curResource->data.symResource.firstObject = sym;
	} else {
	    curResource->data.symResource.lastObject->data.symObject.next = sym;
	}
	curResource->data.symResource.lastObject = sym;
	sym->flags |= SYM_DATA_ADDED;
    }
}


/***********************************************************************
 *				MakeVisMoniker
 ***********************************************************************
 * SYNOPSIS:	  make a vis moniker symbol and init it
 * CALLED BY:	  misc
 * SIDE EFFECTS:  Lots
 *
 * STRATEGY:
 *
 ***********************************************************************/

void
MakeVisMoniker(Symbol *sym, char *data)
{
    /*
     * Check to see if the previous chunk needs localization.
     */
    if ( localizationWarning && localizationRequired ){
	Parse_LastChunkWarning("Missing @localize instruction");
	localizationRequired = 0;
    }

    lastChunk = sym;
    lastChunkType = CDT_visMoniker;
    ParseSetLastChunkWarningInfo();

    sym->flags |= SYM_DEFINED;
    if (data != NULL) {
	sym->data.symVisMoniker.data.nonList.data = data;

	/* Don't give the localization warning if it is a gstring */
	if ( !(sym->flags & SYM_GRAPHIC_MONIKER) ){
	    localizationRequired = 1;
	}
    }
    AddDataDef(sym);
}

void
MakeHelpEntry(Symbol *sym, char *data)
{
    sym->flags |= SYM_DEFINED;
    sym->data.symHelpEntry.text = data;
    AddDataDef(sym);
}

void
MakeHintList(Symbol *sym, ObjectField *data)
{
    sym->flags |= SYM_DEFINED;
    sym->data.symHintList.firstHint = data;
    AddDataDef(sym);
}

void
MakeActiveList(Symbol *sym, ObjectField *data)
{
    sym->flags |= SYM_DEFINED;
    sym->data.symActiveList.firstActive = data;
    AddDataDef(sym);
}

void
MakeChunk(Symbol *sym, ChunkArgs ca, ChunkDataType cdt)
{
    /*
     * Check to see if the previous chunk needs localization.
     */
    if ( localizationWarning && localizationRequired ){
	Parse_LastChunkWarning("Missing @localize instruction");
	localizationRequired = 0;
    }

    /*
     * If this new chunk is localizable, then set the flag.
     */
    if ( cdt == CDT_text ){
	localizationRequired = 1;
    }

    lastChunk = sym;
    lastChunkType = cdt;
    ParseSetLastChunkWarningInfo();

    sym->flags |= SYM_DEFINED;
    sym->flags |= ca.chunkFlags;
    sym->data.symChunk.data = ca.data;
    AddDataDef(sym);
}

/***********************************************************************
 *				FormInstVarName
 ***********************************************************************
 * SYNOPSIS:	Create the name to use with an instance variable that
 * 	    	is localizable (so it doesn't change arbitrarily
 *		between compilations). The name is formed from that of
 *		the current object and the instance variable's name.
 * CALLED BY:	(INTERNAL)
 * RETURN:	string to use, entered into the string table.
 * SIDE EFFECTS:none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 3/93		Initial Revision
 *
 ***********************************************************************/
static char *
FormInstVarName(Symbol	*instvar)
{
    int     len = strlen(curObject->name) + 1 + strlen(instvar->name);
    char    *name = (char *)malloc(len + 1);
    char    *result;
			
    sprintf(name, "%s_%s", curObject->name, instvar->name);
    result = String_Enter(name,len);
    free(name);
    return(result);
}


/***********************************************************************
 *				ParseInit
 ***********************************************************************
 * SYNOPSIS:	  Initialize the parser
 * CALLED BY:	  main
 * SIDE EFFECTS:  Adds symbol to global symbol table
 *
 * STRATEGY:
 *
 ***********************************************************************/
void
Parse_Init(void)
{
    processResource = Symbol_Enter(UniqueName(), PROCESS_RESOURCE_SYM,
								SYM_DEFINED);
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

    if (malloc_size(*state) != 0) {
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
 *				Parse_LastChunkWarning
 ***********************************************************************
 * SYNOPSIS:	    Display the warning related to the lastChunk.
 * CALLED BY:	    EXTERN
 * RETURN:	    nothing
 * SIDE EFFECTS:    nothing
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	clee	2/ 4/97   	Initial Revision
 *
 ***********************************************************************/
void
Parse_LastChunkWarning (char *fmt, ...)
{
    va_list args;

    va_start(args,fmt);

#if defined(unix) || defined(_WIN32)
    fprintf(stderr, "file %s, line %d: Warning: ", 
	    lastChunkFile, lastChunkLine);
#else
    fprintf(stderr, "Warning %s %d: ",
	    lastChunkFile, lastChunkLine);
#endif
    vfprintf(stderr, fmt, args);

    va_end(args);

    putc('\n', stderr);

}	/* End of Parse_LastChunkWarning.	*/


/***********************************************************************
 *				ParseSetLastChunkWarningInfo
 ***********************************************************************
 * SYNOPSIS:	    Set the file name and line number for the lastChunk.
 * CALLED BY:	    MakeChunk(), MakeVisMoniker()
 * RETURN:	    nothing
 * SIDE EFFECTS:    
 *		lastChunkLine and lastChunkFile are set.
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	clee	2/ 4/97   	Initial Revision
 *
 ***********************************************************************/
static void
ParseSetLastChunkWarningInfo (void)
{
    /* Set the line number */
    lastChunkLine = yylineno;

    /* Set the file name */
    if ( lastChunkFile == NULL ){
	lastChunkFile = (char *) malloc (sizeof(char) * strlen(inFile) + 1);
	strcpy(lastChunkFile, inFile);
    } else if ( strcmp(inFile, lastChunkFile) != 0 ){
	lastChunkFile = (char *) realloc (lastChunkFile,
					 sizeof(char) * strlen(inFile) + 1);
	strcpy(lastChunkFile, inFile);
    }
}	/* End of ParseSetLastChunkWarningInfo.	*/


/***********************************************************************
 *				ParseSetMonikerListItem
 ***********************************************************************
 * SYNOPSIS:	    Create the symbolic name for the list item of 
 *                  the moniker list.
 * CALLED BY:	    Parser
 * RETURN:	    Symbolic name
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	clee	3/ 3/97   	Initial Revision
 *
 ***********************************************************************/
static char *
ParseSetMonikerListItem (char* prefix)
{
    char	temp[60];	

    sprintf(temp, "%s_uic_%d", prefix, uniqueCount);
    uniqueCount++;
    return( String_Enter(temp, strlen(temp)) );
}	/* End of ParseSetMonikerListItem.	*/
