/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Symbol Handling
 * FILE:	  symbol.c
 *
 * AUTHOR:  	  Adam de Boor: Jun 26, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Sym_Enter 	    Enter a symbol into the table.
 *	Sym_Find  	    Find a symbol by ID.
 *	Sym_Init  	    Initialize the module.
 *	Sym_ForEachSegment  Iterate over all known segments, setting curSeg
 *	    	    	    to each in turn...
 *	Sym_ForEachLocal    Iterate over all local symbols for a procedure
 *	Sym_ProcessSegments Perform necessary symbol and fixup processing
 *	    	    	    for writing segments to output.
 *	Sym_Adjust  	    Fix up the symbols in a segment to accomodate
 *	    	    	    a change in the size of an element in the segment
 *	Sym_BindMethod	    Bind a method procedure to a method constant
 *	    	    	    in a class.
 *	Sym_SetAddress	    Set the address recorded for a symbol.
 *	Sym_AddToGroup	    Add another segment to a group.
 *	Sym_AdjustArgOffset Adjust the offsets for all argument symbols of
 *	    	    	    the current procedure.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	6/26/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Symbol-handling primitives
 *
 *	When symbol is entered and an existing SYM_PUBLIC symbols exists,
 *	the SYM_GLOBAL flag should be set and the SYM_PUBLIC symbol
 * 	deleted. Under no circumstances should a SYM_PUBLIC symbol
 *	ever be returned by Sym_Find -- the identifier should be
 *	treated as undefined until it is defined.
 *
 *	Sym_Enter is responsible for advancing sType.common.size if
 *	value non-null for SYM_FIELD and SYM_INSTVAR
 *
 *	Sym_Enter will need to handle definition of SYM_UNDEF symbols with
 *	addresses, using old definition, but placing it in the proper place
 *	in the list of symbols.
 *
 *	During write-out, chunk symbols must be converted so their address
 *	is their handle.
 *
 *
 *	The table is organized similarly to the string table, except it's
 * 	all in virtual memory. The hash value computed for a symbol's
 *	identifier is used to decide in which bucket the symbol should
 *	be placed. As for the string table, the symbols for a bucket are
 *	are allocated in chunks, which chunks are chained together (as
 *	opposed to chaining the symbols themselves together). This not only
 *	reduces heap overhead, but saves four bytes per symbol...
 *
 *	Segments and groups receive special treatment, since they are the
 * 	primary unit of organization and the only things over which we
 *	need to iterate. A pointer to each known segment is placed in the
 *	"segments" array, which is re-allocated at need. Similarly, groups
 *	are placed in the "groups" array.
 *
 ***********************************************************************/

#include    "esp.h"
#include    <objfmt.h>
/*#include    "scan.h"	;XXX */
/*
 * Number of buckets in the symbol table
 */
#define SYM_BUCKETS 	509

/*
 * Number of symbols allocated in a chunk in a bucket.
 */
#define SYMS_PER_BUCKET	32

typedef struct _SymBucket {
    Symbol  	    	syms[SYMS_PER_BUCKET];	/* Symbols in bucket */
    Symbol  	    	*ptr;	/* Place to store next symbol */
    struct _SymBucket	*next;	/* Next chunk in bucket chain */
} SymBucketRec, *SymBucketPtr;
    
static SymBucketPtr symTable[SYM_BUCKETS];  /* Table of named symbols */
static SymBucketPtr symAnon;	    /* Current bucket for anonymous symbols.
				     * These aren't used much and are never
				     * written to the file, so there's no
				     * need to keep track of them all, but
				     * we still don't want to allocate each
				     * one individually */
static SymbolPtr    *segments;	    /* Array of known segment symbols. */
static int  	    numSegments=0;

static SymbolPtr    *groups;
static int  	    numGroups=0;

static int  	    writing = 0;    /* Set TRUE during object-file write-out
				     * to signal that Sym_Find should look
				     * for a symbol using a permanent ID if
				     * it's around and the temporary ID can't
				     * be found. This is something of a hack */

static void 	    SymResolveInherit(SymbolPtr inheritSym, SymbolPtr destProc);


/***********************************************************************
 *				SymPermanentName
 ***********************************************************************
 * SYNOPSIS:	    Fetch the permanent name for a symbol, i.e. the ID
 *	    	    for the symbol in the permanent string table.
 * CALLED BY:	    INTERNAL
 * RETURN:	    ID for the symbol
 * SIDE EFFECTS:    If the symbol hasn't had its name placed in the
 *	    	    permanent table, the name is copied there and the
 *	    	    resulting ID replaces the symbol's name, since nothing
 *	    	    should need to look the symbol up again.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/21/90		Initial Revision
 *
 ***********************************************************************/
static ID
SymPermanentName(Symbol	*sym)
{
    if (!(sym->flags & SYM_PERM)) {
	sym->name = ST_Dup(output, sym->name, output, permStrings);
	sym->flags |= SYM_PERM;
    }
    return(sym->name);
}


/***********************************************************************
 *				SymAlloc
 ***********************************************************************
 * SYNOPSIS:	Alloc another SymbolRec from the passed bucket
 * CALLED BY:	Sym_Enter, SymInherit
 * RETURN:	SymbolPtr to use
 * SIDE EFFECTS:*bucketPtr updated if new bucket allocated
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/24/92		Initial Revision
 *
 ***********************************************************************/
static SymbolPtr
SymAlloc(SymBucketPtr	*bucketPtr)
{
    SymBucketPtr    bucket = *bucketPtr;

    /*
     * If no segments in bucket or no symbols left in current bucket,
     * allocate another segment and link it to the front of the
     * bucket chain.
     */
    if ((bucket == NULL) || (bucket->ptr==&bucket->syms[SYMS_PER_BUCKET])){
	bucket = (SymBucketPtr)malloc(sizeof(SymBucketRec));
	bucket->next = *bucketPtr;
	*bucketPtr = bucket;
	bucket->ptr = bucket->syms;
    }
    /*
     * Use next symbol
     */
    return (bucket->ptr++);
}


/***********************************************************************
 *				Sym_BindMethod
 ***********************************************************************
 * SYNOPSIS:	    Bind a procedure to a method in the context of
 *	    	    a class.
 * CALLED BY:	    Obj_EnterHandler
 * RETURN:	    NullID if ok, the name of previously bound procedure
 *	    	    if not ok.
 * SIDE EFFECTS:    A new SYM_BINDING symbol is created in the
 *	    	    bindings chain for the class.
 *
 * STRATEGY:
 *	Binding symbols don't live in the normal symbol table. Rather,
 *	they are chained in buckets off the class symbol to which
 *	they pertain, much the way procedure-local symbols are chained
 *	off the procedure symbol to which they are local.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 4/89		Initial Revision
 *
 ***********************************************************************/
ID
Sym_BindMethod(SymbolPtr    class,
	       ID    	    method,
	       SymbolPtr    proc,
	       byte 	    callType)
{
    SymBucketPtr    bucket, *prev;
    SymbolPtr	    binding;

    Sym_Reference(proc);

    prev = (SymBucketPtr *)&class->u.class.data->bindings;

    for (bucket = *prev; bucket; bucket = *prev) {
	for (binding = bucket->syms; binding < bucket->ptr; binding++) {
	    if (binding->name == method) {
		/*
		 * Conflict -- this method is already bound. Return the
		 * name of the already bound procedure.
		 */
		return(binding->u.binding.proc->name);
	    }
	}
	if (bucket->ptr == &bucket->syms[SYMS_PER_BUCKET]) {
	    /*
	     * No room in this bucket -- advance to next.
	     */
	    prev = &bucket->next;
	} else {
	    /*
	     * Room here -- get out now (there can't be any other bindings).
	     */
	    break;
	}
    }
    binding = SymAlloc(prev);
    /*
     * A BINDING symbol has the name of the method as its name with the
     * per-class data containing the procedure involved.
     */
    binding->name = method;
    binding->type = SYM_BINDING;
    binding->flags = 0;
    binding->u.binding.proc = proc;
    binding->u.binding.callType = callType;
    return(NullID);
}
		 


/***********************************************************************
 *				SymInherit
 ***********************************************************************
 * SYNOPSIS:	Inherit all local variables from given procedure, if
 *	    	it's got any. It's an error for there to already be
 *	    	local variables defined for the procedure.
 * CALLED BY:	Sym_Find, Sym_Enter
 * RETURN:	nothing
 * SIDE EFFECTS:u.inherit.done is set
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/24/92		Initial Revision
 *
 ***********************************************************************/
static void
SymInherit(SymbolPtr	inheritSym,
	   SymbolPtr	sourceProc,
	   SymbolPtr	destProc,
	   int	    	resolveInherits)
{
    SymBucketPtr    bucket, *prev;
    SymbolPtr	    sym;
    SymBucketPtr    sBucket;
    SymbolPtr	    sSym;

    /*
     * Make sure the destProc doesn't have any local vars or parameters yet
     */
    prev = (SymBucketPtr *)&destProc->u.proc.locals;
    for (bucket = *prev; bucket != NULL; bucket = *prev) {
	for (sym = bucket->syms; sym < bucket->ptr; sym++) {
	    if (sym->type == SYM_LOCAL) {
		Notify(NOTIFY_ERROR, inheritSym->u.inherit.file,
		       inheritSym->u.inherit.line,
		       "cannot define additional locals when inheriting all locals from %i",
		       sourceProc->name);
		return;
	    }
	}
	prev = &bucket->next;
    }

    /*
     * Now copy all the local variables from the source procedure to this
     * one.
     */
do_inherit:
    for (sBucket = (SymBucketPtr)sourceProc->u.proc.locals;
	 sBucket != NULL;
	 sBucket = sBucket->next)
    {
	for (sSym = sBucket->syms; sSym < sBucket->ptr; sSym++) {
	    if (sSym->type == SYM_LOCAL) {
		/*
		 * Alloc a the next symbol from the dest proc's bucket.
		 * XXX: CHECK FOR DUPLICATES...
		 */
		sym = SymAlloc(prev);
		*sym = *sSym;
		Sym_Reference(sym); /* Mark it as referenced,as might be
				     * used in parent or a "sibling"
				     * routine, as it were... */
	    } else if ((sSym->type == SYM_INHERIT) &&
		       !sSym->u.inherit.done)
	    {
		/*
		 * Source proc is itself inheriting local variables, but
		 * hasn't done so yet.
		 */
		if (!resolveInherits) {
		    return;
		} else {
		    /*
		     * Attempt to resolve the inheritance there and start
		     * the copying over again.
		     */
		    SymResolveInherit(sSym, sourceProc);
		    goto    do_inherit;
		}
	    }
	}
    }

    inheritSym->u.inherit.done = TRUE;
}
     

/***********************************************************************
 *				SymResolveInherit
 ***********************************************************************
 * SYNOPSIS:	    Resolve the inheritance of local variables.
 * CALLED BY:	    Sym_Find, SymInherit
 * RETURN:	    nothing
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/24/92		Initial Revision
 *
 ***********************************************************************/
static void
SymResolveInherit(SymbolPtr  inheritSym,    /* SYM_INHERIT symbol */
		  SymbolPtr  destProc)	    /* Procedure doing the inheriting */
{
    SymbolPtr	proc = Sym_Find(inheritSym->name, SYM_PROC, TRUE);

    if (proc == NullSymbol) {
	Notify(NOTIFY_ERROR, inheritSym->u.inherit.file,
	       inheritSym->u.inherit.line,
	       "procedure %i not defined -- cannot inherit its local variables",
	       inheritSym->name);
    } else if (proc->type != SYM_PROC) {
	Notify(NOTIFY_ERROR, inheritSym->u.inherit.file,
	       inheritSym->u.inherit.line,
	       "%i isn't a procedure, so it has no local variables to inherit",
	       inheritSym->name);
    } else if (proc->flags & SYM_UNDEF) {
	Notify(NOTIFY_ERROR, inheritSym->u.inherit.file,
	       inheritSym->u.inherit.line,
	       "cannot inherit local variables from external procedure %i",
	       inheritSym->name);
    } else if (proc == destProc) {
	Notify(NOTIFY_ERROR, inheritSym->u.inherit.file,
	       inheritSym->u.inherit.line,
	       "one cannot inherit local variables from oneself");
    } else {
	SymInherit(inheritSym, proc, destProc, TRUE);
    }

    /*
     * For good or evil, this inheritance is taken care of.
     */
    inheritSym->u.inherit.done = TRUE;
}

/***********************************************************************
 *				SymLookup
 ***********************************************************************
 * SYNOPSIS:	    Attempt to locate a symbol in the table
 * CALLED BY:	    Sym_Enter, Sym_Find
 * RETURN:	    The SymbolPtr, if found, and the bucket head
 *	    	    pointer for the symbol's chain, even if the symbol
 *	    	    isn't found.
 * SIDE EFFECTS:
 *	None.
 *
 * STRATEGY:
 *	If id is null, point bucketPtr at symAnon and return NULL, causing
 *	anonymous symbols to be allocated in the proper place.
 *
 *	Else, fetch the index for the ID and wrap it to the symTable
 *	buckets, pointing bucketPtr at the proper entry. Search the bucket
 *	chain for the symbol, returning the result.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/21/89		Initial Revision
 *
 ***********************************************************************/
static SymbolPtr
SymLookup(ID	    	id, 	    	/* ID of symbol to find */
	  SymType   	type,	    	/* Type of symbol being sought.
					 * SYM_LASTADDR for any type. This
					 * is used only to determine if
					 * the chain in the current procedure
					 * should be used when searching. */
	  SymBucketPtr	**bucketPtr) 	/* OUT: Address of pointer to first
					 * segment in bucket chain */
{
    if (id == NullID) {
	*bucketPtr = &symAnon;
    } else {
	word   	    	index;
	SymBucketPtr	bucket;

	if ((type == SYM_LOCALLABEL) ||
	    (type == SYM_LOCAL) ||
	    (type == SYM_INHERIT))
	{
	    /*
	     * Type desired is a procedure-local one -- look in the locals
	     * chain of the current procedure.
	     *
	     * IT IS AN ERROR TO CREATE A PROCEDURE-LOCAL SYMBOL OUTSIDE
	     * A PROCEDURE. The parser should check for being in a
	     * procedure before calling Sym_Enter.
	     */
	    assert(curProc != NULL);
	    
	    *bucketPtr = (SymBucketPtr *)&curProc->u.proc.locals;
	} else {
	    /*
	     * Use the proper chain in the symbol table
	     */
	    index = ST_Index(output, id);

	    *bucketPtr = &symTable[index % SYM_BUCKETS];
	}

	/*
	 * Run through all the buckets, looking for the symbol in question
	 */
	for (bucket = **bucketPtr; bucket != NULL; bucket = bucket->next) {
	    /*
	     * For full buckets, bucket->ptr is left pointing after the
	     * last symbol, while for partially empty buckets, since ptr
	     * points to the next available slot, this is also true.
	     * Hence, we just loop through the symbols from syms to ptr,
	     * comparing the name to id, returning the symbol if there's
	     * a match.
	     *
	     * 11/5/91: we only return a method symbol with the RANGE flag
	     * set if the type being sought is explicitly SYM_METHOD. This
	     * allows us to use the same name for a message range's placeholder
	     * and for its enumerated type. In addition, when the type being
	     * sought is SYM_METHOD, we refuse to return a symbol unless
	     * it *is* a method symbol. This is used in the implementation
	     * of exported message ranges and must not change.
	     */
	    SymbolPtr	sym;

	    if (type == SYM_METHOD) {
		for (sym = bucket->syms; sym < bucket->ptr; sym++) {
		    if ((sym->name == id) && (sym->type == SYM_METHOD)) {
			return(sym);
		    }
		}
	    } else {
		for (sym = bucket->syms; sym < bucket->ptr; sym++) {
		    if ((sym->name == id) &&
			((sym->type != SYM_METHOD) ||
			 !(sym->u.method.flags & SYM_METH_RANGE)))
		    {
			return(sym);
		    }
		}
	    }
	}
    }

    /*
     * Unsuccessful search -- *bucketPtr already set.
     */
    return(NULL);
}
	

