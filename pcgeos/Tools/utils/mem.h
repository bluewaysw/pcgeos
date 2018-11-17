/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- Memory Allocation
 * FILE:	  mem.h
 *
 * AUTHOR:  	  Adam de Boor: Aug  1, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 1/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Emulation of the PC/GEOS Mem module. Very simple. No otherInfo,
 *	lock count, owner or block type -- just address and size.
 *
 *
 * 	$Id: mem.h,v 1.5 91/04/26 11:47:32 adam Exp $
 *
 ***********************************************************************/
#ifndef _MEM_H_
#define _MEM_H_

#include <os90.h>

/*
 * This is an opaque type...
 */
typedef word	MemHandle;

/*
 * Block type flags. All of these are ignored.
 */
#define HF_FIXED    	    0x0080  /* Block won't move (of course) */
#define HF_SHARABLE 	    0x0040  /* May be shared by other (non-existent)
				     * processes */
#define HF_DISCARDABLE	    0x0020  /* Block may be discarded (but won't be) */
#define HF_SWAPABLE 	    0x0010  /* Block may be swapped (and may be,
				     * but not by us) */
#define HF_LMEM	    	    0x0008  /* Managed by LMem module (ignored) */
#define HF_DEBUG    	    0x0004  /* Block attached to Swat (yeah right) */
#define HF_DISCARDED	    0x0002  /* Block has been discarded (never) */
#define HF_SWAPPED 	    0x0001  /* Block has been swapped to extended
				     * or expanded memory (which we don't
				     * have) */

/*
 * Block allocation flags.
 */
#define HAF_ZERO_INIT	    0x0080  /* Initialize block to 0's */
#define HAF_LOCK    	    0x0040  /* Lock block before returning. NOT
				     * USED EXCEPT BY MemAllocAndLock */
#define HAF_NO_ERR  	    0x0020  /* Abort on error -- don't return one */
#define HAF_UI	    	    0x0010  /* Block run by UI (hee hee) */
#define HAF_READ_ONLY	    0x0008  /* Block can be made read-only */
#define HAF_OBJECT_RESOURCE 0x0004  /* Block is object resource to be run
				     * by either current process or the UI
				     * (q.v. HAF_UI) */
#define HAF_CODE    	    0x0002
#define HAF_CONFORMING	    0x0001

/*
 * Allocate a block of memory, returning the handle for it.
 */
extern MemHandle    MemAlloc(word    	numBytes,
			     short  	typeFlags,
			     short  	allocFlags);
			     
/*
 * Allocate a block and lock it, returning both the handle and the
 * address of the block.
 */
extern MemHandle    MemAllocAndLock(short   numBytes,
				    short   typeFlags,
				    short   allocFlags,
				    void    **addrPtr);
/*
 * Change the size of a block. Only HAF_ZERO_INIT is valid for allocFlags.
 * Returns non-zero if successful.
 */
extern int  	    MemReAlloc(MemHandle    handle,
			       word	    newSize,
			       short	    allocFlags);

/*
 * Change the size of a block and lock it down, returning the address
 * of the block. Returns non-zero if successful. Again, only HAF_ZERO_INIT
 * is valid in allocFlags.
 */
extern int  	    MemReAllocAndLock(MemHandle	handle,
				      short 	newSize,
				      short 	allocFlags,
				      void  	**addrPtr);
/*
 * Free a block and its handle
 */
extern void 	    MemFree(MemHandle	handle);

/*
 * Lock down a block and return its address
 */
extern void 	    *MemLock(MemHandle	handle);

/*
 * Unlock a block, allowing it to be moved (but not in this implementation)
 */
#define MemUnlock(handle)

/*
 * Fetch info for a handle.
 */
extern void 	    MemInfo(MemHandle	handle,
			    genptr    	*addrPtr,
			    word    	*sizePtr);
/*
 * Other routines from PC/GEOS will be implemented as needed.
 */

#endif /* _MEM_H_ */
