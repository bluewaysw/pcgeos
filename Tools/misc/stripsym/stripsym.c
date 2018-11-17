/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  stripsym.c
 * FILE:	  stripsym.c
 *
 * AUTHOR:  	  Adam de Boor: Jul 21, 1992
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/21/92	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Program to strip .sym files to their distributable form.
 *
 *	This involves:
 *	    - removing all line number information
 *	    - removing all local variables, but not parameters
 *	    - removing all local labels
 *	    - having only those strings in the table that apply to the
 *	      symbols that are kept.
 *
 ***********************************************************************/

#ifndef lint
static char *rcsid =
"$Id: stripsym.c,v 1.12 97/04/01 13:59:31 jacob Exp $";
#endif lint

#include    <st.h>
#include    <objformat.h>
#include    <objSwap.h>
#include    <stdio.h>
#include    <ctype.h>
#include    <assert.h>

int debug = 0;
int genericSyms = 0;
int dbcsRelease = 0;    /* needed for utils library */
int symfileFormat = 0;

VMHandle	    input;  	/* File being stripped */
VMHandle    	    output; 	/* Result */
VMBlockHandle	    outstr; 	/* String table in output file */
VMHandle    	    idfile; 	/* For printf */
int	    	    geosRelease;    /* For VM functions */

/******************************************************************************
 *
 *		       SYMBOL HASH TABLE STUFF
 *
 ******************************************************************************/

/***********************************************************************
 *				Sym_Create
 ***********************************************************************
 * SYNOPSIS:	    Create a new symbol table.
 * CALLED BY:	    EXTERNAL (Seg_AddSegment)
 * RETURN:	    Block handle for new table
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
VMBlockHandle
Sym_Create(VMHandle 	file)
{
    /*
     * VM code will zero the block the first time it's locked down.
     */
    if (symfileFormat) {
	return(VMAlloc(file, sizeof(ObjHashHeaderNewFormat), 
		       OID_HASH_HEAD_BLOCK));
    } else {
	return(VMAlloc(file, sizeof(ObjHashHeader), OID_HASH_HEAD_BLOCK));
    }
}


/***********************************************************************
 *				Sym_Close
 ***********************************************************************
 * SYNOPSIS:	    Close down a symbol table, freeing any extra
 *	    	    space allocated for it in any of its chains.
 * CALLED BY:	    Final.
 * RETURN:	    Nothing
 * SIDE EFFECTS:    All chains have their head block shrunk to match
 *	    	    its nextEnt field.
 *
 * STRATEGY:
 *	Ideally, if a symbol table is completely empty, we'd nuke it...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
void
Sym_Close(VMHandle  	file,
	  VMBlockHandle	table)
{
    ObjHashHeader   	*hdr;
    int	    	    	i;
    word    	    	obj_hash_chains;

    if (symfileFormat) {
	obj_hash_chains = OBJ_HASH_CHAINS_NEW_FORMAT;
    } else {
	obj_hash_chains = OBJ_HASH_CHAINS;
    }
    hdr = (ObjHashHeader *)VMLock(file, table, (MemHandle *)NULL);

    for (i = 0; i < obj_hash_chains; i++) {
	if (hdr->chains[i] != 0) {
	    ObjHashBlock    *hb;
	    MemHandle	    mem;

	    hb = (ObjHashBlock *)VMLock(file, hdr->chains[i], &mem);

	    (void)MemReAlloc(mem,
			     (genptr)&hb->entries[hb->nextEnt]-(genptr)hb,
			     0);
	    
	    VMUnlockDirty(file, hdr->chains[i]);
	}
    }

    VMUnlock(file, table);
}

/***********************************************************************
 *				SymLookup
 ***********************************************************************
 * SYNOPSIS:	    Find a symbol in the table, or at least where the
 *	    	    thing would go, if not already there.
 * CALLED BY:	    Sym_Enter, Sym_Find.
 * RETURN:	    If present:
 *	    	    	returns non-zero
 *	    	    	*blockPtr holds VMBlock containing the hash entry
 *	    	    	*hdrPtr points to the locked memory for it
 *	    	    	*hePtr points to the entry itself.
 *	    	    	*bucketPtr points to the chain pointer for
 *	    	    	    the chain in which the entry resides.
 *	    	    If absent:
 *	    	    	returns zero
 *	    	    	*bucketPtr points to chain pointer for the chain.
 *
 *	    	    In either case, table and *blockPtr (if non-zero)
 *	    	    	remain LOCKED.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
static int
SymLookup(VMHandle  	file,
	  VMBlockHandle	table,
	  ID	    	id,
	  VMBlockHandle	**bucketPtr,
	  VMBlockHandle	*blockPtr,
	  ObjHashBlock	**hdrPtr,
	  ObjHashEntry	**hePtr)
{
    int	    	    index;
    VMBlockHandle   cur;
    VMBlockHandle   next;
    ObjHashHeader   *hdr;

    if (symfileFormat) {
	index = ST_Index(file, id) % OBJ_HASH_CHAINS_NEW_FORMAT;
    } else {
	index = ST_Index(file, id) % OBJ_HASH_CHAINS;
    }
    hdr = (ObjHashHeader *)VMLock(file, table, (MemHandle *)NULL);

    *bucketPtr = &hdr->chains[index];

    for (cur = hdr->chains[index]; cur != 0; cur = next) {
	ObjHashBlock	*hb;
	ObjHashEntry	*he;

	hb = (ObjHashBlock *)VMLock(file, cur, (MemHandle *)NULL);
	next = hb->next;

	for (he = hb->entries; he < &hb->entries[hb->nextEnt]; he++) {
	    if (he->name == id) {
		/*
		 * Set return variables, leaving both blocks locked.
		 */
		*blockPtr = cur;
		*hdrPtr = hb;
		*hePtr = he;
		return(1);
	    }
	}
	VMUnlock(file, cur);
    }

    /*
     * Be nice and return the head block already locked, if it exists, with
     * he pointing at the next entry to be allocated.
     */
    cur = *blockPtr = **bucketPtr;

    if (cur != 0) {
	ObjHashBlock *hb=(ObjHashBlock *)VMLock(file, cur, (MemHandle *)NULL);

	*hdrPtr = hb;
	*hePtr = &hb->entries[hb->nextEnt];
    } else {
	*hdrPtr = NULL;
	*hePtr = NULL;
    }
    
    return(0);
}
    

