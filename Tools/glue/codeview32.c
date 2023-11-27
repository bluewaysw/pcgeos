/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- CodeView information
 * FILE:	  codeview32.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 12, 1991
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/12/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for handling CodeView type and symbol information.
 *
 *	Codeview symbols are arranged in a rather brain-damaged fashion,
 *	with the type descriptions for the file coming *last*. To deal with
 *	this, we concatenate all the type descriptions together into
 *	a single segment (because a single description can be broken across
 *	multiple object records), and save all symbol segments and PUBDEF
 *	records until the entire file has been processed.
 *
 *	Once the MODEND record has been seen, we process all the symbols,
 *	generating type descriptions from the types once we know they're
 *	needed.
 *
 *	All structure/enum/union/field type symbols go into the global
 *	segment, for lack of any better place to put them.
 *
 *	Still need to look at fixups in the first pass to determine if
 *	they'll need run-time relocations.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: codeview.c,v 1.20 95/11/08 17:23:04 adam Exp $";
#endif lint

#include    "glue.h"
#include    "codeview32.h"
#include    "msobj.h"
#include    "obj.h"
#include    "sym.h"
#include    "cv.h"
#include    <objfmt.h>

/*
 * Values placed in segments vector for symbol and type segments. Most of
 * the fields matter not a whit, so we don't initialize them, especially
 * since one of those fields is a union...
 */
static SegDesc	cvTypesSegment = { NullID, S_SEGMENT };
static SegDesc	cvSymsSegment = { NullID, S_SEGMENT };

#define CV_TYPES_SEGMENT (&cvTypesSegment)
#define CV_SYMS_SEGMENT  (&cvSymsSegment)

static MSSaveRecLinks comHead = {
    (struct _MSSaveRec *)&comHead, (struct _MSSaveRec *)&comHead
};

static MSSaveRecLinks	fixHead = {
    (struct _MSSaveRec *)&fixHead, (struct _MSSaveRec *)&fixHead
};

/*
 * Since High C is mean enough to split symbol and type records across
 * object records at the slightest provocation (after all, they're going to
 * be merged into a single segment anyway, right?), rather than saving the
 * individual object records, we get the joy of merging all the data records
 * for the $$SYMBOLS and $$TYPES segments together, saving the fixups for the
 * $$SYMBOLS segment, of course....
 */
static byte	*typeSeg;   	/* Base of current type segment */
static long	typeSize;   	/* Total size of the type segment */

static byte	*symSeg;    	/* Base of current symbol segment */
static long	symSize;    	/* Total size of the symbol segment */

static word 	CV32ProcessTypeRecord(const char *file,
				    byte **bpPtr,
				    word len,
				    VMBlockHandle typeBlock);
static word
CV32FetchType(const char 	    *file,
					VMBlockHandle   typeBlock,
					unsigned   	    index);


/***********************************************************************
 *				CV32LocatePublic
 ***********************************************************************
 * SYNOPSIS:	    See if the passed symbol was declared public
 * CALLED BY:	    CVLocateFixup, CVProcessSymbols
 * RETURN:	    TRUE if symbol was public
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/25/91		Initial Revision
 *
 ***********************************************************************/
static Boolean
CV32LocatePublic(ID   	name,	    	/* Name to find */
	       SegDesc	**sdPtr,    	/* Storage for segment holding symbol */
	       word 	*offsetPtr, 	/* Storage for offset of symbol */
	       Boolean	*realPtr,   	/* Storage for flag indicating if
					 * symbol is really public, or it was
					 * declared so in a CVPUBDEF record */
	       ID   	*aliasPtr)  	/* Place to store any alias under which
					 * we found the thing. */
{
    MSSaveRec 	*srp;
    byte    	*bp,
		*end;
    SegDesc 	*sd;
    char    	*namestr;
    unsigned   	namelen;

    namestr = ST_Lock(symbols, name);
    namelen = strlen(namestr);

    for (srp = pubHead.next;
	 srp != (MSSaveRec *)&pubHead;
	 srp = srp->links.next)
    {
	bp = srp->data;
	end = bp + srp->len;

	/*
	 * Skip group index
	 */
	MSObj_GetIndex(bp);

	/*
	 * Fetch segment, in case the symbol's here...
	 */
	sd = MSObj_GetSegment(&bp);

	while (bp < end) {
	    /*
	     * Perform a fuzzy comparison on the name, allowing it to be an
	     * all-uppercase or underscore-preceded version of the name
	     * passed. The additional tests in the tortuous conditional are
	     * to avoid an unnecessary function call, if possible.
	     *
	     * 2/5/92: this used to perform an unsigned string comparison
	     * of the two names, to deal with brain-damage from HighC
	     * when the aliasing convention was to upcase everything. We've
	     * stopped doing that, however, since HighC insisted on giving
	     * us all our variables in all uppercase and that was a pain in
	     * the butt to deal with. Of course, if anyone else using HighC
	     * is stupid enough to set the convention that way, they'll be
	     * scrod, but maybe if enough people complain to MetaWare about
	     * it, something'll happen...yeah right. -- ardeb
	     *
	     * 12/4/18: need to bring case-insensitve comparison back
	     * due to upper casing of some names by Watcom C -- mgroeber
 	     */
	    if (((*bp == namelen) && (ustrncmp((char *)bp+1, namestr, namelen) == 0)) ||
		((aliasPtr != NULL) &&
		 (bp[1] == '_') && (*bp == namelen+1) &&
		 (strncmp(namestr, (char *)bp+2, namelen) == 0))) {
			if (aliasPtr != NULL) {
				/*
				* Caller is interested in the alias for the beast. If
				* the name in the PUBDEF record differs, enter it into
				* the string table.
				* XXX: might it just be faster to do the ST_Enter? We'd
				* get  name  back if the string's not aliased...
				*/
				if (strncmp((char *)bp+1, namestr, namelen) != 0) {
				*aliasPtr = ST_Enter(symbols, strings,
							(char *)bp+1, *bp);
				} else {
				*aliasPtr = name;
				}
			}
			ST_Unlock(symbols, name);
			if (offsetPtr != NULL) {
				bp += *bp + 1;
				MSObj_GetWord(*offsetPtr, bp);
			}
			if (sdPtr != NULL) {
				*sdPtr = sd;
			}
			/*
			* The thing is real only if it it's defined inside a PUBDEF
			* record.
			*/
			if (realPtr != NULL) {
				*realPtr = ((srp->type == MO_PUBDEF) ||
						(srp->type == MO_LPUBDEF1) ||
						(srp->type == MO_LPUBDEF2));
			}
			return(TRUE);
		}

	    /*
	     * Skip string and offset, then skip over
	     * the type index (variable-sized)
	     */
	    bp += *bp + 1 + 2;
	    MSObj_GetIndex(bp);
	}
    }

    /*
     * Not found
     */
    ST_Unlock(symbols, name);
    return(FALSE);
}

/***********************************************************************
 *				CV32LocateFixup
 ***********************************************************************
 * SYNOPSIS:	    Locate the fixup for somethin in the $$SYMBOLS
 *	    	    segment and return Import Information about it.
 * CALLED BY:	    CVProcessSymbols
 * RETURN:	    TRUE if the fixup was found, plus the SegDesc and
 *	    	    	extra offset for the fixup.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/22/91		Initial Revision
 *
 ***********************************************************************/
static Boolean
CV32LocateFixup(const char *file,	    	/* Object file being processed */
	      dword  	fixOff, 	/* Offset of needed fixup */
	      SegDesc	**sdPtr,    	/* Target segment of fixup */
	      word  	*extraOffPtr,  	/* Extra offset for fixup (to be
					 * added to existing offset) */
	      ID	*realName)
{
    MSSaveFixupRec  *sfp;	/* Current FIXUPP record being searched */
    byte    	    *bp;	/* General record pointer */
    byte    	    *end;	/* General end-of-record pointer */
    word    	    fixLoc;	/* Offset of fixup within the record's data
				 * field */
    byte    	    fixData;    /* Type of fixup */
    MSFixData	    target;	/* Target of the fixup */
    MSFixData	    frame;	/* Frame w.r.t. which the fixup's being made */
    word    	    reclen;	/* Length of the fixup record */

    *realName = NullID;
    /*
     * First find the right fixup record.
     */
    for (sfp = (MSSaveFixupRec *)fixHead.prev;
	 sfp != (MSSaveFixupRec *)&fixHead;
	 sfp = (MSSaveFixupRec *)sfp->links.prev)
    {
	if ((sfp->startOff <= fixOff) && (sfp->endOff > fixOff)) {
	    /*
	     * Adjust the offset to be w.r.t. to the record's data start.
	     */
	    word recOffset = fixOff - sfp->startOff;

	    /*
	     * Set up the relocation threads as they were when the fixup record
	     * was encountered, so things get resolved correctly.
	     */
	    bcopy(sfp->threads, msThreads, sizeof(sfp->threads));

	    /*
	     * Set up loop variables.
	     */
	    bp = sfp->data;
	    MSObj_GetWord(reclen, bp);
	    end = bp + reclen - 1; /* don't include non-existent checksum */


	    while (bp < end) {
		if (!MSObj_DecodeFixup((char *)file, CV_SYMS_SEGMENT,
				       &bp, &fixLoc, &fixData, &target, &frame))
		{
		    /*
		     * Fixup record is bad -- get out of here.
		     */
		    return(FALSE);
		}

		if ((fixLoc & FL_OFFSET) == recOffset) {
		    if (!(fixData & FD_NO_TARG_DISP)) {
			MSObj_GetWord(*extraOffPtr, bp);
		    } else {
			*extraOffPtr = 0;
		    }
		    switch(fixData & FD_TARGET) {
			case TFM_SEGMENT:
			    *sdPtr = target.segment;
			    break;
			case TFM_GROUP:
			case TFM_ABSOLUTE:
			    Notify(NOTIFY_ERROR,
				   "%s: unsupported codeview-symbol fixup target %d",
				   file, fixData & FD_TARGET);
			    return(FALSE);
			    break;
			case TFM_EXTERNAL:
			{
			    Boolean real;
			    if (!CV32LocatePublic(target.external,
						sdPtr, extraOffPtr,
						&real, (ID *)NULL))
			    {
#if 0	/* HighC likes to generate codeview symbols for external arrays, so
	 * we can't bitch about this... */
				Notify(NOTIFY_ERROR,
				   "%s: cannot locate segment for external symbol %i for codeview fixup",
				   file, target.external & ~MO_EXT_IN_LIB);
#endif
				return(FALSE);
			    }
			    *realName = target.external;
			    break;
			}
		    }
		    return(TRUE);
		} else if (!(fixData & FD_NO_TARG_DISP)) {
		    /*
		     * Skip extra target displacement, too
		     */
		    bp += 2;
		}
	   }
	}
    }

    return(FALSE);
}


/***********************************************************************
 *				CV32AllocSymAndTypeBlocks
 ***********************************************************************
 * SYNOPSIS:	    Allocate a temporary symbol and associated type
 *	    	    block.
 * CALLED BY:	    ?
 * RETURN:	    The symbol and type blocks
 * SIDE EFFECTS:    the headers of the blocks are initialized
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/14/91		Initial Revision
 *
 ***********************************************************************/
static void
CV32AllocSymAndTypeBlocks(VMBlockHandle	*symBlockPtr,
			VMBlockHandle	*typeBlockPtr)
{
    ObjTypeHeader   *oth;
    ObjSymHeader    *osh;

    *typeBlockPtr = VMAlloc(symbols,
			    sizeof(ObjTypeHeader) + 16 * sizeof(ObjType),
			    OID_TYPE_BLOCK);
    oth = (ObjTypeHeader *)VMLock(symbols, *typeBlockPtr, (MemHandle *)NULL);
    oth->num = 0;
    VMUnlockDirty(symbols, *typeBlockPtr);

    *symBlockPtr = VMAlloc(symbols,
			   sizeof(ObjSymHeader) + 16 * sizeof(ObjSym),
			   OID_SYM_BLOCK);

    osh = (ObjSymHeader *)VMLock(symbols, *symBlockPtr, (MemHandle *)NULL);
    osh->num = 0;
    osh->types = *typeBlockPtr;
    osh->seg = 0;
    osh->next = 0;
    VMUnlockDirty(symbols, *symBlockPtr);
}


/***********************************************************************
 *				CV32GetString
 ***********************************************************************
 * SYNOPSIS:	    Decode a CTL_STRING tree and return the ID for it.
 * CALLED BY:	    INTERNAL
 * RETURN:	    ID if string is there, or NullID if empty string
 * SIDE EFFECTS:    *bpPtr is advanced beyond the string.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/17/91		Initial Revision
 *
 ***********************************************************************/
static ID
CV32GetString(byte    **bpPtr)
{
    ID	    retval;

    //assert(**bpPtr == CTL_STRING);
	word len;
	//MSObj_GetWord(len, *bpPtr);
	len = **bpPtr;
	*bpPtr += 1;

    	if (len != 0) {
		retval = ST_Enter(symbols, strings, (char *)(*bpPtr), len);
	} else {
	retval = NullID;
    }

    *bpPtr += len;

    return(retval);
}


/***********************************************************************
 *				CV32GetInteger
 ***********************************************************************
 * SYNOPSIS:	    Decode an Integer tree.
 * CALLED BY:	    INTERNAL
 * RETURN:	    The integer
 * SIDE EFFECTS:    *bpPtr is advanced beyond the tree
 *
 * STRATEGY:
 *	XXX: There are cases where HighC can confuse this, e.g. when it
 *	expects something to always be a byte, but the value won't
 *	actually fit (q.v. # procedure args), it'll just store the low
 *	byte. If the low byte is one of the recognized type leaves
 *	that indicate a different size, all hell will break loose.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/17/91		Initial Revision
 *
 ***********************************************************************/
static unsigned long
CV32GetInteger(byte   **bpPtr)
{
    byte    	    *bp;
    unsigned long   retval;
	word numeric;

	bp = *bpPtr;

	MSObj_GetWord(numeric, bp);

	if (numeric >= 0x8000) {

		switch (numeric) {
		/*case CTL_WORD:*/
		case CNL2_USHORT:
			MSObj_GetWord(retval, bp);
			break;
		/*case CTL_SDWORD:*/
		/*case CTL_DWORD:*/
		case CNL2_LONG:
		case CNL2_ULONG:
			retval = *bp | (bp[1] << 8) | (bp[2] << 16) | (bp[3] << 24);
			bp += 4;
			break;
		/*case CTL_QWORD:*/
		/*case CTL_SQWORD:*/
		case CNL2_REAL32:
		case CNL2_REAL80:
		case CNL2_REAL64:
		case CNL2_REAL128:
		case CNL2_QUADWORD:
		case CNL2_UQUADWORD:
		case CNL2_REAL48:
		case CNL2_COMPLEX32:
		case CNL2_COMPLEX64:
		case CNL2_COMPLEX80:
		case CNL2_COMPLEX128:
		case CNL2_VARSTRING:
			assert(0);
		/*case CTL_SBYTE:*/
		case CNL2_CHAR:
			retval = *bp | (*bp & 0x80 ? 0xffffff00 : 0);
			bp++;
			break;
		/*case CTL_SWORD:*/
		case CNL2_SHORT:
			retval = *bp | (bp[1] << 8) | (bp[1] & 0x80 ? 0xffff0000 : 0);
			bp += 2;
			break;
		default:
			retval = bp[-1];
			break;
		}
	}
	else {
		retval = numeric;
	}
    *bpPtr = bp;
    return(retval);
}




/***********************************************************************
 *				CV32AllocSymLocked
 ***********************************************************************
 * SYNOPSIS:	    Allocate an ObjSym record from a locked symbol block
 * CALLED BY:	    CVAllocSym, CVProcessStructure
 * RETURN:	    Pointer to the ObjSym
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/15/91		Initial Revision
 *
 ***********************************************************************/
