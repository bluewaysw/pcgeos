COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS Sound System
MODULE:		Sound Library
FILE:		nsoundResident.asm

AUTHOR:		Todd Stumpf, Aug 20, 1992

ROUTINES:
	Name			Description
	----			-----------
INTERN	SoundHandleTimerEvent	Routine that is called by the timer
INTERN	SoundResetTimer		Set up appropriate timer for next event
INTERN	SoundVoiceOn		Handle a voice-on Event
INTERN	SoundVoiceOff		Handle a voice-off Event
INTERN	SoundChange		Handle a Change-Envelope Event
INTERN	SoundGeneral		Handle a General stream event
INTERN	SoundReadNextWord	Get the next word of data from strea/memory

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/20/92		Initial revision
	TS	12/28/92	Changed to read from stream or memory

DESCRIPTION:
	This contains all the code that remains in the fixed block of
	the library.  Code in this segment is probably here because
	at some point it is or could be called by an interupt routine
	or msec timer.

	$Id: soundResident.asm,v 1.1 97/04/07 10:46:29 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundHandleTimerEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with the expiration of a timer by doing the next event

CALLED BY:	Timer Routine

PASS:		ax	-> SoundStream to act upon
RETURN:		nothing
DESTROYED:	ax,bx,si,ds (allowed) (flags saved)
SIDE EFFECTS:	
		probably sets up another timer.
		probably does something with the sound driver.

PSEUDO CODE/STRATEGY:
		read in next event and act upon it.
		If not an end-of-song event, determine delta time
		to next event and go for it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.ioenable
	.assert	ST_SIMPLE_FM 	eq 	0	; for fast check of
	.assert ST_STREAM_FM	eq	2	; # of events
SoundHandleTimerEvent	proc	far
	uses	cx
	.enter
	pushf				; save interrupts state

if PZ_PCGEOS
	;
	; if someone has exclusive access, forget it
	;
	; (this fixes some EMS conflicts with the FEP TSR)
	;
	push	ax
	mov	ax, segment dgroup
	mov	ds, ax
	tst	ds:[exclusiveAccess]
	pop	ax
;EC <	WARNING_NZ	SOUND_DELAYED_BY_EXCLUSIVE_ACCESS		>
	jnz	done
endif

	mov	ds, ax			; ds <- segment of stream
	mov	si, offset SC_voice	; si <- offset to driver info
	;
	;  Test for a long tempo delta time
	tst	ds:[SC_format.SFS_fm].SFMS_timeRemaining
	jnz	dealWithLongTimer

	;
	;  Turn interrupts off.  They must be off for the remainder
	;  of the routine.  To make sure we return interrupts in the
	;  propper format (on if possible, but not for msec) we have
	;  previously pushed the flags onto the stack.  At the end
	;  of the routine we will pop the flags, restoring them
	;  to the correct state.
	INT_OFF

doNextEvent:
	;
	;  Determine if we are reading from a stream,
	;	and if so, if there is anything left to
	;	read
	tst	ds:[SBS_type]		; stream are non-zero
	jz	readEvent

	tst	ds:[SC_position.SSS_stream].SSS_dataOnStream
	LONG jz	readFromEmptyStream

	dec	ds:[SC_position.SSS_stream].SSS_dataOnStream

readEvent:
	;
	;  Read in next event and act upon it.

	call	SoundReadNextWord	; ax <- next word (nothing destroyed)

	mov_tr	bx, ax				; bx <- event #

EC<	test	bx, 1				; can't be odd		    >
EC<	ERROR_NZ SOUND_BAD_EVENT_COMMAND				    >
EC<	cmp	bx, 12				; can't go off end of table >
EC<	ERROR_A SOUND_BAD_EVENT_COMMAND					    >

	call	cs:eventJumpTable[bx]	; carry set if EOS, bx <- zero if EOS

	jnc	doNextEvent

	tst	bx				; was last event and EOS?
	jnz	possibleEOS

done:
	call	SafePopf			; restore interrupt state
	.leave
	ret

