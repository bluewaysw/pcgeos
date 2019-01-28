/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  ESP -- Dynamically sized table implementation.
 * FILE:	  table.c
 *
 * AUTHOR:  	  Adam de Boor: Mar  9, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Table_Init  	    Initialize a table
 *	Table_Delete	    Delete elements from a table
 *	Table_Insert	    Insert elements into a table
 *	Table_Size  	    Find number of elements in the table
 *	Table_Write 	    Write table to a file
 *	Table_Store 	    Store elements in a table
 *	Table_StoreZeroes   Store blank (zero) elements in a table.
 *	Table_Lookup	    Find the position of an element in a table
 *	Table_EnumFirst	    Begin enumerating the elements of a table
 *	Table_EnumNext	    Find the next element of a table
 *	Table_Fetch 	    Extract elements from a table
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/ 9/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Implementation of the Table object.
 *
 *	XXX: Optimize for byte-sized elements?
 *
 ***********************************************************************/

#include    "esp.h"
#include    "table.h"

/*
 * A piece of a table.
 */
typedef struct {
    int	    numElts;	    /* Number of elements stored in the chunk */
    int	    maxElts;	    /* Number of elements that may be stored */
    genptr  elts;  	    /* The elements themselves */
} TableChunk;

/*
 * A table descriptor
 */
typedef struct {
    TableChunk	*chunks;    	/* Extensible array of chunks */
    int	    	numChunks;  	/* Size of chunks array */
    int	    	tableSize;  	/* Number of elements in the table */
    int	    	eltSize;    	/* Size of each element */
    int	    	eltsPerChunk;	/* Initial size of each chunk */
} TableRec, *TablePtr;

#define INITIAL_NUM_CHUNKS  	1

#define SCALE(pos,tp)  ((tp)->eltSize==1?(pos):(pos)*(tp)->eltSize)


/***********************************************************************
 *				TableVerify
 ***********************************************************************
 * SYNOPSIS:	    Make sure the table isn't fucked
 * CALLED BY:	    All table routines except Table_Init
 * RETURN:	    Only if table's ok
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 6/89	Initial Revision
 *
 ***********************************************************************/
static void
TableVerify(TablePtr	tp)
{
    int	    	    i;
    TableChunk      *tcp;
    int	    	    size;

    assert(tp->numChunks <=
              malloc_size((malloc_t)tp->chunks)/sizeof(TableChunk));
    assert(tp->numChunks >= 1);

    for (i = 0, size = 0, tcp = tp->chunks; i < tp->numChunks; i++, tcp++) {
	size += tcp->numElts;
	assert(tcp->maxElts <= malloc_size(tcp->elts)/tp->eltSize);
	assert(tcp->numElts <= tcp->maxElts);
    }
    assert(size == tp->tableSize);
}

/***********************************************************************
 *				Table_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize a new table.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    A new Table token for later use.
 * SIDE EFFECTS:    Memory is allocated.
 *
 * STRATEGY:
 *	XXX: How many chunks should be allocated at first?
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 9/89		Initial Revision
 *
 ***********************************************************************/
Table
Table_Init(int	eltSize,    	    /* Size of each element */
	   int	eltsPerChunk)	    /* Elements allocated per chunk */
{
    TablePtr	tp; 	    	    /* Internal representation of new table */
    int	    	i;

    tp = (TablePtr)malloc(sizeof(TableRec));
    tp->numChunks = 	INITIAL_NUM_CHUNKS;
    tp->chunks =    	(TableChunk *)malloc(tp->numChunks *
					     sizeof(TableChunk));
    tp->tableSize = 	0;
    tp->eltSize =   	eltSize;
    tp->eltsPerChunk = 	eltsPerChunk;

    for (i = 0; i < tp->numChunks; i++) {
	tp->chunks[i].numElts = 0;
	tp->chunks[i].maxElts = eltsPerChunk;
	tp->chunks[i].elts    = (genptr)malloc(eltSize * eltsPerChunk);
    }

    return((Table)tp);
}

