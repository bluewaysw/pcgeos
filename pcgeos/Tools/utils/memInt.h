/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  memInt.h
 * FILE:	  memInt.h
 *
 * AUTHOR:  	  Adam de Boor: Aug  1, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 1/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	The Mem module of the Tools Utilities Library contains a
 *	half-hearted emulation of the PC/GEOS heap code. It doesn't
 *	deal with swapping or discarding or compaction or...
 *	To be blunt, this thing exists primarily to support the VM
 *	module of this library. As more functions are required, they
 *	will be added. For now, however, this thing is really simple.
 *
 *	There is a single handle table that contains a pointer and a
 *	size for each handle. As for PC/GEOS, a MemHandle is an index
 *	into this table.
 *
 * 	$Id: memInt.h,v 1.5 91/04/26 11:48:10 adam Exp $
 *
 ***********************************************************************/
#ifndef _MEMINT_H_
#define _MEMINT_H_

#include    <mem.h>

#include    <assert.h>

typedef struct {
    void    	*addr;	    /* Where data be located */
    int	    	size;	    /* Size of block allocated */
} MemHandleRec, *MemHandlePtr;

extern MemHandlePtr memHandleTable;
extern int  	    memNumHandles;

extern MemHandle    MemAllocHandle(void);
extern void 	    MemFreeHandle(MemHandle handle);

/*
 * Error message when can't allocate memory. Doesn't return
 */
extern volatile void MemAllocErr(void);

#endif /* _MEMINT_H_ */
