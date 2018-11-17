/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- VM Object loading, pass 1
 * FILE:	  pass1vm.c
 *
 * AUTHOR:  	  Adam de Boor: Nov 10, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Pass1VM_Load	    Main entry point to the module
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/10/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	First pass of the linking process when loading in a VM-format
 *	object file.
 *
 *	Responsible for relocating all symbols and line number maps, copying
 *	same to the output file, summing sizes of segments and counting needed
 *	run-time relocations.
 *
 *	For the final output, there are two classes of symbols: those
 *	with addresses (and associated symbols) and those without them
 *	(types). Symbols with addresses are copied straight (after being
 *	relocated).
 *
 *	Type-related symbols have to be dealt with a little more carefully.
 *	For structures, records and typedefs, if the type is defined
 *	in more than one object file, the multiple definitions must be
 *	compared for structural and name equivalence. Any mismatch is
 *	an error. For enumerated types, members with the same name must
 *	have the same value across all object files, while the final
 *	enumerated type is the union of all the definitions in all the
 *	object files.
 *
 *	All this isn't as difficult as it might sound, since Esp produces
 *	a block chain for each segment such that each block contains
 *	only one class of symbols (address-bearing or type). Moreover,
 *	all the address-bearing symbols come first.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: pass1vm.c,v 3.21 93/09/19 18:09:49 adam Exp $";
#endif lint

#include    "glue.h"
#include    "obj.h"
#include    "sym.h"
#include    <lmem.h>
#include    <objfmt.h>
#include    "output.h"


/***********************************************************************
 *				Pass1VMRelLines
 ***********************************************************************
 * SYNOPSIS:	    Relocate the line maps for a single segment
 * CALLED BY:	    Pass1VM_Load
 * RETURN:	    Zero on error.
 * SIDE EFFECTS:    Blocks are added to the symbol file.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 2/89	Initial Revision
 *
 ***********************************************************************/
static int
Pass1VMRelLines(char *file,         /* Name of object file, in case of error */
		VMHandle    fh,     /* Handle of same */
		ObjSegment  *s,	    /* Segment whose lines are being copied */
		SegDesc	    *sd,    /* Internal version of same in output */
		word  	    reloc)  /* Amount by which to relocate lines */
{
    /*
     * If the segment has no line numbers, forget about it.
     */
    if (s->lines == 0) {
	return(1);
    }

    Out_AddLines(file, fh, sd, s->lines, reloc, TRUE);
    return(1);
}

/***********************************************************************
 *				Pass1VMDupTypeBlock
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
Pass1VMDupTypeBlock(VMHandle  	    fh,     /* Object file */
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
    dup = VMAlloc(symbols, 0, OID_TYPE_BLOCK);

    /*
     * Copy the descriptions to the output file.
     */
    mem = VMDetach(fh, block);
    VMAttach(symbols, dup, mem);

    /*
     * Point to the first description. Note that the block could be flushed
     * between the attach and the lock (unlikely, but possible) so we
     * ask for the mem handle as well.
     */
    oth = (ObjTypeHeader *)VMLock(symbols, dup, &mem);
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
	    ID	    id = ST_Dup(fh, OTYPE_STRUCT_ID(ot), symbols, strings);

	    OTYPE_ID_TO_STRUCT(id,ot);
	}
	ot++, n--;
    }

    /*
     * Unlock the block and make sure the system knows it's dirty.
     */
    VMUnlockDirty(symbols, dup);

    /*
     * Return the handle of the duplicate block.
     */
    return(dup);
}

/***********************************************************************
 *				Pass1VMRelAddrSyms
 ***********************************************************************
 * SYNOPSIS:	    Relocate and copy all address-bearing symbols
 *	    	    for the given segment to the symbol file.
 * CALLED BY:	    Pass1VM_Load
 * RETURN:	    0 on error
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 3/89	Initial Revision
 *
 ***********************************************************************/