/***********************************************************************
 *				Sym_SetAddress
 ***********************************************************************
 * SYNOPSIS:	    Set the address for an address symbol, placing the
 *	    	    symbol in the proper position in its segment's list
 * CALLED BY:	    Sym_Enter, EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The u.addrsym fields are set
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/22/89		Initial Revision
 *
 ***********************************************************************/
void
Sym_SetAddress(SymbolPtr    sym,
	       int  	    offset)
{
    SymbolPtr	seg = sym->segment;
    
    sym->u.addrsym.offset = offset;

    /*
     * If not warning about unreferenced symbols, flag the beast as
     * referenced, in case the warning is turned on again later...
     * 9/11/91: added special-casing of local labels (note: not local
     * variables) so Eric can turn off complaints about such things -- ardeb
     */
    if (((sym->type == SYM_LOCALLABEL) && !warn_local_unref) ||
	((sym->type != SYM_LOCALLABEL) && !warn_unref))
    {
	sym->flags |= SYM_REF;
    }
    
    if (seg->u.segment.data->last == NULL) {
	/*
	 * No other address symbols -- make this be the entire list
	 */
	sym->u.addrsym.next = NULL;
	seg->u.segment.data->first =
	    seg->u.segment.data->last = sym;
    } else if (offset >= seg->u.segment.data->last->u.addrsym.offset) {
	/*
	 * After last symbol in list -- just put it at the end.
	 */
	seg->u.segment.data->last->u.addrsym.next = sym;
	seg->u.segment.data->last = sym;
	sym->u.addrsym.next = NULL;
    } else {
	/*
	 * Insert out of order -- first find the symbol after which the
	 * thing should go. There's no need to check for null since the
	 * symbol *must* go before the last one in the list or we'd have
	 * placed it after it, above.
	 */
	SymbolPtr   *prevPtr;
	SymbolPtr   sym2;

	prevPtr = &sym->segment->u.segment.data->first;
	for (sym2=*prevPtr; offset >= sym2->u.addrsym.offset; sym2=*prevPtr) {
	    prevPtr = &sym2->u.addrsym.next;
	}

	sym->u.addrsym.next = sym2;
	*prevPtr = sym;
    }
}
	

/***********************************************************************
 *				Sym_AllocLoc
 ***********************************************************************
 * SYNOPSIS:	    Allocate a suitable localization record for this
 *	    	    chunk.
 * CALLED BY:	    (INTERNAL/EXTERNAL) Sym_Enter, LOCALIZE rule
 * RETURN:	    pointer to LocalizeInfo for the chunk
 * SIDE EFFECTS:    memory is allocated
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 7/93		Initial Revision
 *
 ***********************************************************************/
LocalizeInfo *
Sym_AllocLoc(SymbolPtr	    sym,
	     ChunkDataType  type)
{
    char    	    *name = ST_Lock(output, sym->name);
    LocalizeInfo    *loc;

    loc = (LocalizeInfo *)malloc(sizeof(LocalizeInfo) + strlen(name)+1);
    loc->chunkName = (char *)(loc+1);
    strcpy(loc->chunkName, name);

    loc->chunkNumber = sym->u.chunk.handle/2;
    loc->dataTypeHint = type;
    /*
     * No instructions, min, max or next, yet.
     */
    loc->instructions = 0;
    loc->min = loc->max = 0;
    loc->next = 0;

    ST_Unlock(output, sym->name);

    /*
     * Make sure the localization stuff knows what resource the thing
     * belongs to. We use the segment of the containing segment, rather
     * than the containing segment, as that's the group that will become
     * the resource; the containing segment is just the @Heap portion.
     */
    name = ST_Lock(output, sym->segment->segment->name);
    Localize_EnterResource((Opaque)sym->segment->segment, name);
    ST_Unlock(output, sym->segment->segment->name);

    Localize_AddLocalization(loc);

    return(loc);
}

/***********************************************************************
 *				Sym_Enter
 ***********************************************************************
 * SYNOPSIS:	    Enter a new symbol into the table
 * CALLED BY:	    parser and others
 * RETURN:	    The SymbolPtr for the symbol
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 *	Type	    	Pass
 *	SYM_BITFIELD	offset, width, value (Expr *), type (TypePtr or NULL)
 *	SYM_CHUNK   	address of chunk, handle, type of data
 *	SYM_CLASS   	superclass, method type, instance type, base type,
 *	    	    	vardata type, class flags
 *	SYM_ENUM    	enumerated type, value, protominor
 *	SYM_ETYPE   	base value, increment, size, flags
 *	SYM_FIELD   	containing structure, type, default value (Expr *)
 *	    	    	If value is non-null, need to enlarge containing
 *	    	    	structure.
 *	SYM_GROUP   	initial number of segments, initial segments
 *	SYM_INSTVAR 	class, type, value, is public?, in state block?
 *	    	    	if value is non-null, need to enlarge instance
 *	    	    	structure size.
 *	SYM_LABEL   	address, is near?
 *	SYM_LINE    	file, line number, address
 *	SYM_LOCAL   	offset, type, containing procedure
 *	SYM_MACRO   	text chain, # args, # locals
 *	SYM_METHOD  	class, flags (value must be assigned)
 *	SYM_NUMBER  	Expr * value, read-only flag
 *	SYM_ONSTACK 	address, ID of descriptor
 *	SYM_PROC    	address, is near?
 *	SYM_PUBLIC  	file, line number
 *	SYM_RECORD  	nothing
 *	SYM_SEGMENT 	combine type, alignment, class ID EXCEPT
 *	    	    	combine type ABSOLUTE:
 *	    	    	combine type, segment address
 *	SYM_STRING  	text chain
 *	SYM_STRUCT  	nothing
 *	SYM_UNION  	nothing
 *	SYM_TYPE    	type
 *	SYM_VAR	    	address, type
 *	SYM_VARDATA 	enumerated type, value, data type
 *	SYM_PROTOMINOR 	nothing
 *	SYM_INHERIT 	source proc symbol (null if not defined yet), file, line
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/18/89		Initial Revision
 *
 ***********************************************************************/
