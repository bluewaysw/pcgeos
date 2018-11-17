COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Heap
FILE:		heapManager.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name			Description
	----			-----------
   GLB	MemAlloc		Allocate memory from the heap
   GLB	MemReAlloc		Reallocate a block on the heap
   GLB	MemFree			Free the given block on the heap
   GLB	MemLock			Retrieve the absolute address of and lock a
				block on the global heap
   GLB	MemUnlock		Unlock the given block on the global heap
   GLB	MemInfo			Return information about a block
   GLB	MemModifyFlags		Modify the flags associated with a block
   GLB	HandleModifyOwner		Modify the owner associated with a block
   GLB	MemModifyOtherInfo	Modify the other info associated with a block
   GLB	HandleP			Set a semaphore on the given block to ensure
				exclusive access
   GLB	HandleV			Release a semaphore on the given block
   GLB	MemThreadGrab		Lock a block and set a semaphore on the block
				that allows the current thread to do more
				MemThreadGrab's but will cause other threads
				to wait.
   GLB	MemThreadGrabNB		Like MemThreadGrab, but won't block if block
				already grabbed.
   GLB	MemThreadRelease	Undo MemThreadGrab

   EXT  GetByteSize		Returns size of a block
   EXT	InitHeap		Initialize the heap
   EXT	RemoveSwapFiles		Remove all swap files from the swap disk
   EXT	PHeap			Do P_CS_SEM heapSem
   EXT	VHeap			Do V_CS_SEM heapSem
   EXT	DoFree			Free the given block (internal routine)
   EXT	DoReAlloc		Reallocate the given block (internal routine)

   EXT	NearLock		Call LockBlock from the kernel
   EXT	NearUnlock		Call UnlockBlock from the kernel
   EXT	AllocateHandle		Allocate a handle from the handle table
   EXT	FreeHandle		Free a handle from the handle table

   EXT	ECCheckMemHandle	Check to make sure a handle is legal, cause an
				appropriate fatal error if not


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	6/88		Added OwnBlock, ReleaseBlock
	Tony	9/88		Fixed bug in DoSwap
	Chris	10/88		Made GetByteSize external
	Tony	10/88		Comments from Jim's code review added

DESCRIPTION:
	This file assembles the heap code.


Testing:

	This module was tested in three ways.  First, I wrote test code
to call the various routines and this code was stepped through with the
Atron board.  Second, I wrote Atron macros to call the heap routines as they
are called externally.  This method worked much better than the first.  To
do extensive tests, I wrote a test routine "DoSomething" that did a random
(actually pseudo-random) action to one of 100 blocks.  Running this in a
loop caught many obscure bugs.

	All of the macros are in the file heap.mac.  One very useful macro
is 'walk' which displays the heap much like the Heapwalker does.

Future Ideas/Requirements:

	While this is a working module, there are a few changes that will
have to be made:

      - Initialization code must be added to set swapFast, swapOK and
	swapDevice depending on system configuration and depending upon the
	user's preferences

      - Checks must be put in the swapping routines to make sure the correct
	disk is in the drive.

      - Code modules must be locked while they are running.

	There are also several improvements that could be made:

      - Before throwing out blocks, the first n blocks on the LRU list could
	be checked and if they are as large or larger than the request, that
	block could be thrown out and the request filled immediately.

      - CompactHeap could be modified to exit if a large enough free block
	has been created.

      - If swapping is slow, blocks could be encoded to reduce their size,
	eliminating the need for discarding.  This probably only makes sense
	if the system has no hard disk.

	See the spec for more information.

	$Id: heapManager.asm,v 1.1 97/04/05 01:13:56 newdeal Exp $

-------------------------------------------------------------------------------@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include lmem.def
include sem.def
include Objects/processC.def
include timer.def		;for AllocHandleAndBytes calling TimerSleep
include graphics.def
include font.def
include vm.def
include profile.def


include Internal/fileInt.def		; for FAF_EXCLUSIVE
include Internal/geodeStr.def		;includes: geode.def
include Internal/interrup.def
include Internal/debug.def
UseDriver Internal/swapDr.def
UseDriver Internal/fontDr.def		; for FID_MAN_ID
UseLib Internal/swap.def

if	USE_32BIT_STRING_INSTR
.386					; enable 386 instructions
endif

;--------------------------------------

include heapMacro.def		;HEAP macros
include heapConstant.def	;HEAP constants

;-------------------------------------

include heapVariable.def

;-------------------------------------

kcode	segment
include heapErrorCheck.asm
include heapCore.asm
include heapHandle.asm
include heapHigh.asm
include heapLow.asm
include heapSwap.asm
include heapScrub.asm
include heapCompress.asm
kcode	ends

include heapC.asm

;-------------------------------------

kinit	segment
include heapInit.asm
kinit	ends

end
