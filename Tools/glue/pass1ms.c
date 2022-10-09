/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue
 * FILE:	  pass1ms.c
 *
 * AUTHOR:  	  Adam de Boor: Nov 12, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Pass1MS_Load	    Load in definitions from a microsoft object file
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/12/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Perform pass1 loading operations for a Microsoft(tm) object file.
 *
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: pass1ms.c,v 1.30 96/07/08 17:29:46 tbradley Exp $";
#endif lint


#include    <config.h>
#include    "glue.h"
#include    "msobj.h"
#include    "geo.h"
#include    "obj.h"
#include    "output.h"
#include    "sym.h"
#include    "library.h"
#include    "cv.h"

#include    <objfmt.h>
typedef int (*CmpCallback)(const void *, const void*);

#define MS_SYMS_NOT_ENTERED 1	/* Value stuck in osh->seg when we add symbols
				 * from a PUBDEF record so we know that all
				 * further symbols from this object file must
				 * go in the same block so they end up in the
				 * correct by-address order. */

/***********************************************************************
 *				Pass1MSAddLMemSegment
 ***********************************************************************
 * SYNOPSIS:	    Record another lmem segment we have to mangle.
 * CALLED BY:	    Pass1MS_ProcessObject
 * RETURN:	    nothing
 * SIDE EFFECTS:    another entry may be added to lmemSegs
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 3/92		Initial Revision
 *
 ***********************************************************************/
static void
Pass1MSAddLMemSegment(SegDesc *sd)
{
    MSObjLMemData **lmdPtr;
    MSObjLMemData *lmd;
    int	    	    i;

    /*
     * See if this segment's been seen before (ya never know, ya know?)
     */
    for (i = Vector_Length(lmemSegs),
	 lmdPtr = (MSObjLMemData **)Vector_Data(lmemSegs);

	 i > 0;

	 i--, lmdPtr++)
    {
	if ((*lmdPtr)->handles == sd) {
	    return;
	}
    }

    /*
     * Allocate a new descriptor to track the thing, placing the handle
     * table at the end.
     */
    lmd = (MSObjLMemData *)malloc(sizeof(MSObjLMemData) + sd->size);
    /*
     * Record affected segment.
     */
    lmd->handles = sd;
    /*
     * Empty chain of fixup records is self-referential.
     */
    lmd->fixups.prev = lmd->fixups.next = (MSSaveRec *)&lmd->fixups;
    /*
     * Make sure anything we don't read from the file is zero.
     */
    bzero(lmd->handleData, sd->size);

    /*
     * Place pointer to the new record at the end of the vector.
     */
    Vector_Add(lmemSegs, VECTOR_END, (Address)&lmd);
}

/***********************************************************************
 *				Pass1MSRecordLMemHandles
 ***********************************************************************
 * SYNOPSIS:	    Record more data from the file in the handle table
 *	    	    for the lmem segment.
 * CALLED BY:	    Pass1MS_ProcessObject
 * RETURN:	    nothing
 * SIDE EFFECTS:    data are copied into the block
 *	    	    any fixups are added to the chain of saved records
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 3/92		Initial Revision
 *
 ***********************************************************************/
static void
Pass1MSRecordLMemHandles(SegDesc    	*sd,
			 byte	    	rectype,    /* Type of data record */
			 byte	    	*bp,	    /* Start of data */
			 word	    	startOff,   /* Offset w/in segment at
						     * which these data start */
			 word	    	reclen)	    /* Length of data record */
{
    MSObjLMemData 	**lmdPtr;
    int	    	    	i;
    byte    	    	*dest;

    for (i = Vector_Length(lmemSegs),
	 lmdPtr = (MSObjLMemData **)Vector_Data(lmemSegs);

	 i > 0;

	 i--, lmdPtr++)
    {
	if ((*lmdPtr)->handles == sd) {
	    break;
	}
    }

    assert(i > 0);

    /*
     * Figure where the data for this record go in the scheme of things.
     */
    dest = ((byte *)(*lmdPtr)->handleData) + startOff;

    if (rectype == MO_LEDATA) {
	/*
	 * Copy the data straight out of the record and into the buffer.
	 */
	int 	datalen = reclen - (bp - msobjBuf);

	bcopy(bp, dest, datalen);

	if (msobjBuf[reclen] == MO_FIXUPP) {
	    /*
	     * Save the fixups away.
	     */
	    MSObj_SaveFixups(startOff, reclen, datalen, &(*lmdPtr)->fixups);
	}
    } else {
	/*
	 * Expand the data into the appropriate part of the handle table.
	 */
	MSObj_ExpandIData(&bp, &dest);

	/*
	 * We can't handle fixups in this case (if we were to record them,
	 * they'd be meaningless, as their offsets refer to the object record
	 * before it's been expanded).
	 */
	assert(msobjBuf[reclen] != MO_FIXUPP);
    }
}


/***********************************************************************
 *				Pass1MSCheckForObjectBlock
 ***********************************************************************
 * SYNOPSIS:	    Examine an LEDATA record for the header segment
 *		    of an lmem trio to determine if it's an object
 *	    	    block. If it is, set the isObjSeg bit for it,
 *	    	    and set the doObjReloc bit for the heap segment
 *	    	    of the trio, if it's defined.
 * CALLED BY:	    Pass1MS_ProcessObject
 * RETURN:	    nothing
 * SIDE EFFECTS:    isObjSeg and doObjReloc may be altered
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/15/92		Initial Revision
 *
 ***********************************************************************/
static void
Pass1MSCheckForObjectBlock(SegDesc    	*sd,	    /* Descriptor for header
						     * segment of the trio */
			   byte	    	rectype,    /* Type of data record */
			   byte	    	*bp,	    /* Start of data */
			   word	    	startOff,   /* Offset w/in segment at
						     * which these data start */
			   word	    	reclen)	    /* Length of data record */
{
    int 	datalen = reclen - (bp - msobjBuf);

    /*
     * Make sure the entire field is present.
     * XXX: WHAT IF SOMETHING STUPID BREAKS THE FIELD ACROSS RECORDS?
     */
    if (startOff <= offsetof(LMemBlockHeader, LMBH_lmemType) &&
	startOff + datalen >= (offsetof(LMemBlockHeader, LMBH_lmemType) + 2))
    {
	/*
	 * Extract the value of the LMBH_type field from the record.
	 */
	word	w = bp[offsetof(LMemBlockHeader, LMBH_lmemType)-startOff] |
	    (bp[offsetof(LMemBlockHeader, LMBH_lmemType)-startOff+1] << 8);

	/*
	 * If the thing's an object block, record that in this segment's
	 * descriptor
	 */
	if (w == LMEM_TYPE_OBJ_BLOCK) {
	    sd->isObjSeg = 1;
	    if (sd->group->numSegs == 3) {
		/*
		 * Have all 3 segments that make up the lmem group, so we need
		 * to also set the doObjReloc flag for the heap segment. If
		 * there aren't 3 segments, we don't have to worry, as the
		 * flag we just set for the header will be copied to the heap
		 * when the 3d segment arrives, in Pass1MS_ProcessObject.
		 */
		sd->group->segs[LMEM_HEAP]->doObjReloc = 1;
	    }
	}
    }
}

/***********************************************************************
 *				Pass1MSLayoutLMem
 ***********************************************************************
 * SYNOPSIS:	    Apply all fixups to the handle table for this lmem
 *	    	    segment, then run through the table to figure out
 *	    	    how big the heap should really be.
 * CALLED BY:	    Pass1MS_Finish
 * RETURN:	    nothing
 * SIDE EFFECTS:    the descriptor is freed, and the 'size' field of the
 *	    	    heap segment is adjusted upward as appropriate
 *
 * STRATEGY:	    Once the handle table has been fixed up, so it
 *		    contains the actual offsets of the chunks within the
 *	    	    heap segment, we:
 *	    	    1) figure the size of each chunk
 *	    	    2) pad it and its size word to a dword boundary
 *	    	    laying the chunks end to end gives us the size of the
 *	    	    heap segment.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 3/92		Initial Revision
 *
 ***********************************************************************/