/***********************************************************************
 *				Sym_Enter
 ***********************************************************************
 * SYNOPSIS:	    Enter another symbol into the table.
 * CALLED BY:	    Pass1 functions, InterPass for creating modules
 * RETURN:	    Nothing
 * SIDE EFFECTS:    If a symbol of the name is already defined,
 *	    	    an error is posted. If symbol was undefined before,
 *	    	    it is removed from the list of undefined symbols.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
void
Sym_Enter(VMHandle  	file,    	/* Output file */
	  VMBlockHandle	table,	    	/* Chain-root block */
	  ID	    	id, 	    	/* Name of symbol being entered */
	  VMBlockHandle	symBlock,   	/* Block at which symbol is located */
	  word	    	symOff)	    	/* Offset in same */
{
    VMBlockHandle   *bucket;	    /* Bucket in which symbol is to sit */
    VMBlockHandle   block;  	    /* Block in which symbol is to sit */
    ObjHashBlock    *hb;    	    /* Locked version of same */
    ObjHashEntry    *he;    	    /* Entry at which duplicate was found */
    word    	    obj_syms_per;

    if (symfileFormat) {
	obj_syms_per = OBJ_SYMS_PER_NEW_FORMAT;
    } else {
	obj_syms_per = OBJ_SYMS_PER;
    }
    
    if (!SymLookup(file, table, id, &bucket, &block, &hb, &he)) {
	if (!hb || (hb->nextEnt == obj_syms_per)) {
	    /*
	     * Out of room in this block -- allocate another one.
	     */
	    VMBlockHandle   new;

	    if (symfileFormat) {
		new = VMAlloc(file, sizeof(ObjHashBlockNewFormat), 
			      OID_HASH_BLOCK);
	    } else {
		new = VMAlloc(file, sizeof(ObjHashBlock), OID_HASH_BLOCK);
	    }

	    /*
	     * Lock the new block down and link it into the chain.
	     * VMAlloc zero-inits the thing, so...
	     */
	    hb = (ObjHashBlock *)VMLock(file, new, (MemHandle *)NULL);
	    hb->next = *bucket;
	    *bucket = new;
	    he = hb->entries;
	    /*
	     * If not first in the chain, unlock the block that SymLookup
	     * locked for us.
	     */
	    if (block != 0) {
		VMUnlock(file, block);
	    }
	    block = new;
	    /*
	     * Header is now dirty...
	     */
	    VMDirty(file, table);
	}
	/*
	 * Install the entry in the block and advance the index to the
	 * next one.
	 */
	he->name =  	id;
	he->offset = 	symOff;
	he->block = 	symBlock;
	
	hb->nextEnt += 1;

	/*
	 * Release the block now the data are in.
	 */
	VMDirty(file, block);
    } else {
	/*
	 * Multiple definitions of local symbols in different segments
	 * are iffy, but we allow them. When they start congregating
	 * in the same segment, though, we get upset.
	 */
	assert(0);
    }
    /*
     * table and block were left locked by SymLookup
     */
    VMUnlock(file, block);
    VMUnlock(file, table);
}

/***********************************************************************
 *				Sym_Find
 ***********************************************************************
 * SYNOPSIS:	    Find a symbol in a table, if it's there
 * CALLED BY:	    EXTERNAL
 * RETURN:	    non-zero and block/offset if defined. 0 if not.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
int
Sym_Find(VMHandle   	file,	    	/* File in which to search */
	 VMBlockHandle	table,	    	/* Table in which to look. If NULL,
					 * searches through the tables of all
					 * known segments */
	 ID 	    	id, 	    	/* Name of symbol to find */
	 VMBlockHandle	*symBlockPtr,	/* Place to store handle of block
					 * holding the symbol */
	 word	    	*symOffPtr) 	/* Place to store the offset into the
					 * block at which the symbol lies */
{
    VMBlockHandle   *bucket;	    /* Bucket in which symbol sits */
    VMBlockHandle   block;  	    /* Block in which symbol sits */
    ObjHashBlock    *hb;    	    /* Locked version of same */
    ObjHashEntry    *he;    	    /* Entry at which symbol was found */
    int	    	    retval;

    retval = SymLookup(file, table, id, &bucket, &block, &hb, &he);
    VMUnlock(file, table);
    
    if (retval) {
	*symBlockPtr = he->block;
	*symOffPtr = he->offset;
    }
    if (block != 0) {
	VMUnlock(file, block);
    }

    return(retval);
}

