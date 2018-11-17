/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Symbol Handling Functions
 * FILE:	  symbol.h
 *
 * AUTHOR:  	  Adam de Boor: Aug 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Interface definition for Sym module
 *
 *
 * 	$Id: symbol.h,v 3.14 93/09/19 18:08:54 adam Exp $
 *
 ***********************************************************************/
#ifndef _SYMBOL_H_
#define _SYMBOL_H_

#include    <objfmt.h>
#include    <localize.h>

/****************************************************************************
 *
 * Extra data kept for a class symbol (separated to keep Symbol small)
 *
 ***************************************************************************/
typedef struct {
    SymbolPtr	    methods;	/* Enum type for methods */
    SymbolPtr	    base;   	/* Structure type for base */
    SymbolPtr	    vardata;	/* Enum type for vardata tags */
    Opaque  	    bindings;	/* BINDING symbols */
    Opaque  	    noreloc;	/* List of things that should not be relocated
				 * for the class */
    int	    	    flags;  	/* Flags for class: */
#define SYM_CLASS_MASTER    0x00000001	/* Top of a master group */
#define SYM_CLASS_VARIANT   0x00000002	/* Superclass unknown */
#define SYM_CLASS_CHECKING  0x00000004	/* Checking class for relativity (see
					 * CheckRelated in parse.y) */
#define SYM_CLASS_FORWARD   0x00000008	/* Class was declared forward by an
					 * ahead-of-its-time uses directive --
					 * it hasn't really been declared yet */
    int	    	    numUsed;	/* Number of classes whose methods are
				 * explicitly allowed to be bound to handlers
				 * for this class */
    SymbolPtr	    used[LABEL_IN_STRUCT];
}	ClassData;

/*****************************************************************************
 *
 * Extra data kept for a segment symbol
 *
 ****************************************************************************/
typedef struct {
    Opaque  	    fixPriv;	/* Data private to Fix module */
    unsigned long   align:8,  	/* Alignment (mask of bits to clear) */
	     	    comb:4;   	/* Combine type */
    ID  	    class;	/* Segment class */
    unsigned short  offset; 	/* Offset into map block of descriptor */
    SymbolPtr	    pair;   	/* Paired segment (for LMem segments) */
    int		    inited;	/* Non-zero if initialized (for LMem) */
    int	    	    lastdot;	/* Value of $ when segment last closed */
    int	    	    checkLabel:1,   /* Non-zero if should check for some sort of
				     * label at the current address when
				     * generating code */
		    blockStart:1;   /* Non-zero if next instruction is the
				     * start of a basic block */
    int    	    lastLabel;	/* Address of most-recently defined label for
				 * the segment */
    word    	    segment;	/* Segment address, if absolute */
    SymbolPtr	    first;  	/* Head of symbols-by-address list */
    SymbolPtr	    last;   	/* Tail of symbols-by-address list */
    SymbolPtr	    lastLine;	/* Last line number entered */
    VMBlockHandle   lastSym;	/* Last block in symbol chain (for write-out)*/
} 	SegData;    

/*****************************************************************************
 *
 * Structure for an individual symbol. Each symbol has a name, a type, and
 * some type-specific information.
 *
 ****************************************************************************/
/*
 * Type of a symbol 
 */
typedef enum {
    SYM_VAR,	    	/* Variable */
    SYM_LABEL,	    	/* Regular label */
    SYM_LOCALLABEL,	/* Label local to a procedure. Uses the label data */
    SYM_PROC,	    	/* Procedure */
    SYM_LINE,	    	/* Line number mapping */
    SYM_CLASS,	    	/* Object class */
    SYM_CHUNK,	    	/* LMem chunk */
    SYM_ONSTACK,    	/* Stack descriptor */
    SYM_PROFILE_MARK,	/* Basic-block profiling code */
    SYM_LASTADDR,   	/* MARKER: Last symbol w/associated offset */

    SYM_BITFIELD,	/* Field in a RECORD */
    SYM_FIELD,	    	/* Field in a STRUC */
    SYM_STRUCT,	    	/* STRUC definition */
    SYM_UNION,	    	/* UNION definition */
    SYM_MACRO,	    	/* Macro definition */
    SYM_NUMBER,	    	/* = definition */
    SYM_STRING,	    	/* EQU definition */
    SYM_SEGMENT,	/* SEGMENT name */
    SYM_GROUP,	    	/* GROUP name */
    SYM_ENUM,	    	/* Member of enumerated type */
    SYM_ETYPE,	    	/* Enumerated type */
    SYM_TYPE,	    	/* Typedef */
    SYM_METHOD,	    	/* Method constant */
    SYM_INSTVAR,	/* Instance variable */
    SYM_PUBLIC,	    	/* Grossness to handle forward-referencing PUBLIC
			 * and GLOBAL directives */
    SYM_RECORD,	    	/* RECORD definition */
    SYM_LOCAL,	    	/* Local variable (stack-relative) */
    SYM_BINDING,    	/* Binding of procedure to method */
    SYM_VARDATA,    	/* VarData type */
    SYM_INHERIT,    	/* Inherit-local-vars-from placeholder; name is source
			 * procedure */
    SYM_PROTOMINOR    	/* ProtoMinor type */
}	SymType;

