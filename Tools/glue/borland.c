/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  borland.c
 * FILE:	  borland.c
 *
 * AUTHOR:  	  Adam de Boor: Dec 17, 1991
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/17/91  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for linking an Intel/Microsoft object file containing
 *	Borland-format symbolic information.
 *
 *	Strategy:
 *
 *	Our basic strategy is to enter symbols in their proper location
 *	as we encounter them, but not to enter them in their hash table
 *	until we've processed the whole file, as they might move (we don't
 *	get address-bearing symbols in ascending order, necessarily).
 *
 *	We also cannot enter types until the end, as type descriptions can
 *	reference types that aren't defined yet. Instead, we store the type
 *	index (unless it can be easily determined what it should be (e.g.
 *	for predefined types)) in the usual type word and run through
 *	all the symbols when we're done, converting indices to their actual
 *	VM-file type descriptions.
 *
 *	There are a number of different records we need to deal with:
 *	    PUBDEF  	Create an address-bearing symbol with the given
 *	    	    	name but unknown class or type in the proper position
 *			in the record's segment's symbol table for each
 *			entry in the record. Save the address of the last
 *			symbol so created. If blockstart symbol at same
 *	    	    	address, overwrite it.
 *	    EXTDEF  	Create an undefined symbol with the given name but
 *	    	    	unknown class or type in a block appropriate for
 *	    	    	the segment for each entry in the record. Save the
 *			address of the last symbol so created.
 *	    BCC_EXTERNAL_TYPE
 *	    	    	Set the index into the address-symbol-type field
 *	    	    	of the last-created external symbol.
 *	    BCC_PUBLIC_TYPE
 *	    	    	Set the index into the address-symbol-type field
 *	    	    	of the last-created external symbol.
 *	    BCC_STRUCT_MEMBERS
 *	    	    	If first such record, create a STRUCT symbol in
 *	    	    	the current or global scope. Create and link
 *	    	    	symbols for all the fields, setting the type to
 *			the indicated index.
 *	    	    	Set the offsets for all fields to -1, unless a
 *	    	    	new-offset "member" is found in the record, in which
 *	    	    	case set the next-created field symbol's offset to
 *	    	    	that offset (requires static variable set to -1
 *			normally, but set to new-offset so it carries across
 *	    	    	BCC_STRUCT_MEMBERS records, then set to -1 after
 *	    	    	each real field).
 *	    	    	(3.0) need to save the beast around. can perform
 *			same processing as for 2.0, actually, but need to
 *			save the block in a list, along with the "index" of
 *			the first field in the block, where each enum member,
 *			and struct member (including "new offset" members)
 *	    	    	count as 1, and the index is 1-origin.
 *	    BCC_TYPEDEF
 *	    	    	Convert the type descriptor and store in its
 *			alloted place in the bTypes vector, if possible
 *			to convert fully. Else mark as unconverted and
 *			save the object record away.
 *	    BCC_ENUM_MEMBERS
 *	    	    	If first such record, create an ETYPE symbol in the
 *			current or global scope. Create and link symbols for
 *			all the members, setting their values, etc.
 *	    	    	(3.0) need to save the beast around. can perform
 *			same processing as for 2.0, actually, but need to
 *			save the block in a list, along with the "index" of
 *			the first field in the block, where each enum member,
 *			and struct member (including "new offset" members)
 *	    	    	count as 1, and the index is 1-origin.
 *	    BCC_BEGIN_SCOPE
 *	    	    	if the scope stack is empty:
 *	    	    	    look for OSYM_PROC at same address. create
 *	    	    	    OSYM_PROC if none
 *	    	    	    push whichever
 *	    	    	else if the scope stack holds 1 entry:
 *	    	    	    create a ??START symbol at this scope's address,
 *	    	    	    then push the first scope again.
 *	    	    	else
 *	    	    	    create a BLOCKSTART symbol at the proper place
 *	    	    	    in the symbol block (after all local syms
 *	    	    	    following scope symbol that comes before this
 *	    	    	    one) and push its offset onto the scope stack
 *	    BCC_LOCALS
 *	    	    	    Process each symbol in the record, creating
 *			    partial symbols, as usual, storing the type
 *	    	    	    index in the place of a normal type and linking
 *			    the symbols to the nearest scope. If there is
 *	    	    	    no nearest scope, create file-global symbols
 *	    	    	    instead of local ones.
 *
 *	    BCC_END_SCOPE   If the top scope is a BLOCKSTART, add a
 *	    	    	    BLOCKEND after it in its scope, else do nothing
 *	    	    	    but pop the scope stack.
 *
 *	    BCC_SOURCE_FILE Record or locate the name of the current source
 *			    file for Pass1MS_Load to use in entering
 *	    	    	    line number information.
 *
 *	    BCC_DEPENDENCY  We only deal with the first of these to know
 *			    it's a file that uses Borland-format symbol
 *			    information.
 *
 *	    BCC_COMPILER_DESC
 *	    	    	    Remember BCDF_UNDERSCORES to decide whether to
 *	    	    	    enter symbols under their official name, or
 *	    	    	    with the initial underscore removed.
 *
 *	    BCC_EXTERNAL_BY_NAME
 *	    	    	    Similar to BCC_EXTERNAL_TYPE, except we have to
 *	    	    	    go looking through all the external symbols defined
 *	    	    	    so far to locate the one whose name matches the
 *			    element of the record we're processing then.
 *			    Otherwise the handling is the same.
 *
 *	    BCC_PUBLIC_BY_NAME
 *	    	    	    Similar to BCC_PUBLIC_TYPE, except we have to
 *	    	    	    go looking through all the public symbols defined
 *	    	    	    so far to locate the one whose name matches the
 *			    element of the record we're processing then.
 *			    Otherwise the handling is the same.
 *
 *	    BCC_VERSION
 *	    	    	    Record version number, so we know whether we need
 *			    to do the 3.0 stuff.
 *	    	    	
 *	When inserting address-bearing symbol, need to check scope stack
 *	and adjust offsets for any symbols in the stack in the same block
 *	after the insertion point.
 *
 *	When creating a PROC or other address-bearing symbol, if there's
 *	a PROC symbol already at the given address, it means we got a
 *	BEGIN_SCOPE for that address when no other scope was active; just
 *	overwrite the appropriate parts of the symbol.
 *
 * DATA STRUCTURES NEEDED:
 *	Need a vector to track source-file IDs
 *
 *	Vector to track type descriptions (initialized to predefined types)
 *	    - for each type, need to know if it's been converted yet
 *	    - if it has been converted, need to know its short form, if any
 *	    - if no short form, need to know that, and its long form. this
 *	      is made more difficult by array long-forms sometimes requiring
 *	      multiple ObjType structures to hold them, if their bounds go
 *	      beyond 16383 elements.
 *	    - always store the type index where a short-form would go in
 *	      an ObjType record.
 *	    - only one Borland type record contains more than 10 bytes
 *	      of data (BTID_SPECIALFUNC) and we don't handle it anyway.
 *
 *	For each segment, need symbol & type block for:
 *	    - defined address-bearing & local symbols, the address-bearing
 *	      ones to be passed to Sym_Enter once their types are known
 *	    - defined non-address symbols (must be entered specially to
 *	      get type-checking between modules)
 *	    - external symbols, to be passed to Sym_EnterUndef once
 *	      their types are known
 *
 * RANDOM NOTES:
 *	procedure symbols have their type index stored in proc.flags, which
 *	just happens to overlap variable.type, until Borland_Finish gets
 * 	to them.
 *
 *	There's only one thing for external undefined symbols, not one per
 *	segment as the comments above imply, as there is no segment
 *	information passed in the MO_EXTDEF record.
 *
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: borland.c,v 1.33 95/11/08 17:22:49 adam Exp $";
#endif lint

#include    "glue.h"
#include    "borland.h"
#include    "msobj.h"
#include    "obj.h"
#include    "sym.h"
#include    <objfmt.h>

#define BORLAND_INIT_SYMS   256	    	/* Initial number of symbols to allocate
					 * in a new symbol block */
#define BORLAND_INCR_SYMS   128	    	/* Number of symbols to add to a block
					 * when it gets too small but ain't up
					 * to capacity yet */

#define BORLAND_FIRST_MEMBER	(sizeof(ObjSymHeader) + sizeof(ObjSym))

#define BT_MAX_TYPE_LEN	    12		/* The most # bytes in a type
					 * description from the object
					 * file */
/*
 * The stack of current local-variable scopes.
 */
#define BORLAND_MAX_SCOPE   30	    	/* Greatest scope depth we can
					 * handle */

typedef struct {
    VMPtr   	scope;	    	    /* The scope symbol itself */
    word    	segIndex;   	    /* Index of the segment to which it
				     * belongs */
    word    	lastLocal;  	    /* Offset of last local symbol entered
				     * into the scope */
} BorlandScope;



static BorlandScope scopeStack[BORLAND_MAX_SCOPE];
static int    	    scopeTop;	/* Next entry to use in scopeStack (i.e. 0 =>
				 * stack is empty) */
static int  	    scopeNum;	/* Counter for scopes in the current procedure;
				 * used when manufacturing names for the scopes
				 */
/*
 * Element in the borlandTypes vector.
 */
typedef struct {
    word    shortType;	    /* Word to use when this type is referenced,
			     * if it fits in a word. This is 0 if the type
			     * hasn't been converted yet, has bit 1
			     * (OTYPE_SPECIAL) set if it has and it fits
			     * in a word, or non-zero with bit 1 clear if
			     * it requires an ObjType descriptor */
#define BORLAND_CONVERTED_LONG_TYPE 2	/* Value stored in shortType when
					 * descriptor has been converted into
					 * an ObjType */
    word    size;   	    /* Size of the type, in bytes */
    ObjType ot;	    	    /* Long-form, once converted, if it'll fit.
			     * Most things will, but arrays with a length
			     * that's greater than 16383 will not fit in a
			     * single ObjType descriptor. Where normally
			     * one would use a word to describe the base
			     * type (for a pointer or array), we store
			     * the index of that type instead. */
    byte    desc[BT_MAX_TYPE_LEN];  /* The raw bytes of the type description
				     * from the object file, from the
				     * BTID constant on. */
} BorlandType;
/* NOTES:
 *	if type is unconverted and desc[0] is:
 *	    BTID_NEAR, BTID_FAR, or BTID_SEG, ot.words[0] is the proper
 *	    	word for the converted pointer-type; the index for the base
 *	    	type must still be extracted from &desc[1]
 *	    BTID_STRUCT, BTID_UNION, BTID_ENUM, BTID_PENUM, ot.words[0] is
 *	    	the block offset, and ot.words[1] the VMBlockHandle, of the
 *	    	symbol that contains the name to be used once the type has
 *	    	been converted; the first symbol in the block is always the
 *	    	type whose field-types must be converted when the object
 *	    	file has been fully read, though ot.words[0] may not be the
 *	    	offset of this symbol.
 */


static Vector	borlandTypes = NullVector;

/*
 * Element in the borlandSegs vector, to keep track of unresolved symbols, etc.,
 * for each segment in the current object file.
 */
typedef struct {
    VMBlockHandle   addrH;  	/* First block of unresolved address symbols */
    VMBlockHandle   addrT;  	/* Last block of unresolved address symbols */
} BorlandSegData;

static Vector	borlandSegs = NullVector;

/*
 * Vector of source file names (IDs) as they've been encountered.
 */
static Vector	borlandSources = NullVector;

/*
 * Vector of procedure-local static variables whose symbols may need to be
 * adjusted as symbols are added to the block holding the variables
 * themselves.
 */
typedef struct {
    VMPtr   	    local;  	    /* The LOCAL_STATIC symbol that points to
				     * the thing. */
    word    	    varOffset;	    /* The offset of the VAR symbol in its
				     * block */
    VMBlockHandle   varBlock;	    /* The block of address symbols in which
				     * the VAR symbol resides */
} BorlandLocalStatic;

static Vector	borlandLocalStatics = NullVector;

/*
 * Non-zero if compiler added underscores to the front of all global
 * symbols, so we need to remove them.
 */
static byte	borlandUnderscores = 0;

/*
 * Major version number of the information we're seeing. We assume 2.x until
 * proven otherwise. For 3.1, Borland's introduced "Browser Information", which
 * we'll gladly skip over if we're dealing with that format.
 */
static byte 	borlandMajorVersion = 2;
static byte 	borlandMinorVersion = 0;


/*
 * The most-recently-seen PUBDEF and EXTDEF symbols, for handling
 * BCC_PUBLIC_TYPE and BCC_EXTERNAL_TYPE
 *
 * lastExternal serves also to tell us the place to stick the next
 * external we seem since they all go in a single block.
 */
static VMPtr	lastPublic = NullVMPtr;
static VMPtr	lastExternal = NullVMPtr;

/*
 * Variables for creating type symbols, all of which get put in the global
 * segment.
 */
static VMBlockHandle   	sTypes;	    	/* Head of structured-type symbols
					 * chain; one block is allocated per
					 * complex type */
static VMBlockHandle   	others;	    	/* Block holding the other symbols
					 * things like typedefs and the like */
static int    	    	seuNext=0;    	/* Next available slot in sTypes when
					 * building up a struct/union/enum
					 * symbol. 0 if not building such a
					 * beast, yet */
static word    	    	suNextOff=-1;	/* Offset for next struct/union field;
					 * usually -1, to indicate it must be
					 * resolved when all the other types are
					 * in, but will be set to something else
					 * if a "new offset" member comes in */
static int  	    	seuStartInd=1;	/* Index of first member of this type */
static int  	    	seuCurIndex=1;	/* Index of next member to be seen */

/*
 * Structure for tracking the struct/enum/union members we see in 3.x so we
 * can resolve those pesky struct/enum/union types at the end of the file.
 */
typedef struct {
    VMBlockHandle   members;	    /* Block holding the members */
    int	    	    start;	    /* Index of the first member in the block */
} BorlandMembers;

static Vector	    borlandMembers = NullVector;


/***********************************************************************
 *				BorlandGetSegData
 ***********************************************************************
 * SYNOPSIS:	    Point to the segment data for the passed segment
 *	    	    number. Note that any addition to the borlandSegs
 *	    	    vector will invalidate the pointer returned.
 * CALLED BY:	    INTERNAL
 * RETURN:	    BorlandSegData * for the segment, 0-initialized if
 *	    	    not there before.
 * SIDE EFFECTS:    Any previously-returned pointer will be nuked if the
 *	    	    passed segment wasn't in the vector before.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/20/91	Initial Revision
 *
 ***********************************************************************/
static BorlandSegData *
BorlandGetSegData(int	index)
{
    BorlandSegData  *retval;

    assert(index != 0);

    /*
     * Make sure we've data for this segment in our private vector.
     */
    if (Vector_Length(borlandSegs) <= index) {
	/*
	 * Not there, so add a zero-initialized element to the vector at
	 * this position.
	 */
	BorlandSegData	newData;

	bzero(&newData, sizeof(newData));
	Vector_Add(borlandSegs, index, (Address)&newData);
    }

    /*
     * Fetch the pointer to the vector's data and calculate the actual
     * element the caller should play with.
     */
    retval = (BorlandSegData *)Vector_Data(borlandSegs);
    return (retval+index);
}


/***********************************************************************
 *				BorlandGetTypeData
 ***********************************************************************
 * SYNOPSIS:	    Return a pointer to the BorlandType record for a
 *	    	    particular index.
 * CALLED BY:	    INTERNAL
 * RETURN:	    BorlandType *
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 3/92		Initial Revision
 *
 ***********************************************************************/
static BorlandType *
BorlandGetTypeData(word	index)
{
    assert(index < Vector_Length(borlandTypes));

    return(((BorlandType *)Vector_Data(borlandTypes))+index);
}


/***********************************************************************
 *				BorlandAllocAndInitSymBlock
 ***********************************************************************
 * SYNOPSIS:	    Allocate a new symbol block in the symbols file and
 *	    	    initialize it appropriately.
 * CALLED BY:	    INTERNAL (BorlandEnterAddressSymbol,
 *	    	    BorlandProcessExternal, ...
 * RETURN:	    VM block handle of new block (not locked)
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/31/91	Initial Revision
 *
 ***********************************************************************/
static VMBlockHandle
BorlandAllocAndInitSymBlock(void)
{
    VMBlockHandle   block = VMAlloc(symbols,
				    sizeof(ObjSymHeader) +
				    BORLAND_INIT_SYMS * sizeof(ObjSym),
				    OID_SYM_BLOCK);
    ObjSymHeader    *osh;

    osh = (ObjSymHeader *)VMLock(symbols, block, (MemHandle *)NULL);
    osh->next = 0;  /* No next symbol block... yet */
    osh->types = 0; /* Type block allocated when symbols resolved */
    osh->seg = 0;   /* Address of last symbol in block initialized to 0 */
    osh->num = 0;   /* No symbols entered yet */

    VMUnlockDirty(symbols, block);

    return(block);
}
    

