/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  obj.c
 * FILE:	  obj.c
 *
 * AUTHOR:  	  Adam de Boor: Oct  2, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Obj_Open    	    Open an object file
 *	Obj_TypeEqual	    Compare two VM data types for equality
 *	Obj_PrintType	    Print a VM data type to a stream in human-readable
 *	    	    	    form.
 *	Obj_FindFrameVM	    Figure the frame for a VM relocation
 *	Obj_TypeSize	    Figure the number of bytes taken by something
 *	    	    	    of the given type.
 *	Obj_EnterTypeSyms   Enter the type symbols from a chain of VM
 *	    	    	    blocks into the output file.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/ 2/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for scanning object files. Includes functions for
 *	byte-swapping the components of same.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: obj.c,v 3.29 96/06/10 12:09:07 adam Exp $";
#endif lint

#include    "glue.h"

#include    <objfmt.h>
#include    "msobj.h"
#include    "obj.h"
#include    "sym.h"
#include    <objSwap.h>
#include    <st.h>
#include    <errno.h>



/***********************************************************************
 *				Obj_Open
 ***********************************************************************
 * SYNOPSIS:	    Open an object file as a VM file.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The VM file, the handle of the map block (locked),
 *	    	    the address of the object header in the map block and
 *	    	    the status from the open, if successful.
 *	    	    NULL and the status from the failed open if not. The
 *	    	    status will be EINVAL (or something) if the object
 *	    	    file doesn't contain a valid magic number.
 * SIDE EFFECTS:    Naaaaaahh.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 2/89	Initial Revision
 *
 ***********************************************************************/
VMHandle
Obj_Open(const char    	*file,      /* Name of file to open */
	 short	    	*statusPtr, /* Place to store status of open */
	 ObjFileType   	*typePtr,   /* Type of object file opened */
	 int	    	justChecking)
{
    VMHandle	    fh;	    	/* Handle to file */
    short   	    status; 	/* Status from open */
    VMBlockHandle   map;    	/* Block handle of file map */
    ObjHeader	    *hdr;   	/* Header in map block */
    short   	    minor, major;

    /*
     * Open the object file. Note we don't give it a relocation routine yet
     * as we don't know if the file was written with a different byte order.
     */
    fh = VMOpen(VMO_OPEN|FILE_DENY_W|FILE_ACCESS_R, 0, file, &status);

    if (fh == NULL) {
	if (status == EINVAL) {
	    FILE    *f = fopen(file, "rb");

	    if (f != NULL) {
		/*
		 * Attempt to verify the thing is a Microsoft object file by
		 *  1) making sure the file begins with a THEADR record
		 *  2) the THEADR record is valid, as determined by forming
		 *     the 8-bit checksum and making sure the result is 0.
		 */
		unsigned char	c;

		c = getc(f);
		if (c == MO_THEADR) {
		    /*
		     * First byte is code for THEADR. Make sure the length
		     * is reasonable and the bytes in the record sum to 0.
		     * 9/18/92: Microsoft, in Their infinite wisdom, have
		     * decided that checksums are passe, so we can't actually
		     * perform this checksum test reliably. Instead, we will
		     * look at the length of the record and compare it to the
		     * length of the string. If it's 2 bytes longer, we assume
		     * the thing's a valid object file and run with it -- ardeb
		     */
		    byte    c1, c2;
		    word    len;

		    c1 = getc(f);
		    c2 = getc(f);

		    len = c1 | (c2 << 8);
		    if (len-2 == getc(f)) {
			/*
			 * Looks good, dude. Rewind the file, return
			 * a zero status, OBJ_MS as the type and the
			 * stdio stream as the object file handle.
			 */
			rewind(f);
			if (statusPtr) {
			    *statusPtr = 0;
			}
			*typePtr = OBJ_MS;
			return((VMHandle)f);
		    }
		} else if (c == MO_LHEADR) {
		    /*
		     * Looks like a Microsoft library. Not much we can
		     * check on without a good deal of work, so just assume
		     * that's what it is...
		     */
		    rewind(f);
		    if (statusPtr) {
			*statusPtr = 0;
		    }
		    *typePtr = OBJ_MSL;
		    return((VMHandle)f);
		}
		fclose(f);
	    }
	}
	if (!justChecking) {
	    if (status == ENOENT) {
		Notify(NOTIFY_ERROR, "%s: file not found\n", file);
	    } else {
		Notify(NOTIFY_ERROR,
		       "%s: invalid object module (not VM or MS format)\n",
		       file);
	    }
	    errors++;
	}
	if (statusPtr) {
	    *statusPtr = status;
	}
	return(NULL);
    }

    /*
     * Make sure the object file was created by a version of Esp we know
     * and trust.
     */
    if (VMGetVersion(fh) > 1) {
	GeosFileHeader2  gfh;    	/* Header for verifying protocol */

	VMGetHeader(fh, (char *)&gfh);
	minor = swaps(gfh.protocol.minor);
	major = swaps(gfh.protocol.major);
    } else {
	GeosFileHeader	gfh;

	VMGetHeader(fh, (char *)&gfh);
	minor = swaps(gfh.core.protocol.minor);
	major = swaps(gfh.core.protocol.major);
    }

    if ((major != OBJ_PROTOCOL_MAJOR) || (minor > OBJ_PROTOCOL_MINOR)) {
	if (!justChecking) {
	    Notify(NOTIFY_ERROR,
		   "%s: invalid object file (version mismatch)",
		   file);
	    errors++;
	}
	VMClose(fh);
	if (statusPtr) {
	    *statusPtr = EINVAL;
	}
	return(NULL);
    }

    /*
     * Load the header block
     */
    map = VMGetMapBlock(fh);
    hdr = (ObjHeader *)VMLock(fh, map, NULL);

    if (hdr->magic != OBJMAGIC) {
	if (hdr->magic == SWOBJMAGIC) {
	    /*
	     * File was written on a machine with a different byte-order --
	     * byte-swap the header, then register the general object
	     * relocation routine to deal with future blocks.
	     */
	    ObjSwap_Header(hdr);
	    VMSetReloc(fh, ObjSwap_Reloc);
	} else {
	    if (!justChecking) {
		Notify(NOTIFY_ERROR,
		       "%s: invalid object file (bad magic number)",
		       file);
		errors++;
	    }
	    VMUnlock(fh, map);
	    VMClose(fh);
	    if (statusPtr) {
		*statusPtr = EINVAL;
	    }
	    return (NULL);
	}
    }

    VMUnlock(fh, map);

    *typePtr = OBJ_VM;

    return(fh);
}


/***********************************************************************
 *				ObjIntTypeEqual
 ***********************************************************************
 * SYNOPSIS:	    Special hack routine to allow real types from assembly
 *	    	    to compare positively with crippled integer types
 *	    	    from C
 * CALLED BY:	    (INTERNAL) Obj_TypeEqual
 * RETURN:	    TRUE/FALSE if type is equivalent/not equivalent to
 *	    	    	more-complex type
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    The following things are allowed as equal:
 *	    	    	optr	4-byte integer
 *	    	    	hptr	2-byte integer
 *	    	    	sptr	2-byte integer
 *	    	    	lptr	2-byte integer
 *	    	    	enum	same-sized integer
 *	    	    	record	same-sized integer
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/15/95		Initial Revision
 *
 ***********************************************************************/
static int
ObjIntTypeEqual(word	    t1,
		VMHandle    f2,
		void	    *t2Base,
		word	    t2)
{
    ObjType *ot;

    assert((t1 & OTYPE_TYPE) == OTYPE_INT);

    if (t2 & OTYPE_SPECIAL) {
	/*
	 * Must be another int or some type of pointer
	 */
	if (t1 == t2) {
	    /* This one's obvious */
	    return (TRUE);
	}

	if ((t2 & OTYPE_TYPE) == OTYPE_PTR) {
	    /*
	     * Pointer to void -- look for the ones that can't be represented
	     * properly in C.
	     */
	    word    neededSize = 0;

	    switch(t2 & OTYPE_DATA) {
	    case OTYPE_PTR_LMEM:
	    case OTYPE_PTR_HANDLE:
	    case OTYPE_PTR_SEG:
		neededSize = 2;
		break;
	    case OTYPE_PTR_VIRTUAL:
	    case OTYPE_PTR_VM:
	    case OTYPE_PTR_OBJ:
		neededSize = 4;
		break;
	    }
	    return(t1 == OTYPE_MAKE_INT(neededSize));
	}

	return(FALSE);
    }

    ot = (ObjType *)((char *)t2Base + t2);

    if (OTYPE_IS_STRUCT(ot->words[0])) {
	unsigned size = Obj_TypeSize(t2, t2Base, TRUE);

	if (size == 0) {
	    /*
	     * We have no way of knowing if they're equivalent, as the
	     * assembly thing is using a structure that's defined in a library.
	     * We assume the other checks for structure field offsets and
	     * structure sizes and the like being equal will catch if the
	     * structure and the integer are of inequal size...
	     */
	    return(TRUE);
	} else {
	    return(t1 == OTYPE_MAKE_INT(size));
	}
    } else if (OTYPE_IS_PTR(ot->words[0])) {
	/*
	 * Pointer to something else -- allow it to be an integer for those
	 * pointer types not representable in C
	 */
	unsigned neededSize = 0;

	switch(OTYPE_PTR_TYPE(ot->words[0])<<OTYPE_DATA_SHIFT) {
	case OTYPE_PTR_LMEM:
	case OTYPE_PTR_HANDLE:
	case OTYPE_PTR_SEG:
	    neededSize = 2;
	    break;
	case OTYPE_PTR_VIRTUAL:
	case OTYPE_PTR_VM:
	case OTYPE_PTR_OBJ:
	    neededSize = 4;
	    break;
	}
	return(t1 == OTYPE_MAKE_INT(neededSize));
    }

    return(FALSE);
}