#define SYM_ANY	SYM_LASTADDR	/* Type to pass to Sym_Find to tell it to
				 * find any type of symbol */

typedef struct _Symbol {
    SymType 	  	type:16;    /* Symbol's type */
    short    	  	flags;      /* Flags for the symbol (low 8 bits go
				     * into the object file): */
#define SYM_GLOBAL	0x0001      	/* Symbol defined as global */
#define SYM_UNDEF	0x0002      	/* Symbol not defined yet */
#define SYM_REF	    	0x0004	    	/* Symbol referenced */
#define SYM_NAMELESS	0x0020	    	/* Symbol's name is fake and not for
					 * human consumption */

#define SYM_NOWRITE   	0x0100	    	/* Symbol is not to be written to
					 * the output file. Used for local
					 * symbols ($ and <n>$) to alert
					 * the fixup module it must do
					 * special things */
#define SYM_PERM    	0x0200	    	/* Symbol's name is in permanent
					 * storage already */
    ID    	  	name;	    /* Symbol's name */
    struct _Symbol	*segment;   /* Segment in which it's defined */
    /*
     * Type-specific data. NOTE: These are all no more than 16 bytes long.
     * They should be kept that way to keep memory usage "low".
     */
    union {
	/*
	 * Data left when symbol has been written to the file.
	 */
	struct {
	    int	    	    addr;   /* Space left to keep the "address" part
				     * of the symbol data valid, allowing
				     * constants involving symbols to be
				     * written to the file correctly. */
	    unsigned short  offset; /* Offset into block of ObjSym record */
	    VMBlockHandle   block;  /* Block in which ObjSym record resides */
	}   	    	objsym;

	/*
	 * THINGS WITH ADDRESSES (LOCALLABEL data defined later)
	 */
	struct addrcom {    	      	/* Common info for address-bearing
					 * symbols */
	    int 	    offset; /* Offset of symbol */
	    struct _Symbol  *next;  /* Next in address chain */
	}   	    	addrsym;

	struct {	    	    	/* Label info */
	    struct addrcom  common;
	    int	    	    near;   /* Non-zero if near label */
	    int	    	    unreach;/* Non-zero if unreferenced label is for
				     * unreachable code */
	}   	  	label;
	struct {	    	    	/* Proc info */
	    struct addrcom  common;
	    int	    	    flags;  /* Flags about the procedure: */
#define SYM_NEAR    	    0x0001    	/* Set if procedure near */
#define SYM_WEIRD   	    0x0002    	/* Set if procedure contains an
					 * on_stack directive */
#define SYM_NO_JMP	    0x0004    	/* Set if procedure may not be jumped
					 * to */
#define SYM_NO_CALL 	    0x0008    	/* Set if procedure may not be called */
#define SYM_STATIC  	    0x0010    	/* Static method handler */
#define SYM_PRIVSTATIC	    0x0020    	/* Private static method handler */
#define SYM_DYNAMIC 	    0x0040    	/* Dynamic method handler */
#define SYM_HANDLER 	    0x0080    	/* Method handler */
#define SYM_HANDLER_MASK    0x0070  	    /* Mask of bits to indicate special
					     * method handler */
	    Opaque    	    locals; /* Local symbols. Format known only
				     * to Sym module */
	}   	  	proc;
	struct {	    	    	/* Variable info */
	    struct addrcom  common;
	    TypePtr 	    type;   /* Type of variable */
	}   	  	var;
	struct {    	    	    	/* Line-number info */
	    struct addrcom  common;
	    int	    	    line;   /* Line number */
	    ID    	    file;   /* File name */
	}   	    	line;
	struct {    	    	    	/* Class record */
	    struct addrcom  common;
	    struct _Symbol  *super; /* Super class */
	    SymbolPtr	    instance;/* Structure type for instance */
	    ClassData	    *data;  /* Other stuff used by Obj module */
	}   	    	class;

	struct {    	    	    	/* LMem chunk */
	    struct addrcom  common;
	    TypePtr 	    type;   /* Type of data stored at chunk */
	    word    	    handle; /* Handle to the chunk to be used when
				     * chunk referenced */
	    LocalizeInfo    *loc;
	}   	    	chunk;
	struct {    	    	    	/* Stack descriptor */
	    struct addrcom  common;
	    ID	    	    desc;   /* Descriptor */
	}   	    	onStack;
	
	struct {
	    struct addrcom  common;
	    word    	    markType;
#define SYM_PROF_BBLOCK	    1
#define SYM_PROF_COUNT	    2
	}   	    	profMark;

	/*
	 * STRUCTURED TYPES
	 */
	struct typecom {    	    	/* Common info for types */
	    int    	    size;   /* Number of bytes in type */
	    TypePtr 	    desc;   /* Type descriptor describing the
				     * type, if any */
	}   	    	typesym;

	struct {	    	    	/* Structure type info */
	    struct typecom  common;
	    struct _Symbol  *first; /* First field in type */
	    struct _Symbol  *last;  /* Last field in type */
	}		sType;

	struct {	    	    	/* Enumerated type info */
	    struct typecom  common;
	    struct _Symbol  *mems;  /* List of members */
	    word    	    firstVal;/* First value assigned to type */
	    word    	    nextVal;/* Value for next member */
	    word    	    incr;   /* Increment */
	    byte    	    flags;
#define SYM_ETYPE_PROTOMINOR	    0x01    /* Set if members of the etype are
					     * affected by protominor symbols */
	}		eType;

	struct {    	    	    	/* Typedef info */
	    struct typecom  common;
	    TypePtr 	    type;   /* Description of type */
	}   	    	typeDef;

	struct {    	    	    	/* RECORD type info */
	    struct typecom  common;
	    struct _Symbol  *first; /* First field in type */
	    word   	    mask;   /* Mask for entire record */
	}   	    	record;

	/*
	 * TYPE ELEMENTS. The elements of a structured type are linked into
	 * a list through the u.eltsym.next field of this record. The
	 * final element of the type points back to the type of which
	 * all the elements are a part.
	 */
	struct eltcom {	    	    	/* Type element-common data */
	    struct _Symbol  *next;  /* Next element in type */
	}   	    	eltsym;

	struct {	    	    	/* Structure field info */
	    struct eltcom   common;
	    TypePtr 	    type;   /* Field type */
	    Expr  	    *value; /* Default initial value */
	    int	  	    offset; /* Byte offset of field in structure */
	}   	  	field;
	struct {	    	    	/* Instance variable info */
	    struct eltcom   common;
	    TypePtr 	    type;   /* Variable type */
	    Expr    	    *value; /* Default initial value */
	    short  	    offset; /* Byte offset of field in structure */
	    word    	    flags;  /* Flags for variable */
#define SYM_VAR_PUBLIC	0x0001	    	/* May be accessed by routines other
					 * than handler for owning class
					 * or descendant */
#define SYM_VAR_STATE	0x0002	    	/* Field stored in state block */
#define SYM_VAR_NORELOC	0x0004	    	/* Field should not be entered in the
					 * class's relocation table */
	    struct _Symbol  *class; /* Class to which the variable belongs */
	}   	  	instvar;
	struct {  	    	    	/* Record field info */
	    struct eltcom   common;
	    TypePtr 	    type;   /* Type if field not untyped */
	    Expr  	    *value; /* Default value */
	    short  	    offset; /* Bit offset of field in word */
	    short	    width;  /* Width of field */
	}   	  	bitField;
	struct econst {    	    	    	/* Enum member info */
	    struct eltcom   common;
	    word    	    value;  /* Value of this one */
	    struct _Symbol  *protoMinor;
	}   	    	econst;

	struct {    	    	    	/* VarData member info */
	    struct econst   common;
	    TypePtr 	    type;   /* Type of data stored with tag */
	}   	    	varData;

	struct {    	    	    	/* Method */
	    struct econst   common;
	    
	    word    	    flags;  /* Flags for method: */
#define SYM_METH_PUBLIC	    	0x0001  /* Publicly available */
#define SYM_METH_RANGE	    	0x0002	/* Method is actually the start of
					 * a range */
#define SYM_METH_RANGE_LENGTH 	0xfffc	/* Where the length of the exported
					 * range is stored */
#define SYM_METH_RANGE_LENGTH_OFFSET 2	/* Bit-shift to get to range length */
	    struct _Symbol  *class; /* Class to which it belongs */
	}   	    	method;
	/*
	 * MISCELLANEOUS -- Macro/String stuff are opaque to avoid having
	 * the definitions for macro blocks in this file.
	 */
	struct {  	    	    	/* Numeric/expression equate */
	    Expr	    *value; /* Value of the symbol */
	    int	    	    rdonly; /* Non-zero if defined with EQU and hence
				     * should be considered read-only */
	}   	  	equate;
	struct {  	    	    	/* String equate */
	    void  	    *value; /* The value, ready for interpolating */
	}   	  	string;
	struct {  	    	    	/* Macro */
	    void  	    *text;  /* The macro text */
	    int	    	    numArgs;/* Number of dummy parameters */
	    int	    	    numLocals; /* Number of local labels to define */
	}   	  	macro;
	struct {    	    	    	/* Procedure -> message binding */
	    SymbolPtr	    proc;   /* Handler */
	    byte    	    callType;/* How handler may be called */
	}   	    	binding;

	struct {    	    	    	/* Undefined public symbol */
	    ID	    	    file;   /* File where PUBLIC directive was seen */
	    int	    	    line;   /* Line number of same */
	}   	    	public;

	/*
	 * LOCAL SYMBOLS -- These are chained internally to the symbol module
	 * (i.e. the connections aren't visible to the outside world)
	 */
	struct {    	    	    	/* Local variable (arg or variable) */
	    int	    	    offset; /* Offset from BP */
	    TypePtr 	    type;   /* Type of variable */
	}   	    	localVar;
	struct {    	    	    	/* inherit-locals-from binding */
	    int	    	    done;   /* Non-zero if inheritance resolved */
	    ID	    	    file;   /* File containing .enter inherit */
	    int	    	    line;   /* Line number of same */
	}   	    	inherit;

	/*
	 * SEGMENT STUFF
	 */
	struct {  	    	    	/* Segment info */
	    SegData 	    *data;  /* Data not used as often */
	    Table  	    code;   /* Code in segment */
#define CODE_BYTES_PER	256 	    	/* Bytes per chunk in table */
	}   	  	segment;
	struct {
	    int	  	    nSegs;  /* Number of segments in the group */
	    struct _Symbol  **segs; /* Array of segments in the group */
	    int	    	    offset; /* Offset w/in object header for group */
	}   	  	group;
    }	u;
} Symbol;

