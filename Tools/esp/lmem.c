/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Local Memory Segment Stuff
 * FILE:	  lmem.c
 *
 * AUTHOR:  	  Adam de Boor: Aug 14, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	LMem_DefineChunk    Begin the definition of a chunk
 *	LMem_EndChunk	    Finish off the definition of a chunk
 *	LMem_InitSegment    Initialize an LMem segment.
 *	LMem_CreateSegment  Create an LMem segment without defining any
 *	    	    	    data for it.
 *	LMem_UsesHandles    See if an LMem segment uses chunk handles.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/14/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Support for PCGEOS LMem segments.
 *
 *	An LMem segment is actually implemented as two segments in a
 *	group (the group is given the name from the segment directive).
 *	One segment contains the LMemBlockHeader and other data, while the
 *	other contains the handle table and the chunks themselves.
 *
 *	The problem posed by LMem segments lies in the need to place data that
 *	are not bracketed by CHUNK/ENDC directives between the block header
 *	and the handle table. The Data module is not set up (nor should
 *	it be) to insert data in the segment -- it simply overwrites
 *	whatever is there (as is required by certain things), yet that is
 *	exactly what is required when data are entered into an LMem
 *	segment outside of a chunk.
 *
 *	By breaking the segment into two, we avoid this need to insert
 *	data for all things except the addition of a chunk, when the
 *	handle table must be enlarged. This is completely under our control
 *	and is managed properly.
 *
 *	All other operations reduce to the simple overwriting and automatic
 *	extension of a segment already supported by the Data and Table
 *	modules.
 *
 *	SYM_CHUNK symbols have their block address as their addrsym.offset
 *	field, with the handle kept internally. This is to cause the
 *	address to be automatically adjusted when handles are inserted.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: lmem.c,v 3.10 93/02/12 18:47:58 adam Exp $";
#endif lint

#include    "esp.h"
#include    <objfmt.h>
#include    <stddef.h>
#include    <lmem.h>

#define DEFAULT_ALIGN  0xf  	/* Default to para alignment for compatibility
				 * with 1.X */

int	lmem_Alignment = DEFAULT_ALIGN;


/***********************************************************************
 *				LMemStoreOffset
 ***********************************************************************
 * SYNOPSIS:	    Use the size of the current segment to set the
 *	    	    LMBH_offset field of the header
 * CALLED BY:	    Fixup code (pass 4)
 * RETURN:	    FR_DONE
 * SIDE EFFECTS:    Not really (LMBH_offset field overwritten)
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/14/89		Initial Revision
 *
 ***********************************************************************/
FixResult
LMemStoreOffset(int 	*dotPtr,
		int 	prevSize,
		int 	pass,
		Expr	*expr1,
		Expr	*expr2,
		Opaque	data)
{
    byte    	b[2];
    dword    	size = Table_Size(curSeg->u.segment.code);

    /*
     * Convert size to buffer in proper byte order, padding to the
     * proper boundary, as dictated by lmem_Alignment.
     */
    size = (size + lmem_Alignment) & ~lmem_Alignment;
    b[0] = size;
    b[1] = size >> 8;

    /*
     * Store the bytes in the current segment at the given offset.
     */
    Table_Store(curSeg->u.segment.code, 2, (void *)b, *dotPtr);

    /*
     * Advance so fixup module knows we used all the space.
     */
    *dotPtr += 2;

    return(FR_DONE);
}

/***********************************************************************
 *				LMemStoreSize
 ***********************************************************************
 * SYNOPSIS:	    Store the combined size of the two LMem segments
 *	    	    in the LMBH_blockSize field of the header in the
 *	    	    current segment.
 * CALLED BY:	    Fix_Pass4
 * RETURN:	    FR_DONE (all set)
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/14/89		Initial Revision
 *
 ***********************************************************************/
