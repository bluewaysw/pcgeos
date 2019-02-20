/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Patient-dependent module: data cache
 * FILE:	  ibmCache.c
 *
 * AUTHOR:  	  Adam de Boor: May 18, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Ibm_ReadBytes	    Read bytes from the patient, handle-relative or
 *	    	    	    absolute.
 *	Ibm_WriteBytes	    Write bytes to the patient, handle-relative or
 *	    	    	    absolute.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/18/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions implementing the data cache
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: ibmCache.c,v 4.18 97/04/18 15:57:55 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cache.h"
#include "cmd.h"
#include "ibmInt.h"
#include "rpc.h"
#include "ui.h"
#include <compat/stdlib.h>
#include <errno.h>

#if defined(unix)
#include <sys/file.h>
#else
#include <io.h>
#define L_SET	SEEK_SET
#define L_INCR	SEEK_CUR
#define L_XTND	SEEK_END
#endif

/*
 * Statistics for optimizing the cache.
 */
int  	bytesFromPC;	    	    /* Total number of bytes read from
				     * the PC */
int  	bytesFromCache;     	    /* Number of bytes read from the cache */
int  	bytesToPC;	    	    /* Total number of bytes written to
				     * the PC */
int  	bytesToCache;	    	    /* Number of bytes written into the cache*/
int  	cacheRefs;	    	    /* Number of times the cache was
				     * examined */
int  	cacheHits;	    	    /* Number of times the block was found
				     * in the cache. */

#define CACHE_BLOCK_SIZE    32	    /* Default size of each cache block */
#define CACHE_LENGTH	    64	    /* Default number of blocks in the cache */

int  	cacheBlockSize;     	    /* Current size of blocks to be cached.
				     * may only be changed when Cache_Size is
				     * 0 */
Cache   dataCache;	    	    /* Cached blocks */

Boolean	cacheOn = TRUE;


/***********************************************************************
 *				IbmDecomposeAddress
 ***********************************************************************
 * SYNOPSIS:	    Break a 32-bit linear address into its segment:offset
 *	    	    components, dealing with the funky addressing of
 *	    	    things above 1Mb
 * CALLED BY:	    INTERNAL
 * RETURN:	    the segment & offset
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/13/91	Initial Revision
 *
 ***********************************************************************/
static void
IbmDecomposeAddress(Address 	addr,
		    word    	*segmentPtr,
		    word    	*offsetPtr)
{
#if GEOS32
    *segmentPtr = SegmentOf(addr) ;
    *offsetPtr = OffsetOf(addr) ;
#else
    if ((addr > (Address)0xfffff) && (addr < (Address)(0xffff0 + 0xffff)))
    {
	/*
	 * Special case access > 1Mb (for high-loaded DOS and other things)
	 */
	*segmentPtr = 0xffff;
	*offsetPtr = addr - (Address)0xffff0;
    } else {
	*segmentPtr = ((dword)addr & 0xffff0) >> 4;
	*offsetPtr = (dword)addr & 0xf;
    }
#endif
}
    

/***********************************************************************
 *				IbmCacheInterestProc
 ***********************************************************************
 * SYNOPSIS:	    Take note of a change in the status of a handle the
 *		    contents of which we've cached.
 * CALLED BY:	    Handle module
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    This exists for two purposes (1) to make sure the
 *	    	    handle structure remains valid until we can write
 *	    	    the data back (XXX: this may no longer be pertinent,
 *		    since we no longer destroy handles on continue), and
 *	    	    (2) to cope with core blocks being freed after the
 *		    user ignores a patient, but while there's data in
 *		    the cache.
 *	    	    we need to give something to call to Handle_Interest
 *
 *	    	    This puppy can be called, e.g., due to a breakpoint
 *	    	    in a resource handle (since the Break module comes
 *	    	    first in the interest list, it writes the breakpoint
 *	    	    instruction out, which causes us to be added to the
 *	    	    interest list and be called next) when the patient
 *	    	    is resurrected.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/8/89		Initial Revision
 *
 ***********************************************************************/