/***********************************************************************
 *				Table_Delete
 ***********************************************************************
 * SYNOPSIS:	    Delete elements from a table.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Elements after those deleted have their positions
 *		    adjusted (nothing actually done here, but the effect
 *		    is still present).
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 9/89		Initial Revision
 *
 ***********************************************************************/
void
Table_Delete(Table  table,  	/* Table to alter */
	     int    pos,    	/* Position of first element to delete */
	     int    numElts)	/* Number of elements to delete */
{
    TablePtr	    tp = (TablePtr)table;
    int	    	    i;
    TableChunk	    *tcp;

    TableVerify(tp);

    tp->tableSize -= numElts;

    for (i = tp->numChunks, tcp = tp->chunks;
	 numElts > 0 && i > 0;
	 i--, tcp++)
    {
	if (tcp->numElts <= pos) {
	    /*
	     * Not there yet -- adjust pos for the elements we're skipping
	     */
	    pos -= tcp->numElts;
	} else {
	    if (pos + numElts >= tcp->numElts) {
		/*
		 * All elements to delete from this chunk are at the end --
		 * no motion necessary. May still be things in the next
		 * chunk to nuke though, so we just adjust numElts; we don't
		 * break out of the loop.
		 */
		int 	ne = tcp->numElts - pos;

		tcp->numElts = pos;
		pos = 0;	/* adjust to start of next chunk */
		numElts -= ne;
	    } else {
		genptr	src, dest;
		int 	numCopy;

		/*
		 * Copy down to the pos'th element
		 */
		dest = tcp->elts + (SCALE(pos,tp));
		/*
		 * Copy from numElts beyond the pos'th
		 */
		src = dest + (SCALE(numElts,tp));
		/*
		 * Figure the number of elements to copy down, adjusting
		 * tcp->numElts as you go.
		 */
		numCopy = tcp->numElts - (pos + numElts);
		tcp->numElts -= numElts;
		/*
		 * Copy them down
		 */
		bcopy(src, dest, SCALE(numCopy,tp));
		/*
		 * All done.
		 */
		numElts = 0;
		break;
	    }
	}
    }
    /*
     * Add back any elements we couldn't delete.
     */
    tp->tableSize += numElts;
    TableVerify(tp);
}


/***********************************************************************
 *				Table_Insert
 ***********************************************************************
 * SYNOPSIS:	    Insert elements into the table.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Elements in the expanded chunk may move.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 9/89		Initial Revision
 *
 ***********************************************************************/
