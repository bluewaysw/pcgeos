/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1989,1990,1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Symbol Table Manipulation
 * FILE:	  sym.c
 *
 * AUTHOR:  	  Adam de Boor: Oct 20, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Sym_Create  	    Create a new, empty symbol table
 *	Sym_Close   	    Close down a symbol table
 *	Sym_Destroy 	    Destroy a symbol table
 *	Sym_Enter   	    Enter a symbol in a table.
 *	Sym_Find    	    Locate a symbol in a table
 *	Sym_FindWithSegment Locate a symbol in any table, returning the symbol
 *	    	    	    and its segment.
 *	Sym_EnterUndef	    Enter an undefined symbol into a table...sort of
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/20/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Symbol table creation and examination for Glue. A symbol table
 *	consists of a chain-root block and a set of blocks making up
 *	the individual chains. The entries in the chains are eight
 *	bytes each: four for the ID, two for the symbol block, two
 *	for the offset in that block in which the symbol resides.
 *
 *	Before the symbol is entered into the table, it must be entered
 *	into a symbol block for the segment in the output file.
 *
 *	A symbol table serves only as a hash table mapping symbol names
 *	to block/offset pairs; all data for the symbol reside at that
 *	block/offset address.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: sym.c,v 3.22 95/11/08 18:13:52 adam Exp $";
#endif lint

#include    "glue.h"
#include    "obj.h"
#include    "sym.h"
#include    "objfmt.h"
#include    <stddef.h>

extern Boolean oldSymfileFormat;

/*
 * List of undefined symbols. Perhaps it should be a hash table?
 * Since the symbol table is really only a mapping of name to block/offset,
 * and we can't place an undefined symbol in the final output file (e.g.
 * if we did that for a procedure, the by-address sorting order of the
 * block would be destroyed), and we need to have the expected type information
 * for a symbol around to make sure there are no mismatches between
 * object files....I'll leave this sentence dangling :)
 */