/***********************************************************************
 *				ObjTypedefEqual
 ***********************************************************************
 *
 * SYNOPSIS:	    Compare a potential typedef against another type.
 * CALLED BY:	    Obj_TypeEqual
 * RETURN:	    1 if symbol was typedef (sets result), 0 if not.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Lookup the typedef symbol.  If found and is typedef,
 *		    set result to comparison of type against other type
 *		    and return 1, else return 0.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dhunter	8/14/00   	Initial Revision
 *
 ***********************************************************************/
int
ObjTypedefEqual (void *base, ObjType *tdef, VMHandle f2, void *t2Base,
		 word t2, int *result)
{
    ID	    	    id = OTYPE_STRUCT_ID(tdef);
    VMBlockHandle   block;
    word    	    off;
    int	    	    i, retval = 1;

    *result = 1;  /* assume things will go to plan */
    for (i = 0; i < seg_NumSegs; i++) {
	if (Sym_Find(symbols, seg_Segments[i]->syms, id, &block, &off,
		     FALSE))
	{
	    ObjSym  	*sym;

	    sym = (ObjSym *)((genptr)VMLock(symbols, block,
					    (MemHandle *)NULL)+off);
	    if (sym->type == OSYM_TYPEDEF)
	    {
		*result = Obj_TypeEqual(symbols, base, sym->u.typeDef.type,
				       f2, t2Base, t2);
		retval = 1;
	    }
	    else
		retval = 0;   /* let other checks take a stab at it */
	    VMUnlock(symbols, block);
	    break;
	}
    }
    return retval;
}	/* End of ObjTypedefEqual.	*/


/***********************************************************************
 *				Obj_TypeEqual
 ***********************************************************************
 * SYNOPSIS:	    Make sure two type descriptions match.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    1 if the two are equal. 0 if not.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 7/89	Initial Revision
 *
 ***********************************************************************/
int
Obj_TypeEqual(VMHandle	f1, 	    /* VM file containing any IDs for type1 */
	      void  	*t1Base,    /* Base of block containing first type */
	      word  	t1,         /* Type descriptor 1 */
	      VMHandle	f2, 	    /* VM file containing any IDs for type2 */
	      void  	*t2Base,    /* Base of block containing second type */
	      word  	t2)	    /* Type descriptor 2 */
{
    if (t1 & OTYPE_SPECIAL) {
	/*
	 * If first type is special, it must match t2 exactly. Note that
	 * a pointer to void matches a pointer to a data type as long
	 * as the species of pointer is the same (e.g. both lmem pointers)
	 */
	ObjType	*type2 = (ObjType *)((genptr)t2Base + t2);

	if (t2 & OTYPE_SPECIAL) {
	    if ((t1 & OTYPE_TYPE) == OTYPE_INT) {
		return(ObjIntTypeEqual(t1, f2, t2Base, t2));
	    } else if ((t2 & OTYPE_TYPE) == OTYPE_INT) {
		return(ObjIntTypeEqual(t2, f1, t1Base, t1));
	    } else {
		return(t1 == t2);
	    }
	}

	/*
	 * If second type is an array, allow the thing to be declared as
	 * just the most basic element of the array, equivalent to
	 *	extern	char	foo[]
	 * in C.
	 * 3/31/93: we also allow a void _near * to match a word[0], to allow
	 * external references to chunks in BorlandC to match, since we
	 * carefully transform word[1] (which is word[] in the external case,
	 * and BCC translates [] to 0) to void _near * in borland.c. -- ardeb
	 */
	if (OTYPE_IS_ARRAY(type2->words[0])) {
	    return(Obj_TypeEqual(f1, t1Base, t1, f2, t2Base, type2->words[1]) ||
		   ((t1 == OTYPE_MAKE_VOID_PTR(OTYPE_PTR_NEAR)) &&
		    (OTYPE_ARRAY_LEN(type2->words[0]) == 0) &&
		    (type2->words[1] == OTYPE_MAKE_INT(2))));
	}

	/* void * matches type * so long as the size of the ptr is the same */
	if (((t1&OTYPE_TYPE) == OTYPE_PTR) && (OTYPE_IS_PTR(type2->words[0]) &&
	    ((type2->words[0]&0xfe) == (t1 & 0xfe))))
	{
	    return(TRUE);
	} else if ((t1 & OTYPE_TYPE) == OTYPE_INT) {
	    /*
	     * Special hacks for integers
	     */
	    return (ObjIntTypeEqual(t1, f2, t2Base, t2));
	} else {
	    /*
	     * Not a pointer or a different species
	     */
	    return(FALSE);
	}
    } else if (t2 & OTYPE_SPECIAL) {
	ObjType	*type1;

	type1 = (ObjType *)((genptr)t1Base + t1);

	if (OTYPE_IS_ARRAY(type1->words[0])) {
	    return(Obj_TypeEqual(f1, t1Base, type1->words[1], f2, t2Base, t2) ||
		   ((t2 == OTYPE_MAKE_VOID_PTR(OTYPE_PTR_NEAR)) &&
		    (OTYPE_ARRAY_LEN(type1->words[0]) == 0) &&
		    (type1->words[1] == OTYPE_MAKE_INT(2))));
	}

	/* void * matches type * so long as the size of the ptr is the same */
	if (((t2&OTYPE_TYPE) == OTYPE_PTR) && OTYPE_IS_PTR(type1->words[0]) &&
	    ((type1->words[0]&0xfe) == (t2 & 0xfe)))
	{
	    return(TRUE);
	} else if ((t2 & OTYPE_TYPE) == OTYPE_INT) {
	    /*
	     * Special hacks for integers
	     */
	    return(ObjIntTypeEqual(t2, f1, t1Base, t1));
	} else {
	    /*
	     * Not a pointer or a different species
	     */
	    return(FALSE);
	}
    } else {
	ObjType	    *type1, *type2;
	int 	    retval;

	type1 = (ObjType *)((genptr)t1Base + t1);
	type2 = (ObjType *)((genptr)t2Base + t2);

	/*
	 * If one type is a structure and the other isn't, as C-asm linkage
	 * is prone to causing, see if the structure is a typedef, and if
	 * so, compare its base type to the other type.  If we cannot locate
	 * the structure (i.e. defined in a library), we hope the other
	 * checks will suffice.
	 */
	if (OTYPE_IS_STRUCT(type1->words[0]) &&
	    !OTYPE_IS_STRUCT(type2->words[0]))
	{
	    if (ObjTypedefEqual(t1Base, type1, f2, t2Base, t2, &retval))
		return retval;
	}
	else if (!OTYPE_IS_STRUCT(type1->words[0]) &&
	     OTYPE_IS_STRUCT(type2->words[0]))
	{
	    if (ObjTypedefEqual(t2Base, type2, f1, t1Base, t1, &retval))
		return retval;
	}

	/*
	 * If one type is an array, and the other isn't, compare the base
	 * type of the array against the other, to allow for external
	 * declarations to not include the thing being an array, as in C.
	 * XXX: what about nested arrays? This will let them all through.
	 * Should it?
	 */
	if (OTYPE_IS_ARRAY(type1->words[0]) &&
	    !OTYPE_IS_ARRAY(type2->words[0]))
	{
	    return(Obj_TypeEqual(f1, t1Base, type1->words[1],
				 f2, t2Base, t2));
	} else if (OTYPE_IS_ARRAY(type2->words[0])) {
	    return(Obj_TypeEqual(f1, t1Base, t1,
				 f2, t2Base, type2->words[1]));
	} else if (OTYPE_IS_STRUCT(type1->words[0])) {
	    if (OTYPE_IS_STRUCT(type2->words[0])) {
		/*
		 * Lock both ID's and do a string compare. No point in
		 * resolving one to an ID in the other's context, as that
		 * will require more strcmps than the 1 we have to do...
		 */
		char	*name1, *name2;

		name1 = ST_Lock(f1, OTYPE_STRUCT_ID(type1));
		name2 = ST_Lock(f2, OTYPE_STRUCT_ID(type2));

		retval = (strcmp(name1, name2) == 0);

		ST_Unlock(f1, OTYPE_STRUCT_ID(type1));
		ST_Unlock(f2, OTYPE_STRUCT_ID(type2));
	    } else {
		retval = 0;
	    }
	} else {
	    /*
	     * The other types have a word giving the pointer type or array
	     * length, which must match exactly, and a word that's another
	     * type description, which we check recursively.
	     */
	    retval = ((type1->words[0] == type2->words[0]) &&
		      Obj_TypeEqual(f1, t1Base, type1->words[1],
				    f2, t2Base, type2->words[1]));
	}

	return(retval);
    }
}


/***********************************************************************
 *				Obj_PrintType
 ***********************************************************************
 * SYNOPSIS:	    Convert a VMObject-style type description to words.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Wheee
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/30/89	Initial Revision
 *
 ***********************************************************************/
