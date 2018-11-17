COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodeUtils.asm

ROUTINES:
	Name			Description
	----			----------
   INT	FreeGeode		Free a GEODE
   INT	FindMatchingGeode	Search the list of GEODEs for a matching GEODE
   INT	AddGeodeToList		Add a GEODE to the GEODE list
   EXT  GeodeFindResource	Find a resource in a geode file

	GeodeMakeTemporaryCoreBlock	Make a temporary core block
				for the given geode file.

	GeodeSnatchResource	Load the specified resource (from a
				geode that has not been loaded) into a
				memory block.  This method avoids the
				overhead/side effects of loading the geode.
				The resource is language-patched if
				necessary.

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	Tony	9/88		Initial version
	PJC	1/26/95		Added GeodeSnatchResource.

DESCRIPTION:
	This file contains utility routines to handle GEODEs

	$Id: geodesUtils.asm,v 1.1 97/04/05 01:12:16 newdeal Exp $

------------------------------------------------------------------------------@

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindMatchingGeode

DESCRIPTION:	Search the list of GEODEs for a matching GEODE

CALLED BY:	FreeGeodeLow, InitResources

PASS:
	ds - core block for GEODE to try to match
	es - kernel variables

RETURN:
	carry - set if match found
	ax - segment address of matching GEODE (0 if none found)
	bx - handle of matching GEODE (locked if found)

DESTROYED:
	ax, bx, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

FindMatchingGeode	proc	far	uses	si, di, es
	.enter

AXIP <	push	dx							>
AXIP <	mov	dx, es:[geodeCount]					>
	mov	bx, es:[geodeListPtr]	;start at start of list

FMC_loop:
	clr	ax
	tst	bx			;(clears carry)
	jz	done			;if empty/end of list then no match

	call	NearLockES			;ax = segment also
	mov	si, offset GH_geodeFileType	;set up for compare (not
						;geodeAttr, as attributes can
						;differ during setup, owing to
						;GEODE_DRIVER_INITIALIZED and
						;whatnot)
	mov	di, si
	mov	cx,(GH_geodeRefCount-GH_geodeFileType) / 2
	repe cmpsw
	stc
	je	done

	mov	bx, es:[GH_nextGeode]		;move to next GEODE on list
	call	UnlockES
EC <	call	NullES							>
AXIP <	tst	dx				;only kernel loaded?	>
AXIP <	jnz	FMC_loop			;no, so continue	>
AXIP <	clr	bx				;else next must be NULL	>
	jmp	FMC_loop

done:
AXIP <	pop	dx							>

	.leave
	ret

FindMatchingGeode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeRemoveReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an extra reference to a geode, taking it out of
		memory if the last reference is removed.

CALLED BY:	GLOBAL
PASS:		bx	= handle of geode from which to remove a reference
RETURN:		carry set if geode last reference removed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeRemoveReference proc	far
		call	PushAll
		LoadVarSeg	ds
		call	FreeGeode
		call	PopAll
		ret
GeodeRemoveReference endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FreeGeode

DESCRIPTION:	Remove a GEODE from memory

CALLED BY:	GeodeFreeLibrary, ThreadDestroy

PASS:
	bx - handle of geode to free
	ds - kernel variables

RETURN:
	carry - set if geode removed

DESTROYED:
	ax, bx, cx, dx, si, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

FreeGeode	proc	near
	call	PGeode
	call	FreeGeodeLow
	GOTO	VGeode

FreeGeode	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FreeGeodeLow

DESCRIPTION:	Remove a GEODE from memory

CALLED BY:	FrGL_FreeLibraryUsages, FreeGeode, LoadGeodeLow, RemoveGeodes,
		UseLibraryLow

PASS:
	bx - handle of geode to free
	ds - kernel variables

RETURN:
	carry - set if geode removed

DESTROYED:
	ax, bx, cx, dx, si, di, bp, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

FreeGeodeLow	proc	far
EC <	call	ECCheckGeodeHandle					>

;	The kernel's coreblock is in ROM - don't dec the refcount

AXIP <	cmp	bx, handle 0						>
AXIP <	je	done							>
	call	NearLockES
	tst	es:[GH_geodeRefCount]
	jz	remove
	dec	es:[GH_geodeRefCount]	;decrement reference count
	jz	remove
	call	NearUnlock
EC <	call	NullES							>
AXIP <done:								>
	clc				;no geode destroyed
	ret
