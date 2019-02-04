/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  goc -- Definitions file for symbol module
 * FILE:	  symbol.h
 *
 * AUTHOR:  	  Tony Requist
 *
 * DESCRIPTION:
 *	Header file for symbol module
 *
 * 	$Id: symbol.h,v 1.37 96/07/08 17:39:16 tbradley Exp $
 *
 ***********************************************************************/
#ifndef _SYMBOL_H_
#define _SYMBOL_H_

#include "goc.h"

#include <localize.h>

/********************************************************/
/*	For VisualMonikers and VisualMonikerLists	*/
/********************************************************/

typedef unsigned short word;
typedef unsigned long dword;
typedef dword optr;

typedef struct {
    word	XYS_width;
    word	XYS_height;
} XYSize;

typedef enum /* byte */ {
    DC_TEXT,
    DC_GRAY_1,
    DC_GRAY_2,
    DC_GRAY_4,
    DC_GRAY_8,
    DC_COLOR_2,
    DC_COLOR_4,
    DC_COLOR_8,
    DC_COLOR_RGB
} DisplayClasses;

typedef enum /* byte*/ {
    DS_TINY,
    DS_STANDARD,
    DS_LARGE,
    DS_HUGE
} DisplaySize;

typedef enum /* byte */ {
    DAR_NORMAL,
    DAR_SQUISHED,
    DAR_VERY_SQUISHED
} DisplayAspectRatio;

typedef enum /* byte */ {
    VMS_TEXT,
    VMS_ABBREV_TEXT,
    VMS_GRAPHIC_TEXT,
    VMS_ICON,
    VMS_TOOL
} VMStyle;

typedef struct {
        DisplayClasses		gsColor:4;
        DisplayAspectRatio	aspectRatio:2;
        unsigned		gstring:1;
        unsigned		monikerList:1;
	VMStyle			style:4;
        DisplaySize		gsSize:2;
	unsigned		:2;
} VisMonikerListEntryType;

#define VMLET_GS_SIZE		0x3000
#define VMLET_STYLE		0x0f00
#define VMLET_MONIKER_LIST	0x0080
#define VMLET_GSTRING		0x0040
#define VMLET_GS_ASPECT_RATIO	0x0030
#define VMLET_GS_COLOR		0x000f

#define VMLET_GS_SIZE_OFFSET 12
#define VMLET_STYLE_OFFSET 8
#define VMLET_GS_ASPECT_RATIO_OFFSET 4
#define VMLET_GS_COLOR_OFFSET 0

typedef struct {
    DisplayClasses	color:4;
    DisplayAspectRatio	aspectRatio:2;
    unsigned		gstring:1;
    unsigned		monikerList:1;
} VisMonikerType;

#define VMT_MONIKER_LIST	0x80
#define VMT_GSTRING		0x40
#define VMT_GS_ASPECT_RATIO	0x30	/* DisplayAspectRatio */
#define VMT_GS_COLOR		0x0f	/* DisplayClasses */

#define VMT_GS_ASPECT_RATIO_OFFSET 4
#define VMT_GS_COLOR_OFFSET 0

typedef struct {
     VisMonikerListEntryType	VMLE_type;
     optr			VMLE_moniker;
} VisualMonikerListEntry;

typedef struct {
    VisMonikerType	VM_type;
    XYSize		VM_size;
} VisualMoniker;

typedef enum {
    NT_CHAR,
    NT_CONST,
    NT_STRING
} NavTypes;

/*
 * Maximum depth of open scopes
 */

#define	MAX_SCOPES 10

/*
 * Structure of a scope
*/

typedef struct _Scope {
    struct _Scope *parent;		/* Higher scope */
    int	    	restricted;   	    	/* Non-zero if this scope is
					 * restrictive => lookups shouldn't
					 * proceed down the scope stack
					 * if not found in this one */
    Hash_Table *symbols;		/* Symbols for this scope */
} Scope;

#define NullScope ((Scope *) NULL)