SymbolPtr
Sym_Enter(ID id, SymType type, ...)
{
    va_list 	    args;
    SymbolPtr	    sym;
    SymBucketPtr    *bucketPtr;
    Symbol  	    old;

    sym = SymLookup(id, type, &bucketPtr);

    va_start(args, type);

    if (sym == NULL) {
	sym = SymAlloc(bucketPtr);
	/*
	 * Set up the symbol as if it were undefined so we just override
	 * the fields with the new data.
	 */
	sym->name = 	id;
	sym->flags = 	SYM_UNDEF;
	sym->type = 	type;
	sym->segment = 	curSeg;
	old.type = SYM_LASTADDR;

    } else {
	old = *sym;
	/*
	 * If previous def was just a forward public declaration, pretend
	 * there was no previous definition -- sym-flags will still be
	 * set up properly and that's all that matters. This pretense
	 * includes the switching of the segment of the symbol from
	 * wherever it was.
	 *
	 * %%% Perhaps this should only be done if defined in the global
	 * segment?
	 */
	if (old.type == SYM_PUBLIC) {
	    old.type = SYM_LASTADDR;
	    sym->segment = curSeg;
	}

    }

    if ((sym->flags & SYM_UNDEF) || (type == SYM_NUMBER)) {
	/*
	 * Symbol was undefined -- any typechecks have been performed
	 * elsewhere (?), so just override the fields of the symbol with
	 * new data.
	 */

	sym->type = type;   /* In case of type change (q.v. DefineDataSym) */
	sym->segment = curSeg;

	switch(type) {
	    case SYM_BITFIELD:
		/*
		 * offset, width, value (Expr *)
		 */
		sym->u.bitField.offset =    	va_arg(args, int);
		sym->u.bitField.width =     	va_arg(args, int);
		sym->u.bitField.value =     	va_arg(args, Expr *);
		sym->u.bitField.type =		va_arg(args, TypePtr);
		if (sym->u.bitField.value) {
		    malloc_settag((void *)sym->u.bitField.value, TAG_BITFIELD_VALUE);
		}

		if (old.type != SYM_LASTADDR && old.type != SYM_BITFIELD &&
		    old.type != SYM_NUMBER)
		{
		    yyerror("%i cannot be redefined as a record field",
			    sym->name);
		}
		break;
	    case SYM_CHUNK:
		/*
		 * address of chunk, handle, type of data
		 */
		sym->u.chunk.common.offset =	va_arg(args, int);
		sym->u.chunk.handle = 	    	va_arg(args, int);
		sym->u.chunk.type = 	    	va_arg(args, TypePtr);

		if (localize &&
		    (sym->name != NullID) &&
		    ((sym->u.chunk.type->tn_type == TYPE_CHAR) ||
		     ((sym->u.chunk.type->tn_type == TYPE_ARRAY) &&
		      (sym->u.chunk.type->tn_u.tn_array.tn_base->tn_type ==
		       TYPE_CHAR))))
		{
		    /*
		     * Chunk holds text, so allocate localization info for the
		     * thing and enter it.
		     */
		    sym->u.chunk.loc = Sym_AllocLoc(sym, CDT_text);
		} else {
		    sym->u.chunk.loc = 0;
		}
		
		if (old.type != SYM_LASTADDR) {
		    if (old.type != SYM_CHUNK) {
			yyerror("%i cannot be redefined as a chunk",
				sym->name);
		    } else if (!Type_Equal(old.u.chunk.type,sym->u.chunk.type)
			       && !Type_Equal(old.u.chunk.type,Type_Void()))
		    {
			yyerror("%i doesn't match previously declared type",
				sym->name);
		    }
		}

		/* 
		 * Warning for the anonymous chunk. 
		 */
		if ( warn_anonymous_chunk && (sym->name == NullID)) {
		    yywarning("Current chunk has no name.");
		}
		break;
	    case SYM_CLASS:
		/*
		 * superclass, method type, instance type, base type, vardata
		 * type, class flags. Need to allocate ClassData
		 */
		sym->u.class.data = (ClassData *)malloc(sizeof(ClassData));
		sym->u.class.super = 	     	va_arg(args, SymbolPtr);
		sym->u.class.data->methods = 	va_arg(args, SymbolPtr);
		sym->u.class.instance =      	va_arg(args, SymbolPtr);
		sym->u.class.data->base =    	va_arg(args, SymbolPtr);
		sym->u.class.data->vardata = 	va_arg(args, SymbolPtr);
		sym->u.class.data->flags =   	va_arg(args, int);
		sym->u.class.data->bindings =	(Opaque)NULL;
		sym->u.class.data->noreloc = 	(Opaque)NULL;
		sym->u.class.data->numUsed =	0;
		if (old.type != SYM_LASTADDR && old.type != SYM_CLASS) {
		    yyerror("%i cannot be redefined as an object class",
			    sym->name);
		}
		break;
	    case SYM_ENUM:
	    {
		/*
		 * enumerated type, value
		 */
		SymbolPtr   etype;

		/*
		 * Fetch containing type and link the symbol into the list.
		 */
		etype = va_arg(args, SymbolPtr);

		sym->u.econst.common.next = etype->u.eType.mems;
		etype->u.eType.mems = sym;
		
		/*
		 * Store the value given.
		 */
		sym->u.econst.value = va_arg(args, int);
		sym->u.econst.protoMinor = NullSymbol;
		if (etype->u.eType.common.size == 1) {
		    if ((sym->u.econst.value & 0xff00) &&
			((sym->u.econst.value & 0xff80) != 0xff80))
		    {
			yyerror("value %d too large for byte-sized enumerated constant %i",
				sym->u.econst.value,
				sym->name);
		    }
		    sym->u.econst.value &= 0xff;
		}
		
		/*
		 * Set the nextVal field for use by the parser when an enum
		 * w/o an explicit value is given.
		 */
		etype->u.eType.nextVal =
		    sym->u.econst.value + etype->u.eType.incr;
		if (old.type != SYM_LASTADDR && old.type != SYM_ENUM) {
		    yyerror("%i cannot be redefined as an enumerated constant",
			    sym->name);
		}
		break;
	    }
	    case SYM_VARDATA:
	    {
		/*
		 * enumerated type, value, associated data type
		 */
		SymbolPtr   etype;

		/*
		 * Fetch containing type and link the symbol into the list.
		 */
		etype = va_arg(args, SymbolPtr);

		sym->u.varData.common.common.next = etype->u.eType.mems;
		etype->u.eType.mems = sym;
		
		/*
		 * Store the value given.
		 */
		sym->u.varData.common.value = va_arg(args, int);
		sym->u.varData.type = va_arg(args, TypePtr);
		sym->u.varData.common.protoMinor = NullSymbol;
		
		/*
		 * Set the nextVal field for use by the parser when an enum
		 * w/o an explicit value is given.
		 */
		etype->u.eType.nextVal =
		    sym->u.econst.value + etype->u.eType.incr;
		if (old.type != SYM_LASTADDR && old.type != SYM_VARDATA) {
		    yyerror("%i cannot be redefined as a vardata type",
			    sym->name);
		}
		break;
	    }
	    case SYM_ETYPE:
		/*
		 * base value, increment, size, flags
		 *
		 * Sets nextVal to be base so first element is given
		 * base value.
		 */
		sym->u.eType.mems = sym;
		sym->u.eType.firstVal =	    	va_arg(args, int);
		sym->u.eType.incr = 	    	va_arg(args, int);
		sym->u.eType.common.size =  	va_arg(args, int);
		sym->u.eType.flags =		va_arg(args, int);
		sym->u.eType.common.desc =  	(TypePtr)NULL;
		sym->u.eType.nextVal = 	    	sym->u.eType.firstVal;
		if (old.type != SYM_LASTADDR && old.type != SYM_ETYPE) {
		    yyerror("%i cannot be redefined as an enumerated type",
			    sym->name);
		}
		break;
	    case SYM_FIELD:
	    {
		/*
		 * containing structure, type, default value (Expr *)
		 * Need to update sType.common.size for containing
		 * type if value isn't NULL
		 */
		SymbolPtr   sType;

		sType = va_arg(args, SymbolPtr);

		/*
		 * Point field symbol's link at structure, as required, then
		 * place the field symbol in the list, either at the end
		 * of the list, or as the only element of the list
		 */
		sym->u.field.common.next = sType;
		if (sType->u.sType.last) {
		    sType->u.sType.last->u.eltsym.next = sym;
		    sType->u.sType.last = sym;
		} else {
		    sType->u.sType.last =
			sType->u.sType.first = sym;
		}
		
		/*
		 * Fetch the rest of the fields and set the offset from the
		 * size of the containing structure.
		 */
		sym->u.field.type = 	    va_arg(args, TypePtr);
		sym->u.field.value =	    va_arg(args, Expr *);

		malloc_settag((void *)sym->u.field.value, TAG_FIELD_VALUE);

		/*
		 * Update the size of the containing structure based on
		 * the size of the field's type. Note this only happens if
		 * the value given was non-null.
		 */
		if (sType->type == SYM_STRUCT) {
		    sym->u.field.offset =	    sType->u.sType.common.size;
		    if (sym->u.field.value != NULL) {
			sType->u.sType.common.size +=
			    Type_Size(sym->u.field.type);
		    }
		} else {
		    /*
		     * Size of a union is the greatest of all its field sizes.
		     * All its fields start at 0.
		     */
		    int fsize;

		    sym->u.field.offset =   	    0;
		    
		    fsize = Type_Size(sym->u.field.type);
		    if (fsize > sType->u.sType.common.size) {
			sType->u.sType.common.size = fsize;
		    }
		}
		
		if (old.type != SYM_LASTADDR && old.type != SYM_FIELD &&
		    old.type != SYM_NUMBER)
		{
		    yyerror("%i cannot be redefined as a structure field",
			    sym->name);
		}
		break;
	    }
	    case SYM_GROUP:
	    {
		/*
		 * initial number of segments, initial segments
		 */
		int 	    i;
		
		sym->u.group.nSegs = va_arg(args, int);

		/*
		 * Allocate room for the segments, but at least for 1 segment
		 * so malloc doesn't complain about the args (allowing us
		 * to realloc the thing with impunity).
		 */
		sym->u.group.segs =
		    (SymbolPtr *)malloc((sym->u.group.nSegs > 0 ?
					 sym->u.group.nSegs : 1) *
					sizeof(SymbolPtr));

		for (i = 0; i < sym->u.group.nSegs; i++) {
		    sym->u.group.segs[i] = va_arg(args, SymbolPtr);
		    sym->u.group.segs[i]->segment = sym;
		}

		/*
		 * Record the group symbol in the array of known groups
		 */
		numGroups += 1;
		groups = (SymbolPtr *)realloc((void *)groups,
					      numGroups*sizeof(SymbolPtr));
		groups[numGroups-1] = sym;
		if (old.type != SYM_LASTADDR && old.type != SYM_GROUP)
		{
		    yyerror("%i cannot be redefined as a group", sym->name);
		}
		Sym_Reference(sym);
		break;
	    }
	    case SYM_INSTVAR:
	    {
		/*
		 * class, type, value, is public?
		 */
		SymbolPtr   sType;

		sym->u.instvar.class = va_arg(args, SymbolPtr);
		sType = sym->u.instvar.class->u.class.instance;
		

		/*
		 * Point instance variable symbol's link at structure, as
		 * required, then place the instvar symbol in the list, either
		 * at the end of the list, or as the only element of the list
		 */
		sym->u.instvar.common.next = sType;
		if (sType->u.sType.last) {
		    sType->u.sType.last->u.eltsym.next = sym;
		    sType->u.sType.last = sym;
		} else {
		    sType->u.sType.last =
			sType->u.sType.first = sym;
		}
		
		/*
		 * Fetch the rest of the fields and set the offset from the
		 * size of the containing structure.
		 */
		sym->u.instvar.type = 	    va_arg(args, TypePtr);
		sym->u.instvar.value =	    va_arg(args, Expr *);
		sym->u.instvar.offset =	    sType->u.sType.common.size;

		malloc_settag((void *)sym->u.instvar.value, TAG_FIELD_VALUE);

		/*
		 * Update the size of the containing structure based on
		 * the size of the field's type.
		 */
		if (sym->u.instvar.value != NULL) {
		    sType->u.sType.common.size += Type_Size(sym->u.field.type);
		}

		/*
		 * Set the instance variable's flags based on the next two
		 * args: is public? and in state block?
		 */
		sym->u.instvar.flags = 0;
		if (va_arg(args, int)) {
		   sym->u.instvar.flags |= SYM_VAR_PUBLIC;
		}
		if (va_arg(args, int)) {
		    sym->u.instvar.flags |= SYM_VAR_STATE;
		}
		if (old.type != SYM_LASTADDR && old.type != SYM_INSTVAR &&
		    old.type != SYM_NUMBER)
		{
		    yyerror("%i cannot be redefined as an instance variable",
			    sym->name);
		}
		break;
	    }
	    case SYM_LOCALLABEL:
	    case SYM_LABEL:
		/*
		 * address, is near?
		 */
		sym->u.label.common.offset = 	va_arg(args, int);
		sym->u.label.near = 	    	va_arg(args, int);
		sym->u.label.unreach = 	curSeg->u.segment.data->checkLabel;
		if ((type != SYM_LOCALLABEL && !warn_unref) ||
		    (type == SYM_LOCALLABEL && !warn_local_unref))
		{
		    /*
		     * Flag as referenced if -Wunref currently off.
		     */
		    sym->flags |= SYM_REF;
		}
		if (old.type != SYM_LASTADDR && old.type != type)
		{
		    yyerror("%i cannot be redefined as a %slabel", sym->name,
			    type == SYM_LOCALLABEL ? "local " : "");
		}
		if (sym->name == NullID) {
		    sym->flags |= SYM_NOWRITE;
		}
		break;
	    case SYM_PROFILE_MARK:
		/*
		 * address, markType
		 */
		sym->u.profMark.common.offset = 	va_arg(args, int);
		sym->u.profMark.markType =  	    	va_arg(args, int);
		break;
	    case SYM_LINE:
		/*
		 * file, line number, address
		 */
		sym->u.line.file =  	    	va_arg(args, ID);
		sym->u.line.line =  	    	va_arg(args, int);
		sym->u.line.common.offset = 	va_arg(args, int);
		break;
	    case SYM_LOCAL:
	    {
		/*
		 * offset, type
		 */
		sym->u.localVar.offset =    va_arg(args, int);
		sym->u.localVar.type =	    va_arg(args, TypePtr);
		if (!warn_local_unref)
		{
		    /*
		     * Flag as referenced if -Wunref currently off.
		     */
		    sym->flags |= SYM_REF;
		}
		if (old.type != SYM_LASTADDR && old.type != SYM_LOCAL) {
		    yyerror("%i cannot be redefined as a local variable",
			    sym->name);
		}
		break;
	    }
	    case SYM_MACRO:
		/*
		 * text chain, # args, # locals
		 */
		sym->u.macro.text = 	    	va_arg(args, void *);
		sym->u.macro.numArgs = 	    	va_arg(args, int);
		sym->u.macro.numLocals =    	va_arg(args, int);
		if (old.type != SYM_LASTADDR && old.type != SYM_MACRO) {
		    yyerror("%i cannot be redefined as a macro",
			    sym->name);
		}
		break;
	    case SYM_METHOD:
	    {
		/*
		 * class, flags (value must be assigned)
		 */
		SymbolPtr   class = va_arg(args, SymbolPtr);
		SymbolPtr   methods;

		methods = class->u.class.data->methods;

		/*
		 * Set value to be nextVal for method type, updating
		 * nextVal.
		 */
		sym->u.method.common.value = methods->u.eType.nextVal;
		methods->u.eType.nextVal += methods->u.eType.incr;

		/*
		 * Set the flags and class for the method
		 */
		sym->u.method.flags = va_arg(args, int);
		sym->u.method.class = class;
		sym->u.method.common.protoMinor = NullSymbol;
		
		/*
		 * Link the symbol into the enumerated methods type
		 */
		sym->u.method.common.common.next = methods->u.eType.mems;
		methods->u.eType.mems = sym;
		if (old.type != SYM_LASTADDR && old.type != SYM_METHOD &&
		    old.type != SYM_NUMBER)
		{
		    yyerror("%i cannot be redefined as a message",
			    sym->name);
		}
		break;
	    }
	    case SYM_NUMBER:
		/*
		 * Expr * value, read-only flag
		 */
		if (old.type != SYM_LASTADDR && old.type != SYM_NUMBER) {
		    yyerror("%i cannot be redefined as a numeric equate",
			    sym->name);
		} else {
		    if (!(sym->flags & SYM_UNDEF)) {
			Expr_Free(sym->u.equate.value);
		    }
		}
		sym->u.equate.value = va_arg(args, Expr *);
		malloc_settag((void *)sym->u.equate.value, TAG_EQUATE_EXPR);
		sym->u.equate.rdonly = va_arg(args, int);
		break;
	    case SYM_ONSTACK:
		/*
		 * address, ID of descriptor
		 */
		sym->u.onStack.common.offset = 	va_arg(args, int);
		sym->u.onStack.desc	     = 	va_arg(args, ID);
		break;
	    case SYM_PROTOMINOR:
		sym->u.addrsym.offset = 0;
		break;
	    case SYM_PROC:
		/*
		 * address, is near?
		 */
		sym->u.proc.common.offset = va_arg(args, int);
		sym->u.proc.flags = va_arg(args, int);
		sym->u.proc.locals = NULL;
		if (old.type != SYM_LASTADDR && old.type != SYM_PROC &&
		    old.type != SYM_LABEL)
		{
		    yyerror("%i cannot be redefined as a procedure",
			    sym->name);
		}
		break;
	    case SYM_PUBLIC:
		/*
		 * file, line
		 * Mark the symbol as global so when its type is properly
		 * overridden, it will be properly marked.
		 */
		sym->u.public.file = va_arg(args, ID);
		sym->u.public.line = va_arg(args, int);
		sym->flags |= SYM_GLOBAL;
		break;
	    case SYM_RECORD:
		/*
		 * nothing
		 */
		sym->u.record.mask = 0;
		sym->u.record.first = NULL;
		sym->u.record.common.size = 0;
		sym->u.record.common.desc = (TypePtr)NULL;
		if (old.type != SYM_LASTADDR && old.type != SYM_RECORD) {
		    yyerror("%i cannot be redefined as a record",
			    sym->name);
		}
		break;

	    case SYM_SEGMENT:
	    {
		/*
		 * combine type, alignment, class ID EXCEPT type ABSOLUTE:
		 * combine type, segment address
		 */
		SegData	    *data = (SegData *)malloc(sizeof(SegData));

		sym->u.segment.data = data;

		data->comb = va_arg(args, int);
		if (data->comb == SEG_ABSOLUTE) {
		    data->segment = va_arg(args, unsigned int);
		    data->class = NullID;
		} else if (data->comb != SEG_GLOBAL) {
		    data->align = va_arg(args, int);
		    data->class = va_arg(args, ID);
		} else {
		    /* glue will bitch if the alignment is non-zero for
		     * the global segment
		     */
		    data->align = 0;
		    data->segment = 0;
		    data->class = NullID;
		}
		/*
		 * Initialize remaining fields
		 */
		data->offset = 0;
		data->pair = NULL;
		data->lastdot = 0;
		data->inited = FALSE;
		data->checkLabel = TRUE;
		data->lastLabel = -1;
		data->lastLine = data->first = data->last = NULL;

		/*
		 * Store things in the symbol itself.
		 */
		sym->u.segment.data = data;
		sym->u.segment.code = Table_Init(1, CODE_BYTES_PER);
		Fix_Init(sym);

		/*
		 * Record the segment symbol in the array of known segments
		 */
		numSegments += 1;
		segments = (SymbolPtr *)realloc((void *)segments,
						numSegments*sizeof(SymbolPtr));
		segments[numSegments-1] = sym;
		if (old.type != SYM_LASTADDR && old.type != SYM_SEGMENT) {
		    yyerror("%i cannot be redefined as a segment",
			    sym->name);
		}
		/*
		 * Segments go below the global scope always, until they are
		 * added to a group.
		 */
		sym->segment = global;

		Sym_Reference(sym);
		break;
	    }
	    case SYM_STRING:
		/*
		 * text chain
		 */
		sym->u.string.value = va_arg(args, void *);
		if (old.type != SYM_LASTADDR && old.type != SYM_STRING) {
		    yyerror("%i cannot be redefined as a string equate",
			    sym->name);
		}
		break;
	    case SYM_STRUCT:
	    case SYM_UNION:
		/*
		 * nothing
		 */
		sym->u.sType.first = sym->u.sType.last = NULL;
		sym->u.sType.common.size = 0;
		sym->u.sType.common.desc = (TypePtr)NULL;
		if (old.type != SYM_LASTADDR && old.type != SYM_STRUCT) {
		    yyerror("%i cannot be redefineeed as a %s",
			    sym->name,
			    type == SYM_STRUCT ? "structure" : "union");
		}
		break;
	    case SYM_TYPE:
		/*
		 * type
		 */
		sym->u.typeDef.type = va_arg(args, TypePtr);
		sym->u.typeDef.common.size = Type_Size(sym->u.typeDef.type);
		sym->u.typeDef.common.desc = (TypePtr)NULL;
		if (old.type != SYM_LASTADDR && old.type != SYM_TYPE) {
		    yyerror("%i cannot be redefined as a typedef",
			    sym->name);
		}
		break;
	    case SYM_VAR:
		/*
		 * address, type
		 */
		sym->u.var.common.offset =  	va_arg(args, int);
		sym->u.var.type =   	    	va_arg(args, TypePtr);
		if (old.type != SYM_LASTADDR) {
		    if (old.type != SYM_VAR) {
			yyerror("%i cannot be redefined as a variable",
				sym->name);
		    } else if (!Type_Equal(old.u.var.type, sym->u.var.type)) {
			yyerror("%i doesn't match previously declared type",
				sym->name);
		    }
		}
		if (sym->name == NullID) {
		    sym->flags |= SYM_NOWRITE;
		}
		break;
	    case SYM_INHERIT:
	    {
		/*
		 * source proc symbol, file name, line num
		 */
		SymbolPtr   proc = va_arg(args, SymbolPtr);
		
		sym->u.inherit.file = va_arg(args, ID);
		sym->u.inherit.line = va_arg(args, int);
		sym->u.inherit.done = FALSE;
		sym->flags |= SYM_NOWRITE;

		if ((proc != NullSymbol) && !(proc->flags & SYM_UNDEF)) {
		    SymInherit(sym, proc, curProc, FALSE);
		}
		break;
	    }
		
	}
	if (sym->type != SYM_PUBLIC) {
	    sym->flags &= ~SYM_UNDEF; /* Symbol no longer undefined */
	}
	if (type < SYM_LASTADDR && type != SYM_CLASS) {
	    /*
	     * Symbol now has an address -- we need to add it to the address
	     * list properly. We just use Sym_SetAddress, to make our
	     * life easier and more consistent.
	     *
	     * Well, almost. SYM_CLASS doesn't pass in the address here,
	     * since the thing is defined in two pieces...
	     */
	    Sym_SetAddress(sym, sym->u.addrsym.offset);
	}
    } else {
	yyerror("%i is multiply defined", sym->name);
    }

    va_end(args);
    
    return(sym);
}


