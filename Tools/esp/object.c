/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Object support
 * FILE:	  object.c
 *
 * AUTHOR:  	  Adam de Boor: Apr 25, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Obj_DeclareClass    Begin the declaration of a class.
 *	Obj_EnterHandler    Define a method handler for a class
 *	Obj_DefineClass	    Define a class record for a class
 *	Obj_EnterDefault    Define the default method handler for a class.
 *	Obj_ClassType	    Return the actual type description of a class
 *	    	    	    record.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/25/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Support for PC/GEOS's object world, including class, instance and
 *	method definition.
 *
 *	Note that the support for the "noreloc" directive is not
 *	particularly efficient. This is because it's not used much,
 *	certainly not more than a few times per class, and most classes
 *	have none.
 *
 ***********************************************************************/

#include    "esp.h"
#include    "expr.h"
#include    "data.h"
#include    "scan.h"
#include    "type.h"
#include    "object.h"
#include    <stddef.h>
    
#define SORT_METHOD_TABLES  0

/*
 * PC/GEOS class record, method table not included. Doesn't use any dword
 * fields, though the PC/GEOS structure does, to avoid alignment problems
 * on the Sparc.
 */
typedef struct {
    word    Class_superClassOff;    /* Superclass pointer */
    word    Class_superClassSeg;    /* Segment of same */
    word    Class_masterOffset;	    /* Offset w/in base of master field */
    word    Class_methodCount;	    /* Number of method handlers */
    word    Class_instanceSize;	    /* Size of instance data (part) */
    word    Class_initRoutineOff;   /* Pointer to routine for initializing
				     * other class data on first instantiation
				     * of object in class */
    word    Class_initRoutineSeg;   /* Segment of same */
    word    Class_relocTable;	    /* Offset of relocation table*/
    byte    Class_flags;    	    /* Flags for class (formed from known class
				     * type and flags given for definition) */
    byte    Class_masterMethods;    /* Bits for method handlers in the different
				     * master levels */
} Class_rel1;

typedef struct {
    word    Class_superClassOff;    /* Superclass pointer */
    word    Class_superClassSeg;    /* Segment of same */
    word    Class_masterOffset;	    /* Offset w/in base of master field */
    word    Class_methodCount;	    /* Number of method handlers */
    word    Class_instanceSize;	    /* Size of instance data (part) */
    word    Class_vdRelocTable;	    /* Offset of vardata relocation table */
    word    Class_relocTable;	    /* Offset of relocation table*/
    byte    Class_flags;    	    /* Flags for class (formed from known class
				     * type and flags given for definition) */
#define CLASSF_HAS_DEFAULT  	    0x80
#define CLASSF_MASTER_CLASS 	    0x40
#define CLASSF_VARIANT_CLASS	    0x20
#define CLASSF_DISCARD_ON_SAVE	    0x10
#define CLASSF_NEVER_SAVED  	    0x08
#define CLASSF_HAS_RELOC    	    0x04
#define CLASSF_UNUSED	    	    0x03
    byte    Class_masterMethods;    /* Bits for method handlers in the different
				     * master levels */
} Class;

/*
 * Relocation types (first byte of relocation entry)
 */
#define RELOC_END_OF_LIST   0
#define RELOC_HANDLE	    1
#define RELOC_SEGMENT	    2
#define RELOC_ENTRY_POINT   3

typedef struct {
    SymbolPtr   tag;	    /* SYM_VARDATA tag with which noreloc offset is
			     * associated. NULL if associated with instance
			     * data, not vardata. */
#define ONR_LAST    ((SymbolPtr)-1) /* Value for "tag" if this is the last
				     * ObjNoReloc structure in the array */
    int	    	offset;	    /* Offset into associated structure (either vardata
			     * or instance data, if tag is NULL) at which a
			     * relocation is not to take place */
#define ONR_ENTIRE_VARDATA  -1	/* Value in offset field for vardata if entire
				 * data for that beast should not be
				 * relocated */
} ObjNoReloc;

static struct {
    int	    messagesPerClass;	    /* Message numbers allocated per normal
				     * class */
    int	    messagesPerMasterClass; /* Message numbers allocated for a master
				     * class */
    int	    messagesForMetaClass;   /* Message numbers allocated for a meta
				     * class */
    int	    firstMasterNumber;	    /* First number for first master class */
    int	    messagesPerMasterLevel; /* Total message numbers allocated for a
				     * master level */
}	messageAlloc[] =  {
{	512,	512,	2048,	8192, 	8192 },	/* Release 1.X */
{	512,	2048,	8192,	16384,	8192 }	/* Release 2.0 and later */
};

static int ObjInit(void);


/***********************************************************************
 *				ObjFetchHandlerType
 ***********************************************************************
 * SYNOPSIS:	    Return a type description for the handler of a message
 * CALLED BY:	    INTERNAL
 * RETURN:	    TypePtr to pass to ObjDataEnter
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/12/92		Initial Revision
 *
 ***********************************************************************/
static TypePtr
ObjFetchHandlerType(void)
{
    static TypePtr	objHandlerPtr = NULL;

    if (objHandlerPtr == NULL) {
	objHandlerPtr = Type_Ptr(TYPE_PTR_FAR, Type_Far());
    }

    return(objHandlerPtr);
}



/***********************************************************************
 *				ObjFigureMessageStart
 ***********************************************************************
 * SYNOPSIS:	    Figure where the messages for a class start.
 * CALLED BY:	    Obj_DeclareClass, Obj_CheckVarDataBounds
 * RETURN:	    the start of the message range for a class
 *	    	    below the given superclass, and which has the passed
 *	    	    flags.
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 7/91	Initial Revision
 *
 ***********************************************************************/
static int
ObjFigureMessageStart(int   	flags,
		      SymbolPtr	superClass)
{
    SymbolPtr	cl;
    int	    	mbase = 0;
    int	    	masterBase;
    
    /*
     * Figure the base of the Methods type for the class by counting
     * up the class hierarchy until we blow through the roof. Note we
     * have to deal with the current class being a master class
     * specially, else only classes below a master will have the special
     * master group offset added in, which isn't right.
     */
    if (flags & SYM_CLASS_MASTER) {
	masterBase = messageAlloc[geosRelease-1].messagesPerMasterLevel;
    } else {
	masterBase = 0;
    }
    for (cl = superClass; cl != NULL; cl = cl->u.class.super) {
	/*
	 * Only sum methods within the master group. If there are no
	 * master groups in the hierarchy, masterBase remains zero and
	 * mbase sums up the tree.
	 */
	if (!masterBase) {
	    /*
	     * Haven't encountered a master class yet, so adjust
	     * intra-master base by another class level.
	     */
	    mbase += messageAlloc[geosRelease-1].messagesPerClass;
	}
	if (cl->u.class.data->flags & SYM_CLASS_MASTER) {
	    if (!masterBase) {
		/*
		 * First master class encountered, so give it the
		 * required amount of extra room.
		 */
		mbase += messageAlloc[geosRelease-1].messagesPerMasterClass-
		    messageAlloc[geosRelease-1].messagesPerClass;
	    }
	    masterBase += messageAlloc[geosRelease-1].messagesPerMasterLevel;
	}
    }
    /*
     * Deal with extra room given to meta classes in some releases
     * by making sure masters start at firstMasterNumber for the
     * release. Need to subtract out messagesPerMasterLevel as
     * we've already got it added in to masterBase for the top-most
     * master class, when we should have used firstMasterNumber
     * instead.
     */
    if (masterBase) {
	masterBase += messageAlloc[geosRelease-1].firstMasterNumber -
	    messageAlloc[geosRelease-1].messagesPerMasterLevel;
    }
    /*
     * Offset the base into the master group.
     */
    mbase += masterBase;
    
    if (!masterBase) {
	/*
	 * In a group with the meta-class -- give the meta-class
	 * breathing room by offsetting methods for subclasses in its
	 * group by the proper amount.
	 */
	mbase += messageAlloc[geosRelease-1].messagesForMetaClass -
	    messageAlloc[geosRelease-1].messagesPerClass;
    }

    return(mbase);
}


