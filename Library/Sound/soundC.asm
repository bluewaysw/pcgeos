COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS Sound System	
MODULE:		C Stubs for sound library
FILE:		soundC.asm

AUTHOR:		Todd Stumpf, Sep 25, 1992

ROUTINES:
	Name				Description
	----				-----------
	SOUNDGETEXCLUSIVENB		SoundGetExclusiveNB	 Stub
	SOUNDGETEXCLUSIVE		SoundGetExclusive	 Stub
	SOUNDRELEASEEXCLUSIVE		SoundReleaseExclusive	 Stub

	SOUNDALLOCMUSIC			SoundAllocMusic		 Stub
	SOUNDPLAYMUSIC			SoundPlayMusic		 Stub
	SOUNDSTOPMUSIC			SoundStopMusic		 Stub
	SOUNDPLAYMUSICLMEM		SoundPlayMusicLMem	 Stub
	SOUNDSTOPMUSICLMEM		SoundStopMusicLMem	 Stub
	SOUNDREALLOCMUSIC		SoundReallocMusic	 Stub
	SOUNDFREEMUSIC			SoundFreeMusic		 Stub

	SOUNDALLOCMUSICNOTE		SoundAllocMusicNote	 Stub
	SOUNDPLAYMUSICNOTE		SoundPlayMusicNote	 Stub
	SOUNDSTOPMUSICNOTE		SoundStopMusicNote	 Stub
	SOUNDREALLOCMUSICNOTE		SoundReallocMusicNote	 Stub
	SOUNDFREEMUSICNOTE		SoundFreeMusicNote	 Stub

	SOUNDALLOCMUSICSTREAM		SoundAllocMusicStream	 Stub
	SOUNDPLAYTOMUSICSTREAM		SoundPlayToMusicStream	 Stub
	SOUNDPLAYTOMUSICSTREAMNOBLOCK	SoundPlayToMusicStreamNoBlock
								 Stub
	SOUNDSTOPMUSICSTREAM		SoundStopMusicStream	 Stub
	SOUNDFREEMUSICSTREAM		SoundFreeMusicStream	 Stub

	SOUNDINITMUSIC			SoundInitMusic		 Stub

	SOUNDALLOCSAMPLESTREAM		SoundAllocSampleStream	 Stub
	SOUNDENABLESAMPLESTREAM		SoundEnableSampleStream	 Stub
	SOUNDPLAYTOSAMPLESTREAM		SoundPlayToSampleStream	 Stub
	SOUNDDISABLESAMPLESTREAM	SoundDisableSampleStream Stub
	SOUNDFREESAMPLESTREAM		SoundFreeSampleStream	 Stub

	SOUNDCHANGEOWNERSIMPLE		SoundChangeOwnerSimple	 Stub
	SOUNDCHANGEOWNERSTREAM		SoundChangeOwnerStream	 Stub

	SOUNDSYNTHDRIVERINFO		SoundSynthDriverInfo	 Stub
	SOUNDSAMPLEDRIVERINFO		SoundSampleDriverInfo	 Stub

	SOUNDSETLOWFREQUENCYFLAG	SoundSetLowFrequencyFlag Stub

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/25/92		Initial revision
	JV	4/6/94		Added LMem chunk support

DESCRIPTION:
	C-stubs for the library interface.  For more information, see
	the regular assemply routines.

	$Id: soundC.asm,v 1.1 97/04/07 10:46:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Common		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDGETEXCLUSIVENB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundGetExclusiveNB

C DECLARATION:	extern Boolean
			_far _pascal SoundGetExclusiveNB(void)

RETURNS:	TRUE if Error,
		FALSE if Success

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDGETEXCLUSIVENB	proc	far	
	.enter
	call	SoundGetExclusiveNB

	mov	ax, 1				; assume things went wrong
	jc	done				; did they?

	clr	ax				; guess they didn't
done:
	.leave
	ret