/***********************************************************************
 *				Sym_Find
 ***********************************************************************
 * SYNOPSIS:	    Locate a symbol by ID
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The SymbolPtr for the thing or NULL if no such
 *	    	    symbol known.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/89		Initial Revision
 *
 ***********************************************************************/
SymbolPtr
Sym_Find(ID 	    id,
	 SymType    type,
	 int	    resolveInherits)
{
    SymBucketPtr    bucket;
    SymbolPtr	    sym;

    if (curProc && (type != SYM_PROC)) {
	/*
	 * Search the procedure-local symbols first
	 */
	for (bucket = (SymBucketPtr)curProc->u.proc.locals;
	     bucket != NULL;
	     bucket = bucket->next)
	{
	    for (sym = bucket->syms; sym < bucket->ptr; sym++) {
		if ((sym->name == id) && (sym->type != SYM_INHERIT)) {
		    return(sym);
		} else if (resolveInherits &&
			   (sym->type == SYM_INHERIT) &&
			   !sym->u.inherit.done)
		{
		    /*
		     * Attempt the resolve the name to a procedure.
		     */
		    SymResolveInherit(sym, curProc);
		}
	    }
	}
    }

    sym = SymLookup(id, type, (SymBucketPtr **)&bucket);
    if (sym != NULL && sym->type == SYM_PUBLIC) {
	/*
	 * The PUBLIC type is for our use only, allowing us to remember
	 * what symbols have been exported. If the symbol found is a PUBLIC,
	 * we just return NULL -- the symbol isn't really defined.
	 */
	return(NULL);
    } else if (sym == NULL && writing) {
	ID  pid = ST_DupNoEnter(output, id, output, permStrings);

	if (pid != NullID && pid != id) {
	    /*
	     * ID has permanent equivalent and we've not recursed yet (passed
	     * ID doesn't match permanent version), so look for a symbol with
	     * the permanent version now as well.
	     */
	    return(Sym_Find(pid, type, resolveInherits));
	} else {
	    return(NULL);
	}
    } else {
	return(sym);
    }
}


/***********************************************************************
 *				Sym_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize symbol-table stuff.
 * CALLED BY:	    main
 * RETURN:	    SymbolPtr for global segment scope
 * SIDE EFFECTS:    segments is initialized...
 *
 * STRATEGY:
 *	The global scope is an anonymous segment of type SEG_GLOBAL.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/22/89		Initial Revision
 *
 ***********************************************************************/
SymbolPtr
Sym_Init(void)
{
    /*
     * Set up segments and groups arrays to allow Sym_Enter to realloc them.
     */
    segments = (SymbolPtr *)malloc(sizeof(SymbolPtr));
    groups = (SymbolPtr *)malloc(sizeof(SymbolPtr));

    return(Sym_Enter(NullID, SYM_SEGMENT, SEG_GLOBAL));
}


/***********************************************************************
 *				Sym_ForEachSegment
 ***********************************************************************
 * SYNOPSIS:	    Iterate over all segments, calling a function for
 *	    	    each.
 * CALLED BY:	    Fix_Pass2, Fix_Pass3, Fix_Pass4
 * RETURN:	    Nothing
 * SIDE EFFECTS:    curSeg is set to the last segment processed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/89		Initial Revision
 *
 ***********************************************************************/
void
Sym_ForEachSegment(SymForEachProc   *func,
		   Opaque   	    data)
{
    int	    i;

    for (i = 0; i < numSegments; i++) {
	curSeg = segments[i];
	if ((*func)(curSeg, data)) {
	    break;
	}
    }
}


/***********************************************************************
 *				Sym_ForEachLocal
 ***********************************************************************
 * SYNOPSIS:	    Iterate over all local symbols for a procedure
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/89		Initial Revision
 *
 ***********************************************************************/
void
Sym_ForEachLocal(SymbolPtr  	proc,
		 SymForEachProc	*func,
		 Opaque	    	data)
{
    SymBucketPtr    bucket;
    SymbolPtr	    sym;

    assert(proc->type == SYM_PROC);

    for (bucket = (SymBucketPtr)proc->u.proc.locals;
	 bucket != 0;
	 bucket = bucket->next)
    {
	for (sym = bucket->syms; sym < bucket->ptr; sym++) {
	    if ((*func)(sym, data)) {
		break;
	    }
	}
    }
}


/***********************************************************************
 *				Sym_AdjustArgOffset
 ***********************************************************************
 * SYNOPSIS:	    Adjust the offsets for all existing arguments (i.e.
 *	    	    local vars with non-negative offsets) of a procedure.
 * CALLED BY:	    yyparse
 * RETURN:	    0 (continue scan)
 * SIDE EFFECTS:    see above
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/90		Initial Revision
 *
 ***********************************************************************/
int
SAAO_Callback(SymbolPtr	sym,
	      Opaque 	data)
{
    if (sym->u.localVar.offset >= 0) {
	sym->u.localVar.offset += (int)data;
    }
    return(0);
}

void
Sym_AdjustArgOffset(SymbolPtr	proc,
		    int	    	adjustment)
{
    Sym_ForEachLocal(proc, SAAO_Callback, (Opaque)adjustment);
}


/***********************************************************************
 *				Sym_ReferenceAllLocals
 ***********************************************************************
 * SYNOPSIS:	    Mark all local variables and args of a procedure as
 *	    	    referenced.
 * CALLED BY:	    yyparse
 * RETURN:	    0 (continue scan)
 * SIDE EFFECTS:    see above
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/90		Initial Revision
 *
 ***********************************************************************/
int
SRAL_Callback(SymbolPtr	sym,
	      Opaque 	data)
{
    Sym_Reference(sym);
    return(0);
}

void
Sym_ReferenceAllLocals(SymbolPtr	proc)
{
    Sym_ForEachLocal(proc, SRAL_Callback, (Opaque)0);
}

/******************************************************************************
 *
 *			   SYMBOL WRITE-OUT
 *
 *****************************************************************************/
/*
 * Data passed among the various routines. This saves having to pass
 * the address of heaps of local variables all the time...
 */
typedef struct {
    /*
     * Data for current symbol block.
     */
    VMBlockHandle   syms;   	/* Handle of current block */
    ObjSym  	    *nextSym;	/* Place to store next copied symbol */
    int	    	    symOff; 	/* Offset of same w/in syms */
    int	    	    symSize;	/* Total size of syms */
    MemHandle	    mem;    	/* Memory handle for syms */
    ObjSymHeader    *prevSymH;	/* Header of previous symbol block (for
				 * linking); 0 if none */
    VMBlockHandle   prevSyms;	/* Separate holding pen for 'syms' for
				 * linking. This allows us to set 'syms' to
				 * NULL to indicate the need for a new block */
    /*
     * Data for type descriptions.
     */
    VMBlockHandle   types;  	/* Current type block */
    ObjType 	    *nextType;	/* Address of next slot ObjType in types */
    int	    	    typeOff;	/* Offset of same w/in types */
    int	    	    typeSize;	/* Total size of types */
    MemHandle	    tmem;   	/* Memory handle of types */
} SymWriteData;

/***********************************************************************
 *				SymAllocTypeBlock
 ***********************************************************************
 * SYNOPSIS:	    Allocate a new type block.
 * CALLED BY:	    SymWriteSegment, SymAllocSymBlock
 * RETURN:	    Nothing
 * SIDE EFFECTS:    type-related data in swd reset
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/89	Initial Revision
 *
 ***********************************************************************/
static void
SymAllocTypeBlock(SymWriteData	*swd)
{
    if (swd->tmem) {
	ObjTypeHeader	*thdr;
	
	MemInfo(swd->tmem, (genptr *)&thdr, (word *)NULL);
	thdr->num = (swd->typeOff - sizeof(ObjTypeHeader))/sizeof(ObjType);

	/*
	 * Shrink to match offset, in case we're switching before the
	 * block is full...
	 */
	MemReAlloc(swd->tmem, swd->typeOff, 0);
    
	VMUnlockDirty(output, swd->types);
    }
    
    swd->typeSize = OBJ_INIT_TYPES;
    swd->types = VMAlloc(output, swd->typeSize, OID_TYPE_BLOCK);
    
    swd->typeOff = sizeof(ObjTypeHeader);
    swd->nextType = (ObjType *)((genptr)VMLock(output, swd->types, &swd->tmem) +
			       swd->typeOff);
}

/***********************************************************************
 *				SymConvertType
 ***********************************************************************
 * SYNOPSIS:	    Convert an internal type description to one that's
 *	    	    suitable for an object file
 * CALLED BY:	    SymWriteSegment
 * RETURN:	
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/25/89		Initial Revision
 *
 ***********************************************************************/
static void
SymConvertType(TypePtr	    	type,	    	/* Type to convert */
	       SymWriteData 	*swd,	    	/* Current write-out state */
	       unsigned short	*token)	    	/* Place to store initial
						 * description token */
{
    /*
     * For structured types, ot is the type record to be stored in the
     * block and next is the type to go in the second word, if any.
     */
    ObjType 	ot;
    TypePtr 	next;
    
    switch(type->tn_type) {
    case TYPE_INT:
	*token = OTYPE_INT|(type->tn_u.tn_int << 1)|OTYPE_SPECIAL;
	return;
    case TYPE_SIGNED:
	*token = OTYPE_SIGNED|(type->tn_u.tn_int << 1)|OTYPE_SPECIAL;
	return;
    case TYPE_CHAR:
	*token = OTYPE_CHAR|((type->tn_u.tn_charSize-1) << 1)|OTYPE_SPECIAL;
	return;
    case TYPE_VOID:
	*token = OTYPE_VOID|OTYPE_SPECIAL;
	return;
    case TYPE_NEAR:
	*token = OTYPE_NEAR|OTYPE_SPECIAL;
	return;
    case TYPE_FAR:
	*token = OTYPE_FAR|OTYPE_SPECIAL;
	return;
    case TYPE_PTR:
	if (type->tn_u.tn_ptr.tn_base->tn_type == TYPE_VOID) {
	    *token = OTYPE_PTR|(type->tn_u.tn_ptr.tn_ptrtype<<1)|OTYPE_SPECIAL;
	    return;
	} else {
	    ot.words[0] = (type->tn_u.tn_ptr.tn_ptrtype << 1)|OTYPE_SPECIAL;
	    next = type->tn_u.tn_ptr.tn_base;
	    break;
	}
    case TYPE_ARRAY:
	ot.words[0] = (0x8000|
		       ((type->tn_u.tn_array.tn_length<<1)&0x7ffe)|
		       OTYPE_SPECIAL);
	next = type->tn_u.tn_array.tn_base;
	break;
    case TYPE_STRUCT:
	OTYPE_ID_TO_STRUCT(SymPermanentName(type->tn_u.tn_struct), &ot);
	next = NULL;
	break;
    default:
	assert(0);
	return;
    }

    /*
     * See if this description has been written to the current block yet.
     * If so, use the offset of the previous instance.
     */
    if (type->tn_block == swd->types) {
	*token = type->tn_offset;
    } else {
	/*
	 * If need to convert a nested type, do it now into the ot record to
	 * avoid problems with the block being reallocated and moving on us.
	 */
	if (next != NULL) {
	    SymConvertType(next, swd, &ot.words[1]);
	}
	
	if (swd->typeOff == swd->typeSize) {
	    /*
	     * Add another record to the block. This could be considered
	     * inefficient, but the blocks are allocated large enough and 
	     * symbol blocks proportionately small enough (and the descriptions
	     * themselves are compact enough), that I don't anticipate this
	     * being executed very often. It might be the better part of wisdom
	     * to allocate several extra chunks at a time, however.
	     */
	    ObjTypeHeader	*base;
	    
	    swd->typeSize += sizeof(ObjType);
	    (void)MemReAlloc(swd->tmem, swd->typeSize, 0);
	    MemInfo(swd->tmem, (genptr *)&base, (word *)NULL);
	    swd->nextType = (ObjType *)((genptr)base + swd->typeOff);
	    base->num = (swd->typeSize - sizeof(ObjTypeHeader))/sizeof(ObjType);
	}
	
	type->tn_block = swd->types;
	type->tn_offset = *token = swd->typeOff;
	*swd->nextType++ = ot;
	swd->typeOff += sizeof(ObjType);
    }
}


/***********************************************************************
 *				SymAllocSymBlock
 ***********************************************************************
 * SYNOPSIS:	    Allocate a new symbol block for the current segment.
 * CALLED BY:	    SymWriteSegment
 * RETURN:	    The VMBlockHandle of the new block
 * SIDE EFFECTS:    All the variables passed in may have been altered.
 *	    	    If current types block is (over)full, a new one is
 *	    	    allocated.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/27/89		Initial Revision
 *
 ***********************************************************************/
static inline void
SymAllocSymBlock(SymWriteData	*swd,
		 ObjSegment    	*seg,	    	/* Segment descriptor in case
						 * this is the first symbol
						 * block for the segment */
		 word	    	segOff)	    	/* Offset of segment for
						 * header of new block */
{
    VMBlockHandle   	syms;

    /*
     * See if we can/should allocate a new type-description block now we're
     * switching symbol blocks.
     */
    if ((swd->typeOff == swd->typeSize) || (swd->typeSize > OBJ_INIT_TYPES)) {
	SymAllocTypeBlock(swd);
    }
	
    /*
     * Now allocate a new symbol block.
     */
    syms = VMAlloc(output, OBJ_MAX_SYMS, OID_SYM_BLOCK);
    swd->symSize = OBJ_MAX_SYMS;

    if (swd->prevSymH) {
	/*
	 * Link to previous and unlock prev.
	 */
	swd->prevSymH->next = syms;
	VMUnlockDirty(output, swd->prevSyms);
    } else {
	/*
	 * No previous => is first, so store the handle in the syms field
	 * of the segment descriptor.
	 */
	seg->syms = syms;
    }

    swd->prevSymH = (ObjSymHeader *)VMLock(output, syms, &swd->mem);
    swd->prevSymH->next = (VMBlockHandle)NULL;
    swd->prevSymH->types = swd->types;
    swd->prevSymH->seg = segOff;
    swd->prevSymH->num = (swd->symSize - sizeof(ObjSymHeader))/sizeof(ObjSym);
    swd->prevSyms = swd->syms = syms;
    swd->nextSym = (ObjSym *)(swd->prevSymH + 1);
    swd->symOff = sizeof(ObjSymHeader);
}
    