FixResult
LMemStoreSize(int 	*dotPtr,
	      int 	prevSize,
	      int 	pass,
	      Expr	*expr1,
	      Expr	*expr2,
	      Opaque	data)	    /* Paired segment */
{
    byte    	b[2];
    dword    	size = Table_Size(curSeg->u.segment.code);
    SymbolPtr	pair = (SymbolPtr)data;

    /*
     * Convert size to buffer in proper byte order, padding both to a dword
     * boundary, as that's the alignment for the handle table.
     */
    size = ((size + lmem_Alignment) & ~lmem_Alignment) +
	Table_Size(pair->u.segment.code);
    
    b[0] = size;
    b[1] = size >> 8;

    /*
     * Store the bytes in the current segment at the given offset.
     */
    Table_Store(curSeg->u.segment.code, 2, (void *)b, *dotPtr);

    /*
     * Advance so fixup module knows we used all the space.
     */
    *dotPtr += 2;

    return(FR_DONE);
}


/***********************************************************************
 *				LMemAddFreeSpace
 ***********************************************************************
 * SYNOPSIS:	    Tack the requested amount of free space onto the end
 *	    	    of the heap.
 * CALLED BY:	    Fixup module
 * RETURN:	    FR_DONE.
 * SIDE EFFECTS:    The indicated amount of free space is tacked onto the
 *	    	    end of the heap segment and initialized as a free block
 *	    	    A final-pass fixup is register to store the final
 *	    	    offset of the free block in the header.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/19/90		Initial Revision
 *
 ***********************************************************************/
FixResult
LMemAddFreeSpace(int 	*dotPtr,
		 int 	prevSize,
		 int 	pass,
		 Expr	*expr1,
		 Expr	*expr2,
		 Opaque	data)	    /* Amount of free space desired */
{
    byte    	b[2];
    word    	freeSpace = (word)data;
    byte    	*freeBlock;
    SymbolPtr	pair = curSeg->u.segment.data->pair;
    dword   	freeOffset;
    int	    	i;


    freeBlock = (byte *)malloc(freeSpace);
    /*
     * Initialize the free block. The first word contains the block's size;
     * the second contains the next free block pointer (0); all the rest contain
     * 0xcc -- the universal debugging constant.
     */
    freeBlock[0] = freeSpace;
    freeBlock[1] = freeSpace >> 8;
    freeBlock[2] = freeBlock[3] = 0; /* No next free block */
    for (i = 4; i < freeSpace; i++) {
	freeBlock[i] = 0xcc;
    }

    /*
     * Add the free block to the end of the heap segment.
     */
    freeOffset = Table_Size(pair->u.segment.code);
    Table_Store(pair->u.segment.code, freeSpace, (void *)freeBlock, freeOffset);

    freeOffset += (Table_Size(curSeg->u.segment.code)+lmem_Alignment) & ~lmem_Alignment;

    b[0] = freeOffset;
    b[1] = freeOffset >> 8;
    
    Table_Store(curSeg->u.segment.code, 2, (void *)b, *dotPtr);

    /*
     * Adjust the LMBH_blockSize field as well.
     */
    freeOffset += freeSpace;

    b[0] = freeOffset;
    b[1] = freeOffset >> 8;

    Table_Store(curSeg->u.segment.code, 2, (void *)b,
		offsetof(LMemBlockHeader,LMBH_blockSize));

    /*
     * Advance so fixup module knows we used all the space.
     */
    *dotPtr += 2;

    free((void *)freeBlock);
    return(FR_DONE);
}

/***********************************************************************
 *				LMemRoundNumHandles
 ***********************************************************************
 * SYNOPSIS:	    Round the number of handles stored in the block's
 *	    	    header up to an even number, since we always allocate
 *	    	    handles in the table by twos (to keep the heap
 *	    	    dword-aligned)
 * CALLED BY:	    Fixup module
 * RETURN:	    FR_DONE.
 * SIDE EFFECTS:    The word at the address is rounded up.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 8/91		Initial Revision
 *
 ***********************************************************************/