SOUNDGETEXCLUSIVENB	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDGETEXCLUSIVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundGetExclusive

C DECLARATION:	extern void
			_far _pascal SoundGetExclusive(void)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDGETEXCLUSIVE	proc	far
	.enter
	call	SoundGetExclusive
	.leave
	ret
SOUNDGETEXCLUSIVE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDRELEASEEXCLUSIVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundReleaseExclusive

C DECLARATION:	extern void
			_far _pascal SoundReleaseExclusiveAccess(void)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDRELEASEEXCLUSIVE	proc	far
	.enter
	call	SoundReleaseExclusive
	.leave
	ret
SOUNDRELEASEEXCLUSIVE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDALLOCMUSIC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		

C FUNCTION:	SoundAllocMusic

C DECLARATION:	extern SoundError
			_far _pascal SoundAllocMusic  (word      *song,
						       word      voices,
						       MemHandle *control)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDALLOCMUSIC 	proc	far	song:fptr.word,
					voices:word,
					control:fptr.word

	uses	bx,cx,ds,si
	.enter
	movdw	bxsi, song		; bx:si <- buffer for song
	mov	cx, voices		; cx	<- # of voices used in buffer

	call	SoundAllocMusic		; allocate a sound stream

	;
	;  Assume things went right.  We need to store
	;	the mem handle in control
	lds	si, control		; ds:si <- storage for memhandle

	mov	ds:[si], bx		; store handle
	jc	done

	;
	;  Nope. no error.  Return zero
	mov	ax, SOUND_ERROR_NO_ERROR

done:
	.leave
	ret
SOUNDALLOCMUSIC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDPLAYMUSIC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundPlayMusic

C DECLARATION:	extern Sounderror
			_far _pascal SoundPlayMusic (MemHandle      mh,
						      SoundPriority priority,
						      word	    tempo,
						      char	    flags)

RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDPLAYMUSIC	proc	far		mh:hptr,
					priority:word,
					tempo:word,
					flags:word
	uses	bx, cx, dx
	.enter
	mov	bx, mh				; bx <- handle for sound
	mov	ax, priority			; ax <- priority for sound
	mov	cx, tempo			; cx <- tempo for sound
	mov	dl, {byte} flags		; dl <- flags

	call	SoundPlayMusic			; start playing sound
	jc	done				; did they?

	mov	ax, SOUND_ERROR_NO_ERROR

done:
	.leave
	ret
SOUNDPLAYMUSIC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDSTOPMUSIC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundStopMusic

C DECLARATION:	extern SoundError
			_far _pascal SoundStopMusic (MemHandle     mh)

RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDSTOPMUSIC	proc	far		mh:hptr
	uses	bx
	.enter
	mov	bx, mh				; bx <- sound token

	call	SoundStopMusic			; stop the sound

	jc	done				; did they?

	mov	ax, SOUND_ERROR_NO_ERROR

done:
	.leave
	ret
SOUNDSTOPMUSIC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDPLAYMUSICLMEM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundPlayMusicLMem

C DECLARATION:	extern Sounderror
			_far _pascal SoundPlayMusicLMem (MemHandle      mh,
						      SoundPriority priority,
						      word	    tempo,
						      char	    flags)

RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JV	4/6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDPLAYMUSICLMEM	proc	far		mh:hptr,
						priority:word,
						tempo:word,
						flags:word
	uses	bx, cx, dx
	.enter
	mov	bx, mh				; bx <- handle for sound
	mov	ax, priority			; ax <- priority for sound
	mov	cx, tempo			; cx <- tempo for sound
	mov	dl, {byte} flags		; dl <- flags

	call	SoundPlayMusicLMem		; start playing sound
	jc	done				; did they?

	mov	ax, SOUND_ERROR_NO_ERROR

done:
	.leave
	ret
SOUNDPLAYMUSICLMEM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDSTOPMUSICLMEM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundStopMusicLMem

