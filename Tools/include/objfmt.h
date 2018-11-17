/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat/Esp/Glue -- interface definitions
 * FILE:	  objformat.h
 *
 * AUTHOR:  	  Adam de Boor: June 13, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	6/13/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for the interface between Esp, Glue and Swat.
 *	These definitions govern two types of files: .obj (relocatable
 *	object files, as produced by Esp) and .sym (symbol files, as produced
 *	by Glue. The two files are essentially the same, except the .sym
 *	file contains no object code -- just symbols.
 *
 *	All binary things, other than the object code itself, are written
 *	in the byte-order of the creating machine. The byte-order is recorded
 *	in the header of the file and is dealt with by Glue and Swat,
 *	if the file is taken to a machine with a different byte-order.
 *	More things are in binary than I'd originally intended, as I
 *	decided the taking of a binary from one byte-order machine to
 *	another would be relatively infrequent.
 *	
 *	There are several goals for this file format:
 *	    - Compact
 *	    - Easy to generate
 *	    - Fast to link
 *	    - Symbol table must be modular so Swat can read it in in pieces
 *	    - Similar (if not identical) to OS90 VM file to allow
 *	      easy conversion, or simple copying, to the OS90 debug
 *	      environment, when it gets going.
 *
 *	Due to the segmented architecture, the file itself is segmented.
 *
 * 	$Id: objfmt.h,v 1.2 1996/09/19 03:30:33 jacob Exp $
 *
 ***********************************************************************/
#ifndef _OBJFORMAT_H_
#define _OBJFORMAT_H_

#include <vm.h>
#include <st.h>

/*
 * Get a pointer to the first entry in a block headed by the structure
 * *(basePtr). eltType is the structure type of each element in the array
 * following the header.
 */
#if defined(__GNUC__)
# define ObjFirstEntry(basePtr,eltType) \
    ((eltType *)((void *)(basePtr) + sizeof(*(basePtr))))
#else
# define ObjFirstEntry(basePtr,eltType) \
    ((eltType *)((char *)(basePtr) + sizeof(*(basePtr))))
#endif

/*
 * Return the number of bytes between the two pointers.
 */
#if defined(__GNUC__)
# define ObjEntryOffset(eltPtr,basePtr) \
    ((void *)(eltPtr) - (void *)(basePtr))
#else
# define ObjEntryOffset(eltPtr,basePtr) \
    ((char *)(eltPtr) - (char *)(basePtr))
#endif

/******************************************************************************
 *
 *			  SEGMENT DESCRIPTOR
 *
 ******************************************************************************/
typedef struct {
    ID	    	    name;   	/* Segment name */
    ID	    	    class;  	/* Segment class */
    unsigned short  align:8, 	/* Alignment (mask of bits to clear) */
   	    	    type:4, 	/* Segment type: */
#define SEG_PRIVATE 	0   	    /* Private to object module. MUST BE ZERO*/
#define SEG_COMMON  	1   	    /* Overlap all instances */
#define SEG_STACK   	2   	    /* Stack segment for DOS executable */
#define SEG_LIBRARY 	3   	    /* Library definitions, only */
#define SEG_RESOURCE	4   	    /* Resource segment to be handled by
				     * kernel */
#define SEG_LMEM    	5   	    /* Same, but with LMem heap */
#define SEG_PUBLIC  	6   	    /* Segments from object modules follow
				     * each other */
#define SEG_ABSOLUTE	7   	    /* Absolute segment (data field contains
				     * segment address, not handle of data) */
#define SEG_GLOBAL  	8   	    /* Global scope -- no data, just symbols */
		    flags:4;	/* Flags for segment */
#define SEG_IN_DGROUP	1   	    /* Part of the dgroup resource */
#define SEG_IN_GROUP	2   	    /* In any group */
    VMBlockHandle   data;   	/* Block in which data are stored/absolute
				 * segment address if SEG_ABSOLUTE */
    word    	    size;   	/* Number of bytes of data (size of VMBlock
				 * cannot be relied on) */
    VMBlockHandle   relHead;	/* First block of relocations */
    VMBlockHandle   syms;   	/* Symbols for segment. this is just a chain
				 * of blocks. */
    VMBlockHandle   toc;    	/* Table of contents for the symbols. This is
				 * zero in a .obj file */
    VMBlockHandle   addrMap;	/* Block containing the by-address map for the
				 * symbol table. This is zero in a .obj file */
    VMBlockHandle   lines;  	/* map block for the line number -> address
				 * mapping */
} ObjSegment;

/******************************************************************************
 *
 *			   GROUP DESCRIPTOR
 *
 *****************************************************************************/
typedef struct {
    ID	    	    name;   	/* Name of group */
    unsigned short  numSegs;	/* Number of segments in the group */
    unsigned short  pad;    	/* So sizeof(ObjGroup) doesn't return
				 * misleading value... */
    unsigned short  segs[LABEL_IN_STRUCT];   /* Start of array of segment
					      * offsets - note there isn't
					      * a label in this struct */
} ObjGroup;