SymUndef  	*symUndefHead;	    /* Head of list of undefined symbols */


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
    int	size;
    /*
     * VM code will zero the block the first time it's locked down.
     */
    if (oldSymfileFormat == TRUE) {
	size = sizeof(ObjHashHeader);
    } else {
	size = sizeof(ObjHashHeaderNewFormat);
    }
    return(VMAlloc(file, size, OID_HASH_HEAD_BLOCK));
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
    int	    	    	obj_hash_chains;

    hdr = (ObjHashHeader *)VMLock(file, table, (MemHandle *)NULL);

    if (oldSymfileFormat == TRUE) {
	obj_hash_chains = OBJ_HASH_CHAINS;
    } else {
	obj_hash_chains = OBJ_HASH_CHAINS_NEW_FORMAT;
    }
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
 *				Sym_Destroy
 ***********************************************************************
 * SYNOPSIS:	    Destroy a symbol table, freeing any space allocated
 *	    	    for it and all of its chains.
 * CALLED BY:	    Final.
 * RETURN:	    Nothing
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
void
Sym_Destroy(VMHandle  	    file,
	    VMBlockHandle   table)
{
    ObjHashHeader   	*hdr;
    int	    	    	i;
    int	    	    	obj_hash_chains;

    if (oldSymfileFormat == TRUE) {
	obj_hash_chains = OBJ_HASH_CHAINS;
    } else {
	obj_hash_chains = OBJ_HASH_CHAINS_NEW_FORMAT;
    }
    hdr = (ObjHashHeader *)VMLock(file, table, (MemHandle *)NULL);

    for (i = 0; i < obj_hash_chains; i++) {
	VMBlockHandle	cur, next;

	for (cur = hdr->chains[i]; cur != 0; cur = next) {
	    ObjHashBlock *hb;

	    hb = (ObjHashBlock *)VMLock(file, cur, (MemHandle *)NULL);

	    next = hb->next;
	    VMFree(file, cur);
	}
    }

    VMFree(file, table);
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

    if (oldSymfileFormat == TRUE) {
	index = ST_Index(file, id) % OBJ_HASH_CHAINS;
    } else {
	index = ST_Index(file, id) % OBJ_HASH_CHAINS_NEW_FORMAT;
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
 *				SymCompareSyms
 ***********************************************************************
 * SYNOPSIS:	    Make sure two symbols are equivalent.
 * CALLED BY:	    SymCheckUndef, Sym_EnterUndef
 * RETURN:	    Nothing
 * SIDE EFFECTS:    An error message will be printed if there's an error
 *
 * STRATEGY:
 *  	symbols should be in the same table or one in the table
 *  	    for the global segment.
 *  	symbols must have the same symbol type
 *  	if symbols have type descriptions, they must match
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/21/89	Initial Revision
 *
 ***********************************************************************/
static void
SymCompareSyms(VMHandle	    	file,	/* Output file */
	       VMBlockHandle	table1,	/* Table containing first symbol */
	       ObjSym	    	*sym1,	/* First symbol. NAME MUST BE IN
					 * OUTPUT FILE */
	       word 	    	sym1Off,/* Offset of same within its block */
	       VMHandle	    	tfile1,	/* File containing ObjType's for sym1*/
	       VMBlockHandle	types,	/* Block containing same */
	       VMBlockHandle	table2,	/* Table containing second symbol */
	       ObjSym	    	*sym2,	/* Second symbol */
	       VMHandle	    	tfile2,	/* File containing strings for type
					 * of sym2 */
	       void 	    	*base2)	/* Base of memory block containing
					 * ObjType's for sym2 */
{
    ObjSym  *swapSym;

    /*
     * If either symbol is of unknown type, we just accept the match, as we've
     * no basis for deciding, and hence no basis for complaint.
     */
    if ((sym1->type == OSYM_UNKNOWN) || (sym2->type == OSYM_UNKNOWN)) {
	return;
    }

    if ((table1 != table2) && (table1 != globalSeg->syms) &&
	(table2 != globalSeg->syms))
    {
	SegDesc     *su, *sd;
	int 	    i;

	su = sd = (SegDesc *)NULL;

	for (i = 0; i < seg_NumSegs; i++) {
	    if (seg_Segments[i]->syms == table1) {
		sd = seg_Segments[i];
	    } else if (seg_Segments[i]->syms == table2) {
		su = seg_Segments[i];
	    }
	    if (su && sd) {
		break;
	    }
	}

	assert(su && sd);

	/*
	 * We allow this to happen if one of the two symbols is undefined and
	 * both lie in an lmem segment. Why? To deal with global declaration
	 * of chunks in an lmem segment that has no chunk handles. In this
	 * case, the programmer can't declare the thing global as :chunk <type>,
	 * as that causes problems when using the thing later, since it's
	 * actually a variable, not an lptr to the data. If the programmer
	 * declares it as just :<type>, it's properly identified as a variable,
	 * but its segment is the @Data segment, not the @Heap segment, where
	 * it actually ends up. Without this check, we'd bitch about the symbol
	 * being in two different segments. Sigh.
	 */
	if (!((sym1->flags & OSYM_UNDEF) || (sym2->flags & OSYM_UNDEF)) ||
	    (su->combine != SEG_LMEM) || (sd->combine != SEG_LMEM))
	{
	    Notify(NOTIFY_ERROR, "%i declared in both %i and %i",
		   sym1->name, su->name, sd->name);
	    return;
	}
    }

    /* if sym2 (the new sym) is an OSYM_PROC and sym1 (the known, though not
     * necessarily defined sym) is an OSYM_LABEL then that's really
     * ok, as a global label can just be treated as a procedure, so instead
     * of reporting a type mismatch, just convert the label into a procedure
     *
     * 9/15/93: Jon changed this on 9/10 to copy the near/farness of the
     * procedure to the non-procedure to avoid type conflicts when linking
     * against the Borland RTL. This strikes me as unfortunate, but I'm willing
     * to live with it, provided it's done right -- ardeb
     */
    if ((sym1->type == OSYM_LABEL) && (sym2->type == OSYM_PROC))
    {
	sym1->type = OSYM_PROC;
	sym1->u.proc.flags = sym2->u.proc.flags;
	/*
	 * No local variables yet, so point the local var chain back to the
	 * proc sym itself.
	 */
	sym1->u.proc.local = sym1Off;
	/* XXX: NEED TO VMDIRTY THE BLOCK HOLDING SYM1 */
    } else if ((sym1->type == OSYM_PROC) && (sym2->type == OSYM_LABEL)) {
	/*
	 * Don't have to deal with local vars here, just force sym2 to be
	 * an OSYM_PROC with valid flags. Don't need to dirty the block as we
	 * don't care whether it stays this way.
	 */
	sym2->type = OSYM_PROC;
	sym2->u.proc.flags = sym1->u.proc.flags;
    }


    /* there is code in here that deals with sym1 being a CLASS and sym2
     * being a VAR, but not the other way around, so I just swap the two
     * here if it is the other way around, since we are just checking for
     * type equivalency, I figure there is no harm done and for some reason
     * just allowing the other case in the code without swapping was causing
     * glue to fail an assertion in Obj_TypeEqual down below - jimmy
     */
    if ((sym1->type == OSYM_VAR) &&
	  ((sym2->type == OSYM_CLASS) ||
	   (sym2->type == OSYM_MASTER_CLASS) ||
	   (sym2->type == OSYM_VARIANT_CLASS)))
    {
	swapSym = sym1;
	sym1 = sym2;
	sym2 = sym1;
    }


    if ( (sym1->type != sym2->type) &&
	!( (sym2->type == OSYM_VAR) &&
	  ((sym1->type == OSYM_CLASS) ||
	   (sym1->type == OSYM_MASTER_CLASS) ||
	   (sym1->type == OSYM_VARIANT_CLASS))))
    {
	/* XXX: Record where previous def was! */
	Notify(NOTIFY_ERROR, "%i: symbol type mismatch", sym1->name);
    } else {
	switch(sym1->type) {
	    case OSYM_VAR:
	    case OSYM_CHUNK:
	    {
		void	*base1 = VMLock(tfile1, types, (MemHandle *)NULL);

		if (!Obj_TypeEqual(tfile1,
				   base1,
				   sym1->u.variable.type,
				   tfile2,
				   base2,
				   sym2->u.variable.type) &&
		    sym1->u.variable.type != (OTYPE_VOID|OTYPE_SPECIAL) &&
		    sym2->u.variable.type != (OTYPE_VOID|OTYPE_SPECIAL))
		{
		    Notify(NOTIFY_ERROR,
			   "%i: type differs between object files",
			   sym1->name);
		    fprintf(stderr, "\t");
		    Obj_PrintType(stderr, tfile1, base1, sym1->u.variable.type);
		    fprintf(stderr, "\nversus\n\t");
		    Obj_PrintType(stderr, tfile2, base2, sym2->u.variable.type);
		    fprintf(stderr, "\n");
		}

		VMUnlock(tfile1, types);
		break;
	    }
	    case OSYM_PROC:
		if ((sym1->u.proc.flags & OSYM_NEAR) !=
		    (sym2->u.proc.flags & OSYM_NEAR))
		{
		    Notify(NOTIFY_ERROR,
			   "procedure %i declared both near and far",
			   sym1->name);
		}
		break;
	    case OSYM_LABEL:
		if (sym1->u.label.near != sym2->u.label.near) {
		    Notify(NOTIFY_ERROR,
			   "label %i declared both near and far",
			   sym1->name);
		}
		break;
	}
    }
}

/***********************************************************************
 *				SymCheckUndef
 ***********************************************************************
 * SYNOPSIS:	    Look for an SymUndef record for the symbol and make
 *	    	    sure the types match.
 * CALLED BY:	    Sym_Enter, Sym_EnterUndef
 * RETURN:	    Non-zero if a previous record was found.
 * SIDE EFFECTS:    If sym is for a defined symbol, the SymUndef record
 *	    	    is removed from the list.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/21/89	Initial Revision
 *
 ***********************************************************************/
static int
SymCheckUndef(VMHandle	    file,   /* File containing sym */
	      VMBlockHandle table,  /* Table in which symbol is expected
				     * to/will be put */
	      ID    	    id,	    /* Symbol's name */
	      ObjSym	    *sym,   /* Symbol against which to compare */
	      word  	    symOff, /* Offset of same within its block */
	      VMHandle	    tfile,  /* File containing type block */
	      VMBlockHandle types)  /* Block in file containing any
				     * ObjType records required by sym */
{
    SymUndef   	**prev;
    SymUndef   	*u;
    ID	    	id2;	    	/* ID w/o leading underscore */
    char    	*name;

    name = ST_Lock(symbols, id);

    /* if the thing is defined no reason to look for the other names */
    if (!(sym->flags & OSYM_UNDEF))
    {
	id2 = NullID;
    }
    else
    {
    	if (*name == '_') {
	    id2 = ST_LookupNoLen(symbols, strings, name+1);
	} else {
	    id2 = NullID;
    	}
    }
    ST_Unlock(symbols, id);

    /*
     * See if any matching SymUndef record.
     */
    prev = &symUndefHead;
    for (u = *prev; u != NULL; u = *prev) {
	if ((u->sym.name == id) || (u->sym.name == id2)) {
	    break;
	}
	prev = &u->next;
    }

    if (u == NULL) {
	return(0);
    }

    SymCompareSyms(file, table, sym, symOff, tfile, types,
		   u->table, &u->sym, symbols, (void *)u);

    if (!(sym->flags & OSYM_UNDEF)) {
	/*
	 * Finally, unlink the SymUndef record from the chain, if
	 * it's defined.
	 */
	*prev = u->next;
	free((char *)u);
    } else if ((u->sym.type == OSYM_UNKNOWN) &&
	       (sym->type != OSYM_UNKNOWN))
    {
	/*
	 * If the existing definition gives no clue as to the type of symbol,
	 * but the passed one does, throw away the existing definition and
	 * say no previous record was found, so the new one will be
	 * stored in its stead.
	 */
	*prev = u->next;
	free((char *)u);
	return(0);
    }


    return(1);
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
    int	    	    obj_syms_per;   /* used to support both symfile formats */

			    //Notify(NOTIFY_WARNING,
				  // "Sym_Enter %i",
				  // id);


    if (!SymLookup(file, table, id, &bucket, &block, &hb, &he)) {
	VMID	    vmid;
	/*
	 * See if the block contains symbols -- we need to do other things
	 * if the thing's actually a symbol. Checking this allows us to use
	 * the same hashing code for source file stuff.
	 */
	VMInfo(file, symBlock, (word *)NULL, (MemHandle *)NULL, &vmid);

	if (vmid == OID_SYM_BLOCK) {
	    ObjSym  	    *os;    /* Locked version of symbol data */
	    ObjSymHeader    *osh;   /* Header of block containing data */

	    osh = (ObjSymHeader *)VMLock(file, symBlock, (MemHandle *)NULL);
	    os = (ObjSym *)((genptr)osh + symOff);

	    if (os->flags & OSYM_GLOBAL) {
		/*
		 * If symbol is global, make sure it's not defined global in
		 * any other segment. Even if it is, we don't abort -- that'll
		 * happen at the end of this pass when main() discovers "errors"
		 * is non-zero.
		 */
		int 	    i;	    	/* Index of current segment */
		/* More-or-less-junk variables for search */
		VMBlockHandle   oblock;
		ObjHashBlock    *ohb;
		ObjHashEntry    *ohe;
		VMBlockHandle   *obucket;

		for (i = 0; i < seg_NumSegs; i++) {
		    SegDesc 	*sd = seg_Segments[i];

		    if ((sd->syms != table) &&
			SymLookup(symbols, sd->syms, id, &obucket,
				  &oblock, &ohb, &ohe))
		    {
			ObjSym  *osym;

			osym = (ObjSym *)((genptr)VMLock(symbols, ohe->block,
						 (MemHandle *)NULL)+ohe->offset);

			if (osym->flags & OSYM_GLOBAL) {
			    Notify(NOTIFY_ERROR,
				   "%i already defined (in segment %i)",
				   id, sd->name);
			}
			VMUnlock(symbols, ohe->block);
			VMUnlock(symbols, oblock);
			VMUnlock(symbols, sd->syms);
		    }
		}

		SymCheckUndef(file, table, id, os, symOff, file, osh->types);
	    }
	    VMUnlock(file, symBlock);
	}

	if (oldSymfileFormat == TRUE) {
	    obj_syms_per = OBJ_SYMS_PER;
	} else {
	    obj_syms_per = OBJ_SYMS_PER_NEW_FORMAT;
	}
	if (!hb || (hb->nextEnt == obj_syms_per)) {
	    /*
	     * Out of room in this block -- allocate another one.
	     */
	    VMBlockHandle   new;
	    int	    	    size;

	    if (oldSymfileFormat == TRUE) {
		size = sizeof(ObjHashBlock);
	    } else {
		size = sizeof(ObjHashBlockNewFormat);
	    }

	    new = VMAlloc(file, size, OID_HASH_BLOCK);
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
	Notify(NOTIFY_WARNING, "%i multiply defined in a single segment", id);
    }
    /*
     * table and block were left locked by SymLookup
     */
    VMUnlock(file, block);
    VMUnlock(file, table);
}


/***********************************************************************
 *				Sym_FindWithSegment
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
Sym_FindWithSegment(VMHandle   	    file,	   /* File in which to
						    * search */
		    ID 	    	    id, 	   /* Name of symbol to find */
		    VMBlockHandle   *symBlockPtr,   /* Place to store handle of
					            * block holding the symbol
					            */
		    word	    *symOffPtr,    /* Place to store the offset
					            * into the block at which
						    * the symbol lies */
		    int	    	    globalOnly,	   /* TRUE if only a global
						    * symbol is acceptable */
		    SegDesc 	    **sdPtr) 	   /* Place to store segment
						    * that contains the symbol
						    */
{
    VMBlockHandle   *bucket;	    /* Bucket in which symbol sits */
    VMBlockHandle   block;  	    /* Block in which symbol sits */
    ObjHashBlock    *hb;    	    /* Locked version of same */
    ObjHashEntry    *he;    	    /* Entry at which symbol was found */
    int	    	    retval;
    int 	    i;
    SegDesc 	    *sd = NULL;

    for (i = 0; i < seg_NumSegs; i++) {
	sd = seg_Segments[i];

	if (SymLookup(file, sd->syms, id, &bucket, &block, &hb, &he))
	{
	    int 	    	isglobal;
	    ObjSym	    	*os;
	    ObjSymHeader	*osh;

	    /*
	     * Lock the defined version down.
	     */
	    osh = (ObjSymHeader *)VMLock(file,he->block,(MemHandle *)NULL);

	    os = (ObjSym *)((genptr)osh + he->offset);

	    isglobal = (os->flags & OSYM_GLOBAL);

	    /*
	     * Release the table and symbol always
	     */
	    VMUnlock(file, sd->syms);
	    VMUnlock(file, he->block);

	    if (isglobal || !globalOnly) {
		break;
	    } else {
		VMUnlock(file, block);
	    }
	} else {
	    if (block) {
		VMUnlock(file, block);
	    }
	    VMUnlock(file, sd->syms);
	}
	sd = NULL;
    }
    if (sd != NULL) {
	/*
	 * If sd is non-null, we broke out of the loop when we found a
	 * global symbol of the proper name.
	 */
	retval = 1;
    } else {
	/*
	 * If none defined, block is already unlocked.
	 */
	block = 0;
	retval = 0;
    }

    if (retval) {
	*sdPtr = sd;
	*symBlockPtr = he->block;
	*symOffPtr = he->offset;
    }
    if (block != 0) {
	VMUnlock(file, block);
    }

    return(retval);
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
	 word	    	*symOffPtr, 	/* Place to store the offset into the
					 * block at which the symbol lies */
	 int	    	globalOnly) 	/* TRUE if only a global symbol is
					 * acceptable */
{
    VMBlockHandle   *bucket;	    /* Bucket in which symbol sits */
    VMBlockHandle   block;  	    /* Block in which symbol sits */
    ObjHashBlock    *hb;    	    /* Locked version of same */
    ObjHashEntry    *he;    	    /* Entry at which symbol was found */
    int	    	    retval;

    if (table == 0) {
	/*
	 * Joy! Rapture! Bliss! The caller has no *clue* where the little
	 * beggar may be ensconced, so we get to go through all the segments
	 * and try and find a defined, global version of the symbol.
	 */
	SegDesc	    *sd;    	/* Junk variable */

	return(Sym_FindWithSegment(file, id, symBlockPtr, symOffPtr,
				   globalOnly, &sd));

    } else {
	retval = SymLookup(file, table, id, &bucket, &block, &hb, &he);
	VMUnlock(file, table);
    }

    if (retval) {
	*symBlockPtr = he->block;
	*symOffPtr = he->offset;
    }
    if (block != 0) {
	VMUnlock(file, block);
    }

    return(retval);
}


/***********************************************************************
 *				Sym_EnterUndef
 ***********************************************************************
 * SYNOPSIS:	    Register another undefined symbol.
 * CALLED BY:	    pass1 functions
 * RETURN:	    Nothing
 * SIDE EFFECTS:    An SymUndef record could be added to the list
 *
 * STRATEGY:
 *	There are three things this function needs to do:
 *	    - if the symbol is already defined, type-check the undefined
 *	      against the defined.
 *	    - if the symbol is already undefined, type-check the two
 *	      undefined symbols.
 *	    - if none of the above, prepare an Undef record for later use.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
void
Sym_EnterUndef(VMHandle	    	file,	/* Output file */
	       VMBlockHandle	table,	/* Table in which symbol should be
					 * (eventually) defined */
	       ID   	    	id, 	/* Name for symbol as copied to the
					 * output file */
	       ObjSym	    	*os,	/* Record for undefined symbol */
	       word 	    	symOff,	/* Offset of same within its block */
	       VMHandle	    	tfile,	/* File containing types block */
	       VMBlockHandle	types)	/* Block containing any ObjType
					 * records required by the symbol */
{
    if (!SymCheckUndef(file, table, id, os, symOff, tfile, types)) {
	/*
	 * No previous record for this symbol. See if maybe it's defined
	 * elsewhere. We search all segments, rather than just the one
	 * into which we expect the symbol to go, to catch any segment
	 * mismatch between the symbol's declaration and its definition.
	 */
	int 	    i;	    	/* Index of current segment */
	VMBlockHandle   block;	/* Block containing actual/potential entry */
	ObjHashBlock    *hb;	/* Header of same */
	ObjHashEntry    *he;	/* Actual/potential entry */
	VMBlockHandle   *bucket;/* Head pointer of bucket for sym */
	SegDesc 	*sd;	/* Descriptor of already-defined sym segment */
	SegDesc	    	*su;	/* Descriptor of this undefined sym segment */
	ObjSymHeader    *osh;	/* Header of block containing defined sym */
	ObjSym  	*ds;	/* Defined symbol */
	VMBlockHandle	dblock;	/* Block containing same */

	/*
	 * Figure the segment to which the undefined symbol belongs by
	 * examining the symbol tables bound to the segment descriptors.
	 */
	su = NULL;
	for (i = 0; i < seg_NumSegs; i++) {
	    su = seg_Segments[i];
	    if (su->syms == table) {
		break;
	    }
	}

	assert(su != NULL);

	/*
	 * Now run through all the segments looking for a definition for the
	 * symbol.
	 */
	sd = NULL;
	osh = NULL;		/* Be quiet, GCC (osh will be non-null and
				 * valid only if sd is non-null, and that's
				 * the only time osh is used) */
	ds = NULL;		/* Be quiet, GCC (ditto) */

	for (i = 0; i < seg_NumSegs; i++) {
	    sd = seg_Segments[i];

	    if (SymLookup(file, sd->syms, id, &bucket, &block, &hb, &he))
	    {
		int 	isglobal;

		/*
		 * Lock the defined version down. No need to lock the types
		 * block for it -- SymCompareSyms will do so if required.
		 */
		osh = (ObjSymHeader *)VMLock(file,
					     he->block,
					     (MemHandle *)NULL);

		ds = (ObjSym *)((genptr)osh + he->offset);

		isglobal = (ds->flags & OSYM_GLOBAL);

		VMUnlock(file, block);
		VMUnlock(file, sd->syms);

		if (isglobal) {
		    /*
		     * Record symbol block and break out of loop
		     */
		    dblock = he->block;
		    break;
		} else {
		    /*
		     * Release the symbol block
		     */
		    VMUnlock(file, he->block);
		}
	    } else {
		if (block) {
		    VMUnlock(file, block);
		}
		VMUnlock(file, sd->syms);
	    }
	    sd = NULL;
	}

	if (sd && (sd != su) && (su->combine != SEG_GLOBAL) &&
	    !((sd->combine == SEG_LMEM) && (su->combine == SEG_LMEM)))
	{
	    Notify(NOTIFY_ERROR,
		   "%i declared in %i, actually in %i",
		   id, su->name, sd->name);
	    VMUnlock(file, dblock);
	} else if (sd) {
	    /*
	     * Symbol already defined in the proper segment -- type check
	     * against undef version we've got now.
	     */
	    void    	    *tbase = VMLock(tfile, types, (MemHandle *)NULL);

	    /*
	     * Generate any necessary error messages
	     */
	    SymCompareSyms(file, sd->syms, ds, he->offset, file, osh->types,
			   table, os, tfile, tbase);

	    /*
	     * Unlock the blocks we've got.
	     */
	    VMUnlock(file, dblock);
	    VMUnlock(tfile, types);
	} else {
	    /*
	     * Yuck. We need to make an Undef record for the thing, copying
	     * in any type description required.
	     */
	    int	    ntypes = 0;	/* Number of type records to allocate after
				 * the SymUndef record proper */
	    void    *tbase = NULL;
	    SymUndef   *u;

	    if ((os->type == OSYM_VAR) || (os->type == OSYM_CHUNK)) {
		word	    type = os->u.variable.type;

		tbase = VMLock(tfile, types, (MemHandle *)NULL);
		while (!(type & OTYPE_SPECIAL)) {
		    ObjType *t = (ObjType *)((genptr)tbase + type);

		    ntypes += 1;
		    if (!OTYPE_IS_STRUCT(t->words[0])) {
			type = t->words[1];
		    } else {
			break;
		    }
		}
	    }

	    u = (SymUndef *)malloc(sizeof(SymUndef) + (ntypes * sizeof(ObjType)));
	    u->table = table;
	    u->sym = *os;
	    u->next = symUndefHead;
	    symUndefHead = u;

	    if ((os->type == OSYM_VAR) || (os->type == OSYM_CHUNK)) {
		word	    type = os->u.variable.type;
		word	    *tp = &u->sym.u.variable.type;
		int 	    tnum = 0;

		/*
		 * Always need to copy at least one word, so use a do while
		 * loop until we've copied in all the type records this
		 * symbol requires.
		 */
		while (tnum != ntypes) {
		    if (type & OTYPE_SPECIAL) {
			/*
			 * Copy special type token directly in.
			 * XXX: Probably never used.
			 */
			*tp = type;
		    } else {
			ObjType	*t = (ObjType *)((genptr)tbase + type);

			if (OTYPE_IS_STRUCT(t->words[0])) {
			    /*
			     * Structural type needs to have its name copied
			     * into the output file's string table.
			     */
			    ID	    id = ST_Dup(tfile, OTYPE_STRUCT_ID(t),
						symbols, strings);

			    OTYPE_ID_TO_STRUCT(id,&u->types[tnum]);
			} else {
			    /*
			     * Pointer or array needs dimension copied with
			     * base type handled on next loop.
			     */
			    u->types[tnum].words[0] = t->words[0];
			    type = t->words[1];
			}
			/*
			 * Store offset of duplicated ObjType and point
			 * tp at what could be the base type of the thing,
			 * upping tnum.
			 */
			*tp = ((genptr)(&u->types[tnum])-(genptr)u);
			tp = &u->types[tnum++].words[1];
		    }
		}
		/*
		 * Copy final special type in.
		 */
		if (type & OTYPE_SPECIAL) {
		    *tp = type;
		}
	    }

	    /*
	     * Copy the symbol name into the output file as well.
	     */
	    u->sym.name = id;
	}
    }
}


/***********************************************************************
 *				Sym_AllocCommon
 ***********************************************************************
 * SYNOPSIS:	    Allocate communal variables for a segment.
 * CALLED BY:	    InterPass
 * RETURN:	    nothing
 * SIDE EFFECTS:    any undefined symbols in the passed segment will have
 *	    	    space allocated for them at the end of the segment.
 *
 * STRATEGY:
 *	    On the assumption there won't be huge gobs of these things,
 *	    I've decided to use a single symbol block and a single type
 *	    block to hold the data for communal variables allocated here.
 *	    If this poses a problem later, it should be fairly simple to
 *	    change it to be as gross as other code that deals with this
 *	    stuff.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 5/91		Initial Revision
 *
 ***********************************************************************/
void
Sym_AllocCommon(SegDesc	*sd)
{

    SymUndef   	    *u, **prev;
    VMBlockHandle   symBlock;	/* Symbol block being filled */
    word    	    symSize;	/* Current size of same */
    ObjSymHeader    *osh;   	/* Header for same */
    ObjSym  	    *os;    	/* Next free slot in same */
    MemHandle	    symMem; 	/* Memory handle for same */
    word    	    symOff; 	/* Offset of next free slot in same */
    VMBlockHandle   typeBlock;	/* Associated type block being filled */
    word    	    typeSize;	/* Current size of same */
    ObjTypeHeader   *oth;   	/* Header for same */
    ObjType 	    *ot;    	/* Next free slot in same */
    MemHandle	    typeMem;	/* Memory handle for same */
    word    	    typeOff;	/* Offset of next free slot in same */
    int	    	    ntypes; 	/* Number of ObjType records that need
				 * copying from the SymUndef record to the
				 * associated type block */
    word    	    type;   	/* General purpose type descriptor for
				 * copying/relocating */

    prev = &symUndefHead;
    symBlock = 0;
    symSize = 0;		/* Be quiet, GCC (set to a real value
				 * when symBlock is non-0, which it is the
				 * first time through the loop) */
    symOff = 0;			/* Be quiet, GCC (ditto) */
    os = NULL;			/* Be quiet, GCC (ditto) */
    typeBlock = 0;		/* Be quiet, GCC (only used when symBlock
				 * has been set 0, and that code always
				 * sets this to something real) */
    typeSize = 0;		/* Be quiet, GCC (ditto) */
    ot = NULL;			/* Be quiet, GCC (ditto) */
    typeOff = 0;		/* Be quiet, GCC (ditto) */

    for (u = *prev; u != (SymUndef *)NULL; u = *prev) {
	if ((u->table == sd->syms) && (u->sym.type == OSYM_VAR)) {
	    /*
	     * This undefined monster is in the proper segment. Figure its
	     * size, define it as a variable with an offset of the current
	     * size of the segment.
	     */
	    u->sym.u.variable.address = sd->size;
	    sd->size += Obj_TypeSize(u->sym.u.variable.type, (void *)u,
				     FALSE);
	    numAddrSyms += 1;
	    u->sym.flags &= ~OSYM_UNDEF;

	    /*
	     * If we've not yet allocated a symbol and type block for the
	     * variables we're allocating around here, do so now. The blocks
	     * remain locked for the remainder of the loop. Ignore warnings
	     * about symSize, os, osh, oth, typeBlock, typeSize, ot, typeOff
	     * or diff being used uninitialized in this function -- they're
	     * all taken care of by the symBlock = 0 at the start of this
	     * function.
	     */
	    if (symBlock == 0) {
		symSize = OBJ_MAX_SYMS;
		typeSize = OBJ_INIT_TYPES;

		symBlock = VMAlloc(symbols, symSize, OID_SYM_BLOCK);
		typeBlock = VMAlloc(symbols, typeSize, OID_TYPE_BLOCK);

		osh = (ObjSymHeader *)VMLock(symbols, symBlock, &symMem);
		osh->next = 0;
		osh->types = typeBlock;
		osh->num = 0;

		oth = (ObjTypeHeader *)VMLock(symbols, typeBlock, &typeMem);
		oth->num = 0;

		if (sd->addrT != 0) {
		    ObjSymHeader    *addrT;

		    addrT = (ObjSymHeader *)VMLock(symbols, sd->addrT,
						   (MemHandle *)NULL);
		    addrT->next = symBlock;
		    VMUnlockDirty(symbols, sd->addrT);
		} else {
		    sd->addrH = symBlock;
		}
		sd->addrT = symBlock;
		os = ObjFirstEntry(osh, ObjSym);
		symOff = sizeof(ObjSymHeader);
		ot = ObjFirstEntry(oth, ObjType);
		typeOff = sizeof(ObjTypeHeader);
	    }

	    /*
	     * If the new symbol won't fit in the symbol block as it currently
	     * stands, enlarge the block to hold more...
	     */
	    if (symOff >= symSize) {
		symSize += 16 * sizeof(ObjSym);

		MemReAlloc(symMem, symSize, 0);
		MemInfo(symMem, (genptr *)&osh, (word *)0);
		os = (ObjSym *)((genptr)osh + symOff);
	    }

	    *os = u->sym;

	    /*
	     * Count the number of type records that need to be placed in the
	     * type block.
	     */
	    ntypes = 0;
	    type = os->u.variable.type;

	    while (!(type & OTYPE_SPECIAL)) {
		ObjType *t = (ObjType *)((genptr)u + type);

		ntypes += 1;
		if (!OTYPE_IS_STRUCT(t->words[0])) {
		    type = t->words[1];
		} else {
		    break;
		}
	    }

	    /*
	     * If there are any auxiliary type descriptions, copy them into
	     * the type block associated with the symbol block.
	     */
	    if (ntypes != 0) {
		word	diff;

		/*
		 * Make room for the type descriptions that follow the
		 * record.
		 */
		if (typeOff + (ntypes * sizeof(ObjType)) >= typeSize) {
		    typeSize = typeOff + ((ntypes + 16) * sizeof(ObjType));

		    MemReAlloc(typeMem, typeSize, 0);
		    MemInfo(symMem, (genptr *)&oth, (word *)0);
		    ot = (ObjType *)((genptr)oth + typeOff);
		}

		/*
		 * Copy them in wholesale.
		 */
		bcopy(u->types, ot, ntypes * sizeof(ObjType));

		/*
		 * Now relocate the descriptions properly.
		 */
		diff = typeOff - offsetof(SymUndef,types);

		os->u.variable.type += diff;
		type = os->u.variable.type;

		while (!(type & OTYPE_SPECIAL)) {
		    ot = (ObjType *)((genptr)oth + type);

		    if (!OTYPE_IS_STRUCT(ot->words[0])) {
			/*
			 * Adjust the base/element type descriptor, and loop
			 * to relocate that beast as well.
			 */
			ot->words[1] += diff;
			type = ot->words[1];
		    } else {
			break;
		    }
		}
		typeOff += ntypes * sizeof(ObjType);
		oth->num += ntypes;
	    }
	    Sym_Enter(symbols, sd->syms, os->name, symBlock, symOff);

	    os++;
	    symOff += sizeof(ObjSym);
	    osh->num += 1;
	    /*
	     * Do not reset prev, as the record we're using has been nuked
	     * by Sym_Enter...
	     */
	} else {
	    prev = &u->next;
	}
    }

    /*
     * If we allocated any variables, shrink the symbol and type blocks down.
     */
    if (symBlock != 0) {
	/*
	 * Shrink the symbol block down.
	 */
	MemReAlloc(symMem, symOff, 0);
	VMUnlockDirty(symbols, symBlock);

	/*
	 * If no type descriptions added, we still need to leave the block
	 * around, but we make it only 1 byte.
	 */
	if (typeOff == sizeof(ObjTypeHeader)) {
	    typeOff = 1;
	}
	MemReAlloc(typeMem, typeOff, 0);
	VMUnlockDirty(symbols, typeBlock);
    }
}