/***********************************************************************
 *				BorlandEnterAddressSymbol
 ***********************************************************************
 * SYNOPSIS:	    Enter an address-bearing symbol into the chain of
 *	    	    unresolved symbols for the given segment.
 * CALLED BY:	    BorlandProcessPublic, BorlandProcessBeginScope,
 *	    	    BorlandProcessLocal
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *	We need to locate the block in which to place this symbol. Our
 *	block chain contains the unrelocated offset of the last address
 *	symbol in the block stored in osh->seg, so we keep looking down
 *	the chain until we find a block whose osh->seg is greater than
 *	our symbol's offset, or we run out of blocks.
 *
 *	If the block we found is too full, we go to the next one, creating
 *	it if necessary, unless there's a nameless symbol at the same
 *	address as our public one, in which case we'll take that symbol's
 *	place so the size doesn't matter.
 *
 *	Find the place within the chosen block for inserting the new
 *	symbol and do so.
 *
 *	Set the new symbol to have the correct name and offset and be
 *	marked OSYM_UNKNOWN and OSYM_GLOBAL
 *
 *	Update osh->seg if necessary.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/20/91	Initial Revision
 *
 ***********************************************************************/
static VMPtr
BorlandEnterAddressSymbol(ID	    	    id,	       /* Name of new sym */
			  word	    	    offset,    /* Unrelocated offset */
			  byte	    	    symType,   /* Symbol type */
			  byte	    	    symFlags,  /* Flags for symbol */
			  BorlandSegData    *sData)    /* Our data for the
						        * segment in which the
						        * symbol resides */
{
    int	    	    i;
    ObjSymHeader    *osh;
    ObjSym    	    *os;
    MemHandle	    mem;
    int	    	    need;
    word    	    size;
    VMPtr   	    retval;
    VMBlockHandle   block;
    int	    	    replace = FALSE;

    if (sData->addrH == 0) {
	/*
	 * No blocks allocated for this segment yet, so allocate the first
	 * and use it for this new symbol.
	 */
	sData->addrH = sData->addrT = block = BorlandAllocAndInitSymBlock();
	
	osh = (ObjSymHeader *)VMLock(symbols, block, &mem);
	os = ObjFirstEntry(osh,ObjSym);
	i = 0;
    } else {
	VMBlockHandle   next;
	
	/*
	 * Find the block in which this beast should go. We always stop
	 * at the tail, rather than checking its osh->seg, as it's the
	 * block of last-resort :)
	 */
	osh = NULL;
	for (block = sData->addrH; block != sData->addrT; block = next) {
	    osh = (ObjSymHeader *)VMLock(symbols, block, &mem);
	    
	    if (osh->seg < offset) {
		next = osh->next;
		osh = NULL;
		VMUnlock(symbols, block);
	    } else {
		/*
		 * Falls in this block, so break out of the loop with the
		 * beast still locked.
		 */
		break;
	    }
	}
	
	/*
	 * If osh is NULL, then no block had a seg that was <= offset, so
	 * we are free to add a new block to the end if the one chosen
	 * is too big.
	 */
	if (osh == NULL) {
	    osh = (ObjSymHeader *)VMLock(symbols, block, &mem);
	    if ((((osh->num * sizeof(ObjSym)) + sizeof(ObjSymHeader)) >=
		 OBJ_MAX_SYMS) &&
		(scopeTop == 0))
	    {
		/*
		 * Block is filled to capacity and we're not inside a procedure,
		 * so allocate a new one and link it at the end of the chain.
		 */
		sData->addrT =
		    next =
			osh->next = BorlandAllocAndInitSymBlock();
		VMUnlockDirty(symbols, block);
		/*
		 * Lock down the new block.
		 */
		block = next;
		osh = (ObjSymHeader *)VMLock(symbols, block, &mem);
	    }
	}
	
	/*
	 * block = handle of block in which to put the symbol
	 * osh = locked header for same
	 * mem = memory handle for same, if we need to enlarge the block
	 * id = name of the symbol
	 * offset = unrelocated offset of the beast.
	 */
	for (os = ObjFirstEntry(osh,ObjSym), i = osh->num;
	     i > 0;
	     os++, i--)
	{
	    if ((Obj_IsAddrSym(os) || os->type == OSYM_UNKNOWN) &&
		(os->u.addrSym.address >= offset))
	    {
		/*
		 * Found the insertion point (just before the symbol with
		 * the same or greater address).
		 */
		break;
	    }
	}
    }
    
    /*
     * block = handle of block in which to put the symbol
     * osh = locked header for same
     * os = place to insert the symbol
     * mem = memory handle for same, if we need to enlarge the block
     * id = name of the symbol
     * offset = unrelocated offset of the beast.
     */
    need = osh->num + 1;
    if (i != 0) {
	/*
	 * Not putting the symbol at the end of the block, so there might
	 * be a symbol already defined at the same address, having been
	 * put there by a BCC_BEGIN_SCOPE record. Deal with it...
	 */
	if (os->u.addrSym.address == offset) {
	    int first = 1;
	    
	    while ((os->u.addrSym.address == offset) && !replace && i > 0) {
		if (first && os->name == NullID)
		{
		    /* 
		     * this replace is designed to catch procedure starts,
		     * primarily, where the procedure symbol is defined after
		     * the BLOCK_START symbol is entered. In that case we have
		     * to convert the BLOCK_START to a procedure symbol. If
		     * the entered symbol is a BLOCK_END, though, it shouldn't
		     * be replaced.
		     */
		    if (os->type == OSYM_BLOCKEND)
		    {
			os++, i--;
		    	first = 0;
		    }
		    else 
		    {
			replace = TRUE;
			need -= 1;
		    }
		} else if (os->name == id) {
		    /*
		     * Turbo assembler likes to put in a BSC_STATIC symbol
		     * definition for all procedures, even if it's already put
		     * out a PUBDEF for them, so we ignore duplicate definitions
		     * if they are at the same offset and have the same name.
		     */
		    os->flags |= symFlags;
		    retval = MAKE_VMP(block, ObjEntryOffset(os,osh));
		    VMUnlockDirty(symbols, block);
		    return(retval);
		} else if (symType == OSYM_BLOCKSTART && os->type != OSYM_BLOCKEND) {
		    /*
		     * Creating a scope, but there's already a symbol at that
		     * offset; it must be a procedure, so leave it as-is, making
		     * sure we know it's a procedure so its local-variable list
		     * gets updated properly after an insertion.
		     */

		    /* NOTE: it doesn't actually have to be a proceudre as you
		     * can have local variables inside of any set of curly
		     * braces, so if the thing is a ??START symbol then we 
		     * better not call it a OSYM_PROC as glue will die later,
		     * for now I am just checking for LOCL_LABEL, I don't
		     * know that this is the right answe...jimmy 8/93
		     */

		    /* if os->type ==  OSYM_BLOCKSTART then what we have
		     * is two nested scopes with the same offset so
		     * its not actually a procedure so don't screw with
		     * it
		     */

		    if (os->type != OSYM_BLOCKSTART && 
			os->type != OSYM_LOCLABEL)
		    {
			os->type = OSYM_PROC;
		    }

		    retval = MAKE_VMP(block, ObjEntryOffset(os,osh));
		    VMUnlock(symbols, block);
		    return(retval);
		} else {
		    os++, i--;
		    first = 0;
		}
	    }
	}
    }

    /*
     * See if we need to enlarge the block to hold the new symbol.
     */
    VMInfo(symbols, block, &size, (MemHandle *)NULL, (VMID *)NULL);

    if (((need * sizeof(ObjSym)) + sizeof(ObjSymHeader)) > size) {
	/*
	 * Yes. Keep track of os so we can relocate it when the block's
	 * been resized (and possibly moved).
	 */
	int 	osOff = ObjEntryOffset(os, osh);

	MemReAlloc(mem, size + BORLAND_INCR_SYMS * sizeof(ObjSym), 0);

	/*
	 * Relocate osh and os
	 */
	MemInfo(mem, (genptr *)&osh, (word *)NULL);
	os = (ObjSym *)((genptr)osh + osOff);
    }

    /*
     * If we need to insert a symbol here, do so, fixing up the various
     * block-internal pointers and pointers into the block that are messed
     * up by this.
     */
    if ((i != 0) && (need != osh->num)) 
    {
	int 	    	    j;
	BorlandLocalStatic  *bls;
	ObjSym	    	    *tos;
	word	    	    insertOff;
	
	bcopy(os, os+1, i * sizeof(ObjSym));
	os->type = OSYM_UNKNOWN;

	/*
	 * Adjust the offsets of any scope symbols in the scope stack.
	 */
	insertOff = ObjEntryOffset(os,osh);
	
	if (VMP_BLOCK(scopeStack[0].scope) == block) {
	    for (j = 0; j < scopeTop; j++) {
		if (VMP_OFFSET(scopeStack[j].scope) >= insertOff) {
		    scopeStack[j].scope =
			MAKE_VMP(VMP_BLOCK(scopeStack[j].scope),
				 VMP_OFFSET(scopeStack[j].scope)+sizeof(ObjSym));
		}
		if (scopeStack[j].lastLocal >= insertOff) {
		    scopeStack[j].lastLocal += sizeof(ObjSym);
		}
	    }
	}

	/*
	 * Now adjust whatever pointers are in the symbols in the block that
	 * point to or after the insertion point. No need to worry about
	 * structure fields, as they don't reside in address blocks.
	 */
	for (j = osh->num+1, tos = ObjFirstEntry(osh,ObjSym);
	     j > 0;
	     j--, tos++)
	{
	    switch(tos->type) {
		case OSYM_PROC:
		    if (tos->u.proc.local >= insertOff) {
			tos->u.proc.local += sizeof(ObjSym);
		    }
		    break;
		case OSYM_BLOCKSTART:
		    if (tos->u.blockStart.next >= insertOff) {
			tos->u.blockStart.next += sizeof(ObjSym);
		    }
		    if (tos->u.blockStart.local >= insertOff) {
			tos->u.blockStart.local += sizeof(ObjSym);
		    }
		    break;
		case OSYM_LOCLABEL:
		case OSYM_LOCVAR:
		case OSYM_BLOCKEND:
		case OSYM_LOCAL_STATIC:
		case OSYM_REGVAR:
		    if (tos->u.procLocal.next >= insertOff) {
			tos->u.procLocal.next += sizeof(ObjSym);
		    }
		    break;
	    }
	}

	/*
	 * Adjust the offsets of any local-static symbols that point into
	 * this block, as well as the pointers to those symbols in the
	 * borlandLocalStatics vector.
	 */
	for (bls = (BorlandLocalStatic *)Vector_Data(borlandLocalStatics),
	     j = Vector_Length(borlandLocalStatics);

	     j > 0;

	     j--, bls++)
	{
	    if ((VMP_BLOCK(bls->local) == block) &&
		(VMP_OFFSET(bls->local) >= insertOff))
	    {
		bls->local = MAKE_VMP(VMP_BLOCK(bls->local),
				      VMP_OFFSET(bls->local) + sizeof(ObjSym));
	    }
	    
	    if ((bls->varBlock == block) && (bls->varOffset >= insertOff))
	    {
		ObjSym	*lsos;

		lsos = (ObjSym *)VMLockVMPtr(symbols, bls->local,
					     (MemHandle *)NULL);
		lsos->u.localStatic.symOff += sizeof(ObjSym);
		bls->varOffset += sizeof(ObjSym);
		VMUnlockDirty(symbols, VMP_BLOCK(bls->local));
	    }
	}
    } else if (need != osh->num) {
	/*
         * Appending a symbol to the block, so adjust osh->seg appropriately
         */
	osh->seg = offset;
    }

    /*
     * Set the new number of symbols in the block and initialize the symbol
     * properly.
     */
    osh->num = need;

    os->name = id;

    if (!replace) {
	/*
	 * Zero the class-specific data if not replacing a symbol for which
	 * it was already done and for which some of the data might be valid
	 * and important (namely the local-symbol pointer for a procedure)
	 */
	bzero(&os->u, sizeof(os->u));
    }
    os->u.addrSym.address = offset;
    os->flags = symFlags;
    if (!replace || (symType != OSYM_UNKNOWN)) {
	/*
	 * We only set the symbol type when replacing if the passed type
	 * isn't OSYM_UNKNOWN, so as to avoid setting an OSYM_BLOCKSTART
	 * symbol to OSYM_UNKNOWN and causing its local-variable pointer
	 * to not be updated should any symbol be inserted before it in the
	 * block.
	 */
	os->type = symType;
    } else {
	/*
	 * Must be a procedure...set it so it gets processed properly
	 * in BorlandProcessAllPublics
	 */
	assert(os->type == OSYM_BLOCKSTART);
	os->type = OSYM_PROC;
    }
    
    retval = MAKE_VMP(block, ObjEntryOffset(os,osh));
    VMUnlockDirty(symbols, block);

    return(retval);
}
	    

/***********************************************************************
 *				BorlandProcessPublic
 ***********************************************************************
 * SYNOPSIS:	    Process a record of public symbols
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    lastPublic is updated. stuff may be added to the
 *		    borlandSegs vector.
 *
 * STRATEGY:
 *	     - Locate/allocate symbol block for the symbol.
 * 	     - If no symbol at that address, insert one, adjusting
 *	     current scope-stack entries if necessary.
 *	     - Record block/offset of symbol in lastPublic
 *	     - Enter symbol name and set ID as name for symbol.
 *	     - Set OSYM_GLOBAL flag for the symbol
 *	     XXX: can't deal with borlandUnderscores here b/c need to
 *	     enter the name with the underscore and w/o it...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/20/91	Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessPublic(const char *file,
		     byte   	rectype,
		     word   	reclen,
		     byte   	*bp)
{
    SegDesc 	    *sd;
    GroupDesc  	    *gd;
    byte    	    *tbp;
    byte	    *endRecord;
    int	    	    segIndex;
    BorlandSegData  *sdata;
    
    
    /*
     * Figure where this record ends.
     */
    endRecord = bp + reclen;
    
    /*
     * Fetch out the group and segment definitions.
     */
    gd = MSObj_GetGroup(&bp);
    tbp = bp;
    sd = MSObj_GetSegment(&bp);
    segIndex = MSObj_GetIndex(tbp);
    sdata = BorlandGetSegData(segIndex);

    /*
     * XXX: DEAL WITH ABSOLUTE CONSTANTS AND SEGMENTS.
     */
    assert(sd != NULL);
#if 0
    if (sd == NULL) {
	/*
	 * Segment is absolute. Perhaps these things are constants?
	 */
	word    	frame;
	
	MSObj_GetWord(frame, bp);
	
	if (frame == 0) {
	    template.type = symType = OSYM_CONST;
	    sd = globalSeg;
	} else {
	    template.type = symType = OSYM_LABEL;
	    template.u.label.near = FALSE;
	    
	    /* Look for an absolute segment of the same frame,
	     * create one if none existent yet */
	    assert(0);
	}
    }
#endif

    /*
     * Each entry in the record from here-on out contains the name of a
     * symbol (counted string), its unrelocated offset within the segment,
     * and a type index (which we ignore).
     */
    while (bp < endRecord) {
	ID  	id;
	word	offset;
	int 	mangled = 0;

	/*
	 * Store the name, get the offset, and skip the type index.
	 */
	if (borlandUnderscores && bp[1] == '_') {
	    mangled = OSYM_MANGLED;
	}
	id = ST_Enter(symbols, strings, (char *)bp+1, *bp);
	bp += *bp + 1;
	MSObj_GetWord(offset, bp);
	(void)MSObj_GetIndex(bp);

	lastPublic = BorlandEnterAddressSymbol(id, offset, OSYM_UNKNOWN,
					       OSYM_GLOBAL|mangled,
					       sdata);
    }
}