static FixResult
LMemRoundNumHandles(int 	*dotPtr,
		    int 	prevSize,
		    int 	pass,
		    Expr	*expr1,
		    Expr	*expr2,
		    Opaque	data)
{
    byte    	b[2];
    word    	nHandles;

    Table_Fetch(curSeg->u.segment.code, 2, (void *)b, *dotPtr);
    nHandles = b[0] | (b[1] << 8);

    nHandles = (nHandles + 1) & ~1;

    b[0] = nHandles;
    b[1] = nHandles >> 8;

    Table_Store(curSeg->u.segment.code, 2, (void *)b, *dotPtr);

    /*
     * The extra handle, if such there be, was initialized to 0 by
     * LMem_DefineChunk, so no need to do it here...
     */

    /*
     * Adjust address so fixup module doesn't think we lied to it.
     */
    *dotPtr += prevSize;

    return(FR_DONE);
}
		

/***********************************************************************
 *				LMem_CreateSegment
 ***********************************************************************
 * SYNOPSIS:	    Create an LMem group
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    One SYM_GROUP and two SYM_SEGMENT symbols are created.
 *	    	
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/14/89		Initial Revision
 *
 ***********************************************************************/
SymbolPtr
LMem_CreateSegment(ID 	name)
{
    char    	    *nameStr;	/* Locked version of "name" */
    char    	    *segName;	/* New name for internal segments */
    ID	    	    segID;  	/* ID for internal segments */
    ID 	    	    class;  	/* ID of class for internal segments */
    SymbolPtr	    dataSeg,	/* Data/header segment */
		    heapSeg;	/* Heap (handle table, et al) segment */

    nameStr = ST_Lock(output, name);

    /* 5 = strlen("@Heap" || "@Data") + 1 */
    segName = (char *)malloc(strlen(nameStr) + 6);
    class = ST_EnterNoLen(output, permStrings, "LMEM");

    /*
     * Create the data segment first -- padded to a word boundary,
     * as all resource segments are.
     */
    sprintf(segName, "%s@Data", nameStr);

    segID = ST_EnterNoLen(output, symStrings, segName);
    dataSeg = Sym_Enter(segID, SYM_SEGMENT, SEG_LMEM, lmem_Alignment, class);

    /*
     * Now the heap segment (with the handle table and chunks) aligned to
     * a word boundary, as the handle table must be.
     */
    sprintf(segName, "%s@Heap", nameStr);

    segID = ST_EnterNoLen(output, symStrings, segName);
    heapSeg = Sym_Enter(segID, SYM_SEGMENT, SEG_LMEM, lmem_Alignment, class);

    free(segName);

    /*
     * Point the two segments at each other for LMem_DefineChunk and
     * LMem_EndChunk.
     */
    heapSeg->u.segment.data->pair = dataSeg;
    dataSeg->u.segment.data->pair = heapSeg;

    /*
     * Mark data segment as uninitialized.
     */
    dataSeg->u.segment.data->inited = FALSE;

    /*
     * Finally, create the group that encompasses them both.
     */
    return (Sym_Enter(name, SYM_GROUP, 2, dataSeg, heapSeg));

}


/***********************************************************************
 *				LMem_InitSegment
 ***********************************************************************
 * SYNOPSIS:	    Initialize
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    One SYM_GROUP and two SYM_SEGMENT symbols are created.
 *	    	    The data segment for the LMem group has an LMem
 *	    	    block header stored at its beginning, with
 *	    	    appropriate internal and external fixups
 *	    	    registered to fixup the header.
 *	    	
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/14/89		Initial Revision
 *
 ***********************************************************************/