C DECLARATION:	extern SoundError
			_far _pascal SoundStopMusicLMem (MemHandle     mh)

RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JV	4/6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDSTOPMUSICLMEM	proc	far		mh:hptr
	uses	bx
	.enter
	mov	bx, mh				; bx <- sound token

	call	SoundStopMusic			; stop the sound

	jc	done				; did they?

	mov	ax, SOUND_ERROR_NO_ERROR

done:
	.leave
	ret
SOUNDSTOPMUSICLMEM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDREALLOCMUSIC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundReallocMusic

C DECLARATION:	extern SoundError
			_far _pascal SoundReallocMusic (MemHandle	mh,
							 word _far	song)
						      
RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDREALLOCMUSIC	proc	far	mh:hptr,
					song:fptr.word
	uses	bx, si, ds
	.enter
	mov	bx, mh			; bx <- token to change
	mov	ds, song.segment	; ds <- song segment
	mov	si, song.offset		; si <- song offset

	call	SoundReallocMusic	; re-allocate the stream

	jc	done			; did they?

	mov	ax, SOUND_ERROR_NO_ERROR
done:
	.leave
	ret
SOUNDREALLOCMUSIC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDREALLOCMUSICLMEM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundReallocMusic

C DECLARATION:	extern SoundError
			_far _pascal SoundReallocMusicLMem (MemHandle	mh,
							    optr song)
						      
RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDREALLOCMUSICLMEM	proc	far	mh:hptr,
					song:optr.word
	uses	bx, si, dx
	.enter
	mov	bx, mh			; bx <- token to change
	mov	dx, song.segment	; ds <- song segment
	mov	si, song.offset		; si <- song offset

	call	SoundReallocMusicLMem	; re-allocate the stream

	jc	done			; did they?

	mov	ax, SOUND_ERROR_NO_ERROR
done:
	.leave
	ret
SOUNDREALLOCMUSICLMEM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDFREEMUSIC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundFreeMusic

C DECLARATION:	extern void
			_far _pascal SoundFreeMusic (MemHandle     mh)
						      
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDFREEMUSIC	proc	far		mh:hptr
	uses	bx
	.enter
	mov	bx, mh
	call	SoundFreeMusic
	.leave
	ret
SOUNDFREEMUSIC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDALLOCMUSICNOTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundAllocMusicNote

C DECLARATION:	extern SoundError
			_far _pascal SoundAllocNote  (word	instrument,
						      word	instTable,
						      word	frequency,
						      word	volume,
						      word	DeltaType,
						      word	duration,
						      MemHandle *control)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDALLOCMUSICNOTE	proc	far	instrument:word,
					instTable:word,
					frequency:word,
					volume:word,
					deltaType:word,
					duration:word,
					control:fptr.word

	uses	bx, cx, dx, si, di
	.enter
	mov	bx, instTable		; bx:si <- instrument setting
	mov	si, instrument
	mov	ax, frequency		; ax <- note frequency
	mov	cx, volume		; cx <- note volume
	mov	dx, deltaType		; dx <- duration type
	mov	di, duration		; di <- duration length

	call	SoundAllocMusicNote

	;
	;  Assume things went well. Save handle
	;
	lds	si, control

	mov	ds:[si], bx

	jc	done

	mov	ax, SOUND_ERROR_NO_ERROR

done:
	.leave
	ret
SOUNDALLOCMUSICNOTE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDPLAYMUSICNOTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundPlayMusicNote

C DECLARATION:	extern SoundError
			_far _pascal SoundPlayMusicNote   (MemHandle     mh,
						        SoundPriority priority,
						        word	    tempo,
							char	    flags)

RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDPLAYMUSICNOTE	proc	far	mh:hptr, 
					priority:word, 
					tempo:word, 
					flags:word
	uses	bx, cx, dx
	.enter
	mov	bx, mh			; bx <- handle for note
	mov	ax, priority		; ax <- priority for note
	mov	cx, tempo		; cx <- tempo for note
	mov	dl, {byte} flags	; dx <- flags

	call	SoundPlayMusic		; Play the note

	jc	done			; was there?

	mov	ax, SOUND_ERROR_NO_ERROR