static int
Pass1VMRelAddrSyms(const char 	    *file,  	/* File name */
		   VMHandle   	    fh,     	/* Object file handle */
		   ObjSegment       *s,     	/* Segment descriptor in obj
						 * file*/
		   SegDesc    	    *sd,    	/* Internal segment
						 * descriptor */
		   word	    	    reloc,  	/* Relocation constant for the
						 * segment */
		   VMBlockHandle    *nextPtr) 	/* Place to return first block
						 * containing non-address
						 * syms */
{
    VMBlockHandle	prev;	    /* Block to which it should be linked */
    VMBlockHandle	next;	    /* Next symbol block */
    VMBlockHandle   	dup;	    /* Duplicate of same in "symbols" */
    VMBlockHandle	lastType;   /* Most recent type block */
    VMBlockHandle	typeDup;    /* Copy of same in output file */
    int	    	    	retval = 1; /* Assume success */

    prev = sd->addrT;
    next = s->syms;

    typeDup = lastType = (VMBlockHandle)NULL;

    while (next != 0) {
	ObjSymHeader    *osh;
	ObjSym      	*os;
	word	    	n;  	/* Number of symbols left in the block */
	MemHandle   	mem;	/* Handle of detached block */

	/*
	 * Make sure this block contains address-bearing symbols.
	 */
	osh = (ObjSymHeader *)VMLock(fh, next, NULL);
	os = (ObjSym *)(osh+1);
	if (!Obj_IsAddrSym(os)) {
	    /*
	     * Not one of the address-bearing types, or is one but it's
	     * undefined, so we've reached the end of the line. Unlock
	     * the block, set up our return values and return.
	     */
	    VMUnlock(fh, next);
	    *nextPtr = next;
	    return(retval);
	}

	/*
	 * Allocate a duplicate block in the symbols file. It will
	 * take its size from the memory handle we'll attach to it.
	 */
	dup = VMAlloc(symbols, 0, OID_SYM_BLOCK);

	/*
	 * Link the duplicate into the chain.
	 */
	if (prev == 0) {
	    sd->addrH = dup;
	} else {
	    osh = (ObjSymHeader *)VMLock(symbols, prev, NULL);
	    osh->next = dup;
	    VMUnlockDirty(symbols, prev);
	}

	sd->addrT = prev = dup;

	/*
	 * "copy" all the records to the duplicate by switching the
	 * memory handle from the block to its duplicate in the
	 * symbol file.
	 */
	mem = VMDetach(fh, next);
	VMAttach(symbols, dup, mem);

	osh = (ObjSymHeader *)VMLock(symbols, dup, &mem);

	/*
	 * If type block not already copied into the output file, do so now,
	 * changing the types field of the duplicate symbol block to be
	 * that of the duplicated type block.
	 */
	if (osh->types != lastType) {
	    lastType = osh->types;
	    osh->types = typeDup = Pass1VMDupTypeBlock(fh, osh->types);
	} else {
	    osh->types = typeDup;
	}

	/*
	 * Now enter the symbols into the table for the segment and relocate
	 * them.
	 */

	n = osh->num;

	os = (ObjSym *)(osh+1);

	while (n > 0) {
	    int	    enter = 0;

	    switch(os->type) {
		case OSYM_VAR:
		case OSYM_CHUNK:
		case OSYM_PROTOMINOR:
		case OSYM_PROC:
		case OSYM_LABEL:
		    enter = 1;
		    /*FALLTHRU*/
		    /* Procedure-local, address-bearing syms */
		case OSYM_LOCLABEL:
		case OSYM_BLOCKSTART:
		case OSYM_BLOCKEND:
		    if (!(os->flags & OSYM_UNDEF)) {
			numAddrSyms += 1;
			os->u.addrSym.address += reloc;
		    }
		    /*FALLTHRU*/
		default:
		    /*
		     * Anything else not handled specially just needs to
		     * have its name duplicated.
		     */
		    os->name = ST_Dup(fh, os->name, symbols, strings);
		    break;
		case OSYM_BINDING:
		    /*
		     * More complex as we need to copy both the name and
		     * the procedure name.
		     */
		    OBJ_STORE_SID(os->u.binding.proc,
				  ST_Dup(fh,
					 OBJ_FETCH_SID(os->u.binding.proc),
					 symbols, strings));

		    os->name = ST_Dup(fh, os->name, symbols, strings);
		    break;
	        case OSYM_PROFILE_MARK:
		    os->u.addrSym.address += reloc;
		    numAddrSyms += 1;
		    sd->hasProfileMark = 1;
		    break;
		case OSYM_ONSTACK:
		    /*
		     * Need to relocate and copy the descriptor string.
		     * The name is always Null.
		     */
		    OBJ_STORE_SID(os->u.onStack.desc,
				  ST_Dup(fh,
					 OBJ_FETCH_SID(os->u.onStack.desc),
					 symbols, strings));
		    os->u.onStack.address += reloc;
		    break;
		case OSYM_CLASS:
		case OSYM_MASTER_CLASS:
		case OSYM_VARIANT_CLASS:
		    /*
		     * Need to relocate (if defined) and copy the superclass
		     * ID and the name.
		     */
		    enter = 1;
		    if (!(os->flags & OSYM_UNDEF)) {
			numAddrSyms += 1;
			os->u.addrSym.address += reloc;
		    }
		    OBJ_STORE_SID(os->u.class.super,
				  ST_Dup(fh,
					 OBJ_FETCH_SID(os->u.class.super),
					 symbols, strings));
		    os->name = ST_Dup(fh, os->name, symbols, strings);
		    break;
	    }

	    /*
	     * If the symbol should be entered in the symbol table for this
	     * segment, do so now. The only things that go into the table
	     * are the ID and the block:offset for the ObjSym itself --
	     * all the rest of the info normally kept in a symbol table is
	     * kept in the ObjSym.
	     */
	    if (enter && (os->name != NullID)) {
		Sym_Enter(symbols, sd->syms, os->name,
			  dup, ((genptr)os - (genptr)osh));
	    }

	    os++, n--;
	}

	/*
	 * The duplicated block still has osh->next pointing back to the
	 * object file chain, so get the next block handle from there (saves
	 * having to lock the original block again), then null-terminate the
	 * chain in the output file, unlocking and marking the duplicate
	 * as dirty.
	 */
	next = osh->next;
	osh->next = (VMBlockHandle)NULL;
	VMUnlockDirty(symbols, dup);
    }

    /*
     * Set up return values and return.
     */
    *nextPtr = next;
    return(retval);
}

