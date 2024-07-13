COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Data Exchange Library
FILE:		dataxUtils.asm

AUTHOR:		Robert Greenwalt, Nov  6, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 6/96   	Initial revision


DESCRIPTION:
		
	Utility routines for the Data Exchange Library

	$Id: dataxUtils.asm,v 1.1 97/04/04 17:54:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnterDXLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some prep for the pipe-control API

CALLED BY:	DXOpenPipe and DXClosePipe
PASS:		nothing
RETURN:		ds - dgroup
		DXGeodeTable locked down - segment stored in dgroup (temporarily)
			librarySem P'd
		helperOptr filled in

DESTROYED:	es, bx, cx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnterDXLibrary	proc	near
	.enter
	;
	; Check the DataExchange semaphore - only one access to the
	; library at a time!
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		PSem	ds, librarySem, TRASH_AX_BX
	;
	; Verify we have a geodeTable - if not, allocate one
	;
		mov	bx, ds:[geodeTable]
		tst	bx
		jnz	haveTable
	;
	; Don't have table - allocate..
	;
		mov	cx, cs
		call	MemSegmentToHandle
		mov	bx, cx
		call	MemOwner
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		mov	ax, 16
		call	MemAllocSetOwner
		jc	memError
		mov	ds:[geodeTable], bx	; store away the new block
	;
	; and initialize it
	;
		mov	es, ax
		clr	es:[DXGTH_entryCount]
		mov	es:[DXGTH_blockSize], 16
		jmp	tableLocked
haveTable:
EC<		call	ECCheckMemHandle				>
		call	MemLock
tableLocked:
		mov	ds:[geodeTableSegment], ax

	;
	; Now find our helper object
	;
		mov	cx, cs
		call	MemSegmentToHandle	; cx = handle
		mov	bx, cx
		call	MemOwner		; bx = process
		clr	cx
		movdw	ds:[helperOptr], bxcx
done:
	.leave
	ret
memError:
	;
	; release the sem
	;
		VSem	ds, librarySem, TRASH_AX_BX
		mov	ax, DXRT_MEM_ERROR
		stc
		jmp	done
EnterDXLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitDXLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Leave our Pipe API routine

CALLED BY:	DXOpenPipe, DXClosePipe and some util routines
PASS:		ds = dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExitDXLibrary	proc	near
	uses	bx
	.enter
		mov	bx, ds:[geodeTable]
EC<		call	ECCheckMemHandle				>
		call	MemUnlock
		VSem	ds, librarySem
	.leave
	ret
ExitDXLibrary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyPipeDesc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check (ec and non) the contents of the pipe descriptor.

CALLED BY:	DXOpenPipe
PASS:		ds - dgroup
		es:di - pipe descriptor
RETURN:		on error:
			carry set
			ax - DXReturnType
		else
			carry clear
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	must ExitDXLibrary on error.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VerifyPipeDesc	proc	near
	uses	bx,cx,dx
	.enter
	;
	; Check the dataBuffer
	;
EC<		push	bx						>
EC<		mov	bx, es:[di].DXPD_dataBuffer			>
EC<		call	ECCheckMemHandle				>
EC<		pop	bx						>
	;
	; Check that we have room for all the elements
	;
		mov	cx, es
		call	MemSegmentToHandle
		jnc	error
		mov	bx, cx
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		mov	bx, ax		; store away size
		mov	ax, es:[di].DXPD_elementCount
		mov	cx, size DataXElementDescriptor
		mul	cx
		add	ax, size DataXPipeDescriptor
		adc	dx, 0
		tst	dx
		jnz	error
		cmp	ax, bx		; is the proposed size bigger
					; then the block it came in?
		ja	error
		clc
done:
	.leave
	ret
error:
		mov	ax, DXRT_BAD_PIPE_DESC
		stc
		jmp	done
VerifyPipeDesc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDXGeodeTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see that a geode can be in another pipe and
		not reentrant

CALLED BY:	DXOpenPipe
PASS:		ds - dgroup
		es:di - GeodeToken