/*
 * Structure of a instance variable value
 */

#define INST_ADD_OPTR		0x00000001

typedef struct _InstanceValue {
    char *name;
    struct _InstanceValue *next;
    char *value;
    union {
	struct {
	    int flags;
	} instReg;
	struct {
	    struct _Symbol *link;
	    int isParentLink;
	} instLink;
	struct {
	    int flags;				/* KS_ flags */
	    int key;
	    int specificUI;
	} instKbdAccelerator;
    } data;
} InstanceValue;

#define NullInstanceValue ((InstanceValue *)NULL)

/*
 * Structure of a vardata value
 */

typedef struct _VardataValue {
    struct _Symbol *type;
    struct _VardataValue *next;
    char *value;
    char *arraySize; /* this is a string containg the size of the hint array */
} VardataValue;

#define NullVardataValue (VardataValue *)NULL

/*
 * Structures used to store vm list elements and active list elements
 */

typedef struct _SymbolListEntry {
    struct _Symbol *entry;
    struct _SymbolListEntry *next;
} SymbolListEntry;

#define NullSymbolListEntry (SymbolListEntry *)NULL

/*
 * Structures used to store relocations
 */

typedef enum {
    RT_FPTR,
    RT_HPTR,
    RT_OPTR
} RelocTypes;

typedef struct _Reloc {
    char *text;
    RelocTypes type;
    struct _Symbol *tag;    /* assoc tag (or NullSymbol for instance data) */
    int count;
    char *structName;  	    /* name of array structure */
    struct _Reloc *next;
} Reloc;

#define NullReloc (Reloc *)NULL


/* 
 * These are used in the parser to store type-decl strings that get 
 * made after scanning things like msg parms, vardata and instance
 * declarations. ONLY USED IN THE PARSER.
 *
 */

typedef struct {
  char *ct;   /* type prefix */
  char *id;   /* identifier  */
  char *ts;   /* type suffix */
}TypeDeclString;



/*
 * Structure used to store message parameters
 */

typedef struct _MessageParam {
    char *name;
    char *ctype;
    char *typeSuffix;
    struct _MessageParam *next;
} MessageParam;

#define NullParam (MessageParam *)NULL

/*
 * Structure used to store methods
 */

typedef enum {
    MM_FAR,
    MM_NEAR,
    MM_BASED
} MethodModels;

#define MTD_MODEL   	    0xc0
#define MTD_PROCESS_CLASS   0x20
#define MTD_RELOC   	    0x10    /* Internal flag only; indicates
				     * method is for reloc/unreloc */
#define MTD_MODEL_OFFSET 6

typedef struct _Method {
    char *name;
    struct _Method *next;
    MethodModels model;
    struct _Symbol *message;
    struct _Symbol *class;
    int htd;	    /* method type def */
} Method;



#define NullMethod (Method *)NULL

/*
 * Structure of a message parameter definition
 */

typedef enum {
    MPR_NONE,
    MPR_CL,
    MPR_CH,
    MPR_DL,
    MPR_DH,
    MPR_CX,
    MPR_DX,
    MPR_BP
} MessagePassRegs;

#define MPD_PASS    	    0x03ff  	/* Bits used to encode params passed */
#define MPD_REGISTER_PARAMS 0x0200  	/* Set if params passed in registers */
 	    	    	    	    	/* If MPD_REGISTER_PARAMS = 1 */
#define MPD_PARAM_3 	    0x01c0  	    /* Reg to put 3st parameter in */
#define MPD_PARAM_2 	    0x0038  	    /* Reg to put 2nd parameter in */
#define MPD_PARAM_1 	    0x0007  	    /* Reg to put 1rd parameter in */
 	    	    	    	    	/* If MPD_REGISTER_PARAMS = 0 */
#define MPD_C_PARAMS 	    0x0100  	    /* Set if params in C style */
 	    	    	    	    	    /* If MPD_C_PARAMS = 1 */