void
LMem_InitSegment(SymbolPtr	group,
		 word		segType,
		 word		flags,
		 word	    	freeSpace)
{
    LMemBlockHeader lmbh;   	/* Header to store at front of dataSeg */
    byte    	    *bp;    	/* Pointer for initializing header in proper
				 * byte-order */
    ExprResult	    res;    	/* Result for external handle fixup */

    /*
     * Change to the data segment of the lmem group.
     */
    PushSegment(group->u.group.segs[0]);

    /*
     * If already initialized, just return.
     */
    if (curSeg->u.segment.data->inited) {
	return;
    }

    /*
     * Make sure nothing got in here before us.
     */
    if (Table_Size(curSeg->u.segment.code) != 0) {
	yyerror("cannot initialize lmem segment %i -- data stored before header",
		group->name);
	return;
    }
    curSeg->u.segment.data->inited = TRUE;

    /*
     * Set up the header block for the thing, storing in the flags and
     * segment type we were given.
     */
    bzero(&lmbh, sizeof(lmbh));
    bp = (byte *)&lmbh.LMBH_flags;
    *bp++ = flags;
    *bp++ = flags >> 8;
    *bp++ = segType;
    *bp++ = segType >> 8;

    freeSpace = (freeSpace + 3) & ~3;
    bp = (byte *)&lmbh.LMBH_totalFree;
    *bp++ = freeSpace;
    *bp = freeSpace >> 8;

    /*
     * Store the header in the segment, advancing dot so the next data
     * stored go after the header.
     */
    Table_Store(curSeg->u.segment.code, sizeof(lmbh), (void *)&lmbh, 0);
    dot += sizeof(lmbh);

    /*
     * Register fixup for the LMBH_offset field for the final pass so
     * we get the proper value in the header.
     */
    Fix_Register(FC_FINAL, LMemStoreOffset,
		 offsetof(LMemBlockHeader, LMBH_offset),
		 2,
		 NULL,
		 NULL,
		 (Opaque)NULL);

    /*
     * Register fixup for LMBH_nHandles so we can round it up properly.
     */
    Fix_Register(FC_FINAL, LMemRoundNumHandles,
		 offsetof(LMemBlockHeader, LMBH_nHandles),
		 2,
		 NULL,
		 NULL,
		 (Opaque)NULL);
    /*
     * If any free space requested, register a FINAL fixup to add the free
     * block at the end of the segment.
     */
    if (freeSpace != 0) {
	Fix_Register(FC_FINAL, LMemAddFreeSpace,
		     offsetof(LMemBlockHeader, LMBH_freeList),
		     2,
		     NULL,
		     NULL,
		     (Opaque)freeSpace);
    } else {
	/*
	 * Register fixup for the LMBH_blockSize field for the final pass so
	 * we get the proper value in the header. This is only registered if
	 * no extra free space was declared, as LMemAddFreeSpace has to set
	 * LMBH_blockSize anyway to account for the extra free block.
	 */
	Fix_Register(FC_FINAL, LMemStoreSize,
		     offsetof(LMemBlockHeader, LMBH_blockSize),
		     2,
		     NULL,
		     NULL,
		     (Opaque)curSeg->u.segment.data->pair);
	
	
    }
    /*
     * Enter a FIX_HANDLE external fixup for the LMBH_handle field of
     * the header.
     */
    res.rel.sym = res.rel.frame = group;
    res.rel.type = FIX_HANDLE;
    res.rel.size = FIX_SIZE_WORD;
    res.rel.pcrel = 0;
    res.rel.fixed = 0;
    Fix_Enter(&res,
	      offsetof(LMemBlockHeader, LMBH_handle),
	      offsetof(LMemBlockHeader, LMBH_handle));
}


/***********************************************************************
 *				LMemFixHandle
 ***********************************************************************
 * SYNOPSIS:	    Fix up the LMem structures for a chunk once
 *	    	    everything is set.
 * CALLED BY:	    Fix_Pass4
 * RETURN:	    FR_DONE
 * SIDE EFFECTS:    Not really.
 *
 * STRATEGY:	    Figure the address of the block and store it in
 *	    	    the handle.
 *
 *	    	    XXX: This should probably be done with a link-time
 *	    	    relocation of something w.r.t. the lmem group.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/15/89		Initial Revision
 *
 ***********************************************************************/
FixResult
LMemFixHandle(int 	*dotPtr,
	      int 	prevSize,
	      int 	pass,
	      Expr	*expr1,
	      Expr	*expr2,
	      Opaque	data)	    /* Chunk symbol to fix */
{
    byte    	b[2];
    SymbolPtr	sym = (SymbolPtr)data;
    word    	offset;
    SymbolPtr	pair;

    /*
     * First figure the size of the data portion so we can determine the
     * offset of the handle table in the group.
     */
    pair = sym->segment->u.segment.data->pair;
    offset = (Table_Size(pair->u.segment.code)+lmem_Alignment)&~lmem_Alignment;
    /*
     * Now add in the offset of the chunk data w/in the heap segment.
     */
    offset += sym->u.addrsym.offset;

    b[0] = offset;
    b[1] = offset >> 8;

    /*
     * Store the bytes in the current segment at the given offset.
     */
    Table_Store(curSeg->u.segment.code, 2, (void *)b, *dotPtr);

    /*
     * Advance so fixup module knows we used all the space.
     */
    *dotPtr += 2;

    return(FR_DONE);
}    


