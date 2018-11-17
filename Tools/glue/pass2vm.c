/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Pass2 for VM object files
 * FILE:	  pass2vm.c
 *
 * AUTHOR:  	  Adam de Boor: Nov 12, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Pass2VM_Load	    Load a VM Object file during pass 2
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/12/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Perform second-pass loading operations for a VM object file.
 *
 *	Performs fixups and copies segment data to the output buffer.
 *
 *	NOTE: the abbreviation "w.r.t." stands for "with respect to", a
 *	phrase often used when talking about relocations.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: pass2vm.c,v 3.25 96/07/08 17:30:23 tbradley Exp $";
#endif lint

#include    "glue.h"
#include    "obj.h"
#include    "output.h"
#include    "sym.h"
#include    "geode.h"
#include    "library.h"
#include    <config.h>
#include    <compat/stdlib.h>


/***********************************************************************
 *				Pass2VMCheckFixed
 ***********************************************************************
 * SYNOPSIS:	    If relocation demands to be to a fixed segment, make
 *	    	    sure this condition is met.
 * CALLED BY:	    Pass2VMHandleOffsetRel, Pass2VMHandleSegRel,
 *	    	    Pass2VMHandleMethCall
 * RETURN:	    non-zero if relocation is ok.
 * SIDE EFFECTS:    Error message is generated if relocation improper.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/18/89	Initial Revision
 *
 ***********************************************************************/
static int
Pass2VMCheckFixed(SegDesc   	*sd,	    /* Current segment */
		  ObjRel    	*rel,	    /* Relocation to check */
		  SegDesc   	*frame,	    /* Frame for relocation */
		  ObjSym    	*sym)	    /* Symbol involved */
{
    /*
     * If the relocation demands a fixed target and either the output module
     * declares the frame to not be fixed or the relocation is w.r.t. a symbol
     * in a library segment that we marked as movable in an earlier incarnation,
     * the relocation is in error and we bitch and return 0.
     */
    if (rel->fixed) {
	if (!(*fileOps->checkFixed)(frame) ||
	    (sym && (frame->type != S_GROUP) && 
	     (frame->combine == SEG_LIBRARY) &&
	     (sym->flags & OSYM_MOVABLE)))
	{
	    Pass2_RelocError(sd, rel->offset,
			     "target of relocation (%i) must be in fixed segment",
			     sym ? sym->name : NullID);
	    return(0);
	} else if (sym && (sym->type == OSYM_PROC) &&
		   (sym->u.proc.flags & OSYM_NO_JMP))
	{
	    Pass2_RelocError(sd, rel->offset,
			     "procedure %i may not be jumped to",
			     sym->name);
	    return(0);
	}
    }
    return(1);
}


/***********************************************************************
 *				Pass2VMRelOff
 ***********************************************************************
 * SYNOPSIS:	    Determine the offset for a relocation.
 * CALLED BY:	    Pass2VM_Load
 * RETURN:	    Relocated offset of the symbol and frame w.r.t. which
 *	    	    the offset was generated. Returns 0 if relocation is
 *	    	    in error.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/19/89	Initial Revision
 *
 ***********************************************************************/