void
Table_Insert(Table  table,
	     int    pos,
	     int    numElts)
{
    TablePtr	    tp = (TablePtr)table;
    int	    	    i;
    TableChunk	    *tcp;

    TableVerify(tp);
    assert(numElts <= tp->eltsPerChunk);

    if (numElts > tp->eltsPerChunk) {
	/*
	 * This is illegal.
	 */
	return;
    }

    tp->tableSize += numElts;

    for (i = tp->numChunks, tcp = tp->chunks; i > 0; i--, tcp++) {
	if (pos >= tcp->numElts) {
	    pos -= tcp->numElts;
	} else {
	    /*
	     * Insert in this chunk. We want to move as little as possible.
	     */
	    if (pos == tcp->numElts) {
		/*
		 * Adding to the end of the chunk. If we can fit the desired
		 * elements in w/o reallocating this chunk, fine.
		 */
		if (pos + numElts <= tcp->maxElts) {
		    tcp->numElts += numElts;
		    numElts = 0;
		    break;
		} else if (i > 1) {
		    if (tcp[1].numElts == 0) {
			/*
			 * Nothing in the next chunk -- just place the
			 * new elements there.
			 */
			if (numElts <= tcp[1].maxElts) {
			    /*
			     * Just set the number of elements -- they'll fit
			     */
			    tcp[1].numElts = numElts;
			} else {
			    /*
			     * They all won't fit. Nothing to copy, however,
			     * so just allocate a new array and free the
			     * old. (XXX: Use the chunk after?)
			     */
			    genptr  old = tcp[1].elts;

			    tcp[1].elts = (genptr)malloc(SCALE(numElts, tp));
			    free((char *)old);
			    tcp[1].numElts = tcp[1].maxElts = numElts;
			}
			numElts = 0;
			break;
		    } else if (tcp[1].numElts < tcp->maxElts) {
			/*
			 * Fewer active elements in the next than
			 * total in this one -- allocate a new chunk and
			 * copy the elements in the next chunk by hand
			 * rather than chance copying the whole current
			 * chunk in realloc (is this logic reasonable?
			 * too bad we can't find out if the stuff *will* be
			 * copied...)
			 */
			if (tcp[1].maxElts < tcp[1].numElts + numElts) {
			    /*
			     * New elements won't fit in old chunk, so
			     * allocate a new one, then copy the
			     * old elements to their new place in the new
			     * chunk.
			     */
			    genptr	old = tcp[1].elts;
			    int	    	numUsed = tcp[1].numElts+numElts;

			    if (numUsed > tcp[1].maxElts) {
				tcp[1].maxElts = numUsed;
			    }
			    tcp[1].elts = (genptr)malloc(SCALE(numUsed,
								      tp));
			    bcopy(old, tcp[1].elts+SCALE(numElts,tp),
				  SCALE(tcp[1].numElts,tp));
			    tcp[1].numElts = numUsed;
			    free((char *)old);
			    numElts = 0;
			    break;
			} else {
			    /*
			     * Else just copy the elements up to make
			     * room and adjust the number of elements.
			     */
			    bcopy(tcp[1].elts,
				  tcp[1].elts+SCALE(numElts,tp),
				  SCALE(tcp[1].numElts,tp));
			    tcp[1].numElts += numElts;
			    numElts = 0;
			    break;
			}
		    } else {
			/*
			 * Just realloc the current chunk to hold the
			 * new elements.
			 */
			tcp->elts =
			    (genptr)realloc(tcp->elts,
					    SCALE((tcp->numElts +
							   numElts),tp));
			tcp->maxElts = (tcp->numElts += numElts);
			numElts = 0;
			break;
		    }
		} else {
		    /*
		     * Adding to the last chunk. Stick as many as will
		     * fit into this one and allocate a new chunk for
		     * the rest (there will be leftovers since the elements
		     * couldn't fit in the current chunk (remember the
		     * first "if" in this part?)).
		     */
		    numElts -= tcp->maxElts - tcp->numElts;

		    tcp->numElts = tcp->maxElts;

		    tp->numChunks += 1;
		    tp->chunks =
			(TableChunk *)realloc((void *)tp->chunks,
					      (tp->numChunks *
					       sizeof(TableChunk)));
		    tcp = &tp->chunks[tp->numChunks-1];
		    tcp->numElts = numElts;
		    tcp->maxElts = tp->eltsPerChunk;
		    tcp->elts =
			(genptr)malloc(SCALE(tp->eltsPerChunk,tp));
		    numElts = 0;
		    break;
		}
	    } else if (i > 1) {
		/*
		 * Need to move stuff, but there are elements following.
		 */
		if (tcp->numElts + numElts <= tcp->maxElts) {
		    /*
		     * Just shift these ones up -- not worth hassling the
		     * next chunk.
		     */
		    genptr   dest, src;
		    int	    numCopy;

		    src = tcp->elts + SCALE(pos,tp);
		    dest = src + SCALE(numElts,tp);
		    numCopy = tcp->numElts - pos;

		    bcopy(src, dest, SCALE(numCopy,tp));
		    tcp->numElts += numElts;
		    numElts = 0;
		    break;
		} else if (tcp[1].numElts == 0 &&
			   tcp[1].maxElts >= (tcp->numElts - pos))
		{
		    /*
		     * Next chunk is empty and will hold the extra ones
		     * in this chunk -- just copy the extra ones into the
		     * next chunk and adjust things properly (we would
		     * have had to copy these things anyway, but this way
		     * we avoid copying the initial things as well).
		     */
		    genptr  src;
		    int	    numCopy;
		    int	    destOff;

		    src = tcp->elts + SCALE(pos,tp);
		    numCopy = tcp->numElts - pos;

		    /*
		     * Figure offset into next chunk at which elements
		     * should go to account for any spillover from previous
		     * and elements being inserted.
		     */
		    destOff = pos + numElts - tcp->maxElts;
		    if (destOff < 0) {
			/*
			 * None -- just set to 0
			 */
			destOff = 0;
		    }

		    /*
		     * Make sure we won't be overflowing the next chunk.
		     */
		    if (destOff+numCopy < tcp[1].maxElts) {
			/*
			 * Well we were wrong, but there's nothing in this
			 * chunk, so we can just free the old buffer and
			 * allocate a new one...
			 */
			genptr  new;

			new = (genptr)malloc(destOff + numCopy);
			free(tcp[1].elts);
			tcp[1].elts = new;
			tcp[1].maxElts = destOff+numCopy;
		    }

		    bcopy(src,
			  tcp[1].elts+SCALE(destOff,tp),
			  SCALE(numCopy,tp));
		    tcp[1].numElts = numCopy+destOff;
		    tcp->numElts = pos + numElts-destOff;
		    numElts = 0;
		    break;
		} else {
		    genptr  old;

		    old = tcp->elts;
		    tcp->elts = (genptr)malloc(SCALE((tcp->numElts +
							     numElts),tp));
		    bcopy(old, tcp->elts, SCALE(pos,tp));
		    bcopy(old + SCALE(pos,tp),
			  tcp->elts + SCALE((pos + numElts),tp),
			  SCALE((tcp->numElts - pos),tp));

		    free((char *)old);
		    tcp->maxElts = (tcp->numElts += numElts);
		    numElts = 0;
		    break;
		}
	    } else if (tcp->numElts + numElts <= tcp->maxElts) {
		/*
		 * Just shift these ones up -- not worth hassling the
		 * next chunk.
		 */
		genptr  dest, src;
		int	    numCopy;

		src = tcp->elts + SCALE(pos,tp);
		dest = src + SCALE(numElts,tp);
		numCopy = tcp->numElts - pos;

		bcopy(src, dest, SCALE(numCopy,tp));
		tcp->numElts += numElts;
		numElts = 0;
		break;
	    } else {
		/*
		 * Allocate a new chunk to hold the overflow.
		 */
		genptr	src;
		int	numCopy;
		int	destOff;

		tp->numChunks += 1;
		tp->chunks = (TableChunk *)realloc((void *)tp->chunks,
						   tp->numChunks *
						   sizeof(TableChunk));
		tcp = &tp->chunks[tp->numChunks-2];

		src = tcp->elts + SCALE(pos, tp);
		numCopy = tcp->numElts - pos;

		/*
		 * Figure offset into next chunk at which elements
		 * should go to account for any spillover from previous.
		 */
		destOff = pos + numElts - tcp->maxElts;
		if (destOff < 0) {
		    /*
		     * None -- just set to 0
		     */
		    destOff = 0;
		}

		tcp[1].maxElts = tp->eltsPerChunk;
		/*
		 * Make sure we won't be overflowing the next chunk.
		 */
		if (destOff+numCopy > tcp[1].maxElts) {
		    /*
		     * Well we were wrong, but there's nothing in this
		     * chunk, so we can just allocate the thing as large
		     * as we please...
		     */
		    tcp[1].maxElts = destOff+numCopy;
		}

		tcp[1].elts = (genptr)malloc(SCALE(tcp[1].maxElts,tp));

		bcopy(src,
		      tcp[1].elts+SCALE(destOff,tp),
		      SCALE(numCopy,tp));
		tcp[1].numElts = numCopy+destOff;
		tcp->numElts = pos + numElts-destOff;
		numElts = 0;
	    }
	}
    }
    if (numElts > 0) {
	/*
	 * Weirdo is inserting at the end of the table -- allocate as
	 * much room as possible in the final chunk. If that's not enough,
	 * allocate another chunk to hold the rest.
	 */
	tcp = &tp->chunks[tp->numChunks-1];

	tcp->numElts += numElts;
	numElts = tcp->numElts - tcp->maxElts;
	if (numElts > 0) {
	    /*
	     * Sigh. Need to add another chunk. First reset tcp->numElts
	     * to be within bounds...
	     */
	    tcp->numElts = tcp->maxElts;

	    tp->numChunks += 1;
	    tp->chunks = (TableChunk *)realloc((void *)tp->chunks,
					       tp->numChunks *
					       sizeof(TableChunk));
	    tcp = &tp->chunks[tp->numChunks-1];
	    tcp->maxElts = tp->eltsPerChunk;
	    tcp->numElts = numElts;
	    tcp->elts = (genptr)malloc(SCALE(tp->eltsPerChunk,tp));
	}
    }
    TableVerify(tp);
}


