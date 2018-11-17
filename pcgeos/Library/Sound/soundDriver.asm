COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS Sound System
MODULE:		Sound Library's Driver Interface
FILE:		soundLibDriver.asm

AUTHOR:		Todd Stumpf, Aug 26, 1992

ROUTINES:
	Name			Description
	----			-----------
	SoundLibDriverStrategy	Strategy routine for driver part of library
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/26/92		Initial revision


DESCRIPTION:
	The driver is used for the PlayNote command because interrupts
	must be turned off around the call to the driver (as the driver
	expects interrupts to be off while it does whatever it is it
	is doing.
		
	$Id: soundDriver.asm,v 1.1 97/04/07 10:46:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
DriverTable	DriverInfoStruct <SoundLibDriverStrategy,0,DRIVER_TYPE_OUTPUT>
idata	ends

	.ioenable

ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routines for driver-part of library

CALLED BY:	GLOBAL
PASS:		di	-> driver command to execute

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		calls appropriate routine

PSEUDO CODE/STRATEGY:
		we don't set up or do anything, so just use di as
		the offset it is for the jump table.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverStrategy	proc	far
	.enter
	;
	;  Determine which routine to call
	shl	di, 1				; di <- dword index

	mov	ss:[TPD_dataAX], ax		; pass ax in ax
	mov	ss:[TPD_dataBX], bx		; pass bx in bx

	movdw	bxax, cs:driverJumpTable[di]	; bxax <- fptr to routine

	call	ProcCallFixedOrMovable	; Finally call the stupid thing
	.leave
	ret
SoundLibDriverStrategy	endp


driverJumpTable		fptr	SoundLibDriverDoNothing,  ; INIT
				SoundLibDriverDoNothing,  ; EXIT
				SoundLibDriverDoNothing,  ; SUSPEND
				SoundLibDriverDoNothing,  ; UNSUSPEND
				SoundLibDriverEnterLibraryRoutine,
				SoundLibDriverExitLibraryRoutine,
				SoundLibDriverAllocSimpleFM,
				SoundLibDriverAllocStreamFM,
				SoundLibDriverAllocNoteFM,
				SoundLibDriverReallocSimpleFM,
				SoundLibDriverReallocNoteFM,
				SoundLibDriverPlaySimpleFM,
				SoundLibDriverPlayToStreamFM,
				SoundLibDriverPlayToStreamFMNB,
				SoundLibDriverStopSimpleFM,
				SoundLibDriverStopStreamFM,
				SoundLibDriverInitSimpleFM,
				SoundLibDriverFreeSimple,
				SoundLibDriverFreeStream,
				SoundLibDriverChangeOwnerSimple,
				SoundLibDriverChangeOwnerStream,
				SoundLibDriverAllocDAC,
				SoundLibDriverEnableDAC,
				SoundLibDriverPlayToDAC,
				SoundLibDriverDisableDAC,
				SoundLibDriverFreeDAC,
				SoundLibDriverPlayLMemSimpleFM,
				SoundLibDriverReallocLMemSimpleFM


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing

CALLED BY:	SoundLibDriverStrategy
PASS:		who knows...
RETURN:		who cares...
DESTROYED:	nothing
SIDE EFFECTS:
		clears carry flag
PSEUDO CODE/STRATEGY:
		fast.  Isn't it?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverDoNothing	proc	far
	.enter
	clc
	.leave
	ret
SoundLibDriverDoNothing	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverWriterNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification recipient routine

CALLED BY:	Stream driver
PASS:		ax	-> segment of Sound associated with Stream
		bx	-> stream segment 
		cx	-> # of bytes that can be written
		dx	-> stream token

		INTERRUPTS_OFF acceptable

RETURN:		nothing
DESTROYED:	nothing (allowed: ax, bx, si, di)
SIDE EFFECTS:
		Can V activeReaderSem for stream
		Non-reentrant (for the same stream)

PSEUDO CODE/STRATEGY:

		When a driver reads DAC data from the stream,
		we need to re-fill it.  There are also
		some things we need to take care of when
			a) we finish writing all of our
				data to the stream
			b) the reader reads all of the data
				from the stream, and we
				have no more to write.


		There is a hierarchy of semaphores that need
			to be manipulated:

			DataSem - This semaphore allows the
			thread which called PlayToDAC to block
			until the notification routine has
			succeeded in writing all of its data
			to the stream

			ActiveReaderSem - This semaphore allows
			a pending writer to block until the stream
			empties, thus allowing the DAC to change
			speeds and formats, etc.

		A thread must make sure it grabs the Writer semaphore
			and the mutEx semaphore (in that order),
			before it grabs anything else...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/11/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverWriterNotification	proc	far
	uses	cx, dx, ds, es
	.enter

	;
	;  Move segment of sound structure into es.
	;	Verify that it is a sound segment
	;	Verify that this stream is associated with this sound
	mov	ds, ax				; ds <- Sound segment
	mov	es, ax				; es <- Sound segment

EC<	call	SoundLibDriverVerifySoundBlockDS			>

EC<	cmp	ds:[SC_position.SSS_stream].SSS_streamSegment, bx	>
EC<	ERROR_NE SOUND_BAD_STREAM_IN_NOTIFICATION			>

EC<	push	ds							>
EC<	mov	ds, bx				; ds <- stream segment	>
EC<	tst	ds:[SD_writer.SSD_data].SN_ack	; are we Ack'ed?	>
EC<	ERROR_Z	SOUND_CORRUPT_SOUND_STREAM	; hope so...		>
EC<	pop	ds							>

	;
	;  Do we have more data to write to the stream?
	tst	ds:[SC_position.SSS_stream].SSS_dataRemaining
	jz	lookForEOS

	;
	;  Write as much data as we can to the stream.
	;	Get the buffer to copy from, and the amount
	;		in the buffer.
	;	Do some bounds checking on the data buffer
	;	Try to write all of it to the stream
	push	ds, es				; save sound segments

	mov	cx, ds:[SC_position.SSS_stream].SSS_dataRemaining

	lds	si, ds:[SC_position.SSS_stream].SSS_buffer

	mov	ax, segment dgroup		; es <- dgroup of driver
	mov	es, ax

	mov	ax, STREAM_NOBLOCK		; we can be called with int off

	mov	di, DR_STREAM_WRITE
	call	es:[streamStrategy]	; cx <- # of bytes actually written

	pop	ds, es				; restore sound segment

	LONG jc	errorWriting

adjustPointers:

EC<	call	SoundLibDriverVerifySoundBlockDS			>

EC<	cmp	ds:[SC_position.SSS_stream].SSS_streamSegment, bx	>
EC<	ERROR_NE SOUND_BAD_STREAM_IN_NOTIFICATION			>

	sub	ds:[SC_position.SSS_stream].SSS_dataRemaining, cx
EC<	ERROR_B	SOUND_CORRUPT_SOUND_STREAM	; negative remaining	>

	add	ds:[SC_position.SSS_stream].SSS_buffer.offset, cx

	;
	;  Determine how many bytes remain to be read.
	;  Instead of using a query or some other stream driver
	;  routine, just look at the stream data and see for ourselves.
	;  If it is zero, deactive the Reader
	mov	ds, bx				; ds <- stream segment

	tst	ds:[SD_reader.SSD_sem].Sem_value
	jz	deactivateReader

done:
	;
	;  Whether we did anything or not, we need to re-set the
	;	propper fields so we are informed if the status
	;	of the stream changes.  If we don't do this,
	;	we will not recieve another notification until we
	;	write something.  Since we can easily be finished
	;	writing, and still waiting for the stream to
	;	empty, we must "fiddle" with things
	clr	ds:[SD_writer.SSD_data].SN_ack
	and	ds:[SD_state], not mask SS_WDATA

	.leave
	ret
;----------------------------------------------
lookForEOS:
EC<	call	SoundLibDriverVerifySoundBlockDS			>
	;
	;  We have no more to write, but we don't know if
	;	the reader is done. So, we check the semaphore
	;	value of the reader, if it is zero,
	;	we know we are done.
	tst	ds:[SC_position.SSS_stream].SSS_buffer.segment
	jz	checkReader

	;
	;  We have no more data to write, so we should
	;	V the dataSem semaphore so that we free
	;	up the current writer's thread.
	;  We only want to do this once, however, so we
	;	zero the buffer segment, indicating we
	;	have no active writer, so we better not
	;	try to get to any of the DAC stuff.
	clrdw	ds:[SC_position.SSS_stream].SSS_buffer
vDataSem::

	VSem	ds, SC_position.SSS_stream.SSS_dataSem

checkReader:
	;
	;  We have one more semaphore to V, but we only
	;	wish to do so when (and if) the stream gets
	;	emptied.
	mov	ds, bx				; ds <- stream segment
	cmp	ds:[SD_reader.SSD_sem].Sem_value, 0
	jne	done


deactivateReader:
EC<	call	SoundLibDriverVerifySoundBlockES			>

	;
	;  No more bytes to read.  V the semaphore and return
	pushf
	INT_OFF

	mov	es:[SC_position.SSS_stream].SSS_activeReaderSem.Sem_value, 1

	mov	bx, offset SC_position.SSS_stream.SSS_activeReaderSem.Sem_queue

	cmp	{word} es:[bx], 0	; test semaphore queue

	je	afterWakeUp

	mov	ax, es				; ax:bx is queue to wake up
	call	ThreadWakeUpQueue	; free thread waiting for Change

afterWakeUp:
	call	SafePopf
	jmp	short done

errorWriting:
	;
	;  We experienced an error when we tried to write to
	;	the stream.
	;  The only thing we can really do is clear cx (indicating
	;	that no bytes were written) and go on and do our
	;	thing....
	clr	cx
	jmp	adjustPointers


SoundLibDriverWriterNotification	endp

ResidentCode	ends

CommonCode	segment

;-----------------------------------------------------------------------------
;
;		MISC. INDEPENDENT ROUTINES
;
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverEnterLibraryRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	increment the inUseCount

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		carry set if unable to enter
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/ 4/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverEnterLibraryRoutine	proc	far
	uses	ax, ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax

	pushf						; save old flags

	INT_OFF						; disable interrupts

	tst	ds:[exclusiveAccess]
	jnz	error

	clr	ds:[librarySemaphore].Sem_value

	inc	ds:[libraryAccess]

	call	SafePopf				; restore int status
	clc						; everying A.O.K.
done:
	
	.leave
	ret

error:
	call	SafePopf				; restore int status
	stc						; things not A.O.K.
	jmp	short done
SoundLibDriverEnterLibraryRoutine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverExitLibraryRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement inUseCount and free blocking threads

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		decrements inUseCount
		V's semaphore
PSEUDO CODE/STRATEGY:
		decrement libraryAccess

		on a zero, V semaphore

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/ 4/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverExitLibraryRoutine	proc	far
	uses	ax, bx, ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax

	pushf
	INT_OFF
	dec	ds:[libraryAccess]
	jnz	done

	VSem	ds, librarySemaphore,TRASH_AX_BX

done:
	call	SafePopf
	.leave
	ret
SoundLibDriverExitLibraryRoutine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverFreeSimple
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up all memory associated with a Simple stream

CALLED BY:	GLOBAL
PASS:		bx	-> handle for SoundControl

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	
		frees up memory from the global heap
		frees up the mutual exclusion semaphore

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverFreeSimple	proc	far
	uses	ax, bx, ds, di
	.enter
	;
	;  lock down the SoundStreamStatus
	call	MemLock
EC<	ERROR_C SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	mov	ds, ax					; ds <- block
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	;
	;  move the handle of the semaphore into bx and free it
	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadFreeSem

	;
	;  move the handle of the block into bx and free it
	mov	bx, ds:[SC_status.SBS_blockHandle]	; bx <- handle
	call	MemFree					; free up block
done::
	.leave
	ret

SoundLibDriverFreeSimple	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverFreeStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a sound stream

CALLED BY:	Strategy Routine
PASS:		bx	-> token to free
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		frees up block on global heap
		frees up lots of handles

PSEUDO CODE/STRATEGY:
		free up stream if necessary
		free up handles
		free up block

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverFreeStream	proc	far
	uses	ax, bx, di, ds
	.enter

	call	MemLock
