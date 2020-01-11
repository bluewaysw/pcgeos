/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- Virtual Memory Emulation: file update
 * FILE:	  vmUpdate.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	VMUpdate    	    Write all dirty VM blocks to disk
 *	VMSwapHeader	    Byte-swap a VMHeader structure
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Synchronize a VM file with its in-core image
 *
 ***********************************************************************/

#include <config.h>
#include <compat/queue.h>
#include <compat/file.h>
#include <compat/string.h>
#include <search.h>
#include "vmInt.h"
#include "malloc.h"

#if !defined(_WIN32)
# define size_t	other_size_t
# define time_t	other_time_t
#endif

#include <sys/types.h>
#undef size_t
#undef time_t
#include <sys/stat.h>
# include <errno.h>

/*
 * Definitions for write-queueing. After running Esp a couple times, I
 * discovered that while it was spending less time doing its thing than
 * MASM, it was taking more elapsed time and almost twice as much system
 * time and performing ridiculously more output operations than were
 * necessary (about 100 times more than MASM was, e.g.). This is
 * caused by the (good) tendency to prefer many reasonable (read: 8K) blocks
 * to one big block whenever possible. Before, each block write would
 * cause a write() system call to be made. This is wasteful. Now, we
 * simply queue all the writes, ordering them by file position, so we
 * can write things as efficiently as possible.
 */
typedef struct _VMQueue {
    struct _VMQueue	*next;
    struct _VMQueue	*prev;
    int			fileOff;
    int			size;
    genptr		block;
} VMQueue;

static VMQueue	writeQueue = { &writeQueue, &writeQueue, -1, 0, 0 };
    

/***********************************************************************
 *				VMQueueWrite
 ***********************************************************************
 * SYNOPSIS:	    Queue a block for writing to the file.
 * CALLED BY:	    VMWriteBlock
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/14/89	Initial Revision
 *
 ***********************************************************************/
static void
VMQueueWrite(int    offset,
	     int    size,
	     genptr block)
{
    VMQueue 	*q;
    VMQueue 	*pred;

    q = (VMQueue *)malloc(sizeof(VMQueue));

    q->fileOff = offset;
    q->size = size;
    q->block = block;

    for (pred = writeQueue.prev;
	 pred != &writeQueue && pred->fileOff > offset;
	 pred = pred->prev)
    {
	;
    }
    insque((struct qelem*) q, (struct qelem*) pred);
}


/***********************************************************************
 *				VMFlushWrites
 ***********************************************************************
 * SYNOPSIS:	    Flush pending writes to a file.
 * CALLED BY:	    VMUpdate
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/14/89	Initial Revision
 *
 ***********************************************************************/
static void
VMFlushWrites(VMFilePtr	    file)
{
    genptr	buf;
    int	    	inbuf;
    /* struct stat	stb; */
    VMQueue 	*q, *nq;
    int	    	offset;
    int	    	blksize = 2048;	/* assume 2048, unless we can
				 * find out more in a particular
 				 * OS */
    /* int	    	fstatResult; */
    long    	bytesWritten = 0;

#if 0
    /*
     * file->fd is now a FILE *, and fstat doesn't work.
     * We can just use the default of 2048.
     */
    /*
     * Figure the "optimal" block size for the file and allocate a buffer
     * that big.
     */
#if defined(unix)
    fstatResult = fstat(file->fd, &stb);
    assert(fstatResult == 0);
    blksize = stb.st_blksize;
#elif defined(_MSDOS)
    /* hard-disks typically have 2K clusters... */
    blksize = 2048;
#endif
#endif /* 0 */

    buf = (genptr)malloc(blksize);

    /*
     * Buffer is initially empty and file offset is 0 to force an initial
     * seek.
     */
    inbuf = 0;
    offset = 0;

    for (q = writeQueue.next; q != &writeQueue; q = nq) {
	if (offset != q->fileOff) {
	    /*
	     * Discontinuity in the queue. If any data stored in the
	     * write buffer, flush it to the file, then seek to this block's
	     * file position and record that as the most-recent offset.
	     */
	    if (inbuf != 0) {
		FileUtil_Write(file->fd, buf, inbuf, &bytesWritten);
		inbuf = 0;
	    }
	    FileUtil_Seek(file->fd, ((file->flags & VM_2_0) ?
				     q->fileOff + sizeof(GeosFileHeader2) :
				     q->fileOff), SEEK_SET);
	    offset = q->fileOff;
	} else if (inbuf != 0) {
	    /*
	     * Data left in the write buffer. If this block too small
	     * to fill the buffer, copy in what we can and update inbuf and
	     * offset accordingly.
	     */
	    if (inbuf + q->size < blksize) {
		memcpy(buf+inbuf, q->block, q->size);
		inbuf += q->size;
		offset += q->size;
		q->size = 0;
	    } else {
		/*
		 * Else, fill the buffer to its limit, updating the recorded
		 * size and address, the most-recent offset and the number
		 * of bytes in the buffer to account for the data copied into
		 * it, then write the buffer to disk.
		 */
		int n = blksize - inbuf;

		memcpy(buf+inbuf, q->block, n);
		q->size -= n;
		q->block += n;
		offset += n;

		FileUtil_Write(file->fd, buf, blksize, &bytesWritten);
		inbuf = 0;
	    }
	}

	/*
	 * Write out as many blksize blocks as possible from the current block
	 * at once. Total bytes to write tracked in "size".
	 */
	if (q->size >= blksize) {
	    int	    size = 0;

	    while(q->size >= blksize) {
		size += blksize;
		q->size -= blksize;
	    }
	    FileUtil_Write(file->fd, q->block, size, &bytesWritten);
	    q->block += size;
	    offset += size;
	}

	if (q->size != 0) {
	    /*
	     * Data left in the block -- copy it into the write buffer and
	     * record the amount, updating the offset to account for the
	     * data "written".
	     */
	    bcopy(q->block, buf, q->size);
	    inbuf = q->size;
	    offset += q->size;
	}

	/*
	 * Remove the block from the queue and free its record.
	 */
	nq = q->next;
	remque((struct qelem*) q);
	free((void*) q);
    }

    /*
     * If any data remaining in the write buffer, flush it to disk now.
     */
    if (inbuf != 0) {
	FileUtil_Write(file->fd, buf, inbuf, &bytesWritten);
    }

    /*
     * Release the write buffer...
     */
    free(buf);
}
		
	
    
    
#ifdef SWAP