/***********************************************************************
 *				SymExpandBlock
 ***********************************************************************
 * SYNOPSIS:	    Make sure the current symbol block has enough
 *	    	    room to hold the number of bytes indicated
 * CALLED BY:	    SymWriteSegment for SYM_STRUCT, SYM_ETYPE and SYM_RECORD
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The block may be enlarged, with attendant alteration
 *	    	    of the state variables passed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/27/89		Initial Revision
 *
 ***********************************************************************/
static void
SymExpandBlock(SymWriteData *swd,
	       int  	    bytesNeeded)    /* Guess what? */
{
    if (swd->symOff + bytesNeeded > swd->symSize) {
	/*
	 * Set new size
	 */
	swd->symSize = swd->symOff + bytesNeeded;
	/*
	 * Enlarge block and get the new address.
	 * XXX: Have a MemReAllocLocked?
	 */
	(void)MemReAlloc(swd->mem, swd->symSize, 0);
	MemInfo(swd->mem, (genptr *)&swd->prevSymH, (word *)NULL);
	/*
	 * Adjust curSym for caller.
	 */
	swd->nextSym = (ObjSym *)((genptr)swd->prevSymH + swd->symOff);
	swd->prevSymH->num =
	    (swd->symSize - sizeof(ObjSymHeader))/sizeof(ObjSym);
    }
}

/***********************************************************************
 *				SymCheckUnref
 ***********************************************************************
 * SYNOPSIS:	    Check for locally defined, statically scoped,
 *	    	    unreferenced symbols. Also provides a filter
 *	    	    for unreferenced, undefined externals
 * CALLED BY:	    SymWriteSegment
 * RETURN:	    0 if symbol shouldn't go in the output file.
 * SIDE EFFECTS:    A warning may be generated
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 7/89	Initial Revision
 *
 ***********************************************************************/
static int
SymCheckUnref(SymbolPtr	sym,	    /* Symbol to check */
	      SymbolPtr	proc,	    /* Containing procedure, if any */
	      ID    	file,
	      int   	line,
	      int   	*lastRefOffPtr)
{
    if (!(sym->flags & SYM_REF)) {
	if (warn_unreach && !(sym->flags & SYM_UNDEF) &&
	    ((sym->type == SYM_LABEL) || (sym->type == SYM_LOCALLABEL)) &&
	    sym->u.label.unreach)
	{
	    /*
	     * See if the most-recently referenced label was at the same
	     * offset as this label, or if there follows another label at the
	     * same address that's referenced. If either is true, the code
	     * that follows isn't actually unreachable.
	     */
	    int	    confirmed = TRUE;
	    
	    if ((lastRefOffPtr != NULL) &&
		(sym->u.addrsym.offset != *lastRefOffPtr))
	    {
		SymbolPtr   next;

		for (next = sym->u.addrsym.next;
		     ((next != NullSymbol) &&
		      (next->u.addrsym.offset == sym->u.addrsym.offset));
		     next = next->u.addrsym.next)
		{
		    if (next->flags & SYM_REF) {
			confirmed = FALSE;
			break;
		    }
		}
	    } else if (lastRefOffPtr != NULL) {
		confirmed = FALSE;
	    }
	    
	    if (confirmed) {
		SymbolPtr   prevProc = curProc;

		curProc = proc;
		Notify(NOTIFY_WARNING, file, line,
		       "code after %i cannot be reached", sym->name);
		curProc = prevProc;
	    }
	}
	    
	if (sym->flags & SYM_GLOBAL) {
	    if ((sym->flags & SYM_UNDEF) ||
		((sym->type == SYM_PROTOMINOR) &&
		 (sym->segment->u.segment.data->comb != SEG_LIBRARY)))
	    {
		/*
		 * Undefined, unreferenced globals don't make it to the
		 * output file -- they'd just waste space. Same for
		 * unreferenced protominor symbols, unless they're in
		 * a non-library segment, which means they're defined by this
		 * geode, not a library.
		 */
		return(0);
	    }
	} else if ((sym->type != SYM_LOCALLABEL && warn_unref) ||
		   (sym->type == SYM_LOCALLABEL && warn_local_unref))
	{
	    /*
	     * 2/28/92: don't warn about nameless undefined things, as they're
	     * usually referenced off nearby named things. -- ardeb
	     */
	    if (sym->name != NullID) {
		SymbolPtr   prevProc = curProc;

		curProc = proc;
		Notify(NOTIFY_WARNING, file, line,
		       "%i defined but never used",
		       sym->name);
		curProc = prevProc;
	    }
	}
    } else if ((lastRefOffPtr != NULL) &&
	       ((sym->type == SYM_LABEL) || (sym->type == SYM_LOCALLABEL)))
    {
	*lastRefOffPtr = sym->u.addrsym.offset;
    }
    
    return(1);
}
/*XXX
static int stringBlocks = 0;
static int stringEquates = 0;
*/

/***********************************************************************
 *				SymWriteNonAddress
 ***********************************************************************
 * SYNOPSIS:	    Search the table for symbols w/o addresses that belong
 *	    	    to this segment and write them out.
 * CALLED BY:	    SymWriteSegment for non-library segments
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/28/90		Initial Revision
 *
 ***********************************************************************/