static int
Pass2VMRelOff(SegDesc 	    *sd,    	    /* Segment in which relocation is
					     * to occur */
	      void  	    *data,  	    /* Base of data block for same */
	      ObjRel  	    *rel,	    /* Relocation data */
	      const char    *file,	    /* Name of object file */
	      VMHandle	    fh, 	    /* Object file */
	      ObjHeader	    *hdr,	    /* Header for same */
	      dword   	    *relocPtr,      /* Place to store relocation
					     * value */
	      SegDesc 	    **framePtr,     /* Place to store relocation
					     * frame */
	      SegDesc 	    **symSegPtr,    /* Place to store segment to which
					     * symbol belongs */
	      VMBlockHandle *symBlockPtr,   /* Place to store block in which
					     * the symbol resides */
	      word  	    *symOffPtr)	    /* Place to store offset in block
					     * in which the symbol resides */
{
    ObjSym	    	*sym;	    /* Symbol that's the target of the
				     * relocation */
    ObjSymHeader	*osh;	    /* Header of block containing same */
    dword   	    	reloc;	    /* Relocation value we're returning */
    SegDesc 	    	*frame;	    /* Descriptor for relocation frame */
    SegDesc 	    	*ssd;	    /* Descriptor for segment containing the
				     * symbol */
    ID	    	    	id;    	    /* Converted ID for search */
    VMBlockHandle   	symBlock;
    word    	    	symOff;
	
    /*
     * Find the relocation frame. It can be either a segment or a group...
     */
    frame = Obj_FindFrameVM(file, fh, hdr, rel->frame);
    
    /*
     * Deal with local-segment relocation, where there is no symbol w.r.t.
     * which to relocate the thing. Instead, the relocation value for the
     * segment piece is to be used. 
     */
    if (rel->symBlock == 0) {
	*framePtr = frame;
	*symSegPtr = sd;
	*relocPtr = sd->nextOff - sd->foff;
	/*
	 * If frame isn't the segment, add in the group offset too. NOTE:
	 * no need to check for unrelated frame as we trust the assembler...
	 */
	if (rel->type != OREL_LOW && rel->type != OREL_HIGH && frame != sd) {
	    pass2_assert((sd->group && sd->group->name == frame->name),
			 sd, rel->offset);
	    /*
	     * Use difference of foff's so we can safely set grpOff to zero
	     * when segments in a group are subsumed by the group itself,
	     * as happens for geodes and vm files, e.g.
	     */
	    *relocPtr += sd->foff - frame->foff;
	}
	*symBlockPtr = (VMBlockHandle)0;
	return(1);
    }

    /*
     * Start with a relocation value of 0 so we can incrementally add things.
     */
    reloc = 0;
    
    osh = (ObjSymHeader *)VMLock(fh, rel->symBlock, NULL);
    
    sym = (ObjSym *)((genptr)osh+rel->symOff);
    
    ssd = Obj_FindFrameVM(file, fh, hdr, osh->seg);

    if ((sym->flags & OSYM_UNDEF) || (sym->type == OSYM_PROTOMINOR)) {
	/*
	 * Need to find the actual global symbol for this thing. It should be
	 * in the same segment, but we need to handle the subsumption of
	 * segments into their groups by some output formats, as well as
	 * the assembler not having been told in which segment the symbol
	 * will reside.
	 */
	VMBlockHandle	table;  	/* Symbol table to search */
	ID  	    	frameName;  	/* Name of segment containing the
					 * table */

	/*
	 * Figure in which table to look.
	 */
	if (frame->type == S_GROUP) {
	    /*
	     * Relocating w.r.t. a group. Use the ObjSegment descriptor for the
	     * symbol to find the thing.
	     */
	    if (ssd->combine == SEG_GLOBAL) {
		/*
		 * Same reasoning applies as for frame being the global segment
		 */
		table = (VMBlockHandle)0;
		frameName = NullID;
	    } else {
		table = ssd->syms;
		frameName = ssd->name;
	    }
	} else if (frame->combine == SEG_GLOBAL) {
	    /*
	     * This one's even *more* fun! The symbol was declared global in
	     * the global segment, so we've no idea in which segment the
	     * thing is actually defined. Tell Sym_Find to look everywhere
	     * by setting table to be NULL. Note: we can't use ssd->syms b/c
	     * ssd will be the same as the frame for this object file.
	     */
	    table = (VMBlockHandle)0;
	    frameName = NullID;
	} else {
	    table = frame->syms;
	    frameName = frame->name;
	}
	
	id = ST_Dup(fh, sym->name, symbols, strings);
	
	if (!Sym_Find(symbols, table, id, &symBlock, &symOff, TRUE)) {
	    /*
	     * Can't find it -- complain.
	     */
	    if (frameName != NullID) {
		if ((frame->type != S_GROUP) && (frame->combine==SEG_LIBRARY)) {
		    if (sym->type == OSYM_PROTOMINOR && frame->alignment == 1) {
			/*
			 * Reference is to a protominor symbol being defined
			 * by the geode itself (as indicated by the segment's
			 * alignment being 1, not 0), so just ignore the
			 * reference.
			 */
			return(0);
		    } else {
			Pass2_RelocError(sd, rel->offset,
		         "%i undefined in library %i, perhaps you forgot to load it?", id, frameName);
		    }
		} else {
		    Pass2_RelocError(sd, rel->offset, "%i undefined in %i", id,
				     frameName);
		}
	    } else {
		Pass2_RelocError(sd, rel->offset, "%i undefined3", id);
	    }
	    return(0);
	} else if (ssd->combine == SEG_GLOBAL) {
	    /*
	     * Fetch the actual segment in which the thing is defined if
	     * this object file claims the thing is in the global segment,
	     * which is a preposterous assertion caused by having a global
	     * declaration outside any segment.
	     */
	    
	    VMBlockHandle   omap = VMGetMapBlock(symbols);

	    hdr = (ObjHeader *)VMLock(symbols, omap, NULL);
	    osh = (ObjSymHeader *)VMLock(symbols, symBlock, NULL);
	    ssd = Obj_FindFrameVM(file, symbols, hdr, osh->seg);
	    VMUnlock(symbols, symBlock);
	    VMUnlock(symbols, omap);
	}
    } else {
	/*
	 * Have to go locate the actual value since the segment may have
	 * already been processed, thus ssd->nextOff isn't a valid indicator
	 * of the relocation value used for the segment.
	 */
	id = ST_Dup(fh, sym->name, symbols, strings);

	if (!Sym_Find(symbols, ssd->syms, id, &symBlock, &symOff, FALSE)) {
	    Pass2_RelocError(sd, rel->offset, "%i undefined?!?!?!?", id);
	    return(0);
	}
    }
    
    /*
     * Lock down the real version, mark it as referenced, fetch
     * the address out, then unlock the block again.
     */
    osh = (ObjSymHeader *)VMLock(symbols, symBlock, NULL);
    sym = (ObjSym *)((genptr)osh+symOff);
    sym->flags |= OSYM_REF;

    /*
     * Let library module know we're using an entry point, if such it is.
     */
    if (ssd->combine == SEG_LIBRARY) {
	(void)Library_UseEntry(ssd, sym, TRUE, TRUE);
    }

    /*
     * Only fetch the address out if it's an address symbol.
     * XXX: Deal with global constants.
     */
    switch(sym->type) {
	case OSYM_VAR:
	case OSYM_CHUNK:
	case OSYM_PROTOMINOR:
	case OSYM_PROC:
	case OSYM_LABEL:
	case OSYM_CLASS:
	case OSYM_MASTER_CLASS:
	case OSYM_VARIANT_CLASS:
	    reloc = sym->u.addrSym.address;
	    break;
	default:
	    pass2_assert(0, sd, rel->offset);
    }
    *symBlockPtr = symBlock;
    *symOffPtr = symOff;
    
    if (frame != ssd) {
	/*
	 * Frame can only be the segment to which the symbol belongs or the
	 * group containing the segment. I have yet to see an intentional
	 * relocation w.r.t. an unrelated segment.
	 */
	if (frame->name == NullID) {
	    /*
	     * Relocation expected symbol to be in the global segment.
	     * This is the signal that the symbol's segment was unknown at
	     * assembly time. We declare the frame to be the segment's group,
	     * if any, or the segment itself, it not in a group.
	     */
	    if (ssd->group) {
		frame = (SegDesc *)ssd->group;
		/*
		 * Relocating w.r.t. a group. Add in the group offset for the
		 * segment. The file-specific preparation routine should
		 * already have checked for a group > 64K, so we don't have to.
		 * Note this only happens if the segment containing the symbol
		 * is actually a real segment; if it's a subsegment, its
		 * symbols have already been relocated w.r.t. to the group so
		 * we don't need to.
		 * We round the offset down to the nearest paragraph as any
		 * stuff we trim off should already have been added into the
		 * offset of all the symbols in the segment.
		 */
		if (ssd->type == S_SEGMENT) {
		    reloc += (ssd->foff - frame->foff) & ~0xf;
		}
	    } else {
		frame = ssd;
	    }
	} else if (!Obj_CheckRelated(frame, ssd)) {
	    Pass2_RelocError(sd, rel->offset,
		       "%i unrelated to %i: improper frame for relocation to %i",
		       frame->name, ssd->name, id);
	    VMUnlockDirty(symbols, symBlock);
	    VMUnlock(fh, rel->symBlock);
	    return(0);
	} else if (ssd->type == S_SEGMENT) {
	    /*
	     * Relocating w.r.t. a group. Add in the group offset for the
	     * segment. The file-specific preparation routine should already
	     * have checked for a group > 64K, so we don't have to. Note this
	     * only happens if the segment containing the symbol is actually a
	     * real segment; if it's a subsegment, its symbols have already
	     * been relocated w.r.t. to the group so we don't need to.
	     * We round the offset down to the nearest paragraph as any
	     * stuff we trim off should already have been added into the
	     * offset of all the symbols in the segment.
	     */
	    reloc += (ssd->foff - ssd->group->foff) & ~0xf;
	}
    }

    /*
     * If the relocation is pc-relative, make sure the target of the relocation
     * is in the same segment as the relocation itself.
     */
    if (rel->pcrel && !Obj_CheckRelated(frame, sd)) {
	Pass2_RelocError(sd, rel->offset,
			 "relative relocation to different segment (%i:%i)",
			 frame->name, id);
	VMUnlockDirty(symbols, symBlock);
	VMUnlock(fh, rel->symBlock);
	return(0);
    }

    /*
     * If relocation is a call relocation, as indicated either by the type
     * being OREL_CALL or the relocation being a pc-relative relocation with
     * the byte before it being the near call opcode (0xe8), and the destination
     * is a procedure that doesn't like to be called (like me in the early
     * morning :), complain to the authorities
     */
    if (((rel->type == OREL_CALL) ||
	 (rel->pcrel && (*((byte *)data+rel->offset-1) == 0xe8))) &&
	(sym->type == OSYM_PROC) &&
	(sym->u.proc.flags & OSYM_NO_CALL))
    {
	Pass2_RelocError(sd, rel->offset,
			 "procedure %i may not be called", sym->name);
	VMUnlockDirty(symbols, symBlock);
	VMUnlock(fh, rel->symBlock);
	return(0);
    }

    /*
     * Handle fixed relocations while we've got the target symbol here.
     */
    if (!Pass2VMCheckFixed(sd, rel, frame, sym)) {
	VMUnlockDirty(symbols, symBlock);
	VMUnlock(fh, rel->symBlock);
	return(0);
    }
    
    VMUnlockDirty(symbols, symBlock);

    /*
     * Done with the symbol, so unlock its block.
     */
    VMUnlock(fh, rel->symBlock);
    
    /*
     * Set return values.
     */
    *framePtr = frame;
    *symSegPtr = ssd;
    *relocPtr = reloc;

    return(1);
}

