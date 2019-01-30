/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Type Description Manipulation
 * FILE:	  type.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 27, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Type_Char   	    Create a node of type TYPE_CHAR
 *	Type_Near   	    Create a node of type TYPE_NEAR
 *	Type_Far    	    Create a node of type TYPE_FAR
 *	Type_Int    	    Create a node of type TYPE_INT of a given size
 *	Type_Array  	    Create a node for an array (TYPE_ARRAY) of
 *			    a given length and element type
 *	Type_Signed 	    Create a node of type TYPE_SIGNED for an
 *			    integer of a given size.
 *	Type_Struct 	    Create a node for a structured type.
 *	Type_Ptr    	    Create a node describing a pointer to something
 *	Type_Void   	    Create a node of type TYPE_VOID
 *	Type_Size   	    Figure the element size of a description
 *	Type_Length 	    Figure the number of elements for a description
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/27/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to deal with type descriptions.
 *
 ***********************************************************************/


#include    "esp.h"
#include    "type.h"

/*
 * Statically-allocated nodes for integers (signed and unsigned) of sizes
 * 0 to 10 (for speed and space savings).
 *
 * XXX: THIS IS GROSS! Probably better to just have an array of TypeRecs that
 * are inititialized when one is first used. Until I do this, however, this
 * little structure MUST MATCH THE INITIAL PART OF TypeRec
 */
static struct {
    enum TypeType   type;
    VMBlockHandle   block;
    word    	    offset;
    TypePtr 	    ptrto;
    int	    	    size;
}	typeInts[] = {
    { TYPE_INT, 	    0,	0,  0,	0, },
    { TYPE_INT,	    0,	0,  0,	1, },
    { TYPE_INT,	    0,	0,  0,	2, },
    { TYPE_INT,	    0,	0,  0,	3,  /* BOGUS */ },
    { TYPE_INT,	    0,	0,  0,	4, },
    { TYPE_INT,	    0,	0,  0,	5,  /* BOGUS */ },
    { TYPE_INT,	    0,	0,  0,	6,  /* BOGUS */ },
    { TYPE_INT,	    0,	0,  0,	7,  /* BOGUS */ },
    { TYPE_INT,	    0,	0,  0,	8, },
    { TYPE_INT,	    0,	0,  0,	9,  /* BOGUS */ },
    { TYPE_INT,	    0,	0,  0,	10, },
},	typeSInts[] = {
    { TYPE_SIGNED,    0,	0,  0,	0, },
    { TYPE_SIGNED,    0,	0,  0,	1, },
    { TYPE_SIGNED,    0,	0,  0,	2, },
    { TYPE_SIGNED,    0,	0,  0,	3,  /* BOGUS */ },
    { TYPE_SIGNED,    0,	0,  0,	4, },
    { TYPE_SIGNED,    0,	0,  0,	5,  /* BOGUS */ },
    { TYPE_SIGNED,    0,	0,  0,	6,  /* BOGUS */ },
    { TYPE_SIGNED,    0,	0,  0,	7,  /* BOGUS */ },
    { TYPE_SIGNED,    0,	0,  0,	8, },
    { TYPE_SIGNED,    0,	0,  0,	9,  /* BOGUS */ },
    { TYPE_SIGNED,    0,	0,  0,	10, },
};
#define NUM_INTS (sizeof(typeInts)/sizeof(typeInts[0]))
#define NUM_SINTS (sizeof(typeSInts)/sizeof(typeSInts[0]))
TypeRec	typeVoid = {TYPE_VOID};
TypeRec	typeNear = {TYPE_NEAR};
TypeRec	typeFar = {TYPE_FAR};


/***********************************************************************
 *				TypeNewNode
 ***********************************************************************
 * SYNOPSIS:	    Return a new node that will never be freed.
 * CALLED BY:	    Type_Int, Type_Array, Type_Signed, Type_Struct,
 *	    	    Type_Ptr
 * RETURN:	    A new node...
 * SIDE EFFECTS:    Another chunk of nodes may be allocated
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/27/89		Initial Revision
 *
 ***********************************************************************/
static inline TypePtr
TypeNewNode(void)
{
    static TypePtr  nextTP;
    static int	    numTP=0;

    if (numTP == 0) {
	numTP = 100;	/* A Nice Round Number */
	nextTP = (TypePtr)malloc(numTP * sizeof(TypeRec));
    }

    numTP -= 1;

    /*
     * Initialize common fields
     */
    nextTP->tn_block = 0;
    nextTP->tn_ptrto = NULL;
    
    return(nextTP++);
}