/******************************************************************************
 *
 *			     OTHER STUFF
 *
 ******************************************************************************/
/*
 * Data passed among the various routines. This saves having to pass
 * the address of heaps of local variables all the time...
 */
typedef struct {
    void    	    *tbase; 	/* Base of type description block for current
				 * symbol in input file */
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
    /*
     * Address mapping.
     */
    VMBlockHandle   map;
    ObjAddrMapEntry *nextMap;
    int	    	    mapOff;
    int	    	    mapSize;
    MemHandle	    mmem;
} SymWriteData;


/***********************************************************************
 *				DupType
 ***********************************************************************
 * SYNOPSIS:	    Duplicate a type description
 * CALLED BY:	    Obj_EnterTypeSyms
 * RETURN:	    The "current type" variables of the caller will be
 *	    	    altered if some ObjType records were added to the
 *	    	    type block.
 * SIDE EFFECTS:    The type block may be expanded.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 6/89	Initial Revision
 *
 ***********************************************************************/
static void
DupType(word   	    	type,       /* Type to copy */
	SymWriteData 	*swd, 	    /* State of the copy */
	VMHandle	fh,	    /* Handle to obj file */
	void   	    	*tbase,     /* Base of type block in object
				     * file */
	word   	    	*typeDest)  /* Place to store duplicate */
{
    if (type & OTYPE_SPECIAL) {
	/*
	 * If special, there's nothing else to copy.
	 */
	*typeDest = type;
    } else {
	ObjType	src;

	src = *(ObjType *)((genptr)tbase + type);
	
	/*
	 * Copy any nested type first.
	 */
	if (!OTYPE_IS_STRUCT(src.words[0])) {
	    DupType(src.words[1], swd, fh, tbase, &src.words[1]);
	}

	/*
	 * Make sure there's room for the descriptor in the block.
	 */
	if (swd->typeOff == swd->typeSize) {
	    /*
	     * Add another record to the block. This could be considered
	     * inefficient, but the blocks are allocated large enough and 
	     * symbol blocks proportionately small enough (and the descriptions
	     * themselves are compact enough), that I don't anticipate this
	     * being executed very often. It might be the better part of wisdom
	     * to allocate several extra chunks at a time, however.
	     */
	    void	*base;
	    
	    swd->typeSize += sizeof(ObjType);
	    (void)MemReAlloc(swd->tmem, swd->typeSize, 0);
	    MemInfo(swd->tmem, (genptr *)&base, (word *)NULL);
	    swd->nextType = (ObjType *)((genptr)base + swd->typeOff);
	}
	    
	if (OTYPE_IS_STRUCT(src.words[0])) {
	    /*
	     * A structure needs to have the structure name duplicated
	     */
	    ID	    id = ST_Dup(fh, OTYPE_STRUCT_ID(&src),
				output, outstr);
	    
	    OTYPE_ID_TO_STRUCT(id,swd->nextType);
	} else {
	    /*
	     * Anything else can be copied in directly, since the
	     * nested type has already been copied.
	     */
	    *swd->nextType = src;
	}
	/*
	 * Adjust caller's variables.
	 */
	*typeDest = swd->typeOff;
	swd->nextType += 1;
	swd->typeOff += sizeof(ObjType);
    }
}


/***********************************************************************
 *				Obj_IsAddrSym
 ***********************************************************************
 * SYNOPSIS:	    See if the passed ObjSym contains an address.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    TRUE if it does, FALSE if it don't :)
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/20/91	Initial Revision
 *
 ***********************************************************************/
int
Obj_IsAddrSym(ObjSym *os)
{
    switch(os->type) {
        case OSYM_PROFILE_MARK:
	case OSYM_ONSTACK:
	    return(1);
    	case OSYM_NEWMINOR:
    	case OSYM_PROTOMINOR:
	case OSYM_LOCLABEL:
	case OSYM_BLOCKSTART:
	case OSYM_BLOCKEND:
	case OSYM_VAR:
	case OSYM_CHUNK:
	case OSYM_PROC:
	case OSYM_LABEL:
	case OSYM_CLASS:
	case OSYM_MASTER_CLASS:
	case OSYM_VARIANT_CLASS:
	    if (!(os->flags & OSYM_UNDEF)) {
		return(1);
	    }
	    /*FALLTHRU*/
	default:
	    /*
	     * Not one of the address-bearing types, or is one but it's
	     * undefined, so doesn't hold an address.
	     */
	    return(0);
    }
}

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
	ObjAddrMapHeader *mapBase;
	
	swd->prevSymH->next = syms;
	VMUnlockDirty(output, swd->prevSyms);

	/*
	 * Make room for another block in the address map.
	 */
	swd->mapSize += sizeof(ObjAddrMapEntry);
	MemReAlloc(swd->mmem, swd->mapSize, 0);
	MemInfo(swd->mmem, (genptr *)&mapBase, (word *)NULL);
	swd->mapOff += sizeof(ObjAddrMapEntry);
	swd->nextMap = (ObjAddrMapEntry *)((genptr)mapBase + swd->mapOff);
	mapBase->numEntries += 1;
    } else {
	/*
	 * No previous => is first, so store the handle in the syms field
	 * of the segment descriptor.
	 */
	ObjAddrMapHeader    *mapHdr;
	seg->syms = syms;

	/*
	 * Allocate address map for the segment as well.
	 */
	swd->mapSize = sizeof(ObjAddrMapHeader) + sizeof(ObjAddrMapEntry);

	seg->addrMap = swd->map = VMAlloc(output, swd->mapSize, OID_ADDR_MAP);
	mapHdr = (ObjAddrMapHeader *)VMLock(output, swd->map, &swd->mmem);
	mapHdr->numEntries = 1;
	swd->mapOff = sizeof(ObjAddrMapHeader);
	swd->nextMap = ObjFirstEntry(mapHdr, ObjAddrMapEntry);
    }

    swd->nextMap->block = syms;

    swd->prevSymH = (ObjSymHeader *)VMLock(output, syms, &swd->mem);
    swd->prevSymH->next = (VMBlockHandle)NULL;
    swd->prevSymH->types = swd->types;
    swd->prevSymH->seg = segOff;
    swd->prevSymH->num = (swd->symSize - sizeof(ObjSymHeader))/sizeof(ObjSym);
    swd->prevSyms = swd->syms = syms;
    swd->symOff = sizeof(ObjSymHeader);
}
    