/*
 * OBJ_GROUP_SIZE gives the size, in bytes, required for an ObjGroup descriptor
 * containing n segments.
 * OBJ_NEXT_GROUP returns a pointer to the Group descriptor after g, which
 * is a pointer to an initialized group descriptor.
 */
#define OBJ_GROUP_SIZE(n)   ((sizeof(ObjGroup)+((n)*sizeof(unsigned short))+3)&~3)
#define OBJ_NEXT_GROUP(g)   (ObjGroup *)((char *)(g)+OBJ_GROUP_SIZE((g)->numSegs))


/******************************************************************************
 *
 *		       SYMBOL TABLE DEFINITIONS
 *
 ******************************************************************************/
typedef struct {
    VMBlockHandle   next;
    VMBlockHandle   types;
    unsigned short  seg;    /* Offset in map block of segment owning these
			     * symbols */
    unsigned short  num;    /* Number of symbols in the block. This can't
			     * be determined from the block size always as
			     * the kernel likes to round allocations to a
			     * paragraph boundary */
} ObjSymHeader;

/*
 * Symbol definition. The reason the per-type data comes before the
 * actual type and flags is to avoid excessive padding by the compiler. 
 * Even though I made sure things were properly aligned, the compiler
 * decided I was wrong and added extra space, making the object files
 * incompatible between architectures, which isn't good.
 */
typedef unsigned short SID[2];	/* Gross fake ID needed to keep compiler from
				 * mis-aligning things on anal-retentive 
				 * processors like the Sparc. We guarantee that
				 * longword fields are longword-aligned, so
				 * an ID can safely be stored in the field.
				 * To make life simple, there are macros
				 * for fetching and storing these things,
				 * as the syntax is a bit gross. */