/***********************************************************************
 *				ObjDataEnter
 ***********************************************************************
 * SYNOPSIS:	Enter data, avoiding bogus warnings about inline data.
 * CALLED BY:	Obj_EnterDefault, Obj_EnterReloc, Obj_EnterHandler,
 *		Obj_DefineClass
 * RETURN:	whatever Data_Enter returns
 * SIDE EFFECTS:?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/31/91		Initial Revision
 *
 ***********************************************************************/
static inline int
ObjDataEnter(int    	*addrPtr,   /* IN/OUT: address at which to store */
	     TypePtr  	type,	    /* Type of data being defined */
	     Expr    	*expr,	    /* Value(s) to store. Must not have
				     * anything where the parser can nuke
				     * it. */
	     int    	maxElts)    /* Maximum number of elements that may
				     * be in expr */
{
    int	    old_w_i_d = warn_inline_data;
    int	    rval;

    warn_inline_data = FALSE;
    rval = Data_Enter(addrPtr, type, expr, maxElts);
    warn_inline_data = old_w_i_d;

    return(rval);
}

/***********************************************************************
 *				Obj_DeclareClass
 ***********************************************************************
 * SYNOPSIS:	    Begin the definition of a new class
 * CALLED BY:	    StartClass
 * RETURN:	    The symbol for the class, ready for fields, etc.
 * SIDE EFFECTS:   
 *
 * STRATEGY:	    Use the class name as the basis for the instance
 *	    	    structure and and methods. If the class name ends in
 *	    	    "Class", it is stripped before "Instance" and "Methods"
 *	    	    are tacked onto the end to form the name for the
 *	    	    instance structure and method enumerated type.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/25/89		Initial Revision
 *
 ***********************************************************************/
SymbolPtr
Obj_DeclareClass(ID	    className,	/* Name for new class */
		 SymbolPtr  superClass,	/* Parent class (NULL if meta class) */
		 int 	    flags)  	/* Flags describing inheritance */
{
    int 	len;
    SymbolPtr	class,	    	/* Symbol to return */
		instance,   	/* Instance structure */
		methods,    	/* Methods enum */
		vardata,    	/* VarData enum */
		base;	    	/* Base structure */
    int	    	mbase;  	/* Base for methods enum */
    char    	*classStr;  	/* Pointer to locked className */
    
    if (flags & SYM_CLASS_FORWARD) {
	base = NullSymbol;
	instance = NullSymbol;
	methods = NullSymbol;
	vardata = NullSymbol;
    } else {
	char	*tmpName;	/* Buffer for instance and
				 * method type names */

	/*
	 * Figure the base of the Instance, Base and Methods
	 * type names by trimming the Class off the identifier
	 * if it's there.
	 */
	classStr = ST_Lock(output, className);
	len = strlen(classStr);
	if (len > 5 && bcmp(classStr+len-5, "Class", 5) == 0) {
	    len -= 5;
	}
	/*
	 * Allocate a buffer to hold the base name plus the longest suffix
	 * we'll tack onto it, then copy the base into the start of the buffer.
	 */
	tmpName = (char *)malloc(len + sizeof(OBJ_LONGEST_SUFFIX));
	bcopy(classStr, tmpName, len);

	ST_Unlock(output, className);

	/*
	 * Create the symbol for the Instance structure type.
	 */
	strcpy(tmpName+len, OBJ_INSTANCE_SUFFIX);
	instance = Sym_Enter(ST_Enter(output, symStrings,
				      tmpName,
				      len+sizeof(OBJ_INSTANCE_SUFFIX)-1),
			     SYM_STRUCT);


	if (superClass) {
	    SymbolPtr   cl; 	    /* Class pointer for tree traversal */
	    ExprElt	fElts[2];	
	      /* 		2, curFile->name, 0, 0, 0, curProc, {0, 0, 0, 0}, fElts */
	    Expr	fExpr;
	    Expr	*iExpr,     /* Integral 0 for integer fields */
			*sExpr;     /* String 0 for structure fields */
	    int 	freeI;      /* FALSE if iExpr used and can't be freed */

	    fExpr.numElts = 2;
	    fExpr.file = curFile->name;
	    fExpr.line = 0;
	    fExpr.idents = 0;
	    fExpr.musteval = 0;
	    fExpr.curProc = curProc;
	    fExpr.segments[0] = 0;
	    fExpr.segments[1] = 0;
	    fExpr.segments[2] = 0;
	    fExpr.segments[3] = 0;
	    fExpr.elts = fElts;

	    fExpr.line = yylineno;
	    /*
	     * Zero the second element of the field-value expression. This will
	     * give us both an empty string and a 0 integer.
	     */
	    bzero(&fElts[1], sizeof(fElts[1]));

	    /*
	     * Set up empty-string initializer for structure fields
	     */
	    fElts[0].op = EXPR_INIT;
	    sExpr = Expr_Copy(&fExpr, FALSE);

	    /*
	     * Set up zero-integer initializer for integral fields
	     */
	    fElts[0].op = EXPR_CONST;
	    iExpr = Expr_Copy(&fExpr, FALSE);
	    freeI = TRUE;

	    /*
	     * Create the symbol for the Base structure type.
	     */
	    strcpy(tmpName+len, OBJ_BASE_SUFFIX);
	    base = Sym_Enter(ST_Enter(output, symStrings,
				      tmpName, len+sizeof(OBJ_BASE_SUFFIX)-1),
			     SYM_STRUCT);

	    /*
	     * All Bases have a field at the beginning that holds the Base for
	     * their superclass.
	     */
	    strcpy(tmpName+len,OBJ_META_BASE_SUFFIX);
	    (void)Sym_Enter(ST_Enter(output, symStrings,
				     tmpName,
				     len+sizeof(OBJ_META_BASE_SUFFIX)-1),
			    SYM_FIELD,
			    base,	    	    	 /* Containing type */
			    Type_Struct(superClass->u.class.data->base),
			    sExpr);	    	   /* Default value */

	    if (flags & SYM_CLASS_MASTER) {
		/*
		 * If class is a master class, need to add another field to
		 * the Base of the superclass.
		 */
		strcpy(tmpName+len, OBJ_BASE_OFF_SUFFIX);
		(void)Sym_Enter(ST_Enter(output, symStrings,
					 tmpName,
					 len+sizeof(OBJ_BASE_OFF_SUFFIX)-1),
				SYM_FIELD,
				base,
				Type_Int(2),
				iExpr);
		freeI = FALSE;
	    } else {
		/*
		 * Not a master, but it's still nice to have a foo_offset
		 * symbol around so the programmer needn't be aware of where
		 * the master boundary lies, so create a SYM_EXPR that
		 * points to the master boundary's offset symbol.
		 * Note that we do have to deal with cases where there are
		 * *no* master classes in the hierarchy. In such a case,
		 * we don't create any master-offset symbol.
		 */
		SymbolPtr   masterClass;
		
		strcpy(tmpName+len, OBJ_BASE_OFF_SUFFIX);
		for (masterClass = superClass;
		     masterClass != NULL &&
		     (masterClass->u.class.data->flags & SYM_CLASS_MASTER)==0;
		     masterClass = masterClass->u.class.super)
		{
		    ;
		}
		
		if (masterClass != NULL) {
		    fElts[0].op = EXPR_SYMOP;
		    fElts[1].sym =
			masterClass->u.class.data->base->u.sType.last;
		    
		    (void)Sym_Enter(ST_Enter(output, symStrings,
					     tmpName,
					     len+sizeof(OBJ_BASE_OFF_SUFFIX)-1),
				    SYM_NUMBER,
				    Expr_Copy(&fExpr, FALSE),
				    TRUE);
		}
	    }


	    strcpy(tmpName+len, OBJ_META_INST_SUFFIX);

	    if (flags & SYM_CLASS_VARIANT) {
		/*
		 * Variant class -- has variable superclass, so superclass
		 * pointer is contained in MetaBase structure at start of
		 * instance data. "MetaBase" is the base structure of the class
		 * at the root of this class's hierarchy.
		 */

		/*
		 * Get to the top of the tree...
		 */
		for (cl = superClass;
		     cl->u.class.super != NULL;
		     cl = cl->u.class.super)
		{
		    ;
		}
		(void)Sym_Enter(ST_Enter(output, symStrings,
					 tmpName,
					 len+sizeof(OBJ_META_INST_SUFFIX)-1),
				SYM_FIELD,
				instance,
				Type_Struct(cl->u.class.data->base),
				sExpr);
	    } else if ((flags & SYM_CLASS_MASTER) == 0) {
		/*
		 * Not a master class and not a variant => instance data
		 * contains superClass's instance data as its MetaInstance
		 * field.
		 *
		 * Non-variant master classes begin with an empty instance
		 * structure.
		 */
		(void)Sym_Enter(ST_Enter(output, symStrings, tmpName,
					 len+sizeof(OBJ_META_INST_SUFFIX)-1),
				SYM_FIELD,
				instance,
				Type_Struct(superClass->u.class.instance),
				sExpr);
	    }

	    mbase = ObjFigureMessageStart(flags, superClass);

	    /*
	     * If integer 0 not actually used, blow it away.
	     */
	    if (freeI) {
		Expr_Free(iExpr);
	    }
	} else {
	    /*
	     * Top of the object class hierarchy. We do things a bit
	     * differently: the Instance structure starts out empty and the
	     * Base structure is assumed pre-defined.
	     */
	    strcpy(tmpName+len, OBJ_BASE_SUFFIX);
	    base = Sym_Find(ST_Enter(output, symStrings,
				     tmpName, len+sizeof(OBJ_BASE_SUFFIX)-1),
			    SYM_STRUCT,
			    FALSE);

	    if ((base == NULL) || (base->type != SYM_STRUCT)) {
		yywarning("meta-class %i defined without %s structure; using instance structure as base",
			  className, tmpName);
		/*
		 * Make the base and the instance structures the same, for
		 * argument's sake (and to avoid later bugs).
		 */
		base = instance;
	    }
	    mbase = 0;
	}

	/*
	 * Create the enumerated type to hold the methods defined for the
	 * class.
	 */
	strcpy(tmpName+len, geosRelease >= 2 ? OBJ_METHODS_SUFFIX :
	       OBJ_METHODS_SUFFIX_R1);
	methods = Sym_Enter(ST_Enter(output, symStrings,
				     tmpName,
				     len+(geosRelease >= 2 ?
					  sizeof(OBJ_METHODS_SUFFIX) :
					  sizeof(OBJ_METHODS_SUFFIX_R1))-1),
			    SYM_ETYPE, mbase, 1, 2);

	/*
	 * If working on 2.0 or later, create an enumerated type to hold the
	 * vardata tags defined for the class. VarData tags start at the
	 * same value as the Methods type, but they skip by 4 instead of 1.
	 */
	if (geosRelease >= 2) {
	    strcpy(tmpName+len, OBJ_VARDATA_SUFFIX);
	    vardata = Sym_Enter(ST_Enter(output, symStrings,
					 tmpName,
					 len+sizeof(OBJ_VARDATA_SUFFIX)-1),
				SYM_ETYPE, mbase, 4, 2);
	} else {
	    vardata = NullSymbol;
	}

	free(tmpName);
    }
    /*
     * Deal with forward declarations by looking for the symbol first, creating
     * it only if it doesn't already exist.
     */
    class = Sym_Find(className, SYM_CLASS, FALSE);
    if (class == NullSymbol) {
	/*
	 * Create the class symbol itself, now that all the components are
	 * around.
	 */
	class = Sym_Enter(className, SYM_CLASS, superClass, methods, instance,
			  base, vardata, flags);
    } else {
	/*
	 * Set the actual parameters of a forward-declared class.
	 */
	class->segment = curSeg;
	class->u.class.super = superClass;
	class->u.class.instance = instance;
	class->u.class.data->flags = flags;
	class->u.class.data->methods = methods;
	class->u.class.data->vardata = vardata;
	class->u.class.data->base = base;
    }
	
    /*
     * Class not really defined yet; all classes, however, are global.
     */
    class->flags |= SYM_UNDEF|SYM_GLOBAL;

    return(class);
}