/***********************************************************************
 *				Table_Size
 ***********************************************************************
 * SYNOPSIS:	    Return the number of elements stored in the table.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The number of elements...
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/10/89		Initial Revision
 *
 ***********************************************************************/
int
Table_Size(Table    table)
{
    return (((TablePtr)table)->tableSize);
}

/***********************************************************************
 *				Table_Write
 ***********************************************************************
 * SYNOPSIS:	    Write all elements of a table to a VM block
 * CALLED BY:	    EXTERNAL
 * RETURN:	    non-zero if successful.
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *	The block should have been allocated to hold the table.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/10/89		Initial Revision
 *
 ***********************************************************************/
int
Table_Write(Table   	    table,
	    VMBlockHandle   block)
{
    TablePtr	    tp = (TablePtr)table;
    int	    	    i;
    TableChunk	    *tcp;
    genptr	    bp;
    MemHandle	    mem;
    word    	    size;

    TableVerify(tp);

    bp = VMLock(output, block, &mem);
    MemInfo(mem, (genptr *)NULL, &size);

    assert(size >= tp->tableSize * tp->eltSize);

    for (i = tp->numChunks, tcp = tp->chunks; i > 0; i--, tcp++) {
	size = SCALE(tcp->numElts,tp);
	bcopy(tcp->elts, bp, size);
	bp += size;
    }
    VMUnlock(output, block);
    TableVerify(tp);
    return(1);
}

