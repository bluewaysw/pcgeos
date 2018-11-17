COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodeResource.asm

ROUTINES:
	Name			Description
	----			-----------
    GLB ProcGetLibraryEntry	Fetch the address of a routine in a
				library. You can pass the result of this
				straight to ProcCallFixedOrMovable to call
				the routine.

    GLB ProcCallFixedOrMovable	Call an entry point where the segment value
				is actually either a segment or a handle
				shifted right 4.

    GLB PROCCALLFIXEDORMOVABLE_CDECL Call an entry point where the segment
				value is actually either a segment or a
				handle shifted right 4.

    GLB PROCCALLFIXEDORMOVABLE_PASCAL Call an entry point where the segment
				value is actually either a segment or a
				handle shifted right 4.

    GLB ProcInfo		Get information about a process

    GLB ProcCallModuleRoutine	Call a process' routine in another module.
				This routine is called by applications to
				call between modules.  Since it is
				important for this routine to be fast, code
				for locking and unlocking the destination
				code segment is inline.

    GLB GeodeDuplicateResource	Load a resource into a given block at
				memory

    INT LockDiscardedResource	Standard second half of locking resource
				block

    INT LockOwnersCoreBlockAndLibraries Lock a block's owner and imported
				libraries

    INT UnlockOwnersCoreBlockAndLibraries Unlock a block's owner and
				imported libraries

    INT LockDiscardedResource_callback Reload a resource from the resource
				file

    EXT LoadResourceLow		Load a code resource and do the relocations

    INT HandleToID		Given a resource handle, map it to a
				resource ID

    INT AssertInterruptsEnabled Given a resource handle, map it to a
				resource ID

    INT FarAssertInterruptsEnabled Given a resource handle, map it to a
				resource ID

    INT DoLoadResource		Load a resource and if it is a code
				resource do the relocations

    INT LockOrUnlockImportedLibraries Lock or unlock all imported libraries
				for a geode

    INT DoRelocation		Do a relocation

    INT LoadResourceData	Load the data for a resource

    EXT ResourceCallInt		Call a movable routine in a resource.
				There are actually 16 software interrupt
				handlers here

    EXT RestoreMovableInt	Restore the movable call interrupts

    GLB ECCheckDirectionFlag	Make sure the direction flag is clear, as
				the rest of the system expects...

    INT RecordModuleCall	Record a call made between modules

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file contains routines to handle GEODE resources.

	$Id: geodesResource.asm,v 1.1 97/04/05 01:12:10 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @----------------------------------------------------------------------

FUNCTION:	ProcGetLibraryEntry

DESCRIPTION:	Fetch the address of a routine in a library. You can pass
		the result of this straight to ProcCallFixedOrMovable to
		call the routine.

CALLED BY:	GLOBAL

PASS:
	ax - library entry point number
	bx - library handle

RETURN:
	bx:ax - library entry point (virtual far pointer)
	
DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	Jon	10/91		Substituted mov_trash for mov.
------------------------------------------------------------------------------@

ProcGetLibraryEntry	proc	far
	uses	si, ds
	.enter
EC <	call	AssertInterruptsEnabled					>
EC <	call	ECCheckGeodeHandle					>
EC <	call	ECCheckStack						>

	mov_tr	si, ax
	call	NearLockDS			;ds = core block of library

EC <	cmp	si,ds:[GH_exportEntryCount]				>
EC <	ERROR_AE	LIBRARY_ENTRY_NUMBER_TOO_LARGE			>

	shl	si				;*4 for entry into table
	shl	si
	add	si, ds:[GH_exportLibTabOff]

	lodsw					;ax = routine offset
	mov	si, ds:[si]			;si = virtual segment
						;((routine handle >> 4)|0xf000
						; or segment)
	call	NearUnlock
	mov	bx, si				;bx <- vsegment
	.leave
	ret

ProcGetLibraryEntry	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ProcCallFixedOrMovable

DESCRIPTION:	Call a routine given its virtual far pointer.

CALLED BY:	GLOBAL

PASS:
	ax - offset of routine
	bx - virtual segment
	ss:[TPD_dataAX] - data to pass in AX
	ss:[TPD_dataBX] - data to pass in BX

RETURN:
	return values from called routine

DESTROYED:
	bx, ax (unless returned by called routine)
	others by called routine

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

ProcCallFixedOrMovable	proc	far
	mov	ss:[TPD_callVector].offset, ax	;Save flags
	lahf

EC <    tst     bx                              ; bogus vseg?		>
EC <    jz      EC_callingZero                  ; jump if so. 		>

HMA <	cmp	bx, HMA_SEGMENT			;check hi-mem segment	>
HMA <	je	PCFOM_fixed						>
	cmp	bh,high MAX_SEGMENT
	jb	PCFOM_fixed			;if fixed then use direct call

	shl	bx,1				;convert to handle
	shl	bx,1
	shl	bx,1
	shl	bx,1

	sahf					;Restore flags

	mov_trash	ax, bx			;ax = handle

	mov	bx, ss:[TPD_stackBot]
	pop	ss:[bx].RCIIF_retAddr.offset
	pop	ss:[bx].RCIIF_retAddr.segment

	; Store a known constant in RCIIF_checkSum for the non-error-checking
	; build.
NEC <	mov	ss:[bx].RCIIF_checkSum, RCIIF_CHECKSUM_CONSTANT		>

	pushf					;Save flags
	mov	ss:[bx].RCIIF_handle, ax
	add	bx, size RCI_infoFrame
	mov	ss:[TPD_stackBot], bx

if	FULL_EXECUTE_IN_PLACE
if	TRACK_INTER_RESOURCE_CALLS
	;
	; remember the old resource handle, and update curXIPResourceHandle.
	;
	push	ax, bx, ds, bp
	mov	bp, bx				;use ss:[bp]
	mov_tr	bx, ax				;bx = handle
	LoadVarSeg	ds, ax
	mov	ax, ds:[curXIPResourceHandle]
	call	RecordInterResourceCall
	mov	ss:[bp][-(size RCI_infoFrame)].RCIIF_oldResource, ax
	mov	ds:[curXIPResourceHandle], bx
	pop	ax, bx, ds, bp
endif
	cmp	ax, LAST_XIP_RESOURCE_HANDLE
	ja	lockNonXIPResource

;	Save which XIP page is currently mapped in, and map in the page with
;	the code.

	push	ds
	LoadVarSeg	ds
	mov	ax, ds:[curXIPPage]
	mov	ss:[bx][-(size RCI_infoFrame)].RCIIF_oldPage, ax
	mov	bx, ss:[bx][-(size RCI_infoFrame)].RCIIF_handle
if PROFILE_LOG
	push	dx, di
	mov	dx, bx
	mov	di, ss:[TPD_callVector].offset
	InsertProcCallEntry	PET_PROC_CALL, 1, PMF_PROC_CALL, 5
	pop	dx, di
endif
	call	MapInXIPResource
	pop	ds

	mov	ss:[TPD_callVector].segment, bx
	jmp	afterLock
lockNonXIPResource:
endif

	mov_trash	bx, ax
if PROFILE_LOG
	push	dx, di
	mov	dx, bx
	mov	di, ss:[TPD_callVector].offset
	InsertProcCallEntry	PET_PROC_CALL, 1, PMF_PROC_CALL, 6
	pop	dx, di
endif
EC <	push	ds							>
EC <	LoadVarSeg	ds, ax						>
EC <	call	ECCheckNotAfterFilesClosed				>
EC <	pop	ds							>
	; NearLock may call LockDiscardedResource, which can in turn trigger
	; some EC code in a movable resource, and those movable calls will
	; overwrite the value in TPD_callVector that we have already set up
	; earlier.  So we have to preserve TPD_callVector here.
	; -dhunter 8/16/2000
EC <	push	ss:[TPD_callVector].offset				>
	call	NearLock
EC <	pop	ss:[TPD_callVector].offset				>
	mov	ss:[TPD_callVector].segment, ax

if	ANALYZE_WORKING_SET or RECORD_MODULE_CALLS
	push	ds
	LoadVarSeg	ds
if	ANALYZE_WORKING_SET
	call	WorkingSetResourceInUse
endif
if	RECORD_MODULE_CALLS
	push	ax
	mov	ax, ss:[TPD_callVector].offset
	call	RecordModuleCall
	pop	ax
endif	
	pop	ds
endif
FXIP <afterLock:							>

	popf					;Restore flags
	mov	ax, ss:[TPD_dataAX]		;emulate ProcCallModuleRoutine
	mov	bx, ss:[TPD_dataBX]
	jmp	RCI_call

PCFOM_fixed:
	sahf					;Restore flags
;
; Removed call to ECCheckBounds here, as you can get a deadlock problem when
; ECCheckBounds grabs the heap semaphore.
; If this is called by the filesystem driver, with a drive locked, and if
; another thread is trying to swap something in from the disk, the other
; thread will grab the heap semaphore first, *then* try to lock the drive,
; and *boom*, we'll deadlock...
;
;EC <	push	ds, si							>
;EC <	mov	ds, bx							>
;EC <	mov	si, ss:[TPD_callVector].offset				>
;EC <	call	ECCheckBounds						>
;EC <	pop	ds, si							>
 	push	bx				;push segment
	push	ss:[TPD_callVector].offset	;push offset
	mov	ax, ss:[TPD_dataAX]		;emulate ProcCallModuleRoutine
	mov	bx, ss:[TPD_dataBX]
	ret					;jump to routine

;
; If the caller to ProcCallFixedOrMovable was silly enough to call with a bogus
; virtual segment, slap them on the nose.
;
EC <EC_callingZero:							>
EC <  	ERROR 	REQUESTED_PROC_CALL_FIXED_OR_MOVABLE_TO_LEAP_INTO_SPACE >

ProcCallFixedOrMovable	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ProcCallFixedOrMovable_cdecl

C DECLARATION:	extern void
		    _cdecl ProcCallFixedOrMovable_cdecl(void (*routine)(), ...);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
FOMFrame	struct	; s/b same size as that for RCI to avoid confusing Swat
    FOMF_retf	fptr.far	; return address from PCFOM_CDECL or
				;  PCFOM_PASCAL
    FOMF_spAdj	word		; amount to subtract from SP after call
				;  to PCFOM to put args back on the stack
FOMFrame	ends

_ProcCallFixedOrMovable_cdecl	proc	far
	on_stack	retf

	mov	ax, size fptr	; need to "push" our part of the args (the
				;  routine to call) back on the stack after
				;  ProcCallFixedOrMovable so caller can pop
				;  everything off at once.
	