RETURN:		on error:
			carry set
			ax - DXReturnType
		else
			carry clear
			si - offset to entry in table of geode, newly
				inserted or not.
DESTROYED:	ax, dx, cx
SIDE EFFECTS:	
		May have to reallocate the geode table
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckDXGeodeTable	proc	near
	uses	es, di, bp, cx
		.enter
	;
	; setup to search through the table
	;
		mov	dx, es:[di]
		mov	ax, es:[di].2
		mov	bp, es:[di].4	; dxaxbp = GeodeToken to find

		mov	cx, ds:[geodeTableSegment]
		mov	es, cx
		mov	di, offset DXGTH_firstElement - size DXGeodeTableEntry
		mov	cx, es:[DXGTH_blockSize]
		sub	cx, size DXGeodeTableEntry

loopTop:
		add	di, size DXGeodeTableEntry
	;
	; cx = beginning of last possible entry
	;
		cmp	cx, di
		jb	notFound
		
		cmp	dx, {word}es:[di].DXGTE_token
		jne	loopTop
		cmp	ax, {word}es:[di].DXGTE_token.2
		jne	loopTop
		cmp	bp, {word}es:[di].DXGTE_token.4
		mov	si, di			; setup return value
	;
	; ok, check if reentrant
	;
		tst	es:[di].DXGTE_refCount	; clears carry
		jnz	done
	;
	; ERROR: is in use and not reentrant - signal error
	;
		mov	ax, DXRT_NON_REENTRANT_ELEMENT_ALREADY_IN_USE
		stc
done:
		.leave
		ret

notFound:
	;
	; Verify that we can add more to the table
	;
		inc	es:[DXGTH_entryCount]
		jnz	canAddGeode
	;
	; ERROR: the table is full (only 255 geodes allowed)
	;
		dec	es:[DXGTH_entryCount]
		stc
		mov	ax, DXRT_MEM_ERROR
		jmp	done
	;
	; Find empty spot
	;
canAddGeode:
		mov	di, offset DXGTH_firstElement - size DXGeodeTableEntry
vacancyLoop:
		add	di, size DXGeodeTableEntry
	;
	; cx= beginning of last possible entry
	;
		cmp	cx, di
		LONG_EC	jb	reallocTable

		tst	{word}es:[di].DXGTE_token
		jnz	vacancyLoop
		tst	{word}es:[di].DXGTE_token.2
		jnz	vacancyLoop
		tst	{word}es:[di].DXGTE_token.4
		jnz	vacancyLoop
	;
	; Found an empty spot - insert
	;
insertGeode:
		mov	{word}es:[di].DXGTE_token, dx
		mov	{word}es:[di].DXGTE_token.2, ax
		mov	{word}es:[di].DXGTE_token.4, bp
		mov	si, di			; setup return value
	;
	; later, you can tell this is a new entry, because it got
	; through this routine with 0 refCount
	;
		clr	es:[di].DXGTE_refCount
		clc
		jmp	done
reallocTable:
	;
	; The table is full - make bigger
	;
		push	ax
		add	es:[DXGTH_blockSize], (size DXGeodeTableEntry) shl 2 
		mov	ax, es:[DXGTH_blockSize]
		mov	bx, ds:[geodeTable]
		mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK
		call	MemReAlloc
		jnc	allocOK
	;
	; ERROR: mem alloc failure
	;
		pop	ax
		mov	ax, DXRT_MEM_ERROR
		stc
		jmp	done

allocOK:
		mov	es, ax
		mov	ds:[geodeTableSegment], ax
		pop	ax
		jmp	insertGeode
CheckDXGeodeTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PipeOpenDoIACPStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do all the iacp stuff to startup a pipe element

CALLED BY:	DXOpenPipe
PASS:		es:di = geode token
		ds = dgroup
		ds:[infoBlockSegment]
RETURN:		on error
			no IACP connection established
			ax = DataXReturnType
			bp = NULL
			carry set
		else
			carry clear
			bp = IACPConnection