/***********************************************************************
 *				Pass1VMCountRels
 ***********************************************************************
 * SYNOPSIS:	    Figure out how many relocations will need to be
 *	    	    performed at run-time for a segment.
 * CALLED BY:	    Pass1VM_Load
 * RETURN:	    0 on error, 1 if ok
 * SIDE EFFECTS:    The nrel field for the segment is modified
 *
 * STRATEGY:
 *	Relocations that make it to the output file:
 *	    - segment
 *	    - handle
 *	    - call
 *	    - offset for library entry
 *	All but the segment relocation cause the mustBeGeode flag to
 *	be set, since ms dos can't handle them.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/10/89	Initial Revision
 *
 ***********************************************************************/
static void
Pass1VMCountRels(const char *file,  /* Object file being loaded */
		 VMHandle   fh,	    /* Handle of same */
		 ObjSegment *s,	    /* Descriptor in object file for segment
				     * being dealt with now */
		 SegDesc    *sd,    /* Internal form of same */
		 ObjHeader  *hdr)   /* Header for object file */
{
    VMBlockHandle   cur, next;
    word    	    n;
    MemHandle	    mem;
    ObjRel  	    *rel;
    ObjRelHeader    *orh;

    for (cur = s->relHead; cur != 0; cur = next) {
	orh = (ObjRelHeader *)VMLock(fh, cur, &mem);

	n = orh->num;

	for (rel = (ObjRel *)(orh+1); n > 0; rel++, n--) {
	    switch(rel->type) {
		case OREL_LOW:
		case OREL_HIGH:
		case OREL_OFFSET:
		{
		    ObjSymHeader    *osh;
		    ObjSegment 	    *seg;

		    if (rel->symBlock == 0) {
			/*
			 * Local relocation, so not runtime.
			 */
			break;
		    }

		    osh = (ObjSymHeader *)VMLock(fh, rel->symBlock, NULL);
		    seg = (ObjSegment *)((genptr)hdr + osh->seg);

		    if (seg->type == SEG_GLOBAL) {
			/*
			 * Didn't know the segment of the beast before, so could
			 * be in a library and the user forgot the StartLibrary
			 * and EndLibrary. If that's the case, we'll generate
			 * too many runtime relocations in the second pass
			 * and corrupt our heap...Of course, this also means
			 * that if a developer is lazy and doesn't define the
			 * segments for his/her global symbols, we'll be doing
			 * this a lot, but we'd rather work slowly than not
			 * work at all....
			 */
			ID  	    	outID;
			SegDesc	    	*outSD;
			VMBlockHandle	outSymBlock;
			word	    	outSymOff;
			ObjSym	    	*os;

			os = (ObjSym *)((genptr)osh+rel->symOff);
			outID = ST_Dup(fh, os->name, symbols, strings);

			if (Sym_FindWithSegment(symbols, outID,
						&outSymBlock,
						&outSymOff,
						TRUE,
						&outSD))
			{
			    if (outSD->combine == SEG_LIBRARY) {
				mustBeGeode = 1;
				sd->nrel += 1;
			    }
			}
		    }

		    VMUnlock(fh, rel->symBlock);

		    if (seg->type == SEG_LIBRARY) {
			/*
			 * If segment containing symbol is a library,
			 * the runtime loader must handle it.
			 */
			mustBeGeode = 1;
			sd->nrel += 1;
		    }
		    break;
		}
		case OREL_RESID:
		case OREL_ENTRY:
		    /*
		     * This we can take care of
		     */
		    mustBeGeode = 1;
		    break;
		case OREL_HANDLE:
		    /*
		     * Either of these or an offset/call to a library segment
		     * means the thing we're making *must* be a Geode.
		     */
		    mustBeGeode = 1;
		    /*FALLTHRU*/
		case OREL_CALL:
		case OREL_SEGMENT:
		{
		    /*
		     * Figure frame and deal with relocations to absolute
		     * segments, which are permitted here and don't count
		     * as a runtime relocation.
		     */
		    SegDesc *frame=Obj_FindFrameVM((char *)file, fh, hdr, rel->frame);

		    if ((frame->type != S_SEGMENT) ||
			(frame->combine != SEG_ABSOLUTE))
		    {
			sd->nrel += 1;
			if (frame->type != S_GROUP && frame->combine == SEG_LIBRARY) {
			    mustBeGeode = 1;
			}
		    }
		    break;
		}
		case OREL_METHCALL:
		case OREL_SUPERCALL:
		    /*
		     * Assume the relocation will be needed -- we've no
		     * way to tell at this point.
		     */
		    sd->nrel += 1;
		    mustBeGeode = 1;
		    break;
	    }
	}
	/*
	 * Advance to next block of relocations.
	 */
	next = orh->next;
	VMUnlock(fh, cur);
    }
}
#ifdef OLDSEARCH
/*********************************************************************
 *			Pass1VMSeachAddrSyms
 *********************************************************************
 * SYNOPSIS: search for strings from the segment s in the symbol file
 * CALLED BY:	Pass1VM_FileIsNeeded
 * RETURN:  true if any symbols were found
 * SIDE EFFECTS:    none
 * STRATEGY:	brute force
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	5/29/92		Initial version
 * *********************************************************************/