FOM_common	label	near

	; save return address & stack adjustment in pseudo-stack

	mov	bx, ss:[TPD_stackBot]
	popdw	ss:[bx].FOMF_retf
	mov	ss:[bx].FOMF_spAdj, ax
	lea	bx, ss:[bx][size FOMFrame]			
	mov	ss:[TPD_stackBot], bx

	on_stack	ax bx stackbot=FOMFrame.FOMF_retf

	; get address of routine to call (virtual fptr)

	popdw	bxax

	on_stack	stackbot=FOMFrame.FOMF_retf

	call	ProcCallFixedOrMovable			;call it

	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	lahf			;Preserve flags
	mov	bx, ss:[TPD_stackBot]
	sub	bx, size FOMFrame

	; return with original args on stack, if indicated by FOMF_spAdj

	sub	sp, ss:[bx].FOMF_spAdj

	mov	ss:[TPD_stackBot], bx
	pushdw	ss:[bx].FOMF_retf
	sahf			;Restore flags
	mov	bx, ss:[TPD_dataBX]
	mov	ax, ss:[TPD_dataAX]
	retf

_ProcCallFixedOrMovable_cdecl	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ProcCallFixedOrMovable_pascal

C DECLARATION:	extern void
		    _pascal ProcCallFixedOrMovable_pascal(...,
			    				  void (*routine)());

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
PROCCALLFIXEDORMOVABLE_PASCAL	proc	far
	mov	ss:[TPD_dataAX], ax
	mov	ss:[TPD_dataBX], bx

;	Don't change this to CLR, as we need to preserve the passed-in flags

	mov	ax, 0		; our args will be popped by common code before
				;  performing the call, and routine args will
				;  be popped by called function, so no
				;  adjustment of SP is required after
				;  ProcCallFixedOrMovable returns

	jmp	FOM_common

PROCCALLFIXEDORMOVABLE_PASCAL	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

FUNCTION:	ProcInfo

DESCRIPTION:	Get information about a process

CALLED BY:	GLOBAL

PASS:
	bx - process handle to get information for

RETURN:
	bx - handle of first thread

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

ProcInfo	proc	far
	push	ds
EC <	call	ECCheckProcessHandle					>

	LoadVarSeg	ds
	mov	bx,ds:[bx].HM_otherInfo

	pop	ds
	ret

ProcInfo	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ProcCallModuleRoutine

DESCRIPTION:	Call a process' routine in another module.  This routine is
		called by applications to call between modules.  Since it is
		important for this routine to be fast, code for locking and
		unlocking the destination code segment is inline.

		*** NOTE: The stack usage of this routine is guaranteed.  See
		***	  below.

CALLED BY:	GLOBAL

PASS:
	ax - offset to routine
	bx - handle
	ss:[TPD_dataAX] - data to pass in AX
	ss:[TPD_dataBX] - data to pass in BX

RETURN:
	return values from called routine

DESTROYED:
	bx, ax (unless returned by called routine)
	others by called routine

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	For speed, the code is inline.  This causes the routine to be
	somewhat long.

	Lock destination block
	Call routine
	Unlock destination block

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Registers ax and bx are destroyed before the handling routine is
	called.

	465 cycles (assuming that the block is in memory)

	If track-inter-resource-calls is true, the "on_stack"
	statements are not accurate (there should be an extra handle
	before "retf").

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Doug's code review added
	Jon	10/91		Minor speed optimization (486 -> 465 CPU cyc)
	kho	7/29/96		Track inter-resource calls added
-------------------------------------------------------------------------------@

PCMRStack struct
    PCMRS_flags		CPUFlags
    PCMRS_ax		word
if	FULL_EXECUTE_IN_PLACE
    PCMRS_oldPage	word
endif
    PCMRS_blockHandle	hptr
if	TRACK_INTER_RESOURCE_CALLS and FULL_EXECUTE_IN_PLACE
    PCMRS_curXIPResource hptr
endif
    PCMRS_retf		fptr.far
PCMRStack ends

if	FULL_EXECUTE_IN_PLACE
LockNonXIPResource	label	near
EC <	call	CheckToLock						>

EC <	call	ECCheckNotAfterFilesClosed				>
	FastLock1	ds, bx, ax, PCMR_1, PCMR_2	;52

if	ANALYZE_WORKING_SET
	push	ds
	LoadVarSeg	ds
	call	WorkingSetResourceInUse
	pop	ds
endif

	mov	ss:[TPD_callVector].segment,ax	;16
	jmp	afterLock

???_PCMR_2	label	near
	INT_ON
	call	LockDiscardedResource
	jmp	???_PCMR_1
endif


ProcCallModuleRoutine	proc	far
if	TRACK_INTER_RESOURCE_CALLS and FULL_EXECUTE_IN_PLACE
	;
	; Save our current resource handle, and update curXIPResourceHandle
	;
	push	ax
	push	ds
	LoadVarSeg	ds, ax
	mov	ax, ds:[curXIPResourceHandle]
	call	RecordInterResourceCall
	mov	ds:[curXIPResourceHandle], bx
	pop	ds
	XchgTopStack	ax				; ax restored, and top
							; of stack = old handle
endif
	
	on_stack	retf
EC <	call	AssertInterruptsEnabled					>
EC <	call	ECCheckResourceHandle					>
EC <	call	ECCheckStack						>
EC <	call	ECCheckBlockChecksumFar					>

	on_stack	bx retf
	push	bx				;15
	mov	ss:[TPD_callVector].offset,ax	;16

if PROFILE_LOG
	push	dx, di
	on_stack	di dx bx retf
	movdw	dxdi, bxax
	InsertProcCallEntry	PET_PROC_CALL, 1, PMF_PROC_CALL, 1
	pop	dx, di
	on_stack	bx retf
endif

	push	ds				;14
	on_stack	ds bx retf
	LoadVarSeg	ds, ax			;6 (4+2)

	pushf
	on_stack	cc ds bx retf

if	FULL_EXECUTE_IN_PLACE

	cmp	bx, LAST_XIP_RESOURCE_HANDLE
	ja	LockNonXIPResource

	; We are mapping in an XIP resource, so save the currently mapped
	; in XIP page, and map in the new one...

	mov	ax, ds:[curXIPPage]	;AX <- old XIP page that was mapped in
	call	MapInXIPResource	;Returns BX as segment of just-mapped
					; resource
	mov	ss:[TPD_callVector].segment, bx

endif

;	The least-frequent case is when this code is called for geodes outside
;	of the XIP image, so we move the code that locks down those blocks
;	outside of this routine, so the most common case (calling geode in
;	XIP resource) can continue executing without any jumps.

ife	FULL_EXECUTE_IN_PLACE
EC <	push	ss:[TPD_callVector].offset				>
EC <	call	CheckToLock						>
EC <	pop	ss:[TPD_callVector].offset				>

EC <	call	ECCheckNotAfterFilesClosed				>
	FastLock1	ds, bx, ax, PCMR_1, PCMR_2	;52

if	ANALYZE_WORKING_SET
	call	WorkingSetResourceInUse
endif

	mov	ss:[TPD_callVector].segment,ax	;16
endif	;ife FULL_EXECUTE_IN_PLACE
FXIP <afterLock	label near						>
EC <	tst	ss:[TPD_callVector].segment				>
EC <	ERROR_Z	PCFOM_CALL_WANTS_TO_LEAP_INTO_SPACE			>
	popf
	pop	ds				;12
	on_stack	bx retf
FXIP <	push	ax				;Save old XIP page	>
FXIP <	on_stack	xipPage bx retf					>

	mov	ax, ss:[TPD_dataAX]		;16
	mov	bx, ss:[TPD_dataBX]		;20
EC <	call	ECCheckDirectionFlag					>
CMRCall label	near
	ForceRef	CMRCall
	call	ss:[TPD_callVector]		;65

PCMR_ret label	near
	ForceRef	PCMR_ret

EC <	call	ECCheckDirectionFlag					>
EC <	call	ECCheckBlockChecksumFar					>

	;
	;	Now we save ax and flags to the stack, then
	;	exchange the return value in bx with the handle called.
	;
	push	ax				;15
	mov_tr	ax, bp			;3 - save bp in ax
	pushf					;14

FXIP <	on_stack	cc ax xipPage bx retf				>
NOFXIP <on_stack	cc ax bx retf					>

	mov	bp, sp				;2 - bp <- stack ptr
	xchg	ss:[bp].PCMRS_blockHandle, bx	;34 = 25 + 9(EA)
FXIP <	xchg	ss:[bp].PCMRS_oldPage, dx	;34 = 25 + 9(EA)	>
	push	ds				;14

FXIP <	on_stack	ds cc ax dx bx retf				>
NOFXIP <on_stack	ds cc ax bx retf				>

	mov_tr	bp, ax			;3 - restore bp

	LoadVarSeg	ds, ax			;6 (4 + 2)

if PROFILE_LOG
	xchg	dx, bx
	InsertProcCallEntry	PET_PROC_CALL, 0, PMF_PROC_CALL, 2
	xchg	bx, dx
endif
if	ANALYZE_WORKING_SET
	call	WorkingSetResourceNotInUse
endif
if	FULL_EXECUTE_IN_PLACE
	cmp	bx, LAST_XIP_RESOURCE_HANDLE
	ja	unlockNonXIPResource

;	Map in the old page, and return

	MapXIPPageInline	dx, TRASH_AX_BX_DX
endif

NOFXIP<	FastUnLock	ds, bx, ax, NO_NULL_SEG	;62			>
FXIP <afterUnlock:							>
	pop	ds				;12
EC <	call	NullSegmentRegisters					>
	popf					;12
	pop	ax				;12
FXIP <	pop	dx							>
	pop	bx				;12

if	TRACK_INTER_RESOURCE_CALLS and FULL_EXECUTE_IN_PLACE
	;
	; Restore our curXIPResourceHandle from stack
	;
	XchgTopStack	ax			; ax <- old handle, and
						; top of stack = ax to return 
	push	ds
	LoadVarSeg	ds
	mov	ds:[curXIPResourceHandle], ax
	pop	ds
	pop	ax
endif
	ret					;32



;*************************************************

	; special case of lock

	; FastLock2	ds, bx, ax, PCMR_1, PCMR_2, LockDiscardedResource

ife	FULL_EXECUTE_IN_PLACE
???_PCMR_2	label	near
	INT_ON
	; In some obscure case, LockDiscardedResource may trigger some EC code
	; in a movable resource, and those movable calls will overwrite the
	; value in TPD_callVector that we have already set up earlier.  So we
	; have to preserve TPD_callVector here. -dhunter 8/17/2000
EC <	push	ss:[TPD_callVector].offset				>
	call	LockDiscardedResource