DESTROYED:	dx, bx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PipeOpenDoIACPStuff	proc	near
	uses	cx, si, di
	.enter
	;
	; Open an IACP connection with the current element
	;
		mov	dx, MSG_GEN_PROCESS_OPEN_ENGINE
		call	IACPCreateDefaultLaunchBlock	; dx = hptr to ALB
		jc	memError

		mov	bx, dx
		mov	ax, mask IACPCF_FIRST_ONLY or mask IACPCF_CLIENT_OD_SPECIFIED
		movdw	cxdx, ds:[helperOptr]
		call	IACPConnect
		jc	iacpError
	;
	; Connection made.  bp = IACPConnection
	;   Now we need to package up our startup message
	;
		mov	ax, MSG_META_IACP_DATA_EXCHANGE
		mov	di, mask MF_RECORD
		mov	bx, segment MetaClass
		mov	cx, ds:[infoBlockSegment]
		clr	dx
		mov	si, offset MetaClass
		call	ObjMessage
	;
	; And send the startup Message
	;
		mov	bx, di
		clr	cx
		mov	dx, TO_SELF
		mov	ax, IACPS_CLIENT
		call	IACPSendMessageAndWait
		clc
done:
	.leave
	ret
memError:
		mov	ax, DXRT_MEM_ERROR
		mov	bp, 0
		jmp	done
iacpError:
		mov	ax, DXRT_IACP_ERROR
		mov	bp, 0
		jmp	done
PipeOpenDoIACPStuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXOpenTimerRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've timed out waiting for our IACP response..

CALLED BY:	Timer
PASS:		na
RETURN:		na
DESTROYED:	ax, bx
SIDE EFFECTS:	sets timerFired and wakes other thread.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXOpenTimerRoutine	proc	far
	.enter
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	ds:[timerFired], 1
		VSem	ds, openWaitSem, TRASH_AX_BX
	.leave
	ret
DXOpenTimerRoutine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXIncGeodeTableEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've gotten a good response from this geode, update it.

CALLED BY:	DXOpenPipe
PASS:		ax = lastReturnValue - DXStartupFlags back from the geode
		si = offset to this geode's entry in geodetable
		ds = dgroup
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXIncGeodeTableEntry	proc	near
	uses	ds
	.enter
		mov	bx, ds:[geodeTableSegment]
		mov	ds, bx
	;
	; Now, check to see if the element is new
	;
		tst	ds:[si].DXGTE_refCount
		jnz	notNew
	;
	; Now, it's new, so the ref count = 0.  Leave it zero if not
	; reentrant, else inc it.  The inc will let us reuse it,
	; but 0 won't let it through CheckDXGeodeTable
	;
		test	ax, mask DXSF_REENTRANT
		jz	nextElement
notNew:
		inc	ds:[si].DXGTE_refCount
nextElement:

	.leave
	ret
DXIncGeodeTableEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXDecGeodeTableEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Time to dec this entry.

CALLED BY:	DXAbortPipe
PASS:		es:di = GeodeToken to nuke
		ds = dgroup
RETURN:		nothing
DESTROYED:	dx, ax, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXDecGeodeTableEntry	proc	near
	uses	es, cx
	.enter
		call	CheckDXGeodeTable
		jnc	nukeIt
		cmp	ax, DXRT_NON_REENTRANT_ELEMENT_ALREADY_IN_USE
		jne	dontRemove
nukeIt:
		mov	cx, ds:[geodeTableSegment]
		mov	es, cx
	;
	; if it is zero, remove it
	;
		tst	es:[si].DXGTE_refCount
		jnz	decAndTest
removeEntry:
		clr	cx
		mov	{word}es:[si].DXGTE_token, cx
		mov	{word}es:[si].DXGTE_token.2, cx
		mov	{word}es:[si].DXGTE_token.4, cx
dontRemove:
	.leave
	ret
decAndTest:
		dec	es:[si].DXGTE_refCount
		jnz	dontRemove
		jmp	removeEntry
DXDecGeodeTableEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXSetupInfoBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the InfoBlock so we can pass it to each element
		on startup

CALLED BY:	DXOpenPipe
PASS:		ds = dgroup
		bx = 	pipe descriptor handle
		es:di = pipe description data
RETURN:		on error
			carry set
			ax = DXReturnType
		else
			carry clear
			ds:infoBlock assigned, and locked
				dataBuffer inserted
DESTROYED:	bx, ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXSetupInfoBlock	proc	near
	uses	ds
	.enter
		push	bx
	;
	; allocate!
	;
		mov	ax, size DXInternalDataXInfo
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		jnc	noMemError
		mov	ax, DXRT_MEM_ERROR
		pop	cx
		jmp	done		
	;
	; and initialize
	;
noMemError:
		push	bx
		mov	ds:[infoBlockSegment], ax
		mov	ds, ax

		mov	bx, es:[di].DXPD_dataBuffer
		mov	ds:[DXI_dataBuffer], bx
		call	MemLock
		mov	ds:[DXI_dataSegment], ax
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		mov	ds:[DXI_bufferSize], ax
		mov	ds:[DXI_dataSize], ax
		mov	ds:[DXI_protoMajor], DX_MAJOR_PROTO
		mov	ds:[DXI_protoMinor], DX_MINOR_PROTO

		mov	bx, 0
		call	ThreadAllocSem
		mov	ds:[DXIDXI_infoWordSema], bx

		pop	es:[DXIPD_infoBlock]

		pop	ds:[DXIDXI_deathInfo]
done:
	.leave
	ret
DXSetupInfoBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXSetInfoBlockData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've got to another pipe element to start.  Set data.

CALLED BY:	DXOpenPipe
PASS:		es:di = elementDescriptor
		ds = dgroup
		cx = element remaining count ( 1 for last element )
		infoBlock setup
RETURN:		ax, bx
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXSetInfoBlockData	proc	near
	uses	ds
		.enter
	;
	; Copy in the startup data
	;	
		mov	ax, ds:[infoBlockSegment]
		mov	ds, ax

		mov	ax, es:[di].DXED_initialInfoWord
		mov	ds:[DXI_infoWord], ax
		mov	ax, {word}es:[di].DXED_initialMiscInfo
		mov	{word}ds:[DXI_miscInfo], ax
		mov	ax, {word}es:[di].DXED_initialMiscInfo.2
		mov	{word}ds:[DXI_miscInfo].2, ax
	;
	; Transfer over the right side sema from the last element to
	; be our inverse left side semas.  If this is the first
	; element, we'll be copying nulls..
	;
		mov	ax, ds:[DXI_intSemaphoreRight]
		mov	ds:[DXI_extSemaphoreLeft], ax

		mov	ax, ds:[DXI_extSemaphoreRight]
		mov	ds:[DXI_intSemaphoreLeft], ax
	;
	; Now Check for the right sider
	;
		clr	bx
		cmp	cx, 1 			; are we the last?
		je	noRightPort
	;
	; Allocate new right side semas
	;
		clr	bx
		call	ThreadAllocSem
		mov	ds:[DXI_intSemaphoreRight], bx
		clr	bx
		call	ThreadAllocSem
		jmp	semsAllocated

noRightPort:
		mov	ds:[DXI_intSemaphoreRight], bx
semsAllocated:
		mov	ds:[DXI_extSemaphoreRight], bx
	;
	; Store these away for the day when we kill the pipe
	;
		mov	ax, ds:[DXI_intSemaphoreRight]
		mov	bx, ds:[DXI_intSemaphoreLeft]
		mov	es:[di].DXIED_intRight, ax
		mov	es:[di].DXIED_intLeft, bx
		.leave
	ret
DXSetInfoBlockData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXAbortPipe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In the middle of setting up elements we had a problem.

CALLED BY:	DXOpenPipe
PASS:		es:di = last InternalElementDescriptor
		ax = DXReturnType
		ds = dgroup