dealWithLongTimer:
	;
	;  We have such a slow tempo, or such a long rest that it
	;  exceeded 65535 msec.  We rested the fraction first, so
	;  now we just rest lumps of 65535
	push	dx, bp				; uses dx, bp

	mov	bx, ds:[SBS_blockHandle]	; bx <- handle of stream
	call	MemOwner			; bx <- owner of handle

	mov	bp, bx				; bp <- owner for timer
	mov	al, TIMER_MS_ROUTINE_ONE_SHOT
	mov	bx, segment SoundHandleTimerEvent
	mov	si, offset SoundHandleTimerEvent
	mov	cx, 65535			; rest for maximum time
	mov	dx, ds				; pass along this stream
	call	TimerStartSetOwner

	pop	dx, bp				; restore dx
	dec	ds:[SC_format.SFS_fm].SFMS_timeRemaining; dec # of rests

						; save timer ID
	mov	ds:[SC_format.SFS_fm.SFMS_timerID], ax
						; save timer handle
	mov	ds:[SC_format.SFS_fm.SFMS_timerHandle], bx


	jmp	short done

possibleEOS:
	;
	;  We have reached an end of song marker.
	;  If we are a simple FM sound, we need to set the timerID
	;  and handle to the default values and V the semaphore.
	;  If we are a stream, however, we can just ignore
	;  this occurance.
	tst	ds:[SBS_type]
	LONG jnz	doNextEvent

	;
	;  Well, we are a simple sound.  Clean up after
	;	ourselves and end.
	clr	bx
	mov	ds:[SC_format.SFS_fm.SFMS_timerID], bx
	mov	ds:[SC_format.SFS_fm.SFMS_timerHandle], bx

;	;  I don't see the point to this, do you?  -- todd
;
;	mov	bx, ds:[SBS_mutExSem]		; bx <- handle of sem
;	call	ThreadVSem			; free up semaphore

	;
	;  If this sound buffer was an LMem chunk that we locked down, we
	;  need to unlock it when we complete.  Jason 3/31/94
	;
	mov	al, ds:[SBS_EOS]		; al <- EOS Flags
	test	al, mask EOSF_LMEM_UNLOCK	; was this an LMem chunk?
	jz	testUnlock

	mov	bx, ds:[SC_position.SSS_simple.SSS_songHandle].handle
						; bx <- LMem block handle
EC<	Assert	lmem bx							>
EC<	call	MemUnlockNoSegmentChecking				>
NEC<	call	MemUnlock						>
		
testUnlock:
	mov	bx, ds:[SBS_blockHandle]	; bx <- sound handle
	test	al, mask EOSF_UNLOCK 		; do we unlock it on EOS?
	jz	testDestroy

EC<	call	MemUnlockNoSegmentChecking				>
NEC<	call	MemUnlock						>

testDestroy:
	test	al, mask EOSF_DESTROY		; do we free it on EOS?
	LONG jz	done

	push	dx, bp				; save trashed registers

	mov_tr	dx, bx				; dx <- handle to block

	mov	al, TIMER_ROUTINE_ONE_SHOT		; one shot timer
	mov	bx, segment SoundFreeBlockRoutine	; calls this routine
	mov	si, offset SoundFreeBlockRoutine
	mov	cx, 1					; in one tick
	mov	bp, handle 0				; owned by library
	call	TimerStartSetOwner

	pop	dx, bp				; restore trashed registers

	jmp	done

readFromEmptyStream:
	;
	;  We tried to read from an empty stream.
	;  This is expected.  Unwelcome, but expected.
	;  We mark ourselves as inactive and wait for someone
	;  to wake us up.
	andnf	ds:[SC_position.SSS_stream].SSS_streamState,not mask SSS_active

	;
	;  GACK!  There is a problem here.  If we don't free up our
	;  voices when we unlock our block, they will still have
	;  references to our previous segment location, and if
	;  someone steals them, it will dork memory...
	;  Believe me, this is not an easy bug to find...
	;
	;  What we need to do is only unlock the block if there
	;  are no voices playing, and if there are voices playing,
	;  we just leave the block locked.
	;			-- todd  07/28/93

	mov	cx, ds:[SC_format.SFS_fm].SFMS_voicesUsed
	mov	si, offset SC_voice

