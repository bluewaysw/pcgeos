COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel
FILE:		heapInit.asm (heap initialization)

AUTHOR:		Tony Requist

ROUTINES:
	Name		Description
	----		-----------
   EXT	InitHeap	Initialize the heap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

DESCRIPTION:
	This module initializes the heap.  See manager.asm for documentation.

	$Id: heapInit.asm,v 1.1 97/04/05 01:13:59 newdeal Exp $

-------------------------------------------------------------------------------@



COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitHeap

DESCRIPTION:	Initialize the heap

CALLED BY:	EXTERNAL
		InitGeos

PASS:
	ds - kernel variable segment

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added
	Don	2/93		Added XIP initialization

-------------------------------------------------------------------------------@

InitHeap	proc	near

if	FULL_EXECUTE_IN_PLACE

	; Set the top of the heap - this is an optimization, so SearchHeap
	; won't bother looking through all the blocks from the XIP image
	; that never move/are never freed

	push	es
	mov	es, ds:[loaderVars].KLV_xipHeader
	mov	bx, es:[FXIPH_bottomBlock]
	mov	ds:[xipHandleTopBlock], bx
	pop	es

	; Initialize the heap with cc's since the loader can't handle it for
	; XIP systems.

EC<	mov	bx, ds:[loaderVars].KLV_handleBottomBlock		>
EC<	call	ECInitHeapCCCC						>

elseif	KERNEL_EXECUTE_IN_PLACE
	;
	; For XIP, store the handle with the highest segment address that
	; resides in the usable heap. The heap management code will not
	; try to allocate anything beyond this, and will also not search
	; needlessly through lots of fixed handles
	;
		mov	bx, ds:[loaderVars].KLV_handleBottomBlock
handleLoop:
		test	ds:[bx].HM_flags, mask HF_FIXED
		jnz	done
		mov	bx, ds:[bx].HM_next
		jmp	handleLoop
done:
		mov	ds:[xipHandleTopBlock], bx
endif

if 	TRACK_FINAL_FREE
	;
	; Locate the last free block, searching from the end of the heap.
	; 
		mov	bx, ds:[loaderVars].KLV_handleBottomBlock
findFreeLoop:
		mov	bx, ds:[bx].HM_prev
		cmp	ds:[bx].HM_owner, 0
		jne	findFreeLoop
		
		mov	ds:[lastFreeBlock], bx
endif
		ret
InitHeap	endp

if	not NEVER_ENFORCE_HEAPSPACE_LIMITS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitHeapSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the size of the heap

CALLED BY:	InitGeos
		EXTERNAL
PASS:		ds - kdata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	sets heapSize

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitHeapSize	proc	near
	uses	ax,bx,cx,dx,si,di
	.enter
	mov	bx, ds:[loaderVars].KLV_heapEnd
	sub	bx, ds:[loaderVars].KLV_heapStart	

	mov	cl, 6
	shr	bx, cl		; divide by 64 to go from para to k

	; this gives us the base heapsize in bx


	push	ds
	mov	ax, DOC_RESERVE_DEFAULT
	mov	cx, cs
	mov	dx, offset docReserveKeyString
	mov	ds, cx
	mov	si, offset heapSpaceCategoryString
	call	InitFileReadInteger
	mov	di, ax

	; get the space reserved for documents for each app in di

	mov	ax, EXEC_RESERVE_DEFAULT
	mov	dx, offset execReserveKeyString
	call	InitFileReadInteger
	add	di, ax
	
	; add in the space reserved for execution for each app

	mov	ax, CONCURRENCY_DEFAULT
	mov	dx, offset concurrencyKeyString
	call	InitFileReadInteger
	mul	di

	; multiply the two by the concurrency given for the platform.
	; This leaves the total app-based adjustment in dx:ax, but dx
	; had better be 0..
EC<	tst	dx					>
EC<	ERROR_NZ	GASP_CHOKE_WHEEZE		>

	sub	bx, ax
	; now we subtract the space set aside for app use from the
	; total heap size.  This may go negative..  we don't care at
	; this point since swap drivers may pull it out of the hole.
	; In fact on a desktop with it's high concurrency and
	; docReserve and correspondingly high resources the heapSize
	; probably is negative now.

	clr	ax		; heapadjustment default
	mov	dx, offset heapAdjustmentKeyString
	call	InitFileReadInteger
	add	bx, ax
	; now we've added in the heapAdjustment to the heapSize

	mov	ax, SYS_RESERVE_DEFAULT
	mov	dx, offset sysReserveKeyString
	call	InitFileReadInteger
	sub	bx, ax
	; next we subtract out some space for the system libraries

	mov	ax, BW_TRUE		; Default is Limit Enforced
	mov	dx, offset heapLimitEnforcedKeyString
	call	InitFileReadBoolean
	; lastly we check to see if all the heapspace limits are to be enforced

	pop	ds
	mov	ds:[heapSpaceLimitsEnforced], ax
	mov	ds:[heapSize], bx