#define MPD_C_PARAM_SIZE    0x00ff  	    	/* Param size (in bytes) */
 	    	    	    	    	    /* If MPD_C_PARAMS = 0 */
#define MPD_STRUCT_AT_SS_BP 0x0080  	    	/* MPD_STRUCT_AT_SS_BP = 1 */
#define MPD_STACK_PARAM_SIZE 0x007f 	    	    /* Single C parameter is a
						     * far pointer to a
						     * structure which must be
						     * copied onto the stack,
						     * passed in ss:bp and
						     * copied back */
 	    	    	    	    	    	/* MPD_STRUCT_AT_SS_BP = 0 */
 	    	    	    	    	    	    /* Multiple paramters
						     * passed on the stack
						     * because they don't fit
						     * in regs.  Pass ss:bp
						     * pointing to the
						     * parameters */

#define MPD_PARAM_3_OFFSET  6
#define MPD_PARAM_2_OFFSET  3
#define MPD_PARAM_1_OFFSET  0

/***/

typedef enum {
    MRT_VOID,
    MRT_BYTE_OR_WORD,
    MRT_DWORD,
    MRT_MULTIPLE
} MessageReturnTypes;

typedef enum {
    MRBWT_AL,
    MRBWT_AH,
    MRBWT_CL,
    MRBWT_CH,
    MRBWT_DL,
    MRBWT_DH,
    MRBWT_BPL,
    MRBWT_BPH,
    MRBWT_AX,
    MRBWT_CX,
    MRBWT_DX,
    MRBWT_BP
} MessageReturnByteWordTypes;

typedef enum {
    MRDWR_AX,
    MRDWR_CX,
    MRDWR_DX,
    MRDWR_BP
} MessageReturnDWordRegs;

typedef enum {
    MRMT_AXBPCXDX,
    MRMT_AXCXDXBP,
    MRMT_CXDXBPAX,
    MRMT_DXCX,
    MRMT_BPAXDXCX,
    MRMT_MULTIPLEAX
} MessageReturnMultipleTypes;

#define MPD_RETURN  	    0xfc00  	/* Bits used to encode return value */
#define MPD_RETURN_TYPE	    0xc000  	/* Type of return value */
#define MPD_RETURN_INFO	    0x3c00  	/* Data based on MPD_RETURN_TYPE: */
#define MPD_RET_WORD_REG    0x3c00  	    /* if MRT_WORD */
#define MPD_RET_DWORD_HIGH  0x3000  	    /* if MRT_DWORD */
#define MPD_RET_DWORD_LOW   0x0c00  	    /* if MRT_DWORD */
#define MPD_RET_MULT_TYPE   0x3c00  	    /* if MRT_MULTIPLE */

#define MPD_RETURN_TYPE_OFFSET	   14
#define MPD_RET_WORD_OFFSET	   10
#define MPD_RET_DWORD_HIGH_OFFSET  12
#define MPD_RET_DWORD_LOW_OFFSET   10
#define MPD_RET_MULT_OFFSET	   10

#define RetTypeBWReg(reg) ((MRT_BYTE_OR_WORD << MPD_RETURN_TYPE_OFFSET) | \
		    	    (reg << MPD_RET_WORD_OFFSET))

/*
 * Flags for prototypes made for a message (we don't generate them all because
 * this would a unneeded effort
 */

#define PROTO_ONE_PARAM	    0x01
#define PROTO_TWO_PARAMS    0x02
#define PROTO_OM	    0x10
#define PROTO_ODM	    0x20
#define PROTO_OCS	    0x40

#define PROTO_NUM_PARAMS(a) (a & 0x0f)

/*
 * Structure for an individual symbol. Each symbol has a name, a type, and
 * some type-specific information.
 */

/*
 * Flags in Symbol's flags field
*/