static void
Pass1MSLayoutLMem(const char *file,
		  SegDesc   *sd)    	/* Descriptor for handles segment
					 * of lmem troika defined in this
					 * object file */
{
    MSSaveFixupRec  *sfp;
    SegDesc 	    *heap;
    word    	    size;
    int	    	    i;
    word    	    *handle;
    MSObjLMemData   *lmd, **lmdPtr;

    lmd = NULL;

    /*
     * Locate the MSObjLMemData descriptor for this lmem segment.
     */
    for (i = Vector_Length(lmemSegs),
	 lmdPtr = (MSObjLMemData **)Vector_Data(lmemSegs);

	 i > 0;

	 lmdPtr++, i--)
    {
	if ((*lmdPtr)->handles == sd) {
	    lmd = *lmdPtr;
	    break;
	}
    }

    assert(lmd != NULL);


    heap = lmd->handles->group->segs[LMEM_HEAP];

    /*
     * Make sure the various things MSObj_PerformRelocations might use for
     * relocating the handles are set to 0.
     */
    heap->group->foff =
	lmd->handles->foff =
	    heap->foff =
		heap->grpOff =
		    lmd->handles->grpOff = 0;

    /*
     * If heap is now marked as requiring object relocations, zero the number
     * of runtime relocations, as there will be none.
     */
    if (heap->doObjReloc) {
	heap->nrel = 0;
    }

    /*
     * Shouldn't have been any other data for these segments.
     */
    assert(lmd->handles->nextOff == 0);
    assert(heap->nextOff == 0);

    /*
     * Now perform all the relocations.
     */
    for (sfp = (MSSaveFixupRec *)lmd->fixups.next;
	 sfp != (MSSaveFixupRec *)&lmd->fixups;
	 sfp = (MSSaveFixupRec *)sfp->links.next)
    {
	word	fixlen = sfp->data[0] | (sfp->data[1] << 8);

	if (!MSObj_PerformRelocations(file,
				      (byte *)lmd->handleData+sfp->startOff,
				      &sfp->data[2],
				      &sfp->data[2+fixlen-1],
				      lmd->handles,
				      sfp->startOff,
				      1,
				      (byte **)NULL))
	{
	    Notify(NOTIFY_ERROR, "%s: unable to prepare handle table for %i",
		   file, lmd->handles->group->name);
	    free((malloc_t)lmd);
	    return;
	}
    }

    /*
     * Free the chain of fixups.
     */
    MSObj_FreeFixups(&lmd->fixups);

    /*
     * Now run through all the handles, forwards, relying on the fact that
     * the chunks to which things refer must be in ascending order (so as we
     * back through the table, we're always going to lower addresses). Each
     * chunk ends up being the number of bytes from it to the next higher, plus
     * 2 bytes (the size word) plus padding to bring it up to the nearest
     * dword. The sum of all these sizes gives us the size of the heap segment.
     *
     * As we move through, we also adjust the address symbols that point into
     * each chunk.
     */
    i = lmd->handles->size/2;
    handle = &lmd->handleData[0];
    size = 0;

    while (i > 0) {
	if ((*handle != 0) && (*handle != 0xffff)) {
	    word    *nextHandle;
	    int	    j;
	    word    endOff;

	    /*
	     * Find the next handle in the table that has data associated
	     * with it.
	     */
	    for (nextHandle = handle+1, j = i-1; j > 0; nextHandle++, j--) {
		if ((*nextHandle != 0) && (*nextHandle != 0xffff)) {
		    break;
		}
	    }
	    if (j > 0) {
		endOff = swaps(*nextHandle);
	    } else {
		/*
		 * This is the last non-free, non-zero-length handle in the
		 * table, so it ends at the end of the heap.
		 */
		endOff = heap->size + LMEM_SIZE_SIZE;
	    }

	    assert(endOff > swaps(*handle));

	    /*
	     * Add the size of this chunk, plus size word, plus padding, into
	     * the size of the heap.
	     */
	    size += (((endOff-swaps(*handle))+2)+3) & ~3;
	}
	handle++, i--;
    }

    /*
     * Set the heap to be the calculated size.
     */
    assert(size > heap->size);
    lmd->heapSize = heap->size;
    heap->size = size;
}



/***********************************************************************
 *				Pass1MSCompareSyms
 ***********************************************************************
 * SYNOPSIS:	    Compare two address-bearing symbols so they can be
 *	    	    sorted in ascending order.
 * CALLED BY:	    Pass1MS_Finish via qsort.
 * RETURN:	    < 0 if os1's address is less than os2's, 0 if they're
 *	    	    equal (choke), > 0 if os1's is greater than os2's
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 4/91		Initial Revision
 *
 ***********************************************************************/
static int
Pass1MSCompareSyms(ObjSym   *os1,
		   ObjSym   *os2)
{
    assert(Obj_IsAddrSym(os1) && Obj_IsAddrSym(os2));

    if (os1->u.addrSym.address < os2->u.addrSym.address) {
	return (-1);
    } else if (os1->u.addrSym.address > os2->u.addrSym.address) {
	return (1);
    } else {
	/* HighC's libraries have labels at the same address, so...
	assert(0);
	*/
	return(0);
    }
}

/***********************************************************************
 *				Pass1MS_Finish
 ***********************************************************************
 * SYNOPSIS:	    Finish off an object file.
 * CALLED BY:	    Pass1MS_Load through msbjFinish
 * RETURN:	    Nothing
 * SIDE EFFECTS:    none
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
Pass1MS_Finish(const char *file, int happy, int pass)
{
    int	    i;

    /*
     * Adjust the "last" value for the final line number block for the segment
     * to encompass all the data that'll come into the segment from this
     * object file so Swat can find line number information for any byte
     * in the segment.
     */
    for (i = Vector_Length(segments)-1; i >= 0; i--) {
	SegDesc	    	    *sd;

	Vector_Get(segments, i, &sd);

	if (sd > MS_MIN_SEGMENT) {
	    if (sd->lineMap) {
		ObjAddrMapHeader    *oamh;
		ObjAddrMapEntry 	*oame;

		oamh = (ObjAddrMapHeader *)VMLock(symbols, sd->lineMap, (MemHandle *)NULL);
		oame = ObjFirstEntry(oamh, ObjAddrMapEntry)+oamh->numEntries-1;

		if (oame->last < sd->size) {
		    oame->last = sd->size;
		    VMDirty(symbols, sd->lineMap);
		}
		VMUnlock(symbols, sd->lineMap);
	    }
	    if (sd->addrT) {
		ObjSymHeader	*osh;

		osh = (ObjSymHeader *)VMLock(symbols, sd->addrT, (MemHandle *)NULL);
		if (osh->seg == MS_SYMS_NOT_ENTERED) {
		    ObjSym  *os;
		    ObjSym  *base = NULL;
		    ObjSym  *last = NULL;

		    /*
		     * Find the symbols at the end that come from this file
		     * (their address is >= the offset (sd->nextOff) of data
		     * for this segment from this file).
		     */
		    os = ObjFirstEntry(osh, ObjSym) + osh->num - 1;
		    while (os >= ObjFirstEntry(osh, ObjSym) && base == NULL) {
			switch(os->type) {
			    case OSYM_VAR:
			    case OSYM_CHUNK:
			    case OSYM_ONSTACK:
			    case OSYM_PROC:
			    case OSYM_LABEL:
			    case OSYM_CLASS:
			    case OSYM_MASTER_CLASS:
			    case OSYM_VARIANT_CLASS:
				if (os->u.addrSym.address < sd->nextOff) {
				    base = last;
				} else {
				    last = os;
				}
				break;
			}
			os--;
		    }
		    if (base == NULL) {
			base = ObjFirstEntry(osh, ObjSym);
		    }
		    last = ObjFirstEntry(osh, ObjSym) + osh->num;
		    assert(last != base);

		    qsort(base, last-base, sizeof(*base), (CmpCallback) Pass1MSCompareSyms);

		    for (os = base; os < last; os++) {
			Sym_Enter(symbols, sd->syms, os->name,
				  sd->addrT, (genptr)os - (genptr)osh);
		    }
		    osh->seg = 0;
		    VMDirty(symbols, sd->addrT);
		}
		VMUnlock(symbols, sd->addrT);
	    }
	}
    }
    /*
     * Now go through the lmem segments and abuse them.
     */
    for (i = Vector_Length(segments)-1; i >= 0; i--) {
	SegDesc	    *sd;

	Vector_Get(segments, i, &sd);

	if (happy && (sd->combine == SEG_LMEM) &&
	    (MSObj_GetLMemSegOrder(sd) == LMEM_HANDLES))
	{
	    Pass1MSLayoutLMem(file, sd);
	}
    }
}