EC <	pop	ss:[TPD_callVector].offset				>
	jmp	???_PCMR_1
endif

FXIP <unlockNonXIPResource:						>
FXIP <	FastUnLock	ds, bx, ax, NO_NULL_SEG	;62			>
FXIP <	jmp	afterUnlock						>
ProcCallModuleRoutine	endp

if	TRACK_INTER_RESOURCE_CALLS and FULL_EXECUTE_IN_PLACE

idata	segment
	;
	; data structure to store our profile about calls
	;
	; e.g. {1287, 26912, 100} means there are 100 calls from
	; resource 1287 to resource 26912. But to make searching easy,
	; we will have three different arrays, instead of one array of
	; three elements.
	; 
	fromResourceArray	hptr	RESOURCE_MAPPING_STAT_SIZE dup (?)
	toResourceArray		hptr	RESOURCE_MAPPING_STAT_SIZE dup (?)
	callCountArray		word	RESOURCE_MAPPING_STAT_SIZE dup (?)

	;
	; And we want to minimize number of page mapping. This is the
	; counts of page mapping.
	;
	mapPageCount		word

idata	ends

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordInterResourceCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record that one instance of call between two
		particular resources is made.

CALLED BY:	INTERNAL
PASS:		ax	= resource the call is made from
		bx	= resource the call is made to
RETURN:		nothing
DESTROYED:	nothing, flags preserved
SIDE EFFECTS:	
		callCountArray (and fromResource/toResourceArray
		if necessary) updated.

PSEUDO CODE/STRATEGY:
		if (from, to) resources pair is in the profile {
			increment count in callCountArray
			return
		} else {
	recordNewSlot:
			if unused slot available (ie.count==0) {
				use slot
			} else {
				purge low frequency slot
				jmp	recordNewSlot
			}
		}
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	7/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordInterResourceCall	proc	near
		uses	ax, cx, dx, es, di
		.enter
		pushf
	;
	; Get dgroup
	;
		LoadVarSeg	es, cx			; es <- dgroup
	;
	; See if (from, to) resource pair is found in our profile
	;
	; 1. Search (from) in fromResourceArray
	;
		mov	di, offset fromResourceArray
		mov	cx, length fromResourceArray
searchFrom:
		repnz	scasw
		jnz	noFromMatch
	;
	; 2. See if (to) field match. If not, search (from) again.
	;
	;    Note: es:[di] points to the element after the target.
	;
		cmp	es:[di][-(size word)+(size fromResourceArray)], bx
		jne	searchFrom
	;
	; 3. Found it! Increment count and leave
	;
		inc	{word}es:[di][-(size word)+(size fromResourceArray)*2]
		jmp	quit
noFromMatch:
	;
	; 1. Find an empty slot for the resource mapping pair.
	;
		mov_tr	dx, ax				; dx <- (from)
lookForEmptySlot:
		clr	ax				; search for 0
		mov	cx, length callCountArray	; size
		mov	di, offset callCountArray
		repnz	scasw
		jnz	noEmptySlot
	;
	; 2. Found an empty slot! Use it.
	;    Update callCountArray, toResourceArray and fromResourceArray.
	;
		mov	{word} es:[di][-(size word)], 1
		mov	es:[di][-(size word)-(size fromResourceArray)], bx
		mov	es:[di][-(size word)-(size fromResourceArray)*2], dx
		ForceRef toResourceArray
		jmp	quit
noEmptySlot:
		call	PurgeSlotsWithLowFrequency
		jmp	lookForEmptySlot
quit:
		popf
		.leave
		ret
RecordInterResourceCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PurgeSlotsWithLowFrequency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Purge all slots with low frequencies. We start with
		frequency == 1, and go up if we cannot find any victim.

CALLED BY:	INTERNAL
PASS:		es	== dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		victim = 0
		loop {
			victim++
			if (find slots with count == victim) {
				purge all such slots
				return
			}
		}

		Ultimately some slots will be cleared.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	7/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PurgeSlotsWithLowFrequency	proc	near
		uses	ax, cx, di
		.enter
EC <		WARNING	PURGE_LOW_FREQUENCY_SLOTS			>
	;
	; victim := 0
	;
		mov	ax, 0
	;
	; 1. Find the first instance of resource pairs where count==
	;    victim.
	;
noVictimFound:
		inc	ax				; search for next
							; victim
		mov	cx, length callCountArray
		mov	di, offset callCountArray
		repnz	scasw
		jnz	noVictimFound
	;
	; 2. Found a slot with frequency == victim. Make the slot zero, and
	;    search for next slot with the same frequency.
	;
purgeMore:
		mov	{word}es:[di][-(size word)], 0
		jcxz	quit				; if no more element,
							; quit
		repnz	scasw
		jz	purgeMore			; continue if
							; we have match
quit:
		.leave
		ret
PurgeSlotsWithLowFrequency	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeDuplicateResource

DESCRIPTION:	Load a resource into a new block of memory

CALLED BY:	GLOBAL

PASS:
	bx - resource handle to duplicate

RETURN:
	bx - handle of newly allocated resource

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Add EC code to ensure block is big enough!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

ObjectLoad	segment resource

GeodeDuplicateResource	proc	far	uses ax, cx, dx, si, bp, ds, es
	.enter

	;
	; Gain the exclusive right to load things from this executable.
	; 
	LoadVarSeg	ds
	call	LoadResourcePrelude	; si <- owned file handle

	;
	; save flags so we can set HF_LMEM once the block is loaded, if it's
	; needed.
	;
	mov	al, ds:[bx].HM_flags
	push	ax

	;
	; Allocate a block (locked) of the same size as the resource.
	; 
	mov	bp, bx			;bp saves source
	mov	ax, MGIT_SIZE
	call	MemGetInfo		;ax = size
	mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or \
			mask HF_SWAPABLE or mask HF_SHARABLE
	call	MemAllocFar		;allocate new block and lock it

	;
	; Load in the resource, relocating anything for the resource itself
	; to be for the block we just allocated.
	; 
	mov	cx, bx				;cx = dest block
	xchg	bx, bp				;bx = resource, bp = dest
if USE_PATCHES
	; The patch code needs the handle of the destination block in
	; SI so that it can reallocate it if necessary
	push	si
	mov	si, cx
endif
	call	LoadResourceLow
if USE_PATCHES
	pop	si
endif
	mov	al,DEBUG_DISCARD		;no, we really did not load
	call	FarDebugMemory			;the resource

	;
	; Release the executable file and core blocks while we've still got the
	; resource handle in BX
	; 
	call	LoadResourceEpilude

	;
	; Set the HF_LMEM bit of the duplicate, if it's set for the resource.
	; 
	mov	bx, bp				;bx = dest
	pop	ax				;recover flags
	andnf	al, mask HF_LMEM
	ornf	ds:[bx].HM_flags, al

	;
	; Release the new block.
	; 
	call	MemUnlock

	.leave
	ret

GeodeDuplicateResource	endp

ObjectLoad	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadResourcePrelude
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare to load a resource into memory, either into its
		own block or into another one.

CALLED BY:	(INTERNAL) LockDiscardedResource, GeodeDuplicateResource
PASS:		ds	= dgroup
		bx	= resource being loaded
RETURN:		si	= file handle (for passing to LoadResourceEpilude)
		owner & library core blocks locked down
DESTROYED:	es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadResourcePrelude proc	far
	.enter
if	MOVABLE_CORE_BLOCKS
	call	LockOwnersCoreBlockAndLibraries
endif
	;
	; Gain the exclusive right to load a resource for this geode by P'ing
	; the semaphore in the executable's file handle.
	; 
	mov	si, ds:[bx].HM_owner
	mov	es, ds:[si].HM_addr	; es <- owner core block (already
					;  locked)

	;
	; Grab the FS Info resource shared.  We don't actually need
	; it, we just want to make sure that someone else doesn't
	; already have it locked exclusive, since, if they do, they
	; might also have the heapSem locked, which would mean that we
	; would block with the geoHandle locked while going for the
	; heapSem, while the other thread blocks holding the heapSem,
	; going for the geoHandle.  Fail case is during 
	; DosExecSuspend/Unsuspend. 
	;

	call	FSDLockInfoShared

	mov	si, es:[GH_geoHandle]	; ds:si <- HandleFile

if _FXIP or FAULT_IN_EXECUTABLES_ON_FLOPPIES
	tst	si
	jz	exit
endif

	; We used to use a semaphore to allow only one thread at a time
	; to load a resource, but now we are using a threadlock so
	; that we can recursively load resources.  This is required
	; since we allow the async biffing of VM based Object blocks.
	; An example:  we are trying to load in a resource, so we need
	; to find room.  One of the blocks we toss out is an Object
	; block requiring relocation.  This locks down the owner and
	; any imported libraries which may include our initial
	; resource.
	push	bx
	mov	bx, ds:[si].HF_semaphore	; get the semaphore handle
	call	ThreadGrabThreadLock
	pop	bx

exit::
	.leave
	ret
LoadResourcePrelude endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadResourceEpilude
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish loading a resource, unlocking that which was locked
		in LoadResourcePrelude

CALLED BY:	(INTERNAL) LockDiscardedResource, GeodeDuplicateResource
PASS:		ds	= dgroup
		si	= file handle returned by LoadResourcePrelude
		bx	= handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadResourceEpilude proc	far
	.enter

if _FXIP or FAULT_IN_EXECUTABLES_ON_FLOPPIES
	tst	si
	jz	noV
endif

;
; see LoadResourcePrelude for comment on the semaphore to ThreadLock change
;
	push	bx
	mov	bx, ds:[si].HF_semaphore
	call	ThreadReleaseThreadLock
	pop	bx

noV::

if	MOVABLE_CORE_BLOCKS
	call	UnlockOwnersCoreBlockAndLibraries
endif

	call	FSDUnlockInfoShared

	.leave
	ret
LoadResourceEpilude endp
	

COMMENT @----------------------------------------------------------------------

FUNCTION:	LockDiscardedResource

DESCRIPTION:	Standard second half of locking resource block

CALLED BY:	MemLock, ...

PASS:
	ds - kdata
	bx - handle

RETURN:
	ax - handle (locked)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

LockDiscardedResource	proc	far	uses dx, si, es
	.enter

	call	LoadResourcePrelude		;si = file handle

	;
	; Now do the standard stuff of reallocating, loading, etc. The callback
	; routine will release the heap semaphore during the read, but that's
	; ok, as the only way for this resource to come in is via this routine,
	; and the other thread will block on the executable file handle.
	; 
	mov	dx, offset LockDiscardedResource_callback
	call	FullLockReload			;ax <- segment

