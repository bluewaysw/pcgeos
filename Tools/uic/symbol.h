/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  uic -- Definitions file for symbol module
 * FILE:	  symbol.h
 *
 * AUTHOR:  	  Tony Requist
 *
 * DESCRIPTION:
 *	Header file for symbol module
 *
 * 	$Id: symbol.h,v 2.21 93/02/03 19:47:28 adam Exp $
 *
 ***********************************************************************/
#ifndef _SYMBOL_H_
#define _SYMBOL_H_

#include <localize.h>
/*
 * Maximum depth of open scopes
 */

#define	MAX_SCOPES 10

/*
 * Structure of a scope
*/

typedef struct _Scope {
    struct _Scope *parent;		/* Higher scope */
    int	    	restrict;   	    	/* Non-zero if this scope is
					 * restrictive => lookups shouldn't
					 * proceed down the scope stack
					 * if not found in this one */
    Hash_Table *symbols;		/* Symbols for this scope */
} Scope;

#define NullScope ((Scope *) NULL)

typedef enum _optrTypes {
    OPTR_NULL,
    OPTR_PROCESS,
    OPTR_STRING,
    OPTR_STRING_OPTR,
    OPTR_OBJECT
} optrTypes;

/*
 * Structure of a field element.  Fields are stored in a linked list for each
 * object.
 *
 */
typedef struct _ObjectField {
    struct _Symbol *type;		/* Type of field */
    struct _ObjectField *next;		/* Next field in linked list */
    union {
	struct {			/* Structure field definition: */
	    struct _ObjectField *firstValue;	/* First field of struct */
	} fieldStructure;
	struct {			/* Type definition (for typeComp) : */
	    char *value;			/* Value of field */
	} fieldType;
	struct {			/* Byte definition: */
	    char *value;			/* Value of field */
	    char *type;				/* Type of field (if any) */
	} fieldByte;
	struct {			/* Word definition: */
	    char *value;			/* Value of field */
	    char *type;				/* Type of field (if any) */
	} fieldWord;
	struct {			/* DWord definition: */
	    char *value;			/* Value of field */
	    char *type;				/* Type of field (if any) */
	} fieldDWord;
	struct {			/* fptr definition: */
	    char *value;			/* Value of field */
	} fieldFptr;
	struct {			/* Bit field definition: */
	    int value;				/* Numeric value */
	    int maskOut;
	    int modifiesDefault;		/* True if default -x, +x */
	} fieldBitField;
	struct {			/* Enumerated definition: */
	    int value;				/* Numeric value */
	} fieldEnum;
	struct {			/* Composite definition: */
	    struct _Symbol *firstChild;		/* First child */
	} fieldComposite;
	struct {			/* LinkPart data definition: */
	    struct _Symbol *link;		/* Next child */
	    int isParentLink;			/* Flag: link to parent */
	    struct _Symbol *parent;		/* Parent (for path bits) */
	} fieldLink;
	struct {			/* Vis moniker definition: */
	    struct _Symbol *moniker;		/* Definition of moniker */
	} fieldVisMoniker;
	struct {			/* Kbd accelerator definition: */
	    int flags;				/* KS_ flags */
	    int key;
	    int specificUI;
	} fieldKbdAccelerator;
	struct {			/* Hint list definition: */
	    struct _Symbol *hintList;		/* Definition of hint list */
	} fieldHint;
	struct {			/* Help definition: */
	    struct _Symbol *helpEntry;		/* Definition of help entry */
	} fieldHelp;
	struct {			/* Output desc definition: */
	    union {
		struct {
		    struct _Symbol *dest;	/* Dest object */
		} obj;
		struct {
		    char *extra;		/* Extra data */
		} proc;
	    } data;
	    optrTypes type;			/* True if process OD */
	} fieldOptr;
	struct {			/* Action desc definition: */
	    union {
		struct {
		    struct _Symbol *dest;	/* Dest object */
		} obj;
		struct {
		    char *extra;		/* Extra data */
		} proc;
	    } data;
	    optrTypes type;			/* True if process OD */
	    struct _Symbol *method;		/* Method constant */
	} fieldAction;
	struct {			/* Active list definition: */
	    struct _Symbol *list;		/* element in the list */
	} fieldActiveList;
	struct {			/* Nptr definition */
	    struct _Symbol *target;		/* target of pointer */
	} fieldNptr;
	struct {			/* Hptr definition */
	    struct _Symbol *target;		/* target of pointer */
	} fieldHptr;
	struct {    	    	    	/* Variant super ptr definition */
	    struct _Symbol *target; 	    	/* target of pointer */
	} fieldVariantPtr;

	/*
	 *	To add a component, add a "fieldBiff" structure here
	 */

		/* Used in Hint symbols */

	struct {			/* Children definition: */
	    struct _Symbol *name;		/* Name of hint */
	    char *data;				/* Hint data */
	} fieldHintEntry;

		/* Used in active list symbols */

	struct {			/* Active definition: */
	    struct _Symbol *element;		/* element in the list */
	} fieldActive;

		/* Used in vis moniker list symbols */

	struct {			/* Active definition: */
	    struct _Symbol *element;		/* element in the list */
	} fieldVMElement;

    } data;
} ObjectField;

