/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- type graph manipulation
 * FILE:	  type.c
 *
 * AUTHOR:  	  Adam de Boor: Sep 26, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Type_CreateInt	    Create a TYPE_INT type
 *	Type_CreateChar	    Create a TYPE_CHAR type
 *	Type_GetCharData    Get bounds of a TYPE_CHAR type
 *	Type_CreatePointer  Create a TYPE_POINTER type
 *	Type_GetPointerData Get target and class of a pointer
 *	Type_GetPointerType Get target of a pointer
 *	Type_SetPointerBase Set target of a pointer
 *	Type_CreateArray    Create a TYPE_ARRAY type
 *	Type_GetArrayData   Get bounds, element and index types of an array
 *	Type_CreateRange    Create a TYPE_RANGE type
 *	Type_GetRangeData   Get base and bounds of a range type
 *	Type_CreateUnion    Begin creating a TYPE_UNION type
 *	Type_CreateStruct   Begin creating a TYPE_STRUCT type
 *	Type_EndStructUnion Finish off TYPE_{UNION,STRUCT} and compress
 *	Type_AddField	    Add a field to a struct/union
 *	Type_GetFieldData   Fetch data about a field of a struct/union
 *	Type_ForEachField   Iterate over fields in a struct/union
 *	Type_FindFieldData  Locate a field by offset
 *	Type_CreateEnum	    Create a TYPE_ENUM type
 *	Type_GetEnumData    Fetch the bounds of a TYPE_ENUM type
 *	Type_AddEnumMember  Add a member to a TYPE_ENUM type
 *	Type_GetEnumValue   Fetch the value for a member of a TYPE_ENUM type
 *	Type_GetEnumName    Fetch the name for a value in a TYPE_ENUM type
 *	Type_ForEachEnum    Iterate over all members of an enum type
 *	Type_CreateFunction Create a TYPE_FUNCTION type
 *	Type_GetFunctionReturn Fetch the return value of a function type
 *	Type_CreateFloat    Create a TYPE_FLOAT type
 *	Type_CreateExternal Create a TYPE_EXTERNAL type
 *	Type_GetExternalData Fetch data for an external type
 *	Type_Sizeof 	    Return the size of a type
 *	Type_Class  	    Return the class of a type
 *	Type_Name   	    Return a formatted representation of a type
 *	Type_NameOffset     Return a formatted representation of a type with
 *			    a given number of spaces before each line
 *	Type_Equal  	    See if two types are equivalent
 *	Type_Cast   	    Cast a value from one type to another
 *	Type_IsSigned 	    See if a type is a signed integer
 *	Type_CreatePackedStruct Create a TYPE_STRUCT of fields that have
 *			    no padding between them
 *	Type_Init   	    Initialie the module.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/26/88	  ardeb	    Initial version
 *	12/2/88	  ardeb	    Added pointers to type command
 *
 * DESCRIPTION:
 *	This file contains functions for manipulating type descriptors
 *	in Swat.
 *
 *	Type descriptions are made of TypeRec and Sym elements kept in
 *	a sort of directed graph.
 *
 *	There are three sorts of type descriptions that are dealt
 *	with here. The TypeInternalize function brings this down to
 *	two. The three types are:
 *	    - internal descriptions created by the "type" command and the
 *	      descriptor-creation functions in this module. Various
 *	      things need to create these things at various times. They
 *	      are freed during garbage collection.
 *	    - VM symbols from a patient's symbol file. These include
 *	      TYPEDEF, STRUCT, RECORD, UNION and ETYPE symbols. They
 *	      are treated like their internal forms, except they may
 *	      not be modified.
 *	    - VM type descriptions, as extracted from symbols. They can
 *	      be any of the forms described in objfmt.h and are
 *	      converted to internal form by TypeInternalize.
 *	The three types are all contained in the 8 bytes of a TypeToken
 *	(the internal form of a Type token):
 *	    file==0 	an internal description. The other 4 bytes point
 *	    	    	to the internal descriptor (a TypeRec)
 *	    user id of block is OID_SYM_BLOCK
 *	    	    	a VM symbol.
 *	    user id of block is OID_TYPE_BLOCK
 *	    	    	a VM type description that must be converted, to
 *	    	    	an internal descriptor, if OTYPE_SPECIAL, an array
 *	    	    	or pointer, or to a VM symbol if a structure.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: type.c,v 4.21 97/04/18 16:55:43 dbaumann Exp $";
#endif lint

#include <config.h> 
#include "swat.h"
#include "buf.h"
#include "cmd.h"
#include "hash.h"
#include "sym.h"
#include "type.h"
#include "vector.h"
#include "vmsym.h"
#include "malloc.h"
#include <compat/stdlib.h>

/* HighC 3.1 crashes when gc.h is included */
#if !defined(__HIGHC__)
#include "gc.h"
#endif

#define ID String
#include <sttab.h>
#undef ID

#include <stdarg.h>

/*
 * Conditional-compilation constants. NOTE: THESE WERE ALL TAKEN OUT FOR
 * A REASON. YOU WILL NEED TO DO A BIT OF WORK TO GET THEM TO FUNCTION
 */
#define COMPRESS_DUPLICATE_STRUCTURES	FALSE
#define CACHE_FUNCTION_RETURNING_TYPE	FALSE
#define USE_TYPE_EXTERNAL   	    	FALSE

/*
 * Description of a field in a structure or union
 */
typedef struct _Field {
    String    	  name;    	/* Name of field */
    int	    	  offset;   	/* Bit offset from structure start */
    int	    	  length;   	/* Length of field (in bits) */
    Type    	  type;	    	/* Type of field */
} FieldRec, *FieldPtr;

#define TYPE_FIELD_INIT	    5
#define TYPE_FIELD_INCR	    2
#define TYPE_FIELD_ADJUST   ADJUST_MULTIPLY

/*
 * Description of a member of an enumerated type
 */
typedef struct {
    char    	  *name;    	/* Name of enumerated constant */
    int	    	  value;    	/* Ordinal value of enumerated constant. */
} EnumRec, *Enum;

/*
 * Type descriptions are organized in a vaguely graph-like way with each
 * node containing a class and some class-specific data. In addition, to
 * reduce the number of nodes created, each type has a slot for a type that
 * points to it (e.g. type_Char's pointerTo field holds a pointer to the Type
 * for "char *").
 */
typedef struct _Type {
    word	  class:7,    	/* Class of this type (see type.h) */
		  temp:1;   	/* Set if type is temporary (i.e. should
				 * be destroyed before leaving and exists
				 * only to handle funky external types) */
/*    Type    	  pointerTo;	 * Pointer to this type */
#if CACHE_FUNCTION_RETURNING_TYPE
    Type    	  function; 	/* Function returning this type */
#endif
    union {
	struct {
	    Type  	    baseType;  	/* Type pointed-to */
	    int	    	    ptrType;	
	}   	  	Pointer;
	struct {
	    word  	    lower;  	/* Lower bound of index */
	    word	    upper;  	/* Upper bound of index */
	    Type	    indexType;	/* Type of index */
	    Type	    baseType;	/* Type of elements */
	}   	  	Array;
	struct {
	    word  	    lower;  	/* Lower bound of range */
	    word	    upper;  	/* Upper bound of range */
	    Type	    baseType;	/* Type of range elements */
	}   	  	Range;
	struct {
	    word  	    size;   	/* Total size of structure */
	    word  	    checksum;	/* Sum of all characters in all the
					 * names of all the fields. Used to
					 * make type compression faster */
	    Vector	    fields; 	/* The fields in the structure */
	    Type	    checked;	/* Set to type against which it
					 * is in the process of being compared
					 * in Type_Equal() */
	}   	  	StructUnion;
	struct {
	    Lst	  	    members;	/* List of Enums (see below) */
	    word	    min;    	/* Smallest member number */
	    word	    max;    	/* Largest member number */
	    word	    size;	/* Number o bytes this thing takes up*/
	}   	  	Enum;
	struct {
	    Type  	    retType;	/* Type function returns */
	}   	  	Function;
	struct {
	    int	  	    size;   	/* Size of float in bytes */
	}   	  	Float;
	struct {
	    word	    class;  	/* Class of external type */
	    char	    *name;  	/* Name of external type */
	}   	  	External;
	struct {
	    int	  	    size;   	/* Bytes in integer */
	    Boolean	    isSigned;	/* TRUE if signed */
	}   	  	Int;
	struct {
	    int	  	    min;    	/* Minimal character value */
	    int		    max;    	/* Maximal character value */
	    int	    	    size;   	/* size of char (1 or 2) */
	}   	  	Char;
	struct {
	    byte    	    offset;
	    byte    	    width;
	    Type    	    type;
	    struct _Type    *next;   	/* Next cached type at same bit offset*/
	}   	    	BitField;
    }	    	  data;
} TypeRec, *TypePtr;

/*
 * Internal form of Type token
 */
typedef struct {
    VMHandle	file;	    /* 0 if internal descriptor */
    union {
	TypePtr	    internal;
	struct {
	    VMBlockHandle   block;
	    word    	    offset;
	}   	    external;
    }	    	other;
} TypeToken;

#define TypeFile(type) 	(((TypeToken *)&(type))->file)
#define TypeInt(type)	(((TypeToken *)&(type))->other.internal)
#define TypeBlock(type)	(((TypeToken *)&(type))->other.external.block)
#define TypeOffset(type)    (((TypeToken *)&(type))->other.external.offset)

#define TypeIsInt(type) (((TypeToken *)&(type))->file == (VMHandle)0)

/*
 * Type-compression data.
 */
Hash_Table	  structs;  	/* Structured types, hashed by size */

/*
 * Pre-defined types. Since we know this is for an IBM PC, we can define the
 * things here. Unfortunately, all but type_Void must have data and we can't
 * initialize a union, so create the other types in Type_Init.
 */
Type	    type_Void,
	    type_Int,
	    type_Short,
	    type_Long,
	    type_Char,
	    type_WChar,
	    type_SByte,
	    type_UnsignedInt,
	    type_UnsignedShort,
	    type_UnsignedLong,
	    type_UnsignedChar,
	    type_Float,
	    type_Double,
    	    type_LongDouble,
	    type_Byte,
	    type_Word,
	    type_DWord;
	    
#if defined(__HIGHC__) || defined(__BORLANDC__)
/*
 * High C doesn't have in-line structure constructors, so...
 */
Type	NullType = { 0, 0 };
#endif

/*
 * Types used internally for conversion of special external types.
 */
Type	    type_NPtr, type_FPtr, type_SPtr, type_LPtr, type_HPtr, type_OPtr,
	    type_VPtr, type_VFPtr, type_VoidProc;

/*
 * Allocate and initialize a TypeRec, returning NULL if the record
 * couldn't be created.
 */
#define ALLOC_TYPE(t, c) \
    (t) = (TypePtr)malloc_tagged(sizeof(TypeRec), TAG_TYPE); \
    if ((t) == (TypePtr) NULL) { \
	return (NullType); \
    } else { \
	(t)->class = (c); \
	(t)->temp = 0; \
    }

/*
 * Make sure the given type is of the appropriate class and call Punt if not,
 * returning via the statement in the fifth argument.
 */