/***********************************************************************
 *				LMem_DefineChunk
 ***********************************************************************
 * SYNOPSIS:	    Begin the definition of a chunk
 * CALLED BY:	    parser
 * RETURN:	    The symbol of the new chunk
 * SIDE EFFECTS:    A handle is added to the heap segment's handle table
 *	    	    Fixups and symbols for the segment are adjusted to
 *	    	    account for the new handle
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/14/89		Initial Revision
 *
 ***********************************************************************/
SymbolPtr
LMem_DefineChunk(TypePtr    type,   /* Type of data in the chunk */
		 ID 	    name)   /* Name for new symbol */
{
    byte    	b[2];	    /* Buffer for adjusting LMBH_nHandles */
    word    	nHandles;   /* Number of handles in table */
    SymbolPtr	sym;	    /* New chunk symbol */
    word    	flags;	    /* Flags so we know whether to create a handle
			     * for the thing... */

    /*
     * Make sure used has specified parameters for the segment and the
     * data segment has been initialized.
     */
    if (!curSeg->u.segment.data->inited) {
	yyerror("cannot open chunk -- lmem segment not initialized");
	return NullSymbol;
    }

    /*
     * Locate the nHandles field of the header and extract its value
     */
    Table_Fetch(curSeg->u.segment.code, 2, (void *)b,
		offsetof(LMemBlockHeader,LMBH_nHandles));
    nHandles = b[0] | (b[1] << 8);

    /*
     * Locate the flags word of the header and extract its value.
     */
    Table_Fetch(curSeg->u.segment.code, 2, (void *)b,
		offsetof(LMemBlockHeader,LMBH_flags));
    flags = b[0] | (b[1] << 8);

    /*
     * Switch to the heap segment of the group for the storage of data in
     * the chunk and the definition of the symbol itself.
     */
    PushSegment(curSeg->u.segment.data->pair);
    
    /*
     * Make room for the new handle in the table, adjusting following fixups
     * and symbols.
     * NOTE: We add handles two at a time, to keep the heap longword-aligned.
     * nHandles only goes up by one, however. Eventually nHandles is rounded
     * up...
     */
    if (!(flags & LMF_NO_HANDLES) && (nHandles & 1) == 0) {
	Table_Insert(curSeg->u.segment.code, nHandles * 2, 4);
	Table_StoreZeroes(curSeg->u.segment.code, 4, nHandles * 2);
	Fix_Adjust(curSeg, nHandles*2, 4);
	Sym_Adjust(curSeg, nHandles*2, 4);
    }

    /*
     * Figure where the block should go (at the end of the segment, plus
     * two bytes to account for the size word). Note we do not actually
     * store anything as that would cause the table to be extended, which
     * we don't want if the chunk is to be empty.
     */
    dot = Table_Size(curSeg->u.segment.code) + 2;
    
    if (flags & LMF_NO_HANDLES) {
	/*
	 * The beast is actually a variable, since it's available for
	 * immediate reference...
	 */
	sym = Sym_Enter(name, SYM_VAR, dot, type);
    } else {
	/*
	 * Create the symbol for the chunk, giving the address of the block
	 * as the addrsym.offset, nHandles*2 as the handle (this will never
	 * change) and the passed type as the type of data stored in the chunk.
	 */
	sym = Sym_Enter(name, SYM_CHUNK, dot, nHandles*2, type);

	/*
	 * Up the number of handles and store it away.
	 */
	nHandles += 1;
	b[0] = nHandles;
	b[1] = nHandles >> 8;
	Table_Store(curSeg->u.segment.data->pair->u.segment.code,
		    2, (void *)b,
		    offsetof(LMemBlockHeader,LMBH_nHandles));
    }

    return(sym);
}
    