/***********************************************************************
 *				DupTypeBlock
 ***********************************************************************
 * SYNOPSIS:	    Duplicate a type block to the output file.
 * CALLED BY:	    Pass1VMRelAddrSyms
 * RETURN:	    The handle in the output file.
 * SIDE EFFECTS:    Any ID's in the type descriptions are copied to the
 *	    	    output file.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 3/89	Initial Revision
 *
 ***********************************************************************/
static VMBlockHandle
DupTypeBlock(VMHandle  	    fh,     /* Object file */
	     VMBlockHandle   block)  /* Block to duplicate */
{
    ObjType 	    *ot;    	/* Current type description to copy */
    MemHandle	    mem;    	/* Handle of block in which descriptions
				 * reside */
    word    	    n;	    	/* Number of descriptions left to copy */
    VMBlockHandle   dup;    	/* VM Block handle of duplicate in output
				 * file */
    ObjTypeHeader   *oth;

    /*
     * Allocate a duplicate block in the symbols file. It will
     * take its size from the memory handle we'll attach to it.
     */
    dup = VMAlloc(output, 0, OID_TYPE_BLOCK);
    
    /*
     * Copy the descriptions to the output file.
     */
    mem = VMDetach(fh, block);
    VMAttach(output, dup, mem);
    
    /*
     * Point to the first description. Note that the block could be flushed
     * between the attach and the lock (unlikely, but possible) so we
     * ask for the mem handle as well.
     */
    oth = (ObjTypeHeader *)VMLock(output, dup, &mem);
    n = oth->num;
    ot = (ObjType *)(oth+1);

    /*
     * The only thing we need to do here is copy the ID's of any
     * structure descriptions into the output file. Note that even if
     * the ID is trimmed out, because it pertains to a description
     * for a type that's already in the symbol table, the ID won't just
     * be hanging out unreferenced, as the duplicate type will have entered
     * it before us and still be using it.
     */
    while (n > 0) {
	if (OTYPE_IS_STRUCT(ot->words[0])) {
	    ID	    id = ST_Dup(fh, OTYPE_STRUCT_ID(ot), output, outstr);

	    OTYPE_ID_TO_STRUCT(id,ot);
	}
	ot++, n--;
    }

    /*
     * Unlock the block and make sure the system knows it's dirty.
     */
    VMUnlockDirty(output, dup);

    /*
     * Return the handle of the duplicate block.
     */
    return(dup);
}

/***********************************************************************
 *				CopySym
 ***********************************************************************
 * SYNOPSIS:	    Make room for and copy a symbol from the input file
 *	    	    to the current symbol block.
 * CALLED BY:	    StripSegment
 * RETURN:	    ObjSym * for the new symbol, with name duplicated into
 *	    	    the output file's string table.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/22/92		Initial Revision
 *
 ***********************************************************************/
ObjSym *
CopySym(SymWriteData *swd, ObjSym *inos)
{
    ObjSym  *outos;

    if (swd->symOff + sizeof(ObjSym) > swd->symSize) {
	/*
	 * Set new size
	 */
	swd->symSize = swd->symOff + sizeof(ObjSym);
	/*
	 * Enlarge block and get the new address.
	 * XXX: Have a MemReAllocLocked?
	 */
	(void)MemReAlloc(swd->mem, swd->symSize, 0);
	MemInfo(swd->mem, (genptr *)&swd->prevSymH, (word *)NULL);
	/*
	 * Adjust curSym for caller.
	 */
	swd->prevSymH->num =
	    (swd->symSize - sizeof(ObjSymHeader))/sizeof(ObjSym);
    }
    outos = (ObjSym *)((genptr)swd->prevSymH + swd->symOff);
    *outos = *inos;
    outos->name = ST_Dup(input, inos->name, output, outstr);

    return(outos);
}

/***********************************************************************
 *				StripSegment
 ***********************************************************************
 * SYNOPSIS:	Strip out all unnecessary stuff for a segment.
 * CALLED BY:	StripHeader
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/22/92		Initial Revision
 *
 ***********************************************************************/