loaded::

	call	LoadResourceEpilude

	.leave
	ret
LockDiscardedResource	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LockOwnersCoreBlockAndLibraries

DESCRIPTION:	Lock a block's owner and imported libraries

CALLED BY:	INTERNAL

PASS:
	bx - block

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
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

if	MOVABLE_CORE_BLOCKS
LockOwnersCoreBlockAndLibraries	proc	far	uses ax, bx, dx, ds
	.enter
	call	MemOwner
	call	NearLockDS

ife DELAY_LIBRARY_CORE_BLOCK_LOCK
	; lock imported libraries (since relocations will need them and we
	; can't lock them later)

	mov	dx, offset NearLock
	call	LockOrUnlockImportedLibraries
endif
	.leave
	ret

LockOwnersCoreBlockAndLibraries	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	UnlockOwnersCoreBlockAndLibraries

DESCRIPTION:	Unlock a block's owner and imported libraries

CALLED BY:	INTERNAL

PASS:
	bx - block

RETURN:
	none (flags preserved)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

if	MOVABLE_CORE_BLOCKS
UnlockOwnersCoreBlockAndLibraries	proc	far	uses ax, bx, dx, ds
	.enter
	pushf

	call	MemOwner
ife	DELAY_LIBRARY_CORE_BLOCK_LOCK
	call	MemDerefDS

	; lock imported libraries (since relocations will need them and we
	; can't lock them later)

	mov	dx, offset NearUnlock
	call	LockOrUnlockImportedLibraries
endif
	call	NearUnlock

	popf
	.leave
	ret

UnlockOwnersCoreBlockAndLibraries	endp
endif



COMMENT @-----------------------------------------------------------------------

FUNCTION:	LockDiscardedResource_callback

DESCRIPTION:	Reload a resource from the resource file

CALLED BY:	LockDiscardedResource

PASS:
	bx - handle passed (HM_addr NOT valid)
	si - temporary handle (HM_addr valid, HM_otherInfo NOT valid, locked)
	ds - dgroup
	geode of owner - locked
	exclusive access to heap

RETURN:
	none

DESTROYED:
	ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

-------------------------------------------------------------------------------@

LockDiscardedResource_callback	proc	near
	mov	ax, ds:[si].HM_addr	;ax = address to load at
	;
	; For XIP handles, we don't need to go to the file system, and we
	; *do* want the added synchronization provided by the heap semaphore,
	; so don't P/V the heap sem.
	;
FXIP <	cmp	bx, LAST_XIP_RESOURCE_HANDLE				>
FXIP <	jb	skipVHeap						>
	;
	; Release the heap lock (new memory is locked) so it's not grabbed
	; when we go to the filesystem to read the stuff in. This allows us
	; to execute things over the remote filesystem. There's no problem
	; with another thread trying to load the resource in at the same
	; time, as LockDiscardedResource P'ed the executable file handle to
	; prevent exactly that.
	; 
	call	VHeap
FXIP <skipVHeap:							>
	mov	cx, bx		; cx <- handle for relocations to resource
	call	LoadResourceLow
FXIP <	cmp	bx, LAST_XIP_RESOURCE_HANDLE				>
FXIP <	jb	skipPHeap						>
	;
	; Return with exclusive access to the heap again, so the caller can
	; release it :)
	;

if FAULT_IN_EXECUTABLES_ON_FLOPPIES

	; if there is no executable file for this block then we need
	; to free the special block that had the data and relocations
	; 1) because we don't need it anymore
	; 2) because HM_usageValue will be overwritten soon

	push	ds
	mov	di, ds:[bx].HM_owner		;di = core block handle
	mov	ds, ds:[di].HM_addr		;ds = core block
	tst	ds:[GH_geoHandle]
	pop	ds
	jnz	haveAFile

	andnf	ds:[bx].HM_flags, not mask HF_DISCARDABLE
	push	bx
	mov	bx, ds:[bx].HM_usageValue
	call	MemFree
	pop	bx
haveAFile:

endif
	
	call	PHeap
FXIP <skipPHeap:						>
	ret

LockDiscardedResource_callback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadResourceLow

DESCRIPTION:	Load a code resource and do the relocations

CALLED BY:	EXTERNAL
		PreLoadResources, LockDiscardedResource_callback,
		GeodeDuplicateResource

PASS:
	heap lock NOT grabbed
	exclusive access to executable file
	core blocks of owner and imported libraries locked

	ax - segment address of temporary block into which resource
	     will be loaded
	bx - resource handle, allocated to correct size.
		HM_addr = 0
		HM_size valid
	cx - handle of destination block
	
	if USE_PATCHES assembly constant is set, then
	si - handle of AX


RETURN:
	none

DESTROYED:
	cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

------------------------------------------------------------------------------@

LoadResourceLow	proc	far	uses bp, ds, es
	.enter

	push	ax, bx, si

	mov	bp, bx
	push	cx
	LoadVarSeg	ds
EC <	cmp	ax, ds:[loaderVars].KLV_heapEnd				>
EC <	ERROR_AE	SEGMENT_PASSED_TO_LOAD_RESOURCE_LOW_NOT_IN_HEAP	>
	mov_trash	dx, ax		;save load address
	call	GetByteSize		; ax, cx <- # bytes
	call	HandleToID		;bx: handle -> ID
EC <	ERROR_C	CANNOT_FIND_RESOURCE					>

	;
	; Changed from "mov bx, si" to "xchg si, bx" so that patch
	; code can get the temp block's handle in BX and reallocate
	; the block if necessary.
	;
	xchg	si, bx
	shl	si			;si = resource ID * 2

	mov	ds,ax			;ds = core block of owner
loadResource::
	mov_tr	ax,dx			;pass load address
	pop	dx			;dx <- handle for relocations
	call	DoLoadResource

	mov	bx, ds:[GH_geodeHandle]
	call	NearUnlock
EC <	call	NullDS							>

	pop	ax, bx, si

	LoadVarSeg	es
	call	FarDebugLoadResource	;notify debugger of resource load
					;MUST PASS ES = KDATA
	.leave
	ret

LoadResourceLow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HandleToID

DESCRIPTION:	Given a resource handle, map it to a resource ID

CALLED BY:	FullObjLock, LoadResourceLow, TransferToVM, UnRelocateLow
		ECCheckResourceHandle

PASS:
	bx - handle

RETURN:
	carry - set if handle not found
	ax - core block to owner (locked, must be unlocked by caller)
		(if passed handle of coreblock, ax returned 0)
	bx - resource ID

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

HandleToID	proc	far	uses cx, dx, di, es
	.enter

EC <	call	AssertInterruptsEnabled					>

	LoadVarSeg	es
	mov	di, es:[bx].HM_owner	;di = owner
	cmp	di, FONT_MAN_ID
	je	notFound
if	FULL_EXECUTE_IN_PLACE

;	If we pass a non-resident coreblock handle here, something is
;	hideously wrong, as we should change the caller to detect coreblock
;	handles and do something special with them. Otherwise, we have to
;	change HandleToID to return some extra flag saying that the handle is
;	a coreblock handle, so the caller knows not to unlock it.

EC <	cmp	di, bx							>
EC <	jnz	notCore							>
EC <	test	es:[di].HM_flags, mask HF_DISCARDED			>
EC <	ERROR_NZ HANDLE_TO_ID_PASSED_NON_RESIDENT_COREBLOCK		>
EC <notCore:								>
endif

HMA <	cmp	es:[di].HG_type, SIG_UNUSED_FF				>
HMA <	je	isMem							>
	cmp	es:[di].HG_type, SIG_NON_MEM
	jae	notFound