remove:

	; if a library -> call library's entry routine with exit code

	push	ds
	segmov	ds,es
	test	ds:[GH_geodeAttr], mask GA_LIBRARY
	jz	notLibrary
	test	ds:[GH_geodeAttr],mask GA_LIBRARY_INITIALIZED
	jz	notLibrary
	mov	di,LCT_DETACH
	call	CallLibraryEntry
notLibrary:
	; Clean up patch information, if necessary.
if USE_PATCHES
	call	GeodePatchFree
endif

	; if a driver -> call driver's DR_EXIT routine
	test	ds:[GH_geodeAttr], mask GA_DRIVER
	jz	notDriver
	test	ds:[GH_geodeAttr], mask GA_DRIVER_INITIALIZED
	jz	notDriver

	; call driver's exit routine

	call	PushAll

	LoadVarSeg	es
	dec	es:[geodeDriverCount]

	; remove the driver from the system driver list if needed

	mov	ax, ds:[GH_driverTabOff]
	mov	bx, ds:[GH_driverTabSegment]
	test	ds:[GH_geodeAttr], mask GA_SYSTEM
	jz	notSystemDriver
	mov	di, offset systemDriverList
findLoop:
	scasw
	jnz	notFound
	xchg	ax, bx
	scasw
	xchg	ax, bx
	jz	found
	dec	di
	dec	di
notFound:
	inc	di
	inc	di
EC <	cmp	di, es:[nextSystemDriver]				>
EC <	ERROR_Z	SYSTEM_DRIVER_NOT_FOUND_IN_LIST				>
NEC <	cmp	di, es:[nextSystemDriver]	; handle table overflow >
NEC <	je	notSystemDriver			; gracefully...		>
	jmp	findLoop

found:
	segmov	ds, es
	mov	si, di			;ds:si = source
	sub	di, size fptr		;es:di = dest
	mov	cx, ds:[nextSystemDriver]
	sub	cx, di
	shr	cx
	rep	movsw

	sub	ds:[nextSystemDriver], size fptr

notSystemDriver:

	mov	si, ax
	mov	ds, bx

	mov	di,DR_EXIT
CallDExit:
	ForceRef	CallDExit		;used by SWAT

	call	ds:[si].DIS_strategy	;call exit routine in driver
	call	PopAll
	andnf	ds:[GH_geodeAttr],not mask GA_DRIVER
notDriver:
	pop	ds

	; remove Geode from Geode list

	test	es:[GH_geodeAttr],mask GA_GEODE_INITIALIZED
	jz	10$
	call	FrGL_RemoveGeode
10$:

	; Free all library usages by this geode

	call	FrGL_FreeLibraryUsages

	; Look for another instance

	call	SwapESDS		; ds = core block, es = kernel vars

	call	FindMatchingGeode		;is there another instance ?
	jnc	noOtherInstance

	; Change ownership of shared resources to (next) oldest instance
	; Note this will do extra work if this isn't the oldest instance
	; going away here...

	; start off with the geodes semaphore
	mov	di, ds:[GH_geoHandle]	; get file
	mov	di, es:[di].HF_semaphore; get its semaphore
	mov	es:[di].HS_owner, bx	; set new owner

	mov	di,bx
	mov	si,ds:[GH_resHandleOff]	;remove shared code segments
	mov	cx, ds:[GH_resCount]
	dec	cx			; account for initial increment
					;  that skips the core block
FrGL_loop:
	inc	si
	inc	si
	mov	bx,ds:[si]		; fetch next handle
	push	es
	mov	es, es:[di].HM_addr	; es <- core block of other instance
	cmp	bx, es:[si]		; same handle ID? (resource table
					;  must be laid out the same way, so
					;  we can just use si...)
	pop	es
	jne	next			; no -- no ownership change needed
	mov	es:[bx].HM_owner, di	; yes -- change owner to next oldest
next:
	loop	FrGL_loop

	; If file handle open and owned by this geode, transfer ownership
	; to other geode so file not closed.

	test	ds:[GH_geodeAttr], mask GA_KEEP_FILE_OPEN
	jz	unlockOtherInstanceNoCloseFile
	mov	bx, ds:[GH_geoHandle]		; bx <- file handle
	mov	si, es:[bx].HG_owner		; si <- owner of file handle
	cmp	si, ds:[GH_geodeHandle]		; matches nuked geode?
	jne	unlockOtherInstanceNoCloseFile	; no. leave it alone
	mov	es:[bx].HG_owner, di		; transfer ownership
unlockOtherInstanceNoCloseFile:
	mov	bx, di
	call	NearUnlock
	jmp	noCloseFile			; notify debugger *this*
						;  geode is going away, even
						;  if shared resources aren't

	; No other instance exists, close the executable if it exists