/***********************************************************************
 *				Table_Store
 ***********************************************************************
 * SYNOPSIS:	    Store elements in the table.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Address of the first element stored.
 * SIDE EFFECTS:    The table will be extended if pos is TABLE_END or if
 *	    	    pos + numElts extends beyond the end of the table..
 *	    	    Otherwise, elements are overwritten..
 *
 * STRATEGY:	    If pos is TABLE_END, we know we can just extend the
 *	    	    puppy, so we do so.
 *	    	    Else, run through the chunks looking for where to
 *	    	    start storing the new elements. Store the elements
 *	    	    in the appropriate chunks w/o modifying the lengths
 *	    	    at all (not inserting, only overwriting). If there
 *	    	    are still elements to be stored when we reach the
 *	    	    end of the table, we call ourselves with TABLE_END
 *	    	    as the position.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/10/89		Initial Revision
 *
 ***********************************************************************/
void *
Table_Store(Table   table,  	/* Table to modify */
	    int	    numElts,	/* Number of elements to store */
	    void    *eltPtr,	/* The elements themselves */
	    int	    pos)    	/* Position at which to store. If TABLE_END,
				 * elements are appended to the table */
{
    TablePtr	    tp = (TablePtr)table;
    int	    	    i;
    TableChunk	    *tcp;
    void    	    *result = NULL;

    TableVerify(tp);

    while (numElts > tp->eltsPerChunk) {
	/*
	 * Sometimes this happens. But rarely, so we just hack it by calling
	 * ourselves enough times to store the whole thing.
	 */
	Table_Store(table, tp->eltsPerChunk, eltPtr, pos);
	eltPtr = (genptr)eltPtr + tp->eltsPerChunk;
	numElts -= tp->eltsPerChunk;
	pos = (pos == TABLE_END ? TABLE_END : pos + tp->eltsPerChunk);
    }

    if (pos == TABLE_END || pos == tp->tableSize) {
	/*
	 * Special case for most-common case.
	 */
	tcp = &tp->chunks[tp->numChunks-1];

	tp->tableSize += numElts;

	if (tcp->numElts + numElts <= tcp->maxElts) {
	    /*
	     * All things will fit into this chunk -- copy them in and have
	     * done.
	     */
	    result = tcp->elts + SCALE(tcp->numElts,tp);
	    bcopy(eltPtr, result, SCALE(numElts,tp));
	    tcp->numElts += numElts;
	    return (result);
	} else if (tcp->numElts < tcp->maxElts) {
	    /*
	     * Some things will fit into this chunk. Put them there and
	     * add a new chunk to the end for the rest.
	     */
	    result = tcp->elts + SCALE(tcp->numElts,tp);
	    i = tcp->maxElts - tcp->numElts;
	    bcopy(eltPtr, result, SCALE(i,tp));

	    /*
	     * Adjust input values for the next chunk
	     */
	    numElts -= i;
	    eltPtr = (genptr)eltPtr + SCALE(i,tp);
	    tcp->numElts = tcp->maxElts;
	}
	/*
	 * Copy the (remaining) elements into a newly-allocated chunk.
	 */

	/*
	 * Allocate a new chunk
	 */
	tp->chunks = (TableChunk *)realloc((void *)tp->chunks,
					   ((tp->numChunks+1) *
					    sizeof(TableChunk)));
	/*
	 * Initialize same
	 */
	tcp = &tp->chunks[tp->numChunks];
	tcp->numElts = numElts;
	tcp->maxElts = tp->eltsPerChunk;
	tcp->elts = (genptr)malloc(SCALE(tp->eltsPerChunk,tp));
	tp->numChunks += 1;

	/*
	 * Copy the rest of the new elements in.
	 */
	bcopy(eltPtr, tcp->elts, SCALE(numElts,tp));
    } else {
	/*
	 * Copying into the table.
	 */
	result = (void *)NULL;

	if (pos < tp->tableSize) {
	    for (i=tp->numChunks, tcp=tp->chunks; i > 0 && numElts; i--, tcp++)
	    {
		if (pos < tcp->numElts) {
		    int 	numCopy;
		    genptr	dest;

		    numCopy = tcp->numElts - pos;
		    if (numCopy > numElts) {
			numCopy = numElts;
		    }

		    dest = tcp->elts + SCALE(pos,tp);
		    /*
		     * Set up return value if not set already.
		     */
		    if (result == (void *)NULL) {
			result = dest;
		    }

		    /*
		     * Copy in as many as will fit.
		     */
		    bcopy(eltPtr, dest, SCALE(numCopy,tp));

		    numElts -= numCopy;
		    eltPtr = (genptr)eltPtr + SCALE(numCopy,tp);
		    pos += numCopy;
		}

		pos -= tcp->numElts;
	    }
	} else {
	    /*
	     * Extend the table with enough elements to bring it up to
	     * the position at which things are being stored.
	     */
	    int	    need = pos - tp->tableSize;

	    tcp = &tp->chunks[tp->numChunks-1];

	    need -= tcp->maxElts - tcp->numElts;
	    if (need <= 0) {
		/*
		 * Enough in the current chunk -- just allocate whatever
		 * is needed (need is <= 0, so we add it to maxElts to get
		 * the proper numElts...). Note that any table extending
		 * must zero-fill the table...
		 */
		bzero(tcp->elts + SCALE(tcp->numElts,tp),
		      SCALE((tcp->maxElts + need - tcp->numElts),tp));
		tcp->numElts = tcp->maxElts + need;
	    } else {
		int chunksNeeded=(need+tp->eltsPerChunk-1) / tp->eltsPerChunk;
		int first;
		int i;

		/*
		 * Consume all that's left in the final chunk, initializing
		 * all to zeroes as required.
		 */
		bzero(tcp->elts + SCALE(tcp->numElts,tp),
		      SCALE((tcp->maxElts-tcp->numElts),tp));
		tp->tableSize += tcp->maxElts - tcp->numElts;
		tcp->numElts = tcp->maxElts;

		/*
		 * Record the index of the first new chunk, then enlarge
		 * the 'chunks' array to hold the number of chunks we need.
		 */
		first = tp->numChunks;
		tp->numChunks += chunksNeeded;
		tp->chunks =
		    (TableChunk *)realloc((void *)tp->chunks,
					  tp->numChunks*sizeof(TableChunk));

		/*
		 * For all but the last new chunk, allocate eltsPerChunk
		 * elements and mark them all as used.
		 */
		for (i = first; i < tp->numChunks-1; i++) {
		    tp->chunks[i].numElts =
			tp->chunks[i].maxElts = tp->eltsPerChunk;

		    tp->chunks[i].elts = (genptr)calloc(tp->eltsPerChunk,
							tp->eltSize);
		    tp->tableSize += tp->eltsPerChunk;
		}
		/*
		 * For the last chunk, we only allocate as many as is necessary
		 * to bring the tableSize up to match pos. The last chunk
		 * still holds eltsPerChunk elements, however.
		 */
		tp->chunks[i].numElts = pos - tp->tableSize;
		tp->chunks[i].maxElts = tp->eltsPerChunk;
		tp->chunks[i].elts = (genptr)calloc(tp->eltsPerChunk,
						    tp->eltSize);
	    }
	    tp->tableSize = pos;
	}

	/*
	 * If any elements left, the caller must want us to extend the
	 * table. Rather than calling Table_Insert, which is more
	 * general-purpose (and does more work) than we need, we just
	 * recurse, telling ourselves to place the elements at the end
	 * of the table.
	 */
	if (numElts > 0) {
	    Table_Store(table, numElts, eltPtr, TABLE_END);
	}
    }

    TableVerify(tp);

    return(result);
}


