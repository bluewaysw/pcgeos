/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Pass2 for Microsoft object files
 * FILE:	  pass2ms.c
 *
 * AUTHOR:  	  Adam de Boor: Nov 12, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Pass2MS_Load	    Load a microsoft object file during pass 2
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/12/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Pass2 functions for microsoft object files.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: pass2ms.c,v 1.40 96/07/08 17:30:13 tbradley Exp $";
#endif lint

#include    <config.h>
#include    "glue.h"
#include    "msobj.h"
#include    "obj.h"
#include    "output.h"
#include    "sym.h"
#include    "geo.h"
#include    "cv.h"

#include    <objfmt.h>

Vector	    segSizes = NULL;

/*
 * List of saved MO_BACKPATCH records for processing at the end of the
 * object file.
 */
static MSSaveRecLinks	backPatches = {
    (MSSaveRec *)&backPatches, (MSSaveRec *)&backPatches
};


/***********************************************************************
 *				Pass2MSFixupLMem
 ***********************************************************************
 * SYNOPSIS:	    Fix up the heap part of an lmem segment, storing
 *	    	    size words for each chunk and filling necessary
 *	    	    pad bytes with 0xcc
 * CALLED BY:	    Pass2MS_Finish
 * RETURN:	    nothing
 * SIDE EFFECTS:    lots
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
Pass2MSFixupLMem(const char *file,  	/* File being linked */
		 SegDesc    *sd,    	/* Handles segment */
		 long 	    size)   	/* Size of same */
{
    MSObjLMemData   	*lmd, **lmdPtr;
    int	    	    	i;
    word    	    	*newHT;	    	/* Shuffled handle table, as fetched
					 * from the output file */
    byte    	    	*heapData;
    SegDesc 	    	*heap, *lmem;
    word    	    	*oldHandle, *newHandle;
    word    	    	*nextOldHandle, *nextNewHandle;

    GeodeRelocEntry 	*relocs;
    word    	    	prevOff;
    word    	    	prevOldOff;
    byte    	    	b[2];	    	/* Buffer for putting out resource
					 * size */
    LMemType	    	lmemType;
    ObjAddrMapHeader	*oamh;
    ObjAddrMapEntry 	*oame;
    word    	    	mapEntries;
    VMBlockHandle   	cur, next;
    word    	    	lastOff;

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

    /*
     * We have the handle table as it was before we shuffled things around,
     * while the output file has the same info, except shifted up by
     * heap->grpOff.
     * Now we need to read in the heap segment from the output file and
     * actually perform all the shuffling of the heap data, symbols, address
     * map, chunk handles, and of any runtime relocations. We, unfortunately,
     * must break the abstraction provided by fileOps->mapRel to do this,
     * but....
     */

    heap = sd->group->segs[LMEM_HEAP];

    heapData = (byte *)malloc(heap->size);
    Out_Fetch(heap->foff, heapData, heap->size);

    newHT = (word *)malloc(sd->size);
    Out_Fetch(sd->foff, newHT, sd->size);

    lmem = Seg_FindPromotedGroup(sd);
    if (lmem->nrel) {
	relocs = (GeodeRelocEntry *)malloc(lmem->nrel *
					   sizeof(GeodeRelocEntry));
	Out_Fetch(lmem->foff + ((lmem->size + 15) & ~15), relocs,
		  lmem->nrel * sizeof(GeodeRelocEntry));
    } else {
	relocs = 0;		/* Be quiet, GCC (relocs is never used except
				 * where lmem->nrel [which doesn't change] is
				 * checked) */
    }

    /*
     * All the pieces are primed. We now want to loop from the end of the
     * handle table performing the following services for each chunk:
     *  1) figure its unrounded size
     *	2) move it to its final resting place (*newHandle + 2)
     *	3) fill in its size word
     *	4) fill in its padding
     *	5) locate any runtime relocations for it and adjust them
     */
    prevOff = (lmem->size - heap->grpOff) + LMEM_SIZE_SIZE;
    prevOldOff = lmd->heapSize + LMEM_SIZE_SIZE;

    i = sd->size / 2;
    oldHandle = &lmd->handleData[i-1];
    newHandle = &newHT[i-1];

    while (i > 0) {
	if ((*newHandle != 0) && (*newHandle != 0xffff)) {
	    word    	    size;
	    word    	    rndSize;
	    byte    	    *src,
			    *dest;
	    int	    	    j;
	    GeodeRelocEntry *rel;
	    word	    finalVarType;
	    word    	    finalVarOff;
	    VMBlockHandle   finalVarTypesBlock = 0;
	    Boolean 	    foundFinalType = FALSE;

	    finalVarType = 0; finalVarOff = 0; /* Be quiet, GCC (these are
						* used only when
						* finalVarTypesBlock is found
						* to be non-zero) */
	    /*
	     * To cope with the word alignment of some compilers, we need to
	     * find the last variable within the current chunk and add its
	     * size to its offset from the base of the chunk to obtain the
	     * size of the chunk. We need to be much more precise here than
	     * in pass 1, as we're actually setting the size word now.
	     */
	    for (cur = heap->addrH; cur != 0 && !foundFinalType; cur = next) {
		ObjSymHeader	*osh;
		ObjSym	    	*os;
		word	    	n;

		osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);
		os = ObjFirstEntry(osh, ObjSym);
		if (!Obj_IsAddrSym(os)) {
		    /*
		     * Into the chain of type symbols for the segment, so
		     * the last variable seen must be the last one in the
		     * chunk...
		     */
		    VMUnlock(symbols, cur);
		    break;
		}

		for (n = osh->num; n > 0; n--, os++) {
		    if (Obj_IsAddrSym(os)) {
			if ((os->u.addrSym.address - heap->grpOff <
			     prevOldOff - LMEM_SIZE_SIZE) &&
			    (os->u.addrSym.address - heap->grpOff >=
			     swaps(*oldHandle) - LMEM_SIZE_SIZE))

			{
			    /*
			     * If this block is inside the current chunk:
			     * Record the type and offset of this variable,
			     * in case it's the last one in the chunk.
			     */
			    assert(os->type == OSYM_VAR);
			    if (os->u.addrSym.address > finalVarOff)
			    {
				finalVarType = os->u.variable.type;
				finalVarOff = os->u.addrSym.address;
				finalVarTypesBlock = osh->types;
			    }
			}
		    }
		}
		next = osh->next;
		VMUnlock(symbols, cur);
	    }

	    assert(finalVarTypesBlock != 0);

	    /*
	     * Compute the size of the chunk, as indicated above, from the size
	     * of the last variable in the chunk plus that variable's offset
	     * from the start of the chunk. Recall that the symbols haven't
	     * been adjusted for the size word, so we need to back the start up
	     * to compensate.
	     */

	    size = Obj_TypeSize(finalVarType,
				VMLock(symbols, finalVarTypesBlock,
				       (MemHandle *)NULL),
				FALSE);
	    VMUnlock(symbols, finalVarTypesBlock);
	    size += ((finalVarOff - heap->grpOff) -
		     (swaps(*oldHandle) - LMEM_SIZE_SIZE));

	    /*
	     * Figure the rounded size of the chunk to determine where we should
	     * put the thing (that many bytes before the previous (aka
	     * following) chunk.
	     */
	    rndSize = ((size + 2) + 3) & ~3;

	    src = heapData + (swaps(*oldHandle)-LMEM_SIZE_SIZE);
	    dest = heapData + (prevOff - rndSize);

	    /*
	     * Copy the data up first, so we can set the size word without fear
	     * of tromping on the data.
	     */
	    bcopy(src, dest, size);

	    /*
	     * Now set the size word = the size of the chunk + the size of the
	     * size word.
	     */
	    size += 2;

	    dest[-2] = (size) & 0xff;
	    dest[-1] = (size) >> 8;

	    /*
	     * If the size (with size word included) isn't a multiple of 4,
	     * fill the bytes that remain until the next dword with 0xcc, as
	     * required by EC code in the kernel.
	     */
	    if (size & 0x3) {
		memset(dest+(size-2), 0xcc, 4 - (size & 0x3));
	    }

	    /*
	     * Now look for any relocations that fall within the old chunk
	     * and shift them up. Because we're moving down through the table,
	     * which is in ascending order, we never have to worry about a
	     * relocation being adjusted twice. Note, however, that there's
	     * no guarantee that the relocations are in order, since the
	     * compiler is free to put out LEDATA and LIDATA records in whatever
	     * order it wishes, and that's the order in which we'll store
	     * the runtime relocations. This means we have to search the entire
	     * table each time.
	     */
	    for (rel = relocs, j = lmem->nrel; j > 0; rel++, j--) {
		if ((swaps(rel->offset) >= ((swaps(*oldHandle)-LMEM_SIZE_SIZE) +
					    heap->grpOff)) &&
		    (swaps(rel->offset) < ((prevOldOff-LMEM_SIZE_SIZE) +
					   heap->grpOff)))
		{
		    word    newoff = swaps(rel->offset) + (prevOff - rndSize) -
			(swaps(*oldHandle) - LMEM_SIZE_SIZE);

		    rel->offset = swaps(newoff);
		}
	    }
	    prevOldOff = swaps(*oldHandle);
	    prevOff -= rndSize;

	    /*
	     * Point handle to new location.
	     */
	    *newHandle = swaps(prevOff + heap->grpOff);
	}

	newHandle--, oldHandle--, i--;
    }

    /*
     * We've encountered problems with Borland C, where the size of symbols
     * as stored in the .obj file do not match the size of symbols as
     * calculated by subtracting the difference between the offset of
     * the current symbol and the offset of the next symbol.
     *
     * This leaves us with some unused space between the lmem heap's handle
     * table and the start of the chunk data. To work around this, we will
     * make this space into a free chunk.
     */
    if (prevOff > 2) {
	assert(prevOff >= 6);	/* We need at least 4 bytes for a decent free
				 * chunk */
	Notify(NOTIFY_WARNING, "fixing up unused space in lmem resource %i", lmem->name);

	/*
	 * Set up the free chunk at the start of "heapData" - the first word
	 * is the size of the free chunk (prevOff-2). The second word is a
	 * link to the next free chunk (0).
	 *
	 * The free chunk is initialized to 0xCC, natch
	 */
	memset(heapData, 0xcc, prevOff-2);
	heapData[0] = (prevOff-2);  	/* Setup size word */
	heapData[1] = (prevOff-2) >> 8;
	heapData[2] = heapData[3] = 0;	/* Init next ptr to 0 */
	b[0] = (heap->grpOff+2);    	/* Init LMBH_freeList to point past */
	b[1] = (heap->grpOff+2) >> 8;	/* size word */
	Out_Block(lmem->foff + offsetof(LMemBlockHeader, LMBH_freeList), b, 2);
	/*
	 * Take advantage of the fact that we have the size of the free chunk
	 * already stored at the start of heapData, and just write it out.
	 */
	Out_Block(lmem->foff + offsetof(LMemBlockHeader, LMBH_totalFree), heapData, 2);

    }
    /*
     * Find the address-map entry for the first block of symbols from the
     * heap.
     */
    oamh = (ObjAddrMapHeader *)VMLock(symbols, lmem->addrMap,
				      (MemHandle *)NULL);
    mapEntries = oamh->numEntries;
    oame = ObjFirstEntry(oamh, ObjAddrMapEntry);

    while (mapEntries > 0) {
	if (oame->block == heap->addrH) {
	    break;
	}
	oame++, mapEntries--;
    }

    /*
     * Now deal with chunk arrays and relocating the symbols, in general.
     * First find the first in-use chunk handle.
     */
    i = sd->size/2;
    i--;
    nextOldHandle = &lmd->handleData[i]; 
    nextNewHandle = &newHT[i];


    /*
     * Now find the next in-use chunk handle, so we know the limit of the
     * current one. If there is no next, "i" will be left 0 and we won't try
     * and check to see if the address symbol is within bounds of the current
     * chunk.
     */
    for (oldHandle = nextOldHandle - 1,
	 newHandle = nextNewHandle - 1,
	 i -= 1;

	 i > 0;

	 oldHandle--, newHandle--, i--)
    {
	if ((*oldHandle != 0) && (*newHandle != 0xffff)) {
	    break;
	}
    }

    /*
     * Set the variable that holds the segment offset of the last symbol in the
     * block to the start of the heap, just to be clean.
     */
    lastOff = heap->grpOff;
    /* ========================================================================
     * because WATCOM holds not in addressing order we have to
     * fully loop thought all symbols for every chunk */

    while(i > 0) {
	    
	mapEntries = oamh->numEntries;
	oame = ObjFirstEntry(oamh, ObjAddrMapEntry);
	lastOff = oame->last;
	
	for (cur = heap->addrH; cur != 0; cur = next) { /* block look */
	    ObjSymHeader    *osh;
	    ObjSym  	*os, *first;
	    word	    	n;

	    osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);

	    os = ObjFirstEntry(osh, ObjSym);
	    first = os;
	    if (!Obj_IsAddrSym(os)) {
		/*
		 * Hit the first type block (no need to worry about undefined
		 * symbols, either, as they'd be an error at this point and would
		 * have been caught already...)
		 */
		VMUnlock(symbols, cur);
		break;
	    }

	    for (n = osh->num; n > 0; os++, n--) { /* smybol loop */
		/*
		 * If the thing's an address symbol (XXX: what else could it be?
		 * there are no type or procedure-local symbols here...) relocate
		 * it by the amount the associated chunk shifted.
		 */
		if (Obj_IsAddrSym(os)) {
		    if ((i == 0) ||
		    	((os->u.addrSym.address >=
		    	(swaps(*oldHandle)-LMEM_SIZE_SIZE) + heap->grpOff)
			&&
			(os->u.addrSym.address <
			(swaps(*nextOldHandle)-LMEM_SIZE_SIZE) + heap->grpOff)))
		    {
			int newLastOffset = -1;
			    
			/*
			 * Still within the current chunk, so relocate according
			 * to current chunk's relocation amount. Both *newHandle and
			 * *oldHandle have LMEM_SIZE_SIZE added into them, so we
			 * need to add it into the address explicitly.
			 */
			newLastOffset = (os->u.addrSym.address +=
				       (swaps(*newHandle) -
					(swaps(*oldHandle) + heap->grpOff) +
					LMEM_SIZE_SIZE));
			if(newLastOffset > lastOff) {
			    lastOff = newLastOffset;
			}
		    }
		}
	    } /* symbol loop */
	    /*
	     * Advance to next block, dirtying this one, since we've messed with it
	     */
	    next = osh->next;
	    VMUnlockDirty(symbols, cur);
	    /*
	     * Update the offset for the block in the address map to be that of the
	     * last symbol we relocated.
	     */
	    oame->last = lastOff;
	    oame++, mapEntries--;	
        }    /* block loop */

	/* move to next chunk */
	if (i > 0) {
	    /*
	     * Symbol is outside the bounds of the current chunk, so
	     * advance to the next chunk.
	     */
	    nextOldHandle = oldHandle;
	    nextNewHandle = newHandle;
	
	    for (oldHandle = nextOldHandle - 1,
		 newHandle = nextNewHandle - 1,
		 i -= 1;
	
		 i > 0;
	
		 oldHandle--, newHandle++, i--)
	    {
		if ((*oldHandle != 0) &&
		    (*oldHandle != 0xffff))
		{
		    break;
		}
	    }
        }
    }

    for (cur = heap->addrH; cur != 0; cur = next) { /* block look */
	ObjSymHeader    *osh;
	ObjSym  	*os, *first;
	word	    	n;

	osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);

	os = ObjFirstEntry(osh, ObjSym);
	first = os;
	if (!Obj_IsAddrSym(os)) {
	    /*
	     * Hit the first type block (no need to worry about undefined
	     * symbols, either, as they'd be an error at this point and would
	     * have been caught already...)
	     */
	    VMUnlock(symbols, cur);
	    break;
	}
	for (n = osh->num; n > 0; os++, n--) { /* smybol loop */
	    /*
	     * If the thing's an address symbol (XXX: what else could it be?
	     * there are no type or procedure-local symbols here...) relocate
	     * it by the amount the associated chunk shifted.
	     */
	     
	    /*
	     * If the symbol's a variable, see if it's the body of a chunk array
	     * and fix up the header properly if so.
	     */
	    if (os->type == OSYM_VAR) {
		char	*name = ST_Lock(symbols, os->name);

		/* must check for both the _carray_ and __carray_ because
		 * GOC puts out an _carray_ and some compilers will add
		 * an underscore to that
		 */
		if (strncmp(name, "_carray_", 8) == 0 ||
		    strncmp(name, "__carray_", 9) == 0) {
		    /*
		     * This is the actual array symbol. The preceding symbol
		     * is the thing that contains the chunk array header whose
		     * CAH_count we must fill in
		     */
		    genptr  tbase;  	/* Base of associated type block */
		    word    len;    	/* Length of this portion of the
					     * array descriptor */
		    word    nels = 0;	/* Number of elements in the array
					     * total */
		    ObjType *t;	    	/* Current piece of the array
					     * descriptor */
		    byte    *bp;    	/* Pointer for storing CAH_count */
		    int     preceding;  /* index of preceding symbold
					     * based on addr offset */
		    word    pl;         /* preceding loop */

		    /*
		     * Point to the first descriptor for the array type (this
		     * symbol *must* be of an array type, by definition).
		     */
		    assert(!(os->u.variable.type & OTYPE_SPECIAL));
		    tbase = (genptr)VMLock(symbols, osh->types,
					       (MemHandle *)NULL);
		    t = (ObjType *)(tbase + os->u.variable.type);
		    assert(OTYPE_IS_ARRAY(t->words[0]));

		    /*
		     * Deal with arrays > OTYPE_MAX_ARRAY_LEN by moving down the
		     * chain of ObjType's, summing the lengths from each until
		     * we get to one that has <= OTYPE_MAX_ARRAY_LEN elements.
		     */
		    len = OTYPE_ARRAY_LEN(t->words[0]);
		    while (len == OTYPE_MAX_ARRAY_LEN+1) {
			nels += len;

			t = (ObjType *)(tbase + t->words[1]);
			len = OTYPE_ARRAY_LEN(t->words[0]);
		    }
		    nels += len;

		    VMUnlock(symbols, osh->types);

		    /*
		     * The symbol for the header must be the preceding one.
		     * 4/17/96: changed first assertion to check that os-1
		     * is >= ObjFirstEntry, rather than != ObjFirstEntry, as
		     * it's legal for the header to be the first symbol in
		     * the block, I believe... -- ardeb
		     */

		    /*
		     * WATCOM doesn't garantie offset related order of then
		     * symbols, so we need to lookup the symbols by iterating
		     * the symbols block and pick the var with the closest
		     * offset address before ourself.
		     */
		    preceding = -1;
		    for (pl = 0; pl < osh->num; pl++) {
			if(first[pl].u.addrSym.address < os->u.addrSym.address) {
			    if(preceding <  0) {
				preceding = pl;
			    } else if(first[pl].u.addrSym.address >
				first[preceding].u.addrSym.address) {
				preceding = pl;
			    }
			}
		    }
		    assert(preceding >= 0);
		    assert(first[preceding].type == OSYM_VAR);

		    /*
		     * Point to the CAH_count (first field) of the preceding
		     * variable in the block of heap data we've already got
		     * around and set that word to the number of elements in
		     * the array.
		     */
		    bp = heapData + first[preceding].u.addrSym.address - heap->grpOff;
		    *bp++ = nels;
		    *bp = nels >> 8;
		}
		ST_Unlock(symbols, os->name);
	    }
	}	/* symbol loop */
	
	/*
	 * Advance to next block, dirtying this one, since we've messed with it
	 */
	next = osh->next;
	VMUnlockDirty(symbols, cur);
	/*
	 * Update the offset for the block in the address map to be that of the
	 * last symbol we relocated.
	 */
    }    /* block loop */
    
    
    /* ================================================================*/
    /*
     * Make the final address map entry cover to the end of the segment and
     * unlock the thing, marking it dirty.
     */
    oame[-1].last = lmem->size;
    VMUnlockDirty(symbols, lmem->addrMap);

    /*
     * Write the affected blocks (the heap segment, handle table and the
     * runtime relocations) back to the output file.
     */
    Out_Block(heap->foff, heapData, heap->size);
    Out_Block(sd->foff, newHT, sd->size);
    if (lmem->nrel) {
	Out_Block(lmem->foff + ((lmem->size + 15) & ~15), relocs,
		  lmem->nrel * sizeof(GeodeRelocEntry));
    }

    /*
     * Put out the size of the resource, both to the regular header and, if
     * the block's an object block, to the ObjLMemBlockHeader.
     */
    Out_Fetch(lmem->foff + offsetof(LMemBlockHeader, LMBH_lmemType), b, 2);
    lmemType = (b[0] | (b[1] << 8));

    b[0] = lmem->size;
    b[1] = lmem->size >> 8;
    Out_Block(lmem->foff + offsetof(LMemBlockHeader, LMBH_blockSize), b, 2);

    if (lmemType == LMEM_TYPE_OBJ_BLOCK) {
	b[0] = (lmem->size + 15) >> 4;
	b[1] = (lmem->size + 15) >> 12;
	Out_Block(lmem->foff + offsetof(ObjLMemBlockHeader, OLMBH_resourceSize),
		  b, 2);
    }

    /*
     * Free the blocks o' memory we used in the adjustment.
     */
    free((malloc_t)heapData);
    free((malloc_t)newHT);
    if (lmem->nrel) {
	free((malloc_t)relocs);
    }
    /*
     * We only get called once per segment, so we can safely free the descriptor
     * for this beast now we've done what we need to do.
     */
    free((malloc_t)lmd);
}