/***********************************************************************
 *				Pass2VMHandleEntryRel
 ***********************************************************************
 * SYNOPSIS:	    Deal with an entry point relocation.
 * CALLED BY:	    Pass2VM_Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The word at the relocation offset is filled with the
 *	    	    entry point number, either from its library or
 *	    	    for the geode being created.
 *
 * STRATEGY:
 *	    Look up the symbol in its segment. If the symbol is an
 *	    ENTRY, then accept its address. Else ask the Library module
 *	    to tell us what to use.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 6/89	Initial Revision
 *
 ***********************************************************************/
static void
Pass2VMHandleEntryRel(SegDesc 	*sd,	    /* Segment being operated on */
		      void    	*data,	    /* Base of data block */
		      const char *file,	    /* Object file name */
		      VMHandle	fh, 	    /* VM handle open to same */
		      ObjHeader	*hdr,	    /* Header from same */
		      ObjRel  	*rel)	    /* Relocation on which we're
					     * working */
{
    SegDesc 	    *frame; 	/* Relocation frame */
    ID	    	    id;	    	/* Name of symbol in output string table */
    ObjSym  	    *sym;   	/* Symbol we found */
    VMBlockHandle   block;  	/* Block in which it resides */
    word    	    offset; 	/* Offset in same */
    byte    	    *bp;    	/* Pointer for mangling segment data */
    word	    entry;  	/* Entry point number */
    VMBlockHandle   table;

    frame = Obj_FindFrameVM(file, fh, hdr, rel->frame);

    sym = (ObjSym *)((genptr)VMLock(fh, rel->symBlock, NULL)+rel->symOff);
    id = ST_Dup(fh, sym->name, symbols, strings);

    pass2_assert((frame->type != S_GROUP), sd, rel->offset);

    if (frame->combine == SEG_GLOBAL) {
	/*
	 * Search everywhere if Esp thought the thing was in the global segment
	 */
	table = (VMBlockHandle)0;
    } else {
	table = frame->syms;
    }
    
    if (!Sym_Find(symbols, table, id, &block, &offset, TRUE)) {
	Pass2_RelocError(sd, rel->offset, "%i not in %i",
			 id, frame->name);
	return;
    }

    sym = (ObjSym *)((genptr)VMLock(symbols, block, NULL)+offset);
    sym->flags |= OSYM_REF;

    bp = (byte *)data+rel->offset;
    if (sym->flags & OSYM_ENTRY) {
	assert(frame->combine == SEG_LIBRARY);
	(void)Library_UseEntry(frame, sym, TRUE, TRUE);

	entry = sym->u.addrSym.address;
    } else {

	if (!Library_Find(id, &entry)) {
	    Pass2_RelocError(sd, rel->offset, "%i not exported in geode's .gp file", id);
	    entry = 0;
	} 
    }

    VMUnlockDirty(symbols, block);
    entry += *bp | (bp[1] << 8);
    
    *bp++ = entry;
    *bp = entry >> 8;
}
	

/***********************************************************************
 *				Pass2VMHandleMethCall
 ***********************************************************************
 * SYNOPSIS:	    Resolve a CALL relocation, dealing with static
 *	    	    method calls.
 * CALLED BY:	    Pass2VMHandleOffRel
 * RETURN:	    0 if error, non-zero if ok.
 * SIDE EFFECTS:    *framePtr, *ssdPtr, *relocPtr will have been modified
 *	    	    on successful return if call was a static method call.
 *	    	    Otherwise, they are unchanged.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/12/89	Initial Revision
 *
 ***********************************************************************/