/*
 * Type description for a class record
 */
static TypePtr	    classType;

/***********************************************************************
 *				ObjInit
 ***********************************************************************
 * SYNOPSIS:	    Initialize this module.
 * CALLED BY:	    Obj_ functions
 * RETURN:	    Nothing
 * SIDE EFFECTS:    classType is created if not already defined.
 *
 * STRATEGY:
 *	Searches for the symbol "Class" and creates a TYPE_STRUCT for
 *	it.
 *
 *	Note this means the Class type must be defined before any
 *	class is defined.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/17/89		Initial Revision
 *
 ***********************************************************************/
static int
ObjInit(void)
{
    if (classType == NULL) {
	ID  	    classID;
	SymbolPtr   classSym;

	classID = ST_Lookup(output, symStrings,
			    geosRelease>=2 ? OBJ_CLASS_TYPE : OBJ_CLASS_TYPE_R1,
			    (geosRelease>=2 ? sizeof(OBJ_CLASS_TYPE) :
			     sizeof(OBJ_CLASS_TYPE_R1))-1);
	if ((classID == NullID) ||
	    (classSym = Sym_Find(classID, SYM_ANY, FALSE)) == NULL)
	{
	    yyerror("Structure %s must be defined before a class can be defined",
		    geosRelease>=2 ? OBJ_CLASS_TYPE : OBJ_CLASS_TYPE_R1);
	    return 0;
	}
	
	classType = Type_Struct(classSym);
    }
    return(1);
}

/***********************************************************************
 *				ObjSetBit
 ***********************************************************************
 * SYNOPSIS:	    Set a bit in a byte of a class record
 * CALLED BY:	    INTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The bit in the byte at the offset from the start of
 *	    	    the class record is set.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/20/90		Initial Revision
 *
 ***********************************************************************/
static void
ObjSetBit(SymbolPtr 	class,
	  byte	    	bit,
	  int	    	offset)
{
    Table   	code = class->segment->u.segment.code;
    byte    	b;

    Table_Fetch(code, 1, (void *)&b, class->u.addrsym.offset + offset);

    b |= bit;

    Table_Store(code, 1, (void *)&b, class->u.addrsym.offset + offset);
}


/***********************************************************************
 *				Obj_EnterDefault
 ***********************************************************************
 * SYNOPSIS:	    Adjust the class record to contain a default method
 *	    	    handler. This involves setting the CLASSF_HAS_DEFAULT
 *	    	    flag and inserting four bytes for a pointer to the
 *	    	    routine just before the class record.
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The class record shifts forward four bytes.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/15/89	Initial Revision
 *
 ***********************************************************************/