/***********************************************************************
 *			BorlandProcessExternal
 ***********************************************************************
 * SYNOPSIS:	    Process an EXTDEF record
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah
 *
 * STRATEGY:
 *	     - Locate/allocate symbol block for the symbol.
 *	     - Add new symbol to the end of the block.
 *	     - Record block/offset of symbol in lastExternal
 *	     - Enter symbol name and set ID as name for symbol.
 *	     - Set OSYM_GLOBAL|OSYM_UNDEF flags for the symbol
 *	     XXX: can't deal with borlandUnderscores here b/c need to
 *	     enter the name with the underscore and w/o it...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/20/91	Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessExternal(const char *file,
		       byte   	rectype,
		       word   	reclen,
		       byte   	*bp)
{
    /*
     * For each symbol mentioned in here, see if the damn thing
     * exists, and in what segment. If the segment is a library
     * segment, we or MO_EXT_IN_LIB into the external's name to
     * signal that the symbol's in a library.
     */
    ID  	    	name;	    /* name of current external */
    byte	    	*endRecord = bp+reclen;
    ObjSym  	    	*os;
    ObjSymHeader    	*osh;
    VMBlockHandle   	extBlock;
    word    	    	extSize;
    MemHandle	    	mem;
    
    /*
     * If no block for externals allocated yet, do so and set lastExternal
     * so we start with the first slot in the block.
     */
    if (lastExternal == NullVMPtr) {
	extBlock = BorlandAllocAndInitSymBlock();
	lastExternal = MAKE_VMP(extBlock,
				sizeof(ObjSymHeader)-sizeof(ObjSym));
    }

    /*
     * Find out how big our external block is so we can quickly decide whether
     * we need to enlarge it in the loop.
     */
    extBlock = VMP_BLOCK(lastExternal);
    VMInfo(symbols, extBlock, &extSize, (MemHandle *)NULL, (VMID *)NULL);

    /*
     * Lock down the externals block and point osh and os at their respective
     * pieces o' data (os gets the next slot to use, not the last external
     * entered...).
     */
    osh = (ObjSymHeader *)VMLock(symbols, extBlock, &mem);
    os = (ObjSym *)((genptr)osh +
		    ((VMP_OFFSET(lastExternal)+sizeof(ObjSym)) & 0xffff));
	
    while (bp < endRecord) {
	/*
	 * Enter the name of the undefined external beast in the string table,
	 * and advance the object-record pointer over the whole thing.
	 */
	name = ST_Enter(symbols, strings, (char *)bp+1, *bp);
	bp += *bp + 1;

	/*
	 * If the block won't hold another symbol, enlarge it so it will.
	 */
	if (((osh->num+1)*sizeof(ObjSym)+sizeof(ObjSymHeader)) > extSize) {
	    extSize += BORLAND_INCR_SYMS * sizeof(ObjSym);
	    MemReAlloc(mem, extSize, 0);
	    MemInfo(mem, (genptr *)&osh, (word *)NULL);
	    os = (ObjSym *)((genptr)osh + VMP_OFFSET(lastExternal))+1;
	}

	/*
	 * Initialize the symbol to a global-undefined of unknown type with
	 * the given name.
	 */
	os->name = name;
	os->type = OSYM_UNKNOWN;
	os->flags = OSYM_GLOBAL | OSYM_UNDEF;
	bzero(&os->u, sizeof(os->u));

	osh->num += 1;

	/*
	 * Record this as the last external symbol defined.
	 */
	os++;
	lastExternal = MAKE_VMP(extBlock,
				VMP_OFFSET(lastExternal)+sizeof(ObjSym));

	
	Pass1MS_EnterExternal(name);

	/*
	 * Skip over meaningless type index
	 */
	MSObj_GetIndex(bp);
    }

    VMUnlockDirty(symbols, extBlock);
}
    

/***********************************************************************
 *				BorlandProcessExternalType
 ***********************************************************************
 * SYNOPSIS:	    Set the type index for the most-recently-defined
 *	    	    external symbol.
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    the u.variable.type field is set to the index
 *	    	    in this object record (in native byte-order).
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/20/91	Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessExternalType(const char *file,
			   word	    reclen, 	/* Length of remainder of
						 * COMENT record */
			   byte	    *bp)    	/* Remainder of COMENT record */
{
    word    	    index;
    ObjSym  	    *os;

    assert(lastExternal != NullVMPtr);

    index = MSObj_GetIndex(bp);

    os = (ObjSym *)VMLockVMPtr(symbols, lastExternal, (MemHandle *)NULL);

    /*
     * Put the index in the variable.type field, for want of a better place;
     * We'll use the index to decode things once all the type descriptions
     * are in.
     */
    os->u.variable.type = index;

    VMUnlockDirty(symbols, VMP_BLOCK(lastExternal));
}
    

/***********************************************************************
 *				BorlandProcessPublicType
 ***********************************************************************
 * SYNOPSIS:	    Set the type index for the most-recently-defined
 *	    	    public symbol.
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    the u.variable.type field is set to the index
 *	    	    in this object record (in native byte-order).
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/20/91	Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessPublicType(const char *file,
			 word	    reclen, 	/* Length of remainder of
						 * COMENT record */
			 byte	    *bp)    	/* Remainder of COMENT record */
{
    word    	    index;
    ObjSym  	    *os;

    assert(lastPublic != NullVMPtr);

    index = MSObj_GetIndex(bp);

    os = (ObjSym *)VMLockVMPtr(symbols, lastPublic, (MemHandle *)NULL);

    /*
     * Put the index in the variable.type field, for want of a better place;
     * we'll use the index to decode things once all the type descriptions
     * are in.
     */
    os->u.variable.type = index;

    VMUnlockDirty(symbols, VMP_BLOCK(lastPublic));
}

/***********************************************************************
 *				BorlandRecordMemberBlock
 ***********************************************************************
 * SYNOPSIS:	    Record another block filled with happy struct/enum/union
 *	    	    members for later processing.
 * CALLED BY:	    BorlandProcessStructMembers, BorlandProcessEnumMembers
 * RETURN:	    nothing
 * SIDE EFFECTS:    if major version is >= 3, another element is added
 *		    to the borlandMembers vector.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/14/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandRecordMemberBlock(VMBlockHandle	symBlock)
{
    BorlandMembers	memb;
	
    if (borlandMajorVersion >= 3) {
	/*
	 * Initialize new vector element.
	 */
	memb.members = symBlock;
	memb.start = seuStartInd;

	/*
	 * Add it to the vector.
	 */
	Vector_Add(borlandMembers, VECTOR_END, (Address)&memb);

	/*
	 * Record the index of the next member to be seen as the starting
	 * index for the next struct/enum/union.
	 */
	seuStartInd = seuCurIndex;
    }
}

/***********************************************************************
 *				BorlandProcessStructMembers
 ***********************************************************************
 * SYNOPSIS:	    Process the fields of a structure or union.
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *	For now, types always go in the global segment. This might cause
 *	    problems later on, should someone define types of the same
 *	    name differently inside different procedures.
 *	
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/31/91	Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessStructMembers(const char *file,
			    word    reclen, 	/* Length of remainder of
						 * COMENT record */
			    byte    *bp)    	/* Remainder of COMENT record */
{
    VMBlockHandle   symBlock;	    	/* Block being filled */
    ObjSymHeader    *osh;   	    	/* Header for same */
    MemHandle	    mem;    	    	/* Memory block for same, when loaded */
    word    	    symSize;	    	/* # bytes allocated for same */
    ObjSym  	    *os;    	    	/* Current field symbol */
    byte    	    *endRecord;	    	/* End of the current object record */
    int	    	    structComplete = FALSE;

    /*
     * Initialize osh and os for the loop, based on whether we're in the middle
     * of defining one of these beasts or not.
     */
    if (seuNext == 0) {
	/*
	 * First record for the structure, so allocate a new block in which to
	 * place things.
	 */
	symBlock = BorlandAllocAndInitSymBlock();

	suNextOff = -1;	/* default next offset */

	osh = (ObjSymHeader *)VMLock(symbols, symBlock, &mem);
	os = ObjFirstEntry(osh, ObjSym);

	os->name = NullID;
	os->flags = OSYM_UNDEF;

	osh->next = sTypes;
	sTypes = symBlock;
	osh->num = 1;
	seuNext = BORLAND_FIRST_MEMBER;
	os += 1;
    } else {
	/*
	 * Not the first, so pick up where we left off.
	 */
	symBlock = sTypes;
	assert(symBlock != 0);
	osh = (ObjSymHeader *)VMLock(symbols, symBlock, &mem);
	os = (ObjSym *)((genptr)osh + seuNext);
    }

    /*
     * Determine the current size of the symbol block, for quick comparison
     * in the inner loop
     */
    MemInfo(mem, (genptr *)NULL, &symSize);

    /*
     * Figure the end of the object record now, for similar reasons.
     */
    endRecord = bp + reclen;

    while (bp < endRecord && !structComplete) {
	byte	flags = *bp++;

	/*
	 * Another member encountered in this here file, whether it's a real
	 * member or just a "new offset" member.
	 */
	seuCurIndex += 1;

	switch(flags) {
	    case 0x60:	/* static member */
	    case 0x50:	/* conversion (operator) */
	    case 0x48:	/* member function */
	    case 0x49:	/* destructor */
	    case 0x4a:	/* constructor */
	    case 0x4b:	/* static member function */
	    case 0x4c:	/* virtual member function */
		/*
		 * These are all C++ things that we don't support yet.
		 */
		Notify(NOTIFY_ERROR,
		       "%s contains unsupported C++ structure field type %02x\n",
		       flags);
		goto done;
	    default:
		/*
		 * Set structComplete if this member as the LAST_MEMBER flag
		 * set for it.
		 */
		if (flags & BSM_LAST_MEMBER) {
		    structComplete = TRUE;
		}

		/*
		 * See if the member is actually a new offset or what.
		 */
		if (flags & BSM_NEW_OFFSET) {
		    /*
		     * Flags byte is follwed by dword giving the byte offset
		     * for the next member. We can only handle 16-bit offsets
		     * for now, so we just drop the high bytes, but we assert
		     * they're 0 :)
		     */
		    MSObj_GetWord(suNextOff, bp);

		    assert(*bp == 0 && bp[1] == 0);
		    bp += 2;	/* Drop high bytes (MBZ) */
		} else {
		    /*
		     * Enter the name into the string table, if the field has
		     * a name.
		     */
		    if (*bp != 0) {
			os->name = ST_Enter(symbols, strings,
					    (char *)bp+1, *bp);
		    } else {
			os->name = NullID;
		    }

		    /*
		     * Skip over name
		     */
		    bp += *bp + 1;

		    /*
		     * Specify the symbol is a structure field.
		     */
		    os->type = OSYM_FIELD;
		    os->flags = 0;

		    /*
		     * If this isn't the final member, set its next field to
		     * the next slot in the block, as another member will be
		     * placed there.
		     *
		     * If it is the final member, the beast needs to be linked
		     * back to the containing type symbol, which always follows
		     * the block header.
		     */
		    if (!structComplete) {
			os->u.sField.next = seuNext + sizeof(ObjSym);
		    } else {
			os->u.sField.next = sizeof(ObjSymHeader);
		    }

		    /*
		     * Set offset of the field to the next one and reset to
		     * be calculated for the next field (offsets of -1 are
		     * calculated in BorlandConvertSymbolBlock based on the
		     * previous field).
		     */
		    os->u.sField.offset = suNextOff;
		    suNextOff = -1;

		    /*
		     * Extract the field type from the record; this consumes
		     * all the bytes for this member, placing bp to the start
		     * of the record for the next member.
		     */
		    os->u.sField.type = MSObj_GetIndex(bp);
		    
		    /*
		     * Figure if the beast is a bitfield or what.
		     */
		    if (flags & BSM_MEMBER_WIDTH) {
			/*
			 * It's a bitfield, so the type is special; the index
			 * *must* be one of BT_CHAR, BT_SHORT, BT_LONG,
			 * BT_BYTE, BT_WORD or BT_DWORD, as that's all we can
			 * handle.
			 *
			 * We set the os->type to OSYM_BITFIELD so we know
			 * we needn't convert the type index to a type
			 * description; it'll get changed back to OSYM_FIELD
			 * at that time.
			 */
			word	type;
			
			os->type = OSYM_BITFIELD;
			type = OTYPE_BITFIELD | OTYPE_SPECIAL |
			    ((flags & BSM_MEMBER_WIDTH) << OTYPE_BF_WIDTH_SHIFT);
			
			if (os[-1].type == OSYM_BITFIELD) {
			    word    prevType = os[-1].u.sField.type;
			    
			    type |= (((prevType & OTYPE_BF_OFFSET) >>
				      OTYPE_BF_OFFSET_SHIFT) +
				     ((prevType & OTYPE_BF_WIDTH) >>
				      OTYPE_BF_WIDTH_SHIFT)) <<
					  OTYPE_BF_OFFSET_SHIFT;
			}

			switch(os->u.sField.type) {
			    case BT_CHAR:
			    case BT_SHORT:
			    case BT_LONG:
				type |= OTYPE_BF_SIGNED;
				break;
			    case BT_NAMELESS:
			    case BT_BYTE:
			    case BT_WORD:
			    case BT_DWORD:
				/* leave OTYPE_BF_SIGNED clear */
				break;
			    default:
				/*
				 * We can't deal with anything else
				 */
				assert(0 /* invalid bitfield base type */);
				break;
			}
			
			os->u.sField.type = type;
		    } else {
		    	os->flags |= OSYM_UNDEF; /* Until the type index is
					      * converted... */
		    }
		    /*
		     * Advance to the next slot in the block. If not the last
		     * member, make sure the block can hold at least one more
		     * symbol
		     */
		    seuNext += sizeof(ObjSym);
		    if (!structComplete && (seuNext + sizeof(ObjSym)) > symSize)
		    {
			symSize = seuNext + BORLAND_INCR_SYMS*sizeof(ObjSym);
			MemReAlloc(mem, symSize, 0);
			MemInfo(mem, (genptr *)&os, (word *)NULL);
			os = (ObjSym *)((genptr)osh + seuNext);
		    } else {
			os += 1;
		    }
		    osh->num += 1;
		}
		break;
	}
    }

    if (structComplete) {
	seuNext = 0;

	BorlandRecordMemberBlock(symBlock);
    }

    done:

    VMUnlockDirty(symbols, symBlock);
}
    

/***********************************************************************
 *				BorlandProcessEnumMembers
 ***********************************************************************
 * SYNOPSIS:	    Process the fields of an enumerated type
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *	For now, types always go in the global segment. This might cause
 *	    problems later on, should someone define types of the same
 *	    name differently inside different procedures.
 *	
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/31/91	Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessEnumMembers(const char *file,
			  word  reclen, 	/* Length of remainder of
						 * COMENT record */
			  byte  *bp)    	/* Remainder of COMENT record */
{
    VMBlockHandle   symBlock;	    	/* Block being filled */
    ObjSymHeader    *osh;   	    	/* Header for same */
    MemHandle	    mem;    	    	/* Memory block for same, when loaded */
    word    	    symSize;	    	/* # bytes allocated for same */
    ObjSym  	    *os;    	    	/* Current field symbol */
    byte    	    *endRecord;	    	/* End of the current object record */
    int	    	    structComplete = FALSE;

    /*
     * Initialize osh and os for the loop, based on whether we're in the middle
     * of defining one of these beasts or not.
     */
    if (seuNext == 0) {
	/*
	 * First record for the structure, so allocate a new block in which to
	 * place things.
	 */
	symBlock = BorlandAllocAndInitSymBlock();

	osh = (ObjSymHeader *)VMLock(symbols, symBlock, &mem);
	os = ObjFirstEntry(osh, ObjSym);

	os->name = NullID;
	os->flags = OSYM_UNDEF;

	osh->next = sTypes;
	sTypes = symBlock;
	osh->num = 1;
	seuNext = BORLAND_FIRST_MEMBER;
	os += 1;
    } else {
	/*
	 * Not the first, so pick up where we left off.
	 */
	symBlock = sTypes;
	assert(symBlock != 0);
	osh = (ObjSymHeader *)VMLock(symbols, symBlock, &mem);
	os = (ObjSym *)((genptr)osh + seuNext);
    }

    /*
     * Determine the current size of the symbol block, for quick comparison
     * in the inner loop
     */
    MemInfo(mem, (genptr *)NULL, &symSize);

    /*
     * Figure the end of the object record now, for similar reasons.
     */
    endRecord = bp + reclen;

    while (bp < endRecord && !structComplete) {
	byte	flags = *bp++;

	assert(flags == 0 || flags == BEM_LAST_MEMBER);

	/*
	 * Another member record seen...
	 */
	seuCurIndex += 1;

	/*
	 * Set structComplete if this member as the LAST_MEMBER flag
	 * set for it.
	 */
	if (flags & BEM_LAST_MEMBER) {
	    structComplete = TRUE;
	}

	/*
	 * Enter the name into the string table, if the member has a name.
	 */
	if (*bp != 0) {
	    os-> name = ST_Enter(symbols, strings, (char *)bp+1, *bp);
	} else {
	    os->name = NullID;
	}

	/*
	 * Skip over name
	 */
	bp += *bp + 1;

	/*
	 * Specify the symbol is a enumerated constant.
	 */
	os->type = OSYM_ENUM;
	os->flags = 0;

	/*
	 * If this isn't the final member, set its next field to the next slot
	 * in the block, as another member will be placed there.
	 *
	 * If it is the final member, the beast needs to be linked back to the
	 * containing type symbol, which always follows the block header.
	 */
	if (!structComplete) {
	    os->u.eField.next = seuNext + sizeof(ObjSym);
	} else {
	    os->u.eField.next = sizeof(ObjSymHeader);
	}

	/*
	 * Set the value of the constant to that stored in the record
	 */
	MSObj_GetWord(os->u.eField.value, bp);
		    
	/*
	 * Advance to the next slot in the block. If not the last member, make
	 * sure the block can hold at least one more symbol
	 */
	seuNext += sizeof(ObjSym);
	if (!structComplete && (seuNext + sizeof(ObjSym)) > symSize) {
	    symSize = seuNext + BORLAND_INCR_SYMS*sizeof(ObjSym);
	    MemReAlloc(mem, symSize, 0);
	    MemInfo(mem, (genptr *)&os, (word *)NULL);
	    os = (ObjSym *)((genptr)osh + seuNext);
	} else {
	    os += 1;
	}
	osh->num += 1;
    }

    if (structComplete) {
	seuNext = 0;

	BorlandRecordMemberBlock(symBlock);
    }

    VMUnlockDirty(symbols, symBlock);
}
    

/***********************************************************************
 *				BorlandFinishSEU
 ***********************************************************************
 * SYNOPSIS:	    Finish off the definition of a structure, enumerated
 *	    	    type, or union.
 * CALLED BY:	    BorlandProcessTypedef
 * RETURN:	    nothing
 * SIDE EFFECTS:    ja.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/31/91	Initial Revision
 *
 ***********************************************************************/