static void
IbmCacheInterestProc(Handle handle, Handle_Status status, Opaque clientData)
{
    Cache_Entry	entry = (Cache_Entry)clientData;

    /*
     * If handle's being freed, flush the entry from the cache.
     */
    if (status == HANDLE_FREE) {
	if (malloc_tag(Cache_GetValue(entry)) == TAG_DCBLOCK) {
	    Warning("Handle %04xh freed before cached data could be written",
		    Handle_ID(handle));
	}
	Cache_InvalidateOne(dataCache, entry);
    }
}


/***********************************************************************
 *				IbmFindBlock
 ***********************************************************************
 * SYNOPSIS:	  Find a block in the cache.
 * CALLED BY:	  IbmReadBytes, IbmWriteBytes
 * RETURN:	  The address of the data in our memory or NULL if the
 *	    	  block couldn't be obtained.
 * SIDE EFFECTS:  A block may be thrown out of the cache. keyPtr->offset
 *	is adjusted to the offset of the start of the block returned.
 *
 * STRATEGY:
 *	The blocks in the cache are keyed on a <handle,offset> pair,
 *	where "offset" is always aligned on a cacheBlockSize boundary
 *	to avoid problems with overlapping blocks. While this will lose if
 *	someone wants two bytes straddling such a boundary, it's easy to
 *	do.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/13/88		Initial Revision
 *
 ***********************************************************************/
static genptr
IbmFindBlock(IbmKey	    *keyPtr,	/* Key under which to look/enter */
	     Cache_Entry    *entryPtr)	/* Place to store entry for block
					 * if desired. */
{
    genptr 	  	block;	    	/* Block found/read */
    Cache_Entry		entry;

    assert(VALIDTPTR(keyPtr->handle, TAG_HANDLE) || keyPtr->handle==NULL);
    
    /*
     * Set up the address of the block to be read -- round down to start of
     * block containing the offset.
     */
/* MessageFlush("keyPtr->offset = %d\n", (word)keyPtr->offset); */
    keyPtr->offset = ((int)keyPtr->offset) & ~(cacheBlockSize-1);

    /*
     * See if it's in the cache and note another cache reference
     */
    cacheRefs++;
    entry = Cache_Lookup(dataCache, (Address)keyPtr);

    if (entry == NullEntry) {
	Boolean	new;

	block = (genptr)malloc_tagged(cacheBlockSize, TAG_CBLOCK);

        /* Clear with CC's */
        memset(block, 0xCC, cacheBlockSize) ;

	if (keyPtr->handle != NullHandle) {
	    /*
	     * Need to read the data from the host in a handle-relative way.
	     * Note that if the handle is marked as discarded, it can't be
	     * read. Alternative action must then be taken.
	     */
	    int	    	state = Handle_State(keyPtr->handle);

	    if (state & HANDLE_DISCARDED) {
		if (state & (HANDLE_KERNEL|HANDLE_RESOURCE)) {
		    /*
		     * Discarded, but we can fetch the data from the object
		     * file.
		     *
		     * XXX: What about relocation?
		     */
		    Patient 	patient = Handle_Patient(keyPtr->handle);
     		    ResourcePtr rp;
		    int 	i;
		    
		    /*
		     * Find the resource descriptor for the handle
		     */
		    for (i = patient->numRes, rp = patient->resources;
			 i > 0;
			 i--, rp++)
		    {
			if (rp->handle == keyPtr->handle) {
			    break;
			}
		    }
		    
		    assert(i > 0);
		    
		    /*
		     * Seek to the right place in the object file
		     * and read the data.
		     */
		    IbmEnsureObject(patient);
/* MessageFlush("rp->offset = %d and keyPtr->offset = %d\n",  
	     	    	    (word)rp->offset, (word)keyPtr->offset);
*/
		    if (Ibm_ReadFromObjectFile(patient, (word)cacheBlockSize,
					(dword)(rp->offset+keyPtr->offset),
					block, L_SET,
			      	    	GEODE_DATA_NORMAL, 
					Handle_ID(keyPtr->handle),
					(word)rp->offset) == TCL_ERROR)
	            {
		    	return ((genptr)NULL);
		    }
		} else {
		    Warning("Handle %04xh discarded",
			    Handle_ID(keyPtr->handle));
		    return((genptr)NULL);
		}
	    } else if (state & HANDLE_KERNEL) {
		/*
		 * If it's a kernel segment, we have to turn it into an
		 * absolute read since the handle ID's are bogus.
		 */
		AbsReadArgs	ara;
		
		ara.ara_segment = Handle_Segment(keyPtr->handle);
		ara.ara_offset = (word)keyPtr->offset;
		ara.ara_numBytes = cacheBlockSize;
		
		if (Rpc_Call(RPC_READ_ABS,
			     sizeof(AbsReadArgs), typeAbsReadArgs, &ara,
			     cacheBlockSize, NullType, block))
		{
		    free((malloc_t)block);
		    Warning("Couldn't read from kernel: %s",
			    Rpc_LastError());
		    return((genptr)NULL);
		}
		bytesFromPC += cacheBlockSize;
	    } else {
		ReadArgs    ra;

		/*XXX*/
		IbmCheckPatient(Handle_Patient(keyPtr->handle));

		ra.ra_handle = Handle_ID(keyPtr->handle);
		ra.ra_offset = (word)keyPtr->offset;
		ra.ra_numBytes = cacheBlockSize;

		if (Rpc_Call(RPC_READ_MEM,
			     sizeof(ReadArgs), typeReadArgs, (Opaque)&ra,
			     cacheBlockSize, NullType, block))
		{
		    free((malloc_t)block);
		    Warning("Couldn't read block from ^h%04xh:%04xh: %s",
			    Handle_ID(keyPtr->handle), keyPtr->offset,
			    Rpc_LastError());
		    return((genptr)NULL);
		}
		bytesFromPC += cacheBlockSize;
	    }
	} else {
	    AbsReadArgs ara;

	    IbmDecomposeAddress(keyPtr->offset,
				&ara.ara_segment,
				&ara.ara_offset);
	    ara.ara_numBytes = cacheBlockSize;

	    if (Rpc_Call(RPC_READ_ABS,
			 sizeof(AbsReadArgs), typeAbsReadArgs, &ara,
			 cacheBlockSize, NullType, block))
	    {
		free((malloc_t)block);
		Warning("Couldn't read from absolute mem %04xh:%04xh %s",
			swaps(ara.ara_segment),
			swaps(ara.ara_offset),
			Rpc_LastError());
		return((genptr)NULL);
	    }
	    bytesFromPC += cacheBlockSize;
	}
	entry = Cache_Enter(dataCache, (Address)keyPtr, &new);
	assert(new);
	Cache_SetValue(entry, (Opaque)block);

	/*
	 * Make sure we get told if this handle gets freed.
	 */
	if (keyPtr->handle != NullHandle) {
	    Handle_Interest(keyPtr->handle, IbmCacheInterestProc,
			    (Opaque)entry);
	}
    } else {
	/*
	 * Found the block already in the cache -- use it.
	 */
	cacheHits++;

	block = (genptr)Cache_GetValue(entry);
    }

    if (entryPtr != (Cache_Entry *)NULL) {
	*entryPtr = entry;
    }

    return(block);
}