/***********************************************************************
 *				Table_StoreZeroes
 ***********************************************************************
 * SYNOPSIS:	    Store zeroed elements in the table.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Address of the first element stored.
 * SIDE EFFECTS:    The table will be extended if pos is TABLE_END or if
 *	    	    pos + numElts extends beyond the end of the table..
 *	    	    Otherwise, elements are overwritten..
 *
 * STRATEGY:	    Allocate a zeroed buffer to hold the desired elements
 *		    then store them all at once.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/10/89		Initial Revision
 *
 ***********************************************************************/
void *
Table_StoreZeroes(Table table, 	    /* Table to modify */
		  int	numElts,    /* Number of elements to store */
		  int   pos)        /* Position at which to store. If TABLE_END,
				     * elements are appended to the table */
{
    TablePtr	tp = (TablePtr)table;
    void	*buf;
    void	*retval;

    TableVerify(tp);
    buf = (void *)calloc(numElts, tp->eltSize);
    retval = Table_Store(table, numElts, buf, pos);
    free(buf);

    return(retval);
}


/***********************************************************************
 *				Table_Lookup
 ***********************************************************************
 * SYNOPSIS:	    Return the address of a given element in the table
 * CALLED BY:	    EXTERNAL
 * RETURN:	    See above (or NULL if the element isn't present)
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/10/89		Initial Revision
 *
 ***********************************************************************/