static int
Pass1VMSearchAddrSyms(const char    *file,  	/* File name */
		      VMHandle      fh,     	/* Object file handle */
		      ObjSegment    *s)     	/* Segment descriptor in obj */
						/* file*/
{
    VMBlockHandle	next;	    /* Next symbol block */
    int	    	    	retval = 0; /* Assume not there */

    next = s->syms;

    if (next != 0) {
	ObjSymHeader    *osh;
	ObjSym      	*os;
	word	    	n;  	/* Number of symbols left in the block */
	MemHandle   	mem;	/* Handle of detached block */


	osh = (ObjSymHeader *)VMLock(fh, next, NULL);
	n = osh->num;
	os = (ObjSym *)(osh+1);

	if (!Obj_IsAddrSym(os)) {
	    /*
	     * Not one of the address-bearing types, or is one but it's
	     * undefined, so we've reached the end of the line. Unlock
	     * the block, set up our return values and return.
	     */
	    VMUnlock(fh, next);
	    return(retval);
	}

	/*
	 * for each string in the segment, search for it in the
	 * symbol file
	 */
	while (n > 0) {
	    if (os->type == OSYM_PROC) {
		  if (ST_DupNoEnter(fh, os->name, symbols, strings) != NullID){
		      retval = 1;
		  }
	    }
	    n--;
	    os++;
	}
	next = osh->next;
	VMUnlock(fh, next);
    }
    return(retval);
}
#endif