/***********************************************************************
 *				Pass1MSAddLines
 ***********************************************************************
 * SYNOPSIS:	    Add the line number information from the current
 *	    	    object record to the given segment's table.
 * CALLED BY:	    Pass1MS_Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    a few.
 *
 * STRATEGY:
 *	If segment has no line information yet, create a line map and
 *	initial block, pointing the lineH and lineT to it.
 *
 *	while there are line number records remaining:
 *	    Lock down the tail line block. If it's not at capacity, relocate &
 *	    copy as many line number records as will fit in the block.
 *
 *	    If any line numbers remain, allocate and initialize a new block.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 1/91		Initial Revision
 *
 ***********************************************************************/
static void
Pass1MSAddLines(SegDesc	    *sd,    	/* Segment to which to add the lines */
		byte	    *bp,    	/* First record to add */
		word	    reclen) 	/* Bytes of data in the whole record */
{
    ObjLineHeader   	*olh;	    /* Header for current line block */
    ObjLine 	    	*ol;	    /* Current line entry being filled */

    assert((reclen & 3) == 0);

    if (sd->lineT == 0) {
	/*
	 * No line map allocated yet, do so now. Allocate room for a single
	 * address map entry, for now.
	 */
	sd->lineH = sd->lineT = VMAlloc(symbols,
					OBJ_INIT_LINES,
					OID_LINE_BLOCK);

	olh = (ObjLineHeader *)VMLock(symbols, sd->lineT, (MemHandle *)NULL);
	olh->next = 0;
	olh->num = 0;
	VMUnlock(symbols, sd->lineT);
    }


    while (reclen > 0) {
	word	    curSize;	    /* Size of current line block */
	word	    newSize;	    /* Size it should be */
	MemHandle   mem;    	    /* Memory handle for resizing it */
	word        spaceLeft;	    /* Number of bytes left in it that we
				     * may fill */
	int 	    numLeft;	    /* Number of line entries we have left
				     * to fill from our buffer */
	int 	    prevStart = -1;
	int 	    prevLine = -1;

	VMInfo(symbols, sd->lineT, &curSize, (MemHandle *)NULL, (VMID *)NULL);
	olh = (ObjLineHeader *)VMLock(symbols, sd->lineT, &mem);

	/*
	 * If the block isn't as big as we let it get, let us resize it...
	 */
	if (curSize < OBJ_INIT_LINES) {
	    newSize = OBJ_INIT_LINES;
	} else {
	    newSize = curSize;
	}

	spaceLeft = newSize - (olh->num * sizeof(ObjLine) +
			       sizeof(ObjLineHeader));

	/*
	 * If there's enough room in the current block for the current file and
	 * one ObjLine record (for a total of 3 new records), place as many
	 * records as will fit at the end of the block.
	 */
	if (spaceLeft >= 3 * sizeof(ObjLine)) {
	    if (curSize != newSize) {
		MemReAlloc(mem, newSize, 0);
		MemInfo(mem, (genptr *)&olh, (word *)NULL);
	    }

	    ol = ObjFirstEntry(olh, ObjLine);

	    if (olh->num == 0) {
		/*
		 * A virgin block -- stick the current file name at the very
		 * start of the block and up the number of entries, reducing
		 * the space left in the block accordingly.
		 */
		*(ID *)ol++ = msobj_CurFileName;
		olh->num = 1;
		spaceLeft -= sizeof(ObjLine);
	    } else {
		ID  	lastFile = NullID; /* Avoid GCC complaint */
		ObjLine	*olend;

		/*
		 * See if the current file is actually the last file mentioned
		 * in the block. If not, then we have to switch it to the
		 * current file. We can't search backward, b/c the low word
		 * of an ID could very well be 0...
		 */
		olend = ol + olh->num;

		while (ol < olend) {
		    if (ol->line == 0) {
			ol++;
			lastFile = *(ID *)ol;
		    }
		    ol++;
		}

		if (lastFile != msobj_CurFileName) {
		    /*
		     * Switch to the current file, placing a bogus record (0
		     * line) followed by the current file's ID. This uses
		     * up two more entries in the block.
		     */
		    ol->line = 0;
		    ol++;
		    *(ID *)ol++ = msobj_CurFileName;
		    olh->num += 2;
		    spaceLeft -= 2 * sizeof(ObjLine);
		}
	    }

	    /*
	     * ol == place to store first record. Increase the number of
	     * entries in the block by the number we're about to stick in
	     * there. Line records in both types of object files are always
	     * 4 bytes each....
	     */
	    if (reclen < spaceLeft) {
		numLeft = reclen / sizeof(ObjLine);
	    } else {
		numLeft = spaceLeft / sizeof(ObjLine);
	    }

	    olh->num += numLeft;
	    reclen -= numLeft * 4;
	    spaceLeft -= numLeft * sizeof(ObjLine);

	    while (numLeft > 0) {
		word 	line,	    /* Line number for current record */
			offset;	    /* Relocated offset for current record */

		/*
		 * Fetch the line and offset from the record.
		 */
		MSObj_GetWord(line, bp);
		MSObj_GetWord(offset, bp);

		/*
		 * Relocate the offset.
		 */
		offset += sd->nextOff;

		/*
		 * Now store the record.
		 */
		if (prevStart == -1) {
		    prevStart = line;
		}

		if (prevLine > line)
		{
		    /*
		     * We've backtracked in the range, so add a map entry
		     * for just the line by itself (we're assuming it's the
		     * "next" and "test" part of a for loop, so there's just
		     * one line...)
		     */
		    AddSrcMapEntry(msobj_CurFileName, sd, line, line);
		}
		else
		{
		    /*
		     * The range continues -- remember the last line in
		     * the range.
		     */
		    prevLine = line;
		}

	        assert(line != 0);
		ol->line = line;
		ol->offset = offset;
		ol++;
		/*
		 * Adjust loop vars...
		 */
		numLeft--;
	    }

	    if (prevStart != -1) {
		AddSrcMapEntry(msobj_CurFileName, sd, prevStart, prevLine);
	    }

	    VMDirty(symbols, sd->lineT);

	    /*
	     * If any bytes left in the block, reduce the block to just
	     * hold the number of entries we say are there.
	     */
	    if (spaceLeft > 0) {
		MemReAlloc(mem, newSize - spaceLeft, 0);
	    }
	}

	/*
	 * If there are still line numbers to be copied over, we need to
	 * allocate and initialize a new block to hold them.
	 */
	if (reclen > 0) {
	    VMBlockHandle   next;

	    /*
	     * Enter the block in the line map for the segment.
	     */
	    Out_FinishLineBlock(sd, sd->lineT);


	    /*
	     * Allocate another block big and link it to the current tail.
	     */
	    next = olh->next = VMAlloc(symbols,
				       OBJ_INIT_LINES,
				       OID_LINE_BLOCK);

	    VMUnlockDirty(symbols, sd->lineT);

	    /*
	     * Now initialize the new tail to contain no entries and have
	     * no next block.
	     */
	    sd->lineT = next;
	    olh = (ObjLineHeader *)VMLock(symbols, sd->lineT,
					  (MemHandle *)NULL);
	    olh->next = 0;
	    olh->num = 0;
	    VMDirty(symbols, sd->lineT);
	}

	/*
	 * Unlock the tail line block, whether we used it or not.
	 */
	VMUnlock(symbols, sd->lineT);
    }
}

/***********************************************************************
 *				Pass1MSReplaceFileName
 ***********************************************************************
 * SYNOPSIS:	    Add the line number information from the current
 *	    	    object record to the given segment's table.
 * CALLED BY:	    Pass1MS_Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    a few.
 *
 * STRATEGY:
 *	If segment has no line information yet, create a line map and
 *	initial block, pointing the lineH and lineT to it.
 *
 *	while there are line number records remaining:
 *	    Lock down the tail line block. If it's not at capacity, relocate &
 *	    copy as many line number records as will fit in the block.
 *
 *	    If any line numbers remain, allocate and initialize a new block.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 1/91		Initial Revision
 *
 ***********************************************************************/