void
Obj_EnterDefault(SymbolPtr  class,  	/* Class to adjust */
		 SymbolPtr  handler,	/* Handler procedure itself */
		 Expr	    *expr,  	/* Expression for generating
					 * fixup for handler pointer */
		 int	    callType)	/* How handler may be called */
{
    Table   	code;	    	/* Table holding class record */
    ID	    	conflict;   	/* Procedure already bound */
    int	    	handlerOffset;	/* Place to store handler pointer */

    if (!ObjInit()) {
	return;
    }

    /*
     * Make sure class record is defined in this assembly.
     */
    if (class->flags & SYM_UNDEF) {
	yyerror("cannot define default message handler for %i as %i's class record is not defined yet",
		class->name, class->name);
	return;
    }
    /*
     * The NULL method is what we use to indicate the presence of a default
     * method handler for a class.
     */
    conflict = Sym_BindMethod(class, NullID, handler, callType);
    if (conflict != NullID) {
	yyerror("default method already bound to %i for %i",
		conflict, class->name);
	return;
    }

    /*
     * If method flagged as dynamic, do not permit jumps or calls to it.
     */
    if (callType == OBJ_DYNAMIC) {
	handler->u.proc.flags |= SYM_NO_JMP|SYM_NO_CALL;
    }
    
    code = class->segment->u.segment.code;

    /*
     * Set the HAS_DEFAULT flag for the class.
     */
    ObjSetBit(class, CLASSF_HAS_DEFAULT,
	      (geosRelease >= 2 ? offsetof(Class, Class_flags) :
	       offsetof(Class_rel1, Class_flags)));

    /*
     * Make room for the default routine before the class record, adjusting all
     * fixups and symbols accordingly.
     */
    handlerOffset = class->u.addrsym.offset;
    Table_Insert(code, class->u.addrsym.offset, 4);
    Fix_Adjust(class->segment, class->u.addrsym.offset, 4);
    Sym_Adjust(class->segment, class->u.addrsym.offset, 4);

    /*
     * Switch to the class's segment and enter the default handler's address
     * in the space made for it. We use Data_Enter b/c it's the simplest
     * thing to do.
     */
    PushSegment(class->segment);
    (void)ObjDataEnter(&handlerOffset, ObjFetchHandlerType(), expr, 1);

    /*
     * Deal with having the location counter in the area affected by the
     * change.
     */
    if (dot >= handlerOffset-4) {
	dot += 4;
    }

    PopSegment();

    handler->u.proc.flags |= SYM_HANDLER;
}


/***********************************************************************
 *				Obj_EnterReloc
 ***********************************************************************
 * SYNOPSIS:	    Adjust the class record to contain a relocation
 *	    	    routine. This involves setting the CLASSF_HAS_RELOC
 *	    	    flag and inserting four bytes for a pointer to the
 *	    	    routine just after the method table, before the
 *	    	    relocation table.
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The relocation record shifts forward four bytes
 *
 * STRATEGY:
 *	XXX: Need to have some way to detect duplicate, but the class
 *	must be declared with the HAS_RELOC flag set so we know not to
 *	form a relocation table for the thing, so we can't use that...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/16/89	Initial Revision
 *
 ***********************************************************************/
void
Obj_EnterReloc(SymbolPtr    class,  	/* Class to adjust */
	       SymbolPtr    handler,	/* Handler procedure itself */
	       Expr	    *expr)  	/* Expression for generating
					 * fixup for handler pointer */
{
    Table   	code;	    	/* Table holding class record */
    byte    	b[2];
    int	    	handlerOffset;	/* Place to store handler pointer */
    word    	count;	    	/* Method count so we know where to store
				 * the pointer */


    if (!ObjInit()) {
	return;
    }

    /*
     * Make sure class record is defined in this assembly.
     */
    if (class->flags & SYM_UNDEF) {
	yyerror("cannot define relocation message handler for %i as %i's class record is not defined yet",
		class->name, class->name);
	return;
    }

    /*
     * Set the HAS_RELOC flag for the class.
     */
    code = class->segment->u.segment.code;
    ObjSetBit(class, CLASSF_HAS_RELOC,
	      (geosRelease >= 2 ? offsetof(Class, Class_flags) :
	       offsetof(Class_rel1, Class_flags)));

    /*
     * Fetch the number of methods currently bound for the class.
     */
    Table_Fetch(code, 2, (void *)b,
		class->u.addrsym.offset +
		(geosRelease >= 2 ? offsetof(Class, Class_methodCount) :
		 offsetof(Class_rel1, Class_methodCount)));

    count = b[0] | (b[1] << 8);

    /*
     * Make room for the relocation routine after the class record and message
     * tables, adjusting all fixups and symbols accordingly.
     */
    handlerOffset = class->u.addrsym.offset +
	(geosRelease >= 2 ? sizeof(Class) : sizeof(Class_rel1)) + (count * 6);
    Table_Insert(code, handlerOffset, 4);
    Fix_Adjust(class->segment, handlerOffset, 4);
    Sym_Adjust(class->segment, handlerOffset, 4);

    /*
     * Switch to the class's segment and enter the reloc handler's address
     * in the space made for it. We use Data_Enter b/c it's the simplest
     * thing to do.
     */
    PushSegment(class->segment);
    (void)ObjDataEnter(&handlerOffset, ObjFetchHandlerType(), expr, 1);

    /*
     * Deal with having the location counter in the area affected by the
     * change.
     */
    if (dot >= handlerOffset-4) {
	dot += 4;
    }

    PopSegment();

    handler->u.proc.flags |= SYM_HANDLER;
}


/***********************************************************************
 *				Obj_EnterHandler
 ***********************************************************************
 * SYNOPSIS:	    Enter another method handler for a class
 * CALLED BY:	    parser
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The method table for the class is enlarged, with
 *	    	    attendant fixups being added and symbols/fixups being
 *	    	    adjusted.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/16/89		Initial Revision
 *
 ***********************************************************************/