static ObjSym *
CV32AllocSymLocked(VMBlockHandle	symBlock,   	/* Block in which to alloc */
		 MemHandle  	mem,	    	/* Memory handle of same */
		 word	    	*offsetPtr, 	/* Place to store offset of
						 * new ObjSym w/in same */
		 ObjSymHeader	**oshPtr)   	/* Base of the locked block,
						 * updated if it moves */
{
    ObjSymHeader    *osh = *oshPtr;
    ObjSym 	    *os;
    word    	    blockSize;

    MemInfo(mem, (genptr *)NULL, &blockSize);

    /*
     * If the block isn't big enough to hold another entry, expand it by
     * some arbitrary number of entries (16, for now).
     */
    os = ObjFirstEntry(osh, ObjSym) + osh->num;
    if (ObjEntryOffset(os, osh) > (blockSize - sizeof(ObjSym))) {
	MemReAlloc(mem, blockSize + 16 * sizeof(ObjSym), 0);
	MemInfo(mem, (genptr *)&osh, (word *)NULL);
	os = ObjFirstEntry(osh, ObjSym) + osh->num;
	*oshPtr = osh;
    }

    /*
     * Return the actual offset of the thing in the block and up the number
     * of entries in the block by one.
     */
    *offsetPtr = ObjEntryOffset(os, osh);
    osh->num += 1;

    /*
     * Mark the block as dirty and return the pointer to our caller.
     */
    VMDirty(symbols, symBlock);
    return(os);
}

/***********************************************************************
 *				CV32AllocSym
 ***********************************************************************
 * SYNOPSIS:	    Allocate an ObjSym record in the passed sym block.
 * CALLED BY:	    CVProcessSymbols, and others
 * RETURN:	    Pointer to the ObjSym
 *	    	    Offset of it within the block
 * SIDE EFFECTS:    The block may move...
 *	    	    osh->num will be upped by 1
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/91		Initial Revision
 *
 ***********************************************************************/
static ObjSym *
CV32AllocSym(VMBlockHandle   symBlock,
	   word    	    *offsetPtr)
{
    MemHandle	    mem;
    ObjSymHeader    *osh;
    static ObjSym   fakeOS;

    if (symBlock == 0) {
	/*
	 * Not actually creating a symbol, so just return
	 * the address of fakeOS and an offset of 0...
	 */
	*offsetPtr = 0;
	return (&fakeOS);
    }

    /*
     * Lock down the block and find how big it currently is.
     */
    osh = (ObjSymHeader *)VMLock(symbols, symBlock, &mem);
    return (CV32AllocSymLocked(symBlock, mem, offsetPtr, &osh));
}


/***********************************************************************
 *				CVLocateType
 ***********************************************************************
 * SYNOPSIS:	    Locate the type in the type segment whose index is
 *	    	    passed (as obtained from a symbol or another type)
 * CALLED BY:	    ?
 * RETURN:	    The start of the type record (excluding the linkage
 *	    	    and length), and the length of the data in the record.
 *
 *	    	    NULL is returned if the passed index is out-of-bounds
 *
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/11/91		Initial Revision
 *
 ***********************************************************************/
static byte *
CV32LocateType(word    	index,
	     word    	*lenPtr)
{
    word    len;
    byte    *bp;
    byte    *endTypes;
	dword sig;

	bp = typeSeg;

	MSObj_GetDWord(sig, bp);
	if (sig != 1) {

		return ((byte *)NULL);
	}
	else {
		assert(index > CST_LAST_PREDEF);

		index -= CST_LAST_PREDEF + 1;

		endTypes = typeSeg + typeSize;

		while (index > 0) {
			len = bp[0] | (bp[1] << 8);
			bp = bp + 2 + len;
			if (bp > endTypes) {
				return ((byte *)NULL);
			}
			index--;
		}

		*lenPtr = bp[0] | (bp[1] << 8);

		return(bp + 2);
	}
}


/***********************************************************************
 *				CV32FinishStructuredType
 ***********************************************************************
 * SYNOPSIS:	    Finish off the definition of a structured type,
 *	    	    be it a structure, union, array, or typedef.
 * CALLED BY:	    CVProcessStructure, CVProcessTypeRecord (CTL_TYPEDEF)
 * RETURN:	    The offset of the ObjType record allocated for
 *	    	    the type.
 * SIDE EFFECTS:    The passed temp VM blocks are freed.
 *	    	    The record is converted to a CTL_ID record.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/17/91		Initial Revision
 *
 ***********************************************************************/
static word
CV32FinishStructuredType(const char    	*file,	    /* Object file being read */
		       byte 	    	*dataBase,  /* Base of data in type
						     * record*/
		       word 	    	len,	    /* Length of same */
		       ObjSym	    	*os,        /* Main type symbol being
						     * entered */
		       VMBlockHandle	tsymBlock,  /* Temporary symbol block
						     * whose symbols are to be
						     * entered. */
		       VMBlockHandle	ttypeBlock, /* Associated type block */
		       VMBlockHandle	typeBlock)  /* Main type block in which
						     * to allocate the ObjType
						     * for this type */
{
    ID	    name;
    ObjType *ot;
    word    typeOff;

    /*
     * Convert our CTL_STRUCTURE record into a CTL_ID record so we don't have
     * to go through all this again next time this type is used.
     */
    assert(len >= 4);
	dataBase[-2] = CTL2_ID & 0xff;
	dataBase[-1] = (CTL2_ID >> 8) & 0xff;
	name = os->name;
    *dataBase++ = name & 0xff;
    name >>= 8;
    *dataBase++ = name & 0xff;
    name >>= 8;
    *dataBase++ = name & 0xff;
    name >>= 8;
    *dataBase++ = name & 0xff;
    name = os->name;		/* Get it back again for our type descriptor */

    /*
     * Unlock and dirty the tsymBlock, as we're done entering symbols.
     */
    VMUnlockDirty(symbols, tsymBlock);

    /*
     * Now enter the whole passel into the global segment.
     */
    (void)Obj_EnterTypeSyms(file, symbols, globalSeg, tsymBlock,
			    OETS_TOP_LEVEL_ONLY);


    /*
     * Free the temporary blocks with which we just finished.
     */
    VMFree(symbols, ttypeBlock);
    VMFree(symbols, tsymBlock);

    /*
     * Finally, allocate the type descriptor for this structured type in
     * the passed type block and return the thing's offset to our caller.
     */
    ot = MSObj_AllocType(typeBlock, &typeOff);
    OTYPE_ID_TO_STRUCT(name,ot);
    if (typeBlock != 0) {
	VMUnlockDirty(symbols, typeBlock);
    }

    return (typeOff);
}


/***********************************************************************
 *				CV32CreateTypedef
 ***********************************************************************
 * SYNOPSIS:	    Creates an OSYM_TYPEDEF symbol given an Esp
 *	    	    type description in some other block. This is used
 *	    	    *only* for type descriptions that have tags associated
 *	    	    with them (like CTL_POINTER and CTL_ARRAY), not for
 *	    	    CTL_TYPEDEF descriptions.
 * CALLED BY:	    CVProcessTypeRecord
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/17/91		Initial Revision
 *
 ***********************************************************************/
static void
CV32CreateTypedef(const char    	*file,	    /* Object file from which the
					     * description came */
		byte	    	**tagPtr,   /* Pointer to CTL_STRING tree
					     * holding the name of the type */
		byte	    	*dataBase,  /* Base of record holding this
					     * potential tag */
		word	    	len,	    /* Overall length of the record */
		VMBlockHandle	typeBlock,  /* Block in symbols in which
					     * descriptor was created. */
		word	    	offset)	    /* Offset of type descriptor */
{
    /*
     * This is a really cute hack. If the type actually has a tag, as
     * determined from the position of the "tag" pointer in the record, etc.,
     * we just allocate a symbol block with an OSYM_TYPEDEF symbol in it, using
     * the passed typeBlock as the associated type block. Obj_EnterTypeSyms
     * will deal with duplicating the description. We also have to deal with
     * "empty" tags; ones that have the STRING tree, but a length of 0.
     */
    if ((*tagPtr - dataBase < len) && (**tagPtr == CTL_STRING) &&
	((*tagPtr)[1] != 0))
    {
	VMBlockHandle	tsymBlock;
	ObjSym	    	*os;
	ObjSymHeader	*osh;
	byte	    	*tagBase;

	tsymBlock = VMAlloc(symbols,
			    sizeof(ObjSymHeader) + sizeof(ObjSym),
			    OID_SYM_BLOCK);

	osh = (ObjSymHeader *)VMLock(symbols, tsymBlock, (MemHandle *)NULL);
	osh->num = 1;
	osh->types = typeBlock;
	osh->seg = 0;
	osh->next = 0;
	os = ObjFirstEntry(osh, ObjSym);

	/*
	 * Figure the name of the type and set the leaf to CTL_NIL so we don't
	 * go through this again the next time the type is referenced.
	 *
	 * XXX: change the record to a CTL_ID? Unless we also alter the
	 * type description we created in our caller to contain an ID,
	 * rather than a full type description, users will probably notice
	 * that if two variables are defined with the same typedef, only
	 * one of them shows up in Swat as having a type def. Of course,
	 * we could actually change the descriptor whose head we've been
	 * passed...hmmmmm.
	 */
	tagBase = *tagPtr;
	os->name = CV32GetString(tagPtr);
	*tagBase = CTL_NIL;

	os->type = OSYM_TYPEDEF;
	os->flags = 0;
	os->u.typeDef.type = offset;
	VMUnlockDirty(symbols, tsymBlock);

	(void)Obj_EnterTypeSyms(file, symbols, globalSeg, tsymBlock,
				OETS_TOP_LEVEL_ONLY);
	VMFree(symbols, tsymBlock);
    }
}

/***********************************************************************
 *				CV32LocateList
 ***********************************************************************
 * SYNOPSIS:	    Locate a CTL_LIST type for something.
 * CALLED BY:	    CVProcessScalar, CVProcessStructure
 * RETURN:	    FALSE if couldn't find it. Error message already given
 * SIDE EFFECTS:    *bpPtr is advanced.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/17/91		Initial Revision
 *
 ***********************************************************************/
static Boolean
CV32LocateList(const char	    *file,
	     byte   	    **bpPtr,
	     byte   	    **basePtr,
	     word   	    *lenPtr)
{
    byte    	*bp = *bpPtr;
	word leaf;


	*basePtr = CV32LocateType(bp[0] | (bp[1] << 8), lenPtr);
	if (*basePtr == NULL) {
	    Notify(NOTIFY_ERROR,
		   "%s: illegal index %d for LIST",
		   file, bp[1] | (bp[2] << 8));
	    return(FALSE);
	}
	bp += 2;

	// check and skip field list type
	MSObj_GetWord(leaf, *basePtr);
	if (leaf != CTL2_FIELDLIST) {
		Notify(NOTIFY_ERROR,
			"%s: wrong field list type %d",
			file, leaf);
		return(FALSE);
	}
	*lenPtr -= 2;

    *bpPtr = bp;
    return(TRUE);
}

/***********************************************************************
 *				CV32ProcessStructure
 ***********************************************************************
 * SYNOPSIS:	    Process a structure definition.
 * CALLED BY:	    CVProcessTypeRecord
 * RETURN:	    Offset of type descriptor for structure in typeBlock
 * SIDE EFFECTS:    Structure and field symbols will be entered in the
 *	    	    global scope.
 *
 *	    	    The CTL_STRUCTURE description is transformed into
 *	    	    our CTL_ID description.
 *
 * STRATEGY:
 *	Allocate a symbol and type block.
 *	Fetch size.
 *	Fetch # fields.
 *	Find base of type list.
 *	Allocate array of words for field types.
 *	For each field type:
 *	    process the type record into tempTypeBlock & store result
 *	    	into type array
 *	    if type word is BITFIELD with no width specified:
 *	    	if this is first BF in struct, search through $$TYPES
 *		    recording address of last transition to a BF before
 *		    current type.
 *		use next CTL_BITFIELD record in the sequence before this
 *		    list to set the width and offset of the bitfield
 *	create the main structured-type symbol
 *	foreach field name/offset:
 *	    allocate a FIELD symbol
 *	    map name to ID and store in symbol.
 *	    set type to that stored in the type array
 *	    if there's another field, set the next ptr to the next
 *	        symbol we'll allocate.
 *	    else set it to the offset of the structured-type symbol
 *	    set offset to offset in name/offset tree
 *	    if offset is same as that of previous field, note that type is
 *	    	UNION
 *	    advance field counter
 *	finish off the STRUCT/UNION symbol (the "last" pointer)
 *	allocate a type descriptor in the passed type block and
 *	    store the structure's name in there and set to return the
 *	    descriptor's offset.
 *	Obj_EnterTypeSyms(symBlock)
 *    	free the symbol and type blocks we allocated.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/14/91		Initial Revision
 *
 ***********************************************************************/