scanVoices:
	cmp	ds:[si].SVS_physicalVoice, NO_VOICE
	jne	done

	add	si, size SoundVoiceStatus
	loop	scanVoices

	;
	;  Unlock ourselves, to balance the lock we did when
	;  someone first wrote to the stream.
	andnf	ds:[SC_position.SSS_stream].SSS_streamState,not mask SSS_locked

	mov	bx, ds:[SBS_blockHandle]

EC<	call	MemUnlockNoSegmentChecking				>
NEC<	call	MemUnlock						>
	jmp	done

SoundHandleTimerEvent	endp

	;
	;  The kernel doesn't export SafePopf, but I need it,
	;  so I just duplicate it here.
SafePopf	label	far
	iret

	;
	;  Jump table for routines to handle stream events
eventJumpTable	nptr	SoundVoiceOn,		; SSE_VOICE_ON
			SoundVoiceOff,		; SSE_VOICE_OFF
			SoundChange,		; SSE_CHANGE
			SoundGeneral,		; SSE_GENERAL
			SoundResetTimer,	; SSDTT_MSEC
			SoundResetTimer,	; SSDTT_TICKS
			SoundResetTimer		; SSDTT_TEMPO


if	ERROR_CHECK
	;
	; EC +segment wreaks havoc when messing with the heap at interrupt
	; time.  This might be technically legal, but EC deaths occur every so
	; often anyway.
	;						jdashe	6/20/95
MemUnlockNoSegmentChecking	proc	near
	ecLev	local	word

	uses	cx, dx
	.enter

	movdw	cxdx, axbx			; save original values	
	call	SysGetECLevel			; ax <- sysECLevel	
	mov	ss:[ecLev], ax			; save original EC	

	BitClr	ax, ECF_SEGMENT			; no segment checking, please
	call	SysSetECLevel						
	movdw	axbx, cxdx			; recover originals	

	call	MemUnlock			; no return value

	call	SysGetECLevel			; reset ec.. bx might've changed
	mov	ax, ss:[ecLev]			; recover old EC flags	
	call	SysSetECLevel						

	movdw	axbx, cxdx						
	.leave
	ret

MemUnlockNoSegmentChecking	endp
endif 	; ERROR_CHECK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundFreeBlockRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the sound handle block specified

CALLED BY:	Timer
PASS:		ax	-> handle of block to free
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		sends a message

PSEUDO CODE/STRATEGY:
		Use ObjMessage MF_FORCE_QUEUE to send a
		message to the UI that will cause this block to
		be freed.

		We have to use this routine because we can't send
		data to the UI if we use a TIMER_EVENT...., 
		and we can't do it in the HandleTimerEvenRoutine
		because we might have reached there through a msec
		routine, and ObjMessage enables interrupts.

		Believe me, its messy, but it works.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	2/ 4/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundFreeBlockRoutine	proc	far
	uses	ax, bx, cx, di, ds
	.enter
	mov_tr	dx, ax				; dx <- handle to free

	mov	ax, segment dgroup
	mov	ds, ax

	mov	bx, ds:[userInterfaceHandle]
	mov	di, mask MF_FORCE_QUEUE
	mov	ax, MSG_USER_FREE_SOUND_HANDLE
	mov	cx, dx				; cx <- handle to free
	call	ObjMessage
	.leave
	ret
SoundFreeBlockRoutine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundResetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up a timer to trigger the next event

CALLED BY:	SoundHandleTimerEvent
PASS:		bx	-> type of timer

		ds	-> SoundStreamStatus

RETURN:		ax	<- timer ID
		bx	<- timer handle

DESTROYED:	nothing

SIDE EFFECTS:	
		sets up another timer to call SoundHandleTimerEvent to
		handle the next timer event.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundResetTimer	proc	near
	uses	cx, dx, si, bp
	.enter
	;
	;  Read in delta time
	;
	call	SoundReadNextWord		; ax <- delta time

	tst_clc	ax				; look for zero delta time
	jz	done

	;
	;  We only need to set up the type and time for
	;  each type.
	sub	bx, SoundStreamEvent		; bx <- offset for TimerType