/***********************************************************************
 *				IbmFreeBlock
 ***********************************************************************
 * SYNOPSIS:	  Throw out a block in the cache
 * CALLED BY:	  Cache_Enter, Cache_Destroy
 * RETURN:	  Nothing
 * SIDE EFFECTS:  If the block is dirty, its contents are written out.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/13/88		Initial Revision
 *
 ***********************************************************************/
static void
IbmFreeBlock(Cache  	    cache,
	     Cache_Entry    entry)	    	/* Entry to throw out */
{
    genptr 	  	block;	    	/* Block to be nuked */
    IbmKey	    	*keyPtr = (IbmKey *)entry->key.words;

    block = (genptr)Cache_GetValue(entry);

    if (malloc_tag(block) == TAG_DCBLOCK) {
	if (keyPtr->handle != NullHandle) {
	    int	    	state;

	    state = Handle_State(keyPtr->handle);

	    if (state & HANDLE_DISCARDED) {
		if (Handle_ID(keyPtr->handle) != HID_SWAT) {
		    Warning("Data for discarded handle %04xh not written",
			    Handle_ID(keyPtr->handle));
		}
	    } else if (state & HANDLE_KERNEL) {
		/*
		 * Writes to kernel memory are always absolute, since the
		 * kernel has no handle by which it can refer to itself
		 */
		keyPtr->offset += (dword)Handle_Address(keyPtr->handle);
		goto flush_absolute;
	    } else {
		WriteArgs	*wa; /* Args for the memory write. The
				      * handle,offset pair comes first with
				      * the data bytes following after */
	    
		wa = (WriteArgs *)malloc(sizeof(WriteArgs) + cacheBlockSize);
	    
		/*XXX*/
		IbmCheckPatient(Handle_Patient(keyPtr->handle));

		wa->wa_handle = Handle_ID(keyPtr->handle);
		wa->wa_offset = (unsigned short)keyPtr->offset;
		bcopy(block, (genptr)&wa[1], cacheBlockSize);
	    
		if (Rpc_Call(RPC_WRITE_MEM,
			     sizeof(WriteArgs)+cacheBlockSize, typeWriteArgs,
			     wa,
			     0, NullType, (Opaque)0) != RPC_SUCCESS)
		{
		    Warning("Unable to flush block ^h%04xh:%04xh: %s",
			    wa->wa_handle, wa->wa_offset, Rpc_LastError());
		} else {
		    bytesToPC += cacheBlockSize;
		}
		free((malloc_t)wa);
	    }
	} else {
	    AbsWriteArgs    *awa;   /* Args for an absolute write. */
	    
	flush_absolute:
	    awa = (AbsWriteArgs *)malloc(sizeof(AbsWriteArgs)+cacheBlockSize);
	    IbmDecomposeAddress(keyPtr->offset,
				&awa->awa_segment,
				&awa->awa_offset);
	    bcopy(block, (genptr)&awa[1], cacheBlockSize);
	    
	    if (Rpc_Call(RPC_WRITE_ABS,
			 sizeof(AbsWriteArgs)+cacheBlockSize, typeAbsWriteArgs,
			 awa,
			 0, NullType, (Opaque)0) != RPC_SUCCESS)
	    {
		Warning("Unable to flush absolute block %xh: %s",
			keyPtr->offset, Rpc_LastError());
	    } else {
		bytesToPC += cacheBlockSize;
	    }
	    free((malloc_t)awa);
	}
    }

    if (keyPtr->handle != NullHandle) {
	/*
	 * Express our supreme lack of further interest in this handle.
	 */
	Handle_NoInterest(keyPtr->handle, IbmCacheInterestProc,
			  (Opaque)entry);
    }

    free((malloc_t)block);
}