static word
CV32ProcessStructure(const char  	    *file,
		   byte	    	    **bpPtr,
		   word	    	    len,
		   VMBlockHandle    typeBlock)
{
    byte    	    *bp;    	    /* Current byte in structure record */
    byte    	    *dataBase;	    /* Base of the structure description */
    VMBlockHandle   tsymBlock,	    /* Temporary symbol block for creating
				     * structure and field symbols */
		    ttypeBlock;	    /* Temporary type block holding type
				     * descriptions for the fields */
    word    	    *types; 	    /* Array of type words to store in the
				     * field symbols */
    unsigned long   size;   	    /* Size of the structure, in bytes */
    unsigned long   nfields;	    /* Number of fields in the structure */
    byte    	    *tlistp,	    /* Current byte in field-type CTL_LIST
				     * record */
		    *tlistBase;	    /* Base of data in said record */
    word    	    tlistLen;	    /* Total length of data in said record */
//    byte    	    *nlistp,	    /* Current byte in name/offset CTL_LIST
//				     * record */
//		    *nlistBase;	    /* Base of data in said record */
    word    	    nlistLen;	    /* Total length of data in said record */
    unsigned long   i;	    	    /* Index of current field */
    byte    	    *nextBFType=0;  /* Start of CTL_BITFIELD record to use for
				     * the next bitfield in the structure */
    MemHandle	    mem;    	    /* Memory handle for tsymBlock */
    genptr	    symBase;	    /* Base of locked tsymBlock */
    ObjSym  	    *os;  	    /* Symbol being created in block */
    word    	    ssymOff,	    /* Offset of structure symbol in block */
		    fsymOff;	    /* Offset of current field symbol in
				     * block */
    byte    	    ssymType;	    /* OSYM_STRUCT or OSYM_UNION, telling
				     * symbol type for structured type */
    ID	    	    ssymName;
    byte    	    symFlags;

    word	    prop;
    word	    dlist;
    word	    shape;

    dataBase = bp = *bpPtr;

    *bpPtr += len;

    /*
     * If just scanning, skip the record and return VOID. We use this return
     * value ourselves when looking for a non-bitfield structure field.
     */
    if (typeBlock == 0) {
	return (OTYPE_VOID | OTYPE_SPECIAL);
    }

    /*
     * Allocate a symbol and associated type block for us to fill with
     * structure and field symbols...
     */
    CV32AllocSymAndTypeBlocks(&tsymBlock, &ttypeBlock);

    /*
     * Fetch the size and number of fields in the structure.
     */
    //size = CVGetInteger(&bp) / 8;
//	MSObj_GetWord(size, bp);
    MSObj_GetWord(nfields, bp);

    if (!CV32LocateList(file, &bp, &tlistBase, &tlistLen)) {
	return(OTYPE_VOID | OTYPE_SPECIAL);
    }

//    if (!CVLocateList(file, &bp, &nlistBase, &nlistLen)) {
//	return(OTYPE_VOID | OTYPE_SPECIAL);
//    }

    MSObj_GetWord(prop, bp);
    MSObj_GetWord(dlist, bp);
    MSObj_GetWord(shape, bp);

    size = CV32GetInteger(&bp) /*/ 8*/;

    if(size == 0) {

	return(OTYPE_VOID | OTYPE_SPECIAL);
    }

//    if ((bp - dataBase < len) && (*bp == CTL_STRING) &&
//	(strncmp((char *)bp+2, "(untagged)", bp[1]) != 0) &&
//	(bp[1] != 0))
    if(bp[0] != 0)
    {
	char	*tname;
	char 	*name;
	char	*prefix;
        ID	typeName;
	int	namelen;
	    
	/*
	 * The structure actually has a real name that's not the fake string
	 * uSoft C 6.0 puts in for untagged structures, and it's not the
	 * empty string HighC puts in so it can say if the structure's packed.
	 * Give the name to the structure.
	 */
	ssymName = CV32GetString(&bp);
	symFlags = 0;
	
	tname = ST_Lock(symbols, ssymName);
	prefix = "struct ";
        namelen = strlen(prefix) + strlen(tname);
        name = (char *)malloc(namelen + 1);
        sprintf(name, "%s%s", prefix, (char *)tname);
         
        typeName = ST_Enter(symbols, strings, name, namelen);
        symFlags = 0;  	/* Not nameless */
	ST_Unlock(symbols, ssymName);
        ssymName = typeName;
        free(name);
        	
    } else {
	ssymName = MSObj_MakeString();
	symFlags = OSYM_NAMELESS;
    }

    /*
     * Switch the type record to a CTL_ID *now* so if we've got any fields
     * pointing to ourselves, we won't recurse infinitely...
     */
    assert(bp-dataBase >= 4);
    dataBase[-2] = CTL2_ID & 0xff;
	dataBase[-1] = (CTL2_ID >> 8) & 0xff;
	dataBase[0]  = ssymName & 0xff;
    dataBase[1]  = (ssymName >> 8) & 0xff;
    dataBase[2]  = (ssymName >> 16) & 0xff;
    dataBase[3]  = (ssymName >> 24) & 0xff;


    types = (word *)calloc(nfields, sizeof(word));
    tlistp = tlistBase;
    //nlistp  = nlistBase;

  /*
     * Process the types of all the fields into an array. We need to do this
     * first as all the fields in the structure/union must be contiguous. This
     * won't happen if some of the fields are structures in their own right.
     */
#if 0
	for (i = 0; i < nfields; i++) {

		word thisLeaf;
		word typeIndex;
		word thislen;
		word thisOffset;

		// process thetre data records here
		MSObj_GetWord(thisLeaf, tlistp);
		tlistLen -= 2;

		// expect member
		if (thisLeaf != CTL2_MEMBER) {

			Notify(NOTIFY_ERROR, "%s: invalid member field", file);
			return(OTYPE_VOID | OTYPE_SPECIAL);
		}

		MSObj_GetWord(typeIndex, tlistp);
		tlistLen -= 2;

		types[i] = CVLocateType(typeIndex, &thislen);

	if ((types[i] == (OTYPE_BITFIELD | OTYPE_SPECIAL)) &&
	    ((types[i] & OTYPE_BF_WIDTH) == 0))
	{
	    /*
	     * If the thing's a bitfield that's not been decoded yet, locate
	     * the proper BITFIELD record (thanks, HighC) and set up the
	     * special type appropriately. Why do I thank HighC? Because their
	     * compiler generates a type list for a structure where the
	     * type indices for all bitfields are 1. All the CTL_BITFIELD
	     * records are emitted just before the fieldtype list, however,
	     * so we go questing for all those little records and use them
	     * in sequence...yuck.
	     */
	    if (nextBFType == 0) {
		/*
		 * Haven't bothered to locate the first CTL_BITFIELD record
		 * before the type list. Do so now.
		 */
		byte	*tp;
		byte	lastType;
		byte	thisType;
		word	len;

		lastType = CTL_STRUCTURE;

		for (tp = typeSeg; tp < tlistBase; tp += len) {
		    tp++;	/* Skip linkage, damn you */
		    MSObj_GetWord(len, tp);
		    thisType = *tp;
		    if ((thisType==CTL_BITFIELD) && (lastType!=CTL_BITFIELD)) {
			nextBFType = tp-3;
		    }
		    lastType = thisType;
		}
	    }
	    if ((nextBFType == 0) || (nextBFType[3] != CTL_BITFIELD)) {
		Notify(NOTIFY_ERROR, "%s: invalid structure descriptor (no bitfield descriptor before field-type list)", file);
		return(OTYPE_VOID | OTYPE_SPECIAL);
	    }

	    nextBFType += 3;
	    types[i] =
		CVProcessTypeRecord(file,
				    &nextBFType,
				    nextBFType[-2] | (nextBFType[-1] << 8),
				    ttypeBlock);
	}
    }
#endif

    /*
     * Now allocate a STRUCT or UNION symbol for the thing. Start with
     * A STRUCT for now. If we find non-bitfield fields whose offsets are
     * the same, or bitfield fields whose bit offsets are the same, we'll
     * switch it to be a union...
     */     
    os = CV32AllocSym(tsymBlock, &ssymOff);
    ssymType = OSYM_STRUCT;
    os->flags = symFlags;
    os->name = ssymName;
	os->u.sType.size = size;
    os->u.sType.first = ssymOff + sizeof(ObjSym);
    os->u.sType.last = ssymOff + nfields * sizeof(ObjSym);

      /*
     * Fetch the base and memory handle of the symbol block so we don't
     * have to VMLock the thing each time -- it's already been locked
     * by the first CVAllocSym
     */
    VMInfo(symbols, tsymBlock, (word *)NULL, &mem, (VMID *)NULL);
    MemInfo(mem, (genptr *)&symBase, (word *)NULL);

    for (i = 0; i < nfields; i++) {
	//if (*nlistp != CTL_STRING) {
	//    Notify(NOTIFY_ERROR,
	//	   "%s: invalid structure descriptor (field name not CTL_STRING tree)",
	//	   file);
	//    break;
	//}

		word thisLeaf;
		word typeIndex;
		word thislen;
		word thisOffset;
		word offset;
		word attr;
		byte pad;

		// process thetre data records here
		MSObj_GetWord(thisLeaf, tlistp);
		tlistLen -= 2;

		// expect member
		if (thisLeaf != CTL2_MEMBER) {

			Notify(NOTIFY_ERROR, "%s: invalid member field", file);
			return(OTYPE_VOID | OTYPE_SPECIAL);
		}

		MSObj_GetWord(typeIndex, tlistp);
		tlistLen -= 2;


		MSObj_GetWord(attr, tlistp);
		tlistLen -= 2;

		offset = CV32GetInteger(&tlistp);

	os = CV32AllocSymLocked(tsymBlock, mem, &fsymOff,
			      (ObjSymHeader **)&symBase);
	os->type = OSYM_FIELD;
	os->name = CV32GetString(&tlistp);
	os->flags = 0;
	os->u.sField.offset = offset;
	types[i] = CV32FetchType(file, ttypeBlock, typeIndex);
	os->u.sField.type = types[i];

	/*
	 * If this isn't the last field, point the field to the next one we'll
	 * allocate. If it is the last field, point the thing back at the
	 * structure symbol.
	 */
	if (i != nfields - 1) {
	    os->u.sField.next = fsymOff + sizeof(ObjSym);
	} else {
	    os->u.sField.next = ssymOff;
	}

	/*
	 * This one's fun: the type description doesn't distinguish between a
	 * union and a structure, except in the offsets for the various fields.
	 * So to figure this out, we see if two adjacent fields have the same
	 * offset. Of course, this doesn't work for bitfields, as they all
	 * have the same offset. However, declaring bitfields within a union
	 * causes all of them to have the same bit offset, so if both the
	 * current and the previous fields are bitfields at the same byte
	 * offset, and the bit offsets are the same, or if either field
	 * isn't a bitfield, but they have the same offset, the thing's a
	 * union.
	 */
	if ((ssymType == OSYM_STRUCT) &&
	    (i != 0) &&
	    (os->u.sField.offset == os[-1].u.sField.offset) &&
	    (((types[i] & OTYPE_TYPE) != OTYPE_BITFIELD) ||
	     ((types[i-1] & OTYPE_TYPE) != OTYPE_BITFIELD) ||
	     ((types[i] & OTYPE_BF_OFFSET) == (types[i-1] & OTYPE_BF_OFFSET))))
	{
	    ssymType = OSYM_UNION;
	}
	/*
	 * One more little piece of joy in this department.  MASM doesn't
	 * like to tell us fields are an array, but gives us the base type.
	 * We have to figure the # of elements out for ourselves. We may
	 * want to handle this in the future.
	 */

	pad = *tlistp;
	if (pad > 0xf0) {
		tlistp += pad & 0x0f;
	}
    }

    free((void *)types);

    os = (ObjSym *)(symBase + ssymOff);
    os->type = ssymType;

    if (os->flags & OSYM_NAMELESS) {
	MSObj_AddAnonStruct(os, ttypeBlock, size, nfields);
    }

    return CV32FinishStructuredType(file, dataBase, len, os,
				  tsymBlock, ttypeBlock,
				  typeBlock);
}


/***********************************************************************
 *				CV32ProcessArray
 ***********************************************************************
 * SYNOPSIS:	    Process an array type description.
 * CALLED BY:	    CVProcessTypeRecord
 * RETURN:	    The offset of the Esp type description in the passed
 *	    	    typeBlock of the final result.
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/17/91		Initial Revision
 *
 ***********************************************************************/
static word
CV32ProcessArray(const char    	*file,
	       byte 	    	**bpPtr,
	       word 	    	len,
	       VMBlockHandle	typeBlock)
{
    byte    	*bp = *bpPtr;
    word    	retval = OTYPE_VOID | OTYPE_SPECIAL;
    byte    	*dataBase = bp;

    if (typeBlock != 0) {
	unsigned long   alen;	    /* Length of the array, first in bits,
				     * then in elements */
	word	    	elType;	    /* Esp type of array element */
	unsigned	elSize;	    /* Size of an array element (bytes) */
	genptr		typeBase;  /* Base of typeBlock, so we can determine
				     * elSize */
	MemHandle   	mem;	    /* Memory handle of typeBlock so we can
				     * update typeBase if we need to allocate
				     * more than one ObjType record */
	word index;
	word idxTypeIndex;

	/*
	 * Get a descriptor for the element type.
	 */
	MSObj_GetWord(index, bp);
	elType = CV32FetchType(file, typeBlock, index);

	MSObj_GetWord(idxTypeIndex, bp);

	//if ((*bpPtr)[-3] == CTL_STRING_TYPE) {
	//	elType = OTYPE_CHAR | OTYPE_SPECIAL;
	//}
	//else {
	//	elType = CVProcessTypeRecord(file,
	//		&bp,
	//		bp[1] | (bp[2] << 8),
	//		typeBlock);
	//}


	/*
	 * Figure the length of the array (bits)
	 */
	alen = CV32GetInteger(&bp);


	/*
	 * Find the size of the element so we know how many elements
	 * there are in the array.
	 */
	typeBase = VMLock(symbols, typeBlock, &mem);
	elSize = Obj_TypeSize(elType, typeBase, FALSE);
	VMUnlock(symbols, typeBlock);

	//if (alen % 8) {
	//    Notify(NOTIFY_ERROR,
	//	   "%s: Non-integral # bytes in array",
	//	   file);
	//}
	//alen >>= 3;

	if (alen % elSize) {
	    Notify(NOTIFY_ERROR,
		   "%s: Non-integral # elements in array",
		   file);
	}

	/*
	 * If # elts > OTYPE_MAX_ARRAY_LEN, need to allocate another
	 * chained descriptor to give the number over
	 * OTYPE_MAX_ARRAY_LEN. This continues until the number of
	 * elements is <= OTYPE_MAX_ARRAY_LEN, with the final
	 * ObjType.
	 */
	alen /= elSize;

	retval = MSObj_CreateArrayType(typeBlock, elType, alen);
	VMUnlock(symbols, typeBlock);

	if ((bp - dataBase) < len) {
	    if (*bp != CTL_NIL) {
		/*
		 * Skip over the index type, but make sure it's a
		 * signed or unsigned integer or a char.
		 */
		word	idxType;

		idxType = CV32FetchType(file, typeBlock, idxTypeIndex);

		if (!(idxType & OTYPE_SPECIAL) ||
		    (((idxType & OTYPE_TYPE) != OTYPE_INT) &&
		     ((idxType & OTYPE_TYPE) != OTYPE_SIGNED) &&
		     ((idxType & OTYPE_TYPE) != OTYPE_CHAR)))
		{
		    Notify(NOTIFY_WARNING,
			   "%s: array index types not supported -- defaulting to int",
			   file);
		}
	    } else {
		/*
		 * Skip the NIL leaf that indicates no index type used.
		 */
		bp++;
	    }

	    /*
	     * Deal with any typedef tag at the end of the descriptor.
	     */
	    CV32CreateTypedef(file,
			    &bp,
			    dataBase,
			    len,
			    typeBlock,
			    retval);
	}
    }
    *bpPtr += len;
    return(retval);
}

/***********************************************************************
 *				CV32ProcessScalar
 ***********************************************************************
 * SYNOPSIS:	    Process a scalar type. For now this only handles
 *	    	    enums, not type ranges.
 * CALLED BY:	    CVProcessTypeRecord
 * RETURN:	    offset of ObjType for the scalar
 * SIDE EFFECTS:    Record is converted to a CTL_ID record...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/17/91		Initial Revision
 *
 ***********************************************************************/
static word
CV32ProcessScalar(const char    	*file,  	/* Object file from which
						 * the record came */
		byte	    	**bpPtr,   	/* Start of the record's data */
		word	    	len,    	/* Length of data in it */
		VMBlockHandle	typeBlock)	/* Block in which to
						 * allocate needed type
						 * descriptors */
{
    word			size;   	    /* Size of the scalar, in bits */
    ID	    	    name;   	    /* Name for the scalar */
    byte    	    *bp = *bpPtr;   /* Current position in the record */
    word    	    retval; 	    /* Value we're going to return */
    word			enumTypeIndex;
    word			fieldTypeIndex;

    /*
     * Fetch the size of the scalar (bits)
     */
    MSObj_GetWord(size, bp);
    MSObj_GetWord(enumTypeIndex, bp);
    /*
     * We only allow scalars based on signed and unsigned integers around here.
     * Set retval to the appropriate special base type according to whether the
     * thing is signed or unsigned, in case there are no members specified.
     */

    if (enumTypeIndex == CSTT2_CHAR) {
	retval = OTYPE_SIGNED | (size << 1) | OTYPE_SPECIAL;
    } else if ((enumTypeIndex == CSTT2_SHORT) || (enumTypeIndex == CSTT2_USHORT)) {
	retval = OTYPE_INT | (2 << 1) | OTYPE_SPECIAL;
    } else {
	Notify(NOTIFY_ERROR,
	       "%s: unknown scalar base type %02.2x",
	       file, enumTypeIndex);
error:
	retval = OTYPE_VOID | OTYPE_SPECIAL;
	goto done;

    }
    //bp++;			/* Skip the base type */
	fieldTypeIndex = MSObj_GetWordImm(bp);	/* field index */
	MSObj_GetWordImm(bp);	/* property */

    /*
     * Figure the name of the type, if any given.
     */
    name = NullID;
    if ((bp - *bpPtr) < len) {
	    
	name = CV32GetString(&bp);
	
	if(name != NullID) {
		
	    char	*tname;
	    char	*prefix;
	    int		namelen;
	    ID		typeName;
	    char	*newName;

	    tname = ST_Lock(symbols, name);
	    prefix = "enum ";
            namelen = strlen(prefix) + strlen(tname);
            newName = (char *)malloc(namelen + 1);
            sprintf(newName, "%s%s", prefix, (char *)tname);
         
            typeName = ST_Enter(symbols, strings, newName, namelen);
	    ST_Unlock(symbols, name);
	
            name = typeName;
            free(newName);
    	}
    }

    if (fieldTypeIndex) {

		//word fieldTypeLen;
		//byte* fieldType = CVLocateType(fieldTypeIndex, &fieldTypeLen);

	    /*
	     * This thing's actually an enum (damn good thing, too). Create
	     * an OSYM_ETYPE structure for it and enter the beast.
	     */
	    byte    	    *mlistp,	    /* Current position in member list
					     * record */
			    *mlistBase;	    /* Base of member list record */
	    word    	    mlistLen;	    /* Total length of the member list
					     * record's data */
	    ObjSym  	    *esym;  	    /* ETYPE symbol */
	    word    	    esymOff;	    /* Offset of same in tsymBlock */
	    ObjSym  	    *msym;  	    /* ENUM member symbol */
	    word    	    msymOff;	    /* Offset of same in tsymBlock */
	    genptr	    symBase;	    /* Base of locked tsymBlock */
	    MemHandle	    mem;    	    /* Memory handle of same */
	    VMBlockHandle   tsymBlock;	    /* Block in which Esp symbols are
					     * allocated for the type
					     * definition */
	    VMBlockHandle   ttypeBlock;	    /* Associated type block (shouldn't
					     * be used at all...) */
	    byte    	    symflags;	    /* Flags to give to esym */

	    /*
	     * Locate the CTL_LIST record that holds the list of members
	     */
		bp = &fieldTypeIndex;
	    if (!CV32LocateList(file, &bp, &mlistBase, &mlistLen)) {
		goto error;
	    }

	    /*
	     * If this is actually an enum, we need to have a real name for
	     * the thing, even if we mark the beggar as nameless.
	     */
	    if (name == NullID) {
		word leaf;

		mlistp = mlistBase;
		leaf = MSObj_GetWordImm(mlistp);
		/*
		 * If the beggar is nameless, see if we've encountered the type
		 * before by looking for the first element of the type in the
		 * global segment.
		 */
		if (leaf == CTL2_ENUMERATIO) {
		    ID	first;

		    MSObj_GetWordImm(mlistp);	/* attr */
		    MSObj_GetWordImm(mlistp);	/* value */
		    first = CV32GetString(&mlistp);
		    if ((first != NullID) && Sym_Find(symbols, globalSeg->syms,
						      first, &tsymBlock,
						      &msymOff, FALSE))
		    {
			/*
			 * Well, the first member is in the global segment,
			 * so skip through the "next" pointers until we get
			 * back to the enumerated type itself.
			 */
			symBase = VMLock(symbols, tsymBlock, (MemHandle *)NULL);

			for (msym = (ObjSym *)(symBase + msymOff);
			     msym->type == OSYM_ENUM;
			     msym = (ObjSym *)(symBase + msym->u.eField.next))
			{
			    ;
			}

			/*
			 * Use the previous name and flags. Doing this, rather
			 * than just saying we've found the type, allows us
			 * to type-check between modules.
			 */
			name = msym->name;
			symflags = (msym->flags & OSYM_NAMELESS);
			VMUnlock(symbols, tsymBlock);
		    } else {
			name = MSObj_MakeString();
			symflags = OSYM_NAMELESS;
		    }
		} else {
		    name = MSObj_MakeString();
		    symflags = OSYM_NAMELESS;
		}
	    } else {
		symflags = 0;
	    }

	    /*
	     * Allocate a symbol and (never-used) associated type block for
	     * this definition.
	     */
	    CV32AllocSymAndTypeBlocks(&tsymBlock, &ttypeBlock);

	    /*
	     * Allocate and initialize an ETYPE Esp symbol.
	     */
	    esym = CV32AllocSym(tsymBlock, &esymOff);
	    esym->type = OSYM_ETYPE;
	    esym->u.sType.size = 2;
	    esym->u.sType.first = esymOff + sizeof(ObjSym);
	    esym->flags = symflags;
	    esym->name = name;

	    /*
	     * Fetch the base and memory handle of the symbol block so we don't
	     * have to VMLock the thing each time -- it's already been locked
	     * by the first CVAllocSym
	     */
	    VMInfo(symbols, tsymBlock, (word *)NULL, &mem, (VMID *)NULL);
	    MemInfo(mem, (genptr *)&symBase, (word *)NULL);

	    mlistp = mlistBase;

	    assert(mlistLen != 0);

	    /*
	     * Now loop through all the members, creating ENUM symbols for each
	     * one.
	     */
		while(1) {
			word leaf = MSObj_GetWordImm(mlistp);

			if (leaf != CTL2_ENUMERATIO) {
				Notify(NOTIFY_ERROR,
					"%s: invalid scalar descriptor (member name not CTL_STRING tree)",
					file);
				break;
			}
			MSObj_GetWordImm(mlistp);	/* attr */

			msym = CV32AllocSymLocked(tsymBlock, mem, &msymOff,
				(ObjSymHeader **)&symBase);
			msym->u.eField.value = CV32GetInteger(&mlistp);
			msym->type = OSYM_ENUM;
			msym->name = CV32GetString(&mlistp);
			msym->flags = 0;

			if (*mlistp > 0xf0) {
				mlistp += *mlistp & 0x0f;
			}

			/*
			 * Set up linkage. If this was not the last member, the next
			 * member will be allocated immediately after this one. If
			 * it is the last member, we have to point the beggar back
			 * to the ETYPE symbol, then get out of the loop.
			 */
			if ((mlistp - mlistBase) < mlistLen) {
				msym->u.eField.next = msymOff + sizeof(ObjSym);
			}
			else {
				msym->u.eField.next = esymOff;
				break;
			}

		}

	    /*
	     * Set the "last" pointer for the ETYPE to be the offset of the
	     * last member entered.
	     */
	    esym = ((ObjSym *)(symBase + esymOff));
	    esym->u.sType.last = msymOff;

	    /*
	     * Enter this thing in the global segment. This will also transmute
	     * the CTL_SCALAR record into a CTL_ID record...
	     */
	    retval = CV32FinishStructuredType(file, *bpPtr, len, esym,
					    tsymBlock, ttypeBlock,
					    typeBlock);
	}

    done:

    *bpPtr += len;
    return(retval);
}