EC<	cmp	bx, 4						>
EC<	ERROR_A SOUND_BAD_EVENT_COMMAND		; must be =< 4	>
EC<	test	bx, 1				; must be even	>
EC<	ERROR_NZ SOUND_BAD_EVENT_COMMAND			>

	jmp	cs:timerTable[bx]

tempoTimer:
	;
	;  If the tempo actually turns out to be longer than 65535
	;  msec, and hence, can't get fit in a msec timer what we do
	;  is: set up a sequence of msec timers which decrement the
	;  dx count by one and set up a timer for 65535 msec.  As we
	;  set the first delay to be ax, it all works out...
	mul	ds:[SC_format.SFS_fm].SFMS_tempo ; dxax <- # of msec to wait
	mov	ds:[SC_format.SFS_fm].SFMS_timeRemaining,dx; hopefully its zero

msecTimer:
	;
	;  Set cx to the # of msec, and set the propper type
	mov_tr	cx, ax				; cx <- # of msec to wait
	mov	al, TIMER_MS_ROUTINE_ONE_SHOT	; al <- msec timer

setUpTimer:
	;
	;  Set up bx:si to call SoundHandleTimerEvent and
	;  have it pass along this sound segment
	mov	bx, ds:[SBS_blockHandle]	; bx <- handle of stream
	call	MemOwner			; bx <- owner of stream

	mov	bp, bx				; bp <- owner of timer
	mov	bx, segment ResidentCode	; call bx:si
	mov	si, offset SoundHandleTimerEvent
	mov	dx, ds				; pass it this stream
	call	TimerStartSetOwner

						; save timer ID
	mov	ds:[SC_format.SFS_fm].SFMS_timerID, ax
						; save timer handle
	mov	ds:[SC_format.SFS_fm].SFMS_timerHandle, bx

	;
	;  Signal end of timer event
	;
	clr	bx				; mark as not eos
	stc
done:
	.leave
	ret

tickTimer:
	;
	;  set cx to hold the # of ticks and set the propper type
	mov_tr	cx, ax				; cx <- # of ticks to wait
	mov	al, TIMER_ROUTINE_ONE_SHOT	; al <- tick timer
	jmp	short setUpTimer

timerTable	nptr	msecTimer,
			tickTimer,
			tempoTimer
SoundResetTimer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundVoiceOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on a voice to play from a channel

CALLED BY:	SoundHandleTimerEvent
PASS:		si	-> offset to driver's voices in Sound struct
		ds	-> Sound struct segment

RETURN:		carry clear

DESTROYED:	nothing

SIDE EFFECTS:	
		allocates a voice, and possibly plays a note

PSEUDO CODE/STRATEGY:
		get a voice from VoiceManager.
		set up our SoundVoiceStatus to reflect change

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		.assert	size SoundVoiceStatus	eq	8
SoundVoiceOn	proc	near
	uses	ax, bx, cx, si, di, es
	.enter
	mov	ax, segment dgroup		; ax <- dgroup of library
	mov	es, ax				; es <- dgroup of library

	;
	;  Get voice # we are supposed to play on and
	;  check our voice settings to see if we are
	;  currently playing something on this voice
	call	SoundReadNextWord

	mov	di, ax				; di <- voice #

	shl	ax, 1				; ax <- ax * 2
	shl	ax, 1				; ax <- ax * 4
	shl	ax, 1				; ax <- ax * 8 (size SVS)
	add	si, ax				; si <- offset to our voice

	;
	;  If we are playing something on the voice,
	;  we should turn it off so it doesn't stay allocated
	;  forever
	mov	cx, ds:[si].SVS_physicalVoice	; cx <- voice to turn off
	cmp	cx, NO_VOICE
	je	getNewVoice

	;
	;  turn off the voice (just incase its playing),
	;	and re-activate it at the current priority.

	mov	di, DRE_SOUND_VOICE_OFF		; turn off the note
	call	es:[soundSynthStrategy]

	call	SoundVoiceDeactivate		; move voice from active list

	mov	ax, ds:[SBS_priority]		; ax <- new priority

	call	SoundVoiceActivate		; move voice back to list
						; with new priority