#define SYM_REFERENCED		0x00000000  /* Passed to Symbol_enter */
#define SYM_DEFINED		0x00000001  /* Symbol is defined */
#define SYM_CLASS_MASTER	0x00000002  /* Class is a master class */
#define SYM_CLASS_VARIANT	0x00000004  /* Class is a variant class */
#define SYM_NEVER_SAVED		0x00000008  /* Class is never saved */
#define SYM_IMPORTED		0x00000010  /* Imported message */
#define SYM_PROCESS_CLASS	0x00000020  /* Class is a process class */
#define SYM_OBJECT_BLOCK	0x00000040  /* Resource is an object block */
#define SYM_IS_OBJECT  		0x00000080  /* Chunk is an object */
#define SYM_IGNORE_DIRTY	0x00000100  /* Chunk is ignore dirty */
#define SYM_GSTRING_MONIKER	0x00000200  /* vis moniker is a gstring */
#define SYM_DATA_MONIKER	0x00000400  /* vis moniker is text in data */
#define SYM_LIST_MONIKER	0x00000800  /* vis moniker is a list */
#define SYM_CONST_NAV_MONIKER	0x00001000  /* vis moniker nav char is const */
#define SYM_STRING_NAV_MONIKER	0x00002000  /* vis moniker nav char is string */
#define SYM_NOT_DETACHABLE	0x00004000  /* resource not detachable */
#define SYM_HAS_KBD_ACCEL	0x00008000  /* object has kbd accelerator */
#define SYM_IS_KBD_PATH		0x00010000  /* link field is kbd path */
#define SYM_IS_EMPTY_CHUNK	0x00020000  /* chunk is empty (0 length) */
#define SYM_OBJECT_HAS_VD_RELOC 0x00040000  /* Object has var data relocations */
#define SYM_CHUNK_NEEDS_QUOTES	0x00080000  /* chunk sym needs quotes */
#define SYM_CLASS_HAS_INST_RELOC 0x00100000  /* Class has instance relcoations */
#define SYM_CLASS_HAS_VD_RELOC	0x00200000  /* Class has vardata relcoations */
#define SYM_VARDATA_HAS_RELOC	0x00400000  /* vardata type has relocation */
#define SYM_MULTIPLY_DEFINED   	0x00800000
#define SYM_IS_CHUNK_ARRAY   	0x01000000  /* Chunk is a chunk array */
#define SYM_IS_ELEMENT_ARRAY   	0x02000000  /* Chunk is an element array */
#define SYM_EXTERN  	   	0x04000000  /* Symbol appears in @extern */
#define SYM_CLASS_DECLARED   	0x08000000  /* Class has @classdecl */
#define SYM_CANNOT_BE_EXTERN   	0x10000000  /* Object must be defined */
#define SYM_CLASS_HAS_RELOC 	0x20000000  /* Class has relocation method */
#define SYM_RESOURCE_NOT_LMEM   0x40000000  /* Resource is not an LMem block,
					       and shouldn't be output
					       as such */

/*
 * Structure of a symbol.  All symbol types that have a first/next link put the
 * link at the start of the union structure.
 *
*/

/* NOT WORTH THE TROUBLE 
 *#define UNAME(sym) (sym->uniqueName)
 */
#define NAME(sym) (sym->name)