/***********************************************************************
 *				CV32FetchType
 ***********************************************************************
 * SYNOPSIS:	    Decode a CodeView type for a symbol, given its index.
 * CALLED BY:	    CVProcessCodeViewRecords,?
 * RETURN:	    The type word to place in the symbol.
 * SIDE EFFECTS:    Type descriptors may be allocated in the passed block.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 8/91		Initial Revision
 *
 ***********************************************************************/
static word
CV32FetchType(const char 	    *file,  	/* Object file being read */
	    VMBlockHandle   typeBlock,	/* Type block associated with the
					 * symbol being created */
	    unsigned   	    index)  	/* Index of type being fetched */
{
    word    retval;

    if (index <= CST_LAST_PREDEF) {

		switch (index) {
		case CSTT2_VOID:
			retval = OTYPE_VOID | OTYPE_SPECIAL;
			break;
		case CSTT2_RCHAR:
		case CSTT2_CHAR:
			retval = OTYPE_CHAR | OTYPE_SPECIAL | (0 << 1);
			break;
		case CSTT2_INT2:
		case CSTT2_SHORT:
			retval = OTYPE_SIGNED | OTYPE_SPECIAL | (2 << 1);
			break;
		case CSTT2_UINT2:
		case CSTT2_USHORT:
			retval = OTYPE_INT | OTYPE_SPECIAL | (2 << 1);
			break;
		case CSTT2_LONG:
				retval = OTYPE_SIGNED | OTYPE_SPECIAL | (4 << 1);
				break;
		case CSTT2_ULONG:
			retval = OTYPE_INT | OTYPE_SPECIAL | (4 << 1);
			break;
		case CSTT2_UCHAR:
			retval = OTYPE_CHAR | OTYPE_SPECIAL | (0 << 1);
			break;
		case CSTT2_PVOID:
		case CSTT2_PCHAR:
		case CSTT2_PSHORT:
		case CSTT2_PLONG:
		case CSTT2_PUSHORT:
		case CSTT2_PULONG:
		case CSTT2_PRCHAR:
		case CSTT2_PUCHAR:
		case CSTT2_PINT2:
		case CSTT2_PUINT2:
			retval = OTYPE_PTR | OTYPE_PTR_NEAR | OTYPE_SPECIAL;
			break;
		case CSTT2_PFVOID:
		case CSTT2_PFCHAR:
		case CSTT2_PFSHORT:
		case CSTT2_PFLONG:
		case CSTT2_PFUSHORT:
		case CSTT2_PFULONG:
		case CSTT2_PFRCHAR:
		case CSTT2_PFUCHAR:
		case CSTT2_PFINT2:
		case CSTT2_PFUINT2:
		case CSTT2_PFREAL32:
		case CSTT2_PFREAL64:
			retval = OTYPE_PTR | OTYPE_PTR_FAR | OTYPE_SPECIAL;
			break;
		case CSTT2_REAL32:
            retval = OTYPE_MAKE_FLOAT(4);
    		break;
		case CSTT2_REAL64:
    		retval = OTYPE_MAKE_FLOAT(8);
    		break;

		default:
			Notify(NOTIFY_ERROR,
				"%s: unsupported special type %02.2x",
				file, index);
			retval = OTYPE_VOID | OTYPE_SPECIAL;
			break;
		}
#if 0
	if (index & CST_SPECIAL) {
	    if ((index &  CST_MODE) != CSTM_DIRECT) {
		word	baseType;

		baseType = CVFetchType(file,
				       typeBlock,
				       (index & ~CST_MODE)|CSTM_DIRECT);

		if (baseType == (OTYPE_VOID | OTYPE_SPECIAL)) {
		    switch (index & CST_MODE) {
			case CSTM_NEAR:
			    retval = OTYPE_PTR | OTYPE_PTR_NEAR | OTYPE_SPECIAL;
			    break;
			case CSTM_FAR:
			    retval = OTYPE_PTR | OTYPE_PTR_FAR | OTYPE_SPECIAL;
			    break;
			case CSTM_HUGE:
			    Notify(NOTIFY_ERROR,
				   "%s: HUGE pointers not unsupported",
				   file);
			    retval = OTYPE_VOID | OTYPE_SPECIAL;
			    break;
		    }
		} else {
		    ObjType	*ot;

		    ot = MSObj_AllocType(typeBlock, &retval);
		    switch (index & CST_MODE) {
			case CSTM_NEAR:
			    ot->words[0] = OTYPE_PTR_NEAR | OTYPE_SPECIAL;
			    if (baseType == (OTYPE_FAR | OTYPE_SPECIAL)) {
				baseType = (OTYPE_NEAR | OTYPE_SPECIAL);
			    }
			    break;
			case CSTM_FAR:
			    ot->words[0] = OTYPE_PTR_FAR | OTYPE_SPECIAL;
			    break;
			case CSTM_HUGE:
			    Notify(NOTIFY_ERROR,
				   "%s: HUGE pointers not supported",
				   file);
			    retval = OTYPE_VOID | OTYPE_SPECIAL;
			    break;
		    }
		    ot->words[1] = baseType;
		    VMUnlockDirty(symbols, typeBlock);
		}
	    } else {
		static const word sizes[4][4] = {
#define CV_RESERVED_SIZE 0xffff
#define CVSIZE_INT  0
		    { 1, 2, 4, CV_RESERVED_SIZE },
#define CVSIZE_FLOAT 1
	            { 4, 8, 10, CV_RESERVED_SIZE },
#define CVSIZE_COMPLEX 2
		    { 8, 16, 20, CV_RESERVED_SIZE },
#define CVSIZE_CURRENCY 3
		    { CV_RESERVED_SIZE, 8, CV_RESERVED_SIZE,  CV_RESERVED_SIZE }
		};
		int 	sizeIdx;

		switch(index & CST_TYPE) {
		    case CSTT_SIGNED:
			retval = OTYPE_SIGNED | OTYPE_SPECIAL;
			sizeIdx = CVSIZE_INT;
			break;
		    case CSTT_UNSIGNED:
			retval = OTYPE_INT | OTYPE_SPECIAL;
			sizeIdx = CVSIZE_INT;
			break;
		    case CSTT_REAL:
			retval = OTYPE_FLOAT | OTYPE_SPECIAL;
			sizeIdx = CVSIZE_FLOAT;
			break;
		    case CSTT_COMPLEX:
			retval = OTYPE_COMPLEX | OTYPE_SPECIAL;
			sizeIdx = CVSIZE_COMPLEX;
			break;
		    case CSTT_BOOLEAN:
			retval = OTYPE_INT | OTYPE_SPECIAL;
			sizeIdx = CVSIZE_INT;
			break;
		    case CSTT_ASCII:
			retval = OTYPE_CHAR | OTYPE_SPECIAL;
			sizeIdx = CVSIZE_INT;
			break;
		    case CSTT_CURRENCY:
			retval = OTYPE_CURRENCY | OTYPE_SPECIAL;
			sizeIdx = CVSIZE_CURRENCY;
			break;
		    default:
			Notify(NOTIFY_ERROR,
			       "%s: unsupported special type %02.2x",
			       file, index & CST_TYPE);
			retval = OTYPE_VOID | OTYPE_SPECIAL;
			sizeIdx = CVSIZE_INT;
			break;
		}
		if (sizes[sizeIdx][index & CST_SIZE] == CV_RESERVED_SIZE) {
		    Notify(NOTIFY_ERROR,
			   "%s: illegal size index %02.2x",
			   file, index & CST_SIZE);
		} else {
		    retval |= sizes[sizeIdx][index & CST_SIZE] << 1;
		}
	    }
	} else {
	    switch(index) {
		case 0:	/* NOTYPE */
		    retval = OTYPE_VOID | OTYPE_SPECIAL;
		    break;
		case 1:	/* ABSOLUTE -- also used for bitfields */
		    retval = OTYPE_BITFIELD | OTYPE_SPECIAL;
		    break;
		default:
		    Notify(NOTIFY_ERROR,
			   "%s: unsupported special type index 0x%x",
			   file, index);
		    retval = OTYPE_VOID | OTYPE_SPECIAL;
		    break;
	    }
	}
#endif
    } else {
	byte	*bp;
	word	len;
	bp = CV32LocateType(index, &len);
	if (bp == NULL) {
	    Notify(NOTIFY_ERROR,
		   "%s: undefined type index 0x%x", file, index);
	    return (OTYPE_VOID | OTYPE_SPECIAL);
	}
	retval = CV32ProcessTypeRecord(file, &bp, len, typeBlock);
    }

    return(retval);
}

/***********************************************************************
 *				CV32ProcessTypeRecord
 ***********************************************************************
 * SYNOPSIS:	    Process a single CodeView type record
 * CALLED BY:	    CVFetchType
 * RETURN:	    type descriptor word
 * SIDE EFFECTS:    ObjType's may be allocated in the passed block.
 *
 * STRATEGY:
 *	XXX: maybe pass tsymBlock and ttypeBlock when we recurse to avoid
 *	excessive Obj_EnterTypeSyms/VMAlloc/VMFree calls...?
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/11/91		Initial Revision
 *
 ***********************************************************************/