static int
Pass2VMHandleMethCall(SegDesc 	*sd,	    /* Segment being operated on */
		      void    	*data,	    /* Base of data block */
		      const char *file,	    /* Object file name */
		      VMHandle	fh, 	    /* VM handle open to same */
		      ObjHeader	*hdr,	    /* Header from same */
		      ObjRel  	*rel,	    /* Relocation on which we're
					     * working */
		      void    	*nextRel)   /* Next runtime relocation, if
					     * need to call maprel */
{
    SegDesc	    *frame;	/* Relocation frame */
    dword	    reloc;	/* Relocation value */
    SegDesc	    *ssd;	/* Segment in which relocation's symbol
				 * resides */
    byte	    *bp;    	/* Pointer for modifying the segment
				 * data */
    VMBlockHandle   symBlock;  	/* Block in which relocation symbol
				 * resides. Used for CALL relocations
				 * only */
    word    	    symOff;    	/* Offset of symbol in same */
    ObjSym	    *sym;
    void	    *base;
    ID	    	    method;
    ObjSym  	    *csym;  	/* Class symbol */
    ObjSym  	    *bsym;  	/* Binding symbol */
    VMBlockHandle   psymBlock;	/* Block... */
    word    	    psymOff;	/*  and offset for bound procedure */
    ObjSym  	    *psym;  	/* Procedure symbol */
    ObjSymHeader    *osh;   	/* Header of block containing procedure
				 * so we can determine its segment */
    ObjSegment 	    *s;	    	/* External descriptor for procedure's
				 * segment */
    VMBlockHandle   smap;   	/* Map block for symbols file */
    ObjHeader       *shdr;  	/* Header for symbols file */
    ObjSym 	    *defBind;  	/* Default binding, if any given */
    ID  	    omethod;   	/* ID from object file */
    ID	    	    proc;   	/* Procedure to use */
    /*
     * Alternatives should a static call be found not feasible. The array
     * is indexed by rel->type-OREL_METHCALL.
     */
    static struct {
	char	    	*name;
	VMBlockHandle	block;
	word	    	offset;
    }	    	    altProcs[] = {
	{"ObjCallInstanceNoLock",    0,	0},
	{"ObjCallSuperNoLock", 	    0,	0}
    };
    

    if (fileOps->flags & FILE_NOCALL) {
	Pass2_RelocError(sd, rel->offset,
			 "output format can't handle static method calls");
	return(0);
    }
    
    proc = NullID;
    
    /*
     * Locate the class symbol involved. Easiest if we just use
     * Pass2VMRelOff, even though it does a bit more work than we need.
     */
    if (!Pass2VMRelOff(sd, data, rel, file, fh, hdr, &reloc, &frame, &ssd,
		       &symBlock, &symOff))
    {
	return(0);
    }
    
    bp = (byte *)data + rel->offset;
    
    base = VMLock(symbols, symBlock, (MemHandle *)NULL);
    sym = (ObjSym *)((genptr)base+symOff);

    /*
     * Make sure the target of the call is actually a class symbol.
     */
    if ((sym->type != OSYM_CLASS) &&
	(sym->type != OSYM_MASTER_CLASS) &&
	(sym->type != OSYM_VARIANT_CLASS))
    {
	Pass2_RelocError(sd, rel->offset,
			 "target for static method call (%i) not a class",
			 sym->name);
	return(0);
    }

    /*
     * First fetch the ID from the datum being relocated, then look the
     * thing up in the output file. Do NOT use autoincrement on bp --
     * order of evaluation isn't guaranteed.
     */
    omethod = (ID)(*bp | (bp[1] << 8) | (bp[2] << 16) | (bp[3] << 24));
    method = ST_Dup(fh, omethod, symbols, strings);
    
    defBind = NULL;
    
    /*
     * Make sure the method exists.
     */
    if (method == NullID) {
	//VMHandle	oidfile = UtilGetIDFile();
	
	//UtilSetIDFile(fh);
	Pass2_RelocError(sd, rel->offset,
			 "cannot resolve static method call: method %i not found",
			 omethod);
	//UtilSetIDFile(oidfile);
	VMUnlock(symbols, symBlock);
	return(0);
    }
    
    /*
     * Now work our way up the class tree, searching the binding list
     * for each class until we find one that fields the method
     * in question, or until we find we cannot continue, for any of
     * a variety of reasons.
     */
    csym = sym;
    
    while (1) {
	ID  	super;	    /* Name of super class, if needed */
	
	/*
	 * Search the binding list of the current class.
	 * XXX: What if there are no bindings for a class? Kind of a pointless
	 * class, true, but...
	 */
	bsym = csym+1;
	while (bsym->type == OSYM_BINDING) {
	    if (bsym->name == method) {
		break;
	    } else {
		if (bsym->name == NullID) {
		    defBind = bsym;
		}
		if (bsym->u.binding.isLast) {
		    break;
		} else {
		    bsym++;
		}
	    }
	}
	
	if (bsym->name == method) {
	    /*
	     * Got it -- move on to phase 3...
	     */
	    break;
	} else if (defBind) {
	    /*
	     * Use default binding if given. Remember: a static call is
	     * supposed to be the same as a dynamic one, just faster.
	     */
	    bsym = defBind;
	    break;
	}
	
	/*
	 * Try and go up a level in the class hierarchy
	 */
	super = OBJ_FETCH_SID(csym->u.class.super);
	
	if (csym->type == OSYM_VARIANT_CLASS) {
	    /*
	     * Don't know what the real superclass is, so cannot resolve
	     * through a variant class.
	     */
	    bsym = NULL;
	    break;
	} else if (super == NullID) {
	    /*
	     * Hit the top of the tree w/o finding someone to handle the
	     * method -- cannot resolve. This is a fun case, however, as
	     * it means that were we to put in the proper kernel call,
	     * the call would do nothing. This is silly. Instead, we fill
	     * in the five bytes with instructions that set things up
	     * as if the method hadn't been handled (carry and AX both
	     * clear), then we warn the user we've done this.
	     *
	     * One might argue that this voids the chance of a library
	     * changing and actually fielding the message. However, in such
	     * a case, the protocol number of the library should change and
	     * this thing wouldn't load anyway.
	     */
	    bp[-1] = 0xf8;  /* CLC */
	    *bp++ = 0x33;   /* XOR rw,ew */
	    *bp++ = 0xc0;   /* AX, AX */
	    *bp++ = 0x89;   /* MOV ew,rw */
	    *bp++ = 0xc0;   /* AX, AX */
	    Pass2_RelocWarning(sd, rel->offset,
			       "%i not handled by %i or its superclasses: call deleted",
			       method, sym->name);
	    VMUnlock(symbols, symBlock);
	    /*
	     * No relocation needed for this puppy, but we had to count it on
	     * the first pass.
	     */
	    sd->nrel -= 1;
	    return(0);
	}
	VMUnlock(symbols, symBlock);
	
	/*
	 * Look for the symbol describing the superclass.
	 */
	if (!Sym_Find(symbols, (VMBlockHandle)0, super, &symBlock, &symOff,
		      TRUE))
	{
	    Pass2_RelocError(sd, rel->offset,
			     "cannot resolve static method call: class %i not found",
			     super);
	    return(0);
	}
	
	/*
	 * Make sure the thing we found is actually a class, pointing csym
	 * and base at it in case it is.
	 */
	base = VMLock(symbols, symBlock, (MemHandle *)NULL);
	csym = (ObjSym *)((genptr)base+symOff);
	if ((csym->type != OSYM_CLASS) &&
	    (csym->type != OSYM_MASTER_CLASS) &&
	    (csym->type != OSYM_VARIANT_CLASS))
	{
	    Pass2_RelocError(sd, rel->offset,
			     "cannot resolve static method call: %i is not a class",
			     super);
	    VMUnlock(symbols, symBlock);
	    return(0);
	}
    }
    
    /*
     * bsym may now point to the binding to use. If it's null, it implies we
     * should just use the kernel routine because the method may not be
     * called staticly.
     */
    psymBlock = (VMBlockHandle)NULL;
    if ((bsym != NULL) && (bsym->u.binding.callType >= OSYM_STATIC)) {
	proc = OBJ_FETCH_SID(bsym->u.binding.proc);
	
	/*
	 * See if the procedure we've decided on is known in these parts.
	 * NOTE: The procedure does *not* have to be global (in fact, We'd
	 * prefer if it isn't....data abstraction and all that).
	 */
	if (!Sym_Find(symbols, (VMBlockHandle)0, proc, &psymBlock, &psymOff,
		      FALSE))
      	{
	    proc = NullID;
	}
    } else {
	proc = NullID;
    }

    /*
     * If proc is null, we want to find the kernel routine. If we've never
     * looked the thing up before, do so now and record the ID.
     */
    if (proc == NullID) {
	if (altProcs[rel->type - OREL_METHCALL].block == 0) {
	    proc = ST_LookupNoLen(symbols, strings,
				  altProcs[rel->type - OREL_METHCALL].name);
	    if (proc == NullID) {
		Pass2_RelocError(sd, rel->offset,
				 "cannot resolve static method call: %s is not defined",
				 altProcs[rel->type - OREL_METHCALL].name);
		VMUnlock(symbols, symBlock);
		return(0);
	    }
	    if (!Sym_Find(symbols, (VMBlockHandle)0, proc,
			  &altProcs[rel->type - OREL_METHCALL].block,
			  &altProcs[rel->type - OREL_METHCALL].offset,
			  FALSE))
	    {
		Pass2_RelocError(sd, rel->offset,
				 "cannot resolve static method call: %i is not defined",
				 proc);
		VMUnlock(symbols, symBlock);
		return(0);
	    }
	}
	psymBlock = altProcs[rel->type - OREL_METHCALL].block;
	psymOff = altProcs[rel->type - OREL_METHCALL].offset;
    }

    
    osh = (ObjSymHeader *)VMLock(symbols, psymBlock,(MemHandle *)NULL);
    psym = (ObjSym *)((genptr)osh+psymOff);
    
    if (psym->type != OSYM_PROC) {
	Pass2_RelocError(sd, rel->offset,
			 "cannot resolve static method call: %i is not a procedure",
			 psym->name);
	VMUnlock(symbols, psymBlock);
	VMUnlock(symbols, symBlock);
	return(0);
    }
    
    /*
     * Figure the segment in which the routine is defined.
     *
     * This takes advantage of the knowledge that we must be
     * creating a geode so all segments in groups have been subsumed
     * with the attendant alteration of the osh->seg fields of all
     * involved symbol blocks. The upshot of this is we needn't
     * worry about group offsets or similar dreck.
     */
    smap = VMGetMapBlock(symbols);
    shdr = (ObjHeader *)VMLock(symbols, smap, (MemHandle *)NULL);
    
    s = (ObjSegment *)((genptr)shdr+osh->seg);
    frame = Seg_Find("", s->name, s->class);

    VMUnlock(symbols, smap);
    VMUnlock(symbols, symBlock);

    if (!Pass2VMCheckFixed(sd, rel, frame, psym)) {
	return(0);
    }

    /*
     * Now perform the relocation, transforming any call into the same segment
     * into a CallFN followed by a NOP to avoid the kernel relocation that
     * might get transformed into a software interrupt.
     */
    if (frame == sd) {
	reloc = psym->u.proc.address - (rel->offset+(sd->nextOff-sd->foff)+3);

	bp[-1] = 0x0e;	/* PUSH CS */
	*bp++ = 0xe8;	/* CALL NEAR PTR */
	*bp++ = reloc;
	*bp++ = reloc >> 8;
	*bp = 0x90;

	sd->nrel -= 1;	/* One fewer runtime relocation */
	VMUnlock(symbols, psymBlock);
	return(0);
    } else {
	*bp = psym->u.proc.address;
	bp[1] = psym->u.proc.address >> 8;

	VMUnlock(symbols, psymBlock);
	
	if ((*fileOps->maprel)(OREL_CALL, frame, nextRel, sd, rel->offset,
			       (word *)bp))
	{
	    return(1);
	}
    }
    
    return(0);
}