void
Obj_PrintType(FILE  	*stream,
	      VMHandle	file,
	      void  	*base,
	      word  	type)
{
    if (type & OTYPE_SPECIAL) {
	switch(type & 0xff00) {
	    case OTYPE_INT: fprintf(stream, "int(%d)", (type & 0xfe) >> 1); break;
	    case OTYPE_SIGNED: fprintf(stream, "signed(%d)", (type & 0xfe) >> 1); break;
	    case OTYPE_NEAR: fprintf(stream, "near"); break;
	    case OTYPE_FAR: fprintf(stream, "far"); break;
	    case OTYPE_CHAR: fprintf(stream, "char(%d)", (type & 0xfe)>>1); break;
	    case OTYPE_VOID: fprintf(stream, "void"); break;
	    case OTYPE_PTR: fprintf(stream, "%cptr", (type & 0xfe)>>1); break;
	    case OTYPE_BITFIELD: fprintf(stream, "bitfield"); break;
	}
    } else {
	ObjType	*t = (ObjType *)((genptr)base+type);

	if (OTYPE_IS_STRUCT(t->words[0])) {
	    VMHandle	oidfile = UtilGetIDFile();

	    UtilSetIDFile(file);
	    fprintf(stream, "struct(%i)", OTYPE_STRUCT_ID(t));
	    UtilSetIDFile(oidfile);
	} else if (OTYPE_IS_PTR(t->words[0])) {
	    fprintf(stream, "%cptr(", OTYPE_PTR_TYPE(t->words[0]));
	    Obj_PrintType(stream, file, base, t->words[1]);
	    fprintf(stream, ")");
	} else {
	    word	len = OTYPE_ARRAY_LEN(t->words[0]);
	    word	nels = 0;

	    /*
	     * Deal with arrays > OTYPE_MAX_ARRAY_LEN by moving down the
	     * chain of ObjType's, summing the lengths from each until
	     * we get to one that has <= OTYPE_MAX_ARRAY_LEN elements.
	     */
	    while (len == OTYPE_MAX_ARRAY_LEN+1) {
		nels += len;

		t = (ObjType *)((genptr)base + t->words[1]);
		len = OTYPE_ARRAY_LEN(t->words[0]);
	    }
	    nels += len;

	    fprintf(stream, "%d array(", nels);
	    Obj_PrintType(stream, file, base, t->words[1]);
	    fprintf(stream, ")");
	}
    }
}

/***********************************************************************
 *				Obj_FindFrameVM
 ***********************************************************************
 * SYNOPSIS:	    Find the frame for a relocation. In general,
 *	    	    returns a SegDesc or GroupDesc, as appropriate,
 *	    	    depending on the offset of the thing being sought
 *	    	    in the ObjHeader from a VM file.
 * CALLED BY:	    Pass1CountRels, Pass2RelocOff, Pass2LoadVM
 * RETURN:	    SegDesc * or GroupDesc * (can be distinguished by
 *	    	    the type field common to both).
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	    If offset is within the segment descriptor range of the
 *	    header, call Seg_Find, passing the name and class.
 *	    If offset is within the group descriptor range, call
 *	    Seg_FindGroup -- it will deal with any groups that mutated
 *	    into segments.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/23/89	Initial Revision
 *
 ***********************************************************************/
SegDesc *
Obj_FindFrameVM(const char  *file,  	/* File name (for PRIVATE segments) */
		 VMHandle   fh,	    	/* Object file */
		 ObjHeader  *hdr,   	/* Header for same */
		 word	    offset) 	/* Offset of descriptor w/in header
					 * block */
{
    if (offset < sizeof(ObjHeader) + hdr->numSeg * sizeof(ObjSegment)) {
	/*
	 * Segment. Use name and class and object filename for locating it.
	 */
	ObjSegment	*s = (ObjSegment *)((genptr)hdr+offset);
	SegDesc	    	*sd;

	sd = Seg_Find(file,
		      ST_Dup(fh, s->name, symbols, strings),
		      ST_Dup(fh, s->class, symbols, strings));
	if ((sd == NULL) && (fh == symbols)) {
	    /*
	     * To deal with private segments properly during pass 2, where there
	     * could well be references to private segments in other files, if
	     * we can't find a segment by the proper name, etc., and the fh is
	     * actually our output file, we look through the segments again,
	     * seeking one with the given header offset.
	     *
	     * XXX: what about private segments that have been subsumed into
	     * a group?
	     */
	    int	    	i;

	    for (i = 0; i < seg_NumSegs; i++) {
		sd = seg_Segments[i];
		if (sd->offset == offset) {
		    break;
		}
	    }
	}

	return(sd);
    } else {
	ObjGroup	    *g = (ObjGroup *)((genptr)hdr+offset);

	return((SegDesc *)Seg_FindGroup(file,
					ST_Dup(fh,
					       g->name,
					       symbols,
					       strings)));
    }
}


/***********************************************************************
 *				Obj_TypeSize
 ***********************************************************************
 * SYNOPSIS:	    Figure how many bytes something of the given type
 *	    	    requires.
 * CALLED BY:	    Sym_AllocCommon
 * RETURN:	    # of bytes
 * SIDE EFFECTS:    none.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 5/91		Initial Revision
 *
 ***********************************************************************/
unsigned
Obj_TypeSize(word   type,   	    /* The start of the type description */
	     void   *base,  	    /* Base of the type block holding
				     * additional ObjType descriptors */
	     int    mayBeUndefined) /* TRUE if it's ok for a structure type
				     * to be undefined. 0 is returned for
				     * the size in this case */
{
    int	    size = 0;

    if (type & OTYPE_SPECIAL) {
	switch (type & OTYPE_TYPE) {
	    case OTYPE_FLOAT:
	    case OTYPE_COMPLEX:
	    case OTYPE_INT:
	    case OTYPE_SIGNED:
		size = (type & OTYPE_DATA) >> 1;
		break;
	    case OTYPE_NEAR:
	    case OTYPE_FAR:
	    case OTYPE_VOID:
	    case OTYPE_BITFIELD:
		/*
		 * We shouldn't be called with these. It's an error if we are.
		 */
		Notify(NOTIFY_ERROR,
		       "Obj_TypeSize called with unexpected special type %04x",
		       type);
		assert(0);
		break;
	    case OTYPE_CHAR:
		size = ((type & OTYPE_DATA) >> 1) + 1;
		break;
	    case OTYPE_PTR:
		switch (type & OTYPE_DATA) {
		    case OTYPE_PTR_FAR:
		    case OTYPE_PTR_OBJ:
			size = 4;
			break;
		    default:
			size = 2;
			break;
		}
		break;
	    default:
		Notify(NOTIFY_ERROR,
		       "Obj_TypeSize called with unknown special type %04x",
		       type);
		assert(0);
		break;
	}
    } else {
	ObjType	*ot = (ObjType *)((genptr)base + type);

	if (OTYPE_IS_PTR(ot->words[0])) {
	    /*
	     * We don't care what the base type is, just the pointer type.
	     */
	    switch (ot->words[0] & OTYPE_DATA) {
		case OTYPE_PTR_FAR:
		case OTYPE_PTR_OBJ:
		    size = 4;
		    break;
		default:
		    size = 2;
		    break;
	    }
	} else if (OTYPE_IS_ARRAY(ot->words[0])) {
	    size = OTYPE_ARRAY_LEN(ot->words[0]) * Obj_TypeSize(ot->words[1],
								base,
								mayBeUndefined);
	} else {
	    ID	    	    id = OTYPE_STRUCT_ID(ot);
	    VMBlockHandle   block;
	    word    	    off;
	    int	    	    i;


	    for (i = 0; i < seg_NumSegs; i++) {
		if (Sym_Find(symbols, seg_Segments[i]->syms, id, &block, &off,
			     FALSE))
		{
		    ObjSym  	*sym;

		    sym = (ObjSym *)((genptr)VMLock(symbols, block,
						    (MemHandle *)NULL)+
				     off);
		    if ((sym->type == OSYM_STRUCT) ||
			(sym->type == OSYM_RECORD) ||
			(sym->type == OSYM_ETYPE) ||
			(sym->type == OSYM_UNION))
		    {
			size = sym->u.sType.size;
		    } else if (sym->type == OSYM_TYPEDEF) {
			size = Obj_TypeSize(sym->u.typeDef.type, base,
					    mayBeUndefined);
		    }
		    VMUnlock(symbols, block);
		    break;
		}
	    }
	    /* XXX: bitch if type undefined, don't die */
	    assert(i != seg_NumSegs || mayBeUndefined);
	}
    }

    return(size);
}


/*
 * Data passed among the various type-specific copy routines.
 */
typedef struct {
    const char 	    *file;  	/* Name of current object file */
    SegDesc 	    *sd;    	/* Segment being loaded */
    void    	    *tbase; 	/* Base of type description block for current
				 * symbol IN OBJECT FILE */
    /*
     * Data for current duplicate symbol block.
     */
    VMBlockHandle   syms;   	/* Handle of current block */
    ObjSym  	    *nextSym;	/* Place to store next copied symbol */
    int	    	    symOff; 	/* Offset of same w/in syms */
    int	    	    symSize;	/* Total size of syms */
    MemHandle	    mem;    	/* Memory handle for syms */
    /*
     * Data for type descriptions.
     */
    VMBlockHandle   types;  	/* Current type block */
    ObjType 	    *nextType;	/* Address of next slot ObjType in types */
    int	    	    typeOff;	/* Offset of same w/in types */
    int	    	    typeSize;	/* Total size of types */
    MemHandle	    tmem;   	/* Memory handle of types */
} ObjETSData;

/***********************************************************************
 *				ObjAllocSymBlock
 ***********************************************************************
 * SYNOPSIS:	    Allocate a new symbol block for the current segment.
 * CALLED BY:	    Obj_EnterTypeSyms
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
static void
ObjAllocSymBlock(ObjETSData    *dp)	/* Data describing state of
						 * the copy */
{
    ObjSymHeader    	*osh;	    /* General sym-block header */

    /*
     * See if we can/should allocate a new type-description block now we're
     * switching symbol blocks.
     */
    if ((dp->types == 0) || (dp->typeOff == dp->typeSize) ||
	(dp->typeSize > OBJ_INIT_TYPES))
    {
	if (dp->types != 0) {
	    ObjTypeHeader   *oth;

	    MemInfo(dp->tmem, (genptr *)&oth, 0);
	    oth->num = (dp->typeSize - sizeof(ObjTypeHeader))/sizeof(ObjType);
	    VMUnlockDirty(symbols, dp->types);
	}

	dp->typeSize = OBJ_INIT_TYPES;
	dp->types = VMAlloc(symbols, dp->typeSize, OID_TYPE_BLOCK);

	dp->typeOff = sizeof(ObjTypeHeader);
	dp->nextType = (ObjType *)((genptr)VMLock(symbols,dp->types,&dp->tmem)+
				   dp->typeOff);
    }

    /*
     * Now allocate a new symbol block.
     */
    dp->syms = VMAlloc(symbols, OBJ_MAX_SYMS, OID_SYM_BLOCK);

    if (dp->sd->symT != 0) {
	/*
	 * Not the first block -- link the new block into the last.
	 */
	osh = (ObjSymHeader *)VMLock(symbols, dp->sd->symT, NULL);
	osh->next = dp->syms;
	VMUnlockDirty(symbols, dp->sd->symT);
    } else {
	/*
	 * Store the block as the head of the chain.
	 */
	dp->sd->symH = dp->syms;
    }

    dp->symSize = OBJ_MAX_SYMS;

    osh = (ObjSymHeader *)VMLock(symbols, dp->syms, &dp->mem);
    osh->next = (VMBlockHandle)NULL;
    osh->types = dp->types;
    osh->num = (dp->symSize - sizeof(ObjSymHeader))/sizeof(ObjSym);
    dp->sd->symT = dp->syms;

    dp->nextSym = (ObjSym *)(osh + 1);
    dp->symOff = sizeof(ObjSymHeader);
}