void
StripSegment(VMHandle	output,
	     ObjSegment	*outs,
	     VMHandle	input,
	     ObjSegment	*s,
	     word   	segOff,
	     FILE   	*gpfile)
{
    VMBlockHandle   cur, next, head, prev;
    SymWriteData    swd;
    
    outs->type = s->type;
    outs->name = ST_Dup(input, s->name, output, outstr);
    outs->class = ST_Dup(input, s->class, output, outstr);
    outs->align = s->align;
    outs->type = s->type;
    outs->size = s->size;

    /*
     * If the segment has data, copy it over (allows us to strip an object file
     * of non-essential information).
     */
    if (s->data != 0 && s->type != SEG_ABSOLUTE) {
	MemHandle   mem = VMDetach(input, s->data);

	outs->data = VMAlloc(output, 0, OID_CODE_BLOCK);
	VMAttach(output, outs->data, mem);
    }

    /*
     * Duplicate the relocation chain, too.
     */
    head = 0;
    for (cur = s->relHead; cur != 0; cur = next) {
	MemHandle   	mem = VMDetach(input, cur);
	ObjRelHeader	*orh;

	if (head == 0) {
	    head = prev = outs->relHead = VMAlloc(output, 0, OID_REL_BLOCK);
	    VMAttach(output, prev, mem);
	} else {
	    VMBlockHandle   new;

	    orh = VMLock(output, prev, (MemHandle *)NULL);
	    new = orh->next = VMAlloc(output, 0, OID_REL_BLOCK);
	    VMAttach(output, new, mem);
	    VMUnlockDirty(output, prev);
	    prev = new;
	}
	orh = MemLock(mem);
	next = orh->next;
	MemUnlock(mem);
    }
    outs->relHead = head;
	    

    outs->toc = Sym_Create(output);

    /*
     * Set up initial type description block.
     */
    swd.tmem = NULL;		/* So don't try to close non-existent block */
    SymAllocTypeBlock(&swd);

    swd.prevSymH = (ObjSymHeader *)NULL;
    swd.prevSyms = (VMBlockHandle)NULL;
    swd.symOff = 0;
    
    swd.syms = (VMBlockHandle)NULL;

    for (cur = s->syms; cur != 0; cur = next) {
	ObjSymHeader	*osh;
	ObjSym	    	*os;
	int 	    	n;
	unsigned    	prevLocal;
	ObjSym	    	*outos;

	osh = (ObjSymHeader *)VMLock(input, cur, (MemHandle *)NULL);
	os = ObjFirstEntry(osh, ObjSym);
	
	if (!Obj_IsAddrSym(os)) {
	    VMUnlock(input, cur);
	    break;
	}
	swd.tbase = VMLock(input, osh->types, (MemHandle *)NULL);
	/*
	 * If the current block is full, allocate a new one.
	 */
	if ((swd.symOff >= OBJ_MAX_SYMS) || (swd.prevSymH == NULL)) {
	    SymAllocSymBlock(&swd, outs, segOff);
	}

	for (n = osh->num; n > 0; n--, os++) {
	    switch(os->type) 
	    {
		case OSYM_PROC:
		{
		    char	*nameString;
		    int 	index;

		    outos = CopySym(&swd, os);
		    index = 0;
		    if ((os->flags & OSYM_GLOBAL) &&
			 !(os->u.proc.flags & OSYM_NEAR) &&
			genericSyms)
		    {

			/* ok we have a global far routine, so lets see if
			 * it's exported in the gp file...
			 */
			nameString = ST_Lock(input, os->name);
			index = FindStringInGPFile(nameString, gpfile);
			ST_Unlock(input, os->name);
		    }

		    if (index)
		    {
			index--;    /* start from zero, not 1 */
			outos->flags |= OSYM_ENTRY; /* mark it as an entry */
			outos->u.proc.address = index;
		    }
		    else if (genericSyms)
		    {
			break;
		    }
		    /*
		     * Point back to self for local scope.
		     */
		    prevLocal = outos->u.proc.local = swd.symOff;

		    /*
		     * Set offset of nextMap
		     */
		    swd.nextMap->last = os->u.proc.address;

		    Sym_Enter(output, outs->toc, outos->name,
			      swd.syms, swd.symOff);
		    
		    swd.symOff += sizeof(ObjSym);
		    break;
		}
		case OSYM_LOCVAR:
		    if (os->u.localVar.offset <= 0) {
			break;
		    }
		    /*
		     * It's a parameter, so keep it.
		     */
		    /*FALLTHRU*/
		case OSYM_RETURN_TYPE:
		{
		    ObjSym	*pl;
		    
		    outos = CopySym(&swd, os);
		    /*
		     * Link the beast into the current local-variable
		     * chain at the very end. Must deal with procedure
		     * symbol having its pointer in the wrong place,
		     * however...
		     */
		    pl = (ObjSym *)((genptr)swd.prevSymH + prevLocal);
		    if (pl->type == OSYM_PROC) {
			outos->u.procLocal.next = pl->u.proc.local;
			pl->u.proc.local = swd.symOff;
		    } else {
			outos->u.procLocal.next = pl->u.procLocal.next;
			pl->u.procLocal.next = swd.symOff;
		    }
		    prevLocal = swd.symOff;
		    DupType(os->u.localVar.type,
			       &swd,
			       input,
			       swd.tbase,
			       &outos->u.localVar.type);

		    swd.symOff += sizeof(ObjSym);
		    break;
		}
		case OSYM_ONSTACK:
		    outos = CopySym(&swd, os);
		    OBJ_STORE_SID(outos->u.onStack.desc,
				  ST_Dup(input,
					 OBJ_FETCH_SID(os->u.onStack.desc),
					 output,
					 outstr));
		    swd.symOff += sizeof(ObjSym);
		    break;
		case OSYM_CLASS:
		case OSYM_MASTER_CLASS:
		case OSYM_VARIANT_CLASS:
	    	{
		    char	*nameString;
		    int 	index;

		    index = 0;
		    outos = CopySym(&swd, os);
		    if ((os->flags & OSYM_GLOBAL) && genericSyms)
		    {

			/* ok we have a global class, so lets see if
			 * it's exported in the gp file...
			 */
			nameString = ST_Lock(input, os->name);
			index = FindStringInGPFile(nameString, gpfile);
			ST_Unlock(input, os->name);
		    }
		    if (index)
		    {
			index--;    	    /* start from zero, not 1 */
			outos->flags |= OSYM_ENTRY; /* mark it as an entry */
			outos->u.proc.address = index;
		    }
		    else if (genericSyms)
		    {
			break;
		    }
		
		    OBJ_STORE_SID(outos->u.class.super,
				  ST_Dup(input,
					 OBJ_FETCH_SID(os->u.class.super),
					 output,
					 outstr));
		    swd.nextMap->last = outos->u.class.address;
		    Sym_Enter(output, outs->toc, outos->name,
			      swd.syms, swd.symOff);
		    swd.symOff += sizeof(ObjSym);
		    break;
		}
		case OSYM_MODULE:
		    outos = CopySym(&swd, os);
		    if (outos->name != NullID) {
			Sym_Enter(output, outs->toc, outos->name,
				  swd.syms, swd.symOff);
		    }
		    swd.symOff += sizeof(ObjSym);
		    break;
		case OSYM_VAR:
		    if (genericSyms)
	    	    {
			break;
		    }
		    /* FALLTHRU */
		case OSYM_CHUNK:
		{
		    int	enter;

		    if (os->name != NullID) {
			VMBlockHandle	junkBlock;
			word	    	junkOffset;
			
			enter = (Sym_Find(input, s->toc, os->name,
					  &junkBlock, &junkOffset) &&
				 (junkBlock == cur) &&
				 (junkOffset == ObjEntryOffset(os,osh)));
		    } else {
			enter = 0;
		    }

		    /*
		     * Only put the thing in the output file if it should be
		     * entered or has a null name. If it's got a name but
		     * shouldn't be entered, it means it's a local static
		     * variable, which should be stripped out.
		     */
		    if (enter || os->name == NullID) {
			outos = CopySym(&swd, os);
			DupType(os->u.variable.type,
				&swd,
				input,
				swd.tbase,
				&outos->u.variable.type);
			if (enter) {
			    Sym_Enter(output, outs->toc, outos->name,
				      swd.syms, swd.symOff);
			}
			swd.nextMap->last = outos->u.variable.address;
			swd.symOff += sizeof(ObjSym);
		    }
		    break;
		}
		case OSYM_LABEL:
		    if (genericSyms)
		    {
			break;
		    }
		    outos = CopySym(&swd, os);
		    Sym_Enter(output, outs->toc, outos->name,
			      swd.syms, swd.symOff);
		    swd.nextMap->last = outos->u.label.address;
		    swd.symOff += sizeof(ObjSym);
		    break;
		case OSYM_PROFILE_MARK:
		    outos = CopySym(&swd, os);
		    swd.nextMap->last = outos->u.addrSym.address;
		    swd.symOff += sizeof(ObjSym);
		    break;
	    }
	}
	next = osh->next;
	VMUnlock(input, osh->types);
	VMUnlock(input, cur);
    }

    /*
     * Shrink the final type block down and unlock it -- all the rest will
     * be duplicated from the input file.
     */
    if (swd.typeOff < swd.typeSize) {
	ObjTypeHeader	*thdr;
	
	MemReAlloc(swd.tmem, swd.typeOff, 0);
	MemInfo(swd.tmem, (genptr *)&thdr, (word *)NULL);
	thdr->num = (swd.typeOff - sizeof(ObjTypeHeader)) / sizeof(ObjType);
    }
    VMUnlockDirty(output, swd.types);

    /*
     * Shrink final block, if appropriate.
     */
    if (swd.prevSymH) {
	if (swd.symOff < swd.symSize) {
	    MemReAlloc(swd.mem, swd.symOff, 0);
	    MemInfo(swd.mem, (genptr *)&swd.prevSymH, (word *)0);
	    swd.symSize = swd.symOff;
	    swd.prevSymH->num =
		(swd.symOff - sizeof(ObjSymHeader))/sizeof(ObjSym);
	}
	/*
	 * All done with the address map, thanks.
	 */
	VMUnlockDirty(output, swd.map);
    }

    if (cur != 0) {
	/*
	 * Hit a bunch of type symbols, all of which need to be entered.
	 * These are easier to do -- we just want to copy the blocks verbatim.
	 * No duplication of types, nothing.
	 */
	VMBlockHandle	lastTypes = 0;
	VMBlockHandle	typeDup;
	VMBlockHandle	dup;
	
	while (cur != 0) {
	    ObjSymHeader	*osh;
	    ObjSym	    	*os;
	    int 	    	n;
	    MemHandle	    	mem;

	    mem = VMDetach(input, cur);
	    dup = VMAlloc(output, 0, OID_SYM_BLOCK);
	    VMAttach(output, dup, mem);
	    
	    osh = (ObjSymHeader *)VMLock(output, dup, NULL);
	    os = ObjFirstEntry(osh, ObjSym);

	    if (swd.prevSymH) {
		swd.prevSymH->next = dup;
	    } else {
		outs->syms = dup;
	    }
	    swd.prevSymH = osh;

	    /*
	     * If type block not already copied into the output file, do so now,
	     * changing the types field of the duplicate symbol block to be
	     * that of the duplicated type block.
	     */
	    if (osh->types != lastTypes) {
		lastTypes = osh->types;
		typeDup = osh->types = DupTypeBlock(input, osh->types);
	    } else {
		osh->types = typeDup;
	    }
	    
	    for (n = osh->num; n > 0; n--, os++) {
		int 	    	enter;

		if (os->name != NullID) {
		    VMBlockHandle	junkBlock;
		    word	    	junkOffset;

		    enter = (Sym_Find(input, s->toc, os->name,
				      &junkBlock, &junkOffset) &&
			     (junkBlock == cur) &&
			     (junkOffset == ObjEntryOffset(os,osh)));
		} else {
		    enter = 0;
		}
		os->name = ST_Dup(input, os->name, output, outstr);
		if (enter) {
		    Sym_Enter(output, outs->toc, os->name, dup,
			      ObjEntryOffset(os,osh));
		}
	    }
	    next = osh->next;
	    VMUnlockDirty(output, dup);
	    cur = next;
	}
    }
    Sym_Close(output, outs->toc);
}