/***********************************************************************
 *				Pass2VMHandleOffRel
 ***********************************************************************
 * SYNOPSIS:	    Deal with a relocation involving an offset. This
 *	    	    includes OREL_CALL, OREL_OFFSET, OREL_HIGH, OREL_LOW
 * CALLED BY:	    Pass2VMLoad
 * RETURN:	    1 if had to enter a runtime relocation, 0 otherwise
 * SIDE EFFECTS:    data at relocation offset modified.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/12/89	Initial Revision
 *
 ***********************************************************************/
static int
Pass2VMHandleOffRel(SegDesc 	*sd,	    /* Segment being operated on */
		    void    	*data,	    /* Base of data block */
		    const char 	*file,	    /* Object file name */
		    VMHandle	fh, 	    /* VM handle open to same */
		    ObjHeader	*hdr,	    /* Header from same */
		    ObjRel  	*rel,	    /* Relocation on which we're
					     * working */
		    void    	*nextRel)   /* Next runtime relocation, if
					     * need to call maprel */
{
    SegDesc	    	*frame;	    /* Relocation frame */
    dword	    	reloc;	    /* Relocation value */
    SegDesc	    	*ssd;	    /* Segment in which relocation's symbol
				     * resides */
    byte	    	*bp;	    /* Pointer for modifying the segment
				     * data */
    VMBlockHandle   	symBlock;   /* Block in which relocation symbol
				     * resides. Used for CALL relocations
				     * only */
    word    	    	symOff;	    /* Offset of symbol in same */
    word    	    	reloff;

    reloff = 0;			/* Be quiet, GCC (used only if rel->pcrel
				 * [which doesn't change] and set then) */

    /*
     * For offset relocations, we need to find the symbol w.r.t. which the
     * relocation is to take place.
     */
    if (!Pass2VMRelOff(sd, data, rel, file, fh, hdr, &reloc, &frame, &ssd,
		       &symBlock, &symOff))
    {
	return(0);
    }
    
    bp = (byte *)data + rel->offset;
    
    if (rel->pcrel) {
	reloff = rel->offset + (sd->nextOff - sd->foff);

	if (frame != ssd && frame == (SegDesc *)sd->group) {
	    reloff += sd->foff - frame->foff;
	}
    }

    /*
     * Add in the value already in the segment. If the relocation is
     * pc-relative, we take the PC to be just after the relocation. Note we
     * do have to relocate the offset of the relocation to get the PC
     * by adding in sd->nextOff first.
     */
    switch(rel->size) {
	case OREL_SIZE_BYTE:
	    /*
	     * Add in the value SIGN EXTENDED to handle HIGH and LOW
	     * relocations
	     */
	    reloc += *(char *)bp;
	    
	    if (rel->pcrel) {
		reloc -= reloff + 1;
	    }
	    break;
	case OREL_SIZE_WORD:
	    reloc += *bp | (bp[1] << 8) |
		(((bp[1] & 0x80) ? -1 : 0) & ~0xffff);
	    
	    if (rel->pcrel) {
		reloc -= reloff + 2;
	    }
	    break;
	case OREL_SIZE_DWORD:
	    reloc += *bp | (bp[1] << 8) |
		(bp[2] << 16) | (bp[3] << 24);
	    
	    if (rel->pcrel) {
		reloc -= reloff + 4;
	    }
	    break;
    }
    
    /*
     * If relocation is a call to the same segment, transform it into a
     * CallFN followed by a nop. This is actually a bit slower than a regular
     * call and doesn't have the advantage of saving a byte that doing this in
     * the assembler has. However, it does prevent the kernel from transforming
     * the thing into a 700-cycle software interrupt, which is always good.
     */
    if ((rel->type == OREL_CALL) && (frame == sd)) {
	/*
	 * Transform the instruction to a CallFN with a trailing NOP.
	 * This means one fewer runtime relocation, but there's not
	 * much we can do about it... Note that bp points past the
	 * far call opcode, so we need to use bp[-1] to modify it.
	 *
	 * We place the nop after the call as it's best to have a short
	 * instruction following the call on a 286, where a return takes
	 * 15+m cycles, m being the length of the instruction immediately
	 * following.
	 */
	reloc -= rel->offset + (sd->nextOff - sd->foff) + 3;
	bp[-1] = 0x0e;		/* PUSH CS */

	*bp++ = 0xe8;		/* CALL NEAR PTR */
	*bp++ = reloc;
	*bp++ = reloc >> 8;

	*bp = 0x90;		/* NOP */
	sd->nrel -= 1;		/* One fewer runtime relocation */
	return(0);		/* We didn't store a runtime relocation */
    }
	       
    /*
     * Now have final value to store in reloc. Do so.
     */
    if ((rel->type == OREL_OFFSET) || (rel->type == OREL_CALL)) {
	switch(rel->size) {
	    case OREL_SIZE_BYTE: /* XXX: Happens? */
		*bp = reloc;
		if ((reloc & ~0xff) && ((reloc & ~0x7f) != ~0x7f)) {
		    Pass2_RelocError(sd, rel->offset,
				     "value %d (%#x) too large for byte",
				     reloc, reloc);
		}
		break;
	    case OREL_SIZE_WORD:
		*bp++ = reloc;
		*bp = reloc >> 8;
		/*
		 * We exempt pc-relative relocations from this test b/c there
		 * are times when we need to use a "forward" offset to force
		 * the CPU to wrap around the 64K segment so we can reach all
		 * parts of the segment. E.g. if we've got a call at offset
		 * c000h to something at offset 0, we have to use a forward
		 * displacement of 4000h, rather than a backward displacement
		 * of c000h (which is impossible).
		 */
		if (!rel->pcrel && (reloc & ~0xffff) &&
		    ((reloc & ~0x7fff) != ~0x7fff))
		{
		    Pass2_RelocError(sd, rel->offset,
				     "value %d (%#x) too large for word",
				     reloc, reloc);
		}
		break;
	    case OREL_SIZE_DWORD:
		*bp++ = reloc;
		*bp++ = reloc >> 8;
		*bp++ = reloc >> 16;
		*bp = reloc >> 24;
		break;
	}
    } else if (rel->type == OREL_LOW) {
	if (symBlock == 0) {
	    if (fileOps->flags & FILE_PROTO_RELS) {
		Out_RegisterFinalProtoRel(FALSE,
					  sd->nextOff + rel->offset,
					  frame);
	    } else {
		Pass2_RelocError(sd, rel->offset,
				 "protocol number relocations not supported by output format");
	    }
	} else {
	    *bp = reloc;
	}
    } else if (rel->type == OREL_HIGH) {
	if (symBlock == 0) {
	    if (fileOps->flags & FILE_PROTO_RELS) {
		Out_RegisterFinalProtoRel(TRUE,
					  sd->nextOff + rel->offset,
					  frame);
	    } else {
		Pass2_RelocError(sd, rel->offset,
				 "protocol number relocations not supported by output format");
	    }
	} else {
	    *bp = reloc >> 8;
	}
    }
    
    /*
     * If we're working on a CALL relocation, and the output file doesn't do
     * anything special with them, we need to enter a segment relocation for
     * the second word.
     */
    if ((rel->type == OREL_CALL) && (fileOps->flags & FILE_NOCALL)) {
	if ((*fileOps->maprel)(OREL_SEGMENT, frame, nextRel, sd, rel->offset+2,
			       (word *)((genptr)data+rel->offset+2)))
	{
	    return(1);
	}
    } else if ((rel->type == OREL_CALL) ||
	       ((rel->type == OREL_OFFSET) &&
	        (frame->type != S_GROUP) &&
	        (frame->combine == SEG_LIBRARY)))
    {
	/*
	 * Call for an output file with runtime call relocations, or an offset
	 * to something in a library segment -- call the maprel procedure
	 * for the output file. This allows us to pass the value for the
	 * symbol in the data buffer.
	 */
	if ((*fileOps->maprel)(rel->type, frame, nextRel, sd, rel->offset,
			       (word *)((genptr)data+rel->offset)))
	{
	    return(1);
	}
    }
    return(0);
}