typedef struct {
    ID	    	    name;   	/* Pointer to name in string table */
    union {
	/*
	 * General form for all symbols.
	 */
	struct {
	    unsigned short  data[3];	/* Three words of type-specific data */
	}   	    genSym;
	/*
	 * General form for symbols with actual addresses
	 */
	struct {
	    unsigned short  pad[2]; 	/* Type-specific data */
	    unsigned short  address;	/* Address w/in segment */
	}   	    addrSym;
	/*
	 * General form for symbols that have other symbols within their
	 * scope. This includes structured types, procedures, and block-start
	 * symbols.
	 */
	struct {
	    unsigned short  pad1;   	/* Type-specific data */
	    unsigned short  first;  	/* Head of symbols in the scope */
	    unsigned short  pad2;   	/* Type-specific data */
	}   	    scope;
	/*
	 * Type definition. Created via
	 *  <name>  type <typedesc>
	 */
	struct {
	    unsigned short  type;   	/* Start of type description */
	}   	    typeDef;
	/*
	 * Structured type (struc, union, record or enum)
	 */
	struct {
	    unsigned short  size;   	/* Total size of type */
	    unsigned short  first;  	/* Offset of first field in type in
					 * this block */
	    unsigned short  last;   	/* Offset of last field in type */
	}   	    sType;
	/*
	 * An element of one of the above.
	 */
	struct {
	    unsigned short  next;
	    unsigned short  pad[2];
	}   	    tField;
	/*
	 * Field in a structure (possibly an instance variable)
	 */
	struct {
	    unsigned short  next;   	/* Next field in type */
	    unsigned short  offset; 	/* Byte offset w/in structure */
	    unsigned short  type;   	/* Type of field */
	}   	    sField;
	/*
	 * Field in a record
	 */
	struct {
	    unsigned short  next;   	/* Next field in type */
	    unsigned char   offset; 	/* Bit offset w/in record */
	    unsigned char   width;  	/* Bit width of field */
	    unsigned short  type;   	/* Type of field */
	}   	    bField;
	/*
	 * Method number
	 */
	struct {
	    unsigned short  next;   	/* Next member in enumerated type */
	    unsigned short  value;  	/* Value of method constant */
	    unsigned short  flags; 	/* Flags concerning method: */
#define OSYM_METH_PUBLIC    	0x0001	    /* Publicly available */
#define OSYM_METH_RANGE	    	0x0002	    /* Start of an exported range */
#define OSYM_METH_RANGE_LENGTH	0xfffc	    /* # exported messages in range */
#define OSYM_METH_RANGE_LENGTH_OFFSET 2
	}   	    method;
	/*
	 * Enumerated constant
	 */
	struct {
	    unsigned short  next;   	/* Next member of enumerated type */
	    unsigned short  value;  	/* Value of enumerated constant */
	}   	    eField;
	/*
	 * Enumerated constant in object-class vardata enum
	 */
	struct {
	    unsigned short  next;   	/* Next member of enumerated type */
	    unsigned short  value;  	/* Value of enumerated constant */
	    unsigned short  type;   	/* Type of data stored with tag */
	}   	    varData;
	/*
	 * Unenumerated, named constant
	 */
	struct {
	    unsigned short  value;  	/* Value of constant */
	}   	    constant;
	/*
	 * Static variable
	 */
	struct {
	    unsigned short  type;   	/* Type of variable */
	    unsigned short  pad;
	    unsigned short  address;	/* Offset w/in segment */
	}   	    variable;
	/*
	 * Variable in LMem chunk
	 */
	struct {
	    unsigned short  type;   	/* Type of data in chunk */
	    unsigned short  pad;
	    unsigned short  handle; 	/* LMem handle of chunk */
	}   	    chunk;
	/*
	 * Procedure
	 */
	struct {
	    unsigned short  flags;  	/* Flags for procedure */
#define OSYM_NEAR   	    0x0001    	    /* Procedure is NEAR */
#define OSYM_WEIRD  	    0x0002    	    /* Procedure contains at least one
					     * on_stack */
#define OSYM_NO_JMP	    0x0004    	    /* Procedure may not be jumped to */
#define OSYM_NO_CALL	    0x0008    	    /* Procedure may not be called
					     * (only jumped to) */
#define OSYM_PROC_STATIC    0x0010    	    /* Static method handler */
#define OSYM_PROC_PSTATIC   0x0020    	    /* Private static method handler */
#define OSYM_PROC_DYNAMIC   0x0040    	    /* Dynamic method handler */
#define OSYM_PROC_HANDLER   0x0080    	    /* Method handler */
#define OSYM_PROC_PASCAL    0x0100  	    /* Pascal calling convention */
#define OSYM_PROC_PUBLISHED 0x0200  	    /* Set if routine is to be
					       copied into the .ldf file */
	    unsigned short  local;  	/* Offset w/in block of first local
					 * symbol */
	    unsigned short  address;	/* Offset w/in segment */
	}   	    proc;
#define	OSYM_PROC_START_NAME	"??START"   /* Name of local label pointing to
					     * the end of the procedure
					     * prologue */
	/*
	 * Non-local label (local label is the same, except it uses the
	 * procLocal.next field as well)
	 */
	struct {
	    unsigned short  pad;
#if defined(_MSC_VER) || defined(__WATCOMC__)
#    define near nearFlag
#endif /* defined _MSC_VER */
	    unsigned short  near;   	/* Non-zero if label near */
	    unsigned short  address;	/* Offset w/in segment */
	}   	    label;
	/*
	 * Stack layout descriptor
	 */
	struct {
	    SID	    	    desc;   	/* Pointer to string containing
					 * stack layout */
	    unsigned short  address;	/* Offset w/in segment */
	}   	    onStack;
	/*
	 * General form for procedure-local symbols (for list traversal)
	 */
	struct {
	    unsigned short  next;   	/* Offset of next symbol in block */
	    unsigned short  pad[2]; 	/* Type-specific data */
	}   	    procLocal;
	
	/*
	 * Local variable
	 */
	struct {
	    unsigned short  next;   	/* Next in chain */
	    unsigned short  type;   	/* Type of variable */
	    short   	    offset; 	/* Offset from BP for variable, or
					 * register number if OSYM_REGVAR: */
#define OSYM_REG_AX          0
#define OSYM_REG_BX          3
#define OSYM_REG_CX          1
#define OSYM_REG_DX          2
#define OSYM_REG_SP          4
#define OSYM_REG_BP          5
#define OSYM_REG_SI          6
#define OSYM_REG_DI          7

#define OSYM_REG_ES          8
#define OSYM_REG_CS          9
#define OSYM_REG_SS          10
#define OSYM_REG_DS          11

#define OSYM_REG_AL          12
#define OSYM_REG_BL          15
#define OSYM_REG_CL          13
#define OSYM_REG_DL          14
#define OSYM_REG_AH          16
#define OSYM_REG_BH          19
#define OSYM_REG_CH          17
#define OSYM_REG_DH          18
	}   	    localVar;
	/*
	 * Local static variable (defined in a different segment, but its
	 * name is available only within the procedure)
	 */
	struct {
	    unsigned short  next;   	/* Next in chain */
	    VMBlockHandle   symBlock;	/* Block in which OSYM_VAR symbol is
					 * located */
	    unsigned short  symOff; 	/* Offset at which symbol is located
					 * within the block */
	}   	    localStatic;

	/*
	 * Lexical block start
	 */
	struct {
	    unsigned short  next;   	/* Next procedure-local symbol (s/b
					 * end block) */
	    unsigned short  local;  	/* First symbol local to block */
	    unsigned short  address;  	/* Offset w/in segment of start */
	}   	    blockStart;
	struct {
	    unsigned short  next;
	    unsigned short  pad;
	    unsigned short  address;
	}   	    blockEnd;
	/*
	 * Class symbol. Bindings follow immediately after. First non-binding
	 * symbol ends binding list...
	 */
	struct {
	    SID	    	    super;  	/* Name of superclass */
	    unsigned short  address;	/* Offset w/in segment */
	}   	    class;
	/*
	 * Method -> Procedure binding for dealing with static method binding.
	 */
	struct {
	    SID	    	    proc;   	/* Name of bound procedure */
	    byte    	    callType;	/* One of the following: */
#define OSYM_DYNAMIC	    	0   	    /* Method must be called
					     * dynamically (by a message) */
#define OSYM_DYNAMIC_CALLABLE	1   	    /* Method may be called by a message
					     * or directly */
#define OSYM_STATIC 	    	2   	    /* Method may always be called
					     * staticly */
#define OSYM_PRIVSTATIC	    	3   	    /* Method may only be called
					     * staticly from within the geode
					     * that defines the handler. The
					     * difference is noted only when
					     * creating a library's ldf file */
	    byte    	    isLast; 	/* Non-zero if this is the last binding
					 * for the class */
	}   	    binding;
	/*
	 * Library-defined type.
	 */
	struct {
	    unsigned short  offset; 	/* Place to store offset of actual
					 * type symbol w/in block */
	    VMBlockHandle   block;  	/* Place to store block containing
					 * actual type symbol */
	    unsigned char   stype;  	/* Expected symbol type */
	}   	    extType;
	/*
	 * Module. Placed only in the global segment in a .sym file for
	 * Swat's sake.
	 */
	struct {
	    VMBlockHandle   table;  	/* Handle of symbol table */
	    unsigned short  offset; 	/* Offset of segment descriptor
					 * for module */
	    VMBlockHandle   syms;   	/* List of symbols for the segment */
	}   	    module;
	/*
	 * Minor-number marker. Used only in .ldf files, it indicates the minor
	 * protocol number that should be used in the imported library table
	 * for a client geode when any of the entry points that follow is used
	 * by the client.
	 */
	struct {
	    word    	    number; 	/* The minor number */
	}   	    newMinor;
	/*
	 * Profile-code marker.
	 */
	struct {
	    word    	    markType;
#define OSYM_PROF_BBLOCK    	1   	/* Basic-block coverage */
#define OSYM_PROF_COUNT	    	2   	/* Execution counter */
	    word    	    pad;
	    word    	    address;	/* Address w/in segment */
	}   	    profMark;
	    
    } 	    u;
    unsigned char   type;   	/* Type of symbol: */
#define OSYM_TYPEDEF	    1  	    /* Typedef */
#define OSYM_STRUCT 	    2	    /* Structure */
#define OSYM_RECORD 	    3	    /* Record */
#define OSYM_ETYPE   	    4	    /* Enumerated type (may hold methods) */
#define OSYM_FIELD  	    5  	    /* Structure field */
#define OSYM_BITFIELD	    6  	    /* Record field */
#define OSYM_ENUM   	    7  	    /* Member of enumerated type */
#define OSYM_METHOD 	    8  	    /* Method number */
#define OSYM_CONST  	    9  	    /* Named constant */
#define OSYM_VAR    	    10 	    /* Static variable */
#define OSYM_CHUNK  	    11 	    /* LMem chunk */
#define OSYM_PROC   	    12 	    /* Procedure */
#define OSYM_LABEL  	    13 	    /* File-global label */
#define OSYM_LOCLABEL	    14 	    /* Procedure-local label */
#define OSYM_LOCVAR 	    15 	    /* Procedure-local variable (stack) */
#define OSYM_ONSTACK	    16 	    /* Stack layout descriptor */
#define OSYM_BLOCKSTART     17 	    /* Lexical block start (H.L.L. only) */
#define OSYM_BLOCKEND 	    18	    /* Lexical block end (H.L.L. only) */
#define OSYM_EXTTYPE	    19 	    /* External type (actual type defined in
				     * a library somewhere...) */