noOtherInstance:
	test	ds:[GH_geodeAttr], mask GA_KEEP_FILE_OPEN
	jz	noCloseFile
	clr	bx			; clear out geoHandle
	xchg	bx,ds:[GH_geoHandle]
FXIP <	tst	bx							>
FXIP <	jz	noCloseFile						>
	mov	al,FILE_NO_ERRORS
	call	FileCloseFar

noCloseFile:
	;
	; since we are nuk'ing the geode, tell the debugger about it so that
	; it does not get confused...
	;
	mov	bx,ds:[GH_geodeHandle]		;must pass bx = geode handle
	mov	al,DEBUG_EXIT_GEODE
	call	FarDebugProcess			;notify debugger of Geode Exit

	;
	; common code for final and non-final geode instance situations.
	; Nuke blocks still owned by geode, etc.
	;
	mov	si,ds:[GH_geodeHandle]

	call	SwapESDS		; es = core block, ds = kernel vars

	;
	; Deal with private data first, while we're thinking of it and before
	; we grab the heap semaphore (else deadlock).
	;
	mov	ax, si
	call	ThreadPrivExit
	call	GeodePrivExit

	; free blocks owned by geode

	call	PHeap			; exclusive access to heap gotten now
					; and held until core block freed

	dec	ds:[geodeCount]		;one less GEODE in system
	test	es:[GH_geodeAttr], mask GA_LIBRARY
	jz	noRemoveLibrary
	dec	ds:[geodeLibraryCount]
noRemoveLibrary:
	call	FreeGeodeBlocks		;Any private data is freed here

if 0
	; if geode is an app then decrement this count

	test	byte ptr es:[GH_geodeAttr],mask GA_APPLICATION
	jz	noRemoveApp
	dec	ds:[geodeApplicationCount]
	jnz	noRemoveApp
	mov	ds:[exitFlag],TRUE	;if we remove the last one then done...
					;(flag checked in ThreadDestroy)
noRemoveApp:
endif
	;
	; Now we're sure ss doesn't point to the core block, remove the block
	; if the reference count is zero.
	;
	mov	bx, es:[GH_geodeHandle]
FXIP <	test	es:[GH_geodeAttr], mask GA_XIP				>
FXIP <	jnz	discardCoreblock					>
	call	DoFree
FXIP <common:								>
EC <	mov	bx, NULL_SEGMENT					>
EC <	mov	es, bx							>

	call	VHeap			; release the heap

	stc				;return geode destroyed
	ret

if	FULL_EXECUTE_IN_PLACE
discardCoreblock:
	call	MemUnlock
EC <	call	NullES							>
	call	MemDiscard
	jmp	common
endif

FreeGeodeLow	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FrGL_RemoveGeode

DESCRIPTION:	Remove a GEODE from the GEODE list for FreeGeodeLow

CALLED BY:	FreeGeodeLow

PASS:
	ds - kernel variables
	es - core block (locked)

RETURN:

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

FrGL_RemoveGeode	proc	near
	push	es

	mov	cx, es:[GH_nextGeode]
	mov	dx, es:[GH_geodeHandle]
AXIP <	cmp	dx, handle 0						>
AXIP <	je	done			; if XIP, can't unlink 1st han	>

	mov	bx,ds:[geodeListPtr]	;start of list
	cmp	bx,dx			;are we first on list ?
	jnz	notFirst		;if not then branch

	mov	ds:[geodeListPtr],cx	;update list head pointer
	jmp	done

removeLoop:
	call	UnlockES
EC <	call	NullES							>
notFirst:
EC <	tst	bx							>
EC <	ERROR_Z	CORRUPT_GEODE_LIST					>
	call	NearLockES
	mov	bx,es:[GH_nextGeode]
	cmp	bx, dx			;found ?
	jnz	removeLoop		;if not then loop

	mov	es:[GH_nextGeode],cx	;update list
	call	UnlockES
done:
	pop	es
	ret

FrGL_RemoveGeode	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FrGL_FreeLibraryUsages

DESCRIPTION:	Free the library usages for a GEODE

CALLED BY:	FreeGeodeLow, LoadGeodeLow, ProcessLibraryTable

PASS:
	ds - kernel variables
	es - core block (locked)

RETURN:

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

FrGL_FreeLibraryUsages	proc	far	uses si, di, es
	.enter
	mov	si,es:[GH_libCount]	;number of library usages to remove
	tst	si
	jz	done
	dec	si
	shl	si,1
	add	si,es:[GH_libOffset]	;si points at end of library table