static word
CV32ProcessTypeRecord(const char 	    *file,  	/* Object file from which
						 * the record came */
		    byte	    **bpPtr,   	/* Start of the record */
		    word	    len,    	/* Length of data in it */
		    VMBlockHandle   typeBlock)	/* Block in which to
						 * allocate needed type
						 * descriptors */
{

    word    retval = OTYPE_VOID | OTYPE_SPECIAL;
	byte    *bp = *bpPtr;
	byte    *endp = *bpPtr + len;
	byte    *dataBase;
	dataBase = bp;

	// process leafs
	while (bp < endp) {

		word leaf;
		word argsCount;
		MSObj_GetWord(leaf, bp);

		// process leaf
		switch (leaf) {
		case CTL2_PROCEDURE:
		{
			/* Must be because there's a pointer to a function. We can't
			* communicate the params/names/types/etc. in a type
			* description, so we just return OTYPE_FAR. Swat'll do
			* pretty much the right thing with it... */
			/*if (*bp++ != CTL_NIL) {
				Notify(NOTIFY_ERROR,
					"%s: PROCEDURE definition missing spurious NIL leaf",
					file);
			}
			else {*/
				/*
				* Skip over the return type.
				*/
				word rvType;
				word argsCount;
				word argsList;
				MSObj_GetWord(rvType, bp);

				//(void)CVProcessTypeRecord(file,
				//	&bp,
				//	bp[1] | (bp[2] << 8),
				//	0);
				if ((*bp == CCC2_C_NEAR) || (*bp == CCC2_PASCAL_NEAR)) {
					retval = OTYPE_NEAR | OTYPE_SPECIAL;
				}
				else if ((*bp == CCC2_C_FAR) || (*bp == CCC2_PASCAL_FAR)) {
					retval = OTYPE_FAR | OTYPE_SPECIAL;
				}
				else {
					Notify(NOTIFY_ERROR,
						"%s: Unknown call-type (%02.2x) in PROCEDURE definition",
						file, *bp);
				}
			/*}*/

			/*
			* Skip over the rest of the record.
			*
			* mcasadevall: THere's no length record anymore for procedures, so
			* we calculate the length to jump based off the arg count and ignore
			* the len variable.
			*/

			// Move bp past reserved value
			bp += 2;
			MSObj_GetWord(argsCount, bp);
			MSObj_GetWord(argsList, bp); // argsList pointer

			bp = *bpPtr + len;
			break;
		}

		case CTL2_MODIFIER:
		{
			word	attrib;
			word	index;
			MSObj_GetWord(attrib, bp);
			MSObj_GetWord(index, bp);

			retval = CV32FetchType(file, typeBlock, index);
			break;
		}
		case CTL2_POINTER:
		{
			byte    ptrType;
			word    baseType;
			word	attrib;
			MSObj_GetWord(attrib, bp);

			ptrType = attrib & 0x1F;

			MSObj_GetWord(baseType, bp);

			baseType = CV32FetchType(file, typeBlock, baseType);

			switch (ptrType) {
			case 0:	//CTL_NEAR_PTR:
				retval = OTYPE_PTR | OTYPE_PTR_NEAR | OTYPE_SPECIAL;
				break;
			case 1: //CTL_FAR_PTR:
				retval = OTYPE_PTR | OTYPE_PTR_FAR | OTYPE_SPECIAL;
				break;
			case 9: //based on self
				retval = OTYPE_INT | OTYPE_SPECIAL | (2 << 1);
				break;
			default:
				Notify(NOTIFY_ERROR,
					"%s: unhandled pointer type (%02.2x)",
					file, ptrType);
			}

			if (baseType != (OTYPE_VOID | OTYPE_SPECIAL)) {
				/*
				* Pointer to something interesting -- allocate a type
				* record for our result and fill it in appropriately.
				*/
				ObjType *ot;
				word	tOffset;

				ot = MSObj_AllocType(typeBlock, &tOffset);
				ot->words[0] = retval;
				ot->words[1] = baseType;
				retval = tOffset;
				VMUnlockDirty(symbols, typeBlock);
			}

			/*
			* Deal with any typedef tag at the end of the descriptor.
			* XXX: HighC puts out a CTL_TYPEDEF record, and names pointers
			* using this method, so we're doing extra shit...
			*/
/*			CVCreateTypedef(file,
				&bp,
				dataBase,
				len,
				typeBlock,
				retval);*/
			break;
		}
		break;
		case CTL2_ARRAY:
			retval = CV32ProcessArray(file, &bp, len - 2, typeBlock);
			break;
		case CTL2_CLASS:
		case CTL2_STRUCTURE:
			retval = CV32ProcessStructure(file, &bp, len - 2, typeBlock);
			break;
		case CTL2_MEMBER:
			retval = CV32ProcessStructure(file, &bp, len - 2, typeBlock);
			break;
		case CTL2_ID:
		{
			ObjType 	*ot;

			ot = MSObj_AllocType(typeBlock, &retval);
			MSObj_GetWord(ot->words[0], bp);
			MSObj_GetWord(ot->words[1], bp);
			VMUnlockDirty(symbols, typeBlock);
			/*
			* Skip over left-over bytes
			*/
			bp = *bpPtr + len;
			break;
		}
		case CTL2_UNION:
		{
			word count;
			word baseType;
			word properties;
			unsigned long size;
			ID name;   	    /* Name of the union */

			MSObj_GetWord(count, bp);
			MSObj_GetWord(baseType, bp);
			MSObj_GetWord(properties, bp);

			size = CV32GetInteger(&bp);

			name = NullID;
			if ((bp - *bpPtr) < (len-2)) {
				name = CV32GetString(&bp);
			}
			bp = *bpPtr + len;
			break;
		}
		case CTL2_ENUMERATION:
		{
			retval = CV32ProcessScalar(file, &bp, len - 2, typeBlock);
			break;
		}
		case CTL2_BITFIELD:
		{
			byte length;
			byte position;
			word baseType;
			bp++;
			length = *bp;
			bp++;
			position = *bp;

			MSObj_GetWord(baseType, bp);
			retval = OTYPE_BITFIELD | OTYPE_SPECIAL;
			break;
		}
		default:
			printf("ERROR: Unable to parse %x type\r\n", leaf);
		}
	}

#if 0
    byte    typeClass;
    byte    *dataBase;
	byte    *bp = *bpPtr;

    typeClass = *bp++;
    dataBase = bp;

    switch(typeClass) {
	case CTL_VOID:
	    /* retval already set to void, and bp already advanced */
	    break;
	case CTL_INDEX:
	    /*
	     * No length word after this typeClass, just a type index.
	     * If we're not just skipping things, look up the type description
	     * for the index that's just before our adjusted bp and recursively
	     * process that description.
	     */
	    if (typeBlock != 0) {
		retval = CVFetchType(file, typeBlock, bp[0] | (bp[1] << 8));
	    }
	    bp += 2;
	    break;
	case CTL_BITFIELD:
	{
	    word    offset, length;

	    retval = OTYPE_BITFIELD | OTYPE_SPECIAL;

	    length = CVGetInteger(&bp);
	    if (*bp == CTL_SIGNED_INT) {
		retval |= OTYPE_BF_SIGNED;
	    } else if (*bp != CTL_UNSIGNED_INT) {
		Notify(NOTIFY_ERROR,
		       "%s: bitfield's base type must be signed or unsigned int",
		       file);
		retval = OTYPE_VOID | OTYPE_SPECIAL;
		bp = dataBase + len;
		break;
	    }
	    bp++;
	    offset = CVGetInteger(&bp);
	    retval |= ((offset << OTYPE_BF_OFFSET_SHIFT) & OTYPE_BF_OFFSET) |
		((length << OTYPE_BF_WIDTH_SHIFT) & OTYPE_BF_WIDTH);
	    break;
	}
	default:
	    Notify(NOTIFY_ERROR,
		   "%s: unsupported type record class %02.2x",
		   file, typeClass);
	    /*FALLTHRU*/
	case CTL_LIST:
	case CTL_SKIP_ME:
	    bp += len;
	    break;
	case CTL_TYPEDEF:
	{
	    /* Create OSYM_TYPEDEF, setting the type to the type record
	     * pointed to by this record, then replace this record by the
	     * ID of the type definition as a CTL_ID record */
	    VMBlockHandle   tsymBlock;
	    VMBlockHandle   ttypeBlock;
	    word    	    equivType;
	    ObjSym  	    *os;
	    word    	    symOff;

	    if (typeBlock == 0) {
		/*
		 * Just skipping the description -- do so and boogie.
		 */
		bp += len;
		break;
	    }

	    /*
	     * Need to allocate a TYPEDEF symbol
	     */
	    CVAllocSymAndTypeBlocks(&tsymBlock, &ttypeBlock);
	    equivType = CVProcessTypeRecord(file,
					    &bp,
					    bp[1] | (bp[2] << 8),
					    ttypeBlock);
	    os = CVAllocSym(tsymBlock, &symOff);
	    os->type = OSYM_TYPEDEF;
	    os->flags = 0;
	    os->name = CVGetString(&bp);
	    os->u.typeDef.type = equivType;
	    retval = CVFinishStructuredType(file, dataBase, len-1, os,
					    tsymBlock, ttypeBlock, typeBlock);
	    break;
	}
	case CTL_PARAMETER:
	case CTL_CONSTANT:
	    Notify(NOTIFY_ERROR,
		   "%s: can't handle parameter/constant -- Microsoft didn't define them.",
		   file);
	    break;
	case CTL_LABEL:
	    /* Return OTYPE_NEAR or OTYPE_FAR */
	    if (*bp++ != CTL_NIL) {
		Notify(NOTIFY_ERROR,
		       "%s: LABEL definition missing spurious NIL leaf",
		       file);
	    } else if (*bp == CTL_NEAR) {
		retval = OTYPE_NEAR | OTYPE_SPECIAL;
	    } else if (*bp == CTL_FAR) {
		retval = OTYPE_FAR | OTYPE_SPECIAL;
	    } else {
		Notify(NOTIFY_ERROR,
		       "%s: Unknown type (%02.2x) in LABEL definition",
		       file, *bp);
	    }
	    bp = dataBase + len;
	    break;
	case CTL_PROCEDURE:
	    /* Must be because there's a pointer to a function. We can't
	     * communicate the params/names/types/etc. in a type
	     * description, so we just return OTYPE_FAR. Swat'll do
	     * pretty much the right thing with it... */
	    if (*bp++ != CTL_NIL) {
		Notify(NOTIFY_ERROR,
		       "%s: PROCEDURE definition missing spurious NIL leaf",
		       file);
	    } else {
		/*
		 * Skip over the return type.
		 */
		(void)CVProcessTypeRecord(file,
					  &bp,
					  bp[1] | (bp[2] << 8),
					  0);
		if (*bp == CTL_NEAR) {
		    retval = OTYPE_NEAR | OTYPE_SPECIAL;
		} else if (*bp == CTL_FAR) {
		    retval = OTYPE_FAR | OTYPE_SPECIAL;
		} else {
		    Notify(NOTIFY_ERROR,
			   "%s: Unknown call-type (%02.2x) in PROCEDURE definition",
			   file, *bp);
		}
	    }
	    /*
	     * Skip over the rest of the record.
	     */
	    bp = dataBase + len;
	    break;
	case CTL_STRING_TYPE:
	case CTL_ARRAY:
	    retval = CVProcessArray(file, &bp, len-1, typeBlock);
	    break;
	case CTL_STRUCTURE:
	    retval = CVProcessStructure(file, &bp, len-1, typeBlock);
	    break;
	case CTL_POINTER:
	{
	    byte    ptrType = *bp++;
	    word    baseType;

	    baseType = CVProcessTypeRecord(file, &bp, bp[1] | (bp[2] << 8),
					   typeBlock);
	    switch(ptrType) {
		case CTL_NEAR_PTR:
		    retval = OTYPE_PTR | OTYPE_PTR_NEAR | OTYPE_SPECIAL;
		    break;
		case CTL_FAR_PTR:
		    retval = OTYPE_PTR | OTYPE_PTR_FAR | OTYPE_SPECIAL;
		    break;
		default:
		    Notify(NOTIFY_ERROR,
			   "%s: unhandled pointer type (%02.2x)",
			   file, ptrType);
	    }

	    if (baseType != (OTYPE_VOID | OTYPE_SPECIAL)) {
		/*
		 * Pointer to something interesting -- allocate a type
		 * record for our result and fill it in appropriately.
		 */
		ObjType *ot;
		word	tOffset;

		ot = MSObj_AllocType(typeBlock, &tOffset);
		ot->words[0] = retval;
		ot->words[1] = baseType;
		retval = tOffset;
		VMUnlockDirty(symbols, typeBlock);
	    }

	    /*
	     * Deal with any typedef tag at the end of the descriptor.
	     * XXX: HighC puts out a CTL_TYPEDEF record, and names pointers
	     * using this method, so we're doing extra shit...
	     */
	    CVCreateTypedef(file,
			    &bp,
			    dataBase,
			    len,
			    typeBlock,
			    retval);
	    break;
	}
	case CTL_BASED:
	{
	    /*
	     * We really ought to record on what the thing is based, rather
	     * than just converting these things into near pointers, as
	     * Swat's going to need this information to indirect through
	     * the pointer correctly. However, for now we just make them
	     * near and f*** them if they can't take a joke.
	     */
	    word    baseType;

	    baseType = CVProcessTypeRecord(file, &bp, bp[1] | (bp[2] << 8),
					   typeBlock);

	    if (baseType != (OTYPE_VOID | OTYPE_SPECIAL)) {
		/*
		 * Pointer to something interesting -- allocate a type
		 * record for our result and fill it in appropriately.
		 */
		ObjType *ot;
		word	tOffset;

		ot = MSObj_AllocType(typeBlock, &tOffset);
		ot->words[0] = retval;
		ot->words[1] = baseType;
		retval = tOffset;
		VMUnlockDirty(symbols, typeBlock);
	    } else {
		retval = OTYPE_PTR | OTYPE_PTR_NEAR | OTYPE_SPECIAL;
	    }
	    break;
	}
	case CTL_SCALAR:
	    retval = CVProcessScalar(file, &bp, len-1, typeBlock);
	    break;
	case CTL_ID:
	{
	    ObjType 	*ot;

	    ot = MSObj_AllocType(typeBlock, &retval);
	    MSObj_GetWord(ot->words[0], bp);
	    MSObj_GetWord(ot->words[1], bp);
	    VMUnlockDirty(symbols, typeBlock);
	    /*
	     * Skip over left-over bytes
	     */
	    bp = *bpPtr + len;
	    break;
	}
    }
#endif

	*bpPtr = bp;
	return(retval);
}


/***********************************************************************
 *				CV32ProcessUnprocessedTypeRecords
 ***********************************************************************
 * SYNOPSIS:	    Deal with any important (i.e. structured) type
 *	    	    records that haven't yet been dealt with.
 * CALLED BY:	    CV_Finish
 * RETURN:	    nothing
 * SIDE EFFECTS:    beaucoup
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/17/92		Initial Revision
 *
 ***********************************************************************/
static void
CV32ProcessUnprocessedTypeRecords(const char *file)
{
    byte    	*bp;
    byte    	*end;
    word    	len;

    bp = typeSeg;
    end = typeSeg + typeSize;

    while (bp < end) {
    	word leaf;
	len = bp[0] | (bp[1] << 8);

	bp += 2;
	MSObj_GetWord(leaf, bp);
	bp -= 2;

	switch(leaf) {
	    //case CTL_TYPEDEF:
	    case CTL2_STRUCTURE:
	    //case CTL_SCALAR:
		(void)CV32ProcessTypeRecord(file,
					  &bp,
					  len,
					  0);
		break;
	    default:
		bp = bp + len;
		break;
	}
    }
}

/***********************************************************************
 *				CV32_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize things for a new object file.
 * CALLED BY:	    Pass1MS_Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    this that and the other thing
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/91		Initial Revision
 *
 ***********************************************************************/
void
CV32_Init(const char *file,
	FILE	*f)
{
    if (cvTypesSegment.name == NullID) {
	cvTypesSegment.name = ST_EnterNoLen(symbols, strings, CV_TYPE_SEG_NAME);
	cvSymsSegment.name = ST_EnterNoLen(symbols, strings, CV_SYM_SEG_NAME);
    }

    typeSize = symSize = 0;
}

/***********************************************************************
 *				CV32AllocLocalSym
 ***********************************************************************
 * SYNOPSIS:	    Allocate a symbol local to the current scope.
 * CALLED BY:	    CVProcessSymbols
 * RETURN:	    pointer to the allocated symbol.
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/22/91		Initial Revision
 *
 ***********************************************************************/
static ObjSym *
CV32AllocLocalSym(VMBlockHandle	    symBlock,
		MemHandle   	    mem,
		word	    	    curScope,
		word	    	    *lastLocalPtr,
		genptr		    *symBasePtr)
{
    ObjSym  	    *os;
    word    	    symOff;

    os = CV32AllocSymLocked(symBlock, mem, &symOff, (ObjSymHeader **)symBasePtr);

    /*
     * Link to enclosing scope, in case this ends up being the last one.
     */
    os->u.procLocal.next = curScope;

    if (*lastLocalPtr != 0) {
	((ObjSym *)(*symBasePtr + *lastLocalPtr))->u.procLocal.next = symOff;
    } else {
	((ObjSym *)(*symBasePtr + curScope))->u.scope.first = symOff;
    }
    *lastLocalPtr = symOff;

    return(os);
}

/***********************************************************************
 *				CV32DetermineSymbolBlock
 ***********************************************************************
 * SYNOPSIS:	    Determine in what symbol block the symbol being
 *	    	    defined should go.
 * CALLED BY:	    CVProcessSymbols
 * RETURN:	    TRUE if the segment & block could be determined. The
 *	    	    	symbol block is locked in this case.
 * SIDE EFFECTS:    Symbol/type blocks may be allocated for the segment
 *	    	    containing the symbol
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/25/91		Initial Revision
 *
 ***********************************************************************/