#define OSYM_CLASS  	    20 	    /* Object class */
#define OSYM_MASTER_CLASS   22	    /* Master object class */
#define OSYM_VARIANT_CLASS  23	    /* Variant object class */
#define OSYM_BINDING	    24	    /* Method -> Procedure binding. Name
				     * is method, data contains procedure */
#define OSYM_MODULE 	    25	    /* Module descriptor (.sym file only) */
#define OSYM_UNION  	    26	    /* Union type */
#define OSYM_REGVAR 	    27	    /* Procedure-local variable (register).
				     * Uses localVar data. .offset is one of
				     * the OSYM_REG_* constants */
#define OSYM_PROFILE_MARK   28	    /* Nameless address-bearing symbol that
				     * marks a profiling location for Swat */
#define OSYM_RETURN_TYPE    29	    /* Symbol holding the return type of a
				     * procedure. Linked into the local-symbol
				     * list for the proc. Same data as a
				     * LOCALVAR */
#define OSYM_LOCAL_STATIC   30	    /* Pointer to VAR symbol for a variable
				     * that is static to a procedure */
#define OSYM_VARDATA	    31	    /* Element of object-class VarData
				     * enumerated type */
#define OSYM_NEWMINOR	    32	    /* A marker indicating the minor protocol
				     * number that should be used in the
				     * imported library table for a client
				     * geode when any of the entry points that
				     * follow are used by the client */