/*********************************************************************
 *			FindStringInGPFile
 *********************************************************************
 * SYNOPSIS: 	find the string in the gp file
 * CALLED BY:	StripSegment
 * RETURN:  	index of routine (or 0 if not found)
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	7/ 9/93		Initial version			     
 * 
 *********************************************************************/
int
FindStringInGPFile(char *name, FILE *gpfile)
{
    char    buf[256];
    int	    index = 0;

    if (gpfile == NULL) {
	return 0;
    }

    /* set the file to the beginning */
    fseek(gpfile, 0L, 0);
    while (1)
    {
	char	cp;
	int 	start;

    	fgets(buf, sizeof(buf), gpfile);
	if ((!strncmp(buf, "export", 6) && (start=6)) ||
	    (!strncmp(buf, "publish", 7) && (start=7)))
	{
	    int	len = strlen(name);

	    while(isspace(buf[start]))
	    {
		start++;
	    }
	    index++;
	    if (!strncmp(buf+start, name, len))
	    {
		if (isspace(buf[start+len]))
		{
		    return index;
		}
	    }
	} else if (!strncmp(buf, "skip", 4))
	{
	    int	start = 4;
	    int	skip;

	    while(isspace(buf[start]))
	    {
		start++;
	    }
	    
	    skip = atoi(buf+start);
	    index += skip;
	}

	cp = getc(gpfile);
	if (cp == EOF)
	{
	    return 0;
	}
	ungetc(cp, gpfile);
    }
}