/***********************************************************************
 *				Ibm_ReadBytes
 ***********************************************************************
 * SYNOPSIS:	  Read bytes from the patient's address space.
 * CALLED BY:	  GLOBAL
 * RETURN:	  The number of bytes read.
 * SIDE EFFECTS:  Old data may be flushed from the cache.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/12/88		Initial Revision
 *
 ***********************************************************************/
int
Ibm_ReadBytes(int    	numBytes,   	/* Number of bytes to read */
	     Handle 	handle,	    	/* Handle to data or NullHandle if read
					 * should be absolute */
	     Address	patientAddress,	/* Offset into block or absolute
					 * address from which to read */
	     genptr	swatAddress)	/* Address at which read data should be
					 * stored. */
{
    IbmKey  	  	key;	    	/* Key used for lookup */
    int			numRead;    	/* Number of bytes read so far */
    genptr		block;	    	/* Block from which to fetch data */
    int	    	  	i;  	    	/* Number of bytes from block to read*/
    Cache_Entry	    	entry;	    	/* Entry for flushing */

    /* Setup the memory we are about to receive to be CC'd so if we */
    /* don't get what we are looking for, it will appear not there */
    memset(swatAddress, 0xCC, numBytes) ;

    if (cacheOn && ((sysFlags & PATIENT_RUNNING)==0)) {
	/*
	 * Install the handle -- this never changes
	 */
	key.handle = handle;
	
	numRead = 0;
	
	while(numBytes != 0 && !Ui_CheckInterrupt()) {
	    if (handle != NullHandle && patientAddress >= (Address)65536) {
		/*
		 * If the address is beyond the 64k that can be in a handle,
		 * convert the beast to absolute so we get the right data.
		 */
		patientAddress += MakeAddress(Handle_Segment(handle), 0);
		key.handle = handle = NullHandle;
	    }
	    
	    key.offset = patientAddress;
	    block = IbmFindBlock(&key, &entry);
	    
	    if (block == (genptr)NULL) {
		break;
	    }
	    
	    /*
	     * Figure the number of bytes to copy from the block
	     */
	    i = cacheBlockSize - (patientAddress - key.offset);
	    if (i > numBytes) {
		i = numBytes;
	    }
	    
	    bcopy(block + (patientAddress - key.offset),
		  (void *)swatAddress,
		  i);
	    
	    /*
	     * Update the various counters and statistics and pointers
	     */
	    swatAddress     += i;	/* Data sink */
	    numRead   	    += i;	/* Return value counter */
	    numBytes	    -= i;	/* Loop counter */
	    bytesFromCache  += i;	/* Statistics */
	    patientAddress  += i;	/* Data source */
	    /*
	     * If patient actually running, flush the block right away
	     */
	    if (sysFlags & PATIENT_RUNNING) {
		Cache_InvalidateOne(dataCache, entry);
	    }
	}
    } else {
	/*
	 * Cache inactive -- we get to do the reading ourselves...
	 * We take advantage of the similarities between the
	 * AbsReadArgs and ReadArgs structures to have a single
	 * read loop...
	 */
	word	    segment, offset;
	Rpc_Proc    procNum;
	
	
	if (handle != NullHandle) {
	    int	    state = Handle_State(handle);

	    if (state & HANDLE_DISCARDED) {
		if (state & (HANDLE_KERNEL|HANDLE_RESOURCE)) {
		    /*
		     * Discarded, but we can fetch the data from the object
		     * file.
		     *
		     * XXX: What about relocation?
		     */
		    Patient 	patient = Handle_Patient(handle);
		    ResourcePtr rp;
		    int 	i;
		    
		    /*
		     * Find the resource descriptor for the handle
		     */
		    for (i = patient->numRes, rp = patient->resources;
			 i > 0;
			 i--, rp++)
		    {
			if (rp->handle == handle) {
			    break;
			}
		    }
		    
		    assert(i > 0);
		    
		    /*
		     * Seek to the right place in the object file
		     * and read the data.
		     */
		    IbmEnsureObject(patient);

		    if ((dword)patientAddress + numBytes > rp->size) {
			numBytes = rp->size - (dword)patientAddress;
		    }

		    if (Ibm_ReadFromObjectFile(patient, (word)numBytes,
		    	    	    (dword)(rp->offset+patientAddress), 
			    	    swatAddress, L_SET, 
				    GEODE_DATA_NORMAL, Handle_ID(handle),
				    (word)patientAddress) == TCL_ERROR)
	            {
		    	return 0;
		    }
			
		    return(numBytes);
		} else {
		    Warning("Handle %04xh discarded", Handle_ID(handle));
		    return(0);
		}
	    } else if (state & HANDLE_KERNEL) {
		/*
		 * Kernel segments are read absolutely, since there aren't any
		 * real handles for them
		 */
		procNum = RPC_READ_ABS;
		segment = Handle_Segment(handle);
		offset = (word)patientAddress;
	    } else {
		if (handle != NullHandle &&
		    (patientAddress+numBytes) > (Address)65536)
		{
		    /*
		     * If the address is beyond the 64k that can be in a
		     * handle, convert the beast to absolute so we get the
		     * right data.
		     */
		    procNum = RPC_READ_ABS;
		    IbmDecomposeAddress(patientAddress +
					MakeAddress(Handle_Segment(handle), 0),
					&segment,
					&offset);
		} else {
		    procNum = RPC_READ_MEM;
		    segment = Handle_ID(handle);
		    offset = (word)patientAddress;
		}
	    }
	} else {
	    procNum = RPC_READ_ABS;
	    IbmDecomposeAddress(patientAddress, &segment, &offset);
	}

	numRead = 0;
	while(numBytes != 0 && !Ui_CheckInterrupt()) {
	    ReadArgs	ra;
	    int	    	i = ((numBytes > RPC_MAX_DATA-2*sizeof(RpcHeader)) ?
			     RPC_MAX_DATA - 2*sizeof(RpcHeader) : numBytes);

	    /*
	     * Set up the args to be passed (even the handle, as it might have
	     * gotten thrashed by byte-swapping last time through).
	     */
	    ra.ra_handle = segment;
	    ra.ra_offset = offset;
	    ra.ra_numBytes = i;

	    if (Rpc_Call(procNum,
			 sizeof(ra), typeReadArgs, (Opaque)&ra,
			 i, NullType, (Opaque)swatAddress) != RPC_SUCCESS)
	    {
		Warning("Couldn't read from PC: %s",
			Rpc_LastError());
		break;
	    }

	    numRead 	+= i;
	    numBytes	-= i;
	    swatAddress += i;
	    offset  	+= i;
	}
    }
    return(numRead);
}