static void
Pass1MSReplaceFileName(
		ID	    oldName,    	/* First record to add */
		ID	    newName) 	/* Bytes of data in the whole record */
{
    int i;
    ObjLineHeader   	*olh;	    /* Header for current line block */
    ObjLine 	    	*ol;	    /* Current line entry being filled */
    VMBlockHandle	next, last;
    for (i = Vector_Length(segments)-1; i >= 0; i--) {
	SegDesc	    	    *sd;

	Vector_Get(segments, i, &sd);
	
	next = sd->lineT;
	if (next != 0) {
		
	    word	    curSize;	    /* Size of current line block */
	    word	    newSize;	    /* Size it should be */
	    MemHandle   mem;    	    /* Memory handle for resizing it */
	    word        spaceLeft;	    /* Number of bytes left in it that we
					     * may fill */
	    int 	    numLeft;	    /* Number of line entries we have left
					     * to fill from our buffer */
	    int 	    prevStart = -1;
	    int 	    prevLine = -1;
	    int nlines;
	    Boolean first = TRUE;
	
	    VMInfo(symbols, next, &curSize, (MemHandle *)NULL, (VMID *)NULL);
	    olh = (ObjLineHeader *)VMLock(symbols, next, &mem);

	    if(olh->num > 0) {
		ObjLine	*olend;		    
		
		ol = ObjFirstEntry(olh, ObjLine);
		
		olend = ol + olh->num;
		nlines = olh->num;

		while (ol < olend) {
			nlines--;

		    if(first) {
			
			    if(*(ID *)ol == oldName) {
    				
    			    *(ID *)ol = newName;
    			    VMDirty(symbols, next);
    			}
			first = FALSE;
			 
		    } else if (ol->line == 0) {
			ol++;
			if(*(ID *)ol == oldName) {
				
			    *(ID *)ol = newName;
			    VMDirty(symbols, next);
			}
		    }
		    ol++;
		}
		
	    }
	    /*
	     * Unlock the tail line block, whether we used it or not.
 	     */
	     last = next;
	     next = olh->next;
	     VMUnlockDirty(symbols, last);
	}
    }
    
    RenameFileSrcMapEntry(oldName, newName);    
}

/***********************************************************************
 *				Pass1MSCountBlocks
 ***********************************************************************
 * SYNOPSIS:	    Count the number of repeated blocks there are holding
 *	    	    the data at a given offset.
 * CALLED BY:	    Pass1MSCountRels, self
 * RETURN:	    # of times the data are repeated
 *	    	    Offset in record past block holding the data
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 4/91		Initial Revision
 *
 ***********************************************************************/
static int
Pass1MSCountBlocks(word	    *iPtr,
		   word	    offset,
		   byte	    *data)
{
    word    repCount;
    word    blockCount;

    repCount = data[*iPtr] | (data[(*iPtr) + 1] << 8);
    *iPtr += 2;
    blockCount = data[*iPtr] | (data[(*iPtr) + 1] << 8);
    *iPtr += 2;

    if (blockCount == 0) {
	/*
	 * No nested blocks, so advance iPtr over the data in the content
	 * field and return the repCount for the block.
	 */
	*iPtr += data[(*iPtr)] + 1;
	return(repCount);
    } else {
	int 	j;

	/*
	 * Run through the blocks inside this one until we find the
	 * basic block that contains the data being fixed up.
	 */
	for (j = 0; j < blockCount; j++) {
	    int	nestedReps = Pass1MSCountBlocks(iPtr, offset, data);

	    if (*iPtr > offset) {
		return (nestedReps * repCount);
	    }
	}
	assert(0);
	return(0);
    }
}


/***********************************************************************
 *				Pass1MS_CountRels
 ***********************************************************************
 * SYNOPSIS:	    Count run-time relocations for the segment to which
 *	    	    the passed fixups apply.
 * CALLED BY:	    Pass1MS_Load
 * RETURN:	    the number of run-time relocations that may be needed
 * SIDE EFFECTS:    msThreads may be altered.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 4/91		Initial Revision
 *
 ***********************************************************************/