static Boolean
CV32DetermineSymbolBlock(const char    	*file,	    	/* Object file being
							 * read */
		       char   	    	*name,	    	/* Name of symbol being
							 * defined */
		       word             nameLen,
		       char 	    	*symType,   	/* String telling type
							 * of symbol, for error
							 * messages */
		       byte 	    	*bp,	    	/* Place in symSeg of
							 * offset for symbol */
		       SegDesc	    	*procSD,    	/* Segment of procedure
							 * currently being
							 * defined; NULL if
							 * none */
		       SegDesc	    	**sdPtr,    	/* Storage for symbol
							 * segment */
		       word 	    	*addrPtr,   	/* Storage for relocated
							 * symbol offset */
		       VMBlockHandle	*symBlockPtr,	/* Storage for block in
							 * which to allocate the
							 * ObjSym */
		       VMBlockHandle	*typeBlockPtr,	/* Storage for assoc.
							 * type block */
		       MemHandle    	*memPtr,    	/* Storage for memory
							 * handle of symBlock */
		       genptr 	    	*symBasePtr,	/* Storage for base of
							 * locked symBlock */
		       ID               *realName)      /* Public name under
							 * which symbol was
							 * found, NullID if
							 * none */
{
    VMBlockHandle   symBlock;
    VMBlockHandle   typeBlock;
    ObjSymHeader    *osh;
    word    	    curSize;

    /*
     * Figure the segment and offset of the symbol itself. bp
     * points to the offset field of the symbol record. First
     * find a fixup for this position
     */
    *realName = NullID;
    if (!CV32LocateFixup(file, bp-symSeg, sdPtr, addrPtr, realName)) {
	/*
	 * No fixup around, so see if there's a public definition
	 * for the damn thing.
	 */
	Boolean	real;
        *realName = ST_Enter(symbols, strings, name, nameLen);
	if (!CV32LocatePublic(*realName, sdPtr, addrPtr, &real, (ID *)NULL)) {
#if 0	/* HighC likes to generate codeview symbols for external arrays, so
	 * we can't bitch about this... */
	    Notify(NOTIFY_ERROR,
		   "%s: cannot determine segment & offset for %s %i",
		   file, symType, name);
#endif
	    return(FALSE);
	}
    }
    if (*realName==NullID) {
	*realName = ST_Enter(symbols, strings, name, nameLen);
    }

    assert (*sdPtr != NULL);

    /*
     * Relocate the thing by the segment's current relocation factor and the
     * offset stored in the symbol segment.
     */
    *addrPtr += (*sdPtr)->nextOff + (bp[0]  | (bp[1] << 8));

    /*
     * See if the last block of the chain can hold a bit more.
     * Use it if so.
     */
    symBlock = (*sdPtr)->addrT;
    if (symBlock != 0) {
	VMInfo(symbols, symBlock, &curSize, (MemHandle *)NULL,
	       (VMID *)NULL);

	if ((curSize  < OBJ_MAX_SYMS) || (*sdPtr == procSD)) {
	    /*
	     * Symbol block is either still small enough or the symbol lies
	     * in the segment of the procedure being defined, so we must
	     * use the block anyway, as we need to place any local
	     * labels/variables in the same block as the procedure.
	     */
	    osh = (ObjSymHeader *)VMLock(symbols, symBlock, memPtr);
	    typeBlock = osh->types;
	} else {
	    symBlock = 0;
	}
    }

    if (symBlock == 0) {
	/*
	 * Couldn't use the tail. Allocate a new tail and associated
	 * type block.
	 */
	CV32AllocSymAndTypeBlocks(&symBlock, &typeBlock);

	if ((*sdPtr)->addrT) {
	    /*
	     * Link the new tail to the old one and see if the old
	     * tail's type block can hold some more descriptions.
	     * Use it if so, freeing the one we just allocated.
	     */
	    osh = (ObjSymHeader *)VMLock(symbols, (*sdPtr)->addrT, (MemHandle *)NULL);
	    osh->next = symBlock;

	    VMInfo(symbols, osh->types, &curSize, (MemHandle *)NULL,
		   (VMID *)NULL);
	    if (curSize < OBJ_INIT_TYPES) {
		VMFree(symbols, typeBlock);
		typeBlock = osh->types;
	    }
	    VMUnlockDirty(symbols, (*sdPtr)->addrT);
	} else {
	    /*
	     * No address symbols in this segment yet -- set the
	     * head of the queue to what we just allocated.
	     */
	    (*sdPtr)->addrH = symBlock;
	}
	(*sdPtr)->addrT = symBlock;
    }
    *symBasePtr = (genptr)(osh = (ObjSymHeader *)VMLock(symbols, symBlock, memPtr));

    osh->types = typeBlock;	/* In case it changed, above */

    *symBlockPtr = symBlock;
    *typeBlockPtr = typeBlock;
    return(TRUE);
}


/***********************************************************************
 *				CV32ProcessSymbols
 ***********************************************************************
 * SYNOPSIS:	    Create output symbols for all the symbols in the
 *	    	    $$SYMBOLS segment.
 * CALLED BY:	    CV_Finish
 * RETURN:	    nothing
 * SIDE EFFECTS:    Symbols are created, of course.
 *
 * STRATEGY:
 *	We assume that the symbols are sorted in ascending order of address.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/22/91		Initial Revision
 *
 ***********************************************************************/
#define MAX_SCOPES  32