/***********************************************************************
 *				Ibm_WriteBytes
 ***********************************************************************
 * SYNOPSIS:	  Write data to the PC
 * CALLED BY:	  GLOBAL
 * RETURN:	  The number of bytes written.
 * SIDE EFFECTS:  Blocks may be added to the cache and placed on the
 *	dirtyBlocks list.
 *
 * STRATEGY:
 *	Bytes are only written into the cache, not to the PC. Any modified
 *	block is placed on the dirtyBlocks list, however, and will be
 *	flushed to the PC when the patient is continued or when
 *	curPatient is changed.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/13/88		Initial Revision
 *
 ***********************************************************************/
int
Ibm_WriteBytes(int   	numBytes,   	/* Number of bytes to write */
	       genptr	swatAddress,	/* Address of data to write */
	       Handle	handle,	    	/* Handle of block on PC to which to
					 * write. NullHandle if write s/b
					 * absolute */
	       Address	patientAddress)	/* Offset into block or absolute
					 * address if handle is NullHandle */
{
    genptr		block;	    	/* Cache block to modify */
    Cache_Entry	  	entry;	    	/* Its entry in the cache (for the
					 * dirtyBlocks list) */
    IbmKey  	  	key;	    	/* Key under which to find the
					 * block */
    int			numWritten; 	/* Total number of bytes written this
					 * time */
    int	    	    	i;

    if (handle != NullHandle && patientAddress >= (Address)65536) {
	/*
	 * If the address is beyond the 64k that can be in a handle, convert
	 * the beast to absolute so we get the right data.
	 */
	patientAddress += MakeAddress(Handle_Segment(handle), 0) ;
	handle = NullHandle;
    }
	 
    if (cacheOn && ((sysFlags & PATIENT_RUNNING)==0)) {
	key.handle = handle;
	
	numWritten = 0;
	
	while(numBytes != 0 && !Ui_CheckInterrupt()) {
	    key.offset = patientAddress;
	    
	    /*
	     * First find the block in the cache
	     */
	    block = IbmFindBlock(&key, &entry);
	    
	    if (block == (genptr)NULL) {
		/*
		 * Not finding the block is a serious error -- stop now
		 */
		break;
	    }
	    
	    /*
	     * Figure out how many bytes actually go into the cache block.
	     */
	    i = cacheBlockSize - (patientAddress - key.offset);
	    if (i > numBytes) {
		i = numBytes;
	    }
	    
	    /*
	     * Copy them in.
	     */
	    bcopy((void *)swatAddress,
		  block + (patientAddress - key.offset),
		  i);
	    
	    /*
	     * Update state variables.
	     */
	    swatAddress     += i;	/* Data source */
	    numBytes	    -= i;	/* Loop counter */
	    patientAddress  += i;	/* Offset in PC */
	    bytesToCache    += i;	/* Statistics */
	    numWritten	    += i;	/* Return value count */
	    
	    /*
	     * Mark the block as dirty.
	     */
	    malloc_settag(block, TAG_DCBLOCK);
	    
	    /*
	     * If patient actually running, flush the data right away
	     */
	    if (sysFlags & PATIENT_RUNNING) {
		Cache_InvalidateOne(dataCache, entry);
	    }
	}

    } else {
	/*
	 * Cache inactive -- we get to do the writing ourselves...
	 * We take advantage of the similarities between the
	 * AbsWriteArgs and WriteArgs structures to have a single
	 * write loop...
	 */
	word	    segment, offset;
	Rpc_Proc    procNum;
	
	
	if (handle != NullHandle) {
	    int	    state = Handle_State(handle);

	    if (state & HANDLE_DISCARDED) {
		Warning("Handle %04xh discarded", Handle_ID(handle));
		return(0);
	    } else if (state & HANDLE_KERNEL) {
		/*
		 * Kernel segments are written absolutely, since there aren't
		 * any  real handles for them
		 */
		procNum = RPC_WRITE_ABS;
		segment = Handle_Segment(handle);
		offset = (word)patientAddress;
	    } else {
		procNum = RPC_WRITE_MEM;
		segment = Handle_ID(handle);
		offset = (word)patientAddress;
	    }
	} else {
	    procNum = RPC_WRITE_ABS;
	    IbmDecomposeAddress(patientAddress, &segment, &offset);
	}

	numWritten = 0;
	while(numBytes != 0 && !Ui_CheckInterrupt()) {
	    struct {
		WriteArgs   wa;
		byte	    buf[RPC_MAX_DATA-sizeof(RpcHeader)];
	    }	    	arg;
	    int	    	i = ((numBytes > RPC_MAX_DATA-2*sizeof(RpcHeader)) ?
			     RPC_MAX_DATA - 2*sizeof(RpcHeader) : numBytes);

	    /*
	     * Set up standard args (even the handle -- it might have been
	     * thrashed by the Rpc module when it byte-swapped the arg).
	     */
	    arg.wa.wa_handle = segment;
	    arg.wa.wa_offset = offset;
	    /*
	     * Copy the bytes into the argument buffer. Unfortunately, we
	     * can't just tell the Rpc module to take them from elsewhere,
	     * so we have to do the copy....
	     */
	    bcopy((void *)swatAddress, arg.buf, i);

	    /*
	     * Issue the call.
	     */
	    if (Rpc_Call(procNum,
			 sizeof(WriteArgs)+i, typeWriteArgs, (Opaque)&arg,
			 0, NullType, NullOpaque) != RPC_SUCCESS)
	    {
		Warning("Couldn't write to PC: %s",
			Rpc_LastError());
		break;
	    }

	    /*
	     * Update loop/state variables
	     */
	    numWritten 	+= i;
	    numBytes	-= i;
	    swatAddress += i;
	    offset  	+= i;
	}
    }
    return(numWritten);
}