#define OSYM_PROTOMINOR	    33

    unsigned char   flags;  	/* Flags for symbol: */
#define OSYM_GLOBAL 	0x01	    /* Global to program */
#define OSYM_UNDEF  	0x02	    /* Undefined in segment -- placeholder */
#define OSYM_REF    	0x04	    /* Symbol referenced during assembly */
#define OSYM_ENTRY  	0x08	    /* Symbol actually a library entry point.
				     * This is found exclusively in .ldf files
				     * and is used, for the most part, when
				     * handling an ENTRY relocation so the
				     * linker knows it needn't go searching
				     * through the geode's own export table */
#define OSYM_MOVABLE	0x10	    /* Symbol lies in a movable segment. Used
				     * only in .ldf files to detect jumps to
				     * movable library routines. */
#define OSYM_NAMELESS	0x20	    /* Symbol name should not be printed */
#define OSYM_MANGLED	0x40	    /* Symbol name has been mangled. Unmangle
				     * as appropriate */
} ObjSym;

/*
 * Since an SID is an array, using it yields a pointer, which we cast to be
 * a pointer to an ID, which is what's actually stored there.
 */
#define OBJ_STORE_SID(field,value)	(*(ID *)(field) = (value))
#define OBJ_FETCH_SID(field)		(*(ID *)(field))


/******************************************************************************
 *
 *			   RELOCATION DATA
 *
 ******************************************************************************/
typedef struct {
    VMBlockHandle   next;   	/* Next block in chain */
    unsigned short  num; 	/* Number of relocations in the block */
} ObjRelHeader;

typedef struct {
    unsigned short  symOff; 	/* Offset of symbol w.r.t. which the relocation
				 * is to take place */
    VMBlockHandle   symBlock;	/* Block in which symbol resides */
    unsigned short  offset; 	/* Offset in segment for relocation */
    unsigned short  frame;  	/* Offset in map block of segment/group
				 * descriptor w.r.t. which relocation is to
				 * take place */
    unsigned short  type:4, 	/* Type of relocation */
#define OREL_LOW    	0   	    /* Low part of offset */
#define OREL_HIGH   	1   	    /* High part of offset */
#define OREL_OFFSET 	2   	    /* Full offset */
#define OREL_SEGMENT	3   	    /* Physical segment */
#define OREL_HANDLE 	4   	    /* Handle of segment */
#define OREL_RESID  	5   	    /* Resource ID of segment */
#define OREL_CALL   	6   	    /* Far call */
#define OREL_ENTRY	7	    /* Library entry point # */
#define OREL_METHCALL	8   	    /* Static method call to object of
				     * class given by symBlock:symOff */
#define OREL_SUPERCALL	9   	    /* Static method call, but class is
				     * superclass of that of the object */
#define OREL_PROTOMINOR 10   	    /* ProtoMinor type relocation */
		    size:2, 	/* Size of data to relocate */
#define OREL_SIZE_BYTE	0
#define OREL_SIZE_WORD	1
#define OREL_SIZE_DWORD	2
		    pcrel:1,	/* Relocation relative to addr after data */
		    fixed:1,	/* Target must lie in a fixed segment. */
		    unused:8;	/* Pad to word boundary */
} ObjRel;

/******************************************************************************
 *
 *		 BLOCK IDENTIFIERS FOR OBJECT BLOCKS
 *
 * so we know how to byteswap them....
 ******************************************************************************/
#define	OID_STRING_HEAD	    ST_HEADER_ID
#define OID_STRING_CHAIN    ST_CHAIN_ID
#define OID_REL_BLOCK	    OID_STRING_CHAIN+1	/* ObjRels */
#define OID_SYM_BLOCK	    OID_REL_BLOCK+1 	/* ObjSyms */
#define OID_HASH_BLOCK	    OID_SYM_BLOCK+1 	/* ObjSym hash table */
#define OID_HASH_HEAD_BLOCK OID_HASH_BLOCK+1 	/* Head of ObjSym hash table */
#define OID_MAP_BLOCK	    OID_HASH_HEAD_BLOCK+1/* Map block for file */
#define OID_CODE_BLOCK	    OID_MAP_BLOCK+1 	/* Code for segment */
#define OID_TYPE_BLOCK	    OID_CODE_BLOCK+1	/* Type descriptions */
#define OID_LINE_BLOCK	    OID_TYPE_BLOCK+1 	/* Line number info */
#define OID_ADDR_MAP	    OID_LINE_BLOCK+1	/* Address map for a segment */
#define OID_SRC_BLOCK 	    OID_ADDR_MAP+1  	/* Source file mapping */

/******************************************************************************
 *
 *			   TYPE DESCRIPTORS
 *
 * This relies on elements in symbol blocks being word-aligned, allowing us to
 * use the lowest bit to indicate if the word is a block offset or it's a
 * special code.
 ******************************************************************************/

#define OTYPE_SPECIAL	0x0001	/* Set if type token is special */