RETURN:		
DESTROYED:	cx, bx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Wake them all and then wait for them all to report back
	(miscInfo sema).  Later, free all the sems.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXAbortPipe	proc	near
	uses	ax, bp
	.enter
	;
	; setup the init status
	;
		push	ds
		mov	ax, ds:[infoBlockSegment]
		mov	ds, ax
		mov	ds:[DXI_infoWord], DXIW_CLEAN_SHUTDOWN
		mov	bx, es:[DXIPD_elementCount]
		mov	ds:[DXIDXI_deathCount], bx
		mov	bx, 1		; so we loop at least once for free.
		call	ThreadAllocSem
		mov	ds:[DXIDXI_deathSema], bx
	;
	; Wakeup anyone on the sync mechanism (current "running" element)
	;	
		mov	bx, ds:[DXIDXI_infoWordSema]
		call	ThreadVSem
	;
	; Now, loop until we reach the leftmost.
	;
		pop	ds
		push	di
loopTop:
	;
	; Remove from geodeTable
	;
		call	DXDecGeodeTableEntry
	;
	; Check for a right side
	;
		mov	bx, es:[di].DXIED_intRight
		tst	bx
		jz	noRightV
		call	ThreadVSem
noRightV:
		mov	bx, es:[di].DXIED_intLeft
		tst	bx
		jz	noLeftV
		call	ThreadVSem
noLeftV:
		cmp	di, offset DXPD_firstElement
		je	firstLoopDone
		sub	di, size DXInternalElementDescriptor
		jmp	loopTop
	;
	; Now, sleep
	;
firstLoopDone:
		pop	di
		push	ds
		mov	ax, ds:[infoBlockSegment]
		mov	ds, ax
		mov	bx, ds:[DXIDXI_deathSema]
stillWaiting:
		call	ThreadPSem
		cmp	ds:[DXIDXI_deathCount], 0
		ja	stillWaiting
		call	ThreadFreeSem
		pop	ds
freeLoopTop:
		mov	bx, es:[di].DXIED_intRight
		tst	bx
		jz	noRightFree
		call	ThreadFreeSem
noRightFree:
		mov	bx, es:[di].DXIED_intLeft
		tst	bx
		jz	noLeftFree
		call	ThreadFreeSem
noLeftFree:
		mov	bp, es:[di].DXIED_IACPConnection
		tst	bp
		jz	noConnection
		clr	cx
		call	IACPShutdown
noConnection:
		cmp	di, offset DXPD_firstElement
		je	done
		sub	di, size DXInternalElementDescriptor
		jmp	freeLoopTop
done:
	.leave
	ret
DXAbortPipe	endp
DataXFixed	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXInternalClosePipe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kill the Pipe from within

CALLED BY:	PipeElement after death prep
PASS:		on stack:
			fptr to DataXBehaviorArguments
RETURN:		doesn't - jumps to thread destroy
DESTROYED:	don't care.
SIDE EFFECTS:	death
		PipeElementHeader freed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	1/15/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
DXINTERNALCLOSEPIPE	proc	far	toArgs:fptr.DataXBehaviorArguments
ForceRef DXINTERNALCLOSEPIPE
	.enter
	;
	; Send the DataX helper obj a message to kill this pipe
	;
		les	di, toArgs
		les	di, es:[di].DXBA_dataXInfo
		mov	dx, es:[di].DXIDXI_deathInfo
		mov	bx, handle dgroup
		call	MemDerefDS
		push	di
		movdw	bxsi, ds:[helperOptr]
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_DXH_KILL_PIPE
		call	ObjMessage
		pop	di
	;
	; Let them think we're perpetually pre-scan on the infoWord
	;
		mov	bx, es:[di].DXIDXI_infoWordSema
		call	ThreadVSem
	;
	; Sleep on an internal sem to be woken by the abort
	;
		les	di, toArgs
		les	di, es:[di].DXBA_elementHeader
		mov	bx, es:[di].PEH_intSemaphoreLeft
		tst	bx
		jnz	haveSema
		mov	bx, es:[di].PEH_intSemaphoreRight