void *
Table_Lookup(Table  table,
	     int    pos)
{
    TablePtr	    tp = (TablePtr)table;
    int	    	    i;
    TableChunk	    *tcp;

    TableVerify(tp);

    for (i = tp->numChunks, tcp = tp->chunks; i > 0; i--, tcp++) {
	if (pos >= tcp->numElts) {
	    pos -= tcp->numElts;
	} else {
	    return (tcp->elts + SCALE(pos,tp));
	}
    }
    return((void *)NULL);
}


/***********************************************************************
 *				Table_EnumFirst
 ***********************************************************************
 * SYNOPSIS:	    Begin enumerating the entries in a table. The table
 *	    	    should not be modified while this is happening.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Pointer to first entry (or NULL if table empty).
 * SIDE EFFECTS:    Fields of the Table_Enum passed are filled in.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/10/89		Initial Revision
 *
 ***********************************************************************/
void *
Table_EnumFirst(Table	    table,
		Table_Enum  *te)
{
    TablePtr	    tp = (TablePtr)table;
    TableChunk	    *tcp;
    int	    	    i;

    TableVerify(tp);

    for (i = tp->numChunks, tcp = tp->chunks; i > 0; i--, tcp++) {
	if (tcp->numElts != 0) {
	    break;
	}
    }
    if (i == 0) {
	return((void *)NULL);
    }

    te->table = table;
    te->num = 	tcp->numElts-1;
    te->chunk = (void *)tcp;
    te->next = 	tcp->elts + tp->eltSize;

    return(tcp->elts);
}