static void
BorlandFinishSEU(byte	    	*tname,	    /* Name for the type (counted
					     * ASCII), if any. NULL if called
					     * to process type record at end
					     * of file under v3.0 symbol
					     * format */
		 BorlandType	*bt,	    /* Type record being defined */
		 byte	    	symType)    /* OSYM_* symbol-type for the
					     * thing being finished */
{
    ID	    	    typeName;	    /* Entered name of the type */
    word    	    flags;  	    /* OSYM_NAMELESS or 0, depending on whether
				     * the type has a name */
    VMBlockHandle   symBlock;	    /* Block in which members reside */
    ObjSymHeader    *osh;   	    /* Locked header of same */
    ObjSym  	    *os;    	    /* Symbol for the type itself */
    
    /*
     * Figure a name for the type, since all users of the type must, perforce,
     * use the name.
     */
    if (tname != NULL) {
	if (*tname == 0) {
	    /*
	     * Type has no name, so make one up and flag the thing as nameless.
	     */
	    typeName = MSObj_MakeString();
	    flags = OSYM_NAMELESS;
	} else {
	    char 	*name;
	    int 	namelen;
	    char	*prefix;
	    
	    /*
	     * Create a name for the beast, placing the appropriate string in
	     * front of the tag to be consistent with CodeView and general usage.
	     */
	    switch(symType) {
		case OSYM_STRUCT: prefix = "struct "; break;
		case OSYM_UNION: prefix = "union "; break;
		case OSYM_ETYPE: prefix = "enum "; break;
		default:
		    assert(0);
		    prefix = "";
		    break;
	    }
	    namelen = strlen(prefix) + *tname;
	    name = (char *)malloc(namelen + 1);
	    sprintf(name, "%s%.*s", prefix, *tname, (char *)tname+1);
	    
	    typeName = ST_Enter(symbols, strings, name, namelen);
	    flags = 0;  	/* Not nameless */
	    
	    free(name);
	}
    } else {
	typeName = NullID;
	flags = 0;
    }


    if (borlandMajorVersion >= 3) {
	if ((bt->ot.words[0] == 0) && (bt->ot.words[1] == 0)) {
	    /*
	     * Not done with the object file yet, so just store the name in
	     * the ot (low bit set => nameless)
	     */
	    if (flags) {
		OTYPE_ID_TO_STRUCT(typeName|1, &bt->ot);
	    } else {
		OTYPE_ID_TO_STRUCT(typeName, &bt->ot);
	    }
	    return;
	} else {
	    /*
	     * Must be done with the file, so now we need to find the block
	     * containing the members and do as we would have had this format
	     * been left as it was for BCC 2.x...
	     */
	    word    	    index;  	/* Index of the first member, using
					 * which we can find the member block */
	    byte    	    *bp;    	/* Pointer for extracting the index */
	    BorlandMembers  *memp;  	/* Member block we're checking */
	    int	    	    i;	    	/* Counter for checking it */
	    
	    assert(tname == NULL); /* Must be at eof */

	    switch (bt->desc[0]) {
		case BTID_VLSTRUCT:
		case BTID_VLUNION:
		    /*
		     * TID is followed by high word of type size, then comes
		     * the index.
		     */
		    symType = ((bt->desc[0] == BTID_VLSTRUCT) ? OSYM_STRUCT :
			       OSYM_UNION);
		    bp = &bt->desc[3];
		    break;
		case BTID_STRUCT:
		case BTID_UNION:
		    /*
		     * index follows immediately after TID.
		     */
		    symType = ((bt->desc[0] == BTID_STRUCT) ? OSYM_STRUCT :
			       OSYM_UNION);
		    bp = &bt->desc[1];
		    break;
		case BTID_ENUM:
		    /*
		     * TID is followed by parent type index, then min and
		     * max (both words), then comes the index.
		     */
		    symType = OSYM_ETYPE;
		    bp = &bt->desc[1];
		    (void)MSObj_GetIndex(bp);
		    bp += 4;
		    break;
		default:
		    assert(0 /* unhandled structured type */);
		    return;
	    }
	    /*
	     * Extract the index of the first member from the proper place, as
	     * determined by the preceding switch.
	     */
	    index = MSObj_GetIndex(bp);

	    /*
	     * Now look for a block of members whose first member has the
	     * indicated index.
	     */
	    for (i = Vector_Length(borlandMembers),
		 memp = (BorlandMembers *)Vector_Data(borlandMembers);

		 i > 0;

		 i--, memp++)
	    {
		if (memp->start == index) {
		    break;
		}
	    }

	    assert(i != 0 /* could not find structured type members */);

	    /*
	     * Record its block handle so we can mess with it in a moment.
	     */
	    symBlock = memp->members;

	    /*
	     * Extract the typeName and flags we saved before.
	     */
	    typeName = OTYPE_STRUCT_ID(&bt->ot) & ~1;
	    if (bt->ot.words[0] & 1) {
		flags = OSYM_NAMELESS;
	    } else {
		flags = 0;
	    }
	}
    } else {
	/*
	 * pre-3.0, so members should have been just before this record and
	 * be at the head of the non-empty sTypes list.
	 */
	assert(sTypes != 0);
	symBlock = sTypes;
    }

    /*
     * Initialize the type symbol for the structured type.
     */
    osh = (ObjSymHeader *)VMLock(symbols, symBlock, (MemHandle *)NULL);
    os = ObjFirstEntry(osh, ObjSym);

    /*
     * Each structured-type definition must be followed by a TYPEDEF record.
     * To check this, we set OSYM_UNDEF in the flags byte of the type symbol
     * when creating the symbol block in which the fields/members are placed.
     * We clear it here...
     */
    assert(os->flags & OSYM_UNDEF);

    os->flags = flags;
    os->name = typeName;
    os->type = symType;

    /*
     * Record the block & offset of the first symbol in the block.
     */
    bt->ot.words[0] = sizeof(ObjSymHeader);
    bt->ot.words[1] = symBlock;

    /*
     * Initialize the rest of the symbol appropriately.
     */
    os->u.sType.first = BORLAND_FIRST_MEMBER;
    os->u.sType.last = sizeof(ObjSymHeader) + (osh->num - 1) * sizeof(ObjSym);
    os->u.sType.size = bt->size;

    /*
     * Dirty and unlock the block
     */
    VMUnlockDirty(symbols, symBlock);
}
    

/***********************************************************************
 *				BorlandProcessTypedef
 ***********************************************************************
 * SYNOPSIS:	    Process the definition of a type
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *	For now, types always go in the global segment. This might cause
 *	    problems later on, should someone define types of the same
 *	    name differently inside different procedures.
 *	
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/31/91	Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessTypedef(const char *file,
		      word  reclen, 	/* Length of remainder of
					 * COMENT record */
		      byte  *bp)    	/* Remainder of COMENT record */
{
    byte    	*start = bp;
    word    	index = MSObj_GetIndex(bp);
    byte    	*tname;
    BorlandType	bt;

    /*
     * Save the name for creating a "struct <foo>" or "union <foo>" or
     * "enum <foo>" string for the current struct/union/enum
     */
    tname = bp;
    bp += *bp + 1;

    bzero(&bt, sizeof(bt));

    MSObj_GetWord(bt.size, bp);

    /*
     * Copy the bytes of the descriptor itself into the BorlandType record for
     * this beast, for later use once the object file has been completely
     * processed.
     */
    reclen -= bp - start;
    assert(reclen < BT_MAX_TYPE_LEN);

    bcopy(bp, bt.desc, reclen);

    /*
     * Assume the type will be converted later.
     */
    bt.shortType = 0;

    switch(*bp++) {
	case BTID_VOID:	    	/* Void:
				 *	- nothing
				 */
	    bt.shortType = OTYPE_MAKE_VOID();
	    break;
	case BTID_LSTR:	    	/* BASIC Literal string:
				 *	- nothing
				 */
	    goto unhandled;
	case BTID_DSTR:	    	/* BASIC Dynamic string:
				 *	- nothing
				 */
	    goto unhandled;
	case BTID_PSTR:	    	/* Pascal string:
				 *	- maximum length (byte)
				 */
	    bt.shortType = BORLAND_CONVERTED_LONG_TYPE;
	    bt.ot.words[0] = OTYPE_MAKE_ARRAY(*bp);
	    bt.ot.words[1] = OTYPE_MAKE_CHAR(1);
	    break;
	case BTID_SCHAR:	/* 1-byte signed int range:
				 *	- parent type index (index)
				 *	- lower bound (dword)
				 *	- upper bound (dword)
				 */
	    bt.shortType = OTYPE_MAKE_CHAR(1);
	    break;
	case BTID_SINT:	    	/* 2-byte signed int range:
				 *	- parent type index (index)
				 *	- lower bound (dword)
				 *	- upper bound (dword)
				 */
	    bt.shortType = OTYPE_MAKE_SIGNED(2);
	    break;
	case BTID_SLONG:	/* 4-byte signed int range:
				 *	- parent type index (index)
				 *	- lower bound (dword)
				 *	- upper bound (dword)
				 */
	    bt.shortType = OTYPE_MAKE_SIGNED(4);
	    break;
	case BTID_SQUAD:	/* 8-byte signed int range:
				 *	- parent type index (index)
				 *	- lower bound (dword)
				 *	- upper bound (dword)
				 */
	    bt.shortType = OTYPE_MAKE_SIGNED(8);
	    break;
	case BTID_UCHAR:	/* 1-byte unsigned int range:
				 *	- parent type index (index)
				 *	- lower bound (dword)
				 *	- upper bound (dword)
				 */
	    bt.shortType = OTYPE_MAKE_INT(1);
	    break;
	case BTID_UINT:	    	/* 2-byte unsigned int range:
				 *	- parent type index (index)
				 *	- lower bound (dword)
				 *	- upper bound (dword)
				 */
	    bt.shortType = OTYPE_MAKE_INT(2);
	    break;
	case BTID_ULONG:	/* 4-byte unsigned int range:
				 *	- parent type index (index)
				 *	- lower bound (dword)
				 *	- upper bound (dword)
				 */
            bt.shortType = OTYPE_MAKE_INT(4);
	    break;
	case BTID_UQUAD:	/* 8-byte unsigned int range:
				 *	- parent type index (index)
				 *	- lower bound (dword)
				 *	- upper bound (dword)
				 */
	    bt.shortType = OTYPE_MAKE_INT(8);
	    break;
	case BTID_PCHAR:	/* 1-byte unsigned int range (Pascal
				 * character, so no arithmetic allowed):
				 *	- parent type index (index)
				 *	- lower bound (dword)
				 *	- upper bound (dword)
				 */
	    bt.shortType = OTYPE_MAKE_INT(1);
	    break;
	case BTID_FLOAT:	/* IEEE 32-bit real:
				 *	- nothing
				 */
	    bt.shortType = OTYPE_MAKE_FLOAT(4);
	    break;
	case BTID_TPREAL:	/* Turbo Pascal real (6-byte):
				 *	- nothing
				 */
	    goto unhandled;
	case BTID_DOUBLE:	/* IEEE 64-bit real:
				 *	- nothing
				 */
	    bt.shortType = OTYPE_MAKE_FLOAT(8);
	    break;
	case BTID_LDOUBLE:	/* IEEE 80-bit real:
				 *	- nothing
				 */
	    bt.shortType = OTYPE_MAKE_FLOAT(10);
	    break;
	case BTID_BCD4:	    	/* 4-byte BCD:
				 *	- nothing
				 */
	    goto unhandled;
	case BTID_BCD8:	    	/* 8-byte BCD:
				 *	- nothing
				 */
	    goto unhandled;
	case BTID_BCD10:	/* 10-byte BCD:
				 *	- nothing
				 */
	    goto unhandled;
	case BTID_BCDCOB:	/* COBOL BCD:
				 *	- position of the decimal point (byte)
				 */
	    goto unhandled;
	case BTID_NEAR:	    	/* near pointer:
				 *	- index of type pointed to (index)
				 *	- segment base (byte):
				 *	    0x00    unspecified
				 *	    0x01    ES
				 *	    0x02    CS
				 *	    0x03    SS
				 *	    0x04    DS
				 *	    0x05    FS
				 *	    0x06    GS
				 */
	    bt.shortType = BORLAND_CONVERTED_LONG_TYPE;
	    bt.ot.words[0] = OTYPE_PTR | OTYPE_PTR_NEAR | OTYPE_SPECIAL;
	    bt.ot.words[1] = MSObj_GetIndex(bp);
	    break;
	case BTID_FAR:	    	/* far pointer:
				 *	- index of type pointed to (index)
				 *	- pointer arithmetic (byte):
				 *	    0x00    segment adjustment not nec'y
				 *	    0x01    segment adjustments needed
				 *		    to avoid offset wrap.
				 */
	    bt.shortType = BORLAND_CONVERTED_LONG_TYPE;
	    bt.ot.words[0] = OTYPE_PTR | OTYPE_PTR_FAR | OTYPE_SPECIAL;
	    bt.ot.words[1] = MSObj_GetIndex(bp);
	    break;
	case BTID_SEG:	    	/* segment pointer:
				 *	- index of type pointed to (index)
				 *	- extra byte
				 */
	    bt.shortType = BORLAND_CONVERTED_LONG_TYPE;
	    bt.ot.words[0] = OTYPE_PTR | OTYPE_PTR_SEG | OTYPE_SPECIAL;
	    bt.ot.words[1] = MSObj_GetIndex(bp);
	    break;
	case BTID_NEAR386:	/* 32-bit near pointer:
				 *	- index of type pointed to (index)
				 *	- segment base (byte):
				 *	    0x00    unspecified
				 *	    0x01    ES
				 *	    0x02    CS
				 *	    0x03    SS
				 *	    0x04    DS
				 *	    0x05    FS
				 *	    0x06    GS
				 */
	    goto unhandled;
	case BTID_FAR386:	/* 48-bit far pointer:
				 *	- index of type pointed to (index)
				 *	- pointer arithmetic (byte):
				 *	    0x00    segment adjustment not nec'y
				 *	    0x01    segment adjustments needed
				 *		    to avoid offset wrap.
				 */
	    goto unhandled;
	case BTID_CARRAY:	/* C array (0-based):
				 *	- element type (index)
				 * dimension is determined by dividing type
				 * size by element size.
				 */
	    bt.shortType = BORLAND_CONVERTED_LONG_TYPE;
	    bt.ot.words[0] = OTYPE_MAKE_ARRAY(0);
	    bt.ot.words[1] = MSObj_GetIndex(bp);
	    break;
	case BTID_VLARRAY:	/* Very Large array (0-based):
				 *	- high 16 bits of array size (word);
				 *	  merged with usual word of type size to
				 *	  form dword of type size.
				 *	- element type (index)
				 * dimension again determined by dividing
				 * dword type size by element size
				 */
	    if (*bp != 0 || bp[1] != 0) {
		goto unhandled;
	    }
	    bp += 2;
	    
	    bt.shortType = BORLAND_CONVERTED_LONG_TYPE;
	    bt.ot.words[0] = OTYPE_MAKE_ARRAY(0);
	    bt.ot.words[1] = MSObj_GetIndex(bp);
	    break;
	case BTID_PARRAY:	/* Pascal array:
				 *	- element type (index)
				 *	- index type (index)
				 * dimension determined by elements of the
				 * index type.
				 */
	    goto unhandled;
	case BTID_ADESC:	/* BASIC array descriptor:
				 *	- nothing
				 */
	    goto unhandled;
	case BTID_VLSTRUCT:	/* Very Large Structure:
				 *	- high 16 bits of type size (word)
				 */
	    if (*bp != 0 || bp[1] != 0) {
		goto unhandled;
	    }
	    /*FALLTHRU*/
	case BTID_STRUCT:	/* Structure:
				 *	- nothing
				 */
	    BorlandFinishSEU(tname, &bt, OSYM_STRUCT);
	    break;
	case BTID_VLUNION:	/* Very Large Union:
				 *	- high 16 bits of type size (word)
				 */
	    if (*bp != 0 || bp[1] != 0) {
		goto unhandled;
	    }
	    /*FALLTHRU*/
	case BTID_UNION:	/* Union:
				 *	- nothing
				 */
	    BorlandFinishSEU(tname, &bt, OSYM_UNION);
	    break;
	case BTID_ENUM:	    	/* Enumerated type:
				 *	- parent type (index)
				 *	- lower bound (signed word)
				 *	- upper bound (signed word)
				 */
	    /*
	     * XXX: do something about non-integer parent type.
	     */
	    BorlandFinishSEU(tname, &bt, OSYM_ETYPE);
	    break;
	case BTID_FUNCTION:	/* Function/procedure:
				 *	- return type (index)
				 *	- language modifier (byte):
				 *	    0x00    near C function
				 *	    0x01    near Pascal function
				 *	    0x02    unused
				 *	    0x03    unused
				 *	    0x04    far C function
				 *	    0x05    far Pascal function
				 *	    0x06    unused
				 *	    0x07    interrupt
				 *	- varargs (byte). 1 if function accepts
				 *	  variable # of args, 0 otherwise.
				 */
	    MSObj_GetIndex(bp);
	    bt.shortType = ((*bp == 0 || *bp == 1) ? OTYPE_MAKE_NEAR() :
			    OTYPE_MAKE_FAR());
	    
	    /* Other parts dealt with when a function symbol is encountered with
	     * this type. The stuff we just did is for function pointers */
	    break;
	case BTID_LABEL:	/* Label:
				 *	- distance (byte). 0 if near, 1 if far.
				 */
	    bt.shortType = *bp ? OTYPE_MAKE_FAR() : OTYPE_MAKE_NEAR();
	    break;
	case BTID_SET:	    	/* Pascal Set:
				 *	- parent type (index)
				 */
	    goto unhandled;
	case BTID_TFILE:	/* Pascal text file:
				 *	- nothing
				 */
	    goto unhandled;
	case BTID_BFILE:	/* Pascal binary file:
				 *	- record type (index)
				 */
	    goto unhandled;
	case BTID_BOOL:	    	/* Pascal boolean:
				 *	- nothing
				 */
	    goto unhandled;
	case BTID_PENUM:	/* Pascal enumerated type (no arithmetic):
				 *	- parent type (index)
				 *	- lower bound (signed word)
				 *	- upper bound (signed word)
				 */
	    BorlandFinishSEU(tname, &bt, OSYM_ETYPE);
	    break;
	case BTID_PWORD:	/* pword (some MASM thing I've forgotten):
				 *	- nothing
				 */
	    bt.shortType = OTYPE_MAKE_INT(6);
	    break;
	case BTID_TBYTE:	/* 10-byte thing, usually a real:
				 *	- nothing
				 */
	    goto unhandled;
	case BTID_SPECIALFUNC:	/* Member/duplicate function:
				 *	- return type (index)
				 *	- language modifier (byte):
				 *	    0x00    near C function
				 *	    0x01    near Pascal function
				 *	    0x02    unused
				 *	    0x03    unused
				 *	    0x04    far C function
				 *	    0x05    far Pascal function
				 *	    0x06    unused
				 *	    0x07    interrupt
				 *	- other flags (byte):
				 *	    bit 0   set if member function
				 *	    bit 1   set if duplicate function
				 *	    bit 2   set if operator function
				 *	    bit 3   set if local function
				 *	- class, if member function (index)
				 *	- offset in virtual table (word), if
				 *	  member function
				 *	- mangled name (string), if non-local
				 *	  member function
				 * "this" should appear as a local symbol
				 * in the second inner scope of a member
				 * function (not in the outermost,
				 * parameter, scope)
				 */
	    goto unhandled;
	case BTID_CLASS:	/* C++ class:
				 *	- class index (index), as separate from
				 *	  the type index, I think.
				 */
	    goto unhandled;
	case BTID_MEMBERPTR:	/* Type pointed to by a class member ptr:
				 *	- type pointed to (index)
				 *	- class to which member belongs (index),
				 *	  supposedly the class index, not type
				 *	  index...
				 */
	    goto unhandled;

	case BTID_NREF:	    	/* Near reference (parameter passed by
				 * reference, I think, not value):
				 *	- type pointed to (index)
				 *	- extra byte (byte), always 0
				 */
	    /* convert later */
	    break;
	case BTID_FREF:	    	/* Far reference (parameter passed by
				 * reference, I think, not value):
				 *	- type pointed to (index)
				 *	- extra byte (byte), always 0
				 */
	    /* convert later */
	    break;

	    unhandled:

	    Notify(NOTIFY_ERROR,
		   "%s: unhandled Borland type ID %02x\n",
		   file, bp[-1]);
	    break;
    }

    Vector_Add(borlandTypes, index, (Address)&bt);
}