IHS_initialHeapSize::				; showcalls -H
	.leave
	ret
InitHeapSize	endp

docReserveKeyString		char	"docReserve", 0
execReserveKeyString		char	"execReserve", 0
sysReserveKeyString		char	"sysReserve", 0
concurrencyKeyString		char	"concurrency", 0
heapAdjustmentKeyString		char	"heapAdjustment", 0
heapLimitEnforcedKeyString	char	"heapSpaceLimitsEnforced", 0
heapSpaceCategoryString		char	"heapspace", 0

endif	; not NEVER_ENFORCE_HEAPSPACE_LIMITS

if FULL_EXECUTE_IN_PLACE

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECInitHeapCCCC

DESCRIPTION:	Fill a block with 0xcc for EC purposes

CALLED BY:	GLOBAL

PASS:		ds	= idata
		bx	= block to fill

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

if ERROR_CHECK

ECInitHeapCCCC	proc	near
	call	PushAllFar

	mov	es,ds:[bx][HM_addr]
	mov	dx,ds:[bx][HM_size]
	mov	ax, 0xcccc
largeLoop:
	mov	cx, 0xfff
	sub	dx, cx				;assume 0xfff0 bytes
	jae	10$				;=> ok
	add	cx, dx				;downgrade count by overshoot
10$:
	shl	cx				;convert paras to words
	shl	cx
	shl	cx				;cx = # words
	clr	di
	rep	stosw

	mov	cx, es				;assume > 0xfff paragraphs
	add	cx, 0xfff
	mov	es, cx
	tst	dx				;XXX: assumes no free block
						; > 1/2 megabyte. Fair enough?
	jg	largeLoop

	call	PopAllFar
	ret

ECInitHeapCCCC	endp
endif
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeapStartScrub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a scrub thread for the heap

CALLED BY:	InitGeos
PASS:		ds	= idata
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeapStartScrub	proc	near
		.enter

	;
	; Display log entry
	;
		push	ds
		segmov	ds, cs
		mov	si, offset scrubLogString
		call	LogWriteInitEntry
		pop	ds

if 0
	;
	; If this machine doesn't have much memory (initial free size is
	; less than HEAP_LOW_MEM_SIZE), up the priority of the scrub thread
	; so we keep the heap clean enough.
	; 
		mov	al, PRIORITY_LOW
		cmp	ds:[loaderVars].KLV_heapFreeSize,
						HEAP_LOW_MEM_SIZE shr 4
		jae	priorityOK
		mov	al, PRIORITY_STANDARD
priorityOK:
endif
if	IDLE_UPDATE_ASYNC_VM
	;
	; Allocate a queue on which to place the handles of VM files that need
	; to be updated at idle time.
	;
		call	GeodeAllocQueue
		mov	ds:[heapAsyncVMQueue], bx
endif	; IDLE_UPDATE_ASYNC_VM

	;
	; With the new heap functionality performance is better if the scrub
	; thread just stands and waits...
	;
		mov	al, PRIORITY_IDLE

		mov	bx, ds
		mov	cx, segment HeapScrubThread
		mov	dx, offset HeapScrubThread
		mov	di, SCRUB_STACK_SIZE
		mov	bp, handle 0
		call	ThreadCreate

if	INI_SETTABLE_HEAP_THRESHOLDS

	;
	; Initialize some thresholds from the .ini file, if there.
	;

		push	ds
		mov	cx, cs
		mov	ds, cx
		mov	si, offset cs:systemCategoryString
		mov	dx, offset cs:minSpaceForInitialCompactionKey
		mov	ax, MIN_SPACE_FOR_INITIAL_COMPACTION	;default
		call	InitFileReadInteger
		pop	ds
		mov	ds:minSpaceForInitialCompaction, ax

		push	ds
		mov	ds, cx
		mov	dx, offset cs:minSpaceToThrowOutKey
		mov	ax, MIN_SPACE_TO_THROW_OUT	;default
		call	InitFileReadInteger
		pop	ds
		mov	ds:minSpaceToThrowOut, ax
endif
		.leave
		ret
HeapStartScrub	endp


scrubLogString	char	"Scrub Thread", 0


if	INI_SETTABLE_HEAP_THRESHOLDS
minSpaceForInitialCompactionKey	char	"minSpaceForInitialCompaction",0
minSpaceToThrowOutKey		char	"minSpaceToThrowOut",0
endif