/***********************************************************************
 *				Pass2MS_Finish
 ***********************************************************************
 * SYNOPSIS:	    Finish off an object file.
 * CALLED BY:	    Pass2MS_Load through msobjFinish
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
Pass2MS_Finish(const char *file, int happy, int pass)
{
    int	    	i;
    SegDesc 	*sd;
    long    	size;
    MSSaveRec	*backpatch;

    /*
     * Deal with back patches.
     */
    for (backpatch = backPatches.next;
	 backpatch != (MSSaveRec *)&backPatches;
	 backpatch = backpatch->links.next)
    {
	byte	*endRecord = backpatch->data+backpatch->len;
	byte	*bp = backpatch->data;
	byte	loctype;

	/*
	 * Fetch affected segment and type of data to be patched (byte,
	 * word, or dword; we don't handle dword for now, as that's only
	 * for 32-bit segments...)
	 */
	sd = MSObj_GetSegment(&bp);
	loctype = *bp++;

	assert((loctype == BPS_BYTE) || (loctype == BPS_WORD));

	while (bp < endRecord) {
	    byte	d[2];
	    word	val;
	    word	offset;
	    long    	fpos;

	    /*
	     * Fetch offset of data and the value to add to it.
	     */
	    MSObj_GetWord(offset, bp);
	    MSObj_GetWord(val, bp);

	    /*
	     * Offset is relative to the start of the segment data from this
	     * object file.
	     */
	    fpos = sd->nextOff + offset;

	    if (loctype == BPS_BYTE) {
		/*
		 * Fetch the byte to fix, add the value to it, and write it
		 * back.
		 */
		Out_Fetch(fpos, d, 1);
		d[0] += val;
		Out_Block(fpos, d, 1);
	    } else {
		/*
		 * Fetch the word to fix, add the value to it, and write it
		 * back.
		 */
		Out_Fetch(fpos, d, 2);
		val += d[0] | (d[1] << 8);
		d[0] = val;
		d[1] = val >> 8;
		Out_Block(fpos, d, 2);
	    }
	}
    }
    /*
     * Free all saved back-patch records.
     */
    MSObj_FreeSaved(&backPatches);


    /*
     * Update the nextOff field for each segment used by the file.
     */
    for (i = Vector_Length(segments)-1; i >= 0; i--) {
	Vector_Get(segments, i, &sd);
	Vector_Get(segSizes, i, &size);

	if (sd > MS_MIN_SEGMENT) {
	    if (happy && (sd->combine == SEG_LMEM) &&
		(MSObj_GetLMemSegOrder(sd) == LMEM_HANDLES))
	    {
		Pass2MSFixupLMem(file, sd, size);
	    }

	    sd->nextOff += (size + sd->alignment) & ~sd->alignment;
	}
    }
}