/***********************************************************************
 *				BorlandAllocLocal
 ***********************************************************************
 * SYNOPSIS:	    Allocate an ObjSym for a local symbol at the end
 *	    	    of the passed block.
 * CALLED BY:	    BorlandLinkLocal, BorlandEnterLocalStackSymbol
 * RETURN:	    address of ObjSym to use
 *	    	    *sosPtr fixed up, if non-null.
 *	    	    *symPtr filled in, if non-null.
 *	    	    THE BLOCK IS NOT MARKED DIRTY, THOUGH IT IS MADE SO
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static ObjSym *
BorlandAllocLocal(VMBlockHandle	    block,
		  ObjSym    	    **sosPtr,
		  VMPtr	    	    *symPtr)
{
    ObjSymHeader    	*osh;
    word    	    	size;
    MemHandle	    	mem;
    ObjSym  	    	*os;
    
    osh = (ObjSymHeader *)VMLock(symbols, block, &mem);
    MemInfo(mem, (genptr *)NULL, &size);
    
    /*
     * Make sure the block can hold another symbol.
     */
    if ((osh->num + 1) * sizeof(ObjSym) + sizeof(ObjSymHeader) > size) {
	/*
	 * Nope. Expand the block some more, dealing with fixing up
	 * *sosPtr if it's passed.
	 */
	word	sosOff = 0;	/* avoid bogus gcc warning */

	if (sosPtr != NULL) {
	    sosOff = ObjEntryOffset(osh, *sosPtr);
	}

	MemReAlloc(mem, size + BORLAND_INCR_SYMS * sizeof(ObjSym), 0);
	MemInfo(mem, (genptr *)&osh, (word *)NULL);

	if (sosPtr != NULL) {
	    *sosPtr = (ObjSym *)((genptr)osh + sosOff);
	}
    }
    
    /*
     * Set up the return value
     */
    os = ObjFirstEntry(osh, ObjSym) + osh->num;

    /*
     * Return the VMPtr for the beast, if asked.
     */
    if (symPtr != NULL) {
	*symPtr = MAKE_VMP(block, ObjEntryOffset(os,osh));
    }
    
    /*
     * Flag another symbol in the block.
     */
    osh->num += 1;

    /*
     * Return the return value, of course
     */
    return(os);
}


/***********************************************************************
 *				BorlandLinkLocal
 ***********************************************************************
 * SYNOPSIS:	    Link a symbol into the current local-symbol scope.
 * CALLED BY:	    BorlandProcessBeginScope, BorlandProcessLocals,
 *	    	    BorlandProcessEndScope
 * RETURN:	    nothing
 * SIDE EFFECTS:    pointers into the current scope's block are invalid
 *	    	    after this call, as a LOCAL_STATIC symbol may need to
 *	    	    be created.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandLinkLocal(VMPtr	sym)
{
    ObjSym  	*os;	    /* Symbol being linked */
    ObjSym  	*sos;	    /* Scope symbol */

    /*
     * If not in a scope, then it's just file-static, not actually local.
     */
    if (scopeTop == 0) {
	return;
    }

    os = (ObjSym *)VMLockVMPtr(symbols, sym, (MemHandle *)NULL);
    sos = (ObjSym *)VMLockVMPtr(symbols, scopeStack[scopeTop-1].scope,
				(MemHandle *)NULL);

    switch(os->type) {
	default:
	{
	    /*
	     * Symbol has no linkage, so we must make up a LOCAL_STATIC
	     * symbol for the beast.
	     */
	    BorlandLocalStatic	bls;
	    ID	    	    	name;

	    /*
	     * Save the name of the variable for the LOCAL_STATIC to use, then
	     * unlock the variable again.
	     */
	    name = os->name;
	    VMUnlock(symbols, VMP_BLOCK(sym));
	    
	    /*
	     * Allocate space at the end of the scope's block.
	     */
	    os = BorlandAllocLocal(VMP_BLOCK(scopeStack[scopeTop-1].scope),
				   &sos,
				   &bls.local);
	    
	    /*
	     * Fill in the new symbol appropriately.
	     */
	    os->type = OSYM_LOCAL_STATIC;
	    os->flags = 0;
	    os->name = name;
	    bls.varBlock = os->u.localStatic.symBlock = VMP_BLOCK(sym);
	    bls.varOffset = os->u.localStatic.symOff = VMP_OFFSET(sym);

	    /*
	     * Finish initializing the structure that tracks these things to
	     * deal with inserting a symbol in either this block or the one
	     * holding the static symbol, then add the thing to the end of the
	     * list (borlandLocalStatics).
	     */
	    Vector_Add(borlandLocalStatics, VECTOR_END, (Address)&bls);

	    /*
	     * Dirty the scope's block and fall through to add the new symbol
	     * to the end of the current scope's local-symbol list.
	     */
	    sym = bls.local;
	    /*FALLTHRU*/
	}
	case OSYM_LOCLABEL:
	case OSYM_LOCVAR:
	case OSYM_REGVAR:
	case OSYM_BLOCKSTART:
	case OSYM_BLOCKEND:
	{
	    /*
	     * These are all officially part of a local-symbol chain, so we can
	     * link them in safely.
	     */
	    genptr  base;   	/* Base of the block holding the scope and its
				 * locals, so we can get to the individual
				 * locals easily */
	    word    scopeOff;	/* Offset of the scope symbol in the block */

	    scopeOff = VMP_OFFSET(scopeStack[scopeTop-1].scope);


	    base = (genptr)os - VMP_OFFSET(sym);
	    assert(base == ((genptr)sos - scopeOff));

	    if (scopeStack[scopeTop-1].lastLocal == scopeOff) {
		sos->u.scope.first = VMP_OFFSET(sym);
	    } else {
		ObjSym  *prev;

		prev = (ObjSym *)(base + scopeStack[scopeTop-1].lastLocal);
		prev->u.procLocal.next = VMP_OFFSET(sym);
	    }

	    /*
	     * Link the new symbol to the end of the chain.
	     */
	    os->u.procLocal.next = scopeOff;
	    scopeStack[scopeTop-1].lastLocal = VMP_OFFSET(sym);
	    break;
	}
    }
    
    VMUnlockDirty(symbols, VMP_BLOCK(sym));
    VMUnlock(symbols, VMP_BLOCK(scopeStack[scopeTop-1].scope));
}
	    

/***********************************************************************
 *				BorlandProcessBeginScope
 ***********************************************************************
 * SYNOPSIS:	    Process the beginning of a variable scope
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *    	    	if the scope stack is empty:
 *    	    	    look for OSYM_PROC at same address. create
 *    	    	    OSYM_PROC if none
 *    	    	    push whichever
 *    	    	else if the scope stack holds 1 entry:
 *    	    	    create a ??START symbol at this scope's address,
 *    	    	    then push the first scope again.
 *    	    	else
 *    	    	    create a BLOCKSTART symbol at the proper place
 *    	    	    in the symbol block (after all local syms
 *    	    	    following scope symbol that comes before this
 *    	    	    one) and push its offset onto the scope stack
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/31/91	Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessBeginScope(const char *file,
			 word  	reclen,	/* Length of remainder of
					 * COMENT record */
			 byte  	*bp)   	/* Remainder of COMENT record */
{
    VMPtr   	    sym;
    BorlandSegData  *sdata;
    word    	    segIndex;
    ObjSym  	    *os;

    segIndex = MSObj_GetIndex(bp);
    sdata = BorlandGetSegData(segIndex);


    switch(scopeTop) {
	case 0:
	    /*
	     * Entering a procedure scope. This scope holds the parameters,
	     * and will be made to hold the local variables, as well.
	     *
	     * Since the symbol we may create will be taken over by the
	     * actual procedure (they have the same address), we pass a name
	     * of NullID, rather than making up a scope name. 
	     * BorlandEnterAddressSymbol will properly detect if a procedure
	     * symbol is already in the symbol table and do nothing but return
	     * us its address.
	     */
	    sym = BorlandEnterAddressSymbol(NullID, MSObj_GetWordImm(bp),
					    OSYM_BLOCKSTART,
					    0, sdata);
	    scopeNum = 0;
	    break;
	case 1:
	    /*
	     * Borland puts all top-level procedure-local variables in this
	     * scope. We have just one scope that holds both parameters and
	     * local variables, though. This scope does serve the purpose of
	     * telling us where the local variables are valid, however, so we
	     * create a ??START local label at the scope's offset instead, then
	     * push the current scope on the stack again, so we don't get
	     * confused by the END_SCOPE record.
	     */
	    sym = BorlandEnterAddressSymbol(ST_EnterNoLen(symbols, strings,
							  OSYM_PROC_START_NAME),
					    MSObj_GetWordImm(bp),
					    OSYM_LOCLABEL,
					    OSYM_NAMELESS,
					    sdata);
	    BorlandLinkLocal(sym);
	    sym = scopeStack[0].scope;
	    break;
	default:
	{
	    char    name[16];

	    sprintf(name, "block%d", ++scopeNum);
	    
	    sym = BorlandEnterAddressSymbol(ST_EnterNoLen(symbols, strings,
							  name),
					    MSObj_GetWordImm(bp),
					    OSYM_BLOCKSTART,
					    0,
					    sdata);
	    BorlandLinkLocal(sym);
	    break;
	}
    }

    /*
     * Initialize the first-local pointer of the new scope to the scope itself,
     * if it is a new scope (i.e. scopeTop isn't 1 => we're pushing the
     * procedure symbol again)
     */
    os = (ObjSym *)VMLockVMPtr(symbols, sym, (MemHandle *)NULL);
    if (scopeTop != 1) {
	os->u.scope.first = VMP_OFFSET(sym);
	scopeStack[scopeTop].lastLocal = VMP_OFFSET(sym);
    } else {
	/*
	 * Top-level variable scope inherits the lastLocal value of the
	 * parameter scope...
	 */
	scopeStack[scopeTop].lastLocal = scopeStack[scopeTop-1].lastLocal;
    }

    /*
     * Now push the scope onto the stack.
     */
    scopeStack[scopeTop].segIndex = segIndex;
    scopeStack[scopeTop++].scope = sym;

    VMUnlockDirty(symbols, VMP_BLOCK(sym));
}


/***********************************************************************
 *				BorlandEnterLocalAddrSymbol
 ***********************************************************************
 * SYNOPSIS:	    Enter a non-global address-bearing symbol into the
 *	    	    current scope.
 * CALLED BY:	    BorlandProcessLocals
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandEnterLocalAddrSymbol(const char *file,
			    ID    	name,
			    byte    	symType,
			    word    	typeIndex,
			    byte    	**bpPtr)
{
    /*
     * bp points to:
     *	- containing group (index), if any
     *	- containing segment (index)
     *	- offset (word)
     */
    BorlandSegData  	*sdata;
    VMPtr   	    	sym;
    ObjSym  	    	*os;
    byte    	    	*bp = *bpPtr;

    /*
     * Get the segment to which the symbol belongs.
     */
    MSObj_GetIndex(bp);		/* Ignore the group, man */
    sdata = BorlandGetSegData(MSObj_GetIndex(bp));
    
    /*
     * Enter the symbol into the segment, appropriately.
     */
    sym = BorlandEnterAddressSymbol(name,
				    MSObj_GetWordImm(bp),
				    symType,
				    0,
				    sdata);

    /*
     * Save away the type index. This works for procedures, too, as this
     * writes into the proc.flags field...
     */
    os = (ObjSym *)VMLockVMPtr(symbols, sym, (MemHandle *)NULL);
    os->u.variable.type = typeIndex;
    VMUnlockDirty(symbols, VMP_BLOCK(sym));

    /*
     * Now link the thing into the current scope, if any.
     */
    BorlandLinkLocal(sym);

    *bpPtr = bp;
}

/***********************************************************************
 *				BorlandEnterLocalStackSymbol
 ***********************************************************************
 * SYNOPSIS:	    Enter a local variable that's in the stack frame,
 *	    	    not static.
 * CALLED BY:	    BorlandProcessLocals
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandEnterLocalStackSymbol(const char *file,
			     ID   	name,
			     byte   	symType,
			     word   	typeIndex,
			     short   	offset)
{
    VMPtr   	    sym;
    ObjSym  	    *os;
    ObjSym  	    *sos;
    ObjSymHeader    *osh;

    if (scopeTop <= 0) {
	/*
	 * Turbo Assembler likes to put arguments into the global scope unless
	 * one bends over backwards. We have no way to express this, however,
	 * so we just drop these warped things on the floor.
	 *  	    -- ardeb 9/3/92
	 */
	return;
    }
    
    os = BorlandAllocLocal(VMP_BLOCK(scopeStack[scopeTop-1].scope),
			   (ObjSym **)NULL,
			   &sym);
    /*
     * Make sure there isn't already a symbol of the same name in the scope,
     * as happens when parameter variables are duplicated in the variable scope
     * by turbo C.
     */
    osh = (ObjSymHeader *)((genptr)os - VMP_OFFSET(sym));
    sos = (ObjSym *)((genptr)osh + VMP_OFFSET(scopeStack[scopeTop-1].scope));
    if (sos->u.scope.first != VMP_OFFSET(scopeStack[scopeTop-1].scope)) {
	ObjSym	    *los;
	
	for (los = (ObjSym *)((genptr)osh + sos->u.scope.first);
	     los != sos;
	     los = (ObjSym *)((genptr)osh + los->u.procLocal.next))
	{
	    if (los->name == name) {
		/*
		 * De-allocate the local symbol again.
		 * 2/21/92: override the existing symbol type with the
		 * passed one, in case they're different (e.g. when
		 * a parameter is converted to a register variable,
		 * or when a parameter that is declared using K&R-style
		 * is accidentally redeclared by the compiler.) 
		 */
		if (los->type != symType
			|| los->u.localVar.type != typeIndex) {
		    los->type = symType;
		    los->u.localVar.type = typeIndex;
		    los->u.localVar.offset = offset;
		}
		assert(los->u.localVar.type == typeIndex);
		assert(los->u.localVar.offset == offset);
		
		osh->num -= 1;
		VMUnlockDirty(symbols, VMP_BLOCK(sym));
		return;
	    }
	}
    }
    
    /*
     * No duplication here, so fill in the fields of the symbol and link the
     * beast into the chain.
     */
    os->name = name;
    os->type = symType;
    os->flags = 0;
    os->u.localVar.offset = offset;
    os->u.localVar.type = typeIndex;

    VMUnlockDirty(symbols, VMP_BLOCK(sym));
    BorlandLinkLocal(sym);
}
    