FGLRU_loop:
	mov	bx,es:[si]		;get handle

if	NUMBER_OF_SYSTEM_GEODES gt 0
	mov	bx,cs			;test for system GEODE
	cmp	ax,bx
	jz	next
endif
	;
	; Call library entry to tell of a client going away.
	;
	push	si
	push	ds
	call	NearLockDS		;library core block in ds
	test	ds:[GH_geodeAttr], mask GA_LIBRARY
	jz	notLibrary
	mov	cx, es:[GH_geodeHandle]	;pass client handle in cx
	mov	di, LCT_CLIENT_EXIT	;call code
	call	CallLibraryEntry
notLibrary:
	call	NearUnlock
	pop	ds
	;
	; Now "free" the library geode -- reduces ref count and actually frees
	; if this was the last reference.
	;
	clc				;not removing process
	push	es
	call	FreeGeodeLow		;free it
	pop	es
	pop	si

if	NUMBER_OF_SYSTEM_GEODES gt 0
next:
endif

	dec	si
	dec	si
	cmp	si,es:[GH_libOffset]
	jae	FGLRU_loop

done:
	.leave
	ret

FrGL_FreeLibraryUsages	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FreeGeodeBlocks

DESCRIPTION:	Free all blocks owned by a GEODE except for the current stack
		and the core block

CALLED BY:	INTERNAL
		FreeGeodeLow

PASS:
	Exclusive access to heap
	si - process handle
	ds - kernel variable segment
	es - segment of locked coreblock

RETURN:

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	Tony	4/88		Initial version

------------------------------------------------------------------------------@

FreeGeodeBlocks	proc	near
	mov	bx, ds:[loaderVars].KLV_handleTableStart ;start at first handle

FGB_loop:
	push	bx

	cmp	bx,ss:[TPD_blockHandle]		;don't nuke the stack, please
	jz	next				;-- it will get nuked by 
						; ThreadDestroy()
	cmp	bx, si
	je	next			; Core block -- freed specially

	mov	al, ds:[bx].HG_type
	cmp	al, SIG_NON_MEM
	jb	isMem
	clr	ah
	shl	ax
	xchg	ax, bx
	mov	bx, cs:[fgbJumpTable][bx-SIG_NON_MEM*2]
	xchg	ax, bx
	cmp	ds:[bx].HG_owner,si		;test for owned by this process
						; jump is taken in specific
						; handler, if the comparison
						; is valid
	jmp	ax

fgbJumpTable	nptr.near	isUnknown,
				isUnknown,
				isHeapReservation,
				isFree,
				isQueue,
				isUnknown,
				isTimer,
				isEventData,
				isEventStack,
				isEventReg,
				isSavedBlock,
				isSemaphore,
				isVM,
				isFile,
				isThread,
				isFF
	CheckHack <length fgbJumpTable eq 16>


	;--------------------
HMA <isFF:								>
isMem:
	cmp	ds:[bx].HM_owner, si
	jne	next		; not owned by this geode

if 	FULL_EXECUTE_IN_PLACE
	cmp	bx, LAST_XIP_RESOURCE_HANDLE
	ja	freeMem

	test	ds:[bx].HM_flags, mask HF_DISCARDED
	jnz	next

;	If a geode has a discardable dgroup (a fixed block that is discardable)
;	then discard it, otherwise leave it alone.

	test	ds:[bx].HM_flags, mask HF_FIXED
	jnz	fixed
	cmp	ds:[bx].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	jne	discardBlock
fixed:
	test	ds:[bx].HM_flags, mask HF_DISCARDABLE
	jz	next
discardBlock:
EC <	cmp	ds:[bx].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED>
EC <	je	discardPseudoFixed					>
EC <	tst	ds:[bx].HM_lockCount					>
EC <	ERROR_NZ	XIP_RESOURCE_LEFT_LOCKED_WHEN_GEODE_EXITED	>

discardPseudoFixed::

;	We don't want to free any XIP resources, so just discard the data
;	associated with them.

	call	MemDiscard	;Discard this movable resource

;	If a movable resource was mistakenly left locked, clear out its lock
;	count.

	cmp	ds:[bx].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	je	next
	clr	ds:[bx].HM_lockCount
	jmp	next

freeMem:
endif

	; memory handle, free the block

	call	DoFree