/***********************************************************************
 *				VMSwapHeader
 ***********************************************************************
 * SYNOPSIS:	    Byte-swap a VM header
 * CALLED BY:	    VMOpen, VMClose
 * RETURN:	    Nothing
 * SIDE EFFECTS:    All the fields are byte-swapped
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/18/89		Initial Revision
 *
 ***********************************************************************/
void
VMSwapHeader(VMHeader	*hdr, word size)
{
    VMBlock 	*blk;	    /* Block handle being swapped */
    int	    	i;  	    /* Count of blocks left to swap */
    byte    	*cp, t;	    /* Pointer and temp for swapping */

    /*
     * First all the word-sized fields
     */
    cp = (byte *)hdr;
    while (cp < (byte *)&hdr->VMH_usedSize) {
	t = *cp++;
	cp[-1] = *cp;
	*cp++ = t;
    }
    hdr->VMH_dbMapBlock = swapword(hdr->VMH_dbMapBlock);

    /*
     * Now the filesize field (only dword field around)
     */
    hdr->VMH_usedSize = swapdword(hdr->VMH_usedSize);

    /*
     * Figure the number of handles in the table.
     */
    i = (size - VMH_BT_OFF)/sizeof(VMBlock);

    /*
     * Byte-swap all the handles
     */
    for (blk = hdr->VMH_blockTable; i > 0; blk++, i--) {
	if (VM_IN_USE(blk)) {
	    /*
	     * First the word-sized fields
	     */
	    blk->VMB_memHandle = swapword(blk->VMB_memHandle);
	    blk->VMB_uid = swapword(blk->VMB_uid);
	    blk->VMB_size = swapword(blk->VMB_size);

	    /*
	     * Then the position (only dword field in the thing)
	     */
	    blk->VMB_pos = swapdword(blk->VMB_pos);
	} else {
	    blk->VMB_free.VMBF_nextPtr = swapword(blk->VMB_free.VMBF_nextPtr);
	    blk->VMB_free.VMBF_prevPtr = swapword(blk->VMB_free.VMBF_prevPtr);
	    blk->VMB_free.VMBF_size = swapdword(blk->VMB_free.VMBF_size);
	    blk->VMB_free.VMBF_pos = swapdword(blk->VMB_free.VMBF_pos);
	}
    }
}

#endif /* SWAP */

/***********************************************************************
 *				VMWriteBlock
 ***********************************************************************
 * SYNOPSIS:	    Flush a block out to disk
 * CALLED BY:	    VMUpdate
 * RETURN:	    1 if successful
 * SIDE EFFECTS:    The block's signature is set back to VM_USED_BLK_SIG.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/28/89		Initial Revision
 *
 ***********************************************************************/