/***********************************************************************
 *				ObjExpandBlock
 ***********************************************************************
 * SYNOPSIS:	    Make sure the current symbol block has enough
 *	    	    room to hold the number of bytes indicated
 * CALLED BY:	    Obj_EnterTypeSyms
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
static inline void
ObjExpandBlock(ObjETSData  *dp,    	    /* State of the copy */
	       int 	    bytesNeeded)    /* Guess what? */
{
    if (dp->symOff + bytesNeeded > dp->symSize) {
	ObjSymHeader	*base;

	/*
	 * Set new size
	 */
	dp->symSize = dp->symOff + bytesNeeded;
	/*
	 * Enlarge block and get the new address.
	 * XXX: Have a MemReAllocLocked?
	 */
	(void)MemReAlloc(dp->mem, dp->symSize, 0);
	MemInfo(dp->mem, (genptr *)&base, (word *)NULL);
	/*
	 * Adjust nextSym for caller.
	 */
	dp->nextSym = (ObjSym *)((genptr)base + dp->symOff);

	base->num = (dp->symSize - sizeof(ObjSymHeader))/sizeof(ObjSym);
    }
}

/***********************************************************************
 *				ObjDupType
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
ObjDupType(word   	    type,   	/* Type to copy */
	   ObjETSData  	    *dp, 	/* State of the copy */
	   VMHandle	    fh,	    	/* Handle to obj file */
	   void   	    *tbase,     /* Base of type block in object
					 * file */
	   word   	    *typeDest)  /* Place to store duplicate */
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
	    ObjDupType(src.words[1], dp, fh, tbase, &src.words[1]);
	}

	/*
	 * Make sure there's room for the descriptor in the block.
	 */
	if (dp->typeOff == dp->typeSize) {
	    /*
	     * Add another record to the block. This could be considered
	     * inefficient, but the blocks are allocated large enough and
	     * symbol blocks proportionately small enough (and the descriptions
	     * themselves are compact enough), that I don't anticipate this
	     * being executed very often. It might be the better part of wisdom
	     * to allocate several extra chunks at a time, however.
	     */
	    void	*base;

	    dp->typeSize += sizeof(ObjType);
	    (void)MemReAlloc(dp->tmem, dp->typeSize, 0);
	    MemInfo(dp->tmem, (genptr *)&base, (word *)NULL);
	    dp->nextType = (ObjType *)((genptr)base + dp->typeOff);
	}

	if (OTYPE_IS_STRUCT(src.words[0])) {
	    /*
	     * A structure needs to have the structure name duplicated
	     */
	    ID id = ST_Dup(fh, OTYPE_STRUCT_ID(&src),
				symbols, strings);

	    OTYPE_ID_TO_STRUCT(id,dp->nextType);
	} else {
	    /*
	     * Anything else can be copied in directly, since the
	     * nested type has already been copied.
	     */
	    *dp->nextType = src;
	}
	/*
	 * Adjust caller's variables.
	 */
	*typeDest = dp->typeOff;
	dp->nextType += 1;
	dp->typeOff += sizeof(ObjType);
    }
}


/***********************************************************************
 *				ObjEnterStruct
 ***********************************************************************
 * SYNOPSIS:	    Copy a structure or record to the output file.
 * CALLED BY:	    Obj_EnterTypeSyms
 * RETURN:	    0 if error. 1 if not.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/10/89	Initial Revision
 *
 ***********************************************************************/