/***********************************************************************
 *				Type_Int
 ***********************************************************************
 * SYNOPSIS:	    Return a TYPE_INT node for an unsigned integer of
 *		    the given size.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    ...
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/27/89		Initial Revision
 *
 ***********************************************************************/
TypePtr
Type_Int(int	size)
{
    if (size < 0) {
	return(Type_Signed(-size));
    } else if (size < NUM_INTS) {
	return((TypePtr)&typeInts[size]);
    } else {
	TypePtr	tp = TypeNewNode();

	tp->tn_type = TYPE_INT;
	tp->tn_u.tn_int = size;

	return(tp);
    }
}


/***********************************************************************
 *				Type_Char
 ***********************************************************************
 * SYNOPSIS:	    Return a TYPE_CHAR node for an char of the given size.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    ...
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	gene	6/1/93		Initial Revision
 *
 ***********************************************************************/
TypePtr
Type_Char(int	size)
{
    TypePtr	tp = TypeNewNode();

    tp->tn_type = TYPE_CHAR;
    tp->tn_u.tn_charSize = size;

    return(tp);
}

/***********************************************************************
 *				Type_Signed
 ***********************************************************************
 * SYNOPSIS:	    Return a TYPE_SIGNED node for an integer of
 *		    the given size.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    ...
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/27/89		Initial Revision
 *
 ***********************************************************************/
TypePtr
Type_Signed(int	size)
{
    if (size < NUM_SINTS) {
	return((TypePtr)&typeSInts[size]);
    } else {
	TypePtr	tp = TypeNewNode();

	tp->tn_type = TYPE_SIGNED;
	tp->tn_u.tn_int = size;

	return(tp);
    }
}


/***********************************************************************
 *				Type_Array
 ***********************************************************************
 * SYNOPSIS:	    Return a TYPE_ARRAY node for an array of the given
 *		    length and element type.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    ...
 * SIDE EFFECTS:    None
 *	
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/27/89		Initial Revision
 *
 ***********************************************************************/
TypePtr
Type_Array(int	    length,
	   TypePtr  base)
{
    TypePtr tp = TypeNewNode();

    tp->tn_type = TYPE_ARRAY;
    tp->tn_u.tn_array.tn_length = length;
    tp->tn_u.tn_array.tn_base = base;

    return(tp);
}


/***********************************************************************
 *				Type_Struct
 ***********************************************************************
 * SYNOPSIS:	    Return a TYPE_STRUCT node to describe a reference
 *		    to the given structure type (enum, struct, record,
 *		    etc)
 * CALLED BY:	    EXTERNAL
 * RETURN:	    ...
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/27/89		Initial Revision
 *
 ***********************************************************************/
TypePtr
Type_Struct(Symbol *t)
{
    TypePtr 	tp;

    if (t->u.typesym.desc) {
	return(t->u.typesym.desc);
    } else {
	tp = t->u.typesym.desc = TypeNewNode();

	tp->tn_type = TYPE_STRUCT;
	tp->tn_u.tn_struct = t;
	Sym_Reference(t);
    }

    return(tp);
}


/***********************************************************************
 *				Type_Ptr
 ***********************************************************************
 * SYNOPSIS:	    Return a TYPE_PTR node to describe a pointer to
 *	    	    a type.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    ...
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/27/89		Initial Revision
 *
 ***********************************************************************/
TypePtr
Type_Ptr(char	    pType,	    /* Pointer type (n, f, s, l, h, o) */
	 TypePtr    base)   	    /* Type pointed to */
{
    TypePtr 	tp;

    for (tp = base->tn_ptrto; tp != NULL; tp = tp->tn_u.tn_ptr.tn_next) {
	if (tp->tn_u.tn_ptr.tn_ptrtype == pType) {
	    return(tp);
	}
    }

    tp = TypeNewNode();

    tp->tn_type = TYPE_PTR;
    tp->tn_u.tn_ptr.tn_ptrtype = pType;
    tp->tn_u.tn_ptr.tn_base = base;

    tp->tn_u.tn_ptr.tn_next = base->tn_ptrto;
    base->tn_ptrto = tp;

    return(tp);
}

	

/***********************************************************************
 *				Type_Size
 ***********************************************************************
 * SYNOPSIS:	    Figure the size of a type description
 * CALLED BY:	    yyparse
 * RETURN:	    The size of an element of the type (if it's an array
 *	    	    type) or the size of the type itself.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/30/89		Initial Revision
 *
 ***********************************************************************/