int
VMWriteBlock(VMFilePtr	file,	    /* File to which block belongs */
	     VMBlock	*block)	    /* Block to write */
{
    word   	size;	    /* Current size of the memory block */
    genptr	addr;	    /* Where the block is located in memory */
    VMHeader	*hdr;	    /* File header */

    VMBlockHandle blockH;
    int	    	doSwap=0;

    hdr = file->blkHdr;
    
#ifdef SWAP
    doSwap = (block == hdr->VMH_blockTable);
#endif

    MemInfo(block->VMB_memHandle, (genptr *)&addr, &size);
    
    if (block->VMB_pos == 0) {
	/*
	 * Room not yet allocated for the block in the file. Do so now.
	 */
	block->VMB_pos = VMFileAlloc(file, size);
    } else if (block->VMB_size > size) {
	/*
	 * Block shrank -- release the extra space back to the file.
	 * VMFileFree can move the header...
	 */
	blockH = VM_BLOCK_TO_HANDLE(block, hdr);
	VMFileFree(file, block->VMB_pos + size, block->VMB_size - size);
	hdr = file->blkHdr;
	block = VM_HANDLE_TO_BLOCK(blockH, hdr);

    } else {
	/*
	 * Need to get more file space. First see if there's an assigned
	 * block of the proper size immediately following or preceding the
	 * current region.
	 */
	VMBlock	    	*cur;	    /* Assigned block being examined */
	dword	    	pos;	    /* Position after 'block' */
	int 	    	diff;	    /* Size difference between mem and file */
	VMBlockHandle	*prevPtr;   /* Address of link to cur */

	/*
	 * Figure loop-invariants...
	 */
	pos = block->VMB_pos + block->VMB_size;
	diff = size - block->VMB_size;
	
	/*
	 * Look for an appropriate block
	 */
	for (prevPtr = &hdr->VMH_assigned,
	     cur = VM_HANDLE_TO_BLOCK(hdr->VMH_assigned,hdr);

	     cur != VM_NULL(file);

	     prevPtr = &cur->VMB_nextPtr,
	     cur = VM_HANDLE_TO_BLOCK(cur->VMB_nextPtr,hdr))
	{
	    if (cur->VMB_pos >= pos) {
		/*
		 * Passed the old space...
		 */
		break;
	    } else if ((cur->VMB_pos+cur->VMB_size == block->VMB_pos) &&
		       (cur->VMB_size >= diff))
	    {
		/*
		 * The one before has enough room...
		 */
		break;
	    }
	}

	if ((cur != VM_NULL(file)) && (cur->VMB_pos == pos) &&
	    (cur->VMB_size >= diff))
	{
	    /*
	     * There's a block on the list after the current one with
	     * enough room for the allocation -- shrink that block and
	     * give the required space to the current one.
	     */
	    cur->VMB_pos += diff;
	    cur->VMB_size -= diff;

	    block->VMB_size += diff;
	} else if (cur != VM_NULL(file)) {
	    /*
	     * Must have found a block before the current one that will hold
	     * the difference. Shrink the thing by the amount needed. If
	     * size goes to zero, put the block on the unassigned list.
	     */
	    cur->VMB_size -= diff;
	    block->VMB_pos -= diff;

	    if (cur->VMB_size == 0) {
		/*
		 * Nothing left -- unlink and place on unassigned list.
		 */
		*prevPtr = cur->VMB_nextPtr;
		hdr->VMH_numAssigned -= 1;

		hdr->VMH_numUnassigned += 1;
		cur->VMB_nextPtr = hdr->VMH_unassigned;
		hdr->VMH_unassigned = VM_BLOCK_TO_HANDLE(cur,hdr);
	    }
	} else {
	    /*
	     * Nothing there. Need to release the space we have now and
	     * get a larger area.
	     */
	    blockH = VM_BLOCK_TO_HANDLE(block, hdr);

	    VMFileFree(file, block->VMB_pos, block->VMB_size);

	    hdr = file->blkHdr;
	    block = VM_HANDLE_TO_BLOCK(blockH, hdr);

	    block->VMB_pos = VMFileAlloc(file, size);
	}
    }

    /*
     * Whatever was done above, we now have 'size' bytes of space in the file.
     */
    block->VMB_size = size;

    assert(block->VMB_pos != 0);
    
    /*
     * Reset the signature and reduce the file's dirty-block count now, before
     * writing the block to disk, in case the block is the header...
     */
    block->VMB_sig = VM_USED_BLK_SIG;

    if (!doSwap) {
	/*
	 * Not header block or header doesn't need swapping, so queue
	 * the thing for writing once all blocks have been cleansed.
	 */
	VMQueueWrite(block->VMB_pos, block->VMB_size, addr);
    } else {
#ifdef SWAP
	/*
	 * Seek to allocated position
	 */
	if (FileUtil_Seek(file->fd, 
			  ((file->flags & VM_2_0) ?
			   block->VMB_pos + sizeof(GeosFileHeader2) :
			   block->VMB_pos),
			  SEEK_SET) == -1L)
	{
	    /*
	     * Couldn't get there -- mark the block as still dirty
	     * and return 0 to signal error.
	     */
	    block->VMB_sig = VM_DIRTY_BLK_SIG;
	    return 0;
	}

	/*
	 * Swap it now we don't need any info from the thing
	 */
	VMSwapHeader(file->blkHdr, size);

	/*
	 * Write the data out.
	 */
	{
		int         bytesWritten = 0;
		FileUtil_Write(file->fd, addr, size, &bytesWritten);
		if (bytesWritten < size) {
			/*
			 * No room on device? Mark the block as still dirty and return 0
			 * to signal error.
			 *
			 * XXX: Release file space?
			 */
			/*
			 * Swap header back, if necessary.
			 */
			VMSwapHeader(file->blkHdr, size);
			block->VMB_sig = VM_DIRTY_BLK_SIG;
			return 0;
		}
	}

	/*
	 * Swap header back, if necessary.
	 */
	VMSwapHeader(file->blkHdr, size);
#endif /* SWAP */
    }

    return(1);
}
		