/*********************************************************************
 *			BorlandCreateLocalTypeSymbol
 *********************************************************************
 * SYNOPSIS: 	    Handle the creation of a typedef within a local
 *	    	    scope.
 * CALLED BY:	    BorlandProcessLocals
 * RETURN:  	    nothing
 * SIDE EFFECTS:    name of type in BorlandType may be altered.
 *
 * STRATEGY:
 *		if BorlandType record exists and it's for a struct/union/
 *		 enum, create a symbol at the end of the block for the type,
 *		 and change the ObjType to point to the new symbol
 *		else
 *		 create a symbol in the "others" block.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	9/18/92		Initial version			     
 * 
 *********************************************************************/
static void
BorlandCreateLocalTypeSymbol(const char *file,
			     ID	    	name,	    /* Name of new type */
			     word   	typeIndex)  /* Index of type to which
						     * this is mapped */
{
    ObjSym	*os;

    if (typeIndex < Vector_Length(borlandTypes)) {
	/*
	 * Type descriptor already seen for this thing. See if it's a
	 * structured type to which we should lend this typedef's name.
	 */
	BorlandType *btp;

	btp = BorlandGetTypeData(typeIndex);

	if ((btp->desc[0] == BTID_ENUM) ||
	    (btp->desc[0] == BTID_STRUCT) ||
	    (btp->desc[0] == BTID_UNION) ||
	    (btp->desc[0] == BTID_VLSTRUCT) ||
	    (btp->desc[0] == BTID_VLUNION))
	{
	    if (borlandMajorVersion >= 3) {
		/*
		 * Symbol hasn't been created for the thing yet, so we can
		 * just change the name it will use later.
		 * XXX: WE LOSE ANY NON-NAMELESS ID HERE...
		 */
		OTYPE_ID_TO_STRUCT(name, &btp->ot);
		return;
	    } else {
		/*
		 * Allocate a symbol at the end of the block for the beast.
		 */
		os = (ObjSym *)VMLockVMPtr(symbols,
					   MAKE_VMP(btp->ot.words[1],
						    btp->ot.words[0]),
					   (MemHandle *)NULL);

		if (os->flags & OSYM_NAMELESS) {
		    /*
		     * The existing type is nameless, so replace it with
		     * the name of the typedef, as that's far more useful.
		     */
		    os->name = name;
		    os->name = name;
		    VMUnlockDirty(symbols, btp->ot.words[1]);
		    return;
		}
		/*
		 * Existing type isn't nameless, so we must leave it be.
		 * We don't have a type block associated with the block
		 * containing the structured type, so we need to add the
		 * symbol to the end of the "others" block instead, with
		 * the type being the index of the named type that we
		 * may not override.
		 */
		VMUnlock(symbols, btp->ot.words[1]);
	    }
	}
    }
    
    if (others == 0) {
	others = BorlandAllocAndInitSymBlock();
    }
    os = BorlandAllocLocal(others, (ObjSym **)NULL, (VMPtr *)NULL);
    
    os->name = name;
    os->type = OSYM_TYPEDEF;
    os->flags = 0;
    os->u.typeDef.type = typeIndex;

    VMUnlockDirty(symbols, others);
}

/***********************************************************************
 *				BorlandProcessLocals
 ***********************************************************************
 * SYNOPSIS:	    Process the declaration of a bunch of local symbols
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessLocals(const char *file,
		     word   reclen,
		     byte   *bp)
{
    ID	    	name;
    word    	typeIndex;
    byte    	*endRecord;

    endRecord = bp + reclen;

    while (bp < endRecord) {
	name = ST_Enter(symbols, strings, (char *)bp+1, *bp);
	bp += *bp + 1;
	typeIndex = MSObj_GetIndex(bp);

    again:
	switch(*bp++) {
	    case BSC_STATIC:    /* A static variable:
				 *  - containing group (index), if any
				 *  - containing segment (index)
				 *  - offset (word)
				 */
		BorlandEnterLocalAddrSymbol(file, name, OSYM_VAR,
					    typeIndex, &bp);
		break;
	    case BSC_ABSOLUTE:  /* A variable in an absolute segment:
				 *  - containing segment (index); the
				 *    segment must be an absolute one
				 *  - offset (word)
				 */
		assert(0);  /* Need to make BELAS optionally "skip" group */
		break;
	    case BSC_PARAM:
	    case BSC_AUTO:	    /* Local (auto) variable/parameter:
				     *  - signed offset from BP (word)
				     */
		BorlandEnterLocalStackSymbol(file, name, OSYM_LOCVAR,
					     typeIndex, MSObj_GetWordImm(bp));
		break;
		
	    case BSC_PASVAR:    /* Pascal VAR parameter:
				 *  - signed offset from BP (word);
				 *    this location on the stack points
				 *    to the actual value.
				 */
		assert(0);		/* Need to change type to ptr... */
		break;
	    case BSC_REGPARAM:
	    case BSC_REGVAR:    /* Register variable/parameter:
				 *  - register id (byte)
				 */
	    {
		word    offset = 0;
		
		if (*bp > BR_LAST_REG) {
		    Notify(NOTIFY_ERROR,
			   "%s: unhandled register number %d",
			   file, *bp);
		} else if (*bp >= BR_DWORD_REG_START) {
		    Notify(NOTIFY_ERROR,
			   "%s: unhandled register number %d",
			   file, *bp);
		} else if (*bp >= BR_SEG_REG_START) {
		    offset = (*bp - BR_SEG_REG_START) + OSYM_REG_ES;
		} else if (*bp >= BR_BYTE_REG_START) {
		    offset = (*bp - BR_BYTE_REG_START) + OSYM_REG_AL;
		} else {
		    offset = (*bp - BR_WORD_REG_START) + OSYM_REG_AX;
		}
		bp += 1;
		BorlandEnterLocalStackSymbol(file, name, OSYM_REGVAR,
					     typeIndex, offset);
		break;
	    }
	    case BSC_CONSTANT:  /* A constant:
				 *  - value (dword)
				 */
		assert(0);		/* What generates this? */
		break;
		
		
	    case BSC_TYPEDEF:   /* A typedef:
				 *  - nothing extra
				 */
		/*
		 * if BorlandType record exists and it's for a struct/union/
		 *  enum, create a symbol at the end of the block for the type,
		 *  and change the ObjType to point to the new symbol
		 * else
		 *  create a symbol in the "others" block.
		 */
                BorlandCreateLocalTypeSymbol(file, name, typeIndex);
		break;
	    case BSC_TAG:	    /* A struct/union/enum tag:
				     *  - nothing extra
				     */
		/* I don't think I need to do anything else with this, as the
		 * tag should have been in the initial type definition record
		 * and have been handled there... */
		break;
		
	    case BSC_GLOBAL_FUNCTION:	/* Global function:
					 *  - group (index)
					 *  - segment (index)
					 *  - offset (word)
					 * WHY IS THIS HERE? It's put out by
					 * Turbo Assembler, which has already
					 * put out a PUBDEF and a
					 * BCC_PUBLIC_TYPE record for the damn
					 * thing. There doesn't seem to be any
					 * more information...
					 */
		/* I don't need to do anything else here but skip it... */
		(void)MSObj_GetIndex(bp); /* group */
		(void)MSObj_GetIndex(bp); /* segment */
		bp += 2;	    	  /* offset */
		break;
	    case BSC_FUNCTION:  /* Static function:
				 *  - group (index)
				 *  - segment (index)
				 *  - offset (word)
				 */
		BorlandEnterLocalAddrSymbol(file, name, OSYM_PROC,
					    typeIndex, &bp);
		break;
	    case BSC_OPTIMIZED:	/* Variable's been optimized:
				 *  - # entries in range list (index)
				 *  - entries of this form:
				 *  	- start of range (word); offset
				 *	  from outermost enclosing
				 *	  scope (i.e. proc start)
				 *  	- end of range (word)
				 *  	- regular local symbol
				 *	  record
				 */
		if (MSObj_GetIndex(bp) != 1) {
		    Notify(NOTIFY_ERROR,
			   "%s: cannot cope with more than one live range for variable %i",
			   file, name);
		    return;
		} else {
		    /*
		     * Pretend the range is actually for the entire function,
		     * since the documentation and object files don't seem to
		     * correspond in any meaningful fashion.
		     */
		    bp += 4;	/* Skip start & end of range */

		    /*
		     * Process the sole range definition as if it were the
		     * actual definition for the symbol.
		     */
		    goto again;
		}
	    default:
		Notify(NOTIFY_ERROR,
		       "%s: unhandled Borland local symbol type %02x\n",
		       file, bp[-1]);
		return;
	}
	/*
	 * Skip source file index and line number if version >= 3.0
	 */
	if ((borlandMajorVersion >= 3) && MSObj_GetIndex(bp)) {
	    bp += 2;		/* Skip line # if source index non-zero */
	}

	/*
	 * If version >= 3.1, then we'll need to skip over the browser
	 * information. The way to do that is this:
	 *
	 * The first word is an OMF index. If it is non-zero, then immediately
	 * after it will be another OMF index. If that is also non-zero, we
	 * enter the following loop:
	 *
	 * If the first character is 0x00, skip it and exit the loop.
	 * If the first character is < 0xf0, skip it and the following byte,
	 *   and restart the loop.
	 * If the first character is >= 0xf0, skip it, a character, an OMF, and
	 *   another word, then restart the loop.
	 * 
	 * At the end of the loop, skip 2 0x00's
	 */

	if ((borlandMajorVersion > 3) || ((borlandMajorVersion == 3) &&
					  (borlandMinorVersion >= 1))) {
	/*
	 * This doesn't really seem to pan out, so we'll error if we detect
	 * any browser info for now...
	 *
	    if ((word)*bp == 0) {
		bp++;
	    } else {
		bp++;
		if ((word)*bp == 0) {
		    bp++;
		} else {
		    bp++;
		    while(*bp != 0) {
			if (*bp >= 0xf0) {
			    bp += 6;
			} else {
			    bp += 2;
			}
		    }
		    bp += 2;
		}
	    }
	 *
	 */

	    if ((word)*bp == 0) {
		bp++;
	    } else {
		Notify(NOTIFY_ERROR,
		       "%s: glue can't deal with browser information. Please recompile this file without passing the -R flag to BCC, and try again.\n", file);
	    }
	}
    }
}


/***********************************************************************
 *				BorlandProcessEndScope
 ***********************************************************************
 * SYNOPSIS:	    Close the current variable scope.
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessEndScope(const char *file,
		       word 	reclen,
		       byte 	*bp)
{
    assert(scopeTop != 0);

    /*
     * Pop the current scope.
     */
    scopeTop--;

    if (scopeTop > 1) {
	/*
	 * A real internal-scope to be ended, here
	 */
	VMPtr	    	endScope;
	BorlandSegData	*sdata;

	sdata = BorlandGetSegData(scopeStack[scopeTop].segIndex);
	endScope = BorlandEnterAddressSymbol(NullID,
					     MSObj_GetWordImm(bp),
					     OSYM_BLOCKEND,
					     0,
					     sdata);
	BorlandLinkLocal(endScope);
    } else if (scopeTop == 1) {
	/*
	 * The parameter scope inherits the lastLocal for the top-level
	 * variable scope, since they are one and the same...
	 */
	scopeStack[scopeTop-1].lastLocal = scopeStack[scopeTop].lastLocal;
    }
}
	

/***********************************************************************
 *				BorlandProcessSourceFile
 ***********************************************************************
 * SYNOPSIS:	    Set the name of the source file from which all
 *	    	    following LINNUM records come.
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessSourceFile(const char *file,
			 word	reclen,
			 byte	*bp)
{
    word    	index;

    index = MSObj_GetIndex(bp);

#if defined(_MSDOS)
{
    char    *cp;
    int	    i;

    /* to make sure that filenames look alike no matter what compiler
     * we are upcasing the filenames and translating backslashes to
     * forward slashes because its too hard to enter backslashes in
     * swat as the TCL interpreter gets to the first 

     * this is being changed to treanslate forward slashes to backslashes
     * so that all filenames from the PC will be with backslashes in the
     * SYM files for consistanccy with ESP, BORLAND and GOC.
     */
    i = *bp;
    cp = (char *)bp+1;
    while (i--)
    {
	if (islower(*cp)) {
	    *cp = toupper(*cp);
	}
	if (*cp == '/')
	{
	    *cp = '\\';
	}
	cp++;
    }
}
#endif


    if (index == 0) {
	msobj_CurFileName = ST_Enter(symbols, strings, (char *)bp+1, *bp);

	/*
	 * Add the name to the end of the list of known source files, for
	 * the next time the thing is encountered.
	 */
	Vector_Add(borlandSources, VECTOR_END, (Address)&msobj_CurFileName);
	/* ignore modification date/time */
    } else if (index < Vector_Length(borlandSources)) {
	Vector_Get(borlandSources, index, (Address)&msobj_CurFileName);
    } else {
	/*
	 * The compiler isn't playing by its own rules. Ostensibly, if I
	 * get a non-zero index, it means I've already got the file,
	 * but the object files produced by BCC 3.1, at least, always stick
	 * the index in, whether I've seen the thing or not. To cope with
	 * this, assume there's a name after the index and enter it under
	 * the given index into the vector.
	 */
	msobj_CurFileName = ST_Enter(symbols, strings, (char *)bp+1, *bp);

	Vector_Add(borlandSources, index, (Address)&msobj_CurFileName);
    }
}

	

/***********************************************************************
 *				BorlandProcessDependency
 ***********************************************************************
 * SYNOPSIS:	    Deal with a dependency record (ignored)
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessDependency(const char *file,
			 word	reclen,
			 byte	*bp)
{
}

/***********************************************************************
 *				BorlandProcessCompilerDesc
 ***********************************************************************
 * SYNOPSIS:	    Deal with the specification of how the compiler was
 *	    	    invoked
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessCompilerDesc(const char *file,
			   word	reclen,
			   byte	*bp)
{
    /*
     * If flag set to indicate compiler placed underscores before global
     * variables, flag this so we know to strip them off again.
     */
    if (bp[1] & BCDF_UNDERSCORES) {
	borlandUnderscores = TRUE;
    }
}

/***********************************************************************
 *				BorlandProcessPublicByName
 ***********************************************************************
 * SYNOPSIS:	    Deal with the declaration of the types of public
 *	    	    symbols given their names
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessPublicByName(const char *file,
			   word	reclen,
			   byte	*bp)
{
    byte    	*endRecord = bp + reclen;

    while (bp < endRecord) {
	ID  	name = ST_Enter(symbols, strings, (char *)bp+1, *bp);
	int 	i;

	/*
	 * Look through all the public symbols we've encountered so far
	 * to find the one to which we should give this beloved type
	 * index.
	 */
	bp += *bp + 1;

	for (i = Vector_Length(borlandSegs)-1; i > 0; i--) {
	    BorlandSegData  *sdata;
	    VMBlockHandle   cur, next;

	    sdata = BorlandGetSegData(i);

	    for (cur = sdata->addrH; cur != 0; cur = next) {
		ObjSymHeader    *osh;
		ObjSym	    	*os;
		int	    	j;
		
		osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);
		os = ObjFirstEntry(osh, ObjSym);

		for (j = osh->num; j > 0; j--, os++) {
		    if ((os->name == name) && (os->flags & OSYM_GLOBAL)) {
			/*
			 * Store the type index away.
			 */
			os->u.variable.type = MSObj_GetIndex(bp);
			/*
			 * Unlock and dirty the block and get out of the
			 * loop prematurely
			 */
			VMUnlockDirty(symbols, cur);
			break;
		    }
		}
		if (j > 0) {
		    /*
		     * => exited the loop early, so we found the symbol.
		     */
		    break;
		} else {
		    /*
		     * Save the next block to lock down and unlock the current
		     * one.
		     */
		    next = osh->next;
		    VMUnlock(symbols, cur);
		}
	    }
	    if (cur != 0) {
		/*
		 * If got out with cur non-zero, means we broke out of the
		 * loop and our work with this symbol is done.
		 */
		break;
	    }
	}
	assert (i >= 0);
	bp += 1;		/* Skip frame-pointer flags */
	/*
	 * Skip over source file index & line number, if >= 3.0
	 */
	if (borlandMajorVersion >= 3) {
	    (void)MSObj_GetIndex(bp);
	    bp += 2;
	}
    }
}