/*
 * For special tokens, the high byte holds the token type, bits 1-12
 * ("the low byte"), holds additional info.
 */
#define OTYPE_INT   	0x1000	/* Low byte contains size */
#define OTYPE_SIGNED	0x2000	/* Low byte contains size */
#define OTYPE_NEAR  	0x3000	/* Low byte is meaningless */
#define OTYPE_FAR   	0x4000	/* Low byte is meaningless */
#define OTYPE_CHAR  	0x5000	/* Low byte contains size-1 */
#define OTYPE_VOID  	0x6000	/* Low byte is meaningless */
#define OTYPE_PTR   	0x7000	/* For void *, the low byte contains the
				 * pointer type */
#define OTYPE_PTR_FAR	    ('f'<<OTYPE_DATA_SHIFT)
#define OTYPE_PTR_NEAR	    ('n'<<OTYPE_DATA_SHIFT)
#define OTYPE_PTR_LMEM	    ('l'<<OTYPE_DATA_SHIFT)
#define OTYPE_PTR_HANDLE    ('h'<<OTYPE_DATA_SHIFT)
#define OTYPE_PTR_SEG	    ('s'<<OTYPE_DATA_SHIFT)
#define OTYPE_PTR_OBJ	    ('o'<<OTYPE_DATA_SHIFT)
#define OTYPE_PTR_VM	    ('v'<<OTYPE_DATA_SHIFT)
#define OTYPE_PTR_VIRTUAL   ('F'<<OTYPE_DATA_SHIFT)

#define OTYPE_BITFIELD	0x8000	/* Bitfields w/o special type. Low byte 
				 * holds 5 bits of offset, 5 bits of
				 * width (0-origin), and 1 bit to say
				 * if it's signed or unsigned. */
#define OTYPE_BF_WIDTH	0x003e	    /* Bits holding width of a bitfield */
#define OTYPE_BF_WIDTH_SHIFT	1
#define OTYPE_BF_OFFSET	0x07c0	    /* Bits holding offset of a bitfield */
#define OTYPE_BF_OFFSET_SHIFT	6
#define OTYPE_BF_SIGNED	0x0800


#define OTYPE_FLOAT 	0x9000	/* Low byte contains size */
#define OTYPE_COMPLEX	0xa000	/* Low byte contains size */
#define OTYPE_CURRENCY	0xb000	/* What the hell is this? */

#define OTYPE_TYPE  	0xf000	/* Bits that contain type */
#define OTYPE_DATA  	0x0ffe	/* Bits that contain the data for the type */
#define OTYPE_DATA_SHIFT 1

/*
 * Macros to create a word for a special type.
 */
#define OTYPE_MAKE_INT(size)	(OTYPE_INT | \
				 ((size) << OTYPE_DATA_SHIFT) | \
				 OTYPE_SPECIAL)
#define OTYPE_MAKE_SIGNED(size)	(OTYPE_SIGNED | \
				 ((size) << OTYPE_DATA_SHIFT) | \
				 OTYPE_SPECIAL)
#define OTYPE_MAKE_NEAR()	(OTYPE_NEAR | OTYPE_SPECIAL)
#define OTYPE_MAKE_FAR()	(OTYPE_FAR | OTYPE_SPECIAL)
#define OTYPE_MAKE_CHAR(size)	(OTYPE_CHAR | \
				 ((size-1) << OTYPE_DATA_SHIFT) | \
				  OTYPE_SPECIAL)
#define OTYPE_MAKE_VOID()	(OTYPE_VOID | OTYPE_SPECIAL)
#define OTYPE_MAKE_VOID_PTR(pt)	(OTYPE_PTR | (pt) | OTYPE_SPECIAL)
#define OTYPE_MAKE_BITFIELD(w,o) (OTYPE_BITFIELD | \
				  ((w) << OTYPE_BF_WIDTH_SHIFT) | \
				  ((o) << OTYPE_BF_OFFSET_SHIFT) | \
				  OTYPE_SPECIAL)
#define OTYPE_MAKE_FLOAT(size)	(OTYPE_FLOAT | \
				 ((size) << OTYPE_DATA_SHIFT) | \
				 OTYPE_SPECIAL)
#define OTYPE_MAKE_COMPLEX(size) (OTYPE_COMPLEX | \
				  ((size) << OTYPE_DATA_SHIFT) | \
				  OTYPE_SPECIAL)
#define OTYPE_MAKE_CURRENCY()	(OTYPE_CURRENCY | OTYPE_SPECIAL)
				  