turnOnVoice:
	call	SoundReadNextWord
	mov_tr	bx, ax				; bx <- frequency

	call	SoundReadNextWord
	xchg	ax, bx				; ax <- frequency, bx <- volume

	mov	di, DRE_SOUND_VOICE_ON
	call	es:[soundSynthStrategy]	

done:
	clc
	.leave
	ret

getNewVoice:
	;
	;  call voiceManager and see if there is a voice available
	mov	ax, ds:[SBS_priority]		; ax <- new priority
	call	SoundVoiceGetFree	; cx <- free voice #
	jc	noVoiceAvailable

	;
	;  set up and associate voice with our Sound
	;
	push	dx

	mov	dx, di				; dx <- stream voice #
	mov	bx, ds				; bx <- SoundStreamStatus seg.
	call	SoundVoiceAssign


	call	SoundVoiceActivate		; add to active list

	pop	dx
	;
	;  set the voice up for the new stream.
	push	si

	mov	bx, ds:[si].SVS_instrument.segment
	mov	si, ds:[si].SVS_instrument.offset

	mov	di, DRE_SOUND_SET_ENVELOPE
	call	es:[soundSynthStrategy]

	pop	si
	jmp	short turnOnVoice

noVoiceAvailable:
	;
	;  Ahem.  Now would be a good time to advance the pointer
	;	so that it looks like we read the next two words,
	;	even though we don't need them, so that things don't
	;	get messed up.
	;  Not that I ever forgot.
	call	SoundReadNextWord		; "read" frequency

	call	SoundReadNextWord		; "read" volume

	mov	ds:[si].SVS_physicalVoice, NO_VOICE	; set voice silent
	jmp	short	done

SoundVoiceOn	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundVoiceOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off a voice (if note is still playing)

CALLED BY:	SoundHandleTimerEvent
PASS:		si	-> driver's voices in stream

		ds	-> SoundStreamStatus

RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	
		turns off voice

PSEUDO CODE/STRATEGY:
		see if stream's voice is attached to real voice.
		If so, turn off real voice, and "free" it up.
		If not, return

		Instead of actually returning the free voice
		to the free list, we simply deactivate it,
		removing it from the active list, change
		its priority to 255 (since we want to use
		it again), but we don't place it on the free
		list, we place it back on the active list.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		.assert	size SoundVoiceStatus	eq	8
SoundVoiceOff	proc	near
	uses	ax, cx, si, ds
	.enter
	;
	;  Check voice for active voice
	call	SoundReadNextWord
	shl	ax, 1				; ax <- voice * 2
	shl	ax, 1				; ax <- voice * 4
	shl	ax, 1				; ax <- voice * 8 (size SVS)

	add	si, ax				; si <- our voice

	mov	cx, ds:[si].SVS_physicalVoice	; cx <- voice assigned to us
	cmp	cx, NO_VOICE
	je	done

	;
	;  Well, looks like we really are playing a note.  Turn
	;  it off and free up the voice
	mov	ax, segment dgroup		; ax <- dgroup of library
	mov	ds, ax				; es <- dgroup of library

	mov_tr	ax, di				; save di

	mov	di, DRE_SOUND_VOICE_OFF
	call	ds:[soundSynthStrategy]		; stop note

	mov_tr	di, ax				; restore di

	call	SoundVoiceDeactivate		; move node from active list

	mov	ax, 0ffffh			; ax <- worst priority possible
	call	SoundVoiceActivate
done:
	clc

	.leave
	ret
SoundVoiceOff	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter the stream's data structure to reflect change

CALLED BY:	SoundHandleTimerEvent
PASS:		si	-> offset voice data of driver in stream
		ds	-> SoundStreamStatus

RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	
		changes settings for voice, but does not silence any
		not playing.