static void
SymWriteNonAddress(ObjSegment	*seg,
		   SymWriteData	*swdp,
		   word	    	segOff,
		   SymbolPtr	segSym)
{
    int	    	    i;
    SymbolPtr	    sym;
    
    /*
     * Close out the current type block so the linker doesn't have to worry
     * about trimming wasted space from a duplicated type block.
     */
    if (swdp->typeOff != sizeof(ObjTypeHeader)) {
	SymAllocTypeBlock(swdp);
    }
    
    /*
     * Now run through the symbol table, looking for symbols for this
     * segment that haven't been written out yet.
     */
    swdp->syms = NULL;
    for (i = 0; i < SYM_BUCKETS; i++) {
	SymBucketPtr	bucket;
	
	for (bucket = symTable[i]; bucket; bucket = bucket->next) {
	    for (sym = bucket->syms; sym < bucket->ptr; sym++) {
		if ((sym->segment != segSym) || (sym->flags & SYM_NOWRITE))
		{
		    continue;
		}
		
		switch(sym->type) {
		    case SYM_LASTADDR:
		    case SYM_LOCALLABEL:
		    case SYM_LINE:
		    case SYM_ONSTACK:
			/*
			 * Can't be declared global, so they can't be
			 * undefined and they've already been handled above.
			 */
		    case SYM_VAR:
			if (sym->flags & SYM_UNDEF) {
			    ObjSym	osym;
			    
			    if (!SymCheckUnref(sym, NULL, NullID, 0, NULL)) {
				break;
			    }
			    
			    osym.name = SymPermanentName(sym);
			    osym.type = OSYM_VAR;
			    osym.flags = sym->flags;
			    SymConvertType(sym->u.var.type, swdp,
					   &osym.u.variable.type);
			    if (swdp->syms == NULL) {
				SymAllocSymBlock(swdp, seg, segOff);
			    }
			    /*
			     * Record block and offset for the symbol in
			     * case there are relocations to it...
			     */
			    sym->u.objsym.block = swdp->syms;
			    sym->u.objsym.offset = swdp->symOff;
			    *swdp->nextSym++ = osym;
			    swdp->symOff += sizeof(ObjSym);
			}
			break;
		    case SYM_LABEL:
			if (sym->flags & SYM_UNDEF) {
			    ObjSym	osym;
			    
			    if (!SymCheckUnref(sym, NULL, NullID, 0, NULL)) {
				break;
			    }
			    
			    osym.name = SymPermanentName(sym);
			    osym.type = OSYM_LABEL;
			    osym.flags = sym->flags;
			    osym.u.label.near = sym->u.label.near;
			    if (swdp->syms == NULL) {
				SymAllocSymBlock(swdp, seg, segOff);
			    }
			    /*
			     * Record block and offset for the symbol in
			     * case there are relocations to it...
			     */
			    sym->u.objsym.block = swdp->syms;
			    sym->u.objsym.offset = swdp->symOff;
			    *swdp->nextSym++ = osym;
			    swdp->symOff += sizeof(ObjSym);
			}
			break;
		    case SYM_PROTOMINOR:
			if (sym->flags & SYM_UNDEF) {
			    ObjSym	osym;
			    
			    if (!SymCheckUnref(sym, NULL, NullID, 0, NULL)) {
				break;
			    }
			    
			    osym.name = SymPermanentName(sym);
			    osym.type = OSYM_PROTOMINOR;
			    osym.flags = sym->flags;
			    if (swdp->syms == NULL) {
				SymAllocSymBlock(swdp, seg, segOff);
			    }
			    /*
			     * Record block and offset for the symbol in
			     * case there are relocations to it...
			     */
			    sym->u.objsym.block = swdp->syms;
			    sym->u.objsym.offset = swdp->symOff;
			    *swdp->nextSym++ = osym;
			    swdp->symOff += sizeof(ObjSym);
			}
			break;
		    case SYM_PROC:
			if (sym->flags & SYM_UNDEF) {
			    ObjSym	osym;
			    
			    if (!SymCheckUnref(sym, NULL, NullID, 0, NULL)) {
				break;
			    }
			    
			    osym.name = SymPermanentName(sym);
			    osym.type = OSYM_PROC;
			    osym.flags = sym->flags;
			    osym.u.proc.flags = sym->u.proc.flags;
			    osym.u.proc.local = 0;
			    if (swdp->syms == NULL) {
				SymAllocSymBlock(swdp, seg, segOff);
			    }
			    /*
			     * Record block and offset for the symbol in
			     * case there are relocations to it...
			     */
			    sym->u.objsym.block = swdp->syms;
			    sym->u.objsym.offset = swdp->symOff;
			    *swdp->nextSym++ = osym;
			    swdp->symOff += sizeof(ObjSym);
			}
			break;
		    case SYM_CLASS:
			if (sym->flags & SYM_UNDEF) {
			    ObjSym	osym;
			    
			    if (!SymCheckUnref(sym, NULL, NullID, 0, NULL)) {
				break;
			    }
			    
			    osym.name = SymPermanentName(sym);
			    if (sym->u.class.data->flags & SYM_CLASS_VARIANT) {
				osym.type = OSYM_VARIANT_CLASS;
			    } else if (sym->u.class.data->flags&SYM_CLASS_MASTER) {
				osym.type = OSYM_MASTER_CLASS;
			    } else {
				osym.type = OSYM_CLASS;
			    }
			    osym.flags = sym->flags;
			    if (sym->u.class.super) {
				Sym_Reference(sym->u.class.super);
				OBJ_STORE_SID(osym.u.class.super,
				   SymPermanentName(sym->u.class.super));
			    } else {
				OBJ_STORE_SID(osym.u.class.super, NullID);
			    }
			    
			    if (swdp->syms == NULL) {
				SymAllocSymBlock(swdp, seg, segOff);
			    }
			    /*
			     * Record block and offset for the symbol in case
			     * there are relocations to it...
			     */
			    sym->u.objsym.block = swdp->syms;
			    sym->u.objsym.offset = swdp->symOff;
			    *swdp->nextSym++ = osym;
			    swdp->symOff += sizeof(ObjSym);
			}
			break;
		    case SYM_CHUNK:
			if (sym->flags & SYM_UNDEF) {
			    ObjSym	osym;
			    
			    if (!SymCheckUnref(sym, NULL, NullID, 0, NULL)) {
				break;
			    }
			    
			    osym.name = SymPermanentName(sym);
			    osym.type = OSYM_CHUNK;
			    osym.flags = sym->flags;
			    SymConvertType(sym->u.chunk.type, swdp,
					   &osym.u.chunk.type);
			    if (swdp->syms == NULL) {
				SymAllocSymBlock(swdp, seg, segOff);
			    }
			    /*
			     * Record block and offset for the symbol in case there
			     * are relocations to it...
			     */
			    sym->u.objsym.block = swdp->syms;
			    sym->u.objsym.offset = swdp->symOff;
			    *swdp->nextSym++ = osym;
			    swdp->symOff += sizeof(ObjSym);
			}
			break;
		    case SYM_BITFIELD:
		    case SYM_FIELD:
		    case SYM_ENUM:
		    case SYM_METHOD:
		    case SYM_INSTVAR:
			/*
			 * Type-members are dealt with when their containing
			 * type is written.
			 */
			break;
		    case SYM_STRING:
			/* XXX
		    {
			MBlk	*mp;

			stringEquates += 1;
			for (mp = sym->u.string.value; mp != NULL; mp = mp->next) {
			    if (mp->dynamic) {
				stringBlocks += 1;
			    }
			}
		    }
		    */

		    case SYM_MACRO:
			/*
			 * These don't make it to the file
			 */
			break;
		    case SYM_LOCAL:
			/*
			 * These were handled with their corresponding proc
			 */
			break;
		    case SYM_NUMBER:
		    {
			if (seg->type == SEG_LIBRARY) {
			    break;
			}
			/*
			 * If defined with EQU, convert to numeric and store.
			 */
			if (((sym->flags & SYM_UNDEF) == 0) &&
			    sym->u.equate.rdonly)
			{
			    ExprResult	res;
			    byte    	status;
			    ObjSym  	osym;
			    
			    Sym_Reference(sym);
			    
			    if (!Expr_Eval(sym->u.equate.value, &res,
					   (EXPR_NOUNDEF|EXPR_FINALIZE|
					    EXPR_NOT_OPERAND), &status))
			    {
				Notify(NOTIFY_ERROR,
				       sym->u.equate.value->file,
				       sym->u.equate.value->line,
				       "Cannot store value for %i in output table: %s",
				       sym->name, (char *)res.type);
				break;
			    } else if (res.type != EXPR_TYPE_CONST) {
				/*
				 * Only numeric constants actually make it into
				 * the symbol table.
				 */
				break;
			    } else {
				osym.u.constant.value = res.data.number;
				/*
				 * XXX: record block/offset?
				 */
			    }
			    osym.name = SymPermanentName(sym);
			    osym.type = OSYM_CONST;
			    osym.flags = sym->flags;
			    
			    if (swdp->syms == NULL) {
				SymAllocSymBlock(swdp, seg, segOff);
			    }
			    *swdp->nextSym++ = osym;
			    swdp->symOff += sizeof(ObjSym);
			}
			break;
		    }
		    case SYM_STRUCT:
		    case SYM_UNION:
		    {
			/*
			 * Convert to external and store fields
			 */
			unsigned char   stype;
			
			if (seg->type == SEG_LIBRARY) {
			    break;
			}
			stype = ((sym->type == SYM_STRUCT) ? OSYM_STRUCT :
				 OSYM_UNION);
			
			if (swdp->syms == NULL) {
			    SymAllocSymBlock(swdp, seg, segOff);
			}
			Sym_Reference(sym);
			if (sym->u.sType.first == NullSymbol) {
			    swdp->nextSym->name =    	SymPermanentName(sym);
			    swdp->nextSym->type =	    	stype;
			    swdp->nextSym->flags =	    	sym->flags;
			    swdp->nextSym->u.sType.size = 	0;
			    swdp->nextSym->u.sType.first = 	0;
			    swdp->nextSym->u.sType.last = 	0;
			    swdp->nextSym++;
			    swdp->symOff += sizeof(ObjSym);
			} else {
			    int 	    j;
			    SymbolPtr   fld;
			    
			    for(j = 1, fld = sym->u.sType.first;
				fld->type != SYM_STRUCT && fld->type != SYM_UNION;
				fld = fld->u.eltsym.next)
			    {
			    	Sym_Reference(fld);
				j += 1;
			    }
			    
			    /*
			     * Make sure we've enough room for these things.
			     */
			    SymExpandBlock(swdp, j * sizeof(ObjSym));
			    /*
			     * Convert the STRUCT symbol to external.
			     *
			     * XXX: since the fields always follow immediately
			     * after, do we really need the 'first' field? or
			     * the 'next' fields in the data for the symbols
			     * themselves? Might it be better to record if
			     * an instance variable is public/private/state?
			     */
			    swdp->nextSym->name =    	SymPermanentName(sym);
			    swdp->nextSym->type = 	stype;
			    swdp->nextSym->flags =     	sym->flags;
			    swdp->nextSym->u.sType.size = 	sym->u.typesym.size;
			    swdp->nextSym->u.sType.first =
				swdp->symOff + sizeof(ObjSym);
			    swdp->nextSym->u.sType.last =
				swdp->symOff + (j-1)*sizeof(ObjSym);
			    
			    swdp->nextSym++;
			    swdp->symOff += sizeof(ObjSym);
			    
			    /*
			     * Convert the constituent fields.
			     */
			    for (fld = sym->u.sType.first;
				 fld->type != SYM_STRUCT && fld->type != SYM_UNION;
				 fld = fld->u.eltsym.next)
			    {
				swdp->nextSym->name =  	SymPermanentName(fld);
				swdp->nextSym->type =  	    OSYM_FIELD;
				swdp->nextSym->flags = 	    fld->flags;
				swdp->nextSym->u.sField.next =
				    swdp->symOff+sizeof(ObjSym);
				
				if (fld->type == SYM_FIELD) {
				    swdp->nextSym->u.sField.offset =
					fld->u.field.offset;
				    SymConvertType(fld->u.field.type, swdp,
						   &swdp->nextSym->u.sField.type);
				} else {
				    /*
				     * Must be instance variable
				     */
				    swdp->nextSym->u.sField.offset =
					fld->u.instvar.offset;
				    SymConvertType(fld->u.instvar.type, swdp,
						   &swdp->nextSym->u.sField.type);
				}
				
				swdp->nextSym++;
				swdp->symOff += sizeof(ObjSym);
			    }
			}
			break;
		    }
		    case SYM_RECORD:
			/*
			 * Convert to external and store fields
			 */
			if (seg->type == SEG_LIBRARY) {
			    break;
			}
			if (swdp->syms == NULL) {
			    SymAllocSymBlock(swdp, seg, segOff);
			}
			Sym_Reference(sym);
			if (sym->u.sType.first == NullSymbol) {
			    swdp->nextSym->name =    	SymPermanentName(sym);
			    swdp->nextSym->type =	    	OSYM_RECORD;
			    swdp->nextSym->flags =	    	sym->flags;
			    swdp->nextSym->u.sType.size = 	0;
			    swdp->nextSym->u.sType.first = 	0;
			    swdp->nextSym->u.sType.last = 	0;
			    swdp->nextSym++;
			    swdp->symOff += sizeof(ObjSym);
			} else {
			    int 	    j;
			    SymbolPtr   fld;
			    
			    for(j = 1, fld = sym->u.sType.first;
				fld->type != SYM_RECORD;
				fld = fld->u.eltsym.next)
			    {
				Sym_Reference(fld);
				j += 1;
			    }
			    /*
			     * Make sure we've enough room for these things.
			     */
			    SymExpandBlock(swdp, j * sizeof(ObjSym));
			    /*
			     * Convert the RECORD symbol to an external RECORD
			     *
			     * XXX: since the fields always follow immediately
			     * after, do we really need the 'first' field? or
			     * the 'next' fields in the data for the symbols
			     * themselves? Might it be better to record if
			     * an instance variable is public/private/state?
			     */
			    swdp->nextSym->name =     	SymPermanentName(sym);
			    swdp->nextSym->type =     	OSYM_RECORD;
			    swdp->nextSym->flags =     	sym->flags;
			    swdp->nextSym->u.sType.size =sym->u.typesym.size;
			    swdp->nextSym->u.sType.first =
				swdp->symOff + sizeof(ObjSym);
			    swdp->nextSym->u.sType.last =
				swdp->symOff + (j-1)*sizeof(ObjSym);
			    
			    swdp->nextSym++;
			    swdp->symOff += sizeof(ObjSym);
			    
			    /*
			     * Convert the constituent members.
			     */
			    for (fld = sym->u.sType.first;
				 fld->type != SYM_RECORD;
				 fld = fld->u.eltsym.next)
			    {
				swdp->nextSym->name =  SymPermanentName(fld);
				swdp->nextSym->type =  	    OSYM_BITFIELD;
				swdp->nextSym->flags = 	    fld->flags;
				swdp->nextSym->u.bField.next =
				    swdp->symOff+sizeof(ObjSym);
				
				swdp->nextSym->u.bField.offset =
				    fld->u.bitField.offset;
				swdp->nextSym->u.bField.width =
				    fld->u.bitField.width;
				
				if (fld->u.bitField.type) {
				    /*
				     * If bitfield not typeless, convert the
				     * type description.
				     */
				    SymConvertType(fld->u.bitField.type, swdp,
						   &swdp->nextSym->u.bField.type);
				} else {
				    /*
				     * Else use special "bitfield" type to
				     * indicate the typelessness.
				     */
				    swdp->nextSym->u.bField.type =
					(OTYPE_BITFIELD|OTYPE_SPECIAL|
					 (fld->u.bitField.width <<
					  OTYPE_BF_WIDTH_SHIFT) |
					 (fld->u.bitField.offset <<
					  OTYPE_BF_OFFSET_SHIFT));
				}
				
				swdp->nextSym++;
				swdp->symOff += sizeof(ObjSym);
			    }
			}
			break;
		    case SYM_ETYPE:
			/*
			 * Convert to external and store members
			 */
			if (seg->type == SEG_LIBRARY) {
			    break;
			}
			if (swdp->syms == NULL) {
			    SymAllocSymBlock(swdp, seg, segOff);
			}
			Sym_Reference(sym);
			
			if (sym->u.eType.mems->type == SYM_ETYPE) {
			    swdp->nextSym->name =    	SymPermanentName(sym);
			    swdp->nextSym->type =	OSYM_ETYPE;
			    swdp->nextSym->flags =	sym->flags;
			    swdp->nextSym->u.sType.size =sym->u.typesym.size;
			    swdp->nextSym->u.sType.first =	0;
			    swdp->nextSym->u.sType.last = 	0;
			    swdp->nextSym++;
			    swdp->symOff += sizeof(ObjSym);
			} else {
			    int 	    j;
			    SymbolPtr   fld;
			    
			    for(j = 1, fld = sym->u.eType.mems;
				fld->type != SYM_ETYPE;
				fld = fld->u.eltsym.next)
			    {
				Sym_Reference(fld);
				j += 1;
			    }
			    /*
			     * Make sure we've enough room for these things.
			     */
			    SymExpandBlock(swdp, j * sizeof(ObjSym));
			    /*
			     * Convert the ETYPE symbol to an external ETYPE.
			     *
			     * XXX: since the fields always follow immediately
			     * after, do we really need the 'first' field? or
			     * the 'next' fields in the data for the symbols
			     * themselves? Might it be better to record if
			     * an instance variable is public/private/state?
			     */
			    swdp->nextSym->name =     	SymPermanentName(sym);
			    swdp->nextSym->type =     	OSYM_ETYPE;
			    swdp->nextSym->flags =     	sym->flags;
			    swdp->nextSym->u.sType.size = sym->u.typesym.size;
			    swdp->nextSym->u.sType.first =
				swdp->symOff + sizeof(ObjSym);
			    swdp->nextSym->u.sType.last =
				swdp->symOff + (j-1)*sizeof(ObjSym);
			    
			    swdp->nextSym++;
			    swdp->symOff += sizeof(ObjSym);
			    
			    /*
			     * Convert the constituent fields.
			     */
			    for (fld = sym->u.eType.mems;
				 fld->type != SYM_ETYPE;
				 fld = fld->u.eltsym.next)
			    {
				swdp->nextSym->name = SymPermanentName(fld);
				swdp->nextSym->flags = fld->flags;
				swdp->nextSym->u.eField.next =
				    swdp->symOff+sizeof(ObjSym);
				
				if (fld->type == SYM_ENUM) {
				    swdp->nextSym->type = 	    OSYM_ENUM;
				    swdp->nextSym->u.eField.value =
					fld->u.econst.value;
				} else if (fld->type == SYM_METHOD) {
				    /*
				     * Must be method
				     */
				    swdp->nextSym->type =	    OSYM_METHOD;
				    swdp->nextSym->u.method.value =
					fld->u.method.common.value;
				    if (geosRelease >= 2) {
					swdp->nextSym->u.method.flags =
					    fld->u.method.flags;
				    } else {
					/*
					 * Don't write the whole flags word
					 * out for 1.X, as the offset that we
					 * store in the RANGE_LENGTH field
					 * internally causes problems on
					 * linking if of two modules, one
					 * includes the file with the
					 * ImportMethod macros. The only flag
					 * that's used is the PUBLIC one.
					 */
					swdp->nextSym->u.method.flags =
					    fld->u.method.flags & SYM_METH_PUBLIC;
				    }
				} else {
				    /*
				     * Must be vardata
				     */
				    swdp->nextSym->type =   	OSYM_VARDATA;
				    swdp->nextSym->u.varData.value =
					fld->u.varData.common.value;
				    if (fld->u.varData.type) {
					SymConvertType(fld->u.varData.type,
						       swdp,
						       &swdp->nextSym->u.varData.type);
				    } else {
					swdp->nextSym->u.varData.type = OTYPE_VOID|OTYPE_SPECIAL;
				    }
				}
				
				swdp->nextSym++;
				swdp->symOff += sizeof(ObjSym);
			    }
			}
			break;
		    case SYM_TYPE:
		    {
			/*
			 * Convert to external and store
			 */
			if (seg->type == SEG_LIBRARY) {
			    break;
			}
			Sym_Reference(sym);
			
			if (swdp->syms == NULL) {
			    SymAllocSymBlock(swdp, seg, segOff);
			}
			swdp->nextSym->name = SymPermanentName(sym);
			swdp->nextSym->type = OSYM_TYPEDEF;
			swdp->nextSym->flags = sym->flags;
			SymConvertType(sym->u.typeDef.type, swdp,
				       &swdp->nextSym->u.typeDef.type);
			
			swdp->nextSym++;
			swdp->symOff += sizeof(ObjSym);
			break;
		    }
		    case SYM_PUBLIC:
			/*
			 * There should be none of these remaining.
			 */
			Notify(NOTIFY_ERROR, sym->u.public.file,
			       sym->u.public.line,
			       "%i: declared PUBLIC but not defined",
			       sym->name);
			break;
		}
		assert(!swdp->syms || swdp->symOff <= swdp->symSize);
		/*
		 * If we're at the end of the block, set syms to NULL so we'll
		 * allocate another block for the next symbol.
		 */
		if (swdp->symOff == swdp->symSize) {
		    swdp->syms = NULL;
		}
	    }
	}
    }
}

/***********************************************************************
 *				SymWriteSegment
 ***********************************************************************
 * SYNOPSIS:	    Write out the symbols for a segment.
 * CALLED BY:	    Sym_ProcessSegments
 * RETURN:	    1 if successful
 * SIDE EFFECTS:    All symbols with addresses have their data transformed
 *	    	    to the objsym format (i.e. with the handle and offset
 *	    	    of their in-file representation).
 *
 * STRATEGY:
 *	The symbol table is divided into blocks of no more than 8Kb,
 *	when possible. All items in a symbol block are longword aligned,
 *	as there is a longword-sized field at the start.
 *
 *	In general, blocks are allocated large and only shrunk if they
 *	remain incompletely used when everything is done.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/24/89		Initial Revision
 *
 ***********************************************************************/