/***********************************************************************
 *				BorlandProcessExternalByName
 ***********************************************************************
 * SYNOPSIS:	    Deal with the declaration of the types of external
 *	    	    symbols given their names
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessExternalByName(const char *file,
			     word   reclen,
			     byte   *bp)
{
    byte    	    *endRecord = bp + reclen;
    ObjSymHeader    *osh;

    assert(VMP_BLOCK(lastExternal) != 0);

    osh = (ObjSymHeader *)VMLock(symbols, VMP_BLOCK(lastExternal),
				 (MemHandle *)NULL);
    while (bp < endRecord) {
	ID  	name = ST_Enter(symbols, strings, (char *)bp+1, *bp);
	ObjSym	*os;
	int 	i;

	bp += *bp + 1;

	for (i = osh->num, os = ObjFirstEntry(osh, ObjSym); i > 0; i--, os++) {
	    if (os->name == name) {
		break;
	    }
	}

	assert(i > 0);

	os->u.variable.type = MSObj_GetIndex(bp);

	/*
	 * Skip over source file index & line number, if >= 3.0
	 */
	if (borlandMajorVersion >= 3) {
	    (void)MSObj_GetIndex(bp);
	    bp += 2;
	}
    }

    VMUnlockDirty(symbols, VMP_BLOCK(lastExternal));
}

/***********************************************************************
 *				BorlandInit
 ***********************************************************************
 * SYNOPSIS:	    Initialize the module
 * CALLED BY:	    Borland_Check
 * RETURN:	    nothing
 * SIDE EFFECTS:    vectors will be created and initialized, if appropriate.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/20/91	Initial Revision
 *
 ***********************************************************************/
static void
BorlandInit(void)
{
    static BorlandType	predefs[] = {
    {OTYPE_MAKE_VOID(), 0},	/* 0 */
    {OTYPE_MAKE_VOID(), 0},   	/* BT_VOID */
    {OTYPE_MAKE_CHAR(1), 1}, 	/* BT_CHAR */
    {OTYPE_MAKE_VOID(), 0},	/* 3 */
    {OTYPE_MAKE_SIGNED(2), 2},  /* BT_SHORT */
    {OTYPE_MAKE_VOID(), 0},	/* 5 */
    {OTYPE_MAKE_SIGNED(4), 4},  /* BT_LONG */
    {OTYPE_MAKE_VOID(), 0},	/* 7 */
    {OTYPE_MAKE_INT(1), 1},    	/* BT_BYTE */
    {OTYPE_MAKE_VOID(), 0},	/* 9 */
    {OTYPE_MAKE_INT(2), 2},    	/* BT_WORD */
    {OTYPE_MAKE_VOID(), 0},	/* 11 */
    {OTYPE_MAKE_INT(4), 4},    	/* BT_DWORD */
    {OTYPE_MAKE_VOID(), 0},	/* 13 */
    {OTYPE_MAKE_FLOAT(4), 4},   /* BT_FLOAT */
    {OTYPE_MAKE_FLOAT(8), 8},   /* BT_DOUBLE */
    {OTYPE_MAKE_FLOAT(10), 10},	/* BT_LONG_DOUBLE */
    {OTYPE_MAKE_FLOAT(6), 6},   /* BT_PASC_FLOAT */
    {OTYPE_MAKE_INT(1), 1},    	/* BT_PASC_BOOL */
    {OTYPE_MAKE_CHAR(1), 1}, 	/* BT_PASC_CHAR */
    {OTYPE_MAKE_VOID(), 0},	/* 20 */
    {OTYPE_MAKE_SIGNED(8), 8},  /* BT_SIGNED_RANGE */
    {OTYPE_MAKE_INT(8), 8},   	/* BT_UNSIGNED_RANGE */
    {BORLAND_CONVERTED_LONG_TYPE, 10, {{OTYPE_MAKE_ARRAY(10), BT_BYTE}}}
    	    	    	    	    	    	    	/* BT_TBYTE */
    };
    int	    	    	i;

    /*
     * Create our three vectors
     */
    borlandSegs = Vector_Create(sizeof(BorlandSegData),
				ADJUST_ADD,
				10,
				10);
    borlandSources = Vector_Create(sizeof(ID),
				   ADJUST_ADD,
				   10,
				   10);
    borlandTypes = Vector_Create(sizeof(BorlandType),
				 ADJUST_MULTIPLY,
				 BT_LAST_PREDEF+1,
				 2);

    borlandLocalStatics = Vector_Create(sizeof(BorlandLocalStatic),
					ADJUST_ADD,
					10,
					10);

    borlandMembers = Vector_Create(sizeof(BorlandMembers),
				   ADJUST_MULTIPLY,
				   10,
				   2);
    /*
     * Initialize all the pre-defined types
     */
    for (i = sizeof(predefs)/sizeof(predefs[0]);
	 i > 0;
	 i--)
    {
	Vector_Add(borlandTypes, i-1, (Address)&predefs[i-1]);
    }
}


/***********************************************************************
 *				Borland_Check
 ***********************************************************************
 * SYNOPSIS:	    See if we want to consume the passed object record.
 * CALLED BY:	    Pass1MS_Load, Pass2MS_Load
 * RETURN:	    TRUE if we've processed the record
 * SIDE EFFECTS:    many and varied :)
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/19/91	Initial Revision
 *
 ***********************************************************************/
int
Borland_Check(const char    *file,
	      byte	    rectype,
	      word	    reclen,
	      byte	    *bp,
	      int	    pass)   	/* Pass #: 1 if pass 1, 2 if pass 2 */
{
    if (borlandSegs == NullVector) {
	BorlandInit();
    }
    
    /*
     * We don't need to do anything on pass 2 here.
     */
    if (pass != 1) {
	return(FALSE);
    }

    switch(rectype) {
	case MO_PUBDEF:
	case MO_CVPUB:
	    BorlandProcessPublic(file, rectype, reclen, bp);
	    break;
	case MO_EXTDEF:
	    BorlandProcessExternal(file, rectype, reclen, bp);
	    break;
	case MO_COMENT:
	    /*
	     * The biggie.
	     */
	    switch(bp[1]) {
		case BCC_EXTERNAL_TYPE:
		    BorlandProcessExternalType(file, reclen-2, bp+2);
		    break;
		case BCC_PUBLIC_TYPE:
		    BorlandProcessPublicType(file, reclen-2, bp+2);
		    break;
		case BCC_STRUCT_MEMBERS:
		    BorlandProcessStructMembers(file, reclen-2, bp+2);
		    break;
		case BCC_TYPEDEF:
		    BorlandProcessTypedef(file, reclen-2, bp+2);
		    break;
		case BCC_ENUM_MEMBERS:
		    BorlandProcessEnumMembers(file, reclen-2, bp+2);
		    break;
		case BCC_BEGIN_SCOPE:
		    BorlandProcessBeginScope(file, reclen-2, bp+2);
		    break;
		case BCC_LOCALS:
		    BorlandProcessLocals(file, reclen-2, bp+2);
		    break;
		case BCC_END_SCOPE:
		    BorlandProcessEndScope(file, reclen-2, bp+2);
		    break;
		case BCC_SOURCE_FILE:
		    BorlandProcessSourceFile(file, reclen-2, bp+2);
		    break;
		case BCC_DEPENDENCY:
		    BorlandProcessDependency(file, reclen-2, bp+2);
		    break;
		case BCC_COMPILER_DESC:
		    BorlandProcessCompilerDesc(file, reclen-2, bp+2);
		    break;
		case BCC_EXTERNAL_BY_NAME:
		    BorlandProcessExternalByName(file, reclen-2, bp+2);
		    break;
		case BCC_PUBLIC_BY_NAME:
		    BorlandProcessPublicByName(file, reclen-2, bp+2);
		    break;
		case BCC_VERSION:
		    /*
		     * Don't care about the minor version, just the major.
		     * XXX: ensure it's a supported version.
		     */
		    borlandMajorVersion = bp[2];
		    borlandMinorVersion = bp[3];
		    break;
	    }
	    break;
	case MO_COMDEF:
	    /*
	     * I don't do anything with these in CV, so I'll put off doing
	     * anything with them here for now, too.
	     */
	    /*FALLTHRU*/
	default:
	    /*
	     * Everything else we ignore.
	     */
	    return(FALSE);
    }

    /*
     * If we get here, the record's been consumed.
     */
    return(TRUE);
}
    
static void BorlandEnsureTypeConverted(int i, Boolean isLMem);

/***********************************************************************
 *				BorlandCopyTypeDesc
 ***********************************************************************
 * SYNOPSIS:	    Convert a type index into a series of ObjType
 *	    	    records, if necessary, and return the word to store
 *	    	    in place of the type index.
 * CALLED BY:	    ?
 * RETURN:	    type word
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static word
BorlandCopyTypeDesc(int	    	    index,  	/* Index of type to copy */
		    VMBlockHandle   types, 	/* Block in which to
						 * place ObjType descriptors */
		    Boolean 	    isLMem)
{
    BorlandType	*btp;
    word    	retval;

    BorlandEnsureTypeConverted(index, isLMem);

    btp = BorlandGetTypeData(index);

    assert(btp->shortType != 0);

    if (btp->shortType & OTYPE_SPECIAL) {
	retval = btp->shortType;
    } else {
	ObjType	    *otp;

	if (OTYPE_IS_PTR(btp->ot.words[0])) {
	    word	    base;
	    
	    base = BorlandCopyTypeDesc(btp->ot.words[1], types, isLMem);
	    if (base == OTYPE_MAKE_VOID()) {
		retval = OTYPE_MAKE_VOID_PTR(btp->ot.words[0] & OTYPE_DATA);
	    } else {
		otp = MSObj_AllocType(types, &retval);
		/* Non-special token for pointer contains the pointer type
		 * in OTYPE_DATA, but not OTYPE_TYPE. */
		otp->words[0] = (btp->ot.words[0] & ~OTYPE_TYPE);
		otp->words[1] = base;
	    }
	} else if (OTYPE_IS_ARRAY(btp->ot.words[0])) {
	    word	    base;
	    BorlandType     *baseBTP;
	    
	    /*
	     * Find the BorlandType record for the base type so we know
	     * how big each element is.
	     */
	    baseBTP = BorlandGetTypeData(btp->ot.words[1]);
	    
	    assert((btp->size % baseBTP->size) == 0);

	    if (isLMem &&
		((btp->size / baseBTP->size) == 1) &&
		(baseBTP->shortType == OTYPE_MAKE_INT(2)))
	    {
		/*
		 * This is the hacked way we have to define chunk handles in
		 * bcc 3.1 to ensure they end up in the proper segment. Return
		 * the type as a void near * instead.
		 */
		retval = OTYPE_MAKE_VOID_PTR(OTYPE_PTR_NEAR);
	    } else {
		/*
		 * Copy in descriptors for the base type.
		 */
		base = BorlandCopyTypeDesc(btp->ot.words[1], types, isLMem);
		
		/*
		 * Create the descriptor for the array itself.
		 */
		
		retval = MSObj_CreateArrayType(types, base,
					       btp->size / baseBTP->size);
	    }
	} else {
	    /*
	     * Must be structured.
	     */
	    assert((btp->desc[0] == BTID_VLSTRUCT)  ||
		   (btp->desc[0] == BTID_STRUCT) ||
		   (btp->desc[0] == BTID_VLUNION) ||
		   (btp->desc[0] == BTID_UNION) ||
		   (btp->desc[0] == BTID_ENUM));

	    otp = MSObj_AllocType(types, &retval);
	    *otp = btp->ot;
	}
	VMUnlockDirty(symbols, types);
    }

    return(retval);
}

/***********************************************************************
 *				BorlandDefineFunction
 ***********************************************************************
 * SYNOPSIS:	    Take a function type and use it to flesh out the
 *	    	    definition of an OSYM_PROC symbol.
 * CALLED BY:	    BorlandConvertSymbolTypes
 * RETURN:	    new address of passed symbol, if the symbol block
 *	    	    	moved
 *	    	    new address of the symbol block itself
 * SIDE EFFECTS:    block may move
 *
 * STRATEGY:
 *	    In the near future, this should take the return type stored
 *	    	in the passed type description and create a RETURN_TYPE
 *	    	symbol in the procedure's scope
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 3/92		Initial Revision
 *
 ***********************************************************************/
static ObjSym *
BorlandDefineFunction(ObjSym	    *os,
		      ObjSymHeader  **oshPtr,
		      BorlandType   *btp)
{
    word    	returnType;
    byte    	*bp;
    
    os->type = OSYM_PROC;

    bp = &btp->desc[1];		/* skip BTID_FUNCTION, of course */
    returnType = MSObj_GetIndex(bp);
    switch (*bp) {
	case 2:			/* near fastcall */
	case 0:			/* near C */
	    os->u.proc.flags = OSYM_NEAR;
	    break;
	case 1:			/* near Pascal */
	    os->u.proc.flags = OSYM_NEAR | OSYM_PROC_PASCAL;
	    break;
	case 3:			/* unused */
	default:
	    assert(0);
	    break;
	case 6:			/* far fastcall */
	case 7:			/* interrupt */
	case 4:			/* far C */
	    os->u.proc.flags = 0;
	    break;
	case 5:			/* far Pascal */
	    os->u.proc.flags = OSYM_PROC_PASCAL;
	    break;
    }

    return(os);
}

/***********************************************************************
 *				BorlandConvertSymbolBlock
 ***********************************************************************
 * SYNOPSIS:	    Convert the types for all the symbols in a single block.
 * CALLED BY:	    BorlandConvertSymbolTypes, BorlandEnsureTypeConverted
 * RETURN:	    new types block, if one allocated.
 *	    	    block is not marked dirty, though it may have been
 *	    	    	dirtied.
 * SIDE EFFECTS:    guess.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 3/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandConvertSymbolBlock(VMBlockHandle	    cur,
			  ObjSymHeader	    *osh,
			  VMBlockHandle	    *typesPtr,
			  Boolean   	    isLMem)
{
    VMBlockHandle   types = *typesPtr;
    ObjSym  	    *os;
    word    	    fieldOff = 0;
    int	    	    i;
    Boolean 	    isUnion = FALSE;

    if (types != 0) {
	/*
	 * Make sure types not too big
	 */
	word    size;
	
	VMInfo(symbols, types, &size, (MemHandle *)NULL, (VMID *)NULL);
	if (size > OBJ_MAX_TYPES) {
	    types = 0;
	}
    }
    
    /*
     * Allocate a new block for type descriptions, if required.
     */
    if (osh->types != 0) {
	types = osh->types;
    } else if (types == 0) {
	ObjTypeHeader   *oth;
	
	types = VMAlloc(symbols,
			sizeof(ObjTypeHeader) + 16 * sizeof(ObjType),
			OID_TYPE_BLOCK);
	oth = (ObjTypeHeader *)VMLock(symbols, types, (MemHandle *)NULL);
	oth->num = 0;
	VMUnlockDirty(symbols, types);
    }
    
    osh->types = types;
    os = ObjFirstEntry(osh, ObjSym);
    
    for (i = osh->num; i > 0; i--, os++) {
	switch(os->type) {
	    case OSYM_UNION:
		isUnion = TRUE;
		/*FALLTHRU*/
	    case OSYM_STRUCT:
		/*
		 * Reset fieldOff to 0 for calculating the offset of the
		 * fields that follow.
		 */
		fieldOff = 0;
		break;
	    case OSYM_TYPEDEF:  /* typeDef.type */
		/*
		 * Convert index to type description
		 * XXX: at some point, we'd like (I think) to replace the
		 * BorlandType record with this symbol's name, but for
		 * now we'll just punt.
		 */
		os->u.typeDef.type = BorlandCopyTypeDesc(os->u.typeDef.type,
							 types, isLMem);
		break;
	    case OSYM_FIELD:    /* sField.type */
		/*
		 * Convert index to type description, set field offset,
		 * if not -1, and advance fieldOff.
		 */
		if (os->flags & OSYM_UNDEF) {
		    if (os->u.sField.offset == 0xffff) {
			os->u.sField.offset = fieldOff;
		    } else {
			fieldOff = os->u.sField.offset;
		    }
		    if (!isUnion) {
			fieldOff += BorlandGetTypeData(os->u.sField.type)->size;
		    }
		    os->u.sField.type =
			BorlandCopyTypeDesc(os->u.sField.type, types, isLMem);
		    os->flags &= ~OSYM_UNDEF;
		}
		break;
	    case OSYM_BITFIELD:
		/*
		 * Set sField.offset. if next symbol not bitfield, or
		 * its bit offset is less, advance fieldOff properly.
		 */
		os->u.sField.offset = fieldOff;
		
		if (!isUnion &&
		    ((i == 1) || (os[1].type != OSYM_BITFIELD) ||
		     ((os[1].u.sField.type & OTYPE_BF_OFFSET) <=
		      (os->u.sField.type & OTYPE_BF_OFFSET))))
		{
		    int fieldWidth;
		    
		    fieldWidth =
			((os->u.sField.type & OTYPE_BF_OFFSET) >>
			 OTYPE_BF_OFFSET_SHIFT) +
			     ((os->u.sField.type & OTYPE_BF_WIDTH) >>
			      OTYPE_BF_WIDTH_SHIFT);
		    if (fieldWidth > 24) {
			fieldOff += 4;
		    } else if (fieldWidth > 16) {
			fieldOff += 3;
		    } else if (fieldWidth > 8) {
			fieldOff += 2;
		    } else {
			fieldOff += 1;
		    }
		}
		/*
		 * Switch the symbol back to being a field
		 */
		os->type = OSYM_FIELD;
		break;
	    case OSYM_VAR:	    /* variable.type */
		/*
		 * Convert to OSYM_CHUNK if in lmem handle segment?
		 *
		 * If the variable's "type" is near or far, it means the thing
		 * is actually a label, not a variable...
		 *
		 * XXX: WHAT IF THE THING IS A LOCAL LABEL? IF OSYM_GLOBAL
		 * IS CLEAR, WE SHOULD LINK IT INTO THE LIST OF LABELS FOR
		 * THE PROCEDURE...
		 */
		os->u.variable.type =
		    BorlandCopyTypeDesc(os->u.variable.type, types, isLMem);
		if (os->u.variable.type == OTYPE_MAKE_NEAR()) {
		    os->type = OSYM_LABEL;
		    os->u.label.near = TRUE;
		} else if (os->u.variable.type == OTYPE_MAKE_FAR()) {
		    os->type = OSYM_LABEL;
		    os->u.label.near = FALSE;
		}
		break;
	    case OSYM_LOCVAR:   /* localVar.type */
	    case OSYM_REGVAR:   /* localVar.type */
		os->u.localVar.type =
		    BorlandCopyTypeDesc(os->u.localVar.type, types, isLMem);
		break;
	    case OSYM_PROC:	    /* proc.flags */
		/*
		 * This beast holds its return/call type index in the flags
		 * word. We can just fall into the handler for
		 * OSYM_UNKNOWN, as proc.flags is the same as variable.type,
		 * which is where the type index for an unknown global
		 * symbol is placed.
		 */
	    case OSYM_UNKNOWN:
	    {
		/*
		 * This is what gets created when all we've got is a type
		 * index and we need to know the actual type to determine
		 * the type of symbol.
		 * 9/14/92: changed to check os->u.variable.type for 0, to
		 * see if the type was actually defined for the beast. if
		 * the user failed to compile with debugging info enabled,
		 * this will still be 0, and we need to leave the thing as
		 * OSYM_UNKNOWN to avoid hosing things. -- ardeb
		 */
		
		if (os->u.variable.type != 0 &&
                    os->u.variable.type < Vector_Length(borlandTypes)) {
		    BorlandType	*btp;

		    btp = BorlandGetTypeData(os->u.variable.type);
		    if (btp->desc[0] == BTID_FUNCTION) {
			os = BorlandDefineFunction(os, &osh, btp);
		    } else if (btp->desc[0] == BTID_LABEL) {
			os->type = OSYM_LABEL;
			os->u.label.near = (btp->desc[1] ? FALSE : TRUE);
		    } else {
			/*
			 * Convert to OSYM_CHUNK if in lmem handle segment?
			 */
			os->type = OSYM_VAR;
			os->u.variable.type =
			    BorlandCopyTypeDesc(os->u.variable.type, types,
						isLMem);
		    }
		}
		break;
	    }
	}
    }

    *typesPtr = types;
}