/***********************************************************************
 *				FixModuleSymbols
 ***********************************************************************
 * SYNOPSIS:	    Fix up the table value for any module symbols in the
 *	    	    first block of the symbol table for the global
 *	    	    segment.
 * CALLED BY:	    StripHeader
 * RETURN:	
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/22/92		Initial Revision
 *
 ***********************************************************************/
void
FixModuleSymbols(VMHandle   output,
		 ObjHeader  *hdr)
{
    ObjSegment	    *global;
    ObjSymHeader    *osh;
    ObjSym  	    *os;

    global = (ObjSegment *)(hdr+1);
    if (global->syms == 0) {
	return;
    }
    osh = (ObjSymHeader *)VMLock(output, global->syms, (MemHandle *)NULL);
    os = ObjFirstEntry(osh, ObjSym);

    if (os->type == OSYM_MODULE) {
	int 	n;
	/*
	 * Entire block contains only module symbols, so...
	 */
	for (n = osh->num; n > 0; n--, os++) {
	    ObjSegment  *s;
	    int	    	sn;

	    for (s = (ObjSegment *)(hdr+1), sn = hdr->numSeg;
		 sn > 0;
		 sn--, s++)
	    {
		if (s->name == os->name) {
		    os->u.module.table = s->toc;
		    os->u.module.syms = s->syms;
		    break;
		}
	    }
	}
	VMDirty(output, global->syms);
    }
    VMUnlock(output, global->syms);
}

/***********************************************************************
 *				StripHeader
 ***********************************************************************
 * SYNOPSIS:	    Begins the stripping process starting with the header.
 *	    	    This actually is the driving function for the whole
 *	    	    process...
 * CALLED BY:	    main
 * RETURN:	    nothing
 * SIDE EFFECTS:    lots
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/22/92		Initial Revision
 *
 ***********************************************************************/