void
Obj_EnterHandler(SymbolPtr  	class,	    /* Class for handler */
		 SymbolPtr  	handler,    /* Handler procedure itself */
		 SymbolPtr  	method,	    /* Method being handled */
		 Expr	    	*expr,	    /* Expression for generating
					     * fixup for handler pointer */
		 int	    	callType)   /* How handler may be called */
{
    byte    	    b[2];    	    /* Bytes containing the count */
    word    	    count;  	    /* Method count */
    int	    	    idOffset;	    /* Offset for method ID in table */
    int	    	    handlerOffset;  /* Offset for handler pointer */
    Table   	    code;   	    /* Code table */
    ID	    	    conflict;	    /* Procedure already bound */

    if (!ObjInit()) {
	return;
    }

    /*
     * Make sure class record actually defined in this assembly
     */
    if (class->flags & SYM_UNDEF) {
	yyerror("cannot define message handler for %i as %i's class record is not defined yet",
		class->name, class->name);
	return;
    }
    
    /*
     * Register the binding of handler to method in the given class. If
     * that method is already bound, complain.
     */
    Sym_Reference(method);
    conflict = Sym_BindMethod(class, method->name, handler, callType);
    if (conflict != NullID) {
	yyerror("%i already bound to %i for %i", method->name, conflict,
		class->name);
	return;
    }

    /*
     * Set procedure flags according to callType.
     */
    if (callType == OBJ_DYNAMIC) {
	handler->u.proc.flags |= SYM_NO_JMP|SYM_NO_CALL|SYM_DYNAMIC|SYM_HANDLER;
    } else if (callType == OBJ_PRIVSTATIC) {
	handler->u.proc.flags |= SYM_PRIVSTATIC|SYM_HANDLER;
    } else if (callType == OBJ_STATIC) {
	handler->u.proc.flags |= SYM_STATIC|SYM_HANDLER;
    } else if (callType == OBJ_DYNAMIC_CALLABLE) {
	handler->u.proc.flags |= SYM_HANDLER;
    }
    
    /*
     * Enter the method and procedure in the class's table.
     */
    code = class->segment->u.segment.code;
    Table_Fetch(code, 2, (void *)b,
		class->u.addrsym.offset +
		(geosRelease >= 2 ? offsetof(Class, Class_methodCount) :
		 offsetof(Class_rel1, Class_methodCount)));

    count = b[0] | (b[1] << 8);

#if SORT_METHOD_TABLES
    /*
     * We build the table in ascending order, now, so find the first message
     * number that's greater than this one and insert this one before it.
     */
    idOffset = class->u.addrsym.offset + 
	(geosRelease >= 2 ? sizeof(Class) : sizeof(Class_rel1));

    if (count != 0) {
	int 	i;

	for (i = 0; i < count; i++) {
	    Table_Fetch(code, 2, (void *)b, idOffset + i * 2);
	    if ((b[0] | (b[1] << 8)) > method->u.method.value) {
		break;
	    }
	}
	/*
	 * handlerOffset is same position in handler table, with an extra 2
	 * added to cope with the expanded method ID table.
	 */
	handlerOffset = idOffset + count * 2 + i * 4 + 2;
	/*
	 * Point idOffset to the appropriate place in the table.
	 */
	idOffset += i * 2;
    } else {
	handlerOffset = idOffset + 2;
    }
	
#else
    /*
     * Figure where these things will go (handlerOffset adjusted for expanded
     * method ID table).
     */
    idOffset = class->u.addrsym.offset +
	(geosRelease >= 2 ? sizeof(Class) : sizeof(Class_rel1)) + count * 2;
    handlerOffset = idOffset + 2 + count * 4;
#endif

    /*
     * Up the number of methods by one.
     */
    count += 1;
    b[0] = count;
    b[1] = count >> 8;
    Table_Store(code, 2, (void *)b,
		class->u.addrsym.offset +
		(geosRelease >= 2 ? offsetof(Class, Class_methodCount) :
		 offsetof(Class_rel1, Class_methodCount)));

    /*
     * Make room for the new method ID and insert it. Note that we postpone
     * the adjustment of symbols until after we've installed the handler
     * procedure as well, since there are no symbols w/in the method table.
     * The same delay cannot be applied to fixups, however, as there's one
     * per handler...
     */
    Table_Insert(code, idOffset, 2);
    b[0] = method->u.method.common.value;
    b[1] = method->u.method.common.value >> 8;
    Table_Store(code, 2, (void *)b, idOffset);

    Fix_Adjust(class->segment, idOffset, 2);

    /*
     * Make room for the handler pointer, then enter it using Data_Enter.
     * Data_Enter only operates on curSeg, so "switch" to the class's
     * segment before calling Data_Enter, reverting to the regular segment
     * afterwards.
     */
    Table_Insert(code, handlerOffset, 4);
    Fix_Adjust(class->segment, handlerOffset, 4);

    /*
     * Flag the proper master level as having at least one method in the
     * class's table.
     */
    ObjSetBit(class, (1 << ((method->u.method.common.value >> 13) & 0x7)),
	      (geosRelease >= 2 ? offsetof(Class, Class_masterMethods) :
	       offsetof(Class_rel1, Class_masterMethods)));
    

    PushSegment(class->segment);
    
    (void)ObjDataEnter(&handlerOffset, ObjFetchHandlerType(), expr, 1);

    /*
     * Deal with having the location counter in the area affected by
     * the change. See below for the reasons behind handlerOffset-6
     */
    if (dot >= handlerOffset-6) {
	dot += 6;
    }

    PopSegment();

    /*
     * Make cumulative adjustment of all symbols after the method handler
     * table to account for the new handler. (Need to subtract 6 b/c Data_Enter
     * adjusts handlerOffset plus we need th deal with the two bytes
     * inserted for the method number as well.)
     */
    Sym_Adjust(class->segment, handlerOffset-6, 6);
}    

static void ObjFormRelocTable(SymbolPtr tag, ObjNoReloc *noreloc,
			      SymbolPtr field, int offset);

/***********************************************************************
 *				ObjRelocType
 ***********************************************************************
 * SYNOPSIS:	    Create a relocation table entry based on a type
 * CALLED BY:	    ObjFormRelocTable, ObjRelocType
 * RETURN:	    Nothing
 * SIDE EFFECTS:    dot advanced past relocation entry, if any
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 1/89		Initial Revision
 *
 ***********************************************************************/
static void
ObjRelocType(SymbolPtr	tag,	    /* VarData tag for which table is
				     * being built, or NullSymbol if for
				     * instance data */
	     ObjNoReloc	*noreloc,   /* Array of things not to be relocated
				     * for this class */
	     TypePtr	ftype,	    /* Field type */
	     int    	foff)	    /* Field offset */
{
    byte    b[4];		/* Relocation for storage */
    
    switch(ftype->tn_type) {
	case TYPE_STRUCT:
	    /*
	     * Structured type -- if an actual structure, recurse to
	     * handle things w/in the structure, passing the offset
	     * of the current field as the base for any fields w/in the
	     * nested structure.
	     */
	    if (ftype->tn_u.tn_struct->type == SYM_STRUCT) {
		ObjFormRelocTable(tag,
				  noreloc,
				  ftype->tn_u.tn_struct->u.sType.first,
				  foff);
	    }
	    break;
	case TYPE_ARRAY:
	{
	    /*
	     * Array -- form reloc table for base element and duplicate,
	     * with proper offset adjustments, for the length of the
	     * array.
	     */
	    int 	start;  	/* Offset of first entry for array */
	    TypePtr	base;
	    
	    start = dot;
	    base = ftype->tn_u.tn_array.tn_base;
	    
	    /*
	     * Relocate the base type
	     */
	    ObjRelocType(tag, noreloc, base, foff);

	    if (dot != start) {
		/*
		 * Added relocations. Fetch the bytes added and adjust
		 * the offsets in the relocations for the successive
		 * elements of the array. Doing it this way makes for more
		 * efficient implementation and allows the programmer to just
		 * specify the first element isn't to be relocated and we'll
		 * properly take it to mean the whole array isn't to be
		 * relocated.
		 */
		int 	diff = dot-start;   /* Size of each table piece */
		byte    *buffer;	    /* Buffer for modification */
		int 	j;  	    	    /* Count of table pieces */
		int    	size=Type_Size(base);	/* Diff for offsets in
						 * piece */
		int 	n; 	    	    /* Number of relocations in piece*/

		if (tag != NullSymbol) {
		    n = diff / 4; /* 4-byte entries for VarData */
		} else {
		    n = diff / 3; /* 3-byte entries for instance data */
		}
		
		buffer = (byte *)malloc(diff);

		/*
		 * Fetch the table piece
		 */
		Table_Fetch(curSeg->u.segment.code,
			    diff, (void *)buffer, start);

		for (j = 1; j < ftype->tn_u.tn_array.tn_length; j++) {
		    word    w;	    /* Offset (for arithmetic) */
		    int	    i;	    /* Rels left */
		    byte    *bp;    /* Pointer into buffer */
		    int	    rts;    /* Rel Type Size */

		    rts = (tag == NullSymbol) ? 1 : 2;
		    
		    for (i = n, bp = buffer; i > 0; i--) {
			bp += rts;
			w = *bp | (bp[1] << 8);
			w += size;
			*bp++ = w;
			*bp++ = w >> 8;
		    }

		    /*
		     * Store another copy and advance dot to match.
		     */
		    Table_Store(curSeg->u.segment.code,
				diff, (void *)buffer, dot);
		    dot += diff;
		}
		free((void *)buffer);
	    }
	    break;
	}
	case TYPE_PTR:
	{
	    int     	doReloc = 0;
	    
	    /*
	     * Make sure the user hasn't specified that this field is not
	     * to be relocated. We need to do this early so adjustments to
	     * foff in the switch below don't mess things up.
	     */
	    if (noreloc != NULL) {
		ObjNoReloc	*onr;

		for (onr = noreloc; onr->tag != ONR_LAST; onr++) {
		    if ((onr->tag == tag) && (onr->offset == foff)) {
			return;
		    }
		}
	    }
	    
	    switch(ftype->tn_u.tn_ptr.tn_ptrtype) {
		case TYPE_PTR_OBJ:
		    /*
		     * Wants to be a handle relocation, not a double-word
		     * relocation. The handle is at foff+2, however.
		     */
		    b[0] = RELOC_HANDLE;
		    foff += 2;
		    doReloc = 1;
		    break;
	        case TYPE_PTR_VIRTUAL:
		case TYPE_PTR_FAR:
		    /*
		     * Double-word pointer that needs relocation.
		     */
		    b[0] = RELOC_ENTRY_POINT;
		    doReloc = 1;
		    break;
		case TYPE_PTR_HANDLE:
		    /*
		     * Handle that needs relocation
		     */
		    b[0] = RELOC_HANDLE;
		    doReloc = 1;
		    break;
		case TYPE_PTR_SEG:
		    /*
		     * Segment that needs relocation
		     */
		    b[0] = RELOC_SEGMENT;
		    doReloc = 1;
		    break;
	    }
	    
	    if (doReloc) {
		/*
		 * Store the offset in the relocation.
		 */
		if (tag != NullSymbol) {
		    /*
		     * Relocation is for vardata, so set the first word to be
		     * the tag value (has low two bits clear, of course) or'ed
		     * with the relocation type.
		     */
		    b[0] |= tag->u.varData.common.value & 0xff;
		    b[1] = tag->u.varData.common.value >> 8;
		    b[2] = foff & 0xff;
		    b[3] = foff >> 8;
		    /*
		     * Store the relocation away and advance dot to
		     * compensate.
		     */
		    Table_Store(curSeg->u.segment.code, 4, (void *)b, dot);
		    dot += 4;
		} else {
		    /*
		     * Standard object relocation. Type goes in b[0] (already
		     * stored there, of course), and offset goes in the
		     * following word.
		     */
		    b[1] = foff;
		    b[2] = foff >> 8;
		    /*
		     * Store the relocation away and advance dot to
		     * compensate.
		     */
		    Table_Store(curSeg->u.segment.code, 3, (void *)b, dot);
		    dot += 3;
		}
	    }
	    break;
	}
    }
}