haveSema:
		call	ThreadPSem
	;
	; Now shut down like a good guy
	;
		lds	si, toArgs
		segmov	es, ss
		mov	cx, size DataXBehaviorArguments
		sub	sp, cx
		mov	di, sp
		ArbitraryCopy
		call	DXBShutdown
	.leave	.unreached
DXINTERNALCLOSEPIPE	endp
	SetDefaultConvention
DataXFixed	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXFindDgroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to find the dgroup for our custom code

CALLED BY:	DXCopyInitInfo
PASS:		es:[0] = PEH
RETURN:		nothing
DESTROYED:	di, ax
SIDE EFFECTS:	set PEH_dgroup

PSEUDO CODE/STRATEGY:
		Look for custom routines - none, don't need dgroup

		Look for Default

		Look for custom

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	1/17/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXFindDgroup	proc	far
	uses	bx, ds
	.enter
	;
	; Look for custom routines
	;
		mov	di, es:[PEH_customRoutines]
		tst	es:[di].RTE_infoWord
		jnz	haveCustomRoutines

		mov	es:[PEH_dgroup], es
done:
	.leave
	ret

haveCustomRoutines:
	;
	; Check for default
	;
		tst	{word}es:[PEH_defaultRoutine]
		jz	noDefault
		movdw	bxax, es:[PEH_defaultRoutine]
		jmp	haveRoutine
noDefault:
	;
	; just grab the first one
	;
		mov	di, es:[PEH_customRoutines]
		movdw	bxax, es:[di].RTE_routine
haveRoutine:
	;
	; Now use the owner of the code resource to find the dgroup
	;
		shl	bx
		shl	bx
		shl	bx
		shl	bx
		call	GeodeGetDGroupDS
		mov	ax, ds
		mov	es:[PEH_dgroup], ax
		jmp	done
DXFindDgroup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXSetStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy all the good stuff from our PEH block to the
		stack and toss out that clunk old guy.

CALLED BY:	DXMain
PASS:		cx	- hptr to PEH block
RETURN:		ss:bp	- PEH
		ss:sp	- after return = bottom of DataXBehaviorArguments
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	1/20/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXSetStack	proc	far

		popdw	bpdx	; return ptr

		add	sp, size DataXBehaviorArguments
	;
	; get size of PEH block
	;
		mov	bx, cx
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		sub	sp, ax
		mov	cx, ax
		mov	di, sp
		segmov	es, ss, ax
	;
	; lock PEH
	;
		call	MemLock
		mov	ds, ax
		clr	si
	;
	; copy
	;
		shr	cx
		rep	movsw
	
		call	MemFree
		mov	di, bp
		mov	bp, sp
	;
	; Fixup customRoutines Ptr
	;
		add	ss:[bp].PEH_customRoutines, bp
	;
	; set DXBA
	;
		movdw	cxbx, ss:[bp].PEH_dataXInfo
		pushdw	cxbx

		mov	bx, ss
		mov	cx, bp
		add	cx, offset PEH_customData
		pushdw	bxcx

		pushdw	bxbp
	;
	; replace return offset
	;
		pushdw	didx
	ret
DXSetStack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXOpenSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the Timer to wait for element acknowledgement

CALLED BY:	DXOPENPIPE
PASS:		nothing
RETURN:		ax	= timerID
		bx	= timer handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	1/24/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXOpenSetTimer	proc	far
	.enter
		push	si, cx
		mov	al, TIMER_ROUTINE_ONE_SHOT
		mov	bx, cs
		mov	si, offset DXOpenTimerRoutine
		mov	cx, DX_START_TIME
		call	TimerStart	; ax = timerID
					; bx = timer handle
		pop	si, cx
	.leave
	ret
DXOpenSetTimer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXManualPipeCycle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Somebody wants to cycle the pipe themselves - usefull
		in enumerate/callback setups.