#define CHECK_CLASS(rT, c, dt, f, ret) \
    if ((rT == NULL) || ((TypePtr)rT)->class != (c)) {\
	Punt("Non-" #dt " type passed to " #f); \
	ret; \
    }

/*
 * Assign the value of var to *ptr only if ptr is non-null.
 */
#define COND_ASSIGN(ptr, var) if (ptr) { *ptr = var; }

/*
 * If the given Type is actually a Sym, fetch its TypePtr into rT,
 * else cast t into a TypePtr and place the result in rT
 */
#define MAKE_TYPE(t, rT, rS) \
    if (!TypeInternalize((t), &(rT), &(rS))) {\
	Punt("invalid external type");\
    }
/*
 * More lenient version of same for TCL functions.
 */
#define MAKE_TYPE_TCL(t, rT, rS) \
    if (!TypeInternalize((t), &(rT), &(rS))) {\
	Tcl_Error(interp, "invalid external type");\
    }

/*
 * Clean up after TypeInternalize, if necessary.
 */
#define CLEANUP_TYPE(t) \
    if ((t) != (TypePtr)NULL && (t)->temp) {\
	(void)free((char *)(t));\
    }
/*
 * Return an internal type descriptor as a Type token
 */
#define RETURN_TYPE(t) {TypeToken _tt; _tt.file = (VMHandle)0; TypeInt(_tt) = (t); return TypeCast(_tt); }


/***********************************************************************
 *				TypeValid
 ***********************************************************************
 * SYNOPSIS:	    See if a Type token is valid
 * CALLED BY:	    INTERNAL
 * RETURN:	    1 if it's ok. 0 if it ain't
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/31/90		Initial Revision
 *
 ***********************************************************************/
static int
TypeValid(Type	type)
{
    if (TypeIsInt(type)) {
	return (malloc_tag((malloc_t)TypeInt(type)) == TAG_TYPE);
    } else {
	VMID	    id;

	if (!VALIDTPTR(TypeFile(type), TAG_VMFILE)) {
	    return(0);
	}
	
	VMInfo(TypeFile(type), TypeBlock(type), (word *)NULL,
	       (MemHandle *)NULL, &id);
	if (id == OID_TYPE_BLOCK) {
	    return(1);
	} else if ((id == OID_SYM_BLOCK) &&
		   (Sym_Class(SymCast(type)) & SYM_TYPE))
	{
	    return(1);
	} else {
	    return(0);
	}
    }
}
    

/***********************************************************************
 *				TypeInternalize
 ***********************************************************************
 * SYNOPSIS:	    Convert an external type into an internal one, if
 *	    	    possible.
 * CALLED BY:	    MAKE_TYPE and MAKE_TYPE_TCL macros
 * RETURN:	    0 if type is bogus
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/31/90		Initial Revision
 *
 ***********************************************************************/
static int
TypeInternalize(Type	    t,
		TypePtr	    *tP,
		Sym 	    *sP)
{
    VMID    	    uid;

    /*
     * If type is already internal, just store that and return success
     */
    if (TypeIsInt(t)) {
	if (Type_IsNull(t)) {
	    return TypeInternalize(type_Void, tP, sP);
	} else {
	    *tP = TypeInt(t);
	    return(malloc_tag((malloc_t)(*tP)) == TAG_TYPE);
	}
    }
    
    /*
     * Convert from external to internal, if possible.
     */
    VMInfo(TypeFile(t), TypeBlock(t), (word *)NULL, (MemHandle *)NULL, &uid);

    if (uid == OID_SYM_BLOCK) {
	/*
	 * Actually a type symbol. Just copy the whole token into *sP and
	 * set *tP to NULL to indicate its externicity, so to speak.
	 */
	*sP = SymCast(t);
	if (Sym_IsNull(*sP)) {
	    return(0);
	}
	assert(Sym_Class(*sP) & SYM_TYPE);
	*tP = NULL;
    } else if (TypeOffset(t) & OTYPE_SPECIAL) {
	/*
	 * Funky single-word descriptor. Use a predefined internal form for
	 * the thing.
	 */
	switch (TypeOffset(t) & OTYPE_TYPE) {
	    case OTYPE_FLOAT:
	    	switch((TypeOffset(t) & OTYPE_DATA) >> OTYPE_DATA_SHIFT) {
		    case 4: *tP = TypeInt(type_Float); break;
		    case 8: *tP = TypeInt(type_Double); break;
		    case 10: *tP = TypeInt(type_LongDouble); break;
		    default: return(0);
		}
		break;
	    case OTYPE_INT:
		switch ((TypeOffset(t) & OTYPE_DATA) >> 1) {
		    case 1: *tP = TypeInt(type_Byte); break;
		    case 2: *tP = TypeInt(type_Word); break;
		    case 4: *tP = TypeInt(type_DWord); break;
		    default: return(0);
		}
		break;
	    case OTYPE_SIGNED:
		switch ((TypeOffset(t) & OTYPE_DATA) >> 1) {
		    case 1: *tP = TypeInt(type_SByte); break;
		    case 2: *tP = TypeInt(type_Short); break;
		    case 4: *tP = TypeInt(type_Long); break;
		    default: return(0);
		}
		break;
	    case OTYPE_NEAR:
	    case OTYPE_FAR:
	    	*tP = TypeInt(type_VoidProc);
		break;
	    case OTYPE_CHAR:
		switch (((TypeOffset(t) & OTYPE_DATA) >> OTYPE_DATA_SHIFT)+1) {
		    case 1:*tP = TypeInt(type_Char); break;
		    case 2:*tP = TypeInt(type_WChar); break;
		    default: return(0);
		}
		break;
	    case OTYPE_VOID: *tP = TypeInt(type_Void); break;
	    case OTYPE_PTR:
		switch(TypeOffset(t) & OTYPE_DATA) {
		    case OTYPE_PTR_FAR: *tP = TypeInt(type_FPtr); break;
		    case OTYPE_PTR_NEAR: *tP = TypeInt(type_NPtr); break;
		    case OTYPE_PTR_LMEM: *tP = TypeInt(type_LPtr); break;
		    case OTYPE_PTR_HANDLE: *tP = TypeInt(type_HPtr); break;
		    case OTYPE_PTR_SEG: *tP = TypeInt(type_SPtr); break;
		    case OTYPE_PTR_OBJ: *tP = TypeInt(type_OPtr); break;
		    case OTYPE_PTR_VM: *tP = TypeInt(type_VPtr); break;
		    case OTYPE_PTR_VIRTUAL: *tP = TypeInt(type_VFPtr); break;
		    default: return(0);
		}
		break;
	    case OTYPE_BITFIELD:
	    {
		Type	new;
		word	bf = TypeOffset(t);

		/*
		 * XXX: assumes Type_CreateBitField is caching things. If it
		 * doesn't, we need to set the temp bit on the result.
		 */
		new = Type_CreateBitField((bf & OTYPE_BF_OFFSET) >> OTYPE_BF_OFFSET_SHIFT,
					  (bf & OTYPE_BF_WIDTH) >> OTYPE_BF_WIDTH_SHIFT,
					  (bf & OTYPE_BF_SIGNED) ? type_Int :
					    	    	type_UnsignedInt);
		*tP = TypeInt(new);
		break;
	    }
	    default:
		return(0);
	}
    } else {
	genptr	tbase = VMLock(TypeFile(t), TypeBlock(t), (MemHandle *)NULL);
	ObjType	*ot = (ObjType *)(tbase + TypeOffset(t));

	if (OTYPE_IS_STRUCT(ot->words[0])) {
	    /*
	     * A structured type. We've only got the name, so lock the name
	     * down and search for it relative to the patient that owns the
	     * file in which this description lies (no point doing any more
	     * work than we might have to by going to the current patient.
	     * that could also cause problems...this way, everyone's happy)
	     */
	    VMHandle	file = TypeFile(t);
	    char    	*name = ST_Lock(file, OTYPE_STRUCT_ID(ot));
	    Patient 	patient = Sym_Patient(SymCast(t));  /* XXX */

	    *sP = Sym_Lookup(name, SYM_TYPE, patient->global);
	    if (Sym_IsNull(*sP)) {
		/*
		 * If the patient in which the type is defined has been
		 * ignored, we could easily fail to find the beast, so warn the
		 * user and return void if the thing couldn't be found. Better
		 * to return type_Void than total failure, as failure causes
		 * a Punt...
		 */
/* this can get really annoying...
		Warning("Cannot find structured type \"%s\"", name);
*/
		*tP = TypeInt(type_Void);
	    } else {
		*tP = NULL;		/* Signal "externicity" */
	    }

	    /*
	     * Release the name and the type block, as we may need to exit
	     * stage left...
	     */
	    ST_Unlock(file, OTYPE_STRUCT_ID(ot));
	    VMUnlock(file, TypeBlock(t));
	} else {
	    Type    base;
	    Type    new;

	    TypeFile(base) = TypeFile(t);
	    TypeBlock(base) = TypeBlock(t);
	    
	    if (OTYPE_IS_PTR(ot->words[0])) {
		TypeOffset(base) = ot->words[1];
		new = Type_CreatePointer(base, OTYPE_PTR_TYPE(ot->words[0]));
	    } else {
		word	len = OTYPE_ARRAY_LEN(ot->words[0]);
		word	nels = 0;

		/*
		 * Deal with arrays > OTYPE_MAX_ARRAY_LEN by moving down the
		 * chain of ObjType's, summing the lengths from each until
		 * we get to one that has <= OTYPE_MAX_ARRAY_LEN elements.
		 */
		while (len == OTYPE_MAX_ARRAY_LEN+1) {
		    nels += len;

		    ot = (ObjType *)(tbase + ot->words[1]);
		    len = OTYPE_ARRAY_LEN(ot->words[0]);
		}
		nels += len;
		TypeOffset(base) = ot->words[1];
		   
		new = Type_CreateArray(0, nels-1, type_Int, base);
	    }
	    /*
	     * Nuke this type on the way out if it's not being returned...
	     */
	    TypeInt(new)->temp = 1;
	    *tP = TypeInt(new);
	    VMUnlock(TypeFile(t), TypeBlock(t));
	}
    }

    return(1);
}

	
    

/***********************************************************************
 *				Type_Destroy
 ***********************************************************************
 * SYNOPSIS:	    Destroy a type description.
 * CALLED BY:	    TypeCmd
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Maybe
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/88	Initial Revision
 *
 ***********************************************************************/
void
Type_Destroy(Type   type)
{
    TypePtr 	t;
    Sym	    	sym;

    MAKE_TYPE(type, t, sym);
    if (t != NULL) {
	/*
	 * Only structures and arrays may be destroyed...
	 */
	switch(t->class) {
	    case TYPE_STRUCT:
	    {
		FieldPtr	f;
		int	    	i;
		
		f = (FieldPtr)Vector_Data(t->data.StructUnion.fields);
		for (i = Vector_Length(t->data.StructUnion.fields);
		     i>0;
		     i--,f++)
    	    	{
		    Type_Destroy(f->type);
		}
		Vector_Destroy(t->data.StructUnion.fields);
		free((char *)t);
		break;
	    }
	    case TYPE_ARRAY:
		Type_Destroy(t->data.Array.baseType);
		free((char *)t);
		break;
	}
    }
}

/***********************************************************************
 *				TypeCmdPrintField
 ***********************************************************************
 * SYNOPSIS:	    Place another structure field in an expandable
 *	    	    buffer for "type fields" command
 * CALLED BY:	    TypeCmd via Type_ForEachField
 * RETURN:	    0 (continue)
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/31/90		Initial Revision
 *
 ***********************************************************************/
static int
TypeCmdPrintField(Type	    base,   	/* Base structure type */
		  char	    *name,  	/* Name of the field */
		  int	    offset, 	/* Bit offset from base */
		  int	    length, 	/* Width of field in bits */
		  Type	    ftype,  	/* Type of field */
		  Opaque    data)   	/* Expandable buffer */
{
    Buffer  buf = (Buffer)data;
    char    foo[32];
    char    *token;

    Buf_AddByte(buf, (Byte)'{');
    if (*name == '\0') {
	Buf_AddBytes(buf, 2, (Byte *)"{}");
    } else {
	Buf_AddBytes(buf, strlen(name), (Byte *)name);
    }
    sprintf(foo, " %d %d {", offset, length);
    Buf_AddBytes(buf, strlen(foo), (Byte *)foo);
    token = Type_ToAscii(ftype);
    Buf_AddBytes(buf, strlen(token), (Byte *)token);
    Buf_AddBytes(buf, 3, (Byte *)"}} ");

    return(0);
}
	

/***********************************************************************
 *				TypeCmdPrintEnum
 ***********************************************************************
 * SYNOPSIS:	    Add another enum to an expandable buffer for TypeCmd
 * CALLED BY:	    TypeCmd via Type_ForEachEnum
 * RETURN:  	    0 (continue)	
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/31/90		Initial Revision
 *
 ***********************************************************************/
static int
TypeCmdPrintEnum(Type	    type,   	/* Enumerated type */
		 char	    *name,  	/* Constant's name */
		 int	    value,  	/* Constant's value */
		 Opaque	    data)   	/* Expandable buffer */
{
    Buffer  buf = (Buffer)data;
    char    num[16];

    Buf_AddByte(buf, (Byte)'{');
    Buf_AddBytes(buf, strlen(name), (Byte *)name);
    sprintf(num, " %d} ", value);
    Buf_AddBytes(buf, strlen(num), (Byte *)num);

    return(0);
}

/***********************************************************************
 *				Type_ToToken
 ***********************************************************************
 * SYNOPSIS:	    Convert an ASCII symbol token to its internal form
 * CALLED BY:	    SymbolCmd, EXTERNAL
 * RETURN:	    Sym for the symbol. 
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    A TCL-level Sym token is a 3-list
 *	    	    	{<file> <block> <offset>}
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/27/90		Initial Revision
 *
 ***********************************************************************/
Type
Type_ToToken(char    *token)
{
    TypeToken	    ftype;
    int	    	    argc;
    char    	    **argv;

    if (Tcl_SplitList(interp, token, &argc, &argv) != TCL_OK) {
	return NullType;
    }
    if (argc != 3) {
	Tcl_Return(interp, "malformed type token", TCL_STATIC);
	free((char *)argv);
	return NullType;
    }
    ftype.file = (VMHandle)atoi(argv[0]);
    ftype.other.external.block = (VMBlockHandle)atoi(argv[1]);
    ftype.other.external.offset = (word)atoi(argv[2]);
    free((char *)argv);

    if (!TypeValid(TypeCast(ftype))) {
	return NullType;
    }
    
    return (TypeCast(ftype));
}


/***********************************************************************
 *				Type_IsNull
 ***********************************************************************
 * SYNOPSIS:	    See if a type is NullType
 * CALLED BY:	    EXTERNAL
 * RETURN:	    TRUE if the type is null
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 1/90		Initial Revision
 *
 ***********************************************************************/
Boolean
Type_IsNull(Type    type)
{
    return ((TypeFile(type) == NULL) &&
	    (TypeBlock(type) == 0) &&
	    (TypeOffset(type) == 0));
}

/***********************************************************************
 *				Type_ToAscii
 ***********************************************************************
 * SYNOPSIS:	    Convert an internal Type token to an ascii string
 *	    	    suitable for return to TCL.
 * CALLED BY:	    SymbolCmd, EXTERNAL
 * RETURN:	    Address of a *static* buffer containing the necessary
 *	    	    3-list
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/27/90		Initial Revision
 *
 ***********************************************************************/
char *
Type_ToAscii(Type   type)
{
    static char	token[32];

    if ((TypeFile(type) == NULL) && (TypeBlock(type) == 0) &&
	(TypeOffset(type) == 0))
    {
	strcpy(token, "nil");
    } else {
	sprintf(token, "%d %d %d", (int)TypeFile(type), TypeBlock(type),
		TypeOffset(type));
    }

    return(token);
}

/***********************************************************************
 *				TypeCmd
 ***********************************************************************
 * SYNOPSIS:	    Create a type description
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    A description is created.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/30/88	Initial Revision
 *
 ***********************************************************************/
#define TYPE_PREDEF (ClientData)0
#define TYPE_MAKE   (ClientData)1
#define TYPE_SIZE   (ClientData)2
#define TYPE_CLASS  (ClientData)3
#define TYPE_NAME   (ClientData)4
#define TYPE_AGET   (ClientData)5
#define TYPE_FIELDS (ClientData)6
#define TYPE_MEMBERS (ClientData)7
#define TYPE_PGET   (ClientData)8
#define TYPE_FIELD  (ClientData)9
#define TYPE_SIGNED (ClientData)10
#define TYPE_BFGET  (ClientData)11
#define TYPE_DELETE (ClientData)12
#define TYPE_EMAP   (ClientData)13
static const CmdSubRec typeCmds[] = {
    {"make", 	TYPE_MAKE,  1, CMD_NOCHECK, "(array|pstruct|struct|nptr|fptr|sptr|lptr|hptr|optr|vptr|vfptr) ..."},
    {"size", 	TYPE_SIZE,  1, 1, "<type>"},
    {"class",	TYPE_CLASS, 1, 1, "<type>"},
    {"name", 	TYPE_NAME,  3, 3, "<type> <tag> <expand>"},
    {"aget", 	TYPE_AGET,  1, 1, "<array-type>"},
    {"fields",	TYPE_FIELDS,1, 1, "<struct-type>"},
    {"members",	TYPE_MEMBERS,1,1, "<enum-type>"},
    {"pget", 	TYPE_PGET,  1, 1, "<ptr-type>"},
    {"emap", 	TYPE_EMAP,  2, 2, "<num> <enum-type>"},
    {"signed",	TYPE_SIGNED,1, 1, "<type>"},
    {"field",	TYPE_FIELD, 2, 2, "<struct-type> <offset>"},
    {"delete",	TYPE_DELETE,1, 1, "<type>"},
    {"bfget",	TYPE_BFGET, 1, 1, "<bitfield-type>"},
    {"",		TYPE_PREDEF,0, 0, ""},
    {NULL,	(ClientData)NULL,	    0, 0, NULL}
};
DEFCMD(type,Type,0,typeCmds,swat_prog,
"Usage:\n\
    type <basic-type-name>\n\
    type make array <length> <base-type>\n\
    type make pstruct (<field> <type>)+\n\
    type make struct (<field> <type> <bit-offset> <bit-length>)+\n\
    type make union (<field> <type>)+\n\
    type make <ptr-type> <base-type>\n\
    type delete <type>\n\
    type size <type>\n\
    type class <type>\n\
    type name <type> <var-name> <expand>\n\
    type aget <array-type>\n\
    type fields <struct-type>\n\
    type members <enum-type>\n\
    type pget <ptr-type>\n\
    type emap <num> <enum-type>\n\
    type signed <type>\n\
    type field <struct-type> <offset>\n\
    type bfget <bitfield-type>\n\
\n\
Examples:\n\
    \"type word\"	    	    	Returns a type token for a word (2-byte\n\
				unsigned quantity).\n\
    \"type make array 10 [type char]\"\n\
    	    	    	    	Returns a type token for a 10-character array.\n\
    \"type make optr [symbol find type GenBase]\"\n\
    	    	    	    	Returns a type token for an optr (4-byte\n\
				global/local handle pair) to a \"GenBase\"\n\
				structure.\n\
\n\
Synopsis:\n\
    Provides access to the type descriptions by which all PC-based data are\n\
    manipulated in Swat, and allows a Tcl procedure to obtain information\n\
    about a type for display to the user, or for its own purposes. As with\n\
    other Swat commands, this works by calling one subcommand to obtain an\n\
    opaque \"type token\", which you then pass to other commands.\n\
\n\
Notes:\n\
    * Type tokens and symbol tokens for type-class symbols may be freely\n\
      interchanged anywhere in Swat.\n\
\n\
    * There are 11 predefined basic types that can be given as the\n\
      <basic-type-name> argument in \"type <basic-type-name>\". They are:\n\
	byte	    single-byte unsigned integer\n\
	char	    single-byte character\n\
	double	    eight-byte floating-point\n\
	dword	    four-byte unsigned integer\n\
	float	    four-byte floating-point\n\
	int 	    two-byte signed integer\n\
	long	    four-byte signed integer\n\
	sbyte	    single-byte signed integer\n\
	short	    two-byte signed integer\n\
	void	    nothing. useful as the base type for a pointer type\n\
	word	    two-byte unsigned integer\n\
\n\
    * Most type tokens are obtained, via the \"symbol get\" and \"symbol tget\"\n\
      commands, from symbols that are defined for a loaded patient. These are\n\
      known as \"external\" type descriptions. \"Internal\" type descriptions are\n\
      created with the \"type make\" command and should be deleted, with \"type\n\
      delete\" when they are no longer needed.\n\
\n\
    * An internal structure type description can be created using either the\n\
      \"pstruct\" (packed structure) or \"struct\" subcommands. Using \"pstruct\" is\n\
      simpler, but you have no say in where each field is placed (they are\n\
      placed at sequential offsets with no padding between fields), and all\n\
      fields must be a multiple of 8 bits long. The \"struct\" subcommand is\n\
      more complex, but does allow you to specify bitfields.\n\
\n\
    * \"type make pstruct\" takes 1 or more pairs of arguments of the form\n\
      \"<field> <type>\", where <field> is the name for the field and <type> is\n\
      a type token giving the data type for the field. All fields must be\n\
      specified for the structure in this call; fields cannot be appended to\n\
      an existing type description.\n\
\n\
    * \"type make struct\" takes 1 or more 4-tuples of arguments of the form\n\
      \"<field> <type> <bit-offset> <bit-length>\". <field> is the name of the\n\
      field, and <type> is its data type. <bit-offset> is the offset, in bits,\n\
      from the start of the structure (starting with 0, as you'd expect).\n\
      <bit-length> is the length of the field, in bits (starting with 1, as\n\
      you'd expect).  For a bitfield, <type> should be the field within which\n\
      the bitfield is defined. For example, the C declaration:\n\
    	struct {\n\
    	    word    a:6;\n\
	    word    b:10;\n\
	    word    c;\n\
    	}\n\
      would result in the command \"type make struct a [type word] 0 6 b [type\n\
      word] 6 10 c [type word] 16 16\", because a and b are defined within a\n\
      word type, and c is itself a word.\n\
\n\
    * \"type make union\" is similar to \"type make pstruct\", except all fields\n\
      start at offset 0. Like \"pstruct\", this cannot be used to hold\n\
      bitfields, except by specifying a type created via \"type make struct\"\n\
      command as the <type> for one of the fields.\n\
\n\
    * \"type make array <length> <base-type>\" returns a token for an array of\n\
      <length> elements of the given <base-type>, which may be any valid type\n\
      token, including another array type.\n\
\n\
    * \"type make <ptr-type> <base-type>\" returns a token for a pointer to the\n\
      given <base-type>. There are 6 different classes of pointers in GEOS:\n\
    	nptr	a near pointer. 16-bits. points to something in the same\n\
	    	segment as the pointer itself.\n\
    	fptr	a far pointer. 32-bits. segment in high word, offset in the\n\
      	    	low.\n\
    	sptr	a segment pointer. 16-bits. contains a segment only.\n\
    	lptr	an lmem pointer. 16-bits. contains a local-memory \"chunk\n\
      	    	handle\". data pointed to is assumed to be in the same segment\n\
      	    	as the lptr itself, but requires two indirections to get to it.\n\
    	hptr	a handle pointer. 16-bits. a GEOS handle.\n\
    	optr	an object pointer. 32-bits. contains a GEOS memory handle\n\
      	    	in the high word, and a GEOS local-memory chunk handle in\n\
      	    	the low.\n\
	vptr	a VM pointer. 32-bits. contains a GEOS file handle in the high\n\
		word, and a GEOS VM block handle in the low.\n\
	vfptr	a virtual far pointer. 32-bits. contains a virtual segment in\n\
		the high word, and an offset in the low.\n\
    * \"type delete\" is used to delete a type description created by \"type\n\
      make\". You should do this whenever possible to avoid wasting memory.\n\
\n\
    * NOTE: any type created by the \"type make\" command is subject to garbage\n\
      collection unless it is registered with the garbage collector. If you need\n\
      to keep a type description beyond the end of the command being executed,\n\
      you must register it. See the \"gc\" command for details.\n\
\n\
    * \"type size\" returns the size of the passed type, in bytes.\n\
\n\
    * \"type class\" returns the class of a type, a string in the following set:\n\
    	char	    for the basic \"char\" type only.\n\
	int 	    any integer, signed or unsigned.\n\
	struct	    a structure, record, or union.\n\
	enum	    an enumerated type.\n\
	array	    an array, of course,\n\
	pointer	    a pointer to another type.\n\
	void	    nothingness. Often a base for a pointer.\n\
	function    a function, used solely as a base for a pointer.\n\
	float	    a floating-point number.\n\
      Each type class has certain data associated with it that can only be\n\
      obtained by using the proper subcommand.\n\
\n\
    * \"type aget\" applies only to an array-class type token. It returns a\n\
      four-element list: {<base-type> <low> <high> <index-type>} <base-type>\n\
      is the type token describing elements of the array. <low> is the lower\n\
      bound for an index into the array (currently always 0), <high> is the\n\
      inclusive upper bound for an index into the array, and <index-type> is a\n\
      token for the data type that indexes the array (currently always [type\n\
      int]).\n\
\n\
    * \"type fields\" applies only to a struct-class type token. It returns a\n\
      list of four-tuples {<name> <offset> <length> <type>}, one for each\n\
      field in the structure. <offset> is the *bit* offset from the start of\n\
      the structure, while <length> is the length of the field, again in\n\
      *bits*. <type> is the token for the data type of the field, and <name>\n\
      is, of course, the field's name.\n\
\n\
    * \"type members\" applies only to an enum-class type token. It returns a\n\
      list of {<name> <value>} pairs for the members of the enumerated type.\n\
\n\
    * \"type pget\" applies only to a pointer-class type token. It returns the\n\
      type of pointer (\"near\", \"far\", \"seg\", \"lmem\", \"handle\", \n\
      \"object\", \"virtual\", or \"vm\") and the token for the type to which\n\
      it points.\n\
\n\
    * \"type bfget\" returns a three-list for the given bitfield type:\n\
	{<offset> <width> <is-signed>}\n\
\n\
    * \"type signed\" returns non-zero if the type is signed. If the <type> is\n\
      not an int-class type, it is considered unsigned.\n\
\n\
    * \"type emap\" can be used to map an integer to its corresponding\n\
      enumerated constant. If no member of the enumerated type described by\n\
      <type> has the value indicated, \"nil\" is returned, else the name of the\n\
      matching constant is returned.\n\
\n\
    * \"type field\" maps an offset into the passed struct-class type into a\n\
      triple of the form {<name> <length> <ftype>}, where <name> can be either\n\
      a straight field name, or a string of the form <field>.<field>... with\n\
      as many .<field> clauses as necessary to get to the smallest field in\n\
      the nested structure <type> that covers the given byte <offset> bytes\n\
      from the start of the structure. <length> is the *bit* length of the\n\
      field, and <ftype> is its type.\n\
\n\
    * \"type name\" produces a printable description of the given type, using C\n\
      syntax. <varname> is the name of the variable to which the type belongs.\n\
      It will be placed at the proper point in the resulting string. If\n\
      <expand> is non-zero, structured types (including enumerated types) are\n\
      expanded to display their fields (or members, as the case may be).\n\
\n\
See also:\n\
    gc, symbol, symbol-types, value\n\
")
{
    Type    type;
    TypePtr t;
    Sym	    sym;

    if (clientData >= TYPE_SIZE && clientData <= TYPE_DELETE) {
	type = Type_ToToken(argv[2]);
	if (!TypeValid(type)) {
	    Tcl_RetPrintf(interp, "type %s: %s not a type", argv[1], argv[2]);
	    return(TCL_ERROR);
	}
    }

	    
    switch((int)clientData) {
	case (int)TYPE_MAKE:
	    /*
	     * Construct a new structured type.
	     */
	    if (strcmp(argv[2], "array") == 0) {
		/*
		 * type make array <length> <base-type>
		 */
		Type    base;
		int	    length;
		
		if (argc != 5) {
		    Tcl_Error(interp, "Usage: type make array <length> <base>");
		}
		
		length = cvtnum(argv[3], NULL);
		base = Type_ToToken(argv[4]);
		
		if (!TypeValid(base)) {
		    Tcl_RetPrintf(interp, "type make array: %s not a type",
				  argv[4]);
		    return(TCL_ERROR);
		} else if (length == 0) {
		    Tcl_Error(interp, "type make array: zero-length array?");
		}
		
		Tcl_Return(interp, Type_ToAscii(Type_CreateArray(0, length - 1,
								 type_Int,
								 base)),
			   TCL_VOLATILE);
	    } else if (strcmp(argv[2], "pstruct") == 0) {
		/*
		 * type make pstruct <name> <type> ...
		 *
		 */
		int	    i;	    /* Index into argv */
		int	    offset; /* Current offset into structure */
		TypePtr t;	    /* New type */
		Type    rtype;
		
		/*
		 * Start with a 0-sized structure -- we'll fill in the size
		 * later.
		 */
		rtype = Type_CreateStruct(0);
		t = TypeInt(rtype);
		offset = 0;
		
		/*
		 * Scan off the fields one at a time.
		 */
		for (i = 3; i < argc; i += 2) {
		    Type    ftype;  /* Field type */
		    int	size;   /* Size of field */
		    
		    if (i + 1 >= argc) {
			Tcl_RetPrintf(interp,
				      "type make pstruct ... %s: missing type.",
				      argv[i]);
			Type_Destroy(rtype);
			return(TCL_ERROR);
		    }
		    
		    ftype = Type_ToToken(argv[i+1]);
		    if (!TypeValid(ftype)) {
			Tcl_RetPrintf(interp,
				      "type make pstruct ... %s %s: not a type",
				      argv[i], argv[i+1]);
			Type_Destroy(rtype);
			return(TCL_ERROR);
		    }
		    
		    size = Type_Sizeof(ftype);
		    
		    Type_AddField(rtype, argv[i], offset, size*8, ftype);
		    offset += size*8;
		    t->data.StructUnion.size += size;
		}
#if COMPRESS_DUPLICATE_STRUCTURES
		/*
		 * Finish out the structure definition by compressing duplicate
		 * definitions.
		 */
		type = (Type)t;
		t = (TypePtr)Type_EndStructUnion(type);
		
		/*
		 * If the first field isn't around, create symbols for them all.
		 * We run into a problem with re-attaching, where the type
		 * description remains, but the field symbols are inaccessible,
		 * since the patient has been discarded. That's why we actually
		 * look for one of the fields, rather than relying on the structure
		 * being compressed out.
		 */
		if (argc > 3 &&
		    Sym_Lookup(argv[3], SYM_FIELD,
			       (curPatient->scope ?
				curPatient->scope :
				curPatient->global))==NullSym)
		{
		    /*
		     * Create FIELD symbols for all the fields in the new structure
		     */
		    for (i = 3; i < argc; i += 2) {
			Sym fsym = Sym_Make(argv[i], SYM_FIELD);
			
			Sym_Enter(fsym, (curPatient->scope ?
					 curPatient->scope :
					 curPatient->global));
			Sym_SetFieldData(fsym, (Type)t);
		    }
		}	
#endif
		Tcl_Return(interp, Type_ToAscii(rtype), TCL_VOLATILE);
	    } else if (strcmp(argv[2], "struct") == 0) {
		/*
		 * type make struct <field> ...
		 *
		 * field := <name> <type> <bit-offset> <bit-width>
		 */
		int	    i;	    /* Index into argv */
		int	    base;   /* Bit offset to field base */
		int	    width;  /* Width of field */
		Type    type;   /* Type of field */
		Type    stype;  /* Structure being created */
		
		/*
		 * Start with a 0-byte structure -- we'll figure the
		 * real size as we go along.
		 */
		stype = Type_CreateStruct(0);
		
		/*
		 * Scan off the fields one at a time.
		 */
		for (i = 3; i < argc; i += 4) {
		    if (i + 4 > argc) {
			Tcl_RetPrintf(interp, "%s has incomplete field record",
				      argv[i]);
			Type_Destroy(stype);
			return(TCL_ERROR);
		    }
		    
		    type = Type_ToToken(argv[i+1]);
		    base = cvtnum(argv[i+2], NULL);
		    width = cvtnum(argv[i+3], NULL);
		    if (width < 0) {
			width = Type_Sizeof(type) * 8;
		    }
		    
		    
		    if (((base+width+7)/8)>(TypeInt(stype))->data.StructUnion.size)
		    {
			TypeInt(stype)->data.StructUnion.size=((base+width+7)/8);
		    }
		    
		    if (!TypeValid(type)) {
			Tcl_RetPrintf(interp,
				      "type make struct ... %s %s: not a type",
				      argv[i], argv[i+1]);
			Type_Destroy(stype);
			return(TCL_ERROR);
		    }
		    
		    Type_AddField(stype, argv[i], base, width, type);
		}
#if COMPRESS_DUPLICATE_STRUCTURES
		/*
		 * Finish out the structure definition by compressing duplicate
		 * definitions.
		 */
		type = stype;
		stype = Type_EndStructUnion(type);
		
		/*
		 * If the first field isn't around, create symbols for them all.
		 * We run into a problem with re-attaching, where the type
		 * description remains, but the field symbols are inaccessible,
		 * since the patient has been discarded. That's why we actually
		 * look for one of the fields, rather than relying on the structure
		 * being compressed out.
		 */
		if (argc > 3 &&
		    Sym_Lookup(argv[3], SYM_FIELD,
			       (curPatient->scope ?
				curPatient->scope :
				curPatient->global))==NullSym)
		{
		    /*
		     * Create FIELD symbols for all the fields in the new structure
		     */
		    for (i = 3; i < argc; i += 4) {
			Sym fsym = Sym_Make(argv[i], SYM_FIELD);
			
			Sym_Enter(fsym, (curPatient->scope ?
					 curPatient->scope :
					 curPatient->global));
			Sym_SetFieldData(fsym, (Type)stype);
		    }
		}	
#endif
		Tcl_Return(interp, Type_ToAscii(stype), TCL_VOLATILE);
	    } else if (strcmp(argv[2], "union") == 0) {
		/*
		 * type make union <size> <field> ...
		 *
		 * field := <name> <type>
		 */
		int	    i;	    /* Index into argv */
		Type    type;   /* Type of field */
		Type    stype;  /* Structure being created */
		
		assert(argc >= 4);
		stype = Type_CreateUnion(atoi(argv[3]));
		
		/*
		 * Scan off the fields one at a time.
		 */
		for (i = 4; i < argc; i += 2) {
		    if (i + 2 > argc) {
			Tcl_RetPrintf(interp, "%s has incomplete field record",
				      argv[i]);
			Type_Destroy(stype);
			return(TCL_ERROR);
		    }
		    
		    type = Type_ToToken(argv[i+1]);
		    
		    
		    if (!TypeValid(type)) {
			Tcl_RetPrintf(interp,
				      "type make struct ... %s %s: not a type",
				      argv[i], argv[i+1]);
			Type_Destroy(stype);
			return(TCL_ERROR);
		    }
		    
		    Type_AddField(stype, argv[i], 0, Type_Sizeof(type)*8, type);
		}
#if COMPRESS_DUPLICATE_STRUCTURES
		/*
		 * Finish out the structure definition by compressing duplicate
		 * definitions.
		 */
		type = stype;
		stype = Type_EndStructUnion(type);
		
		/*
		 * If the first field isn't around, create symbols for them all.
		 * We run into a problem with re-attaching, where the type
		 * description remains, but the field symbols are inaccessible,
		 * since the patient has been discarded. That's why we actually
		 * look for one of the fields, rather than relying on the structure
		 * being compressed out.
		 */
		if (Sym_Lookup(argv[3], SYM_FIELD,
			       (curPatient->scope ?
				curPatient->scope :
				curPatient->global))==NullSym)
		{
		    /*
		     * Create FIELD symbols for all the fields in the new structure
		     */
		    for (i = 3; i < argc; i += 4) {
			Sym fsym = Sym_Make(argv[i], SYM_FIELD);
			
			Sym_Enter(fsym, (curPatient->scope ?
					 curPatient->scope :
					 curPatient->global));
			Sym_SetFieldData(fsym, (Type)stype);
		    }
		}	
#endif
		Tcl_Return(interp, Type_ToAscii(stype), TCL_VOLATILE);
	    } else if ((strcmp(argv[2], "ptr") == 0) ||
		       (strcmp(&argv[2][1], "ptr") == 0))
	    {
		int	    ptrType;
		Type    ptype, type;
		
		if (argc != 4) {
		    Tcl_Error(interp, "Usage: type make (nptr|sptr|fptr|lptr|hptr|optr) <type>");
		}
		
		type = Type_ToToken(argv[3]);
		if (!TypeValid(type)) {
		    Tcl_RetPrintf(interp, "type make ptr: %s not a type", argv[3]);
		    return(TCL_ERROR);
		}
		
		switch (argv[2][0]) {
		    case 's': ptrType = TYPE_PTR_SEG; break;
		    case 'f': ptrType = TYPE_PTR_FAR; break;
		    case 'l': ptrType = TYPE_PTR_LMEM; break;
		    case 'h': ptrType = TYPE_PTR_HANDLE; break;
		    case 'o': ptrType = TYPE_PTR_OBJECT; break;
		    case 'v':
			if (argv[2][1] == 'f') {
			    ptrType = TYPE_PTR_VIRTUAL;
			} else {
			    ptrType = TYPE_PTR_VM;
			}
			break;
		    default:  ptrType = TYPE_PTR_NEAR; break;
		}
		ptype = Type_CreatePointer(type, ptrType);
		Tcl_Return(interp, Type_ToAscii(ptype), TCL_VOLATILE);
	    } else {
		return(TCL_SUBUSAGE);
	    }
	    break;
	case (int)TYPE_SIZE:
	    Tcl_RetPrintf(interp, "%d", Type_Sizeof(type));
	    break;
	case (int)TYPE_CLASS:
	{
	    char	*res;
	    
	    switch(Type_Class(type)) {
		case TYPE_CHAR: res = "char"; break;
		case TYPE_INT:  res = "int"; break;
		case TYPE_STRUCT: res = "struct"; break;
		case TYPE_UNION: res = "union"; break;
		case TYPE_ENUM: res = "enum"; break;
		case TYPE_ARRAY: res = "array"; break;
		case TYPE_POINTER: res = "pointer"; break;
		case TYPE_VOID: res = "void"; break;
		case TYPE_FUNCTION: res = "function"; break;
		case TYPE_FLOAT: res = "float"; break;
		case TYPE_BITFIELD: res = "bitfield"; break;
		case TYPE_NULL: res = "nil"; break;
		default: res = "???"; break;
	    }
	    Tcl_Return(interp, res, TCL_STATIC);
	    break;
	}
	case (int)TYPE_NAME:
	    Tcl_Return(interp, Type_Name(type, argv[3], atoi(argv[4])),
		       TCL_DYNAMIC);
	    break;
	case (int)TYPE_AGET:
	{
	    char	baseToken[32];
	    Type	base, index;
	    int 	lower, upper;
    
	    MAKE_TYPE_TCL(type,t,sym);
	    if (Type_Class(type) != TYPE_ARRAY) {
		Tcl_Error(interp, "not an array type");
	    }
	    Type_GetArrayData(type, &lower, &upper, &index, &base);
	    strcpy(baseToken, Type_ToAscii(base));
	    Tcl_RetPrintf(interp, "{%s} %d %d {%s}",
			  baseToken, lower, upper, Type_ToAscii(index));
	    CLEANUP_TYPE(t);
	    break;
	}
	case (int)TYPE_FIELDS:
	{
	    Buffer	    buf;
	    
	    MAKE_TYPE_TCL(type, t, sym);
	    if (t == NULL) {
		switch (Sym_Type(sym)) {
		    case OSYM_RECORD:
		    case OSYM_UNION:
		    case OSYM_STRUCT:
			break;
		    default:
			Tcl_Error(interp, "not a structure type");
		}
	    } else if (t->class != TYPE_STRUCT && t->class != TYPE_UNION) {
		Tcl_Error(interp, "not a struct type");
	    }
	    buf = Buf_Init(0);
	    Type_ForEachField(type, TypeCmdPrintField, (Opaque)buf);
	    Tcl_Return(interp, (char *)Buf_GetAll(buf, NULL), TCL_DYNAMIC);
	    Buf_Destroy(buf, FALSE);
	    CLEANUP_TYPE(t);
	    break;
	}
	case (int)TYPE_MEMBERS:
	{
	    Buffer	    buf;
	    
	    MAKE_TYPE_TCL(type, t, sym);
	    if (t == NULL) {
		if (Sym_Type(sym) != OSYM_ETYPE) {
		    Tcl_Error(interp, "not an enumerated type");
		}
	    } else if (t->class != TYPE_ENUM) {
		Tcl_Error(interp, "not an enumerated type");
	    }
	    buf = Buf_Init(0);
	    Type_ForEachEnum(type, TypeCmdPrintEnum, (Opaque)buf);
	    Tcl_Return(interp, (char *)Buf_GetAll(buf, NULL), TCL_DYNAMIC);
	    Buf_Destroy(buf, FALSE);
	    CLEANUP_TYPE(t);
	    break;
	}
	case (int)TYPE_PGET:
	{
	    char	*ptrType;
	    
	    MAKE_TYPE_TCL(type, t, sym);
	    /*
	     * look up each typedef until we get to the pointer base type
	     */
	    while((t == NULL) && (Sym_Type(sym) == OSYM_TYPEDEF)) {
		MAKE_TYPE_TCL(Sym_GetTypeData(sym), t, sym);
	    }
	    if ((t == NULL) || (t->class != TYPE_POINTER)) {
		Tcl_Error(interp, "not a pointer type");
	    }

	    switch(t->data.Pointer.ptrType) {
		case TYPE_PTR_NEAR: ptrType = "near"; break;
		case TYPE_PTR_FAR: ptrType = "far"; break;
		case TYPE_PTR_SEG: ptrType = "seg"; break;
		case TYPE_PTR_LMEM: ptrType = "lmem"; break;
		case TYPE_PTR_HANDLE: ptrType = "handle"; break;
		case TYPE_PTR_OBJECT: ptrType = "object"; break;
	        case TYPE_PTR_VIRTUAL: ptrType = "virtual"; break;
		case TYPE_PTR_VM: ptrType = "vm"; break;
		default: assert(0); ptrType = "unknown"; break;
	    }
	    
	    Tcl_RetPrintf(interp, "%s {%s}", ptrType,
			  Type_ToAscii(t->data.Pointer.baseType));
	    CLEANUP_TYPE(t);
	    break;
	}
	case (int)TYPE_EMAP:
	{
	    Type	type;
	    TypePtr	t;
	    char	*name;
	    
	    type = Type_ToToken(argv[3]);
	    if (!TypeValid(type)) {
		Tcl_Error(interp, "not a valid type");
	    }
	    MAKE_TYPE_TCL(type, t, sym);
	    if (t == NULL) {
		if (Sym_Type(sym) != OSYM_ETYPE) {
		    Tcl_Error(interp, "not an enumerated type");
		}
	    } else if (t->class != TYPE_ENUM) {
		Tcl_Error(interp, "not an enumerated type");
	    }
	    name = Type_GetEnumName(type, cvtnum(argv[2], NULL));
	    Tcl_RetPrintf(interp, "%s", name ? name : "nil");
	    CLEANUP_TYPE(t);
	    break;
	}
	case (int)TYPE_SIGNED:
	    Tcl_RetPrintf(interp, "%d", Type_IsSigned(type));
	    break;
	case (int)TYPE_BFGET:
	    MAKE_TYPE_TCL(type, t, sym);
	    if ((t == NULL) || (t->class != TYPE_BITFIELD)) {
		Tcl_Error(interp, "not a bitfield type");
	    }

	    Tcl_RetPrintf(interp, "%d %d {%s}",
			  t->data.BitField.offset,
			  t->data.BitField.width,
			  Type_ToAscii(t->data.BitField.type));
	    CLEANUP_TYPE(t);
	    break;
	case (int)TYPE_PREDEF:
	{
	    static struct {
		char	*name;
		Type	*typePtr;
	    }	predefs[] = {
		{"char",	&type_Char},
		{"wchar",    &type_WChar},
		{"word",	&type_Word},
		{"byte",	&type_Byte},
		{"dword",    &type_DWord},
		{"int",	&type_Int},
		{"short",    &type_Short},
		{"long",	&type_Long},
		{"void",	&type_Void},
		{"sbyte",    &type_SByte},
		{"float",    &type_Float},
		{"double",   &type_Double}
	    };
	    int 	i;
	    
	    /*
	     * See if it's a predefined type.
	     */
	    for (i = 0; i < Number(predefs); i++) {
		if (strcmp(argv[1], predefs[i].name) == 0) {
		    Tcl_Return(interp, Type_ToAscii(*predefs[i].typePtr),
			       TCL_VOLATILE);
		    return(TCL_OK);
		}
	    }
	    return (TCL_USAGE);
	}
	case (int)TYPE_FIELD:
	{
	    /*
	     * Figure the field of the given type at the given offset. Handles
	     * fields within fields, returning a string <field1>.<field2>...
	     * to be as specific as possible.
	     */
	    int 	    offset;
	    char	    *name;
	    int 	    length;
	    Type	    ftype;
	    
	    MAKE_TYPE_TCL(type, t, sym);
	    if (t == NULL) {
		switch(Sym_Type(sym)) {
		    case OSYM_STRUCT:
		    case OSYM_UNION:
			break;
		    case OSYM_RECORD:
			Tcl_Return(interp, NULL, TCL_STATIC);
			return(TCL_OK);
		    default:
			Tcl_Error(interp, "not a struct type");
		}
	    } else if (t->class != TYPE_STRUCT) {
		Tcl_Error(interp, "not a struct type");
	    }
	    offset = cvtnum(argv[3], NULL);
	    
	    /*
	     * Make sure it's not negative -- that would really screw us up.
	     */
	    if (offset < 0) {
		Tcl_Return(interp, NULL, TCL_STATIC);
		return(TCL_OK);
	    }
	    
	    if (!Type_FindFieldData(type, offset * 8, &name, &length,
				    &ftype, NULL))
	    {
		Tcl_Return(interp, NULL, TCL_STATIC);
	    } else {
		Tcl_RetPrintf(interp, "%s %d {%s}", name, length,
			      Type_ToAscii(ftype));
		free(name);
	    }
	    CLEANUP_TYPE(t);
	    break;
	}
	case (int)TYPE_DELETE:
	    Type_Destroy(type);
	    break;
    }
    return(TCL_OK);
}

/*-
 *-----------------------------------------------------------------------
 * Type_CreateInt --
 *	Create a type to describe a variety of integer. The integer is
 *	size bytes long and is signed, according to the 'isSigned' parameter.
 *
 * Results:
 *	The new type.
 *
 * Side Effects:
 *	The type is created.
 *
 *-----------------------------------------------------------------------
 */
Type
Type_CreateInt(int	  size,
	       Boolean	  isSigned)
{
    TypePtr 	  t;
    
    ALLOC_TYPE(t, TYPE_INT);
    t->data.Int.size = size;
    t->data.Int.isSigned = isSigned;

    RETURN_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_CreateChar --
 *	Create a type to describe a variety of character. A character
 *	is usually a single byte long and its value can range from min
 *	to max. min may be negative.
 *
 * Results:
 *	The new type.
 *
 * Side Effects:
 *	The type be created.
 *
 *-----------------------------------------------------------------------
 */
Type
Type_CreateChar(int	minChar,
		int 	maxChar,
		int 	size)
{
    TypePtr 	  t;
    
    ALLOC_TYPE(t, TYPE_CHAR);
    t->data.Char.min = minChar;
    t->data.Char.max = maxChar;
    t->data.Char.size = size;

    RETURN_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_GetCharData --
 *	Find the bounding values of the given character.
 *
 * Results:
 *	The min and max for a character of that type.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
void
Type_GetCharData(Type	type,
		 int	*minPtr,
		 int	*maxPtr)
{
    TypePtr 	t;
    Sym	    	sym;
    
    MAKE_TYPE(type, t, sym);
    assert(t != NULL);	    	    /* No external form */

    CHECK_CLASS(t, TYPE_CHAR, character, Type_GetCharData, return);
    
    COND_ASSIGN(minPtr, t->data.Char.min);
    COND_ASSIGN(maxPtr, t->data.Char.max);
    CLEANUP_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_CreatePointer --
 *	Create a Type that is a pointer to the given baseType. Note the
 *	cacheing of pointer types is taken care of here.
 *
 * Results:
 *	The newly created Type.
 *
 * Side Effects:
 *	The pointerTo field of baseType is altered if a pointer type for
 *	baseType didn't already exist.
 *
 *-----------------------------------------------------------------------
 */
Type
Type_CreatePointer(Type	baseType, int ptrType)
{
    TypePtr	  t;

    ALLOC_TYPE(t, TYPE_POINTER);
    t->data.Pointer.baseType = baseType;
    t->data.Pointer.ptrType = ptrType;
    RETURN_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_GetPointerData --
 *	Find the type pointed to by the given pointer type.
 *
 * Results:
 *	The base type of the pointer.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
void
Type_GetPointerData(Type    type,
		    int	    *ptype,
		    Type    *base)
{
    TypePtr	t;
    Sym	    	sym;

    MAKE_TYPE(type, t, sym);
    
    CHECK_CLASS(t, TYPE_POINTER, pointer, Type_GetPointerBase, return);

    COND_ASSIGN(ptype, t->data.Pointer.ptrType);
    COND_ASSIGN(base, t->data.Pointer.baseType);
    CLEANUP_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_SetPointerBase --
 *	Change the base type of a pointer.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	If the new base doesn't have a pointerTo, it will. If this type
 *	is its base's pointerTo, it will no longer be.
 *
 *-----------------------------------------------------------------------
 */
void
Type_SetPointerBase(Type    type,
		    Type    baseType)
{
    TypePtr    	    t;
    Sym	    	    sym;

    MAKE_TYPE(type, t, sym);
    assert(t != NULL);	    	    /* No external form */

    t->data.Pointer.baseType = baseType;
}

/*-
 *-----------------------------------------------------------------------
 * Type_CreateArray --
 *	Create a type describing an array with the given bounds and
 *	element type. In C, lower === 0, indexType === type_Int. If
 *	indexType is an enumerated type, lower and upper bounds should
 *	be the ordinal values of the enum elements that index the array.
 *
 * Results:
 *	The resulting type.
 *
 * Side Effects:
 *	The type is created and its fields filled in.
 *
 *-----------------------------------------------------------------------
 */
Type
Type_CreateArray (int	lower,    	    /* Lower bound for index */
		  int	upper,    	    /* Upper bound for index */
		  Type	indexType,
		  Type	baseType)
{
    TypePtr	  t;
    
    ALLOC_TYPE(t, TYPE_ARRAY);

    t->data.Array.lower = lower;
    t->data.Array.upper = upper;
    t->data.Array.indexType = indexType;
    t->data.Array.baseType = baseType;

    RETURN_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_GetArrayData --
 *	Returns the data for the given array type.
 *
 * Results:
 *	The pieces o' data.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
void
Type_GetArrayData(Type	type,	    	/* Type to check */
		  int	*lowerPtr,  	/* Place for lower bound */
		  int	*upperPtr,  	/* Place for upper bound */
		  Type	*indexTypePtr,	/* Place for type of bound */
		  Type	*baseTypePtr)	/* Place for type of elements */
{
    TypePtr	    t;
    Sym	    	    sym;
    
    MAKE_TYPE(type, t, sym);
    
    again:

    if (t != NULL) {
	CHECK_CLASS(t, TYPE_ARRAY, array, Type_GetArrayData, return);

	COND_ASSIGN(lowerPtr, t->data.Array.lower);
	COND_ASSIGN(upperPtr, t->data.Array.upper);
	COND_ASSIGN(indexTypePtr, t->data.Array.indexType);
	COND_ASSIGN(baseTypePtr, t->data.Array.baseType);
    } else if (Sym_Type(sym) == OSYM_TYPEDEF) {
	while((t == NULL) && (Sym_Type(sym) == OSYM_TYPEDEF)) {
	    MAKE_TYPE(Sym_GetTypeData(sym), t, sym);
	}
	goto again;
    } else {
	/*
	 * No external form other than a typedef, which should have been
	 * resolved to an internal type...
	 */
	assert(0);
    }
    CLEANUP_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_CreateRange --
 *	Create a type describing a subrange of another type. This is
 *	used mostly to describe the different types of integers.
 *
 * Results:
 *	The resulting type.
 *
 * Side Effects:
 *	The type is created and its data filled in.
 *
 *-----------------------------------------------------------------------
 */
Type
Type_CreateRange(int	lower, 	    	/* Lower bound of range */
		 int	upper,	    	/* Upper bound of range */
		 Type	baseType)   	/* Base type of range elements */
{
    TypePtr	  	t;
    
    ALLOC_TYPE(t, TYPE_RANGE);

    t->data.Range.lower = lower;
    t->data.Range.upper = upper;
    t->data.Range.baseType = baseType;

    RETURN_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_GetRangeData --
 *	Find the limits and element type of a range type.
 *
 * Results:
 *	The above-mentioned limits and type.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
void
Type_GetRangeData(Type	type,	    	/* Type to check */
		  int	*lowerPtr,  	/* Place for lower bound */
		  int	*upperPtr,  	/* Place for upper bound */
		  Type	*baseTypePtr)	/* Place for element type */
{
    TypePtr	t;
    Sym	    	sym;
    
    MAKE_TYPE(type, t, sym);
    assert(t != NULL);		/* No external form */

    CHECK_CLASS(t, TYPE_RANGE, range, Type_GetRangeData, return);

    COND_ASSIGN(lowerPtr, t->data.Range.lower);
    COND_ASSIGN(upperPtr, t->data.Range.upper);
    COND_ASSIGN(baseTypePtr, t->data.Range.baseType);
    CLEANUP_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_CreateUnion --
 *	Create a type to describe a union. Only the size is given here.
 *	The fields are filled in with Type_AddField.
 *
 * Results:
 *	The new Type.
 *
 * Side Effects:
 *	The type is created and its list of fields initialized.
 *
 *-----------------------------------------------------------------------
 */
Type
Type_CreateUnion(int	size)	    	/* Size of the whole union in bytes */
{
    TypePtr	  	t;

    ALLOC_TYPE(t, TYPE_UNION);

    t->data.StructUnion.size = size;
    t->data.StructUnion.fields = Vector_Create(sizeof(FieldRec),
					       TYPE_FIELD_ADJUST,
					       TYPE_FIELD_INCR,
					       TYPE_FIELD_INIT);
    t->data.StructUnion.checksum = 0;
    t->data.StructUnion.checked = NullType;

    RETURN_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_CreateStruct --
 *	Create a type to describe a structure. Again, only the size is
 *	given here, the fields being filled in later.
 *
 * Results:
 *	The new Type.
 *
 * Side Effects:
 *	The type is created and initialized.
 *
 *-----------------------------------------------------------------------
 */
Type
Type_CreateStruct(int	size)	    	/* Size of structure (in bytes) */
{
    TypePtr	  	t;

    ALLOC_TYPE(t, TYPE_STRUCT);

    t->data.StructUnion.size = size;
    t->data.StructUnion.fields = Vector_Create(sizeof(FieldRec),
					       TYPE_FIELD_ADJUST,
					       TYPE_FIELD_INCR,
					       TYPE_FIELD_INIT);
    t->data.StructUnion.checksum = 0;
    t->data.StructUnion.checked = NullType;

    RETURN_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_AddField --
 *	Add a field to a structure or union type.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	A Field structure is created and appended to the type's list of
 *	fields.
 *
 *-----------------------------------------------------------------------
 */
void
Type_AddField(Type  type,	    	/* Type to change */
	      char  *fieldName, 	/* Name of new field */
	      int   offset,	    	/* Bit offset of field */
	      int   length,	    	/* Length of the field (bits) */
	      Type  fieldType)  	/* Type of the field */
{
    TypePtr	    t;
    FieldRec	    f;
    Sym	    	    sym;
    
    MAKE_TYPE(type, t, sym);
    assert(t != NULL);	    	    /* No external form when adding */

    if ((t->class == TYPE_STRUCT) || (t->class == TYPE_UNION)) {
	f.name = String_EnterNoLen(fieldName);
	f.offset = offset;
	f.length = length;
	f.type  = fieldType;
	Vector_Add(t->data.StructUnion.fields, -1, &f);

	while (*fieldName != '\0') {
	    t->data.StructUnion.checksum += *(unsigned char *)fieldName;
	    fieldName++;
	}
    } else {
	Punt("Non-struct/union type passed to Type_AddField");
    }
}

/*-
 *-----------------------------------------------------------------------
 * Type_GetFieldData  --
 *	Return the data for the given field of the given structure/union.
 *
 * Results:
 *	TRUE if field was found, FALSE if not.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Type_GetFieldData(Type	type,	    	/* Struct/Union type */
		  char	*fieldName, 	/* Name of desired field */
		  int	*offsetPtr, 	/* Place for bit offset */
		  int	*lengthPtr, 	/* Place for bit length */
		  Type	*fieldTypePtr)	/* Place for field type. */
{
    TypePtr	  	t;
    register FieldPtr  	f;
    register int  	i;
    Sym	    	    	sym;

    MAKE_TYPE(type, t, sym);
    
    if (t != (TypePtr)NULL) {
	if ((t->class == TYPE_STRUCT) || (t->class == TYPE_UNION)) {
	    f = (FieldPtr)Vector_Data(t->data.StructUnion.fields);
	    for (i = Vector_Length(t->data.StructUnion.fields);
		 i > 0;
		 i--)
	    {
		if (strcmp(f->name, fieldName) == 0) {
		    break;
		} else {
		    f++;
		}
	    }
	    if (i > 0) {
		COND_ASSIGN(offsetPtr, f->offset);
		COND_ASSIGN(lengthPtr, f->length);
		COND_ASSIGN(fieldTypePtr, f->type);
		CLEANUP_TYPE(t);
		return (TRUE);
	    }
	} else {
	    Punt("Non-struct/union type passed to Type_GetFieldData");
	}
	CLEANUP_TYPE(t);
	return (FALSE);
    } else {
	Sym field = Sym_LookupInScope(fieldName, SYM_FIELD, sym);

	if (!Sym_IsNull(field)) {
	    Sym_GetFieldData(field, offsetPtr, lengthPtr, fieldTypePtr,
			     (Type *)NULL);
	    return (TRUE);
	} else {
	    return(FALSE);
	}
    }
    return (FALSE);  /* not executed, but makes the compiler happy */
}

/***********************************************************************
 *				TFFDCallback
 ***********************************************************************
 * SYNOPSIS:	    Callback function for Type_FindFieldData
 * CALLED BY:	    Type_FindFieldData via Sym_ForEach	
 * RETURN:	    1 if found a reasonable field.
 * SIDE EFFECTS:    the passed symbol is replaced with the found one
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 1/90		Initial Revision
 *
 ***********************************************************************/
static int
TFFDCallback(Sym    sym,    	/* Field to check */
	     Opaque data)   	/* Pointer to Sym whose offset is the
				 * offset being sought */
{
    Sym	    	*sp = (Sym *)data;
    int	    	offset;
    int	    	length;

    Sym_GetFieldData(sym, &offset, &length, (Type *)NULL, (Type *)NULL);
    
    if (offset <= SymOffset(*sp) && offset + length > SymOffset(*sp)) {
	*sp = sym;
	return(1);		/* Stop searching */
    }
    return(0);
}
	

/*-
 *-----------------------------------------------------------------------
 * Type_FindFieldData  --
 *	Locate a field of a structure that begins at the desired bit
 *	offset.
 *
 * Results:
 *	TRUE if field was found, FALSE if not.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Type_FindFieldData(Type	type,	    	/* Struct/Union type */
		   int	offset,	    	/* Bit offset field must be */
		   char	**fieldNamePtr,	/* Place for Name of desired field */
		   int	*lengthPtr, 	/* Place for bit length */
		   Type	*fieldTypePtr,	/* Place for field type. */
		   int	*diffPtr)    	/* Difference between offset and
					 * field's offset */
{
    TypePtr	  	t;
    register FieldPtr  	f;
    register int  	i;
    Buffer  	    	retval;
    Sym	    	    	sym;

    MAKE_TYPE(type, t, sym);
    
    retval = Buf_Init(0);
	
    if (t != NULL) {
	assert(t->class == TYPE_STRUCT || t->class == TYPE_UNION);
	return(FALSE);
    } else {
	switch(Sym_Type(sym)) {
	    case OSYM_STRUCT:
	    case OSYM_UNION:
	    case OSYM_RECORD:
		break;
	    default:
		assert(0);
		return (FALSE);
	}
    }
	
    while (1) {
	char	*fname;
	int    	flen;
	int    	foff;
	Type    ftype;

	if (t != NULL) {
	    f = (FieldPtr)Vector_Data(t->data.StructUnion.fields);
	    for (i = Vector_Length(t->data.StructUnion.fields);
		 i > 0;
		 i--)
	    {
		if (f->offset <= offset && f->offset + f->length > offset) {
		    break;
		} else {
		    f++;
		}
	    }
	    if (i == 0) {
		break;
	    }
	    fname = f->name;
	    flen = f->length;
	    foff = f->offset;
	    ftype = f->type;
	} else {
	    Sym	    field;

	    SymFile(field) = 0;
	    SymOffset(field) = offset;

	    Sym_ForEach(sym, SYM_FIELD, TFFDCallback, (Opaque)&field);
	    if (SymFile(field) == 0) {
		break;
	    }
	    fname = Sym_Name(field);
	    Sym_GetFieldData(field, &foff, &flen, &ftype, (Type *)NULL);
	}
	/*
	 * Add field's name to the return value, placing a '.' before it
	 * if not the first one.
	 */
	if (Buf_Size(retval) > 0) {
	    Buf_AddByte(retval, (Byte)'.');
	}
	Buf_AddBytes(retval, strlen(fname), (Byte *)fname);
		
	/*
	 * Store the length and type in case we're at a non-structure
	 * field
	 */
	COND_ASSIGN(lengthPtr, flen);
	COND_ASSIGN(fieldTypePtr, ftype);
		
	/*
	 * Change to a real type and convert offset to be relative to the
	 * field, and loop.
	 */
	MAKE_TYPE(ftype, t, sym);
	offset -= foff;
		
	COND_ASSIGN(diffPtr, offset);

	if (t != NULL) {
	    if (t->class == TYPE_STRUCT || t->class == TYPE_UNION) {
		continue;
	    }
	} else {
	    switch(Sym_Type(sym)) {
		case OSYM_STRUCT:
		case OSYM_UNION:
		case OSYM_RECORD:
		    continue;
	    }
	}
	break;
    }
    /*
     * If anything in the retval buffer, we found a field that covered the
     * offset and want to return that name and TRUE.
     */
    if (Buf_Size(retval) > 0) {
	if (fieldNamePtr) {
	    /*
	     * Caller interested in the name, so null-terminate and
	     * return the thing, then destroy the buffer while leaving the
	     * name alone.
	     */
	    Buf_AddByte(retval, 0);
	    *fieldNamePtr = (char *)Buf_GetAll(retval, NULL);
	    Buf_Destroy(retval, FALSE);
	} else {
	    /*
	     * Not interested -- nuke the whole thing.
	     */
	    Buf_Destroy(retval, TRUE);
	}
	/*
	 * Search successful
	 */
	return (TRUE);
    } else {
	/*
	 * Found nothing -- destroy buffer and return failure.
	 */
	Buf_Destroy(retval, TRUE);
	COND_ASSIGN(fieldNamePtr, NULL);
	return (FALSE);
    }
}
typedef struct {
    Boolean (*func)();
    Opaque  clientData;
} TFEFData;

/***********************************************************************
 *				TFEFCallback
 ***********************************************************************
 * SYNOPSIS:	    Callback function for Type_ForEachField to pass
 *	    	    the right data to the actual callback function
 * CALLED BY:	    Type_ForEachField via Sym_ForEach
 * RETURN:	    Whatever the real callback routine returns
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 1/90		Initial Revision
 *
 ***********************************************************************/
static Boolean
TFEFCallback(Sym    sym,
	     Opaque data)
{
    TFEFData	*dp = (TFEFData *)data;
    char    	*name;
    int	    	offset;
    int	    	length;
    Type    	type;
    Type    	struc;

    Sym_GetFieldData(sym, &offset, &length, &type, &struc);
    name = Sym_Name(sym);

    return ((*dp->func)(struc, name, offset, length, type, dp->clientData));
}
    

/*-
 *-----------------------------------------------------------------------
 * Type_ForEachField --
 *	Iterate through the list of fields for this struct/union type,
 *	calling the indicated function with the passed data:
 *	    (* func) (type, fieldName, offset, length,
 *	    	  	fieldType,clientData)
 *	Func should return 0 to continue and non-zero to stop.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The passed function is called.
 *
 *-----------------------------------------------------------------------
 */
void
Type_ForEachField(Type	    type,    	/* Type through which to iterate */
		  Boolean   (*func)(),  /* Function to call */
		  Opaque    clientData) /* Data to pass it */
{
    TypePtr	  	t;
    register FieldPtr	f;
    register int	i;
    Sym	    	    	sym;

    MAKE_TYPE(type, t, sym);
    
    if (t != NULL) {
	if ((t->class == TYPE_STRUCT) || (t->class == TYPE_UNION)) {
	    f = (FieldPtr)Vector_Data(t->data.StructUnion.fields);
	    for (i = Vector_Length(t->data.StructUnion.fields);
		 i > 0;
		 i--)
	    {
		if ((* func) (type, f->name, f->offset, f->length,
			      f->type, clientData))
		{
		    break;
		} else {
		    f++;
		}
	    }
	} else {
	    Punt("Non-struct/union type passed to Type_ForEachField");
	}
    } else {
	TFEFData    tfefd;

	tfefd.func = func;
	tfefd.clientData = clientData;

	Sym_ForEach(sym, SYM_FIELD, TFEFCallback, (Opaque)&tfefd);
    }
    CLEANUP_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * TypeStructEquiv --
 *	See if the two structures are structurally equivalent. Callback
 *	function for Lst_Find from Type_EndStructUnion.
 *
 * Results:
 *	Returns 0 if they are. 1 if they are not.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static int
TypeStructEquiv(Type	type1,
		Type	type2)
{
    TypePtr 	  	t1;
    TypePtr 	  	t2;
    Sym	    	    	sym;
    int	    	    	retval;

    MAKE_TYPE(type1, t1, sym);
    MAKE_TYPE(type2, t2, sym);

    if (t1->data.StructUnion.checksum == t2->data.StructUnion.checksum) {
	retval = (Type_Equal(type1, type2) ? 0 : 1);
    } else {
	retval = (1);
    }
    CLEANUP_TYPE(t1);
    CLEANUP_TYPE(t2);

    return(retval);
}

/*-
 *-----------------------------------------------------------------------
 * Type_EndStructUnion --
 *	Terminate the definition of a structure or union. Checks to see
 *	if it is already defined (using structural equivalence) and if it
 *	is, frees up the new definition and returns the old. If the
 *	structure or union is new, returns the new definition.
 *
 * Results:
 *	The Type to use for the given definition (either new or old).
 *
 * Side Effects:
 *	The new definition may be freed.
 *
 *-----------------------------------------------------------------------
 */
Type
Type_EndStructUnion(Type    type)	    	/* Type to check */
{
    Hash_Entry	  	*entry;
    Lst			l;
    Boolean		new;
    TypePtr		t;
    LstNode		ln;
    Sym	    	    	sym;

    MAKE_TYPE(type, t, sym);
    if (t->class != TYPE_STRUCT && t->class != TYPE_UNION) {
	Punt("Non-struct/union type passed to Type_EndStructUnion");
	return(type);
    }
    entry = Hash_CreateEntry(&structs, (Address)t->data.StructUnion.size,
			     &new);
    if (new) {
	l = Lst_Init(FALSE);
	Hash_SetValue(entry, l);
    } else {
	l = (Lst)Hash_GetValue(entry);
    }
    ln = Lst_Find(l, (LstClientData)t, TypeStructEquiv);
    if (ln != NILLNODE) {
	/*
	 * Found an equivalent defintion -- free the new and set t to be
	 * the old one.
	 */
	Vector_Destroy(t->data.StructUnion.fields);
	free((char *)t);
	t = (TypePtr)Lst_Datum(ln);
    } else {
	/*
	 * No equivalent definition -- stuff this one at the end of the list
	 * for its size.
	 */
	(void)Lst_AtEnd(l, (LstClientData)t);
    }
    RETURN_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_CreateEnum --
 *	Create an enumerated type handle. Members are added to the type
 *	by Type_AddEnumMember.
 *
 * Results:
 *	The newly-created Type.
 *
 * Side Effects:
 *	The type is created and initialized.
 *
 *-----------------------------------------------------------------------
 */
Type
Type_CreateEnum(int size)
{
    TypePtr	  	t;

    ALLOC_TYPE(t, TYPE_ENUM);

    t->data.Enum.members = Lst_Init(FALSE);
    t->data.Enum.min = t->data.Enum.max = 0;
    t->data.Enum.size = size;

    RETURN_TYPE(t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_AddEnumMember --
 *	Add a name->number mapping (enum member) to an existing ENUM type.
 *	The enumName is assumed to be non-volatile.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	An Enum structure is added to the list of members for the type and
 *	the min and max fields will be altered if the new member is outside
 *	them.
 *
 *-----------------------------------------------------------------------
 */
void
Type_AddEnumMember(Type	type,	    	/* The type to modify */
		   char	*enumName,  	/* Name of new member */
		   int	enumValue)  	/* Value for new member */
{
    TypePtr	  	t;
    Enum    	  	e;
    Sym			sym;

    MAKE_TYPE(type, t, sym);
    assert(t != NULL);	/* Only internal may be added to */
    
    CHECK_CLASS(t, TYPE_ENUM, enum, Type_AddEnumMember, return);

    e = (Enum)malloc_tagged(sizeof(EnumRec), TAG_TYPEETC);
    if (e == (Enum)NULL) {
	Punt("Couldn't allocate Enum record in Type_AddEnumMember");
    } else {
	if (Lst_IsEmpty(t->data.Enum.members)) {
	    t->data.Enum.min = t->data.Enum.max = enumValue;
	} else {
	    if (enumValue < t->data.Enum.min) {
		t->data.Enum.min = enumValue;
	    }
	    if (enumValue > t->data.Enum.max) {
		t->data.Enum.max = enumValue;
	    }
	}
	e->name = enumName;
	e->value = enumValue;
	(void)Lst_AtEnd(t->data.Enum.members, (LstClientData)e);
    }
}

/*-
 *-----------------------------------------------------------------------
 * TypeEnumHasName --
 *	Callback function for Type_GetEnumValue to see if an Enum is the
 *	one desired.
 *
 * Results:
 *	0 if e is the sought-for Enum, non-zero if not.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static int
TypeEnumHasName(Enum	e,  	    	/* Enum to check */
		char	*name)	    	/* Name of desired Enum */
{
    return (strcmp(e->name, name));
}
/*-
 *-----------------------------------------------------------------------
 * TypeEnumHasValue --
 *	Callback function for Type_GetEnumValue to see if an Enum has the
 *	sought-for value.
 *
 * Results:
 *	0 if e is the desired Enum, non-zero if not.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static int
TypeEnumHasValue(Enum	e,  	    	/* Enum to check */
		 int	value)	    	/* Value of desired Enum */
{
    return (e->value - value);
}

/*-
 *-----------------------------------------------------------------------
 * Type_GetEnumValue --
 *	Return the value of a given symbolic constant in the given type.
 *
 * Results:
 *	The value, if the constant exists, or -1 if it doesn't.
 *	XXX: -1 may be a valid value...
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Type_GetEnumValue(Type	type,	    	/* Type to check */
		  char	*name)	    	/* Name of desired member */
{
    TypePtr	  	t;
    LstNode 	  	ln;
    Enum    	  	e;
    Sym	    	    	sym;

    MAKE_TYPE(type, t, sym);

    if (t != NULL) {
	CHECK_CLASS(t, TYPE_ENUM, enum, Type_GetEnumValue, return -1);

	ln = Lst_Find(t->data.Enum.members, (LstClientData)name,
		      TypeEnumHasName);
	CLEANUP_TYPE(t);
	if (ln != NILLNODE) {
	    e = (Enum)Lst_Datum(ln);
	    return (e->value);
	} else {
	    return (-1);
	}
    } else {
	Sym member = Sym_LookupInScope(name, SYM_ENUM, sym);
	int value;

	if (!Sym_IsNull(member)) {
	    Sym_GetEnumData(member, &value, (Type *)NULL);
	} else {
	    value = -1;
	}
	return(value);
    }
}

/***********************************************************************
 *				TGENCallback
 ***********************************************************************
 * SYNOPSIS:	    Callback function for Type_GetEnumName
 * CALLED BY:	    Type_GetEnumName via Sym_ForEach	
 * RETURN:	    1 if found a reasonable enum.
 * SIDE EFFECTS:    the passed symbol is replaced with the found one
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 1/90		Initial Revision
 *
 ***********************************************************************/
static int
TGENCallback(Sym    sym,    	/* Enum to check */
	     Opaque data)   	/* Pointer to Sym whose offset is the
				 * value being sought */
{
    Sym	    	*sp = (Sym *)data;
    int	    	value;

    Sym_GetEnumData(sym, &value, (Type *)NULL);

    if (value == SymOffset(*sp)) {
	*sp = sym;
	return(1);		/* Stop searching */
    } else {
	return(0);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Type_GetEnumName --
 *	Find the name for a given value in the given type.
 *
 * Results:
 *	The name of the constant, WHICH MAY NOT BE MODIFIED.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
char *
Type_GetEnumName(Type	type,	    	/* Type to examine */
		 int	value)	    	/* Value desired */
{
    TypePtr	  	t;
    LstNode 	  	ln;
    Enum    	  	e;
    Sym	    	    	sym;

    MAKE_TYPE(type, t, sym);
    
    if (t != NULL) {
	CHECK_CLASS(t, TYPE_ENUM, enum, Type_GetEnumValue, return (char *)NULL);
	
	ln = Lst_Find(t->data.Enum.members, (LstClientData)value,
		      TypeEnumHasValue);
	CLEANUP_TYPE(t);
	if (ln != NILLNODE) {
	    e = (Enum)Lst_Datum(ln);
	    return (e->name);
	} else {
	    return ((char *)NULL);
	}
    } else {
	Sym 	member;

	SymFile(member) = 0;
	SymOffset(member) = value;
	Sym_ForEach(sym, SYM_ENUM, TGENCallback, (Opaque)&member);

	if (SymFile(member) != 0) {
	    return Sym_Name(member);
	} else {
	    return (char *)NULL;
	}
    }
}

/***********************************************************************
 *				TGEDCallback
 ***********************************************************************
 * SYNOPSIS:	    Callback for Type_GetEnumData for finding the bounds
 *	    	    of an enumerated type
 * CALLED BY:	    Type_GetEnumData via Sym_ForEach
 * RETURN:	    0 (continue)
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 1/90		Initial Revision
 *
 ***********************************************************************/
typedef struct {
    word    min;
    word    max;
} TGEDData;

static int
TGEDCallback(Sym    sym,
	     Opaque data)
{
    TGEDData	*dp = (TGEDData *)data;
    int	    	value;

    Sym_GetEnumData(sym, &value, (Type *)NULL);
    if (value > dp->max) {
	dp->max = value;
    }
    if (value < dp->min) {
	dp->min = value;
    }

    return(0);
}


/*-
 *-----------------------------------------------------------------------
 * Type_GetEnumData --
 *	Return the salient facts about an enumerated type -- the lower and
 *	upper bounds of its values.
 *
 * Results:
 *	The lower and upper bounds are stored in the given variables.
 *
 * Side Effects:
 *	The buffers passed are overwritten.
 *
 *-----------------------------------------------------------------------
 */
void
Type_GetEnumData(Type	type,	    	/* Type to check */
		 int	*minPtr,    	/* Place for minimum value */
		 int	*maxPtr)    	/* Place for maximum value */
{
    TypePtr	  	t;
    Sym	    	    	sym;
    
    MAKE_TYPE(type, t, sym);
    
    if (t != NULL) {
	CHECK_CLASS(t, TYPE_ENUM, enum, Type_GetEnumData, return);

	COND_ASSIGN(minPtr, t->data.Enum.min);
	COND_ASSIGN(maxPtr, t->data.Enum.max);
	CLEANUP_TYPE(t);
    } else {
	TGEDData    data;

	data.min = 65535; data.max = 0;
	Sym_ForEach(sym, SYM_ENUM, TGEDCallback, (Opaque)&data);
	COND_ASSIGN(minPtr, data.min);
	COND_ASSIGN(maxPtr, data.max);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Type_ForEachEnum --
 *	Iterate through all the members in an enumerated type, calling
 *	the given function:
 *	    (* func) (type, enumName, enumValue, clientData)
 *	Func should return 0 to continue and non-zero to stop.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The function is called.
 *
 *-----------------------------------------------------------------------
 */
void
Type_ForEachEnum(Type	type,	    /* Type through which to iterate */
		 type_foreachenum_callback func,  /* Function to call */
		 Opaque	clientData) /* Data to pass it */
{
    TypePtr	  	t;
    LstNode 	  	ln;
    Enum    	  	e;
    Sym	    	    	sym;

    MAKE_TYPE(type, t, sym);
    
    if (t != NULL) {
	CHECK_CLASS(t, TYPE_ENUM, enum, Type_ForEachEnum, return);

	if (Lst_Open(t->data.Enum.members) == SUCCESS) {
	    while ((ln = Lst_Next(t->data.Enum.members)) != NILLNODE) {
		e = (Enum)Lst_Datum(ln);
		if ((* func) (type, e->name, e->value, clientData)){
		    break;
		}
	    }
	    Lst_Close(t->data.Enum.members);
	}
	CLEANUP_TYPE(t);
    } else {
	Sym_ForEach(sym, SYM_ENUM, (sym_foreach_callback)func, clientData);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Type_CreateFunction --
 *	Create a type describing a function that returns the given type.
 *	Note this is not a pointer to a function returning the given type.
 *
 * Results:
 *	The new type.
 *
 * Side Effects:
 *	The type is created and intialized. The retType will have its
 *	function slot modified if the type is created.
 *
 *-----------------------------------------------------------------------
 */
Type
Type_CreateFunction(Type    retType)    	/* Return type for function */
{
    TypePtr	    t;
    TypePtr	    rt;
    Sym	    	    sym;

    MAKE_TYPE(retType, rt, sym);
    
#if CACHE_FUNCTION_RETURNING_TYPE
    if (rt->function) {
	return ((Type)rt->function);
    } else {
#endif
	ALLOC_TYPE(t, TYPE_FUNCTION);

	t->data.Function.retType = retType;
#if CACHE_FUNCTION_RETURNING_TYPE
	rt->function = (Type)t;
#endif

	RETURN_TYPE (t);
#if CACHE_FUNCTION_RETURNING_TYPE
    }
#endif
}

/*-
 *-----------------------------------------------------------------------
 * Type_GetFunctionReturn --
 *	Find the type returned by the given function type.
 *
 * Results:
 *	The indicated type.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Type
Type_GetFunctionReturn(Type type)  	    /* The type to investigate */
{
    TypePtr	  	t;
    Sym	    	    	sym;

    MAKE_TYPE(type, t, sym);
    assert(t != NULL);		/* No external form (yet) */
    
    CHECK_CLASS(t, TYPE_FUNCTION, function, Type_GetFunctionReturn,
		return NullType);

    return (t->data.Function.retType);
}

/*-
 *-----------------------------------------------------------------------
 * Type_CreateFloat --
 *	Create a floating point type of the given size.
 *
 * Results:
 *	The new Type.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Type
Type_CreateFloat(int	size)
{
    TypePtr	  	t;

    ALLOC_TYPE(t, TYPE_FLOAT);

    t->data.Float.size = size;

    RETURN_TYPE (t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_CreateExternal --
 *	Create a reference to an external struct/union/enum.
 *
 * Results:
 *	The new type.
 *
 * Side Effects:
 *	Guess what?
 *
 *-----------------------------------------------------------------------
 */
Type
Type_CreateExternal(word	class,
		    char	*name)
{
    TypePtr	  	t;

    ALLOC_TYPE(t, TYPE_EXTERNAL);

    t->data.External.class = class;
    t->data.External.name = name;

    RETURN_TYPE (t);
}

/*-
 *-----------------------------------------------------------------------
 * Type_GetExternalData --
 *	Return the class and name of an external struct/union/enum.
 *
 * Results:
 *	The class and name.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
void
Type_GetExternalData(Type    	type,
		     word	*classPtr,
		     char	**namePtr)
{
    TypePtr	    t;
    Sym	    	    sym;
    
    MAKE_TYPE(type, t, sym);
    assert (t != NULL);		/* No external form */

    CHECK_CLASS(t, TYPE_EXTERNAL, external, Type_GetExternalData,
		return );

    COND_ASSIGN(classPtr, t->data.External.class);
    COND_ASSIGN(namePtr, t->data.External.name);
}


/***********************************************************************
 *				Type_CreateBitField
 ***********************************************************************
 * SYNOPSIS:	    Create a descriptor for a bitfield.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Type for the thing.
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *	    There are a limited number of bitfield/width/signed
 *	    combinations (2**11), so we cache the little beggars.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 4/92		Initial Revision
 *
 ***********************************************************************/
Type
Type_CreateBitField(unsigned offset, unsigned width, Type type)
{
    static  TypePtr bits[32];
    TypePtr 	t;
    TypeToken 	tt;
    
    assert(offset < 32);

    for (t = bits[offset]; t != NULL; t = t->data.BitField.next) {
	if ((t->data.BitField.width == width) &&
	    Type_Equal(t->data.BitField.type,type))
	{
	    RETURN_TYPE(t);
	}
    }

    ALLOC_TYPE(t, TYPE_BITFIELD);
    t->data.BitField.offset = offset;
    t->data.BitField.width = width;
    t->data.BitField.type = type;
    t->data.BitField.next = bits[offset];
    bits[offset] = t;

    tt.file = (VMHandle)0;
    TypeInt(tt) = t;
    GC_RegisterType(TypeCast(tt));

    RETURN_TYPE(t);
}


/***********************************************************************
 *				Type_GetBitFieldData
 ***********************************************************************
 * SYNOPSIS:	    Fetch info about a bitfield type.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    the dimensions of the bitfield, as requested
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 4/92		Initial Revision
 *
 ***********************************************************************/
void
Type_GetBitFieldData(Type   type,
		     unsigned *offsetPtr,
		     unsigned *widthPtr,
		     Type *typePtr)
{
    TypePtr t;
    Sym	    sym;

    MAKE_TYPE(type, t, sym);
    assert(t != NULL);	    /* No external form */

    CHECK_CLASS(t, TYPE_BITFIELD, bitfield, Type_GetBitFieldData, return);

    COND_ASSIGN(offsetPtr, t->data.BitField.offset);
    COND_ASSIGN(widthPtr, t->data.BitField.width);
    COND_ASSIGN(typePtr, t->data.BitField.type);
}

/*-
 *-----------------------------------------------------------------------
 * Type_IsSigned --
 *	See if the given type is signed. Applies really only to integers.
 *	Anything else is considered unsigned.
 *
 * Results:
 *	TRUE if the type is signed and FALSE otherwise.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Type_IsSigned(Type    	type)
{
    TypePtr 	  	t;
    Sym	    	    	sym;

    MAKE_TYPE(type, t, sym);	/* Ints converted to internal... */

    if (t != NULL && (t->class == TYPE_INT || t->class == TYPE_BITFIELD)) {
	return((t->class == TYPE_INT) ? t->data.Int.isSigned :
	       Type_IsSigned(t->data.BitField.type));
    } else {
	return(FALSE);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Type_Sizeof --
 *	Find the size of a type.
 *
 * Results:
 *	The size (in bytes) of the given type in the given patient's
 *	representation.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Type_Sizeof(Type    	type)	    /* The type to check */
{
    TypePtr	  	t;
    Sym	    	    	sym;

    MAKE_TYPE(type, t, sym);
    
    if (t != NULL) {
	int   	    size;

	switch (t->class) {
	    case TYPE_ENUM:
		size = t->data.Enum.size;
		break;
	    case TYPE_INT:
		size = t->data.Int.size;
		break;
	    case TYPE_CHAR:
		size = t->data.Char.size;
		break;
	    case TYPE_POINTER:
		switch (t->data.Pointer.ptrType) {
		    case TYPE_PTR_NEAR:
		    case TYPE_PTR_HANDLE:
		    case TYPE_PTR_LMEM:
		    case TYPE_PTR_SEG:
			size = 2;
			break;
		    case TYPE_PTR_VIRTUAL:
		    case TYPE_PTR_VM:
		    case TYPE_PTR_FAR:
		    case TYPE_PTR_OBJECT:
			size = 4;
			break;
		    default:
			size = 0;
			break;
		}
		break;
	    case TYPE_FLOAT:
		size = t->data.Float.size;
		break;
	    case TYPE_ARRAY:
		size = (((t->data.Array.upper -
			  t->data.Array.lower) + 1) *
			Type_Sizeof(t->data.Array.baseType));
		break;
	    case TYPE_UNION:
	    case TYPE_STRUCT:
		size =  t->data.StructUnion.size;
		break;
#if USE_TYPE_EXTERNAL
	    case TYPE_EXTERNAL: {
		Sym	  sym;
		
		sym = Sym_Lookup(t->data.External.name, SYM_TAG,
				 curPatient->global);
		if (sym == NullSym) {
		    Warning("Couldn't resolve reference to %s %s",
			    t->data.External.class == TYPE_STRUCT ? "struct" :
			    t->data.External.class == TYPE_UNION ? "union" : "enum",
			    t->data.External.name);
		    return(0);
		} else {
		    return (Type_Sizeof(patient, sym));
		}
	    }
#endif
	    case TYPE_FUNCTION:
	    case TYPE_VOID:
		/*
		 * The size of both a function and void is 1. Why? To facilitate
		 * expressions like "main+1" and @fp+3 where otherwise pointer
		 * arithmetic wouldn't work properly.
		 */
		size = 1;
		break;
	    case TYPE_RANGE:
	    {
		TypePtr	bt;
		
		MAKE_TYPE(t->data.Range.baseType, bt, sym);
		
		if (bt == TypeInt(type_Int)) {
		    /*
		     * For subranges of int, we figure out how many bits
		     * the subrange would take and convert that to bytes.
		     */
		    register unsigned int 	i;
		    unsigned int	span;
		    
		    span = t->data.Range.upper - t->data.Range.upper;
		    for (i = 0x80000000; i != 0; i >>= 1) {
			if (span & i) {
			    break;
			}
		    }
		    size = (ffs(i) + 7) / 8;
		} else {
		    /*
		     * For anything else, we assume it takes the same space
		     * as its base (this is really compiler-dependent)
		     */
		    size = Type_Sizeof(t->data.Range.baseType);
		}
		CLEANUP_TYPE(bt);
	    }
	    case TYPE_BITFIELD:
		size = (t->data.BitField.offset + t->data.BitField.width + 7)/8;
		if (size == 3) {
		    /*
		     * Round up to the size of a long...
		     */
		    size = 4;
		}
		break;
	    default:
		Punt("Unknown type in Type_Sizeof");
		return(0);
	}
	CLEANUP_TYPE(t);
	return(size);
    } else {
	ObjSym	    *s = SymLock(sym);
	int 	    result;


	if (s->type != OSYM_TYPEDEF) {
	    result = s->u.sType.size;
	} else {
	    /*
	     * Size not stored for typedefs -- figure the size using the actual
	     * type description for the thing.
	     */
	    result = Type_Sizeof(Sym_GetTypeData(sym));
	}

	SymUnlock(sym);
	return(result);
    }
}


/*-
 *-----------------------------------------------------------------------
 * Type_Class --
 *	Return the class of a given type.
 *
 * Results:
 *	A word indicating the class of the type.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
word
Type_Class(Type    	type)
{
    TypePtr	  	t;
    Sym	    	    	sym;

    if (Type_IsNull(type)) {
	return(TYPE_NULL);
    }
    
    MAKE_TYPE(type, t, sym);
    if (t != NULL) {
	word	class = t->class;

	CLEANUP_TYPE(t);
	return(class);
    } else {
	switch(Sym_Type(sym)) {
	    case OSYM_STRUCT:
	    case OSYM_RECORD:
		return(TYPE_STRUCT);
	    case OSYM_UNION:
		return(TYPE_UNION);
	    case OSYM_ETYPE:
		return(TYPE_ENUM);
	    case OSYM_TYPEDEF:
		return Type_Class(Sym_GetTypeData(sym));
	    default:
		assert(0);
	}
    }
    return 0;  /* never executed, but makes the compiler happy */
}
typedef struct {
    Buffer  	buf;	    /* Buffer in which we're printing things */
    int	    	offset;	    /* Leading offset for each element, if
			     * needed */
    int	    	first;	    /* Non-zero if callback is for first element */
} TNData;


/***********************************************************************
 *				TNAddOffset
 ***********************************************************************
 * SYNOPSIS:	    Stick in the proper number of spaces for the current
 *	    	    indentation level.
 * CALLED BY:	    INTERNAL (see below)
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 1/90		Initial Revision
 *
 ***********************************************************************/
static void
TNAddOffset(TNData  *tndp)
{
    int	    i;

    /*
     * This is a hack.
     */
    for (i = tndp->offset; i > 0; i--) {
	Buf_AddByte(tndp->buf, (Byte)' ');
    }
}

/***********************************************************************
 *				TFECallback
 ***********************************************************************
 * SYNOPSIS:	    Callback function for TypeFormatEnum to stick
 *	    	    the enumerated type's member names into a buffer.
 * CALLED BY:	    TypeFormatEnum via Type_ForEachEnum
 * RETURN:	    0 (continue)
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 1/90		Initial Revision
 *
 ***********************************************************************/
static int
TFECallback(Sym	    sym,
	    Opaque  data)
{
    TNData  *tndp = (TNData *)data;
    char    *name;

    if (tndp->first) {
	tndp->first = 0;
    } else {
	Buf_AddBytes(tndp->buf, 2, (Byte *)", ");
    }
    name = Sym_Name(sym);
    Buf_AddBytes(tndp->buf, strlen(name), (Byte *)name);

    return(0);
}

/*-
 *-----------------------------------------------------------------------
 * TypeFormatEnum --
 *	Pretty-print an enumerated type.
 *
 * Results:
 *	A string of the form "enum { <members> } name".
 *
 * Side Effects:
 *	The string is dynamically-allocated and must be freed by the
 *	caller.
 *
 *-----------------------------------------------------------------------
 */
static char *
TypeFormatEnum(Type	type,
	       char	*tag,
	       char    	*name,
	       int	offset)
{
    char		*newName;
    TNData	    	tnd;

    tnd.buf = Buf_Init(0);
    tnd.offset = offset;
    tnd.first = 1;

    /*
     * Stick in the initial stuff: the leading offset, the tag (if
     * any) and the curly-brace/newline pair.
     */
    TNAddOffset(&tnd);
    Buf_AddBytes(tnd.buf, strlen(tag), (Byte *)tag);
    if (*tag) {
	Buf_AddBytes(tnd.buf, 3, (Byte *)" {\n");
    } else {
	Buf_AddBytes(tnd.buf, 2, (Byte *)"{\n");
    }
    /*
     * Indent another level and stick in the leading offset, then
     * stuff all the members into the buffer with TFECallback.
     */
    tnd.offset += 4;
    TNAddOffset(&tnd);
    Type_ForEachEnum(type, (type_foreachenum_callback)TFECallback, (Opaque)&tnd);

    /*
     * Insert the trailing stuff: newline (finish off the member list),
     * offset, close-curly and the name.
     */
    tnd.offset -= 4;
    Buf_AddByte(tnd.buf, (Byte)'\n');
    TNAddOffset(&tnd);
    if (*name) {
	Buf_AddBytes(tnd.buf, 2, (Byte *)"} ");
	Buf_AddBytes(tnd.buf, strlen(name), (Byte *)name);
    } else {
	Buf_AddByte(tnd.buf, (Byte)'}');
    }

    newName = (char *)Buf_GetAll(tnd.buf, NULL);
    Buf_Destroy(tnd.buf, FALSE);
    return(newName);
}

/***********************************************************************
 *				TFSUCallback
 ***********************************************************************
 * SYNOPSIS:	    Callback routine for expanding structure or union
 *	    	    fields.
 * CALLED BY:	    TypeFormatStructUnion via Type_ForEachField
 * RETURN:	    0 (continue)
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 1/90		Initial Revision
 *
 ***********************************************************************/
static int
TFSUCallback(Type   type,   	    /* Enclosing type */
	     char   *name,  	    /* Field name */
	     int    offset, 	    /* Bit offset of field */
	     int    length, 	    /* Bit length of field */
	     Type   ftype,   	    /* Type of field */
	     Opaque clientData)	    /* Our data */
{
    TNData  	*tndp = (TNData *)clientData;
    char    	*field;

    /*
     * Ignore nameless fields...
     */
    if (*name != '\0') {
	field = Type_NameOffset(ftype, name, tndp->offset, TRUE);
	
	Buf_AddBytes(tndp->buf, strlen(field), (Byte *)field);
	if ((length != Type_Sizeof(ftype)*8) &&
	    (Type_Class(ftype) != TYPE_BITFIELD))
	{
	    char    width[16];
	    sprintf(width, ":%d;\n", length);
	    Buf_AddBytes(tndp->buf, strlen(width), (Byte *)width);
	} else {
	    Buf_AddBytes(tndp->buf, 2, (Byte *)";\n");
	}
	
	free(field);
    }

    return(0);
}
/*-
 *-----------------------------------------------------------------------
 * TypeFormatStructUnion --
 *	Pretty-print a structure or union.
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
static char *
TypeFormatStructUnion(Type	type,
		      char	*which,
		      char	*name,
		      int	offset)
{
    TNData  	    	tnd;
    char		*newName;
    
    tnd.buf = Buf_Init(0);
    tnd.first = 1;
    tnd.offset = offset;

    TNAddOffset(&tnd);
    Buf_AddBytes(tnd.buf, strlen(which), (Byte *)which);
    Buf_AddBytes(tnd.buf, 3, (Byte *)" {\n");

    tnd.offset += 4;
    Type_ForEachField(type, TFSUCallback, (Opaque)&tnd);
    
    tnd.offset -= 4;
    TNAddOffset(&tnd);
    if (*name) {
	Buf_AddBytes(tnd.buf, 2, (Byte *)"} ");
	Buf_AddBytes(tnd.buf, strlen(name), (Byte *)name);
    } else {
	Buf_AddByte(tnd.buf, (Byte)'}');
    }

    newName = (char *)Buf_GetAll(tnd.buf, NULL);
    Buf_Destroy(tnd.buf, FALSE);
    return (newName);
}    

/*-
 *-----------------------------------------------------------------------
 * Type_NameOffset --
 *	Form a printable name from a type description. Offset is the
 *	number of spaces to place before it. This routine is "internal"
 *	in the sense that most callers should use Type_Name instead.
 *	Some callers, however, need the offset argument, so...
 *
 * Results:
 *	The name, which must be freed by the caller.
 *
 * Side Effects:
 *	Memory is allocated for the name.
 *
 *-----------------------------------------------------------------------
 */
char *
Type_NameOffset(Type	    type,   /* Type to name */
		char	    *name,  /* Extra string to put in the proper place
				     * (e.g. a variable name) */
		int	    offset, /* Extra space to place before it all */
		Boolean	    expand) /* TRUE if should expand any s/u/e's we
				     * find */
{
    char	    *tName;
    char 	    *freeme = 0;
    char	    *newName;
    TypePtr  	    t;
    Sym	    	    sym;

    MAKE_TYPE(type, t, sym);

    if (t == NULL) {
	tName = Sym_Name(sym);
	newName = (char *)malloc(strlen(tName) + sizeof("record "));
	freeme = newName;
	switch(Sym_Type(sym)) {
	    case OSYM_STRUCT:
		sprintf(newName, "struct %s", tName);
		if (expand) {
		    tName = TypeFormatStructUnion(type, newName, name, offset);
		    free((malloc_t)newName);
		    return(tName);
		}
		break;
	    case OSYM_UNION:
		sprintf(newName, "union %s", tName);
		if (expand) {
		    tName = TypeFormatStructUnion(type, newName, name, offset);
		    free((malloc_t)newName);
		    return(tName);
		}
		break;
	    case OSYM_ETYPE:
		sprintf(newName, "enum %s", tName);
		if (expand) {
		    tName = TypeFormatEnum(type, newName, name, offset);
		    free((malloc_t)newName);
		    return(tName);
		}
		break;
	    case OSYM_RECORD:
		sprintf(newName, "record %s", tName);
		if (expand) {
		    tName = TypeFormatStructUnion(type, newName, name, offset);
		    free((malloc_t)newName);
		    return(tName);
		}
		break;
	    default:
		/*
		 * Anything else must be a typedef. We just use the name of the
		 * symbol straight out.
		 */
		strcpy(newName, tName);
		break;
	}
	/*
	 * Go to the bottom of the function to tack the name onto the
	 * un-expanded type name...
	 */
	tName = newName;
    } else {
	switch(t->class) {
	    case TYPE_INT:
		if (t == TypeInt(type_Int)) {
		    tName = "int";
		} else if (t == TypeInt(type_Short)) {
		    tName = "short";
		} else if (t == TypeInt(type_Long)) {
		    tName = "long";
		} else if (t == TypeInt(type_UnsignedShort)) {
		    tName = "unsigned short";
		} else if (t == TypeInt(type_UnsignedLong)) {
		    tName = "unsigned long";
		} else if (t == TypeInt(type_UnsignedInt)) {
		    tName = "unsigned";
		} else if (t == TypeInt(type_Byte)) {
		    tName = "byte";
		} else if (t == TypeInt(type_Word)) {
		    tName = "word";
		} else if (t == TypeInt(type_DWord)) {
		    tName = "dword";
		} else if (t == TypeInt(type_SByte)) {
		    tName = "sbyte";
		} else {
		    tName = "int";
		}
		break;
	    case TYPE_CHAR:
		switch (t->data.Char.size) {
		    case 1: tName = "char"; break;
		    case 2: tName = "wchar"; break;
		    default:tName = "BUG"; break;
		}
		break;
	    case TYPE_VOID:
		tName = "void"; break;
	    case TYPE_POINTER:
	    {
		char	*distattr;
		
		tName = (char *)malloc(strlen(name) + 11);
		switch(t->data.Pointer.ptrType) {
		    case TYPE_PTR_NEAR:
			distattr = "_near *";
			break;
		    case TYPE_PTR_FAR:
			distattr = "_far *";
			break;
		    case TYPE_PTR_SEG:
			distattr = "_sptr ";
			break;
		    case TYPE_PTR_LMEM:
			distattr = "_lptr ";
			break;
		    case TYPE_PTR_HANDLE:
			distattr = "_hptr ";
			break;
		    case TYPE_PTR_OBJECT:
			distattr = "_optr ";
			break;
		    case TYPE_PTR_VIRTUAL:
			distattr = "_vfar ";
			break;
		    case TYPE_PTR_VM:
			distattr = "_vm ";
			break;
		    default:
			distattr = "_unknown *";
			break;
		}
		strcpy(tName, distattr);
		strcat(tName, name);
		newName = Type_NameOffset(t->data.Pointer.baseType,
				       tName, offset,
				       FALSE);
		free((malloc_t)tName);
		CLEANUP_TYPE(t);
		return(newName);
	    }
	    case TYPE_FUNCTION:
	    {
		tName = (char *)malloc(strlen(name) + 5);
		sprintf(tName, "(%s)()", name);
		newName = Type_NameOffset(t->data.Function.retType,
				       tName, offset,
				       FALSE);
		free((malloc_t)tName);
		CLEANUP_TYPE(t);
		return(newName);
	    }
	    case TYPE_ENUM:
		if (expand) {
		    CLEANUP_TYPE(t);
		    return (TypeFormatEnum(type, "", name, offset));
		} else {
		    tName = "enum";
		}
		break;
	    case TYPE_STRUCT:
		if (expand) {
		    CLEANUP_TYPE(t);
		    return (TypeFormatStructUnion(type, "struct",
						  name, offset));
		} else {
		    tName = "struct";
		}
		break;
	    case TYPE_UNION:
		if (expand) {
		    CLEANUP_TYPE(t);
		    return (TypeFormatStructUnion(type, "union",
						  name, offset));
		} else {
		    tName = "union";
		}
		break;
	    case TYPE_ARRAY:
	    {
		tName = (char *)malloc(strlen(name) + 13);

		sprintf(tName, "%s[%d]", name,
			t->data.Array.upper - t->data.Array.lower + 1);
		newName = Type_NameOffset(t->data.Array.baseType,
					  tName, offset, FALSE);
		free((malloc_t)tName);
		CLEANUP_TYPE(t);
		return(newName);
	    }
	    case TYPE_RANGE:
		if (Type_Class(t->data.Range.baseType) == TYPE_ENUM) {
		    /*
		     * Find top and bottom constants and return them in
		     * string separated by ".."
		     */
		    tName = "enum";
		} else {
		    tName = "int";
		}
		break;
	    case TYPE_FLOAT:
		if (t == TypeInt(type_Float)) {
		    tName = "float";
		} else if (t == TypeInt(type_Double)) {
		    tName = "double";
		} else {
		    tName = "long double";
		}
		break;
	    case TYPE_EXTERNAL: {
		char	*className;
		int	len;

		len = strlen(t->data.External.name) + 2;
		
		switch (t->data.External.class) {
		    case TYPE_STRUCT:
			className = "struct";
			len += 6;
			break;
		    case TYPE_UNION:
			className = "union";
			len += 5;
			break;
		    case TYPE_ENUM:
			className = "enum";
			len += 4;
			break;
		    default:
			className = "BUG";
			break;
		}
		freeme = tName = (char *)malloc(len);
		(void)sprintf(tName, "%s %s", className, t->data.External.name);
		break;
	    }
	    case TYPE_BITFIELD:
	    {
		/*
		 * XXX: assumes the offset is implicit in the ordering of the
		 * fields...
		 */
		newName = Type_NameOffset(t->data.BitField.type, name, offset,
					  expand); 
		CLEANUP_TYPE(t);
		return (newName);
	    }
	    default:
		tName = "BUG";
		break;
	}
    }

    newName = (char *)malloc_tagged((unsigned)(offset+strlen(tName)+1+
					       strlen(name)+1), TAG_TYPEETC);
    (void)sprintf(newName, "%*s%s%s%s", offset, "", tName, *name?" ":"",name);
    if (freeme != 0) {
	free((malloc_t)freeme);
    }
    CLEANUP_TYPE(t);
    return (newName);
}

/*-
 *-----------------------------------------------------------------------
 * Type_Name --
 *	Form a printable name from a type description.
 *
 * Results:
 *	The name, which must be freed by the caller.
 *
 * Side Effects:
 *	Memory is allocated for the name.
 *
 *-----------------------------------------------------------------------
 */
char *
Type_Name(Type    	type,	    /* Type to name */
	  char		*name,	    /* Extra string to put in the proper place
				     * (e.g. a variable name) */
	  Boolean	expand)	    /* TRUE if should expand sue's */
{
    return (Type_NameOffset(type, name, 0, expand));
}

/*-
 *-----------------------------------------------------------------------
 * Type_Cast --
 *	Transform the data given from one type to another.
 *
 * Results:
 *	TRUE if cast could be performed. FALSE if not.
 *
 * Side Effects:
 *	If cast was performed, old data are freed.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Type_Cast(Opaque  *valuePtr,
	  Type	  srcType,
	  Type	  dstType)
{
#if 0
    TypePtr 	  sT;
    TypePtr	  dT;

    MAKE_TYPE(srcType, sT);
    MAKE_TYPE(dstType, dT);
#endif

    return(FALSE);
}

/*-
 *-----------------------------------------------------------------------
 * Type_Equal --
 *	See if two types are equivalent.
 *
 * Results:
 *	TRUE if they are. FALSE if they aren't.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Type_Equal(Type    	type1,	    /* First type to compare */
	   Type    	type2)	    /* Second type to compare */
{
    TypePtr	  	st1;	    /* Slow TypePtr for type1 */
    TypePtr	  	st2;	    /* Slow TypePtr for type2 */
    register TypePtr	t1; 	    /* Real TypePtr for type1 */
    register TypePtr	t2; 	    /* Real TypePtr for type2 */
    Sym	    	    	s1;
    Sym	    	    	s2;
    Boolean 	    	retval;

    MAKE_TYPE(type1, st1, s1);
    MAKE_TYPE(type2, st2, s2);
    /*
     * If either type is external, we can't compare them, so just say they're
     * unequal....
     */
    if (st1 == NULL || st2 == NULL) {
	CLEANUP_TYPE(st1);
	CLEANUP_TYPE(st2);
	return(FALSE);
    }
    t1 = st1; t2 = st2;
    
    if (!t1 || !t2 || t1->class != t2->class) {
	CLEANUP_TYPE(st1);
	CLEANUP_TYPE(st2);
	return(FALSE);
    }
    if (t1 == t2) {
	CLEANUP_TYPE(st1);
	return(TRUE);
    }

    switch(t1->class) {
	case TYPE_POINTER:
	    if (Type_IsNull(t1->data.Pointer.baseType)) {
		retval = Type_IsNull(t2->data.Pointer.baseType);
	    } else if (Type_IsNull(t2->data.Pointer.baseType)) {
		retval = FALSE;
	    } else {
		retval = (t1->data.Pointer.ptrType==t2->data.Pointer.ptrType) &&
		    Type_Equal(t1->data.Pointer.baseType,
			       t2->data.Pointer.baseType);
	    }
	    break;
	case TYPE_ARRAY:
	    retval = (! ((t1->data.Array.lower != t2->data.Array.lower) ||
			 (t2->data.Array.upper != t2->data.Array.upper) ||
			 (!Type_Equal(t1->data.Array.baseType,
				      t2->data.Array.baseType)) ||
			 (!Type_Equal(t1->data.Array.indexType,
				      t2->data.Array.indexType))));
	    break;
	case TYPE_RANGE:
	    retval = (! ((t1->data.Range.lower != t2->data.Range.lower) ||
			 (t2->data.Range.upper != t2->data.Range.upper) ||
			 (!Type_Equal(t1->data.Range.baseType,
				      t2->data.Range.baseType))));
	    break;
	case TYPE_STRUCT:
	case TYPE_UNION:
	{
	    register FieldPtr	f1; 	/* Field from type 1 */
	    register FieldPtr	f2; 	/* Field from type 2 */
	    register int	i;
	    
	    if ((TypeInt(t1->data.StructUnion.checked) == t2) &&
		(TypeInt(t2->data.StructUnion.checked) == t1))
	    {
		/*
		 * Catch self-recursive structures and unions -- if
		 * we're already comparing these two, assume they are
		 * equal (the pointers are equivalent)
		 */
		retval = TRUE;
		break;
	    } else if (!Type_IsNull(t1->data.StructUnion.checked) ||
		       !Type_IsNull(t2->data.StructUnion.checked))
	    {
		/*
		 * Can't handle multiple recursion. If ever we get a
		 * structure or union that's being checked against someone
		 * else, we will assume they are not equal. See what
		 * happens.
		 */
		retval = FALSE;
		break;
	    }
	    
	    /*
	     * Figure out the length of both field vectors and if they don't
	     * match, the structures cannot be equal.
	     */
	    i = Vector_Length(t1->data.StructUnion.fields);
	    if (i != Vector_Length(t2->data.StructUnion.fields)) {
		retval = FALSE;
		break;
	    }
	    
	    TypeInt(t1->data.StructUnion.checked) = t2;
	    TypeInt(t2->data.StructUnion.checked) = t1;

	    /*
	     * Schmooz down both vectors one field at a time, making sure
	     * each one has the same offset, length, type and name.
	     */
	    for(f1=(FieldPtr)Vector_Data(t1->data.StructUnion.fields),
		f2=(FieldPtr)Vector_Data(t2->data.StructUnion.fields);
		i > 0;
		i--, f1++, f2++)
	    {
		if ((f1->offset != f2->offset) ||
		    (f1->length != f2->length) ||
		    (strcmp(f1->name, f2->name) != 0) ||
		    (!Type_Equal(f1->type, f2->type)))
		{
		    /*
		     * Field not in same position, of same size, of same name,
		     * or of same type --  not equivalent
		     */
		    t1->data.StructUnion.checked = NullType;
		    t2->data.StructUnion.checked = NullType;
		    retval = FALSE;
		    break;
		}
	    }
	    t1->data.StructUnion.checked = NullType;
	    t2->data.StructUnion.checked = NullType;
	    retval = TRUE;
	    break;
	}
	case TYPE_ENUM:
	{
	    register Enum	e1; 	/* Member from type 1 */
	    register Enum	e2; 	/* Member from type 2 */
	    LstNode		ln1;	/* Element of type 1's members list */
	    LstNode		ln2;	/* Element of type 2's members list */
	    register Lst  	l1; 	/* Type 1's members list */
	    register Lst  	l2; 	/* Type 2's members list */
	    int			n;
	    
	    l1 = t1->data.Enum.members;
	    l2 = t2->data.Enum.members;
	    n = Lst_Length(l1);
	    if (Lst_Length(l2) != n) {
		/*
		 * Different number of members -- not equivalent.
		 */
		retval = FALSE;
		break;
	    }
	    if ((Lst_Open(l1) != SUCCESS) || (Lst_Open(l2) != SUCCESS)) {
		/*
		 * Couldn't open a list -- no way to tell.
		 */
		Lst_Close(l1);
		Lst_Close(l2);
		retval = FALSE;
		break;
	    }
	    
	    /*
	     * Schmooz down both lists one member at a time making sure
	     * each one has the same name and value.
	     */
	    while (n > 0) {
		ln1 = Lst_Next(l1);
		ln2 = Lst_Next(l2);
		e1 = (Enum)Lst_Datum(ln1);
		e2 = (Enum)Lst_Datum(ln2);
		
		if ((e1->value != e2->value) ||
		    (strcmp(e1->name, e2->name) != 0))
		{
		    /*
		     * Different name or value -- not equivalent
		     */
		    Lst_Close(l1);
		    Lst_Close(l2);
		    retval = FALSE;
		    break;
		}
		n--;
	    }
	    Lst_Close(l1);
	    Lst_Close(l2);
	    retval = TRUE;
	    break;
	}
	case TYPE_FUNCTION:
	    retval = Type_Equal(t1->data.Function.retType,
				t2->data.Function.retType);
	    break;
	case TYPE_INT:
	    retval = (t1->data.Int.isSigned == t2->data.Int.isSigned) &&
		(t1->data.Int.size == t2->data.Int.size);
	    break;
	case TYPE_CHAR:
	    retval = (t1->data.Char.min == t2->data.Char.min) &&
		(t2->data.Char.max == t2->data.Char.max);
	    break;
	case TYPE_VOID:
	    retval = TRUE;
	    break;
	case TYPE_FLOAT:
	    retval = (t1->data.Float.size == t2->data.Float.size);
	    break;
	case TYPE_EXTERNAL:
	    retval = ((t1->data.External.class == t2->data.External.class) &&
		      (strcmp(t1->data.External.name,t2->data.External.name)==0));
	    break;
	default:
	    Warning("Unknown type in Type_Equal");
	    retval = FALSE;
	    break;
    }
    CLEANUP_TYPE(t1);
    CLEANUP_TYPE(t2);

    return(retval);
}

/*-
 *-----------------------------------------------------------------------
 * Type_Init --
 *	Initialize our information for the given patient.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Well, yeah. typePriv is altered to point to the hash table
 *	of defined structure/union types.
 *
 *-----------------------------------------------------------------------
 */
void
Type_Init(void)
{
    Type    	tv;

    Hash_InitTable(&structs, 0, HASH_ONE_WORD_KEYS, 0);

    TypeInt(tv) = (TypePtr)malloc_tagged(sizeof(TypeRec), TAG_TYPE);
    TypeInt(tv)->class = TYPE_VOID;
    TypeInt(tv)->temp = 0;
    TypeFile(tv) = (VMHandle)0;

#define CREATE(var,create) \
    var = create; GC_RegisterType(var)

    CREATE(type_Void,	    	tv);
    CREATE(type_Int,	    	(Type_CreateInt(2, TRUE)));
    CREATE(type_Short,	    	(Type_CreateInt(2, TRUE)));
    CREATE(type_Long,	    	(Type_CreateInt(4, TRUE)));
    CREATE(type_SByte,	    	(Type_CreateInt(1, TRUE)));
    CREATE(type_Char,	    	(Type_CreateChar(0, 127, 1)));
    CREATE(type_WChar,	    	(Type_CreateChar(0, 127, 2)));
    CREATE(type_UnsignedInt,	(Type_CreateInt(2, FALSE)));
    CREATE(type_UnsignedShort,	(Type_CreateInt(2, FALSE)));
    CREATE(type_UnsignedLong,	(Type_CreateInt(4, FALSE)));
    CREATE(type_UnsignedChar,	(Type_CreateInt(1, FALSE)));
    CREATE(type_Byte,		(Type_CreateInt(1, FALSE)));
    CREATE(type_Word,		(Type_CreateInt(2, FALSE)));
    CREATE(type_DWord,		(Type_CreateInt(4, FALSE)));
    CREATE(type_Float,		(Type_CreateFloat(4)));
    CREATE(type_Double,		(Type_CreateFloat(8)));
    CREATE(type_LongDouble, 	(Type_CreateFloat(10)));
    CREATE(type_NPtr,	    	(Type_CreatePointer(type_Void, TYPE_PTR_NEAR)));
    CREATE(type_FPtr,	    	(Type_CreatePointer(type_Void, TYPE_PTR_FAR)));
    CREATE(type_SPtr,	    	(Type_CreatePointer(type_Void, TYPE_PTR_SEG)));
    CREATE(type_LPtr,	    	(Type_CreatePointer(type_Void, TYPE_PTR_LMEM)));
    CREATE(type_HPtr,	    	(Type_CreatePointer(type_Void, TYPE_PTR_HANDLE)));
    CREATE(type_OPtr,	    	(Type_CreatePointer(type_Void, TYPE_PTR_OBJECT)));
    CREATE(type_VPtr,	    	(Type_CreatePointer(type_Void, TYPE_PTR_VM)));
    CREATE(type_VFPtr,	    	(Type_CreatePointer(type_Void, TYPE_PTR_VIRTUAL)));
    CREATE(type_VoidProc,   	(Type_CreateFunction(type_Void)));
    
    Cmd_Create(&TypeCmdRec);
}


/***********************************************************************
 *				Type_CreatePackedStruct
 ***********************************************************************
 * SYNOPSIS:	  Create a structure type from a list of fields.
 * CALLED BY:	  GLOBAL
 * RETURN:	  The new Type
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/25/88		Initial Revision
 *
 ***********************************************************************/
/*VARARGS*/
Type
Type_CreatePackedStruct(char *firstname, ...)
{
    va_list 	  args;
    int	    	  offset;
    TypePtr 	  t;
    char    	  *name;
    Type    	  ftype;
    int	    	  size;
    Type    	  rtype;

    va_start(args, firstname);

    name = firstname;
    

    ALLOC_TYPE(t, TYPE_STRUCT);

    TypeFile(rtype) = (VMHandle)0;
    TypeInt(rtype) = t;

    t->data.StructUnion.size = 0;
    t->data.StructUnion.fields = Vector_Create(sizeof(FieldRec),
					       TYPE_FIELD_ADJUST,
					       TYPE_FIELD_INCR,
					       TYPE_FIELD_INIT);
    t->data.StructUnion.checksum = 0;
    t->data.StructUnion.checked = NullType;

    offset = 0;

    while(name != (char *)0) {
	/*
	 * Fetch field type and size.
	 */
	ftype = va_arg(args, Type);
	size = Type_Sizeof(ftype);

	/*
	 * Add the field to the structure at the current offset
	 */
	Type_AddField(rtype, name, offset, size*8, ftype);

	/*
	 * Update the offset and overall size of the structure
	 */
	offset += size*8;
	t->data.StructUnion.size += size;


	name = va_arg(args, char *);
    }

    va_end(args);

    RETURN_TYPE(t);
}
    

/******************************************************************************
 *                                                                            *
 *		       GARBAGE COLLECTION STUFF				      *
 *                                                                            *
 *****************************************************************************/

/***********************************************************************
 *				Type_Mark
 ***********************************************************************
 * SYNOPSIS:	    Mark a type as in-use for garbage collection
 * CALLED BY:	    Sym_Mark
 * RETURN:	    === 0
 * SIDE EFFECTS:    The high bit on the tags for all things related to
 *		    this one is set.
 *
 * STRATEGY:	    Recursion, man.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/21/89		Initial Revision
 *
 ***********************************************************************/
int
Type_Mark(Type	type)
{
    TypePtr 	t;

    /*
     * Deal with empty structures -- Sym_Mark will call us regardless.
     * On a sun, this would cause us to die. On the ISI, this causes us
     * to die slowly by recursing endlessly. Avoid death at all costs.
     */
    if ((TypeFile(type) != 0) || (TypeInt(type) == NULL)) {
	return(0);
    }

    t = TypeInt(type);

    if (malloc_tag((char *)t) == (TAG_TYPE|0x80)) {
	/*
	 * Already marked -- nothing to do.
	 */
	return(0);
    }
    malloc_settag((char *)t, TAG_TYPE|0x80);

    switch(t->class) {
	case TYPE_INT:
	case TYPE_CHAR:
	case TYPE_VOID:
	case TYPE_ENUM:
	case TYPE_FLOAT:
	case TYPE_EXTERNAL:
	case TYPE_BITFIELD:
	    break;
	case TYPE_POINTER:
	    (void)Type_Mark(t->data.Pointer.baseType);
	    break;
	case TYPE_FUNCTION:
	    (void)Type_Mark(t->data.Function.retType);
	    break;
	case TYPE_UNION:
	case TYPE_STRUCT:
	{
	    register FieldPtr	f;
	    register int	i;
	    
	    f = (FieldPtr)Vector_Data(t->data.StructUnion.fields);
	    for (i = Vector_Length(t->data.StructUnion.fields);
		 i > 0;
		 i--)
	    {
		(void)Type_Mark(f->type);
		f++;
	    }
	    break;
	}
	case TYPE_ARRAY:
	    (void)Type_Mark(t->data.Array.indexType);
	    (void)Type_Mark(t->data.Array.baseType);
	    break;
	case TYPE_RANGE:
	    (void)Type_Mark(t->data.Range.baseType);
	    break;
	default:
	    Warning("Type_Mark: unknown type class %d", t->class);
    }
    return(0);
}


/***********************************************************************
 *				Type_Nuke
 ***********************************************************************
 * SYNOPSIS:	    Free up any extra memory for a type.
 * CALLED BY:	    GCCmd
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/24/89		Initial Revision
 *
 ***********************************************************************/
void
Type_Nuke(Opaque    type,
	  int	    *sizeFree,
	  int	    *numFree)
{
    TypePtr 	t = (TypePtr)type;
    int	    	num, size;

    num = size = 0;

    if (t->class == TYPE_STRUCT || t->class == TYPE_UNION) {
	/*
	 * Nuke the fields vector.
	 */
	Hash_Entry  *entry;
	LstNode	    ln;

	size += Vector_Size(t->data.StructUnion.fields);
	num += 1;
	
	Vector_Destroy(t->data.StructUnion.fields);

	/*
	 * Remove the definition from the structure-compression table
	 */
	entry = Hash_FindEntry(&structs, (Address)t->data.StructUnion.size);

	if (entry != (Hash_Entry *)NULL) {
	    for (ln = Lst_First((Lst)Hash_GetValue(entry));
		 ln != NILLNODE;
		 ln = Lst_Succ(ln))
	    {
		if (t == (TypePtr)Lst_Datum(ln)) {
		    /*
		     * Got it -- nuke the puppy and break out.
		     */
		    size += malloc_size(ln);
		    num++;
		    Lst_Remove((Lst)Hash_GetValue(entry), ln);
		    break;
		}
	    }
	}
    } else if (t->class == TYPE_ENUM) {
	/*
	 * Nuke all the EnumRec's for the type.
	 */
	num = Lst_Length(t->data.Enum.members);
	size = num * malloc_size(
                        (malloc_t)Lst_Datum(Lst_First(t->data.Enum.members)));
	Lst_Destroy(t->data.Enum.members, (void (*)())free);
    }

    *numFree = num;
    *sizeFree = size;
}

/***********************************************************************
 *				TIRCallback
 ***********************************************************************
 * SYNOPSIS:	    Callback function for Type_IsRecord to check
 *	    	    a field
 * CALLED BY:	    Type_IsRecord via Sym_ForEach
 * RETURN:	    TRUE if found a bitfield
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 1/90		Initial Revision
 *
 ***********************************************************************/
static Boolean
TIRCallback(Sym    sym,
	     Opaque data)
{
    Boolean	*dp = (Boolean *)data;
    int	    	offset;
    int	    	length;
    Type    	type;
    Type    	struc;

    Sym_GetFieldData(sym, &offset, &length, &type, &struc);

    if ((offset & 7) || (length != Type_Sizeof(type) * 8)) {
	/*
	 * Not on a byte boundary, or field length doesn't match field size;
	 * these are the hallmarks of a bitfield, so set the flag and stop
	 * enumerating, please.
	 */
	*dp = TRUE;
	return(TRUE);
    } else if (offset >= 16) {
	/*
	 * If we're beyond the first word, we can assume the thing isn't a
	 * record, since records are <= 16 bits wide...
	 */
	return(TRUE);
    } else {
	/*
	 * Still not sure...
	 */
	return(FALSE);
    }
}

/***********************************************************************
 *				Type_IsRecord
 ***********************************************************************
 * SYNOPSIS:	    See if a particular type is a record (i.e. contains
 *		    bitfields)
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    TRUE if it is
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/19/94	Initial Revision
 *
 ***********************************************************************/
Boolean
Type_IsRecord(Type  type)
{
    TypePtr t;
    Sym	    sym;
    Boolean result = FALSE;

    MAKE_TYPE(type, t, sym);

    if (t != NULL) {
	if (t->class == TYPE_STRUCT) {
	    /*
	     * Internal type that's a structure, so see if any of its
	     * fields looks like a bitfield.
	     */
	    FieldPtr	f;
	    int	    	i;

	    f = (FieldPtr)Vector_Data(t->data.StructUnion.fields);
	    for (i = Vector_Length(t->data.StructUnion.fields);
		 i > 0;
		 i--)
	    {
		if ((f->offset & 0x7) ||    /* not on byte boundary */
		    (f->length != Type_Sizeof(f->type) * 8))
		{
		    result = TRUE;
		    break;
		}
	    }
	}
    } else {
	switch (Sym_Type(sym)) {
	case OSYM_RECORD:
	    /*
	     * External type that's a record.
	     */
	    result = TRUE;
	    break;
	case OSYM_STRUCT:
	    /*
	     * External structure type from C could be considered a record
	     */
	    Sym_ForEach(sym, SYM_FIELD, TIRCallback, (Opaque)&result);
	    break;
	}
    }

    CLEANUP_TYPE(t);

    return(result);
}