int
Type_Size(TypePtr    tp)
{
    if (tp == NULL) {
	return (0);
    }
    
    switch(tp->tn_type) {
	case TYPE_CHAR:
	    return(tp->tn_u.tn_charSize);
	case TYPE_PTR:
	    switch(tp->tn_u.tn_ptr.tn_ptrtype) {
	    case 'n': case 's': case 'h': case 'l':
		return(2);
	    case 'f': case 'o': case 'v': case 'F':
		return(4);
	    }
    	case TYPE_NEAR:
    	case TYPE_FAR:
	case TYPE_VOID:
	    return(1);
	case TYPE_SIGNED:
	case TYPE_INT:
	    return(tp->tn_u.tn_int ? tp->tn_u.tn_int : 2);
	case TYPE_ARRAY:
	    return(Type_Size(tp->tn_u.tn_array.tn_base) *
		   tp->tn_u.tn_array.tn_length);
	case TYPE_STRUCT: 
	    return(tp->tn_u.tn_struct->u.typesym.size);
	default:
	    assert(0);
	    return(0);
    }
}

/***********************************************************************
 *				Type_Length
 ***********************************************************************
 * SYNOPSIS:	    Return the length of a type.
 * CALLED BY:	    yyparse
 * RETURN:	    The length of the type: 1 if not an array, tn_length
 *	    	    if so.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/30/89		Initial Revision
 *
 ***********************************************************************/
int
Type_Length(TypePtr  tp)
{
    if (tp) {
	if (tp->tn_type == TYPE_ARRAY) {
	    return(tp->tn_u.tn_array.tn_length);
	} else if (tp->tn_type == TYPE_STRUCT &&
		   tp->tn_u.tn_struct->type == SYM_TYPE)
	{
	    /*
	     * For a typedef, return the length of the typedef's description
	     */
	    return(Type_Length(tp->tn_u.tn_struct->u.typeDef.type));
	}
    }
    return(1);
}

/***********************************************************************
 *				Type_Equal
 ***********************************************************************
 * SYNOPSIS:	    See if two type descriptions are equal. This
 *	    	    works on name equivalence, not structural equivalence
 * CALLED BY:	    EXTERNAL
 * RETURN:	    1 if they are, 0 if they're not.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/24/89		Initial Revision
 *
 ***********************************************************************/
int
Type_Equal(TypePtr  t1,
	   TypePtr  t2)
{
    if (t1 == t2) {
	return(1);
    } else if (!t1 || !t2) {
	return(0);
    } else if (t1->tn_type != t2->tn_type) {
	return(0);
    } else {
	switch(t1->tn_type) {
	    case TYPE_CHAR:
	    	/*
		 * char and wchar are not the same thing...
		 */
	    	return (t1->tn_u.tn_charSize == t2->tn_u.tn_charSize);
	    case TYPE_NEAR:
	    case TYPE_FAR:
	    case TYPE_VOID:
		/*
		 * There are no variations on these themes...
		 */
		return(1);
	    case TYPE_INT:
	    case TYPE_SIGNED:
		/*
		 * These always come from a static area, so to be equal,
		 * they must be equal :)
		 */
		return(t1 == t2);
	    case TYPE_ARRAY:
		/*
		 * Lengths and base types must match
		 */
		return((t1->tn_u.tn_array.tn_length ==
			t2->tn_u.tn_array.tn_length) &&
		       Type_Equal(t1->tn_u.tn_array.tn_base,
				  t2->tn_u.tn_array.tn_base));
	    case TYPE_STRUCT:
		/*
		 * Since this is name-equivalence, we have only to compare
		 * the symbol pointers -- if they're different, the
		 * structures can't be the same.
		 */
		return(t1->tn_u.tn_struct == t2->tn_u.tn_struct);
	    case TYPE_PTR:
		/*
		 * Type of pointer and type pointed to must match.
		 * Except we allow a void * to match anything
		 */
		return((t1->tn_u.tn_ptr.tn_ptrtype ==
			t2->tn_u.tn_ptr.tn_ptrtype) &&
		       (Type_Equal(t1->tn_u.tn_ptr.tn_base,
				   t2->tn_u.tn_ptr.tn_base) ||
			t1->tn_u.tn_ptr.tn_base == &typeVoid ||
			t2->tn_u.tn_ptr.tn_base == &typeVoid));
	    default:
		Notify(NOTIFY_ERROR, NullID, 0,
		       "unknown type %d in Type_Equal", t1->tn_type);
		return(0);
	}
    }
}