CALLED BY:	Behavior
PASS:		on stack
			fptr to DataXBehaviorArguments
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	must MUST check the DXIW_infoWord on return.  If it's
		a clean shutdown you've got to handle it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	1/23/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
DXMANUALPIPECYCLE	proc	far	toArgs:fptr.DataXBehaviorArguments
	uses	bp, es, di, ds, si, ax, bx
	.enter
		lds	si, toArgs
		les	di, ds:[si].DXBA_elementHeader
		mov	bp, di
		SemaphoreTwiddle
	.leave
	ret
DXMANUALPIPECYCLE	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXManualBehaviorCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Somebody wants to call another behavior without
		cycling the pipe.  

CALLED BY:	Behavior
PASS:		DXI_infoWord filled in
		on stack
			fptr to DataXBehaviorArguments
RETURN:		ax = DXET value
DESTROYED:	nothing
SIDE EFFECTS:	Must deal with the return value.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	1/23/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
DXMANUALBEHAVIORCALL	proc	far	toArgs:fptr.DataXBehaviorArguments
	uses	bx,cx,dx,si,di,es,ds
	.enter
		lds	si, toArgs
		mov	cx, size DataXBehaviorArguments
		sub	sp, cx
		segmov	es, ss, di
		mov	di, sp
		EvenCopy

		lds	si, toArgs
		les	di, ds:[si].DXBA_elementHeader
		lds	si, ds:[si].DXBA_dataXInfo
		mov	ax, ds:[si].DXI_infoWord
		mov	di, es:[di].PEH_customRoutines
		call	DXFindBehavior
		jc	noCustomRoutine
		movdw	bxax, es:[di].RTE_routine
haveRoutineLoaded:
		call	ProcCallFixedOrMovable
restoreStack:
		add	sp, size DataXBehaviorArguments
	.leave
	ret
noCustomRoutine:
		lds	di, toArgs
		les	di, ds:[di].DXBA_elementHeader
		tst	{word}es:[di].PEH_defaultRoutine.segment
		jz	noDefault
		movdw	bxax, es:[di].PEH_defaultRoutine
		jmp	haveRoutineLoaded
noDefault:
		call	DXFindInheritedBehavior
		mov	ax, DXET_NO_ERROR
		jc	restoreStack
		movdw	bxax, es:[di].RTE_routine
		jmp	haveRoutineLoaded
DXMANUALBEHAVIORCALL	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXSETDXIDATABUFFERSIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the size of the DXI_dataBuffer, ensuring that it
		is the right size

CALLED BY:	external
PASS:		on stack:
		fptr to DataXInfo	
		size of buffer

RETURN:		success:
			ax = offset of segment, 
		on error:
			carry set
			ax = 0
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
	Return value of the segment in ax.  0 if there was an error,
	so C can detect an error too (C can't see a carry set condition).
	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	1/30/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
DXSETDXIDATABUFFERSIZE	proc	far dxInfo:fptr.DataXInfo, dataSize:word
	uses	bx, cx, es, si
	.enter
		les	si, dxInfo
		mov	ax, dataSize
	;
	; We can always get smaller than the buffer size (or equal).  
	;
		cmp	ax, es:[si].DXI_bufferSize
		jbe	setSize
	;
	; The buffer is not big enough.  Reallocate.
	;	
		mov	bx, es:[si].DXI_dataBuffer
		mov	ch, 0 
		call	MemReAlloc			; ax = segment address
		jnc	success
		mov	ax, 0
		jmp 	done

success:
		mov	es:[si].DXI_dataSegment, ax

		mov	ax, MGIT_SIZE
		call	MemGetInfo
		mov	es:[si].DXI_bufferSize, ax

		mov	ax, ss:[dataSize]
setSize:
		mov	es:[si].DXI_dataSize, ax
		mov	ax, es:[si].DXI_dataSegment
		clc
done:
	.leave
	ret
DXSETDXIDATABUFFERSIZE	endp
	SetDefaultConvention
ExtCode	ends