EC<	ERROR_C SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	mov	ds, ax
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	;
	;  Get mutEx sem.
	;
	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadPSem

	;
	;  Free up stream
	;
	mov	bx, ds:[SC_position.SSS_stream].SSS_streamSegment
	mov	ax, STREAM_DISCARD
	mov	di, DR_STREAM_CLOSE
	call	StreamStrategy

	;
	;  Free up semaphore handles
	;
	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadFreeSem

	;
	;  Free up block
	;
	mov	bx, ds:[SC_status.SBS_blockHandle]
	call	MemFree
done::
	.leave
	ret
SoundLibDriverFreeStream	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverChangeOwnerSimple
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter the owner for all the sounds handles

CALLED BY:	Strategy Routine

PASS:		ax	-> new owner for sound
		bx	-> handle for sound

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		changes the owner of the block itself, the semaphores
		for the block and any streams or other handles that
		are associated with the block.  Does not change
		permissions or the state of any of the handles.

PSEUDO CODE/STRATEGY:
		change the owner of the handle of the block
		lock it down
		determine the type
		change the semaphores
		look for a stream
		change the stream
		unlock the block
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverChangeOwnerSimple	proc	far
	uses	ax,cx,ds
	.enter
	mov	cx, ax				; save owner

	call	HandleModifyOwner		; set sound's owner
	
	call	MemLock				; lock block for changing
EC<	ERROR_C	SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	mov	ds, ax				; ds <- segment of block
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	mov	ax, cx				; ax <- new owner
	mov	bx, ds:[SC_status.SBS_mutExSem]	; bx <- mutEx sem. handle
	call	HandleModifyOwner		; set sound's new owner

	INT_OFF					; bx <- handle of current timer
	mov	bx, ds:[SC_format.SFS_fm.SFMS_timerHandle]

	tst	bx				; is there a current timer?
	jz	timerChanged

	mov_tr	ax, cx				; ax <- new owner
	call	HandleModifyOwner		; set sound's new owner

timerChanged:
	INT_ON

	mov	bx, ds:[SC_status.SBS_blockHandle]
	call	MemUnlock		; unlock the block

done::
	.leave
	ret
SoundLibDriverChangeOwnerSimple	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverChangeOwnerStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the owner of a Stream based sound

CALLED BY:	Strategy Routine
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverChangeOwnerStream	proc	far
	.enter
	mov	cx, ax				; save owner

	call	HandleModifyOwner		; set sound's owner
	
	call	MemLock				; lock block for changing
EC<	ERROR_C SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	mov	ds, ax			; ds <- segment of block
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	mov	ax, cx				; ax <- new owner
	mov	bx, ds:[SC_status.SBS_mutExSem]	; bx <- mutEx sem. handle
	call	HandleModifyOwner		; set sound's new owner

	INT_OFF					; bx <- handle of current timer
	mov	bx, ds:[SC_format.SFS_fm.SFMS_timerHandle]
	tst	bx				; is there a current timer?
	jz	timerChanged

	mov_tr	ax, cx				; ax <- new owner
	call	HandleModifyOwner		; set sound's new owner

timerChanged:
	INT_ON

	mov	bx, ds:[SC_status.SBS_blockHandle]
	call	MemUnlock			; unlock the block

done::
	.leave
	ret

%out     SoundLibDriverChangeOwnerStream needs to deal with streams

SoundLibDriverChangeOwnerStream	endp

CommonCode	ends


;-----------------------------------------------------------------------------
;
;		SIMPLE FM SOUND ROUTINES
;
;-----------------------------------------------------------------------------

	;
	;  A simple sound is not necessarily less complex than another
	;	sound, it is simply one which is entirly within fixed
	;	memory while it plays.  This does not necessarily mean
	;	it is in a fixed block, just that while it is playing,
	;	it will never move.
	;
	;  This allows a great many optimizations to take place,
	;	thus making the playing of such a sound "simple"

FMCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverPlaySimpleFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take a SimpleSoundStreamStatus and play it

CALLED BY:	GLOBAL

PASS:		ax	-> SoundPriority for stream
		bx	-> handle of SoundSimpleStreamStatus
		cx	-> tempo of song (only used if DeltaTempo in song)
		dl	-> EOSFlag for sound

RETURN:		carry clear on ok
		ax destroyed

		carry set on error
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	ax

SIDE EFFECTS:	
		plays piece

PSEUDO CODE/STRATEGY:
		turn off any timer chain currently active.
		re-set pointer
		re-set priority
		re-set tempo
		start timer chain up again.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IS_MS_TIMER		equ	1

SoundLibDriverPlaySimpleFM	proc	far
	uses	bx,si,ds
	.enter

	;
	;  First, we need to check to see if this SoundStatus is already being
	;  played, and if so, turn it off.
						; bx = SoundControl
	call	SoundCheckExclusiveSimpleFM  ; ds <- SoundControl segment
					; carry set on error
	jc	done				; something went wrong, bail.

EC<	call	SoundLibDriverVerifySoundBlockDS			>

	;
	;  change the necessary parameters.
	mov	ds:[SC_status.SBS_priority], ax		; set new priority
	mov	ds:[SC_format.SFS_fm.SFMS_tempo], cx	; set new tempo
							; ax <- start of song
	mov	ax, ds:[SC_position.SSS_simple.SSS_songBuffer].offset
							; set to start
	mov	ds:[SC_position.SSS_simple.SSS_songPointer], ax
	mov	ds:[SC_status.SBS_EOS], dl		; save flags

	mov	bx, ds:[SC_status.SBS_mutExSem]		; bx <- mutEx sem
							; ds = SoundControl seg
	call	SoundStartSimpleFM	; ax destroyed
	clc
done:
	.leave
	ret
SoundLibDriverPlaySimpleFM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverStopSimpleFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the current timer thread for a simple stream

CALLED BY:	GLOBAL

PASS:		bx	-> handle of SoundControl to stop

RETURN:		carry clear on success
		ax destroyed

			- or -

		carry set on error
		ax	<- SOUND_ERROR reason for problem

DESTROYED:	ax

SIDE EFFECTS:	
		P's mutEx semaphore of stream.

		cancels the current timer and silences all the
		voices allocated to this sound

		V's mutEx semaphore of stream		
PSEUDO CODE/STRATEGY:
		stop the thread.
		call driver and turn off each voice allocated to us.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverStopSimpleFM	proc	far
	uses	bx, es, ds
	.enter
	;
	;  Lock down block so we can check it out.
	call	MemLock
EC<	ERROR_C SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	mov	ds, ax					; ds <- stream seg.
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	;
	;  We are going to modify the stream's parameters, so we
	;  don't want another routine comming along and fiddling
	;  with it, so we grab the semaphore for this stream
	mov	bx, ds:[SC_status.SBS_mutExSem]		; bx <- mutEx semaphore
	call	ThreadPSem				; exclusive access

	call	SoundLibDriverSilenceVoices
	pushf			                        ; preserve error
	push	ax					; preserve error code

EC<	call	SoundLibDriverVerifySoundBlockDS			>
	;
	;  Release mutEx lock on 
	mov	bx, ds:[SC_status.SBS_mutExSem]		; bx <- mutEx semaphore
	call	ThreadVSem				; release mutEx

	mov	bx, ds:[SC_status.SBS_blockHandle]
	call	MemUnlock

	pop	ax					; restore error code
	popf						; restore error
done::
	.leave
	ret
SoundLibDriverStopSimpleFM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverSilenceVoices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the timer and turn off all voices

CALLED BY:	SoundLibDriverStopSimple and SoundLibDriverPlaySimple

PASS:		ds	-> segment of sound

RETURN:		carry clear
		ax destroyed

			- or -

		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	ax

SIDE EFFECTS:	
		stops the current timer,
		silences all the playing voices

PSEUDO CODE/STRATEGY:
		turn interrupts off for a moment while we kill the
		timer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverSilenceVoices	proc	far
	uses	bx, cx, dx, si, es, bp
	.enter
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	mov	ax, segment dgroup			; bx <- lib. dgroup
	mov	es, ax					; es <- lib. dgroup
	;
	;  The next thing we need to do is stop the current timer
	;  chain.  We do this by calling TimerStop.  Note: The handle
	;  and ID could be for the timer that just expired, if that
	;  is the case, TimerStop will not barf, but return with
	;  a carry set.  Fine with us.  We just don't want the timer
	;  chain to come along and use voices we just turned off.
	clr	ax, bx

	INT_OFF
	;
	;  Get and clear the current timer handle and ID
	xchg	bx, ds:[SC_format.SFS_fm].SFMS_timerHandle
	xchg	ax, ds:[SC_format.SFS_fm].SFMS_timerID

	tst	bx					; was any timer set?
	jz	noTimer

	call	TimerStop				; turn off timer

EC<	call	SoundLibDriverVerifySoundBlockDS			>

	;
	;  If this sound buffer was an LMem chunk that we locked down, we
	;  need to unlock it when we complete.  Jason 3/31/94
	;
	test	ds:[SC_status.SBS_EOS], mask EOSF_LMEM_UNLOCK
							; was it an LMem chunk?
	jz	noLMem

	mov	bx, ds:[SC_position.SSS_simple.SSS_songHandle].handle
						; bx <- LMem block handle
EC<	Assert	lmem bx							>
	call	MemUnlock		; no return value

noLMem:
	;
	;  Now unlock the SoundControl block, if appropriate.
	;
	test	ds:[SC_status.SBS_EOS], mask EOSF_UNLOCK ; do we unlock block?
	jz	noTimer
	
	mov	bx, ds:[SC_status.SBS_blockHandle]
EC<	Assert	handle bx						>
	call	MemUnlock				; unlock for truncated
							; song
noTimer:
	INT_ON

EC<	call	SoundLibDriverVerifySoundBlockDS			>
	mov	si, offset SC_voice			; si <- end of 

	mov	cx,ds:[SC_format.SFS_fm].SFMS_voicesUsed; cl # of voices

EC<	tst	cx							>
EC<	ERROR_Z SOUND_ERROR_CAN_NOT_ALLOCATE_CONTROL_WITH_NO_VOICES	>
NEC<	jcxz	done							>
topOfLoop:
	INT_OFF

	cmp	ds:[si].SVS_physicalVoice, NO_VOICE	; is voice sounding?
	jne	turnOffVoice

nextVoice:
	INT_ON

EC<	call	SoundLibDriverVerifySoundBlockDS			>

	add	si, size SoundVoiceStatus

	loop	topOfLoop
done:
	clc

	.leave
	ret

	;
	;  We jump to here when the voice is actually
	;  assigned to a real voice.  We turn off
	;  the voice, free the voice, then mark the
	;  voice as not used.
turnOffVoice:
	mov_tr	ax, cx					; ax <- voice count

	;
	;  Get voice # and mark as silent
	mov	cx, NO_VOICE
	xchg	cx, ds:[si].SVS_physicalVoice

	mov	di, DRE_SOUND_VOICE_SILENCE
	call	es:[soundSynthStrategy]			; silence the voice

EC<	call	SoundLibDriverVerifySoundBlockDS			>
	;
	; remove voice from active list
	call	SoundVoiceDeactivateFar			; remove from active
	call	SoundVoiceFreeFar			; move to free list

	mov_tr	cx, ax					; cx <- voice count
	jmp	short	nextVoice
SoundLibDriverSilenceVoices	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverAllocSimpleFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate space on the global heap for a simple stream

CALLED BY:	Strategy routine
PASS:		bx:si	-> song in fixed memory to play
		cx	-> # of voices used in song

RETURN:		carry clear
		bx	<- handle for SoundControl
		ax destroyed

			- or -
		carry set
		ax	<- SOUND_ERROR reason for failure
		bx destroyed

DESTROYED:	ax

SIDE EFFECTS:	
		allocates a block on the global heap.

PSEUDO CODE/STRATEGY:
		allocate space,
		set up pointers		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		.assert	size SoundVoiceStatus	eq	8
SoundLibDriverAllocSimpleFM	proc	far
	uses	cx, dx, es, ds
	.enter
	tst	cx