static int
SymWriteSegment(SymbolPtr   segSym,
		ObjSegment  *seg)
{
    SymWriteData    	swd;	    /* State of the write-out. Passed to the
				     * various utility routines in lieu of
				     * passing the address of pretty much
				     * every local variable we've got */
    /*
     * Line number block data
     */
    VMBlockHandle   	lines;	    /* Current line info block handle */
    MemHandle	    	lineHandle; /* Memory handle in case of resize */
    ObjLine 	    	*curLine;   /* Current line record */
    int	    	    	curLOff;    /* Offset withing line block */
    ID 	    	    	*curFile;   /* Record containing current file */
    ObjLineHeader   	*prevLineH; /* Header for previous line block (for
				     * linking) */
    VMBlockHandle   	prevLines;  /* Block to unlock once link is made */
    VMBlockHandle   	lineMap;    /* Block containing map for line blocks */
    /*
     * Other things
     */
    ObjSym  	    	*lastProc;  /* Most recent procedure (for linking
				     * local labels) */
    SymbolPtr	    	lastProcSym;/* Internal form of same */
    SymbolPtr	    	sym;	    /* Symbol being processed */
    word    	    	segOff;	    /* Offset of segment descriptor in map
				     * block (for SymAllocSymBlock) */
    ID  	    	file;	    /* File of most-recently encountered
				     * SYM_LINE */
    int 	    	line;	    /* Line number of same */
    int 	    	lastRefOff; /* Offset of last-referenced label, for
				     * telling whether code after an
				     * unreferenced label is unreachable */

    segOff = segSym->u.segment.data->offset;

    /*
     * Set up initial type description block.
     */
    swd.tmem = NULL;		/* So don't try to close non-existent block */
    SymAllocTypeBlock(&swd);

    sym = segSym->u.segment.data->first;
    
    swd.prevSymH = (ObjSymHeader *)NULL;
    swd.prevSyms = (VMBlockHandle)NULL;
    prevLineH = (ObjLineHeader *)NULL;
    
    swd.syms = lines = lineMap = (VMBlockHandle)NULL;

    lastRefOff = -1;
    file = NullID;
    line = 0;

    /*
     * First write out all the symbols with addresses in address-order.
     * Doing so allows us to slap the blocks wholesale into the new table
     * when linking, since Swat needs to have a list of symbols in
     * address-order.
     */
    while (sym != NULL) {
	/*
	 * Figure where we should end this next block of symbols, taking
	 * into account the need for procedures to have their local symbols
	 * in the same VM block and that local labels need to be written
	 * in order, not just immediately after their corresponding proc.
	 */
	SymbolPtr	endSym;	    /* Symbol with which to stop filling
				     * this block and move on to the next.
				     * This is figured out before the block
				     * is allocated to take any procedure-local
				     * symbols that must be written into
				     * account */
	SymbolPtr    	mustReach;  /* Symbol that endSym must reach, if
				     * any, before we can stop filling the
				     * block. This is used to make sure that
				     * all local labels for a procedure make
				     * it into the block */

	endSym = sym;
	mustReach = NULL;
	swd.symSize = sizeof(ObjSymHeader);
	while ((endSym != NULL) &&
	       ((mustReach != NULL) || (swd.symSize < OBJ_MAX_SYMS)))
	{
	    /*
	     * If got where we had to be, remove the goal, allowing
	     * us to break out if the block is too big.
	     */
	    if (endSym == mustReach) {
		mustReach = NULL;
	    }
	    switch(endSym->type) {
	    case SYM_LINE:
		/*
		 * Lines don't go into symbol blocks.
		 */
		break;
	    case SYM_PROC:
	    {
		/*
		 * Find the last local label and add in the sizes
		 * of all the procedure-local symbols
		 */
		SymBucketPtr	bucket;
		SymbolPtr   	local;
		
		for (bucket = (SymBucketPtr)endSym->u.proc.locals;
		     bucket != NULL;
		     bucket = bucket->next)
		{
		    for (local = bucket->syms;
			 local < bucket->ptr;
			 local++)
		    {
			if (local->flags & SYM_NOWRITE) {
			    continue;
			}
			/*
			 * If this one's a local label and comes
			 * after mustReach in the by-address list,
			 * record it as the symbol that must be
			 * reached. Its size will be added in when it's
			 * encountered in the by-address list.
			 */
			if (local->type == SYM_LOCALLABEL) {
			    if (mustReach == NULL) {
				mustReach = local;
			    } else if (local->u.addrsym.offset >
				       mustReach->u.addrsym.offset)
			    {
				mustReach = local;
			    } else if (local->u.addrsym.offset ==
				       mustReach->u.addrsym.offset)
			    {
				/*
				 * If there are multiple local labels at the
				 * same address, we have to make sure mustReach
				 * points to the *last* one with that address,
				 * so we run down the by-address list from the
				 * local label so long as the address is still
				 * the same. Any non-local label can go in
				 * another block, so we avoid setting mustReach
				 * to such a beast if it is encountered.
				 */
				SymbolPtr   asym;
				
				for (asym = local;
				     (asym != NULL) &&
				     (asym->u.addrsym.offset ==
				      mustReach->u.addrsym.offset);
				     asym = asym->u.addrsym.next)
				{
				    if (asym->type == SYM_LOCALLABEL) {
					mustReach = asym;
				    }
				}
			    }
			} else {
			    swd.symSize += sizeof(ObjSym);
			}
		    }
		}
		/*
		 * Add in procedure symbol
		 */
		swd.symSize += sizeof(ObjSym);
		break;
	    }
	    case SYM_CLASS:
	    {
		/*
		 * Add in the size of all the method bindings for the class.
		 */
		SymBucketPtr	bucket;
		
		for (bucket = (SymBucketPtr)endSym->u.class.data->bindings;
		     bucket != NULL;
		     bucket = bucket->next)
		{
		    swd.symSize += (bucket->ptr-bucket->syms) * sizeof(ObjSym);
		}
		/*
		 * Add in class symbol 
		 */
		swd.symSize += sizeof(ObjSym);
		break;
	    }
	    default:
		if ((endSym->flags & SYM_NOWRITE) == 0) {
		    swd.symSize += sizeof(ObjSym);
		}
		break;
	    }
	    endSym = endSym->u.addrsym.next;
	}
	
	if (swd.symSize != sizeof(ObjSymHeader)) {
	    /*
	     * Now allocate the block and perform a loop similar to the
	     * above, except now we actually convert the symbols to
	     * external form and record their locations.
	     */
	    VMBlockHandle   syms;
	    
	    syms = VMAlloc(output, swd.symSize, OID_SYM_BLOCK);
	    if (swd.prevSymH) {
		swd.prevSymH->next = syms;
		VMUnlockDirty(output, swd.prevSyms);
	    } else {
		seg->syms = syms;
	    }

	    swd.prevSyms = swd.syms = syms;
	    
	    /*
	     * Lock down the block and initialize the header,
	     * null-terminating the chain and storing the current types
	     * block as our companion block.
	     */
	    swd.prevSymH = (ObjSymHeader *)VMLock(output,
						  swd.syms,
						  (MemHandle *)&swd.mem);
	    swd.prevSymH->next = (VMBlockHandle)NULL;
	    swd.prevSymH->types = swd.types;
	    swd.prevSymH->seg = segOff;
	    swd.prevSymH->num =
		(swd.symSize - sizeof(ObjSymHeader)) / sizeof(ObjSym);
	    swd.nextSym = (ObjSym *)(swd.prevSymH+1);
	    swd.symOff = sizeof(ObjSymHeader);
	}
	
	while (sym != endSym) {
	    /*
	     * Place to store offset of current symbol. It is needed b/c
	     * a SYM_PROC is followed by its local symbols, thus
	     * nuking swd.symOff. To avoid having to store the block and
	     * offset in each arm of the switch, below, we save the
	     * swd.symOff at the start and use that to convert the sym
	     * to an objSym.
	     */
	    unsigned short	symOff;
	    SymbolPtr   	nextSym;
	    
	    if (sym->type != SYM_LINE) {
		if ((sym->type != SYM_ONSTACK) && (sym->name != NullID)) {
		    (void)SymCheckUnref(sym,
					(sym->type == SYM_LOCALLABEL ?
					 lastProcSym:NULL),
					file, line, &lastRefOff);
		}
		
		/*
		 * If symbol not being written out, skip it.
		 */
		if (sym->flags & SYM_NOWRITE) {
		    sym = sym->u.addrsym.next;
		    continue;
		}
		
		swd.nextSym->name = SymPermanentName(sym);
		swd.nextSym->flags = sym->flags;
		swd.nextSym->u.addrSym.address = sym->u.addrsym.offset;
		symOff = swd.symOff;
	    } else {
		file = sym->u.line.file;
		line = sym->u.line.line;
	    }
	    
	    switch(sym->type) {
	    case SYM_LINE:
		/*
		 * Only bother with line numbers if the segment's got actual
		 * size to it...
		 */
		if (seg->size != 0) {
		    if (lines == NULL) {
			ObjAddrMapHeader	*oamh;
			ObjAddrMapEntry 	*oame;
			MemHandle       	lmmem;

			if (lineMap == NULL) {
			    /*
			     * Initializes to zero for us. right?
			     */
			    seg->lines =
				lineMap = VMAlloc(output,
						  sizeof(ObjAddrMapHeader),
						  OID_ADDR_MAP);
			}
			/*
			 * Expand the line map by another entry and point oame
			 * at the newly created entry.
			 */
			oamh = (ObjAddrMapHeader *)VMLock(output, lineMap,
							  &lmmem);
			oamh->numEntries += 1;
			MemReAlloc(lmmem,
				   sizeof(ObjAddrMapHeader)+
				   (oamh->numEntries * sizeof(ObjAddrMapEntry)),
				   0);
			MemInfo(lmmem, (genptr *)&oamh, (word *)NULL);
			oame =
			    &((ObjAddrMapEntry *)(oamh+1))[oamh->numEntries-1];
		    
			/*
			 * No current block for line numbers -- allocate
			 * one and link it in.
			 */
			lines = VMAlloc(output,
					OBJ_INIT_LINES,
					OID_LINE_BLOCK);
			/*
			 * Form link from previous to new block, recording
			 * new block as first if no previous to be found.
			 * Also set the "last" field of the previous
			 * map entry to that in curLine-1 (curLine
			 * will be pointing beyond the last one, since
			 * it's the "next available record")
			 */
			if (prevLineH) {
			    oame[-1].last = curLine[-1].offset;
			    prevLineH->next = lines;
			    VMUnlock(output, prevLines);
			}
			oame->block = lines;

			VMUnlockDirty(output, lineMap);
		    
			prevLineH = (ObjLineHeader *)VMLock(output,
							    lines,
							    &lineHandle);
			prevLineH->next = (VMBlockHandle)0;
			prevLineH->num =
			    (OBJ_INIT_LINES-
			     sizeof(ObjLineHeader))/sizeof(ObjLine);

			prevLines = lines;
			curLine = (ObjLine *)(prevLineH+1);
		    
			/*
			 * Store file name of line symbol in first, so
			 * we can always find the thing without
			 * grovelling through an earlier block, which
			 * would be hard to find anyway.
			 */
			curFile = (ID *)curLine++;
			*curFile = sym->u.line.file;
			curLOff = sizeof(ObjLineHeader) + sizeof(ObjLine);
		    }
		
		    if (*curFile != sym->u.line.file) {
			/*
			 * If the block isn't big enough to hold the
			 * 2 records for the file and the record for the
			 * current line, enlarge it enough to hold those
			 * three (so we don't have to have two pieces of
			 * code to allocate a block).
			 */
			int	    sizeNeeded = curLOff + 3*sizeof(ObjLine);
		    
			if (sizeNeeded > OBJ_INIT_LINES) {
			    if (!MemReAlloc(lineHandle,
					    sizeNeeded,
					    0))
			    {
				Notify(NOTIFY_ERROR, NullID, 0,
				       "Couldn't enlarge line block for %i",
				       segSym->name);
				return(0);
			    } else {
				MemInfo(lineHandle, (genptr *)&prevLineH,
					(word *)NULL);
				/*
				 * Adjust curLine to be in the proper place
				 * as the block might have moved.
				 */
				curLine = (ObjLine *)((char *)prevLineH+
						      curLOff);
			    }
			    prevLineH->num +=
				(sizeNeeded - OBJ_INIT_LINES)/sizeof(ObjLine);
			}
			/*
			 * Create a line record with line 0 to mark the
			 * next record as containing the ID of the
			 * current file, store the file in the next record
			 * and leave curLOff and curLine pointing to the
			 * proper slot immediately after the file.
			 */
			curLine->line = 0;
			curLine++;
			curFile = (ID *)curLine++;
			*curFile = sym->u.line.file;
			curLOff += 2 * sizeof(ObjLine);
		    }
		    /*
		     * Store the current line now we know our file is
		     * correct.
		     */
		    if ((curLine == (ObjLine *)(curFile+1)) ||
			(sym->u.line.common.offset != curLine[-1].offset))
		    {
			/*
			 * Immediately after a file token, or this line
			 * record hasn't the same offset as the previous one,
			 * so we want to store a new record.
			 */
			curLine->line = sym->u.line.line;
			curLine->offset = sym->u.line.common.offset;
			curLine++;
			curLOff += sizeof(ObjLine);
		    } else if (curLine != (ObjLine *)(curFile+1)) {
			/*
			 * Previous line record was at the same address, so
			 * just overwrite its 'line' field with the current
			 * one's
			 */
			curLine[-1].line = sym->u.line.line;
		    }
		
		    /*
		     * If hit end of block, set lines to 0 so we allocate
		     * another block next time.
		     */
		    if (curLOff >= OBJ_INIT_LINES) {
			lines = 0;
		    }
		}
		sym = sym->u.addrsym.next;
		continue;
	    case SYM_VAR:
		SymConvertType(sym->u.var.type, &swd,
			       &swd.nextSym->u.variable.type);
		swd.nextSym->type = OSYM_VAR;
		break;
	    case SYM_CHUNK:
		SymConvertType(sym->u.chunk.type, &swd,
			       &swd.nextSym->u.chunk.type);
		swd.nextSym->type = OSYM_CHUNK;
		swd.nextSym->u.chunk.handle = sym->u.chunk.handle;
		break;
	    case SYM_LABEL:
		swd.nextSym->type = OSYM_LABEL;
		swd.nextSym->u.label.near = sym->u.label.near;
		break;
	    case SYM_PROFILE_MARK:
		swd.nextSym->type = OSYM_PROFILE_MARK;
		swd.nextSym->u.profMark.markType = sym->u.profMark.markType;
		break;
	    case SYM_PROTOMINOR:
		swd.nextSym->type = OSYM_PROTOMINOR;
		swd.nextSym->u.addrSym.address = 0;
		break;
	    case SYM_LOCALLABEL:
		swd.nextSym->type = OSYM_LOCLABEL;
		swd.nextSym->u.label.near = sym->u.label.near;
		swd.nextSym->u.procLocal.next = lastProc->u.proc.local;
		lastProc->u.proc.local = swd.symOff;
		break;
	    case SYM_PROC:
		swd.nextSym->type = OSYM_PROC;
		swd.nextSym->u.proc.local = swd.symOff;	/* Point back at
							 * ourselves */
		swd.nextSym->u.proc.flags = sym->u.proc.flags;
		lastProc = swd.nextSym;
		lastProcSym = sym;
		
		if (sym->u.proc.locals) {
		    SymBucketPtr	bucket;
		    SymbolPtr   	local;
		    
		    for (bucket = (SymBucketPtr)sym->u.proc.locals;
			 bucket != NULL;
			 bucket = bucket->next)
		    {
			for (local = bucket->syms;
			     local < bucket->ptr;
			     local++)
			{
			    if (local->type == SYM_LOCALLABEL) {
				/*
				 * Taken care of later
				 */
				continue;
			    }
			    if (local->flags & SYM_NOWRITE) {
				continue;
			    }
			    
			    swd.nextSym++;
			    swd.symOff += sizeof(ObjSym);
			    
			    swd.nextSym->flags = local->flags;
			    
			    switch(local->type) {
			    case SYM_LOCAL:
				(void)SymCheckUnref(local, lastProcSym,
						    file, line, &lastRefOff);
				swd.nextSym->type = OSYM_LOCVAR;
				swd.nextSym->u.localVar.offset =
				    local->u.localVar.offset;
				SymConvertType(local->u.localVar.type, &swd,
					       &swd.nextSym->u.localVar.type);
				break;
			    default:
				Notify(NOTIFY_ERROR, NullID, 0,
				       "Unhandled symbol type for %i",
				       local->name);
				abort();
			    }
			    swd.nextSym->name = SymPermanentName(local);
			    
			    /*
			     * Link the symbol into the list of loca
			     * symbols for the current procedure.
			     */
			    swd.nextSym->u.procLocal.next =
				lastProc->u.proc.local;
			    lastProc->u.proc.local = swd.symOff;
			    
			}
		    }
		}
		break;
	    case SYM_CLASS:
	    {
		int baseOff;
		
		if (sym->u.class.data->flags & SYM_CLASS_VARIANT) {
		    swd.nextSym->type = OSYM_VARIANT_CLASS;
		} else if (sym->u.class.data->flags & SYM_CLASS_MASTER) {
		    swd.nextSym->type = OSYM_MASTER_CLASS;
		} else {
		    swd.nextSym->type = OSYM_CLASS;
		}
		if (sym->u.class.super) {
		    Sym_Reference(sym->u.class.super);
		    OBJ_STORE_SID(swd.nextSym->u.class.super,
				  SymPermanentName(sym->u.class.super));
		} else {
		    OBJ_STORE_SID(swd.nextSym->u.class.super, NullID);
		}
		baseOff = swd.symOff;
		
		if (sym->u.class.data->bindings) {
		    SymBucketPtr	bucket;
		    SymbolPtr   	binding;
		    
		    for (bucket = (SymBucketPtr)sym->u.class.data->bindings;
			 bucket != NULL;
			 bucket = bucket->next)
		    {
			for (binding = bucket->syms;
			     binding < bucket->ptr;
			     binding++)
			{
			    swd.nextSym++;
			    swd.symOff += sizeof(ObjSym);
			    
			    swd.nextSym->name = SymPermanentName(binding);
			    swd.nextSym->type = OSYM_BINDING;
			    swd.nextSym->flags = 0;
			    swd.nextSym->u.binding.isLast = 0;
			    swd.nextSym->u.binding.callType =
				binding->u.binding.callType;

			    OBJ_STORE_SID(swd.nextSym->u.binding.proc,
				    SymPermanentName(binding->u.binding.proc));
			}
		    }
		    /*
		     * Set isLast flag of final binding
		     */
		    swd.nextSym->u.binding.isLast = 1;
		}
		break;
	    }
	    case SYM_ONSTACK:
		swd.nextSym->type = OSYM_ONSTACK;
		OBJ_STORE_SID(swd.nextSym->u.onStack.desc,
			      sym->u.onStack.desc);
		break;
	    default:
		Notify(NOTIFY_ERROR, NullID, 0,
		       "Unhandled symbol type for %i", sym->name);
		abort();
	    }
	    /*
	     * Preserve address of next symbol while we convert the symbol
	     * to have the standard objsym data: the block and offset
	     * at which it was written.
	     */
	    nextSym = sym->u.addrsym.next;
	    sym->u.objsym.block = swd.syms;
	    sym->u.objsym.offset = symOff;
	    
	    /*
	     * Advance to the next symbol in the list.
	     */
	    sym = nextSym;
	    swd.nextSym++;
	    swd.symOff += sizeof(ObjSym);
	}
	
	/*
	 * Allocate a new block for type descriptions if we've used up the
	 * current one...
	 */
	if ((swd.typeOff == swd.typeSize) || (swd.typeSize > OBJ_INIT_TYPES)) {
	    SymAllocTypeBlock(&swd);
	}
    }

    /*
     * Finish out the current block of line numbers. First store the address
     * of the last line stored, then shrink the block down to match the
     * current offset (if prevLineH actually points to an active block, as
     * indicated by lines being non-zero [else prevLineH points to the
     * previous block]). As for the unlock, there is always only one lines
     * block locked at a given time, and prevLines always holds its handle.
     *
     * 4/2/91: changed oame->last to be the size of the segment so any bytes
     * between the last line number and the end of the segment are covered by
     * the final line number record -- ardeb
     */
    if (prevLineH) {
	ObjAddrMapHeader    *oamh;
	ObjAddrMapEntry	    *oame;

	oamh = (ObjAddrMapHeader *)VMLock(output, lineMap, (MemHandle *)NULL);
	oame = &((ObjAddrMapEntry *)(oamh+1))[oamh->numEntries - 1];
	oame->last = seg->size;
	VMUnlockDirty(output, lineMap);

	if (lines) {
	    prevLineH->num = (curLOff - sizeof(ObjLineHeader))/sizeof(ObjLine);
	    (void)MemReAlloc(lineHandle, curLOff, 0);
	}
	VMUnlockDirty(output, prevLines);
    } else {
	Notify(NOTIFY_DEBUG, segSym->name, 0,
	       "segment contains no line numbers?!\n");
    }
    
    SymWriteNonAddress(seg, &swd, segOff, segSym);

    /*
     * Clean up after ourselves, unlocking the types and prevSyms blocks and
     * shrinking them if they've got unused space in them.
     */
    if (swd.typeOff == 0) {
	/*
	 * No type-descriptions stored -- resize the block to a single
	 * byte. It turns out to be more trouble than it's worth to be
	 * careful about not locking the type block if the type is special,
	 * so we make sure the block continues to exist, but only marginally.
	 */
	swd.typeOff = sizeof(ObjTypeHeader);
    }
    if (swd.typeOff != swd.typeSize) {
	ObjTypeHeader	*thdr;
	
	MemInfo(swd.tmem, (genptr *)&thdr, (word *)NULL);
	thdr->num = (swd.typeOff-sizeof(ObjTypeHeader))/sizeof(ObjType);
	
	(void)MemReAlloc(swd.tmem, swd.typeOff, 0);
	
    }
    VMUnlockDirty(output, swd.types);
    
    if (swd.syms) {
	/*
	 * If we were working on a block, shrink it down. Note there's no
	 * need to check curOff against size, since syms would be NULL
	 * if they were equal...
	 */
	swd.prevSymH->num = (swd.symOff-sizeof(ObjSymHeader))/sizeof(ObjSym);
	(void)MemReAlloc(swd.mem, swd.symOff, 0);
    }

    /*
     * If any symbols (there may not be...), unlock the previous symbol block.
     * This also takes care of any block we might have been working on, since
     * prevSyms will be == to syms in that case.
     */
    if (swd.prevSyms) {
	VMUnlockDirty(output, swd.prevSyms);
    }

    return(1);
}