typedef struct _Symbol {
    int type;				/* type of symbol (parser token) */
    int flags;   	 		/* flags for the symbol: SYM_??? */
    char *name;				/* Symbol name (in string table) */
    /*    char *uniqueName; NOT WORTH THE TROUBLE */
    char *fileName; 	    	    	/* File in which symbol is defined */
    char *realFileName;	    	    	/* REAL File in which symbol is
					 * defined.  This can be different
					   than the other file due to hacks
					   done for MetaWare */
    int lineNumber; 	    	    	/* Line number " " */
    union {

	/* Class symbol (CLASS_SYM) */

	struct {
	    struct _Symbol *superclass;		/* NullSymbol => meta */
	    Scope *localSymbols;    	    	/* instance variables */
	    int masterLevel;			/* # of master classes */
	    int firstMessage;	    	    	/* First message assigned */
	    int nextMessage; 	    	    	/* Next message # to assign */
	    int nextTag;    	    	    	/* Next tag # to assign */

	    struct _Symbol *firstMessagePtr;    /* messages are attached    */
	                                        /* in a list for output of  */
						/* message #s as an enum    */

	    struct _Symbol **nextMessageElementPtr;  /* where to insert MSG */

	    struct _Symbol *instanceData;	/* Instance variables */
	    struct _Symbol *nextDeclaredClass;	/* Next class with @classdecl */
	    Method *firstMethod;	    	/* Linked list of methders */
	    int methodCount;	    	    	/* Number of methods */
	    char *root;
	    Reloc *relocList;	    	    	/* List of relocations */
	    int masterMessages;	    	    	/* record of messages per master
						 * class */
	    InstanceValue *defaultList;	    	/* Linked list of overridden
						   defaults */
	    int	    	  numUsed;	    	/* Number of classes whose
						 * messages are explicitly
						 * allowed to be bound to
						 * handlers for this class */
	    struct _Symbol **used;
	    struct _Symbol *classSeg;           /* Current segment at the
						 * time the class was
						 * declared */
	} symClass;

	/* Message symbol (MSG_SYM) */

	struct {
	    struct _Symbol *class;		/* Class for message */
	    struct _Symbol *nextMessage;	
	    int messageNumber;			/* #  */
	    int mpd;	    	    	  	/* Parameter definition */
	    char *mpdString;	    	    	/* string for mpd (can contain
						 * sizeof stuff */
	    MessageParam *firstParam;	    	/* List of parameters */
	    char *returnType;	    	    	/* Return type */
	    struct _Symbol *protoMinor;         /* Active protoMinor */
	} symMessage;

	/* Exported messages symbol (EXPORT_SYM) */

	struct {
	    struct _Symbol *class;		/* Class for exported range */
	    int firstMessage;	    	    	/* First message assigned */
	    int nextMessage; 	    	    	/* Next message # to assign */
	} symExport;

	/* Vardata symbol (VARDATA_SYM) */

	struct {
	    struct _Symbol *class;
	    int tag;
	    char *ctype;    	    	    	/* c type for vardata */
	    char *typeSuffix;
	    struct _Symbol *protoMinor;         /* Active protoMinor */
	} symVardata;

	/* ProtoMinor symbol (PROTOMINOR_SYM) */

	struct {
	    struct _Symbol *msgOrVardataSym;
	    int references;    	    	    	/* # of references to sym */
	} symProtoMinor;

	/* Resource symbol (RESOURCE_SYM) */

	struct {
	    int numberOfChunks;
	    struct _Symbol *firstChunk;	    	/* Linked list of chunks */
	    struct _Symbol *nextResource;
	    char *header_ctype;    	    	/* Custom header */
	    char *header_initializer;
	    struct _Symbol *resourceOutput;
	} symResource;

	/* Chunk symbol (CHUNK_SYM) */

#define CHUNK_LOC(chunk) ((chunk)->data.symChunk.loc)
	struct {
	    struct _Symbol *nextChunk;
	    struct _Symbol *resource;
	    LocalizeInfo       *loc;
	    
	    char 	*data;	    	    	    	/* Chunk's data */
	    char 	*ctype;
	    char 	*typeSuffix;
	    char 	*headerType;
	    char 	*headerData;
	} symChunk;

	/* Object symbol (OBJECT_SYM) */

	struct {
	    struct _Symbol *nextChunk;
	    struct _Symbol *resource;
	    LocalizeInfo       *loc;

	    struct _Symbol *class;
	    InstanceValue *firstInstance;
	    struct _Symbol *kbdPathParent;
	    VardataValue *vardata;
	    struct _Symbol *gcnListOfLists;
	} symObject;

	/* Vis moniker symbol (VIS_MONIKER_CHUNK_SYM) */

	struct {
	    struct _Symbol *nextChunk;
	    struct _Symbol *resource;
	    LocalizeInfo       *loc;

	    SymbolListEntry *list;
	    VisMonikerListEntryType vmType;
	    int vmXSize, vmYSize;
	    char *vmText;
	    int  startLine;
	    NavTypes navType;
	    char navChar;
	    int navConst;
	    char *ctype;
	    char *navString;
	} symVisMoniker;

	/* Active list symbol (ACTIVE_LIST_CHUNK_SYM) */

	struct {
	    struct _Symbol *nextChunk;
	    struct _Symbol *resource;
	    LocalizeInfo       *loc;

	    SymbolListEntry *list;
	} symActiveList;

	/* GCN List symbol */

	struct {
	    struct _Symbol *nextChunk;		/* next chunk */
	    struct _Symbol *resource;		/* resource containing data */
	    LocalizeInfo       *loc;

	    char *manufID;			/* GCN list manufacturer ID */
	    char *type;				/* GCN list type */
	    SymbolListEntry *firstItem;		/* first GCN list item ptr */
	    struct _Symbol *nextList;		/* next GCN list */
	} symGCNList;

	/* GCN List of Lists symbol */

	struct {
	    struct _Symbol *nextChunk;		/* next chunk */
	    struct _Symbol *resource;		/* resource containing data */
	    LocalizeInfo       *loc;

	    struct _Symbol *firstList;		/* first GCN list ptr */
	} symGCNListOfLists;

	/* ***** Instance data symbols ***** */

	/* Normal (non-special instance variable) (REG_INSTANCE_SYM) */
	/* Variant superclass instance variable (VARIANT_PTR_SYM) */

	struct {
	    struct _Symbol *next;		/* Next instance variable */
	    char *ctype;
	    char *defaultValue;			/* Default value */
	    char *typeSuffix;
	} symRegInstance;

	/* Composite part instance variable (COMPOSITE_SYM) */

	struct {
	    struct _Symbol *next;		/* Next instance variable */
	    char *ctype;
	    struct _Symbol *linkPart;	    	/* Corresponding link part */
	} symComposite;

	/* Special symbol (used as part of visMoniker scope and kbd scope */

	struct {			/* Special for vis monikers */
	    int value;				/* value */
	} symSpecial;

    }	data;
} Symbol;


