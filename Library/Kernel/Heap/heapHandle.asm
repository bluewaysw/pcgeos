COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel
FILE:		heapHandle.asm (handle routines)

AUTHOR:		Tony Requist

ROUTINES:
	Name			Description
	----			-----------
   EXT	AllocateHandle		Allocate a handle from the handle table
   EXT	FreeHandle		Free a handle from the handle table

   INT	AllocateMemHandle	Allocate a handle for a memory block
   INT	DupHandle		Duplicate a memory handle

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

DESCRIPTION:

	This module contains handle manipulation routines for the heap.
See manager.asm for documentation.

    	$Id: heapHandle.asm,v 1.1 97/04/05 01:13:57 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	AllocateMemHandle

DESCRIPTION:	Allocate a handle from the handle table for a memory block
		and initialize some fields

CALLED BY:	INTERNAL
		AllocHandleAndBytes, DupHandle, MemAlloc

PASS:
	exclusive access to heap variables
	bx - owner for new block
	ds - kernel segment
	cl - flags for block type
		bit 7: set to allocate fixed block (BLOCK_FIXED)
		bit 6: set to allocate block as sharable (BLOCK_SHARABLE)
		bit 5: set to allocate block as discardable (BLOCK_DISCARDABLE)
		bit 4: set to allocate block as swapable (BLOCK_SWAPPABLE)
		bit 3: set to allocate block as DISCARDED (BLOCK_DISCARDED)
		bit 2: set to allocate block as being debugged (BLOCK_DEBUG)
		bits 1-0: block's priority (BLOCK_PRIORITY), 3 is highest
			0 - BLOCK_PRIO_LOW
			1 - BLOCK_PRIO_STANDARD
			2 - BLOCK_PRIO_HIGH
			3 - BLOCK_PRIO_HIGHEST

RETURN:
	bx - handle with -> lock count = 0
			 -> HM_otherInfo = 1

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@
AllocateMemHandleFar	proc	far
	call	AllocateMemHandle
	ret
AllocateMemHandleFar	endp

AllocateMemHandle	proc	near

EC <	call	AssertDSKdata					>
EC <	call	AssertHeapMine					>

	call	AllocateHandle

	mov	ds:[bx][HM_flags],cl	;save flags
	mov	ds:[bx][HM_lockCount],0	;save lock count

	mov	ds:[bx][HM_otherInfo],1

	mov	ax,ds:[systemCounter.low]
	mov	ds:[bx][HM_usageValue],ax

	ret

AllocateMemHandle	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	AllocateHandle

DESCRIPTION:	Allocate a handle from the handle table

CALLED BY:	EXTERNAL
		AllocateMemHandle, CreateThreadCommon

PASS:
	bx - owner for handle (if any)
	ds - kernel segment

RETURN:
	interrupts in same state as when called
	bx - handle (all fields but HG_owner initialized to zero)

DESTROYED:
	none (not even flags)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	temp = handleFreePtr
	handleFreePtr = handleFreePtr->nextFreeHandle
	return(temp)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added

-------------------------------------------------------------------------------@

AllocateHandle	proc	near

	pushf
EC <	call	AssertDSKdata					>
	push	ax
	INT_OFF
	push	bx			;save owner

	mov	bx, ds:[loaderVars].KLV_handleFreePtr

	tst	bx
	jz	AH_error
EC <	cmp	ds:[bx].HG_type, SIG_FREE				>
EC <	ERROR_NZ NON_FREE_HANDLE_ON_FREE_LIST				>
					;save new free list pointer
	mov	ax, ds:[bx].HM_next	; was HM_nextFree
	mov	ds:[loaderVars].KLV_handleFreePtr, ax

	; clear out the handle. This may look inefficient, but the jockeying of
	; registers required to get to a rep stosw takes 57 more cycles (180
	; vs. 123) and only 3 fewer bytes (17 vs. 20)

	clr	ax				
	mov	{word}ds:[bx].HG_data1, ax	; 2	(9)
	mov	ds:[bx].HG_data2[0], ax		; 3	(19)
	mov	ds:[bx].HG_data2[2], ax		; 3	(19)
	mov	ds:[bx].HG_data2[4], ax		; 3	(19)
	mov	ds:[bx].HG_data2[6], ax		; 3	(19)
	mov	ds:[bx].HG_data2[8], ax		; 3	(19)
	mov	ds:[bx].HG_data2[10], ax	; 3	(19)
						; 20	(123)

	pop	ds:[bx][HM_owner]		;set owner

	mov	ax, ds:[loaderVars].KLV_handleFreeCount	;update the number
	dec	ax				; of free handles
	mov	ds:[loaderVars].KLV_handleFreeCount, ax
	cmp	ax, FREE_HANDLE_DESPERATION_THRESHOLD
	jbe	notifyThresholdReached

finish:
	pop	ax
	call	SafePopf			;Restore interrupt state
	ret

	; error -- handle table full
	; must do something

AH_error:
EC <	cmp	ds:[loaderVars].KLV_handleFreeCount, 0			>
EC <	ERROR_NZ	CORRUPT_FREE_HANDLE_LIST			>

	ornf	ds:[exitFlags], mask EF_PANIC
	; for now, just die
	ERROR	HANDLE_TABLE_FULL

AllocateHandleNotifyStack	struct
    AHNS_es	word
    AHNS_di	word
    AHNS_si	word
    AHNS_ax	word
    AHNS_flags	word
AllocateHandleNotifyStack	ends