/***********************************************************************
 *				ObjFormRelocTable
 ***********************************************************************
 * SYNOPSIS:	    Create the relocation table for a class.
 * CALLED BY:	    Obj_DefineClass, and recursively
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Relocation entries may be added to the current segment
 *	    	    at dot.
 *
 * STRATEGY:
 *	This thing looks through the instance data for four types of
 *	pointers whose values need to be relocated on load and save:
 *	    hptr    	Must be converted from resource ID to handle
 *	    fptr    	Must be converted to proper dword
 *	    sptr    	Must be converted from resource ID to segment
 *	    optr    	Must be converted to proper dword
 *	Any structures contained w/in the structure are processed
 *	recursively.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/17/89		Initial Revision
 *
 ***********************************************************************/
static void
ObjFormRelocTable(SymbolPtr 	tag,	    /* VarData tag for which table
					     * is being built, if any */
		  ObjNoReloc	*noreloc,   /* Things that are not to be
					     * relocated, if any */
		  SymbolPtr 	field,	    /* First field to examine */
		  int	    	offset)     /* Offset from start of instance.
					     * Added to u.field.offset to
					     * obtain offset for entry */
{
    /*
     * Elements of the structure are all linked together with the final
     * element pointing back to the source structure.
     */
    while (field->type != SYM_STRUCT) {
	if (field->type == SYM_FIELD) {
	    ObjRelocType(tag, noreloc, field->u.field.type,
			 offset+field->u.field.offset);
	} else {
	    ObjRelocType(tag, noreloc, field->u.instvar.type,
			 offset+field->u.instvar.offset);
	}
	
	field = field->u.eltsym.next;
    }
}
			

/***********************************************************************
 *				ObjFinishRelocTable
 ***********************************************************************
 * SYNOPSIS:	    Terminate a relocation table, establishing a fixup
 *	    	    for its pointer.
 * CALLED BY:	    Obj_DefineClass
 * RETURN:	    nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 5/91	Initial Revision
 *
 ***********************************************************************/
static void
ObjFinishRelocTable(word    offset,
		    word    cbase,
		    word    ptrOffset)
{
    if (dot != offset) {
	ExprResult  res;
	byte	    b[1];

	/*
	 * Store list terminator, advancing dot.
	 */
	b[0] = RELOC_END_OF_LIST;
	Table_Store(curSeg->u.segment.code, 1, (void *)b, dot);
	dot += 1;
	    
	/*
	 * Create symbol for start of relocation table and enter external
	 * fixup to same in Class_relocTable field.
	 */
	res.rel.sym = Sym_Enter(NullID, SYM_LABEL, offset, TRUE);
	res.rel.size = FIX_SIZE_WORD;
	res.rel.type = FIX_OFFSET;
	res.rel.pcrel = 0;
	res.rel.fixed = 0;
	res.rel.frame = curSeg;
	if (curSeg->segment && curSeg->segment->type == SYM_GROUP) {
	    res.rel.frame = curSeg->segment;
	}
	Fix_Enter(&res, cbase+ptrOffset, cbase+ptrOffset);
    }
}

/***********************************************************************
 *				Obj_DefineClass
 ***********************************************************************
 * SYNOPSIS:	    Define a class record in the current segment
 * CALLED BY:	    parser
 * RETURN:	    Nothing
 * SIDE EFFECTS:    A class record and relocation table are entered
 *	    	    into the segment and dot is advanced.
 *
 * STRATEGY:
 *	Create class record with attendant fixups for superClass and
 *	initRoutine. methodCount initialized to 0. masterOffset gets
 *	sizeof(superBase) where superBase is preceding master class,
 *	whereever it is (0 if no preceding master class).
 *
 *	Relocation table formed by skipping over metaInstance field,
 *	if any, then examining each field in turn for hptr (RELOC_HANDLE),
 *	sptr (RELOC_SEGMENT) or fptr/optr (RELOC_ENTRY_POINT) elements.
 *	This traversal is recursive, to handle nested structures.
 *
 *	If relocation table non-empty, store RELOC_END_OF_LIST, register
 *	final-pass fixup to store the final address of the table (determined
 *	from method count, rather than an anonymous symbol.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/16/89		Initial Revision
 *
 ***********************************************************************/