done:
	.leave
	ret
SOUNDPLAYMUSICNOTE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDSTOPMUSICNOTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundStopMusicNote

C DECLARATION:	extern SoundError
			_far _pascal SoundStopMusicNote   (MemHandle     mh)

RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDSTOPMUSICNOTE	proc	far		mh:hptr
	uses	bx
	.enter
	mov	bx, mh			; bx <- handle of sound to turn off

	call	SoundStopMusic		; stop the MusicNote

	jc	done			; check if they did

	mov	ax, SOUND_ERROR_NO_ERROR
done:
	.leave
	ret
SOUNDSTOPMUSICNOTE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDREALLOCMUSICNOTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundReallocMusicNote

C DECLARATION:	extern SoundError
			_far _pascal SoundReallocMusicNote(MemHandle	mh,
							   word		freq,
							   word		vol,
							   word		timer,
							   word		durat,
							   word		instr,
							   word		instT)

RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDREALLOCMUSICNOTE	proc	far	mh:hptr, 
					freq:word, 
					vol:word, 
					timer:word, 
					durat:word, 
					instrument:word,
					instTable:word
	uses	bx, cx, dx, si, di, ds
	.enter
	mov	ax, freq
	mov	bx, mh
	mov	cx, vol
	mov	dx, timer
	mov	di, durat
	mov	ds, instTable
	mov	si, instrument

	call	SoundReallocMusicNote

	jc	done

	mov	ax, SOUND_ERROR_NO_ERROR
done:
	.leave
	ret
SOUNDREALLOCMUSICNOTE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDFREEMUSICNOTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundFreeMusicNote

C DECLARATION:	extern void
			_far _pascal SoundFreeMusicNote(MemHandle	mh)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDFREEMUSICNOTE	proc	far	mh:hptr
	uses	bx
	.enter
	mov	bx, mh

	call	SoundFreeMusic
	.leave
	ret
SOUNDFREEMUSICNOTE endp

;-----------------------------------------------------------------------------
;
;  Stream Functions
;
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDALLOCMUSICSTREAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundAllocMusicStream

C DECLARATION:	extern SoundError
		_far _pascal SoundAllocMusicStream   (word 	streamSize,
						      word	priority,
						      word	voices,
						      word	tempo,
						      MemHandle *control)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDALLOCMUSICSTREAM	proc	far	streamSize:word, 
					priority:word,
					voice:word, 
					tempo:word,
					control:fptr.word

	uses	bx, cx, dx, ds, si
	.enter
	mov	ax, streamSize
	mov	bx, priority
	mov	cx, voice
	mov	dx, tempo

	call	SoundAllocMusicStream

	;
	;  Assume things went well.  Store the new
	;	handle in the propper place.
	lds	si, control

	mov	ds:[si], bx

	;
	;  Now see if things did go well.
	jc	done				; propgate error?

	mov	ax, SOUND_ERROR_NO_ERROR	; things went fine

done:
	.leave
	ret
SOUNDALLOCMUSICSTREAM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDPLAYTOMUSICSTREAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundPlayToMusicStream

C DECLARATION:	extern SoundError
		_far _pascal SoundPlayToMusicStream (MemHandle   mh,
						     const word  *buffer,
						     word	 bufferSize)

RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDPLAYTOMUSICSTREAM	proc	far	mh:hptr,
					buffer:fptr.word, 
					bufferSize:word
	uses	bx, cx, dx, si
	.enter
	mov	bx, mh			; bx <- handle for sound
	movdw	dxsi, buffer		; dx:si <- buffer to copy
	mov	cx, bufferSize		; cx <- size of buffer

	call	SoundPlayToMusicStream
	jc	done

	mov	ax, SOUND_ERROR_NO_ERROR