/*********************************************************************
 *			Pass1VMSeachForUndefinedSymbol
 *********************************************************************
 * SYNOPSIS: 	search for strings from the segment s in the symbol file
 * CALLED BY:	Pass1VM_FileIsNeeded
 * RETURN:  	true if any symbols were found
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	brute force
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	5/29/92		Initial version
 *
 *********************************************************************/
static Boolean
Pass1VMSearchForUndefinedSymbol(const char *file,  	/* File name */
				VMHandle      fh,     	/* Object file handle */
				VMBlockHandle fhStrings,/* String table for
							 * the file */
				ObjSegment    *s)    	/* Segment descriptor
							 * in obj file */
{
    Boolean    	    	retval = FALSE; /* Assume not there */
    SymUndef	    	*sup;

    for (sup = symUndefHead; sup != NULL && !retval; sup = sup->next) {
	ID  	supID;
	/*
	 * Look up the undefined symbol's name in the the object file's
	 * string table. If it's not there, neither can the symbol be.
	 */
	supID = ST_DupNoEnter(symbols, sup->sym.name, fh, fhStrings);

	if (supID != NullID) {
	    ObjSymHeader    *osh;
	    ObjSym          *os;
	    word	    n;	    /* Number of symbols left in the block */
	    VMBlockHandle   next;	    /* Next symbol block */
	    VMBlockHandle   cur;	    /* Current symbol block */


	    for (cur = s->syms; cur != 0 && !retval; cur = next) {
		osh = (ObjSymHeader *)VMLock(fh, cur, NULL);
		n = osh->num;
		os = (ObjSym *)(osh+1);

		if (!Obj_IsAddrSym(os))
		{
		    /*
		     * Not one of the address-bearing types, or is one but it's
		     * undefined, so we've reached the end of the line. Unlock
		     * the block, set up our return values and return.
		     */
		    VMUnlock(fh, cur);
		    break;
		}

		/*
		 * Look at each procedure symbol in the block, seeing if its
		 * name matches that of the undefined symbol.
		 */
		while (n > 0)
		{
		    /*
		     * only worry about procedures, global labels, and
		     * global variables.  ignore local variables and local
		     * labels and such
		     */
		    if ((os->flags & OSYM_GLOBAL) &&
			((os->type == OSYM_PROC) || os->type == OSYM_LABEL ||
			 (os->type == OSYM_VAR)) &&
			(os->name == supID))
		    {
			retval = TRUE;
			break;
		    }
		    n--, os++;
		}
		next = osh->next;
		VMUnlock(fh, cur);
	    }
	}
    }
    return(retval);
}


/*********************************************************************
 *			Pass1VM_FileIsNeeded
 *********************************************************************
 * SYNOPSIS: 	sees if any symbols from the file are needed (ie. they
 *	     	exist in the symbol file
 * CALLED BY:	EXTERNAL (LoadFileIfNeeded)
 * RETURN:  	true (non-zero) if file is needed
 * SIDE EFFECTS:
 *
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	5/29/92		Initial version
 *
 *********************************************************************/