unsigned
Pass1MS_CountRels(const char   	*file,	    /* Object file being read */
		  byte	    	rectype,    /* Type of object record for which
					     * relocations are being counted */
		  SegDesc    	*sd,	    /* Segment for which fixups are.
					     * If NULL, fixups are just
					     * defining relocation threads,
					     * not actually fixing up data */
		  word	    	startOff,   /* Base offset of data buffer in
					     * the segment */
		  word	    	reclen,	    /* Total length of the record */
		  byte	    	*data)	    /* Start of the enumerated data */
{
    word    	fixlen;
    byte    	*endRecord;
    byte    	*bp;
    unsigned	total = 0;
    word    	*callArray;
    byte    	hadCall = FALSE;
    word    	size;

    if (rectype != MO_FIXUPP) {
	bp = msobjBuf + reclen + 1;
	MSObj_GetWord(fixlen, bp);
	fixlen -= 1;
    } else {
	bp = data;
	fixlen = reclen;
    }

    /* this callArray allows us to deal with object records that break up
     * calls and possibly come in out of order. there are essentially two
     * types of entries in this array (although they all look the same). one
     * entry signifies that we actually have a 0x9a coming as the last byte
     * in an object record. this will be used when processing the record for
     * the code following the 0x9a. the other entry is for when we process an
     * object record out of order, and we need to know if the preceeding
     * object record had a 0x9a as its last byte, but since we haven't read it
     * yet, we enter the offset we were looking at, and when we do process
     * that record, it will see that we were looking for a 0x9a as the last
     * byte, so it will check its last byte and act accordingly
     * jimmy 5/95
     */

    if (sd != NULL) {
	if (!sd->callArray)
	{
	    sd->callArray = (word *)malloc(CALL_ARRAY_STEP * sizeof(word));
	    memset(sd->callArray, 0, CALL_ARRAY_STEP * sizeof(word));
	}
	callArray = sd->callArray;
	while (*callArray)
	{
	    if (*callArray == startOff - 1) {
		/* we had a 0x9a in the previous record, so note that for
		 * later
		 */
		hadCall = TRUE;
	    }
	    if (*callArray == startOff + reclen - 4) {
		/* ok, we were looking for the 0x9a, so we need to dec the
		 * nrel count if indeed there is a 0x9a there
		 */
		if (data[reclen-4] == 0x9a)
		{
		    sd->nrel -= 1;
		}
	    }
	    callArray++;
	}
    } else {
	callArray = NULL;
    }

#if TEST_NRELS
    /*XXX*/
    printf("P1 %i:%04x (%s)\n", sd->name, startOff, file);
#endif

    endRecord = bp + fixlen;

    while (bp < endRecord) {
	if (*bp & FLH_IS_FIXUP) {
	    byte    	fixdata;
	    MSFixData	target;
	    MSFixData	frame;
	    word    	fixLoc;
	    word    	fixOffset;
	    int	    	nrel = 0;

	    if (sd == NULL) {
		/*
		 * Fixup record is not associated with any data record, so
		 * it *may not* hold any fixups, only thread definitions.
		 */
		Notify(NOTIFY_ERROR,
		       "%s: non-data FIXUPP record may only contain THREAD definitions",
		       file);
		return(0);
	    }

	    if (!MSObj_DecodeFixup(file, sd, &bp, &fixLoc, &fixdata, &target,
				   &frame))
	    {
		return(0);
	    }

	    fixOffset = (fixLoc & FL_OFFSET);
	    /* if the target is an external record, then see if its a
	     * special borland record that will require the borlandc library
	     * to be linked in, if it is then link the puppy in, this must be
	     * done in pass 1, while the actual fixups for these special
	     * records must be done in pass 2
	     */
	    if ((target.external != NullID) &&
	        ((fixdata & FD_TARGET) == TFM_EXTERNAL))
	    {
		if (MSObj_IsFloatingPointExtDef(target.external) != FPED_FALSE)
		{
			printf("borlandc\r\n");
		    //Library_Link("borlandc", LLT_ON_STARTUP, GA_LIBRARY);
		}
	    }
	    /*
	     * Skip the target displacement too.
	     */
	    if (!(fixdata & FD_NO_TARG_DISP)) {
		bp += 2;
	    }

	    switch (((fixLoc >> 8) & FLH_LOC_TYPE) >> FLH_LOC_TYPE_SHIFT){
		case FLT_LOW_BYTE:
		    /*
		     * Can't take low byte of a library entry, so no run-time.
		     */
		    break;
		case FLT_FAR_PTR:
		    /*
		     * If the relocation is in the data portion of a lmem
		     * resource then this will be handled by an object
		     * relocation and no runtime relocation is needed.
		     * 11/15/92: Always assume the thing is a non-object lmem
		     * segment, as it makes our life easier to assume this
		     * and reduce the number of runtime relocations to 0
		     * at the end of the file, when we can be sure we've seen
		     * the header for the thing and know whether the block
		     * is an object block, rather than just hoping the
		     * header data will have come by already (which will likely
		     * never happen, given what GOC puts out) -- ardeb.
		     */
		    /*
		     * At least one run-time relocation for the segment part.
		     */
		    nrel += 1;
		    /*
		     * If the output format supports CALL relocations, See if
		     * the thing's a far call. If so, only one relocation needed
		     */
		    if (!(fileOps->flags & FILE_NOCALL))
		    {
			if ((fixOffset && (data[fixOffset - 1] == 0x9a)) ||
			(!fixOffset && hadCall))
			{
                            break;
			}


			/* log that we were looking at this offset for
			 * a 0x9a, there are two possible reasons why this
			 * would be the case, either we read in the
			 * object record for the preceeding byte and it wansn't
			 * a 0x9a, in which case this value will never be
			 * used, which is fine as its not needed, or we just
			 * haven't read in the record yet, in which case when
			 * we do read in the right record, it will see that
			 * we were looking for a 0x9a and the right thing
			 * depending on whether there is a 0x9a there or
			 * not! - jimmy 5/95
			 */
			if (!fixOffset)
			{
			    *callArray++ = startOff - 1;
			    size = callArray - sd->callArray;
			    /* See if we're into a new block of entries that
			     * we've not allocated yet. */
			    if ((size & CALL_ARRAY_MASK) == 0)
			    {
				sd->callArray =
				    (word *)realloc((malloc_t)sd->callArray,
						    ((size+CALL_ARRAY_STEP) *
						     sizeof(word)));
				callArray = sd->callArray + size;
				/*
				 * Initialize new entries to 0 so while() knows
				 * when to stop: there's always a 0 entry as a
				 * sentinel.
				 */
				memset(callArray, 0,
				       CALL_ARRAY_STEP * sizeof(word));
			    }
			}
			/*
			 * Byte before the far pointer is a far call opcode,
			 * so assume it's a far call. If the target of the
			 * relocation isn't actually a code symbol, we'll
			 * just have to reduce the number of runtime relocations
			 * during pass 2...
			 */
		    }

                    /*FALLTHRU*/
                case FLT_LDRRES_OFF:
                    /*
                     * According to the docs I have seen, this is treated
                     * the same as FLT_OFFSET by the linker. -- mgroeber 7/19/00
                     */
                case FLT_OFFSET:
		    /*
		     * If the target's in a library, we'll need a run-time
		     * relocation for it.
		     */
		    if ((fixdata & FD_TARGET) == TFM_SEGMENT) {
			if (target.segment->combine == SEG_LIBRARY) {
			    /*
			     * In a library segment => in a library
			     */
			    nrel += 1;
			}
		    } else if ((fixdata & FD_TARGET) == TFM_EXTERNAL) {
			if (target.external & MO_EXT_IN_LIB) {
			    /*
			     * External data is non-zero, so it's in a library.
			     */
			    nrel += 1;
			}
		    }
		    break;
		case FLT_SEGMENT:
		    /*
		     * Definitely generates a run-time
		     * relocation.
		     */
		    nrel += 1;
		    break;
		default:
		case FLT_HIGH_BYTE:
		    Notify(NOTIFY_ERROR,
			   "%s: unsupported fixup type FLT_HIGH_BYTE",
			   file);
		    break;
	    }
	    if (nrel && (rectype == MO_LIDATA)) {
		/*
		 * Ick. We need to figure how many times this damn thing will
		 * be repeated.
		 */
		word i;

		i = 0;
		nrel *= Pass1MSCountBlocks(&i, fixLoc & FL_OFFSET, data);
	    }
#if TEST_NRELS
	    /*XXX*/
	    printf ("%04x %d 0\n", fixLoc & FL_OFFSET, nrel);
#endif
	    total += nrel;
	} else {
	    /*
	     * Defining a thread.
	     */
	    byte    fixdata = *bp++;
	    int	    thread = fixdata & TD_THREAD_NUM;

	    /*
	     * Merge the fixup method into the proper field of the .fixup
	     * field for the thread, then decode the following index into
	     * a MSFixData and mark the thread valid.
	     */
	    if (fixdata & TD_IS_FRAME) {
		msThreads[thread].fixup &= ~FD_FRAME;
		msThreads[thread].fixup |=
		    (fixdata & TD_METHOD) << (FD_FRAME_SHIFT - TD_METHOD_SHIFT);
		MSObj_DecodeFrameOrTarget((fixdata&TD_METHOD)>>TD_METHOD_SHIFT,
					  &bp,
					  &msThreads[thread].data[MST_FRAME]);
		msThreads[thread].valid |= 1 << MST_FRAME;
	    } else {
		msThreads[thread].fixup &= ~(TD_METHOD>>TD_METHOD_SHIFT);
		msThreads[thread].fixup |=
		    (fixdata & TD_METHOD) >> TD_METHOD_SHIFT;
		MSObj_DecodeFrameOrTarget((fixdata&TD_METHOD)>>TD_METHOD_SHIFT,
					  &bp,
					  &msThreads[thread].data[MST_TARGET]);
		msThreads[thread].valid |= 1 << MST_TARGET;
	    }
	}
    }


    /* if the last actual byte of data in the object record is a 0x9a then
     * add it to the array of such beasts so that future calls to
     * this routine can determine the correct number of relocations
     * needed for its fixups
     */
    if (sd != NULL && data[reclen-4] == 0x9a)
    {
	*callArray++ = startOff + reclen - 4;
	size = callArray - sd->callArray;
	if ((size & CALL_ARRAY_MASK) == 0)
	{
	    sd->callArray =
		(word *)realloc((malloc_t)sd->callArray,
				((size+CALL_ARRAY_STEP)*sizeof(word)));
	    callArray = sd->callArray + size;
	    /*
	     * Initialize new entries to 0 so while() knows when to stop:
	     * there's always a 0 entry as a sentinel.
	     */
	    memset(callArray, 0, CALL_ARRAY_STEP * sizeof(word));
	}
    }
    return (total);
}


/***********************************************************************
 *				Pass1MSProcessComdef
 ***********************************************************************
 * SYNOPSIS:	    Enter the typeless communal variables into the
 *	    	    proper segments as undefined externals.
 * CALLED BY:	    Pass1MS_Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/18/91		Initial Revision
 *
 ***********************************************************************/
static void
Pass1MSProcessComdef(word   reclen) /* Number of data bytes in the whole
				     * record */
{
}


/***********************************************************************
 *				Pass1MS_Load
 ***********************************************************************
 * SYNOPSIS:	    Load object code from a Microsoft Object File
 * CALLED BY:	    Pass1Load
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
Pass1MS_Load(const char	*file,	    /* File name (for error messages) */
	     genptr 	handle)    /* Stream open to the file */
{
    FILE    	    *f = (FILE *)handle;

    Pass1MS_ProcessObject(file, f);

    fclose(f);
}

/***********************************************************************
 *				Pass1MSLMemSegCompareSwap
 ***********************************************************************
 * SYNOPSIS:	    Compare segment ordering for two lmem segments and
 *	    	    swap if needed
 * CALLED BY:	    Pass1MS_Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Possibly swaps entries
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	6/1/91		Initial Revision
 *
 ***********************************************************************/
static void
Pass1MSLMemSegCompareSwap(SegDesc **seg1, SegDesc **seg2)
{
    SegDesc *temp;

    if (MSObj_GetLMemSegOrder(*seg1) > MSObj_GetLMemSegOrder(*seg2)) {
	temp = *seg1;
	*seg1 = *seg2;
	*seg2 = temp;
    }
}


/***********************************************************************
 *				Pass1MS_EnterExternal
 ***********************************************************************
 * SYNOPSIS:	    Enter the name of an external symbol in the
 *		    externals vector, dealing with seeing if it's in
 *		    a library, etc.
 * CALLED BY:	    (EXTERNAL) Pass1MS_ProcessObject, BorlandProcessExternal
 * RETURN:	    nothing
 * SIDE EFFECTS:    another element is appended to the externals vector
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/15/92		Initial Revision
 *
 ***********************************************************************/