#define NullSymbol	((Symbol *)NULL)

#define Sym_IsNear(sym) ((((sym)->type == SYM_LABEL) || \
			  ((sym)->type == SYM_LOCALLABEL)) ? \
			 (sym)->u.label.near : \
			 (((sym)->type == SYM_PROC) ? \
			  ((sym)->u.proc.flags & SYM_NEAR) : 0))
#define Sym_Reference(sym) (((Symbol *)(sym))->flags |= SYM_REF)

typedef int 	SymForEachProc(SymbolPtr sym, Opaque data);

/*
 * Initialize the symbol table, returning the symbol for the global scope
 */
extern SymbolPtr 	Sym_Init(void);

/*
 * Enter a symbol into the current scope.
 */
extern SymbolPtr    	Sym_Enter(ID id, SymType type, ...);

/*
 * Locate a symbol in the current scope
 */
extern SymbolPtr    	Sym_Find(ID id, SymType type,
				 int resolveInherits);

/*
 * Iterate over all segments
 */
extern void 	    	Sym_ForEachSegment(SymForEachProc *func, Opaque data);

/*
 * Iterate over all local symbols for a procedure
 */
extern void 	    	Sym_ForEachLocal(SymbolPtr proc,
					 SymForEachProc *func,
					 Opaque data);