static void
CV32ProcessSymbols(const char	*file)	/* Object file name (for errors) */
{
    VMBlockHandle   symBlock;	    /* Temporary symbol block */
    genptr	    symBase;	    /* Base of same, when locked */
    MemHandle	    mem;    	    /* Memory handle of same */
    VMBlockHandle   typeBlock;	    /* Temporary type block */
    word    	    scopeStack[MAX_SCOPES];
    int	    	    scopeTop=0;	    /* Top of the scope stack */
    word    	    lastLocal;	    /* Offset of previous local, for linking */
    byte    	    *bp;
    byte    	    *end;
    SegDesc 	    *procSD, *defSeg;
    ID	    	    CODE;
    int 	    i;
    int	    	    blockCount=0;   /* Next local scope count to use */
	dword sig;

    bp = symSeg;
    end = bp + symSize;
    lastLocal = 0;

    /*
     * Determine the default segment for code symbols, in case fixups don't
     * exist... the default segment is the first one of class CODE, by
     * "definition".
     */
    defSeg = (SegDesc *)NULL;
    CODE = ST_LookupNoLen(symbols, strings, "CODE");
    if (CODE != NullID) {
	int 	nseg;

	nseg = Vector_Length(segments);

	for (i = 0; i < nseg; i++) {
	    Vector_Get(segments, i, &defSeg);
	    if ((defSeg != CV_TYPES_SEGMENT) && (defSeg != CV_SYMS_SEGMENT) &&
		(defSeg->class == CODE))
	    {
		break;
	    }
	}
    }


    /*
     * Now process all the symbols. Strategy:
    *       - for each symbol:
    *       	case type in
    *	    	    with_start:
    *   	    block_start:
    *   	    	relocate.
    *   		if same offset as current procedure, ignore
    *   		else
    *   		    make up name, if none given
    *   		    create/enter symbol (blockStart.next holds
    *   		    	length of block)
    *   		    push on scope stack
    *	    	    fortran_start:
    *	    	    procedure:
    *   	    	relocate
    *   		find fixup for offset field to determine containing
    *   		    segment
    *   		perform offset fixup, if non-zero displacement
    *   		create/enter symbol, looking for PUBDEF record and
    *   		    marking global, if present
    *   		push on scope stack
    *   		record as current procedure
    *   		if end of prologue non-zero, create $$prologue_end
    *   		    local label and enter into procedure
    *	    	    end_block:
    *   	    	if top of scope stack is lexical block:
    *   		    create end-block symbol at proper offset from
    *   		    block_start symbol (using blockStart.next
    *   		    field)
    *   		else
    *   		    reset current procedure to empty
    *   		pop scope stack
    *   	    local_var:
    *	    	    	create type description
    *   	    	create symbol
    *   		enter into current scope
    *	    	    variable:
    *   	    	create type description
    *   		create/enter symbol, looking for PUBDEF record and
    *   		    marking global, if present
    *   		    use fixup for fptr to determine proper segment for
    *   		    entry of symbol.
    *   	    code_label:
    *   	    	create/enter symbol in segment dictated by fixup,
    *   		    marking global if PUBDEF record is present
    *   	    	relocate.
    *	    	    reg_var:
    *   	    	convert register number
    *   		create type description
    *   		create symbol and enter into current scope
    *	    	    const:
    *   	    	create constant symbol & enter into global scope...
    *   		    maybe
    *	    	    skip_me:
    *   	    	do so
    *   	    change_seg:
    *	    	    	find segment fixup and change to it.
    *   	    typedef:
    *   	    	create type description
    *   		enter symbol in current scope, or global if no
    *   		    current scope.
    */
    symBlock = 0;
    procSD = NULL;

	/*
	* Check supported CodeView format
	*/
	MSObj_GetDWord(sig, bp);
	if (sig != 1) {
		Notify(NOTIFY_ERROR,
			"%s: unsupported CodeView format",
			file);
	}

	while (bp < end) {
	byte	*base;
	word    len;
	word recType;

	MSObj_GetWord(len, bp);
	base = bp;
	MSObj_GetWord(recType, bp);
	switch(recType) {
	case CST2_END:
	{
		ObjSym	    *os;

		if (scopeTop == 0) {
			Notify(NOTIFY_ERROR,
				"%s: cannot end non-existent current scope",
				file);
			break;
		}
		os = (ObjSym *)(symBase + scopeStack[scopeTop - 1]);
		if ((scopeTop > 1) &&
			(scopeStack[scopeTop - 2] == scopeStack[scopeTop - 1]))
		{
			/*
			* End of a scope we considered to be spurious, as its
			* address matched that of the previous scope (procedure
			* or block). Just pop the scope stack w/o creating a
			* blockend symbol.
			*/
			scopeTop--;
		}
		else if (os->type == OSYM_BLOCKSTART) {
			word    addr;

			addr = os->u.blockStart.address + os->u.blockStart.next;

			lastLocal = scopeStack[--scopeTop];
			os = CV32AllocLocalSym(symBlock, mem, scopeStack[scopeTop - 1],
				&lastLocal, &symBase);
			os->type = OSYM_BLOCKEND;
			os->name = NullID;
			os->flags = OSYM_NAMELESS;
			os->u.blockEnd.address = addr;
		}
		else {
			/*
			* Must be ending a procedure -- unlock the symbol and
			* type blocks. Other people will worry about their
			* size at a later date.
			*/
			scopeTop--;
			assert(scopeTop == 0);

			procSD = NULL;
			VMUnlockDirty(symbols, symBlock);
			VMUnlockDirty(symbols, typeBlock);
		}
		break;
	}
	case CST2_BLOCK16:
	{
		word	extraOffset;
		word	blockLength;
		ObjSym	*os;
		SegDesc	*sd;
		dword	pParent;
		dword	pEnd;
		ID      name;

		MSObj_GetDWord(pParent, bp);
		MSObj_GetDWord(pEnd, bp);
		MSObj_GetWord(blockLength, bp);

		if (symBlock == 0) {
			Notify(NOTIFY_ERROR,
				"%s: block start not in procedure",
				file);
			break;
		}
		else if (scopeTop == MAX_SCOPES) {
			Notify(NOTIFY_ERROR,
				"%s: Too many nested scopes",
				file);
			break;
		}

		if (CV32LocateFixup(file, bp - symSeg, &sd, &extraOffset, &name)) {
			extraOffset += MSObj_GetWordImm(bp);
		}
		else {
			sd = defSeg;
			MSObj_GetWord(extraOffset, bp);
		}
		extraOffset += sd->nextOff;
		if (extraOffset ==
			((ObjSym *)(symBase + scopeStack[scopeTop - 1]))->u.proc.address)
		{
			/*
			* Block is just the beginning of the procedure. Push the
			* procedure onto the scope stack again and drop this
			* symbol on the floor.
			*/
			scopeStack[scopeTop] = scopeStack[scopeTop - 1];
			scopeTop++;
			bp = base + len;
		}
		else {
			int	    i;
			word	blockSeg;

			os = CV32AllocLocalSym(symBlock, mem, scopeStack[scopeTop - 1],
				&lastLocal, &symBase);
			os->flags = 0;
			MSObj_GetWord(blockSeg, bp);
			if (bp < base + len && *bp != 0) {
				os->name = ST_Enter(symbols, strings, (char *)bp + 1, *bp);
			}
			else {
				char	blockName[32];

				sprintf(blockName, "??block%d", blockCount++);
				os->name = ST_EnterNoLen(symbols, strings,
					blockName);
			}
			os->type = OSYM_BLOCKSTART;
			os->u.blockStart.next = blockLength;
			os->u.blockStart.local = lastLocal;
			os->u.blockStart.address = extraOffset;
			/*
			* Push the block onto the scope stack and reset the
			* "local" symbol list.
			*/
			scopeStack[scopeTop++] = lastLocal;
			lastLocal = 0;
		}
		break;
	}
	case CST2_BPREL16:
	{
    		ID  	name;
    		ObjSym	*os;

    		name = ST_Enter(symbols, strings, (char *)bp+5, bp[4]);

    		if (scopeTop == 0) {
    		    Notify(NOTIFY_ERROR,
    			   "%s: local variable %i outside any scope",
    			   file, name);
    		    break;
    		}

    		os = CV32AllocLocalSym(symBlock, mem, scopeStack[scopeTop-1],
    				     &lastLocal, &symBase);
    		os->type = OSYM_LOCVAR;
    		os->name = name;
    		os->flags = 0;
    		MSObj_GetWord(os->u.localVar.offset, bp);
    		os->u.localVar.type = CV32FetchType(file, typeBlock,
    						  MSObj_GetWordImm(bp));
    		break;
	}
	case CST2_UDT:
		/*
		* Deal with this some day.
		*/
		break;
	case CST2_LDATA16:
	case CST2_GDATA16:
		/*
		* Deal with this some day.
		*/
	{
		word	    	addr;
		Boolean	    	real;
		ID  	    	name;
		ID  	    	alias;
		VMBlockHandle	tsymBlock;
		VMBlockHandle	ttypeBlock;
		MemHandle   	tmem;
		genptr	    	tsymBase;
		SegDesc	    	*sd;
		ObjSym	    	*os;
		word	    	symOff;
		char            *segName;

		if (!CV32DetermineSymbolBlock(file, (char *)bp + 7, bp[6], "variable", bp, procSD,
			&sd, &addr, &tsymBlock, &ttypeBlock,
			&tmem, &tsymBase, &name))
		{
			break;
		}
		os = CV32AllocSymLocked(tsymBlock, tmem, &symOff,
			(ObjSymHeader **)&tsymBase);
		os->type = OSYM_VAR;
		os->name = name;
		os->flags = 0;
		os->u.variable.address = addr;
		os->u.variable.type = CV32FetchType(file, ttypeBlock,
			bp[4] | (bp[5] << 8));

		/*
		* Mark the thing global if it's really declared public,
		* or if it resides in the handle segment of an lmem group,
		* since HighC is so kind as to only let us place things in
		* individual segments none of whose symbols can ever be
		* declared public. -- ardeb 12/12/91
		*/
		if (CV32LocatePublic(name, (SegDesc **)NULL, (word *)NULL,
			&real, (ID *)NULL) && real)
		{
			os->flags |= OSYM_GLOBAL;

			if ((sd->combine == SEG_LMEM) &&
				(MSObj_GetLMemSegOrder(sd) == 1))
			{
				os->type = OSYM_VAR;
				os->u.variable.type = OTYPE_MAKE_VOID_PTR(OTYPE_PTR_NEAR);
				os->u.label.near = TRUE;
			}
			else 
			{
				/*
			 	 * Do not enter alias for variables to avoid
			 	* conflicts between ChunkHandle and chunk in LMem
			 	*/
#if 0
				if (alias != name) {
					Sym_Enter(symbols, sd->syms, alias, tsymBlock, symOff);
				}
#endif
			}
		}
		/*
		* If the segment's name is _CLASSSEG_<whatever>, we'll do
		* the same thing as above...
		*/

		else if (sd->name) {
			segName = ST_Lock(symbols, sd->name);

			if (!(strncmp(segName, "_CLASSSEG_",
				sizeof("_CLASSSEG_") - 1))) {
				os->flags |= OSYM_GLOBAL;
			}

			ST_Unlock(symbols, sd->name);
		}

		/*
		* Enter the symbol into the table for the segment.
		*/
		if (procSD == NULL) {

#if 0
			VMBlockHandle    foundBlock;
			word             foundOffset;

			/*
			* If the thing hasn't been entered, do it now. This
			* check has been added to keep High C from complaining
			* about multiple modules with _far class structures, and
			* may be completely inappropriate... -jon 25 oct 1994
			*/

			/*
			* The check has subsequently been removed, 'cause it
			* didn't do a damn bit of good in the High C case...
			* -jon 25 jan 1995
			*/

			if (Sym_Find(symbols, sd->syms, name,
				&foundBlock, &foundOffset, FALSE)) {
				if ((foundOffset != tsymBlock) ||
					(foundBlock != symOff)) {

					Notify(NOTIFY_ERROR,
						"yo, %i multiply defined in a single segment",
						name);
				}
			}
			else {
#endif /* 0 */
				Sym_Enter(symbols, sd->syms, name, tsymBlock, symOff);
#if 0
			}
#endif /* 0 */

			/*
			* Release the symbol and type blocks.
			*/
			VMUnlockDirty(symbols, tsymBlock);
			VMUnlockDirty(symbols, ttypeBlock);
		}
		else {
			/*
			* Variable is local to the procedure. Create a
			* LOCAL_STATIC symbol inside the current scope to point to
			* the VAR symbol we just created.
			*/
			if (sd == procSD) {
				/*
				* If variable allocated in same segment as current
				* procedure, update base of symbol block now so
				* its accurate for our creation of the LOCAL_STATIC
				* symbol we're about to perform.
				*/
				symBase = tsymBase;
			}

			os = CV32AllocLocalSym(symBlock, mem, scopeStack[scopeTop - 1],
				&lastLocal, &symBase);
			os->type = OSYM_LOCAL_STATIC;
			os->name = name;
			os->flags = 0;
			os->u.localStatic.symBlock = tsymBlock;
			os->u.localStatic.symOff = symOff;
		}
	}

		break;
	case CST2_LPROC16:
	case CST2_GPROC16:
	{
		ObjSym	    	*os;	    /* General symbol pointer */
		word	    	addr;	    /* Relocated address of the
									* procedure */
		SegDesc	    	*sd;	    /* Segment in which it's defined */
		byte	    	*ptype;	    /* Pointer to CTL_PROCEDURE type
									* from which the procedure's
									* return type is extracted */
		word	    	ptypeLen;   /* Length of that record */
		ID  	    	name;	    /* The procedure's name */
		ID  	    	alias;	    /* The global alias for it */
		word	    	prologueLen;/* Length of frame-setup prologue */
		Boolean	    	real;
		word			leaf;

		if (scopeTop != 0) {
			Notify(NOTIFY_ERROR,
				"%s: procedure %i may not be nested inside another scope",
				file, name);
			break;
		}

		if (!CV32DetermineSymbolBlock(file, (char *)bp + 26, bp[25], "procedure", bp +18, NULL,
			&sd, &addr, &symBlock, &typeBlock,
			&mem, (genptr *)&symBase, &name))
		{
			break;
		}

		/*
		* Skip offset field since CVDetermineSymbolBlock has already
		* dealt with it for us.
		*/
		//bp += 2;

		/*
		* Locate the CTL_PROCEDURE type descriptor for the thing.
		* We'll need it in a moment.
		*/
		bp = bp + 22;
		ptype = CV32LocateType(MSObj_GetWordImm(bp), &ptypeLen);

		MSObj_GetWord(leaf, ptype);
		if (leaf != CTL2_PROCEDURE) {
			Notify(NOTIFY_ERROR,
				"%s: procedure not defined with PROCEDURE definition",
				file);
			VMUnlock(symbols, symBlock);
			symBlock = 0;
			break;
		}
		/*else if (*ptype++ != CTL_NIL) {
			Notify(NOTIFY_ERROR,
				"%s: PROCEDURE definition missing spurious NIL leaf",
				file);
			VMUnlock(symbols, symBlock);
			symBlock = 0;
			break;
		}*/

		bp -= 12;
		bp += 2;	/* Skip the procedure length */
		MSObj_GetWord(prologueLen, bp);

		bp += 8;	/* Skip epilogue start & reserved */

					/*
					* Allocate and initialize the procedure symbol.
					*/
		os = CV32AllocSymLocked(symBlock, mem, &scopeStack[scopeTop++],
			(ObjSymHeader **)&symBase);
		os->type = OSYM_PROC;
		os->flags = 0;
		os->name = name;
		os->u.proc.local = scopeStack[scopeTop - 1]; /* No locals yet */
		if ((*bp & 4) == 0) {
			os->u.proc.flags = OSYM_NEAR;
		}
		else {
			os->u.proc.flags = 0;
		}
		os->u.proc.address = addr;

		/*
		* Mark the thing global if it's really declared public.
		*/
		if (recType == CST2_GPROC16) {
			if (CV32LocatePublic(name, (SegDesc **)NULL, (word *)NULL,
				&real, (ID *)NULL) && real)
			{
				os->flags |= OSYM_GLOBAL;
#if 0
				if (alias != name) {
					Sym_Enter(symbols, sd->syms, alias, symBlock,
						scopeStack[scopeTop - 1]);
				}
#endif
			} else if ((sd->combine == SEG_LMEM) &&
				   (MSObj_GetLMemSegOrder(sd) == 1))
			{
			    os->flags |= OSYM_GLOBAL;
			}		
		} else {
			if (CV32LocatePublic(name, (SegDesc **)NULL, (word *)NULL,
				&real, (ID *)NULL) && real) {
			}
		}

		/*
		* Enter the symbol into the table for the segment.
		*/
		Sym_Enter(symbols, sd->syms, name, symBlock,
			scopeStack[scopeTop - 1]);

		procSD = sd;
		blockCount = lastLocal = 0;

		/*
		* Allocate a RETURN_TYPE symbol to hold the procedure's
		* return type, there being no room in the procedure symbol
		* itself.... Use CVProcessTypeRecord b/c the return type's
		* a type tree, not a plain index.
		*/
		os = CV32AllocLocalSym(symBlock, mem, scopeStack[scopeTop - 1],
			&lastLocal, &symBase);
		os->name = NullID;
		os->type = OSYM_RETURN_TYPE;
		os->flags = OSYM_NAMELESS;
		ptype -= 2;
		os->u.localVar.type =
			CV32ProcessTypeRecord(file, &ptype,
				ptypeLen,
				typeBlock);

		/*
		* If the thing follows the Pascal calling convention, note
		* this in the procedure symbol. ptype's been advanced beyond
		* the return type for us by CVProcessTypeRecord.
		*/

		ptype -= 6; /* MC: CHECK ME: my math may be off */

		switch (*ptype) {
		case CCC2_PASCAL_NEAR:
		case CCC2_PASCAL_FAR:
			((ObjSym *)(symBase + scopeStack[scopeTop - 1]))->u.proc.flags |=
				OSYM_PROC_PASCAL;
			break;
		}

		/*
		* If the procedure has a prologue, define a special local
		* label to mark the end of that prologue. Swat uses this in
		* its "stop" command.
		*/
		if (prologueLen != 0) {
			os = CV32AllocLocalSym(symBlock, mem, scopeStack[scopeTop - 1],
				&lastLocal, &symBase);
			os->name = ST_EnterNoLen(symbols, strings,
				OSYM_PROC_START_NAME);
			os->type = OSYM_LOCLABEL;
			os->flags = OSYM_NAMELESS;
			os->u.label.near = TRUE;
			os->u.label.address = addr + prologueLen;
		}
		break;
	}
	default:
		break;
#if 0


	case CST_WITH_START:
	    case CST_BLOCK_START:
	    {
		word	extraOffset;
		word	blockLength;
		ObjSym	*os;
		SegDesc	*sd;

		if (symBlock == 0) {
		    Notify(NOTIFY_ERROR,
			   "%s: block start not in procedure",
			   file);
		    break;
		} else if (scopeTop == MAX_SCOPES) {
		    Notify(NOTIFY_ERROR,
			   "%s: Too many nested scopes",
			   file);
		    break;
		}

		if (CVLocateFixup(file, bp-symSeg, &sd, &extraOffset)) {
		    extraOffset += MSObj_GetWordImm(bp);
		} else {
		    sd = defSeg;
		    MSObj_GetWord(extraOffset, bp);
		}
		extraOffset += sd->nextOff;
		MSObj_GetWord(blockLength, bp);
		if (extraOffset ==
		    ((ObjSym *)(symBase+scopeStack[scopeTop-1]))->u.proc.address)
		{
		    /*
		     * Block is just the beginning of the procedure. Push the
		     * procedure onto the scope stack again and drop this
		     * symbol on the floor.
		     */
		    scopeStack[scopeTop] = scopeStack[scopeTop-1];
		    scopeTop++;
		    bp = base + len;
		} else {
		    /*
		     * XXX: MetaWare puts out the offset of the block start
		     * plus the offset of the procedure, here, so as a hack,
		     * until we support something else with codeview symbols,
		     * subtract off the offset of the procedure
		     */
		    int	    i;

		    for (i = scopeTop-1; i >= 0; i--) {
			if (((ObjSym *)(symBase+scopeStack[i]))->type ==
			    OSYM_PROC)
			{
			    extraOffset -= ((ObjSym *)(symBase+scopeStack[i]))->u.proc.address;
			    break;
			}
		    }

		    os = CVAllocLocalSym(symBlock, mem, scopeStack[scopeTop-1],
					 &lastLocal, &symBase);
		    os->flags = 0;
		    if (bp < base + len) {
			os->name = ST_Enter(symbols, strings, (char *)bp+1,*bp);
		    } else {
			char	blockName[32];

			sprintf(blockName, "??block%d", blockCount++);
			os->name = ST_EnterNoLen(symbols, strings,
						 blockName);
		    }
		    os->type = OSYM_BLOCKSTART;
		    os->u.blockStart.next = blockLength;
		    os->u.blockStart.local = lastLocal;
		    os->u.blockStart.address = extraOffset;
		    /*
		     * Push the block onto the scope stack and reset the
		     * "local" symbol list.
		     */
		    scopeStack[scopeTop++] = lastLocal;
		    lastLocal = 0;
		}
		break;
	    }
	    case CST_FORTRAN_ENTRY:
	    case CST_PROC_START:
	    {
		ObjSym	    	*os;	    /* General symbol pointer */
		word	    	addr;	    /* Relocated address of the
					     * procedure */
		SegDesc	    	*sd;	    /* Segment in which it's defined */
		byte	    	*ptype;	    /* Pointer to CTL_PROCEDURE type
					     * from which the procedure's
					     * return type is extracted */
		word	    	ptypeLen;   /* Length of that record */
		ID  	    	name;	    /* The procedure's name */
		ID  	    	alias;	    /* The global alias for it */
		word	    	prologueLen;/* Length of frame-setup prologue */
		Boolean	    	real;

		/*
		 * Figure the name of the procedure -- we may need it soon.
		 */
		name = ST_Enter(symbols, strings, (char *)bp+14, bp[13]);

		if (scopeTop != 0) {
		    Notify(NOTIFY_ERROR,
			   "%s: procedure %i may not be nested inside another scope",
			   file, name);
		    break;
		}

		if (!CVDetermineSymbolBlock(file, name, "procedure", bp, NULL,
					    &sd, &addr, &symBlock, &typeBlock,
					    &mem,(genptr *)&symBase))
		{
		    break;
		}

		/*
		 * Skip offset field since CVDetermineSymbolBlock has already
		 * dealt with it for us.
		 */
		bp += 2;

		/*
		 * Locate the CTL_PROCEDURE type descriptor for the thing.
		 * We'll need it in a moment.
		 */
		ptype = CVLocateType(MSObj_GetWordImm(bp), &ptypeLen);

		if (*ptype++ != CTL_PROCEDURE) {
		    Notify(NOTIFY_ERROR,
			   "%s: procedure not defined with PROCEDURE definition",
			   file);
		    VMUnlock(symbols, symBlock);
		    symBlock = 0;
		    break;
		} else if (*ptype++ != CTL_NIL) {
		    Notify(NOTIFY_ERROR,
			   "%s: PROCEDURE definition missing spurious NIL leaf",
			   file);
		    VMUnlock(symbols, symBlock);
		    symBlock = 0;
		    break;
		}

		bp += 2;	/* Skip the procedure length */
		MSObj_GetWord(prologueLen, bp);

		bp += 4;	/* Skip epilogue start & reserved */

		/*
		 * Allocate and initialize the procedure symbol.
		 */
		os = CVAllocSymLocked(symBlock, mem, &scopeStack[scopeTop++],
				      (ObjSymHeader **)&symBase);
		os->type = OSYM_PROC;
		os->flags = 0;
		os->name = name;
		os->u.proc.local = scopeStack[scopeTop-1]; /* No locals yet */
		if (*bp == 0) {
		    os->u.proc.flags = OSYM_NEAR;
		} else {
		    os->u.proc.flags = 0;
		}
		os->u.proc.address = addr;

		/*
		 * Mark the thing global if it's really declared public.
		 */
		if (CVLocatePublic(name, (SegDesc **)NULL, (word *)NULL,
				   &real, &alias) && real)
		{
		    os->flags |= OSYM_GLOBAL;
		    if (alias != name) {
			Sym_Enter(symbols, sd->syms, alias, symBlock,
				  scopeStack[scopeTop-1]);
		    }
		}

		/*
		 * Enter the symbol into the table for the segment.
		 */
		Sym_Enter(symbols, sd->syms, name, symBlock,
			  scopeStack[scopeTop-1]);

		procSD = sd;
		blockCount = lastLocal = 0;

		/*
		 * Allocate a RETURN_TYPE symbol to hold the procedure's
		 * return type, there being no room in the procedure symbol
		 * itself.... Use CVProcessTypeRecord b/c the return type's
		 * a type tree, not a plain index.
		 */
		os = CVAllocLocalSym(symBlock, mem, scopeStack[scopeTop-1],
				     &lastLocal, &symBase);
		os->name = NullID;
		os->type = OSYM_RETURN_TYPE;
		os->flags = OSYM_NAMELESS;
		os->u.localVar.type =
		    CVProcessTypeRecord(file, &ptype,
					ptype[1] | (ptype[2] << 8),
					typeBlock);

		/*
		 * If the thing follows the Pascal calling convention, note
		 * this in the procedure symbol. ptype's been advanced beyond
		 * the return type for us by CVProcessTypeRecord.
		 */
		switch (*ptype) {
		    case CCC_PASCAL_NEAR:
		    case CCC_PASCAL_FAR:
			((ObjSym *)(symBase+scopeStack[scopeTop-1]))->u.proc.flags |=
			    OSYM_PROC_PASCAL;
			break;
		}

		/*
		 * If the procedure has a prologue, define a special local
		 * label to mark the end of that prologue. Swat uses this in
		 * its "stop" command.
		 */
		if (prologueLen != 0) {
		    os = CVAllocLocalSym(symBlock, mem, scopeStack[scopeTop-1],
					 &lastLocal, &symBase);
		    os->name = ST_EnterNoLen(symbols, strings,
					     OSYM_PROC_START_NAME);
		    os->type = OSYM_LOCLABEL;
		    os->flags = OSYM_NAMELESS;
		    os->u.label.near = TRUE;
		    os->u.label.address = addr + prologueLen;
		}
		break;
	    }
	    case CST_END:
	    {
		ObjSym	    *os;

		if (scopeTop == 0) {
		    Notify(NOTIFY_ERROR,
			   "%s: cannot end non-existent current scope",
			   file);
		    break;
		}
		os = (ObjSym *)(symBase + scopeStack[scopeTop-1]);
		if ((scopeTop > 1) &&
		    (scopeStack[scopeTop-2] == scopeStack[scopeTop-1]))
		{
		    /*
		     * End of a scope we considered to be spurious, as its
		     * address matched that of the previous scope (procedure
		     * or block). Just pop the scope stack w/o creating a
		     * blockend symbol.
		     */
		    scopeTop--;
		} else if (os->type == OSYM_BLOCKSTART) {
		    word    addr;

		    addr = os->u.blockStart.address + os->u.blockStart.next;

		    lastLocal = scopeStack[--scopeTop];
		    os = CVAllocLocalSym(symBlock, mem, scopeStack[scopeTop-1],
					 &lastLocal, &symBase);
		    os->type = OSYM_BLOCKEND;
		    os->name = NullID;
		    os->flags = OSYM_NAMELESS;
		    os->u.blockEnd.address = addr;
		} else {
		    /*
		     * Must be ending a procedure -- unlock the symbol and
		     * type blocks. Other people will worry about their
		     * size at a later date.
		     */
		    scopeTop--;
		    assert(scopeTop == 0);

		    procSD = NULL;
		    VMUnlockDirty(symbols, symBlock);
		    VMUnlockDirty(symbols, typeBlock);
		}
		break;
	    }
	    case CST_LOCAL_VAR:
	    {
		ID  	name;
		ObjSym	*os;

		name = ST_Enter(symbols, strings, (char *)bp+5, bp[4]);

		if (scopeTop == 0) {
		    Notify(NOTIFY_ERROR,
			   "%s: local variable %i outside any scope",
			   file, name);
		    break;
		}

		os = CVAllocLocalSym(symBlock, mem, scopeStack[scopeTop-1],
				     &lastLocal, &symBase);
		os->type = OSYM_LOCVAR;
		os->name = name;
		os->flags = 0;
		MSObj_GetWord(os->u.localVar.offset, bp);
		os->u.localVar.type = CVFetchType(file, typeBlock,
						  MSObj_GetWordImm(bp));
		break;
	    }
	    case CST_VARIABLE:
	    {
		word	    	addr;
		Boolean	    	real;
		ID  	    	name;
		ID  	    	alias;
		VMBlockHandle	tsymBlock;
		VMBlockHandle	ttypeBlock;
		MemHandle   	tmem;
		genptr	    	tsymBase;
		SegDesc	    	*sd;
		ObjSym	    	*os;
		word	    	symOff;
		char            *segName;

		name = ST_Enter(symbols, strings, (char *)bp+7, bp[6]);

		if (!CVDetermineSymbolBlock(file, name, "variable", bp, procSD,
					    &sd, &addr, &tsymBlock, &ttypeBlock,
					    &tmem, &tsymBase))
		{
		    break;
		}

		os = CVAllocSymLocked(tsymBlock, tmem, &symOff,
				      (ObjSymHeader **)&tsymBase);
		os->type = OSYM_VAR;
		os->name = name;
		os->flags = 0;
		os->u.variable.address = addr;
		os->u.variable.type = CVFetchType(file, ttypeBlock,
						  bp[4] | (bp[5] << 8));

		/*
		 * Mark the thing global if it's really declared public,
		 * or if it resides in the handle segment of an lmem group,
		 * since HighC is so kind as to only let us place things in
		 * individual segments none of whose symbols can ever be
		 * declared public. -- ardeb 12/12/91
		 */
		if (CVLocatePublic(name, (SegDesc **)NULL, (word *)NULL,
				   &real, &alias) && real)
		{
		    os->flags |= OSYM_GLOBAL;
		    if (alias != name) {
			Sym_Enter(symbols, sd->syms, name, tsymBlock, symOff);
		    }
		} else if ((sd->combine == SEG_LMEM) &&
			   (MSObj_GetLMemSegOrder(sd) == 1))
		{
		    os->flags |= OSYM_GLOBAL;
		}
		/*
		 * If the segment's name is _CLASSSEG_<whatever>, we'll do
		 * the same thing as above...
		 */

		else if (sd->name) {
		    segName = ST_Lock(symbols, sd->name);

		    if (!(strncmp(segName, "_CLASSSEG_",
				  sizeof("_CLASSSEG_") - 1))) {
			os->flags |= OSYM_GLOBAL;
		    }

		    ST_Unlock(symbols, sd->name);
		}

		/*
		 * Enter the symbol into the table for the segment.
		 */
		if (procSD == NULL) {

#if 0
		    VMBlockHandle    foundBlock;
		    word             foundOffset;

		    /*
		     * If the thing hasn't been entered, do it now. This
		     * check has been added to keep High C from complaining
		     * about multiple modules with _far class structures, and
		     * may be completely inappropriate... -jon 25 oct 1994
		     */

		    /*
		     * The check has subsequently been removed, 'cause it
		     * didn't do a damn bit of good in the High C case...
		     * -jon 25 jan 1995
		     */

		    if (Sym_Find(symbols, sd->syms, name,
				 &foundBlock, &foundOffset, FALSE)) {
			if ((foundOffset != tsymBlock) ||
			    (foundBlock != symOff)) {

			    Notify(NOTIFY_ERROR,
				   "yo, %i multiply defined in a single segment",
				   name);
			}
		    } else {
#endif /* 0 */
			Sym_Enter(symbols, sd->syms, name, tsymBlock, symOff);
#if 0
		    }
#endif /* 0 */

		    /*
		     * Release the symbol and type blocks.
		     */
		    VMUnlockDirty(symbols, tsymBlock);
		    VMUnlockDirty(symbols, ttypeBlock);
		} else {
		    /*
		     * Variable is local to the procedure. Create a
		     * LOCAL_STATIC symbol inside the current scope to point to
		     * the VAR symbol we just created.
		     */
		    if (sd == procSD) {
			/*
			 * If variable allocated in same segment as current
			 * procedure, update base of symbol block now so
			 * its accurate for our creation of the LOCAL_STATIC
			 * symbol we're about to perform.
			 */
			symBase = tsymBase;
		    }

		    os = CVAllocLocalSym(symBlock, mem, scopeStack[scopeTop-1],
					 &lastLocal, &symBase);
		    os->type = OSYM_LOCAL_STATIC;
		    os->name = name;
		    os->flags = 0;
		    os->u.localStatic.symBlock = tsymBlock;
		    os->u.localStatic.symOff = symOff;
		}
		break;
	    }
	    case CST_CODE_LABEL:
	    {
		word	    	addr;
		Boolean	    	real;
		ID  	    	name;
		ID  	    	alias;
		VMBlockHandle	tsymBlock;
		VMBlockHandle	ttypeBlock;
		MemHandle   	tmem;
		genptr	    	tsymBase;
		SegDesc	    	*sd;
		ObjSym	    	*os;
		word	    	symOff;

		name = ST_Enter(symbols, strings, (char *)bp+4, bp[3]);

		/*
		 * XXX: procedure-static symbols?
		 */
		if (!CVDetermineSymbolBlock(file, name, "label", bp, procSD,
					    &sd, &addr, &tsymBlock, &ttypeBlock,
					    &tmem, &tsymBase))
		{
		    break;
		}

		os = CVAllocSymLocked(tsymBlock, tmem, &symOff,
				      (ObjSymHeader **)&tsymBase);
		os->type = OSYM_LABEL;
		os->name = name;
		os->flags = 0;
		os->u.label.address = addr;
		os->u.label.near = (bp[2] == 0);

		/*
		 * Mark the thing global if it's really declared public.
		 */
		if (CVLocatePublic(name, (SegDesc **)NULL, (word *)NULL,
				   &real, &alias) && real)
		{
		    os->flags |= OSYM_GLOBAL;
		    if (alias != name) {
			Sym_Enter(symbols, sd->syms, alias, tsymBlock, symOff);
		    }
		}

		/*
		 * Enter the symbol into the table for the segment.
		 */
		Sym_Enter(symbols, sd->syms, name, tsymBlock, symOff);

		if (sd == procSD) {
		    /*
		     * Using procedure-global blocks; be sure to update the
		     * procedure-global base of the symbol block....
		     */
		    symBase = tsymBase;
		} else {
		    /*
		     * Release the symbol and type blocks.
		     */
		    VMUnlockDirty(symbols, tsymBlock);
		    VMUnlockDirty(symbols, ttypeBlock);
		}
		break;
	    }
	    case CST_CONST:
		assert(0);
	    case CST_SKIP_ME:
		break;
	    case CST_CHANGE_SEG:
	    {
		word	extraOff;

		if (!CVLocateFixup(file, bp-symSeg, &defSeg, &extraOff)) {
		    Notify(NOTIFY_ERROR,
			   "%s: cannot determine new segment for CHANGE_SEG",
			   file);
		}
		break;
	    }
	    case CST_REG_VAR:
	    {
		ID  	name;
		ObjSym	*os;

		name = ST_Enter(symbols, strings, (char *)bp+4, bp[3]);

		if (scopeTop == 0) {
		    Notify(NOTIFY_ERROR,
			   "%s: register variable %i outside any scope",
			   file, name);
		    break;
		}

		os = CVAllocLocalSym(symBlock, mem, scopeStack[scopeTop-1],
				     &lastLocal, &symBase);
		os->type = OSYM_REGVAR;
		os->name = name;
		os->flags = 0;
		os->u.localVar.type = CVFetchType(file, typeBlock,
						  MSObj_GetWordImm(bp));
		if (*bp >= CSR_DX_AX) {
		    Notify(NOTIFY_ERROR,
			   "%s: unhandled register number %d",
			   file, *bp);
		} else if (*bp >= CSR_SEG_REG_START) {
		    os->u.localVar.offset =
			(*bp - CSR_SEG_REG_START) + OSYM_REG_ES;
		} else if (*bp >= CSR_DWORD_REG_START) {
		    Notify(NOTIFY_ERROR,
			   "%s: unhandled register number %d",
			   file, *bp);
		} else if (*bp >= CSR_WORD_REG_START) {
		    os->u.localVar.offset =
			(*bp - CSR_WORD_REG_START) + OSYM_REG_AX;
		} else {
		    os->u.localVar.offset =
			(*bp - CSR_BYTE_REG_START) + OSYM_REG_AL;
		}
		break;
	    }
#endif
	}
	bp = base + len;
    }

    /*
     * Process communal vawriables here.
     */

    /*
     * Shrink the final block of address-bearing symbols for each segment
     * encountered in this file down to the smallest it can go.
     */
    for (i = Vector_Length(segments)-1; i >= 0 ; i--) {
	SegDesc	    	*sd;
	ObjSymHeader	*osh;
	ObjTypeHeader	*oth;
	word	    	curSize;
	word	    	newSize;
	MemHandle   	mem;
	MemHandle   	tmem;

	Vector_Get(segments, i, &sd);
	if ((sd != CV_TYPES_SEGMENT) && (sd != CV_SYMS_SEGMENT) && sd->addrT) {
	    osh = (ObjSymHeader *)VMLock(symbols, sd->addrT, &mem);
	    oth = (ObjTypeHeader *)VMLock(symbols, osh->types, &tmem);
	    MemInfo(tmem, (genptr *)NULL, &curSize);
	    newSize = sizeof(*oth)  + oth->num * sizeof(ObjType);
	    if (newSize < curSize) {
		MemReAlloc(tmem, newSize, 0);
		VMDirty(symbols, osh->types);
	    }
	    VMUnlock(symbols, osh->types);

	    MemInfo(mem, (genptr *)NULL, &curSize);
	    newSize = sizeof(*osh) + osh->num * sizeof(ObjSym);
	    if (newSize < curSize) {
		MemReAlloc(mem, newSize, 0);
		VMDirty(symbols, sd->addrT);
	    }
	    VMUnlock(symbols, sd->addrT);
	}
    }
}