/*
 * For non-special tokens, the word is an offset to a two-word structure,
 * the first word of which describes the type of type, while the second word
 * contains additional info. This additional structure is required only for
 * arrays, structured types (structs, enums, records, or typedefs) and
 * pointers to non-void types.
 *
 * Again, we take advantage of the word-alignment of things in the symbol
 * table.
 *
 * For structured types, the two words are simply the identifier for the
 * structured type. This allows us to handle mutually referential types
 * gracefully (we needn't define a bogus "external" type as a forward
 * reference -- we've just got the name and when the base type of the
 * pointer is required, we can find it by name).
 *
 * For a pointer type, the lowest bit is set, with bits 1-7 giving the
 * type of pointer, as for the special token, above. The second word is
 * a type token/offset as above.
 *
 * For an array type, both the LSB and the MSB of the initial word are
 * set (the LSB indicates it's not a structured type and the MSB indicates
 * it's not a pointer). Bits 1-14 contain the number of elements in the array
 * and the second word contains a type token/offset describing the elements.
 *
 * NOTE: It is important that these records be four bytes long, as the
 * symbol table elements must actually be longword aligned to avoid
 * memory faults on the Sparc and other processors that are anal retentive
 * about memory accesses.
 */
typedef struct {
    unsigned short  num;    /* Number of descriptors in the block */
    unsigned short  pad;    /* To ensure longword alignment of descriptors */
} ObjTypeHeader;

#define OTYPE_IS_STRUCT(w)  (((w) & 1) == 0)
#define OTYPE_STRUCT_ID(tp) (((tp)->words[1] << 16) | ((tp)->words[0]))
#define OTYPE_ID_TO_STRUCT(id,tp) (((tp)->words[0] = (id)), ((tp)->words[1] = ((id)>>16)))

#define OTYPE_IS_PTR(w)	    (((w) & 0x8001) == 1)
#define OTYPE_PTR_TYPE(w)   (((w) & 0xfe) >> 1)

#define OTYPE_IS_ARRAY(w)   (((w) & 0x8001) == 0x8001)
#define OTYPE_ARRAY_LEN(w)  (((w) & 0x7ffe) >> 1)
#define OTYPE_MAX_ARRAY_LEN 0x3ffe
#define OTYPE_MAKE_ARRAY(len)	(0x8001 | ((len) << 1))
typedef struct {
    unsigned short  words[2];
} ObjType;

/******************************************************************************
 *
 *		       LINE NUMBER INFORMATION
 *
 * The address -> line mapping for a segment is made of a series of two-word
 * records, containing the line number and starting address, interspersed with
 * records containing the name of the file to which the following records
 * refer. A filename record is set off from the preceding line number records
 * by a line number record whose line number is 0.
 *
 * The use of four-byte records is necessitated by the filename being a
 * longword identifier that the Sparc cannot fetch from a non-longword
 * boundary. The number of transitions in a typical table will be small,
 * in any case, so the space matters little.
 *
 * Overlooking the entire list of line numbers is an address map of the same
 * format as that stored for the address symbols of a segment (q.v.
 * ObjAddrMapHeader and ObjAddrMapEntry, below). This allows us to find the
 * line block we need without having to bring in the entire chain.
 ******************************************************************************/
typedef struct {
    VMBlockHandle   next;   	/* Next block in chain */
    unsigned short  num;	/* Number of lines in the block */
} ObjLineHeader;

typedef struct {
    unsigned short  line;   	/* Line number */
    unsigned short  offset; 	/* Segment offset of start */
} ObjLine;

/******************************************************************************
 *
 *			    INITIAL SIZES
 *
 * for various types of blocks in output file.
 ******************************************************************************/
#define OBJ_INIT_TYPES	6144	/* 6K -- should keep us under 8K */
#define OBJ_MAX_TYPES	8192
#define OBJ_MAX_SYMS	8192	/* 682 symbols + header */
#define OBJ_INIT_LINES	8192	/* Nice, round number */
#define OBJ_MAX_HASH	8192

#define OBJ_INIT_SRC_MAP    6144
#define OBJ_MAX_SRC_MAP	    8192

/******************************************************************************
 *
 *			HASH TABLE DEFINITIONS
 *
 * A symbol table is made of two types of blocks:
 *	- blocks containing OBJ_SYMS_PER 8-byte records that give the
 *	  name (as an ID) and address (block/offset pair) of a symbol. These
 *	  blocks are chained together through a four-byte header to form
 *	  a series of chains.
 *	- a header block that contains the chain pointers for the table.
 * A symbol is assigned to a chain based on the index returned by the ST
 * module for its ID.
 *
 * This hash table structure is also used for the file:line -> segment:offset
 * mapping...
 ******************************************************************************/
#define OBJ_HASH_CHAINS	127 	/* Number of chains in a symbol hash table */
#define OBJ_SYMS_PER	64 	/* Number of symbols per hash table block */

/* new values so it can work reasonable well under GEOS */
#define OBJ_HASH_CHAINS_NEW_FORMAT	5
#define OBJ_SYMS_PER_NEW_FORMAT		1024

typedef struct {
    VMBlockHandle   	    chains[OBJ_HASH_CHAINS];
} ObjHashHeader;

typedef struct {
    VMBlockHandle   	    chains[OBJ_HASH_CHAINS_NEW_FORMAT];
} ObjHashHeaderNewFormat;

typedef struct {
    ID	    	    name;   	/* Symbol name */
    word    	    offset; 	/* Offset w/in block */
    VMBlockHandle   block;  	/* Block containing symbol data */
} ObjHashEntry;