HMA <isMem:								>
	xchg	bx, di			; bx = owner, di = handle
	call	NearLockES		; es = core block

	mov	cx, es:[GH_resCount]
	mov	ax, di			;ax = handle
	mov	dx, cx			;dx = count
	mov	di, es:[GH_resHandleOff]
	repne scasw			;leaves cx (# res - target - 1)

	jz	found			;(carry cleared by == comparison)
	call	NearUnlock
EC <	call	NullES							>

notFound:
	stc
found:
	lahf
	inc	cx
	sub	dx, cx
	mov	bx, dx
	sahf
	mov	ax, es			;return ax = core block
	.leave
	ret
HandleToID	endp

;---

if	ERROR_CHECK

	; ensure that interrupts are on here...

AssertInterruptsEnabled	proc	near
	pushf
	push	ax

	pushf
	pop	ax
	test	ax, mask CPU_INTERRUPT
	ERROR_Z	INTERRUPTS_OFF_WHEN_THEY_SHOULD_NOT_BE
	test	ax, mask CPU_DIRECTION
	ERROR_NZ DIRECTION_FLAG_SET_INCORRECTLY

	pop	ax
	popf
	ret

AssertInterruptsEnabled	endp

FarAssertInterruptsEnabled	proc	far
	call	AssertInterruptsEnabled
	ret
FarAssertInterruptsEnabled	endp

endif



COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoLoadResource

DESCRIPTION:	Load a resource and if it is a code resource do the relocations

CALLED BY:	INTERNAL
		LoadResourceLow, PreLoadResources

PASS:
	heap lock NOT grabbed
	exclusive access to executable file handle
	core blocks of owner and imported libraries locked
	ax - segment address of block into which resource data will be loaded
	bx - handle of ax
	cx - size of resource
	si - resource number * 2
	ds - core block of owner of resource (locked)
	dx - handle of block containing relocation
		in the case of GeodeDuplicateResource, this is the
		handle of the duplicate block, which is the same as
		BX.  In the case of LockDiscardedResource, this is the
		resource handle, which is the same as BP.
		In the case of PreLoadResources, DX, BX, and BP are
		the same
	
	bp - handle of block that relocation is relative to

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Call LoadResourceData to load in the code
	Allocate stack space for relocations
	Read in relocations
	Loop to do relocations

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

-------------------------------------------------------------------------------@

DoLoadResource	proc	far
	uses	es, di
	.enter

	push	ss:[TPD_dataAX], ss:[TPD_dataBX]

	mov	ss:[TPD_dataAX], dx
	mov	ss:[TPD_dataBX], bp

	; Load in the resource data.

if USE_PATCHES		
	call	GeodePatchLoadResource
	jc	toNoRelocations		; Relocations came from patch file.
	jmp	afterLoad

else
	call	LoadResourceData
endif

afterLoad::

	mov	es, ax			;save module address
if	FULL_EXECUTE_IN_PLACE
	test	ds:[GH_geodeAttr], mask GA_XIP
	jz	notXIP

	;We've loaded an XIP resource - we cannot do any relocations here,
	; but if the resource is an LMEM resource, then store the handle
	; of the block in the LMBH_handle field, in case we are being called
	; as part of a GeodeDuplicateResource.

	cmp	dx, bp		;Is the destination handle the same as the
				; source? If so, just exit (not part of
				; GeodeDuplicateResource).
	je	toNoRelocations

	push	ds							
	LoadVarSeg	ds						
	test	ds:[bp].HM_flags, mask HF_LMEM				
EC <	WARNING_Z	DUPLICATING_NON_LMEM_XIP_RESOURCE		>
	pop	ds							
	jz	toNoRelocations
	jmp	stuffLMBH_handle



notXIP:
endif

	add	si,ds:[GH_resRelocOff]
	mov	cx,ds:[si]		;size of relocation table
	jcxz	toNoRelocations

if FAULT_IN_EXECUTABLES_ON_FLOPPIES

	tst	ds:[GH_geoHandle]
	jnz	haveAFile

	; no file exists -- do relocations from the special block

relocFromMem::
	push	ds
	LoadVarSeg	ds
	mov	bx, ds:[bp].HM_usageValue
	call	MemLock
	mov	si, ds:[bp].HM_size
	pop	ds
	shl	si
	shl	si
	shl	si
	shl	si
	mov	bp, ax				;bp:si = relocations

	;bp:si = relocation table
	;ds = core block
	;es = new code segment
	;cx = size of relocation table (counter)

	push	bx
memRelocLoop:
	push	ds
	mov	ds, bp
	lodsw
	mov_tr	bx, ax			;bx = first word
	lodsw
	xchg	ax, bx			;ax = first word, bx = second word
	pop	ds

	push	cx, si, bp
	mov	cx, ss:[TPD_dataAX]
	mov	bp, ss:[TPD_dataBX]
	call	DoRelocation
	pop	cx, si, bp
	sub	cx, size GeodeRelocationEntry
	jnz	memRelocLoop

	pop	bx
	call	MemUnlock
	jmp	noRelocations

haveAFile:
endif

	; if there is only one relocation and if this is an lmem
	; block then skip it (the one relocation will always be for
	; LMBH_handle, which we can take care of quickly and easily without
	; going to the file)

	cmp	cx, size GeodeRelocationEntry
	jnz	notLMem
	push	ds
	LoadVarSeg	ds
	test	ds:[bp].HM_flags, mask HF_LMEM
	pop	ds
	jz	notLMem
FXIP <stuffLMBH_handle:							>
	mov	es:[LMBH_handle], dx

toNoRelocations:
	jmp	noRelocations

notLMem:
EC <	test	ds:[GH_geodeAttr], mask GA_XIP				>
EC <	ERROR_NZ	RELOCATING_XIP_GEODE				>


	;Allocate stack space for relocations

	mov	di, STACK_SPACE_FOR_LOAD_RELOCATIONS+30
	call	ThreadBorrowStackSpace
	push	di

	push	bp			;allocate local space for reloc table
	mov	ax, sp			;calculate stack space to allocate
	sub	ax, ss:TPD_stackBot
	sub	ax, STACK_RESERVED_FOR_INTERRUPTS + \
					STACK_SPACE_FOR_LOAD_RELOCATIONS
EC <	ERROR_BE	STACK_OVERFLOW					>
NEC <	jbe	useMinSize						>
	cmp	ax, MIN_RELOCATIONS * (size GeodeRelocationEntry)
	jae	gotSize
NEC <useMinSize:							>
	mov	ax, MIN_RELOCATIONS * (size GeodeRelocationEntry)
gotSize:

		CheckHack <(size GeodeRelocationEntry) eq 4>
	and	ax, not 3
	sub	sp, ax
	mov	bp, sp
	push	ax			;save stack space allocated

EC <	call	ECCheckStack						>

	; cx = size of relocation table

groupLoop:
	jcxz	done			;if no relocations then branch
	pop	ax
	push	ax
	mov	dx, cx			;set cx = size this pass, assume all
	cmp	cx, ax
	jbe	10$
	mov	cx, ax			;too big, do only one group
10$:
	sub	dx,cx			;compute relocations left (in dx)
	push	dx

	;Read in relocations

	push	ds
	mov	dx,bp			;address to read in
	mov	bx,ds:[GH_geoHandle]
	segmov	ds,ss
	mov	al,FILE_NO_ERRORS
	call	FileReadFar		;call MS-DOS read
EC <	ERROR_C	COULD_NOT_READ_RELOCATIONS				>
	pop	ds

	;Loop to do relocations

	clr	si

	;ss:bp - reloc table
	;ds = process's stack segment
	;es = new code segment
	;cx = size of relocation table to do this pass
	;si = counter

relocLoop:
	push	cx, si, bp
	mov	ax,word ptr ss:[bp][si].GRE_info ;load GeodeRelocationEntry
	mov	bx,ss:[bp][si].GRE_offset	 ;load offset of relocation
	mov	cx, ss:[TPD_dataAX]
	mov	bp, ss:[TPD_dataBX]
	call	DoRelocation
	pop	cx, si, bp
	add	si, size GeodeRelocationEntry
	cmp	si,cx
	jnz	relocLoop

	pop	cx
	jmp	groupLoop			;loop to do more

done:

	pop	ax
	add	sp, ax				;reclaim local space
	pop	bp

	pop	di
	call	ThreadReturnStackSpace

noRelocations:
	pop	ss:[TPD_dataAX], ss:[TPD_dataBX]

	.leave
	ret

DoLoadResource	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LockOrUnlockImportedLibraries

DESCRIPTION:	Lock or unlock all imported libraries for a geode

CALLED BY:	DoLoadResource

PASS:
	ds - core block
	dx - offset of routine

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
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ife DELAY_LIBRARY_CORE_BLOCK_LOCK
LockOrUnlockImportedLibraries	proc	near	uses ax, bx, cx, si
	.enter

	mov	si, ds:[GH_libOffset]
	mov	cx, ds:[GH_libCount]
	jcxz	done
libLoop:
	lodsw
	mov_tr	bx, ax
	call	dx
	loop	libLoop
done:
	.leave
	ret

LockOrUnlockImportedLibraries	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoRelocation

DESCRIPTION:	Do a relocation

CALLED BY:	ConvertIDToSegment, DoLoadResource

PASS:
	al - GeodeRelocationInfo:
		high nibble = GeodeRelocationSource
		low nibble = GeodeRelocationType
	ah - GRE_extra: extra data depending on relocation source
	bx - offset of relocation
	cx - handle of block containing relocation (handle of ES, not
	     necessarily the same as that being loaded)
	bp - handle of block that relocation is relative to (the one being
	     loaded)
	es - segment containing relocation
	ds - process's core block (locked)
	all core blocks for all imported libraries must be locked

RETURN:
	relocation inserted

UPDATE THIS
+
DESTROYED:
	ax, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Eric	2/23		optimizations

-------------------------------------------------------------------------------@


DoRelocation	proc	far

	push	ds

	; first, get the correct address based on the source

	mov	dx,ax
	and	dl,mask GRI_SOURCE		;dl = GRI_SOURCE
	and	al,mask GRI_TYPE		;al = GRI_TYPE
	mov	di,es:[bx]			;di = data at relocation

EC <	cmp	dl,GRS_KERNEL shl offset GRI_SOURCE			>
EC <	ERROR_Z	KERNEL_RELOCATION_TYPE_IS_OBSOLETE			>

	cmp	dl,GRS_LIBRARY shl offset GRI_SOURCE
	jz	isLibrary			;skip if is a library...

	;is a resource relocation

isResource::

EC <	cmp	dl,GRS_RESOURCE shl offset GRI_SOURCE			>
EC <	ERROR_NZ	BAD_GEODE_RELOCATION_SOURCE			>

EC <	cmp	al,GRT_FAR_PTR						>
EC <	ERROR_Z	BAD_GEODE_RELOCATION_RESOURCE_FAR_PTR			>
EC <	cmp	al,GRT_OFFSET						>
EC <	ERROR_Z	BAD_GEODE_RELOCATION_RESOURCE_OFFSET			>

	;resource relocation (di = resource #)

	shl	di, 1				;2 di = module# * 2
	add	di, ds:[GH_resHandleOff]	;di = offset of handle

;fetchAndStoreHandle:
	mov	si, ds:[di]			;si = handle
	cmp	al,GRT_HANDLE			;optimize -- if handle
	jz	doHandle

notHandle::
	LoadVarSeg ds, di			;6 (4+2)
	mov	di,ds:[si][HM_addr]		;assume fixed (use segment)
	test	ds:[si].HM_flags,mask HF_FIXED
	jnz	doSegment			;if fixed then store segment
						;(can't have CALL reloc to
						;fixed block...)
	cmp	ds:[si].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	jz	doSegment			; => pseudo-fixed, so treat as
						;  fixed

	cmp	al,GRT_SEGMENT
	LONG jne storeMovableInt		;=> must be CALL reloc...
						;optimization of this call not
						;worth the trouble...

	; convert handle to virtual segment

	shr	si, 1				;2 form handle >> 4 with
	shr	si, 1				;2 high four bits set to mark as
	shr	si, 1				;2 invalid segment.
	shr	si, 1				;2
	add	si, MAX_SEGMENT			;4

storeSI:
	mov	es:[bx],si
	pop	ds
exit1::
	ret

	; if the handle relocation is to the block from which the data were
	; loaded, use the handle of the block being relocated (differs for
	; duplicated blocks)

doHandle:
	cmp	si, bp
	jnz	storeSI

	mov	es:[bx],cx
	pop	ds
exit2::
	ret

	; if the segment relocation is to the block from which the data were
	; loaded, use the segment of the block being relocated (differs for
	; duplicated blocks)

doSegment:
	cmp	si, bp
	LONG jnz storeDI

	mov	es:[bx],es
	pop	ds
exit3::
	ret

;-----------------------------------------------------------

if DELAY_LIBRARY_CORE_BLOCK_LOCK

;This is called by FastLock1, above. (And it is called very rarely.)

fastLock2::
	FastLock2	ds, si, dx, DRL1, DRL2
	.UNREACHED
endif

;-----------------------------------------------------------

isLibrary:
	; library relocation

	clr	dx			; dx <- imported library # * 2
	mov	dl, ah
	shl	dx, 1			;2
	mov	si, ds:[GH_libOffset]
	add	si, dx			; ds:si = addr of library core block
					;  segment
	mov	si, ds:[si]		; si = handle of library

	; check for relocation to library handle itself. entry # is -1 for
	; library handle. 

   	inc	di
	jz	storeSI

isLibrary2::
	;fetch core block segment (si = handle of library)

	LoadVarSeg	ds, dx		;6 (4+2)	ds = kdata, dx = trash

ife DELAY_LIBRARY_CORE_BLOCK_LOCK
EC <	tst	ds:[si].HM_lockCount					>
EC <	ERROR_Z	DO_RELOCATION_LIBRARY_MUST_BE_LOCKED			>
	mov	ds, ds:[si].HM_addr	;ds = core block of TARGET
else
	FastLock1 ds, si, dx, DRL1, DRL2
					;sets dx = segment of library coreblock
	mov	ds, dx			;ds = segment of library coreblock
	mov	dx, si			;dx = handle of library
endif

	dec	di			; convert back to entry number

EC <	cmp	di,ds:[GH_exportEntryCount]				>
EC <	ERROR_AE RELOCATION_TO_INVALID_LIBRARY_ROUTINE_NUMBER		>

	shl	di,1				;di = routine #, make into
	shl	di,1				;offset
	add	di,ds:[GH_exportLibTabOff]	;di = ptr into target table
	mov	si,ds:[di].segment		;si = virtual segment of
						; target

	mov	di,ds:[di].offset		;di = offset of target

if DELAY_LIBRARY_CORE_BLOCK_LOCK
	;unlock the library's coreblock
	;	ds = segment of library coreblock
	;	dx = handle of library coreblock

	push	ax
	LoadVarSeg ds, ax			;6 (4+2) ds = kdata, ax = trash
	xchg	bx, dx				;bx = handle, dx = offset
	FastUnLock ds, bx, ax, NO_NULL_SEG	;unlock block whose handle is bx
	mov	bx, dx				;restore bx = offset to code
	pop	ax
endif

	cmp	al,GRT_SEGMENT			;if segment then just store it
	LONG jz	storeSI				;VERY COMMON BRANCH

isLibrary3::
	cmp	al,GRT_OFFSET			;if offset then just store it
	jz	storeDI				;VERY COMMON BRANCH

isLibrary4::
	cmp	al,GRT_HANDLE			;if handle then branch
	jz	libraryHandle			;VERY RARE BRANCH

isLibrary5::
	cmp	al,GRT_FAR_PTR			;if not far pointer then branch
	jz	libraryFarPtr			;VERY, VERY RARE BRANCH

libraryCall::					;fallthru VERY, VERY COMMON
EC <	cmp	al, GRT_CALL						>
EC <	ERROR_NZ BAD_GEODE_RELOCATION_TYPE				>

	;CALL type relocation to library

HMA <	cmp	si, HMA_SEGMENT					        >
HMA <	je	libraryFarPtr						>

	cmp	si, MAX_SEGMENT		;segment or handle ?
	jnb	libraryCall2		;skip if is a handle...
					;LESS COMMON BRANCH

libraryFarPtr:				;FALL THRU VERY COMMON
	;is a segment: treat as a farPtr as routine must be in fixed code

	mov	es:[bx+2], si			;store segment of routine
storeDI:
	mov	es:[bx], di
	pop	ds
exit4::
	ret

libraryCall2:
	; movable call type relocation to library

	mov	es:[bx+2], di			; offset goes in high word of
						;  far pointer
						; convert to handle
	shl	si, 1				;2 (faster than shl si, cl)
	shl	si, 1				;2
	shl	si, 1				;2
	shl	si, 1				;2

storeMovableInt:
	; call relocation for geode resource call (si = handle)

EC <	cmp	al, GRT_CALL						>
EC <	ERROR_NZ BAD_GEODE_RELOCATION_TYPE				>

	mov	byte ptr es:[bx][-1], INT_OPCODE

	mov	ax, si				;2	ax = handle
	shr	al, 1				;shift four bits of handle down
	shr	al, 1				; so they're recorded in the
	shr	al, 1				; interrupt number used
	shr	al, 1
	or	al, RESOURCE_CALL_INT_BASE
						;no need to put into DI
	mov	es:[bx], ax			;store es:[bx][0] with INT #
						;and es:[bx][1] with hand high
	pop	ds
exit5::
	ret


mapLibrarySegment:				;EXTREMELY RARE
	xchg	si, cx				; cx <- segment
	call	SegmentToHandle
	xchg	si, cx				; si <- handle, cx <- as passed
EC <	ERROR_NC BAD_GEODE_RELOCATION_LIBRARY_SEGMENT_NOT_FOUND		>

	mov	es:[bx],si
	pop	ds
exit6::
	ret

libraryHandle:				;VERY RARE
	; store handle of library entry. si is segment or handle >> 4.
	; if segment, we must map to handle. if handle >> 4, we must shift
	; it back before storing the value

HMA <	cmp	si, HMA_SEGMENT		;high-mem is a memory block	>
HMA <	je	mapLibrarySegment					>

	cmp	si,MAX_SEGMENT
	jb	mapLibrarySegment	;EXTREMELY RARE BRANCH
	
	shl	si, 1				;2 (faster than shl si, cl)
	shl	si, 1				;2
	shl	si, 1				;2
	shl	si, 1				;2

	mov	es:[bx],si
	pop	ds
exit7::
	ret
DoRelocation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapXIPPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an offset into the XIP image, this routine maps it in
		to addressable memory

CALLED BY:	GLOBAL
PASS:		dx - page of XIP image to bank in
		ds - kdata
RETURN:		bx - segment of map window 
DESTROYED:	nada (flags preserved)
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
	; far stub so the swat Stub can call this puppy
MapXIPPageFar	proc	far
	call	MapXIPPage
	ret
MapXIPPageFar	endp
ForceRef	MapXIPPageFar

MapXIPPage	proc	near	uses	ax, dx
	.enter
	MapXIPPageInline	dx, TRASH_AX_BX_DX
	mov	bx, ds:[loaderVars].KLV_mapPageAddr
	.leave
	ret
MapXIPPage	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyDataFromXIPImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies data out of the XIP image

CALLED BY:	LoadResourceData
PASS:		bx - handle of resource to load
		cx - # bytes to copy
		es:di - ptr to buffer to copy data into
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyDataFromXIPImageFar	proc	far
	call	CopyDataFromXIPImage
	ret
CopyDataFromXIPImageFar	endp

if	COMPRESSED_XIP
CopyDataFromXIPImage	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

	LoadVarSeg	ds
	ConvertHandleToImageOffset	bx,   dx,ax

	;DX - page of XIP image to copy data from
	;AX - offset into page from which to copy data
	;DS - dgroup
	;ES:DI - dest for data

	mov	bp, offset copy
	test	dx, 0x8000		;check compressed flag
	jz	continue
	mov	bp, offset uncompress
continue:
	and	dx, 0x7fff		;clear compressed flag

	push	ds:[curXIPPage]		;Save current XIP page number.
	call	MapXIPPage		;BX <- segment of mapped in page
	movdw	dssi, bxax		;DS:SI <- source
	call	bp			;COPY or UNCOMPRESS
	pop	dx			;Restore previous XIP page number.

	LoadVarSeg	ds
	call	MapXIPPage		;Restore previous XIP page.

	.leave
	ret

copy:
	shr	cx, 1
	rep	movsw
	adc	cx, cx
	rep	movsb
	retn

uncompress:
EC <	mov	ax, cx			;AX <- desired size		>
EC <	tst	cx			;CX				>
EC <	ERROR_Z ERROR_COMPRESSED_XIP_IMAGE_IS_HOSED			>
	call	LZGUncompress
EC <	cmp	ax, cx			;Compare with uncompressed size	>
EC <	ERROR_NE ERROR_COMPRESSED_XIP_IMAGE_IS_HOSED			>
	retn

CopyDataFromXIPImage	endp

else	; not COMPRESSED_XIP

CopyDataFromXIPImage	proc	near	uses	ax, bx, cx, dx, si, di, ds
	bytesToCopy	local	word \
			push	cx
	.enter

	LoadVarSeg	ds
	ConvertHandleToImageOffset	bx,   dx,ax
				;DX - logical page #
				;AX - offset into logical page

	push	ds:[curXIPPage]		;Save offset of data currently mapped
					; in.

loopTop:
	;DX - page of XIP image to copy data from
	;AX - offset into page from which to copy data
	;ES:DI - dest for data
	;DS - dgroup

	call	MapXIPPage		;Returns BX <- segment of mapped in
					; page, AX <- offset where data lies
	movdw	dssi, bxax
	

	;DS:SI <- src for data to copy
	;ES:DI <- dest for data to copy
	

;	Now that data has been mapped in, copy it to the destination.

	mov	cx, MAPPING_PAGE_SIZE
	sub	cx, si			;CX <- # bytes of data in this physical
					; page
	cmp	cx, bytesToCopy
	jbe	10$
	mov	cx, bytesToCopy
10$:
	clr	ax			;Go to the start of the next page
	inc	dx
if VG230_FULL_XIP and (MAPPING_PAGE_SIZE eq PHYSICAL_PAGE_SIZE * 2)
	inc	dx
endif

				;   to get to next page

	sub	bytesToCopy, cx
	rep	movsb			;
EC <	cmp	si, MAPPING_PAGE_SIZE					>
EC <	ERROR_A	-1							>

	LoadVarSeg	ds

	tst	bytesToCopy
	jnz	loopTop

;	Re-map whatever part of the image *used* to be here...

	pop	dx
	call	MapXIPPage
	.leave
	ret
CopyDataFromXIPImage	endp
endif	; COMPRESSED_XIP
endif	; FULL_EXECUTE_IN_PLACE


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoadResourceData

DESCRIPTION:	Load the data for a resource

CALLED BY:	DoLoadResource, GeodePatchLoadResource

PASS:
	ax - segment address to load resource
	cx - size of resource
	si - resource number * 2
	ds - core block of owner of resource (locked)

RETURN:
	ax, cx, dx, si, ds - same

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Get file position from table, move to file position
	Read in resource

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

-------------------------------------------------------------------------------@

LoadResourceData	proc	near

if	FULL_EXECUTE_IN_PLACE
	test	ds:[GH_geodeAttr], mask GA_XIP
	jz	loadNormalResource

;	Map the resource ID to a handle, and copy the data out.

	push	es, di, bx
	mov	bx, si
	add	bx, ds:[GH_resHandleOff]
	mov	bx, ds:[bx]	;BX <- handle of resource to load
	mov	es, ax	
	clr	di		;ES:DI <- dest to copy XIP image data
	call	CopyDataFromXIPImage
	pop	es, di, bx
	jmp	done

loadNormalResource:
else
EC <	test	ds:[GH_geodeAttr], mask GA_XIP				>
EC <	ERROR_NZ	LOADING_XIP_RESOURCE_FROM_NON_XIP_GEODE		>
endif
	push	bx, dx, ds

	push	cx			;save size
	push	ax			;save segment address

	;Get file position from table, move to file position

	push	si
	shl	si			;resource number * 4
	add	si,ds:[GH_resPosOff]
	mov	dx,ds:[si]		;put position in cx:dx
	mov	cx,ds:[si][2]
	pop	si
	mov	bx,ds:[GH_geoHandle]


if FAULT_IN_EXECUTABLES_ON_FLOPPIES

	; if no file then just copy the memory from HM_usageValue

	tst	bx
	jnz	haveAFile

loadFromBlock::
	mov	bx, si
	add	bx, ds:[GH_resHandleOff]
	mov	bx, ds:[bx]			;bx: handle of resource to load
	LoadVarSeg	ds
	mov	bx, ds:[bx].HM_usageValue	;bx: special data handle
	call	MemLock
	mov	ds, ax				;ds = special data block
	mov	dx, es				;dx saves es
	pop	es				;segment to load to
	pop	cx				;size
	push	si, di
	clr	si
	clr	di
	shr	cx
	rep	movsw				;copy data
	pop	si, di
	call	MemUnlock
	segmov	ds, es				;ds = segment read into
	mov	es, dx
	jmp	afterRead

haveAFile:

endif

	mov	al,FILE_POS_START
	call	FilePosFar		;call MS-DOS to move file pointer

	;Read in resource

	pop	ds			;recover segment to load into
	pop	cx			;recover size

	mov	al,FILE_NO_ERRORS
	clr	dx			;read at offset 0
	call	FileReadFar
afterRead::

	mov	ax, ds
	pop	bx, dx, ds
FXIP <done:								>
	ret

LoadResourceData	endp

if USE_PATCHES
LoadResourceDataFar	proc	far
	call	LoadResourceData
	ret
LoadResourceDataFar	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ResourceCallInt

DESCRIPTION:	Call a movable routine in a resource without using any
		extra stack space or nuking any registers.

CALLED BY:	EXTERNAL
		INT ??

PASS:
	interrupts off
	on stack: flags, return address
	in instruction stream called from:
		bytes 0 and 1:INT RESOURCE_CALL_VECTOR+b4-b7 of resource handle
		byte 2: high byte of resource handle
		byte 3 and 4: offset of call

RETURN:
	from called routine

DESTROYED:
	from called routine

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	830 cycles (assuming block is in memory)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@


; NOTE: THIS STRUCTURE IS DEFINED IN vidcomMacro.def IN THE VIDEO DRIVERS AS
;	VidRCI_infoFrame.  IF ANY CHANGES ARE MADE TO THIS STRUCTURE, THEY 
;	SHOULD BE MADE THERE TOO.
;
; *ACTUALLY*, I couldn't find this anywhere in vidcomMacro.def - it's just a
; lie, I guess.
;
RCI_infoFrame	struct
    RCIIF_retAddr	fptr.far
    RCIIF_handle	hptr
    RCIIF_checkSum	word
if	FULL_EXECUTE_IN_PLACE
    RCIIF_oldPage	word
if	TRACK_INTER_RESOURCE_CALLS
    RCIIF_oldResource	hptr
endif
endif
RCI_infoFrame	ends

RCI_stack	struct
    RCI_saveSI		word
    RCI_saveDS		word
    RCI_saveBX		word
    RCI_saveBP		word
    RCI_retAddr		fptr.far			;address called from
    RCI_intFlags	word
RCI_stack	ends

RCIIF_CHECKSUM_CONSTANT	equ	0adebh		; surprise, surprise...

ResourceCallInt		proc	far
	ON_STACK	iret
SSP <	TRAP_ON								>
if	SINGLE_STEP_PROFILING
	REAL_FALL_THRU	ResourceCallIntProfiling
ResourceCallInt	endp
ResourceCallIntProfiling	proc	far
	ON_STACK	iret
endif

	push	bp, bx, ds, si			;15, 15, 14, 15

	; we don't need interrupts off

	ON_STACK	si ds bx bp iret

	INT_ON					;2
EC <	call	ECCheckStack						>

	mov	bp,sp				;2

	; point ds:si at the cs:ip after the INT instruction

	lds	si,ss:[bp].RCI_retAddr		;33

	; fetch handle from interrupt number and following byte. bits
	; 4 through 7 of the handle are stored in bits 0 through 3 of the
	; interrupt number and are shifted up bit by bit interspersed with
	; longer instructions to make execution more efficient, I think.
	
	mov	bx, ds:[si-1]			;21
	shl	bl				;2
	mov	bp,ds:[si+1]			;21 - bp = offset
	shl	bl				;2
	mov	ss:[TPD_callVector].offset,bp	;21 - save offset
	shl	bl				;2

	; point ss:bp at pseudo-stack

	mov	bp,ss:[TPD_stackBot]		;20
	shl	bl				;2 - (bx now contains handle)

	add	si,3				;4
	mov	ss:[bp].RCIIF_retAddr.offset,si	;22 - store return frame on our
	mov	ss:[bp].RCIIF_retAddr.segment,ds;22 - private stack

	; Store a known constant in RCIIF_checkSum for the non-error-checking
	; build.
NEC <	mov	ss:[bp].RCIIF_checkSum, RCIIF_CHECKSUM_CONSTANT		>
	
if PROFILE_LOG
	push	dx,di
	mov	dx, bx
	mov	di, ss:[TPD_callVector].offset
	InsertProcCallEntry	PET_PROC_CALL, 1, PMF_PROC_CALL, 3
	pop	dx,di
endif
	; bx = handle of routine being called
	; ss:TPD_callVector.offset = offset of routine being called
	; ss:bp = RCI_infoFrame for current call with RCIIF_retAddr filled
	;  in.
	ON_STACK	si ds bx bp iret

	mov	ss:[bp].RCIIF_handle,bx		;22
	add	bp,size RCI_infoFrame		;4
	mov	ss:[TPD_stackBot],bp		;21

;	Old way uses BP - XIP still needs to stick values in RCI_infoFrame,
;	so we use SI instead (which gets restored below anyway)
;	LoadVarSeg	ds, bp			;6  (4+2)
	LoadVarSeg	ds, si

if	FULL_EXECUTE_IN_PLACE
if	TRACK_INTER_RESOURCE_CALLS
	;
	; remember the old resource handle, and update curXIPResourceHandle.
	;
	push	ax
	mov	ax, ds:[curXIPResourceHandle]
	call	RecordInterResourceCall
	mov	ss:[bp][-(size RCI_infoFrame)].RCIIF_oldResource, ax
	mov	ds:[curXIPResourceHandle], bx
	pop	ax
endif
	
	cmp	bx, LAST_XIP_RESOURCE_HANDLE
	ja	normalResource

;	Store index of currently-mapped-in-page so we can restore it later

	mov	si, ds:[curXIPPage]
	mov	ss:[bp][-(size RCI_infoFrame)].RCIIF_oldPage, si

;	Map in the desired XIP resource

	call	MapInXIPResource	;Returns BX = handle of XIP resource
	mov	ss:[TPD_callVector].segment,bx	;21
	jmp	common

;	Moved up here on Full-XIP systems, to avoid a double-branch in the
;	FastLock macro below (making it NotSoFastLock).

???_RCI_2:
	INT_ON
	xchg	ax, si			; preserve AX
	test	ds:[bx].HM_flags, mask HF_DISCARDED
	jnz	lockDiscarded

	; FullLockNoReload will trigger some EC code in a movable resource
	; if the AUTOMATICALLY_FIXUP_PSELF code is assembled in, and those
	; movable calls will overwrite the value in TPD_callVector that
	; we have already set up earlier, so we have to preserve
	; TPD_callVector here. -dhunter 8/16/2000
	
EC <	push	ss:[TPD_callVector].offset				>
	call	FullLockNoReload
EC <	pop	ss:[TPD_callVector].offset				>
	jc	lockDiscarded
	xchg	ax, si			; restore AX, SI <- segment (destReg
					;  of FastLock1, above)
	jmp	???_RCI_1

lockDiscarded:
	; In some obscure case, LockDiscardedResource may trigger some EC code
	; in a movable resource, and those movable calls will overwrite the
	; value in TPD_callVector that we have already set up earlier.  So we
	; have to preserve TPD_callVector here.  --- AY 8/5/96
EC <	push	ss:[TPD_callVector].offset				>
	call	LockDiscardedResource
EC <	pop	ss:[TPD_callVector].offset				>
	xchg	ax, si			; restore AX, SI <- segment (destReg
					;  of FastLock1, above)
	jmp	???_RCI_1

normalResource:
ifdef	XIP_DEBUGGING_VERSION
	mov	ss:[bp][-(size RCI_infoFrame)].RCIIF_oldPage, -1
endif
endif


if	ERROR_CHECK
	; Make sure we are not in interrupt time or a critical section.
	;
	; NOTE: In XIP-kernel, if the movable routine being called is in XIP,
	; the code won't reach here.  So we are not catching movable XIP
	; routine being called from interrupt code.  That's not to say
	; people are supposed to do so.  Rather, since there are probably
	; existing code that is already doing so, and we don't want to deal
	; with too many fatal errors now, we just decide to tolerate that.
	; --- AY 3/7/97
	tst	ds:[interruptCount]
	ERROR_NZ NOT_ALLOWED_TO_CALL_MOVABLE_ROUTINE_IN_INTERRUPT_CODE
endif	; ERROR_CHECK

EC <	call	ECCheckNotAfterFilesClosed				>

	FastLock1	ds, bx, si, RCI_1, RCI_2	;52

if	ANALYZE_WORKING_SET
	call	WorkingSetResourceInUse
endif
if	RECORD_MODULE_CALLS
	push	ax
	mov	ax, ss:[TPD_callVector].offset
	call	RecordModuleCall
	pop	ax
endif	
	mov	ss:[TPD_callVector].segment,si	;21
FXIP <common:								>
	pop	si				;12
	pop	ds				;12
	pop	bx				;12
	pop	bp				;12

	add	sp,4				;4 - trash return address
	popf					;12 - recover flags

;	Ensure that the trap flag is always set

SSP <	EnsureTrapSet							>

	ON_STACK	stackbot=RCI_infoFrame.RCIIF_retAddr

RCI_call	label	far
EC <	call	ECCheckDirectionFlag					>
EC <	call	ECCheckBlockChecksumFar					>
EC <	call	ECComputeRCIChecksum					>

EC <	pushf								>
EC <	tst	ss:[TPD_callVector].segment				>
EC <	ERROR_Z	RCI_CALL_WANTS_TO_LEAP_INTO_SPACE			>
EC <	popf								>

	call	ss:[TPD_callVector]		;65

RCI_ret label	far		;Used by SWAT
	ForceRef	RCI_ret

	InsertProcCallEntry	PET_PROC_CALL, 0, PMF_PROC_CALL, 4

EC <	call	ECCheckDirectionFlag					>
EC <	call	ECCheckBlockChecksumFar					>
EC <	call	ECCheckRCIChecksum					>

	; Use bp instead of bx to address the RCI_infoFrame, as we use
	; it 3 times, while FastUnLock uses the register only twice. So we
	; only need an override twice now, compared with three times when
	; bx was used -- ardeb 4/21/90

	pushf					;14
	push	ax				;15
	push	bp				;15
	push	ds				;14

	ON_STACK	ds bp ax cc stackbot=RCI_infoFrame.RCIIF_retAddr

	; take advantage of special "mov ax, <direct address>" opcode

	mov	ax,ss:[TPD_stackBot]		;16
	sub	ax,size RCI_infoFrame		;4
	mov	ss:[TPD_stackBot],ax		;16

	; you could theoretically save another cycle by replacing the
	; following mov_tr with a plain old mov (2 cycles instead of 3),
	; but tests showed no speed difference between the two.

	mov_tr	bp, ax				;3

	; load return address into callVector, since we can't really
	; push it with things on the stack already.

	mov	ax,ss:[bp].RCIIF_retAddr.offset	;21
	mov	ss:[TPD_callVector].offset,ax	;16
	mov	ax,ss:[bp].RCIIF_retAddr.segment ;21
	mov	ss:[TPD_callVector].segment,ax	;16


	LoadVarSeg	ds, ax
if 	FULL_EXECUTE_IN_PLACE
if	TRACK_INTER_RESOURCE_CALLS
	;
	; restore our curXIPResourceHandle from the stack
	;
	mov	ax, ss:[bp].RCIIF_oldResource
	mov	ds:[curXIPResourceHandle], ax
endif
	
;	If we mapped in an XIP resource, then unmap it
;	If we locked down a normal resource, then unlock it
	
	cmp	ss:[bp].RCIIF_handle, LAST_XIP_RESOURCE_HANDLE
	ja	doUnlock		;Not an XIP resource, so just unlock
					; the code segment we just called
;
;	Map in the XIP page that *used* to be mapped in - this updates the
;	"curXIPPage" variable in kdata.
;
	mov	bp, ss:[bp].RCIIF_oldPage

	xchg	bp, bx			;Save BX while mapping in the old XIP
					; page

	MapXIPPageInline	bx, TRASH_AX_BX
	mov	bx, bp

EC <	pop	ds			;bp is not the unlocked handle	>
EC <	jmp	noNullSeg		;so we need to skip some EC code>
NEC <	jmp	afterUnlock						>
	
doUnlock:
endif

	; unlock the handle
	mov	bp,ss:[bp].RCIIF_handle		;21

if	ANALYZE_WORKING_SET
	xchg	bx, bp
	call	WorkingSetResourceNotInUse
	xchg	bx, bp
endif

	FastUnLock	ds, bp, ax, NO_NULL_SEG	;62
FXIP <afterUnlock::							>

	; 4/17/94: don't do NullSegmentRegisters if lock count non-zero,
	; so DOSVirtGetExtAttrsEnsureHeader can call DOSVirtReadFileHeader
	; with the BIOS lock down. That code calls MemLockFixedOrMovable before
	; grabbing the BIOS lock, so we don't go for the heapSem with the
	; biosLock grabbed. This NullSegmentRegisters call defeats all that
	; if we do it all the time. -- ardeb

EC <	tst	ds:[bp].HM_lockCount					>
	pop	ds				;12
EC <	jnz	noNullSeg						>
EC <	call	NullSegmentRegisters ; in case was pointing at code...	>
EC <noNullSeg:								>
	pop	bp				;12
	pop	ax				;12
	popf					;12

RCI_end label	near
	ForceRef	RCI_end

	jmp	ss:[TPD_callVector]		;32

	; slow part of lock

	; FastLock2	ds, bx, si, RCI_1, RCI_2, LockDiscardedResource

ife	FULL_EXECUTE_IN_PLACE
???_RCI_2:
	INT_ON
	xchg	ax, si			; preserve AX
	test	ds:[bx].HM_flags, mask HF_DISCARDED
	jnz	lockDiscarded

	; FullLockNoReload will trigger some EC code in a movable resource
	; if the AUTOMATICALLY_FIXUP_PSELF code is assembled in, and those
	; movable calls will overwrite the value in TPD_callVector that
	; we have already set up earlier, so we have to preserve
	; TPD_callVector here. -dhunter 8/16/2000
	
EC <	push	ss:[TPD_callVector].offset				>
	call	FullLockNoReload
EC <	pop	ss:[TPD_callVector].offset				>
	jc	lockDiscarded
	xchg	ax, si			; restore AX, SI <- segment (destReg
					;  of FastLock1, above)
	jmp	???_RCI_1

lockDiscarded:
	; In some obscure case, LockDiscardedResource may trigger some EC code
	; in a movable resource, and those movable calls will overwrite the
	; value in TPD_callVector that we have already set up earlier.  So we
	; have to preserve TPD_callVector here.  --- AY 8/5/96
EC <	push	ss:[TPD_callVector].offset				>
	call	LockDiscardedResource
EC <	pop	ss:[TPD_callVector].offset				>
	xchg	ax, si			; restore AX, SI <- segment (destReg
					;  of FastLock1, above)
	jmp	???_RCI_1
endif
SwatLabel ResourceCallInt_end
if	SINGLE_STEP_PROFILING
ResourceCallIntProfiling	endp
else
ResourceCallInt	endp
endif

if	ERROR_CHECK
;
; Compute a checksum of the handle and return address and save it into the
; error-checking RCI frame
;
ECComputeRCIChecksum	proc	near
	;
	; Compute a checksum of the RCI_frame
	;
	pushf
	push	ax, bx
	call	ECCalcRCIChecksum
	mov	ss:[bx].RCIIF_checkSum, ax
	pop	ax, bx
	popf
	ret
ECComputeRCIChecksum	endp

ECCalcRCIChecksum proc near
	mov	bx, ss:[TPD_stackBot]		; ss:bx <- ptr past RCI_frame
	sub	bx, size RCI_infoFrame		; ss:bx <- ptr to RCI_frame
	mov	ax, ss:[bx].RCIIF_handle
	add	ax, ss:[bx].RCIIF_retAddr.offset
	add	ax, ss:[bx].RCIIF_retAddr.segment
	add	ax, 'jw'			; Don't allow zero to work
	ret
ECCalcRCIChecksum endp

;
; Check the checksum of the handle and return address.
;
ECCheckRCIChecksum	proc	near
	;
	; Compute a checksum of the RCI_frame
	;
	pushf
	push	ax, bx
	call	ECCalcRCIChecksum
	cmp	ax, ss:[bx].RCIIF_checkSum
	ERROR_NZ RESOURCE_CALL_INT_STACK_MESSED_UP_POSSIBLY_WRITING_PAST_DGROUP
	pop	ax, bx
	popf
	ret
ECCheckRCIChecksum	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	RestoreMovableInt

DESCRIPTION:	Restore the movable call interrupts

CALLED BY:	EXTERNAL
		EndGeos

PASS:
	ds - kernel variable segment

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

RestoreMovableInt	proc	far
	INT_OFF
	push	si, di, es
	clr	ax
	mov	es,ax			;point at bottom of memory

	; make sure we've intercepted the things...

	tst	ds:[installedMovableVectors]
	jz	done
	mov	ds:[installedMovableVectors], FALSE

	; just block-move the old vectors back into place.

	mov	cx,16*2			;number of interrupts to restore
	mov	si, offset oldResourceCalls
	mov	di, RESOURCE_CALL_VECTOR_BASE
	rep	movsw

done:
	pop	si, di, es
	INT_ON
	ret

RestoreMovableInt	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckDirectionFlag

DESCRIPTION:	Make sure the direction flag is clear, as the rest of the
		system expects...

CALLED BY:	GLOBAL

PASS:

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

if	ERROR_CHECK
ECCheckDirectionFlag	proc	near
	pushf
	push	ax

	pushf
	pop	ax
	test	ax, mask CPU_DIRECTION
	ERROR_NZ	DIRECTION_FLAG_SET

	pop	ax
	popf
	ret

ECCheckDirectionFlag	endp
endif

if	RECORD_MODULE_CALLS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordModuleCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record a call made between modules

CALLED BY:	ResourceCallInt

PASS:		AX	= Routine offset
		BX	= Routine handle
		DS	= Kdata segment

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RecordModuleCall	proc	near
		uses	cx, si
		.enter
	
		; Search for the routine. If it doesn't exist, add it
		; to our list. Else, add a new entry
		;
		mov	cx, ds:[recModuleCallHeader].RMCH_used
		mov	si, offset recModuleCallTable
		jcxz	addEntry
nextEntry:
		cmp	ax, ds:[si].RMCE_offset
		jne	next
		cmp	bx, ds:[si].RMCE_handle
		je	found
next: 
		add	si, (size RecordModuleCallEntry)
		loop	nextEntry

		; Add our entry to the table
addEntry:
		dec	ds:[recModuleCallHeader].RMCH_unused
		jz	tableFull
		inc	ds:[recModuleCallHeader].RMCH_used
		mov	ds:[si].RMCE_offset, ax
		mov	ds:[si].RMCE_handle, bx
		clrdw	ds:[si].RMCE_count
found:
		incdw	ds:[si].RMCE_count
done:
		.leave
		ret

		; The table is full. Tough nookie
tableFull:
		inc	ds:[recModuleCallHeader].RMCH_unused
		incdw	ds:[recModuleCallHeader].RMCH_overflow
		jmp	done
RecordModuleCall	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapInXIPResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maps in an XIP resource

CALLED BY:	GLOBAL
PASS:		ds - kdata
		bx - handle of resource to map in
RETURN:		bx - segment of resource
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
MapInXIPResource	proc	near	uses	ax, dx
	.enter

;	Find out the XIP image offset of the passed handle, and store it
;	in the variable that keeps track of what bank should be mapped in.

EC <	call	AssertDSKdata						>
	ConvertHandleToImageOffset	bx,   dx,ax

	call	MapXIPPage		;Now, BX:AX = ptr to mapped-in data
EC <	test	ax, 0x000f						>
EC <	ERROR_NZ	INVALID_XIP_RESOURCE_OFFSET			>
	shr	ax			;Convert AX from offset into mapping
	shr	ax			; page to segment itself
	shr	ax
	shr	ax
	add	bx, ax
	.leave
	ret
MapInXIPResource	endp
endif