static int
ObjEnterStruct(VMHandle    	fh, 	    /* Object file */
	       ObjSym    	**osPtr,    /* I/O: current/next sym from
					     * object file */
	       word	    	*nPtr,      /* I/O: number of symbols left
					     * in current block */
	       ObjETSData	*dp,        /* State of the copy */
	       Boolean	    	all)	    /* TRUE to enter fields */
{
    ObjSym  	    *os = *osPtr;   	/* Current object symbol */
    word    	    n = *nPtr;	    	/* Number of symbols left in block */
    ID	    	    id;	    	    	/* Name of base type in output file */
    VMBlockHandle   otherBlock;	    	/* Block containing duplicate of
					 * base type */
    word    	    otherOff;	    	/* Offset of base type in same */
    int	    	    retval = 1;	    	/* Value to return (assume ok) */

    /*
     * Map the symbol's name into an ID in the output file. We do the mapping
     * because if the symbol doesn't exist, we'll have to enter the ID into
     * the output file anyway, and we suspect the number of comparisons
     * required for looking up an ID will be comparable to that for looking
     * up a symbol.
     */
    id = ST_Dup(fh, os->name, symbols, strings);

    if (!Sym_Find(symbols, dp->sd->syms, id, &otherBlock, &otherOff, FALSE)) {
	/*
	 * Not defined yet -- copy it and its fields into the output file,
	 * entering them in the table for the segment.
	 */
	ObjSym	*fs;	    /* Field symbol */
	word	baseOff;    /* Offset of base type symbol for setting "next"
			     * pointer of final field */

	if (os->u.sType.first == 0) {
	    /*
	     * If the first pointer is 0, the structure/record has no fields,
	     * so set fs to os+1.
	     */
	    fs = os+1;
	} else {
	    fs = (ObjSym *)((genptr)os+(os->u.sType.last-os->u.sType.first))+2;
	}

	/*
	 * Allocate another symbol block if needed.
	 */
	if (dp->syms == 0) {
	    ObjAllocSymBlock(dp);
	}

	/*
	 * Make sure there's enough room in the current
	 * symbol block for this thing and its fields.
	 */
	ObjExpandBlock(dp, (genptr)fs-(genptr)os);

	/*
	 * Copy all the symbols wholesale to the new block.
	 */
	bcopy(os, dp->nextSym, (genptr)fs-(genptr)os);

	/*
	 * Record offset of type symbol for the 'next' field
	 * of the last field. This allows us to find the type
	 * again later.
	 */
	baseOff = dp->symOff;

	/*
	 * Deal with the main type symbol first. Avoids
	 * a test in the loop...
	 */
	dp->nextSym->name = id;
	Sym_Enter(symbols, dp->sd->syms, id, dp->syms, dp->symOff);

	if (dp->nextSym->u.sType.first != 0) {
	    dp->nextSym->u.sType.first = dp->symOff + sizeof(ObjSym);
	    dp->nextSym->u.sType.last =
		dp->nextSym->u.sType.first + (os->u.sType.last -
					      os->u.sType.first);

	    /*
	     * Advance to first field.
	     */
	    dp->nextSym++, os++, n--, dp->symOff += sizeof(ObjSym);


	    while (os != fs) {
		/*
		 * Duplicate the field name.
		 */
		dp->nextSym->name = ST_Dup(fh, os->name, symbols, strings);
		/*
		 * Adjust the "next" pointer.
		 */
		dp->nextSym->u.sField.next = dp->symOff + sizeof(ObjSym);
		/*
		 * Duplicate the field type description.
		 */
		ObjDupType(dp->nextSym->u.sField.type, dp, fh,
			     dp->tbase, &dp->nextSym->u.sField.type);

		if ((os->name != NullID) && all) {
		    Sym_Enter(symbols, dp->sd->syms, dp->nextSym->name,
			      dp->syms, dp->symOff);
		}

		/*
		 * Advance to next field.
		 */
		dp->nextSym++, os++, n--, dp->symOff += sizeof(ObjSym);
	    }
	    dp->nextSym[-1].u.sField.next = baseOff;
	} else {
	    dp->nextSym++, os++, n--, dp->symOff += sizeof(ObjSym);
	}
    } else {
	/*
	 * Already defined -- make sure the definitions match
	 */
	ObjSymHeader	*otherOSH;
	ObjSym	    	*otherOS;
	void	    	*otherTBase;
	ObjSym	    	*fs1;
	int 	    	fc;

	fc = os->u.sType.last - os->u.sType.first;

	otherOSH = (ObjSymHeader *)VMLock(symbols, otherBlock, NULL);
	otherOS = (ObjSym *)((genptr)otherOSH+otherOff);
	otherTBase = VMLock(symbols, otherOSH->types, NULL);

	/*
	 * Make sure they're the same type of symbol.
	 */
	if (otherOS->type != os->type) {
	    if (os->type == OSYM_RECORD &&
		otherOS->type == OSYM_TYPEDEF &&
		(Obj_TypeSize(otherOS->type, otherTBase, TRUE) ==
		 os->u.sType.size))
	    {
		/*
		 * Allow a record to match a typedef if they're the same
		 * size, to cope with linking assembly and C. I'd prefer to
		 * choose the record, but I haven't the time to figure out
		 * the logistics -- ardeb 5/19/95
		 */
		/* nothing to do here */;
	    } else if ((os->type == OSYM_ENUM &&
			otherOS->type == OSYM_METHOD) ||
		       (os->type == OSYM_METHOD &&
			otherOS->type == OSYM_ENUM))
	    {
		/*
		 * Allow an enum to match a method so long as the number
		 * is the same.
		 */
		if (os->u.eField.value != otherOS->u.eField.value) {
		    Notify(NOTIFY_ERROR,
			   "%s: %i: method number differs between object files",
			   dp->file, otherOS->name);
		    retval = 0;
		} else if (os->type == OSYM_METHOD) {
		    /*
		     * Make sure method info makes it from assembly to C.
		     */
		    otherOS->type = OSYM_METHOD;
		    otherOS->u.method.flags = os->u.method.flags;
		}
	    } else {
		Notify(NOTIFY_ERROR,
		       "%s: %i: symbol type differs between object files",
		       dp->file, otherOS->name);
		retval = 0;
	    }
	    /*
	     * Skip type symbol too.
	     */
	    fc += sizeof(ObjSym);
	    goto done;
	}

	/*
	 * Make sure the types are of the same size.
	 */
	if (otherOS->u.sType.size != os->u.sType.size) {
	    Notify(NOTIFY_ERROR,
		   "%s: %i: size differs between object files (%d vs. %d)",
		   dp->file, otherOS->name,
		   otherOS->u.sType.size, os->u.sType.size);
	    retval = 0;
	    /*
	     * Skip type symbol too.
	     */
	    fc += sizeof(ObjSym);
	    goto done;
	}
	/*
	 * Use the difference between the offsets of the
	 * first and last field symbols to see if the two
	 * definitions have the same number of fields.
	 */
	if ((otherOS->u.sType.last - otherOS->u.sType.first) !=
	    (os->u.sType.last - os->u.sType.first))
	{
	    Notify(NOTIFY_ERROR,
		   "%s: %i: number of fields differs between object files",
		   dp->file, otherOS->name);
	    retval = 0;
	    /*
	     * Skip type symbol too.
	     */
	    fc += sizeof(ObjSym);
	    goto done;
	}
	/*
	 * If first is zero, structure has no fields to be checked.
	 */
	if (os->u.sType.first == 0) {
	    goto done;
	}

	/*
	 * Now check the individual fields for compatibility.
	 */
	for (fs1 = otherOS+1, os++, n--;
	     fc >= 0;
	     fs1++, fc -= sizeof(ObjSym), os++, n--)
	{
	    /*
	     * Compare the two names. Don't bother
	     * looking one up in the other's string table,
	     * as that will cause more string compares than
	     * just doing one here will...
	     */
	    if ((fs1->name == NullID) || (os->name == NullID)) {
		if (fs1->name != os->name) {
		    /*XXX: GIVE FIELD NAME */
		    Notify(NOTIFY_ERROR,
			   "%s: %i: nameless vs. named field mismatch",
			   dp->file, otherOS->name);
		    retval = 0;
		    break;
		}
	    } else {
		char *name1 = ST_Lock(symbols, fs1->name);
		char *name2 = ST_Lock(fh, os->name);

		if (strcmp(name1, name2) != 0) {
		    Notify(NOTIFY_ERROR,
			   "%s: %i: field name mismatch (%s vs. %s)",
			   dp->file, otherOS->name,
			   name1, name2);
		    ST_Unlock(symbols, os->name);
		    ST_Unlock(fh, fs1->name);
		    retval = 0;
		    break;
		}
		ST_Unlock(symbols, fs1->name);
		ST_Unlock(fh, os->name);
	    }

	    if (fs1->type == OSYM_FIELD) {
		/*
		 * Make sure the fields lie at the same offset
		 * in their respective structures.
		 */
		if (fs1->u.sField.offset != os->u.sField.offset) {
		    Notify(NOTIFY_ERROR,
			   "%s: %i.%i: field offset mismatch (%d vs %d)",
			   dp->file, otherOS->name, fs1->name,
			   fs1->u.sField.offset,
			   os->u.sField.offset);
		    retval = 0;
		    break;
		}
	    } else {
		/*
		 * Make sure the fields lie at the same offset
		 * in their respective records.
		 */
		if (fs1->u.bField.offset != os->u.bField.offset) {
		    Notify(NOTIFY_ERROR,
			   "%s: %i.%i: field offset mismatch (%d vs %d)",
			   dp->file, otherOS->name, fs1->name,
			   fs1->u.bField.offset,
			   os->u.bField.offset);
		    retval = 0;
		    break;
		}
		/*
		 * Make sure the fields are the same width
		 * in their respective records.
		 */
		if (fs1->u.bField.width != os->u.bField.width) {
		    Notify(NOTIFY_ERROR,
			   "%s: %i.%i: field width mismatch (%d vs %d)",
			   dp->file, otherOS->name, fs1->name,
			   fs1->u.bField.width,
			   os->u.bField.width);
		    retval = 0;
		    break;
		}
	    }
	    /*
	     * Make sure their types match.
	     */
	    if (!Obj_TypeEqual(symbols, otherTBase, fs1->u.sField.type,
			       fh, dp->tbase, os->u.sField.type))
	    {
		Notify(NOTIFY_ERROR,
		       "%s: %i.%i: field type mismatch",
		       dp->file, otherOS->name, fs1->name);
		fprintf(stderr, "Type ");
		Obj_PrintType(stderr, symbols, otherTBase, fs1->u.sField.type);
		fprintf(stderr, " not same as type ");
		Obj_PrintType(stderr, fh, dp->tbase, os->u.sField.type);
		fprintf(stderr, ".\n");
		retval = 0;
		break;
	    }
	}

	done:

	/*
	 * Advance to beyond last field symbol.
	 */

	if (fc >= 0) {
	    os = (ObjSym *)((genptr)os + fc);
	    n -= fc/sizeof(ObjSym);
	    os++, n--;
	}

	/*
	 * Release the block containing the already-defined
	 * symbol.
	 */
	VMUnlock(symbols, otherOSH->types);
	VMUnlock(symbols, otherBlock);
    }

    *osPtr = os, *nPtr = n;

    return(retval);
}

/***********************************************************************
 *				ObjEnterTypedef
 ***********************************************************************
 * SYNOPSIS:	    Copy a TYPEDEF symbol into the output file.
 * CALLED BY:	    Obj_EnterTypeSyms
 * RETURN:	    0 if error, 1 if ok.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/10/89		Initial Revision
 *
 ***********************************************************************/
static int
ObjEnterTypedef(VMHandle   	fh, 	    /* Object file */
		   ObjSym    	**osPtr,    /* I/O: current/next sym from
					     * object file */
		   word	    	*nPtr, 	    /* I/O: number of symbols left
					     * in current block */
		   ObjETSData	*dp) 	    /* State of the copy */
{
    ObjSym  	    *os = *osPtr;   	/* Current object symbol */
    ID	    	    id;	    	    	/* Name of base type in output file */
    VMBlockHandle   otherBlock;	    	/* Block containing duplicate of
					 * base type */
    word    	    otherOff;	    	/* Offset of base type in same */
    int	    	    retval = 1;	    	/* Value to return (assume ok) */

    /*
     * Map the symbol's name into an ID in the output file. We do the mapping
     * because if the symbol doesn't exist, we'll have to enter the ID into
     * the output file anyway, and we suspect the number of comparisons
     * required for looking up an ID will be comparable to that for looking
     * up a symbol.
     */
    id = ST_Dup(fh, os->name, symbols, strings);

    if (!Sym_Find(symbols, dp->sd->syms, id, &otherBlock, &otherOff, FALSE)) {
	/*
	 * Not defined yet -- copy it into the output.
	 */
	if (dp->syms == 0) {
	    ObjAllocSymBlock(dp);
	}

	/*
	 * Copy
	 *  1) the name
	 *  2) the type and flags
	 *  3) the type description
	 *
	 * into nextSym. We know there's a symbol available, as there's always
	 * one, or dp->syms would be 0.
	 */
	dp->nextSym->name = id;
	dp->nextSym->type = os->type;
	dp->nextSym->flags = os->flags;

	ObjDupType(os->u.typeDef.type, dp, fh,
		     dp->tbase, &dp->nextSym->u.typeDef.type);

	/*
	 * Enter the symbol into the table for the segment.
	 */
	Sym_Enter(symbols, dp->sd->syms, id, dp->syms, dp->symOff);

	dp->nextSym++, dp->symOff += sizeof(ObjSym);
    } else {
	/*
	 * Already defined -- make sure the definitions match
	 */
	ObjSymHeader	*otherOSH;
	ObjSym	    	*otherOS;
	void	    	*otherTBase;

	otherOSH = (ObjSymHeader *)VMLock(symbols, otherBlock, NULL);
	otherOS = (ObjSym *)((genptr)otherOSH+otherOff);
	otherTBase = VMLock(symbols, otherOSH->types, NULL);

	/*
	 * Make sure they're the same type of symbol.
	 */
	if (otherOS->type != os->type) {
	    /*
	     * Allow a typedef in C to match a record or enumerated type in
	     * assembly, so long as the types are the same size.
	     */
	    if (((otherOS->type == OSYM_RECORD) ||
		 (otherOS->type == OSYM_ETYPE)) &&
		(otherOS->u.sType.size ==
		 Obj_TypeSize(os->u.typeDef.type, dp->tbase, TRUE)))
	    {
		/* do nothing */;
	    } else if ((os->type == OSYM_ENUM &&
			otherOS->type == OSYM_METHOD) ||
		       (os->type == OSYM_METHOD &&
			otherOS->type == OSYM_ENUM))
	    {
		/*
		 * Allow an enum to match a method so long as the number
		 * is the same.
		 */
		if (os->u.eField.value != otherOS->u.eField.value) {
		    Notify(NOTIFY_ERROR,
			   "%s: %i: method number differs between object files",
			   dp->file, otherOS->name);
		    retval = 0;
		} else if (os->type == OSYM_METHOD) {
		    /*
		     * Make sure method info makes it from assembly to C.
		     */
		    otherOS->type = OSYM_METHOD;
		    otherOS->u.method.flags = os->u.method.flags;
		}
	    } else {
		Notify(NOTIFY_ERROR,
		       "%s: %i: symbol type differs between object files",
		       dp->file, otherOS->name);
		retval = 0;
	    }
	    goto done;
	}

	/*
	 * Make sure the type definitions match.
	 */
	if (!Obj_TypeEqual(symbols, otherTBase, otherOS->u.typeDef.type,
			   fh, dp->tbase, os->u.typeDef.type))
	{
	    Notify(NOTIFY_ERROR,
		   "%s: %i: definition differs between object files",
		   dp->file, otherOS->name);
	    retval = 0;
	}

	done:

	VMUnlock(symbols, otherOSH->types);

	/*
	 * Matches in all particulars -- let the thing go.
	 */
	VMUnlock(symbols, otherBlock);
    }

    *osPtr += 1;
    *nPtr -= 1;

    return(retval);
}