void
Pass1MS_EnterExternal(ID    name)   	/* Name of external to enter */
{
    const char	    *nameStr;	/* Locked form of name, for checking for
				 * underscore */
    ID	    	    name2;  	/* Name without leading underscore */
    ID	    	    pubName;  	/* Name without leading underscore */
    VMBlockHandle   symBlock;   /* Junk */
    word	    symOff;    	/* Junk, the sequel */
    int 	    i;  	/* Index into seg_Segments */

    pubName = Library_TackPrependPublishedToID(symbols, strings, name);

    /*
     * If the name begins with an underscore, look for it without its underscore
     * as well, to cope with _GenViewClass and the like.
     */
    nameStr = ST_Lock(symbols, name);
    if (nameStr[0] == '_') {
	name2 = ST_LookupNoLen(symbols, strings, nameStr+1);
    } else {
	name2 = NullID;
    }
    ST_Unlock(symbols, name);

    /*
     * Look through all library segments for the symbol.
     */

    for (i = 0; i < seg_NumSegs; i++) {
	SegDesc	    *sd = seg_Segments[i];

	if ((sd->combine == SEG_LIBRARY) &&
	    (Sym_Find(symbols, sd->syms, name, &symBlock, &symOff, TRUE) ||
	     ((name2 != NullID) &&
	      Sym_Find(symbols, sd->syms, name2, &symBlock, &symOff, TRUE))))
	{
	    ObjSym  	    *os;    	/* External symbol */

	    os = (ObjSym *)((genptr)VMLock(symbols, symBlock, (MemHandle *)NULL) + symOff);
	    if (Library_UseEntry(sd, os, FALSE, FALSE)) {
		/*
		 * If it's allright to use this entry point, then there's
		 * no need to use the published version
		 */
		pubName = NullID;
	    }
	    VMUnlock(sym, symBlock);

	    /*
	     * Found in a library segment, so mark the name
	     * and get out of this damn loop.
	     */
	    name |= MO_EXT_IN_LIB;
	    break;
	}
    }

    Vector_Add(externals, VECTOR_END, &name);


    /*
     * If the thing was published, check to see if we'll end up using
     * the published version, and if so, mark that segment a SEG_RESOURCE
     * instead of the SEG_LIBRARY that it is.
     */

    if(pubName != NullID) {
	for (i = 0; i < seg_NumSegs; i++) {

	    SegDesc    *sd = seg_Segments[i];

	    if (sd->name == pubName) {
		/*
		 * Mark the segment as a SEG_RESOURCE so that it'll appear
		 * in the final product.
		 */
		sd->combine = SEG_RESOURCE;
		break;
	    }
	}
    }
}


/***********************************************************************
 *				Pass1MS_ProcessObject
 ***********************************************************************
 * SYNOPSIS:	    Process object records from the passed file until
 *	    	    the end of the module is seen.
 * CALLED BY:	    Pass1MS_Load, Pass1MSL_Load
 * RETURN:	    nothing
 * SIDE EFFECTS:    Lots
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/10/91		Initial Revision
 *
 ***********************************************************************/