/***********************************************************************
 *				Pass2MSProcessRels
 ***********************************************************************
 * SYNOPSIS:	    Process the relocations from a FIXUPP record.
 * CALLED BY:	    Pass2MS_Load
 * RETURN:	    nothing
 * SIDE EFFECTS:    msThreads may be altered
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/28/91		Initial Revision
 *
 ***********************************************************************/
static void
Pass2MSProcessRels(const char 	*file,	    /* Object file being read */
		   byte	    	rectype,    /* Type of record for which
					     * fixups are */
		   SegDesc  	*sd,	    /* Segment to which the data in
					     * the record belong */
		   word	    	baseOff,    /* Base offset of the data in the
					     * record within that segment */
		   word	    	reclen,	    /* Size of the data record,
					     * including the segment, group and
					     * offset fields */
		   byte	    	*data)	    /* Start of the data in the
					     * record */
{
    word    	fixlen;	    /* Number of bytes of fixups */
    byte    	*endRecord; /* End of the fixups */
    byte    	*bp;	    /* Current byte in fixups */
    void    	*rbase,	    /* Base of runtime relocation buffer */
		*nextRel;   /* Next available byte in same */

    /*
     * Figure where the fixups begin and end.
     */
    if (rectype != MO_FIXUPP) {
	bp = msobjBuf + reclen + 1;
	MSObj_GetWord(fixlen, bp);
	fixlen -= 1;
    } else {
	bp = data;
	fixlen = reclen;
    }

    endRecord = bp + fixlen;

    /*
     * Assume all the runtime relocations are in this piece and allocate
     * a block big enough to hold all of them...
     */
    if ((sd != NULL) && (sd->nrel != 0) && (fileOps->rtrelsize != 0)) {
	rbase = nextRel = (void *)malloc(sd->nrel * fileOps->rtrelsize);
    } else {
	rbase = nextRel = NULL;
    }
#if TEST_NRELS
    /*XXX*/
    printf ("P2 %i:%04x (%s)\n", sd->name, baseOff, file);
#endif
    if ((sd != NULL) && (sd->combine == SEG_LMEM) &&
	(sd->group->segs[0] == sd) &&
	(fileOps->rtrelsize != 0) && (baseOff == 0))
    {
	/*
	 * Since this is the header, we need to enter a single runtime
	 * relocation for the handle at the beginning of the segment...
	 */
	data[0] = data[1] = 0xff;/* See pass2vm.c for reason...*/

	if ((*fileOps->maprel) (OREL_HANDLE, (SegDesc *)sd->group,
				nextRel, sd, 0, (word *)data))
	{
	    nextRel = (genptr)nextRel + fileOps->rtrelsize;
	}
    }

    if ((msobjBuf[reclen] == MO_FIXUPP) || (rectype == MO_FIXUPP)) {
	(void)MSObj_PerformRelocations(file, data, bp, endRecord, sd, baseOff,
				       2, (byte **)&nextRel);
    }

    /*
     * If any runtime relocations in our buffer, send them to the output file,
     * advancing the roff field of the segment to account for them.
     */
    if (nextRel != rbase) {
	unsigned    len = (genptr)nextRel - (genptr)rbase;

	assert(((byte *)rbase)[0] != 0);

	Out_Block(sd->roff, rbase, len);
	sd->roff += len;
    }
    if (rbase != NULL) {
	free(rbase);
    }
}