EC<	ERROR_Z	SOUND_ERROR_CAN_NOT_ALLOCATE_CONTROL_WITH_NO_VOICES	>
NEC<	jz	noVoices						>
NEC<afterCheck:								>
	;
	;  allocate a block on the global heap.  The block must
	;  contain the basic stream information as well as fptrs
	;  for each voice to the current setting for voice
	mov	ds, bx					; ds <- song segment
	push	cx					; save # of voices

	mov_tr	ax, cx					; ax <- # of voices
	shl	ax, 1					; ax <- ax * 2
	shl	ax, 1					; ax <- ax * 4
	shl	ax, 1					; ax <- ax * size SVS
	add	ax, size SoundControl			; ax <- sound + voice
	mov	cx, mask HF_SWAPABLE or mask HF_SHARABLE or   \
		(( mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8)
	call	MemAlloc		; ax <- segment, bx <- handle
	jc	memoryFull

	pop	cx					; cx <- # of voices

	mov	dx, ds					; dx:si <- song
	mov	ds, ax					; ds <- sound segment

	call	SoundLibDriverInitSimpleFM

EC<	call	SoundLibDriverVerifySoundBlockDS			>

	mov	bx, ds:[SC_status.SBS_blockHandle]	; bx <- handle of block
	call	MemUnlock				; unlock block
	clc

done:
	.leave
	ret

NEC<noVoices:								>
NEC<									>
NEC<	;  They want us to allocate a sound with no voices...		>
NEC<	;  Why?!?							>
NEC<	mov	cl, 1							>
NEC<	jmp	short afterCheck					>


memoryFull:
	;
	;  We had an error trying to allocate the sound.
	;  Set up error and propogate carry.
	mov	ax, SOUND_ERROR_OUT_OF_MEMORY
EC<	mov	bx, SOUND_ID				; set bx illegal >
	jmp	short done
SoundLibDriverAllocSimpleFM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverReallocSimpleFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the song pointer for a sound stream

CALLED BY:	Strategy Routine
PASS:		bx	-> old handle for SoundControl
		ds:si	-> new song buffer to play

RETURN:		carry clear	
		bx	<- new handle for SoundControl
		ax destroyed

			- or -
		carry set
		ax	<- SOUND_ERROR reason for error
		bx destroyed

DESTROYED:	ax

SIDE EFFECTS:	
		could free up and/or allocate space on the global heap

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverReallocSimpleFM	proc	far
	uses	bx, es
	.enter
	call	MemLock
EC<	ERROR_C SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	mov	es, ax			; es <- sound segment

EC<	call	SoundLibDriverVerifySoundBlockES			>

	mov	es:[SC_position.SSS_simple.SSS_songBuffer].segment, ds
	mov	es:[SC_position.SSS_simple.SSS_songBuffer].offset, si

	mov	bx, es:[SC_status.SBS_blockHandle]
	call	MemUnlock

	clc
done::
	.leave
	ret
SoundLibDriverReallocSimpleFM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverReallocLMemSimpleFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the song pointer for a sound stream to an
		optr containing the sound buffer

CALLED BY:	Strategy Routine
PASS:		bx	-> old handle for SoundControl
		^ldx:si	-> new song buffer to play

RETURN:		carry clear	
		bx	<- new handle for SoundControl
		ax destroyed

			- or -
		carry set
		ax	<- SOUND_ERROR reason for error
		bx destroyed

DESTROYED:	ax

SIDE EFFECTS:	
		could free up and/or allocate space on the global heap

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverReallocLMemSimpleFM	proc	far
	uses	bx, es
	.enter
	call	MemLock
EC<	ERROR_C SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	mov	es, ax			; es <- sound segment

EC<	call	SoundLibDriverVerifySoundBlockES			>

	mov	es:[SC_position.SSS_simple.SSS_songHandle].segment, dx
	mov	es:[SC_position.SSS_simple.SSS_songHandle].offset, si

	mov	bx, es:[SC_status.SBS_blockHandle]
	call	MemUnlock

	clc
done::
	.leave
	ret
SoundLibDriverReallocLMemSimpleFM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverInitSimpleFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a simple sound stream

CALLED BY:	Strategy Routine, ...Alloc....

PASS:		ax	-> segment of sound
		bx	-> block handle
		cx	-> # of stream's voices
		dx:si	-> location of song

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	
		allocates a handle for a mutEx semaphore

PSEUDO CODE/STRATEGY:
		save the appropriate data, set all the voices
		to un-assigned, allocate a mutEx semaphore, save
		its handle and return.

		We can not assume the things are zeroed, so we
		need to do that ourselves.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/28/92		Initial version
	TS	4/14/93		Optimized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverInitSimpleFM	proc	far
	uses	cx, ds, si
	.enter
EC<	tst	cx							>
EC<	ERROR_Z SOUND_ERROR_CAN_NOT_ALLOCATE_CONTROL_WITH_NO_VOICES	>

	mov	ds, ax					; ds <- SSS segment
	;
	;  Set up basic Sound parameters
	mov	ds:[SC_status.SBS_blockHandle], bx	; save handle
	mov	ds:[SC_status.SBS_ID], SOUND_ID		; set secret ID #...

	;
	;  Mark as ST_SIMPLE_FM, but as ST_SIMPLE_FM is
	;  zero, the fastest thing to do is clear it.

	clr	ax					; for fast clears...
	czr	ax, ds:[SC_status.SBS_type]		; mem <- ST_SIMPLE_FM

	;
	;  Set up format information
	czr	ax, ds:[SC_format.SFS_fm].SFMS_timerHandle
	czr	ax, ds:[SC_format.SFS_fm].SFMS_timerID
	czr	ax, ds:[SC_format.SFS_fm].SFMS_timeRemaining

	mov	ds:[SC_format.SFS_fm].SFMS_voicesUsed, cx

	;
	;  Set up positional information.  Note that songBuffer and
	;  songHandle are copies.  This is to ensure that if this is
	;  an LMem handle, a copy is retained in the songHandle field
	;  for later dereferencing.  Jason 4/5/94
	;
	movdw	ds:[SC_position.SSS_simple].SSS_songBuffer, dxsi
	movdw	ds:[SC_position.SSS_simple].SSS_songHandle, dxsi

	czr	ax, ds:[SC_position.SSS_simple].SSS_songPointer

	;
	;  Initialize voices to no-voice
	mov	si, size SoundControl			; di <- 1st voice

	jcxz	allocSems
topOfLoop:
EC<	EC_BOUNDS ds,si						>
	mov	ds:[si].SVS_physicalVoice, NO_VOICE	; set to no-voice
	CheckHack 	<DEFAULT_INSTRUMENT lt 65536>	; assume instrument
							; fits in a word
	mov	ds:[si].SVS_instrument.low, DEFAULT_INSTRUMENT
	clr	ds:[si].SVS_instrument.high 		; instru<-
							; DEFAULT_INSTRUMENT 
	add	si, size SoundVoiceStatus		; di <- next voice
	loop	topOfLoop

allocSems:
	;
	;  Now, allocate a semaphore handle for the mutual-exclusion
	;  semaphore, but make the semaphore owned by the same geode
	;  that owns the block.  This ensures that the UI (who may
	;  be doing and SST_CUSTOM_BUFFER) will own both the block
	;  that contains the sound, and the semaphores associated
	;  with them.
	mov_tr	ax, bx					; ax <- block handle

	mov	bx, 1					; mutEx semaphore
	call	ThreadAllocSem		; bx <- handle of semaphore
	mov	ds:[SC_status.SBS_mutExSem], bx		; save semaphore handle

	xchg	ax, bx					; ax <- mutEx semaphore
							; bx <- block handle

	call	MemOwner		; bx <- owner of block

	xchg	ax, bx					; ax <- owner of block
							; bx <- mutEx semaphore

	call	HandleModifyOwner	; ax destroyed

	mov	ax, ds					; ax <- segment
	mov	bx, ds:[SC_status.SBS_blockHandle]	; bx <- handle
	clc
done::
	.leave
	ret
SoundLibDriverInitSimpleFM	endp

;-----------------------------------------------------------------------------
;
;		FM NOTE ROUTINES
;
;-----------------------------------------------------------------------------

	;
	;  The only thing different between a Note and a Simple FM
	;	sound is that a note has a pre-defined sound buffer.
	;  This means allocating and Re-Allocating a note is a little
	;	different than other simple sounds.

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverAllocNoteFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a note

CALLED BY:	GLOBAL

PASS:		bx:si	-> instrument setting
		ax	-> frequency
		cx	-> volume
		dx	-> delta type for duration
		bp	-> duration value

RETURN:		carry clear
		bx	<- handle of sound
		ax destroyed

		carry set
		ax 	<- SOUND_ERROR reason for failure
		bx destroyed

DESTROYED:	ax

SIDE EFFECTS:	
		allocates space on the global heap

PSEUDO CODE/STRATEGY:
		allocate one large block to contain the stream information,
		the voice and the stream intself.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SONG_START	equ	size SoundControl + size SoundVoiceStatus
NOTE_LENGTH	equ	SONG_START + size StandardNoteBuffer
SoundLibDriverAllocNoteFM	proc	far
	uses	di, ds, es
	.enter

	push	bx, si, ax, cx, dx	; save trashed registers

	;
	;  allocate a sharable, swapable block that is large enough to
	;  contain the stream, the single voice the note uses and
	;  the sound strea which defines the note.
	mov	ax, size SoundControl + size SoundVoiceStatus + \
		    size StandardNoteBuffer
	mov	cx, mask HF_SWAPABLE or mask HF_SHARABLE 		 \
                 or ((mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8)
	call	MemAlloc		; ax <- segment, bx <- handle
	jc	outOfMemory

	clr	dx					; mark sound as note
	mov	si, SONG_START				; si <- offset to song

	mov	cx, 1					; uses 1 voice
	call	SoundLibDriverInitSimpleFM		; set up basics

	;
	;  Now we have a block that will contain both the stream
	;  status as well as the data.
	mov	es, ax					; es <- sound segment
	mov	di, si					; es:di <- "song"
EC<	call	SoundLibDriverVerifySoundBlockES			>

	segmov	ds, cs, ax				; ds <- code segment
	mov	si, offset oneNoteSong			; ds:si <- song

	mov	cx, size StandardNoteBuffer		; cx <- # of bytes
	shr	cx, 1
	jc	moveOddByte

moveWords:
	rep	movsw					; copy song

	;
	;  Set up note values
	pop	bx, si, ax, cx, dx			; restore registers

	mov	es:[SONG_START].SNB_instrument.segment, bx ; set instrument
	mov	es:[SONG_START].SNB_instrument.offset, si
	mov	es:[SONG_START].SNB_frequency, ax	; set freq. of note
	mov	es:[SONG_START].SNB_attack, cx		; set volume of note
	mov	es:[SONG_START].SNB_deltaType, dx	; set timer type

	mov	es:[SONG_START].SNB_deltaTime, bp	; set duration of note

	mov	bx, es:[SC_status.SBS_blockHandle]	; get handle of block
	call	MemUnlock				; free it up

	clc
done:
	.leave
	ret

moveOddByte:
	movsb
	jmp	short moveWords

outOfMemory:
	;
	;  clean up stack
	pop	bx, si, ax, cx, dx			; restore trashed regs.

	;
	;  We had an error allocating the block
	;  Mark it as such.
	mov	ax, SOUND_ERROR_OUT_OF_MEMORY
EC<	mov	bx, SOUND_ID						>
	jmp	short done

	;
	;  Standard one note song copied into the note buffer
oneNoteSong	StandardNoteBuffer	<>

SoundLibDriverAllocNoteFM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverReallocNoteFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reallocate a note

CALLED BY:	Strategy Routine
PASS:		bx	-> handle for note
		ax	-> frequency for note
		cx	-> volume for note
		dx	-> timer type
		bp	-> timer value
		ds:si	-> new instrument setting
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		none.
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverReallocNoteFM	proc	far
	uses	bx,ds
	.enter
	;
	;  Lock down the block so we can alter the
	;  data
	push	ax				; save frequency
	push	ds				; save instrument segment

	call	MemLock
EC<	ERROR_C	SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	mov	ds, ax				; ds <- block segment
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	mov	bx, size SoundControl + size SoundVoiceStatus

	pop	ds:[bx].SNB_instrument.segment	; set new segment:offset
	mov	ds:[bx].SNB_instrument.offset, si
	pop	ds:[bx].SNB_frequency		; set new frequency
	mov	ds:[bx].SNB_attack, cx		; set new volume
	mov	ds:[bx].SNB_deltaType, dx	; set new duration type
	mov	ds:[bx].SNB_deltaTime, bp	; set new duration length

	mov	bx, ds:[SC_status.SBS_blockHandle]	; bx <- stream token
	call	MemUnlock

	clc
done::
	.leave
	ret
SoundLibDriverReallocNoteFM	endp

FMCode			ends


DACCode			segment	resource

;-----------------------------------------------------------------------------
;
;		DAC Driver Interface
;
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverAllocDAC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up a DAC Sound structure

CALLED BY:	Strategy Routine

PASS:		nothing

RETURN:		carry clear
		bx	<- handle for sound
		ax destroyed

			- or -
		carry set
		ax	<- SOUND_ERROR reason for failure
		bx destroyed

DESTROYED:	ax

SIDE EFFECTS:	
		allocates a handle for the sound block
		allocates a handle for all the semaphores

PSEUDO CODE/STRATEGY:
		allocate space for the sound block
		initialize the data

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverAllocDAC	proc	far
	uses	cx, ds
	.enter
	;
	;  Allocate space for the sound block.  Extra space
	;	is required, but it is known in advance.
	;  With each DAC goes to one and only one physical DAC
	;	so only one SoundVoiceStatus need be allocated
	;
	mov	ax, size SoundControl + size SoundVoiceStatus
	mov	cx, mask HF_SWAPABLE or mask HF_SHARABLE or \
		  ((mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8)
	call	MemAlloc	; ax <- segment, bx <- handle
	jc	outOfMemory

	mov	ds, ax				; ds <- segment of DAC sound

	;
	;  Now that we have a structure, we need to set up the
	;	seamphore and starting values and such.
	call	SoundLibDriverInitDAC		; nothing destroyed

EC<	call	SoundLibDriverVerifySoundBlockDS			>

	call	MemUnlock			; unlock block

done:
	.leave
	ret

outOfMemory:
	mov	ax, SOUND_ERROR_OUT_OF_MEMORY	; mark as error
EC<	mov	bx, SOUND_ID			; return illegal value	>
	jmp	short done
SoundLibDriverAllocDAC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverInitDAC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the Sound structure for a Simple DAC sound

CALLED BY:	Strategy Routine
PASS:		bx	-> block handle for sound
		ds	-> segment for sound

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		alters Sound structure to fit parameters

PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverInitDAC	proc	far
	uses	ax
	.enter
	mov	ds:[SC_status.SBS_blockHandle], bx	; set block handle

	;
	;  Initialize the mutEx semaphore for the libDriver routines.
	;  Initialize the mutEx semaphore for the writing threads
	;  Initialize the mutEx semaphore for reader
	;  Initialize the transfer complete semaphore for writer
	mov	bx, 1
	call	ThreadAllocSem

	mov	ds:[SC_status.SBS_mutExSem], bx

	mov	ds:[SC_status.SBS_ID], SOUND_ID		; Set ID

	;
	;  We need to clear memory quickly.  That fastest way to
	;  do it is to have a zero register hanging around that
	;  we can store...
	clr	ax

	;
	;  Set up Basic status structure
	mov	ds:[SC_status.SBS_type], ST_STREAM_DAC
	czr	al, ds:[SC_status.SBS_EOS]	; no unlock or destroy

	;
	;  Initialize the SoundVoiceStatus structure
	;  (Instrument is not needed to be initialized for DAC)
	;
	mov	ds:[SC_voice].SVS_physicalVoice, NO_VOICE

	;
	;  Initialize SC_format structure to an illegal
	;	rate and format.  This ensures that
	;	the first time something is played on
	;	the stream, the DAC will be re-initialized
	czr	ax, ds:[SC_format.SFS_dac].SDACS_rate
	mov	ds:[SC_format.SFS_dac].SDACS_format, -1
	mov	ds:[SC_format.SFS_dac].SDACS_manufactID, -1

	;
	;  Initialize SC_position structure
	czr	ax, ds:[SC_position.SSS_stream].SSS_streamToken
	czr	ax, ds:[SC_position.SSS_stream].SSS_streamSegment

	czr	ax, ds:[SC_position.SSS_stream].SSS_dataRemaining
	czr	ax, ds:[SC_position.SSS_stream].SSS_dataOnStream

	mov	ds:[SC_position.SSS_stream].SSS_writerSem.Sem_value, 1
	czr	ax, ds:[SC_position.SSS_stream].SSS_writerSem.Sem_queue

	mov	ds:[SC_position.SSS_stream].SSS_activeReaderSem.Sem_value, 1
	czr	ax, ds:[SC_position.SSS_stream].SSS_activeReaderSem.Sem_queue

	clrdw	ds:[SC_position.SSS_stream].SSS_dataSem, ax
	clrdw	ds:[SC_position.SSS_stream].SSS_buffer, ax

	czr	al, ds:[SC_position.SSS_stream].SSS_streamState

	;
	;  Restore trashed registers
	mov	bx, ds:[SC_status.SBS_blockHandle]	; bx <- handle of Sound

done::
	.leave
	ret
SoundLibDriverInitDAC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverEnableDAC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a real DAC to go with the stream

CALLED BY:	Strategy Routine
PASS:		ax	-> priority for DAC
		bx	-> handle of sound

		cx	-> rate for sample
		dx	-> ManufacturerID for sample
		si	-> Format for sample

RETURN:		carry clear
		ax destroyed

			- or -
		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	ax

SIDE EFFECTS:	
		attach stream to device driver
		locks block on heap

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/18/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverEnableDAC	proc	far
	uses	bx, ds
	.enter

	push	ax				; save priority

	;
	;  We need to change the stream settings, so lock down
	;	the block
	call	MemLock
EC<	ERROR_C SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	mov	ds, ax				; ds <- block segment
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	mov	bx, ds:[SC_status.SBS_mutExSem]	; get exclusive access to sound
	call	ThreadPSem

	;
	;  Change Sound structure to reflect new priority,
	;	format and rate.
	pop	ax					; ax <- priority

	mov	ds:[SC_status.SBS_priority], ax		; save priority
	mov	ds:[SC_format.SFS_dac].SDACS_rate, cx
	mov	ds:[SC_format.SFS_dac].SDACS_manufactID, dx
	mov	ds:[SC_format.SFS_dac].SDACS_format, si

	;
	;  Marks stream as active
	or	ds:[SC_position.SSS_stream].SSS_streamState, mask SSS_active

	;
	;  Associate a DAC with the current stream
	;	and set it to the propper rate
	;	and format.
	call	SoundLibDriverGetDACAndStreamForSound

	push	ax					; save error

	;
	;  Release MutEx Sem
	mov	bx, ds:[SC_status.SBS_mutExSem]		; bx <- handle of sem
	call	ThreadVSem

	pop	ax					; restore error

	.leave
	ret
SoundLibDriverEnableDAC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverGetDACAndStreamForSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the priority for a Sound get a DAC and stream

CALLED BY:	SoundLibDriverEnableDAC, SoundLibDriverPlayToDAC
PASS:		ax	-> priority
		dx	-> manufactID
		si	-> format

		ds	-> segment for sound

RETURN:		carry clear if ok.
		ax destroyed

		carry set it not ok.
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	ax

SIDE EFFECTS:
		fiddles with the DAC list
		allocates fixed memory

PSEUDO CODE/STRATEGY:
		get a free DAC
		if non available, return carry set
		set up stream
		set up notification
		place DAC on active list

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/25/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverGetDACAndStreamForSound	proc	far
	uses	bx, cx, dx, di, bp, es
	.enter

	;
	;  Get dgroup
	mov	cx, segment dgroup			; cx <- dgroup
	mov	es, cx					; es <- dgroup

EC<	call	SoundLibDriverVerifySoundBlockDS			>

	;
	;  Try to get a free, or less important, DAC
	;	for the sound
	INT_OFF
	call	SoundDACGetFree			; get free DAC
	INT_ON				; cx <- DAC #
	jc	noVoice

	;
	;  Save voice # in the S_voice
	mov	ds:[SC_voice].SVS_physicalVoice, cx	; save voice

	;
	;  We got one!  Now associate this sound with the DAC

	mov	bx, ds				; bx <- segment of Sound
	INT_OFF
	call	SoundDACAssign			; assign DAC to sound
	INT_ON

	;
	;  Just incase we stole it from someone else, lets
	;	clean it out and detach it.  Ok?
	mov	di, DRE_SOUND_DAC_FLUSH_DAC
	call	es:[soundSynthStrategy]

	mov	di, DRE_SOUND_DAC_DETTACH_FROM_STREAM
	call	es:[soundSynthStrategy]

	;
	;  Set up the DAC to play the new sample format and such
	mov_tr	ax, dx					; ax <- manufactID
	mov	bx, si					; bx <- format
	mov	dx, ds:[SC_format.SFS_dac].SDACS_rate	; dx <- rate

	mov	di, DRE_SOUND_DAC_SET_SAMPLE_RATE_AND_FORMAT
	INT_OFF
	call	es:[soundSynthStrategy]	; dx <- supported rate,
	INT_ON					; cx <- supported size

	tst	dx
	jz	unsupportedFormat

	;
	;  Now that we have that taken care of, we can
	;	allocate a stream of the requested size
	call	SoundLibDriverCreateStream
	jc	unableToCreateStream

	;
	;  Attach the DAC to a stream.
	mov	cx, ds:[SC_voice].SVS_physicalVoice
	mov	di, DRE_SOUND_DAC_ATTACH_TO_STREAM
	call	es:[soundSynthStrategy]
	jc	errorAttachingToDAC

	;
	;  Save newly attached stream token and segment
	mov	ds:[SC_position.SSS_stream].SSS_streamToken, ax
	mov	ds:[SC_position.SSS_stream].SSS_streamSegment, bx

	;
	;  Set up writer notification and threshold
	;  Ideally, we want the stream to notify us when it
	;	gets empty.  As we can't actually do this, we
	;	get notified everytime the reader reads.  Then,
	;	when it reads for the final time, we V the semaphore
	mov	di, DR_STREAM_SET_THRESHOLD
	mov	ax, STREAM_WRITE		; set threshold for writer
	clr	cx				; set zero threshold
	call	es:[streamStrategy]

	;
	;  Set up notification routine
	mov	cx, segment ResidentCode
	mov	dx, offset SoundLibDriverWriterNotification
	mov	bp, ds				; bp <- segment of Sound
	mov	ax, StreamNotifyType <0, SNE_DATA, SNM_ROUTINE>
	mov	di, DR_STREAM_SET_NOTIFY
	call	es:[streamStrategy]

	;
	;  Place new DAC on active list
	;  It is safe to do this because if things
	;	get appropriated now, we won't notice.
	mov	cx, ds:[SC_voice].SVS_physicalVoice
	INT_OFF
	call	SoundDACActivate		; place on active list
	INT_ON

	clc
done:
	.leave
	ret
noVoice:
	mov	ax, SOUND_ERROR_HARDWARE_NOT_AVAILABLE
EC<	mov	bx, SOUND_ID					>
	stc
	jmp	short done

errorAttachingToDAC:
	;
	;  We tried to attach the stream to the DAC, but we
	;	failed.  We need to free the stream and
	;	then clean up
	mov	ax, STREAM_DISCARD
	mov	di, DR_STREAM_DESTROY
	call	es:[streamStrategy]

	mov	ax, SOUND_ERROR_FAILED_ATTACH_TO_HARDWARE
	stc
	jmp	short done

unsupportedFormat:
	;
	;  We wanted to play something the DAC doesn't support.
	;  Set the stream to NO_VOICE and return the requested
	;	DAC.
	;  Eventually, it would be nice if we could try
	;  	to allocate another DAC.
	mov	cx, NO_VOICE
	INT_OFF
	xchg	cx, ds:[SC_voice].SVS_physicalVoice
	call	SoundDACFree
	INT_ON

	mov	ax, SOUND_ERROR_HARDWARE_DOESNT_SUPPORT_FORMAT
	stc
	jmp	short done

unableToCreateStream:
	;
	;  We tried to create a stream and it failed.  This could
	;	be because the size recommended by the stream was
	;	to large, or because we are running out of memory.
	;  We set the stream to point to to NO_VOICE and return
	;	the requested DAC
	mov	cx, NO_VOICE
	INT_OFF
	xchg	cx, ds:[SC_voice].SVS_physicalVoice
	call	SoundDACFree
	INT_ON

	mov	ax, SOUND_ERROR_UNABLE_TO_ALLOCATE_STREAM
	stc
	jmp	short done
SoundLibDriverGetDACAndStreamForSound	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverCreateStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a stream for the Sound

CALLED BY:	SoundLibDriverGetDACAndStreamForSound
PASS:		cx	-> requested size
		es	-> dgroup of lib/driver
		ds	-> Sound structure

RETURN:		carry clear
		ax	<- stream token (virtual segment)
		bx	<- stream segment
		dx	<- stream size

		carry set
		ax, bx, dx destroyed

DESTROYED:	nothing (ax, bx, dx on error)

SIDE EFFECTS:	allocates a stream.

PSEUDO CODE/STRATEGY:
		See if we are talking to a DMA device.  If so,
			allocate one, check for crossing a page
			boundry, if so, allocate another.

		Free the spare stream
		return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverCreateStream	proc	far
	uses	cx, di
	.enter
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	mov	dx, cx				; dx <- requested size

	;
	;  Alocate a stram of the requested size
	mov	ax, cx				; ax <- requested size
	mov	bx, handle 0			; bx <- handle of sound lib.
	mov	cx, mask HF_FIXED		; cx <- fixed stream
	mov	di, DR_STREAM_CREATE
	call	es:[streamStrategy]
	jc	done

	;
	;  See if we require a DMA stream
	test	es:[driverDACCapability], mask SDDACC_DMA
	jz	done

	;
	;  See if stream flops over page boundry
	mov	cx, bx				; cx <- stream segment
	shl	cx, 1				; cx <- offset into page
	shl	cx, 1
	shl	cx, 1
	shl	cx, 1
	add	cx, offset SD_data		; cx <- beginning of stream
	add	cx, dx				; cx <- end of page
	jnc	done

	;
	;  It flopped.  Allocate another and free the first
	push	bx				; save 1st stream segment

	mov	ax, dx				; ax <- requested size
	mov	bx, handle 0			; bx <- handle of sound lib.
	mov	cx, mask HF_FIXED
	mov	di, DR_STREAM_CREATE
	call	es:[streamStrategy]
	pop	cx				; cx <- 1st stream segment
	jc	done
	
	push	ax, bx				; save segment and token

	mov	bx, cx				; bx <- 1st stream segment
	mov	ax, STREAM_DISCARD		; ax <- nuke it
	mov	di, DR_STREAM_DESTROY		; di <- destroy it
	call	es:[streamStrategy]

	pop	ax, bx
	clc
done:
	.leave
	ret
SoundLibDriverCreateStream	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverPlayToDAC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play a simple DAC sound

CALLED BY:	Strategy Routine
PASS:		bx	-> handle for Sound
		cx	-> length of buffer (in bytes)
		dx:si	-> buffer to play
		ax:bp	-> SampleFormatDescription

RETURN:		carry clear
		ax destroyed

		carry set
		ax 	<- SOUND_ERROR reason for failure
	
DESTROYED:	ax

SIDE EFFECTS:	
		none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverPlayToDAC		proc	far
	uses	bx, ds
	.enter
	;
	;  Make sure buffer is legal
EC<	EC_BOUNDS dx,si							>
EC<	add	si, cx							>
EC<	dec	si							>

EC<	EC_BOUNDS dx,si							>
EC<	inc	si							>
EC<	sub	si, cx							>

	;	
	;  Lock down sound so we can get ahold of it.
	call	MemDerefDS

EC<	call	SoundLibDriverVerifySoundBlockDS			>

	test	ds:[SC_position.SSS_stream].SSS_streamState, mask SSS_active
	jz	inactiveDAC

	;  Before we write to the stream, we have to make
	;	sure we are the only one dumping
	;	stuff into the stream
	PSem	ds, SC_position.SSS_stream.SSS_writerSem

	test	ds:[SC_position.SSS_stream].SSS_streamState,mask SSS_destroying
	jnz	streamDestroyed

	;
	;  As we are going to be fiddling with the
	;	tasty bits, we need to have exclusive
	;	access to the sound
	push	ax, bx

	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadPSem	; trashes ax

	pop	ax, bx
	;
	;  Now that we want to write stuff to the stream,
	;	and we know we can do what we want with it,
	;	see if it has a voice.
	cmp	ds:[SC_voice.SVS_physicalVoice], NO_VOICE
	je	getStreamForSound

writeToStream:

	;
	;  Write the Data to the stream.  Block until we are done.
	;	There are a couple of considerations that
	;	we must think about.
	;		Are we changing formats?
	;		Are We Changing Speeds?
	;		Do We want to concatenate the sounds?
	;	Because of these considerations, we use
	;	a seperate routine to actually write to
	;	the stream
	call	SoundLibDriverWriteToDAC
	jc	errorWriting

vMutExSem:
EC<	call	SoundLibDriverVerifySoundBlockDS			>
	;
	;  We are finished changing things, so we can release
	;	the mutual exlcusion lock
	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadVSem		; destroys ax

	;
	;  We are also finished writing, so we can release that
	;	semaphore as well.
	VSem	ds, SC_position.SSS_stream.SSS_writerSem

done:
	.leave
	ret

inactiveDAC:
	mov	ax, SOUND_ERROR_DAC_UNATTACHED
	stc
	jmp	short done

streamDestroyed:
	tst	ds:[SC_position.SSS_stream.SSS_writerSem].Sem_queue
	jz	destroySound

	VSem	ds, SC_position.SSS_stream.SSS_writerSem, TRASH_AX

streamDestroyedError:
	mov	ax, SOUND_ERROR_STREAM_DESTROYED
	stc
	jmp	short done

errorWriting:
	push	ax					; save error

	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadVSem		; destroys ax

	VSem	ds, SC_position.SSS_stream.SSS_writerSem, TRASH_AX_BX

	pop	ax					; restore error
	stc
	jmp	short done

getStreamForSound:
	;
	;  We are trying to play to a DAC, and we have no
	;	stream.
	;  We try to get a stream, and thus a DAC.
	;
	push	ax, dx, si, es
	mov	es, ax					; es <- format

	mov	dx, es:[bp].SFD_manufact		; dx <- manufacturer ID
	mov	si, es:[bp].SFD_format			; si <- sample format
	mov	ax, es:[bp].SFD_rate
	mov	ds:[SC_format.SFS_dac].SDACS_rate, ax	; set new rate

	mov	ax, segment dgroup
	mov	es, ax

	mov	ax, ds:[SC_status.SBS_priority]		; ax <- priority
	call	SoundLibDriverGetDACAndStreamForSound

	pop	ax, dx, si, es
	jc	vMutExSem
	jmp	writeToStream

destroySound:
	;
	;  When we woke up, the stream was inactive.  See if
	;	we are the last ones out...
	VSem	ds, SC_position.SSS_stream.SSS_writerSem, TRASH_AX_BX

	call	SoundLibDriverFreeDAC
	jmp	short streamDestroyedError

SoundLibDriverPlayToDAC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverWriteToDAC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a block of DAC data to a stream

CALLED BY:	SoundLibDriverPlayToDAC
PASS:		dx:si	-> Buffer to add
		cx	-> length of buffer (in bytes)
		ax:bp	-> SampleFormatDescription

		ds	-> sound segment

RETURN:		carry clear
		ax destroyed

			- or -
		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	ax

SIDE EFFECTS:	
		blocks until block is written to stream

PSEUDO CODE/STRATEGY:
		check for change of format and/or rate.
		if catenate,
			write to stream BLOCK
		if no catenate
			P(emptyStream)
			write to stream BLOCK
		return

		While we do P the activeReaderSem, we don't V it.
		Why?  Because it gets V'ed when the stream empties
		out.  If someone is blocked on the activeReaderSem,
		they are waiting for the stream to clear out.  If
		we take that semaphore, and then give it right back,
		we eliminate its usefullness.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/11/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverWriteToDAC	proc	far
	uses	ax, bx, cx, di, ds, es
	.enter
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	mov	es, ax				; es:bp <- SampleFormatDescrip

	;
	;  Check to make sure settings of new data are the
	;	same as the old data.
	;  First, make sure the rates are the same
	;  Second, make sure the manufacturer's are the same
	;  Third, make sure the formats are the same
	;     If the formats are the same, catenate them if there
	;	is no reference bit, otherwise wait for a change
	;  Fourth, make sure we are to catenate these together
	mov	ax, es:[bp].SFD_rate		; ax <- new rate
	cmp	ax, ds:[SC_format.SFS_dac].SDACS_rate
	LONG jne	waitForChange

	mov	ax, es:[bp].SFD_manufact	; ax <- new manufacturer
	cmp	ax, ds:[SC_format.SFS_dac].SDACS_manufactID
	LONG jne	waitForChange

	mov	ax, es:[bp].SFD_format		; ax <- new format + ref. bit
	xor	ax, ds:[SC_format.SFS_dac].SDACS_format
	and	ax, not mask SMID_reference	; ignore ref. bit
	LONG jnz	waitForChange
	
	test	es:[bp].SFD_format, mask SMID_reference	; does it have ref?
	LONG jnz	waitForChange
	
	test	es:[bp].SFD_playFlags, mask DACPF_CATENATE
	LONG jz		waitForChange

writeDataToStream:
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	;
	;  We can now write the data to the stream.  We want to
	;	write it all, and we are willing to wait, but we
	;	want to be able to write to the stream immediatly
	;	if it ever runs low.  SO.  We write as much
	;	as we can on the first go around, set up the Sound
	;	structure propperly, and then block on the data
	;	complete semaphore and wait for the notification
	;	routine to wake us up.
	INT_OFF

EC<	tst	cx							>
EC<	ERROR_Z SOUND_ATTEMPT_TO_WRITE_NO_DATA_TO_STREAM		>

EC<	tst	ds:[SC_position.SSS_stream].SSS_dataRemaining		>
EC<	ERROR_NZ SOUND_CORRUPT_SOUND_STREAM				>

	mov	ds:[SC_position.SSS_stream].SSS_dataRemaining, cx
EC<	ERROR_C SOUND_CORRUPT_SOUND_STREAM				>

	movdw	ds:[SC_position.SSS_stream].SSS_buffer, dxsi

	;
	;  Determine how much we should be able to write
	;	the first go through.  We need to set up
	;	the pointers for the next writer now,
	;  Because it could be that the write/read notification
	;	thing will occur before we actually get a
	;	chance to return to here.

	mov	bx, ds:[SC_position.SSS_stream].SSS_streamSegment

EC<	mov	es, bx				; es <- stream segment	>
EC<	mov	ax, ds				; ax <- our sound seg.	>
EC<	cmp	ax, es:[SD_writer.SSD_data.SN_data]			>
EC<	ERROR_NE SOUND_CORRUPT_SOUND_STREAM	; Does notification 	>

	mov	ax, segment dgroup		; es <- dgroup of lib/driver
	mov	es, ax

	;
	; We're about to write data to the stream, and shortly thereafter
	; the reader should become active.
	;
	clr	ds:[SC_position.SSS_stream].SSS_activeReaderSem.Sem_value

	mov	ax, STREAM_WRITE		; how much can we write?
	mov	di, DR_STREAM_QUERY

	call	es:[streamStrategy]	; ax <- # of bytes available

EC<	push	ax							>
EC<	pushf								>
EC<	pop	ax							>
EC<	test	ax, mask CPU_INTERRUPT					>
EC<	ERROR_NZ -1							>
EC<	pop	ax							>

	;
	;  Even though we have tons of room, we can't
	;	write more than we have.  Adjust the
	;	level to the lowest of the available
	;	space and the available data.
	cmp	ax, cx
	jb	adjustPointers

	mov_tr	ax, cx				; ax <- all the data avail.

adjustPointers:
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	add	ds:[SC_position.SSS_stream].SSS_buffer.offset, ax
	sub	ds:[SC_position.SSS_stream].SSS_dataRemaining, ax
EC<	ERROR_B SOUND_CORRUPT_SOUND_STREAM				>

	push	ds				; save sound segment

	push	ds:[SC_position.SSS_stream].SSS_buffer.segment

	;
	;  Write data to stream.  Disable writer notification
	;	until we have finished writing.  We can do
	;	this because the writer notification routine
	;	can't DO anything until we are done.
	;
	mov	ds, bx				; ds <- stream segment

	or	ds:[SD_state], mask SS_WDATA	; disable write notification
 
	mov_tr	cx, ax				; cx <- # of bytes avail.

	pop	ds				; ds:si <- buffer to write

	INT_ON

EC<	EC_BOUNDS ds,si							>

	mov	di, DR_STREAM_WRITE
	mov	ax, STREAM_NOBLOCK		; don't block on write

	call	es:[streamStrategy]

	mov	ds, bx				; ds <- stream segment
	and	ds:[SD_state], not mask SS_WDATA; enable write notification

	segmov	ds, es, ax			; ds <- dgroup of lib

	mov	es, bx				; es <- stream segment
	call	StreamWriteDataNotify	; expects es to be segment of stream

	segmov	es, ds, ax			; es <- dgroup of lib

	pop	ds				; ds <- sound segment

EC<	call	SoundLibDriverVerifySoundBlockDS			>

	;
	;  Now we wait for the notification routine to take care
	;	of transfering everything...
	PSem	ds, SC_position.SSS_stream.SSS_dataSem, TRASH_AX_BX

EC<	tst	ds:[SC_position.SSS_stream].SSS_dataRemaining		>
EC<	ERROR_NZ -1 							>

done:
	.leave
	ret

waitForChange:
EC<	call	SoundLibDriverVerifySoundBlockDS			>
	;
	;  Before we write anything the stream must empty itself.
	;  We need to reprogram the DAC to our new rate and format,
	;  but if we do that while data is still in the stream it
	;  will sound wrong.
	push	cx, dx

	PSem	ds, SC_position.SSS_stream.SSS_activeReaderSem, TRASH_AX_BX

	;
	;  Get current DAC #
	mov	cx, ds:[SC_voice].SVS_physicalVoice

	;
	;  Get and update Sample's manufacturer's ID
	mov	ax, es:[bp].SFD_manufact
	mov	ds:[SC_format.SFS_dac].SDACS_manufactID, ax

	;
	;  Get and update Sample's format
	mov	bx, es:[bp].SFD_format  ; bx <- format + ref. bit
	mov	ds:[SC_format.SFS_dac].SDACS_format, bx

	;
	;  Get and update Sample's rate
	mov	dx, es:[bp].SFD_rate
	mov	ds:[SC_format.SFS_dac].SDACS_rate, dx

	mov	di, segment dgroup
	mov	es, di
	mov	di, DRE_SOUND_DAC_SET_SAMPLE_RATE_AND_FORMAT

	INT_OFF
	call	es:[soundSynthStrategy]
	INT_ON

EC<	call	SoundLibDriverVerifySoundBlockDS			>

	tst	dx

	pop	cx, dx

	LONG jnz writeDataToStream		; format supported

	mov	ax, SOUND_ERROR_HARDWARE_DOESNT_SUPPORT_FORMAT
	stc
	jmp	done		; format not supported
SoundLibDriverWriteToDAC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverDisableDAC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal driver DAC is no longer being used

CALLED BY:	Strategy Routine
PASS:		bx	-> Sound Handle
		
RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Detaches DAC from stream
		Returns DAC to free list

PSEUDO CODE/STRATEGY:
		signal Driver to dettach from stream
		Return voice to free list

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/18/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverDisableDAC	proc	far
	uses	ax, cx, dx, ds, es
	.enter
	;
	;  Set up es to have our dgroup
	mov	ax, segment dgroup
	mov	es, ax

	;
	;  First things, as always, first.
	;  Lock down the block so we can get ahold of it.
	;
	call	MemDerefDS			; ds <- segment

EC<	call	SoundLibDriverVerifySoundBlockDS			>

	;
	;  Then grab writer sem so we know any subsequent writer
	;  will notice inactivitity and not try to write to stream.
	PSem	ds, SC_position.SSS_stream.SSS_writerSem, TRASH_AX_BX

	;
	;  Then get mutex so we know we can alter sound
	mov	bx, ds:[SC_status.SBS_mutExSem]	; bx <- handle for semaphore
	call	ThreadPSem

	;
	;  Dettach the stream from the DAC by
	;	calling the sound driver and
	;	then telling the voice manager
	;	to free the voice.

	clr	ax, bx, dx

	mov	cx, NO_VOICE

	INT_OFF
	xchg	cx, ds:[SC_voice].SVS_physicalVoice

	cmp	cx, NO_VOICE
	je	dettachDACFromStream

	;
	;  Remove our current DAC from the active list.
	;  Don't free it yet because we still need to
	;	use it.
	call	SoundDACDeactivate

dettachDACFromStream:
	INT_ON

	;
	; Wait for the stream to empty before dettaching the DAC from it.
	;
	PSem	ds, SC_position.SSS_stream.SSS_activeReaderSem

	cmp	cx, NO_VOICE
	je	freeStream
	
	mov	di, DRE_SOUND_DAC_DETTACH_FROM_STREAM
	call	es:[soundSynthStrategy]

freeStream:
	;
	;  Deactivate DAC.
	and	ds:[SC_position.SSS_stream].SSS_streamState,not mask SSS_active

	;
	;  Get stream handle & token
	INT_OFF

	xchg	ax, ds:[SC_position.SSS_stream].SSS_streamToken
	xchg	bx, ds:[SC_position.SSS_stream].SSS_streamSegment

	INT_ON

	tst	bx
	jz	freeVoice

	;
	;  Destroy the stream.  It is no longer needed.
	mov	ax, STREAM_DISCARD
	mov	di, DR_STREAM_DESTROY
	call	es:[streamStrategy]

freeVoice:
	cmp	cx, NO_VOICE
	je	cleanUp

	;
	;  Return voice to Free list
	;
	INT_OFF
	call	SoundDACFree
	INT_ON

cleanUp:
EC<	call	SoundLibDriverVerifySoundBlockDS			>

	;
	;  Clean up after ourselves.
	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadVSem

	VSem	ds, SC_position.SSS_stream.SSS_writerSem, TRASH_AX_BX

	;
	;  Unlock block (From SoundLibDriverEnableDAC)
	mov	bx, ds:[SC_status.SBS_blockHandle]
	call	MemUnlock
	clc
done::
	.leave
	ret
SoundLibDriverDisableDAC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverFreeDAC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release a DAC and clean up the Sound structure

CALLED BY:	Strategy Routine
PASS:		bx	-> Sound to free

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		informs driver DAC is released
		returns DAC to free list
		frees up block
		frees up semaphore handles

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/11/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverFreeDAC	proc	far
	uses	ax, bx, ds
	.enter
	;
	;  Lock down the block so we can get to it.
	;
	call	MemLock
	mov	ds, ax				; ds <- segment of Sound

EC<	call	SoundLibDriverVerifySoundBlockDS			>

	;
	;  Make sure we are the only ones using	the sound.
	;  But, to ensure that no one gets lost on a semaphore,
	;	P the writer sem first.  Only one writer can
	;	make it past the writer semaphore, and we want
	;	that one writer to be us...
	PSem	ds, SC_position.SSS_stream.SSS_writerSem, TRASH_AX_BX

	;
	;  Mark it as "to be destroyed, not active"
	;  This happens to be the same as SSS_destroying.
	mov	ds:[SC_position.SSS_stream].SSS_streamState,mask SSS_destroying

	;
	;  Get mutEx semaphore so we know everyone is out of
	;	code that references the structure.
	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadPSem

	;
	;  See if there is anyone waiting to write.
	tst	ds:[SC_position.SSS_stream.SSS_writerSem].Sem_queue
	jz	biffEverything

	;
	;  Well, someone is waiting to write.  Let them
	;	clean up the mess.
	VSem	ds, SC_position.SSS_stream.SSS_writerSem, TRASH_AX_BX

done:
	clc

	.leave
	ret

biffEverything:	
	;
	;  Start ripping off the semaphore and nuking it.
	;
	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadFreeSem

	;
	;  Free up the block
	mov	bx, ds:[SC_status.SBS_blockHandle]
	call	MemFree
	jmp	short done

SoundLibDriverFreeDAC	endp

DACCode		ends

FMCode		segment	resource

;-----------------------------------------------------------------------------
;
;		STREAM FM SOUND ROUTINES
;
;-----------------------------------------------------------------------------

	;
	;  An streamed FM sound operates slightly different from
	;	a simple sound.

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverAllocStreamFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a stream to play FM sounds

CALLED BY:	Strategy Routine
PASS:		ax	-> SoundStreamType
		bx	-> starting priority
		cx	-> # of voices
		dx	-> starting tempo

RETURN:		carry clear
		bx	<- handle for sound
		ax destroyed

			- or -
		carry set
		ax	<- SOUND_ERROR reason for failure
		bx destroyed

DESTROYED:	ax

SIDE EFFECTS:	
		allocates a block on the global heap
		allocates a bunch of handles

PSEUDO CODE/STRATEGY:
		allocate sound structure
		allocate a stream for the sound
		initialize the stream
		initialize the semaphores		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert	size SoundVoiceStatus eq 8
SoundLibDriverAllocStreamFM	proc	far
	uses	cx, ds, di
	.enter

	tst	cx
EC<	ERROR_Z	SOUND_ERROR_CAN_NOT_ALLOCATE_CONTROL_WITH_NO_VOICES	>
NEC<	jz	noVoices						>
NEC<afterCheck:								>

	push	ax					; save stream size
	push	cx					; save voice #

	mov	di, bx					; di <- starting prio.

	;
	;  Allocate a block to hold the basic sound structure and
	;	the voice status'
	mov_tr	ax, cx					; ax <- # of voices
	shl	ax, 1					; ax <- ax * 2
	shl	ax, 1					; ax <- ax * 4
	shl	ax, 1					; ax <- ax * size SVS

	add	ax, size SoundControl

	mov	cx, mask HF_SWAPABLE or mask HF_SHARABLE or \
			((mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8)
	call	MemAlloc
	jc	memoryFull

	mov	ds, ax					; es <- sound segment

	pop	cx					; restore voice #

	;
	;  Initialize the sound structure
	;
	call	SoundLibDriverInitStreamFM	; trashes ax

	;
	;  Allocate a stream
	;
	pop	ax					; restore stream size

	mov	bx, handle 0				; bx <- owner
	mov	cx, mask HF_FIXED
	mov	di, DR_STREAM_CREATE
	call	StreamStrategy
	jc	noStream

	mov	ds:[SC_position.SSS_stream].SSS_streamSegment, bx
	mov	ds:[SC_position.SSS_stream].SSS_streamToken, bx

	mov	bx, ds:[SC_status.SBS_blockHandle]
	call	MemUnlock
done:
	.leave
	ret

NEC<noVoices:								>
NEC<	;								>
NEC<	;  They want us to allocate a sound with no voices...		>
NEC<	;  Why?								>
NEC<	mov	cx, 1							>
NEC<	jmp	afterCheck						>


memoryFull:
	pop	cx					; clean up stack
	pop	ax

	mov	ax, SOUND_ERROR_OUT_OF_MEMORY
EC<	mov	bx, SOUND_ID						>
	stc
	jmp	short done

noStream:
	;
	;  Well, we need to free up what we just created.
	;  Since we don't have a stream yet, we don't call
	;	SoundLibDriverFreeStream.
	mov	bx, ds:[SC_status.SBS_blockHandle]
	call	SoundLibDriverFreeSimple

	mov	ax, SOUND_ERROR_UNABLE_TO_ALLOCATE_STREAM
EC<	mov	bx, SOUND_ID						>
	stc
	jmp	short done

SoundLibDriverAllocStreamFM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverInitStreamFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up semaphore and values for an FM stream

CALLED BY:	SoundLibDriverAllocStreamFM
PASS:		es	-> segment of block
		bx	-> block handle
		cx	-> # of voices
		dx	-> starting tempo
		di	-> starting priority

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		uses handles for semaphores

PSEUDO CODE/STRATEGY:
		set up starting values
		allocate semaphores

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverInitStreamFM	proc	far
	uses	bx, cx, si
	.enter

	mov	ds:[SC_status.SBS_blockHandle], bx	; store handle
	mov	ds:[SC_status.SBS_type], ST_STREAM_FM	; store type
	mov	ds:[SC_status.SBS_ID], SOUND_ID		; store ID
	mov	ds:[SC_status.SBS_priority], di		; store prioriy
	mov	ds:[SC_format.SFS_fm].SFMS_tempo, dx	; store tempo

	clr	ax

	czr	al, ds:[SC_status.SBS_EOS]

	czr	ax, ds:[SC_format.SFS_fm].SFMS_timerHandle
	czr	ax, ds:[SC_format.SFS_fm].SFMS_timerID
	czr	ax, ds:[SC_format.SFS_fm].SFMS_timeRemaining

	mov	ds:[SC_format.SFS_fm].SFMS_voicesUsed, cx; set # of voices

	czr	ax, ds:[SC_position.SSS_stream].SSS_dataRemaining
	czr	ax, ds:[SC_position.SSS_stream].SSS_dataOnStream
	czr	ax, ds:[SC_position.SSS_stream].SSS_streamSegment
	czr	ax, ds:[SC_position.SSS_stream].SSS_streamToken

	clrdw	ds:[SC_position.SSS_stream].SSS_buffer

	czr	al, ds:[SC_position.SSS_stream].SSS_streamState

	mov	si, offset SC_voice

	jcxz	allocSems
topOfLoop:
	mov	ds:[si].SVS_physicalVoice, NO_VOICE
	CheckHack 	<DEFAULT_INSTRUMENT lt 65536>	; assume instrument
							; fits in a word
	mov	ds:[si].SVS_instrument.low, DEFAULT_INSTRUMENT
	clr	ds:[si].SVS_instrument.high 		; instru<-
							; DEFAULT_INSTRUMENT 
	add	si, size SoundVoiceStatus		; set voice inactive
	loop	topOfLoop

allocSems:
	;
	;  Allocate all the semaphores we need to
	;	do the various things we do.
	mov	bx, 1
	call	ThreadAllocSem
	mov	ds:[SC_status.SBS_mutExSem], bx

	mov	ds:[SC_position.SSS_stream].SSS_writerSem.Sem_value, 1
	czr	ax, ds:[SC_position.SSS_stream].SSS_writerSem.Sem_queue
	czr	ax, ds:[SC_position.SSS_stream].SSS_dataSem.Sem_value
	czr	ax, ds:[SC_position.SSS_stream].SSS_dataSem.Sem_queue
	mov	ds:[SC_position.SSS_stream].SSS_activeReaderSem.Sem_value, 1
	czr	ax, ds:[SC_position.SSS_stream].SSS_activeReaderSem.Sem_queue

done::
	.leave
	ret
SoundLibDriverInitStreamFM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverPlayToStreamFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play an FM sound on the given stream

CALLED BY:	StrategyRoutine
PASS:		bx	-> token for Sound
		dx:si	-> buffer of sound events
		cx	-> bytes in buffer

RETURN:		carry clear
		ax destroyed

			- or -

		carry set
		ax	<- SOUND_ERROR failure reason

DESTROYED:	ax

SIDE EFFECTS:
		stuffs stream events onto stream

PSEUDO CODE/STRATEGY:
		stuff one event at a time on the stream
		increment the event counter after adding
			stuff to the stream.
		repeat

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverPlayToStreamFM	proc	far
	uses	bx, si, ds
	.enter
EC <	Assert_fptr	dxsi						>
	;
	; Grab stream semaphore and set up initial values
	;
	call	SoundStartPlayToStreamFM		; ds<-fptr to
							;   SoundControl block 
							; ax<-thread priority
							; bx<-stream segment
	push	ax					; save priority

topOfLoop:
	call	SoundLibDriverWriteEvent

	pushf
	push	cx					; save count

	inc	ds:[SC_position.SSS_stream].SSS_dataOnStream

	test 	ds:[SC_position.SSS_stream].SSS_streamState, mask SSS_active
	jz	activateReader

continueLoop:
	pop	cx					; restore count
	popf
	jnc	topOfLoop	; 'inc' does NOT affect carry!

	pop	ax					; al <- orig. priority

	call	SoundEndPlayToStreamFM			; ax, bx destroyed
	clc
done::
	.leave
	ret

activateReader:
	call	SoundActivateStreamReader		; nothing destroyed
	jmp	short continueLoop

SoundLibDriverPlayToStreamFM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverPlayToStreamFMNB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play an FM sound on the given stream

CALLED BY:	StrategyRoutine
PASS:		bx	-> token for Sound
		dx:si	-> buffer of sound events
		cx	-> bytes in buffer (0 if unknown)

RETURN:		cx	-> bytes written to stream
	
		carry clear
		ax destroyed

			- or -

		carry set
		ax	<- SoundWriteStreamStatus

DESTROYED:	ax

SIDE EFFECTS:
		stuffs stream events onto stream

PSEUDO CODE/STRATEGY:
		stuff one event at a time on the stream
		increment the event counter after adding
			stuff to the stream.
		repeat

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverPlayToStreamFMNB	proc	far
		soundDataLeftToWrite	local	word	push	cx
		bytesWritten		local	word
	uses	bx, si, ds
	.enter
EC <	Assert_fptr	dxsi						>
	;
	; Grab stream semaphore and set up initial values
	;
	call	SoundStartPlayToStreamFM	; ds<-fptr to
						;   SoundControl block 
						; ax<-thread priority
						; bx<-stream segment

	push	ax				; save priority
	
	;
	; Init sound data counter
	;
	clr	ss:[bytesWritten]		; no bytes written
	
topOfLoop:
	call	SoundCanWriteEventToStream	; cx <- # bytes can be written
						; carry set if not enough
						;   room in stream to write
						;   the next event 
	jnc	canWriteEvent
	mov	ax, SWSS_NOT_ENOUGH_SPACE_IN_STREAM_TO_WRITE
	jmp	doneWritingEvent

canWriteEvent:
	add	ss:[bytesWritten], cx
	mov	cx, ss:[soundDataLeftToWrite]
	;
	; The code that retrieves the size of next event has been duplicated
	; in SoundCanWriteEventToStream and SoundLibDriverWriteEvent.
	; However, if they are combined, many conditionals must be added
	; which would make the codes more complicated...
	;
	call	SoundLibDriverWriteEvent	; cx<-#bytes remaining in
						;   buffer, if buf size known
	pushf
	tst	ss:[soundDataLeftToWrite]
	jz	doNotUpdateCounter
	mov	ss:[soundDataLeftToWrite], cx
	
doNotUpdateCounter:
	push	cx				; save count

	inc	ds:[SC_position.SSS_stream].SSS_dataOnStream

	test 	ds:[SC_position.SSS_stream].SSS_streamState, mask SSS_active
	jz	activateReader

continueLoop:
	pop	cx				; restore count
	popf
	jnc	topOfLoop			; 'inc' does NOT affect carry!
	mov	ax, SWSS_SUCCESSFUL_WRITE

doneWritingEvent:
	;
	; We save off ax <- SoundWriteStreamStatus. Then we release thread
	; and recheck the status so that we can set up the return values
	; accordingly 
	;
	mov	bx, ax				; bx <- SoundWriteStreamStatus
	pop	ax				; al <- orig. priority
	push	bx				; save SoundWriteStreamSTatus
	
	call	SoundEndPlayToStreamFM		; ax, bx destroyed
	
	pop	ax				; ax <- SoundWriteStreamStatus

	;
	; Check the write status and set the return values
	;
	cmp	ax, SWSS_NOT_ENOUGH_SPACE_IN_STREAM_TO_WRITE
	jne	succeed				; jmp if succeed
	stc
	jmp	done
	
succeed:
	clc
done::
	mov	cx, ss:[bytesWritten]
	.leave
	ret

activateReader:
	call	SoundActivateStreamReader	; nothing destroyed
	jmp	continueLoop
	
SoundLibDriverPlayToStreamFMNB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverWriteEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the next set of FM events to the stream

CALLED BY:	SoundLibDriverPlayToStreamFM

PASS:		bx	-> stream token
		cx	-> # of bytes in buffer (zero if unknown)
		dx:si	-> buffer to write from

RETURN:		dx:si	<- beginning of unsent portion
		carry set if no more events to write

		if # of bytes known in buffer,
		cx	<- # of bytes remaining in buffer
		
DESTROYED:	nothing

SIDE EFFECTS:
		adds data to the stream
		can block

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/23/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverWriteEvent	proc	far
	uses	ax, bx, di, ds
startingSize	local	word	push	cx
endingSize	local	word	push	cx
endOfSongFlag	local	word
	.enter
	push	bx
	clr	endOfSongFlag

	mov	ds, dx

	;
	;  Read the stream event and determine how much to write
	;	to the stream
	mov	bx, ds:[si]

EC<	test	bx,1							>
EC<	ERROR_NZ SOUND_BAD_EVENT_COMMAND				>

	mov	cx, cs:eventBufferSize[bx]	; cx <- # of bytes in event
	jcxz	transferGeneralEvent

writeToStream:
	;
	;  We know how much we are supposed to transfer, so do so.
	sub	endingSize, cx			; remove size of event
	mov	ax, STREAM_BLOCK
	pop	bx
	mov	di, DR_STREAM_WRITE
	call	StreamStrategy

	add	si, cx				; point to next event

	;
	;  See if we knew how much we had when we
	;	came in here
	tst	startingSize			; zero starting size means
	jz	lookForEOS			;	unknown length

	mov	cx, endingSize			; cx <- # of bytes remaining
	tst_clc	cx
	jnz	done

setCarry:
	stc					; mark as no more to write

done:
	.leave
	ret

lookForEOS:
	;
	;  We don't know how big the buffer is that we
	;	are writing to the stream, so we just look
	;	for the first EOS
	clr	cx				; we don't know how much left
	tst_clc	endOfSongFlag			; see if we wrote an EOS
	jz	done
	jmp	short setCarry

transferGeneralEvent:
	;
	;  We will be transfering a general event.  Look
	;	for writing an EOS.  Set a flag if that
	;	is the case.
	;  Remember, we need to look one word past the
	;	start of the "General Event" to determine
	;	which event we are writing...
	mov	bx, ds:[si]+2			; bx <- general event #

	;
	;  Assume we will write an EOS
	dec	endOfSongFlag			; mark as EOS
	cmp	bx, GE_END_OF_SONG
	je	getEventSize

	;
	;  Well, we didn't write an EOS.  Clear the flag
	clr	endOfSongFlag			; mark as not EOS

getEventSize:
	mov	cx, cs:generalEventBufferSize[bx]
	jmp	short writeToStream

eventBufferSize		word	8,		; voiceOnEvent
				4,		; voiceOffEvent
				8,		; changeEvent
				0,		; GENERAL_EVENT, handle special
				4, 		; delta
				4,		; delta
				4 		; delta

generalEventBufferSize	word	4,		; No Event
				4,		; End Of Song
				6,		; Set Priority
				6,		; Set Tempo
				10, 		; Send Notification
				6		; V Semaphore
SoundLibDriverWriteEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverStopStreamFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the current FM sound stream

CALLED BY:	Strategy Routine
PASS:		bx	-> token for Sound

RETURN:		carry clear
		ax destroyed

			- or -
		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	ax

SIDE EFFECTS:	
		stop timer and flush stream

PSEUDO CODE/STRATEGY:
		stop timer
		flush stream
		turn off voices

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverStopStreamFM	proc	far
	uses	ax, bx, di, ds
	.enter
	;
	;  Lock down sound so we can use it
	;
	call	MemLock
EC<	ERROR_C	SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>
	mov	ds, ax

	;
	;  Get Sound's semaphore
	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadPSem

	;
	;  Turn off all the voices and stop the timer
	call	SoundLibDriverSilenceVoices
	jc	errorSilencing

	;
	;  Flush the stream.
	mov	bx, ds:[SC_position.SSS_stream].SSS_streamSegment
	mov	di, DR_STREAM_FLUSH
	call	StreamStrategy

	clr	ds:[SC_position.SSS_stream].SSS_dataOnStream
	clr	ds:[SC_position.SSS_stream].SSS_dataRemaining

	;
	;  Mark reader as inactive
	clr	ds:[SC_position.SSS_stream].SSS_activeReaderSem.Sem_value
	and	ds:[SC_position.SSS_stream].SSS_streamState,not mask SSS_active

	;
	;  Release mutEx semaphore
	;
	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadVSem
done:
	;
	; Unlock the SoundControl/Token for sound
	;
	mov	bx, ds:[SC_status].SBS_blockHandle
	call	MemUnlock				; flags preserved
	
	.leave
	ret

errorSilencing:
	push	ax					; save error

	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadVSem

	pop	ax					; restore error
	stc
	jmp	short done

SoundLibDriverStopStreamFM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverPlayLMemSimpleFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take an LMem chunk, lock it, and play the sound.

CALLED BY:	GLOBAL

PASS:		ax	-> SoundPriority for buffer
		bx	-> handle of SoundControl block
		cx	-> tempo of song (only used if DeltaTempo in song)
		dl	-> EOSFlag for sound

RETURN:		carry clear on ok
		ax destroyed

		carry set on error
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	ax

SIDE EFFECTS:	locks LMem block and plays piece

PSEUDO CODE/STRATEGY:
		initialize SoundControl (lock down block, deref handle)
		play sound
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JV	3/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverPlayLMemSimpleFM	proc	far
	uses	bx,cx,si,bp,ds
	.enter

EC<	Assert	handle bx					>
EC<	Assert	record dl EndOfSongFlags			>

	;
	;  First, we need to check to see if this SoundStatus is already being
	;  played, and if so, turn it off.
						; bx = SoundControl
	call	SoundCheckExclusiveSimpleFM  ; ds <- SoundControl segment
					     ; carry set on error
	jc	done				; something went wrong, bail.

EC<	call	SoundLibDriverVerifySoundBlockDS		>

	;
	;  change the necessary parameters.
	mov	ds:[SC_status.SBS_priority], ax		; set new priority
	mov	ds:[SC_format.SFS_fm.SFMS_tempo], cx	; set new tempo
	BitSet	dl, EOSF_LMEM_UNLOCK			; mark the sound as
							;   locked by the lib

	mov	ds:[SC_status.SBS_EOS], dl			; save flags

	;
	;  Dereference the handle to the sound buffer that has been passed
	;  to us in the SoundControl block.
	;
	mov	bx, ds:[SC_position.SSS_simple.SSS_songHandle].handle
						; bx <- handle of LMem block
EC<	Assert	lmem bx						>
	call	MemLock			; ax <- segment address
					; carry set on error
EC<	ERROR_C SOUND_BUFFER_IN_DISCARDED_RESOURCE		>

	;
	;  And now we need to get to the chunk itself.
	;
	mov	bx, ds:[SC_position.SSS_simple.SSS_songHandle].chunk
						; bx <- chunk handle of buffer
	mov	cx, ds				; store SoundControl seg.
	mov	ds, ax				; ds <- segment of sound buffer
	mov	bx, ds:[bx]			; ds:bx <- sound buffer ptr
	mov	ds, cx				; restore SoundControl

	;
	;  Store the pointers.  Start the songPointer at the beginning
	;  of the buffer.
	;
	movdw	ds:[SC_position.SSS_simple.SSS_songBuffer], axbx
	mov	ds:[SC_position.SSS_simple.SSS_songPointer], bx

	mov_tr	ax, bx					; ax <- start of song
	mov	bx, ds:[SC_status.SBS_mutExSem]		; bx <- mutEx sem
							; ds = SoundControl seg
	call	SoundStartSimpleFM	; ax destroyed
	clc
done:
	.leave
	ret
SoundLibDriverPlayLMemSimpleFM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundCanWriteEventToStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if stream has enough room to write the next
		event from buffer 

CALLED BY:	INTERNAL

PASS:		ds 	-> segment of SoundControl block
		bx	-> stream token
		dx:si	-> buffer to write from

RETURN:		carry clear on ok
		cx 	<- # bytes can be written

		carry set if not enough room to write event to stream
		cx destroyed
	
DESTROYED:	cx 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundCanWriteEventToStream	proc	near
		streamToken	local	word	push	bx
	uses	es, ax, bx, di
	.enter
	;
	; This routine is extracted from SoundLibDriverWriteEvent. Only the
	; codes that calculates the size of next event are here.
	;
EC <	Assert_fptr	dxsi						>
	mov	es, dx
	mov	bx, es:[si]			; bx <- event

EC<	test	bx,1							>
EC<	ERROR_NZ SOUND_BAD_EVENT_COMMAND				>

	mov	cx, cs:eventBufferSize[bx]	; cx <- # of bytes in event
	jcxz	transferGeneralEvent

checkStream:
	; CURRENT REGISTERS: cx <- # bytes of event to write
	
	;
	; Get the number of bytes in stream available to write
	;
	mov	di, DR_STREAM_QUERY
	mov	bx, ss:[streamToken]
	mov	ax, STREAM_WRITE
	call	StreamStrategy			; ax <- # bytes avail to write

	cmp	ax, cx				; bytes avail >= event size 
						; carry clear if yes,
						; carry set if no
	.leave
	ret
	
transferGeneralEvent:
	;
	;  Remember, we need to look one word past the
	;	start of the "General Event" to determine
	;	which event we are writing...
	mov	bx, es:[si]+(size GeneralEvent)	; bx <- general event #
	mov	cx, cs:generalEventBufferSize[bx]
	jmp	checkStream			; done getting size
SoundCanWriteEventToStream		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundCheckExclusiveSimpleFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do common exclusive check for PlaySimpleFM and PlayLMemSimpleFM

CALLED BY:	SoundLibDriverPlaySimpleFM, SoundLibDriverPlayLMemSimpleFM

PASS:		bx	-> handle of SoundStreamStatus block

RETURN:		ds	<- segment of locked SoundStreamStatus block
	
		carry clear
		ax destroyed

			- or -
		carry set
		ax	<- SOUND_ERROR reason for failure

DESTROYED:	ax

SIDE EFFECTS:	gets sound exclusive for the stream

PSEUDO CODE/STRATEGY:
		turn off any timer chain currently active.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JV	4/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundCheckExclusiveSimpleFM	proc	near
	uses	ax,bx
	.enter

	;
	;  lock down the SoundStream so we can work on it
	call	MemLock
EC<	ERROR_C	SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	mov	ds, ax					; ds <- segment of SSS
EC<	call	SoundLibDriverVerifySoundBlockDS			>
	;
	;  As we are going to be altering the settings and voices,
	;  we need exclusive access to the stream
	mov	bx, ds:[SC_status.SBS_mutExSem]		; bx <- mutEx sem
	call	ThreadPSem				; get exclusive lock

	;
	;  Check to see if the block is already playing.  If
	;  so stop the timer, and turn off all the voices.
	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT		; ax <- info to get
	mov	bx, ds:[SC_status.SBS_blockHandle]	; bx <- info to get
	call	MemGetInfo			; ax <- info value

	cmp	ah, 1					; only locked by us?
	je	done				; if so, exit w/carry clear

	;
	;  It is busy playing from a previous PlaySimpleFM.
	;  We must turn off the voices and stop the
	;  timer.
	call	SoundLibDriverSilenceVoices	; carry set on error
						; -- our return value
done:
	.leave
	ret
SoundCheckExclusiveSimpleFM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundStartSimpleFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do common music startup for PlaySimpleFM and PlayLMemSimpleFM

CALLED BY:	SoundLibDriverPlaySimpleFM and SoundLibDriverPlayLMemSimpleFM

PASS:		ax	<- offset into sound buffer
		bx	<- mutEx sem
		ds	<- segment of locked SoundControl block

RETURN:		nothing

DESTROYED:	ax,bx,si,ds

SIDE EFFECTS:	releases exclusive
		actuivates sound stream

PSEUDO CODE/STRATEGY:
		release exclusive
		activate stream

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JV	4/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundStartSimpleFM	proc	near
	.enter


	INT_OFF

	;
	;  We are done now with fiddling with the stream.
	;  release the mutEx lock and start up the timer
	call	ThreadVSem				; release exclusive

	mov	ax, ds					; ax <- sound handle

	;
	;  SoundHandleTimerEvent can destroy ax,bx,si,ds
	call	SoundHandleTimerEvent			; activate stream

	INT_ON

	.leave
	ret
SoundStartSimpleFM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundStartPlayToStreamFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up initial values and grab stream semaphore before
		playing FM music to stream

CALLED BY:	
PASS:		bx	-> token for Sound

RETURN:		ds 	-> fptr to SoundControl block
		ax 	-> thread priority
		bx	-> Stream segment
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SA	6/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundStartPlayToStreamFM	proc	near
	uses	cx
	.enter
	;
	;  Lock down the block so we can torture... 
	;  err, I mean, so we can "play" with it.
	call	MemLock
EC<	ERROR_C	SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	;
	;  Get mutually exclusive access to it.
	mov	ds, ax				; ds <- sound segment
	mov	bx, ds:[SC_status.SBS_mutExSem]	; bx <- mutExSem
	call	ThreadPSem

	;
	;  Before we write to the stream, we need to
	;	get the write semaphore we know we
	;	aren't tromping on other people toes.
	PSem	ds, SC_position.SSS_stream.SSS_writerSem, TRASH_AX_BX

	;
	;  OK.  Here comes the guts of the writing process.
	;	What we do is stuff data on the stream
	;	and then increase the event count.
	clr	bx				; look at current one
	mov	ax, TGIT_PRIORITY_AND_USAGE
	call	ThreadGetInfo			; ax <- thread priority
	mov	cx, ax				; cx <- thread priority

	;
	; Change the priority of thread
	;
	mov	al, PRIORITY_HIGH		; very important
	mov	ah, mask TMF_BASE_PRIO
	call	ThreadModify			; ax destroyed

	mov	ax, cx				; ax <- thread priority
	mov	bx, ds:[SC_position.SSS_stream].SSS_streamSegment
	
	.leave
	ret
SoundStartPlayToStreamFM		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundEndPlayToStreamFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release thread, semaphores and any locked blocks during
		playing music to sound stream

CALLED BY:	
PASS:		al	->	priority
		ds	->	segment of SoundControl block
RETURN:		nothing
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SA	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundEndPlayToStreamFM	proc	near
	.enter
EC <	Assert_segment	ds						>
	clr	bx					; current thread
	mov	ah, mask TMF_BASE_PRIO

	call	ThreadModify

	;
	;  We are finished writing things so we can release the
	;	writer semaphore
	VSem	ds, SC_position.SSS_stream.SSS_writerSem, TRASH_BX

	;
	;  We are also finished playing with our stream,
	;	so we release the mutEx
	mov	bx, ds:[SC_status.SBS_mutExSem]
	call	ThreadVSem

	mov	bx, ds:[SC_status.SBS_blockHandle]
	call	MemUnlock
	
	.leave
	ret
SoundEndPlayToStreamFM		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundActivateStreamReader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Activate the reader for sound stream

CALLED BY:	
PASS:		ds	-> 	segment of SoundControl block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SA	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundActivateStreamReader	proc	near
	uses	ax, bx, ds, si
	.enter
	;
	;  The reader has fallen asleap since we last left him.
	;  We must re-activate him.
	;
	;  First, we must make sure the block remains locked for
	;	the duration of the sound.
	;  This lock will be balances by an unlock when the stream
	;	becomes inactive.
	mov	bx, ds:[SC_status.SBS_blockHandle]

	test	ds:[SC_position.SSS_stream].SSS_streamState, mask SSS_locked
	jnz	locked

	call	MemLock
EC<	ERROR_C	SOUND_CONTROL_BLOCK_IN_DISCARDED_RESOURCE		>

	ornf	ds:[SC_position.SSS_stream].SSS_streamState, mask SSS_locked

locked:


	INT_OFF
	or	ds:[SC_position.SSS_stream].SSS_streamState, mask SSS_active
	mov	ax, ds			; ax <- stream to act on

	call	SoundHandleTimerEvent	; can trash ax, bx, ds, si
	INT_ON

	.leave
	ret
SoundActivateStreamReader		endp

FMCode	ends

if ERROR_CHECK

ResidentCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverVerifySoundBlockES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the block at segment ES is a sound segment

CALLED BY:	INTERNAL
PASS:		es	-> segment to check
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Fatal Errors if not the case

PSEUDO CODE/STRATEGY:
		mov segment in DS and call SLDVSBDS.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	2/23/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverVerifySoundBlockES	proc	far
	uses	ds
	.enter
	segmov	ds, es
	call	SoundLibDriverVerifySoundBlockDS
	.leave
	ret
SoundLibDriverVerifySoundBlockES	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundLibDriverVerifysoundBlockDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify block at segment ds is a sound block

CALLED BY:	INTERNAL
PASS:		ds	-> segment to check
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Fatal errors if not the case

PSEUDO CODE/STRATEGY:
		Check ID

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	2/23/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundLibDriverVerifySoundBlockDS	proc	far
	uses	ax, bx
	.enter
	;
	;  First see if we have the correct ID
	cmp	ds:[SC_status.SBS_ID], SOUND_ID
	ERROR_NE SOUND_CORRUPT_SOUND_BLOCK
	.leave
	ret
SoundLibDriverVerifySoundBlockDS	endp

ResidentCode		ends

endif