/***********************************************************************
 *				Sym_ProcessSegments
 ***********************************************************************
 * SYNOPSIS:	    Write all the segments and header info to the file
 * CALLED BY:	    main
 * RETURN:	    0 on error
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/89		Initial Revision
 *
 ***********************************************************************/
int
Sym_ProcessSegments(void)
{
    VMBlockHandle   map;    	/* Handle for map block */
    ObjHeader	    *hdr;   	/* Header of map block */
    ObjSegment 	    *nextSeg;	/* Segment descriptor */
    ObjGroup   	    *nextGrp;	/* Group descriptor */
    int	    	    mapSize;	/* Current size of map block */
    int	    	    i;	    	/* Index into segments array */
    ExprResult      entryRes;	/* Result of evaluating entry-point expr */

    writing = TRUE;

    /*
     * Evaluate entry-point expression now while symbols are unmolested.
     */
    if (entryPoint) {
	byte	    status;

	if (!Expr_Eval(entryPoint, &entryRes,
		       (EXPR_NOUNDEF|EXPR_FINALIZE|EXPR_NOT_OPERAND),
		       &status))
	{
	    Notify(NOTIFY_ERROR, entryPoint->file, entryPoint->line,
		   "evaluating entry-point expression: %s",
		   (char *)entryRes.type);
	    return(0);
	} else if (entryRes.type == EXPR_TYPE_CONST ||
		   entryRes.type == EXPR_TYPE_STRING)
	{
	    Notify(NOTIFY_ERROR, entryPoint->file, entryPoint->line,
		   "entry-point can't be a constant!");
	    return(0);
	} else if (entryRes.data.ea.modrm != MR_DIRECT) {
	    Notify(NOTIFY_ERROR, entryPoint->file, entryPoint->line,
		   "entry-point must be directly addressable");
	    return(0);
	} else if (!entryRes.rel.sym) {
	    Notify(NOTIFY_ERROR, entryPoint->file, entryPoint->line,
		   "entry-point may not be absolute");
	    return(0);
	}
    }
    
    /*
     * Figure map block size based on number of segments.
     */
    mapSize = sizeof(ObjHeader) + numSegments * sizeof(ObjSegment);

    /*
     * Add in the sizes for the groups, making sure they stay longword-aligned
     */
    for (i = 0; i < numGroups; i++) {
	mapSize += OBJ_GROUP_SIZE(groups[i]->u.group.nSegs);
    }
    
    map = VMAlloc(output, mapSize, OID_MAP_BLOCK);
    if (map == 0) {
	Notify(NOTIFY_ERROR, NullID, 0,
	       "Couldn't allocate map block in output file");
	return(0);
    }
    /*
     * Record that block as the map block for Glue's sake
     */
    VMSetMapBlock(output, map);

    /*
     * Initialize the header fields
     */
    hdr = (ObjHeader *)VMLock(output, map, (MemHandle *)NULL);

    hdr->magic =    OBJMAGIC;
    hdr->numSeg =   numSegments;
    hdr->numGrp =   numGroups;
    hdr->strings =  permStrings;
    hdr->srcMap =   0;		/* Done in Glue, only */
    
    /*
     * Initialize the segment descriptors for all the segments to the file.
     */
    nextSeg = (ObjSegment *)(hdr+1);

    for (i = 0; i < numSegments; i++) {
	SymbolPtr   seg;

	seg = segments[i];
	seg->u.segment.data->offset = (char *)nextSeg - (char *)hdr;
	nextSeg->name = SymPermanentName(seg);
	nextSeg->class = seg->u.segment.data->class;
	nextSeg->align = seg->u.segment.data->align;
	nextSeg->type = seg->u.segment.data->comb;
	nextSeg->data = nextSeg->relHead = nextSeg->syms = nextSeg->lines = 0;
	if (seg->segment && seg->segment->type == SYM_GROUP) {
	    nextSeg->flags = SEG_IN_GROUP;
	} else {
	    nextSeg->flags = 0;
	}
	if ((nextSeg->type != SEG_ABSOLUTE) &&
	    (nextSeg->type != SEG_GLOBAL) &&
	    (nextSeg->type != SEG_LIBRARY))
	{
	    long	    size = Table_Size(seg->u.segment.code);

	    nextSeg->size = size;
	    /*
	     * Check for block > 64K to avoid failed assertions in VMAlloc
	     */
	    if (size > 65536) {
		Notify(NOTIFY_ERROR, NullID, 0,
		       "%i is greater than 64K (%d bytes total)",
		       nextSeg->name, size);
		return(0);
	    }
	} else {
	    nextSeg->size = 0;
	}
	nextSeg++;
    }

    /*
     * Set up the descriptors for the groups.
     */
    nextGrp = (ObjGroup *)nextSeg;
    for (i = 0; i < numGroups; i++) {
	SymbolPtr   grp = groups[i];
	int 	    j;

	nextGrp->name = SymPermanentName(grp);
	nextGrp->numSegs = grp->u.group.nSegs;
	grp->u.group.offset = (char *)nextGrp-(char *)hdr;

	for (j = 0; j < grp->u.group.nSegs; j++) {
	    nextGrp->segs[j] = grp->u.group.segs[j]->u.segment.data->offset;
	}
	/*
	 * Point nextGrp at the next group record, accounting for required
	 * longword-alignment.
	 */
	nextGrp = OBJ_NEXT_GROUP(nextGrp);
    }

    /*
     * Write out all the symbols for the segments. This causes numSegments
     * traversals over the symbol table, but it makes the algorithm easier
     * to write and reduces headaches as far as type description blocks go.
     */
    for (i = 0; i < numSegments; i++) {
	SymbolPtr   segSym;
	ObjSegment	    *seg;
	
	segSym = segments[i];
	seg = (ObjSegment *)((char *)hdr + segSym->u.segment.data->offset);
	if (!SymWriteSegment(segSym, seg)) {
	    return(0);
	}
    }
    
	
    /*
     * Now all the symbols have been written and their places recorded,
     * let the fixup module write out its stuff while we save the head
     * of the block chain it returns for each segment.
     */
    for (i = 0; i < numSegments; i++) {
	SymbolPtr   segSym;
	ObjSegment  *seg;
	
	segSym = segments[i];
	seg = (ObjSegment *)((char *)hdr + segSym->u.segment.data->offset);
	seg->relHead = Fix_Write(segSym);

	/*
	 * Once the fixup module is complete, we know the segments' data aren't
	 * going to be modified any more, so we can write them to the file.
	 */
	if (seg->size != 0) {
	    seg->data = VMAlloc(output, seg->size, OID_CODE_BLOCK);
	    if (seg->data == 0) {
		Notify(NOTIFY_ERROR, NullID, 0,
		       "Couldn't allocate block for %i's data",
		       segSym->name);
		return(0);
	    }
	    if (!Table_Write(segSym->u.segment.code, seg->data)) {
		Notify(NOTIFY_ERROR, NullID, 0,
		       "Couldn't write data for %i", segSym->name);
		return(0);
	    }
	} else if (seg->type == SEG_ABSOLUTE) {
	    seg->data = segSym->u.segment.data->segment;
	} else {
	    seg->data = 0;
	}
    }
    
    /*
     * If entry point in this file, store the segment offset.
     */
    if (entryPoint) {
	/*
	 * Transform the relocation to be a dword-sized call relocation
	 */
	entryRes.rel.type = FIX_CALL;
	entryRes.rel.size = FIX_SIZE_DWORD;
	if (!Fix_OutputRel((SymbolPtr)NULL, 0, &entryRes.rel,
			   (Opaque)&hdr->entry))
	{
	    Notify(NOTIFY_ERROR, entryPoint->file, entryPoint->line,
		   "not supposed to write out entry-point?!");
	    return(0);
	}
    } else {
	/*
	 * Signal entry point not here.
	 */
	hdr->entry.frame = 0;
    }
	
/* XXX
    fprintf(stderr, "%d string equates using %d dynamic string blocks\n",
	    stringEquates, stringBlocks);
*/
    VMUnlockDirty(output, map);
    return(1);
}
	

/***********************************************************************
 *				Sym_Adjust
 ***********************************************************************
 * SYNOPSIS:	    Adjust the addresses of symbols in a segment after
 *	    	    a certain point to accomodate a size change before them.
 * CALLED BY:	    LMem_DefineChunk, among others
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The u.addrsym.offset fields of the symbols in the
 *	    	    by-address list for the current segment are adjusted
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/89		Initial Revision
 *
 ***********************************************************************/
void
Sym_Adjust(SymbolPtr	seg,
	   int	    	start,
	   int	    	diff)
{
    SymbolPtr	sym;

    /*
     * Locate the first affected symbol (one whose address is >= start)
     */
    for (sym = seg->u.segment.data->first;
	 sym != NULL && sym->u.addrsym.offset < start;
	 sym = sym->u.addrsym.next)
    {
	;
    }

    /*
     * Adjust that and all succeeding symbols.
     */
    while (sym != NULL) {
	sym->u.addrsym.offset += diff;
	sym = sym->u.addrsym.next;
    }
}


/***********************************************************************
 *				Sym_AddToGroup
 ***********************************************************************
 * SYNOPSIS:	    Add another segment to a group symbol
 * CALLED BY:	    yyparse when a GROUP directive is seen
 * RETURN:	
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/89		Initial Revision
 *
 ***********************************************************************/
void
Sym_AddToGroup(SymbolPtr    grp,
	       SymbolPtr    seg)
{
    grp->u.group.nSegs += 1;
    grp->u.group.segs =
	(SymbolPtr *)realloc((void *)grp->u.group.segs,
			     grp->u.group.nSegs * sizeof(SymbolPtr));
    grp->u.group.segs[grp->u.group.nSegs-1] = seg;
    seg->segment = grp;
}