#define	NullSymbol ((Symbol *) NULL)

/*
 * Exported function definitions.
 */

#define	LOCAL_SCOPE	0	/* Symbol_Find: search local scope only */
#define	ALL_SCOPES	1	/* Symbol_Find: search all scopes */

extern Symbol *
    Symbol_Enter(char *name, int type, int flags);

extern void
Symbol_ClassUses(Symbol *class, Symbol *used);

Symbol *
Symbol_EnterWithLineNumber(char *name, int type, int flags,int lineNumber);

extern Symbol *
    Symbol_Find(char *name, int allScopes);

extern void
    Symbol_Init(void);

extern void
    Symbol_PushScope(Scope *scope);

extern Scope *
    Symbol_PopScope(void);

extern void 
    Symbol_PopScopeTo(Scope *);

extern void
    Symbol_OutputProtoMinorRelocations(char *inFileName);

extern int
    Symbol_ReplaceScope(Scope *old, Scope *new);

extern Scope *
    Symbol_NewScope(Scope *scope, int);

extern Scope **scopePtr;
extern Scope *ScopeArray[];

extern Scope *visMonikerScope;
extern Scope *kbdAcceleratorScope;

#define currentScope (*scopePtr)
#define globalScope (ScopeArray[0])


/* 
 * When we read a message arg for one of the kernel object functions,
 * we have two things: the internal symbol for the message, which
 * we use to determine it return type and params to pass, and the 
 * message number.
 */

#define MSG(a) ((a)->msg)
#define MSG_OUT(a) ((a)->ascii)

