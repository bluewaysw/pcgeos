COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Data Exchange Library
FILE:		dataxPipeAPI.asm

AUTHOR:		Robert Greenwalt, Nov  5, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 5/96   	Initial revision


DESCRIPTION:
		
	Exported routines for doing pipe management

	$Id: dataxPipeAPI.asm,v 1.1 97/04/04 17:54:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ExtCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXOPENPIPE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Caller wants to open a particular data pipe.

CALLED BY:	GLOBAL
PASS:		on stack:
		hptr to a buffer containing a DataXPipeDescriptor
			followed by a set of DataXElementDescriptors,
			establishing startup parameters and element
			order from left to right.
RETURN:		ax - DataXReturnType
DESTROYED:	nothing
SIDE EFFECTS:	Starts the pipe.  The passed hptr and any resources
		referenced within its buffer must be untouched for the
		life of the pipe.

PSEUDO CODE/STRATEGY:
	Lock our semaphore to serialize access to the API.
	Verification of the descriptor contents - all infoWords are
		valid, etc.  There are definite requirements for infoWord
	Start at beginning, for each pipe element 
		- verify that the geode is not currently in a pipe or
			is reentrant
		- open an IACP connection
		- send MSG_META_IACP_DATA_EXCHANGE with a pointer to
			the pipe window, with this elements data
		- start a timer.  If we don't get an IACP response
			back before the timer goes off, abort the
			pipe.
		- Record the geode (and its reentrant status) in the
			PipeElementTable. 
	After all the elements have responded, the pipe is ready to
		go.  V each element's topmost internal semaphore.  All
		elements but the head element will setup and then P
		their upstream internal sem. The head will start the
		flow.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
DXOPENPIPE	proc	far	myDescBlock:hptr
	uses	bx,cx,dx,si,di,bp, es, ds
		.enter
	;
	; Check the DataExchange semaphore - only one access to the
	; library at a time!
	;
		call	EnterDXLibrary
		LONG	jc	reallyDone
	;
	; Lock down the descriptor block and check out the contents
	;
		mov	bx, myDescBlock
		push	bx
EC<		call	ECCheckMemHandle				>
		call	MemLock
		mov	es, ax
		clr	di			; es:di = myDescBlock
		call	VerifyPipeDesc
		LONG_EC	jc	done

		call	DXSetupInfoBlock
		LONG_EC	jc	done

		mov	bx, es:[di].DXPD_dataBuffer
		mov	cx, es:[di].DXPD_elementCount
		add	di, offset DXPD_firstElement
		clr	ds:[timerFired]
elementLoop:
	;	es:di = current ElementDescriptor
	;	ds = dgroup
	;	cx = element count remaining

		clr	bp
	;
	; OK, now copy in the relevent data and allocate semaphores
	;
		call	DXSetInfoBlockData
	;
	; For each element, verify that the geode is either not
	; currently a pipe, or is reentrant
	;
		CheckHack < (offset DXED_geodeToken) eq 0 >
		call	CheckDXGeodeTable		; si = offset
							; entry in table
		LONG_EC	jc	elementsError
	;
	; Send off the startup message
	;
		call	PipeOpenDoIACPStuff
		LONG_EC	jc	elementsError
	;
	; Now, start timer and go to sleep
	;
		call	DXOpenSetTimer

		PSem	ds, openWaitSem
		tst	ds:[timerFired]	; did the timer wake us?
		jnz	timerTriggered
	;
	; Kill the timer
	;
		call	TimerStop
	;
	; Store the IACPConnection
	;
		mov	es:[di].DXIED_IACPConnection, bp
	;
	; Oh, this is fun..  first check if there's an error and the
	; element didn't happen
	;
		mov	ax, ds:[lastReturnValue]
		test	ax, mask DXSF_PROTOCOL_ERROR or mask DXSF_MEMORY_ERROR
		jnz	elementsErrorSetAX

		call	DXIncGeodeTableEntry
		add	di, size DataXElementDescriptor
		loop	elementLoop		
	;
	; OK.  All the elements responded positively.  Wake the
	; rightmost element
	;
		sub	di, size DataXElementDescriptor
		mov	bx, es:[di].DXIED_intLeft
		call	ThreadVSem
		mov	ax, DXRT_NO_ERROR
done:
		pop	bx
		call	MemUnlock
		call	ExitDXLibrary
reallyDone:
		.leave
	ret
timerTriggered:
		mov	ax, DXRT_BAD_PIPE_DESC
		jmp	elementsError
elementsErrorSetAX:
		test	ax, mask DXSF_PROTOCOL_ERROR
		mov	ax, DXRT_BAD_PIPE_DESC
		jnz	elementsError
		mov	ax, DXRT_MEM_ERROR
elementsError:
		mov	es:[di].DXIED_IACPConnection, bp
	;
	; We had a problem in the middle of pipe setup.  Go back and
	; kill earlier elements.
	;
		sub	es:[DXIPD_elementCount], cx
		call	DXAbortPipe
	;
	; and free up the infoBlock
	;
		mov	bx, es:[DXIPD_infoBlock]
		call	MemFree

		jmp	done
DXOPENPIPE	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXCLOSEPIPE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Caller wants to close a particular data pipe.

CALLED BY:	GLOBAL
PASS:		on stack:
		hptr - same as that used to open the pipe
RETURN:		ax - DataXReturnType
DESTROYED:	nothing
SIDE EFFECTS:	Tries to shutdown the pipe.  Any resources allocated
		for this pipe by its elements can be freed.

PSEUDO CODE/STRATEGY:
	Assume the pipe is running

	Look through the PipeElementTable for elements belonging to
		this pipe.  Find the Pipe window, and insert the
		DXIW_CLEAN_SHUTDOWN value into infoWord.  V all of
		each element's internal semaphores.

	Free the deathSema in DataXInfo
	
	Free the DataBlock pointed to by DataXInfo

	Free DataXInfo

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
DXCLOSEPIPE	proc	far	myDescBlock:hptr
	uses	bx,cx,dx,si,di,bp,ds,es
	.enter
		call	EnterDXLibrary
		LONG_EC	jc	reallyDone
	;
	; Now lock down the descBlock
	;
		mov	bx, myDescBlock
		call	MemLock
		mov	es, ax
	;
	; Sync up for the kill
	;
		push	ds
		mov	bx, es:[DXIPD_infoBlock]
		call	MemDerefDS
		mov	bx, ds:[DXIDXI_infoWordSema]
		call	ThreadPSem
		pop	ds
	;
	; now shut it down
	;
		mov	di, offset DXPD_firstElement
		mov	ax, size DXInternalElementDescriptor
		mov	cx, es:[DXIPD_elementCount]
		dec	cx
		mul	cx		; ax+di = offset of last descriptor
		add	di, ax		; es:di = last InternalElementDescriptor

		call	DXAbortPipe
	;
	; Free up the infoBlock
	;
		mov	bx, es:[DXIPD_infoBlock]
		mov	ax, bx
		call	MemDerefES
		mov	bx, es:[DXIDXI_infoWordSema]
		call	ThreadFreeSem
	;
	; Free the data buffer -- don't check if it is zero, it REALLY
	; is supposed to be filled in (the user should not be freeing it)
	;
		mov	bx, es:[DXI_dataBuffer]
		call	MemFree
		mov	bx, ax
		call	MemFree

		mov	bx, myDescBlock
		call	MemUnlock
		call	ExitDXLibrary
		mov	ax, DXRT_NO_ERROR
reallyDone:
	.leave
	ret
DXCLOSEPIPE	endp
	SetDefaultConvention
ExtCode	ends