/***********************************************************************
 *				VMUpdate
 ***********************************************************************
 * SYNOPSIS:	    Write all dirty blocks for a file to disk.
 * CALLED BY:	    VMClose, EXTERNAL
 * RETURN:	    0 if successful, error code if not
 * SIDE EFFECTS:    All dirty blocks are written and their signatures
 *	    	    changed back to VM_USED_BLK_SIG.
 *	    	    The file could very well (is likely to) be extended.
 *
 * STRATEGY:
 *	For all blocks but the header:
 *	    - if block is dirty (signature is VM_DIRTY_BLK_SIG),
 *	      call VMWriteBlock to flush the block to disk
 *	If header dirty (signature is VM_DIRTY_BLK_SIG), flush it
 *	to disk.
 *	Update the file header.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/28/89		Initial Revision
 *
 ***********************************************************************/
int
VMUpdate(VMHandle   vmHandle)
{
    VMFilePtr	    file = (VMFilePtr)vmHandle;
    VMBlock 	    *block; 	/* Current block */
    VMBlock 	    *last;  	/* Block after last used */
    VMHeader	    *hdr;   	/* Header for file */
    VMBlockHandle    blockH;
    long 	    bytesWritten = 0;
    
    hdr = file->blkHdr;

    /*
     * Locate all dirty blocks and flush them to disk. We needn't mark
     * the header dirty after flushing a block, even though the block's
     * signature has changed, since the header must already be dirty or
     * the block's signature couldn't have changed from USED to DIRTY...
     * Note we start at VMH_blockTable[1], not 0, since 0 is the header
     * block and must remain in-core until all dirty blocks have been
     * made clean again.
     */
    /* Also note the VMWriteBlock can move the header block */

    last = VM_LAST(file);
    for (block = &hdr->VMH_blockTable[1]; block < last; block++)
    {
	if (block->VMB_sig == VM_DIRTY_BLK_SIG)
	{
	    blockH = VM_BLOCK_TO_HANDLE(block, hdr);

	    if (!VMWriteBlock(file, block))
	    {
		return FileUtil_GetError();
	    }
	    
	    /* re-dereferencing everything, assuming hdr moved */

	    hdr = file->blkHdr;
	    block = VM_HANDLE_TO_BLOCK(blockH, hdr);
	    last = VM_LAST(file);
	}
    }

    if (file->flags & VM_SHRINK_HDR) {
	/*
	 * If the header was allocated huge before, truncate it at the first
	 * unassigned block in the last block of unassigned handles.
	 */
	VMBlockHandle	newSize, *uPtr;
	short 	    	numUnassigned;
	VMBlockHandle	headerHandle;

	file->flags &= ~VM_SHRINK_HDR;

	/*
	 * Locate the first handle that's in-use or has file space. That's the
	 * last block handle we need to preserve.
	 */
	for (block = last-1; block > &hdr->VMH_blockTable[0]; block--) {
	    if (VM_IN_USE(block) || block->VMB_free.VMBF_size != 0) {
		break;
	    }
	}
	/*
	 * set "barrier" to be the size of the truncated header.
	 */
	newSize = VM_BLOCK_TO_HANDLE(block, hdr) + sizeof(VMBlock);

	/*
	 * Now run down the chain of unassigned blocks, removing those
	 * that point beyond the edge of the new header.
	 */
	numUnassigned = 0;
	uPtr = &hdr->VMH_unassigned;
	while (*uPtr != 0) {
	    VMBlock *cur;

	    cur = VM_HANDLE_TO_BLOCK(*uPtr, hdr);
	    
	    if (*uPtr >= newSize) {
		*uPtr = cur->VMB_nextPtr;
	    } else {
		uPtr=&cur->VMB_nextPtr;
		numUnassigned += 1;
	    }
	}

	/*
	 * Now adjust the header accordingly:
	 *  VMH_numUnassigned <- remaining number of unassigned handles
	 *  VMH_blockTable[0].VMB_size <- new header size
	 *  VMH_blockTable[0].VMB_sig <- dirty
	 *  VMH_lastHandle <- new header size.
	 */
	hdr->VMH_numUnassigned = numUnassigned;

	headerHandle = hdr->VMH_blockTable[0].VMB_memHandle;
	MemReAlloc(headerHandle, newSize, 0);
	MemInfo(headerHandle, (genptr *)&file->blkHdr, (word *)NULL);
	hdr = file->blkHdr;

	hdr->VMH_lastHandle = newSize;
	hdr->VMH_blockTable[0].VMB_sig = VM_DIRTY_BLK_SIG;
	hdr->VMH_blockTable[0].VMB_size = newSize;
    }
    
    if (hdr->VMH_blockTable[0].VMB_sig == VM_DIRTY_BLK_SIG) {
	/*
	 * Header dirty -- write it out. Before doing this, we need
	 * to link all the assigned blocks in their reverse order, since
	 * PC/GEOS likes to have the list doubly-linked...
	 *
	 * prevID holds the handle ID of the previous element in the list.
	 * When the loop runs off the end, prevID holds the ID of the
	 * last element in the list.
	 *
	 * The termination condition for the loop is block == file->blkHdr
	 * b/c the nextPtr of the final block is 0, leading
	 * VM_HANDLE_TO_BLOCK to give us block pointing 0 bytes from
	 * file->blkHdr...
	 */
	word	    	prevID;

	prevID = 0;
	for (block = VM_HANDLE_TO_BLOCK(hdr->VMH_assigned, hdr);
	     block != VM_NULL(file);
	     block = VM_HANDLE_TO_BLOCK(block->VMB_nextPtr, hdr))
	{
	    block->VMB_prevPtr = prevID;
	    prevID = VM_BLOCK_TO_HANDLE(block,hdr);
	}
	/*
	 * Stuff the ID of the last element in now we know it.
	 */
	hdr->VMH_lastAssigned = prevID;
	
	block = hdr->VMH_blockTable;
	if (!VMWriteBlock(file, block)) {
	    return FileUtil_GetError();
	}

        /* re-deref block, hdr */
 
        hdr = file->blkHdr;
        block = hdr->VMH_blockTable;

	VMFlushWrites(file);

	/*
	 * Now need to write out the file header with the correct
	 * position for the header block. The position is stored in the
	 * first block handle...
	 */
	if (FileUtil_Seek(file->fd, 0L, SEEK_SET) == -1) {
	    return FileUtil_GetError();
	}
	if (file->flags & VM_2_0) {
	    file->fileHdr.v2.VMFH_headerPos = swapdword(block->VMB_pos);
	    file->fileHdr.v2.VMFH_headerSize = swapword(block->VMB_size);
	    file->fileHdr.v2.VMFH_signature = swapword(VMFH_SIG);
	    FileUtil_Write(file->fd,
			   (const void *)&file->fileHdr.v2,
			   sizeof(file->fileHdr.v2),
			   &bytesWritten);
	    if (bytesWritten != sizeof(file->fileHdr.v2))
	    {
		return FileUtil_GetError();
	    }
	} else {
	    file->fileHdr.v1.VMFH_headerPos = swapdword(block->VMB_pos);
	    file->fileHdr.v1.VMFH_headerSize = swapword(block->VMB_size);
	    file->fileHdr.v1.VMFH_signature = swapword(VMFH_SIG);
	    FileUtil_Write(file->fd,
			   (const void *)&file->fileHdr.v1,
			   sizeof(file->fileHdr.v1),
			   &bytesWritten);
	    if (bytesWritten != sizeof(file->fileHdr.v1))
	    {
		return FileUtil_GetError();
	    }
	}
    }
    /*
     * Seek to the current size of the file to make sure the system knows
     * how big the thing is supposed to be.
     */
    FileUtil_Seek(file->fd, file->fsize, SEEK_SET);

    return(0);
}