void
StripHeader(VMHandle	    input,
	    ObjHeader	    *hdr,
	    VMBlockHandle   map,
	    VMHandle	    output,
	    FILE    	    *gpfile)
{
    word    	    size;
    VMBlockHandle   outmap;
    ObjHeader	    *outhdr;
    ObjSegment	    *s, *outs;
    ObjGroup	    *g, *outg;
    int	    	    i;

    VMInfo(input, map, &size, (MemHandle *)NULL, (VMID *)NULL);
    outmap = VMAlloc(output, size, OID_MAP_BLOCK);

    VMSetMapBlock(output, outmap);

    outstr = ST_Create(output);
    outhdr = (ObjHeader *)VMLock(output, outmap, (MemHandle *)NULL);

    bzero(outhdr, size);
    if (symfileFormat) {
	outhdr->magic = OBJMAGIC_NEW_FORMAT;
    } else {
	outhdr->magic = OBJMAGIC;
    }
    outhdr->numSeg = hdr->numSeg;
    outhdr->numGrp = hdr->numGrp;
    outhdr->strings = outstr;
    outhdr->srcMap = 0;
    outhdr->rev = hdr->rev;
    outhdr->proto = hdr->proto;

    for (i=hdr->numSeg, s=(ObjSegment *)(hdr+1), outs=(ObjSegment *)(outhdr+1);
	 i > 0;
	 s++, outs++, i--)
    {
	StripSegment(output, outs, input, s, ObjEntryOffset(s,hdr), gpfile);
    }

    for (i=hdr->numGrp, g=(ObjGroup *)s, outg=(ObjGroup *)outs;
	 i > 0;
	 g = OBJ_NEXT_GROUP(g), outg = OBJ_NEXT_GROUP(outg), i--)
    {
	bcopy(g, outg, OBJ_GROUP_SIZE(g->numSegs));
	outg->name = ST_Dup(input, g->name, output, outstr);
    }

    /* MANGLE MODULE SYMBOLS IN GLOBAL SEGMENT */
    FixModuleSymbols(output, outhdr);

    VMUnlockDirty(output, outmap);
    ST_Close(output, outstr);
}


void Usage()
{
    printf("Stripsym can be used to either strip out internal symbols\n");
    printf("from a sym file, or create a gym file from a sym file\n");
    printf("To create a stripped down sym file:\n"); 
    printf("	stripsym symfile outfile\n");
    printf("To create a gym file:\n");
    printf("	stripsym -g symfile gymfile gpfile\n");
}


volatile void
main(argc, argv)
    int	    argc;
    char    **argv;
{
    short   	    status;
    VMBlockHandle   map;
    ObjHeader	    *hdr;
    int	    	    i;
    extern volatile void exit(int);
    extern char	    *optarg;
    extern int	    optind;
    char    	    optchar;
    FILE    	    *gpfile = (FILE *) NULL;

    if (argc == 1) {
	Usage();
	return;
    }

    while ((optchar = getopt(argc, argv, "Ddg"))  != -1) {
	switch (optchar) {
	    case 'D':
		debug = 1;
		break;
	    case 'g':
		genericSyms = 1;
		break;
	}
    }
    if (optind + 1 == argc) {
	printf("Missing input file name\n");
	exit(1);
    }
    
    idfile = input = VMOpen(VMO_OPEN|FILE_DENY_W|FILE_ACCESS_R, 0,
			    argv[optind],
			    &status);

    if (input == NULL) {
	printf("Couldn't open %s\n", argv[optind]);
	exit(1);
    }

    geosRelease = VMGetVersion(input);

    map = VMGetMapBlock(input);
    hdr = (ObjHeader *)VMLock(input, map, NULL);
    if ((hdr->magic != OBJMAGIC) && (hdr->magic != SWOBJMAGIC) &&
	(hdr->magic != OBJMAGIC_NEW_FORMAT) && 
	 (hdr->magic != SWOBJMAGIC_NEW_FORMAT))
    {
	printf("invalid magic number (is %04x, s/b %04x)\n",
	       hdr->magic, OBJMAGIC);
	exit(1);
    }
    else switch (hdr->magic)
    {
	case SWOBJMAGIC:
	    	/*
		 * If file was written in the other order, set a relocation
		 * routine for the file so blocks get byte-swapped properly.
		 */
		ObjSwap_Header(hdr);
		VMSetReloc(input, ObjSwap_Reloc);
		/* FALLTHRU */
	case OBJMAGIC:
		symfileFormat = 0;
		break;
	case SWOBJMAGIC_NEW_FORMAT:
		ObjSwap_Header(hdr);
		VMSetReloc(input, ObjSwap_Reloc_NewFormat);
		/* FALLTHRU */
	case OBJMAGIC_NEW_FORMAT:
		symfileFormat = 1;
		break;
    }

    output = VMOpen(VMO_CREATE_TRUNCATE|FILE_DENY_RW|FILE_ACCESS_RW, 0,
		    argv[optind+1],
		    &status);
    if (output == NULL) {
	printf("Couldn't create %s\n", argv[optind+1]);
	VMClose(input);
	exit(1);
    }

    if (genericSyms)
    {
    	/* if we are trying to create generic symbol files then open up the
	 * associated ldf file to make my life easier
	 */
	if (optind + 3 > argc) {
	    printf("WARNING: No GP file passed!\n");
	} else {
	    gpfile = fopen(argv[optind+2], "rt");
	    if (gpfile == (FILE *)NULL) 
	    {
	    	printf("Couldn't open %s\n", argv[optind+2]);
		VMClose(input);
		VMClose(output);
		exit(1);
	    }
	}
    }

    if (geosRelease > 1) {
	GeosFileHeader2	gfh;

	VMGetHeader(input, (genptr)&gfh);
	VMSetHeader(output, (genptr)&gfh);
    } else {
	GeosFileHeader	gfh;

	VMGetHeader(input, (genptr)&gfh);
	VMSetHeader(output, (genptr)&gfh);
    }
    
    StripHeader(input, hdr, map, output, gpfile);

    VMClose(input);
    VMClose(output);
    if (gpfile != (FILE *)NULL)
    {
	fclose(gpfile);
    }
    exit(0);

}