/***********************************************************************
 *				CV32_Finish
 ***********************************************************************
 * SYNOPSIS:	    Finish processing an object file.
 * CALLED BY:	    Pass1MS_Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Lots
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/91		Initial Revision
 *
 ***********************************************************************/
void
CV32_Finish(const char *file,
	  Boolean   happy,  	/* TRUE if file read successfully */
	  int	    pass)   	/* Pass number (1 or 2) */
{
    if (happy) {
	if (pass == 1) {
	    /*
	     * Process symbol records
	     */
	    CV32ProcessSymbols(file);
	    CV32ProcessUnprocessedTypeRecords(file);
	    Pass1MS_Finish((char *)file, happy, pass);
	} else {
	    Pass2MS_Finish((char *)file, happy, pass);
	}
    }

    if (typeSize != 0 && pass == 1) {
	free((void *)typeSeg);
    }

    if (symSize != 0 && pass == 1) {
	free((void *)symSeg);
    }

    if (pass == 1) {
	MSObj_FreeSaved(&comHead);
	MSObj_FreeSaved(&pubHead);
	MSObj_FreeFixups(&fixHead);
    }
}


/***********************************************************************
 *				CV32_Check
 ***********************************************************************
 * SYNOPSIS:	    See if the object record is destined for us and
 *	    	    process it if so.
 * CALLED BY:	    Pass1MS_Load
 * RETURN:	    TRUE if we processed it.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/91		Initial Revision
 *
 ***********************************************************************/
int
CV32_Check(const char *file,
	 byte	    rectype,
	 word	    reclen,
	 byte	    *bp,
	 int	    pass)   	/* Pass #: 1 if pass 1, 2 if pass 2 */
{
    switch(rectype) {
	case MO_SEGDEF32:
	case MO_SEGDEF:
	{
	    int 	type;	/* Segment combine type */
	    int 	align;	/* Segment alignment */
	    ID  	name;	/* Segment name */
	    ID  	class;	/* Segment class name */
	    word	frame;	/* Absolute frame, if any */
	    long	size;	/* Segment size */
	    SegDesc	*sd;	/* Associated segment descriptor */

	    if (!MSObj_DecodeSegDef((char *)file, rectype, bp,
				    &type, &align, &name, &class,
				    &frame, &size))
	    {
		return(FALSE);
	    }

	    /*
	     * Look for segments that hold debugging information and
	     * handle them specially: they don't get real segment
	     * descriptors.
	     */
	    if (name == cvTypesSegment.name) {
		if (typeSize != 0) {
		    Notify(NOTIFY_ERROR,
			   "%s: type descriptor segment already defined for this file",
			   file);
		} else if (size != 0) {
		    /*
		     * Allocate room to store all the descriptors in one
		     * block, according to the size specified for the
		     * segment. Note that High C likes to sometimes
		     * generate two segment definitions for this thing.
		     * God only knows why... One of them has size 0, hence
		     * the test for size != 0...
		     */
		    typeSize = size;
		    if (pass == 1) {
			typeSeg = (byte *)malloc(size);
		    }
		}
		sd = CV_TYPES_SEGMENT;
	    } else if (name == cvSymsSegment.name) {
		if (symSize != 0) {
		    Notify(NOTIFY_ERROR,
			   "%s: symbol segment already defined for this file",
			   file);
		} else if (size != 0) {
		    /*
		     * Allocate room to store all the symbols in one
		     * block, according to the size specified for the
		     * segment. Note that High C likes to sometimes
		     * generate two segment definitions for this thing.
		     * God only knows why... One of them has size 0, hence
		     * the test for size != 0...
		     */
		    symSize = size;
		    if (pass == 1) {
			symSeg = (byte *)malloc(size);
		    }
		}
		sd = CV_SYMS_SEGMENT;
	    } else {
		/*
		 * Not processed.
		 */
		return(FALSE);
	    }

	    /*
	     * Place the descriptor in the segment map for this file.
	     */
	    Vector_Add(segments, VECTOR_END, &sd);

	    /*
	     * If second pass, add the size too so the segSizes vector doesn't
	     * get out of whack.
	     */
	    if (pass == 2) {
		Vector_Add(segSizes, VECTOR_END, &size);
	    }
	    break;
	}
	case MO_LEDATA32:
	case MO_LEDATA:
	{
	    /*
	     * Handle debugging types and symbols here. Also need to count
	     * run-time relocations...
	     */
	    SegDesc	    *sd;
	    dword	    startOff;

	    sd = MSObj_GetSegment(&bp);
	    if (rectype == MO_LEDATA32) {
		MSObj_GetDWord(startOff, bp);
	    } else {
		MSObj_GetWord(startOff, bp);
	    }

	    if (sd != CV_SYMS_SEGMENT && sd != CV_TYPES_SEGMENT) {
			return(FALSE);
	    }
	    if (sd == CV_SYMS_SEGMENT) {
		/*
		 * Save symbols to be processed once we've got types.
		 */
		int	    datalen = reclen - (bp - msobjBuf);

		assert(symSize != 0);
		assert(startOff + datalen <= symSize);

		if (pass == 1) {
		    /*
		     * Copy this chunk of symbols to their proper place.
		     */
		    bcopy(bp, symSeg+startOff, datalen);
		}

		if (msobjBuf[reclen] == MO_FIXUPP) {
		    /*
		     * Now save the fixups away. First find where they
		     * should go in the list. We search from the end for
		     * the first record whose starting offset is below this
		     * one's. We start searching from the end b/c these
		     * records will almost always be in ascending order in
		     * the object file.
		     */
		    if (pass == 1) {
			MSObj_SaveFixups(startOff, reclen, datalen, &fixHead);
		    }

		    /*
		     * Need to run through the fixups to make sure the
		     * threads are set up correctly, since, in theory,
		     * threads can be used between object records. Sigh.
		     */
			(void)Pass1MS_CountRels((char *)file,rectype, sd, startOff,
					    reclen, bp);
		}
	    } else {
		/*
		 * There should be no need of fixups in this segment, and
		 * the segment must have already been defined. The data
		 * fill the remainder of the record...
		 */
		int	datalen = reclen - (bp - msobjBuf);

		assert(msobjBuf[reclen] != MO_FIXUPP);
		assert(typeSize != 0);
		assert(startOff + datalen <= typeSize);

		if (pass == 1) {
		    bcopy(bp, typeSeg+startOff, datalen);
		}
	    }
	    break;
	}
	case MO_LIDATA32:
	case MO_LIDATA:
	{
	    /*
	     * Need to count run-time relocations...should not be any
	     * debugging types or symbols defined this way.
	     */
	    SegDesc	    *sd;
	    dword	    startOff;

	    sd = MSObj_GetSegment(&bp);
	    if (rectype == MO_LIDATA32) {
		MSObj_GetDWord(startOff, bp);
	    } else {
		MSObj_GetWord(startOff, bp);
	    }

	    assert ((sd != CV_SYMS_SEGMENT) &&
		    (sd != CV_TYPES_SEGMENT));
	    return(FALSE);
	}
	case MO_LPUBDEF1:
	case MO_LPUBDEF2:
	case MO_PUBDEF:
	    if (pass == 1) {
		MSObj_SaveRecord(rectype, reclen, &pubHead);
	    }
	    break;
	case MO_COMDEF:
	    if (pass == 1) {
		MSObj_SaveRecord(rectype, reclen, &comHead);
	    }
	    break;
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