Boolean
Pass1VM_FileIsNeeded(const char   *file,    /* file for errors */
		     void    *handle)	    /* File handle for access */
{
    VMHandle	    fh = (VMHandle)handle;
    int	    	    i;
    ObjSegment 	    *s;
    VMBlockHandle   map = VMGetMapBlock(fh);
    ObjHeader	    *hdr = (ObjHeader *)VMLock(fh, map, (MemHandle *)NULL);
    Boolean    	    isNeeded = FALSE;

    /*
     * go through each segment and see if any of the strings are in
     * the symbol file
     */
    for (i = hdr->numSeg, s = (ObjSegment *)(hdr+1);
	 i > 0;
	 i--, s++)
    {
			printf("EEE\n");
	if ((s->syms != 0) &&
	    Pass1VMSearchForUndefinedSymbol(file, fh, hdr->strings, s))
	{
		printf("EEE\n");
	    isNeeded = TRUE;
	    break;
	}
    }
    VMUnlock(fh, map);
    VMClose(fh);

		printf("EEE DONE\n");
    return (isNeeded);
}


/***********************************************************************
 *				Pass1VM_Load
 ***********************************************************************
 * SYNOPSIS:	    Load object code from a VM file
 * CALLED BY:	    Pass1_Load, Library_Link
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Lots.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 3/89	Initial Revision
 *
 ***********************************************************************/