/***********************************************************************
 *				ObjEnterEType
 ***********************************************************************
 * SYNOPSIS:	    Copy an enumerated type into the output file,
 *	    	    merging in any members not previously known.
 * CALLED BY:	    Obj_EnterTypeSyms
 * RETURN:	    0 on error, 1 if ok.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	 This one's *much* more fun. We can't just check for
 *	 an exact match. We have to form the union of all
 *	 the definitions available, meaning for each member we've
 *	 got in the object file, we need to look it up in the
 *	 segment. If it's not there, we need to link it into
 *	 the type  If it is there, we need to make sure the
 *	 existing symbol belongs to the same type and has the
 *	 same value.
 *
 *	 All this is to allow ImportMethod/ExportMethod to work.
 *	 Sigh.
 *
 *	 An enumerated type description appears slightly
 *	 different in a .sym file than in a .obj file. Since
 *	 we can't guarantee that all the members will follow
 *	 immediately after the ETYPE, as we can in the .obj,
 *	 we make the eField.next pointer of the final member
 *	 point to the ETYPE so we can make sure an existing
 *	 symbol is part of the right enumerated type.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/10/89	Initial Revision
 *
 ***********************************************************************/
static int
ObjEnterEType(VMHandle   	fh, 	    /* Object file */
		 ObjSym	    	**osPtr,    /* I/O: current/next sym from
					     * object file */
		 word	    	*nPtr, 	    /* I/O: number of symbols left
					     * in current block */
		 ObjETSData	*dp)
{
    ObjSym  	    *os = *osPtr;   	/* Current object symbol */
    word    	    n = *nPtr;	    	/* Number of symbols left in block */
    ID	    	    id;	    	    	/* Name of base type in output file */
    VMBlockHandle   otherBlock;	    	/* Block containing duplicate of
					 * base type */
    word    	    otherOff;	    	/* Offset of base type in same */
    int	    	    retval = 1;	    	/* Value to return (assume ok) */

    /*
     * Map the symbol's name into an ID in the output file. We do the mapping
     * because if the symbol doesn't exist, we'll have to enter the ID into
     * the output file anyway, and we suspect the number of comparisons
     * required for looking up an ID will be comparable to that for looking
     * up a symbol.
     */
    id = ST_Dup(fh, os->name, symbols, strings);

    if (!Sym_Find(symbols, dp->sd->syms, id, &otherBlock, &otherOff, FALSE)) {
	/*
	 * Yea! Not defined. We just need to copy and enter
	 * all the members into the output file.
	 */
	ObjSym	    *ms;
	word	    baseOff;

	/*
	 * Point ms after the last member. We know in an
	 * object file all the members follow immediately
	 * after the etype symbol.
	 */
	if (os->u.sType.first == 0) {
	    /*
	     * No members at all...
	     */
	    ms = os+1;
	} else {
	    ms = (ObjSym *)((genptr)os+(os->u.sType.last-os->u.sType.first))+2;
	}

	/*
	 * Allocate another symbol block if needed.
	 */
	if (dp->syms == 0) {
	    ObjAllocSymBlock(dp);
	}

	/*
	 * Make sure there's enough room in the current
	 * symbol block for this thing and its fields.
	 */
	ObjExpandBlock(dp, (genptr)ms-(genptr)os);
	/*
	 * Copy all the symbols wholesale to the new block.
	 */
	bcopy(os, dp->nextSym, (genptr)ms-(genptr)os);

	/*
	 * Record offset of ETYPE symbol for the 'next' field
	 * of the last member. This allows us to find the type
	 * again when we're merging things.
	 */
	baseOff = dp->symOff;

	/*
	 * Deal with the main type symbol first. Avoids
	 * a test in the loop...
	 */
	dp->nextSym->name = id;
	Sym_Enter(symbols, dp->sd->syms, id, dp->syms, dp->symOff);

	if (dp->nextSym->u.sType.first != 0) {
	    dp->nextSym->u.sType.first = dp->symOff + sizeof(ObjSym);
	    dp->nextSym->u.sType.last =
		dp->nextSym->u.sType.first + (os->u.sType.last -
					      os->u.sType.first);

	    /*
	     * Advance to first member.
	     */
	    dp->nextSym++, os++, n--, dp->symOff += sizeof(ObjSym);

	    while (os != ms) {
		/*
		 * Duplicate the member name.
		 */
		dp->nextSym->name = ST_Dup(fh, os->name, symbols, strings);
		/*
		 * Adjust the "next" pointer.
		 */
		dp->nextSym->u.eField.next = dp->symOff + sizeof(ObjSym);

		/*
		 * Do not enter exported message ranges into the symbol table
		 * for this segment. They have enumerated type alter-egos that
		 * we want to be able to look up instead. As mentioned below,
		 * these alter-egos shouldn't be in the same segment as the
		 * OSYM_METHOD symbol, but stranger things have happened.
		 */
		if ((dp->nextSym->type != OSYM_METHOD) ||
		    !(dp->nextSym->u.method.flags & OSYM_METH_RANGE))
		{
		    Sym_Enter(symbols, dp->sd->syms, dp->nextSym->name,
			      dp->syms, dp->symOff);
		}

		/*
		 * Duplicate the type descriptor for data associated with
		 * the VarData type.
		 */
		if (dp->nextSym->type == OSYM_VARDATA) {
		    ObjDupType(os->u.varData.type, dp, fh,
			       dp->tbase, &dp->nextSym->u.varData.type);
		}

		/*
		 * Advance to next member.
		 */
		dp->nextSym++, os++, n--, dp->symOff += sizeof(ObjSym);
	    }
	    dp->nextSym[-1].u.eField.next = baseOff;
	} else {
	    dp->nextSym++, os++, n--, dp->symOff += sizeof(ObjSym);
	}
    } else {
	/*
	 * Already defined -- make sure the definitions match, merging any
	 * as-yet undefined members.
	 */
	VMBlockHandle	mBlock;	/* Block containing found enum member */
	word	    	mOff;	/* Offset of same */
	ObjSym	    	*m; 	/* Locked version of same */
	ObjSym	    	*ms;	/* Current member in object file */
	ObjSymHeader	*otherOSH;
	ObjSym	    	*otherOS;
	MemHandle   	omem;
	int 	    	osize;

	otherOSH = (ObjSymHeader *)VMLock(symbols, otherBlock, &omem);
	otherOS = (ObjSym *)((genptr)otherOSH+otherOff);

	osize = sizeof(ObjSymHeader) + (otherOSH->num * sizeof(ObjSym));

	/*
	 * Point ms after the last member. We know in an object file all the
	 * members follow immediately after the etype symbol.
	 */
	if (os->u.sType.first == 0) {
	    ms = os+1;
	} else {
	    ms = (ObjSym *)((genptr)os+(os->u.sType.last-os->u.sType.first))+2;
	}

	n -= ms-os;

	/*
	 * Make sure they're the same type of symbol.
	 */
	if (otherOS->type != os->type) {
	    if (otherOS->type == OSYM_TYPEDEF) {
		/*
		 * Allow an enumerated type to match a typedef, if they're the
		 * same size, to cope with assembly/C linking. We'd prefer to
		 * replace the typedef with the enumerated type, but
		 * at the moment, I don't have the time to figure out the
		 * logistics -- ardeb 5/19/95
		 */
		void *otherTBase = VMLock(symbols, otherOSH->types,
					  (MemHandle *)NULL);
		unsigned size;

		size = Obj_TypeSize(otherOS->u.typeDef.type, otherTBase,
				    TRUE);
		VMUnlock(symbols, otherOSH->types);

		if (size == os->u.sType.size) {
		    goto done2;
		}
	    }

	    Notify(NOTIFY_ERROR,
		   "%s: %i: symbol type differs between object files",
		   dp->file, otherOS->name);
	    retval = 0;
	    goto done2;
	}

	for (os += 1; retval && os != ms; os++) {
	    ID	    mid;
	    int	    found;
	    int	    dontEnter = 0;

	    mid = ST_Dup(fh, os->name, symbols, strings);
	    if ((os->type == OSYM_METHOD) &&
		(os->u.method.flags & OSYM_METH_RANGE))
	    {
		/*
		 * Exported message ranges are not entered into the symbol
		 * table so they don't conflict with the enumerated type
		 * of the same name the assembler creates. Now, in theory,
		 * the enumerated type shouldn't be in the same segment, the
		 * whole point of exported message ranges being that you don't
		 * have to define or know about all the weird messages exported
		 * from a high-level class. It has been known to happen,
		 * however, so we're careful...
		 */
		ObjSym	    *tms;   /* Current member in already-defined
				     * enumerated type */

		found = 0;
		dontEnter = 1;

		for (tms = (ObjSym *)((genptr)otherOSH+otherOS->u.sType.first);
		     tms != otherOS;
		     tms = (ObjSym *)((genptr)otherOSH+tms->u.eField.next))
		{
		    if (tms->name == mid) {
			found = 1;
			mBlock = otherBlock;
			mOff = (genptr)tms - (genptr)otherOSH;
			break;
		    }
		}
	    } else {
		found = Sym_Find(symbols, dp->sd->syms, mid, &mBlock, &mOff,
				 FALSE);
	    }

	    if (!found) {
		word	off;
		void	*base;

		/*
		 * Member not already defined -- add it to the type.
		 */
		if (otherBlock == dp->syms) {
		    /*
		     * In current symbol block, so we need to use the state
		     * variables we're keeping, making sure they're up-to-date.
		     */
		    ObjExpandBlock(dp, sizeof(ObjSym));
		    m = dp->nextSym++;
		    off = dp->symOff;
		    dp->symOff += sizeof(ObjSym);
		    MemInfo(dp->mem, (genptr *)&base, (word *)NULL);
		} else {
		    /*
		     * In some other, full block, so the thing just goes at
		     * the end, making "off" be the size of the block.
		     */
		    off = osize;
		    otherOSH->num += 1;
		    osize += sizeof(ObjSym);
		    MemReAlloc(omem, osize, 0);
		    MemInfo(omem, (genptr *)&base, (word *)NULL);
		    m = (ObjSym *)((genptr)base + off);
		}

		if (!dontEnter) {
		    Sym_Enter(symbols, dp->sd->syms, mid, otherBlock, off);
		}

		/*
		 * "m" now contains the place to store the member, "id"
		 * contains its translated ID, "off" contains the offset of
		 * "m" within its block.
		 */
		*m = *os;
		m->name = mid;
		m->u.eField.next = otherOff; /* Link to base type */

		/*
		 * Duplicate the type descriptor for data associated with
		 * the VarData type.
		 */
		if (m->type == OSYM_VARDATA) {
		    ObjDupType(os->u.varData.type, dp, fh,
			       dp->tbase, &m->u.varData.type);
		}

		/*
		 * Adjust "last" pointer for type and "next" pointer of final
		 * member.
		 */
		otherOSH = (ObjSymHeader *)base;
		otherOS=(ObjSym *)((genptr)base+otherOff);
		m=(ObjSym *)((genptr)base+otherOS->u.sType.last);
		otherOS->u.sType.last = m->u.eField.next = off;
	    } else {
		/*
		 * Member is defined -- make sure it matches in all
		 * particulars.
		 */
		void	*base;

		base = VMLock(symbols, mBlock, NULL);
		m = (ObjSym *)((genptr)base + mOff);

		/*
		 * Symbol type.
		 */
		if (os->type != m->type) {
		    if ((os->type == OSYM_ENUM && m->type == OSYM_METHOD) ||
			(os->type == OSYM_METHOD && m->type == OSYM_ENUM))
		    {
			/*
			 * Allow an enum to match a method so long as the number
			 * is the same.
			 */
			if (os->type == OSYM_METHOD) {
			    /*
			     * Make sure method info makes it from assembly to
			     * C.
			     */
			    m->type = OSYM_METHOD;
			    m->u.method.flags = os->u.method.flags;
			}
		    } else {
			Notify(NOTIFY_ERROR,
			       "%s: %i: symbol type differs between object files",
			       dp->file, m->name);
			retval = 0;
			goto done;
		    }
		}

		/*
		 * Symbol value
		 */
		if (os->u.eField.value != m->u.eField.value) {
		    Notify(NOTIFY_ERROR,
			   "%s: %i: symbol value differs between object files",
			   dp->file, m->name);
		    retval = 0;
		    goto done;
		}

		/*
		 * If method, then method flags must match
		 */
		if ((os->type == OSYM_METHOD) &&
		    (os->u.method.flags != m->u.method.flags))
		{
		    Notify(NOTIFY_ERROR,
			   "%s: %i: method flags differ between object files",
			   dp->file, m->name);
		    retval = 0;
		    goto done;
		}

		/*
		 * If vardata, then associated type must match.
		 */
		if (os->type == OSYM_VARDATA) {
		    void    	*otherTBase;

		    otherTBase = VMLock(symbols, otherOSH->types, NULL);
		    if (!Obj_TypeEqual(symbols,
				       otherTBase, m->u.varData.type,
				       fh,
				       dp->tbase, os->u.varData.type))
		    {
			Notify(NOTIFY_ERROR,
			       "%s: %i: definition of associated data differs between object files",
			       dp->file, otherOS->name);
			VMUnlock(symbols, otherOSH->types);
			retval = 0;
			goto done;
		    }
		    VMUnlock(symbols, otherOSH->types);
		}

		/*
		 * Make sure found member lies in same block as
		 * base type. If not, can't match.
		 */
		if (mBlock != otherBlock) {
		    Notify(NOTIFY_ERROR,
			   "%s: %i: containing type differs between object files",
			   dp->file, mid);
		    retval = 0;
		    goto done;
		}

		/*
		 * Find the base type for the found symbol
		 * and make sure it matches the base type
		 * we found before.
		 */
		do {
		    m = (ObjSym *)((genptr)base + m->u.eField.next);
		} while (m->type != OSYM_ETYPE);

		if (((genptr)m - (genptr)base) != otherOff) {
		    Notify(NOTIFY_ERROR,
			   "%s: %i: containing type differs between object files",
			   dp->file, mid);
		    retval = 0;
		}

		done:

		VMUnlock(symbols, mBlock);
	    }
	}

	done2:

	os = ms;		/* In case of early exit */

	VMUnlock(symbols, otherBlock);
    }

    *osPtr = os;
    *nPtr = n;
    return(retval);
}