/***********************************************************************
 *				BorlandEnsureTypeConverted
 ***********************************************************************
 * SYNOPSIS:	    Make sure the given type index has been converted.
 * CALLED BY:	    BorlandProcessAllTypes, BorlandFetchType
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandEnsureTypeConverted(int	    i,
			   Boolean  isLMem)
{
    BorlandType	*btp;

    btp = BorlandGetTypeData(i);
    
    /*
     * If this type has already been converted, we're done.
     */
    if (btp->shortType != 0) {
	return;
    }

    switch(btp->desc[0]) {
	case BTID_VLSTRUCT:
	case BTID_STRUCT:
	case BTID_VLUNION:
	case BTID_UNION:
	{
	    /*
	     * Convert all the types of the fields now so we can deal with
	     * giving similar anonymous structures the same names, thereby
	     * ensuring proper type-matching between object files.
	     */
	    VMBlockHandle   types = 0;
	    ObjSymHeader    *osh;
	    ObjSym  	    *os;
	    VMBlockHandle   block = btp->ot.words[1];

	    osh = (ObjSymHeader *)VMLock(symbols, block, (MemHandle *)NULL);
	    os = (ObjSym *)((genptr)osh + btp->ot.words[0]);

	    /*
	     * Mark the beast as converted in case it's self-referential
	     * or mutually referential with some other type; we'd rather
	     * avoid endless recursion.
	     *
	     * Note that we don't have to worry about the name of a nameless
	     * structure changing after having been used by something during the
	     * call to BorlandConvertSymbolBlock, as each block contains only
	     * a single type, and the only thing that could use a nameless
	     * structure is a variable or a typedef, neither of which is to
	     * be found in the symbol block containing the type, nor in any
	     * other symbol block containing another structure.
	     */
	    btp->shortType = BORLAND_CONVERTED_LONG_TYPE;
	    OTYPE_ID_TO_STRUCT(os->name, &btp->ot);

	    BorlandConvertSymbolBlock(block, osh, &types, isLMem);

	    if (os->flags & OSYM_NAMELESS) {
		MSObj_AddAnonStruct(os, types, os->u.sType.size,
				    ((os->u.sType.last-os->u.sType.first)/
					 sizeof(ObjSym)));
		OTYPE_ID_TO_STRUCT(os->name, &btp->ot);
	    }
	    VMUnlockDirty(symbols, block);
	    break;
	}
	case BTID_ENUM:
	{
	    /*
	     * No further processing required, but we need to get the name
	     * of the symbol that ended up here (might not be the structured
	     * type itself owing to typedefs and the like).
	     */
	    VMBlockHandle   block = btp->ot.words[1];
	    ObjSym  	    *osp = (ObjSym *)VMLockVMPtr(symbols,
					       MAKE_VMP(block,
							btp->ot.words[0]),
					       (MemHandle *)NULL);

	    OTYPE_ID_TO_STRUCT(osp->name, &btp->ot);
	    VMUnlock(symbols, block);
	    btp->shortType = BORLAND_CONVERTED_LONG_TYPE;
	    break;
	}
	case 0:
	    /*
	     * Turbo C seems to skip a type number occasionally. We musn't
	     * die because of it, though...
	     */
	    break;
	default:
	    assert(0);
    }
}

/***********************************************************************
 *				BorlandConvertSymbolTypes
 ***********************************************************************
 * SYNOPSIS:	    Convert the type indices for all symbols in a
 *	    	    chain of blocks into standard type words/ObjType
 *	    	    records.
 * CALLED BY:	    BorlandProcessAllTypes, BorlandProcessAllPublics,
 *	    	    BorlandProcessAllExternals
 * RETURN:	    nothing
 * SIDE EFFECTS:    guess
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 3/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandConvertSymbolTypes(const char   	*file,  /* Object file name */
			  VMBlockHandle	next,	/* First symbol block */
			  Boolean   	isLMem)	/* TRUE if should watch for
						 * chunks disguised as
						 * single-element word arrays */
{
    ObjSymHeader    *osh;
    VMBlockHandle   types;
    VMBlockHandle   cur;

    types = 0;
    
    while (next != 0) {
	cur = next;
	osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);

	BorlandConvertSymbolBlock(cur, osh, &types, isLMem);

	next = osh->next;
	VMUnlockDirty(symbols, cur);
    }
}


/***********************************************************************
 *				BorlandProcessAllTypes
 ***********************************************************************
 * SYNOPSIS:	    Convert all type descriptions not yet converted.
 * CALLED BY:	    Borland_Finish
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessAllTypes(const char *file)
{
    /*
     * Deal with the structured types under 3.x first, locating their
     * members and creating the type symbols themselves.
     */
    if (borlandMajorVersion >= 3) {
	int 	    i;
	BorlandType *btp;

	for (i = Vector_Length(borlandTypes),
	     btp = (BorlandType *)Vector_Data(borlandTypes);

	     i > 0;

	     i--, btp++)
	{
	    switch(btp->desc[0]) {
		case BTID_VLSTRUCT:
		case BTID_VLUNION:
		case BTID_STRUCT:
		case BTID_UNION:
		case BTID_ENUM:
		    BorlandFinishSEU(NULL, btp, 0);
		    break;
	    }
	}
    }

    /*
     * Now convert all type indices and enter all type symbols.
     */
    if (sTypes != (VMBlockHandle)0) {
	int 	i;
	int 	max;
	
	/*
	 * Convert all the structures here so we can be sure anonymous
	 * structures get the same names across object files.
	 */
	max = Vector_Length(borlandTypes);
	for (i = BT_LAST_PREDEF+1; i < max; i++) {
	    BorlandEnsureTypeConverted(i, FALSE);
	}

	/*
	 * Now create type descriptions from all the type indices stored
	 * in the various symbols.
	 */
	BorlandConvertSymbolTypes(file, sTypes, FALSE);

	/*
	 * Enter all the type symbols, now they've been properly massaged, but
	 * don't enter structure fields.
	 */
	(void)Obj_EnterTypeSyms(file, symbols, globalSeg, sTypes,
				OETS_TOP_LEVEL_ONLY|OETS_RETAIN_ORIGINAL);
    }

    /*
     * Do likewise for the random typedefs we've acquired.
     */
    if (others != (VMBlockHandle)0) {
	BorlandConvertSymbolTypes(file, others, FALSE);
	(void)Obj_EnterTypeSyms(file, symbols, globalSeg, others,
				OETS_TOP_LEVEL_ONLY|OETS_RETAIN_ORIGINAL);
    }
}


/***********************************************************************
 *				BorlandProcessAllExternals
 ***********************************************************************
 * SYNOPSIS:	    Process all the external symbols we've worked up.
 * CALLED BY:	    Borland_Finish
 * RETURN:	    nothing
 * SIDE EFFECTS:    the symbols are entered as undefined in the
 *	    	    global scope, after their types have been converted.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 3/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessAllExternals(const char *file)
{
    if (lastExternal != NullVMPtr) {
	ObjSymHeader	*osh;
	ObjSym	    	*os;
	int 	    	i;

	BorlandConvertSymbolTypes(file, VMP_BLOCK(lastExternal), FALSE);

	osh = (ObjSymHeader *)VMLock(symbols, VMP_BLOCK(lastExternal),
				     (MemHandle *)NULL);
	os = ObjFirstEntry(osh, ObjSym);
	for (i = osh->num; i > 0; i--, os++) {
	    Sym_EnterUndef(symbols, globalSeg->syms,
			   os->name, os, ObjEntryOffset(os,osh),
			   symbols, osh->types);
	}

	VMFree(symbols, osh->types);
	
	VMUnlock(symbols, VMP_BLOCK(lastExternal));
	VMFree(symbols, VMP_BLOCK(lastExternal));
	lastExternal = NullVMPtr;
    }
}
    

/***********************************************************************
 *				BorlandProcessAllPublics
 ***********************************************************************
 * SYNOPSIS:	    Process all public symbols for all segments.
 * CALLED BY:	    Borland_Finish
 * RETURN:	    nothing
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 3/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandProcessAllPublics(const char	*file)
{
    int	    	    i;
    int	    	    max;
    BorlandSegData  *sdata;

    max = Vector_Length(borlandSegs);
    
    for (i = 0, sdata = (BorlandSegData *)Vector_Data(borlandSegs);
	 i < max;
	 i++, sdata++)
    {
	if (sdata->addrH != 0) {
	    SegDesc	    *sd;
	    VMBlockHandle   next, cur;
	    ObjSymHeader    *osh;
	    ObjSym  	    *os;
	    int	    	    j;

	    /* Note: won't get here with i == 0, since there never is a
	     * segment with index 0 and Vector functions 0-initialize all
	     * new entries, so sdata[0].addrH will always be 0... */
	    assert(i != 0);
	    Vector_Get(segments, i-1, (Address)&sd);

	    /*
	     * Convert the type indices for everything in the segment.
	     */
	    BorlandConvertSymbolTypes(file, sdata->addrH,
				      sd->combine == SEG_LMEM);

	    /*
	     * Now relocate all the address-bearing symbols by the segment's
	     * current relocation factor.
	     */
	    next = sdata->addrH;

	    while (next != 0) {
		cur = next;
		osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);
		osh->seg = 0;
		os = ObjFirstEntry(osh, ObjSym);

		for (j = osh->num; j > 0; j--, os++) {
		    if (Obj_IsAddrSym(os)) {
			os->u.addrSym.address += sd->nextOff;

			if ((os->name != NullID) &&
			    ((os->type == OSYM_VAR) ||
			     (os->type == OSYM_CHUNK) ||
			     (os->type == OSYM_PROC) ||
			     (os->type == OSYM_LABEL) ||
			     (os->type == OSYM_UNKNOWN)))
			{
			    /*
			     * Enter the symbol under its given name first.
			     */
			    Sym_Enter(symbols, sd->syms, os->name, cur,
				      ObjEntryOffset(os, osh));
			    
#if 0	    /* This was nuked b/c of the way GOC does chunks (if handle is
	     * foo, data is _foo) */

			    if (borlandUnderscores) {
				char    *name = ST_Lock(symbols, os->name);
				ID	    extName;
				
				extName = os->name;
				
				if (name[0] == '_') {
				    os->name = ST_EnterNoLen(symbols, strings,
							     name+1);
				    Sym_Enter(symbols, sd->syms, os->name, cur,
					      ObjEntryOffset(os, osh));
				}
				ST_Unlock(symbols, extName);
			    }
#endif

			}
		    }
		}
		next = osh->next;
		VMUnlockDirty(symbols, cur);
	    }

	    if (sd->addrH == 0) {
		/*
		 * No address symbols for the segment yet, so make our
		 * queue the segment's queue.
		 */
		sd->addrH = sdata->addrH;
		sd->addrT = sdata->addrT;
	    } else {
		/*
		 * Hook our queue onto the end.
		 */
		osh = (ObjSymHeader *)VMLock(symbols, sd->addrT,
					     (MemHandle *)NULL);

		osh->next = sdata->addrH;
		VMUnlockDirty(symbols, sd->addrT);
		sd->addrT = sdata->addrT;
	    }
	}
    }
}
    

/***********************************************************************
 *				BorlandNukeTypes
 ***********************************************************************
 * SYNOPSIS:	    Free up the sTypes and others chain
 * CALLED BY:	    Borland_Finish
 * RETURN:	    nothing
 * SIDE EFFECTS:    sTypes and others set to 0
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 3/92		Initial Revision
 *
 ***********************************************************************/
static void
BorlandNukeTypes(void)
{
    VMBlockHandle   next, cur;
    ObjSymHeader    *osh;
    VMBlockHandle   lastTypes;

    next = sTypes;
    lastTypes = 0;

    while (next != 0) {
	cur = next;

	osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);
	if (osh->types != lastTypes) {
	    VMFree(symbols, osh->types);
	    lastTypes = osh->types;
	}
	next = osh->next;
	VMUnlock(symbols, cur);
	VMFree(symbols, cur);
    }

    next = others;
    while (next != 0) {
	cur = next;

	osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);
	if (osh->types != lastTypes) {
	    VMFree(symbols, osh->types);
	    lastTypes = osh->types;
	}
	next = osh->next;
	VMUnlock(symbols, cur);
	VMFree(symbols, cur);
    }

    sTypes = others = 0;

}

/***********************************************************************
 *				Borland_Finish
 ***********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:	
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
void
Borland_Finish(const char *file,    	/* Object file just read */
	       int  happy,  	    	/* Non-zero if no errors, so all
					 * symbolic information should be
					 * copacetic */
	       int  pass)   	    	/* 1 or 2 */
{
    if (happy) {
	if (pass == 1) {
	    /*
	     * First, process all the type descriptions in the borlandTypes
	     * vector.
	     */
	    BorlandProcessAllTypes(file);
	    
	    /*
	     * Next, deal with all the externals.
	     */
	    BorlandProcessAllExternals(file);
	    
	    /*
	     * Finally, work through all the symbols in the various segments.
	     */
	    BorlandProcessAllPublics(file);
	    
	    /*
	     * Let Pass1MS have its crack at things after we've reset the
	     * osh->seg fields to make sure it doesn't try to re-enter our
	     * symbols for us...
	     */
	    Pass1MS_Finish(file, happy, pass);

	    /*
	     * Free up sTypes and others chains
	     */
	    BorlandNukeTypes();

	    /*
	     * Clean up the vectors for the next time.
	     */
	    Vector_Empty(borlandSources);
	    Vector_Empty(borlandLocalStatics);
	    Vector_Empty(borlandSegs);
	    Vector_Truncate(borlandTypes, BT_LAST_PREDEF+1);
	    Vector_Empty(borlandMembers);
	    borlandUnderscores = FALSE;
	    borlandMajorVersion = 2;
	    seuStartInd = seuCurIndex = 1;
	} else {
	    Pass2MS_Finish(file, happy, pass);
	}
    }
}