/*
 * Adjust the offsets of all arguments for a procedure by a set amount.
 */
extern void 	    	Sym_AdjustArgOffset(SymbolPtr proc, int adjustment);

extern void		Sym_Adjust(SymbolPtr	seg,
				   int	    	start,
				   int	    	diff);

/*
 * Mark all the local variables and arguments as referenced.
 */
extern void 	    	Sym_ReferenceAllLocals(SymbolPtr proc);

/*
 * Write all segments to the output file. This includes setup of the
 * file header, the segment descriptors, arranging for the write-out of all
 * fixups and segment data.
 */
extern int  	    	Sym_ProcessSegments(void);

/*
 * Bind a procedure to a method in the context of a class.
 */
extern ID   	    	Sym_BindMethod(SymbolPtr    class,
				       ID    	    method,
				       SymbolPtr    proc,
				       byte 	    isStatic);
/*
 * Allocate and enter localization information for a chunk. The fields of
 * the thing are to be filled in later.
 */
extern LocalizeInfo 	*Sym_AllocLoc(SymbolPtr	    sym,
				      ChunkDataType type);

extern void		Sym_SetAddress(SymbolPtr    sym,
				       int  	    offset);

extern void Sym_AddToGroup(SymbolPtr grp, SymbolPtr seg);

#endif /* _SYMBOL_H_ */