void
Pass1MS_ProcessObject(const char  *file,
		      FILE  *f)
{
    word	    reclen;
    byte    	    rectype;
    int	    	    done = FALSE;
	int	recno = 0;

    MSObj_Init(f);
    CV_Init(file, f);
		CV32_Init(file, f);

    msobjCheck = MSObj_DefCheck;
    msobjFinish = Pass1MS_Finish;


    while(!done) {
	byte	*bp;

	rectype = MSObj_ReadRecord(f, &reclen, &recno);

	bp = msobjBuf;

	if ((*msobjCheck) (file, rectype, reclen, msobjBuf, 1)) {
	    continue;
	}

        switch(rectype) {
	    case MO_THEADR: {
		/*
		 * Extract the source file name out and enter it into the
		 * string table, recording the ID for LINNUM record translation.
		 * for WATCOM, only apply if there is actually a name.
		 */
		 if(*bp) {
		    msobj_CurFileName = ST_Enter(symbols, strings, (char *)bp+1,
						*bp);
		if(msobj_FirstFileName ==  NullID) {
		
		    msobj_FirstFileName = msobj_CurFileName;
		}
	}
		break;
	    }
	    case MO_COMENT:
		/*
		 * Handle Turbo C type records here...
		 */
		if(
		 (reclen > 3) &&
		 (bp[1] == 0x9f) &&	/* class 0 */
		 (bp[2] == '@'))
  		{
		    ID newName;


		    /*
		     * Entertaining comment record placed in the output file by
		     * GOC to tell us the actual source file name under metaware.
		     */
		    newName = ST_Enter(symbols, strings, (char *)&bp[3],
						   reclen-3);
		    /*
		     *
	   	     */
		    if((msobj_FirstFileName != NullID) && (newName != msobj_FirstFileName)) {

			Pass1MSReplaceFileName(msobj_FirstFileName, newName);
		    }
		}		
		break;
	    case MO_MODEND:
		/*
		 * Ignore module type and entry point fixup.
		 */
		done = TRUE;
		break;
            case MO_LEXTDEF:
	    case MO_EXTDEF:
	    {
		/*
		 * For each symbol mentioned in here, see if the damn thing
		 * exists, and in what segment. If the segment is a library
		 * segment, we or MO_EXT_IN_LIB into the external's name to
		 * signal that the symbol's in a library.
		 */
		ID  	    	name;	/* name of current external */
		byte	    	*endRecord = bp+reclen;
		ObjSym	    	os; 	/* Symbol record for Sym_EnterUndef */

		os.type = OSYM_UNKNOWN;
		os.flags = OSYM_UNDEF;

		while (bp < endRecord) {
		    /*
		     * Must use ST_Enter instead of ST_Lookup to deal with
		     * Microsoft C 6.0's annoying tendency to create both
		     * PUBDEF and EXTDEF records for symbols for which it
		     * outputs CodeView information so it can use FFM_EXTERNAL
		     * fixups to specify the offsets in $$SYMBOLS. We need to
		     * be able to find the proper symbol in codeview.c to
		     * figure in what segment to define the symbol, which
		     * means we *must* have an ID recorded for each symbol.
		     */
		    name = ST_Enter(symbols, strings, (char *)bp+1, *bp);
		    os.name = name;

		    /*
		     * Enter the symbol as undefined in the global segment,
		     * to indicate we've no clue where it actually lives,
		     * of unknown type (since EXTDEF contains no real type
		     * information (grrr))
		     */
		    Sym_EnterUndef(symbols, globalSeg->syms,
				   name,
				   &os,
				   0,
				   symbols, /* junk 1 */
				   strings);/* junk 2 */

		    Pass1MS_EnterExternal(name);
		    /*
		     * Skip over name-length byte, name, and meaningless
		     * type index (1 byte only ?!)
		     */
		    bp += 1 + *bp + 1;
		}
		break;
	    }
	    case MO_TYPDEF:
		/*
		 * Do something with these beasties for the non-CV case...
		 */
		break;
                /*
                 * Handle "hidden" publics for static symbols the same way
                 * regular ones...
                 */
	    case MO_LPUBDEF1:
	    case MO_LPUBDEF2:
            case MO_PUBDEF:
	    {
		SegDesc	    	*sd;
		GroupDesc   	*gd;
		byte	    	symType;
		VMBlockHandle	symBlock;
		VMBlockHandle	typeBlock;
		int 	    	i;
		byte	    	*tbp;
		byte	    	*endRecord;
		ObjSymHeader	*osh;
		ObjSym	    	*os;
		ObjSym	    	template;
		VMBlockHandle	*head, *tail;


		/*
		 * Figure where this record ends.
		 */
		endRecord = bp + reclen - 1;

		/*
		 * Fetch out the group and segment definitions.
		 */
		gd = MSObj_GetGroup(&bp);
		sd = MSObj_GetSegment(&bp);

		/*
		 * All symbols we enter here are global.
		 */
		template.flags = OSYM_GLOBAL;

		if (sd == NULL) {
		    /*
		     * Segment is absolute. Perhaps these things are constants?
		     */
		    word    	frame;

		    MSObj_GetWord(frame, bp);

		    if (frame == 0) {
			template.type = symType = OSYM_CONST;
			sd = globalSeg;
			head = &sd->symH; tail = &sd->symT;
		    } else {
			template.type = symType = OSYM_LABEL;
			template.u.label.near = FALSE;

			/* Look for an absolute segment of the same frame,
			 * create one if none existent yet */
			assert(0);
		    }
		} else if (sd->class != NullID) {
		    /*
		     * The segment has a specified class. Use that class to
		     * determine the type of symbols we're creating. A
		     * CODE segment holds procedures. Anything else holds
		     * variables.
		     */
		    char    *class;

		    head = &sd->addrH; tail = &sd->addrT;

		    class = ST_Lock(symbols, sd->class);
		    if (ustrncmp(class, "CODE", 4) == 0) {
			template.type = symType = OSYM_PROC;
			template.u.proc.local = 0; /* No locals */
			template.u.proc.flags = 0; /* Far procedure */
		    } else {
			template.type = symType = OSYM_VAR;
			template.u.variable.type = /* byte variable */
			    OTYPE_INT | OTYPE_SPECIAL | (1 << 1);
		    }
		    ST_Unlock(symbols, sd->class);
		} else {
		    /*
		     * No class => byte variables
		     */
		    head = &sd->addrH; tail = &sd->addrT;

		    template.type = symType = OSYM_VAR;
		    template.u.variable.type = /* byte variable */
			OTYPE_INT | OTYPE_SPECIAL | (1 << 1);
		}

		/*
		 * Count the number of symbols defined in this record so we
		 * can resize the block once and not have to deal with
		 * dereferencing the block handle after each allocation.
		 */
		for (i = 0, tbp = bp; tbp < endRecord; i++) {
		    tbp += *tbp + 1 + 2;
		    MSObj_GetIndex(tbp);
		}

		/*
		 * Now allocate or commandeer a symbol and type block for our
		 * purposes.
		 */
		if (*tail) {
		    MemHandle	mem;
		    word    	newSize;

		    osh = (ObjSymHeader *)VMLock(symbols, *tail, &mem);

		    /*
		     * Always use this type block.
		     */
		    typeBlock = osh->types;

		    /*
		     * Figure how big the block'd be with these new symbols.
		     */
		    newSize = (osh->num + i) * sizeof(ObjSym) +
			sizeof(ObjSymHeader);

		    if ((newSize < OBJ_MAX_SYMS) ||
			(osh->seg == MS_SYMS_NOT_ENTERED))
		    {
			/*
			 * We won't overflow, or we must use this block because
			 * there are other symbols we've not yet entered in
			 * this block.
			 */
			symBlock = *tail;
			/*
			 * Make it big enough, and deref the block handle so
			 * we've got the base again.
			 */
			MemReAlloc(mem, newSize, 0);
			MemInfo(mem, (genptr *)&osh, (word *)NULL);

			/*
			 * If we've not stuck any symbols of our own, the
			 * first symbol must be before the start of the segment
			 * for this object file... if it ain't our qsort in
			 * Pass1MS_Finish ain't gonna help...
			 */
			assert((osh->num == 0) ||
			       (osh->seg == MS_SYMS_NOT_ENTERED) ||
			       (ObjFirstEntry(osh, ObjSym)->u.addrSym.address <=
				sd->nextOff));
		    } else {
			/*
			 * Block would become too big -- allocate a new one
			 * and link it to the old tail, making the new the
			 * new tail.
			 */
			symBlock = VMAlloc(symbols,
					   (sizeof(ObjSymHeader) +
					    i * sizeof(ObjSym)),
					   OID_SYM_BLOCK);
			osh->next = symBlock;
			VMUnlockDirty(symbols, *tail);
			*tail = symBlock;
			osh = (ObjSymHeader *)VMLock(symbols, symBlock, (MemHandle *)NULL);
		    }
		} else {
		    /*
		     * No previous tail. Allocate a new symbol and a minimal
		     * type block and make the symbol block the whole chain.
		     */
		    ObjTypeHeader   *oth;

		    *head = *tail =
			symBlock = VMAlloc(symbols,
					   (sizeof(ObjSymHeader) +
					    i * sizeof(ObjSym)),
					   OID_SYM_BLOCK);
		    osh = (ObjSymHeader *)VMLock(symbols, symBlock, (MemHandle *)NULL);
		    osh->next = 0;
		    osh->seg = 0;
		    osh->num = 0;
		    /*
		     * Allocate a tiny type block, as we don't store any types.
		     */
		    osh->types = VMAlloc(symbols, sizeof(ObjTypeHeader),
					 OID_TYPE_BLOCK);
		    oth = (ObjTypeHeader *)VMLock(symbols, osh->types, (MemHandle *)NULL);
		    oth->num = 0;
		    VMUnlockDirty(symbols, osh->types);
		}

		/*
		 * Start storing with the first available entry. If we're
		 * storing symbols with addresses (not constants), mark the
		 * block as needing attention by Pass1MS_Finish...
		 */
		os = ObjFirstEntry(osh, ObjSym) + osh->num;
		if (symType != OSYM_CONST) {
		    osh->seg = MS_SYMS_NOT_ENTERED;
		}

		/*
		 * Add the number of symbols we'll be putting in *once*
		 */
		osh->num += i;

		while (bp < endRecord) {
		    /*
		     * Enter and store the name in the template.
		     */
		    template.name = ST_Enter(symbols, strings,
					     (char *)bp+1, *bp);
		    /*
		     * Skip over it, of course.
		     */
		    bp += *bp + 1;

		    /*
		     * Fetch the "offset". For a constant, it's the constant's
		     * value; for a non-constant, it's the unrelocated offset
		     * of the symbol.
		     */
		    if (symType == OSYM_CONST) {
			MSObj_GetWord(template.u.constant.value, bp);
		    } else {
			MSObj_GetWord(template.u.addrSym.address, bp);
			/*
			 * Relocate...
			 */
			template.u.addrSym.address += sd->nextOff;
		    }
		    /*
		     * Store the template in its proper location and advance our
		     * pointer.
		     */
		    *os++ = template;
		    MSObj_GetIndex(bp);	/* Ignore type index */

		    /*
		     * Now enter the beggar in the segment's symbol table if
		     * it's a constant.
		     */
		    if (symType == OSYM_CONST) {
			Sym_Enter(symbols, sd->syms, template.name, *tail,
				  (genptr)(os-1) - (genptr)osh);
		    }

		}
		/*
		 * Done, until we've read the whole file.
		 */
		VMUnlockDirty(symbols, *tail);
		break;
	    }
	    case MO_LINNUM:
	    {
		SegDesc	    	*sd;
		GroupDesc   	*gd;

		/*
		 * Fetch the group and segment for which these line numbers are.
		 * We ignore the group, of course, but the segment's nice to
		 * have...
		 */
		gd = MSObj_GetGroup(&bp);
		sd = MSObj_GetSegment(&bp);

		if (sd == (SegDesc *)NULL) {
		    Notify(NOTIFY_ERROR,
			   "%s: undefined segment in line number record",
			   file);
		    break;
		}

		Pass1MSAddLines(sd, bp, reclen-(bp-msobjBuf));
		break;
	    }
	    case MO_LNAMES:
	    {
		int 	namelen;
		ID  	name;

		while (reclen > 0) {
		    /*
		     * Fetch name length and enter the name into the string
		     * table for the .sym file.
		     */
		    namelen = *bp++;

		    if ((*bp == 'D') && (namelen == 6) &&
			strncmp((char *)bp, "DGROUP", 6) == 0)
		    {
			/*
			 * Map DGROUP down to dgroup as normal sane people
			 * prefer to type...
			 */
			name = ST_Enter(symbols, strings, "dgroup", namelen);
		    } else {
			name = ST_Enter(symbols, strings, (char *)bp, namelen);
		    }
		    /*
		     * Add the name to the end of the NAMES vector for later
		     * use.
		     */
		    Vector_Add(names, VECTOR_END, &name);

		    /*
		     * Adjust loop variables for name's length.
		     */
		    bp += namelen;
		    reclen -= namelen + 1;
		}
		break;
	    }
	    case MO_SEGDEF32:
	    {
		int 	type;	    /* Segment combine type */
		int 	align;	    /* Segment alignment */
		ID  	name;	    /* Segment name */
		ID  	class;	    /* Segment class name */
		word	frame;	    /* Absolute frame, if any */
		long	size;	    /* Segment size */

		if (!MSObj_DecodeSegDef(file, rectype, bp,
					&type, &align, &name, &class,
					&frame, &size))
		{
		    goto file_done;
		}

		Notify(NOTIFY_ERROR, "32-bit segment %i not supported", name);
		goto file_done;
	    }
	    case MO_SEGDEF:
	    {
		int 	type;	    /* Segment combine type */
		int 	align;	    /* Segment alignment */
		ID  	name;	    /* Segment name */
		ID  	class;	    /* Segment class name */
		word	frame;	    /* Absolute frame, if any */
		long	size;	    /* Segment size */
		SegDesc	*sd;	    /* Associated segment descriptor */

		if (!MSObj_DecodeSegDef(file, rectype, bp,
					&type, &align, &name, &class,
					&frame, &size))
		{
		    goto file_done;
		}

		sd = Seg_AddSegment(file, name, class, type, align, 0);
		if (sd) {
		    if (sd->callArray) {
			free((malloc_t)sd->callArray);
		    }
		    sd->callArray = (word *)malloc(CALL_ARRAY_STEP * sizeof(word));
		    memset(sd->callArray, 0, CALL_ARRAY_STEP * sizeof(word));

		    /*
		     * Pad the size out to the alignment boundary of the
		     * segment. Must use sd->align to deal with segment
		     * aliases, which might change the alignment.
		     */
		    size = (size + sd->alignment) & ~sd->alignment;

		    if (type == SEG_ABSOLUTE) {
			/*
			 * Segment is absolute, so set the frame.
			 * XXX: error check for already-defined absolute
			 * segment with different frame.
			 */
			sd->pdata.frame = frame;
		    } else if (type != SEG_COMMON) {
			/*
			 * Segment may be concatenated, so do so.
			 */
			sd->size += size;
		    } else if (size > sd->size) {
			/*
			 * Segment is COMMON and gets overlapped between
			 * files. Segment size in this file is bigger than
			 * any previous one, so adjust the segment size
			 * to match.
			 */
			sd->size = size;
		    }

		    /*
		     * Check for LMEM seg (as figured by MSObj_DecodeSegDef).
		     * If so, enter the segment in the correct group.
		     */
		    if (sd->combine == SEG_LMEM) {
			char	    *segName;
			char	    *baseName;
			ID  	    groupID;
			GroupDesc   *gd;
			int 	    order;

			segName = ST_Lock(symbols, sd->name);
			baseName = MSObj_DecodeLMemName(segName, &order);
			if (order == LMEM_HEADER) {
			    /*
			     * The thing is the header, so count a runtime
			     * relocation for the handle that must go at
			     * offset 0. The relocation itself will be
			     * manufactured during pass 2.
			     */
			    sd->nrel += 1;
			    if (sd->nextOff != 0) {
				Notify(NOTIFY_ERROR, "%s: cannot have data in lmem segment %s in more than one object file",
				       file, baseName);
			    }
			} else if (order == LMEM_HANDLES) {
			    Pass1MSAddLMemSegment(sd);
			}
			groupID = ST_EnterNoLen(symbols, strings, baseName);
			gd = Seg_AddGroup(file, groupID);
			Seg_EnterGroupMember(file, gd, sd);


			/*
			 * Ensure correct segment ordering within the group if
			 * we've now seen all the segments.
			 */
			if (gd->numSegs == 3) {
			    Pass1MSLMemSegCompareSwap(&(gd->segs[0]),
						      &(gd->segs[1]));
			    Pass1MSLMemSegCompareSwap(&(gd->segs[0]),
						      &(gd->segs[2]));
			    Pass1MSLMemSegCompareSwap(&(gd->segs[1]),
						      &(gd->segs[2]));
			    gd->segs[LMEM_HEAP]->doObjReloc =
				gd->segs[LMEM_HEADER]->isObjSeg;
			}
			ST_Unlock(symbols, sd->name);
		    }

		    /*
		     * Check for a _CLASSSEG_ segment, and create a group
		     * sans the _CLASSSEG_.
		     */

		    if(sd->name) {
			char	    *segName;
			char	    *baseName;
			ID  	    groupID;
			GroupDesc   *gd;

			segName = ST_Lock(symbols, sd->name);
			if (!(strncmp(segName, "_CLASSSEG_", sizeof("_CLASSSEG_") - 1))) {
			    baseName = segName + sizeof("_CLASSSEG_") - 1;
			    groupID = ST_EnterNoLen(symbols, strings, baseName);
			    gd = Seg_AddGroup(file, groupID);
			    Seg_EnterGroupMember(file, gd, sd);
			}
			ST_Unlock(symbols, name);
		    }

		    /*
		     * Bitch if segment size now too big.
		     */
		    if (sd->size > 65536) {
			Notify(NOTIFY_ERROR,
			       "%s: segment %i greater than 64K (now %d)",
			       file, sd->name, sd->size);
		    }
		}

		/*
		 * Place the descriptor in the segment map for this file.
		 */
		Vector_Add(segments, VECTOR_END, &sd);
		break;
	    }
	    case MO_GRPDEF:
	    {
		ID  	    name;   	/* Name of group being defined */
		char        *segName;   /* Place to store char* of name */
		byte	    *segEnd;	/* End of segment descriptors */
		GroupDesc   *gd;    	/* Descriptor for group being defined */
		SegDesc	    *sd;    	/* Descriptor for group member */
		int 	    i;	    	/* Group member # being entered */

		segEnd = bp + reclen;

		name = MSObj_GetName(&bp);

		gd = Seg_AddGroup(file, name);

		for (i = 0; bp < segEnd; i++) {
		    if (*bp++ != 0xff) {
			Notify(NOTIFY_ERROR,
			       "%s: unknown group member type %02x",
			       file,
			       bp[-1]);
			break;
		    }
		    /*
		     * Look up the segment descriptor for the index.
		     */
		    sd = MSObj_GetSegment(&bp);

		    /*
		     * Enter the beast into the group (unless it is LMEM)
		     */
		    if (sd->combine != SEG_LMEM) {

			/*
			 * Make sure the segment being subsumed isn't a
			 * _CLASSSEG_ being entered into dgroup, since that's
			 * the whole reason we have _CLASSSEG_'s...
			 */
			if(sd->name) {
			    segName = ST_Lock(symbols, sd->name);
			    if (strncmp(segName, "_CLASSSEG_", sizeof("_CLASSSEG_") -1)) {
				Seg_EnterGroupMember(file, gd, sd);
			    }
			    ST_Unlock(symbols, name);
			} else {
			    Seg_EnterGroupMember(file, gd, sd);
			}
		    }
		}

		/*
		 * Place the descriptor in the group map for this file.
		 */
		Vector_Add(groups, VECTOR_END, &gd);
		break;
	    }
	    case MO_FIXUPP:
		/*
		 * Record not associated with any data record, so it must
		 * contain only thread definitions.
		 */
		(void)Pass1MS_CountRels(file, rectype, (SegDesc *)NULL,
					0, reclen, bp);
		break;
	    case MO_LEDATA:
	    case MO_LIDATA:
	    {
		/*
		 * Need to count run-time relocations... debugging symbols
		 * and types are handled in the msobjCheck routine, if needed.
		 */
		SegDesc	    *sd;
		word	    startOff;

		sd = MSObj_GetSegment(&bp);
		MSObj_GetWord(startOff, bp);

		if (msobjBuf[reclen] == MO_FIXUPP) {

		    /*
		     * Record has fixups. We need to figure the number of
		     * run-time relocations that'll be required for this
		     * record. Yech.
		     */
		    sd->nrel += Pass1MS_CountRels(file, rectype, sd, startOff,
						  reclen, bp);
		}

		/*
		 * If the segment is the handles leg of an lmem tripod, record
		 * the data and fixups.
		 */
		if (sd->combine == SEG_LMEM) {
		    switch (MSObj_GetLMemSegOrder(sd)) {
		    case LMEM_HANDLES:
			Pass1MSRecordLMemHandles(sd, rectype, bp,
						 startOff, reclen);
			break;
		    case LMEM_HEADER:
			Pass1MSCheckForObjectBlock(sd, rectype, bp, startOff,
						   reclen);
			break;
		    }
		}
		break;
	    }
	    case MO_COMDEF:
		/*
		 * What to do....what to do. Need to record the damn thing
		 * some place....
		 */
		Pass1MSProcessComdef(reclen);
		break;
	    case MO_BACKPATCH:
	    case MO_BACKPATCH32:
		/*
		 * Only need these in pass 2
		 */
		break;
	    case MO_ERROR:
		Notify(NOTIFY_ERROR, "%s: invalid object record", file);
		goto file_done;
	    default:
		Notify(NOTIFY_ERROR, "%s: unhandled object record type %02x",
		       file, rectype);
		break;
	}
    }

file_done:

    (*msobjFinish)(file, done, 1);
}