/***********************************************************************
 *				ObjEnterConst
 ***********************************************************************
 * SYNOPSIS:	    Copy a constant symbol into the output file.
 * CALLED BY:	    Obj_EnterTypeSyms
 * RETURN:	    0 on error, 1 if ok.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/10/89	Initial Revision
 *
 ***********************************************************************/
static int
ObjEnterConst(VMHandle   	fh, 	    /* Object file */
		 ObjSym	    	**osPtr,    /* I/O: current/next sym from
					     * object file */
		 word	    	*nPtr, 	    /* I/O: number of symbols left
					     * in current block+1 */
		 ObjETSData	*dp)
{
    ObjSym  	    *os = *osPtr;   	/* Current object symbol */
    ID	    	    id;	    	    	/* Name of base type in output file */
    VMBlockHandle   otherBlock;	    	/* Block containing duplicate of
					 * base type */
    word    	    otherOff;	    	/* Offset of base type in same */
    int	    	    retval = 1;	    	/* Value to return (assume ok) */

    /*
     * Map the symbol's name into an ID in the output file. We do the mapping
     * because if the symbol doesn't exist, we'll have to enter the ID into
     * the output file anyway, and we suspect the number of comparisons
     * required for looking up an ID will be comparable to that for looking
     * up a symbol.
     */
    id = ST_Dup(fh, os->name, symbols, strings);

    if (!Sym_Find(symbols, dp->sd->syms, id, &otherBlock, &otherOff, FALSE)) {

	/*
	 * Not defined yet -- copy it into the output.
	 */
	if (dp->syms == 0) {
	    ObjAllocSymBlock(dp);
	}

	/*
	 * Copy
	 *  1) the name
	 *  2) the type and flags
	 *  3) the value
	 * into nextSym. We know there's a symbol available, as there's always
	 * one, or dp->syms would be 0.
	 */
	dp->nextSym->name = id;
	dp->nextSym->type = os->type;
	dp->nextSym->flags = os->flags;
	dp->nextSym->u.constant.value = os->u.constant.value;

	/*
	 * Enter the symbol into the table for the segment.
	 */
	Sym_Enter(symbols, dp->sd->syms, id, dp->syms, dp->symOff);

	dp->nextSym++, dp->symOff += sizeof(ObjSym);
    } else {
	/*
	 * Already defined -- make sure the definitions match
	 */
	ObjSymHeader	*otherOSH;
	ObjSym	    	*otherOS;

	otherOSH = (ObjSymHeader *)VMLock(symbols, otherBlock, NULL);
	otherOS = (ObjSym *)((genptr)otherOSH+otherOff);

	/*
	 * Make sure they're the same type of symbol.
	 */
	if (otherOS->type != os->type) {
	    Notify(NOTIFY_ERROR,
		   "%s: %i: symbol type differs between object files",
		   dp->file, otherOS->name);
	    retval = 0;
	    goto done;
	}

	/*
	 * Make sure the values match.
	 */
	if (otherOS->u.constant.value != os->u.constant.value) {
	    Notify(NOTIFY_ERROR,
		   "%s: %i: value differs between object files (%d vs. %d)",
		   dp->file, otherOS->name,
		   otherOS->u.constant.value, os->u.constant.value);
	    retval = 0;
	}
	/*
	 * Matches in all particulars -- let the thing go.
	 */
	done:

	VMUnlock(symbols, otherBlock);
    }

    *osPtr += 1;
    *nPtr -= 1;
    return(retval);
}

/***********************************************************************
 *				ObjEnterExtType
 ***********************************************************************
 * SYNOPSIS:	    Copy an external type into the output file.
 * CALLED BY:	    Obj_EnterTypeSyms
 * RETURN:	    0 on error, 1 if ok.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/10/89	Initial Revision
 *
 ***********************************************************************/