isFree:
isEventData:			; will be freed by associated EVENT handle
NEC <isThread:			; won't happen>
isVM:				; sigh
next:
	pop	bx
	add	bx,size HandleMem
	cmp	bx,ds:[loaderVars].KLV_lastHandle
	jb	FGB_loop

	ret


	;--------------------
NOHMA <isFF:								>
isUnknown:
EC <	ERROR	UNKNOWN_HANDLE_TYPE_IN_HANDLE_TABLE			>
NEC <	jmp	next							>

	;--------------------
isEventStack:
isEventReg:
	cmp	ds:[bx].HE_next, si	; owner is in HE_next field...
	jnz	next		; not owned by this geode
	call	ObjFreeMessage
	jmp	next

	;--------------------
isFile:
	jne	next		; not owned by this geode
	call	FileCloseFar
	jmp	next

	;--------------------
isTimer:
	jne	next		; not owned by this geode
	INT_OFF
	cmp	ds:[bx].HG_type,SIG_TIMER	;timer handle? (use HG_type
						; again to protect against
						; expiration during above
						; initial check...)
	jne	timerNext
EC <	WARNING TIMER_NOT_STOPPED_BEFORE_GEODE_EXITED			>

	; timer handle -- stop the timer. We have to be careful if it's
	; a continual timer and pass an ID of 0, not the intervalOrID, or
	; else the timer won't be shut off.

	mov	al, ds:[bx].HTI_type
	cmp	al, TIMER_EVENT_CONTINUAL
	je	stopContinual
	cmp	al, TIMER_ROUTINE_CONTINUAL
	je	stopContinual
	mov	ax,ds:[bx].HTI_intervalOrID
stopTimer:
	call	TimerStop
timerNext:
	INT_ON
	jmp	next

stopContinual:
	clr	ax		; 0 => continual
	jmp	stopTimer


	;--------------------
isSemaphore:
	jne	next		; not owned by this geode
	
	call	ThreadFreeSem
	jmp	next

	;--------------------
isQueue:
	jne	next		; not owned by this geode
	call	GeodeFreeQueue
	jmp	next

	;--------------------
isSavedBlock:
	jne	next		; not owned by this geode
	call	FreeHandle
	jmp	next

	;--------------------
isHeapReservation:
	jne	next		; not owned by this geode
	mov	ds:[bx].HR_type, SIG_FREE
	clr	{word}ds:[bx].HR_owner
	clr	{word}ds:[bx].HR_size
	jmp	next

	;--------------------
EC <isThread:			; won't happen>
EC <	cmp	ds:[bx].HT_owner, si					>
EC <	jne	toNext							>

;	If doing a dirty shutdown (currentThread = 0), skip this check.

EC <	tst	ds:[currentThread]					>
EC <	jz	toNext							>
EC <	cmp	bx, ds:[currentThread]					>
EC <	ERROR_NE GASP_CHOKE_WHEEZE					>
EC <toNext:								>
EC <	jmp	next							>

FreeGeodeBlocks	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	RemoveGeodes

DESCRIPTION:	Remove any geodes remaining in the system

CALLED BY:	EXTERNAL
		EndGeos, ExitCleanly

PASS:

RETURN:
	ds	= kdata
DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

RemoveGeodes	proc	near	uses es
	.enter
	LoadVarSeg	ds
	;
	; Push the handles of all known drivers on the stack. We
	; assume there won't be *too* many left...
	;
	mov	bx, ds:[geodeListPtr]
	clr	cx
pushLoop:
	tst	bx
	jz	pushLoopDone
	call	NearLockES

	; System geodes do not get nuked this way, as they may be required
	; during the nuking of other things.
	test	es:[GH_geodeAttr], mask GA_SYSTEM
	jnz	noPush
	
	test	es:[GH_geodeAttr], mask GA_DRIVER
	jz	noPush

	inc	cx
	push	bx
noPush:
	mov	bx, es:[GH_nextGeode]
	call	UnlockES
EC <	call	NullES							>
	jmp	pushLoop
pushLoopDone:
	;
	; If cx still zero, we've nothing to do.
	;
	jcxz	done
freeLoop:
	;
	; Pop each handle in turn from the stack and call the driver's DR_EXIT
	; routine
	;
	pop	bx		; fetch handle

	cmp	ds:[bx].HM_owner, bx	; Geode go away due to other exits?
	jne	noNuke		; yes => don't free it now :)

	; The coreblocks of XIP geodes are not freed when the geode exits, they
	; are merely discarded, so check to see if the coreblock was discarded
	; before trying to free the geode...
		