typedef struct {
    VMBlockHandle   next;   	/* Next HashBlock in chain */
    word    	    nextEnt;	/* Index of next available entry in this
				 * block */
    ObjHashEntry    entries[OBJ_SYMS_PER];
} ObjHashBlock;

typedef struct {
    VMBlockHandle   next;   	/* Next HashBlock in chain */
    word    	    nextEnt;	/* Index of next available entry in this
				 * block */
    ObjHashEntry    entries[OBJ_SYMS_PER_NEW_FORMAT];
} ObjHashBlockNewFormat;
    
/******************************************************************************
 *
 *			 SEGMENT ADDRESS MAP
 *
 * Each segment descriptor in a .sym file has associated with it an
 * address map that maps offsets in the segment to symbol blocks. Each
 * entry in the map contains a block and the offset of the last
 * address-bearing symbol in that block, allowing a fast binary search
 * of the map to locate a desired symbol.
 *
 * This same format is used for the line address map as well.
 ******************************************************************************/
typedef struct {
    word    	    numEntries;	/* Number of entries in the map */
} ObjAddrMapHeader;

typedef struct {
    VMBlockHandle   block;  	/* Block with the symbols */
    word    	    last;   	/* Segment offset of last */
} ObjAddrMapEntry;

/******************************************************************************
 *
 *			   SOURCE FILE MAP
 *
 * A .sym file contains an extra hash table (beyond the ones used for symbol
 * lookup in each segment) that is keyed off source file names. The VMPtr
 * stored as the data for each entry points to an ObjSrcMapHeader, which
 * header is followed by an array of ObjSrcMap structures to make determining
 * a segment and offset from a source file/line number pair fast.
 *
 * There's a difference between an ObjSrcMapHeader and other *Header structures,
 * however: there can be more than one ObjSrcMap array in a single block.
 *
 * The idea is, a group of lines will be in a single segment (e.g. all the lines
 * of a function lie within the same segment), so one can have a map sorted by
 * ascending line numbers giving the segment in which the first line is defined,
 * and the offset of that line within the segment. Once the search has narrowed
 * to a particular starting line and offset, it's a simple matter of finding the
 * line number block with that line and searching forward to find the offset of
 * the line in question.
 *
 ******************************************************************************/
typedef struct {
    word    	numEntries;	/* Number of entries in the map */
} ObjSrcMapHeader;

typedef struct {
    word    	line;		/* Starting line number */
    word    	offset;		/* Offset of that line in the segment */
    word    	segment;	/* Offset of ObjSegment descriptor in
				 * the ObjHeader */
} ObjSrcMap;

/******************************************************************************
 *
 *			   MAP BLOCK HEADER
 *
 ******************************************************************************/
/*
 * Protocol numbers stored in the header of a VM-format object file.
 */
#define OBJ_PROTOCOL_MAJOR  5
#define OBJ_PROTOCOL_MINOR  2

#define OBJ_OBJTOKEN	"POBJ"	/* File token for VM-format objects */
#define OBJ_SYMTOKEN	"PSYM"	/* File token for final symbol files */

/*
 * Interface protocol revision number (for libraries, mostly)
 */
typedef struct {
    word    	major;
    word    	minor;
} ObjProto;

/*
 * Geode revision number.
 */
typedef struct {
    word    	major;	    /* Major release number */
    word    	minor;	    /* Minor release number */
    word    	change;	    /* Running-change number (between minor/major
			     * releases) */
    word    	internal;   /* Internal revision number (changed each
			     * install) */
} ObjRevision;

/*
 * Header for map block. Header is followed by segment and group descriptors
 */
#define OBJMAGIC    0x5170  	/* Magic number. Stored in native byte
				 * order. If reader must swap to be valid,
				 * other parts of file must be swapped */
#define SWOBJMAGIC  0x7051  	/* Opposite byte-order... */

#define OBJMAGIC_NEW_FORMAT 0x6170
#define SWOBJMAGIC_NEW_FORMAT 0x7061

typedef struct {
   unsigned short   magic;   	/* Magic number */
   unsigned short   numSeg; 	/* Number of segments */
   unsigned short   numGrp; 	/* Number of groups */
   VMBlockHandle    strings;	/* String table for file */
   VMBlockHandle    srcMap;  	/* Hash table for source file->offset
				 * mapping */
   ObjRel   	    entry;  	/* Relocation for entry point, if it's in this
				 * object file */
   ObjRevision	    rev;    	/* Revision number (.sym and .ldf only) */
   ObjProto 	    proto;  	/* Protocol number (.sym and .ldf only) */
   long	    	    pad;        /* (Padding for Sparc and because I forgot
				 * to remove this when I added "strings") */
   ObjSegment	    segments[LABEL_IN_STRUCT];  /* Start of segment 
						 * information (forces proper
						 * padding of structure...) */
} ObjHeader;

#endif /* _OBJFORMAT_H_ */