void
Pass1VM_Load(const char     *file,  /* File name (for error messages) */
	     genptr	    handle)/* File handle for access */
{
    VMHandle	    fh = (VMHandle)handle;
    int	    	    i, j;
    ObjSegment 	    *s;
    ObjGroup   	    *g;
    VMBlockHandle   map = VMGetMapBlock(fh);
    ObjHeader	    *hdr = (ObjHeader *)VMLock(fh, map, (MemHandle *)NULL);
    SegDesc 	    **segs;

    segs = (SegDesc **)malloc(hdr->numSeg * sizeof(SegDesc *));

    /*
     * Add all the segments at once so when we're counting relocations,
     * we can actually make sure the relocation is for real, e.g. if its an
     * offset to a library segment, or if we need to see if the segment is
     * absolute.
     */
    for (i = hdr->numSeg, s = (ObjSegment *)(hdr+1), j = 0;
	 i > 0;
	 i--, s++, j++)
    {
	SegDesc	    	*sd;	    /* Internal description of segment */

	/*
	 * Add the segment to those already known. If there are conflicts
	 * between the parameters for the segment and those given in earlier
	 * declarations, Seg_AddSegment will complain and return NULL.
	 */
	segs[j] = sd = Seg_AddSegment((char *)file,
				      ST_Dup(fh, s->name, symbols, strings),
				      ST_Dup(fh, s->class, symbols, strings),
				      s->type,
				      s->align,
				      s->flags);
	if (sd &&
	    (sd->combine == SEG_LMEM) && (sd->size != 0) && (s->data != 0))
	{
	    Notify(NOTIFY_ERROR,
		  "data given in more than one object file for lmem segment %i",
		    sd->name);
	}
    }

    /*
     * Enter any groups and their component segments into the tables.
     */
    for (i = hdr->numGrp, g = (ObjGroup *)s;
	 i > 0;
	 i--, g = OBJ_NEXT_GROUP(g))
    {
	GroupDesc   *gd = Seg_AddGroup((char *)file,
				       ST_Dup(fh, g->name, symbols, strings));

	if (gd == NULL) {
	    continue;
	}

	/*
	 * The group descriptor contains the offsets to the segment descriptors
	 * w.r.t. the start of the map block for this file. We've stored the
	 * SegDesc pointers we got for each one in the "segs" local array,
	 * but we need now to map from ObjSegment offset to SegDesc *, which
	 * we do by subtracting the header size from the ObjSegment offset,
	 * yielding an offset into the ObjSegment array, and then dividing by
	 * the size of a ObjSegment, to get an index.
	 */
	for (j = 0; j < g->numSegs; j++) {
	    int	    s = (g->segs[j]-sizeof(ObjHeader))/sizeof(ObjSegment);

	    if (segs[s] != NULL) {
		Seg_EnterGroupMember((char *)file, gd, segs[s]);
	    }
	}
    }

    for (i = hdr->numSeg, s = (ObjSegment *)(hdr+1); i > 0; i--, s++) {
	SegDesc	    	*sd;	    /* Internal description of segment */
	word	    	reloc;	    /* Amount by which to relocate things.
				     * Based on the current size of the
				     * segment, which gives the offset into
				     * the segment at which the code from
				     * this file will be loaded */
	VMBlockHandle	next;	    /* Next symbol block */

	/*
	 * Find the segment in the table.
	 */
	sd = Seg_Find((char *)file,
		      ST_Dup(fh, s->name, symbols, strings),
		      ST_Dup(fh, s->class, symbols, strings));

	if (sd == NULL) {
	    /*
	     * Bogus segment.
	     */
	    continue;
	}

	if ((sd->combine == SEG_LMEM) && (sd->group->segs[0] == sd)) {
	    /*
	     * Header segment of lmem group. If the thing has data, see if the
	     * thing's an object block.
	     */
	    if (s->data != 0) {
		LMemBlockHeader	*lmbh =
		    (LMemBlockHeader *)VMLock(fh, s->data, (MemHandle *)NULL);

		if (swaps(lmbh->LMBH_lmemType) == LMEM_TYPE_OBJ_BLOCK) {
		    /*
		     * It's an object block. Mark it as such so various things
		     * are clear on it. (e.g. the Geo module will set
		     * HAF_OBJECT automatically).
		     */
		    sd->isObjSeg = 1;
		}
		VMUnlock(fh, s->data);
	    }
	}
	/*
	 * The nextOff of the segment is the relocation factor for all
	 * relocations done during this pass.
	 */
	if ((sd->combine != SEG_COMMON) && (sd->combine != SEG_ABSOLUTE)) {
	    reloc = sd->nextOff;
	} else {
	    reloc = 0;
	}

	/*
	 * Copy and relocate line number information from the object file
	 * to the symbol file.
	 */
	if ((s->lines != 0) && !Pass1VMRelLines(file, fh, s, sd, reloc)) {
	    continue;
	}

	/*
	 * Copy, relocate and enter symbols with addresses, and their
	 * compatriots.
	 */
	if ((s->syms != 0) && !Pass1VMRelAddrSyms(file, fh, s, sd, reloc,
						  &next))
	{
	    continue;
	}

	/*
	 * Copy, relocate and enter type symbols and undefined address-
	 * bearing symbols.
	 */
	if ((s->syms != 0) && (next != 0) && !Obj_EnterTypeSyms(file, fh, sd,
								next, 0))
	{
	    continue;
	}

	/*
	 * Count the number of run-time relocations that will be required.
	 * The check for SEG_LIBRARY is made to skip over published relocations
	 * in a .ldf file
	 */
/*
	if ((s->type != SEG_LIBRARY) && (s->relHead != 0)) {
	    Pass1VMCountRels(file, fh, s, sd, hdr);
	}
*/
	if (s->relHead != 0) {
	    Pass1VMCountRels(file, fh, s, sd, hdr);
	}

	if (s->type == SEG_ABSOLUTE) {
	    /*
	     * Absolute segments always use the pdata.frame value and it
	     * always contains the value from the header.
	     * XXX: error check between object files.
	     */
	    sd->pdata.frame = s->data;
	} else if (s->data) {
	    word    	size;

	    /*
	     * Pad the size out to the alignment boundary of the segment.
	     * Use sd->align, not s->align, to deal with segment aliases.
	     */
	    size = (s->size + sd->alignment) & ~sd->alignment;

	    /*
	     * Then include the thing in the internal segment descriptor.
	     */
	    if (sd->combine != SEG_COMMON) {
		sd->size += size;
	    } else if (size > sd->size) {
		sd->size = size;
	    }
	    if (sd->size > 65536) {
		Notify(NOTIFY_ERROR,
		       "%s: segment %i greater than 64K (now %d)",
		       file, sd->name, sd->size);
	    }
	}
    }

    VMUnlock(fh, map);
    VMClose(fh);

    free((char *)segs);
}
