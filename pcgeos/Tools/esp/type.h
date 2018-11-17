/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Type Description definitions.
 * FILE:	  type.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 27, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/27/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for building up type descriptions.
 *
 *
 * 	$Id: type.h,v 1.13 94/05/15 15:09:14 adam Exp $
 *
 ***********************************************************************/
#ifndef _TYPE_H_
#define _TYPE_H_

#define TYPE_PTR_FAR	'f'
#define TYPE_PTR_NEAR	'n'
#define TYPE_PTR_LMEM	'l'
#define TYPE_PTR_HANDLE	'h'
#define TYPE_PTR_SEG	's'
#define TYPE_PTR_OBJ	'o'
#define TYPE_PTR_VM 	'v'
#define TYPE_PTR_VIRTUAL 'F'

typedef struct _Type {
    enum TypeType {
	TYPE_CHAR,		/* Character */
	TYPE_INT,		/* Unspecified (integer) */
	TYPE_PTR,		/* Pointer to something */
	TYPE_ARRAY,		/* Array of things */
	TYPE_STRUCT, 		/* Structured type (STRUC, Enum, RECORD) */
	TYPE_VOID,		/* Void (used for pointers to routines) */
	TYPE_SIGNED, 	    	/* Signed integer */
	TYPE_NEAR,  	    	/* NEAR label */
	TYPE_FAR,   	    	/* FAR label */
	TYPE_FLOATSTACK    	/* coprocessor stack element */
    }		tn_type;	/* Type of node */
    VMBlockHandle   tn_block;	    /* Block in which type was last written */
    word    	    tn_offset;	    /* Offset at which it was written */
    struct _Type    *tn_ptrto;	    /* First description of a pointer to
				     * this type. */
    union {
	int		tn_int;	    	/* Size of TYPE_INT/TYPE_SIGNED */
	SymbolPtr	tn_struct;	/* Type for TYPE_STRUCT */
	struct {
	    struct _Type    *tn_base;	    /* Type pointed to */
	    struct _Type    *tn_next;	    /* Next pointer class to same
					     * base */
	    char	    tn_ptrtype;	    /* Type of pointer */
	}		tn_ptr;		/* Data for TYPE_PTR */
	struct {
	    struct _Type    *tn_base;	    /* Base type of array */
	    int		    tn_length;	    /* Length of array */
	}		tn_array;	/* Data for TYPE_ARRAY */
	int 	    	tn_floatstack; /* coprocessor stack element */
	int 	    	tn_charSize;	/* Size of TYPE_CHAR */
    }		tn_u;
} TypeRec, *TypePtr;

/*
 * Constructors
 */
extern TypeRec	typeNear, typeFar, typeVoid;
#define Type_Near() (&typeNear)
#define Type_Far()  (&typeFar)
#define Type_Void() (&typeVoid)

extern TypePtr	Type_Int(int size),
    	    	Type_Char(int size),
		Type_Array(int len, TypePtr base),
		Type_Signed(int size),
		Type_Struct(SymbolPtr t),
		Type_Ptr(char pType, TypePtr base);

/*
 * Things to deal with type descriptions
 */
extern int  	Type_Size(TypePtr type);
extern int	Type_Length(TypePtr type);
extern int  	Type_Equal(TypePtr t1, TypePtr t2);

#endif /* _TYPE_H_ */