done:
	.leave
	ret
SOUNDPLAYTOMUSICSTREAM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDPLAYTOMUSICSTREAMNB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundPlayToMusicStreamNB

C DECLARATION:	extern SoundError
			_far pascal SoundPlayToMusicStreamNB(MemHandle   mh,
                                               const word  *buffer,
                                               word      bufferSize,
					       word _far *bytesWritten)

RETURNS:	SoundError
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDPLAYTOMUSICSTREAMNB	proc	far	mh:hptr,
						buffer:fptr.word,
						bufferSize:word,
						bytesWritten:fptr
	uses	bx, cx, dx, ds, si
	.enter
	mov	bx, mh			; bx <- handle for sound
	movdw	dxsi, buffer		; dx:si <- buffer to copy
	mov	cx, bufferSize		; cx <- size of buffer

	call	SoundPlayToMusicStreamNB
	;
	; carry set if can't write everything to stream
	;     ax <- SoundWriteStreamStatus
	;     if ax = SWSS_NOT_ENOUGH_SPACE_IN_STREAM_TO_WRITE, 
	;         cx <- # bytes written
	;
	lds	si, bytesWritten
	mov	ds:[si], cx		; return # bytes written
	jnc	writtenAll		; jmp if all events written

	;
	; Cannot write everything to stream. Now, set up return values
	;
	cmp	ax, SWSS_NOT_ENOUGH_SPACE_IN_STREAM_TO_WRITE
EC <	ERROR_NE SOUND_INVALID_WRITE_STREAM_STATUS			>
	mov	ax, SOUND_ERROR_STREAM_FULL
	jmp	done

writtenAll:
	mov	ax, SOUND_ERROR_NO_ERROR
	
done:
	.leave
	ret
SOUNDPLAYTOMUSICSTREAMNB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDSTOPMUSICSTREAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundStopMusicStream

C DECLARATION:	extern SoundError
			_far _pascal SoundStopMusicStream
						MemHandle   mh,
						     const word  *buffer,
						     word	 bufferSize)
RETURNS:	SoundError

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDSTOPMUSICSTREAM	proc	far		mh:hptr
	uses	bx
	.enter
	mov	bx, mh			; bx <- handle of sound to turn off

	call	SoundStopMusicStream	; stop the MusicNote

	jc	done			; check if they did

	mov	ax, SOUND_ERROR_NO_ERROR

done:
	.leave
	ret
SOUNDSTOPMUSICSTREAM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDFREEMUSICSTREAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundFreeMusicStream

C DECLARATION:	extern void
			_far _pascal SoundFreeMusicStream(MemHandle	mh)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDFREEMUSICSTREAM	proc	far	mh:hptr
	uses	bx
	.enter
	mov	bx, mh

	call	SoundFreeMusicStream
	.leave
	ret
SOUNDFREEMUSICSTREAM endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDINITMUSIC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundInitMusic

C DECLARATION:	extern void
			_far _pascal SoundInitMusic(MemHandle mh, word voices);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	3/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDINITMUSIC		proc	far	mh:hptr,
					voices:word
	uses	bx, cx
	.enter
	mov	bx, mh
	mov	cx, voices

	call	SoundInitMusic
	.leave
	ret
SOUNDINITMUSIC	endp


;-----------------------------------------------------------------------------
;
;  Sampled Stream Functions
;
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDALLOCSAMPLESTREAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundAllocSampleStream

C DECLARATION:	extern SoundError
		_far _pascal SoundAllocSampleStream(MemHandle *control)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDALLOCSAMPLESTREAM	proc	far	control:fptr.hptr
	uses	bx, si, ds
	.enter

	call	SoundAllocSampleStream

	lds	si, control

	mov	ds:[si], bx

	jc	done

	mov	ax, SOUND_ERROR_NO_ERROR

done:
	.leave
	ret