notifyThresholdReached:
	;
	; DO NOT DO THIS IF WE'RE IN AN INTERRUPT. We'll never be able to
	; context switch to the input manager to field the carriage return,
	; so the system will just hang...
	; 
	tst	ds:[interruptCount]
	jnz	finish

	; Do not attempt to do this if interrupts were off coming into this
	; routine

	push	si, di, es

	mov	si, sp
	test	ss:[si].AHNS_flags, mask CPU_INTERRUPT
	jz	noNotify

	; interrupts were on when we were called -- they can be on now

	INT_ON

	mov	ax, ds:[systemCounter].low
	push	ax				;save systemCounter.low
	sub	ax, ds:[lastLowHandleNotice]
	cmp	ax, LOW_HANDLE_NOTIFICATION_INTERVAL
	pop	ax				;recover systemCounter.low
	jbe	noNotify

	mov	ds:[lastLowHandleNotice], ax
ifdef GPC
	mov	al, KS_TOO_MUCH_AT_ONCE
else
	mov	al, KS_LOW_ON_HANDLES_1
endif
	call	AddStringAtMessageBuffer
	inc	di				;put second string after first
DBCS <	inc	di							>
	push	di
ifdef GPC
	mov	al, KS_TOO_MUCH_AT_ONCE_PART_TWO
else
	mov	al, KS_LOW_ON_HANDLES_2
endif
	call	AddStringAtESDI
	pop	di
	mov	si, offset messageBuffer
	mov	ax, mask SNF_CONTINUE
	call	SysNotify
	mov	ds:[messageBuffer][0], 0	; don't print the message when
						;  we exit, thanks.
noNotify:
	pop	si, di, es
	jmp	finish
	

AllocateHandle	endp

MemIntAllocHandle proc	far
		call	AllocateHandle
		ret
MemIntAllocHandle endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FreeHandle

DESCRIPTION:	Deallocate a handle from the handle table

CALLED BY:	EXTERNAL
		AllocHandleAndBytes, DoFreeNoDeleteSwap, CombineBlocks,
		RemoveThread

PASS:
	bx - handle to free
	ds - kernel segment

RETURN:
	interrupts unchanged
	bx, ds - unchanged

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Put passed handle at the front of the LRU list.

	handle->HM_addr = 0
	handle->nextFreeHandle = handleFreePtr
	handleFreePtr = handle

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

FarFreeHandle	proc	far
	call	FreeHandle
	ret
FarFreeHandle	endp

FreeHandle	proc	near
	pushf					;Save interrupt state

EC <	tst	bx							>
EC <	ERROR_Z	FREE_HANDLE_PASSED_BAD_HANDLE				>
EC <	test	bx,15							>
EC <	ERROR_NZ	FREE_HANDLE_PASSED_BAD_HANDLE			>
EC <	call	AssertDSKdata						>
EC <	cmp	ds:[bx][HG_type], SIG_FREE				>
EC <	ERROR_Z	FREEING_FREE_HANDLE					>

if	FULL_EXECUTE_IN_PLACE
EC <	cmp	bx, LAST_XIP_RESOURCE_HANDLE				>
EC <	ERROR_BE	FREEING_XIP_RESOURCE				>
endif


if TRACK_FINAL_FREE and ERROR_CHECK
	cmp	ds:[lastFreeBlock], bx
	ERROR_E	GASP_CHOKE_WHEEZE
elseif TRACK_FINAL_FREE
	PrintMessage <nuke this stuff before shipping>
	cmp	ds:[lastFreeBlock], bx
	jne	5$
	int	3
5$:
endif

NEC <	FAST_CHECK_HANDLE_LEGAL	ds					>

if TEST_TIMER_FREE
	cmp	ds:[bx].HG_type, SIG_TIMER
	jne	20$
	push	bp
	mov	bp, sp
	mov	bp, ss:[bp+4]
	cmp	bp, offset TimerRoutineOneShotFreeHandle
	je	10$
	cmp	bp, offset TimerSemaphoreFreeHandle
	je	10$
	cmp	bp, offset TimerSleepFreeHandle
	je	10$
	cmp	bp, offset TimerStopFreeHandle
	je	10$
	ERROR	INVALID_TIMER_FREE
10$:
	pop	bp
20$:
endif

	INT_OFF
	push	ax
	clr	ax
	mov	ds:[bx].HM_addr, ax		;mark handle as unused
	mov	ds:[bx].HM_owner, ax		;mark handle as unused
	mov	ds:[bx].HG_type, SIG_FREE	;mark handle as free (now done
						; in non-ec so we can tell if
						; a non-mem handle gets freed,
						; e.g. in VMOpen)
	mov	ax, ds:[loaderVars].KLV_handleFreePtr		;use a temp
	mov	ds:[bx].HM_next, ax		;was HM_nextFree
	mov	ds:[loaderVars].KLV_handleFreePtr, bx
	inc	ds:[loaderVars].KLV_handleFreeCount
	pop	ax
	call	SafePopf			;Restore interrupt state
	ret
FreeHandle	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DupHandle

DESCRIPTION:	Allocate a new handle and make it a duplicate of the handle
		passed.

CALLED BY:	INTERNAL
		SplitBlock, FreeBlockData

PASS:
	bx - handle to duplicate
	ds - kernel segment

RETURN:
	bx - new handle
	si - handle passed
	ds - unchanged

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

FarDupHandle	proc	far
	call	DupHandle
	ret
FarDupHandle	endp

DupHandle	proc	near

EC <	call	AssertDSKdata					>

	mov	si,bx
				;don't care what owner is set to
	call	AllocateHandle	;allocate a new handle for second block

	; copy data from old to new, si = old, bx = new

	push	cx		;save registers
	push	si
	push	di
	push	es

	segmov 	es, ds		;es = dest
	mov	di,bx

	mov	cx,size HandleMem / 2	;copy entire handle
	rep movsw

	pop	es
	pop	di
	pop	si		;restore registers
	pop	cx
	ret

DupHandle	endp