PSEUDO CODE/STRATEGY:
		just update the pointer for the voice in the
		data located after the regualr SoundStreamStatus

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert size SoundVoiceStatus eq 8
SoundChange	proc	near
	uses	ax, cx, ds, si
	.enter
	;
	;  Get sound's voice # to change
	call	SoundReadNextWord
	shl	ax, 1				; ax <- ax * 2
	shl	ax, 1				; ax <- ax * 4
	shl	ax, 1				; ax <- ax * 8 (size SVS)
	add	si, ax				; si <- our voice

	;
	;  Get offset of instrument first (little endian, remember?)
	call	SoundReadNextWord
	mov	ds:[si].SVS_instrument.offset, ax

	;
	;  Get segment of instrument next (little endian, got it..)
	call	SoundReadNextWord
	mov	ds:[si].SVS_instrument.segment, ax

	;
	;  Deactivate the voice, since we aren't going to need
	;  it until the next VoiceOn shows up.
	mov	cx, NO_VOICE
	xchg	ds:[si].SVS_physicalVoice, cx

	cmp	cx, NO_VOICE
	je	done				; => not playing

	;
	;  We're playing a note (or had a voice from a previous
	;  note on), so we need to turn off the note and stuff
	;  it back on the list.
	;
	segmov	ds, dgroup, ax
	mov_tr	ax, di				; save trashed di

	mov	di, DRE_SOUND_VOICE_OFF		; turn off note (just in case)
	call	ds:[soundSynthStrategy]

	mov_tr	di, ax				; restore trashed di

	call	SoundVoiceDeactivate		; return voice to free list
	call	SoundVoiceFree

done:
	;
	;  No errors here...
	clc
	.leave
	ret
SoundChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundGeneral
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with a general command

CALLED BY:	SoundHandleTimerEvent
PASS:		ds	-> Sound segment

RETURN:		carry set if general event is END_OF_SONG
		carry clear, otherwise.

		bx non-zero if END_OF_SONG
		bx zero otherwise

DESTROYED:	bx (see above)

SIDE EFFECTS:	
		signals end of song, causing HandleTimerEvent to
		not set up another timer.  Hence, EOS must be
		the last event.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/17/92		Initial version


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert size SoundVoiceStatus	eq	8
SoundGeneral	proc	near
	uses	ax
	.enter
; not allowed from interrupt code -- ardeb
;EC<	call	ECCheckStack				>
	call	SoundReadNextWord
	mov_tr	bx, ax				; bx <- general command

	;
	;  Make sure general event is a legal event
EC<	cmp	bx, 10						>
EC<	ERROR_A  SOUND_BAD_EVENT_COMMAND	; must be =< 10	>
EC<	test	bx, 1				; must be even	>
EC<	ERROR_NZ SOUND_BAD_EVENT_COMMAND			>
	jmp	cs:GeneralEventJumpTable[bx]

handleEndOfSong:


	;
	;  Examine all the voices and free them.
	;
	mov	bx, ds:[SC_format.SFS_fm].SFMS_voicesUsed
	dec	bx				; we want bx = 0 when 1 voice

	shl	bx, 1				; bx <- bx * 2
	shl	bx, 1				; bx <- bx * 4
	shl	bx, 1				; bx <- bx * 8 (size SVS)

topOfLoop:
	mov	cx, NO_VOICE
	xchg	cx, ds:SC_voice[bx].SVS_physicalVoice
	cmp	cx, NO_VOICE
	je	nextVoice

	call	SoundVoiceDeactivate		; remove from active list
	call	SoundVoiceFree			; free voice

nextVoice:
	sub	bx, size SoundVoiceStatus
	jns	topOfLoop
	
	mov	bx, -1				; mark end of song
	stc					; mark end of song
	jmp	short done

handleSetPriority:
	call	SoundReadNextWord
	mov	ds:[SBS_priority], ax		; save new priority
	jmp	short clearCarry

handleSetTempo:
	call	SoundReadNextWord
	mov	ds:[SC_format.SFS_fm].SFMS_tempo, ax	; save new tempo
	jmp	short clearCarry