SOUNDALLOCSAMPLESTREAM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDENABLESAMPLESTREAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundEnableSampleStream

C DECLARATION:	extern SoundError
			_far _pascal SoundEnableSampleStream (MemHandle     mh,
							word	priority,
							word	rate,
							word	manufacturerID,
							DACSampleFormat format)

RETURNS:	SoundError

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDENABLESAMPLESTREAM	proc	far	mh:hptr,
					priority:word, 
					rate:word,
					manufacturerID:word, 
					format:DACSampleFormat
	uses	bx, cx, dx, si
	.enter
	mov	bx, mh
	mov	ax, priority
	mov	cx, rate
	mov	dx, manufacturerID
	mov	si, format

	call	SoundEnableSampleStream

	jc	done			; was there?

	mov	ax, SOUND_ERROR_NO_ERROR

done:
	.leave
	ret
SOUNDENABLESAMPLESTREAM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDPLAYTOSAMPLESTREAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundPlayToSampleStream

C DECLARATION:	extern SoundError
		_far _pascal SoundPlayToSampleStream (MemHandle     mh,
						      const word   *sample,
						      word	    size,
						SampleFormatDescription format)

RETURNS:	SoundError

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDPLAYTOSAMPLESTREAM	proc	far	mh:hptr, 
					sample:fptr.word, 
					sampleSize:word,
					format:fptr.SampleFormatDescription
	uses	bx, cx, dx, si, di
	.enter
	mov	bx, mh			; bx <- handle of sound
	movdw	dxsi, sample		; dx:si <- buffer
	mov	cx, sampleSize		; cx <- size
	movdw	axdi, format		; ax:di <- SampleFormatDescription

	push	bp			; save frame pointer

	mov	bp, di			; ax:bp <- SampleFormatDescription

	call	SoundPlayToSampleStream	; play the buffer

	pop	bp			; restore frame pointer

	jc	done			; was there?

	mov	ax, SOUND_ERROR_NO_ERROR
done:
	.leave
	ret
SOUNDPLAYTOSAMPLESTREAM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDDISABLESAMPLESTREAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundDisableSampleStream

C DECLARATION:	extern void
			_far _pascal SoundDisableSampleStream (MemHandle    mh)

RETURNS:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDDISABLESAMPLESTREAM	proc	far	mh:hptr
	uses	bx
	.enter
	mov	bx, mh

	call	SoundDisableSampleStream
	.leave
	ret
SOUNDDISABLESAMPLESTREAM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDFREESAMPLESTREAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundFreeSampleStream

C DECLARATION:	extern void
			_far _pascal SoundFreeSampleStream(MemHandle	mh)

RETURN:		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDFREESAMPLESTREAM	proc	far	mh:hptr
	uses	bx
	.enter
	mov	bx, mh

	call	SoundFreeSampleStream

	.leave
	ret
SOUNDFREESAMPLESTREAM endp


;-----------------------------------------------------------------------------
;
;  Ownership functions
;
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDCHANGEOWNERSIMPLE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundChangeOwnerSimple

C DECLARATION:	extern void
			_far _pascal SoundChangeOwnerSimple (MemHandle	mh,
							     word	owner)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDCHANGEOWNERSIMPLE	proc	far	mh:hptr, 
					owner:hptr
	uses	ax, bx
	.enter
	mov	bx, mh
	mov	ax, owner
	call	SoundChangeOwnerMusic
	.leave
	ret
SOUNDCHANGEOWNERSIMPLE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDCHANGEOWNERSTREAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundChangeOwnerStream

C DECLARATION:	extern void
			_far _pascal SoundChangeOwnerStream (MemHandle  mh,
						             word	owner)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	3/ 3/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDCHANGEOWNERSTREAM	proc	far	mh:hptr, 
					owner:hptr
	uses	ax, bx
	.enter
	mov	bx, mh
	mov	ax, owner
	call	SoundChangeOwnerStream
	.leave
	ret