#define NullObjectField (ObjectField *) NULL

/*
 * Structure for an individual symbol. Each symbol has a name, a type, and
 * some type-specific information.
 */

/*
 * Flags in Symbol's flags field
*/

#define SYM_REFERENCED		0x00000000  /* Passed to Symbol_enter */
#define SYM_DEFINED		0x00000001  /* Symbol is defined */
#define SYM_STATIC		0x00000002  /* Symbol is a static component */
#define SYM_CLASS_MASTER	0x00000004  /* Class is a variant class */
#define SYM_CLASS_VARIANT	0x00000008  /* Class is a master class */
#define SYM_CHUNK_IS_TEXT	0x00000010  /* symChunk defined as text */
#define SYM_CHUNK_IS_EMPTY	0x00000020  /* symChunk defined as empty */
#define SYM_CHUNK_IS_STRUCTURE	0x00000040  /* symChunk defined as empty */
#define SYM_DATA_RESOURCE	0x00000080  /* resource is for data */
#define SYM_GRAPHIC_MONIKER	0x00000100  /* vis moniker is a gstring */
#define SYM_DATA_MONIKER	0x00000200  /* vis moniker is text in data */
#define SYM_DATA_ADDED		0x00000400  /* Symbol is in resource's list */
#define SYM_IGNORE_DIRTY	0x00000800  /* Object needs this bit */
#define SYM_LIST_MONIKER	0x00001000  /* vis moniker is a list */
#define SYM_NOT_DETACHABLE	0x00002000  /* resource is not detachable */
#define SYM_HAS_KBD_ACCEL	0x00004000  /* object has a kbd accelerator */
#define SYM_IS_KBD_PATH		0x00008000  /* composite part is kbd path */
#define SYM_CONST_NAV_MONIKER	0x00010000  /* vis moniker nav char is const */
#define SYM_STRING_NAV_MONIKER	0x00020000  /* vis moniker nav char is string */
#define SYM_VARDATA_RELOC	0x00040000  /* Object needs this bit */
#define SYM_CLASS_FORCE_KBD_PATH 0x00080000 /* Force all objects of class on
					     * kbd path 
					     */
#define SYM_LOC			0x00100000  /* should put out localization 
					     * info for this symbol.
					     */
#define SYM_EXTERNAL	    	0x00200000  /* symbol defined in another
					     * compilation */
/*
 * Structure of a symbol.  All symbol types that have a first/next link put the
 * link at the start of the union structure.
 *
*/