/***********************************************************************
 *				Table_EnumNext
 ***********************************************************************
 * SYNOPSIS:	    Return the next element in a table.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The next element or NULL if none left.
 * SIDE EFFECTS:    Stuff in the Table_Enum is advanced
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/10/89		Initial Revision
 *
 ***********************************************************************/
void *
Table_EnumNext(Table_Enum   *te)
{
    TablePtr	tp = (TablePtr)te->table;
    TableChunk	*tcp = (TableChunk *)te->chunk;
    void    	*result;

    TableVerify(tp);

    /*
     * Advance to next non-empty chunk
     */
    while (te->num == 0) {
	if (++tcp == &tp->chunks[tp->numChunks]) {
	    /*
	     * At end of chunk table -- no more elements
	     */
	    return((void *)NULL);
	}
	/*
	 * Set up state block appropriately.
	 */
	te->num = tcp->numElts;
	te->next = tcp->elts;
	te->chunk = (void *)tcp;
    }

    result = te->next;
    /*
     * Advance pointers for next time.
     */
    te->next = (genptr)te->next + tp->eltSize;
    te->num -= 1;

    return(result);
}

/***********************************************************************
 *				Table_Fetch
 ***********************************************************************
 * SYNOPSIS:	    Extract elements from a table
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/17/89		Initial Revision
 *
 ***********************************************************************/
void
Table_Fetch(Table   table,  	/* Table from which to extract */
	    int	    numElts,	/* Number of elements */
	    void    *eltPtr,	/* Buffer to hold the elements */
	    int	    pos)    	/* Position from which to start the
				 * extraction */
{
    TablePtr	    tp = (TablePtr)table;
    int	    	    i;
    TableChunk	    *tcp;
    void    	    *ep;

    TableVerify(tp);

    for (i = tp->numChunks, tcp = tp->chunks; i > 0; i--, tcp++) {
	if (pos >= tcp->numElts) {
	    pos -= tcp->numElts;
	} else {
	    break;
	}
    }

    if (i == 0) {
	/*
	 * Elements not in the table, so return 0.
	 */
	bzero(eltPtr, SCALE(numElts,tp));
	return;
    }

    ep = tcp->elts + (pos * tp->eltSize);

    if (tcp->numElts - pos >= numElts) {
	/*
	 * All in this chunk -- just copy them into the buffer.
	 */
	bcopy(ep, eltPtr, SCALE(numElts,tp));
    } else {
	int 	j = tcp->numElts - pos;

	while (1) {
	    int	size = SCALE(j,tp);

	    /*
	     * Copy a bunch o' elements in
	     */
	    bcopy(ep, eltPtr, size);

	    /*
	     * Advance the buffer pointer and decrease the number of
	     * elements to account for newly-extracted elements
	     */
	    eltPtr = (genptr)eltPtr + size;
	    numElts -= j;

	    if (numElts > 0) {
		/*
		 * Advance to next chunk o' elements, setting j to be
		 * the number to copy next time.
		 */
		tcp++;
		i--;

		if (i == 0) {
		    /*
		     * Ran out of table chunks, so zero the remaining and
		     * break.
		     */
		    bzero(eltPtr, SCALE(numElts, tp));
		    break;
		}
		j = tcp->numElts;
		if (j > numElts) {
		    j = numElts;
		}
		ep = tcp->elts;
	    } else {
		/*
		 * All done...
		 */
		break;
	    }
	}
    }

    TableVerify(tp);
}