/***********************************************************************
 *				Pass2MS_Load
 ***********************************************************************
 * SYNOPSIS:	    Load object code from a Microsoft Object File
 * CALLED BY:	    Pass2Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Lots.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/18/89	Initial Revision
 *
 ***********************************************************************/
void
Pass2MS_Load(const char	*file,	    /* File name (for error messages) */
	     genptr    	handle)    /* Stream open to the file */
{
    FILE    	    *f = (FILE *)handle;

    Pass2MS_ProcessObject(file, f);

    fclose(f);
}


/***********************************************************************
 *				Pass2MS_ProcessObject
 ***********************************************************************
 * SYNOPSIS:	    Really load object code from a Microsoft Object File
 * CALLED BY:	    Pass2MS_Load, Pass2MSL_Load
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
Pass2MS_ProcessObject(const char *file,
		      FILE  *f)
{
    word	    reclen;
    byte    	    rectype;
    int	    	    done = FALSE;
	int recno = 0;

    MSObj_Init(f);
    CV_Init(file, f);
    CV32_Init(file, f);
    if (segSizes == NULL) {
	segSizes = Vector_Create(sizeof(long), ADJUST_ADD, 10, 10);
    } else {
	Vector_Empty(segSizes);
    }

    msobjCheck = MSObj_DefCheck;
    msobjFinish = Pass2MS_Finish;


    while(!done) {
	byte	*bp;

	rectype = MSObj_ReadRecord(f, &reclen, &recno);

	bp = msobjBuf;

	if ((*msobjCheck) (file, rectype, reclen, msobjBuf, 2)) {
	    continue;
	}


	switch(rectype) {
	    case MO_THEADR:
		/* Ignore -- handled in Pass 1*/
		break;
	    case MO_COMENT:
		/* Ignore -- handled in MSObj_DefCheck */
		break;
	    case MO_MODEND:
		if ((*bp & MT_HAS_START) && !entryGiven) {
		    entryGiven = TRUE;

		    if (fileOps->setEntry != (SetEntryProc *)0) {
			bp -= 1;	/* So bp points to the "location" word
					 * of the fixup (non-existent, but
					 * doing so allows us to use
					 * MSObj_DecodeFixup...) */

#if 0				/* XXX: DEAL WITH THIS */
			if (!Pass2MSRelOff(file, globalSeg, &bp,
					   &frame, &offset))
			{
			    Notify(NOTIFY_ERROR,
				   "%s: error relocating entry point",
				   file);
			} else {
			    (*fileOps->setEntry)(frame, offset);
			}
#endif
		    }
		} else if (*bp & MT_HAS_START) {
		    Notify(NOTIFY_ERROR,
			   "%s: entry point already given",
			   file);
		}
		done = TRUE;
		break;
            case MO_LEXTDEF:
	    case MO_EXTDEF:
	    {
		/*
		 * For each symbol mentioned in here, go find the thing in
		 * some segment or other and store its block & offset in
		 * the externals vector.
		 */
		ID  	    	name;	/* name of current external */
		VMBlockHandle	symBlock;
		word	    	symOff;
		VMPtr	    	sym;
		byte	    	*endRecord;
		int             isGlobal = TRUE;

		/**
		 * If we're LEXTDEF, we search within this file only
		 */
		if (rectype == MO_LEXTDEF) {
			isGlobal = FALSE;
		}
		endRecord = bp+reclen;
		while (bp < endRecord) {
		    name = ST_Lookup(symbols, strings, (char *)bp+1, *bp);
		    if (Sym_FindWithFile(symbols, file, 0, name, &symBlock, &symOff, isGlobal))
		    {
			/*
			 * Got it -- store the block and offset.
			 */
			sym = (symBlock << 16) | symOff;
		    } else if (bp[1] == '_') {
			/*
			 * Try it without the underscore and see if we have
			 * any better luck.
			 */
			ID  newname;

			newname = ST_Lookup(symbols, strings, (char *)bp+2,
					    (*bp) - 1);

			if ((newname == NullID) ||
			    !Sym_FindWithFile(symbols, file, 0, newname, &symBlock, &symOff,
				      isGlobal))
			{
			    /*
			     * Couldn't find it -- store the name with the
			     * UNDEFINED bit set.
			     */
			    sym = name | MO_EXT_UNDEFINED;
			} else {
			    sym = (symBlock << 16) | symOff;
			}
		    } else {
			/*
			 * Couldn't find it -- store the name with the
			 * UNDEFINED bit set.
			 */
			sym = name | MO_EXT_UNDEFINED;
		    }

		    Vector_Add(externals, VECTOR_END, &sym);

		    /*
		     * Skip over name-length byte, name, and meaningless
		     * type index (1 byte only ?!)
		     */
		    bp += 1 + *bp + 1;
		}
		break;
	    }
	    case MO_TYPDEF:
		/* Ignore -- handled in Pass 1*/
		break;
            case MO_CVPUB:
            case MO_PUBDEF:
		/* Ignore -- handled in Pass 1*/
		break;
	    case MO_LINNUM:
		/* Ignore -- handled in Pass 1*/
		break;
	    case MO_LNAMES:
	    {
		/*
		 * Still need this so we can find segments.
		 */
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
			name = ST_Lookup(symbols, strings, "dgroup", namelen);
		    } else {
			name = ST_Lookup(symbols, strings, (char *)bp, namelen);
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

		sd = Seg_Find(file, name, class);

		assert(sd != NULL);

		/*
		 * Save the segment size for adjusting nextOff for the segment
		 * at the end of this file.
		 */
		size = (size + sd->alignment) & ~sd->alignment;
		Vector_Add(segSizes, VECTOR_END, &size);

		/*
		 * Place the descriptor in the segment map for this file.
		 */
		Vector_Add(segments, VECTOR_END, &sd);
		break;
	    }
	    case MO_GRPDEF:
	    {
		ID  	    name;   	/* Name of group being defined */
		GroupDesc   *gd;    	/* Descriptor for group being defined */

		name = MSObj_GetName(&bp);

		gd = Seg_FindGroup(file, name);

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
		Pass2MSProcessRels(file, rectype, (SegDesc *)NULL,
				   0, reclen, bp);
		break;
	    case MO_LEDATA:
	    {
		/*
		 * Process relocations for the thing before shooting it out
		 * to the output file. Debugging symbols and types are
		 * handled in the msobjCheck routine, if needed.
		 */
		SegDesc	    *sd;
		word	    startOff;
		word	    size;

		sd = MSObj_GetSegment(&bp);
		MSObj_GetWord(startOff, bp);

		if ((msobjBuf[reclen] == MO_FIXUPP) ||
		    ((sd->combine == SEG_LMEM) &&
		     (sd->group->segs[0] == sd) &&
		     (fileOps->rtrelsize != 0) &&
		     (startOff == 0)))
		{
		    /*
		     * Record has fixups. Process them.
		     */
		    Pass2MSProcessRels(file, rectype, sd, startOff,
				       reclen, bp);
		}
		/*
		 * Figure the number of bytes in the block and shove the whole
		 * thing out to the output file.
		 */
		size = reclen - (bp - msobjBuf);
		Out_Block(sd->nextOff + startOff, bp, size);

		break;
	    }
	    case MO_LIDATA:
	    {
		/*
		 * Process relocations for the thing before shooting it out
		 * to the output file. Debugging symbols and types are
		 * handled in the msobjCheck routine, if needed.
		 */
		SegDesc	    *sd;
		word	    startOff;
		word	    size;
		byte	    *buf, *bufPtr;

		sd = MSObj_GetSegment(&bp);
		MSObj_GetWord(startOff, bp);

		if (msobjBuf[reclen] == MO_FIXUPP) {
		    /*
		     * Record has fixups. Process them first, so we expand
		     * fixed-up data.
		     */
		    Pass2MSProcessRels(file, rectype, sd, startOff,
				       reclen, bp);
		}
		/*
		 * Figure the number of bytes in the block and shove the whole
		 * thing out to the output file.
		 */
		bufPtr = bp;
		size = MSObj_CalcIDataSize(&bufPtr);

		bufPtr = buf = (byte *)malloc(size);
		MSObj_ExpandIData(&bp, &bufPtr);

		Out_Block(sd->nextOff + startOff, buf, size);

		free((void *)buf);

		break;
	    }
	    case MO_COMDEF:
		/* Ignore -- handled in pass 1*/
		break;
	    case MO_BACKPATCH:
		MSObj_SaveRecord(rectype, reclen, &backPatches);
		break;
	    case MO_BACKPATCH32:
		Notify(NOTIFY_ERROR,
		       "%s: 32-bit backpatches not supported (yet).",
		       file);
		goto file_done;
	    case MO_ERROR:
		Notify(NOTIFY_ERROR, "%s: invalid object record", file);
		goto file_done;
	}
    }

file_done:
    (*msobjFinish)(file, done, 2);
}