typedef struct _SentMessage {
    Symbol 	*msg;        /* the internal symbol for the message arg */
    char 	ascii[200];  /* what to output. Just a number for now 	*/
}SentMessage;




/* 
 * The parser returns objDests because and object destination has too
 * many parts to it to make it a simple value.
 *
 * 'dest' should be output in the call to PC/GEOS's object function.
 *
 * 'destType' tells if 'dest' is one or two args.
 *
 * 'children' (a string) is the args that should be output to the call
 * to CObjSendToChildren().
 */

typedef struct {
    char dest[200];		/* ascii output for file to generate dest */
    int  destType;		/* describes dest (number of params)      */
    char children[200];         /* ascii output for file to gen. children */

} ObjDest;


#define DEST(a)  	((a)->dest)
#define DEST_TYPE(a)	((a)->destType)
#define OBJ_CHILDREN(a) ((a)->children)

#define HAS_CHILDREN(a) (*OBJ_CHILDREN(a) != '\0')

#define SET_OBJ_DEST(a,dest,type,children) \
       do{                                 \
        strcpy(DEST(a),(dest));            \
	DEST_TYPE(a) = (type);             \
	strcpy(OBJ_CHILDREN(a),(children));\
       }while(0)


/* all calls are even integers to make detection quick. */

#define IS_CALL_TYPE(a) (!(((int)(a)) & 0x1))

typedef enum  {
    MIT_CALL	=0,       /* CALL */
    MIT_RECORD	=1,    
    MIT_CALLSUPER	=2,       /* CALL */
    MIT_DISPATCH	=3,
    MIT_DISPATCHCALL=4,       /* CALL */
    MIT_SEND	=5,    
} MsgInvocType;

/* 
 * tells whether a message invocation should:
 *     1. pass and receive params as the MSG being sent does
 *     2. pass as the message does, but return an EventHandle -- for MF_RECORD
 *     3. don't pass anything, but return as the message does -- MF_DISPATCH
 */
typedef enum {
    MPD_PASS_AND_RETURN,               /* Normal messages               */
    MPD_PASS_ONLY_RETURN_EVENT_HANDLE, /* @record, msg sent to children */
    MPD_RETURN_ONLY,                   /* dispatched messages           */
    MPD_PASS_VOID_RETURN_VOID,         /* @dispatch                     */
    MPD_PASS_ONLY_RETURN_VOID,         /* don't return anything         */
}MsgParamPassEnum;

/* this tells how the MsgInvocType passes params */

/* we call it static so we can put it here (next to the other two defns)*/
/* and yet not cause trouble with multiple symbols while linking	*/

#define PARAM_ENUM(__mpp_enum) (sym_ParamTable[(int) (__mpp_enum)])

/*
 *  If it has chilren, we must return the eventhandle.
 *  otherwise, look up the way to return values.
 */
#define COMPLEX_PARAM_ENUM(mpp,dest) \
    (HAS_CHILDREN(dest)?PARAM_ENUM(MIT_RECORD):PARAM_ENUM(mpp))

extern MsgParamPassEnum sym_ParamTable[];


/* 
 *  a call to CObjMessage must have its MF_RECORD bit set if it is an 
 *  @record call, or the message is sent to the children.
 */
#define HAS_RECORD_FLAG(is_record,send_to_children) \
    ((is_record)==MIT_RECORD || (send_to_children))


/* return the record flag based on the kind of msg invocation and whether */
/* or not the message goes to the children (which requires an eventhandle */

#define RECORD_FLAG(type,children) \
    (HAS_RECORD_FLAG((type),HAS_CHILDREN(children))?MF_RECORD:0) 

/*
 *  the MF_CALL flag if the msg invocation takes it, or zero
 */
#if 0
#define CALL_FLAG(type) (IS_CALL_TYPE(type)?MF_CALL:0)
#else
#define CALL_FLAG(type) ((IS_CALL_TYPE(type) && type != MIT_SEND)?MF_CALL:0)
#endif


#endif /* _SYMBOL_H_ */