typedef union {
    char *chunkText;			/* textual -- data */
    struct {
	struct _Symbol 	*strucType;
	ObjectField 	*strucData;
    } chunkStructure;			/* structure -- (symStructureComp) */
} ChunkData;

typedef struct _ChunkArgs {
    LocalizeInfo 	loc;
    int 		chunkFlags;
    ChunkData 		data;
} ChunkArgs;

#define CHUNK_LOC(sym) ((sym)->data.symChunk.loc)

typedef struct _Symbol {
    int type;				/* type of symbol (token) */
    int flags;   	 		/* flags for the symbol: */
    char *name;
    union {

			/* Components: */

	struct {
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	    struct _Symbol *structureType;  /* Type of structure */
	} symStructureComp;
	struct {			/* Byte component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	    char *typeName;
	} symTypeComp;
	struct {			/* Byte component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symByteComp;
	struct {			/* Word component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symWordComp;
	struct {			/* DWord component definition: */
	    struct _Symbol *next;   	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symDWordComp;
	struct {			/* Fptr component definition: */
	    struct _Symbol *next;   	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symFptrComp;
	struct {			/* Bit field component definition: */
	    struct _Symbol *next;   	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	    int bitSize;		    /* size in bits */
	    Scope *localSymbols;	    /* Symbols local to scope */
	    int kbdPathMask;		    /* Mask for bit in kbdPath */
	} symBitFieldComp;
	struct {			/* Enum component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	    int bitSize;		    /* size in bits */
	    Scope *localSymbols;	    /* Symbols local to scope */
	} symEnumComp;
	struct {			/* Composite component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	    struct _Symbol *linkSym;	    /* Symbol of associated link */
	} symCompositeComp;
	struct {			/* Link part component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symLinkComp;
	struct {			/* Vis moniker component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symVisMonikerComp;
	struct {			/* Kbd moniker component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symKbdMonikerComp;
	struct {			/* Hint component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symHintComp;
	struct {			/* Help component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symHelpComp;
	struct {			/* optr component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symOptrComp;
	struct {			/* Action desc component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symActionComp;
	struct {			/* Active list component definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symActiveListComp;
	struct {			/* Nptr comp definition: */
	    struct _Symbol *next;	    /* next component */
	    ObjectField *defaultValue;	    /* default value */
	} symNptrComp;
	struct {    	    	    	/* Variant ptr comp definition: */
	    struct _Symbol *next;   	    /* next component */
	    struct _Symbol *class;  	    /* class to which it belongs */
	} symVariantPtr;

	/*
	 *	To add a component, add a "symBiffComp" structure here
	 */

		/* Symbols used for structure like stuff */

	struct {
	    struct _Symbol *next;	    /* next component */
	    struct _Symbol *firstField;	    /* First field of structure */
	    Scope *localSymbols;	    /* Symbols local to structure */
	} symStructure;
	struct {			/* Bit field definition: */
	    int position;			/* mask of field value */
	    int max;				/* maximum field value */
	    Scope *localSymbols;	        /* Symbols local to scope */
	} symBitField;
	struct {			/* Enum definition: */
	    int value;				/* value */
	} symEnum;
	struct {			/* Special for vis monikers */
	    int value;				/* value */
	} symSpecial;

		/* Data generators */

	struct {			/* Object definition: */
	    struct _Symbol *next;		/* next object,moniker */
	    struct _Symbol *resource;		/* resource containing data */
	    struct _Symbol *class;		/* class of object */
	    ObjectField *firstField;		/* first field of obj */
	    struct _Symbol *varData;		/* variable data of object */
	    struct _Symbol *gcnListOfLists;	/* object's gcn list of lists */
	} symObject;
	struct {			/* Moniker definition: */
	    struct _Symbol *next;		/* next object,moniker */
	    struct _Symbol *resource;		/* resource containing data */
	    LocalizeInfo	*loc;	/* localization info for non-lists */

	    union {
		struct {
		    ObjectField *firstField;	/* first mokier on list */
		} list;
		struct {
		    char *data;			/* data field */
		    unsigned short flags;	/* VMT_??? */
		    unsigned short xSize;	/* Cached size */
		    unsigned short ySize;	/* Cached size */
		    union {
			int navChar;		/* Navigation character */
			char *navString;
		    } nav;
		} nonList;
	    } data;
	} symVisMoniker;
	struct {			/* Hint list definition: */
	    struct _Symbol *next;		/* next object,moniker */
	    struct _Symbol *resource;		/* resource containing data */
	    ObjectField *firstHint;		/* first hint */
	} symHintList;
	struct {			/* Help entry definition: */
	    struct _Symbol *next;		/* next object,moniker */
	    struct _Symbol *resource;		/* resource containing data */
	    char *text;				/* text of help */
	} symHelpEntry;
	struct {			/* Active List definition: */
	    struct _Symbol *next;		/* next object,moniker */
	    struct _Symbol *resource;		/* resource containing data */
	    ObjectField *firstActive;		/* first active ptr */
	} symActiveList;
	struct {			/* GCN List definition: */
	    struct _Symbol *next;		/* next object,moniker */
	    struct _Symbol *resource;		/* resource containing data */
	    char *manufID;			/* GCN list manufacturer ID */
	    char *type;				/* GCN list type */
	    ObjectField *firstItem;		/* first GCN list item ptr */
	    struct _Symbol *nextList;		/* next GCN list */
	} symGCNList;
	struct {			/* GCN List Of Lists definition: */
	    struct _Symbol *next;		/* next object,moniker */
	    struct _Symbol *resource;		/* resource containing data */
	    struct _Symbol *firstList;		/* first GCN list ptr */
	} symGCNListOfLists;
	struct {			/* Data chunk definition: */
	    struct _Symbol *next;		/* next object,moniker */
	    struct _Symbol *resource;		/* resource containing data */
	    LocalizeInfo	*loc;	/* localization info for non-lists */
	    ChunkData data;			/* chunk's data */
	} symChunk;

		/* Other */

	struct {			/* Resource definition: */
	    struct _Symbol *nextResource;	/* next resource */
	    struct _Symbol *firstObject;	/* 1st obj in resource */
	    struct _Symbol *lastObject;		/* last obj in resource */
	    struct _Symbol *resourceOutput;
	    int chunkCount;			/* Number of chunks */
	} symResource;
	struct {			/* Class: */
	    struct _Symbol *componentPtr;	/* first component */
	    struct _Symbol *superclass;		/* 0 = meta */
	    ObjectField *firstDefault;		/* first 'default =' field */
	    Scope *localSymbols;		/* Symbols local to scope */
	    int masterLevel;			/* # of master classes */
	} symClass;

#if 0
      /* 
       * This doesn't compile under borlandc and I don't think it used
       * anywhere.
       */
	struct {			/* Process resource definition: */
	} symProcessResource;
#endif
    }	data;
} Symbol;

#define	NullSymbol (Symbol *) NULL

/*
 * Exported function definitions.
 */

#define	LOCAL_SCOPE	0	/* Symbol_Find: search local scope only */
#define	ALL_SCOPES	1	/* Symbol_Find: search all scopes */

extern Symbol *Symbol_Enter(char *, int, int);
extern Symbol *Symbol_Find(char *, int);
extern void Symbol_Init();
extern void Symbol_PushScope(Scope *);
extern Scope *Symbol_PopScope(void);
extern void Symbol_PopScopeTo(Scope *);
extern int Symbol_ReplaceScope(Scope *old, Scope *new);
extern Scope *Symbol_NewScope(Scope *, int);

extern Scope **scopePtr;
extern Scope *ScopeArray[];

#define currentScope (*scopePtr)
#define globalScope (ScopeArray[0])

#endif /* _SYMBOL_H_ */