/***********************************************************************
 *				Pass2VMHandleSegRel
 ***********************************************************************
 * SYNOPSIS:	    Handle a relocation referring to a segment/block,
 *	    	    rather than a symbol.
 * CALLED BY:	    Pass2VM_Load
 * RETURN:	    non-zero if added a runtime relocation to the table
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/12/89	Initial Revision
 *
 ***********************************************************************/
static int
Pass2VMHandleSegRel(SegDesc 	*sd,	    /* Segment being operated on */
		    void    	*data,	    /* Base of data block */
		    const char 	*file,	    /* Object file name */
		    VMHandle	fh, 	    /* VM handle open to same */
		    ObjHeader	*hdr,	    /* Header from same */
		    ObjRel  	*rel,	    /* Relocation on which we're
					     * working */
		    void    	*nextRel)   /* Next runtime relocation, if
					     * need to call maprel */
{
    SegDesc	    *frame;	/* Relocation frame */
    SegDesc	    *ssd;	/* Segment in which any symbol we use is
				 * defined */
    VMBlockHandle   symBlock;
    word    	    symOff;
    dword   	    reloc;  	/* Relocation value from Pass2VMRelOff */

    /*
     * What we're after here is the relocation frame. If a symbol is given in
     * the relocation (symBlock is non-null) we want to get its frame (using
     * Pass2VMRelOff as that's easiest). This allows us to properly obtain the
     * segment/handle/resid of a symbol whose actual segment wasn't known at
     * compile time.
     */
    if (rel->symBlock == 0) {
	byte    *bp = (byte *)data+rel->offset;
	/*
	 * Only thing of interest here is the frame, which
	 * can be either a segment or a group.
	 */
	frame = Obj_FindFrameVM(file, fh, hdr, rel->frame);
	/*
	 * Special case for handle relocation. When getting the handle of a
	 * library segment, we want to provide the handle of the library, not
	 * of one of its entry points. To inform the kernel of this, we store
	 * -1 at the relocation point if the relocation type is OREL_HANDLE
	 * (the kernel never adds anything to the location either, so it
	 * doesn't matter if we modify it).
	 */
	if ((rel->type == OREL_HANDLE) && (frame->combine == SEG_LIBRARY)) {
	    *bp++ = 0xff;
	    *bp = 0xff;
	}
	if (!Pass2VMCheckFixed(sd, rel, frame, NULL)) {
	    return(0);
	}
    } else if (!Pass2VMRelOff(sd, data, rel, file, fh, hdr, &reloc,
			      &frame, &ssd, &symBlock, &symOff))
    {
	return(0);
    } else if (rel->type != OREL_RESID) {
	/*
	 * Store in whatever value we got back in case
	 * the maprel function needs to know the offset
	 * of the symbol involved.
	 */
	byte    *bp = (byte *)data+rel->offset;
	
	*bp++ = reloc;
	*bp = reloc >> 8;
    }
    
    if ((*fileOps->maprel)(rel->type, frame, nextRel, sd, rel->offset,
			   (word *)((genptr)data+rel->offset)))
    {
	return(1);
    }
    return(0);
}