FXIP <	test	ds:[bx].HM_flags, mask HF_DISCARDED			>
FXIP <	jnz	noNuke							>

	call	MemLock
	mov	es, ax

	; Clear the DRIVER_INITIALIZED attribute so if driver gets unloaded
	; by a later DR_EXIT call, it doesn't receive a second DR_EXIT call
	mov	ax, es:[GH_geodeAttr]
	andnf	es:[GH_geodeAttr], not mask GA_DRIVER_INITIALIZED

	les	si, es:[GH_driverTab]
	call	MemUnlock

	test	ax, mask GA_DRIVER_INITIALIZED
	jz	noNuke		; => didn't receive DR_INIT, so no DR_EXIT

	mov	di, DR_EXIT
	push	cx, ds
	call	es:[si].DIS_strategy
	pop	cx, ds

	call	ResetWatchdog
noNuke:
	loop	freeLoop
done:
	.leave
	ret

RemoveGeodes	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExitSystemDrivers

DESCRIPTION:	Exit any remaining system drivers

CALLED BY:	EXTERNAL
		EndGeos

PASS:

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/90		Initial version

-------------------------------------------------------------------------------@
ExitSystemDrivers	proc	near	uses es
	.enter

	; call the driver exit routine for all system drivers using the
	; system driver list

	LoadVarSeg	ds
	mov	si, ds:[nextSystemDriver]
	jmp	loopEntry

driverLoop:
	sub	si, 4
	mov	di, DR_EXIT
	push	si, ds
	lds	si, ds:[si]		;ds:si points at DriverInfoStruct
	call	{dword} ds:[si].DIS_strategy
	call	ResetWatchdog
	pop	si, ds
loopEntry:
	cmp	si, offset systemDriverList
	jnz	driverLoop

	.leave
	ret

ExitSystemDrivers	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	PGeode, VGeode

DESCRIPTION:	P or V the geode semaphore

CALLED BY:	INTERNAL
		GeodeLoad, GeodeEnum

PASS:
	none

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
-------------------------------------------------------------------------------@


FarPGeode	proc	far
	call	PGeode
	ret
FarPGeode	endp

PGeode	proc	near
	push	bx
	mov	bx, offset geodeSem
	jmp	SysLockCommon
PGeode	endp


FarVGeode	proc	far
	call	VGeode
	ret
FarVGeode	endp

VGeode	proc	near
	push	bx
	mov	bx, offset geodeSem
	jmp	SysUnlockCommon
VGeode	endp

Filemisc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                GeodeFindResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Locate a particular resource in a .geo file

CALLED BY:      GLOBAL

PASS:           bx      = file handle
                cx      = resource number
                dx      = offset in resource to which to position the file