void
Obj_DefineClass(SymbolPtr   class,  	    /* Class to define */
		Expr	    *flags, 	    /* Optional flags */
		Expr	    *initRoutine)   /* Initialization routine */
{
    SymbolPtr	sym;	    	/* General symbol pointer */
    word    	offset;	    	/* Master offset and dot before creating reloc
				 * table */
    byte    	b[4];	    	/* General-purpose buffer */
    word    	cflags;	    	/* Flags for class as an integer */
    word    	cbase;	    	/* Start of the ClassStruc */

    if (!ObjInit()) {
	return;
    }

    class->segment = curSeg;
    class->flags &= ~SYM_UNDEF;

    /*
     * Set the address for the class symbol (clears SYM_UNDEF)
     */
    Sym_SetAddress(class, dot);
    cbase = dot;

    /*
     * Form up expression for the superclass and store it (we claim the type
     * is fptr.char for simplicity's sake -- all we need is the fptr part)
     */
    if (!class->u.class.super ||
	(class->u.class.data->flags & SYM_CLASS_VARIANT))
    {
	/*
	 * No superclass, or class is variant. If no superclass,
	 * store four bytes of zero. If class is variant, the segment should
	 * be 1, so b[2] is 1...
	 */
	b[0] = b[1] = b[3] = 0;
	b[2] = (class->u.class.data->flags & SYM_CLASS_VARIANT) ? 1 : 0;
	Table_Store(curSeg->u.segment.code, 4, (void *)b, dot);
	dot += 4;
    } else {
	ExprElt	scElts[2];  	/* Elements for storing superClass */
	Expr    scExpr;
	  /*	    2, curFile->name, 0, 0, 0, curProc, {0, 0, 0, 0}, scElts */

	scExpr.numElts = 2;
	scExpr.file = curFile->name;
	scExpr.line = 0;
	scExpr.idents = 0;
	scExpr.musteval = 0;
	scExpr.curProc = curProc;
	scExpr.segments[0] = 0;
	scExpr.segments[1] = 0;
	scExpr.segments[2] = 0;
	scExpr.segments[3] = 0;
	scExpr.elts = scElts;

	scExpr.line = yylineno;

	scElts[0].op = EXPR_SYMOP;
	scElts[1].sym = class->u.class.super;
	if (!ObjDataEnter(&dot, Type_Ptr(TYPE_PTR_FAR,
					 Obj_ClassType(NullSymbol)),
			  &scExpr,1))
	{
	    return;
	}
    }

    /*
     * Find the head of this class's master group, if class is in master
     * group. Loop ends up with sym pointing at master class or at the
     * meta class for the entire hierarchy.
     */
    for (sym = class;
	 !(sym->u.class.data->flags & SYM_CLASS_MASTER) && sym->u.class.super;
	 sym = sym->u.class.super)
    {
	;
    }
    
    if (sym->u.class.data->flags & SYM_CLASS_MASTER) {
	/*
	 * Offset for this master group is simply the size of the base
	 * structure for the master class's super class, since the offset
	 * was added immediately after that structure.
	 */
	offset = sym->u.class.super->u.class.data->base->u.typesym.size;
    } else {
	/*
	 * At meta-class, so this class has no master offset.
	 * XXX: Handle MetaBase w/more than a class ptr (e.g. a master offset?)
	 */
	offset = 0;
    }

    /*
     * Store the offset away -- no fixup needed
     */
    b[0] = offset;
    b[1] = offset >> 8;
    Table_Store(curSeg->u.segment.code, 2, (void *)b, dot);
    dot += 2;
    /*
     * No methods are defined yet, so set method count to 0 -- no fixup needed
     */
    b[0] = b[1] = 0;
    Table_Store(curSeg->u.segment.code, 2, (void *)b, dot);
    dot += 2;
    /*
     * Store the instance size -- no fixup needed.
     */
    b[0] = class->u.class.instance->u.typesym.size;
    b[1] = class->u.class.instance->u.typesym.size >> 8;
    Table_Store(curSeg->u.segment.code, 2, (void *)b, dot);
    dot += 2;

    if (geosRelease >= 2) {
	/*
	 * Store a 0 pointer for the vdRelocTable. If such a table is actually
	 * required, we'll register a fixup to set its address.
	 */
	b[0] = 0;
	b[1] = 0;
	
	Table_Store(curSeg->u.segment.code, 2, (void *)b, dot);
	dot += 2;

	if (initRoutine != NULL) {
	    Notify(NOTIFY_ERROR, initRoutine->file, initRoutine->line,
		   "class-initialization routines are no longer supported");
	}
    } else {
	/*
	 * Store the init routine, if given.
	 */
	if (initRoutine != NULL) {
	    (void)ObjDataEnter(&dot, ObjFetchHandlerType(),
			       initRoutine, 1);
	} else {
	    b[0] = b[1] = b[2] = b[3] = 0;
	    Table_Store(curSeg->u.segment.code, 4, (void *)b, dot);
	    dot += 4;
	}
    }
    
    /*
     * Store zero for the relocTable -- we'll create an external fixup for
     * the thing if the class actually requires a relocation table
     */
    b[0] = b[1] = 0;
    Table_Store(curSeg->u.segment.code, 2, (void *)b, dot);
    dot += 2;
    
    /*
     * Figure the ClassFlags to store.
     */
    if (flags) {
	/*
	 * Expression given for flags (the expression must be constant).
	 */
	ExprResult  res;

	if (!Expr_Eval(flags, &res, EXPR_NOUNDEF|EXPR_FINALIZE, NULL)) {
	    /*
	     * Error in evaluation -- return now
	     */
	    Notify(NOTIFY_ERROR, flags->file, flags->line,
		   (char *)res.type);
	    return;
	}

	/*
	 * Flags must be non-relocatable constants.
	 */
	if ((res.type != EXPR_TYPE_CONST) || res.rel.sym) {
	    Notify(NOTIFY_ERROR, flags->file, flags->line,
		   "Class flags must be constant");
	    return;
	}

	/*
	 * Set initial flags byte to result of eval
	 */
	cflags = res.data.number;
    } else {
	/*
	 * No additional flags set
	 */
	cflags = 0;
    }
    /*
     * Set the CLASS_MASTER and CLASS_VARIANT flags as appropriate.
     */
    if (class->u.class.data->flags & SYM_CLASS_MASTER) {
	cflags |= CLASSF_MASTER_CLASS;
    }
    if (class->u.class.data->flags & SYM_CLASS_VARIANT) {
	cflags |= CLASSF_VARIANT_CLASS;
    }
    b[0] = cflags;
    b[1] = 0;			/* No master levels have methods here yet */

    /*
     * Store the final two bytes of the class record
     */
    Table_Store(curSeg->u.segment.code, 2, (void *)b, dot);
    dot += 2;

    /*
     * Create a relocation table for the class as long as the NEVER_SAVED
     * and HAS_RELOC flags aren't set for the class.
     */
    if ((cflags & (CLASSF_NEVER_SAVED|CLASSF_HAS_RELOC)) == 0) {
	/*
	 * Record current position so we know if any relocations were created.
	 */
	offset = dot;
	
	if (((class->u.class.data->flags &
	      (SYM_CLASS_MASTER|SYM_CLASS_VARIANT)) == SYM_CLASS_MASTER) ||
	    (class->u.class.super == NULL))
	{
	    /*
	     * Class is a master or meta class and *not* variant -- start
	     * relocation search with first field of instance data. For a
	     * variant class, we need to skip the MetaBase structure at
	     * the start, as that is expected to be redone whenever the
	     * object is loaded in.
	     */
	    sym = class->u.class.instance->u.sType.first;
	} else {
	    /*
	     * Skip metaInstance field -- it's taken care of by the
	     * superclass's relocation table.
	     */
	    sym = class->u.class.instance->u.sType.first->u.eltsym.next;
	}
	/*
	 * Traverse instance fields (base offset is 0 since this is the
	 * Instance structure).
	 */
	if (sym != NullSymbol) {
	    ObjFormRelocTable(NullSymbol, (ObjNoReloc *)class->u.class.data->noreloc, sym, 0);
	}
	
	
	ObjFinishRelocTable(offset, cbase,
			    (geosRelease >= 2 ? offsetof(Class, Class_relocTable) :
			     offsetof(Class_rel1, Class_relocTable)));

	/*
	 * Create a relocation table for the variable data as well, if we're
	 * assembling for 2.0 or later.
	 */
	if (geosRelease >= 2) {
	    SymbolPtr	vd;

	    offset = dot;   /* Record start of table so we know if we added
			     * anything */

	    for (vd = class->u.class.data->vardata->u.eType.mems;
		 vd->type == SYM_VARDATA;
		 vd = vd->u.varData.common.common.next)
	    {
		if (vd->u.varData.type) {
		    ObjNoReloc  *onr;
		    
		    /*
		     * Make sure the user hasn't asked us to ignore this
		     * entire vardata tag.
		     */
		    onr = (ObjNoReloc *)class->u.class.data->noreloc;
		    while ((onr != NULL) && (onr->tag != ONR_LAST)) {
			if ((onr->tag == vd) &&
			    (onr->offset == ONR_ENTIRE_VARDATA))
			{
			    break;
			}
			onr++;
		    }

		    if ((onr == NULL) || (onr->tag == ONR_LAST)) {
		       ObjRelocType(vd,
				    (ObjNoReloc *)class->u.class.data->noreloc,
				     vd->u.varData.type,
				     0);
		    }
		}
	    }
	    
	    ObjFinishRelocTable(offset, cbase,
				offsetof(Class, Class_vdRelocTable));
	}
    }
}