/***********************************************************************
 *				IbmDCacheCmd
 ***********************************************************************
 * SYNOPSIS:	    Control the data caching parameters
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    Probably.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/27/88	Initial Revision
 *
 ***********************************************************************/
#define DCACHE_BSIZE 	(ClientData)0
#define DCACHE_LEN   	(ClientData)1
#define DCACHE_PARAMS	(ClientData)2
#define DCACHE_STATS 	(ClientData)3
#define DCACHE_ON   	(ClientData)4
#define DCACHE_OFF  	(ClientData)5
static const CmdSubRec	dcacheCmds[] = {
    {"bsize",	DCACHE_BSIZE,	1, 1,	"<block size>"},
    {"length",	DCACHE_LEN,	1, 1,	"<# blocks cached>"},
    {"params",	DCACHE_PARAMS,	0, 0,	""},
    {"stats",	DCACHE_STATS,	0, 0,	""},
    {"on",   	DCACHE_ON,  	0, 0, 	""},
    {"off",  	DCACHE_OFF, 	0, 0,	""},
    {NULL,   	0,  	    	0, 0,	NULL}
};
DEFCMD(dcache,IbmDCache,TCL_EXACT,dcacheCmds,swat_prog,
"Usage:\n\
    dcache bsize <blockSize>\n\
    dcache length <numBlocks>\n\
    dcache stats\n\
    dcache params\n\
    dcache (on|off)\n\
\n\
Examples:\n\
    \"dcache bsize 16\"	    Set the number of bytes fetched at a time to 16.\n\
    \"dcache length 1024\"    Allow 1024 blocks of the current block size to\n\
			    be in the cache at a time.\n\
    \"dcache off\"    	    Disables the Swat data cache.\n\
\n\
Synopsis:\n\
    Controls the cache Swat uses to hold data read from the PC while the\n\
    machine is stopped.\n\
\n\
Notes:\n\
    * Data written while the machine is stopped actually get written to the\n\
      cache, not the PC, and the modified blocks are written when the\n\
      machine is continued.\n\
\n\
    * The default cache block size is 32 bytes, with a default cache length\n\
      of 64 blocks.\n\
\n\
    * It is a very rare thing to have to turn the data cache off. You might\n\
      need to do it while examining the changing registers of a\n\
      memory-mapped I/O device, but other than that...\n\
\n\
    * The <blockSize> must be a power of 2 and no more than 128. \n\
\n\
    * Changing the block size causes all cached blocks to be flushed (any\n\
      modified cache blocks are written to the PC).\n\
\n\
    * Changing the cache length will only flush blocks if there are more\n\
      blocks currently in the cache than are allowed by the new length.\n\
\n\
    * The \"dcache stats\" command prints statistics giving some indication of\n\
      the efficacy of the data cache. It does not return anything.\n\
\n\
    * The \"dcache params\" command returns a list {<blockSize> <numBlocks>}\n\
      giving the current parameters of the data cache. There are some\n\
      operations where you might want to adjust the size of the cache either\n\
      up or down, but need to reset the parameters when the operation\n\
      completes. This is what you need to do this. \n\
\n\
See also:\n\
    cache\n\
")
{
    switch((int)clientData) {
	case (int)DCACHE_STATS:
	    Message("CACHE STATISTICS:\n");
	    Message("From                      To\n");
	    Message("PC           Cache        PC           Cache\n");
	    Message("%-13d%-13d%-13d%-13d\n", bytesFromPC, bytesFromCache,
		    bytesToPC, bytesToCache);
	    Message("\nReferenced: %d times, Hit %d times\n", cacheRefs,
		    cacheHits);
	    Message("Ratios: read %d%%, write %d%%, overall %d%%\n",
		    bytesFromPC ? bytesFromCache * 100 / bytesFromPC : 0,
		    bytesToPC ? bytesToCache * 100 / bytesToPC : 0,
		    cacheRefs ? cacheHits * 100 / cacheRefs : 0);
	    Message("Block size: %d, Cache size: %d blocks, Contains %d blocks\n",
		    cacheBlockSize,
		    Cache_MaxSize(dataCache), Cache_Size(dataCache));
	    return(TCL_OK);
	case (int)DCACHE_BSIZE:
	{
	    int 	bsize;
	    
	    /*
	     * Make sure the size is within bounds.
	     */
	    bsize = atoi(argv[2]);
	    if (/*(bsize == 0) || */
		(ffs(bsize & ~(1 << (ffs(bsize)-1))) != 0) ||
		(bsize > RPC_MAX_DATA - 2*sizeof(RpcHeader)))
	    {
		Tcl_Error(interp, "block size must be a power of 2");
	    }
	    
	    /*
	     * Flush the cache
	     */
	    Cache_InvalidateAll(dataCache, TRUE);
	    cacheBlockSize = bsize;
	    if (bsize == 0) {
		cacheOn = FALSE;
	    } else {
		cacheOn = TRUE;
	    }
	    break;
	}
	case (int)DCACHE_LEN:
	{
	    int clen;
	    
	    /*
	     * Make sure the desired length is ok
	     */
	    clen = atoi(argv[2]);
	    if (clen <= 0) {
		Tcl_Error(interp, "illegal cache size (must be at least 1)");
	    }
	    
	    /*
	     * Set the maximum allowed size. If blocks need to be thrown out,
	     * they will be...
	     */
	    Cache_SetMaxSize(dataCache, clen);
	    break;
	}
	case (int)DCACHE_PARAMS:
	    Tcl_RetPrintf(interp, "%d %d", cacheBlockSize,
			  Cache_MaxSize(dataCache));
	    return(TCL_OK);
	case (int)DCACHE_ON:
	    cacheOn = TRUE;
	    return(TCL_OK);
	case (int)DCACHE_OFF:
	    cacheOn = FALSE;
	    return(TCL_OK);
    }
    /*
     * Reset cache statistics
     */
    bytesFromPC = bytesFromCache = bytesToPC = bytesToCache = cacheRefs =
	cacheHits = 0;
    return(TCL_OK);
}


/***********************************************************************
 *				IbmCache_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize the data cache
 * CALLED BY:	    Ibm_Init
 * RETURN:	    Nothing
 * SIDE EFFECTS:    A Cache is created.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/18/89		Initial Revision
 *
 ***********************************************************************/
void
IbmCache_Init()
{
    
    dataCache = Cache_Create(CACHE_LRU, CACHE_LENGTH, CACHE_THIS(IbmKey),
			     IbmFreeBlock);
    cacheRefs = cacheHits = bytesFromPC = bytesFromCache =
	bytesToPC = bytesToCache = 0;
    cacheBlockSize = CACHE_BLOCK_SIZE;

    Cmd_Create(&IbmDCacheCmdRec);
}    