RETURN:         cx:dx   = base position of the resource in the file
                ax      = size of the resource

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
                A geode is laid out as follows:

                        +---------------------------------------+
                        |                                       |
                        |        GeodeFileHeader up to		|
			|	   (but not including		|
			|      GFH_coreBlock.GH_geoHandle)	|
                        |                                       |
                        +---------------------------------------+
                        |                                       |
                        |       Imported library table made     |
                        |       of ImportedLibraryEntry         |
                        |               structures              |
                        |                                       |
                        +---------------------------------------+
                        |                                       |
                        |       Exported routine table made     |
                        |             of far pointers           |
                        |                                       |
                        +---------------------------------------+
                        |                                       |
                        |       Resource size table (words)     |
                        |                                       |
                        +---------------------------------------+
                        |                                       |
                        |    Resource position table (dwords)   |
                        |                                       |
                        +---------------------------------------+
                        |                                       |
                        |   Relocation table size table (words) |
                        |                                       |
                        +---------------------------------------+
                        |                                       |
                        |    Allocation flags table (words)     |
                        |                                       |
                        +---------------------------------------+

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeodeFindResource	proc far
execHeader      local	ExecutableFileHeader
resTableBase    local	dword
resSize         local	word
resPos          local	dword
	uses	ds, si, di
	.enter
	;
	; Preserve the resource # and offset where we can get at them easily
	;
	push  dx, cx
	;
	; Read in the entire ExecutableFileHeader (we need a number of fields in
	; it and I don't feel like kludging up a smaller structure for them)
	;
	mov     dx, offset GFH_execHeader
	clr     cx
	mov     al, FILE_POS_START
	call    FilePosFar

	segmov  ds, ss
	lea     dx, ss:[execHeader]
	mov     cx, size execHeader
	clr     al
	call    FileReadFar
	LONG	jc      errorPopCXDX
	;
	; Figure the location of the resource tables. We start from
	; the end of the geode header (which is *not* size GeodeFileHeader,
	; as that includes three variables from the end of GeodeHeader
	; that are not in the file).
	mov     di, offset GFH_coreBlock + offset GH_geoHandle
	clr     si
	;
	; Add in the size of the imported library table:
	;       importLibraryCount * size ImportedLibraryEntry
	;
	mov     ax, ss:[execHeader].EFH_importLibraryCount
	mov     dx, size ImportedLibraryEntry
	mul     dx
	add     di, ax
	adc     si, dx
	;
	; Plus the size of the exported entry table:
	;       exportEntryCount * size fptr
	;
	; 32 bit multiply by 4, shift twice
	mov     ax, ss:[execHeader].EFH_exportEntryCount
	clr     dx
	shl     ax
	rcl     dx
	shl     ax
	rcl     dx
	add     di, ax
	adc     si, dx
	;
	; This gives us the base of the resource tables
	;
	mov     ss:[resTableBase].low, di
	mov     ss:[resTableBase].high, si
	;
	; Position file at proper offset to get the size word for the resource
	;
	pop     ax              ; recover desired resource
	shl     ax
	push    ax
	add     di, ax
	adc     si, 0
	mov     dx, di
	mov     cx, si
	mov     al, FILE_POS_START
	call    FilePosFar
	;
	; Read the size word into our tee tiny buffer
	;
	lea     dx, ss:[resSize]
	mov     cx, size resSize
	clr     al
	call    FileReadFar
	jc      errorPopCXDX
	;
	; Reposition the file at the file-position dword for the resource
	;		
	mov     dx, ss:[resTableBase].low
	mov     cx, ss:[resTableBase].high
	mov     ax, ss:[execHeader].EFH_resourceCount
	shl     ax
	add     dx, ax          ; advance to end of size table
	adc     cx, 0

	pop     ax              ; recover res# * 2
	shl     ax              ; * 4...
	add     dx, ax
	adc     cx, 0
	mov     al, FILE_POS_START
	call    FilePosFar
	;
	; Fetch that thar file position...
	;
	lea     dx, ss:[resPos]
	mov     cx, size resPos
	clr     al
	call    FileReadFar
	jc      errorPopDX
	;
	; Now position the file at the desired offset w/in the resource
	;
	mov     dx, ss:[resPos].low
	mov     cx, ss:[resPos].high
	mov     di, dx          ; avoid future memory refs...
	mov     si, cx
	pop     ax              ; recover desired offset
	add     dx, ax

	adc     cx, 0
	mov     al, FILE_POS_START
	call    FilePosFar
	;
	; Position return values in return registers...
	;
	mov     dx, di
	mov     cx, si
	mov     ax, ss:[resSize]
done:
	.leave
	ret
errorPopCXDX:
	pop     cx      ; just clears the stack, doesn't restore CX
errorPopDX:
	pop     dx      ; restores DX, but who cares
	jmp     done
GeodeFindResource	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeSnatchResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the specified resource (from a geode that has not
		been loaded) into a memory block.  This method avoids
		the overhead/side effects of loading the geode.
		The resource is language-patched if necessary.

CALLED BY:	EXTERNAL: LoadExtendedInfo

PASS:           bx      = file handle
                cx      = resource number
                dx      = offset in resource to which to position the file

RETURN: 	if error,
			carry	= set
		else
			carry	= clear
	                ax      = address of locked resource block
			bx	= handle of locked resource block

DESTROYED:	nothing
SIDE EFFECTS:	nausea

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeSnatchResource	proc	far
		uses	cx,dx,si,di,bp
		.enter

EC <		call	ECCheckFileHandle				>
EC <		cmp	cx, 2						>
EC <		ERROR_B	RESOURCE_NOT_SNATCHABLE				>

if MULTI_LANGUAGE

	; Is multi-language mode on?

		call	IsMultiLanguageModeOn
		jc	findResource			; Not on.

	; Remember twice the resource number.

		mov	si, cx		; Resource number.
		shl	si, 1

	; Create a temporary core block to fool the patch code.

		call	GeodeMakeTemporaryCoreBlock
		jc	error
endif

findResource::

	; Position the geode file at our resource.

		call	GeodeFindResource
		jc	error			; Error in reading, so abort.

	; Allocate the block to hold the resource.

		mov	dx, bx			; dx <- file handle
	        push    ax			; Save resource size.
        	mov     cx, ALLOC_DYNAMIC_LOCK
	        call    MemAllocFar		
			; ax = locked segment of resource block
			; bx = handle of resource block
        	pop     cx
			; cx = resource size
	        jc      error			; Memory allocation error.

	; Read the resource into the new block.
	
		push	ds, bx		; Core block, resource block.
		mov	bx, dx		
			; bx = file handle
		mov	ds, ax		
			; ds = locked segment of resource block.
	        mov     es, ax		
			; es = locked segment of resource block.
        	clr     dx		; Read in at start of block.
	        clr     al
	        call    FileReadFar
		mov	ax, ds		; Segment of resource block.
		pop	ds, bx		; Core block, resource block.
			; ds = core block
			; bx = handle of resource block
	        jc      errorFreeBlock

if MULTI_LANGUAGE

	; Is multi-language mode on?

		call	IsMultiLanguageModeOn
		jc	noPatchDataFound		; Not on.

	; Are there any language patches?

		tst	ds:[GH_languagePatchData]
		jz	noPatchDataFound
else
		jmp	noPatchDataFound
endif

if MULTI_LANGUAGE

	; Search the language patch list.

		push	bx		; Resource block handle.
		mov	bx, ds:[GH_languagePatchData]
			; si = twice the resource number being loaded.
		call	SearchPatchResourceList
		pop	bx		; Resource block handle.
		jc	noPatchDataFound

	; Check if more room is needed to apply the patches than we
	; currently have.

		cmp	cx, es:[di].PRE_maxResourceSize
		jae	afterReAlloc		; Enough space already.

reAlloc::

	; Reallocate the resource to the maximum space needed while
	; patching this resource.

		push	cx
		mov	ax, es:[di].PRE_maxResourceSize
		mov	ch, mask HAF_NO_ERR
		call	MemReAlloc
		jc	error
			; ax = resource block segment
		pop	cx

afterReAlloc:

	; Perform patches on the resource.

		mov	dx, bx		; Resource block handle.
		call	GeodePatchResourceFar
		pushf			; Remember if we did relocations.

	; Resize the resource to its final size.

		add	cx, es:[di].PRE_resourceSizeDiff
		mov	ax, cx		; ax = post-patching resource size
		mov	ch, mask HAF_NO_ERR
		call	MemReAlloc
		jc	error
		popf			; Remember if we did relocations.
endif

error::
exit:

EC <		jc	exitWithErrorEC					>
EC <		call	ECCheckSegment		; ax			>
EC <		call	ECCheckMemHandleFar	; bx			>
EC < exitWithErrorEC:							>

		.leave
		ret			; <---  EXIT HERE!

noPatchDataFound:

		clc			; No relocations done.
		jmp	exit


errorFreeBlock:
		call    MemFree		; Free resource block.

		mov	bx, ds		; Temporary core block handle.
		call	MemFree		; Free temporary core block.
		stc
		jmp	exit

GeodeSnatchResource	endp


if MULTI_LANGUAGE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeMakeTemporaryCoreBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a temporary core block for the given geode file.

CALLED BY:	GeodeSnatchResource

PASS:		bx	= file handle

RETURN:		if error
			carry set
		else
			carry clear
			ds = temporary core block segment

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeMakeTemporaryCoreBlock	proc	near
		uses	ax,bx,cx,dx,di,es
		.enter

EC <		call	ECCheckFileHandle				>

	; Allocate space for a temporary core block.

		push	bx			; File handle.
		mov	ax, size GeodeHeader
        	mov     cx, ALLOC_DYNAMIC_LOCK
       		call    MemAllocFar
		mov	ds, ax			; Locked segment of block.
		mov	di, bx			; Core block handle.
		pop	bx			; File handle.

	; Position the file at the file's GeodeHeader.

		clr     cx
		mov	dx, offset GFH_coreBlock
		mov     al, FILE_POS_START
		call    FilePosFar

	; Read in partial GeodeHeader from file into core block.	

		mov	cx, GEODE_FILE_TABLE_SIZE	
			; GeodeHeader in file includes up to (but not
			; including) GH_geoHandle field.
		clr	dx
		clr	al
		call	FileReadFar
		jc	exit			; Error.

	; Read patch file information in.

		clr	ds:[GH_languagePatchData]
		mov	ds:[GH_geodeHandle], di	; Core block handle.
		LoadVarSeg	es, cx
		clr 	di
		call	GeodeOpenLanguagePatchFile
			; if ds:[GH_languagePatchData]
		clc

exit:
		.leave
		ret
GeodeMakeTemporaryCoreBlock	endp

endif ; (MULTI_LANGUAGE)

Filemisc	ends