/***********************************************************************
 *				Pass2VM_Load
 ***********************************************************************
 * SYNOPSIS:	    Load object code from a VM-format object file
 * CALLED BY:	    Pass2_Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    File is closed. Data copied to output buffer. etc.
 *
 * STRATEGY:
 *	Foreach segment:
 *	    Find SegDesc for it.
 *	    Lock data block.
 *	    malloc/alloca buffer for runtime relocations, using
 *	    	fileOps->rtrelsize and the nrel field in the segment
 *	    	descriptor.
 *	    foreach block of relocations:
 *	    	foreach relocation:
 *	    	    find segment descriptors and target symbol.
 *	    	    if (offset to library, or runtime relocation)
 *	    	    	call maprel function and up rtrel ptr.
 *	    	    else
 *	    	    	perform relocation
 *	    output data block at current file offset for the segment,
 *	    	adjusting the offset to compensate.
 *	    output relocation block at current rel offset for the segment,
 *	    	adjusting the offset to compensate.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/18/89	Initial Revision
 *
 ***********************************************************************/
void
Pass2VM_Load(const char *file,	/* File name (for error messages) */
	     genptr   	handle)/* File handle for access */
{
    VMHandle	    fh = (VMHandle)handle;
    int	    	    i;
    ObjSegment 	    *s;
    int	    	    grpOff; 	/* Offset of first group descriptor in map */
    ObjHeader	    *hdr;   	/* Header block for file */
    VMBlockHandle   map;    	/* Block handle of same */
    VMBlockHandle   block;      /* Block handle for searching through the
				 * symbols whilst looking for published
				 * routines */
    word            memSize;
    ObjSymHeader    *symHdr;
    ObjSym  	    *sym;       /* ObjSym for use whilst looking for
				 * published routines */

    map = VMGetMapBlock(fh);
    hdr = (ObjHeader *)VMLock(fh, map, (MemHandle *)NULL);

    /*
     * Figure offset of first group descriptor so we can quickly
     * decide if something is being relocated w.r.t. a segment or a group.
     */
    grpOff = (hdr->numSeg * sizeof(ObjSegment)) + sizeof(ObjHeader);

    for (i = hdr->numSeg, s = (ObjSegment *)(hdr+1); i > 0; i--, s++) {
	SegDesc	    	*sd;	    /* Descriptor for current segment */
	MemHandle   	mem;	    /* Mem handle for finding size of segment
				     * piece */
	void	    	*data;	    /* Address of current segment piece */
	VMBlockHandle   cur;	    /* Handle of current relocation block */
	VMBlockHandle	next;	    /* Handle of next relocation block */
	ObjRel  	*rel;	    /* Relocation being performed */
	word    	n;  	    /* MemInfo parameter to fetch size */
	MemHandle	rmem;	    /* Mem handle for determining number of
				     * relocations in the current block */
	ObjRelHeader   	*orh;	    /* Base of relocation block */
	void	    	*rbase;	    /* Base of runtime relocation block */
	void	    	*nextRel;   /* Pointer to next runtime relocation */
	
	if ((s->data == 0) || (s->type == SEG_ABSOLUTE)) {

	    /*
	     * If the segment has no data, it can't have any relocations,
	     * now can it? So there's nothing to do here.
	     */
	    if (s->relHead == 0) {
		continue;
	    } else {
		/*
		 * a non-zero relHead, the it must be the segment containing
		 * only protominor relocations.
		 */
		sd = Obj_FindFrameVM(file, fh, hdr, (genptr)s-(genptr)hdr);
	    }
	} else {

	    sd = Obj_FindFrameVM(file, fh, hdr, (genptr)s-(genptr)hdr);

	    if (sd->combine == SEG_LIBRARY) {
		continue;
	    }
	}


	/*
	 * Lock the data block down. We'll modify it in-place, but not mark
	 * the thing as dirty. Since the block is locked, it won't be
	 * thrown out. Since it's not dirty, the file won't be modified.
	 * Need the memory handle to get the size for the final transfer.
	 */

	if (s->data != 0) {
	    data = VMLock(fh, s->data, &mem);
	} else {
	    data = 0;
	}

	/*
	 * If output module has requested that data not be copied, skip this
	 * segment. Any data that are non-zero (indicated both by actual
	 * non-zero data and by any relocations) are taken to be an error,
	 * as the program cannot possibly function correctly.
	 */
	if (sd->nodata) {
	    /* CHECK FOR NON_ZERO VALUES */
	    long    	*lp;
	    long    	l;
	    byte    	*bp;

	    MemInfo(mem, (genptr *)&lp, &n);

	    /*
	     * We assume any data block is going to be longword
	     * aligned, on those machines that care. This is a safe assumption
	     * since the block is dynamically allocated and malloc returns
	     * things longword aligned (or doubleword aligned on a sparc). It
	     * may be more efficient on a PC to use words, though...
	     */
	    l = 0;
	    while (n >= 4) {
		l |= *lp++;
		n -= 4;
	    }
	    bp = (byte *)lp;
	    while (n > 0) {
		l |= *bp++;
		n--;
	    }

	    if ((l != 0) || (s->relHead != 0)) {
		Notify(NOTIFY_ERROR,
		       "%s: uninitialized segment %i contains non-zero data",
		       file, sd->name);
	    }
	    VMUnlock(fh, s->data);
	    continue;
	}

	/*
	 * Assume all the runtime relocations are in this piece, allocating
	 * a block big enough to hold all of them...
	 */
	if ((sd->nrel != 0) && (fileOps->rtrelsize != 0)) {
	    rbase = nextRel = (void *)malloc(sd->nrel * fileOps->rtrelsize);
	} else {
	    rbase = nextRel = NULL;
	}

	for (block = s->syms; block != 0; block = next) {
	    symHdr = (ObjSymHeader *)VMLock(fh, block, (MemHandle *)NULL);
	    MemInfo(mem, (genptr *)NULL, &memSize);

	    n = symHdr->num;

	    for (sym = (ObjSym *)(symHdr+1); n > 0; sym++, n--) {
		if (sym->type == OSYM_PROC) {
		    ObjSym           *symSym;
		    ID               symID;
		    VMBlockHandle    symBlock;
		    word             symOff;
		    SegDesc          *symSegDesc;
		    ObjSymHeader     *osh;

		    symID =  ST_DupNoEnter(fh, sym->name, symbols, strings);

		    if (Sym_FindWithSegment(symbols, symID, &symBlock, &symOff, TRUE, &symSegDesc)) {
			osh = (ObjSymHeader *)VMLock(symbols, symBlock, (MemHandle *) NULL);
			symSym = (ObjSym *)((genptr)osh+symOff);

			if (symSym->u.proc.flags & OSYM_PROC_PUBLISHED) {
			    ObjSym    *nextSym;
			    word      symsLeft;    /* The number of symbols
						    * left in the current block
						    * while looking for the
						    * next routine.
						    */

			    /*
			     * Publish this routine. We have to let the .ldf
			     * file know how long the routine is, so we'll
			     * calculate that value by looking for the next
			     * procedure and guessing that this routine extends
			     * all ther way to that one.
			     */

			    for (symsLeft = n - 1, nextSym = symSym + 1;
				 symsLeft != 0;
				 symsLeft--, nextSym++) {
				if (nextSym->type == OSYM_PROC) {
				    /*
				     * Found it!
				     */
				    Library_Publish(fh,
						    s->data,
						    s->relHead,
						    sym->u.proc.address,
						    nextSym->u.proc.address -
						    symSym->u.proc.address,
						    symID);
				break;
				}
			    }

			    /*
			     * If we couldn't find the next procedure in that
			     * block, then start looking through all the rest
			     */

			    if (symsLeft == 0) {
				VMBlockHandle    nextBlock;
				VMBlockHandle    nextNext;
				ObjSymHeader     *nextHdr;
				
				for (nextBlock = osh->next; nextBlock != 0;
				     nextBlock = nextNext) {
				    nextHdr = (ObjSymHeader *)VMLock(symbols,
								     nextBlock,
								     (MemHandle *)NULL);
				    for (symsLeft = nextHdr->num,
					 nextSym = (ObjSym *)(nextHdr+1);
					 symsLeft != 0;
					 symsLeft--, nextSym++) {

					if (nextSym->type == OSYM_PROC) {
					    /*
					     * Found it!
					     */
					    Library_Publish(fh,
							    s->data,
							    s->relHead,
							    sym->u.proc.address,
							    nextSym->u.proc.address -
							    symSym->u.proc.address,
							    symID);
					    break;
					}
				    }

				    nextNext = nextHdr->next;
				    VMUnlock(symbols, nextBlock);
				    
				    /*
				     * If we found the next proc, break here
				     */
				    if (symsLeft != 0) {
					break;
				    }
				}
			    }

			    /*
			     * If symsLeft is still zero, then we never found
			     * the next routine. We'll assume that the current
			     * routine is the last one in the data block and
			     * copy the rest of the data out.
			     */

			    if (symsLeft == 0) {
				Library_Publish(fh,
						s->data,
						s->relHead,
						sym->u.proc.address,
						s->size - sym->u.proc.address,
						symID);
			    }
			}
			VMUnlock(symbols, symBlock);
		    }
		}
	    }
	    next = symHdr->next;
	    VMUnlock(fh, block);
	}

	for (cur = s->relHead; cur != 0; cur = next) {
	    orh = (ObjRelHeader *)VMLock(fh, cur, &rmem);
	    next = orh->next;
	    n = orh->num;

	    for (rel = (ObjRel *)(orh+1); n > 0; n--, rel++) {
		int 	    	uprel=0;    /* Set if should advance nextRel
					     * to next runtime relocation */

		switch(rel->type) {
		    case OREL_PROTOMINOR:
			(void)Pass2VMHandleOffRel(sd, data, file, fh, hdr,
						    rel, nextRel);
			uprel = 1;
			break;
		    case OREL_CALL:
		    case OREL_OFFSET:
		    case OREL_LOW:
		    case OREL_HIGH:
			uprel = Pass2VMHandleOffRel(sd, data, file, fh, hdr,
						    rel, nextRel);
			break;
		    case OREL_ENTRY:
			if (fileOps->flags & FILE_NOENTRYPTS) {
			    Pass2_RelocError(sd, rel->offset,
				"entry-point relocations not supported");
			} else {
			    Pass2VMHandleEntryRel(sd, data, file, fh, hdr,
						  rel);
			}
			break;
		    case OREL_SEGMENT:
		    case OREL_HANDLE:
		    case OREL_RESID:
			uprel = Pass2VMHandleSegRel(sd, data, file, fh, hdr,
						    rel, nextRel);
			break;
		    case OREL_METHCALL:
		    case OREL_SUPERCALL:
			uprel = Pass2VMHandleMethCall(sd, data, file, fh, hdr,
						      rel, nextRel);
			break;
		    default:
			abort();
		}
		if (uprel) {
		    nextRel = (genptr)nextRel + fileOps->rtrelsize;
		}
	    }
	    VMUnlock(fh, cur);
	}

	if ((s->data == 0) || (s->type == SEG_ABSOLUTE)) {
	    /*
	     * If the segment has no data, it can't have any relocations,
	     * now can it? So there's nothing to do here.
	     */
	    continue;
	}

	/*
	 * Figure the size of the data block out.
	 */
	MemInfo(mem, (genptr *)NULL, &n);

	/*
	 * Send it to the output file.
	 */
	Out_Block(sd->nextOff, data, n);

	/*
	 * Advance the nextOff pointer to the next position, padding to
	 * the alignment boundary.
	 */
	sd->nextOff += (n + sd->alignment) & ~sd->alignment;

	/*
	 * Zero-fill any needed padding (why? Why not?)
	 */
	if (n & sd->alignment) {
	    /*
	     * Using a dynamic array tickles a bug in the sparc version of
	     * the compiler, so use malloc and free for now...
	     */
	    int	    extra = (sd->alignment+1) - (n & sd->alignment);
	    /*char    zeroes[extra];*/
	    char    *zeroes = (char *)malloc(extra);

	    bzero(zeroes, extra);
	    Out_Block(sd->nextOff-extra, zeroes, extra);
	    free(zeroes);
	}

	/*
	 * If any runtime relocations in our buffer, send them to the
	 * output file as well, advancing the roff field of the segment to
	 * account for them.
	 */
	if (nextRel != rbase) {
	    int	    len = (genptr)nextRel - (genptr)rbase;

	    Out_Block(sd->roff, rbase, len);
	    sd->roff += len;
	}
	if (rbase != NULL) {
	    free(rbase);
	}
    }

    /*
     * Handle any entry point specified in this header.
     */
    if (hdr->entry.frame != 0) {
	if (entryGiven) {
	    Notify(NOTIFY_ERROR, "%s: entry point already given",
		   file);
	} else {
	    entryGiven = TRUE;

	    if (fileOps->setEntry != (SetEntryProc *)0) {
		SegDesc	    	*frame;
		SegDesc	    	*ssd;
		dword	    	reloc;
		VMBlockHandle	symBlock;
		word	    	symOff;

		/*
		 * Figure the proper offset using the standard mechanism. We
		 * use the global segment as the relocation context for lack
		 * of anything better...
		 */
		if (!Pass2VMRelOff(globalSeg, (void *)NULL, &hdr->entry,
				   file, fh, hdr,
				   &reloc, &frame, &ssd, &symBlock, &symOff))
		{
		    Notify(NOTIFY_ERROR, "error relocating entry point");
		} else {
		    /*
		     * Pass the information to the output module to do with as
		     * it sees fit.
		     */
		    (*fileOps->setEntry)(frame, reloc);
		}
	    }
	}
    }

    VMUnlock(fh, map);
    VMClose(fh);
}
	    