/***********************************************************************
 *				Obj_ClassType
 ***********************************************************************
 * SYNOPSIS:	    Return a type description for a class symbol
 * CALLED BY:	    ExprConvertSym
 * RETURN:	    A TypePtr
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/17/89		Initial Revision
 *
 ***********************************************************************/
TypePtr
Obj_ClassType(SymbolPtr	sym)
{
    (void)ObjInit();

    return(classType);
}


/***********************************************************************
 *				Obj_NoReloc
 ***********************************************************************
 * SYNOPSIS:	    Take note of another thing not to be relocated
 *	    	    for this class.
 * CALLED BY:	    yyparse
 * RETURN:	    nothing
 * SIDE EFFECTS:    An ObjNoReloc record is added to the array of same
 *	    	    for the class.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 5/91	Initial Revision
 *
 ***********************************************************************/
void
Obj_NoReloc(SymbolPtr	class,	    /* Class for which this is defined */
	    SymbolPtr	varData,    /* VarData tag, or NullSymbol if for
				     * instance data */
	    Expr    	*expr)	    /* Expression giving the offset, or NULL if
				     * entire tag data should not be relocated
				     */
{
    ExprResult	res;
    int	    	i;

    /*
     * Determine the offset at which no relocation is to take place.
     */
    if (expr != NULL) {
	if (!Expr_Eval(expr, &res, EXPR_NOUNDEF|EXPR_FINALIZE, NULL)) {
	    /*
	     * Error in evaluation -- return now
	     */
	    Notify(NOTIFY_ERROR, expr->file, expr->line,
		   (char *)res.type);
	    return;
	}
    
	/*
	 * Offset must be non-relocatable constant (it's a structure field or
	 * instance variable, after all.
	 */
	if ((res.type != EXPR_TYPE_CONST) || res.rel.sym) {
	    if (varData == NullSymbol) {
		Notify(NOTIFY_ERROR, expr->file, expr->line,
		       "noreloc argument must be an already-defined instance variable");
	    } else {
		Notify(NOTIFY_ERROR, expr->file, expr->line,
		       "noreloc argument must be a field within the data bound to %i",
		       varData->name);
	    }
	    return;
	}
    } else {
	/*
	 * Flag entire data type as off-limits.
	 */
	res.data.number = ONR_ENTIRE_VARDATA;
    }

    /*
     * Enlarge/allocate the array of ObjNoReloc structures for the class. We
     * always allocate an extra one so we've room to store our sentinel.
     */
    if (class->u.class.data->noreloc == NULL) {
	class->u.class.data->noreloc = (Opaque)malloc(2*sizeof(ObjNoReloc));
	i = 0;
    } else {
	/*
	 * Count how many we've got.
	 */
	for (i = 0; ((ObjNoReloc *)class->u.class.data->noreloc)[i].tag != ONR_LAST; i++) {
	    ;
	}
	class->u.class.data->noreloc =
	    (Opaque)realloc(class->u.class.data->noreloc,
			    (i+2)*sizeof(ObjNoReloc));
    }
    ((ObjNoReloc *)class->u.class.data->noreloc)[i].tag = varData;
    ((ObjNoReloc *)class->u.class.data->noreloc)[i].offset = res.data.number;
    
    /*
     * Set sentinel in last entry.
     */
    ((ObjNoReloc *)class->u.class.data->noreloc)[i+1].tag = ONR_LAST;
}
	

/***********************************************************************
 *				Obj_ExportMessages
 ***********************************************************************
 * SYNOPSIS:	    Export a range of messages from the passed class.
 * CALLED BY:	    yyparse
 * RETURN:	    nothing
 * SIDE EFFECTS:    this'n'that
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 6/91	Initial Revision
 *
 ***********************************************************************/
void
Obj_ExportMessages(SymbolPtr    class,	    /* Class from which to export it */
		   ID	    	rangeName,  /* Name for the exported range */
		   Expr	    	*length)    /* Number of messages to export */
{
    ExprResult	res;

    if (!Expr_Eval(length, &res, EXPR_NOUNDEF|EXPR_FINALIZE, NULL)) {
	/*
	 * Error in evaluation -- return now
	 */
	Notify(NOTIFY_ERROR, length->file, length->line,
	       (char *)res.type);
	return;
    }
    
    /*
     * Offset must be non-relocatable constant (it's a structure field or
     * instance variable, after all.
     */
    if ((res.type != EXPR_TYPE_CONST) || res.rel.sym) {
	Notify(NOTIFY_ERROR, length->file, length->line,
	       "the number of messages to be exported in the %i range must be a constant",
	       rangeName);
	return;
    }

    /*
     * Create a message symbol in the enumerated type, marking it as an exported
     * range. Such a symbol will never be returned by Sym_Find unless
     * SYM_METHOD is passed as the type being sought. How convenient.
     */
    (void) Sym_Enter(rangeName, SYM_METHOD, class,
		     SYM_METH_RANGE |
		     (res.data.number << SYM_METH_RANGE_LENGTH_OFFSET));

    /*
     * Up the Methods type nextVal by the number of messages to be exported,
     * minus 1 to account for the increment already applied by our having
     * defined the symbol.
     */
    class->u.class.data->methods->u.eType.nextVal += res.data.number-1;
}


/***********************************************************************
 *				ObjCheckETypeBounds
 ***********************************************************************
 * SYNOPSIS:	    Make sure the next value to be defined for the
 *	    	    given enumerated type doesn't extend beyond the
 *	    	    bounds set for the given class.
 * CALLED BY:	    Obj_CheckMessageBounds, Obj_CheckVarDataBounds
 * RETURN:	    nothing
 * SIDE EFFECTS:    error message produced if beyond bounds
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 7/91	Initial Revision
 *
 ***********************************************************************/
static void
ObjCheckETypeBounds(SymbolPtr	    etype,
		    SymbolPtr	    class,
		    char    	    *typeName)
{
    int	    limit;

    /*
     * The limit for the passed class is the start of the next class, so just
     * pretend we want the start for a non-master subclass of this one...
     */
    limit = ObjFigureMessageStart(0, class);

    if (etype->u.eType.nextVal >= limit) {
	yyerror("%s beyond range of numbers allocated to %i",
		typeName, class->name);
    }
}


/***********************************************************************
 *				Obj_CheckMessageBounds
 ***********************************************************************
 * SYNOPSIS:	    Make sure the definition of this message
 *	    	    doesn't go beyond the bounds for the class.
 * CALLED BY:	    yyparse
 * RETURN:	    nothing
 * SIDE EFFECTS:    error message produced if message about to be
 *	    	    created extends beyond the bounds allotted for the class
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 7/91	Initial Revision
 *
 ***********************************************************************/
void
Obj_CheckMessageBounds(SymbolPtr    class)
{
    ObjCheckETypeBounds(class->u.class.data->methods, class, "message");
}


/***********************************************************************
 *				Obj_CheckVarDataBounds
 ***********************************************************************
 * SYNOPSIS:	    Make sure the definition of this VarData type
 *	    	    doesn't go beyond the bounds for the class.
 * CALLED BY:	    yyparse
 * RETURN:	    nothing
 * SIDE EFFECTS:    error message produced if VarData type about to be
 *	    	    created extends beyond the bounds allotted for the class
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 7/91	Initial Revision
 *
 ***********************************************************************/
void
Obj_CheckVarDataBounds(SymbolPtr    class)
{
    ObjCheckETypeBounds(class->u.class.data->vardata, class, "vardata");
}