static int
ObjEnterExtType(VMHandle   	fh, 	    /* Object file */
		   ObjSym    	**osPtr,    /* I/O: current/next sym from
					     * object file */
		   word	    	*nPtr, 	    /* I/O: number of symbols left
					     * in current block+1 */
		   ObjETSData	*dp) 	    /* State of the copy */
{
    ObjSym  	    *os = *osPtr;   	/* Current object symbol */
    ID	    	    id;	    	    	/* Name of base type in output file */
    VMBlockHandle   otherBlock;	    	/* Block containing duplicate of
					 * base type */
    word    	    otherOff;	    	/* Offset of base type in same */
    int	    	    retval = 1;	    	/* Value to return (assume ok) */

    /*
     * Map the symbol's name into an ID in the output file. We do the mapping
     * because if the symbol doesn't exist, we'll have to enter the ID into
     * the output file anyway, and we suspect the number of comparisons
     * required for looking up an ID will be comparable to that for looking
     * up a symbol.
     */
    id = ST_Dup(fh, os->name, symbols, strings);

    if (!Sym_Find(symbols, dp->sd->syms, id, &otherBlock, &otherOff, FALSE)) {
	/*
	 * Not defined yet -- copy it into the output.
	 */
	if (dp->syms == 0) {
	    ObjAllocSymBlock(dp);
	}

	/*
	 * Copy
	 *  1) the name
	 *  2) the type and flags
	 *  3) the expected symbol type
	 *  4) the zeroed block and offset, so Swat knows
	 *     the cache is empty...
	 * into nextSym. We know there's a symbol available, as there's always
	 * one, or syms would be 0.
	 */
	dp->nextSym->name = id;
	dp->nextSym->type = os->type;
	dp->nextSym->flags = os->flags;
	dp->nextSym->u.extType.stype = os->u.extType.stype;
	dp->nextSym->u.extType.block = dp->nextSym->u.extType.offset = 0;

	/*
	 * Enter the symbol into the table for the segment.
	 */
	Sym_Enter(symbols, dp->sd->syms, id, dp->syms, dp->symOff);

	dp->nextSym++, dp->symOff += sizeof(ObjSym);
    } else {
	/*
	 * Already defined -- make sure the definitions match
	 */
	ObjSymHeader	*otherOSH;
	ObjSym	    	*otherOS;

	otherOSH = (ObjSymHeader *)VMLock(symbols, otherBlock,
					  NULL);
	otherOS = (ObjSym *)((genptr)otherOSH+otherOff);

	/*
	 * Make sure they're the same type of symbol.
	 */
	if (otherOS->type != os->type) {
	    Notify(NOTIFY_ERROR,
		   "%s: %i: symbol type differs between object files",
		   dp->file, otherOS->name);
	    retval = 0;
	    goto done;
	}

	/*
	 * Make sure the expected types match.
	 */
	if (otherOS->u.extType.stype != os->u.extType.stype) {
	    Notify(NOTIFY_ERROR,
		   "%s: %i: expected symbol type differs between object files",
		   dp->file, otherOS->name);
	    retval = 0;
	}
	done:

	/*
	 * Matches in all particulars -- let the thing go.
	 */
	VMUnlock(symbols, otherBlock);
    }

    *osPtr += 1;
    *nPtr -= 1;
    return(retval);
}

/***********************************************************************
 *				Obj_EnterTypeSyms
 ***********************************************************************
 * SYNOPSIS:	    Copy all non-address-bearing symbols
 *	    	    for the given segment to the symbol file.
 * CALLED BY:	    Pass1VM_Load, Pass1MS_Load
 * RETURN:	    0 on error
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	This one is more difficult than ObjRelAddrSyms, as we need to
 *	do type-checking between the object modules:
 *	    - for structures, records and typedefs, the two definitions
 *	      must be both name- and structurally-equivalent. E.g.
 *	      two OSYM_STRUCT symbols must have the same number of fields
 *	      with the same names and types.
 *	    - for enumerated types, members with the same name must have
 *	      the same value. The type in the final output is the union
 *	      of all the type definitions.
 *	For undefined address symbols, we rely on Sym_EnterUndef to do the
 *	type-checking between object modules.
 *
 *	Also don't want to copy symbol blocks into the output file, as
 *	there will be duplicate type symbols around.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 3/89	Initial Revision
 *
 ***********************************************************************/
int
Obj_EnterTypeSyms(const char   	*file,	/* File name */
		  VMHandle    	fh,     /* Object file handle */
		  SegDesc      	*sd,    /* Internal segment
					 * descriptor */
		  VMBlockHandle	next,   /* First block in chain of
					 * type/undefined symbols */
		  int   	flags)	/* OETS* flags */
{
    int	    	    	retval = 1; /* Assume success */
    ObjETSData   	data;	    /* Data to pass to copy routines */
    MemHandle	    	mem;	    /* Handle for finding size of current
				     * object symbol block */
    word    	    	n;  	    /* Number of symbols remaining in block */
    ObjSymHeader    	*osh;	    /* Header of current block */
    ObjSym      	*os;	    /* Symbol to copy */

    /*
     * Figure out where we were with this segment, setting the symbol block
     * and associated type block variables appropriately.
     */
    if (sd->symTNext != 0) {
	/*
	 * Space left in final symbol block -- lock the thing down and
	 * point nextSym at the next slot, recording the size of
	 * the block in symSize for later checks.
	 */
	data.syms = sd->symT;
	osh = (ObjSymHeader *)VMLock(symbols, data.syms, &data.mem);
	MemInfo(data.mem, (genptr *)NULL, &n);
	data.symSize = n;
	data.symOff = sd->symTNext;
	data.nextSym = (ObjSym *)((genptr)osh+data.symOff);

	/*
	 * Extract info for associated type block too
	 */
	data.types = osh->types;
	data.nextType = (ObjType *)VMLock(symbols, data.types, &data.tmem);
	MemInfo(data.tmem, (genptr *)NULL, &n);
	data.typeSize = n;
	data.typeOff = sd->typeNext;
	data.nextType = (ObjType *)((genptr)data.nextType + data.typeOff);
    } else if (sd->typeNext != -1) {
	/*
	 * Can't use the last symbol block, but there's room left in the
	 * associated type block. Lock down the block to get the types block,
	 * then set up the various type-block-associated variables we've got.
	 */
	data.syms = 0;
	data.symSize = data.symOff = 0;

	osh = (ObjSymHeader *)VMLock(symbols, sd->symT, NULL);

	data.types = osh->types;
	data.nextType = (ObjType *)VMLock(symbols, data.types, &data.tmem);
	MemInfo(data.tmem, (genptr *)NULL, &n);
	data.typeSize = n;
	data.typeOff = sd->typeNext;
	data.nextType = (ObjType *)((genptr)data.nextType + data.typeOff);

	VMUnlock(symbols, sd->symT);
    } else {
	/*
	 * Neither symbol block nor type block can we use -- record this.
	 */
	data.syms = data.types = 0;
	data.symSize = data.symOff = 0;
	data.typeSize = data.typeOff = 0;
    }

    data.file = file;
    data.sd = sd;

    while (next != 0) {
	VMBlockHandle	tempNext;

	osh = (ObjSymHeader *)VMLock(fh, next, &mem);

 	data.tbase = VMLock(fh, osh->types, NULL);

	/*
	 * Figure number of symbols in this block
	 */
	n = osh->num;

	for (os = ObjFirstEntry(osh, ObjSym); n > 0; ) {

	    switch(os->type) {
		case OSYM_STRUCT:
		case OSYM_RECORD:
		case OSYM_UNION:
		    retval = ObjEnterStruct(fh, &os, &n, &data,
					    !(flags & OETS_TOP_LEVEL_ONLY)) &&
			retval;
		    break;
		case OSYM_TYPEDEF:
		    retval = ObjEnterTypedef(fh, &os, &n, &data) && retval;
		    break;
		case OSYM_ETYPE:
		    retval = ObjEnterEType(fh, &os, &n, &data) && retval;
		    break;
		case OSYM_CONST:
		    retval = ObjEnterConst(fh, &os, &n, &data) && retval;
		    break;
		case OSYM_EXTTYPE:
		    retval = ObjEnterExtType(fh, &os, &n, &data) && retval;
		    break;
		default:
		{
		    /*
		     * Use a temporary local so we can pass Sym_EnterUndef
		     * a symbol whose name is in "symbols", as it
		     * requires. We can't really overwrite os->name since
		     * we opened the file read-only...
		     */
		    ObjSym	tmp = *os;

		    tmp.name = ST_Dup(fh, os->name, symbols, strings);

		    /* Undef addrsym */
		    Sym_EnterUndef(symbols, sd->syms,
				   tmp.name,
				   &tmp, 0, fh, osh->types);
		    os++, n--;
		    break;
		}
	    }
	    /*
	     * If overran the limit of the current output symbol
	     * block, release the block and set syms to 0 so
	     * we'll allocate a new block next time.
	     */
	    if (data.syms &&
		((data.symSize>OBJ_MAX_SYMS) || (data.symOff==data.symSize)))
	    {
		ObjSymHeader	*tosh;

		MemInfo(mem, (genptr *)&tosh, 0);
		tosh->num = (data.symSize-sizeof(ObjSymHeader))/sizeof(ObjSym);

		VMUnlockDirty(symbols, data.syms);
		data.syms = 0;
	    }
	}
	/*
	 * Done with type block.
	 */
	VMUnlock(fh, osh->types);
	/*
	 * Release this symbol block and advance to next.
	 */
	tempNext = osh->next;
	VMUnlock(fh, next);

	if (!(flags & OETS_RETAIN_ORIGINAL)) {
	    VMEmpty(fh, next);	/* Free associated memory -- we won't use it
				 * again */
	}
	next = tempNext;
    }


    /*
     * Record where we left off in the symbol and type blocks.
     */
    if (data.syms) {
	sd->symTNext = data.symOff;
	VMUnlockDirty(symbols, data.syms);
    } else {
	sd->symTNext = 0;
    }
    if (data.types) {
	sd->typeNext = data.typeOff;
	VMUnlockDirty(symbols, data.types);
    } else {
	sd->typeNext = -1;
    }

    /*
     * Return final return value.
     */
    return(retval);
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
	    return(TRUE);
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
		return(TRUE);
	    }
	    /*FALLTHRU*/
	default:
	    /*
	     * Not one of the address-bearing types, or is one but it's
	     * undefined, so doesn't hold an address.
	     */
	    return(FALSE);
    }
}