handleSendNotification:
	;
	;  Now, you're probably thinking we're just going
	;	to use ObjMessage and send things right
	;	along, right?  Not!
	;  We can't even use ObjMessage MF_FORCE_QUEUE because
	;	ObjMessage turns on interrupts.  As this
	;	routine can be called in a msec timer, INT's
	;	can never be enabled.
	;  What do we do?  Easy.. We set up ANOTHER timer (a tick
	;	timer) that does the messaging for us.  Pretty
	;	slick, huh?  We don't even have to use ObjMessage
	;	because we can just set up a timer to send the
	;	message all by its lonesome.  :)
	;
	push	cx, dx, si, bp			; save trashed registers

	call	SoundReadNextWord
	mov_tr	dx, ax				; dx <- message
	call	SoundReadNextWord
	mov_tr	bp, ax				; bp:si <- object
	call	SoundReadNextWord
	mov_tr	si, ax

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, 1				; 1 tick later

	;
	;  The owner of this timer should be the owner
	;	of the Sound buffer.

	mov	bx, ds:[SBS_blockHandle]	; bx <- handle of sound
	call	MemOwner

	xchg	bx, bp				; bx:si <- object, bp <- owner

	call	TimerStartSetOwner		; set up message timer

	pop	cx, dx, si, bp			; restore trashed registers
	jmp	short clearCarry

handleVSemaphore:
	call	SoundReadNextWord
	mov_tr	bx, ax				; bx <- semaphore handle
	call	ThreadVSem			; v the semaphore

clearCarry:
	clr	bx
	clc					; only EOS returns carry set

done:
	.leave
	ret

GeneralEventJumpTable	nptr	clearCarry,		; GE_NO_EVENT
				handleEndOfSong,	; GE_END_OF_SONG
				handleSetPriority,	; GE_SET_PRIORITY
				handleSetTempo,		; GE_SET_TEMPO
				handleSendNotification,	; GE_SEND_NOTIFICATION
				handleVSemaphore	; GE_V_SEMAPHORE

SoundGeneral	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundReadNextWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the next word of data from memory or the stream

CALLED BY:	SoundGeneral
PASS:		ds	-> Sound structure

RETURN:		ax	<- word of data

DESTROYED:	nothing

SIDE EFFECTS:	reads data from stream or from memory

PSEUDO CODE/STRATEGY:
		determine type
		read one word
		return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/28/92    	Initial version
	TS	 4/14/93	Optimized once

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert ST_SIMPLE_FM eq 0
SoundReadNextWord	proc	near
	.enter
	;
	;  See if we are reading from an FM stream or a simple FM.
	;	ST_SIMPLE_FM is zero, so if SBS_type is non-zero, it
	;	must be a stream.
	tst	ds:[SBS_type]
	jnz	readFromStream

	tst	ds:[SC_position.SSS_simple].SSS_songBuffer.segment
	jnz	readFromFixedMemory

readFromSoundSegment::
	;
	;  We are reading from a buffer which is in the same
	;	segment as the SoundControl block.
	;  This means we just use the current segment to get
	;	to the buffer.
	push	si

	mov	si, ds:[SC_position.SSS_simple].SSS_songPointer

	lodsw

	mov	ds:[SC_position.SSS_simple].SSS_songPointer, si

	pop	si
done:
	.leave
	ret

readFromFixedMemory:
	;
	;  We are playing a sound buffer which is not in the same
	;	segment as this SoundControl block.

	push	si				; save trashed si

	mov	si, ds:[SC_position.SSS_simple].SSS_songPointer

	push	ds				; save sound segment

	mov	ds, ds:[SC_position.SSS_simple].SSS_songBuffer.segment

	lodsw

	pop	ds				; restore sound segment

	mov	ds:[SC_position.SSS_simple].SSS_songPointer, si

	pop	si				; restore trashed si

	jmp	short done

readFromStream:
	push	bx, cx, di, es

	mov	es, ds:[SC_position.SSS_stream].SSS_streamSegment

	StreamGetByteNB es, cl, INTS_OFF	; trashes ax, bx
	StreamGetByteNB es, ch, INTS_OFF	; trashes ax, bx

	call	StreamWriteDataNotify		; trashes ax, di

	mov_tr	ax, cx				; ax <- word read

	pop	bx, cx, di, es
	jmp	done
SoundReadNextWord	endp

ResidentCode	ends