/***********************************************************************
 *				LMem_EndChunk
 ***********************************************************************
 * SYNOPSIS:	    Close out the current chunk
 * CALLED BY:	    parser (on ENDC directive)
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The size of the chunk is stored in the word
 *	    	    before the chunk.
 *	    	    The current segment reverts to the pair (data
 *	    	    segment) in the lmem group.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/15/89		Initial Revision
 *
 ***********************************************************************/
void
LMem_EndChunk(SymbolPtr	    sym)
{
    word    size;
    byte    b[4];
    word    flags;	    /* Flags so we know whether there's a handle to
			     * be fixed up */

    Table_Fetch(curSeg->u.segment.data->pair->u.segment.code, 2, (void *)b,
		offsetof(LMemBlockHeader,LMBH_flags));
    flags = b[0] | (b[1] << 8);
    
    /*
     * Figure the final size of the chunk, including the size word
     */
    size = (dot - sym->u.addrsym.offset) + 2;

    if (size == 2) {
	if (flags & LMF_NO_HANDLES) {
	    yyerror("empty chunks are not allowed inside lmem segments with no chunk handles");
	    return;
	}
	
	/*
	 * Chunk is empty. This is handled specially. Rather than using four
	 * bytes, we arrange for the handle to hold 0xffff and rein dot back
	 * in to its previous location (2 less than it is now).
	 */
	b[1] = b[0] = 0xff;

	Table_Store(curSeg->u.segment.code, 2, (void *)b,
		    sym->u.chunk.handle);

	dot -= 2;
    } else {
	/*
	 * Register a fixup for the handle to store the final address of the
	 * chunk in the handle table, passing the chunk symbol as the data.
	 */
	if (!(flags & LMF_NO_HANDLES)) {
	    Fix_Register(FC_FINAL, LMemFixHandle, sym->u.chunk.handle, 2, NULL,
			 NULL, (Opaque)sym);
	}
			      
	/*
	 * Format it in the proper byte-order
	 */
	b[0] = size;
	b[1] = size >> 8;

	/*
	 * Store the bytes in the size word for the chunk.
	 */
	(void)Table_Store(curSeg->u.segment.code, 2, (void *)b,
			  sym->u.addrsym.offset-2);

	/*
	 * The size of a chunk (including the size word) is padded to a
	 * four-byte boundary so there can be enough pad bytes to ensure that
	 * when chunk is shrunk down, the kernel can force there to be a
	 * four-byte chunk of space for linking into the free list (size word +
	 * next handle)
	 */
	if (size & 3) {
	    /*
	     * Pad the block out to a four-byte boundary so the next chunk
	     * starts right. Note that kernel EC code expects extra bytes
	     * to all be 0xcc, so that's what we store (3 bytes at most).
	     */
	    b[0] = b[1] = b[2] = 0xcc;
	    (void)Table_Store(curSeg->u.segment.code, 4 - (size & 3),
			      (void *)b, dot);
	    dot += 4 - (size & 3);
	}
    }

    /*
     * Revert to the data segment for the lmem group.
     */
    PopSegment();
}
    
    

/***********************************************************************
 *				LMem_UsesHandles
 ***********************************************************************
 * SYNOPSIS:	    See if the passed LMem segment uses chunk handles
 *	    	    (i.e. if chunks in the segment are defined as SYM_CHUNK
 *	    	    or SYM_VAR symbols)
 * CALLED BY:	    GLOBAL
 * RETURN:	    non-zero if the segment uses chunk handles
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/27/91		Initial Revision
 *
 ***********************************************************************/
int
LMem_UsesHandles(SymbolPtr  seg)
{
    byte    b[2];
    word    flags;	    /* Flags so we know whether there's a handle to
			     * be fixed up */

    Table_Fetch(seg->u.segment.code, 2, (void *)b,
		offsetof(LMemBlockHeader,LMBH_flags));
    flags = b[0] | (b[1] << 8);

    return (!(flags & LMF_NO_HANDLES));
}