SOUNDCHANGEOWNERSTREAM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDSYNTHDRIVERINFO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundSynthDriverInfo

C DECLARATION:	extern void
			_far _pascal SoundSynthDriverInfo(word *voices,
				  SupportedInstrumentFormat    *format,
				  SoundDriverCapability        *capability)


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	3/16/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDSYNTHDRIVERINFO	proc	far	voices:fptr.word, 
					format:fptr.word,
					capability:fptr.word
	uses	ax, bx, cx, si, ds
	.enter
	call	SoundSynthDriverInfo

	movdw	dssi, voices
	mov	ds:[si], ax

	movdw	dssi, format
	mov	ds:[si], bx

	movdw	dssi, capability
	mov	ds:[si], cx

	.leave
	ret
SOUNDSYNTHDRIVERINFO	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDSAMPLEDRIVERINFO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundSampleDriverInfo

C DECLARATION:	extern void
			_far _pascal SoundSampleDriverInfo(word *voices,
				       SoundDriverDACCapability	*format)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	3/16/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDSAMPLEDRIVERINFO	proc	far	voices:fptr.word, 
					format:fptr.word
	uses	ax, bx, si, ds
	.enter
	call	SoundSampleDriverInfo

	movdw	dssi, voices
	mov	ds:[si], ax

	movdw	dssi, format
	mov	ds:[si], bx
	.leave
	ret
SOUNDSAMPLEDRIVERINFO	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDVOICEMANAGERGETFREE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundVoiceManagerGetFree

C DECLARATION:	extern word 
		      _far _pascal SoundVoiceManagerGetFree(word priority)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDVOICEMANAGERGETFREE	proc	far	priority:word
	uses	cx
	.enter
	mov	ax, priority			; ax <- priority

	;
	;  Make call to voice manager.
	pushf
	INT_OFF

	call	SoundVoiceGetFreeFar	; cx <- voice

	call	SafePopf

	mov	ax, NO_VOICE			; ax <- -1
	jc	done

	mov_tr	ax, cx				; ax <- voice
done:
	.leave
	ret
SOUNDVOICEMANAGERGETFREE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDVOICEMANAGERFREE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundVoiceManagerFree

C DECLARATION:	extern void
			_far _pascal SoundVoiceManagerFree(word voice)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDVOICEMANAGERFREE	proc	far	voice:word
	uses	cx
	.enter
	mov	cx, voice			; cx <- voice to free

	;
	;  Make call to voice manager
	pushf
	INT_OFF					; disable interrupts

	call	SoundVoiceFreeFar		; free voice

	call	SafePopf			; restore interrupts
	.leave
	ret
SOUNDVOICEMANAGERFREE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDDACMANAGERGETFREE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundDACManagerGetFree

C DECLARATION:	extern word 
		      _far _pascal SoundDACManagerGetFree(word priority)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDDACMANAGERGETFREE	proc	far	priority:word
	uses	cx
	.enter
	mov	ax, priority			; ax <- priority

	;
	;  Make call to voice manager.
	pushf
	INT_OFF

	call	SoundDACGetFree		; cx <- voice

	call	SafePopf

	mov	ax, NO_VOICE			; ax <- -1
	jc	done

	mov_tr	ax, cx				; ax <- voice
done:
	.leave
	ret
SOUNDDACMANAGERGETFREE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOUNDDACMANAGERFREE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	SoundDACManagerFree

C DECLARATION:	extern void
			_far _pascal SoundDACManagerFree(word voice)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOUNDDACMANAGERFREE	proc	far	voice:word
	uses	cx
	.enter
	mov	cx, voice			; cx <- voice to free

	;
	;  Make call to voice manager
	pushf
	INT_OFF					; disable interrupts

	call	SoundDACFree			; free voice

	call	SafePopf			; restore interrupts
	.leave
	ret
SOUNDDACMANAGERFREE	endp

C_Common		ends








