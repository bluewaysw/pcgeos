/***********************************************************************
 *
 *	Copyright (c) Geoworks 1998.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  GEOS-SC WWW Library
 * MODULE:	  Movable Memory
 * FILE:	  wwmem.h
 *
 * AUTHOR:  	  Kok Kin Kee: Jan 30, 1998
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	kkee    	1/30/98		Initial version
 *
 * DESCRIPTION:
 *
 *	WWW Movable Memory. This replaces any platform specific movable 
 *      memory APIs.
 *
 * 	$Id: //depot/pcgeos/CInclude/WWW2/ww2mem.h#1 $
 *
 ***********************************************************************/
#ifndef _WW_MEM_H_
#define _WW_MEM_H_

#define WWMemHandle optr


    /**
     *
     *  Allocate a block of movable memory.
     *
     * [in]  size 
     *
     * Return_value_ WWMemHandle or NULL.
     *
     * See_also_ MallocH
     *
     * Overrides_ MallocH
     *
     * Status_ Functional
     */
WWMemHandle _far _pascal WWMemAlloc(word size);

    /**
     *
     *  Realloc a block of movable memory. Old data is copied over 
     *  to new handle. If reallocated to be bigger, remaining space
     *  will be initialized with zero values.
     *
     * [out] handle   Memory handle to realloc. The block must not be 
     *                locked or it will die in EC code.
     * [in]  size     New size.
     *
     * Return_value_  TRUE for success else failure.
     *
     * See_also_ ReallocH()
     *
     * Overrides_ ReallocH()
     *
     * Status_ Functional
     */
Boolean _far _pascal WWMemRealloc(WWMemHandle handle, word size);

    /**
     *
     *  Free a movable block of memory.
     *
     * [in]  handle  Block to free.
     *
     * Return_value_ Nothing
     *
     * See_also_ FreeH()
     *
     * Overrides_ FreeH()
     *
     * Status_ Functional
     */
void _far _pascal WWMemFree(WWMemHandle handle);

    /**
     *
     * Lock a movable block of memory. 
     *
     * [in]  WWMemHandle    Handle of memory to lock
     *
     * Return_value_ Pointer or NULL if cannot lock block into memory.
     *
     * See_also_ Lock()
     *
     * Overrides_ Lock()
     *
     * Status_ Functional
     */
void* _far _pascal WWMemLock(WWMemHandle handle);

    /**
     *
     * Unlock a locked memory handle. 
     *
     * [in]  WWMemHandle   Handle of memory to unlock.
     *
     * Return_value_ Nothing
     *
     * See_also_ Unlock()
     *
     * Overrides_ Unlock()
     *
     * Status_ Functional
     */
void _far _pascal WWMemUnlock(WWMemHandle handle);

    /**
     *
     * Alloc and lock a block. 
     *
     * [out] handle   Block handle allocated or 0 if not allocated.
     * [in]  size     Size of block
     *
     * Return_value_ void*   Pointer or NULL if not allocated.
     *
     * See_also_ 
     *
     * Overrides_
     *
     * Status_ Functional
     */
void* _far _pascal WWMemAllocAndLock(WWMemHandle *handle, word size);


    /**
     *
     * Unlock and free. 
     *
     * [in]  
     *
     * Return_value_ 
     *
     * See_also_ 
     *
     * Overrides_
     *
     * Status_ Functional
     */
void _far _pascal WWMemUnlockAndFree(WWMemHandle handle);

    /**
     *
     * Deref a locked block. 
     *
     * [in]  WWMemHandle   Handle to deref.
     *
     * Return_value_ void*  Pointer to locked block.
     *
     * See_also_ Deref()
     *
     * Overrides_ Deref()
     *
     * Status_ Functional
     */
void* _far _pascal WWMemDeref(WWMemHandle handle);

    /**
     *
     * EC check a WWMemHandle. 
     *
     * [out] 
     * [in]  
     *
     * Return_value_ 
     *
     * See_also_ 
     *
     * Overrides_
     *
     * Status_ EC only.
     */
void _far _pascal ECCheckWWMemHandle(WWMemHandle handle);

#endif /* _WW_MEM_H_ */
